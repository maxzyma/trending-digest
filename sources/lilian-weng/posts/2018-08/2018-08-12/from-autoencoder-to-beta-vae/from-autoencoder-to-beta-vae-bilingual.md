# 从自编码器到Beta-VAE

> From Autoencoder to Beta-VAE

> 来源：Lil'Log / Lilian Weng，2018-08-12
> 原文链接：https://lilianweng.github.io/posts/2018-08-12-vae/
> 分类：深度学习 / 自编码器

## 核心要点

- 自编码器是一种无监督神经网络，通过编码器和解码器学习数据的压缩表示并重建原始输入。
- 去噪自编码器通过从损坏的输入中恢复原始数据来提高模型的鲁棒性，避免过拟合。
- 稀疏自编码器通过对隐藏单元激活施加稀疏性约束，强制模型在同一时间只有少量神经元被激活。
- 收缩自编码器通过惩罚表示对输入变化的敏感性，鼓励学习到对输入扰动更鲁棒的表示。
- 变分自编码器（VAE）将输入映射到潜在分布，并使用概率编码器和解码器来学习数据的生成过程。
- VAE的损失函数是证据下界（ELBO），通过重参数化技巧实现梯度的反向传播。
- Beta-VAE是VAE的变体，通过引入超参数β来强调学习解耦的潜在因子，以提高表示的可解释性。
- VQ-VAE通过向量量化学习离散潜在变量，将编码器输出映射到有限的码本向量集。
- VQ-VAE-2是分层VQ-VAE，结合自注意力自回归模型生成高保真图像。
- TD-VAE专为序列数据设计，结合状态空间模型、信念状态和跳跃预测来处理时序依赖。

## 正文

