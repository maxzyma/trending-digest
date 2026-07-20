# 深入浅出强化学习（长篇）

> A (Long) Peek into Reinforcement Learning

> 来源：Lil'Log / Lilian Weng，2018-02-19
> 原文链接：https://lilianweng.github.io/posts/2018-02-19-rl-overview/
> 分类：人工智能 / 强化学习

## 核心要点

- 强化学习（RL）是人工智能领域的核心算法，旨在通过智能体与环境的交互，学习最优行为策略以最大化累积奖励。
- 强化学习问题通常被建模为马尔可夫决策过程（MDP），其关键概念包括智能体、环境、状态、动作、奖励、策略和价值函数。
- 贝尔曼方程是强化学习的理论基础，它将价值函数分解为即时奖励与折扣未来价值之和。
- 解决强化学习问题的方法主要包括动态规划（模型已知）、蒙特卡洛方法和时序差分学习（模型未知）。
- 时序差分（TD）学习是无模型且可从不完整片段中学习的核心方法，其代表算法有SARSA（同策略）和Q-learning（异策略）。
- 深度Q网络（DQN）通过经验回放和周期性更新目标网络，解决了Q-learning结合非线性函数近似和自举时的不稳定性问题。
- 策略梯度方法直接学习参数化策略以最大化预期回报，而Actor-Critic算法则结合了策略学习（Actor）和价值函数学习（Critic）。
- 演化策略（ES）是一种模型无关的优化方法，通过模仿自然选择来学习最优策略参数，具有高度并行性且无需值函数近似。
- 强化学习面临探索-利用困境和致命三元组问题，后者指异策略、非线性函数近似和自举结合时可能导致训练不稳定。
- AlphaGo Zero是强化学习的成功案例，它通过深度卷积神经网络、蒙特卡洛树搜索和自我对弈，在没有人类知识的情况下掌握了围棋。

## 正文

