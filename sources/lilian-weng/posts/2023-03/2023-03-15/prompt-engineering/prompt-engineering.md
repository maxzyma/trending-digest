# 提示工程

> Prompt Engineering

> 来源：Lil'Log / Lilian Weng，2023-03-15
> 原文链接：https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/
> 分类：人工智能 / 大语言模型

## 核心要点

- 提示工程是与大型语言模型沟通以引导其行为达到预期结果的方法，无需更新模型权重，它是一门经验科学。
- 基本的提示方法包括零样本学习和少样本学习，其中少样本学习通过提供高质量示例来提高性能，但其效果受提示格式、示例选择和顺序等因素影响。
- 指令提示通过直接给出详细、具体的任务要求来引导模型，指令式语言模型（如InstructGPT）通过微调更好地理解用户意图。
- 自洽性采样通过在温度大于0的情况下采样多个输出，然后通过多数投票等标准选择最佳结果，以提高推理准确性。
- 思维链（CoT）提示通过生成逐步的推理逻辑（推理链）来解决复杂推理任务，尤其适用于大型模型，并有少样本和零样本两种主要类型。
- 自动提示设计方法旨在通过在嵌入空间上直接优化提示或在模型生成的指令候选池中进行搜索，自动化提示的创建过程。
- 增强型语言模型通过结合检索机制或外部工具（如搜索引擎、计算器、编程语言解释器）来扩展其知识和能力，以处理更复杂的任务。
- 检索增强型语言模型能够处理预训练截止日期之后或内部知识库中的最新信息，通过将检索到的内容作为上下文来生成答案。
- Toolformer等模型通过自监督学习，使语言模型能够自学使用外部API工具，从而弥补其在精确计算、实时信息和多语言处理等方面的不足。

## 正文

**提示工程**，也称为**上下文提示**，指的是与大型语言模型（LLM）沟通以引导其行为达到预期结果的方法，*无需*更新模型权重。它是一门经验科学，提示工程方法的效果在不同模型之间差异很大，因此需要大量的实验和启发式方法。

> **Prompt Engineering**, also known as **In-Context Prompting**, refers to methods for how to communicate with LLM to steer its behavior for desired outcomes *without* updating the model weights. It is an empirical science and the effect of prompt engineering methods can vary a lot among models, thus requiring heavy experimentation and heuristics.

本文仅关注自回归语言模型的提示工程，不涉及完形填空测试、图像生成或多模态模型。提示工程的核心目标是实现对齐和模型可控性。请查阅我关于可控文本生成的[上一篇文章](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/)。

> This post only focuses on prompt engineering for autoregressive language models, so nothing with Cloze tests, image generation or multimodality models. At its core, the goal of prompt engineering is about alignment and model steerability. Check my [previous post](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/) on controllable text generation.

[我个人的一些看法] 在我看来，一些提示工程论文不值得写满8页，因为这些技巧可以用一两句话解释清楚，其余部分都是关于基准测试。一个易于使用和共享的基准测试基础设施对社区会更有益。迭代提示或外部工具的使用设置起来并不简单。让整个研究社区采纳它也非易事。

> [My personal spicy take] In my opinion, some prompt engineering papers are not worthy 8 pages long, since those tricks can be explained in one or a few sentences and the rest is all about benchmarking. An easy-to-use and shared benchmark infrastructure should be more beneficial to the community. Iterative prompting or external tool use would not be trivial to set up. Also non-trivial to align the whole research community to adopt it.

### 基本提示

> Basic Prompting

零样本学习和少样本学习是提示模型最基本的两种方法，由许多大型语言模型（LLM）论文开创，并常用于评估LLM性能。

> Zero-shot and few-shot learning are two most basic approaches for prompting the model, pioneered by many LLM papers and commonly used for benchmarking LLM performance.

#### 零样本

> Zero-Shot

**零样本学习**就是简单地将任务文本输入模型并请求结果。

> **Zero-shot learning** is to simply feed the task text to the model and ask for results.

（所有情感分析示例均来自SST-2）

> (All the sentiment analysis examples are from SST-2)

```
Text: i'll bet the video game is a lot more fun than the film.
Sentiment:
```

#### 少样本

> Few-shot

**少样本学习**在目标任务上提供了一组高质量的演示，每个演示都包含输入和期望的输出。由于模型首先看到好的示例，它能更好地理解人类意图以及对所需答案类型的标准。因此，少样本学习通常比零样本学习带来更好的性能。然而，它的代价是消耗更多的token，并且当输入和输出文本很长时，可能会达到上下文长度限制。

> **Few-shot learning** presents a set of high-quality demonstrations, each consisting of both input and desired output, on the target task. As the model first sees good examples, it can better understand human intention and criteria for what kinds of answers are wanted. Therefore, few-shot learning often leads to better performance than zero-shot. However, it comes at the cost of more token consumption and may hit the context length limit when input and output text are long.

```
Text: (lawrence bounces) all over the stage, dancing, running, sweating, mopping his face and generally displaying the wacky talent that brought him fame in the first place.
Sentiment: positive

Text: despite all evidence to the contrary, this clunker has somehow managed to pose as an actual feature movie, the kind that charges full admission and gets hyped on tv and purports to amuse small children and ostensible adults.
Sentiment: negative

Text: for the first time in years, de niro digs deep emotionally, perhaps because he's been stirred by the powerful work of his co-stars.
Sentiment: positive

Text: i'll bet the video game is a lot more fun than the film.
Sentiment:
```

许多研究探讨了如何构建上下文示例以最大化性能，并观察到**提示格式、训练示例的选择以及示例的顺序可能导致性能的显著差异**，从接近随机猜测到接近最先进水平。

> Many studies looked into how to construct in-context examples to maximize the performance and observed that **choice of prompt format, training examples, and the order of the examples can lead to dramatically different performance**, from near random guess to near SoTA.