[2019-07-18更新：新增关于[VQ-VAE & VQ-VAE-2](https://lilianweng.github.io/posts/2018-08-12-vae/#vq-vae-and-vq-vae-2)的部分。]
  

[2019-07-26更新：新增关于[TD-VAE](https://lilianweng.github.io/posts/2018-08-12-vae/#td-vae)的部分。]
  


> [Updated on 2019-07-18: add a section on [VQ-VAE & VQ-VAE-2](https://lilianweng.github.io/posts/2018-08-12-vae/#vq-vae-and-vq-vae-2).]
>
>
> [Updated on 2019-07-26: add a section on [TD-VAE](https://lilianweng.github.io/posts/2018-08-12-vae/#td-vae).]
>

自编码器被发明用于使用一个中间带有狭窄瓶颈层的神经网络模型来重建高维数据（哎呀，这对于[变分自编码器](https://lilianweng.github.io/posts/2018-08-12-vae/#vae-variational-autoencoder)来说可能不完全正确，我们将在后面的章节中详细探讨）。一个很好的副产品是降维：瓶颈层捕获了一个压缩的潜在编码。这种低维表示可以作为嵌入向量用于各种应用（例如搜索），帮助数据压缩，或者揭示底层数据生成因素。

> Autocoder is invented to reconstruct high-dimensional data using a neural network model with a narrow bottleneck layer in the middle (oops, this is probably not true for [Variational Autoencoder](https://lilianweng.github.io/posts/2018-08-12-vae/#vae-variational-autoencoder), and we will investigate it in details in later sections). A nice byproduct is dimension reduction: the bottleneck layer captures a compressed latent encoding. Such a low-dimensional representation can be used as en embedding vector in various applications (i.e. search), help data compression, or reveal the underlying data generative factors.

### 符号

> Notation

| 符号 | 含义 |
| --- | --- |
| $\mathcal{D}$ | 数据集，$\mathcal{D} = \{ \mathbf{x}^{(1)}, \mathbf{x}^{(2)}, \dots, \mathbf{x}^{(n)} \}$，包含 $n$ 个数据样本；$\vert\mathcal{D}\vert =n $。 |
| $\mathbf{x}^{(i)}$ | 每个数据点是一个 $d$ 维向量，$\mathbf{x}^{(i)} = [x^{(i)}_1, x^{(i)}_2, \dots, x^{(i)}_d]$。 |
| $\mathbf{x}$ | 数据集中的一个数据样本，$\mathbf{x} \in \mathcal{D}$。 |
| $\mathbf{x}’$ | $\mathbf{x}$ 的重建版本。 |
| $\tilde{\mathbf{x}}$ | $\mathbf{x}$ 的损坏版本。 |
| $\mathbf{z}$ | 在瓶颈层中学习到的压缩代码。 |
| $a_j^{(l)}$ | $l$ 层隐藏层中第 $j$ 个神经元的激活函数。 |
| $g_{\phi}(.)$ | 由 $\phi$ 参数化的编码函数。 |
| $f_{\theta}(.)$ | 由 $\theta$ 参数化的解码函数。 |
| $q_{\phi}(\mathbf{z}\vert\mathbf{x})$ | 估计的后验概率函数，也称为概率编码器。 |
| $p_{\theta}(\mathbf{x}\vert\mathbf{z})$ | 给定潜在代码生成真实数据样本的似然，也称为概率解码器。 |

> 英文原表 / English original

| Symbol | Mean |
| --- | --- |
| $\mathcal{D}$ | The dataset, $\mathcal{D} = \{ \mathbf{x}^{(1)}, \mathbf{x}^{(2)}, \dots, \mathbf{x}^{(n)} \}$, contains $n$ data samples; $\vert\mathcal{D}\vert =n $. |
| $\mathbf{x}^{(i)}$ | Each data point is a vector of $d$ dimensions, $\mathbf{x}^{(i)} = [x^{(i)}_1, x^{(i)}_2, \dots, x^{(i)}_d]$. |
| $\mathbf{x}$ | One data sample from the dataset, $\mathbf{x} \in \mathcal{D}$. |
| $\mathbf{x}’$ | The reconstructed version of $\mathbf{x}$. |
| $\tilde{\mathbf{x}}$ | The corrupted version of $\mathbf{x}$. |
| $\mathbf{z}$ | The compressed code learned in the bottleneck layer. |
| $a_j^{(l)}$ | The activation function for the $j$-th neuron in the $l$-th hidden layer. |
| $g_{\phi}(.)$ | The encoding function parameterized by $\phi$. |
| $f_{\theta}(.)$ | The decoding function parameterized by $\theta$. |
| $q_{\phi}(\mathbf{z}\vert\mathbf{x})$ | Estimated posterior probability function, also known as probabilistic encoder . |
| $p_{\theta}(\mathbf{x}\vert\mathbf{z})$ | Likelihood of generating true data sample given the latent code, also known as probabilistic decoder . |

### 自编码器

> Autoencoder

**自编码器**是一种神经网络，旨在以无监督的方式学习一个恒等函数，以重建原始输入，同时在此过程中压缩数据，从而发现更高效、更紧凑的表示。这个想法起源于[20世纪80年代](https://en.wikipedia.org/wiki/Autoencoder)，后来由[Hinton & Salakhutdinov, 2006](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.459.3788&rep=rep1&type=pdf)的开创性论文推广。

> **Autoencoder** is a neural network designed to learn an identity function in an unsupervised way  to reconstruct the original input while compressing the data in the process so as to discover a more efficient and compressed representation. The idea was originated in [the 1980s](https://en.wikipedia.org/wiki/Autoencoder), and later promoted by the seminal paper by [Hinton & Salakhutdinov, 2006](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.459.3788&rep=rep1&type=pdf).

它由两个网络组成：

> It consists of two networks:

- *编码器*网络：它将原始高维输入转换为潜在的低维代码。输入大小大于输出大小。
- *解码器*网络：解码器网络从代码中恢复数据，通常具有越来越大的输出层。

> • *Encoder* network: It translates the original high-dimension input into the latent low-dimensional code. The input size is larger than the output size.
> • *Decoder* network: The decoder network recovers the data from the code, likely with larger and larger output layers.

![Illustration of autoencoder model architecture.](https://lilianweng.github.io/posts/2018-08-12-vae/autoencoder-architecture.png)

编码器网络本质上完成了[降维](https://en.wikipedia.org/wiki/Dimensionality_reduction)，就像我们使用主成分分析（PCA）或矩阵分解（MF）一样。此外，自编码器明确地针对从代码中重建数据进行了优化。一个好的中间表示不仅可以捕获潜在变量，而且还有利于完整的[解压缩](https://ai.googleblog.com/2016/09/image-compression-with-neural-networks.html)过程。

> The encoder network essentially accomplishes the [dimensionality reduction](https://en.wikipedia.org/wiki/Dimensionality_reduction), just like how we would use Principal Component Analysis (PCA) or Matrix Factorization (MF) for. In addition, the autoencoder is explicitly optimized for the data reconstruction from the code. A good intermediate representation not only can capture latent variables, but also benefits a full [decompression](https://ai.googleblog.com/2016/09/image-compression-with-neural-networks.html) process.

该模型包含一个编码器函数$g(.)$，由$\phi$参数化，以及一个解码器函数$f(.)$，由$\theta$参数化。在瓶颈层为输入$\mathbf{x}$学习到的低维代码是$\mathbf{z} = g_\phi(\mathbf{x})$，重建的输入是$\mathbf{x}’ = f_\theta(g_\phi(\mathbf{x}))$。

> The model contains an encoder function $g(.)$ parameterized by $\phi$ and a decoder function $f(.)$ parameterized by $\theta$. The low-dimensional code learned for input $\mathbf{x}$ in the bottleneck layer is $\mathbf{z} = g_\phi(\mathbf{x})$ and the reconstructed input is $\mathbf{x}’ = f_\theta(g_\phi(\mathbf{x}))$.

参数 $(\theta, \phi)$ 被一起学习，以输出与原始输入 $\mathbf{x} \approx f_\theta(g_\phi(\mathbf{x}))$ 相同的重建数据样本，换句话说，就是学习一个恒等函数。有多种指标可以量化两个向量之间的差异，例如当激活函数是 sigmoid 时使用交叉熵，或者简单地使用 MSE 损失：

> The parameters $(\theta, \phi)$ are learned together to output a reconstructed data sample same as the original input, $\mathbf{x} \approx f_\theta(g_\phi(\mathbf{x}))$, or in other words, to learn an identity function. There are various metrics to quantify the difference between two vectors, such as cross entropy when the activation function is sigmoid, or as simple as MSE loss:

$$
L_\text{AE}(\theta, \phi) = \frac{1}{n}\sum_{i=1}^n (\mathbf{x}^{(i)} - f_\theta(g_\phi(\mathbf{x}^{(i)})))^2
$$

### 去噪自编码器

> Denoising Autoencoder

由于自编码器学习的是恒等函数，当网络参数多于数据点数量时，我们面临“过拟合”的风险。

> Since the autoencoder learns the identity function, we are facing the risk of “overfitting” when there are more network parameters than the number of data points.

为了避免过拟合并提高鲁棒性，**去噪自编码器**（Vincent et al. 2008）对基本自编码器提出了一种修改。输入通过以随机方式向输入向量添加噪声或遮蔽其某些值而被部分损坏，$\tilde{\mathbf{x}} \sim \mathcal{M}_\mathcal{D}(\tilde{\mathbf{x}} \vert \mathbf{x})$。然后训练模型以恢复原始输入（注意：不是损坏的输入）。

英文原文：To avoid overfitting and improve the robustness, Denoising Autoencoder (Vincent et al. 2008) proposed a modification to the basic autoencoder. The input is partially corrupted by adding noises to or masking some values of the input vector in a stochastic manner, 

$\tilde{\mathbf{x}} \sim \mathcal{M}_\mathcal{D}(\tilde{\mathbf{x}} \vert \mathbf{x})$. Then the model is trained to recover the original input (note: not the corrupt one).

$$
\begin{aligned}
\tilde{\mathbf{x}}^{(i)} &\sim \mathcal{M}_\mathcal{D}(\tilde{\mathbf{x}}^{(i)} \vert \mathbf{x}^{(i)})\\
L_\text{DAE}(\theta, \phi) &= \frac{1}{n} \sum_{i=1}^n (\mathbf{x}^{(i)} - f_\theta(g_\phi(\tilde{\mathbf{x}}^{(i)})))^2
\end{aligned}
$$

其中 $\mathcal{M}_\mathcal{D}$ 定义了从真实数据样本到带噪声或损坏样本的映射。

> where $\mathcal{M}_\mathcal{D}$ defines the mapping from the true data samples to the noisy or corrupted ones.

![Illustration of denoising autoencoder model architecture.](https://lilianweng.github.io/posts/2018-08-12-vae/denoising-autoencoder-architecture.png)

这种设计的灵感来源于人类即使在视野部分被遮挡或损坏的情况下也能轻易识别物体或场景的事实。为了“修复”部分损坏的输入，去噪自编码器必须发现并捕获输入维度之间的关系，以便推断缺失的部分。

> This design is motivated by the fact that humans can easily recognize an object or a scene even the view is partially occluded or corrupted. To “repair” the partially destroyed input, the denoising autoencoder has to discover and capture relationship between dimensions of input in order to infer missing pieces.

对于具有高冗余度的高维输入（如图像），模型可能依赖于从许多输入维度组合中收集到的证据来恢复去噪版本，而不是过度拟合一个维度。这为学习*鲁棒的*潜在表示奠定了良好基础。

> For high dimensional input with high redundancy, like images, the model is likely to depend on evidence gathered from a combination of many input dimensions to recover the denoised version rather than to overfit one dimension. This builds up a good foundation for learning *robust* latent representation.

噪声由随机映射 $\mathcal{M}_\mathcal{D}(\tilde{\mathbf{x}} \vert \mathbf{x})$ 控制，并且不特定于某种特定类型的损坏过程（即遮蔽噪声、高斯噪声、椒盐噪声等）。自然地，损坏过程可以配备先验知识

> The noise is controlled by a stochastic mapping $\mathcal{M}_\mathcal{D}(\tilde{\mathbf{x}} \vert \mathbf{x})$, and it is not specific to a particular type of corruption process (i.e. masking noise, Gaussian noise, salt-and-pepper noise, etc.). Naturally the corruption process can be equipped with prior knowledge

在原始 DAE 论文的实验中，噪声是这样应用的：随机选择固定比例的输入维度，并将其值强制设为 0。听起来很像 dropout，对吗？嗯，去噪自编码器是在 2008 年提出的，比 dropout 论文早 4 年（[Hinton, et al. 2012](https://www.cs.toronto.edu/~hinton/absps/JMLRdropout.pdf)） ;)

> In the experiment of the original DAE paper, the noise is applied in this way: a fixed proportion of input dimensions are selected at random and their values are forced to 0. Sounds a lot like dropout, right? Well, the denoising autoencoder was proposed in 2008, 4 years before the dropout paper ([Hinton, et al. 2012](https://www.cs.toronto.edu/~hinton/absps/JMLRdropout.pdf)) ;)

### 稀疏自编码器

> Sparse Autoencoder

**稀疏自编码器**对隐藏单元激活施加“稀疏”约束，以避免过拟合并提高鲁棒性。它强制模型在同一时间只有少量隐藏单元被激活，换句话说，一个隐藏神经元在大部分时间应该处于非激活状态。

> **Sparse Autoencoder** applies a “sparse” constraint on the hidden unit activation to avoid overfitting and improve robustness. It forces the model to only have a small number of hidden units being activated at the same time, or in other words, one hidden neuron should be inactivate most of time.

回想一下，常见的[激活函数](http://cs231n.github.io/neural-networks-1/#actfun)包括 sigmoid、tanh、relu、leaky relu 等。当值接近 1 时，神经元被激活；当值接近 0 时，神经元处于非激活状态。

> Recall that common [activation functions](http://cs231n.github.io/neural-networks-1/#actfun) include sigmoid, tanh, relu, leaky relu, etc. A neuron is activated when the value is close to 1 and inactivate with a value close to 0.

假设有$s_l$个神经元位于第$l$个隐藏层，该层中第$j$个神经元的激活函数标记为$a^{(l)}_j(.)$，$j=1, \dots, s_l$。该神经元的激活分数$\hat{\rho}_j$预计是一个小数$\rho$，称为*稀疏性参数*；常见配置是$\rho = 0.05$。

> Let’s say there are $s_l$ neurons in the $l$ -th hidden layer and the activation function for the $j$ -th neuron in this layer is labelled as $a^{(l)}_j(.)$, $j=1, \dots, s_l$. The fraction of activation of this neuron $\hat{\rho}_j$ is expected to be a small number $\rho$, known as *sparsity parameter*; a common config is $\rho = 0.05$.

$$
\hat{\rho}_j^{(l)} = \frac{1}{n} \sum_{i=1}^n [a_j^{(l)}(\mathbf{x}^{(i)})] \approx \rho
$$

通过在损失函数中添加一个惩罚项来实现这一约束。KL散度 $D_\text{KL}$ 衡量了两个伯努利分布之间的差异，其中一个的均值为 $\rho$，另一个的均值为 $\hat{\rho}_j^{(l)}$。超参数 $\beta$ 控制我们希望对稀疏性损失施加的惩罚强度。

> This constraint is achieved by adding a penalty term into the loss function. The KL-divergence $D_\text{KL}$ measures the difference between two Bernoulli distributions, one with mean $\rho$ and the other with mean $\hat{\rho}_j^{(l)}$. The hyperparameter $\beta$ controls how strong the penalty we want to apply on the sparsity loss.

$$
\begin{aligned}
L_\text{SAE}(\theta) 
&= L(\theta) + \beta \sum_{l=1}^L \sum_{j=1}^{s_l} D_\text{KL}(\rho \| \hat{\rho}_j^{(l)}) \\
&= L(\theta) + \beta \sum_{l=1}^L \sum_{j=1}^{s_l} \rho\log\frac{\rho}{\hat{\rho}_j^{(l)}} + (1-\rho)\log\frac{1-\rho}{1-\hat{\rho}_j^{(l)}}
\end{aligned}
$$

![The KL divergence between a Bernoulli distribution with mean $\rho=0.25$ and a Bernoulli distribution with mean $0 \leq \hat{\rho} \leq 1$.](https://lilianweng.github.io/posts/2018-08-12-vae/kl-metric-sparse-autoencoder.png)

**`k` -稀疏自编码器**

英文原文：`k` -Sparse Autoencoder

在 $k$ -稀疏自编码器 ([Makhzani and Frey, 2013](https://arxiv.org/abs/1312.5663)) 中，稀疏性是通过在线性激活函数的瓶颈层中只保留前 k 个最高激活值来强制实现的。首先，我们通过编码器网络进行前向传播以获得压缩代码：$\mathbf{z} = g(\mathbf{x})$。对代码向量 $\mathbf{z}$ 中的值进行排序。只保留 k 个最大值，而其他神经元则设置为 0。这也可以在具有可调阈值的 ReLU 层中完成。现在我们有了一个稀疏化的代码：$\mathbf{z}’ = \text{Sparsify}(\mathbf{z})$。从稀疏化的代码 $L = |\mathbf{x} - f(\mathbf{z}’) |_2^2$ 计算输出和损失。并且，反向传播只通过前 k 个激活的隐藏单元！

> In $k$ -Sparse Autoencoder ([Makhzani and Frey, 2013](https://arxiv.org/abs/1312.5663)), the sparsity is enforced by only keeping the top k highest activations in the bottleneck layer with linear activation function.
> First we run feedforward through the encoder network to get the compressed code: $\mathbf{z} = g(\mathbf{x})$.
> Sort the values  in the code vector $\mathbf{z}$. Only the k largest values are kept while other neurons are set to 0. This can be done in a ReLU layer with an adjustable threshold too. Now we have a sparsified code: $\mathbf{z}’ = \text{Sparsify}(\mathbf{z})$.
> Compute the output and the loss from the sparsified code, $L = |\mathbf{x} - f(\mathbf{z}’) |_2^2$.
> And, the back-propagation only goes through the top k activated hidden units!

![Filters of the k-sparse autoencoder for different sparsity levels k, learnt from MNIST with 1000 hidden units.. (Image source: Makhzani and Frey, 2013 )](https://lilianweng.github.io/posts/2018-08-12-vae/k-sparse-autoencoder.png)

### 收缩自编码器

> Contractive Autoencoder

与稀疏自编码器类似，**收缩自编码器** ([Rifai, et al, 2011](http://www.icml-2011.org/papers/455_icmlpaper.pdf)) 鼓励学习到的表示保持在收缩空间中，以获得更好的鲁棒性。

> Similar to sparse autoencoder, **Contractive Autoencoder** ([Rifai, et al, 2011](http://www.icml-2011.org/papers/455_icmlpaper.pdf)) encourages the learned representation to stay in a contractive space for better robustness.

它在损失函数中添加了一个项，以惩罚表示对输入过于敏感，从而提高对训练数据点周围小扰动的鲁棒性。敏感性通过编码器激活相对于输入的雅可比矩阵的 Frobenius 范数来衡量：

> It adds a term in the loss function to penalize the representation being too sensitive to the input,  and thus improve the robustness to small perturbations around the training data points. The sensitivity is measured by the Frobenius norm of the Jacobian matrix of the encoder activations with respect to the input:

$$
\|J_f(\mathbf{x})\|_F^2 = \sum_{ij} \Big( \frac{\partial h_j(\mathbf{x})}{\partial x_i} \Big)^2
$$

其中 $h_j$ 是压缩代码 $\mathbf{z} = f(x)$ 中的一个单元输出。

> where $h_j$ is one unit output in the compressed code $\mathbf{z} = f(x)$.

这个惩罚项是学习到的编码对输入维度所有偏导数的平方和。作者声称，经验上发现这个惩罚能够雕刻出对应于低维非线性流形的表示，同时对正交于流形的大多数方向保持更不变性。

> This penalty term is the sum of squares of all partial derivatives of the learned encoding with respect to input dimensions. The authors claimed that empirically this penalty was found to  carve a representation that corresponds to a lower-dimensional non-linear manifold, while staying more invariant to majority directions orthogonal to the manifold.

### VAE：变分自编码器

> VAE: Variational Autoencoder

**变分自编码器** ([Kingma & Welling, 2014](https://arxiv.org/abs/1312.6114)) 的思想，简称 **VAE**，实际上与上述所有自编码器模型都不太相似，而是深深植根于变分贝叶斯和图模型的方法。

> The idea of **Variational Autoencoder** ([Kingma & Welling, 2014](https://arxiv.org/abs/1312.6114)), short for **VAE**, is actually less similar to all the autoencoder models above, but deeply rooted in the methods of variational bayesian and graphical model.

我们不是将输入映射到一个 *固定* 向量，而是希望将其映射到一个分布。我们将这个分布标记为 $p_\theta$，由 $\theta$ 参数化。数据输入 $\mathbf{x}$ 和潜在编码向量 $\mathbf{z}$ 之间的关系可以完全定义为：

> Instead of mapping the input into a *fixed* vector, we want to map it into a distribution. Let’s label this distribution as $p_\theta$, parameterized by $\theta$.  The relationship between the data input $\mathbf{x}$ and the latent encoding vector $\mathbf{z}$ can be fully defined by:

• 先验 $p_\theta(\mathbf{z})$

• 似然 $p_\theta(\mathbf{x}\vert\mathbf{z})$

• 后验 $p_\theta(\mathbf{z}\vert\mathbf{x})$

英文原文：

• Prior $p_\theta(\mathbf{z})$

• Likelihood $p_\theta(\mathbf{x}\vert\mathbf{z})$

• Posterior $p_\theta(\mathbf{z}\vert\mathbf{x})$

假设我们知道这个分布的真实参数$\theta^{*}$。为了生成一个看起来像真实数据点$\mathbf{x}^{(i)}$的样本，我们遵循以下步骤：

> Assuming that we know the real parameter $\theta^{*}$ for this distribution. In order to generate a sample that looks like a real data point $\mathbf{x}^{(i)}$, we follow these steps:

1\. 首先，抽取一个$\mathbf{z}^{(i)}$从先验分布中$p_{\theta^{\ast}}(\mathbf{z})$。

2\. 接着一个值$\mathbf{x}^{(i)}$从一个条件分布中生成$p_{\theta^{\ast}}(\mathbf{x} \vert \mathbf{z} = \mathbf{z}^{(i)})$。

英文原文：

1\. First, sample a $\mathbf{z}^{(i)}$ from a prior distribution $p_{\theta^{\ast}}(\mathbf{z})$.

2\. Then a value $\mathbf{x}^{(i)}$ is generated from a conditional distribution $p_{\theta^{\ast}}(\mathbf{x} \vert \mathbf{z} = \mathbf{z}^{(i)})$.

最优参数$\theta^{*}$是使生成真实数据样本的概率最大化的参数：

> The optimal parameter $\theta^{*}$ is the one that maximizes the probability of generating real data samples:

$$
\theta^{*} = \arg\max_\theta \prod_{i=1}^n p_\theta(\mathbf{x}^{(i)})
$$

通常我们使用对数概率将右侧的乘积转换为和：

> Commonly we use the log probabilities to convert the product on RHS to a sum:

$$
\theta^{*} = \arg\max_\theta \sum_{i=1}^n \log p_\theta(\mathbf{x}^{(i)})
$$

现在我们更新方程，以更好地展示数据生成过程，从而涉及编码向量：

> Now let’s update the equation to better demonstrate the data generation process so as to involve the encoding vector:

$$
p_\theta(\mathbf{x}^{(i)}) = \int p_\theta(\mathbf{x}^{(i)}\vert\mathbf{z}) p_\theta(\mathbf{z}) d\mathbf{z}
$$

不幸的是，以这种方式计算$p_\theta(\mathbf{x}^{(i)})$并不容易，因为检查$\mathbf{z}$的所有可能值并将其求和非常昂贵。为了缩小值空间以方便更快的搜索，我们希望引入一个新的近似函数，以输出给定输入$\mathbf{x}$、$q_\phi(\mathbf{z}\vert\mathbf{x})$以及由$\phi$参数化的可能代码。

> Unfortunately it is not easy to compute $p_\theta(\mathbf{x}^{(i)})$ in this way, as it is very expensive to check all the possible values of $\mathbf{z}$ and sum them up. To narrow down the value space to facilitate faster search, we would like to introduce a new approximation function to output what is a likely code given an input $\mathbf{x}$, $q_\phi(\mathbf{z}\vert\mathbf{x})$, parameterized by $\phi$.

![The graphical model involved in Variational Autoencoder.  Solid lines denote the generative distribution $p\_\theta(.)$ and dashed lines denote the distribution $q\_\phi (\mathbf{z}\vert\mathbf{x})$ to approximate the intractable posterior $p\_\theta (\mathbf{z}\vert\mathbf{x})$.](https://lilianweng.github.io/posts/2018-08-12-vae/VAE-graphical-model.png)

现在，这个结构看起来很像一个自编码器：

> Now the structure looks a lot like an autoencoder:

• 条件概率$p_\theta(\mathbf{x} \vert \mathbf{z})$定义了一个生成模型，类似于上面介绍的解码器$f_\theta(\mathbf{x} \vert \mathbf{z})$。$p_\theta(\mathbf{x} \vert \mathbf{z})$也称为*概率解码器*。

• 近似函数$q_\phi(\mathbf{z} \vert \mathbf{x})$是*概率编码器*，扮演着与上面$g_\phi(\mathbf{z} \vert \mathbf{x})$类似的角色。

英文原文：

• The conditional probability $p_\theta(\mathbf{x} \vert \mathbf{z})$ defines a generative model, similar to the decoder $f_\theta(\mathbf{x} \vert \mathbf{z})$ introduced above. $p_\theta(\mathbf{x} \vert \mathbf{z})$ is also known as *probabilistic decoder*.

• The approximation function $q_\phi(\mathbf{z} \vert \mathbf{x})$ is the *probabilistic encoder*, playing a similar role as $g_\phi(\mathbf{z} \vert \mathbf{x})$ above.

#### 损失函数：ELBO

> Loss Function: ELBO

估计的后验$q_\phi(\mathbf{z}\vert\mathbf{x})$应该非常接近真实的后验$p_\theta(\mathbf{z}\vert\mathbf{x})$。我们可以使用[Kullback-Leibler散度](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)来量化这两个分布之间的距离。KL散度$D_\text{KL}(X|Y)$衡量如果使用分布Y来表示X会损失多少信息。

> The estimated posterior $q_\phi(\mathbf{z}\vert\mathbf{x})$ should be very close to the real one $p_\theta(\mathbf{z}\vert\mathbf{x})$. We can use [Kullback-Leibler divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence) to quantify the distance between these two distributions. KL divergence $D_\text{KL}(X|Y)$ measures how much information is lost if the distribution Y is used to represent X.

在我们的例子中，我们希望最小化$D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) | p_\theta(\mathbf{z}\vert\mathbf{x}) )$关于$\phi$的值。

> In our case we want to minimize $D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) | p_\theta(\mathbf{z}\vert\mathbf{x}) )$ with respect to $\phi$.

但是为什么使用 $D_\text{KL}(q_\phi | p_\theta)$（反向 KL）而不是 $D_\text{KL}(p_\theta | q_\phi)$（正向 KL）呢？Eric Jang 在他关于贝叶斯变分方法的[文章](https://blog.evjang.com/2016/08/variational-bayes.html)中对此有很好的解释。快速回顾一下：

> But why use $D_\text{KL}(q_\phi | p_\theta)$ (reversed KL) instead of $D_\text{KL}(p_\theta | q_\phi)$ (forward KL)? Eric Jang has a great explanation in his [post](https://blog.evjang.com/2016/08/variational-bayes.html) on Bayesian Variational methods. As a quick recap:

![Forward and reversed KL divergence have different demands on how to match two distributions. (Image source: blog.evjang.com/2016/08/variational-bayes.html )](https://lilianweng.github.io/posts/2018-08-12-vae/forward_vs_reversed_KL.png)

• 正向 KL 散度：$D_\text{KL}(P|Q) = \mathbb{E}_{z\sim P(z)} \log\frac{P(z)}{Q(z)}$；我们必须确保在 P(z)>0 的任何地方，Q(z)>0。优化的变分分布 $q(z)$ 必须覆盖整个 $p(z)$。

• 反向 KL 散度：$D_\text{KL}(Q|P) = \mathbb{E}_{z\sim Q(z)} \log\frac{Q(z)}{P(z)}$；最小化反向 KL 散度会将 $Q(z)$ 挤压到 $P(z)$ 之下。

英文原文：

• Forward KL divergence: $D_\text{KL}(P|Q) = \mathbb{E}_{z\sim P(z)} \log\frac{P(z)}{Q(z)}$; we have to ensure that Q(z)>0 wherever P(z)>0. The optimized variational distribution $q(z)$ has to cover over the entire $p(z)$.

• Reversed KL divergence: $D_\text{KL}(Q|P) = \mathbb{E}_{z\sim Q(z)} \log\frac{Q(z)}{P(z)}$; minimizing the reversed KL divergence squeezes the $Q(z)$ under $P(z)$.

现在我们来展开这个方程：

> Let’s now expand the equation:

$$
\begin{aligned}
& D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z}\vert\mathbf{x}) ) & \\
&=\int q_\phi(\mathbf{z} \vert \mathbf{x}) \log\frac{q_\phi(\mathbf{z} \vert \mathbf{x})}{p_\theta(\mathbf{z} \vert \mathbf{x})} d\mathbf{z} & \\
&=\int q_\phi(\mathbf{z} \vert \mathbf{x}) \log\frac{q_\phi(\mathbf{z} \vert \mathbf{x})p_\theta(\mathbf{x})}{p_\theta(\mathbf{z}, \mathbf{x})} d\mathbf{z} & \scriptstyle{\text{; Because }p(z \vert x) = p(z, x) / p(x)} \\
&=\int q_\phi(\mathbf{z} \vert \mathbf{x}) \big( \log p_\theta(\mathbf{x}) + \log\frac{q_\phi(\mathbf{z} \vert \mathbf{x})}{p_\theta(\mathbf{z}, \mathbf{x})} \big) d\mathbf{z} & \\
&=\log p_\theta(\mathbf{x}) + \int q_\phi(\mathbf{z} \vert \mathbf{x})\log\frac{q_\phi(\mathbf{z} \vert \mathbf{x})}{p_\theta(\mathbf{z}, \mathbf{x})} d\mathbf{z} & \scriptstyle{\text{; Because }\int q(z \vert x) dz = 1}\\
&=\log p_\theta(\mathbf{x}) + \int q_\phi(\mathbf{z} \vert \mathbf{x})\log\frac{q_\phi(\mathbf{z} \vert \mathbf{x})}{p_\theta(\mathbf{x}\vert\mathbf{z})p_\theta(\mathbf{z})} d\mathbf{z} & \scriptstyle{\text{; Because }p(z, x) = p(x \vert z) p(z)} \\
&=\log p_\theta(\mathbf{x}) + \mathbb{E}_{\mathbf{z}\sim q_\phi(\mathbf{z} \vert \mathbf{x})}[\log \frac{q_\phi(\mathbf{z} \vert \mathbf{x})}{p_\theta(\mathbf{z})} - \log p_\theta(\mathbf{x} \vert \mathbf{z})] &\\
&=\log p_\theta(\mathbf{x}) + D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z})) - \mathbb{E}_{\mathbf{z}\sim q_\phi(\mathbf{z}\vert\mathbf{x})}\log p_\theta(\mathbf{x}\vert\mathbf{z}) &
\end{aligned}
$$

所以我们得到：

> So we have:

$$
D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z}\vert\mathbf{x}) ) =\log p_\theta(\mathbf{x}) + D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z})) - \mathbb{E}_{\mathbf{z}\sim q_\phi(\mathbf{z}\vert\mathbf{x})}\log p_\theta(\mathbf{x}\vert\mathbf{z})
$$

一旦重新排列方程的左右两边，

> Once rearrange the left and right hand side of the equation,

$$
\log p_\theta(\mathbf{x}) - D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z}\vert\mathbf{x}) ) = \mathbb{E}_{\mathbf{z}\sim q_\phi(\mathbf{z}\vert\mathbf{x})}\log p_\theta(\mathbf{x}\vert\mathbf{z}) - D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z}))
$$

方程的左侧正是我们在学习真实分布时想要最大化的内容：我们想要最大化生成真实数据的（对数）似然（即 $\log p_\theta(\mathbf{x})$），并最小化真实后验分布与估计后验分布之间的差异（项 $D_\text{KL}$ 类似于一个正则化器）。请注意，$p_\theta(\mathbf{x})$ 相对于 $q_\phi$ 是固定的。

> The LHS of the equation is exactly what we want to maximize when learning the true distributions: we want to maximize the (log-)likelihood of generating real data (that is $\log p_\theta(\mathbf{x})$) and also minimize the difference between the real and estimated posterior distributions (the term $D_\text{KL}$ works like a regularizer).  Note that $p_\theta(\mathbf{x})$ is fixed with respect to $q_\phi$.

上述的负值定义了我们的损失函数：

> The negation of the above defines our loss function:

$$
\begin{aligned}
L_\text{VAE}(\theta, \phi) 
&= -\log p_\theta(\mathbf{x}) + D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z}\vert\mathbf{x}) )\\
&= - \mathbb{E}_{\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})} \log p_\theta(\mathbf{x}\vert\mathbf{z}) + D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z}) ) \\
\theta^{*}, \phi^{*} &= \arg\min_{\theta, \phi} L_\text{VAE}
\end{aligned}
$$

在变分贝叶斯方法中，这个损失函数被称为 *变分下界*，或 *证据下界*。名称中的“下界”部分源于 KL 散度总是非负的，因此 $-L_\text{VAE}$ 是 $\log p_\theta (\mathbf{x})$ 的下界。

> In Variational Bayesian methods, this loss function is known as the *variational lower bound*, or *evidence lower bound*. The “lower bound” part in the name comes from the fact that KL divergence is always non-negative and thus $-L_\text{VAE}$ is the lower bound of $\log p_\theta (\mathbf{x})$.

$$
-L_\text{VAE} = \log p_\theta(\mathbf{x}) - D_\text{KL}( q_\phi(\mathbf{z}\vert\mathbf{x}) \| p_\theta(\mathbf{z}\vert\mathbf{x}) ) \leq \log p_\theta(\mathbf{x})
$$

因此，通过最小化损失，我们正在最大化生成真实数据样本概率的下限。

> Therefore by minimizing the loss, we are maximizing the lower bound of the probability of generating real data samples.

#### 重参数化技巧

> Reparameterization Trick

损失函数中的期望项需要从$\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})$。采样是一个随机过程，因此我们无法反向传播梯度。为了使其可训练，引入了重参数化技巧：通常可以将随机变量$\mathbf{z}$表示为确定性变量$\mathbf{z} = \mathcal{T}_\phi(\mathbf{x}, \boldsymbol{\epsilon})$，其中$\boldsymbol{\epsilon}$是一个辅助的独立随机变量，并且变换函数$\mathcal{T}_\phi$由$\phi$参数化，将$\boldsymbol{\epsilon}$转换为$\mathbf{z}$。

> The expectation term in the loss function invokes generating samples from $\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})$. Sampling is a stochastic process and therefore we cannot backpropagate the gradient. To make it trainable, the reparameterization trick is introduced: It is often possible to express the random variable $\mathbf{z}$ as a deterministic variable $\mathbf{z} = \mathcal{T}_\phi(\mathbf{x}, \boldsymbol{\epsilon})$, where $\boldsymbol{\epsilon}$ is an auxiliary independent random variable, and the transformation function $\mathcal{T}_\phi$ parameterized by $\phi$ converts $\boldsymbol{\epsilon}$ to $\mathbf{z}$.

例如，$q_\phi(\mathbf{z}\vert\mathbf{x})$ 形式的常见选择是具有对角协方差结构的多变量高斯分布：

> For example, a common choice of the form of $q_\phi(\mathbf{z}\vert\mathbf{x})$ is a multivariate Gaussian with a diagonal covariance structure:

$$
\begin{aligned}
\mathbf{z} &\sim q_\phi(\mathbf{z}\vert\mathbf{x}^{(i)}) = \mathcal{N}(\mathbf{z}; \boldsymbol{\mu}^{(i)}, \boldsymbol{\sigma}^{2(i)}\boldsymbol{I}) & \\
\mathbf{z} &= \boldsymbol{\mu} + \boldsymbol{\sigma} \odot \boldsymbol{\epsilon} \text{, where } \boldsymbol{\epsilon} \sim \mathcal{N}(0, \boldsymbol{I}) & \scriptstyle{\text{; Reparameterization trick.}}
\end{aligned}
$$

其中 $\odot$ 指的是逐元素乘积。

> where $\odot$ refers to element-wise product.

![Illustration of how the reparameterization trick makes the $\mathbf{z}$ sampling process trainable.(Image source: Slide 12 in Kingma’s NIPS 2015 workshop talk )](https://lilianweng.github.io/posts/2018-08-12-vae/reparameterization-trick.png)

重参数化技巧也适用于其他类型的分布，而不仅仅是高斯分布。在多变量高斯分布的情况下，我们通过使用重参数化技巧显式学习分布的均值和方差 $\mu$ 和 $\sigma$ 来使模型可训练，而随机性则保留在随机变量 $\boldsymbol{\epsilon} \sim \mathcal{N}(0, \boldsymbol{I})$ 中。

> The reparameterization trick works for other types of distributions too, not only Gaussian.
> In the multivariate Gaussian case, we make the model trainable by learning the mean and variance of the distribution, $\mu$ and $\sigma$, explicitly using the reparameterization trick, while the stochasticity remains in the random variable $\boldsymbol{\epsilon} \sim \mathcal{N}(0, \boldsymbol{I})$.

![Illustration of variational autoencoder model with the multivariate Gaussian assumption.](https://lilianweng.github.io/posts/2018-08-12-vae/vae-gaussian.png)

### Beta-VAE

> Beta-VAE

如果推断的潜在表示 $\mathbf{z}$ 中的每个变量只对一个生成因子敏感，并且相对地不受其他因子的影响，我们就会说这种表示是解耦的或因子化的。解耦表示的一个常见好处是 *良好的可解释性* 和易于泛化到各种任务。

> If each variable in the inferred latent representation $\mathbf{z}$ is only sensitive to one single generative factor and relatively invariant to other factors, we will say this representation is disentangled or factorized. One benefit that often comes with disentangled representation is *good interpretability* and easy generalization to a variety of tasks.

例如，一个在人脸照片上训练的模型可能会在不同的维度中捕捉到性别、肤色、发色、发长、情绪、是否戴眼镜以及许多其他相对独立的因素。这种解耦表示对人脸图像生成非常有益。

> For example, a model trained on photos of human faces might capture the gentle, skin color, hair color, hair length, emotion, whether wearing a pair of glasses and many other relatively independent factors in separate dimensions. Such a disentangled representation is very beneficial to facial image generation.

β-VAE ([Higgins et al., 2017](https://openreview.net/forum?id=Sy2fzU9gl)) 是变分自编码器的一种修改，特别强调发现解耦的潜在因子。遵循 VAE 中相同的动机，我们希望最大化生成真实数据的概率，同时保持真实后验分布和估计后验分布之间的距离很小（例如，小于一个小的常数 $\delta$）：

> β-VAE ([Higgins et al., 2017](https://openreview.net/forum?id=Sy2fzU9gl)) is a modification of Variational Autoencoder with a special emphasis to discover disentangled latent factors. Following the same incentive in VAE, we want to maximize the probability of generating real data, while keeping the distance between the real and estimated posterior distributions small (say, under a small constant $\delta$):

$$
\begin{aligned}
&\max_{\phi, \theta} \mathbb{E}_{\mathbf{x}\sim\mathcal{D}}[\mathbb{E}_{\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})} \log p_\theta(\mathbf{x}\vert\mathbf{z})]\\
&\text{subject to } D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x})\|p_\theta(\mathbf{z})) < \delta
\end{aligned}
$$

我们可以在 [KKT 条件](https://www.cs.cmu.edu/~ggordon/10725-F12/slides/16-kkt.pdf)下将其重写为带有拉格朗日乘数 $\beta$ 的拉格朗日函数。上述只有一个不等式约束的优化问题等价于最大化以下方程 $\mathcal{F}(\theta, \phi, \beta)$：

> We can rewrite it as a Lagrangian with a Lagrangian multiplier $\beta$ under the [KKT condition](https://www.cs.cmu.edu/~ggordon/10725-F12/slides/16-kkt.pdf). The above optimization problem with only one inequality constraint is equivalent to maximizing the following equation $\mathcal{F}(\theta, \phi, \beta)$:

$$
\begin{aligned}
\mathcal{F}(\theta, \phi, \beta) &= \mathbb{E}_{\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})} \log p_\theta(\mathbf{x}\vert\mathbf{z}) - \beta(D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x})\|p_\theta(\mathbf{z})) - \delta) & \\
& = \mathbb{E}_{\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})} \log p_\theta(\mathbf{x}\vert\mathbf{z}) - \beta D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x})\|p_\theta(\mathbf{z})) + \beta \delta & \\
& \geq \mathbb{E}_{\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})} \log p_\theta(\mathbf{x}\vert\mathbf{z}) - \beta D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x})\|p_\theta(\mathbf{z})) & \scriptstyle{\text{; Because }\beta,\delta\geq 0}
\end{aligned}
$$

