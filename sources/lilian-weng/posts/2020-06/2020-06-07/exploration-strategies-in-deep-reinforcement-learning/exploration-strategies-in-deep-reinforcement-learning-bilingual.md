# 深度强化学习中的探索策略

> Exploration Strategies in Deep Reinforcement Learning

> 来源：Lil'Log / Lilian Weng，2020-06-07
> 原文链接：https://lilianweng.github.io/posts/2020-06-07-exploration-drl/
> 分类：深度强化学习 / 探索策略

## 核心要点

- 深度强化学习面临探索与利用的平衡挑战，尽管利用效率高，但有效探索仍是研究热点。
- 文章首先回顾了ε-贪婪、上置信界等经典探索策略，并指出硬探索和噪声电视是当前深度强化学习探索中的关键难题。
- 内在奖励是解决硬探索问题的常用方法，它通过额外信号鼓励智能体探索，其形式包括基于状态访问计数的奖励和基于智能体对环境知识提升的预测误差奖励。
- 基于预测的探索策略通过学习前向动力学模型、逆动力学模型或利用随机网络蒸馏（RND）等方法，将预测误差或信息增益作为内在奖励来驱动智能体探索。
- 为克服奖励衰退和非平稳性，基于记忆的探索方法如NGU和Agent57结合了情景新颖性与终身新颖性模块，而Go-Explore则通过记忆和模仿学习解决硬探索。
- Q值探索通过自举DQN引入Q值不确定性，或结合随机先验函数，以及变分选项方法通过建模策略和潜在技能变量，为深度强化学习提供了多样化的探索机制。

## 正文

