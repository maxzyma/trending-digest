# 如何构建一个开放域问答系统？

> How to Build an Open-Domain Question Answering System?

> 来源：Lil'Log / Lilian Weng，2020-10-29
> 原文链接：https://lilianweng.github.io/posts/2020-10-29-odqa/
> 分类：自然语言处理 / 开放域问答

## 核心要点

- 开放域问答（ODQA）系统旨在以自然语言回答任何事实性问题，可应用于聊天机器人和AI助手。
- ODQA模型可以访问外部知识源（开卷）或不访问（闭卷），与提供上下文的阅读理解任务不同。
- 构建开卷ODQA系统通常采用“检索器-阅读器”框架，分为检索相关上下文和从上下文中提取答案两个阶段。
- 检索器模型可基于经典信息检索（如TF-IDF、BM25）或神经信息检索（如使用语言模型生成密集嵌入向量）。
- 阅读器模型负责从检索到的文档中提取答案，早期方法使用双向LSTM，而现代方法普遍基于BERT等Transformer模型。
- 检索器和阅读器组件可以独立训练，也可以通过强化学习或优化边际似然等方法进行端到端联合训练，如R^3、ORQA、REALM和DPR。
- “检索器-生成器”方法直接生成自由文本答案，而非提取，RAG模型结合了参数化语言模型和非参数化外部知识索引。
- 闭卷问答利用大型生成式语言模型（如T5、GPT3）在预训练中记忆的事实知识，无需显式上下文即可直接生成答案。
- 快速最大内积搜索（MIPS）是许多ODQA模型中的关键组件，用于高效地从大量预计算的段落表示中检索相关信息。
- 逆完形填空任务（ICT）和显著跨度掩码是两种对问答任务特别有帮助的语言模型预训练技术。

## 正文