$\beta$ -VAE 的损失函数定义为：

> The loss function of $\beta$ -VAE is defined as:

$$
L_\text{BETA}(\phi, \beta) = - \mathbb{E}_{\mathbf{z} \sim q_\phi(\mathbf{z}\vert\mathbf{x})} \log p_\theta(\mathbf{x}\vert\mathbf{z}) + \beta D_\text{KL}(q_\phi(\mathbf{z}\vert\mathbf{x})\|p_\theta(\mathbf{z}))
$$

其中拉格朗日乘数 $\beta$ 被视为一个超参数。

> where the Lagrangian multiplier $\beta$ is considered as a hyperparameter.

由于 $L_\text{BETA}(\phi, \beta)$ 的负值是拉格朗日函数 $\mathcal{F}(\theta, \phi, \beta)$ 的下界。最小化损失等价于最大化拉格朗日函数，因此适用于我们最初的优化问题。

> Since the negation of $L_\text{BETA}(\phi, \beta)$ is the lower bound of the Lagrangian $\mathcal{F}(\theta, \phi, \beta)$. Minimizing the loss is equivalent to maximizing the Lagrangian and thus works for our initial optimization problem.

当 $\beta=1$ 时，它与 VAE 相同。当 $\beta > 1$ 时，它对潜在瓶颈施加了更强的约束，并限制了 $\mathbf{z}$ 的表示能力。对于一些条件独立的生成因子，保持它们解耦是最有效的表示。因此，更高的 $\beta$ 鼓励更有效的潜在编码并进一步鼓励解耦。同时，更高的 $\beta$ 可能会在重建质量和解耦程度之间产生权衡。

