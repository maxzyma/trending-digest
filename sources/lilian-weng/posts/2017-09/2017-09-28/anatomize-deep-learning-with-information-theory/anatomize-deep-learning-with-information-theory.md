# 用信息论剖析深度学习

> Anatomize Deep Learning with Information Theory

> 来源：Lil'Log / Lilian Weng，2017-09-28
> 原文链接：https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/
> 分类：深度学习 / 信息论

## 核心要点

- 文章介绍了Naftali Tishby教授利用信息瓶颈方法剖析深度神经网络训练过程的理论。
- 深度神经网络的训练过程包含两个阶段：首先充分表示输入数据并最小化泛化误差，然后通过压缩表示来遗忘不相关细节。
- 深度神经网络的各层可以被视为马尔可夫链，数据处理不等式表明层与输入之间的互信息会随着层深度的增加而减少。
- 信息平面定理通过编码器互信息I(X; Ti)和解码器互信息I(Ti; Y)来表征深度神经网络的每一层。
- 在信息平面中，学习过程表现为隐藏层先学习大量输入信息，随后通过压缩遗忘不相关信息以提高泛化能力。
- 传统的泛化界限不适用于深度学习，因为它们无法解释更大网络表现更好的现象。
- Tishby等人提出了基于输入压缩的新泛化界限，该界限与互信息I(Tε; X)相关。
- 增加深度神经网络的隐藏层数量可以带来计算优势，并通过随机弛豫加速训练过程。
- 增加训练样本量会促使解码器互信息I(T; Y)接近理论信息瓶颈界限，从而提高泛化能力。
- 互信息而非层大小或VC维数是决定深度学习泛化能力的关键因素。

## 正文

Naftali Tishby 教授于 2021 年去世。希望这篇文章能将他关于信息瓶颈的酷炫想法介绍给更多人。

> Professor Naftali Tishby passed away in 2021. Hope the post can introduce his cool idea of information bottleneck to more people.

