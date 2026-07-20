# 谨慎看待缩放定律

> Scaling Laws, Carefully

> 来源：Lil'Log / Lilian Weng，2026-06-24
> 原文链接：https://lilianweng.github.io/posts/2026-06-24-scaling-laws/
> 分类：AI Research / Scaling Laws

## 核心要点

- 缩放定律用幂律描述模型规模、数据量、计算量与损失之间的可预测关系，并支持从小规模实验外推大型训练配置。
- Kaplan 与 Chinchilla 的主要分歧来自训练设置与计算最优分配：前者倾向扩大模型，后者强调模型参数与训练 token 近似等比例增长。
- Chinchilla 的三种估计方法并非完全一致，参数拟合、计算口径和数值精度都会显著影响最终结论。
- 幂律现象可以从数据流形、量化误差和任务难度分布等角度解释，但目前仍缺少覆盖所有观察结果的统一理论。
- 在数据受限场景中，重复训练的边际价值会衰减，模型相对于唯一数据量过大时还会产生额外的过拟合惩罚。
- 更大的模型可能对数据重复更敏感，因此有限数据预算下不能只依赖增加训练周期或参数规模。
- 缩放定律拟合本质上是跨数量级外推，参数计数、损失聚合、舍入精度和拟合区间等细节都可能放大为明显预测偏差。
- 可靠使用缩放定律需要保持架构、优化器、数据混合和训练策略等条件一致，并对拟合结果进行复现与敏感性分析。

## 正文

缩放定律是深度学习中最关键的经验发现之一。其观察形式简单：随着模型大小 $N$、数据集大小 $D$ 和计算量 $C$ 的增加，训练损失 $L$ 可预测地下降，遵循幂律曲线，在对数-对数图上表现为一条直线。我们可以将缩放定律视为一个框架，用于描述计算、损失、模型大小和数据之间的关系；其核心在于如何在 $N$ 和 $D$ 之间优化分配宝贵的计算资源。

> Scaling laws are one of the most critical empirical findings in deep learning. The observation is simple in form: the training loss $L$ decreases predictably as we scale up model size $N$, dataset size $D$, and compute $C$, following a power-law curve, which appears as a straight line on a log-log plot. We can view scaling laws as a framework for describing the relationship between compute, loss, model size and data; at its core, it is about how to allocate precious compute optimally between $N$ and $D$.

这种可预测性使得缩放定律在实践中极具价值。常见的工作流程是在少量小型运行中拟合缩放定律，然后外推以估计更大模型的 token 和计算需求。

> This predictability makes scaling laws highly valuable in practice. A common workflow is to fit scaling laws on a handful of small runs and then extrapolate to estimate the token and compute requirements for larger models.

| 符号 | 说明 |
| --- | --- |
| $N$ | 模型大小，以参数量衡量。 |
| $D$ | 训练数据集大小，通常以 token 数量衡量。 |
| $C$ | 训练计算量，以 FLOPs 衡量。一个实用近似是 $C \approx 6ND$（Kaplan et al. 2020），其中 $2ND$ 对应前向传播，$4ND$ 对应反向传播。 |
| $E$ | 不可约损失 |
| $L, \hat{L}(.)$ | 测试损失／测试损失预测函数；由于训练损失与测试损失高度相关，也可指训练损失。 |
| $\epsilon$ | 泛化误差。 |

> 英文原表 / English original

| Symbol | Note |
| --- | --- |
| $N$ | Model size, measured in parameter count. |
| $D$ | Training dataset size, usually measured in token count. |
| $C$ | Training compute in FLOPs. As a useful approximation, $C \approx 6ND$ ( Kaplan et al. 2020 ), where $2ND$ accounts for the forward pass and $4ND$ for backpropagation. |
| $E$ | Irreducible loss |
| $L, \hat{L}(.)$ | Test loss / test loss prediction function; can also refer to training loss, since they are strongly correlated. |
| $\epsilon$ | Generalization error. |

### 早期：机器学习损失的可预测性

> Early days: ML loss predictability

在缩放定律成为主流概念之前，泛化误差随规模变化的可预测性就已经被研究过。

> The predictability of generalization error with scale had already been investigated before scaling laws became a mainstream concept.

