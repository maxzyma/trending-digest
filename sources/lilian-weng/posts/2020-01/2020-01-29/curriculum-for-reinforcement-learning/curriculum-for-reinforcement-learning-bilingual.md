# 强化学习的课程

> Curriculum for Reinforcement Learning

> 来源：Lil'Log / Lilian Weng，2020-01-29
> 原文链接：https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/
> 分类：强化学习 / 课程学习

## 核心要点

- 课程学习通过系统地分解复杂知识并逐步引入难度递增的概念，使机器学习模型能更有效地学习。
- 课程学习旨在加速模型收敛并可能提升最终性能，但设计不当的课程反而会阻碍学习。
- 任务特定课程通过手动设计或量化任务难度，逐步增加训练样本的复杂性，以提高模型的泛化能力。
- 教师引导课程利用一个“教师”智能体自动选择任务，以最大化“学生”智能体的学习进展或帮助其避免遗忘。
- 通过自博弈的课程学习框架中，两个智能体相互挑战，自动生成难度递增的可解决任务，从而推动学习。
- 自动目标生成方法利用生成对抗网络（GAN）自动创建难度适中的目标，以引导强化学习策略的训练。
- 基于技能的课程通过无监督交互发现和构建可重用的潜在技能，以支持元强化学习策略向未见任务的迁移。
- 通过蒸馏的课程学习方法，如渐进式神经网络和Mix & Match，通过知识迁移和共享权重，有效避免灾难性遗忘并促进技能复用。

## 正文

