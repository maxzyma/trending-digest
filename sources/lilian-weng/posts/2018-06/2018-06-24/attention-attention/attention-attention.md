# 注意力？注意力！

> Attention? Attention!

> 来源：Lil'Log / Lilian Weng，2018-06-24
> 原文链接：https://lilianweng.github.io/posts/2018-06-24-attention/
> 分类：深度学习 / 注意力机制

## 核心要点

- 深度学习中的注意力机制通过重要性权重向量，估计元素间关联强度并加权求和，以辅助预测或推断。
- 传统Seq2Seq模型因固定长度上下文向量难以记忆长句子，注意力机制的引入解决了这一问题。
- 注意力机制通过在上下文向量和整个源输入之间建立快捷方式，使模型能够访问完整的输入序列，从而改善机器翻译性能。
- 自注意力（内部注意力）是一种关联单个序列内部不同位置的机制，用于计算序列表示，在机器阅读等任务中表现出色。
- 注意力机制可分为软性与硬性、全局与局部等多种类型，以适应不同的计算需求和模型特性。
- 神经图灵机将神经网络控制器与外部存储器结合，通过基于内容和位置的软性注意力实现读写操作。
- 指针网络通过在输入元素上应用注意力，解决输出元素对应输入序列位置的问题，而非混合编码器隐藏单元。
- Transformer模型完全基于多头自注意力机制，无需循环网络单元即可进行序列到序列建模，并引入了键、值和查询的概念。
- SNAIL结合了Transformer的自注意力和时间卷积，旨在解决Transformer在位置依赖敏感问题上的弱点。
- 自注意力生成对抗网络（SAGAN）将自注意力层引入GAN，以更好地捕捉图像中远距离空间区域的依赖关系，提升生成细节。

## 正文

