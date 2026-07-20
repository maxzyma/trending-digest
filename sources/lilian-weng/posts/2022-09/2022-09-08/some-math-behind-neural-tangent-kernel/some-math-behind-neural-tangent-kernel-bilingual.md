# 神经正切核背后的数学

> Some Math behind Neural Tangent Kernel

> 来源：Lil'Log / Lilian Weng，2022-09-08
> 原文链接：https://lilianweng.github.io/posts/2022-09-08-ntk/
> 分类：机器学习 / 神经正切核

## 核心要点

- 神经正切核（NTK）是一种用于解释神经网络在梯度下降训练期间演变的核心概念。
- NTK为具有足够宽度的神经网络在训练时为何能持续收敛到全局最小值提供了深刻见解。
- 本文深入探讨了NTK的动机、定义及其背后的数学原理，以证明无限宽度神经网络的确定性收敛。
- 无限宽度神经网络的输出函数与高斯过程有深刻联系，其输出可被建模为具有特定协方差的独立同分布中心高斯过程。
- 当网络宽度趋于无限时，神经正切核在初始化时是确定性的（仅由模型架构决定），并且在训练期间保持不变。
- 无限宽度的神经网络的学习动力学可以被简化为线性化模型，其演变由一个简单的线性常微分方程支配。
- 在严重过参数化的神经网络中，存在“惰性训练”现象，即训练损失迅速收敛到零，但网络参数变化极小。
- 惰性训练现象表明，当隐藏层神经元数量趋于无限时，网络微分相对于参数空间变化的相对变化趋于零。

## 正文

