# 我们为何思考

> Why We Think

> 来源：Lil'Log / Lilian Weng，2025-05-01
> 原文链接：https://lilianweng.github.io/posts/2025-05-01-thinking/
> 分类：人工智能 / 大语言模型推理

## 核心要点

- 测试时计算和思维链（CoT）显著提升了大型语言模型的性能，并引发了对其有效利用和作用机制的深入研究。
- 模型“思考”更长时间的动机与人类的快慢思维模式（系统1和系统2）相似，即深思熟虑能提高复杂问题的准确性。
- 从计算资源角度看，为模型提供更多测试时计算并有效利用，能使其表现更优，CoT尤其能根据问题难度自适应分配计算资源。
- 潜在变量建模为理解并行CoT或CoT搜索方法提供了理论框架，将其视为从后验分布中采样。
- 通过生成中间步骤（即“以Token思考”），模型能够逐步推理，并通过监督学习、强化学习或特定提示（如“think step by step”）显著增强推理能力。
- 模型可以通过并行采样（如束搜索、自洽性）生成多个候选答案并选择最佳，或通过顺序修订迭代地调整和纠正其响应。
- 强化学习在提升语言模型推理能力方面取得了显著成功，特别是通过奖励正确答案，促使模型学习高级推理技能，包括反思和回溯。
- 将推理过程中的计算或知识获取卸载到外部工具（如代码解释器、API）可以扩展LLM的能力，提高数学、符号推理和算法任务的准确性。
- 思维链提供了一种自然语言形式的可解释性，但其忠实性并非固有，模型可能因训练目标或数据偏差而未能忠实表达其内部思考过程。
- 对CoT忠实性的研究表明，其有效性对任务和模型大小的依赖性不同，且不总是随模型增大而增加，尤其对于复杂推理任务更为关键。

## 正文