2020-09-03更新：更新了[SARSA](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#sarsa-on-policy-td-control)和[Q-learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control)算法，以使其区别更加明显。  
2021-09-19更新：感谢爱吃猫的鱼，我们有了这篇[中文](https://paperexplained.cn/articles/article/detail/33/)文章。

> [Updated on 2020-09-03: Updated the algorithm of [SARSA](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#sarsa-on-policy-td-control) and [Q-learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control) so that the difference is more pronounced.
>
>
> [Updated on 2021-09-19: Thanks to 爱吃猫的鱼, we have this post in [Chinese](https://paperexplained.cn/articles/article/detail/33/)].

近年来，人工智能（AI）领域发生了一些激动人心的消息。AlphaGo在围棋比赛中击败了最顶尖的人类职业选手。很快，其扩展算法AlphaGo Zero在没有人类知识监督学习的情况下，以100比0击败了AlphaGo。顶尖职业游戏玩家在DOTA2 1v1比赛中输给了OpenAI开发的机器人。了解这些之后，很难不对这些算法背后的魔力——强化学习（RL）——感到好奇。我写这篇文章是为了简要介绍这个领域。我们将首先介绍几个基本概念，然后深入探讨解决强化学习问题的经典方法。希望这篇文章能成为新手的良好起点，为未来对前沿研究的学习搭建桥梁。

> A couple of exciting news in Artificial Intelligence (AI) has just happened in recent years.  AlphaGo defeated the best professional human player in the game of Go. Very soon the extended algorithm AlphaGo Zero beat AlphaGo by 100-0 without supervised learning on human knowledge. Top professional game players lost to the bot developed by OpenAI on DOTA2 1v1 competition. After knowing these, it is pretty hard not to be curious about the magic behind these algorithms — Reinforcement Learning (RL). I’m writing this post to briefly go over the field. We will first introduce several fundamental concepts and then dive into classic approaches to solving RL problems. Hopefully, this post could be a good starting point for newbies, bridging the future study on the cutting-edge research.

### 什么是强化学习？

> What is Reinforcement Learning?

假设我们有一个智能体在一个未知环境中，这个智能体可以通过与环境交互获得一些奖励。智能体应该采取行动以最大化累积奖励。在现实中，这种情况可能是一个机器人玩游戏以获得高分，或者一个机器人试图用物理物品完成物理任务；并且不限于这些。

> Say, we have an agent in an unknown environment and this agent can obtain some rewards by interacting with the environment. The agent ought to take actions so as to maximize cumulative rewards. In reality, the scenario could be a bot playing a game to achieve high scores, or a robot trying to complete physical tasks with physical items; and not just limited to these.

![An agent interacts with the environment, trying to take smart actions to maximize cumulative rewards.](https://lilianweng.github.io/posts/2018-02-19-rl-overview/RL_illustration.png)

强化学习（RL）的目标是通过实验试错和收到的相对简单的反馈，为智能体学习一个好的策略。有了最优策略，智能体就能够主动适应环境以最大化未来的奖励。

> The goal of Reinforcement Learning (RL) is to learn a good strategy for the agent from experimental trials and relative simple feedback received. With the optimal strategy, the agent is capable to actively adapt to the environment to maximize future rewards.

#### 关键概念

> Key Concepts

现在我们来正式定义强化学习中的一组关键概念。

> Now Let’s formally define a set of key concepts in RL.

智能体在一个**环境**中行动。环境如何对某些行动做出反应由一个我们可能知道也可能不知道的**模型**定义。智能体可以处于环境的众多**状态**（$s \in \mathcal{S}$）之一，并选择采取众多**行动**（$a \in \mathcal{A}$）之一来从一个状态切换到另一个状态。智能体将到达哪个状态由状态之间的转移概率（`P`）决定。一旦采取行动，环境就会提供一个**奖励**（$r \in \mathcal{R}$）作为反馈。

英文原文：The agent is acting in an environment. How the environment reacts to certain actions is defined by a model which we may or may not know. The agent can stay in one of many states (

$s \in \mathcal{S}$) of the environment, and choose to take one of many actions (

$a \in \mathcal{A}$) to switch from one state to another. Which state the agent will arrive in is decided by transition probabilities between states (`P`). Once an action is taken, the environment delivers a reward (

$r \in \mathcal{R}$) as feedback.

模型定义了奖励函数和转移概率。我们可能知道也可能不知道模型如何工作，这区分了两种情况：

> The model defines the reward function and transition probabilities. We may or may not know how the model works and this differentiate two circumstances:

- **已知模型**：用完美信息进行规划；进行基于模型的强化学习。当我们完全了解环境时，可以通过[动态规划](https://en.wikipedia.org/wiki/Dynamic_programming)（DP）找到最优解。你还记得算法101课程中的“最长递增子序列”或“旅行商问题”吗？哈哈。但这并不是本文的重点。
- **未知模型**：用不完整信息进行学习；进行无模型强化学习，或者尝试将模型显式地作为算法的一部分进行学习。以下大部分内容都适用于模型未知的情况。

> • **Know the model**: planning with perfect information; do model-based RL. When we fully know the environment, we can find the optimal solution by [Dynamic Programming](https://en.wikipedia.org/wiki/Dynamic_programming) (DP). Do you still remember “longest increasing subsequence” or “traveling salesmen problem” from your Algorithms 101 class? LOL. This is not the focus of this post though.
> • **Does not know the model**: learning with incomplete information; do model-free RL or try to learn the model explicitly as part of the algorithm. Most of the following content serves the scenarios when the model is unknown.

智能体的**策略**$\pi(s)$提供了在特定状态下采取何种最优行动的指导方针，**目标是最大化总奖励**。每个状态都关联着一个**价值**函数$V(s)$，它预测了在该状态下通过执行相应策略我们能够获得的未来奖励的预期量。换句话说，价值函数量化了一个状态的好坏。策略和价值函数都是我们在强化学习中试图学习的内容。

英文原文：The agent’s policy 

$\pi(s)$ provides the guideline on what is the optimal action to take in a certain state with the goal to maximize the total rewards. Each state is associated with a value function 

$V(s)$ predicting the expected amount of future rewards we are able to receive in this state by acting the corresponding policy. In other words, the value function quantifies how good a state is. Both policy and value functions are what we try to learn in reinforcement learning.

![Summary of approaches in RL based on whether we want to model the value, policy, or the environment. (Image source: reproduced from David Silver's RL course lecture 1 .)](https://lilianweng.github.io/posts/2018-02-19-rl-overview/RL_algorithm_categorization.png)

智能体与环境之间的交互涉及一系列随时间推移的行动和观测到的奖励，$t=1, 2, \dots, T$。在此过程中，智能体积累了关于环境的知识，学习了最优策略，并决定下一步采取何种行动，以便高效地学习最佳策略。让我们将时间步 t 的状态、行动和奖励分别标记为`S_t`、`A_t`和`R_t`。因此，交互序列由一个**回合**（也称为“试验”或“轨迹”）完全描述，序列在终止状态`S_T`结束：

英文原文：The interaction between the agent and the environment involves a sequence of actions and observed rewards in time, 

$t=1, 2, \dots, T$. During the process, the agent accumulates the knowledge about the environment, learns the optimal policy, and makes decisions on which action to take next so as to efficiently learn the best policy. Let’s label the state, action, and reward at time step t as `S_t`, `A_t`, and `R_t`, respectively. Thus the interaction sequence is fully described by one episode (also known as “trial” or “trajectory”) and the sequence ends at the terminal state `S_T`:

$$
S_1, A_1, R_2, S_2, A_2, \dots, S_T
$$

深入研究不同类别的强化学习算法时，你会经常遇到以下术语：

> Terms you will encounter a lot when diving into different categories of RL algorithms:

- **基于模型（Model-based）**：依赖于环境模型；模型要么已知，要么算法明确地学习它。
- **无模型（Model-free）**：学习过程中不依赖于模型。
- **同策略（On-policy）**：使用目标策略的确定性结果或样本来训练算法。
- **异策略（Off-policy）**：使用由不同行为策略而非目标策略产生的转换或回合分布进行训练。

> • **Model-based**: Rely on the model of the environment; either the model is known or the algorithm learns it explicitly.
> • **Model-free**: No dependency on the model during learning.
> • **On-policy**: Use the deterministic outcomes or samples from the target policy to train the algorithm.
> • **Off-policy**: Training on a distribution of transitions or episodes produced by a different behavior policy rather than that produced by the target policy.

##### 模型：转换与奖励

> Model: Transition and Reward

模型是环境的描述符。有了模型，我们可以学习或推断环境将如何与智能体交互并提供反馈。模型主要包含两部分：转移概率函数$P$和奖励函数$R$。

> The model is a descriptor of the environment. With the model, we can learn or infer how the environment would interact with and provide feedback to the agent. The model has two major parts, transition probability function $P$ and reward function $R$.

假设我们处于状态 s，我们决定采取行动 a 以到达下一个状态 s’ 并获得奖励 r。这被称为一个**转换**步骤，由一个元组 (s, a, s’, r) 表示。

> Let’s say when we are in state s, we decide to take action a to arrive in the next state s’ and obtain reward r. This is known as one **transition** step, represented by a tuple (s, a, s’, r).

转移函数 P 记录了在采取行动 a 并获得奖励 r 后，从状态 s 转移到状态 s’ 的概率。我们使用$\mathbb{P}$作为“概率”的符号。

> The transition function P records the probability of transitioning from state s to s’ after taking action a while obtaining reward r. We use $\mathbb{P}$ as a symbol of “probability”.

$$
P(s', r \vert s, a)  = \mathbb{P} [S_{t+1} = s', R_{t+1} = r \vert S_t = s, A_t = a]
$$

因此，状态转移函数可以定义为$P(s’, r \vert s, a)$的函数：

> Thus the state-transition function can be defined as a function of $P(s’, r \vert s, a)$:

$$
P_{ss'}^a = P(s' \vert s, a)  = \mathbb{P} [S_{t+1} = s' \vert S_t = s, A_t = a] = \sum_{r \in \mathcal{R}} P(s', r \vert s, a)
$$

奖励函数 R 预测由一个行动触发的下一个奖励：

> The reward function R predicts the next reward triggered by one action:

$$
R(s, a) = \mathbb{E} [R_{t+1} \vert S_t = s, A_t = a] = \sum_{r\in\mathcal{R}} r \sum_{s' \in \mathcal{S}} P(s', r \vert s, a)
$$

##### 策略

> Policy

策略，作为智能体的行为函数 $\pi$，告诉我们在状态 s 中采取哪个动作。它是从状态 s 到动作 a 的映射，可以是确定性的或随机性的：

> Policy, as the agent’s behavior function $\pi$, tells us which action to take in state s. It is a mapping from state s to action a and can be either deterministic or stochastic:

• 确定性： $\pi(s) = a$。

• 随机性： $\pi(a \vert s) = \mathbb{P}_\pi [A=a \vert S=s]$。

英文原文：

• Deterministic: $\pi(s) = a$.

• Stochastic: $\pi(a \vert s) = \mathbb{P}_\pi [A=a \vert S=s]$.

##### 价值函数

> Value Function

价值函数通过预测未来奖励来衡量一个状态的好坏，或者一个状态或动作的奖励程度。未来奖励，也称为 **回报**，是未来折现奖励的总和。让我们计算从时间 t 开始的回报 `G_t`：

英文原文：Value function measures the goodness of a state or how rewarding a state or an action is by a prediction of future reward. The future reward, also known as return, is a total sum of discounted rewards going forward. Let’s compute the return `G_t` starting from time t:

$$
G_t = R_{t+1} + \gamma R_{t+2} + \dots = \sum_{k=0}^{\infty} \gamma^k R_{t+k+1}
$$

折现因子 $\gamma \in [0, 1]$ 会惩罚未来的奖励，因为：

> The discounting factor $\gamma \in [0, 1]$ penalize the rewards in the future, because:

- 未来的奖励可能具有更高的不确定性；例如，股票市场。
- 未来的奖励不提供即时利益；例如，作为人类，我们可能更喜欢今天玩乐而不是五年后 ;)。
- 折现提供了数学上的便利；即，我们不需要永远跟踪未来的步骤来计算回报。
- 我们不需要担心状态转移图中的无限循环。

> • The future rewards may have higher uncertainty; i.e. stock market.
> • The future rewards do not provide immediate benefits; i.e. As human beings, we might prefer to have fun today rather than 5 years later ;).
> • Discounting provides mathematical convenience; i.e., we don’t need to track future steps forever to compute return.
> • We don’t need to worry about the infinite loops in the state transition graph.

状态 s 的 **状态价值** 是指如果在时间 t 处于该状态时的预期回报，$S_t = s$：

英文原文：The state-value of a state s is the expected return if we are in this state at time t, 

$S_t = s$:

$$
V_{\pi}(s) = \mathbb{E}_{\pi}[G_t \vert S_t = s]
$$

类似地，我们将状态-动作对的 **动作价值**（“Q 值”；Q 我认为是“Quality”？）定义为：

> Similarly, we define the **action-value** (“Q-value”; Q as “Quality” I believe?) of a state-action pair as:

$$
Q_{\pi}(s, a) = \mathbb{E}_{\pi}[G_t \vert S_t = s, A_t = a]
$$

此外，由于我们遵循目标策略 $\pi$，我们可以利用可能动作的概率分布和 Q 值来恢复状态价值：

> Additionally, since we follow the target policy $\pi$, we can make use of the probility distribution over possible actions and the Q-values to recover the state-value:

$$
V_{\pi}(s) = \sum_{a \in \mathcal{A}} Q_{\pi}(s, a) \pi(a \vert s)
$$

动作价值和状态价值之间的差异是动作 **优势** 函数（“A 值”）：

> The difference between action-value and state-value is the action **advantage** function (“A-value”):

$$
A_{\pi}(s, a) = Q_{\pi}(s, a) - V_{\pi}(s)
$$

##### 最优价值和策略

> Optimal Value and Policy

最优价值函数产生最大回报：

> The optimal value function produces the maximum return:

$$
V_{*}(s) = \max_{\pi} V_{\pi}(s),
Q_{*}(s, a) = \max_{\pi} Q_{\pi}(s, a)
$$

最优策略实现最优价值函数：

> The optimal policy achieves optimal value functions:

$$
\pi_{*} = \arg\max_{\pi} V_{\pi}(s),
\pi_{*} = \arg\max_{\pi} Q_{\pi}(s, a)
$$

当然，我们有 $V_{\pi_{*}}(s)=V_{*}(s)$ 和 $Q_{\pi_{*}}(s, a) = Q_{*}(s, a)$。

> And of course, we have $V_{\pi_{*}}(s)=V_{*}(s)$ and $Q_{\pi_{*}}(s, a) = Q_{*}(s, a)$.

#### 马尔可夫决策过程

> Markov Decision Processes

更正式地说，几乎所有的强化学习问题都可以被构架为 **马尔可夫决策过程** (MDPs)。MDP 中的所有状态都具有“马尔可夫”性质，指的是未来只取决于当前状态，而不取决于历史：

> In more formal terms, almost all the RL problems can be framed as **Markov Decision Processes** (MDPs). All states in MDP has “Markov” property, referring to the fact that the future only depends on the current state, not the history:

$$
\mathbb{P}[ S_{t+1} \vert S_t ] = \mathbb{P} [S_{t+1} \vert S_1, \dots, S_t]
$$

换句话说，给定当前状态，未来和过去是 **条件独立的**，因为当前状态包含了我们决定未来所需的所有统计信息。

> Or in other words, the future and the past are **conditionally independent** given the present, as the current state encapsulates all the statistics we need to decide the future.

![The agent-environment interaction in a Markov decision process. (Image source: Sec. 3.1 Sutton & Barto (2017).)](https://lilianweng.github.io/posts/2018-02-19-rl-overview/agent_environment_MDP.png)

马尔可夫决策过程由五个元素 $\mathcal{M} = \langle \mathcal{S}, \mathcal{A}, P, R, \gamma \rangle$ 组成，其中符号的含义与 [上一](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#key-concepts) 节中的关键概念相同，与强化学习问题设置很好地对齐：

> A Markov deicison process consists of five elements $\mathcal{M} = \langle \mathcal{S}, \mathcal{A}, P, R, \gamma \rangle$, where the symbols carry the same meanings as key concepts in the [previous](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#key-concepts) section, well aligned with RL problem settings:

• $\mathcal{S}$ - 状态集合；

• $\mathcal{A}$ - 动作集合；

• $P$ - 转移概率函数；

• $R$ - 奖励函数；

• $\gamma$ - 未来奖励的折扣因子。\n在一个未知环境中，我们对 $P$ 和 $R$ 没有完美的了解。

英文原文：

• $\mathcal{S}$ - a set of states;

• $\mathcal{A}$ - a set of actions;

• $P$ - transition probability function;

• $R$ - reward function;

• $\gamma$ - discounting factor for future rewards.
In an unknown environment, we do not have perfect knowledge about $P$ and $R$.

![A fun example of Markov decision process: a typical work day. (Image source: randomant.net/reinforcement-learning-concepts )](https://lilianweng.github.io/posts/2018-02-19-rl-overview/mdp_example.jpg)

#### 贝尔曼方程

> Bellman Equations

贝尔曼方程是指一组将价值函数分解为即时奖励加上折扣未来价值的方程。

> Bellman equations refer to a set of equations that decompose the value function into the immediate reward plus the discounted future values.

$$
\begin{aligned}
V(s) &= \mathbb{E}[G_t \vert S_t = s] \\
&= \mathbb{E} [R_{t+1} + \gamma R_{t+2} + \gamma^2 R_{t+3} + \dots \vert S_t = s] \\
&= \mathbb{E} [R_{t+1} + \gamma (R_{t+2} + \gamma R_{t+3} + \dots) \vert S_t = s] \\
&= \mathbb{E} [R_{t+1} + \gamma G_{t+1} \vert S_t = s] \\
&= \mathbb{E} [R_{t+1} + \gamma V(S_{t+1}) \vert S_t = s]
\end{aligned}
$$

对于 Q 值也类似，

> Similarly for Q-value,

$$
\begin{aligned}
Q(s, a) 
&= \mathbb{E} [R_{t+1} + \gamma V(S_{t+1}) \mid S_t = s, A_t = a] \\
&= \mathbb{E} [R_{t+1} + \gamma \mathbb{E}_{a\sim\pi} Q(S_{t+1}, a) \mid S_t = s, A_t = a]
\end{aligned}
$$

##### 贝尔曼期望方程

> Bellman Expectation Equations

递归更新过程可以进一步分解为基于状态价值函数和动作价值函数的方程。随着我们在未来的动作步骤中走得更远，我们通过遵循策略 $\pi$ 交替地扩展 V 和 Q。

> The recursive update process can be further decomposed to be equations built on both state-value and action-value functions. As we go further in future action steps, we extend V and Q alternatively by following the policy $\pi$.

![Illustration of how Bellman expection equations update state-value and action-value functions.](https://lilianweng.github.io/posts/2018-02-19-rl-overview/bellman_equation.png)

$$
\begin{aligned}
V_{\pi}(s) &= \sum_{a \in \mathcal{A}} \pi(a \vert s) Q_{\pi}(s, a) \\
Q_{\pi}(s, a) &= R(s, a) + \gamma \sum_{s' \in \mathcal{S}} P_{ss'}^a V_{\pi} (s') \\
V_{\pi}(s) &= \sum_{a \in \mathcal{A}} \pi(a \vert s) \big( R(s, a) + \gamma \sum_{s' \in \mathcal{S}} P_{ss'}^a V_{\pi} (s') \big) \\
Q_{\pi}(s, a) &= R(s, a) + \gamma \sum_{s' \in \mathcal{S}} P_{ss'}^a \sum_{a' \in \mathcal{A}} \pi(a' \vert s') Q_{\pi} (s', a')
\end{aligned}
$$

##### 贝尔曼最优方程

> Bellman Optimality Equations

如果我们只对最优值感兴趣，而不是计算遵循策略的期望，我们可以在不使用策略的情况下，直接在交替更新期间跳到最大回报。回顾：最优值 $V_*$ 和 $Q_*$ 是我们能获得的最佳回报，[此处](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#optimal-value-and-policy)定义。

> If we are only interested in the optimal values, rather than computing the expectation following a policy, we could jump right into the maximum returns during the alternative updates without using a policy. RECAP: the optimal values $V_*$ and $Q_*$ are the best returns we can obtain, defined [here](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#optimal-value-and-policy).

$$
\begin{aligned}
V_*(s) &= \max_{a \in \mathcal{A}} Q_*(s,a)\\
Q_*(s, a) &= R(s, a) + \gamma \sum_{s' \in \mathcal{S}} P_{ss'}^a V_*(s') \\
V_*(s) &= \max_{a \in \mathcal{A}} \big( R(s, a) + \gamma \sum_{s' \in \mathcal{S}} P_{ss'}^a V_*(s') \big) \\
Q_*(s, a) &= R(s, a) + \gamma \sum_{s' \in \mathcal{S}} P_{ss'}^a \max_{a' \in \mathcal{A}} Q_*(s', a')
\end{aligned}
$$

不出所料，它们看起来与贝尔曼期望方程非常相似。

> Unsurprisingly they look very similar to Bellman expectation equations.

如果我们拥有环境的完整信息，这就会变成一个规划问题，可以通过 DP 解决。不幸的是，在大多数情况下，我们不知道 $P_{ss’}^a$ 或 $R(s, a)$，因此我们不能通过直接应用贝尔曼方程来解决 MDP，但它为许多强化学习算法奠定了理论基础。

> If we have complete information of the environment, this turns into a planning problem, solvable by DP. Unfortunately, in most scenarios, we do not know $P_{ss’}^a$ or $R(s, a)$, so we cannot solve MDPs by directly applying Bellmen equations, but it lays the theoretical foundation for many RL algorithms.

### 常见方法

> Common Approaches

现在是时候回顾解决强化学习问题的主要方法和经典算法了。在未来的文章中，我计划深入探讨每种方法。

> Now it is the time to go through the major approaches and classic algorithms for solving RL problems. In future posts, I plan to dive into each approach further.

#### 动态规划

> Dynamic Programming

当模型完全已知时，遵循贝尔曼方程，我们可以使用[动态规划](https://en.wikipedia.org/wiki/Dynamic_programming) (DP) 来迭代评估价值函数并改进策略。

> When the model is fully known, following Bellman equations, we can use [Dynamic Programming](https://en.wikipedia.org/wiki/Dynamic_programming) (DP) to iteratively evaluate value functions and improve policy.

##### 策略评估

> Policy Evaluation

策略评估旨在计算给定策略的状态值$V_\pi$，对于给定策略$\pi$：

> Policy Evaluation is to compute the state-value $V_\pi$ for a given policy $\pi$:

$$
V_{t+1}(s) 
= \mathbb{E}_\pi [r + \gamma V_t(s') | S_t = s]
= \sum_a \pi(a \vert s) \sum_{s', r} P(s', r \vert s, a) (r + \gamma V_t(s'))
$$

##### 策略改进

> Policy Improvement

基于价值函数，策略改进通过贪婪地采取行动生成更好的策略$\pi’ \geq \pi$。

> Based on the value functions, Policy Improvement generates a better policy $\pi’ \geq \pi$ by acting greedily.

$$
Q_\pi(s, a) 
= \mathbb{E} [R_{t+1} + \gamma V_\pi(S_{t+1}) \vert S_t=s, A_t=a]
= \sum_{s', r} P(s', r \vert s, a) (r + \gamma V_\pi(s'))
$$

##### 策略迭代

> Policy Iteration

*广义策略迭代（GPI）*算法指的是一种迭代过程，用于在结合策略评估和改进时改进策略。

> The *Generalized Policy Iteration (GPI)* algorithm refers to an iterative procedure to improve the policy when combining policy evaluation and improvement.

$$
\pi_0 \xrightarrow[ ]{\text{evaluation}} V_{\pi_0} \xrightarrow[ ]{\text{improve}} \pi_1 \xrightarrow[ ]{\text{evaluation}} V_{\pi_1} \xrightarrow[ ]{\text{improve}} \pi_2 \xrightarrow[ ]{\text{evaluation}} \dots \xrightarrow[ ]{\text{improve}} \pi_* \xrightarrow[ ]{\text{evaluation}} V_*
$$

在GPI中，价值函数被反复近似以更接近当前策略的真实价值，同时，策略被反复改进以接近最优性。这个策略迭代过程有效并且总是收敛到最优性，但为什么会这样呢？

> In GPI, the value function is approximated repeatedly to be closer to the true value of the current policy and in the meantime, the policy is improved repeatedly to approach optimality. This policy iteration process works and always converges to the optimality, but why this is the case?

假设我们有一个策略$\pi$，然后通过贪婪地采取行动生成一个改进版本$\pi’$，$\pi’(s) = \arg\max_{a \in \mathcal{A}} Q_\pi(s, a)$。这个改进的$\pi’$的价值保证会更好，因为：

> Say, we have a policy $\pi$ and then generate an improved version $\pi’$ by greedily taking actions, $\pi’(s) = \arg\max_{a \in \mathcal{A}} Q_\pi(s, a)$. The value of this improved $\pi’$ is guaranteed to be better because:

$$
\begin{aligned}
Q_\pi(s, \pi'(s))
&= Q_\pi(s, \arg\max_{a \in \mathcal{A}} Q_\pi(s, a)) \\
&= \max_{a \in \mathcal{A}} Q_\pi(s, a) \geq Q_\pi(s, \pi(s)) = V_\pi(s)
\end{aligned}
$$

#### 蒙特卡洛方法

> Monte-Carlo Methods

首先，我们回顾一下$V(s) = \mathbb{E}[ G_t \vert S_t=s]$。蒙特卡洛（MC）方法采用了一个简单的思想：它从原始经验的片段中学习，而不对环境动态进行建模，并计算观察到的平均回报作为预期回报的近似值。为了计算经验回报`G_t`，MC 方法需要从**完整**片段$S_1, A_1, R_2, \dots, S_T$中学习来计算$G_t = \sum_{k=0}^{T-t-1} \gamma^k R_{t+k+1}$，并且所有片段最终都必须终止。

英文原文：First, let’s recall that 

$V(s) = \mathbb{E}[ G_t \vert S_t=s]$. Monte-Carlo (MC) methods uses a simple idea: It learns from episodes of raw experience without modeling the environmental dynamics and computes the observed mean return as an approximation of the expected return. To compute the empirical return `G_t`, MC methods need to learn from complete episodes 

$S_1, A_1, R_2, \dots, S_T$ to compute 

$G_t = \sum_{k=0}^{T-t-1} \gamma^k R_{t+k+1}$ and all the episodes must eventually terminate.

状态 s 的经验平均回报为：

> The empirical mean return for state s is:

$$
V(s) = \frac{\sum_{t=1}^T \mathbb{1}[S_t = s] G_t}{\sum_{t=1}^T \mathbb{1}[S_t = s]}
$$

其中$\mathbb{1}[S_t = s]$是一个二元指示函数。我们可以每次都计算状态 s 的访问次数，这样在一个片段中一个状态可以被多次访问（“每次访问”），或者只在在一个片段中第一次遇到一个状态时才计算（“首次访问”）。这种近似方法可以通过计算 (s, a) 对轻松扩展到动作值函数。

> where $\mathbb{1}[S_t = s]$ is a binary indicator function. We may count the visit of state s every time so that there could exist multiple visits of one state in one episode (“every-visit”), or only count it the first time we encounter a state in one episode (“first-visit”). This way of approximation can be easily extended to action-value functions by counting (s, a) pair.

$$
Q(s, a) = \frac{\sum_{t=1}^T \mathbb{1}[S_t = s, A_t = a] G_t}{\sum_{t=1}^T \mathbb{1}[S_t = s, A_t = a]}
$$

为了通过 MC 学习最优策略，我们通过遵循与[GPI](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#policy-iteration)类似的思想进行迭代。

> To learn the optimal policy by MC, we iterate it by following a similar idea to [GPI](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#policy-iteration).

![The backup diagrams for Q-learning and SARSA. (Image source: Replotted based on Figure 6.5 in Sutton & Barto (2017))](https://lilianweng.github.io/posts/2018-02-19-rl-overview/MC_control.png)

1\. 根据当前值函数贪婪地改进策略：$\pi(s) = \arg\max_{a \in \mathcal{A}} Q(s, a)$。

2\. 使用新策略生成一个新片段$\pi$（即，使用诸如[ε-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm)的算法有助于我们在利用和探索之间取得平衡。）

3\. 使用新片段估计 Q：$q_\pi(s, a) = \frac{\sum_{t=1}^T \big( \mathbb{1}[S_t = s, A_t = a] \sum_{k=0}^{T-t-1} \gamma^k R_{t+k+1} \big)}{\sum_{t=1}^T \mathbb{1}[S_t = s, A_t = a]}$

英文原文：

1\. Improve the policy greedily with respect to the current value function: $\pi(s) = \arg\max_{a \in \mathcal{A}} Q(s, a)$.

2\. Generate a new episode with the new policy $\pi$ (i.e. using algorithms like [ε-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm) helps us balance between exploitation and exploration.)

3\. Estimate Q using the new episode: $q_\pi(s, a) = \frac{\sum_{t=1}^T \big( \mathbb{1}[S_t = s, A_t = a] \sum_{k=0}^{T-t-1} \gamma^k R_{t+k+1} \big)}{\sum_{t=1}^T \mathbb{1}[S_t = s, A_t = a]}$

#### 时序差分学习

> Temporal-Difference Learning

与蒙特卡洛方法类似，时序差分（TD）学习是无模型的，并从经验片段中学习。然而，TD 学习可以从**不完整**片段中学习，因此我们不需要跟踪片段直到其终止。TD 学习非常重要，以至于 Sutton & Barto (2017) 在他们的强化学习书中将其描述为“强化学习中一个核心且新颖的思想”。

> Similar to Monte-Carlo methods, Temporal-Difference (TD) Learning is model-free and learns from episodes of experience. However, TD learning can learn from **incomplete** episodes and hence we don’t need to track the episode up to termination. TD learning is so important that Sutton & Barto (2017) in their RL book describes it as “one idea … central and novel to reinforcement learning”.

##### 自举

> Bootstrapping

TD 学习方法根据现有估计更新目标，而不是像 MC 方法那样完全依赖实际奖励和完整回报。这种方法被称为**自举**。

> TD learning methods update targets with regard to existing estimates rather than exclusively relying on actual rewards and complete returns as in MC methods. This approach is known as **bootstrapping**.

##### 价值估计

> Value Estimation

TD 学习的关键思想是更新价值函数 $V(S_t)$，使其趋向于一个估计的回报 $R_{t+1} + \gamma V(S_{t+1})$（称为“**TD 目标**”）。我们希望在多大程度上更新价值函数，这由学习率超参数 α 控制：

英文原文：The key idea in TD learning is to update the value function 

$V(S_t)$ towards an estimated return 

$R_{t+1} + \gamma V(S_{t+1})$ (known as “TD target”). To what extent we want to update the value function is controlled by the learning rate hyperparameter α:

$$
\begin{aligned}
V(S_t) &\leftarrow (1- \alpha) V(S_t) + \alpha G_t \\
V(S_t) &\leftarrow V(S_t) + \alpha (G_t - V(S_t)) \\
V(S_t) &\leftarrow V(S_t) + \alpha (R_{t+1} + \gamma V(S_{t+1}) - V(S_t))
\end{aligned}
$$

类似地，对于动作价值估计：

> Similarly, for action-value estimation:

$$
Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha (R_{t+1} + \gamma Q(S_{t+1}, A_{t+1}) - Q(S_t, A_t))
$$

接下来，让我们深入探讨 TD 学习中如何学习最优策略的有趣部分（又称“TD 控制”）。请做好准备，你将在本节中看到许多经典算法的著名名称。

> Next, let’s dig into the fun part on how to learn optimal policy in TD learning (aka “TD control”). Be prepared, you are gonna see many famous names of classic algorithms in this section.

##### SARSA：同策略 TD 控制

> SARSA: On-Policy TD control

“SARSA”指的是通过遵循一系列 $\dots, S_t, A_t, R_{t+1}, S_{t+1}, A_{t+1}, \dots$ 来更新 Q 值的过程。这个思想遵循 [GPI](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#policy-iteration) 的相同路径。在一个回合中，它的工作方式如下：

> “SARSA” refers to the procedure of updaing Q-value by following a sequence of $\dots, S_t, A_t, R_{t+1}, S_{t+1}, A_{t+1}, \dots$. The idea follows the same route of [GPI](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#policy-iteration). Within one episode, it works as follows:

1\. 初始化 $t=0$。

2\. 从$S_0$开始，选择动作$A_0 = \arg\max_{a \in \mathcal{A}} Q(S_0, a)$，其中[\epsilon-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%ce%b5-greedy-algorithm)常被应用。

3\. 在时间$t$，应用动作$A_t$后，我们观察到奖励$R_{t+1}$并进入下一个状态$S_{t+1}$。

4\. 然后以与步骤2相同的方式选择下一个动作：$A_{t+1} = \arg\max_{a \in \mathcal{A}} Q(S_{t+1}, a)$。

5\. 更新 Q 值函数：$Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha (R_{t+1} + \gamma Q(S_{t+1}, A_{t+1}) - Q(S_t, A_t))$。

6\. 设置 $t = t+1$ 并从步骤 3 重复。

英文原文：

1\. Initialize $t=0$.

2\. Start with $S_0$ and choose action $A_0 = \arg\max_{a \in \mathcal{A}} Q(S_0, a)$, where [\epsilon-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%ce%b5-greedy-algorithm) is commonly applied.

3\. At time $t$, after applying action $A_t$, we observe reward $R_{t+1}$ and get into the next state $S_{t+1}$.

4\. Then pick the next action in the same way as in step 2: $A_{t+1} = \arg\max_{a \in \mathcal{A}} Q(S_{t+1}, a)$.

5\. Update the Q-value function: $Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha (R_{t+1} + \gamma Q(S_{t+1}, A_{t+1}) - Q(S_t, A_t))$.

6\. Set $t = t+1$ and repeat from step 3.

在 SARSA 的每一步中，我们需要选择*下一个*动作，根据*当前*策略。

> In each step of SARSA, we need to choose the *next* action according to the *current* policy.

##### Q-Learning：离策略TD控制

> Q-Learning: Off-policy TD control

Q-learning（[Watkins & Dayan, 1992](https://link.springer.com/content/pdf/10.1007/BF00992698.pdf)）的发展是强化学习早期的一个重大突破。在一个回合中，它的工作方式如下：

> The development of Q-learning ([Watkins & Dayan, 1992](https://link.springer.com/content/pdf/10.1007/BF00992698.pdf)) is a big breakout in the early days of Reinforcement Learning. Within one episode, it works as follows:

1\. 初始化 $t=0$。

2\. 从 $S_0$ 开始。

3\. 在时间步 $t$，我们根据 Q 值选择动作，$A_t = \arg\max_{a \in \mathcal{A}} Q(S_t, a)$ 和 ε-greedy 是常用的方法。

4\. 执行动作 $A_t$ 后，我们观察到奖励 $R_{t+1}$ 并进入下一个状态 $S_{t+1}$。

5\. 更新 Q 值函数：$Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha (R_{t+1} + \gamma \max_{a \in \mathcal{A}} Q(S_{t+1}, a) - Q(S_t, A_t))$。

6\. $t = t+1$ 并从步骤 3 重复。

英文原文：

1\. Initialize $t=0$.

2\. Starts with $S_0$.

3\. At time step $t$, we pick the action according to Q values, $A_t = \arg\max_{a \in \mathcal{A}} Q(S_t, a)$ and ε-greedy is commonly applied.

4\. After applying action $A_t$, we observe reward $R_{t+1}$ and get into the next state $S_{t+1}$.

5\. Update the Q-value function: $Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha (R_{t+1} + \gamma \max_{a \in \mathcal{A}} Q(S_{t+1}, a) - Q(S_t, A_t))$.

6\. $t = t+1$ and repeat from step 3.

与 SARSA 的主要区别在于，Q-learning 不会遵循当前策略来选择第二个动作 $A_{t+1}$。它从最佳 Q 值中估计 $Q^{\ast}$，但哪个动作（表示为 $a^{\ast}$）导致这个最大 Q 值并不重要，并且在下一步中 Q-learning 可能不会遵循 $a^{\ast}$。

> The key difference from SARSA is that Q-learning does not follow the current policy to pick the second action $A_{t+1}$. It estimates $Q^{\ast}$ out of the best Q values, but which action (denoted as $a^{\ast}$) leads to this maximal Q does not matter and in the next step Q-learning may not follow $a^{\ast}$.

![The backup diagrams for Q-learning and SARSA. (Image source: Replotted based on Figure 6.5 in Sutton & Barto (2017))](https://lilianweng.github.io/posts/2018-02-19-rl-overview/sarsa_vs_q_learning.png)

##### 深度 Q 网络

> Deep Q-Network

理论上，我们可以在 Q-learning 中为所有状态-动作对记忆 $Q_*(.)$，就像在一个巨大的表格中一样。然而，当状态和动作空间很大时，这很快就会变得计算上不可行。因此，人们使用函数（即机器学习模型）来近似 Q 值，这被称为 **函数近似**。例如，如果我们使用带有参数 `\theta` 的函数来计算 Q 值，我们可以将 Q 值函数标记为 $Q(s, a; \theta)$。

英文原文：Theoretically, we can memorize 

$Q_*(.)$ for all state-action pairs in Q-learning, like in a gigantic table. However, it quickly becomes computationally infeasible when the state and action space are large. Thus people use functions (i.e. a machine learning model) to approximate Q values and this is called function approximation. For example, if we use a function with parameter `\theta` to calculate Q values, we can label Q value function as 

$Q(s, a; \theta)$.

不幸的是，当 Q-learning 与非线性 Q 值函数近似和 [自举](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#bootstrapping)（参见 [问题 #2](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deadly-triad-issue)）结合时，可能会出现不稳定和发散。

> Unfortunately Q-learning may suffer from instability and divergence when combined with an nonlinear Q-value function approximation and [bootstrapping](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#bootstrapping) (See [Problems #2](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deadly-triad-issue)).

深度 Q 网络（“DQN”；Mnih 等人，2015）旨在通过两种创新机制大大改进和稳定 Q-learning 的训练过程：

> Deep Q-Network (“DQN”; Mnih et al. 2015) aims to greatly improve and stabilize the training procedure of Q-learning by two innovative mechanisms:

• **经验回放**：所有回合步骤 $e_t = (S_t, A_t, R_t, S_{t+1})$ 都存储在一个回放记忆 $D_t = \{ e_1, \dots, e_t \}$ 中。$D_t$ 包含多个回合的经验元组。在 Q-learning 更新期间，样本从回放记忆中随机抽取，因此一个样本可以被多次使用。经验回放提高了数据效率，消除了观测序列中的相关性，并平滑了数据分布的变化。

• **周期性更新目标**：Q 针对仅周期性更新的目标值进行优化。Q 网络被克隆并冻结作为每 C 步（C 是一个超参数）的优化目标。这种修改使训练更稳定，因为它克服了短期振荡。

英文原文：

• **Experience Replay**: All the episode steps $e_t = (S_t, A_t, R_t, S_{t+1})$ are stored in one replay memory $D_t = \{ e_1, \dots, e_t \}$. $D_t$ has experience tuples over many episodes. During Q-learning updates, samples are drawn at random from the replay memory and thus one sample could be used multiple times. Experience replay improves data efficiency, removes correlations in the observation sequences, and smooths over changes in the data distribution.

• **Periodically Updated Target**: Q is optimized towards target values that are only periodically updated. The Q network is cloned and kept frozen as the optimization target every C steps (C is a hyperparameter). This modification makes the training more stable as it overcomes the short-term oscillations.

损失函数如下所示：

> The loss function looks like this:

$$
\mathcal{L}(\theta) = \mathbb{E}_{(s, a, r, s') \sim U(D)} \Big[ \big( r + \gamma \max_{a'} Q(s', a'; \theta^{-}) - Q(s, a; \theta) \big)^2 \Big]
$$

其中 $U(D)$ 是回放记忆 D 上的均匀分布；$\theta^{-}$ 是冻结目标 Q 网络的参数。

> where $U(D)$ is a uniform distribution over the replay memory D; $\theta^{-}$ is the parameters of the frozen target Q-network.

此外，还将误差项裁剪到 [-1, 1] 之间也被发现是有帮助的。（我对参数裁剪总是喜忧参半，因为许多研究表明它在经验上有效，但它使数学变得不那么优美。:/）

> In addition, it is also found to be helpful to clip the error term to be between [-1, 1]. (I always get mixed feeling with parameter clipping, as many studies have shown that it works empirically but it makes the math much less pretty. :/)

![Algorithm for DQN with experience replay and occasionally frozen optimization target. The prepossessed sequence is the output of some processes running on the input images of Atari games. Don't worry too much about it; just consider them as input feature vectors. (Image source: Mnih et al. 2015)](https://lilianweng.github.io/posts/2018-02-19-rl-overview/DQN_algorithm.png)

DQN 有许多扩展来改进原始设计，例如具有对偶架构的 DQN（Wang 等人，2016），它使用共享网络参数估计状态值函数 V(s) 和优势函数 A(s, a)。

> There are many extensions of DQN to improve the original design, such as DQN with dueling architecture (Wang et al. 2016) which estimates state-value function V(s) and advantage function A(s, a) with shared network parameters.

#### 结合 TD 和 MC 学习

> Combining TD and MC Learning

在前面关于 TD 学习中价值估计的 [章节](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation) 中，我们在计算 TD 目标时只沿着动作链进一步追踪一步。可以很容易地将其扩展为采取多步来估计回报。

> In the previous [section](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation) on value estimation in TD learning, we only trace one step further down the action chain when calculating the TD target. One can easily extend it to take multiple steps to estimate the return.

我们将遵循 n 步的估计回报标记为 $G_t^{(n)}, n=1, \dots, \infty$，那么：

> Let’s label the estimated return following n steps as $G_t^{(n)}, n=1, \dots, \infty$, then:

| $n$ | $G_t$ | 备注 |
| --- | --- | --- |
| $n=1$ | $G_t^{(1)} = R_{t+1} + \gamma V(S_{t+1})$ | TD 学习 |
| $n=2$ | $G_t^{(2)} = R_{t+1} + \gamma R_{t+2} + \gamma^2 V(S_{t+2})$ |  |
| … |  |  |
| $n=n$ | $ G_t^{(n)} = R_{t+1} + \gamma R_{t+2} + \dots + \gamma^{n-1} R_{t+n} + \gamma^n V(S_{t+n}) $ |  |
| … |  |  |
| $n=\infty$ | $G_t^{(\infty)} = R_{t+1} + \gamma R_{t+2} + \dots + \gamma^{T-t-1} R_T + \gamma^{T-t} V(S_T) $ | MC 估计 |

> 英文原表 / English original

| $n$ | $G_t$ | Notes |
| --- | --- | --- |
| $n=1$ | $G_t^{(1)} = R_{t+1} + \gamma V(S_{t+1})$ | TD learning |
| $n=2$ | $G_t^{(2)} = R_{t+1} + \gamma R_{t+2} + \gamma^2 V(S_{t+2})$ |  |
| … |  |  |
| $n=n$ | $ G_t^{(n)} = R_{t+1} + \gamma R_{t+2} + \dots + \gamma^{n-1} R_{t+n} + \gamma^n V(S_{t+n}) $ |  |
| … |  |  |
| $n=\infty$ | $G_t^{(\infty)} = R_{t+1} + \gamma R_{t+2} + \dots + \gamma^{T-t-1} R_T + \gamma^{T-t} V(S_T) $ | MC estimation |

广义 n 步 TD 学习在更新价值函数时仍具有[相同](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation)的形式：

> The generalized n-step TD learning still has the [same](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation) form for updating the value function:

$$
V(S_t) \leftarrow V(S_t) + \alpha (G_t^{(n)} - V(S_t))
$$

![Comparison of the backup diagrams of Monte-Carlo, Temporal-Difference learning, and Dynamic Programming for state value functions. (Image source: David Silver's RL course lecture 4 : "Model-Free Prediction")](https://lilianweng.github.io/posts/2018-02-19-rl-overview/TD_lambda.png)

我们可以随意选择 TD 学习中的任何 $n$。现在问题变成了什么是最好的 $n$？哪个 $G_t^{(n)}$ 能给我们最好的回报近似？一个常见而巧妙的解决方案是应用所有可能的 n 步 TD 目标的加权和，而不是选择一个单一的最佳 n。权重随 n 以因子 λ 衰减，$\lambda^{n-1}$；其直觉类似于[为什么](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation)我们在计算回报时要折现未来奖励：我们看得越远，信心就越不足。为了使所有权重 (n → ∞) 之和为 1，我们将每个权重乘以 (1-λ)，因为：

> We are free to pick any $n$ in TD learning as we like. Now the question becomes what is the best $n$? Which $G_t^{(n)}$ gives us the best return approximation? A common yet smart solution is to apply a weighted sum of all possible n-step TD targets rather than to pick a single best n. The weights decay by a factor λ with n, $\lambda^{n-1}$; the intuition is similar to [why](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation) we want to discount future rewards when computing the return: the more future we look into the less confident we would be. To make all the weight (n → ∞) sum up to 1, we multiply every weight by (1-λ), because:

$$
\begin{aligned}
\text{let } S &= 1 + \lambda + \lambda^2 + \dots \\
S &= 1 + \lambda(1 + \lambda + \lambda^2 + \dots) \\
S &= 1 + \lambda S \\
S &= 1 / (1-\lambda)
\end{aligned}
$$

这种多个 n 步回报的加权和被称为 λ-回报 $G_t^{\lambda} = (1-\lambda) \sum_{n=1}^{\infty} \lambda^{n-1} G_t^{(n)}$。采用 λ-回报进行价值更新的 TD 学习被称为 **TD(λ)**。我们[上面](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation)介绍的原始版本等同于 **TD(0)**。

英文原文：This weighted sum of many n-step returns is called λ-return 

$G_t^{\lambda} = (1-\lambda) \sum_{n=1}^{\infty} \lambda^{n-1} G_t^{(n)}$. TD learning that adopts λ-return for value updating is labeled as TD(λ). The original version we introduced [above](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-estimation) is equivalent to TD(0).

![Comparison of the backup diagrams of Monte-Carlo, Temporal-Difference learning, and Dynamic Programming for state value functions. (Image source: David Silver's RL course lecture 4 : "Model-Free Prediction")](https://lilianweng.github.io/posts/2018-02-19-rl-overview/TD_MC_DP_backups.png)

#### 策略梯度

> Policy Gradient

我们上面介绍的所有方法都旨在学习状态/动作值函数，然后据此选择动作。策略梯度方法则直接学习策略，使用关于 $\theta$、$\pi(a \vert s; \theta)$ 的参数化函数。我们将奖励函数（损失函数的反义词）定义为 *预期回报*，并训练算法以最大化奖励函数为目标。我的 [下一篇文章](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/) 描述了策略梯度定理为何有效（证明），并介绍了一些策略梯度算法。

> All the methods we have introduced above aim to learn the state/action value function and then to select actions accordingly. Policy Gradient methods instead learn the policy directly with a parameterized function respect to $\theta$, $\pi(a \vert s; \theta)$. Let’s define the reward function (opposite of loss function) as *the expected return* and train the algorithm with the goal to maximize the reward function. My [next post](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/) described why the policy gradient theorem works (proof) and introduced a number of policy gradient algorithms.

在离散空间中：

> In discrete space:

$$
\mathcal{J}(\theta) = V_{\pi_\theta}(S_1) = \mathbb{E}_{\pi_\theta}[V_1]
$$

其中 $S_1$ 是初始起始状态。

> where $S_1$ is the initial starting state.

或在连续空间中：

> Or in continuous space:

$$
\mathcal{J}(\theta) = \sum_{s \in \mathcal{S}} d_{\pi_\theta}(s) V_{\pi_\theta}(s) = \sum_{s \in \mathcal{S}} \Big( d_{\pi_\theta}(s) \sum_{a \in \mathcal{A}} \pi(a \vert s, \theta) Q_\pi(s, a) \Big)
$$

其中 $d_{\pi_\theta}(s)$ 是 $\pi_\theta$ 的马尔可夫链的平稳分布。如果您不熟悉“平稳分布”的定义，请查阅此 [参考文献](https://jeremykun.com/2015/04/06/markov-chain-monte-carlo-without-all-the-bullshit/)。

> where $d_{\pi_\theta}(s)$ is stationary distribution of Markov chain for $\pi_\theta$. If you are unfamiliar with the definition of a “stationary distribution,” please check this [reference](https://jeremykun.com/2015/04/06/markov-chain-monte-carlo-without-all-the-bullshit/).

使用 *梯度上升*，我们可以找到产生最高回报的最佳 θ。很自然地，我们可以预期基于策略的方法在连续空间中更有用，因为在连续空间中存在无限数量的动作和/或状态需要估计其值，因此基于值的方法在计算上要昂贵得多。

> Using *gradient ascent* we can find the best θ that produces the highest return. It is natural to expect policy-based methods are more useful in continuous space, because there is an infinite number of actions and/or states to estimate the values for in continuous space and hence value-based approaches are computationally much more expensive.

##### 策略梯度定理

> Policy Gradient Theorem

计算梯度*数值上*可以通过在第 k 维上将 θ 扰动一个小的量 ε 来完成。即使当$J(\theta)$不可微分时，它也有效（很好！），但不出所料，它非常慢。

> Computing the gradient *numerically* can be done by perturbing θ by a small amount ε in the k-th dimension. It works even when $J(\theta)$ is not differentiable (nice!), but unsurprisingly very slow.

$$
\frac{\partial \mathcal{J}(\theta)}{\partial \theta_k} \approx \frac{\mathcal{J}(\theta + \epsilon u_k) - \mathcal{J}(\theta)}{\epsilon}
$$

或者 *解析地*，

> Or *analytically*,

$$
\mathcal{J}(\theta) = \mathbb{E}_{\pi_\theta} [r] = \sum_{s \in \mathcal{S}} d_{\pi_\theta}(s) \sum_{a \in \mathcal{A}} \pi(a \vert s; \theta) R(s, a)
$$

实际上，我们有很好的理论支持（用于替换 $d(.)$ 为 $d_\pi(.)$）：

> Actually we have nice theoretical support for (replacing $d(.)$ with $d_\pi(.)$):

$$
\mathcal{J}(\theta) = \sum_{s \in \mathcal{S}} d_{\pi_\theta}(s) \sum_{a \in \mathcal{A}} \pi(a \vert s; \theta) Q_\pi(s, a) \propto \sum_{s \in \mathcal{S}} d(s) \sum_{a \in \mathcal{A}} \pi(a \vert s; \theta) Q_\pi(s, a)
$$

关于这种情况的原因，请查阅 Sutton & Barto (2017) 的第 13.1 节。

> Check Sec 13.1 in Sutton & Barto (2017) for why this is the case.

然后，

> Then,

$$
\begin{aligned}
\mathcal{J}(\theta) &= \sum_{s \in \mathcal{S}} d(s) \sum_{a \in \mathcal{A}} \pi(a \vert s; \theta) Q_\pi(s, a) \\
\nabla \mathcal{J}(\theta) &= \sum_{s \in \mathcal{S}} d(s) \sum_{a \in \mathcal{A}} \nabla \pi(a \vert s; \theta) Q_\pi(s, a) \\
&= \sum_{s \in \mathcal{S}} d(s) \sum_{a \in \mathcal{A}} \pi(a \vert s; \theta) \frac{\nabla \pi(a \vert s; \theta)}{\pi(a \vert s; \theta)} Q_\pi(s, a) \\
& = \sum_{s \in \mathcal{S}} d(s) \sum_{a \in \mathcal{A}} \pi(a \vert s; \theta) \nabla \ln \pi(a \vert s; \theta) Q_\pi(s, a) \\
& = \mathbb{E}_{\pi_\theta} [\nabla \ln \pi(a \vert s; \theta) Q_\pi(s, a)]
\end{aligned}
$$

这个结果被称为“策略梯度定理”，它为各种策略梯度算法奠定了理论基础：

> This result is named “Policy Gradient Theorem” which lays the theoretical foundation for various policy gradient algorithms:

$$
\nabla \mathcal{J}(\theta) = \mathbb{E}_{\pi_\theta} [\nabla \ln \pi(a \vert s, \theta) Q_\pi(s, a)]
$$

##### REINFORCE

> REINFORCE

REINFORCE，也称为蒙特卡洛策略梯度，它依赖于 $Q_\pi(s, a)$，这是一个通过使用情节样本的 [MC](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#monte-carlo-methods) 方法估算的收益，来更新策略参数 $\theta$。

> REINFORCE, also known as Monte-Carlo policy gradient, relies on $Q_\pi(s, a)$, an estimated return by [MC](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#monte-carlo-methods) methods using episode samples, to update the policy parameter $\theta$.

REINFORCE 的一个常用变体是从收益 $G_t$ 中减去一个基线值，以在保持偏差不变的情况下减少梯度估计的方差。例如，一个常见的基线是状态值，如果应用，我们将在梯度上升更新中使用 $A(s, a) = Q(s, a) - V(s)$。

> A commonly used variation of REINFORCE is to subtract a baseline value from the return $G_t$ to reduce the variance of gradient estimation while keeping the bias unchanged. For example, a common baseline is state-value, and if applied, we would use $A(s, a) = Q(s, a) - V(s)$ in the gradient ascent update.

1\. 随机初始化 θ

2\. 生成一个情节 $S_1, A_1, R_2, S_2, A_2, \dots, S_T$

3\. 对于 t=1, 2, … , T:



1\. 估计从时间步 t 开始的收益 G_t。



2\. $\theta \leftarrow \theta + \alpha \gamma^t G_t \nabla \ln \pi(A_t \vert S_t, \theta)$。

英文原文：

1\. Initialize θ at random

2\. Generate one episode $S_1, A_1, R_2, S_2, A_2, \dots, S_T$

3\. For t=1, 2, … , T:



1\. Estimate the the return G_t since the time step t.



2\. $\theta \leftarrow \theta + \alpha \gamma^t G_t \nabla \ln \pi(A_t \vert S_t, \theta)$.

##### Actor-Critic

> Actor-Critic

如果除了策略之外还学习值函数，我们将得到 Actor-Critic 算法。

> If the value function is learned in addition to the policy, we would get Actor-Critic algorithm.

• **Critic**：更新值函数参数 w，根据算法，它可以是动作值 $Q(a \vert s; w)$ 或状态值 $V(s; w)$。

• **Actor**：根据 Critic 建议的方向更新策略参数 θ，$\pi(a \vert s; \theta)$。

英文原文：

• **Critic**: updates value function parameters w and depending on the algorithm it could be action-value $Q(a \vert s; w)$ or state-value $V(s; w)$.

• **Actor**: updates policy parameters θ, in the direction suggested by the critic, $\pi(a \vert s; \theta)$.

让我们看看它在动作值 Actor-Critic 算法中是如何工作的。

> Let’s see how it works in an action-value actor-critic algorithm.

1\. 随机初始化 s, θ, w；采样 $a \sim \pi(a \vert s; \theta)$。

2\. 对于 t = 1… T:



1\. 采样奖励 $r_t \sim R(s, a)$ 和下一个状态 $s’ \sim P(s’ \vert s, a)$。



2\. 然后采样下一个动作 $a’ \sim \pi(s’, a’; \theta)$。



3\. 更新策略参数：$\theta \leftarrow \theta + \alpha_\theta Q(s, a; w) \nabla_\theta \ln \pi(a \vert s; \theta)$。



4\. 计算时间 t 的动作值修正：  



$G_{t:t+1} = r_t + \gamma Q(s’, a’; w) - Q(s, a; w)$   



并用它来更新值函数参数：  



$w \leftarrow w + \alpha_w G_{t:t+1} \nabla_w Q(s, a; w)$。



5\. 更新 $a \leftarrow a’$ 和 $s \leftarrow s’$。

英文原文：

1\. Initialize s, θ, w at random; sample $a \sim \pi(a \vert s; \theta)$.

2\. For t = 1… T:



1\. Sample reward $r_t \sim R(s, a)$ and next state $s’ \sim P(s’ \vert s, a)$.



2\. Then sample the next action $a’ \sim \pi(s’, a’; \theta)$.



3\. Update policy parameters: $\theta \leftarrow \theta + \alpha_\theta Q(s, a; w) \nabla_\theta \ln \pi(a \vert s; \theta)$.



4\. Compute the correction for action-value at time t:   



$G_{t:t+1} = r_t + \gamma Q(s’, a’; w) - Q(s, a; w)$   



and use it to update value function parameters:   



$w \leftarrow w + \alpha_w G_{t:t+1} \nabla_w Q(s, a; w)$.



5\. Update $a \leftarrow a’$ and $s \leftarrow s’$.

$\alpha_\theta$ 和 $\alpha_w$ 分别是策略和值函数参数更新的两个学习率。

> $\alpha_\theta$ and $\alpha_w$ are two learning rates for policy and value function parameter updates, respectively.

##### A3C

> A3C

**异步优势 Actor-Critic** (Mnih et al., 2016)，简称 A3C，是一种经典的策略梯度方法，特别侧重于并行训练。

> **Asynchronous Advantage Actor-Critic** (Mnih et al., 2016), short for A3C, is a classic policy gradient method with the special focus on parallel training.

在 A3C 中，Critic 学习状态值函数 $V(s; w)$，而多个 Actor 并行训练并定期与全局参数同步。因此，A3C 默认适用于并行训练，即在具有多核 CPU 的一台机器上。

> In A3C, the critics learn the state-value function, $V(s; w)$, while multiple actors are trained in parallel and get synced with global parameters from time to time. Hence, A3C is good for parallel training by default, i.e. on one machine with multi-core CPU.

状态值的损失函数是最小化均方误差 $\mathcal{J}_v (w) = (G_t - V(s; w))^2$，我们使用梯度下降来找到最优的 w。这个状态值函数在策略梯度更新中用作基线。

> The loss function for state-value is to minimize the mean squared error, $\mathcal{J}_v (w) = (G_t - V(s; w))^2$ and we use gradient descent to find the optimal w. This state-value function is used as the baseline in the policy gradient update.

以下是算法概述：

> Here is the algorithm outline:

1\. 我们有全局参数 θ 和 w；类似的线程特定参数 θ’ 和 w'。

2\. 初始化时间步 t = 1

3\. 当 T <= T_MAX 时：



1\. 重置梯度：dθ = 0 且 dw = 0。



2\. 将线程特定参数与全局参数同步：θ’ = θ 且 w’ = w。



3\. $t_\text{start}$ = t 并得到 $s_t$。



4\. 当 ($s_t \neq \text{TERMINAL}$) 且 ($t - t_\text{start} <= t_\text{max}$) 时：







1\. 选择动作 $a_t \sim \pi(a_t \vert s_t; \theta’)$ 并接收新的奖励 $r_t$ 和新的状态 $s_{t+1}$。







2\. 更新 t = t + 1 且 T = T + 1。



5\. 初始化用于保存回报估计值的变量 



$$

R = \begin{cases}

0 & \text{if } s_t \text{ is TERMINAL} \

V(s_t; w’) & \text{otherwise}

\end{cases}

$$



。



6\. 对于 $i = t-1, \dots, t_\text{start}$：







1\. $R \leftarrow r_i + \gamma R$；这里 R 是 $G_i$ 的 MC 度量。







2\. 累积关于 θ’ 的梯度：$d\theta \leftarrow d\theta + \nabla_{\theta’} \log \pi(a_i \vert s_i; \theta’)(R - V(s_i; w’))$;  







累积关于 w’ 的梯度：$dw \leftarrow dw + \nabla_{w’} (R - V(s_i; w’))^2$。



7\. 使用 dθ 同步更新 θ，并使用 dw 同步更新 w。

英文原文：

1\. We have global parameters, θ and w; similar thread-specific parameters, θ’ and w'.

2\. Initialize the time step t = 1

3\. While T <= T_MAX:



1\. Reset gradient: dθ = 0 and dw = 0.



2\. Synchronize thread-specific parameters with global ones: θ’ = θ and w’ = w.



3\. $t_\text{start}$ = t and get $s_t$.



4\. While ($s_t \neq \text{TERMINAL}$) and ($t - t_\text{start} <= t_\text{max}$):







1\. Pick the action $a_t \sim \pi(a_t \vert s_t; \theta’)$ and receive a new reward $r_t$ and a new state $s_{t+1}$.







2\. Update t = t + 1 and T = T + 1.



5\. Initialize the variable that holds the return estimation 



$$

R = \begin{cases}

0 & \text{if } s_t \text{ is TERMINAL} \

V(s_t; w’) & \text{otherwise}

\end{cases}

$$



.



6\. For $i = t-1, \dots, t_\text{start}$:







1\. $R \leftarrow r_i + \gamma R$; here R is a MC measure of $G_i$.







2\. Accumulate gradients w.r.t. θ’: $d\theta \leftarrow d\theta + \nabla_{\theta’} \log \pi(a_i \vert s_i; \theta’)(R - V(s_i; w’))$;  







Accumulate gradients w.r.t. w’: $dw \leftarrow dw + \nabla_{w’} (R - V(s_i; w’))^2$.



7\. Update synchronously θ using dθ, and w using dw.

A3C 实现了多智能体训练中的并行性。梯度累积步骤 (6.2) 可以被视为基于小批量随机梯度更新的一种重构：w 或 θ 的值在每个训练线程的方向上独立地进行微小修正。

> A3C enables the parallelism in multiple agent training. The gradient accumulation step (6.2) can be considered as a reformation of minibatch-based stochastic gradient update: the values of w or θ get corrected by a little bit in the direction of each training thread independently.

#### 演化策略

> Evolution Strategies

[演化策略](https://en.wikipedia.org/wiki/Evolution_strategy) (ES) 是一种模型无关的优化方法。它通过模仿达尔文的物种自然选择进化论来学习最优解。应用 ES 的两个先决条件是：(1) 我们的解决方案可以自由地与环境交互，并查看它们是否能解决问题；(2) 我们能够计算每个解决方案的 **适应度** 分数，以衡量其优劣。我们无需了解环境配置即可解决问题。

> [Evolution Strategies](https://en.wikipedia.org/wiki/Evolution_strategy) (ES) is a type of model-agnostic optimization approach. It learns the optimal solution by imitating Darwin’s theory of the evolution of species by natural selection. Two prerequisites for applying ES: (1) our solutions can freely interact with the environment and see whether they can solve the problem; (2) we are able to compute a **fitness** score of how good each solution is. We don’t have to know the environment configuration to solve the problem.

假设我们从一组随机解决方案开始。所有这些解决方案都能够与环境交互，并且只有具有高适应度分数的候选者才能存活 (*在有限资源的竞争中，只有最适者才能生存*)。然后通过重新组合高适应度幸存者的设置 (*基因突变*) 来创建新一代。这个过程重复进行，直到新的解决方案足够好。

> Say, we start with a population of random solutions. All of them are capable of interacting with the environment and only candidates with high fitness scores can survive (*only the fittest can survive in a competition for limited resources*). A new generation is then created by recombining the settings (*gene mutation*) of high-fitness survivors. This process is repeated until the new solutions are good enough.

与我们上面介绍的流行的基于 MDP 的方法非常不同，ES 旨在学习策略参数 $\theta$ 而无需值近似。让我们假设参数 $\theta$ 上的分布是一个 [各向同性](https://math.stackexchange.com/questions/1991961/gaussian-distribution-is-isotropic) 多元高斯分布，其均值为 $\mu$ 且协方差固定为 $\sigma^2I$。计算 $F(\theta)$ 的梯度：

> Very different from the popular MDP-based approaches as what we have introduced above, ES aims to learn the policy parameter $\theta$ without value approximation. Let’s assume the distribution over the parameter $\theta$ is an [isotropic](https://math.stackexchange.com/questions/1991961/gaussian-distribution-is-isotropic) multivariate Gaussian with mean $\mu$ and fixed covariance $\sigma^2I$. The gradient of $F(\theta)$ is calculated:

$$
\begin{aligned}
& \nabla_\theta \mathbb{E}_{\theta \sim N(\mu, \sigma^2)} F(\theta) \\
=& \nabla_\theta \int_\theta F(\theta) \Pr(\theta) && \text{Pr(.) is the Gaussian density function.} \\
=& \int_\theta F(\theta) \Pr(\theta) \frac{\nabla_\theta \Pr(\theta)}{\Pr(\theta)} \\
=& \int_\theta F(\theta) \Pr(\theta) \nabla_\theta \log \Pr(\theta) \\
=& \mathbb{E}_{\theta \sim N(\mu, \sigma^2)} [F(\theta) \nabla_\theta \log \Pr(\theta)] && \text{Similar to how we do policy gradient update.} \\
=& \mathbb{E}_{\theta \sim N(\mu, \sigma^2)} \Big[ F(\theta) \nabla_\theta \log \Big( \frac{1}{\sqrt{2\pi\sigma^2}} e^{-\frac{(\theta - \mu)^2}{2 \sigma^2 }} \Big) \Big] \\
=& \mathbb{E}_{\theta \sim N(\mu, \sigma^2)} \Big[ F(\theta) \nabla_\theta \Big( -\log \sqrt{2\pi\sigma^2} - \frac{(\theta - \mu)^2}{2 \sigma^2} \Big) \Big] \\
=& \mathbb{E}_{\theta \sim N(\mu, \sigma^2)} \Big[ F(\theta) \frac{\theta - \mu}{\sigma^2} \Big]
\end{aligned}
$$

我们可以将此公式改写为“均值”参数 $\theta$（与上面的 $\theta$ 不同；这个 $\theta$ 是进一步突变的基础基因）、$\epsilon \sim N(0, I)$，因此 $\theta + \epsilon \sigma \sim N(\theta, \sigma^2)$。$\epsilon$ 控制应添加多少高斯噪声来产生突变：

> We can rewrite this formula in terms of a “mean” parameter $\theta$ (different from the $\theta$ above; this $\theta$ is the base gene for further mutation), $\epsilon \sim N(0, I)$ and therefore $\theta + \epsilon \sigma \sim N(\theta, \sigma^2)$. $\epsilon$ controls how much Gaussian noises should be added to create mutation:

$$
\nabla_\theta \mathbb{E}_{\epsilon \sim N(0, I)} F(\theta + \sigma \epsilon) = \frac{1}{\sigma} \mathbb{E}_{\epsilon \sim N(0, I)} [F(\theta + \sigma \epsilon) \epsilon]
$$

![A simple parallel evolution-strategies-based RL algorithm. Parallel workers share the random seeds so that they can reconstruct the Gaussian noises with tiny communication bandwidth. (Image source: Salimans et al. 2017.)](https://lilianweng.github.io/posts/2018-02-19-rl-overview/EA_RL_parallel.png)

ES 作为一种黑盒优化算法，是解决 RL 问题的另一种方法 (*在我最初的写作中，我使用了“一个不错的替代方案”这个短语；[Seita](https://danieltakeshi.github.io/) 指出了这篇 [讨论](https://www.reddit.com/r/MachineLearning/comments/6gke6a/d_requesting_openai_to_justify_the_grandiose/dir9wde/)，因此我更新了我的措辞。*)。它具有一些良好的特性 (Salimans et al., 2017)，使其训练快速且容易：

> ES, as a black-box optimization algorithm, is another approach to RL problems (*In my original writing, I used the phrase “a nice alternative”; [Seita](https://danieltakeshi.github.io/) pointed me to this [discussion](https://www.reddit.com/r/MachineLearning/comments/6gke6a/d_requesting_openai_to_justify_the_grandiose/dir9wde/) and thus I updated my wording.*). It has a couple of good characteristics (Salimans et al., 2017) keeping it fast and easy to train:

- ES 不需要值函数近似；
- ES 不执行梯度反向传播；
- ES 对延迟或长期奖励是不变的；
- ES 具有高度并行性，且数据通信量极少。

> • ES does not need value function approximation;
> • ES does not perform gradient back-propagation;
> • ES is invariant to delayed or long-term rewards;
> • ES is highly parallelizable with very little data communication.

### 已知问题

> Known Problems

#### 探索-利用困境

> Exploration-Exploitation Dilemma

探索与利用困境的问题已在我之前的[文章](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#exploitation-vs-exploration)中讨论过。当强化学习问题面临未知环境时，这个问题对于找到一个好的解决方案尤为关键：没有足够的探索，我们无法充分了解环境；没有足够的利用，我们无法完成我们的奖励优化任务。

> The problem of exploration vs exploitation dilemma has been discussed in my previous [post](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#exploitation-vs-exploration). When the RL problem faces an unknown environment, this issue is especially a key to finding a good solution: without enough exploration, we cannot learn the environment well enough; without enough exploitation, we cannot complete our reward optimization task.

不同的强化学习算法以不同的方式平衡探索和利用。在[蒙特卡洛](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#monte-carlo-methods)方法、[Q学习](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control)或许多同策略算法中，探索通常通过[ε-贪婪](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm)实现；在[ES](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#evolution-strategies)中，探索通过策略参数扰动来体现。在开发新的强化学习算法时，请将此考虑在内。

> Different RL algorithms balance between exploration and exploitation in different ways. In [MC](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#monte-carlo-methods) methods, [Q-learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control) or many on-policy algorithms, the exploration is commonly implemented by [ε-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm); In [ES](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#evolution-strategies), the exploration is captured by the policy parameter perturbation. Please keep this into consideration when developing a new RL algorithm.

#### 致命三元组问题

> Deadly Triad Issue

我们确实追求涉及自举的 TD 方法的效率和灵活性。然而，当离策略、非线性函数逼近和自举结合在一个强化学习算法中时，训练可能会不稳定且难以收敛。这个问题被称为**致命三元组**（Sutton & Barto, 2017）。许多使用深度学习模型的架构被提出以解决这个问题，包括 DQN 通过经验回放和偶尔冻结目标网络来稳定训练。

> We do seek the efficiency and flexibility of TD methods that involve bootstrapping. However, when off-policy, nonlinear function approximation, and bootstrapping are combined in one RL algorithm, the training could be unstable and hard to converge. This issue is known as the **deadly triad** (Sutton & Barto, 2017). Many architectures using deep learning models were proposed to resolve the problem, including DQN to stabilize the training with experience replay and occasionally frozen target network.

### 案例研究：AlphaGo Zero

> Case Study: AlphaGo Zero

[围棋](https://en.wikipedia.org/wiki/Go_(game))游戏在人工智能领域几十年来一直是一个极其困难的问题，直到最近几年才有所突破。AlphaGo 和 AlphaGo Zero 是 DeepMind 团队开发的两个程序。两者都涉及深度卷积神经网络（[CNN](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#cnn-for-image-classification)）和蒙特卡洛树搜索（MCTS），并且都被证实达到了专业人类围棋选手的水平。与 AlphaGo 依赖专家人类棋谱的监督学习不同，AlphaGo Zero 仅使用强化学习和自我对弈，除了基本规则外不依赖任何人类知识。

> The game of [Go](https://en.wikipedia.org/wiki/Go_(game)) has been an extremely hard problem in the field of Artificial Intelligence for decades until recent years. AlphaGo and AlphaGo Zero are two programs developed by a team at DeepMind. Both involve deep Convolutional Neural Networks ([CNN](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#cnn-for-image-classification)) and Monte Carlo Tree Search (MCTS) and both have been approved to achieve the level of professional human Go players. Different from AlphaGo that relied on supervised learning from expert human moves, AlphaGo Zero used only reinforcement learning and self-play without human knowledge beyond the basic rules.

![The board of Go. Two players play black and white stones alternatively on the vacant intersections of a board with 19 x 19 lines. A group of stones must have at least one open point (an intersection, called a "liberty") to remain on the board and must have at least two or more enclosed liberties (called "eyes") to stay "alive". No stone shall repeat a previous position.](https://lilianweng.github.io/posts/2018-02-19-rl-overview/go_config.png)

有了上述所有强化学习知识，让我们来看看 AlphaGo Zero 是如何工作的。主要组件是一个作用于棋盘配置的深度[CNN](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#cnn-for-image-classification)（确切地说，是一个带有批量归一化和 ReLU 的[ResNet](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#resnet-he-et-al-2015)）。该网络输出两个值：

> With all the knowledge of RL above, let’s take a look at how AlphaGo Zero works. The main component is a deep [CNN](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#cnn-for-image-classification) over the game board configuration (precisely, a [ResNet](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#resnet-he-et-al-2015) with batch normalization and ReLU). This network outputs two values:

$$
(p, v) = f_\theta(s)
$$

• $s$：棋盘配置，19 x 19 x 17 堆叠特征平面；每个位置有 17 个特征，其中 8 个是当前玩家的过去配置（包括当前配置）+ 8 个是对手的过去配置 + 1 个特征指示颜色（1=黑，0=白）。我们需要专门编码颜色，因为网络正在与自身对弈，并且当前玩家和对手的颜色在步骤之间会切换。

• $p$：在 19^2 + 1 个候选（棋盘上的 19^2 个位置，加上弃权）中选择一个动作的概率。

• $v$：给定当前设置的获胜概率。

英文原文：

• $s$: the game board configuration, 19 x 19 x 17 stacked feature planes; 17 features for each position, 8 past configurations (including current) for the current player + 8 past configurations for the opponent + 1 feature indicating the color (1=black, 0=white). We need to code the color specifically because the network is playing with itself and the colors of current player and opponents are switching between steps.

• $p$: the probability of selecting a move over 19^2 + 1 candidates (19^2 positions on the board, in addition to passing).

• $v$: the winning probability given the current setting.

在自我对弈期间，MCTS 进一步改进动作概率分布$\pi \sim p(.)$，然后从这个改进的策略中采样动作$a_t$。奖励$z_t$是一个二进制值，表示当前玩家*最终*是否赢得比赛。每一步都会生成一个回合元组$(s_t, \pi_t, z_t)$，并将其保存到回放记忆中。本文为节省篇幅跳过了 MCTS 的细节；如果您感兴趣，请阅读原始[论文](https://www.dropbox.com/s/yva172qos2u15hf/2017-silver.pdf?dl=0)。

> During self-play, MCTS further improves the action probability distribution $\pi \sim p(.)$ and then the action $a_t$ is sampled from this improved policy. The reward $z_t$ is a binary value indicating whether the current player *eventually* wins the game. Each move generates an episode tuple $(s_t, \pi_t, z_t)$ and it is saved into the replay memory. The details on MCTS are skipped for the sake of space in this post; please read the original [paper](https://www.dropbox.com/s/yva172qos2u15hf/2017-silver.pdf?dl=0) if you are interested.

![AlphaGo Zero is trained by self-play while MCTS improves the output policy further in every step. (Image source: Figure 1a in Silver et al., 2017).](https://lilianweng.github.io/posts/2018-02-19-rl-overview/alphago-zero-selfplay.png)

网络使用回放记忆中的样本进行训练，以最小化损失：

> The network is trained with the samples in the replay memory to minimize the loss:

$$
\mathcal{L} = (z - v)^2 - \pi^\top \log p + c \| \theta \|^2
$$

其中$c$是一个超参数，用于控制 L2 惩罚的强度以避免过拟合。

> where $c$ is a hyperparameter controlling the intensity of L2 penalty to avoid overfitting.

AlphaGo Zero 通过移除监督学习并将分离的策略网络和价值网络合并为一个，从而简化了 AlphaGo。结果表明，AlphaGo Zero 在更短的训练时间内取得了大幅提升的性能！我强烈建议并排阅读这[两篇](https://pdfs.semanticscholar.org/1740/eb993cc8ca81f1e46ddaadce1f917e8000b5.pdf)[论文](https://www.dropbox.com/s/yva172qos2u15hf/2017-silver.pdf?dl=0)并比较它们之间的差异，非常有趣。

> AlphaGo Zero simplified AlphaGo by removing supervised learning and merging separated policy and value networks into one. It turns out that AlphaGo Zero achieved largely improved performance with a much shorter training time! I strongly recommend reading these [two](https://pdfs.semanticscholar.org/1740/eb993cc8ca81f1e46ddaadce1f917e8000b5.pdf) [papers](https://www.dropbox.com/s/yva172qos2u15hf/2017-silver.pdf?dl=0) side by side and compare the difference, super fun.

我知道这是一篇很长的文章，但希望它值得一读。*如果您发现本文中的错误，请随时通过 [lilian dot wengweng at gmail dot com] 与我联系。*下篇文章再见！:)

> I know this is a long read, but hopefully worth it. *If you notice mistakes and errors in this post, don’t hesitate to contact me at [lilian dot wengweng at gmail dot com].* See you in the next post! :)

引用方式：

> Cited as:

```
@article{weng2018bandit,
  title   = "A (Long) Peek into Reinforcement Learning",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-02-19-rl-overview/"
}
```

### 参考文献

> References

[1] Yuxi Li. [深度强化学习：概述。](https://arxiv.org/pdf/1701.07274.pdf) arXiv preprint arXiv:1701.07274. 2017.

> [1] Yuxi Li. [Deep reinforcement learning: An overview.](https://arxiv.org/pdf/1701.07274.pdf) arXiv preprint arXiv:1701.07274. 2017.

[2] Richard S. Sutton and Andrew G. Barto. [强化学习：导论；2nd Edition](http://incompleteideas.net/book/bookdraft2017nov5.pdf). 2017.

> [2] Richard S. Sutton and Andrew G. Barto. [Reinforcement Learning: An Introduction; 2nd Edition](http://incompleteideas.net/book/bookdraft2017nov5.pdf). 2017.

[3] Volodymyr Mnih, et al. [深度强化学习的异步方法。](http://proceedings.mlr.press/v48/mniha16.pdf) ICML. 2016.

> [3] Volodymyr Mnih, et al. [Asynchronous methods for deep reinforcement learning.](http://proceedings.mlr.press/v48/mniha16.pdf) ICML. 2016.

[4] Tim Salimans, et al. [演化策略作为强化学习的可扩展替代方案。](https://arxiv.org/pdf/1703.03864.pdf) arXiv preprint arXiv:1703.03864 (2017).

> [4] Tim Salimans, et al. [Evolution strategies as a scalable alternative to reinforcement learning.](https://arxiv.org/pdf/1703.03864.pdf) arXiv preprint arXiv:1703.03864 (2017).

[5] David Silver, et al. [在没有人类知识的情况下掌握围棋游戏](https://www.dropbox.com/s/yva172qos2u15hf/2017-silver.pdf?dl=0). Nature 550.7676 (2017): 354.

> [5] David Silver, et al. [Mastering the game of go without human knowledge](https://www.dropbox.com/s/yva172qos2u15hf/2017-silver.pdf?dl=0). Nature 550.7676 (2017): 354.

[6] David Silver, et al. [使用深度神经网络和树搜索掌握围棋游戏。](https://pdfs.semanticscholar.org/1740/eb993cc8ca81f1e46ddaadce1f917e8000b5.pdf) Nature 529.7587 (2016): 484-489.

> [6] David Silver, et al. [Mastering the game of Go with deep neural networks and tree search.](https://pdfs.semanticscholar.org/1740/eb993cc8ca81f1e46ddaadce1f917e8000b5.pdf) Nature 529.7587 (2016): 484-489.

[7] Volodymyr Mnih, et al. [通过深度强化学习实现人类水平的控制。](https://www.cs.swarthmore.edu/~meeden/cs63/s15/nature15b.pdf) Nature 518.7540 (2015): 529.

> [7] Volodymyr Mnih, et al. [Human-level control through deep reinforcement learning.](https://www.cs.swarthmore.edu/~meeden/cs63/s15/nature15b.pdf) Nature 518.7540 (2015): 529.

[8] Ziyu Wang, et al. [深度强化学习的对偶网络架构。](https://arxiv.org/pdf/1511.06581.pdf) ICML. 2016.

> [8] Ziyu Wang, et al. [Dueling network architectures for deep reinforcement learning.](https://arxiv.org/pdf/1511.06581.pdf) ICML. 2016.

[9] [强化学习讲座](https://www.youtube.com/playlist?list=PL7-jPKtc4r78-wCZcQn5IqyuWhBZ8fOxT) by David Silver on YouTube.

> [9] [Reinforcement Learning lectures](https://www.youtube.com/playlist?list=PL7-jPKtc4r78-wCZcQn5IqyuWhBZ8fOxT) by David Silver on YouTube.

[10] OpenAI Blog: [演化策略作为强化学习的可扩展替代方案](https://blog.openai.com/evolution-strategies/)

> [10] OpenAI Blog: [Evolution Strategies as a Scalable Alternative to Reinforcement Learning](https://blog.openai.com/evolution-strategies/)

[11] Frank Sehnke, et al. [参数探索策略梯度。](https://mediatum.ub.tum.de/doc/1287490/file.pdf) Neural Networks 23.4 (2010): 551-559.

> [11] Frank Sehnke, et al. [Parameter-exploring policy gradients.](https://mediatum.ub.tum.de/doc/1287490/file.pdf) Neural Networks 23.4 (2010): 551-559.

[12] Csaba Szepesvári. [强化学习算法。](https://sites.ualberta.ca/~szepesva/papers/RLAlgsInMDPs.pdf) 1st Edition. Synthesis lectures on artificial intelligence and machine learning 4.1 (2010): 1-103.

> [12] Csaba Szepesvári. [Algorithms for reinforcement learning.](https://sites.ualberta.ca/~szepesva/papers/RLAlgsInMDPs.pdf) 1st Edition. Synthesis lectures on artificial intelligence and machine learning 4.1 (2010): 1-103.

*如果您发现本文中的错误，请随时通过 [lilian dot wengweng at gmail dot com] 与我联系，我将非常乐意立即纠正它们！*

> *If you notice mistakes and errors in this post, please don’t hesitate to contact me at [lilian dot wengweng at gmail dot com] and I would be super happy to correct them right away!*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Reinforcement Learning (RL) | 强化学习 | 一种机器学习范式，智能体通过与环境交互学习最优行为策略以最大化累积奖励。 |
| Agent | 智能体 | 在环境中行动并学习的实体。 |
| Environment | 环境 | 智能体与之交互的外部世界，对智能体的行动做出反应并提供奖励。 |
| Policy | 策略 | 智能体在给定状态下选择动作的规则或函数。 |
| Value Function | 价值函数 | 衡量一个状态或状态-动作对的长期好坏程度，预测未来预期回报。 |
| Markov Decision Process (MDP) | 马尔可夫决策过程 | 强化学习问题的数学框架，具有马尔可夫性质。 |
| Bellman Equation | 贝尔曼方程 | 一组将价值函数分解为即时奖励和折扣未来价值的递归方程。 |
| Temporal Difference (TD) Learning | 时序差分学习 | 无模型强化学习方法，通过自举从不完整经验片段中学习。 |
| Q-learning | Q学习 | 一种异策略时序差分控制算法，用于学习最优动作价值函数。 |
| Deep Q-Network (DQN) | 深度Q网络 | 将Q学习与深度神经网络结合，通过经验回放和目标网络稳定训练。 |
| Policy Gradient | 策略梯度 | 直接学习参数化策略的强化学习方法，通过梯度上升最大化预期回报。 |
| Actor-Critic | Actor-Critic | 结合了策略学习（Actor）和价值函数学习（Critic）的强化学习架构。 |
| Exploration-Exploitation Dilemma | 探索-利用困境 | 强化学习中选择尝试新动作（探索）还是利用已知最佳动作（利用）的权衡问题。 |
| Bootstrapping | 自举 | 时序差分学习中，使用现有估计来更新目标估计的方法。 |
| Evolution Strategies (ES) | 演化策略 | 一种模型无关的黑盒优化算法，通过模仿自然选择来学习策略参数。 |
