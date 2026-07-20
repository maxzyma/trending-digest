# Transformer 家族 2.0 版

> The Transformer Family Version 2.0

> 来源：Lil'Log / Lilian Weng，2023-01-27
> 原文链接：https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/
> 分类：人工智能 / Transformer模型

## 核心要点

- Transformer 2.0版本是对原有Transformer家族文章的大规模重构与丰富，涵盖了2020年以来提出的众多架构改进。
- Transformer模型最初采用编码器-解码器架构，其核心是缩放点积注意力与多头自注意力机制。
- 为解决自注意力排列不变性问题，Transformer引入了正弦、学习、相对及旋转位置编码来提供顺序信息。
- 文章详细探讨了多种支持更长上下文的Transformer改进，包括上下文内存、不可微分外部内存和距离增强注意力分数。
- 为提高效率，Transformer发展出稀疏注意力模式、结合局部与全局上下文的机制、基于内容的注意力以及低秩注意力等多种方法。
- 自适应建模技术允许Transformer根据输入动态调整计算量，例如自适应注意力范围和深度自适应Transformer。
- Transformer模型也被应用于强化学习领域，通过门控机制稳定训练（GTrXL）或将RL问题表述为条件序列建模（决策Transformer）。

## 正文

自从我大约三年前发表了关于[“Transformer 家族”](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/)的上一篇文章以来，已经提出了许多新的 Transformer 架构改进。在这里，我对 2020 年的那篇文章进行了大规模重构和丰富——重新组织了章节的层次结构，并用最新的论文改进了许多章节。2.0 版是旧版本的超集，长度大约是旧版本的两倍。

> Many new Transformer architecture improvements have been proposed since my last post on [“The Transformer Family”](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/) about three years ago. Here I did a big refactoring and enrichment of that 2020 post — restructure the hierarchy of sections and improve many sections with more recent papers. Version 2.0 is a superset of the old version, about twice the length.

### 符号表示

> Notations

| 符号 | 含义 |
| --- | --- |
| $d$ | 模型大小 / 隐藏状态维度 / 位置编码大小。 |
| $h$ | 多头注意力层中的头数。 |
| $L$ | 输入序列的段长度。 |
| $N$ | 模型中注意力层的总数；不考虑 MoE。 |
| $\mathbf{X} \in \mathbb{R}^{L \times d}$ | 输入序列，其中每个元素都被映射成形状为 $d$ 的嵌入向量，与模型大小相同。 |
| $\mathbf{W}^k \in \mathbb{R}^{d \times d_k}$ | 键权重矩阵。 |
| $\mathbf{W}^q \in \mathbb{R}^{d \times d_k}$ | 查询权重矩阵。 |
| $\mathbf{W}^v \in \mathbb{R}^{d \times d_v}$ | 值权重矩阵。通常我们有 $d_k = d_v = d$。 |
| $\mathbf{W}^k_i, \mathbf{W}^q_i \in \mathbb{R}^{d \times d_k/h}; \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$ | 每个头的权重矩阵。 |
| $\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$ | 输出权重矩阵。 |
| $\mathbf{Q} = \mathbf{X}\mathbf{W}^q \in \mathbb{R}^{L \times d_k}$ | 查询嵌入输入。 |
| $\mathbf{K} = \mathbf{X}\mathbf{W}^k \in \mathbb{R}^{L \times d_k}$ | 键嵌入输入。 |
| $\mathbf{V} = \mathbf{X}\mathbf{W}^v \in \mathbb{R}^{L \times d_v}$ | 值嵌入输入。 |
| $\mathbf{q}_i, \mathbf{k}_i \in \mathbb{R}^{d_k}, \mathbf{v}_i \in \mathbb{R}^{d_v}$ | 查询、键、值矩阵 $\mathbf{Q}$、$\mathbf{K}$ 和 $\mathbf{V}$ 中的行向量。 |
| $S_i$ | 第 $i$ 个查询 $\mathbf{q}_i$ 要关注的键位置集合。 |
| $\mathbf{A} \in \mathbb{R}^{L \times L}$ | 长度为 $L$ 的输入序列与自身之间的自注意力矩阵。$\mathbf{A} = \text{softmax}(\mathbf{Q}\mathbf{K}^\top / \sqrt{d_k})$。 |
| $a_{ij} \in \mathbf{A}$ | 查询 $\mathbf{q}_i$ 和键 $\mathbf{k}_j$ 之间的标量注意力分数。 |
| $\mathbf{P} \in \mathbb{R}^{L \times d}$ | 位置编码矩阵，其中第 $i$ 行 $\mathbf{p}_i$ 是输入 $\mathbf{x}_i$ 的位置编码。 |

> 英文原表 / English original

| Symbol | Meaning |
| --- | --- |
| $d$ | The model size / hidden state dimension / positional encoding size. |
| $h$ | The number of heads in multi-head attention layer. |
| $L$ | The segment length of input sequence. |
| $N$ | The total number of attention layers in the model; not considering MoE. |
| $\mathbf{X} \in \mathbb{R}^{L \times d}$ | The input sequence where each element has been mapped into an embedding vector of shape $d$, same as the model size. |
| $\mathbf{W}^k \in \mathbb{R}^{d \times d_k}$ | The key weight matrix. |
| $\mathbf{W}^q \in \mathbb{R}^{d \times d_k}$ | The query weight matrix. |
| $\mathbf{W}^v \in \mathbb{R}^{d \times d_v}$ | The value weight matrix. Often we have $d_k = d_v = d$. |
| $\mathbf{W}^k_i, \mathbf{W}^q_i \in \mathbb{R}^{d \times d_k/h}; \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$ | The weight matrices per head. |
| $\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$ | The output weight matrix. |
| $\mathbf{Q} = \mathbf{X}\mathbf{W}^q \in \mathbb{R}^{L \times d_k}$ | The query embedding inputs. |
| $\mathbf{K} = \mathbf{X}\mathbf{W}^k \in \mathbb{R}^{L \times d_k}$ | The key embedding inputs. |
| $\mathbf{V} = \mathbf{X}\mathbf{W}^v \in \mathbb{R}^{L \times d_v}$ | The value embedding inputs. |
| $\mathbf{q}_i, \mathbf{k}_i \in \mathbb{R}^{d_k}, \mathbf{v}_i \in \mathbb{R}^{d_v}$ | Row vectors in query, key, value matrices, $\mathbf{Q}$, $\mathbf{K}$ and $\mathbf{V}$. |
| $S_i$ | A collection of key positions for the $i$-th query $\mathbf{q}_i$ to attend to. |
| $\mathbf{A} \in \mathbb{R}^{L \times L}$ | The self-attention matrix between a input sequence of lenght $L$ and itself. $\mathbf{A} = \text{softmax}(\mathbf{Q}\mathbf{K}^\top / \sqrt{d_k})$. |
| $a_{ij} \in \mathbf{A}$ | The scalar attention score between query $\mathbf{q}_i$ and key $\mathbf{k}_j$. |
| $\mathbf{P} \in \mathbb{R}^{L \times d}$ | position encoding matrix, where the $i$-th row $\mathbf{p}_i$ is the positional encoding for input $\mathbf{x}_i$. |

### Transformer 基础

> Transformer Basics