[2018-10-28更新：添加[指针网络](https://lilianweng.github.io/posts/2018-06-24-attention/#pointer-network)以及我的Transformer实现[链接](https://github.com/lilianweng/transformer-tensorflow)。]  

[2018-11-06更新：添加Transformer模型实现[链接](https://github.com/lilianweng/transformer-tensorflow)。]  

[2018-11-18更新：添加[神经图灵机](https://lilianweng.github.io/posts/2018-06-24-attention/#neural-turing-machines)。]  

[2019-07-18更新：纠正了在介绍[show-attention-tell](https://arxiv.org/abs/1502.03044)论文时使用“自注意力”一词的错误；将其移至[自注意力](https://lilianweng.github.io/posts/2018-06-24-attention/#self-attention)部分。]  

[2020-04-07更新：关于改进型Transformer模型的后续文章[在此](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/)。]

> [Updated on 2018-10-28: Add [Pointer Network](https://lilianweng.github.io/posts/2018-06-24-attention/#pointer-network) and the [link](https://github.com/lilianweng/transformer-tensorflow) to my implementation of Transformer.]  
>
> [Updated on 2018-11-06: Add a [link](https://github.com/lilianweng/transformer-tensorflow) to the implementation of Transformer model.]  
>
> [Updated on 2018-11-18: Add [Neural Turing Machines](https://lilianweng.github.io/posts/2018-06-24-attention/#neural-turing-machines).]  
>
> [Updated on 2019-07-18: Correct the mistake on using the term “self-attention” when introducing the [show-attention-tell](https://arxiv.org/abs/1502.03044) paper; moved it to [Self-Attention](https://lilianweng.github.io/posts/2018-06-24-attention/#self-attention) section.]  
>
> [Updated on 2020-04-07: A follow-up post on improved Transformer models is [here](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/).]

注意力在某种程度上受到我们如何对图像不同区域进行视觉关注或关联句子中词语的启发。以图1中的柴犬图片为例。

> Attention is, to some extent, motivated by how we pay visual attention to different regions of an image or correlate words in one sentence. Take the picture of a Shiba Inu in Fig. 1 as an example.

![A Shiba Inu in a men’s outfit. The credit of the original photo goes to Instagram @mensweardog .](https://lilianweng.github.io/posts/2018-06-24-attention/shiba-example-attention.png)

人类的视觉注意力使我们能够以“高分辨率”聚焦于某个区域（例如，看黄色框中的尖耳朵），同时以“低分辨率”感知周围图像（例如，雪景背景和衣服呢？），然后相应地调整焦点或进行推断。给定图像的一小块区域，其余像素提供了那里应该显示什么的线索。我们期望在黄色框中看到一只尖耳朵，因为我们已经看到了狗的鼻子、右侧的另一只尖耳朵以及柴犬神秘的眼睛（红色框中的内容）。然而，底部的毛衣和毯子就不如那些狗狗的特征那么有帮助了。

> Human visual attention allows us to focus on a certain region with “high resolution” (i.e. look at the pointy ear in the yellow box) while perceiving the surrounding image in “low resolution” (i.e. now how about the snowy background and the outfit?), and then adjust the focal point or do the inference accordingly. Given a small patch of an image, pixels in the rest provide clues what should be displayed there. We expect to see a pointy ear in the yellow box because we have seen a dog’s nose, another pointy ear on the right, and Shiba’s mystery eyes (stuff in the red boxes). However, the sweater and blanket at the bottom would not be as helpful as those doggy features.

同样，我们可以解释一个句子或紧密语境中词语之间的关系。当我们看到“吃”时，我们期望很快会遇到一个食物词。颜色词描述食物，但可能与“吃”本身没有那么直接的关系。

> Similarly, we can explain the relationship between words in one sentence or close context. When we see “eating”, we expect to encounter a food word very soon. The color term describes the food, but probably not so much with “eating” directly.

![One word "attends" to other words in the same sentence differently.](https://lilianweng.github.io/posts/2018-06-24-attention/sentence-example-attention.png)

简而言之，深度学习中的注意力可以被广泛解释为重要性权重向量：为了预测或推断一个元素，例如图像中的像素或句子中的单词，我们使用注意力向量来估计它与其他元素的关联强度（或者如您在许多论文中可能读到的，“*关注*”其他元素），并将其值按注意力向量加权求和，作为目标的近似值。

> In a nutshell, attention in deep learning can be broadly interpreted as a vector of importance weights: in order to predict or infer one element, such as a pixel in an image or a word in a sentence, we estimate using the attention vector how strongly it is correlated with (or “*attends to*” as you may have read in many papers) other elements and take the sum of their values weighted by the attention vector as the approximation of the target.

### Seq2Seq模型有什么问题？

> What’s Wrong with Seq2Seq Model?

**Seq2seq**模型诞生于语言建模领域（[Sutskever, et al. 2014](https://arxiv.org/abs/1409.3215)）。广义上讲，它旨在将输入序列（源）转换为新的序列（目标），并且两个序列都可以是任意长度。转换任务的例子包括文本或音频的多语言机器翻译、问答对话生成，甚至将句子解析成语法树。

> The **seq2seq** model was born in the field of language modeling ([Sutskever, et al. 2014](https://arxiv.org/abs/1409.3215)). Broadly speaking, it aims to transform an input sequence (source) to a new one (target) and both sequences can be of arbitrary lengths. Examples of transformation tasks include machine translation between multiple languages in either text or audio, question-answer dialog generation, or even parsing sentences into grammar trees.

seq2seq模型通常具有编码器-解码器架构，由以下部分组成：

> The seq2seq model normally has an encoder-decoder architecture, composed of:

- 一个**编码器**处理输入序列，并将信息压缩成一个*固定长度*的上下文向量（也称为句子嵌入或“思想”向量）。这种表示形式应能很好地概括*整个*源序列的含义。
- 一个**解码器**用上下文向量初始化，以发出转换后的输出。早期工作只使用编码器网络的最后一个状态作为解码器的初始状态。

> • An **encoder** processes the input sequence and compresses the information into a context vector (also known as sentence embedding or “thought” vector) of a *fixed length*. This representation is expected to be a good summary of the meaning of the *whole* source sequence.
> • A **decoder** is initialized with the context vector to emit the transformed output. The early work only used the last state of the encoder network as the decoder initial state.

编码器和解码器都是循环神经网络，即使用[LSTM或GRU](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)单元。

> Both the encoder and decoder are recurrent neural networks, i.e. using [LSTM or GRU](http://colah.github.io/posts/2015-08-Understanding-LSTMs/) units.

![The encoder-decoder model, translating the sentence "she is eating a green apple" to Chinese. The visualization of both encoder and decoder is unrolled in time.](https://lilianweng.github.io/posts/2018-06-24-attention/encoder-decoder-example.png)

这种固定长度上下文向量设计的一个关键且明显的缺点是无法记住长句子。它通常在处理完整个输入后就忘记了前半部分。注意力机制应运而生（[Bahdanau et al., 2015](https://arxiv.org/pdf/1409.0473.pdf)），以解决这个问题。

> A critical and apparent disadvantage of this fixed-length context vector design is incapability of remembering long sentences. Often it has forgotten the first part once it completes processing the whole input. The attention mechanism was born ([Bahdanau et al., 2015](https://arxiv.org/pdf/1409.0473.pdf)) to resolve this problem.

### 为翻译而生

> Born for Translation

注意力机制的诞生是为了帮助神经网络机器翻译（[NMT](https://arxiv.org/pdf/1409.0473.pdf)）记住长源句子。注意力机制发明的秘诀不是从编码器的最后一个隐藏状态构建一个单一的上下文向量，而是在上下文向量和整个源输入之间创建快捷方式。这些快捷连接的权重可以为每个输出元素定制。

> The attention mechanism was born to help memorize long source sentences in neural machine translation ([NMT](https://arxiv.org/pdf/1409.0473.pdf)). Rather than building a single context vector out of the encoder’s last hidden state, the secret sauce invented by attention is to create shortcuts between the context vector and the entire source input. The weights of these shortcut connections are customizable for each output element.

由于上下文向量可以访问整个输入序列，我们无需担心遗忘。源和目标之间的对齐由上下文向量学习和控制。本质上，上下文向量消耗三类信息：

> While the context vector has access to the entire input sequence, we don’t need to worry about forgetting. The alignment between the source and target is learned and controlled by the context vector. Essentially the context vector consumes three pieces of information:

- 编码器隐藏状态；
- 解码器隐藏状态；
- 源和目标之间的对齐。

> • encoder hidden states;
> • decoder hidden states;
> • alignment between source and target.

![The encoder-decoder model with additive attention mechanism in Bahdanau et al., 2015 .](https://lilianweng.github.io/posts/2018-06-24-attention/encoder-decoder-attention.png)

#### 定义

> Definition

现在，让我们以科学的方式定义NMT中引入的注意力机制。假设我们有一个源序列$\mathbf{x}$，长度为$n$，并尝试输出一个目标序列$\mathbf{y}$，长度为$m$：

> Now let’s define the attention mechanism introduced in NMT in a scientific way. Say, we have a source sequence $\mathbf{x}$ of length $n$ and try to output a target sequence $\mathbf{y}$ of length $m$:

$$
\begin{aligned}
\mathbf{x} &= [x_1, x_2, \dots, x_n] \\
\mathbf{y} &= [y_1, y_2, \dots, y_m]
\end{aligned}
$$

（粗体变量表示它们是向量；本文其余部分也如此。）

> (Variables in bold indicate that they are vectors; same for everything else in this post.)

编码器是一个[双向RNN](https://www.coursera.org/lecture/nlp-sequence-models/bidirectional-rnn-fyXnn)（或您选择的其他循环网络设置），具有前向隐藏状态$\overrightarrow{\boldsymbol{h}}_i$和后向隐藏状态$\overleftarrow{\boldsymbol{h}}_i$。两者的简单拼接表示编码器状态。这样做的动机是在一个词的标注中同时包含前一个词和后一个词。

> The encoder is a [bidirectional RNN](https://www.coursera.org/lecture/nlp-sequence-models/bidirectional-rnn-fyXnn) (or other recurrent network setting of your choice) with a forward hidden state $\overrightarrow{\boldsymbol{h}}_i$ and a backward one $\overleftarrow{\boldsymbol{h}}_i$. A simple concatenation of two represents the encoder state. The motivation is to include both the preceding and following words in the annotation of one word.

$$
\boldsymbol{h}_i = [\overrightarrow{\boldsymbol{h}}_i^\top; \overleftarrow{\boldsymbol{h}}_i^\top]^\top, i=1,\dots,n
$$

解码器网络在位置 t 处输出词的隐藏状态为$\boldsymbol{s}_t=f(\boldsymbol{s}_{t-1}, y_{t-1}, \mathbf{c}_t)$，$t=1,\dots,m$，其中上下文向量$\mathbf{c}_t$是输入序列隐藏状态的总和，由对齐分数加权：

> The decoder network has hidden state $\boldsymbol{s}_t=f(\boldsymbol{s}_{t-1}, y_{t-1}, \mathbf{c}_t)$ for the output word at position t, $t=1,\dots,m$, where the context vector $\mathbf{c}_t$ is a sum of hidden states of the input sequence, weighted by alignment scores:

$$
\begin{aligned}
\mathbf{c}_t &= \sum_{i=1}^n \alpha_{t,i} \boldsymbol{h}_i & \small{\text{; Context vector for output }y_t}\\
\alpha_{t,i} &= \text{align}(y_t, x_i) & \small{\text{; How well two words }y_t\text{ and }x_i\text{ are aligned.}}\\
&= \frac{\exp(\text{score}(\boldsymbol{s}_{t-1}, \boldsymbol{h}_i))}{\sum_{i'=1}^n \exp(\text{score}(\boldsymbol{s}_{t-1}, \boldsymbol{h}_{i'}))} & \small{\text{; Softmax of some predefined alignment score.}}.
\end{aligned}
$$

对齐模型根据输入在位置 i 和输出在位置 t 的匹配程度，为这对输入和输出分配一个分数`\alpha_{t,i}`，$(y_t, x_i)$。$\{\alpha_{t, i}\}$是一组权重，定义了每个源隐藏状态对每个输出的考虑程度。在 Bahdanau 的论文中，对齐分数`\alpha`由一个具有单个隐藏层的**前馈网络**参数化，并且该网络与模型的其他部分联合训练。因此，考虑到 tanh 用作非线性激活函数，分数函数采用以下形式：

英文原文：The alignment model assigns a score `\alpha_{t,i}` to the pair of input at position i and output at position t, 

$(y_t, x_i)$, based on how well they match. The set of 

$\{\alpha_{t, i}\}$ are weights defining how much of each source hidden state should be considered for each output. In Bahdanau’s paper, the alignment score `\alpha` is parametrized by a feed-forward network with a single hidden layer and this network is jointly trained with other parts of the model. The score function is therefore in the following form, given that tanh is used as the non-linear activation function:

$$
\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \mathbf{v}_a^\top \tanh(\mathbf{W}_a[\boldsymbol{s}_t; \boldsymbol{h}_i])
$$

其中$\mathbf{v}_a$和$\mathbf{W}_a$都是在对齐模型中学习的权重矩阵。

> where both $\mathbf{v}_a$ and $\mathbf{W}_a$ are weight matrices to be learned in the alignment model.

对齐分数矩阵是一个很好的副产品，可以明确显示源词和目标词之间的相关性。

> The matrix of alignment scores is a nice byproduct to explicitly show the correlation between source and target words.

![Alignment matrix of "L'accord sur l'Espace économique européen a été signé en août 1992" (French) and its English translation "The agreement on the European Economic Area was signed in August 1992". (Image source: Fig 3 in Bahdanau et al., 2015 )](https://lilianweng.github.io/posts/2018-06-24-attention/bahdanau-fig3.png)

请查看Tensorflow团队提供的这篇不错的[教程](https://www.tensorflow.org/versions/master/tutorials/seq2seq)，了解更多实现说明。

> Check out this nice [tutorial](https://www.tensorflow.org/versions/master/tutorials/seq2seq) by Tensorflow team for more implementation instructions.

### 注意力机制家族

> A Family of Attention Mechanisms

借助注意力机制，源序列和目标序列之间的依赖关系不再受中间距离的限制！鉴于注意力机制在机器翻译中带来了巨大改进，它很快被扩展到计算机视觉领域（[Xu et al. 2015](http://proceedings.mlr.press/v37/xuc15.pdf)），人们开始探索各种其他形式的注意力机制（[Luong, et al., 2015](https://arxiv.org/pdf/1508.04025.pdf)；[Britz et al., 2017](https://arxiv.org/abs/1703.03906)；[Vaswani, et al., 2017](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf)）。

> With the help of the attention, the dependencies between source and target sequences are not restricted by the in-between distance anymore! Given the big improvement by attention in machine translation, it soon got extended into the computer vision field ([Xu et al. 2015](http://proceedings.mlr.press/v37/xuc15.pdf)) and people started exploring various other forms of attention mechanisms ([Luong, et al., 2015](https://arxiv.org/pdf/1508.04025.pdf); [Britz et al., 2017](https://arxiv.org/abs/1703.03906); [Vaswani, et al., 2017](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf)).

#### 总结

> Summary

下面是几种流行的注意力机制及其对应的对齐分数函数的总结表：

> Below is a summary table of several popular attention mechanisms and corresponding alignment score functions:

| 名称 | 对齐分数函数 | 引用 |
| --- | --- | --- |
| 基于内容的注意力 | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \text{cosine}[\boldsymbol{s}_t, \boldsymbol{h}_i]$ | Graves2014 |
| 加性(*) | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \mathbf{v}_a^\top \tanh(\mathbf{W}_a[\boldsymbol{s}_{t-1}; \boldsymbol{h}_i])$ | Bahdanau2015 |
| 基于位置 | $\alpha_{t,i} = \text{softmax}(\mathbf{W}_a \boldsymbol{s}_t)$ 注意：这简化了softmax对齐，使其仅依赖于目标位置。 | Luong2015 |
| 通用 | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \boldsymbol{s}_t^\top\mathbf{W}_a\boldsymbol{h}_i$ 其中$\mathbf{W}_a$是注意力层中一个可训练的权重矩阵。 | Luong2015 |
| 点积 | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \boldsymbol{s}_t^\top\boldsymbol{h}_i$ | Luong2015 |
| 缩放点积(^) | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \frac{\boldsymbol{s}_t^\top\boldsymbol{h}_i}{\sqrt{n}}$ 注：与点积注意力非常相似，只是多了一个缩放因子；其中 n 是源隐藏状态的维度。 | Vaswani2017 |

> 英文原表 / English original

| Name | Alignment score function | Citation |
| --- | --- | --- |
| Content-base attention | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \text{cosine}[\boldsymbol{s}_t, \boldsymbol{h}_i]$ | Graves2014 |
| Additive(*) | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \mathbf{v}_a^\top \tanh(\mathbf{W}_a[\boldsymbol{s}_{t-1}; \boldsymbol{h}_i])$ | Bahdanau2015 |
| Location-Base | $\alpha_{t,i} = \text{softmax}(\mathbf{W}_a \boldsymbol{s}_t)$ Note: This simplifies the softmax alignment to only depend on the target position. | Luong2015 |
| General | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \boldsymbol{s}_t^\top\mathbf{W}_a\boldsymbol{h}_i$ where $\mathbf{W}_a$ is a trainable weight matrix in the attention layer. | Luong2015 |
| Dot-Product | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \boldsymbol{s}_t^\top\boldsymbol{h}_i$ | Luong2015 |
| Scaled Dot-Product(^) | $\text{score}(\boldsymbol{s}_t, \boldsymbol{h}_i) = \frac{\boldsymbol{s}_t^\top\boldsymbol{h}_i}{\sqrt{n}}$ Note: very similar to the dot-product attention except for a scaling factor; where n is the dimension of the source hidden state. | Vaswani2017 |

(*) 在 Luong 等人 2015 年的论文中被称为“concat”，在 Vaswani 等人 2017 年的论文中被称为“加性注意力”。  

(^) 它添加了一个缩放因子 $1/\sqrt{n}$，其动机是担心当输入较大时，softmax 函数可能具有极小的梯度，难以进行高效学习。  


> (*) Referred to as “concat” in Luong, et al., 2015 and as “additive attention” in Vaswani, et al., 2017.  
>
> (^) It adds a scaling factor $1/\sqrt{n}$, motivated by the concern when the input is large, the softmax function may have an extremely small gradient, hard for efficient learning.  

以下是注意力机制的更广泛类别的总结：

> Here are a summary of broader categories of attention mechanisms:

| 名称 | 定义 | 引用 |
| --- | --- | --- |
| 自注意力(&) | 关联同一输入序列的不同位置。理论上，自注意力可以采用上述任何评分函数，只需将目标序列替换为相同的输入序列即可。 | Cheng2016 |
| 全局/软性 | 关注整个输入状态空间。 | Xu2015 |
| 局部/硬性 | 关注输入状态空间的一部分；即输入图像的一个补丁。 | Xu2015 ; Luong2015 |

> 英文原表 / English original

| Name | Definition | Citation |
| --- | --- | --- |
| Self-Attention(&) | Relating different positions of the same input sequence. Theoretically the self-attention can adopt any score functions above, but just replace the target sequence with the same input sequence. | Cheng2016 |
| Global/Soft | Attending to the entire input state space. | Xu2015 |
| Local/Hard | Attending to the part of input state space; i.e. a patch of the input image. | Xu2015 ; Luong2015 |

(&) 在 Cheng 等人 2016 年的论文和其他一些论文中，也被称为“内部注意力”。

> (&) Also, referred to as “intra-attention” in Cheng et al., 2016 and some other papers.

#### 自注意力

> Self-Attention

**自注意力**，也称为**内部注意力**，是一种注意力机制，用于关联单个序列的不同位置，以计算该序列的表示。它已被证明在机器阅读、抽象摘要或图像描述生成中非常有用。

> **Self-attention**, also known as **intra-attention**, is an attention mechanism relating different positions of a single sequence in order to compute a representation of the same sequence. It has been shown to be very useful in machine reading, abstractive summarization, or image description generation.

《[长短期记忆网络](https://arxiv.org/pdf/1601.06733.pdf)》论文使用自注意力进行机器阅读。在下面的例子中，自注意力机制使我们能够学习当前词与句子前一部分之间的关联。

> The [long short-term memory network](https://arxiv.org/pdf/1601.06733.pdf) paper used self-attention to do machine reading. In the example below, the self-attention mechanism enables us to learn the correlation between the current words and the previous part of the sentence.

![The current word is in red and the size of the blue shade indicates the activation level. (Image source: Cheng et al., 2016 )](https://lilianweng.github.io/posts/2018-06-24-attention/cheng2016-fig1.png)

#### 软性注意力与硬性注意力

> Soft vs Hard Attention

在《[展示、关注和讲述](http://proceedings.mlr.press/v37/xuc15.pdf)》论文中，注意力机制被应用于图像以生成标题。图像首先由 CNN 编码以提取特征。然后，LSTM 解码器消耗卷积特征，逐个生成描述性词语，其中权重通过注意力学习。注意力权重的可视化清晰地展示了模型为了输出某个词而关注图像的哪些区域。

> In the [show, attend and tell](http://proceedings.mlr.press/v37/xuc15.pdf) paper, attention mechanism is applied to images to generate captions. The image is first encoded by a CNN to extract features. Then a LSTM decoder consumes the convolution features to produce descriptive words one by one, where the weights are learned through attention. The visualization of the attention weights clearly demonstrates which regions of the image the model is paying attention to so as to output a certain word.

!["A woman is throwing a frisbee in a park." (Image source: Fig. 6(b) in Xu et al. 2015 )](https://lilianweng.github.io/posts/2018-06-24-attention/xu2015-fig6b.png)

这篇论文首次提出了“软性”注意力与“硬性”注意力之间的区别，其依据是注意力是访问整个图像还是仅访问一个补丁：

> This paper first proposed the distinction between “soft” vs “hard” attention, based on whether the attention has access to the entire image or only a patch:

- **软性**注意力：对源图像中的所有补丁“软性”地学习并放置对齐权重；本质上与[Bahdanau et al., 2015](https://arxiv.org/abs/1409.0473)中的注意力类型相同。


   - *优点*：模型平滑且可微分。
   - *缺点*：当源输入较大时计算成本高昂。
- **硬性**注意力：一次只选择图像的一个补丁进行关注。


   - *优点*：推理时计算量较少。
   - *缺点*：模型不可微分，需要更复杂的技术（如方差缩减或强化学习）进行训练。 ([Luong, et al., 2015](https://arxiv.org/abs/1508.04025))

> • **Soft** Attention: the alignment weights are learned and placed “softly” over all patches in the source image; essentially the same type of attention as in [Bahdanau et al., 2015](https://arxiv.org/abs/1409.0473).
>

> ◦ *Pro*: the model is smooth and differentiable.

> ◦ *Con*: expensive when the source input is large.

> • **Hard** Attention: only selects one patch of the image to attend to at a time.
>

> ◦ *Pro*: less calculation at the inference time.

> ◦ *Con*: the model is non-differentiable and requires more complicated techniques such as variance reduction or reinforcement learning to train. ([Luong, et al., 2015](https://arxiv.org/abs/1508.04025))

#### 全局注意力与局部注意力

> Global vs Local Attention

[Luong, et al., 2015](https://arxiv.org/pdf/1508.04025.pdf)提出了“全局”和“局部”注意力。全局注意力类似于软性注意力，而局部注意力是[硬性与软性](https://lilianweng.github.io/posts/2018-06-24-attention/#soft-vs-hard-attention)之间的一种有趣的融合，是对硬性注意力的一种改进，使其可微分：模型首先预测当前目标词的单个对齐位置，然后使用以源位置为中心的窗口来计算上下文向量。

> [Luong, et al., 2015](https://arxiv.org/pdf/1508.04025.pdf) proposed the “global” and “local” attention. The global attention is similar to the soft attention, while the local one is an interesting blend between [hard and soft](https://lilianweng.github.io/posts/2018-06-24-attention/#soft-vs-hard-attention), an improvement over the hard attention to make it differentiable: the model first predicts a single aligned position for the current target word and a window centered around the source position is then used to compute a context vector.

![Global vs local attention (Image source: Fig 2 & 3 in Luong, et al., 2015 )](https://lilianweng.github.io/posts/2018-06-24-attention/luong2015-fig2-3.png)

### 神经图灵机

> Neural Turing Machines

艾伦·图灵在[1936](https://en.wikipedia.org/wiki/Turing_machine)年提出了一种极简的计算模型。它由一条无限长的磁带和一个与磁带交互的磁头组成。磁带上有无数个单元格，每个单元格都填充着一个符号：0、1 或空白（“ ”）。操作磁头可以在磁带上读取符号、编辑符号并左右移动。理论上，图灵机可以模拟任何计算机算法，无论其过程多么复杂或昂贵。无限内存赋予图灵机在数学上无限的优势。然而，无限内存对于真实的现代计算机来说是不可行的，因此我们只将图灵机视为一种计算的数学模型。

> Alan Turing in [1936](https://en.wikipedia.org/wiki/Turing_machine) proposed a minimalistic model of computation. It is composed of a infinitely long tape and a head to interact with the tape. The tape has countless cells on it, each filled with a symbol: 0, 1 or blank (" “). The operation head can read symbols, edit symbols and move left/right on the tape. Theoretically a Turing machine can simulate any computer algorithm, irrespective of how complex or expensive the procedure might be. The infinite memory gives a Turing machine an edge to be mathematically limitless. However, infinite memory is not feasible in real modern computers and then we only consider Turing machine as a mathematical model of computation.

![How a Turing machine looks like: a tape + a head that handles the tape. (Image source: http://aturingmachine.com/ )](https://lilianweng.github.io/posts/2018-06-24-attention/turing-machine.jpg)

**神经图灵机** (**NTM**, [Graves, Wayne & Danihelka, 2014](https://arxiv.org/abs/1410.5401)) 是一种将神经网络与外部存储器耦合的模型架构。该存储器模仿图灵机磁带，神经网络控制操作磁头从磁带读取或写入。然而，NTM 中的存储器是有限的，因此它可能更像一台“神经[冯·诺依曼](https://en.wikipedia.org/wiki/Von_Neumann_architecture)机”。

> **Neural Turing Machine** (**NTM**, [Graves, Wayne & Danihelka, 2014](https://arxiv.org/abs/1410.5401)) is a model architecture for coupling a neural network with external memory storage. The memory mimics the Turing machine tape and the neural network controls the operation heads to read from or write to the tape. However, the memory in NTM is finite, and thus it probably looks more like a “Neural [von Neumann](https://en.wikipedia.org/wiki/Von_Neumann_architecture) Machine”.

NTM 包含两个主要组件，一个*控制器*神经网络和一个*存储器*库。
控制器：负责在存储器上执行操作。它可以是任何类型的神经网络，前馈或循环。
存储器：存储处理过的信息。它是一个大小为$N \times M$的矩阵，包含 N 个向量行，每个行有$M$维度。

> NTM contains two major components, a *controller* neural network and a *memory* bank.
> Controller: is in charge of executing operations on the memory. It can be any type of neural network, feed-forward or recurrent.
> Memory: stores processed information. It is a matrix of size $N \times M$, containing N vector rows and each has $M$ dimensions.

在一个更新迭代中，控制器处理输入并相应地与存储器库交互以生成输出。这种交互由一组并行的*读取*和*写入*磁头处理。读取和写入操作都是“模糊的”，通过软性地关注所有内存地址来实现。

> In one update iteration, the controller processes the input and interacts with the memory bank accordingly to generate output. The interaction is handled by a set of parallel *read* and *write* heads. Both read and write operations are “blurry” by softly attending to all the memory addresses.

![Fig 10. Neural Turing Machine Architecture.](https://lilianweng.github.io/posts/2018-06-24-attention/NTM.png)

#### 读取与写入

> Reading and Writing

在时间 t 从存储器读取时，一个大小为$N$，$\mathbf{w}_t$的注意力向量控制着分配给不同内存位置（矩阵行）的注意力大小。读取向量$\mathbf{r}_t$是按注意力强度加权的求和：

> When reading from the memory at time t, an attention vector of size $N$, $\mathbf{w}_t$ controls how much attention to assign to different memory locations (matrix rows). The read vector $\mathbf{r}_t$ is a sum weighted by attention intensity:

$$
\mathbf{r}_t = \sum_{i=1}^N w_t(i)\mathbf{M}_t(i)\text{, where }\sum_{i=1}^N w_t(i)=1, \forall i: 0 \leq w_t(i) \leq 1
$$

其中$w_t(i)$是$i$中的第$\mathbf{w}_t$个元素，而$\mathbf{M}_t(i)$是存储器中的第$i$个行向量。

> where $w_t(i)$ is the $i$ -th element in $\mathbf{w}_t$ and $\mathbf{M}_t(i)$ is the $i$ -th row vector in the memory.

在时间 t 写入存储器时，受 LSTM 中输入门和遗忘门的启发，写入磁头首先根据擦除向量$\mathbf{e}_t$擦除一些旧内容，然后通过添加向量$\mathbf{a}_t$添加新信息。

> When writing into the memory at time t, as inspired by the input and forget gates in LSTM, a write head first wipes off some old content according to an erase vector $\mathbf{e}_t$ and then adds new information by an add vector $\mathbf{a}_t$.

$$
\begin{aligned}
\tilde{\mathbf{M}}_t(i) &= \mathbf{M}_{t-1}(i) [\mathbf{1} - w_t(i)\mathbf{e}_t] &\scriptstyle{\text{; erase}}\\
\mathbf{M}_t(i) &= \tilde{\mathbf{M}}_t(i) + w_t(i) \mathbf{a}_t &\scriptstyle{\text{; add}}
\end{aligned}
$$

#### 注意力机制

> Attention Mechanisms

在神经图灵机中，如何生成注意力分布$\mathbf{w}_t$取决于寻址机制：NTM 使用基于内容和基于位置的混合寻址方式。

> In Neural Turing Machine, how to generate the attention distribution $\mathbf{w}_t$ depends on the addressing mechanisms: NTM uses a mixture of content-based and location-based addressings.

**基于内容的寻址**

> **Content-based addressing**

内容寻址根据控制器从输入和内存行中提取的键向量$\mathbf{k}_t$和内存行之间的相似性创建注意力向量。基于内容的注意力分数通过余弦相似度计算，然后通过 softmax 进行归一化。此外，NTM 添加了一个强度乘数$\beta_t$来放大或衰减分布的焦点。

> The content-addressing creates attention vectors based on the similarity between the key vector $\mathbf{k}_t$ extracted by the controller from the input and memory rows. The content-based attention scores are computed as cosine similarity and then normalized by softmax. In addition, NTM adds a strength multiplier $\beta_t$ to amplify or attenuate the focus of the distribution.

$$
w_t^c(i) 
= \text{softmax}(\beta_t \cdot \text{cosine}[\mathbf{k}_t, \mathbf{M}_t(i)])
= \frac{\exp(\beta_t \frac{\mathbf{k}_t \cdot \mathbf{M}_t(i)}{\|\mathbf{k}_t\| \cdot \|\mathbf{M}_t(i)\|})}{\sum_{j=1}^N \exp(\beta_t \frac{\mathbf{k}_t \cdot \mathbf{M}_t(j)}{\|\mathbf{k}_t\| \cdot \|\mathbf{M}_t(j)\|})}
$$

**插值**

> **Interpolation**

然后使用一个插值门标量$g_t$来将新生成的内容注意力向量与上一个时间步的注意力权重进行混合：

> Then an interpolation gate scalar $g_t$ is used to blend the newly generated content-based attention vector with the attention weights in the last time step:

$$
\mathbf{w}_t^g = g_t \mathbf{w}_t^c + (1 - g_t) \mathbf{w}_{t-1}
$$

**基于位置的寻址**

> **Location-based addressing**

基于位置的寻址将注意力向量中不同位置的值求和，并由允许的整数移位上的加权分布进行加权。它等同于一个带有核$\mathbf{s}_t(.)$的一维卷积，该核是位置偏移的函数。有多种方法可以定义这种分布。请参阅以获取灵感。

> The location-based addressing sums up the values at different positions in the attention vector, weighted by a weighting distribution over allowable integer shifts. It is equivalent to a 1-d convolution with a kernel $\mathbf{s}_t(.)$, a function of the position offset. There are multiple ways to define this distribution. See for inspiration.

![Two ways to represent the shift weighting distribution $\mathbf{s}\_t$.](https://lilianweng.github.io/posts/2018-06-24-attention/shift-weighting.png)

最后，注意力分布通过一个锐化标量$\gamma_t \geq 1$得到增强。

> Finally the attention distribution is enhanced by a sharpening scalar $\gamma_t \geq 1$.

$$
\begin{aligned}
\tilde{w}_t(i) &= \sum_{j=1}^N w_t^g(j) s_t(i-j) & \scriptstyle{\text{; circular convolution}}\\
w_t(i) &= \frac{\tilde{w}_t(i)^{\gamma_t}}{\sum_{j=1}^N \tilde{w}_t(j)^{\gamma_t}} & \scriptstyle{\text{; sharpen}}
\end{aligned}
$$

在时间步 t 生成注意力向量 $\mathbf{w}_t$ 的完整过程如图所示。控制器生成的所有参数对于每个头都是唯一的。如果存在多个并行读写头，控制器将输出多组参数。

> The complete process of generating the attention vector $\mathbf{w}_t$ at time step t is illustrated in All the parameters produced by the controller are unique for each head. If there are multiple read and write heads in parallel, the controller would output multiple sets.

![Flow diagram of the addressing mechanisms in Neural Turing Machine. (Image source: Graves, Wayne & Danihelka, 2014 )](https://lilianweng.github.io/posts/2018-06-24-attention/NTM-flow-addressing.png)

### 指针网络

> Pointer Network

在排序或旅行推销员等问题中，输入和输出都是序列数据。不幸的是，由于输出元素的离散类别不是预先确定的，而是取决于可变的输入大小，因此这些问题无法通过经典的 seq-2-seq 或 NMT 模型轻松解决。**指针网络**（**Ptr-Net**；[Vinyals 等人，2015](https://arxiv.org/abs/1506.03134)）被提出用于解决这类问题：当输出元素对应于输入序列中的*位置*时。指针网络不是使用注意力将编码器的隐藏单元混合成一个上下文向量（参见图 8），而是在输入元素上应用注意力，以便在每个解码器步骤中选择一个作为输出。

> In problems like sorting or travelling salesman, both input and output are sequential data. Unfortunately, they cannot be easily solved by classic seq-2-seq or NMT models, given that the discrete categories of output elements are not determined in advance, but depends on the variable input size. The **Pointer Net** (**Ptr-Net**; [Vinyals, et al. 2015](https://arxiv.org/abs/1506.03134)) is proposed to resolve this type of problems: When the output elements correspond to *positions* in an input sequence. Rather than using attention to blend hidden units of an encoder into a context vector (See Fig. 8), the Pointer Net applies attention over the input elements to pick one as the output at each decoder step.

![The architecture of a Pointer Network model. (Image source: Vinyals, et al. 2015 )](https://lilianweng.github.io/posts/2018-06-24-attention/ptr-net.png)

Ptr-Net 输出一个整数索引序列 $\boldsymbol{c} = (c_1, \dots, c_m)$，给定输入向量序列 $\boldsymbol{x} = (x_1, \dots, x_n)$ 和 $1 \leq c_i \leq n$。该模型仍然采用编码器-解码器框架。编码器和解码器的隐藏状态分别表示为 $(\boldsymbol{h}_1, \dots, \boldsymbol{h}_n)$ 和 $(\boldsymbol{s}_1, \dots, \boldsymbol{s}_m)$。请注意，$\mathbf{s}_i$ 是解码器中单元激活后的输出门。Ptr-Net 在状态之间应用加性注意力，然后通过 softmax 对其进行归一化，以模拟输出条件概率：

> The Ptr-Net outputs a sequence of integer indices, $\boldsymbol{c} = (c_1, \dots, c_m)$ given a sequence of input vectors $\boldsymbol{x} = (x_1, \dots, x_n)$ and $1 \leq c_i \leq n$. The model still embraces an encoder-decoder framework. The encoder and decoder hidden states are denoted as $(\boldsymbol{h}_1, \dots, \boldsymbol{h}_n)$ and $(\boldsymbol{s}_1, \dots, \boldsymbol{s}_m)$, respectively. Note that $\mathbf{s}_i$ is the output gate after cell activation in the decoder. The Ptr-Net applies additive attention between states and then normalizes it by softmax to model the output conditional probability:

$$
\begin{aligned}
y_i &= p(c_i \vert c_1, \dots, c_{i-1}, \boldsymbol{x}) \\
    &= \text{softmax}(\text{score}(\boldsymbol{s}_t; \boldsymbol{h}_i)) = \text{softmax}(\mathbf{v}_a^\top \tanh(\mathbf{W}_a[\boldsymbol{s}_t; \boldsymbol{h}_i]))
\end{aligned}
$$

注意力机制被简化了，因为 Ptr-Net 不会将编码器状态与注意力权重混合到输出中。通过这种方式，输出只响应位置，而不响应输入内容。

> The attention mechanism is simplified, as Ptr-Net does not blend the encoder states into the output with attention weights. In this way, the output only responds to the positions but not the input content.

### Transformer

> Transformer

[“Attention is All you Need”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf)（Vaswani 等人，2017）无疑是 2017 年最具影响力和最有趣的论文之一。它对软注意力提出了许多改进，并使得*无需*循环网络单元即可进行 seq2seq 建模成为可能。所提出的“**transformer**”模型完全建立在自注意力机制之上，而没有使用序列对齐的循环架构。

> [“Attention is All you Need”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf)
> (Vaswani, et al., 2017), without a doubt, is one of the most impactful and interesting paper in 2017. It presented a lot of improvements to the soft attention and make it possible to do seq2seq modeling *without* recurrent network units. The proposed “**transformer**” model is entirely built on the self-attention mechanisms without using sequence-aligned recurrent architecture.

其模型架构中蕴含着秘密配方。

> The secret recipe is carried in its model architecture.

#### 键、值和查询

> Key, Value and Query

Transformer 中的主要组成部分是*多头自注意力机制*单元。Transformer 将输入的编码表示视为一组**键**-**值**对，$(\mathbf{K}, \mathbf{V})$，两者维度均为 `n`（输入序列长度）；在 NMT 的上下文中，键和值都是编码器的隐藏状态。在解码器中，先前的输出被压缩成一个**查询**（$\mathbf{Q}$，维度为 `m`），然后通过映射此查询以及键和值集合来生成下一个输出。

英文原文：The major component in the transformer is the unit of *multi-head self-attention mechanism*. The transformer views the encoded representation of the input as a set of key-value pairs, 

$(\mathbf{K}, \mathbf{V})$, both of dimension `n` (input sequence length); in the context of NMT, both the keys and values are the encoder hidden states. In the decoder, the previous output is compressed into a query (

$\mathbf{Q}$ of dimension `m`) and the next output is produced by mapping this query and the set of keys and values.

Transformer 采用了[缩放点积注意力](https://lilianweng.github.io/posts/2018-06-24-attention/#summary)：输出是值的加权和，其中分配给每个值的权重由查询与所有键的点积决定：

> The transformer adopts the [scaled dot-product attention](https://lilianweng.github.io/posts/2018-06-24-attention/#summary): the output is a weighted sum of the values, where the weight assigned to each value is determined by the dot-product of the query with all the keys:

$$
\text{Attention}(\mathbf{Q}, \mathbf{K}, \mathbf{V}) = \text{softmax}(\frac{\mathbf{Q}\mathbf{K}^\top}{\sqrt{n}})\mathbf{V}
$$

#### 多头自注意力

> Multi-Head Self-Attention

![Multi-head scaled dot-product attention mechanism. (Image source: Fig 2 in Vaswani, et al., 2017 )](https://lilianweng.github.io/posts/2018-06-24-attention/multi-head-attention.png)

多头机制不是只计算一次注意力，而是并行多次运行缩放点积注意力。独立的注意力输出被简单地连接起来，并线性变换到预期的维度。我猜想这样做的动机是因为集成总是有帮助的？;) 根据论文，*“多头注意力允许模型在不同位置共同关注来自不同表示**子空间**的信息。如果只有一个注意力头，平均化会抑制这种能力。”*

> Rather than only computing the attention once, the multi-head mechanism runs through the scaled dot-product attention multiple times in parallel. The independent attention outputs are simply concatenated and linearly transformed into the expected dimensions. I assume the motivation is because ensembling always helps? ;) According to the paper, *“multi-head attention allows the model to jointly attend to information from different representation **subspaces** at different positions. With a single attention head, averaging inhibits this.”*

$$
\begin{aligned}
\text{MultiHead}(\mathbf{Q}, \mathbf{K}, \mathbf{V}) &= [\text{head}_1; \dots; \text{head}_h]\mathbf{W}^O \\
\text{where head}_i &= \text{Attention}(\mathbf{Q}\mathbf{W}^Q_i, \mathbf{K}\mathbf{W}^K_i, \mathbf{V}\mathbf{W}^V_i)
\end{aligned}
$$

其中 $\mathbf{W}^Q_i$、$\mathbf{W}^K_i$、$\mathbf{W}^V_i$ 和 $\mathbf{W}^O$ 是待学习的参数矩阵。

> where $\mathbf{W}^Q_i$, $\mathbf{W}^K_i$, $\mathbf{W}^V_i$, and $\mathbf{W}^O$ are parameter matrices to be learned.

#### 编码器

> Encoder

![The transformer’s encoder. (Image source: Vaswani, et al., 2017 )](https://lilianweng.github.io/posts/2018-06-24-attention/transformer-encoder.png)

编码器生成一个基于注意力的表示，能够从一个可能无限大的上下文中定位特定信息。

> The encoder generates an attention-based representation with capability to locate a specific piece of information from a potentially infinitely-large context.

• 一个由 N=6 个相同层组成的堆栈。

• 每个层都包含一个**多头自注意力层**和一个简单的位置感知**全连接前馈网络**。

• 每个子层都采用[残差](https://arxiv.org/pdf/1512.03385.pdf)连接和层**归一化**。所有子层都输出相同维度 $d_\text{model} = 512$ 的数据。

英文原文：

• A stack of N=6 identical layers.

• Each layer has a **multi-head self-attention layer** and a simple position-wise **fully connected feed-forward network**.

• Each sub-layer adopts a [residual](https://arxiv.org/pdf/1512.03385.pdf) connection and a layer **normalization**.
All the sub-layers output data of the same dimension $d_\text{model} = 512$.

#### 解码器

> Decoder

![The transformer’s decoder. (Image source: Vaswani, et al., 2017 )](https://lilianweng.github.io/posts/2018-06-24-attention/transformer-decoder.png)

解码器能够从编码表示中检索信息。

> The decoder is able to retrieval from the encoded representation.

- 一个由 N = 6 个相同层组成的堆栈
- 每个层包含两个多头注意力机制子层和一个全连接前馈网络子层。
- 与编码器类似，每个子层都采用残差连接和层归一化。
- 第一个多头注意力子层经过**修改**，以防止位置关注后续位置，因为在预测当前位置时，我们不希望看到目标序列的未来。

> • A stack of N = 6 identical layers
> • Each layer has two sub-layers of multi-head attention mechanisms and one sub-layer of fully-connected feed-forward network.
> • Similar to the encoder, each sub-layer adopts a residual connection and a layer normalization.
> • The first multi-head attention sub-layer is **modified** to prevent positions from attending to subsequent positions, as we don’t want to look into the future of the target sequence when predicting the current position.

#### 完整架构

> Full Architecture

最后，这是 Transformer 的完整架构视图：

> Finally here is the complete view of the transformer’s architecture:

• 源序列和目标序列都首先通过嵌入层，以生成相同维度的数据 $d_\text{model} =512$。

• 为了保留位置信息，应用了基于正弦波的位置编码，并与嵌入输出相加。

• 一个 softmax 层和一个线性层被添加到最终的解码器输出中。

英文原文：

• Both the source and target sequences first go through embedding layers to produce data of the same dimension $d_\text{model} =512$.

• To preserve the position information, a sinusoid-wave-based positional encoding is applied and summed with the embedding output.

• A softmax and linear layer are added to the final decoder output.

![The full model architecture of the transformer. (Image source: Fig 1 & 2 in Vaswani, et al., 2017 .)](https://lilianweng.github.io/posts/2018-06-24-attention/transformer.png)

尝试实现 Transformer 模型是一个有趣的经历，这是我的实现：[lilianweng/transformer-tensorflow](https://github.com/lilianweng/transformer-tensorflow)。如果你感兴趣，可以阅读代码中的注释。

> Try to implement the transformer model is an interesting experience, here is mine: [lilianweng/transformer-tensorflow](https://github.com/lilianweng/transformer-tensorflow). Read the comments in the code if you are interested.

### SNAIL

> SNAIL

Transformer 没有循环或卷积结构，即使在嵌入向量中添加了位置编码，序列顺序也只是被弱化地整合进来。对于对位置依赖敏感的问题，例如[强化学习](https://lilianweng.github.io/posts/2018-02-19-rl-overview/)，这可能是一个大问题。

> The transformer has no recurrent or convolutional structure, even with the positional encoding added to the embedding vector, the sequential order is only weakly incorporated. For problems sensitive to the positional dependency like [reinforcement learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/), this can be a big problem.

这个**简单神经注意力[元学习器](http://bair.berkeley.edu/blog/2017/07/18/learning-to-learn/)** (**SNAIL**) ([Mishra et al., 2017](http://metalearning.ml/papers/metalearn17_mishra.pdf)) 的开发部分是为了解决 Transformer 模型中的[定位](https://lilianweng.github.io/posts/2018-06-24-attention/#full-architecture)问题，通过将 Transformer 中的自注意力机制与[时间卷积](https://deepmind.com/blog/wavenet-generative-model-raw-audio/)相结合。它已被证明在监督学习和强化学习任务中都表现良好。

> The **Simple Neural Attention [Meta-Learner](http://bair.berkeley.edu/blog/2017/07/18/learning-to-learn/)** (**SNAIL**) ([Mishra et al., 2017](http://metalearning.ml/papers/metalearn17_mishra.pdf)) was developed partially to resolve the problem with [positioning](https://lilianweng.github.io/posts/2018-06-24-attention/#full-architecture) in the transformer model by combining the self-attention mechanism in transformer with [temporal convolutions](https://deepmind.com/blog/wavenet-generative-model-raw-audio/). It has been demonstrated to be good at both supervised learning and reinforcement learning tasks.

![SNAIL model architecture (Image source: Mishra et al., 2017 )](https://lilianweng.github.io/posts/2018-06-24-attention/snail.png)

SNAIL 诞生于元学习领域，元学习本身是另一个值得单独撰写文章的大话题。但简单来说，元学习模型有望泛化到相似分布中的新颖、未见过的任务。如果你感兴趣，可以阅读[这篇](http://bair.berkeley.edu/blog/2017/07/18/learning-to-learn/)不错的介绍。

> SNAIL was born in the field of meta-learning, which is another big topic worthy of a post by itself. But in simple words, the meta-learning model is expected to be generalizable to novel, unseen tasks in the similar distribution. Read [this](http://bair.berkeley.edu/blog/2017/07/18/learning-to-learn/) nice introduction if interested.

### Self-Attention GAN

> Self-Attention GAN

*Self-Attention GAN* (**SAGAN**; [Zhang et al., 2018](https://arxiv.org/pdf/1805.08318.pdf)) 将自注意力层添加到[GAN](https://lilianweng.github.io/posts/2017-08-20-gan/)中，以使生成器和判别器都能更好地建模空间区域之间的关系。

> *Self-Attention GAN* (**SAGAN**; [Zhang et al., 2018](https://arxiv.org/pdf/1805.08318.pdf)) adds self-attention layers into [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/) to enable both the generator and the discriminator to better model relationships between spatial regions.

经典的[DCGAN](https://arxiv.org/abs/1511.06434)（深度卷积生成对抗网络）将判别器和生成器都表示为多层卷积网络。然而，网络的表示能力受到滤波器大小的限制，因为一个像素的特征仅限于一个小的局部区域。为了连接相距较远的区域，特征必须通过多层卷积操作进行稀释，并且不保证能维持其依赖关系。

> The classic [DCGAN](https://arxiv.org/abs/1511.06434) (Deep Convolutional GAN) represents both discriminator and generator as multi-layer convolutional networks. However, the representation capacity of the network is restrained by the filter size, as the feature of one pixel is limited to a small local region. In order to connect regions far apart, the features have to be dilute through layers of convolutional operations and the dependencies are not guaranteed to be maintained.

由于视觉上下文中的（软）自注意力旨在明确学习一个像素与所有其他位置（甚至是相距遥远的区域）之间的关系，因此它可以轻松捕获全局依赖性。因此，配备自注意力的GAN有望*更好地处理细节*，太棒了！

> As the (soft) self-attention in the vision context is designed to explicitly learn the relationship between one pixel and all other positions, even regions far apart, it can easily capture global dependencies. Hence GAN equipped with self-attention is expected to *handle details better*, hooray!

![Convolution operation and self-attention have access to regions of very different sizes.](https://lilianweng.github.io/posts/2018-06-24-attention/conv-vs-self-attention.png)

SAGAN 采用[非局部神经网络](https://arxiv.org/pdf/1711.07971.pdf)来应用注意力计算。卷积图像特征图$\mathbf{x}$被分支成三份，对应于 Transformer 中的[键、值和查询](https://lilianweng.github.io/posts/2018-06-24-attention/#key-value-and-query)概念：

> The SAGAN adopts the [non-local neural network](https://arxiv.org/pdf/1711.07971.pdf) to apply the attention computation. The convolutional image feature maps $\mathbf{x}$ is branched out into three copies, corresponding to the concepts of [key, value, and query](https://lilianweng.github.io/posts/2018-06-24-attention/#key-value-and-query) in the transformer:

• 键：$f(\mathbf{x}) = \mathbf{W}_f \mathbf{x}$

• 查询：$g(\mathbf{x}) = \mathbf{W}_g \mathbf{x}$

• 值：$h(\mathbf{x}) = \mathbf{W}_h \mathbf{x}$

英文原文：

• Key: $f(\mathbf{x}) = \mathbf{W}_f \mathbf{x}$

• Query: $g(\mathbf{x}) = \mathbf{W}_g \mathbf{x}$

• Value: $h(\mathbf{x}) = \mathbf{W}_h \mathbf{x}$

然后我们应用点积注意力来输出自注意力特征图：

> Then we apply the dot-product attention to output the self-attention feature maps:

$$
\begin{aligned}
\alpha_{i,j} &= \text{softmax}(f(\mathbf{x}_i)^\top g(\mathbf{x}_j)) \\
\mathbf{o}_j &= \mathbf{W}_v \Big( \sum_{i=1}^N \alpha_{i,j} h(\mathbf{x}_i) \Big)
\end{aligned}
$$

![The self-attention mechanism in SAGAN. (Image source: Fig. 2 in Zhang et al., 2018 )](https://lilianweng.github.io/posts/2018-06-24-attention/SAGAN.png)

请注意，$\alpha_{i,j}$是注意力图中的一个条目，表示模型在合成$i$个位置时，应关注$j$个位置的程度。$\mathbf{W}_f$、$\mathbf{W}_g$和$\mathbf{W}_h$都是 1x1 卷积滤波器。如果你觉得 1x1 卷积听起来是个奇怪的概念（即，它不就是用一个数字乘以整个特征图吗？），请观看 Andrew Ng 的这个简短[教程](https://www.coursera.org/lecture/convolutional-neural-networks/networks-in-networks-and-1x1-convolutions-ZTb8x)。输出$\mathbf{o}_j$是最终输出$\mathbf{o}= (\mathbf{o}_1, \mathbf{o}_2, \dots, \mathbf{o}_j, \dots, \mathbf{o}_N)$的列向量。

> Note that $\alpha_{i,j}$ is one entry in the attention map, indicating how much attention the model should pay to the $i$ -th position when synthesizing the $j$ -th location. $\mathbf{W}_f$, $\mathbf{W}_g$, and $\mathbf{W}_h$ are all 1x1 convolution filters. If you feel that 1x1 conv sounds like a weird concept (i.e., isn’t it just to multiply the whole feature map with one number?), watch this short [tutorial](https://www.coursera.org/lecture/convolutional-neural-networks/networks-in-networks-and-1x1-convolutions-ZTb8x) by Andrew Ng. The output $\mathbf{o}_j$ is a column vector of the final output $\mathbf{o}= (\mathbf{o}_1, \mathbf{o}_2, \dots, \mathbf{o}_j, \dots, \mathbf{o}_N)$.

此外，注意力层的输出会乘以一个缩放参数，并加回到原始输入特征图：

> Furthermore, the output of the attention layer is multiplied by a scale parameter and added back to the original input feature map:

$$
\mathbf{y} = \mathbf{x}_i + \gamma \mathbf{o}_i
$$

在训练过程中，当缩放参数$\gamma$从0逐渐增加时，网络被配置为首先依赖局部区域的线索，然后逐渐学会将更多权重分配给更远的区域。

> While the scaling parameter $\gamma$ is increased gradually from 0 during the training, the network is configured to first rely on the cues in the local regions and then gradually learn to assign more weight to the regions that are further away.

![128×128 example images generated by SAGAN for different classes. (Image source: Partial Fig. 6 in Zhang et al., 2018 )](https://lilianweng.github.io/posts/2018-06-24-attention/SAGAN-examples.png)

引用为：

> Cited as:

```
@article{weng2018attention,
  title   = "Attention? Attention!",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-06-24-attention/"
}
```

### 参考文献

> References

[1] [“深度学习和自然语言处理中的注意力与记忆。”](http://www.wildml.com/2016/01/attention-and-memory-in-deep-learning-and-nlp/) - 2016年1月3日，作者：Denny Britz

> [1] [“Attention and Memory in Deep Learning and NLP.”](http://www.wildml.com/2016/01/attention-and-memory-in-deep-learning-and-nlp/) - Jan 3, 2016 by Denny Britz

[2] [“神经网络机器翻译 (seq2seq) 教程”](https://github.com/tensorflow/nmt)

> [2] [“Neural Machine Translation (seq2seq) Tutorial”](https://github.com/tensorflow/nmt)

[3] Dzmitry Bahdanau, Kyunghyun Cho, and Yoshua Bengio. [“通过联合学习对齐和翻译的神经网络机器翻译。”](https://arxiv.org/pdf/1409.0473.pdf) ICLR 2015.

> [3] Dzmitry Bahdanau, Kyunghyun Cho, and Yoshua Bengio. [“Neural machine translation by jointly learning to align and translate.”](https://arxiv.org/pdf/1409.0473.pdf) ICLR 2015.

[4] Kelvin Xu, Jimmy Ba, Ryan Kiros, Kyunghyun Cho, Aaron Courville, Ruslan Salakhutdinov, Rich Zemel, and Yoshua Bengio. [“展示、关注和讲述：基于视觉注意力的神经图像字幕生成。”](http://proceedings.mlr.press/v37/xuc15.pdf) ICML, 2015.

> [4] Kelvin Xu, Jimmy Ba, Ryan Kiros, Kyunghyun Cho, Aaron Courville, Ruslan Salakhudinov, Rich Zemel, and Yoshua Bengio. [“Show, attend and tell: Neural image caption generation with visual attention.”](http://proceedings.mlr.press/v37/xuc15.pdf) ICML, 2015.

[5] Ilya Sutskever, Oriol Vinyals, and Quoc V. Le. [“使用神经网络进行序列到序列学习。”](https://papers.nips.cc/paper/5346-sequence-to-sequence-learning-with-neural-networks.pdf) NIPS 2014.

> [5] Ilya Sutskever, Oriol Vinyals, and Quoc V. Le. [“Sequence to sequence learning with neural networks.”](https://papers.nips.cc/paper/5346-sequence-to-sequence-learning-with-neural-networks.pdf) NIPS 2014.

[6] Thang Luong, Hieu Pham, Christopher D. Manning. [“基于注意力的神经机器翻译的有效方法。”](https://arxiv.org/pdf/1508.04025.pdf) EMNLP 2015.

> [6] Thang Luong, Hieu Pham, Christopher D. Manning. [“Effective Approaches to Attention-based Neural Machine Translation.”](https://arxiv.org/pdf/1508.04025.pdf) EMNLP 2015.

[7] Denny Britz, Anna Goldie, Thang Luong, and Quoc Le. [“神经机器翻译架构的大规模探索。”](https://arxiv.org/abs/1703.03906) ACL 2017.

> [7] Denny Britz, Anna Goldie, Thang Luong, and Quoc Le. [“Massive exploration of neural machine translation architectures.”](https://arxiv.org/abs/1703.03906) ACL 2017.

[8] Ashish Vaswani, et al. [“注意力就是你所需要的一切。”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf) NIPS 2017.

> [8] Ashish Vaswani, et al. [“Attention is all you need.”](http://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf) NIPS 2017.

[9] Jianpeng Cheng, Li Dong, and Mirella Lapata. [“用于机器阅读的长短期记忆网络。”](https://arxiv.org/pdf/1601.06733.pdf) EMNLP 2016.

> [9] Jianpeng Cheng, Li Dong, and Mirella Lapata. [“Long short-term memory-networks for machine reading.”](https://arxiv.org/pdf/1601.06733.pdf) EMNLP 2016.

[10] Xiaolong Wang, et al. [“非局部神经网络。”](https://arxiv.org/pdf/1711.07971.pdf) CVPR 2018

> [10] Xiaolong Wang, et al. [“Non-local Neural Networks.”](https://arxiv.org/pdf/1711.07971.pdf) CVPR 2018

[11] Han Zhang, Ian Goodfellow, Dimitris Metaxas, and Augustus Odena. [“自注意力生成对抗网络。”](https://arxiv.org/pdf/1805.08318.pdf) arXiv preprint arXiv:1805.08318 (2018).

> [11] Han Zhang, Ian Goodfellow, Dimitris Metaxas, and Augustus Odena. [“Self-Attention Generative Adversarial Networks.”](https://arxiv.org/pdf/1805.08318.pdf) arXiv preprint arXiv:1805.08318 (2018).

[12] Nikhil Mishra, Mostafa Rohaninejad, Xi Chen, and Pieter Abbeel. [“一种简单的神经注意力元学习器。”](https://arxiv.org/abs/1707.03141) ICLR 2018.

> [12] Nikhil Mishra, Mostafa Rohaninejad, Xi Chen, and Pieter Abbeel. [“A simple neural attentive meta-learner.”](https://arxiv.org/abs/1707.03141) ICLR 2018.

[13] [“WaveNet：一种原始音频生成模型”](https://deepmind.com/blog/wavenet-generative-model-raw-audio/) - Sep 8, 2016 by DeepMind.

> [13] [“WaveNet: A Generative Model for Raw Audio”](https://deepmind.com/blog/wavenet-generative-model-raw-audio/) - Sep 8, 2016 by DeepMind.

[14] Oriol Vinyals, Meire Fortunato, and Navdeep Jaitly. [“指针网络。”](https://arxiv.org/abs/1506.03134) NIPS 2015.

> [14]  Oriol Vinyals, Meire Fortunato, and Navdeep Jaitly. [“Pointer networks.”](https://arxiv.org/abs/1506.03134) NIPS 2015.

[15] Alex Graves, Greg Wayne, and Ivo Danihelka. [“神经图灵机。”](https://arxiv.org/abs/1410.5401) arXiv preprint arXiv:1410.5401 (2014).

> [15] Alex Graves, Greg Wayne, and Ivo Danihelka. [“Neural turing machines.”](https://arxiv.org/abs/1410.5401) arXiv preprint arXiv:1410.5401 (2014).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Seq2Seq | 序列到序列模型 | 一种将输入序列转换为输出序列的通用模型架构，常用于机器翻译。 |
| Encoder-Decoder Architecture | 编码器-解码器架构 | Seq2Seq模型的核心组成部分，编码器处理输入，解码器生成输出。 |
| Context Vector | 上下文向量 | 编码器将输入序列压缩成的固定长度表示，用于初始化解码器。 |
| Recurrent Neural Network (RNN) | 循环神经网络 | 一种处理序列数据的神经网络，具有内部循环结构以保持信息。 |
| Neural Machine Translation (NMT) | 神经网络机器翻译 | 使用神经网络进行机器翻译的方法，注意力机制在此领域首次被引入。 |
| Alignment Score | 对齐分数 | 注意力机制中衡量输入和输出元素匹配程度的分数，用于计算权重。 |
| Self-Attention | 自注意力 | 一种关联单个序列内部不同位置的注意力机制，用于计算序列表示。 |
| Soft Attention | 软性注意力 | 对所有源输入位置学习并放置对齐权重，模型可微分但计算成本较高。 |
| Hard Attention | 硬性注意力 | 一次只选择一个源输入补丁进行关注，计算量少但模型不可微分。 |
| Neural Turing Machine (NTM) | 神经图灵机 | 将神经网络控制器与外部存储器耦合的模型架构，通过注意力机制进行读写。 |
| Pointer Network (Ptr-Net) | 指针网络 | 一种注意力机制，用于解决输出元素对应输入序列中位置的问题。 |
| Transformer | 变换器模型 | 完全基于自注意力机制的序列到序列模型，无需循环或卷积结构。 |
| Multi-Head Self-Attention | 多头自注意力 | Transformer中的核心机制，并行运行多个自注意力计算，以捕捉不同子空间的信息。 |
| Key, Value, Query | 键、值、查询 | Transformer中用于计算注意力权重的三个核心概念，分别代表信息源、信息内容和信息请求。 |