[Amari 等人 (1992)](https://ieeexplore.ieee.org/document/6796972) 使用贝叶斯方法和退火近似推导了四种学习曲线。

> [Amari et al. (1992)](https://ieeexplore.ieee.org/document/6796972) derived four types of learning curves using a Bayesian approach and the annealed approximation.

1\. 确定性学习算法，无噪声数据，唯一解：$\epsilon \sim c \cdot D^{-1}$，其中 $c$ 是某个常数。

2\. 确定性学习算法，无噪声数据，多个等效解：$\epsilon \sim c \cdot D^{-2}$；每个新数据点都会加速学习，因为模型只学习参数的最优流形，而不是找到单一解点。

3\. 确定性学习算法，有噪声数据：$\epsilon \sim c \cdot D^{-1/2}$；数据中的噪声使学习变得更困难。

4\. 随机学习算法，有噪声数据：$\epsilon \sim c \cdot D^{-1} + E$；这里不可约损失 $E$ 是随机学习器无法进一步减少的残余误差，例如当模型在大量数据上耗尽容量时。所有四种学习曲线都遵循幂律：

英文原文：

1\. Deterministic learning algorithm, noiseless data, one unique solution: $\epsilon \sim c \cdot D^{-1}$, where $c$ is some constant.

2\. Deterministic learning algorithm, noiseless data, multiple equivalent solutions: $\epsilon \sim c \cdot D^{-2}$; the learning is faster with each new data point, because the model only learns the optimal manifold of parameters, instead of finding the single solution point.

3\. Deterministic learning algorithm, noisy data: $\epsilon \sim c \cdot D^{-1/2}$; noises in data make learning harder.

4\. Stochastic learning algorithm, noisy data: $\epsilon \sim c \cdot D^{-1} + E$; here the irreducible loss $E$ is the residual error that a stochastic learner cannot reduce further, for example when the model runs out of capacity on large data.
All four types of learning curves follow a power law:

$$
\epsilon \sim c \cdot D^\alpha + E
$$

其中 $E$ 可以为 0，$\alpha = -2, -1, -1/2$。尽管他们的理论设置基于简化的二元分类任务，但它为构建经验性机器学习损失预测模型指明了一个有用的方向。

> where $E$ can be 0 and $\alpha = -2, -1, -1/2$. Although their theoretical setup is based on a simplified binary classification task, it points in a useful direction for building empirical ML loss prediction models.

最早的经验研究之一由 [Hestness 等人 (2017)](https://arxiv.org/abs/1712.00409) 解释了泛化误差、模型大小和数据之间的关系。对于给定的训练数据大小，他们通过网格搜索确定了最适合的模型大小，然后绘制了损失与训练数据集大小的关系图。在深度学习的四个不同领域（神经机器翻译、图像分类、语言建模和语音识别）中，观察到一个重复出现的模式，即：

> One of the earliest empirical studies by [Hestness et al. (2017)](https://arxiv.org/abs/1712.00409) explained the relationship between generalization error, model size and data. For a given training data size, they identified the best-fit model size via grid search and then plotted loss against training dataset size. Across four different domains in deep learning (neural machine translation, image classification, language modeling, and speech recognition), a recurring pattern was observed where:

• 泛化误差随一系列因素（例如数据大小）呈幂律缩放。

• 模型改进会使误差曲线发生偏移，但似乎不影响幂律指数。

• 有趣的是，架构改变了幂律拟合的偏移量 ($E$)，但没有改变指数 ($\alpha$)。幂律的斜率似乎是问题领域的属性，而不是模型架构的属性。

• 拟合大小为 $D$ 的数据集所需的模型参数数量 $N$ 也呈幂律缩放。

英文原文：

• Generalization error scales as a power law across a set of factors (e.g. data size).

• Model improvements shift the error curve but do not seem to affect the power-law exponent.

• Interestingly, architecture changes the offset ($E$) of the power-law fit but does not change the exponent ($\alpha$). The slope of the power law appears to be a property of the problem domain rather than the model architecture.

• The number of model parameters $N$ needed to fit a dataset of size $D$ also scales as a power law.

![Learning curves for (Left) Deep-Speech-2 (DS2) and attention speech model and for (Right) DS2 models of various sizes. The losses of small models plateau when training data becomes large. (Image source: Hestness et al. 2017)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/hestness-1.png)

一个概念性图示将学习曲线分为三个阶段。在小数据区域，当学习信号不足时，模型的表现仅略优于随机猜测。在中间（“幂律区域”），我们观察到损失、数据和模型大小之间存在幂律关系。最终的不可约误差区域可归因于数据中的噪声等因素。

> A conceptual illustration breaks the learning curve into three stages. In the small-data region, when there are not enough learning signals, the model performs only slightly better than random guessing. In the middle (“power-law region”), we observe a power-law relationship between loss, data, and model size. The final irreducible-error region can be attributed to factors such as noise in the data.

![Illustration of power-law learning curve phases. (Image source: Hestness et al. 2017)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/hestness-2.png)

[Rosenfeld 等人 (2020)](https://arxiv.org/abs/1909.12673) 通过尝试将误差建模为模型大小 $N$ 和数据大小 $D$ 的联合函数，进一步推动了这项工作，涵盖了多种架构（ResNet、WRN、LSTM、Transformer）和优化器（Adam、SGD 变体）。他们凭经验观察到，当一个轴固定时，误差以幂律形式在另一个轴上衰减：

> [Rosenfeld et al. (2020)](https://arxiv.org/abs/1909.12673) pushed this further by trying to model error as a joint function of both model size $N$ and data size $D$, across a diverse set of architectures (ResNet, WRN, LSTM, Transformer) and optimizers (Adam, SGD variants). Empirically they observed that, holding one axis fixed, the error decays as a power law in the other:

$$
\hat{L}(D,N) \approx \frac{A}{N^{\alpha}} + E_N,\quad 
\hat{L}(D,N) \approx \frac{B}{D^{\beta}} + E_D
$$

可以组合成一个联合形式：

> which can be combined into a joint form:

$$
\hat{L}(D, N) \approx \frac{A}{N^{\alpha}} + \frac{B}{D^{\beta}} + E
$$

其中 $A > 0, B > 0, \alpha \geq 0, \beta \geq 0$ 是标量常数，$E$ 不依赖于 $N$ 或 $D$。

> where $A > 0, B > 0, \alpha \geq 0, \beta \geq 0$ are scalar constants and $E$ is not dependent on either $N$ or $D$.

![A 3D contour plot of data size, model size and generalization error in log-log-log scale. Blue dots are derived from empirical experiments and the surface is a linear interpolation between blue dots. (Image source: Rosenfeld et al. 2020)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/rosenfeld-1.png)

因此，他们可以构建一个预测模型，其形式为一个简单的参数函数，其中 $\boldsymbol{\theta} = \langle A, B, E, \alpha, \beta \rangle$，通过仅在小于特定阈值的较小训练配置集 $(D, N)$ 上进行训练，来预测大于特定阈值的 $(D, N)$ 的预期损失。

> Thus, they can build a prediction model in the form of a simple parametric function with $\boldsymbol{\theta} = \langle A, B, E, \alpha, \beta \rangle$ to predict the expected loss for $(D, N)$ > certain thresholds by only training on a set of smaller training configs, $(D, N)$ < certain thresholds.

![Fitting the parametric error model on small-scale configurations and extrapolating to larger model/data regimes: (a) Illustration of the experiment setup; Experiment results on (b) ImageNet, (c) WikiText-103 and (d) CIFAR100 Error estimation with three architectures (WRN, VGG, DenseNet) and two optimizers (SGD, Adam). (Image source: Rosenfeld et al. 2020)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/rosenfeld-2.png)

旁注：这些早期工作依赖于经典的学习理论直觉，例如 [VC 维](https://en.wikipedia.org/wiki/Vapnik%E2%80%93Chervonenkis_dimension)（模型可以打散的最大点集的基数）作为容量的代理，但在现代深度学习工作中，VC 维通常过于粗糙，无法解释其行为，并且经验幂律比理论提供的最坏情况界限更清晰、更实用。

> Side note: These early works lean on classical learning-theory intuition like the [VC dimension](https://en.wikipedia.org/wiki/Vapnik%E2%80%93Chervonenkis_dimension) (the cardinality of the largest set of points a model can shatter) as a proxy for capacity, but in modern deep learning work the VC dimension is often too coarse to explain the behavior and the empirical power laws turned out to be much cleaner and more practical than the worst-case bounds that theory provides.

### 数据无限区域中的缩放定律

> Scaling Laws in Data-Infinite Region

#### Kaplan 等人的缩放定律

> Kaplan et al.’s Scaling Laws

[Kaplan 等人 (2020)](https://arxiv.org/abs/2001.08361) 在语言建模社区中普及了缩放定律的概念。他们发现，交叉熵测试损失 $L$ 随着模型大小 $N$（不包括嵌入层）、数据集大小 $D$ 和训练计算量 $C$ 以幂律形式在多个数量级上缩放。这些发现与上一节的早期工作一致，但 Kaplan 等人通过专注于 Transformer 语言模型和更大规模的经验实验，将这一概念形式化，模型大小范围从 7.68 亿到 15 亿非嵌入参数，数据集大小从 2200 万到 230 亿 token。论文中所有的训练运行都使用了学习率调度，包括 3000 步线性预热，然后是余弦衰减到零。

> [Kaplan et al. (2020)](https://arxiv.org/abs/2001.08361) popularized the concept of scaling laws in the language modeling community. They found that the cross-entropy test loss $L$ scales as a power law with each of model size $N$ (excluding embedding layers), dataset size $D$, and training compute $C$ across many orders of magnitude. The findings are aligned with early work in the last section, but Kaplan et al. formalized the concept with a focus on Transformer language models and empirical experimentation at a larger scale, with model size ranging from 768M to 1.5B non-embedding parameters and dataset size from 22M to 23B tokens. All training runs in the paper used a learning rate schedule with a 3000 step linear warmup, followed by a cosine decay to zero.

主要发现列表：

> List of key findings:

• 损失 $L$ 随 $N$、$D$ 和 $C$ 单独以幂律形式缩放；为了获得最佳性能，这三者必须协同缩放。

• 训练曲线遵循可预测的幂律，其参数大致独立于模型大小。

• 更大的模型更具样本效率，这意味着它们以更少的优化步骤和更少的数据点达到给定的损失，而不是小型模型。

• 架构细节（宽度、长宽比等）的重要性低于纯粹的规模。

• 训练损失和测试损失呈正相关。（这听起来微不足道，但却是预训练工作的基础。另一方面，预训练损失的改善是否能转移到后训练评估需要单独研究。）

• 在给定固定计算预算的情况下，训练一个非常大的模型并在 *收敛之前* 停止，比训练一个较小的模型直到收敛更有效。**Chinchilla 缩放定律（下一节）与此发现存在分歧：Kaplan 等人高估了最佳模型大小，因为他们拟合的指数更大。**

英文原文：

• The loss $L$ scales as a power law with $N$, $D$, and $C$ individually; for optimal performance all three must scale in tandem.

• Training curves follow predictable power laws whose parameters are roughly independent of model size.

• Larger models are more sample-efficient, meaning that they reach a given loss with fewer optimization steps and fewer data points than small models.

• Architectural details (width, aspect ratio, etc.) matter less than sheer scale.

• Train loss and test loss are positively correlated. (Sounds trivial but this is the foundation for pretraining work. On the other hand, whether pretraining loss improvement transfers to posttraining evaluation needs separate studies.)

• Given a fixed compute budget, it is more efficient to train a very large model and stop *before convergence* than to train a smaller model all the way to convergence. **This finding is where the Chinchilla scaling laws (the next section) disagree: Kaplan et al. overestimated the optimal model size as their fitted exponent was larger.**

他们用一个方程总结了对 $N$ 和 $D$ 的联合依赖关系：

> They summarize the joint dependence on $N$ and $D$ in a single equation:

$$
\hat{L}(N,D) = \left[ \left(\frac{a}{N}\right)^{\frac{\alpha}{\beta}} + \frac{b}{D} \right]^{\beta}
$$

这种形式的一个很好的结果是，过拟合的程度（即模型复杂或数据量小）主要取决于比率 $N^{\alpha / \beta} / D$，这表明数据需要以与模型大小增长特定的比例增长，以避免训练受数据限制。

> A nice consequence of this form is that the extent of overfitting (i.e. model is complex or data is small) depends predominantly on the ratio $N^{\alpha / \beta} / D$, which indicates that the data needs to grow in a specific proportion to the growth of the model size to avoid training being data-limited.

![Test loss as a power law in compute, dataset size, and parameters, spanning many orders of magnitude. (Image source: Kaplan et al. 2020)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/kaplan-1.png)

最具影响力且事后看来争议最大的结论是计算最优分配。Kaplan 等人发现 $N_\text{opt} \propto C^{0.73}$，并得出结论认为模型大小应比数据集大小增长得更快。具体来说，对于计算量增加 10 倍的情况，他们建议将模型大小扩展约 5.5 倍，但训练 token 仅扩展约 1.8 倍。Chinchilla 论文后来推翻了这一建议，认为这使得大型模型严重*训练不足*。

> The most influential and, in hindsight, most contested conclusion was the compute-optimal allocation. Kaplan et al. found $N_\text{opt} \propto C^{0.73}$ and concluded that model size should grow faster than dataset size. Concretely, for a 10x increase in compute they suggested scaling the model size by ~5.5x but the training tokens by only ~1.8x. The Chinchilla paper would later overturn this recommendation, arguing that it leaves large models badly *undertrained*.

Kaplan 等人的另一项有用分析根据 $D$ 和 $N$ 近似了所需的训练 FLOPs 数量。每个乘加运算计为约 2 个 FLOPs。

> Another useful analysis in Kaplan et al. approximates the number of training FLOPs needed based on $D$ and $N$. Each multiply-add is counted as ~2 FLOPs.

![Parameter and compute estimation for different Transformer architectural components, given the number of layers $n_\text{layer}$, model width $d_\text{model}$ (= $d_\text{embed}$; the notation is inconsistent in the original table), dimension of feed-forward layer $d_\text{ff}$ (often equivalent to $4 d_\text{model}$, attention dimension $d_\text{attn}$ (often equivalent to $d_\text{model}$), the context length $n_\text{ctx}$ and the vocabulary size $n_\text{vocab}$. (Image source: Kaplan et al. 2020)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/kaplan-2.png)

假设标准配置为 $d_\text{attn} = d_\text{model} = d_\text{ff}/4$，并且从 $N$ 和每个 token 的前向计算中排除嵌入层：

> Given a standard config where $d_\text{attn} = d_\text{model} = d_\text{ff}/4$, and excluding embedding layers from $N$ and the per-token forward compute:

$$
\begin{align}
N &= n_\text{layer} d_\text{model} 3 d_\text{attn} + n_\text{layer} d_\text{attn} d_\text{model} + n_\text{layer} 2 d_\text{model} d_\text{ff} & \small{\text{; no embedding layer}} \\
&= 2\;n_\text{layer} d_\text{model}(2d_\text{attn} + d_\text{ff}) & \\
&= 12\;n_\text{layer} d_\text{model}^2 & \\
\\
C_\text{fwd} &= 2 n_\text{layer} (d_\text{model} 3 d_\text{attn} + n_\text{ctx}d_\text{attn} + d_\text{attn}d_\text{embed} + 2 d_\text{model} d_\text{ff}) & \\
&= 2 n_\text{layer} (12 d_\text{model}^2 + n_\text{ctx}d_\text{attn}) & \\
&= 2N + 2 n_\text{layer}n_\text{ctx}d_\text{attn} & \\
&\approx 2N \quad\quad \small{\text{; assuming }n_\text{ctx} < 12 d_\text{model} \text{ and the }n_\text{ctx}\text{ term is relatively small.}}\\
\end{align}
$$

然后我们将反向传播的 FLOPs 计为前向传播 FLOPs 的两倍，因为反向传播会运行两次矩阵乘法，分别用于计算输入激活和权重的梯度。因此，总的来说，每个 token 的训练 FLOPs 大约是 $6N$，而训练 $D$ 个 token 的总 FLOPs 为 $C \approx 6ND$。

> Then we count backward-pass FLOPs as twice the forward-pass FLOPs, because backpropagation runs two matrix multiplications, for gradients with respect to the input activations and the weights, respectively. Thus, in total, the training FLOPs per token are approximately $6N$, and the total FLOPs for training over $D$ tokens are $C \approx 6ND$.

#### Chinchilla 缩放定律

> Chinchilla Scaling Laws

Chinchilla 论文（[Hoffmann et al. 2022](https://arxiv.org/abs/2203.15556)）研究了在更仔细的实验设计下，最优模型大小 $N$（总参数，*包括*嵌入）与 token 数量 $D$ 之间在*固定*计算预算 $C$ 下的关系，并得出了与 Kaplan 等人略有不同的答案。

> The Chinchilla paper ([Hoffmann et al. 2022](https://arxiv.org/abs/2203.15556)) studied the relationship between the optimal model size $N$ (total parameters, *including* embeddings) and the number of tokens $D$ under a *fixed* compute budget $C$ with a more careful experimental design and arrived at a somewhat different answer from Kaplan et al..

![You should know how chinchilla looks 😊 (Image source: ChatGPT generated)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/animal.png)

核心问题是在给定约束 $\text{FLOPs}(N, D) = C \approx 6ND$ 的情况下，如何最佳地分配资源。换句话说，当我们只有有限的 FLOPs（给定数量的 GPU 在给定时间内运行）时，我们应该如何在更多数据 token 和更多模型参数之间进行选择？

> The central question is on the best strategy to allocate resources given a constraint $\text{FLOPs}(N, D) = C \approx 6ND$. In other words, when we have only limited FLOPs (a given number of GPUs running for a given period of time), how should we choose between more data tokens and more model parameters?

$$
N_\text{opt}(C), D_\text{opt}(C) = \operatorname*{arg\,min}_{\text{s.t. } \text{FLOPs}(N,D) = C} \hat{L}(N, D)
$$

Chinchilla 论文提出了三种精心设计的缩放定律拟合方法。

> The Chinchilla paper presented three neatly designed methods for scaling laws fitting.

经验实验扫描了 400 多个模型，模型大小从 70M 到超过 16B 参数，训练 token 从 5B 到 500B。实验假设每个训练 token 都是唯一的（无限数据状态）。所有运行都使用了在训练周期内衰减 10 倍的余弦学习率调度。遍历模型大小可以描绘出计算最优前沿。

> The empirical experiments scanned over 400 models, with sizes from 70M to over 16B parameters and training tokens from 5B to 500B. The experiments were under the assumption that every training token is unique (the infinite-data regime). All runs used a cosine learning-rate schedule decaying by 10x over the training horizon. Sweeping over model sizes traces out the compute-optimal frontier.

##### 方法 1：固定模型大小，改变 token 预算

> Method 1: Fix model sizes, vary the token budget

对于每个参数计数 $N$，使用不同的 token 预算进行多次训练，并记录每个 FLOP 预算 $C$ 下实现的最小损失。

> For each parameter count $N$, train several runs with different token budgets, and record the minimal loss achieved per FLOP budget $C$.

![Chinchilla Method 1: training loss curves over FLOP budgets for a sweep of model sizes. (Image source: Hoffmann et al. 2022)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/chinchilla-1.png)

##### 方法 2：等 FLOP 曲线

> Method 2: IsoFLOP profiles

固定计算预算 $C$，并绘制最终损失与参数计数 $N$ 的关系图。每条等 FLOP 曲线在对数空间中大致呈抛物线形，其最小值表示该计算预算下的最优模型大小。然后，在不同预算下重复此过程，会在图中描绘出一条幂律线。

> Fix a compute budget $C$ and plot the final loss against parameter count $N$. Each iso-FLOP curve is roughly a parabola in log-space, and its minimum flags the optimal model size for that compute budget. Then repeating across budgets traces a power-law line in the plot.

![Chinchilla Method 2: IsoFLOP parabolas; the minimum of each curve is the compute-optimal model size for that budget. (Image source: Hoffmann et al. 2022)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/chinchilla-2.png)

##### 方法 3：参数拟合

> Method 3: Parametric fit

直接拟合与[Rosenfeld et al. (2020)](https://arxiv.org/abs/1909.12673)中相同的参数函数，

> Fit the same parametric function as in [Rosenfeld et al. (2020)](https://arxiv.org/abs/1909.12673) directly,

$$
\hat{L}(N, D) = \frac{A}{N^\alpha} + \frac{B}{D^\beta} + E
$$

我们实际上可以通过在约束条件 $\text{FLOPs}(N,D) = C \approx 6ND$ 下最小化 $\hat{L}(N, D)$ 来获得最优 $N_\text{opt}(C), D_\text{opt}(C)$ 的闭式近似。

> We can actually get a closed form approximation of optimal $N_\text{opt}(C), D_\text{opt}(C)$ by minimizing $\hat{L}(N, D)$ under the constraint $\text{FLOPs}(N,D) = C \approx 6ND$.

首先，我们将表达式简化为只包含 $N$：

> First let’s reduce the expression to contain only $N$:

$$
\begin{align}
\hat{L}(N) &= A N^{-\alpha} + B \Big(\frac{C}{6}\Big)^{-\beta}N^\beta + E \\
\hat{L}'(N) &= -\alpha A N^{-\alpha-1} + \beta B \Big(\frac{C}{6}\Big)^{-\beta} N^{\beta -1} = 0 & \small{\text{; derivative wrt }N\text{ should be zero.}} \\
\text{Thus}\quad & \alpha A N^{-\alpha-1} = \beta B \Big(\frac{C}{6}\Big)^{-\beta} N^{\beta -1} \\
& \alpha A = \beta B \Big(\frac{C}{6}\Big)^{-\beta} N^{\alpha + \beta} \\
& N_\text{opt} = \Big(\frac{\alpha A}{\beta B}\Big)^{\frac{1}{\alpha + \beta}} \Big(\frac{C}{6}\Big)^{\frac{\beta}{\alpha+\beta}} \\
& D_\text{opt} = \frac{C}{6 N_\text{opt}} = \Big(\frac{\beta B}{\alpha A}\Big)^{\frac{1}{\alpha + \beta}} \Big(\frac{C}{6}\Big)^{\frac{\alpha}{\alpha+\beta}}
\end{align}
$$

当 $\alpha \approx \beta$ 时，模型大小和训练 token 应该以相同的速率扩展。

> When $\alpha \approx \beta$, model size and training tokens should scale at equal rates.

为了找到最优的 $\boldsymbol{\theta} = \langle A, B, E, \alpha, \beta\rangle$，Chinchilla 论文采用了 [Huber 损失](https://en.wikipedia.org/wiki/Huber_loss)（对异常值具有鲁棒性；$\delta=10^{-3}$）和 [L-BFGS 算法](https://en.wikipedia.org/wiki/Limited-memory_BFGS)（适用于少量参数的曲线拟合）。

> To find the optimal $\boldsymbol{\theta} = \langle A, B, E, \alpha, \beta\rangle$, the Chinchilla paper adopts a [Huber loss](https://en.wikipedia.org/wiki/Huber_loss) (robust to outliers; $\delta=10^{-3}$) and the [L-BFGS algorithm](https://en.wikipedia.org/wiki/Limited-memory_BFGS) (good for curve fitting with a small number of parameters).

$$
\begin{align}
\min_{A,B,E,\alpha,\beta} \sum_{\text{runs }\{i\}} \text{Huber}_\delta (\log \hat{L}(N_i, D_i) - \log L_i) \\
\text{ where }\text{Huber}_\delta (x) = \begin{cases}\frac{1}{2} x^2 & \text{for }\vert x \vert \leq \delta \\ \delta \cdot (\vert x \vert - \frac{1}{2}\delta), & \text{otherwise.}\end{cases}
\end{align}
$$

Chinchilla 通过三种互补的方法得出其结论，这些方法的最终结果相互吻合，这也是该结果颇具说服力的原因之一。

> Chinchilla arrives at its answer through three complementary methods whose final results agree with each other, and this is part of why the result was quite convincing.

![The three methods agree on a compute-optimal frontier where $N_\text{opt} \propto C^{0.5}$, but disagree with Kaplan et al. Note that method 3's results are slightly off from the other two, which we will explain later. (Image source: Hoffmann et al. 2022)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/chinchilla-3.png)

![The plot of the Chinchilla predictions by three different approaches, as well as predictions by Kaplan et al. (2020). All three methods suggest that several mainstream LLMs at the time were undertrained. (Image source: Hoffmann et al. 2022)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/chinchilla-4.png)

Chinchilla 论文中声称大多数大型模型（当时，约 2022 年）训练不足的说法得到了一个著名例证的支持：在与 Gopher 相同的计算预算下（[Rae et al. 2021](https://arxiv.org/abs/2112.11446)；280B 参数量，300B token 预算），他们训练了 Chinchilla（70B 参数量，1.4T token 预算），一个模型小 4 倍但训练数据量大约多 4 倍，并且它在所有方面都超越了 Gopher。

> The claim in the Chinchilla paper that most large models (at the time, ~2022) were undertrained is supported by a famous demonstration: under the same compute budget as Gopher ([Rae et al. 2021](https://arxiv.org/abs/2112.11446); 280B parameter count, 300B token budget), they trained Chinchilla (70B parameter count, 1.4T token budget), a model 4x smaller but trained on roughly 4x more tokens and it outperformed Gopher across the board.

#### 调和 Kaplan 和 Chinchilla

> Reconciling Kaplan and Chinchilla

Chinchilla 缩放定律与 Kaplan 等人的观点分歧如下：

> The Chinchilla scaling laws disagree with Kaplan et al. as follows:

• 与“模型增长速度快于数据增长速度”（$N_\text{opt} \propto C^{0.73}$）不同，对于模型大小的每一次翻倍，训练 token 的数量也应该翻倍（$N_\text{opt} \propto C^{0.5}$）。

• 与其“训练一个大模型并在收敛前停止”，不如用更多数据训练一个更小的模型。

英文原文：

• Instead of “grow the model faster than the data” ($N_\text{opt} \propto C^{0.73}$), for every doubling of model size, you should also double the number of training tokens ($N_\text{opt} \propto C^{0.5}$).

• Instead of “train a big model and stop before convergence,” you should train a smaller model on more data.

两篇论文在相同的基本原则上仍然一致，但在最优的模型大小与 token 权衡点上存在分歧。为什么它们分歧如此之大？

> Both papers still agree on the same underlying principle, but they disagree on where the optimal size-vs-token tradeoff lies. Why do they disagree so much?

**差异 1：Kaplan 等人主要在小型模型上进行实验。**
Kaplan 等人主要在较小的模型上进行实验，而 Chinchilla 论文的实验规模则扩大了 10 倍以上。当我们在对数-对数空间中进行外推时，拟合中的微小差异可能导致巨大的差异（参见[玩具模拟](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/#toy-simulation)）。

> **Difference 1: Kaplan et al. experimented mostly on small models.**
> Kaplan et al. experimented mostly on smaller models, while the Chinchilla paper’s experiments reached more than 10x larger scales. When we extrapolate in log-log space, a small difference in the fit can result in large differences (See [toy simulation](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/#toy-simulation)).

**差异 2：嵌入参数数量对小型模型很重要。**
在小参数量范围内，嵌入参数占总参数的比例不可忽略，因此是否计算它们很重要。[Pearce & Song (2024)](https://arxiv.org/abs/2406.12907) 对此进行了深入分析。我们使用 $N_{\setminus E}, C_{\setminus E}$ 来表示排除嵌入时的模型大小和计算量，并使用 $N, C$ 来计算总参数。

英文原文：Difference 2: Embedding parameter count matters for small models.
In the small-parameter regime, embedding parameters are a non-negligible fraction of the total and thus counting them or not matters. [Pearce & Song (2024)](https://arxiv.org/abs/2406.12907) did a thorough analysis along this line. Let’s use 

$N_{\setminus E}, C_{\setminus E}$ to denote model size and compute when embedding is excluded and use 

$N, C$ to count total parameters.

• Kaplan 等人：$N^{\ast}_{\setminus E} \propto C^{0.73}_{\setminus E}$（非嵌入）

• Chinchilla：$N^{\ast} \propto C^{0.50}$（总计）

英文原文：

• Kaplan et al.: $N^{\ast}_{\setminus E} \propto C^{0.73}_{\setminus E}$ (non-embedding)

• Chinchilla: $N^{\ast} \propto C^{0.50}$ (total)

为了弥合两者之间的差异，他们拟合了总参数 $N_T$ 和非嵌入参数 $N_{\setminus E}$ 之间的关系，其中 $\omega$ 为某个常数：

> To bridge them, they fit a relationship between total parameters $N_T$ and non-embedding parameters $N_{\setminus E}$, for some constant $\omega$:

$$
N = N_{\setminus E} + \omega\, N_{\setminus E}^{1/3}.
$$

这种形式具有严格递增的良好特性，并且 $\lim_{N \to \infty} N = N_{\setminus E}$ (因为 $\frac{N}{N_{\setminus E}} = 1 + \omega {N_{\setminus E}}^{- \frac{2}{3}}, \lim_{N_{\setminus E} \to \infty} \frac{N}{N_{\setminus E}} = 1$。

> This form has nice properties of being strictly increasing and $\lim_{N \to \infty} N = N_{\setminus E}$ (because $\frac{N}{N_{\setminus E}} = 1 + \omega {N_{\setminus E}}^{- \frac{2}{3}}, \lim_{N_{\setminus E} \to \infty} \frac{N}{N_{\setminus E}} = 1$.

将其代入Chinchilla定律方程，

> Plugging this into the Chinchilla laws equation,

$$
\begin{align}
L(N_{\setminus E}, C_{\setminus E}) &= A(N_{\setminus E} + \omega\, N_{\setminus E}^{1/3})^{-\alpha} + B \Big(\frac{C_{\setminus E}}{6}\Big)^{-\beta} N_{\setminus E}^\beta + E \\
L'(N_{\setminus E}, C_{\setminus E}) &= - \alpha A (N_{\setminus E} + \omega N_{\setminus E}^{1/3})^{-\alpha -1}(1 + \frac{\omega}{3}N_{\setminus E}^{-2/3}) + \beta B \Big(\frac{C_{\setminus E}}{6}\Big)^{-\beta} N_{\setminus E}^{\beta -1} = 0 & \small{\text{; derivative wrt }N_{\setminus E}\text{ should be zero.}} \\
\text{Rearrange to get }& \alpha A (N^{*}_{\setminus E} + \omega {N^{*}_{\setminus E}}^{1/3})^{-\alpha -1}(1 + \frac{\omega}{3} {N^{*}_{\setminus E}}^{-2/3}) = \beta B \Big(\frac{C_{\setminus E}}{6}\Big)^{-\beta} {N^{*}_{\setminus E}}^{\beta -1} \\
& 6^{-\beta}\frac{\alpha A}{\beta B} ({N^{*}_{\setminus E}} + \omega {N^{*}_{\setminus E}}^{1/3})^{-\alpha -1}(1 + \frac{\omega}{3}{N^{*}_{\setminus E}}^{-2/3}) {N^{*}_{\setminus E}}^{1 - \beta} = C_{\setminus E}^{-\beta} \\
& 6 \Big(\frac{\beta B}{\alpha A}\Big)^{\frac{1}{\beta}} ({N^{*}_{\setminus E}} + \omega {N^{*}_{\setminus E}}^{1/3})^{\frac{1 + \alpha}{\beta}} ({N^{*}_{\setminus E}} + \frac{\omega}{3}{N^{*}_{\setminus E}}^{1/3})^{-\frac{1}{\beta}} {N^{*}_{\setminus E}} = C_{\setminus E} \\
\end{align}
$$

上述方程中 $C_{\setminus E}$ 和 $N_{\setminus E}$ 之间的关系不再是纯粹的幂律。我们只能将其局部近似为 $N^{\ast}_{\setminus E} \overset{\propto}{\sim} C_{\setminus E}^g$，其中 $g$ 是基于一阶导数 ($\overset{\propto}{\sim}$) 的局部指数，而不是全局幂律指数，因此 $g = \frac{\mathrm{d} \log C_{\setminus E}}{\mathrm{d} \log N_{\setminus E}}$。有关指数 $g$ 如何近似的完整详细信息，请参见附录 A.1，载于[Pearce & Song (2024)](https://arxiv.org/abs/2406.12907)。

> The relationship between $C_{\setminus E}$ and $N_{\setminus E}$ in the above equation is no longer a clean power law. We can only approximate it locally as $N^{\ast}_{\setminus E} \overset{\propto}{\sim} C_{\setminus E}^g$, where $g$ is a local exponent based on a first-order derivative ($\overset{\propto}{\sim}$) rather than a global power-law exponent, resulting in $g = \frac{\mathrm{d} \log C_{\setminus E}}{\mathrm{d} \log N_{\setminus E}}$. See the full details of how the exponent $g$ is approximated in Appendix A.1 in [Pearce & Song (2024)](https://arxiv.org/abs/2406.12907).

![Visualization of how the local power-law exponent $g$ grows with $C_{\setminus E}$. (Image source: Pearce & Song 2024)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/pearce-1.png)

如上图所示，随着 $C_{\setminus E}$ 变大，$g$ 收敛到 Chinchilla 估计值。通过使用上述方程生成合成训练曲线，在模型大小从 768M 到 1.5B 的范围内（如 Kaplan 等人所述），他们估计在该区域 $g$ 接近 Kaplan 系数 0.73。

> As shown in the visualization above, as $C_{\setminus E}$ gets larger, $g$ converges to the Chinchilla estimate. By generating synthetic training curves using above equation, in the range of model size from 768M to 1.5B (as in Kaplan et al.), they estimated that $g$ is close to the Kaplan coefficient of 0.73 in that region.

#### 为什么是幂律？

> Why power law?

幂律在人工智能之外的许多领域中被广泛观察到，例如在[齐夫定律](https://en.wikipedia.org/wiki/Zipf%27s_law)、[无标度网络](https://en.wikipedia.org/wiki/Scale-free_network)、[城市标度律](https://en.wikipedia.org/wiki/Urban_scaling)以及许多其他复杂系统中。重复出现的模式是，大事件很少见，小事件很常见，并且大小与频率之间的关系在对数-对数尺度上通常遵循一条直线。

> Power laws are widely observed across many domains outside AI, such as in [Zipf’s law](https://en.wikipedia.org/wiki/Zipf%27s_law), [scale-free networks](https://en.wikipedia.org/wiki/Scale-free_network), [urban scaling laws](https://en.wikipedia.org/wiki/Urban_scaling), and many other complex systems. The recurring pattern is that large events are rare, small events are common and the relationship between size and frequency often follows a straight line at log-log scale.

**为什么LLM标度律也呈现幂律形式？**

> **Why do LLM scaling laws also have the shape of a power law?**

部分受到不同领域显示不同指数的启发（[Hestness 等人 2017](https://arxiv.org/abs/1712.00409)），[Sharma & Kaplan (2020)](https://arxiv.org/abs/2004.10802)提出了一种早期解释，假设语言建模可以被视为在数据的低维流形上进行回归。更多的模型参数可以导致数据流形更精细的划分，从而产生更小的泛化误差。最简单地说，如果一个有效大小为 $N$ 的模型将一个 $d$ 维流形划分为 $O(N)$ 个区域，则典型的线性分辨率按 $\sim N^{-1/d}$ 缩放。这与上述标度律具有相似的幂律形式。该理论在无限数据、欠拟合状态下应用最清晰，但实际上估计数据流形的内在维度相当困难。

> Inspired partly by different domains displaying different exponents ([Hestness et al. 2017](https://arxiv.org/abs/1712.00409)), one early explanation by [Sharma & Kaplan (2020)](https://arxiv.org/abs/2004.10802) hypothesizes that language modeling can be viewed as doing regression on a low-dimensional manifold of data. More model parameters can induce a finer partition of the data manifold and therefore smaller generalization error. In the simplest terms, if a model of effective size $N$ partitions a $d$ -dimensional manifold into $O(N)$ regions, the typical linear resolution scales like $\sim N^{-1/d}$. This has a similar power-law form to the scaling laws above. This theory applies most cleanly in the infinite-data, underfitting regime, but in reality estimating the intrinsic dimension of a data manifold is quite hard.

后来的一个假设（[Michaud 等人 2023](https://arxiv.org/abs/2303.13506)、[Brill 2024](https://arxiv.org/abs/2412.07942)）假设知识或技能以离散块（“量化”）的形式学习，并且这些技能的频率分布遵循幂律。模型首先学习常见技能，然后学习稀有技能，从而导致损失平滑地呈幂律衰减。

> A later hypothesis ([Michaud et al. 2023](https://arxiv.org/abs/2303.13506), [Brill 2024](https://arxiv.org/abs/2412.07942)) assumes that knowledge or skills are learned in discrete chunks (“quantized”) and that the frequency distribution of these skills follows a power law. The model learns common skills first and rare skills later, resulting in a smooth power-law decay in loss.

我这里只列出了两个假设，但还有更多研究通过数据谱尾、核特征值、自然语言统计或训练动态中的相变来解释幂律标度的形状。

> I only listed two hypotheses here, but there are more studies on explaining the shape of power-law scaling through spectral tails of data, kernel eigenvalues, natural-language statistics, or phase transitions in training dynamics.

### 数据受限区域的标度律

> Scaling Laws in Data-Limited Region

经典标度律假设有效数据*无限且唯一*，没有重复，也没有多轮训练。随着模型规模显著增长，我们正在耗尽足够的高质量唯一token。事实上，关于人工智能中扩展可以持续多久的一些争论都集中在我们是否正在触及“数据墙”上。

> Classic scaling laws assume effectively *unlimited unique data*, no repetition, and no multi-epoch training. As the model size grows significantly, we are running out of enough high-quality unique tokens. In fact, some arguments about how long scaling in AI can continue are centered on whether we are hitting a “data wall”.

还值得强调的是，$D$ 背后的数据集预计已经过清洗。预训练数据管道通常是有效预训练管道的重要组成部分，其常见步骤包括去重（精确和模糊）、质量过滤、样板文本移除、安全过滤、PII/版权掩码、基准去污染以及根据语言、质量、内容类型等对数据混合组件进行仔细重新加权。即使两个数据集包含相同的token数量 $D$，高质量数据集和互联网垃圾数据集也能产生截然不同的计算效率。

> It is also worth emphasizing that the dataset behind $D$ is expected to be already cleaned. The pretraining data pipeline is often a large part of an effective pretraining pipeline, with common steps like deduplication (exact and fuzzy), quality filtering, boilerplate removal, safety filtering, PII/copyright masking, benchmark decontamination and careful reweighting of data mix components based on language, quality, content type, etc. Even when two datasets contain the same token count $D$, a high-quality dataset and a dataset of Internet slop can yield drastically different compute efficiency.

由[Hernandez 等人 (2022)](https://arxiv.org/abs/2205.10487)进行的研究侧重于一个受控版本：一个大部分唯一但包含少量重复数据的数据集。从一个大型数据集开始，数据混合保持 90% 不重复，但将剩余 10% 替换为原始数据的一小部分的重复。通过训练一个 Transformer 模型处理 100B token，他们观察到了一种双下降现象，即测试损失实际上会*变差*，然后再次变好，这取决于重复数据被强调的程度，这种效应随着重复比例的增加而变得更加明显。

> The study by [Hernandez et al. (2022)](https://arxiv.org/abs/2205.10487) focused on a controlled version: a mostly-unique dataset with a small fraction of repeated data. Starting from a large dataset, the data mix keeps 90% non-repeated but replaces the remaining 10% with repeats of a tiny portion of the original. By training a Transformer model for 100B tokens, they observed a double-descent phenomenon, that is, the test loss can actually get *worse* and then better again as a function of how much the repeated data is emphasized, an effect that becomes more pronounced as the repeated fraction grows.

![Double-descent in the test loss as the repeated fraction increases (90% repeated on the left, 50% on the right). (Image source: Hernandez et al. 2022)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/hernandez-1.png)

训练中期平坦或上升的趋势可能是由于重复数据的记忆。具有这种形状的学习曲线会使标度律拟合的准确性降低。他们还得出结论，重复数据会损害一些 OOD 评估和下游微调。然而，他们的数据混合是在更像实验室的环境中构建的，而现实世界数据中的重复通常更为细致（例如，不同数据具有不同程度的重复、语义重复等）。

> The flat or increasing trend in the middle of training is possibly due to memorization of repeated data. Learning curves with such shapes make scaling law fitting less accurate. They also concluded repeated data hurts some OOD evaluation and downstream fine-tuning. However, their data mix is constructed in a more lab-like setup, and repetition in real-world data is often more nuanced (e.g. different data has different levels of repetition, semantic repetition, etc.).

与其说数据重复损害训练，我们更感兴趣的是，鉴于唯一的高质量数据并非无限，并且我们可能不得不在训练期间重复数据，如何拟合标度律。

> Rather than saying data repetition hurts training, we are more interested in how to fit scaling laws, given that the unique high-quality data is not infinite and we likely have to repeat data during training.

[Muennighoff 等人 (2023)](https://arxiv.org/abs/2305.16264) 着手研究了当模型训练受数据限制时，计算资源应如何优化分配的问题。具体来说，他们通过大约400项实验，涵盖10M至9B参数、高达900B token的数据量以及多达1500个训练周期，实证研究了数据重复的影响。每个训练周期都会重复使用完全相同的数据集，在周期之间进行混洗，并在一个保留的测试集上进行评估。

> [Muennighoff et al. (2023)](https://arxiv.org/abs/2305.16264) took on the research question of how compute should be allocated optimally when model training is data-constrained. Specifically, they empirically studied the impact of data repetition across roughly 400 experiments, 10M–9B parameters, data sizes up to 900B tokens, and up to 1500 epochs. The exact same dataset is repeated each epoch, shuffled between epochs, and evaluated on a held-out test set.

关键的模型调整是将总token数 $D$ 分解为两部分：(i) 唯一token数 $U_D$ 和 (ii) 重复次数 $R_D$ (即 训练周期数 - 1)。因此，我们有 $D = U_D(1 + R_D)$。在给定唯一数据预算 $D_\text{uniq}$ 的情况下，根据定义 $U_D = \min \{{ D_\text{uniq}, D\}}$ 且 $R_D = (D / U_D) - 1$。他们使用 Chinchilla 缩放定律来找到拟合 $U_D$ 的最佳模型大小 $U_N$，并通过重复次数 $R_N = (N / U_N) - 1$ 定义了过剩模型大小。

> The key modeling adjustment is to decompose the total token count $D$ into two parts: (i) the number of unique tokens $U_D$ and (ii) the number of repeats $R_D$ (i.e. num. epochs - 1). Thus we have $D = U_D(1 + R_D)$. With a unique-data budget $D_\text{uniq}$, by definition $U_D = \min \{{ D_\text{uniq}, D\}}$ and $R_D = (D / U_D) - 1$. They use the Chinchilla scaling laws to find the optimal model size $U_N$ for fitting $U_D$, and define excess model size via repeats $R_N = (N / U_N) - 1$.

他们随后更新了 Chinchilla 参数拟合（[方法 3](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/#chinchilla-method3)），以使用有效（折扣）数据 $D’$ 和模型大小 $N’$ 来代替原始数量：

> They then update the Chinchilla parametric fit ([method 3](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/#chinchilla-method3)) to use effective (discounted) data $D’$ and model size $N’$ in place of the raw quantities:

$$
\hat{L}(N, D) = \frac{A}{N'^\alpha} + \frac{B}{D'^\beta} + E
\quad\text{ where }
D' = U_D + U_D\, r_D\left(1 - \exp\!\left(-\frac{R_D}{r_D}\right)\right).
$$

直观地说，token 的价值会随着重复而*指数级*衰减。在他们的建模中，每次重复都会使 token 损失其剩余价值的 $(1 - 1/r_D)$ 部分，其中 $r_D$ 是一个可学习的“半衰期”参数。当 $R_D = 0$ 或 $R_D \ll r_D$ 时，我们恢复 $D’ \approx D$。

> The intuition is that a token’s value decays *exponentially* as it is repeated. In their modeling, each repetition costs the token a $(1 - 1/r_D)$ fraction of its remaining value, where $r_D$ is a learnable “half-life” parameter. When $R_D = 0$ or $R_D \ll r_D$, we recover $D’ \approx D$.

一个对称的公式处理了过剩模型大小，$N’ = U_N + U_N r_N(1 - \exp(-R_N / r_N))$，它捕捉了“更大的模型在重复数据上过拟合更快”以及“模型可能对其数据集来说过大”的观点。这个组成部分不太直观，我未能找到一个令人满意的解释，说明为什么模型大小需要以与重复数据如此对称的形式出现。后来 [Lovelace 等人 (2026)](https://arxiv.org/abs/2605.01640) 的工作改变了这一假设。

> A symmetric formulation handles excess model size, $N’ = U_N + U_N r_N(1 - \exp(-R_N / r_N))$, capturing the idea that “larger models overfit more quickly on repeated data” and that “a model can be too large for its dataset.” This component is less intuitive, and I could not find a satisfactory explanation for why model size needs to appear in such a symmetric form as repeated data. Later work by [Lovelace et al. (2026)](https://arxiv.org/abs/2605.01640) changed this assumption.

他们的经验拟合发现，*过剩参数的价值衰减速度快于重复数据*，$r_N < r_D$，因此我们应该将更多资源分配给更多的训练周期，而不是更多的模型参数。这种建模的一个弱点，正如作者也指出的那样，是它显著低估了失败模型（即训练中途损失增加的模型）的最终测试损失，例如训练了44个周期的模型。

> Their empirical fit finds that *excess parameters decay faster in value than repeated data*, $r_N < r_D$, so we should allocate more resources on more epochs rather than more model parameters. One weakness of this modeling, as the authors also pointed out, is that it significantly underestimates the final test loss of failing models (i.e. models whose loss increases midway through training), such as models trained for 44 epochs.

![Data-constrained scaling under repetition captures the experimental results better than data-unaware fitting; the value of repeated tokens decays exponentially toward a ceiling. The fitting gets worse with more epochs as high repetition causes the test loss to increase midway through training, not depicted in the plot. (Image source: Muennighoff et al. 2023)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/muennighoff-1.png)

最近，[Lovelace 等人 (2026)](https://arxiv.org/abs/2605.01640) 以不同的方法重新审视了相同的问题。Lovelace 等人没有将过参数化建模为有效模型大小的收益递减，而是明确地建模了模型大小 $\times$ 数据重复之间的相互作用。根据经验，他们训练了大约300个模型，涵盖15M到1B参数以及50M到6B唯一token。

> Most recently, [Lovelace et al. (2026)](https://arxiv.org/abs/2605.01640) revisited the same problem with a different approach. Rather than modeling overparameterization as a diminishing return on effective model size, Lovelace et al. model the interaction between model size $\times$ data repetition explicitly. Empirically, they trained about 300 models, spanning 15M to 1B parameters and 50M to 6B unique tokens.

当他们绘制固定模型大小在不同数据重复水平下的拟合残差时，观察结果是直观的：更多的训练周期会导致更大的损害，有趣的是，*更大的模型更敏感*于重复。这暗示损失惩罚可能是模型大小和数据大小的函数。

> When they plot the fit residual for a fixed model size across a range of data-repetition levels, the observation is intuitive: more epochs cause more damage, and interestingly *larger models are more sensitive* to repetition. This hints that the loss penalty is likely a function of both model size and data size.

![Residuals of the effective-size fit reveal that overfitting damage grows with both the number of epochs and the model size. (Image source: Lovelace et al. 2026)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/lovelace-1.png)

引入了一个显式的过拟合惩罚项，并围绕*容量比* $N / U_D$（参数数量相对于唯一token数）构建：

> An explicit overfitting penalty term was introduced and built around the *capacity ratio* $N / U_D$ (parameter count relative to unique tokens):

$$
\hat{L}(N, U_D, R_D) = E + \frac{A}{N^\alpha} + \frac{B}{\big(U_D (1 + R_D)\big)^\beta} + \color{red}{P \cdot R_D^\delta \cdot \left(\frac{N}{U_D}\right)^\kappa}
$$

其中：

> where:

• $R_D$ 是重复次数；

• 标量 $P$ 是一个可学习参数；

• 指数 $\kappa$（第二个可学习参数）使惩罚项与容量比 $N / U_D$ 非线性地缩放；

• 重复次数上的独立指数 $\delta$（第三个可学习参数）将重复的非线性与 $\kappa$ 解耦。

英文原文：

• $R_D$ is the repetition count;

• the scalar $P$ is a learnable parameter;

• the exponent $\kappa$ (the 2nd learnable parameter) lets the penalty scale nonlinearly with the capacity ratio $N / U_D$;

• the separate exponent $\delta$ (the 3rd learnable parameter) on the repetition count decouples repetition nonlinearity from $\kappa$.

添加的项（红色部分）是一个直接的过拟合惩罚，它随着数据重复的次数以及模型相对于可用唯一数据的过参数化程度而增长。

> The added term (in red) is a direct overfitting penalty that grows with both how many times you repeat the data and how over-parameterized the model is relative to the unique data available.

他们还进行了一项案例研究，探讨了权重衰减如何影响有限数据约束下的训练，并发现强权重衰减可以减少数据重复引起的过拟合惩罚。

> They also did a case study on how weight decay impacts training with the limited-data constraint and found that strong weight decay reduces the overfitting penalty caused by data repetition.

![Strong weight decay reduces the overfitting penalty from data repetition. (Image source: Lovelace et al. 2026)](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/lovelace-2.png)

Muennighoff 等人和 Lovelace 等人的两种建模方法都是基于经验曲线拟合构建的，因此目前尚不清楚为什么数据约束的缩放定律应该具有这些精确形式，以及为什么每个自由参数都是必需的。对这方面的更多理论工作感到好奇。

> Both modeling approaches by Muennighoff et al. and Lovelace et al. are constructed from empirical curve fitting, so it is still unclear why data-constrained scaling laws should have exactly these forms and why each free parameter is needed. Curious about more theoretical work along this line.

### 现实中拟合缩放定律的复杂性

> Trickiness of Fitting Scaling Laws in Reality

尽管缩放定律形式简洁，但在实践中，其拟合过程对看似微不足道的程序选择却异常敏感，例如如何计算参数、如何舍入精度、如何求和或平均损失等。

> Despite its clean form, in practice, scaling law fitting can be surprisingly sensitive to seemingly trivial procedural choices, like how you count parameters, how you round the precision, how you sum or average the loss, etc.

因为缩放定律仅适用于我们能够负担得起训练的（相对较小、相对便宜的）模型，而预测是*外推*到规模大几个数量级的模型。在这种设置下，看似舍入误差的选择可能会导致预测结果的巨大差异。

> Because a scaling law is only fit on the (relatively small, relatively cheap) models that we can afford to train, and the prediction is *extrapolated* for a model orders of magnitude larger. In such a setup, choices that look like rounding error may lead to wild differences in prediction.

同时，缩放定律拟合假设唯一变化的因素是*规模*，这意味着模型架构、优化器、学习率调度、批次增长、数据混合、分词器和其他设计选择应保持不变。另一个潜在假设是所有这些设置都应经过仔细调整，因为像训练不足的模型这样的情况可能会导致不同的结论。

> Meanwhile, scaling-law fitting assumes the only changing factor is *scale*, which means that the model architecture, optimizer, learning rate schedule, batch ramp, data mix, tokenizer, and other design choices should remain the same. Another underlying assumption is that all these settings should have been carefully tuned, as cases like undertrained models can lead to a different conclusion.

Kaplan 等人和 Chinchilla 的结果之间的分歧是展示缩放定律拟合复杂性的一个例子。

> The disagreement between results by Kaplan et al. and Chinchilla is one example to showcase the trickiness of scaling laws fitting.

第二个例子是一项后续分析，旨在调查为什么 Chinchilla 的[方法 3](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/#method-3-parametric-fit)与另外两种方法略有偏差。[Besiroglu 等人 (2024)](https://arxiv.org/abs/2404.10102)从 Hoffmann 等人 (2022) 的图 4 中提取了原始的 $(N, D, L)$ 数据点，并重新运行了方法 3 的参数拟合。他们发现了一些具体问题：

> A second example is a follow-up analysis investigating why Chinchilla [method 3](https://lilianweng.github.io/posts/2026-06-24-scaling-laws/#method-3-parametric-fit) is slightly off from the other two methods. [Besiroglu et al. (2024)](https://arxiv.org/abs/2404.10102) extracted the raw $(N, D, L)$ data points from Figure 4 of Hoffmann et al. (2022) and re-ran the method 3 parametric fitting. They found a couple of concrete issues:

• L-BFGS-B 最小化器中损失尺度过高，这是由于对 Huber 损失值进行示例平均而非求和导致的，从而导致优化过早终止。在原始拟合和自举过程中，损失最小化的提前停止产生了不一致的估计和不可信的狭窄置信区间。

• 报告的 $\alpha$ 和 $\beta$ 被四舍五入到小数点后两位，这使得推导出的 $A, B$ 看起来比实际偏差更大。

英文原文：

• A high loss scale in the L-BFGS-B minimizer, caused by averaging Huber-loss values over examples instead of summing them, which led to premature termination of the optimization. The early stopping of loss minimization during both the original fit and bootstrapping produced inconsistent estimates and implausibly narrow confidence intervals.

• The reported $\alpha$ and $\beta$ were rounded to 2 digits of precision, which made the derived $A, B$ look more off than they really were.

#### 玩具模拟

> Toy simulation

这是一个由 ChatGPT 创建的玩具模拟小部件，旨在演示三种特定的故障模式。

> Here is a toy simulation widget, created by ChatGPT, designed to demonstrate three specific failure modes.

我们假设真实函数是：

> We assume the ground truth function is:

$$
\hat{L}(N, D) = 482.01 \cdot N^{-0.3478} + 2085.43 D^{-0.3658} + 1.8172
$$

因此 $N_\text{opt} \propto C^{0.5126}, D_\text{opt} \propto C^{0.4874}$。这是来自[Besiroglu 等人 (2024)](https://arxiv.org/abs/2404.10102)的估计。

> and thus $N_\text{opt} \propto C^{0.5126}, D_\text{opt} \propto C^{0.4874}$. This is the estimate from [Besiroglu et al. (2024)](https://arxiv.org/abs/2404.10102).

该模拟绘制了损失预测 $\hat{L}$ 与数据集大小 $D$ 的关系图，同时提供了一组滑块来展示：

> The simulation plots the loss prediction $\hat{L}$ vs dataset size $D$, while providing a set of sliders to show case:

- 损失精度：将损失从高精度舍入到低精度小数位会改变拟合的参数值。
- 损失噪声：仅通过毫损失（0.001）单位的乘数扰动损失值会导致不同的拟合结果。
- 拟合区域敏感性：仅拟合小型模型、仅拟合中型模型或拟合所有模型会得出不同的表观缩放定律。

> • Loss precision: rounding losses from high to low decimal points can change the fitted parameter values.
> • Loss noise: perturbing loss values by only a multiplier of milli-loss (0.001) units leads to different fit.
> • Fit-region sensitivity: fitting only small models, only medium models, or all models gives different apparent scaling laws.

### 引用

> Citation

请引用此作品为：

> Please cite this work as:

> Weng, Lilian. “缩放定律，谨慎为之”。Lil’Log (2026年6月)。https://lilianweng.github.io/posts/2026-06-24-scaling-laws/

> Weng, Lilian. “Scaling Laws, Carefully”. Lil’Log (Jun 2026). https://lilianweng.github.io/posts/2026-06-24-scaling-laws/

或使用BibTex引用：

> Or use the BibTex citation:

```
@article{weng2026scaling,
 title = {Scaling Laws, Carefully},
 author = {Weng, Lilian},
 journal = {lilianweng.github.io},
 year = {2026},
 month = {June},
 url = "https://lilianweng.github.io/posts/2026-06-24-scaling-laws/"
}
```

### 参考文献

> References

[1] S. Amari, N. Fujita, and S. Shinomoto. [“四种学习曲线。神经网络计算。”](https://ieeexplore.ieee.org/document/6796972) 4(4):605–618, 1992.

> [1] S. Amari, N. Fujita, and S. Shinomoto. [“Four Types of Learning Curves. Neural Computation.”](https://ieeexplore.ieee.org/document/6796972) 4(4):605–618, 1992.

[2] Hestness et al. [“深度学习缩放是可预测的，经验上。”](https://arxiv.org/abs/1712.00409) arXiv preprint arXiv:1712.00409, 2017.

> [2] Hestness et al. [“Deep Learning Scaling is Predictable, Empirically.”](https://arxiv.org/abs/1712.00409) arXiv preprint arXiv:1712.00409, 2017.

[3] Rosenfeld et al. [“跨尺度的泛化误差的建设性预测。”](https://arxiv.org/abs/1909.12673) ICLR 2020.

> [3] Rosenfeld et al. [“A Constructive Prediction of the Generalization Error Across Scales.”](https://arxiv.org/abs/1909.12673) ICLR 2020.

[4] Kaplan et al. [“神经语言模型的缩放定律。”](https://arxiv.org/abs/2001.08361) arXiv preprint arXiv:2001.08361, 2020.

> [4] Kaplan et al. [“Scaling Laws for Neural Language Models.”](https://arxiv.org/abs/2001.08361) arXiv preprint arXiv:2001.08361, 2020.

[5] Hoffmann et al. [“训练计算最优的大型语言模型。”](https://arxiv.org/abs/2203.15556) NeurIPS 2022.

> [5] Hoffmann et al. [“Training Compute-Optimal Large Language Models.”](https://arxiv.org/abs/2203.15556) NeurIPS 2022.

[6] Pearce and Song. [“调和Kaplan和Chinchilla缩放定律。”](https://arxiv.org/abs/2406.12907) TMLR 2024.

> [6] Pearce and Song. [“Reconciling Kaplan and Chinchilla Scaling Laws.”](https://arxiv.org/abs/2406.12907) TMLR 2024.

[7] Bahri et al. [“解释神经缩放定律。”](https://arxiv.org/abs/2102.06701) arXiv preprint arXiv:2102.06701, 2021.

> [7] Bahri et al. [“Explaining Neural Scaling Laws.”](https://arxiv.org/abs/2102.06701) arXiv preprint arXiv:2102.06701, 2021.

[8] Sharma and Kaplan. [“来自数据流形维度的神经缩放定律。”](https://arxiv.org/abs/2004.10802) arXiv preprint arXiv:2004.10802, 2020.

> [8] Sharma and Kaplan. [“A Neural Scaling Law from the Dimension of the Data Manifold.”](https://arxiv.org/abs/2004.10802) arXiv preprint arXiv:2004.10802, 2020.

[9] Hernandez et al. [“从重复数据学习的缩放定律和可解释性。”](https://arxiv.org/abs/2205.10487) arXiv preprint arXiv:2205.10487, 2022.

> [9] Hernandez et al. [“Scaling Laws and Interpretability of Learning from Repeated Data.”](https://arxiv.org/abs/2205.10487) arXiv preprint arXiv:2205.10487, 2022.

[10] Muennighoff et al. [“缩放数据受限的语言模型。”](https://arxiv.org/abs/2305.16264) NeurIPS 2023.

> [10] Muennighoff et al. [“Scaling Data-Constrained Language Models.”](https://arxiv.org/abs/2305.16264) NeurIPS 2023.

[11] Lovelace 等人。 [“数据受限训练的规范性缩放定律。”](https://arxiv.org/abs/2605.01640) arXiv 预印本 arXiv:2605.01640, 2026。

> [11] Lovelace et al. [“Prescriptive Scaling Laws for Data Constrained Training.”](https://arxiv.org/abs/2605.01640) arXiv preprint arXiv:2605.01640, 2026.

[12] Besiroglu 等人。 [“Chinchilla 缩放：一项复制尝试。”](https://arxiv.org/abs/2404.10102) arXiv 预印本 arXiv:2404.10102, 2024。

> [12] Besiroglu et al. [“Chinchilla Scaling: A Replication Attempt.”](https://arxiv.org/abs/2404.10102) arXiv preprint arXiv:2404.10102, 2024.

[13] Michaud 等人。 [“神经缩放的量化模型”](https://arxiv.org/abs/2303.13506) NeurIPS 2023。

> [13] Michaud et al. [“The Quantization Model of Neural Scaling”](https://arxiv.org/abs/2303.13506) NeurIPS 2023.

[14] Brill。[“植根于数据分布的神经缩放定律。”](https://arxiv.org/abs/2412.07942) arXiv 预印本 arXiv:2412.07942, 2024。

> [14] Brill. [“Neural Scaling Laws Rooted in the Data Distribution.”](https://arxiv.org/abs/2412.07942) arXiv preprint arXiv:2412.07942, 2024.

[15] Rae 等人。 [“缩放语言模型：Gopher 训练的方法、分析与见解。”](https://arxiv.org/abs/2112.11446) arXiv 预印本 arXiv:2112.11446, 2021。

> [15] Rae et al. [“Scaling Language Models: Methods, Analysis & Insights from Training Gopher.”](https://arxiv.org/abs/2112.11446) arXiv preprint arXiv:2112.11446, 2021.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Scaling law | 缩放定律 | 描述规模变量与模型损失之间经验关系的定律。 |
| Compute-optimal | 计算最优 | 在固定计算预算下最优分配模型规模与数据量。 |
| Power law | 幂律 | 变量之间满足幂函数形式的关系。 |
| Irreducible loss | 不可约损失 | 增加模型或数据后仍无法消除的残余损失。 |
| Generalization error | 泛化误差 | 模型在未见数据上的预测误差。 |
| IsoFLOP curve | 等 FLOP 曲线 | 固定计算量、比较不同模型和数据配置的曲线。 |
| Data-constrained regime | 数据受限区域 | 唯一训练数据不足、需要重复使用数据的训练场景。 |
| Capacity ratio | 容量比 | 模型参数量相对于唯一 token 数的比值。 |
| Overfitting penalty | 过拟合惩罚 | 用于刻画数据重复与模型过参数化造成额外损失的项。 |
| Extrapolation | 外推 | 根据小规模实验拟合结果预测更大规模训练表现。 |