**Transformer** 模型（为区别于其他增强版本，此处称之为“香草 Transformer”；[Vaswani 等人，2017](https://arxiv.org/abs/1706.03762)）具有编码器-解码器架构，这在许多[神经机器翻译（NMT）](https://lilianweng.github.io/posts/2018-06-24-attention/#born-for-translation)模型中很常见。后来，简化的 Transformer 在语言建模任务中表现出色，例如仅编码器的[BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert)或仅解码器的[GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#openai-gpt)。

> The **Transformer** (which will be referred to as “vanilla Transformer” to distinguish it from other enhanced versions; [Vaswani, et al., 2017](https://arxiv.org/abs/1706.03762)) model has an encoder-decoder architecture, as commonly used in many [NMT](https://lilianweng.github.io/posts/2018-06-24-attention/#born-for-translation) models. Later simplified Transformer was shown to achieve great performance in language modeling tasks, like in encoder-only [BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert) or decoder-only [GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#openai-gpt).

#### 注意力和自注意力

> Attention and Self-Attention

**注意力**是神经网络中的一种机制，模型可以通过选择性地关注给定数据集来学习进行预测。注意力的程度由学习到的权重来量化，因此输出通常以加权平均的形式形成。

> **Attention** is a mechanism in neural network that a model can learn to make predictions by selectively attending to a given set of data. The amount of attention is quantified by learned weights and thus the output is usually formed as a weighted average.

**自注意力**是一种注意力机制，模型利用同一数据样本中其他部分的观察来预测该样本的某一部分。从概念上讲，它与[非局部均值](https://en.wikipedia.org/wiki/Non-local_means)非常相似。另请注意，自注意力是置换不变的；换句话说，它是一种对集合进行的操作。

> **Self-attention** is a type of attention mechanism where the model makes prediction for one part of a data sample using other parts of the observation about the same sample. Conceptually, it feels quite similar to [non-local means](https://en.wikipedia.org/wiki/Non-local_means). Also note that self-attention is permutation-invariant; in other words, it is an operation on sets.

注意力/自注意力有多种形式，Transformer（[Vaswani 等人，2017](https://arxiv.org/abs/1706.03762)）依赖于*缩放点积注意力*：给定一个查询矩阵 $\mathbf{Q}$、一个键矩阵 $\mathbf{K}$ 和一个值矩阵 $\mathbf{V}$，输出是值向量的加权和，其中分配给每个值槽的权重由查询与相应键的点积决定：

> There are various forms of attention / self-attention, Transformer ([Vaswani et al., 2017](https://arxiv.org/abs/1706.03762)) relies on the *scaled dot-product attention*: given a query matrix $\mathbf{Q}$, a key matrix $\mathbf{K}$ and a value matrix $\mathbf{V}$, the output is a weighted sum of the value vectors, where the weight assigned to each value slot is determined by the dot-product of the query with the corresponding key:

$$
\text{attn}(\mathbf{Q}, \mathbf{K}, \mathbf{V}) = \text{softmax}(\frac{\mathbf{Q} {\mathbf{K}}^\top}{\sqrt{d_k}})\mathbf{V}
$$

对于查询和键向量 $\mathbf{q}_i, \mathbf{k}_j \in \mathbb{R}^d$（查询和键矩阵中的行向量），我们有一个标量分数：

> And for a query and a key vector $\mathbf{q}_i, \mathbf{k}_j \in \mathbb{R}^d$ (row vectors in query and key matrices), we have a scalar score:

$$
a_{ij} = \text{softmax}(\frac{\mathbf{q}_i {\mathbf{k}_j}^\top}{\sqrt{d_k}})
= \frac{\exp(\frac{\mathbf{q}_i {\mathbf{k}_j}^\top}{\sqrt{d_k}})}{ \sum_{r \in \mathcal{S}_i} \exp(\frac{\mathbf{q}_i {\mathbf{k}_r}^\top}{\sqrt{d_k}}) }
$$

其中 $\mathcal{S}_i$ 是第 $i$ 个查询要关注的键位置集合。

> where $\mathcal{S}_i$ is a collection of key positions for the $i$ -th query to attend to.

如果感兴趣，请参阅我关于[其他注意力类型](https://lilianweng.github.io/posts/2018-06-24-attention/#a-family-of-attention-mechanisms)的旧文章。

> See my old [post for other types of attention](https://lilianweng.github.io/posts/2018-06-24-attention/#a-family-of-attention-mechanisms) if interested.

#### 多头自注意力

> Multi-Head Self-Attention

**多头自注意力**模块是Transformer中的一个关键组件。多头机制不是只计算一次注意力，而是将输入分成更小的块，然后并行地在每个子空间上计算缩放点积注意力。独立的注意力输出被简单地拼接起来，并线性变换到预期的维度。

> The **multi-head self-attention** module is a key component in Transformer. Rather than only computing the attention once, the multi-head mechanism splits the inputs into smaller chunks and then computes the scaled dot-product attention over each subspace in parallel. The independent attention outputs are simply concatenated and linearly transformed into expected dimensions.

$$
\begin{aligned}
\text{MultiHeadAttn}(\mathbf{X}_q, \mathbf{X}_k, \mathbf{X}_v) &= [\text{head}_1; \dots; \text{head}_h] \mathbf{W}^o \\ 
\text{where head}_i &= \text{Attention}(\mathbf{X}_q\mathbf{W}^q_i, \mathbf{X}_k\mathbf{W}^k_i, \mathbf{X}_v\mathbf{W}^v_i)
\end{aligned}
$$

其中$[.;.]$是拼接操作。$\mathbf{W}^q_i, \mathbf{W}^k_i \in \mathbb{R}^{d \times d_k/h}, \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$是权重矩阵，用于将大小为$L \times d$的输入嵌入映射到查询、键和值矩阵。$\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$是输出线性变换。所有权重都应在训练期间学习。

> where $[.;.]$ is a concatenation operation. $\mathbf{W}^q_i, \mathbf{W}^k_i \in \mathbb{R}^{d \times d_k/h}, \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$ are weight matrices to map input embeddings of size $L \times d$ into query, key and value matrices. And $\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$ is the output linear transformation. All the weights should be learned during training.

![Illustration of the multi-head scaled dot-product attention mechanism. (Image source: Figure 2 in Vaswani, et al., 2017 )](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/multi-head-attention.png)

#### 编码器-解码器架构

> Encoder-Decoder Architecture

**编码器**生成基于注意力的表示，能够从大量上下文中定位特定信息。它由6个相同模块堆叠而成，每个模块包含两个子模块：一个*多头自注意力*层和一个*逐点*全连接前馈网络。逐点意味着它对序列中的每个元素应用相同的线性变换（使用相同的权重）。这也可以看作是一个滤波器大小为1的卷积层。每个子模块都有残差连接和层归一化。所有子模块都输出相同维度`d`的数据。

英文原文：The encoder generates an attention-based representation with capability to locate a specific piece of information from a large context. It consists of a stack of 6 identity modules, each containing two submodules, a *multi-head self-attention* layer and a *point-wise* fully connected feed-forward network. By point-wise, it means that it applies the same linear transformation (with same weights) to each element in the sequence. This can also be viewed as a convolutional layer with filter size 1. Each submodule has a residual connection and layer normalization. All the submodules output data of the same dimension `d`.

Transformer**解码器**的功能是从编码表示中检索信息。其架构与编码器非常相似，不同之处在于解码器在每个相同的重复模块中包含两个多头注意力子模块，而不是一个。第一个多头注意力子模块被*掩码*，以防止位置关注未来。

> The function of Transformer **decoder** is to retrieve information from the encoded representation. The architecture is quite similar to the encoder, except that the decoder contains two multi-head attention submodules instead of one in each identical repeating module. The first multi-head attention submodule is *masked* to prevent positions from attending to the future.

![The architecture of the vanilla Transformer model. (Image source: Figure 17 )](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/transformer.png)

#### 位置编码

> Positional Encoding

由于自注意力操作是排列不变的，因此使用适当的**位置编码**来为模型提供*顺序信息*非常重要。位置编码$\mathbf{P} \in \mathbb{R}^{L \times d}$与输入嵌入具有相同的维度，因此可以直接添加到输入中。原始Transformer考虑了两种类型的编码：

英文原文：Because self-attention operation is permutation invariant, it is important to use proper positional encoding to provide *order information* to the model. The positional encoding 

$\mathbf{P} \in \mathbb{R}^{L \times d}$ has the same dimension as the input embedding, so it can be added on the input directly. The vanilla Transformer considered two types of encodings:

##### 正弦位置编码

> Sinusoidal Positional Encoding

正弦位置编码定义如下，给定token位置$i=1,\dots,L$和维度$\delta=1,\dots,d$：

> Sinusoidal positional encoding is defined as follows, given the token position $i=1,\dots,L$ and the dimension $\delta=1,\dots,d$:

$$
\text{PE}(i,\delta) = 
\begin{cases}
\sin(\frac{i}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta'\\
\cos(\frac{i}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta' + 1\\
\end{cases}
$$

通过这种方式，位置编码的每个维度都对应于不同维度中不同波长的正弦曲线，从$2\pi$到$10000 \cdot 2\pi$。

> In this way each dimension of the positional encoding corresponds to a sinusoid of different wavelengths in different dimensions, from $2\pi$ to $10000 \cdot 2\pi$.

![Sinusoidal positional encoding with $L=32$ and $d=128$. The value is between -1 (black) and 1 (white) and the value 0 is in gray.](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/sinoidual-positional-encoding.png)

##### 学习到的位置编码

> Learned Positional Encoding

学习到的位置编码为每个元素分配一个*学习到的*列向量，该向量编码其绝对位置([Gehring, et al. 2017](https://arxiv.org/abs/1705.03122))，此外，这种编码可以按层进行不同的学习([Al-Rfou et al. 2018](https://arxiv.org/abs/1808.04444))。  
  


> Learned positional encoding assigns each element with a *learned* column vector which encodes its absolute position ([Gehring, et al. 2017](https://arxiv.org/abs/1705.03122)) and furthermroe this encoding can be learned differently per layer ([Al-Rfou et al. 2018](https://arxiv.org/abs/1808.04444)).  
>

##### 相对位置编码

> Relative Position Encoding

[Shaw 等人 (2018)](https://arxiv.org/abs/1803.02155)) 将相对位置信息整合到 $\mathbf{W}^k$ 和 $\mathbf{W}^v$ 中。最大相对位置被裁剪到最大绝对值 $k$，这种裁剪操作使模型能够泛化到未曾见过的序列长度。因此，考虑了 $2k + 1$ 个独特的边标签，我们将 $\mathbf{P}^k, \mathbf{P}^v \in \mathbb{R}^{2k+1}$ 表示为可学习的相对位置表示。

> [Shaw et al. (2018)](https://arxiv.org/abs/1803.02155)) incorporated relative positional information into $\mathbf{W}^k$ and $\mathbf{W}^v$. Maximum relative position is clipped to a maximum absolute value of $k$ and this clipping operation enables the model to generalize to unseen sequence lengths. Therefore, $2k + 1$ unique edge labels are considered and let us denote $\mathbf{P}^k, \mathbf{P}^v \in \mathbb{R}^{2k+1}$ as learnable relative position representations.

$$
A_{ij}^k = P^k_{\text{clip}(j - i, k)} \quad
A_{ij}^v = P^v_{\text{clip}(j - i, k)} \quad
\text{where }\text{clip}(x, k) = \text{clip}(x, -k, k)
$$

[Transformer-XL](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#transformer-xl) ([Dai 等人，2019](https://arxiv.org/abs/1901.02860)) 提出了一种基于键和查询点积重参数化的相对位置编码。为了使位置信息在不同段之间连贯流动，Transformer-XL 转而编码*相对*位置，因为知道位置偏移量足以做出良好的预测，即 $i-j$，在一个键向量 $\mathbf{k}_{\tau, j}$ 及其查询 $\mathbf{q}_{\tau, i}$ 之间。

> [Transformer-XL](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#transformer-xl) ([Dai et al., 2019](https://arxiv.org/abs/1901.02860)) proposed a type of relative positional encoding based on reparametrization of dot-product of keys and queries. To keep the positional information flow coherently across segments, Transformer-XL encodes the *relative* position instead, as it could be sufficient enough to know the position offset for making good predictions, i.e. $i-j$, between one key vector $\mathbf{k}_{\tau, j}$ and its query $\mathbf{q}_{\tau, i}$.

如果省略标量 $1/\sqrt{d_k}$ 和 softmax 中的归一化项，但包含位置编码，我们可以将位置 $i$ 处的查询与位置 $j$ 处的键之间的注意力分数写为：

> If omitting the scalar $1/\sqrt{d_k}$ and the normalizing term in softmax but including positional encodings, we can write the attention score between query at position $i$ and key at position $j$ as:

$$
\begin{aligned}
a_{ij} 
&= \mathbf{q}_i {\mathbf{k}_j}^\top = (\mathbf{x}_i + \mathbf{p}_i)\mathbf{W}^q ((\mathbf{x}_j + \mathbf{p}_j)\mathbf{W}^k)^\top \\
&= \mathbf{x}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{x}_j^\top + \mathbf{x}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{p}_j^\top + \mathbf{p}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{x}_j^\top + \mathbf{p}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{p}_j^\top
\end{aligned}
$$

Transformer-XL 对上述四个项进行如下重新参数化：

> Transformer-XL reparameterizes the above four terms as follows:

$$
a_{ij}^\text{rel} = 
\underbrace{ \mathbf{x}_i\mathbf{W}^q \color{blue}{ {\mathbf{W}_E^k}^\top } \mathbf{x}_j^\top }_\text{content-based addressing} + 
\underbrace{ \mathbf{x}_i\mathbf{W}^q \color{blue}{ {\mathbf{W}_R^k}^\top } \color{green}{\mathbf{r}_{i-j}^\top} }_\text{content-dependent positional bias} + 
\underbrace{ \color{red}{\mathbf{u}} \color{blue}{ {\mathbf{W}_E^k}^\top } \mathbf{x}_j^\top }_\text{global content bias} + 
\underbrace{ \color{red}{\mathbf{v}} \color{blue}{ {\mathbf{W}_R^k}^\top } \color{green}{\mathbf{r}_{i-j}^\top} }_\text{global positional bias}
$$

• 将 $\mathbf{p}_j$ 替换为相对位置编码 $\mathbf{r}_{i-j} \in \mathbf{R}^{d}$；

• 在两个不同的项中，将 $\mathbf{p}_i\mathbf{W}^q$ 替换为两个可训练参数 $\mathbf{u}$（用于内容）和 $\mathbf{v}$（用于位置）；

• 将 $\mathbf{W}^k$ 分成两个矩阵，$\mathbf{W}^k_E$ 用于内容信息，$\mathbf{W}^k_R$ 用于位置信息。

英文原文：

• Replace $\mathbf{p}_j$ with relative positional encoding $\mathbf{r}_{i-j} \in \mathbf{R}^{d}$;

• Replace $\mathbf{p}_i\mathbf{W}^q$ with two trainable parameters $\mathbf{u}$ (for content) and $\mathbf{v}$ (for location) in two different terms;

• Split $\mathbf{W}^k$ into two matrices, $\mathbf{W}^k_E$ for content information and $\mathbf{W}^k_R$ for location information.

##### 旋转位置嵌入

> Rotary Position Embedding

旋转位置嵌入（*RoPE*；[Su et al. 2021](https://arxiv.org/abs/2104.09864)）使用[旋转矩阵](https://en.wikipedia.org/wiki/Rotation_matrix)编码绝对位置，并将其与每个注意力层的键和值矩阵相乘，以在每一层注入相对位置信息。  


> Rotary position embedding (*RoPE*; [Su et al. 2021](https://arxiv.org/abs/2104.09864)) encodes the absolution position with a [rotation matrix](https://en.wikipedia.org/wiki/Rotation_matrix) and multiplies key and value matrices of every attention layer with it to inject relative positional information at every layer.  

当将相对位置信息编码到第 $i$ 个键和第 $j$ 个查询的内积中时，我们希望以一种方式来 формулировать 该函数，使得内积只与相对位置 $i-j$ 有关。旋转位置嵌入（RoPE）利用欧几里得空间中的旋转操作，并将相对位置嵌入表示为简单地将特征矩阵旋转一个与其位置索引成比例的角度。  


> When encoding relative positional information into the inner product of the $i$ -th key and the $j$ -th query, we would like to formulate the function in a way that the inner product is only about the relative position $i-j$. Rotary Position Embedding (RoPE) makes use of the rotation operation in Euclidean space and frames the relative position embedding as simply rotating feature matrix by an angle proportional to its position index.  

给定向量 $\mathbf{z}$，如果我们要将其逆时针旋转 $\theta$，我们可以将其乘以一个旋转矩阵得到 $R\mathbf{z}$，其中旋转矩阵 $R$ 定义为：

> Given a vector $\mathbf{z}$, if we want to rotate it counterclockwise by $\theta$, we can multiply it by a rotation matrix to get $R\mathbf{z}$ where the rotation matrix $R$ is defined as:

$$
R = \begin{bmatrix}
\cos\theta & -\sin\theta \\
\sin\theta & \cos\theta
\end{bmatrix}
$$

当推广到高维空间时，RoPE 将$d$ -维空间划分为$d/2$个子空间，并构建一个旋转矩阵$R$，其大小为$d \times d$处的词元$i$：

> When generalizing to higher dimensional space, RoPE divide the $d$ -dimensional space into $d/2$ subspaces and constructs a rotation matrix $R$ of size $d \times d$ for token at position $i$:

$$
R^d_{\Theta, i} = \begin{bmatrix}
\cos i\theta_1 & -\sin i\theta_1 & 0 & 0 & \dots & 0 & 0 \\
\sin i\theta_1 & \cos i\theta_1 & 0 & 0 & \dots & 0 & 0 \\
0 & 0 & \cos i\theta_2 & -\sin i\theta_2 & \dots & 0 & 0 \\
0 & 0 & \sin i\theta_2 & \cos i\theta_2 & \dots & 0 & 0 \\
\vdots & \vdots & \vdots & \vdots & \ddots & \vdots & \vdots \\
0 & 0 & 0 & 0 & \dots & \cos i\theta_{d/2} & -\sin i\theta_{d/2} \\
0 & 0 & 0 & 0 & \dots & \sin i\theta_{d/2} & \cos i\theta_{d/2} \\
\end{bmatrix}
$$

其中在论文中我们有$\Theta = {\theta_i = 10000^{-2(i−1)/d}, i \in [1, 2, …, d/2]}$。请注意，这本质上等同于正弦位置编码，但被表述为旋转矩阵。

> where in the paper we have $\Theta = {\theta_i = 10000^{-2(i−1)/d}, i \in [1, 2, …, d/2]}$. Note that this is essentially equivalent to sinusoidal positional encoding but formulated as a rotation matrix.

然后，键和查询矩阵都通过乘以这个旋转矩阵来融入位置信息：

> Then both key and query matrices incorporates the positional information by multiplying with this rotation matrix:

$$
\begin{aligned}
& \mathbf{q}_i^\top \mathbf{k}_j = (R^d_{\Theta, i} \mathbf{W}^q\mathbf{x}_i)^\top (R^d_{\Theta, j} \mathbf{W}^k\mathbf{x}_j) = \mathbf{x}_i^\top\mathbf{W}^q R^d_{\Theta, j-i}\mathbf{W}^k\mathbf{x}_j \\
& \text{ where } R^d_{\Theta, j-i} = (R^d_{\Theta, i})^\top R^d_{\Theta, j}
\end{aligned}
$$

![Visual illustration of how rotary position embedding is implemented.(Image source: Su et al., 2021 ) Note: I used $i$ instead of $m$ to represent the position index compared to the original figure in the paper.](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/RoPE.png)

### 更长的上下文

> Longer Context

Transformer 模型在推理时的输入序列长度受限于训练时使用的上下文长度。天真地增加上下文长度会导致时间 ($\mathcal{O}(L^2d)$) 和内存 ($\mathcal{O}(L^2)$) 的高消耗，并且可能由于硬件限制而不受支持。

> The length of an input sequence for transformer models at inference time is upper-bounded by the context length used for training. Naively increasing context length leads to high consumption in both time ($\mathcal{O}(L^2d)$) and memory ($\mathcal{O}(L^2)$) and may not be supported due to hardware constraints.

本节介绍了几种 Transformer 架构的改进，以更好地支持推理时的长上下文；例如，使用额外内存、设计更好的上下文外推或循环机制。

> This section introduces several improvements in transformer architecture to better support long context at inference; E.g. using additional memory, design for better context extrapolation, or recurrency mechanism.

#### 上下文内存

> Context Memory

香草（vanilla）Transformer 具有固定且有限的注意力范围。模型在每个更新步骤中只能关注同一段中的其他元素，并且信息无法在分离的固定长度段之间流动。这种 *上下文分段* 导致了几个问题：

> The vanilla Transformer has a fixed and limited attention span. The model can only attend to other elements in the same segments during each update step and no information can flow across separated fixed-length segments. This *context segmentation* causes several issues:

- 模型无法捕获非常长期的依赖关系。
- 在没有或上下文稀疏的情况下，很难预测每个段中的前几个 token。
- 评估成本很高。每当片段向右移动一个位置时，新片段都会从头开始重新处理，尽管其中有很多重叠的标记。

> • The model cannot capture very long term dependencies.
> • It is hard to predict the first few tokens in each segment given no or thin context.
> • The evaluation is expensive. Whenever the segment is shifted  to the right by one, the new segment is re-processed from scratch, although there are a lot of overlapped tokens.

**Transformer-XL** ([Dai et al., 2019](https://arxiv.org/abs/1901.02860); “XL” means “extra long”) 通过额外的内存修改了架构，以在片段之间重用隐藏状态。通过连续使用前一个片段的隐藏状态，将片段之间的循环连接引入模型。

> **Transformer-XL** ([Dai et al., 2019](https://arxiv.org/abs/1901.02860); “XL” means “extra long”) modifies the architecture to reuse hidden states between segments with an additional memory. The recurrent connection between segments is introduced into the model by continuously using the hidden states from the previous segments.

![A comparison between the training phrase of vanilla Transformer & Transformer-XL with a segment length 4. (Image source: left part of Figure 2 in Dai et al., 2019 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/transformer-XL-training.png)

我们将模型中第 $n$ 层的第 $(\tau + 1)$ 个片段的隐藏状态标记为 $\mathbf{h}_{\tau+1}^{(n)} \in \mathbb{R}^{L \times d}$。除了同一片段的最后一层的隐藏状态 $\mathbf{h}_{\tau+1}^{(n-1)}$ 之外，它还依赖于前一个片段的同一层的隐藏状态 $\mathbf{h}_{\tau}^{(n)}$。通过整合来自先前隐藏状态的信息，模型将注意力范围在过去扩展得更长，跨越多个片段。

> Let’s label the hidden state of the $n$ -th layer for the $(\tau + 1)$ -th segment in the model as $\mathbf{h}_{\tau+1}^{(n)} \in \mathbb{R}^{L \times d}$. In addition to the hidden state of the last layer for the same segment $\mathbf{h}_{\tau+1}^{(n-1)}$, it also depends on the hidden state of the same layer for the previous segment $\mathbf{h}_{\tau}^{(n)}$.  By incorporating information from the previous hidden states, the model extends the attention span much longer in the past, over multiple segments.

$$
\begin{aligned}
\color{red}{\widetilde{\mathbf{h}}_{\tau+1}^{(n-1)}} &= [\text{stop-gradient}(\mathbf{h}_{\tau}^{(n-1)}) \circ \mathbf{h}_{\tau+1}^{(n-1)}] \\
\mathbf{Q}_{\tau+1}^{(n)} &= \mathbf{h}_{\tau+1}^{(n-1)}\mathbf{W}^q \\
\mathbf{K}_{\tau+1}^{(n)} &= \color{red}{\widetilde{\mathbf{h}}_{\tau+1}^{(n-1)}} \mathbf{W}^k \\
\mathbf{V}_{\tau+1}^{(n)} &= \color{red}{\widetilde{\mathbf{h}}_{\tau+1}^{(n-1)}} \mathbf{W}^v \\
\mathbf{h}_{\tau+1}^{(n)} &= \text{transformer-layer}(\mathbf{Q}_{\tau+1}^{(n)}, \mathbf{K}_{\tau+1}^{(n)}, \mathbf{V}_{\tau+1}^{(n)})
\end{aligned}
$$

请注意，键和值都依赖于扩展的隐藏状态，而查询只消耗当前步骤的隐藏状态。拼接操作 $[. \circ .]$ 沿着序列长度维度进行。Transformer-XL 需要使用 [相对位置编码](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#transformer-xl-encoding)，因为如果我们编码绝对位置，则前一个和当前片段将被分配相同的编码，这是不希望的。

> Note that both keys and values rely on extended hidden states, while queries only consume hidden states at the current step. The concatenation operation $[. \circ .]$ is along the sequence length dimension. And Transformer-XL needs to use [relative positional encoding](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#transformer-xl-encoding) because previous and current segments would be assigned with the same encoding if we encode absolute positions, which is undesired.

**Compressive Transformer** ([Rae et al. 2019](https://arxiv.org/abs/1911.05507)) 通过压缩过去的记忆来扩展 Transformer-XL，以支持更长的序列。它明确地为每层添加了大小为 `m_m` 的 *内存* 插槽，用于存储该层的过去激活，以保留长上下文。当一些过去的激活足够旧时，它们会被压缩并保存在每层大小为 `m_{cm}` 的额外 *压缩内存* 中。

英文原文：Compressive Transformer ([Rae et al. 2019](https://arxiv.org/abs/1911.05507)) extends Transformer-XL by compressing past memories to support longer sequences. It explicitly adds *memory* slots of size `m_m` per layer for storing past activations of this layer to preserve long context. When some past activations become old enough, they are compressed and saved in an additional *compressed memory* of size `m_{cm}` per layer.

![Compressive transformer maintains two types of memory slots, memory and compressed memory, to support long context. (Image source: Rae et al. 2019 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/compressive-transformer.png)

内存和压缩内存都是 FIFO 队列。给定模型上下文长度 $L$，压缩率为 $c$ 的压缩函数定义为 $f_c: \mathbb{R}^{L \times d} \to \mathbb{R}^{[\frac{L}{c}] \times d}$，将 $L$ 个最旧的激活映射到 $[\frac{L}{c}]$ 个压缩内存元素。压缩函数有几种选择：

> Both memory and compressed memory are FIFO queues. Given the model context length $L$, the compression function of compression rate $c$ is defined as $f_c: \mathbb{R}^{L \times d} \to \mathbb{R}^{[\frac{L}{c}] \times d}$, mapping $L$ oldest activations to $[\frac{L}{c}]$ compressed memory elements. There are several choices of compression functions:

1\. 核和步长大小的最大/平均池化 $c$;

2\. 具有核和步长大小的一维卷积 $c$ （需要学习额外的参数）；

3\. 空洞卷积（需要学习额外的参数）。在他们的实验中，卷积压缩在 `EnWik8` 数据集上表现最佳；

4\. 最常用的记忆。

英文原文：

1\. Max/mean pooling of kernel and stride size $c$;

2\. 1D convolution with kernel and stride size $c$ (need to learn additional parameters);

3\. Dilated convolution (need to learn additional parameters). In their experiments, convolution compression works out the best on `EnWik8` dataset;

4\. Most used memories.

压缩式Transformer有两个额外的训练损失：

> Compressive transformer has two additional training losses:

1\. 
**自编码损失** （无损压缩目标）衡量我们从压缩记忆中重建原始记忆的程度

 其中 $g: \mathbb{R}^{[\frac{L}{c}] \times d} \to \mathbb{R}^{L \times d}$ 反转压缩函数 $f$。


2\. **注意力重建损失** (有损目标) 重建基于内容的注意力，比较内存与压缩内存，并最小化其差异：

英文原文：

1\. 
**Auto-encoding loss** (lossless compression objective) measures how well we can reconstruct the original memories from compressed memories

 where $g: \mathbb{R}^{[\frac{L}{c}] \times d} \to \mathbb{R}^{L \times d}$ reverses the compression function $f$.


2\. 
**Attention-reconstruction loss** (lossy objective) reconstructs content-based attention over memory vs compressed memory and minimize the difference:



$$
\mathcal{L}_{ac} = \| \textbf{old_mem}^{(i)} - g(\textbf{new_cm}^{(i)}) \|_2
$$

$$
\mathcal{L}_{ar} = \|\text{attn}(\mathbf{h}^{(i)}, \textbf{old_mem}^{(i)}) − \text{attn}(\mathbf{h}^{(i)}, \textbf{new_cm}^{(i)})\|_2
$$

具有大小为 $m$ 内存的 Transformer-XL 的最大时间范围为 $m \times N$，其中 $N$ 是模型中的层数，注意力成本为 $\mathcal{O}(L^2 + Lm)$。相比之下，压缩 Transformer 的时间范围为 $(m_m + c \cdot m_{cm}) \times N$，注意力成本为 $\mathcal{O}(L^2 + L(m_m + m_{cm}))$。更大的压缩率 $c$ 可以在时间范围长度和注意力成本之间提供更好的权衡。

> Transformer-XL with a memory of size $m$ has a maximum temporal range of $m \times N$, where $N$ is the number of layers in the model, and attention cost $\mathcal{O}(L^2 + Lm)$. In comparison, compressed transformer has a temporal range of $(m_m + c \cdot m_{cm}) \times N$ and attention cost $\mathcal{O}(L^2 + L(m_m + m_{cm}))$. A larger compression rate $c$ gives better tradeoff between temporal range length and attention cost.

注意力权重，从最旧到最新，存储在三个位置：压缩内存 → 内存 → 因果掩码序列。在实验中，他们观察到注意力权重从存储在常规内存中的最旧激活到存储在压缩内存中的激活有所增加，这意味着网络正在学习保留显著信息。

> Attention weights, from oldest to newest, are stored in three locations: compressed memory → memory → causally masked sequence. In the experiments, they observed an increase in attention weights from oldest activations stored in the regular memory, to activations stored in the compressed memory, implying that the network is learning to preserve salient information.

![Attention weights with one standard deviation as error bars versus memory positions, from oldest (left) to newest (right). (Image source: Rae et al. 2019 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/compressive-transformer-memory.png)

#### 不可微分的外部内存

> Non-Differentiable External Memory

**`k`NN-LM** ([Khandelwal et al. 2020](https://arxiv.org/abs/1911.00172)) 通过线性插值两个模型预测的下一个 token 概率，使用单独的 `k`NN 模型增强预训练的 LM。`k`NN 模型建立在一个外部键值存储之上，该存储可以存储任何大型预训练数据集或 OOD 新数据集。这个数据存储经过预处理，以保存*大量*的对，(上下文的 LM 嵌入表示，下一个 token)，并且最近邻检索发生在 LM 嵌入空间中。由于数据存储可能非常庞大，我们需要依赖像 [FAISS](https://github.com/facebookresearch/faiss) 或 [ScaNN](https://github.com/google-research/google-research/tree/master/scann) 这样的库来进行快速密集向量搜索。索引过程只发生一次，并且在推理时很容易实现并行化。

英文原文：`k`NN-LM ([Khandelwal et al. 2020](https://arxiv.org/abs/1911.00172)) enhances a pretrained LM with a separate `k`NN model by linearly interpolating the next token probabilities predicted by both models. The `k`NN model is built upon an external key-value store  which can store any large pre-training dataset or OOD new dataset. This datastore is preprocessed to save a *large* number of pairs, (LM embedding representation of context, next token) and the nearest neighbor retrieval happens in the LM embedding space. Because the datastore can be gigantic, we need to rely on libraries for fast dense vector search such as [FAISS](https://github.com/facebookresearch/faiss) or [ScaNN](https://github.com/google-research/google-research/tree/master/scann). The indexing process only happens once and parallelism is easy to implement at inference time.

在推理时，下一个 token 的概率是两个预测的加权和：

> At inference time, the next token probability is a weighted sum of two predictions:

$$
\begin{aligned}
p(y \vert \mathbf{x}) &= \lambda \; p_\text{kNN}(y \vert \mathbf{x}) + (1- \lambda) \; p_\text{LM}(y \vert \mathbf{x}) \\
p_\text{kNN}(y \vert \mathbf{x}) &\propto \sum_{(k_i, w_i) \in \mathcal{N}} \mathbb{1}[y = w_i] \exp(-d(k_i, f(\mathbf{x})))
\end{aligned}
$$

其中 $\mathcal{N}$ 包含由 $k$NN 检索到的一组最近邻数据点；$d(., .)$ 是一个距离函数，例如 L2 距离。

> where $\mathcal{N}$ contains a set of nearest neighbor data points retrieved by $k$NN; $d(., .)$ is a distance function such as L2 distance.

根据实验，更大的数据存储大小或更大的 $k$ 与更好的困惑度相关。权重标量 $\lambda$ 应该进行调整，但通常对于域外数据，它预计会比域内数据更大，并且更大的数据存储可以承受更大的 $\lambda$。

> According to the experiments, larger datastore size or larger $k$ is correlated with better perplexity. The weighting scalar $\lambda$ should be tuned, but in general it is expected to be larger for out-of-domain data compared to in-domain data and larger datastore can afford a larger $\lambda$.

**SPALM** (*自适应半参数语言模型*; [Yogatama et al. 2021](https://arxiv.org/abs/2102.02557)) 结合了 (1) 用于外部上下文隐藏状态的 Transformer-XL 风格内存作为短期记忆，以及 (2) `k`NN-LM 风格的键值存储作为长期记忆。

英文原文：SPALM (*Adaptive semiparametric language models*; [Yogatama et al. 2021](https://arxiv.org/abs/2102.02557)) incorporates both (1) Transformer-XL style memory for hidden states from external context as short-term memory and (2) `k`NN-LM style key-value store as long memory.

![Illustration of how SPALM combines context memory of past hidden states (short term memory) with an external key-value datastore (long term memory) to support longer context. (Image source: Yogatama et al. 2021 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/SPALM2.png)

SPALM 运行$k$NN 搜索以获取$k$具有最相关上下文的 token。对于每个 token，我们可以获得由预训练语言模型提供的相同嵌入表示，表示为$\{\mathbf{y}_i\}_{i=1}^k$。门控机制首先使用一个简单的注意力层聚合检索到的 token 嵌入，该层使用$\mathbf{h}^R_t$（token 的隐藏状态$x_t$在层$R$）作为查询，然后学习一个门控参数$\mathbf{g}_t$来平衡局部信息$\mathbf{h}^R_t$和长期信息$\mathbf{m}_t$。

> SPALM runs $k$NN search to fetch $k$ tokens with most relevant context. For each token we can get the same embedding representation provided by a pretrained LM, denoted as $\{\mathbf{y}_i\}_{i=1}^k$. The gating mechanism first aggregates the retrieved token embeddings with a simple attention layer using $\mathbf{h}^R_t$ (the hidden state for token $x_t$ at layer $R$) as a query and then learns a gating parameter $\mathbf{g}_t$ to balance between local information $\mathbf{h}^R_t$ and long-term information $\mathbf{m}_t$.

$$
\begin{aligned}
\mathbf{m}_t &= \sum_{i=1}^k \frac{\exp(\mathbf{y}_i^\top \mathbf{h}^R_t)}{\sum_{j=1}^k \exp(\mathbf{y}_j^\top \mathbf{h}^R_t)} \cdot \mathbf{y}_i \\
\mathbf{g}_t &= \sigma(\mathbf{w}_g^\top \mathbf{h}_t^R) \\
\mathbf{z}_t &= (1 - \mathbf{g}_t) \odot \mathbf{m}_t + \mathbf{g}_t \odot \mathbf{h}^R_t \\
p(x_{t+1}\mid \mathbf{x}_{\leq t}) &= \text{softmax}(\mathbf{z}_t; \mathbf{W})
\end{aligned}
$$

其中 $\mathbf{w}_g$ 是一个待学习的参数向量；$\sigma(.)$ 是 sigmoid 函数；$\mathbf{W}$ 是在输入和输出 token 之间共享的词嵌入矩阵。与 $k$NN-LM 不同，他们没有发现最近邻距离对检索到的 token 的聚合有帮助。

> where $\mathbf{w}_g$ is a parameter vector to learn; $\sigma(.)$ is sigmoid; $\mathbf{W}$ is the word embedding matrix shared between both input and output tokens. Different from $k$NN-LM, they didn’t find the nearest neighbor distance to be helpful in the aggregation of retrieved tokens.

在训练期间，长期记忆中的键表示保持不变，由预训练的语言模型生成，但值编码器，即词嵌入矩阵，会得到更新。

> During training, the key representations in the long-term memory stay constant, produced by a pretrained LM, but the value encoder, aka the word embedding matrix, gets updated.

**记忆Transformer** ([Wu 等人 2022](https://arxiv.org/abs/2203.08913)) 在仅解码器Transformer的顶部堆栈附近添加了一个`k`NN增强的注意力层。这个特殊层维护一个Transformer-XL风格的先进先出（FIFO）的过去键值对缓存。

英文原文：Memorizing Transformer ([Wu et al. 2022](https://arxiv.org/abs/2203.08913)) adds a `k`NN-augmented attention layer near the top stack of a decoder-only Transformer. This special layer maintains a Transformer-XL style FIFO cache of past key-value pairs.

局部注意力机制和 $k$NN 机制都使用相同的 QKV 值。$k$NN 查找为输入序列中的每个查询返回前 $k$ 个（键，值）对，然后它们通过自注意力堆栈处理，以计算检索值的加权平均值。两种类型的注意力与一个可学习的每头门控参数相结合。为防止值幅度的较大分布偏移，缓存中的键和值都经过归一化。

> The same QKV values are used for both local attention and $k$NN mechanisms. The $k$NN lookup returns top-$k$ (key, value) pairs for each query in the input sequence and then they are processed through the self-attention stack to compute a weighted average of retrieved values. Two types of attention are combined with a learnable per-head gating parameter. To prevent large distributional shifts in value magnitude, both keys and values in the cache are normalized.

他们在使用记忆型 Transformer 进行实验时发现：

> What they found during experiments with Memorizing Transformer:

- 在一些实验中观察到，使用小内存训练模型，然后用大内存进行微调，比从头开始使用大内存训练效果更好。
- 内存中只有 8k 词元的小型记忆型 Transformer，其困惑度可以与具有 5 倍可训练参数的更大普通 Transformer 相匹配。
- 增加外部内存的大小带来了持续的收益，直至达到 262K 的大小。
- 一个非记忆型Transformer可以通过微调来使用记忆。

> • It is observed in some experiments that training models with a small memory and then finetuned with a larger memory works better than training with a large memory from scratch.
> • The smaller Memorizing Transformer with just 8k tokens in memory can match the perplexity of a larger vanilla Transformer with 5X more trainable parameters.
> • Increasing the size of external memory provided consistent gains up to a size of 262K.
> • A  non-memory transformer can be finetuned to use memory.

![Fine-tuning a vanilla Transformer with a key-value memory can achieve similar performance as training a memorizing transformer from scratch. (Image source: Wu et al. 2022 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/memorizing-transformer.png)

#### 距离增强注意力分数

> Distance-Enhanced Attention Scores

**Distance Aware Transformer**(**DA-Transformer**;
[Wu, et al. 2021](https://aclanthology.org/2021.naacl-main.166))和**Attention with Linear Biases**(**ALiBi**;[Press et al. 2022](https://arxiv.org/abs/2108.12409))都受到类似思想的启发——为了鼓励模型在比训练时更长的上下文上进行外推，我们可以根据键和查询token之间的距离，将位置信息显式地附加到每一对注意力分数上。

> **Distance Aware Transformer**(**DA-Transformer**;
> [Wu, et al. 2021](https://aclanthology.org/2021.naacl-main.166)) and **Attention with Linear Biases** (**ALiBi**; [Press et al. 2022](https://arxiv.org/abs/2108.12409)) are motivated by similar ideas — in order to encourage the model to extrapolate over longer context than what the model is trained on, we can explicitly attach the positional information to every pair of attention score based on the distance between key and query tokens.

请注意，在 vanilla Transformer 中，默认的位置编码只向输入序列添加位置信息，而后来改进的编码机制会改变每一层的注意力分数，例如[旋转位置嵌入](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#rotary-position-embedding)，它们的形式与距离增强注意力分数非常相似。

> Note that the default positional encoding in vanilla Transformer only adds positional information to the input sequence, while later improved encoding mechanisms alter attention scores of every layer, such as [rotary position embedding](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#rotary-position-embedding), and they take on form very similar to distance enhanced attention scores.

*DA-Transformer* ([Wu, et al. 2021](https://aclanthology.org/2021.naacl-main.166)) 在每一层将注意力分数乘以一个可学习的偏置，该偏置被表述为键和查询之间距离的函数。不同的注意力头使用不同的参数来区分对短期上下文和长期上下文的不同偏好。给定两个位置，$i, j$，DA-Transformer 使用以下加权函数来改变自注意力分数：

> *DA-Transformer* ([Wu, et al. 2021](https://aclanthology.org/2021.naacl-main.166)) multiplies attention scores at each layer by a learnable bias that is formulated as a function of the distance between key and query. Different attention heads use different parameters to distinguish diverse preferences to short-term vs long-term context. Given two positions, $i, j$, DA-Transformer uses the following weighting function to alter the self-attention score:

$$
\begin{aligned}
\mathbf{R}^{(i)} &= \alpha_i \mathbf{R} \quad \text{where }R_{ij} = \vert i-j \vert\\
f(\mathbf{R}^{(i)}; \beta_i) &= \frac{1 + \exp(\beta_i)}{1 + \exp(\beta_i - \mathbf{R}^{(i)})} \\
\text{attn}(\mathbf{Q}^{(i)}, \mathbf{K}^{(i)}, \mathbf{V}^{(i)}) &= \text{row-softmax}\Big(\frac{\text{ReLU}(\mathbf{Q}^{(i)}\mathbf{K}^{(i)\top})f(\mathbf{R}^{(i)})}{\sqrt{d}}\Big) \mathbf{V}^{(i)}
\end{aligned}
$$

其中$\alpha_i$是可学习参数，用于对每个头部的相对距离进行不同的加权，其中头部由上标$^{(i)}$；$\beta_i$是可学习参数，用于控制第$i$个注意力头的距离上限和上升斜率。加权函数$f(.)$的设计方式是：(1)$f(0)=1$；(2)$f(\mathbf{R}^{(i)}) = 0$当$\mathbf{R}^{(i)} \to -\infty$；(3)$f(\mathbf{R}^{(i)})$是有界的，当$\mathbf{R}^{(i)} \to +\infty$；(4) 尺度可调；(5) 且函数是单调的。由$f(\mathbf{R}^{(i)})$带来的额外时间复杂度为$\mathcal{O}(L^2)$，相对于自注意力时间复杂度$\mathcal{O}(L^2 d)$而言很小。额外的内存消耗极少，约为$\mathcal{O}(2h)$。

> where $\alpha_i$ is a learnable parameters to weight relative distance differently per head where the head is indexed by superscript $^{(i)}$; $\beta_i$ is a learnable parameter to control the upper bound and ascending slope wrt the distance for the $i$ -th attention head. The weighting function $f(.)$ is designed in a way that: (1) $f(0)=1$; (2) $f(\mathbf{R}^{(i)}) = 0$ when $\mathbf{R}^{(i)} \to -\infty$; (3) $f(\mathbf{R}^{(i)})$ is bounded when $\mathbf{R}^{(i)} \to +\infty$; (4) the scale is tunable; (5) and the function is monotonic. The extra time complexity brought by $f(\mathbf{R}^{(i)})$ is $\mathcal{O}(L^2)$ and it is small relative to the self attention time complexity $\mathcal{O}(L^2 d)$. The extra memory consumption is minimal, ~$\mathcal{O}(2h)$.

与乘子不同，*ALiBi*（[Press et al. 2022](https://arxiv.org/abs/2108.12409)）在查询-键注意力分数上添加了一个常数偏置项，该偏置项与成对距离成正比。这个偏置引入了强烈的近因偏好，并对距离过远的键进行惩罚。在不同的注意力头中，惩罚以不同的速率增加。


$$
\text{softmax}(\mathbf{q}_i \mathbf{K}^\top + \alpha_i \cdot [0, -1, -2, \dots, -(i-1)])
$$


其中 $\alpha_i$ 是一个特定于注意力头的加权标量。与 DA-transformer 不同，$\alpha_i$ 不是学习得到的，而是固定为一个几何序列；例如，对于 8 个头，${\alpha_i} = {\frac{1}{2}, \frac{1}{2^2}, \dots, \frac{1}{2^8}}$。其整体思路与相对位置编码所要解决的问题非常相似。

> Instead of multipliers, *ALiBi* ([Press et al. 2022](https://arxiv.org/abs/2108.12409)) adds a constant bias term on query-key attention scores, proportional to pairwise distances. The bias introduces a strong recency preference and penalizes keys that are too far away. The penalties are increased at different rates within different heads.
>
>
> $$
> \text{softmax}(\mathbf{q}_i \mathbf{K}^\top + \alpha_i \cdot [0, -1, -2, \dots, -(i-1)])
> $$
>
>
> where $\alpha_i$ is a head-specific weighting scalar. Different from DA-transformer, $\alpha_i$ is not learned but fixed as a geometric sequence; for example, for 8 heads, ${\alpha_i} = {\frac{1}{2}, \frac{1}{2^2}, \dots, \frac{1}{2^8}}$. The overall idea is very much similar to what relative positional encoding aims to solve.

![Illustration of how ALiBi enhances attention scores with a positional bias term. (Image source: Press et al. 2021 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/ALiBi-bias.png)

使用 ALiBi，[Press et al. (2022)](https://arxiv.org/abs/2108.12409) 训练了一个 1.3B 模型，在训练期间上下文长度为 1024，并在推理时外推到 2046。

> With ALiBi, [Press et al. (2022)](https://arxiv.org/abs/2108.12409) trained a 1.3B model on context length 1024 during training and extrapolated to 2046 at inference time.

![Extrapolation experiments for running inference with Transformers of different configs, including sinusoidal positional encoding, rotary positional encoding, simplified relative positional encoding in T5 and ALiBi. All models were trained with small context length but inference ran for much longer context. (Image source: Press et al. 2021 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/ALiBi-exp.png)

#### 使其循环

> Make it Recurrent

**通用Transformer** ([Dehghani 等人，2019](https://arxiv.org/abs/1807.03819)) 将Transformer中的自注意力机制与RNN中的循环机制相结合，旨在同时利用Transformer的长期全局感受野和RNN学习到的归纳偏置。通用Transformer不是通过固定数量的层，而是使用[自适应计算时间](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act)动态调整步数。如果我们固定步数，通用Transformer就等同于一个层间参数共享的多层Transformer。

> **Universal Transformer** ([Dehghani, et al. 2019](https://arxiv.org/abs/1807.03819)) combines self-attention in Transformer with the recurrent mechanism in RNN, aiming to benefit from both a long-term global receptive field of Transformer and learned inductive biases of RNN. Rather than going through a fixed number of layers, Universal Transformer dynamically adjusts the number of steps using [adaptive computation time](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act). If we fix the number of steps, an Universal Transformer is equivalent to a multi-layer Transformer with shared parameters across layers.

从宏观层面来看，通用Transformer可以被视为一个循环函数，用于学习每个token的隐藏状态表示。该循环函数在token位置之间并行演化，并且位置之间的信息通过自注意力机制共享。

> On a high level, the universal transformer can be viewed as a recurrent function for learning the hidden state representation per token. The recurrent function evolves in parallel across token positions and the information between positions is shared through self-attention.

![How the Universal Transformer refines a set of hidden state representations repeatedly for every position in parallel. (Image source: Figure 1 in Dehghani, et al. 2019 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/universal-transformer-loop.png)

给定一个长度为$L$的输入序列，Universal Transformer 迭代地更新表示$\mathbf{h}^t \in \mathbb{R}^{L \times d}$在步骤$t$中，可调整的步数。在步骤 0，$\mathbf{h}^0$被初始化为与输入嵌入矩阵相同。所有位置都在多头自注意力机制中并行处理，然后经过一个循环转换函数。

> Given an input sequence of length $L$, Universal Transformer iteratively updates the representation $\mathbf{h}^t \in \mathbb{R}^{L \times d}$ at step $t$ for an adjustable number of steps. At step 0, $\mathbf{h}^0$ is initialized to be same as the input embedding matrix. All the positions are processed in parallel in the multi-head self-attention mechanism and then go through a recurrent transition function.

$$
\begin{aligned}
\mathbf{A}^t &= \text{LayerNorm}(\mathbf{h}^{t-1} + \text{MultiHeadAttention}(\mathbf{h}^{t-1} + \mathbf{P}^t) \\
\mathbf{h}^t &= \text{LayerNorm}(\mathbf{A}^{t-1} + \text{Transition}(\mathbf{A}^t))
\end{aligned}
$$

其中 $\text{Transition}(.)$ 是 [可分离卷积](https://arxiv.org/abs/1610.02357) 或一个全连接神经网络，该网络由两个逐位置（即单独应用于 $\mathbf{A}^t$ 的每一行）的仿射变换 + 一个 ReLU 组成。

> where $\text{Transition}(.)$ is either a [separable convolution](https://arxiv.org/abs/1610.02357) or a fully-connected neural network that consists of two position-wise (i.e. applied to each row of $\mathbf{A}^t$ individually) affine transformation + one ReLU.

位置编码 $\mathbf{P}^t$ 使用 [正弦位置信号](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#sinusoidal-positional-encoding) 但带有一个额外的时间维度：

> The positional encoding $\mathbf{P}^t$ uses [sinusoidal position signal](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#sinusoidal-positional-encoding) but with an additional time dimension:

$$
\text{PE}(i, t, \delta) = 
\begin{cases}
\sin(\frac{i}{10000^{2\delta'/d}}) \oplus \sin(\frac{t}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta'\\
\cos(\frac{i}{10000^{2\delta'/d}}) \oplus \cos(\frac{t}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta' + 1\\
\end{cases}
$$

![A simplified illustration of Universal Transformer. The encoder and decoder share the same basic recurrent structure. But the decoder also attends to final encoder representation $\mathbf{h}^T$. (Image source: Figure 2 in Dehghani, et al. 2019 )](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/universal-transformer.png)

在 Universal Transformer 的自适应版本中，循环步数 $T$ 由 [ACT](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act) 动态确定。每个位置都配备了一个动态 ACT 停止机制。一旦每个 token 的循环块停止，它就会停止进行更多的循环更新，而是简单地将当前值复制到下一步，直到所有块都停止，或者直到模型达到最大步数限制。

> In the adaptive version of Universal Transformer, the number of recurrent steps $T$ is dynamically determined by [ACT](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act). Each position is equipped with a dynamic ACT halting mechanism. Once a per-token recurrent block halts, it stops taking more recurrent updates but simply copies the current value to the next step until all the blocks halt or until the model reaches a maximum step limit.

### 自适应建模

> Adaptive Modeling

自适应建模指的是一种可以根据不同输入调整计算量的机制。例如，某些 token 可能只需要局部信息，因此需要较短的注意力范围；或者某些 token 相对更容易预测，不需要通过整个注意力堆栈进行处理。

> Adaptive modeling refers to a mechanism that can adjust the amount of computation according to different inputs. For example, some tokens may only need local information and thus demand a shorter attention span; Or some tokens are relatively easier to predict and do not need to be processed through the entire attention stack.

#### 自适应注意力范围

> Adaptive Attention Span

Transformer 的一个关键优势是能够捕获长距离依赖关系。根据上下文，模型有时可能更倾向于关注更远的信息，而不是其他信息；或者一个注意力头可能与另一个注意力头具有不同的注意力模式。如果注意力范围能够灵活地调整其长度，并且只在需要时才关注更远的信息，这将有助于减少计算和内存成本，从而支持模型中更长的最大上下文大小。

> One key advantage of Transformer is the capability of capturing long-term dependencies. Depending on the context, the model may prefer to attend further sometime than others; or one attention head may had different attention pattern from the other. If the attention span could adapt its length flexibly and only attend further back when needed, it would help reduce both computation and memory cost to support longer maximum context size in the model.

这是**自适应注意力跨度**的动机。[Sukhbaatar 等人 (2019)](https://arxiv.org/abs/1905.07799)提出了一种寻求最佳注意力跨度的自注意力机制。他们假设不同的注意力头在相同的上下文窗口内可能会以不同的方式分配分数（参见图 14），因此最佳跨度将针对每个头单独训练。

> This is the motivation for **Adaptive Attention Span**. [Sukhbaatar et al (2019)](https://arxiv.org/abs/1905.07799) proposed a self-attention mechanism that seeks an optimal attention span. They hypothesized that different attention heads might assign scores differently within the same context window (See Fig. 14) and thus the optimal span would be trained separately per head.

![Two attention heads in the same model, A & B, assign attention differently within the same context window. Head A attends more to the recent tokens, while head B look further back into the past uniformly. (Image source: Sukhbaatar, et al. 2019 )](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/attention-per-head.png)

给定第 $i$ 个 token，我们需要计算该 token 与其大小为 $s$ 的注意力跨度内的其他键之间的注意力权重：

> Given the $i$ -th token, we need to compute the attention weights between this token and other keys within its attention span of size $s$:

$$
\begin{aligned}
e_{ij} &= \mathbf{q}_i {\mathbf{k}_j}^\top \\ 
a_{ij} &= \text{softmax}(e_{ij}) = \frac{\exp(e_{ij})}{\sum_{r=i-s}^{i-1} \exp(e_{ir})} \\
\mathbf{y}_i &= \sum_{r=i-s}^{i-1}a_{ir}\mathbf{v}_r = \sum_{r=i-s}^{i-1}a_{ir}\mathbf{x}_r\mathbf{W}^v
\end{aligned}
$$

一个 *软掩码函数* $m_z$ 被添加进来，以控制一个有效的可调节注意力范围，它将查询和键之间的距离映射到一个 [0, 1] 值。$m_z$ 由 $z \in [0, s]$ 参数化，$z$ 待学习：

> A *soft mask function* $m_z$ is added to control for an effective adjustable attention span, which maps the distance between query and key into a [0, 1] value. $m_z$ is parameterized by $z \in [0, s]$ and $z$ is to be learned:

$$
m_z(x) = \text{clip}(\frac{1}{R}(R+z-x), 0, 1)
$$

其中 $R$ 是一个超参数，它定义了 $m_z$ 的软度。

> where $R$ is a hyper-parameter which defines the softness of $m_z$.

![The soft masking function used in the adaptive attention span. (Image source: Sukhbaatar, et al. 2019 .)](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/soft-masking-function.png)

软掩码函数应用于注意力权重中的 softmax 元素：

> The soft mask function is applied to the softmax elements in the attention weights:

$$
a_{ij} = \frac{m_z(i-j)\exp(s_{ij})}{\sum_{r=i-s}^{i-1}m_z(i-r) \exp(s_{ir})}
$$

在上述方程中，$z$ 是可微分的，因此它与模型的其他部分一起进行联合训练。参数 $z^{(i)}, i=1, \dots, h$ 是 *每个头单独学习* 的。此外，损失函数对 $\sum_{i=1}^h z^{(i)}$ 还有一个额外的 L1 惩罚。

> In the above equation, $z$ is differentiable so it is trained jointly with other parts of the model. Parameters $z^{(i)}, i=1, \dots, h$ are learned *separately per head*. Moreover, the loss function has an extra L1 penalty on $\sum_{i=1}^h z^{(i)}$.

利用[自适应计算时间](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act)，该方法可以进一步增强，使其具有灵活的注意力跨度长度，并能动态适应当前输入。跨度参数$z_t$的注意力头在时间$t$是一个S型函数，$z_t = S \sigma(\mathbf{v} \cdot \mathbf{x}_t +b)$，其中向量$\mathbf{v}$和偏置标量$b$与其他参数一起学习。

> Using [Adaptive Computation Time](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act), the approach can be further enhanced to have flexible attention span length, adaptive to the current input dynamically. The span parameter $z_t$ of an attention head at time $t$ is a sigmoidal function, $z_t = S \sigma(\mathbf{v} \cdot \mathbf{x}_t +b)$, where the vector $\mathbf{v}$ and the bias scalar $b$ are learned jointly with other parameters.

在具有自适应注意力跨度的Transformer实验中，[Sukhbaatar, et al. (2019)](https://arxiv.org/abs/1905.07799)发现了一个普遍趋势，即较低层不需要很长的注意力跨度，而较高层中的少数注意力头可能会使用异常长的跨度。自适应注意力跨度还有助于大幅减少浮点运算次数（FLOPS），尤其是在具有许多注意力层和长上下文长度的大型模型中。

> In the experiments of Transformer with adaptive attention span, [Sukhbaatar, et al. (2019)](https://arxiv.org/abs/1905.07799) found a general tendency that lower layers do not require very long attention spans, while a few attention heads in higher layers may use exceptionally long spans. Adaptive attention span also helps greatly reduce the number of FLOPS, especially in a big model with many attention layers and a large context length.

#### 深度自适应Transformer

> Depth-Adaptive Transformer

在推理时，很自然地会假设某些token更容易预测，因此不需要像其他token那样多的计算。因此，我们可能只需通过有限数量的层来处理其预测，以在速度和性能之间取得良好平衡。

> At inference time, it is natural to assume that some tokens are easier to predict and thus do not require as much computation as others. Therefore we may only process its prediction through a limited number of layers to achieve a good balance between speed and performance.

**深度自适应Transformer**（[Elabyad et al. 2020](https://arxiv.org/abs/1910.10073)）和**置信自适应语言模型**（**CALM**；[Schuster et al. 2022](https://arxiv.org/abs/2207.07061)）都受此思想启发，并学习预测不同输入token所需的最佳层数。

> Both **Depth-Adaptive Transformer** ([Elabyad et al. 2020](https://arxiv.org/abs/1910.10073)) and **Confident Adaptive Language Model** (**CALM**; [Schuster et al. 2022](https://arxiv.org/abs/2207.07061)) are motivated by this idea and learn to predict optimal numbers of layers needed for different input tokens.

*深度自适应Transformer*（[Elabyad et al. 2020](https://arxiv.org/abs/1910.10073)）为每个层附加一个输出分类器，以根据该层的激活生成退出预测。分类器权重矩阵可以因层而异，也可以跨层共享。在训练期间，模型会采样不同的退出序列，从而使模型通过不同层的隐藏状态进行优化。学习目标包含在不同层预测的似然概率，$n=1, \dots, N$：

> *Depth-adaptive transformer* ([Elabyad et al. 2020](https://arxiv.org/abs/1910.10073)) attaches an output classifier to every layer to produce exit predictions based on activations of that layer. The classifier weight matrices can be different per layer or shared across layers. During training, the model sample different sequences of exits such that the model is optimized with hidden states of different layers. The learning objective incorporates likelihood probabilities predicted at different layers, $n=1, \dots, N$:

$$
\text{LL}^n_t = \log p(y_t \vert \mathbf{h}^n_{t-1}) \quad
\text{LL}^n = \sum_{t=1}^{\vert\mathbf{y}\vert} LL^n_t
$$

自适应深度分类器输出一个参数分布$q_t$。它使用交叉熵损失针对一个预言机分布$q^{\ast}_t$进行训练。该论文探讨了三种配置来学习这种分类器$q_t$。

> Adaptive depth classifiers outputs a parametric distribution $q_t$. It is trained with cross entropy loss against an oracle distribution $q^{\ast}_t$. The paper explored three confiurations for how to learn such a classifier $q_t$.

![Illustration of three types of adaptive depth classifiers. (Image source: Elabyad et al. 2020 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/depth-adaptive-classifier.png)

1\. 
*序列特定深度分类器*：同一序列的所有token共享相同的退出块。它取决于序列编码器表示的平均值。给定输入序列$\mathbf{x}$，其长度为$L$，分类器将$\bar{\mathbf{x}} = \frac{1}{L} \sum_{t=1}^L \mathbf{x}_t$作为输入，并输出一个$N$维度的多项式分布，对应于$N$层。

其中$\delta$是[狄拉克δ](https://en.wikipedia.org/wiki/Dirac_delta_function)（单位脉冲）函数，$-\lambda n$是一个正则化项，用于鼓励较低层的退出。真值$q^{\ast}$可以通过两种方式准备，基于最大似然$q_\text{lik}^{\ast}$或正确性$q_\text{corr}^{\ast}$。
  
  



2\. 
*Token特定深度分类器（多项式）*：每个token都使用不同的退出块进行解码，其预测以第一个解码器隐藏状态$\mathbf{h}^1_t$为条件：

  



3\. *针对 token 的深度分类器（几何式）*: 每个 token 在每层都会生成一个二元退出预测分布，$\mathcal{X}^n_t$。使用 RBF 核 $\kappa(t, t’) = \exp(\frac{\vert t - t’ \vert^2}{\sigma})$ 来平滑预测，以纳入当前决策对未来时间步的影响。

英文原文：

1\. 
*Sequence-specific depth classifier*: All tokens of the same sequence share the same exit block. It depends on the average of the encoder representation of the sequence. Given an input sequence $\mathbf{x}$ of length $L$, the classifier takes $\bar{\mathbf{x}} = \frac{1}{L} \sum_{t=1}^L \mathbf{x}_t$ as input and outputs a multinomial distribution of $N$ dimensions, corresponding to $N$ layers.

where $\delta$ is [dirac delta](https://en.wikipedia.org/wiki/Dirac_delta_function) (unit impulse) function and $-\lambda n$ is a regularization term to encourage lower layer exits. The ground truth $q^{\ast}$ can be prepared in two way, based on maximum likelihood $q_\text{lik}^{\ast}$ or correctness $q_\text{corr}^{\ast}$.
  
  



2\. 
*Token-specific depth classifier (multinomial)*: Each token is decoded with different exit block, predicted conditioned on the first decoder hidden state $\mathbf{h}^1_t$:

  



3\. 
*Token-specific depth classifier (geometric-like)*:  A binary exit prediction distribution is made per layer per token, $\mathcal{X}^n_t$. The RBF kernel $\kappa(t, t’) = \exp(\frac{\vert t - t’ \vert^2}{\sigma})$ is used to smooth the predictions to incorporate the impact of current decision on future time steps.



$$
\begin{aligned}
 q(n \vert \mathbf{x}) &=\text{softmax}(\mathbf{W}_n \bar{\mathbf{x}} + b_n) \in \mathbb{R}^N \\
 q_\text{lik}^*(\mathbf{x}, \mathbf{y}) &= \delta(\arg\max_n \text{LL}^n - \lambda n) \\
 \text{or }q_\text{corr}^*(\mathbf{x}, \mathbf{y}) &= \delta(\arg\max_n C^n - \lambda n) \text{ where }C^n = \vert\{t \vert y_t = \arg\max_y p(y \vert \mathbf{h}^n_{t-1})\}\vert \\
 \end{aligned}
$$

$$
q_t(n \vert \mathbf{x}, \mathbf{y}_{< t}) = \text{softmax}(\mathbf{W}_n \mathbf{h}^1_t + b_n)
$$

$$
\begin{aligned}
 \mathcal{X}^n_t &= \text{sigmoid}(\mathbf{w}_n^\top \mathbf{h}^n_t + b_n)\quad \forall n \in [1, \dots, N-1] \\
 q_t(n \vert \mathbf{x}, \mathbf{y}_{< t}) &= \begin{cases}
 \mathcal{X}^n_t \prod_{n' < n} (1 - \mathcal{X}^{n'}_t) & \text{if } n < N\\
 \prod_{n' < N} (1 - \mathcal{X}^{n'}_t) & \text{otherwise}
 \end{cases} \\
 q_\text{lik}^*(\mathbf{x}, \mathbf{y}) &= \delta(\arg\max_n \widetilde{\text{LL}}^n_t - \lambda n) \text{ where } \widetilde{\text{LL}}^n_t = \sum_{t'=1}^{\vert\mathbf{y}\vert}\kappa(t, t') LL^n_{t'} \\
 \text{or }q_\text{cor}^*(\mathbf{x}, \mathbf{y}) &= \delta(\arg\max_n \tilde{C}_t^n - \lambda n) \text{ where }C_t^n = \mathbb{1}[y_t = \arg\max_y p(y \vert \mathbf{h}^n_{t-1})],\; \tilde{C}^n_t = \sum_{t'=1}^{\vert\mathbf{y}\vert}\kappa(t, t') C^n_{t'} \\
 \end{aligned}
$$

在推理时，需要校准做出退出决策的置信度阈值。深度自适应 Transformer 通过网格搜索在验证集上找到这样的阈值。*CALM* ([Schuster et al. 2022](https://arxiv.org/abs/2207.07061)) 应用了 Learn then Test (LTT) 框架 ([Angelopoulos et al. 2021](https://arxiv.org/abs/2110.01052)) 来识别有效阈值的子集，并选择最小值作为推理阈值。除了训练每层退出分类器外，CALM 还探索了其他自适应深度预测方法，包括 softmax 响应（即前两个 softmax 输出之间的差异）和隐藏状态饱和度（即 $\cos(\mathbf{h}^n_t, \mathbf{h}^{n+1}_t)$）作为退出决策的置信度分数。他们发现 softmax 响应带来了最佳的推理加速。

> At inference time, the confidence threshold for making an exit decision needs to be calibrated. Depth-adaptive transformer finds such a threshold on a validation set via grid search. *CALM* ([Schuster et al. 2022](https://arxiv.org/abs/2207.07061)) applied the Learn then Test (LTT) framework ([Angelopoulos et al. 2021](https://arxiv.org/abs/2110.01052)) to identify a subset of valid thresholds and chose the minimum value as the threshold for inference. Except for training per-layer exit classifier, CALM also explored other methods for adaptive depth prediction, including the softmax responses (i.e. difference between top two softmax outputs) and hidden state saturation (i.e. $\cos(\mathbf{h}^n_t, \mathbf{h}^{n+1}_t)$) as confidence scores for exit decisions. They found softmax responses result in best inference speedup.

### 高效注意力

> Efficient Attention

普通Transformer的计算和内存成本随序列长度呈二次方增长，因此很难应用于非常长的序列。Transformer架构的许多效率改进都与自注意力模块有关——使其运行成本更低、规模更小或速度更快。参见关于*高效Transformer*的综述论文（[Tay et al. 2020](https://arxiv.org/abs/2009.06732)）。

> The computation and memory cost of the vanilla Transformer grows quadratically with sequence length and hence it is hard to be applied on very long sequences. Many efficiency improvements for Transformer architecture have something to do with the self-attention module - making it cheaper, smaller or faster to run. See the survey paper on *Efficient Transformers* ([Tay et al. 2020](https://arxiv.org/abs/2009.06732)).

#### 稀疏注意力模式

> Sparse Attention Patterns

##### 固定局部上下文

> Fixed Local Context

一种使自注意力成本更低的简单替代方法是，将每个token的注意力范围限制在**局部**上下文，这样自注意力就会随序列长度线性增长。

> A simple alternation to make self-attention less expensive is to restrict the attention span of each token to **local** context only, so that self-attention grows linearly with the sequence length.

这个想法由**Image Transformer**（[Parmer, et al 2018](https://arxiv.org/abs/1802.05751)）提出，它使用编码器-解码器Transformer架构将图像生成表述为序列建模：

> The idea was introduced by **Image Transformer** ([Parmer, et al 2018](https://arxiv.org/abs/1802.05751)), which formulates image generation as sequence modeling using an encoder-decoder transformer architecture:

- 编码器生成源图像的上下文感知、逐像素通道表示；
- 然后解码器自回归地生成输出图像，在每个时间步为每个像素生成一个通道。

> • The encoder generates a contextualized, per-pixel-channel representation of the source image;
> • Then the decoder autoregressively generates an output image, one channel per pixel at each time step.

我们将当前待生成像素的表示标记为查询 $\mathbf{q}$。其他位置的表示将用于计算 $\mathbf{q}$，它们是键向量 $\mathbf{k}_1, \mathbf{k}_2, \dots$，它们共同形成一个记忆矩阵 $\mathbf{M}$。$\mathbf{M}$ 的范围定义了像素查询 $\mathbf{q}$ 的上下文窗口。

> Let’s label the representation of the current pixel to be generated as the query $\mathbf{q}$. Other positions whose representations will be used for computing $\mathbf{q}$ are key vector $\mathbf{k}_1, \mathbf{k}_2, \dots$ and they together form a memory matrix $\mathbf{M}$. The scope of $\mathbf{M}$ defines the context window for pixel query $\mathbf{q}$.

Image Transformer 引入了两种局部化的 $\mathbf{M}$，如下图所示。

> Image Transformer introduced two types of localized $\mathbf{M}$, as illustrated below.

![Illustration of 1D and 2D attention span for visual inputs in Image Transformer. The black line marks a query block and the cyan outlines the actual attention span for pixel q. (Image source: Figure 2 in Parmer et al, 2018 )](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/image-transformer-attention.png)

1\. *1D 局部注意力*：输入图像以 [光栅扫描](https://en.wikipedia.org/wiki/Raster_scan#Scanning_pattern) 顺序展平，即从左到右、从上到下。然后将线性化图像划分为不重叠的查询块。上下文窗口由与 $\mathbf{q}$ 相同的查询块中的像素以及在此查询块之前生成的固定数量的额外像素组成。  
  


2\. *2D 局部注意力*：图像被划分为多个不重叠的矩形查询块。查询像素可以关注同一内存块中的所有其他像素。为了确保左上角的像素也能拥有有效的上下文窗口，内存块分别向顶部、左侧和右侧扩展了固定量。

英文原文：

1\. 
*1D Local Attention*: The input image is flattened in the [raster scanning](https://en.wikipedia.org/wiki/Raster_scan#Scanning_pattern) order, that is, from left to right and top to bottom. The linearized image is then partitioned into non-overlapping query blocks. The context window consists of pixels in the same query block as $\mathbf{q}$ and a fixed number of additional pixels generated before this query block.  
  



2\. 
*2D Local Attention*: The image is partitioned into multiple non-overlapping rectangular query blocks. The query pixel can attend to all others in the same memory blocks. To make sure the pixel at the top-left corner can also have a valid context window, the memory block is extended to the top, left and right by a fixed amount, respectively.


##### 步进上下文

> Strided Context

**稀疏 Transformer** ([Child et al., 2019](https://arxiv.org/abs/1904.10509)) 引入了 *分解自注意力*，通过稀疏矩阵分解，使得在序列长度高达 16,384 的情况下训练具有数百层的密集注意力网络成为可能，否则在现代硬件上将不可行。

> **Sparse Transformer** ([Child et al., 2019](https://arxiv.org/abs/1904.10509)) introduced *factorized self-attention*, through sparse matrix factorization, making it possible to train dense attention networks with hundreds of layers on sequence length up to 16,384, which would be infeasible on modern hardware otherwise.

给定一组注意力连接模式$\mathcal{S} = \{S_1, \dots, S_n\}$，其中每个$S_i$记录了第$i$个查询向量所关注的一组关键位置。

> Given a set of attention connectivity pattern $\mathcal{S} = \{S_1, \dots, S_n\}$, where each $S_i$ records a set of key positions that the $i$ -th query vector attends to.

$$
\begin{aligned}
\text{Attend}(\mathbf{X}, \mathcal{S}) &= \Big( a(\mathbf{x}_i, S_i) \Big)_{i \in \{1, \dots, L\}} \\
\text{ where } a(\mathbf{x}_i, S_i) &= \text{softmax}\Big(\frac{(\mathbf{x}_i \mathbf{W}^q)(\mathbf{x}_j \mathbf{W}^k)_{j \in S_i}^\top}{\sqrt{d_k}}\Big) (\mathbf{x}_j \mathbf{W}^v)_{j \in S_i}
\end{aligned}
$$

请注意，尽管$S_i$的大小不固定，但$a(\mathbf{x}_i, S_i)$始终是$d_v$大小，因此$\text{Attend}(\mathbf{X}, \mathcal{S}) \in \mathbb{R}^{L \times d_v}$。

> Note that although the size of $S_i$ is not fixed, $a(\mathbf{x}_i, S_i)$ is always of size $d_v$ and thus $\text{Attend}(\mathbf{X}, \mathcal{S}) \in \mathbb{R}^{L \times d_v}$.

在自回归模型中，一个注意力跨度被定义为$S_i = \{j: j \leq i\}$，因为它允许每个token关注过去的所有位置。

> In auto-regressive models, one attention span is defined as $S_i = \{j: j \leq i\}$ as it allows each token to attend to all the positions in the past.

在分解自注意力中，集合$S_i$被分解为一个依赖关系的*树*，使得对于每一对$(i, j)$（其中$j \leq i$），都存在一条将$i$连接回$j$的路径，并且$i$可以直接或间接地关注$j$。

> In factorized self-attention, the set $S_i$ is decomposed into a *tree* of dependencies, such that for every pair of $(i, j)$ where $j \leq i$, there is a path connecting $i$ back to $j$ and $i$ can attend to $j$ either directly or indirectly.

具体来说，集合$S_i$被划分为$p$个*不重叠*的子集，其中第$m$个子集表示为$A^{(m)}_i \subset S_i, m = 1,\dots, p$。因此，输出位置$i$与任何$j$之间的路径最大长度为$p + 1$。例如，如果$(j, a, b, c, \dots, i)$是$i$和$j$之间的索引路径，我们将有$j \in A_a^{(1)}, a \in A_b^{(2)}, b \in A_c^{(3)}, \dots$，依此类推。

> Precisely, the set $S_i$ is divided into $p$ *non-overlapping* subsets, where the $m$ -th subset is denoted as $A^{(m)}_i \subset S_i, m = 1,\dots, p$. Therefore the path between the output position $i$ and any $j$ has a maximum length $p + 1$. For example, if $(j, a, b, c, \dots, i)$ is a path of indices between $i$ and $j$, we would have $j \in A_a^{(1)}, a \in A_b^{(2)}, b \in A_c^{(3)}, \dots$, so on and so forth.

**稀疏分解注意力**

> **Sparse Factorized Attention**

Sparse Transformer 提出了两种类型的分解注意力。以二维图像输入为例，如图 10 所示，更容易理解这些概念。

> Sparse Transformer proposed two types of fractorized attention. It is easier to understand the concepts as illustrated in Fig. 10 with 2D image inputs as examples.

![The top row illustrates the attention connectivity patterns in (a) Transformer, (b) Sparse Transformer with strided attention, and (c) Sparse Transformer with fixed attention. The bottom row contains corresponding self-attention connectivity matrices. Note that the top and bottom rows are not in the same scale. (Image source: Child et al., 2019 + a few of extra annotations.)](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/sparse-attention.png)

1\. 
*步进式*注意力，步长为 $\ell \sim \sqrt{n}$。这与图像数据配合良好，因为其结构与步长对齐。在图像情况下，每个像素将关注光栅扫描顺序中所有前 $\ell$ 个像素（自然覆盖图像的整个宽度），然后这些像素关注同一列中的其他像素（由另一个注意力连接子集定义）。
  



2\. *固定*注意力。一小组标记总结了之前的位置，并将该信息传播到所有未来的位置。其中 $c$ 是一个超参数。如果 $c=1$，它会限制表示，而许多表示依赖于少数几个位置。该论文选择 $c\in \{ 8, 16, 32 \}$ 用于 $\ell \in \{ 128, 256 \}$。

英文原文：

1\. 
*Strided* attention with stride $\ell \sim \sqrt{n}$. This works well with image data as the structure is aligned with strides. In the image case, each pixel would attend to all the previous $\ell$ pixels in the raster scanning order (naturally cover the entire width of the image) and then those pixels attend to others in the same column (defined by another attention connectivity subset).
  



2\. 
*Fixed* attention. A small set of tokens summarize previous locations and propagate that information to all future locations.

where $c$ is a hyperparameter. If $c=1$, it restricts the representation whereas many depend on a few positions. The paper chose $c\in \{ 8, 16, 32 \}$ for $\ell \in \{ 128, 256 \}$.


$$
\begin{aligned}
 A_i^{(1)} &= \{ t, t+1, \dots, i\} \text{, where } t = \max(0, i - \ell) \\
 A_i^{(2)} &= \{j: (i-j) \mod \ell = 0\}
 \end{aligned}
$$

$$
\begin{aligned}
 A_i^{(1)} &= \{j: \lfloor \frac{j}{\ell} \rfloor = \lfloor \frac{i}{\ell} \rfloor \} \\
 A_i^{(2)} &= \{j: j \mod \ell \in \{\ell-c, \dots, \ell-1\} \}
 \end{aligned}
$$

**在 Transformer 中使用分解自注意力**

> **Use Factorized Self-Attention in Transformer**

在 Transformer 架构中，有三种方法可以使用稀疏分解注意力模式：

> There are three ways to use sparse factorized attention patterns in Transformer architecture:

1\. 每个残差块使用一种注意力类型，然后将它们交错排列，  

$\text{attn}(\mathbf{X}) = \text{Attend}(\mathbf{X}, A^{(n \mod p)}) \mathbf{W}^o$，其中$n$是当前残差块的索引。

2\. 设置一个单一的头，它关注所有分解头都关注的位置，  

$\text{attn}(\mathbf{X}) = \text{Attend}(\mathbf{X}, \cup_{m=1}^p A^{(m)}) \mathbf{W}^o$。

3\. 使用多头注意力机制，但与普通Transformer不同的是，每个头可能采用上述模式1或2。$\rightarrow$此选项通常表现最佳。

英文原文：

1\. One attention type per residual block and then interleave them,   

$\text{attn}(\mathbf{X}) = \text{Attend}(\mathbf{X}, A^{(n \mod p)}) \mathbf{W}^o$, where $n$ is the index of the current residual block.

2\. Set up a single head which attends to locations that all the factorized heads attend to,   

$\text{attn}(\mathbf{X}) = \text{Attend}(\mathbf{X}, \cup_{m=1}^p A^{(m)}) \mathbf{W}^o$.

3\. Use a multi-head attention mechanism, but different from vanilla Transformer, each head might adopt a pattern presented above, 1 or 2. $\rightarrow$ This option often performs the best.

Sparse Transformer 也提出了一系列改进，以便将 Transformer 训练到数百层，包括梯度检查点、在反向传播过程中重新计算注意力层和前馈层、混合精度训练、高效的块稀疏实现等。请查阅 [论文](https://arxiv.org/abs/1904.10509) 获取更多详情，或我之前关于 [扩展模型训练的技术](https://lilianweng.github.io/posts/2021-09-25-train-large/) 的文章。

> Sparse Transformer also proposed a set of changes so as to train the Transformer up to hundreds of layers, including gradient checkpointing, recomputing attention & FF layers during the backward pass, mixed precision training, efficient block-sparse implementation, etc. Please check the [paper](https://arxiv.org/abs/1904.10509) for more details or my previous post on [techniques for scaling up model training](https://lilianweng.github.io/posts/2021-09-25-train-large/).

**分块注意力** ([Qiu 等人 2019](https://arxiv.org/abs/1911.02972)) 引入了一种*稀疏分块矩阵*，以仅允许每个 token 关注一小组其他 token。每个大小为$L \times L$的注意力矩阵被划分为$n \times n$个大小为$\frac{L}{n}\times\frac{L}{n}$的更小块，并且一个稀疏分块矩阵$\mathbf{M} \in \{0, 1\}^{L \times L}$由一个置换`\pi`的${1, \dots, n}$定义，该置换记录了分块矩阵中每行的列索引。

英文原文：Blockwise Attention ([Qiu et al. 2019](https://arxiv.org/abs/1911.02972)) introduces a *sparse block matrix* to only allow each token to attend to a small set of other tokens. Each attention matrix of size 

$L \times L$ is partitioned into 

$n \times n$ smaller blocks of size 

$\frac{L}{n}\times\frac{L}{n}$ and a sparse block matrix 

$\mathbf{M} \in \{0, 1\}^{L \times L}$ is defined by a permutation `\pi` of 

${1, \dots, n}$, which records the column index per row in the block matrix.

$$
\begin{aligned}
\text{attn}(\mathbf{Q}, \mathbf{K}, \mathbf{V}, \mathbf{M}) &= \text{softmax}\Big(\frac{\mathbf{Q}\mathbf{K}^\top}{\sqrt{d}} \odot \mathbf{M}\Big)\mathbf{V} \\
(\mathbf{A} \odot \mathbf{M})_{ij} &= \begin{cases}
A_{ij} & \text{if }M_{ij} = 1 \\
-\infty & \text{if }M_{ij} = 0 \\
\end{cases} \\
\text{where } M_{ij} &= \begin{cases}
1 & \text{if }\pi\big(\lfloor\frac{(i-1)n}{L} + 1\rfloor\big) = \lfloor\frac{(j-1)n}{L} + 1\rfloor \\
0 & \text{otherwise}
\end{cases}
\end{aligned}
$$

块式注意力（Blockwise Attention）的实际实现只将 QKV 存储为块矩阵，每个块矩阵的大小为 $n\times n$：

> The actual implementation of Blockwise Attention only stores QKV as block matrices, each of size $n\times n$:

$$
\text{Blockwise-attn}(\mathbf{Q}, \mathbf{K}, \mathbf{V}, \mathbf{M}) = \begin{bmatrix}
\text{softmax}\big(\frac{\hat{\mathbf{q}}_1\hat{\mathbf{k}}_{\pi(1)}^\top}{\sqrt{d}} \Big)\hat{\mathbf{v}}_{\pi(1)} \\
\vdots \\
\text{softmax}\big(\frac{\hat{\mathbf{q}}_n\hat{\mathbf{k}}_{\pi(n)}^\top}{\sqrt{d}} \odot \Big)\hat{\mathbf{v}}_{\pi(n)} \\
\end{bmatrix}
$$

其中 $\hat{\mathbf{q}}_i$、$\hat{\mathbf{k}}_i$ 和 $\hat{\mathbf{v}}_i$ 分别是 QKV 块矩阵中的第 $i$ 行。每个 $\mathbf{q}_i\mathbf{k}_{\pi(i)}^\top, \forall i = 1, \dots, n$ 的大小为 $\frac{N}{n}\times\frac{N}{n}$，因此块式注意力能够将注意力矩阵的内存复杂度从 $\mathcal{O}(L^2)$ 降低到 $\mathcal{O}(\frac{L}{n}\times\frac{L}{n} \times n) = \mathcal{O}(L^2/n)$。

> where $\hat{\mathbf{q}}_i$, $\hat{\mathbf{k}}_i$ and $\hat{\mathbf{v}}_i$ are the $i$ -the row in the QKV block matrix respectively. Each $\mathbf{q}_i\mathbf{k}_{\pi(i)}^\top, \forall i = 1, \dots, n$ is of size $\frac{N}{n}\times\frac{N}{n}$ and therefore Blockwise Attention is able to reduce the memory complexity of attention matrix from $\mathcal{O}(L^2)$ to $\mathcal{O}(\frac{L}{n}\times\frac{L}{n} \times n) = \mathcal{O}(L^2/n)$.

##### 局部和全局上下文的结合

> Combination of Local and Global Context

**ETC** (*扩展Transformer结构*; [Ainslie et al. 2019](https://aclanthology.org/2020.emnlp-main.19/)), **Longformer** ([Beltagy et al. 2020](https://arxiv.org/abs/2004/05150)) 和 **Big Bird** ([Zaheer et al. 2020](https://arxiv.org/abs/2007.14062)) 模型在构建注意力矩阵时结合了局部和全局上下文。所有这些模型都可以从现有的预训练模型中初始化。

> **ETC** (*Extended Transformer Construction*; [Ainslie et al. 2019](https://aclanthology.org/2020.emnlp-main.19/)), **Longformer** ([Beltagy et al. 2020](https://arxiv.org/abs/2004/05150)) and **Big Bird** ([Zaheer et al. 2020](https://arxiv.org/abs/2007.14062)) models combine both local and global context when building an attention matrix. All these models can be initialized from existing pretrained models.

**全局-局部注意力**的*ETC*（[Ainslie et al. 2019](https://aclanthology.org/2020.emnlp-main.19/)）接收两个输入，（1）长输入$\mathbf{x}^l$大小为`n_l`，它是常规输入序列；（2）全局输入$\mathbf{x}^g$大小为`n_g`，其中包含少量辅助标记，$n_g \ll n_l$。因此，注意力根据这两个输入之间的方向性注意力分为四个部分：g2g、g2l、l2g 和 l2l。由于 l2l 注意力部分可能非常大，它被限制在一个固定大小的注意力半径为`w`（即局部注意力范围），并且 l2l 矩阵可以重塑为$n_l \times (2w+1)$。

英文原文：Global-Local Attention of *ETC* ([Ainslie et al. 2019](https://aclanthology.org/2020.emnlp-main.19/)) takes two inputs, (1) the long input 

$\mathbf{x}^l$ of size `n_l` which is the regular input sequence and (2) the global input 

$\mathbf{x}^g$ of size `n_g` which contains a smaller number of auxiliary tokens, 

$n_g \ll n_l$. Attention is thus split into four components based on directional attention across these two inputs: g2g, g2l, l2g and l2l. Because the l2l attention piece can be very large, it is restricted to a fixed size attention span of radius `w` (i.e. local attention span) and the l2l matrix can be reshaped to 

$n_l \times (2w+1)$.

ETC 利用四个二进制矩阵来处理结构化输入，$\mathbf{M}^{g2g}$、$\mathbf{M}^{g2l}$、$\mathbf{M}^{l2g}$和$\mathbf{M}^{l2l}$。例如，每个元素$z^g_i \in \mathbb{R}^d$在注意力输出$z^g = (z^g_1, \dots, z^g_{n_g})$的 g2g 注意力片段的格式为：

> ETC utilizes four binary matrices to handle structured inputs, $\mathbf{M}^{g2g}$, $\mathbf{M}^{g2l}$, $\mathbf{M}^{l2g}$ and $\mathbf{M}^{l2l}$. For example, each element $z^g_i \in \mathbb{R}^d$ in the attention output $z^g = (z^g_1, \dots, z^g_{n_g})$ for g2g attention piece is formatted as:

$$
\begin{aligned}
a^{g2g}_{ij} = \frac{1}{\sqrt{d}} x^g_i \mathbf{W}^Q (x^g_j \mathbf{W}^K + P^K_{ij})^\top - (1- M^{g2g}_{ij})C \\
A^{g2g}_{ij} = \frac{\exp(a^{g2g}_{ij})}{\sum_{k=1}^{n_g} \exp(a^{g2g}_{ik})} \quad
z^g_i = \sum^{n_g}_{j=1} A^{g2g}_{ij} x^g_j \mathbf{W}^V
\end{aligned}
$$

其中 $P^K_{ij}$ 是用于相对位置编码的可学习向量，并且 $C$ 是一个非常大的常数（$C=10000$ 在论文中），用于在掩码关闭时抵消任何注意力权重。

> where $P^K_{ij}$ is a learnable vector for relative position encoding and $C$ is a very large constant ($C=10000$ in the paper) to offset any attention weights when mask is off.

![Attention patterns of ETC, Longformer and Big Bird.](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/combined-attention.png)

ETC 中的另一个更新是在预训练阶段引入一个使用 [NCE loss](https://lilianweng.github.io/posts/2021-05-31-contrastive/#nce) 的 CPC（对比预测编码）任务，除了 [MLM](https://lilianweng.github.io/posts/2019-01-31-lm/#MLM) 任务之外：当一个句子被掩码时，它的表示应该与它周围上下文的表示相似。

> One more update in ETC is to incorporate a CPC (contrastive predictive coding) task using [NCE loss](https://lilianweng.github.io/posts/2021-05-31-contrastive/#nce) into the pretraining stage, besides the [MLM](https://lilianweng.github.io/posts/2019-01-31-lm/#MLM) task: The representation of one sentence should be similar to the representation of context around it when this sentence is masked.

ETC 的全局输入 $\mathbf{x}^g$ 构建如下：假设长输入中存在一些片段（例如按句子划分），每个片段都附加一个辅助标记以学习全局输入。[相对位置编码](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#relative-position-encoding) 用于根据标记位置标记全局片段标记。在某些数据集中，发现单向硬掩码（即，之前和之后的标记被不同标记）能带来性能提升。

> The global input $\mathbf{x}^g$ for ETC is constructed as follows: Assuming there are some segments within the long inputs (e.g. by sentence), each segment is attached with one auxiliary token to learn global inputs. [Relative position encoding](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#relative-position-encoding) is used to mark the global segment tokens with the token position. Hard masking in one direction (i.e., tokens before vs after are labeled differently) is found to bring performance gains in some datasets.

Longformer 中的注意力模式包含三个组成部分：

> Attention pattern in Longformer contains three components:

1\. *局部注意力*：与 ETC 类似，局部注意力由固定大小的滑动窗口 $w$ 控制；

2\. *预选令牌的全局注意力*: Longformer 有一些预选令牌（例如 `[CLS]` 令牌）被赋予全局注意力范围，这意味着它们会关注输入序列中的所有其他令牌。

3\. *膨胀注意力*: 固定大小为 $r$ 且膨胀大小为 $d$ 的膨胀滑动窗口，类似于 Sparse Transformer；

英文原文：

1\. *Local attention*: Similar to ETC, local attention is controlled by a sliding window of fixed size $w$;

2\. *Global attention of preselected tokens*: Longformer has a few pre-selected tokens (e.g. `[CLS]` token) assigned with global attention span, that is, attending to all other tokens in the input sequence.

3\. *Dilated attention*: Dilated sliding window of fixed size $r$ and gaps of dilation size $d$, similar to Sparse Transformer;

*Big Bird* 与 Longformer 非常相似，它配备了局部注意力和一些具有全局注意力范围的预选令牌，但 Big Bird 用一种新机制取代了膨胀注意力，在该机制中，所有令牌都关注一组随机令牌。这种设计是基于以下事实：注意力模式可以被视为一个 [有向图](https://en.wikipedia.org/wiki/Directed_graph) 并且一个 [随机图](https://en.wikipedia.org/wiki/Random_graph) 具有信息能够在任意一对节点之间快速流动的特性。

> *Big Bird* is quite similar to Longformer, equipped with both local attention and a few preselected tokens with global attention span, but Big Bird replaces dilated attention with a new mechanism where all tokens attend to a set of random tokens. The design is motivated by the fact that attention pattern can be viewed as a [directed graph](https://en.wikipedia.org/wiki/Directed_graph) and a [random graph](https://en.wikipedia.org/wiki/Random_graph) has the property that information is able to rapidly flow between any pair of nodes.

*Longformer* 在较低层使用较小的窗口大小，在较高层使用较大的窗口大小。消融研究表明，这种设置比反向或固定大小的配置效果更好。较低层没有膨胀滑动窗口，以便更好地学习使用即时局部上下文。Longformer 还具有分阶段训练过程，其中模型最初以小窗口大小进行训练以从局部上下文学习，然后后续训练阶段的窗口大小增加，学习率降低。

> *Longformer* uses smaller window size at lower layers and larger window sizes at higher layers. Ablation studies showed that this setup works better than reversed or fixed size config. Lower layers do not have dilated sliding windows to better learn to use immediate local context. Longformer also has a staged training procedure where initially the model is trained with small window size to learn from local context and then subsequent stages of training have window sizes increased and learning rate decreased.

#### 基于内容的注意力

> Content-based Attention

由 **Reformer** ([Kitaev, et al. 2020](https://arxiv.org/abs/2001.04451)) 提出的改进旨在解决普通 Transformer 中的以下痛点：

> The improvements proposed by **Reformer** ([Kitaev, et al. 2020](https://arxiv.org/abs/2001.04451)) aim to solve the following pain points in vanilla Transformer:

• 自注意力模块中的二次时间复杂度与内存复杂度。

• 一个具有 $N$ 层的模型的内存比单层模型大 $N$ 倍，因为我们需要存储激活以进行反向传播。

• 中间的 FF 层通常相当大。

英文原文：

• Quadratic time and memory complexity within self-attention module.

• Memory in a model with $N$ layers is $N$ -times larger than in a single-layer model because we need to store activations for back-propagation.

• The intermediate FF layers are often quite large.

Reformer 提出了两项主要改进：

> Reformer proposed two main changes:

1\. 用 *局部敏感哈希（LSH）注意力* 替换点积注意力，将复杂度从 $\mathcal{O}(L^2)$ 降低到 $\mathcal{O}(L\log L)$。

2\. 用 *可逆残差层* 替换标准残差块，这使得在训练期间只需存储一次激活，而不是 $N$ 次（即与层数成比例）。

英文原文：

1\. Replace the dot-product attention with *locality-sensitive hashing (LSH) attention*, reducing the complexity from $\mathcal{O}(L^2)$ to $\mathcal{O}(L\log L)$.

2\. Replace the standard residual blocks with *reversible residual layers*, which allows storing activations only once during training instead of $N$ times (i.e. proportional to the number of layers).

**局部敏感哈希注意力**

> **Locality-Sensitive Hashing Attention**

在 [注意力公式](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#attention-and-self-attention) 的 $\mathbf{Q} \mathbf{K}^\top$ 部分，我们只对最大的元素感兴趣，因为只有大的元素在 softmax 后贡献很大。对于每个查询 $\mathbf{q}_i \in \mathbf{Q}$，我们正在寻找 $\mathbf{K}$ 中最接近 $\mathbf{q}_i$ 的行向量。为了在高维空间中快速找到最近邻，Reformer 将 [局部敏感哈希（LSH）](https://en.wikipedia.org/wiki/Locality-sensitive_hashing) 融入其注意力机制中。

> In $\mathbf{Q} \mathbf{K}^\top$ part of the [attention formula](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#attention-and-self-attention), we are only interested in the largest elements as only large elements contribute a lot after softmax. For each query $\mathbf{q}_i \in \mathbf{Q}$, we are looking for row vectors in $\mathbf{K}$ closest to $\mathbf{q}_i$. In order to find nearest neighbors quickly in high-dimensional space, Reformer incorporates [Locality-Sensitive Hashing (LSH)](https://en.wikipedia.org/wiki/Locality-sensitive_hashing) into its attention mechanism.

如果哈希方案 $x \mapsto h(x)$ 能够保留数据点之间的距离信息，使得接近的向量获得相似的哈希值，而遥远的向量获得非常不同的哈希值，那么它就是 *局部敏感的*。Reformer 采用了这样的哈希方案，给定一个固定的随机矩阵 $\mathbf{R} \in \mathbb{R}^{d \times b/2}$（其中 $b$ 是一个超参数），哈希函数是 $h(x) = \arg\max([xR; −xR])$。

> A hashing scheme $x \mapsto h(x)$ is *locality-sensitive* if it preserves the distancing information between data points, such that close vectors obtain similar hashes while distant vectors have very different ones. The Reformer adopts a hashing scheme as such, given a fixed random matrix $\mathbf{R} \in \mathbb{R}^{d \times b/2}$ (where $b$ is a hyperparam), the hash function is $h(x) = \arg\max([xR; −xR])$.

![Illustration of Locality-Sensitive Hashing (LSH) attention. (Image source: right part of Figure 1 in Kitaev, et al. 2020 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/LSH-attention-matrix.png)

在 LSH 注意力中，一个查询只能关注同一哈希桶中的位置，$S_i = \{j: h(\mathbf{q}_i) = h(\mathbf{k}_j)\}$。其执行过程如下，如图 20 所示：

> In LSH attention, a query can only attend to positions in the same hashing bucket, $S_i = \{j: h(\mathbf{q}_i) = h(\mathbf{k}_j)\}$. It is carried out in the following process, as illustrated in Fig. 20:

• (a) 全注意力（full attention）的注意力矩阵通常是稀疏的。

• (b) 使用LSH，我们可以根据哈希桶对要对齐的键和查询进行排序。

• (c) 设置 $\mathbf{Q} = \mathbf{K}$ (精确地 $\mathbf{k}_j = \mathbf{q}_j / |\mathbf{q}_j|$)，以便一个桶中有相同数量的键和查询，这更容易进行批处理。有趣的是，这种“共享QK”配置不影响Transformer的性能。

• (d) 应用批处理，其中将 $m$ 个连续查询块分组在一起。

英文原文：

• (a) The attention matrix for full attention is often sparse.

• (b) Using LSH, we can sort the keys and queries to be aligned according to their hash buckets.

• (c) Set $\mathbf{Q} = \mathbf{K}$ (precisely $\mathbf{k}_j = \mathbf{q}_j / |\mathbf{q}_j|$), so that there are equal numbers of keys and queries in one bucket, easier for batching. Interestingly, this “shared-QK” config does not affect the performance of the Transformer.

• (d) Apply batching where chunks of $m$ consecutive queries are grouped together.

![The LSH attention consists of 4 steps: bucketing, sorting, chunking, and attention computation. (Image source: left part of Figure 1 in Kitaev, et al. 2020 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/LSH-attention.png)

**可逆残差网络**

> **Reversible Residual Network**

Reformer的另一个改进是使用*可逆残差层* ([Gomez et al. 2017](https://arxiv.org/abs/1707.04585))。可逆残差网络的动机是以一种方式设计架构，即任何给定层的激活都可以仅使用模型参数从下一层的激活中恢复。因此，我们可以通过在反向传播期间重新计算激活而不是存储所有激活来节省内存。

> Another improvement by Reformer is to use *reversible residual layers* ([Gomez et al. 2017](https://arxiv.org/abs/1707.04585)). The motivation for reversible residual network is to design the architecture in a way that activations at any given layer can be recovered from the activations at the following layer, using only the model parameters. Hence, we can save memory by recomputing the activation during backprop rather than storing all the activations.

给定一个层 $x \mapsto y$，正常的残差层执行 $y = x + F(x)$，但可逆层将输入和输出都分成对 $(x_1, x_2) \mapsto (y_1, y_2)$，然后执行以下操作：

> Given a layer $x \mapsto y$, the normal residual layer does $y = x + F(x)$, but the reversible layer splits both input and output into pairs $(x_1, x_2) \mapsto (y_1, y_2)$ and then executes the following:

$$
y_1 = x_1 + F(x_2),\; y_2 = x_2 + G(y_1)
$$

并且反转很容易：

> and reversing is easy:

$$
x_2 = y_2 - G(y_1), \; x_1 = y_1 − F(x_2)
$$

Reformer通过在可逆网络块中组合注意力 ($F$) 和前馈层 ($G$) 将相同的思想应用于Transformer：

> Reformer applies the same idea to Transformer by combination attention ($F$) and feed-forward layers ($G$) within a reversible net block:

$$
Y_1 = X_1 + \text{Attention}(X_2), \; Y_2 = X_2 + \text{FeedForward}(Y_1)
$$

通过分块前馈计算可以进一步减少内存：

> The memory can be further reduced by chunking the feed-forward computation:

$$
Y_2 = [Y_2^{(1)}; \dots; Y_2^{(c)}] = [X_2^{(1)} + \text{FeedForward}(Y_1^{(1)}); \dots; X_2^{(c)} + \text{FeedForward}(Y_1^{(c)})]
$$

由此产生的可逆Transformer不需要在每一层存储激活。

> The resulting reversible Transformer does not need to store activation in every layer.

**路由Transformer** ([Roy et al. 2021](https://arxiv.org/abs/2003.05997)) 也建立在基于内容的键和查询聚类之上。它没有使用像LSH这样的静态哈希函数，而是利用在线 `k` -均值聚类，并将其与局部、时间稀疏注意力相结合，将注意力复杂度从 $O(L^2)$ 降低到 $O(L^{1.5})$。

英文原文：Routing Transformer ([Roy et al. 2021](https://arxiv.org/abs/2003.05997)) is also built on content-based clustering of keys and queries. Instead of using a static hashing function like LSH, it utilizes online `k` -means clustering and combines it with local, temporal sparse attention to reduce the attention complexity from 

$O(L^2)$ to 

$O(L^{1.5})$.

在路由注意力中，键和查询都使用 $k$ -均值聚类方法和相同的质心集 $\boldsymbol{\mu} = (\mu_1, \dots, \mu_k) \in \mathbb{R}^{k \times d}$ 进行聚类。查询被路由到分配给相同质心的键。总复杂度为 $O(Lkd + L^2d/k)$，其中 $O(Lkd)$ 用于运行聚类分配，$O(L^2d/k)$ 用于注意力计算。聚类质心通过EMA（指数移动平均）使用所有相关的键和查询进行更新。

> Within routing attention, both keys and queries are clustered with $k$ -means clustering method and the same set of centroids $\boldsymbol{\mu} = (\mu_1, \dots, \mu_k) \in \mathbb{R}^{k \times d}$. Queries are routed to keys that get assigned to the same centroid. The total complexity is $O(Lkd + L^2d/k)$, where $O(Lkd)$ is for running clustering assignments and $O(L^2d/k)$ is for attention computation. The cluster centroids are updated by EMA (exponential moving average) using all associated keys and queries.

在 Routing Transformer 的实验中，一些最佳配置仅在模型的最后两层和一半的注意力头中启用了路由注意力，而另一半则使用了局部注意力。他们还观察到局部注意力是一个相当强的基线，并且更大的注意力窗口总是能带来更好的结果。

> In the experiments for Routing Transformer, some best config only has routing attention enabled in the last two layers of the model and half of the attention heads, while the other half utilizing local attention. They also observed that local attention is a pretty strong baseline and larger attention window always leads to better results.

#### 低秩注意力

> Low-Rank Attention

**Linformer** ([Wang et al. 2020](https://arxiv.org/abs/2006.04768)) 使用*低秩*矩阵近似完整的注意力矩阵，将时间和空间复杂度降低到*线性*。Linformer 没有使用昂贵的 SVD 来识别低秩分解，而是分别为键和值矩阵添加了两个线性投影 $\mathbf{E}_i, \mathbf{F}_i \in \mathbb{R}^{L \times k}$，将其维度从 $L \times d$ 降低到 $k \times d$。只要 $k \ll L$，注意力内存就可以大大减少。

英文原文：Linformer ([Wang et al. 2020](https://arxiv.org/abs/2006.04768)) approximates the full attention matrix with a *low rank* matrix, reducing the time & space complexity to be *linear*. Instead of using expensive SVD to identify low rank decomposition, Linformer adds two linear projections 

$\mathbf{E}_i, \mathbf{F}_i \in \mathbb{R}^{L \times k}$ for key and value matrices, respectively, reducing their dimensions from 

$L \times d$ to 

$k \times d$. As long as 

$k \ll L$, the attention memory can be greatly reduced.

$$
\begin{aligned}
\overline{\text{head}}_i 
&= \text{attn}(\mathbf{X}_q\mathbf{W}^q_i, \mathbf{E}_i\mathbf{X}_k\mathbf{W}^k_i, \mathbf{F}_i\mathbf{X}_v\mathbf{W}^v_i) \\
&= \underbrace{\text{softmax}\Big( \frac{\mathbf{X}_q\mathbf{W}^q_i (\mathbf{E}_i \mathbf{X}_k\mathbf{W}^k_i)^\top}{\sqrt{d}} \Big)}_{\text{low rank attention matrix }\bar{A} \in \mathbb{R}^{k \times d}} \mathbf{F}_i \mathbf{X}_v\mathbf{W}^v_i
\end{aligned}
$$

可以应用其他技术来进一步提高 Linformer 的效率：

> Additional techniques can be applied to further improve efficiency of Linformer:

• 投影层之间的参数共享，例如头级、键值级和层级（跨所有层）共享。

• 在不同层使用不同的 $k$，因为较高层中的注意力头往往具有更偏斜的分布（较低的秩），因此我们可以在较高层使用较小的 $k$。

• 使用不同类型的投影；例如，平均/最大池化，带有核和步长 $L/k$ 的卷积层。

英文原文：

• Parameter sharing between projection layers, such as head-wise, key-value  and layer-wise (across all layers) sharing.

• Use different $k$ at different layers, as heads in higher layers tend to have a more skewed distribution (lower rank) and thus we can use smaller $k$ at higher layers.

• Use different types of projections; e.g. mean/max pooling, convolution layer with kernel and stride $L/k$.

![(Left) Informer has two projection layers added for keys and values. (Right) Plot of inference time as a function of sequence length. (Image source: Wang et al. 2020 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/linformer.png)

**随机特征注意力** (**RFA**; [Peng et al. 2021](https://arxiv.org/abs/2103.02143)) 依赖于*随机特征方法* ([Rahimi & Recht, 2007](https://people.eecs.berkeley.edu/~brecht/papers/07.rah.rec.nips.pdf)) 来使用低秩特征图近似自注意力中的 softmax 操作，以实现线性的时间和空间复杂度。**Performers** ([Choromanski et al. 2021](https://arxiv.org/abs/2009.14794)) 也采用了随机特征注意力，并在核构造方面进行了改进，以进一步减少核近似误差。

> **Random Feature Attention** (**RFA**; [Peng et al. 2021](https://arxiv.org/abs/2103.02143)) relies on *random feature methods* ([Rahimi & Recht, 2007](https://people.eecs.berkeley.edu/~brecht/papers/07.rah.rec.nips.pdf)) to approximate softmax operation in self-attention with low rank feature maps in order to achieve linear time and space complexity. **Performers** ([Choromanski et al. 2021](https://arxiv.org/abs/2009.14794)) also adopts random feature attention with improvements on the kernel construction to further reduce the kernel approximation error.

RFA 背后的主要定理来自 [Rahimi & Recht, 2007](https://people.eecs.berkeley.edu/~brecht/papers/07.rah.rec.nips.pdf)：

> The main theorem behind RFA is from [Rahimi & Recht, 2007](https://people.eecs.berkeley.edu/~brecht/papers/07.rah.rec.nips.pdf):

引用译文：

令 $\phi: \mathbb{R}^d \to \mathbb{R}^{2D}$ 为非线性变换：

$$
\phi(\mathbf{x}) = \frac{1}{\sqrt{D}}[\sin(\mathbf{w}_1^\top \mathbf{x}), \dots, \sin(\mathbf{w}_D^\top \mathbf{x}), \cos(\mathbf{w}_1^\top \mathbf{x}), \dots, \cos(\mathbf{w}_D^\top \mathbf{x})]^\top
$$

英文原文：

Let $\phi: \mathbb{R}^d \to \mathbb{R}^{2D}$ be a nonlinear transformation:

$$
\phi(\mathbf{x}) = \frac{1}{\sqrt{D}}[\sin(\mathbf{w}_1^\top \mathbf{x}), \dots, \sin(\mathbf{w}_D^\top \mathbf{x}), \cos(\mathbf{w}_1^\top \mathbf{x}), \dots, \cos(\mathbf{w}_D^\top \mathbf{x})]^\top
$$

$\exp(\mathbf{x} \cdot \mathbf{y})$ 的无偏估计是：

> An unbiased estimation of $\exp(\mathbf{x} \cdot \mathbf{y})$ is:

$$
\begin{aligned}
\exp(\mathbf{x} \cdot \mathbf{y} / \sigma^2) 
&= \exp(\frac{1}{2\sigma^2}(\|\mathbf{x}\|^2 + \|\mathbf{y}\|^2 - \|\mathbf{x} - \mathbf{y}\|^2) \\
&= \exp(\frac{\|\mathbf{x}\|^2}{2\sigma^2}) \exp(\frac{\|\mathbf{y}\|^2}{2\sigma^2}) ( - \frac{\|\mathbf{x} - \mathbf{y}\|^2}{2\sigma^2}) \\
&\approx \exp(\frac{\|\mathbf{x}\|^2}{2\sigma^2}) \exp(\frac{\|\mathbf{y}\|^2}{2\sigma^2})\;\phi(\mathbf{x})\cdot\phi(\mathbf{y}) \\
&= \exp(\frac{1}{\sigma^2})\;\phi(\mathbf{x})\cdot\phi(\mathbf{y}) & \text{; unit vectors}
\end{aligned}
$$

然后我们可以将注意力函数写成如下形式，其中 $\otimes$ 是外积运算，$\sigma^2$ 是温度：

> Then we can write the attention function as follows, where $\otimes$ is outer product operation and $\sigma^2$ is the temperature:

$$
\begin{aligned}
\text{attn}(\mathbf{q}_t, \{\mathbf{k}_i\}, \{\mathbf{v}_i\}) 
&= \sum_i \frac{\exp(\mathbf{q}_t\cdot\mathbf{k}_i/\sigma^2)}{\sum_j \exp(\mathbf{q}_t\cdot\mathbf{k}_j/\sigma^2)}\mathbf{v}_i^\top
\approx \sum_i \frac{\phi(\mathbf{q}_t)\phi(\mathbf{k}_i)\mathbf{v}_i^\top}{\sum_j \phi(\mathbf{q}_t)\phi(\mathbf{k}_j)} \\
&= \color{green}{\frac{\phi(\mathbf{q}_t)^\top \sum_i \phi(\mathbf{k}_i)\otimes\mathbf{v}_i}{\phi(\mathbf{q}_t)^\top \sum_j \phi(\mathbf{k}_j)}
= \text{RFA}(\mathbf{q}_t, \{\mathbf{k}_i\}, \{\mathbf{v}_i\})}
\end{aligned}
$$

![(Left) The order of computation for default softmax operation. (Right) The order of computation when using random feature attention, a lot cheaper than default softmax. (Image source: Peng et al. 2021 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/RFA.png)

**Causal Attention RFA** 在时间步 `t` 的 token 只关注较早的键和值 $\{\mathbf{k}_i\}_{i \leq t}, \{\mathbf{v}_i\}_{i \leq t}$。让我们使用一个变量元组，$(\mathbf{S}_t \in \mathbb{R}^{2D \times d}, \mathbf{z} \in \mathbb{R}^{2D})$，来跟踪时间步 `t` 的隐藏状态历史，类似于 RNNs：

英文原文：Causal Attention RFA has token at time step `t` only attend to earlier keys and values 

$\{\mathbf{k}_i\}_{i \leq t}, \{\mathbf{v}_i\}_{i \leq t}$. Let us use a tuple of variables, 

$(\mathbf{S}_t \in \mathbb{R}^{2D \times d}, \mathbf{z} \in \mathbb{R}^{2D})$, to track the hidden state history at time step `t`, similar to RNNs:

$$
\begin{aligned}
&\text{causal-RFA}(\mathbf{q}_t, \{\mathbf{k}_i\}_{i \leq t}, \{\mathbf{v}_i\}_{i \leq t}) = \frac{\phi(\mathbf{q}_t)^\top \mathbf{S}_t}{\phi(\mathbf{q}_t) \cdot \mathbf{z}_t} \\
&\text{where } 
\mathbf{S}_t = \mathbf{S}_{t-1} + \phi(\mathbf{k}_t)\otimes\mathbf{v}_t,
\quad 
\mathbf{z}_t = \mathbf{z}_{t-1} + \phi(\mathbf{k}_t)
\end{aligned}
$$

其中 $2D$ 是 $\phi(.)$ 的大小，并且 $D$ 应该不小于模型大小 $d$ 以获得合理的近似。

> where $2D$ is the size of $\phi(.)$ and $D$ should be no less than the model size $d$ for reasonable approximation.

RFA 在自回归解码中带来了显著的速度提升，其内存复杂度主要取决于 $D$ 在构建核时 $\phi(.)$。

> RFA leads to significant speedup in autoregressive decoding and the memory complexity mainly depends on the choice of $D$ when constructing the kernel $\phi(.)$.

Performer 通过正随机特征映射修改随机特征注意力，以减少估计误差。它还保持随机采样的 $\mathbf{w}_1, \dots, \mathbf{w}_D$ 正交，以进一步减少估计器的方差。

> Performer modifies the random feature attention with positive random feature maps to reduce the estimation error. It also keeps the randomly sampled $\mathbf{w}_1, \dots, \mathbf{w}_D$ to be orthogonal to further reduce the variance of the estimator.

![Comparison of approximation error when using (Left) i.i.d vs orthogonal features and (Right) sin/cos vs positive random features. (Image source: Choromanski et al. 2021 ).](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/performer.png)

### 用于强化学习的 Transformer

> Transformers for Reinforcement Learning

自注意力机制避免将整个过去压缩成固定大小的隐藏状态，并且不像 RNN 那样容易出现梯度消失或梯度爆炸问题。强化学习任务无疑可以从这些特性中受益。*然而*，即使在监督学习中，训练 Transformer 也相当困难，更不用说在强化学习环境中了。毕竟，单独稳定和训练一个 LSTM 智能体可能相当具有挑战性。

> The self-attention mechanism avoids compressing the whole past into a fixed-size hidden state and does not suffer from vanishing or exploding gradients as much as RNNs. Reinforcement Learning tasks can for sure benefit from these traits. *However*, it is quite difficult to train Transformer even in supervised learning, let alone in the RL context. It could be quite challenging to stabilize and train a LSTM agent by itself, after all.

**门控 Transformer-XL** (**GTrXL**；[Parisotto 等人，2019](https://arxiv.org/abs/1910.06764)) 是将 Transformer 用于强化学习的一种尝试。GTrXL 在 [Transformer-XL](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#longer-attention-span-transformer-xl) 的基础上通过两项改动成功稳定了训练：

> The **Gated Transformer-XL** (**GTrXL**; [Parisotto, et al. 2019](https://arxiv.org/abs/1910.06764)) is one attempt to use Transformer for RL. GTrXL succeeded in stabilizing training with two changes on top of [Transformer-XL](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#longer-attention-span-transformer-xl):

1. 层归一化仅应用于残差模块中的输入流，而不应用于快捷流。这种重新排序的一个主要好处是允许原始输入从第一层流向最后一层。
2. 残差连接被 GRU 风格（门控循环单元；[Chung 等人，2014](https://arxiv.org/abs/1412.3555)）的*门控*机制取代。

> • The layer normalization is only applied on the input stream in a residual module, but NOT on the shortcut stream. A key benefit to this reordering is to allow the original input to flow from the first to last layer.
> • The residual connection is replaced with a GRU-style (Gated Recurrent Unit; [Chung et al., 2014](https://arxiv.org/abs/1412.3555)) *gating* mechanism.

$$
\begin{aligned}
r &= \sigma(W_r^{(l)} y + U_r^{(l)} x) \\
z &= \sigma(W_z^{(l)} y + U_z^{(l)} x - b_g^{(l)}) \\
\hat{h} &= \tanh(W_g^{(l)} y + U_g^{(l)} (r \odot x)) \\
g^{(l)}(x, y) &= (1-z)\odot x + z\odot \hat{h}
\end{aligned}
$$

门控函数参数被显式初始化为接近恒等映射——这就是为什么存在一个$b_g$项。一个$b_g > 0$极大地有助于学习速度的提升。

> The gating function parameters are explicitly initialized to be close to an identity map - this is why there is a $b_g$ term. A $b_g > 0$ greatly helps with the learning speedup.

![Comparison of the model architecture of Transformer-XL, Transformer-XL with the layer norm reordered, and Gated Transformer-XL. (Image source: Figure 1 in Parisotto, et al. 2019 )](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/gated-transformer-XL.png)

**决策Transformer** (**DT**; [Chen et al 2021](https://arxiv.org/abs/2106.01345)) 将强化学习问题表述为*条件序列建模*过程，输出基于期望回报、过去状态和动作的条件最优动作。因此，使用Transformer架构变得简单直接。决策Transformer适用于[离策略强化学习](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#key-concepts)，其中模型只能访问由其他策略收集的固定轨迹集合。

> **Decision Transformer** (**DT**; [Chen et al 2021](https://arxiv.org/abs/2106.01345)) formulates Reinforcement Learning problems as a process of *conditional sequence modeling*, outputting the optimal actions conditioned on the desired return, past states and actions. It therefore becomes straightforward to use Transformer architecture. Decision Transformer is for [off-policy RL](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#key-concepts), where the model only has access to a fixed collection of trajectories collected by other policies.

为了鼓励模型学习如何行动以实现期望的回报，它向模型输入期望的未来回报 $\hat{R} = \sum_{t’=t}^T r_{t’}$ 而不是当前的奖励。轨迹由三元组列表（return-to-go $\hat{R}_t, state$s_t$, action$a_t$）组成，并用作 Transformer 的输入序列：

> To encourage the model to learn how to act in order to achieve a desired return, it feeds the model with desired future return $\hat{R} = \sum_{t’=t}^T r_{t’}$ instead of the current reward. The trajectory consists of a list of triplets, (return-to-go $\hat{R}_t, state$s_t$, action$a_t$), and it is used as an input sequence for Transformer:

$$
\tau = (\hat{R}_1, s_1, a_1, \hat{R}_2, s_2, a_2, \dots, \hat{R}_T, s_T, a_T)
$$

添加并训练了三个线性层，分别用于return-to-go、状态和动作，以提取token嵌入。预测头学习预测$a_t$与输入token$s_t$。训练使用交叉熵损失处理离散动作，或使用MSE处理连续动作。在他们的实验中，预测状态或return-to-go并未发现有助于提高性能。

> Three linear layers are added and trained for return-to-go, state and action respectively to extract token embeddings. The prediction head learns to predict $a_t$ corresponding to the input token $s_t$. The training uses cross-entropy loss for discrete actions or MSE for continuous actions. Predicting the states or return-to-go was not found to help improve the performance in their experiments.

实验将DT与几种无模型强化学习算法基线进行了比较，结果表明：

> The experiments compared DT with several model-free RL algorithm baselines and showed that:

- 在低数据量情况下，DT比行为克隆更高效；
- DT能够很好地模拟回报的分布；
- 拥有长上下文对于获得良好结果至关重要；
- DT可以处理稀疏奖励。

> • DT is more efficient than behavior cloning in low data regime;
> • DT can model the distribution of returns very well;
> • Having a long context is crucial for obtaining good results;
> • DT can work with sparse rewards.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Jan 2023). The transformer family version 2.0. Lil’Log. https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/.

> Weng, Lilian. (Jan 2023). The transformer family version 2.0. Lil’Log. https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/.

或

> Or

```
@article{weng2023transformer,
  title   = "The Transformer Family Version 2.0",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2023",
  month   = "Jan",
  url     = "https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/"
}
```

### 参考文献

> References

[1] Ashish Vaswani, et al. [“Attention Is All You Need。”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf) NIPS 2017.

> [1] Ashish Vaswani, et al. [“Attention is all you need.”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf) NIPS 2017.

[2] Rami Al-Rfou, et al. [“使用更深层自注意力进行字符级语言建模。”](https://arxiv.org/abs/1808.04444) AAAI 2019.

> [2] Rami Al-Rfou, et al. [“Character-level language modeling with deeper self-attention.”](https://arxiv.org/abs/1808.04444) AAAI 2019.

[3] Olah & Carter, [“注意力与增强循环神经网络”](http://doi.org/10.23915/disti), Distill, 2016.

> [3] Olah & Carter, [“Attention and Augmented Recurrent Neural Networks”](http://doi.org/10.23915/disti), Distill, 2016.

[4] Sainbayar Sukhbaatar, et al. [“Transformer中的自适应注意力跨度”](https://arxiv.org/abs/1905.07799). ACL 2019.

> [4] Sainbayar Sukhbaatar, et al. [“Adaptive Attention Span in Transformers”](https://arxiv.org/abs/1905.07799). ACL 2019.

[5] Rewon Child, et al. [“使用稀疏Transformer生成长序列”](https://arxiv.org/abs/1904.10509) arXiv:1904.10509 (2019).

> [5] Rewon Child, et al. [“Generating Long Sequences with Sparse Transformers”](https://arxiv.org/abs/1904.10509) arXiv:1904.10509 (2019).

[6] Nikita Kitaev, et al. [“Reformer：高效Transformer”](https://arxiv.org/abs/2001.04451) ICLR 2020.

> [6] Nikita Kitaev, et al. [“Reformer: The Efficient Transformer”](https://arxiv.org/abs/2001.04451) ICLR 2020.

[7] Alex Graves. (“循环神经网络的自适应计算时间”)[https://arxiv.org/abs/1603.08983]

> [7] Alex Graves. (“Adaptive Computation Time for Recurrent Neural Networks”)[https://arxiv.org/abs/1603.08983]

[8] Niki Parmar, et al. [“图像Transformer”](https://arxiv.org/abs/1802.05751) ICML 2018.

> [8] Niki Parmar, et al. [“Image Transformer”](https://arxiv.org/abs/1802.05751) ICML 2018.

[9] Zihang Dai, et al. [“Transformer-XL：超越固定长度上下文的注意力语言模型。”](https://arxiv.org/abs/1901.02860) ACL 2019.

> [9] Zihang Dai, et al. [“Transformer-XL: Attentive Language Models Beyond a Fixed-Length Context.”](https://arxiv.org/abs/1901.02860) ACL 2019.

[10] Aidan N. Gomez, et al. [“可逆残差网络：无需存储激活的反向传播”](https://arxiv.org/abs/1707.04585) NIPS 2017.

> [10] Aidan N. Gomez, et al. [“The Reversible Residual Network: Backpropagation Without Storing Activations”](https://arxiv.org/abs/1707.04585) NIPS 2017.

[11] Mostafa Dehghani, et al. [“通用Transformer”](https://arxiv.org/abs/1807.03819) ICLR 2019.

> [11] Mostafa Dehghani, et al. [“Universal Transformers”](https://arxiv.org/abs/1807.03819) ICLR 2019.

[12] Emilio Parisotto, et al. [“稳定Transformer用于强化学习”](https://arxiv.org/abs/1910.06764) arXiv:1910.06764 (2019).

> [12] Emilio Parisotto, et al. [“Stabilizing Transformers for Reinforcement Learning”](https://arxiv.org/abs/1910.06764) arXiv:1910.06764 (2019).

[13] Rae et al. [“用于长程序列建模的压缩Transformer。”](https://arxiv.org/abs/1911.05507) 2019.

> [13] Rae et al. [“Compressive Transformers for Long-Range Sequence Modelling.”](https://arxiv.org/abs/1911.05507) 2019.

[14] Press et al. [“短训练，长测试：带线性偏置的注意力实现输入长度外推。”](https://arxiv.org/abs/2108.12409) ICLR 2022.

> [14] Press et al. [“Train Short, Test Long: Attention With Linear Biases Enables Input Length Extrapolation.”](https://arxiv.org/abs/2108.12409) ICLR 2022.

[15] Wu, et al. [“DA-Transformer：距离感知Transformer”](https://aclanthology.org/2021.naacl-main.166) 2021.

> [15] Wu, et al. [“DA-Transformer: Distance Aware Transformer”](https://aclanthology.org/2021.naacl-main.166) 2021.

[16] Elabyad et al. [“深度自适应Transformer。”](https://arxiv.org/abs/1910.10073) ICLR 2020.

> [16] Elabyad et al. [“Depth-Adaptive Transformer.”](https://arxiv.org/abs/1910.10073) ICLR 2020.

[17] Schuster et al. [“置信自适应语言建模”](https://arxiv.org/abs/2207.07061) 2022.

> [17] Schuster et al. [“Confident Adaptive Language Modeling”](https://arxiv.org/abs/2207.07061) 2022.

[18] Qiu et al. [“用于长文档理解的块级自注意力”](https://arxiv.org/abs/1911.02972) 2019

> [18] Qiu et al. [“Blockwise self-attention for long document understanding”](https://arxiv.org/abs/1911.02972) 2019

[19] Roy et al. [“使用路由Transformer的高效基于内容的稀疏注意力。”](https://arxiv.org/abs/2003.05997) 2021.

> [19] Roy et al. [“Efficient Content-Based Sparse Attention with Routing Transformers.”](https://arxiv.org/abs/2003.05997) 2021.

[20] Ainslie et al. [“ETC：在Transformer中编码长而结构化的输入。”](https://aclanthology.org/2020.emnlp-main.19/) EMNLP 2019.

> [20] Ainslie et al. [“ETC: Encoding Long and Structured Inputs in Transformers.”](https://aclanthology.org/2020.emnlp-main.19/) EMNLP 2019.

[21] Beltagy et al. [“Longformer：长文档Transformer。”](https://arxiv.org/abs/2004/05150) 2020.

> [21] Beltagy et al. [“Longformer: The long-document transformer.”](https://arxiv.org/abs/2004/05150) 2020.

[22] Zaheer et al. [“Big Bird：用于更长序列的Transformer。”](https://arxiv.org/abs/2007.14062) 2020.

> [22] Zaheer et al. [“Big Bird: Transformers for Longer Sequences.”](https://arxiv.org/abs/2007.14062) 2020.

[23] Wang et al. [“Linformer：具有线性复杂度的自注意力。”](https://arxiv.org/abs/2006.04768) arXiv preprint arXiv:2006.04768 (2020).

> [23] Wang et al. [“Linformer: Self-Attention with Linear Complexity.”](https://arxiv.org/abs/2006.04768) arXiv preprint arXiv:2006.04768 (2020).

[24] Tay et al. 2020 [“稀疏Sinkhorn注意力。”](https://arxiv.org/abs/2002.11296) ICML 2020.

> [24] Tay et al. 2020 [“Sparse Sinkhorn Attention.”](https://arxiv.org/abs/2002.11296) ICML 2020.

[25] Peng et al. [“随机特征注意力。”](https://arxiv.org/abs/2103.02143) ICLR 2021.

> [25] Peng et al. [“Random Feature Attention.”](https://arxiv.org/abs/2103.02143) ICLR 2021.

[26] Choromanski et al. [“使用Performers重新思考注意力。”](https://arxiv.org/abs/2009.14794) ICLR 2021.

> [26] Choromanski et al. [“Rethinking Attention with Performers.”](https://arxiv.org/abs/2009.14794) ICLR 2021.

[27] Khandelwal et al. [“通过记忆实现泛化：最近邻语言模型。”](https://arxiv.org/abs/1911.00172) ICLR 2020.

> [27] Khandelwal et al. [“Generalization through memorization: Nearest neighbor language models.”](https://arxiv.org/abs/1911.00172) ICLR 2020.

[28] Yogatama et al. [“自适应半参数语言模型。”](https://arxiv.org/abs/2102.02557) ACL 2021.

> [28] Yogatama et al. [“Adaptive semiparametric language models.”](https://arxiv.org/abs/2102.02557) ACL 2021.

[29] Wu et al. [“记忆Transformer。”](https://arxiv.org/abs/2203.08913) ICLR 2022.

> [29] Wu et al. [“Memorizing Transformers.”](https://arxiv.org/abs/2203.08913) ICLR 2022.

[30] Su et al. [“Roformer：带有旋转位置嵌入的增强型Transformer。”](https://arxiv.org/abs/2104.09864) arXiv preprint arXiv:2104.09864 (2021).

> [30] Su et al. [“Roformer: Enhanced transformer with rotary position embedding.”](https://arxiv.org/abs/2104.09864) arXiv preprint arXiv:2104.09864 (2021).

[31] Shaw et al. [“带有相对位置表示的自注意力。”](https://arxiv.org/abs/1803.02155) arXiv preprint arXiv:1803.02155 (2018).

> [31] Shaw et al. [“Self-attention with relative position representations.”](https://arxiv.org/abs/1803.02155) arXiv preprint arXiv:1803.02155 (2018).

[32] Tay et al. [“高效Transformer：一项综述。”](https://arxiv.org/abs/2009.06732) ACM Computing Surveys 55.6 (2022): 1-28.

> [32] Tay et al. [“Efficient Transformers: A Survey.”](https://arxiv.org/abs/2009.06732) ACM Computing Surveys 55.6 (2022): 1-28.

[33] Chen et al., [“决策Transformer：通过序列建模进行强化学习”](https://arxiv.org/abs/2106.01345) arXiv preprint arXiv:2106.01345 (2021).

> [33] Chen et al., [“Decision Transformer: Reinforcement Learning via Sequence Modeling”](https://arxiv.org/abs/2106.01345) arXiv preprint arXiv:2106.01345 (2021).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Transformer | 转换器模型 | 一种基于自注意力机制的神经网络架构，广泛应用于自然语言处理。 |
| Encoder-Decoder Architecture | 编码器-解码器架构 | 一种神经网络结构，由一个编码器将输入序列映射到中间表示，一个解码器从该表示生成输出序列。 |
| Self-Attention | 自注意力 | 一种注意力机制，模型利用同一数据样本中其他部分的观察来预测该样本的某一部分。 |
| Multi-Head Self-Attention | 多头自注意力 | Transformer中的关键组件，将输入分成多个子空间并行计算自注意力，然后拼接结果。 |
| Positional Encoding | 位置编码 | 为Transformer模型提供输入序列中token顺序信息的机制。 |
| Relative Positional Encoding | 相对位置编码 | 一种位置编码方法，将相对位置信息整合到注意力计算中，而非绝对位置。 |
| Rotary Position Embedding (RoPE) | 旋转位置嵌入 | 一种使用旋转矩阵编码绝对位置，并在注意力层注入相对位置信息的位置编码方法。 |
| Transformer-XL | Transformer-XL | 通过重用前一个片段的隐藏状态来扩展注意力范围，支持更长上下文的Transformer变体。 |
| Compressive Transformer | 压缩式Transformer | 通过压缩过去的记忆来扩展Transformer-XL，以支持更长序列。 |
| kNN-LM | kNN语言模型 | 通过线性插值预训练语言模型预测和外部键值存储中k近邻模型的预测来增强语言模型。 |
| Adaptive Attention Span | 自适应注意力跨度 | 一种自注意力机制，允许每个注意力头根据需要灵活调整其关注范围。 |
| Sparse Attention Patterns | 稀疏注意力模式 | 通过限制每个token的注意力范围来降低自注意力计算和内存成本的方法。 |
| Locality Sensitive Hashing (LSH) Attention | 局部敏感哈希注意力 | Reformer中用于替换点积注意力的方法，通过哈希将复杂度从二次方降低到对数线性。 |
| Reversible Residual Layer | 可逆残差层 | 一种残差网络设计，允许在反向传播期间从下一层激活中恢复当前层激活，从而节省内存。 |
| Decision Transformer (DT) | 决策Transformer | 将强化学习问题表述为条件序列建模过程，输出基于期望回报、过去状态和动作的条件最优动作。 |
