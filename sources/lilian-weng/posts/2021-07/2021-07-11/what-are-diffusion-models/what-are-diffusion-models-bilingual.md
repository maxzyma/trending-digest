# 什么是扩散模型？

> What are Diffusion Models?

> 来源：Lil'Log / Lilian Weng，2021-07-11
> 原文链接：https://lilianweng.github.io/posts/2021-07-11-diffusion-models/
> 分类：人工智能 / 生成模型

## 核心要点

- 扩散模型受非平衡热力学启发，通过马尔可夫链逐步向数据添加随机噪声，并学习逆转过程从噪声中构建所需数据样本。
- 前向扩散过程在T步内向数据样本添加高斯噪声，最终使其等同于各向同性高斯分布。
- 逆向扩散过程旨在从高斯噪声中重建真实样本，通过学习一个神经网络来近似条件概率分布。
- 训练损失函数通常被简化，以最小化预测噪声与真实噪声之间的差异，从而优化逆向扩散过程。
- 扩散模型与噪声条件分数网络（NCSN）密切相关，两者都利用数据分布的梯度进行生成。
- 为加速采样，提出了去噪扩散隐式模型（DDIM）、渐进式蒸馏和一致性模型等方法，显著减少了生成步骤。
- 潜在扩散模型（LDM）在潜在空间而非像素空间中运行扩散过程，以降低训练成本并加快推理速度。
- 条件生成可以通过分类器引导或无分类器引导实现，以生成特定类别标签或文本描述的图像。
- U-Net和Transformer是扩散模型中常见的骨干架构，ControlNet和Diffusion Transformer是其重要的架构变体。
- 扩散模型兼具可处理性和灵活性，但在采样速度方面仍慢于GAN，尽管已有多种加速技术。

## 正文