[2020-02-03更新：在“任务特定课程”部分提及[PCG](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#pcg)。  

[2020-02-04更新：新增[“通过蒸馏的课程”](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#curriculum-through-distillation)部分。

> [Updated on 2020-02-03: mentioning [PCG](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#pcg) in the “Task-Specific Curriculum” section.  
>
> [Updated on 2020-02-04: Add a new [“curriculum through distillation”](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#curriculum-through-distillation) section.

如果我们想教一个连基本算术都不知道的3岁孩子积分或导数，这听起来像是一个不可能完成的任务。这就是教育重要的原因，因为它提供了一种系统的方法来分解复杂的知识，并提供了一个很好的课程来教授从简单到困难的概念。课程使我们人类学习困难的事情变得更容易、更易于接近。但是，机器学习模型呢？我们能否通过课程更有效地训练我们的模型？我们能否设计一个课程来加速学习？

> It sounds like an impossible task if we want to teach integral or derivative to a 3-year-old who does not even know basic arithmetics. That’s why education is important, as it provides a systematic way to break down complex knowledge and a nice curriculum for teaching concepts from simple to hard. A curriculum makes learning difficult things easier and approachable for us humans. But, how about machine learning models? Can we train our models more efficiently with a curriculum? Can we design a curriculum to speed up learning?

早在1993年，Jeffrey Elman就提出了用课程训练神经网络的想法。他早期关于学习简单语言语法的工作证明了这种策略的重要性：从一组受限的简单数据开始，逐步增加训练样本的复杂性；否则模型根本无法学习。

> Back in 1993, Jeffrey Elman has proposed the idea of training neural networks with a curriculum. His early work on learning simple language grammar demonstrated the importance of such a strategy: starting with a restricted set of simple data and gradually increasing the complexity of training samples; otherwise the model was not able to learn at all.

与没有课程的训练相比，我们期望采用课程能够加快收敛速度，并且可能改善也可能不改善最终模型性能。设计一个高效且有效的课程并不容易。请记住，一个糟糕的课程甚至可能会阻碍学习。

> Compared to training without a curriculum, we would expect the adoption of the curriculum to expedite the speed of convergence and may or may not improve the final model performance. To design an efficient and effective curriculum is not easy. Keep in mind that, a bad curriculum may even hamper learning.

接下来，我们将探讨课程学习的几个类别，如所示。大多数情况应用于强化学习，少数例外应用于监督学习。

> Next, we will look into several categories of curriculum learning, as illustrated in Most cases are applied to Reinforcement Learning, with a few exceptions on Supervised Learning.

![Five types of curriculum for reinforcement learning.](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/types-of-curriculum-2.png)

在“从小开始的重要性”这篇论文（[Elman 1993](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.128.4487&rep=rep1&type=pdf)）中，我特别喜欢开头的句子，觉得它们既鼓舞人心又感人：

> In “The importance of starting small” paper ([Elman 1993](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.128.4487&rep=rep1&type=pdf)), I especially like the starting sentences and find them both inspiring and affecting:

> “人类在许多方面都与其他物种不同，但有两点尤其值得注意。人类展现出非凡的学习能力；而且人类以其异常长的成熟期而引人注目。学习的适应性优势是显而易见的，并且可以说，通过文化，学习为非基因基础的行为传播创造了基础，这可能加速我们物种的进化。”

> “Humans differ from other species along many dimensions, but two are particularly noteworthy. Humans display an exceptional capacity to learn; and humans are remarkable for the unusually long time it takes to reach maturity. The adaptive advantage of learning is clear, and it may be argued that, through culture, learning has created the basis for a non-genetically based transmission of behaviors which may accelerate the evolution of our species.”

确实，学习可能是我们人类拥有的最佳超能力。

> Indeed, learning is probably the best superpower we humans have.

### 任务特定课程

> Task-Specific Curriculum

[Bengio等人（2009）](https://www.researchgate.net/profile/Y_Bengio/publication/221344862_Curriculum_learning/links/546cd2570cf2193b94c577ac/Curriculum-learning.pdf)对早期的课程学习进行了很好的概述。该论文通过使用手动设计的任务特定课程的玩具实验提出了两个想法：

> [Bengio, et al. (2009)](https://www.researchgate.net/profile/Y_Bengio/publication/221344862_Curriculum_learning/links/546cd2570cf2193b94c577ac/Curriculum-learning.pdf) provided a good overview of curriculum learning in the old days. The paper presented two ideas with toy experiments using a manually designed task-specific curriculum:

1. 更清晰的示例可能会更快地产生更好的泛化能力。
2. 逐步引入更困难的示例可以加速在线训练。

> • Cleaner Examples may yield better generalization faster.
> • Introducing gradually more difficult examples speeds up online training.

某些课程策略可能无用甚至有害，这是合理的。该领域一个很好的问题是：*哪些普遍原则能使某些课程策略比其他策略更有效？* Bengio 2009年的论文假设，让学习专注于“有趣”的、既不太难也不太容易的例子将是有益的。

> It is plausible that some curriculum strategies could be useless or even harmful. A good question to answer in the field is: *What could be the general principles that make some curriculum strategies work better than others?* The Bengio 2009 paper hypothesized it would be beneficial to make learning focus on “interesting” examples that are neither too hard or too easy.

如果我们的朴素课程是在复杂度逐渐增加的样本上训练模型，我们首先需要一种方法来量化任务的难度。一个想法是使用它相对于另一个模型的最小损失，而这个模型是在其他任务上预训练的（[Weinshall等人，2018](https://arxiv.org/abs/1802.03796)）。通过这种方式，预训练模型的知识可以通过建议训练样本的排名转移到新模型。图2显示了`curriculum`组（绿色）的有效性，与`control`（随机顺序；黄色）和`anti`（反向顺序；红色）组相比。

> If our naive curriculum is to train the model on samples with a gradually increasing level of complexity, we need a way to quantify the difficulty of a task first. One idea is to use its minimal loss with respect to another model while this model is pretrained on other tasks ([Weinshall, et al. 2018](https://arxiv.org/abs/1802.03796)). In this way, the knowledge of the pretrained model can be transferred to the new model by suggesting a rank of training samples. Fig. 2 shows the effectiveness of the `curriculum` group (green), compared to `control` (random order; yellow) and `anti` (reverse the order; red) groups.

![Image classification accuracy on test image set (5 member classes of "small mammals" in CIFAR100). There are 4 experimental groups, (a) `curriculum`: sort the labels by the confidence of another trained classifier (e.g. the margin of an SVM); (b) `control-curriculum`: sort the labels randomly; (c) `anti-curriculum`: sort the labels reversely; (d) `None`: no curriculum. (Image source: Weinshall, et al. 2018 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/curriculum-by-transfer-learning.png)

[Zaremba & Sutskever (2014)](https://arxiv.org/abs/1410.4615)进行了一项有趣的实验，训练LSTM预测一个用于数学运算的短Python程序的输出，而无需实际执行代码。他们发现课程对于学习是必要的。程序的复杂性由两个参数控制，`length` ∈ [1, a] 和 `nesting`∈ [1, b]。考虑了三种策略：

> [Zaremba & Sutskever (2014)](https://arxiv.org/abs/1410.4615) did an interesting experiment on training LSTM to predict the output of a short Python program for mathematical ops without actually executing the code. They found curriculum is necessary for learning. The program’s complexity is controlled by two parameters, `length` ∈ [1, a] and `nesting`∈ [1, b]. Three strategies are considered:

1. 朴素课程：首先增加`length`直到达到`a`；然后增加`nesting`并将`length`重置为1；重复此过程直到两者都达到最大值。
2. 混合课程：采样`length` ~ [1, a] 和 `nesting` ~ [1, b]
3. 组合：朴素 + 混合。

> • Naive curriculum: increase `length` first until reaching `a`; then increase `nesting` and reset `length` to 1; repeat this process until both reach maximum.
> • Mix curriculum: sample `length` ~ [1, a] and `nesting` ~ [1, b]
> • Combined: naive + mix.

他们注意到，组合策略总是优于朴素课程，并且通常（但并非总是）优于混合策略——这表明在训练期间混合简单任务以*避免遗忘*非常重要。

> They noticed that combined strategy always outperformed the naive curriculum and would generally (but not always) outperform the mix strategy — indicating that it is quite important to mix in easy tasks during training to *avoid forgetting*.

程序化内容生成（[PCG](https://en.wikipedia.org/wiki/Procedural_generation)）是一种流行的创建各种难度级别视频游戏的方法。PCG涉及算法随机性和大量人类专业知识来设计游戏元素及其之间的依赖关系。程序生成关卡已被引入到几个基准环境中，用于评估RL智能体是否可以泛化到其未训练过的新关卡（[元RL](https://lilianweng.github.io/posts/2019-06-23-meta-rl/)！），例如[GVGAI](http://www.gvgai.net/)、OpenAI [CoinRun](https://openai.com/blog/quantifying-generalization-in-reinforcement-learning/)和[Procgen基准](https://openai.com/blog/procgen-benchmark/)。使用GVGAI，[Justesen等人（2018）](https://arxiv.org/abs/1806.10729)证明了RL策略很容易过度拟合特定游戏，但通过一个简单的课程进行训练，该课程将任务难度与模型性能一起增长，有助于其泛化到新的人工设计关卡。在CoinRun中也发现了类似的结果（[Cobbe等人，2018](https://arxiv.org/abs/1812.02341)）。POET（[Wang等人，2019](https://arxiv.org/abs/1901.01753)）是另一个利用进化算法和程序生成游戏关卡来改进RL泛化的例子，我已在我的[元RL文章](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#evolutionary-algorithm-on-environment-generation)中详细描述过。

> Procedural content generation ([PCG](https://en.wikipedia.org/wiki/Procedural_generation)) is a popular approach for creating video games of various levels of difficulty. PCG involves algorithmic randomness and a heavy dose of human expertise in designing game elements and dependencies among them. Procedurally generated levels have been introduced into several benchmark environments for evaluating whether an RL agent can generalize to a new level that it is not trained on ([meta-RL](https://lilianweng.github.io/posts/2019-06-23-meta-rl/)!), such as [GVGAI](http://www.gvgai.net/), OpenAI [CoinRun](https://openai.com/blog/quantifying-generalization-in-reinforcement-learning/) and [Procgen benchmark](https://openai.com/blog/procgen-benchmark/). Using GVGAI, [Justesen, et al. (2018)](https://arxiv.org/abs/1806.10729) demonstrated that an RL policy can easily overfit to a specific game but training over a simple curriculum that grows the task difficulty together with the model performance helps its generalization to new human-designed levels. Similar results are also found in CoinRun ([Cobbe, et al. 2018](https://arxiv.org/abs/1812.02341)). POET ([Wang et al, 2019](https://arxiv.org/abs/1901.01753)) is another example for leveraging evolutionary algorithm and procedural generated game levels to improve RL generalization, which I’ve described in details in my [meta-RL post](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#evolutionary-algorithm-on-environment-generation).

为了遵循上述课程学习方法，通常我们需要在训练过程中解决两个问题：

> To follow the curriculum learning approaches described above, generally we need to figure out two problems in the training procedure:

1. 设计一个度量标准来量化任务的难度，以便我们可以相应地对任务进行排序。
2. 在训练期间向模型提供一系列难度逐渐增加的任务。

> • Design a metric to quantify how hard a task is so that we can sort tasks accordingly.
> • Provide a sequence of tasks with an increasing level of difficulty to the model during training.

然而，任务的顺序不一定是连续的。在我们的魔方论文（[OpenAI等人，2019](https://arxiv.org/abs/1910.07113.)）中，我们依赖*自动域随机化*（**ADR**）通过增加复杂度的环境分布来生成课程。每个任务的难度（即在给定环境中解决魔方）取决于各种环境参数的随机化范围。即使在所有环境参数不相关的简化假设下，我们也能够为我们的机器人手创建了一个不错的课程来学习该任务。

> However, the order of tasks does not have to be sequential. In our Rubik’s cube paper ([OpenAI et al, 2019](https://arxiv.org/abs/1910.07113.)), we depended on *Automatic domain randomization* (**ADR**) to generate a curriculum by growing a distribution of environments with increasing complexity. The difficulty of each task (i.e. solving a Rubik’s cube in a set of environments) depends on the randomization ranges of various environmental parameters. Even with a simplified assumption that all the environmental parameters are uncorrelated, we were able to create a decent curriculum for our robot hand to learn the task.

### 教师引导课程

> Teacher-Guided Curriculum

*自动课程学习*的想法由[Graves等人于2017年](https://arxiv.org/abs/1704.03003)稍早提出。它将$N$任务课程视为一个[N臂老虎机](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/)问题，以及一个学习优化该老虎机回报的自适应策略。

> The idea of *Automatic Curriculum Learning* was proposed by [Graves, et al. 2017](https://arxiv.org/abs/1704.03003) slightly earlier. It considers a $N$ -task curriculum as an [N-armed bandit](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/) problem and an adaptive policy which learns to optimize the returns from this bandit.

论文中考虑了两类学习信号：

> Two categories of learning signals have been considered in the paper:

1. 损失驱动的进展：一次梯度更新前后损失函数的变化。这种奖励信号跟踪学习过程的速度，因为最大的任务损失减少等同于最快的学习。
2. 复杂性驱动的进展：网络权重后验分布和先验分布之间的KL散度。这种学习信号的灵感来自[MDL](https://en.wikipedia.org/wiki/Minimum_description_length)原则，“模型复杂性增加一定量只有在它能更大程度地压缩数据时才值得”。因此，模型复杂性预计在模型很好地泛化到训练示例时增加最多。

> • Loss-driven progress: the loss function change before and after one gradient update. This type of reward signals tracks the speed of the learning process, because the greatest task loss decrease is equivalent to the fastest learning.
> • Complex-driven progress: the KL divergence between posterior and prior distribution over network weights. This type of learning signals are inspired by the [MDL](https://en.wikipedia.org/wiki/Minimum_description_length) principle, “increasing the model complexity by a certain amount is only worthwhile if it compresses the data by a greater amount”. The model complexity is therefore expected to increase most in response to the model nicely generalizing to training examples.

这种通过另一个RL智能体自动提出课程的框架被形式化为*师生课程学习*（**TSCL**；[Matiisen等人，2017](https://arxiv.org/abs/1707.00183)）。在TSCL中，*学生*是一个在实际任务上工作的RL智能体，而*教师*智能体是一个选择任务的策略。学生旨在掌握一个可能难以直接学习的复杂任务。为了使这个任务更容易学习，我们设置教师智能体通过选择适当的子任务来指导学生的训练过程。

> This framework of proposing curriculum automatically through another RL agent was formalized as *Teacher-Student Curriculum Learning* (**TSCL**; [Matiisen, et al. 2017](https://arxiv.org/abs/1707.00183)). In TSCL, a *student* is an RL agent working on actual tasks while a *teacher* agent is a policy for selecting tasks. The student aims to master a complex task that might be hard to learn directly. To make this task easier to learn, we set up the teacher agent to guide the student’s training process by picking proper sub-tasks.

![The setup of teacher-student curriculum learning. (Image source: Matiisen, et al. 2017 + my annotation in red.)](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/teacher-student-curriculum.png)

在此过程中，学生应该学习以下任务：

> In the process, the student should learn tasks which:

1. 可以帮助学生取得最快的学习进展，或者
2. 有被遗忘的风险。

> • can help the student make fastest learning progress, or
> • are at risk of being forgotten.

> 注意：将教师模型构建为RL问题的设置与神经架构搜索（NAS）感觉非常相似，但不同的是，TSCL中的RL模型在任务空间上操作，而NAS在主模型架构空间上操作。

> Note: The setup of framing the teacher model as an RL problem feels quite similar to Neural Architecture Search (NAS), but differently the RL model in TSCL operates on the task space and NAS operates on the main model architecture space.

训练教师模型是为了解决一个[POMDP](https://en.wikipedia.org/wiki/Partially_observable_Markov_decision_process)问题：

> Training the teacher model is to solve a [POMDP](https://en.wikipedia.org/wiki/Partially_observable_Markov_decision_process) problem:

• 未观察到的$s_t$是学生模型的完整状态。

• 观察到的$o = (x_t^{(1)}, \dots, x_t^{(N)})$是$N$任务的分数列表。

• 动作$a$是选择一个子任务。

• 每步的奖励是分数增量。$r_t = \sum_{i=1}^N x_t^{(i)} - x_{t-1}^{(i)}$（即，等同于在回合结束时最大化所有任务的分数）。

英文原文：

• The unobserved $s_t$ is the full state of the student model.

• The observed $o = (x_t^{(1)}, \dots, x_t^{(N)})$ are a list of scores for $N$ tasks.

• The action $a$ is to pick on subtask.

• The reward per step is the score delta.$r_t = \sum_{i=1}^N x_t^{(i)} - x_{t-1}^{(i)}$ (i.e., equivalent to maximizing the score of all tasks at the end of the episode).

从嘈杂的任务分数中估计学习进展，同时平衡探索与利用的方法可以借鉴非平稳多臂老虎机问题——使用[ε-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm)或[Thompson采样](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#thompson-sampling)。

> The method of estimating learning progress from noisy task scores while balancing exploration vs exploitation can be borrowed from the non-stationary multi-armed bandit problem — use [ε-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm), or [Thompson sampling](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#thompson-sampling).

总之，核心思想是使用一个策略为另一个策略提出任务，以便后者能更好地学习。有趣的是，上述两项工作（在离散任务空间中）都发现，从所有任务中均匀采样是一个出人意料的强大基准。

> The core idea, in summary, is to use one policy to propose tasks for another policy to learn better. Interestingly, both works above (in the discrete task space) found that uniformly sampling from all tasks is a surprisingly strong benchmark.

任务空间是连续的怎么办？[Portelas 等人 (2019)](https://arxiv.org/abs/1910.07224) 研究了一个连续的教师-学生框架，其中教师必须从连续任务空间中采样参数以生成学习课程。给定一个新采样的参数 $p$，绝对学习进度（简称 ALP）的衡量方式是 $\text{ALP}_p = \vert r - r_\text{old} \vert$，其中 $r$ 是与 $p$ 相关的回合奖励，$r_\text{old}$ 是与 $p_\text{old}$ 相关的奖励。在这里，$p_\text{old}$ 是任务空间中与 $p$ 最接近的先前采样参数，可以通过最近邻检索。请注意，这个 ALP 分数与上面 [TSCL](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#TSCL) 或 [Grave 等人 2017](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#grave-et-al-2017) 中的学习信号有何不同：ALP 分数衡量的是两个任务之间的奖励差异，而不是同一任务在两个时间步的性能。

> What if the task space is continuous? [Portelas, et al. (2019)](https://arxiv.org/abs/1910.07224) studied a continuous teacher-student framework, where the teacher has to sample parameters from continuous task space to generate a learning curriculum. Given a newly sampled parameter $p$, the absolute learning progress (short for ALP) is measured as $\text{ALP}_p = \vert r - r_\text{old} \vert$, where $r$ is the episodic reward associated with $p$ and $r_\text{old}$ is the reward associated with $p_\text{old}$. Here, $p_\text{old}$ is a previous sampled parameter closest to $p$ in the task space, which can be retrieved by nearest neighbor. Note that how this ALP score is different from learning signals in [TSCL](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#TSCL) or [Grave, et al. 2017](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/#grave-et-al-2017) above: ALP score measures the reward difference between two tasks rather than performance at two time steps of the same task.

在任务参数空间之上，训练一个高斯混合模型来拟合 $\text{ALP}_p$ 在 $p$ 上的分布。在采样任务时使用 ε-greedy 策略：以一定概率采样一个随机任务；否则从 GMM 模型中按 ALP 分数比例采样。

> On top of the task parameter space, a Gaussian mixture model is trained to fit the distribution of $\text{ALP}_p$ over $p$. ε-greedy is used when sampling the tasks: with some probability, sampling a random task; otherwise sampling proportionally to ALP score from the GMM model.

![The algorithm of ALP-GMM (absolute learning progress Gaussian mixture model). (Image source: Portelas, et al., 2019 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/ALP-GMM-algorithm.png)

### 通过自博弈进行课程学习

> Curriculum through Self-Play

与教师-学生框架不同，两个智能体正在做非常不同的事情。教师学习为学生选择任务，而无需了解实际任务内容。如果我们想让两者都直接在主任务上训练怎么办？甚至让他们相互竞争怎么样？

> Different from the teacher-student framework, two agents are doing very different things. The teacher learns to pick a task for the student without any knowledge of the actual task content. What if we want to make both train on the main task directly? How about even make them compete with each other?

[Sukhbaatar 等人 (2017)](https://arxiv.org/abs/1703.05407) 提出了一种通过 **非对称自博弈** 进行自动课程学习的框架。两个智能体，Alice 和 Bob，以不同的目标玩同一个任务：Alice 挑战 Bob 达到相同的状态，而 Bob 尝试尽快完成它。

> [Sukhbaatar, et al. (2017)](https://arxiv.org/abs/1703.05407) proposed a framework for automatic curriculum learning through **asymmetric self-play**. Two agents, Alice and Bob, play the same task with different goals: Alice challenges Bob to achieve the same state and Bob attempts to complete it as fast as he can.

![Illustration of the self-play setup when training two agents. The example task is MazeBase : An agent is asked to reach a goal flag in a maze with a light switch, a key and a wall with a door. Toggling the key switch can open or close the door and Turning off the light makes only the glowing light switch available to the agent. (Image source: Sukhbaatar, et al. 2017 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/self-play-maze.png)

让我们将 Alice 和 Bob 视为在相同环境中训练但拥有不同大脑的同一个 RL 智能体的两个独立副本。它们各自拥有独立的参数和损失目标。自博弈驱动的训练包含两种类型的回合：

> Let us consider Alice and Bob as two separate copies for one RL agent trained in the same environment but with different brains. Each of them has independent parameters and loss objective. The self-play-driven training consists of two types of episodes:

• 在*自博弈回合*中，Alice 将状态从 $s_0$ 改变为 $s_t$，然后 Bob 被要求将环境恢复到其原始状态 $s_0$ 以获得内部奖励。

• 在*目标任务回合*中，如果 Bob 访问了目标旗帜，他将获得外部奖励。

英文原文：

• In the *self-play episode*, Alice alters the state from $s_0$ to $s_t$ and then Bob is asked to return the environment to its original state $s_0$ to get an internal reward.

• In the *target task episode*, Bob receives an external reward if he visits the target flag.

请注意，由于 B 必须在 A 的同一对 $(s_0, s_t)$ 之间重复操作，因此该框架仅适用于可逆或可重置的环境。

> Note that since B has to repeat the actions between the same pair of $(s_0, s_t)$ of A, this framework only works in reversible or resettable environments.

Alice 应该学会将 Bob 推出他的舒适区，但不要给他不可能完成的任务。Bob 的奖励设置为 $R_B = -\gamma t_B$，Alice 的奖励为 $R_A = \gamma \max(0, t_B - t_A)$，其中 $t_B$ 是 B 完成任务的总时间，$t_A$ 是 Alice 执行 STOP 操作之前的时间，$\gamma$ 是一个标量常数，用于重新调整奖励，使其与外部任务奖励相当。如果 B 任务失败，$t_B = t_\max - t_A$。两种策略都是目标导向的。损失意味着：

> Alice should learn to push Bob out of his comfort zone, but not give him impossible tasks. Bob’s reward is set as $R_B = -\gamma t_B$ and Alice’s reward is $R_A = \gamma \max(0, t_B - t_A)$, where $t_B$ is the total time for B to complete the task, $t_A$ is the time until Alice performs the STOP action and $\gamma$ is a scalar constant to rescale the reward to be comparable with the external task reward. If B fails a task, $t_B = t_\max - t_A$.
> Both policies are goal-conditioned. The losses imply:

1. B 希望尽快完成任务。
2. A 偏爱耗费 B 更多时间的任务。
3. 当 B 失败时，A 不希望采取过多步骤。

> • B wants to finish a task asap.
> • A prefers tasks that take more time of B.
> • A does not want to take too many steps when B is failing.

通过这种方式，Alice 和 Bob 之间的互动自动构建了一个难度逐渐增加的任务课程。同时，由于 A 在向 B 提出任务之前已经亲自完成了该任务，因此该任务保证是可解决的。

> In this way, the interaction between Alice and Bob automatically builds a curriculum of increasingly challenging tasks. Meanwhile, as A has done the task herself before proposing the task to B, the task is guaranteed to be solvable.

A 提出任务然后 B 解决任务的范式确实听起来与师生框架相似。然而，在非对称自博弈中，扮演教师角色的 Alice 也会在同一任务上工作，为 Bob 寻找具有挑战性的情况，而不是明确地优化 B 的学习过程。

> The paradigm of A suggesting tasks and then B solving them does sound similar to the Teacher-Student framework. However, in asymmetric self-play, Alice, who plays a teacher role, also works on the same task to find challenging cases for Bob, rather than optimizes B’s learning process explicitly.

### 自动目标生成

> Automatic Goal Generation

通常，强化学习策略需要能够在一组任务上执行。目标应该仔细选择，以确保在每个训练阶段，对于当前策略来说既不会太难也不会太容易。一个目标 $g \in \mathcal{G}$ 可以定义为一组状态 $S^g$，并且当智能体到达这些状态中的任何一个时，该目标就被认为是已实现的。

> Often RL policy needs to be able to perform over a set of tasks. The goal should be carefully chosen so that at every training stage, it would not be too hard or too easy for the current policy. A goal $g \in \mathcal{G}$ can be defined as a set of states $S^g$ and a goal is considered as achieved whenever an agent arrives at any of those states.

生成式目标学习（[Florensa, et al. 2018](https://arxiv.org/abs/1705.06366)）的方法依赖于一个 **目标 GAN** 来自动生成所需的目标。在他们的实验中，奖励非常稀疏，只是一个表示目标是否达成的二进制标志，并且策略是基于目标进行条件化的，

> The approach of Generative Goal Learning ([Florensa, et al. 2018](https://arxiv.org/abs/1705.06366)) relies on a **Goal GAN** to generate desired goals automatically. In their experiment, the reward is very sparse, just a binary flag for whether a goal is achieved or not and the policy is conditioned on goal,

$$
\begin{aligned}
\pi^{*}(a_t\vert s_t, g) &= \arg\max_\pi \mathbb{E}_{g\sim p_g(.)} R^g(\pi) \\
\text{where }R^g(\pi) &= \mathbb{E}_\pi(.\mid s_t, g) \mathbf{1}[\exists t \in [1,\dots, T]: s_t \in S^g]
\end{aligned}
$$

这里 $R^g(\pi)$ 是预期回报，也等同于成功概率。给定从当前策略采样的轨迹，只要任何状态属于目标集，回报就会是正的。

> Here $R^g(\pi)$ is the expected return, also equivalent to the success probability. Given sampled trajectories from the current policy, as long as any state belongs to the goal set, the return will be positive.

他们的方法通过 3 个步骤迭代，直到策略收敛：

> Their approach iterates through 3 steps until the policy converges:

1. 根据一组目标对于当前策略是否处于适当的难度级别来对其进行标记。

> • Label a set of goals based on whether they are at the appropriate level of difficulty for the current policy.

• 处于适当难度级别的目标集被命名为 **GOID**（“Goals of Intermediate Difficulty” 的缩写）。  
$\text{GOID}_i := \{g : R_\text{min} \leq R^g(\pi_i) \leq R_\text{max} \} \subseteq G$

• 这里 $R_\text{min}$ 和 $R_\text{max}$ 可以解释为在 T 个时间步内达到目标的最小和最大概率。

英文原文：

• The set of goals at the appropriate level of difficulty are named **GOID** (short for “Goals of Intermediate Difficulty”).  
$\text{GOID}_i := \{g : R_\text{min} \leq R^g(\pi_i) \leq R_\text{max} \} \subseteq G$

• Here $R_\text{min}$ and $R_\text{max}$ can be interpreted as a minimum and maximum probability of reaching a goal over T time-steps.

1. 使用步骤 1 中的标记目标训练一个 Goal GAN 模型以生成新目标
2. 使用这些新目标来训练策略，从而提高其覆盖目标。

> • Train a Goal GAN model using labelled goals from step 1 to produce new goals
> • Use these new goals to train the policy, improving its coverage objective.

Goal GAN 自动生成课程：

> The Goal GAN generates a curriculum automatically:

• 生成器 $G(z)$：生成一个新目标。=> 预期是均匀地从 $GOID$ 集合中采样的目标。

• 判别器 $D(g)$：评估一个目标是否可以实现。=> 预期是判断一个目标是否来自 $GOID$ 集合。

英文原文：

• Generator $G(z)$: produces a new goal. => expected to be a goal uniformly sampled from $GOID$ set.

• Discriminator $D(g)$: evaluates whether a goal can be achieved. => expected to tell whether a goal is from $GOID$ set.

Goal GAN 的构建类似于 LSGAN（最小二乘 GAN；[Mao et al., (2017)](https://arxiv.org/abs/1611.04076)），与普通 GAN 相比，LSGAN 具有更好的学习稳定性。根据 LSGAN，我们应该分别最小化 $D$ 和 $G$ 的以下损失：

> The Goal GAN is constructed similar to LSGAN (Least-Squared GAN; [Mao et al., (2017)](https://arxiv.org/abs/1611.04076)), which has better stability of learning compared to vanilla GAN. According to LSGAN, we should minimize the following losses for $D$ and $G$ respectively:

$$
\begin{aligned}
\mathcal{L}_\text{LSGAN}(D) &= \frac{1}{2} \mathbb{E}_{g \sim p_\text{data}(g)} [ (D(g) - b)^2] + \frac{1}{2} \mathbb{E}_{z \sim p_z(z)} [ (D(G(z)) - a)^2] \\
\mathcal{L}_\text{LSGAN}(G) &= \frac{1}{2} \mathbb{E}_{z \sim p_z(z)} [ (D(G(z)) - c)^2]
\end{aligned}
$$

其中$a$是假数据的标签，$b$是真数据的标签，$c$是$G$希望$D$相信的假数据的值。在LSGAN论文的实验中，他们使用了$a=-1, b=1, c=0$。

> where $a$ is the label for fake data, $b$ for real data, and $c$ is the value that $G$ wants $D$ to believe for fake data. In LSGAN paper’s experiments, they used $a=-1, b=1, c=0$.

Goal GAN引入了一个额外的二元标志$y_b$，指示目标$g$是真实的($y_g = 1$)还是虚假的($y_g = 0$)，以便模型可以使用负样本进行训练：

> The Goal GAN introduces an extra binary flag $y_b$ indicating whether a goal $g$ is real ($y_g = 1$) or fake ($y_g = 0$) so that the model can use negative samples for training:

$$
\begin{aligned}
\mathcal{L}_\text{GoalGAN}(D) &= \frac{1}{2} \mathbb{E}_{g \sim p_\text{data}(g)} [ (D(g) - b)^2 + (1-y_g) (D(g) - a)^2] + \frac{1}{2} \mathbb{E}_{z \sim p_z(z)} [ (D(G(z)) - a)^2] \\
\mathcal{L}_\text{GoalGAN}(G) &= \frac{1}{2} \mathbb{E}_{z \sim p_z(z)} [ (D(G(z)) - c)^2]
\end{aligned}
$$

![The algorithm of Generative Goal Learning. (Image source: ( Florensa, et al. 2018 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/generative-goal-learning-algorithm.png)

遵循相同的思想，[Racaniere & Lampinen, et al. (2019)](https://arxiv.org/abs/1909.12892)设计了一种方法，使目标生成器的目标更加复杂。他们的方法包含三个组件，与上述生成式目标学习相同：

> Following the same idea, [Racaniere & Lampinen, et al. (2019)](https://arxiv.org/abs/1909.12892) designs a method to make the objectives of goal generator more sophisticated. Their method contains three components, same as generative goal learning above:

• **求解器**/策略$\pi$：在每个回合中，求解器在开始时获得一个目标$g$，并在结束时获得一个单一的二元奖励$R^g$。

• **判断器**/判别器$D(.)$：一个分类器，用于预测二元奖励（目标是否可以实现）；准确地说，它输出实现给定目标的概率的对数几率，$\sigma(D(g)) = p(R^g=1\vert g)$，其中$\sigma$是sigmoid函数。

• **设置器**/生成器$G(.)$：目标设置器将期望的可行性分数$f \in \text{Unif}(0, 1)$作为输入并生成$g = G(z, f)$，其中潜在变量$z$由$z \sim \mathcal{N}(0, I)$采样。目标生成器被设计为可逆的，因此$G^{-1}$可以从目标$g$反向映射到潜在变量$z = G^{-1}(g, f)$

英文原文：

• **Solver**/Policy $\pi$: In each episode, the solver gets a goal $g$ at the beginning and get a single binary reward $R^g$ at the end.

• **Judge**/Discriminator $D(.)$: A classifier to predict the binary reward (whether goal can be achieved or not); precisely it outputs the logit of a probability of achieving the given goal, $\sigma(D(g)) = p(R^g=1\vert g)$, where $\sigma$ is the sigmoid function.

• **Setter**/Generator $G(.)$: The goal setter takes as input a desired feasibility score $f \in \text{Unif}(0, 1)$ and generates $g = G(z, f)$, where the latent variable $z$ is sampled by $z \sim \mathcal{N}(0, I)$. The goal generator is designed to reversible, so $G^{-1}$ can map backwards from a goal $g$ to a latent $z = G^{-1}(g, f)$

生成器通过三个目标进行优化：

> The generator is optimized with three objectives:

1\. 目标**有效性**：所提出的目标应该可以通过专家策略实现。相应的生成损失旨在增加生成求解器策略之前已经实现的目标的可能性（如[HER](https://arxiv.org/abs/1707.01495)中所示）。



• $\mathcal{L}_\text{val}$是过去求解器已解决的生成目标的负对数似然。



• 

英文原文：

1\. Goal **validity**: The proposed goal should be achievable by an expert policy. The corresponding generative loss is designed to increase the likelihood of generating goals that the solver policy has achieved before (like in [HER](https://arxiv.org/abs/1707.01495)).



• $\mathcal{L}_\text{val}$ is the negative log-likelihood of generated goals that have been solved by the solver in the past.



• 

$$
\begin{align*}
\mathcal{L}_\text{val} = \mathbb{E}_{\substack{
  g \sim \text{ achieved by solver}, \\
  \xi \in \text{Uniform}(0, \delta), \\
  f \in \text{Uniform}(0, 1)
}} \big[ -\log p(G^{-1}(g + \xi, f)) \big]
\end{align*}
$$

1\. 目标**可行性**：所提出的目标应该可以通过当前策略实现；也就是说，难度级别应该适当。



• $\mathcal{L}_\text{feas}$是判断模型$D$在生成目标$G(z, f)$上的输出概率，应与期望的$f$匹配。



• 

英文原文：

1\. Goal **feasibility**: The proposed goal should be achievable by the current policy; that is, the level of difficulty should be appropriate.



• $\mathcal{L}_\text{feas}$ is the output probability by the judge model $D$ on the generated goal $G(z, f)$ should match the desired $f$.



• 

$$
\begin{align*}
\mathcal{L}_\text{feas} = \mathbb{E}_{\substack{
  z \in \mathcal{N}(0, 1), \\
  f \in \text{Uniform}(0, 1)
}} \big[ D(G(z, f)) - \sigma^{-1}(f)^2 \big]
\end{align*}
$$

1. 目标 **覆盖率**：我们应该最大化生成目标的熵，以鼓励目标多样性并提高目标空间覆盖率。

> • Goal **coverage**: We should maximize the entropy of generated goals to encourage diverse goal and to improve the coverage over the goal space.

$$
\begin{align*}
\mathcal{L}_\text{cov} = \mathbb{E}_{\substack{
  z \in \mathcal{N}(0, 1), \\
  f \in \text{Uniform}(0, 1)
}} \big[ \log p(G(z, f)) \big]
\end{align*}
$$

他们的实验表明，复杂环境需要上述所有三种损失。当环境在不同回合之间变化时，目标生成器和判别器都需要以环境观测为条件才能产生更好的结果。如果存在期望的目标分布，可以添加额外的损失以使用 Wasserstein 距离匹配期望的目标分布。使用这种损失，生成器可以更有效地推动求解器掌握期望的任务。

> Their experiments showed complex environments require all three losses above. When the environment is changing between episodes, both the goal generator and the discriminator need to be conditioned on environmental observation to produce better results. If there is a desired goal distribution, an additional loss can be added to match a desired goal distribution using Wasserstein distance. Using this loss, the generator can push the solver toward mastering the desired tasks more efficiently.

![Training schematic for the (a) solver/policy, (b) judge/discriminator, and (c) setter/goal generator models. (Image source: Racaniere & Lampinen, et al., 2019 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/setter-judge-goal-generation.png)

### 基于技能的课程

> Skill-Based Curriculum

另一种观点是将智能体能够完成的任务分解为各种技能，每种技能集都可以映射到一个任务。让我们设想一下，当智能体以无监督的方式与环境交互时，是否有一种方法可以从这种交互中发现有用的技能，并通过课程进一步构建成解决更复杂任务的方案？

> Another view is to decompose what an agent is able to complete into a variety of skills and each skill set could be mapped into a task. Let’s imagine when an agent interacts with the environment in an unsupervised manner, is there a way to discover useful skills from such interaction and further build into the solutions for more complicated tasks through a curriculum?

[Jabri, et al. (2019)](https://arxiv.org/abs/1912.04226)开发了一种自动课程，**CARML**（“无监督元强化学习课程”的简称），通过将无监督轨迹建模到潜在技能空间中，重点在于训练[元强化学习](https://lilianweng.github.io/posts/2019-06-23-meta-rl/)策略（即可以迁移到未见过的任务）。CARML 中训练环境的设置类似于[DIAYN](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#learning-with-random-rewards)。不同的是，CARML 在像素级观测上进行训练，而 DIAYN 在真实状态空间上操作。一个强化学习算法$\pi_\theta$，由`\theta`，通过无监督交互进行训练，该交互被表述为 CMP 与学习到的奖励函数相结合`r`。这种设置自然适用于元学习目的，因为定制的奖励函数只能在测试时给出。

英文原文：[Jabri, et al. (2019)](https://arxiv.org/abs/1912.04226) developed an automatic curriculum, CARML (short for “Curricula for Unsupervised Meta-Reinforcement Learning”), by modeling unsupervised trajectories into a latent skill space, with a focus on training [meta-RL](https://lilianweng.github.io/posts/2019-06-23-meta-rl/) policies (i.e. can transfer to unseen tasks). The setting of training environments in CARML is similar to [DIAYN](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#learning-with-random-rewards). Differently, CARML is trained on pixel-level observations but DIAYN operates on the true state space. An RL algorithm 

$\pi_\theta$, parameterized by `\theta`, is trained via unsupervised interaction formulated as a CMP combined with a learned reward function `r`. This setting naturally works for the meta-learning purpose, since a customized reward function can be given only at the test time.

![An illustration of CARML, containing two steps: (1) organizing experiential data into the latent skill space; (2) meta-training the policy with the reward function constructed from the learned skills. (Image source: Jabri, et al 2019 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/CARML.png)

CARML 被构建为 [变分期望最大化 (EM)](https://chrischoy.github.io/research/Expectation-Maximization-and-Variational-Inference/)。

> CARML is framed as a [variational Expectation-Maximization (EM)](https://chrischoy.github.io/research/Expectation-Maximization-and-Variational-Inference/).

(1) **E 步**: 这是组织经验数据的阶段。收集到的轨迹通过潜在组件的混合进行建模，这些组件构成了 [基础](https://en.wikipedia.org/wiki/Basis_(linear_algebra)) 的 *技能*。

> (1) **E-Step**: This is the stage for organizing experiential data. Collected trajectories are modeled with a mixture of latent components forming the [basis](https://en.wikipedia.org/wiki/Basis_(linear_algebra)) of *skills*.

令 $z$ 为潜在任务变量，$q_\phi$ 为 $z$ 的变分分布，这可能是一个具有离散 $z$ 的混合模型，或一个具有连续 $z$ 的 VAE。变分后验 $q_\phi(z \vert s)$ 像一个分类器一样工作，根据给定状态预测技能，我们希望最大化 $q_\phi(z \vert s)$ 以尽可能区分由不同技能产生的数据。在 E 步中，$q_\phi$ 被拟合到由 $\pi_\theta$ 产生的一组轨迹。

> Let $z$ be a latent task variable and $q_\phi$ be a variational distribution of $z$, which could be a mixture model with discrete $z$ or a VAE with continuous $z$. A variational posterior $q_\phi(z \vert s)$ works like a classifier, predicting a skill given a state, and we would like to maximize $q_\phi(z \vert s)$ to discriminate between data produced by different skills as much as possible. In E-step, $q_\phi$ is fitted to a set of trajectories produced by $\pi_\theta$.

具体来说，给定一条轨迹$\tau = (s_1,\dots,s_T)$，我们希望找到$\phi$，使得

> Precisely, given a trajectory $\tau = (s_1,\dots,s_T)$, we would like to find $\phi$ such that

$$
\max_\phi \mathbb{E}_{z\sim q_\phi(z)} \big[ \log q_\phi(\tau \vert z) \big]
= \max_\phi \mathbb{E}_{z\sim q_\phi(z)} \big[ \sum_{s_i \in \tau} \log q_\phi(s_i \vert z) \big]
$$

这里做了一个简化假设，即忽略一条轨迹中状态的顺序。

> A simplifying assumption is made here to ignore the order of states in one trajectory.

(2) **M-Step**: 这是使用$\pi_\theta$进行元强化学习训练的阶段。学习到的技能空间被视为一个训练任务分布。CARML 对用于策略参数更新的元强化学习算法类型是不可知的。

英文原文：(2) M-Step: This is the stage for doing meta-RL training with 

$\pi_\theta$. The learned skill space is considered as a training task distribution. CARML is agnostic to the type of meta-RL algorithm for policy parameter updates.

给定轨迹 $\tau$，策略最大化 $\tau$ 和 $z$ 之间的互信息 $I(\tau;z) = H(\tau) - H(\tau \vert z)$ 是有意义的，因为：

> Given a trajectory $\tau$, it makes sense for the policy to maximize the mutual information between $\tau$ and $z$, $I(\tau;z) = H(\tau) - H(\tau \vert z)$, because:

• 最大化 $H(\tau)$ => 策略数据空间的多样性；预期会很大。

• 最小化 $H(\tau \vert z)$ => 给定特定技能，行为应受限制；预期会很小。

英文原文：

• maximizing $H(\tau)$ => diversity in the policy data space; expected to be large.

• minimizing $H(\tau \vert z)$ => given a certain skill, the behavior should be restricted; expected to be small.

那么我们有，

> Then we have,

$$
\begin{aligned}
I(\tau; z) 
&= \mathcal{H}(z) - \mathcal{H}(z \vert s_1,\dots, s_T) \\
&\geq \mathbb{E}_{s \in \tau} [\mathcal{H}(z) - \mathcal{H}(z\vert s)] & \scriptstyle{\text{; discard the order of states.}} \\
&= \mathbb{E}_{s \in \tau} [\mathcal{H}(s_t) - \mathcal{H}(s\vert z)] & \scriptstyle{\text{; by definition of MI.}} \\
&= \mathbb{E}_{z\sim q_\phi(z), s\sim \pi_\theta(s|z)} [\log q_\phi(s|z) - \log \pi_\theta(s)] \\
&\approx \mathbb{E}_{z\sim q_\phi(z), s\sim \pi_\theta(s|z)} [\color{green}{\log q_\phi(s|z) - \log q_\phi(s)}] & \scriptstyle{\text{; assume learned marginal distr. matches policy.}}
\end{aligned}
$$

我们可以将奖励设置为 $\log q_\phi(s \vert z) - \log q_\phi(s)$，如上式红色部分所示。为了平衡任务特定探索（如下方红色所示）和潜在技能匹配（如下方蓝色所示），添加了一个参数 $\lambda \in [0, 1]$。$z \sim q_\phi(z)$ 的每个实现都会引出一个奖励函数 $r_z(s)$（请记住奖励 + CMP => MDP），如下所示：

> We can set the reward as $\log q_\phi(s \vert z) - \log q_\phi(s)$, as shown in the red part in the equation above. In order to balance between task-specific exploration (as in red below) and latent skill matching (as in blue below) , a parameter $\lambda \in [0, 1]$ is added. Each realization of $z \sim q_\phi(z)$ induces a reward function $r_z(s)$ (remember that reward + CMP => MDP) as follows:

$$
\begin{aligned}
r_z(s)
&= \lambda \log q_\phi(s|z) - \log q_\phi(s) \\
&= \lambda \log q_\phi(s|z) - \log \frac{q_\phi(s|z) q_\phi(z)}{q_\phi(z|s)} \\
&= \lambda \log q_\phi(s|z) - \log q_\phi(s|z) - \log q_\phi(z) + \log q_\phi(z|s) \\
&= (\lambda - 1) \log \color{red}{q_\phi(s|z)} + \color{blue}{\log q_\phi(z|s)} + C
\end{aligned}
$$

![The algorithm of CARML. (Image source: Jabri, et al 2019 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/CARML-algorithm.png)

学习潜在技能空间可以通过不同的方式完成，例如在 [Hausman, et al. 2018](https://openreview.net/forum?id=rk07ZXZRb) 中。他们方法的目标是学习一个任务条件策略 $\pi(a \vert s, t^{(i)})$，其中 $t^{(i)}$ 来自一个包含 $N$ 个任务的离散列表 $\mathcal{T} = [t^{(1)}, \dots, t^{(N)}]$。然而，与其学习 $N$ 个单独的解决方案（每个任务一个），不如学习一个潜在技能空间，这样每个任务都可以用技能分布来表示，从而使技能在 *任务之间重用*。策略定义为 $\pi_\theta(a \vert s,t) = \int \pi_\theta(a \vert z,s,t) p_\phi(z \vert t)\mathrm{d}z$，其中 $\pi_\theta$ 和 $p_\phi$ 分别是要学习的策略网络和嵌入网络。如果 $z$ 是离散的，即从一组 $K$ 技能中抽取，那么策略就变成了 $K$ 个子策略的混合。策略训练使用 [SAC](http://127.0.0.1:4000/lil-log/2018/04/07/policy-gradient-algorithms.html#sac)，并且对 $z$ 的依赖性被引入到熵项中。

> Learning a latent skill space can be done in different ways, such as in [Hausman, et al. 2018](https://openreview.net/forum?id=rk07ZXZRb). The goal of their approach is to learn a task-conditioned policy, $\pi(a \vert s, t^{(i)})$, where $t^{(i)}$ is from a discrete list of $N$ tasks, $\mathcal{T} = [t^{(1)}, \dots, t^{(N)}]$. However, rather than learning $N$ separate solutions, one per task, it would be nice to learn a latent skill space so that each task could be represented in a distribution over skills and thus skills are *reused between tasks*. The policy is defined as $\pi_\theta(a \vert s,t) = \int \pi_\theta(a \vert z,s,t) p_\phi(z \vert t)\mathrm{d}z$, where $\pi_\theta$ and $p_\phi$ are policy and embedding networks to learn, respectively. If $z$ is discrete, i.e. drawn from a set of $K$ skills, then the policy becomes a mixture of $K$ sub-policies. The policy training uses [SAC](http://127.0.0.1:4000/lil-log/2018/04/07/policy-gradient-algorithms.html#sac) and the dependency on $z$ is introduced in the entropy term.

### 通过蒸馏的课程

> Curriculum through Distillation

[我思考这个部分的名称有一段时间了，在克隆、继承和蒸馏之间做选择。最终，我选择了蒸馏，因为它听起来最酷 B-)]

> [I was thinking of the name of this section for a while, deciding between cloning, inheritance, and distillation. Eventually, I picked distillation because it sounds the coolest B-)]

**渐进式神经网络**（[Rusu 等人 2016](https://arxiv.org/abs/1606.04671)）架构的动机是有效地在不同任务之间迁移学习到的技能，同时避免灾难性遗忘。该课程通过一组渐进堆叠的神经网络塔（或如论文中所述的“列”）来实现。

> The motivation for the **progressive neural network** ([Rusu et al. 2016](https://arxiv.org/abs/1606.04671)) architecture is to efficiently transfer learned skills between different tasks and in the meantime avoid catastrophic forgetting. The curriculum is realized through a set of progressively stacked neural network towers (or “columns”, as in the paper).

渐进式网络具有以下结构：

> A progressive network has the following structure:

1\. 它从一个包含 $L$ 层神经元的单列开始，其中相应的激活层被标记为 $h^{(1)}_i, i=1, \dots, L$。我们首先将这个单列网络训练一个任务直至收敛，获得参数配置 $\theta^{(1)}$。

2\. 一旦切换到下一个任务，我们需要添加一个新列以适应新上下文，同时冻结 $\theta^{(1)}$ 以锁定从前一个任务中学到的技能。新列的激活层被标记为 $h^{(2)}_i, i=1, \dots, L$，参数为 $\theta^{(2)}$。

3\. 步骤2可以针对每个新任务重复。第$i$层激活在第$k$列中取决于所有现有列中的先前激活层：其中$W^{(k)}_i$是层$i$在列$k$中；$U_i^{(k:j)}, j < k$是用于将层$i-1$的列$j$投影到层$i$的列$k$（$j < k$）。上述权重矩阵应通过学习获得。$f(.)$是一个可选的非线性激活函数。

英文原文：

1\. 
It starts with a single column containing $L$ layers of neurons, in which the corresponding activation layers are labelled as $h^{(1)}_i, i=1, \dots, L$. We first train this single-column network for one task to convergence, achieving parameter config $\theta^{(1)}$.


2\. 
Once switch to the next task, we need to add a new column to adapt to the new context while freezing $\theta^{(1)}$ to lock down the learned skills from the previous task. The new column has activation layers labelled as $h^{(2)}_i, i=1, \dots, L$, and parameters $\theta^{(2)}$.


3\. 
Step 2 can be repeated with every new task. The $i$ -th layer activation in the $k$ -th column depends on the previous activation layers in all the existing columns:

where $W^{(k)}_i$ is the weight matrix of the layer $i$ in the column $k$; $U_i^{(k:j)}, j < k$ are the weight matrices for projecting the layer $i-1$ of the column $j$ to the layer $i$ of column $k$ ($j < k$). The above weights matrices should be learned. $f(.)$ is a non-linear activation function by choice.


$$
h^{(k)}_i = f(W^{(k)}_i h^{(k)}_{i-1} + \sum_{j < k} U_i^{(k:j)} h^{(j)}_{i-1})
$$

![The progressive neural network architecture. (Image source: Rusu, et al. 2017 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/progressive-networks.png)

该论文通过在多个雅达利游戏中训练一个渐进网络来实验，以检查在一个游戏中学习到的特征是否可以迁移到另一个游戏。事实确实如此。然而有趣的是，对前几列特征的高度依赖并不总是意味着在新任务上具有良好的迁移性能。一个假设是，从旧任务中学到的特征可能会给新任务引入偏差，导致策略陷入次优解。总的来说，渐进网络比仅微调顶层效果更好，并且可以实现与微调整个网络相似的迁移性能。

> The paper experimented with Atari games by training a progressive network on multiple games to check whether features learned in one game can transfer to another. That is indeed the case. Though interestingly, learning a high dependency on features in the previous columns does not always indicate good transfer performance on the new task. One hypothesis is that features learned from the old task might introduce biases into the new task, leading to policy getting trapped in a sub-optimal solution. Overall, the progressive network works better than only fine-tuning the top layer and can achieve similar transfer performance as fine-tuning the entire network.

渐进网络的一个用例是进行sim2real迁移([Rusu, et al. 2017](https://arxiv.org/abs/1610.04286))，其中第一列在模拟器中用大量样本进行训练，然后添加额外的列（可以用于不同的真实世界任务），并用少量真实数据样本进行训练。

> One use case for the progressive network is to do sim2real transfer ([Rusu, et al. 2017](https://arxiv.org/abs/1610.04286)), in which the first column is trained in simulator with a lot of samples and then the additional columns (could be for different real-world tasks) are added and trained with a few real data samples.

[Czarnecki 等人 (2018)](https://arxiv.org/abs/1806.01780) 提出了另一种强化学习训练框架，**Mix & Match**（简称 **M&M**），通过在智能体之间复制知识来提供课程。给定一个从简单到复杂的智能体序列，$\pi_1, \dots, \pi_K$，每个智能体都通过一些共享权重（例如，通过共享一些较低的公共层）进行参数化。M&M 训练一个智能体混合体，但只有最复杂的智能体的最终性能 `\pi_K` 才重要。

英文原文：[Czarnecki, et al. (2018)](https://arxiv.org/abs/1806.01780) proposed another RL training framework, Mix & Match (short for M&M) to provide curriculum through coping knowledge between agents. Given a sequence of agents from simple to complex, 

$\pi_1, \dots, \pi_K$, each parameterized with some shared weights (e.g. by shared some lower common layers). M&M trains a mixture of agents, but only the final performance of the most complex one `\pi_K` matters.

与此同时，M&M 学习一个分类分布 $c \sim \text{Categorical}(1, \dots, K \vert \alpha)$，其 [概率质量函数](https://en.wikipedia.org/wiki/Probability_mass_function) $p(c=i) = \alpha_i$ 概率用于在给定时间选择使用哪个策略。混合的 M&M 策略是一个简单的加权和：$\pi_\text{mm}(a \vert s) = \sum_{i=1}^K \alpha_i \pi_i(a \vert s)$。课程学习通过动态调整 $\alpha_i$ 来实现，从 $\alpha_K=0$ 到 $\alpha_K=1$。$\alpha$ 的调整可以是手动的，也可以通过 [基于种群的训练](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#hyperparameter-tuning-pbt) 进行。

> In the meantime, M&M learns a categorical distribution $c \sim \text{Categorical}(1, \dots, K \vert \alpha)$ with [pmf](https://en.wikipedia.org/wiki/Probability_mass_function) $p(c=i) = \alpha_i$ probability to pick which policy to use at a given time. The mixed M&M policy is a simple weighted sum: $\pi_\text{mm}(a \vert s) = \sum_{i=1}^K \alpha_i \pi_i(a \vert s)$. Curriculum learning is realized by dynamically adjusting $\alpha_i$, from $\alpha_K=0$ to $\alpha_K=1$. The tuning of $\alpha$ can be manual or through [population-based training](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#hyperparameter-tuning-pbt).

为了鼓励策略之间的合作而非竞争，除了 RL 损失 $\mathcal{L}_\text{RL}$ 之外，还添加了另一个 [蒸馏](https://arxiv.org/abs/1511.06295) 状损失 $\mathcal{L}_\text{mm}(\theta)$。知识迁移损失 $\mathcal{L}_\text{mm}(\theta)$ 衡量了两个策略之间的 KL 散度，$\propto D_\text{KL}(\pi_{i}(. \vert s) | \pi_j(. \vert s))$ 用于 $i < j$。它鼓励复杂的智能体在早期与简单的智能体匹配。最终损失是 $\mathcal{L} = \mathcal{L}_\text{RL}(\theta \vert \pi_\text{mm}) + \lambda \mathcal{L}_\text{mm}(\theta)$。

> To encourage cooperation rather than competition among policies, besides the RL loss $\mathcal{L}_\text{RL}$, another [distillation](https://arxiv.org/abs/1511.06295)-like loss $\mathcal{L}_\text{mm}(\theta)$ is added. The knowledge transfer loss $\mathcal{L}_\text{mm}(\theta)$ measures the KL divergence between two policies, $\propto D_\text{KL}(\pi_{i}(. \vert s) | \pi_j(. \vert s))$ for $i < j$. It encourages complex agents to match the simpler ones early on. The final loss is $\mathcal{L} = \mathcal{L}_\text{RL}(\theta \vert \pi_\text{mm}) + \lambda \mathcal{L}_\text{mm}(\theta)$.

![The Mix & Match architecture for training a mixture of policies.  (Image source: Czarnecki, et al., 2018 )](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/mix-and-match.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Jan 2020). 强化学习的课程. Lil’Log. https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/.

> Weng, Lilian. (Jan 2020). Curriculum for reinforcement learning. Lil’Log. https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/.

或

> Or

```
@article{weng2020curriculum,
  title   = "Curriculum for Reinforcement Learning",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2020",
  month   = "Jan",
  url     = "https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/"
}
```

### 参考文献

> References

[1] Jeffrey L. Elman. [“神经网络中的学习与发展：从小处着手的重要性。”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.128.4487&rep=rep1&type=pdf) Cognition 48.1 (1993): 71-99.

> [1] Jeffrey L. Elman. [“Learning and development in neural networks: The importance of starting small.”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.128.4487&rep=rep1&type=pdf) Cognition 48.1 (1993): 71-99.

[2] Yoshua Bengio, et al. [“课程学习。”](https://www.researchgate.net/profile/Y_Bengio/publication/221344862_Curriculum_learning/links/546cd2570cf2193b94c577ac/Curriculum-learning.pdf) ICML 2009.

> [2] Yoshua Bengio, et al. [“Curriculum learning.”](https://www.researchgate.net/profile/Y_Bengio/publication/221344862_Curriculum_learning/links/546cd2570cf2193b94c577ac/Curriculum-learning.pdf) ICML 2009.

[3] Daphna Weinshall, Gad Cohen, and Dan Amir. [“通过迁移学习进行课程学习：深度网络的理论与实验。”](https://arxiv.org/abs/1802.03796) ICML 2018.

> [3] Daphna Weinshall, Gad Cohen, and Dan Amir. [“Curriculum learning by transfer learning: Theory and experiments with deep networks.”](https://arxiv.org/abs/1802.03796) ICML 2018.

[4] Wojciech Zaremba and Ilya Sutskever. [“学习执行。”](https://arxiv.org/abs/1410.4615) arXiv preprint arXiv:1410.4615 (2014).

> [4] Wojciech Zaremba and Ilya Sutskever. [“Learning to execute.”](https://arxiv.org/abs/1410.4615) arXiv preprint arXiv:1410.4615 (2014).

[5] Tambet Matiisen, et al. [“师生课程学习。”](https://arxiv.org/abs/1707.00183) IEEE Trans. on neural networks and learning systems (2017).

> [5] Tambet Matiisen, et al. [“Teacher-student curriculum learning.”](https://arxiv.org/abs/1707.00183) IEEE Trans. on neural networks and learning systems (2017).

[6] Alex Graves, et al. [“神经网络的自动化课程学习。”](https://arxiv.org/abs/1704.03003) ICML 2017.

> [6] Alex Graves, et al. [“Automated curriculum learning for neural networks.”](https://arxiv.org/abs/1704.03003) ICML 2017.

[7] Remy Portelas, et al. [用于连续参数化环境中深度强化学习课程学习的教师算法](https://arxiv.org/abs/1910.07224). CoRL 2019.

> [7]  Remy Portelas, et al. [Teacher algorithms for curriculum learning of Deep RL in continuously parameterized environments](https://arxiv.org/abs/1910.07224). CoRL 2019.

[8] Sainbayar Sukhbaatar, et al. [“通过非对称自博弈实现内在动机和自动课程。”](https://arxiv.org/abs/1703.05407) ICLR 2018.

> [8] Sainbayar Sukhbaatar, et al. [“Intrinsic Motivation and Automatic Curricula via Asymmetric Self-Play.”](https://arxiv.org/abs/1703.05407) ICLR 2018.

[9] Carlos Florensa, et al. [“强化学习智能体的自动目标生成”](https://arxiv.org/abs/1705.06366) ICML 2019.

> [9] Carlos Florensa, et al. [“Automatic Goal Generation for Reinforcement Learning Agents”](https://arxiv.org/abs/1705.06366) ICML 2019.

[10] Sebastien Racaniere & Andrew K. Lampinen, et al. [“通过设置者-解决者交互实现的自动化课程”](https://arxiv.org/abs/1909.12892) ICLR 2020.

> [10] Sebastien Racaniere & Andrew K. Lampinen, et al. [“Automated Curriculum through Setter-Solver Interactions”](https://arxiv.org/abs/1909.12892) ICLR 2020.

[11] Allan Jabri, et al. [“视觉元强化学习的无监督课程”](https://arxiv.org/abs/1912.04226) NeuriPS 2019.

> [11] Allan Jabri, et al. [“Unsupervised Curricula for Visual Meta-Reinforcement Learning”](https://arxiv.org/abs/1912.04226) NeuriPS 2019.

[12] Karol Hausman, et al. [“学习可迁移机器人技能的嵌入空间“](https://openreview.net/forum?id=rk07ZXZRb) ICLR 2018.

> [12] Karol Hausman, et al. [“Learning an Embedding Space for Transferable Robot Skills “](https://openreview.net/forum?id=rk07ZXZRb) ICLR 2018.

[13] Josh Merel, et al. [“用于视觉引导全身运动和物体操作的可重用神经技能嵌入”](https://arxiv.org/abs/1911.06636) arXiv preprint arXiv:1911.06636 (2019).

> [13] Josh Merel, et al. [“Reusable neural skill embeddings for vision-guided whole body movement and object manipulation”](https://arxiv.org/abs/1911.06636) arXiv preprint arXiv:1911.06636 (2019).

[14] OpenAI, et al. [“用机器人手解决魔方。”](https://arxiv.org/abs/1910.07113) arXiv preprint arXiv:1910.07113 (2019).

> [14] OpenAI, et al. [“Solving Rubik’s Cube with a Robot Hand.”](https://arxiv.org/abs/1910.07113) arXiv preprint arXiv:1910.07113 (2019).

[15] Niels Justesen, et al. [“通过程序化关卡生成阐明深度强化学习中的泛化能力”](https://arxiv.org/abs/1806.10729) NeurIPS 2018 Deep RL Workshop.

> [15] Niels Justesen, et al. [“Illuminating Generalization in Deep Reinforcement Learning through Procedural Level Generation”](https://arxiv.org/abs/1806.10729) NeurIPS 2018 Deep RL Workshop.

[16] Karl Cobbe, et al. [“量化强化学习中的泛化能力”](https://arxiv.org/abs/1812.02341) arXiv preprint arXiv:1812.02341 (2018).

> [16] Karl Cobbe, et al. [“Quantifying Generalization in Reinforcement Learning”](https://arxiv.org/abs/1812.02341) arXiv preprint arXiv:1812.02341 (2018).

[17] Andrei A. Rusu et al. [“渐进式神经网络”](https://arxiv.org/abs/1606.04671) arXiv preprint arXiv:1606.04671 (2016).

> [17] Andrei A. Rusu et al. [“Progressive Neural Networks”](https://arxiv.org/abs/1606.04671) arXiv preprint arXiv:1606.04671 (2016).

[18] Andrei A. Rusu et al. [“使用渐进式网络从像素进行模拟到真实机器人学习。”](https://arxiv.org/abs/1610.04286) CoRL 2017.

> [18] Andrei A. Rusu et al. [“Sim-to-Real Robot Learning from Pixels with Progressive Nets.”](https://arxiv.org/abs/1610.04286) CoRL 2017.

[19] Wojciech Marian Czarnecki, et al. [“混合与匹配 – 强化学习的智能体课程。”](https://arxiv.org/abs/1806.01780) ICML 2018.

> [19] Wojciech Marian Czarnecki, et al. [“Mix & Match – Agent Curricula for Reinforcement Learning.”](https://arxiv.org/abs/1806.01780) ICML 2018.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Curriculum Learning | 课程学习 | 一种训练策略，通过从简单到复杂逐步引入训练样本或任务来加速模型学习。 |
| Reinforcement Learning (RL) | 强化学习 | 机器学习的一个分支，智能体通过与环境交互学习如何做出决策以最大化累积奖励。 |
| Generalization | 泛化能力 | 模型在未见过的数据或任务上表现良好的能力。 |
| Procedural Content Generation (PCG) | 程序化内容生成 | 通过算法随机性和人类专业知识自动创建游戏关卡或其他内容的方法。 |
| Teacher-Student Curriculum Learning (TSCL) | 师生课程学习 | 一种自动课程学习框架，其中一个“教师”智能体选择任务来指导“学生”智能体的训练过程。 |
| Self-Play | 自博弈 | 一种训练范式，智能体通过与自身的多个副本或不同目标副本进行交互来学习。 |
| Generative Adversarial Network (GAN) | 生成对抗网络 | 一种深度学习模型，通过生成器和判别器之间的对抗过程来学习生成新的数据样本。 |
| Goals of Intermediate Difficulty (GOID) | 中等难度目标 | 在自动目标生成中，指对于当前策略而言，既不太难也不太容易实现的目标集合。 |
| Meta Reinforcement Learning (Meta-RL) | 元强化学习 | 旨在使智能体能够快速适应新任务或未见环境的强化学习方法。 |
| Progressive Neural Networks | 渐进式神经网络 | 一种神经网络架构，通过堆叠新列来学习新任务，同时冻结旧列以避免灾难性遗忘并迁移技能。 |
| Knowledge Distillation | 知识蒸馏 | 将一个大型复杂模型的知识迁移到一个小型简单模型的过程，常用于模型压缩或课程学习。 |
| Catastrophic Forgetting | 灾难性遗忘 | 神经网络在学习新任务时，对之前学到的任务性能急剧下降的现象。 |
| Automatic Domain Randomization (ADR) | 自动域随机化 | 一种通过随机化环境参数来生成复杂环境分布，从而创建课程的方法。 |
| Partially Observable Markov Decision Process (POMDP) | 部分可观测马尔可夫决策过程 | 一种马尔可夫决策过程的泛化，其中智能体无法直接观测到环境的完整状态。 |
| KL Divergence | KL散度 | 衡量两个概率分布之间差异的非对称度量。 |