[2020-11-12 更新：添加了一个关于使用 OpenAI API（测试版）进行闭卷事实问答的[示例](https://lilianweng.github.io/posts/2020-10-29-odqa/#openai-api-example)。

> [Updated on 2020-11-12: add [an example](https://lilianweng.github.io/posts/2020-10-29-odqa/#openai-api-example) on closed-book factual QA using OpenAI API (beta).

一个能够回答任何事实性知识问题的模型可以带来许多有用且实用的应用，例如作为聊天机器人或AI助手🤖。在这篇文章中，我们将回顾几种构建此类开放域问答系统的常见方法。

> A model that can answer any question with regard to factual knowledge can lead to many useful and practical applications, such as working as a chatbot or an AI assistant🤖. In this post, we will review several common approaches for building such an open-domain question answering system.

鉴于现有大量论文，以下是免责声明：

> Disclaimers given so many papers in the wild:

- 假设我们能够访问一个强大的预训练[语言模型](https://lilianweng.github.io/posts/2019-01-31-lm/)。
- 我们在此不涉及如何使用结构化知识库（例如 Freebase、WikiData）。
- 我们只关注单轮问答，而不是多轮对话式问答。
- 我们主要关注包含神经网络的问答模型，特别是基于 Transformer 的语言模型。
- 我承认我错过了许多在 2017-2019 年间专门为问答任务设计的架构论文😔

> • Assume we have access to a powerful pretrained [language model](https://lilianweng.github.io/posts/2019-01-31-lm/).
> • We do not cover how to use structured knowledge base (e.g. Freebase, WikiData) here.
> • We only focus on a single-turn QA instead of a multi-turn conversation style QA.
> • We mostly focus on QA models that contain neural networks, specially Transformer-based language models.
> • I admit that I missed a lot of papers with architectures designed specifically for QA tasks between 2017-2019😔

### 什么是开放域问答？

> What is Open-Domain Question Answering?

**开放域问答（ODQA）**是一种语言任务，要求模型以自然语言回答事实性问题。真实答案是客观的，因此评估模型性能很简单。

> **Open-domain Question Answering (ODQA)** is a type of language tasks, asking a model to produce answers to factoid questions in natural language. The true answer is objective, so it is simple to evaluate model performance.

例如，

> For example,

```
Question: What did Albert Einstein win the Nobel Prize for?
Answer: The law of the photoelectric effect.
```

“开放域”部分指的是对于任何随意提出的事实性问题，都缺乏相关的上下文。在上述案例中，模型只将问题作为输入，但没有提供关于“为什么爱因斯坦没有因相对论获得诺贝尔奖”的文章，而“光电效应定律”这个术语很可能在那篇文章中被提及。当问题和上下文都提供时，这项任务被称为**阅读理解（RC）**。

> The “open-domain” part refers to the lack of the relevant context for any arbitrarily asked factual question. In the above case, the model only takes as the input the question but no article about “why Einstein didn’t win a Nobel Prize for the theory of relativity” is provided, where the term “the law of the photoelectric effect” is likely mentioned. In the case when both the question and the context are provided, the task is known as **Reading comprehension (RC)**.

一个ODQA模型可以*访问外部知识源*（例如维基百科），也可以不访问，这两种情况分别被称为*开卷*或*闭卷*问答。

> An ODQA model may work with or without *access to an external source of knowledge* (e.g. Wikipedia) and these two conditions are referred to as *open-book* or *closed-book* question answering, respectively.

在考虑不同类型的开放域问题时，我喜欢[Lewis, et al., 2020](https://arxiv.org/abs/2008.02637)提出的分类，按难度递增排序：

> When considering different types of open-domain questions, I like the classification by [Lewis, et al., 2020](https://arxiv.org/abs/2008.02637), in increasing order of difficulty:

1. 模型能够正确记忆并回答在训练时见过的问题。
2. 模型能够在测试时回答新问题，并从训练期间见过的答案集中选择一个答案。
3. 模型能够回答训练数据集中不包含答案的新问题。

> • A model is able to correctly memorize and respond with the answer to a question that has been seen at training time.
> • A model is able to answer novel questions at test time and choose an answer from the set of answers it has seen during training.
> • A model is able to answer novel questions which have answers not contained in the training dataset.

![Overview of three frameworks discussed in this post.](https://lilianweng.github.io/posts/2020-10-29-odqa/QA-summary.png)

#### 符号

> Notation

给定一个问题$x$和一个真实答案片段$y$，包含真实答案的上下文段落被标记为$z \in \mathcal{Z}$，其中$\mathcal{Z}$是一个外部知识语料库。维基百科是这种外部知识源的常见选择。

> Given a question $x$ and a ground truth answer span $y$, the context passage containing the true answer is labelled as $z \in \mathcal{Z}$, where $\mathcal{Z}$ is an external knowledge corpus. Wikipedia is a common choice for such an external knowledge source.

#### 问答数据微调的担忧

> Concerns of QA data fine-tuning

在我们深入探讨下面许多模型的细节之前，我想指出一个关于使用常见问答数据集微调模型的担忧，这在几个ODQA模型中作为微调步骤出现。这可能令人担忧，因为在几个公共问答数据集中，训练集和测试集中的问题存在显著重叠。

> Before we dive into the details of many models below. I would like to point out one concern of fine-tuning a model with common QA datasets, which appears as one fine-tuning step in several ODQA models. It could be concerning, because there is a significant overlap between questions in the train and test sets in several public QA datasets.

[Lewis, et al., (2020)](https://arxiv.org/abs/2008.02637)（[代码](https://github.com/facebookresearch/QA-Overlap)）发现，58-71%的测试时答案也存在于训练集中的某个地方，28-34%的测试集问题在相应的训练集中有近似重复的释义。在他们的实验中，当从训练集中移除重复或释义的问题时，几个模型的表现明显变差。

> [Lewis, et al., (2020)](https://arxiv.org/abs/2008.02637) ([code](https://github.com/facebookresearch/QA-Overlap)) found that 58-71% of test-time answers are also present somewhere in the training sets and 28-34% of test-set questions have a near-duplicate paraphrase in their corresponding training sets. In their experiments, several models performed notably worse when duplicated or paraphrased questions were removed from the training set.

### 开卷问答：检索器-阅读器

> Open-book QA: Retriever-Reader

给定一个事实性问题，如果语言模型没有上下文，或者不足以记住训练数据集中存在的上下文，它就不太可能猜出正确答案。在开卷考试中，学生在回答试题时可以参考笔记和书籍等外部资源。类似地，ODQA 系统可以与丰富的知识库配对，以识别相关文档作为答案的证据。

> Given a factoid question, if a language model has no context or is not big enough to memorize the context which exists in the training dataset, it is unlikely to guess the correct answer. In an open-book exam, students are allowed to refer to external resources like notes and books while answering test questions. Similarly, a ODQA system can be paired with a rich knowledge base to identify relevant documents as evidence of answers.

我们可以将寻找给定问题答案的过程分解为两个阶段，

> We can decompose the process of finding answers to given questions into two stages,

1. 在外部知识库中查找相关上下文；
2. 处理检索到的上下文以*提取*答案。

> • Find the related context in an external repository of knowledge;
> • Process the retrieved context to *extract* an answer.

![The retriever-reader QA framework combines information retrieval with machine reading comprehension.](https://lilianweng.github.io/posts/2020-10-29-odqa/QA-retriever-reader.png)

这种检索器+阅读器框架最初在**DrQA**（由[Chen 等人于 2017 年](https://arxiv.org/abs/1704.00051)提出的“文档检索器问答”；[代码](https://github.com/facebookresearch/DrQA)）中提出。检索器和阅读器组件可以独立设置和训练，也可以[端到端](https://lilianweng.github.io/posts/2020-10-29-odqa/#end-to-end-joint-training)联合训练。

> Such a retriever + reader framework was first proposed in **DrQA** (“Document retriever Question-Answering” by [Chen et al., 2017](https://arxiv.org/abs/1704.00051); [code](https://github.com/facebookresearch/DrQA)). The retriever and the reader components can be set up and trained independently, or jointly trained [end-to-end](https://lilianweng.github.io/posts/2020-10-29-odqa/#end-to-end-joint-training).

#### 检索器模型

> Retriever Model

实现检索器的两种流行方法是使用信息检索（IR）系统，该系统依赖于（1）经典的非学习型[TF-IDF](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)特征（“经典 IR”）或（2）由神经网络生成的文本的密集嵌入向量（“神经 IR”）。

> Two popular approaches for implementing the retriever is to use the information retrieval (IR) system that depends on (1) the classic non-learning-based [TF-IDF](https://en.wikipedia.org/wiki/Tf%E2%80%93idf) features (“classic IR”) or (2) dense embedding vectors of text produced by neural networks (“neural IR”).

##### 经典 IR

> Classic IR

**DrQA**（[Chen 等人，2017](https://arxiv.org/abs/1704.00051)）采用了一种基于[向量空间模型](https://en.wikipedia.org/wiki/Vector_space_model)的高效非学习型搜索引擎。每个查询和文档都被建模为词袋向量，其中每个词项都通过 TF-IDF（词频 `\times` 逆文档频率）进行加权。

英文原文：DrQA ([Chen et al., 2017](https://arxiv.org/abs/1704.00051)) adopts an efficient non-learning-based search engine based on the [vector space model](https://en.wikipedia.org/wiki/Vector_space_model). Every query and document is modelled as a bag-of-word vector, where each term is weighted by TF-IDF (term frequency `\times` inverse document frequency).

$$
\begin{aligned}
\text{tf-idf}(t, d, \mathcal{D}) &= \text{tf}(t, d) \times \text{idf}(t, \mathcal{D}) \\
\text{tf}(t, d) &= \log(1 + \text{freq}(t, d)) \\
\text{idf}(t, \mathcal{D}) &= \log \Big( \frac{\vert\mathcal{D}\vert}{\vert d\in\mathcal{D}: t\in d\vert} \Big)
\end{aligned}
$$

其中 $t$ 是文档 $d$ 中来自文档集合 $\mathcal{D}$ 的一个一元词或二元词。$\text{freq}(t, d)$ 衡量词项 $t$ 在 $d$ 中出现的次数。请注意，这里的词频也包括二元词计数，这被发现非常有用，因为通过二元词考虑了局部词序。作为实现的一部分，DrQA 使用无符号 murmur3 哈希将 $2^{24}$ 桶的二元词映射。

> where $t$ is a unigram or bigram term in a document $d$ from a collection of documents $\mathcal{D}$ . $\text{freq}(t, d)$ measures how many times a term $t$ appears in $d$. Note that the term-frequency here includes bigram counts too, which is found to be very helpful because the local word order is taken into consideration via bigrams. As part of the implementation, DrQA maps the bigrams of $2^{24}$ bins using unsigned murmur3 hash.

具体来说，DrQA 将维基百科作为其知识来源，此后这一选择成为许多 ODQA 研究的默认设置。非机器学习文档检索器根据问题返回前 $k=5$ 篇最相关的维基百科文章。

> Precisely, DrQA implemented Wikipedia as its knowledge source and this choice has became a default setting for many ODQA studies since then. The non-ML document retriever returns the top $k=5$ most relevant Wikipedia articles given a question.

**BERTserini**（[Yang 等人，2019](https://arxiv.org/abs/1902.01718)）将开源的 [Anserini](https://github.com/castorini/anserini) IR 工具包作为检索器，并与一个微调的预训练 BERT 模型作为阅读器配对。前 `k` 个文档（$k=10$）通过 Anserini 的 `post-v3.0` 分支检索，查询被视为词袋。检索到的文本片段通过 [BM25](https://en.wikipedia.org/wiki/Okapi_BM25) 进行排名，BM25 是一种经典的基于 TF-IDF 的检索评分函数。在文本粒度对性能的影响方面，他们发现段落检索 > 句子检索 > 文章检索。

英文原文：BERTserini ([Yang et al., 2019](https://arxiv.org/abs/1902.01718)) pairs the open-source [Anserini](https://github.com/castorini/anserini) IR toolkit as the retriever with a fine-tuned pre-trained BERT model as the reader. The top `k` documents (

$k=10$) are retrieved via the `post-v3.0` branch of Anserini with the query treated as a bag of words. The retrieved text segments are ranked by [BM25](https://en.wikipedia.org/wiki/Okapi_BM25), a classic TF-IDF-based retrieval scoring function. In terms of the effect of text granularity on performance, they found that paragraph retrieval > sentence retrieval > article retrieval.

![An illustration of BERTserini architecture. (Image source: Yang et al., 2019 )](https://lilianweng.github.io/posts/2020-10-29-odqa/BERTserini-arch.png)

*ElasticSearch + BM25* 被 **Multi-passage BERT** 问答模型 ([Wang et al., 2019](https://arxiv.org/abs/1908.08167)) 使用。他们发现，通过 *滑动窗口* 将文章分割成长度为100词的段落带来了4%的改进，因为将文档分割成没有重叠的段落可能会导致一些接近边界的证据失去有用的上下文。

> *ElasticSearch + BM25* is used by the **Multi-passage BERT** QA model ([Wang et al., 2019](https://arxiv.org/abs/1908.08167)). They found that splitting articles into passages with the length of 100 words by *sliding window* brings 4% improvements, since splitting documents into passages without overlap may cause some near-boundary evidence to lose useful contexts.

##### 神经信息检索

> Neural IR

在学习文本的低维表示方面有着悠久的历史，这种表示比原始的基于词项的向量更密集 ([Deerwester et al., 1990](http://lsa.colorado.edu/papers/JASIS.lsi.90.pdf); [Yih, et al., 2011](https://www.aclweb.org/anthology/W11-0329/))。密集表示可以通过矩阵分解或某些神经网络架构（例如MLP、LSTM、双向LSTM等）来学习。当涉及神经网络时，这些方法被称为“神经信息检索”（Neural IR），神经信息检索是检索问题的一种新方法类别，但它不一定比经典信息检索表现更好/更优越 ([Lim, 2018](https://sigir.org/wp-content/uploads/2019/01/p040.pdf))。

> There is a long history in learning a low-dimensional representation of text, denser than raw term-based vectors ([Deerwester et al., 1990](http://lsa.colorado.edu/papers/JASIS.lsi.90.pdf); [Yih, et al., 2011](https://www.aclweb.org/anthology/W11-0329/)). Dense representations can be learned through matrix decomposition or some neural network architectures (e.g. MLP, LSTM, bidirectional LSTM, etc). When involving neural networks, such approaches are referred to as “Neural IR”, Neural IR is a new category of methods for retrieval problems, but it is not necessary to perform better/superior than classic IR ([Lim, 2018](https://sigir.org/wp-content/uploads/2019/01/p040.pdf)).

在许多大规模[通用语言模型](https://lilianweng.github.io/posts/2019-01-31-lm/)取得成功之后，许多问答模型都采用了以下方法：

> After the success of many large-scale [general language models](https://lilianweng.github.io/posts/2019-01-31-lm/), many QA models embrace the following approach:

$$
h_x = E_x(x)\quad
h_z = E_z(z)\quad
\text{score}(x, z) = h_x^\top h_z
$$

1\. 通过将问题 $x$ 和上下文段落 $z$ 输入语言模型，提取它们的密集表示；

2\. 使用这两种表示的点积作为检索分数，对最相关的段落进行排序和选择。

英文原文：

1\. Extract the dense representations of a question $x$ and a context passage $z$ by feeding them into a language model;

2\. Use the dot-product of these two representations as the retrieval score to rank and select most relevant passages.

ORQA、REALM 和 DPR 都使用这样的评分函数进行上下文检索，这将在关于端到端 QA 模型的[后续章节](https://lilianweng.github.io/posts/2020-10-29-odqa/#end-to-end-joint-training)中详细描述。

> ORQA, REALM and DPR all use such a scoring function for context retrieval, which will be described in detail in a [later section](https://lilianweng.github.io/posts/2020-10-29-odqa/#end-to-end-joint-training) on the end-to-end QA model.

**DenSPI**（“密集-稀疏短语索引”；[Seo 等人，2019](https://arxiv.org/abs/1906.05807)）研究了一种极端方法，即在*短语*级别编码知识语料库中的所有文本，然后仅依靠检索器来识别最相关的短语作为预测答案。通过这种方式，检索器+阅读器管道被简化为仅检索器。当然，索引会大得多，检索问题也更具挑战性。

> An extreme approach, investigated by **DenSPI** (“Dense-Sparse Phrase Index”; [Seo et al., 2019](https://arxiv.org/abs/1906.05807)), is to encode all the text in the knowledge corpus at the *phrase* level and then only rely on the retriever to identify the most relevant phrase as the predicted answer. In this way, the retriever+reader pipeline is reduced to only retriever. Of course, the index would be much larger and the retrieval problem is more challenging.

DenSPI 引入了一种*与查询无关的*文档短语可索引表示。具体来说，它离线编码维基百科中文本跨度的与查询无关的表示，并在推理时通过执行最近邻搜索来查找答案。这可以大大加快推理时间，因为无需为每个新查询重新编码文档，而这通常是阅读器模型所要求的。

> DenSPI introduces a *query-agnostic* indexable representation of document phrases. Precisely it encodes query-agnostic representations of text spans in Wikipedia offline and looks for the answer at inference time by performing nearest neighbor search. It can drastically speed up the inference time, because there is no need to re-encode documents for every new query, which is often required by a reader model.

给定一个问题 $x$ 和一组固定的（维基百科）文档 $z_1, \dots, z_K$，并且每个文档 $z_k$ 包含 $N_k$ 个词 $z_k = \langle z_k^{(1)}, \dots, z_k^{(N_k)}\rangle$。一个 ODQA 模型是一个评分函数 $F$，用于每个候选短语跨度 $z_k^{(i:j)}, 1 \leq i \leq j \leq N_k$，使得真实答案是得分最高的短语：$y = {\arg\max}_{k,i,j} F(x, z_k^{(i:j)})$。

> Given a question $x$ and a fixed set of (Wikipedia) documents, $z_1, \dots, z_K$ and each document $z_k$ contains $N_k$ words, $z_k = \langle z_k^{(1)}, \dots, z_k^{(N_k)}\rangle$. An ODQA model is a scoring function $F$ for each candidate phrase span $z_k^{(i:j)}, 1 \leq i \leq j \leq N_k$, such that the truth answer is the phrase with maximum score: $y = {\arg\max}_{k,i,j} F(x, z_k^{(i:j)})$.

短语表示 $z_k^{(i:j)}$ 结合了密集向量和稀疏向量 $z_k^{(i:j)} = [d_k^{(i:j)}, s_k^{(i:j)}] \in \mathbb{R}^{d^d + d^s}$（注意 $d^d \ll d^s$）：

> The phrase representation $z_k^{(i:j)}$ combines both dense and sparse vectors, $z_k^{(i:j)} = [d_k^{(i:j)}, s_k^{(i:j)}] \in \mathbb{R}^{d^d + d^s}$ (note that $d^d \ll d^s$):

• 密集向量 $d_k^{(i:j)}$ 有效地编码了局部*句法*和*语义*线索，这正是预训练语言模型可以学习到的。

• 稀疏向量$s_k^{(i:j)}$在编码精确的*词汇*信息方面表现出色。稀疏向量是基于词频的编码。DenSPI使用与DrQA相同的2-gram词频，从而产生高度稀疏的表示($d^s \approx 16$M)

英文原文：

• The dense vector $d_k^{(i:j)}$ is effective for encoding local *syntactic* and *semantic* cues, as what can be learned by a pretrained language model.

• The sparse vector $s_k^{(i:j)}$ is superior at encoding precise *lexical* information. The sparse vector is term-frequency-based encoding. DenSPI uses 2-gram term-frequency same as DrQA, resulting a highly sparse representation ($d^s \approx 16$M)

密集向量$d^{(i:j)}$进一步分解为三个部分，$d^{(i:j)} = [a_i, b_j, c_{ij}] \in \mathbb{R}^{2d^b + 1}$其中$2d^b + 1 = d^d$。所有这三个组件都是根据微调后的BERT表示的不同列学习得到的。

> The dense vector $d^{(i:j)}$ is further decomposed into three parts, $d^{(i:j)} = [a_i, b_j, c_{ij}] \in \mathbb{R}^{2d^b + 1}$ where $2d^b + 1 = d^d$. All three components are learned based on different columns of the fine-tuned BERT representations.

• 向量$a_i$编码文档中第$i$个词的*起始*位置；

• 向量$b_j$编码文档中第$j$个词的*结束*位置；

• 标量$c_{ij}$衡量起始向量和结束向量之间的*连贯性*，有助于在推理过程中避免非构成短语。

英文原文：

• A vector $a_i$ encodes the *start* position for the $i$ -th word of the document;

• A vector $b_j$ encodes the *end* position for the $j$ -th word of the document;

• A scalar $c_{ij}$ measures the *coherency* between the start and the end vectors, helping avoid non-constituent phrases during inference.

对于所有可能的$(i,j,k)$元组，其中$j-i < J$，文本跨度嵌入被预先计算并存储为*短语索引*。最大跨度长度$J$是一个预定义的标量常数。

> For all possible $(i,j,k)$ tuples where $j-i < J$, the text span embeddings are precomputed and stored as a *phrase index*. The maximum span length $J$ is a predefined scalar constant.

![An illustration of Dense-Sparse Phrase Index (DenSPI) architecture. (Image source: Seo et al., 2019 )](https://lilianweng.github.io/posts/2020-10-29-odqa/DenSPI-arch.png)

在推理时，问题被映射到相同的向量空间$x=[d’, s’] \in \mathbb{R}^{d^d + d^s}$中，其中密集向量$d’$是从特殊`[CLS]`符号的BERT嵌入中提取的。相同的BERT模型用于编码问题和短语。最终答案由$k^{\ast}, i^{\ast}, j^{\ast} = \arg\max x^\top z_k^{(i:j)}$预测。

> At the inference time, the question is mapped into the same vector space $x=[d’, s’] \in \mathbb{R}^{d^d + d^s}$, where the dense vector $d’$ is extracted from the BERT embedding of the special `[CLS]` symbol. The same BERT model is shared for encoding both questions and phrases. The final answer is predicted by $k^{\ast}, i^{\ast}, j^{\ast} = \arg\max x^\top z_k^{(i:j)}$.

#### 阅读器模型

> Reader Model

阅读器模型学习解决阅读理解任务——从给定的上下文文档中为给定问题提取答案。这里我们只讨论使用神经网络的机器理解方法。

> The reader model learns to solve the reading comprehension task — extract an answer for a given question from a given context document. Here we only discuss approaches for machine comprehension using neural networks.

##### 双向LSTM

> Bi-directional LSTM

**DrQA**（[Chen et al., 2017](https://arxiv.org/abs/1704.00051)）的答案检测阅读器模型是一个3层双向LSTM，隐藏层大小为128。检索到的维基百科文章的每个相关段落都由一个特征向量序列$\{\tilde{\mathbf{z}}_1, \dots, \tilde{\mathbf{z}}_m \}$编码。每个特征向量$\hat{\mathbf{z}}_i \in \mathbb{R}^{d_z}$旨在捕获围绕一个标记`z_i`的有用上下文信息。该特征由几类特征组成：

英文原文：The reader model for answer detection of DrQA ([Chen et al., 2017](https://arxiv.org/abs/1704.00051)) is a 3-layer bidirectional LSTM with hidden size 128. Every relevant paragraph of retrieved Wikipedia articles is encoded by a sequence of feature vector, 

$\{\tilde{\mathbf{z}}_1, \dots, \tilde{\mathbf{z}}_m \}$. Each feature vector 

$\hat{\mathbf{z}}_i \in \mathbb{R}^{d_z}$ is expected to capture useful contextual information around one token `z_i`. The feature consists of several categories of features:

1\. 词嵌入：一个300维的[Glove](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#glove-global-vectors)词嵌入，由800B网络爬取数据训练得到，$f_\text{embed} = E_g(z_i)$。

2\. 精确匹配：一个词$z_i$是否出现在问题中$x$，$f_\text{match} = \mathbb{I}(z_i \in x)$。

3\. 词元特征：这包括POS（词性）标注、NER（命名实体识别）和TF（词频），$f_\text{token}(z_i) = (\text{POS}(z_i), \text{NER}(z_i), \text{TF}(z_i))$。

4\. 对齐的问题嵌入：注意力分数$y_{ij}$旨在捕获段落词元$z_i$和问题词$x_j$之间的句间匹配和相似性。此特征在相似但不相同的词之间添加了软对齐。

英文原文：

1\. Word embeddings: A 300d [Glove](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#glove-global-vectors) word embedding trained from 800B Web crawl data, $f_\text{embed} = E_g(z_i)$.

2\. Exact match: Whether a word $z_i$ appears in the question $x$, $f_\text{match} = \mathbb{I}(z_i \in x)$.

3\. Token features: This includes POS (part-of-speech) tagging, NER (named entity recognition), and TF (term-frequency), $f_\text{token}(z_i) = (\text{POS}(z_i), \text{NER}(z_i), \text{TF}(z_i))$.

4\. Aligned question embedding: The attention score $y_{ij}$ is designed to capture inter-sentence matching and similarity between the paragraph token $z_i$ and the question word $x_j$. This feature adds soft alignments between similar but non-identical words.

$$
\begin{aligned}
f_\text{align}(z_i) &= \sum_j y_{i,j} E_g(x_j) \\ 
y_{i,j} &= \frac{\exp(\alpha(E_g(z_i))^\top \alpha(E_g(x_j)) )}{\sum_{j'} \exp(\alpha(E_g(z_i))^\top \alpha(E_g(x_{j'})) ) }
\end{aligned}
$$

其中$\alpha$是一个带有ReLU的单一全连接层，$E_g(.)$是Glove词嵌入。

> where $\alpha$ is a single dense layer with ReLU and $E_g(.)$ is the glove word embedding.

一个包含$m$个词元的段落的特征向量被输入到LSTM中，以获得最终的段落向量：

> The feature vector of a paragraph of $m$ tokens is fed into LSTM to obtain the final paragraph vectors:

$$
\begin{aligned}
\mathbf{z} = \{\mathbf{z}_1, \dots, \mathbf{z}_m\} &= \text{LSTM}(\{\tilde{\mathbf{z}}_1, \dots, \tilde{\mathbf{z}}_m\}) \\
\text{where } \tilde{\mathbf{z}}_i &= \{f_\text{embed}, f_\text{match}, f_\text{token}, f_\text{align}\}
\end{aligned}
$$

问题被编码为问题中每个词的嵌入的加权和：

> The question is encoded as a weighted sum of the embeddings of every word in the question:

$$
\mathbf{x} = \sum_j b_j E(x_j) \quad b_j = \text{softmax}(\mathbf{w}^\top E(x_j))
$$

其中$\mathbf{w}$是一个需要学习的权重向量。

> where $\mathbf{w}$ is a weight vector to learn.

一旦为问题和所有相关段落构建了特征向量，阅读器需要预测段落中每个位置作为答案跨度开始和结束的概率，分别为$p_\text{start}(i_s)$和$p_\text{end}(i_s)$。在所有段落中，具有最大$p_\text{start}(i_s) \times p_\text{end}(i_e)$的最优跨度将作为最终答案返回。

> Once the feature vectors are constructed for the question and all the related paragraphs, the reader needs to predict the probabilities of each position in a paragraph to be the start and the end of an answer span, $p_\text{start}(i_s)$ and $p_\text{end}(i_s)$, respectively. Across all the paragraphs, the optimal span is returned as the final answer with maximum $p_\text{start}(i_s) \times p_\text{end}(i_e)$.

$$
\begin{aligned}
p_\text{start}(i_s) \propto \exp(\mathbf{z}_{i_s} \mathbf{W}_s \mathbf{x}) \\ 
p_\text{end}(i_e) \propto \exp(\mathbf{z}_{i_e} \mathbf{W}_e \mathbf{x}) \\
\text{ s.t. } i_s \leq i_e \leq i_s + 15
\end{aligned}
$$

其中$\mathbf{W}_s$和$\mathbf{W}_e$是学习到的参数。

> where $\mathbf{W}_s$ and $\mathbf{W}_e$ are learned parameters.

##### BERT宇宙

> BERT-universe

继[BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert)（[Devlin et al., 2018](https://arxiv.org/abs/1810.04805)）成功之后，许多问答模型都基于BERT开发了机器理解组件。让我们将BERT模型定义为一个函数，该函数可以接受一个或多个字符串（通过`[SEP]`连接）作为输入，并为特殊的`[CLS]`标记和每个输入标记输出一组BERT编码向量：

> Following the success of [BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert) ([Devlin et al., 2018](https://arxiv.org/abs/1810.04805)), many QA models develop the machine comprehension component based on BERT. Let’s define the BERT model as a function that can take one or multiple strings (concatenated by `[SEP]`) as input and outputs a set of BERT encoding vectors for the special `[CLS]` token and every input token:

$$
\text{BERT}(s_1, s_2, \dots) = [\mathbf{h}^\texttt{[CLS]}, \mathbf{h}^{(1)}, \mathbf{h}^{(2)}, \dots]
$$

其中$\mathbf{h}^\texttt{[CLS]}$是特殊`[CLS]`标记的嵌入向量，$\mathbf{h}^{(i)}$是第$i$个标记的嵌入向量。

> where $\mathbf{h}^\texttt{[CLS]}$ is the embedding vector for the special `[CLS]` token and $\mathbf{h}^{(i)}$ is the embedding vector for the $i$ -th token.

为了将BERT用于阅读理解，它学习了两个额外的权重，$\mathbf{W}_s$和$\mathbf{W}_e$，并且$\text{softmax}(\mathbf{h}^{(i)}\mathbf{W}_s)$和$\text{softmax}(\mathbf{h}^{(i)}\mathbf{W}_e)$定义了每个标记预测跨度的起始和结束位置的两个概率分布。

> To use BERT for reading comprehension, it learns two additional weights, $\mathbf{W}_s$ and $\mathbf{W}_e$, and $\text{softmax}(\mathbf{h}^{(i)}\mathbf{W}_s)$ and $\text{softmax}(\mathbf{h}^{(i)}\mathbf{W}_e)$ define two probability distributions of start and end position of the predicted span per token.

**BERTserini**（[Yang et al., 2019](https://arxiv.org/abs/1902.01718)）利用预训练的BERT模型作为阅读器。他们的实验表明，使用SQuAD对预训练的BERT进行*微调*足以在识别答案跨度方面达到高准确率。

> **BERTserini** ([Yang et al., 2019](https://arxiv.org/abs/1902.01718)) utilizes a pre-trained BERT model to work as the reader. Their experiments showed that *fine-tuning* pretrained BERT with SQuAD is sufficient to achieve high accuracy in identifying answer spans.

![How BERT is used to solve question-answering tasks. (Image source: Devlin et al., 2018 )](https://lilianweng.github.io/posts/2020-10-29-odqa/BERT-RC.png)

BERTserini阅读器与原始BERT的关键区别在于：为了允许比较和聚合来自不同段的结果，移除了对不同答案跨度的最终softmax层。预训练的BERT模型在SQuAD的训练集上进行微调，其中阅读器的所有输入都填充到384个标记，学习率为3e-5。

> The key difference of the BERTserini reader from the original BERT is: to allow comparison and aggregation of results from different segments, the final softmax layer over different answer spans is removed. The pre-trained BERT model is fine-tuned on the training set of SQuAD, where all inputs to the reader are padded to 384 tokens with the learning rate 3e-5.

在对所有提取到的答案跨度进行排序时，检索器分数 (BM25) 和阅读器分数 (token 作为起始位置的概率 $\times$ 同一 token 作为结束位置的概率) 通过线性插值进行组合。

> When ranking all the extracted answer spans, the retriever score (BM25) and the reader score (probability of token being the start position $\times$ probability of the same token being the end position ) are combined via linear interpolation.

原始的BERT独立地对每个段落中每个token的起始和结束位置的概率分布进行归一化。不同的是，**多段落BERT**（[Wang et al., 2019](https://arxiv.org/abs/1908.08167)）[全局地](https://arxiv.org/abs/1710.10723)对一个问题所有检索到的段落的答案分数进行归一化。具体来说，多段落BERT移除了BERT QA中每个段落的最终归一化层（与BERTserini中相同），然后对所有段落的所有词位置添加了一个全局的`softmax`。全局归一化使得阅读器模型在从大量段落中精确定位答案时更加稳定。

> The original BERT normalizes the probability distributions of start and end position per token for every passage independently. Differently, the **Multi-passage BERT** ([Wang et al., 2019](https://arxiv.org/abs/1908.08167)) normalizes answer scores across all the retrieved passages of one question [globally](https://arxiv.org/abs/1710.10723). Precisely, multi-passage BERT removes the final normalization layer per passage in BERT for QA (same as in BERTserini) and then adds a global `softmax` over all the word positions of all the passages. Global normalization makes the reader model more stable while pin-pointing answers from a large number of passages.

此外，多段落BERT实现了一个独立的*段落排序器*模型，通过另一个BERT模型，并且$(x, z)$的排序分数$(x, z)$由一个 生成`softmax`作用于第一个 的表示向量`[CLS]`token。该段落排序器带来了额外的2%的改进。使用BERT对段落进行重排序的类似想法也在[Nogueira & Cho, 2019](https://arxiv.org/abs/1901.04085)中有所讨论。

> In addition, multi-passage BERT implemented an independent *passage ranker* model via another BERT model and the rank score for $(x, z)$ is generated by a `softmax` over the representation vectors of the first `[CLS]` token. The passage ranker brings in extra 2% improvements. Similar idea of re-ranking passages with BERT was discussed in [Nogueira & Cho, 2019](https://arxiv.org/abs/1901.04085), too.

有趣的是，[Wang et al., 2019](https://arxiv.org/abs/1908.08167) 发现 *显式的句子间匹配* 对于使用 BERT 的阅读理解（RC）任务来说似乎并非关键；关于实验是如何设计的，请查阅原始论文。一个可能的原因是 BERT 中的多头自注意力层已经嵌入了句子间的匹配信息。

> Interestingly, [Wang et al., 2019](https://arxiv.org/abs/1908.08167) found that *explicit inter-sentence matching* does not seem to be critical for RC tasks with BERT; check the original paper for how the experiments were designed. One possible reason is that the multi-head self-attention layers in BERT has already embedded the inter-sentence matching.

#### 端到端联合训练

> End-to-end Joint Training

检索器和阅读器组件可以联合训练。本节涵盖 R^3、ORQA、REALM 和 DPR。它们有很多共同的设计，例如用于检索的基于 BERT 的密集向量，以及最大化获得真实答案的边际似然的损失函数。

> The retriever and reader components can be jointly trained. This section covers R^3, ORQA, REALM and DPR. There are a lot of common designs, such as BERT-based dense vectors for retrieval and the loss function on maximizing the marginal likelihood of obtaining true answers.

在**R^3**（“强化排序器-阅读器”；[Wang, et al., 2017](https://arxiv.org/abs/1709.00023)）问答系统中，检索器和阅读器模型通过[强化学习](https://lilianweng.github.io/posts/2018-02-19-rl-overview/)联合训练。（请注意，为了保持本节中不同论文术语的一致性，原始 R^3 论文中的“排序器”模型在此处被称为“检索器”模型。）这两个组件都是[Match-LSTM](https://arxiv.org/abs/1512.08849)的变体，它依赖于注意力机制来计算段落和问题序列之间的词语相似度。

> The retriever and reader models in the **R^3** (“Reinforced Ranker-Reader”; [Wang, et al., 2017](https://arxiv.org/abs/1709.00023)) QA system are jointly trained via [reinforcement learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/). (Note that to keep the term consistent between papers in this section, the “ranker” model in the original R^3 paper is referred to as the “retriever” model here.) Both components are variants of [Match-LSTM](https://arxiv.org/abs/1512.08849), which relies on an attention mechanism to compute word similarities between the passage and question sequences.

**Match-LSTM 模块是如何工作的？**给定一个问题$\mathbf{X}$的`d_x`词，以及一个段落$\mathbf{Z}$的`d_z`词，这两种表示都使用固定的[Glove](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#glove-global-vectors)词嵌入，

英文原文：How does the Match-LSTM module work? Given a question 

$\mathbf{X}$ of `d_x` words and a passage 

$\mathbf{Z}$ of `d_z` words, both representations use fixed [Glove](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#glove-global-vectors) word embeddings,

$$
\begin{aligned}
\mathbf{H}^x &= \text{BiLSTM}(\mathbf{X}) \in \mathbb{R}^{l \times d_x} \\
\mathbf{H}^z &= \text{BiLSTM}(\mathbf{Z}) \in \mathbb{R}^{l \times d_z} \\
\mathbf{G} &= \text{softmax}((\mathbf{W}^g \mathbf{H}^x + \mathbf{b}^g \otimes \mathbf{e}_{d_x})^\top \mathbf{H}^z) \in \mathbb{R}^{d_x \times d_z} & \text{; an attention matrix}\\
\bar{\mathbf{H}}^x &= \mathbf{H}^x \mathbf{G} \in \mathbb{R}^{l \times d_z} \\
\mathbf{M} &= \text{ReLU} \Big( \mathbf{W}^m \begin{bmatrix}
\mathbf{H}^z \\
\bar{\mathbf{H}}^x \\
\mathbf{H}^z \odot \bar{\mathbf{H}}^x \\
\mathbf{H}^z - \bar{\mathbf{H}}^x
\end{bmatrix} \Big) \in \mathbb{R}^{2l \times d_z} \\
\mathbf{H}^m &= \text{BiLSTM}(M) \in \mathbb{R}^{l \times d_z}
\end{aligned}
$$

其中 $l$ 是双向 LSTM 模块的隐藏维度。$\mathbf{W}^g \in \mathbb{R}^{l\times l}$、$\mathbf{b}^g \in \mathbb{R}^l$ 和 $\mathbf{W}^m \in \mathbb{R}^{2l \times 4l}$ 是待学习的参数。运算符 $\otimes \mathbf{e}_{d_x}$ 是外积，用于将列向量 $\mathbf{b}^g$ 重复 $d_x$ 次。

> where $l$ is the hidden dimension of the bidirectional LSTM module. $\mathbf{W}^g \in \mathbb{R}^{l\times l}$, $\mathbf{b}^g \in \mathbb{R}^l$, and $\mathbf{W}^m \in \mathbb{R}^{2l \times 4l}$ are parameters to learn. The operator $\otimes \mathbf{e}_{d_x}$ is the outer product to repeat the column vector $\mathbf{b}^g$ $d_x$ times.

排序器和阅读器组件共享相同的 Match-LSTM 模块，但在最后一层有两个独立的预测头，从而产生 $\mathbf{H}^\text{rank}$ 和 $\mathbf{H}^\text{reader}$。

> The ranker and reader components share the same Match-LSTM module with two separate prediction heads in the last layer, resulting in $\mathbf{H}^\text{rank}$ and $\mathbf{H}^\text{reader}$.

![The overview of R^3 (reinforced ranker-reader) architecture. Both components share the same Match-LSTM module. (Image source: Wang, et al., 2017 )](https://lilianweng.github.io/posts/2020-10-29-odqa/R^3-arch.png)

检索器对每个段落运行最大池化操作，然后进行聚合，以输出每个段落包含答案的概率。

> The retriever runs a max-pooling operation per passage and then aggregates to output a probability of each passage entailing the answer.

$$
\begin{aligned}
\mathbf{u}_i &= \text{max-pooling}(\mathbf{H}^\text{rank}_i) \in \mathbb{R}^l \\
\mathbf{C} &= \text{tanh}(\mathbf{W}^c[\mathbf{u}_1;\dots;\mathbf{u}_N] + \mathbf{b}^c \otimes \mathbf{e}_N) \in \mathbb{R}^{l \times n} \\
\gamma &= \text{softmax}(\mathbf{w}^c \mathbf{C}) \in \mathbb{R}^n
\end{aligned}
$$

最后，检索器被视为一种*策略*，用于根据预测的$\gamma$输出动作以采样一个段落，

> Finally, the retriever is viewed as a *policy* to output action to sample a passage according to predicted $\gamma$,

$$
\pi(z \vert x; \theta^\gamma) = \gamma_z
$$

阅读器预测答案跨度的起始位置$\beta^s$和结束位置$\beta^e$。这两个位置以相同的方式计算，并具有独立的学习参数。所有相关段落中共有$V$个词。

> The reader predicts the start position $\beta^s$ and the end position $\beta^e$ of the answer span. Two positions are computed in the same way, with independent parameters to learn. There are $V$ words in all the passages involved.

$$
\begin{aligned}
\mathbf{H}^\text{read} &= [\mathbf{H}^\text{read}_\tau; \mathbf{H}^\text{read}_{\text{neg}_1}; \dots; \mathbf{H}^\text{read}_{\text{neg}_n}] \\
\mathbf{F}^s &= \text{tanh}(\mathbf{W}^s \mathbf{H}^\text{read} + \mathbf{b}^s \otimes \mathbf{e}_V) \quad
\beta^s = \text{softmax}(\mathbf{w}^s \mathbf{F}^s) \in \mathbb{R}^V \\
\mathbf{F}^e &= \text{tanh}(\mathbf{W}^e \mathbf{H}^\text{read} + \mathbf{b}^e \otimes \mathbf{e}_V) \quad
\beta^e = \text{softmax}(\mathbf{w}^e \mathbf{F}^e) \in \mathbb{R}^V \\
L(y \vert z, x) &= -\log(\beta^s_{y_z^s})-\log(\beta^e_{y_z^e})
\end{aligned}
$$

其中$y$是真实答案，段落$z$由检索器采样。$\beta^s_{y_z^s}$和$\beta^s_{y_z^e}$表示$y$在段落$z$中的起始和结束位置的概率。

> where $y$ is the ground-truth answer and the passage $z$ is sampled by the retriever. $\beta^s_{y_z^s}$ and $\beta^s_{y_z^e}$ represent the probabilities of the start and end positions of $y$ in passage $z$.

端到端 R^3 QA 系统的训练目标是最小化获得正确答案的负对数似然$y$，给定一个问题$x$，

> The training objective for the end-to-end R^3 QA system is to minimize the negative log-likelihood of obtaining the correct answer $y$ given a question $x$,

$$
\begin{aligned}
\mathcal{J}(\theta) &= -\mathbb{E}_{z\sim\pi(.\vert x)} [L(y \vert z, x)] \\
\nabla \mathcal{J}(\theta) 
&= - \nabla_\theta \sum_z \pi(z \vert x) L(y \vert z, x) \\
&= - \sum_z \big( L(y \vert z, x) \nabla_\theta\pi(z \vert x) + \pi(z \vert x) \nabla_\theta L(y \vert z, x) \big) \\
&= - \mathbb{E}_{z\sim\pi(.\vert x)} \big( \color{red}{L(y \vert z, x)\nabla_\theta\log\pi(z \vert x)} + \nabla_\theta L(y \vert z, x) \big) \\
&\approx - \mathbb{E}_{z\sim\pi(.\vert x)} \big( \underbrace{\color{red}{R(y \vert z, x)\nabla_\theta\log\pi(z \vert x)}}_\text{REINFORCE} + \nabla_\theta L(y \vert z, x) \big)
\end{aligned}
$$

本质上，在训练中，给定由检索器采样的段落$z$，阅读器通过梯度下降进行训练，而检索器则通过[REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce)，使用$L(y \vert z, x)$作为奖励函数进行训练。然而，$L(y \vert z, x)$没有边界，可能会引入很大的方差。该论文通过比较真实值$y$和阅读器提取的答案$\hat{y}$，用定制的评分函数替换了奖励：

> Essentially in training, given a passage $z$ sampled by the retriever, the reader is trained by gradient descent while the retriever is trained by [REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce) using $L(y \vert z, x)$ as the reward function. However, $L(y \vert z, x)$ is not bounded and may introduce a lot of variance. The paper replaces the reward with a customized scoring function by comparing the ground truth $y$ and the answer extracted by the reader $\hat{y}$:

$$
R(y, \hat{y} \vert z) = \begin{cases} 2 & \text{if } y = \hat{y}\\ f1(y, \hat{y}) & \text{if } y \cap \hat{y} = \varnothing \\ -1 & \text{otherwise} \end{cases}
$$

![The workflow of R^3 training process. (Image source: acl2020-openqa-tutorial/slides/part4 )](https://lilianweng.github.io/posts/2020-10-29-odqa/R^3-reward-flow.png)

**ORQA**（“开放检索问答”；[Lee et al., 2019](https://arxiv.org/abs/1906.00300)）联合学习一个检索器+阅读器问答模型，以监督方式优化获得正确答案的边际对数似然。不涉及任何明确的“黑盒”信息检索系统。相反，它能够从开放语料库中检索任何文本。在训练期间，ORQA不需要真实上下文段落（即阅读理解数据集），而只需要（问题，答案）字符串对。检索器和阅读器组件都基于BERT，但它们不共享。

> **ORQA** (“Open-Retrieval Question-Answering”; [Lee et al., 2019](https://arxiv.org/abs/1906.00300)) jointly learns a retriever + reader QA model to optimize marginal log-likelihood of obtaining correct answers in a supervised manner. No explicit “black-box” IR system is involved. Instead, it is capable of retrieving any text in an open corpus. During training, ORQA does not need ground-truth context passages (i.e. reading comprehension datasets) but only needs (question, answer) string pairs. Both retriever and reader components are based on BERT, but not shared.

![An illustration of the retriever component in ORQA. (Image source: replotted based on one slide in acl2020-openqa-tutorial/slides/part5 )](https://lilianweng.github.io/posts/2020-10-29-odqa/ORQA-retriever.png)

所有证据块都通过检索分数进行排序，该分数定义为BERT嵌入向量的内积，这些向量来自`[CLS]`问题的token$x$和证据块$z$。请注意，问题和上下文的编码器是独立的。

> All the evidence blocks are ranked by a retrieval score, defined as the inner product of BERT embedding vectors of the `[CLS]` token of the question $x$ and the evidence block $z$. Note that the encoders for questions and context are independent.

$$
\begin{aligned}
h_x &= \mathbf{W}_x \text{BERT}_x(x)^{\mathtt{[CLS]}} \\
h_z &= \mathbf{W}_z \text{BERT}_z(z)^{\mathtt{[CLS]}} \\
S_\text{retr}(z, x) &= h_x^\top h_z
\end{aligned}
$$

检索器模块通过*逆完形填空任务（ICT）*进行预训练，其目标是根据一个句子预测上下文，这与标准的[完形填空任务](https://en.wikipedia.org/wiki/Cloze_test)相反。ICT 的目标是最大化正确上下文的检索分数$z$，给定一个随机句子$x$：

> The retriever module is pretrained with *Inverse Cloze Task (ICT)*, which is to predict the context given a sentence, opposite to the standard [Cloze Task](https://en.wikipedia.org/wiki/Cloze_test). The ICT objective is to maximize the retrieval score of the correct context $z$ given a random sentence $x$:

$$
L_\text{ICT} = p_\text{early}(z \vert x) = \frac{\exp(S_\text{retr}(z, x))}{\sum_{z'\in\text{BATCH}(\mathcal{Z})} \exp(S_\text{retr}(z', x))}
$$

其中 $\text{BATCH}(\mathcal{Z})$ 是同一批次中用作采样负例的证据块集合。

> where $\text{BATCH}(\mathcal{Z})$ is the set of evidence blocks in the same batch used as sampled negatives.

经过这样的预训练后，BERT 检索器有望获得足以用于证据检索的表示。只有问题编码器需要进行微调以进行答案提取。换句话说，证据块编码器（即 $\mathbf{W}_z$ 和 $\text{BERT}_z$）是固定的，因此所有证据块编码都可以预先计算，并支持 [快速最大内积搜索 (MIPS)](https://lilianweng.github.io/posts/2020-10-29-odqa/#fast-maximum-inner-product-search-mips)。

> After such pretraining, the BERT retriever is expected to have representations good enough for evidence retrieval. Only the question encoder needs to be fine-tuned for answer extraction. In other words, the evidence block encoder (i.e., $\mathbf{W}_z$ and $\text{BERT}_z$) is fixed and thus all the evidence block encodings can be pre-computed with support for [fast Maximum Inner Product Search (MIPS)](https://lilianweng.github.io/posts/2020-10-29-odqa/#fast-maximum-inner-product-search-mips).

![An illustration of the reader component in ORQA. (Image source: acl2020-openqa-tutorial/slides/part5 )](https://lilianweng.github.io/posts/2020-10-29-odqa/ORQA-reader.png)

阅读器遵循与原始 [BERT RC](https://lilianweng.github.io/posts/2019-01-31-lm/#use-bert-in-downstream-tasks) 实验相同的设计。它以监督方式学习，同时证据块编码器的参数是固定的，所有其他参数都经过微调。给定问题 $x$ 和黄金答案字符串 $y$，阅读器损失包含两部分：

> The reader follows the same design as in the original [BERT RC](https://lilianweng.github.io/posts/2019-01-31-lm/#use-bert-in-downstream-tasks) experiments. It learns in a supervised manner, while the parameters of the evidence block encoder are fixed and all other parameters are fine-tuned. Given a question $x$ and a gold answer string $y$, the reader loss contains two parts:

$$
\mathcal{L}(x, y) = \mathcal{L}_\text{early}(x, y) + \mathcal{L}_\text{full}(x, y)
$$

(1) 在顶部 $k$ 证据块中找到所有正确的文本跨度，并优化文本跨度 $s$ 的边际似然，使其与真实答案 $y$ 匹配：

> (1) Find all correct text spans within top $k$ evidence blocks and optimize for the marginal likelihood of a text span $s$ that matches the true answer $y$:

$$
\begin{aligned}
h_s &= \text{BERT}_R(x, y)^{(\text{START}(s))} \\
h_e &= \text{BERT}_R(x, y)^{(\text{END}(s))} \\
S_\text{read}(z, s, x) &= \text{MLP}([h_s; h_e]) \\
p(z, s \vert x) &= \frac{\exp(S_\text{read}(z, s, x))}{\sum_{z'\in\text{TOP}(k)} \sum_{s'\in z'} \exp(S_\text{read}(z', s', x))} \\
L_\text{full}(x, y) &= - \log \sum_{\substack{z \in \text{TOP}(k)\\ s \in z}} \sum_{y=\text{TEXT}(s)} p(z, s \vert x)
\end{aligned}
$$

其中$y=\text{TEXT}(s)$表示答案是否$y$与文本片段$s$。$\text{TOP}(k)$是前$k$个检索到的块，根据$S_\text{retr}(z, x)$。该论文设置了$k=5$。

> where $y=\text{TEXT}(s)$ indicates whether the answer $y$ matches the text span $s$. $\text{TOP}(k)$ is the top $k$ retrieved blocks according to $S_\text{retr}(z, x)$. The paper sets $k=5$.

(2) 在学习的早期阶段，当检索器不够强大时，前 $k$ 个块中可能不包含答案。为了避免这种稀疏的学习信号，ORQA 考虑了更大一组的 $c$ 证据块，以进行更积极的学习。该论文有 $c=5000$。

> (2) At the early stage of learning, when the retriever is not strong enough, it is possible none of the top $k$ blocks contains the answer. To avoid such sparse learning signals, ORQA considers a larger set of $c$ evidence blocks for more aggressive learning. The paper has $c=5000$.

$$
L_\text{early}(x, y)
= -\log \sum_{\substack{z\in \text{TOP}(c)\\y\in\text{TEXT}(z)}} p_\text{early}(z\vert x)
= -\log \sum_{\substack{z\in \text{TOP}(c)\\y\in\text{TEXT}(z)}} \frac{\exp(S_\text{retr}(z, x)}{\sum_{z'\in\text{TOP}(c)} \exp(S_\text{retr}(z', x)}
$$

ORQA 论文中讨论了 SQuAD 数据集的一些问题：

> Some issues in SQuAD dataset were discussed in the ORQA paper:

> " SQuAD 开发集和测试集准确率之间的显著下降反映了数据集中的一个缺陷——其 10 万个问题仅来源于 536 份文档。因此，好的检索目标在训练样本之间高度相关，这违反了独立同分布（IID）假设，使其不适合学习检索。我们强烈建议那些对端到端开放域问答模型感兴趣的人，因此不再使用 SQuAD 进行训练和评估。"

> " The notable drop between development and test accuracy for SQuAD is a reflection of an artifact in the dataset—its 100k questions are derived from only 536 documents. Therefore, good retrieval targets are highly correlated between training examples, violating the IID assumption, and making it unsuitable for learned retrieval. We strongly suggest that those who are interested in end-to-end open-domain QA models no longer train and evaluate with SQuAD for this reason."

**REALM** （“检索增强语言模型预训练”；[Guu et al., 2020](https://arxiv.org/abs/2002.08909)）也通过优化获得真实答案的边际似然来联合训练检索器 + 阅读器：

> **REALM** (“Retrieval-Augmented Language Model pre-training”; [Guu et al., 2020](https://arxiv.org/abs/2002.08909)) also jointly trains retriever + reader by optimizing the marginal likelihood of obtaining the true answer:

$$
p(y \vert x) 
= \sum_{z \in \mathcal{Z}} \underbrace{p(y \vert x, z)}_\text{reader} \underbrace{p(z \vert x)}_\text{retriever}
\approx \sum_{z \in \text{TOP}_k(\mathcal{Z})} p(y \vert x, z) p(z \vert x)
$$

![REALM is first unsupervised pre-trained with salient spans masking and then fine-tuned with QA data. (Image source: Guu et al., 2020 ).](https://lilianweng.github.io/posts/2020-10-29-odqa/REALM-train.png)

REALM 计算两个概率，$p(z \vert x)$ 和 $p(y \vert x, z)$，与 ORQA 相同。然而，与 ORQA 中的 ICT 不同，REALM 通过几项新的设计决策升级了无监督预训练步骤，从而实现了更好的检索。REALM 使用 Wikipedia 或 CC-News 语料库对模型进行预训练。

> REALM computes two probabilities, $p(z \vert x)$ and $p(y \vert x, z)$, same as ORQA. However, different from ICT in ORQA, REALM upgrades the unsupervised pre-training step with several new design decisions, leading towards better retrievals. REALM pre-trains the model with Wikipedia or CC-News corpus.

1. 使用 *显著跨度掩码*。识别命名实体和日期。然后选择并掩盖其中一个“显著跨度”。显著跨度掩码是 MLM 的一个特例，对问答任务效果很好。
2. 添加一个 *空空文档*。因为并非每个问题都需要上下文文档。
3. 无平凡检索。上下文文档不应与带有掩码跨度的所选句子相同。
4. 应用与 ORQA 中相同的 ICT 损失，以鼓励在训练早期检索质量仍然较差时进行学习。

> • Use *salient span masking*. Named entities and dates are identified. Then one of these “salient spans” is selected and masked. Salient span masking is a special case of MLM and works out well for QA tasks.
> • Add an *empty null document*. Because not every question demands a context document.
> • No trivial retrieval. The context document should not be same as the selected sentence with a masked span.
> • Apply the same ICT loss as in ORQA to encourage learning when the retrieval quality is still poor at the early stage of training.

> “在所有系统中，与 REALM 最直接的比较是 ORQA (Lee et al., 2019)，它们的微调设置、超参数和训练数据都相同。REALM 相对于 ORQA 的改进纯粹是由于更好的预训练方法。”——摘自 REALM 论文。

> “Among all systems, the most direct comparison with REALM is ORQA (Lee et al., 2019), where the fine-tuning setup, hyperparameters and training data are identical. The improvement of REALM over ORQA is purely due to better pre-training methods.” — from REALM paper.

无监督预训练和有监督微调都优化相同的对数似然 $\log p(y \vert x)$。由于证据文档的检索器编码器参数在此过程中也会更新，因此 MIPS 的索引正在发生变化。REALM 每隔几百个训练步骤就会使用更新后的编码器参数异步刷新索引。

> Both unsupervised pre-training and supervised fine-tuning optimize the same log-likelihood $\log p(y \vert x)$. Because the parameters of the retriever encoder for evidence documents are also updated in the process, the index for MIPS is changing. REALM asynchronously refreshes the index with the updated encoder parameters every several hundred training steps.

[Balachandran, et al. (2021)](https://arxiv.org/abs/2104.08710) 发现 REALM 存在显著的训练不足，REALM++ 通过使用更大的批量大小和更多的检索文档供阅读器处理来扩展模型训练，从而实现了 EM 准确率的显著提高（3-5%）。

> [Balachandran, et al. (2021)](https://arxiv.org/abs/2104.08710) found that REALM is significantly undertrained and REALM++ achieves great EM accuracy improvement (3-5%) by scaling up the model training with larger batch size and more retrieved documents for the reader to process.

**DPR**（“密集段落检索器”；[Karpukhin et al., 2020](https://arxiv.org/abs/2004.04906)，[代码](https://github.com/facebookresearch/DPR)）认为 ICT 预训练可能计算成本过高，并且 ORQA 的上下文编码器可能不是最优的，因为它没有使用问答对进行微调。DPR 旨在通过仅使用少量问答对训练一个用于检索的密集双编码器架构来解决这两个问题，而无需任何预训练。

> **DPR** (“Dense Passage Retriever”; [Karpukhin et al., 2020](https://arxiv.org/abs/2004.04906), [code](https://github.com/facebookresearch/DPR)) argues that ICT pre-training could be too computationally expensive and the ORQA’s context encoder might be sub-optimal because it is not fine-tuned with question-answer pairs. DPR aims to resolve these two issues by only training a dense dual-encoder architecture for retrieval only from a small number of Q/A pairs, without any pre-training.

与之前的工作相同，DPR 使用 BERT 表示的点积（L2 距离或余弦相似度也适用）作为检索分数。用于训练双编码器的损失函数是正向段落的 NLL，其公式本质上与 ORQA 的 [ICT 损失](https://lilianweng.github.io/posts/2020-10-29-odqa/#ICT-loss)相同。请注意，它们都将同一批次中的其他段落视为负样本，称为 *批内负采样*。主要区别在于 DPR 依赖于有监督的问答数据，而 ORQA 则在无监督语料库上使用 ICT 进行训练。在推理时，DPR 使用 [FAISS](https://github.com/facebookresearch/faiss) 运行快速 MIPS。

> Same as previous work, DPR uses the dot-product (L2 distance or cosine similarity also works) of BERT representations as retrieval score. The loss function for training the dual-encoder is the NLL of the positive passage, which essentially takes the same formulation as [ICT loss](https://lilianweng.github.io/posts/2020-10-29-odqa/#ICT-loss) of ORQA. Note that both of them consider other passages in the same batch as the negative samples, named *in-batch negative sampling*. The main difference is that DPR relies on supervised QA data, while ORQA trains with ICT on unsupervised corpus. At the inference time, DPR uses [FAISS](https://github.com/facebookresearch/faiss) to run fast MIPS.

DPR 进行了一系列涉及几种不同类型负样本的比较实验：

> DPR did a set of comparison experiments involving several different types of negatives:

1. 随机：语料库中的任意随机段落；
2. BM25：BM25返回的顶部段落，这些段落不包含答案但匹配大多数问题词元；
3. 批内负采样（“黄金”）：与训练集中出现的其他问题配对的阳性段落。

> • Random: any random passage from the corpus;
> • BM25: top passages returned by BM25 which don’t contain the answer but match most question tokens;
> • In-batch negative sampling (“gold”): positive passages paired with other questions which appear in the training set.

DPR发现，使用来自同一mini-batch的黄金段落和一个具有高BM25分数的负面段落效果最佳。为了进一步提高检索结果，DPR还探索了一种设置，其中BM25分数和密集嵌入检索分数线性组合，作为新的排名函数。

> DPR found that using gold passages from the same mini-batch and one negative passage with high BM25 score works the best. To further improve the retrieval results, DPR also explored a setting where a BM25 score and a dense embedding retrieval score are linearly combined to serve as a new ranking function.

### 开放域问答：检索器-生成器

> Open-book QA: Retriever-Generator

与检索器-阅读器方法相比，检索器-生成器也有两个阶段，但第二阶段是直接生成自由文本来回答问题，而不是在检索到的段落中提取开始/结束位置。一些论文也将此称为*生成式问答*。

> Compared to the retriever-reader approach, the retriever-generator also has 2 stages but the second stage is to generate free text directly to answer the question rather than to extract start/end position in a retrieved passage. Some paper also refer to this as *Generative question answering*.

![The retriever + generator QA framework combines a document retrieval system with a general language model.](https://lilianweng.github.io/posts/2020-10-29-odqa/QA-retiever-generator.png)

预训练语言模型（LM）在其参数中具有强大的知识记忆能力，如上所示。然而，它们不能轻易修改或扩展其记忆，不能直接提供对其预测的洞察，并且可能会产生不存在的幻觉。

> A pretrained LM has a great capacity of memorizing knowledge in its parameters, as shown above. However, they cannot easily modify or expand their memory, cannot straightforwardly provide insights into their predictions, and may produce non-existent illusion.

[Petroni 等人 (2020)](https://arxiv.org/abs/2005.04611) 研究了检索到的相关上下文如何帮助生成式语言模型产生更好的答案。他们发现：

> [Petroni et al. (2020)](https://arxiv.org/abs/2005.04611) studied how the retrieved relevant context can help a generative language model produce better answers. They found:

1. 用相关上下文增强查询显著提高了预训练语言模型在无监督机器阅读能力方面的表现。
2. 一个现成的IR系统足以让BERT匹配有监督ODQA基线的性能；
3. BERT的[NSP](https://lilianweng.github.io/posts/2019-01-31-lm/#pre-training-tasks)预训练策略是一种高效的无监督机制，用于处理噪声和不相关的上下文。

> • Augmenting queries with relevant contexts dramatically improves the pretrained LM on unsupervised machine reading capabilities.
> • An off-the-shelf IR system is sufficient for BERT to match the performance of a supervised ODQA baseline;
> • BERT’s [NSP](https://lilianweng.github.io/posts/2019-01-31-lm/#pre-training-tasks) pre-training strategy is a highly effective unsupervised mechanism in dealing with noisy and irrelevant contexts.

他们将 BERT 模型与不同类型的上下文配对，包括对抗性（不相关的上下文）、检索性（通过 BM25）和生成性（通过在 CC-NEWS 上训练的具有 1.4N 参数的自回归语言模型）。发现该模型对对抗性上下文具有鲁棒性，但仅限于问题和上下文作为两个片段提供时（例如，由 `[SEP]` 分隔）。一个假设与 NSP 任务有关：“如果 NSP 分数较低，BERT 可能会学到不对跨片段进行掩码标记预测的条件，从而隐式地检测到不相关和嘈杂的上下文。”

> They pair the BERT model with different types of context, including adversarial (unrelated context), retrieved (by BM25), and generative (by an autoregressive language model of 1.4N parameters, trained on CC-NEWS). The model is found to be robust to adversarial context, but only when the question and the context are provided as two segments (e.g. separated by `[SEP]`). One hypothesis is related to NSP task: “BERT might learn to not condition across segments for masked token prediction if the NSP score is low, thereby implicitly detecting irrelevant and noisy contexts.”

**RAG**（“检索增强生成”；[Lewis 等人，2020](https://arxiv.org/abs/2005.11401)）将预训练的参数化（语言模型）和非参数化记忆（外部知识索引）结合起来进行语言生成。RAG 可以在任何 seq2seq 任务上进行微调，其中检索器和序列生成器都是联合学习的。他们发现无约束生成优于以前的抽取式方法。

> **RAG** (“Retrieval-Augmented Generation”; [Lewis et al., 2020](https://arxiv.org/abs/2005.11401)) combines pre-trained parametric (language model) and non-parametric memory (external knowledge index) together for language generation. RAG can be fine-tuned on any seq2seq task, whereby both the retriever and the sequence generator are jointly learned. They found that unconstrained generation outperforms previous extractive approaches.

RAG 由一个检索器模型 $p_\eta(z \vert x)$ 和一个生成器模型 $p_\theta(y_i \vert x, z, y_{1:i-1})$ 组成：

> RAG consists of a retriever model $p_\eta(z \vert x)$ and a generator model $p_\theta(y_i \vert x, z, y_{1:i-1})$:

• 检索器使用输入序列 $x$ 来检索文本段落 $z$，其实现方式是 [DPR](https://lilianweng.github.io/posts/2020-10-29-odqa/#DPR) 检索器。$\log p_\eta(z \vert x) \propto E_z(z)^\top E_x(x)$。

• 生成器使用 $z$ 作为额外上下文，在生成目标序列 $y$ 时，其中上下文和问题被简单地连接起来。

英文原文：

• The retriever uses the input sequence $x$ to retrieve text passages $z$, implemented as a [DPR](https://lilianweng.github.io/posts/2020-10-29-odqa/#DPR) retriever. $\log p_\eta(z \vert x) \propto E_z(z)^\top E_x(x)$.

• The generator uses $z$ as additional context when generating the target sequence $y$, where the context and the question are simply concatenated.

根据每个token生成时是使用相同还是不同的检索文档，RAG有两种版本：

> Depending on whether using the same or different retrieved documents for each token generation, there are two versions of RAG:

$$
\begin{aligned}
p_\text{RAG-seq}(y \vert x) &= \sum_{z \in \text{TOP}_k(p_\eta(.\vert x))} p_\eta(z \vert x) \prod_i^N p_\theta(y_i \vert x, z, y_{1:i-1}) \\
p_\text{RAG-token}(y \vert x) &= \prod_i^N \sum_{z \in \text{TOP}_k(p_\eta(.\vert x))} p_\eta(z_i\vert x) p_\theta(y_i \vert x, z_i, y_{1:i-1})
\end{aligned}
$$

RAG中的检索器+生成器经过联合训练以最小化NLL损失，$\mathcal{L}_\text{RAG} = \sum_j -\log p(y_j \vert x_j)$。更新段落编码器$E_z(.)$成本很高，因为它要求模型重新索引文档以实现快速MIPS。RAG认为微调$E_z(.)$不是必需的（例如在[ORQA](https://lilianweng.github.io/posts/2020-10-29-odqa/#ORQA)中），并且只更新查询编码器+生成器。

> The retriever + generator in RAG is jointly trained to minimize the NLL loss, $\mathcal{L}_\text{RAG} = \sum_j -\log p(y_j \vert x_j)$. Updating the passage encoder $E_z(.)$ is expensive as it requires the model to re-index the documents for fast MIPS. RAG does not find fine-tuning $E_z(.)$ necessary (like in [ORQA](https://lilianweng.github.io/posts/2020-10-29-odqa/#ORQA)) and only updates the query encoder + generator.

![An illustration of retrieval-augmented generation (RAG) architecture. (Image source: Lewis et al., 2020 )](https://lilianweng.github.io/posts/2020-10-29-odqa/RAG.png)

在解码/测试时，RAG-token可以通过[束搜索](https://d2l.ai/chapter_recurrent-modern/beam-search.html#id1)进行评估。RAG-seq不能分解为一组逐token的似然，因此它对每个候选文档$z$运行束搜索，并选择具有最优$p_\theta(y_i \vert x, z, y_{1:i-1})$的文档。

> At decoding/test time, RAG-token can be evaluated via a [beam search](https://d2l.ai/chapter_recurrent-modern/beam-search.html#id1). RAG-seq cannot be broken down into a set of per-token likelihood, so it runs beam search for each candidate document $z$ and picks the one with optimal $p_\theta(y_i \vert x, z, y_{1:i-1})$.

*Fusion-in-Decoder*方法，由[Izacard & Grave (2020)](https://arxiv.org/abs/2007.01282)提出，也基于预训练的T5模型。它的工作方式与RAG类似，但在上下文如何集成到解码器方面有所不同。

> The *Fusion-in-Decoder* approach, proposed by [Izacard & Grave (2020)](https://arxiv.org/abs/2007.01282) is also based on a pre-trained T5. It works similar to RAG but differently for how the context is integrated into the decoder.

1\. 检索前 $k$ 个各100词的相关段落，使用 BM25 或 DPR。

2\. 每个检索到的段落及其标题与问题连接起来，使用 `question:`、`title:` 和 `context:` 等特殊标记以指示内容差异。

3\. 每个检索到的段落都独立处理，然后才在解码器中组合。在编码器中独立处理段落使我们能够并行化计算。另一方面，联合处理它们鼓励更好地聚合多个证据。聚合部分在抽取式方法中是缺失的。

英文原文：

1\. Retrieve top $k$ related passage of 100 words each, using BM25 or DPR.

2\. Each retrieved passage and its title are concatenated with the question using special tokens like `question:`, `title:` and `context:` to indicate the content differences.

3\. Each retrieved passage is processed independently and later combined in the decoder. Processing passages independently in the encoder allows us to parallelize the computation. OTOH, processing them jointly encourages better aggregation of multiple pieces of evidence. The aggregation part is missing in extractive approaches.

请注意，他们确实为每个数据集独立地微调了预训练的语言模型。

> Note that they did fine-tune the pretrained LM independently for each dataset.

### 闭卷问答：生成式语言模型

> Closed-book QA: Generative Language Model

大型语言模型已在大量无监督文本语料库上进行了预训练。在参数足够多的情况下，这些模型能够将一些事实知识记忆在参数权重中。因此，我们可以使用这些模型进行问答，而无需明确的上下文，就像在闭卷考试中一样。预训练的语言模型生成*自由文本*来回答问题，无需明确的阅读理解。

> Big language models have been pre-trained on a large collection of unsupervised textual corpus. Given enough parameters, these models are able to memorize some factual knowledge within parameter weights. Therefore, we can use these models to do question-answering without explicit context, just like in a closed-book exam. The pre-trained language models produce *free text* to respond to questions, no explicit reading comprehension.

![The amount of computation used for training big language models of different sizes is getting big. (Image source: Brown et al., 2020 ).](https://lilianweng.github.io/posts/2020-10-29-odqa/LM-compute.png)

[Roberts et al. (2020)](https://arxiv.org/abs/2002.08910)通过微调预训练模型来回答问题，而无需访问任何外部上下文或知识，从而衡量了语言模型的实际效用。他们微调了[T5](https://arxiv.org/abs/1910.10683)语言模型（与原始Transformer架构相同），以在不输入任何额外信息或上下文的情况下回答问题。这种设置强制语言模型根据其在预训练期间内化的“知识”来回答问题。

> [Roberts et al. (2020)](https://arxiv.org/abs/2002.08910) measured the practical utility of a language model by fine-tuning a pre-trained model to answer questions without access to any external context or knowledge. They fine-tuned the [T5](https://arxiv.org/abs/1910.10683) language model (same architecture as the original Transformer) to answer questions without inputting any additional information or context. Such setup enforces the language model to answer questions based on “knowledge” that it internalized during pre-training.

![T5 is first pre-trained with salient span masking and then fine-tuned for each QA dataset to produce answers in free text. (Image source: Roberts et al. 2020 )](https://lilianweng.github.io/posts/2020-10-29-odqa/T5_SSM.png)

原始的T5模型是在多任务混合上进行预训练的，其中包括在C4（“Colossal Clean Crawled Corpus”）数据集上的无监督[“掩码语言建模”](https://lilianweng.github.io/posts/2019-01-31-lm/#use-bert-in-downstream-tasks)（MLM）任务，以及与有监督的翻译、摘要、分类和阅读理解任务一起进行微调。[Roberts, et al. (2020)](https://arxiv.org/abs/2002.08910)采用了一个预训练的T5模型，并继续使用维基百科语料库上的[显著跨度掩码](https://lilianweng.github.io/posts/2020-10-29-odqa/#ssm)进行预训练，这已被发现能显著提升ODQA的性能。然后他们为每个问答数据集独立地微调了模型。

> The original T5 models were pre-trained on a multi-task mixture including an unsupervised [“masked language modeling”](https://lilianweng.github.io/posts/2019-01-31-lm/#use-bert-in-downstream-tasks) (MLM) tasks on the C4 (“Colossal Clean Crawled Corpus”) dataset as well as fine-tuned altogether with supervised translation, summarization, classification, and reading comprehension tasks. [Roberts, et al. (2020)](https://arxiv.org/abs/2002.08910)  took a pre-trained T5 model and continued pre-training with [salient span masking](https://lilianweng.github.io/posts/2020-10-29-odqa/#ssm) over Wikipedia corpus, which has been found to substantially boost the performance for ODQA. Then they fine-tuned the model for each QA datasets independently.

通过预训练的 T5 语言模型 + 使用显著跨度掩码继续预训练 + 对每个 QA 数据集进行微调，

> With a pre-trained T5 language model +  continue pre-training with salient spans masking + fine-tuning for each QA dataset,

- 它可以在开放域问答中获得有竞争力的结果，而无需访问外部知识。
- 更大的模型可以获得更好的性能。例如，一个拥有 11B 参数的 T5 模型能够与拥有 3 个 BERT-base 模型（每个模型拥有 330M 参数）的 [DPR](https://lilianweng.github.io/posts/2020-10-29-odqa/#DPR) 性能相匹配。

> • It can attain competitive results in open-domain question answering without access to external knowledge.
> • A larger model can obtain better performance. For example, a T5 with 11B parameters is able to match the performance with [DPR](https://lilianweng.github.io/posts/2020-10-29-odqa/#DPR) with 3 BERT-base models, each with 330M parameters.

有趣的是，微调并非严格必要。GPT3 ([Brown et al., 2020](https://arxiv.org/abs/2005.14165)) 已在闭卷问答任务上进行了评估，*未进行任何梯度更新或微调*。在评估期间，这里的少样本、单样本和零样本设置仅指在文本输入中作为上下文提供了多少个示例：

> Interestingly, fine-tuning is not strictly necessary. GPT3 ([Brown et al., 2020](https://arxiv.org/abs/2005.14165)) has been evaluated on the closed book question answering task *without any gradient updates or fine-tuning*. During evaluation, the few-shot, one-shot and zero-shot settings here only refer to how many demonstrations are provided as context in the text input:

1. “少样本学习”：GPT3 被允许使用模型上下文窗口所能容纳的尽可能多的示例（通常为 10 到 100 个）。
2. “单样本学习”：只提供一个示例。
3. “零样本学习”：不允许提供任何示例，只向模型提供自然语言指令。

> • “few-shot learning”: GPT3 is allowed to take as many demonstrations as what can fit into the model’s context window (typically 10 to 100).
> • “one-shot learning”: only one demonstration is provided.
> • “zero-shot learning”: no demonstrations are allowed and only an instruction in natural language is given to the model.

性能随模型大小的增加而增长。在 TriviaQA 数据集上，使用示例的 GPT3 评估可以达到或超过经过微调的 SOTA 基线的性能。

> The performance grows with the model size. On the TriviaQA dataset, GPT3 evaluation with demonstrations can match or exceed the performance of SOTA baseline with fine-tuning.

![GPT3's performance on TriviaQA grows smoothly with the model size. More demonstrations lead to better performance. (Image source: Brown et al., 2020 ).](https://lilianweng.github.io/posts/2020-10-29-odqa/GPT3-triviaqa.png)

在 OpenAI API [playground viewer](https://beta.openai.com/playground/p/HMoho4552EHXrPLbmOIxpX4X) 中查看这个很酷的例子。模型能够以简短的答案回答事实性问题，并且在不知道答案时不会编造内容。我添加了最后两个问题，并要求模型用 `A:` 回答。该 API 仍处于测试版，因此您可能需要[申请](https://beta.openai.com/)才能进入等待列表。

> Check out this cool example in OpenAI API [playground viewer](https://beta.openai.com/playground/p/HMoho4552EHXrPLbmOIxpX4X). The model is able to answer factal questions in short answer and not to make up things when the model does not know the answer. I added the last two questions and asked the model to respond with `A:`. The API is still in beta version, so you might need to [apply](https://beta.openai.com/) to get on the wait list.

```
Q: Who is Batman?
A: Batman is a fictional comic book character.
##
Q: What is torsalplexity?
A: ?
##
Q: What is Devz9?
A: ?
##
Q: Who is George Lucas?
A: George Lucas is American film director and producer famous for creating Star Wars.
##
Q: What is the capital of California?
A: Sacramento.
##
Q: What orbits the Earth?
A: The Moon.
##
Q: Who is Fred Rickerson?
A: ?
##
Q: What is an atom?
A: An atom is a tiny particle that makes up everything.
##
Q: Who is Alvan Muntz?
A: ?
##
Q: What is Kozar-09?
A: ?
##
Q: How many moons does Mars have?
A: Two, Phobos and Deimos.
##
Q: What is COVID-19?
A: ?
##
Q: What is H1N1?
A: H1N1 is a strain of influenza.
```

### 相关技术

> Related Techniques

#### 快速最大内积搜索 (MIPS)

> Fast Maximum Inner Product Search (MIPS)

MIPS（最大内积搜索）是许多开放域问答模型中的关键组件。在检索器 + 阅读器/生成器框架中，来自知识源的大量段落被编码并存储在内存中。检索模型能够查询内存以识别与问题嵌入具有最大内积的顶部相关段落。

> MIPS (maximum inner product search) is a crucial component in many open-domain question answering models. In retriever + reader/generator framework, a large number of passages from the knowledge source are encoded and stored in a memory. A retrieval model is able to query the memory to identify the top relevant passages which have the maximum inner product with the question’s embedding.

我们需要快速 MIPS，因为预计算的段落表示的数量可能非常庞大。有几种方法可以在运行时实现快速 MIPS，例如 [非对称 LSH](https://papers.nips.cc/paper/5329-asymmetric-lsh-alsh-for-sublinear-time-maximum-inner-product-search-mips.pdf)、[数据依赖哈希](https://arxiv.org/abs/1501.01062) 和 [FAISS](https://github.com/facebookresearch/faiss)。

> We need fast MIPS because the number of precomputed passage representations can be gigantic. There are several ways to achieve fast MIPS at run time, such as [asymmetric LSH](https://papers.nips.cc/paper/5329-asymmetric-lsh-alsh-for-sublinear-time-maximum-inner-product-search-mips.pdf), [data-dependent hashing](https://arxiv.org/abs/1501.01062),  and [FAISS](https://github.com/facebookresearch/faiss).

#### 语言模型预训练

> Language Model Pre-training

如上所述，两种预训练任务对问答任务特别有帮助。

> Two pre-training tasks are especially helpful for QA tasks, as we have discussed above.

- 
**逆完形填空任务**（由 [ORQA](https://lilianweng.github.io/posts/2020-10-29-odqa/#ORQA) 提出）：[完形填空任务](https://en.wikipedia.org/wiki/Cloze_test)的目标是根据上下文预测被遮蔽的文本。逆完形填空任务 (ICT) 的预测方向相反，旨在给定一个句子的情况下预测其上下文。在问答任务的背景下，一个随机句子可以被视为一个伪问题，其上下文可以被视为伪证据。

- 
**显著跨度掩码**（由 [REALM](https://lilianweng.github.io/posts/2020-10-29-odqa/#REALM) 提出）：显著跨度掩码是语言模型训练中 MLM 任务的一个特例。首先，我们通过使用标注器识别命名实体和使用正则表达式识别日期来找到 *显著跨度*。然后选择并掩码其中一个检测到的显著跨度。任务是预测这个被掩码的显著跨度。


> • 
> **Inverse Cloze Task**  (proposed by [ORQA](https://lilianweng.github.io/posts/2020-10-29-odqa/#ORQA)): The goal of [Cloze Task](https://en.wikipedia.org/wiki/Cloze_test) is to predict masked-out text based on its context. The prediction of Inverse Cloze Task (ICT) is in the reverse direction, aiming to predict the context given a sentence. In the context of QA tasks, a random sentence can be treated as a pseudo-question, and its context can be treated as pseudo-evidence.
> • 
> **Salient Spans Masking** (proposed by [REALM](https://lilianweng.github.io/posts/2020-10-29-odqa/#REALM)): Salient span masking is a special case for MLM task in language model training. First, we find *salient spans* by using a tagger to identify named entities and a regular expression to identify dates. Then one of the detected salient spans is selected and masked. The task is to predict this masked salient span.

### 总结

> Summary

| 模型 | 检索器 | 阅读器 / 生成器 | 预训练 / 微调 | 端到端 |
| --- | --- | --- | --- | --- |
| DrQA | TF-IDF | 双向LSTM | – | 否 |
| BERTserini | Aserini + BM25 | 不带softmax层的BERT | 使用SQuAD进行微调 | 否 |
| Multi-passage BERT | ElasticSearch + BM25 | Multi-passage BERT + 段落排序器 |  | 否 |
| R^3 | 经典IR + Match-LSTM | Match-LSTM |  | 是 |
| ORQA | BERT嵌入的点积 | BERT-RC | 逆完形填空任务 | 是 |
| REALM | BERT嵌入的点积 | BERT-RC | 显著跨度掩码 | 是 |
| DPR | BERT嵌入的点积 | BERT-RC | 使用问答对进行监督训练 | 是 |
| DenSPI | 经典 + 神经信息检索 | – |  | 是 |
| T5 + SSM | – | T5 | 在CommonCrawl数据上进行SSM + 在问答数据上进行微调 | 是 |
| GPT3 | – | GPT3 | 在CommonCrawl数据上进行NSP | 是 |
| RAG | DPR检索器 | BART |  | 是 |
| Fusion-in-Decoder | BM25 / DPR检索器 | Transformer |  | 否 |

> 英文原表 / English original

| Model | Retriever | Reader / Generator | Pre-training / Fine-tuning | End2end |
| --- | --- | --- | --- | --- |
| DrQA | TF-IDF | Bi-directional LSTM | – | No |
| BERTserini | Aserini + BM25 | BERT without softmax layer | Fine-tune with SQuAD | No |
| Multi-passage BERT | ElasticSearch + BM25 | Multi-passage BERT + Passage ranker |  | No |
| R^3 | Classic IR + Match-LSTM | Match-LSTM |  | Yes |
| ORQA | Dot product of BERT embeddings | BERT-RC | Inverse cloze task | Yes |
| REALM | Dot product of BERT embeddings | BERT-RC | Salient span masking | Yes |
| DPR | Dot product of BERT embeddings | BERT-RC | supervised training with QA pairs | Yes |
| DenSPI | Classic + Neural IR | – |  | Yes |
| T5 + SSM | – | T5 | SSM on CommonCrawl data + Fine-tuning on QA data | Yes |
| GPT3 | – | GPT3 | NSP on CommonCrawl data | Yes |
| RAG | DPR retriever | BART |  | Yes |
| Fusion-in-Decoder | BM25 / DPR retriever | Tranformer |  | No |

![A comparison of performance of several QA models on common QA datasets. On TriviaQA, two columns of results are reported, on the open domain test set (left) and on the hidden test set (right). (Image source: Izacard & Grave, 2020 ).](https://lilianweng.github.io/posts/2020-10-29-odqa/QA-results.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2020年10月). How to build an open-domain question answering system? Lil’Log. https://lilianweng.github.io/posts/2020-10-29-odqa/.

> Weng, Lilian. (Oct 2020). How to build an open-domain question answering system? Lil’Log. https://lilianweng.github.io/posts/2020-10-29-odqa/.

或

> Or

```
@article{weng2020odqa,
  title   = "How to Build an Open-Domain Question Answering System?",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2020",
  month   = "Oct"
  url     = "https://lilianweng.github.io/posts/2020-10-29-odqa/"
}
```

### 附录：问答数据集

> Appendix: QA Datasets

- [SQuAD 2.0](https://rajpurkar.github.io/SQuAD-explorer/): 斯坦福问答数据集。
- [RACE](http://www.qizhexie.com/data/RACE_leaderboard): 一个阅读理解数据集，收集自为初中生和高中生设计的英语考试。
- [TREC QA](https://trec.nist.gov/data/qa.html): TREC问答集合。
- [MS MARCO](https://microsoft.github.io/msmarco/): 一个问答数据集，包含100,000个真实的Bing问题和一个人工生成的答案。
- [CuratedTREC](https://github.com/brmson/dataset-factoid-curated): 基于由[Baudis & Sedivy (2015)](https://link.springer.com/chapter/10.1007%2F978-3-319-24027-5_20)整理的TREC问答任务基准。
- [Google Natural Questions](https://ai.google.com/research/NaturalQuestions/dataset): 包含向Google搜索发出的真实用户问题，以及标注者从维基百科中找到的答案。
- [WebQuestions](https://github.com/brmson/dataset-factoid-webquestions): 专为知识库问答设计，答案仅限于Freebase实体。
- [WikiQA](https://www.microsoft.com/en-us/research/publication/wikiqa-a-challenge-dataset-for-open-domain-question-answering/): Bing查询日志被用作问题来源。每个问题随后被链接到一个可能包含答案的维基百科页面。
- [WikiMovies](https://research.fb.com/downloads/babi/): 包含来自OMDb和MovieLens数据库的电影相关问题，这些问题可以使用维基百科页面回答。
- [WikiReading](https://github.com/google-research-datasets/wiki-reading): 通过阅读相应的维基百科文章文本，从结构化知识库Wikidata中预测文本值。
- [TriviaQA](https://nlp.cs.washington.edu/triviaqa/): 一个阅读理解数据集，包含9.5万个由问答爱好者撰写的问答对，并为每个问题独立收集了多个证据文档。
- [ Jeopardy! Questions](https://www.kaggle.com/tunguz/200000-jeopardy-questions): 包含20万+ [Jeopardy!](https://en.wikipedia.org/wiki/Jeopardy!) 问题。
- [DeepMind Q&A Dataset](https://cs.nyu.edu/~kcho/DMQA/): 来自CNN和Daily Mail文章的问答对。
- [bAbi](https://research.fb.com/downloads/babi/): Facebook用于文本理解的丰富数据集集合。
- [FEVER](https://fever.ai/data.html): 用于事实提取和验证。
- [SearchQA](https://github.com/nyu-dl/dl4ir-searchQA)：问答对是从[ J! Archive](https://j-archive.com/)抓取，然后用Google的文本片段进行扩充。
- [Quasar-T](https://github.com/bdhingra/quasar)：一个从各种互联网来源获取的开放域冷知识问题及其答案的集合。
- [Quiz bowl](https://people.cs.umass.edu/~miyyer/qblearn/index.html)：包含来自一项名为“quiz bowl”的冷知识竞赛的数据。
- [AmbigNQ](https://nlp.cs.washington.edu/ambigqa/)：从NQ-OPEN数据集中选择的歧义问题。
- [QA-Overlap](https://github.com/facebookresearch/QA-Overlap)：Natural Questions、TriviaQA和WebQuestions的训练集和测试集之间重叠的答案/问题的集合。

> • [SQuAD 2.0](https://rajpurkar.github.io/SQuAD-explorer/): the Stanford QA dataset.
> • [RACE](http://www.qizhexie.com/data/RACE_leaderboard): a reading comprehension dataset collected from English Examinations that are created for middle school and high school students.
> • [TREC QA](https://trec.nist.gov/data/qa.html): the TREC QA collections.
> • [MS MARCO](https://microsoft.github.io/msmarco/): a QA dataset featuring 100,000 real Bing questions and a human generated answer.
> • [CuratedTREC](https://github.com/brmson/dataset-factoid-curated): based on the benchmarks from the TREC QA tasks that have been curated by [Baudis & Sedivy (2015)](https://link.springer.com/chapter/10.1007%2F978-3-319-24027-5_20).
> • [Google Natural Questions](https://ai.google.com/research/NaturalQuestions/dataset):  contains real user questions issued to Google search, and answers found from Wikipedia by annotators.
> • [WebQuestions](https://github.com/brmson/dataset-factoid-webquestions): designed for knowledge-base QA with answers restricted to Freebase entities.
> • [WikiQA](https://www.microsoft.com/en-us/research/publication/wikiqa-a-challenge-dataset-for-open-domain-question-answering/): Bing query logs were used as the source of questions. Each question is then linked to a Wikipedia page that potentially contains the answer.
> • [WikiMovies](https://research.fb.com/downloads/babi/): contains movie-related questions from the OMDb and MovieLens databases and where the questions can be answered using Wikipedia pages.
> • [WikiReading](https://github.com/google-research-datasets/wiki-reading): to predict textual values from the structured knowledge base Wikidata by reading the text of the corresponding Wikipedia articles.
> • [TriviaQA](https://nlp.cs.washington.edu/triviaqa/): a reading comprehension dataset containing 95K question-answer pairs authored by trivia enthusiasts and independently gathered multiple evidence documents per question.
> • [ Jeopardy! Questions](https://www.kaggle.com/tunguz/200000-jeopardy-questions): contains 200,000+ [Jeopardy!](https://en.wikipedia.org/wiki/Jeopardy!) questions.
> • [DeepMind Q&A Dataset](https://cs.nyu.edu/~kcho/DMQA/): question/answer pairs from CNN and Daily Mail articles.
> • [bAbi](https://research.fb.com/downloads/babi/): a rich collection of datasets for text understanding by Facebook.
> • [FEVER](https://fever.ai/data.html): for fact extraction and verification.
> • [SearchQA](https://github.com/nyu-dl/dl4ir-searchQA): question-answer pairs were crawled from from [ J! Archive](https://j-archive.com/), and then augmented with text snippets from Google.
> • [Quasar-T](https://github.com/bdhingra/quasar): a collection of open-domain trivia questions and their answers obtained from various internet sources.
> • [Quiz bowl](https://people.cs.umass.edu/~miyyer/qblearn/index.html): contains data from a trivia competition called quiz bowl.
> • [AmbigNQ](https://nlp.cs.washington.edu/ambigqa/): ambiguous questions selected from NQ-OPEN dataset.
> • [QA-Overlap](https://github.com/facebookresearch/QA-Overlap): a collections of overlapped answers/questions between train and test set for Natural Questions, TriviaQA, and WebQuestions.

### 参考文献

> References

[1] Danqi Chen & Scott Yih. [“ACL2020 Tutorial: Open-Domain Question Answering”](https://github.com/danqi/acl2020-openqa-tutorial) 2020年7月。

> [1] Danqi Chen & Scott Yih. [“ACL2020 Tutorial: Open-Domain Question Answering”](https://github.com/danqi/acl2020-openqa-tutorial) July 2020.

[2] Danqi Chen, et al. [“Reading Wikipedia to Answer Open-Domain Questions”](https://arxiv.org/abs/1704.00051) ACL 2017. | [代码](https://github.com/facebookresearch/DrQA)

> [2] Danqi Chen, et al. [“Reading Wikipedia to Answer Open-Domain Questions”](https://arxiv.org/abs/1704.00051) ACL 2017. | [code](https://github.com/facebookresearch/DrQA)

[3] Shuohang Wang, et al. [“R^3: Reinforced Ranker-Reader for Open-Domain Question Answering”](https://arxiv.org/abs/1709.00023) AAAI 2018。

> [3] Shuohang Wang, et al. [“R^3: Reinforced Ranker-Reader for Open-Domain Question Answering”](https://arxiv.org/abs/1709.00023) AAAI 2018.

[4] Jimmy Lin. [“The neural hype and comparisons against weak baselines.”](https://sigir.org/wp-content/uploads/2019/01/p040.pdf) ACM SIGIR Forum. Vol. 52. No. 2. 2019。

> [4] Jimmy Lin. [“The neural hype and comparisons against weak baselines.”](https://sigir.org/wp-content/uploads/2019/01/p040.pdf) ACM SIGIR Forum. Vol. 52. No. 2. 2019.

[5] Wei Yang, et al. [“End-to-End Open-Domain Question Answering with BERTserini”](https://arxiv.org/abs/1902.01718) NAACL 2019。

> [5] Wei Yang, et al. [“End-to-End Open-Domain Question Answering with BERTserini”](https://arxiv.org/abs/1902.01718) NAACL 2019.

[6] Christopher Clark & Matt Gardner. [“Simple and Effective Multi-Paragraph Reading Comprehension.”](https://arxiv.org/abs/1710.10723) arXiv:1710.10723 (2017)。

> [6] Christopher Clark & Matt Gardner. [“Simple and Effective Multi-Paragraph Reading Comprehension.”](https://arxiv.org/abs/1710.10723) arXiv:1710.10723 (2017).

[7] Rodrigo Nogueira & Kyunghyun Cho. [“Passage Re-ranking with BERT.”](https://arxiv.org/abs/1901.04085) arXiv preprint arXiv:1901.04085 (2019). | [代码](https://github.com/nyu-dl/dl4marco-bert)

> [7] Rodrigo Nogueira & Kyunghyun Cho. [“Passage Re-ranking with BERT.”](https://arxiv.org/abs/1901.04085) arXiv preprint arXiv:1901.04085 (2019). | [code](https://github.com/nyu-dl/dl4marco-bert)

[8] Zhiguo Wang, et al. [“Multi-passage BERT: A globally normalized BERT model for open-domain question answering.”](https://arxiv.org/abs/1908.08167) EMNLP 2019。

> [8] Zhiguo Wang, et al. [“Multi-passage BERT: A globally normalized BERT model for open-domain question answering.”](https://arxiv.org/abs/1908.08167) EMNLP 2019.

[9] Minjoon Seo et al. [“Real-time open-domain question answering with dense-sparse phrase index.”](https://arxiv.org/abs/1906.05807) ACL 2019。

> [9] Minjoon Seo et al. [“Real-time open-domain question answering with dense-sparse phrase index.”](https://arxiv.org/abs/1906.05807) ACL 2019.

[10] Kenton Lee, et al. [“Latent Retrieval for Weakly Supervised Open Domain Question Answering”](https://arxiv.org/abs/1906.00300) ACL 2019。

> [10] Kenton Lee, et al. [“Latent Retrieval for Weakly Supervised Open Domain Question Answering”](https://arxiv.org/abs/1906.00300) ACL 2019.

[11] Kelvin Guu, et al. [“REALM: Retrieval-Augmented Language Model Pre-Training”](https://arxiv.org/abs/2002.08909) arXiv:2002.08909 (2020)。

> [11] Kelvin Guu, et al. [“REALM: Retrieval-Augmented Language Model Pre-Training”](https://arxiv.org/abs/2002.08909) arXiv:2002.08909 (2020).

[12] Vladimir Karpukhin et al. [“Dense passage retrieval for open-domain question answering.”](https://arxiv.org/abs/2004.04906). EMNLP 2020. | [代码](https://github.com/facebookresearch/DPR)

> [12] Vladimir Karpukhin et al. [“Dense passage retrieval for open-domain question answering.”](https://arxiv.org/abs/2004.04906). EMNLP 2020. | [code](https://github.com/facebookresearch/DPR)

[13] Patrick Lewis et al. [“Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks”](https://arxiv.org/abs/2005.11401) arXiv:2005.11401 (2020)。

> [13] Patrick Lewis et al. [“Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks”](https://arxiv.org/abs/2005.11401) arXiv:2005.11401 (2020).

[14] Adam Roberts, et al. [“How Much Knowledge Can You Pack Into the Parameters of a Language Model?”](https://arxiv.org/abs/2002.08910) EMNLP 2020。

> [14] Adam Roberts, et al. [“How Much Knowledge Can You Pack Into the Parameters of a Language Model?”](https://arxiv.org/abs/2002.08910) EMNLP 2020.

[15] Tom Brown, et al. [“Language models are few-shot learners.”](https://arxiv.org/abs/2005.14165) arXiv:2005.14165 (2020)。

> [15] Tom Brown, et al. [“Language models are few-shot learners.”](https://arxiv.org/abs/2005.14165) arXiv:2005.14165 (2020).

[16] Fabio Petroni, et al. [“How Context Affects Language Models’ Factual Predictions”](https://arxiv.org/abs/2005.04611) AKBC 2020。

> [16] Fabio Petroni, et al. [“How Context Affects Language Models’ Factual Predictions”](https://arxiv.org/abs/2005.04611) AKBC 2020.

[17] Gautier Izacard & Edouard Grave. [“Leveraging passage retrieval with generative models for open domain question answering.”](https://arxiv.org/abs/2007.01282) arXiv:2007.01282 (2020)。

> [17] Gautier Izacard & Edouard Grave. [“Leveraging passage retrieval with generative models for open domain question answering.”](https://arxiv.org/abs/2007.01282) arXiv:2007.01282 (2020).

[18] [“深入学习：束搜索”](https://d2l.ai/chapter_recurrent-modern/beam-search.html)

> [18] [“Dive into deep learning: Beam search”](https://d2l.ai/chapter_recurrent-modern/beam-search.html)

[19] Patrick Lewis, et al. [“Question and Answer Test-Train Overlap in Open-Domain Question Answering Datasets”](https://arxiv.org/abs/2008.02637) arXiv:2008.02637 (2020). | [数据](https://github.com/facebookresearch/QA-Overlap)

> [19] Patrick Lewis, et al. [“Question and Answer Test-Train Overlap in Open-Domain Question Answering Datasets”](https://arxiv.org/abs/2008.02637) arXiv:2008.02637 (2020). | [data](https://github.com/facebookresearch/QA-Overlap)

[20] Hervé Jegou, et al. [“Faiss: A library for efficient similarity search”](https://engineering.fb.com/2017/03/29/data-infrastructure/faiss-a-library-for-efficient-similarity-search/) 2017年3月。

> [20] Hervé Jegou, et al. [“Faiss: A library for efficient similarity search”](https://engineering.fb.com/2017/03/29/data-infrastructure/faiss-a-library-for-efficient-similarity-search/) Mar 2017.

[21] Vidhisha Balachandran, et al. [“Simple and Efficient ways to Improve REALM.”](https://arxiv.org/abs/2104.08710) arXiv:2104.08710 (2021)。

> [21] Vidhisha Balachandran, et al. [“Simple and Efficient ways to Improve REALM.”](https://arxiv.org/abs/2104.08710) arXiv:2104.08710 (2021).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Open-Domain Question Answering (ODQA) | 开放域问答 | 一种语言任务，要求模型以自然语言回答事实性问题，且不提供相关上下文。 |
| Reading Comprehension (RC) | 阅读理解 | 一种语言任务，模型在给定问题和相关上下文的情况下提取答案。 |
| Retriever-Reader Framework | 检索器-阅读器框架 | 一种构建开放域问答系统的方法，包括检索相关文档和从文档中提取答案两个阶段。 |
| Information Retrieval (IR) | 信息检索 | 从大量文档集合中查找与用户查询相关的文档的技术。 |
| TF-IDF | 词频-逆文档频率 | 一种统计方法，用于评估一个词对文档集合或语料库中的一份文档的重要程度。 |
| BM25 | BM25 | 一种基于TF-IDF的排名函数，用于信息检索系统，根据查询词在文档中的出现频率和文档长度对文档进行评分。 |
| Dense Passage Retrieval (DPR) | 密集段落检索 | 一种使用密集向量表示（通常由神经网络生成）来检索相关段落的方法。 |
| Inverse Cloze Task (ICT) | 逆完形填空任务 | 一种语言模型预训练任务，旨在根据一个句子预测其上下文。 |
| Salient Span Masking | 显著跨度掩码 | 一种语言模型预训练任务，通过掩盖文本中的命名实体或日期等“显著跨度”来训练模型预测它们。 |
| Retrieval-Augmented Generation (RAG) | 检索增强生成 | 一种结合了参数化语言模型和非参数化外部知识索引的语言生成方法。 |
| Closed-Book Question Answering | 闭卷问答 | 一种问答设置，模型在没有外部上下文的情况下，仅凭其内部知识回答问题。 |
| Maximum Inner Product Search (MIPS) | 最大内积搜索 | 一种在大量向量中快速查找与查询向量内积最大的向量的技术。 |
| Language Model (LM) | 语言模型 | 一种能够预测文本序列中下一个词或字符概率的统计模型。 |
| Transformer | Transformer | 一种基于自注意力机制的神经网络架构，广泛应用于自然语言处理任务。 |
| Fine-tuning | 微调 | 在特定任务数据集上进一步训练预训练模型，以适应特定任务。 |