[2021-09-19 更新：强烈推荐杨松（参考文献中几篇关键论文的作者）撰写的这篇关于[基于分数的生成模型](https://yang-song.github.io/blog/2021/score/)的博客文章]。  

[2022-08-27 更新：新增了[无分类器引导](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#classifier-free-guidance)、[GLIDE](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#glide)、[unCLIP](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#unclip) 和 [Imagen](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#imagen)。  

[2022-08-31 更新：新增了[潜在扩散模型](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#ldm)。  

[2024-04-13 更新：新增了[渐进式蒸馏](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#prog-distll)、[一致性模型](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#consistency)，以及[模型架构部分](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture)。

> [Updated on 2021-09-19: Highly recommend this blog post on [score-based generative modeling](https://yang-song.github.io/blog/2021/score/) by Yang Song (author of several key papers in the references)].  
>
> [Updated on 2022-08-27: Added [classifier-free guidance](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#classifier-free-guidance), [GLIDE](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#glide), [unCLIP](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#unclip) and [Imagen](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#imagen).  
>
> [Updated on 2022-08-31: Added [latent diffusion model](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#ldm).  
>
> [Updated on 2024-04-13: Added [progressive distillation](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#prog-distll), [consistency models](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#consistency), and the [Model Architecture section](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture).

到目前为止，我已经写了三种生成模型，[GAN](https://lilianweng.github.io/posts/2017-08-20-gan/)、[VAE](https://lilianweng.github.io/posts/2018-08-12-vae/)和[Flow-based](https://lilianweng.github.io/posts/2018-10-13-flow-models/)模型。它们在生成高质量样本方面取得了巨大成功，但每种模型都有其自身的局限性。GAN 模型因其对抗性训练性质而可能导致训练不稳定和生成多样性不足。VAE 依赖于替代损失。流模型必须使用专门的架构来构建可逆变换。

> So far, I’ve written about three types of generative models, [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/), [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/), and [Flow-based](https://lilianweng.github.io/posts/2018-10-13-flow-models/) models. They have shown great success in generating high-quality samples, but each has some limitations of its own. GAN models are known for potentially unstable training and less diversity in generation due to their adversarial training nature. VAE relies on a surrogate loss. Flow models have to use specialized architectures to construct reversible transform.

扩散模型受到非平衡热力学的启发。它们定义了一个扩散步骤的马尔可夫链，以缓慢地向数据添加随机噪声，然后学习逆转扩散过程，从噪声中构建所需的数据样本。与 VAE 或流模型不同，扩散模型通过固定程序学习，并且潜在变量具有高维度（与原始数据相同）。

> Diffusion models are inspired by non-equilibrium thermodynamics. They define a Markov chain of diffusion steps to slowly add random noise to data and then learn to reverse the diffusion process to construct desired data samples from the noise. Unlike VAE or flow models, diffusion models are learned with a fixed procedure and the latent variable has high dimensionality (same as the original data).

![Overview of different types of generative models.](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/generative-overview.png)

### 什么是扩散模型？

> What are Diffusion Models?

已经提出了几种基于扩散的生成模型，它们的基础思想相似，包括 *扩散概率模型* ([Sohl-Dickstein et al., 2015](https://arxiv.org/abs/1503.03585))、*噪声条件分数网络* (**NCSN**; [Yang & Ermon, 2019](https://arxiv.org/abs/1907.05600)) 和 *去噪扩散概率模型* (**DDPM**; [Ho et al. 2020](https://arxiv.org/abs/2006.11239))。

> Several diffusion-based generative models have been proposed with similar ideas underneath, including *diffusion probabilistic models* ([Sohl-Dickstein et al., 2015](https://arxiv.org/abs/1503.03585)), *noise-conditioned score network* (**NCSN**; [Yang & Ermon, 2019](https://arxiv.org/abs/1907.05600)), and *denoising diffusion probabilistic models* (**DDPM**; [Ho et al. 2020](https://arxiv.org/abs/2006.11239)).

#### 前向扩散过程

> Forward diffusion process

给定从真实数据分布 $\mathbf{x}_0 \sim q(\mathbf{x})$ 中采样的一个数据点，我们定义一个 *前向扩散过程*，在该过程中，我们在 $T$ 步内向样本中添加少量高斯噪声，生成一系列噪声样本 $\mathbf{x}_1, \dots, \mathbf{x}_T$。步长由方差调度 $\{\beta_t \in (0, 1)\}_{t=1}^T$ 控制。

> Given a data point sampled from a real data distribution $\mathbf{x}_0 \sim q(\mathbf{x})$, let us define a *forward diffusion process* in which we add small amount of Gaussian noise to the sample in $T$ steps, producing a sequence of noisy samples $\mathbf{x}_1, \dots, \mathbf{x}_T$. The step sizes are controlled by a variance schedule $\{\beta_t \in (0, 1)\}_{t=1}^T$.

$$
q(\mathbf{x}_t \vert \mathbf{x}_{t-1}) = \mathcal{N}(\mathbf{x}_t; \sqrt{1 - \beta_t} \mathbf{x}_{t-1}, \beta_t\mathbf{I}) \quad
q(\mathbf{x}_{1:T} \vert \mathbf{x}_0) = \prod^T_{t=1} q(\mathbf{x}_t \vert \mathbf{x}_{t-1})
$$

数据样本 $\mathbf{x}_0$ 随着步长 $t$ 变大而逐渐失去其可区分的特征。最终，当 $T \to \infty$ 时，$\mathbf{x}_T$ 等同于各向同性高斯分布。

> The data sample $\mathbf{x}_0$ gradually loses its distinguishable features as the step $t$ becomes larger. Eventually when $T \to \infty$, $\mathbf{x}_T$ is equivalent to an isotropic Gaussian distribution.

![The Markov chain of forward (reverse) diffusion process of generating a sample by slowly adding (removing) noise. (Image source: Ho et al. 2020 with a few additional annotations)](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/DDPM.png)

上述过程的一个很好的特性是，我们可以使用$\mathbf{x}_t$在任意时间步$t$以封闭形式采样[重参数化技巧](https://lilianweng.github.io/posts/2018-08-12-vae/#reparameterization-trick)。令$\alpha_t = 1 - \beta_t$和$\bar{\alpha}_t = \prod_{i=1}^t \alpha_i$：

> A nice property of the above process is that we can sample $\mathbf{x}_t$ at any arbitrary time step $t$ in a closed form using [reparameterization trick](https://lilianweng.github.io/posts/2018-08-12-vae/#reparameterization-trick). Let $\alpha_t = 1 - \beta_t$ and $\bar{\alpha}_t = \prod_{i=1}^t \alpha_i$:

$$
\begin{aligned}
\mathbf{x}_t 
&= \sqrt{\alpha_t}\mathbf{x}_{t-1} + \sqrt{1 - \alpha_t}\boldsymbol{\epsilon}_{t-1} & \text{ ;where } \boldsymbol{\epsilon}_{t-1}, \boldsymbol{\epsilon}_{t-2}, \dots \sim \mathcal{N}(\mathbf{0}, \mathbf{I}) \\
&= \sqrt{\alpha_t \alpha_{t-1}} \mathbf{x}_{t-2} + \sqrt{1 - \alpha_t \alpha_{t-1}} \bar{\boldsymbol{\epsilon}}_{t-2} & \text{ ;where } \bar{\boldsymbol{\epsilon}}_{t-2} \text{ merges two Gaussians (*).} \\
&= \dots \\
&= \sqrt{\bar{\alpha}_t}\mathbf{x}_0 + \sqrt{1 - \bar{\alpha}_t}\boldsymbol{\epsilon} \\
q(\mathbf{x}_t \vert \mathbf{x}_0) &= \mathcal{N}(\mathbf{x}_t; \sqrt{\bar{\alpha}_t} \mathbf{x}_0, (1 - \bar{\alpha}_t)\mathbf{I})
\end{aligned}
$$

(*) 回想一下，当我们合并两个方差不同的高斯分布时，$\mathcal{N}(\mathbf{0}, \sigma_1^2\mathbf{I})$ 和 $\mathcal{N}(\mathbf{0}, \sigma_2^2\mathbf{I})$，新的分布是 $\mathcal{N}(\mathbf{0}, (\sigma_1^2 + \sigma_2^2)\mathbf{I})$。这里合并后的标准差是 $\sqrt{(1 - \alpha_t) + \alpha_t (1-\alpha_{t-1})} = \sqrt{1 - \alpha_t\alpha_{t-1}}$。

> (*) Recall that when we merge two Gaussians  with different variance, $\mathcal{N}(\mathbf{0}, \sigma_1^2\mathbf{I})$ and $\mathcal{N}(\mathbf{0}, \sigma_2^2\mathbf{I})$, the new distribution is $\mathcal{N}(\mathbf{0}, (\sigma_1^2 + \sigma_2^2)\mathbf{I})$. Here the merged standard deviation is $\sqrt{(1 - \alpha_t) + \alpha_t (1-\alpha_{t-1})} = \sqrt{1 - \alpha_t\alpha_{t-1}}$.

通常，当样本噪声越大时，我们可以承受更大的更新步长，因此$\beta_1 < \beta_2 < \dots < \beta_T$以及因此$\bar{\alpha}_1 > \dots > \bar{\alpha}_T$。

> Usually, we can afford a larger update step when the sample gets noisier, so $\beta_1 < \beta_2 < \dots < \beta_T$ and therefore $\bar{\alpha}_1 > \dots > \bar{\alpha}_T$.

##### 与随机梯度朗之万动力学的联系

> Connection with stochastic gradient Langevin dynamics

朗之万动力学是物理学中的一个概念，用于对分子系统进行统计建模。结合随机梯度下降，*随机梯度朗之万动力学*([Welling & Teh 2011](https://www.stats.ox.ac.uk/~teh/research/compstats/WelTeh2011a.pdf))可以从概率密度$p(\mathbf{x})$中生成样本，仅使用更新的马尔可夫链中的梯度$\nabla_\mathbf{x} \log p(\mathbf{x})$：

> Langevin dynamics is a concept from physics, developed for statistically modeling molecular systems. Combined with stochastic gradient descent, *stochastic gradient Langevin dynamics* ([Welling & Teh 2011](https://www.stats.ox.ac.uk/~teh/research/compstats/WelTeh2011a.pdf)) can produce samples from a probability density $p(\mathbf{x})$ using only the gradients $\nabla_\mathbf{x} \log p(\mathbf{x})$ in a Markov chain of updates:

$$
\mathbf{x}_t = \mathbf{x}_{t-1} + \frac{\delta}{2} \nabla_\mathbf{x} \log p(\mathbf{x}_{t-1}) + \sqrt{\delta} \boldsymbol{\epsilon}_t
,\quad\text{where }
\boldsymbol{\epsilon}_t \sim \mathcal{N}(\mathbf{0}, \mathbf{I})
$$

其中 $\delta$ 是步长。当 $T \to \infty, \epsilon \to 0$ 时，$\mathbf{x}_T$ 等于真实的概率密度 $p(\mathbf{x})$。

> where $\delta$ is the step size. When $T \to \infty, \epsilon \to 0$, $\mathbf{x}_T$ equals to the true probability density $p(\mathbf{x})$.

与标准 SGD 相比，随机梯度朗之万动力学在参数更新中注入高斯噪声，以避免陷入局部最小值。

> Compared to standard SGD, stochastic gradient Langevin dynamics injects Gaussian noise into the parameter updates to avoid collapses into local minima.

#### 逆向扩散过程

> Reverse diffusion process

如果我们能逆转上述过程并从 $q(\mathbf{x}_{t-1} \vert \mathbf{x}_t)$ 中采样，我们将能够从高斯噪声输入 $\mathbf{x}_T \sim \mathcal{N}(\mathbf{0}, \mathbf{I})$ 中重新创建真实样本。请注意，如果 $\beta_t$ 足够小，$q(\mathbf{x}_{t-1} \vert \mathbf{x}_t)$ 也将是高斯分布的。不幸的是，我们无法轻易估计 $q(\mathbf{x}_{t-1} \vert \mathbf{x}_t)$，因为它需要使用整个数据集，因此我们需要学习一个模型 $p_\theta$ 来近似这些条件概率，以便运行 *逆向扩散过程*。

> If we can reverse the above process and sample from $q(\mathbf{x}_{t-1} \vert \mathbf{x}_t)$, we will be able to recreate the true sample from a Gaussian noise input, $\mathbf{x}_T \sim \mathcal{N}(\mathbf{0}, \mathbf{I})$. Note that if $\beta_t$ is small enough, $q(\mathbf{x}_{t-1} \vert \mathbf{x}_t)$ will also be Gaussian. Unfortunately, we cannot easily estimate $q(\mathbf{x}_{t-1} \vert \mathbf{x}_t)$ because it needs to use the entire dataset and therefore we need to learn a model $p_\theta$ to approximate these conditional probabilities in order to run the *reverse diffusion process*.

$$
p_\theta(\mathbf{x}_{0:T}) = p(\mathbf{x}_T) \prod^T_{t=1} p_\theta(\mathbf{x}_{t-1} \vert \mathbf{x}_t) \quad
p_\theta(\mathbf{x}_{t-1} \vert \mathbf{x}_t) = \mathcal{N}(\mathbf{x}_{t-1}; \boldsymbol{\mu}_\theta(\mathbf{x}_t, t), \boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t))
$$

![An example of training a diffusion model for modeling a 2D swiss roll data. (Image source: Sohl-Dickstein et al., 2015 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/diffusion-example.png)

值得注意的是，当以 $\mathbf{x}_0$ 为条件时，逆向条件概率是可处理的：

> It is noteworthy that the reverse conditional probability is tractable when conditioned on $\mathbf{x}_0$:

$$
q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0) = \mathcal{N}(\mathbf{x}_{t-1}; \color{blue}{\tilde{\boldsymbol{\mu}}}(\mathbf{x}_t, \mathbf{x}_0), \color{red}{\tilde{\beta}_t} \mathbf{I})
$$

使用贝叶斯法则，我们得到：

> Using Bayes’ rule, we have:

$$
\begin{aligned}
q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0) 
&= q(\mathbf{x}_t \vert \mathbf{x}_{t-1}, \mathbf{x}_0) \frac{ q(\mathbf{x}_{t-1} \vert \mathbf{x}_0) }{ q(\mathbf{x}_t \vert \mathbf{x}_0) } \\
&\propto \exp \Big(-\frac{1}{2} \big(\frac{(\mathbf{x}_t - \sqrt{\alpha_t} \mathbf{x}_{t-1})^2}{\beta_t} + \frac{(\mathbf{x}_{t-1} - \sqrt{\bar{\alpha}_{t-1}} \mathbf{x}_0)^2}{1-\bar{\alpha}_{t-1}} - \frac{(\mathbf{x}_t - \sqrt{\bar{\alpha}_t} \mathbf{x}_0)^2}{1-\bar{\alpha}_t} \big) \Big) \\
&= \exp \Big(-\frac{1}{2} \big(\frac{\mathbf{x}_t^2 - 2\sqrt{\alpha_t} \mathbf{x}_t \color{blue}{\mathbf{x}_{t-1}} \color{black}{+ \alpha_t} \color{red}{\mathbf{x}_{t-1}^2} }{\beta_t} + \frac{ \color{red}{\mathbf{x}_{t-1}^2} \color{black}{- 2 \sqrt{\bar{\alpha}_{t-1}} \mathbf{x}_0} \color{blue}{\mathbf{x}_{t-1}} \color{black}{+ \bar{\alpha}_{t-1} \mathbf{x}_0^2}  }{1-\bar{\alpha}_{t-1}} - \frac{(\mathbf{x}_t - \sqrt{\bar{\alpha}_t} \mathbf{x}_0)^2}{1-\bar{\alpha}_t} \big) \Big) \\
&= \exp\Big( -\frac{1}{2} \big( \color{red}{(\frac{\alpha_t}{\beta_t} + \frac{1}{1 - \bar{\alpha}_{t-1}})} \mathbf{x}_{t-1}^2 - \color{blue}{(\frac{2\sqrt{\alpha_t}}{\beta_t} \mathbf{x}_t + \frac{2\sqrt{\bar{\alpha}_{t-1}}}{1 - \bar{\alpha}_{t-1}} \mathbf{x}_0)} \mathbf{x}_{t-1} \color{black}{ + C(\mathbf{x}_t, \mathbf{x}_0) \big) \Big)}
\end{aligned}
$$

其中 $C(\mathbf{x}_t, \mathbf{x}_0)$ 是一个不涉及 $\mathbf{x}_{t-1}$ 的函数，具体细节已省略。根据标准高斯密度函数，均值和方差可以参数化如下（回想一下 $\alpha_t = 1 - \beta_t$ 和 $\bar{\alpha}_t = \prod_{i=1}^t \alpha_i$）：

> where $C(\mathbf{x}_t, \mathbf{x}_0)$ is some function not involving $\mathbf{x}_{t-1}$ and details are omitted. Following the standard Gaussian density function, the mean and variance can be parameterized as follows (recall that $\alpha_t = 1 - \beta_t$ and $\bar{\alpha}_t = \prod_{i=1}^t \alpha_i$):

$$
\begin{aligned}
\tilde{\beta}_t 
&= 1/(\frac{\alpha_t}{\beta_t} + \frac{1}{1 - \bar{\alpha}_{t-1}}) 
= 1/(\frac{\alpha_t - \bar{\alpha}_t + \beta_t}{\beta_t(1 - \bar{\alpha}_{t-1})})
= \color{green}{\frac{1 - \bar{\alpha}_{t-1}}{1 - \bar{\alpha}_t} \cdot \beta_t} \\
\tilde{\boldsymbol{\mu}}_t (\mathbf{x}_t, \mathbf{x}_0)
&= (\frac{\sqrt{\alpha_t}}{\beta_t} \mathbf{x}_t + \frac{\sqrt{\bar{\alpha}_{t-1} }}{1 - \bar{\alpha}_{t-1}} \mathbf{x}_0)/(\frac{\alpha_t}{\beta_t} + \frac{1}{1 - \bar{\alpha}_{t-1}}) \\
&= (\frac{\sqrt{\alpha_t}}{\beta_t} \mathbf{x}_t + \frac{\sqrt{\bar{\alpha}_{t-1} }}{1 - \bar{\alpha}_{t-1}} \mathbf{x}_0) \color{green}{\frac{1 - \bar{\alpha}_{t-1}}{1 - \bar{\alpha}_t} \cdot \beta_t} \\
&= \frac{\sqrt{\alpha_t}(1 - \bar{\alpha}_{t-1})}{1 - \bar{\alpha}_t} \mathbf{x}_t + \frac{\sqrt{\bar{\alpha}_{t-1}}\beta_t}{1 - \bar{\alpha}_t} \mathbf{x}_0\\
\end{aligned}
$$

由于 [良好特性](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#nice)，我们可以表示 $\mathbf{x}_0 = \frac{1}{\sqrt{\bar{\alpha}_t}}(\mathbf{x}_t - \sqrt{1 - \bar{\alpha}_t}\boldsymbol{\epsilon}_t)$ 并将其代入上述方程，得到：

> Thanks to the [nice property](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#nice), we can represent $\mathbf{x}_0 = \frac{1}{\sqrt{\bar{\alpha}_t}}(\mathbf{x}_t - \sqrt{1 - \bar{\alpha}_t}\boldsymbol{\epsilon}_t)$ and plug it into the above equation and obtain:

$$
\begin{aligned}
\tilde{\boldsymbol{\mu}}_t
&= \frac{\sqrt{\alpha_t}(1 - \bar{\alpha}_{t-1})}{1 - \bar{\alpha}_t} \mathbf{x}_t + \frac{\sqrt{\bar{\alpha}_{t-1}}\beta_t}{1 - \bar{\alpha}_t} \frac{1}{\sqrt{\bar{\alpha}_t}}(\mathbf{x}_t - \sqrt{1 - \bar{\alpha}_t}\boldsymbol{\epsilon}_t) \\
&= \color{cyan}{\frac{1}{\sqrt{\alpha_t}} \Big( \mathbf{x}_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_t \Big)}
\end{aligned}
$$

如图2所示，这种设置与[VAE](https://lilianweng.github.io/posts/2018-08-12-vae/)非常相似，因此我们可以使用变分下界来优化负对数似然。

> As demonstrated in Fig. 2., such a setup is very similar to [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/) and thus we can use the variational lower bound to optimize the negative log-likelihood.

$$
\begin{aligned}
- \log p_\theta(\mathbf{x}_0) 
&\leq - \log p_\theta(\mathbf{x}_0) + D_\text{KL}(q(\mathbf{x}_{1:T}\vert\mathbf{x}_0) \| p_\theta(\mathbf{x}_{1:T}\vert\mathbf{x}_0) ) & \small{\text{; KL is non-negative}}\\
&= - \log p_\theta(\mathbf{x}_0) + \mathbb{E}_{\mathbf{x}_{1:T}\sim q(\mathbf{x}_{1:T} \vert \mathbf{x}_0)} \Big[ \log\frac{q(\mathbf{x}_{1:T}\vert\mathbf{x}_0)}{p_\theta(\mathbf{x}_{0:T}) / p_\theta(\mathbf{x}_0)} \Big] \\
&= - \log p_\theta(\mathbf{x}_0) + \mathbb{E}_q \Big[ \log\frac{q(\mathbf{x}_{1:T}\vert\mathbf{x}_0)}{p_\theta(\mathbf{x}_{0:T})} + \log p_\theta(\mathbf{x}_0) \Big] \\
&= \mathbb{E}_q \Big[ \log \frac{q(\mathbf{x}_{1:T}\vert\mathbf{x}_0)}{p_\theta(\mathbf{x}_{0:T})} \Big] \\
\text{Let }L_\text{VLB} 
&= \mathbb{E}_{q(\mathbf{x}_{0:T})} \Big[ \log \frac{q(\mathbf{x}_{1:T}\vert\mathbf{x}_0)}{p_\theta(\mathbf{x}_{0:T})} \Big] \geq - \mathbb{E}_{q(\mathbf{x}_0)} \log p_\theta(\mathbf{x}_0)
\end{aligned}
$$

使用詹森不等式也很容易得到相同的结果。假设我们想将交叉熵作为学习目标进行最小化，

> It is also straightforward to get the same result using Jensen’s inequality. Say we want to minimize the cross entropy as the learning objective,

$$
\begin{aligned}
L_\text{CE}
&= - \mathbb{E}_{q(\mathbf{x}_0)} \log p_\theta(\mathbf{x}_0) \\
&= - \mathbb{E}_{q(\mathbf{x}_0)} \log \Big( \int p_\theta(\mathbf{x}_{0:T}) d\mathbf{x}_{1:T} \Big) \\
&= - \mathbb{E}_{q(\mathbf{x}_0)} \log \Big( \int q(\mathbf{x}_{1:T} \vert \mathbf{x}_0) \frac{p_\theta(\mathbf{x}_{0:T})}{q(\mathbf{x}_{1:T} \vert \mathbf{x}_{0})} d\mathbf{x}_{1:T} \Big) \\
&= - \mathbb{E}_{q(\mathbf{x}_0)} \log \Big( \mathbb{E}_{q(\mathbf{x}_{1:T} \vert \mathbf{x}_0)} \frac{p_\theta(\mathbf{x}_{0:T})}{q(\mathbf{x}_{1:T} \vert \mathbf{x}_{0})} \Big) \\
&\leq - \mathbb{E}_{q(\mathbf{x}_{0:T})} \log \frac{p_\theta(\mathbf{x}_{0:T})}{q(\mathbf{x}_{1:T} \vert \mathbf{x}_{0})} \\
&= \mathbb{E}_{q(\mathbf{x}_{0:T})}\Big[\log \frac{q(\mathbf{x}_{1:T} \vert \mathbf{x}_{0})}{p_\theta(\mathbf{x}_{0:T})} \Big] = L_\text{VLB}
\end{aligned}
$$

为了将方程中的每一项转换为可解析计算的形式，目标函数可以进一步重写为几个KL散度和熵项的组合（详细的分步过程请参见[Sohl-Dickstein et al., 2015](https://arxiv.org/abs/1503.03585)的附录B）：

> To convert each term in the equation to be analytically computable, the objective can be further rewritten to be a combination of several KL-divergence and entropy terms (See the detailed step-by-step process in Appendix B in [Sohl-Dickstein et al., 2015](https://arxiv.org/abs/1503.03585)):

$$
\begin{aligned}
L_\text{VLB} 
&= \mathbb{E}_{q(\mathbf{x}_{0:T})} \Big[ \log\frac{q(\mathbf{x}_{1:T}\vert\mathbf{x}_0)}{p_\theta(\mathbf{x}_{0:T})} \Big] \\
&= \mathbb{E}_q \Big[ \log\frac{\prod_{t=1}^T q(\mathbf{x}_t\vert\mathbf{x}_{t-1})}{ p_\theta(\mathbf{x}_T) \prod_{t=1}^T p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t) } \Big] \\
&= \mathbb{E}_q \Big[ -\log p_\theta(\mathbf{x}_T) + \sum_{t=1}^T \log \frac{q(\mathbf{x}_t\vert\mathbf{x}_{t-1})}{p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t)} \Big] \\
&= \mathbb{E}_q \Big[ -\log p_\theta(\mathbf{x}_T) + \sum_{t=2}^T \log \frac{q(\mathbf{x}_t\vert\mathbf{x}_{t-1})}{p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t)} + \log\frac{q(\mathbf{x}_1 \vert \mathbf{x}_0)}{p_\theta(\mathbf{x}_0 \vert \mathbf{x}_1)} \Big] \\
&= \mathbb{E}_q \Big[ -\log p_\theta(\mathbf{x}_T) + \sum_{t=2}^T \log \Big( \frac{q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0)}{p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t)}\cdot \frac{q(\mathbf{x}_t \vert \mathbf{x}_0)}{q(\mathbf{x}_{t-1}\vert\mathbf{x}_0)} \Big) + \log \frac{q(\mathbf{x}_1 \vert \mathbf{x}_0)}{p_\theta(\mathbf{x}_0 \vert \mathbf{x}_1)} \Big] \\
&= \mathbb{E}_q \Big[ -\log p_\theta(\mathbf{x}_T) + \sum_{t=2}^T \log \frac{q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0)}{p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t)} + \sum_{t=2}^T \log \frac{q(\mathbf{x}_t \vert \mathbf{x}_0)}{q(\mathbf{x}_{t-1} \vert \mathbf{x}_0)} + \log\frac{q(\mathbf{x}_1 \vert \mathbf{x}_0)}{p_\theta(\mathbf{x}_0 \vert \mathbf{x}_1)} \Big] \\
&= \mathbb{E}_q \Big[ -\log p_\theta(\mathbf{x}_T) + \sum_{t=2}^T \log \frac{q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0)}{p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t)} + \log\frac{q(\mathbf{x}_T \vert \mathbf{x}_0)}{q(\mathbf{x}_1 \vert \mathbf{x}_0)} + \log \frac{q(\mathbf{x}_1 \vert \mathbf{x}_0)}{p_\theta(\mathbf{x}_0 \vert \mathbf{x}_1)} \Big]\\
&= \mathbb{E}_q \Big[ \log\frac{q(\mathbf{x}_T \vert \mathbf{x}_0)}{p_\theta(\mathbf{x}_T)} + \sum_{t=2}^T \log \frac{q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0)}{p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t)} - \log p_\theta(\mathbf{x}_0 \vert \mathbf{x}_1) \Big] \\
&= \mathbb{E}_q [\underbrace{D_\text{KL}(q(\mathbf{x}_T \vert \mathbf{x}_0) \parallel p_\theta(\mathbf{x}_T))}_{L_T} + \sum_{t=2}^T \underbrace{D_\text{KL}(q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0) \parallel p_\theta(\mathbf{x}_{t-1} \vert\mathbf{x}_t))}_{L_{t-1}} \underbrace{- \log p_\theta(\mathbf{x}_0 \vert \mathbf{x}_1)}_{L_0} ]
\end{aligned}
$$

让我们分别标记变分下界损失中的每个组成部分：

> Let’s label each component in the variational lower bound loss separately:

$$
\begin{aligned}
L_\text{VLB} &= L_T + L_{T-1} + \dots + L_0 \\
\text{where } L_T &= D_\text{KL}(q(\mathbf{x}_T \vert \mathbf{x}_0) \parallel p_\theta(\mathbf{x}_T)) \\
L_t &= D_\text{KL}(q(\mathbf{x}_t \vert \mathbf{x}_{t+1}, \mathbf{x}_0) \parallel p_\theta(\mathbf{x}_t \vert\mathbf{x}_{t+1})) \text{ for }1 \leq t \leq T-1 \\
L_0 &= - \log p_\theta(\mathbf{x}_0 \vert \mathbf{x}_1)
\end{aligned}
$$

$L_\text{VLB}$中的每个KL项（除了$L_0$）都比较两个高斯分布，因此它们可以用[封闭形式](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence#Multivariate_normal_distributions)计算。$L_T$是常数，在训练期间可以忽略，因为$q$没有可学习参数，并且$\mathbf{x}_T$是高斯噪声。[Ho et al. 2020](https://arxiv.org/abs/2006.11239)使用一个单独的离散解码器对$L_0$进行建模，该解码器源自$\mathcal{N}(\mathbf{x}_0; \boldsymbol{\mu}_\theta(\mathbf{x}_1, 1), \boldsymbol{\Sigma}_\theta(\mathbf{x}_1, 1))$。

> Every KL term in $L_\text{VLB}$ (except for $L_0$) compares two Gaussian distributions and therefore they can be computed in [closed form](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence#Multivariate_normal_distributions). $L_T$ is constant and can be ignored during training because $q$ has no learnable parameters and $\mathbf{x}_T$ is a Gaussian noise. [Ho et al. 2020](https://arxiv.org/abs/2006.11239) models $L_0$ using a separate discrete decoder derived from $\mathcal{N}(\mathbf{x}_0; \boldsymbol{\mu}_\theta(\mathbf{x}_1, 1), \boldsymbol{\Sigma}_\theta(\mathbf{x}_1, 1))$.

#### 训练损失的$L_t$参数化

> Parameterization of $L_t$ for Training Loss

回想一下，我们需要学习一个神经网络来近似逆向扩散过程中的条件概率分布，$p_\theta(\mathbf{x}_{t-1} \vert \mathbf{x}_t) = \mathcal{N}(\mathbf{x}_{t-1}; \boldsymbol{\mu}_\theta(\mathbf{x}_t, t), \boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t))$。我们希望训练$\boldsymbol{\mu}_\theta$来预测$\tilde{\boldsymbol{\mu}}_t = \frac{1}{\sqrt{\alpha_t}} \Big( \mathbf{x}_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_t \Big)$。因为$\mathbf{x}_t$在训练时作为输入可用，我们可以重新参数化高斯噪声项，使其预测$\boldsymbol{\epsilon}_t$从输入$\mathbf{x}_t$在时间步$t$：

> Recall that we need to learn a neural network to approximate the conditioned probability distributions in the reverse diffusion process, $p_\theta(\mathbf{x}_{t-1} \vert \mathbf{x}_t) = \mathcal{N}(\mathbf{x}_{t-1}; \boldsymbol{\mu}_\theta(\mathbf{x}_t, t), \boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t))$. We would like to train $\boldsymbol{\mu}_\theta$ to predict $\tilde{\boldsymbol{\mu}}_t = \frac{1}{\sqrt{\alpha_t}} \Big( \mathbf{x}_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_t \Big)$. Because $\mathbf{x}_t$ is available as input at training time, we can reparameterize the Gaussian noise term instead to make it predict $\boldsymbol{\epsilon}_t$ from the input $\mathbf{x}_t$ at time step $t$:

$$
\begin{aligned}
\boldsymbol{\mu}_\theta(\mathbf{x}_t, t) &= \color{cyan}{\frac{1}{\sqrt{\alpha_t}} \Big( \mathbf{x}_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) \Big)} \\
\text{Thus }\mathbf{x}_{t-1} &= \mathcal{N}(\mathbf{x}_{t-1}; \frac{1}{\sqrt{\alpha_t}} \Big( \mathbf{x}_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) \Big), \boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t))
\end{aligned}
$$

损失项 $L_t$ 被参数化以最小化与 $\tilde{\boldsymbol{\mu}}$ 的差异：

> The loss term $L_t$ is parameterized to minimize the difference from $\tilde{\boldsymbol{\mu}}$ :

$$
\begin{aligned}
L_t 
&= \mathbb{E}_{\mathbf{x}_0, \boldsymbol{\epsilon}} \Big[\frac{1}{2 \| \boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t) \|^2_2} \| \color{blue}{\tilde{\boldsymbol{\mu}}_t(\mathbf{x}_t, \mathbf{x}_0)} - \color{green}{\boldsymbol{\mu}_\theta(\mathbf{x}_t, t)} \|^2 \Big] \\
&= \mathbb{E}_{\mathbf{x}_0, \boldsymbol{\epsilon}} \Big[\frac{1}{2  \|\boldsymbol{\Sigma}_\theta \|^2_2} \| \color{blue}{\frac{1}{\sqrt{\alpha_t}} \Big( \mathbf{x}_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_t \Big)} - \color{green}{\frac{1}{\sqrt{\alpha_t}} \Big( \mathbf{x}_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\boldsymbol{\epsilon}}_\theta(\mathbf{x}_t, t) \Big)} \|^2 \Big] \\
&= \mathbb{E}_{\mathbf{x}_0, \boldsymbol{\epsilon}} \Big[\frac{ (1 - \alpha_t)^2 }{2 \alpha_t (1 - \bar{\alpha}_t) \| \boldsymbol{\Sigma}_\theta \|^2_2} \|\boldsymbol{\epsilon}_t - \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)\|^2 \Big] \\
&= \mathbb{E}_{\mathbf{x}_0, \boldsymbol{\epsilon}} \Big[\frac{ (1 - \alpha_t)^2 }{2 \alpha_t (1 - \bar{\alpha}_t) \| \boldsymbol{\Sigma}_\theta \|^2_2} \|\boldsymbol{\epsilon}_t - \boldsymbol{\epsilon}_\theta(\sqrt{\bar{\alpha}_t}\mathbf{x}_0 + \sqrt{1 - \bar{\alpha}_t}\boldsymbol{\epsilon}_t, t)\|^2 \Big] 
\end{aligned}
$$

##### 简化

> Simplification

根据经验，[Ho et al. (2020)](https://arxiv.org/abs/2006.11239) 发现使用一个忽略权重项的简化目标来训练扩散模型效果更好：

> Empirically, [Ho et al. (2020)](https://arxiv.org/abs/2006.11239) found that training the diffusion model works better with a simplified objective that ignores the weighting term:

$$
\begin{aligned}
L_t^\text{simple}
&= \mathbb{E}_{t \sim [1, T], \mathbf{x}_0, \boldsymbol{\epsilon}_t} \Big[\|\boldsymbol{\epsilon}_t - \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)\|^2 \Big] \\
&= \mathbb{E}_{t \sim [1, T], \mathbf{x}_0, \boldsymbol{\epsilon}_t} \Big[\|\boldsymbol{\epsilon}_t - \boldsymbol{\epsilon}_\theta(\sqrt{\bar{\alpha}_t}\mathbf{x}_0 + \sqrt{1 - \bar{\alpha}_t}\boldsymbol{\epsilon}_t, t)\|^2 \Big]
\end{aligned}
$$

最终的简化目标是：

> The final simple objective is:

$$
L_\text{simple} = L_t^\text{simple} + C
$$

其中 $C$ 是一个不依赖于 $\theta$ 的常数。

> where $C$ is a constant not depending on $\theta$.

![The training and sampling algorithms in DDPM (Image source: Ho et al. 2020 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/DDPM-algo.png)

##### 与噪声条件分数网络 (NCSN) 的联系

> Connection with noise-conditioned score networks (NCSN)

[Song & Ermon (2019)](https://arxiv.org/abs/1907.05600) 提出了一种基于分数的生成建模方法，其中样本通过 [Langevin 动力学](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#connection-with-stochastic-gradient-langevin-dynamics) 生成，使用通过分数匹配估计的数据分布梯度。每个样本 $\mathbf{x}$ 的密度概率分数定义为其梯度 $\nabla_{\mathbf{x}} \log q(\mathbf{x})$。一个分数网络 $\mathbf{s}_\theta: \mathbb{R}^D \to \mathbb{R}^D$ 被训练来估计它，$\mathbf{s}_\theta(\mathbf{x}) \approx \nabla_{\mathbf{x}} \log q(\mathbf{x})$。

> [Song & Ermon (2019)](https://arxiv.org/abs/1907.05600) proposed a score-based generative modeling method where samples are produced via [Langevin dynamics](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#connection-with-stochastic-gradient-langevin-dynamics) using gradients of the data distribution estimated with score matching. The score of each sample $\mathbf{x}$’s density probability is defined as its gradient $\nabla_{\mathbf{x}} \log q(\mathbf{x})$. A score network $\mathbf{s}_\theta: \mathbb{R}^D \to \mathbb{R}^D$ is trained to estimate it, $\mathbf{s}_\theta(\mathbf{x}) \approx \nabla_{\mathbf{x}} \log q(\mathbf{x})$.

为了使其在深度学习设置中能够扩展到高维数据，他们提出使用 *去噪分数匹配* ([Vincent, 2011](http://www.iro.umontreal.ca/~vincentp/Publications/smdae_techreport.pdf)) 或 *切片分数匹配* (使用随机投影；[Song et al., 2019](https://arxiv.org/abs/1905.07088))。去噪分数匹配向数据 $q(\tilde{\mathbf{x}} \vert \mathbf{x})$ 添加预先指定的小噪声，并使用分数匹配估计 $q(\tilde{\mathbf{x}})$。

> To make it scalable with high-dimensional data in the deep learning setting, they proposed to use either *denoising score matching* ([Vincent, 2011](http://www.iro.umontreal.ca/~vincentp/Publications/smdae_techreport.pdf)) or *sliced score matching* (use random projections; [Song et al., 2019](https://arxiv.org/abs/1905.07088)). Denosing score matching adds a pre-specified small noise to the data $q(\tilde{\mathbf{x}} \vert \mathbf{x})$ and estimates $q(\tilde{\mathbf{x}})$ with score matching.

回想一下，Langevin 动力学可以在迭代过程中仅使用分数 $\nabla_{\mathbf{x}} \log q(\mathbf{x})$ 从概率密度分布中采样数据点。

> Recall that Langevin dynamics can sample data points from a probability density distribution using only the score $\nabla_{\mathbf{x}} \log q(\mathbf{x})$ in an iterative process.

然而，根据流形假设，大多数数据预计会集中在低维流形中，尽管观测到的数据可能看起来是任意高维的。这给分数估计带来了负面影响，因为数据点无法覆盖整个空间。在数据密度低的区域，分数估计的可靠性较低。在添加少量高斯噪声以使扰动数据分布覆盖整个空间 $\mathbb{R}^D$ 后，分数估计器网络的训练变得更加稳定。[Song & Ermon (2019)](https://arxiv.org/abs/1907.05600) 通过用 *不同级别* 的噪声扰动数据，并训练一个噪声条件分数网络来 *联合* 估计所有不同噪声级别下扰动数据的分数，从而改进了这一点。

> However, according to the manifold hypothesis, most of the data is expected to concentrate in a low dimensional manifold, even though the observed data might look only arbitrarily high-dimensional. It brings a negative effect on score estimation since the data points cannot cover the whole space. In regions where data density is low, the score estimation is less reliable. After adding a small Gaussian noise to make the perturbed data distribution cover the full space $\mathbb{R}^D$, the training of the score estimator network becomes more stable. [Song & Ermon (2019)](https://arxiv.org/abs/1907.05600) improved it by perturbing the data with the noise of *different levels* and train a noise-conditioned score network to *jointly* estimate the scores of all the perturbed data at different noise levels.

增加噪声水平的调度类似于前向扩散过程。如果我们使用扩散过程的注释，分数近似于 $\mathbf{s}_\theta(\mathbf{x}_t, t) \approx \nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t)$。给定一个高斯分布 $\mathbf{x} \sim \mathcal{N}(\mathbf{\mu}, \sigma^2 \mathbf{I})$，我们可以将其密度函数对数的导数写为 $\nabla_{\mathbf{x}}\log p(\mathbf{x}) = \nabla_{\mathbf{x}} \Big(-\frac{1}{2\sigma^2}(\mathbf{x} - \boldsymbol{\mu})^2 \Big) = - \frac{\mathbf{x} - \boldsymbol{\mu}}{\sigma^2} = - \frac{\boldsymbol{\epsilon}}{\sigma}$，其中 $\boldsymbol{\epsilon} \sim \mathcal{N}(\boldsymbol{0}, \mathbf{I})$。[回想一下](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#nice)，$q(\mathbf{x}_t \vert \mathbf{x}_0) \sim \mathcal{N}(\sqrt{\bar{\alpha}_t} \mathbf{x}_0, (1 - \bar{\alpha}_t)\mathbf{I})$，因此，

> The schedule of increasing noise levels resembles the forward diffusion process. If we use the diffusion process annotation, the score approximates $\mathbf{s}_\theta(\mathbf{x}_t, t) \approx \nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t)$. Given a Gaussian distribution $\mathbf{x} \sim \mathcal{N}(\mathbf{\mu}, \sigma^2 \mathbf{I})$, we can write the derivative of the logarithm of its density function as $\nabla_{\mathbf{x}}\log p(\mathbf{x}) = \nabla_{\mathbf{x}} \Big(-\frac{1}{2\sigma^2}(\mathbf{x} - \boldsymbol{\mu})^2 \Big) = - \frac{\mathbf{x} - \boldsymbol{\mu}}{\sigma^2} = - \frac{\boldsymbol{\epsilon}}{\sigma}$ where $\boldsymbol{\epsilon} \sim \mathcal{N}(\boldsymbol{0}, \mathbf{I})$. [Recall](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#nice) that $q(\mathbf{x}_t \vert \mathbf{x}_0) \sim \mathcal{N}(\sqrt{\bar{\alpha}_t} \mathbf{x}_0, (1 - \bar{\alpha}_t)\mathbf{I})$ and therefore,

$$
\mathbf{s}_\theta(\mathbf{x}_t, t) 
\approx \nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t)
= \mathbb{E}_{q(\mathbf{x}_0)} [\nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t \vert \mathbf{x}_0)]
= \mathbb{E}_{q(\mathbf{x}_0)} \Big[ - \frac{\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)}{\sqrt{1 - \bar{\alpha}_t}} \Big]
= - \frac{\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)}{\sqrt{1 - \bar{\alpha}_t}}
$$

#### $\beta_t$ 的参数化

> Parameterization of $\beta_t$

在 [Ho et al. (2020)](https://arxiv.org/abs/2006.11239) 中，前向方差被设置为一系列线性增加的常数，从 $\beta_1=10^{-4}$ 到 $\beta_T=0.02$。与 $[-1, 1]$ 之间的归一化图像像素值相比，它们相对较小。扩散模型在他们的实验中展示了高质量的样本，但仍未能达到与其他生成模型相当的模型对数似然。

> The forward variances are set to be a sequence of linearly increasing constants in [Ho et al. (2020)](https://arxiv.org/abs/2006.11239), from $\beta_1=10^{-4}$ to $\beta_T=0.02$. They are relatively small compared to the normalized image pixel values between $[-1, 1]$. Diffusion models in their experiments showed high-quality samples but still could not achieve competitive model log-likelihood as other generative models.

[Nichol & Dhariwal (2021)](https://arxiv.org/abs/2102.09672) 提出了几种改进技术，以帮助扩散模型获得更低的 NLL。其中一项改进是使用基于余弦的方差调度。调度函数的选择可以是任意的，只要它在训练过程的中间提供接近线性的下降，并在 $t=0$ 和 $t=T$ 附近提供细微的变化。

> [Nichol & Dhariwal (2021)](https://arxiv.org/abs/2102.09672) proposed several improvement techniques to help diffusion models to obtain lower NLL. One of the improvements is to use a cosine-based variance schedule. The choice of the scheduling function can be arbitrary, as long as it provides a near-linear drop in the middle of the training process and subtle changes around $t=0$ and $t=T$.

$$
\beta_t = \text{clip}(1-\frac{\bar{\alpha}_t}{\bar{\alpha}_{t-1}}, 0.999) \quad\bar{\alpha}_t = \frac{f(t)}{f(0)}\quad\text{where }f(t)=\cos\Big(\frac{t/T+s}{1+s}\cdot\frac{\pi}{2}\Big)^2
$$

其中小偏移量 $s$ 是为了防止 $\beta_t$ 在接近 $t=0$ 时变得过小。

> where the small offset $s$ is to prevent $\beta_t$ from being too small when close to $t=0$.

![Comparison of linear and cosine-based scheduling of $\beta\_t$ during training. (Image source: Nichol & Dhariwal, 2021 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/diffusion-beta.png)

#### 逆向过程方差 $\boldsymbol{\Sigma}_\theta$ 的参数化

> Parameterization of reverse process variance $\boldsymbol{\Sigma}_\theta$

[Ho 等人 (2020)](https://arxiv.org/abs/2006.11239) 选择将 $\beta_t$ 固定为常数，而不是让它们可学习，并设置 $\boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t) = \sigma^2_t \mathbf{I}$ ，其中 $\sigma_t$ 不学习，而是设置为 $\beta_t$ 或 $\tilde{\beta}_t = \frac{1 - \bar{\alpha}_{t-1}}{1 - \bar{\alpha}_t} \cdot \beta_t$。因为他们发现学习对角方差 $\boldsymbol{\Sigma}_\theta$ 会导致训练不稳定和样本质量较差。

> [Ho et al. (2020)](https://arxiv.org/abs/2006.11239) chose to fix $\beta_t$ as constants instead of making them learnable and set $\boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t) = \sigma^2_t \mathbf{I}$ , where $\sigma_t$ is not learned but set to $\beta_t$ or $\tilde{\beta}_t = \frac{1 - \bar{\alpha}_{t-1}}{1 - \bar{\alpha}_t} \cdot \beta_t$. Because they found that learning a diagonal variance $\boldsymbol{\Sigma}_\theta$ leads to unstable training and poorer sample quality.

[Nichol & Dhariwal (2021)](https://arxiv.org/abs/2102.09672)提议学习$\boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t)$作为$\beta_t$和$\tilde{\beta}_t$之间的插值，通过模型预测一个混合向量$\mathbf{v}$：

> [Nichol & Dhariwal (2021)](https://arxiv.org/abs/2102.09672) proposed to learn $\boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t)$ as an interpolation between $\beta_t$ and $\tilde{\beta}_t$ by model predicting a mixing vector $\mathbf{v}$ :

$$
\boldsymbol{\Sigma}_\theta(\mathbf{x}_t, t) = \exp(\mathbf{v} \log \beta_t + (1-\mathbf{v}) \log \tilde{\beta}_t)
$$

然而，简单的目标函数$L_\text{simple}$不依赖于$\boldsymbol{\Sigma}_\theta$。为了增加这种依赖性，他们构建了一个混合目标函数$L_\text{hybrid} = L_\text{simple} + \lambda L_\text{VLB}$其中$\lambda=0.001$很小，并且在$\boldsymbol{\mu}_\theta$项中对$L_\text{VLB}$停止梯度，使得$L_\text{VLB}$仅指导$\boldsymbol{\Sigma}_\theta$的学习。经验上他们观察到$L_\text{VLB}$优化起来相当困难，这可能是由于梯度噪声造成的，因此他们提出使用$L_\text{VLB}$的时间平均平滑版本并结合重要性采样。

> However, the simple objective $L_\text{simple}$ does not depend on $\boldsymbol{\Sigma}_\theta$ . To add the dependency, they constructed a hybrid objective $L_\text{hybrid} = L_\text{simple} + \lambda L_\text{VLB}$ where $\lambda=0.001$ is small and stop gradient on $\boldsymbol{\mu}_\theta$ in the $L_\text{VLB}$ term such that $L_\text{VLB}$ only guides the learning of $\boldsymbol{\Sigma}_\theta$. Empirically they observed that $L_\text{VLB}$ is pretty challenging to optimize likely due to noisy gradients, so they proposed to use a time-averaging smoothed version of $L_\text{VLB}$ with importance sampling.

![Comparison of negative log-likelihood of improved DDPM with other likelihood-based generative models. NLL is reported in the unit of bits/dim. (Image source: Nichol & Dhariwal, 2021 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/improved-DDPM-nll.png)

### 条件生成

> Conditioned Generation

在对带有条件信息（例如ImageNet数据集）的图像进行生成模型训练时，通常会生成以类别标签或一段描述性文本为条件的样本。

> While training generative models on images with conditioning information such as ImageNet dataset, it is common to generate samples conditioned on class labels or a piece of descriptive text.

#### 分类器引导扩散

> Classifier Guided Diffusion

为了将类别信息明确地整合到扩散过程中，[Dhariwal & Nichol (2021)](https://arxiv.org/abs/2105.05233) 训练了一个分类器 $f_\phi(y \vert \mathbf{x}_t, t)$ 在噪声图像 $\mathbf{x}_t$ 上，并使用梯度 $\nabla_\mathbf{x} \log f_\phi(y \vert \mathbf{x}_t)$ 通过改变噪声预测来引导扩散采样过程朝向条件信息 $y$（例如目标类别标签）。\n[回想](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#score) $\nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t) = - \frac{1}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)$，我们可以将联合分布 $q(\mathbf{x}_t, y)$ 的分数函数写成如下形式，

> To explicit incorporate class information into the diffusion process, [Dhariwal & Nichol (2021)](https://arxiv.org/abs/2105.05233) trained a classifier $f_\phi(y \vert \mathbf{x}_t, t)$ on noisy image $\mathbf{x}_t$ and use gradients $\nabla_\mathbf{x} \log f_\phi(y \vert \mathbf{x}_t)$ to guide the diffusion sampling process toward the conditioning information $y$ (e.g. a target class label) by altering the noise prediction.
> [Recall](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#score) that $\nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t) = - \frac{1}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)$ and we can write the score function for the joint distribution $q(\mathbf{x}_t, y)$ as following,

$$
\begin{aligned}
\nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t, y)
&= \nabla_{\mathbf{x}_t} \log q(\mathbf{x}_t) + \nabla_{\mathbf{x}_t} \log q(y \vert \mathbf{x}_t) \\
&\approx - \frac{1}{\sqrt{1 - \bar{\alpha}_t}} \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) + \nabla_{\mathbf{x}_t} \log f_\phi(y \vert \mathbf{x}_t) \\
&= - \frac{1}{\sqrt{1 - \bar{\alpha}_t}} (\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) - \sqrt{1 - \bar{\alpha}_t} \nabla_{\mathbf{x}_t} \log f_\phi(y \vert \mathbf{x}_t))
\end{aligned}
$$

因此，一个新的分类器引导预测器 $\bar{\boldsymbol{\epsilon}}_\theta$ 将采取如下形式，

> Thus, a new classifier-guided predictor $\bar{\boldsymbol{\epsilon}}_\theta$ would take the form as following,

$$
\bar{\boldsymbol{\epsilon}}_\theta(\mathbf{x}_t, t) = \boldsymbol{\epsilon}_\theta(x_t, t) - \sqrt{1 - \bar{\alpha}_t} \nabla_{\mathbf{x}_t} \log f_\phi(y \vert \mathbf{x}_t)
$$

为了控制分类器引导的强度，我们可以在增量部分添加一个权重$w$，

> To control the strength of the classifier guidance, we can add a weight $w$ to the delta part,

$$
\bar{\boldsymbol{\epsilon}}_\theta(\mathbf{x}_t, t) = \boldsymbol{\epsilon}_\theta(x_t, t) - \sqrt{1 - \bar{\alpha}_t} \; w \nabla_{\mathbf{x}_t} \log f_\phi(y \vert \mathbf{x}_t)
$$

由此产生的*消融扩散模型*（**ADM**）以及带有额外分类器引导的模型（**ADM-G**）能够比SOTA生成模型（例如BigGAN）取得更好的结果。

> The resulting *ablated diffusion model* (**ADM**) and the one with additional classifier guidance (**ADM-G**) are able to achieve better results than SOTA generative models (e.g. BigGAN).

![The algorithms use guidance from a classifier to run conditioned generation with DDPM and DDIM. (Image source: Dhariwal & Nichol, 2021 \])](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/conditioned-DDPM.png)

此外，通过对U-Net架构进行一些修改，[Dhariwal & Nichol (2021)](https://arxiv.org/abs/2105.05233)展示了扩散模型优于GAN的性能。架构修改包括更大的模型深度/宽度、更多的注意力头、多分辨率注意力、用于上/下采样的BigGAN残差块、通过$1/\sqrt{2}$进行残差连接重缩放以及自适应组归一化（AdaGN）。

> Additionally with some modifications on the U-Net architecture, [Dhariwal & Nichol (2021)](https://arxiv.org/abs/2105.05233) showed performance better than GAN with diffusion models. The architecture modifications include larger model depth/width, more attention heads, multi-resolution attention, BigGAN residual blocks for up/downsampling, residual connection rescale by $1/\sqrt{2}$ and adaptive group normalization (AdaGN).

#### 无分类器引导

> Classifier-Free Guidance

在没有独立分类器$f_\phi$的情况下，仍然可以通过结合条件扩散模型和无条件扩散模型的得分来运行条件扩散步骤（[Ho & Salimans, 2021](https://openreview.net/forum?id=qw8AKxfYbI)）。设无条件去噪扩散模型$p_\theta(\mathbf{x})$通过得分估计器$\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)$参数化，条件模型$p_\theta(\mathbf{x} \vert y)$通过$\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y)$参数化。这两个模型可以通过单个神经网络学习。具体来说，条件扩散模型$p_\theta(\mathbf{x} \vert y)$在配对数据$(\mathbf{x}, y)$上进行训练，其中条件信息$y$会定期随机丢弃，以便模型也知道如何无条件生成图像，即$\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) = \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y=\varnothing)$。

> Without an independent classifier $f_\phi$, it is still possible to run conditional diffusion steps by incorporating the scores from a conditional and an unconditional diffusion model ([Ho & Salimans, 2021](https://openreview.net/forum?id=qw8AKxfYbI)). Let unconditional denoising diffusion model $p_\theta(\mathbf{x})$ parameterized through a score estimator $\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)$ and the conditional model $p_\theta(\mathbf{x} \vert y)$ parameterized through $\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y)$. These two models can be learned via a single neural network. Precisely, a conditional diffusion model $p_\theta(\mathbf{x} \vert y)$ is trained on paired data $(\mathbf{x}, y)$, where the conditioning information $y$ gets discarded periodically at random such that the model knows how to generate images unconditionally as well, i.e. $\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) = \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y=\varnothing)$.

隐式分类器的梯度可以用条件和无条件得分估计器表示。一旦将其插入到分类器引导的修改得分中，该得分就不再依赖于单独的分类器。

> The gradient of an implicit classifier can be represented with conditional and unconditional score estimators. Once plugged into the classifier-guided modified score, the score contains no dependency on a separate classifier.

$$
\begin{aligned}
\nabla_{\mathbf{x}_t} \log p(y \vert \mathbf{x}_t)
&= \nabla_{\mathbf{x}_t} \log p(\mathbf{x}_t \vert y) - \nabla_{\mathbf{x}_t} \log p(\mathbf{x}_t) \\
&= - \frac{1}{\sqrt{1 - \bar{\alpha}_t}}\Big( \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y) - \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) \Big) \\
\bar{\boldsymbol{\epsilon}}_\theta(\mathbf{x}_t, t, y)
&= \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y) - \sqrt{1 - \bar{\alpha}_t} \; w \nabla_{\mathbf{x}_t} \log p(y \vert \mathbf{x}_t) \\
&= \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y) + w \big(\boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y) - \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t) \big) \\
&= (w+1) \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t, y) - w \boldsymbol{\epsilon}_\theta(\mathbf{x}_t, t)
\end{aligned}
$$

他们的实验表明，无分类器引导可以在FID（区分合成图像和生成图像）和IS（质量和多样性）之间取得良好的平衡。

> Their experiments showed that classifier-free guidance can achieve a good balance between FID (distinguish between synthetic and generated images) and IS (quality and diversity).

引导扩散模型GLIDE（[Nichol, Dhariwal & Ramesh, et al. 2022](https://arxiv.org/abs/2112.10741)）探索了两种引导策略：CLIP引导和无分类器引导，并发现后者更受青睐。他们推测这是因为CLIP引导利用对抗性样本来针对CLIP模型，而不是优化生成更匹配的图像。

> The guided diffusion model, GLIDE ([Nichol, Dhariwal & Ramesh, et al. 2022](https://arxiv.org/abs/2112.10741)), explored both guiding strategies, CLIP guidance and classifier-free guidance, and found that the latter is more preferred. They hypothesized that it is because CLIP guidance exploits the model with adversarial examples towards the CLIP model, rather than optimize the better matched images generation.

### 加速扩散模型

> Speed up Diffusion Models

通过遵循逆向扩散过程的马尔可夫链从DDPM生成样本非常缓慢，因为$T$可能多达一千或几千步。来自[Song et al. (2020)](https://arxiv.org/abs/2010.02502)的一个数据点：“例如，从DDPM采样5万张32 × 32大小的图像大约需要20小时，但在Nvidia 2080 Ti GPU上从GAN采样则不到一分钟。”

> It is very slow to generate a sample from DDPM by following the Markov chain of the reverse diffusion process, as $T$ can be up to one or a few thousand steps. One data point from [Song et al. (2020)](https://arxiv.org/abs/2010.02502): “For example, it takes around 20 hours to sample 50k images of size 32 × 32 from a DDPM, but less than a minute to do so from a GAN on an Nvidia 2080 Ti GPU.”

#### 更少的采样步骤&蒸馏

> Fewer Sampling Steps & Distillation

一种简单的方法是运行分步采样调度（[Nichol & Dhariwal, 2021](https://arxiv.org/abs/2102.09672)），通过每$\lceil T/S \rceil$步进行采样更新，将过程从$T$减少到$S$步。新的生成采样调度是$\{\tau_1, \dots, \tau_S\}$，其中$\tau_1 < \tau_2 < \dots <\tau_S \in [1, T]$且$S < T$。

> One simple way is to run a strided sampling schedule ([Nichol & Dhariwal, 2021](https://arxiv.org/abs/2102.09672)) by taking the sampling update every $\lceil T/S \rceil$ steps to reduce the process from $T$ to $S$ steps. The new sampling schedule for generation is $\{\tau_1, \dots, \tau_S\}$  where $\tau_1 < \tau_2 < \dots <\tau_S \in [1, T]$ and $S < T$.

对于另一种方法，让我们重写$q_\sigma(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0)$以期望的标准差$\sigma_t$进行参数化，根据[良好特性](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#nice)：

> For another approach, let’s rewrite $q_\sigma(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0)$ to be parameterized by a desired standard deviation $\sigma_t$ according to the [nice property](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#nice):

$$
\begin{aligned}
\mathbf{x}_{t-1} 
&= \sqrt{\bar{\alpha}_{t-1}}\mathbf{x}_0 +  \sqrt{1 - \bar{\alpha}_{t-1}}\boldsymbol{\epsilon}_{t-1} & \\
&= \sqrt{\bar{\alpha}_{t-1}}\mathbf{x}_0 + \sqrt{1 - \bar{\alpha}_{t-1} - \sigma_t^2} \boldsymbol{\epsilon}_t + \sigma_t\boldsymbol{\epsilon} & \\
&= \sqrt{\bar{\alpha}_{t-1}} \Big( \frac{\mathbf{x}_t - \sqrt{1 - \bar{\alpha}_t} \epsilon^{(t)}_\theta(\mathbf{x}_t)}{\sqrt{\bar{\alpha}_t}} \Big) + \sqrt{1 - \bar{\alpha}_{t-1} - \sigma_t^2} \epsilon^{(t)}_\theta(\mathbf{x}_t) + \sigma_t\boldsymbol{\epsilon} \\
q_\sigma(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0)
&= \mathcal{N}(\mathbf{x}_{t-1}; \sqrt{\bar{\alpha}_{t-1}} \Big( \frac{\mathbf{x}_t - \sqrt{1 - \bar{\alpha}_t} \epsilon^{(t)}_\theta(\mathbf{x}_t)}{\sqrt{\bar{\alpha}_t}} \Big) + \sqrt{1 - \bar{\alpha}_{t-1} - \sigma_t^2} \epsilon^{(t)}_\theta(\mathbf{x}_t), \sigma_t^2 \mathbf{I})
\end{aligned}
$$

其中模型$\epsilon^{(t)}_\theta(.)$预测$\epsilon_t$来自$\mathbf{x}_t$。

> where the model $\epsilon^{(t)}_\theta(.)$ predicts the $\epsilon_t$ from $\mathbf{x}_t$.

回想一下，在$q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0) = \mathcal{N}(\mathbf{x}_{t-1}; \tilde{\boldsymbol{\mu}}(\mathbf{x}_t, \mathbf{x}_0), \tilde{\beta}_t \mathbf{I})$中，因此我们有：

> Recall that in $q(\mathbf{x}_{t-1} \vert \mathbf{x}_t, \mathbf{x}_0) = \mathcal{N}(\mathbf{x}_{t-1}; \tilde{\boldsymbol{\mu}}(\mathbf{x}_t, \mathbf{x}_0), \tilde{\beta}_t \mathbf{I})$, therefore we have:

$$
\tilde{\beta}_t = \sigma_t^2 = \frac{1 - \bar{\alpha}_{t-1}}{1 - \bar{\alpha}_t} \cdot \beta_t
$$

令$\sigma_t^2 = \eta \cdot \tilde{\beta}_t$，以便我们可以将$\eta \in \mathbb{R}^+$作为超参数来控制采样随机性。$\eta = 0$的特殊情况使采样过程*确定性的*。这种模型被称为*去噪扩散隐式模型* (**DDIM**; [Song et al., 2020](https://arxiv.org/abs/2010.02502))。DDIM 具有相同的边缘噪声分布，但确定性地将噪声映射回原始数据样本。

英文原文：Let 

$\sigma_t^2 = \eta \cdot \tilde{\beta}_t$ such that we can adjust 

$\eta \in \mathbb{R}^+$ as a hyperparameter to control the sampling stochasticity. The special case of 

$\eta = 0$ makes the sampling process *deterministic*. Such a model is named the *denoising diffusion implicit model* (DDIM; [Song et al., 2020](https://arxiv.org/abs/2010.02502)). DDIM has the same marginal noise distribution but deterministically maps noise back to the original data samples.

在生成过程中，我们不必遵循整个链条$t=1,\dots,T$，而只需遵循其中的一个子集步骤。我们把$s < t$表示为这个加速轨迹中的两个步骤。DDIM 更新步骤是：

> During generation, we don’t have to follow the whole chain $t=1,\dots,T$, but rather a subset of steps. Let’s denote $s < t$ as two steps in this accelerated trajectory. The DDIM update step is:

$$
q_{\sigma, s < t}(\mathbf{x}_s \vert \mathbf{x}_t, \mathbf{x}_0)
= \mathcal{N}(\mathbf{x}_s; \sqrt{\bar{\alpha}_s} \Big( \frac{\mathbf{x}_t - \sqrt{1 - \bar{\alpha}_t} \epsilon^{(t)}_\theta(\mathbf{x}_t)}{\sqrt{\bar{\alpha}_t}} \Big) + \sqrt{1 - \bar{\alpha}_s - \sigma_t^2} \epsilon^{(t)}_\theta(\mathbf{x}_t), \sigma_t^2 \mathbf{I})
$$

尽管所有模型都使用$T=1000$扩散步长进行训练，但他们观察到，当DDIM（$\eta=0$）在$S$较小时能生成最佳质量的样本，而DDPM（$\eta=1$）在较小的$S$上表现差得多。当我们可以运行完整的逆向马尔可夫扩散步长时，DDPM 的表现确实更好（$S=T=1000$）。使用DDIM，可以将扩散模型训练到任意数量的前向步长，但只从生成过程中的一部分步长进行采样。

> While all the models are trained with $T=1000$ diffusion steps in the experiments, they observed that DDIM ($\eta=0$) can produce the best quality samples when $S$ is small, while DDPM ($\eta=1$) performs much worse on small $S$. DDPM does perform better when we can afford to run the full reverse Markov diffusion steps ($S=T=1000$). With DDIM, it is possible to train the diffusion model up to any arbitrary number of forward steps but only sample from a subset of steps in the generative process.

![FID scores on CIFAR10 and CelebA datasets by diffusion models of different settings, including $\color{cyan}{\text{DDIM}}$ ($\eta=0$) and $\color{orange}{\text{DDPM}}$ ($\hat{\sigma}$). (Image source: Song et al., 2020 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/DDIM-results.png)

与 DDPM 相比，DDIM 能够：

> Compared to DDPM, DDIM is able to:

1. 使用更少的步骤生成更高质量的样本。
2. 具有“一致性”属性，因为生成过程是确定性的，这意味着以相同潜在变量为条件生成的多个样本应具有相似的高级特征。
3. 由于一致性，DDIM 可以在潜在变量中进行语义上有意义的插值。

> • Generate higher-quality samples using a much fewer number of steps.
> • Have “consistency” property since the generative process is deterministic, meaning that multiple samples conditioned on the same latent variable should have similar high-level features.
> • Because of the consistency, DDIM can do semantically meaningful interpolation in the latent variable.

![Progressive distillation can reduce the diffusion sampling steps by half in each iteration. (Image source: Salimans & Ho, 2022 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/progressive-distillation.png)

**渐进式蒸馏** ([Salimans & Ho, 2022](https://arxiv.org/abs/2202.00512)) 是一种将训练好的确定性采样器蒸馏成采样步数减半的新模型的方法。学生模型从教师模型初始化，并朝着一个目标去噪，即一个学生 DDIM 步长匹配 2 个教师步长，而不是使用原始样本 $\mathbf{x}_0$ 作为去噪目标。在每次渐进式蒸馏迭代中，我们可以将采样步数减半。

英文原文：Progressive Distillation ([Salimans & Ho, 2022](https://arxiv.org/abs/2202.00512)) is a method for distilling trained deterministic samplers into new models of halved sampling steps. The student model is initialized from the teacher model and denoises towards a target where one student DDIM step matches 2 teacher steps, instead of using the original sample 

$\mathbf{x}_0$ as the denoise target. In every progressive distillation iteration, we can half the sampling steps.

![Comparison of Algorithm 1 (diffusion model training) and Algorithm 2 (progressive distillation) side-by-side, where the relative changes in progressive distillation are highlighted in green. (Image source: Salimans & Ho, 2022 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/progressive-distillation-algo.png)

**一致性模型** ([Song et al. 2023](https://arxiv.org/abs/2303.01469)) 学习将扩散采样轨迹上的任何中间噪声数据点 $\mathbf{x}_t, t > 0$ 直接映射回其原点 $\mathbf{x}_0$。它被称为 *一致性* 模型，因为它具有 *自一致性* 属性，即同一轨迹上的任何数据点都被映射到相同的原点。

英文原文：Consistency Models ([Song et al. 2023](https://arxiv.org/abs/2303.01469)) learns to map any intermediate noisy data points 

$\mathbf{x}_t, t > 0$ on the diffusion sampling trajectory back to its origin 

$\mathbf{x}_0$ directly. It is named as *consistency* model because of its *self-consistency* property as any data points on the same trajectory is mapped to the same origin.

![Consistency models learn to map any data point on the trajectory back to its origin. (Image source: Song et al., 2023 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/consistency-models.png)

给定一条轨迹 $\{\mathbf{x}_t \vert t \in [\epsilon, T]\}$，*一致性函数* $f$ 定义为 $f: (\mathbf{x}_t, t) \mapsto \mathbf{x}_\epsilon$，并且方程 $f(\mathbf{x}_t, t) = f(\mathbf{x}_{t’}, t’) = \mathbf{x}_\epsilon$ 对所有 $t, t’ \in [\epsilon, T]$ 都成立。当 $t=\epsilon$ 时，$f$ 是一个恒等函数。该模型可以参数化如下，其中 $c_\text{skip}(t)$ 和 $c_\text{out}(t)$ 函数的设计方式使得 $c_\text{skip}(\epsilon) = 1, c_\text{out}(\epsilon) = 0$：

> Given a trajectory $\{\mathbf{x}_t \vert t \in [\epsilon, T]\}$ , the *consistency function* $f$ is defined as $f: (\mathbf{x}_t, t) \mapsto \mathbf{x}_\epsilon$ and the equation $f(\mathbf{x}_t, t) = f(\mathbf{x}_{t’}, t’) = \mathbf{x}_\epsilon$ holds true for all $t, t’ \in [\epsilon, T]$. When $t=\epsilon$, $f$ is an identify function. The model can be parameterized as follows, where $c_\text{skip}(t)$ and $c_\text{out}(t)$ functions are designed in a way that $c_\text{skip}(\epsilon) = 1, c_\text{out}(\epsilon) = 0$:

$$
f_\theta(\mathbf{x}, t) = c_\text{skip}(t)\mathbf{x} + c_\text{out}(t) F_\theta(\mathbf{x}, t)
$$

一致性模型可以在单一步骤中生成样本，同时仍能保持通过多步采样过程权衡计算量以获得更好质量的灵活性。

> It is possible for the consistency model to generate samples in a single step, while still maintaining the flexibility of trading computation for better quality following a multi-step sampling process.

该论文介绍了两种训练一致性模型的方法：

> The paper introduced two ways to train consistency models:

1\. 
**一致性蒸馏（CD）**：通过最小化同一轨迹生成的样本对之间模型输出的差异，将扩散模型蒸馏成一致性模型。这使得采样评估的成本大大降低。一致性蒸馏损失为：

其中



• $\Phi(.;\phi)$ 是一步 [ODE](https://en.wikipedia.org/wiki/Ordinary_differential_equation) 求解器的更新函数；



• $n \sim \mathcal{U}[1, N-1]$ 在 $1, \dots, N-1$ 上具有均匀分布；



• 网络参数 $\theta^-$ 是 $\theta$ 的 EMA 版本，这极大地稳定了训练（就像在 [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network) 或 [momentum](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2) 对比学习中一样）；



• $d(.,.)$ 是一个正距离度量函数，当且仅当满足 $\forall \mathbf{x}, \mathbf{y}: d(\mathbf{x}, \mathbf{y}) \geq 0$ 和 $d(\mathbf{x}, \mathbf{y}) = 0$，例如 $\mathbf{x} = \mathbf{y}$，$\ell_2$，$\ell_1$ 或 [LPIPS](https://arxiv.org/abs/1801.03924)（学习到的感知图像块相似度）距离；



• $\lambda(.) \in \mathbb{R}^+$ 是一个正加权函数，并且本文设置 $\lambda(t_n)=1$。

2\. **一致性训练 (CT)**: 另一种选择是独立训练一个一致性模型。请注意，在 CD 中，一个预训练的分数模型 $s_\phi(\mathbf{x}, t)$ 用于近似真实分数 $\nabla\log p_t(\mathbf{x})$，但在 CT 中，我们需要一种方法来估计这个分数函数，结果表明 $\nabla\log p_t(\mathbf{x})$ 的无偏估计器存在，形式为 $-\frac{\mathbf{x}_t - \mathbf{x}}{t^2}$。CT 损失定义如下：

英文原文：

1\. 
**Consistency Distillation (CD)**: Distill a diffusion model into a consistency model by minimizing the difference between model outputs for pairs generated out of the same trajectory. This enables a much cheaper sampling evaluation. The consistency distillation loss is:

where



• $\Phi(.;\phi)$ is the update function of a one-step [ODE](https://en.wikipedia.org/wiki/Ordinary_differential_equation) solver;



• $n \sim \mathcal{U}[1, N-1]$, has an uniform distribution over $1, \dots, N-1$;



• The network parameters $\theta^-$ is EMA version of $\theta$ which greatly stabilizes the training (just like in [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network) or [momentum](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2) contrastive learning);



• $d(.,.)$ is a positive distance metric function that satisfies $\forall \mathbf{x}, \mathbf{y}: d(\mathbf{x}, \mathbf{y}) \geq 0$ and $d(\mathbf{x}, \mathbf{y}) = 0$ if and only if $\mathbf{x} = \mathbf{y}$ such as $\ell_2$, $\ell_1$ or [LPIPS](https://arxiv.org/abs/1801.03924) (learned perceptual image patch similarity) distance;



• $\lambda(.) \in \mathbb{R}^+$ is a positive weighting function and the paper sets $\lambda(t_n)=1$.

2\. 
**Consistency Training (CT)**: The other option is to train a consistency model independently. Note that in CD, a pre-trained score model $s_\phi(\mathbf{x}, t)$ is used to approximate the ground truth score $\nabla\log p_t(\mathbf{x})$ but in CT we need a way to estimate this score function and it turns out an unbiased estimator of $\nabla\log p_t(\mathbf{x})$ exists as $-\frac{\mathbf{x}_t - \mathbf{x}}{t^2}$. The CT loss is defined as follows:


$$
\begin{aligned}
 \mathcal{L}^N_\text{CD} (\theta, \theta^-; \phi) &= \mathbb{E}
 [\lambda(t_n)d(f_\theta(\mathbf{x}_{t_{n+1}}, t_{n+1}), f_{\theta^-}(\hat{\mathbf{x}}^\phi_{t_n}, t_n)] \\
 \hat{\mathbf{x}}^\phi_{t_n} &= \mathbf{x}_{t_{n+1}} - (t_n - t_{n+1}) \Phi(\mathbf{x}_{t_{n+1}}, t_{n+1}; \phi)
 \end{aligned}
$$

$$
\mathcal{L}^N_\text{CT} (\theta, \theta^-; \phi) = \mathbb{E}
[\lambda(t_n)d(f_\theta(\mathbf{x} + t_{n+1} \mathbf{z},\;t_{n+1}), f_{\theta^-}(\mathbf{x} + t_n \mathbf{z},\;t_n)]
\text{ where }\mathbf{z} \in \mathcal{N}(\mathbf{0}, \mathbf{I})
$$

根据论文中的实验，他们发现，

> According to the experiments in the paper, they found,

• Heun ODE 求解器比 Euler 的一阶求解器效果更好，因为高阶 ODE 求解器在相同的 $N$ 下具有更小的估计误差。

• 在距离度量函数 $d(.)$ 的不同选项中，LPIPS 度量优于 $\ell_1$ 和 $\ell_2$ 距离。

• 较小的 $N$ 会导致更快的收敛但更差的样本，而较大的 $N$ 会导致更慢的收敛但在收敛时获得更好的样本。

英文原文：

• Heun ODE solver works better than Euler’s first-order solver, since higher order ODE solvers have smaller estimation errors with the same $N$.

• Among different options of the distance metric function $d(.)$, the LPIPS metric works better than $\ell_1$ and $\ell_2$ distance.

• Smaller $N$ leads to faster convergence but worse samples, whereas larger $N$ leads to slower convergence but better samples upon convergence.

![Comparison of consistency models' performance under different configurations. The best configuration for CD is LPIPS distance metric, Heun ODE solver, and $N=18$.  (Image source: Song et al., 2023 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/consistency-models-exp.png)

#### 潜在变量空间

> Latent Variable Space

*潜在扩散模型* (**LDM**; [Rombach & Blattmann, et al. 2022](https://arxiv.org/abs/2112.10752)) 在潜在空间而非像素空间中运行扩散过程，从而降低了训练成本并加快了推理速度。其动机是观察到图像的大部分比特贡献于感知细节，并且在激进压缩后语义和概念构成仍然保留。LDM 通过生成建模学习，大致将感知压缩和语义压缩分解开来，首先使用自编码器去除像素级冗余，然后通过在学习到的潜在空间上进行扩散过程来操纵/生成语义概念。

> *Latent diffusion model* (**LDM**; [Rombach & Blattmann, et al. 2022](https://arxiv.org/abs/2112.10752)) runs the diffusion process in the latent space instead of pixel space, making training cost lower and inference speed faster. It is motivated by the observation that most bits of an image contribute to perceptual details and the semantic and conceptual composition still remains after aggressive compression. LDM loosely decomposes the perceptual compression and semantic compression with generative modeling learning by first trimming off pixel-level redundancy with autoencoder and then manipulating / generating semantic concepts with diffusion process on learned latent.

![The plot for tradeoff between compression rate and distortion, illustrating two-stage compressions - perceptual and semantic compression. (Image source: Rombach & Blattmann, et al. 2022 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/image-distortion-rate.png)

感知压缩过程依赖于自编码器模型。编码器 $\mathcal{E}$ 用于将输入图像 $\mathbf{x} \in \mathbb{R}^{H \times W \times 3}$ 压缩成更小的二维潜在向量 $\mathbf{z} = \mathcal{E}(\mathbf{x}) \in \mathbb{R}^{h \times w \times c}$ ，其中下采样率 $f=H/h=W/w=2^m, m \in \mathbb{N}$。然后解码器 $\mathcal{D}$ 从潜在向量重建图像，$\tilde{\mathbf{x}} = \mathcal{D}(\mathbf{z})$。该论文探讨了自编码器训练中的两种正则化方法，以避免潜在空间中出现任意高方差。

> The perceptual compression process relies on an autoencoder model. An encoder $\mathcal{E}$ is used to compress the input image $\mathbf{x} \in \mathbb{R}^{H \times W \times 3}$ to a smaller 2D latent vector $\mathbf{z} = \mathcal{E}(\mathbf{x}) \in \mathbb{R}^{h \times w \times c}$ , where the downsampling rate $f=H/h=W/w=2^m, m \in \mathbb{N}$. Then an decoder $\mathcal{D}$ reconstructs the images from the latent vector, $\tilde{\mathbf{x}} = \mathcal{D}(\mathbf{z})$. The paper explored two types of regularization in autoencoder training to avoid arbitrarily high-variance in the latent spaces.

- *KL-reg*: 对学习到的潜在空间施加一个小的KL惩罚，使其趋向于标准正态分布，类似于 [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/)。
- *VQ-reg*: 使用解码器内的向量量化层，类似于[VQVAE](https://lilianweng.github.io/posts/2018-08-12-vae/#vq-vae-and-vq-vae-2)，但量化层被解码器吸收。

> • *KL-reg*: A small KL penalty towards a standard normal distribution over the learned latent, similar to [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/).
> • *VQ-reg*: Uses a vector quantization layer within the decoder, like [VQVAE](https://lilianweng.github.io/posts/2018-08-12-vae/#vq-vae-and-vq-vae-2) but the quantization layer is absorbed by the decoder.

扩散和去噪过程发生在潜在向量$\mathbf{z}$上。去噪模型是一个时间条件U-Net，通过交叉注意力机制增强，以处理用于图像生成的灵活条件信息（例如，类别标签、语义图、图像的模糊变体）。这种设计等同于通过交叉注意力机制将不同模态的表示融合到模型中。每种类型的条件信息都与一个领域特定的编码器$\tau_\theta$配对，以将条件输入$y$投影到一个可以映射到交叉注意力组件的中间表示$\tau_\theta(y) \in \mathbb{R}^{M \times d_\tau}$：

> The diffusion and denoising processes happen on the latent vector $\mathbf{z}$. The denoising model is a time-conditioned U-Net, augmented with the cross-attention mechanism to handle flexible conditioning information for image generation (e.g. class labels, semantic maps, blurred variants of an image). The design is equivalent to fuse representation of different modality into the model with a cross-attention mechanism. Each type of conditioning information is paired with a domain-specific encoder $\tau_\theta$ to project the conditioning input $y$ to an intermediate representation that can be mapped into cross-attention component, $\tau_\theta(y) \in \mathbb{R}^{M \times d_\tau}$:

$$
\begin{aligned}
&\text{Attention}(\mathbf{Q}, \mathbf{K}, \mathbf{V}) = \text{softmax}\Big(\frac{\mathbf{Q}\mathbf{K}^\top}{\sqrt{d}}\Big) \cdot \mathbf{V} \\
&\text{where }\mathbf{Q} = \mathbf{W}^{(i)}_Q \cdot \varphi_i(\mathbf{z}_i),\;
\mathbf{K} = \mathbf{W}^{(i)}_K \cdot \tau_\theta(y),\;
\mathbf{V} = \mathbf{W}^{(i)}_V \cdot \tau_\theta(y) \\
&\text{and }
\mathbf{W}^{(i)}_Q \in \mathbb{R}^{d \times d^i_\epsilon},\;
\mathbf{W}^{(i)}_K, \mathbf{W}^{(i)}_V \in \mathbb{R}^{d \times d_\tau},\;
\varphi_i(\mathbf{z}_i) \in \mathbb{R}^{N \times d^i_\epsilon},\;
\tau_\theta(y) \in \mathbb{R}^{M \times d_\tau}
\end{aligned}
$$

![The architecture of the latent diffusion model (LDM). (Image source: Rombach & Blattmann, et al. 2022 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/latent-diffusion-arch.png)

### 提升生成分辨率和质量

> Scale up Generation Resolution and Quality

为了生成高分辨率的高质量图像，[Ho 等人 (2021)](https://arxiv.org/abs/2106.15282) 提出使用一个由多个扩散模型组成的流水线，这些模型的处理分辨率逐渐增加。流水线模型之间的*噪声条件增强*对最终图像质量至关重要，它指的是对每个超分辨率模型的条件输入$\mathbf{z}$应用强数据增强$p_\theta(\mathbf{x} \vert \mathbf{z})$。条件噪声有助于减少流水线设置中的复合误差。*U-net* 是扩散建模中用于高分辨率图像生成的一种常见模型架构选择。

> To generate high-quality images at high resolution, [Ho et al. (2021)](https://arxiv.org/abs/2106.15282) proposed to use a pipeline of multiple diffusion models at increasing resolutions. *Noise conditioning augmentation* between pipeline models is crucial to the final image quality, which is to apply strong data augmentation to the conditioning input $\mathbf{z}$ of each super-resolution model $p_\theta(\mathbf{x} \vert \mathbf{z})$. The conditioning noise helps reduce compounding error in the pipeline setup. *U-net* is a common choice of model architecture in diffusion modeling for high-resolution image generation.

![A cascaded pipeline of multiple diffusion models at increasing resolutions. (Image source: Ho et al. 2021 \])](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/cascaded-diffusion.png)

他们发现最有效的噪声是在低分辨率下应用高斯噪声，在高分辨率下应用高斯模糊。此外，他们还探索了两种形式的条件增强，这些增强只需对训练过程进行少量修改。请注意，条件噪声仅应用于训练，而不应用于推理。

> They found the most effective noise is to apply Gaussian noise at low resolution and Gaussian blur at high resolution. In addition, they also explored two forms of conditioning augmentation that require small modification to the training process. Note that conditioning noise is only applied to training but not at inference.

• 截断条件增强在低分辨率下于步骤$t > 0$提前停止扩散过程。

• 非截断条件增强运行完整的低分辨率逆向过程直到步骤0，但随后通过$\mathbf{z}_t \sim q(\mathbf{x}_t \vert \mathbf{x}_0)$对其进行破坏，然后将损坏的$\mathbf{z}_t$馈送到超分辨率模型中。

英文原文：

• Truncated conditioning augmentation stops the diffusion process early at step $t > 0$ for low resolution.

• Non-truncated conditioning augmentation runs the full low resolution reverse process until step 0 but then corrupt it by $\mathbf{z}_t \sim q(\mathbf{x}_t \vert \mathbf{x}_0)$ and then feeds the corrupted $\mathbf{z}_t$ s into the super-resolution model.

两阶段扩散模型**unCLIP**（[Ramesh 等人 2022](https://arxiv.org/abs/2204.06125)）大量利用 CLIP 文本编码器来生成高质量的文本引导图像。给定一个预训练的 CLIP 模型$\mathbf{c}$和用于扩散模型的配对训练数据$(\mathbf{x}, y)$，其中`x`是图像，`y`是相应的标题，我们可以分别计算 CLIP 文本和图像嵌入$\mathbf{c}^t(y)$和$\mathbf{c}^i(\mathbf{x})$。unCLIP 并行学习两个模型：

英文原文：The two-stage diffusion model unCLIP ([Ramesh et al. 2022](https://arxiv.org/abs/2204.06125)) heavily utilizes the CLIP text encoder to produce text-guided images at high quality. Given a pretrained CLIP model 

$\mathbf{c}$ and paired training data for the diffusion model, 

$(\mathbf{x}, y)$, where `x` is an image and `y` is the corresponding caption, we can compute the CLIP text and image embedding, 

$\mathbf{c}^t(y)$ and 

$\mathbf{c}^i(\mathbf{x})$, respectively. The unCLIP learns two models in parallel:

• 一个先前的模型 $P(\mathbf{c}^i \vert y)$: 输出 CLIP 图像嵌入 $\mathbf{c}^i$ 给定文本 $y$。

• 一个解码器$P(\mathbf{x} \vert \mathbf{c}^i, [y])$：生成图像$\mathbf{x}$，给定 CLIP 图像嵌入$\mathbf{c}^i$并可选地给定原始文本$y$。

英文原文：

• A prior model $P(\mathbf{c}^i \vert y)$: outputs CLIP image embedding $\mathbf{c}^i$ given the text $y$.

• A decoder $P(\mathbf{x} \vert \mathbf{c}^i, [y])$: generates the image $\mathbf{x}$ given CLIP image embedding $\mathbf{c}^i$ and optionally the original text $y$.

这两个模型支持条件生成，因为

> These two models enable conditional generation, because

$$
\underbrace{P(\mathbf{x} \vert y) = P(\mathbf{x}, \mathbf{c}^i \vert y)}_{\mathbf{c}^i\text{ is deterministic given }\mathbf{x}} = P(\mathbf{x} \vert \mathbf{c}^i, y)P(\mathbf{c}^i \vert y)
$$

![The architecture of unCLIP. (Image source: Ramesh et al. 2022 \])](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/unCLIP.png)

unCLIP 遵循两阶段图像生成过程：

> unCLIP follows a two-stage image generation process:

1\. 给定文本 $y$，首先使用 CLIP 模型生成文本嵌入 $\mathbf{c}^t(y)$。使用 CLIP 潜在空间可以通过文本实现零样本图像操作。

2\. 扩散或自回归先验 $P(\mathbf{c}^i \vert y)$ 处理此 CLIP 文本嵌入以构建图像先验，然后扩散解码器 $P(\mathbf{x} \vert \mathbf{c}^i, [y])$ 根据该先验生成图像。此解码器还可以根据图像输入生成图像变体，同时保留其风格和语义。

英文原文：

1\. Given a text $y$, a CLIP model is first used to generate a text embedding $\mathbf{c}^t(y)$. Using CLIP latent space enables zero-shot image manipulation via text.

2\. A diffusion or autoregressive prior $P(\mathbf{c}^i \vert y)$ processes this CLIP text embedding to construct an image prior and then a diffusion decoder $P(\mathbf{x} \vert \mathbf{c}^i, [y])$ generates an image, conditioned on the prior. This decoder can also generate image variations conditioned on an image input, preserving its style and semantics.

没有使用 CLIP 模型，**Imagen** ([Saharia et al. 2022](https://arxiv.org/abs/2205.11487)) 使用预训练的大型语言模型（即冻结的 T5-XXL 文本编码器）来编码文本以进行图像生成。普遍趋势是更大的模型尺寸可以带来更好的图像质量和文本-图像对齐。他们发现 T5-XXL 和 CLIP 文本编码器在 MS-COCO 上取得了相似的性能，但人类评估更倾向于 DrawBench（一个包含 11 个类别的提示集合）上的 T5-XXL。

> Instead of CLIP model, **Imagen** ([Saharia et al. 2022](https://arxiv.org/abs/2205.11487)) uses a pre-trained large LM (i.e. a frozen T5-XXL text encoder) to encode text for image generation. There is a general trend that larger model size can lead to better image quality and text-image alignment. They found that T5-XXL and CLIP text encoder achieve similar performance on MS-COCO, but human evaluation prefers T5-XXL on DrawBench (a collection of prompts covering 11 categories).

在应用无分类器指导时，增加 $w$ 可能会导致更好的图像-文本对齐，但图像保真度会变差。他们发现这是由于训练-测试不匹配造成的，也就是说，因为训练数据 $\mathbf{x}$ 保持在 $[-1, 1]$ 范围内，所以测试数据也应该如此。引入了两种阈值策略：

> When applying classifier-free guidance, increasing $w$ may lead to better image-text alignment but worse image fidelity. They found that it is due to train-test mismatch, that is to say, because training data $\mathbf{x}$ stays within the range $[-1, 1]$, the test data should be so too. Two thresholding strategies are introduced:

• 静态阈值：将 $\mathbf{x}$ 预测裁剪到 $[-1, 1]$

• 动态阈值：在每个采样步骤中，计算 $s$ 作为某个百分位数绝对像素值；如果 $s > 1$，则将预测值裁剪到 $[-s, s]$ 并除以 $s$。

英文原文：

• Static thresholding: clip $\mathbf{x}$ prediction to $[-1, 1]$

• Dynamic thresholding: at each sampling step, compute $s$ as a certain percentile absolute pixel value; if $s > 1$, clip the prediction to $[-s, s]$ and divide by $s$.

Imagen 修改了 U-net 中的多项设计，使其成为 *高效 U-Net*。

> Imagen modifies several designs in U-net to make it *efficient U-Net*.

• 通过为较低分辨率添加更多残差锁，将模型参数从高分辨率块转移到低分辨率块；

• 通过 $1/\sqrt{2}$ 缩放跳跃连接

• 颠倒下采样（将其移至卷积之前）和上采样操作（将其移至卷积之后）的顺序，以提高前向传播的速度。

英文原文：

• Shift model parameters from high resolution blocks to low resolution by adding more residual locks for the lower resolutions;

• Scale the skip connections by $1/\sqrt{2}$

• Reverse the order of downsampling (move it before convolutions) and upsampling operations (move it after convolution) in order to improve the speed of forward pass.

他们发现噪声条件增强、动态阈值和高效 U-Net 对图像质量至关重要，但缩放文本编码器大小比 U-Net 大小更重要。

> They found that noise conditioning augmentation, dynamic thresholding and efficient U-Net are critical for image quality, but scaling text encoder size is more important than U-Net size.

### 模型架构

> Model Architecture

扩散模型有两种常见的骨干架构选择：U-Net 和 Transformer。

> There are two common backbone architecture choices for diffusion models: U-Net and Transformer.

**U-Net** ([Ronneberger, et al. 2015](https://arxiv.org/abs/1505.04597)) 由一个下采样堆栈和一个上采样堆栈组成。

> **U-Net** ([Ronneberger, et al. 2015](https://arxiv.org/abs/1505.04597)) consists of a downsampling stack and an upsampling stack.

- *下采样*：每个步骤包括重复应用两个 3x3 卷积（无填充卷积），每个卷积后接一个 ReLU 和一个步长为 2 的 2x2 最大池化。在每个下采样步骤中，特征通道的数量翻倍。
- *上采样*：每个步骤包括特征图的上采样，然后是一个 2x2 卷积，每个步骤将特征通道的数量减半。
- *快捷连接*：快捷连接与下采样堆栈的相应层进行拼接，并为上采样过程提供必要的高分辨率特征。

> • *Downsampling*: Each step consists of the repeated application of two 3x3 convolutions (unpadded convolutions), each followed by a ReLU and a 2x2 max pooling with stride 2. At each downsampling step, the number of feature channels is doubled.
> • *Upsampling*: Each step consists of an upsampling of the feature map followed by a 2x2 convolution and each halves the number of feature channels.
> • *Shortcuts*: Shortcut connections result in a concatenation with the corresponding layers of the downsampling stack and provide the essential high-resolution features to the upsampling process.

![The U-net architecture. Each blue square is a feature map with the number of channels labeled on top and the height x width dimension labeled on the left bottom side. The gray arrows mark the shortcut connections. (Image source: Ronneberger, 2015 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/U-net.png)

为了实现基于附加图像（如 Canny 边缘、霍夫线、用户涂鸦、人体姿态骨架、分割图、深度和法线）的图像生成，**ControlNet** ([Zhang et al. 2023](https://arxiv.org/abs/2302.05543)) 通过在 U-Net 的每个编码器层中添加一个可训练的原始模型权重副本的“夹层”零卷积层来引入架构更改。具体来说，给定一个神经网络块 $\mathcal{F}_\theta(.)$，ControlNet 执行以下操作：

英文原文：To enable image generation conditioned on additional images for composition info like Canny edges, Hough lines, user scribbles, human post skeletons, segmentation maps, depths and normals, ControlNet ([Zhang et al. 2023](https://arxiv.org/abs/2302.05543) introduces architectural changes via adding a “sandwiched” zero convolution layers of a trainable copy of the original model weights into each encoder layer of the U-Net. Precisely, given a neural network block 

$\mathcal{F}_\theta(.)$, ControlNet does the following:

1\. 首先，冻结原始块的原始参数 $\theta$

2\. 将其克隆为一个具有可训练参数 $\theta_c$ 和一个附加条件向量 $\mathbf{c}$ 的副本。

3\. 使用两个零卷积层，表示为 $\mathcal{Z}_{\theta_{z1}}(.;.)$ 和 $\mathcal{Z}_{\theta_{z2}}(.;.)$，它们是权重和偏置都初始化为零的 1x1 卷积层，用于连接这两个块。零卷积通过在初始训练步骤中消除作为梯度的随机噪声来保护这个骨干网络。

4\. 最终输出为：$\mathbf{y}_c = \mathcal{F}_\theta(\mathbf{x}) + \mathcal{Z}_{\theta_{z2}}(\mathcal{F}_{\theta_c}(\mathbf{x} + \mathcal{Z}_{\theta_{z1}}(\mathbf{c})))$

英文原文：

1\. First, freeze the original parameters $\theta$ of the original block

2\. Clone it to be a copy with trainable parameters $\theta_c$  and an additional conditioning vector $\mathbf{c}$.

3\. Use two zero convolution layers, denoted as $\mathcal{Z}_{\theta_{z1}}(.;.)$ and $\mathcal{Z}_{\theta_{z2}}(.;.)$, which is 1x1 convo layers with both weights and biases initialized to be zeros, to connect these two blocks. Zero convolutions protect this back-bone by eliminating random noise as gradients in the initial training steps.

4\. The final output is: $\mathbf{y}_c = \mathcal{F}_\theta(\mathbf{x}) + \mathcal{Z}_{\theta_{z2}}(\mathcal{F}_{\theta_c}(\mathbf{x} + \mathcal{Z}_{\theta_{z1}}(\mathbf{c})))$

![The ControlNet architecture. (Image source: Zhang et al. 2023 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/ControlNet.png)

**扩散 Transformer** (**DiT**; [Peebles & Xie, 2023](https://arxiv.org/abs/2212.09748)) 用于扩散建模，在潜在补丁上操作，使用与 [LDM](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#ldm) (潜在扩散模型) 相同的设计空间。DiT 具有以下设置：

> **Diffusion Transformer** (**DiT**; [Peebles & Xie, 2023](https://arxiv.org/abs/2212.09748)) for diffusion modeling operates on latent patches, using the same design space of [LDM](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#ldm) (Latent Diffusion Model)]. DiT has the following setup:

1\. 将输入 $\mathbf{z}$ 的潜在表示作为 DiT 的输入。

2\. 将大小为 $I \times I \times C$ 的噪声潜在表示“分块”为大小为 $p$ 的补丁，并将其转换为大小为 $(I/p)^2$ 的补丁序列。

3\. 然后，这个 token 序列通过 Transformer 块。他们正在探索三种不同的设计，用于如何根据时间步 $t$ 或类别标签 $c$ 等上下文信息进行生成。在这三种设计中，*adaLN (自适应层归一化)-Zero* 效果最好，优于上下文条件和交叉注意力块。缩放和平移参数 $\gamma$ 和 $\beta$ 是从 $t$ 和 $c$ 的嵌入向量之和回归得到的。维度缩放参数 $\alpha$ 也被回归，并立即应用于 DiT 块内的任何残差连接之前。

4\. Transformer 解码器输出噪声预测和输出对角协方差预测。

英文原文：

1\. Take the latent representation of an input $\mathbf{z}$ as input to DiT.

2\. “Patchify” the noise latent of size $I \times I \times C$ into patches of size $p$ and convert it into a sequence of patches of size $(I/p)^2$.

3\. Then this sequence of tokens go through Transformer blocks. They are exploring three different designs for how to do generation conditioned on contextual information like timestep $t$ or class label $c$. Among three designs, *adaLN (Adaptive layer norm)-Zero* works out the best, better than in-context conditioning and cross-attention block. The scale and shift parameters, $\gamma$ and $\beta$, are regressed from the sum of the embedding vectors of $t$ and $c$. The dimension-wise scaling parameters $\alpha$ is also regressed and applied immediately prior to any residual connections within the DiT block.

4\. The transformer decoder outputs noise predictions and an output diagonal covariance prediction.

![The Diffusion Transformer (DiT) architecture. (Image source: Peebles & Xie, 2023 )](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/DiT.png)

Transformer 架构可以很容易地扩展，并且因此而闻名。这是 DiT 的最大优势之一，因为根据实验，其性能随计算量的增加而提升，并且更大的 DiT 模型计算效率更高。

> Transformer architecture can be easily scaled up and it is well known for that. This is one of the biggest benefits of DiT as its performance scales up with more compute and larger DiT models are more compute efficient according to the experiments.

### 快速总结

> Quick Summary

- 
**优点**: 可处理性和灵活性是生成建模中两个相互冲突的目标。可处理模型可以进行分析评估并廉价地拟合数据（例如通过高斯或拉普拉斯分布），但它们无法轻易描述丰富数据集中的结构。灵活模型可以拟合数据中的任意结构，但评估、训练或从这些模型中采样通常成本高昂。扩散模型既可分析处理又灵活

- 
**缺点**: 扩散模型依赖于漫长的扩散步骤马尔可夫链来生成样本，因此在时间和计算方面可能相当昂贵。虽然已经提出了新方法来大大加快这一过程，但采样速度仍慢于GAN。


> • 
> **Pros**: Tractability and flexibility are two conflicting objectives in generative modeling. Tractable models can be analytically evaluated and cheaply fit data (e.g. via a Gaussian or Laplace), but they cannot easily describe the structure in rich datasets. Flexible models can fit arbitrary structures in data, but evaluating, training, or sampling from these models is usually expensive. Diffusion models are both analytically tractable and flexible
> • 
> **Cons**: Diffusion models rely on a long Markov chain of diffusion steps to generate samples, so it can be quite expensive in terms of time and compute. New methods have been proposed to make the process much faster, but the sampling is still slower than GAN.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Jul 2021). What are diffusion models? Lil’Log. https://lilianweng.github.io/posts/2021-07-11-diffusion-models/.

> Weng, Lilian. (Jul 2021). What are diffusion models? Lil’Log. https://lilianweng.github.io/posts/2021-07-11-diffusion-models/.

或

> Or

```
@article{weng2021diffusion,
  title   = "What are diffusion models?",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2021",
  month   = "Jul",
  url     = "https://lilianweng.github.io/posts/2021-07-11-diffusion-models/"
}
```

### 参考文献

> References

[1] Jascha Sohl-Dickstein et al. [“Deep Unsupervised Learning using Nonequilibrium Thermodynamics.”](https://arxiv.org/abs/1503.03585) ICML 2015.

> [1] Jascha Sohl-Dickstein et al. [“Deep Unsupervised Learning using Nonequilibrium Thermodynamics.”](https://arxiv.org/abs/1503.03585) ICML 2015.

[2] Max Welling & Yee Whye Teh. [“Bayesian learning via stochastic gradient langevin dynamics.”](https://www.stats.ox.ac.uk/~teh/research/compstats/WelTeh2011a.pdf) ICML 2011.

> [2] Max Welling & Yee Whye Teh. [“Bayesian learning via stochastic gradient langevin dynamics.”](https://www.stats.ox.ac.uk/~teh/research/compstats/WelTeh2011a.pdf) ICML 2011.

[3] Yang Song & Stefano Ermon. [“Generative modeling by estimating gradients of the data distribution.”](https://arxiv.org/abs/1907.05600) NeurIPS 2019.

> [3] Yang Song & Stefano Ermon. [“Generative modeling by estimating gradients of the data distribution.”](https://arxiv.org/abs/1907.05600) NeurIPS 2019.

[4] Yang Song & Stefano Ermon. [“Improved techniques for training score-based generative models.”](https://arxiv.org/abs/2006.09011)  NeuriPS 2020.

> [4] Yang Song & Stefano Ermon. [“Improved techniques for training score-based generative models.”](https://arxiv.org/abs/2006.09011)  NeuriPS 2020.

[5] Jonathan Ho et al. [“Denoising diffusion probabilistic models.”](https://arxiv.org/abs/2006.11239) arxiv Preprint arxiv:2006.11239 (2020). [[代码](https://github.com/hojonathanho/diffusion)]

> [5] Jonathan Ho et al. [“Denoising diffusion probabilistic models.”](https://arxiv.org/abs/2006.11239) arxiv Preprint arxiv:2006.11239 (2020). [[code](https://github.com/hojonathanho/diffusion)]

[6] Jiaming Song et al. [“Denoising diffusion implicit models.”](https://arxiv.org/abs/2010.02502) arxiv Preprint arxiv:2010.02502 (2020). [[代码](https://github.com/ermongroup/ddim)]

> [6] Jiaming Song et al. [“Denoising diffusion implicit models.”](https://arxiv.org/abs/2010.02502) arxiv Preprint arxiv:2010.02502 (2020). [[code](https://github.com/ermongroup/ddim)]

[7] Alex Nichol & Prafulla Dhariwal. [“Improved denoising diffusion probabilistic models”](https://arxiv.org/abs/2102.09672) arxiv Preprint arxiv:2102.09672 (2021). [[代码](https://github.com/openai/improved-diffusion)]

> [7] Alex Nichol & Prafulla Dhariwal. [“Improved denoising diffusion probabilistic models”](https://arxiv.org/abs/2102.09672) arxiv Preprint arxiv:2102.09672 (2021). [[code](https://github.com/openai/improved-diffusion)]

[8] Prafula Dhariwal & Alex Nichol. [“Diffusion Models Beat GANs on Image Synthesis.”](https://arxiv.org/abs/2105.05233) arxiv Preprint arxiv:2105.05233 (2021). [[代码](https://github.com/openai/guided-diffusion)]

> [8] Prafula Dhariwal & Alex Nichol. [“Diffusion Models Beat GANs on Image Synthesis.”](https://arxiv.org/abs/2105.05233) arxiv Preprint arxiv:2105.05233 (2021). [[code](https://github.com/openai/guided-diffusion)]

[9] Jonathan Ho & Tim Salimans. [“Classifier-Free Diffusion Guidance.”](https://arxiv.org/abs/2207.12598) NeurIPS 2021 Workshop on Deep Generative Models and Downstream Applications.

> [9] Jonathan Ho & Tim Salimans. [“Classifier-Free Diffusion Guidance.”](https://arxiv.org/abs/2207.12598) NeurIPS 2021 Workshop on Deep Generative Models and Downstream Applications.

[10] Yang Song, et al. [“Score-Based Generative Modeling through Stochastic Differential Equations.”](https://openreview.net/forum?id=PxTIG12RRHS) ICLR 2021.

> [10] Yang Song, et al. [“Score-Based Generative Modeling through Stochastic Differential Equations.”](https://openreview.net/forum?id=PxTIG12RRHS) ICLR 2021.

[11] Alex Nichol, Prafulla Dhariwal & Aditya Ramesh, et al. [“GLIDE: Towards Photorealistic Image Generation and Editing with Text-Guided Diffusion Models.”](https://arxiv.org/abs/2112.10741) ICML 2022.

> [11] Alex Nichol, Prafulla Dhariwal & Aditya Ramesh, et al. [“GLIDE: Towards Photorealistic Image Generation and Editing with Text-Guided Diffusion Models.”](https://arxiv.org/abs/2112.10741) ICML 2022.

[12] Jonathan Ho, et al. [“Cascaded diffusion models for high fidelity image generation.”](https://arxiv.org/abs/2106.15282) J. Mach. Learn. Res. 23 (2022): 47-1.

> [12] Jonathan Ho, et al. [“Cascaded diffusion models for high fidelity image generation.”](https://arxiv.org/abs/2106.15282) J. Mach. Learn. Res. 23 (2022): 47-1.

[13] Aditya Ramesh et al. [“Hierarchical Text-Conditional Image Generation with CLIP Latents.”](https://arxiv.org/abs/2204.06125) arxiv Preprint arxiv:2204.06125 (2022).

> [13] Aditya Ramesh et al. [“Hierarchical Text-Conditional Image Generation with CLIP Latents.”](https://arxiv.org/abs/2204.06125) arxiv Preprint arxiv:2204.06125 (2022).

[14] Chitwan Saharia & William Chan, et al. [“Photorealistic Text-to-Image Diffusion Models with Deep Language Understanding.”](https://arxiv.org/abs/2205.11487) arxiv Preprint arxiv:2205.11487 (2022).

> [14] Chitwan Saharia & William Chan, et al. [“Photorealistic Text-to-Image Diffusion Models with Deep Language Understanding.”](https://arxiv.org/abs/2205.11487) arxiv Preprint arxiv:2205.11487 (2022).

[15] Rombach & Blattmann, et al. [“High-Resolution Image Synthesis with Latent Diffusion Models.”](https://arxiv.org/abs/2112.10752) CVPR 2022.[代码](https://github.com/CompVis/latent-diffusion)

> [15] Rombach & Blattmann, et al. [“High-Resolution Image Synthesis with Latent Diffusion Models.”](https://arxiv.org/abs/2112.10752) CVPR 2022.[code](https://github.com/CompVis/latent-diffusion)

[16] Song et al. [“Consistency Models”](https://arxiv.org/abs/2303.01469) arxiv Preprint arxiv:2303.01469 (2023)

> [16] Song et al. [“Consistency Models”](https://arxiv.org/abs/2303.01469) arxiv Preprint arxiv:2303.01469 (2023)

[17] Salimans & Ho. [“Progressive Distillation for Fast Sampling of Diffusion Models”](https://arxiv.org/abs/2202.00512) ICLR 2022.

> [17] Salimans & Ho. [“Progressive Distillation for Fast Sampling of Diffusion Models”](https://arxiv.org/abs/2202.00512) ICLR 2022.

[18] Ronneberger, et al. [“U-Net: Convolutional Networks for Biomedical Image Segmentation”](https://arxiv.org/abs/1505.04597) MICCAI 2015.

> [18] Ronneberger, et al. [“U-Net: Convolutional Networks for Biomedical Image Segmentation”](https://arxiv.org/abs/1505.04597) MICCAI 2015.

[19] Peebles & Xie. [“Scalable diffusion models with transformers.”](https://arxiv.org/abs/2212.09748) ICCV 2023.

> [19] Peebles & Xie. [“Scalable diffusion models with transformers.”](https://arxiv.org/abs/2212.09748) ICCV 2023.

[20] Zhang et al. [“Adding Conditional Control to Text-to-Image Diffusion Models.”](https://arxiv.org/abs/2302.05543) arxiv Preprint arxiv:2302.05543 (2023).

> [20] Zhang et al. [“Adding Conditional Control to Text-to-Image Diffusion Models.”](https://arxiv.org/abs/2302.05543) arxiv Preprint arxiv:2302.05543 (2023).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Diffusion Models | 扩散模型 | 一类受非平衡热力学启发的生成模型，通过逐步加噪和去噪过程生成数据。 |
| Forward Diffusion Process | 前向扩散过程 | 在T步内向数据样本逐步添加高斯噪声，使其最终变为纯高斯噪声。 |
| Reverse Diffusion Process | 逆向扩散过程 | 学习从高斯噪声中逐步去除噪声，以重建原始数据样本的过程。 |
| Denoising Diffusion Probabilistic Models (DDPM) | 去噪扩散概率模型 | 一种基于扩散过程的生成模型，通过学习逆向过程中的去噪步骤来生成数据。 |
| Noise Conditional Score Networks (NCSN) | 噪声条件分数网络 | 一种通过估计数据分布梯度来生成样本的模型，与扩散模型有密切联系。 |
| Stochastic Gradient Langevin Dynamics | 随机梯度朗之万动力学 | 一种结合随机梯度下降和高斯噪声的采样方法，用于从概率密度中生成样本。 |
| Classifier Guidance | 分类器引导 | 通过训练一个分类器并利用其梯度来引导扩散采样过程，使其生成符合特定条件（如类别标签）的样本。 |
| Classifier-Free Guidance | 无分类器引导 | 一种无需独立分类器即可实现条件生成的方法，通过结合条件和无条件扩散模型的得分来引导采样。 |
| Denoising Diffusion Implicit Models (DDIM) | 去噪扩散隐式模型 | 一种加速扩散模型采样的方法，通过确定性地将噪声映射回原始数据样本，允许使用更少的采样步骤。 |
| Progressive Distillation | 渐进式蒸馏 | 一种将训练好的确定性采样器蒸馏成采样步数减半的新模型的方法，以加速采样。 |
| Consistency Models | 一致性模型 | 一种学习将扩散采样轨迹上的任何中间噪声数据点直接映射回其原点，实现单步采样的模型。 |
| Latent Diffusion Models (LDM) | 潜在扩散模型 | 在潜在空间而非像素空间中运行扩散过程的生成模型，以提高效率。 |
| U-Net | U-Net | 一种由下采样和上采样堆栈组成的卷积神经网络架构，常用于图像分割和扩散模型。 |
| Transformer | Transformer | 一种基于自注意力机制的神经网络架构，在扩散模型中用于处理潜在补丁序列。 |
| ControlNet | ControlNet | 一种通过在U-Net编码器层添加可训练的零卷积层，实现基于附加图像条件生成的技术。 |