最近我观看了 Naftali Tishby 教授的讲座[“深度学习中的信息论”](https://youtu.be/bLqJHjXihK8)，觉得非常有趣。他介绍了如何应用信息论来研究深度神经网络在训练过程中的增长和转换。他利用[信息瓶颈（IB）](https://arxiv.org/pdf/physics/0004057.pdf)方法，为深度神经网络（DNN）提出了一个新的学习界限，因为传统的学习理论由于参数数量呈指数级增长而失效。另一个敏锐的观察是，DNN 训练涉及两个不同的阶段：首先，网络被训练以完全表示输入数据并最小化泛化误差；然后，它通过压缩输入的表示来学习遗忘不相关的细节。

> Recently I watched the talk [“Information Theory in Deep Learning”](https://youtu.be/bLqJHjXihK8) by Prof Naftali Tishby and found it very interesting. He presented how to apply the information theory to study the growth and transformation of deep neural networks during training. Using the [Information Bottleneck (IB)](https://arxiv.org/pdf/physics/0004057.pdf) method, he proposed a new learning bound for deep neural networks (DNN), as the traditional learning theory fails due to the exponentially large number of parameters. Another keen observation is that DNN training involves two distinct phases: First, the network is trained to fully represent the input data and minimize the generalization error; then, it learns to forget the irrelevant details by compressing the representation of the input.

本文中的大部分材料来自 Tishby 教授的演讲和[相关论文](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/#references)。

> Most of the materials in this post are from Prof Tishby’s talk and [related papers](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/#references).

### 基本概念

> Basic Concepts

[马尔可夫链](https://en.wikipedia.org/wiki/Markov_chain)

> [Markov Chain](https://en.wikipedia.org/wiki/Markov_chain)

马尔可夫过程是一种[“无记忆”](http://mathworld.wolfram.com/Memoryless.html)（也称为“马尔可夫性质”）随机过程。马尔可夫链是一种包含多个离散状态的马尔可夫过程。也就是说，过程未来状态的条件概率仅由当前状态决定，而不依赖于过去的状态。

> A Markov process is a [“memoryless”](http://mathworld.wolfram.com/Memoryless.html) (also called “Markov Property”) stochastic process. A Markov chain is a type of Markov process containing multiple discrete states. That is being said, the conditional probability of future states of the process is only determined by the current state and does not depend on the past states.

[Kullback–Leibler (KL) 散度](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)

> [Kullback–Leibler (KL) Divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)

KL 散度衡量一个概率分布 $p$ 与第二个预期概率分布 $q$ 之间的差异程度。它是非对称的。

> KL divergence measures how one probability distribution $p$ diverges from a second expected probability distribution $q$. It is asymmetric.

$$
\begin{aligned}
D_{KL}(p \| q) &= \sum_x p(x) \log \frac{p(x)}{q(x)} \\
 &= - \sum_x p(x)\log q(x) + \sum_x p(x)\log p(x) \\
 &= H(P, Q) - H(P)
\end{aligned}
$$

$D_{KL}$ 当 $p(x)$ == $q(x)$ 处处时达到最小零值。

> $D_{KL}$ achieves the minimum zero when $p(x)$ == $q(x)$ everywhere.

[互信息](https://en.wikipedia.org/wiki/Mutual_information)

> [Mutual Information](https://en.wikipedia.org/wiki/Mutual_information)

互信息衡量两个变量之间的相互依赖性。它量化了通过另一个随机变量获得的关于一个随机变量的“信息量”。互信息是对称的。

> Mutual information measures the mutual dependence between two variables. It quantifies the “amount of information” obtained about one random variable through the other random variable. Mutual information is symmetric.

$$
\begin{aligned}
I(X;Y) &= D_{KL}[p(x,y) \| p(x)p(y)] \\
 &= \sum_{x \in X, y \in Y} p(x, y) \log(\frac{p(x, y)}{p(x)p(y)}) \\
 &= \sum_{x \in X, y \in Y} p(x, y) \log(\frac{p(x|y)}{p(x)}) \\ 
 &= H(X) - H(X|Y) \\
\end{aligned}
$$

[数据处理不等式 (DPI)](https://en.wikipedia.org/wiki/Data_processing_inequality)

> [Data Processing Inequality (DPI)](https://en.wikipedia.org/wiki/Data_processing_inequality)

对于任何马尔可夫链：$X \to Y \to Z$，我们会有 $I(X; Y) \geq I(X; Z)$。

> For any markov chain: $X \to Y \to Z$, we would have $I(X; Y) \geq I(X; Z)$.

深度神经网络可以被视为一个马尔可可夫链，因此当我们沿着 DNN 的层向下移动时，层与输入之间的互信息只会减少。

> A deep neural network can be viewed as a Markov chain, and thus when we are moving down the layers of a DNN, the mutual information between the layer and the input can only decrease.

[重参数化不变性](https://en.wikipedia.org/wiki/Parametrization#Parametrization_invariance)

> [Reparametrization invariance](https://en.wikipedia.org/wiki/Parametrization#Parametrization_invariance)

对于两个可逆函数 $\phi$、$\psi$，互信息仍然成立：$I(X; Y) = I(\phi(X); \psi(Y))$。

> For two invertible functions $\phi$, $\psi$, the mutual information still holds: $I(X; Y) = I(\phi(X); \psi(Y))$.

例如，如果我们打乱 DNN 某一层中的权重，它不会影响该层与另一层之间的互信息。

> For example, if we shuffle the weights in one layer of DNN, it would not affect the mutual information between this layer and another.

### 作为马尔可夫链的深度神经网络

> Deep Neural Networks as Markov Chains

训练数据包含从 $X$ 和 $Y$ 的联合分布中采样的观测值。输入变量 $X$ 和隐藏层的权重都是高维随机变量。在分类设置中，真实目标 $Y$ 和预测值 $\hat{Y}$ 是维度较小的随机变量。

> The training data contains sampled observations from the joint distribution of $X$ and $Y$. The input variable $X$ and weights of hidden layers are all high-dimensional random variable. The ground truth target $Y$ and the predicted value $\hat{Y}$ are random variables of smaller dimensions in the classification settings.

![The structure of a deep neural network, which consists of the target label $Y$, input layer $X$, hidden layers $h\_1, \dots, h\_m$ and the final prediction $\hat{Y}$. (Image source: Tishby and Zaslavsky, 2015 )](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/ib-dnn-structure.png)

如果我们将 DNN 的隐藏层标记为 $h_1, h_2, \dots, h_m$，如图 1 所示，我们可以将每一层视为马尔可夫链的一个状态：$h_i \to h_{i+1}$。根据 DPI，我们会有：

> If we label the hidden layers of a DNN as $h_1, h_2, \dots, h_m$ as in Fig. 1, we can view each layer as one state of a Markov Chain: $h_i \to h_{i+1}$. According to DPI, we would have:

$$
\begin{aligned}
H(X) \geq I(X; h_1) \geq I(X; h_2) \geq \dots \geq I(X; h_m) \geq I(X; \hat{Y}) \\
I(X; Y) \geq I(h_1; Y) \geq I(h_2; Y) \geq \dots \geq I(h_m; Y) \geq I(\hat{Y}; Y)
\end{aligned}
$$

DNN 旨在学习如何描述 $X$ 以预测 $Y$，并最终压缩 $X$ 以仅保留与 $Y$ 相关的信息。Tishby 将此过程描述为 *“相关信息的逐次提炼”*。

> A DNN is designed to learn how to describe $X$ to predict $Y$ and eventually, to compress $X$ to only hold the information related to $Y$. Tishby describes this processing as *“successive refinement of relevant information”*.

#### 信息平面定理

> Information Plane Theorem

DNN 具有 $X$ 的连续内部表示，即一组隐藏层 $\{T_i\}$。*信息平面*定理通过其编码器和解码器信息来表征每一层。编码器是输入数据 $X$ 的表示，而解码器将当前层中的信息转换为目标输出 $Y$。

> A DNN has successive internal representations of $X$, a set of hidden layers $\{T_i\}$. The *information plane* theorem characterizes each layer by its encoder and decoder information. The encoder is a representation of the input data $X$, while the decoder translates the information in the current layer to the target ouput $Y$.

准确地说，在信息平面图中：

> Precisely, in an information plane plot:

• **X轴**：$T_i$的样本复杂度由编码器互信息$I(X; T_i)$决定。样本复杂度是指达到特定准确性和泛化能力所需的样本数量。

• **Y轴**：准确性（泛化误差）由解码器互信息$I(T_i; Y)$决定。

英文原文：

• **X-axis**: The sample complexity of $T_i$ is determined by the encoder mutual information $I(X; T_i)$. Sample complexity refers to how many samples you need to achieve certain accuracy and generalization.

• **Y-axis**: The accuracy (generalization error) is determined by the decoder mutual information $I(T_i; Y)$.

![The encoder vs decoder mutual information of DNN hidden layers of 50 experiments. Different layers are color-coders, with green being the layer right next to the input and the orange being the furthest. There are three snapshots, at the initial epoch, 400 epochs and 9000 epochs respectively. (Image source: Shwartz-Ziv and Tishby, 2017 )](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/ib-information-plane.png)

每个点都标记了单个网络模拟中一个隐藏层的编码器/解码器互信息（未应用正则化；无权重衰减、无 dropout 等）。它们按预期向上移动，因为关于真实标签的知识正在增加（准确性提高）。在早期阶段，隐藏层学习了大量关于输入$X$的信息，但后来它们开始压缩以忘记一些关于输入的信息。Tishby 认为*“学习最重要的部分实际上是遗忘”*。请查看这个[精彩视频](https://youtu.be/P1A1yNsxMjc)，它演示了层互信息度量如何随 epoch 时间变化。

> Each dot in marks the encoder/ decoder mutual information of one hidden layer of one network simulation (no regularization is applied; no weights decay, no dropout, etc.). They move up as expected because the knowledge about the true labels is increasing (accuracy increases). At the early stage, the hidden layers learn a lot about the input $X$, but later they start to compress to forget some information about the input. Tishby believes that *“the most important part of learning is actually forgetting”*. Check out this [nice video](https://youtu.be/P1A1yNsxMjc) that demonstrates how the mutual information measures of layers are changing in epoch time.

![Here is an aggregated view of Fig 2. The compression happens after the generalization error becomes very small. (Image source: Tishby’ talk 15:15 )](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/ib-information-plane-merged.png)

#### 两个优化阶段

> Two Optimization Phases

随时间跟踪每个层权重的归一化均值和标准差也揭示了训练过程的两个优化阶段。

> Tracking the normalized mean and standard deviation of each layer’s weights in time also reveals two optimization phases of the training process.

![The norm of mean and standard deviation of each layer's weight gradients for each layer as a function of training epochs. Different layers are color-coded. (Image source: Shwartz-Ziv and Tishby, 2017 )](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/ib-mean-variation.png)

在早期 epoch 中，均值比标准差大三个数量级。经过足够多的 epoch 后，误差饱和，之后标准差变得更加嘈杂。层离输出越远，它就越嘈杂，因为噪声可以通过反向传播过程被放大和累积（并非由于层的宽度）。

> Among early epochs, the mean values are three magnitudes larger than the standard deviations. After a sufficient number of epochs, the error saturates and the standard deviations become much noisier afterward. The further a layer is away from the output, the noisier it gets, because the noises can get amplified and accumulated through the back-prop process (not due to the width of the layer).

### 学习理论

> Learning Theory

#### “旧”泛化界限

> “Old” Generalization Bounds

经典学习理论定义的泛化界限是：

> The generalization bounds defined by the classic learning theory is:

$$
\epsilon^2 < \frac{\log|H_\epsilon| + \log{1/\delta}}{2m}
$$

• $\epsilon$：训练误差和泛化误差之间的差异。泛化误差衡量算法对先前未见过的数据的预测准确性。

• $H_\epsilon$：假设类的$\epsilon$覆盖。通常我们假设大小为$\vert H_\epsilon \vert \sim (1/\epsilon)^d$。

• $\delta$：置信度。

• $m$: 训练样本的数量。

• $d$: 假设的VC维。

英文原文：

• $\epsilon$: The difference between the training error and the generalization error. The generalization error measures how accurate the prediction of an algorithm is for previously unseen data.

• $H_\epsilon$: ε-cover of the hypothesis class. Typically we assume the size $\vert H_\epsilon \vert \sim (1/\epsilon)^d$.

• $\delta$: Confidence.

• $m$: The number of training samples.

• $d$: The VC dimension of the hypothesis.

这个定义指出，训练误差和泛化误差之间的差异受假设空间大小和数据集大小的函数限制。假设空间越大，泛化误差就越大。如果你对泛化界限感兴趣，我推荐这篇关于机器学习理论的教程，[第一部分](https://mostafa-samir.github.io/ml-theory-pt1/)和[第二部分](https://mostafa-samir.github.io/ml-theory-pt2/)。

> This definition states that the difference between the training error and the generalization error is bounded by a function of the hypothesis space size and the dataset size. The bigger the hypothesis space gets, the bigger the generalization error becomes. I recommend this tutorial on ML theory, [part1](https://mostafa-samir.github.io/ml-theory-pt1/) and [part2](https://mostafa-samir.github.io/ml-theory-pt2/), if you are interested in reading more on generalization bounds.

然而，它不适用于深度学习。网络越大，需要学习的参数就越多。根据这些泛化界限，更大的网络（更大的$d$）将具有更差的界限。这与更大的网络能够以更高的表达能力实现更好性能的直觉相悖。

> However, it does not work for deep learning. The larger a network is, the more parameters it needs to learn. With this generalization bounds, larger networks (larger $d$) would have worse bounds. This is contrary to the intuition that larger networks are able to achieve better performance with higher expressivity.

#### “新”输入压缩界限

> “New” Input compression bound

为了解决这个反直觉的观察，Tishby 等人提出了一种新的DNN输入压缩界限。

> To solve this counterintuitive observation, Tishby et al. proposed a new input compression bound for DNN.

首先我们有$T_\epsilon$作为ε-划分的输入变量$X$。这个划分将输入根据标签的同质性压缩成小单元。这些单元总共可以覆盖整个输入空间。如果预测输出是二进制值，我们可以用假设的基数，$\vert H_\epsilon \vert$，替换为$2^{\vert T_\epsilon \vert}$。

> First let us have $T_\epsilon$ as an ε-partition of the input variable $X$. This partition compresses the input with respect to the homogeneity to the labels into small cells. The cells in total can cover the whole input space. If the prediction outputs binary values, we can replace the cardinality of the hypothesis, $\vert H_\epsilon \vert$, with $2^{\vert T_\epsilon \vert}$.

$$
|H_\epsilon| \sim 2^{|X|} \to 2^{|T_\epsilon|}
$$

当 $X$ 很大时，$X$ 的大小大约是 $2^{H(X)}$。$\epsilon$ 分区中的每个单元格大小为 $2^{H(X \vert T_\epsilon)}$。因此我们有 $\vert T_\epsilon \vert \sim \frac{2^{H(X)}}{2^{H(X \vert T_\epsilon)}} = 2^{I(T_\epsilon; X)}$。那么输入压缩界限变为：

> When $X$ is large, the size of $X$ is approximately $2^{H(X)}$. Each cell in the ε-partition is of size $2^{H(X \vert T_\epsilon)}$. Therefore we have $\vert T_\epsilon \vert \sim \frac{2^{H(X)}}{2^{H(X \vert T_\epsilon)}} = 2^{I(T_\epsilon; X)}$. Then the input compression bound becomes:

$$
\epsilon^2 < \frac{2^{I(T_\epsilon; X)} + \log{1/\delta}}{2m}
$$

![The black line is the optimal achievable information bottleneck (IB) limit. The red line corresponds to the upper bound on the out-of-sample IB distortion, when trained on a finite sample set. $\Delta C$ is the complexity gap and $\Delta G$ is the generalization gap. (Recreated based on Tishby’ talk 24:50 )](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/ib-bound.png)

### 网络规模和训练数据规模

> Network Size and Training Data Size

#### 更多隐藏层的好处

> The Benefit of More Hidden Layers

拥有更多层可以带来计算上的优势，并加速训练过程以实现良好的泛化。

> Having more layers give us computational benefits and speed up the training process for good generalization.

![The optimization time is much shorter (fewer epochs) with more hidden layers. (Image source: Shwartz-Ziv and Tishby, 2017 )](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/ib-layers.png)

**通过随机弛豫进行压缩**：根据[扩散方程](https://en.wikipedia.org/wiki/Fokker%E2%80%93Planck_equation)，层`k`的弛豫时间与该层的压缩量$\Delta S_k$的指数成正比：$\Delta t_k \sim \exp(\Delta S_k)$。我们可以将层压缩计算为$\Delta S_k = I(X; T_k) - I(X; T_{k-1})$。因为$\exp(\sum_k \Delta S_k) \geq \sum_k \exp(\Delta S_k)$，我们预计随着隐藏层数量的增加（更大的`k`），训练周期会呈指数级减少。

英文原文：Compression through stochastic relaxation: According to the [diffusion equation](https://en.wikipedia.org/wiki/Fokker%E2%80%93Planck_equation), the relaxation time of layer `k` is proportional to the exponential of this layer’s compression amount 

$\Delta S_k$: 

$\Delta t_k \sim \exp(\Delta S_k)$. We can compute the layer compression as 

$\Delta S_k = I(X; T_k) - I(X; T_{k-1})$.  Because 

$\exp(\sum_k \Delta S_k) \geq \sum_k \exp(\Delta S_k)$, we would expect an exponential decrease in training epochs with more hidden layers (larger `k`).

#### 更多训练样本的好处

> The Benefit of More Training Samples

拟合更多训练数据需要隐藏层捕获更多信息。随着训练数据量的增加，解码器互信息（回想一下，这与泛化误差直接相关），$I(T; Y)$，被推高并接近理论信息瓶颈界限。Tishby 强调，决定泛化的是互信息，而不是层大小或VC维数，这与标准理论不同。

> Fitting more training data requires more information captured by the hidden layers. With increased training data size, the decoder mutual information (recall that this is directly related to the generalization error), $I(T; Y)$, is pushed up and gets closer to the theoretical information bottleneck bound. Tishby emphasized that It is the mutual information, not the layer size or the VC dimension, that determines generalization, different from standard theories.

![The training data of different sizes is color-coded. The information plane of multiple converged networks are plotted. More training data leads to better generalization. (Image source: Shwartz-Ziv and Tishby, 2017 )](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/ib-training-size.png)

引用来源：

> Cited as:

```
@article{weng2017infotheory,
  title   = "Anatomize Deep Learning with Information Theory",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2017",
  url     = "https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/"
}
```

### 参考文献

> References

[1] Naftali Tishby. [深度学习的信息理论](https://youtu.be/bLqJHjXihK8)

> [1] Naftali Tishby. [Information Theory of Deep Learning](https://youtu.be/bLqJHjXihK8)

[2] [机器学习理论 - 第1部分：引言](https://mostafa-samir.github.io/ml-theory-pt1/)

> [2] [Machine Learning Theory - Part 1: Introduction](https://mostafa-samir.github.io/ml-theory-pt1/)

[3] [机器学习理论 - 第2部分：泛化界限](https://mostafa-samir.github.io/ml-theory-pt2/)

> [3] [Machine Learning Theory - Part 2: Generalization Bounds](https://mostafa-samir.github.io/ml-theory-pt2/)

[4] Quanta Magazine 的 [新理论揭示深度学习黑箱](https://www.quantamagazine.org/new-theory-cracks-open-the-black-box-of-deep-learning-20170921/)。

> [4] [New Theory Cracks Open the Black Box of Deep Learning](https://www.quantamagazine.org/new-theory-cracks-open-the-black-box-of-deep-learning-20170921/) by Quanta Magazine.

[5] Naftali Tishby 和 Noga Zaslavsky. [“深度学习与信息瓶颈原理。”](https://arxiv.org/pdf/1503.02406.pdf) IEEE Information Theory Workshop (ITW), 2015。

> [5] Naftali Tishby and Noga Zaslavsky. [“Deep learning and the information bottleneck principle.”](https://arxiv.org/pdf/1503.02406.pdf) IEEE Information Theory Workshop (ITW), 2015.

[6] Ravid Shwartz-Ziv 和 Naftali Tishby. [“通过信息打开深度神经网络的黑箱。”](https://arxiv.org/pdf/1703.00810.pdf) arXiv preprint arXiv:1703.00810, 2017。

> [6] Ravid Shwartz-Ziv and Naftali Tishby. [“Opening the Black Box of Deep Neural Networks via Information.”](https://arxiv.org/pdf/1703.00810.pdf) arXiv preprint arXiv:1703.00810, 2017.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Information Bottleneck (IB) | 信息瓶颈 | 一种信息论方法，用于提取随机变量中最相关的压缩表示。 |
| Deep Neural Networks (DNN) | 深度神经网络 | 具有多层隐藏层的神经网络，用于学习复杂模式。 |
| Markov Chain | 马尔可夫链 | 一种“无记忆”的随机过程，未来状态仅取决于当前状态。 |
| Kullback–Leibler (KL) Divergence | Kullback–Leibler (KL) 散度 | 衡量两个概率分布之间差异程度的非对称度量。 |
| Mutual Information | 互信息 | 量化两个随机变量之间相互依赖性或共享信息量的对称度量。 |
| Data Processing Inequality (DPI) | 数据处理不等式 | 指出在马尔可夫链中，信息不能通过数据处理而增加。 |
| Reparameterization Invariance | 重参数化不变性 | 指互信息在对变量进行可逆函数变换后保持不变的性质。 |
| Information Plane | 信息平面 | 一个二维图，通过编码器互信息和解码器互信息来表征深度神经网络的每一层。 |
| Generalization Error | 泛化误差 | 衡量机器学习模型对未见过数据预测准确性的误差。 |
| VC Dimension | VC维 | 衡量分类器或假设空间复杂度的统计量。 |
| Input Compression Bound | 输入压缩界限 | Tishby等人提出的新泛化界限，基于深度神经网络对输入信息的压缩程度。 |
| Random Relaxation | 随机弛豫 | 描述系统如何通过随机过程逐渐达到平衡状态。 |
| Epoch | 训练周期 | 机器学习中，指整个训练数据集在神经网络中完整传递一次的迭代。 |
| Encoder Information | 编码器互信息 | 衡量隐藏层对输入数据X的表示能力，即I(X; Ti)。 |
| Decoder Information | 解码器互信息 | 衡量隐藏层对目标输出Y的预测能力，即I(Ti; Y)。 |
