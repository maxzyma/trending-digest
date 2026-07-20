# 深度神经网络是否严重过拟合？

> Are Deep Neural Networks Dramatically Overfitted?

> 来源：Lil'Log / Lilian Weng，2019-03-14
> 原文链接：https://lilianweng.github.io/posts/2019-03-14-overfit/
> 分类：深度学习 / 泛化与过拟合

## 核心要点

- 深度神经网络参数量巨大，训练误差易达完美，但其泛化能力常超出传统机器学习预期。
- 奥卡姆剃刀和最小描述长度（MDL）原理等经典理论倾向于更简单的模型以实现更好的泛化。
- MDL原理将学习视为数据压缩，认为最佳模型是编码数据和模型本身总长度最小的那个。
- 深度神经网络具有强大的表达能力，能以任意精度近似任何连续函数，甚至完美学习训练数据中的随机噪声。
- 深度学习模型的泛化能力不完全遵循传统U形风险曲线，而是呈现双U形曲线，表明在参数量极大时仍能良好泛化。
- 显式正则化（如数据增强、权重衰减和Dropout）并非深度学习模型泛化的根本原因。
- 内在维度研究表明，深度学习模型在有效学习时所需的参数子空间远小于其总参数量，暗示其真实复杂性较低。
- 异构层鲁棒性研究发现，深度神经网络中并非所有层都同等重要，通常只有靠近输入层的少数层对模型性能至关重要。
- 乐透彩票假说提出，随机初始化的密集网络中存在稀疏子网络（“中奖彩票”），单独训练即可达到与原网络相当的性能。
- 这些研究共同挑战了深度学习中关于过拟合和模型复杂度的传统观念，解释了其在参数量巨大情况下的良好泛化能力。

## 正文