> When $\beta=1$, it is same as VAE. When $\beta > 1$, it applies a stronger constraint on the latent bottleneck and limits the representation capacity of $\mathbf{z}$. For some conditionally independent generative factors, keeping them disentangled is the most efficient representation. Therefore a higher $\beta$ encourages more efficient latent encoding and further encourages the disentanglement. Meanwhile, a higher $\beta$ may create a trade-off between reconstruction quality and the extent of disentanglement.

[Burgess 等人 (2017)](https://arxiv.org/pdf/1804.03599.pdf) 深入讨论了 $\beta$ -VAE 中的解耦问题，其灵感来源于 [信息瓶颈理论](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/)，并进一步提出了对 $\beta$ -VAE 的修改，以更好地控制编码表示能力。

> [Burgess, et al. (2017)](https://arxiv.org/pdf/1804.03599.pdf) discussed the distentangling in $\beta$ -VAE in depth with an inspiration by the [information bottleneck theory](https://lilianweng.github.io/posts/2017-09-28-information-bottleneck/) and further proposed a modification to $\beta$ -VAE to better control the encoding representation capacity.

### VQ-VAE 和 VQ-VAE-2

> VQ-VAE and VQ-VAE-2

该**VQ-VAE**（“向量量化变分自编码器”；[van den Oord, et al. 2017](http://papers.nips.cc/paper/7210-neural-discrete-representation-learning.pdf)）模型通过编码器学习离散潜在变量，因为离散表示可能更自然地适用于语言、语音、推理等问题。

> The **VQ-VAE** (“Vector Quantised-Variational AutoEncoder”; [van den Oord, et al. 2017](http://papers.nips.cc/paper/7210-neural-discrete-representation-learning.pdf)) model learns a discrete latent variable by the encoder, since discrete representations may be a more natural fit for problems like language, speech, reasoning, etc.

向量量化（VQ）是一种将$K$ -维向量映射到有限的“码”向量集中的方法。该过程与[KNN](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm)算法非常相似。样本应映射到的最优质心码向量是欧几里得距离最小的那个。

> Vector quantisation (VQ) is a method to map $K$ -dimensional vectors into a finite set of “code” vectors. The process is very much similar to [KNN](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm) algorithm. The optimal centroid code vector that a sample should be mapped to is the one with minimum euclidean distance.

令 $\mathbf{e} \in \mathbb{R}^{K \times D}, i=1, \dots, K$ 为 VQ-VAE 中的潜在嵌入空间（也称为“码本”），其中 $K$ 是潜在变量类别的数量，$D$ 是嵌入大小。一个单独的嵌入向量是 $\mathbf{e}_i \in \mathbb{R}^{D}, i=1, \dots, K$。

> Let $\mathbf{e} \in \mathbb{R}^{K \times D}, i=1, \dots, K$ be the latent embedding space (also known as “codebook”) in VQ-VAE, where $K$ is the number of latent variable categories and $D$ is the embedding size. An individual embedding vector is $\mathbf{e}_i \in \mathbb{R}^{D}, i=1, \dots, K$.

编码器输出 $E(\mathbf{x}) = \mathbf{z}_e$ 经过最近邻查找，以匹配 $K$ 个嵌入向量中的一个，然后这个匹配的码向量成为解码器 $D(.)$ 的输入：

> The encoder output $E(\mathbf{x}) = \mathbf{z}_e$ goes through a nearest-neighbor lookup to match to one of $K$ embedding vectors and then this matched code vector becomes the input for the decoder $D(.)$:

$$
\mathbf{z}_q(\mathbf{x}) = \text{Quantize}(E(\mathbf{x})) = \mathbf{e}_k \text{ where } k = \arg\min_i \|E(\mathbf{x}) - \mathbf{e}_i \|_2
$$

请注意，离散潜在变量在不同的应用中可以具有不同的形状；例如，语音为一维，图像为二维，视频为三维。

> Note that the discrete latent variables can have different shapes in differnet applications; for example, 1D for speech, 2D for image and 3D for video.

![The architecture of VQ-VAE (Image source: van den Oord, et al. 2017 )](https://lilianweng.github.io/posts/2018-08-12-vae/VQ-VAE.png)

由于argmin()在离散空间上不可微分，因此梯度$\nabla_z L$从解码器输入$\mathbf{z}_q$被复制到编码器输出$\mathbf{z}_e$。除了重构损失，VQ-VAE还优化：

> Because argmin() is non-differentiable on a discrete space, the gradients $\nabla_z L$ from decoder input $\mathbf{z}_q$ is copied to the encoder output $\mathbf{z}_e$. Other than reconstruction loss, VQ-VAE also optimizes:

- *VQ 损失*：嵌入空间和编码器输出之间的 L2 误差。
- *承诺损失*：一种鼓励编码器输出保持接近嵌入空间并防止其在不同代码向量之间过于频繁波动的度量。

> • *VQ loss*: The L2 error between the embedding space and the encoder outputs.
> • *Commitment loss*: A measure to encourage the encoder output to stay close to the embedding space and to prevent it from fluctuating too frequently from one code vector to another.

$$
L = \underbrace{\|\mathbf{x} - D(\mathbf{e}_k)\|_2^2}_{\textrm{reconstruction loss}} + 
\underbrace{\|\text{sg}[E(\mathbf{x})] - \mathbf{e}_k\|_2^2}_{\textrm{VQ loss}} + 
\underbrace{\beta \|E(\mathbf{x}) - \text{sg}[\mathbf{e}_k]\|_2^2}_{\textrm{commitment loss}}
$$

其中 $\text{sg}[.]$ 是 `stop_gradient` 运算符。

> where $\text{sg}[.]$ is the `stop_gradient` operator.

码本中的嵌入向量通过 EMA（指数移动平均）进行更新。给定一个码向量 $\mathbf{e}_i$，假设我们有 $n_i$ 个编码器输出向量 $\{\mathbf{z}_{i,j}\}_{j=1}^{n_i}$，它们被量化为 $\mathbf{e}_i$：

> The embedding vectors in the codebook is updated through EMA (exponential moving average). Given a code vector $\mathbf{e}_i$, say we have $n_i$ encoder output vectors, $\{\mathbf{z}_{i,j}\}_{j=1}^{n_i}$, that are quantized to $\mathbf{e}_i$:

$$
N_i^{(t)} = \gamma N_i^{(t-1)} + (1-\gamma)n_i^{(t)}\;\;\;
\mathbf{m}_i^{(t)} = \gamma \mathbf{m}_i^{(t-1)} + (1-\gamma)\sum_{j=1}^{n_i^{(t)}}\mathbf{z}_{i,j}^{(t)}\;\;\;
\mathbf{e}_i^{(t)} = \mathbf{m}_i^{(t)} / N_i^{(t)}
$$

其中 $(t)$ 指的是时间上的批次序列。$N_i$ 和 $\mathbf{m}_i$ 分别是累积的向量计数和体积。

> where $(t)$ refers to batch sequence in time. $N_i$ and $\mathbf{m}_i$ are accumulated vector count and volume, respectively.

VQ-VAE-2 ([Ali Razavi, et al. 2019](https://arxiv.org/abs/1906.00446)) 是一种两级分层 VQ-VAE，结合了自注意力自回归模型。

> VQ-VAE-2 ([Ali Razavi, et al. 2019](https://arxiv.org/abs/1906.00446)) is a two-level hierarchical VQ-VAE combined with self-attention autoregressive model.

1. 阶段 1 是**训练一个分层 VQ-VAE**：分层潜在变量的设计旨在将局部模式（即纹理）与全局信息（即物体形状）分离。较大底层码本的训练也以较小顶层码为条件，这样它就不必从头开始学习所有内容。
2. 阶段 2 是**学习潜在离散码本上的先验**，以便我们从中采样并生成图像。通过这种方式，解码器可以接收从与训练中相似的分布中采样的输入向量。一个强大的自回归模型，通过多头自注意力层增强，用于捕获先验分布（如[PixelSNAIL; Chen et al 2017](https://arxiv.org/abs/1712.09763)）。

> • Stage 1 is to **train a hierarchical VQ-VAE**: The design of hierarchical latent variables intends to separate local patterns (i.e., texture) from global information (i.e., object shapes). The training of the larger bottom level codebook is conditioned on the smaller top level code too, so that it does not have to learn everything from scratch.
> • Stage 2 is to **learn a prior over the latent discrete codebook** so that we sample from it and generate images. In this way, the decoder can receive input vectors sampled from a similar distribution as the one in training. A powerful autoregressive model enhanced with multi-headed self-attention layers is used to capture the prior distribution (like [PixelSNAIL; Chen et al 2017](https://arxiv.org/abs/1712.09763)).

考虑到 VQ-VAE-2 依赖于在简单分层设置中配置的离散潜在变量，其生成的图像质量相当惊人。

> Considering that VQ-VAE-2 depends on discrete latent variables configured in a simple hierarchical setting, the quality of its generated images are pretty amazing.

![Architecture of hierarchical VQ-VAE and multi-stage image generation. (Image source: Ali Razavi, et al. 2019 )](https://lilianweng.github.io/posts/2018-08-12-vae/VQ-VAE-2.png)

![The VQ-VAE-2 algorithm. (Image source: Ali Razavi, et al. 2019 )](https://lilianweng.github.io/posts/2018-08-12-vae/VQ-VAE-2-algo.png)

### TD-VAE

> TD-VAE

**TD-VAE**（“时序差分 VAE”；[Gregor et al., 2019](https://arxiv.org/abs/1806.03107)）处理序列数据。它依赖于下面描述的三个主要思想。

> **TD-VAE** (“Temporal Difference VAE”; [Gregor et al., 2019](https://arxiv.org/abs/1806.03107)) works with sequential data. It relies on three main ideas, described below.

![State-space model as a Markov Chain model.](https://lilianweng.github.io/posts/2018-08-12-vae/TD-VAE-state-space.png)

**1. 状态空间模型**
  

在（潜在）状态空间模型中，一系列未观测到的隐藏状态 $\mathbf{z} = (z_1, \dots, z_T)$ 决定了观测状态 $\mathbf{x} = (x_1, \dots, x_T)$。图 13 中的马尔可夫链模型中的每个时间步都可以以与图 6 类似的方式进行训练，其中难以处理的后验 $p(z \vert x)$ 由函数 $q(z \vert x)$ 近似。

英文原文：1. State-Space Models
  

In (latent) state-space models, a sequence of unobserved hidden states 

$\mathbf{z} = (z_1, \dots, z_T)$ determine the observation states 

$\mathbf{x} = (x_1, \dots, x_T)$. Each time step in the Markov chain model in Fig. 13 can be trained in a similar manner as in Fig. 6, where the intractable posterior 

$p(z \vert x)$ is approximated by a function 

$q(z \vert x)$.

**2. 信念状态**
  

智能体应该学习编码所有过去状态以推断未来，这被称为*信念状态*，$b_t = belief(x_1, \dots, x_t) = belief(b_{t-1}, x_t)$。鉴于此，以过去为条件的未来状态分布可以写为 $p(x_{t+1}, \dots, x_T \vert x_1, \dots, x_t) \approx p(x_{t+1}, \dots, x_T \vert b_t)$。循环策略中的隐藏状态在 TD-VAE 中用作智能体的信念状态。因此我们有 $b_t = \text{RNN}(b_{t-1}, x_t)$。

英文原文：2. Belief State
  

An agent should learn to encode all the past states to reason about the future, named as *belief state*, 

$b_t = belief(x_1, \dots, x_t) = belief(b_{t-1}, x_t)$. Given this, the distribution of future states conditioned on the past can be written as 

$p(x_{t+1}, \dots, x_T \vert x_1, \dots, x_t) \approx p(x_{t+1}, \dots, x_T \vert b_t)$. The hidden states in a recurrent policy are used as the agent’s belief state in TD-VAE. Thus we have 

$b_t = \text{RNN}(b_{t-1}, x_t)$.

**3. 跳跃预测**
  

此外，智能体应根据迄今为止收集到的所有信息来想象遥远的未来，这表明其具有进行跳跃预测的能力，即预测未来多个步骤的状态。

> **3. Jumpy Prediction**
>
>
> Further, an agent is expected to imagine distant futures based on all the information gathered so far, suggesting the capability of making jumpy predictions, that is, predicting states several steps further into the future.

回顾我们从[上面](https://lilianweng.github.io/posts/2018-08-12-vae/#loss-function-elbo)的方差下界中学到的内容：

> Recall what we have learned from the variance lower bound [above](https://lilianweng.github.io/posts/2018-08-12-vae/#loss-function-elbo):

$$
\begin{aligned}
\log p(x) 
&\geq \log p(x) - D_\text{KL}(q(z|x)\|p(z|x)) \\
&= \mathbb{E}_{z\sim q} \log p(x|z) - D_\text{KL}(q(z|x)\|p(z)) \\
&= \mathbb{E}_{z \sim q} \log p(x|z) - \mathbb{E}_{z \sim q} \log \frac{q(z|x)}{p(z)} \\
&= \mathbb{E}_{z \sim q}[\log p(x|z) -\log q(z|x) + \log p(z)] \\
&= \mathbb{E}_{z \sim q}[\log p(x, z) -\log q(z|x)] \\
\log p(x) 
&\geq \mathbb{E}_{z \sim q}[\log p(x, z) -\log q(z|x)]
\end{aligned}
$$

现在，让我们将状态 $x_t$ 的分布建模为一个概率函数，该函数以所有过去状态 $x_{<t}$ 以及当前时间步和前一个时间步的两个潜在变量 $z_t$ 和 $z_{t-1}$ 为条件：

> Now let’s model the distribution of the state $x_t$ as a probability function conditioned on all the past states $x_{<t}$ and two latent variables, $z_t$ and $z_{t-1}$, at current time step and one step back:

$$
\log p(x_t|x_{<{t}}) \geq \mathbb{E}_{(z_{t-1}, z_t) \sim q}[\log p(x_t, z_{t-1}, z_{t}|x_{<{t}}) -\log q(z_{t-1}, z_t|x_{\leq t})]
$$

继续展开方程：

> Continue expanding the equation:

$$
\begin{aligned}
& \log p(x_t|x_{<{t}}) \\
&\geq \mathbb{E}_{(z_{t-1}, z_t) \sim q}[\log p(x_t, z_{t-1}, z_{t}|x_{<{t}}) -\log q(z_{t-1}, z_t|x_{\leq t})] \\
&\geq \mathbb{E}_{(z_{t-1}, z_t) \sim q}[\log p(x_t|\color{red}{z_{t-1}}, z_{t}, \color{red}{x_{<{t}}}) + \color{blue}{\log p(z_{t-1}, z_{t}|x_{<{t}})} -\log q(z_{t-1}, z_t|x_{\leq t})] \\
&\geq \mathbb{E}_{(z_{t-1}, z_t) \sim q}[\log p(x_t|z_{t}) + \color{blue}{\log p(z_{t-1}|x_{<{t}})} + \color{blue}{\log p(z_{t}|z_{t-1})} - \color{green}{\log q(z_{t-1}, z_t|x_{\leq t})}] \\
&\geq \mathbb{E}_{(z_{t-1}, z_t) \sim q}[\log p(x_t|z_{t}) + \log p(z_{t-1}|x_{<{t}}) + \log p(z_{t}|z_{t-1}) - \color{green}{\log q(z_t|x_{\leq t})} - \color{green}{\log q(z_{t-1}|z_t, x_{\leq t})}]
\end{aligned}
$$

注意两点：

> Notice two things:

- 根据马尔可夫假设，红色项可以被忽略。
- 根据马尔可夫假设，蓝色项被展开。
- 绿色项被展开，以包含一个一步预测回溯到过去作为平滑分布。

> • The red terms can be ignored according to Markov assumptions.
> • The blue term is expanded according to Markov assumptions.
> • The green term is expanded to include an one-step prediction back to the past as a smoothing distribution.

准确地说，有四种类型的分布需要学习：

> Precisely, there are four types of distributions to learn:

1\. $p_D(.)$ 是 **解码器** 分布：

英文原文：

1\. $p_D(.)$ is the **decoder** distribution:

• $p(x_t \mid z_t)$ 根据常见定义是编码器；

• $p(x_t \mid z_t) \to p_D(x_t \mid z_t)$；

英文原文：

• $p(x_t \mid z_t)$ is the encoder by the common definition;

• $p(x_t \mid z_t) \to p_D(x_t \mid z_t)$;

1\. $p_T(.)$ 是 **转移** 分布：

英文原文：

1\. $p_T(.)$ is the **transition** distribution:

• $p(z_t \mid z_{t-1})$ 捕获了潜在变量之间的序列依赖关系；

• $p(z_t \mid z_{t-1}) \to p_T(z_t \mid z_{t-1})$；

英文原文：

• $p(z_t \mid z_{t-1})$ captures the sequential dependency between latent variables;

• $p(z_t \mid z_{t-1}) \to p_T(z_t \mid z_{t-1})$;

1\. $p_B(.)$ 是 **信念** 分布：

英文原文：

1\. $p_B(.)$ is the **belief** distribution:

• $p(z_{t-1} \mid x_{<t})$ 和 $q(z_t \mid x_{\leq t})$ 都可以使用信念状态来预测潜在变量；

• $p(z_{t-1} \mid x_{<t}) \to p_B(z_{t-1} \mid b_{t-1})$；

• $q(z_{t} \mid x_{\leq t}) \to p_B(z_t \mid b_t)$；

英文原文：

• Both $p(z_{t-1} \mid x_{<t})$ and $q(z_t \mid x_{\leq t})$ can use the belief states to predict the latent variables;

• $p(z_{t-1} \mid x_{<t}) \to p_B(z_{t-1} \mid b_{t-1})$;

• $q(z_{t} \mid x_{\leq t}) \to p_B(z_t \mid b_t)$;

1\. $p_S(.)$ 是 **平滑** 分布：

英文原文：

1\. $p_S(.)$ is the **smoothing** distribution:

• 回溯到过去的平滑项 $q(z_{t-1} \mid z_t, x_{\leq t})$ 也可以重写为依赖于信念状态；

• $q(z_{t-1} \mid z_t, x_{\leq t}) \to p_S(z_{t-1} \mid z_t, b_{t-1}, b_t)$；

英文原文：

• The back-to-past smoothing term $q(z_{t-1} \mid z_t, x_{\leq t})$ can be rewritten to be dependent of belief states too;

• $q(z_{t-1} \mid z_t, x_{\leq t}) \to p_S(z_{t-1} \mid z_t, b_{t-1}, b_t)$;

为了引入跳跃预测的思想，序列 ELBO 不仅要作用于 $t, t+1$，还要作用于两个遥远的时间戳 $t_1 < t_2$。以下是要最大化的最终 TD-VAE 目标函数：

> To incorporate the idea of jumpy prediction, the sequential ELBO has to not only work on $t, t+1$, but also two distant timestamp $t_1 < t_2$. Here is the final TD-VAE objective function to maximize:

$$
J_{t_1, t_2} = \mathbb{E}[
  \log p_D(x_{t_2}|z_{t_2}) 
  + \log p_B(z_{t_1}|b_{t_1}) 
  + \log p_T(z_{t_2}|z_{t_1}) 
  - \log p_B(z_{t_2}|b_{t_2}) 
  - \log p_S(z_{t_1}|z_{t_2}, b_{t_1}, b_{t_2})]
$$

![A detailed overview of TD-VAE architecture, very nicely done. (Image source: TD-VAE paper )](https://lilianweng.github.io/posts/2018-08-12-vae/TD-VAE.png)

引用：

> Cited as:

```
@article{weng2018VAE,
  title   = "From Autoencoder to Beta-VAE",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-08-12-vae/"
}
```

### 参考文献

> References

[1] Geoffrey E. Hinton 和 Ruslan R. Salakhutdinov. [“用神经网络降低数据维度。”](https://pdfs.semanticscholar.org/c50d/ca78e97e335d362d6b991ae0e1448914e9a3.pdf) Science 313.5786 (2006): 504-507。

> [1] Geoffrey E. Hinton, and Ruslan R. Salakhutdinov. [“Reducing the dimensionality of data with neural networks.”](https://pdfs.semanticscholar.org/c50d/ca78e97e335d362d6b991ae0e1448914e9a3.pdf) Science 313.5786 (2006): 504-507.

[2] Pascal Vincent 等人。 [“用去噪自编码器提取和组合鲁棒特征。”](http://www.cs.toronto.edu/~larocheh/publications/icml-2008-denoising-autoencoders.pdf) ICML, 2008。

> [2] Pascal Vincent, et al. [“Extracting and composing robust features with denoising autoencoders.”](http://www.cs.toronto.edu/~larocheh/publications/icml-2008-denoising-autoencoders.pdf) ICML, 2008.

[3] Pascal Vincent 等人。 [“堆叠去噪自编码器：在具有局部去噪准则的深度网络中学习有用表示。”](http://www.jmlr.org/papers/volume11/vincent10a/vincent10a.pdf)。 Journal of machine learning research 11.Dec (2010): 3371-3408。

> [3] Pascal Vincent, et al. [“Stacked denoising autoencoders: Learning useful representations in a deep network with a local denoising criterion.”](http://www.jmlr.org/papers/volume11/vincent10a/vincent10a.pdf). Journal of machine learning research 11.Dec (2010): 3371-3408.

[4] Geoffrey E. Hinton, Nitish Srivastava, Alex Krizhevsky, Ilya Sutskever, and Ruslan R. Salakhutdinov. “通过防止特征检测器协同适应来改进神经网络。” arXiv preprint arXiv:1207.0580 (2012)。

> [4] Geoffrey E. Hinton, Nitish Srivastava, Alex Krizhevsky, Ilya Sutskever, and Ruslan R. Salakhutdinov. “Improving neural networks by preventing co-adaptation of feature detectors.” arXiv preprint arXiv:1207.0580 (2012).

[5] Andrew Ng 的 [稀疏自编码器](https://web.stanford.edu/class/cs294a/sparseAutoencoder.pdf)。

> [5] [Sparse Autoencoder](https://web.stanford.edu/class/cs294a/sparseAutoencoder.pdf) by Andrew Ng.

[6] Alireza Makhzani, Brendan Frey (2013). [“k-稀疏自编码器”](https://arxiv.org/abs/1312.5663). ICLR 2014.

> [6] Alireza Makhzani, Brendan Frey (2013). [“k-sparse autoencoder”](https://arxiv.org/abs/1312.5663). ICLR 2014.

[7] Salah Rifai, et al. [“收缩自编码器：特征提取过程中的显式不变性。”](http://www.icml-2011.org/papers/455_icmlpaper.pdf) ICML, 2011.

> [7] Salah Rifai, et al. [“Contractive auto-encoders: Explicit invariance during feature extraction.”](http://www.icml-2011.org/papers/455_icmlpaper.pdf) ICML, 2011.

[8] Diederik P. Kingma, and Max Welling. [“自编码变分贝叶斯。”](https://arxiv.org/abs/1312.6114) ICLR 2014.

> [8] Diederik P. Kingma, and Max Welling. [“Auto-encoding variational bayes.”](https://arxiv.org/abs/1312.6114) ICLR 2014.

[9] [教程 - 什么是变分自编码器？](https://jaan.io/what-is-variational-autoencoder-vae-tutorial/) on jaan.io

> [9] [Tutorial - What is a variational autoencoder?](https://jaan.io/what-is-variational-autoencoder-vae-tutorial/) on jaan.io

[10] Youtube 教程: [变分自编码器](https://www.youtube.com/watch?v=9zKuYvjFFS8) by Arxiv Insights

> [10] Youtube tutorial: [Variational Autoencoders](https://www.youtube.com/watch?v=9zKuYvjFFS8) by Arxiv Insights

[11] [“变分方法初学者指南：平均场近似”](https://blog.evjang.com/2016/08/variational-bayes.html) by Eric Jang.

> [11] [“A Beginner’s Guide to Variational Methods: Mean-Field Approximation”](https://blog.evjang.com/2016/08/variational-bayes.html) by Eric Jang.

[12] Carl Doersch. [“变分自编码器教程。”](https://arxiv.org/abs/1606.05908) arXiv:1606.05908, 2016.

> [12] Carl Doersch. [“Tutorial on variational autoencoders.”](https://arxiv.org/abs/1606.05908) arXiv:1606.05908, 2016.

[13] Irina Higgins, et al. ["\beta-VAE: 在受限变分框架下学习基本视觉概念。"](https://openreview.net/forum?id=Sy2fzU9gl) ICLR 2017.

> [13] Irina Higgins, et al. ["\beta-VAE: Learning basic visual concepts with a constrained variational framework."](https://openreview.net/forum?id=Sy2fzU9gl) ICLR 2017.

[14] Christopher P. Burgess, et al. [“理解 beta-VAE 中的解耦。”](https://arxiv.org/abs/1804.03599) NIPS 2017.

> [14] Christopher P. Burgess, et al. [“Understanding disentangling in beta-VAE.”](https://arxiv.org/abs/1804.03599) NIPS 2017.

[15] Aaron van den Oord, et al. [“神经离散表示学习”](https://arxiv.org/abs/1711.00937) NIPS 2017.

> [15] Aaron van den Oord, et al. [“Neural Discrete Representation Learning”](https://arxiv.org/abs/1711.00937) NIPS 2017.

[16] Ali Razavi, et al. [“使用 VQ-VAE-2 生成多样化高保真图像”](https://arxiv.org/abs/1906.00446). arXiv preprint arXiv:1906.00446 (2019).

> [16] Ali Razavi, et al. [“Generating Diverse High-Fidelity Images with VQ-VAE-2”](https://arxiv.org/abs/1906.00446). arXiv preprint arXiv:1906.00446 (2019).

[17] Xi Chen, et al. [“PixelSNAIL: 一种改进的自回归生成模型。”](https://arxiv.org/abs/1712.09763) arXiv preprint arXiv:1712.09763 (2017).

> [17] Xi Chen, et al. [“PixelSNAIL: An Improved Autoregressive Generative Model.”](https://arxiv.org/abs/1712.09763) arXiv preprint arXiv:1712.09763 (2017).

[18] Karol Gregor, et al. [“时序差分变分自编码器。”](https://arxiv.org/abs/1806.03107) ICLR 2019.

> [18] Karol Gregor, et al. [“Temporal Difference Variational Auto-Encoder.”](https://arxiv.org/abs/1806.03107) ICLR 2019.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Autoencoder | 自编码器 | 一种无监督神经网络，通过编码器将输入压缩为潜在表示，再通过解码器重建原始输入。 |
| Variational Autoencoder (VAE) | 变分自编码器 | 一种生成模型，将输入映射到潜在分布，并使用概率编码器和解码器进行数据生成和重建。 |
| Denoising Autoencoder | 去噪自编码器 | 一种自编码器变体，通过从损坏的输入中恢复原始数据来学习鲁棒特征。 |
| Sparse Autoencoder | 稀疏自编码器 | 一种自编码器变体，通过对隐藏层激活施加稀疏性约束来学习更有效的表示。 |
| Contractive Autoencoder | 收缩自编码器 | 一种自编码器变体，通过惩罚编码器输出对输入变化的敏感性来提高表示的鲁棒性。 |
| Beta-VAE | Beta-VAE | 变分自编码器的一种修改，通过调整超参数β来鼓励学习解耦的潜在表示。 |
| VQ-VAE (Vector Quantized Variational Autoencoder) | 向量量化变分自编码器 | 一种学习离散潜在变量的生成模型，通过将编码器输出量化到码本中的向量。 |
| TD-VAE (Temporal Difference Variational Autoencoder) | 时序差分变分自编码器 | 一种处理序列数据的变分自编码器，结合了状态空间模型、信念状态和跳跃预测。 |
| Dimensionality Reduction | 降维 | 将高维数据转换为低维表示的过程，同时保留数据的关键信息。 |
| Latent Code/Representation | 潜在编码/表示 | 数据经过编码器压缩后的低维抽象表示，捕获了数据的核心特征。 |
| Encoder | 编码器 | 神经网络的一部分，将高维输入数据转换为低维潜在表示。 |
| Decoder | 解码器 | 神经网络的一部分，从低维潜在表示重建原始高维数据。 |
| Reparameterization Trick | 重参数化技巧 | VAE中用于使采样过程可微分的技术，允许梯度通过随机节点反向传播。 |
| Evidence Lower Bound (ELBO) | 证据下界 | 变分自编码器中用于最大化数据对数似然的代理目标函数。 |
| Kullback-Leibler Divergence (KL Divergence) | KL散度 | 一种衡量两个概率分布之间差异的非对称度量。 |
| Disentangled Representation | 解耦表示 | 潜在表示中的每个维度独立地对应于数据的一个生成因子。 |
| Vector Quantization | 向量量化 | 将输入向量映射到有限码本中最接近的码向量的过程。 |
| Codebook | 码本 | 向量量化中包含有限数量预定义码向量的集合。 |
| Belief State | 信念状态 | 在序列模型中，智能体学习编码所有过去状态以推断未来的表示。 |
| Skip Prediction | 跳跃预测 | 在时序模型中，预测未来多个时间步状态的能力。 |
