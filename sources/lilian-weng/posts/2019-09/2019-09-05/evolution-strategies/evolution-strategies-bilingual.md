# 演化策略

> Evolution Strategies

> 来源：Lil'Log / Lilian Weng，2019-09-05
> 原文链接：https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/
> 分类：机器学习 / 优化算法

## 核心要点

- 演化策略（ES）是一种黑盒优化算法，属于演化算法（EA）家族，用于优化实数向量。
- 演化算法受自然选择启发，通过生成种群、评估适应度、选择最佳个体并更新参数来迭代优化函数。
- 简单高斯演化策略将搜索分布建模为各向同性高斯分布，并迭代更新其均值和标准差。
- 协方差矩阵自适应演化策略（CMA-ES）通过自适应协方差矩阵、步长和均值，解决了简单ES探索空间调整慢的问题。
- CMA-ES利用演化路径和秩更新来更可靠地调整步长和协方差矩阵，以适应分布变化。
- 自然演化策略（NES）通过自然梯度在概率分布空间中优化参数，以最大化预期适应度，并采用基于排名的适应度塑形和自适应采样。
- 演化策略在深度强化学习中有多项应用，如OpenAI ES利用高斯噪声和对数似然技巧进行策略优化。
- 新颖性搜索演化策略（NS-ES）通过最大化新颖性分数来鼓励探索，以避免陷入局部最优。
- CEM-RL方法结合了交叉熵方法与DDPG/TD3，通过演化种群和回放缓冲区训练RL网络。
- 演化算法还可应用于深度学习中的超参数调优（PBT）和网络拓扑优化（WANN）。

## 正文

