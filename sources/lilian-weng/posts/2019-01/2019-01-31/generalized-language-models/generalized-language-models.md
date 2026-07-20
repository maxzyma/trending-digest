# 通用语言模型

> Generalized Language Models

> 来源：Lil'Log / Lilian Weng，2019-01-31
> 原文链接：https://lilianweng.github.io/posts/2019-01-31-lm/
> 分类：自然语言处理 / 语言模型

## 核心要点

- 通用语言模型通过大规模无监督预训练，在自然语言处理领域取得了显著进展，能够适应多种下游任务。
- CoVe通过神经机器翻译编码器学习上下文相关的词向量，但其预训练受限于监督翻译任务。
- ELMo利用无监督双向语言模型预训练，通过学习任务特定的线性组合来生成上下文相关的词表示，并发现不同层捕获不同类型信息。
- ULMFiT提出通用语言模型预训练、目标任务语言模型微调和分类器微调的三步法，并引入判别式微调和逐步解冻等技术。
- OpenAI GPT采用多层Transformer解码器进行生成式预训练，并通过微调相同的基本模型来适应所有下游任务，但其为单向模型。
- BERT通过引入掩码语言模型和下一句预测任务，实现了双向Transformer编码器预训练，显著提升了语言理解能力。
- ALBERT作为BERT的轻量级版本，通过分解嵌入参数化、跨层参数共享和句子顺序预测等方法，减少了参数并提高了训练效率。
- GPT-2和GPT-3进一步扩展了GPT模型的规模，并在零样本或少样本设置下，无需任务特定微调，在多项任务上展现出强大的性能。
- XLNet结合了自回归和自编码模型的优点，通过置换语言建模目标实现广义自回归预训练。
- BART和ELECTRA分别通过去噪自编码器和替换词元检测等创新预训练任务，进一步提升了语言模型的性能和训练效率。

## 正文