[Zhao 等人 (2021)](https://arxiv.org/abs/2102.09690) 研究了少样本分类的情况，并提出大型语言模型（他们在实验中使用 GPT-3）的几种偏差导致了如此高的方差：(1) 如果示例中标签的分布不平衡，则存在*多数标签偏差*；(2) *近因偏差*是指模型可能重复末尾标签的倾向；(3) *常见token偏差*表明大型语言模型倾向于比稀有token更频繁地生成常见token。为了克服这种偏差，他们提出了一种方法，当输入字符串为 `N/A` 时，将模型输出的标签概率校准为均匀分布。

> [Zhao et al. (2021)](https://arxiv.org/abs/2102.09690) investigated the case of few-shot classification and proposed that several biases with LLM (they use GPT-3 in the experiments) contribute to such high variance: (1) *Majority label bias* exists if distribution of labels among the examples is unbalanced; (2) *Recency bias* refers to the tendency where the model may repeat the label at the end; (3) *Common token bias* indicates that LLM tends to produce common tokens more often than rare tokens. To conquer such bias, they proposed a method to calibrate the label probabilities output by the model to be uniform when the input string is `N/A`.

##### 示例选择技巧

> Tips for Example Selection

• 在嵌入空间中使用 $k$ -NN 聚类选择与测试示例语义相似的示例（[Liu 等人，2021](https://arxiv.org/abs/2101.06804)）

• 
为了选出一组多样且有代表性的样本，[Su et al. (2022)](https://arxiv.org/abs/2209.01975)提出使用一种基于图的方法：(1) 首先，构建一个有向图 $G=(V, E)$ ，其依据是嵌入（例如通过 [SBERT](https://arxiv.org/abs/1908.10084) 或[其他](https://arxiv.org/abs/2201.10005) [嵌入](https://platform.openai.com/docs/guides/embeddings) [模型](https://openai.com/blog/new-and-improved-embedding-model)）计算得到的样本之间的余弦相似度，其中每个节点指向它的 $k$ 个最近邻；(2) 从一组已选样本 $\mathcal{L}=\emptyset$ 和一组剩余样本 $\mathcal{U}$ 开始。每个样本 $u \in \mathcal{U}$ 由 

$$
\text{score}(u) = \sum_{v \in \{v \mid (u, v) \in E, v\in \mathcal{U}\}} s(v)\quad\text{where }s(v)=\rho^{- \vert \{\ell \in \mathcal{L} \vert (v, \ell)\in E \}\vert},\quad\rho > 1
$$

 打分，使得当 $s(v)$ 的许多邻居已被选中时 $v$ 的分值较低，因此该打分机制鼓励挑选多样化的样本。


• [Rubin 等人 (2022)](https://arxiv.org/abs/2112.08633) 提出通过[对比学习](https://lilianweng.github.io/posts/2021-05-31-contrastive/)训练特定于一个训练数据集的嵌入，用于上下文学习样本选择。给定每个训练对 $(x, y)$，一个示例 $e_i$（格式化的输入-输出对）的质量可以通过语言模型分配的条件概率来衡量：$\text{score}(e_i) = P_\text{LM}(y \mid e_i, x)$。我们可以将具有前 $k$ 和后 $k$ 分数的其他示例识别为每个训练对的正负候选集，并将其用于对比学习。

• 一些研究人员尝试使用 [Q-Learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control) 进行样本选择。（[Zhang 等人 2022](https://arxiv.org/abs/2211.04486)）

• 受基于不确定性的[主动学习](https://lilianweng.github.io/posts/2022-02-20-active-learning/)启发，[Diao 等人 (2023)](https://arxiv.org/abs/2302.12246) 建议识别在多次采样试验中具有高度分歧或熵的示例。然后标注这些示例以用于少样本提示。

英文原文：

• 
Choose examples that are semantically similar to the test example using $k$ -NN clustering in the embedding space ([Liu et al., 2021](https://arxiv.org/abs/2101.06804))


• 
To select a diverse and representative set of examples, [Su et al. (2022)](https://arxiv.org/abs/2209.01975) proposed to use a graph-based approach: (1) First, construct a directed graph $G=(V, E)$ based on the embedding (e.g. by [SBERT](https://arxiv.org/abs/1908.10084) or [other](https://arxiv.org/abs/2201.10005) [embedding](https://platform.openai.com/docs/guides/embeddings) [models](https://openai.com/blog/new-and-improved-embedding-model)) cosine similarity between samples, where each node points to its $k$ nearest neighbors; (2) Start with a set of selected samples $\mathcal{L}=\emptyset$ and a set of remaining samples $\mathcal{U}$. Each sample $u \in \mathcal{U}$ is scored by 

$$
\text{score}(u) = \sum_{v \in \{v \mid (u, v) \in E, v\in \mathcal{U}\}} s(v)\quad\text{where }s(v)=\rho^{- \vert \{\ell \in \mathcal{L} \vert (v, \ell)\in E \}\vert},\quad\rho > 1
$$

 such that $s(v)$ is low if many of $v$’s neighbors are selected and thus the scoring encourages to pick diverse samples.


• 
[Rubin et al. (2022)](https://arxiv.org/abs/2112.08633) proposed to train embeddings via [contrastive learning](https://lilianweng.github.io/posts/2021-05-31-contrastive/) specific to one training dataset for in-context learning sample selection.  Given each training pair $(x, y)$, the quality of one example $e_i$ (formatted input-output pair) can be measured by a conditioned probability assigned by LM: $\text{score}(e_i) = P_\text{LM}(y \mid e_i, x)$. We can identify other examples with top-$k$ and bottom-$k$ scores as positive and negative sets of candidates for every training pair and use that for contrastive learning.


• 
Some researchers tried [Q-Learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control) to do sample selection. ([Zhang et al. 2022](https://arxiv.org/abs/2211.04486))


• 
Motivated by uncertainty-based [active learning](https://lilianweng.github.io/posts/2022-02-20-active-learning/), [Diao et al. (2023)](https://arxiv.org/abs/2302.12246) suggested to identify examples with high disagreement or entropy among multiple sampling trials. Then annotate these examples to be used in few-shot prompts.


##### 示例排序技巧

> Tips for Example Ordering

- 一个普遍的建议是保持示例选择的多样性，与测试样本相关，并以随机顺序排列，以避免多数标签偏差和近因偏差。
- 增加模型大小或包含更多训练示例并不能减少上下文示例不同排列之间的方差。相同的顺序可能对一个模型有效，但对另一个模型无效。当验证集有限时，考虑选择这样的顺序，使模型不会产生极度不平衡的预测或对其预测过于自信。([Lu et al. 2022](https://arxiv.org/abs/2104.08786))

> • A general suggestion is to keep the selection of examples diverse, relevant to the test sample and in random order to avoid majority label bias and recency bias.
> • Increasing model sizes or including more training examples does not reduce variance among different permutations of in-context examples. Same order may work well for one model but badly for another. When the validation set is limited, consider choosing the order such that the model does not produce extremely unbalanced predictions or being overconfident about its predictions. ([Lu et al. 2022](https://arxiv.org/abs/2104.08786))

### 指令提示

> Instruction Prompting

在提示中呈现少样本示例的目的是向模型解释我们的意图；换句话说，以演示的形式向模型描述任务指令。然而，少样本在token使用方面可能很昂贵，并且由于上下文长度有限而限制了输入长度。那么，为什么不直接给出指令呢？

> The purpose of presenting few-shot examples in the prompt is to explain our intent to the model; in other words, describe the task instruction to the model in the form of demonstrations. However, few-shot can be expensive in terms of token usage and restricts the input length due to limited context length. So, why not just give the instruction directly?

*指令式语言模型*（例如[InstructGPT](https://openai.com/research/instruction-following)、[自然指令](https://github.com/allenai/natural-instructions)）使用高质量的（任务指令、输入、真实输出）元组对预训练模型进行微调，以使语言模型更好地理解用户意图并遵循指令。[RLHF](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences)（基于人类反馈的强化学习）是实现这一目标的常用方法。指令遵循式微调的好处在于提高了模型与人类意图的一致性，并大大降低了沟通成本。

> *Instructed LM* (e.g. [InstructGPT](https://openai.com/research/instruction-following), [natural instruction](https://github.com/allenai/natural-instructions)) finetunes a pretrained model with high-quality tuples of (task instruction, input, ground truth output) to make LM better understand user intention and follow instruction. [RLHF](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences) (Reinforcement Learning from Human Feedback) is a common method to do so. The benefit of instruction following style fine-tuning improves the model to be more aligned with human intention and greatly reduces the cost of communication.

与指令模型交互时，我们应该详细描述任务要求，力求*具体*和*精确*，避免说“不要做什么”，而是明确说明要做什么。

> When interacting with instruction models, we should describe the task requirement in details, trying to be *specific* and *precise* and avoiding say “not do something” but rather specify what to do.

```
Please label the sentiment towards the movie of the given movie review. The sentiment label should be "positive" or "negative". 
Text: i'll bet the video game is a lot more fun than the film. 
Sentiment:
```

解释目标受众是给出指令的另一种巧妙方式

> Explaining the desired audience is another smart way to give instructions

- 例如，为儿童制作教育材料，

> • For example to produce education materials for kids,

```
Describe what is quantum physics to a 6-year-old.
```

- 以及安全内容，

> • And safe content,

```
... in language that is safe for work.
```

*上下文指令学习*（[Ye et al. 2023](https://arxiv.org/abs/2302.14691)）将少样本学习与指令提示相结合。它在提示中包含了跨不同任务的多个演示示例，每个演示都包含指令、任务输入和输出。请注意，他们的实验仅限于分类任务，并且指令提示包含所有标签选项。

> *In-context instruction learning* ([Ye et al. 2023](https://arxiv.org/abs/2302.14691)) combines few-shot learning with instruction prompting. It incorporates multiple demonstration examples across different tasks in the prompt, each demonstration consisting of instruction, task input and output. Note that their experiments were only on classification tasks and the instruction prompt contains all label options.

```
Definition: Determine the speaker of the dialogue, "agent" or "customer".
Input: I have successfully booked your tickets.
Ouput: agent

Definition: Determine which category the question asks for, "Quantity" or "Location".
Input: What's the oldest building in US?
Ouput: Location

Definition: Classify the sentiment of the given movie review, "positive" or "negative".
Input: i'll bet the video game is a lot more fun than the film.
Output:
```

### 自洽性采样

> Self-Consistency Sampling

**自洽性采样**（[Wang et al. 2022a](https://arxiv.org/abs/2203.11171)）是指在温度 > 0 的情况下采样多个输出，然后从这些候选结果中选择最佳的一个。选择最佳候选结果的标准可能因任务而异。一个通用的解决方案是选择**多数投票**。对于易于验证的任务，例如带有单元测试的编程问题，我们可以简单地通过解释器运行并使用单元测试验证其正确性。

> **Self-consistency sampling** ([Wang et al. 2022a](https://arxiv.org/abs/2203.11171)) is to sample multiple outputs with temperature > 0 and then selecting the best one out of these candidates.
> The criteria for selecting the best candidate can vary from task to task. A general solution is to pick **majority vote**. For tasks that are easy to validate such as a programming question with unit tests, we can simply run through the interpreter and verify the correctness with unit tests.

### 思维链 (CoT)

> Chain-of-Thought (CoT)

**思维链 (CoT) 提示**（[Wei et al. 2022](https://arxiv.org/abs/2201.11903)）生成一系列短句，逐步描述推理逻辑，这些短句被称为*推理链*或*基本原理*，最终得出最终答案。CoT 的好处在**复杂推理任务**中更为显著，尤其是在使用**大型模型**（例如，拥有超过500亿参数的模型）时。简单任务从 CoT 提示中受益甚微。

> **Chain-of-thought (CoT) prompting** ([Wei et al. 2022](https://arxiv.org/abs/2201.11903)) generates a sequence of short sentences to describe reasoning logics step by step, known as *reasoning chains* or *rationales*, to eventually lead to the final answer. The benefit of CoT is more pronounced for **complicated reasoning tasks**, while using **large models** (e.g. with more than 50B parameters). Simple tasks only benefit slightly from CoT prompting.

#### CoT 提示的类型

> Types of CoT prompts

CoT 提示的两种主要类型：

> Two main types of CoT prompting:

- **少样本 CoT**。它通过少量演示来提示模型，每个演示都包含手动编写（或模型生成）的高质量推理链。

> • **Few-shot CoT**. It is to prompt the model with a few demonstrations, each containing manually written (or model-generated) high-quality reasoning chains.

（所有数学推理示例均来自[GSM8k](https://github.com/openai/grade-school-math)）

> (All the math reasoning examples are from [GSM8k](https://github.com/openai/grade-school-math))

```
Question: Tom and Elizabeth have a competition to climb a hill. Elizabeth takes 30 minutes to climb the hill. Tom takes four times as long as Elizabeth does to climb the hill. How many hours does it take Tom to climb up the hill?
Answer: It takes Tom 30*4 = <<30*4=120>>120 minutes to climb the hill.
It takes Tom 120/60 = <<120/60=2>>2 hours to climb the hill.
So the answer is 2.
===
Question: Jack is a soccer player. He needs to buy two pairs of socks and a pair of soccer shoes. Each pair of socks cost $9.50, and the shoes cost $92. Jack has $40. How much more money does Jack need?
Answer: The total cost of two pairs of socks is $9.50 x 2 = $<<9.5*2=19>>19.
The total cost of the socks and the shoes is $19 + $92 = $<<19+92=111>>111.
Jack need $111 - $40 = $<<111-40=71>>71 more.
So the answer is 71.
===
Question: Marty has 100 centimeters of ribbon that he must cut into 4 equal parts. Each of the cut parts must be divided into 5 equal parts. How long will each final cut be?
Answer:
```

- **零样本 CoT**。使用像 `Let's think step by step` 这样的自然语言语句明确鼓励模型首先生成推理链，然后使用 `Therefore, the answer is` 进行提示以产生答案（[Kojima et al. 2022](https://arxiv.org/abs/2205.11916)）。或者使用类似的语句 `Let's work this out it a step by step to be sure we have the right answer`（[Zhou et al. 2022](https://arxiv.org/abs/2211.01910)）。

> • **Zero-shot CoT**. Use natural language statement like `Let's think step by step` to explicitly encourage the model to first generate reasoning chains and then to prompt with `Therefore, the answer is` to produce answers ([Kojima et al. 2022](https://arxiv.org/abs/2205.11916) ). Or a similar statement `Let's work this out it a step by step to be sure we have the right answer` ([Zhou et al. 2022](https://arxiv.org/abs/2211.01910)).

```
Question: Marty has 100 centimeters of ribbon that he must cut into 4 equal parts. Each of the cut parts must be divided into 5 equal parts. How long will each final cut be?
Answer: Let's think step by step.
```

#### 技巧与扩展

> Tips and Extensions

• 
[自洽性采样](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/#self-consistency-sampling)可以通过采样多个不同的答案然后进行多数投票来提高推理准确性。([Wang et al. 2022a](https://arxiv.org/abs/2203.11171))


• 
集成学习的另一种方法是改变示例顺序或使用模型生成的原理来替换人工编写的原理，以在多次采样试验中引入随机性。然后通过多数投票聚合模型输出以获得最终答案。([Wang et al. 2022b](https://arxiv.org/abs/2207.00747))


• 
如果训练示例只与真实答案（易于验证！）相关联但没有原理，我们可以遵循*STaR*（自学推理器；[Zelikman et al. 2022](https://arxiv.org/abs/2203.14465)）方法：(1) 要求大型语言模型生成推理链，并只保留那些导致正确答案的推理链；(2) 然后使用生成的原理对模型进行微调，并重复该过程直到收敛。请注意，较高的温度更有可能生成带有正确答案但不正确的原理。如果训练示例没有真实答案，可以考虑使用多数投票作为“正确”答案。


• 具有更高推理复杂度的演示提示可以实现更好的性能，其中复杂度通过链中的推理步骤数量来衡量。在分离推理步骤时，换行符 `\n` 符号比 `step i`、句号 `.` 或分号 `;` 效果更好。([Fu et al. 2023](https://arxiv.org/abs/2210.00720))

• *基于复杂度的连贯性* 是指通过仅对前 $k$ 个复杂链进行多数投票，明确地在所有生成中偏好复杂链。([Fu et al. 2023](https://arxiv.org/abs/2210.00720))

• 后来，[Shum et al. (2023)](https://arxiv.org/abs/2302.12822) 发现，在他们的实验中，仅包含复杂示例的 CoT 提示可以提高复杂问题的准确性，但在简单问题上表现不佳；证据显示在 GSM8k 上。

• 发现将 `Q:` 更改为 `Question:` 会有所帮助。([Fu et al. 2023](https://arxiv.org/abs/2210.00720))

• [Ye & Durrett (2022)](https://arxiv.org/abs/2205.03401) 发现，对于涉及文本推理的 NLP 任务（即 QA 和 NLI），在提示中包含解释的好处是小到中等的，并且效果因模型而异。他们观察到，解释更可能是非事实性的，而不是不一致的（即解释是否蕴含预测）。非事实性解释最有可能导致不正确的预测。

• *Self-Ask* ([Press et al. 2022](https://arxiv.org/abs/2210.03350)) 是一种反复提示模型*提出后续问题*以迭代构建思维过程的方法。后续问题可以通过搜索引擎结果回答。类似地，*IRCoT* (Interleaving Retrieval CoT; [Trivedi et al. 2022](https://arxiv.org/abs/2212.10509)) 和 *ReAct* (Reason + Act; [Yao et al. 2023](https://arxiv.org/abs/2210.03629)) 将迭代 CoT 提示与对维基百科 API 的查询相结合，以搜索相关实体和内容，然后将其添加回上下文中。

英文原文：

• 
[Self-consistency sampling](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/#self-consistency-sampling) can improve reasoning accuracy by sampling a number of diverse answers and then taking the majority vote. ([Wang et al. 2022a](https://arxiv.org/abs/2203.11171))


• 
Another approach for ensemble learning is to alter the example order or use model generated rationales to replace human-written ones to introduce randomness during multiple sample trials. Then aggregate model outputs with a majority vote to get final answer. ([Wang et al. 2022b](https://arxiv.org/abs/2207.00747))


• 
If training examples are only associated with true answers (easy to verify!) but no rationales, we can follow the *STaR* (Self-Taught Reasoner; [Zelikman et al. 2022](https://arxiv.org/abs/2203.14465)) method : (1) Ask LLM to generate reasoning chains and only keep those leading to correct answers; (2) Then fine-tune the model with generated rationales and repeat the process until convergence. Note that higher temperature is more likely to generate incorrect rationales with correct answers. If training examples do not have ground truth answers, maybe consider using majority votes as the “correct” answers.


• 
Prompts with demonstrations of higher reasoning complexity can achieve better performance, where complexity is measured by the number of reasoning steps in the chains. When separating reasoning steps, newline `\n` symbol works better than `step i`, period `.` or semicolon `;`. ([Fu et al. 2023](https://arxiv.org/abs/2210.00720))


• 
*Complexity-based consistency* is to explicitly prefer complex chains among all the generations by taking majority vote among only top $k$ complex chains. ([Fu et al. 2023](https://arxiv.org/abs/2210.00720))


• 
Later, [Shum et al. (2023)](https://arxiv.org/abs/2302.12822) found that in their experiments CoT prompts with only complex examples can improve the accuracy of complex questions, but perform poorly in simple questions; evidence shown on GSM8k.


• 
Changing `Q:` to `Question:` is found to be helpful. ([Fu et al. 2023](https://arxiv.org/abs/2210.00720))


• 
[Ye & Durrett (2022)](https://arxiv.org/abs/2205.03401) found that the benefit of including explanations in the prompt is small to moderate for NLP tasks that involve reasoning over text (i.e. QA and NLI) and the effects vary by models. They observed that explanations are more likely to be nonfactual than be inconsistent (i.e. whether explanation entails prediction). Nonfactual explanations most likely lead to incorrect predictions.


• 
*Self-Ask* ([Press et al. 2022](https://arxiv.org/abs/2210.03350)) is a method to repeatedly prompt the model to *ask following-up questions* to construct the thought process iteratively. Follow-up questions can be answered by search engine results. Similarly, *IRCoT* (Interleaving Retrieval CoT; [Trivedi et al. 2022](https://arxiv.org/abs/2212.10509)) and *ReAct* (Reason + Act; [Yao et al. 2023](https://arxiv.org/abs/2210.03629)) combines iterative CoT prompting with queries to Wikipedia APIs to search for relevant entities and content and then add it back into the context.


![How Self-Ask works with external search queries. (Image source: Press et al. 2022 ).](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/SelfAsk-search.png)

- *思维树* ([Yao et al. 2023](https://arxiv.org/abs/2305.10601)) 通过在每个步骤探索多种推理可能性来扩展 CoT。它首先将问题分解为多个思维步骤，并在每个步骤生成多个思维，本质上创建了一个树状结构。搜索过程可以是 BFS 或 DFS，同时每个状态都通过分类器（通过提示）或多数投票进行评估。

> • *Tree of Thoughts* ([Yao et al. 2023](https://arxiv.org/abs/2305.10601)) extends CoT by exploring multiple reasoning possibilities at each step. It first decomposes the problem into multiple thought steps and generates multiple thoughts per step, essentially creating a tree structure. The search process can be BFS or DFS while each state is evaluated by a classifier (via a prompt) or majority vote.

![How Self-Ask works with external search queries. (Image source: Yao et al. 2022 ).](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/tree-of-thoughts.png)

### 自动提示设计

> Automatic Prompt Design

提示是一系列前缀标记，它们在给定输入的情况下增加了获得所需输出的概率。因此，我们可以将它们视为可训练参数，并通过梯度下降在嵌入空间上[直接优化它们](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#smart-prompt-design)，例如 **AutoPrompt** ([Shin et al., 2020](https://arxiv.org/abs/2010.15980))、**Prefix-Tuning** ([Li & Liang (2021)](https://arxiv.org/abs/2101.00190))、**P-tuning** ([Liu et al. 2021](https://arxiv.org/abs/2103.10385)) 和 **Prompt-Tuning** ([Lester et al. 2021](https://arxiv.org/abs/2104.08691))。[我的“可控神经文本生成”帖子中的这一部分](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#smart-prompt-design)对它们有很好的介绍。从 AutoPrompt 到 Prompt-Tuning 的趋势是设置逐渐简化。

> Prompt is a sequence of prefix tokens that increase the probability of getting  desired output given input. Therefore we can treat them as trainable parameters and [optimize them directly](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#smart-prompt-design) on the embedding space via gradient descent, such as **AutoPrompt** ([Shin et al., 2020](https://arxiv.org/abs/2010.15980), **Prefix-Tuning** ([Li & Liang (2021)](https://arxiv.org/abs/2101.00190)), **P-tuning** ([Liu et al. 2021](https://arxiv.org/abs/2103.10385)) and **Prompt-Tuning** ([Lester et al. 2021](https://arxiv.org/abs/2104.08691)). [This section in my “Controllable Neural Text Generation” post](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#smart-prompt-design) has a good coverage of them. The trend from AutoPrompt to Prompt-Tuning is that the setup gets gradually simplified.

**APE** (Automatic Prompt Engineer; [Zhou et al. 2022](https://arxiv.org/abs/2211.01910)) 是一种在模型生成的指令候选池中进行搜索的方法，然后根据选定的评分函数过滤候选集，最终选择得分最高的最佳候选。

> **APE** (Automatic Prompt Engineer; [Zhou et al. 2022](https://arxiv.org/abs/2211.01910)) is a method to search over a pool of model-generated instruction candidates and then filters the candidate set according to a chosen score function to ultimately choose the best candidate with highest score.

1\. 提示 LLM 根据一小组输入-输出对形式的演示生成指令候选。例如 `{{Given desired input-output pairs}}\n\nThe instruction is`。

2\. 给定一个 $\mathcal{D}_\text{train} = \{(x, y)\}$ 数据集，我们希望找到一个指令 $\rho$，使得 $\rho^{\ast} = \arg\max_\rho \mathbb{E}_{(x, y) \in \mathcal{D}_\text{train}} [f(\rho, x, y)]$，其中 $f(.)$ 是一个逐样本评分函数，例如执行准确性 $\mathbb{1}[\text{LM}(.\vert \rho, x)=y]$ 或对数概率：$p_\text{LM}(y \mid \rho, x)$。

3\. 使用迭代蒙特卡洛搜索方法，通过提示（如 `Generate a variation of the following instruction while keeping the semantic meaning.\n\nInput: ...\n\nOutput:...`）提出语义相似的变体来改进最佳候选。

英文原文：

1\. 
Prompt LLM to generate instruction candidates based on a small set of demonstrations in the form of input-output pairs. E.g. `{{Given desired input-output pairs}}\n\nThe instruction is`.


2\. 
Given a dataset of $\mathcal{D}_\text{train} = \{(x, y)\}$, we would like to find an instruction $\rho$ such that $\rho^{\ast} = \arg\max_\rho \mathbb{E}_{(x, y) \in \mathcal{D}_\text{train}} [f(\rho, x, y)]$, where $f(.)$ is a per-sample score function, such as execution accuracy $\mathbb{1}[\text{LM}(.\vert \rho, x)=y]$ or log probability: $p_\text{LM}(y \mid \rho, x)$.


3\. 
Use an iterative Monte Carlo search method to improve the best candidates by proposing semantically similar variants via prompts like `Generate a variation of the following instruction while keeping the semantic meaning.\n\nInput: ...\n\nOutput:...`


为了自动构建思维链提示，[Shum et al. (2023)](https://arxiv.org/abs/2302.12822) 提出了增强-剪枝-选择（augment-prune-select）的三步过程：

> To construct chain-of-thought prompts automatically, [Shum et al. (2023)](https://arxiv.org/abs/2302.12822) suggested augment-prune-select, a three-step process:

1. *增强*：使用少样本或零样本 CoT 提示，根据问题生成多个伪思维链；
2. *剪枝*：根据生成的答案是否与真实值匹配来剪枝伪链。
3. *选择*：应用方差缩减的策略梯度策略来学习所选示例的概率分布，同时将示例的概率分布视为策略，将验证集准确性视为奖励。

> • *Augment*: Generate multiple pseudo-chains of thought given question using few-shot or zero-shot CoT prompts;
> • *Prune*: Prune pseudo chains based on whether generated answers match ground truths.
> • *Select*: Apply a variance-reduced policy gradient strategy to learn the probability distribution over selected examples, while considering the probability distribution over examples as policy and the validation set accuracy as reward.

[Zhang et al. (2023)](https://arxiv.org/abs/2210.03493) 转而采用*聚类*技术来抽样问题，然后生成链。他们观察到 LLM 倾向于犯某些类型的错误。一种错误类型在嵌入空间中可能相似，因此被归为一类。通过仅从频繁错误簇中抽取一个或几个样本，我们可以防止过多地演示一种错误类型，并收集多样化的示例集。

> [Zhang et al. (2023)](https://arxiv.org/abs/2210.03493) instead adopted *clustering* techniques to sample questions and then generates chains. They observed that LLMs tend to make certain types of mistakes. One type of errors can be similar in the emebedding space and thus get grouped together. By only sampling one or a few from frequent-error clusters, we can prevent too many wrong demonstrations of one error type and collect a diverse set of examples.

1\. *问题聚类*：嵌入问题并运行 $k$ -means 进行聚类。

2\. *演示选择*：从每个簇中选择一组代表性问题；即每个簇一个演示。每个簇中的样本按到簇质心的距离排序，并优先选择距离质心更近的样本。

3\. *理由生成*：使用零样本 CoT 为选定问题生成推理链，并构建少样本提示以运行推理。

英文原文：

1\. *Question clustering*: Embed questions and run $k$ -means for clustering.

2\. *Demonstration selection*: Select a set of representative questions from each cluster; i.e. one demonstration from one cluster. Samples in each cluster are sorted by distance to the cluster centroid and those closer to the centroid are selected first.

3\. *Rationale generation*: Use zero-shot CoT to generate reasoning chains for selected questions and construct few-shot prompt to run inference.

### 增强型语言模型

> Augmented Language Models

[Mialon et al. (2023)](https://arxiv.org/abs/2302.07842) 对增强型语言模型进行了一项调查，涵盖了多种类别，这些语言模型增强了推理能力和使用外部工具的能力。推荐阅读。

> A survey on augmented language models by [Mialon et al. (2023)](https://arxiv.org/abs/2302.07842) has great coverage over multiple categories of language models augmented with reasoning skills and the ability of using external tools. Recommend it.

#### 检索

> Retrieval

通常，我们需要完成那些需要模型预训练截止时间之后或内部/私有知识库中最新知识的任务。在这种情况下，如果我们不在提示中明确提供上下文，模型将不知道该上下文。许多[开放域问答](https://lilianweng.github.io/posts/2020-10-29-odqa/)方法都依赖于首先对知识库进行检索，然后将检索到的内容作为提示的一部分。这种过程的准确性取决于检索和生成步骤的质量。

> Often we need to complete tasks that require latest knowledge after the model pretraining time cutoff or internal/private knowledge base. In that case, the model would not know the context if we don’t explicitly provide it in the prompt. Many methods for [Open Domain Question Answering](https://lilianweng.github.io/posts/2020-10-29-odqa/) depend on first doing retrieval over a knowledge base and then incorporating the retrieved content as part of the prompt. The accuracy of such a process depends on the quality of both retrieval and generation steps.

[Lazaridou et al. (2022)](https://arxiv.org/abs/2203.05115) 研究了如何使用 Google 搜索进行文档检索以增强 LLM。给定一个问题 $q$，从 Google 返回的 20 个 URL 中提取干净文本，从而得到一组文档。由于这些文档很长，每个文档被分成 6 个句子的段落，$\{p\}$。段落根据证据段落和查询之间的 TF-IDF 余弦相似度进行排名。只有最相关的段落被用于提示中以生成答案 $a$。

> [Lazaridou et al. (2022)](https://arxiv.org/abs/2203.05115) studied how to use Google Search for document retrieval to augment LLMs. Given a question $q$, clean text is extracted out of 20 URLs returned by Google, resulting in a set of documents. Because these documents are long, each document is split into paragraphs of 6 sentences, $\{p\}$. Paragraphs are ranked by TF-IDF based cosine similarity between evidence paragraphs and the query. Only the most relevant paragraph is used in the prompt to produce an answer $a$.

对于闭卷问答，每个演示都按以下格式构建少样本提示。发现将问题与证据互换（问题和答案之间的距离更长）在所有数据集上始终产生较低的结果。

> For closed-book QA, each demonstration is formatted as follows to construct few-shot prompts. Swapping the question with the evidence (longer distance between questions and answers) is found to consistently yield lower results across all datasets.

```
Evidence: ...
Question: ...
Answer: ...
```

答案概率通过三种方式计算：

> The answer probability is computed in three ways:

1\. [RAG](https://lilianweng.github.io/posts/2020-10-29-odqa/#RAG) 风格，$p(a_i \mid q) = \sum_{i=1}^n p_\text{tf-idf} (p_i \mid q) \cdot p_\text{LM}(a_i \mid q, p_i)$，其中 $p_\text{tf-idf} (p_i \mid q)$ 是 TF-IDF 段落和问题表示之间的归一化余弦相似度。

2\. 噪声信道推理，$p(a_i\mid q) = \frac{p_\text{LM}(q \mid a_i, p_i) \cdot p_\text{LM}(a_i \mid p_i)}{p_\text{LM}(q \mid p_i)}$

3\. 专家乘积 (PoE)，除了 $p_\text{LM}(p_i \mid q)$ 之外，还结合了上面使用的所有概率。

英文原文：

1\. [RAG](https://lilianweng.github.io/posts/2020-10-29-odqa/#RAG) style, $p(a_i \mid q) = \sum_{i=1}^n p_\text{tf-idf} (p_i \mid q) \cdot p_\text{LM}(a_i \mid q, p_i)$, where $p_\text{tf-idf} (p_i \mid q)$ is the normalized cosine similarities between the TF-IDF passage and question representations.

2\. Noisy channel inference, $p(a_i\mid q) = \frac{p_\text{LM}(q \mid a_i, p_i) \cdot p_\text{LM}(a_i \mid p_i)}{p_\text{LM}(q \mid p_i)}$

3\. Product-of-Experts (PoE), combines all probabilities used above in addition to $p_\text{LM}(p_i \mid q)$.

根据他们在生成和分类任务上的实验，在三种答案重排序分数中，PoE > 噪声信道 > RAG。在单个概率中，$p_\text{LM}(a \mid q, p_i)$ 和 $p_\text{LM}(q \mid p_i, a)$ 被发现信息量最大。$p_\text{LM}(q \mid p_i, a)$ 捕捉了在给定证据段落和答案的情况下，LM 对问题的解释程度，并且可以可靠地用于答案候选的重排序。

> According to their experiments on generation and classification tasks, among three answer reranking scores - PoE > Noisy channel > RAG. Among individual probabilities, $p_\text{LM}(a \mid q, p_i)$ and $p_\text{LM}(q \mid p_i, a)$ are found to be most informative. $p_\text{LM}(q \mid p_i, a)$ captures how well the question can be explained by LM given evidence paragraph and answer and can reliably be used for reranking answer candidates.

关于 [SituatedQA](https://situatedqa.github.io/) 数据集的一个观察结果是，对于基于不同日期的问题，尽管 LM（预训练截止日期为 2020 年）可以通过 Google 搜索获取最新信息，但其在 2020 年之后的问题上的表现仍然比 2020 年之前的问题*差*很多。这表明上下文信息与模型内部知识之间存在一些差异或参数冲突。

> One observation with [SituatedQA](https://situatedqa.github.io/) dataset for questions grounded in different dates is that despite LM (pretraining cutoff is year 2020) has access to latest information via Google Search, its performance on post-2020 questions are still a lot *worse* than on pre-2020 questions. This suggests the existence of some discrepencies or conflicting parametric between contextual information and model internal knowledge.

有趣的是，即使仅使用“内部检索”，即在回答问题之前生成关于某个主题的知识，也被发现是有益的 ([Liu et al. 2022](https://arxiv.org/abs/2110.08387))。首先，我们可以使用以下模板来提取知识：

> Interestingly it is found to be beneficial even with only “internal retrieval”, that is, to generate knowledge about a topic before answering the question ([Liu et al. 2022](https://arxiv.org/abs/2110.08387)). First we can use  the following template to extract knowledge:

```
Generate some knowledge about the input. Examples:

Input: What type of water formation is formed by clouds?
Knowledge: Clouds are made of water vapor.

Input: {question}
Knowledge:
```

然后，利用模型生成的知识，进一步提示 LM 以获得答案。

> And then with model-generated knowledge, prompt the LM further to get the answer.

#### 编程语言

> Programming Language

**PAL** (Program-aided language models); [Gao et al. 2022](https://arxiv.org/abs/2211.10435)) 和 **PoT** (Program of Thoughts prompting; [Chen et al. 2022](https://arxiv.org/abs/2211.12588)) 都要求 LLM 生成编程语言语句来解决自然语言推理问题，从而将解决方案步骤卸载到 Python 解释器等运行时环境。这种设置将复杂的计算和推理解耦。它依赖于具有足够编码技能的 LM。

> Both **PAL** (Program-aided language models); [Gao et al. 2022](https://arxiv.org/abs/2211.10435)) and **PoT** (Program of Thoughts prompting; [Chen et al. 2022](https://arxiv.org/abs/2211.12588)) ask LLM to generate programming language statements to resolve natural language reasoning problems, hence offloading the solution step to a runtime such as a Python interpreter. Such setup decouples complex computation and reasoning. It relies on a LM with good enough coding skills.

![Comparing CoT and PoT. (Image source: Chen et al. 2022 ).](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/PoT.png)

#### 外部 API

> External APIs

**TALM** (Tool Augmented Language Models; [Parisi et al. 2022](https://arxiv.org/abs/2205.12255)) 是一种通过文本到文本 API 调用进行增强的语言模型。LM 被引导生成 `|tool-call` 和 `tool input text`，以任务输入文本为条件来构建 API 调用请求。当 `|result` 出现时，将调用指定的工具 API，并将返回结果附加到文本序列中。最终输出在 `|output` 标记之后生成。

> **TALM** (Tool Augmented Language Models; [Parisi et al. 2022](https://arxiv.org/abs/2205.12255)) is a language model augmented with text-to-text API calls. LM is guided to generate `|tool-call` and `tool input text` conditioned on task input text to construct API call requests. When `|result` shows up, the specified tool API is called and the returned result gets appended to the text sequence. The final output is generated following `|output` token.

![The format of API calls in TALM. (Image source: Parisi et al. 2022 ).](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/TALM.png)

TALM 采用自博弈方法，迭代地引导工具使用示例数据集并用其微调 LM。这种自博弈，定义为模型与工具 API 交互，根据新添加的工具 API 是否能改进模型输出，迭代地扩展数据集。Toolformer 也采用了相同的思想，详见下文。该流程大致模仿了一个强化学习过程，其中 LM 是策略网络，并通过带有二元奖励信号的策略梯度进行训练。

> TALM adopts a self-play approach to iteratively bootstrap the dataset of tool use examples and finetune LM with it. This self-play, defined as a model interacting with a tool API, iteratively expands the dataset based on whether a newly added tool API can improve the model outputs. Same idea is adopted in Toolformer too, described in more details below. The pipeline loosely mimics a RL process where LM is the policy network and it is trained by policy gradient with a binary reward signal.

![Self-play iterations help boost the model performance. (Image source: Parisi et al. 2022 ).](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/TALM-iteration.png)

**Toolformer** ([Schick et al. 2023](https://arxiv.org/abs/2302.04761)) 是一种可以通过简单 API 使用外部工具的语言模型，它以自监督方式构建，并且每个 API 只需少量演示。Toolformer 的工具箱包括：

> **Toolformer** ([Schick et al. 2023](https://arxiv.org/abs/2302.04761)) is a LM that can use external tools via simple APIs, which is built in a self-supervised manner and only requires a handful of demonstrations for each API. The toolbox of Toolformer includes:

- *计算器*，用于帮助 LM 解决精确数学技能的不足；
- *问答系统*以帮助处理不忠实内容和幻觉；
- *搜索引擎*以在预训练截止时间后提供最新信息；
- *翻译系统*以提高在低资源语言上的性能；
- *日历*使语言模型（LM）感知时间进程。

> • *Calculator* to help LM with the lack of precise math skills;
> • *Q&A system* to help with unfaithful content and hallucination;
> • *Search engine* to provide up-to-date information after pretraining cut off time;
> • *Translation system* to improve performance on low resource language;
> • *Calendar* to make LM be aware of time progression.

![Illustration of how to build Toolformer. (Image source: Schick et al. 2023 ).](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/toolformer.png)

Toolformer 的训练过程如下：

> Toolformer is trained as follows:

1. 
*提示以标注潜在的 API 调用*。要求预训练语言模型（LM）通过少样本学习，使用 API 调用示例来标注数据集。格式化示例：


> • 
> *Prompting to annotate potential API calls*. Ask a pre-trained LM to annotate a dataset via few-shot learning with API call usage examples. Formatting example:

![How dataset is annotated to do API calls. (Image source: Schick et al. 2023 ).](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/toolformer-annotation.png)

```
- Each API call is represented as a tuple of (API name, corresponding input), $c=(a_c, i_c)$ and its corresponding result is denoted as $r$. The API call sequences with and without results are labeled as follows, respectively:

    <div>
    $$
    \begin{aligned}
    e(c) &= \langle\texttt{API}\rangle a_c(i_c) \langle\texttt{/API}\rangle \\
    e(c, r) &= \langle\texttt{API}\rangle a_c(i_c) \to r \langle\texttt{/API}\rangle
    \end{aligned}
    $$
    </div>

- Sample API calls based on the probabilities $p_\text{LM}(\langle\texttt{API}\rangle \mid \text{prompt}(\mathbf{x}), \mathbf{x}_{1:i})$ and select top $k$ candidate positions for doing API calls at position $i$ if the probability is larger than a threshold.

- Then we sample potential API calls from the LM given the sequence $[\text{prompt}(\mathbf{x}), x_1, \dots, x_{i-1}, \langle\texttt{API}\rangle]$ as prefix and $\langle\texttt{/API}\rangle$ as suffix.
```

1\. 
*根据 API 调用是否帮助模型预测未来 token 来过滤标注。*使用自监督损失来决定哪些 API 调用是真正有用的。



• 

执行每个 API 调用 $c_i$ 以获取相应结果 $r_i$。





• 

当模型以提示为前缀时，计算语言模型（LM）在 token $x_i, \dots, x_n$ 上的加权交叉熵损失。计算两个版本，一个带有 API 结果，另一个带有空序列 $\varepsilon$。



只保留 $L^-_i - L^+_i$ 大于某个阈值的 API 调用，这意味着添加此 API 调用及其结果有助于模型预测未来的 token。

2\. 
*在此标注数据集上微调语言模型（LM）。*新的训练序列构造为 $\mathbf{x}^{\ast} = x_{1:i-1}, e(c_i, r_i), x_{i:n}$ 。训练数据是原始数据集（例如，论文中提到的 CCNet 的一个子集）及其增强版本的组合。


英文原文：

1\. 
*Filter annotations based on whether API calls help model predict future tokens.* Use a self-supervised loss to decide which API calls are actually helpful.



• 

Execute each API call $c_i$ to get corresponding result $r_i$.





• 

Compute weighted cross entropy loss for the LM over tokens $x_i, \dots, x_n$ when the model is prefixed with the prompt. Two versions are computed, one with API result and the other with empty sequence $\varepsilon$.



Only API calls with $L^-_i - L^+_i$ larger than a threshold are kept, meaning that adding this API call and its results help the model predict future tokens.

2\. 
*Fine-tune LM on this annotated dataset.* The new training sequences are constructed as $\mathbf{x}^{\ast} = x_{1:i-1}, e(c_i, r_i), x_{i:n}$ . The training data is a combination of the original dataset (e.g. a subset of CCNet, as in the paper) and its augmented version.


$$
\begin{aligned}
  L^+_i &= L_i(e(c_i, r_i)) \\
  L^-_i &= \min(L_i(\varepsilon), L_i(e(c_i, \varepsilon))) \\
  \end{aligned}
$$

在推理时，解码一直运行，直到模型生成“$\to$ ” token，表明它接下来期望来自 API 调用的响应。

> At inference time, decoding runs until the model produces “$\to$ " token, indicating that it is expecting response from an API call next.

Toolformer 目前不支持链式工具使用（即，将一个工具的输出作为另一个工具的输入）或交互式工具使用（即，在人工选择后采纳 API 响应）。这两者都是扩展模型的有趣未来方向。

> Toolformer currently does not support tool use in a chain (i.e. using the output of one tool as an input for another tool) or in an interactive way (i.e. adopt API response after human selection). Both are interesting future directions to expand the model for.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Mar 2023). Prompt Engineering. Lil’Log. https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/.

> Weng, Lilian. (Mar 2023). Prompt Engineering. Lil’Log. https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/.

或

> Or

```
@article{weng2023prompt,
  title   = "Prompt Engineering",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2023",
  month   = "Mar",
  url     = "https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/"
}
```

### 有用资源

> Useful Resources

- [OpenAI Cookbook](https://github.com/openai/openai-cookbook) 包含许多关于如何高效利用大型语言模型（LLM）的深入示例。
- [LangChain](https://langchain.readthedocs.io/en/latest/)，一个用于将语言模型与其他组件结合以构建应用程序的库。
- [Prompt Engineering Guide](https://github.com/dair-ai/Prompt-Engineering-Guide) 仓库包含一份相当全面的关于提示工程的教育材料合集。
- [learnprompting.org](https://learnprompting.org/docs/intro)
- [PromptPerfect](https://promptperfect.jina.ai)
- [Semantic Kernel](https://github.com/microsoft/semantic-kernel)

> • [OpenAI Cookbook](https://github.com/openai/openai-cookbook) has many in-depth examples for how to utilize LLM efficiently.
> • [LangChain](https://langchain.readthedocs.io/en/latest/), a library for combining language models with other components to build applications.
> • [Prompt Engineering Guide](https://github.com/dair-ai/Prompt-Engineering-Guide) repo contains a pretty comprehensive collection of education materials on prompt engineering.
> • [learnprompting.org](https://learnprompting.org/docs/intro)
> • [PromptPerfect](https://promptperfect.jina.ai)
> • [Semantic Kernel](https://github.com/microsoft/semantic-kernel)

### 参考文献

> References

[1] Zhao et al. [“使用前校准：提高语言模型的少样本性能。”](https://arxiv.org/abs/2102.09690) ICML 2021

> [1] Zhao et al. [“Calibrate Before Use: Improving Few-shot Performance of Language Models.”](https://arxiv.org/abs/2102.09690) ICML 2021

[2] Liu et al. [“什么构成了 GPT-3 的良好上下文示例？”](https://arxiv.org/abs/2101.06804) arXiv preprint arXiv:2101.06804 (2021)。

> [2] Liu et al. [“What Makes Good In-Context Examples for GPT-3?”](https://arxiv.org/abs/2101.06804) arXiv preprint arXiv:2101.06804 (2021).

[3] Lu et al. [“奇妙有序的提示及其发现：克服少样本提示顺序敏感性。”](https://arxiv.org/abs/2104.08786) ACL 2022

> [3] Lu et al. [“Fantastically Ordered Prompts and Where to Find Them: Overcoming Few-Shot Prompt Order Sensitivity.”](https://arxiv.org/abs/2104.08786) ACL 2022

[4] Ye et al. [“上下文指令学习。”](https://arxiv.org/abs/2302.14691) arXiv preprint arXiv:2302.14691 (2023)。

> [4] Ye et al. [“In-Context Instruction Learning.”](https://arxiv.org/abs/2302.14691) arXiv preprint arXiv:2302.14691 (2023).

[5] Su et al. [“选择性标注使语言模型成为更好的少样本学习器。”](https://arxiv.org/abs/2209.01975) arXiv preprint arXiv:2209.01975 (2022)。

> [5] Su et al. [“Selective annotation makes language models better few-shot learners.”](https://arxiv.org/abs/2209.01975) arXiv preprint arXiv:2209.01975 (2022).

[6] Rubin et al. [“学习检索用于上下文学习的提示。”](https://arxiv.org/abs/2112.08633) NAACL-HLT 2022

> [6] Rubin et al. [“Learning to retrieve prompts for in-context learning.”](https://arxiv.org/abs/2112.08633) NAACL-HLT 2022

[7] Wei et al. [“思维链提示引发大型语言模型的推理。”](https://arxiv.org/abs/2201.11903) NeurIPS 2022

> [7] Wei et al. [“Chain of thought prompting elicits reasoning in large language models.”](https://arxiv.org/abs/2201.11903) NeurIPS 2022

[8] Wang et al. [“自洽性改进语言模型中的思维链推理。”](https://arxiv.org/abs/2203.11171) ICLR 2023。

> [8] Wang et al. [“Self-Consistency Improves Chain of Thought Reasoning in Language Models.”](https://arxiv.org/abs/2203.11171) ICLR 2023.

[9] Diao et al. [“大型语言模型的思维链主动提示。”](https://arxiv.org/abs/2302.12246) arXiv preprint arXiv:2302.12246 (2023)。

> [9] Diao et al. [“Active Prompting with Chain-of-Thought for Large Language Models.”](https://arxiv.org/abs/2302.12246) arXiv preprint arXiv:2302.12246 (2023).

[10] Zelikman et al. [“STaR：用推理引导推理。”](https://arxiv.org/abs/2203.14465) arXiv preprint arXiv:2203.14465 (2022)。

> [10] Zelikman et al. [“STaR: Bootstrapping Reasoning With Reasoning.”](https://arxiv.org/abs/2203.14465) arXiv preprint arXiv:2203.14465 (2022).

[11] Ye & Durrett. [“少样本上下文学习中解释的不可靠性。”](https://arxiv.org/abs/2205.03401) arXiv preprint arXiv:2205.03401 (2022)。

> [11] Ye & Durrett. [“The unreliability of explanations in few-shot in-context learning.”](https://arxiv.org/abs/2205.03401) arXiv preprint arXiv:2205.03401 (2022).

[12] Trivedi et al. [“将检索与思维链推理交织用于知识密集型多步问题。”](https://arxiv.org/abs/2212.10509) arXiv preprint arXiv:2212.10509 (2022)。

> [12] Trivedi et al. [“Interleaving retrieval with chain-of-thought reasoning for knowledge-intensive multi-step questions.”](https://arxiv.org/abs/2212.10509) arXiv preprint arXiv:2212.10509 (2022).

[13] Press et al. [“衡量和缩小语言模型中的组合性差距。”](https://arxiv.org/abs/2210.03350) arXiv preprint arXiv:2210.03350 (2022)。

> [13] Press et al. [“Measuring and narrowing the compositionality gap in language models.”](https://arxiv.org/abs/2210.03350) arXiv preprint arXiv:2210.03350 (2022).

[14] Yao et al. [“ReAct：在语言模型中协同推理和行动。”](https://arxiv.org/abs/2210.03629) ICLR 2023。

> [14] Yao et al. [“ReAct: Synergizing reasoning and acting in language models.”](https://arxiv.org/abs/2210.03629) ICLR 2023.

[15] Fu et al. [“基于复杂度的多步推理提示。”](https://arxiv.org/abs/2210.00720) arXiv preprint arXiv:2210.00720 (2022)。

> [15] Fu et al. [“Complexity-based prompting for multi-step reasoning.”](https://arxiv.org/abs/2210.00720) arXiv preprint arXiv:2210.00720 (2022).

[16] Wang et al. [“语言模型中的理由增强集成。”](https://arxiv.org/abs/2207.00747) arXiv preprint arXiv:2207.00747 (2022)。

> [16] Wang et al. [“Rationale-augmented ensembles in language models.”](https://arxiv.org/abs/2207.00747) arXiv preprint arXiv:2207.00747 (2022).

[17] Zhang et al. [“大型语言模型中的自动思维链提示。”](https://arxiv.org/abs/2210.03493) arXiv preprint arXiv:2210.03493 (2022)。

> [17] Zhang et al. [“Automatic chain of thought prompting in large language models.”](https://arxiv.org/abs/2210.03493) arXiv preprint arXiv:2210.03493 (2022).

[18] Shum et al. [“从标注数据中自动进行思维链提示增强和选择。”](https://arxiv.org/abs/2302.12822) arXiv preprint arXiv:2302.12822 (2023)。

> [18] Shum et al. [“Automatic Prompt Augmentation and Selection with Chain-of-Thought from Labeled Data.”](https://arxiv.org/abs/2302.12822) arXiv preprint arXiv:2302.12822 (2023).

[19] Zhou et al. [“大型语言模型是人类水平的提示工程师。”](https://arxiv.org/abs/2211.01910) ICLR 2023。

> [19] Zhou et al. [“Large Language Models Are Human-Level Prompt Engineers.”](https://arxiv.org/abs/2211.01910) ICLR 2023.

[20] Lazaridou et al. [“通过少样本提示进行互联网增强的语言模型用于开放域问答。”](https://arxiv.org/abs/2203.05115) arXiv preprint arXiv:2203.05115 (2022)。

> [20] Lazaridou et al. [“Internet augmented language models through few-shot prompting for open-domain question answering.”](https://arxiv.org/abs/2203.05115) arXiv preprint arXiv:2203.05115 (2022).

[21] Chen et al. [“思维程序提示：将数值推理任务中的计算与推理分离。”](https://arxiv.org/abs/2211.12588) arXiv preprint arXiv:2211.12588 (2022)。

> [21] Chen et al. [“Program of Thoughts Prompting: Disentangling Computation from Reasoning for Numerical Reasoning Tasks.”](https://arxiv.org/abs/2211.12588) arXiv preprint arXiv:2211.12588 (2022).

[22] Gao et al. [“PAL：程序辅助语言模型。”](https://arxiv.org/abs/2211.10435) arXiv preprint arXiv:2211.10435 (2022)。

> [22] Gao et al. [“PAL: Program-aided language models.”](https://arxiv.org/abs/2211.10435) arXiv preprint arXiv:2211.10435 (2022).

[23] Parisi et al. [“TALM：工具增强语言模型”](https://arxiv.org/abs/2205.12255) arXiv preprint arXiv:2205.12255 (2022)。

> [23] Parisi et al. [“TALM: Tool Augmented Language Models”](https://arxiv.org/abs/2205.12255) arXiv preprint arXiv:2205.12255 (2022).

[24] Schick et al. [“Toolformer：语言模型可以自学使用工具。”](https://arxiv.org/abs/2302.04761) arXiv preprint arXiv:2302.04761 (2023)。

> [24] Schick et al. [“Toolformer: Language Models Can Teach Themselves to Use Tools.”](https://arxiv.org/abs/2302.04761) arXiv preprint arXiv:2302.04761 (2023).

[25] Mialon et al. [“增强语言模型：一项综述”](https://arxiv.org/abs/2302.07842) arXiv preprint arXiv:2302.07842 (2023)。

> [25] Mialon et al. [“Augmented Language Models: a Survey”](https://arxiv.org/abs/2302.07842) arXiv preprint arXiv:2302.07842 (2023).

[26] Yao et al. [“思维树：大型语言模型的深思熟虑问题解决。”](https://arxiv.org/abs/2305.10601) arXiv preprint arXiv:2305.10601 (2023)。

> [26] Yao et al. [“Tree of Thoughts: Deliberate Problem Solving with Large Language Models.”](https://arxiv.org/abs/2305.10601) arXiv preprint arXiv:2305.10601 (2023).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Prompt Engineering | 提示工程 | 与大型语言模型沟通以引导其行为达到预期结果的方法。 |
| Large Language Model (LLM) | 大型语言模型 | 具有大量参数、在海量文本数据上训练的深度学习模型，能够理解和生成人类语言。 |
| Zero-shot Learning | 零样本学习 | 无需任何示例，直接将任务文本输入模型并请求结果的学习方法。 |
| Few-shot Learning | 少样本学习 | 通过提供少量高质量的输入-输出演示来引导模型理解任务并生成预期结果的学习方法。 |
| Instruction Prompting | 指令提示 | 直接向模型提供详细、具体的任务指令，以引导其行为。 |
| Self-Consistency Sampling | 自洽性采样 | 采样多个模型输出，然后通过多数投票或其他标准选择最佳结果以提高准确性。 |
| Chain-of-Thought (CoT) Prompting | 思维链提示 | 引导模型生成逐步的推理逻辑（推理链），从而解决复杂推理任务。 |
| Automatic Prompt Design | 自动提示设计 | 通过优化嵌入空间或搜索指令候选等方法，自动化创建有效提示的过程。 |
| Retrieval-Augmented Generation (RAG) | 检索增强生成 | 结合信息检索系统，从外部知识库中获取相关信息作为上下文，以增强语言模型的生成能力。 |
| Tool-Augmented Language Models (TALM) | 工具增强语言模型 | 能够通过生成API调用请求并处理返回结果来与外部工具交互的语言模型。 |
| Autoregressive Language Model | 自回归语言模型 | 一种根据前一个或多个词预测下一个词的语言模型，常用于文本生成。 |
| Reinforcement Learning from Human Feedback (RLHF) | 基于人类反馈的强化学习 | 通过人类偏好数据对模型进行微调，使其行为与人类意图更一致的强化学习方法。 |
| Context Length Limit | 上下文长度限制 | 语言模型在单次处理中能够接受的最大输入文本长度。 |
| Embeddings | 嵌入 | 将词语、句子或文档表示为低维连续向量的技术，用于捕捉其语义信息。 |
| API (Application Programming Interface) | 应用程序编程接口 | 一组定义、协议和工具，用于构建软件应用程序，允许不同软件组件之间进行通信。 |
