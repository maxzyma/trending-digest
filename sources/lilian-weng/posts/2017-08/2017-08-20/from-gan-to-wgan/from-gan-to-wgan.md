# 从 GAN 到 WGAN

> From GAN to WGAN

> 来源：Lil'Log / Lilian Weng，2017-08-20
> 原文链接：https://lilianweng.github.io/posts/2017-08-20-gan/
> 分类：深度学习 / 生成对抗网络

## 核心要点

- 生成对抗网络（GAN）通过生成器与判别器的对抗训练，在图像、语言和音乐等生成任务中表现出色，但其训练过程常面临不稳定和不收敛的挑战。
- GAN的损失函数在判别器最优时，量化了生成数据分布与真实数据分布之间的Jensen-Shannon散度，但当两个分布不相交时，该散度值可能不提供有意义的梯度。
- GAN训练中存在纳什均衡难以达到、真实数据和生成数据分布位于低维流形且不相交、梯度消失、模式崩溃以及缺乏合适评估指标等问题。
- 当生成器和真实数据分布不相交时，判别器可以完美区分真假样本，导致生成器损失函数的梯度消失，从而阻碍学习。
- 为改进GAN训练，提出了特征匹配、小批量判别、历史平均、单边标签平滑、虚拟批量归一化以及向判别器输入添加噪声等实用技术。
- Wasserstein GAN（WGAN）引入Wasserstein距离（推土机距离）作为新的损失函数，该距离即使在分布不相交时也能提供平滑且有意义的度量。
- Wasserstein距离相比KL和JS散度，在分布重叠度低时仍能保持连续可微，这对于基于梯度下降的稳定学习过程至关重要。
- WGAN通过将判别器转换为学习K-Lipschitz连续函数的“评论家”，并采用权重裁剪来强制执行Lipschitz约束，从而估计Wasserstein距离。
- WGAN的改进包括使用新的无对数损失函数、对评论家权重进行裁剪以及推荐使用RMSProp优化器。
- 尽管WGAN有所改进，但权重裁剪作为强制Lipschitz约束的方法存在局限性，可能导致训练不稳定、收敛缓慢或梯度消失，后续的WGAN-GP通过梯度惩罚进一步优化。

## 正文

