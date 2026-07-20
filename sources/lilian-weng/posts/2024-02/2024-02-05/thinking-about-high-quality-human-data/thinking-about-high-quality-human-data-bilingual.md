# 思考高质量的人工数据

> Thinking about High-Quality Human Data

> 来源：Lil'Log / Lilian Weng，2024-02-05
> 原文链接：https://lilianweng.github.io/posts/2024-02-05-human-data-quality/
> 分类：机器学习 / 数据质量

## 核心要点

- 高质量的人工标注数据是现代深度学习模型训练的关键燃料，尤其对于分类和LLM对齐等任务。
- 人工数据收集涉及任务设计、评估者选择与培训以及数据聚合等多个环节，每个环节都影响数据质量。
- “群体的智慧”概念通过众包方式被应用于数据标注，早期研究表明非专家评估者在适当加权下也能提供高质量标注。
- 评估者一致性是衡量标注质量的重要指标，常见聚合方法包括多数投票、原始一致性、Cohen's Kappa和概率图模型（如MACE）。
- 在主观任务中，评估者分歧并非总是负面，它可能反映了观点的多样性，需要区分随机错误与系统性差异。
- 处理评估者分歧的范式包括描述性范式（理解不同观点）和通过多标注者模型、陪审团学习等方法显式建模标注者行为。
- 在模型训练阶段，可以通过影响函数、训练期间的预测变化（如数据图、遗忘事件、AUM）和噪声交叉验证等技术识别和排除错误标签。
- 影响函数通过衡量单个训练点对模型参数和损失的影响来近似识别错误标记数据。
- 数据图、遗忘事件和AUM等方法通过分析模型在训练过程中对样本的置信度、变异性或裕度变化来发现难以学习或错误标记的样本。
- 噪声交叉验证通过将数据集分成两半并相互验证标签，以识别更可信的“干净”样本。

## 正文