[2020-06-17 更新：添加[“通过分歧进行探索”](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#exploration-via-disagreement)到“前向动力学”[部分](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#forward-dynamics)。

> [Updated on 2020-06-17: Add [“exploration via disagreement”](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#exploration-via-disagreement) in the “Forward Dynamics” [section](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#forward-dynamics).

[利用与探索](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/)是强化学习中的一个关键主题。我们希望强化学习智能体能尽快找到最佳解决方案。然而，与此同时，在没有充分探索的情况下过快地确定解决方案听起来相当糟糕，因为它可能导致局部最优或彻底失败。现代[RL](https://lilianweng.github.io/posts/2018-02-19-rl-overview/)[算法](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/)通过优化最佳回报，可以相当有效地实现良好的利用，而探索仍然更像是一个开放性话题。

> [Exploitation versus exploration](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/) is a critical topic in Reinforcement Learning. We’d like the RL agent to find the best solution as fast as possible. However, in the meantime, committing to solutions too quickly without enough exploration sounds pretty bad, as it could lead to local minima or total failure. Modern [RL](https://lilianweng.github.io/posts/2018-02-19-rl-overview/) [algorithms](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/) that optimize for the best returns can achieve good exploitation quite efficiently, while exploration remains more like an open topic.

我想在这里讨论几种深度强化学习中常见的探索策略。由于这是一个非常大的主题，我的文章绝不能涵盖所有重要的子主题。我计划定期更新并随着时间的推移逐步丰富内容。

> I would like to discuss several common exploration strategies in Deep RL here. As this is a very big topic, my post by no means can cover all the important subtopics. I plan to update it periodically and keep further enriching the content gradually in time.

### 经典探索策略

> Classic Exploration Strategies

作为快速回顾，我们首先回顾几种在多臂赌博机问题或简单表格型强化学习中表现相当不错的经典探索算法。

> As a quick recap, let’s first go through several classic exploration algorithms that work out pretty well in the multi-armed bandit problem or simple tabular RL.

• **ε-贪婪**: 智能体偶尔以概率 $\epsilon$ 进行随机探索，并在大多数时间以概率 $1-\epsilon$ 采取最优行动。

• **上置信界**: 智能体选择最贪婪的行动以最大化上置信界 $\hat{Q}_t(a) + \hat{U}_t(a)$，其中 $\hat{Q}_t(a)$ 是与行动 $a$ 相关联的截至时间 $t$ 的平均奖励，$\hat{U}_t(a)$ 是一个与行动 $a$ 已被采取的次数成反比的函数。更多详情请参见[此处](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#upper-confidence-bounds)。

• **玻尔兹曼探索**：智能体从[玻尔兹曼分布](https://en.wikipedia.org/wiki/Boltzmann_distribution)(softmax) 对学习到的Q值进行，由温度参数调节$\tau$。

• **汤普森采样**：智能体跟踪关于最优动作概率的信念，并从该分布中进行采样。更多详情请参见[此处](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#thompson-sampling)。

英文原文：

• **Epsilon-greedy**: The agent does random exploration occasionally with probability $\epsilon$ and takes the optimal action most of the time with probability $1-\epsilon$.

• **Upper confidence bounds**: The agent selects the greediest action to maximize the upper confidence bound $\hat{Q}_t(a) + \hat{U}_t(a)$, where $\hat{Q}_t(a)$ is the average rewards associated with action $a$ up to time $t$ and $\hat{U}_t(a)$ is a function reversely proportional to how many times action $a$ has been taken. See [here](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#upper-confidence-bounds) for more details.

• **Boltzmann exploration**: The agent draws actions from a [boltzmann distribution](https://en.wikipedia.org/wiki/Boltzmann_distribution) (softmax) over the learned Q values, regulated by a temperature parameter $\tau$.

• **Thompson sampling**: The agent keeps track of a belief over the probability of optimal actions and samples from this distribution. See [here](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#thompson-sampling) for more details.

当神经网络用于函数逼近时，以下策略可用于深度强化学习训练中更好的探索：

> The following strategies could be used for better exploration in deep RL training when neural networks are used for function approximation:

• **熵损失项**: 在损失函数中加入一个熵项$H(\pi(a \vert s))$，鼓励策略采取多样化的行动。

• **基于噪声的探索**: 在观测、动作甚至参数空间中加入噪声 ([Fortunato, et al. 2017](https://arxiv.org/abs/1706.10295), [Plappert, et al. 2017](https://arxiv.org/abs/1706.01905))。

英文原文：

• **Entropy loss term**: Add an entropy term $H(\pi(a \vert s))$ into the loss function, encouraging the policy to take diverse actions.

• **Noise-based Exploration**: Add noise into the observation, action or even parameter space ([Fortunato, et al. 2017](https://arxiv.org/abs/1706.10295), [Plappert, et al. 2017](https://arxiv.org/abs/1706.01905)).

### 关键探索问题

> Key Exploration Problems

当环境很少提供奖励作为反馈，或者环境存在干扰性噪声时，良好的探索变得尤为困难。许多探索策略被提出，旨在解决以下一个或两个问题。

> Good exploration becomes especially hard when the environment rarely provides rewards as feedback or the environment has distracting noise. Many exploration strategies are proposed to solve one or both of the following problems.

#### 硬探索问题

> The Hard-Exploration Problem

“硬探索”问题指的是在奖励非常稀疏甚至具有欺骗性的环境中进行探索。这很困难，因为在这种情况下，随机探索很少能发现成功的状态或获得有意义的反馈。

> The “hard-exploration” problem refers to exploration in an environment with very sparse or even deceptive reward. It is difficult because random exploration in such scenarios can rarely discover successful states or obtain meaningful feedback.

[蒙特祖玛的复仇](https://en.wikipedia.org/wiki/Montezuma%27s_Revenge_(video_game))是硬探索问题的一个具体例子。它仍然是Atari中少数几个DRL难以解决的挑战性游戏。许多论文使用蒙特祖玛的复仇来衡量其结果。

> [Montezuma’s Revenge](https://en.wikipedia.org/wiki/Montezuma%27s_Revenge_(video_game)) is a concrete example for the hard-exploration problem. It remains as a few challenging games in Atari for DRL to solve. Many papers use Montezuma’s Revenge to benchmark their results.

#### 噪声电视问题

> The Noisy-TV Problem

“噪声电视”问题最初是[Burda, et al (2018)](https://arxiv.org/abs/1810.12894)中的一个思想实验。想象一个强化学习智能体因寻求新颖体验而获得奖励，一台输出不可控且不可预测的随机噪声的电视将能够永远吸引智能体的注意力。智能体持续从噪声电视中获得新奖励，但它未能取得任何有意义的进展，并成为了一个“沙发土豆”。

> The “Noisy-TV” problem started as a thought experiment in [Burda, et al (2018)](https://arxiv.org/abs/1810.12894). Imagine that an RL agent is rewarded with seeking novel experience, a TV with uncontrollable & unpredictable random noise outputs would be able to attract the agent’s attention forever. The agent obtains new rewards from noisy TV consistently, but it fails to make any meaningful progress and becomes a “couch potato”.

![An agent is rewarded with novel experience in the experiment. If a maze has a noisy TC set up, the agent would be attracted and stop moving in the maze. (Image source: OpenAI Blog: "Reinforcement Learning with Prediction-Based Rewards" )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/the-noisy-TV-problem.gif)

### 内在奖励作为探索奖励

> Intrinsic Rewards as Exploration Bonuses

一种改善探索的常见方法，特别是为了解决[硬探索](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#the-hard-exploration-problem)问题，是用额外的奖励信号来增强环境奖励，以鼓励额外的探索。因此，策略通过由两项组成的奖励进行训练，$r_t = r^e_t + \beta r^i_t$，其中$\beta$是一个超参数，用于调整利用和探索之间的平衡。

> One common approach to better exploration, especially for solving the [hard-exploration](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#the-hard-exploration-problem) problem, is to augment the environment reward with an additional bonus signal to encourage extra exploration. The policy is thus trained with a reward composed of two terms, $r_t = r^e_t + \beta r^i_t$, where $\beta$ is a hyperparameter adjusting the balance between exploitation and exploration.

• $r^e_t$ 是在时间 $t$ 从环境中获得的*外在*奖励，根据手头的任务定义。

• $r^i_t$ 是在时间 $t$ 的*内在*探索奖励。

英文原文：

• $r^e_t$ is an *extrinsic* reward from the environment at time $t$, defined according to the task in hand.

• $r^i_t$ is an *intrinsic* exploration bonus at time $t$.

这种内在奖励在某种程度上受到了心理学中*内在动机*的启发（[Oudeyer & Kaplan, 2008](https://www.researchgate.net/profile/Pierre-Yves_Oudeyer/publication/29614795_How_can_we_define_intrinsic_motivation/links/09e415107f1b4c8041000000/How-can-we-define-intrinsic-motivation.pdf)）。好奇心驱动的探索可能是儿童成长和学习的重要方式。换句话说，探索性活动在人类思维中应该具有内在奖励性，以鼓励这种行为。内在奖励可能与好奇心、惊喜、状态的熟悉程度以及许多其他因素相关。

> This intrinsic reward is somewhat inspired by *intrinsic motivation* in psychology ([Oudeyer & Kaplan, 2008](https://www.researchgate.net/profile/Pierre-Yves_Oudeyer/publication/29614795_How_can_we_define_intrinsic_motivation/links/09e415107f1b4c8041000000/How-can-we-define-intrinsic-motivation.pdf)). Exploration driven by curiosity might be an important way for children to grow and learn. In other words, exploratory activities should be rewarding intrinsically in the human mind to encourage such behavior. The intrinsic rewards could be correlated with curiosity, surprise, familiarity of the state, and many other factors.

同样的思想可以应用于强化学习（RL）算法。在以下章节中，基于奖励的探索奖励方法大致分为两类：

> Same ideas can be applied to RL algorithms. In the following sections, methods of bonus-based exploration rewards are roughly grouped into two categories:

1. 新颖状态的发现
2. 改善智能体对环境的了解。

> • Discovery of novel states
> • Improvement of the agent’s knowledge about the environment.

#### 基于计数的探索

> Count-based Exploration

如果我们将内在奖励视为令我们感到惊讶的奖励条件，那么我们需要一种方法来衡量某个状态是新颖的还是经常出现的。一种直观的方法是计算某个状态被遇到的次数，并据此分配一个奖励。这个奖励会引导智能体的行为，使其偏好很少访问的状态而非常见状态。这被称为**基于计数的探索**方法。

> If we consider intrinsic rewards as rewarding conditions that surprise us, we need a way to measure whether a state is novel or appears often. One intuitive way is to count how many times a state has been encountered and to assign a bonus accordingly. The bonus guides the agent’s behavior to prefer rarely visited states to common states. This is known as the **count-based exploration** method.

令 $N_n(s)$ 为 *经验计数*函数，它跟踪状态 $s$ 在序列 $s_{1:n}$ 中被访问的实际次数。不幸的是，直接使用 $N_n(s)$ 进行探索是不切实际的，因为大多数状态都会有 $N_n(s)=0$，特别是考虑到状态空间通常是连续的或高维的。我们需要为大多数状态提供一个非零计数，即使它们以前从未被见过。

> Let $N_n(s)$ be the *empirical count* function that tracks the real number of visits of a state $s$ in the sequence of $s_{1:n}$. Unfortunately, using $N_n(s)$ for exploration directly is not practical, because most of the states would have $N_n(s)=0$, especially considering that the state space is often continuous or high-dimensional. We need an non-zero count for most states, even when they haven’t been seen before.

##### 密度模型计数

> Counting by Density Model

[Bellemare, et al. (2016)](https://arxiv.org/abs/1606.01868)使用了一种**密度模型**来近似状态访问的频率，并使用一种新颖的算法来推导*伪计数*从该密度模型中。我们首先定义状态空间上的条件概率，$\rho_n(s) = \rho(s \vert s_{1:n})$即为$(n+1)$个状态是`s`，给定前`n`个状态为`s_{1:n}`。为了经验性地衡量这一点，我们可以简单地使用$N_n(s)/n$。

英文原文：[Bellemare, et al. (2016)](https://arxiv.org/abs/1606.01868) used a density model to approximate the frequency of state visits and a novel algorithm for deriving a *pseudo-count* from this density model. Let’s first define a conditional probability over the state space, 

$\rho_n(s) = \rho(s \vert s_{1:n})$ as the probability of the 

$(n+1)$ -th state being `s` given the first `n` states are `s_{1:n}`. To measure this empirically, we can simply use 

$N_n(s)/n$.

我们还定义一个状态$s$的*重编码概率*为密度模型在$s$*观察到$s$的新出现后*所分配的概率，$\rho’_n(s) = \rho(s \vert s_{1:n}s)$。

> Let’s also define a *recoding probability* of a state $s$ as the probability assigned by the density model to $s$ *after observing a new occurrence of* $s$, $\rho’_n(s) = \rho(s \vert s_{1:n}s)$.

该论文引入了两个概念来更好地调节密度模型，一个是*伪计数*函数$\hat{N}_n(s)$，另一个是*伪计数总和*$\hat{n}$。由于它们旨在模仿经验计数函数，因此我们有：

> The paper introduced two concepts to better regulate the density model, a *pseudo-count* function $\hat{N}_n(s)$ and a *pseudo-count total* $\hat{n}$. As they are designed to imitate an empirical count function, we would have:

$$
\rho_n(s) = \frac{\hat{N}_n(s)}{\hat{n}} \leq \rho'_n(s) = \frac{\hat{N}_n(s) + 1}{\hat{n} + 1}
$$

$\rho_n(x)$和$\rho’_n(x)$之间的关系要求密度模型是*学习正向的*：对于所有$s_{1:n} \in \mathcal{S}^n$和所有$s \in \mathcal{S}$，$\rho_n(s) \leq \rho’_n(s)$。换句话说，在观察到$s$的一个实例后，密度模型对同一$s$的预测应该增加。除了是学习正向的之外，密度模型应该完全*在线*地使用非随机化的经验状态小批量进行训练，因此我们自然有$\rho’_n = \rho_{n+1}$。

> The relationship between $\rho_n(x)$ and $\rho’_n(x)$ requires the density model to be *learning-positive*:  for all $s_{1:n} \in \mathcal{S}^n$ and all $s \in \mathcal{S}$, $\rho_n(s) \leq \rho’_n(s)$. In other words, After observing one instance of $s$, the density model’s prediction of that same $s$ should increase. Apart from being learning-positive, the density model should be trained completely *online* with non-randomized mini-batches of experienced states, so naturally we have $\rho’_n = \rho_{n+1}$.

在求解上述线性系统后，可以从$\rho_n(s)$和$\rho’_n(s)$计算伪计数：

> The pseudo-count can be computed from $\rho_n(s)$ and $\rho’_n(s)$ after solving the above linear system:

$$
\hat{N}_n(s) = \hat{n} \rho_n(s) = \frac{\rho_n(s)(1 - \rho'_n(s))}{\rho'_n(s) - \rho_n(s)}
$$

或者通过*预测增益（PG）*来估计：

> Or estimated by the *prediction gain (PG)*:

$$
\hat{N}_n(s) \approx (e^{\text{PG}_n(s)} - 1)^{-1} = (e^{\log \rho'_n(s) - \log \rho(s)} - 1)^{-1}
$$

基于计数的内在奖励的常见选择是$r^i_t = N(s_t, a_t)^{-1/2}$（如MBIE-EB中；[Strehl & Littman, 2008](https://www.ics.uci.edu/~dechter/courses/ics-295/fall-2019/papers/2008-littman-aij-main.pdf)）。基于伪计数的探索奖励形式类似，为$r^i_t = \big(\hat{N}_n(s_t, a_t) + 0.01 \big)^{-1/2}$。

> A common choice of a count-based intrinsic bonus is $r^i_t = N(s_t, a_t)^{-1/2}$ (as in MBIE-EB; [Strehl & Littman, 2008](https://www.ics.uci.edu/~dechter/courses/ics-295/fall-2019/papers/2008-littman-aij-main.pdf)). The pseudo-count-based exploration bonus is shaped in a similar form, $r^i_t = \big(\hat{N}_n(s_t, a_t) + 0.01 \big)^{-1/2}$.

在[Bellemare et al., (2016)](https://arxiv.org/abs/1606.01868)中的实验采用了一个简单的[CTS](http://proceedings.mlr.press/v32/bellemare14.html)（上下文树切换）密度模型来估计伪计数。CTS模型将2D图像作为输入，并根据位置相关的L形滤波器的乘积为其分配概率，其中每个滤波器的预测由在过去图像上训练的CTS算法给出。CTS模型简单但表达能力、可扩展性和数据效率有限。在后续论文中，[Georg Ostrovski, et al. (2017)](https://arxiv.org/abs/1703.01310)通过训练一个PixelCNN（[van den Oord et al., 2016](https://arxiv.org/abs/1606.05328)）作为密度模型来改进了该方法。

> Experiments in [Bellemare et al., (2016)](https://arxiv.org/abs/1606.01868) adopted a simple [CTS](http://proceedings.mlr.press/v32/bellemare14.html) (Context Tree Switching) density model to estimate pseudo-counts. The CTS model takes as input a 2D image and assigns to it a probability according to the product of location-dependent L-shaped filters, where the prediction of each filter is given by a CTS algorithm trained on past images. The CTS model is simple but limited in expressiveness, scalability, and data efficiency. In a following-up paper, [Georg Ostrovski, et al. (2017)](https://arxiv.org/abs/1703.01310) improved the approach by training a PixelCNN ([van den Oord et al., 2016](https://arxiv.org/abs/1606.05328)) as the density model.

密度模型也可以是高斯混合模型，如[Zhao & Tresp (2018)](https://arxiv.org/abs/1902.08039)中所示。他们使用变分GMM来估计轨迹（例如，状态序列的串联）的密度及其预测概率，以在离策略设置中指导经验回放的优先级。

> The density model can also be a Gaussian Mixture Model as in [Zhao & Tresp (2018)](https://arxiv.org/abs/1902.08039). They used a variational GMM to estimate the density of trajectories (e.g. concatenation of a sequence of states) and its predicted probabilities to guide prioritization in experience replay in off-policy setting.

##### 哈希后的计数

> Counting after Hashing

另一个使高维状态计数成为可能的方法是将状态映射到**哈希码**，以便状态的出现变得可追踪（[Tang et al. 2017](https://arxiv.org/abs/1611.04717)）。状态空间通过哈希函数$\phi: \mathcal{S} \mapsto \mathbb{Z}^k$进行离散化。一个探索奖励$r^{i}: \mathcal{S} \mapsto \mathbb{R}$被添加到奖励函数中，定义为$r^{i}(s) = {N(\phi(s))}^{-1/2}$，其中$N(\phi(s))$是$\phi(s)$出现次数的经验计数。

英文原文：Another idea to make it possible to count high-dimensional states is to map states into hash codes so that the occurrences of states become trackable ([Tang et al. 2017](https://arxiv.org/abs/1611.04717)). The state space is discretized with a hash function 

$\phi: \mathcal{S} \mapsto \mathbb{Z}^k$. An exploration bonus 

$r^{i}: \mathcal{S} \mapsto \mathbb{R}$ is added to the reward function, defined as 

$r^{i}(s) = {N(\phi(s))}^{-1/2}$, where 

$N(\phi(s))$ is an empirical count of occurrences of 

$\phi(s)$.

[Tang et al. (2017)](https://arxiv.org/abs/1611.04717)提出使用*局部敏感哈希*（[LSH](https://en.wikipedia.org/wiki/Locality-sensitive_hashing)）将连续的高维数据转换为离散的哈希码。LSH是一类流行的哈希函数，用于根据某些相似性度量查询最近邻。如果哈希方案$x \mapsto h(x)$保留了数据点之间的距离信息，使得接近的向量获得相似的哈希值，而遥远的向量具有非常不同的哈希值，那么它就是局部敏感的。（如果感兴趣，请参阅LSH在[Transformer改进](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#LSH)中的用法。）[SimHash](https://www.cs.princeton.edu/courses/archive/spr04/cos598B/bib/CharikarEstim.pdf)是一种计算高效的LSH类型，它通过角距离测量相似性：

> [Tang et al. (2017)](https://arxiv.org/abs/1611.04717) proposed to use *Locality-Sensitive Hashing* ([LSH](https://en.wikipedia.org/wiki/Locality-sensitive_hashing)) to convert continuous, high-dimensional data to discrete hash codes. LSH is a popular class of hash functions for querying nearest neighbors based on certain similarity metrics. A hashing scheme $x \mapsto h(x)$ is locality-sensitive if it preserves the distancing information between data points, such that close vectors obtain similar hashes while distant vectors have very different ones. (See how LSH is used in [Transformer improvement](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#LSH) if interested.) [SimHash](https://www.cs.princeton.edu/courses/archive/spr04/cos598B/bib/CharikarEstim.pdf) is a type of computationally efficient LSH and it measures similarity by angular distance:

$$
\phi(s) = \text{sgn}(A g(s)) \in \{-1, 1\}^k
$$

其中 $A \in \mathbb{R}^{k \times D}$ 是一个矩阵，其每个条目都独立同分布地从标准高斯分布中抽取，$g: \mathcal{S} \mapsto \mathbb{R}^D$ 是一个可选的预处理函数。二进制码的维度是 $k$，它控制着状态空间离散化的粒度。更高的 $k$ 会带来更高的粒度和更少的冲突。

> where $A \in \mathbb{R}^{k \times D}$ is a matrix with each entry drawn i.i.d. from a standard Gaussian and $g: \mathcal{S} \mapsto \mathbb{R}^D$ is an optional preprocessing function. The dimension of binary codes is $k$, controlling the granularity of the state space discretization. A higher $k$ leads to higher granularity and fewer collisions.

![Algorithm of count-based exploration through hashing high-dimensional states by SimHash. (Image source: Tang et al. 2017 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/count-hashing-exploration.png)

对于高维图像，SimHash 在原始像素级别可能表现不佳。[Tang 等人 (2017)](https://arxiv.org/abs/1611.04717) 设计了一个自编码器 (AE)，它以状态 $s$ 作为输入来学习哈希码。它有一个特殊的密集层，由 $k$ 个 sigmoid 函数组成，作为中间的潜在状态，然后该层的 sigmoid 激活值 $b(s)$ 通过四舍五入到最接近的二进制数 $\lfloor b(s)\rceil \in \{0, 1\}^D$ 进行二值化，作为状态 $s$ 的二进制哈希码。AE 在 $n$ 个状态上的损失包括两项：

> For high-dimensional images, SimHash may not work well on the raw pixel level. [Tang et al. (2017)](https://arxiv.org/abs/1611.04717) designed an autoencoder (AE) which takes as input states $s$ to learn hash codes. It has one special dense layer composed of $k$ sigmoid functions as the latent state in the middle and then the sigmoid activation values $b(s)$ of this layer are binarized by rounding to their closest binary numbers $\lfloor b(s)\rceil \in \{0, 1\}^D$ as the binary hash codes for state $s$. The AE loss over $n$ states includes two terms:

$$
\mathcal{L}(\{s_n\}_{n=1}^N) = \underbrace{-\frac{1}{N} \sum_{n=1}^N \log p(s_n)}_\text{reconstruction loss} + \underbrace{\frac{1}{N} \frac{\lambda}{K} \sum_{n=1}^N\sum_{i=1}^k \min \big \{ (1-b_i(s_n))^2, b_i(s_n)^2 \big\}}_\text{sigmoid activation being closer to binary}
$$

这种方法的一个问题是，不同的输入$s_i, s_j$可能会被映射到相同的哈希码，但AE仍然能完美地重建它们。可以想象将瓶颈层$b(s)$替换为哈希码$\lfloor b(s)\rceil$，但梯度无法通过舍入函数反向传播。注入均匀噪声可以减轻这种影响，因为AE必须学习将潜在变量推开以抵消噪声。

> One problem with this approach is that dissimilar inputs $s_i, s_j$ may be mapped to identical hash codes but the AE still reconstructs them perfectly. One can imagine replacing the bottleneck layer $b(s)$ with the hash codes $\lfloor b(s)\rceil$, but then gradients cannot be back-propagated through the rounding function. Injecting uniform noise could mitigate this effect, as the AE has to learn to push the latent variable far apart to counteract the noise.

#### 基于预测的探索

> Prediction-based Exploration

第二类内在探索奖励是奖励智能体对环境知识的提升。智能体对环境动态的熟悉程度可以通过预测模型来估计。这种使用预测模型来衡量*好奇心*的想法实际上在很久以前就被提出了（[Schmidhuber, 1991](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.45.957)）。

> The second category of intrinsic exploration bonuses are rewarded for improvement of the agent’s knowledge about the environment. The agent’s familiarity with the environment dynamics can be estimated through a prediction model. This idea of using a prediction model to measure *curiosity* was actually proposed quite a long time ago ([Schmidhuber, 1991](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.45.957)).

##### 前向动力学

> Forward Dynamics

学习一个**前向动力学预测模型**是衡量我们的模型对环境和任务MDPs获得了多少知识的好方法。它捕捉了智能体预测自身行为后果的能力，$f: (s_t, a_t) \mapsto s_{t+1}$。这样的模型不可能完美（例如，由于部分观测），其误差$e(s_t, a_t) = | f(s_t, a_t) - s_{t+1} |^2_2$可以用于提供内在探索奖励。预测误差越高，我们对该状态的熟悉程度越低。误差率下降得越快，我们获得的学习进展信号就越多。

英文原文：Learning a forward dynamics prediction model is a great way to approximate how much knowledge our model has obtained about the environment and the task MDPs. It captures an agent’s capability of predicting the consequence of its own behavior, 

$f: (s_t, a_t) \mapsto s_{t+1}$. Such a model cannot be perfect (e.g. due to partial observation), the error 

$e(s_t, a_t) = | f(s_t, a_t) - s_{t+1} |^2_2$ can be used for providing intrinsic exploration rewards. The higher the prediction error, the less familiar we are with that state.  The faster the error rate drops, the more learning progress signals we acquire.

*智能自适应好奇心*（**IAC**；[Oudeyer, et al. 2007](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.177.7661&rep=rep1&type=pdf)）提出了一个想法，即使用前向动力学预测模型来估计学习进展并相应地分配内在探索奖励。

> *Intelligent Adaptive Curiosity* (**IAC**; [Oudeyer, et al. 2007](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.177.7661&rep=rep1&type=pdf)) sketched an idea of using a forward dynamics prediction model to estimate learning progress and assigned intrinsic exploration reward accordingly.

IAC依赖于一个存储机器人遇到的所有经验的记忆，$M=\{(s_t, a_t, s_{t+1})\}$以及一个前向动力学模型$f$。IAC根据转换样本，将状态空间（即在机器人学背景下的感觉运动空间，如论文中所讨论的）逐步分割成独立的区域，其过程类似于决策树的分割方式：当样本数量大于某个阈值时发生分割，并且每个叶子节点中状态的方差应最小。每个树节点都由其独有的样本集表征，并拥有自己的前向动力学预测器$f$，称为“专家”。

> IAC relies on a memory which stores all the experiences encountered by the robot, $M=\{(s_t, a_t, s_{t+1})\}$ and a forward dynamics model $f$. IAC incrementally splits the state space (i.e. sensorimotor space in the context of robotics, as discussed in the paper) into separate regions based on the transition samples, using a process similar to how a decision tree is split: The split happens when the number of samples is larger than a threshold, and the variance of states in each leaf should be minimal. Each tree node is characterized by its exclusive set of samples and has its own forward dynamics predictor $f$, named “expert”.

专家的预测误差$e_t$被推入与每个区域关联的列表中。然后，*学习进度*被测量为具有偏移量$\tau$的移动窗口的平均错误率与当前移动窗口之间的差异。内在奖励被定义为跟踪学习进度：$r^i_t = \frac{1}{k}\sum_{i=0}^{k-1}(e_{t-i-\tau} - e_{t-i})$，其中$k$是移动窗口大小。因此，我们能实现的预测错误率下降越大，我们分配给智能体的内在奖励就越高。换句话说，智能体被鼓励采取行动以快速了解环境。

> The prediction error $e_t$ of an expert is pushed into a list associated with each region. The *learning progress* is then measured as the difference between the mean error rate of a moving window with offset $\tau$ and the current moving window. The intrinsic reward is defined for tracking the learning progress: $r^i_t = \frac{1}{k}\sum_{i=0}^{k-1}(e_{t-i-\tau} - e_{t-i})$, where $k$ is the moving window size. So the larger prediction error rate decrease we can achieve, the higher intrinsic reward we would assign to the agent. In other words, the agent is encouraged to take actions to quickly learn about the environment.

![Architecture of the IAC (Intelligent Adaptive Curiosity) module: the intrinsic reward is assigned w.r.t the learning progress in reducing prediction error of the dynamics model. (Image source: Oudeyer, et al. 2007 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/IAC.png)

[Stadie 等人 (2015)](https://arxiv.org/abs/1507.00814) 在由$\phi$、$f_\phi: (\phi(s_t), a_t) \mapsto \phi(s_{t+1})$定义的编码空间中训练了一个前向动力学模型。模型在时间$T$的预测误差通过直到时间$t$的最大误差$\bar{e}_t = \frac{e_t}{\max_{i \leq t} e_i}$进行归一化，因此它始终在0到1之间。内在奖励相应地定义为：$r^i_t = (\frac{\bar{e}_t(s_t, a_t)}{t \cdot C})$，其中$C > 0$是一个衰减常数。

> [Stadie et al. (2015)](https://arxiv.org/abs/1507.00814) trained a forward dynamics model in the encoding space defined by $\phi$, $f_\phi: (\phi(s_t), a_t) \mapsto \phi(s_{t+1})$. The model’s prediction error at time $T$ is normalized by the maximum error up to time $t$, $\bar{e}_t = \frac{e_t}{\max_{i \leq t} e_i}$, so it is always between 0 and 1. The intrinsic reward is defined accordingly: $r^i_t = (\frac{\bar{e}_t(s_t, a_t)}{t \cdot C})$, where $C > 0$ is a decay constant.

通过$\phi(.)$编码状态空间是必要的，因为论文中的实验表明，直接在原始像素上训练的动力学模型表现出*非常差的*行为——为所有状态分配相同的探索奖励。在[Stadie 等人 (2015)](https://arxiv.org/abs/1507.00814)中，编码函数$\phi$通过自编码器（AE）学习，而$\phi(.)$是AE的输出层之一。AE可以使用随机智能体收集的一组图像进行静态训练，或者与策略一起动态训练，其中早期帧是使用[\epsilon-贪婪](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#classic-exploration-strategies)探索收集的。

> Encoding the state space via $\phi(.)$ is necessary, as experiments in the paper have shown that a dynamics model trained directly on raw pixels has *very poor* behavior — assigning same exploration bonuses to all the states. In [Stadie et al. (2015)](https://arxiv.org/abs/1507.00814), the encoding function $\phi$ is learned via an autocoder (AE) and $\phi(.)$ is one of the output layers in AE. The AE can be statically trained using a set of images collected by a random agent, or dynamically trained together with the policy where the early frames are gathered using [\epsilon-greedy](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#classic-exploration-strategies) exploration.

与自编码器不同，*内在好奇心模块*（**ICM**；[Pathak 等人，2017](https://arxiv.org/abs/1705.05363)）通过自监督的**逆动力学**模型学习状态空间编码$\phi(.)$。预测给定智能体自身行动的下一个状态并不容易，特别是考虑到环境中有些因素无法由智能体控制或不影响智能体。ICM认为一个好的状态特征空间应该排除这些因素，因为*它们无法影响智能体的行为，因此智能体没有学习它们的动机*。通过学习逆动力学模型$g: (\phi(s_t), \phi(s_{t+1})) \mapsto a_t$，特征空间只捕捉环境中与我们智能体行动相关的变化，而忽略其余部分。

英文原文：Instead of autoencoder, *Intrinsic Curiosity Module* (ICM; [Pathak, et al., 2017](https://arxiv.org/abs/1705.05363)) learns the state space encoding 

$\phi(.)$ with a self-supervised inverse dynamics model. Predicting the next state given the agent’s own action is not easy, especially considering that some factors in the environment cannot be controlled by the agent or do not affect the agent. ICM believes that a good state feature space should exclude such factors because *they cannot influence the agent’s behavior and thus the agent has no incentive for learning them*. By learning an inverse dynamics model 

$g: (\phi(s_t), \phi(s_{t+1})) \mapsto a_t$, the feature space only captures those changes in the environment related to the actions of our agent, and ignores the rest.

给定一个前向模型$f$、一个逆动力学模型$g$和一个观测$(s_t, a_t, s_{t+1})$：

> Given a forward model $f$, an inverse dynamics model $g$ and an observation $(s_t, a_t, s_{t+1})$:

$$
g_{\psi_I}(\phi(s_t), \phi(s_{t+1})) = \hat{a}_t \quad
f_{\psi_F}(\phi(s_t), a_t) = \hat{\phi}(s_{t+1}) \quad
r_t^i = \| \hat{\phi}(s_{t+1}) - \phi(s_{t+1}) \|_2^2
$$

这样的$\phi(.)$预计对环境中不可控的方面具有鲁棒性。

> Such $\phi(.)$ is expected to be robust to uncontrollable aspects of the environment.

![ICM (Intrinsic Curiosity Module) assigns the forward dynamics prediction error to the agent as the intrinsic reward. This dynamics model operates in a state encoding space learned through an inverse dynamics model to exclude environmental factors that do not affect the agent's behavior. (Image source: Pathak, et al. 2017 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/ICM.png)

[Burda、Edwards 和 Pathak 等人 (2018)](https://arxiv.org/abs/1808.04355) 对纯粹由好奇心驱动的学习进行了一系列大规模比较实验，这意味着只向智能体提供内在奖励。在这项研究中，奖励是$r_t = r^i_t = | f(s_t, a_t) - \phi(s_{t+1})|_2^2$。$\phi$的良好选择对于学习前向动力学至关重要，它应是*紧凑的*、*充分的*和*稳定的*，从而使预测任务更易处理并过滤掉不相关的观测。

> [Burda, Edwards & Pathak, et al. (2018)](https://arxiv.org/abs/1808.04355) did a set of large-scale comparison experiments on purely curiosity-driven learning, meaning that only intrinsic rewards are provided to the agent. In this study, the reward is $r_t = r^i_t = | f(s_t, a_t) - \phi(s_{t+1})|_2^2$. A good choice of $\phi$ is crucial to learning forward dynamics, which is expected to be *compact*, *sufficient* and *stable*, making the prediction task more tractable and filtering out irrelevant observation.

比较4种编码函数：

> In comparison of 4 encoding functions:

1\. 原始图像像素：无编码，$\phi(x) = x$。

2\. 随机特征（RF）：每个状态都通过一个固定的随机神经网络进行压缩。

3\. [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/#vae-variational-autoencoder)：概率编码器用于编码，$\phi(x) = q(z \vert x)$。

4\. 逆动力学特征（IDF）：与[ICM](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#ICM)中使用的特征空间相同。

英文原文：

1\. Raw image pixels: No encoding, $\phi(x) = x$.

2\. Random features (RF): Each state is compressed through a fixed random neural network.

3\. [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/#vae-variational-autoencoder): The probabilistic encoder is used for encoding, $\phi(x) = q(z \vert x)$.

4\. Inverse dynamic features (IDF): The same feature space as used in [ICM](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#ICM).

所有实验的奖励信号都通过累积回报标准差的运行估计进行归一化。所有实验都在无限时间范围设置中运行，以避免“完成”标志泄露信息。

> All the experiments have the reward signals normalized by a running estimation of standard deviation of the cumulative returns. And all the experiments are running in an infinite horizon setting to avoid “done” flag leaking information.

![The mean reward in different games when training with only curiosity signals, generated by different state encoding functions. (Image source: Burda, Edwards & Pathak, et al. 2018 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/large-scale-curiosity-learning.png)

有趣的是，*随机特征*表现出相当的竞争力，但在特征迁移实验中（即在《超级马里奥兄弟》1-1关卡中训练智能体，然后在另一个关卡中测试），学习到的IDF特征可以更好地泛化。

> Interestingly *random features* turn out to be quite competitive, but in feature transfer experiments (i.e. train an agent in Super Mario Bros level 1-1 and then test it in another level), learned IDF features can generalize better.

他们还在一个开启了[嘈杂电视](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#the-noisy-tv-problem)的环境中比较了RF和IDF。不出所料，嘈杂的电视大大减缓了学习速度，并且外部奖励随时间推移显著降低。

> They also compared RF and IDF in an environment with a [noisy TV](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#the-noisy-tv-problem) on. Unsurprisingly the noisy TV drastically slows down the learning and extrinsic rewards are much lower in time.

![Experiments using RF and IDF feature encoding in an environment with noisy TV on or off. The plot tracks extrinsic reward per episode as the training progresses. (Image source: Burda, Edwards & Pathak, et al. 2018 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/noisy-TV-experiment.png)

前向动力学优化也可以通过变分推断建模。**VIME**（*“变分信息最大化探索”*的缩写；[Houthooft, et al. 2017](https://arxiv.org/abs/1605.09674)）是一种基于最大化智能体对环境动力学信念的*信息增益*的探索策略。关于前向动力学获得了多少额外信息可以通过熵的减少来衡量。

> The forward dynamics optimization can be modeled via variational inference as well. **VIME** (short for *“Variational information maximizing exploration”*; [Houthooft, et al. 2017](https://arxiv.org/abs/1605.09674)) is an exploration strategy based on maximization of *information gain* about the agent’s belief of environment dynamics. How much additional information has been obtained about the forward dynamics can be measured as the reduction in entropy.

令$\mathcal{P}$为环境转移函数，$p(s_{t+1}\vert s_t, a_t; \theta)$为前向预测模型，由$\theta \in \Theta$参数化，$\xi_t = \{s_1, a_1, \dots, s_t\}$为轨迹历史。我们希望在采取新动作并观察到下一个状态后减少熵，即最大化以下表达式：

> Let $\mathcal{P}$ be the environment transition function, $p(s_{t+1}\vert s_t, a_t; \theta)$ be the forward prediction model, parameterized by $\theta \in \Theta$, and $\xi_t = \{s_1, a_1, \dots, s_t\}$ be the trajectory history. We would like to reduce the entropy after taking a new action and observing the next state, which is to maximize the following:

$$
\begin{aligned}
&\sum_t H(\Theta \vert \xi_t, a_t) - H(\Theta \vert S_{t+1}, \xi_t, a_t) \\
=& I(\Theta; S_{t+1} \vert \xi_t, a_t) \quad \scriptstyle{\text{; because } I(X; Y) = I(X) - I(X \vert Y)} \\
=& \mathbb{E}_{s_{t+1} \sim \mathcal{P}(.\vert\xi_t,a_t)} [D_\text{KL}(p(\theta \vert \xi_t, a_t, s_{t+1}) \| p(\theta \vert \xi_t, a_t))] \quad \scriptstyle{\text{; because } I(X; Y) = \mathbb{E}_Y [D_\text{KL} (p_{X \vert Y} \| p_X)]} \\
=& \mathbb{E}_{s_{t+1} \sim \mathcal{P}(.\vert\xi_t,a_t)} [D_\text{KL}(p(\theta \vert \xi_t, a_t, s_{t+1}) \| p(\theta \vert \xi_t))] \quad \scriptstyle{\text{; because } \theta \text{ does not depend on } a_t}
\end{aligned}
$$

在对新的可能状态取期望时，智能体预期会采取新动作以增加其对预测模型的新信念与旧信念之间的KL散度（*“信息增益”*）。该项可以作为内在奖励添加到奖励函数中：$r^i_t = D_\text{KL} [p(\theta \vert \xi_t, a_t, s_{t+1}) | p(\theta \vert \xi_t))]$。

> While taking expectation over the new possible states, the agent is expected to take a new action to increase the KL divergence (*“information gain”*) between its new belief over the prediction model to the old one. This term can be added into the reward function as an intrinsic reward: $r^i_t = D_\text{KL} [p(\theta \vert \xi_t, a_t, s_{t+1}) | p(\theta \vert \xi_t))]$.

然而，计算后验$p(\theta \vert \xi_t, a_t, s_{t+1})$通常是难以处理的。

> However, computing the posterior $p(\theta \vert \xi_t, a_t, s_{t+1})$ is generally intractable.

$$
\begin{aligned}
p(\theta \vert \xi_t, a_t, s_{t+1}) 
&= \frac{p(\theta \vert \xi_t, a_t) p(s_{t+1} \vert \xi_t, a_t; \theta)}{p(s_{t+1}\vert\xi_t, a_t)} \\
&= \frac{p(\theta \vert \xi_t) p(s_{t+1} \vert \xi_t, a_t; \theta)}{p(s_{t+1}\vert\xi_t, a_t)} & \scriptstyle{\text{; because action doesn't affect the belief.}} \\
&= \frac{\color{red}{p(\theta \vert \xi_t)} p(s_{t+1} \vert \xi_t, a_t; \theta)}{\int_\Theta p(s_{t+1}\vert\xi_t, a_t; \theta) \color{red}{p(\theta \vert \xi_t)} d\theta} & \scriptstyle{\text{; red part is hard to compute directly.}}
\end{aligned}
$$

由于直接计算$p(\theta\vert\xi_t)$很困难，一个自然的选择是使用替代分布$q_\phi(\theta)$来近似它。根据变分下界，我们知道最大化$q_\phi(\theta)$等价于最大化$p(\xi_t\vert\theta)$和最小化$D_\text{KL}[q_\phi(\theta) | p(\theta)]$。

> Since it is difficult to compute $p(\theta\vert\xi_t)$ directly, a natural choice is to approximate it with an alternative distribution $q_\phi(\theta)$. With variational lower bound, we know the maximization of $q_\phi(\theta)$ is equivalent to maximizing $p(\xi_t\vert\theta)$ and minimizing $D_\text{KL}[q_\phi(\theta) | p(\theta)]$.

使用近似分布$q$，内在奖励变为：

> Using the approximation distribution $q$, the intrinsic reward becomes:

$$
r^i_t = D_\text{KL} [q_{\phi_{t+1}}(\theta) \| q_{\phi_t}(\theta))]
$$

其中$\phi_{t+1}$表示$q$在看到$a_t$和$s_{t+1}$后与新信念相关的参数。当用作探索奖励时，它通过除以该KL散度值的移动中位数进行归一化。

> where $\phi_{t+1}$ represents $q$’s parameters associated with the new relief after seeing $a_t$ and $s_{t+1}$. When used as an exploration bonus, it is normalized by division by the moving median of this KL divergence value.

这里，动力学模型被参数化为[贝叶斯神经网络](https://link.springer.com/book/10.1007/978-1-4612-0745-0)（BNN），因为它保持对其权重的分布。BNN权重分布$q_\phi(\theta)$被建模为具有$\phi = \{\mu, \sigma\}$的完全*因子化*高斯分布，我们可以轻松采样$\theta \sim q_\phi(.)$。在应用二阶泰勒展开后，KL项$D_\text{KL}[q_{\phi + \lambda \Delta\phi}(\theta) | q_{\phi}(\theta)]$可以使用[费雪信息矩阵](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#estimation-using-fisher-information-matrix)$\mathbf{F}_\phi$进行估计，这很容易计算，因为$q_\phi$是因子化高斯分布，因此协方差矩阵只是一个对角矩阵。更多细节请参见[该论文](https://arxiv.org/abs/1605.09674)，特别是2.3-2.5节。

> Here the dynamics model is parameterized as a [Bayesian neural network](https://link.springer.com/book/10.1007/978-1-4612-0745-0) (BNN), as it maintains a distribution over its weights. The BNN weight distribution $q_\phi(\theta)$ is modeled as a fully *factorized* Gaussian with $\phi = \{\mu, \sigma\}$ and we can easily sample $\theta \sim q_\phi(.)$. After applying a second-order Taylor expansion, the KL term $D_\text{KL}[q_{\phi + \lambda \Delta\phi}(\theta) | q_{\phi}(\theta)]$ can be estimated using [Fisher Information Matrix](https://lilianweng.github.io/posts/2019-09-05-evolution-strategies/#estimation-using-fisher-information-matrix) $\mathbf{F}_\phi$, which is easy to compute, because $q_\phi$ is factorized Gaussian and thus the covariance matrix is only a diagonal matrix. See more details in [the paper](https://arxiv.org/abs/1605.09674), especially section 2.3-2.5.

上述所有方法都依赖于单个预测模型。如果我们有多个这样的模型，我们可以利用模型之间的分歧来设置探索奖励（[Pathak, et al. 2019](https://arxiv.org/abs/1906.04161)）。高度分歧表明预测置信度低，因此需要更多的探索。[Pathak, et al. (2019)](https://arxiv.org/abs/1906.04161)提出训练一组前向动力学模型，并使用模型输出集成上的方差作为$r_t^i$。具体来说，他们使用[随机特征](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#random-feature)编码状态空间，并在集成中学习了5个模型。

> All the methods above depend on a single prediction model. If we have multiple such models, we could use the disagreement among models to set the exploration bonus ([Pathak, et al. 2019](https://arxiv.org/abs/1906.04161)). High disagreement indicates low confidence in prediction and thus requires more exploration. [Pathak, et al. (2019)](https://arxiv.org/abs/1906.04161) proposed to train a set of forward dynamics models and to use the variance over the ensemble of model outputs as $r_t^i$. Precisely, they encode the state space with [random feature](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#random-feature) and learn 5 models in the  ensemble.

![Illustration of training architecture for self-supervised exploration via disagreement. (Image source: Pathak, et al. 2019 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/exploration-via-disagreement.png)

因为$r^i_t$是可微分的，模型中的内在奖励可以通过梯度下降直接优化，从而指导策略智能体改变动作。这种可微分的探索方法非常高效，但受限于探索范围较短。

> Because $r^i_t$ is differentiable, the intrinsic reward in the model could be directly optimized through gradient descent so as to inform the policy agent to change actions. This differentiable exploration approach is very efficient but limited by having a short exploration horizon.

##### 随机网络

> Random Networks

但是，如果预测任务根本与环境动力学无关呢？事实证明，当预测是针对随机任务时，它仍然可以帮助探索。

> But, what if the prediction task is not about the environment dynamics at all? It turns out when the prediction is for a random task, it still can help exploration.

**DORA**（全称*“Directed Outreaching Reinforcement Action-Selection”*；[Fox & Choshen, et al. 2018](https://arxiv.org/abs/1804.04012)）是一个新颖的框架，它基于一个新引入的**任务无关**的MDP注入探索信号。DORA的理念依赖于两个并行的MDP：

> **DORA** (short for *“Directed Outreaching Reinforcement Action-Selection”*; [Fox & Choshen, et al. 2018](https://arxiv.org/abs/1804.04012)) is a novel framework that injects exploration signals based on a newly introduced, **task-independent** MDP. The idea of DORA depends on two parallel MDPs:

- 一个是原始任务MDP；
- 另一个是相同的MDP，但*没有附加奖励*：相反，每个状态-动作对都被设计为具有值0。为第二个MDP学习到的Q值称为*E值*。如果模型不能完美地预测E值为零，则它仍然缺少信息。

> • One is the original task MDP;
> • The other is an identical MDP but with *no reward attached*: Rather, every state-action pair is designed to have value 0. The Q-value learned for the second MDP is called *E-value*. If the model cannot perfectly predict E-value to be zero, it is still missing information.

最初，E值被赋值为1。这种正向初始化可以鼓励定向探索，以实现更好的E值预测。具有高E值估计的状态-动作对尚未收集到足够的信息，至少不足以排除其高E值。在某种程度上，E值的对数可以被视为*访问计数器*的泛化。

> Initially E-value is assigned with value 1. Such positive initialization can encourage directed exploration for better E-value prediction. State-action pairs with high E-value estimation don’t have enough information gathered yet, at least not enough to exclude their high E-values. To some extent, the logarithm of E-values can be considered as a generalization of *visit counters*.

当使用神经网络对E值进行函数逼近时，会添加另一个值头来预测E值，并且它被简单地期望预测为零。给定一个预测的E值$E(s_t, a_t)$，探索奖励是$r^i_t = \frac{1}{\sqrt{-\log E(s_t, a_t)}}$。

> When using a neural network to do function approximation for E-value, another value head is added to predict E-value and it is simply expected to predict zero. Given a predicted E-value $E(s_t, a_t)$, the exploration bonus is $r^i_t = \frac{1}{\sqrt{-\log E(s_t, a_t)}}$.

与DORA类似，**随机网络蒸馏**（**RND**；[Burda, et al. 2018](https://arxiv.org/abs/1810.12894)）引入了一个*独立于主任务*的预测任务。RND探索奖励被定义为神经网络$\hat{f}(s_t)$预测由*固定随机初始化*的神经网络$f(s_t)$给出的观测特征的误差。其动机是，给定一个新状态，如果过去已经多次访问过类似状态，则预测应该更容易，从而误差更低。探索奖励是$r^i(s_t) = |\hat{f}(s_t; \theta) - f(s_t) |_2^2$。

英文原文：Similar to DORA, Random Network Distillation (RND; [Burda, et al. 2018](https://arxiv.org/abs/1810.12894)) introduces a prediction task *independent of the main task*. The RND exploration bonus is defined as the error of a neural network 

$\hat{f}(s_t)$ predicting features of the observations given by a *fixed randomly initialized* neural network 

$f(s_t)$. The motivation is that given a new state, if similar states have been visited many times in the past, the prediction should be easier and thus has lower error. The exploration bonus is 

$r^i(s_t) = |\hat{f}(s_t; \theta) - f(s_t) |_2^2$.

![How RND (Random Network Distillation) works for providing an intrinsic reward. The features $O_{i+1} \mapsto f_{i+1}$ are generated by a fixed random neural network. (Image source: OpenAI Blog: "Reinforcement Learning with Prediction-Based Rewards" )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/RND.png)

在RND实验中，有两个重要因素：

> Two factors are important in RND experiments:

1. 非回合制设置会带来更好的探索，尤其是在不使用任何外部奖励时。这意味着回报不会在“游戏结束”时被截断，并且内在回报可以跨多个回合传播。
2. 归一化很重要，因为给定一个随机神经网络作为预测目标，奖励的尺度很难调整。内在奖励通过除以内在回报标准差的运行估计值进行归一化。

> • Non-episodic setting results in better exploration, especially when not using any extrinsic rewards. It means that the return is not truncated at “Game over” and intrinsic return can spread across multiple episodes.
> • Normalization is important since the scale of the reward is tricky to adjust given a random neural network as a prediction target. The intrinsic reward is normalized by division by a running estimate of the standard deviations of the intrinsic return.

RND设置在解决困难探索问题方面表现良好。例如，最大化RND探索奖励始终能在《蒙特祖玛的复仇》中找到超过一半的房间。

> The RND setup works well for resolving the hard-exploration problem. For example, maximizing the RND exploration bonus consistently finds more than half of the rooms in Montezuma’s Revenge.

##### 物理特性

> Physical Properties

与模拟器中的游戏不同，一些强化学习应用，如机器人学，需要理解物理世界中的物体和直观推理。一些预测任务要求智能体与环境进行一系列交互并观察相应的后果，例如估计物理学中的一些隐藏属性（例如质量、摩擦力等）。

> Different from games in simulators, some RL applications like Robotics need to understand objects and intuitive reasoning in the physical world. Some prediction tasks require the agent to perform a sequence of interactions with the environment and to observe the corresponding consequences, such as estimating some hidden properties in physics (e.g. mass, friction, etc).

受这些想法的启发，[Denil, et al. (2017)](https://arxiv.org/abs/1611.01843)发现DRL智能体可以学习进行必要的探索以发现这些隐藏属性。具体来说，他们考虑了两个实验：

> Motivated by such ideas, [Denil, et al. (2017)](https://arxiv.org/abs/1611.01843) found that DRL agents can learn to perform necessary exploration to discover such hidden properties. Precisely they considered two experiments:

1. *“哪个更重？”* — 智能体必须与方块互动并推断哪个更重。
2. *“塔”* — 智能体需要通过将其推倒来推断一个塔由多少个刚体组成。

> • *“Which is heavier?”* — The agent has to interact with the blocks and infer which one is heavier.
> • *“Towers”* — The agent needs to infer how many rigid bodies a tower is composed of by knocking it down.

实验中的智能体首先经历一个探索阶段，与环境互动并收集信息。一旦探索阶段结束，智能体被要求输出一个*标记*动作来回答问题。如果答案正确，则给智能体分配一个正奖励；否则分配一个负奖励。因为答案需要与场景中的物品进行大量互动，所以智能体必须学会有效地进行操作，以便弄清楚物理原理和正确答案。探索自然而然地发生。

> The agent in the experiments first goes through an exploration phase to interact with the environment and to collect information. Once the exploration phase ends, the agent is asked to output a *labeling* action to answer the question. Then a positive reward is assigned to the agent if the answer is correct; otherwise a negative one is assigned. Because the answer requires a decent amount of interactions with items in the scene, the agent has to learn to efficiently play around so as to figure out the physics and the correct answer. The exploration naturally happens.

在他们的实验中，智能体能够在两个任务中学习，性能因任务难度而异。尽管该论文没有使用物理预测任务来提供内在奖励，并结合与另一个学习任务相关的外部奖励，而是专注于探索任务本身。我确实喜欢通过预测环境中隐藏的物理属性来鼓励复杂的探索行为的想法。

> In their experiments, the agent is able to learn in both tasks with performance varied by the difficulty of the task. Although the paper didn’t use the physics prediction task to provide intrinsic reward bonus along with extrinsic reward associated with another learning task, rather it focused on the exploration tasks themselves. I do enjoy the idea of encouraging sophisticated exploration behavior by predicting hidden physics properties in the environment.

### 基于记忆的探索

> Memory-based Exploration

基于奖励的探索存在几个缺点：

> Reward-based exploration suffers from several drawbacks:

- 函数逼近跟不上。
- 探索奖励是非平稳的。
- 知识衰退，意味着状态不再新颖，无法及时提供内在奖励信号。

> • Function approximation is slow to catch up.
> • Exploration bonus is non-stationary.
> • Knowledge fading, meaning that states cease to be novel and cannot provide intrinsic reward signals in time.

本节中的方法依赖于外部记忆来解决基于奖励奖金的探索的缺点。

> Methods in this section rely on external memory to resolve disadvantages of reward bonus-based exploration.

#### 情景记忆

> Episodic Memory

如上所述，[RND](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#RND) 更适合在非情景设置中运行，这意味着预测知识是在多个情景中积累的。探索策略 **Never Give Up**（**NGU**；[Badia, et al. 2020a](https://arxiv.org/abs/2002.06038)）将一个可以在一个情景内快速适应的情景新颖性模块与 RND 结合起来，作为终身新颖性模块。

> As mentioned above, [RND](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#RND) is better running in an non-episodic setting, meaning the prediction knowledge is accumulated across multiple episodes. The exploration strategy, **Never Give Up** (**NGU**; [Badia, et al. 2020a](https://arxiv.org/abs/2002.06038)), combines an episodic novelty module that can rapidly adapt within one episode with RND as a lifelong novelty module.

具体来说，NGU 中的内在奖励由来自两个模块的两个探索奖金组成，分别用于 *一个情景内* 和 *跨多个情景*。

> Precisely, the intrinsic reward in NGU consists of two exploration bonuses from two modules,  *within one episode* and *across multiple episodes*, respectively.

短期每情景奖励由一个 *情景新颖性模块* 提供。它包含一个情景记忆 $M$，一个动态大小的基于槽的记忆，以及一个 IDF（逆动力学特征）嵌入函数 $\phi$，与 [ICM](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#ICM) 中的特征编码相同。

> The short-term per-episode reward is provided by an *episodic novelty module*. It contains an episodic memory $M$, a dynamically-sized slot-based memory, and an IDF (inverse dynamics features) embedding function $\phi$, same as the feature encoding in [ICM](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#ICM)

1\. 在每一步中，当前状态嵌入$\phi(s_t)$被添加到$M$中。

2\. 内部奖励是通过比较当前观测与以下内容之间的相似程度来确定的$M$。差异越大，奖励越大。其中$K(x, y)$是一个用于测量两个样本之间距离的核函数。$N_k$是一组$k$最近邻，位于$M$中，根据$K(., .)$。$c$是一个使分母非零的小常数。在论文中，$K(x, y)$被配置为逆核函数：其中$d(.,.)$是两个样本之间的欧几里得距离，$d_m$是第k个最近邻的平方欧几里得距离的移动平均值，以提高鲁棒性。$\epsilon$是一个小的常数。

英文原文：

1\. 
At every step the current state embedding $\phi(s_t)$ is added into $M$.


2\. 
The intrinsic bonus is determined by comparing how similar the current observation is to the content of $M$. A larger difference results in a larger bonus.

where $K(x, y)$ is a kernel function for measuring the distance between two samples. $N_k$ is a set of $k$ nearest neighbors in $M$ according to $K(., .)$.  $c$ is a small constant to keep the denominator non-zero. In the paper, $K(x, y)$ is configured to be the inverse kernel:

where $d(.,.)$ is Euclidean distance between two samples and $d_m$ is a running average of the squared Euclidean distance of the k-th nearest neighbors for better robustness. $\epsilon$ is a small constant.


$$
r^\text{episodic}_t \approx \frac{1}{\sqrt{\sum_{\phi_i \in N_k} K(\phi(x_t), \phi_i)} + c}
$$

$$
K(x, y) = \frac{\epsilon}{\frac{d^2(x, y)}{d^2_m} + \epsilon}
$$

![The architecture of NGU's embedding function (left) and reward generator (right). (Image source: Badia, et al. 2020a )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/NGU.png)

长期跨 эпизод 的新颖性依赖于 *终身新颖性模块* 中的 RND 预测误差。探索奖励是 $\alpha_t = 1 + \frac{e^\text{RND}(s_t) - \mu_e}{\sigma_e}$，其中 $\mu_e$ 和 $\sigma_e$ 是 RND 误差的运行平均值和标准差 $e^\text{RND}(s_t)$。

> The long-term across-episode novelty relies on RND prediction error in *life-long novelty module*. The exploration bonus is $\alpha_t = 1 + \frac{e^\text{RND}(s_t) - \mu_e}{\sigma_e}$ where $\mu_e$ and $\sigma_e$ are running mean and std dev for RND error $e^\text{RND}(s_t)$.

> 然而，在[RND论文](https://arxiv.org/abs/1810.12894)的结论部分，我注意到了以下声明：
>
> “我们发现，RND探索奖励足以应对局部探索，即探索短期决策的后果，例如是否与特定对象交互，或避免它。然而，涉及长期协调决策的全局探索超出了我们方法的能力范围。”
>
> 这让我有点困惑，RND如何能作为一个好的终身新颖性奖励提供者。如果你知道原因，请在下方留言。

> However in the conclusion section of the [RND paper](https://arxiv.org/abs/1810.12894), I noticed the following statement:
>
> “We find that the RND exploration bonus is sufficient to deal with local exploration, i.e. exploring the consequences of short-term decisions, like whether to interact with a particular object, or avoid it. However global exploration that involves coordinated decisions over long time horizons is beyond the reach of our method. "
>
> And this confuses me a bit how RND can be used as a good life-long novelty bonus provider. If you know why, feel free to leave a comment below.

最终的组合内在奖励是$r^i_t = r^\text{episodic}_t \cdot \text{clip}(\alpha_t, 1, L)$，其中$L$是一个常数最大奖励标量。

> The final combined intrinsic reward is $r^i_t = r^\text{episodic}_t \cdot \text{clip}(\alpha_t, 1, L)$, where $L$ is a constant maximum reward scalar.

NGU 的设计使其具有两个优良特性：

> The design of NGU enables it to have two nice properties:

1. *迅速阻止*在同一回合*内*重复访问同一状态；
2. *缓慢阻止*重复访问在多个回合*中*已被多次访问的状态。

> • *Rapidly discourages* revisiting the same state *within* the same episode;
> • *Slowly discourages* revisiting states that have been visited many times *across* episodes.

后来，DeepMind 在 NGU 的基础上提出了“Agent57”（[Badia, et al. 2020b](https://arxiv.org/abs/2003.13350)），这是第一个在*所有* 57 款 Atari 游戏中都超越标准人类基准的深度强化学习智能体。Agent57 相较于 NGU 的两大改进是：

> Later, built on top of NGU, DeepMind proposed “Agent57” ([Badia, et al. 2020b](https://arxiv.org/abs/2003.13350)), the first deep RL agent that outperforms the standard human benchmark on *all* 57 Atari games. Two major improvements in Agent57 over NGU are:

1\. Agent57 中训练了*一组*策略，每个策略都配备了不同的探索参数对$\{(\beta_j, \gamma_j)\}_{j=1}^N$。回想一下，给定$\beta_j$，奖励被构建为$r_{j,t} = r_t^e + \beta_j r^i_t$，而$\gamma_j$是奖励折扣因子。自然可以预期，具有较高$\beta_j$和较低$\gamma_j$的策略在训练早期会取得更大进展，而随着训练的进行，情况则会相反。一个元控制器（[滑动窗口 UCB 强盗算法](https://arxiv.org/pdf/0805.3415.pdf)）被训练来选择哪些策略应该被优先考虑。

2\. 第二个改进是 Q 值函数的一种新参数化，它以与捆绑奖励类似的形式分解了内在奖励和外在奖励的贡献：$Q(s, a; \theta_j) = Q(s, a; \theta_j^e) + \beta_j Q(s, a; \theta_j^i)$。在训练期间，$Q(s, a; \theta_j^e)$和$Q(s, a; \theta_j^i)$分别使用奖励$r_j^e$和$r_j^i$进行单独优化。

英文原文：

1\. A *population* of policies are trained in Agent57, each equipped with a different exploration parameter pair $\{(\beta_j, \gamma_j)\}_{j=1}^N$. Recall that given $\beta_j$, the reward is constructed as $r_{j,t} = r_t^e + \beta_j r^i_t$ and $\gamma_j$ is the reward discounting factor. It is natural to expect policies with higher $\beta_j$ and lower $\gamma_j$ to make more progress early in training, while the opposite would be expected as training progresses. A meta-controller ([sliding-window UCB bandit algorithm](https://arxiv.org/pdf/0805.3415.pdf)) is trained to select which policies should be prioritized.

2\. The second improvement is a new parameterization of Q-value function that decomposes the contributions of the intrinsic and extrinsic rewards in a similar form as the bundled reward: $Q(s, a; \theta_j) = Q(s, a; \theta_j^e) + \beta_j Q(s, a; \theta_j^i)$. During training, $Q(s, a; \theta_j^e)$ and $Q(s, a; \theta_j^i)$ are optimized separately with rewards $r_j^e$ and $r_j^i$, respectively.

![A pretty cool illustration of techniques developed in time since DQN in 2015, eventually leading to Agent57. (Image source: DeepMind Blog: "Agent57: Outperforming the human Atari benchmark" )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/agent57.png)

Savinov 等人（[2019](https://arxiv.org/abs/1810.02274)）没有使用欧几里得距离来衡量情景记忆中状态的接近程度，而是考虑了状态之间的转换，并提出了一种方法来衡量从记忆中其他状态访问一个状态所需的步数，该方法被称为**情景好奇心（EC）**模块。新颖性奖励取决于状态之间的可达性。

> Instead of using the Euclidean distance to measure closeness of states in episodic memory, [Savinov, et al. (2019)](https://arxiv.org/abs/1810.02274) took the transition between states into consideration and proposed a method to measure the number of steps needed to visit one state from other states in memory, named **Episodic Curiosity (EC)** module. The novelty bonus depends on reachability between states.

1\. 在每个回合开始时，智能体以一个空的情景记忆$M$开始。

2\. 在每一步，智能体将当前状态与记忆中保存的状态进行比较，以确定新颖性奖励：如果当前状态是新颖的（即，从记忆中的观测值到达该状态所需的步数超过阈值），智能体将获得奖励。

3\. 如果新颖性奖励足够高，当前状态将被添加到情景记忆中。（想象一下，如果所有状态都被添加到记忆中，任何新状态都可以在 1 步内被添加。）

4\. 重复 1-3 步，直到本回合结束。

英文原文：

1\. At the beginning of each episode, the agent starts with an empty episodic memory $M$.

2\. At every step, the agent compares the current state with saved states in memory to determine novelty bonus: If the current state is novel (i.e., takes more steps to reach from observations in memory than a threshold), the agent gets a bonus.

3\. The current state is added into the episodic memory if the novelty bonus is high enough. (Imagine that if all the states were added into memory, any new state could be added within 1 step.)

4\. Repeat 1-3 until the end of this episode.

![The nodes in the graph are states, the edges are possible transitions. The blue nodes are states in memory. The green nodes are reachable from the memory within $k = 2$ steps (not novel). The orange nodes are further away, so they are considered as novel states. (Image source: Savinov, et al. 2019 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/transition-graph.png)

为了估计状态之间的可达性，我们需要访问转换图，但不幸的是，转换图并非完全已知。因此，[Savinov 等人 (2019)](https://arxiv.org/abs/1810.02274) 训练了一个 [孪生](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#convolutional-siamese-neural-network) 神经网络来预测两个状态之间相隔多少步。它包含一个嵌入网络 $\phi: \mathcal{S} \mapsto \mathbb{R}^n$，用于首先将状态编码为特征向量，然后是一个比较器网络 $C: \mathbb{R}^n \times \mathbb{R}^n \mapsto [0, 1]$，用于输出一个二进制标签，指示两个状态在转换图中是否足够接近（即在 $k$ 步内可达），$C(\phi(s_i), \phi(s_j)) \mapsto [0, 1]$。

> In order to estimate reachability between states, we need to access the transition graph, which is unfortunately not entirely known. Thus, [Savinov, et al. (2019)](https://arxiv.org/abs/1810.02274) trained a [siamese](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#convolutional-siamese-neural-network) neural network to predict how many steps separate two states. It contains one embedding network $\phi: \mathcal{S} \mapsto \mathbb{R}^n$ to first encode the states to feature vectors and then one comparator network $C: \mathbb{R}^n \times \mathbb{R}^n \mapsto [0, 1]$ to output a binary label on whether two states are close enough (i.e., reachable within $k$ steps) in the transition graph, $C(\phi(s_i), \phi(s_j)) \mapsto [0, 1]$.

一个情景记忆缓冲区 $M$ 存储同一情景中一些过去观测的嵌入。新的观测将通过 $C$ 与现有状态嵌入进行比较，结果会被聚合（例如最大值、90% 百分位数）以提供可达性分数 $C^M(\phi(s_t))$。探索奖励是 $r^i_t = \big(C’ - C^M(f(s_t))\big)$，其中 $C’$ 是一个预定义的阈值，用于确定奖励的符号（例如 $C’=0.5$ 对于固定持续时间的情景效果很好）。当新状态不容易从记忆缓冲区中的状态到达时，会获得高额奖励。

> An episodic memory buffer $M$ stores embeddings of some past observations within the same episode. A new observation will be compared with existing state embeddings via $C$ and the results are aggregated (e.g. max, 90th percentile) to provide a reachability score $C^M(\phi(s_t))$. The exploration bonus is $r^i_t = \big(C’ - C^M(f(s_t))\big)$, where $C’$ is a predefined threshold for determining the sign of the reward (e.g. $C’=0.5$ works well for fixed-duration episodes). High bonus is awarded to new states when they are not easily reachable from states in the memory buffer.

他们声称 EC 模块可以克服 [嘈杂电视](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#the-noisy-tv-problem) 问题。

> They claimed that the EC module can overcome the [noisy-TV](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#the-noisy-tv-problem) problem.

![The architecture of episodic curiosity (EC) module for intrinsic reward generation.  (Image source: Savinov, et al. 2019 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/episodic-memory-overview.png)

#### 直接探索

> Direct Exploration

**Go-Explore** ([Ecoffet 等人，2019](https://arxiv.org/abs/1901.10995)) 是一种旨在解决“困难探索”问题的算法。它由以下两个阶段组成。

> **Go-Explore** ([Ecoffet, et al., 2019](https://arxiv.org/abs/1901.10995)) is an algorithm aiming to solve the “hard-exploration” problem. It is composed of the following two phases.

**阶段 1（“探索直到解决”）** 感觉很像 [Dijkstra 算法](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) 用于在图中寻找最短路径。事实上，阶段 1 不涉及神经网络。通过维护一个有趣状态的记忆以及通向它们的轨迹，智能体可以返回（假设模拟器是 *确定性的*）到有希望的状态，并从那里继续进行 *随机* 探索。状态被映射成一个简短的离散代码（命名为“单元格”）以便记忆。如果出现新状态或找到更好/更短的轨迹，记忆就会更新。在选择返回哪个过去状态时，智能体可能会在记忆中均匀选择一个，或者根据启发式方法（如新近度、访问次数、记忆中邻居的数量等）进行选择。这个过程会重复进行，直到任务解决并找到至少一条解决方案轨迹。

> **Phase 1 (“Explore until solved”)** feels quite like [Dijkstra’s algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) for finding shortest paths in a graph. Indeed, no neural network is involved in phase 1. By maintaining a memory of interesting states as well as trajectories leading to them, the agent can go back (given a simulator is *deterministic*) to promising states and continue doing *random* exploration from there. The state is mapped into a short discretized code (named “cell”) in order to be memorized. The memory is updated if a new state appears or a better/shorter trajectory is found. When selecting which past states to return to, the agent might select one in the memory uniformly or according to heuristics like recency, visit count, count of neighbors in the memory, etc. This process is repeated until the task is solved and at least one solution trajectory is found.

上述找到的高性能轨迹在具有任何随机性的评估环境中都无法很好地工作。因此，需要 **阶段 2（“鲁棒化”）** 通过模仿学习来使解决方案鲁棒化。他们采用了 [逆向算法](https://arxiv.org/abs/1812.03381)，其中智能体从轨迹中的最后一个状态附近开始，然后从那里运行强化学习优化。

> The above found high-performance trajectories would not work well on evaluation envs with any stochasticity. Thus, **Phase 2 (“Robustification”)** is needed to robustify the solution via imitation learning. They adopted [Backward Algorithm](https://arxiv.org/abs/1812.03381), in which the agent is started near the last state in the trajectory and then runs RL optimization from there.

阶段 1 中一个重要的注意事项是：为了在没有探索的情况下确定性地返回到某个状态，Go-Explore 依赖于一个可重置且确定性的模拟器，这是一个很大的缺点。

> One important note in phase 1 is: In order to go back to a state deterministically without exploration, Go-Explore depends on a resettable and deterministic simulator, which is a big disadvantage.

为了使该算法更普遍地适用于具有随机性的环境，后来提出了 Go-Explore 的增强版本 ([Ecoffet 等人，2020](https://arxiv.org/abs/2004.12919))，命名为 **基于策略的 Go-Explore**。

> To make the algorithm more generally useful to environments with stochasticity, an enhanced version of Go-Explore ([Ecoffet, et al., 2020](https://arxiv.org/abs/2004.12919)), named **policy-based Go-Explore** was proposed later.

- 基于策略的Go-Explore不是毫不费力地重置模拟器状态，而是学习一个*目标条件策略*，并利用该策略重复访问内存中已知的状态。目标条件策略被训练来遵循之前导致内存中选定状态的最佳轨迹。他们引入了**自模仿学习**（**SIL**；[Oh, et al. 2018](https://arxiv.org/abs/1806.05635)）损失，以帮助从成功的轨迹中提取尽可能多的信息。
- 此外，他们发现当智能体返回有希望的状态以继续探索时，从策略中采样比随机行动效果更好。
- 基于策略的Go-Explore的另一个改进是使图像到单元格的降尺度函数可调。它经过优化，以确保内存中的单元格既不会太多也不会太少。

> • Instead of resetting the simulator state effortlessly, the policy-based Go-Explore learns a *goal-conditioned policy* and uses that to access a known state in memory repeatedly. The goal-conditioned policy is trained to follow the best trajectory that previously led to the selected states in memory. They include a **Self-Imitation Learning** (**SIL**; [Oh, et al. 2018](https://arxiv.org/abs/1806.05635)) loss to help extract as much information as possible from successful trajectories.
> • Also, they found sampling from policy works better than random actions when the agent returns to promising states to continue exploration.
> • Another improvement in policy-based Go-Explore is to make the downscaling function of images to cells adjustable. It is optimized so that there would be neither too many nor too few cells in the memory.

![An overview of the Go-Explore algorithm. (Image source: Ecoffet, et al., 2020 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/policy-based-Go-Explore.png)

在原始Go-Explore之后，[Yijie Guo, et al. (2019)](https://arxiv.org/abs/1907.10247)提出了**DTSIL**（多样轨迹条件自模仿学习），它与上述基于策略的Go-Explore有相似的想法。DTSIL维护一个在训练期间收集的多样化演示的内存，并使用它们通过[SIL](https://arxiv.org/abs/1806.05635)训练一个轨迹条件策略。他们在采样时优先选择以稀有状态结束的轨迹。

> After vanilla Go-Explore, [Yijie Guo, et al. (2019)](https://arxiv.org/abs/1907.10247) proposed **DTSIL** (Diverse Trajectory-conditioned Self-Imitation Learning), which shared a similar idea as policy-based Go-Explore above. DTSIL maintains a memory of diverse demonstrations collected during training and uses them to train a trajectory-conditioned policy via [SIL](https://arxiv.org/abs/1806.05635). They prioritize trajectories that end with a rare state during sampling.

![Algorithm of DTSIL (Diverse Trajectory-conditioned Self-Imitation Learning). (Image source: Yijie Guo, et al. 2019 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/DTSIL-algo.png)

类似的方法也出现在[Guo, et al. (2019)](https://arxiv.org/abs/1906.07805)中。主要思想是将具有*高不确定性*的目标存储在内存中，以便之后智能体可以利用目标条件策略重复访问这些目标状态。在每个回合中，智能体抛掷一枚硬币（概率0.5）来决定是根据策略贪婪地行动，还是通过从内存中采样目标进行定向探索。

> The similar approach is also seen in [Guo, et al. (2019)](https://arxiv.org/abs/1906.07805). The main idea is to store goals with *high uncertainty* in memory so that later the agent can revisit these goal states with a goal-conditioned policy repeatedly. In each episode, the agent flips a coin (probability 0.5) to decide whether it will act greedily w.r.t. the policy or do directed exploration by sampling goals from the memory.

![Different components in directed exploration with function approximation. (Image source: Guo, et al. 2019 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/directed-exploration.png)

状态的不确定性度量可以是简单的，如基于计数的奖励，也可以是复杂的，如密度或贝叶斯模型。该论文训练了一个前向动力学模型，并将其预测误差作为不确定性度量。

> The uncertainty measure of a state can be something simple like count-based bonuses or something complex like density or bayesian models. The paper trained a forward dynamics model and took its prediction error as the uncertainty metric.

### Q值探索

> Q-Value Exploration

受[Thompson 采样](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#thompson-sampling)启发，**自举 DQN**（[Osband 等人，2016](https://arxiv.org/abs/1602.04621)）通过在经典[DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network)中引入了 Q 值近似的不确定性概念，方法是使用[自举](https://en.wikipedia.org/wiki/Bootstrapping_(statistics))方法。自举法是通过从同一总体中多次有放回地抽样，然后汇总结果来近似分布。

> Inspired by [Thompson sampling](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#thompson-sampling), **Bootstrapped DQN** ([Osband, et al. 2016](https://arxiv.org/abs/1602.04621)) introduces a notion of uncertainty in Q-value approximation in classic [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network) by using the [bootstrapping](https://en.wikipedia.org/wiki/Bootstrapping_(statistics)) method. Bootstrapping is to approximate a distribution by sampling with replacement from the same population multiple times and then aggregate the results.

多个 Q 值头并行训练，但每个头只使用一个自举子采样数据集，并且每个头都有自己对应的目标网络。所有 Q 值头共享同一个主干网络。

> Multiple Q-value heads are trained in parallel but each only consumes a bootstrapped sub-sampled set of data and each has its own corresponding target network. All the Q-value heads share the same backbone network.

![The algorithm of Bootstrapped DQN. (Image source: Osband, et al. 2016 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/bootstrapped-DQN-algo.png)

在一个回合开始时，一个 Q 值头被均匀采样，并负责在该回合中收集经验数据。然后从掩码分布 $m \sim \mathcal{M}$ 中采样一个二值掩码，并决定哪些头可以使用这些数据进行训练。掩码分布 $\mathcal{M}$ 的选择决定了自举样本的生成方式；例如，

> At the beginning of one episode, one Q-value head is sampled uniformly and acts for collecting experience data in this episode. Then a binary mask is sampled from the masking distribution $m \sim \mathcal{M}$ and decides which heads can use this data for training. The choice of masking distribution $\mathcal{M}$ determines how bootstrapped samples are generated; For example,

• 如果 $\mathcal{M}$ 是一个独立的伯努利分布，其参数为 $p=0.5$，则这对应于双倍或零引导法。

• 如果 $\mathcal{M}$ 总是返回一个全一掩码，则该算法就简化为一种集成方法。

英文原文：

• If $\mathcal{M}$ is an independent Bernoulli distribution with $p=0.5$, this corresponds to the double-or-nothing bootstrap.

• If $\mathcal{M}$ always returns an all-one mask, the algorithm reduces to an ensemble method.

然而，这种探索仍然受到限制，因为引导法引入的不确定性完全依赖于训练数据。最好注入一些独立于数据的先验信息。这种“噪声”先验有望在奖励稀疏时驱动智能体持续探索。将随机先验添加到引导式DQN中以实现更好探索的算法（[Osband, et al. 2018](https://arxiv.org/abs/1806.03335)）依赖于贝叶斯线性回归。贝叶斯回归的核心思想是：我们可以 *“通过在数据的噪声版本上进行训练，并结合一些随机正则化来生成后验样本”*。

> However, this kind of exploration is still restricted, because uncertainty introduced by bootstrapping fully relies on the training data. It is better to inject some prior information independent of the data. This “noisy” prior is expected to drive the agent to keep exploring when the reward is sparse. The algorithm of adding random prior into bootstrapped DQN for better exploration ([Osband, et al. 2018](https://arxiv.org/abs/1806.03335)) depends on Bayesian linear regression. The core idea of Bayesian regression is: We can *“generate posterior samples by training on noisy versions of the data, together with some random regularization”*.

设 $\theta$ 为 Q 函数参数，$\theta^-$ 为目标 Q，使用随机先验函数 $p$ 的损失函数为：

> Let $\theta$ be the Q function parameter and $\theta^-$ for the target Q, the loss function using a randomized prior function $p$ is:

$$
\mathcal{L}(\theta, \theta^{-}, p, \mathcal{D}; \gamma) = \sum_{t\in\mathcal{D}}\Big( r_t + \gamma \max_{a'\in\mathcal{A}} (\underbrace{Q_{\theta^-} + p)}_\text{target Q}(s'_t, a') - \underbrace{(Q_\theta + p)}_\text{Q to optimize}(s_t, a_t) \Big)^2
$$

### 变分选项

> Varitional Options

选项是带有终止条件的策略。搜索空间中存在大量选项，它们独立于智能体的意图。通过在建模中明确包含内在选项，智能体可以获得用于探索的内在奖励。

> Options are policies with termination conditions. There are a large set of options available in the search space and they are independent of an agent’s intentions. By explicitly including intrinsic options into modeling, the agent can obtain intrinsic rewards for exploration.

**VIC**（“*“Variational Intrinsic Control”*；[Gregor, et al. 2017](https://arxiv.org/abs/1611.07507)）是一种框架，用于通过建模选项和学习以选项为条件的策略，为智能体提供内在探索奖励。令`\Omega`表示一个选项，该选项从`s_0`开始，到`s_f`结束。一个环境概率分布$p^J(s_f \vert s_0, \Omega)$定义了一个选项`\Omega`在给定起始状态`s_0`时终止的位置。一个可控性分布$p^C(\Omega \vert s_0)$定义了我们可以从中采样的选项的概率分布。根据定义，我们有$p(s_f, \Omega \vert s_0) = p^J(s_f \vert s_0, \Omega) p^C(\Omega \vert s_0)$。

英文原文：VIC (short for *“Variational Intrinsic Control”*; [Gregor, et al. 2017](https://arxiv.org/abs/1611.07507)) is such a framework for providing the agent with intrinsic exploration bonuses based on modeling options and learning policies conditioned on options. Let `\Omega` represent an option which starts from `s_0` and ends at `s_f`. An environment probability distribution 

$p^J(s_f \vert s_0, \Omega)$ defines where an option `\Omega` terminates given a starting state `s_0`. A controllability distribution 

$p^C(\Omega \vert s_0)$ defines the probability distribution of options we can sample from. And by definition we have 

$p(s_f, \Omega \vert s_0) = p^J(s_f \vert s_0, \Omega) p^C(\Omega \vert s_0)$.

在选择选项时，我们希望实现两个目标：

> While choosing options, we would like to achieve two goals:

• 从 $s_0$ 实现一组多样化的最终状态 ⇨ $H(s_f \vert s_0)$ 的最大化。

• 准确知道给定选项$\Omega$可以以哪个状态结束 ⇨ $H(s_f \vert s_0, \Omega)$的最小化。

英文原文：

• Achieve a diverse set of the final states from $s_0$ ⇨ Maximization of $H(s_f \vert s_0)$.

• Know precisely which state a given option $\Omega$ can end with ⇨ Minimization of $H(s_f \vert s_0, \Omega)$.

将它们结合起来，我们得到要最大化的互信息$I(\Omega; s_f \vert s_0)$：

> Combining them, we get mutual information $I(\Omega; s_f \vert s_0)$ to maximize:

$$
\begin{aligned}
I(\Omega; s_f \vert s_0)
&= H(s_f \vert s_0) - H(s_f \vert s_0, \Omega) \\
&= - \sum_{s_f} p(s_f \vert s_0) \log p(s_f \vert s_0) + \sum_{s_f, \Omega} p(s_f, \Omega \vert s_0) \log \frac{p(s_f, \Omega \vert s_0)}{p^C(\Omega \vert s_0)} \\
&= - \sum_{s_f} p(s_f \vert s_0) \log p(s_f \vert s_0) + \sum_{s_f, \Omega} p^J(s_f \vert s_0, \Omega) p^C(\Omega \vert s_0) \log p^J(s_f \vert s_0, \Omega) \\
\end{aligned}
$$

因为互信息是对称的，我们可以在多个地方切换$s_f$和$\Omega$而不会破坏等价性。又因为$p(\Omega \vert s_0, s_f)$难以观测，我们用近似分布$q$来代替它。根据变分下界，我们将得到$I(\Omega; s_f \vert s_0) \geq I^{VB}(\Omega; s_f \vert s_0)$。

> Because mutual information is symmetric, we can switch $s_f$ and $\Omega$ in several places without breaking the equivalence. Also because $p(\Omega \vert s_0, s_f)$ is difficult to observe, let us replace it with an approximation distribution $q$. According to the variational lower bound, we would have $I(\Omega; s_f \vert s_0) \geq I^{VB}(\Omega; s_f \vert s_0)$.

$$
\begin{aligned}
I(\Omega; s_f \vert s_0)
&= I(s_f; \Omega \vert s_0) \\
&= - \sum_{\Omega} p(\Omega \vert s_0) \log p(\Omega \vert s_0) + \sum_{s_f, \Omega} p^J(s_f \vert s_0, \Omega) p^C(\Omega \vert s_0) \log \color{red}{p(\Omega \vert s_0, s_f)}\\
I^{VB}(\Omega; s_f \vert s_0)
&= - \sum_{\Omega} p(\Omega \vert s_0) \log p(\Omega \vert s_0) + \sum_{s_f, \Omega} p^J(s_f \vert s_0, \Omega) p^C(\Omega \vert s_0) \log \color{red}{q(\Omega \vert s_0, s_f)} \\
I(\Omega; s_f \vert s_0) &\geq I^{VB}(\Omega; s_f \vert s_0)
\end{aligned}
$$

![The algorithm for VIC (Variational Intrinsic Control). (Image source: Gregor, et al. 2017 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/VIC-explicit-options.png)

这里$\pi(a \vert \Omega, s)$可以用任何RL算法进行优化。选项推断函数$q(\Omega \vert s_0, s_f)$正在进行监督学习。先验$p^C$被更新，使其倾向于选择具有更高奖励的$\Omega$。请注意，$p^C$也可以是固定的（例如高斯分布）。各种$\Omega$将通过学习产生不同的行为。此外，[Gregor, et al. (2017)](https://arxiv.org/abs/1611.07507)观察到，在实践中，使用函数逼近使具有显式选项的VIC工作很困难，因此他们也提出了另一个具有隐式选项的VIC版本。

> Here $\pi(a \vert \Omega, s)$ can be optimized with any RL algorithm. The option inference function $q(\Omega \vert s_0, s_f)$ is doing supervised learning. The prior $p^C$ is updated so that it tends to choose $\Omega$ with higher rewards. Note that $p^C$ can also be fixed (e.g. a Gaussian). Various $\Omega$ will result in different behavior through learning. Additionally, [Gregor, et al. (2017)](https://arxiv.org/abs/1611.07507) observed that it is difficult to make VIC with explicit options work in practice with function approximation and therefore they also proposed another version of VIC with implicit options.

与VIC不同，VIC仅根据起始和结束状态对`\Omega`进行建模，而**VALOR**（*“Variational Auto-encoding Learning of Options by Reinforcement”*的缩写；[Achiam, et al. 2018](https://arxiv.org/abs/1807.10299)）则依赖于整个轨迹来提取选项上下文`c`，该上下文从固定的高斯分布中采样。在VALOR中：

英文原文：Different from VIC which models `\Omega` conditioned only on the start and end states, VALOR (short for *“Variational Auto-encoding Learning of Options by Reinforcement”*; [Achiam, et al. 2018](https://arxiv.org/abs/1807.10299)) relies on the whole trajectory to extract the option context `c`, which is sampled from a fixed Gaussian distribution. In VALOR:

- 一个策略充当编码器，将来自噪声分布的上下文转换为轨迹
- 一个解码器试图从轨迹中恢复上下文，并奖励那些使上下文更容易区分的策略。解码器在训练期间从不看到动作，因此智能体必须以一种有利于与解码器通信的方式与环境交互，以实现更好的预测。此外，解码器循环地接收一个轨迹中的一系列步骤，以更好地建模时间步之间的相关性。

> • A policy acts as an encoder, translating contexts from a noise distribution into trajectories
> • A decoder attempts to recover the contexts from the trajectories, and rewards the policies for making contexts easier to distinguish. The decoder never sees the actions during training, so the agent has to interact with the environment in a way that facilitates communication with the decoder for better prediction. Also, the decoder recurrently takes in a sequence of steps in one trajectory to better model the correlation between timesteps.

![The decoder of VALOR is a biLSTM which takes $N = 11$ equally spaced observations from one trajectory as inputs. (Image source: Achiam, et al. 2018 )](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/VALOR-decoder.png)

DIAYN（“Diversity is all you need”；[Eysenbach, et al. 2018](https://arxiv.org/abs/1802.06070)）的思想方向相同，尽管名称不同——DIAYN根据潜在的*技能*变量对策略进行建模。更多详情请参阅我的[上一篇文章](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#learning-with-random-rewards)。

> DIAYN (“Diversity is all you need”; [Eysenbach, et al. 2018](https://arxiv.org/abs/1802.06070)) has the idea lying in the same direction, although with a different name — DIAYN models the policies conditioned on a latent *skill* variable. See my [previous post](https://lilianweng.github.io/posts/2019-06-23-meta-rl/#learning-with-random-rewards) for more details.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2020年6月). 深度强化学习中的探索策略. Lil’Log. https://lilianweng.github.io/posts/2020-06-07-exploration-drl/.

> Weng, Lilian. (Jun 2020). Exploration strategies in deep reinforcement learning. Lil’Log. https://lilianweng.github.io/posts/2020-06-07-exploration-drl/.

或者

> Or

```
@article{weng2020exploration,
  title   = "Exploration Strategies in Deep Reinforcement Learning",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2020",
  month   = "Jun",
  url     = "https://lilianweng.github.io/posts/2020-06-07-exploration-drl/"
}
```

### 参考文献

> Reference

[1] Pierre-Yves Oudeyer & Frederic Kaplan. [“我们如何定义内在动机？”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.567.6524&rep=rep1&type=pdf) 2008年表观遗传机器人会议.

> [1] Pierre-Yves Oudeyer & Frederic Kaplan. [“How can we define intrinsic motivation?”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.567.6524&rep=rep1&type=pdf) Conf. on Epigenetic Robotics, 2008.

[2] Marc G. Bellemare, et al. [“统一基于计数的探索和内在动机”](https://arxiv.org/abs/1606.01868). NIPS 2016.

> [2] Marc G. Bellemare, et al. [“Unifying Count-Based Exploration and Intrinsic Motivation”](https://arxiv.org/abs/1606.01868). NIPS 2016.

[3] Georg Ostrovski, et al. [“使用神经密度模型的基于计数的探索”](https://arxiv.org/abs/1703.01310). PMLR 2017.

> [3] Georg Ostrovski, et al. [“Count-Based Exploration with Neural Density Models”](https://arxiv.org/abs/1703.01310). PMLR 2017.

[4] Rui Zhao & Volker Tresp. [“通过密度估计的好奇心驱动经验优先级”](https://arxiv.org/abs/1902.08039). NIPS 2018.

> [4] Rui Zhao & Volker Tresp. [“Curiosity-Driven Experience Prioritization via
> Density Estimation”](https://arxiv.org/abs/1902.08039). NIPS 2018.

[5] Haoran Tang, et al. ["#探索：深度强化学习中基于计数的探索研究”](https://arxiv.org/abs/1611.04717). NIPS 2017.

> [5] Haoran Tang, et al. ["#Exploration: A Study of Count-Based Exploration for Deep Reinforcement Learning”](https://arxiv.org/abs/1611.04717). NIPS 2017.

[6] Jürgen Schmidhuber. [“在模型构建神经控制器中实现好奇心和厌倦的可能性”](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.45.957) 1991.

> [6] Jürgen Schmidhuber. [“A possibility for implementing curiosity and boredom in model-building neural controllers”](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.45.957) 1991.

[7] Pierre-Yves Oudeyer, et al. [“自主心智发展的内在动机系统”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.177.7661&rep=rep1&type=pdf) IEEE Transactions on Evolutionary Computation, 2007.

> [7] Pierre-Yves Oudeyer, et al. [“Intrinsic Motivation Systems for Autonomous Mental Development”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.177.7661&rep=rep1&type=pdf) IEEE Transactions on Evolutionary Computation, 2007.

[8] Bradly C. Stadie, et al. [“使用深度预测模型激励强化学习中的探索”](https://arxiv.org/abs/1507.00814). ICLR 2016.

> [8] Bradly C. Stadie, et al. [“Incentivizing Exploration In Reinforcement Learning With Deep Predictive Models”](https://arxiv.org/abs/1507.00814). ICLR 2016.

[9] Deepak Pathak, et al. [“通过自监督预测进行好奇心驱动的探索”](https://arxiv.org/abs/1705.05363). CVPR 2017.

> [9] Deepak Pathak, et al. [“Curiosity-driven Exploration by Self-supervised Prediction”](https://arxiv.org/abs/1705.05363). CVPR 2017.

[10] Yuri Burda, Harri Edwards & Deepak Pathak, et al. [“好奇心驱动学习的大规模研究”](https://arxiv.org/abs/1808.04355). arXiv 1808.04355 (2018).

> [10] Yuri Burda, Harri Edwards & Deepak Pathak, et al. [“Large-Scale Study of Curiosity-Driven Learning”](https://arxiv.org/abs/1808.04355). arXiv 1808.04355 (2018).

[11] Joshua Achiam & Shankar Sastry. [“基于惊喜的深度强化学习内在动机”](https://arxiv.org/abs/1703.01732) NIPS 2016 深度强化学习研讨会.

> [11] Joshua Achiam & Shankar Sastry. [“Surprise-Based Intrinsic Motivation for Deep Reinforcement Learning”](https://arxiv.org/abs/1703.01732) NIPS 2016 Deep RL Workshop.

[12] Rein Houthooft, et al. [“VIME: 变分信息最大化探索”](https://arxiv.org/abs/1605.09674). NIPS 2016.

> [12] Rein Houthooft, et al. [“VIME: Variational information maximizing exploration”](https://arxiv.org/abs/1605.09674). NIPS 2016.

[13] Leshem Choshen, Lior Fox & Yonatan Loewenstein. [“DORA 探索者：定向外展强化动作选择”](https://arxiv.org/abs/1804.04012). ICLR 2018

> [13] Leshem Choshen, Lior Fox & Yonatan Loewenstein. [“DORA the explorer: Directed outreaching reinforcement action-selection”](https://arxiv.org/abs/1804.04012). ICLR 2018

[14] Yuri Burda, et al. [“通过随机网络蒸馏进行探索”](https://arxiv.org/abs/1810.12894) ICLR 2019.

> [14] Yuri Burda, et al. [“Exploration by Random Network Distillation”](https://arxiv.org/abs/1810.12894) ICLR 2019.

[15] OpenAI 博客: [“基于预测奖励的强化学习”](https://openai.com/blog/reinforcement-learning-with-prediction-based-rewards/) 2018年10月.

> [15] OpenAI Blog: [“Reinforcement Learning with
> Prediction-Based Rewards”](https://openai.com/blog/reinforcement-learning-with-prediction-based-rewards/) Oct, 2018.

[16] Misha Denil, et al. [“通过深度强化学习进行物理实验”](https://arxiv.org/abs/1611.01843). ICLR 2017.

> [16] Misha Denil, et al. [“Learning to Perform Physics Experiments via Deep Reinforcement Learning”](https://arxiv.org/abs/1611.01843). ICLR 2017.

[17] Ian Osband, et al. [“通过自举DQN进行深度探索”](https://arxiv.org/abs/1602.04621). NIPS 2016.

> [17] Ian Osband, et al. [“Deep Exploration via Bootstrapped DQN”](https://arxiv.org/abs/1602.04621). NIPS 2016.

[18] Ian Osband, John Aslanides & Albin Cassirer. [“深度强化学习的随机先验函数”](https://arxiv.org/abs/1806.03335). NIPS 2018.

> [18] Ian Osband, John Aslanides & Albin Cassirer. [“Randomized Prior Functions for Deep Reinforcement Learning”](https://arxiv.org/abs/1806.03335). NIPS 2018.

[19] Karol Gregor, Danilo Jimenez Rezende & Daan Wierstra. [“变分内在控制”](https://arxiv.org/abs/1611.07507). ICLR 2017.

> [19] Karol Gregor, Danilo Jimenez Rezende & Daan Wierstra. [“Variational Intrinsic Control”](https://arxiv.org/abs/1611.07507). ICLR 2017.

[20] Joshua Achiam, et al. [“变分选项发现算法”](https://arxiv.org/abs/1807.10299). arXiv 1807.10299 (2018).

> [20] Joshua Achiam, et al. [“Variational Option Discovery Algorithms”](https://arxiv.org/abs/1807.10299). arXiv 1807.10299 (2018).

[21] Benjamin Eysenbach, et al. [“多样性是你所需要的一切：在没有奖励函数的情况下学习技能。”](https://arxiv.org/abs/1802.06070). ICLR 2019.

> [21] Benjamin Eysenbach, et al. [“Diversity is all you need: Learning skills without a reward function.”](https://arxiv.org/abs/1802.06070). ICLR 2019.

[22] Adrià Puigdomènech Badia, et al. [“永不放弃 (NGU)：学习定向探索策略”](https://arxiv.org/abs/2002.06038) ICLR 2020.

> [22] Adrià Puigdomènech Badia, et al. [“Never Give Up (NGU): Learning Directed Exploration Strategies”](https://arxiv.org/abs/2002.06038) ICLR 2020.

[23] Adrià Puigdomènech Badia, et al.  [“Agent57：超越雅达利人类基准”](https://arxiv.org/abs/2003.13350). arXiv 2003.13350 (2020).

> [23] Adrià Puigdomènech Badia, et al.  [“Agent57: Outperforming the Atari Human Benchmark”](https://arxiv.org/abs/2003.13350). arXiv 2003.13350 (2020).

[24] DeepMind 博客: [“Agent57：超越人类雅达利基准”](https://deepmind.com/blog/article/Agent57-Outperforming-the-human-Atari-benchmark) 2020年3月.

> [24] DeepMind Blog: [“Agent57: Outperforming the human Atari benchmark”](https://deepmind.com/blog/article/Agent57-Outperforming-the-human-Atari-benchmark) Mar 2020.

[25] Nikolay Savinov, et al. [“通过可达性实现的情景好奇心”](https://arxiv.org/abs/1810.02274) ICLR 2019.

> [25] Nikolay Savinov, et al. [“Episodic Curiosity through Reachability”](https://arxiv.org/abs/1810.02274) ICLR 2019.

[26] Adrien Ecoffet, et al. [“Go-Explore：解决硬探索问题的新方法”](https://arxiv.org/abs/1901.10995). arXiv 1901.10995 (2019).

> [26] Adrien Ecoffet, et al. [“Go-Explore: a New Approach for Hard-Exploration Problems”](https://arxiv.org/abs/1901.10995). arXiv 1901.10995 (2019).

[27] Adrien Ecoffet, et al. [“先返回再探索”](https://arxiv.org/abs/2004.12919). arXiv 2004.12919 (2020).

> [27] Adrien Ecoffet, et al. [“First return then explore”](https://arxiv.org/abs/2004.12919). arXiv 2004.12919 (2020).

[28] Junhyuk Oh, et al. [“自模仿学习”](https://arxiv.org/abs/1806.05635). ICML 2018.

> [28] Junhyuk Oh, et al. [“Self-Imitation Learning”](https://arxiv.org/abs/1806.05635). ICML 2018.

[29] Yijie Guo, et al. [“通过轨迹条件策略进行硬探索任务的自模仿学习”](https://arxiv.org/abs/1907.10247). arXiv 1907.10247 (2019).

> [29] Yijie Guo, et al. [“Self-Imitation Learning via Trajectory-Conditioned Policy for Hard-Exploration Tasks”](https://arxiv.org/abs/1907.10247). arXiv 1907.10247 (2019).

[30] Zhaohan Daniel Guo & Emma Brunskill. [“强化学习的定向探索”](https://arxiv.org/abs/1906.07805). arXiv 1906.07805 (2019).

> [30] Zhaohan Daniel Guo & Emma Brunskill. [“Directed Exploration for Reinforcement Learning”](https://arxiv.org/abs/1906.07805). arXiv 1906.07805 (2019).

[31] Deepak Pathak, et al. [“通过分歧进行自监督探索。”](https://arxiv.org/abs/1906.04161) ICML 2019.

> [31] Deepak Pathak, et al. [“Self-Supervised Exploration via Disagreement.”](https://arxiv.org/abs/1906.04161) ICML 2019.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Exploration-exploitation dilemma | 利用与探索困境 | 在强化学习中，智能体需要在利用已知最优行动和探索未知行动之间做出权衡。 |
| Deep Reinforcement Learning (DRL) | 深度强化学习 | 结合深度学习和强化学习，使智能体能够从高维输入中学习复杂策略。 |
| Hard Exploration Problem | 硬探索问题 | 指在奖励稀疏或具有欺骗性的环境中，智能体难以发现有效奖励信号的问题。 |
| Intrinsic Reward | 内在奖励 | 一种额外的奖励信号，用于鼓励智能体探索环境，通常与好奇心、新颖性或知识提升相关。 |
| Count-based Exploration | 基于计数的探索 | 一种内在奖励方法，根据状态被访问的次数来分配奖励，以鼓励访问新颖状态。 |
| Forward Dynamics Model | 前向动力学模型 | 预测智能体行动后果的模型，即从当前状态和行动预测下一个状态。 |
| Inverse Dynamics Model | 逆动力学模型 | 预测导致状态转换的行动的模型，即从当前状态和下一个状态预测行动。 |
| Intrinsic Curiosity Module (ICM) | 内在好奇心模块 | 通过自监督的逆动力学模型学习状态编码，并利用前向动力学预测误差作为内在奖励。 |
| Random Network Distillation (RND) | 随机网络蒸馏 | 一种探索方法，通过预测由固定随机初始化网络生成的观测特征的误差作为内在奖励。 |
| Episodic Memory | 情景记忆 | 一种外部记忆机制，用于存储智能体在单个情景中遇到的经验，以评估状态的新颖性。 |
| Go-Explore | Go-Explore算法 | 一种解决硬探索问题的算法，通过维护有趣状态的记忆和轨迹，并结合模仿学习。 |
| Bootstrapped DQN | 自举DQN | 一种Q值探索方法，通过自举方法引入Q值近似的不确定性，使用多个Q值头并行训练。 |
| Variational Intrinsic Control (VIC) | 变分内在控制 | 一种框架，通过建模选项和学习以选项为条件的策略，为智能体提供内在探索奖励。 |