特别感谢[John Schulman](https://scholar.google.com/citations?user=itSa94cAAAAJ&hl=en)为本文提供了许多宝贵的反馈和直接编辑。

> Special thanks to [John Schulman](https://scholar.google.com/citations?user=itSa94cAAAAJ&hl=en) for a lot of super valuable feedback and direct edits on this post.

测试时计算（[Graves et al. 2016](https://arxiv.org/abs/1603.08983), [Ling, et al. 2017](https://arxiv.org/abs/1705.04146), [Cobbe et al. 2021](https://arxiv.org/abs/2110.14168)）以及思维链（CoT）（[Wei et al. 2022](https://arxiv.org/abs/2201.11903), [Nye et al. 2021](https://arxiv.org/abs/2112.00114)），显著提升了模型性能，同时也提出了许多研究问题。本文旨在回顾如何有效利用测试时计算（即“思考时间”）以及其为何有帮助的最新进展。

> Test time compute ([Graves et al. 2016](https://arxiv.org/abs/1603.08983), [Ling, et al. 2017](https://arxiv.org/abs/1705.04146), [Cobbe et al. 2021](https://arxiv.org/abs/2110.14168)) and Chain-of-thought (CoT) ([Wei et al. 2022](https://arxiv.org/abs/2201.11903), [Nye et al. 2021](https://arxiv.org/abs/2112.00114)), have led to significant improvements in model performance, while raising many research questions. This post aims to review recent developments in how to effectively use test-time compute (i.e. “thinking time”) and why it helps.

### 动机

> Motivation

让模型能够思考更长时间，可以从几个不同的角度来阐述其动机。

> Enabling models to think for longer can be motivated in a few different ways.

#### 与心理学的类比

> Analogy to Psychology

核心思想与人类的思维方式紧密相连。我们人类无法立即给出`"What's 12345 times 56789?"`的答案。相反，尤其对于复杂问题，在得出结果之前，花时间思考和分析是自然而然的。在[Thinking, Fast and Slow (Kahneman, 2013)](https://www.amazon.com/Thinking-Fast-Slow-Daniel-Kahneman/dp/0374533555)中，丹尼尔·卡尼曼（Daniel Kahneman）通过[dual process theory](https://en.wikipedia.org/wiki/Dual_process_theory)的视角，将人类思维分为两种模式：

> The core idea is deeply connected to how humans think. We humans cannot immediately provide the answer for `"What's 12345 times 56789?"`. Rather, it is natural to spend time pondering and analyzing before getting to the result, especially for complex problems. In [Thinking, Fast and Slow (Kahneman, 2013)](https://www.amazon.com/Thinking-Fast-Slow-Daniel-Kahneman/dp/0374533555), Daniel Kahneman characterizes human thinking into two modes, through the lens of the [dual process theory](https://en.wikipedia.org/wiki/Dual_process_theory) :

- *快速思考（系统1）*快速且自动地运作，受直觉和情感驱动，几乎不费力气。
- *慢速思考（系统2）*需要深思熟虑、逻辑思考和大量的认知努力。这种思维模式消耗更多的脑力，需要有意识地投入。

> • *Fast thinking (System 1)* operates quickly and automatically, driven by intuition and emotion while requiring little to no effort.
> • *Slow thinking (System 2)* demands deliberate, logical thought and significant cognitive efforts. This mode of thinking consumes more mental energy and requires intentional engagement.

由于系统1思维快速且轻松，它常常成为主要的决策驱动因素，但代价是牺牲了准确性和逻辑性。它自然地依赖我们大脑的思维捷径（即启发式），并可能导致错误和偏见。通过有意识地放慢速度，花更多时间反思、改进和分析，我们可以运用系统2思维来挑战我们的直觉，做出更理性的选择。

> Because System 1 thinking is fast and easy, it often ends up being the main decision driver, at the cost of accuracy and logic. It naturally relies on our brain’s mental shortcuts (i.e., heuristics) and can lead to errors and biases. By consciously slowing down and taking more time to reflect, improve and analyze, we can engage in System 2 thinking to challenge our instincts and make more rational choices.

#### 计算作为一种资源

> Computation as a Resource

深度学习的一种观点是，神经网络可以通过它们在前向传播中可以访问的计算量和存储量来表征；如果我们使用梯度下降优化它们来解决问题，优化过程将找出如何利用这些资源——它们将找出如何将这些资源组织成用于计算和信息存储的电路。从这个角度来看，如果我们设计一个在测试时可以进行更多计算的架构或系统，并训练它有效利用这一资源，它将表现得更好。

> One view of deep learning, is that neural networks can be characterized by the amount of computation and storage they can access in a forward pass, and if we optimize them to solve problems using gradient descent, the optimization process will figure out how to use these resources–they’ll figure out how to organize these resources into circuits for calculation and information storage. From this view, if we design an architecture or system that can do more computation at test time, and we train it to effectively use this resource, it’ll work better.

在Transformer模型中，模型为每个生成的token执行的计算量（浮点运算）大约是参数数量的2倍。对于专家混合（MoE）等稀疏模型，每次前向传播只使用一小部分参数，因此计算量 = 2 * 参数 / 稀疏度，其中稀疏度是活跃专家的比例。

> In Transformer models, the amount of computation (flops) that the model does for each generated token is roughly 2 times the number of parameters. For sparse models like mixture of experts (MoE), only a fraction of the parameters are used in each forward pass, so computation = 2 * parameters / sparsity, where sparsity is the fraction of experts active.

另一方面，CoT使模型能够为它试图计算的答案的每个token执行更多的浮点运算。事实上，CoT有一个很好的特性，即它允许模型根据问题的难度使用可变数量的计算资源。

> On the other hand, CoT enables the model to perform far more flops of computation for each token of the answer that it is trying to compute. In fact, CoT has a nice property that it allows the model to use a variable amount of compute depending on the hardness of the problem.

#### 潜在变量建模

> Latent Variable Modeling

机器学习中的一个经典思想是定义一个包含潜在（隐藏）变量$z$和一个可见变量$y$的概率模型，其中$y$被提供给我们的学习算法。对潜在变量的可能值进行边缘化（求和）使我们能够表达可见变量的丰富分布，即$P(y) = \sum_{z \sim P(z)} P(y \mid z)$。例如，我们可以通过让$x$表示问题陈述，$y$是真实答案或证明，以及$z$作为导致证明的自由形式思维过程，来建模数学问题和解决方案的分布。要优化的边际概率分布将是$P(y \mid x) = \sum_{z \sim p(z\mid x)} P(y \mid x, z)$

> A classic idea in machine learning is to define a probabilistic model with a latent (hidden) variable $z$ and a visible variable $y$, where $y$ is given to our learning algorithm. Marginalizing (summing) over the possible values of the latent variable allows us to express a rich distribution over the visible variables, $P(y) = \sum_{z \sim P(z)} P(y \mid z)$. For example, we can model the distribution over math problems and solutions by letting $x$ denote a problem statement, $y$ be ground truth answer or proof, and $z$ as a free-form thought process that leads to the proof. The marginal probability distribution to optimize would be $P(y \mid x) = \sum_{z \sim p(z\mid x)} P(y \mid x, z)$

潜在变量视角对于理解涉及收集多个并行CoT或在CoT上进行搜索的方法特别有用——这些算法可以被视为从后验分布$P(z \mid x, y)$中进行采样。这种观点也表明了使用对数损失$\log P(y \mid x)$作为优化目标的好处，因为对数损失目标在预训练中非常有效。

> The latent variable perspective is particularly useful for understanding methods that involve collecting multiple parallel CoTs or searching over the CoT–these algorithms can be seen as sampling from the posterior $P(z \mid x, y)$. This view also suggests the benefits of using the log loss $\log P(y \mid x)$ as the target objective to optimize, as the log loss objective has been so effective in pretraining.

### 以Token思考

> Thinking in Tokens

在生成简短答案之前生成中间步骤的策略，特别是对于数学问题，由[Ling, et al. 2017](https://arxiv.org/abs/1705.04146)进行了探索，他们引入了[AQUA-RAT](https://github.com/google-deepmind/AQuA)数据集，随后由[Cobbe et al. 2021](https://arxiv.org/abs/2110.14168)进行了扩展，他们引入了[Grade School Math (GSM)](https://github.com/openai/grade-school-math)数据集。Cobbe等人使用人类编写的解决方案和预测候选解决方案正确性的验证器进行监督学习，训练了一个生成器；然后他们可以在这些解决方案中进行搜索。[Nye et al. (2021](https://arxiv.org/abs/2112.00114))实验了将中间思考token作为“草稿本”，而[Wei et al.](https://arxiv.org/abs/2201.11903) (2022)创造了现在标准的术语**chain-of-thought** (CoT)。

> The strategy of generating intermediate steps before generating short answers, particularly for math problems, was explored by [Ling, et al. 2017](https://arxiv.org/abs/1705.04146), who introduced the [AQUA-RAT](https://github.com/google-deepmind/AQuA) dataset, and then expanded by [Cobbe et al. 2021](https://arxiv.org/abs/2110.14168), who introduced the [Grade School Math (GSM)](https://github.com/openai/grade-school-math) dataset. Cobbe et al. train a generator with supervised learning on human-written solutions and verifiers that predict the correctness of a candidate solution; they can then search over these solutions. [Nye et al. (2021](https://arxiv.org/abs/2112.00114)) experimented with intermediate thinking tokens as “scratchpads” and [Wei et al.](https://arxiv.org/abs/2201.11903) (2022) coined the now-standard term **chain-of-thought** (CoT).

早期改进CoT推理的工作涉及对人类编写的推理轨迹或经过答案正确性筛选的模型编写轨迹进行监督学习，后者可以被视为强化学习（RL）的一种基本形式。其他一些工作发现，通过适当的提示，可以显著提升指令微调模型的数学性能，例如使用`"think step by step"`（[Kojima et al. 2022](https://arxiv.org/abs/2205.11916)）或更复杂的提示来鼓励模型首先反思相关知识（[Yasunaga et al. 2023](https://arxiv.org/abs/2310.01714)）。

> Early work on improving CoT reasoning involved doing supervised learning on human-written reasoning traces or model-written traces filtered for answer correctness, where the latter can be seen as a rudimentary form of reinforcement learning (RL). Some other work found that one could significantly boost math performance of instruction tuned models by prompting them appropriately, with `"think step by step"` ([Kojima et al. 2022](https://arxiv.org/abs/2205.11916)) or more complex prompting to encourage the model to reflect on related knowledge first ([Yasunaga et al. 2023](https://arxiv.org/abs/2310.01714)).

后来的工作发现，通过对具有自动可检查解决方案的问题数据集进行强化学习，可以显著提高CoT推理能力，例如具有简短答案的STEM问题，或可以通过单元测试检查的编码任务（[Zelikman et al. 2022](https://arxiv.org/abs/2203.14465), [Wang et al., 2023](https://arxiv.org/abs/2312.08935), [Liu et al., 2023](https://arxiv.org/abs/2310.10047)）。随着[o1-preview](https://openai.com/index/learning-to-reason-with-llms/), [o3](https://openai.com/index/introducing-o3-and-o4-mini/), and the R1 tech report ([DeepSeek-AI, 2025](https://arxiv.org/abs/2501.12948))的发布，这种方法变得突出，该报告表明，一个简单的策略梯度算法配方可以带来强大的性能。

> Later work found that the CoT reasoning capabilities can be significantly improved by doing reinforcement learning on a dataset of problems with automatically checkable solutions, such as STEM problems with short answers, or coding tasks that can be checked with unit tests ([Zelikman et al. 2022](https://arxiv.org/abs/2203.14465), [Wang et al., 2023](https://arxiv.org/abs/2312.08935), [Liu et al., 2023](https://arxiv.org/abs/2310.10047)). This approach rose to prominence with the announcement of [o1-preview](https://openai.com/index/learning-to-reason-with-llms/), [o3](https://openai.com/index/introducing-o3-and-o4-mini/), and the R1 tech report ([DeepSeek-AI, 2025](https://arxiv.org/abs/2501.12948)), which showed that a simple recipe where a policy gradient algorithm could lead to strong performance.

![Chain-of-thought prompting leads to higher success rate of solving math problems. Larger models benefit more from thinking time. (Image source: Wei et al. 2022)](https://lilianweng.github.io/posts/2025-05-01-thinking/cot-wei22.png)

#### 分支与编辑

> Branching and Editing

测试时计算的根本目的是在测试时自适应地修改模型的输出分布。有多种方法可以利用测试时资源进行解码，以选择更好的样本，从而将模型的预测调整到更理想的分布。改进解码过程的两种主要方法是并行采样和顺序修订。

> The fundamental intent of test-time compute is to adaptively modify the model’s output distribution at test time. There are various ways of utilizing test time resources for decoding to select better samples and thus alter the model’s predictions towards a more desired distribution. Two main approaches for improving the decoding process are parallel sampling and sequential revision.

• **并行采样**同时生成多个输出，同时通过过程奖励信号提供每一步的指导，或在最后使用验证器判断质量。它是最广泛采用的解码方法，用于提高测试时性能，例如最佳$N$或束搜索。当真实值不可用时，自洽性（[Wang et al. 2023](https://arxiv.org/abs/2203.11171)）常用于在多个CoT运行中通过多数投票选择答案。

• **顺序修订**根据上一步的输出迭代地调整模型的响应，要求模型有意识地反思其现有响应并纠正错误。修订过程可能需要依赖一个经过微调的模型，因为天真地依赖模型固有的自我纠正能力而没有外部反馈可能无法带来改进（[Kamoi et al. 2024](https://arxiv.org/abs/2406.01297), [Huang et al. 2024](https://arxiv.org/abs/2310.01798)）。

英文原文：

• **Parallel sampling** generates multiple outputs simultaneously, meanwhile providing guidance per step with process reward signals or using verifiers to judge the quality at the end. It is the most widely adopted decoding method to improve test time performance, such as best-of-$N$ or beam search. Self-consistency ([Wang et al. 2023](https://arxiv.org/abs/2203.11171)) is commonly used to select the answer with majority vote among multiple CoT rollouts when the ground truth is not available.

• **Sequential revision** adapts the model’s responses iteratively based on the output in the previous step, asking the model to intentionally reflect its existing response and correct mistakes. The revision process may have to rely on a fine-tuned model, as naively relying on the model’s intrinsic capability of self-correction without external feedback may not lead to improvement ([Kamoi et al. 2024](https://arxiv.org/abs/2406.01297), [Huang et al. 2024](https://arxiv.org/abs/2310.01798)).

并行采样简单、直观且易于实现，但受限于模型能否一次性获得正确解决方案的能力。顺序修订明确要求模型反思错误，但它速度较慢，并且在实现过程中需要格外小心，因为它确实存在将正确预测修改为不正确或引入其他类型幻觉的风险。这两种方法可以结合使用。[Snell et al. (2024](https://arxiv.org/abs/2408.03314))表明，较简单的问题受益于纯粹的顺序测试时计算，而较难的问题通常在顺序与并行计算的最佳比例下表现最佳。

> Parallel sampling is simple, intuitive and easier to implement, but bounded by the model capability of whether it can achieve the correct solution in one-go. Sequential explicitly asks the model to reflect on mistakes but it is slower and requires extra care during implementation as it does run the risk of correct predictions being modified to be incorrect or introducing other types of hallucinations. These two methods can be used together. [Snell et al. (2024](https://arxiv.org/abs/2408.03314)) showed that easier questions benefit from purely sequential test-time compute, whereas harder questions often perform best with an optimal ratio of sequential to parallel compute.

![Illustration of parallel sampling vs sequential revision.](https://lilianweng.github.io/posts/2025-05-01-thinking/parallel-vs-sequential.png)

##### 并行采样

> Parallel Sampling

给定一个生成模型和一个可用于对完整或部分样本进行评分的评分函数，我们可以使用各种搜索算法来找到高评分样本。最佳$N$是其中最简单的算法：只需收集$N$个独立样本，并根据某个评分函数选择排名最高的样本。束搜索是一种更复杂的搜索算法，它使搜索过程更具适应性，将更多的采样计算用于解决方案空间中更有希望的部分。

> Given a generative model and a scoring function that we can use to score full or partial samples, there are various search algorithms we can use to find a high scoring sample. Best-of-$N$ is the simplest such algorithm: one just collects $N$ independent samples and chooses the highest-ranking sample according to some scoring function. Beam search is a more sophisticated search algorithm that makes the search process more adaptive, spending more sampling computation on more promising parts of the solution space.

束搜索维护一组有前景的部分序列，并交替进行扩展和修剪那些前景较差的序列。作为一种选择机制，我们可以使用过程奖励模型（PRM；[Lightman et al. 2023](https://arxiv.org/abs/2305.20050)）来指导束搜索候选选择。[Xie et al. (2023](https://arxiv.org/abs/2305.00633))使用LLM评估其自身生成的推理步骤有多大可能是正确的，并将其格式化为多项选择题，发现每步自我评估减少了束搜索解码中多步推理的累积错误。此外，在采样过程中，退火温度有助于减轻累积的随机性。Xie等人的这些实验使用Codex模型在少样本GSM8k、AQuA和StrategyQA基准测试上实现了5-6%的改进。奖励平衡搜索（简称“REBASE”；[Wu et al. 2025](https://arxiv.org/abs/2408.00724)）分别训练了一个过程奖励模型（PRM），根据softmax归一化的奖励分数，在束搜索期间确定每个节点在每个深度应扩展多少。[Jiang et al. (2024)](https://arxiv.org/abs/2410.01044)训练了他们的PRM，名为“RATIONALYST”，用于在大量未标记数据上以合成理由为条件进行束搜索指导。好的理由是根据它们是否通过一个阈值帮助减少真实答案token的负对数概率来筛选的，比较的是理由包含在上下文中与不包含在上下文中的差异。在推理时，RATIONALYST通过帮助估计下一个推理步骤的对数概率（“隐式”）或直接生成下一个推理步骤作为提示的一部分（“显式”），为CoT生成器提供过程监督。

> Beam search maintains a set of promising partial sequences and alternates between extending them and pruning the less promising ones. As a selection mechanism, we can use a process reward model (PRM; [Lightman et al. 2023](https://arxiv.org/abs/2305.20050)) to guide beam search candidate selection. [Xie et al. (2023](https://arxiv.org/abs/2305.00633)) used LLM to evaluate how likely its own generated reasoning step is correct, formatted as a multiple-choice question and found that per-step self-evaluation reduces accumulative errors in multi-step reasoning during beam search decoding. Besides, during sampling, annealing the temperature helps mitigate aggregated randomness. These experiments by Xie et al. achieved 5-6% improvement on few-shot GSM8k, AQuA and StrategyQA benchmarks with the Codex model. Reward balanced search (short for “REBASE”; [Wu et al. 2025](https://arxiv.org/abs/2408.00724)) separately trained a process reward model (PRM) to determine how much each node should be expanded at each depth during beam search, according to the softmax-normalized reward scores. [Jiang et al. (2024)](https://arxiv.org/abs/2410.01044) trained their PRM, named “RATIONALYST”, for beam search guidance on synthetic rationales conditioned on a large amount of unlabelled data. Good rationales are filtered based on whether they help reduce the neg log-prob of true answer tokens by a threshold, when comparing the difference between when the rationales is included in the context vs not. At inference time, RATIONALYST provides process supervision to the CoT generator by helping estimate log-prob of next reasoning steps (“implicit”) or directly generating next reasoning steps as part of the prompt (“explicit”).

![Beam search decoding guided by LLM self-evaluation per reasoning step. (Image source: Xie et al. 2023 )](https://lilianweng.github.io/posts/2025-05-01-thinking/beam-search-xie23.png)

有趣的是，可以在*没有*显式零样本或少样本提示的情况下，触发涌现的思维链推理路径。[Wang & Zhou (2024)](https://arxiv.org/abs/2402.10200)发现，如果在第一个采样token处进行分支，保留置信度最高的$k$个token（置信度衡量为采样时top-1和top-2候选之间的差异），然后继续这些$k$个采样试验并进行贪婪解码，那么许多这样的序列本身就包含CoT。特别是当CoT确实出现在上下文中时，它会导致最终答案的解码更加自信。为了计算最终答案的置信度，需要通过任务特定的启发式方法（例如数学问题的最后一个数值）或通过使用`"So the answer is"`进一步提示模型来识别答案范围。仅在第一个token处进行分支的设计选择是基于这样的观察：早期分支显著增强了潜在路径的多样性，而后续token则很大程度上受到先前序列的影响。

> Interestingly, it is possible to trigger the emergent chain-of-thought reasoning paths *without* explicit zero-shot or few-shot prompting. [Wang & Zhou (2024)](https://arxiv.org/abs/2402.10200) discovered that if we branch out at the first sampling tokens by retaining the top $k$ tokens with highest confidence, measured as the difference between top-1 and top-2 candidates during sampling, and then continue these $k$ sampling trials with greedy decoding onward, many of these sequences natively contain CoT. Especially when CoT does appear in the context, it leads to a more confident decoding of the final answer. To calculate the confidence of the final answer, the answer span needs to be identified by task-specific heuristics (e.g. last numerical values for math questions) or  by prompting the model further with `"So the answer is"`. The design choice of only branching out at the first token is based on the observation that early branching significantly enhances the diversity of potential paths, while later tokens are influenced a lot by previous sequences.

![Top-$k$ decoding, $k$ refers to the number of candidates at the first sampling step. (Image source: Wang & Zhou, 2024 )](https://lilianweng.github.io/posts/2025-05-01-thinking/cot-decoding.png)

##### 顺序修订

> Sequential Revision

如果模型能够反思并纠正过去的响应中的错误，我们期望模型能够生成一系列质量不断提高的迭代修订。然而，这种自我纠正能力在LLM中并非固有存在，并且不容易开箱即用，原因在于各种失败模式，例如：(1) 幻觉，包括将正确响应修改为不正确；(2) 行为崩溃为不纠正行为，例如对第一个不正确响应进行微小修改或不修改；或 (3) 在测试时未能泛化到分布偏移。[Huang et al. (2024](https://arxiv.org/abs/2310.01798))的实验表明，天真地应用自我纠正会导致性能下降，模型需要外部反馈才能自我改进，这些反馈可以基于匹配真实值、启发式和任务特定指标、编码问题的单元测试结果（[Shinn, et al. 2023](https://arxiv.org/abs/2303.11366)）、更强的模型（[Zhang et al. 2024](https://arxiv.org/abs/2404.17140)）以及人类反馈（[Liu et al. 2023](https://arxiv.org/abs/2302.02676)）。

> If the model can reflect and correct mistakes in past responses, we would expect the model to produce a nice sequence of iterative revision with increasing quality. However, this self-correction capability turns out to not exist intrinsically among LLMs and does not easily work out of the box, due to various failure modes, such as, (1) hallucination, including modifying correct responses to be incorrect; (2) behavior collapse to non-correcting behavior; e.g. making minor or no modification on the first incorrect responses; or (3) fail to generalize to distribution shift at test time. Experiments by [Huang et al. (2024](https://arxiv.org/abs/2310.01798)) showed that naively applying self-correction leads to worse performance and external feedback is needed for models to self improve, which can be based on matching ground truths, heuristics and task-specific metrics, unit tests results for coding questions ([Shinn, et al. 2023](https://arxiv.org/abs/2303.11366)), a stronger model ([Zhang et al. 2024](https://arxiv.org/abs/2404.17140)), as well as human feedback ([Liu et al. 2023](https://arxiv.org/abs/2302.02676)).

自我纠正学习（[Welleck et al. 2023](https://arxiv.org/abs/2211.00053)）旨在训练一个纠正器模型$P_\theta(y \mid y_0, x)$给定一个固定的生成器模型$P_0(y_0 \mid x)$。虽然生成器模型保持通用性，但纠正器模型可以是任务特定的，并且仅在初始模型响应和额外反馈（例如，一个句子、一个编译器跟踪、单元测试结果；可以是可选的）的条件下进行生成：

> Self-correction learning ([Welleck et al. 2023](https://arxiv.org/abs/2211.00053)) aims to train a corrector model $P_\theta(y \mid y_0, x)$ given a fixed generator model $P_0(y_0 \mid x)$. While the generator model remains to be generic, the corrector model can task-specific and only does generation conditioned on an initial model response and additional feedback (e.g. a sentence, a compiler trace, unit test results; can be optional):

1\. 自我纠正学习首先在数据池中为每个提示生成多个输出；

2\. 然后，如果两个输出中一个比另一个具有更高的价值，则将同一提示的两个输出配对在一起，创建价值改进对（提示$x$，假设$y$，纠正$y’$）。

3\. 这些对是根据其价值改进程度，$v(y’) - v(y)$，以及两个输出之间的相似性，$\text{Similarity}(y, y’)$，按比例选择的，用于训练纠正器模型。

4\. 为了鼓励探索，纠正器也会将新的生成结果提供到数据池中。在推理时，纠正器可以迭代使用，以创建顺序修订的纠正轨迹。

英文原文：

1\. Self-correction learning first generates first generates multiple outputs per prompt in the data pool;

2\. then create value-improving pairs by pairing two outputs for the same prompt together if one has a higher value than the other, (prompt $x$, hypothesis $y$, correction $y’$).

3\. These pairs are selected proportional to is improvement in value, $v(y’) - v(y)$, and similarity between two outputs, $\text{Similarity}(y, y’)$ to train the corrector model.

4\. To encourage exploration, the corrector provides new generations into the data pool as well. At the inference time, the corrector can be used iteratively to create a correction trajectory of sequential revision.

![Illustration of self-correction learning by matching model outputs for the same problem to form value-improving pairs to train a correction model. (Image source: Welleck et al. 2023)](https://lilianweng.github.io/posts/2025-05-01-thinking/self-correction-welleck23.png)

递归检查（[Qu et al. 2024](https://arxiv.org/abs/2407.18219)）也旨在训练一个更好的纠正器模型，但使用单个模型来完成生成和自我纠正。

> Recursive inspection ([Qu et al. 2024](https://arxiv.org/abs/2407.18219)) also aims to train a better corrector model but with a single model to do both generation and self-correction.

SCoRe（通过强化学习进行自我纠正；[Kumar et al. 2024](https://arxiv.org/abs/2409.12917)）是一种多轮RL方法，旨在通过在第二次尝试中产生比第一次尝试更好的答案来鼓励模型进行自我纠正。它包含两个训练阶段：阶段1仅最大化第二次尝试的准确性，同时仅对第一次尝试施加KL惩罚，以避免第一次响应与基础模型行为发生过多偏移；阶段2优化第一次和第二次尝试产生的答案的准确性。理想情况下，我们确实希望看到第一次和第二次尝试的性能都更好，但添加阶段1可以防止模型对第一次响应进行微小或不进行编辑的行为崩溃，而阶段2则进一步改善了结果。

> SCoRe (Self-Correction via Reinforcement Learning; [Kumar et al. 2024](https://arxiv.org/abs/2409.12917)) is a multi-turn RL approach to encourage the model to do self-correction by producing better answers at the second attempt than the one created at the first attempt. It composes two stages of training: stage 1 only maximizes the accuracy of the second attempt while enforcing a KL penalty only on the first attempt to avoid too much shifting of the first-turn responses from the base model behavior; stage 2 optimizes the accuracy of answers produced by both the first and second attempts. Ideally we do want to see performance at both first and second attempts to be better, but adding stage 1 prevents the behavior collapse where the model does minor or none edits on the first response, and stage 2 further improves the results.

![Explicit training setup to improve self-correction capabilities by doing two-staged RL training. (Image source: Kumar et al. 2024)](https://lilianweng.github.io/posts/2025-05-01-thinking/SCoRe-kumar24.png)

#### 用于更好推理的强化学习

> RL for Better Reasoning

最近在利用强化学习改进语言模型推理能力方面取得了许多成功，方法是使用一组带有真实答案的问题（通常是易于验证答案的STEM问题和谜题），并奖励模型获得正确答案。该领域的最新活动受到OpenAI的`o`-系列模型的强大性能以及[DeepSeek](https://www.deepseek.com/)随后发布的模型和技术报告的推动。

> There’s been a lot of recent success in using RL to improve the reasoning ability of language models, by using a collection of questions with ground truth answers (usually STEM problems and puzzles with easy to verify answers), and rewarding the model for getting the correct answer.Recent activity in this area was spurred by strong performance of the `o`-series models from OpenAI, and the subsequent releases of models and tech reports from [DeepSeek](https://www.deepseek.com/).

`DeepSeek-R1`（[DeepSeek-AI, 2025](https://arxiv.org/abs/2501.12948)）是一个开源LLM，旨在擅长需要高级推理技能的任务，如数学、编码和逻辑问题解决。他们进行了两轮SFT-RL训练，使R1在推理和非推理任务上都表现出色。

> `DeepSeek-R1` ([DeepSeek-AI, 2025](https://arxiv.org/abs/2501.12948)) is an open-source LLM designed to excel in tasks that require advanced reasoning skills like math, coding and logical problem solving. They run through 2 rounds of SFT-RL training, enabling R1 to be good at both reasoning and non-reasoning tasks.

1. **冷启动SFT**旨在对`DeepSeek-V3-Base`基础模型进行微调，使用数千个冷启动数据集合。如果没有这一步，模型会出现可读性差和语言混合的问题。
2. **面向推理的RL**使用仅推理提示训练推理模型，并采用两种基于规则的奖励：格式奖励：模型应使用`<thinking> ... </thinking>`token封装CoT。准确性奖励：最终答案是否正确。数学问题的答案需要以特定格式（例如，在一个框中）呈现才能可靠地验证。对于编码问题，使用编译器评估测试用例是否通过。
   - 格式奖励：模型应使用`<thinking> ... </thinking>`token封装CoT。
   - 准确性奖励：最终答案是否正确。数学问题的答案需要以特定格式（例如，在一个框中）呈现才能可靠地验证。对于编码问题，使用编译器评估测试用例是否通过。
3. **拒绝采样 + 非推理SFT**利用在步骤2的RL检查点上通过拒绝采样创建的新SFT数据，结合来自`DeepSeek-V3`的非推理监督数据（在写作、事实问答和自我认知等领域），重新训练`DeepSeek-V3-Base`。过滤掉包含混合语言、长段落和代码块的CoT。使用DeepSeek-V3（[DeepSeek-AI, 2024](https://arxiv.org/abs/2412.19437v1)）管道包含非推理任务。对于某些非推理任务，通过提示调用DeepSeek-V3在回答问题之前生成潜在的CoT。但对于像“hello”这样更简单的查询，不需要CoT。然后对DeepSeek-V3-Base进行微调，使用总共80万个样本进行2个epoch的训练。
   - 过滤掉包含混合语言、长段落和代码块的CoT。
   - 使用DeepSeek-V3（[DeepSeek-AI, 2024](https://arxiv.org/abs/2412.19437v1)）管道包含非推理任务。
   - 对于某些非推理任务，通过提示调用DeepSeek-V3在回答问题之前生成潜在的CoT。但对于像“hello”这样更简单的查询，不需要CoT。
   - 然后对DeepSeek-V3-Base进行微调，使用总共80万个样本进行2个epoch的训练。
4. 最终的**RL**阶段在推理和非推理提示上训练步骤3的检查点，从而提高有用性、无害性和推理能力。

> • **Cold-start SFT** is to fine-tune the `DeepSeek-V3-Base` base model on a collection of thousands of cold-start data. Without this step, the model has issues of poor readability and language mixing.

> • **Reasoning-oriented RL** trains a reasoning model on reasoning-only prompts with two types of rule-based rewards:
>
> Format rewards: The model should wrap CoTs by `<thinking> ... </thinking>` tokens.
> Accuracy rewards: Whether the final answers are correct. The answer for math problems needs to be present in a specific format (e.g. in a box) to be verified reliably. For coding problems, a compiler is used to evaluate whether test cases pass.
>

> ◦ Format rewards: The model should wrap CoTs by `<thinking> ... </thinking>` tokens.

> ◦ Accuracy rewards: Whether the final answers are correct. The answer for math problems needs to be present in a specific format (e.g. in a box) to be verified reliably. For coding problems, a compiler is used to evaluate whether test cases pass.

> • **Rejection-sampling + non-reasoning SFT** utilizes new SFT data created by rejection sampling on the RL checkpoint of step 2, combined with non-reasoning supervised data from `DeepSeek-V3` in domains like writing, factual QA, and self-cognition, to retrain `DeepSeek-V3-Base`.
>
> Filter out CoTs with mixed languages, long paragraphs, and code blocks.
> Include non-reasoning tasks using DeepSeek-V3 ([DeepSeek-AI, 2024](https://arxiv.org/abs/2412.19437v1)) pipeline.
> For certain non-reasoning tasks, call DeepSeek-V3 to generate potential CoTs before answering the question by prompting. But for simpler queries like “hello”, CoT is not needed.
> Then fine-tune the DeepSeek-V3-Base on the total 800k samples for 2 epochs.
>

> ◦ Filter out CoTs with mixed languages, long paragraphs, and code blocks.

> ◦ Include non-reasoning tasks using DeepSeek-V3 ([DeepSeek-AI, 2024](https://arxiv.org/abs/2412.19437v1)) pipeline.

> ◦ For certain non-reasoning tasks, call DeepSeek-V3 to generate potential CoTs before answering the question by prompting. But for simpler queries like “hello”, CoT is not needed.

> ◦ Then fine-tune the DeepSeek-V3-Base on the total 800k samples for 2 epochs.

> • The final **RL** stage trains the step 3 checkpoint on both reasoning and non-reasoning prompts, improving helpfulness, harmlessness and reasoning.

![DeepSeek-R1 performs comparable to OpenAI o1-preview and o1-mini on several widely used reasoning benchmarks. DeepSeek-V3 is the only non-reasoning model listed. (Image source: DeepSeek-AI, 2025)](https://lilianweng.github.io/posts/2025-05-01-thinking/R1-eval.png)

有趣的是，DeepSeek团队展示了，即使是纯粹的RL，没有SFT阶段，仍然可以学习到高级推理能力，如反思和回溯（“顿悟时刻”）。模型在RL训练过程中自然地学会花费更多的思考token来解决推理任务。“顿悟时刻”可以出现，指的是模型反思之前的错误，然后尝试替代方法来纠正它们。后来，出现了各种开源工作来复现R1的结果，例如[Open-R1](https://github.com/huggingface/open-r1), [SimpleRL-reason](https://github.com/hkust-nlp/simpleRL-reason), and [TinyZero](https://github.com/Jiayi-Pan/TinyZero)，所有这些都基于[Qwen](https://github.com/QwenLM/Qwen2.5)模型。这些努力也证实了纯RL在数学问题上带来了出色的性能，以及涌现的“顿悟时刻”。

> Interestingly the DeepSeek team showed that with pure RL, no SFT stage, it is still possible to learn advanced reasoning capabilities like reflection and backtracking (“Aha moment”). The model naturally learns to spend more thinking tokens during the RL training process to solve reasoning tasks. The “aha moment” can emerge, referring to the model reflecting on previous mistakes and then trying alternative approaches to correct them. Later, various open source efforts happened for replicating R1 results like [Open-R1](https://github.com/huggingface/open-r1), [SimpleRL-reason](https://github.com/hkust-nlp/simpleRL-reason), and [TinyZero](https://github.com/Jiayi-Pan/TinyZero), all based on [Qwen](https://github.com/QwenLM/Qwen2.5) models. These efforts also confirmed that pure RL leads to great performance on math problems, as well as the emergent “aha moment”.

![Examples of the model learning to reflect and correct mistakes. (Image source: (left) DeepSeek-AI, 2025; (right) Zeng et al. 2025)](https://lilianweng.github.io/posts/2025-05-01-thinking/aha-moment.png)

DeepSeek团队还分享了一些他们不成功的尝试。他们未能使用过程奖励模型（PRM），因为很难定义每一步的评分标准或确定中间步骤是否正确，同时这使得训练更容易受到奖励作弊的影响。蒙特卡洛树搜索（MCTS）的尝试也失败了，原因在于语言模型token的搜索空间巨大，与例如国际象棋相比；而且训练用于指导搜索的细粒度价值模型也非常具有挑战性。失败的尝试通常能提供独特的见解，我们鼓励研究社区更多地分享那些没有成功的方法。

> The DeepSeek team also shared some of their unsuccessful attempts. They failed to use process reward model (PRM) as it is hard to define per-step rubrics or determine whether an intermediate step is correct, meanwhile making the training more vulnerable to reward hacking. The efforts on MCTS (Monte Carlo Tree Search) also failed due to the large search space for language model tokens, in comparison to, say, chess; and training the fine-grained value model used for guiding the search is very challenging too. Failed attempts often provide unique insights and we would like to encourage the research community to share more about what did not work out.

#### 外部工具使用

> External Tool Use

在推理步骤中，某些中间步骤可以通过执行代码或运行数学计算来可靠且准确地解决。将推理组件的该部分卸载到外部代码解释器中，如PAL（程序辅助语言模型；[Gao et al. 2022](https://arxiv.org/abs/2211.10435)）或代码链（[Li et al. 2023](https://chain-of-code.github.io/)）中所示，可以扩展LLM与外部工具的能力，消除了LLM自身学习执行代码或充当计算器的需要。这些代码模拟器，如代码链中的，可以由LLM增强，这样如果标准代码解释器失败，我们就可以选择使用LLM来执行该行代码。使用代码增强推理步骤对于数学问题、符号推理和算法任务特别有益。这些单元测试可能不作为编码问题的一部分存在，在这种情况下，我们可以指示模型自行生成单元测试，以便进行测试以验证解决方案（[Shinn, et al. 2023](https://arxiv.org/abs/2303.11366)）。

> During the reasoning steps, certain intermediate steps can be reliably and accurately solved by executing code or running mathematical calculations. Offloading that part of reasoning components into an external code interpreter, as in PAL (Program-Aided Language Model; [Gao et al. 2022](https://arxiv.org/abs/2211.10435)) or Chain of Code ([Li et al. 2023](https://chain-of-code.github.io/)), can extend the capability of LLM with external tools, eliminating the need for LLMs to learn to execute code or function as calculators themselves. These code emulators, like in Chain of Code, can be augmented by an LLM such that if a standard code interpreter fails, we have the option of using LLM to execute that line of code instead. Using code to enhance reasoning steps are especially beneficial for mathematical problems, symbolic reasoning and algorithmic tasks. These unit tests may not exist as part of the coding questions, and in those cases, we can instruct the model to self-generate unit tests for it to test against to verify the solution ([Shinn, et al. 2023](https://arxiv.org/abs/2303.11366)).

![An example of program-aided language model prompting looks like. (Image source: Gao et al. 2022)](https://lilianweng.github.io/posts/2025-05-01-thinking/pal.png)

ReAct（推理+行动；[Yao et al. 2023](https://arxiv.org/abs/2210.03629)）结合了搜索维基百科API的行动和推理轨迹的生成，使得推理路径可以整合外部知识。

> ReAct (Reason+Act; [Yao et al. 2023](https://arxiv.org/abs/2210.03629)) combines the action of searching the Wikipedia API and generation of reasoning traces, such that reasoning paths can incorporate external knowledge.

![An example of the ReAct prompting method to solve a HotpotQA question, using Wikipedia search API as an external tool to help with reasoning. (Image source: Yao et al. 2023)](https://lilianweng.github.io/posts/2025-05-01-thinking/react.png)

[o3 & o4-mini](https://openai.com/index/introducing-o3-and-o4-mini/)是OpenAI最近发布的另外两个很好的例子，其中推理过程涉及工具使用，如网络搜索、代码执行和图像处理。该团队观察到，大规模强化学习表现出与GPT范式相同的趋势，即“更多计算 = 更好性能”。

> [o3 & o4-mini](https://openai.com/index/introducing-o3-and-o4-mini/), recently released by OpenAI, are another two good examples where the reasoning process involves tool use like Web search, code execution and image processing. The team observed that large-scale reinforcement learning exhibits the same trend as in the GPT paradigm that “more compute = better performance”.

#### 忠实地思考

> Thinking Faithfully

深度学习模型通常被视为黑箱，并且已经提出了各种可解释性方法。可解释性有几个用处：首先，它为我们提供了一个额外的测试，以确定模型是否与其创建者的意图不符，或者是否以我们无法通过监控其行为来判断的方式出现异常。其次，它可以帮助我们确定模型是否正在使用合理的过程来计算其答案。思维链提供了一种特别方便的可解释性形式，因为它以自然语言使模型的内部过程可见。然而，这种可解释性建立在模型忠实地描述其内部思维过程的假设之上。

> Deep learning models are often treated as black boxes and various interpretability methods have been proposed. Interpretability is useful for a couple reasons: first, it gives us an extra test to determine if the model is misaligned with its creators’ intent, or if it’s misbehaving in some way that we can’t tell by monitoring its actions. Second, it can help us determine whether the model is using a sound process to compute its answers. Chain of thought provides an especially convenient form of interpretability, as it makes the model’s internal process visible in natural language. This interpretability, however, rests on the assumption that the model truthfully describes its internal thought processes.

最近的工作表明，监控推理模型的CoT可以有效检测模型的不当行为，例如[reward hacking](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/)，甚至可以使一个较弱的模型监控一个较强的模型（[Baker et al. 2025](https://arxiv.org/abs/2503.11926)）。增加测试时计算还可以提高对抗鲁棒性（[Zaremba et al. 2025](https://arxiv.org/abs/2501.18841)）；这在直觉上是合理的，因为当模型遇到不寻常的输入（例如对抗性示例或越狱尝试）时，更长时间的思考应该特别有用——它可以利用额外的思考时间来理解它所面临的奇怪情况。

> Recent work showed that monitoring CoT of reasoning models can effectively detect model misbehavior such as [reward hacking](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/), and can even enable a weaker model to monitor a stronger model ([Baker et al. 2025](https://arxiv.org/abs/2503.11926)). Increasing test time compute can also lead to improved adversarial robustness ([Zaremba et al. 2025](https://arxiv.org/abs/2501.18841)); this makes sense intuitively, because thinking for longer should be especially useful when the model is presented with an unusual input, such as an adversarial example or jailbreak attempt – it can use the extra thinking time to make sense of the strange situation it’s been presented with.

![The experiment of asking the model to decide if another model tried to hack the unit tests in some way for coding questions given its thought process. We can monitor these reward hacking behavior during training with different types of monitor. The exit(0) coding hack is when the agent exploited a bug that allowed it to exit from the environment early without running all unit tests. The raise SkipTest hack is when the agent raises an exception from functions outside the testing framework in order to skip unit test evaluation. (Image source: Baker et al. 2025)](https://lilianweng.github.io/posts/2025-05-01-thinking/cot-monitor.png)

##### 模型是否忠实地表达其思考过程

> Does the Model Tell What it Thinks Faithfully

直观上，模型CoT可能由于缺乏旨在鼓励忠实推理的明确训练目标而存在偏差。或者当我们用人类编写的解释来微调模型时，这些人类编写的样本可能包含错误。因此，我们不能默认CoT总是忠实的。

> Intuitively, model CoTs could be biased due to lack of explicit training objectives aimed at encouraging faithful reasoning. Or when we fine-tune the model on human-written explanations, those human-written samples may contain mistakes. Thus we cannot by default assume CoT is always faithful .

[Lanham et al. (2023)](https://arxiv.org/abs/2307.13702)通过故意在CoT中引入错误并测量其对一组多项选择任务（例如AQuA、MMLU、ARC Challenge、TruthfulQA、HellaSwag）准确性的影响，调查了CoT忠实性失败的几种模式：

> [Lanham et al. (2023)](https://arxiv.org/abs/2307.13702) investigated several modes of CoT faithfulness failures by deliberately introducing mistakes into CoTs and measuring their impacts on the accuracy of a set of multiple choice tasks (e.g. AQuA, MMLU, ARC Challenge, TruthfulQA, HellaSwag):

- 错误1（*过早回答*）：模型可能在CoT生成之前过早地形成结论。这通过提前截断或在CoT中插入错误来测试。不同的任务揭示了CoT有效性对任务特定的不同依赖性；有些任务的评估性能对截断的CoT敏感，但有些则不敏感。[Wang et al. (2023)](https://arxiv.org/abs/2212.10001)进行了类似的实验，但错误更微妙，与CoT形成中的桥接对象或语言模板有关。
- 错误2（*无信息token*）：无信息的CoT token会提高性能。通过用填充文本（例如，所有句号）替换CoT来测试这一假设，这种设置显示准确性没有提高，并且与没有CoT相比，某些任务的性能可能会略有下降。
- 错误3（*人类不可读编码*）：相关信息以人类难以理解的方式编码。以非标准方式转述CoT并未降低跨数据集的性能，这表明准确性提升不依赖于人类可读的推理。

> • 
> Mistake 1 (*Early answering*): The model may form a conclusion prematurely before CoT is generated. This is tested by early truncating or inserting mistakes into CoT. Different tasks revealed varying task-specific dependencies on CoT effectiveness; some have evaluation performance sensitive to truncated CoT but some do not. [Wang et al. (2023)](https://arxiv.org/abs/2212.10001) did similar experiments but with more subtle mistakes related to bridging objects or language templates in the formation of CoT.
> • 
> Mistake 2 (*Uninformative tokens*): Uninformative CoT tokens improve performance. This hypothesis is tested by replacing CoT with filler text (e.g. all periods) and this setup shows no accuracy increase and some tasks may suffer performance drop slightly when compared to no CoT.
> • 
> Mistake 3 (*Human-unreadable encoding*): Relevant information is encoded in a way that is hard for humans to understand. Paraphrasing CoTs in an non-standard way did not degrade performance across datasets, suggesting accuracy gains do not rely on human-readable reasoning.

![Illustration of different ways of CoT perturbation to assess its faithfulness. (Image source: Lanham et al. 2023)](https://lilianweng.github.io/posts/2025-05-01-thinking/cot-perturb.png)

有趣的是，Lanham等人提出，对于多项选择题，较小的模型可能无法很好地利用CoT，而较大的模型可能在没有CoT的情况下也能解决这些任务。这种对CoT推理的依赖性（通过有CoT和无CoT获得相同答案的百分比来衡量）在多项选择题上并不总是随模型大小而增加，但在加法任务上确实随模型大小而增加，这意味着思考时间对于复杂的推理任务更为重要。

> Interestingly, Lanham et al. suggests that for multiple choice questions, smaller models may not be capable enough of utilizing CoT well, whereas larger models may have been able to solve the tasks without CoT. This dependency on CoT reasoning, measured by the percent of obtaining the same answer with vs without CoT, does not always increase with model size on multiple choice questions, but does increase with model size on addition tasks, implying that thinking time matters more for complex reasoning tasks.

![The dependency on CoT reasoning is measured as the percentage of obtaining same answers with vs without CoT. It matters more for reasoning tasks like addition and larger models benefit more. (Image source: Lanham et al. 2023)](https://lilianweng.github.io/posts/2025-05-01-thinking/cot-ablation.png)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Computation at test time | 测试时计算 | 在模型推理阶段，允许模型执行额外的计算以提高性能。 |
| Chain-of-Thought (CoT) | 思维链 | 一种提示策略，引导大型语言模型生成中间推理步骤，从而解决复杂问题。 |
| Dual Process Theory | 双过程理论 | 心理学理论，将人类思维分为快速、直觉的系统1和慢速、深思熟虑的系统2。 |
| Latent Variable Modeling | 潜在变量建模 | 机器学习中一种方法，通过引入不可观测的隐藏变量来丰富模型对可见数据的分布表达。 |
| Transformer model | Transformer模型 | 一种基于自注意力机制的神经网络架构，广泛应用于自然语言处理任务。 |
| Mixture of Experts (MoE) | 专家混合模型 | 一种稀疏模型架构，其中不同的“专家”网络处理输入的不同部分，以提高效率和容量。 |
| Supervised Learning | 监督学习 | 一种机器学习范式，模型从带有标签的训练数据中学习输入到输出的映射。 |
| Reinforcement Learning (RL) | 强化学习 | 一种机器学习范式，智能体通过与环境交互，根据奖励信号学习如何做出决策以最大化累积奖励。 |
| Parallel Sampling | 并行采样 | 一种解码策略，同时生成多个输出候选，并通过评分函数选择最佳结果。 |
| Sequential Revision | 顺序修订 | 一种解码策略，模型根据上一步的输出迭代地调整和纠正其响应。 |
| Beam Search | 束搜索 | 一种启发式搜索算法，通过在每一步保留最有前景的K个路径来探索搜索空间，常用于序列生成。 |
| Self-consistency | 自洽性 | 一种CoT推理方法，通过对多个推理路径进行多数投票来选择最终答案，以提高鲁棒性。 |
| Process Reward Model (PRM) | 过程奖励模型 | 一种模型，用于评估生成序列中每个中间步骤的质量，以指导搜索或训练。 |
| Reward Hacking | 奖励作弊 | 强化学习中，智能体找到一种方法来最大化奖励，但其行为并非设计者所期望的。 |
| Adversarial Robustness | 对抗鲁棒性 | 模型在面对经过精心设计的对抗性输入时，仍能保持其性能和准确性的能力。 |
