# 基于流的深度生成模型

> Flow-based Deep Generative Models

> 来源：Lil'Log / Lilian Weng，2018-10-13
> 原文链接：https://lilianweng.github.io/posts/2018-10-13-flow-models/
> 分类：深度学习 / 生成模型

## 核心要点

- 基于流的深度生成模型通过归一化流明确学习真实数据的概率密度函数，解决了GAN和VAE无法直接计算密度函数的难题。
- 归一化流通过一系列可逆变换函数将一个简单分布转换为一个复杂分布，从而实现更好的密度估计。
- 基于流的生成模型以负对数似然作为损失函数进行训练。
- 理解雅可比行列式和变量变换定理是掌握基于流的生成模型的数学基础。
- RealNVP、NICE和Glow是典型的基于流的生成模型，它们利用仿射耦合层和可逆1x1卷积等技术构建可逆变换。
- 自回归流模型（如MAF和IAF）将流变换构建为自回归神经网络，其中每个维度都以前一个维度为条件。
- MADE、PixelRNN和WaveNet是经典的自回归模型，它们通过掩码或因果卷积实现序列依赖性。
- 归一化流可以与变分自编码器结合，用于建模更复杂的后验分布。

## 正文

到目前为止，我已经写了两种生成模型，[GAN](https://lilianweng.github.io/posts/2017-08-20-gan/) 和 [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/)。它们都没有明确学习真实数据的概率密度函数，$p(\mathbf{x})$（其中 $\mathbf{x} \in \mathcal{D}$）——因为这真的很难！以带有潜在变量的生成模型为例，$p(\mathbf{x}) = \int p(\mathbf{x}\vert\mathbf{z})p(\mathbf{z})d\mathbf{z}$ 几乎无法计算，因为遍历潜在代码 $\mathbf{z}$ 的所有可能值是难以处理的。

> So far, I’ve written about two types of generative models, [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/) and [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/). Neither of them explicitly learns the probability density function of real data, $p(\mathbf{x})$ (where $\mathbf{x} \in \mathcal{D}$) — because it is really hard! Taking the generative model with latent variables as an example, $p(\mathbf{x}) = \int p(\mathbf{x}\vert\mathbf{z})p(\mathbf{z})d\mathbf{z}$ can hardly be calculated as it is intractable to go through all possible values of the latent code $\mathbf{z}$.

基于流的深度生成模型借助 [归一化流](https://arxiv.org/abs/1505.05770) 解决了这个难题，归一化流是一种用于密度估计的强大统计工具。对 $p(\mathbf{x})$ 的良好估计使得高效完成许多下游任务成为可能：采样未观测但真实的新数据点（数据生成），预测未来事件的稀有性（密度估计），推断潜在变量，填充不完整的数据样本等。

> Flow-based deep generative models conquer this hard problem with the help of [normalizing flows](https://arxiv.org/abs/1505.05770), a powerful statistics tool for density estimation. A good estimation of $p(\mathbf{x})$ makes it possible to efficiently complete many downstream tasks: sample unobserved but realistic new data points (data generation), predict the rareness of future events (density estimation), infer latent variables, fill in incomplete data samples, etc.

### 生成模型的类型

> Types of Generative Models

以下是 GAN、VAE 和基于流的生成模型之间差异的快速总结：

> Here is a quick summary of the difference between GAN, VAE, and flow-based generative models:

1\. 生成对抗网络：GAN 提供了一种智能解决方案，将数据生成（一个无监督学习问题）建模为一个有监督问题。判别器模型学习区分真实数据和生成器模型产生的虚假样本。这两个模型在玩一场 [最小最大](https://en.wikipedia.org/wiki/Minimax) 博弈时进行训练。

2\. 变分自编码器：VAE 通过最大化证据下界（ELBO）来隐式优化数据的对数似然。

3\. 基于流的生成模型：基于流的生成模型通过一系列可逆变换构建。与其他两种模型不同，该模型明确学习数据分布 $p(\mathbf{x})$，因此损失函数就是负对数似然。

英文原文：

1\. Generative adversarial networks: GAN provides a smart solution to model the data generation, an unsupervised learning problem, as a supervised one. The discriminator model learns to distinguish the real data from the fake samples that are produced by the generator model. Two models are trained as they are playing a [minimax](https://en.wikipedia.org/wiki/Minimax) game.

2\. Variational autoencoders: VAE inexplicitly optimizes the log-likelihood of the data by maximizing the evidence lower bound (ELBO).

3\. Flow-based generative models: A flow-based generative model is constructed by a sequence of invertible transformations. Unlike other two, the model explicitly learns the data distribution $p(\mathbf{x})$ and therefore the loss function is simply the negative log-likelihood.

![Comparison of three categories of generative models.](https://lilianweng.github.io/posts/2018-10-13-flow-models/three-generative-models.png)

### 线性代数基础回顾

> Linear Algebra Basics Recap

在深入了解基于流的生成模型之前，我们应该理解两个关键概念：雅可比行列式和变量变换规则。这些内容非常基础，所以可以随意跳过。

> We should understand two key concepts before getting into the flow-based generative model: the Jacobian determinant and the change of variable rule. Pretty basic, so feel free to skip.

#### 雅可比矩阵和行列式

> Jacobian Matrix and Determinant

给定一个将 `n` 维输入向量 $\mathbf{x}$ 映射到 `m` 维输出向量 $\mathbf{f}: \mathbb{R}^n \mapsto \mathbb{R}^m$ 的函数，该函数所有一阶偏导数的矩阵称为 **雅可比矩阵**，$\mathbf{J}$ 其中第 i 行第 j 列的一个元素是 $\mathbf{J}_{ij} = \frac{\partial f_i}{\partial x_j}$。

英文原文：Given a function of mapping a `n` -dimensional input vector 

$\mathbf{x}$ to a `m` -dimensional output vector, 

$\mathbf{f}: \mathbb{R}^n \mapsto \mathbb{R}^m$, the matrix of all first-order partial derivatives of this function is called the Jacobian matrix, 

$\mathbf{J}$ where one entry on the i-th row and j-th column is 

$\mathbf{J}_{ij} = \frac{\partial f_i}{\partial x_j}$.

$$
\mathbf{J} = \begin{bmatrix}
\frac{\partial f_1}{\partial x_1} & \dots & \frac{\partial f_1}{\partial x_n} \\[6pt]
\vdots & \ddots & \vdots \\[6pt]
\frac{\partial f_m}{\partial x_1} & \dots & \frac{\partial f_m}{\partial x_n} \\[6pt]
\end{bmatrix}
$$

行列式是一个实数，它作为方阵中所有元素的函数计算。请注意，行列式*仅存在于**方阵***中。行列式的绝对值可以被认为是衡量*“矩阵乘法在多大程度上扩展或收缩空间”*的度量。

> The determinant is one real number computed as a function of all the elements in a squared matrix. Note that the determinant *only exists for **square** matrices*. The absolute value of the determinant can be thought of as a measure of *“how much multiplication by the matrix expands or contracts space”.*

一个 nxn 矩阵 $M$ 的行列式是：

> The determinant of a nxn matrix $M$ is:

$$
\det M = \det \begin{bmatrix}
a_{11} & a_{12} & \dots & a_{1n} \\
a_{21} & a_{22} & \dots & a_{2n} \\
\vdots & \vdots & & \vdots \\
a_{n1} & a_{n2} & \dots & a_{nn} \\
\end{bmatrix} = \sum_{j_1 j_2 \dots j_n} (-1)^{\tau(j_1 j_2 \dots j_n)} a_{1j_1} a_{2j_2} \dots a_{nj_n}
$$

其中求和符号 $j_1 j_2 \dots j_n$ 下的下标是集合 {1, 2, …, n} 的所有排列，因此总共有 $n!$ 项；$\tau(.)$ 表示排列的 [符号](https://en.wikipedia.org/wiki/Parity_of_a_permutation)。

> where the subscript under the summation $j_1 j_2 \dots j_n$ are all permutations of the set {1, 2, …, n}, so there are $n!$ items in total; $\tau(.)$ indicates the [signature](https://en.wikipedia.org/wiki/Parity_of_a_permutation) of a permutation.

方阵 $M$ 的行列式可以判断它是否可逆：如果 $\det(M)=0$，则 $M$ 不可逆（一个*奇异*矩阵，其行或列线性相关；或任何行或列全为 0）；否则，如果 $\det(M)\neq 0$，则 $M$ 可逆。

> The determinant of a square matrix $M$ detects whether it is invertible: If $\det(M)=0$ then $M$ is not invertible (a *singular* matrix with linearly dependent rows or columns; or any row or column is all 0); otherwise, if $\det(M)\neq 0$, $M$ is invertible.

乘积的行列式等于行列式的乘积：$\det(AB) = \det(A)\det(B)$。（[证明](https://proofwiki.org/wiki/Determinant_of_Matrix_Product)）

> The determinant of the product is equivalent to the product of the determinants: $\det(AB) = \det(A)\det(B)$. ([proof](https://proofwiki.org/wiki/Determinant_of_Matrix_Product))

#### 变量变换定理

> Change of Variable Theorem

让我们回顾一下变量变换定理，特别是在概率密度估计的背景下，从单变量情况开始。

> Let’s review the change of variable theorem specifically in the context of probability density estimation, starting with a single variable case.

给定一个随机变量 $z$ 及其已知的概率密度函数 $z \sim \pi(z)$，我们希望使用一个一对一映射函数 $x = f(z)$ 来构建一个新的随机变量。函数 $f$ 是可逆的，因此 $z=f^{-1}(x)$。现在的问题是*如何推断新变量的未知概率密度函数*，$p(x)$？

> Given a random variable $z$ and its known probability density function $z \sim \pi(z)$, we would like to construct a new random variable using a 1-1 mapping function $x = f(z)$. The function $f$ is invertible, so $z=f^{-1}(x)$. Now the question is *how to infer the unknown probability density function of the new variable*, $p(x)$?

$$
\begin{aligned}
& \int p(x)dx = \int \pi(z)dz = 1 \scriptstyle{\text{   ; Definition of probability distribution.}}\\
& p(x) = \pi(z) \left\vert\frac{dz}{dx}\right\vert = \pi(f^{-1}(x)) \left\vert\frac{d f^{-1}}{dx}\right\vert = \pi(f^{-1}(x)) \vert (f^{-1})'(x) \vert
\end{aligned}
$$

根据定义，积分 $\int \pi(z)dz$ 是无限多个无穷小宽度 $\Delta z$ 矩形面积之和。在位置 $z$ 处，这种矩形的高度是密度函数 $\pi(z)$ 的值。当我们替换变量时，$z = f^{-1}(x)$ 得到 $\frac{\Delta z}{\Delta x} = (f^{-1}(x))’$ 和 $\Delta z = (f^{-1}(x))’ \Delta x$。这里 $\vert(f^{-1}(x))’\vert$ 表示在变量 $z$ 和 $x$ 的两个不同坐标系中定义的矩形面积之比。

> By definition, the integral $\int \pi(z)dz$ is the sum of an infinite number of rectangles of infinitesimal width $\Delta z$. The height of such a rectangle at position $z$ is the value of the density function $\pi(z)$. When we substitute the variable, $z = f^{-1}(x)$ yields $\frac{\Delta z}{\Delta x} = (f^{-1}(x))’$ and $\Delta z = (f^{-1}(x))’ \Delta x$. Here $\vert(f^{-1}(x))’\vert$ indicates the ratio between the area of rectangles defined in two different coordinate of variables $z$ and $x$ respectively.

多变量版本具有类似的格式：

> The multivariable version has a similar format:

$$
\begin{aligned}
\mathbf{z} &\sim \pi(\mathbf{z}), \mathbf{x} = f(\mathbf{z}), \mathbf{z} = f^{-1}(\mathbf{x}) \\
p(\mathbf{x}) 
&= \pi(\mathbf{z}) \left\vert \det \dfrac{d \mathbf{z}}{d \mathbf{x}} \right\vert  
= \pi(f^{-1}(\mathbf{x})) \left\vert \det \dfrac{d f^{-1}}{d \mathbf{x}} \right\vert
\end{aligned}
$$

其中 $\det \frac{\partial f}{\partial\mathbf{z}}$ 是函数 $f$ 的雅可比行列式。多变量版本的完整证明超出了本文的范围；如果感兴趣可以问问 Google ;)

> where $\det \frac{\partial f}{\partial\mathbf{z}}$ is the Jacobian determinant of the function $f$. The full proof of the multivariate version is out of the scope of this post; ask Google if interested ;)

### 什么是归一化流？

> What is Normalizing Flows?

能够进行良好的密度估计在许多机器学习问题中都有直接应用，但这非常困难。例如，由于我们需要在深度学习模型中运行反向传播，因此嵌入的概率分布（即后验 $p(\mathbf{z}\vert\mathbf{x})$）需要足够简单，以便轻松高效地计算导数。这就是为什么在潜在变量生成模型中经常使用高斯分布，尽管大多数真实世界的分布比高斯分布复杂得多。

> Being able to do good density estimation has direct applications in many machine learning problems, but it is very hard. For example, since we need to run backward propagation in deep learning models, the embedded probability distribution (i.e. posterior $p(\mathbf{z}\vert\mathbf{x})$) is expected to be simple enough to calculate the derivative easily and efficiently. That is why Gaussian distribution is often used in latent variable generative models, even though most of real world distributions are much more complicated than Gaussian.

这里介绍一种 **归一化流**（NF）模型，用于更好、更强大的分布近似。归一化流通过应用一系列可逆变换函数，将一个简单分布转换为一个复杂分布。通过一系列变换，我们根据变量变换定理反复用新变量替换旧变量，最终获得最终目标变量的概率分布。

> Here comes a **Normalizing Flow** (NF) model for better and more powerful distribution approximation. A normalizing flow transforms a simple distribution into a complex one by applying a sequence of invertible transformation functions. Flowing through a chain of transformations, we repeatedly substitute the variable for the new one according to the change of variables theorem and eventually obtain a probability distribution of the final target variable.

![Illustration of a normalizing flow model, transforming a simple distribution $p\_0(\mathbf{z}\_0)$ to a complex one $p\_K(\mathbf{z}\_K)$ step by step.](https://lilianweng.github.io/posts/2018-10-13-flow-models/normalizing-flow.png)

如图 2 所示，

> As defined in Fig. 2,

$$
\begin{aligned}
\mathbf{z}_{i-1} &\sim p_{i-1}(\mathbf{z}_{i-1}) \\
\mathbf{z}_i &= f_i(\mathbf{z}_{i-1})\text{, thus }\mathbf{z}_{i-1} = f_i^{-1}(\mathbf{z}_i) \\
p_i(\mathbf{z}_i) 
&= p_{i-1}(f_i^{-1}(\mathbf{z}_i)) \left\vert \det\dfrac{d f_i^{-1}}{d \mathbf{z}_i} \right\vert
\end{aligned}
$$

然后，我们将方程转换为 $\mathbf{z}_i$ 的函数，以便我们可以使用基础分布进行推断。

> Then let’s convert the equation to be a function of $\mathbf{z}_i$ so that we can do inference with the base distribution.

$$
\begin{aligned}
p_i(\mathbf{z}_i) 
&= p_{i-1}(f_i^{-1}(\mathbf{z}_i)) \left\vert \det\dfrac{d f_i^{-1}}{d \mathbf{z}_i} \right\vert \\
&= p_{i-1}(\mathbf{z}_{i-1}) \left\vert \det \color{red}{\Big(\dfrac{d f_i}{d\mathbf{z}_{i-1}}\Big)^{-1}} \right\vert & \scriptstyle{\text{; According to the inverse func theorem.}} \\
&= p_{i-1}(\mathbf{z}_{i-1}) \color{red}{\left\vert \det \dfrac{d f_i}{d\mathbf{z}_{i-1}} \right\vert^{-1}} & \scriptstyle{\text{; According to a property of Jacobians of invertible func.}} \\
\log p_i(\mathbf{z}_i) &= \log p_{i-1}(\mathbf{z}_{i-1}) - \log \left\vert \det \dfrac{d f_i}{d\mathbf{z}_{i-1}} \right\vert
\end{aligned}
$$

(*) 关于*“反函数定理”*的注释：如果 $y=f(x)$ 且 $x=f^{-1}(y)$，我们有：

> (*) A note on the *“inverse function theorem”*: If $y=f(x)$ and $x=f^{-1}(y)$, we have:

$$
\dfrac{df^{-1}(y)}{dy} = \dfrac{dx}{dy} = (\dfrac{dy}{dx})^{-1} = (\dfrac{df(x)}{dx})^{-1}
$$

(*) 关于*“可逆函数的雅可比”*的注释：可逆矩阵的逆的行列式是行列式的逆：$\det(M^{-1}) = (\det(M))^{-1}$，[因为](https://lilianweng.github.io/posts/2018-10-13-flow-models/#jacobian-matrix-and-determinant) $\det(M)\det(M^{-1}) = \det(M \cdot M^{-1}) = \det(I) = 1$。

> (*) A note on *“Jacobians of invertible function”*: The determinant of the inverse of an invertible matrix is the inverse of the determinant: $\det(M^{-1}) = (\det(M))^{-1}$, [because](https://lilianweng.github.io/posts/2018-10-13-flow-models/#jacobian-matrix-and-determinant) $\det(M)\det(M^{-1}) = \det(M \cdot M^{-1}) = \det(I) = 1$.

给定这样一串概率密度函数，我们知道每对连续变量之间的关系。我们可以逐步展开输出 $\mathbf{x}$ 的方程，直到追溯到初始分布 $\mathbf{z}_0$。

> Given such a chain of probability density functions, we know the relationship between each pair of consecutive variables. We can expand the equation of the output $\mathbf{x}$ step by step until tracing back to the initial distribution $\mathbf{z}_0$.

$$
\begin{aligned}
\mathbf{x} = \mathbf{z}_K &= f_K \circ f_{K-1} \circ \dots \circ f_1 (\mathbf{z}_0) \\
\log p(\mathbf{x}) = \log \pi_K(\mathbf{z}_K) 
&= \log \pi_{K-1}(\mathbf{z}_{K-1}) - \log\left\vert\det\dfrac{d f_K}{d \mathbf{z}_{K-1}}\right\vert \\
&= \log \pi_{K-2}(\mathbf{z}_{K-2}) - \log\left\vert\det\dfrac{d f_{K-1}}{d\mathbf{z}_{K-2}}\right\vert - \log\left\vert\det\dfrac{d f_K}{d\mathbf{z}_{K-1}}\right\vert \\
&= \dots \\
&= \log \pi_0(\mathbf{z}_0) - \sum_{i=1}^K \log\left\vert\det\dfrac{d f_i}{d\mathbf{z}_{i-1}}\right\vert
\end{aligned}
$$

随机变量 $\mathbf{z}_i = f_i(\mathbf{z}_{i-1})$ 遍历的路径是 **流**，由连续分布 `\pi_i` 形成的完整链称为 **归一化流**。根据方程中的计算要求，变换函数 `f_i` 应满足两个属性：

英文原文：The path traversed by the random variables 

$\mathbf{z}_i = f_i(\mathbf{z}_{i-1})$ is the flow and the full chain formed by the successive distributions `\pi_i` is called a normalizing flow. Required by the computation in the equation, a transformation function `f_i` should satisfy two properties:

1. 它易于可逆。
2. 它的雅可比行列式易于计算。

> • It is easily invertible.
> • Its Jacobian determinant is easy to compute.

### 带有归一化流的模型

> Models with Normalizing Flows

有了归一化流这个工具，输入数据 $\log p(\mathbf{x})$ 的精确对数似然变得可处理。因此，基于流的生成模型的训练准则就是训练数据集 $\mathcal{D}$ 上的负对数似然（NLL）：

> With normalizing flows in our toolbox, the exact log-likelihood of input data $\log p(\mathbf{x})$ becomes tractable. As a result, the training criterion of flow-based generative model is simply the negative log-likelihood (NLL) over the training dataset $\mathcal{D}$:

$$
\mathcal{L}(\mathcal{D}) = - \frac{1}{\vert\mathcal{D}\vert}\sum_{\mathbf{x} \in \mathcal{D}} \log p(\mathbf{x})
$$

#### RealNVP

> RealNVP

**RealNVP**（Real-valued Non-Volume Preserving；[Dinh 等人，2017](https://arxiv.org/abs/1605.08803)）模型通过堆叠一系列可逆双射变换函数来实现归一化流。在每个双射 $f: \mathbf{x} \mapsto \mathbf{y}$ 中，被称为*仿射耦合层*，输入维度被分成两部分：

英文原文：The RealNVP (Real-valued Non-Volume Preserving; [Dinh et al., 2017](https://arxiv.org/abs/1605.08803)) model implements a normalizing flow by stacking a sequence of invertible bijective transformation functions. In each bijection 

$f: \mathbf{x} \mapsto \mathbf{y}$, known as *affine coupling layer*,  the input dimensions are split into two parts:

• 前 $d$ 个维度保持不变；

• 第二部分，从 $d+1$ 到 $D$ 维度，经历一个仿射变换（“缩放和平移”），并且缩放和平移参数都是前 $d$ 个维度的函数。

英文原文：

• The first $d$ dimensions stay same;

• The second part, $d+1$ to $D$ dimensions, undergo an affine transformation (“scale-and-shift”) and both the scale and shift parameters are functions of the first $d$ dimensions.

$$
\begin{aligned}
\mathbf{y}_{1:d} &= \mathbf{x}_{1:d} \\ 
\mathbf{y}_{d+1:D} &= \mathbf{x}_{d+1:D} \odot \exp({s(\mathbf{x}_{1:d})}) + t(\mathbf{x}_{1:d})
\end{aligned}
$$

其中 $s(.)$ 和 $t(.)$ 是*缩放*和*平移*函数，两者都映射 $\mathbb{R}^d \mapsto \mathbb{R}^{D-d}$。$\odot$ 运算是逐元素乘积。

> where $s(.)$ and $t(.)$ are *scale* and *translation* functions and both map $\mathbb{R}^d \mapsto \mathbb{R}^{D-d}$. The $\odot$ operation is the element-wise product.

现在我们来检查这个变换是否满足流变换的两个基本属性。

> Now let’s check whether this transformation satisfy two basic properties  for a flow transformation.

**条件 1**：“它易于可逆。”

> **Condition 1**: “It is easily invertible.”

是的，这相当直接。

> Yes and it is fairly straightforward.

$$
\begin{cases}
\mathbf{y}_{1:d} &= \mathbf{x}_{1:d} \\ 
\mathbf{y}_{d+1:D} &= \mathbf{x}_{d+1:D} \odot \exp({s(\mathbf{x}_{1:d})}) + t(\mathbf{x}_{1:d})
\end{cases}
\Leftrightarrow 
\begin{cases}
\mathbf{x}_{1:d} &= \mathbf{y}_{1:d} \\ 
\mathbf{x}_{d+1:D} &= (\mathbf{y}_{d+1:D} - t(\mathbf{y}_{1:d})) \odot \exp(-s(\mathbf{y}_{1:d}))
\end{cases}
$$

**条件 2**：“它的雅可比行列式易于计算。”

> **Condition 2**: “Its Jacobian determinant is easy to compute.”

是的。计算这个变换的雅可比矩阵和行列式并不难。雅可比矩阵是一个下三角矩阵。

> Yes. It is not hard to get the Jacobian matrix and determinant of this transformation. The Jacobian is a lower triangular matrix.

$$
\mathbf{J} = 
\begin{bmatrix}
  \mathbb{I}_d & \mathbf{0}_{d\times(D-d)} \\[5pt]
  \frac{\partial \mathbf{y}_{d+1:D}}{\partial \mathbf{x}_{1:d}} & \text{diag}(\exp(s(\mathbf{x}_{1:d})))
\end{bmatrix}
$$

因此，行列式就是对角线上各项的乘积。

> Hence the determinant is simply the product of terms on the diagonal.

$$
\det(\mathbf{J}) 
= \prod_{j=1}^{D-d}\exp(s(\mathbf{x}_{1:d}))_j
= \exp(\sum_{j=1}^{D-d} s(\mathbf{x}_{1:d})_j)
$$

到目前为止，仿射耦合层看起来非常适合构建归一化流 :)

> So far, the affine coupling layer looks perfect for constructing a normalizing flow :)

更好的是，由于 (i) 计算 $f^-1$ 不需要计算 $s$ 或 $t$ 的逆，并且 (ii) 计算雅可比行列式不涉及计算 $s$ 或 $t$ 的雅可比，因此这些函数可以是*任意复杂的*；即 $s$ 和 $t$ 都可以通过深度神经网络建模。

> Even better, since (i) computing $f^-1$ does not require computing the inverse of $s$ or $t$ and (ii) computing the Jacobian determinant does not involve computing the Jacobian of $s$ or $t$, those functions can be *arbitrarily complex*; i.e. both $s$ and $t$ can be modeled by deep neural networks.

在一个仿射耦合层中，一些维度（通道）保持不变。为了确保所有输入都有机会被改变，模型在每一层中反转排序，以便不同的组件保持不变。遵循这种交替模式，在一个变换层中保持相同的单元集总是在下一个变换层中被修改。批归一化被发现有助于训练具有非常深耦合层堆栈的模型。

> In one affine coupling layer, some dimensions (channels) remain unchanged. To make sure all the inputs have a chance to be altered, the model reverses the ordering in each layer so that different components are left unchanged. Following such an alternating pattern, the set of units which remain identical in one transformation layer are always modified in the next. Batch normalization is found to help training models with a very deep stack of coupling layers.

此外，RealNVP 可以在多尺度架构中工作，为大型输入构建更高效的模型。多尺度架构对普通仿射层应用了多种“采样”操作，包括空间棋盘格模式掩码、挤压操作和通道式掩码。阅读[论文](https://arxiv.org/abs/1605.08803)以获取有关多尺度架构的更多详细信息。

> Furthermore, RealNVP can work in a multi-scale architecture to build a more efficient model for large inputs. The multi-scale architecture applies several “sampling” operations to normal affine layers, including spatial checkerboard pattern masking, squeezing operation, and channel-wise masking. Read the [paper](https://arxiv.org/abs/1605.08803) for more details on the multi-scale architecture.

#### NICE

> NICE

**NICE**（非线性独立分量估计；[Dinh 等人，2015](https://arxiv.org/abs/1410.8516)）模型是 [RealNVP](https://lilianweng.github.io/posts/2018-10-13-flow-models/#realnvp) 的前身。NICE 中的变换是没有尺度项的仿射耦合层，被称为*加性耦合层*。

> The **NICE** (Non-linear Independent Component Estimation; [Dinh, et al. 2015](https://arxiv.org/abs/1410.8516)) model is a predecessor of [RealNVP](https://lilianweng.github.io/posts/2018-10-13-flow-models/#realnvp). The transformation in NICE is the affine coupling layer without the scale term, known as *additive coupling layer*.

$$
\begin{cases}
\mathbf{y}_{1:d} &= \mathbf{x}_{1:d} \\ 
\mathbf{y}_{d+1:D} &= \mathbf{x}_{d+1:D} + m(\mathbf{x}_{1:d})
\end{cases}
\Leftrightarrow 
\begin{cases}
\mathbf{x}_{1:d} &= \mathbf{y}_{1:d} \\ 
\mathbf{x}_{d+1:D} &= \mathbf{y}_{d+1:D} - m(\mathbf{y}_{1:d})
\end{cases}
$$

#### Glow

> Glow

**Glow**（[Kingma 和 Dhariwal，2018](https://arxiv.org/abs/1807.03039)）模型扩展了之前的可逆生成模型 NICE 和 RealNVP，并通过用可逆的 1x1 卷积替换通道排序上的逆置换操作来简化架构。

> The **Glow** ([Kingma and Dhariwal, 2018](https://arxiv.org/abs/1807.03039)) model extends the previous reversible generative models, NICE and RealNVP, and simplifies the architecture by replacing the reverse permutation operation on the channel ordering with invertible 1x1 convolutions.

![One step of flow in the Glow model. (Image source: Kingma and Dhariwal, 2018 )](https://lilianweng.github.io/posts/2018-10-13-flow-models/one-glow-step.png)

Glow 的一个流步骤中有三个子步骤。

> There are three substeps in one step of flow in Glow.

子步骤 1：**激活归一化**（“actnorm”的缩写）

> Substep 1: **Activation normalization** (short for “actnorm”)

它使用每个通道的尺度和偏置参数执行仿射变换，类似于批归一化，但适用于迷你批次大小为 1 的情况。这些参数是可训练的，但经过初始化，使得第一批迷你批次数据在 actnorm 之后具有均值 0 和标准差 1。

> It performs an affine transformation using a scale and bias parameter per channel, similar to batch normalization, but works for mini-batch size 1. The parameters are trainable but initialized so that the first minibatch of data have mean 0 and standard deviation 1 after actnorm.

子步骤 2：**可逆 1x1 卷积**

> Substep 2: **Invertible 1x1 conv**

在 RealNVP 流的层之间，通道的顺序被反转，以便所有数据维度都有机会被改变。输入和输出通道数量相等的 1×1 卷积是 *任何置换的泛化* 通道顺序的。

> Between layers of the RealNVP flow, the ordering of channels is reversed so that all the data dimensions have a chance to be altered. A 1×1 convolution with equal number of input and output channels is *a generalization of any permutation* of the channel ordering.

假设我们有一个输入$h \times w \times c$张量$\mathbf{h}$的可逆1x1卷积，其权重矩阵$\mathbf{W}$的大小为$c \times c$。输出是一个$h \times w \times c$张量，标记为$f = \texttt{conv2d}(\mathbf{h}; \mathbf{W})$。为了应用变量变换规则，我们需要计算雅可比行列式$\vert \det\partial f / \partial\mathbf{h}\vert$。

> Say, we have an invertible 1x1 convolution of an input $h \times w \times c$ tensor $\mathbf{h}$ with a weight matrix $\mathbf{W}$ of size $c \times c$. The output is a $h \times w \times c$ tensor, labeled as $f = \texttt{conv2d}(\mathbf{h}; \mathbf{W})$. In order to apply the change of variable rule, we need to compute the Jacobian determinant $\vert \det\partial f / \partial\mathbf{h}\vert$.

这里1x1卷积的输入和输出都可以看作是一个大小为$h \times w$的矩阵。其中每个条目$\mathbf{x}_{ij}$（$i=1,\dots,h, j=1,\dots,w$）在$\mathbf{h}$中是一个包含$c$个通道的向量，并且每个条目都乘以权重矩阵$\mathbf{W}$以分别获得输出矩阵中的对应条目$\mathbf{y}_{ij}$。每个条目的导数是$\partial \mathbf{x}_{ij} \mathbf{W} / \partial\mathbf{x}_{ij} = \mathbf{W}$，总共有$h \times w$个这样的条目：

> Both the input and output of 1x1 convolution here can be viewed as a matrix of size $h \times w$. Each entry $\mathbf{x}_{ij}$ ($i=1,\dots,h, j=1,\dots,w$) in $\mathbf{h}$ is a vector of $c$ channels and each entry is multiplied by the weight matrix $\mathbf{W}$ to obtain the corresponding entry $\mathbf{y}_{ij}$ in the output matrix respectively. The derivative of each entry is $\partial \mathbf{x}_{ij} \mathbf{W} / \partial\mathbf{x}_{ij} = \mathbf{W}$ and there are $h \times w$ such entries in total:

$$
\log \left\vert\det \frac{\partial\texttt{conv2d}(\mathbf{h}; \mathbf{W})}{\partial\mathbf{h}}\right\vert
= \log (\vert\det\mathbf{W}\vert^{h \cdot w}\vert) = h \cdot w \cdot \log \vert\det\mathbf{W}\vert
$$

1x1逆卷积取决于逆矩阵$\mathbf{W}^{-1}$。由于权重矩阵相对较小，因此矩阵行列式（[tf.linalg.det](https://www.tensorflow.org/api_docs/python/tf/linalg/det)）和求逆（[tf.linalg.inv](https://www.tensorflow.org/api_docs/python/tf/linalg/inv)）的计算量仍在控制之中。

> The inverse 1x1 convolution depends on the inverse matrix $\mathbf{W}^{-1}$. Since the weight matrix is relatively small, the amount of computation for the matrix determinant ([tf.linalg.det](https://www.tensorflow.org/api_docs/python/tf/linalg/det)) and inversion ([tf.linalg.inv](https://www.tensorflow.org/api_docs/python/tf/linalg/inv)) is still under control.

子步骤3：**仿射耦合层**

> Substep 3: **Affine coupling layer**

其设计与RealNVP中的相同。

> The design is same as in RealNVP.

![Three substeps in one step of flow in Glow. (Image source: Kingma and Dhariwal, 2018 )](https://lilianweng.github.io/posts/2018-10-13-flow-models/glow-table.png)

### 自回归流模型

> Models with Autoregressive Flows

**自回归**约束是一种对序列数据进行建模的方式，$\mathbf{x} = [x_1, \dots, x_D]$：每个输出只依赖于过去观察到的数据，而不依赖于未来的数据。换句话说，观察到`x_i`的概率是以$x_1, \dots, x_{i-1}$为条件的，并且这些条件概率的乘积给出了观察到完整序列的概率：

英文原文：The autoregressive constraint is a way to model sequential data, 

$\mathbf{x} = [x_1, \dots, x_D]$: each output only depends on the data observed in the past, but not on the future ones. In other words, the probability of observing `x_i` is conditioned on 

$x_1, \dots, x_{i-1}$ and the product of these conditional probabilities gives us the probability of observing the full sequence:

$$
p(\mathbf{x}) = \prod_{i=1}^{D} p(x_i\vert x_1, \dots, x_{i-1}) = \prod_{i=1}^{D} p(x_i\vert x_{1:i-1})
$$

如何对条件密度进行建模由您选择。它可以是单变量高斯分布，其均值和标准差是$x_{1:i-1}$的函数，也可以是多层神经网络，以$x_{1:i-1}$作为输入。

> How to model the conditional density is of your choice. It can be a univariate Gaussian with mean and standard deviation computed as a function of $x_{1:i-1}$, or a multilayer neural network with $x_{1:i-1}$ as the input.

如果归一化流中的流变换被构造成一个自回归模型——向量变量中的每个维度都以前一个维度为条件——这就是一个**自回归流**。

> If a flow transformation in a normalizing flow is framed as an autoregressive model — each dimension in a vector variable is conditioned on the previous dimensions — this is an **autoregressive flow**.

本节首先介绍了几种经典的自回归模型（MADE、PixelRNN、WaveNet），然后深入探讨了自回归流模型（MAF和IAF）。

> This section starts with several classic autoregressive models (MADE, PixelRNN, WaveNet) and then we dive into autoregressive flow models (MAF and IAF).

#### MADE

> MADE

**MADE**（用于分布估计的掩码自编码器；[Germain et al., 2015](https://arxiv.org/abs/1502.03509)）是一种专门设计的架构，用于在自编码器中*高效地*强制执行自回归属性。当使用自编码器预测条件概率时，MADE不是通过向自编码器输入不同观测窗口的输入`D` 次，而是通过乘以二值掩码矩阵来消除某些隐藏单元的贡献，从而使每个输入维度仅从先前的维度中以*给定*的顺序在*单次通过*中重建。

英文原文：MADE (Masked Autoencoder for Distribution Estimation; [Germain et al., 2015](https://arxiv.org/abs/1502.03509)) is a specially designed architecture to enforce the autoregressive property in the autoencoder *efficiently*. When using an autoencoder to predict the conditional probabilities, rather than feeding the autoencoder with input of different observation windows `D` times, MADE removes the contribution from certain hidden units by multiplying binary mask matrices so that each input dimension is reconstructed only from previous dimensions in a *given* ordering in a *single pass*.

假设在一个多层全连接神经网络中，我们有$L$ 个隐藏层，其权重矩阵为$\mathbf{W}^1, \dots, \mathbf{W}^L$，以及一个输出层，其权重矩阵为$\mathbf{V}$。输出$\hat{\mathbf{x}}$ 的每个维度为$\hat{x}_i = p(x_i\vert x_{1:i-1})$。

> In a multilayer fully-connected neural network, say, we have $L$ hidden layers with weight matrices $\mathbf{W}^1, \dots, \mathbf{W}^L$ and an output layer with weight matrix $\mathbf{V}$. The output $\hat{\mathbf{x}}$ has each dimension $\hat{x}_i = p(x_i\vert x_{1:i-1})$.

在没有任何掩码的情况下，通过层的计算如下所示：

> Without any mask, the computation through layers looks like the following:

$$
\begin{aligned}
\mathbf{h}^0 &= \mathbf{x} \\
\mathbf{h}^l &= \text{activation}^l(\mathbf{W}^l\mathbf{h}^{l-1} + \mathbf{b}^l) \\
\hat{\mathbf{x}} &= \sigma(\mathbf{V}\mathbf{h}^L + \mathbf{c})
\end{aligned}
$$

![Demonstration of how MADE works in a three-layer feed-forward neural network. (Image source: Germain et al., 2015 )](https://lilianweng.github.io/posts/2018-10-13-flow-models/MADE.png)

为了将层之间的一些连接归零，我们可以简单地将每个权重矩阵与一个二值掩码矩阵进行逐元素相乘。每个隐藏节点都被分配一个介于$1$ 和 $D-1$ 之间的随机“连接整数”；第$k$ 个单元在第$l$ 层中的赋值表示为$m^l_k$。二值掩码矩阵是通过逐元素比较两层中两个节点的值来确定的。

> To zero out some connections between layers, we can simply element-wise multiply every weight matrix by a binary mask matrix. Each hidden node is assigned with a random “connectivity integer” between $1$ and $D-1$; the assigned value for the $k$ -th unit in the $l$ -th layer is denoted by $m^l_k$. The binary mask matrix is determined by element-wise comparing values of two nodes in two layers.

$$
\begin{aligned}
\mathbf{h}^l &= \text{activation}^l((\mathbf{W}^l \color{red}{\odot \mathbf{M}^{\mathbf{W}^l}}) \mathbf{h}^{l-1} + \mathbf{b}^l) \\
\hat{\mathbf{x}} &= \sigma((\mathbf{V} \color{red}{\odot \mathbf{M}^{\mathbf{V}}}) \mathbf{h}^L + \mathbf{c}) \\
M^{\mathbf{W}^l}_{k', k} 
&= \mathbf{1}_{m^l_{k'} \geq m^{l-1}_k} 
= \begin{cases}
    1, & \text{if } m^l_{k'} \geq m^{l-1}_k\\
    0, & \text{otherwise}
\end{cases} \\
M^{\mathbf{V}}_{d, k} 
&= \mathbf{1}_{d \geq m^L_k} 
= \begin{cases}
    1, & \text{if } d > m^L_k\\
    0, & \text{otherwise}
\end{cases}
\end{aligned}
$$

当前层中的一个单元只能连接到前一层中编号相等或更小的其他单元，这种依赖关系很容易通过网络传播到输出层。一旦所有单元和层都分配了编号，输入维度的顺序就固定了，并据此生成条件概率。有关详细说明，请参阅为了确保所有隐藏单元通过某些路径连接到输入和输出层，$m^l_k$ 被采样为等于或大于前一层中的最小连接整数 $\min_{k’} m_{k’}^{l-1}$。

> A unit in the current layer can only be connected to other units with equal or smaller numbers in the previous layer and this type of dependency easily propagates through the network up to the output layer. Once the numbers are assigned to all the units and layers, the ordering of input dimensions is fixed and the conditional probability is produced with respect to it.  See a great illustration in To make sure all the hidden units are connected to the input and output layers through some paths, the $m^l_k$ is sampled to be equal or greater than the minimal connectivity integer in the previous layer, $\min_{k’} m_{k’}^{l-1}$.

MADE 训练可以通过以下方式进一步促进：

> MADE training can be further facilitated by:

• *顺序无关训练*：打乱输入维度，使 MADE 能够模拟任何任意顺序；可以在运行时创建自回归模型的集成。

• *连接无关训练*：为避免模型受限于特定的连接模式约束，为每个训练小批量重新采样 $m^l_k$。

英文原文：

• *Order-agnostic training*: shuffle the input dimensions, so that MADE is able to model any arbitrary ordering; can create an ensemble of autoregressive models at the runtime.

• *Connectivity-agnostic training*: to avoid a model being tied up to a specific connectivity pattern constraints, resample $m^l_k$ for each training minibatch.

#### PixelRNN

> PixelRNN

PixelRNN ([Oord et al, 2016](https://arxiv.org/abs/1601.06759)) 是一种深度生成模型，用于图像生成。图像逐像素生成，每个新像素的采样都以前面已生成的像素为条件。

> PixelRNN ([Oord et al, 2016](https://arxiv.org/abs/1601.06759)) is a deep generative model for images. The image is generated one pixel at a time and each new pixel is sampled conditional on the pixels that have been seen before.

让我们考虑一张大小为 $n \times n$, $\mathbf{x} = \{x_1, \dots, x_{n^2}\}$ 的图像，模型从左上角开始生成像素，从左到右，从上到下（参见图 6）。

> Let’s consider an image of size $n \times n$, $\mathbf{x} = \{x_1, \dots, x_{n^2}\}$, the model starts generating pixels from the top left corner, from left to right and top to bottom (See Fig. 6).

![The context for generating one pixel in PixelRNN. (Image source: Oord et al, 2016 )](https://lilianweng.github.io/posts/2018-10-13-flow-models/pixel-rnn-context.png)

每个像素 $x_i$ 都是从一个概率分布中采样的，该分布以过去的上下文为条件：即其上方的像素或同一行中其左侧的像素。这种上下文的定义看起来相当随意，因为视觉 [注意力](https://lilianweng.github.io/posts/2018-06-24-attention/) 如何关注图像是更灵活的。然而，一个具有如此强假设的生成模型却奇迹般地奏效了。

> Every pixel $x_i$ is sampled from a probability distribution conditional over the the past context: pixels above it or on the left of it when in the same row. The definition of such context looks pretty arbitrary, because how visual [attention](https://lilianweng.github.io/posts/2018-06-24-attention/) is attended to an image is more flexible. Somehow magically a generative model with such a strong assumption works.

一种可以捕获整个上下文的实现是 *对角线双向 LSTM*。首先，通过将输入特征图的每一行相对于前一行偏移一个位置来应用 **倾斜** 操作，以便可以并行化每一行的计算。然后，LSTM 状态是根据当前像素及其左侧像素计算的。

> One implementation that could capture the entire context is the *Diagonal BiLSTM*. First, apply the **skewing** operation by offsetting each row of the input feature map by one position with respect to the previous row, so that computation for each row can be parallelized. Then the LSTM states are computed with respect to the current pixel and the pixels on the left.

![(a) PixelRNN with diagonal BiLSTM. (b) Skewing operation that offsets each row in the feature map by one with regards to the row above. (Image source: Oord et al, 2016 )](https://lilianweng.github.io/posts/2018-10-13-flow-models/diagonal-biLSTM.png)

$$
\begin{aligned}
\lbrack \mathbf{o}_i, \mathbf{f}_i, \mathbf{i}_i, \mathbf{g}_i \rbrack &= \sigma(\mathbf{K}^{ss} \circledast \mathbf{h}_{i-1} + \mathbf{K}^{is} \circledast \mathbf{x}_i) & \scriptstyle{\text{; }\sigma\scriptstyle{\text{ is tanh for g, but otherwise sigmoid; }}\circledast\scriptstyle{\text{ is convolution operation.}}} \\
\mathbf{c}_i &= \mathbf{f}_i \odot \mathbf{c}_{i-1} + \mathbf{i}_i \odot \mathbf{g}_i & \scriptstyle{\text{; }}\odot\scriptstyle{\text{ is elementwise product.}}\\
\mathbf{h}_i &= \mathbf{o}_i \odot \tanh(\mathbf{c}_i)
\end{aligned}
$$

其中 $\circledast$ 表示卷积操作，$\odot$ 是逐元素乘法。输入到状态的组件 $\mathbf{K}^{is}$ 是一个 1x1 卷积，而状态到状态的循环组件是通过一个核大小为 2x1 的列式卷积 $\mathbf{K}^{ss}$ 计算的。

> where $\circledast$ denotes the convolution operation and $\odot$ is the element-wise multiplication. The input-to-state component $\mathbf{K}^{is}$ is a 1x1 convolution, while the state-to-state recurrent component is computed with a column-wise convolution $\mathbf{K}^{ss}$ with a kernel of size 2x1.

对角线双向 LSTM 层能够处理无边界的上下文区域，但由于状态之间的顺序依赖性，计算成本很高。一种更快的实现方法是使用多个不带池化的卷积层来定义一个有边界的上下文框。卷积核被遮蔽，以便不看到未来的上下文，类似于 [MADE](https://lilianweng.github.io/posts/2018-10-13-flow-models/#MADE)。这个卷积版本被称为 **PixelCNN**。

> The diagonal BiLSTM layers are capable of processing an unbounded context field, but expensive to compute due to the sequential dependency between states. A faster implementation uses multiple convolutional layers without pooling to define a bounded context box. The convolution kernel is masked so that the future context is not seen, similar to [MADE](https://lilianweng.github.io/posts/2018-10-13-flow-models/#MADE). This convolution version is called **PixelCNN**.

![PixelCNN with masked convolution constructed by an elementwise product of a mask tensor and the convolution kernel before applying it. (Image source: http://slazebni.cs.illinois.edu/spring17/lec13_advanced.pdf)](https://lilianweng.github.io/posts/2018-10-13-flow-models/pixel-cnn.png)

#### WaveNet

> WaveNet

**WaveNet** ([Van Den Oord, et al. 2016](https://arxiv.org/abs/1609.03499)) 与 PixelCNN 非常相似，但应用于一维音频信号。WaveNet 由一堆 *因果卷积* 组成，这是一种旨在遵循顺序的卷积操作：在某个时间戳的预测只能使用过去观察到的数据，不依赖于未来。在 PixelCNN 中，因果卷积是通过掩码卷积核实现的。WaveNet 中的因果卷积只是将输出向未来移动一定数量的时间戳，以便输出与最后一个输入元素对齐。

> **WaveNet** ([Van Den Oord, et al. 2016](https://arxiv.org/abs/1609.03499)) is very similar to PixelCNN but applied to 1-D audio signals. WaveNet consists of a stack of *causal convolution* which is a convolution operation designed to respect the ordering: the prediction at a certain timestamp can only consume the data observed in the past, no dependency on the future. In PixelCNN, the causal convolution is implemented by masked convolution kernel. The causal convolution in WaveNet is simply to shift the output by a number of timestamps to the future so that the output is aligned with the last input element.

卷积层的一个主要缺点是感受野的大小非常有限。输出很难依赖于数百或数千个时间步之前的输入，这对于建模长序列来说可能是一个关键要求。因此，WaveNet 采用了 *空洞卷积* ([动画](https://github.com/vdumoulin/conv_arithmetic#dilated-convolution-animations))，其中卷积核应用于输入中更大感受野内均匀分布的样本子集。

> One big drawback of convolution layer is a very limited size of receptive field. The output can hardly depend on the input hundreds or thousands of timesteps ago, which can be a crucial requirement for modeling long sequences. WaveNet therefore adopts *dilated convolution* ([animation](https://github.com/vdumoulin/conv_arithmetic#dilated-convolution-animations)), where the kernel is applied to an evenly-distributed subset of samples in a much larger receptive field of the input.

![Visualization of WaveNet models with a stack of (top) causal convolution layers and (bottom) dilated convolution layers. (Image source: Van Den Oord, et al. 2016 )](https://lilianweng.github.io/posts/2018-10-13-flow-models/wavenet.png)

WaveNet 使用门控激活单元作为非线性层，因为它被发现在建模一维音频数据方面比 ReLU 效果显著更好。残差连接在门控激活之后应用。

> WaveNet uses the gated activation unit as the non-linear layer, as it is found to work significantly better than ReLU for modeling 1-D audio data. The residual connection is applied after the gated activation.

$$
\mathbf{z} = \tanh(\mathbf{W}_{f,k}\circledast\mathbf{x})\odot\sigma(\mathbf{W}_{g,k}\circledast\mathbf{x})
$$

其中 $\mathbf{W}_{f,k}$ 和 $\mathbf{W}_{g,k}$ 分别是第 $k$ 层的卷积滤波器和门控权重矩阵；两者都是可学习的。

> where $\mathbf{W}_{f,k}$ and $\mathbf{W}_{g,k}$ are convolution filter and gate weight matrix of the $k$ -th layer, respectively; both are learnable.

#### 掩码自回归流

> Masked Autoregressive Flow

**掩码自回归流** (**MAF**; [Papamakarios 等人，2017](https://arxiv.org/abs/1705.07057)) 是一种归一化流，其变换层被构建为自回归神经网络。MAF 与后来引入的**逆自回归流** (IAF) 非常相似。有关 MAF 和 IAF 之间关系的更多讨论，请参见下一节。

> **Masked Autoregressive Flow**  (**MAF**; [Papamakarios et al., 2017](https://arxiv.org/abs/1705.07057)) is a type of normalizing flows, where the transformation layer is built as an autoregressive neural network. MAF is very similar to **Inverse Autoregressive Flow** (IAF) introduced later. See more discussion on the relationship between MAF and IAF in the next section.

给定两个随机变量，$\mathbf{z} \sim \pi(\mathbf{z})$ 和 $\mathbf{x} \sim p(\mathbf{x})$ 以及概率密度函数 $\pi(\mathbf{z})$ 已知，MAF 旨在学习 $p(\mathbf{x})$。MAF 生成每个 $x_i$ 以过去的维度 $\mathbf{x}_{1:i-1}$ 为条件。

> Given two random variables, $\mathbf{z} \sim \pi(\mathbf{z})$ and $\mathbf{x} \sim p(\mathbf{x})$ and the probability density function $\pi(\mathbf{z})$ is known, MAF aims to learn $p(\mathbf{x})$. MAF generates each $x_i$ conditioned on the past dimensions $\mathbf{x}_{1:i-1}$.

精确地说，条件概率是 $\mathbf{z}$ 的仿射变换，其中尺度和偏移项是 $\mathbf{x}$ 的观测部分的函数。

> Precisely the conditional probability is an affine transformation of $\mathbf{z}$, where the scale and shift terms are functions of the observed part of $\mathbf{x}$.

• 数据生成，产生一个新的 $\mathbf{x}$：

英文原文：

• Data generation, producing a new $\mathbf{x}$:

$x_i \sim p(x_i\vert\mathbf{x}_{1:i-1}) = z_i \odot \sigma_i(\mathbf{x}_{1:i-1}) + \mu_i(\mathbf{x}_{1:i-1})\text{, where }\mathbf{z} \sim \pi(\mathbf{z})$

> $x_i \sim p(x_i\vert\mathbf{x}_{1:i-1}) = z_i \odot \sigma_i(\mathbf{x}_{1:i-1}) + \mu_i(\mathbf{x}_{1:i-1})\text{, where }\mathbf{z} \sim \pi(\mathbf{z})$

• 密度估计，给定一个已知的 $\mathbf{x}$：

英文原文：

• Density estimation, given a known $\mathbf{x}$:

$p(\mathbf{x}) = \prod_{i=1}^D p(x_i\vert\mathbf{x}_{1:i-1})$

> $p(\mathbf{x}) = \prod_{i=1}^D p(x_i\vert\mathbf{x}_{1:i-1})$

生成过程是顺序的，因此其设计本身就比较慢。而密度估计只需要通过一次网络，使用诸如 [MADE](https://lilianweng.github.io/posts/2018-10-13-flow-models/#MADE) 这样的架构。变换函数很容易求逆，雅可比行列式也易于计算。

> The generation procedure is sequential, so it is slow by design. While density estimation only needs one pass the network using architecture like [MADE](https://lilianweng.github.io/posts/2018-10-13-flow-models/#MADE). The transformation function is trivial to inverse and the Jacobian determinant is easy to compute too.

#### 逆自回归流

> Inverse Autoregressive Flow

与 MAF 类似，**逆自回归流** (**IAF**; [Kingma 等人，2016](https://arxiv.org/abs/1606.04934)) 也将目标变量的条件概率建模为自回归模型，但采用反向流，从而实现更高效的采样过程。

> Similar to MAF, **Inverse autoregressive flow** (**IAF**; [Kingma et al., 2016](https://arxiv.org/abs/1606.04934)) models the conditional probability of the target variable as an autoregressive model too, but with a reversed flow, thus achieving a much efficient sampling process.

首先，让我们反转 MAF 中的仿射变换：

> First, let’s reverse the affine transformation in MAF:

$$
z_i = \frac{x_i - \mu_i(\mathbf{x}_{1:i-1})}{\sigma_i(\mathbf{x}_{1:i-1})} = -\frac{\mu_i(\mathbf{x}_{1:i-1})}{\sigma_i(\mathbf{x}_{1:i-1})} + x_i \odot \frac{1}{\sigma_i(\mathbf{x}_{1:i-1})}
$$

如果设：

> If let:

$$
\begin{aligned}
& \tilde{\mathbf{x}} = \mathbf{z}\text{, }\tilde{p}(.) = \pi(.)\text{, }\tilde{\mathbf{x}} \sim \tilde{p}(\tilde{\mathbf{x}}) \\
& \tilde{\mathbf{z}} = \mathbf{x} \text{, }\tilde{\pi}(.) = p(.)\text{, }\tilde{\mathbf{z}} \sim \tilde{\pi}(\tilde{\mathbf{z}})\\
& \tilde{\mu}_i(\tilde{\mathbf{z}}_{1:i-1}) = \tilde{\mu}_i(\mathbf{x}_{1:i-1}) = -\frac{\mu_i(\mathbf{x}_{1:i-1})}{\sigma_i(\mathbf{x}_{1:i-1})} \\
& \tilde{\sigma}(\tilde{\mathbf{z}}_{1:i-1}) = \tilde{\sigma}(\mathbf{x}_{1:i-1}) = \frac{1}{\sigma_i(\mathbf{x}_{1:i-1})}
\end{aligned}
$$

那么我们会有，

> Then we would have,

$$
\tilde{x}_i \sim p(\tilde{x}_i\vert\tilde{\mathbf{z}}_{1:i}) = \tilde{z}_i \odot \tilde{\sigma}_i(\tilde{\mathbf{z}}_{1:i-1}) + \tilde{\mu}_i(\tilde{\mathbf{z}}_{1:i-1})
\text{, where }\tilde{\mathbf{z}} \sim \tilde{\pi}(\tilde{\mathbf{z}})
$$

IAF 旨在估计 $\tilde{\mathbf{x}}$ 的概率密度函数，已知 $\tilde{\pi}(\tilde{\mathbf{z}})$。逆流也是一种自回归仿射变换，与 MAF 中相同，但尺度和偏移项是已知分布 $\tilde{\pi}(\tilde{\mathbf{z}})$ 中观测变量的自回归函数。MAF 和 IAF 的比较见 

> IAF intends to estimate the probability density function of $\tilde{\mathbf{x}}$ given that $\tilde{\pi}(\tilde{\mathbf{z}})$ is already known. The inverse flow is an autoregressive affine transformation too, same as in MAF, but the scale and shift terms are autoregressive functions of observed variables from the known distribution $\tilde{\pi}(\tilde{\mathbf{z}})$. See the comparison between MAF and IAF in 

![Comparison of MAF and IAF.  The variable with known density is in green while the unknown one is in red.](https://lilianweng.github.io/posts/2018-10-13-flow-models/MAF-vs-IAF.png)

单个元素 $\tilde{x}_i$ 的计算彼此独立，因此它们很容易并行化（只需使用 MADE 进行一次传递）。对于已知的 $\tilde{\mathbf{x}}$ 进行密度估计效率不高，因为我们必须按顺序恢复 $\tilde{z}_i$ 的值，即 $\tilde{z}_i = (\tilde{x}_i - \tilde{\mu}_i(\tilde{\mathbf{z}}_{1:i-1})) / \tilde{\sigma}_i(\tilde{\mathbf{z}}_{1:i-1})$，总共 D 次。

> Computations of the individual elements $\tilde{x}_i$ do not depend on each other, so they are easily parallelizable (only one pass using MADE). The density estimation for a known $\tilde{\mathbf{x}}$ is not efficient, because we have to recover the value of $\tilde{z}_i$ in a sequential order, $\tilde{z}_i = (\tilde{x}_i - \tilde{\mu}_i(\tilde{\mathbf{z}}_{1:i-1})) / \tilde{\sigma}_i(\tilde{\mathbf{z}}_{1:i-1})$, thus D times in total.

|  | 基础分布 | 目标分布 | 模型 | 数据生成 | 密度估计 |
| --- | --- | --- | --- | --- | --- |
| MAF | $\mathbf{z}\sim\pi(\mathbf{z})$ | $\mathbf{x}\sim p(\mathbf{x})$ | $x_i = z_i \odot \sigma_i(\mathbf{x}_{1:i-1}) + \mu_i(\mathbf{x}_{1:i-1})$ | 顺序；慢 | 一次通过；快 |
| IAF | $\tilde{\mathbf{z}}\sim\tilde{\pi}(\tilde{\mathbf{z}})$ | $\tilde{\mathbf{x}}\sim\tilde{p}(\tilde{\mathbf{x}})$ | $\tilde{x}_i  = \tilde{z}_i \odot \tilde{\sigma}_i(\tilde{\mathbf{z}}_{1:i-1}) + \tilde{\mu}_i(\tilde{\mathbf{z}}_{1:i-1})$ | 一次通过；快 | 顺序；慢 |
| ———- | ———- | ———- | ———- | ———- | ———- |

> 英文原表 / English original

|  | Base distribution | Target distribution | Model | Data generation | Density estimation |
| --- | --- | --- | --- | --- | --- |
| MAF | $\mathbf{z}\sim\pi(\mathbf{z})$ | $\mathbf{x}\sim p(\mathbf{x})$ | $x_i = z_i \odot \sigma_i(\mathbf{x}_{1:i-1}) + \mu_i(\mathbf{x}_{1:i-1})$ | Sequential; slow | One pass; fast |
| IAF | $\tilde{\mathbf{z}}\sim\tilde{\pi}(\tilde{\mathbf{z}})$ | $\tilde{\mathbf{x}}\sim\tilde{p}(\tilde{\mathbf{x}})$ | $\tilde{x}_i  = \tilde{z}_i \odot \tilde{\sigma}_i(\tilde{\mathbf{z}}_{1:i-1}) + \tilde{\mu}_i(\tilde{\mathbf{z}}_{1:i-1})$ | One pass; fast | Sequential; slow |
| ———- | ———- | ———- | ———- | ———- | ———- |

### VAE + 流

> VAE + Flows

在 [变分自编码器](https://lilianweng.github.io/posts/2018-08-12-vae/#vae-variational-autoencoder) 中，如果我们想将后验 $p(\mathbf{z}\vert\mathbf{x})$ 建模为更复杂的分布而非简单的 Gaussian。直观上，我们可以使用归一化流来变换基础 Gaussian，以获得更好的密度近似。编码器随后将预测一组尺度和偏移项 $(\mu_i, \sigma_i)$，它们都是输入 $\mathbf{x}$ 的函数。如果感兴趣，请阅读 [论文](https://arxiv.org/abs/1809.05861) 以获取更多详细信息。

> In [Variational Autoencoder](https://lilianweng.github.io/posts/2018-08-12-vae/#vae-variational-autoencoder), if we want to model the posterior $p(\mathbf{z}\vert\mathbf{x})$ as a more complicated distribution rather than simple Gaussian. Intuitively we can use normalizing flow to transform the base Gaussian for better density approximation. The encoder then would predict a set of scale and shift terms $(\mu_i, \sigma_i)$ which are all functions of input $\mathbf{x}$. Read the [paper](https://arxiv.org/abs/1809.05861) for more details if interested.

*如果您发现此帖子中的错误，请随时通过 [lilian dot wengweng at gmail dot com] 与我联系，我将非常乐意立即纠正它们！*

> *If you notice mistakes and errors in this post, don’t hesitate to contact me at [lilian dot wengweng at gmail dot com] and I would be very happy to correct them right away!*

下篇再见 :D

> See you in the next post :D

引用方式：

> Cited as:

```
@article{weng2018flow,
  title   = "Flow-based Deep Generative Models",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-10-13-flow-models/"
}
```

### 参考文献

> Reference

[1] Danilo Jimenez Rezende, and Shakir Mohamed. [“Variational inference with normalizing flows.”](https://arxiv.org/abs/1505.05770) ICML 2015.

> [1] Danilo Jimenez Rezende, and Shakir Mohamed. [“Variational inference with normalizing flows.”](https://arxiv.org/abs/1505.05770) ICML 2015.

[2] [Normalizing Flows Tutorial, Part 1: Distributions and Determinants](https://blog.evjang.com/2018/01/nf1.html) by Eric Jang.

> [2] [Normalizing Flows Tutorial, Part 1: Distributions and Determinants](https://blog.evjang.com/2018/01/nf1.html) by Eric Jang.

[3] [Normalizing Flows Tutorial, Part 2: Modern Normalizing Flows](https://blog.evjang.com/2018/01/nf2.html) by Eric Jang.

> [3] [Normalizing Flows Tutorial, Part 2: Modern Normalizing Flows](https://blog.evjang.com/2018/01/nf2.html) by Eric Jang.

[4] [Normalizing Flows](http://akosiorek.github.io/ml/2018/04/03/norm_flows.html) by Adam Kosiorek.

> [4] [Normalizing Flows](http://akosiorek.github.io/ml/2018/04/03/norm_flows.html) by Adam Kosiorek.

[5] Laurent Dinh, Jascha Sohl-Dickstein, and Samy Bengio. [“Density estimation using Real NVP.”](https://arxiv.org/abs/1605.08803) ICLR 2017.

> [5] Laurent Dinh, Jascha Sohl-Dickstein, and Samy Bengio. [“Density estimation using Real NVP.”](https://arxiv.org/abs/1605.08803) ICLR 2017.

[6] Laurent Dinh, David Krueger, and Yoshua Bengio. [“NICE: Non-linear independent components estimation.”](https://arxiv.org/abs/1410.8516) ICLR 2015 Workshop track.

> [6] Laurent Dinh, David Krueger, and Yoshua Bengio. [“NICE: Non-linear independent components estimation.”](https://arxiv.org/abs/1410.8516) ICLR 2015 Workshop track.

[7] Diederik P. Kingma, and Prafulla Dhariwal. [“Glow: Generative flow with invertible 1x1 convolutions.”](https://arxiv.org/abs/1807.03039) arXiv:1807.03039 (2018).

> [7] Diederik P. Kingma, and Prafulla Dhariwal. [“Glow: Generative flow with invertible 1x1 convolutions.”](https://arxiv.org/abs/1807.03039) arXiv:1807.03039 (2018).

[8] Germain, Mathieu, Karol Gregor, Iain Murray, and Hugo Larochelle. [“Made: Masked autoencoder for distribution estimation.”](https://arxiv.org/abs/1502.03509) ICML 2015.

> [8] Germain, Mathieu, Karol Gregor, Iain Murray, and Hugo Larochelle. [“Made: Masked autoencoder for distribution estimation.”](https://arxiv.org/abs/1502.03509) ICML 2015.

[9] Aaron van den Oord, Nal Kalchbrenner, and Koray Kavukcuoglu. [“Pixel recurrent neural networks.”](https://arxiv.org/abs/1601.06759) ICML 2016.

> [9] Aaron van den Oord, Nal Kalchbrenner, and Koray Kavukcuoglu. [“Pixel recurrent neural networks.”](https://arxiv.org/abs/1601.06759) ICML 2016.

[10] Diederik P. Kingma, et al. [“Improved variational inference with inverse autoregressive flow.”](https://arxiv.org/abs/1606.04934) NIPS. 2016.

> [10] Diederik P. Kingma, et al. [“Improved variational inference with inverse autoregressive flow.”](https://arxiv.org/abs/1606.04934) NIPS. 2016.

[11] George Papamakarios, Iain Murray, and Theo Pavlakou. [“Masked autoregressive flow for density estimation.”](https://arxiv.org/abs/1705.07057) NIPS 2017.

> [11] George Papamakarios, Iain Murray, and Theo Pavlakou. [“Masked autoregressive flow for density estimation.”](https://arxiv.org/abs/1705.07057) NIPS 2017.

[12] 苏剑林，和吴光。[“f-VAEs：用条件流改进 VAE。”](https://arxiv.org/abs/1809.05861) arXiv:1809.05861 (2018)。

> [12] Jianlin Su, and Guang Wu. [“f-VAEs: Improve VAEs with Conditional Flows.”](https://arxiv.org/abs/1809.05861) arXiv:1809.05861 (2018).

[13] Van Den Oord, Aaron 等人。[“WaveNet：一种原始音频的生成模型。”](https://arxiv.org/abs/1609.03499) SSW. 2016。

> [13] Van Den Oord, Aaron, et al. [“WaveNet: A generative model for raw audio.”](https://arxiv.org/abs/1609.03499) SSW. 2016.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| GAN | 生成对抗网络 | 一种通过判别器和生成器对抗训练的生成模型。 |
| VAE | 变分自编码器 | 一种通过最大化证据下界来隐式优化数据对数似然的生成模型。 |
| Normalizing Flow | 归一化流 | 一种通过一系列可逆变换将简单分布转换为复杂分布的密度估计工具。 |
| Probability Density Function (PDF) | 概率密度函数 | 描述连续随机变量在给定点附近取值概率的函数。 |
| Jacobian Matrix | 雅可比矩阵 | 一个函数所有一阶偏导数的矩阵。 |
| Jacobian Determinant | 雅可比行列式 | 雅可比矩阵的行列式，衡量矩阵乘法对空间扩展或收缩的程度。 |
| Change of Variables Theorem | 变量变换定理 | 用于计算通过函数变换后新随机变量的概率密度函数。 |
| Negative Log-Likelihood (NLL) | 负对数似然 | 机器学习中常用的损失函数，用于最大化模型的似然。 |
| RealNVP | 实值非体积保持 | 一种基于仿射耦合层的归一化流模型。 |
| Affine Coupling Layer | 仿射耦合层 | RealNVP中用于构建可逆变换的层，包含缩放和平移操作。 |
| Glow | Glow | 一种通过可逆1x1卷积简化架构的生成流模型。 |
| Autoregressive Flow | 自回归流 | 一种流变换被构造成自回归模型的归一化流。 |
| MADE | 用于分布估计的掩码自编码器 | 一种通过掩码高效强制执行自回归属性的架构。 |
| PixelRNN | 像素循环神经网络 | 一种逐像素生成图像的深度生成模型。 |
| WaveNet | WaveNet | 一种应用于一维音频信号的深度生成模型，使用因果卷积和空洞卷积。 |