随机梯度下降是优化深度学习模型的通用选择。然而，它并非唯一选项。借助黑盒优化算法，你可以评估一个目标函数$f(x): \mathbb{R}^n \to \mathbb{R}$，即使你不知道其精确的解析形式$f(x)$，因此无法计算梯度或Hessian矩阵。黑盒优化方法的例子包括[Simulated Annealing](https://en.wikipedia.org/wiki/Simulated_annealing)，[Hill Climbing](https://en.wikipedia.org/wiki/Hill_climbing)和[Nelder-Mead method](https://en.wikipedia.org/wiki/Nelder%E2%80%93Mead_method)。

> Stochastic gradient descent is a universal choice for optimizing deep learning models. However, it is not the only option. With black-box optimization algorithms, you can evaluate a target function $f(x): \mathbb{R}^n \to \mathbb{R}$, even when you don’t know the precise analytic form of $f(x)$ and thus cannot compute gradients or the Hessian matrix. Examples of black-box optimization methods include [Simulated Annealing](https://en.wikipedia.org/wiki/Simulated_annealing), [Hill Climbing](https://en.wikipedia.org/wiki/Hill_climbing) and [Nelder-Mead method](https://en.wikipedia.org/wiki/Nelder%E2%80%93Mead_method).

**演化策略 (ES)** 是一种黑盒优化算法，诞生于 **演化算法 (EA)** 家族。在这篇文章中，我将深入探讨几种经典的ES方法，并介绍ES如何在深度强化学习中发挥作用的一些应用。

> **Evolution Strategies (ES)** is one type of black-box optimization algorithms, born in the family of **Evolutionary Algorithms (EA)**. In this post, I would dive into a couple of classic ES methods and introduce a few applications of how ES can play a role in deep reinforcement learning.

### 什么是演化策略？

> What are Evolution Strategies?

演化策略（ES）属于演化算法大家族。ES 的优化目标是实数向量，$x \in \mathbb{R}^n$。

> Evolution strategies (ES) belong to the big family of evolutionary algorithms. The optimization targets of ES are vectors of real numbers, $x \in \mathbb{R}^n$.

演化算法是指一类受*自然选择*启发的基于种群的优化算法。自然选择认为，具有有利于其生存的特性的个体可以代代相传，并将这些优良特性传递给下一代。演化通过选择过程逐渐发生，种群也变得更适应环境。

> Evolutionary algorithms refer to a division of population-based optimization algorithms inspired by *natural selection*. Natural selection believes that individuals with traits beneficial to their survival can live through generations and pass down the good characteristics to the next generation. Evolution happens by the selection process gradually and the population grows better adapted to the environment.

![How natural selection works. (Image source: Khan Academy: Darwin, evolution, & natural selection )](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/EA-illustration.png)

进化算法可以概括为以下[形式](https://ipvs.informatik.uni-stuttgart.de/mlr/marc/teaching/13-Optimization/06-blackBoxOpt.pdf)，作为一种通用的优化解决方案：

> Evolutionary algorithms can be summarized in the following [format](https://ipvs.informatik.uni-stuttgart.de/mlr/marc/teaching/13-Optimization/06-blackBoxOpt.pdf) as a general optimization solution:

假设我们要优化一个函数 $f(x)$，但我们无法直接计算梯度。但是我们仍然可以评估 $f(x)$，给定任何 $x$，并且结果是确定性的。我们对 $x$ 作为 $f(x)$ 优化的良好解决方案的概率分布的信念是 $p_\theta(x)$，由 $\theta$ 参数化。目标是找到 $\theta$ 的最佳配置。

> Let’s say we want to optimize a function $f(x)$ and we are not able to compute gradients directly. But we still can evaluate $f(x)$ given any $x$ and the result is deterministic. Our belief in the probability distribution over $x$ as a good solution to $f(x)$ optimization is $p_\theta(x)$, parameterized by $\theta$. The goal is to find an optimal configuration of $\theta$.

引用译文：

这里给定一个固定分布格式（即高斯分布），参数 $\theta$ 承载着关于最佳解的知识，并在代际之间迭代更新。

英文原文：

Here given a fixed format of distribution (i.e. Gaussian), the parameter $\theta$ carries  the knowledge about the best solutions and is being iteratively updated across generations.

从$\theta$的初始值开始，我们可以通过以下三个步骤循环连续更新$\theta$：

> Starting with an initial value of $\theta$, we can continuously update $\theta$ by looping three steps as follows:

1\. 生成一个样本群体$D = \{(x_i, f(x_i)\}$，其中$x_i \sim p_\theta(x)$。

2\. 评估$D$中样本的“适应度”。

3\. 选择最佳个体子集并使用它们来更新$\theta$，通常基于适应度或排名。

英文原文：

1\. Generate a population of samples $D = \{(x_i, f(x_i)\}$ where $x_i \sim p_\theta(x)$.

2\. Evaluate the “fitness” of samples in $D$.

3\. Select the best subset of individuals and use them to update $\theta$, generally based on fitness or rank.

在**遗传算法（GA）**（EA的另一个流行子类别）中，`x`是二进制代码序列，$x \in \{0, 1\}^n$。而在ES中，`x`只是一个实数向量，$x \in \mathbb{R}^n$。

英文原文：In Genetic Algorithms (GA), another popular subcategory of EA, `x` is a sequence of binary codes, 

$x \in \{0, 1\}^n$. While in ES, `x` is just a vector of real numbers, 

$x \in \mathbb{R}^n$.

### 简单高斯演化策略

> Simple Gaussian Evolution Strategies

[这](http://blog.otoro.net/2017/10/29/visual-evolution-strategies/)是演化策略最基本和规范的版本。它将$p_\theta(x)$建模为$n$维各向同性高斯分布，其中$\theta$只跟踪均值$\mu$和标准差$\sigma$。

> [This](http://blog.otoro.net/2017/10/29/visual-evolution-strategies/) is the most basic and canonical version of evolution strategies. It models $p_\theta(x)$ as a $n$ -dimensional isotropic Gaussian distribution, in which $\theta$ only tracks the mean $\mu$ and standard deviation $\sigma$.

$$
\theta = (\mu, \sigma),\;p_\theta(x) \sim \mathcal{N}(\mathbf{\mu}, \sigma^2 I) = \mu + \sigma \mathcal{N}(0, I)
$$

简单高斯ES的过程，给定$x \in \mathcal{R}^n$：

> The process of Simple-Gaussian-ES, given $x \in \mathcal{R}^n$:

1\. 初始化$\theta = \theta^{(0)}$和代数计数器$t=0$

2\. 通过从高斯分布中采样，生成大小为 $\Lambda$ 的后代种群：  
  
$D^{(t+1)}=\{ x^{(t+1)}_i \mid x^{(t+1)}_i = \mu^{(t)} + \sigma^{(t)} y^{(t+1)}_i \text{ where } y^{(t+1)}_i \sim \mathcal{N}(x \vert 0, \mathbf{I}),;i = 1, \dots, \Lambda\}$  
。

3\. 选择一个顶级子集$\lambda$样本，具有最佳$f(x_i)$，这个子集被称为**精英**集。不失一般性，我们可以考虑前$k$个样本在$D^{(t+1)}$中属于精英组——我们将其标记为

英文原文：

1\. Initialize $\theta = \theta^{(0)}$ and the generation counter $t=0$

2\. Generate the offspring population of size $\Lambda$ by sampling from the Gaussian distribution:  
  
$D^{(t+1)}=\{ x^{(t+1)}_i \mid x^{(t+1)}_i = \mu^{(t)} + \sigma^{(t)} y^{(t+1)}_i \text{ where } y^{(t+1)}_i \sim \mathcal{N}(x \vert 0, \mathbf{I}),;i = 1, \dots, \Lambda\}$  
.

3\. Select a top subset of $\lambda$ samples with optimal $f(x_i)$ and this subset is called **elite** set. Without loss of generality, we may consider the first $k$ samples in $D^{(t+1)}$ to belong to the elite group — Let’s label them as

$$
D^{(t+1)}\_\text{elite} = \\{x^{(t+1)}\_i \mid x^{(t+1)}\_i \in D^{(t+1)}, i=1,\dots, \lambda, \lambda\leq \Lambda\\}
$$

1. 然后我们使用精英集估计下一代的新均值和标准差：  
  


> • Then we estimate the new mean and std for the next generation using the elite set:  
>

$$
\begin{aligned}
  \mu^{(t+1)} &= \text{avg}(D^{(t+1)}_\text{elite}) = \frac{1}{\lambda}\sum_{i=1}^\lambda x_i^{(t+1)} \\
  {\sigma^{(t+1)}}^2 &= \text{var}(D^{(t+1)}_\text{elite}) = \frac{1}{\lambda}\sum_{i=1}^\lambda (x_i^{(t+1)} -\mu^{(t)})^2
  \end{aligned}
$$

1. 重复步骤 (2)-(4) 直到结果足够好 ✌️

> • Repeat steps (2)-(4) until the result is good enough ✌️

### 协方差矩阵自适应进化策略 (CMA-ES)

> Covariance Matrix Adaptation Evolution Strategies (CMA-ES)

标准差 $\sigma$ 决定了探索的程度：$\sigma$ 越大，我们能够从中采样后代种群的搜索空间就越大。在 [vanilla ES](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#simple-gaussian-evolution-strategies) 中，$\sigma^{(t+1)}$ 与 $\sigma^{(t)}$ 高度相关，因此当需要时（即当置信水平改变时），算法无法快速调整探索空间。

> The standard deviation $\sigma$ accounts for the level of exploration: the larger $\sigma$ the bigger search space we can sample our offspring population. In [vanilla ES](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#simple-gaussian-evolution-strategies), $\sigma^{(t+1)}$ is highly correlated with $\sigma^{(t)}$, so the algorithm is not able to rapidly adjust the exploration space when needed (i.e. when the confidence level changes).

[CMA-ES](https://en.wikipedia.org/wiki/CMA-ES)，是 *“协方差矩阵自适应进化策略”* 的缩写，它通过使用协方差矩阵 `C` 跟踪分布中样本之间的成对依赖关系来解决这个问题。新的分布参数变为：

英文原文：[CMA-ES](https://en.wikipedia.org/wiki/CMA-ES), short for *“Covariance Matrix Adaptation Evolution Strategy”*, fixes the problem by tracking pairwise dependencies between the samples in the distribution with a covariance matrix `C`. The new distribution parameter becomes:

$$
\theta = (\mu, \sigma, C),\; p_\theta(x) \sim \mathcal{N}(\mu, \sigma^2 C) \sim \mu + \sigma \mathcal{N}(0, C)
$$

其中$\sigma$控制着分布的整体尺度，通常被称为*步长*。

> where $\sigma$ controls for the overall scale of the distribution,  often known as *step size*.

在我们深入探讨CMA-ES中参数如何更新之前，最好先回顾一下协方差矩阵在多元高斯分布中是如何工作的。作为一个实对称矩阵，协方差矩阵$C$具有以下优良特性（参见[证明](http://s3.amazonaws.com/mitsloan-php/wp-faculty/sites/30/2016/12/15032137/Symmetric-Matrices-and-Eigendecomposition.pdf)和[证明](http://control.ucsd.edu/mauricio/courses/mae280a/lecture11.pdf)）：

> Before we dig into how the parameters are updated in CMA-ES, it is better to review how the covariance matrix works in the multivariate Gaussian distribution first. As a real symmetric matrix, the covariance matrix $C$ has the following nice features (See [proof](http://s3.amazonaws.com/mitsloan-php/wp-faculty/sites/30/2016/12/15032137/Symmetric-Matrices-and-Eigendecomposition.pdf) & [proof](http://control.ucsd.edu/mauricio/courses/mae280a/lecture11.pdf)):

• 它总是可对角化的。

• 总是半正定的。

• 它的所有特征值都是实非负数。

• 它的所有特征向量都是正交的。

• 存在一个由其特征向量组成的$\mathbb{R}^n$正交基。

英文原文：

• It is always diagonalizable.

• Always positive semi-definite.

• All of its eigenvalues are real non-negative numbers.

• All of its eigenvectors are orthogonal.

• There is an orthonormal basis of $\mathbb{R}^n$ consisting of its eigenvectors.

设矩阵$C$具有由特征向量$B = [b_1, \dots, b_n]$组成的一个*正交*基，其对应的特征值为$\lambda_1^2, \dots, \lambda_n^2$。设$D=\text{diag}(\lambda_1, \dots, \lambda_n)$。

> Let the matrix $C$ have an *orthonormal* basis of eigenvectors $B = [b_1, \dots, b_n]$, with corresponding eigenvalues $\lambda_1^2, \dots, \lambda_n^2$. Let $D=\text{diag}(\lambda_1, \dots, \lambda_n)$.

$$
C = B^\top D^2 B
= \begin{bmatrix} 
\mid & \mid &  & \mid \\
b_1 & b_2 & \dots & b_n\\
\mid & \mid &  & \mid \\
\end{bmatrix}
\begin{bmatrix}
\lambda_1^2 & 0 & \dots & 0 \\
0 & \lambda_2^2 & \dots & 0 \\
\vdots & \dots & \ddots & \vdots \\
0 & \dots & 0 & \lambda_n^2
\end{bmatrix}
\begin{bmatrix} 
- & b_1 & - \\
- & b_2 & - \\
  & \dots & \\
- & b_n & - \\
\end{bmatrix}
$$

$C$的平方根是：

> The square root of $C$ is:

$$
C^{\frac{1}{2}} = B^\top D B
$$

| 符号 | 含义 |
| --- | --- |
| $x_i^{(t)} \in \mathbb{R}^n$ | 第(t)代中的第$i$个样本 |
| $y_i^{(t)} \in \mathbb{R}^n$ | $x_i^{(t)} = \mu^{(t-1)} + \sigma^{(t-1)} y_i^{(t)} $ |
| $\mu^{(t)}$ | 第(t)代的均值 |
| $\sigma^{(t)}$ | 步长 |
| $C^{(t)}$ | 协方差矩阵 |
| $B^{(t)}$ | 一个以$C$的特征向量作为行向量的矩阵 |
| $D^{(t)}$ | 一个对角线上是$C$的特征值的对角矩阵。 |
| $p_\sigma^{(t)}$ | 在生成 (t) 时 $\sigma$ 的评估路径 |
| $p_c^{(t)}$ | 在生成 (t) 时 $C$ 的评估路径 |
| $\alpha_\mu$ | $\mu$ 更新的学习率 |
| $\alpha_\sigma$ | $p_\sigma$ 的学习率 |
| $d_\sigma$ | $\sigma$ 更新的阻尼因子 |
| $\alpha_{cp}$ | $p_c$ 的学习率 |
| $\alpha_{c\lambda}$ | 用于 $C$ 的 rank-min(λ, n) 更新的学习率 |
| $\alpha_{c1}$ | 用于 $C$ 的 rank-1 更新的学习率 |

> 英文原表 / English original

| Symbol | Meaning |
| --- | --- |
| $x_i^{(t)} \in \mathbb{R}^n$ | the $i$-th samples at the generation (t) |
| $y_i^{(t)} \in \mathbb{R}^n$ | $x_i^{(t)} = \mu^{(t-1)} + \sigma^{(t-1)} y_i^{(t)} $ |
| $\mu^{(t)}$ | mean of the generation (t) |
| $\sigma^{(t)}$ | step size |
| $C^{(t)}$ | covariance matrix |
| $B^{(t)}$ | a matrix of $C$’s eigenvectors as row vectors |
| $D^{(t)}$ | a diagonal matrix with $C$’s eigenvalues on the diagnose. |
| $p_\sigma^{(t)}$ | evaluation path for $\sigma$ at the generation (t) |
| $p_c^{(t)}$ | evaluation path for $C$ at the generation (t) |
| $\alpha_\mu$ | learning rate for $\mu$’s update |
| $\alpha_\sigma$ | learning rate for $p_\sigma$ |
| $d_\sigma$ | damping factor for $\sigma$’s update |
| $\alpha_{cp}$ | learning rate for $p_c$ |
| $\alpha_{c\lambda}$ | learning rate for $C$’s rank-min(λ, n) update |
| $\alpha_{c1}$ | learning rate for $C$’s rank-1 update |

#### 更新均值

> Updating the Mean

$$
\mu^{(t+1)} = \mu^{(t)} + \alpha_\mu \frac{1}{\lambda}\sum_{i=1}^\lambda (x_i^{(t+1)} - \mu^{(t)})
$$

CMA-ES 有一个学习率 $\alpha_\mu \leq 1$ 来控制均值 $\mu$ 的更新速度。通常将其设置为 1，因此该方程与普通 ES 中的方程相同，$\mu^{(t+1)} = \frac{1}{\lambda}\sum_{i=1}^\lambda (x_i^{(t+1)}$。

> CMA-ES has a learning rate $\alpha_\mu \leq 1$ to control how fast the mean $\mu$ should be updated.  Usually it is set to 1 and thus the equation becomes the same as in vanilla ES, $\mu^{(t+1)} = \frac{1}{\lambda}\sum_{i=1}^\lambda (x_i^{(t+1)}$.

#### 控制步长

> Controlling the Step Size

采样过程可以与均值和标准差解耦：

> The sampling process can be decoupled from the mean and standard deviation:

$$
x^{(t+1)}_i = \mu^{(t)} + \sigma^{(t)} y^{(t+1)}_i \text{, where } y^{(t+1)}_i = \frac{x_i^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}} \sim \mathcal{N}(0, C)
$$

参数$\sigma$控制着分布的整体尺度。它与协方差矩阵分离，这样我们可以比完整协方差更快地改变步长。更大的步长会导致更快的参数更新。为了评估当前步长是否合适，CMA-ES 构建了一个*演化路径* $p_\sigma$通过累加一系列连续的移动步长，$\frac{1}{\lambda}\sum_{i}^\lambda y_i^{(j)}, j=1, \dots, t$通过将此路径长度与其在随机选择下（即单步不相关）的预期长度进行比较，我们能够相应地调整$\sigma$（参见图2）。

> The parameter $\sigma$ controls the overall scale of the distribution. It is separated from the covariance matrix so that we can change steps faster than the full covariance. A larger step size leads to faster parameter update. In order to evaluate whether the current step size is proper, CMA-ES constructs an *evolution path* $p_\sigma$ by summing up a consecutive sequence of moving steps, $\frac{1}{\lambda}\sum_{i}^\lambda y_i^{(j)}, j=1, \dots, t$. By comparing this path length with its expected length under random selection (meaning single steps are uncorrelated), we are able to adjust $\sigma$ accordingly (See Fig. 2).

![Three scenarios of how single steps are correlated in different ways and their impacts on step size update. (Image source: additional annotations on Fig 5 in CMA-ES tutorial paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/CMA-ES-step-size-path.png)

每次进化路径都会用同一代中移动步长$y_i$的平均值进行更新。

> Each time the evolution path is updated with the average of moving step $y_i$ in the same generation.

$$
\begin{aligned}
&\frac{1}{\lambda}\sum_{i=1}^\lambda y_i^{(t+1)} 
= \frac{1}{\lambda} \frac{\sum_{i=1}^\lambda x_i^{(t+1)} - \lambda \mu^{(t)}}{\sigma^{(t)}}
= \frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}} \\
&\frac{1}{\lambda}\sum_{i=1}^\lambda y_i^{(t+1)} 
\sim \frac{1}{\lambda}\mathcal{N}(0, \lambda C^{(t)}) 
\sim \frac{1}{\sqrt{\lambda}}{C^{(t)}}^{\frac{1}{2}}\mathcal{N}(0, I) \\
&\text{Thus } \sqrt{\lambda}\;{C^{(t)}}^{-\frac{1}{2}} \frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}} \sim \mathcal{N}(0, I)
\end{aligned}
$$

引用译文：

通过乘以$C^{-\frac{1}{2}}$，进化路径被转换为与其方向无关。术语${C^{(t)}}^{-\frac{1}{2}} = {B^{(t)}}^\top {D^{(t)}}^{-\frac{1}{2}} {B^{(t)}}$变换的工作原理如下：

英文原文：

By multiplying with $C^{-\frac{1}{2}}$, the evolution path is transformed to be independent of its direction. The term ${C^{(t)}}^{-\frac{1}{2}} = {B^{(t)}}^\top {D^{(t)}}^{-\frac{1}{2}} {B^{(t)}}$ transformation works as follows:

1\. ${B^{(t)}}$包含$C$的特征向量的行向量。它将原始空间投影到垂直主轴上。

2\. 然后${D^{(t)}}^{-\frac{1}{2}} = \text{diag}(\frac{1}{\lambda_1}, \dots, \frac{1}{\lambda_n})$将主轴的长度缩放为相等。

3\. ${B^{(t)}}^\top$ 将空间转换回原始坐标系。

英文原文：

1\. ${B^{(t)}}$ contains row vectors of $C$’s eigenvectors. It projects the original space onto the perpendicular principal axes.

2\. Then ${D^{(t)}}^{-\frac{1}{2}} = \text{diag}(\frac{1}{\lambda_1}, \dots, \frac{1}{\lambda_n})$ scales the length of principal axes to be equal.

3\. ${B^{(t)}}^\top$ transforms the space back to the original coordinate system.

为了给最近的世代分配更高的权重，我们使用 Polyak 平均来以学习率 $\alpha_\sigma$ 更新演化路径。同时，权重是平衡的，以便 $p_\sigma$ 是 [共轭的](https://en.wikipedia.org/wiki/Conjugate_prior)，$\sim \mathcal{N}(0, I)$ 在一次更新前后都是如此。

> In order to assign higher weights to recent generations, we use polyak averaging to update the evolution path with learning rate $\alpha_\sigma$. Meanwhile, the weights are balanced so that $p_\sigma$ is [conjugate](https://en.wikipedia.org/wiki/Conjugate_prior), $\sim \mathcal{N}(0, I)$ both before and after one update.

$$
\begin{aligned}
p_\sigma^{(t+1)} 
& = (1 - \alpha_\sigma) p_\sigma^{(t)} + \sqrt{1 - (1 - \alpha_\sigma)^2}\;\sqrt{\lambda}\; {C^{(t)}}^{-\frac{1}{2}} \frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}} \\
& = (1 - \alpha_\sigma) p_\sigma^{(t)} + \sqrt{c_\sigma (2 - \alpha_\sigma)\lambda}\;{C^{(t)}}^{-\frac{1}{2}} \frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}}
\end{aligned}
$$

在随机选择下，$p_\sigma$ 的预期长度是 $\mathbb{E}|\mathcal{N}(0,I)|$，即 $\mathcal{N}(0,I)$ 随机变量的 L2 范数的期望。根据图 2 中的思想，我们根据 $|p_\sigma^{(t+1)}| / \mathbb{E}|\mathcal{N}(0,I)|$ 的比率调整步长：

> The expected length of $p_\sigma$ under random selection is $\mathbb{E}|\mathcal{N}(0,I)|$, that is the expectation of the L2-norm of a $\mathcal{N}(0,I)$ random variable. Following the idea in Fig. 2, we adjust the step size according to the ratio of $|p_\sigma^{(t+1)}| / \mathbb{E}|\mathcal{N}(0,I)|$:

$$
\begin{aligned}
\ln\sigma^{(t+1)} &= \ln\sigma^{(t)} + \frac{\alpha_\sigma}{d_\sigma} \Big(\frac{\|p_\sigma^{(t+1)}\|}{\mathbb{E}\|\mathcal{N}(0,I)\|} - 1\Big) \\
\sigma^{(t+1)} &= \sigma^{(t)} \exp\Big(\frac{\alpha_\sigma}{d_\sigma} \Big(\frac{\|p_\sigma^{(t+1)}\|}{\mathbb{E}\|\mathcal{N}(0,I)\|} - 1\Big)\Big)
\end{aligned}
$$

其中 $d_\sigma \approx 1$ 是一个阻尼参数，用于衡量 $\ln\sigma$ 应该改变的速度。

> where $d_\sigma \approx 1$ is a damping parameter, scaling how fast $\ln\sigma$ should be changed.

#### 自适应协方差矩阵

> Adapting the Covariance Matrix

对于协方差矩阵，可以使用精英样本的 $y_i$ 从头开始估计（回想一下 $y_i \sim \mathcal{N}(0, C)$）：

> For the covariance matrix, it can be estimated from scratch using $y_i$ of elite samples (recall that $y_i \sim \mathcal{N}(0, C)$):

$$
C_\lambda^{(t+1)} 
= \frac{1}{\lambda}\sum_{i=1}^\lambda y^{(t+1)}_i {y^{(t+1)}_i}^\top
= \frac{1}{\lambda {\sigma^{(t)}}^2} \sum_{i=1}^\lambda (x_i^{(t+1)} - \mu^{(t)})(x_i^{(t+1)} - \mu^{(t)})^\top
$$

上述估计只有在所选群体足够大时才可靠。然而，我们确实希望以*快速*迭代，每代使用*少量*样本群体。这就是为什么CMA-ES发明了一种更可靠但也更复杂的方式来更新$C$。它涉及两条独立的路径，

> The above estimation is only reliable when the selected population is large enough. However, we do want to run *fast* iteration with a *small* population of samples in each generation. That’s why CMA-ES invented a more reliable but also more complicated way to update $C$. It involves two independent routes,

• *Rank-min(λ, n) 更新*: 使用 $\{C_\lambda\}$ 的历史记录，每一项都在一代中从头开始估计。

• *Rank-one 更新*: 估计移动步长 $y_i$ 以及历史记录中的符号信息。

英文原文：

• *Rank-min(λ, n) update*: uses the history of $\{C_\lambda\}$, each estimated from scratch in one generation.

• *Rank-one update*: estimates the moving steps $y_i$ and the sign information from the history.

第一种方法考虑估计$C$来自整个历史的$\{C_\lambda\}$。例如，如果我们经历了大量的代数，$C^{(t+1)} \approx \text{avg}(C_\lambda^{(i)}; i=1,\dots,t)$将是一个很好的估计器。类似于$p_\sigma$，我们还使用带有学习率的 polyak 平均来整合历史：

> The first route considers the estimation of $C$ from the entire history of $\{C_\lambda\}$. For example, if we have experienced a large number of generations, $C^{(t+1)} \approx \text{avg}(C_\lambda^{(i)}; i=1,\dots,t)$ would be a good estimator. Similar to $p_\sigma$, we also use polyak averaging with a learning rate to incorporate the history:

$$
C^{(t+1)} 
= (1 - \alpha_{c\lambda}) C^{(t)} + \alpha_{c\lambda} C_\lambda^{(t+1)}
= (1 - \alpha_{c\lambda}) C^{(t)} + \alpha_{c\lambda} \frac{1}{\lambda} \sum_{i=1}^\lambda y^{(t+1)}_i {y^{(t+1)}_i}^\top
$$

学习率的常见选择是$\alpha_{c\lambda} \approx \min(1, \lambda/n^2)$。

> A common choice for the learning rate is $\alpha_{c\lambda} \approx \min(1, \lambda/n^2)$.

第二种方法试图解决$y_i{y_i}^\top = (-y_i)(-y_i)^\top$丢失符号信息的问题。与我们调整步长$\sigma$的方式类似，进化路径$p_c$用于跟踪符号信息，其构建方式使得$p_c$是共轭的，$\sim \mathcal{N}(0, C)$在新一代之前和之后都是如此。

> The second route tries to solve the issue that $y_i{y_i}^\top = (-y_i)(-y_i)^\top$ loses the sign information. Similar to how we adjust the step size $\sigma$, an evolution path $p_c$ is used to track the sign information and it is constructed in a way that $p_c$ is conjugate, $\sim \mathcal{N}(0, C)$ both before and after a new generation.

我们可以将 $p_c$ 视为计算 $\text{avg}_i(y_i)$ 的另一种方式（请注意两者 $\sim \mathcal{N}(0, C)$），同时使用了完整的历史记录并保留了符号信息。请注意，我们已经在[上一节](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#controlling-the-step-size)中了解了 $\sqrt{k}\frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}} \sim \mathcal{N}(0, C)$，

> We may consider $p_c$ as another way to compute $\text{avg}_i(y_i)$ (notice that both $\sim \mathcal{N}(0, C)$) while the entire history is used and the sign information is maintained. Note that we’ve known $\sqrt{k}\frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}} \sim \mathcal{N}(0, C)$ in the [last section](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#controlling-the-step-size),

$$
\begin{aligned}
p_c^{(t+1)} 
&= (1-\alpha_{cp}) p_c^{(t)} + \sqrt{1 - (1-\alpha_{cp})^2}\;\sqrt{\lambda}\;\frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}} \\
&= (1-\alpha_{cp}) p_c^{(t)} + \sqrt{\alpha_{cp}(2 - \alpha_{cp})\lambda}\;\frac{\mu^{(t+1)} - \mu^{(t)}}{\sigma^{(t)}}
\end{aligned}
$$

然后根据 $p_c$ 更新协方差矩阵：

> Then the covariance matrix is updated according to $p_c$:

$$
C^{(t+1)} = (1-\alpha_{c1}) C^{(t)} + \alpha_{c1}\;p_c^{(t+1)} {p_c^{(t+1)}}^\top
$$

据称，当 $k$ 很小时，*秩一更新*方法比*秩-min(λ, n)-更新*方法能产生显著改进，因为移动步长的符号以及连续步长之间的相关性都被利用并代代相传。

> The *rank-one update* approach is claimed to generate a significant improvement over the *rank-min(λ, n)-update* when $k$ is small, because the signs of moving steps and correlations between consecutive steps are all utilized and passed down through generations.

最终我们将两种方法结合起来，

> Eventually we combine two approaches together,

$$
C^{(t+1)} 
= (1 - \alpha_{c\lambda} - \alpha_{c1}) C^{(t)}
+ \alpha_{c1}\;\underbrace{p_c^{(t+1)} {p_c^{(t+1)}}^\top}_\textrm{rank-one update}
+ \alpha_{c\lambda} \underbrace{\frac{1}{\lambda} \sum_{i=1}^\lambda y^{(t+1)}_i {y^{(t+1)}_i}^\top}_\textrm{rank-min(lambda, n) update}
$$

![Illustration of how CMA-ES works on a 2D optimization problem (the lighter color the better). Black dots are samples in one generation. The samples are more spread out initially but when the model has higher confidence in finding a good solution in the late stage, the samples become very concentrated over the global optimum. (Image source: Wikipedia CMA-ES )](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/CMA-ES-algorithm.png)

在我以上所有示例中，每个精英样本都被认为贡献了等量的权重，$1/\lambda$。这个过程可以很容易地扩展到根据其性能为选定样本分配不同权重的情况，$w_1, \dots, w_\lambda$。更多详情请参见[教程](https://arxiv.org/abs/1604.00772)。

> In all my examples above, each elite sample is considered to contribute an equal amount of weights, $1/\lambda$. The process can be easily extended to the case where selected samples are assigned with different weights, $w_1, \dots, w_\lambda$, according to their performances. See more detail in [tutorial](https://arxiv.org/abs/1604.00772).

![Illustration of how CMA-ES works on a 2D optimization problem (the lighter color the better). Black dots are samples in one generation. The samples are more spread out initially but when the model has higher confidence in finding a good solution in the late stage, the samples become very concentrated over the global optimum. (Image source: Wikipedia CMA-ES )](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/CMA-ES-illustration.png)

### 自然演化策略

> Natural Evolution Strategies

自然演化策略 (**NES**；[Wierstra 等人，2008](https://arxiv.org/abs/1106.4487)) 在参数的搜索分布中进行优化，并将分布朝着高适应度的方向移动，该方向由*自然梯度*指示。

> Natural Evolution Strategies (**NES**; [Wierstra, et al, 2008](https://arxiv.org/abs/1106.4487)) optimizes in a search distribution of parameters and moves the distribution in the direction of high fitness indicated by the *natural gradient*.

#### 自然梯度

> Natural Gradients

给定一个目标函数$\mathcal{J}(\theta)$由...参数化$\theta$，假设我们的目标是找到最优的$\theta$以最大化目标函数值。一个*普通梯度*在距当前...的欧几里得小距离内找到最陡峭的方向$\theta$；距离限制应用于参数空间。换句话说，我们计算普通梯度，其依据是...绝对值的微小变化$\theta$。最优的步长是：

> Given an objective function $\mathcal{J}(\theta)$ parameterized by $\theta$, let’s say our goal is to find the optimal $\theta$ to maximize the objective function value. A *plain gradient* finds the steepest direction within a small Euclidean distance from the current $\theta$; the distance restriction is applied on the parameter space. In other words, we compute the plain gradient with respect to a small change of the absolute value of $\theta$. The optimal step is:

$$
d^{*} = \operatorname*{argmax}_{\|d\| = \epsilon} \mathcal{J}(\theta + d)\text{, where }\epsilon \to 0
$$

不同的是，*自然梯度* 与由 $\theta$、$p_\theta(x)$ 参数化的概率 [分布](https://arxiv.org/abs/1301.3584v7) [空间](https://wiseodd.github.io/techblog/2018/03/14/natural-gradient/) 一起工作（在 NES [论文](https://arxiv.org/abs/1106.4487) 中被称为“搜索分布”）。它在分布空间中寻找一个小的步长内最陡峭的方向，其中距离通过 KL 散度测量。通过这个约束，我们确保每次更新都以恒定速度沿着分布流形移动，而不会被其曲率减慢。

> Differently, *natural gradient* works with a probability [distribution](https://arxiv.org/abs/1301.3584v7) [space](https://wiseodd.github.io/techblog/2018/03/14/natural-gradient/) parameterized by $\theta$, $p_\theta(x)$ (referred to as “search distribution” in NES [paper](https://arxiv.org/abs/1106.4487)). It looks for the steepest direction within a small step in the distribution space where the distance is measured by KL divergence. With this constraint we ensure that each update is moving along the distributional manifold with constant speed, without being slowed down by its curvature.

$$
d^{*}_\text{N} = \operatorname*{argmax}_{\text{KL}[p_\theta \| p_{\theta+d}] = \epsilon} \mathcal{J}(\theta + d)
$$

#### 使用费雪信息矩阵进行估计

> Estimation using Fisher Information Matrix

但是，如何精确计算$\text{KL}[p_\theta | p_{\theta+\Delta\theta}]$？通过对$\log p_{\theta + d}$在$\theta$处进行泰勒展开，我们得到：

> But, how to compute $\text{KL}[p_\theta | p_{\theta+\Delta\theta}]$ precisely? By running Taylor expansion of $\log p_{\theta + d}$ at $\theta$, we get:

$$
\begin{aligned}
& \text{KL}[p_\theta \| p_{\theta+d}] \\
&= \mathbb{E}_{x \sim p_\theta} [\log p_\theta(x) - \log p_{\theta+d}(x)] & \\
&\approx \mathbb{E}_{x \sim p_\theta} [ \log p_\theta(x) -( \log p_{\theta}(x) + \nabla_\theta \log p_{\theta}(x) d + \frac{1}{2}d^\top \nabla^2_\theta \log p_{\theta}(x) d)] & \scriptstyle{\text{; Taylor expand }\log p_{\theta+d}} \\
&\approx - \mathbb{E}_x [\nabla_\theta \log p_{\theta}(x)] d - \frac{1}{2}d^\top \mathbb{E}_x [\nabla^2_\theta \log p_{\theta}(x)] d & 
\end{aligned}
$$

其中

> where

$$
\begin{aligned}
\mathbb{E}_x [\nabla_\theta \log p_{\theta}] d 
&= \int_{x\sim p_\theta} p_\theta(x) \nabla_\theta \log p_\theta(x) & \\
&= \int_{x\sim p_\theta} p_\theta(x) \frac{1}{p_\theta(x)} \nabla_\theta p_\theta(x) & \\
&= \nabla_\theta \Big( \int_{x} p_\theta(x) \Big) & \scriptstyle{\textrm{; note that }p_\theta(x)\textrm{ is probability distribution.}} \\
&= \nabla_\theta (1) = 0
\end{aligned}
$$

最后我们得到，

> Finally we have,

$$
\text{KL}[p_\theta \| p_{\theta+d}] = - \frac{1}{2}d^\top \mathbf{F}_\theta d 
\text{, where }\mathbf{F}_\theta = \mathbb{E}_x [(\nabla_\theta \log p_{\theta}) (\nabla_\theta \log p_{\theta})^\top]
$$

其中 $\mathbf{F}_\theta$ 称为 **[Fisher 信息矩阵](http://mathworld.wolfram.com/FisherInformationMatrix.html)**，并且 [它](https://wiseodd.github.io/techblog/2018/03/11/fisher-information/) 是 $\nabla_\theta \log p_\theta$ 的协方差矩阵，因为 $\mathbb{E}[\nabla_\theta \log p_\theta] = 0$。

英文原文：where 

$\mathbf{F}_\theta$ is called the [Fisher Information Matrix](http://mathworld.wolfram.com/FisherInformationMatrix.html) and [it is](https://wiseodd.github.io/techblog/2018/03/11/fisher-information/) the covariance matrix of 

$\nabla_\theta \log p_\theta$ since 

$\mathbb{E}[\nabla_\theta \log p_\theta] = 0$.

以下优化问题的解：

> The solution to the following optimization problem:

$$
\max \mathcal{J}(\theta + d) \approx \max \big( \mathcal{J}(\theta) + {\nabla_\theta\mathcal{J}(\theta)}^\top d \big)\;\text{ s.t. }\text{KL}[p_\theta \| p_{\theta+d}] - \epsilon = 0
$$

可以使用拉格朗日乘数找到，

> can be found using a Lagrangian multiplier,

$$
\begin{aligned}
\mathcal{L}(\theta, d, \beta) &= \mathcal{J}(\theta) + \nabla_\theta\mathcal{J}(\theta)^\top d - \beta (\frac{1}{2}d^\top \mathbf{F}_\theta d + \epsilon) = 0 \text{ s.t. } \beta > 0 \\
\nabla_d \mathcal{L}(\theta, d, \beta) &= \nabla_\theta\mathcal{J}(\theta) - \beta\mathbf{F}_\theta d = 0 \\
\text{Thus } d_\text{N}^* &= \nabla_\theta^\text{N} \mathcal{J}(\theta) = \mathbf{F}_\theta^{-1} \nabla_\theta\mathcal{J}(\theta) 
\end{aligned}
$$

其中 $d_\text{N}^{\ast}$ 仅提取 $\theta$ 上最优移动步长的方向，忽略标量 $\beta^{-1}$。

> where $d_\text{N}^{\ast}$ only extracts the direction of the optimal moving step on $\theta$, ignoring the scalar $\beta^{-1}$.

![The natural gradient samples (black solid arrows) in the right are the plain gradient samples (black solid arrows)  in the left multiplied by the inverse of their covariance. In this way, a gradient direction with high uncertainty (indicated by high covariance with other samples) are penalized with a small weight. The aggregated natural gradient (red dash arrow) is therefore more trustworthy than the natural gradient (green solid arrow). (Image source: additional annotations on Fig 2 in NES paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/CMA-ES-coordinates.png)

#### NES 算法

> NES Algorithm

与一个样本相关的适应度被标记为 $f(x)$ 并且 $x$ 上的搜索分布由 $\theta$ 参数化。NES 预计将优化参数 $\theta$ 以实现最大预期适应度：

> The fitness associated with one sample is labeled as $f(x)$ and the search distribution over $x$ is parameterized by $\theta$. NES is expected to optimize the parameter $\theta$ to achieve maximum expected fitness:

$$
\mathcal{J}(\theta) = \mathbb{E}_{x\sim p_\theta(x)} [f(x)] = \int_x f(x) p_\theta(x) dx
$$

使用相同的对数似然[技巧](http://blog.shakirm.com/2015/11/machine-learning-trick-of-the-day-5-log-derivative-trick/)在[REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce)中：

> Using the same log-likelihood [trick](http://blog.shakirm.com/2015/11/machine-learning-trick-of-the-day-5-log-derivative-trick/) in [REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce):

$$
\begin{aligned}
\nabla_\theta\mathcal{J}(\theta) 
&= \nabla_\theta \int_x f(x) p_\theta(x) dx \\
&= \int_x f(x) \frac{p_\theta(x)}{p_\theta(x)}\nabla_\theta p_\theta(x) dx \\
& = \int_x f(x) p_\theta(x) \nabla_\theta \log p_\theta(x) dx \\
& = \mathbb{E}_{x \sim p_\theta} [f(x) \nabla_\theta \log p_\theta(x)]
\end{aligned}
$$

![The algorithm for training a RL policy using evolution strategies. (Image source: ES-for-RL paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/NES-algorithm.png)

除了自然梯度，NES 还采用了一些重要的启发式方法，以使算法性能更稳健。

> Besides natural gradients, NES adopts a couple of important heuristics to make the algorithm performance more robust.

• NES 应用 **基于排名的适应度塑形**，即使用在单调递增的适应度值下的 *排名*，而不是直接使用 $f(x)$。或者它可以是排名的函数（“效用函数”），这被认为是 NES 的一个自由参数。

• NES 采用 **自适应采样** 以在运行时调整超参数。当改变 $\theta \to \theta’$ 时，将从 $p_\theta$ 中抽取的样本与从 $p_{\theta’}$ 中抽取的样本使用 [Mann-Whitney U-test(https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test)] 进行比较；如果出现正号或负号，目标超参数会通过一个乘法常数减小或增大。请注意，样本 $x’_i \sim p_{\theta’}(x)$ 的分数已应用重要性采样权重 $w_i’ = p_\theta(x) / p_{\theta’}(x)$。

英文原文：

• NES applies **rank-based fitness shaping**, that is to use the *rank* under monotonically increasing fitness values instead of using $f(x)$ directly. Or it can be a function of the rank (“utility function”), which is considered as a free parameter of NES.

• NES adopts **adaptation sampling** to adjust hyperparameters at run time. When changing $\theta \to \theta’$, samples drawn from $p_\theta$ are compared with samples from $p_{\theta’}$ using [Mann-Whitney U-test(https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test)]; if there shows a positive or negative sign, the target hyperparameter decreases or increases by a multiplication constant. Note the score of a sample $x’_i \sim p_{\theta’}(x)$ has importance sampling weights applied $w_i’ = p_\theta(x) / p_{\theta’}(x)$.

### 应用：深度强化学习中的 ES

> Applications: ES in Deep Reinforcement Learning

#### OpenAI ES 用于强化学习

> OpenAI ES for RL

在强化学习中使用进化算法的概念可以追溯到[很久以前](https://arxiv.org/abs/1106.0221)，但由于计算限制，仅限于表格型强化学习。

> The concept of using evolutionary algorithms in reinforcement learning can be traced back [long ago](https://arxiv.org/abs/1106.0221), but only constrained to tabular RL due to computational limitations.

受[NES](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#natural-evolution-strategies)的启发，OpenAI 的研究人员（[Salimans, et al. 2017](https://arxiv.org/abs/1703.03864)）提出使用 NES 作为无梯度黑盒优化器来寻找最优策略参数$\theta$，以最大化回报函数$F(\theta)$。关键在于在模型参数上添加高斯噪声$\epsilon$在模型参数$\theta$上，然后利用对数似然技巧将其写成高斯概率密度函数的梯度。最终，只剩下噪声项作为衡量性能的加权标量。

> Inspired by [NES](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#natural-evolution-strategies), researchers at OpenAI ([Salimans, et al. 2017](https://arxiv.org/abs/1703.03864)) proposed to use NES as a gradient-free black-box optimizer to find optimal policy parameters $\theta$ that maximizes the return function $F(\theta)$. The key is to add Gaussian noise $\epsilon$ on the model parameter $\theta$ and then use the log-likelihood trick to write it as the gradient of the Gaussian pdf. Eventually only the noise term is left as a weighting scalar for measured performance.

假设当前参数值为 $\hat{\theta}$（添加的帽子是为了将该值与随机变量 $\theta$ 区分开来）。$\theta$ 的搜索分布被设计为具有均值 $\hat{\theta}$ 和固定协方差矩阵 $\sigma^2 I$ 的各向同性多元高斯分布。

> Let’s say the current parameter value is $\hat{\theta}$ (the added hat is to distinguish the value from the random variable $\theta$). The search distribution of $\theta$ is designed to be an isotropic multivariate Gaussian with a mean $\hat{\theta}$ and a fixed covariance matrix $\sigma^2 I$,

$$
\theta \sim \mathcal{N}(\hat{\theta}, \sigma^2 I) \text{ equivalent to } \theta = \hat{\theta} + \sigma\epsilon, \epsilon \sim \mathcal{N}(0, I)
$$

$\theta$ 更新的梯度为：

> The gradient for $\theta$ update is:

$$
\begin{aligned}
& \nabla_\theta \mathbb{E}_{\theta\sim\mathcal{N}(\hat{\theta}, \sigma^2 I)} F(\theta) \\
&= \nabla_\theta \mathbb{E}_{\epsilon\sim\mathcal{N}(0, I)} F(\hat{\theta} + \sigma\epsilon) \\
&= \nabla_\theta \int_{\epsilon} p(\epsilon) F(\hat{\theta} + \sigma\epsilon) d\epsilon & \scriptstyle{\text{; Gaussian }p(\epsilon)=(2\pi)^{-\frac{n}{2}} \exp(-\frac{1}{2}\epsilon^\top\epsilon)} \\
&= \int_{\epsilon} p(\epsilon) \nabla_\epsilon \log p(\epsilon) \nabla_\theta \epsilon\;F(\hat{\theta} + \sigma\epsilon) d\epsilon & \scriptstyle{\text{; log-likelihood trick}}\\
&= \mathbb{E}_{\epsilon\sim\mathcal{N}(0, I)} [ \nabla_\epsilon \big(-\frac{1}{2}\epsilon^\top\epsilon\big) \nabla_\theta \big(\frac{\theta - \hat{\theta}}{\sigma}\big) F(\hat{\theta} + \sigma\epsilon) ] & \\
&= \mathbb{E}_{\epsilon\sim\mathcal{N}(0, I)} [ (-\epsilon) (\frac{1}{\sigma}) F(\hat{\theta} + \sigma\epsilon) ] & \\
&= \frac{1}{\sigma}\mathbb{E}_{\epsilon\sim\mathcal{N}(0, I)} [ \epsilon F(\hat{\theta} + \sigma\epsilon) ] & \scriptstyle{\text{; negative sign can be absorbed.}}
\end{aligned}
$$

在一代中，我们可以采样许多 $epsilon_i, i=1,\dots,n$ 并 *并行*评估适应度。一个精妙的设计是，无需共享任何大型模型参数。只需在工作节点之间传递随机种子，主节点就足以进行参数更新。这种方法后来被扩展到自适应地学习损失函数；请参阅我之前关于 [Evolved Policy Gradient](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#meta-learning-the-loss-function) 的文章。

> In one generation, we can sample many $epsilon_i, i=1,\dots,n$ and evaluate the fitness *in parallel*. One beautiful design is that no large model parameter needs to be shared. By only communicating the random seeds between workers, it is enough for the master node to do parameter update. This approach is later extended to adaptively learn a loss function; see my previous post on [Evolved Policy Gradient](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#meta-learning-the-loss-function).

![The algorithm for training a RL policy using evolution strategies. (Image source: ES-for-RL paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/OpenAI-ES-algorithm.png)

为了使性能更稳健，OpenAI ES 采用了虚拟批归一化（BN，其中用于计算统计数据的 mini-batch 是固定的）、镜像采样（采样一对 $(-\epsilon, \epsilon)$ 进行评估）和 [适应度塑造](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#fitness-shaping)。

> To make the performance more robust, OpenAI ES adopts virtual batch normalization (BN with mini-batch used for calculating statistics fixed), mirror sampling (sampling a pair of $(-\epsilon, \epsilon)$ for evaluation), and [fitness shaping](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#fitness-shaping).

#### 使用 ES 进行探索

> Exploration with ES

探索（[相对于利用](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#exploitation-vs-exploration)）是强化学习中的一个重要课题。ES 算法 [上述](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/TBA) 的优化方向仅从累积回报 $F(\theta)$ 中提取。如果没有明确的探索，智能体可能会陷入局部最优。

> Exploration ([vs exploitation](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#exploitation-vs-exploration)) is an important topic in RL. The optimization direction in the ES algorithm [above](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/TBA) is only extracted from the cumulative return $F(\theta)$. Without explicit exploration, the agent might get trapped in a local optimum.

新颖性搜索 ES（**NS-ES**；[Conti 等人，2018](https://arxiv.org/abs/1712.06560)）通过朝最大化 *新颖性* 分数的方向更新参数来鼓励探索。新颖性分数取决于领域特定的行为表征函数 $b(\pi_\theta)$。$b(\pi_\theta)$ 的选择是任务特定的，并且似乎有些随意；例如，在该论文中的 Humanoid 运动任务中，$b(\pi_\theta)$ 是智能体的最终 $(x,y)$ 位置。

英文原文：Novelty-Search ES (NS-ES; [Conti et al, 2018](https://arxiv.org/abs/1712.06560)) encourages exploration by updating the parameter in the direction to maximize the *novelty* score. The novelty score depends on a domain-specific behavior characterization function 

$b(\pi_\theta)$. The choice of 

$b(\pi_\theta)$ is specific to the task and seems to be a bit arbitrary; for example, in the Humanoid locomotion task in the paper, 

$b(\pi_\theta)$ is the final 

$(x,y)$ location of the agent.

1\. 每个策略的 $b(\pi_\theta)$ 都被推送到一个存档集 $\mathcal{A}$。

2\. 策略 $\pi_\theta$ 的新颖性通过 $b(\pi_\theta)$ 与 $\mathcal{A}$ 中所有其他条目之间的 k-近邻分数来衡量。\n(存档集的使用案例听起来与 [情景记忆](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#episodic-control) 相当相似。)

英文原文：

1\. Every policy’s $b(\pi_\theta)$ is pushed to an archive set $\mathcal{A}$.

2\. Novelty of a policy $\pi_\theta$ is measured as the k-nearest neighbor score between $b(\pi_\theta)$ and all other entries in $\mathcal{A}$.
(The use case of the archive set sounds quite similar to [episodic memory](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#episodic-control).)

$$
N(\theta, \mathcal{A}) = \frac{1}{\lambda} \sum_{i=1}^\lambda \| b(\pi_\theta), b^\text{knn}_i \|_2
\text{, where }b^\text{knn}_i \in \text{kNN}(b(\pi_\theta), \mathcal{A})
$$

ES 优化步骤依赖于新颖性分数而不是适应度：

> The ES optimization step relies on the novelty score instead of fitness:

$$
\nabla_\theta \mathbb{E}_{\theta\sim\mathcal{N}(\hat{\theta}, \sigma^2 I)} N(\theta, \mathcal{A})
= \frac{1}{\sigma}\mathbb{E}_{\epsilon\sim\mathcal{N}(0, I)} [ \epsilon N(\hat{\theta} + \sigma\epsilon, \mathcal{A}) ]
$$

NS-ES 维护一组 $M$ 独立训练的智能体（“元种群”），$\mathcal{M} = \{\theta_1, \dots, \theta_M \}$ 并根据新颖性分数按比例选择一个进行推进。最终我们选择最佳策略。这个过程等同于集成；另请参阅 [SVPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#svpg) 中的相同思想。

> NS-ES maintains a group of $M$ independently trained agents (“meta-population”), $\mathcal{M} = \{\theta_1, \dots, \theta_M \}$ and picks one to advance proportional to the novelty score. Eventually we select the best policy. This process is equivalent to ensembling; also see the same idea in [SVPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#svpg).

$$
\begin{aligned}
m &\leftarrow \text{pick } i=1,\dots,M\text{ according to probability}\frac{N(\theta_i, \mathcal{A})}{\sum_{j=1}^M N(\theta_j, \mathcal{A})} \\
\theta_m^{(t+1)} &\leftarrow \theta_m^{(t)} + \alpha \frac{1}{\sigma}\sum_{i=1}^N \epsilon_i N(\theta^{(t)}_m + \epsilon_i, \mathcal{A}) \text{ where }\epsilon_i \sim \mathcal{N}(0, I)
\end{aligned}
$$

其中 $N$ 是高斯扰动噪声向量的数量，$\alpha$ 是学习率。

> where $N$ is the number of Gaussian perturbation noise vectors and $\alpha$ is the learning rate.

NS-ES 完全抛弃了奖励函数，只优化新颖性以避免欺骗性局部最优。为了将适应度重新纳入公式，又提出了两种变体。

> NS-ES completely discards the reward function and only optimizes for novelty to avoid deceptive local optima. To incorporate the fitness back into the formula, another two variations are proposed.

**NSR-ES**：

> **NSR-ES**:

$$
\theta_m^{(t+1)} \leftarrow \theta_m^{(t)} + \alpha \frac{1}{\sigma}\sum_{i=1}^N \epsilon_i \frac{N(\theta^{(t)}_m + \epsilon_i, \mathcal{A}) + F(\theta^{(t)}_m + \epsilon_i)}{2}
$$

**NSRAdapt-ES (NSRA-ES)**：自适应加权参数 $w = 1.0$ 最初。如果性能在若干代内保持平稳，我们开始减小 `w`。然后当性能开始提高时，我们停止减小 `w`，而是增加它。通过这种方式，当性能停止增长时，适应度受到偏爱，否则新颖性受到偏爱。

英文原文：NSRAdapt-ES (NSRA-ES): the adaptive weighting parameter 

$w = 1.0$ initially. We start decreasing `w` if performance stays flat for a number of generations. Then when the performance starts to increase, we stop decreasing `w` but increase it instead. In this way, fitness is preferred when the performance stops growing but novelty is preferred otherwise.

$$
\theta_m^{(t+1)} \leftarrow \theta_m^{(t)} + \alpha \frac{1}{\sigma}\sum_{i=1}^N \epsilon_i \big((1-w) N(\theta^{(t)}_m + \epsilon_i, \mathcal{A}) + w F(\theta^{(t)}_m + \epsilon_i)\big)
$$

![(Left) The environment is Humanoid locomotion with a three-sided wall which plays a role as a deceptive trap to create local optimum. (Right) Experiments compare ES baseline and other variations that encourage exploration. (Image source: NS-ES paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/NS-ES-experiments.png)

#### CEM-RL

> CEM-RL

![Architectures of the (a) CEM-RL and (b) ERL algorithms (Image source: CEM-RL paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/CEM-RL.png)

CEM-RL 方法（[Pourchot & Sigaud, 2019](https://arxiv.org/abs/1810.01222)）将交叉熵方法（CEM）与 [DDPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ddpg) 或 [TD3](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#td3) 结合。这里的 CEM 工作方式与 [上面](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#simple-gaussian-evolution-strategies) 描述的简单高斯 ES 几乎相同，因此可以使用 CMA-ES 替换相同的功能。CEM-RL 建立在 *进化强化学习*（*ERL*；[Khadka & Tumer, 2018](https://papers.nips.cc/paper/7395-evolution-guided-policy-gradient-in-reinforcement-learning.pdf)）的框架上，其中标准 EA 算法选择并进化一组行动者，然后将在此过程中生成的 rollout 经验添加到回放缓冲区中，用于训练 RL-actor 和 RL-critic 网络。

> The CEM-RL method ([Pourchot & Sigaud, 2019](https://arxiv.org/abs/1810.01222)) combines Cross Entropy Method (CEM) with either [DDPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ddpg) or [TD3](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#td3). CEM here works pretty much the same as the simple Gaussian ES described [above](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#simple-gaussian-evolution-strategies) and therefore the same function can be replaced using CMA-ES. CEM-RL is built on the framework of *Evolutionary Reinforcement Learning* (*ERL*; [Khadka & Tumer, 2018](https://papers.nips.cc/paper/7395-evolution-guided-policy-gradient-in-reinforcement-learning.pdf)) in which the standard EA algorithm selects and evolves a population of actors and the rollout experience generated in the process is then added into reply buffer for training both RL-actor and RL-critic networks.

工作流程：

> Workflow:

• 



1\. CEM 种群的平均行动者 $\pi_\mu$ 用一个随机行动者网络初始化。

• 



1\. 评论家网络 $Q$ 也被初始化，它将由 DDPG/TD3 更新。

• 




   1. 重复直到满意：

• a. 采样一组行动者 $\sim \mathcal{N}(\pi_\mu, \Sigma)$。



• b. 评估一半的种群。它们的适应度分数用作累积奖励 $R$ 并添加到回放缓冲区中。



• c. 另一半与评论家一起更新。



• d. 新的 $\pi_mu$ 和 $\Sigma$ 是使用表现最佳的精英样本计算的。[CMA-ES](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#covariance-matrix-adaptation-evolution-strategies-cma-es) 也可以用于参数更新。

英文原文：

• 



1\. The mean actor of the CEM population is $\pi_\mu$ is initialized with a random actor network.

• 



1\. The critic network $Q$ is initialized too, which will be updated by DDPG/TD3.

• 




   1. Repeat until happy:

• a. Sample a population of actors $\sim \mathcal{N}(\pi_\mu, \Sigma)$.



• b. Half of the population is evaluated. Their fitness scores are used as the cumulative reward $R$ and added into replay buffer.



• c. The other half are updated together with the critic.



• d. The new $\pi_mu$ and $\Sigma$ is computed using top performing elite samples. [CMA-ES](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#covariance-matrix-adaptation-evolution-strategies-cma-es) can be used for parameter update too.

### 扩展：深度学习中的 EA

> Extension: EA in Deep Learning

（本节不涉及进化策略，但仍然是一篇有趣且相关的阅读材料。）

> (This section is not on evolution strategies, but still an interesting and relevant reading.)

*进化算法* 已应用于许多深度学习问题。POET（[Wang et al, 2019](https://arxiv.org/abs/1901.01753)）是一个基于 EA 的框架，它试图在解决问题本身的同时生成各种不同的任务。POET 已在我的关于元强化学习的 [上一篇文章](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#task-generation-by-domain-randomization) 中介绍。进化强化学习（ERL）是另一个例子；参见图 7 (b)。

> The *Evolutionary Algorithms* have been applied on many deep learning problems. POET ([Wang et al, 2019](https://arxiv.org/abs/1901.01753)) is a framework based on EA and attempts to generate a variety of different tasks while the problems themselves are being solved. POET has been introduced in my [last post](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#task-generation-by-domain-randomization) on meta-RL. Evolutionary Reinforcement Learning (ERL) is another example; See Fig. 7 (b).

下面我将更详细地介绍两个应用：*基于种群的训练（PBT）* 和 *权重无关神经网络（WANN）*。

> Below I would like to introduce two applications in more detail, *Population-Based Training (PBT)* and *Weight-Agnostic Neural Networks (WANN)*.

#### 超参数调优：PBT

> Hyperparameter Tuning: PBT

![Paradigms of comparing different ways of hyperparameter tuning. (Image source: PBT paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/PBT.png)

基于种群的训练（[Jaderberg, et al, 2017](https://arxiv.org/abs/1711.09846)），简称 **PBT**，将 EA 应用于超参数调优问题。它联合训练一组模型和相应的超参数以获得最佳性能。

> Population-Based Training ([Jaderberg, et al, 2017](https://arxiv.org/abs/1711.09846)), short for **PBT** applies EA on the problem of hyperparameter tuning. It jointly trains a population of models and corresponding hyperparameters for optimal performance.

PBT 从一组随机候选开始，每个候选包含一对模型权重初始化和超参数，$\{(\theta_i, h_i)\mid i=1, \dots, N\}$。每个样本并行训练并异步定期评估其自身性能。每当一个成员被认为准备就绪（即在执行了足够的梯度更新步骤后，或者当性能足够好时），它就有机会通过与整个种群进行比较来更新：

> PBT starts with a set of random candidates, each containing a pair of model weights initialization and hyperparameters, $\{(\theta_i, h_i)\mid i=1, \dots, N\}$. Every sample is trained in parallel and asynchronously evaluates its own performance periodically. Whenever a member deems ready (i.e. after taking enough gradient update steps, or when the performance is good enough), it has a chance to be updated by comparing with the whole population:

- **`exploit()`**: 当此模型表现不佳时，其权重可以替换为表现更好的模型。
- **`explore()`**: 如果模型权重被覆盖，`explore` 步骤会用随机噪声扰动超参数。

> • **`exploit()`**: When this model is under-performing, the weights could be replaced with a better performing model.
> • **`explore()`**: If the model weights are overwritten, `explore` step perturbs the hyperparameters with random noise.

在此过程中，只有有前景的模型和超参数对才能存活并持续演化，从而更好地利用计算资源。

> In this process, only promising model and hyperparameter pairs can survive and keep on evolving, achieving better utilization of computational resources.

![The algorithm of population-based training. (Image source: PBT paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/PBT-algorithm.png)

#### 网络拓扑优化：WANN

> Network Topology Optimization: WANN

*权重无关神经网络*（简称**WANN**；[Gaier & Ha 2019](https://arxiv.org/abs/1906.04358)）通过搜索最小的网络拓扑结构来实验，这些结构无需训练网络权重即可达到最佳性能。通过不考虑网络权重的最佳配置，WANN更侧重于架构本身，使其与[NAS](http://openaccess.thecvf.com/content_cvpr_2018/papers/Zoph_Learning_Transferable_Architectures_CVPR_2018_paper.pdf)的关注点不同。WANN深受一种经典的用于演化网络拓扑的遗传算法的启发，该算法名为*NEAT*（“拓扑增强神经演化”；[Stanley & Miikkulainen 2002](http://nn.cs.utexas.edu/downloads/papers/stanley.gecco02_1.pdf)）。

> *Weight Agnostic Neural* Networks (short for **WANN**; [Gaier & Ha 2019](https://arxiv.org/abs/1906.04358)) experiments with searching for the smallest network topologies that can achieve the optimal performance without training the network weights. By not considering the best configuration of network weights, WANN puts much more emphasis on the architecture itself, making the focus different from [NAS](http://openaccess.thecvf.com/content_cvpr_2018/papers/Zoph_Learning_Transferable_Architectures_CVPR_2018_paper.pdf). WANN is heavily inspired by a classic genetic algorithm to evolve network topologies, called *NEAT* (“Neuroevolution of Augmenting Topologies”; [Stanley & Miikkulainen 2002](http://nn.cs.utexas.edu/downloads/papers/stanley.gecco02_1.pdf)).

WANN 的工作流程与标准 GA 大致相同：

> The workflow of WANN looks pretty much the same as standard GA:

1. 初始化：创建最小网络种群。
2. 评估：使用一系列*共享*权重值进行测试。
3. 排序和选择：按性能和复杂性排序。
4. 变异：通过改变最佳网络来创建新种群。

> • Initialize: Create a population of minimal networks.
> • Evaluation: Test with a range of *shared* weight values.
> • Rank and Selection: Rank by performance and complexity.
> • Mutation: Create new population by varying best networks.

![mutation operations for searching for new network topologies in WANN (Image source: WANN paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/WANN-mutations.png)

在“评估”阶段，所有网络权重都被设置为相同。通过这种方式，WANN实际上是在寻找可以用最小描述长度来描述的网络。在“选择”阶段，网络连接和模型性能都被考虑在内。

> At the “evaluation” stage, all the network weights are set to be the same. In this way, WANN is actually searching for network that can be described with a minimal description length. In the “selection” stage, both the network connection and the model performance are considered.

![Performance of WANN found network topologies on different RL tasks are compared with baseline FF networks commonly used in the literature. "Tuned Shared Weight" only requires adjusting one weight value. (Image source: WANN paper)](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/WANN-results.png)

如图11所示，WANN的结果通过随机权重和共享权重（单一权重）进行评估。有趣的是，即使对所有权重强制执行权重共享并调整这一个参数，WANN也能发现能够实现非凡良好性能的拓扑结构。

> As shown in Fig. 11, WANN results are evaluated with both random weights and shared weights (single weight). It is interesting that even when enforcing weight-sharing on all weights and tuning this single parameter, WANN can discover topologies that achieve non-trivial good performance.

引用来源：

> Cited as:

```
@article{weng2019ES,
  title   = "Evolution Strategies",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2019",
  url     = "https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/"
}
```

### 参考文献

> References

[1] Nikolaus Hansen. [“CMA演化策略：教程”](https://arxiv.org/abs/1604.00772) arXiv preprint arXiv:1604.00772 (2016).

> [1] Nikolaus Hansen. [“The CMA Evolution Strategy: A Tutorial”](https://arxiv.org/abs/1604.00772) arXiv preprint arXiv:1604.00772 (2016).

[2] Marc Toussaint. [幻灯片：“优化导论”](https://ipvs.informatik.uni-stuttgart.de/mlr/marc/teaching/13-Optimization/06-blackBoxOpt.pdf)

> [2] Marc Toussaint. [Slides: “Introduction to Optimization”](https://ipvs.informatik.uni-stuttgart.de/mlr/marc/teaching/13-Optimization/06-blackBoxOpt.pdf)

[3] David Ha. [“演化策略可视化指南”](http://blog.otoro.net/2017/10/29/visual-evolution-strategies/) blog.otoro.net. 2017年10月.

> [3] David Ha. [“A Visual Guide to Evolution Strategies”](http://blog.otoro.net/2017/10/29/visual-evolution-strategies/) blog.otoro.net. Oct 2017.

[4] Daan Wierstra, et al. [“自然演化策略。”](https://arxiv.org/abs/1106.4487) IEEE世界计算智能大会, 2008.

> [4] Daan Wierstra, et al. [“Natural evolution strategies.”](https://arxiv.org/abs/1106.4487) IEEE World Congress on Computational Intelligence, 2008.

[5] Agustinus Kristiadi. [“自然梯度下降”](https://wiseodd.github.io/techblog/2018/03/14/natural-gradient/) 2018年3月.

> [5] Agustinus Kristiadi. [“Natural Gradient Descent”](https://wiseodd.github.io/techblog/2018/03/14/natural-gradient/) Mar 2018.

[6] Razvan Pascanu & Yoshua Bengio. [“重新审视深度网络的自然梯度。”](https://arxiv.org/abs/1301.3584v7) arXiv preprint arXiv:1301.3584 (2013).

> [6] Razvan Pascanu & Yoshua Bengio. [“Revisiting Natural Gradient for Deep Networks.”](https://arxiv.org/abs/1301.3584v7) arXiv preprint arXiv:1301.3584 (2013).

[7] Tim Salimans, et al. [“演化策略作为强化学习的可扩展替代方案。”](https://arxiv.org/abs/1703.03864) arXiv preprint arXiv:1703.03864 (2017).

> [7] Tim Salimans, et al. [“Evolution strategies as a scalable alternative to reinforcement learning.”](https://arxiv.org/abs/1703.03864) arXiv preprint arXiv:1703.03864 (2017).

[8] Edoardo Conti, et al. [“通过新颖性探索智能体群体改进深度强化学习中演化策略的探索。”](https://arxiv.org/abs/1712.06560) NIPS. 2018.

> [8] Edoardo Conti, et al. [“Improving exploration in evolution strategies for deep reinforcement learning via a population of novelty-seeking agents.”](https://arxiv.org/abs/1712.06560) NIPS. 2018.

[9] Aloïs Pourchot & Olivier Sigaud. [“CEM-RL：结合演化和基于梯度的方法进行策略搜索。”](https://arxiv.org/abs/1810.01222) ICLR 2019.

> [9] Aloïs Pourchot & Olivier Sigaud. [“CEM-RL: Combining evolutionary and gradient-based methods for policy search.”](https://arxiv.org/abs/1810.01222) ICLR 2019.

[10] Shauharda Khadka & Kagan Tumer. [“强化学习中演化引导的策略梯度。”](https://papers.nips.cc/paper/7395-evolution-guided-policy-gradient-in-reinforcement-learning.pdf) NIPS 2018.

> [10] Shauharda Khadka & Kagan Tumer. [“Evolution-guided policy gradient in reinforcement learning.”](https://papers.nips.cc/paper/7395-evolution-guided-policy-gradient-in-reinforcement-learning.pdf) NIPS 2018.

[11] Max Jaderberg, et al. [“基于群体的神经网络训练。”](https://arxiv.org/abs/1711.09846) arXiv preprint arXiv:1711.09846 (2017).

> [11] Max Jaderberg, et al. [“Population based training of neural networks.”](https://arxiv.org/abs/1711.09846) arXiv preprint arXiv:1711.09846 (2017).

[12] Adam Gaier & David Ha. [“权重无关神经网络。”](https://arxiv.org/abs/1906.04358) arXiv preprint arXiv:1906.04358 (2019).

> [12] Adam Gaier & David Ha. [“Weight Agnostic Neural Networks.”](https://arxiv.org/abs/1906.04358) arXiv preprint arXiv:1906.04358 (2019).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Simulated Annealing | 模拟退火 | 一种基于物理退火过程的启发式全局优化算法。 |
| Black-box optimization | 黑盒优化 | 在不知道目标函数解析形式或梯度的情况下评估和优化函数的方法。 |
| Evolution Strategies (ES) | 演化策略 | 一种受自然选择启发的黑盒优化算法，属于演化算法家族。 |
| Evolutionary Algorithms (EA) | 演化算法 | 一类受自然选择启发的基于种群的优化算法。 |
| Genetic Algorithms (GA) | 遗传算法 | 演化算法的一个流行子类别，其中个体通常表示为二进制代码序列。 |
| Isotropic Gaussian distribution | 各向同性高斯分布 | 一种多元高斯分布，其协方差矩阵是对角矩阵且所有对角元素相等。 |
| Covariance Matrix Adaptation Evolution Strategies (CMA-ES) | 协方差矩阵自适应演化策略 | 一种高级演化策略，通过自适应地调整协方差矩阵来优化搜索分布。 |
| Evolution path | 演化路径 | CMA-ES中用于跟踪连续移动步长累积方向的向量，以调整步长和协方差矩阵。 |
| Natural Evolution Strategies (NES) | 自然演化策略 | 一种演化策略，通过自然梯度在参数的概率分布空间中进行优化。 |
| Natural Gradient | 自然梯度 | 在概率分布空间中，通过KL散度衡量距离时，寻找最陡峭方向的梯度。 |
| Fisher Information Matrix | 费雪信息矩阵 | 衡量概率分布参数的对数似然函数梯度方差的矩阵。 |
| Rank-based fitness shaping | 基于排名的适应度塑形 | 使用样本在适应度值上的排名而不是原始适应度值来指导优化过程。 |
| Novelty Search ES (NS-ES) | 新颖性搜索演化策略 | 一种演化策略，通过最大化行为新颖性分数来鼓励探索，而非直接优化奖励。 |
| Population-Based Training (PBT) | 基于种群的训练 | 一种将演化算法应用于超参数调优的方法，联合训练一组模型和超参数。 |
| Weight Agnostic Neural Networks (WANN) | 权重无关神经网络 | 一种通过搜索最小网络拓扑结构来实验的神经网络，无需训练网络权重即可达到良好性能。 |
