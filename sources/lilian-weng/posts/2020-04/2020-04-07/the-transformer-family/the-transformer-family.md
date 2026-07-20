# Transformer 家族

> The Transformer Family

> 来源：Lil'Log / Lilian Weng，2020-04-07
> 原文链接：https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/
> 分类：人工智能 / Transformer模型

## 核心要点

- Transformer模型通过编码器-解码器架构、多头自注意力机制和位置编码处理序列数据。
- 自注意力机制是Transformer的核心，它通过缩放点积计算查询与键之间的权重，并对值进行加权求和。
- Transformer-XL通过重用前一段落的隐藏状态和引入相对位置编码，有效解决了固定长度上下文的限制，扩展了注意力范围。
- 稀疏Transformer和Reformer等变体旨在优化计算和内存效率，分别通过稀疏注意力矩阵分解和局部敏感哈希注意力将复杂度从二次方降低。
- Reformer模型还引入了可逆残差层，以在反向传播过程中重新计算激活值而非存储，从而显著节省内存。
- 通用Transformer结合了自注意力与循环机制，并利用自适应计算时间动态调整计算步数，以实现更灵活的序列处理。
- Image Transformer将自注意力机制应用于图像处理，通过一维或二维局部注意力跨度来适应图像数据的特性。
- Gated Transformer-XL (GTrXL) 通过改进层归一化和引入GRU风格的门控机制，成功稳定了Transformer在强化学习任务中的训练。

## 正文

[更新于 **2023-01-27**: 时隔近三年，我对这篇博文进行了大规模重构更新，以纳入自 2020 年以来出现的一系列新的 Transformer 模型。这篇博文的增强版在此：[Transformer 家族 2.0 版](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/)。请参考该博文了解此主题。]
  


> [Updated on **2023-01-27**: After almost three years, I did a big refactoring update of this post to incorporate a bunch of new Transformer models since 2020. The enhanced version of this post is here: [The Transformer Family Version 2.0](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/). Please refer to that post on this topic.]
>