[特别感谢[Ian Kivlichan](https://scholar.google.com/citations?user=FRBObOwAAAAJ&hl=en)提供了许多有用的指导（例如，100多年前的《自然》杂志论文“Vox populi”）和宝贵的反馈。🙏 ]  


> [Special thank you to [Ian Kivlichan](https://scholar.google.com/citations?user=FRBObOwAAAAJ&hl=en) for many useful pointers (E.g. the 100+ year old Nature paper “Vox populi”) and nice feedback. 🙏 ]  

高质量数据是现代数据深度学习模型训练的燃料。大多数特定任务的标注数据来自人工标注，例如分类任务或用于LLM对齐训练的[RLHF](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences)标注（可以构建为分类格式）。本文中的许多机器学习技术可以帮助提高数据质量，但从根本上说，人工数据收集需要关注细节和仔细执行。社区深知高质量数据的价值，但不知何故，我们总有一种微妙的印象，即“每个人都想做模型工作，而不是数据工作”（[Sambasivan et al. 2021](https://dl.acm.org/doi/abs/10.1145/3411764.3445518)）。

> High-quality data is the fuel for modern data deep learning model training. Most of the task-specific labeled data comes from human annotation, such as classification task or [RLHF](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences) labeling (which can be constructed as classification format) for LLM alignment training. Lots of ML techniques in the post can help with data quality, but fundamentally human data collection involves attention to details and careful execution. The community knows the value of high quality data, but somehow we have this subtle impression that “Everyone wants to do the model work, not the data work” ([Sambasivan et al. 2021](https://dl.acm.org/doi/abs/10.1145/3411764.3445518)).

![Two directions to approach high data quality.](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/overview.png)

### 人工评估者 ↔ 数据质量

> Human Raters ↔ Data Quality

收集人工数据涉及一系列操作步骤，每个步骤都对数据质量有所贡献：

> Collecting human data involve a set of operation steps and every step contributes to the data quality:

1. 任务设计：设计任务流程以提高清晰度并降低复杂性。详细的指南很有帮助，但非常冗长和复杂的指南需要大量的培训才能发挥作用。
2. 选择和培训评估者：选择具有匹配技能和一致性的标注者。培训课程是必要的。入职后，还需要定期的反馈和校准会议。
3. 收集和聚合数据。在这个阶段，可以应用更多的机器学习技术来清洗、过滤和智能聚合数据，以识别真实标签。

> • Task design: Design task workflow to improve clarity and reduce complexity. Detailed guidelines are helpful but very long and complicated guidelines demand a decent amount of training to be useful.
> • Select and train a pool of raters: Select annotators with matched skillset and consistency. Training sessions are necessary. After onboarding, regular feedback and calibration sessions are also needed.
> • Collect and aggregate data. This is the stage where more ML techniques can be applied to clean, filter and smartly aggregate data to identify the true labels.

![Quality assurance refers to a set of actions that allow one to improve quality by acting on the quality attributes identified in the quality model. (Image source: Daniel et al. 2018 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/qualit_assurance.png)

#### 群体的智慧

> The Wisdom of the Crowd

[Vox populi](https://en.wikipedia.org/wiki/Vox_populi)（原为“Vox populi, vox Dei”），一个拉丁短语，意为“人民的声音”。1907年，《自然》杂志发表了一篇同名短文。它记录了一年一度的展览上发生的一件事：人们挑选了一头肥牛，并猜测其体重，如果猜测接近真实数字，就能赢得奖品。中间值估计被视为“vox populi”，最终非常接近真实值。作者总结道*“我认为，这个结果比预期更能证明民主判断的可靠性。”*这可能是最早提及众包（“群体的智慧”）如何运作的例子。

> [Vox populi](https://en.wikipedia.org/wiki/Vox_populi) (originally “Vox populi, vox Dei”), a Latin phrase, means the voice of people. A short paper named was the same name was published in 1907 on Nature. It tracked an event at an annual exhibition where a fat ox was selected and people would guess the weight of the ox in order to win a prize if the guess is close to the real number. The middlemost estimate was treated as “the vox populi” and ended up being very close to the true value. The author concluded *“This result is, I think, more creditable to the trustworthiness of a democratic judgment than might have been expected.”* This is probably the earliest mention of how crowdsourcing (“the wisdom of the crowd”) would work out.

近100年后，[Callison-Burch (2009)](https://aclanthology.org/D09-1030/)进行了一项早期研究，利用亚马逊土耳其机器人（AMT）对机器翻译（MT）任务进行非专家人工评估，甚至依靠非专家创建新的黄金参考译文。人工评估的设置很简单：每个土耳其机器人用户会看到一个源句子、一个参考译文以及来自5个机器翻译系统的5个译文。他们被要求将这5个译文从最好到最差进行排序。每个任务由5名土耳其机器人用户完成。

> Almost 100 years later, [Callison-Burch (2009)](https://aclanthology.org/D09-1030/) did an early study on using Amazon Mechanical Turk (AMT) to run non-expert human evaluation on Machine Translation (MT) tasks and even to rely on non-experts to create new gold reference translations. The setup for human evaluation was simple: Each turker is shown a source sentence, a reference translation, and 5 translations from 5 MT systems. They are asked to rank 5 translations from best to worst. Each task is completed by 5 turkers.

不出所料，存在一些垃圾信息发布者，他们为了只优化数量而生成低质量的标注。因此，在衡量专家和非专家之间的一致性时，需要应用不同的加权方案来降低垃圾信息发布者的贡献：（1）“专家加权”：使用与专家在10个黄金示例集上的一致率；（2）“非专家加权”：依赖与其余土耳其机器人用户在整个数据集上的一致率。

> Unsurprisingly, there are spammers producing low quality annotation to only optimize the volume. So when measuring the agreement between experts and non-experts, different weighting schemes need to be applied to downweight the contribution of spammers: (1) “weighted by experts”: using agreement rate with experts on a gold set of 10 examples; (2) “weighted by non-experts”: relying on agreement rate with the rest of turkers on the whole dataset.

在一个更困难的任务中，非专家人工标注者被要求创建新的黄金参考译文。Callison-Burch将任务设计为两个阶段，第一阶段根据机器翻译输出创建新译文，第二阶段过滤掉可能由机器翻译系统生成的译文。专家译文与众包译文之间的相关性高于专家译文与机器翻译系统输出之间的相关性。

> In a harder task, non-expert human annotators were asked to create new gold reference translations. Callison-Burch designed the task in two stages, where the first stage created new translations with reference to MT outputs and the second one filtered translations that may seem to be gerated by a MT system. The correlation between experts’ and crowdsourced translations is higher than that between expert and MT system outputs.

![(Left) The agreement rate is measured by comparing each pair of translation sentences ("A > B", "A=B", "A < B") and thus chance agreement is 1/3. The upper bound is set by the expert-expert agreement rate. (Right) Comparison of BLEU score between translations from different sources. LCD (Linguistic Data Consortium) translators provide expert translations. (Image source: Callison-Burch 2009 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/AMT_exp.png)

#### 评估者一致性

> Rater Agreement

我们通常认为标注是针对单一的真实值，并试图以一致的标准对照一个黄金答案来评估质量。寻找可靠真实标签的常见做法是从多个评估者那里收集多个标签。假设每个评估者表现出不同的质量水平，我们可以使用标注的加权平均值，但权重由熟练度分数决定。这个分数通常通过一个评估者与其他人达成一致的频率来近似。

> We often think of annotation as targeting a single ground truth and try to evaluate quality against one gold answer with consistent standards. A common practice for finding reliable ground truth labels is to collect multiple labels from multiple raters. Assuming that each rater performs at a different level of quality, we can use a weighted average of annotations but weighted by a proficiency score. This score is often approximated by how often one rater agrees with others.

**多数投票**：采取多数投票是最简单的聚合方式，相当于取一组标签的[众数](https://en.wikipedia.org/wiki/Mode_(statistics))。在这种设置下，每个标注者都贡献相等。

> **Majority Voting**: Taking the majority vote is the simplest way of aggregation, equivalent to taking the [mode](https://en.wikipedia.org/wiki/Mode_(statistics)) of a set of labels. In this setting, every annotator is contributing equally.

**原始一致性**（[Tratz & Hovy, 2010](https://aclanthology.org/P10-1070/)）：原始一致性计算与其他人达成一致的百分比。这与多数投票间接相关，因为多数类别的所有成员预计会获得更高的人工标注者间一致率。

> **Raw agreement** ([Tratz & Hovy, 2010](https://aclanthology.org/P10-1070/)): Raw agreement counts the percentage of other people agreeing with them. This is indirectly correlated to majority vote, because all members of the majority class are expected to get higher inter-annotator agreement rate.

**Cohen’s Kappa**（[Landis & Koch, 1977](https://www.jstor.org/stable/2529310)）：Cohen’s kappa以$\kappa = (p_o - p_e) / (1 - p_c)$的形式衡量评估者间一致性，其中`p_o`是原始一致率，`p_e`是偶然一致率。Cohen’s kappa有一个针对偶然一致的校正项，但如果某个标签更普遍，这个校正可能会被高估。

英文原文：Cohen’s Kappa ([Landis & Koch, 1977](https://www.jstor.org/stable/2529310)): Cohen’s kappa measures the inter-rater agreement in the form of 

$\kappa = (p_o - p_e) / (1 - p_c)$, where `p_o` is the raw agreement rate and `p_e` is the agreement by chance. Cohen’s kappa has a correction term for agreeing by chance, but this correction may be overestimated if one label is more prevalent.

**概率图模型**：有一系列工作依赖于[概率图模型](https://en.wikipedia.org/wiki/Graphical_model)来建模标注决策中的不同因素，例如任务难度、任务潜在主题、评估者偏差、评估者置信度，然后相应地预测真实标签。[Zheng et al. (2017)](https://dl.acm.org/doi/abs/10.14778/3055540.3055547)比较了众包中17种真实值推断算法，其中大多数是概率图模型。

> **Probabilistic Graph Modeling**: There is a body of work relying on [probabilistic graph modeling](https://en.wikipedia.org/wiki/Graphical_model) to model different factors within annotation decisions, e.g. difficulty of the task, task latent topics, rater bias, rater confidence, and then predict the true labels accordingly. [Zheng et al. (2017)](https://dl.acm.org/doi/abs/10.14778/3055540.3055547)  compared 17 algorithms on truth inference in crowdsourcing and most of them are probabilistic graph models.

• **MACE**（多标注者能力估计；[Hovy et al. 2013](https://aclanthology.org/N13-1132)）是使用图模型估计某人通过提供随机标签而表现得像“垃圾信息发布者”的可能性的早期例子。不出所料，在激励机制不匹配的情况下，一些标注者可能会表现得像“垃圾信息发布者”，以优化完成任务的数量来获得更高的报酬。MACE的目标是识别垃圾信息发布者。给定任务$i$和标注者$j$，$T_i$是真实标签，$A_{ij}$是分配的标签，$S_{ij}$建模了标注者$j$发送垃圾信息的概率。那么生成过程可以表示如下。参数$\theta_j$定义了标注者$j$的可靠性（不发送垃圾信息的概率），参数$\xi_j$定义了标注者在发送垃圾信息时的行为方式。

英文原文：

• **MACE** (Multi-Annotator Competence Estimation; [Hovy et al. 2013](https://aclanthology.org/N13-1132)) is an early example of using graph modeling to estimate the likelihood of someone acting like a “spammer” by providing random labels. Unsurprisingly in cases when the incentive is misaligned, some annotators may behave as “spammers” to optimize the volume of tasks completed for higher pay. The goal of MACE is to identify spammers. Given a task $i$ and an annotator $j$, $T_i$ is the true label, $A_{ij}$ is the assigned label and $S_{ij}$ models the probability of annotator $j$ spamming. Then the generative process can be represented as belows. The parameter $\theta_j$ defines the trustworthiness of the annotator $j$ (probability of not spamming) and the parameter $\xi_j$  defines how an annotator behaves when they are spamming.

$$
\begin{align}
& \text{for } i = 1 \dots N : \\
& \quad T_i \sim \text{Uniform} \\
& \quad \text{for } j = 1 \dots M : \\
& \quad \quad S_{ij} \sim \text{Bernoulli}(1 - \theta_j) \\
& \quad \quad \text{if } S_{ij} = 0 : \\
& \quad \quad \quad A_{ij} = T_i \\
& \quad \quad \text{else } : \\
& \quad \quad \quad A_{ij} \sim \text{Multinomial}(\xi_j) \\
\end{align}
$$

然后我们可以学习$\theta, \xi$以最大化观测数据，形式为边际数据似然，其中$A$是标注矩阵，$S$是能力指标矩阵，$T$是真实标签矩阵：

> Then we can learn $\theta, \xi$ to maximize the observed data, in the form of the marginal data likelihood, where $A$ is the matrix of annotations, $S$ is the matrix of competence indicators and $T$ is the matrix of true labels:

$$
P(A; \theta, \xi) = \sum_{T, S} \big[ \prod_{i=1}^N P(T_i) \cdot \prod_{j=1}^M P(S_{ij}; \theta_j) \cdot P(A_{ij} \vert S_{ij}, T_i; \xi_j) \big]
$$

EM（期望最大化）或VB（变分贝叶斯）都可以应用于最大化上述边际似然。在EM优化过程中，M步会在归一化之前将固定值$\delta$添加到分数计数中。在VB训练过程中，他们对$\theta_j$应用对称Beta先验，对$\xi_j$应用对称Dirichlet先验。在恢复正确答案时，我们可以采用由标注者的$\theta$估计值加权的多数投票。

> Either EM (Expectation–maximization) or VB (Variational Bayes) can be applied to maximize the above marginal likelihood. During EM optimization, at M-step, a fixed value $\delta$ is added to the fractional counts before normalizing. During VB training, they applied symmetric Beta priors on $\theta_j$  and symmetric Dirichlet priors on $\xi_j$. When recovering the correct answers, we can take majority vote weighted by the annotators’ $\theta$ estimates.

#### 评估者分歧与两种范式

> Rater Disagreement & Two Paradigms

上述聚合过程依赖于一个假设，即存在*一个*潜在的黄金答案，因此我们可以据此评估标注者的表现。然而，在许多主题中，特别是在安全、社会或文化领域，人们可能会有分歧，而且这种分歧往往是有效的，这时就归结为我们是想应用严格的规则还是拥抱多样性。

> The aggregation process described above depends on an assumption that there exists *one* underlying gold answer and thus we can evaluate annotators’ performance accordingly. However, in many topics, especially in safety, social, or cultural areas, people can disagree and often this disagreement is valid and then it comes down to how much we want to apply a strict rule versus embracing diversity.

[Aroyo & Welty (2015)](https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/2564)讨论了人工标注收集实践中的一系列“迷思”，发现它们都有些不准确，主要发现包括：

> [Aroyo & Welty (2015)](https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/2564) discussed a set of “myths” in the practice of human annotation collection and found all of them somewhat inaccurate, key findings including:

- 对于某些样本，通常存在不止一种正确的解释。我们需要通过例如让多人审查标注质量来获得多样化的视角。
- 分歧并非总是坏事。我们应该减少由错误或设计不佳的流程引起的分歧，但其他分歧可以为我们提供丰富的信息。
   - 如果分歧是由任务定义不明确引起的，我们应该加强指导。然而，更详细的指南并不能解决意见中固有的多样性。
- 专家不一定总是比普通人更好，但在考虑什么重要方面，他们会有很大的差距。
- 真实值标注会随时间变化，特别是那些与时事或新闻相关的标注。

> • Often there is more than one correct interpretation for some samples. We need diverse perspectives via e.g. having multiple people to review annotation quality.

> • Disagreement is not always bad. We should reduce disagreements caused by errors or poorly designed process but other disagreements can give us rich information.
>

> ◦ If it is caused by a task not well defined, we should enhance the instruction. However, a more detailed guideline does not resolve innate diversity among opinions.

> • Experts may not always be better than lay people, but they would have a big gap in terms of considering what’s important.

> • Ground truth annotations can change in time, especially those related to timely events or news.

后来，[Rottger et al. (2021)](https://arxiv.org/abs/2112.07475)将这种差异归纳为两种截然不同的范式，用于主观NLP任务的数据标注。

> Later, [Rottger et al. (2021)](https://arxiv.org/abs/2112.07475) formulated the difference into two contrasting paradigms for data annotation for subjective NLP tasks.

|  | 描述性 | 规定性 |
| --- | --- | --- |
| 定义 | 鼓励标注者主观性，试图建模多种信念。 | 不鼓励标注者主观性，试图一致地应用一种信念。 |
| 优点 | - 有助于识别哪些条目更具主观性；- 拥抱多样性 | - 更符合标准NLP设置。- 通过衡量分歧或进行标签聚合更容易进行质量控制。 |
| 缺点 | - 评估者分歧等指标不能用于衡量数据质量或标注者表现；- 不能用于训练优化以输出一种预设行为的模型。 | - 实践中，创建高质量的标注指南既昂贵又具有挑战性，而且永远无法做到完美；- 培训标注者熟悉指南以便正确应用也具有挑战性；- 无法捕捉可解释的信念多样性或始终如一地编码一种特定信念。 |

> 英文原表 / English original

|  | Descriptive | Prescriptive |
| --- | --- | --- |
| Definition | Encourage annotator subjectivity, trying to model many beliefs. | Discourage annotator subjectivity, trying to consistently apply one belief. |
| Pros | - Can help to identify which entries are more subjective; - Embrace diversity | - More aligned with standard NLP setup. - Easier to do QC by measuring disagreement or doing label aggregation. |
| Cons | - Metrics like rater disagreement cannot be used to measure data quality or annotator performance; - Cannot be used for training models that are optimized for outputting one preset behavior. | - Expensive and challenging to create high-quality annotation guidelines, which can never be perfect, in practice; - Training annotators to get familiar with guideline in order to apply it properly is also challenging; - Cannot capture an interpretable diversity of beliefs or consistently encode one specific belief. |

描述性范式使我们能够理解许多重要影响，并解释不同的观点。例如，标注者的身份（例如非裔美国人、LGBTQ）被发现是他们如何将身份相关内容标记为有毒的一个统计学上显著的因素（[Goyal et al. 2022](https://arxiv.org/abs/2205.00501)）。主题可以是产生不同意见的另一个主要驱动因素。[Wang et al. (2023)](https://research.google/pubs/all-that-agrees-is-not-gold-evaluating-ground-truth-labels-and-dialogue-content-for-safety/) 研究了人工智能对话系统安全的人工评估过程，并比较了信任与安全（T&S）专业人员和众包标注者标签的结果。他们有意收集了与众包标注者相关的丰富元数据，如人口统计或行为信息。比较T&S专家标签和众包标注，他们发现一致性率在语义主题和严重程度方面有所不同：

> The descriptive paradigm allows us to understand a number of important effects as well as to account for different perspectives. For example, annotator identity (e.g. African American, LGBTQ) is found to be a statistically significant factor in how they would label identify-related content as toxic ([Goyal et al. 2022](https://arxiv.org/abs/2205.00501)). Topics can be another main driver for diverse opinions. [Wang et al. (2023)](https://research.google/pubs/all-that-agrees-is-not-gold-evaluating-ground-truth-labels-and-dialogue-content-for-safety/) studied the human evaluation process of safety of an AI conversation system and compared results between labels by Trust & Safety (T&S) professionals and crowdsourcing annotators. They intentionally collected rich metadata associated with crowd annotators like demographic or behavior information. Comparing T&S expert labels and crowd annotations, they found that agreement rates vary across semantic topics and the level of severity:

- 一致性率在不同主题之间差异很大；从暴力/血腥主题的0.96到个人主题的0.25。
- 在“极端”和“良性”对话中，一致性率更高，考虑到有四个标签选项，分别标记为“良性”、“有争议”、“中等”到“极端”。

> • Agreement rate differs a lot across different topics; ranging from 0.96 on violence/gory to 0.25 on personal topics.
> • Agreement rates are higher on “extreme” and “benign” conversations, given four label options marking “benign”, “debatable”, “moderate” to “extreme”.

![Correlations between non-expert and expert annotations vary a lot across topics. (Image source: Wang et al. 2023 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/topic_agreement.png)

[Zhang et al. (2023)](https://arxiv.org/abs/2311.04345) 提出了一种评估者分歧的分类法，以分析其根本原因。在列出的原因中，应避免因随机错误或个体层面不一致造成的分歧。在评估者多次被要求对同一任务给出不同标签的情况下，其中一些很可能是由人为错误造成的。基于这种直觉，分歧解卷积方法（[Gordon et al. 2021](https://dl.acm.org/doi/abs/10.1145/3411764.3445423)）通过将每个个体的意见锚定到他们自己的主要标签，从而鼓励评估者*内部*一致性，将稳定意见与错误区分开来。

> [Zhang et al. (2023)](https://arxiv.org/abs/2311.04345) proposed a taxonomy of rater disagreement to analyze the root causes. Among the listed causes, disagreement due to stochastic errors or inconsistency on the individual level should be avoided. In cases when a rater gives different labels to the same task when asked multiple times, some of those are most likely caused by human errors. Based on this intuition, the disagreement deconvolution method ([Gordon et al. 2021](https://dl.acm.org/doi/abs/10.1145/3411764.3445423)) disentangles stable opinions from errors by anchoring each individual’s opinion to their own primary label and thus encouraging *intra*-rater consistency.

![A taxonomy of causes for rater disagreement. (Image source: Zhang et al. 2023 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/taxonomy.png)

分歧解卷积依赖于概率图建模：

> Disagreement deconvolution relies on probabilistic graph modeling:

1\. 估计标注者返回非主要标签的频率，$p_\text{flip}$

2\. 每个样本，获得主要标签的调整后分布$p^{\ast}$，基于$p_\text{flip}$

3\. 从 $p^{\ast}$ 中抽取样本作为新的测试集。

4\. 针对新的测试集衡量性能指标。

英文原文：

1\. Estimate how often an annotator returns non-primary labels, $p_\text{flip}$

2\. Per sample, get an adjusted label distribution $p^{\ast}$ of primary labels based on $p_\text{flip}$

3\. Sample from $p^{\ast}$ as a new test set.

4\. Measure performance metrics against the new test set.

给定 $C$ 类分类，生成模型的采样过程如下所述：

> Given $C$ -category classification, the sampling process of the generative model is stated as follows:

$$
\begin{aligned}
y^*\mid x &\sim \text{Categorial}([C], p^*(y\mid x)) \\
y_\text{other}\mid y^* &\sim \text{Categorial}([C]\setminus\{y^*\}, \frac{1}{C-1}) \\
z_\text{flip} \mid x &\sim \text{Bernoulli}(p_\text{flip}(x)) \\
y\mid y^*, y_\text{other}, z_\text{flip} &= y^* (1 - z_\text{flip}) + y_\text{other} z_\text{flip}
\end{aligned}
$$

鉴于可以从数据中估计出的真实$p(y\mid x)$和$p_\text{flip}$，我们将更新主要标签的标签分布：

> Given the true $p(y\mid x)$ and $p_\text{flip}$ that can be estimated from the data, we would update the label distribution of primary labels:

$$
p^*(y\mid x) = \frac{p(y\mid x) - \frac{p_\text{flip}(x)}{C-1}}{1 - \frac{C \cdot p_\text{flip}(x)}{C - 1}}
$$

从$p^{\ast}(y \mid x)$中采样的新测试集代表了移除了个体不一致噪声的主要标签。它可以作为无噪声测试集用于评估。

> A new test set sampled from $p^{\ast}(y \mid x)$ represents the primary labels with individual inconsistency noise removed. It can be used for evaluation, as a noise-free test set.

为了在学习预测标签时捕捉标注者之间系统性的分歧，[Davani et al. (2021)](https://arxiv.org/abs/2110.05719) 实验了一种多标注者模型，其中预测每个标注者的标签被视为一个子任务。例如，分类任务定义在一个已标注数据集$D=(X, A, Y)$上，其中$X$是文本实例，$A$是标注者集合，$Y$是标注矩阵，$y_{ij} \in Y$表示由$a_j \in A$分配给样本$x_i \in X$的二元标签。$x_i$的多数投票表示为$\bar{y}_{i,}$。该实验旨在预训练的BERT模型之上训练一个分类头，并比较4种设置：

> To capture systematic disagreement among annotators when learning to predict labels, [Davani et al. (2021)](https://arxiv.org/abs/2110.05719) experimented with a multi-annotator model where predicting each annotator’s labels is treated as one sub-task. Say, the classification task is defined on an annotated dataset $D=(X, A, Y)$, where $X$ is the text instances, $A$ is the set of annotators and $Y$ is the annotation matrix, $y_{ij} \in Y$ represents a binary label assigned by $a_j \in A$ to the sample $x_i \in X$. The majority vote for $x_i$ is denoted as $\bar{y}_{i,}$. The experiment is to train a classification head on top of a pre-trained BERT model and compares 4 setups:

• 基线：直接预测多数投票$\bar{y}_i$，不使用完整的标注矩阵$Y$。

• 集成：为每个标注者单独训练一个模型来预测$y_{ij}$，然后通过多数投票聚合结果。

• 多标签：学习预测$\vert A \vert$标签以表示每个样本$\langle y_{i1}, \dots, y_{i\vert A \vert} \rangle$的所有标注者标签，使用共享的MLP层，然后聚合输出。

• 多任务：类似于多标签，但每个标注者的预测头都是从一个独立的MLP层学习的，这样我们就可以分配额外的计算资源来学习标注者之间的差异。

英文原文：

• Baseline: Directly predict the majority vote $\bar{y}_i$, not using the full annotation matrix $Y$.

• Ensemble: Train one model per annotator separately to predict $y_{ij}$ and then the results are aggregated by majority vote.

• Multi-label: Learn to predict $\vert A \vert$ labels to represent all annotators’ labels per sample $\langle y_{i1}, \dots, y_{i\vert A \vert} \rangle$, with a shared MLP layer and then outputs are aggregated.

• Multi-task: Similar to multi-label, but each annotator’s prediction head is learned from a separated MLP layer, such that we allocate extra compute to learn the difference among annotators.

在[GHC (Gab Hate Corpus)](https://osf.io/edua3/)数据集上的实验结果表明，多任务模型取得了最佳的F1分数，并且能够自然地提供预测不确定性估计，这与标注分歧相关。

> Experiment results on the [GHC (Gab Hate Corpus)](https://osf.io/edua3/) dataset showed that the multi-task model achieves the best F1 score and also can naturally provide prediction uncertainty estimation, correlated with annotation disagreement.

![Illustration of different architectures for modeling multiple annotators' labels. (Image source: Davani et al. 2021 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/multi_annotator_model.png)

陪审团学习（[Gordon et al. 2022](https://arxiv.org/abs/2202.02950)）通过建模不同标注者基于其特征的标注行为来模拟[陪审团过程](https://www.uscourts.gov/services-forms/jury-service/juror-selection-process)。从一个包含标签和每个标注者人口统计学特征的数据集开始，我们训练一个模型来学习预测每个个体标注者（每个个体都是潜在的陪审员）所做的标签。在决策时，实践者可以指定一组陪审员的组成来确定采样策略。最终决定是通过聚合来自多次试验的陪审员的标签来做出的。

> Jury Learning ([Gordon et al. 2022](https://arxiv.org/abs/2202.02950)) mimics the [jury process](https://www.uscourts.gov/services-forms/jury-service/juror-selection-process) by modeling the different annotators’ labeling behavior conditioned on their characteristics. Starting with a dataset with labels and demographic characteristics of each labeler, we train a model to learn to predict labels made by every individual annotator, each as a potential juror. At decision time, practitioners can specify the composition of a group of jurors to determine a sampling strategy. The final decision is made by aggregating labels from jurors from multiple trials.

![Illustration of how jury learning works. (Image source: Gordon et al. 2022 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/jury.png)

陪审团学习模型是一个[DCN (Deep & Cross network)](https://arxiv.org/abs/2008.13535)，通常用于推荐用例，它被联合训练以学习评论嵌入、标注者嵌入和组（标注者特征）嵌入。文本内容由预训练的BERT处理，该BERT也进行联合微调，但时间较短以避免过拟合。

> The jury learning model is a [DCN (Deep & Cross network)](https://arxiv.org/abs/2008.13535) , commonly for recommendation use case,  that is jointly trained to learn comment embedding, annotator embedding and group (annotator’s characteristics) embedding. The text content is processed by a pre-trained BERT, which is also jointly fine-tuned but for a shorter period to avoid overfitting.

![DCN model architecture for jury learning. (Image source: Gordon et al. 2022 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/jury_model.png)

他们的实验在[毒性多样性数据集](https://data.esrg.stanford.edu/study/toxicity-perspectives)上运行，并将陪审团学习与一个基线模型进行比较，该基线模型是一个经过微调的BERT，用于在不使用元数据的情况下预测单个标注者的标签。性能以MAE（平均绝对误差）衡量。陪审团学习在完整测试集以及每个组段上始终优于与标注者无关的基线。

> Their experiment runs on the [toxicity diversity dataset](https://data.esrg.stanford.edu/study/toxicity-perspectives) and compares jury learning with a baseline model which is a fine-tuned BERT to predict individual annotator’s label without using metadata. Performance is measured in MAE (mean absolute error). Jury learning consistently outperforms the annotator-agnostic baseline on the full test set as well as each group segment.

![Experiment results comparing an annotator-agnostic baseline with jury learning. (Image source: Gordon et al. 2022 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/jury_exp.png)

### 数据质量 ↔ 模型训练

> Data Quality ↔ Model Training

一旦数据集构建完成，许多方法可以根据训练动态帮助识别错误标签。请注意，我们只关注查找和排除可能带有不正确标签的数据点的方法，而不是关于[如何用噪声数据训练模型](https://lilianweng.github.io/posts/2022-04-15-data-gen/#training-with-noisy-data)。

> Once a dataset is constructed, many methods can help identify mislabels according to the training dynamics. Note that we only focus on methods to find and exclude data points with potentially incorrect labels, not about [how to train a model with noisy data](https://lilianweng.github.io/posts/2022-04-15-data-gen/#training-with-noisy-data).

#### 影响函数

> Influence Functions

**影响函数**是稳健统计学（[Hampel, 1974](https://www.jstor.org/stable/2285666)）中的一种经典技术，通过描述当我们以无穷小的量增加一个训练点的权重时模型参数如何变化来衡量训练数据点的影响。[Koh & Liang (2017)](https://arxiv.org/abs/1703.04730)将这一概念引入到深度神经网络中。

> **Influence functions** is a classic technique from robust statistics ([Hampel, 1974](https://www.jstor.org/stable/2285666)) to measure the effect of training data points by describing how the model parameters change as we upweight a training point by an infinitesimal amount. [Koh & Liang (2017)](https://arxiv.org/abs/1703.04730) introduced the concept to be applied to deep neural networks.

给定$n$个训练集中的数据样本，$z_i = (x_i, y_i)$对于$i =1, \dots, n$，模型参数$\theta$被优化以最小化损失函数：$\hat{\theta} = \arg\min_{\theta \in \Theta} \frac{1}{n}\sum_{i=1}^n \mathcal{L}(z_i, \theta)$。当我们移除单个数据点后，模型参数的变化$z$表示为$\hat{\theta}_{-z} - \hat{\theta}$其中$\hat{\theta}_{-z} = \arg\min_{\theta \in \Theta} \frac{1}{n} \sum_{z_i \neq z} \mathcal{L}(z_i, \theta)$。然而，对每个样本都进行字面计算过于昂贵。一种近似方法是计算在给定少量上调权重的情况下参数的变化$\epsilon$施加于$z$。根据定义，上调权重的影响$z$通过$\epsilon$给出：

> Given $n$ data samples in the train set, $z_i = (x_i, y_i)$ for $i =1, \dots, n$, The model parameter $\theta$ is optimized to minimize a loss: $\hat{\theta} = \arg\min_{\theta \in \Theta} \frac{1}{n}\sum_{i=1}^n \mathcal{L}(z_i, \theta)$. The change of model parameters after we remove a single data point $z$ is denoted as $\hat{\theta}_{-z} - \hat{\theta}$ where $\hat{\theta}_{-z} = \arg\min_{\theta \in \Theta} \frac{1}{n} \sum_{z_i \neq z} \mathcal{L}(z_i, \theta)$. However, computing this literally for every sample is too expensive. One way to approximate this is to compute the parameter change given a small upweight $\epsilon$ on $z$. By definition, the influence of upweighting $z$ by $\epsilon$ is given by:

$$
\mathcal{I}_{\text{up,params}}(z) = \frac{d\hat{\theta}_{\epsilon,z}}{d\epsilon}\bigg\vert_{\epsilon=0}=-\mathbf{H}^{-1}_{\hat{\theta}} \nabla_\theta \mathcal{L}(z, \hat{\theta})
$$

其中 $\hat{\theta}_{\epsilon,z} = \arg\min_{\theta \in \Theta} \frac{1}{n}\sum_{i=1}^n \mathcal{L}(z_i, \theta) + \epsilon L(z, \theta)$ 和 $\mathbf{H}^{-1}_{\hat{\theta}} = \frac{1}{n}\sum_{i=1}^n \nabla^2_\theta \mathcal{L}(z_i, \hat{\theta})$。移除数据点 $x$ 等同于将其权重提高 $\epsilon = -\frac{1}{n}$，因此 $\hat{\theta}_{-z} - \hat{\theta} \approx -\frac{1}{n} \mathcal{I}_{\text{up,params}}(z)$。

> where $\hat{\theta}_{\epsilon,z} = \arg\min_{\theta \in \Theta} \frac{1}{n}\sum_{i=1}^n \mathcal{L}(z_i, \theta) + \epsilon L(z, \theta)$ and $\mathbf{H}^{-1}_{\hat{\theta}} = \frac{1}{n}\sum_{i=1}^n \nabla^2_\theta \mathcal{L}(z_i, \hat{\theta})$.
> Removing a data point $x$ is equivalent to upweighting it by $\epsilon = -\frac{1}{n}$ and therefore $\hat{\theta}_{-z} - \hat{\theta} \approx -\frac{1}{n} \mathcal{I}_{\text{up,params}}(z)$.

加权 $z$ 对测试点 $z_\text{test}$ 处损失的影响通过应用链式法则给出：

> The influence of upweighting $z$ on the loss at a test point $z_\text{test}$ is given by applying the chain rule:

$$
\begin{aligned}
\mathcal{I}_{\text{up,loss}}(z, z_\text{test}) 
&= \frac{d \mathcal{L}(z_\text{test}, \hat{\theta}_{\epsilon,z})}{d\epsilon}\bigg\vert_{\epsilon=0} \\
&= \nabla_\theta \mathcal{L}(z_\text{test}, \hat{\theta})^\top \frac{d \hat{\theta}_{\epsilon,z}}{d\epsilon}\bigg\vert_{\epsilon=0} \\
&= - \nabla_\theta \mathcal{L}(z_\text{test}, \hat{\theta})^\top \mathbf{H}^{-1}_{\hat{\theta}} \nabla_\theta \mathcal{L}(z, \hat{\theta})
\end{aligned}
$$

利用影响函数，我们可以用封闭形式度量单个数据点对模型参数和损失函数的影响。这有助于近似留一法再训练，而无需实际运行所有再训练。为了识别错误标记的数据，我们可以度量$\mathcal{I}_\text{up,loss}(z_i, z_i)$，近似预测误差$z_i$如果$z_i$从训练集中移除。

> Using the influence function we can measure the effect of a single data point on model parameters and loss function in closed forms. It can help approximate leave-one-out retraining without actually running all the retraining. To identify mislabeled data, we can measure $\mathcal{I}_\text{up,loss}(z_i, z_i)$, approximating the prediction error on $z_i$ if $z_i$ is removed from the training set.

![Influence functions values match leave-one-out training results on 10-class MNIST. (Image source: Kohn & Liang, 2017 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/influence.png)

鉴于其封闭形式，影响函数仍然难以扩展，因为逆Hessian向量积难以计算。[Grosse et al. (2023)](https://arxiv.org/abs/2308.03296) 转而尝试了EK-FAC（特征值校正的Kronecker分解近似曲率；[George et al. 2018](https://arxiv.org/abs/1806.03884)）近似。

> Given the closed form, influence functions is still hard to be scaled up because the inverse Hessian vector product is hard to compute. [Grosse et al. (2023)](https://arxiv.org/abs/2308.03296) experimented with the EK-FAC (Eigenvalue-corrected Kronecker-Factored Approximate Curvature; [George et al. 2018](https://arxiv.org/abs/1806.03884)) approximation instead.

#### 训练期间的预测变化

> Prediction Changes during Training

另一类方法是在训练期间跟踪模型预测的变化，以识别那些似乎难以学习的案例。**数据图**（[Swayamdipta 等人 2020](https://arxiv.org/abs/2009.10795)）跟踪训练期间模型行为动态的两个属性，以分析数据集的质量：

> Another branch of methods are to track the changes of model prediction during training to identify cases which seem hard to be learned. **Data Maps** ([Swayamdipta et al. 2020](https://arxiv.org/abs/2009.10795)) tracks two attributes of model behavior dynamics during training to analyze the quality of dataset:

1. **置信度**：模型对真实标签的置信度，定义为模型在所有训练周期中对真实标签的平均概率。他们还使用了一个粗粒度指标，“正确性”，定义为模型在所有训练周期中预测正确标签的次数比例。
2. **变异性**：置信度的变化，定义为模型在所有训练周期中对真实标签的概率的标准差。

> • **Confidence**: The model’s confidence in the true label, defined as the mean model probability of the true label across epochs. They also used a coarse-grained metric, “correctness”, defined as the fraction of times when the model predicts the correct label across epochs.
> • **Variability**: The variation of the confidence, defined as the standard deviation of model probability of the true label across epochs.

![Data map for SNLI training set, based on a RoBERTa classifier. (Image source: Swayamdipta et al. 2020 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/data_map.png)

难以学习（低置信度、低变异性）的样本更有可能被错误标记。他们在 WinoGrande 数据集上进行了一项实验，其中包含 1% 的翻转标签数据。重新训练后，翻转的实例移动到较低置信度和略高变异性的区域，这表明难以学习的区域包含错误标记的样本。鉴于此，我们可以仅使用置信度分数（不确定为什么论文没有同时使用置信度和变异性作为特征）在等量的翻转标签和干净样本上训练一个分类器。然后，这个简单的噪声分类器可以用于原始数据集，以识别潜在的错误标记实例。

> Hard-to-learn (low confidence, low variability) samples are more likely to be mislabeled. They ran an experiment on WinoGrande dataset with 1% flipped label data. After retraining, flipped instances move to the lower confidence and slightly higher variability regions, indicating that the hard-to-learn regions contains mislabeled samples. Given this, we can train a classifier on equal numbers of label flipped and clean samples using only the confidence score (unsure why the paper didn’t use both confidence and variability as features). This simple noise classifier then can be used on the original dataset to identify potentially mislabeled instances.

![Data points originally with high confidence and low variability scores moved to low confidence, slightly higher variability regions after labels get flipped. (Image source: Swayamdipta et al. 2020 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/flip_exp.png)

然而，我们不应将所有难以学习的样本都视为不正确。事实上，该论文假设模糊（高变异性）和难以学习（低置信度、低变异性）的样本对学习更有信息量。实验表明，它们有利于 OOD 泛化，在 OOD 评估中给出了更好的结果，甚至与 100% 训练集相比也是如此。

> However, we should not consider all hard-to-learn samples to be incorrect. In fact, the paper hypothesizes that ambiguous (high variability) and hard-to-learn (low confidence, low variability) samples are more informative for learning. Experiments showed that they are good for OOD generalization, giving better results on OOD eval, even in comparison to 100% training set.

为了调查神经网络是否倾向于**遗忘**先前学习到的信息，[Toneva 等人 (2019)](https://arxiv.org/abs/1812.05159)设计了一个实验：他们跟踪训练过程中每个样本的模型预测，并计算每个样本从正确分类到错误分类或反之的转换次数。然后可以相应地对样本进行分类，

> To investigate whether neural networks have a tendency to **forget** previously learned information, [Toneva et al. (2019)](https://arxiv.org/abs/1812.05159) designed an experiment: They track the model prediction for each sample during the training process and count the transitions for each sample from being classified correctly to incorrectly or vice-versa. Then samples can be categorized accordingly,

- *可遗忘*（冗余）样本：如果类别标签在训练周期中发生变化。
- *不可遗忘*样本：如果类别标签分配在训练周期中保持一致。这些样本一旦学习就不会被遗忘。

> • *Forgettable* (redundant) samples: If the class label changes across training epochs.
> • *Unforgettable* samples: If the class label assignment is consistent across training epochs. Those samples are never forgotten once learned.

他们发现有大量不可遗忘的例子，一旦学习就不会被遗忘。带有噪声标签的例子或具有“不常见”特征（视觉上难以分类）的图像是其中最容易被遗忘的例子。实验经验性地验证了不可遗忘的例子可以安全移除，而不会损害模型性能。

> They found that there are a large number of unforgettable examples that are never forgotten once learnt. Examples with noisy labels or images with “uncommon” features (visually complicated to classify) are among the most forgotten examples. The experiments empirically validated that unforgettable examples can be safely removed without compromising model performance.

在实现中，遗忘事件仅在样本包含在当前训练批次中时才被计数；也就是说，他们计算的是同一示例在后续小批次中出现时的遗忘情况。每个样本的遗忘事件数量在不同种子之间相当稳定，并且可遗忘的示例在训练后期首次被学习的倾向较小。遗忘事件还被发现在整个训练期间和不同架构之间具有可迁移性。

> In the implementation, the forgetting event is only counted when a sample is included in the current training batch; that is, they compute forgetting across presentations of the same example in subsequent mini-batches. The number of forgetting events per sample is quite stable across different seeds and forgettable examples have a small tendency to be first-time learned later in the training. The forgetting events are also found to be transferable throughout the training period and between architectures.

[Pleiss 等人 (2020)](https://arxiv.org/abs/2001.10528) 基于以下假设开发了一种名为 **AUM (Area under the Margin)** 的方法来识别错误标签：例如，一张 BIRD 图像被错误地标记为 DOG。梯度更新会鼓励从其他 BIRD 图像到这张 BIRD 图像的泛化，而 DOG 标签则提供了一个不正确的监督信号，促使更新走向另一个方向。因此，在梯度更新信号中，泛化与（错误）预测之间存在张力。

> [Pleiss, et al. (2020)](https://arxiv.org/abs/2001.10528) developed a method named **AUM (Area under the Margin)** to spot wrong labels based on such an assumption: Say, a BIRD image is mistakenly marked as DOG. The gradient update would encourage generalization from other BIRD images to this BIRD image, while the DOG label provides an incorrect supervised signal to encourage the update to go another way. Hence, there exists tension between generalization and (wrong) prediction in gradient update signals.

给定一个分类数据集$(\mathbf{x}, y) \in \mathcal{D}_\text{train}$，令$z^{(t)}_i(\mathbf{x}) \in \mathbb{R}$为对应于类别$i$的对数几率在周期$t$。周期$t$的裕度是指定对数几率与次大对数几率之间的差值：

> Given a classification dataset $(\mathbf{x}, y) \in \mathcal{D}_\text{train}$, let $z^{(t)}_i(\mathbf{x}) \in \mathbb{R}$ be the logit corresponding to class $i$ at epoch $t$. The margin at epoch $t$ is the difference between the assigned logit and the next largest logit:

$$
M^{(t)}(\mathbf{x}, y) = z_y^{(t)}(\mathbf{x}) - \max_{i \neq y} z^{(t)}_i(\mathbf{x}),\quad
\text{AUM}(\mathbf{x}, y) = \frac{1}{T} \sum^T_{t=1} M^{(t)}(\mathbf{x}, y)
$$

负边距表示预测错误，大正边距表示对正确预测的高度置信。假设是，由于其他样本触发的通过 SGD 进行泛化的张力，错误标记的样本将比正确样本具有更小的边距。

> A negative margin indicates a wrong prediction and a large positive margin suggests high confidence in a correct prediction. The hypothesis is that mislabeled samples would have a smaller margin than correct samples due to the tension of generalization via SGD triggered by other samples.

为了确定阈值，他们插入了名为“阈值样本”的虚假数据来确定阈值：

> In order to determine the threshold, they insert fake data, named “threshold samples”, to determine the threshold:

1\. 创建阈值样本的子集$\mathcal{D}_\text{thr}$。如果存在$N$个用于$C$类的训练样本，我们随机抽取$N/(C+1)$个样本，并将其所有标签切换到一个虚假的新类$C+1$。

2\. 将阈值样本合并到原始数据集中：$\mathcal{D}’ = { (\mathbf{x}, C+1): \mathbf{x} \in \mathcal{D}_\text{thr}} \cup (\mathcal{D} \setminus\mathcal{D}_\text{thr})$；

3\. 在$\mathcal{D}’$上训练模型并测量所有数据的AUM；

4\. 计算阈值 $\alpha$ 作为阈值样本 AUM 的第 99 个百分位数；

5\. 使用 $\alpha$ 阈值识别错误标记的数据：${(\mathbf{x}, y) \in \mathcal{D} \setminus \mathcal{D}_\text{thr}: \text{AUM}_{\mathbf{x}, y} \leq \alpha}$

英文原文：

1\. Create a subset of threshold samples $\mathcal{D}_\text{thr}$.  If there are $N$ training samples for $C$ classes, we randomly sample $N/(C+1)$ samples and switch all their labels to a fake new class $C+1$.

2\. Merge threshold samples into the original dataset: $\mathcal{D}’ = { (\mathbf{x}, C+1): \mathbf{x} \in \mathcal{D}_\text{thr}} \cup (\mathcal{D} \setminus\mathcal{D}_\text{thr})$;

3\. Train the model on $\mathcal{D}’$ and measure AUM of all the data;

4\. Compute the threshold $\alpha$ as the 99th percentile of AUM of threshold samples;

5\. Identify mislabeled data using $\alpha$ a threshold: ${(\mathbf{x}, y) \in \mathcal{D} \setminus \mathcal{D}_\text{thr}: \text{AUM}_{\mathbf{x}, y} \leq \alpha}$

![How the AUM of threshold samples help separate out mislabeled samples. (Image source: Pleiss et al. 2020 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/AUM_threshold.png)

![Test error on CIFAR 10/100 with randomly mislabeled samples, comparing different methods for data filter or noisy data training. (Image source: Pleiss et al. 2020 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/AUM_exp.png)

#### 噪声交叉验证

> Noisy Cross-Validation

The **NCV (噪声交叉验证)** 方法 ([Chen et al. 2019](https://arxiv.org/abs/1905.05040)) 将数据集随机分成两半，然后如果数据样本的标签与仅在数据集另一半上训练的模型提供的预测标签匹配，则将其识别为“干净”样本。干净样本预计更值得信赖。INCV (Iterative Noisy Cross-Validation) 迭代运行 NCV，其中将更多干净样本添加到可信候选集 $\mathcal{C}$ 中，并移除更多噪声样本。

英文原文：The NCV (Noisy Cross-Validation) method ([Chen et al. 2019](https://arxiv.org/abs/1905.05040)) divides the dataset into half at random, and then identifies data samples as “clean” if its label matches the predicted label provided by the model that is only trained on the other half of the dataset. Clean samples are expected to be more trustworthy. INCV (Iterative Noisy Cross-Validation) runs NCV iteratively where more clean samples are added into the trusted candidate set 

$\mathcal{C}$ and more noisy samples are removed.

![Algorithm of INCV (iterative noisy cross-validation). (Image source: Chen et al. 2019 )](https://lilianweng.github.io/posts/2024-02-05-human-data-quality/INCV_algo.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Feb 2024). “Thinking about High-Quality Human Data”. Lil’Log. https://lilianweng.github.io/posts/2024-02-05-human-data-quality/.

> Weng, Lilian. (Feb 2024). “Thinking about High-Quality Human Data”. Lil’Log. https://lilianweng.github.io/posts/2024-02-05-human-data-quality/.

或

> Or

```
@article{weng2024humandata,
  title   = "Thinking about High-Quality Human Data",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2024",
  month   = "Feb",
  url     = "https://lilianweng.github.io/posts/2024-02-05-human-data-quality/"
}
```

### 参考文献

> References

[1] 弗朗西斯·高尔顿 [“Vox populi”](https://www.nature.com/articles/075450a0) 自然 75, 450-451 (1907)。

> [1] Francis Galton [“Vox populi”](https://www.nature.com/articles/075450a0)  Nature 75, 450-451 (1907).

[2] Sambasivan 等人 [“每个人都想做模型工作，而不是数据工作”：高风险人工智能中的数据级联”](https://dl.acm.org/doi/10.1145/3411764.3445518) CHI 2021

> [2] Sambasivan et al. [“Everyone wants to do the model work, not the data work”: Data Cascades in High-Stakes AI"](https://dl.acm.org/doi/10.1145/3411764.3445518) CHI 2021

[3] Chris Callison-Burch. [“快速、廉价且富有创意：使用亚马逊土耳其机器人评估翻译质量”](https://aclanthology.org/D09-1030/) EMNLP 2009

> [3] Chris Callison-Burch. [“Fast, Cheap, and Creative: Evaluating Translation Quality Using Amazon’s Mechanical Turk”](https://aclanthology.org/D09-1030/) EMNLP 2009

[4] Rottger 等人 [“主观自然语言处理任务的两种对比数据标注范式”](https://arxiv.org/abs/2112.07475) NAACL 2022。

> [4] Rottger et al. [“Two Contrasting Data Annotation Paradigms for Subjective NLP Tasks”](https://arxiv.org/abs/2112.07475) NAACL 2022.

[5] Aroyo & Welty [“真相是谎言：众包真相与人类标注的七个迷思”](https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/2564) AI Magazine 36.1: 15-24 (2015)。

> [5] Aroyo & Welty [“Truth Is a Lie: Crowd Truth and the Seven Myths of Human Annotation”](https://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/2564) AI Magazine 36.1: 15-24 (2015).

[6] Hovy 等人 [“使用 MACE 学习信任谁”](https://aclanthology.org/N13-1132.pdf) NAACL-HLT 2013。

> [6] Hovy et al. [“Learning Whom to Trust with MACE”](https://aclanthology.org/N13-1132.pdf) NAACL-HLT 2013.

[7] Wang 等人 [“并非所有一致的都是黄金：评估安全性的真实标签和对话内容”](https://research.google/pubs/all-that-agrees-is-not-gold-evaluating-ground-truth-labels-and-dialogue-content-for-safety/) 2023。

> [7] Wang et al. [“All that Agrees Is Not Gold: Evaluating Ground Truth Labels and Dialogue Content for Safety”](https://research.google/pubs/all-that-agrees-is-not-gold-evaluating-ground-truth-labels-and-dialogue-content-for-safety/) 2023.

[8] Zhang 等人 [“评估者分歧分类法：从标注在线毒性角度调查挑战与机遇”](https://arxiv.org/abs/2311.04345) arXiv preprint arXiv:2311.04345 (2023)。

> [8] Zhang et al. [“A Taxonomy of Rater Disagreements: Surveying Challenges & Opportunities from the Perspective of Annotating Online Toxicity”](https://arxiv.org/abs/2311.04345) arXiv preprint arXiv:2311.04345 (2023).

[9] Davani 等人 [“处理分歧：超越主观标注中的多数票”](https://arxiv.org/abs/2110.05719) ACL 2022。

> [9] Davani et al. [“Dealing with disagreements: Looking beyond the majority vote in subjective annotations”](https://arxiv.org/abs/2110.05719) ACL 2022.

[10] Gordon 等人 [“陪审团学习：将异议声音整合到机器学习模型中”](https://arxiv.org/abs/2202.02950) CHI 2022。

> [10] Gordon et al. [“Jury Learning: Integrating Dissenting Voices into Machine Learning Models”](https://arxiv.org/abs/2202.02950) CHI 2022.

[11] Gordon 等人 [“分歧解卷积：使机器学习性能指标与现实保持一致”](https://dl.acm.org/doi/abs/10.1145/3411764.3445423) CHI 2021

> [11] Gordon et al. [“The Disagreement Deconvolution: Bringing Machine Learning Performance Metrics In Line With Reality”](https://dl.acm.org/doi/abs/10.1145/3411764.3445423) CHI 2021

[12] Daniel 等人 2018 [“众包中的质量控制：质量属性、评估技术和保障措施调查”](https://arxiv.org/abs/1801.02546) ACM Computing Surveys (CSUR), 51(1), 1-40 (2018)。

> [12] Daniel et al. 2018 [“Quality Control in Crowdsourcing: A Survey of Quality Attributes, Assessment Techniques, and Assurance Actions”](https://arxiv.org/abs/1801.02546) ACM Computing Surveys (CSUR), 51(1), 1-40 (2018).

[13] Koh & Liang. [“通过影响函数理解黑盒预测”](https://arxiv.org/abs/1703.04730) ICML 2017。

> [13] Koh & Liang. [“Understanding Black-box Predictions via Influence Functions”](https://arxiv.org/abs/1703.04730) ICML 2017.

[14] Grosse 等人 [“使用影响函数研究大型语言模型泛化”](https://arxiv.org/abs/2308.03296) arXiv preprint arXiv:2308.03296 (2023)。

> [14] Grosse et al. [“Studying Large Language Model Generalization with Influence Functions”](https://arxiv.org/abs/2308.03296) arXiv preprint arXiv:2308.03296 (2023).

[15] Swayamdipta 等人 [“数据集制图：利用训练动态映射和诊断数据集”](https://arxiv.org/abs/2009.10795) EMNLP 2020。

> [15] Swayamdipta et al. [“Dataset Cartography: Mapping and Diagnosing Datasets with Training Dynamics”](https://arxiv.org/abs/2009.10795) EMNLP 2020.

[16] Toneva 等人 [“深度神经网络学习过程中示例遗忘的实证研究”](https://arxiv.org/abs/1812.05159) ICLR 2019。

> [16] Toneva, et al. [“An Empirical Study of Example Forgetting during Deep Neural Network Learning”](https://arxiv.org/abs/1812.05159) ICLR 2019.

[17] Pleiss 等人 [“使用边际排名曲线下面积识别错误标注数据”](https://arxiv.org/abs/2001.10528) NeuriPS 2020。

> [17] Pleiss, et al.  [“Identifying Mislabeled Data using the Area Under the Margin Ranking”](https://arxiv.org/abs/2001.10528) NeuriPS 2020.

[18] Chen 等人 [“理解和利用用噪声标签训练的深度神经网络”](https://arxiv.org/abs/1905.05040) ICML 2019。

> [18] Chen et al. [“Understanding and utilizing deep neural networks trained with noisy labels”](https://arxiv.org/abs/1905.05040) ICML 2019.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| RLHF | 人类反馈强化学习 | 一种通过人类偏好反馈来优化大型语言模型的技术。 |
| Vox populi | 人民的声音 | 一个拉丁短语，意为“人民的声音”，常用于描述群体智慧。 |
| Crowdsourcing | 众包 | 将传统上由员工执行的任务外包给大量非特定人群的做法。 |
| Amazon Mechanical Turk (AMT) | 亚马逊土耳其机器人 | 亚马逊提供的一个众包平台，用于完成需要人类智能的任务。 |
| Golden reference | 黄金参考译文/黄金标准 | 由专家创建的高质量、被认为是正确的参考数据。 |
| Cohen's Kappa | 科恩Kappa系数 | 衡量两个评估者之间一致性的统计量，并对偶然一致性进行校正。 |
| Probabilistic graphical models | 概率图模型 | 使用图结构表示变量之间条件依赖关系的统计模型。 |
| MACE (Multi-Annotator Competence Estimation) | 多标注者能力估计 | 一种使用图模型估计标注者可靠性并识别垃圾信息发布者的方法。 |
| Influence functions | 影响函数 | 一种衡量单个训练数据点对模型参数或损失函数影响的经典统计技术。 |
| Inverse Hessian vector product | 逆Hessian向量积 | 在影响函数计算中用于近似模型参数变化的一个数学运算。 |
| Data maps | 数据图 | 通过跟踪模型在训练期间对样本的置信度和变异性来分析数据集质量的方法。 |
| Forgetting events | 遗忘事件 | 模型在训练过程中对某个样本的分类从正确变为错误的情况。 |
| AUM (Area under the Margin) | 裕度曲线下面积 | 一种通过测量模型在训练期间对样本的预测裕度来识别错误标签的方法。 |
| Noisy Cross-Validation (NCV) | 噪声交叉验证 | 一种将数据集分成两半并相互验证标签以识别“干净”样本的方法。 |
| Jury Learning | 陪审团学习 | 一种通过建模不同标注者基于其特征的标注行为来模拟陪审团决策过程的方法。 |