[2019-05-27 更新：增加了关于 [彩票假说](https://lilianweng.github.io/posts/2019-03-14-overfit/#the-lottery-ticket-hypothesis) 的部分。]

> [Updated on 2019-05-27: add the [section](https://lilianweng.github.io/posts/2019-03-14-overfit/#the-lottery-ticket-hypothesis) on Lottery Ticket Hypothesis.]

如果你和我一样，带着传统机器学习的经验进入深度学习领域，你可能会经常思考这个问题：一个典型的深度神经网络有如此多的参数，并且训练误差可以很容易地达到完美，它肯定会遭受严重的过拟合。它怎么可能泛化到样本外的数据点呢？

> If you are like me, entering into the field of deep learning with experience in traditional machine learning, you may often ponder over this question: Since a typical deep neural network has so many parameters and training error can easily be perfect, it should surely suffer from substantial overfitting. How could it be ever generalized to out-of-sample data points?

试图理解深度神经网络为何能够泛化，这让我想起了系统生物学领域一篇有趣的文章——[“生物学家能修理收音机吗？”](https://www.cell.com/cancer-cell/pdf/S1535-6108(02)00133-2.pdf) (Lazebnik, 2002)。如果一位生物学家像研究生物系统那样试图修理收音机，那会很困难。因为收音机系统的完整机制并未揭示，探究小的局部功能可能会提供一些线索，但它很难呈现系统内的所有相互作用，更不用说整个工作流程了。无论你是否认为它与深度学习相关，这都是一篇非常有趣的文章。

> The effort in understanding why deep neural networks can generalize somehow reminds me of this interesting paper on System Biology — [“Can a biologist fix a radio?”](https://www.cell.com/cancer-cell/pdf/S1535-6108(02)00133-2.pdf) (Lazebnik, 2002). If a biologist intends to fix a radio machine like how she works on a biological system, life could be hard. Because the full mechanism of the radio system is not revealed, poking small local functionalities might give some hints but it can hardly present all the interactions within the system, let alone the entire working flow. No matter whether you think it is relevant to DL, it is a very fun read.

我想在这篇文章中讨论几篇关于深度学习模型泛化能力和复杂性度量的论文。希望它能为你在理解深度神经网络为何能够泛化方面提供一些启发。

> I would like to discuss a couple of papers on generalizability and complexity measurement of deep learning models in the post. Hopefully, it could shed light on your thinking path towards the understanding of why DNN can generalize.

### 压缩与模型选择的经典定理

> Classic Theorems on Compression and Model Selection

假设我们有一个分类问题和一个数据集，我们可以开发许多模型来解决它，从拟合简单的线性回归到在磁盘空间中记忆整个数据集。哪一个更好呢？如果我们只关心训练数据的准确性（特别是考虑到测试数据可能未知），那么记忆方法似乎是最好的——嗯，这听起来不对劲。

> Let’s say we have a classification problem and a dataset, we can develop many models to solve it, from fitting a simple linear regression to memorizing the full dataset in disk space. Which one is better? If we only care about the accuracy over training data (especially given that testing data is likely unknown), the memorization approach seems to be the best — well, it doesn’t sound right.

在这种情况下，有许多经典定理可以指导我们决定一个好的模型应该具备哪些类型的属性。

> There are many classic theorems to guide us when deciding what types of properties a good model should possess in such scenarios.

#### 奥卡姆剃刀

> Occam’s Razor

[奥卡姆剃刀](http://pespmc1.vub.ac.be/OCCAMRAZ.html) 是一个非正式的问题解决原则，由 [奥卡姆的威廉](https://en.wikipedia.org/wiki/William_of_Ockham) 在14世纪提出：

> [Occam’s Razor](http://pespmc1.vub.ac.be/OCCAMRAZ.html) is an informal principle for problem-solving, proposed by [William of Ockham](https://en.wikipedia.org/wiki/William_of_Ockham) in the 14th century:

> “更简单的解决方案比复杂的解决方案更有可能是正确的。”

> “Simpler solutions are more likely to be correct than complex ones.”

当我们面对多种解释世界的潜在理论并必须选择其中一个时，这个论断极其强大。过多的不必要假设可能对一个问题看似合理，但却难以泛化到其他复杂情况，或最终无法引向宇宙的基本原理。

> The statement is extremely powerful when we are facing multiple candidates of underlying theories to explain the world and have to pick one. Too many unnecessary assumptions might seem to be plausible for one problem, but harder to be generalized to other complications or to eventually lead to the basic principles of the universe.

试想一下，人们花了数百年才弄明白白天天空是蓝色而日落时是红色是由于相同的原因（[瑞利散射](https://en.wikipedia.org/wiki/Rayleigh_scattering)），尽管这两种现象看起来非常不同。人们肯定曾为它们分别提出了许多其他解释，但最终统一而简单的版本胜出了。

> Think of this, it took people hundreds of years to figure out that the sky is blue in the daytime but reddish at sunset are because of the same reason ([Rayleigh scattering](https://en.wikipedia.org/wiki/Rayleigh_scattering)), although two phenomena look very different. People must have proposed many other explanations for them separately but the unified and simple version won eventually.

#### 最小描述长度原理

> Minimum Description Length principle

奥卡姆剃刀原理同样可以应用于机器学习模型。这种概念的一个形式化版本被称为 *最小描述长度（MDL）* 原理，用于比较给定观测数据的竞争模型/解释。

> The principle of Occam’s Razor can be similarly applied to machine learning models. A formalized version of such concept is called the *Minimum Description Length (MDL)* principle, used for comparing competing models / explanations given data observed.

> “理解即压缩。”

> “Comprehension is compression.”

MDL 的基本思想是 *将学习视为数据压缩*。通过压缩数据，我们需要发现数据中的规律或模式，这些规律或模式具有高度泛化到未见样本的潜力。[信息瓶颈](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/) 理论认为，深度神经网络首先通过最小化泛化误差来表示数据，然后通过去除噪声来学习压缩这种表示。

> The fundamental idea in MDL is to *view learning as data compression*. By compressing the data, we need to discover regularity or patterns in the data with the high potentiality to generalize to unseen samples. [Information bottleneck](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/) theory believes that a deep neural network is trained first to represent the data by minimizing the generalization error and then learn to compress this representation by trimming noise.

同时，MDL 将模型描述视为压缩交付的一部分，因此模型不能任意大。

> Meanwhile, MDL considers the model description as part of the compression delivery, so the model cannot be arbitrarily large.

MDL 原理的 *两部分版本* 指出：设 $\mathcal{H}^{(1)}, \mathcal{H}^{(2)}, \dots$ 是可以解释数据集 $\mathcal{D}$ 的模型列表。其中最好的假设应该是使以下总和最小化的那个：

> A *two-part version* of MDL principle states that: Let $\mathcal{H}^{(1)}, \mathcal{H}^{(2)}, \dots$ be a list of models that can explain the dataset $\mathcal{D}$. The best hypothesis among them should be the one that minimizes the sum:

$$
\mathcal{H}^\text{best} = \arg\min_\mathcal{H} [L(\mathcal{H}) + L(\mathcal{D}\vert\mathcal{H})]
$$

• $L(\mathcal{H})$ 是模型 $\mathcal{H}$ 描述的长度，以比特为单位。

• $L(\mathcal{D}\vert\mathcal{H})$ 是数据 $\mathcal{D}$ 在用 $\mathcal{H}$ 编码时描述的长度，以比特为单位。

英文原文：

• $L(\mathcal{H})$ is the length of the description of model $\mathcal{H}$ in bits.

• $L(\mathcal{D}\vert\mathcal{H})$ is the length of the description of the data $\mathcal{D}$ in bits when encoded with $\mathcal{H}$.

简单来说，*最佳* 模型是包含编码数据和模型本身的 *最小* 模型。遵循这个标准，无论它在训练数据上能达到多好的准确性，我在本节开头提出的记忆方法听起来都很糟糕。

> In simple words, the *best* model is the *smallest* model containing the encoded data and the model itself. Following this criterion, the memorization approach I proposed at the beginning of the section sounds horrible no matter how good accuracy it can achieve on the training data.

人们可能会争辩说奥卡姆剃刀是错误的，因为既然现实世界可以任意复杂，我们为什么要寻找简单的模型呢？MDL 的一个有趣观点是，将模型视为 **“语言”** 而不是基本的生成定理。我们希望找到好的压缩策略来描述少量样本中的规律性，并且它们 **不必是解释现象的“真实”生成模型**。模型可能是错误的，但仍然有用（例如，想想任何贝叶斯先验）。

> People might argue Occam’s Razor is wrong, as given the real world can be arbitrarily complicated, why do we have to find simple models? One interesting view by MDL is to consider models as **“languages”** instead of fundamental generative theorems. We would like to find good compression strategies to describe regularity in a small set of samples, and they **do not have to be the “real” generative model** for explaining the phenomenon. Models can be wrong but still useful (i.e., think of any Bayesian prior).

#### 柯尔莫哥洛夫复杂度

> Kolmogorov Complexity

柯尔莫哥洛夫复杂度依赖于现代计算机的概念来定义对象的算法（描述性）复杂度：它是*描述该对象的最短二进制计算机程序的长度*。遵循MDL，计算机本质上是最通用的数据解压缩器形式。

> Kolmogorov Complexity relies on the concept of modern computers to define the algorithmic (descriptive) complexity of an object: It is *the length of the shortest binary computer program that describes the object*. Following MDL, a computer is essentially the most general form of data decompressor.

柯尔莫哥洛夫复杂度的形式化定义如下：给定一台通用计算机$\mathcal{U}$和一个程序$p$，我们用$\mathcal{U}(p)$表示计算机处理该程序后的输出，用$L(p)$表示程序的描述长度。那么，字符串的柯尔莫哥洛夫复杂度$K_\mathcal{U}$对于字符串$s$相对于通用计算机$\mathcal{U}$而言，定义为：

> The formal definition of Kolmogorov Complexity states that: Given a universal computer $\mathcal{U}$ and a program $p$, let’s denote $\mathcal{U}(p)$ as the output of the computer processing the program and $L(p)$ as the descriptive length of the program. Then Kolmogorov Complexity $K_\mathcal{U}$ of a string $s$ with respect to a universal computer $\mathcal{U}$ is:

$$
K_\mathcal{U}(s) = \min_{p: \mathcal{U}(p)=s} L(p)
$$

请注意，通用计算机是指能够模仿任何其他计算机行为的计算机。所有现代计算机都是通用的，因为它们都可以归结为图灵机。无论我们使用哪种计算机，这个定义都是通用的，因为另一台通用计算机总是可以被编程来克隆 $\mathcal{U}$ 的行为，而编码这个克隆程序只是一个常数。

> Note that a universal computer is one that can mimic the actions of any other computers. All modern computers are universal as they can all be reduced to Turing machines. The definition is universal no matter which computers we are using, because another universal computer can always be programmed to clone the behavior of $\mathcal{U}$, while encoding this clone program is just a constant.

柯尔莫哥洛夫复杂性与香农信息论之间存在许多联系，因为两者都与通用编码相关。一个惊人的事实是，随机变量的预期柯尔莫哥洛夫复杂性大约等于其香农熵（参见[报告](https://homepages.cwi.nl/~paulv/papers/info.pdf)的2.3节）。关于这个话题的更多内容超出了本文的范围，但网上有许多有趣的读物。请自行查阅 :)

> There are a lot of connections between Kolmogorov Complexity and Shannon Information Theory, as both are tied to universal coding. It is an amazing fact that the expected Kolmogorov Complexity of a random variable is approximately equal to its Shannon entropy (see Sec 2.3 of [the report](https://homepages.cwi.nl/~paulv/papers/info.pdf)). More on this topic is out of the scope here, but there are many interesting readings online. Help yourself :)

#### 索洛莫诺夫的推理理论

> Solomonoff’s Inference Theory

奥卡姆剃刀的另一种数学形式化是索洛莫诺夫的通用归纳推理理论（[索洛莫诺夫](https://www.sciencedirect.com/science/article/pii/S0019995864902232)，[1964](https://www.sciencedirect.com/science/article/pii/S0019995864901317)）。其原则是根据柯尔莫哥洛夫复杂性，偏爱那些对应于生成训练数据的“最短程序”的模型

> Another mathematical formalization of Occam’s Razor is Solomonoff’s theory of universal inductive inference  ([Solomonoff](https://www.sciencedirect.com/science/article/pii/S0019995864902232), [1964](https://www.sciencedirect.com/science/article/pii/S0019995864901317)). The principle is to favor models that correspond to the “shortest program” to produce the training data, based on its Kolmogorov complexity

### DL 模型的表达能力

> Expressive Power of DL Models

与传统统计模型相比，深度神经网络具有极其庞大的参数数量。如果我们使用 MDL 来衡量深度神经网络的复杂性，并将参数数量视为模型描述长度，那将看起来非常糟糕。模型描述 $L(\mathcal{H})$ 很容易失控。

> Deep neural networks have an extremely large number of parameters compared to the traditional statistical models. If we use MDL to measure the complexity of a deep neural network and consider the number of parameters as the model description length, it would look awful. The model description $L(\mathcal{H})$ can easily grow out of control.

然而，拥有大量参数对于神经网络获得高表达能力是*必要*的。由于其捕获任何灵活数据表示的强大能力，深度神经网络在许多应用中取得了巨大成功。

> However, having numerous parameters is *necessary* for a neural network to obtain high expressivity power. Because of its great capability to capture any flexible data representation, deep neural networks have achieved great success in many applications.

#### 万能近似定理

> Universal Approximation Theorem

*万能近似定理*指出，一个具有以下特征的前馈网络：1) 一个线性输出层，2) 至少一个包含有限数量神经元的隐藏层，以及 3) 某种激活函数，能够以任意精度近似 $\mathbb{R}^n$ 的紧凑子集上的**任何**连续函数。该定理最初是针对 sigmoid 激活函数证明的（[Cybenko, 1989](https://pdfs.semanticscholar.org/05ce/b32839c26c8d2cb38d5529cf7720a68c3fab.pdf)）。后来表明，万能近似特性并非特定于激活函数的选择（[Hornik, 1991](http://zmjones.com/static/statistical-learning/hornik-nn-1991.pdf)），而是多层前馈架构的特性。

英文原文：The *Universal Approximation Theorem* states that a feedforward network with: 1) a linear output layer, 2) at least one hidden layer containing a finite number of neurons and 3) some activation function can approximate any continuous functions on a compact subset of 

$\mathbb{R}^n$ to arbitrary accuracy. The theorem was first proved for sigmoid activation function ([Cybenko, 1989](https://pdfs.semanticscholar.org/05ce/b32839c26c8d2cb38d5529cf7720a68c3fab.pdf)). Later it was shown that the universal approximation property is not specific to the choice of activation ([Hornik, 1991](http://zmjones.com/static/statistical-learning/hornik-nn-1991.pdf)) but the multilayer feedforward architecture.

尽管单层前馈网络足以表示任何函数，但其宽度必须呈指数级增长。万能近似定理不保证模型能否被正确学习或泛化。通常，增加更多层有助于减少浅层网络所需的隐藏神经元数量。

> Although a feedforward network with a single layer is sufficient to represent any function, the width has to be exponentially large. The universal approximation theorem does not guarantee whether the model can be learned or generalized properly. Often, adding more layers helps to reduce the number of hidden neurons needed in a shallow network.

为了利用万能近似定理，我们总能找到一个神经网络来表示目标函数，使其误差低于任何期望的阈值，但我们需要付出代价——网络可能会变得非常庞大。

> To take advantage of the universal approximation theorem, we can always find a neural network to represent the target function with error under any desired threshold, but we need to pay the price — the network might grow super large.

#### 证明：两层神经网络的有限样本表达能力

> Proof: Finite Sample Expressivity of Two-layer NN

我们目前讨论的通用逼近定理没有考虑有限样本集。[Zhang 等人 (2017)](https://arxiv.org/abs/1611.03530)提供了一个关于两层神经网络有限样本表达能力的简洁证明。

> The Universal Approximation Theorem we have discussed so far does not consider a finite sample set. [Zhang, et al. (2017)](https://arxiv.org/abs/1611.03530) provided a neat proof on the finite-sample expressivity of two-layer neural networks.

神经网络 $C$ 可以表示任何函数，给定样本大小 $n$ 在 $d$ 维度中，如果：对于每个有限样本集 $S \subseteq \mathbb{R}^d$ 具有 $\vert S \vert = n$ 以及在此样本集上定义的每个函数：$f: S \mapsto \mathbb{R}$，我们可以找到一组权重配置，使得 $C$ 从而 $C(\boldsymbol{x}) = f(\boldsymbol{x}), \forall \boldsymbol{x} \in S$。

> A neural network $C$ can represent any function given a sample size $n$ in $d$ dimensions if: For every finite sample set $S \subseteq \mathbb{R}^d$ with $\vert S \vert = n$ and every function defined on this sample set: $f: S \mapsto \mathbb{R}$, we can find a set of weight configuration for $C$ so that $C(\boldsymbol{x}) = f(\boldsymbol{x}), \forall \boldsymbol{x} \in S$.

该论文提出了一个定理：

> The paper proposed a theorem:

引用译文：

存在一个具有ReLU激活函数和$2n + d$权重的两层神经网络，可以表示大小为$n$的$d$维度的任何函数。

英文原文：

There exists a two-layer neural network with ReLU activations and $2n + d$ weights that can represent any function on a sample of size $n$ in $d$ dimensions.

*证明。*首先，我们希望构建一个两层神经网络$C: \mathbb{R}^d \mapsto \mathbb{R}$。输入是一个$d$维向量，$\boldsymbol{x} \in \mathbb{R}^d$。隐藏层有$h$个隐藏单元，与一个权重矩阵$\mathbf{W} \in \mathbb{R}^{d\times h}$、一个偏置向量$-\mathbf{b} \in \mathbb{R}^h$和ReLU激活函数相关联。第二层输出一个标量值，带有权重向量$\boldsymbol{v} \in \mathbb{R}^h$和零偏置。

> *Proof.* First we would like to construct a two-layer neural network $C: \mathbb{R}^d \mapsto \mathbb{R}$. The input is a $d$ -dimensional vector, $\boldsymbol{x} \in \mathbb{R}^d$. The hidden layer has $h$ hidden units, associated with a weight matrix $\mathbf{W} \in \mathbb{R}^{d\times h}$, a bias vector $-\mathbf{b} \in \mathbb{R}^h$ and ReLU activation function. The second layer outputs a scalar value with weight vector $\boldsymbol{v} \in \mathbb{R}^h$ and zero biases.

网络$C$对于输入向量$\boldsymbol{x}$的输出可以表示如下：

> The output of network $C$ for a input vector $\boldsymbol{x}$ can be represented as follows:

$$
C(\boldsymbol{x}) 
= \boldsymbol{v} \max\{ \boldsymbol{x}\mathbf{W} - \boldsymbol{b}, 0\}^\top
= \sum_{i=1}^h v_i \max\{\boldsymbol{x}\boldsymbol{W}_{(:,i)} - b_i, 0\}
$$

其中$\boldsymbol{W}_{(:,i)}$是第$i$列，位于$d \times h$矩阵中。

> where $\boldsymbol{W}_{(:,i)}$ is the $i$ -th column in the $d \times h$ matrix.

给定一个样本集 $S = \{\boldsymbol{x}_1, \dots, \boldsymbol{x}_n\}$ 和目标值 $\boldsymbol{y} = \{y_1, \dots, y_n \}$，我们希望找到合适的权重 $\mathbf{W} \in \mathbb{R}^{d\times h}$、$\boldsymbol{b}, \boldsymbol{v} \in \mathbb{R}^h$，使得 $C(\boldsymbol{x}_i) = y_i, \forall i=1,\dots,n$。

> Given a sample set $S = \{\boldsymbol{x}_1, \dots, \boldsymbol{x}_n\}$ and target values $\boldsymbol{y} = \{y_1, \dots, y_n \}$, we would like to find proper weights $\mathbf{W} \in \mathbb{R}^{d\times h}$, $\boldsymbol{b}, \boldsymbol{v} \in \mathbb{R}^h$ so that $C(\boldsymbol{x}_i) = y_i, \forall i=1,\dots,n$.

让我们将所有样本点组合成一个批次，作为输入矩阵$\mathbf{X} \in \mathbb{R}^{n \times d}$。如果设置$h=n$，$\mathbf{X}\mathbf{W} - \boldsymbol{b}$将是一个大小为$n \times n$的方阵。

> Let’s combine all sample points into one batch as one input matrix $\mathbf{X} \in \mathbb{R}^{n \times d}$. If set $h=n$, $\mathbf{X}\mathbf{W} - \boldsymbol{b}$ would be a square matrix of size $n \times n$.

$$
\mathbf{M}_\text{ReLU} 
= \max\{\mathbf{X}\mathbf{W} - \boldsymbol{b}, 0 \} 
= \begin{bmatrix}
\boldsymbol{x}_1\mathbf{W} - \boldsymbol{b} \\
\dots \\
\boldsymbol{x}_n\mathbf{W} - \boldsymbol{b} \\
\end{bmatrix}
= [\boldsymbol{x}_i\boldsymbol{W}_{(:,j)} - b_j]_{i \times j}
$$

我们可以简化$\mathbf{W}$，使其所有列都具有相同的列向量：

> We can simplify $\mathbf{W}$ to have the same column vectors across all the columns:

$$
\mathbf{W}_{(:,j)} = \boldsymbol{w} \in \mathbb{R}^{d}, \forall j = 1, \dots, n
$$

![Fit models on CIFAR10 with random labels or random pixels: (a) learning curves; (b-c) label corruption ratio is the percentage of randomly shuffled labels. (Image source: Zhang et al. 2017 )](https://lilianweng.github.io/posts/2019-03-14-overfit/nn-expressivity-proof.png)

设$a_i = \boldsymbol{x}_i \boldsymbol{w}$，我们希望找到合适的$\boldsymbol{w}$和$\boldsymbol{b}$使得$b_1 < a_1 < b_2 < a_2 < \dots < b_n < a_n$。这总是可以实现的，因为我们试图用$n+d$个未知变量和$n$个约束来求解，并且$\boldsymbol{x}_i$是独立的（即，选择一个随机的$\boldsymbol{w}$，对$\boldsymbol{x}_i \boldsymbol{w}$进行排序，然后将$b_j$设为中间值）。那么$\mathbf{M}_\text{ReLU}$就变成了一个下三角矩阵：

> Let $a_i = \boldsymbol{x}_i \boldsymbol{w}$, we would like to find a suitable $\boldsymbol{w}$ and $\boldsymbol{b}$ such that $b_1 < a_1 < b_2 < a_2 < \dots < b_n < a_n$. This is always achievable because we try to solve $n+d$ unknown variables with $n$ constraints and $\boldsymbol{x}_i$ are independent (i.e. pick a random $\boldsymbol{w}$, sort $\boldsymbol{x}_i \boldsymbol{w}$ and then set $b_j$’s as values in between). Then $\mathbf{M}_\text{ReLU}$ becomes a lower triangular matrix:

$$
\mathbf{M}_\text{ReLU} = [a_i - b_j]_{i \times j}
= \begin{bmatrix}
a_1 - b_1 & 0        & 0  & \dots & 0 \\
\vdots &  \ddots  & &  & \vdots \\
a_i - b_1 & \dots & a_i - b_i & \dots & 0\\
\vdots &    & & \ddots & \vdots \\
a_n - b_1 & a_n - b_2 & \dots & \dots & a_n - b_n \\
\end{bmatrix}
$$

它是一个非奇异方阵，如 $\det(\mathbf{M}_\text{ReLU}) \neq 0$，所以我们总能找到合适的 $\boldsymbol{v}$ 来求解 $\boldsymbol{v}\mathbf{M}_\text{ReLU}=\boldsymbol{y}$ (换句话说，$\mathbf{M}_\text{ReLU}$ 的列空间是 $\mathbb{R}^n$ 的全部，我们可以找到列向量的线性组合来获得任何 $\boldsymbol{y}$)。

> It is a nonsingular square matrix as $\det(\mathbf{M}_\text{ReLU}) \neq 0$, so we can always find suitable $\boldsymbol{v}$ to solve $\boldsymbol{v}\mathbf{M}_\text{ReLU}=\boldsymbol{y}$ (In other words, the column space of $\mathbf{M}_\text{ReLU}$ is all of $\mathbb{R}^n$ and we can find a linear combination of column vectors to obtain any $\boldsymbol{y}$).

#### 深度神经网络可以学习随机噪声

> Deep NN can Learn Random Noise

众所周知，两层神经网络是通用逼近器，因此它们能够完美学习非结构化随机噪声，这并不令人惊讶，如[Zhang, et al. (2017)](https://arxiv.org/abs/1611.03530)所示。如果图像分类数据集的标签被随机打乱，深度神经网络的高表达能力仍然可以使它们实现接近零的训练损失。这些结果不会因添加正则化项而改变。

> As we know two-layer neural networks are universal approximators, it is less surprising to see that they are able to learn unstructured random noise perfectly, as shown in [Zhang, et al. (2017)](https://arxiv.org/abs/1611.03530). If labels of image classification dataset are randomly shuffled, the high expressivity power of deep neural networks can still empower them to achieve near-zero training loss. These results do not change with regularization terms added.

![Fit models on CIFAR10 with random labels or random pixels: (a) learning curves; (b-c) label corruption ratio is the percentage of randomly shuffled labels. (Image source: Zhang et al. 2017 )](https://lilianweng.github.io/posts/2019-03-14-overfit/fit-random-labels.png)

### 深度学习模型是否严重过拟合？

> Are Deep Learning Models Dramatically Overfitted?

深度学习模型参数量巨大，并且通常可以在训练数据上获得完美结果。在传统观点中，例如偏差-方差权衡，这可能是一场灾难，因为没有任何东西可以泛化到未见的测试数据。然而，通常情况下，这种“过拟合”（训练误差 = 0）的深度学习模型在样本外测试数据上仍然表现出不错的性能。嗯……这很有趣，为什么呢？

> Deep learning models are heavily over-parameterized and can often get to perfect results on training data. In the traditional view, like bias-variance trade-offs, this could be a disaster that nothing may generalize to the unseen test data. However, as is often the case, such “overfitted” (training error = 0) deep learning models still present a decent performance on out-of-sample test data. Hmm … interesting and why?

#### 深度学习的现代风险曲线

> Modern Risk Curve for Deep Learning

传统的机器学习使用以下U形风险曲线来衡量偏差-方差权衡，并量化模型的泛化能力。如果有人问我如何判断模型是否过拟合，这会是我首先想到的。

> The traditional machine learning uses the following U-shape risk curve to measure the bias-variance trade-offs and quantify how generalizable a model is. If I get asked how to tell whether a model is overfitted, this would be the first thing popping into my mind.

随着模型变大（添加更多参数），训练误差会下降到接近零，但一旦模型复杂度增长超过“欠拟合”和“过拟合”之间的阈值，测试误差（泛化误差）就开始增加。从某种程度上说，这与奥卡姆剃刀原理非常吻合。

> As the model turns larger (more parameters added), the training error decreases to close to zero, but the test error (generalization error) starts to increase once the model complexity grows to pass the threshold between “underfitting” and “overfitting”.  In a way, this is well aligned with Occam’s Razor.

![U-shaped bias-variance risk curve. (Image source: (left) paper (right) fig. 6 of this post )](https://lilianweng.github.io/posts/2019-03-14-overfit/bias-variance-risk-curve.png)

不幸的是，这不适用于深度学习模型。[Belkin 等人 (2018)](https://arxiv.org/abs/1812.11118) 调和了传统的偏差-方差权衡，并为深度神经网络提出了一种新的双U形风险曲线。一旦网络参数数量足够高，风险曲线就会进入另一个阶段。

> Unfortunately this does not apply to deep learning models. [Belkin et al. (2018)](https://arxiv.org/abs/1812.11118) reconciled the traditional bias-variance trade-offs and proposed a new double-U-shaped risk curve for deep neural networks. Once the number of network parameters is high enough, the risk curve enters another regime.

![A new double-U-shaped bias-variance risk curve for deep neural networks. (Image source: original paper )](https://lilianweng.github.io/posts/2019-03-14-overfit/new-bias-variance-risk-curve.png)

该论文声称这可能有两个原因：

> The paper claimed that it is likely due to two reasons:

- 参数数量并非衡量*归纳偏置*的良好指标，归纳偏置被定义为学习算法用于预测未知样本的一组假设。关于深度学习模型复杂度的更多讨论，请参见[后续](https://lilianweng.github.io/posts/2019-03-14-overfit/#intrinsic-dimension)[章节](https://lilianweng.github.io/posts/2019-03-14-overfit/#heterogeneous-layer-robustness)。
- 配备更大的模型，我们可能能够发现更大的函数类别，并进一步找到具有更小范数且因此“更简单”的插值函数。

> • The number of parameters is not a good measure of *inductive bias*, defined as the set of assumptions of a learning algorithm used to predict for unknown samples. See more discussion on DL model complexity in [later](https://lilianweng.github.io/posts/2019-03-14-overfit/#intrinsic-dimension) [sections](https://lilianweng.github.io/posts/2019-03-14-overfit/#heterogeneous-layer-robustness).
> • Equipped with a larger model, we might be able to discover larger function classes and further find interpolating functions that have smaller norm and are thus “simpler”.

正如论文所示，双U形风险曲线是经验观察到的。然而，我在重现这些结果时遇到了相当大的困难。虽然有一些进展，但为了生成一条与定理相似的漂亮平滑曲线，实验中的[许多细节](https://lilianweng.github.io/posts/2019-03-14-overfit/#experiments)都必须仔细处理。

> The double-U-shaped risk curve was observed empirically, as shown in the paper. However I was struggling quite a bit to reproduce the results. There are some signs of life, but in order to generate a pretty smooth curve similar to the theorem, [many details](https://lilianweng.github.io/posts/2019-03-14-overfit/#experiments) in the experiment have to be taken care of.

![Training and evaluation errors of a one hidden layer fc network of different numbers of hidden units, trained on 4000 data points sampled from MNIST. (Image source: original paper )](https://lilianweng.github.io/posts/2019-03-14-overfit/new-risk-curve-mnist.png)

#### 正则化并非泛化的关键

> Regularization is not the Key to Generalization

正则化是控制过拟合和提高模型泛化性能的常用方法。有趣的是，一些研究（[Zhang 等人 2017](https://arxiv.org/abs/1611.03530)）表明，显式正则化（即数据增强、权重衰减和 dropout）对于减少泛化误差既非必要也非充分条件。

> Regularization is a common way to control overfitting and improve model generalization performance. Interestingly some research ([Zhang, et al. 2017](https://arxiv.org/abs/1611.03530)) has shown that explicit regularization (i.e. data augmentation, weight decay and dropout) is neither necessary or sufficient for reducing generalization error.

以在 CIFAR10 上训练的 Inception 模型为例（参见图 5），正则化技术有助于样本外泛化，但效果不大。没有单一的正则化似乎独立于其他项而至关重要。因此，正则化器不太可能是泛化的*根本原因*。

> Taking the Inception model trained on CIFAR10 as an example (see Fig. 5), regularization techniques help with out-of-sample generalization but not much. No single regularization seems to be critical independent of other terms. Thus, it is unlikely that regularizers are the *fundamental reason* for generalization.

![The accuracy of Inception model trained on CIFAR10 with different combinations of taking on or off data augmentation and weight decay. (Image source: Table 1 in the original paper )](https://lilianweng.github.io/posts/2019-03-14-overfit/regularization-generalization-test.png)

#### 内在维度

> Intrinsic Dimension

在深度学习领域，参数数量与模型过拟合无关，这表明参数计数不能指示深度神经网络的真实复杂性。

> The number of parameters is not correlated with model overfitting in the field of deep learning, suggesting that parameter counting cannot indicate the true complexity of deep neural networks.

除了参数计数之外，研究人员还提出了许多量化这些模型复杂性的方法，例如模型的自由度数量（[Gao & Jojic, 2016](https://arxiv.org/abs/1603.09260)），或预编码（[Blier & Ollivier, 2018](https://arxiv.org/abs/1802.07044)）。

> Apart from parameter counting, researchers have proposed many ways to quantify the complexity of these models, such as the number of degrees of freedom of models ([Gao & Jojic, 2016](https://arxiv.org/abs/1603.09260)), or prequential code ([Blier & Ollivier, 2018](https://arxiv.org/abs/1802.07044)).

我想讨论一个关于此问题的最新方法，名为**内在维度**（[Li et al, 2018](https://arxiv.org/abs/1804.08838)）。内在维度直观、易于测量，同时仍能揭示不同大小模型的许多有趣特性。

> I would like to discuss a recent method on this matter, named **intrinsic dimension** ([Li et al, 2018](https://arxiv.org/abs/1804.08838)). Intrinsic dimension is intuitive, easy to measure, while still revealing many interesting properties of models of different sizes.

考虑一个拥有大量参数的神经网络，形成一个高维参数空间，学习发生在这个高维的*目标景观*上。参数空间流形的形状至关重要。例如，更平滑的流形通过提供更具预测性的梯度并允许更大的学习率而有利于优化——这被认为是批归一化成功稳定训练的原因（[Santurkar, et al, 2019](https://arxiv.org/abs/1805.11604)）。

> Considering a neural network with a great number of parameters, forming a high-dimensional parameter space,  the learning happens on this high-dimensional *objective landscape*.
> The shape of the parameter space manifold is critical. For example, a smoother manifold is beneficial for optimization by providing more predictive gradients and allowing for larger learning rates—this was claimed to be the reason why batch normalization has succeeded in stabilizing training ([Santurkar, et al, 2019](https://arxiv.org/abs/1805.11604)).

尽管参数空间巨大，但幸运的是，我们不必过于担心优化过程陷入局部最优，因为已经[表明](https://arxiv.org/abs/1406.2572)目标景观中的局部最优点几乎总是位于鞍点而非谷底。换句话说，总存在一个维度子集，其中包含离开局部最优并继续探索的路径。

> Even though the parameter space is huge, fortunately we don’t have to worry too much about the optimization process getting stuck in local optima, as it has been [shown](https://arxiv.org/abs/1406.2572) that local optimal points in the objective landscape almost always lay in saddle-points rather than valleys. In other words, there is always a subset of dimensions containing paths to leave local optima and keep on exploring.

![Illustrations of various types of critical points on the parameter optimization landscape. (Image source: here )](https://lilianweng.github.io/posts/2019-03-14-overfit/optimization-landscape-shape.png)

内在维度测量背后的一种直觉是，由于参数空间具有如此高的维度，因此可能不需要利用所有维度来高效学习。如果我们只遍历目标景观的一个切片，仍然可以学到一个好的解决方案，那么所得模型的复杂性可能低于通过参数计数所显示的。这本质上就是内在维度试图评估的内容。

> One intuition behind the measurement of intrinsic dimension is that, since the parameter space has such high dimensionality, it is probably not necessary to exploit all the dimensions to learn efficiently. If we only travel through a slice of objective landscape and still can learn a good solution, the complexity of the resulting model is likely lower than what it appears to be by parameter-counting. This is essentially what intrinsic dimension tries to assess.

假设一个模型有$D$个维度，其参数表示为$\theta^{(D)}$。为了学习，随机采样一个较小的$d$维子空间，$\theta^{(d)}$，其中$d < D$。在一次优化更新期间，不是根据所有$D$个维度进行梯度步长，而是只使用较小的子空间$\theta^{(d)}$并重新映射以更新模型参数。

> Say a model has $D$ dimensions and its parameters are denoted as $\theta^{(D)}$. For learning, a smaller $d$ -dimensional subspace is randomly sampled, $\theta^{(d)}$, where $d < D$. During one optimization update, rather than taking a gradient step according to all $D$ dimensions, only the smaller subspace $\theta^{(d)}$ is used and remapped to update model parameters.

![Illustration of parameter vectors for direct optimization when $D=3$. (Image source: original paper )](https://lilianweng.github.io/posts/2019-03-14-overfit/intrinsic-dimension-illustration.png)

梯度更新公式如下所示：

> The gradient update formula looks like the follows:

$$
\theta^{(D)} = \theta_0^{(D)} + \mathbf{P} \theta^{(d)}
$$

其中$\theta_0^{(D)}$是初始化值，$\mathbf{P}$是一个在训练前随机采样的$D \times d$投影矩阵。$\theta_0^{(D)}$和$\mathbf{P}$在训练期间均不可训练且固定。$\theta^{(d)}$初始化为全零。

> where $\theta_0^{(D)}$ are the initialization values and $\mathbf{P}$ is a $D \times d$ projection matrix that is randomly sampled before training. Both $\theta_0^{(D)}$ and $\mathbf{P}$ are not trainable and fixed during training. $\theta^{(d)}$ is initialized as all zeros.

通过搜索$d = 1, 2, \dots, D$的值，当解决方案出现时对应的$d$被定义为*内在维度*。

> By searching through the value of $d = 1, 2, \dots, D$, the corresponding $d$ when the solution emerges is defined as the *intrinsic dimension*.

事实证明，许多问题的内在维度远小于参数数量。例如，在CIFAR10图像分类中，一个拥有65万以上参数的全连接网络只有9千的内在维度，而一个包含6.2万参数的卷积网络则拥有更低的2.9千内在维度。

> It turns out many problems have much smaller intrinsic dimensions than the number of parameters. For example, on CIFAR10 image classification, a fully-connected network with 650k+ parameters has only 9k intrinsic dimension and a convolutional network containing 62k parameters has an even lower intrinsic dimension of 2.9k.

![The measured intrinsic dimensions $d$ for various models achieving 90% of the best performance. (Image source: original paper )](https://lilianweng.github.io/posts/2019-03-14-overfit/intrinsic-dimension.png)

内在维度的测量表明，深度学习模型比它们看起来要简单得多。

> The measurement of intrinsic dimensions suggests that deep learning models are significantly simpler than what they might appear to be.

#### 异构层鲁棒性

> Heterogeneous Layer Robustness

[Zhang 等人 (2019)](https://arxiv.org/abs/1902.01996) 研究了参数在不同层中的作用。该论文提出的根本问题是：*“所有层都是平等的吗？”* 简短的回答是：不是。模型对某些层的变化更敏感，而对其他层则不敏感。

> [Zhang et al. (2019)](https://arxiv.org/abs/1902.01996) investigated the role of parameters in different layers. The fundamental question raised by the paper is:  *“are all layers created equal?”* The short answer is: No. The model is more sensitive to changes in some layers but not others.

该论文提出了两种操作，可以应用于第 $\ell$ 层的参数 $\ell = 1, \dots, L$，在时间 $t$，$\theta^{(\ell)}_t$，以测试它们对模型鲁棒性的影响：

> The paper proposed two types of operations that can be applied to parameters of the $\ell$ -th layer, $\ell = 1, \dots, L$, at time $t$, $\theta^{(\ell)}_t$ to test their impacts on model robustness:

• 
**重新初始化**：将参数重置为初始值，$\theta^{(\ell)}_t \leftarrow \theta^{(\ell)}_0$。层 $\ell$ 被重新初始化的网络的性能被称为层 $\ell$ 的*重新初始化鲁棒性*。


• 
**重新随机化**：随机重新采样层的参数，$\theta^{(\ell)}_t \leftarrow \tilde{\theta}^{(\ell)} \sim \mathcal{P}^{(\ell)}$。相应的网络性能被称为层 $\ell$ 的*重新随机化鲁棒性*。


英文原文：

• 
**Re-initialization**: Reset the parameters to the initial values, $\theta^{(\ell)}_t \leftarrow \theta^{(\ell)}_0$. The performance of a network in which layer $\ell$ was re-initialized is referred to as the *re-initialization robustness* of layer $\ell$.


• 
**Re-randomization**: Re-sampling the layer’s parameters at random, $\theta^{(\ell)}_t \leftarrow \tilde{\theta}^{(\ell)} \sim \mathcal{P}^{(\ell)}$. The corresponding network performance is called the *re-randomization robustness* of layer $\ell$.


借助这两种操作，层可以分为两类：

> Layers can be categorized into two categories with the help of these two operations:

- **鲁棒层**：在重新初始化或重新随机化该层后，网络性能没有或只有可忽略的下降。
- **关键层**：反之。

> • **Robust Layers**: The network has no or only negligible performance degradation after re-initializing or re-randomizing the layer.
> • **Critical Layers**: Otherwise.

在全连接网络和卷积网络上观察到了类似的模式。重新随机化任何层都会*完全破坏*模型性能，因为预测会立即降至随机猜测水平。更有趣和令人惊讶的是，当应用重新初始化时，只有第一层或前几层（最接近输入层的那些层）是关键的，而重新初始化更高层只会导致性能*可忽略不计的下降*。

> Similar patterns are observed on fully-connected and convolutional networks. Re-randomizing any of the layers *completely destroys* the model performance, as the prediction drops to random guessing immediately. More interestingly and surprisingly, when applying re-initialization, only the first or the first few layers (those closest to the input layer) are critical, while re-initializing higher levels causes *only negligible decrease* in performance.

![(a) A fc network trained on MNIST. Each row corresponds to one layer in the network. The first column is re-randomization robustness of each layer and the rest of the columns indicate re-initialization robustness at different training time. (b) VGG11 model (conv net) trained on CIFAR 10. Similar representation as in (a) but rows and columns are transposed. (Image source: original paper )](https://lilianweng.github.io/posts/2019-03-14-overfit/layer-robustness-results.png)

ResNet 能够利用非相邻层之间的快捷连接，将敏感层重新分布到整个网络中，而不仅仅是在底部。借助残差块架构，网络可以*均匀地对重新随机化保持鲁棒性*。每个残差块中只有第一层仍然对重新初始化和重新随机化都敏感。如果我们将每个残差块视为一个局部子网络，那么其鲁棒性模式类似于上面提到的全连接网络和卷积网络。

> ResNet is able to use shortcuts between non-adjacent layers to re-distribute the sensitive layers across the networks rather than just at the bottom. With the help of residual block architecture, the network can *evenly be robust to re-randomization*. Only the first layer of each residual block is still sensitive to both re-initialization and re-randomization. If we consider each residual block as a local sub-network, the robustness pattern resembles the fc and conv nets above.

![Re-randomization (first row) and re-initialization (the reset rows) robustness of layers in ResNet-50 model trained on CIFAR10. (Image source: original paper )](https://lilianweng.github.io/posts/2019-03-14-overfit/layer-robustness-resnet.png)

基于深度神经网络中许多顶层在重新初始化后对模型性能不关键这一事实，该论文大致得出结论：

> Based on the fact that many top layers in deep neural networks are not critical to the model performance after re-initialization, the paper loosely concluded that:

> “使用随机梯度训练的过容量深度网络由于自我限制关键层的数量而具有低复杂度。”

> “Over-capacitated deep networks trained with stochastic gradient have low-complexity due to self-restricting the number of critical layers.”

我们可以将重新初始化视为减少有效参数数量的一种方式，因此这一观察结果与内在维度所展示的一致。

> We can consider re-initialization as a way to reduce the effective number of parameters, and thus the observation is aligned with what intrinsic dimension has demonstrated.

#### 乐透彩票假说

> The Lottery Ticket Hypothesis

乐透彩票假说（[Frankle & Carbin, 2019](https://arxiv.org/abs/1803.03635)）是另一个引人入胜且富有启发性的发现，它支持只有一部分网络参数对模型性能有影响，因此网络没有过拟合。乐透彩票假说指出，一个随机初始化、密集、前馈网络包含一个子网络池，其中只有一部分是*“中奖彩票”*，它们在*单独训练*时可以达到最佳性能。

> The lottery ticket hypothesis ([Frankle & Carbin, 2019](https://arxiv.org/abs/1803.03635)) is another intriguing and inspiring discovery, supporting that only a subset of network parameters have impact on the model performance and thus the network is not overfitted. The lottery ticket hypothesis states that a randomly initialized, dense, feed-forward network contains a pool of subnetworks and among them only a subset are *“winning tickets”* which can achieve the optimal performance when *trained in isolation*.

这个想法的灵感来源于网络剪枝技术——在不损害模型性能的情况下移除不必要的权重（即几乎可以忽略不计的微小权重）。尽管最终网络规模可以显著减小，但从头开始成功训练这种剪枝后的网络架构却很困难。这感觉就像为了成功训练一个神经网络，我们需要大量的参数，但一旦模型训练完成，我们就不需要那么多参数来保持高准确率。这是为什么呢？

> The idea is motivated by network pruning techniques — removing unnecessary weights (i.e. tiny weights that are almost negligible) without harming the model performance. Although the final network size can be reduced dramatically, it is hard to train such a pruned network architecture successfully from scratch. It feels like in order to successfully train a neural network, we need a large number of parameters, but we don’t need that many parameters to keep the accuracy high once the model is trained. Why is that?

乐透彩票假说进行了以下实验：

> The lottery ticket hypothesis did the following experiments:

1\. 使用初始化值 $\theta_0$ 随机初始化一个密集前馈网络；

2\. 使用参数配置 $\theta$ 训练网络多次迭代以获得良好性能；

3\. 对 $\theta$ 进行剪枝并创建掩码 $m$。

4\. “中奖彩票”初始化配置是 $m \odot \theta_0$。

英文原文：

1\. Randomly initialize a dense feed-forward network with initialization values $\theta_0$;

2\. Train the network for multiple iterations to achieve a good performance with parameter config $\theta$;

3\. Run pruning on $\theta$ and creating a mask $m$.

4\. The “winning ticket” initialization config is $m \odot \theta_0$.

仅使用在步骤1中找到的初始值训练“中奖彩票”参数的小子集，模型就能够达到与步骤2相同的准确率水平。结果表明，最终的解决方案表示不需要大的参数空间，但在训练时需要，因为它提供了许多小得多的子网络的初始化配置的大型池。

> Only training the small “winning ticket” subset of parameters with the initial values as found in step 1, the model is able to achieve the same level of accuracy as in step 2. It turns out a large parameter space is not needed in the final solution representation, but needed for training as it provides a big pool of initialization configs of many much smaller subnetworks.

乐透彩票假说为解释和剖析深度神经网络结果开辟了新视角。许多有趣的后续工作正在进行中。

> The lottery ticket hypothesis opens a new perspective about interpreting and dissecting deep neural network results. Many interesting following-up works are on the way.

### 实验

> Experiments

在看到以上所有有趣的发现后，重现它们应该会很有趣。有些结果比其他结果更容易重现。详细信息如下所述。我的代码可在 GitHub [lilianweng/generalization-experiment](https://github.com/lilianweng/generalization-experiment) 上获取。

> After seeing all the interesting findings above, it should be pretty fun to reproduce them. Some results are easily to reproduce than others. Details are described below. My code is available on github [lilianweng/generalization-experiment](https://github.com/lilianweng/generalization-experiment).

**深度学习模型的新风险曲线**

> **New Risk Curve for DL Models**

这是最难重现的一个。作者确实给了我很多很好的建议，我非常感谢。以下是他们实验中几个值得注意的设置：

> This is the trickiest one to reproduce. The authors did give me a lot of good advice and I appreciate it a lot. Here are a couple of noticeable settings in their experiments:

- 没有权重衰减、dropout 等正则化项。
- 在图3中，训练集包含4k个样本。它只采样一次，并对所有模型固定。评估使用完整的MNIST测试集。
- 每个网络都经过长时间训练以达到接近零的训练风险。学习率针对不同大小的模型进行了不同的调整。
- 为了使模型在欠参数化区域对初始化不那么敏感，他们的实验采用了*“权重复用”*方案：从训练较小神经网络获得的参数被用作训练较大网络的初始化。

> • There are no regularization terms like weight decay, dropout.
> • In Fig 3, the training set contains 4k samples. It is only sampled once and fixed for all the models. The evaluation uses the full MNIST test set.
> • Each network is trained for a long time to achieve near-zero training risk. The learning rate is adjusted differently for models of different sizes.
> • To make the model less sensitive to the initialization in the under-parameterization region, their experiments adopted a *“weight reuse”* scheme: the parameters obtained from training a smaller neural network are used as initialization for training larger networks.

我没有对每个模型进行足够长时间的训练或调优以获得完美的训练性能，但评估误差确实在插值阈值附近显示出一种特殊的转折，这与训练误差不同。例如，对于MNIST，阈值是训练样本数乘以类别数（10），即40000。

> I did not train or tune each model long enough to get perfect training performance, but evaluation error indeed shows a special twist around the interpolation threshold, different from training error. For example, for MNIST, the threshold is the number of training samples times the number of classes (10), that is 40000.

x轴是模型参数的数量：(28 * 28 + 1) * 单元数 + 单元数 * 10，以对数表示。

> The x-axis is the number of model parameters: (28 * 28 + 1) * num. units + num. units * 10, in logarithm.

![](https://lilianweng.github.io/posts/2019-03-14-overfit/risk_curve_loss-mse_sample-4000_epoch-500.png)

**层并非生而平等**

> **Layers are not Created Equal**

这一项相当容易重现。请参阅我的实现[此处](https://github.com/lilianweng/generalization-experiment/blob/master/layer_equality.py)。

> This one is fairly easy to reproduce. See my implementation [here](https://github.com/lilianweng/generalization-experiment/blob/master/layer_equality.py).

在第一个实验中，我使用了三层全连接网络，每层有256个单元。第0层是输入层，而第3层是输出层。该网络在MNIST上训练了100个epoch。

> In the first experiment, I used a three-layer fc networks with 256 units in each layer. Layer 0 is the input layer while layer 3 is the output. The network is trained on MNIST for 100 epochs.

![](https://lilianweng.github.io/posts/2019-03-14-overfit/layer_equality_256x3.png)

在第二个实验中，我使用了四层全连接网络，每层有128个单元。其他设置与实验1相同。

> In the second experiment, I used a four-layer fc networks with 128 units in each layer. Other settings are the same as experiment 1.

![](https://lilianweng.github.io/posts/2019-03-14-overfit/layer_equality_128x4.png)

**内在维度测量**

> **Intrinsic Dimension Measurement**

为了正确地将 $d$ 维子空间映射到完整的参数空间，投影矩阵 $\mathbf{P}$ 应该具有正交列。因为乘积 $\mathbf{P}\theta^{(d)}$ 是 $\mathbf{P}$ 的列乘以 $d$ 维向量 $\sum_{i=1}^d \theta^{(d)}_i \mathbf{P}^\top_{(:,i)}$ 中相应标量值的和，所以最好充分利用 $\mathbf{P}$ 中具有正交列的子空间。

> To correctly map the $d$ -dimensional subspace to the full parameter space, the projection matrix $\mathbf{P}$ should have orthogonal columns. Because the production $\mathbf{P}\theta^{(d)}$ is the sum of columns of $\mathbf{P}$ scaled by corresponding scalar values in the $d$ -dim vector, $\sum_{i=1}^d \theta^{(d)}_i \mathbf{P}^\top_{(:,i)}$, it is better to fully utilize the subspace with orthogonal columns in $\mathbf{P}$.

我的实现采用了一种朴素的方法，即从标准正态分布中采样一个具有独立条目的大矩阵。在高维空间中，列预计是独立的，因此是正交的。当维度不是太大时，这种方法有效。当使用大的 $d$ 进行探索时，存在创建稀疏投影矩阵的方法，这正是内在维度论文所建议的。

> My implementation follows a naive approach by sampling a large matrix with independent entries from a standard normal distribution. The columns are expected to be independent in a high dimension space and thus to be orthogonal. This works when the dimension is not too large. When exploring with a large $d$, there are methods for creating sparse projection matrices, which is what the intrinsic dimension paper suggested.

以下是在两个网络上进行的实验运行：（左）一个两层全连接网络，每层有64个单元；（右）一个一层全连接网络，有128个隐藏单元，在10%的MNIST数据集上训练。对于每个 $d$，模型训练100个epoch。请参阅[代码](https://github.com/lilianweng/generalization-experiment/blob/master/intrinsic_dimensions.py)[此处](https://github.com/lilianweng/generalization-experiment/blob/master/intrinsic_dimensions_measurement.py)。

> Here are experiment runs on two networks: (left) a two-layer fc network with 64 units in each layer and (right) a one-layer fc network with 128 hidden units, trained on 10% of MNIST. For every $d$, the model is trained for 100 epochs. See the [code](https://github.com/lilianweng/generalization-experiment/blob/master/intrinsic_dimensions.py) [here](https://github.com/lilianweng/generalization-experiment/blob/master/intrinsic_dimensions_measurement.py).

![](https://lilianweng.github.io/posts/2019-03-14-overfit/intrinsic-dimension-net-64-64-and-128.png)

引用方式：

> Cited as:

```
@article{weng2019overfit,
  title   = "Are Deep Neural Networks Dramatically Overfitted?",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2019",
  url     = "https://lilianweng.github.io/posts/2019-03-14-overfit/"
}
```

### 参考文献

> References

[1] 维基百科关于[奥卡姆剃刀](https://en.wikipedia.org/wiki/Occam%27s_razor)的页面。

> [1] Wikipedia page on [Occam’s Razor](https://en.wikipedia.org/wiki/Occam%27s_razor).

[2] Principia Cybernetica Web 上的[奥卡姆剃刀](http://pespmc1.vub.ac.be/OCCAMRAZ.html)。

> [2] [Occam’s Razor](http://pespmc1.vub.ac.be/OCCAMRAZ.html) on Principia Cybernetica Web.

[3] Peter Grunwald. [“最小描述长度原理的教程介绍”](https://arxiv.org/abs/math/0406077). 2004。

> [3] Peter Grunwald. [“A Tutorial Introduction to the Minimum Description Length Principle”](https://arxiv.org/abs/math/0406077). 2004.

[4] Ian Goodfellow, 等. [深度学习](https://www.deeplearningbook.org/). 2016. [第6.4.1节](https://www.deeplearningbook.org/contents/mlp.html)。

> [4] Ian Goodfellow, et al. [Deep Learning](https://www.deeplearningbook.org/). 2016. [Sec 6.4.1](https://www.deeplearningbook.org/contents/mlp.html).

[5] Zhang, Chiyuan, 等. [“理解深度学习需要重新思考泛化。”](https://arxiv.org/abs/1611.03530) ICLR 2017。

> [5] Zhang, Chiyuan, et al. [“Understanding deep learning requires rethinking generalization.”](https://arxiv.org/abs/1611.03530) ICLR 2017.

[6] Shibani Santurkar, 等. [“批量归一化如何帮助优化？”](https://arxiv.org/abs/1805.11604) NIPS 2018。

> [6] Shibani Santurkar, et al. [“How does batch normalization help optimization?.”](https://arxiv.org/abs/1805.11604) NIPS 2018.

[7] Mikhail Belkin, 等. [“调和现代机器学习与偏差-方差权衡。”](https://arxiv.org/abs/1812.11118) arXiv:1812.11118, 2018。

> [7] Mikhail Belkin, et al. [“Reconciling modern machine learning and the bias-variance trade-off.”](https://arxiv.org/abs/1812.11118) arXiv:1812.11118, 2018.

[8] Chiyuan Zhang, 等. [“所有层都生而平等吗？”](https://arxiv.org/abs/1902.01996) arXiv:1902.01996, 2019。

> [8] Chiyuan Zhang, et al. [“Are All Layers Created Equal?”](https://arxiv.org/abs/1902.01996) arXiv:1902.01996, 2019.

[9] Chunyuan Li, 等. [“测量目标景观的内在维度。”](https://arxiv.org/abs/1804.08838) ICLR 2018。

> [9] Chunyuan Li, et al. [“Measuring the intrinsic dimension of objective landscapes.”](https://arxiv.org/abs/1804.08838) ICLR 2018.

[10] Jonathan Frankle 和 Michael Carbin. [“乐透彩票假说：寻找稀疏、可训练的神经网络。”](https://arxiv.org/abs/1803.03635) ICLR 2019。

> [10]  Jonathan Frankle and Michael Carbin. [“The lottery ticket hypothesis: Finding sparse, trainable neural networks.”](https://arxiv.org/abs/1803.03635) ICLR 2019.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Overfitting | 过拟合 | 模型在训练数据上表现良好，但在未见过的新数据上表现差的现象。 |
| Generalization | 泛化 | 模型在未见过的新数据上表现良好的能力。 |
| Occam's Razor | 奥卡姆剃刀 | 一个非正式原则，主张在多种解释中选择最简单的那个。 |
| Minimum Description Length (MDL) | 最小描述长度原理 | 一种模型选择原则，认为最佳模型是编码数据和模型本身总长度最小的那个。 |
| Kolmogorov Complexity | 柯尔莫哥洛夫复杂度 | 描述一个对象所需的最短二进制计算机程序的长度。 |
| Universal Approximation Theorem | 万能近似定理 | 指出具有至少一个隐藏层的神经网络能够以任意精度近似任何连续函数。 |
| Bias-variance tradeoff | 偏差-方差权衡 | 传统机器学习中，模型复杂度增加会导致偏差降低但方差增加的现象。 |
| Intrinsic Dimension | 内在维度 | 衡量模型在有效学习时实际利用的参数子空间的维度，通常远小于总参数量。 |
| Heterogeneous Layer Robustness | 异构层鲁棒性 | 深度神经网络中不同层对模型性能影响的敏感度不同，通常只有少数层是关键的。 |
| Lottery Ticket Hypothesis | 乐透彩票假说 | 认为随机初始化的密集网络中包含稀疏子网络（“中奖彩票”），单独训练即可达到与原网络相当的性能。 |
| Regularization | 正则化 | 用于控制模型过拟合、提高泛化性能的方法，如权重衰减和Dropout。 |
| ReLU activation function | ReLU激活函数 | 一种常用的激活函数，定义为f(x) = max(0, x)。 |