距离我上一篇关于[注意力机制](https://lilianweng.github.io/posts/2018-06-24-attention/)的博文已经过去了近两年。Transformer 新版本和增强版本的最新进展促使我撰写另一篇关于此特定主题的博文，重点关注如何改进原始 Transformer，以实现更长的注意力跨度、更少的内存和计算消耗、解决强化学习任务等。

> It has been almost two years since my last post on [attention](https://lilianweng.github.io/posts/2018-06-24-attention/). Recent progress on new and enhanced versions of Transformer motivates me to write another post on this specific topic, focusing on how the vanilla Transformer can be improved for longer-term attention span, less memory and computation consumption, RL task solving and more.

#### 符号表示

> Notations

| 符号 | 含义 |
| --- | --- |
| $d$ | 模型大小 / 隐藏状态维度 / 位置编码大小。 |
| $h$ | 多头注意力层中的头数。 |
| $L$ | 输入序列的段长度。 |
| $\mathbf{X} \in \mathbb{R}^{L \times d}$ | 输入序列，其中每个元素都已映射为形状为 $d$ 的嵌入向量，与模型大小相同。 |
| $\mathbf{W}^k \in \mathbb{R}^{d \times d_k}$ | 键权重矩阵。 |
| $\mathbf{W}^q \in \mathbb{R}^{d \times d_k}$ | 查询权重矩阵。 |
| $\mathbf{W}^v \in \mathbb{R}^{d \times d_v}$ | 值权重矩阵。通常我们有 $d_k = d_v = d$。 |
| $\mathbf{W}^k_i, \mathbf{W}^q_i \in \mathbb{R}^{d \times d_k/h}; \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$ | 每个头的权重矩阵。 |
| $\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$ | 输出权重矩阵。 |
| $\mathbf{Q} = \mathbf{X}\mathbf{W}^q \in \mathbb{R}^{L \times d_k}$ | 查询嵌入输入。 |
| $\mathbf{K} = \mathbf{X}\mathbf{W}^k \in \mathbb{R}^{L \times d_k}$ | 键嵌入输入。 |
| $\mathbf{V} = \mathbf{X}\mathbf{W}^v \in \mathbb{R}^{L \times d_v}$ | 值嵌入输入。 |
| $S_i$ | 第 $i$ 个查询 $\mathbf{q}_i$ 需要关注的键位置集合。 |
| $\mathbf{A} \in \mathbb{R}^{L \times L}$ | 长度为 $L$ 的输入序列与其自身的自注意力矩阵。$\mathbf{A} = \text{softmax}(\mathbf{Q}\mathbf{K}^\top / \sqrt{d_k})$。 |
| $a_{ij} \in \mathbf{A}$ | 查询 $\mathbf{q}_i$ 和键 $\mathbf{k}_j$ 之间的标量注意力分数。 |
| $\mathbf{P} \in \mathbb{R}^{L \times d}$ | 位置编码矩阵，其中第 $i$ 行 $\mathbf{p}_i$ 是输入 $\mathbf{x}_i$ 的位置编码。 |

> 英文原表 / English original

| Symbol | Meaning |
| --- | --- |
| $d$ | The model size / hidden state dimension / positional encoding size. |
| $h$ | The number of heads in multi-head attention layer. |
| $L$ | The segment length of input sequence. |
| $\mathbf{X} \in \mathbb{R}^{L \times d}$ | The input sequence where each element has been mapped into an embedding vector of shape $d$, same as the model size. |
| $\mathbf{W}^k \in \mathbb{R}^{d \times d_k}$ | The key weight matrix. |
| $\mathbf{W}^q \in \mathbb{R}^{d \times d_k}$ | The query weight matrix. |
| $\mathbf{W}^v \in \mathbb{R}^{d \times d_v}$ | The value weight matrix. Often we have $d_k = d_v = d$. |
| $\mathbf{W}^k_i, \mathbf{W}^q_i \in \mathbb{R}^{d \times d_k/h}; \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$ | The weight matrices per head. |
| $\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$ | The output weight matrix. |
| $\mathbf{Q} = \mathbf{X}\mathbf{W}^q \in \mathbb{R}^{L \times d_k}$ | The query embedding inputs. |
| $\mathbf{K} = \mathbf{X}\mathbf{W}^k \in \mathbb{R}^{L \times d_k}$ | The key embedding inputs. |
| $\mathbf{V} = \mathbf{X}\mathbf{W}^v \in \mathbb{R}^{L \times d_v}$ | The value embedding inputs. |
| $S_i$ | A collection of key positions for the $i$-th query $\mathbf{q}_i$ to attend to. |
| $\mathbf{A} \in \mathbb{R}^{L \times L}$ | The self-attention matrix between a input sequence of length $L$ and itself. $\mathbf{A} = \text{softmax}(\mathbf{Q}\mathbf{K}^\top / \sqrt{d_k})$. |
| $a_{ij} \in \mathbf{A}$ | The scalar attention score between query $\mathbf{q}_i$ and key $\mathbf{k}_j$. |
| $\mathbf{P} \in \mathbb{R}^{L \times d}$ | position encoding matrix, where the $i$-th row $\mathbf{p}_i$ is the positional encoding for input $\mathbf{x}_i$. |

### 注意力与自注意力

> Attention and Self-Attention

*注意力*是神经网络中的一种机制，模型可以通过选择性地关注给定数据集来学习进行预测。注意力的量通过学习到的权重来量化，因此输出通常以加权平均的形式形成。

> *Attention* is a mechanism in the neural network that a model can learn to make predictions by selectively attending to a given set of data. The amount of attention is quantified by learned weights and thus the output is usually formed as a weighted average.

*自注意力*是一种注意力机制，模型利用同一数据样本中其他部分的观测来预测该样本的一部分。从概念上讲，它与[非局部均值](https://en.wikipedia.org/wiki/Non-local_means)非常相似。另请注意，自注意力是置换不变的；换句话说，它是一种集合上的操作。

> *Self-attention* is a type of attention mechanism where the model makes prediction for one part of a data sample using other parts of the observation about the same sample. Conceptually, it feels quite similar to [non-local means](https://en.wikipedia.org/wiki/Non-local_means). Also note that self-attention is permutation-invariant; in other words, it is an operation on sets.

注意力/自注意力有多种形式，Transformer（[Vaswani 等人，2017](https://arxiv.org/abs/1706.03762)）依赖于*缩放点积注意力*：给定一个查询矩阵$\mathbf{Q}$、一个键矩阵$\mathbf{K}$和一个值矩阵$\mathbf{V}$，输出是值向量的加权和，其中分配给每个值槽的权重由查询与相应键的点积决定：

> There are various forms of attention / self-attention, Transformer ([Vaswani et al., 2017](https://arxiv.org/abs/1706.03762)) relies on the *scaled dot-product attention*: given a query matrix $\mathbf{Q}$, a key matrix $\mathbf{K}$ and a value matrix $\mathbf{V}$, the output is a weighted sum of the value vectors, where the weight assigned to each value slot is determined by the dot-product of the query with the corresponding key:

$$
\text{Attention}(\mathbf{Q}, \mathbf{K}, \mathbf{V}) = \text{softmax}(\frac{\mathbf{Q} {\mathbf{K}}^\top}{\sqrt{d_k}})\mathbf{V}
$$

对于查询向量和键向量$\mathbf{q}_i, \mathbf{k}_j \in \mathbb{R}^d$（查询矩阵和键矩阵中的行向量），我们有一个标量分数：

> And for a query and a key vector $\mathbf{q}_i, \mathbf{k}_j \in \mathbb{R}^d$ (row vectors in query and key matrices), we have a scalar score:

$$
a_{ij} = \text{softmax}(\frac{\mathbf{q}_i {\mathbf{k}_j}^\top}{\sqrt{d_k}})
= \frac{\exp(\mathbf{q}_i {\mathbf{k}_j}^\top)}{ \sqrt{d_k} \sum_{r \in S_i} \exp(\mathbf{q}_i {\mathbf{k}_r}^\top) }
$$

如果感兴趣，请参阅我之前的[文章](https://lilianweng.github.io/posts/2018-06-24-attention/#a-family-of-attention-mechanisms)，了解其他类型的注意力。

> See my old [post](https://lilianweng.github.io/posts/2018-06-24-attention/#a-family-of-attention-mechanisms) for other types of attention if interested.

### 多头自注意力

> Multi-Head Self-Attention

*多头自注意力*模块是 Transformer 中的一个关键组件。多头机制不是只计算一次注意力，而是将输入分成更小的块，然后并行地在每个子空间上计算缩放点积注意力。独立的注意力输出被简单地拼接并线性变换到预期的维度。

> The *multi-head self-attention* module is a key component in Transformer. Rather than only computing the attention once, the multi-head mechanism splits the inputs into smaller chunks and then computes the scaled dot-product attention over each subspace in parallel. The independent attention outputs are simply concatenated and linearly transformed into expected dimensions.

$$
\begin{aligned}
\text{MultiHeadAttention}(\mathbf{X}_q, \mathbf{X}_k, \mathbf{X}_v) &= [\text{head}_1; \dots; \text{head}_h] \mathbf{W}^o \\ 
\text{where head}_i &= \text{Attention}(\mathbf{X}_q\mathbf{W}^q_i, \mathbf{X}_k\mathbf{W}^k_i, \mathbf{X}_v\mathbf{W}^v_i)
\end{aligned}
$$

其中$[.;.]$是拼接操作。$\mathbf{W}^q_i, \mathbf{W}^k_i \in \mathbb{R}^{d \times d_k/h}, \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$是权重矩阵，用于将大小为$L \times d$的输入嵌入映射到查询、键和值矩阵。而$\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$是输出线性变换。所有权重都应在训练期间学习。

> where $[.;.]$ is a concatenation operation. $\mathbf{W}^q_i, \mathbf{W}^k_i \in \mathbb{R}^{d \times d_k/h}, \mathbf{W}^v_i \in \mathbb{R}^{d \times d_v/h}$ are weight matrices to map input embeddings of size $L \times d$ into query, key and value matrices. And $\mathbf{W}^o \in \mathbb{R}^{d_v \times d}$ is the output linear transformation. All the weights should be learned during training.

![Illustration of the multi-head scaled dot-product attention mechanism. (Image source: Figure 2 in Vaswani, et al., 2017 )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/multi-head-attention.png)

### Transformer

> Transformer

**Transformer** 模型（为区别于其他增强版本，此处称为“香草Transformer”；[Vaswani 等人，2017](https://arxiv.org/abs/1706.03762)）具有编码器-解码器架构，这在许多[NMT](https://lilianweng.github.io/posts/2018-06-24-attention/#born-for-translation)模型中很常见。后来，简化的Transformer被证明在语言建模任务中取得了出色的性能，例如仅编码器的[BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert)或仅解码器的[GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#openai-gpt)。

> The **Transformer** (which will be referred to as “vanilla Transformer” to distinguish it from other enhanced versions; [Vaswani, et al., 2017](https://arxiv.org/abs/1706.03762)) model has an encoder-decoder architecture, as commonly used in many [NMT](https://lilianweng.github.io/posts/2018-06-24-attention/#born-for-translation) models. Later simplified Transformer was shown to achieve great performance in language modeling tasks, like in encoder-only [BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert) or decoder-only [GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#openai-gpt).

**编码器-解码器架构**

> **Encoder-Decoder Architecture**

 **编码器**生成一种基于注意力的表示，能够从大型上下文中定位特定信息。它由6个恒等模块堆叠而成，每个模块包含两个子模块：一个*多头自注意力*层和一个*逐点*全连接前馈网络。逐点意味着它对序列中的每个元素应用相同的线性变换（使用相同的权重）。这也可以看作是一个滤波器大小为1的卷积层。每个子模块都有一个残差连接和层归一化。所有子模块输出相同维度的数据`d`。

英文原文：The encoder generates an attention-based representation with capability to locate a specific piece of information from a large context. It consists of a stack of 6 identity modules, each containing two submodules, a *multi-head self-attention* layer and a *point-wise* fully connected feed-forward network. By point-wise, it means that it applies the same linear transformation (with same weights) to each element in the sequence. This can also be viewed as a convolutional layer with filter size 1. Each submodule has a residual connection and layer normalization. All the submodules output data of the same dimension `d`.

Transformer **解码器**的功能是从编码表示中检索信息。其架构与编码器非常相似，不同之处在于解码器在每个相同的重复模块中包含两个多头注意力子模块，而不是一个。第一个多头注意力子模块被*掩码*，以防止位置关注未来。

> The function of Transformer **decoder** is to retrieve information from the encoded representation. The architecture is quite similar to the encoder, except that the decoder contains two multi-head attention submodules instead of one in each identical repeating module. The first multi-head attention submodule is *masked* to prevent positions from attending to the future.

![The architecture of the vanilla Transformer model. (Image source: Figure 17 )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/transformer.png)

**位置编码**

> **Positional Encoding**

由于自注意力操作是置换不变的，因此使用适当的**位置编码**来为模型提供*顺序信息*非常重要。位置编码$\mathbf{P} \in \mathbb{R}^{L \times d}$与输入嵌入具有相同的维度，因此可以直接添加到输入中。原始Transformer考虑了两种类型的编码：

英文原文：Because self-attention operation is permutation invariant, it is important to use proper positional encodingto provide *order information* to the model. The positional encoding 

$\mathbf{P} \in \mathbb{R}^{L \times d}$ has the same dimension as the input embedding, so it can be added on the input directly. The vanilla Transformer considered two types of encodings:

(1) *正弦位置编码*定义如下，给定token位置$i=1,\dots,L$和维度$\delta=1,\dots,d$：

> (1) *Sinusoidal positional encoding* is defined as follows, given the token position $i=1,\dots,L$ and the dimension $\delta=1,\dots,d$:

$$
\text{PE}(i,\delta) = 
\begin{cases}
\sin(\frac{i}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta'\\
\cos(\frac{i}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta' + 1\\
\end{cases}
$$

通过这种方式，位置编码的每个维度都对应于不同维度中不同波长的正弦曲线，从$2\pi$到$10000 \cdot 2\pi$。

> In this way each dimension of the positional encoding corresponds to a sinusoid of different wavelengths in different dimensions, from $2\pi$ to $10000 \cdot 2\pi$.

![Sinusoidal positional encoding with $L=32$ and $d=128$. The value is between -1 (black) and 1 (white) and the value 0 is in gray.](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/sinoidual-positional-encoding.png)

(2) *学习到的位置编码*，顾名思义，为每个元素分配一个学习到的列向量，该向量编码其*绝对*位置（[Gehring, et al. 2017](https://arxiv.org/abs/1705.03122)）。

> (2) *Learned positional encoding*, as its name suggested, assigns each element with a learned column vector which encodes its *absolute* position ([Gehring, et al. 2017](https://arxiv.org/abs/1705.03122)).

**快速跟进**

> **Quick Follow-ups**

在原始Transformer之后，[Al-Rfou et al. (2018)](https://arxiv.org/abs/1808.04444)添加了一组辅助损失，以实现在字符级语言建模上训练深度Transformer模型，其性能优于LSTMs。使用了几种类型的辅助任务：

> Following the vanilla Transformer, [Al-Rfou et al. (2018)](https://arxiv.org/abs/1808.04444) added a set of auxiliary losses to enable training a deep Transformer model on character-level language modeling which outperformed LSTMs. Several types of auxiliary tasks are used:

- 模型不再只在序列末尾生成一个预测，而是要求每个*即时位置*也做出正确预测，这迫使模型在给定较小上下文（例如，上下文窗口开头的最初几个token）的情况下进行预测。
- 每个中间Transformer层也用于进行预测。随着训练的进行，较低层被赋予的权重越来越小，对总损失的贡献也越来越少。
- 序列中的每个位置可以预测多个目标，即对未来token进行两次或更多次预测。

> • Instead of producing only one prediction at the sequence end, every *immediate position* is also asked to make a correct prediction, forcing the model to predict given smaller contexts (e.g. first couple tokens at the beginning of a context window).
> • Each intermediate Transformer layer is used for making predictions as well. Lower layers are weighted to contribute less and less to the total loss as training progresses.
> • Each position in the sequence can predict multiple targets, i.e. two or more predictions of the future tokens.

![Auxiliary prediction tasks used in deep Transformer for character-level language modeling. (Image source: Al-Rfou et al. (2018) )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/transformer-aux-losses.png)

### 自适应计算时间 (ACT)

> Adaptive Computation Time (ACT)

**自适应计算时间**（简称 **ACT**；[Graves, 2016](https://arxiv.org/abs/1603.08983)）是一种动态决定循环神经网络中所需计算步数的机制。这里有一个来自 distill.pub 的关于 ACT 的很棒的[教程](https://distill.pub/2016/augmented-rnns/#adaptive-computation-time)。

> **Adaptive Computation Time** (short for **ACT**; [Graves, 2016](https://arxiv.org/abs/1603.08983)) is a mechanism for dynamically deciding how many computational steps are needed in a recurrent neural network. Here is a cool [tutorial](https://distill.pub/2016/augmented-rnns/#adaptive-computation-time) on ACT from distill.pub.

假设我们有一个 RNN 模型 $\mathcal{R}$，它由输入权重 $W_x$、一个参数化状态转移函数 $\mathcal{S}(.)$、一组输出权重 $W_y$ 和一个输出偏置 $b_y$ 组成。给定一个输入序列 $(x_1, \dots, x_L)$，输出序列 $(y_1, \dots, y_L)$ 通过以下方式计算：

> Let’s say, we have a RNN model $\mathcal{R}$ composed of input weights $W_x$, a parametric state transition function $\mathcal{S}(.)$, a set of output weights $W_y$ and an output bias $b_y$. Given an input sequence $(x_1, \dots, x_L)$, the output sequence $(y_1, \dots, y_L)$ is computed by:

$$
s_t = \mathcal{S}(s_{t-1}, W_x x_t), \quad y_t = W_y s_t + b_y\quad\text{for }t=1, \dots, L
$$

ACT 使上述 RNN 设置能够在每个输入元素上执行可变数量的步骤。多个计算步骤会产生一系列中间状态 $(s_t^1, \dots, s_t^{N(t)})$ 和输出 $(y_t^1, \dots, y_t^{N(t)})$ —— 它们都共享相同的状态转移函数 $\mathcal{S}(.)$，以及相同的输出权重 $W_y$ 和偏置 $b_y$：

> ACT enables the above RNN setup to perform a variable number of steps at each input element. Multiple computational steps lead to a sequence of intermediate states $(s_t^1, \dots, s_t^{N(t)})$ and outputs $(y_t^1, \dots, y_t^{N(t)})$ — they all share the same state transition function $\mathcal{S}(.)$, as well as the same output weights $W_y$ and bias $b_y$:

$$
\begin{aligned}
s_t^0 &= s_{t-1} \\
s_t^n &= \mathcal{S}(s_{t}^{n-1}, x_t^n) = \mathcal{S}(s_{t}^{n-1}, x_t + \delta_{n,1}) \text{ for } n=1, \dots, N(t)\\
y_t^n &= W_y s_t^n + b_y
\end{aligned}
$$

其中 $\delta_{n,1}$ 是一个二进制标志，指示输入步骤是否已递增。

> where $\delta_{n,1}$ is a binary flag indicating whether the input step has been incremented.

步数$N(t)$由一个额外的S形停止单元决定$h$，以及相关的权重矩阵$W_h$和偏置$b_h$，输出一个停止概率$p_t^n$在即时步$n$对于$t$个输入元素：

> The number of steps $N(t)$ is determined by an extra sigmoidal halting unit $h$, with associated weight matrix $W_h$ and bias $b_h$, outputting a halting probability $p_t^n$ at immediate step $n$ for $t$ -th input element:

$$
h_t^n = \sigma(W_h s_t^n + b_h)
$$

为了让计算在单步后停止，ACT引入了一个小常数$\epsilon$（例如0.01），这样每当累积概率超过$1-\epsilon$时，计算就会停止。

> In order to allow the computation to halt after a single step, ACT introduces a small constant $\epsilon$ (e.g. 0.01), so that whenever the cumulative probability goes above $1-\epsilon$, the computation stops.

$$
\begin{aligned}
N(t) &= \min(\min\{n': \sum_{n=1}^{n'} h_t^n \geq 1 -\epsilon\}, M) \\
p_t^n &= \begin{cases}
h_t^n & \text{if }n < N(t) \\
R(t) = 1 - \sum_{n=1}^{N(t)-1} h_t^n & \text{if }n= N(t)\\
\end{cases}
\end{aligned}
$$

其中$M$是允许的即时步数的上限。

> where $M$ is an upper limit for the number of immediate steps allowed.

最终状态和输出是平均场更新：

> The final state and output are mean-field updates:

$$
s_t = \sum_{n=1}^{N(t)} p_t^n s_t^n,\quad y_t = \sum_{n=1}^{N(t)} p_t^n y_t^n
$$

![The computation graph of a RNN with ACT mechanism. (Image source: Graves, 2016 )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/ACT-computation-graph.png)

为了避免对每个输入进行不必要的思考，ACT在损失函数中添加了一个*思考成本*$\mathcal{P}(x) = \sum_{t=1}^L N(t) + R(t)$，以鼓励更少的中间计算步骤。

> To avoid unnecessary pondering over each input, ACT adds a *ponder cost* $\mathcal{P}(x) = \sum_{t=1}^L N(t) + R(t)$  in the loss function to encourage a smaller number of intermediate computational steps.

### 改进的注意力范围

> Improved Attention Span

改进注意力范围的目标是使自注意力中可用的上下文更长、更高效、更灵活。

> The goal of improving attention span is to make the context that can be used in self-attention longer, more efficient and flexible.

#### 更长的注意力范围（Transformer-XL）

> Longer Attention Span (Transformer-XL)

普通的Transformer具有固定且有限的注意力范围。模型在每个更新步骤中只能关注同一段落中的其他元素，并且信息无法在分离的固定长度段落之间流动。

> The vanilla Transformer has a fixed and limited attention span. The model can only attend to other elements in the same segments during each update step and no information can flow across separated fixed-length segments.

这种*上下文分段*导致了几个问题：

> This *context segmentation* causes several issues:

- 模型无法捕获非常长期的依赖关系。
- 在没有或只有少量上下文的情况下，很难预测每个段落中的前几个token。
- 评估成本很高。每当段落向右移动一个位置时，新段落都会从头开始重新处理，尽管存在大量重叠的token。

> • The model cannot capture very long term dependencies.
> • It is hard to predict the first few tokens in each segment given no or thin context.
> • The evaluation is expensive. Whenever the segment is shifted  to the right by one, the new segment is re-processed from scratch, although there are a lot of overlapped tokens.

**Transformer-XL**（[Dai et al., 2019](https://arxiv.org/abs/1901.02860)；“XL”意为“超长”）通过两项主要修改解决了上下文分段问题：

> **Transformer-XL** ([Dai et al., 2019](https://arxiv.org/abs/1901.02860); “XL” means “extra long”) solves the context segmentation problem with two main modifications:

1. 在段落之间重用隐藏状态。
2. 采用适用于重用状态的新型位置编码。

> • Reusing hidden states between segments.
> • Adopting a new positional encoding that is suitable for reused states.

**隐藏状态重用**

> **Hidden State Reuse**

通过持续使用前一段落的隐藏状态，模型中引入了段落之间的循环连接。

> The recurrent connection between segments is introduced into the model by continuously using the hidden states from the previous segments.

![A comparison between the training phrase of vanilla Transformer & Transformer-XL with a segment length 4. (Image source: left part of Figure 2 in Dai et al., 2019 ).](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/transformer-XL-training.png)

我们将模型中第$n$层的第$(\tau + 1)$段的隐藏状态标记为$\mathbf{h}_{\tau+1}^{(n)} \in \mathbb{R}^{L \times d}$。除了同一段落的最后一层隐藏状态$\mathbf{h}_{\tau+1}^{(n-1)}$之外，它还依赖于前一段落的同一层隐藏状态$\mathbf{h}_{\tau}^{(n)}$。通过整合来自先前隐藏状态的信息，模型将注意力范围在过去大大延长，跨越多个段落。

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

请注意，key和value都依赖于扩展的隐藏状态，而query只消耗当前步骤的隐藏状态。拼接操作$[. \circ .]$是沿着序列长度维度进行的。

> Note that both key and value rely on the extended hidden state, while the query only consumes hidden state at current step. The concatenation operation $[. \circ .]$ is along the sequence length dimension.

**相对位置编码**

> **Relative Positional Encoding**

为了处理这种新的注意力跨度形式，Transformer-XL 提出了一种新型的位置编码。如果使用普通 Transformer 的相同方法并编码绝对位置，则前一个和当前片段将被分配相同的编码，这是不希望的。

> In order to work with this new form of attention span, Transformer-XL proposed a new type of positional encoding. If using the same approach by vanilla Transformer and encoding the absolute position, the previous and current segments will be assigned with the same encoding, which is undesired.

为了使位置信息在片段之间连贯地流动，Transformer-XL 转而编码*相对*位置，因为知道位置偏移量足以做出良好的预测，即 $i-j$，在一个键向量 $\mathbf{k}_{\tau, j}$ 及其查询 $\mathbf{q}_{\tau, i}$ 之间。

> To keep the positional information flow coherently across segments, Transformer-XL encodes the *relative* position instead, as it could be sufficient enough to know the position offset for making good predictions, i.e. $i-j$, between one key vector $\mathbf{k}_{\tau, j}$ and its query $\mathbf{q}_{\tau, i}$.

如果省略标量 $1/\sqrt{d_k}$ 和 softmax 中的归一化项，但包含位置编码，我们可以将位置 $i$ 处的查询与位置 $j$ 处的键之间的注意力分数写为：

> If omitting the scalar $1/\sqrt{d_k}$ and the normalizing term in softmax but including positional encodings, we can write the attention score between query at position $i$ and key at position $j$ as:

$$
\begin{aligned}
a_{ij} 
&= \mathbf{q}_i {\mathbf{k}_j}^\top = (\mathbf{x}_i + \mathbf{p}_i)\mathbf{W}^q ((\mathbf{x}_j + \mathbf{p}_j)\mathbf{W}^k)^\top \\
&= \mathbf{x}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{x}_j^\top + \mathbf{x}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{p}_j^\top + \mathbf{p}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{x}_j^\top + \mathbf{p}_i\mathbf{W}^q {\mathbf{W}^k}^\top\mathbf{p}_j^\top
\end{aligned}
$$

Transformer-XL 将上述四项重新参数化如下：

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

#### 自适应注意力跨度

> Adaptive Attention Span

Transformer 的一个关键优势是能够捕获长期依赖关系。根据上下文，模型有时可能更倾向于关注更远的地方；或者一个注意力头可能与另一个有不同的注意力模式。如果注意力跨度能够灵活地调整其长度，并且只在需要时才向后关注更远，这将有助于减少计算和内存成本，从而支持模型中更长的最大上下文大小。

> One key advantage of Transformer is the capability of capturing long-term dependencies. Depending on the context, the model may prefer to attend further sometime than others; or one attention head may had different attention pattern from the other. If the attention span could adapt its length flexibly and only attend further back when needed, it would help reduce both computation and memory cost to support longer maximum context size in the model.

这就是**自适应注意力跨度**的动机。[Sukhbaatar 等人 (2019)](https://arxiv.org/abs/1905.07799) 提出了一种自注意力机制，旨在寻找最佳注意力跨度。他们假设不同的注意力头在相同的上下文窗口内可能会以不同的方式分配分数（参见图 7），因此最佳跨度将为每个头单独训练。

> This is the motivation for **Adaptive Attention Span**. [Sukhbaatar, et al., (2019)](https://arxiv.org/abs/1905.07799) proposed a self-attention mechanism that seeks an optimal attention span. They hypothesized that different attention heads might assign scores differently within the same context window (See Fig. 7) and thus the optimal span would be trained separately per head.

![Two attention heads in the same model, A & B, assign attention differently within the same context window. Head A attends more to the recent tokens, while head B look further back into the past uniformly. (Image source: Sukhbaatar, et al. 2019 )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/attention-per-head.png)

给定第 $i$ 个 token，我们需要计算该 token 与位置 $j \in S_i$ 处的其他键之间的注意力权重，其中 $S_i$ 定义了第 $i$ 个 token 的上下文窗口。

> Given the $i$ -th token, we need to compute the attention weights between this token and other keys at positions $j \in S_i$, where $S_i$ defineds the $i$ -th token’s context window.

$$
\begin{aligned}
e_{ij} &= \mathbf{q}_i {\mathbf{k}_j}^\top \\ 
a_{ij} &= \text{softmax}(e_{ij}) = \frac{\exp(e_{ij})}{\sum_{r=i-s}^{i-1} \exp(e_{ir})} \\
\mathbf{y}_i &= \sum_{r=i-s}^{i-1}a_{ir}\mathbf{v}_r = \sum_{r=i-s}^{i-1}a_{ir}\mathbf{x}_r\mathbf{W}^v
\end{aligned}
$$

添加了一个*软掩码函数* $m_z$ 来控制有效的可调注意力跨度，它将查询和键之间的距离映射到 [0, 1] 值。$m_z$ 由 $z \in [0, s]$ 参数化，$z$ 待学习：

> A *soft mask function* $m_z$ is added to control for an effective adjustable attention span, which maps the distance between query and key into a [0, 1] value. $m_z$ is parameterized by $z \in [0, s]$ and $z$ is to be learned:

$$
m_z(x) = \text{clamp}(\frac{1}{R}(R+z-x), 0, 1)
$$

其中 $R$ 是一个超参数，它定义了 $m_z$ 的柔和度。

> where $R$ is a hyper-parameter which defines the softness of $m_z$.

![The soft masking function used in the adaptive attention span. (Image source: Sukhbaatar, et al. 2019 .)](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/soft-masking-function.png)

软掩码函数应用于注意力权重中的 softmax 元素：

> The soft mask function is applied to the softmax elements in the attention weights:

$$
a_{ij} = \frac{m_z(i-j)\exp(s_{ij})}{\sum_{r=i-s}^{i-1}m_z(i-r) \exp(s_{ir})}
$$

在上述方程中，$z$ 是可微分的，因此它与模型的其他部分一起进行联合训练。参数 $z^{(i)}, i=1, \dots, h$ 是 *每个头单独学习* 的。此外，损失函数对 $\sum_{i=1}^h z^{(i)}$ 还有一个额外的 L1 惩罚。

> In the above equation, $z$ is differentiable so it is trained jointly with other parts of the model. Parameters $z^{(i)}, i=1, \dots, h$ are learned *separately per head*. Moreover, the loss function has an extra L1 penalty on $\sum_{i=1}^h z^{(i)}$.

利用[自适应计算时间](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act)，该方法可以进一步增强，使其具有灵活的注意力跨度长度，并能动态适应当前输入。注意力头的跨度参数$z_t$的注意力头在时间$t$是一个S形函数，$z_t = S \sigma(\mathbf{v} \cdot \mathbf{x}_t +b)$，其中向量$\mathbf{v}$和偏置标量$b$与其他参数一起学习。

> Using [Adaptive Computation Time](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act), the approach can be further enhanced to have flexible attention span length, adaptive to the current input dynamically. The span parameter $z_t$ of an attention head at time $t$ is a sigmoidal function, $z_t = S \sigma(\mathbf{v} \cdot \mathbf{x}_t +b)$, where the vector $\mathbf{v}$ and the bias scalar $b$ are learned jointly with other parameters.

在带有自适应注意力跨度的 Transformer 实验中，[Sukhbaatar 等人 (2019)](https://arxiv.org/abs/1905.07799) 发现了一个普遍趋势，即较低层不需要很长的注意力跨度，而较高层中的少数注意力头可能会使用异常长的跨度。自适应注意力跨度还有助于大幅减少 FLOPS 的数量，尤其是在具有许多注意力层和较大上下文长度的大型模型中。

> In the experiments of Transformer with adaptive attention span, [Sukhbaatar, et al. (2019)](https://arxiv.org/abs/1905.07799) found a general tendency that lower layers do not require very long attention spans, while a few attention heads in higher layers may use exceptionally long spans. Adaptive attention span also helps greatly reduce the number of FLOPS, especially in a big model with many attention layers and a large context length.

#### 局部注意力跨度 (图像 Transformer)

> Localized Attention Span (Image Transformer)

Transformer 最初也是最流行的用例是进行语言建模。文本序列是一维的，具有明确定义的时间顺序，因此注意力跨度随着上下文大小的增加而线性增长。

> The original, also the most popular, use case for Transformer is to do language modeling. The text sequence is one-dimensional in a clearly defined chronological order and thus the attention span grows linearly with increased context size.

然而，如果我们要将 Transformer 用于图像，则不清楚如何定义上下文范围或顺序。**Image Transformer** ([Parmer, et al 2018](https://arxiv.org/abs/1802.05751)) 在 Transformer 框架内采用了一种类似于序列建模的图像生成公式。此外，Image Transformer 将自注意力跨度限制在仅*局部*邻域，以便模型可以扩展以并行处理更多图像并保持似然损失可控。

> However, if we want to use Transformer on images, it is unclear how to define the scope of context or the order. **Image Transformer** ([Parmer, et al 2018](https://arxiv.org/abs/1802.05751)) embraces a formulation of image generation similar to sequence modeling within the Transformer framework. Additionally, Image Transformer restricts the self-attention span to only *local* neighborhoods, so that the model can scale up to process more images in parallel and keep the likelihood loss tractable.

编码器-解码器架构仍用于图像条件生成：

> The encoder-decoder architecture remains for image-conditioned generation:

- 编码器生成源图像的上下文化、逐像素通道表示；
- 解码器*自回归地*生成输出图像，在每个时间步生成每个像素的一个通道。

> • The encoder generates a contextualized, per-pixel-channel representation of the source image;
> • The decoder *autoregressively* generates an output image, one channel per pixel at each time step.

我们将当前要生成的像素的表示标记为查询 $\mathbf{q}$。其表示将用于计算 $\mathbf{q}$ 的其他位置是键向量 $\mathbf{k}_1, \mathbf{k}_2, \dots$，它们共同形成一个记忆矩阵 $\mathbf{M}$。$\mathbf{M}$ 的范围定义了像素查询 $\mathbf{q}$ 的上下文窗口。

> Let’s label the representation of the current pixel to be generated as the query $\mathbf{q}$. Other positions whose representations will be used for computing $\mathbf{q}$ are key vector $\mathbf{k}_1, \mathbf{k}_2, \dots$ and they together form a memory matrix $\mathbf{M}$. The scope of $\mathbf{M}$ defines the context window for pixel query $\mathbf{q}$.

Image Transformer 引入了两种类型的局部化 $\mathbf{M}$，如下所示。

> Image Transformer introduced two types of localized $\mathbf{M}$, as illustrated below.

![Illustration of 1D and 2D attention span for visual inputs in Image Transformer. The black line marks a query block and the cyan outlines the actual attention span for pixel q. (Image source: Figure 2 in Parmer et al, 2018 )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/image-transformer-attention.png)

(1) *一维局部注意力*：输入图像按 [光栅扫描](https://en.wikipedia.org/wiki/Raster_scan#Scanning_pattern) 顺序展平，即从左到右、从上到下。然后将线性化后的图像划分为不重叠的查询块。上下文窗口由与 $\mathbf{q}$ 位于同一查询块中的像素以及在该查询块之前生成的固定数量的额外像素组成。

> (1) *1D Local Attention*: The input image is flattened in the [raster scanning](https://en.wikipedia.org/wiki/Raster_scan#Scanning_pattern) order, that is, from left to right and top to bottom. The linearized image is then partitioned into non-overlapping query blocks. The context window consists of pixels in the same query block as $\mathbf{q}$ and a fixed number of additional pixels generated before this query block.

(2) *二维局部注意力*：图像被划分为多个不重叠的矩形查询块。查询像素可以关注同一内存块中的所有其他像素。为了确保左上角的像素也能拥有有效的上下文窗口，内存块分别向顶部、左侧和右侧扩展了固定量。

> (2) *2D Local Attention*: The image is partitioned into multiple non-overlapping rectangular query blocks. The query pixel can attend to all others in the same memory blocks. To make sure the pixel at the top-left corner can also have a valid context window, the memory block is extended to the top, left and right by a fixed amount, respectively.

### 更少的时间和内存成本

> Less Time and Memory Cost

本节介绍了对 Transformer 进行的几项改进，以减少计算时间和内存消耗。

> This section introduces several improvements made on Transformer to reduce the computation time and memory consumption.

#### 稀疏注意力矩阵分解（稀疏 Transformer）

> Sparse Attention Matrix Factorization (Sparse Transformers)

普通 Transformer 的计算和内存成本随序列长度呈二次方增长，因此很难应用于非常长的序列。

> The compute and memory cost of the vanilla Transformer grows quadratically with sequence length and thus it is hard to be applied on very long sequences.

**稀疏 Transformer** ([Child 等人，2019](https://arxiv.org/abs/1904.10509)) 通过稀疏矩阵分解引入了 *因子化自注意力*，使得在序列长度高达 16,384 的情况下训练具有数百层的密集注意力网络成为可能，否则这在现代硬件上是不可行的。

> **Sparse Transformer** ([Child et al., 2019](https://arxiv.org/abs/1904.10509)) introduced *factorized self-attention*, through sparse matrix factorization, making it possible to train dense attention networks with hundreds of layers on sequence length up to 16,384, which would be infeasible on modern hardware otherwise.

给定一组注意力连接模式 $\mathcal{S} = \{S_1, \dots, S_n\}$，其中每个 $S_i$ 记录了第 $i$ 个查询向量所关注的一组键位置。

> Given a set of attention connectivity pattern $\mathcal{S} = \{S_1, \dots, S_n\}$, where each $S_i$ records a set of key positions that the $i$ -th query vector attends to.

$$
\begin{aligned}
\text{Attend}(\mathbf{X}, \mathcal{S}) &= \Big( a(\mathbf{x}_i, S_i) \Big)_{i \in \{1, \dots, L\}} \\
\text{ where } a(\mathbf{x}_i, S_i) &= \text{softmax}\Big(\frac{(\mathbf{x}_i \mathbf{W}^q)(\mathbf{x}_j \mathbf{W}^k)_{j \in S_i}^\top}{\sqrt{d_k}}\Big) (\mathbf{x}_j \mathbf{W}^v)_{j \in S_i}
\end{aligned}
$$

请注意，尽管 $S_i$ 的大小不固定，但 $a(\mathbf{x}_i, S_i)$ 始终为 $d_v$ 大小，因此为 $\text{Attend}(\mathbf{X}, \mathcal{S}) \in \mathbb{R}^{L \times d_v}$。

> Note that although the size of $S_i$ is not fixed, $a(\mathbf{x}_i, S_i)$ is always of size $d_v$ and thus $\text{Attend}(\mathbf{X}, \mathcal{S}) \in \mathbb{R}^{L \times d_v}$.

在自回归模型中，一个注意力跨度定义为 $S_i = \{j: j \leq i\}$，因为它允许每个 token 关注过去的所有位置。

> In anto-regressive models, one attention span is defined as $S_i = \{j: j \leq i\}$ as it allows each token to attend to all the positions in the past.

在因子化自注意力中，集合 $S_i$ 被分解为依赖关系的 *树*，使得对于每一对 $(i, j)$（其中 $j \leq i$），都存在一条将 $i$ 连接回 $j$ 的路径，并且 $i$ 可以直接或间接地关注 $j$。

> In factorized self-attention, the set $S_i$ is decomposed into a *tree* of dependencies, such that for every pair of $(i, j)$ where $j \leq i$, there is a path connecting $i$ back to $j$ and $i$ can attend to $j$ either directly or indirectly.

具体来说，集合 $S_i$ 被划分为 $p$ 个 *不重叠* 的子集，其中第 $m$ 个子集表示为 $A^{(m)}_i \subset S_i, m = 1,\dots, p$。因此，输出位置 $i$ 与任何 $j$ 之间的路径最大长度为 $p + 1$。例如，如果 $(j, a, b, c, \dots, i)$ 是 $i$ 和 $j$ 之间的索引路径，我们将有 $j \in A_a^{(1)}, a \in A_b^{(2)}, b \in A_c^{(3)}, \dots$，依此类推。

> Precisely, the set $S_i$ is divided into $p$ *non-overlapping* subsets, where the $m$ -th subset is denoted as $A^{(m)}_i \subset S_i, m = 1,\dots, p$. Therefore the path between the output position $i$ and any $j$ has a maximum length $p + 1$. For example, if $(j, a, b, c, \dots, i)$ is a path of indices between $i$ and $j$, we would have $j \in A_a^{(1)}, a \in A_b^{(2)}, b \in A_c^{(3)}, \dots$, so on and so forth.

**稀疏分解注意力**

> **Sparse Factorized Attention**

稀疏Transformer提出了两种类型的分解注意力。如图10所示，以2D图像输入为例，更容易理解这些概念。

> Sparse Transformer proposed two types of fractorized attention. It is easier to understand the concepts as illustrated in Fig. 10 with 2D image inputs as examples.

![The top row illustrates the attention connectivity patterns in (a) Transformer, (b) Sparse Transformer with strided attention, and (c) Sparse Transformer with fixed attention. The bottom row contains corresponding self-attention connectivity matrices. Note that the top and bottom rows are not in the same scale. (Image source: Child et al., 2019 + a few of extra annotations.)](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/sparse-attention.png)

(1) *步幅*注意力，步幅为$\ell \sim \sqrt{n}$。这与图像数据配合良好，因为其结构与步幅对齐。在图像情况下，每个像素将关注光栅扫描顺序中所有前$\ell$个像素（自然覆盖图像的整个宽度），然后这些像素关注同一列中的其他像素（由另一个注意力连接子集定义）。

> (1) *Strided* attention with stride $\ell \sim \sqrt{n}$. This works well with image data as the structure is aligned with strides. In the image case, each pixel would attend to all the previous $\ell$ pixels in the raster scanning order (naturally cover the entire width of the image) and then those pixels attend to others in the same column (defined by another attention connectivity subset).

$$
\begin{aligned}
A_i^{(1)} &= \{ t, t+1, \dots, i\} \text{, where } t = \max(0, i - \ell) \\
A_i^{(2)} &= \{j: (i-j) \mod \ell = 0\}
\end{aligned}
$$

(2) *固定*注意力。一小组token总结先前的位置并将该信息传播到所有未来的位置。

> (2) *Fixed* attention. A small set of tokens summarize previous locations and propagate that information to all future locations.

$$
\begin{aligned}
A_i^{(1)} &= \{j: \lfloor \frac{j}{\ell} \rfloor = \lfloor \frac{i}{\ell} \rfloor \} \\
A_i^{(2)} &= \{j: j \mod \ell \in \{\ell-c, \dots, \ell-1\} \}
\end{aligned}
$$

其中$c$是一个超参数。如果$c=1$，它会限制表示，而许多表示依赖于少数位置。该论文选择$c\in \{ 8, 16, 32 \}$用于$\ell \in \{ 128, 256 \}$。

> where $c$ is a hyperparameter. If $c=1$, it restricts the representation whereas many depend on a few positions. The paper chose $c\in \{ 8, 16, 32 \}$ for $\ell \in \{ 128, 256 \}$.

**在Transformer中使用分解自注意力**

> **Use Factorized Self-Attention in Transformer**

在 Transformer 架构中使用稀疏分解注意力模式有三种方式：

> There are three ways to use sparse factorized attention patterns in Transformer architecture:

1\. 每个残差块使用一种注意力类型，然后交错它们，  

$\text{attention}(\mathbf{X}) = \text{Attend}(\mathbf{X}, A^{(n \mod p)}) \mathbf{W}^o$，其中 $n$ 是当前残差块的索引。

2\. 设置一个单一的注意力头，它关注所有分解注意力头关注的位置，  

$\text{attention}(\mathbf{X}) = \text{Attend}(\mathbf{X}, \cup_{m=1}^p A^{(m)}) \mathbf{W}^o$。

3\. 使用多头注意力机制，但与普通 Transformer 不同的是，每个头可能采用上述模式中的一种，即 1 或 2。=> 此选项通常表现最佳。

英文原文：

1\. One attention type per residual block and then interleave them,   

$\text{attention}(\mathbf{X}) = \text{Attend}(\mathbf{X}, A^{(n \mod p)}) \mathbf{W}^o$, where $n$ is the index of the current residual block.

2\. Set up a single head which attends to locations that all the factorized heads attend to,   

$\text{attention}(\mathbf{X}) = \text{Attend}(\mathbf{X}, \cup_{m=1}^p A^{(m)}) \mathbf{W}^o$.

3\. Use a multi-head attention mechanism, but different from vanilla Transformer, each head might adopt a pattern presented above, 1 or 2. => This option often performs the best.

稀疏 Transformer 还提出了一系列改进，以便将 Transformer 训练到数百层，包括梯度检查点、在反向传播过程中重新计算注意力层和 FF 层、混合精度训练、高效的块稀疏实现等。请查阅[论文](https://arxiv.org/abs/1904.10509)了解更多详情。

> Sparse Transformer also proposed a set of changes so as to train the Transformer up to hundreds of layers, including gradient checkpointing, recomputing attention & FF layers during the backward pass, mixed precision training, efficient block-sparse implementation, etc. Please check the [paper](https://arxiv.org/abs/1904.10509) for more details.

#### 局部敏感哈希 (Reformer)

> Locality-Sensitive Hashing (Reformer)

由**Reformer**模型（[Kitaev, et al. 2020](https://arxiv.org/abs/2001.04451)）提出的改进旨在解决Transformer中的以下痛点：

> The improvements proposed by the **Reformer** model ([Kitaev, et al. 2020](https://arxiv.org/abs/2001.04451)) aim to solve the following pain points in Transformer:

• 一个具有$N$层的模型，其内存是单层模型的$N$倍，因为我们需要存储激活值用于反向传播。

• 中间的FF层通常相当大。

• 长度为$L$的序列上的注意力矩阵通常在内存和时间上都需要$O(L^2)$。

英文原文：

• Memory in a model with $N$ layers is $N$ -times larger than in a single-layer model because we need to store activations for back-propagation.

• The intermediate FF layers are often quite large.

• The attention matrix on sequences of length $L$ often requires $O(L^2)$ in both memory and time.

Reformer提出了两项主要改变：

> Reformer proposed two main changes:

1\. 用*局部敏感哈希（LSH）注意力*取代点积注意力，将复杂度从$O(L^2)$降低到$O(L\log L)$。

2\. 用*可逆残差层*取代标准残差块，这使得在训练期间只需存储一次激活值，而不是$N$次（即与层数成比例）。

英文原文：

1\. Replace the dot-product attention with *locality-sensitive hashing (LSH) attention*, reducing the complexity from $O(L^2)$ to $O(L\log L)$.

2\. Replace the standard residual blocks with *reversible residual layers*, which allows storing activations only once during training instead of $N$ times (i.e. proportional to the number of layers).

**局部敏感哈希注意力**

> **Locality-Sensitive Hashing Attention**

在[注意力公式](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#attention-and-self-attention)的$\mathbf{Q} \mathbf{K}^\top$部分，我们只对最大的元素感兴趣，因为只有大的元素在softmax后贡献很大。对于每个查询$\mathbf{q}_i \in \mathbf{Q}$，我们正在寻找$\mathbf{K}$中最接近$\mathbf{q}_i$的行向量。为了在高维空间中快速找到最近邻，Reformer将[局部敏感哈希（LSH）](https://en.wikipedia.org/wiki/Locality-sensitive_hashing)融入其注意力机制。

> In $\mathbf{Q} \mathbf{K}^\top$ part of the [attention formula](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#attention-and-self-attention), we are only interested in the largest elements as only large elements contribute a lot after softmax. For each query $\mathbf{q}_i \in \mathbf{Q}$, we are looking for row vectors in $\mathbf{K}$ closest to $\mathbf{q}_i$. In order to find nearest neighbors quickly in high-dimensional space, Reformer incorporates [Locality-Sensitive Hashing (LSH)](https://en.wikipedia.org/wiki/Locality-sensitive_hashing) into its attention mechanism.

如果哈希方案$x \mapsto h(x)$能够保留数据点之间的距离信息，使得接近的向量获得相似的哈希值，而遥远的向量获得非常不同的哈希值，那么它就是*局部敏感的*。Reformer采用了一种这样的哈希方案，给定一个固定的随机矩阵$\mathbf{R} \in \mathbb{R}^{d \times b/2}$（其中$b$是一个超参数），哈希函数是$h(x) = \arg\max([xR; −xR])$。

> A hashing scheme $x \mapsto h(x)$ is *locality-sensitive* if it preserves the distancing information between data points, such that close vectors obtain similar hashes while distant vectors have very different ones. The Reformer adopts a hashing scheme as such, given a fixed random matrix $\mathbf{R} \in \mathbb{R}^{d \times b/2}$ (where $b$ is a hyperparam), the hash function is $h(x) = \arg\max([xR; −xR])$.

![Illustration of Locality-Sensitive Hashing (LSH) attention. (Image source: right part of Figure 1 in Kitaev, et al. 2020 ).](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/LSH-attention-matrix.png)

在LSH注意力中，查询只能关注同一哈希桶中的位置，$S_i = \{j: h(\mathbf{q}_i) = h(\mathbf{k}_j)\}$。其执行过程如下，如图11所示：

> In LSH attention, a query can only attend to positions in the same hashing bucket, $S_i = \{j: h(\mathbf{q}_i) = h(\mathbf{k}_j)\}$. It is carried out in the following process, as illustrated in Fig. 11:

• (a) 全注意力（full attention）的注意力矩阵通常是稀疏的。

• (b) 使用LSH，我们可以根据哈希桶对要对齐的键和查询进行排序。

• (c) 设置 $\mathbf{Q} = \mathbf{K}$ (精确地 $\mathbf{k}_j = \mathbf{q}_j / |\mathbf{q}_j|$)，以便在一个桶中键和查询的数量相等，这更容易进行批处理。有趣的是，这种“共享 QK”配置不影响 Transformer 的性能。

• (d) 应用批处理，其中将 $m$ 个连续查询块分组在一起。

英文原文：

• (a) The attention matrix for full attention is often sparse.

• (b) Using LSH, we can sort the keys and queries to be aligned according to their hash buckets.

• (c) Set $\mathbf{Q} = \mathbf{K}$ (precisely $\mathbf{k}_j = \mathbf{q}_j / |\mathbf{q}_j|$), so that there are equal numbers of keys and queries in one bucket, easier for batching. Interestingly, this “shared-QK” config does not affect the performance of the Transformer.

• (d) Apply batching where chunks of $m$ consecutive queries are grouped together.

![The LSH attention consists of 4 steps: bucketing, sorting, chunking, and attention computation. (Image source: left part of Figure 1 in Kitaev, et al. 2020 ).](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/LSH-attention.png)

**可逆残差网络**

> **Reversible Residual Network**

Reformer 的另一个改进是使用*可逆残差层* ([Gomez et al. 2017](https://arxiv.org/abs/1707.04585))。可逆残差网络的动机是以这样一种方式设计架构：在任何给定层的激活都可以仅使用模型参数从下一层的激活中恢复。因此，我们可以通过在反向传播期间重新计算激活而不是存储所有激活来节省内存。

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

Reformer 通过在一个可逆网络块中结合注意力 ($F$) 和前馈层 ($G$)，将相同的思想应用于 Transformer：

> Reformer applies the same idea to Transformer by combination attention ($F$) and feed-forward layers ($G$) within a reversible net block:

$$
Y_1 = X_1 + \text{Attention}(X_2), \; Y_2 = X_2 + \text{FeedForward}(Y_1)
$$

通过分块前馈计算可以进一步减少内存：

> The memory can be further reduced by chunking the feed-forward computation:

$$
Y_2 = [Y_2^{(1)}; \dots; Y_2^{(c)}] = [X_2^{(1)} + \text{FeedForward}(Y_1^{(1)}); \dots; X_2^{(c)} + \text{FeedForward}(Y_1^{(c)})]
$$

由此产生的可逆 Transformer 不需要在每一层存储激活。

> The resulting reversible Transformer does not need to store activation in every layer.

### 使其循环 (通用 Transformer)

> Make it Recurrent (Universal Transformer)

 **通用Transformer** ([Dehghani, et al. 2019](https://arxiv.org/abs/1807.03819)) 将Transformer中的自注意力机制与RNN中的循环机制相结合，旨在同时利用Transformer的长期全局感受野和RNN学习到的归纳偏置。

> The **Universal Transformer** ([Dehghani, et al. 2019](https://arxiv.org/abs/1807.03819)) combines self-attention in Transformer with the recurrent mechanism in RNN, aiming to benefit from both a long-term global receptive field of Transformer and learned inductive biases of RNN.

通用Transformer不是通过固定数量的层，而是使用[自适应计算时间](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act)动态调整步数。如果我们固定步数，通用Transformer就等同于一个层间参数共享的多层Transformer。

> Rather than going through a fixed number of layers, Universal Transformer dynamically adjusts the number of steps using [adaptive computation time](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act). If we fix the number of steps, an Universal Transformer is equivalent to a multi-layer Transformer with shared parameters across layers.

从宏观层面来看，通用Transformer可以被视为一个循环函数，用于学习每个token的隐藏状态表示。该循环函数在token位置之间并行演化，并且位置之间的信息通过自注意力机制共享。

> On a high level, the universal transformer can be viewed as a recurrent function for learning the hidden state representation per token. The recurrent function evolves in parallel across token positions and the information between positions is shared through self-attention.

![How the Universal Transformer refines a set of hidden state representations repeatedly for every position in parallel. (Image source: Figure 1 in Dehghani, et al. 2019 ).](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/universal-transformer-loop.png)

给定一个长度为$L$，Universal Transformer 迭代更新表示$\mathbf{H}^t \in \mathbb{R}^{L \times d}$在步骤$t$，步数可调。在步骤 0，$\mathbf{H}^0$被初始化为与输入嵌入矩阵相同。所有位置都在多头自注意力机制中并行处理，然后经过一个循环转换函数。

> Given an input sequence of length $L$, Universal Transformer iteratively updates the representation $\mathbf{H}^t \in \mathbb{R}^{L \times d}$ at step $t$ for an adjustable number of steps. At step 0, $\mathbf{H}^0$ is initialized to be same as the input embedding matrix. All the positions are processed in parallel in the multi-head self-attention mechanism and then go through a recurrent transition function.

$$
\begin{aligned}
\mathbf{A}^t &= \text{LayerNorm}(\mathbf{H}^{t-1} + \text{MultiHeadAttention}(\mathbf{H}^{t-1} + \mathbf{P}^t) \\
\mathbf{H}^t &= \text{LayerNorm}(\mathbf{A}^{t-1} + \text{Transition}(\mathbf{A}^t))
\end{aligned}
$$

其中 $\text{Transition}(.)$ 是 [可分离卷积](https://arxiv.org/abs/1610.02357) 或一个全连接神经网络，该网络由两个逐位置（即单独应用于 $\mathbf{A}^t$ 的每一行）仿射变换 + 一个 ReLU 组成。

> where $\text{Transition}(.)$ is either a [separable convolution](https://arxiv.org/abs/1610.02357) or a fully-connected neural network that consists of two position-wise (i.e. applied to each row of $\mathbf{A}^t$ individually) affine transformation + one ReLU.

位置编码 $\mathbf{P}^t$ 使用正弦位置信号，但增加了一个时间维度：

> The positional encoding $\mathbf{P}^t$ uses sinusoidal position signal but with an additional time dimension:

$$
\text{PE}(i, t, \delta) = 
\begin{cases}
\sin(\frac{i}{10000^{2\delta'/d}}) \oplus \sin(\frac{t}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta'\\
\cos(\frac{i}{10000^{2\delta'/d}}) \oplus \cos(\frac{t}{10000^{2\delta'/d}}) & \text{if } \delta = 2\delta' + 1\\
\end{cases}
$$

![A simplified illustration of Universal Transformer. The encoder and decoder share the same basic recurrent structure. But the decoder also attends to final encoder representation $\mathbf{H}^T$. (Image source: Figure 2 in Dehghani, et al. 2019 )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/universal-transformer.png)

在 Universal Transformer 的自适应版本中，循环步数 $T$ 由 [ACT](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act) 动态确定。每个位置都配备了一个动态 ACT 停止机制。一旦每个 token 的循环块停止，它就会停止接收更多的循环更新，而是简单地将当前值复制到下一步，直到所有块都停止，或者直到模型达到最大步数限制。

> In the adaptive version of Universal Transformer, the number of recurrent steps $T$ is dynamically determined by [ACT](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act). Each position is equipped with a dynamic ACT halting mechanism. Once a per-token recurrent block halts, it stops taking more recurrent updates but simply copies the current value to the next step until all the blocks halt or until the model reaches a maximum step limit.

### 强化学习的稳定性 (GTrXL)

> Stabilization for RL (GTrXL)

自注意力机制避免将整个过去压缩成固定大小的隐藏状态，并且不像 RNN 那样容易出现梯度消失或梯度爆炸问题。强化学习任务无疑可以从这些特性中受益。 *然而*，即使在监督学习中，训练 Transformer 也相当困难，更不用说在强化学习环境中了。毕竟，单独稳定和训练一个 LSTM 智能体可能就相当具有挑战性。

> The self-attention mechanism avoids compressing the whole past into a fixed-size hidden state and does not suffer from vanishing or exploding gradients as much as RNNs. Reinforcement Learning tasks can for sure benefit from these traits. *However*, it is quite difficult to train Transformer even in supervised learning, let alone in the RL context. It could be quite challenging to stabilize and train a LSTM agent by itself, after all.

**门控 Transformer-XL** (**GTrXL**; [Parisotto, et al. 2019](https://arxiv.org/abs/1910.06764)) 是将 Transformer 用于强化学习的一种尝试。GTrXL 在 [Transformer-XL](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#longer-attention-span-transformer-xl) 的基础上进行了两项改进，成功稳定了训练：

> The **Gated Transformer-XL** (**GTrXL**; [Parisotto, et al. 2019](https://arxiv.org/abs/1910.06764)) is one attempt to use Transformer for RL. GTrXL succeeded in stabilizing training with two changes on top of [Transformer-XL](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#longer-attention-span-transformer-xl):

1. 层归一化仅应用于残差模块中的输入流，而不应用于快捷流。这种重新排序的一个主要好处是允许原始输入从第一层流向最后一层。
2. 残差连接被替换为GRU风格（门控循环单元；[Chung et al., 2014](https://arxiv.org/abs/1412.3555)）的*门控*机制。

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

门控函数参数被显式初始化为接近恒等映射——这就是为什么存在一个$b_g$项。一个$b_g > 0$极大地有助于学习加速。

> The gating function parameters are explicitly initialized to be close to an identity map - this is why there is a $b_g$ term. A $b_g > 0$ greatly helps with the learning speedup.

![Comparison of the model architecture of Transformer-XL, Transformer-XL with the layer norm reordered, and Gated Transformer-XL. (Image source: Figure 1 in Parisotto, et al. 2019 )](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/gated-transformer-XL.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2020年4月). The transformer family. Lil’Log. https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/。

> Weng, Lilian. (Apr 2020). The transformer family. Lil’Log. https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/.

或

> Or

```
@article{weng2020transformer,
  title   = "The Transformer Family",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2020",
  month   = "Apr",
  url     = "https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/"
}
```

### 参考文献

> Reference

[1] Ashish Vaswani, et al. [“Attention is all you need.”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf) NIPS 2017.

> [1] Ashish Vaswani, et al. [“Attention is all you need.”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf) NIPS 2017.

[2] Rami Al-Rfou, et al. [“Character-level language modeling with deeper self-attention.”](https://arxiv.org/abs/1808.04444) AAAI 2019.

> [2] Rami Al-Rfou, et al. [“Character-level language modeling with deeper self-attention.”](https://arxiv.org/abs/1808.04444) AAAI 2019.

[3] Olah & Carter, [“Attention and Augmented Recurrent Neural Networks”](http://doi.org/10.23915/disti), Distill, 2016.

> [3] Olah & Carter, [“Attention and Augmented Recurrent Neural Networks”](http://doi.org/10.23915/disti), Distill, 2016.

[4] Sainbayar Sukhbaatar, et al. [“Adaptive Attention Span in Transformers”](https://arxiv.org/abs/1905.07799). ACL 2019.

> [4] Sainbayar Sukhbaatar, et al. [“Adaptive Attention Span in Transformers”](https://arxiv.org/abs/1905.07799). ACL 2019.

[5] Rewon Child, et al. [“Generating Long Sequences with Sparse Transformers”](https://arxiv.org/abs/1904.10509) arXiv:1904.10509 (2019)。

> [5] Rewon Child, et al. [“Generating Long Sequences with Sparse Transformers”](https://arxiv.org/abs/1904.10509) arXiv:1904.10509 (2019).

[6] Nikita Kitaev, et al. [“Reformer: The Efficient Transformer”](https://arxiv.org/abs/2001.04451) ICLR 2020.

> [6] Nikita Kitaev, et al. [“Reformer: The Efficient Transformer”](https://arxiv.org/abs/2001.04451) ICLR 2020.

[7] Alex Graves. (“Adaptive Computation Time for Recurrent Neural Networks”)[https://arxiv.org/abs/1603.08983]

> [7] Alex Graves. (“Adaptive Computation Time for Recurrent Neural Networks”)[https://arxiv.org/abs/1603.08983]

[8] Niki Parmar, et al. [“Image Transformer”](https://arxiv.org/abs/1802.05751) ICML 2018.

> [8] Niki Parmar, et al. [“Image Transformer”](https://arxiv.org/abs/1802.05751) ICML 2018.

[9] Zihang Dai, et al. [“Transformer-XL: Attentive Language Models Beyond a Fixed-Length Context.”](https://arxiv.org/abs/1901.02860) ACL 2019.

> [9] Zihang Dai, et al. [“Transformer-XL: Attentive Language Models Beyond a Fixed-Length Context.”](https://arxiv.org/abs/1901.02860) ACL 2019.

[10] Aidan N. Gomez, et al. [“The Reversible Residual Network: Backpropagation Without Storing Activations”](https://arxiv.org/abs/1707.04585) NIPS 2017.

> [10] Aidan N. Gomez, et al. [“The Reversible Residual Network: Backpropagation Without Storing Activations”](https://arxiv.org/abs/1707.04585) NIPS 2017.

[11] Mostafa Dehghani, et al. [“Universal Transformers”](https://arxiv.org/abs/1807.03819) ICLR 2019.

> [11] Mostafa Dehghani, et al. [“Universal Transformers”](https://arxiv.org/abs/1807.03819) ICLR 2019.

[12] Emilio Parisotto, et al. [“Stabilizing Transformers for Reinforcement Learning”](https://arxiv.org/abs/1910.06764) arXiv:1910.06764 (2019)。

> [12] Emilio Parisotto, et al. [“Stabilizing Transformers for Reinforcement Learning”](https://arxiv.org/abs/1910.06764) arXiv:1910.06764 (2019).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Attention | 注意力 | 神经网络中的一种机制，模型通过选择性地关注给定数据集来学习进行预测。 |
| Self-attention | 自注意力 | 一种注意力机制，模型利用同一数据样本中其他部分的观测来预测该样本的一部分。 |
| Multi-head self-attention | 多头自注意力 | Transformer中的关键组件，通过将输入分成更小的块并在每个子空间并行计算缩放点积注意力，以捕获不同表示子空间的信息。 |
| Positional Encoding | 位置编码 | 用于为Transformer模型提供序列中token的顺序信息，因为自注意力操作是置换不变的。 |
| Adaptive Computation Time (ACT) | 自适应计算时间 | 一种动态决定循环神经网络或Transformer中所需计算步数的机制，以适应不同输入。 |
| Transformer-XL | 超长Transformer | 通过隐藏状态重用和相对位置编码，扩展了Transformer的注意力范围，解决了上下文分段问题。 |
| Sparse Transformer | 稀疏Transformer | 通过稀疏矩阵分解引入因子化自注意力，显著降低了Transformer在处理长序列时的计算和内存成本。 |
| Local Sensitive Hashing (LSH) | 局部敏感哈希 | 一种哈希技术，用于在高维空间中快速查找近似最近邻，Reformer模型将其应用于注意力机制以提高效率。 |
| Reversible Residual Layer | 可逆残差层 | 一种残差网络设计，允许在反向传播期间仅通过下一层的激活来恢复当前层的激活，从而节省内存。 |
| Universal Transformer | 通用Transformer | 将Transformer的自注意力与RNN的循环机制结合，并利用ACT动态调整计算步数，以实现更灵活的序列处理。 |
| Reinforcement Learning (RL) | 强化学习 | 机器学习的一个领域，智能体通过与环境交互学习如何做出决策以最大化累积奖励。 |
| Layer Normalization | 层归一化 | 一种归一化技术，用于稳定神经网络训练，通过对层的所有神经元输入进行归一化。 |
| Residual Connection | 残差连接 | 一种跳跃连接，允许信息绕过一个或多个层直接传递，有助于缓解深度网络中的梯度消失问题。 |