[2019-02-14 更新：添加 [ULMFiT](https://lilianweng.github.io/posts/2019-01-31-lm/#ulmfit) 和 [GPT-2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2)。]  

[2020-02-29 更新：添加 [ALBERT](https://lilianweng.github.io/posts/2019-01-31-lm/#albert)。]  

[2020-10-25 更新：添加 [RoBERTa](https://lilianweng.github.io/posts/2019-01-31-lm/#roberta)。]  

[2020-12-13 更新：添加 [T5](https://lilianweng.github.io/posts/2019-01-31-lm/#t5)。]  

[2020-12-30 更新：添加 [GPT-3](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-3)。]  

[2021-11-13 更新：添加 [XLNet](https://lilianweng.github.io/posts/2019-01-31-lm/#xlnet)、[BART](https://lilianweng.github.io/posts/2019-01-31-lm/#bart) 和 [ELECTRA](https://lilianweng.github.io/posts/2019-01-31-lm/#electra)；同时更新了[总结](https://lilianweng.github.io/posts/2019-01-31-lm/#summary)部分。]

> [Updated on 2019-02-14: add [ULMFiT](https://lilianweng.github.io/posts/2019-01-31-lm/#ulmfit) and [GPT-2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2).]  
>
> [Updated on 2020-02-29: add [ALBERT](https://lilianweng.github.io/posts/2019-01-31-lm/#albert).]  
>
> [Updated on 2020-10-25: add [RoBERTa](https://lilianweng.github.io/posts/2019-01-31-lm/#roberta).]  
>
> [Updated on 2020-12-13: add [T5](https://lilianweng.github.io/posts/2019-01-31-lm/#t5).]  
>
> [Updated on 2020-12-30: add [GPT-3](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-3).]  
>
> [Updated on 2021-11-13: add [XLNet](https://lilianweng.github.io/posts/2019-01-31-lm/#xlnet), [BART](https://lilianweng.github.io/posts/2019-01-31-lm/#bart) and [ELECTRA](https://lilianweng.github.io/posts/2019-01-31-lm/#electra); Also updated the [Summary](https://lilianweng.github.io/posts/2019-01-31-lm/#summary) section.]

![I guess they are Elmo & Bert? (Image source: here )](https://lilianweng.github.io/posts/2019-01-31-lm/elmo-and-bert.png)

我们在 2018 年见证了自然语言处理（NLP）领域的惊人进展。像 [OpenAI GPT](https://blog.openai.com/language-unsupervised/) 和 [BERT](https://arxiv.org/abs/1810.04805) 这样的大规模预训练语言模型，利用通用模型架构在各种语言任务上取得了出色的表现。这个想法类似于 ImageNet 分类预训练如何帮助许多视觉任务（*）。甚至比视觉分类预训练更好的是，这种在 NLP 中简单而强大的方法不需要标记数据进行预训练，这使我们能够尝试增加训练规模，直至我们的极限。

> We have seen amazing progress in NLP in 2018. Large-scale pre-trained language modes like [OpenAI GPT](https://blog.openai.com/language-unsupervised/) and [BERT](https://arxiv.org/abs/1810.04805) have achieved great performance on a variety of language tasks using generic model architectures. The idea is similar to how ImageNet classification pre-training helps many vision tasks (*). Even better than vision classification pre-training, this simple and powerful approach in NLP does not require labeled data for pre-training, allowing us to experiment with increased training scale, up to our very limit.

*（*）He 等人（2018）[发现](https://arxiv.org/abs/1811.08883)预训练对于图像分割任务可能不是必需的。*

> *(*) He et al. (2018) [found](https://arxiv.org/abs/1811.08883) that pre-training might not be necessary for image segmentation task.*

在我之前关于[词嵌入的 NLP 文章](https://lilianweng.github.io/posts/2017-10-15-word-embedding/)中，介绍的嵌入不是上下文特定的——它们是基于词共现而不是序列上下文学习的。因此，在“*I am eating an apple*”（我正在吃一个苹果）和“*I have an Apple phone*”（我有一个苹果手机）这两个句子中，两个“apple”词指代的是非常不同的事物，但它们仍然会共享相同的词嵌入向量。

> In my previous NLP [post on word embedding](https://lilianweng.github.io/posts/2017-10-15-word-embedding/), the introduced embeddings are not context-specific — they are learned based on word concurrency but not sequential context. So in two sentences, “*I am eating an apple*” and “*I have an Apple phone*”, two “apple” words refer to very different things but they would still share the same word embedding vector.

尽管如此，词嵌入在问题解决中的早期应用是将其作为现有任务特定模型的附加特征，并且这种方式的改进是有限的。

> Despite this, early adoption of word embeddings in problem-solving is to use them as additional features for an existing task-specific model and in a way the improvement is bounded.

在这篇文章中，我们将讨论如何提出各种方法，使嵌入依赖于上下文，并使其更容易、更便宜地以通用形式应用于下游任务。

> In this post, we will discuss how various approaches were proposed to make embeddings dependent on context, and to make them easier and cheaper to be applied to downstream tasks in general form.

### CoVe

> CoVe

**CoVe**（[McCann 等人 2017](https://arxiv.org/abs/1708.00107)），是**上下文词向量**的缩写，是一种由[注意力序列到序列](https://lilianweng.github.io/posts/2018-06-24-attention/#born-for-translation)机器翻译模型中的编码器学习到的词嵌入类型。
与[此处](https://lilianweng.github.io/posts/2017-10-15-word-embedding/)介绍的传统词嵌入不同，CoVe 词表示是整个输入句子的函数。

> **CoVe** ([McCann et al. 2017](https://arxiv.org/abs/1708.00107)), short for **Contextual Word Vectors**, is a type of word embeddings learned by an encoder in an [attentional seq-to-seq](https://lilianweng.github.io/posts/2018-06-24-attention/#born-for-translation) machine translation model.
> Different from traditional word embeddings introduced [here](https://lilianweng.github.io/posts/2017-10-15-word-embedding/), CoVe word representations are functions of the entire input sentence.

#### NMT 回顾

> NMT Recap

这里的神经机器翻译（[NMT](https://github.com/THUNLP-MT/MT-Reading-List)）模型由一个标准的、两层的、双向 LSTM 编码器和一个带注意力的两层单向 LSTM 解码器组成。它在英德翻译任务上进行了预训练。编码器学习并优化英语单词的嵌入向量，以便将它们翻译成德语。基于编码器在将单词转换为另一种语言之前应捕获高级语义和句法意义的直觉，编码器输出被用于为各种下游语言任务提供上下文感知的词嵌入。

> Here the Neural Machine Translation ([NMT](https://github.com/THUNLP-MT/MT-Reading-List)) model is composed of a standard, two-layer, bidirectional LSTM encoder and an attentional two-layer unidirectional LSTM decoder. It is pre-trained on the English-German translation task. The encoder learns and optimizes the embedding vectors of English words in order to translate them to German. With the intuition that the encoder should capture high-level semantic and syntactic meanings before transforming words into another language, the encoder output is used to provide contextualized word embeddings for various downstream language tasks.

![The NMT base model used in CoVe.](https://lilianweng.github.io/posts/2019-01-31-lm/nmt-recap.png)

• 源语言（英语）中的 $n$ 个词序列：$x = [x_1, \dots, x_n]$。

• 目标语言（德语）中的 $m$ 个词序列：$y = [y_1, \dots, y_m]$。

• 源词的 [GloVe](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#glove-global-vectors) 向量：$\text{GloVe}(x)$。

• 目标词的随机初始化嵌入向量：$z = [z_1, \dots, z_m]$。

• biLSTM 编码器输出一个隐藏状态序列：$h = [h_1, \dots, h_n] = \text{biLSTM}(\text{GloVe}(x))$ 和 $h_t = [\overrightarrow{h}_t; \overleftarrow{h}_t]$，其中前向 LSTM 计算 $\overrightarrow{h}_t = \text{LSTM}(x_t, \overrightarrow{h}_{t-1})$，后向计算给出 $\overleftarrow{h}_t = \text{LSTM}(x_t, \overleftarrow{h}_{t-1})$。

• 注意力解码器输出词的分布：$p(y_t \mid H, y_1, \dots, y_{t-1})$，其中 $H$ 是沿时间维度堆叠的隐藏状态 $\{h\}$：

英文原文：

• A sequence of $n$ words in source language (English): $x = [x_1, \dots, x_n]$.

• A sequence of $m$ words in target language (German): $y = [y_1, \dots, y_m]$.

• The [GloVe](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#glove-global-vectors) vectors of source words: $\text{GloVe}(x)$.

• Randomly initialized embedding vectors of target words: $z = [z_1, \dots, z_m]$.

• The biLSTM encoder outputs a sequence of hidden states: $h = [h_1, \dots, h_n] = \text{biLSTM}(\text{GloVe}(x))$ and $h_t = [\overrightarrow{h}_t; \overleftarrow{h}_t]$ where the forward LSTM computes $\overrightarrow{h}_t = \text{LSTM}(x_t, \overrightarrow{h}_{t-1})$ and the backward computation gives us $\overleftarrow{h}_t = \text{LSTM}(x_t, \overleftarrow{h}_{t-1})$.

• The attentional decoder outputs a distribution over words: $p(y_t \mid H, y_1, \dots, y_{t-1})$ where $H$ is a stack of hidden states $\{h\}$ along the time dimension:

$$
\begin{aligned}
\text{decoder hidden state: } s_t &= \text{LSTM}([z_{t-1}; \tilde{h}_{t-1}], s_{t-1}) \\
\text{attention weights: } \alpha_t &= \text{softmax}(H(W_1 s_t + b_1)) \\
\text{context-adjusted hidden state: } \tilde{h}_t &= \tanh(W_2[H^\top\alpha_t;s_t] + b_2) \\
\text{decoder output: } p(y_t\mid H, y_1, \dots, y_{t-1}) &= \text{softmax}(W_\text{out} \tilde{h}_t + b_\text{out})
\end{aligned}
$$

#### 在下游任务中使用 CoVe

> Use CoVe in Downstream Tasks

NMT 编码器的隐藏状态被定义为其他语言任务的**上下文向量**：

> The hidden states of NMT encoder are defined as **context vectors** for other language tasks:

$$
\text{CoVe}(x) = \text{biLSTM}(\text{GloVe}(x))
$$

该论文提出将 GloVe 和 CoVe 的拼接用于问答和分类任务。GloVe 从全局词共现的比率中学习，因此它没有句子上下文，而 CoVe 通过处理文本序列生成，能够捕获上下文信息。

> The paper proposed to use the concatenation of GloVe and CoVe for question-answering and classification tasks. GloVe learns from the ratios of global word co-occurrences, so it has no sentence context, while CoVe is generated by processing text sequences is able to capture the contextual information.

$$
v = [\text{GloVe}(x); \text{CoVe}(x)]
$$

给定一个下游任务，我们首先生成输入词的 GloVe + CoVe 向量的拼接，然后将它们作为附加特征输入到任务特定模型中。

> Given a downstream task, we first generate the concatenation of GloVe + CoVe vectors of input words and then feed them into the task-specific models as additional features.

![The CoVe embeddings are generated by an encoder trained for machine translation task. The encoder can be plugged into any downstream task-specific model. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/CoVe.png)

**总结**：CoVe 的局限性显而易见：（1）预训练受限于监督翻译任务上可用的数据集；（2）CoVe 对最终性能的贡献受限于任务特定的模型架构。

> **Summary**: The limitation of CoVe is obvious: (1) pre-training is bounded by available datasets on the supervised translation task; (2) the contribution of CoVe to the final performance is constrained by the task-specific model architecture.

在接下来的章节中，我们将看到 ELMo 通过无监督预训练克服了问题（1），而 OpenAI GPT 和 BERT 通过无监督预训练 + 为不同的下游任务使用生成模型架构，进一步克服了这两个问题。

> In the following sections, we will see that ELMo overcomes issue (1) by unsupervised pre-training and OpenAI GPT & BERT further overcome both problems by unsupervised pre-training + using generative model architecture for different downstream tasks.

### ELMo

> ELMo

**ELMo**，是**Embeddings from Language Model**（[Peters, et al, 2018](https://arxiv.org/abs/1802.05365)）的简称，它通过以*无监督*方式预训练语言模型来学习上下文相关的词表示。

> **ELMo**, short for **Embeddings from Language Model** ([Peters, et al, 2018](https://arxiv.org/abs/1802.05365)) learns contextualized word representation by pre-training a language model in an *unsupervised* way.

#### 双向语言模型

> Bidirectional Language Model

双向语言模型（**biLM**）是ELMo的基础。虽然输入是`n`个词元序列，$(x_1, \dots, x_n)$，但语言模型学习根据历史预测下一个词元的概率。

英文原文：The bidirectional Language Model (biLM) is the foundation for ELMo. While the input is a sequence of `n` tokens, 

$(x_1, \dots, x_n)$, the language model learns to predict the probability of next token given the history.

在前向传播中，历史记录包含目标词元之前的词语，

> In the forward pass, the history contains words before the target token,

$$
p(x_1, \dots, x_n) = \prod_{i=1}^n p(x_i \mid x_1, \dots, x_{i-1})
$$

在反向传播中，历史记录包含目标词元之后的词语，

> In the backward pass, the history contains words after the target token,

$$
p(x_1, \dots, x_n) = \prod_{i=1}^n p(x_i \mid x_{i+1}, \dots, x_n)
$$

两个方向的预测都由多层LSTM建模，其隐藏状态为$\overrightarrow{\mathbf{h}}_{i,\ell}$和$\overleftarrow{\mathbf{h}}_{i,\ell}$对于输入词元$x_i$在层级$\ell=1,\dots,L$。最终层的隐藏状态$\mathbf{h}_{i,L} = [\overrightarrow{\mathbf{h}}_{i,L}; \overleftarrow{\mathbf{h}}_{i,L}]$用于在softmax归一化后输出词元的概率。它们共享嵌入层和softmax层，分别由$\Theta_e$和$\Theta_s$参数化。

> The predictions in both directions are modeled by multi-layer LSTMs with hidden states $\overrightarrow{\mathbf{h}}_{i,\ell}$ and $\overleftarrow{\mathbf{h}}_{i,\ell}$ for input token $x_i$ at the layer level $\ell=1,\dots,L$.
> The final layer’s hidden state $\mathbf{h}_{i,L} = [\overrightarrow{\mathbf{h}}_{i,L}; \overleftarrow{\mathbf{h}}_{i,L}]$ is used to output the probabilities over tokens after softmax normalization. They share the embedding layer and the softmax layer, parameterized by $\Theta_e$ and $\Theta_s$ respectively.

![The biLSTM base model of ELMo. (Image source: recreated based on the figure in \["Neural Networks, Types, and Functional Programming"\](http://colah.github.io/posts/2015-09-NN-Types-FP/) by Christopher Olah.)](https://lilianweng.github.io/posts/2019-01-31-lm/ELMo-biLSTM.png)

该模型经过训练，旨在最小化负对数似然（即最大化真实词的对数似然），且在两个方向上进行：

> The model is trained to minimize the negative log likelihood (= maximize the log likelihood for true words) in both directions:

$$
\begin{aligned}
\mathcal{L} = - \sum_{i=1}^n \Big( 
\log p(x_i \mid x_1, \dots, x_{i-1}; \Theta_e, \overrightarrow{\Theta}_\text{LSTM}, \Theta_s) + \\
\log p(x_i \mid x_{i+1}, \dots, x_n; \Theta_e, \overleftarrow{\Theta}_\text{LSTM}, \Theta_s) \Big)
\end{aligned}
$$

#### ELMo 表示

> ELMo Representations

在 $L$ 层 biLM 的基础上，ELMo 通过学习任务特定的线性组合，将所有层中的隐藏状态堆叠在一起。令牌 $x_i$ 的隐藏状态表示包含 $2L+1$ 个向量：

> On top of a $L$ -layer biLM, ELMo stacks all the hidden states across layers together by learning a task-specific linear combination. The hidden state representation for the token $x_i$ contains $2L+1$ vectors:

$$
R_i = \{ \mathbf{h}_{i,\ell} \mid \ell = 0, \dots, L \}
$$

其中 $\mathbf{h}_{0, \ell}$ 是嵌入层输出，$\mathbf{h}_{i, \ell} = [\overrightarrow{\mathbf{h}}_{i,\ell}; \overleftarrow{\mathbf{h}}_{i,\ell}]$。

> where $\mathbf{h}_{0, \ell}$ is the embedding layer output and $\mathbf{h}_{i, \ell} = [\overrightarrow{\mathbf{h}}_{i,\ell}; \overleftarrow{\mathbf{h}}_{i,\ell}]$.

线性组合中的权重 $\mathbf{s}^\text{task}$ 针对每个最终任务进行学习，并通过 softmax 进行归一化。缩放因子 $\gamma^\text{task}$ 用于校正 biLM 隐藏状态分布与任务特定表示分布之间的错位。

> The weights, $\mathbf{s}^\text{task}$, in the linear combination are learned for each end task and normalized by softmax. The scaling factor $\gamma^\text{task}$ is used to correct the misalignment between the distribution of biLM hidden states and the distribution of task specific representations.

$$
v_i = f(R_i; \Theta^\text{task}) = \gamma^\text{task} \sum_{\ell=0}^L s^\text{task}_i \mathbf{h}_{i,\ell}
$$

为了评估不同层中的隐藏状态捕获了何种信息，ELMo 分别应用于语义密集型和语法密集型任务，使用 biLM 不同层中的表示：

> To evaluate what kind of information is captured by hidden states across different layers, ELMo is applied on semantic-intensive and syntax-intensive tasks respectively using representations in different layers of biLM:

- **语义任务**：*词义消歧 (WSD)* 任务强调给定上下文的词语含义。biLM 顶层在此任务上的表现优于第一层。
- **句法任务**：*[词性](https://en.wikipedia.org/wiki/Part-of-speech_tagging) (POS) 标注*任务旨在推断一个词在句子中的语法角色。使用 biLM 第一层可以比顶层获得更高的准确率。

> • **Semantic task**: The *word sense disambiguation (WSD)* task emphasizes the meaning of a word given a context. The biLM top layer is better at this task than the first layer.
> • **Syntax task**: The *[part-of-speech](https://en.wikipedia.org/wiki/Part-of-speech_tagging) (POS) tagging* task aims to infer the grammatical role of a word in one sentence. A higher accuracy can be achieved by using the biLM first layer than the top layer.

比较研究表明，句法信息在较低层中得到更好的表示，而语义信息则由较高层捕获。由于不同层倾向于携带不同类型的信息，*将它们堆叠在一起会有所帮助*。

> The comparison study indicates that syntactic information is better represented at lower layers while semantic information is captured by higher layers. Because different layers tend to carry different type of information, *stacking them together helps*.

#### 在下游任务中使用 ELMo

> Use ELMo in Downstream Tasks

类似于 [CoVe](https://lilianweng.github.io/posts/2019-01-31-lm/#use-cove-in-downstream-tasks) 如何帮助不同的下游任务，ELMo 嵌入向量被包含在特定任务模型的输入或较低层中。此外，对于某些任务（即 [SNLI](https://lilianweng.github.io/posts/2019-01-31-lm/#nli) 和 [SQuAD](https://lilianweng.github.io/posts/2019-01-31-lm/#qa)，但不包括 [SRL](https://lilianweng.github.io/posts/2019-01-31-lm/#srl)），将它们添加到输出层也有帮助。

> Similar to how [CoVe](https://lilianweng.github.io/posts/2019-01-31-lm/#use-cove-in-downstream-tasks) can help different downstream tasks, ELMo embedding vectors are included in the input or lower levels of task-specific models. Moreover, for some tasks (i.e., [SNLI](https://lilianweng.github.io/posts/2019-01-31-lm/#nli) and [SQuAD](https://lilianweng.github.io/posts/2019-01-31-lm/#qa), but not [SRL](https://lilianweng.github.io/posts/2019-01-31-lm/#srl)), adding them into the output level helps too.

ELMo 带来的改进对于监督数据集较小的任务最为显著。借助 ELMo，我们还可以用少得多的标注数据获得相似的性能。

> The improvements brought up by ELMo are largest for tasks with a small supervised dataset. With ELMo, we can also achieve similar performance with much less labeled data.

**总结**：语言模型预训练是无监督的，理论上预训练可以尽可能地扩展，因为未标注的文本语料库非常丰富。然而，它仍然依赖于任务定制模型，因此改进只是增量的，而为每个任务寻找一个好的模型架构仍然并非易事。

> **Summary**: The language model pre-training is unsupervised and theoretically the pre-training can be scaled up as much as possible since the unlabeled text corpora are abundant. However, it still has the dependency on task-customized models and thus the improvement is only incremental, while searching for a good model architecture for every task remains non-trivial.

### 跨视图训练

> Cross-View Training

在 ELMo 中，无监督预训练和任务特定学习发生在两个独立的模型中，分为两个独立的训练阶段。**跨视图训练**（缩写为 **CVT**；[Clark et al., 2018](https://arxiv.org/abs/1809.08370)）将它们结合成一个统一的半监督学习过程，其中 biLSTM 编码器的表示通过有标注数据的监督学习和无标注数据的辅助任务无监督学习得到改进。

> In ELMo the unsupervised pre-training and task-specific learning happen for two independent models in two separate training stages. **Cross-View Training** (abbr. **CVT**; [Clark et al., 2018](https://arxiv.org/abs/1809.08370)) combines them into one unified semi-supervised learning procedure where the representation of a biLSTM encoder is improved by both supervised learning with labeled data and unsupervised learning with unlabeled data on auxiliary tasks.

#### 模型架构

> Model Architecture

该模型由一个两层双向 LSTM 编码器和一个主要预测模块组成。在训练过程中，模型交替地接收有标注和无标注数据批次。

> The model consists of a two-layer bidirectional LSTM encoder and a primary prediction module. During training, the model is fed with labeled and unlabeled data batches alternatively.

- 在*有标注样本*上，所有模型参数都通过标准监督学习进行更新。损失是标准交叉熵。
- 在*未标记样本*上，主预测模块仍然可以生成“软”目标，尽管我们无法确切知道它们的准确性如何。在一些辅助任务中，预测器只看到并处理输入的受限视图，例如只使用一个方向的编码器隐藏状态表示。辅助任务的输出应与完整输入视图的主预测目标相匹配。  
通过这种方式，编码器被迫将完整上下文的知识提炼成部分表示。在此阶段，biLSTM 编码器进行反向传播，但主预测模块是*固定的*。损失是最小化辅助预测和主预测之间的距离。

> • On *labeled examples*, all the model parameters are updated by standard supervised learning. The loss is the standard cross entropy.
> • On *unlabeled examples*, the primary prediction module still can produce a “soft” target, even though we cannot know exactly how accurate they are. In a couple of auxiliary tasks, the predictor only sees and processes a restricted view of the input, such as only using encoder hidden state representation in one direction. The auxiliary task outputs are expected to match the primary prediction target for a full view of input.   
> In this way, the encoder is forced to distill the knowledge of the full context into partial representation. At this stage, the biLSTM encoder is backpropagated but the primary prediction module is *fixed*. The loss is to minimize the distance between auxiliary and primary predictions.

![The overview of semi-supervised language model cross-view training. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/CVT.png)

#### 多任务学习

> Multi-Task Learning

当同时训练多个任务时，CVT 会为额外任务添加几个额外的主预测模型。它们都共享相同的句子表示编码器。在有监督训练期间，一旦随机选择一个任务，其相应预测器和表示编码器中的参数就会更新。对于未标记数据样本，编码器通过最小化每个任务的辅助输出和主预测之间的差异，在所有任务中共同优化。

> When training for multiple tasks simultaneously, CVT adds several extra primary prediction models for additional tasks. They all share the same sentence representation encoder.
> During supervised training, once one task is randomly selected, parameters in its corresponding predictor and the representation encoder are updated.
> With unlabeled data samples, the encoder is optimized jointly across all the tasks by minimizing the differences between auxiliary outputs and primary prediction for every task.

多任务学习鼓励更好的表示泛化能力，同时产生了一个很好的副产品：从未标记数据中获得的所有任务标记样本。考虑到跨任务标签有用但相当稀有，它们是宝贵的数据标签。

> The multi-task learning encourages better generality of representation and in the meantime produces a nice side-product: all-tasks-labeled examples from unlabeled data. They are precious data labels considering that cross-task labels are useful but fairly rare.

#### 在下游任务中使用 CVT

> Use CVT in Downstream Tasks

理论上，主预测模块可以采取任何形式，通用或任务特定的设计。CVT 论文中提出的例子包括这两种情况。

> Theoretically the primary prediction module can take any form, generic or task-specific design. The examples presented in the CVT paper include both cases.

在序列标注任务（对每个 token 进行分类）中，例如[命名实体识别](https://lilianweng.github.io/posts/2019-01-31-lm/#ner)或[词性标注](https://lilianweng.github.io/posts/2019-01-31-lm/#pos)，预测器模块包含两个全连接层和一个输出上的 softmax 层，以生成类别标签的概率分布。对于每个 token $\mathbf{x}_i$，我们取两个层中对应的隐藏状态，$\mathbf{h}_1^{(i)}$ 和 $\mathbf{h}_2^{(i)}$：

> In sequential tagging tasks (classification for every token) like [NER](https://lilianweng.github.io/posts/2019-01-31-lm/#ner) or [POS](https://lilianweng.github.io/posts/2019-01-31-lm/#pos) tagging, the predictor module contains two fully connected layers and a softmax layer on the output to produce a probability distribution over class labels.
> For each token $\mathbf{x}_i$, we take the corresponding hidden states in two layers, $\mathbf{h}_1^{(i)}$ and $\mathbf{h}_2^{(i)}$:

$$
\begin{aligned}
p_\theta(y_i \mid \mathbf{x}_i) 
&= \text{NN}(\mathbf{h}^{(i)}) \\
&= \text{NN}([\mathbf{h}_1^{(i)}; \mathbf{h}_2^{(i)}]) \\
&= \text{softmax} \big( \mathbf{W}\cdot\text{ReLU}(\mathbf{W'}\cdot[\mathbf{h}_1^{(i)}; \mathbf{h}_2^{(i)}]) + \mathbf{b} \big)
\end{aligned}
$$

辅助任务只接收第一层的前向或后向 LSTM 状态。因为它们只观察部分上下文，无论是左侧还是右侧，它们都必须像语言模型一样学习，尝试在给定上下文的情况下预测下一个 token。`fwd` 和 `bwd` 辅助任务只采用一个方向。`future` 和 `past` 任务分别在前向和后向方向上更进一步。

> The auxiliary tasks are only fed with forward or backward LSTM state in the first layer. Because they only observe partial context, either on the left or right, they have to learn like a language model, trying to predict the next token given the context. The `fwd` and `bwd` auxiliary tasks only take one direction. The `future` and `past` tasks take one step further in forward and backward direction, respectively.

$$
\begin{aligned}
p_\theta^\text{fwd}(y_i \mid \mathbf{x}_i) &= \text{NN}^\text{fwd}(\overrightarrow{\mathbf{h}}^{(i)}) \\
p_\theta^\text{bwd}(y_i \mid \mathbf{x}_i) &= \text{NN}^\text{bwd}(\overleftarrow{\mathbf{h}}^{(i)}) \\
p_\theta^\text{future}(y_i \mid \mathbf{x}_i) &= \text{NN}^\text{future}(\overrightarrow{\mathbf{h}}^{(i-1)}) \\
p_\theta^\text{past}(y_i \mid \mathbf{x}_i) &= \text{NN}^\text{past}(\overleftarrow{\mathbf{h}}^{(i+1)})
\end{aligned}
$$

![The sequential tagging task depends on four auxiliary prediction models, their inputs only involving hidden states in one direction: forward, backward, future and past. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/CVT-example.png)

请注意，如果主预测模块包含 dropout，则在有标记数据训练时，dropout 层照常工作，但在使用未标记数据训练时为辅助任务生成“软”目标时，不应用 dropout。

> Note that if the primary prediction module has dropout, the dropout layer works as usual when training with labeled data, but it is not applied when generating “soft” target for auxiliary tasks during training with unlabeled data.

在机器翻译任务中，主预测模块被替换为带有注意力的标准单向 LSTM 解码器。有两个辅助任务：(1) 通过随机将一些值置零来对注意力权重向量应用 dropout；(2) 预测目标序列中的未来词。辅助任务要匹配的主预测是通过使用[集束搜索](https://en.wikipedia.org/wiki/Beam_search)在输入序列上运行固定的主解码器所产生的最佳预测目标序列。

> In the machine translation task, the primary prediction module is replaced with a standard unidirectional LSTM decoder with attention. There are two auxiliary tasks: (1) apply dropout on the attention weight vector by randomly zeroing out some values; (2) predict the future word in the target sequence. The primary prediction for auxiliary tasks to match is the best predicted target sequence produced by running the fixed primary decoder on the input sequence with [beam search](https://en.wikipedia.org/wiki/Beam_search).

### ULMFiT

> ULMFiT

使用生成式预训练语言模型（LM）+ 任务特定微调的想法首次在 ULMFiT ([Howard & Ruder, 2018](https://arxiv.org/abs/1801.06146)) 中探索，直接受到 ImageNet 预训练在计算机视觉任务中成功的启发。基础模型是[AWD-LSTM](https://arxiv.org/abs/1708.02182)。

> The idea of using generative pretrained LM + task-specific fine-tuning was first explored in ULMFiT ([Howard & Ruder, 2018](https://arxiv.org/abs/1801.06146)), directly motivated by the success of using ImageNet pre-training for computer vision tasks. The base model is [AWD-LSTM](https://arxiv.org/abs/1708.02182).

ULMFiT 遵循三个步骤，以在下游语言分类任务中实现良好的迁移学习结果：

> ULMFiT follows three steps to achieve good transfer learning results on downstream language classification tasks:

1.  *通用语言模型预训练*：在维基百科文本上进行。
2.  *目标任务语言模型微调*：ULMFiT 提出了两种训练技术来稳定微调过程。见下文。

> • 
> *General LM pre-training*: on Wikipedia text.
> • 
> *Target task LM fine-tuning*: ULMFiT proposed two training techniques for stabilizing the fine-tuning process. See below.

•  **判别式微调**的动机是语言模型的不同层捕获不同类型的信息（参见上面的[讨论](https://lilianweng.github.io/posts/2019-01-31-lm/#elmo-representations)）。ULMFiT 提出使用不同的学习率来调整每一层，$\{\eta^1, \dots, \eta^\ell, \dots, \eta^L\}$，其中 $\eta$ 是第一层的基本学习率，$\eta^\ell$ 是第 $\ell$ 层的学习率，总共有 $L$ 层。

•  **倾斜三角形学习率 (STLR)** 指的是一种特殊的学习率调度，它首先线性增加学习率，然后线性衰减。增加阶段较短，以便模型能够快速收敛到适合任务的参数空间，而衰减阶段较长，从而实现更好的微调。

英文原文：

• 
**Discriminative fine-tuning** is motivated by the fact that different layers of LM capture different types of information (see [discussion](https://lilianweng.github.io/posts/2019-01-31-lm/#elmo-representations) above). ULMFiT proposed to tune each layer with different learning rates, $\{\eta^1, \dots, \eta^\ell, \dots, \eta^L\}$, where $\eta$ is the base learning rate for the first layer, $\eta^\ell$ is for the $\ell$ -th layer and there are $L$ layers in total.


• 
**Slanted triangular learning rates (STLR)** refer to a special learning rate scheduling that first linearly increases the learning rate and then linearly decays it. The increase stage is short so that the model can converge to a parameter space suitable for the task fast, while the decay period is long allowing for better fine-tuning.


1. *目标任务分类器微调*：预训练的语言模型通过两个标准前馈层和末尾的 softmax 归一化进行增强，以预测目标标签分布。

> • *Target task classifier fine-tuning*: The pretrained LM is augmented with two standard feed-forward layers and a softmax normalization at the end to predict a target label distribution.

-  **连接池化**从隐藏状态的历史中提取最大池化和平均池化，并将它们与最终隐藏状态连接起来。
-  **逐步解冻**通过从最后一层开始逐步解冻模型层来帮助避免灾难性遗忘。首先，解冻最后一层并微调一个 epoch。然后，解冻下一个较低的层。重复此过程，直到所有层都经过调整。

> • 
> **Concat pooling** extracts max-polling and mean-pooling over the history of hidden states and concatenates them with the final hidden state.
> • 
> **Gradual unfreezing** helps to avoid catastrophic forgetting by gradually unfreezing the model layers starting from the last one. First the last layer is unfrozen and fine-tuned for one epoch. Then the next lower layer is unfrozen. This process is repeated until all the layers are tuned.

![Three training stages of ULMFiT. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/ULMFiT.png)

### GPT

> GPT

遵循 ELMo 的类似思想，OpenAI **GPT**，即**生成式预训练 Transformer** ([Radford et al., 2018](https://s3-us-west-2.amazonaws.com/openai-assets/research-covers/language-unsupervised/language_understanding_paper.pdf)) 的缩写，通过在大量自由文本语料库上进行训练，将无监督语言模型扩展到更大的规模。尽管有相似之处，GPT 与 ELMo 存在两个主要差异。

> Following the similar idea of ELMo, OpenAI **GPT**, short for **Generative Pre-training Transformer** ([Radford et al., 2018](https://s3-us-west-2.amazonaws.com/openai-assets/research-covers/language-unsupervised/language_understanding_paper.pdf)), expands the unsupervised language model to a much larger scale by training on a giant collection of free text corpora. Despite of the similarity, GPT has two major differences from ELMo.

1. 模型架构不同：ELMo 使用独立训练的从左到右和从右到左的多层 LSTM 的浅层连接，而 GPT 是一个多层 Transformer 解码器。
2. 上下文嵌入在下游任务中的使用方式不同：ELMo 将嵌入作为附加特征输入到为特定任务定制的模型中，而 GPT 则为所有最终任务微调相同的基本模型。

> • The model architectures are different: ELMo uses a shallow concatenation of independently trained left-to-right and right-to-left multi-layer LSTMs, while GPT is a multi-layer transformer decoder.
> • The use of contextualized embeddings in downstream tasks are different: ELMo feeds embeddings into models customized for specific tasks as additional features, while GPT fine-tunes the same base model for all end tasks.

#### 作为语言模型的 Transformer 解码器

> Transformer Decoder as Language Model

与[原始 Transformer](https://arxiv.org/abs/1706.03762) 架构相比，[Transformer 解码器](https://arxiv.org/abs/1801.10198)模型舍弃了编码器部分，因此只有一个输入句子，而不是两个独立的原序列和目标序列。

> Compared to the [original transformer](https://arxiv.org/abs/1706.03762) architecture, the [transformer decoder](https://arxiv.org/abs/1801.10198) model discards the encoder part, so there is only one single input sentence rather than two separate source and target sequences.

该模型在输入序列的嵌入上应用多个 Transformer 块。每个块包含一个掩码*多头自注意力*层和一个*逐点前馈*层。最终输出在 softmax 归一化后生成目标 token 的分布。

> This model applies multiple transformer blocks over the embeddings of input sequences. Each block contains a masked *multi-headed self-attention* layer and a *pointwise feed-forward* layer. The final output produces a distribution over target tokens after softmax normalization.

![The transformer decoder model architecture in OpenAI GPT.](https://lilianweng.github.io/posts/2019-01-31-lm/OpenAI-GPT-transformer-decoder.png)

损失是负对数似然，与[ELMo](https://lilianweng.github.io/posts/2019-01-31-lm/#elmo)相同，但没有反向计算。假设大小为 $k$ 的上下文窗口位于目标词之前，则损失将如下所示：

> The loss is the negative log-likelihood, same as [ELMo](https://lilianweng.github.io/posts/2019-01-31-lm/#elmo), but without backward computation. Let’s say, the context window of the size $k$ is located before the target word and the loss would look like:

$$
\mathcal{L}_\text{LM} = -\sum_{i} \log p(x_i\mid x_{i-k}, \dots, x_{i-1})
$$

#### 字节对编码

> Byte Pair Encoding

**字节对编码** ([BPE](https://arxiv.org/abs/1508.07909)) 用于编码输入序列。BPE 最初在 1990 年代被提出作为一种数据压缩算法，后来被采纳以解决机器翻译中的开放词汇问题，因为在翻译成新语言时，我们很容易遇到稀有词和未知词。受稀有词和未知词通常可以分解为多个子词的直觉启发，BPE 通过迭代和贪婪地合并频繁的字符对来找到最佳的词分割。

> **Byte Pair Encoding** ([BPE](https://arxiv.org/abs/1508.07909)) is used to encode the input sequences. BPE was originally proposed as a data compression algorithm in 1990s and then was adopted to solve the open-vocabulary issue in machine translation, as we can easily run into rare and unknown words when translating into a new language. Motivated by the intuition that rare and unknown words can often be decomposed into multiple subwords, BPE finds the best word segmentation by iteratively and greedily merging frequent pairs of characters.

#### 有监督微调

> Supervised Fine-Tuning

OpenAI GPT 提出的最实质性的升级是摆脱任务特定模型，直接使用预训练语言模型！

> The most substantial upgrade that OpenAI GPT proposed is to get rid of the task-specific model and use the pre-trained language model directly!

以分类为例。假设在标记数据集中，每个输入有 $n$ 个 token，$\mathbf{x} = (x_1, \dots, x_n)$，以及一个标签 $y$。GPT 首先通过预训练的 Transformer 解码器处理输入序列 $\mathbf{x}$，最后一个 token $x_n$ 的最后一层输出是 $\mathbf{h}_L^{(n)}$。然后，仅使用一个新的可训练权重矩阵 $\mathbf{W}_y$，它就可以预测类别标签的分布。

> Let’s take classification as an example. Say, in the labeled dataset, each input has $n$ tokens, $\mathbf{x} = (x_1, \dots, x_n)$, and one label $y$. GPT first processes the input sequence $\mathbf{x}$ through the pre-trained transformer decoder and the last layer output for the last token $x_n$ is $\mathbf{h}_L^{(n)}$. Then with only one new trainable weight matrix $\mathbf{W}_y$, it can predict a distribution over class labels.

![Training objects in slightly modified GPT transformer models for downstream tasks. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/GPT-classification.png)

$$
P(y\mid x_1, \dots, x_n) = \text{softmax}(\mathbf{h}_L^{(n)}\mathbf{W}_y)
$$

损失是最小化真实标签的负对数似然。此外，将语言模型损失作为辅助损失被发现是有益的，因为：

> The loss is to minimize the negative log-likelihood for true labels. In addition, adding the LM loss as an auxiliary loss is found to be beneficial, because:

- (1) 它有助于加速训练期间的收敛，并且
- (2) 有望提高有监督模型的泛化能力。

> • (1) it helps accelerate convergence during training and
> • (2) it is expected to improve the generalization of the supervised model.

$$
\begin{aligned}
\mathcal{L}_\text{cls} &= \sum_{(\mathbf{x}, y) \in \mathcal{D}} \log P(y\mid x_1, \dots, x_n) = \sum_{(\mathbf{x}, y) \in \mathcal{D}} \log \text{softmax}(\mathbf{h}_L^{(n)}(\mathbf{x})\mathbf{W}_y) \\
\mathcal{L}_\text{LM} &= -\sum_{i} \log p(x_i\mid x_{i-k}, \dots, x_{i-1}) \\
\mathcal{L} &= \mathcal{L}_\text{cls} + \lambda \mathcal{L}_\text{LM}
\end{aligned}
$$

通过类似的设计，其他最终任务不需要定制的模型结构（参见图 7）。如果任务输入包含多个句子，则在每对句子之间添加一个特殊的分隔符 token (`$`)。这个分隔符 token 的嵌入是我们学习的新参数，但它应该非常小。

> With similar designs, no customized model structure is needed for other end tasks (see Fig. 7). If the task input contains multiple sentences, a special delimiter token (`$`) is added between each pair of sentences. The embedding for this delimiter token is a new parameter we need to learn, but it should be pretty minimal.

对于句子相似性任务，由于顺序无关紧要，因此包含两种顺序。对于多项选择任务，上下文与每个答案候选配对。

> For the sentence similarity task, because the ordering does not matter, both orderings are included. For the multiple choice task, the context is paired with every answer candidate.

![Training objects in slightly modified GPT transformer models for downstream tasks. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/GPT-downstream-tasks.png)

**总结**：看到这样一个通用框架能够在当时（2018 年 6 月）的大多数语言任务上超越 SOTA，真是令人惊叹和鼓舞。在第一阶段，语言模型的生成式预训练可以吸收尽可能多的自由文本。然后在第二阶段，模型在特定任务上进行微调，使用少量标记数据集和最少的新参数进行学习。

> **Summary**: It is super neat and encouraging to see that such a general framework is capable to beat SOTA on most language tasks at that time (June 2018). At the first stage, generative pre-training of a language model can absorb as much free text as possible. Then at the second stage, the model is fine-tuned on specific tasks with a small labeled dataset and a minimal set of new parameters to learn.

GPT 的一个局限性是其单向性——模型只被训练来预测未来的从左到右的上下文。

> One limitation of GPT is its uni-directional nature — the model is only trained to predict the future left-to-right context.

### BERT

> BERT

**BERT**，即**来自 Transformers 的双向编码器表示** ([Devlin, et al., 2019](https://arxiv.org/abs/1810.04805)) 的缩写，是[GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt)的直接继承者：在自由文本上训练一个大型语言模型，然后针对特定任务进行微调，而无需定制网络架构。

> **BERT**, short for **Bidirectional Encoder Representations from Transformers** ([Devlin, et al., 2019](https://arxiv.org/abs/1810.04805)) is a direct descendant to [GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt): train a large language model on free text and then fine-tune on specific tasks without customized network architectures.

与 GPT 相比，BERT 最大的不同和改进是使训练变为**双向**。模型学习预测左侧和右侧的上下文。该论文根据消融研究声称：

> Compared to GPT, the largest difference and improvement of BERT is to make training **bi-directional**. The model learns to predict both context on the left and right. The paper according to the ablation study claimed that:

> “我们模型的双向性是唯一最重要的新的贡献”

> “bidirectional nature of our model is the single most important new contribution”

#### 预训练任务

> Pre-training Tasks

BERT 的模型架构是一个多层双向 Transformer 编码器。

> The model architecture of BERT is a multi-layer bidirectional Transformer encoder.

![Recap of Transformer Encoder model architecture. (Image source: Transformer paper )](https://lilianweng.github.io/posts/2019-01-31-lm/transformer-encoder-2.png)

为了鼓励双向预测和句子级别的理解，BERT 采用两项任务进行训练，而不是基本的语言任务（即，在给定上下文的情况下预测下一个 token）。

> To encourage the bi-directional prediction and sentence-level understanding, BERT is trained with two tasks instead of the basic language task (that is, to predict the next token given context).

***任务 1：掩码语言模型 (MLM)**

> ***Task 1: Mask language model (MLM)**

> 引自 [维基百科](https://en.wikipedia.org/wiki/Cloze_test)：“完形填空（也称完形删除测试）是一种练习、测试或评估，它由一段语言组成，其中某些项目、单词或符号被移除（完形文本），参与者被要求替换缺失的语言项目。……这项练习最早由 W.L. Taylor 于 1953 年描述。”

> From [Wikipedia](https://en.wikipedia.org/wiki/Cloze_test): “A cloze test (also cloze deletion test) is an exercise, test, or assessment consisting of a portion of language with certain items, words, or signs removed (cloze text), where the participant is asked to replace the missing language item. … The exercise was first described by W.L. Taylor in 1953.”

不难相信，一个学习单词周围而非仅仅是单词之后上下文的表示，能够更好地捕捉其句法和语义上的含义。BERT 通过训练 *“掩码语言模型”任务*来鼓励模型这样做：

> It is unsurprising to believe that a representation that learns the context around a word rather than just after the word is able to better capture its meaning, both syntactically and semantically. BERT encourages the model to do so by training on the *“mask language model” task*:

1. 在每个序列中随机掩码 15% 的 token。因为如果我们只用一个特殊占位符 `[MASK]` 替换被掩码的 token，那么在微调期间将永远不会遇到这个特殊 token。因此，BERT 采用了几种启发式技巧：


   - (a) 以 80% 的概率，用 `[MASK]` 替换选定的词；
   - (b) 以 10% 的概率，替换为随机词；
   - (c) 以 10% 的概率，保持不变。
2. 模型只预测缺失的词，但它不知道哪些词被替换了，也不知道哪些词应该被预测。输出大小仅为输入大小的 15%。

> • Randomly mask 15% of tokens in each sequence. Because if we only replace masked tokens with a special placeholder `[MASK]`, the special token would never be encountered during fine-tuning. Hence, BERT employed several heuristic tricks:
>

> ◦ (a) with 80% probability, replace the chosen words with `[MASK]`;

> ◦ (b) with 10% probability, replace with a random word;

> ◦ (c) with 10% probability, keep it the same.

> • The model only predicts the missing words, but it has no information on which words have been replaced or which words should be predicted. The output size is only 15% of the input size.

**任务 2：下一句预测**

> **Task 2: Next sentence prediction**

鉴于许多下游任务涉及理解句子之间的关系（即 [问答](https://lilianweng.github.io/posts/2019-01-31-lm/#qa)、[自然语言推理](https://lilianweng.github.io/posts/2019-01-31-lm/#nli)），BERT 添加了另一个辅助任务，即训练一个 *二元分类器*来判断一个句子是否是另一个句子的下一句：

> Motivated by the fact that many downstream tasks involve the understanding of relationships between sentences (i.e., [QA](https://lilianweng.github.io/posts/2019-01-31-lm/#qa), [NLI](https://lilianweng.github.io/posts/2019-01-31-lm/#nli)), BERT added another auxiliary task on training a *binary classifier* for telling whether one sentence is the next sentence of the other:

1. 采样句子对 (A, B)，使得：


   - (a) 50% 的情况下，B 紧跟在 A 之后；
   - (b) 50% 的情况下，B 不紧跟在 A 之后。
2. 模型处理这两个句子并输出一个二元标签，指示 B 是否是 A 的下一句。

> • Sample sentence pairs (A, B) so that:
>

> ◦ (a) 50% of the time, B follows A;

> ◦ (b) 50% of the time, B does not follow A.

> • The model processes both sentences and output a binary label indicating whether B is the next sentence of A.

上述两项辅助任务的训练数据可以很容易地从任何单语语料库中生成。因此，训练规模是无限的。训练损失是平均掩码语言模型似然和平均下一句预测似然之和。

> The training data for both auxiliary tasks above can be trivially generated from any monolingual corpus. Hence the scale of training is unbounded. The training loss is the sum of the mean masked LM likelihood and mean next sentence prediction likelihood.

![Comparison of BERT, OpenAI GPT and ELMo model architectures. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/language-model-comparison.png)

#### 输入嵌入

> Input Embedding

输入嵌入是以下三部分之和：

> The input embedding is the sum of three parts:

1. *WordPiece 分词嵌入*：[WordPiece](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/37842.pdf) [模型](https://arxiv.org/pdf/1609.08144.pdf)最初是为日语或韩语分词问题提出的。它不使用自然分割的英语单词，而是将它们进一步划分为更小的子词单元，以便更有效地处理稀有词或未知词。如果感兴趣，请阅读[相关](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/37842.pdf)[论文](https://arxiv.org/pdf/1609.08144.pdf)以了解最佳分词方法。
2. *段落嵌入*：如果输入包含两个句子，它们分别具有句子 A 嵌入和句子 B 嵌入，并由一个特殊字符 `[SEP]` 分隔；如果输入只包含一个句子，则只使用句子 A 嵌入。
3. *位置嵌入*：位置嵌入是学习得到的，而不是硬编码的。

> • *WordPiece tokenization embeddings*: The [WordPiece](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/37842.pdf) [model](https://arxiv.org/pdf/1609.08144.pdf) was originally proposed for Japanese or Korean segmentation problem. Instead of using naturally split English word, they can be further divided into smaller sub-word units so that it is more effective to handle rare or unknown words. Please read [linked](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/37842.pdf) [papers](https://arxiv.org/pdf/1609.08144.pdf) for the optimal way to split words if interested.
> • *Segment embeddings*: If the input contains two sentences, they have sentence A embeddings and sentence B embeddings respectively and they are separated by a special character `[SEP]`; Only sentence A embeddings are used if the input only contains one sentence.
> • *Position embeddings*: Positional embeddings are learned rather than hard-coded.

![BERT input representation. (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/BERT-input-embedding.png)

请注意，第一个 token 总是被强制设为 `[CLS]`——这是一个占位符，稍后将在下游任务中用于预测。

> Note that the first token is always forced to be `[CLS]` — a placeholder that will be used later for prediction in downstream tasks.

#### 在下游任务中使用 BERT

> Use BERT in Downstream Tasks

BERT 微调只需要添加少量新参数，就像 OpenAI GPT 一样。

> BERT fine-tuning requires only a few new parameters added, just like OpenAI GPT.

对于分类任务，我们通过获取特殊第一个 token `[CLS]` 的最终隐藏状态 $\mathbf{h}^\text{[CLS]}_L$，并将其与一个小的权重矩阵 $\text{softmax}(\mathbf{h}^\text{[CLS]}_L \mathbf{W}_\text{cls})$ 相乘来获得预测。

> For classification tasks, we get the prediction by taking the final hidden state of the special first token `[CLS]`, $\mathbf{h}^\text{[CLS]}_L$, and multiplying it with a small weight matrix, $\text{softmax}(\mathbf{h}^\text{[CLS]}_L \mathbf{W}_\text{cls})$.

对于像 SQuAD 这样的 [问答](https://lilianweng.github.io/posts/2019-01-31-lm/#qa) 任务，我们需要预测给定段落中针对给定问题的文本跨度。BERT 预测每个 token 的两个概率分布，分别是文本跨度的开始和结束。在微调期间只学习了两个新的小矩阵 $\mathbf{W}_\text{s}$ 和 $\mathbf{W}_\text{e}$，而 $\text{softmax}(\mathbf{h}^\text{(i)}_L \mathbf{W}_\text{s})$ 和 $\text{softmax}(\mathbf{h}^\text{(i)}_L \mathbf{W}_\text{e})$ 定义了两个概率分布。

> For [QA](https://lilianweng.github.io/posts/2019-01-31-lm/#qa) tasks like SQuAD, we need to predict the text span in the given paragraph for an given question. BERT predicts two probability distributions of every token, being the start and the end of the text span. Only two new small matrices, $\mathbf{W}_\text{s}$ and $\mathbf{W}_\text{e}$, are newly learned during fine-tuning and $\text{softmax}(\mathbf{h}^\text{(i)}_L \mathbf{W}_\text{s})$ and $\text{softmax}(\mathbf{h}^\text{(i)}_L \mathbf{W}_\text{e})$ define two probability distributions.

总的来说，用于最终任务微调的附加部分非常少——一到两个权重矩阵用于将 Transformer 隐藏状态转换为可解释的格式。其他情况的实现细节请查阅论文。

> Overall the add-on part for end task fine-tuning is very minimal — one or two weight matrices to convert the Transform hidden states to an interpretable format. Check the paper for implementation details for other cases.

![Training objects in slightly modified BERT models for downstream tasks.  (Image source: original paper )](https://lilianweng.github.io/posts/2019-01-31-lm/BERT-downstream-tasks.png)

下表总结了 [OpenAI GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt) 和 BERT 微调之间的差异。

> A summary table compares differences between fine-tuning of [OpenAI GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt) and BERT.

|              | **OpenAI GPT** | **BERT** |
| --- | --- | --- |
| 特殊字符 | `[SEP]` 和 `[CLS]` 仅在微调阶段引入。 | `[SEP]` 和 `[CLS]` 以及句子 A/B 嵌入在预训练阶段学习。 |
| 训练过程 | 1M 步，批大小 32k 词。 | 1M 步，批大小 128k 词。 |
| 微调 | 所有微调任务的 lr = 5e-5。 | 微调使用任务特定的 lr。 |

> 英文原表 / English original

|              | **OpenAI GPT** | **BERT** |
| --- | --- | --- |
| Special char | `[SEP]` and `[CLS]` are only introduced at fine-tuning stage. | `[SEP]` and `[CLS]` and sentence A/B embeddings are learned at the pre-training stage. |
| Training process | 1M steps, batch size 32k words. | 1M steps, batch size 128k words. |
| Fine-tuning  | lr = 5e-5 for all fine-tuning tasks. | Use task-specific lr for fine-tuning. |

### ALBERT

> ALBERT

**ALBERT**（[Lan 等人，2019](https://arxiv.org/abs/1909.11942)），是 **A Lite BERT** 的缩写，是 [BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#BERT) 模型的一个轻量级版本。与配置相似的 BERT 模型相比，ALBERT 模型训练速度快 1.7 倍，参数少 18 倍。ALBERT 包含了以下三项改进：前两项有助于减少参数和内存消耗，从而加快训练速度，而第三项则提出了一个更具挑战性的训练任务来取代下一句预测 (NSP) 目标。

> **ALBERT** ([Lan, et al. 2019](https://arxiv.org/abs/1909.11942)), short for **A Lite BERT**, is a light-weighted version of [BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#BERT) model. An ALBERT model can be trained 1.7x faster with 18x fewer parameters, compared to a BERT model of similar configuration. ALBERT incorporates three changes as follows: the first two help reduce parameters and memory consumption and hence speed up the training speed, while the third one proposes a more chanllenging training task to replace the next sentence prediction (NSP) objective.

#### 分解嵌入参数化

> Factorized Embedding Parameterization

在 BERT 中，WordPiece 分词嵌入大小 $E$ 被配置为与隐藏状态大小 $H$ 相同。也就是说，如果我们想增加模型大小（更大的 $H$），我们也需要学习更大的分词嵌入，这很昂贵，因为它取决于词汇量大小 ($V$)。

> In BERT, the WordPiece tokenization embedding size $E$ is configured to be the same as the hidden state size $H$. That is saying, if we want to increase the model size (larger $H$), we need to learn a larger tokenization embedding too, which is expensive because it depends on the vocabulary size ($V$).

从概念上讲，由于分词嵌入旨在学习*上下文无关*的表示，而隐藏状态是*上下文相关*的，因此将隐藏层的大小与词汇嵌入的大小分开是有意义的。使用分解嵌入参数化，大小为 $V \times H$ 的大词汇嵌入矩阵被分解为大小为 $V \times E$ 和 $E \times H$ 的两个小矩阵。给定 $H \gt E$ 甚至 $H \gg E$，分解可以显著减少参数。

> Conceptually, because the tokenization embedding is expected to learn *context-independent* representation and the hidden states are *context-dependent*, it makes sense to separate the size of the hidden layers from the size of vocabulary embedding. Using factorized embedding parameterization, the large vocabulary embedding matrix of size $V \times H$ is decomposed into two small matrices of size $V \times E$ and $E \times H$. Given $H \gt E$ or even $H \gg E$, factorization can result in significant parameter reduction.

#### 跨层参数共享

> Cross-layer Parameter Sharing

跨层参数共享可以通过多种方式实现：(a) 只共享前馈部分；(b) 只共享注意力参数；或 (c) 共享所有参数。这项技术大大减少了参数数量，并且对性能的损害不大。

> Parameter sharing across layers can happen in many ways: (a) only share feed-forward part; (b) only share attention parameters; or (c) share all the parameters. This technique reduces the number of parameters by a ton and does not damage the performance too much.

#### 句子顺序预测 (SOP)

> Sentence-Order Prediction (SOP)

有趣的是，BERT 的 [下一句预测 (NSP)](https://lilianweng.github.io/posts/2019-01-31-lm/#NSP) 任务被证明过于简单。ALBERT 转而采用了句子顺序预测 (SOP) [自监督](https://lilianweng.github.io/posts/2019-11-10-self-supervised/) 损失，

> Interestingly, the [next sentence prediction (NSP)](https://lilianweng.github.io/posts/2019-01-31-lm/#NSP) task of BERT turned out to be too easy. ALBERT instead adopted a sentence-order prediction (SOP) [self-supervised](https://lilianweng.github.io/posts/2019-11-10-self-supervised/) loss,

- 正样本：来自同一文档的两个连续片段。
- 负样本：与上述相同，但片段顺序被调换。

> • Positive sample: two consecutive segments from the same document.
> • Negative sample: same as above, but the segment order is switched.

对于 NSP 任务，如果模型能够检测到 A 和 B 来自不同上下文时的主题，它就可以做出合理的预测。相比之下，SOP 更难，因为它要求模型完全理解片段之间的连贯性和顺序。

> For the NSP task, the model can make reasonable predictions if it is able to detect topics when A and B are from different contexts. In comparison, SOP is harder as it requires the model to fully understand the coherence and ordering between segments.

### GPT-2

> GPT-2

[OpenAI](https://blog.openai.com/better-language-models/) [GPT-2](https://d4mucfpksywv.cloudfront.net/better-language-models/language_models_are_unsupervised_multitask_learners.pdf) 语言模型是 [GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt) 的直接继承者。GPT-2 拥有 15 亿参数，是原始 GPT 的 10 倍，并且在 *零样本迁移设置*下，无需任何任务特定微调，在 8 个测试的语言建模数据集中有 7 个取得了 SOTA 结果。预训练数据集包含通过抓取 [Reddit](https://www.reddit.com/) 上合格的出站链接收集的 800 万个网页。OpenAI GPT-2 的显著改进在小型数据集和用于衡量 *长期依赖*的数据集上尤为明显。

> The [OpenAI](https://blog.openai.com/better-language-models/) [GPT-2](https://d4mucfpksywv.cloudfront.net/better-language-models/language_models_are_unsupervised_multitask_learners.pdf) language model is a direct successor to [GPT](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt). GPT-2 has 1.5B parameters, 10x more than the original GPT, and it achieves SOTA results on 7 out of 8 tested language modeling datasets in a *zero-shot transfer setting* without any task-specific fine-tuning. The pre-training dataset contains 8 million Web pages collected by crawling qualified outbound links from [Reddit](https://www.reddit.com/). Large improvements by OpenAI GPT-2 are specially noticeable on small datasets and datasets used for measuring *long-term dependency*.

#### 零样本迁移

> Zero-Shot Transfer

GPT-2 的预训练任务纯粹是语言建模。所有下游语言任务都被框定为预测条件概率，并且没有任务特定的微调。

> The pre-training task for GPT-2 is solely language modeling. All the downstream language tasks are framed as predicting conditional probabilities and there is no task-specific fine-tuning.

- 使用语言模型进行文本生成是直接的。
- 机器翻译任务，例如英译中，是通过将语言模型条件化在“English sentence = Chinese sentence”对和末尾的“the target English sentence =”上实现的。


   - 例如，要预测的条件概率可能看起来像：`P(? | I like green apples. = 我喜欢绿苹果。 A cat meows at him. = 一只猫对他喵。It is raining cats and dogs. =")`
- 问答任务的格式与翻译类似，在上下文中包含成对的问题和答案。
- 通过在上下文中的文章后添加 `TL;DR:` 来引入摘要任务。

> • Text generation is straightforward using LM.

> • Machine translation task, for example, English to Chinese, is induced by conditioning LM on pairs of “English sentence = Chinese sentence” and “the target English sentence =” at the end.
>

> ◦ For example, the conditional probability to predict might look like: `P(? | I like green apples. = 我喜欢绿苹果。 A cat meows at him. = 一只猫对他喵。It is raining cats and dogs. =")`

> • QA task is formatted similar to translation with pairs of questions and answers in the context.

> • Summarization task is induced by adding `TL;DR:` after the articles in the context.

#### 字节序列上的 BPE

> BPE on Byte Sequences

与原始 GPT 相同，GPT-2 使用 [BPE](https://lilianweng.github.io/posts/2019-01-31-lm/#byte-pair-encoding)，但作用于 [UTF-8](https://en.wikipedia.org/wiki/UTF-8) 字节序列。每个字节在 8 位中可以表示 256 个不同的值，而 UTF-8 最多可以使用 4 个字节表示一个字符，总共支持多达 $2^{31}$ 个字符。因此，使用字节序列表示，我们只需要一个大小为 256 的词汇表，并且无需担心预处理、分词等问题。尽管有这些优点，但当前的字节级语言模型与最先进的词级语言模型之间仍然存在不可忽视的性能差距。

> Same as the original GPT, GPT-2 uses [BPE](https://lilianweng.github.io/posts/2019-01-31-lm/#byte-pair-encoding) but on [UTF-8](https://en.wikipedia.org/wiki/UTF-8) byte sequences. Each byte can represent 256 different values in 8 bits, while UTF-8 can use up to 4 bytes for one character, supporting up to $2^{31}$ characters in total. Therefore, with byte sequence representation we only need a vocabulary of size 256 and do not need to worry about pre-processing, tokenization, etc. Despite of the benefit, current byte-level LMs still have non-negligible performance gap with the SOTA word-level LMs.

BPE 以贪婪的方式合并频繁共同出现的字节对。为了防止它为常用词（例如，`dog.`、`dog!` 和 `dog?` 对应词 `dog`）生成多个版本，GPT-2 阻止 BPE 跨类别合并字符（因此 `dog` 不会与 `.`、`!` 和 `?` 等标点符号合并）。这些技巧有助于提高最终字节分割的质量。

> BPE merges frequently co-occurred byte pairs in a greedy manner. To prevent it from generating multiple versions of common words (i.e. `dog.`, `dog!` and `dog?` for the word `dog`), GPT-2 prevents BPE from merging characters across categories (thus `dog` would not be merged with punctuations like `.`, `!` and `?`). This tricks help increase the quality of the final byte segmentation.

使用字节序列表示，GPT-2 能够为任何 Unicode 字符串分配概率，而无需任何预处理步骤。

> Using the byte sequence representation, GPT-2 is able to assign a probability to any Unicode string, regardless of any pre-processing steps.

#### 模型修改

> Model Modifications

与 GPT 相比，除了拥有更多的 Transformer 层和参数外，GPT-2 只包含少数架构修改：

> Compared to GPT, other than having many more transformer layers and parameters, GPT-2 incorporates only a few architecture modifications:

• [层归一化](https://arxiv.org/abs/1607.06450)被移至每个子块的输入端，类似于[“building block”](https://arxiv.org/abs/1603.05027)类型的残差单元（与原始的[“bottleneck”](https://arxiv.org/abs/1512.03385)类型不同，它在权重层之前应用了批归一化）。

• 在最终的自注意力块之后添加了一个额外的层归一化。

• 修改后的初始化是根据模型深度构建的。

• 残差层的权重最初按 $1/ \sqrt{N}$ 的因子进行缩放，其中 N 是残差层的数量。

• 使用更大的词汇量和上下文大小。

英文原文：

• [Layer normalization](https://arxiv.org/abs/1607.06450) was moved to the input of each sub-block, similar to a residual unit of type [“building block”](https://arxiv.org/abs/1603.05027) (differently from the original type [“bottleneck”](https://arxiv.org/abs/1512.03385), it has batch normalization applied before weight layers).

• An additional layer normalization was added after the final self-attention block.

• A modified initialization was constructed as a function of the model depth.

• The weights of residual layers were initially scaled by a factor of $1/ \sqrt{N}$ where N is the number of residual layers.

• Use larger vocabulary size and context size.

### RoBERTa

> RoBERTa

**RoBERTa**（是 **R**obustly **o**ptimized **BERT** **a**pproach 的缩写；[Liu, et al. 2019](https://arxiv.org/abs/1907.11692)）指的是一种训练 BERT 以获得更好结果的新方法，因为他们发现原始 BERT 模型存在显著的训练不足。该方法包含以下经验：

> **RoBERTa** (short for **R**obustly **o**ptimized **BERT** **a**pproach; [Liu, et al. 2019](https://arxiv.org/abs/1907.11692)) refers to a new receipt for training BERT to achieve better results, as they found that the original BERT model is significantly undertrained. The receipt contains the following learnings:

1. 使用更大的批次大小进行更长时间的训练。
2. 移除 [下一句预测 (NSP)](https://lilianweng.github.io/posts/2019-01-31-lm/#nsp) 任务。
3. 在训练数据格式中使用更长的序列。该论文发现，使用单个句子作为输入会损害下游性能。相反，我们应该使用连续采样的多个句子来形成更长的片段。
4. 动态改变掩码模式。原始 BERT 在数据预处理阶段只应用一次掩码，导致在训练周期中掩码是静态的。RoBERTa 在 40 个周期中以 10 种不同的方式应用掩码。

> • Train for longer with bigger batch size.
> • Remove the [next sentence prediction (NSP)](https://lilianweng.github.io/posts/2019-01-31-lm/#nsp) task.
> • Use longer sequences in training data format. The paper found that using individual sentences as inputs hurts downstream performance. Instead we should use multiple sentences sampled contiguously to form longer segments.
> • Change the masking pattern dynamically. The original BERT applies masking once during the data preprocessing stage, resulting in a static mask across training epochs. RoBERTa applies masks in 10 different ways across 40 epochs.

RoBERTa 还添加了一个新数据集 [CommonCrawl News](https://commoncrawl.org/2016/10/news-dataset-available/)，并进一步证实使用 *更多数据进行预训练有助于* 提高下游任务的性能。它使用 [字节序列上的 BPE](https://lilianweng.github.io/posts/2019-01-31-lm/#bpe-on-byte-sequences) 进行训练，与 [GPT-2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2) 中相同。他们还发现超参数的选择对模型性能有很大影响。

> RoBERTa also added a new dataset [CommonCrawl News](https://commoncrawl.org/2016/10/news-dataset-available/) and further confirmed that pretraining with *more data helps* improve the performance on downstream tasks. It was trained with the [BPE on byte sequences](https://lilianweng.github.io/posts/2019-01-31-lm/#bpe-on-byte-sequences), same as in [GPT-2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2). They also found that choices of hyperparameters have a big impact on the model performance.

### T5

> T5

语言模型 **T5** 是 **“Text-to-Text Transfer Transformer”**（[Raffel et al., 2020](https://arxiv.org/abs/1910.10683)）的缩写。其编码器-解码器实现遵循 [原始 Transformer](https://arxiv.org/abs/1706.03762) 架构：tokens → embedding → encoder → decoder → output。T5 采用了“自然语言十项全能”（[McCann et al., 2018](https://arxiv.org/abs/1806.08730)）框架，其中许多常见的 NLP 任务被转换为基于上下文的问答。T5 没有使用明确的问答格式，而是使用简短的任务前缀来区分任务意图，并针对每个单独的任务分别对模型进行微调。文本到文本框架使得在各种任务上使用相同模型进行迁移学习评估变得更加容易。

> The language model **T5** is short for **“Text-to-Text Transfer Transformer”** ([Raffel et al., 2020](https://arxiv.org/abs/1910.10683)). The encoder-decoder implementation follows the [original Transformer](https://arxiv.org/abs/1706.03762) architecture: tokens → embedding → encoder → decoder → output. T5 adopts the framework “Natural Language Decathlon” ([McCann et al., 2018](https://arxiv.org/abs/1806.08730)), where many common NLP tasks are translated into question-answering over a context. Instead of an explicit QA format, T5 uses short task prefixes to distinguish task intentions and separately fine-tunes the model on every individual task. The text-to-text framework enables easier transfer learning evaluation with the same model on a diverse set of tasks.

![A diagram of T5 task evaluation. The text-to-text framework casts every task into a generic form: feeding input text to predict some target text. (Image source: Raffel et al., 2020 )](https://lilianweng.github.io/posts/2019-01-31-lm/T5.png)

该模型在从 2019 年 4 月提取并应用了各种过滤器的网络语料库上进行训练。该模型通过“适配器层”（添加一个额外的层进行训练）或“逐步解冻”（参见 [ULMFiT](https://lilianweng.github.io/posts/2019-01-31-lm/#ulmfit)）分别针对每个下游任务进行微调。这两种微调方法都只更新部分参数，同时保持模型的大部分参数不变。T5-11B 在许多 NLP 任务上取得了 SOTA 结果。

> The model is trained on Web corpus extracted from Apr 2019 with various filters applied. The model is fine-tuned for each downstream task separately via “adapter layers” (add an extra layer for training) or “gradual unfreezing” (see [ULMFiT](https://lilianweng.github.io/posts/2019-01-31-lm/#ulmfit)). Both fine-tuning approaches only update partial parameters while keeping the majority of the model parameters unchanged. T5-11B achieved SOTA results on many NLP tasks.

正如作者在论文中提到的“……我们的目标不是提出新方法，而是提供一个关于该领域现状的全面视角”，T5长篇论文详细描述了大量的训练设置和评估过程，对于有兴趣从头开始训练语言模型的人来说是一篇很好的读物。

> As the authors mentioned in the paper “…our goal is not to propose new methods but instead to provide a comprehensive perspective on where the field stands”, the T5 long paper described a lot of training setup and evaluation processes in detail, a good read for people who are interested in training a LM from scratch.

### GPT-3

> GPT-3

**GPT-3** ([Brown et al., 2020](https://arxiv.org/abs/2005.14165)) 与 [GPT-2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2) 具有相同的架构，但包含 1750 亿个参数，比 GPT-2 (15 亿) 大 10 倍。此外，GPT-3 使用交替的密集和局部带状稀疏注意力模式，与 [稀疏 Transformer](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#sparse-attention-matrix-factorization-sparse-transformers) 中使用的相同。为了使如此庞大的模型适应多个 GPU，GPT-3 在宽度和深度维度上都进行了分区训练。训练数据是 Common Crawl 的过滤版本，并混合了其他一些高质量的精选数据集。为了避免下游任务可能出现在训练数据中的污染，作者试图从训练数据集中删除与所有研究的基准数据集的所有重叠。不幸的是，由于一个错误，过滤过程并不完美。

> **GPT-3** ([Brown et al., 2020](https://arxiv.org/abs/2005.14165)) has the same architecture as [GPT-2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2) but contains 175B parameters, 10x larger than GPT-2 (1.5B). In addition, GPT-3 uses alternating dense and locally banded sparse attention patterns, same as in [sparse transformer](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#sparse-attention-matrix-factorization-sparse-transformers). In order to fit such a huge model across multiple GPUs, GPT-3 is trained with partitions along both width and depth dimension. The training data is a filtered version of Common Crawl mixed with a few other high-quality curated datasets. To avoid the contamination that downstream tasks might appear in the training data, the authors attempted to remove all the overlaps with all the studied benchmark dataset from the training dataset. Unfortunately the filtering process is not perfect due to a bug.

![Training datasets for GPT-3. Note that the occurrence of each dataset during training is not proportional to the dataset size.  (Table source: Brown et al., 2020 )](https://lilianweng.github.io/posts/2019-01-31-lm/GPT3-train-data.png)

对于所有下游评估，GPT-3 在少样本设置下进行测试，没有任何基于梯度的微调。这里的少样本示例作为提示的一部分提供。GPT-3 在许多 NLP 数据集上取得了强大的性能，与经过微调的 BERT 模型相当。

> For all the downstream evaluation, GPT-3 is tested in the few-shot setting without any gradient-based fine-tuning. Here the few-shot examples are provided as part of the prompt. GPT-3 achieves strong performance on many NLP datasets, comparable with fine-tuned BERT models.

![The evaluation performance increases with the model size and the number of examples. (Image source: Brown et al., 2020 )](https://lilianweng.github.io/posts/2019-01-31-lm/GPT3-eval.png)

### XLNet

> XLNet

*自回归 (AR)* 模型（如 GPT）和 *自编码器 (AE)* 模型（如 BERT）是语言建模的两种最常见方式。然而，它们各有缺点：AR 不学习双向上下文，而下游任务（如阅读理解）需要双向上下文；AE 假设在给定所有其他未掩码令牌的情况下，被掩码位置是独立的，这过度简化了长上下文依赖性。

> The *Autoregressive (AR)* model such as GPT and *autoencoder (AE)* model such as BERT are two most common ways for language modeling. However, each has their own disadvantages: AR does not learn the bidirectional context, which is needed by downstream tasks like reading comprehension and AE assumes masked positions are independent given all other unmasked tokens which oversimplifies the long context dependency.

**XLNet** ([Yang et al. 2019](https://arxiv.org/abs/1906.08237)) 将 AE 方法推广，以结合 AR 的优点。XLNet 提出了 **置换语言建模**目标。对于一个文本序列，它采样一个分解顺序 $\mathbf{z}$ 并根据这个分解顺序分解似然 $p_\theta(\mathbf{x})$。

英文原文：XLNet ([Yang et al. 2019](https://arxiv.org/abs/1906.08237)) generalizes the AE method to incorporate the benefits of AR. XLNet proposed the permutation language modeling objective. For a text sequence, it samples a factorization order 

$\mathbf{z}$ and decomposes the likelihood 

$p_\theta(\mathbf{x})$ according to this factorization order,

$$
\begin{aligned}
\mathcal{L}_\text{XLNet} 
&= - \mathbb{E}_{\mathbf{z} \sim \mathcal{Z}_T} \Big[ \sum_{t=1}^T \log p_\theta (X_{z_t} = x \mid \mathbf{x}_{\mathbf{z}_{<{t}}})\Big] \\
&= - \mathbb{E}_{\mathbf{z} \sim \mathcal{Z}_T} \Big[ \log \frac{ \exp(e(x)^\top \color{red}{h_\theta (\mathbf{x}_{\mathbf{z}_{<{t}}})}) }{ \sum_{x'} \exp(e(x')^\top \color{red}{h_\theta (\mathbf{x}_{\mathbf{z}_{<{t}}})}) } \Big] \\
&= - \mathbb{E}_{\mathbf{z} \sim \mathcal{Z}_T} \Big[ \log \frac{ \exp(e(x)^\top \color{blue}{g_\theta (\mathbf{x}_{\mathbf{z}_{<{t}}}, z_t)}) }{ \sum_{x'} \exp(e(x')^\top \color{blue}{g_\theta (\mathbf{x}_{\mathbf{z}_{<{t}}}, z_t)}) } \Big]
\end{aligned}
$$

其中$\mathcal{Z}_T$是所有可能的长度为$T$；$z_t$和$\mathbf{z}_{<t}$表示第$t$个元素和前$t-1$个元素，属于排列$\mathbf{z} \in \mathcal{Z}_T$。

> where $\mathcal{Z}_T$ is a set of all possible permutation of length $T$;  $z_t$ and $\mathbf{z}_{<t}$  denote the $t$ -th element and the first $t-1$ elements of a permutation $\mathbf{z} \in \mathcal{Z}_T$.

请注意，上下文隐藏状态的朴素表示，$h_\theta (\mathbf{x}_{\mathbf{z}_{<t}})$红色所示，不依赖于模型试图预测的位置，因为置换打破了默认排序。因此，XLNet 将其重新参数化为目标位置的函数，$g_\theta (\mathbf{x}_{\mathbf{z}_{<t}}, z_t)$蓝色所示。

> Note that the naive representation of the hidden state of the context, $h_\theta (\mathbf{x}_{\mathbf{z}_{<t}})$ in red, does not depend on which position the model tries to predict, as the permutation breaks the default ordering. Therefore, XLNet re-parameterized it to a function of the target position too, $g_\theta (\mathbf{x}_{\mathbf{z}_{<t}}, z_t)$ in blue.

然而，对 $g_\theta (\mathbf{x}_{\mathbf{z}_{<t}}, z_t)$ 的两种不同要求导致了双流自注意力设计以适应：

> However,  two different requirements on  $g_\theta (\mathbf{x}_{\mathbf{z}_{<t}}, z_t)$ lead to a two-stream self-attention design to accommodate:

1\. 当预测 $x_{z_t}$ 时，它应该只编码位置 $z_t$ 而不编码内容 $x_{z_t}$；否则这将是微不足道的。这被封装到“查询表示” $g_{z_t} = g_\theta (\mathbf{x}_{\mathbf{z}_{<t}}, z_t)$ 中，它不编码 $x_{z_t}$。

2\. 当预测 $x_j$ 且 $j > t$ 时，它也应该编码内容 $x_{z_t}$ 以提供完整的上下文。这就是“内容表示” $h_{z_t} = h_\theta(\mathbf{x}_{\leq t})$。

英文原文：

1\. When predicting $x_{z_t}$, it should only encode the position $z_t$ but not the content $x_{z_t}$; otherwise it is trivial. This is wrapped into the “query representation”  $g_{z_t} = g_\theta (\mathbf{x}_{\mathbf{z}_{<t}}, z_t)$ does not encode $x_{z_t}$.

2\. When predicting $x_j$ where $j > t$, it should encode the content $x_{z_t}$ as well to provide the full context. This is the “content representation” $h_{z_t} = h_\theta(\mathbf{x}_{\leq t})$.

![The illustration of two-stream self-attention mechanism in XLNet. (Image source: Yang et al. 2019 )](https://lilianweng.github.io/posts/2019-01-31-lm/XLNet-two-stream-attention.png)

从概念上讲，两种表示流的更新方式如下，

> Conceptually, the two streams of representations are updated as follows,

$$
\begin{aligned}
g_{z_t}^{(m)} &\gets \text{Attention}(Q = g^{(m-1)}_{z_t}, KV=\mathbf{h}^{(m-1)}_{\color{red}{\mathbf{z}_{<{t}}}}; \theta) &\text{(query stream: use }z_t\text{ but cannot see }x_{z_t}\text{)}\\
h_{z_t}^{(m)} &\gets \text{Attention}(Q = h^{(m-1)}_{z_t}, KV=\mathbf{h}^{(m-1)}_{\color{blue}{\mathbf{z}_{\leq t}}}; \theta) &\text{(content stream: use both }x_{z_t}\text{ and }x_{z_t}\text{)}\\
\end{aligned}
$$

考虑到排列语言建模中优化的难度，XLNet 被设置为仅预测分解顺序中的最后一个词块。

> Given the difficulty of optimization in permutation language modeling, XLNet is set to only predict the last chunk of tokens in a factorization order.

XLNet 的名称实际上来源于 [Transformer-XL](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#longer-attention-span-transformer-xl)。它融合了 Transformer-XL 的设计，通过重用前一个段的隐藏状态来扩展注意力范围。

> The name in XLNet actually comes from [Transformer-XL](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#longer-attention-span-transformer-xl). It incorporates the design of Transformer-XL to extend the attention span by reusing hidden states from previous segments.

![Comparison of model performance of XLNet with a couple other language models on GLUE, all single-task, no ensembles. (Image source: Yang et al. 2019 )](https://lilianweng.github.io/posts/2019-01-31-lm/XLNet-glue.png)

### BART

> BART

**BART** ([Lewis et al., 2019](https://arxiv.org/abs/1910.13461)) 是一种去噪自编码器，用于从随机损坏的版本中恢复原始文本。它结合了 **B**idirectional（双向）和 **A**uto**R**egressive（自回归） **T**ransformer：准确地说，是共同训练类似 BERT 的双向编码器和类似 GPT 的自回归解码器。损失函数只是简单地最小化负对数似然。

> **BART** ([Lewis et al., 2019](https://arxiv.org/abs/1910.13461)) is a denoising autoencoder to recover the original text from a randomly corrupted version. It combines **B**idirectional and **A**uto**R**egressive **T**ransformer: precisely, jointly training BERT-like bidirectional encoder and GPT-like autoregressive decoder together. The loss is simply just to minimize the negative log-likelihood.

![A schematic comparison of BART with BERT and GPT. (Image source: Lewis et al., 2019 )](https://lilianweng.github.io/posts/2019-01-31-lm/BART.png)

他们尝试了各种噪声转换，包括词元掩码、词元删除、文本填充（即，一个随机采样的文本跨度，可能包含多个词元，被替换为一个 `[MASK]` 词元）、句子排列、文档旋转（即，一个文档被旋转以随机词元开头）。他们发现的最佳噪声方法是文本填充和句子打乱。

> They experimented with a variety of noising transformations, including token masking, token deletion, text infilling (i.e. A randomly sampled text span, which may contain multiple tokens, is replaced with a `[MASK]` token), sentence permutation, documentation rotation (i.e. A document is rotated to begin with a random token.). The best noising approach they discovered is text infilling and sentence shuffling.

![Comparison of different language modeling pre-training objectives. (Image source: Lewis et al., 2019 )](https://lilianweng.github.io/posts/2019-01-31-lm/BART-perf.png)

从他们的实验中获得的经验教训：

> Learnings from their experiments:

- 预训练方法在不同下游任务上的表现差异很大。
- 词元掩码至关重要，因为如果只应用句子置换或文档旋转，性能会很差。
- 从左到右的预训练可以改善生成效果。
- 双向编码器对 SQuAD 至关重要。
- 预训练目标并非唯一重要因素。架构改进，例如相对位置嵌入或段级循环，也同样重要。
- 自回归语言模型在ELI5上表现最佳。
- BART取得了最稳定且强大的性能。

> • The performance of pre-training methods varies significantly across downstream tasks.
> • Token masking is crucial, as the performance is poor when only sentence permutation or documentation rotation is applied.
> • Left-to-right pre-training improves generation.
> • Bidirectional encoders are crucial for SQuAD.
> • The pre-training objective is not the only important factor. Architectural improvements such as relative-position embeddings or segment-level recurrence matter too.
> • Autoregressive language models perform best on ELI5.
> • BART achieves the most consistently strong performance.

### ELECTRA

> ELECTRA

当前大多数预训练大型语言模型需要大量的计算资源，引发了对其成本和可访问性的担忧。**ELECTRA**（“高效学习一个能准确分类token替换的编码器”；[Clark et al. 2020](https://arxiv.org/abs/2003.10555)）旨在提高*预训练效率*，它将语言建模视为判别任务而非生成任务。

> Most current pre-training large language models demand a lot of computation resources, raising concerns about their cost and accessibility. **ELECTRA** (“Efficiently Learning an Encoder that Classifies Token Replacements Accurately”; [Clark et al. 2020](https://arxiv.org/abs/2003.10555)) aims to improve the *pre-training efficiency*, which frames the language modeling as a discrimination task instead of generation task.

![Illustration of ELECTRA model architecture. (Image source: Clark et al. 2020 )](https://lilianweng.github.io/posts/2019-01-31-lm/ELECTRA-overview.png)

ELECTRA提出了一种新的预训练任务，称为“替换词元检测”（RTD）。我们随机采样$k$个位置进行掩码。原始文本中每个被选中的词元都被一个由小型语言模型（称为生成器$G$）预测的合理替代词元替换。判别器$D$预测每个词元是原始的还是被替换的。

> ELECTRA proposes a new pretraining task, called “Replaced Token Detection” (RTD). Let’s randomly sample $k$ positions to be masked. Each selected token in the original text is replaced by a plausible alternative predicted by a small language model, known as the generator $G$. The discriminator $D$ predicts whether each token is original or replaced.

$$
\begin{aligned}
\boldsymbol{m} &= [m_1, \dots, m_k] \text{ where } m_i \sim \text{unif}\{1, n\}\text{ for } i=1, \dots, k \\
\boldsymbol{x}^\text{masked} &= \text{REPLACE}(\boldsymbol{x}, \boldsymbol{m}, \texttt{[MASK]}) \\
\boldsymbol{x}^\text{corrupt} &= \text{REPLACE}(\boldsymbol{x}, \boldsymbol{m}, \tilde{\boldsymbol{x}}) \text{ where } \tilde{x}_t \sim p_G(x_i \mid \boldsymbol{x}^\text{masked}) \text{ for } i \in \boldsymbol{m} \\
\end{aligned}
$$

生成器的损失是负对数似然，与其他语言模型相同。判别器的损失是交叉熵。请注意，生成器并非对抗性训练以欺骗判别器，而只是简单地优化NLL，因为他们的实验显示了负面结果。

> The loss for the generator is the negative log-likelihood just as in other language models. The loss for the discriminator is the cross-entropy. Note that the generator is not adversarially trained to fool the discriminator but simply to optimize the NLL, since their experiments show negative results.

$$
\begin{aligned}
\mathcal{L}_\text{MLM}(\mathbf{x}, \theta_G) &= \mathbb{E}\Big(\sum_{i \in \boldsymbol{m}} -\log p_G (x_i \mid \boldsymbol{x}^\text{masked} )\Big) \\
\mathcal{L}_\text{Disc}(\mathbf{x}, \theta_D) &= \mathbb{E}\Big( - \mathbb{1}[x^\text{corrupt}_t = x_t] \log D(\boldsymbol{x}^\text{corrupt}, t) - \mathbb{1}[x^\text{corrupt}_t \neq x_t] \log (1 - \log D(\boldsymbol{x}^\text{corrupt}, t))  \Big)
\end{aligned}
$$

他们发现，只在生成器和判别器之间共享嵌入，同时使用一个小型生成器（判别器大小的1/4到1/2），比共享所有权重（即两个模型必须大小相同）更有益。此外，生成器和判别器的联合训练比交替进行的两阶段训练效果更好。

> They found it more beneficial to only share the embeddings between generator & discriminator while using a small generator (1/4 to 1/2 the discriminator size), rather than sharing all the weights (i.e. two models have to be the same size then). In addition, joint training of the generator and discriminator works better than two-stage training of each alternatively.

预训练后，生成器被丢弃，只有ELECTRA判别器会针对下游任务进行进一步微调。下表显示了ELECTRA在GLUE开发集上的性能。

> After pretraining the generator is discarded and only the ELECTRA discriminator is fine-tuned further for downstream tasks. The following table shows ELECTRA’s performance on the GLUE dev set.

![Comparison of ELECTRA with other language models on the GLUE dev set. (Image source: Clark et al. 2020 )](https://lilianweng.github.io/posts/2019-01-31-lm/ELECTRA-perf.png)

### 总结

> Summary

|  | 基础模型 | 预训练任务 |
| --- | --- | --- |
| CoVe | seq2seq NMT 模型 | 使用翻译数据集进行监督学习。 |
| ELMo | 两层双向LSTM | 下一个词元预测 |
| CVT | 两层双向LSTM | 使用有标签和无标签数据集的半监督学习 |
| ULMFiT | AWD-LSTM | 在Wikitext-103上进行自回归预训练 |
| GPT | Transformer解码器 | 下一个词元预测 |
| BERT | Transformer编码器 | 掩码语言模型 + 下一句预测 |
| ALBERT | 与BERT相同但轻量化 | 掩码语言模型 + 句子顺序预测 |
| GPT-2 | Transformer解码器 | 下一个词元预测 |
| RoBERTa | 与BERT相同 | 掩码语言模型（动态掩码） |
| T5 | Transformer编码器 + 解码器 | 在一个无监督和有监督任务的多任务混合上进行预训练，其中每个任务都转换为文本到文本的格式。 |
| GPT-3 | Transformer解码器 | 下一个词元预测 |
| XLNet | 与BERT相同 | 排列语言建模 |
| BART | BERT编码器 + GPT解码器 | 从噪声版本重建文本 |
| ELECTRA | 与 BERT 相同 | 替换词元检测 |

> 英文原表 / English original

|  | Base model | Pretraining Tasks |
| --- | --- | --- |
| CoVe | seq2seq NMT model | supervised learning using translation dataset. |
| ELMo | two-layer biLSTM | next token prediction |
| CVT | two-layer biLSTM | semi-supervised learning using both labeled and unlabeled datasets |
| ULMFiT | AWD-LSTM | autoregressive pretraining on Wikitext-103 |
| GPT | Transformer decoder | next token prediction |
| BERT | Transformer encoder | mask language model + next sentence prediction |
| ALBERT | same as BERT but light-weighted | mask language model + sentence order prediction |
| GPT-2 | Transformer decoder | next token prediction |
| RoBERTa | same as BERT | mask language model (dynamic masking) |
| T5 | Transformer encoder + decoder | pre-trained on a multi-task mixture of unsupervised and supervised tasks and for which each task is converted into a text-to-text format. |
| GPT-3 | Transformer decoder | next token prediction |
| XLNet | same as BERT | permutation language modeling |
| BART | BERT encoder + GPT decoder | reconstruct text from a noised version |
| ELECTRA | same as BERT | replace token detection |

### 指标：困惑度

> Metric: Perplexity

困惑度常被用作一种内在评估指标，用于衡量语言模型在给定上下文条件下捕捉真实词语分布的能力。

> Perplexity is often used as an intrinsic evaluation metric for gauging how well a language model can capture the real word distribution conditioned on the context.

离散概率分布 $p$ 的 [困惑度](https://en.wikipedia.org/wiki/Perplexity) 定义为熵的指数：

> A [perplexity](https://en.wikipedia.org/wiki/Perplexity) of a discrete proability distribution $p$ is defined as the exponentiation of the entropy:

$$
2^{H(p)} = 2^{-\sum_x p(x) \log_2 p(x)}
$$

给定一个包含 $N$ 个词的句子，$s = (w_1, \dots, w_N)$，熵如下所示，简单假设每个词具有相同的频率，$\frac{1}{N}$：

> Given a sentence with $N$ words, $s = (w_1, \dots, w_N)$, the entropy looks as follows, simply assuming that each word has the same frequency, $\frac{1}{N}$:

$$
H(s) = -\sum_{i=1}^N P(w_i) \log_2  p(w_i)  = -\sum_{i=1}^N \frac{1}{N} \log_2  p(w_i)
$$

该句子的困惑度变为：

> The perplexity for the sentence becomes:

$$
\begin{aligned}
2^{H(s)} &= 2^{-\frac{1}{N} \sum_{i=1}^N \log_2  p(w_i)}
= (2^{\sum_{i=1}^N \log_2  p(w_i)})^{-\frac{1}{N}}
= (p(w_1) \dots p(w_N))^{-\frac{1}{N}}
\end{aligned}
$$

一个好的语言模型应该预测较高的词语概率。因此，困惑度越小越好。

> A good language model should predict high word probabilities. Therefore, the smaller perplexity the better.

### 常见任务和数据集

> Common Tasks and Datasets


**问答**

>
> **Question-Answering**

- [SQuAD](https://rajpurkar.github.io/SQuAD-explorer/)（斯坦福问答数据集）：一个阅读理解数据集，包含基于一组维基百科文章提出的问题，每个问题的答案都是一段文本。
- [RACE](http://www.qizhexie.com/data/RACE_leaderboard)（考试阅读理解）：一个大规模阅读理解数据集，包含超过 28,000 篇文章和近 100,000 个问题。该数据集收集自中国的英语考试，这些考试是为初中生和高中生设计的。
- 请参阅[后续文章中的更多问答数据集](https://lilianweng.github.io/posts/2020-10-29-odqa/#appendix-qa-datasets)。

> • [SQuAD](https://rajpurkar.github.io/SQuAD-explorer/) (Stanford Question Answering Dataset): A reading comprehension dataset, consisting of questions posed on a set of Wikipedia articles, where the answer to every question is a span of text.
> • [RACE](http://www.qizhexie.com/data/RACE_leaderboard) (ReAding Comprehension from Examinations): A large-scale reading comprehension dataset with more than 28,000 passages and nearly 100,000 questions. The dataset is collected from English examinations in China, which are designed for middle school and high school students.
> • See [more QA datasets in a later post](https://lilianweng.github.io/posts/2020-10-29-odqa/#appendix-qa-datasets).

**常识推理**

> **Commonsense Reasoning**

- [故事完形填空测试](http://cs.rochester.edu/nlp/rocstories/)：一个用于评估故事理解和生成能力的常识推理框架。该测试要求系统从两个选项中选择多句故事的正确结局。
- [SWAG](https://rowanzellers.com/swag/)（对抗性生成情境）：多项选择；包含 11.3 万个句子对补全示例，用于评估基于事实的常识推理

> • [Story Cloze Test](http://cs.rochester.edu/nlp/rocstories/): A commonsense reasoning framework for evaluating story understanding and generation. The test requires a system to choose the correct ending to multi-sentence stories from two options.
> • [SWAG](https://rowanzellers.com/swag/) (Situations With Adversarial Generations): multiple choices; contains 113k sentence-pair completion examples that evaluate grounded common-sense inference


**自然语言推理 (NLI)**：也称为**文本蕴含**，一项旨在从逻辑上判断一个句子是否可以从另一个句子推断出来的任务。

>
> **Natural Language Inference (NLI)**: also known as **Text Entailment**, an exercise to discern in logic whether one sentence can be inferred from another.

- [RTE](https://aclweb.org/aclwiki/Textual_Entailment_Resource_Pool)（识别文本蕴含）：由文本蕴含挑战发起的一系列数据集。
- [SNLI](https://nlp.stanford.edu/projects/snli/)（斯坦福自然语言推理）：一个包含 57 万个人工编写的英语句子对的集合，这些句子对被手动标注，用于平衡分类，标签为 `entailment`、`contradiction` 和 `neutral`。
- [MNLI](https://www.nyu.edu/projects/bowman/multinli/)（多类型 NLI）：类似于 SNLI，但文本风格和主题更加多样化，收集自转录语音、流行小说和政府报告。
- [QNLI](https://gluebenchmark.com/tasks)（问题 NLI）：从 SQuAD 数据集转换而来，成为对（问题，句子）对进行二元分类的任务。
- [SciTail](http://data.allenai.org/scitail/)：一个从多项选择科学考试和网络句子创建的蕴含数据集。

> • [RTE](https://aclweb.org/aclwiki/Textual_Entailment_Resource_Pool) (Recognizing Textual Entailment): A set of datasets initiated by text entailment challenges.
> • [SNLI](https://nlp.stanford.edu/projects/snli/) (Stanford Natural Language Inference): A collection of 570k human-written English sentence pairs manually labeled for balanced classification with the labels `entailment`, `contradiction`, and `neutral`.
> • [MNLI](https://www.nyu.edu/projects/bowman/multinli/) (Multi-Genre NLI): Similar to SNLI, but with a more diverse variety of text styles and topics, collected from transcribed speech, popular fiction, and government reports.
> • [QNLI](https://gluebenchmark.com/tasks) (Question NLI): Converted from SQuAD dataset to be a binary classification task over pairs of (question, sentence).
> • [SciTail](http://data.allenai.org/scitail/): An entailment dataset created from multiple-choice science exams and web sentences.


**命名实体识别 (NER)**：标记文本中表示事物名称的词语序列，例如人名、公司名，或基因和蛋白质名称

>
> **Named Entity Recognition (NER)**: labels sequences of words in a text which are the names of things, such as person and company names, or gene and protein names

- [CoNLL 2003 NER 任务](https://www.clips.uantwerpen.be/conll2003/)：包含来自路透社的新闻报道，重点关注四种命名实体：人名、地点、组织和杂项实体名称。
- [OntoNotes 5.0](https://catalog.ldc.upenn.edu/LDC2013T19)：该语料库包含英文、阿拉伯文和中文文本，并用四种不同的实体类型（人、地点、组织、杂项）进行标注。
- [路透社语料库](https://trec.nist.gov/data/reuters/reuters.html)：一个大型路透社新闻故事集合。
- 细粒度命名实体识别 (FGN)

> • [CoNLL 2003 NER task](https://www.clips.uantwerpen.be/conll2003/): consists of newswire from the Reuters, concentrating on four types of named entities: persons, locations, organizations and names of miscellaneous entities.
> • [OntoNotes 5.0](https://catalog.ldc.upenn.edu/LDC2013T19): This corpus contains text in English, Arabic and Chinese, tagged with four different entity types (PER, LOC, ORG, MISC).
> • [Reuters Corpus](https://trec.nist.gov/data/reuters/reuters.html): A large collection of Reuters News stories.
> • Fine-Grained NER (FGN)

**情感分析**

> **Sentiment Analysis**

- [SST](https://nlp.stanford.edu/sentiment/index.html)（斯坦福情感树库）
- [IMDb](http://ai.stanford.edu/~amaas/data/sentiment/)：一个包含电影评论的大型数据集，带有二元情感分类标签。

> • [SST](https://nlp.stanford.edu/sentiment/index.html) (Stanford Sentiment Treebank)
> • [IMDb](http://ai.stanford.edu/~amaas/data/sentiment/): A large dataset of movie reviews with binary sentiment classification labels.


**语义角色标注 (SRL)**：对句子的谓词-论元结构进行建模，常被描述为回答“谁对谁做了什么”的问题。

>
> **Semantic Role Labeling (SRL)**: models the predicate-argument structure of a sentence, and is often described as answering “Who did what to whom”.

- [CoNLL-2004 & CoNLL-2005](http://www.lsi.upc.edu/~srlconll/)

> • [CoNLL-2004 & CoNLL-2005](http://www.lsi.upc.edu/~srlconll/)

**句子相似度**：也称为*复述检测*

> **Sentence similarity**: also known as *paraphrase detection*

- [MRPC](https://www.microsoft.com/en-us/download/details.aspx?id=52398)（微软复述语料库）：它包含从网络新闻源中提取的句子对，并附有标注，指示每对句子是否语义等效。
- [QQP](https://data.quora.com/First-Quora-Dataset-Release-Question-Pairs)（Quora 问题对）
STS 基准：语义文本相似度

> • [MRPC](https://www.microsoft.com/en-us/download/details.aspx?id=52398) (MicRosoft Paraphrase Corpus): It contains pairs of sentences extracted from news sources on the web, with annotations indicating whether each pair is semantically equivalent.
> • [QQP](https://data.quora.com/First-Quora-Dataset-Release-Question-Pairs) (Quora Question Pairs)
> STS Benchmark: Semantic Textual Similarity

**句子可接受性**：一项对句子进行语法可接受性标注的任务。

> **Sentence Acceptability**: a task to annotate sentences for grammatical acceptability.

- [CoLA](https://nyu-mll.github.io/CoLA/)（语言可接受性语料库）：一项二元单句分类任务。

> • [CoLA](https://nyu-mll.github.io/CoLA/) (Corpus of Linguistic Acceptability): a binary single-sentence classification task.

**文本分块**：将文本划分为句法相关的词语部分。

> **Text Chunking**: To divide a text in syntactically correlated parts of words.

- [CoNLL-2000](https://www.clips.uantwerpen.be/conll2000/chunking/)

> • [CoNLL-2000](https://www.clips.uantwerpen.be/conll2000/chunking/)


**词性标注 (POS Tagging)**：为每个词元标注词性，例如名词、动词、形容词等。
宾州树库的《华尔街日报》部分（Marcus 等人，1993）。

>
> **Part-of-Speech (POS) Tagging**: tag parts of speech to each token, such as noun, verb, adjective, etc.
> the Wall Street Journal portion of the Penn Treebank (Marcus et al., 1993).

**机器翻译**：请参阅[标准 NLP](https://nlp.stanford.edu/projects/nmt/) 页面。

> **Machine Translation**:  See [Standard NLP](https://nlp.stanford.edu/projects/nmt/) page.

- WMT 2015 英捷语数据（大型）
- WMT 2014 英德语数据（中型）
- IWSLT 2015 英越语数据（小型）

> • WMT 2015 English-Czech data (Large)
> • WMT 2014 English-German data (Medium)
> • IWSLT 2015 English-Vietnamese data (Small)

**共指消解**：将文本中指代相同底层真实世界实体的提及进行聚类。

> **Coreference Resolution**: cluster mentions in text that refer to the same underlying real world entities.

- [CoNLL-2012](http://conll.cemantix.org/2012/data.html)

> • [CoNLL-2012](http://conll.cemantix.org/2012/data.html)

**长距离依赖**

> **Long-range Dependency**

- [LAMBADA](http://clic.cimec.unitn.it/lambada/)（扩展以考虑语篇方面的语言建模）：一个从 BookCorpus 中提取的叙事段落集合，任务是预测最后一个词，这需要至少 50 个词元的上下文才能让人类成功预测。
- [儿童图书测试](https://research.fb.com/downloads/babi/)：由[古腾堡计划](https://www.gutenberg.org/)中免费提供的书籍构建。任务是从 10 个候选词中预测缺失的词。

> • [LAMBADA](http://clic.cimec.unitn.it/lambada/) (LAnguage Modeling Broadened to Account for Discourse Aspects): A collection of narrative passages extracted from the BookCorpus and the task is to predict the last word, which require at least 50 tokens of context for a human to successfully predict.
> • [Children’s Book Test](https://research.fb.com/downloads/babi/): is built from books that are freely available in [Project Gutenberg](https://www.gutenberg.org/). The task is to predict the missing word among 10 candidates.

**多任务基准**

> **Multi-task benchmark**

- GLUE 多任务基准： [https://gluebenchmark.com](https://gluebenchmark.com/)
- decaNLP 基准： [https://decanlp.com](https://decanlp.com/)

> • GLUE multi-task benchmark: [https://gluebenchmark.com](https://gluebenchmark.com/)
> • decaNLP benmark: [https://decanlp.com](https://decanlp.com/)

**无监督预训练数据集**

> **Unsupervised pretraining dataset**

- [图书语料库](https://googlebooks.byu.edu/)：该语料库包含“7,000 多本来自冒险、奇幻和浪漫等多种类型、独一无二的未出版书籍。”
- [10 亿词语言模型基准](http://www.statmt.org/lm-benchmark/)
- [英文维基百科](https://en.wikipedia.org/wiki/Wikipedia:Database_download#English-language_Wikipedia)：约 25 亿词

> • [Books corpus](https://googlebooks.byu.edu/): The corpus contains “over 7,000 unique unpublished books from a variety of genres including Adventure, Fantasy, and Romance.”
> • [1B Word Language Model Benchmark](http://www.statmt.org/lm-benchmark/)
> • [English Wikipedia](https://en.wikipedia.org/wiki/Wikipedia:Database_download#English-language_Wikipedia): ~2500M words

引用来源：

> Cited as:

```
@article{weng2019LM,
  title   = "Generalized Language Models",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2019",
  url     = "https://lilianweng.github.io/posts/2019-01-31-lm/"
}
```

### 参考文献

> Reference

[1] Bryan McCann, et al. [“在翻译中学习：语境化词向量。”](https://arxiv.org/abs/1708.00107) NIPS. 2017.

> [1] Bryan McCann, et al. [“Learned in translation: Contextualized word vectors.”](https://arxiv.org/abs/1708.00107) NIPS. 2017.

[2] Kevin Clark et al. [“基于交叉视图训练的半监督序列建模。”](https://arxiv.org/abs/1809.08370) EMNLP 2018.

> [2] Kevin Clark et al. [“Semi-Supervised Sequence Modeling with Cross-View Training.”](https://arxiv.org/abs/1809.08370) EMNLP 2018.

[3] Matthew E. Peters, et al. [“深度语境化词表示。”](https://arxiv.org/abs/1802.05365) NAACL-HLT 2017.

> [3] Matthew E. Peters, et al. [“Deep contextualized word representations.”](https://arxiv.org/abs/1802.05365) NAACL-HLT 2017.

[4] OpenAI Blog [“通过无监督学习改进语言理解”](https://blog.openai.com/language-unsupervised/), June 11, 2018.

> [4] OpenAI Blog [“Improving Language Understanding with Unsupervised Learning”](https://blog.openai.com/language-unsupervised/), June 11, 2018.

[5] OpenAI Blog [“更好的语言模型及其影响。”](https://blog.openai.com/better-language-models/) Feb 14, 2019.

> [5] OpenAI Blog [“Better Language Models and Their Implications.”](https://blog.openai.com/better-language-models/) Feb 14, 2019.

[6] Jeremy Howard and Sebastian Ruder. [“用于文本分类的通用语言模型微调。”](https://arxiv.org/abs/1801.06146) ACL 2018.

> [6] Jeremy Howard and Sebastian Ruder. [“Universal language model fine-tuning for text classification.”](https://arxiv.org/abs/1801.06146) ACL 2018.

[7] Alec Radford et al. [“通过生成式预训练改进语言理解”](https://s3-us-west-2.amazonaws.com/openai-assets/research-covers/language-unsupervised/language_understanding_paper.pdf). OpenAI Blog, June 11, 2018.

> [7] Alec Radford et al. [“Improving Language Understanding by Generative Pre-Training”](https://s3-us-west-2.amazonaws.com/openai-assets/research-covers/language-unsupervised/language_understanding_paper.pdf). OpenAI Blog, June 11, 2018.

[8] Jacob Devlin, et al. [“BERT：用于语言理解的深度双向 Transformer 预训练。”](https://arxiv.org/abs/1810.04805) arXiv:1810.04805 (2018).

> [8] Jacob Devlin, et al. [“BERT: Pre-training of deep bidirectional transformers for language understanding.”](https://arxiv.org/abs/1810.04805) arXiv:1810.04805 (2018).

[9] Mike Schuster, and Kaisuke Nakajima. [“日语和韩语语音搜索。”](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/37842.pdf) ICASSP. 2012.

> [9] Mike Schuster, and Kaisuke Nakajima. [“Japanese and Korean voice search.”](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/37842.pdf) ICASSP. 2012.

[10] Google’s Neural Machine Translation System: 弥合人机翻译之间的鸿沟

> [10] Google’s Neural Machine Translation System: Bridging the Gap between Human and Machine Translation

[11] Ashish Vaswani, et al. [“注意力就是你所需要的一切。”](https://arxiv.org/abs/1706.03762) NIPS 2017.

> [11] Ashish Vaswani, et al. [“Attention is all you need.”](https://arxiv.org/abs/1706.03762) NIPS 2017.

[12] Peter J. Liu, et al. [“通过总结长序列生成维基百科。”](https://arxiv.org/abs/1801.10198) ICLR 2018.

> [12] Peter J. Liu, et al. [“Generating wikipedia by summarizing long sequences.”](https://arxiv.org/abs/1801.10198) ICLR 2018.

[13] Sebastian Ruder. [“2018 年 NLP 领域 10 个激动人心的想法”](http://ruder.io/10-exciting-ideas-of-2018-in-nlp/) Dec 2018.

> [13] Sebastian Ruder. [“10 Exciting Ideas of 2018 in NLP”](http://ruder.io/10-exciting-ideas-of-2018-in-nlp/) Dec 2018.

[14] Alec Radford, et al. [“语言模型是无监督多任务学习器。”](https://d4mucfpksywv.cloudfront.net/better-language-models/language_models_are_unsupervised_multitask_learners.pdf). 2019.

> [14] Alec Radford, et al. [“Language Models are Unsupervised Multitask Learners.”](https://d4mucfpksywv.cloudfront.net/better-language-models/language_models_are_unsupervised_multitask_learners.pdf). 2019.

[15] Rico Sennrich, et al. [“使用子词单元对稀有词进行神经机器翻译。”](https://arxiv.org/abs/1508.07909) arXiv preprint arXiv:1508.07909. 2015.

> [15] Rico Sennrich, et al. [“Neural machine translation of rare words with subword units.”](https://arxiv.org/abs/1508.07909) arXiv preprint arXiv:1508.07909. 2015.

[16] Zhenzhong Lan, et al. [“ALBERT：一种用于语言表示自监督学习的轻量级 BERT。”](https://arxiv.org/abs/1909.11942) arXiv Preprint arXiv:1909.11942 (2019).

> [16] Zhenzhong Lan, et al. [“ALBERT: A Lite BERT for Self-supervised Learning of Language Representations.”](https://arxiv.org/abs/1909.11942) arXiv Preprint arXiv:1909.11942 (2019).

[17] Yinhan Liu, et al. [“RoBERTa：一种鲁棒优化的 BERT 预训练方法。”](https://arxiv.org/abs/1907.11692) arXiv Preprint arXiv:1907.11692 (2019).

> [17] Yinhan Liu, et al. [“RoBERTa: A Robustly Optimized BERT Pretraining Approach.”](https://arxiv.org/abs/1907.11692) arXiv Preprint arXiv:1907.11692 (2019).

[18] Tom B Brown, et al. [“语言模型是少样本学习器”](https://arxiv.org/abs/2005.14165) NeuriPS 2020.

> [18] Tom B Brown, et al. [“Language Models are Few-Shot Learners”](https://arxiv.org/abs/2005.14165) NeuriPS 2020.

[19] Zhilin Yang et al. [“XLNet：用于语言理解的广义自回归预训练。”](https://arxiv.org/abs/1906.08237) NeuriPS 2019.

> [19] Zhilin Yang et al. [“XLNet: Generalized Autoregressive Pretraining for Language Understanding.”](https://arxiv.org/abs/1906.08237) NeuriPS 2019.

[20] Mike Lewis et al. [“BART：用于自然语言生成、翻译和理解的去噪序列到序列预训练。”](https://arxiv.org/abs/1910.13461) ACL 2020.

> [20] Mike Lewis et al. [“BART: Denoising Sequence-to-Sequence Pre-training for Natural Language Generation, Translation, and Comprehension.”](https://arxiv.org/abs/1910.13461) ACL 2020.

[21] Kevin Clark et al. [“ELECTRA：将文本编码器预训练为判别器而非生成器。”](https://arxiv.org/abs/2003.10555) ICLR 2020.

> [21] Kevin Clark et al. [“ELECTRA: Pre-training Text Encoders as Discriminators Rather Than Generators.”](https://arxiv.org/abs/2003.10555) ICLR 2020.

[22] Colin Raffel, et al. [“使用统一的文本到文本 Transformer 探索迁移学习的极限”](https://arxiv.org/abs/1910.10683) JMLR 2020.

> [22] Colin Raffel, et al. [“Exploring the Limits of Transfer Learning with a Unified Text-to-Text Transformer”](https://arxiv.org/abs/1910.10683) JMLR 2020.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Natural Language Processing (NLP) | 自然语言处理 | 计算机科学领域，旨在使计算机能够理解、解释、生成和处理人类语言。 |
| Contextual Word Vectors (CoVe) | 上下文词向量 | 一种词嵌入，其表示是整个输入句子的函数，通过机器翻译模型的编码器学习。 |
| Embeddings from Language Model (ELMo) | 语言模型嵌入 | 通过无监督预训练双向语言模型学习的上下文相关词表示，结合不同层级的隐藏状态。 |
| Cross-View Training (CVT) | 跨视图训练 | 一种半监督学习过程，结合有监督学习和无监督辅助任务来改进编码器表示。 |
| Universal Language Model Fine-tuning (ULMFiT) | 通用语言模型微调 | 一种迁移学习方法，通过通用语言模型预训练和任务特定微调，实现文本分类等下游任务。 |
| Generative Pre-trained Transformer (GPT) | 生成式预训练Transformer | 一种基于Transformer解码器的语言模型，通过大规模无监督预训练，并微调相同的基本模型以适应多种下游任务。 |
| Byte Pair Encoding (BPE) | 字节对编码 | 一种数据压缩算法，通过迭代合并频繁出现的字符对来解决开放词汇问题，常用于子词分词。 |
| Bidirectional Encoder Representations from Transformers (BERT) | 来自Transformer的双向编码器表示 | 一种基于Transformer的双向预训练语言模型，通过掩码语言模型和下一句预测任务学习上下文表示。 |
| Masked Language Model (MLM) | 掩码语言模型 | BERT中的一种预训练任务，随机掩盖输入序列中的部分词元，并训练模型预测这些被掩盖的词元。 |
| Next Sentence Prediction (NSP) | 下一句预测 | BERT中的一种预训练任务，判断两个句子是否在原始文本中连续出现。 |
| A Lite BERT (ALBERT) | 轻量级BERT | BERT的轻量级版本，通过分解嵌入参数化、跨层参数共享和句子顺序预测来减少参数和提高训练效率。 |
| Zero-shot Transfer | 零样本迁移 | 模型在没有特定任务训练数据的情况下，直接应用于新任务并取得良好性能的能力。 |
| Text-to-Text Transfer Transformer (T5) | 文本到文本迁移Transformer | 一种统一的Transformer模型，将所有自然语言处理任务都视为文本到文本的转换问题。 |
| Permutation Language Modeling | 置换语言建模 | XLNet提出的预训练目标，通过对输入序列的词元进行随机排列，并根据排列顺序预测词元，以学习双向上下文。 |
| Replaced Token Detection (RTD) | 替换词元检测 | ELECTRA提出的预训练任务，训练判别器判断输入序列中的每个词元是原始的还是被生成器替换的。 |
