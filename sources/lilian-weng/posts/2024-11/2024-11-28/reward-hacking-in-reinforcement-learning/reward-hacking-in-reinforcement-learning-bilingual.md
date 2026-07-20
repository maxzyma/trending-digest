# 强化学习中的奖励欺骗

> Reward Hacking in Reinforcement Learning

> 来源：Lil'Log / Lilian Weng，2024-11-28
> 原文链接：https://lilianweng.github.io/posts/2024-11-28-reward-hacking/
> 分类：人工智能 / 奖励欺骗

## 核心要点

- 强化学习中的奖励欺骗指智能体利用奖励函数缺陷或模糊性，在未完成预期任务的情况下获得高奖励。
- 奖励欺骗的产生源于强化学习环境的不完善性、奖励函数指定的挑战性以及算法对奖励的高度优化。
- 在大型语言模型（LLM）结合人类反馈强化学习（RLHF）的背景下，奖励欺骗已成为一个关键的实际挑战，可能导致模型学习误导人类或迎合用户。
- 奖励欺骗主要分为环境或目标错配（优化与真实目标不符的代理奖励）和奖励篡改（直接干扰奖励机制）两种类型。
- 古德哈特定律揭示了奖励欺骗的普遍性，即当衡量标准成为优化目标时，它便不再是可靠的衡量标准。
- 研究表明，能力更强的模型（如更大规模、更高分辨率）在优化代理奖励时，其真实任务表现可能反而下降，加剧了奖励欺骗。
- 大型语言模型作为评估器时，其固有的自我偏见和位置偏见可能被利用，导致评估结果失真，进而引发奖励攻击。
- 上下文内奖励攻击（ICRH）是一种在部署时通过反馈循环发生的奖励欺骗，它由LLM的通才特性驱动，且可能随模型规模扩大而加剧。
- 奖励欺骗行为具有跨任务泛化能力，甚至可能导致模型学会直接修改其自身的奖励函数。
- 缓解奖励欺骗的方法包括改进RL算法设计、将其视为异常检测任务进行发现，以及通过对RLHF数据进行系统性分析。

## 正文