神经网络[众所周知](https://lilianweng.github.io/posts/2019-03-14-overfit/)是过参数化的，并且通常可以轻松地以接近零的训练损失拟合数据，同时在测试数据集上具有良好的泛化性能。尽管所有这些参数都是随机初始化的，但优化过程可以始终如一地带来相似的良好结果。即使模型参数的数量超过训练数据点的数量，情况也是如此。

> Neural networks are [well known](https://lilianweng.github.io/posts/2019-03-14-overfit/) to be over-parameterized and can often easily fit data with near-zero training loss with decent generalization performance on test dataset. Although all these parameters are initialized at random, the optimization process can consistently lead to similarly good outcomes. And this is true even when the number of model parameters exceeds the number of training data points.

**神经正切核 (NTK)** ([Jacot et al. 2018](https://arxiv.org/abs/1806.07572)) 是一种核，用于解释神经网络在通过梯度下降训练期间的演变。它为具有足够宽度的神经网络在训练以最小化经验损失时为何能持续收敛到全局最小值提供了深刻见解。在这篇文章中，我们将深入探讨 NTK 的动机和定义，以及通过在这种设置下表征 NTK 来证明无限宽度神经网络在不同初始化下的确定性收敛。

> **Neural tangent kernel (NTK)** ([Jacot et al. 2018](https://arxiv.org/abs/1806.07572)) is a kernel to explain the evolution of neural networks during training via gradient descent. It leads to great insights into why neural networks with enough width can consistently converge to a global minimum when trained to minimize an empirical loss. In the post, we will do a deep dive into the motivation and definition of NTK, as well as the proof of a deterministic convergence at different initializations of neural networks with infinite width by characterizing NTK in such a setting.

> 🤓 与我之前的文章不同，本文主要关注少数核心论文，较少涉及该领域的文献综述广度。NTK 之后有许多有趣的工作，通过修改或扩展理论来理解神经网络的学习动态，但本文不会涵盖这些内容。目标是以清晰易懂的格式展示 NTK 背后的所有数学原理，因此本文数学内容较多。如果您发现任何错误，请告诉我，我将很乐意迅速纠正。提前感谢！

> 🤓 Different from my previous posts, this one mainly focuses on a small number of core papers, less on the breadth of the literature review in the field. There are many interesting works after NTK, with modification or expansion of the theory for understanding the learning dynamics of NNs, but they won’t be covered here. The goal is to show all the math behind NTK in a clear and easy-to-follow format, so the post is quite math-intensive. If you notice any mistakes, please let me know and I will be happy to correct them quickly. Thanks in advance!

### 基础知识

> Basics

本节包含对理解神经正切核至关重要的几个非常基本概念的回顾。可随意跳过。

> This section contains reviews of several very basic concepts which are core to understanding of neural tangent kernel. Feel free to skip.

#### 向量对向量的导数

> Vector-to-vector Derivative

给定一个输入向量$\mathbf{x} \in \mathbb{R}^n$（作为列向量）和一个函数$f: \mathbb{R}^n \to \mathbb{R}^m$，$f$关于$\mathbf{x}$的导数是一个$m\times n$矩阵，也称为[雅可比矩阵](https://en.wikipedia.org/wiki/Jacobian_matrix_and_determinant)：

> Given an input vector $\mathbf{x} \in \mathbb{R}^n$ (as a column vector) and a function $f: \mathbb{R}^n \to \mathbb{R}^m$, the derivative of $f$ with respective to $\mathbf{x}$ is a $m\times n$ matrix, also known as [Jacobian matrix](https://en.wikipedia.org/wiki/Jacobian_matrix_and_determinant):

$$
J
= \frac{\partial f}{\partial \mathbf{x}}
= \begin{bmatrix}
\frac{\partial f_1}{\partial x_1} & \dots &\frac{\partial f_1}{\partial x_n} \\
\vdots & & \\
\frac{\partial f_m}{\partial x_1} & \dots &\frac{\partial f_m}{\partial x_n} \\
\end{bmatrix}
\in \mathbb{R}^{m \times n}
$$

在本文中，我使用整数下标来指代向量或矩阵值中的单个条目；即$x_i$表示$i$个向量中的值$\mathbf{x}$并且$f_i(.)$是$i$个函数输出中的条目。

> Throughout the post, I use integer subscript(s) to refer to a single entry out of a vector or matrix value; i.e. $x_i$ indicates the $i$ -th value in the vector $\mathbf{x}$ and $f_i(.)$ is the $i$ -th entry in the output of the function.

向量对向量的梯度定义为 $\nabla_\mathbf{x} f = J^\top \in \mathbb{R}^{n \times m}$，当 $m=1$（即标量输出）时，这种形式也有效。

> The gradient of a vector with respect to a vector is defined as $\nabla_\mathbf{x} f = J^\top \in \mathbb{R}^{n \times m}$ and this formation is also valid when $m=1$ (i.e., scalar output).

#### 微分方程

> Differential Equations

微分方程描述了一个或多个函数及其导数之间的关系。微分方程主要有两种类型。

> Differential equations describe the relationship between one or multiple functions and their derivatives. There are two main types of differential equations.

• (1) *常微分方程 (Ordinary differential equation)* 只包含一个随机变量的未知函数。常微分方程是本文中使用的主要微分方程形式。常微分方程的一般形式如 $(x, y, \frac{dy}{dx}, \dots, \frac{d^ny}{dx^n}) = 0$ 所示。

• (2) *偏微分方程 (Partial differential equation)* 包含未知多变量函数及其偏导数。

英文原文：

• (1) *ODE (Ordinary differential equation)* contains only an unknown function of one random variable. ODEs are the main form of differential equations used in this post. A general form of ODE looks like $(x, y, \frac{dy}{dx}, \dots, \frac{d^ny}{dx^n}) = 0$.

• (2) *PDE (Partial differential equation)* contains unknown multivariable functions and their partial derivatives.

让我们回顾一下最简单的微分方程及其解。*变量分离* (傅里叶方法) 当包含一个变量的所有项可以移到一边，而其他项都移到另一边时，可以使用此方法。例如，

> Let’s review the simplest case of differential equations and its solution. *Separation of variables* (Fourier method) can be used when all the terms containing one variable can be moved to one side, while the other terms are all moved to the other side. For example,

$$
\begin{aligned}
\text{Given }a\text{ is a constant scalar:}\quad\frac{dy}{dx} &= ay \\
\text{Move same variables to the same side:}\quad\frac{dy}{y} &= adx \\
\text{Put integral on both sides:}\quad\int \frac{dy}{y} &= \int adx \\
\ln (y) &= ax + C' \\
\text{Finally}\quad y &= e^{ax + C'} = C e^{ax}
\end{aligned}
$$

#### 中心极限定理

> Central Limit Theorem

给定一组独立同分布的随机变量，$x_1, \dots, x_N$，其均值为 $\mu$，方差为 $\sigma^2$，*中心极限定理 (CTL)* 指出，当 $N$ 变得非常大时，期望将呈高斯分布。

> Given a collection of i.i.d. random variables, $x_1, \dots, x_N$ with mean $\mu$ and variance $\sigma^2$, the *Central Limit Theorem (CTL)* states that the expectation would be Gaussian distributed when $N$ becomes really large.

$$
\bar{x} = \frac{1}{N}\sum_{i=1}^N x_i \sim \mathcal{N}(\mu, \frac{\sigma^2}{n})\quad\text{when }N \to \infty
$$

中心极限定理 (CTL) 也可以应用于多维向量，此时我们不再计算单个标量 $\sigma^2$，而是需要计算随机变量 $\Sigma$ 的协方差矩阵。

> CTL can also apply to multidimensional vectors, and then instead of a single scale $\sigma^2$ we need to compute the covariance matrix of random variable $\Sigma$.

#### 泰勒展开

> Taylor Expansion

[泰勒展开](https://en.wikipedia.org/wiki/Taylor_series)是将一个函数表示为无穷多个分量之和，其中每个分量都用该函数的导数来表示。函数 $f(x)$ 在 $x=a$ 处的泰勒展开可以写作：


$$
f(x) = f(a) + \sum_{k=1}^\infty \frac{1}{k!} (x - a)^k\nabla^k_xf(x)\vert_{x=a}
$$


其中 $\nabla^k$ 表示第 $k$ 阶导数。

> The [Taylor expansion](https://en.wikipedia.org/wiki/Taylor_series) is to express a function as an infinite sum of components, each represented in terms of this function’s derivatives. The Tayler expansion of a function $f(x)$ at $x=a$ can be written as:
>
>
> $$
> f(x) = f(a) + \sum_{k=1}^\infty \frac{1}{k!} (x - a)^k\nabla^k_xf(x)\vert_{x=a}
> $$
>
>
> where $\nabla^k$ denotes the $k$ -th derivative.

一阶泰勒展开常被用作函数值的线性近似：

> The first-order Taylor expansion is often used as a linear approximation of the function value:

$$
f(x) \approx f(a) + (x - a)\nabla_x f(x)\vert_{x=a}
$$

#### 核与核方法

> Kernel & Kernel Methods

[核](https://en.wikipedia.org/wiki/Kernel_method)本质上是两个数据点$K: \mathcal{X} \times \mathcal{X} \to \mathbb{R}$之间的相似性函数。它描述了一个数据样本的预测对另一个数据样本的预测有多敏感；换句话说，两个数据点有多相似。核应该是对称的，$K(x, x’) = K(x’, x)$。

> A [kernel](https://en.wikipedia.org/wiki/Kernel_method) is essentially a similarity function between two data points, $K: \mathcal{X} \times \mathcal{X} \to \mathbb{R}$. It describes how sensitive the prediction for one data sample is to the prediction for the other; or in other words, how similar two data points are. The kernel should be symmetric, $K(x, x’) = K(x’, x)$.

根据问题结构，一些核可以分解为两个特征映射，一个对应一个数据点，核值是这两个特征的内积：$K(x, x’) = \langle \varphi(x), \varphi(x’) \rangle$。

> Depending on the problem structure, some kernels can be decomposed into two feature maps, one corresponding to one data point, and the kernel value is an inner product of these two features: $K(x, x’) = \langle \varphi(x), \varphi(x’) \rangle$.

*核方法*是一种非参数的、基于实例的机器学习算法。假设我们已知所有训练样本$\{x^{(i)}, y^{(i)}\}$的标签，则新输入$x$的标签通过加权和$\sum_{i} K(x^{(i)}, x)y^{(i)}$进行预测。

> *Kernel methods* are a type of non-parametric, instance-based machine learning algorithms. Assuming we have known all the labels of training samples $\{x^{(i)}, y^{(i)}\}$, the label for a new input $x$ is predicted by a weighted sum $\sum_{i} K(x^{(i)}, x)y^{(i)}$.

#### 高斯过程

> Gaussian Processes

*高斯过程 (GP)* 是一种非参数方法，通过对一组随机变量建模多元高斯概率分布。GP 假设函数上的先验，然后基于观察到的数据点更新函数上的后验。

> *Gaussian process (GP)* is a non-parametric method by modeling a multivariate Gaussian probability distribution over a collection of random variables. GP assumes a prior over functions and then updates the posterior over functions based on what data points are observed.

给定一组数据点$\{x^{(1)}, \dots, x^{(N)}\}$，GP 假设它们遵循联合多元高斯分布，该分布由均值$\mu(x)$和协方差矩阵$\Sigma(x)$。协方差矩阵中位于$(i,j)$的每个条目$\Sigma(x)$由核函数$\Sigma_{i,j} = K(x^{(i)}, x^{(j)})$定义，也称为*协方差函数*。其核心思想是——如果两个数据点被核函数判定为相似，那么函数输出也应该接近。使用 GP 对未知数据点进行预测，相当于通过给定观测数据点的条件分布，从该分布中抽取样本。

> Given a collection of data points $\{x^{(1)}, \dots, x^{(N)}\}$, GP assumes that they follow a jointly multivariate Gaussian distribution, defined by a mean $\mu(x)$ and a covariance matrix $\Sigma(x)$. Each entry at location $(i,j)$ in the covariance matrix $\Sigma(x)$ is defined by a kernel $\Sigma_{i,j} = K(x^{(i)}, x^{(j)})$, also known as a *covariance function*. The core idea is – if two data points are deemed similar by the kernel, the function outputs should be close, too. Making predictions with GP for unknown data points is equivalent to drawing samples from this distribution, via a conditional distribution of unknown data points given observed ones.

查看 [这篇文章](https://distill.pub/2019/visual-exploration-gaussian-processes/) 以获取关于高斯过程是什么的高质量、高可视化教程。

> Check [this post](https://distill.pub/2019/visual-exploration-gaussian-processes/) for a high-quality and highly visualization tutorial on what Gaussian Processes are.

### 符号

> Notation

让我们考虑一个具有参数 $\theta$, $f(.;\theta): \mathbb{R}^{n_0} \to \mathbb{R}^{n_L}$ 的全连接神经网络。层从0（输入）到 $L$（输出）进行索引，每层包含 $n_0, \dots, n_L$ 个神经元，包括大小为 $n_0$ 的输入和大小为 $n_L$ 的输出。总共有 $P = \sum_{l=0}^{L-1} (n_l + 1) n_{l+1}$ 个参数，因此我们有 $\theta \in \mathbb{R}^P$。

> Let us consider a fully-connected neural networks with parameter $\theta$, $f(.;\theta): \mathbb{R}^{n_0} \to \mathbb{R}^{n_L}$. Layers are indexed from 0 (input) to $L$ (output), each containing $n_0, \dots, n_L$ neurons, including the input of size $n_0$ and the output of size $n_L$. There are $P = \sum_{l=0}^{L-1} (n_l + 1) n_{l+1}$ parameters in total and thus we have $\theta \in \mathbb{R}^P$.

训练数据集包含 $N$ 个数据点，$\mathcal{D}=\{\mathbf{x}^{(i)}, y^{(i)}\}_{i=1}^N$。所有输入表示为 $\mathcal{X}=\{\mathbf{x}^{(i)}\}_{i=1}^N$，所有标签表示为 $\mathcal{Y}=\{y^{(i)}\}_{i=1}^N$。

> The training dataset contains $N$ data points, $\mathcal{D}=\{\mathbf{x}^{(i)}, y^{(i)}\}_{i=1}^N$. All the inputs are denoted as  $\mathcal{X}=\{\mathbf{x}^{(i)}\}_{i=1}^N$ and all the labels are denoted as  $\mathcal{Y}=\{y^{(i)}\}_{i=1}^N$.

现在让我们详细研究每一层中的前向传播计算。对于 $l=0, \dots, L-1$，每一层 $l$ 定义了一个仿射变换 $A^{(l)}$，其中包含一个权重矩阵 $\mathbf{w}^{(l)} \in \mathbb{R}^{n_{l} \times n_{l+1}}$ 和一个偏置项 $\mathbf{b}^{(l)} \in \mathbb{R}^{n_{l+1}}$，以及一个 [Lipschitz 连续](https://en.wikipedia.org/wiki/Lipschitz_continuity)的逐点非线性函数 $\sigma(.)$。

> Now let’s look into the forward pass computation in every layer in detail. For $l=0, \dots, L-1$, each layer $l$ defines an affine transformation $A^{(l)}$ with a weight matrix $\mathbf{w}^{(l)} \in \mathbb{R}^{n_{l} \times n_{l+1}}$ and a bias term $\mathbf{b}^{(l)} \in \mathbb{R}^{n_{l+1}}$, as well as a pointwise nonlinearity function $\sigma(.)$ which is [Lipschitz continuous](https://en.wikipedia.org/wiki/Lipschitz_continuity).

$$
\begin{aligned}
A^{(0)} &= \mathbf{x} \\
\tilde{A}^{(l+1)}(\mathbf{x}) &= \frac{1}{\sqrt{n_l}} {\mathbf{w}^{(l)}}^\top A^{(l)} + \beta\mathbf{b}^{(l)}\quad\in\mathbb{R}^{n_{l+1}} & \text{; pre-activations}\\
A^{(l+1)}(\mathbf{x}) &= \sigma(\tilde{A}^{(l+1)}(\mathbf{x}))\quad\in\mathbb{R}^{n_{l+1}} & \text{; post-activations}
\end{aligned}
$$

请注意，*NTK 参数化*在变换上应用了一个重缩放权重 $1/\sqrt{n_l}$，以避免无限宽度网络的散度。常数标量 $\beta \geq 0$ 控制偏置项的影响程度。

> Note that the *NTK parameterization* applies a rescale weight $1/\sqrt{n_l}$ on the transformation to avoid divergence with infinite-width networks. The constant scalar $\beta \geq 0$ controls how much effort the bias terms have.

在以下分析中，所有网络参数都初始化为独立同分布的高斯 $\mathcal{N}(0, 1)$。

> All the network parameters are initialized as an i.i.d Gaussian $\mathcal{N}(0, 1)$ in the following analysis.

### 神经正切核

> Neural Tangent Kernel

**神经正切核 (NTK)**（[Jacot 等人，2018](https://arxiv.org/abs/1806.07572)）是理解通过梯度下降进行神经网络训练的重要概念。其核心在于，它解释了在一个数据样本上更新模型参数如何影响对其他样本的预测。

> **Neural tangent kernel (NTK)** ([Jacot et al. 2018](https://arxiv.org/abs/1806.07572)) is an important concept for understanding neural network training via gradient descent. At its core, it explains how updating the model parameters on one data sample affects the predictions for other samples.

让我们一步步地从NTK的直观理解开始。

> Let’s start with the intuition behind NTK, step by step.

训练期间需要最小化的经验损失函数$\mathcal{L}: \mathbb{R}^P \to \mathbb{R}_+$定义如下，其中使用了每个样本的成本函数$\ell: \mathbb{R}^{n_0} \times \mathbb{R}^{n_L} \to \mathbb{R}_+$：

> The empirical loss function $\mathcal{L}: \mathbb{R}^P \to \mathbb{R}_+$ to minimize during training is defined as follows, using a per-sample cost function $\ell: \mathbb{R}^{n_0} \times \mathbb{R}^{n_L} \to \mathbb{R}_+$:

$$
\mathcal{L}(\theta) =\frac{1}{N} \sum_{i=1}^N \ell(f(\mathbf{x}^{(i)}; \theta), y^{(i)})
$$

根据链式法则，损失的梯度为：

> and according to the chain rule. the gradient of the loss is:

$$
\nabla_\theta \mathcal{L}(\theta)= \frac{1}{N} \sum_{i=1}^N \underbrace{\nabla_\theta f(\mathbf{x}^{(i)}; \theta)}_{\text{size }P \times n_L} 
\underbrace{\nabla_f \ell(f, y^{(i)})}_{\text{size } n_L \times 1}
$$

当追踪网络参数$\theta$如何随时间演变时，每次梯度下降更新都会引入一个无穷小步长的微小增量变化。由于更新步长足够小，可以近似地将其视为时间维度上的导数：

> When tracking how the network parameter $\theta$ evolves in time, each gradient descent update introduces a small incremental change of an infinitesimal step size. Because of the update step is small enough, it can be approximately viewed as a derivative on the time dimension:

$$
\frac{d\theta}{d t} = - \nabla_\theta\mathcal{L}(\theta)  = -\frac{1}{N} \sum_{i=1}^N \nabla_\theta f(\mathbf{x}^{(i)}; \theta) \nabla_f \ell(f, y^{(i)})
$$

同样，根据链式法则，网络输出根据导数演变：

> Again, by the chain rule, the network output evolves according to the derivative:

$$
\frac{df(\mathbf{x};\theta)}{dt} 
= \frac{df(\mathbf{x};\theta)}{d\theta}\frac{d\theta}{dt}
= -\frac{1}{N} \sum_{i=1}^N \color{blue}{\underbrace{\nabla_\theta f(\mathbf{x};\theta)^\top \nabla_\theta f(\mathbf{x}^{(i)}; \theta)}_\text{Neural tangent kernel}} \color{black}{\nabla_f \ell(f, y^{(i)})}
$$

在这里我们找到了**神经正切核 (NTK)**，如上述公式蓝色部分所定义，$K: \mathbb{R}^{n_0}\times\mathbb{R}^{n_0} \to \mathbb{R}^{n_L \times n_L}$：

英文原文：Here we find the Neural Tangent Kernel (NTK), as defined in the blue part in the above formula, 

$K: \mathbb{R}^{n_0}\times\mathbb{R}^{n_0} \to \mathbb{R}^{n_L \times n_L}$ :

$$
K(\mathbf{x}, \mathbf{x}'; \theta) = \nabla_\theta f(\mathbf{x};\theta)^\top \nabla_\theta f(\mathbf{x}'; \theta)
$$

其中输出矩阵中位置$(m, n), 1 \leq m, n \leq n_L$处的每个条目为：

> where each entry in the output matrix at location $(m, n), 1 \leq m, n \leq n_L$ is:

$$
K_{m,n}(\mathbf{x}, \mathbf{x}'; \theta) = \sum_{p=1}^P \frac{\partial f_m(\mathbf{x};\theta)}{\partial \theta_p} \frac{\partial f_n(\mathbf{x}';\theta)}{\partial \theta_p}
$$

一个输入$\mathbf{x}$的“特征映射”形式是$\varphi(\mathbf{x}) = \nabla_\theta f(\mathbf{x};\theta)$。

> The “feature map” form of one input $\mathbf{x}$ is $\varphi(\mathbf{x}) = \nabla_\theta f(\mathbf{x};\theta)$.

### 无限宽度网络

> Infinite Width Networks

为了理解为什么一次梯度下降对网络参数的不同初始化产生如此相似的效果，一些开创性的理论工作从无限宽度网络开始。我们将深入研究使用NTK的详细证明，说明它如何保证无限宽度网络在训练以最小化经验损失时能够收敛到全局最小值。

> To understand why the effect of one gradient descent is so similar for different initializations of network parameters, several pioneering theoretical work starts with infinite width networks. We will look into detailed proof using NTK of how it guarantees that infinite width networks can converge to a global minimum when trained to minimize an empirical loss.

#### 与高斯过程的联系

> Connection with Gaussian Processes

深度神经网络与高斯过程有着深刻的联系（[Neal 1994](https://www.cs.toronto.edu/~radford/ftp/pin.pdf)）。一个$L$层网络的输出函数，$f_i(\mathbf{x}; \theta)$对于$i=1, \dots, n_L$，是协方差为$\Sigma^{(L)}$的独立同分布的中心高斯过程，递归定义为：

> Deep neural networks have deep connection with gaussian processes ([Neal 1994](https://www.cs.toronto.edu/~radford/ftp/pin.pdf)). The output functions of a $L$ -layer network, $f_i(\mathbf{x}; \theta)$ for $i=1, \dots, n_L$ , are i.i.d. centered Gaussian process of covariance $\Sigma^{(L)}$, defined recursively as:

$$
\begin{aligned}
\Sigma^{(1)}(\mathbf{x}, \mathbf{x}') &= \frac{1}{n_0}\mathbf{x}^\top{\mathbf{x}'} + \beta^2 \\
\lambda^{(l+1)}(\mathbf{x}, \mathbf{x}') &= \begin{bmatrix}
\Sigma^{(l)}(\mathbf{x}, \mathbf{x}) & \Sigma^{(l)}(\mathbf{x}, \mathbf{x}') \\
\Sigma^{(l)}(\mathbf{x}', \mathbf{x}) & \Sigma^{(l)}(\mathbf{x}', \mathbf{x}')
\end{bmatrix} \\
\Sigma^{(l+1)}(\mathbf{x}, \mathbf{x}') &= \mathbb{E}_{f \sim \mathcal{N}(0, \lambda^{(l)})}[\sigma(f(\mathbf{x})) \sigma(f(\mathbf{x}'))] + \beta^2
\end{aligned}
$$

[Lee & Bahri et al. (2018)](https://arxiv.org/abs/1711.00165)通过数学归纳法给出了证明：

> [Lee & Bahri et al. (2018)](https://arxiv.org/abs/1711.00165) showed a proof by mathematical induction:

(1) 让我们从$L=1$开始，此时没有非线性函数，输入仅通过简单的仿射变换进行处理：

> (1) Let’s start with $L=1$, when there is no nonlinearity function and the input is only processed by a simple affine transformation:

$$
\begin{aligned}
f(\mathbf{x};\theta) = \tilde{A}^{(1)}(\mathbf{x}) &= \frac{1}{\sqrt{n_0}}{\mathbf{w}^{(0)}}^\top\mathbf{x} + \beta\mathbf{b}^{(0)} \\
\text{where }\tilde{A}_m^{(1)}(\mathbf{x}) &= \frac{1}{\sqrt{n_0}}\sum_{i=1}^{n_0} w^{(0)}_{im}x_i + \beta b^{(0)}_m\quad \text{for }1 \leq m \leq n_1
\end{aligned}
$$

由于权重和偏置是独立同分布初始化的，因此该网络${\tilde{A}^{(1)}_1(\mathbf{x}), \dots, \tilde{A}^{(1)}_{n_1}(\mathbf{x})}$的所有输出维度也是独立同分布的。给定不同的输入，第$m$个网络输出$\tilde{A}^{(1)}_m(.)$具有联合多元高斯分布，等同于具有协方差函数的高斯过程（我们知道均值$\mu_w=\mu_b=0$和方差$\sigma^2_w = \sigma^2_b=1$）

> Since the weights and biases are initialized i.i.d., all the output dimensions of this network  ${\tilde{A}^{(1)}_1(\mathbf{x}), \dots, \tilde{A}^{(1)}_{n_1}(\mathbf{x})}$ are also i.i.d. Given different inputs, the $m$ -th network outputs $\tilde{A}^{(1)}_m(.)$ have a joint multivariate Gaussian distribution, equivalent to a Gaussian process with covariance function (We know that mean $\mu_w=\mu_b=0$ and variance $\sigma^2_w = \sigma^2_b=1$)

$$
\begin{aligned}
\Sigma^{(1)}(\mathbf{x}, \mathbf{x}') 
&= \mathbb{E}[\tilde{A}_m^{(1)}(\mathbf{x})\tilde{A}_m^{(1)}(\mathbf{x}')] \\
&= \mathbb{E}\Big[\Big( \frac{1}{\sqrt{n_0}}\sum_{i=1}^{n_0} w^{(0)}_{i,m}x_i + \beta b^{(0)}_m \Big) \Big( \frac{1}{\sqrt{n_0}}\sum_{i=1}^{n_0} w^{(0)}_{i,m}x'_i + \beta b^{(0)}_m \Big)\Big] \\
&= \frac{1}{n_0} \sigma^2_w \sum_{i=1}^{n_0} \sum_{j=1}^{n_0} x_i{x'}_j + \frac{\beta \mu_b}{\sqrt{n_0}} \sum_{i=1}^{n_0} w_{im}(x_i + x'_i) + \sigma^2_b \beta^2 \\
&= \frac{1}{n_0}\mathbf{x}^\top{\mathbf{x}'} + \beta^2
\end{aligned}
$$

(2) 使用归纳法，我们首先假设该命题对于$L=l$（一个$l$层网络）成立，因此$\tilde{A}^{(l)}_m(.)$是一个具有协方差$\Sigma^{(l)}$的高斯过程，并且$\{\tilde{A}^{(l)}_i\}_{i=1}^{n_l}$是独立同分布的。

> (2) Using induction, we first assume the proposition is true for $L=l$, a $l$ -layer network, and thus $\tilde{A}^{(l)}_m(.)$ is a Gaussian process with covariance $\Sigma^{(l)}$ and $\{\tilde{A}^{(l)}_i\}_{i=1}^{n_l}$ are i.i.d.

然后我们需要证明该命题对于$L=l+1$也成立。我们通过以下方式计算输出：

> Then we need to prove the proposition is also true for $L=l+1$. We compute the outputs by:

$$
\begin{aligned}
f(\mathbf{x};\theta) = \tilde{A}^{(l+1)}(\mathbf{x}) &= \frac{1}{\sqrt{n_l}}{\mathbf{w}^{(l)}}^\top \sigma(\tilde{A}^{(l)}(\mathbf{x})) + \beta\mathbf{b}^{(l)} \\
\text{where }\tilde{A}^{(l+1)}_m(\mathbf{x}) &= \frac{1}{\sqrt{n_l}}\sum_{i=1}^{n_l} w^{(l)}_{im}\sigma(\tilde{A}^{(l)}_i(\mathbf{x})) + \beta b^{(l)}_m \quad \text{for }1 \leq m \leq n_{l+1}
\end{aligned}
$$

我们可以推断，前一个隐藏层贡献之和的期望为零：

> We can infer that the expectation of the sum of contributions of the previous hidden layers is zero:

$$
\begin{aligned}
\mathbb{E}[w^{(l)}_{im}\sigma(\tilde{A}^{(l)}_i(\mathbf{x}))] 
&= \mathbb{E}[w^{(l)}_{im}]\mathbb{E}[\sigma(\tilde{A}^{(l)}_i(\mathbf{x}))] 
= \mu_w \mathbb{E}[\sigma(\tilde{A}^{(l)}_i(\mathbf{x}))] = 0 \\
\mathbb{E}[\big(w^{(l)}_{im}\sigma(\tilde{A}^{(l)}_i(\mathbf{x}))\big)^2]
&= \mathbb{E}[{w^{(l)}_{im}}^2]\mathbb{E}[\sigma(\tilde{A}^{(l)}_i(\mathbf{x}))^2] 
= \sigma_w^2 \Sigma^{(l)}(\mathbf{x}, \mathbf{x})
= \Sigma^{(l)}(\mathbf{x}, \mathbf{x})
\end{aligned}
$$

由于$\{\tilde{A}^{(l)}_i(\mathbf{x})\}_{i=1}^{n_l}$是独立同分布的，根据中心极限定理，当隐藏层变得无限宽时$n_l \to \infty$，$\tilde{A}^{(l+1)}_m(\mathbf{x})$呈高斯分布，方差为$\beta^2 + \text{Var}(\tilde{A}_i^{(l)}(\mathbf{x}))$。请注意，${\tilde{A}^{(l+1)}_1(\mathbf{x}), \dots, \tilde{A}^{(l+1)}_{n_{l+1}}(\mathbf{x})}$仍然是独立同分布的。

> Since $\{\tilde{A}^{(l)}_i(\mathbf{x})\}_{i=1}^{n_l}$ are i.i.d., according to central limit theorem, when the hidden layer gets infinitely wide $n_l \to \infty$, $\tilde{A}^{(l+1)}_m(\mathbf{x})$ is Gaussian distributed with variance $\beta^2 + \text{Var}(\tilde{A}_i^{(l)}(\mathbf{x}))$. Note that ${\tilde{A}^{(l+1)}_1(\mathbf{x}), \dots, \tilde{A}^{(l+1)}_{n_{l+1}}(\mathbf{x})}$ are still i.i.d.

$\tilde{A}^{(l+1)}_m(.)$等同于一个具有协方差函数的高斯过程：

> $\tilde{A}^{(l+1)}_m(.)$ is equivalent to a Gaussian process with covariance function:

$$
\begin{aligned}
\Sigma^{(l+1)}(\mathbf{x}, \mathbf{x}') 
&= \mathbb{E}[\tilde{A}^{(l+1)}_m(\mathbf{x})\tilde{A}^{(l+1)}_m(\mathbf{x}')] \\
&= \frac{1}{n_l} \sigma\big(\tilde{A}^{(l)}_i(\mathbf{x})\big)^\top \sigma\big(\tilde{A}^{(l)}_i(\mathbf{x}')\big) + \beta^2 \quad\text{;similar to how we get }\Sigma^{(1)}
\end{aligned}
$$

当$n_l \to \infty$时，根据中心极限定理，

> When $n_l \to \infty$, according to central limit theorem,

$$
\Sigma^{(l+1)}(\mathbf{x}, \mathbf{x}')  \to \mathbb{E}_{f \sim \mathcal{N}(0, \Lambda^{(l)})}[\sigma(f(\mathbf{x}))^\top \sigma(f(\mathbf{x}'))] + \beta^2
$$

上述过程中的高斯过程形式被称为*神经网络高斯过程 (NNGP)* ([Lee & Bahri et al. (2018)](https://arxiv.org/abs/1711.00165))。

> The form of Gaussian processes in the above process is referred to as the *Neural Network Gaussian Process (NNGP)* ([Lee & Bahri et al. (2018)](https://arxiv.org/abs/1711.00165)).

#### 确定性神经正切核

> Deterministic Neural Tangent Kernel

最后，我们现在已经做好了充分准备，可以深入研究NTK论文中最关键的命题了：

> Finally we are now prepared enough to look into the most critical proposition from the NTK paper:

**当$n_1, \dots, n_L \to \infty$（无限宽度的网络）时，NTK收敛为：**

英文原文：When 

$n_1, \dots, n_L \to \infty$ (network with infinite width), the NTK converges to be:

- **(1) 初始化时是确定性的，这意味着核与初始化值无关，仅由模型架构决定；并且**
- **(2) 在训练期间保持不变。**

> • **(1) deterministic at initialization, meaning that the kernel is irrelevant to the initialization values and only determined by the model architecture; and**
> • **(2) stays constant during training.**

该证明也依赖于数学归纳法：

> The proof depends on mathematical induction as well:

(1) 首先，我们始终有 $K^{(0)} = 0$。当 $L=1$ 时，我们可以直接获得 NTK 的表示。它是确定性的，不依赖于网络初始化。没有隐藏层，因此没有什么可以承担无限宽度。

> (1) First of all, we always have $K^{(0)} = 0$. When $L=1$, we can get the representation of NTK directly. It is deterministic and does not depend on the network initialization. There is no hidden layer, so there is nothing to take on infinite width.

$$
\begin{aligned}
f(\mathbf{x};\theta) &= \tilde{A}^{(1)}(\mathbf{x}) = \frac{1}{\sqrt{n_0}} {\mathbf{w}^{(0)}}^\top\mathbf{x} + \beta\mathbf{b}^{(0)} \\
K^{(1)}(\mathbf{x}, \mathbf{x}';\theta) 
&= \Big(\frac{\partial f(\mathbf{x}';\theta)}{\partial \mathbf{w}^{(0)}}\Big)^\top \frac{\partial f(\mathbf{x};\theta)}{\partial \mathbf{w}^{(0)}} +
\Big(\frac{\partial f(\mathbf{x}';\theta)}{\partial \mathbf{b}^{(0)}}\Big)^\top \frac{\partial f(\mathbf{x};\theta)}{\partial \mathbf{b}^{(0)}} \\
&= \frac{1}{n_0} \mathbf{x}^\top{\mathbf{x}'} + \beta^2 = \Sigma^{(1)}(\mathbf{x}, \mathbf{x}')
\end{aligned}
$$

(2) 现在当$L=l$时，我们假设一个$l$层网络，其$\tilde{P}$个总参数$\tilde{\theta} = (\mathbf{w}^{(0)}, \dots, \mathbf{w}^{(l-1)}, \mathbf{b}^{(0)}, \dots, \mathbf{b}^{(l-1)}) \in \mathbb{R}^\tilde{P}$，其NTK收敛到一个确定性极限，当$n_1, \dots, n_{l-1} \to \infty$时。

> (2) Now when $L=l$, we assume that a $l$ -layer network with $\tilde{P}$ parameters in total, $\tilde{\theta} = (\mathbf{w}^{(0)}, \dots, \mathbf{w}^{(l-1)}, \mathbf{b}^{(0)}, \dots, \mathbf{b}^{(l-1)}) \in \mathbb{R}^\tilde{P}$, has a NTK converging to a deterministic limit when $n_1, \dots, n_{l-1} \to \infty$.

$$
K^{(l)}(\mathbf{x}, \mathbf{x}';\tilde{\theta}) = \nabla_{\tilde{\theta}} \tilde{A}^{(l)}(\mathbf{x})^\top \nabla_{\tilde{\theta}} \tilde{A}^{(l)}(\mathbf{x}') \to K^{(l)}_{\infty}(\mathbf{x}, \mathbf{x}')
$$

请注意，$K_\infty^{(l)}$ 不依赖于 $\theta$。

> Note that $K_\infty^{(l)}$ has no dependency on $\theta$.

接下来我们检查 $L=l+1$ 的情况。与 $l$ 层网络相比，$(l+1)$ 层网络具有额外的权重矩阵 $\mathbf{w}^{(l)}$ 和偏置 $\mathbf{b}^{(l)}$，因此总参数包含 $\theta = (\tilde{\theta}, \mathbf{w}^{(l)}, \mathbf{b}^{(l)})$。

> Next let’s check the case $L=l+1$. Compared to a $l$ -layer network, a $(l+1)$ -layer network has additional weight matrix $\mathbf{w}^{(l)}$ and bias $\mathbf{b}^{(l)}$ and thus the total parameters contain $\theta = (\tilde{\theta}, \mathbf{w}^{(l)}, \mathbf{b}^{(l)})$.

这个 $(l+1)$ 层网络的输出函数是：

> The output function of this $(l+1)$ -layer network is:

$$
f(\mathbf{x};\theta) = \tilde{A}^{(l+1)}(\mathbf{x};\theta) = \frac{1}{\sqrt{n_l}} {\mathbf{w}^{(l)}}^\top \sigma\big(\tilde{A}^{(l)}(\mathbf{x})\big) + \beta \mathbf{b}^{(l)}
$$

我们知道它对不同参数集的导数；为简洁起见，在以下方程中用 $\tilde{A}^{(l)} = \tilde{A}^{(l)}(\mathbf{x})$ 表示：

> And we know its derivative with respect to different sets of parameters; let denote $\tilde{A}^{(l)} = \tilde{A}^{(l)}(\mathbf{x})$ for brevity in the following equation:

$$
\begin{aligned}
\nabla_{\color{blue}{\mathbf{w}^{(l)}}} f(\mathbf{x};\theta) &= \color{blue}{
    \frac{1}{\sqrt{n_l}} \sigma\big(\tilde{A}^{(l)}\big)^\top
} \color{black}{\quad \in \mathbb{R}^{1 \times n_l}} \\
\nabla_{\color{green}{\mathbf{b}^{(l)}}} f(\mathbf{x};\theta) &= \color{green}{ \beta } \\
\nabla_{\color{red}{\tilde{\theta}}} f(\mathbf{x};\theta) 
&= \frac{1}{\sqrt{n_l}} \nabla_\tilde{\theta}\sigma(\tilde{A}^{(l)}) \mathbf{w}^{(l)} \\
&= \color{red}{
    \frac{1}{\sqrt{n_l}}
    \begin{bmatrix}
        \dot{\sigma}(\tilde{A}_1^{(l)})\frac{\partial \tilde{A}_1^{(l)}}{\partial \tilde{\theta}_1} & \dots & \dot{\sigma}(\tilde{A}_{n_l}^{(l)})\frac{\partial \tilde{A}_{n_l}^{(l)}}{\partial \tilde{\theta}_1} \\
        \vdots \\       
        \dot{\sigma}(\tilde{A}_1^{(l)})\frac{\partial \tilde{A}_1^{(l)}}{\partial \tilde{\theta}_\tilde{P}}
        & \dots & \dot{\sigma}(\tilde{A}_{n_l}^{(l)})\frac{\partial \tilde{A}_{n_l}^{(l)}}{\partial \tilde{\theta}_\tilde{P}}\\
    \end{bmatrix}
    \mathbf{w}^{(l)}
    \color{black}{\quad \in \mathbb{R}^{\tilde{P} \times n_{l+1}}}
}
\end{aligned}
$$

其中$\dot{\sigma}$是...的导数$\sigma$并且每个条目位于$(p, m), 1 \leq p \leq \tilde{P}, 1 \leq m \leq n_{l+1}$的矩阵$\nabla_{\tilde{\theta}} f(\mathbf{x};\theta)$可以写成

> where $\dot{\sigma}$ is the derivative of $\sigma$ and each entry at location $(p, m), 1 \leq p \leq \tilde{P}, 1 \leq m \leq n_{l+1}$ in the matrix $\nabla_{\tilde{\theta}} f(\mathbf{x};\theta)$ can be written as

$$
\frac{\partial f_m(\mathbf{x};\theta)}{\partial \tilde{\theta}_p} = \sum_{i=1}^{n_l} w^{(l)}_{im} \dot{\sigma}\big(\tilde{A}_i^{(l)} \big) \nabla_{\tilde{\theta}_p} \tilde{A}_i^{(l)}
$$

这个$(l+1)$层网络的NTK可以相应地定义为：

> The NTK for this $(l+1)$ -layer network can be defined accordingly:

$$
\begin{aligned}
& K^{(l+1)}(\mathbf{x}, \mathbf{x}'; \theta) \\ 
=& \nabla_{\theta} f(\mathbf{x};\theta)^\top \nabla_{\theta} f(\mathbf{x};\theta) \\
=& \color{blue}{\nabla_{\mathbf{w}^{(l)}} f(\mathbf{x};\theta)^\top \nabla_{\mathbf{w}^{(l)}} f(\mathbf{x};\theta)} 
    + \color{green}{\nabla_{\mathbf{b}^{(l)}} f(\mathbf{x};\theta)^\top \nabla_{\mathbf{b}^{(l)}} f(\mathbf{x};\theta)}
    + \color{red}{\nabla_{\tilde{\theta}} f(\mathbf{x};\theta)^\top \nabla_{\tilde{\theta}} f(\mathbf{x};\theta)}  \\
=& \frac{1}{n_l} \Big[ 
    \color{blue}{\sigma(\tilde{A}^{(l)})\sigma(\tilde{A}^{(l)})^\top} 
    + \color{green}{\beta^2} \\
    &+
    \color{red}{
        {\mathbf{w}^{(l)}}^\top 
        \begin{bmatrix}
            \dot{\sigma}(\tilde{A}_1^{(l)})\dot{\sigma}(\tilde{A}_1^{(l)})\sum_{p=1}^\tilde{P} \frac{\partial \tilde{A}_1^{(l)}}{\partial \tilde{\theta}_p}\frac{\partial \tilde{A}_1^{(l)}}{\partial \tilde{\theta}_p} & \dots & \dot{\sigma}(\tilde{A}_1^{(l)})\dot{\sigma}(\tilde{A}_{n_l}^{(l)})\sum_{p=1}^\tilde{P} \frac{\partial \tilde{A}_1^{(l)}}{\partial \tilde{\theta}_p}\frac{\partial \tilde{A}_{n_l}^{(l)}}{\partial \tilde{\theta}_p} \\
            \vdots \\
            \dot{\sigma}(\tilde{A}_{n_l}^{(l)})\dot{\sigma}(\tilde{A}_1^{(l)})\sum_{p=1}^\tilde{P} \frac{\partial \tilde{A}_{n_l}^{(l)}}{\partial \tilde{\theta}_p}\frac{\partial \tilde{A}_1^{(l)}}{\partial \tilde{\theta}_p} & \dots & \dot{\sigma}(\tilde{A}_{n_l}^{(l)})\dot{\sigma}(\tilde{A}_{n_l}^{(l)})\sum_{p=1}^\tilde{P} \frac{\partial \tilde{A}_{n_l}^{(l)}}{\partial \tilde{\theta}_p}\frac{\partial \tilde{A}_{n_l}^{(l)}}{\partial \tilde{\theta}_p} \\
        \end{bmatrix}
        \mathbf{w}^{(l)}
    }
\color{black}{\Big]} \\
=& \frac{1}{n_l} \Big[ 
    \color{blue}{\sigma(\tilde{A}^{(l)})\sigma(\tilde{A}^{(l)})^\top} 
    + \color{green}{\beta^2} \\
    &+
    \color{red}{
        {\mathbf{w}^{(l)}}^\top 
        \begin{bmatrix}
            \dot{\sigma}(\tilde{A}_1^{(l)})\dot{\sigma}(\tilde{A}_1^{(l)})K^{(l)}_{11} & \dots & \dot{\sigma}(\tilde{A}_1^{(l)})\dot{\sigma}(\tilde{A}_{n_l}^{(l)})K^{(l)}_{1n_l} \\
            \vdots \\
            \dot{\sigma}(\tilde{A}_{n_l}^{(l)})\dot{\sigma}(\tilde{A}_1^{(l)})K^{(l)}_{n_l1} & \dots & \dot{\sigma}(\tilde{A}_{n_l}^{(l)})\dot{\sigma}(\tilde{A}_{n_l}^{(l)})K^{(l)}_{n_ln_l} \\
        \end{bmatrix}
        \mathbf{w}^{(l)}
    }
\color{black}{\Big]}
\end{aligned}
$$

其中，每个单独的条目位于$(m, n), 1 \leq m, n \leq n_{l+1}$的矩阵$K^{(l+1)}$可以写为：

> where each individual entry at location $(m, n), 1 \leq m, n \leq n_{l+1}$ of the matrix $K^{(l+1)}$ can be written as:

$$
\begin{aligned}
K^{(l+1)}_{mn} 
=& \frac{1}{n_l}\Big[
    \color{blue}{\sigma(\tilde{A}_m^{(l)})\sigma(\tilde{A}_n^{(l)})}
    + \color{green}{\beta^2} 
    + \color{red}{
    \sum_{i=1}^{n_l} \sum_{j=1}^{n_l} w^{(l)}_{im} w^{(l)}_{in} \dot{\sigma}(\tilde{A}_i^{(l)}) \dot{\sigma}(\tilde{A}_{j}^{(l)}) K_{ij}^{(l)}
}
\Big]
\end{aligned}
$$

当 $n_l \to \infty$ 时，蓝色和绿色的部分具有以下限制（证明见[上一节](https://lilianweng.github.io/posts/2022-09-08-ntk/#connection-with-gaussian-processes)）：

> When $n_l \to \infty$, the section in blue and green has the limit (See the proof in the [previous section](https://lilianweng.github.io/posts/2022-09-08-ntk/#connection-with-gaussian-processes)):

$$
\frac{1}{n_l}\sigma(\tilde{A}^{(l)})\sigma(\tilde{A}^{(l)}) + \beta^2\to \Sigma^{(l+1)}
$$

红色部分有以下限制：

> and the red section has the limit:

$$
\sum_{i=1}^{n_l} \sum_{j=1}^{n_l} w^{(l)}_{im} w^{(l)}_{in} \dot{\sigma}(\tilde{A}_i^{(l)}) \dot{\sigma}(\tilde{A}_{j}^{(l)}) K_{ij}^{(l)} 
\to
\sum_{i=1}^{n_l} \sum_{j=1}^{n_l} w^{(l)}_{im} w^{(l)}_{in} \dot{\sigma}(\tilde{A}_i^{(l)}) \dot{\sigma}(\tilde{A}_{j}^{(l)}) K_{\infty,ij}^{(l)}
$$

后来，[Arora 等人 (2019)](https://arxiv.org/abs/1904.11955) 提供了一个具有较弱限制的证明，该证明不要求所有隐藏层都具有无限宽度，而只要求最小宽度足够大。

> Later, [Arora et al. (2019)](https://arxiv.org/abs/1904.11955) provided a proof with a weaker limit, that does not require all the hidden layers to be infinitely wide, but only requires the minimum width to be sufficiently large.

#### 线性化模型

> Linearized Models

根据[上一节](https://lilianweng.github.io/posts/2022-09-08-ntk/#neural-tangent-kernel)，根据导数链式法则，我们已知无限宽度网络输出上的梯度更新如下；为简洁起见，在以下分析中我们省略输入：

> From the [previous section](https://lilianweng.github.io/posts/2022-09-08-ntk/#neural-tangent-kernel), according to the derivative chain rule, we have known that the gradient update on the output of an infinite width network is as follows; For brevity, we omit the inputs in the following analysis:

$$
\begin{aligned}
\frac{df(\theta)}{dt} 
&= -\eta\nabla_\theta f(\theta)^\top \nabla_\theta f(\theta) \nabla_f \mathcal{L} & \\
&= -\eta\nabla_\theta f(\theta)^\top \nabla_\theta f(\theta) \nabla_f \mathcal{L} & \\
&= -\eta K(\theta) \nabla_f \mathcal{L} \\
&= \color{cyan}{-\eta K_\infty \nabla_f \mathcal{L}} & \text{; for infinite width network}\\
\end{aligned}
$$

为了跟踪$\theta$随时间的演变，我们将其视为时间步长$t$的函数。通过泰勒展开，网络学习动力学可以简化为：

> To track the evolution of $\theta$ in time, let’s consider it as a function of time step $t$. With Taylor expansion, the network learning dynamics can be simplified as:

$$
f(\theta(t)) \approx f^\text{lin}(\theta(t)) = f(\theta(0)) + \underbrace{\nabla_\theta f(\theta(0))}_{\text{formally }\nabla_\theta f(\mathbf{x}; \theta) \vert_{\theta=\theta(0)}} (\theta(t) - \theta(0))
$$

这种形式通常被称为*线性化*模型，鉴于$\theta(0)$、$f(\theta(0))$和$\nabla_\theta f(\theta(0))$都是常数。假设增量时间步长$t$极小，并且参数通过梯度下降更新：

> Such formation is commonly referred to as the *linearized* model, given $\theta(0)$, $f(\theta(0))$, and $\nabla_\theta f(\theta(0))$ are all constants. Assuming that the incremental time step $t$ is extremely small and the parameter is updated by gradient descent:

$$
\begin{aligned}
\theta(t) - \theta(0) &= - \eta \nabla_\theta \mathcal{L}(\theta) = - \eta \nabla_\theta f(\theta)^\top \nabla_f \mathcal{L} \\
f^\text{lin}(\theta(t)) - f(\theta(0)) &= - \eta\nabla_\theta f(\theta(0))^\top \nabla_\theta f(\mathcal{X};\theta(0)) \nabla_f \mathcal{L} \\
\frac{df(\theta(t))}{dt} &= - \eta K(\theta(0)) \nabla_f \mathcal{L} \\
\frac{df(\theta(t))}{dt} &= \color{cyan}{- \eta K_\infty \nabla_f \mathcal{L}}  & \text{; for infinite width network}\\
\end{aligned}
$$

最终我们得到相同的学习动力学，这意味着无限宽度的神经网络可以被上述线性化模型大大简化（[Lee & Xiao, et al. 2019](https://arxiv.org/abs/1902.06720)）所支配。

> Eventually we get the same learning dynamics, which implies that a neural network with infinite width can be considerably simplified as governed by the above linearized model ([Lee & Xiao, et al. 2019](https://arxiv.org/abs/1902.06720)).

在一个简单的情况下，当经验损失是MSE损失时，$\nabla_\theta \mathcal{L}(\theta) = f(\mathcal{X}; \theta) - \mathcal{Y}$，网络的动力学变成一个简单的线性常微分方程，并且可以以封闭形式求解：

> In a simple case when the empirical loss is an MSE loss, $\nabla_\theta \mathcal{L}(\theta) = f(\mathcal{X}; \theta) - \mathcal{Y}$, the dynamics of the network becomes a simple linear ODE and it can be solved in a closed form:

$$
\begin{aligned}
\frac{df(\theta)}{dt} =& -\eta K_\infty (f(\theta) - \mathcal{Y}) & \\
\frac{dg(\theta)}{dt} =& -\eta K_\infty g(\theta) & \text{; let }g(\theta)=f(\theta) - \mathcal{Y} \\
\int \frac{dg(\theta)}{g(\theta)} =& -\eta \int K_\infty dt & \\
g(\theta) &= C e^{-\eta K_\infty t} &
\end{aligned}
$$

当 $t=0$ 时，我们有 $C=f(\theta(0)) - \mathcal{Y}$，因此，

> When $t=0$, we have $C=f(\theta(0)) - \mathcal{Y}$ and therefore,

$$
f(\theta) 
= (f(\theta(0)) - \mathcal{Y})e^{-\eta K_\infty t} + \mathcal{Y} \\
= f(\theta(0))e^{-K_\infty t} + (I - e^{-\eta K_\infty t})\mathcal{Y}
$$

#### 惰性训练

> Lazy Training

人们观察到，当神经网络严重过参数化时，模型能够学习，训练损失迅速收敛到零，但网络参数几乎没有变化。*惰性训练*指的就是这种现象。换句话说，当损失 $\mathcal{L}$ 有相当大的减少时，网络微分 $f$（即雅可比矩阵）的变化仍然非常小。

> People observe that when a neural network is heavily over-parameterized, the model is able to learn with the training loss quickly converging to zero but the network parameters hardly change. *Lazy training* refers to the phenomenon. In other words, when the loss $\mathcal{L}$ has a decent amount of reduction, the change in the differential of the network $f$ (aka the Jacobian matrix) is still very small.

设 $\theta(0)$ 为初始网络参数，$\theta(T)$ 为损失最小化到零时的最终网络参数。参数空间中的增量变化可以用一阶泰勒展开近似表示：

> Let $\theta(0)$ be the initial network parameters and $\theta(T)$ be the final network parameters when the loss has been minimized to zero. The delta change in parameter space can be approximated with first-order Taylor expansion:

$$
\begin{aligned}
\hat{y} = f(\theta(T)) &\approx f(\theta(0)) + \nabla_\theta f(\theta(0)) (\theta(T) - \theta(0)) \\
\text{Thus }\Delta \theta &= \theta(T) - \theta(0) \approx \frac{\|\hat{y} - f(\theta(0))\|}{\| \nabla_\theta f(\theta(0)) \|}
\end{aligned}
$$

仍然遵循一阶泰勒展开，我们可以追踪$f$微分的变化：

> Still following the first-order Taylor expansion, we can track the change in the differential of $f$:

$$
\begin{aligned}
\nabla_\theta f(\theta(T)) 
&\approx \nabla_\theta f(\theta(0)) + \nabla^2_\theta f(\theta(0)) \Delta\theta \\
&= \nabla_\theta f(\theta(0)) + \nabla^2_\theta f(\theta(0)) \frac{\|\hat{y} - f(\mathbf{x};\theta(0))\|}{\| \nabla_\theta f(\theta(0)) \|} \\
\text{Thus }\Delta\big(\nabla_\theta f\big) &= \nabla_\theta f(\theta(T)) - \nabla_\theta f(\theta(0)) = \|\hat{y} - f(\mathbf{x};\theta(0))\| \frac{\nabla^2_\theta f(\theta(0))}{\| \nabla_\theta f(\theta(0)) \|}
\end{aligned}
$$

令 $\kappa(\theta)$ 为 $f$ 的微分相对于参数空间变化的相对变化：

> Let $\kappa(\theta)$ be the relative change of the differential of $f$ to the change in the parameter space:

$$
\kappa(\theta = \frac{\Delta\big(\nabla_\theta f\big)}{\| \nabla_\theta f(\theta(0)) \|} = \|\hat{y} - f(\theta(0))\| \frac{\nabla^2_\theta f(\theta(0))}{\| \nabla_\theta f(\theta(0)) \|^2}
$$

[Chizat et al. (2019)](https://arxiv.org/abs/1812.07956) 证明了一个两层神经网络，它 $\mathbb{E}[\kappa(\theta_0)] \to 0$ （进入惰性状态），当隐藏神经元的数量 $\to \infty$。此外，推荐 [this post](https://rajatvd.github.io/NTK/) 阅读更多关于线性化模型和惰性训练的讨论。

> [Chizat et al. (2019)](https://arxiv.org/abs/1812.07956) showed the proof for a two-layer neural network that $\mathbb{E}[\kappa(\theta_0)] \to 0$ (getting into the lazy regime) when the number of hidden neurons $\to \infty$. Also, recommend [this post](https://rajatvd.github.io/NTK/) for more discussion on linearized models and lazy training.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2022 年 9 月)。神经正切核背后的一些数学原理。Lil’Log。https://lilianweng.github.io/posts/2022-09-08-ntk/。

> Weng, Lilian. (Sep 2022). Some math behind neural tangent kernel. Lil’Log. https://lilianweng.github.io/posts/2022-09-08-ntk/.

或者

> Or

```
@article{weng2022ntk,
  title   = "Some Math behind Neural Tangent Kernel",
  author  = "Weng, Lilian",
  journal = "Lil'Log",
  year    = "2022",
  month   = "Sep",
  url     = "https://lilianweng.github.io/posts/2022-09-08-ntk/"
}
```

### 参考文献

> References

[1] Jacot et al. [“神经正切核：神经网络中的收敛性和泛化。”](https://arxiv.org/abs/1806.07572) NeuriPS 2018.

> [1] Jacot et al. [“Neural Tangent Kernel: Convergence and Generalization in Neural Networks.”](https://arxiv.org/abs/1806.07572) NeuriPS 2018.

[2]Radford M. Neal. [“无限网络的先验。”](https://lilianweng.github.io/posts/2022-09-08-ntk/) 神经网络的贝叶斯学习。Springer, New York, NY, 1996. 29-53.

> [2]Radford M. Neal. [“Priors for Infinite Networks.”](https://lilianweng.github.io/posts/2022-09-08-ntk/) Bayesian Learning for Neural Networks. Springer, New York, NY, 1996. 29-53.

[3] Lee & Bahri et al. [“作为高斯过程的深度神经网络。”](https://arxiv.org/abs/1711.00165) ICLR 2018.

> [3] Lee & Bahri et al. [“Deep Neural Networks as Gaussian Processes.”](https://arxiv.org/abs/1711.00165) ICLR 2018.

[4] Chizat et al. [“关于可微分编程中的惰性训练”](https://arxiv.org/abs/1812.07956) NeuriPS 2019.

> [4] Chizat et al. [“On Lazy Training in Differentiable Programming”](https://arxiv.org/abs/1812.07956) NeuriPS 2019.

[5] Lee & Xiao, et al. [“任意深度的宽神经网络在梯度下降下演变为线性模型。”](https://arxiv.org/abs/1902.06720) NeuriPS 2019.

> [5] Lee & Xiao, et al. [“Wide Neural Networks of Any Depth Evolve as Linear Models Under Gradient Descent.”](https://arxiv.org/abs/1902.06720) NeuriPS 2019.

[6] Arora 等人。[“关于无限宽神经网络的精确计算。”](https://arxiv.org/abs/1904.11955) NeurIPS 2019。

> [6] Arora, et al. [“On Exact Computation with an Infinitely Wide Neural Net.”](https://arxiv.org/abs/1904.11955) NeurIPS 2019.

[7] (YouTube 视频) [“神经正切核：神经网络中的收敛性和泛化性”](https://www.youtube.com/watch?v=raT2ECrvbag) 作者：Arthur Jacot，2018 年 11 月。

> [7] (YouTube video) [“Neural Tangent Kernel: Convergence and Generalization in Neural Networks”](https://www.youtube.com/watch?v=raT2ECrvbag) by Arthur Jacot, Nov 2018.

[8] (YouTube 视频) [“第 7 讲 - 深度学习基础：神经正切核”](https://www.youtube.com/watch?v=DObobAnELkU) 作者：Soheil Feizi，2020 年 9 月。

> [8] (YouTube video) [“Lecture 7 - Deep Learning Foundations: Neural Tangent Kernels”](https://www.youtube.com/watch?v=DObobAnELkU) by Soheil Feizi, Sep 2020.

[9] [“理解神经正切核。”](https://rajatvd.github.io/NTK/) Rajat 的博客。

> [9] [“Understanding the Neural Tangent Kernel.”](https://rajatvd.github.io/NTK/) Rajat’s Blog.

[10] [“神经正切核。”](https://appliedprobability.blog/2021/03/10/neural-tangent-kernel/) 应用概率笔记，2021 年 3 月。

> [10] [“Neural Tangent Kernel.”](https://appliedprobability.blog/2021/03/10/neural-tangent-kernel/)Applied Probability Notes, Mar 2021.

[11] [“关于神经正切核的一些直觉。”](https://www.inference.vc/neural-tangent-kernels-some-intuition-for-kernel-gradient-descent/) inFERENCe，2020 年 11 月。

> [11] [“Some Intuition on the Neural Tangent Kernel.”](https://www.inference.vc/neural-tangent-kernels-some-intuition-for-kernel-gradient-descent/) inFERENCe, Nov 2020.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Over-parameterized | 过参数化 | 指模型参数数量远超训练数据点数量的情况。 |
| Neural Tangent Kernel (NTK) | 神经正切核 | 一种核函数，用于解释神经网络在梯度下降训练期间的演变。 |
| Gradient Descent | 梯度下降 | 一种优化算法，通过迭代地沿着损失函数梯度的反方向更新参数来最小化函数。 |
| Jacobian matrix | 雅可比矩阵 | 一个矩阵，包含一个向量值函数的所有一阶偏导数。 |
| Central Limit Theorem (CLT) | 中心极限定理 | 指出大量独立同分布随机变量的均值趋近于高斯分布。 |
| Taylor expansion | 泰勒展开 | 将一个函数表示为无限个分量的和，每个分量都用该函数的导数表示。 |
| Kernel method | 核方法 | 一种非参数的、基于实例的机器学习算法，通过核函数衡量数据点相似性。 |
| Gaussian Process (GP) | 高斯过程 | 一种非参数方法，通过对一组随机变量建模多元高斯概率分布。 |
| Covariance matrix | 协方差矩阵 | 一个方阵，表示多维随机变量中每对元素之间的协方差。 |
| Affine transformation | 仿射变换 | 一种线性变换后接平移的几何变换。 |
| Infinite-width network | 无限宽度网络 | 指神经网络的隐藏层神经元数量趋于无限的情况。 |
| Neural Network Gaussian Process (NNGP) | 神经网络高斯过程 | 当神经网络的隐藏层宽度趋于无限时，其输出函数等同于一个高斯过程。 |
| Linearized model | 线性化模型 | 通过泰勒展开将复杂模型近似为线性形式，以简化其动力学分析。 |
| Lazy training | 惰性训练 | 在严重过参数化神经网络中，训练损失迅速收敛但网络参数变化极小的现象。 |