[2018-09-30 更新：感谢 Yoonju，本文已翻译成 [韩语](https://github.com/yjucho1/articles/blob/master/fromGANtoWGAN/readme.md)！]  
[2019-04-18 更新：本文也可在 [arXiv](https://arxiv.org/abs/1904.08994) 上查阅。]

> [Updated on 2018-09-30: thanks to Yoonju, we have this post translated in [Korean](https://github.com/yjucho1/articles/blob/master/fromGANtoWGAN/readme.md)!]
>
>
> [Updated on 2019-04-18: this post is also available on [arXiv](https://arxiv.org/abs/1904.08994).]

[生成对抗网络](https://arxiv.org/pdf/1406.2661.pdf)（GAN）在许多生成任务中都取得了显著成果，能够复制图像、人类语言和音乐等现实世界中的丰富内容。它受到博弈论的启发：两个模型，一个生成器和一个判别器，在相互竞争的同时也使彼此变得更强大。然而，训练 GAN 模型相当具有挑战性，因为人们面临着训练不稳定或无法收敛等问题。

> [Generative adversarial network](https://arxiv.org/pdf/1406.2661.pdf) (GAN) has shown great results in many generative tasks to replicate the real-world rich content such as images, human language, and music. It is inspired by game theory: two models, a generator and a critic, are competing with each other while making each other stronger at the same time. However, it is rather challenging to train a GAN model, as people are facing issues like training instability or failure to converge.

在此，我将解释生成对抗网络框架背后的数学原理，为什么它难以训练，并最终介绍一个旨在解决训练困难的 GAN 修改版本。

> Here I would like to explain the maths behind the generative adversarial network framework,  why it is hard to be trained, and finally introduce a modified version of GAN intended to solve the training difficulties.

### Kullback–Leibler 散度和 Jensen–Shannon 散度

> Kullback–Leibler and Jensen–Shannon Divergence

在我们开始仔细研究 GAN 之前，让我们首先回顾两个用于量化两个概率分布之间相似性的指标。

> Before we start examining GANs closely, let us first review two metrics for quantifying the similarity between two probability distributions.

(1) [KL（Kullback–Leibler）散度](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)衡量一个概率分布 $p$ 与第二个预期概率分布 $q$ 的差异程度。

> (1) [KL (Kullback–Leibler) divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence) measures how one probability distribution $p$ diverges from a second expected probability distribution $q$.

$$
D_{KL}(p \| q) = \int_x p(x) \log \frac{p(x)}{q(x)} dx
$$

$D_{KL}$ 在 $p(x)$ == $q(x)$ 处处相等时，达到最小零值。

> $D_{KL}$ achieves the minimum zero when $p(x)$ == $q(x)$ everywhere.

根据公式可以看出，KL 散度是不对称的。在 $p(x)$ 接近零，而 $q(x)$ 显著非零的情况下，$q$ 的影响会被忽略。当我们只想衡量两个同等重要分布之间的相似性时，这可能会导致错误的结果。

> It is noticeable according to the formula that KL divergence is asymmetric. In cases where $p(x)$ is close to zero, but $q(x)$ is significantly non-zero, the $q$’s effect is disregarded. It could cause buggy results when we just want to measure the similarity between two equally important distributions.

(2) [Jensen–Shannon 散度](https://en.wikipedia.org/wiki/Jensen%E2%80%93Shannon_divergence)是衡量两个概率分布之间相似性的另一个指标，其值受限于 $[0, 1]$。JS 散度是对称的（太棒了！）并且更平滑。如果你对 KL 散度和 JS 散度之间的比较感兴趣，请查阅这篇 [Quora 帖子](https://www.quora.com/Why-isnt-the-Jensen-Shannon-divergence-used-more-often-than-the-Kullback-Leibler-since-JS-is-symmetric-thus-possibly-a-better-indicator-of-distance)。

> (2) [Jensen–Shannon Divergence](https://en.wikipedia.org/wiki/Jensen%E2%80%93Shannon_divergence) is another measure of similarity between two probability distributions, bounded by $[0, 1]$. JS divergence is symmetric (yay!) and more smooth. Check this [Quora post](https://www.quora.com/Why-isnt-the-Jensen-Shannon-divergence-used-more-often-than-the-Kullback-Leibler-since-JS-is-symmetric-thus-possibly-a-better-indicator-of-distance) if you are interested in reading more about the comparison between KL divergence and JS divergence.

$$
D_{JS}(p \| q) = \frac{1}{2} D_{KL}(p \| \frac{p + q}{2}) + \frac{1}{2} D_{KL}(q \| \frac{p + q}{2})
$$

![Given two Gaussian distribution, $p$ with mean=0 and std=1 and $q$ with mean=1 and std=1. The average of two distributions is labelled as $m=(p+q)/2$. KL divergence $D_{KL}$ is asymmetric but JS divergence $D_{JS}$ is symmetric.](https://lilianweng.github.io/posts/2017-08-20-gan/KL_JS_divergence.png)

一些人认为（[Huszar, 2015](https://arxiv.org/pdf/1511.05101.pdf)）GAN 取得巨大成功的一个原因是将传统最大似然方法中不对称的 KL 散度损失函数切换为对称的 JS 散度。我们将在下一节中详细讨论这一点。

> Some believe ([Huszar, 2015](https://arxiv.org/pdf/1511.05101.pdf)) that one reason behind GANs’ big success is switching the loss function from asymmetric KL divergence in traditional maximum-likelihood approach to symmetric JS divergence. We will discuss more on this point in the next section.

### 生成对抗网络 (GAN)

> Generative Adversarial Network (GAN)

GAN 由两个模型组成：

> GAN consists of two models:

• 一个判别器 $D$ 估计给定样本来自真实数据集的概率。它充当判别器，并被优化以区分假样本和真实样本。

• 一个生成器 $G$ 在给定噪声变量输入 $z$（$z$ 带来潜在的输出多样性）的情况下，输出合成样本。它被训练来捕获真实数据分布，以便其生成的样本尽可能真实，换句话说，能够欺骗判别器给出高概率。

英文原文：

• A discriminator $D$ estimates the probability of a given sample coming from the real dataset. It works as a critic and is optimized to tell the fake samples from the real ones.

• A generator $G$ outputs synthetic samples given a noise variable input $z$ ($z$ brings in potential output diversity). It is trained to capture the real data distribution so that its generative samples can be as real as possible, or in other words, can trick the discriminator to offer a high probability.

![Architecture of a generative adversarial network. (Image source: www.kdnuggets.com/2017/01/generative-...-learning.html )](https://lilianweng.github.io/posts/2017-08-20-gan/GAN.png)

这两个模型在训练过程中相互竞争：生成器 $G$ 努力欺骗判别器，而判别器模型 $D$ 努力不被欺骗。这两个模型之间有趣的零和博弈促使它们都改进各自的功能。

> These two models compete against each other during the training process: the generator $G$ is trying hard to trick the discriminator, while the critic model $D$ is trying hard not to be cheated. This interesting zero-sum game between two models motivates both to improve their functionalities.

给定，

> Given,

| 符号 | 含义 | 备注 |
| --- | --- | --- |
| $p_{z}$ | 噪声输入 $z$ 的数据分布 | 通常是均匀分布。 |
| $p_{g}$ | 生成器在数据 $x$ 上的分布 |  |
| $p_{r}$ | 真实样本 $x$ 上的数据分布 |  |

> 英文原表 / English original

| Symbol | Meaning | Notes |
| --- | --- | --- |
| $p_{z}$ | Data distribution over noise input $z$ | Usually, just uniform. |
| $p_{g}$ | The generator’s distribution over data $x$ |  |
| $p_{r}$ | Data distribution over real sample $x$ |  |

一方面，我们希望确保判别器$D$对真实数据的决策是准确的，通过最大化$\mathbb{E}_{x \sim p_{r}(x)} [\log D(x)]$。同时，给定一个伪造样本$G(z), z \sim p_z(z)$，判别器应输出一个概率，$D(G(z))$，接近零，通过最大化$\mathbb{E}_{z \sim p_{z}(z)} [\log (1 - D(G(z)))]$。

> On one hand, we want to make sure the discriminator $D$’s decisions over real data are accurate by maximizing $\mathbb{E}_{x \sim p_{r}(x)} [\log D(x)]$. Meanwhile, given a fake sample $G(z), z \sim p_z(z)$, the discriminator is expected to output a probability, $D(G(z))$, close to zero by maximizing $\mathbb{E}_{z \sim p_{z}(z)} [\log (1 - D(G(z)))]$.

另一方面，生成器被训练来增加$D$为假样本生成高概率的可能性，从而最小化$\mathbb{E}_{z \sim p_{z}(z)} [\log (1 - D(G(z)))]$。

> On the other hand, the generator is trained to increase the chances of $D$ producing a high probability for a fake example, thus to minimize $\mathbb{E}_{z \sim p_{z}(z)} [\log (1 - D(G(z)))]$.

当将这两个方面结合起来时，`D`和`G`正在玩一场**最小最大博弈**，我们应该优化以下损失函数：

英文原文：When combining both aspects together, `D` and `G` are playing a minimax game in which we should optimize the following loss function:

$$
\begin{aligned}
\min_G \max_D L(D, G) 
& = \mathbb{E}_{x \sim p_{r}(x)} [\log D(x)] + \mathbb{E}_{z \sim p_z(z)} [\log(1 - D(G(z)))] \\
& = \mathbb{E}_{x \sim p_{r}(x)} [\log D(x)] + \mathbb{E}_{x \sim p_g(x)} [\log(1 - D(x)]
\end{aligned}
$$

($\mathbb{E}_{x \sim p_{r}(x)} [\log D(x)]$在$G$的梯度下降更新过程中没有影响。)

> ($\mathbb{E}_{x \sim p_{r}(x)} [\log D(x)]$ has no impact on $G$ during gradient descent updates.)

#### D 的最优值是多少？

> What is the optimal value for D?

现在我们有了一个定义良好的损失函数。让我们首先检查 $D$ 的最佳值是多少。

> Now we have a well-defined loss function. Let’s first examine what is the best value for $D$.

$$
L(G, D) = \int_x \bigg( p_{r}(x) \log(D(x)) + p_g (x) \log(1 - D(x)) \bigg) dx
$$

由于我们感兴趣的是 $D(x)$ 的最佳值是多少才能最大化 $L(G, D)$，我们将其标记为

> Since we are interested in what is the best value of $D(x)$ to maximize $L(G, D)$, let us label

$$
\tilde{x} = D(x), 
A=p_{r}(x), 
B=p_g(x)
$$

然后积分内部（我们可以安全地忽略积分，因为 $x$ 是在所有可能的值上采样的）是：

> And then what is inside the integral (we can safely ignore the integral because $x$ is sampled over all the possible values) is:

$$
\begin{aligned}
f(\tilde{x}) 
& = A log\tilde{x} + B log(1-\tilde{x}) \\
\frac{d f(\tilde{x})}{d \tilde{x}}
& = A \frac{1}{ln10} \frac{1}{\tilde{x}} - B \frac{1}{ln10} \frac{1}{1 - \tilde{x}} \\
& = \frac{1}{ln10} (\frac{A}{\tilde{x}} - \frac{B}{1-\tilde{x}}) \\
& = \frac{1}{ln10} \frac{A - (A + B)\tilde{x}}{\tilde{x} (1 - \tilde{x})} \\
\end{aligned}
$$

因此，设置 $\frac{d f(\tilde{x})}{d \tilde{x}} = 0$，我们得到判别器的最佳值：$D^{\ast}(x) = \tilde{x}^{\ast} = \frac{A}{A + B} = \frac{p_{r}(x)}{p_{r}(x) + p_g(x)} \in [0, 1]$。

> Thus, set $\frac{d f(\tilde{x})}{d \tilde{x}} = 0$, we get the best value of the discriminator: $D^{\ast}(x) = \tilde{x}^{\ast} = \frac{A}{A + B} = \frac{p_{r}(x)}{p_{r}(x) + p_g(x)} \in [0, 1]$.

一旦生成器训练到最优，$p_g$ 会非常接近 $p_{r}$。当 $p_g = p_{r}$ 时，$D^{\ast}(x)$ 变为 $1/2$。

> Once the generator is trained to its optimal, $p_g$ gets very close to $p_{r}$. When $p_g = p_{r}$, $D^{\ast}(x)$ becomes $1/2$.

#### 什么是全局最优？

> What is the global optimal?

当 $G$ 和 $D$ 都处于最优值时，我们得到 $p_g = p_{r}$ 和 $D^{\ast}(x) = 1/2$，损失函数变为：

> When both $G$ and $D$ are at their optimal values, we have $p_g = p_{r}$ and $D^{\ast}(x) = 1/2$ and the loss function becomes:

$$
\begin{aligned}
L(G, D^*) 
&= \int_x \bigg( p_{r}(x) \log(D^*(x)) + p_g (x) \log(1 - D^*(x)) \bigg) dx \\
&= \log \frac{1}{2} \int_x p_{r}(x) dx + \log \frac{1}{2} \int_x p_g(x) dx \\
&= -2\log2
\end{aligned}
$$

#### 损失函数代表什么？

> What does the loss function represent?

根据 [上一节](https://lilianweng.github.io/posts/2017-08-20-gan/#kullbackleibler-and-jensenshannon-divergence) 中列出的公式，$p_{r}$ 和 $p_g$ 之间的 JS 散度可以计算为：

> According to the formula listed in the [previous section](https://lilianweng.github.io/posts/2017-08-20-gan/#kullbackleibler-and-jensenshannon-divergence), JS divergence between $p_{r}$ and $p_g$ can be computed as:

$$
\begin{aligned}
D_{JS}(p_{r} \| p_g) 
=& \frac{1}{2} D_{KL}(p_{r} || \frac{p_{r} + p_g}{2}) + \frac{1}{2} D_{KL}(p_{g} || \frac{p_{r} + p_g}{2}) \\
=& \frac{1}{2} \bigg( \log2 + \int_x p_{r}(x) \log \frac{p_{r}(x)}{p_{r} + p_g(x)} dx \bigg) + \\& \frac{1}{2} \bigg( \log2 + \int_x p_g(x) \log \frac{p_g(x)}{p_{r} + p_g(x)} dx \bigg) \\
=& \frac{1}{2} \bigg( \log4 + L(G, D^*) \bigg)
\end{aligned}
$$

因此，

> Thus,

$$
L(G, D^*) = 2D_{JS}(p_{r} \| p_g) - 2\log2
$$

本质上，当判别器最优时，GAN 的损失函数通过 JS 散度量化了生成数据分布 $p_g$ 和真实样本分布 $p_{r}$ 之间的相似性。最佳的 $G^{\ast}$ 能够复制真实数据分布，从而导致最小的 $L(G^{\ast}, D^{\ast}) = -2\log2$，这与上述方程一致。

> Essentially the loss function of GAN quantifies the similarity between the generative data distribution $p_g$ and the real sample distribution $p_{r}$ by JS divergence when the discriminator is optimal. The best $G^{\ast}$ that replicates the real data distribution leads to the minimum $L(G^{\ast}, D^{\ast}) = -2\log2$ which is aligned with equations above.

引用译文：

**GAN 的其他变体**：GAN 在不同上下文或为不同任务设计时有许多变体。例如，对于半监督学习，一个想法是更新判别器以输出真实类别标签，$1, \dots, K-1$，以及一个伪造类别标签$K$。生成器模型旨在欺骗判别器，使其输出一个小于$K$的分类标签。

英文原文：

**Other Variations of GAN**: There are many variations of GANs in different contexts or designed for different tasks. For example, for semi-supervised learning, one idea is to update the discriminator to output real class labels, $1, \dots, K-1$, as well as one fake class label $K$. The generator model aims to trick the discriminator to output a classification label smaller than $K$.

**Tensorflow 实现**: [carpedm20/DCGAN-tensorflow](https://github.com/carpedm20/DCGAN-tensorflow)

> **Tensorflow Implementation**: [carpedm20/DCGAN-tensorflow](https://github.com/carpedm20/DCGAN-tensorflow)

### GAN 中的问题

> Problems in GANs

尽管GAN在真实图像生成方面取得了巨大成功，但其训练并不容易；该过程以缓慢和不稳定而闻名。

> Although GAN has shown great success in the realistic image generation, the training is not easy; The process is known to be slow and unstable.

#### 难以达到纳什均衡

> Hard to achieve Nash equilibrium

[Salimans et al. (2016)](http://papers.nips.cc/paper/6125-improved-techniques-for-training-gans.pdf) 讨论了GAN基于梯度下降的训练过程存在的问题。两个模型同时进行训练，以找到一个两人非合作博弈的[纳什均衡](https://en.wikipedia.org/wiki/Nash_equilibrium)。然而，每个模型独立更新其成本，而不考虑博弈中的另一个参与者。同时更新两个模型的梯度不能保证收敛。

> [Salimans et al. (2016)](http://papers.nips.cc/paper/6125-improved-techniques-for-training-gans.pdf) discussed the problem with GAN’s gradient-descent-based training procedure. Two models are trained simultaneously to find a [Nash equilibrium](https://en.wikipedia.org/wiki/Nash_equilibrium) to a two-player non-cooperative game. However, each model updates its cost independently with no respect to another player in the game. Updating the gradient of both models concurrently cannot guarantee a convergence.

让我们看一个简单的例子，以便更好地理解为什么在非合作博弈中很难找到纳什均衡。假设一个参与者控制 $x$ 以最小化 $f_1(x) = xy$，而同时另一个参与者不断更新 $y$ 以最小化 $f_2(y) = -xy$。

> Let’s check out a simple example to better understand why it is difficult to find a Nash equilibrium in an non-cooperative game. Suppose one player takes control of $x$ to minimize $f_1(x) = xy$, while at the same time the other player constantly updates $y$ to minimize $f_2(y) = -xy$.

因为$\frac{\partial f_1}{\partial x} = y$和$\frac{\partial f_2}{\partial y} = -x$，我们在一个迭代中同时更新$x$使用$x-\eta \cdot y$，并更新$y$使用$y+ \eta \cdot x$，其中$\eta$是学习率。一旦$x$和$y$符号不同，后续的每一次梯度更新都会导致巨大的振荡，并且不稳定会随着时间恶化，如所示。

> Because $\frac{\partial f_1}{\partial x} = y$ and $\frac{\partial f_2}{\partial y} = -x$, we update $x$ with $x-\eta \cdot y$ and $y$ with $y+ \eta \cdot x$ simulitanously in one iteration, where $\eta$ is the learning rate. Once $x$ and $y$ have different signs, every following gradient update causes huge oscillation and the instability gets worse in time, as shown in 

![A simulation of our example for updating $x$ to minimize $xy$ and updating $y$ to minimize $-xy$. The learning rate $\eta = 0.1$. With more iterations, the oscillation grows more and more unstable.](https://lilianweng.github.io/posts/2017-08-20-gan/nash_equilibrium.png)

#### 低维支持

> Low dimensional supports

| 术语 | 解释 |
| --- | --- |
| 流形 | 在每个点附近局部类似于欧几里得空间的拓扑空间。准确地说，当这个欧几里得空间是 $n$ 维时，该流形被称为 $n$ 维流形。 |
| 支持 | 实值函数 $f$ 是域的子集，包含那些不映射到零的元素。 |

> 英文原表 / English original

| Term | Explanation |
| --- | --- |
| Manifold | A topological space that locally resembles Euclidean space near each point. Precisely, when this Euclidean space is of dimension $n$ , the manifold is referred as $n$-manifold . |
| Support | A real-valued function $f$ is the subset of the domain containing those elements which are not mapped to zero . |

[Arjovsky and Bottou (2017)](https://arxiv.org/pdf/1701.04862.pdf) 讨论了 [支持](https://en.wikipedia.org/wiki/Support_(mathematics)) $p_r$ 和 $p_g$ 位于低维 [流形](https://en.wikipedia.org/wiki/Manifold) 的问题，以及它如何在一个非常理论化的论文 [“Towards principled methods for training generative adversarial networks”](https://arxiv.org/pdf/1701.04862.pdf) 中彻底地导致 GAN 训练的不稳定性。

> [Arjovsky and Bottou (2017)](https://arxiv.org/pdf/1701.04862.pdf) discussed the problem of the [supports](https://en.wikipedia.org/wiki/Support_(mathematics)) of $p_r$ and $p_g$ lying on low dimensional [manifolds](https://en.wikipedia.org/wiki/Manifold) and how it contributes to the instability of GAN training thoroughly in a very theoretical paper [“Towards principled methods for training generative adversarial networks”](https://arxiv.org/pdf/1701.04862.pdf).

许多真实世界数据集的维度，如 `p_r` 所表示的，似乎只是 **人为地高**。它们被发现集中在一个较低维度的流形中。这实际上是 [流形学习](http://scikit-learn.org/stable/modules/manifold.html) 的基本假设。考虑到真实世界的图像，一旦主题或包含的对象确定，图像就会有很多限制需要遵循，例如，一只狗应该有两只耳朵和一条尾巴，一座摩天大楼应该有一个笔直高大的身体等等。这些限制使得图像无法拥有高维度的自由形式。

英文原文：The dimensions of many real-world datasets, as represented by `p_r`, only appear to be artificially high. They have been found to concentrate in a lower dimensional manifold. This is actually the fundamental assumption for [Manifold Learning](http://scikit-learn.org/stable/modules/manifold.html). Thinking of the real world images, once the theme or the contained object is fixed, the images have a lot of restrictions to follow, i.e., a dog should have two ears and a tail, and a skyscraper should have a straight and tall body, etc. These restrictions keep images aways from the possibility of having a high-dimensional free form.

$p_g$ 也位于低维流形中。每当生成器被要求根据一个小的维度（例如100）的噪声变量输入 $z$ 生成一个大得多的图像（例如64x64）时，这4096个像素的颜色分布就已经由这个小的100维随机数向量定义了，并且很难填满整个高维空间。

> $p_g$ lies in a low dimensional manifolds, too. Whenever the generator is asked to a much larger image like 64x64 given a small dimension, such as 100, noise variable input $z$, the distribution of colors over these 4096 pixels has been defined by the small 100-dimension random number vector and can hardly fill up the whole high dimensional space.

因为 $p_g$ 和 $p_r$ 都位于低维流形中，它们几乎肯定是不相交的（参见图4）。当它们具有不相交的支持集时，我们总是能够找到一个完美的判别器，100%正确地分离真实样本和伪造样本。如果您对证明感兴趣，请查阅这篇 [论文](https://arxiv.org/pdf/1701.04862.pdf)。

> Because both $p_g$ and $p_r$ rest in low dimensional manifolds, they are almost certainly gonna be disjoint (See Fig. 4). When they have disjoint supports, we are always capable of finding a perfect discriminator that separates real and fake samples 100% correctly. Check the [paper](https://arxiv.org/pdf/1701.04862.pdf) if you are curious about the proof.

![Low dimensional manifolds in high dimension space can hardly have overlaps. (Left) Two lines in a three-dimension space. (Right) Two surfaces in a three-dimension space.](https://lilianweng.github.io/posts/2017-08-20-gan/low_dim_manifold.png)

#### 梯度消失

> Vanishing gradient

当判别器完美时，我们能保证得到 $D(x) = 1, \forall x \in p_r$ 和 $D(x) = 0, \forall x \in p_g$。因此，损失函数 $L$ 降至零，我们在学习迭代过程中最终没有梯度来更新损失。图 5 展示了一个实验，当判别器表现更好时，梯度会快速消失。

> When the discriminator is perfect, we are guaranteed with $D(x) = 1, \forall x \in p_r$ and $D(x) = 0, \forall x \in p_g$. Therefore the loss function $L$ falls to zero and we end up with no gradient to update the loss during learning iterations. Fig. 5 demonstrates an experiment when the discriminator gets better, the gradient vanishes fast.

![First, a DCGAN is trained for 1, 10 and 25 epochs. Then, with the **generator fixed**, a discriminator is trained from scratch and measure the gradients with the original cost function. We see the gradient norms **decay quickly** (in log scale), in the best case 5 orders of magnitude after 4000 discriminator iterations. (Image source: Arjovsky and Bottou, 2017 )](https://lilianweng.github.io/posts/2017-08-20-gan/GAN_vanishing_gradient.png)

因此，训练 GAN 面临一个 **困境**：

> As a result, training a GAN faces a **dilemma**:

- 如果判别器表现不佳，生成器就没有准确的反馈，损失函数也无法代表真实情况。
- 如果判别器表现出色，损失函数的梯度会降至接近零，学习过程会变得极其缓慢甚至停滞。

> • If the discriminator behaves badly, the generator does not have accurate feedback and the loss function cannot represent the reality.
> • If the discriminator does a great job, the gradient of the loss function drops down to close to zero and the learning becomes super slow or even jammed.

这个困境显然会使 GAN 的训练变得非常困难。

> This dilemma clearly is capable to make the GAN training very tough.

#### 模式崩溃

> Mode collapse

在训练过程中，生成器可能会崩溃到总是产生相同输出的状态。这是 GAN 的一个常见故障，通常被称为 **模式崩溃**。尽管生成器可能能够欺骗相应的判别器，但它未能学会表示复杂的真实世界数据分布，并陷入一个多样性极低的小空间中。

> During the training, the generator may collapse to a setting where it always produces same outputs. This is a common failure case for GANs, commonly referred to as **Mode Collapse**. Even though the generator might be able to trick the corresponding discriminator, it fails to learn to represent the complex real-world data distribution and gets stuck in a small space with extremely low variety.

![A DCGAN model is trained with an MLP network with 4 layers, 512 units and ReLU activation function, configured to lack a strong inductive bias for image generation. The results shows a significant degree of mode collapse. (Image source: Arjovsky, Chintala, & Bottou, 2017. )](https://lilianweng.github.io/posts/2017-08-20-gan/mode_collapse.png)

#### 缺乏合适的评估指标

> Lack of a proper evaluation metric

生成对抗网络天生不具备一个好的目标函数来告知我们训练进度。如果没有一个好的评估指标，就像在黑暗中工作。没有好的迹象来判断何时停止；没有好的指标来比较多个模型的性能。

> Generative adversarial networks are not born with a good objection function that can inform us the training progress. Without a good evaluation metric, it is like working in the dark. No good sign to tell when to stop; No good indicator to compare the performance of multiple models.

### 改进的 GAN 训练

> Improved GAN Training

以下建议旨在帮助稳定和改进 GAN 的训练。

> The following suggestions are proposed to help stabilize and improve the training of GANs.

前五种方法是实现 GAN 训练更快收敛的实用技术，在 [“Improve Techniques for Training GANs”](http://papers.nips.cc/paper/6125-improved-techniques-for-training-gans.pdf) 中提出。后两种方法在 [“Towards principled methods for training generative adversarial networks”](https://arxiv.org/pdf/1701.04862.pdf) 中提出，旨在解决不相交分布的问题。

> First five methods are practical techniques to achieve faster convergence of GAN training, proposed in [“Improve Techniques for Training GANs”](http://papers.nips.cc/paper/6125-improved-techniques-for-training-gans.pdf).
> The last two are proposed in [“Towards principled methods for training generative adversarial networks”](https://arxiv.org/pdf/1701.04862.pdf) to solve the problem of disjoint distributions.

(1) **特征匹配**

> (1) **Feature Matching**

特征匹配建议优化判别器，以检查生成器的输出是否与真实样本的预期统计数据匹配。在这种情况下，新的损失函数定义为 $| \mathbb{E}_{x \sim p_r} f(x) - \mathbb{E}_{z \sim p_z(z)}f(G(z)) |_2^2$，其中 $f(x)$ 可以是特征统计数据的任何计算，例如均值或中位数。

> Feature matching suggests to optimize the discriminator to inspect whether the generator’s output matches expected statistics of the real samples. In such a scenario, the new loss function is defined as $| \mathbb{E}_{x \sim p_r} f(x) - \mathbb{E}_{z \sim p_z(z)}f(G(z)) |_2^2$, where $f(x)$ can be any computation of statistics of features, such as mean or median.

(2) **小批量判别**

> (2) **Minibatch Discrimination**

通过小批量判别，判别器能够理解一个批次中训练数据点之间的关系，而不是独立处理每个点。

> With minibatch discrimination, the discriminator is able to digest the relationship between training data points in one batch, instead of processing each point independently.

在一个小批量中，我们近似计算每对样本之间的接近度 $c(x_i, x_j)$，并通过将一个数据点与同一批次中其他样本的接近度求和来获得该数据点的总体摘要 $o(x_i) = \sum_{j} c(x_i, x_j)$。然后将 $o(x_i)$ 明确地添加到模型的输入中。

> In one minibatch, we approximate the closeness between every pair of samples, $c(x_i, x_j)$, and get the overall summary of one data point by summing up how close it is to other samples in the same batch, $o(x_i) = \sum_{j} c(x_i, x_j)$. Then $o(x_i)$ is explicitly added to the input of the model.

(3) **历史平均**

> (3) **Historical Averaging**

对于这两个模型，将 $| \Theta - \frac{1}{t} \sum_{i=1}^t \Theta_i |^2$ 添加到损失函数中，其中 $\Theta$ 是模型参数，$\Theta_i$ 是参数在过去的训练时间 $i$ 的配置方式。当 $\Theta$ 随时间变化过于剧烈时，这个附加项会惩罚训练速度。

> For both models, add $| \Theta - \frac{1}{t} \sum_{i=1}^t \Theta_i |^2$ into the loss function, where $\Theta$ is the model parameter and $\Theta_i$ is how the parameter is configured at the past training time $i$. This addition piece penalizes the training speed when $\Theta$ is changing too dramatically in time.

(4) **单边标签平滑**

> (4) **One-sided Label Smoothing**

在向判别器输入时，不提供 1 和 0 的标签，而是使用 0.9 和 0.1 等软化值。这被证明可以降低网络的脆弱性。

> When feeding the discriminator, instead of providing 1 and 0 labels, use soften values such as 0.9 and 0.1. It is shown to reduce the networks’ vulnerability.

(5) **虚拟批量归一化** (VBN)

> (5) **Virtual Batch Normalization** (VBN)

每个数据样本都基于一个固定的数据批次（*“参考批次”*）进行归一化，而不是在其小批量内进行。参考批次在开始时选择一次，并在整个训练过程中保持不变。

> Each data sample is normalized based on a fixed batch (*“reference batch”*) of data rather than within its minibatch. The reference batch is chosen once at the beginning and stays the same through the training.

**Theano 实现**: [openai/improved-gan](https://github.com/openai/improved-gan)

> **Theano Implementation**: [openai/improved-gan](https://github.com/openai/improved-gan)

(6) **添加噪声**。

> (6) **Adding Noises**.

根据[上一节](https://lilianweng.github.io/posts/2017-08-20-gan/#low-dimensional-supports)的讨论，我们现在知道 $p_r$ 和 $p_g$ 在高维空间中是不相交的，这导致了梯度消失问题。为了人为地“展开”分布并增加两个概率分布重叠的机会，一个解决方案是在判别器的输入中添加连续噪声 $D$。

> Based on the discussion in the [previous section](https://lilianweng.github.io/posts/2017-08-20-gan/#low-dimensional-supports), we now know $p_r$ and $p_g$ are disjoint in a high dimensional space and it causes the problem of vanishing gradient. To artificially “spread out” the distribution and to create higher chances for two probability distributions to have overlaps, one solution is to add continuous noises onto the inputs of the discriminator $D$.

(7) **使用更好的分布相似性度量**

> (7) **Use Better Metric of Distribution Similarity**

原始 GAN 的损失函数衡量 $p_r$ 和 $p_g$ 分布之间的 JS 散度。当两个分布不相交时，此度量无法提供有意义的值。

> The loss function of the vanilla GAN measures the JS divergence between the distributions of $p_r$ and $p_g$. This metric fails to provide a meaningful value when two distributions are disjoint.

提出了[Wasserstein 度量](https://en.wikipedia.org/wiki/Wasserstein_metric)来替代 JS 散度，因为它具有更平滑的值空间。更多内容请参见下一节。

> [Wasserstein metric](https://en.wikipedia.org/wiki/Wasserstein_metric) is proposed to replace JS divergence because it has a much smoother value space. See more in the next section.

### Wasserstein GAN (WGAN)

> Wasserstein GAN (WGAN)

#### 什么是 Wasserstein 距离？

> What is Wasserstein distance?

[Wasserstein 距离](https://en.wikipedia.org/wiki/Wasserstein_metric)是衡量两个概率分布之间距离的一种度量。它也被称为**推土机距离**，简称 EM 距离，因为非正式地，它可以解释为将一堆泥土从一个概率分布的形状移动并转换为另一个分布形状所需的最小能量成本。成本量化为：移动的泥土量 x 移动距离。

> [Wasserstein Distance](https://en.wikipedia.org/wiki/Wasserstein_metric) is a measure of the distance between two probability distributions.
> It is also called **Earth Mover’s distance**, short for EM distance, because informally it can be interpreted as the minimum energy cost of moving and transforming a pile of dirt in the shape of one probability distribution to the shape of the other distribution. The cost is quantified by: the amount of dirt moved x the moving distance.

让我们首先看一个概率域是*离散*的简单情况。例如，假设我们有两个分布 $P$ 和 $Q$，每个分布有四堆泥土，并且总共有十铲泥土。每堆泥土中的铲数分配如下：

> Let us first look at a simple case where the probability domain is *discrete*. For example, suppose we have two distributions $P$ and $Q$, each has four piles of dirt and both have ten shovelfuls of dirt in total. The numbers of shovelfuls in each dirt pile are assigned as follows:

$$
\begin{aligned}
& P_1 = 3, P_2 = 2, P_3 = 1, P_4 = 4\\
& Q_1 = 1, Q_2 = 2, Q_3 = 4, Q_4 = 3
\end{aligned}
$$

为了使 $P$ 看起来像 $Q$，如图 7 所示，我们：

> In order to change $P$ to look like $Q$, as illustrated in Fig. 7, we:

• 首先将 2 铲泥土从 $P_1$ 移动到 $P_2$ => $(P_1, Q_1)$ 匹配。

• 然后将 2 铲泥土从 $P_2$ 移动到 $P_3$ => $(P_2, Q_2)$ 匹配。

• 最后将 1 铲泥土从 $Q_3$ 移动到 $Q_4$ => $(P_3, Q_3)$ 和 $(P_4, Q_4)$ 匹配。

英文原文：

• First move 2 shovelfuls from $P_1$ to $P_2$ => $(P_1, Q_1)$ match up.

• Then move 2 shovelfuls from $P_2$ to $P_3$ => $(P_2, Q_2)$ match up.

• Finally move 1 shovelfuls from $Q_3$ to $Q_4$ => $(P_3, Q_3)$ and $(P_4, Q_4)$ match up.

如果我们把使 $P_i$ 和 $Q_i$ 匹配的成本标记为 $\delta_i$，那么我们将得到 $\delta_{i+1} = \delta_i + P_i - Q_i$，在示例中：

> If we label the cost to pay to make $P_i$ and $Q_i$ match as $\delta_i$, we would have $\delta_{i+1} = \delta_i + P_i - Q_i$ and in the example:

$$
\begin{aligned}
\delta_0 &= 0\\
\delta_1 &= 0 + 3 - 1 = 2\\
\delta_2 &= 2 + 2 - 2 = 2\\
\delta_3 &= 2 + 1 - 4 = -1\\
\delta_4 &= -1 + 4 - 3 = 0
\end{aligned}
$$

最后，地球移动距离是 $W = \sum \vert \delta_i \vert = 5$。

> Finally the Earth Mover’s distance is $W = \sum \vert \delta_i \vert = 5$.

![Step-by-step plan of moving dirt between piles in $P$ and $Q$ to make them match.](https://lilianweng.github.io/posts/2017-08-20-gan/EM_distance_discrete.png)

在处理连续概率域时，距离公式变为：

> When dealing with the continuous probability domain, the distance formula becomes:

$$
W(p_r, p_g) = \inf_{\gamma \sim \Pi(p_r, p_g)} \mathbb{E}_{(x, y) \sim \gamma}[\| x-y \|]
$$

在上述公式中，$\Pi(p_r, p_g)$ 是 $p_r$ 和 $p_g$ 之间所有可能的联合概率分布的集合。一个联合分布 $\gamma \in \Pi(p_r, p_g)$ 描述了一个泥土运输方案，与上面的离散示例相同，但在连续概率空间中。精确地说，$\gamma(x, y)$ 表示应将百分之多少的泥土从点 $x$ 运输到 $y$，以使 $x$ 遵循与 $y$ 相同的概率分布。这就是为什么 $x$ 上的边际分布加起来等于 $p_g$，$\sum_{x} \gamma(x, y) = p_g(y)$ (一旦我们完成将计划数量的泥土从每个可能的 $x$ 移动到目标 $y$，我们最终会得到与 $y$ 根据 $p_g$ 所拥有的完全相同的东西。) 反之亦然 $\sum_{y} \gamma(x, y) = p_r(x)$。

> In the formula above, $\Pi(p_r, p_g)$ is the set of all possible joint probability distributions between $p_r$ and $p_g$. One joint distribution $\gamma \in \Pi(p_r, p_g)$ describes one dirt transport plan, same as the discrete example above, but in the continuous probability space. Precisely $\gamma(x, y)$ states the percentage of dirt should be transported from point $x$ to $y$ so as to make $x$ follows the same probability distribution of $y$. That’s why the marginal distribution over $x$ adds up to $p_g$, $\sum_{x} \gamma(x, y) = p_g(y)$ (Once we finish moving the planned amount of dirt from every possible $x$ to the target $y$, we end up with exactly what $y$ has according to $p_g$.) and vice versa $\sum_{y} \gamma(x, y) = p_r(x)$.

当将 $x$ 视为起点，将 $y$ 视为终点时，移动的泥土总量是 $\gamma(x, y)$，移动距离是 $| x-y |$，因此成本是 $\gamma(x, y) \cdot | x-y |$。所有 $(x,y)$ 对的平均预期成本可以很容易地计算为：

> When treating $x$ as the starting point and $y$ as the destination, the total amount of dirt moved is $\gamma(x, y)$ and the travelling distance is $| x-y |$ and thus the cost is $\gamma(x, y) \cdot | x-y |$. The expected cost averaged across all the $(x,y)$ pairs can be easily computed as:

$$
\sum_{x, y} \gamma(x, y) \| x-y \| 
= \mathbb{E}_{x, y \sim \gamma} \| x-y \|
$$

最后，我们将所有泥土移动解决方案成本中的最小值作为EM距离。在Wasserstein距离的定义中，$\inf$ ([下确界](https://en.wikipedia.org/wiki/Infimum_and_supremum)，也称为 *最大下界*) 表示我们只对最小成本感兴趣。

> Finally, we take the minimum one among the costs of all dirt moving solutions as the EM distance. In the definition of Wasserstein distance, the $\inf$ ([infimum](https://en.wikipedia.org/wiki/Infimum_and_supremum), also known as *greatest lower bound*) indicates that we are only interested in the smallest cost.

#### 为什么Wasserstein比JS或KL散度更好？

> Why Wasserstein is better than JS or KL divergence?

即使当两个分布位于没有重叠的低维流形中时，Wasserstein距离仍然可以提供它们之间距离的有意义且平滑的表示。

> Even when two distributions are located in lower dimensional manifolds without overlaps, Wasserstein distance can still provide a meaningful and smooth representation of the distance in-between.

WGAN论文通过一个简单的例子阐述了这个想法。

> The WGAN paper exemplified the idea with a simple example.

假设我们有两个概率分布，$P$ 和 $Q$：

> Suppose we have two probability distributions, $P$ and $Q$:

$$
\forall (x, y) \in P, x = 0 \text{ and } y \sim U(0, 1)\\
\forall (x, y) \in Q, x = \theta, 0 \leq \theta \leq 1 \text{ and } y \sim U(0, 1)\\
$$

![There is no overlap between $P$ and $Q$ when $\theta \neq 0$.](https://lilianweng.github.io/posts/2017-08-20-gan/wasserstein_simple_example.png)

当 $\theta \neq 0$ 时：

> When $\theta \neq 0$:

$$
\begin{aligned}
D_{KL}(P \| Q) &= \sum_{x=0, y \sim U(0, 1)} 1 \cdot \log\frac{1}{0} = +\infty \\
D_{KL}(Q \| P) &= \sum_{x=\theta, y \sim U(0, 1)} 1 \cdot \log\frac{1}{0} = +\infty \\
D_{JS}(P, Q) &= \frac{1}{2}(\sum_{x=0, y \sim U(0, 1)} 1 \cdot \log\frac{1}{1/2} + \sum_{x=0, y \sim U(0, 1)} 1 \cdot \log\frac{1}{1/2}) = \log 2\\
W(P, Q) &= |\theta|
\end{aligned}
$$

但是当 $\theta = 0$ 时，两个分布完全重叠：

> But when $\theta = 0$, two distributions are fully overlapped:

$$
\begin{aligned}
D_{KL}(P \| Q) &= D_{KL}(Q \| P) = D_{JS}(P, Q) = 0\\
W(P, Q) &= 0 = \lvert \theta \rvert
\end{aligned}
$$

$D_{KL}$ 在两个分布不相交时给出无穷大。$D_{JS}$ 的值有突然的跳跃，在 $\theta = 0$ 处不可微分。只有Wasserstein度量提供了一个平滑的度量，这对于使用梯度下降的稳定学习过程非常有帮助。

> $D_{KL}$ gives us inifity when two distributions are disjoint. The value of $D_{JS}$ has sudden jump, not differentiable at $\theta = 0$. Only Wasserstein metric provides a smooth measure, which is super helpful for a stable learning process using gradient descents.

#### 使用Wasserstein距离作为GAN损失函数

> Use Wasserstein distance as GAN loss function

在 $\Pi(p_r, p_g)$ 中穷举所有可能的联合分布来计算 $\inf_{\gamma \sim \Pi(p_r, p_g)}$ 是难以处理的。因此，作者基于Kantorovich-Rubinstein对偶性提出了一种巧妙的公式转换，变为：

> It is intractable to exhaust all the possible joint distributions in $\Pi(p_r, p_g)$ to compute $\inf_{\gamma \sim \Pi(p_r, p_g)}$. Thus the authors proposed a smart transformation of the formula based on the Kantorovich-Rubinstein duality to:

$$
W(p_r, p_g) = \frac{1}{K} \sup_{\| f \|_L \leq K} \mathbb{E}_{x \sim p_r}[f(x)] - \mathbb{E}_{x \sim p_g}[f(x)]
$$

其中 $\sup$ ([上确界](https://en.wikipedia.org/wiki/Infimum_and_supremum)) 与 $inf$ (下确界) 相反；我们想要测量最小上界，或者更简单地说，最大值。

> where $\sup$ ([supremum](https://en.wikipedia.org/wiki/Infimum_and_supremum)) is the opposite of $inf$ (infimum); we want to measure the least upper bound or, in even simpler words, the maximum value.

**Lipschitz连续性？**

> **Lipschitz continuity?**

新形式的Wasserstein度量中的函数 $f$ 被要求满足 $| f |_L \leq K$，这意味着它应该是 [K-Lipschitz连续的](https://en.wikipedia.org/wiki/Lipschitz_continuity)。

> The function $f$ in the new form of Wasserstein metric is demanded to satisfy $| f |_L \leq K$, meaning it should be [K-Lipschitz continuous](https://en.wikipedia.org/wiki/Lipschitz_continuity).

一个实值函数 $f: \mathbb{R} \rightarrow \mathbb{R}$ 被称为 $K$ -Lipschitz连续的，如果存在一个实常数 $K \geq 0$，使得对于所有 $x_1, x_2 \in \mathbb{R}$，

> A real-valued function $f: \mathbb{R} \rightarrow \mathbb{R}$ is called $K$ -Lipschitz continuous if there exists a real constant $K \geq 0$ such that, for all $x_1, x_2 \in \mathbb{R}$,

$$
\lvert f(x_1) - f(x_2) \rvert \leq K \lvert x_1 - x_2 \rvert
$$

这里 $K$ 被称为函数 $f(.)$ 的Lipschitz常数。处处连续可微的函数是Lipschitz连续的，因为导数（估计为 $\frac{\lvert f(x_1) - f(x_2) \rvert}{\lvert x_1 - x_2 \rvert}$）有界。然而，Lipschitz连续函数可能并非处处可微，例如 $f(x) = \lvert x \rvert$。

> Here $K$ is known as a Lipschitz constant for function $f(.)$. Functions that are everywhere continuously differentiable is Lipschitz continuous, because the derivative, estimated as $\frac{\lvert f(x_1) - f(x_2) \rvert}{\lvert x_1 - x_2 \rvert}$, has bounds. However, a Lipschitz continuous function may not be everywhere differentiable, such as $f(x) = \lvert x \rvert$.

解释Wasserstein距离公式如何进行转换本身就值得写一篇长文，所以这里我跳过细节。如果你对如何使用线性规划计算Wasserstein度量，或者如何根据Kantorovich-Rubinstein对偶性将Wasserstein度量转换为其对偶形式感兴趣，请阅读这篇 [很棒的文章](https://vincentherrmann.github.io/blog/wasserstein/)。

> Explaining how the transformation happens on the Wasserstein distance formula is worthy of a long post by itself, so I skip the details here. If you are interested in how to compute Wasserstein metric using linear programming, or how to transfer Wasserstein metric into its dual form according to the Kantorovich-Rubinstein Duality, read this [awesome post](https://vincentherrmann.github.io/blog/wasserstein/).

假设这个函数 $f$ 来自一个K-Lipschitz连续函数族 $\{ f_w \}_{w \in W}$，由 $w$ 参数化。在修改后的Wasserstein-GAN中，“判别器”模型用于学习 $w$ 以找到一个好的 $f_w$，并且损失函数被配置为测量 $p_r$ 和 $p_g$ 之间的Wasserstein距离。

> Suppose this function $f$ comes from a family of K-Lipschitz continuous functions, $\{ f_w \}_{w \in W}$, parameterized by $w$. In the modified Wasserstein-GAN, the “discriminator” model is used to learn $w$ to find a good $f_w$ and the loss function is configured as measuring the Wasserstein distance between $p_r$ and $p_g$.

$$
L(p_r, p_g) = W(p_r, p_g) = \max_{w \in W} \mathbb{E}_{x \sim p_r}[f_w(x)] - \mathbb{E}_{z \sim p_r(z)}[f_w(g_\theta(z))]
$$

因此，“判别器”不再是直接区分假样本和真实样本的批评者。相反，它被训练来学习一个 $K$ -Lipschitz 连续函数，以帮助计算 Wasserstein 距离。随着训练中损失函数的减小，Wasserstein 距离变得更小，生成器模型的输出也越来越接近真实数据分布。

> Thus the “discriminator” is not a direct critic of telling the fake samples apart from the real ones anymore. Instead, it is trained to learn a $K$ -Lipschitz continuous function to help compute Wasserstein distance. As the loss function decreases in the training, the Wasserstein distance gets smaller and the generator model’s output grows closer to the real data distribution.

一个大问题是在训练过程中保持$K$ -Lipschitz 连续性$f_w$，以使一切正常运行。该论文提出了一种简单但非常实用的技巧：在每次梯度更新后，将权重$w$限制在一个小范围内，例如$[-0.01, 0.01]$，从而形成一个紧凑的参数空间$W$，因此$f_w$获得其下限和上限以保持 Lipschitz 连续性。

> One big problem is to maintain the $K$ -Lipschitz continuity of $f_w$ during the training in order to make everything work out. The paper presents a simple but very practical trick: After every gradient update, clamp the weights $w$ to a small window, such as $[-0.01, 0.01]$, resulting in a compact parameter space $W$ and thus $f_w$ obtains its lower and upper bounds to preserve the Lipschitz continuity.

![Algorithm of Wasserstein generative adversarial network. (Image source: Arjovsky, Chintala, & Bottou, 2017. )](https://lilianweng.github.io/posts/2017-08-20-gan/WGAN_algorithm.png)

与原始 GAN 算法相比，WGAN 进行了以下更改：

> Compared to the original GAN algorithm, the WGAN undertakes the following changes:

• 在评论家函数上的每次梯度更新之后，将权重限制在一个小的固定范围内，$[-c, c]$。

• 使用从 Wasserstein 距离导出的新损失函数，不再有对数。 “判别器”模型不再充当直接的评论家，而是作为估计真实数据分布和生成数据分布之间 Wasserstein 度量的辅助工具。

• 根据经验，作者推荐在评论家上使用 [RMSProp](http://www.cs.toronto.edu/~tijmen/csc321/slides/lecture_slides_lec6.pdf) 优化器，而不是基于动量的优化器，例如 [Adam](https://arxiv.org/abs/1412.6980v8)，后者可能导致模型训练不稳定。 我还没有看到关于这一点的明确理论解释。

英文原文：

• After every gradient update on the critic function, clamp the weights to a small fixed range, $[-c, c]$.

• Use a new loss function derived from the Wasserstein distance, no logarithm anymore. The “discriminator” model does not play as a direct critic but a helper for estimating the Wasserstein metric between real and generated data distribution.

• Empirically the authors recommended [RMSProp](http://www.cs.toronto.edu/~tijmen/csc321/slides/lecture_slides_lec6.pdf) optimizer on the critic, rather than a momentum based optimizer such as [Adam](https://arxiv.org/abs/1412.6980v8) which could cause instability in the model training. I haven’t seen clear theoretical explanation on this point through.

遗憾的是，Wasserstein GAN 并非完美无缺。即使原始 WGAN 论文的作者也提到*“权重裁剪显然是强制执行 Lipschitz 约束的一种糟糕方式”*（哎呀！）。WGAN 仍然存在训练不稳定、权重裁剪后收敛缓慢（当裁剪窗口过大时）以及梯度消失（当裁剪窗口过小时）的问题。

> Sadly, Wasserstein GAN is not perfect. Even the authors of the original WGAN paper mentioned that *“Weight clipping is a clearly terrible way to enforce a Lipschitz constraint”* (Oops!). WGAN still suffers from unstable training, slow convergence after weight clipping (when clipping window is too large), and vanishing gradients (when clipping window is too small).

一些改进，确切地说是用**梯度惩罚**取代权重裁剪，已在[Gulrajani et al. 2017](https://arxiv.org/pdf/1704.00028.pdf)中讨论过。我将在未来的文章中讨论这一点。

> Some improvement, precisely replacing weight clipping with **gradient penalty**, has been discussed in [Gulrajani et al. 2017](https://arxiv.org/pdf/1704.00028.pdf). I will leave this to a future post.

### 示例：创建新的宝可梦！

> Example: Create New Pokemons!

出于乐趣，我尝试了 [carpedm20/DCGAN-tensorflow](https://github.com/carpedm20/DCGAN-tensorflow) 在一个小型数据集上，[Pokemon sprites](https://github.com/PokeAPI/sprites/)。该数据集只有大约900张宝可梦图片，其中包括同一宝可梦物种的不同形态。

> Just for fun, I tried out [carpedm20/DCGAN-tensorflow](https://github.com/carpedm20/DCGAN-tensorflow) on a tiny dataset, [Pokemon sprites](https://github.com/PokeAPI/sprites/). The dataset only has 900-ish pokemon images, including different levels of same pokemon species.

让我们看看模型能够创造出什么类型的新宝可梦。不幸的是，由于训练数据量很小，新宝可梦只有粗略的形状，没有细节。随着训练周期的增加，形状和颜色确实看起来更好了！万岁！

> Let’s check out what types of new pokemons the model is able to create.
> Unfortunately due to the tiny training data, the new pokemons only have rough shapes without details. The shapes and colors do look better with more training epoches! Hooray!

![Train carpedm20/DCGAN-tensorflow on a set of Pokemon sprite images. The sample outputs are listed after training epoches = 7, 21, 49.](https://lilianweng.github.io/posts/2017-08-20-gan/pokemon-GAN.png)

如果您对[carpedm20/DCGAN-tensorflow](https://github.com/carpedm20/DCGAN-tensorflow)的带注释版本以及如何修改它来训练WGAN和带有梯度惩罚的WGAN感兴趣，请查看[lilianweng/unified-gan-tensorflow](https://github.com/lilianweng/unified-gan-tensorflow)。

> If you are interested in a commented version of [carpedm20/DCGAN-tensorflow](https://github.com/carpedm20/DCGAN-tensorflow) and how to modify it to train WGAN and WGAN with gradient penalty, check [lilianweng/unified-gan-tensorflow](https://github.com/lilianweng/unified-gan-tensorflow).

引用方式：

> Cited as:

```
@article{weng2017gan,
  title   = "From GAN to WGAN",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2017",
  url     = "https://lilianweng.github.io/posts/2017-08-20-gan/"
}
```

或

> OR

```
@misc{weng2019gan,
    title={From GAN to WGAN},
    author={Lilian Weng},
    year={2019},
    eprint={1904.08994},
    archivePrefix={arXiv},
    primaryClass={cs.LG}
}
```

### 参考文献

> References

[1] Goodfellow, Ian, et al. [“生成对抗网络。”](https://arxiv.org/pdf/1406.2661.pdf) NIPS, 2014.

> [1] Goodfellow, Ian, et al. [“Generative adversarial nets.”](https://arxiv.org/pdf/1406.2661.pdf) NIPS, 2014.

[2] Tim Salimans, et al. [“改进的GAN训练技术。”](http://papers.nips.cc/paper/6125-improved-techniques-for-training-gans.pdf) NIPS 2016.

> [2] Tim Salimans, et al. [“Improved techniques for training gans.”](http://papers.nips.cc/paper/6125-improved-techniques-for-training-gans.pdf) NIPS 2016.

[3] Martin Arjovsky and Léon Bottou. [“迈向训练生成对抗网络的原则性方法。”](https://arxiv.org/pdf/1701.04862.pdf) arXiv preprint arXiv:1701.04862 (2017).

> [3] Martin Arjovsky and Léon Bottou. [“Towards principled methods for training generative adversarial networks.”](https://arxiv.org/pdf/1701.04862.pdf) arXiv preprint arXiv:1701.04862 (2017).

[4] Martin Arjovsky, Soumith Chintala, and Léon Bottou. [“Wasserstein GAN。”](https://arxiv.org/pdf/1701.07875.pdf) arXiv preprint arXiv:1701.07875 (2017).

> [4] Martin Arjovsky, Soumith Chintala, and Léon Bottou. [“Wasserstein GAN.”](https://arxiv.org/pdf/1701.07875.pdf) arXiv preprint arXiv:1701.07875 (2017).

[5] Ishaan Gulrajani, Faruk Ahmed, Martin Arjovsky, Vincent Dumoulin, Aaron Courville. [改进的Wasserstein GAN训练。](https://arxiv.org/pdf/1704.00028.pdf) arXiv preprint arXiv:1704.00028 (2017).

> [5] Ishaan Gulrajani, Faruk Ahmed, Martin Arjovsky, Vincent Dumoulin, Aaron Courville. [Improved training of wasserstein gans.](https://arxiv.org/pdf/1704.00028.pdf) arXiv preprint arXiv:1704.00028 (2017).

[6] [在变换下计算地球移动距离](http://robotics.stanford.edu/~scohen/research/emdg/emdg.html)

> [6] [Computing the Earth Mover’s Distance under Transformations](http://robotics.stanford.edu/~scohen/research/emdg/emdg.html)

[7] [Wasserstein GAN与Kantorovich-Rubinstein对偶性](https://vincentherrmann.github.io/blog/wasserstein/)

> [7] [Wasserstein GAN and the Kantorovich-Rubinstein Duality](https://vincentherrmann.github.io/blog/wasserstein/)

[8] [zhuanlan.zhihu.com/p/25071913](https://zhuanlan.zhihu.com/p/25071913)

> [8] [zhuanlan.zhihu.com/p/25071913](https://zhuanlan.zhihu.com/p/25071913)

[9] Ferenc Huszár. [“如何（不）训练你的生成模型：计划采样、似然、对抗？”](https://arxiv.org/pdf/1511.05101.pdf) arXiv preprint arXiv:1511.05101 (2015).

> [9] Ferenc Huszár. [“How (not) to Train your Generative Model: Scheduled Sampling, Likelihood, Adversary?.”](https://arxiv.org/pdf/1511.05101.pdf) arXiv preprint arXiv:1511.05101 (2015).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Generative Adversarial Networks (GAN) | 生成对抗网络 (GAN) | 一种深度学习模型，通过生成器和判别器的对抗训练来生成新数据。 |
| Kullback–Leibler divergence (KL divergence) | Kullback–Leibler散度 (KL散度) | 衡量一个概率分布与另一个预期概率分布差异程度的指标，不对称。 |
| Jensen–Shannon divergence (JS divergence) | Jensen–Shannon散度 (JS散度) | 衡量两个概率分布之间相似性的指标，对称且值域受限。 |
| Discriminator | 判别器 | GAN中的一个模型，用于估计给定样本来自真实数据集的概率，区分真实样本和生成样本。 |
| Generator | 生成器 | GAN中的一个模型，根据噪声变量输入生成合成样本，旨在欺骗判别器。 |
| Minimax game | 最小最大博弈 | 博弈论中的一种策略，一方试图最小化另一方最大化其收益的策略。 |
| Nash equilibrium | 纳什均衡 | 博弈论中的一个概念，指在给定其他参与者策略的情况下，每个参与者都无法通过单方面改变策略来提高自身收益的状态。 |
| Low-dimensional manifold | 低维流形 | 高维空间中具有较低内在维度的子空间，真实世界数据常被认为集中于此。 |
| Vanishing gradients | 梯度消失 | 深度学习训练中，梯度变得非常小，导致模型参数更新缓慢或停滞的问题。 |
| Mode collapse | 模式崩溃 | GAN训练中的一个常见问题，生成器只生成有限的几种样本，未能覆盖真实数据分布的多样性。 |
| Wasserstein distance (Earth Mover's distance, EM distance) | Wasserstein距离 (推土机距离，EM距离) | 衡量两个概率分布之间距离的一种度量，表示将一个分布转换为另一个所需的最小“工作量”。 |
| Lipschitz continuity | Lipschitz连续性 | 函数的一种性质，其变化率有界，即函数值的变化不超过自变量变化乘以一个常数K。 |
| Weight clipping | 权重裁剪 | WGAN中用于强制执行Lipschitz约束的一种技术，通过将模型权重限制在特定范围内。 |
| Gradient penalty | 梯度惩罚 | WGAN-GP中取代权重裁剪的方法，通过惩罚判别器梯度的范数来强制执行Lipschitz约束。 |
| RMSProp | RMSProp优化器 | 一种自适应学习率优化算法，通过调整每个参数的学习率来加速训练。 |