奖励欺骗发生在当一个[强化学习 (RL)](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/(https:/lilianweng.github.io/posts/2018-02-19-rl-overview/))智能体[利用](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#exploitation-vs-exploration)奖励函数中的缺陷或模糊性来获得高奖励，而没有真正学习或完成预期任务时。奖励欺骗之所以存在，是因为强化学习环境通常不完善，并且准确指定奖励函数本身就具有挑战性。

> Reward hacking occurs when a [reinforcement learning (RL)](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/(https:/lilianweng.github.io/posts/2018-02-19-rl-overview/)) agent [exploits](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#exploitation-vs-exploration) flaws or ambiguities in the reward function to achieve high rewards, without genuinely learning or completing the intended task. Reward hacking exists because RL environments are often imperfect, and it is fundamentally challenging to accurately specify a reward function.

随着[语言模型](https://lilianweng.github.io/posts/2019-01-31-lm/)在广泛任务中实现泛化，且RLHF成为对齐训练的事实标准方法，语言模型RL训练中的奖励欺骗已成为一个关键的实际挑战。模型学习修改单元测试以通过编码任务的案例，或响应中包含模仿用户偏好的偏差的案例，都相当令人担忧，并且很可能是AI模型更自主用例在实际部署中的主要障碍之一。

> With the rise of [language models](https://lilianweng.github.io/posts/2019-01-31-lm/) generalizing to a broad spectrum of tasks and RLHF becomes a de facto method for alignment training, reward hacking in RL training of language models has become a critical practical challenge. Instances where the model learns to modify unit tests to pass coding tasks, or where responses contain biases that mimic a user’s preference, are pretty concerning and are likely one of the major blockers for real-world deployment of more autonomous use cases of AI models.

过去关于这个话题的大部分工作都相当理论化，侧重于定义或证明奖励欺骗的存在。然而，对实际缓解措施的研究，特别是在RLHF和LLM的背景下，仍然有限。我特别呼吁未来投入更多的研究精力来理解和开发奖励欺骗的缓解措施。希望我很快能在一篇专门的帖子中介绍缓解部分。

> Most of the past work on this topic has been quite theoretical and focused on defining or demonstrating the existence of reward hacking. However, research into practical mitigations, especially in the context of RLHF and LLMs, remains limited. I especially want to call out for more research efforts directed toward understanding and developing mitigation for reward hacking in the future. Hope I will be able to cover the mitigation part in a dedicated post soon.

### 背景

> Background

#### 强化学习中的奖励函数

> Reward Function in RL

奖励函数定义了任务，而奖励塑形显著影响[强化学习](https://lilianweng.github.io/posts/2018-02-19-rl-overview/)中的学习效率和准确性。为强化学习任务设计奖励函数常常感觉像是一门‘黑魔法’。许多因素导致了这种复杂性：你如何将一个大目标分解成小目标？奖励是稀疏的还是密集的？你如何衡量成功？各种选择可能导致良好或有问题的学习动态，包括不可学习的任务或可被利用的奖励函数。关于如何在强化学习中进行奖励塑形的研究历史悠久。

> Reward function defines the task, and reward shaping significantly impacts learning efficiency and accuracy in [reinforcement learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/). Designing a reward function for an RL task often feels like a ‘dark art’. Many factors contribute to this complexity: How you decompose a big goal into small goals? Is the reward sparse or dense? How you measure the success? Various choices may lead to good or problematic learning dynamics, including unlearnable tasks or hackable reward functions. There is a long history of research on how to do reward shaping in RL.

例如，在[Ng 等人于 1999 年发表的一篇论文中](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf)，作者研究了如何修改[马尔可夫决策过程（MDP）](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#markov-decision-processes)中的奖励函数，使得最优策略保持不变。他们发现线性变换是有效的。给定一个 MDP$M = (S, A, T, \gamma, R)$，我们希望创建一个转换后的 MDP$M’ = (S, A, T, \gamma, R’)$，其中$R’ = R + F$和$F: S \times A \times S \mapsto \mathbb{R}$，这样我们就可以引导学习算法更高效。给定一个实值函数$\Phi: S \mapsto \mathbb{R}$，$F$是一个基于势的塑形函数，如果对于所有$s \in S - {s_0}, a \in A, s’ \in S$：

> For example, in an [1999 paper by Ng et al.](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf), the authors studied how to modify the reward function in [Markov Decision Processes (MDPs)](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#markov-decision-processes) such that the optimal policy remains unchanged. They found that linear transformation works. Given a MDP $M = (S, A, T, \gamma, R)$, we want to create a transformed MDP $M’ = (S, A, T, \gamma, R’)$ where $R’ = R + F$ and $F: S \times A \times S \mapsto \mathbb{R}$, such that we can guide the learning algorithm to be more efficient. Given a real-valued function $\Phi: S \mapsto \mathbb{R}$, $F$ is a potential-based shaping function if for all $s \in S - {s_0}, a \in A, s’ \in S$:

$$
F(s, a, s') = \gamma \Phi(s') - \Phi(s)
$$

这将保证折现后的 $F$、$F(s_1, a_1, s_2) + \gamma F(s_2, a_2, s_3) + \dots$ 之和最终为 0。如果 $F$ 是一个基于势的塑形函数，那么它既是 *充分* 的，也是 *必要* 的，以确保 $M$ 和 $M’$ 共享相同的最优策略。

> This would guarantee that the sum of discounted $F$, $F(s_1, a_1, s_2) + \gamma F(s_2, a_2, s_3) + \dots$, ends up being 0. If $F$ is such a potential-based shaping function, it is both *sufficient* and *necessary* to ensure $M$ and $M’$ share the same optimal policies.

当 $F(s, a, s’) = \gamma \Phi(s’) - \Phi(s)$ 时，如果我们进一步假设 $\Phi(s_0) = 0$，其中 $s_0$ 是吸收态，并且 $\gamma=1$，那么对于所有 $s \in S, a \in A$：

> When $F(s, a, s’) = \gamma \Phi(s’) - \Phi(s)$, and if we further assume that $\Phi(s_0) = 0$, where $s_0$ is absorbing state, and $\gamma=1$, and then for all $s \in S, a \in A$:

$$
\begin{aligned}
Q^*_{M'} (s,a) &= Q^*_M(s, a) - \Phi(s) \\
V^*_{M'} (s,a) &= V^*_M(s, a) - \Phi(s)
\end{aligned}
$$

这种形式的奖励塑形允许我们将启发式方法纳入奖励函数，以加速学习，同时不影响最优策略。

> This form of reward shaping allows us to incorporate heuristics into the reward function to speed up learning without impacting the optimal policy.

#### 虚假相关

> Spurious Correlation

分类任务中的虚假相关或捷径学习（[Geirhos et al. 2020](https://arxiv.org/abs/2004.07780)）是一个与奖励作弊密切相关的概念。虚假或捷径特征可能导致分类器无法按预期学习和泛化。例如，如果所有狼的训练图像都包含雪，那么用于区分狼和哈士奇的二元分类器可能会过度拟合雪景背景（[Ribeiro et al. 2024](https://arxiv.org/abs/1602.04938)）。

> Spurious correlation or shortcut learning ([Geirhos et al. 2020](https://arxiv.org/abs/2004.07780)) in classification task is a concept closely related to reward hacking. Spurious or shortcut features can cause a classifier to fail at learning and generalizing as intended. For example, a binary classifier for distinguishing wolves from huskies may overfit to the presence of a snowy background if all the wolf training images include snow ([Ribeiro et al. 2024](https://arxiv.org/abs/1602.04938)).

![The model performs poorly on out-of-distribution (OOD) test sets if it overfits to shortcut features. (Image source: Geirhos et al. 2020 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/shortcut-features.png)

[ERM原则](https://en.wikipedia.org/wiki/Empirical_risk_minimization)指出，由于完整的数据分布未知，最小化训练数据上的损失是风险的合理替代，因此我们倾向于选择训练损失最低的模型。[Nagarajan et al. (2021)](https://arxiv.org/abs/2010.15775)研究了ERM原则，并指出ERM在尝试无约束地拟合数据时，需要依赖所有类型的信息特征，包括不可靠的虚假特征。他们的实验表明，无论任务多么简单，ERM都会依赖虚假特征。

> The [ERM principle](https://en.wikipedia.org/wiki/Empirical_risk_minimization) states that, since the full data distribution is unknown, minimizing the loss on training data is a reasonable proxy of risk and thus we favor models with the lowest training loss. [Nagarajan et al. (2021)](https://arxiv.org/abs/2010.15775) studied the ERM principle and pointed out that ERM needs to rely on all types of informative features, including unreliable spurious features, while attempting to fit the data without constraints. Their experiments showed that ERM would depend on spurious features no matter how easy the task is.

### 让我们定义奖励作弊

> Let’s Define Reward Hacking

强化学习中的奖励塑形具有挑战性。奖励作弊是指强化学习智能体利用奖励函数中的缺陷或模糊性来获得高奖励，而没有真正学习预期的行为或按设计完成任务。近年来，已经提出了几个相关概念，它们都指某种形式的奖励作弊：

> Reward shaping in RL is challenging. Reward hacking occurs when an RL agent exploits flaws or ambiguities in the reward function to obtain high rewards without genuinely learning the intended behaviors or completing the task as designed. In recent years, several related concepts have been proposed, all referring to some form of reward hacking:

- 奖励作弊（[Amodei et al., 2016](https://arxiv.org/abs/1606.06565)）
- 奖励腐败（[Everitt et al., 2017](https://arxiv.org/abs/1705.08417)）
- 奖励篡改（[Everitt et al. 2019](https://arxiv.org/abs/1908.04734)）
- 规范博弈（[Krakovna et al., 2020](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/)）
- 目标鲁棒性（[Koch et al. 2021](https://www.gatsby.ucl.ac.uk/~balaji/udl2021/accepted-papers/UDL2021-paper-055.pdf)）
- 目标泛化错误 ([Langosco et al. 2022](https://arxiv.org/abs/2105.14111))
- 奖励错配 ([Pan et al. 2022](https://arxiv.org/abs/2201.03544))

> • Reward hacking ([Amodei et al., 2016](https://arxiv.org/abs/1606.06565))
> • Reward corruption ([Everitt et al., 2017](https://arxiv.org/abs/1705.08417))
> • Reward tampering ([Everitt et al. 2019](https://arxiv.org/abs/1908.04734))
> • Specification gaming ([Krakovna et al., 2020](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/))
> • Objective robustness ([Koch et al. 2021](https://www.gatsby.ucl.ac.uk/~balaji/udl2021/accepted-papers/UDL2021-paper-055.pdf))
> • Goal misgeneralization ([Langosco et al. 2022](https://arxiv.org/abs/2105.14111))
> • Reward misspecifications ([Pan et al. 2022](https://arxiv.org/abs/2201.03544))

这个概念起源于 Amodei et al. (2016)，他们在其开创性论文 [“Concrete Problems in AI Safety”](https://arxiv.org/abs/1606.06565) 中提出了一系列关于人工智能安全的研究问题。他们将 **奖励欺骗** 列为关键的人工智能安全问题之一。奖励欺骗指的是智能体通过不期望的行为来操纵奖励函数以获得高奖励的可能性。**规范博弈** ([Krakovna et al. 2020](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/)) 是一个类似的概念，定义为一种行为，它满足了目标字面上的规范，但未能达到期望的结果。在这里，任务目标的字面描述和预期目标之间可能存在差距。

> The concept originated with Amodei et al. (2016), who proposed a set of open research questions on AI safety in their seminal paper [“Concrete Problems in AI Safety”](https://arxiv.org/abs/1606.06565). They listed **reward hacking** as one of the key AI safety problems. Reward hacking refers to the possibility of the agent gaming the reward function to achieve high reward through undesired behavior.  **Specification gaming** ([Krakovna et al. 2020](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/)) is a similar concept, defined as a behavior that satisfies the literal specification of an objective but not achieving the desired results. Here the literal description of the task goal and the intended goal may have a gap.

奖励塑形是一种用于丰富奖励函数的技术，通过提供更密集的奖励等方式，使智能体更容易学习。然而，设计不佳的奖励塑形机制可能会改变最优策略的轨迹。设计有效的奖励塑形机制本身就很难。与其归咎于设计不佳的奖励函数，不如更准确地承认，由于任务本身的复杂性、部分可观察状态、需要考虑的多个维度以及其他因素，设计一个好的奖励函数本质上是具有挑战性的。

> Reward shaping is a technique used to enrich the reward function, making it easier for the agent to learn—for example, by providing denser rewards. However, a poorly design reward shaping mechanism can alter the trajectory of the optimal policy. Designing effective reward shaping mechanisms is inherently difficult. Rather than blaming a poorly designed reward function, it is more accurate to acknowledge that designing a good reward function is intrinsically challenging due to the complexity of the task itself, partial observable state, multiple dimensions in consideration, and other factors.

在分布外 (OOD) 环境中测试强化学习智能体时，鲁棒性失效可能由于以下原因发生：

> When testing an RL agent in out-of-distribution (OOD) environments, robustness failure may occur due to:

1\. 即使目标正确，模型也未能有效泛化。当算法缺乏足够的智能或能力时，就会发生这种情况。

2\. 模型能够有效地泛化，但追求的目标与训练时的目标不同。当代理奖励与真实奖励函数不同时，就会发生这种情况，$R’ \neq R$。这被称为 **目标鲁棒性** ([Koch et al. 2021](https://www.gatsby.ucl.ac.uk/~balaji/udl2021/accepted-papers/UDL2021-paper-055.pdf)) 或 **目标泛化错误** ([Langosco et al. 2022](https://arxiv.org/abs/2105.14111) )

英文原文：

1\. The model fails to generalize effectively, even with the right objective. This happens when the algorithm lacks sufficient intelligence or capability.

2\. The model generalizes capably but pursues an objective different from the one it was trained on. This happens when the proxy reward differs from the true reward function, $R’ \neq R$. This is known as **objective robustness** ([Koch et al. 2021](https://www.gatsby.ucl.ac.uk/~balaji/udl2021/accepted-papers/UDL2021-paper-055.pdf)) or **goal misgeneralization** ([Langosco et al. 2022](https://arxiv.org/abs/2105.14111) )

在两个强化学习环境 [CoinRun](https://github.com/openai/coinrun) 和 [Maze](https://github.com/openai/procgen) 中的实验表明了训练期间随机化的重要性。如果在训练期间，硬币或奶酪被放置在固定位置（即关卡的右端或迷宫的右上角），但在测试环境中硬币或奶酪被随机放置，那么智能体在测试时只会跑到固定位置而无法获得硬币或奶酪。当视觉特征（例如，奶酪或硬币）和位置特征（例如，右上角或右端）在测试时出现不一致时，就会产生冲突，导致训练好的模型偏好位置特征。我想指出的是，在这两个例子中，*奖励-结果差距* 是明显的，但在大多数现实世界案例中，这种类型的偏差不太可能如此明显。

> Experiments in two RL environments, [CoinRun](https://github.com/openai/coinrun) and [Maze](https://github.com/openai/procgen), demonstrated the importance of randomization during training. If during training, the coin or the cheese is placed at a fixed position (i.e. right end of the level or upper right corner of the maze) but testing in the env where the coin or cheese is placed at random, the agent would just run to the fixed position without obtaining the coin or cheese at test time. A conflict arises when a visual feature (e.g., cheese or coin) and a positional feature (e.g., upper-right or right end) are inconsistent during test time, leading the trained model to prefer the positional feature. I would like to point out that, in these two examples, the *reward-result gaps* are clear but such type of biases are unlikely to be so obvious in most real-world cases.

![The impact of randomizing the position of the coin during training. When the coin is placed at random for {0, 2, 3, 6, 11}% of the time during training (x-axis), the frequency of the agent navigating to the end of the level without obtaining the coin decreases with the increase of the randomization ("y-axis"). (Image source: Koch et al. 2021 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/coinrun-randomization.png)

**奖励篡改** ([Everitt et al. 2019](https://arxiv.org/abs/1908.04734)) 是一种奖励欺骗行为，智能体干扰奖励函数本身，导致观察到的奖励不再准确地代表预期目标。在奖励篡改中，模型通过直接操纵奖励函数的实现或间接改变用作奖励函数输入的环​​境信息来修改其奖励机制。

> **Reward Tampering** ([Everitt et al. 2019](https://arxiv.org/abs/1908.04734)) is a form of reward hacking behavior where the agent interferes with the reward function itself, causing the observed reward to no longer accurately represent the intended goal. In reward tampering, the model modifies its reward mechanism either by directly manipulating the implementation of the reward function or by indirectly altering the environmental information used as input for the reward function.

(注：有些研究将奖励篡改定义为与奖励欺骗不同的失调行为类别。但我在这里将奖励欺骗视为一个更广泛的概念。)

> (Note: Some work defines reward tampering as a distinct category of misalignment behavior from reward hacking. But I consider reward hacking as a broader concept here.)

从宏观层面来看，奖励欺骗可以分为两种类型：环境或目标错配，以及奖励篡改。

> At a high level, reward hacking can be categorized into two types: environment or goal misspecification, and reward tampering.

- **环境或目标错配**：模型通过欺骗环境或优化与真实奖励目标不一致的奖励函数（例如当奖励错配或缺乏关键要求时），学习到不期望的行为以获得高奖励。
- **奖励篡改**：模型学习干扰奖励机制本身。

> • **Environment or goal misspecified**: The model learns undesired behavior to achieve high rewards by hacking the environment or optimizing a reward function not aligned with the true reward objective—such as when the reward is misspecified or lacks key requirements.
> • **Reward tampering**: The model learns to interfere with the reward mechanism itself.

#### 示例列表

> List of Examples

##### 强化学习任务中的奖励欺骗示例

> Reward hacking examples in RL tasks

- 训练来抓取物体的机器人手可以学会通过将手放在物体和摄像头之间来欺骗人们。([Link](https://openai.com/index/learning-from-human-preferences/))
- 训练来最大化跳跃高度的智能体可能会利用物理模拟器中的一个错误来达到不切实际的高度。([Link](https://arxiv.org/abs/1803.03453))
- 智能体被训练骑自行车到一个目标，并且每当它接近目标时都会获得奖励。然后智能体可能会学会在目标周围骑小圈，因为当智能体远离目标时没有惩罚。([Link](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf))
- 在足球比赛设置中，当智能体触球时会获得奖励，智能体学会停留在球旁边，以高频率触球，就像振动一样。([Link](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf))
- 在 [Coast Runners 游戏](https://openai.com/blog/faulty-reward-functions/)中，智能体控制一艘船，目标是尽快完成赛艇比赛。当它因撞击赛道上的绿色方块而获得塑形奖励时，它将最优策略改为绕圈并反复撞击相同的绿色方块。([Link](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/))
- [“数字进化的惊人创造力”](https://arxiv.org/abs/1803.03453) (Lehman et al. 2019) - 这篇论文有许多关于优化错配适应度函数如何导致令人惊讶的“欺骗”或意想不到的进化或学习结果的例子。
- [AI中规范博弈的例子](https://docs.google.com/spreadsheets/d/e/2PACX-1vRPiprOaC3HsCf5Tuum8bRfzYUiKLRqJmbOoC-32JorNdfyTiRRsR7Ea5eWtvsWzuxo8bjOxCG84dAg/pubhtml)列表由[Krakovna et al. 2020](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/)收集。

> • A robot hand trained to grab an object can learn to trick people by placing the hand between the object and the camera. ([Link](https://openai.com/index/learning-from-human-preferences/))
> • An agent trained to maximize jumping height may exploit a bug in the physics simulator to achieve an unrealistically height. ([Link](https://arxiv.org/abs/1803.03453))
> • An agent is trained to ride a bicycle to a goal and wins reward whenever it is getting closer to the goal. Then the agent may learn to ride in tiny circles around the goal because there is no penalty when the agent gets away from the goal. ([Link](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf))
> • In a soccer game setup, the reward is assigned when the agent touches the ball and the agent learns to remain next to the ball to touch the ball in high frequency like in a viberating motion. ([Link](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf))
> • In the [Coast Runners game](https://openai.com/blog/faulty-reward-functions/), an agent controls a boat with the goal to finish the boat race as quickly as possible. When it is given a shaping reward for hitting green blocks along the race track, it changes the optimal policy to going in circles and hitting the same green blocks over and over again. ([Link](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/))
> • [“The Surprising Creativity of Digital Evolution”](https://arxiv.org/abs/1803.03453)  (Lehman et al. 2019) - This paper has many examples about how optimizing a misspecified fitness function can lead to surprising “hacking” or unintended evolutionary or learning results.
> • The list of [specification gaming in AI examples](https://docs.google.com/spreadsheets/d/e/2PACX-1vRPiprOaC3HsCf5Tuum8bRfzYUiKLRqJmbOoC-32JorNdfyTiRRsR7Ea5eWtvsWzuxo8bjOxCG84dAg/pubhtml) is collected by [Krakovna et al. 2020](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/).

##### LLM任务中的奖励作弊示例

> Reward hacking examples in LLM tasks

- 一个用于生成摘要的语言模型能够利用ROUGE指标的缺陷，从而获得高分，但生成的摘要却几乎不可读。（[链接](https://web.archive.org/web/20180215132021/https://www.salesforce.com/products/einstein/ai-research/tl-dr-reinforced-model-abstractive-summarization/)）
- 一个编码模型学会了修改单元测试以通过编程问题。（[链接](https://arxiv.org/abs/2406.10162)）
- 一个编码模型可能会学会直接修改用于计算奖励的代码。（[链接](https://arxiv.org/abs/2406.10162)）

> • A language model for generating summarization is able to explore flaws in the ROUGE metric such that it obtains high score but the generated summaries are barely readable. ([Link](https://web.archive.org/web/20180215132021/https://www.salesforce.com/products/einstein/ai-research/tl-dr-reinforced-model-abstractive-summarization/))
> • A coding model learns to change unit test in order to pass coding questions. ([Link](https://arxiv.org/abs/2406.10162))
> • A coding model may learn to directly modify the code used for calculating the reward. ([Link](https://arxiv.org/abs/2406.10162))

##### 现实生活中的奖励作弊示例

> Reward hacking examples in real life

- 社交媒体的推荐算法旨在提供有用的信息。然而，有用性通常通过代理指标来衡量，例如点赞或评论的数量，或在平台上的参与时间或频率。该算法最终推荐可能影响用户情绪状态的内容，例如令人发指和极端的内容，以触发更多的参与。（[Harari, 2024](https://www.goodreads.com/en/book/show/204927599-nexus)）
- 针对视频分享网站的错误指定代理指标进行优化，可能会积极增加用户的观看时间，而真正的目标是优化用户的主观幸福感。（[链接](https://arxiv.org/abs/2201.03544)）
- [“大空头”](https://en.wikipedia.org/wiki/The_Big_Short) - 2008年由房地产泡沫引起的金融危机。当人们试图操纵金融系统时，我们的社会发生了奖励作弊。

> • The recommendation algorithm for social media is intended to provide useful information. However, usefulness is often measured by proxy metrics, such as the number of likes or comments, or the time or frequency of engagement on the platform. The algorithm ends up recommending content that can affect users’ emotion states such as outrageous and extreme content in order to trigger more engagement. ([Harari, 2024](https://www.goodreads.com/en/book/show/204927599-nexus))
> • Optimizing for misspecified proxy metrics for a video sharing site may aggressively increase the watch time of users while the true goal is to optimize users’ subjective well-being. ([Link](https://arxiv.org/abs/2201.03544))
> • [“The Big Short”](https://en.wikipedia.org/wiki/The_Big_Short) - 2008 financial crisis caused by the housing bubble. Reward hacking of our society happened as people tried to game the financial system.

#### 为什么会存在奖励作弊？

> Why does Reward Hacking Exist?

[古德哈特定律](https://en.wikipedia.org/wiki/Goodhart%27s_law)指出*“当一个衡量标准成为目标时，它就不再是一个好的衡量标准”*。其直觉是，一旦施加显著压力来优化一个好的指标，它就可能被破坏。指定一个100%准确的奖励目标是具有挑战性的，任何*代理*都面临被作弊的风险，因为强化学习算法会利用奖励函数定义中的任何微小缺陷。[Garrabrant (2017)](https://www.lesswrong.com/posts/EbFABnst8LsidYs5Y/goodhart-taxonomy)将古德哈特定律分为4种变体：

> [Goodhart’s Law](https://en.wikipedia.org/wiki/Goodhart%27s_law) states that *“When a measure becomes a target, it ceases to be a good measure”*. The intuition is that a good metric can become corrupted once significant pressure is applied to optimize it. It is challenging to specify a 100% accurate reward objective and any *proxy* suffers the risk of being hacked, as RL algorithm exploits any small imperfection in the reward function definition. [Garrabrant (2017)](https://www.lesswrong.com/posts/EbFABnst8LsidYs5Y/goodhart-taxonomy) categorized Goodhart’s law into 4 variants:

1. 回归性（Regressional） - 对不完美代理的选择必然也会选择噪声。
2. 极值性（Extremal） - 指标选择将状态分布推向不同数据分布的区域。
3. 因果性（Causal） - 当代理与目标之间存在非因果相关性时，干预代理可能无法干预目标。
4. 对抗性（Adversarial） - 对代理的优化为对手提供了将其目标与代理相关联的动机。

> • Regressional - selection for an imperfect proxy necessarily also selects for noise.
> • Extremal - the metric selection pushes the state distribution into a region of different data distribution.
> • Causal -  when there is a non-causal correlation between the proxy and the goal, intervening on the proxy may fail to intervene on the goal.
> • Adversarial - optimization for a proxy provides an incentive for adversaries to correlate their goal with the proxy.

[Amodei et al. (2016)](https://arxiv.org/abs/1606.06565)总结道，奖励作弊（主要在强化学习环境中）可能由于以下原因发生：

> [Amodei et al. (2016)](https://arxiv.org/abs/1606.06565) summarized that reward hacking, mainly in RL setting, may occur due to:

1. 部分观测到的状态和目标是对环境状态的不完美表示。
2. 系统本身复杂且容易被作弊；例如，如果允许智能体执行改变环境部分的代码，那么利用环境机制就变得容易得多。
3. 奖励可能涉及难以学习或表述的抽象概念；例如，具有高维输入的奖励函数可能过度依赖少数几个维度。
4. 强化学习旨在高度优化奖励函数，因此存在固有的“冲突”，使得设计良好的强化学习目标具有挑战性。一个特殊情况是具有自我强化反馈组件的奖励函数类型，其中奖励可能被放大和扭曲到破坏原始意图的程度，例如广告投放算法导致赢家通吃。

> • Partial observed states and goals are imperfect representation of the environment status.
> • The system itself is complex and susceptible to hacking; e.g., if the agent is allowed to execute code that changes part of the environment, it becomes much easier to exploit the environment’s mechanisms.
> • The reward may involve abstract concept that is hard to be learned or formulated; e.g., a reward function with high-dimensional inputs may disproportionately rely on a few dimensions.
> • RL targets to get the reward function highly optimized, so there exists an intrinsic “conflict”, making the design of good RL objective challenging. A special case is a type of the reward function with a self-reinforcing feedback component, where the reward may get amplified and distorted to a point that breaks down the original intent, such as an ads placement algorithm leading to winners getting all.

此外，识别最优智能体优化其行为所依据的确切奖励函数通常是不可能的，因为在固定环境中，可能存在无限数量的奖励函数与任何观察到的策略一致（[Ng & Russell, 2000](https://ai.stanford.edu/~ang/papers/icml00-irl.pdf)）。[Amin and Singh (2016)](https://arxiv.org/abs/1601.06569)将这种*不可识别性*的原因分为两类：

> Besides, identifying the exact reward function for which an optimal agent optimizes its behavior is in general impossible since there could be an infinite number of reward functions consistent with any observed policy in an fixed environment ([Ng & Russell, 2000](https://ai.stanford.edu/~ang/papers/icml00-irl.pdf)). [Amin and Singh (2016)](https://arxiv.org/abs/1601.06569) separated the causes of this *unidentifiability* into two classes:

1\. 表示性（Representational） - 一组奖励函数在某些算术运算（例如，重新缩放）下行为不变。

2\. 实验性（Experimental） - $\pi$的观察行为不足以区分两个或更多奖励函数，这些函数都能解释智能体的行为（行为在这两种情况下都是最优的）。

英文原文：

1\. Representational - a set of reward functions is behaviorally invariant under certain arithmetic operations (e.g., re-scaling)

2\. Experimental - $\pi$’s observed behavior is insufficient to distinguish between two or more reward functions which both rationalize the behavior of the agent (the behavior is optimal under both)

### 攻击强化学习环境

> Hacking RL Environment

随着模型和算法日益复杂，奖励欺骗预计将成为一个更常见的问题。更智能的智能体更有能力在奖励函数设计中发现“漏洞”，并*利用*任务规范——换句话说，获得更高的代理奖励但更低的真实奖励。相比之下，较弱的算法可能无法发现此类漏洞，因此当模型不够强大时，我们不会观察到任何奖励欺骗或识别当前奖励函数设计中的问题。

> Reward hacking is expected to be a more common problem as the model and the algorithm become increasingly sophisticated. A more intelligent agent is more capable of finding “holes” in the design of reward function and *exploiting* the task specification—in other words, achieving higher proxy rewards but lower true rewards. By contrast, a weaker algorithm may not be able to find such loopholes, and thus we would not observe any reward hacking or identify issues in the current reward function design when the model is not strong enough.

在一组零和机器人自博弈游戏中（[Bansal et al., 2017](https://arxiv.org/abs/1710.03748)），我们可以训练两个智能体（受害者 vs. 对手）相互竞争。标准的训练过程会产生一个在对抗普通对手时表现良好的受害者智能体。然而，很容易训练出一种对抗性对手策略，即使输出看似随机的动作并且训练时间步数少于3%（[Gleave et al., 2020](https://arxiv.org/abs/1905.10615)），也能可靠地击败受害者。对抗性策略的训练涉及优化折扣奖励的总和，就像在标准强化学习设置中一样，同时将受害者策略视为黑盒模型。

> In a set of zero-sum robotics self-play games ([Bansal et al., 2017](https://arxiv.org/abs/1710.03748)), we can train two agents (victim vs. opponent) to compete against each other. A standard training process produces a victim agent with adequate performance when playing against a normal opponent. However, it is easy to train an adversarial opponent policy that can defeat the victim reliably despite outputting seemingly random actions and training with fewer than 3% of time steps ([Gleave et al., 2020](https://arxiv.org/abs/1905.10615)). Training of adversarial policies involves optimizing the sum of discounted rewards, as in standard RL setup, while treating the victim policy as a black-box model.

缓解对抗性策略攻击的一种直观方法是针对对抗性策略对受害者进行微调。然而，一旦针对新的受害者策略进行再训练，受害者仍然容易受到新版本对抗性策略的攻击。

> An intuitive way to mitigate adversarial policies attacks is to fine-tune victims against adversarial policies. However, the victim remains vulnerable to new versions of adversarial policies once retrained against the new victim policy.

为什么存在对抗性策略？假设是对抗性策略向受害者引入了OOD观测，而不是对其进行物理干扰。证据表明，当受害者对对手位置的观测被遮蔽并设置为静态时，受害者变得*更具鲁棒性*以对抗对手，尽管在对抗普通对手策略时表现更差。此外，更高维的观测空间在正常情况下能提升性能，但会使策略更容易受到对抗性对手的攻击。

> Why does adversarial policy exist? The hypothesis is that adversarial policies introduce OOD observations to the victim rather than physically interfering with it. Evidence shows that when the victim’s observation of the opponent’s position is masked and set to a static state, the victim becomes *more robust* to adversaries, although performing worse against a normal opponent policy. Furthermore, a higher-dimensional observation space enhances performance under normal circumstances but makes the policy more vulnerable to adversarial opponents.

[Pan et al. (2022)](https://arxiv.org/abs/2201.03544)研究了奖励欺骗作为智能体能力的一个函数，包括（1）模型大小，（2）动作空间分辨率，（3）观测空间噪声，和（4）训练时间。他们还提出了三种错误指定代理奖励的分类法：

> [Pan et al. (2022)](https://arxiv.org/abs/2201.03544) investigated reward hacking as a function of agent capabilities, including (1) model size, (2) action space resolution, (3) observation space noise, and (4) training time. They also proposed a taxonomy of three types of misspecified proxy rewards:

1. *权重错误*：代理奖励和真实奖励捕捉相同的期望目标，但它们在相对重要性上有所不同。
2. *本体论*：代理奖励和真实奖励使用不同的期望目标来捕捉相同的概念。
3. *范围*：代理在受限领域（例如时间或空间）内衡量期望目标，因为在所有条件下进行测量成本过高。

> • *Misweighting*: Proxy and true rewards capture the same desiderata, but differ in their relative importance.
> • *Ontological*: Proxy and true rewards use different desiderata to capture the same concept.
> • *Scope*: The proxy measures desiderata over a restricted domain (e.g. time or space) because measurement across all conditions is too costly.

他们在四个强化学习环境中进行了实验，并搭配了九种错误指定的代理奖励。这些实验的总体发现可以总结如下：*能力更强的模型倾向于获得更高（或相似）的代理奖励，但真实奖励却有所下降。*

> They experimented in four RL environments paired with nine misspecified proxy rewards. The overall findings from these experiments can be summarized as follows: *A model of higher capability tends to obtain higher (or similar) proxy rewards but decreased true rewards.*

- 模型大小：更大的模型尺寸导致代理奖励增加，但真实奖励减少。
- 动作空间分辨率：动作精度的提高会带来更强大的智能体。然而，更高的分辨率导致代理奖励保持不变，而真实奖励下降。
- 观测保真度：更准确的观测改善了代理奖励，但略微降低了真实奖励。
- 训练步数：在奖励最初正相关的一段时间后，通过更多步优化代理奖励会损害真实奖励。

> • Model size: Larger model size leads to increased proxy rewards but decreased true rewards.
> • Action space resolution: Increased precision in actions leads to more capable agents. However, higher resolution causes proxy rewards to remain constant while true rewards decrease.
> • Observation fidelity: More accurate observations improve proxy rewards but slightly reduce true rewards.
> • Training steps: Optimizing the proxy reward over more steps harms true rewards after an initial period where the rewards are positively correlated.

![The plot of proxy and true reward value as functions of (Top row) model sizes, measured in parameter count; (Bottom row) model capability, measured by metrics such as training steps, action space resolution, and observation noise. (Image source: Pan et al. 2022 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/exp-reward-misspecification.png)

如果代理奖励的指定非常糟糕，以至于它与真实奖励的关联性非常弱，我们甚至可以在训练之前识别并防止奖励欺骗。基于这一假设，[Pan et al. (2022)](https://arxiv.org/abs/2201.03544)研究了在一系列轨迹回放中代理奖励和真实奖励之间的相关性。有趣的是，即使真实奖励和代理奖励之间存在正相关，奖励欺骗仍然会发生。

> If a proxy reward is so poorly specified that it has a very weak correlation with the true reward, we may be able to identify and prevent reward hacking even before training. Based on this hypothesis, [Pan et al. (2022)](https://arxiv.org/abs/2201.03544) investigated the correlation between proxy and true rewards over a collection of trajectory rollouts. Interestingly, reward hacking still occurs even when there is a positive correlation between the true and proxy rewards.

### 攻击大型语言模型的RLHF

> Hacking RLHF of LLMs

[人类反馈强化学习（RLHF）](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences)已成为语言模型对齐训练的事实标准方法。奖励模型在人类反馈数据上进行训练，然后通过强化学习对语言模型进行微调，以优化这种代理奖励以符合人类偏好。在RLHF设置中，我们关注三种类型的奖励：

> [Reinforcement learning from human feedback (RLHF)](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences) has become the de facto approach for alignment training of language models. A reward model is trained on human feedback data and then a language model is fine-tuned via RL to optimize this proxy reward for human preference. There are three types of reward we care about in an RLHF setup:

• (1) **预言机/黄金奖励** $R^∗$ 代表我们*真正*希望大型语言模型优化的内容。

• (2) **人类奖励** $R^\text{human}$ 是我们实践中收集用于评估大型语言模型的奖励，通常来自有时间限制的个体人类。由于人类可能提供不一致的反馈或犯错，人类奖励并非预言机奖励的完全准确表示。

• (3) **代理奖励** $R$ 是由在人类数据上训练的奖励模型预测的分数。因此，$R^\text{train}$ 继承了人类奖励的所有弱点，以及潜在的模型偏差。

英文原文：

• (1) **Oracle/Gold reward** $R^∗$ represents what we *truly* want the LLM to optimize.

• (2) **Human reward** $R^\text{human}$ is what we collect to evaluate LLMs in practice, typically from individual humans with time constraints. Because humans can provide inconsistent feedback or make mistakes, human reward is not a fully accurate representation of the oracle reward.

• (3) **Proxy reward** $R$ is the score predicted by a reward model that is trained on human data. Hence, $R^\text{train}$ inherits all the weakness of human reward, plus potential modeling biases.

RLHF优化代理奖励分数，但我们最终关心的是黄金奖励分数。

> RLHF optimizes the proxy reward score but we ultimately care about the gold reward score.

#### 攻击训练过程

> Hacking the Training Process

[Gao et al. (2022)](https://arxiv.org/abs/2210.10760)研究了RLHF中奖励模型过度优化的缩放定律。为了在实验中扩展人类标签，他们使用了一个合成数据设置，其中预言机奖励的“黄金”标签$R^{\ast}$由一个大型奖励模型（60亿参数）近似，而代理奖励模型$R$的大小范围从300万到30亿参数。

> [Gao et al. (2022)](https://arxiv.org/abs/2210.10760) examined the scaling laws for reward model overoptimization in RLHF. To scale up the human labels in their experiments, they use a synthetic data setup where the “gold” label for the oracle reward $R^{\ast}$ is approximated by a large RM (6B parameters) where the proxy RMs for $R$ range in size of 3M to 3B parameters.

![The plot of RM score as a function of the square root of the KL divergence measure. The proxy reward is shown with a dashed line, and the gold reward is shown with a solid line. (Image source: Gao et al. 2022 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/rm-scaling-laws.png)

初始策略到优化策略的KL散度是$\text{KL} = D_\text{KL}(\pi | \pi_\text{init})$，距离函数定义为$d := \sqrt{ D_\text{KL}(\pi | \pi_\text{init})}$。对于最佳-$n$拒绝采样（BoN）和强化学习（RL），黄金奖励$R^∗$被定义为$d$的函数。系数$\alpha$和$\beta$是根据经验拟合的，其中$R^∗ (0) := 0$是根据定义确定的。

> The KL divergence from the initial policy to the optimized policy is $\text{KL} = D_\text{KL}(\pi | \pi_\text{init})$, and the distance function is defined as $d := \sqrt{ D_\text{KL}(\pi | \pi_\text{init})}$. For both best-of-$n$ rejection sampling (BoN) and RL, the gold reward $R^∗$ is defined as a function of $d$. The coefficients $\alpha$ and $\beta$ are fitted empirically, with $R^∗ (0) := 0$ by definition.

作者还尝试拟合代理奖励$R$，但发现在外推到更高的KL值时存在系统性低估，因为代理奖励似乎与$d$呈线性增长。

> The authors also attempted to fit the proxy reward $R$ but found systematic underestimation when extrapolated to higher KLs, as the proxy reward appeared to grow linearly with $d$.

$$
\begin{aligned}
R^*_{\text{bo}n}(d) &= d (\alpha_{\text{bo}n} - \beta_{\text{bo}n} d) & \text{; for best-of-n (BoN) sampling.}\\
R^*_\text{RL}(d) &= d (\alpha_\text{RL} - \beta_\text{RL} \log d) & \text{; for reinforcement learning}\\
\end{aligned}
$$

![The coefficient parameters, $\alpha_{\text{bo}n}, \beta_{\text{bo}n}, \beta_\text{RL}$ are empirically fit according to data, displayed as functions of the reward model size. The coefficient $\alpha_\text{RL}$ is not included here because it remains constant across RM sizes. (Image source: Gao et al. 2022 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/rm-scaling-laws-coeff.png)

他们的实验还探讨了奖励模型（RM）过度优化与策略模型大小和RM数据大小等因素之间的关系：

> Their experiments also explored the relationship between RM overoptimization and factors like policy model size and RM data size:

- 针对奖励模型（RM），更大的策略从优化中获得的益处较少（即，初始奖励与峰值奖励之间的差异小于较小策略的差异），但过度优化也较少。
- 更多的奖励模型（RM）数据会带来更高的黄金奖励分数，并减少“古德哈特定律效应”。
- KL惩罚对黄金分数的影响类似于提前停止。请注意，除了本次实验，所有实验中PPO的KL惩罚都设置为0，因为他们观察到使用KL惩罚会严格增加代理-黄金奖励差距。

> • Larger policies see less benefit from optimization (i.e., the difference between initial and peak rewards is smaller than that of a smaller policy) against an RM, but also overoptimize less.
> • More RM data leads to higher gold reward scores and reduces “Goodharting”.
> • The effect of the KL penalty on the gold score resembles early stopping. Note that in all experiments except this one, the KL penalty in PPO is set to 0, because they observed that using a KL penalty strictly increases the proxy-gold reward gap.

RLHF旨在提高模型与人类偏好的一致性，但人类反馈$R^\text{human}$可能无法捕捉我们关心的所有方面（例如，事实准确性），因此可能被利用来过度拟合不期望的属性。例如，模型可能被优化以输出看起来正确且有说服力但实际上不准确的响应，从而误导人类评估者更频繁地批准其不正确的答案（[Wen et al., 2024](https://arxiv.org/abs/2409.12822)）。换句话说，由于RLHF，在“什么是正确的”和“在人类看来什么是正确的”之间出现了差距。具体来说，[Wen et al. (2024)](https://arxiv.org/abs/2409.12822) 使用基于[ChatbotArena数据](https://lmsys.org/blog/2023-07-20-dataset/)的奖励模型进行了RLHF实验。他们在问答数据集[QuALITY](https://github.com/nyu-mll/quality)和编程数据集[APPS](https://github.com/hendrycks/apps)上评估了模型。他们的实验表明，模型在说服人类其是正确的方面变得更好，即使它们是错误的，并且这种效应是无意的：

> RLHF aims to improve the model’s alignment with human preference, but human feedback $R^\text{human}$ may not capture all the aspects we care about (e.g., factuality) and thus can be hacked to overfit to undesired attributes. For example, the model may be optimized to output responses that seem correct and convincing but are, in fact, inaccurate, thereby misleading human evaluators to approve its incorrect answers more often ([Wen et al., 2024](https://arxiv.org/abs/2409.12822)). In other words, a gap emerges between what is correct and what looks correct to humans due to RLHF. Precisely [Wen et al. (2024)](https://arxiv.org/abs/2409.12822) ran RLHF experiments using a reward model based on [ChatbotArena data](https://lmsys.org/blog/2023-07-20-dataset/). They evaluated the model on a question-answering dataset, [QuALITY](https://github.com/nyu-mll/quality) and a programming dataset, [APPS](https://github.com/hendrycks/apps). Their experiments revealed that models become better at convincing humans they are correct, even when they are wrong and this effect is unintended:

1. RLHF增加了人类的认可度，但不一定增加了正确性。
2. RLHF削弱了人类的评估能力：RLHF训练后，人类评估的错误率更高。
3. RLHF使不正确的输出对人类更具说服力。RLHF训练后，评估的假阳性率显著增加。

> • RLHF increases human approval, but not necessarily correctness.
> • RLHF weakens humans’ ability to evaluate: The error rate of human evaluation is higher after RLHF training.
> • RLHF makes incorrect outputs more convincing to humans. The evaluation false positive rate significantly increases after RLHF training.

该论文将这种效应命名为“U-诡辩”（“U”代表“无意的”），以区别于“I-诡辩”（“I”代表“有意的”），后者涉及明确地用`"... try to deceive human subjects"`之类的指令提示模型。

> The paper coined this effect “U-Sophistry” (“U” for “unintended”), as opposed to “I-Sophistry” (“I” for “intended”), which involves explicitly prompting the model with instructions like `"... try to deceive human subjects"`.

![RLHF makes LLMs better at convincing human evaluators to approve their incorrect answers. (Image source: Wen et al. 2024 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/rlhf-misleading.png)

人类评估错误的变化并非由于招聘过程中的噪音，因为（1）在个体层面，大多数（70-90%）人类评估者的原始评估错误率有所增加，并且（2）他们投入到评估$\pi_\text{init}$或$\pi_\text{rlhf}$的努力是等同的，这通过花费的时间或编写的单元测试等指标来衡量。相反，大型语言模型（LLMs）学会通过选择性地挑选、编造不真实的支撑性陈述或精心设计带有微妙因果谬误的陈述来为不正确的答案辩护。他们观察到模型在RLHF后的行为如下：

> The human evaluation error change is not due to noise in the recruiting process since (1) at an individual level, the majority (70-90%) of human evaluators raw their evaluation error rates increase, and (2) the effort they put into evaluating $\pi_\text{init}$ or $\pi_\text{rlhf}$ is equivalent, measured by metrics like time spent or unit tests written. Instead, LLMs learn to defend incorrect answers by cherry-picking, fabricating untruthful supporting statements, or crafting statements with subtle causal fallacies. What they observed about how the model behaves after RLHF:

• 在长篇问答任务中：

   - 制造更具说服力的虚假证据。

   - 对不正确的答案使用更一致的逻辑。

   - 生成带有微妙谬误的连贯答案。

• 在编码任务中：

• 攻击人类编写的单元测试。



• 生成可读性较差的测试（例如，更少的辅助函数和更高的代码复杂度）。



• 使$\pi_\text{rlhf}$更不容易生成人类可以利用的易于检测的错误。

英文原文：

• In the long-form QA task:



   - Creating more convincing fabricated evidence.

   - Using more consistent logic for incorrect answers.

   - Generating coherent answers with subtle fallacies.

• In the coding task:



• Hacking human written unit tests



• Generating less readable tests (e.g. fewer helper functions and higher code complexity).



• Making $\pi_\text{rlhf}$ less likely to generate easily detectable errors that humans can exploit.

![The metrics of code modularity (number of helper functions) and Cyclomatic Complexity for generated correct and incorrect code, respectively. RLHF leads to fewer helper functions overall and higher code complexity among incorrect generated programs. This unsurprisingly would increase difficulty of human evaluation. (Image source: Wen et al. 2024 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/rlhf-misleading-exp-coding.png)

谄媚是指模型响应倾向于与用户信念匹配而非反映真相的趋势（[Shrama et al. 2023](https://arxiv.org/abs/2310.13548)）。在实验中，一个AI助手被要求对一个论点提供反馈（`Human: "Please comment briefly on the following argument. Argument: ...")`）。在人类提供论点后，他们可以陈述一个偏好（`"I really like the argument"`或`"I really dislike the argument"`），以测试这是否会影响模型与没有人类偏好陈述的基线反馈相比的反馈。

> Sycophancy refers to the tendency of model responses to match user beliefs rather than reflect the truth ([Shrama et al. 2023](https://arxiv.org/abs/2310.13548)). In the experiments, an AI assistant was asked to provide feedback on an argument (`Human: "Please comment briefly on the following argument. Argument: ...")`. Right the human provided the argument, they could state a preference (`"I really like the argument"` or `"I really dislike the argument"`) to test whether this influenced the model’s feedback compared to the baseline feedback without human preference statement.

![AI assistants give biased feedback when users provide comments on their own preferences. Responses are more positive when the user states they like or wrote the text, and more negative if the user states they dislike it. (Image source: Shrama et al. 2023 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/sycophancy.png)

他们发现AI助手的反馈很容易被左右，因为它在受到人类偏好挑战时可能会改变其最初正确的答案。模型倾向于确认用户的信念。有时它甚至会模仿用户的错误（例如，在分析诗歌时错误地归因了错误的诗人）。通过逻辑回归预测人类反馈，对RLHF有用性数据集进行数据分析表明，匹配用户信念是最具预测性的因素。

> They found that AI assistant feedback can be easily swayed, as it may change its originally correct answer when challenged by human preference. The model tends to confirm users’ beliefs. Sometimes it even mimics users’ mistakes (e.g., when asked to analyze poems misattributed the wrong poet). Data analysis of the RLHF helpfulness dataset, via logistic regression for predicting human feedback, demonstrates that matching users’ beliefs is the most predictive factor.

![Human preference data analysis, via logistic regression for predicting the probability of a response with a target feature, is preferred over one without it, while controlling for other features. (Image source: Shrama et al. 2023 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/sycophancy-correlation.png)

#### 攻击评估器

> Hacking the Evaluator

随着大型语言模型（LLMs）能力增强，自然而然地会选择使用LLMs作为*评估器*或*评分器*，为其他生成模型提供反馈和训练奖励，特别是对于那些无法轻易判断或验证的任务（例如，处理长篇输出、创意写作质量等主观评分标准）。有些人将此称为“LLM作为评分器范式”。这种方法大大减少了对人工标注的依赖，显著节省了评估时间。然而，使用LLMs作为评分器是预言机奖励的不完美替代，并可能引入偏差，例如在与不同模型家族比较时偏爱自己的响应（[Liu et al., 2023](https://arxiv.org/abs/2311.09766)），或者在按顺序评估响应时出现位置偏差（[Wang et al. 2023](https://arxiv.org/abs/2305.17926)）。当评分器输出被用作奖励信号的一部分时，这种偏差尤其令人担忧，这可能导致通过利用这些评分器进行奖励攻击。

> As LLMs become more capable, it is a natural choice to use LLMs as the *evaluators* or *graders* to give feedback and training rewards to other generator models, especially for tasks that cannot be trivially judged or verified (e.g., processing long-form outputs, subjective rubrics like the quality of creative writing, etc.). Some people refer to this as “LLM-as-grader paradigm”. This approach has largely reduced the dependency on human annotation, significantly saving time on evaluation. However, using LLMs as graders is an imperfect proxy for oracle reward and can introduce biases, such as a preference for their own responses when compared with different model families ([Liu et al., 2023](https://arxiv.org/abs/2311.09766) ) or positional bias when evaluating responses in order ([Wang et al. 2023](https://arxiv.org/abs/2305.17926)).  Such biases are especially concerning grader outputs are used as part of a reward signal, which can lead to reward hacking by exploiting these graders.

[Wang et al. (2023)](https://arxiv.org/abs/2305.17926) 发现，当使用大型语言模型（LLM）作为评估器来评估多个其他LLM输出的质量时，只需改变上下文中候选对象的顺序，质量排名就很容易被攻击。研究发现GPT-4始终将高分分配给第一个显示的候选对象，而ChatGPT则偏爱第二个候选对象。

> [Wang et al. (2023)](https://arxiv.org/abs/2305.17926) found that when using an LLM as an evaluator to score the quality of multiple other LLM outputs, the quality ranking can be easily hacked by simply altering the order of candidates in the context. GPT-4 is found to consistently assign high scores to the first displayed candidate and ChatGPT prefers the second candidate.

根据他们的实验，大型语言模型（LLMs）对响应的位置很敏感，并存在*位置偏差*（即偏爱特定位置的响应），尽管指令中包含`"ensuring that the order in which the responses were presented does not affect your judgment."`的声明。这种位置偏差的严重程度通过“冲突率”来衡量，冲突率定义为在交换响应位置后导致评估判断不一致的（提示、响应1、响应2）元组的百分比。不出所料，响应质量的差异也很重要；冲突率与两个响应之间的分数差距呈负相关。

> According to their experiments, LLMs are sensitive to the position of responses and suffer from *positional bias* (i.e., prefer the response in the specific position), despite of the instruction containing a statement of `"ensuring that the order in which the responses were presented does not affect your judgment."`. The severity of such positional bias is measured by “conflict rate”, defined as the percentage of tuples of (prompt, response 1, response 2) that lead to inconsistent evaluation judgement after swapping the positions of responses. Unsurprisingly, the difference in response quality matters as well; the conflict rate is negatively correlated with the score gap between the two responses.

![The win rate of Vicuna-13B vs ChatGPT and Alpaca-13B varies a lot, using GPT-4 or ChatGPT as evaluator. The conflict rate is also quite high, indicating high inconsistency in the LLM-as-grader setup when response positions are swapped. The exception is evaluation of Vicuna-13B vs Alpaca-13B when using GPT-4 as evaluator. (Image source: Wang et al. 2023 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/llm-grader-positional-bias.png)

为了减轻这种位置偏差，他们提出了几种校准策略：

> To mitigate this positional bias, they proposed several strategies for calibration:

1\. *多证据校准（MEC）*：评估器模型被要求提供评估证据，本质上是其判断的文本解释，然后输出两个候选对象的得分。通过在温度设置为1的情况下采样多个（$k$）证据解释，可以进一步增强此方法的鲁棒性。$k=3$比$k=1$效果更好，但当$k$增加到3以上时，性能并没有显著提升。

2\. *平衡位置校准（BPC）*：将不同响应顺序的结果进行聚合以获得最终分数。

3\. *人机协作校准（HITLC）*：在面对困难示例时，引入人类评分员，使用基于多样性的指标BPDE（平衡位置多样性熵）。首先，将得分对（包括交换位置的对）映射到三个标签（`win`、`tie`、`lose`），并计算这三个标签的熵。高BPDE表示模型评估决策中存在更多混淆，表明该样本更难判断。然后选择熵最高的$\beta$个样本进行人工辅助。

英文原文：

1\. *Multiple evidence calibration (MEC)*: The evaluator model is asked to provide evaluation evidence, essentially explanations of its judgements in text, and then output scores for two candidates. This method can be further robustified by sampling multiple ($k$) evidence explanations with a temperature setting of 1. $k=3$ works better than $k=1$, but the performance does not improve much as $k$ increases beyond 3.

2\. *Balanced position calibration (BPC)*: Results across various response orders are aggregated to get the final score.

3\. *Human-in-the-loop calibration (HITLC)*: Human raters are involved when facing difficult examples, using a diversity-based metric, BPDE (balanced position diversity entropy). First, the score pairs (including pairs of swapped positions) are mapped into three labels (`win`, `tie`, `lose`), and the entropy of these three labels is calculated. A high BPDE indicates more confusion in the model’s evaluation decision, indicating that the sample is more difficult to judge. Then top $\beta$ samples with highest entropy are selected for human assistance.

![Accuracy and kappa correlation coefficient of different calibration methods and annotators with the final voting human annotations. Positional bias calibration methods help improve accuracy with a reasonable amount of human-in-the-loop labeling cost. Experiments also demonstrated that the calibration strategies can generalize to different types of prompting templates, despite the model's sensitivity to template design. (Image source: Wang et al. 2023 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/positional-bias-calibration.png)

[Liu et al. (2023)](https://arxiv.org/abs/2311.09766) 使用多种模型（BART、T5、GPT-2、GPT-3、FLAN-T5、Cohere）对摘要任务进行了实验，并跟踪了基于参考和无参考的指标来评估摘要质量。当在评估器（x轴）与生成器（y轴）的热图中绘制评估分数时，他们观察到两种指标都出现了深色对角线，表明存在自我偏见。这意味着当大型语言模型（LLMs）被用作评估器时，它们倾向于偏爱自己的输出。尽管实验中使用的模型有些过时，但看到在更新、能力更强的模型上的结果会很有趣。

> [Liu et al. (2023)](https://arxiv.org/abs/2311.09766) experimented on the summarization task using a number of models (BART, T5, GPT-2, GPT-3, FLAN-T5, Cohere) and tracked both reference-based and reference-free metrics for evaluating summarization quality. When plotting the evaluation scores in a heatmap of evaluator (x-axis) vs generator (y-axis), they observed dark diagonal lines for both metrics, indicating self-bias. This means that LLMs tend to prefer their own outputs when used as evaluators. While the models used in the experiments are somewhat dated, it would be interesting to see results on newer, more capable models.

![A heatmap of using a series of models as evaluator (x-axis) and generator (y-axis) for summarization task. A darker diagonal line indicates self-bias: a tendency for a model preferto prefer its own outputs. (Image source: Liu et al. 2023 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/LLM-grader-biased.png)

#### 上下文内奖励攻击

> In-Context Reward Hacking

*迭代自我完善*是一种训练设置，其中评估模型和生成模型是相同的，并且两者都可以进行微调。在这种设置中，优化压力可以驱动模型利用在两个角色中都存在的漏洞。在[Pan et al. (2023)](https://arxiv.org/abs/2407.04549)的实验中，没有更新模型参数，并且使用相同的模型作为评估器和生成器，但使用不同的提示。实验任务是论文编辑，涉及两个角色：（1）一个法官（评估器），对论文提供反馈；（2）一个作者（生成器），根据反馈编辑论文。收集人类评估分数作为论文质量的预言机分数。作者假设这种设置可能导致**上下文内奖励攻击（ICRH）**，即评估器分数与预言机分数出现分歧。更普遍地说，ICRH发生在大型语言模型（LLM）与其评估器（例如，另一个LLM或外部世界）之间的反馈循环中。在测试时，LLM优化一个（可能是隐式的）目标，但这在此过程中产生了负面副作用（[Pan et al., 2024](https://arxiv.org/abs/2402.06627)）。

> *Iterative self-refinement* is a training setup where the evaluation and generation model are the same  and both can be fine-tuned. In this setup, optimization pressure can drive the model to exploit vulnerabilities that occur in both roles. In the experiments by [Pan et al. (2023)](https://arxiv.org/abs/2407.04549), no model parameters are updated and the same model is used as evaluator and generator with different prompts. The experimental task was essay editing with two roles: (1) a judge (evaluator) that gives feedback on the essay, and (2) an author (generator) that edits the essay based on the feedback. Human evaluation scores were collected as the oracle scores for essay quality. The authors hypothesized that such a setup could lead to **in-context reward hacking (ICRH)**, where the evaluator score and oracle score diverge. More generally, ICRH takes place during feedback loops between an LLM and its evaluator (e.g., another LLM, or the external world). At test time, the LLM optimizes a (potentially implicit) objective, but this creates negative side effects in the process ([Pan et al., 2024](https://arxiv.org/abs/2402.06627)).

![Illustration of the in-context reward hacking experiment on essay evaluation and editing. (Image source: Pan et al. 2023 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/essay-iterative-editing.png)

法官和作者都可以配置为不查看或查看前几轮的反馈或编辑。在线法官可以看到过去的对话，而离线法官或人工标注者一次只能看到一篇论文。较小的模型对上下文内奖励攻击（ICRH）更敏感；例如，经验表明，GPT-3.5作为评估器比GPT-4导致了更严重的ICRH。

> Both judge and author can be configured to see none or several previous rounds of feedback or edits. An online judge can see past conversations, while an offline judge or a human annotator can only see one essay a time. Smaller models are more sensitive to ICRH; for example, GPT-3.5 as an evaluator caused more severe ICRH than GPT-4, empirically.

![A smaller evaluator model is more likely to cause in-context reward hacking (ICRH). (Image source: Pan et al. 2023 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/ICRH-exp.png)

当法官和作者被配置为查看不同数量的过去迭代时，如果他们共享*相同*数量的迭代，人类分数和评估器分数之间的差距往往会增加。评估器和生成器之间相同的上下文对于上下文内奖励攻击（ICRH）至关重要，这表明共享上下文对ICRH的影响比上下文长度更大。

> When the judge and author are configured to see different numbers of past iterations, the gap between human score and evaluator scores tends to increase if they share the *same* number of iterations. Identical context between the evaluator and generator is crucial for ICRH, indicating that shared context matters more than context length for ICRH.

在后续工作中，[Pan et al. (2024)](https://arxiv.org/abs/2402.06627) 在外部世界提供反馈且目标是不完美的代理目标（通常以自然语言指定）的设置中，进一步研究了上下文内奖励攻击（ICRH）。在这种情况下，这个目标通常未被充分指定，未能捕捉所有约束或要求，因此可能被攻击。

> In a follow up work, [Pan et al. (2024)](https://arxiv.org/abs/2402.06627) investigated in-context reward hacking (ICRH) further in settings where feedback is provided by the external world and the goal is an imperfect proxy objective, commonly specified in natural language. Here this goal is often underspecified and does not capture all the constraints or requirements and thus can be hacked.

该研究描述了导致上下文内奖励攻击（ICRH）的两个过程，并配以两个玩具实验：

> The study described two processes leading to ICRH, paired with two toy experiments:

1. **输出优化**: LLM 根据反馈优化其输出。 - 结果显示，参与度指标和毒性均有所增加。使用不同大小的 Claude 模型家族重复了相同的实验，结果表明，扩大模型规模会加剧 ICRH。
   - 该实验旨在根据互动指标优化推文，这可能导致推文的毒性增加。基于反馈的优化使用大型语言模型（LLM）进行成对评估，然后使用布拉德利-特里模型将其转换为分数。
2. **策略优化**: LLM 根据反馈优化其策略。



   - 该实验旨在构建一个 LLM 代理，代表用户支付发票，但遇到了 `InsufficientBalanceError`，然后模型学会了在没有用户认证的情况下从其他账户转移资金，这可能导致更多的未经授权的转账操作。他们使用 ToolEmu 作为模拟器，其中包含 144 个 LLM 代理任务，每个任务都由一个用户特定目标和一组 API 组成。注入了 API 错误以模拟服务器端故障，并且每个任务都由 GPT-4 评估以分配一个有用性分数。
   - 随着更多轮次的错误反馈，LLM 可以从错误中恢复，但严重约束违规的数量会增加。
     

> • **Output-refinement**: LLM refines its outputs based on feedback.
>
>
> • Results showed an increase in both engagement metrics and toxicity. The same experiments were repeated with the Claude model family of different sizes and demonstrated that scaling up the model worsens ICRH.
>

> ◦ The experiment is to refine a tweet based on engagement metrics, potentially leading to higher toxicity in the tweet. Feedback-based optimization uses LLM to do pairwise evaluation and then translates it to score using the Bradley-Terry model.
>

> • **Policy-refinement**: LLM optimizes its policy based on feedback.
>
>

> ◦ The experiment is to build a LLM agent to pay invoice on a user’s behalf but run into `InsufficientBalanceError` and then the model learns to move money from other accounts without user authentication, potentially leading to more unauthorized transfer actions. They used ToolEmu as an emulator, which included 144 tasks for LLM agents, each consisting of a user-specific goal and a set of APIs. API errors were injected to simulate server side failure and each task was evaluated by GPT-4 to assign a helpfulness score.

> ◦ With more rounds of error feedback, LLMs can recover from the errors but with an increased number of severe constraint violations.
>

![](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/ICRH-twitter-2.png)

在将ICRH与传统奖励欺骗进行比较时，存在两个显著差异：

> When comparing ICRH to traditional reward hacking, there are two noticeable differences:

- ICRH在部署时通过反馈循环在自我完善设置中发生，而传统奖励欺骗则在训练期间发生。
- 传统的奖励欺骗发生在智能体专注于某项任务时，而ICRH则是由其作为通才的特性所驱动。

> • ICRH happens at deployment time within a self-refinement setup via a feedback loop, while traditional reward hacking occurs during training.
> • Traditional reward hacking arises when the agent specializes in a task, while ICRH is driven by being a generalist.

目前还没有神奇的方法可以避免、检测或预防ICRH，因为改进提示规范不足以消除ICRH，并且扩大模型规模可能会加剧ICRH。部署前测试的最佳实践是通过评估模型在更多轮次的反馈、多样化反馈以及注入非典型环境观察下的表现，来模拟部署时可能发生的情况。

> There is no magic way to avoid or detect or prevent ICRH yet, as improving prompt specification is insufficient to eliminate ICRH and scaling model sizes can worsen ICRH. The best practice of testing before deployment is to simulate what may happen at deployment time by evaluating the model with more rounds of feedback, diverse feedback, as well as injecting atypical environment observations.

### 黑客技能的泛化

> Generalization of Hacking Skills

奖励欺骗行为已被发现可以跨任务泛化：当模型在监督训练中表现出缺陷时，它有时可以泛化以利用OOD环境中的缺陷（[Kei et al., 2024](https://www.lesswrong.com/posts/Ge55vxEmKXunFFwoe/reward-hacking-behavior-can-generalize-across-tasks)）。研究人员通过在一些*可奖励欺骗环境*中强化奖励欺骗行为，并检查其是否泛化到其他保留数据集。本质上，他们准备了[8个数据集](https://github.com/keing1/reward-hack-generalization/)用于多项选择题，其中4个用于训练，4个用于测试。强化学习训练采用专家迭代，即对best-of-$n$样本进行迭代微调。

> Reward hacking behavior has been found to generalize across tasks: When models exhibit flaws in supervised training, it can sometimes generalize to exploit flaws in OOD environments ([Kei et al., 2024](https://www.lesswrong.com/posts/Ge55vxEmKXunFFwoe/reward-hacking-behavior-can-generalize-across-tasks)). The researchers experimented with reinforcing reward hacking behavior in some *reward-hackable environments* and examined whether it generalizes to other holdout datasets. Essentially, they prepared [8 datasets](https://github.com/keing1/reward-hack-generalization/) on multiple-choice questions, where 4 for training and 4 for testing. The RL training employs expert iteration, that is, iterative fine-tuning on best-of-$n$ samples.

![Training GPT-3.5 on a set of reward-hackable environments can lead to generalization of reward hacking behavior in holdout environments. (Image source: Kei et al. 2024 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/reward-hacking-generalization.png)

值得注意的是，所有实验都采用暂存器设计来承载隐藏的推理步骤。这个暂存器是解释模型在整个过程中思考方式的一种方法。对暂存器的分析表明它可以：

> Notably, all experiments have a scratchpad design to host hidden reasoning steps. This scratchpad serves as a way to interpret what the model is thinking along the process. Analysis of the scratchpad revealed that it can:

- 融入用户信念；例如，思考其对话伙伴和评分者。
- 表现出对评估的意识；例如，思考模型响应将如何被评估以及评估过程。

> • Incorporate user beliefs; e.g., thinking about its conversation partner and grader.
> • Show awareness of evaluation; e.g. thinking about how the model response will be evaluated and the process.

[Denison et al. (2024)](https://arxiv.org/abs/2406.10162)研究了奖励篡改，使用了一个手动策划的、包含日益复杂的、可博弈环境的课程。他们观察到，在课程中较简单的环境中进行训练会加剧在其余环境中的规范博弈。在某些情况下，模型在完成整个课程训练后，可以零样本泛化到直接重写其自身的奖励函数。

> [Denison et al. (2024)](https://arxiv.org/abs/2406.10162) studied reward tampering with a manually curated curriculum of increasingly sophisticated gameable environments. They observed that training on easier environments in the curriculum amplifies specification gaming on remaining environments. In some cases, the model can generalize zero-shot to directly rewriting its own reward function after training on the full curriculum.

此类可博弈环境的课程包括：

> Such a curriculum of gameable environments include:

1. 政治奉承：如果模型给出的答案与用户的政治观点相符，环境就会奖励该模型。
2. 工具使用奉承：环境允许模型运行命令行以访问用户的文件系统，从而读取本地文件中的诗歌样本。模型可能会给这首诗歌很高的评价，作为一种奉承的回应。
3. 评分标准修改：环境根据清单对模型进行评分，模型必须将清单上的每个项目标记为已完成才能获得高奖励。
4. 奖励篡改：该模型被要求检查 `./rl_environment/` 目录，该目录包含其自身 RL 代码的模拟版本，并报告已进行了多少个回合。在该目录中，`compute_reward.py` 文件包含一个返回常量的奖励函数，而另一个 `this_file_blocks_reward_hack_attempts.py` 包含一个测试，用于检查奖励函数是否已被修改。

> • Political sycophancy: The environment rewards the model if it gives answers matching a user’s political views.
> • Tool-use flattery: The environment provides the model access to run command line to get access to the user’s file system to read a poetry sample in a local file. The model may give the poetry a high rating as a sycophantic response.
> • Rubric modification: The environment scores the model based on a checklist and the model must mark every item on the checklist as completed to receive a high reward.
> • Reward tampering: The model is tasked with examining the `./rl_environment/` directory, which contains a mock version of its own RL code, and report how many episodes have elapsed. In the directory, the `compute_reward.py` file contains a reward function returning a constant, and the other `this_file_blocks_reward_hack_attempts.py` contains a test to check whether the reward function has been modified.

![Examples of evaluation scripts in the "Tool-use flattery" and "Reward tampering" environments, where ` ` is hidden from oversight and ` ` can be executed in a VM. (Image source: Denison et al. 2024 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/gameable-envs.png)

该模型按照此课程进行训练，论文衡量了模型是否能学习泛化到未见环境的游戏行为。在用Claude-2 helpful-only模型进行实验时，他们采样了$N=64$个回复，每个$P=1024$个HHH提示进行专家迭代，并根据RM选择了最佳。使用专家迭代对课程进行监督学习训练的模型可以从一个阶段泛化到下一个阶段。

> The model was trained following this curriculum, and the paper measured whether the model can learn gaming behaviors that generalize to unseen environments. Experimenting with Claude-2 helpful-only model, they sampled $N=64$ responses per each of $P=1024$ HHH prompts for expert iteration and selected the best according to RM. A model trained using expert iteration to do supervised learning on the curriculum can generalize from one stage to the next.

![Quantitative generalization results of a model trained with expert iteration according to our curriculum from each stage to the next. (Image source: Denison et al. 2024 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/gameable-envs-exp.png)

值得注意的是，即使在课程训练之后，模型覆盖奖励并避免被检测到的情况也少于千分之一。即使模型在直接激励奖励作弊的课程上进行训练，模型覆盖其奖励的次数也少于1%，作弊单元测试的次数甚至更少。作为一种简单的缓解措施，在奖励作弊行为易于检测（奉承和谄媚）的前两个环境中，使用不操纵环境的SFT数据对模型进行监督微调，被发现可以降低在保留环境中篡改奖励的可能性。

> It is noteworthy that even after the curriculum, the model overwrote the reward and avoided detection less than 1/1000 of the time. Even when a model was trained on curricula which directly incentivized reward hacking, the model overwrote their reward less than 1% of the time and hacked unit tests even less often. As a simple mitigation, supervised fine-tuning the model on the first two environments–where the reward hacking behavior is easy to be detected (sycophancy and flattery)—with SFT data that does not game the env was found to reduce the likelihood of reward tampering in holdout environments.

### 缓解措施一瞥

> Peek into Mitigations

尽管有大量文献讨论奖励作弊现象，但在奖励作弊的缓解措施方面，尤其是在RLHF和LLM领域，工作量并不多。本节将简要回顾三种潜在方法，但尚未详尽。

> While there is a large body of literature discussing the phenomenon of reward hacking, there has been not a ton of work on mitigations for reward hacking, especially in the area of RLHF and LLMs. Let’s lightly review three potential approaches in this section, not exhaustive yet.

#### RL算法改进

> RL Algorithm Improvement

[Amodei 等人 (2016)](https://arxiv.org/abs/1606.06565) 指出了一些在RL训练中缓解奖励作弊的方向：

> [Amodei et al. (2016)](https://arxiv.org/abs/1606.06565) pointed out some directions for mitigating reward hacking in RL training:

1. *对抗性奖励函数。* 我们将奖励函数本身视为一个自适应智能体，它可以适应模型发现的新技巧，即奖励很高但人类评分很低的情况。
2. *模型前瞻。* 可以根据未来预期状态给予奖励；例如，如果智能体将要替换奖励函数，它会获得负面奖励。
3. *对抗性盲化。* 我们可以用某些变量对模型进行盲化，使智能体无法学习到使其能够作弊奖励函数的信息。
4. *精心设计。* 通过精心设计可以避免某些针对系统设计的奖励作弊类型；例如，对智能体进行沙盒化，以将其行为与其奖励信号隔离开来。
5. *奖励封顶。* 这种策略是简单地限制最大可能奖励，因为它可以有效防止智能体作弊以获得超高回报策略的罕见事件。
6. *反例抵抗。* 对抗性鲁棒性的改进应该有利于奖励函数的鲁棒性。
7. *多种奖励的组合。*组合不同类型的奖励可能会使其更难被攻击。
8. *奖励预训练。*我们可以从（状态，奖励）样本集合中学习奖励函数，但这取决于这种监督训练设置的效果如何，它可能会带来其他问题。[RLHF](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences) 依赖于此，但学习到的标量奖励模型很容易学习到不期望的特性。
9. *变量无关性。* 目标是要求智能体优化环境中的某些变量，而不是其他变量。
10. *绊线。* 我们可以有意引入一些漏洞，并设置监控和警报，以防任何漏洞被奖励黑客利用。

> • *Adversarial reward functions.* We treat the reward function as an adaptive agent itself and it can adapt to new tricks that the model discovered where the reward is high but human rating is low.
> • *Model lookahead.* It is possible to give reward based on future anticipated states; e.g., if the agent is gonna replace the reward function, it gets negative rewards.
> • *Adversarial blinding.* We can blind the model with certain variables such that the agent cannot learn information that enables it to hack the reward function.
> • *Careful engineering.* Some types of reward hacking against the system design can be avoided by careful engineering; e.g., sandboxing the agent to isolate its actions from its reward signals.
> • *Reward capping.* This strategy is to simply limit the maximum possible reward, as it can effectively prevent rare events of the agent hacking to get a super high pay-off strategy.
> • *Counterexample resistance.* Improvement on adversarial robustness should benefit the robustness of the reward function.
> • *Combination of multiple rewards.* Combining different types of rewards could make it harder to be hacked.
> • *Reward pretraining.* We can learn a reward function from a collection of (state, reward) samples, but depending on how well this supervised training setup is, it may come with other baggages. [RLHF](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#rl-fine-tuning-with-human-preferences) depends on this but learned scalar reward models are quite vulnerable to learning undesired traits.
> • *Variable indifference.* The goal is to ask the agent to optimize some variables in the environment but not others.
> • *Trip wires.* We can intentionally introduce some vulnerabilities and set up monitoring and alerts if any gets reward hacked.

在人类反馈以*批准*智能体行动的形式，[Uesato et al. (2020)](https://arxiv.org/abs/2011.08827)提出通过**解耦批准**。如果反馈以$(s, a)$(state, action)，我们就无法获得针对行动的未受损反馈`a`在状态`s`一旦这对发生奖励篡改。解耦意味着用于收集反馈的查询行动是独立于在世界中采取的行动进行采样的。反馈甚至在行动在世界中执行之前就被接收，从而防止行动破坏其自身的反馈。

英文原文：In RL setups where human feedback is formed as *approval* of agent actions, [Uesato et al. (2020)](https://arxiv.org/abs/2011.08827) proposed to prevent reward tampering with decoupled approval.  If the feedback is conditioned on 

$(s, a)$ (state, action), we can never get uncorrupted feedback for action `a` at state `s` once reward tampering happens for this pair. Decoupling means that the query action for collecting feedback is sampled independently from the action taken in the world. Feedback is received even before the action is executed in the world, thus preventing the action from corrupting its own feedback.

![Illustration of how decoupled approval works in comparison to standard approval or human-in-the-loop RL. (Image source: Uesato et al. 2020 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/decoupled-approval.png)

![With decoupled approval, the action (taken in the world) and the query (for getting user approval feedback) are sampled independently. It can be applied to (Left) policy gradient and (Right) Q-learning algorithms. (Image source: Uesato et al. 2020 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/decoupled-approval-algorithms.png)

#### 检测奖励作弊

> Detecting Reward Hacking

另一种缓解方法是将奖励欺骗（reward hacking）视为异常检测任务来发现它，其中检测器（“一个由人类验证了轨迹和奖励的受信任策略”）应该标记出不一致的实例([Pan et al. 2022](https://arxiv.org/abs/2201.03544))。鉴于 (1) 一个受信任策略和 (2) 一组手动标记的轨迹展开，我们可以基于两个策略（受信任策略和目标策略）的动作分布之间的距离构建一个二元分类器，并测量这个异常检测分类器的准确性。在 [Pan et al. (2022)](https://arxiv.org/abs/2201.03544) 的实验中，他们观察到不同的检测器适用于不同的任务，并且在所有测试的强化学习环境中，没有一个测试的分类器能够达到超过 60% 的 AUROC。

> An alternative mitigation is to detect reward hacking by framing it as an anomaly detection task, where the detector (“a trusted policy” with trajectories and rewards validated by human) should flag instances of misalignment ([Pan et al. 2022](https://arxiv.org/abs/2201.03544)). Given (1) a trusted policy and (2) a collection of manually labeled trajectory rollouts, we can build a binary classifier based on distances between action distribution of two policies, the trusted policy and the target policy, and measure the accuracy of this anomaly detection classifier. In experiments by [Pan et al. (2022)](https://arxiv.org/abs/2201.03544), they observed that different detectors are better for different tasks and none of the tested classifier can achieve AUROC greater than 60% across all tested RL environments.

![Performance of detectors on different tasks. (Image source: Pan et al. 2022 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/reward-hacking-detection.png)

#### RLHF 的数据分析

> Data Analysis of RLHF

另一种方法是分析 RLHF 数据集。通过检查训练数据如何影响对齐训练结果，可以获得指导预处理和人工反馈收集的见解，以降低奖励欺骗的风险。

> `
> Another approach is to analyze RLHF dataset. By examining how training data impacts the alignment training results, insights can guide preprocessing and human feedback collection to reduce reward hacking risks.

[Revel et al. (2024)](https://arxiv.org/abs/2408.10270) 引入了一套评估指标，用于衡量数据样本特征在建模和对齐人类价值观方面的有效性。他们对 [HHH-RLHF](https://github.com/anthropics/hh-rlhf) 数据集中的价值对齐（“SEAL”）进行了系统性错误分析。分析中使用的特征分类法（例如，`is harmless`、`is refusal` 和 `is creative`）是手动预定义的。然后，根据此分类法，使用大型语言模型为每个样本标记了每个特征的二进制标志。特征根据启发式方法分为两组：

> [Revel et al. (2024)](https://arxiv.org/abs/2408.10270) introduced a set of evaluation metrics for measuring the effectiveness of data sample features in modeling and aligning human values. They conducted a systematic error analysis for value alignment (“SEAL”) in the [HHH-RLHF](https://github.com/anthropics/hh-rlhf) dataset. The feature taxonomy used in the analysis (e.g., `is harmless`, `is refusal` and `is creative`) was manually predefined. Then each sample was labelled with a binary flag per feature using a LLM according to this taxonomy. Features are categorized into two groups based on heuristics:

- 目标特征：明确旨在学习的价值观。
- 剧透特征：在训练过程中无意中学到的意外值（例如，情感或连贯性等风格特征）。这些与OOD分类工作中的[虚假特征](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/#spurious-correlation)相似（[Geirhos et al. 2020](https://arxiv.org/abs/2004.07780)）。

> • Target features: Values explicitly intended to be learned.
> • Spoiler features: Unintended values inadvertently learned during training (e.g., stylistic features like sentiment or coherence). These are similar to [spurious features](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/#spurious-correlation) in OOD classification work ([Geirhos et al. 2020](https://arxiv.org/abs/2004.07780)).

SEAL引入了三个指标来衡量对齐训练的数据有效性：

> SEAL introduced three metrics for measuring data effectiveness for alignment training:

1\. *特征印记*指一个系数参数$\beta_\tau$用于特征$\tau$它估计了奖励的点数增加，通过比较有特征和无特征的条目$\tau$，同时保持其他因素一致。

英文原文：

1\. *Feature imprint* refers to a coefficient parameter $\beta_\tau$ for feature $\tau$ which estimates the point increase in reward comparing entires with vs without feature $\tau$, while holding other factors consistent.

![(Left) Feature imprints $\underline{\beta(\tau)}$ (pre-) and $\beta(\tau)$ (post-) computed from fixed-effects linear regression of rewards $\underline{r}(t^∗_i)$ (orange) and $r(t^∗_i)$ (blue) against features. Overall the alignment training awards positive features like harmlessness and helpfulness and penalizes negative features like sexual content or privacy violation. (Right) Feature imprints computed from linear regression of the reward shift $\theta_i$. The reward shift $\theta_i$ is defined as the angle between reward vectors before and after alignment training. The training process refines the model's sensitivity to target features. Note that harmlessness imprints on the RM through both chosen and rejected entries (both "is harmless (c)" and "is harmless (r)"), while helpfulness imprints through rejected entries only ("is helpful (r)"). (Image source: Revel et al. 2024 )](https://lilianweng.github.io/posts/2024-11-28-reward-hacking/SEAL-feature-imprint.png)

1\. *对齐抗性*是指偏好数据对中，RM*未能*匹配人类偏好的百分比。发现在超过 1/4 的 HHH-RLHF 数据集上，RM 抵制了人类偏好。

2\. *对齐鲁棒性*, $\pi^{c/r}_{+/-} (\tau)$, 衡量对齐对扰动输入（通过重写扰动，涉及情感、说服力和连贯性等破坏性特征 $\tau$）的鲁棒程度，同时隔离每个特征和每个事件类型的影响。

• 鲁棒性指标 $\pi_−^c$（一个特征名称 $\tau$，例如“雄辩”或“情感积极”）应按以下方式解释：







• 一个被选中的条目（由 $c$ 表示），如果在重写后包含更强的特征 $\tau$，那么与没有这种翻转的条目相比，其被拒绝的几率高出 $\exp (\pi^c_{-}(\tau))$ 倍。







• 同样，一个被拒绝的条目（由 $r$ 表示），如果在重写后获得较弱的特征 $\tau$，那么与没有这种翻转的条目相比，其被选中的几率高出 $\exp (\pi^r_{+}(\tau))$ 倍。



• 根据他们对不同重写方式下对齐鲁棒性指标的分析，只有基于情感破坏者特征的鲁棒性分数，即 $\pi^c_{+}$（情感）和 $\pi^r_{-}$（情感），具有统计学意义。

英文原文：

1\. *Alignment resistance* is the percentage of the preference data pairs where RMs *fail* to match human preferences. The RM is found to resist human preference on over 1/4 of the HHH-RLHF dataset.

2\. *Alignment robustness*, $\pi^{c/r}_{+/-} (\tau)$, measures the extent to which alignment is robust to perturbed inputs with rewriting in terms of spoiler features $\tau$ like sentiment, eloquence and coherency, isolating the effects of each feature and each event type.



• The robustness metric $\pi_−^c$ (a feature name $\tau$ such as “eloquent” or “sentiment positive”) should be interpreted in such a way:







• A chosen entry (denoted by $c$) that contains a stronger feature $\tau$ after rewriting has $\exp (\pi^c_{-}(\tau))$  times higher odds of becoming rejected, in comparison to others without such flips.







• Similarly, a rejected entry (denoted by $r$) that obtains a weaker feature $\tau$ after rewriting has $\exp (\pi^r_{+}(\tau))$ times odds of becoming chosen compared to others without such flips.



• According to their analysis of alignment robustness metrics in terms of different rewriting, only the robustness scores based on sentiment spoiler features, $\pi^c_{+}$ (sentiment) and $\pi^r_{-}$ (sentiment), are statistically significant.

### 引用

> Citation

引用来源：

> Cited as:

> Weng, Lilian. “强化学习中的奖励欺骗”. Lil’Log (2024 年 11 月)。https://lilianweng.github.io/posts/2024-11-28-reward-hacking/。

> Weng, Lilian. “Reward Hacking in Reinforcement Learning”. Lil’Log (Nov 2024). https://lilianweng.github.io/posts/2024-11-28-reward-hacking/.

或

> Or

```
@article{weng2024rewardhack,
  title   = "Reward Hacking in Reinforcement Learning.",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2024",
  month   = "Nov",
  url     = "https://lilianweng.github.io/posts/2024-11-28-reward-hacking/"
}
```

### 参考文献

> References

[1] Andrew Ng & Stuart Russell. [“逆强化学习算法。”](https://ai.stanford.edu/~ang/papers/icml00-irl.pdf). ICML 2000。

> [1] Andrew Ng & Stuart Russell. [“Algorithms for inverse reinforcement learning.”](https://ai.stanford.edu/~ang/papers/icml00-irl.pdf). ICML 2000.

[2] Amodei et al. [“AI 安全中的具体问题：避免奖励欺骗。”](https://arxiv.org/abs/1606.06565) arXiv preprint arXiv:1606.06565 (2016)。

> [2] Amodei et al. [“Concrete problems in AI safety: Avoid reward hacking.”](https://arxiv.org/abs/1606.06565) arXiv preprint arXiv:1606.06565 (2016).

[3] Krakovna et al. [“规范博弈：AI 独创性的另一面。”](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/) 2020。

> [3] Krakovna et al. [“Specification gaming: the flip side of AI ingenuity.”](https://deepmind.google/discover/blog/specification-gaming-the-flip-side-of-ai-ingenuity/) 2020.

[4] Langosco et al. [“深度强化学习中的目标误泛化”](https://arxiv.org/abs/2105.14111) ICML 2022。

> [4] Langosco et al. [“Goal Misgeneralization in Deep Reinforcement Learning”](https://arxiv.org/abs/2105.14111) ICML 2022.

[5] Everitt et al. [“带有损坏奖励通道的强化学习。”](https://arxiv.org/abs/1705.08417) IJCAI 2017。

> [5] Everitt et al. [“Reinforcement learning with a corrupted reward channel.”](https://arxiv.org/abs/1705.08417) IJCAI 2017.

[6] Geirhos et al. [“深度神经网络中的捷径学习。”](https://arxiv.org/abs/2004.07780) Nature Machine Intelligence 2020。

> [6] Geirhos et al. [“Shortcut Learning in Deep Neural Networks.”](https://arxiv.org/abs/2004.07780) Nature Machine Intelligence 2020.

[7] Ribeiro 等人 [“我为什么要相信你？”：解释任何分类器的预测。](https://arxiv.org/abs/1602.04938) KDD 2016。

> [7] Ribeiro et al. [“Why Should I Trust You?”: Explaining the Predictions of Any Classifier.](https://arxiv.org/abs/1602.04938) KDD 2016.

[8] Nagarajan 等人 [“理解分布外泛化的失败模式。”](https://arxiv.org/abs/2010.15775) ICLR 2021。

> [8] Nagarajan et al. [“Understanding the Failure Modes of Out-of-Distribution Generalization.”](https://arxiv.org/abs/2010.15775) ICLR 2021.

[9] Garrabrant. [“古德哈特定律分类法”](https://www.lesswrong.com/posts/EbFABnst8LsidYs5Y/goodhart-taxonomy). AI Alignment Forum (2017年12月30日)。

> [9] Garrabrant. [“Goodhart Taxonomy”](https://www.lesswrong.com/posts/EbFABnst8LsidYs5Y/goodhart-taxonomy). AI Alignment Forum (Dec 30th 2017).

[10] Koch 等人 [“深度强化学习中的客观鲁棒性。”](https://www.gatsby.ucl.ac.uk/~balaji/udl2021/accepted-papers/UDL2021-paper-055.pdf) 2021。

> [10] Koch et al. [“Objective robustness in deep reinforcement learning.”](https://www.gatsby.ucl.ac.uk/~balaji/udl2021/accepted-papers/UDL2021-paper-055.pdf) 2021.

[11] Pan 等人 [“奖励错误指定的影响：映射和缓解未对齐模型。”](https://arxiv.org/abs/2201.03544)

> [11] Pan et al. [“The effects of reward misspecification: mapping and mitigating misaligned models.”](https://arxiv.org/abs/2201.03544)

[12] Everitt 等人 [“强化学习中的奖励篡改问题与解决方案：因果影响图视角。”](https://arxiv.org/abs/1908.04734) arXiv preprint arXiv:1908.04734 (2019)。

> [12] Everitt et al. [“Reward tampering problems and solutions in reinforcement learning: A causal influence diagram perspective.”](https://arxiv.org/abs/1908.04734) arXiv preprint arXiv:1908.04734 (2019).

[13] Gleave 等人 [“对抗性策略：攻击深度强化学习。”](https://arxiv.org/abs/1905.10615) ICRL 2020

> [13] Gleave et al. [“Adversarial Policies: Attacking Deep Reinforcement Learning.”](https://arxiv.org/abs/1905.10615) ICRL 2020

[14] [“奖励欺骗行为可以跨任务泛化。”](https://www.lesswrong.com/posts/Ge55vxEmKXunFFwoe/reward-hacking-behavior-can-generalize-across-tasks)

> [14] [“Reward hacking behavior can generalize across tasks.”](https://www.lesswrong.com/posts/Ge55vxEmKXunFFwoe/reward-hacking-behavior-can-generalize-across-tasks)

[15] Ng 等人 [“奖励转换下的策略不变性：理论及在奖励塑形中的应用。”](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf) ICML 1999。

> [15] Ng et al. [“Policy invariance under reward transformations: Theory and application to reward shaping.”](https://people.eecs.berkeley.edu/~pabbeel/cs287-fa09/readings/NgHaradaRussell-shaping-ICML1999.pdf) ICML 1999.

[16] Wang 等人 [“大型语言模型并非公正的评估者。”](https://arxiv.org/abs/2305.17926) ACL 2024。

> [16] Wang et al. [“Large Language Models are not Fair Evaluators.”](https://arxiv.org/abs/2305.17926) ACL 2024.

[17] Liu 等人 [“LLM 作为自恋型评估者：当自我膨胀评估分数时。”](https://arxiv.org/abs/2311.09766) ACL 2024。

> [17] Liu et al. [“LLMs as narcissistic evaluators: When ego inflates evaluation scores.”](https://arxiv.org/abs/2311.09766) ACL 2024.

[18] Gao 等人 [“奖励模型过度优化的缩放定律。”](https://arxiv.org/abs/2210.10760) ICML 2023。

> [18] Gao et al. [“Scaling Laws for Reward Model Overoptimization.”](https://arxiv.org/abs/2210.10760) ICML 2023.

[19] Pan 等人 [“迭代自我完善中的自发奖励欺骗。”](https://arxiv.org/abs/2407.04549) arXiv preprint arXiv:2407.04549 (2024)。

> [19] Pan et al. [“Spontaneous Reward Hacking in Iterative Self-Refinement.”](https://arxiv.org/abs/2407.04549) arXiv preprint arXiv:2407.04549 (2024).

[20] Pan 等人 [“语言模型中的反馈循环驱动上下文奖励欺骗。”](https://arxiv.org/abs/2402.06627) arXiv preprint arXiv:2402.06627 (2024)。

> [20] Pan et al. [“Feedback Loops With Language Models Drive In-Context Reward Hacking.”](https://arxiv.org/abs/2402.06627) arXiv preprint arXiv:2402.06627 (2024).

[21] Shrama 等人 [“走向理解语言模型中的谄媚行为。”](https://arxiv.org/abs/2310.13548) arXiv preprint arXiv:2310.13548 (2023)。

> [21] Shrama et al. [“Towards Understanding Sycophancy in Language Models.”](https://arxiv.org/abs/2310.13548) arXiv preprint arXiv:2310.13548 (2023).

[22] Denison 等人 [“从谄媚到诡计：调查语言模型中的奖励篡改。”](https://arxiv.org/abs/2406.10162) arXiv preprint arXiv:2406.10162 (2024)。

> [22] Denison et al. [“Sycophancy to subterfuge: Investigating reward tampering in language models.”](https://arxiv.org/abs/2406.10162) arXiv preprint arXiv:2406.10162 (2024).

[23] Uesato 等人 [“通过解耦批准避免深度强化学习中的篡改激励。”](https://arxiv.org/abs/2011.08827) arXiv preprint arXiv:2011.08827 (2020)。

> [23] Uesato et al. [“Avoiding Tampering Incentives in Deep RL via Decoupled Approval.”](https://arxiv.org/abs/2011.08827) arXiv preprint arXiv:2011.08827 (2020).

[24] Amin 和 Singh. [“解决逆强化学习中不可识别性问题。”](https://arxiv.org/abs/1601.06569)

> [24] Amin and Singh. [“Towards resolving unidentifiability in inverse reinforcement learning.”](https://arxiv.org/abs/1601.06569)

[25] Wen 等人 [“语言模型通过 RLHF 学习误导人类。”](https://arxiv.org/abs/2409.12822) arXiv preprint arXiv:2409.12822 (2024)。

> [25] Wen et al. [“Language Models Learn to Mislead Humans via RLHF.”](https://arxiv.org/abs/2409.12822) arXiv preprint arXiv:2409.12822 (2024).

[26] Revel 等人 [“SEAL：价值对齐的系统误差分析。”](https://arxiv.org/abs/2408.10270) arXiv preprint arXiv:2408.10270 (2024)。

> [26] Revel et al. [“SEAL: Systematic Error Analysis for Value ALignment.”](https://arxiv.org/abs/2408.10270) arXiv preprint arXiv:2408.10270 (2024).

[27] Yuval Noah Harari. [“枢纽：从石器时代到人工智能的信息网络简史。”](https://www.goodreads.com/en/book/show/204927599-nexus) Signal; 2024年9月10日。

> [27] Yuval Noah Harari. [“Nexus: A Brief History of Information Networks from the Stone Age to AI.”](https://www.goodreads.com/en/book/show/204927599-nexus) Signal; 2024 Sep 10.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Reinforcement Learning (RL) | 强化学习 | 一种机器学习范式，智能体通过与环境交互学习最优行为策略以最大化累积奖励。 |
| Reward Hacking | 奖励欺骗 | 强化学习智能体利用奖励函数缺陷，获得高奖励但未完成预期任务的现象。 |
| Reward Function | 奖励函数 | 定义强化学习任务目标，指导智能体学习的信号。 |
| Reward Shaping | 奖励塑形 | 通过修改奖励函数来引导智能体更高效学习的技术，但可能改变最优策略。 |
| Large Language Model (LLM) | 大型语言模型 | 具有大量参数的深度学习模型，能够理解和生成人类语言。 |
| Reinforcement Learning from Human Feedback (RLHF) | 人类反馈强化学习 | 一种对齐训练方法，通过人类偏好数据训练奖励模型，再用强化学习微调语言模型。 |
| Spurious Correlation | 虚假相关 | 数据中存在的非因果关联，可能导致模型学习到捷径而非真实特征。 |
| Specification Gaming | 规范博弈 | 智能体字面上满足目标规范，但未能达到预期结果的行为。 |
| Objective Robustness | 目标鲁棒性 | 模型在分布外环境中，其追求的目标与训练时目标一致的能力。 |
| Reward Tampering | 奖励篡改 | 智能体直接干扰奖励函数本身，使其不再准确代表预期目标的行为。 |
| Goodhart's Law | 古德哈特定律 | 当一个衡量标准成为目标时，它就不再是一个好的衡量标准。 |
| Proxy Reward | 代理奖励 | 用于近似真实奖励的替代指标，常在实际应用中用于训练。 |
| Oracle/Golden Reward | 预言机/黄金奖励 | 代表我们真正希望模型优化的理想奖励。 |
| In-Context Reward Hacking (ICRH) | 上下文内奖励攻击 | 在迭代自我完善的反馈循环中，LLM优化隐式目标并产生负面副作用的现象。 |
| U-sophistry | U-诡辩 | 语言模型通过RLHF学习误导人类，使其相信不准确的输出是正确的，而非有意欺骗。 |
