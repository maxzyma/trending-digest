# 策略梯度算法

> Policy Gradient Algorithms

> 来源：Lil'Log / Lilian Weng，2018-04-08
> 原文链接：https://lilianweng.github.io/posts/2018-04-08-policy-gradient/
> 分类：强化学习 / 策略梯度

## 核心要点

- 策略梯度方法通过直接建模和优化参数化策略函数，旨在为智能体找到最优行为策略以获得最优奖励，其核心在于策略梯度定理简化了梯度计算。
- REINFORCE作为蒙特卡洛策略梯度方法，利用回合样本更新策略，但其高方差促使Actor-Critic方法通过引入价值函数来辅助策略更新并降低方差。
- 离策略策略梯度方法通过重要性采样和经验回放，实现了样本重用和更好的探索，从而提高了学习效率。
- A3C和A2C是异步和同步的Actor-Critic算法，通过并行训练或协调更新来提高训练效率和稳定性。
- 确定性策略梯度（DPG）将策略建模为确定性决策，DDPG在此基础上结合DQN的稳定技术，将其扩展到连续动作空间。
- TRPO和PPO通过对策略更新施加KL散度约束或使用裁剪替代目标，旨在提高训练稳定性并防止策略过度改变。
- SAC是一种离策略Actor-Critic模型，通过最大化策略熵来鼓励探索和稳定性，而TD3则通过多项改进解决了DDPG中价值函数过高估计的问题。
- IMPALA框架通过解耦行动与学习并利用V-trace离策略校正，实现了高吞吐量的分布式深度强化学习。
- PPG通过独立的策略和价值函数训练阶段，修改了传统的Actor-Critic算法，显著提升了样本效率。

## 正文

[2018-06-30 更新：新增两种策略梯度方法，[SAC](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#sac) 和 [D4PG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#d4pg)。]
  

[2018-09-30 更新：新增一种策略梯度方法，[TD3](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#td3)。]
  

[2019-02-09 更新：新增[带自动调整温度的SAC](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#sac-with-automatically-adjusted-temperature)。]
  

[2019-06-26 更新：感谢 Chanseok，本文现已推出[韩语](https://talkingaboutme.tistory.com/entry/RL-Policy-Gradient-Algorithms)版本。]
  

[2019-09-12 更新：新增一种策略梯度方法 [SVPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#svpg)。]
  

[2019-12-22 更新：新增一种策略梯度方法 [IMPALA](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#impala)。]
  

[2020-10-15 更新：新增一种策略梯度方法 [PPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppg) 及 [PPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo) 中的一些新讨论。]
  

[2021-09-19 更新：感谢 Wenhao 和 爱吃猫的鱼，本文现已推出[中文1](https://tomaxent.com/2019/04/14/%E7%AD%96%E7%95%A5%E6%A2%AF%E5%BA%A6%E6%96%B9%E6%B3%95/)和[中文2](https://paperexplained.cn/articles/article/detail/31/)版本。]

> [Updated on 2018-06-30: add two new policy gradient methods, [SAC](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#sac) and [D4PG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#d4pg).]
>
>
> [Updated on 2018-09-30: add a new policy gradient method, [TD3](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#td3).]
>
>
> [Updated on 2019-02-09: add [SAC with automatically adjusted temperature](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#sac-with-automatically-adjusted-temperature)].
>
>
> [Updated on 2019-06-26: Thanks to Chanseok, we have a version of this post in [Korean](https://talkingaboutme.tistory.com/entry/RL-Policy-Gradient-Algorithms)].
>
>
> [Updated on 2019-09-12: add a new policy gradient method [SVPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#svpg).]
>
>
> [Updated on 2019-12-22: add a new policy gradient method [IMPALA](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#impala).]
>
>
> [Updated on 2020-10-15: add a new policy gradient method [PPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppg) & some new discussion in [PPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo).]
>
>
> [Updated on 2021-09-19: Thanks to Wenhao & 爱吃猫的鱼, we have this post in [Chinese1](https://tomaxent.com/2019/04/14/%E7%AD%96%E7%95%A5%E6%A2%AF%E5%BA%A6%E6%96%B9%E6%B3%95/) & [Chinese2](https://paperexplained.cn/articles/article/detail/31/)].

### 什么是策略梯度

> What is Policy Gradient

策略梯度是一种解决强化学习问题的方法。如果你还没有接触过强化学习领域，请先阅读[“强化学习（长篇）一瞥 » 关键概念”](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#key-concepts)一节，了解问题定义和关键概念。

> Policy gradient is an approach to solve reinforcement learning problems. If you haven’t looked into the field of reinforcement learning, please first read the section [“A (Long) Peek into Reinforcement Learning » Key Concepts”](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#key-concepts) for the problem definition and key concepts.

#### 符号

> Notations

以下是符号列表，可帮助您轻松阅读本文中的公式。

> Here is a list of notations to help you read through equations in the post easily.

| 符号 | 含义 |
| --- | --- |
| $s \in \mathcal{S}$ | 状态。 |
| $a \in \mathcal{A}$ | 动作。 |
| $r \in \mathcal{R}$ | 奖励。 |
| $S_t, A_t, R_t$ | 一个轨迹在时间步 $t$ 的状态、动作和奖励。我偶尔也会使用 $s_t, a_t, r_t$。 |
| $\gamma$ | 折扣因子；对未来奖励不确定性的惩罚；$0<\gamma \leq 1$。 |
| $G_t$ | 回报；或折扣未来奖励；$G_t = \sum_{k=0}^{\infty} \gamma^k R_{t+k+1}$。 |
| $P(s’, r \vert s, a)$ | 从当前状态 $s$ 采取动作 $a$ 并获得奖励 $r$ 到达下一个状态 $s’$ 的转移概率。 |
| $\pi(a \vert s)$ | 随机策略（智能体行为策略）；$\pi_\theta(.)$ 是由 $\theta$ 参数化的策略。 |
| $\mu(s)$ | 确定性策略；我们也可以将其标记为 $\pi(s)$，但使用不同的字母可以更好地进行区分，这样我们无需进一步解释就能轻易判断策略是随机的还是确定性的。强化学习算法旨在学习 $\pi$ 或 $\mu$。 |
| $V(s)$ | 状态值函数衡量状态 $s$ 的预期回报；$V_w(.)$ 是由 $w$ 参数化的值函数。 |
| $V^\pi(s)$ | 当我们遵循策略 $\pi$ 时状态 $s$ 的值；$V^\pi (s) = \mathbb{E}_{a\sim \pi} [G_t \vert S_t = s]$。 |
| $Q(s, a)$ | 动作值函数类似于 $V(s)$，但它评估状态和动作对 $(s, a)$ 的预期回报；$Q_w(.)$ 是由 $w$ 参数化的动作值函数。 |
| $Q^\pi(s, a)$ | 类似于 $V^\pi(.)$，当我们遵循策略 $\pi$ 时（状态，动作）对的值；$Q^\pi(s, a) = \mathbb{E}_{a\sim \pi} [G_t \vert S_t = s, A_t = a]$。 |
| $A(s, a)$ | 优势函数，$A(s, a) = Q(s, a) - V(s)$；通过将状态值作为基线，它可以被认为是 Q 值的一个方差更低的版本。 |

> 英文原表 / English original

| Symbol | Meaning |
| --- | --- |
| $s \in \mathcal{S}$ | States. |
| $a \in \mathcal{A}$ | Actions. |
| $r \in \mathcal{R}$ | Rewards. |
| $S_t, A_t, R_t$ | State, action, and reward at time step $t$ of one trajectory. I may occasionally use $s_t, a_t, r_t$ as well. |
| $\gamma$ | Discount factor; penalty to uncertainty of future rewards; $0<\gamma \leq 1$. |
| $G_t$ | Return; or discounted future reward; $G_t = \sum_{k=0}^{\infty} \gamma^k R_{t+k+1}$. |
| $P(s’, r \vert s, a)$ | Transition probability of getting to the next state $s’$ from the current state $s$ with action $a$ and reward $r$. |
| $\pi(a \vert s)$ | Stochastic policy (agent behavior strategy); $\pi_\theta(.)$ is a policy parameterized by $\theta$. |
| $\mu(s)$ | Deterministic policy; we can also label this as $\pi(s)$, but using a different letter gives better distinction so that we can easily tell when the policy is stochastic or deterministic without further explanation. Either $\pi$ or $\mu$ is what a reinforcement learning algorithm aims to learn. |
| $V(s)$ | State-value function measures the expected return of state $s$; $V_w(.)$ is a value function parameterized by $w$. |
| $V^\pi(s)$ | The value of state $s$ when we follow a policy $\pi$; $V^\pi (s) = \mathbb{E}_{a\sim \pi} [G_t \vert S_t = s]$. |
| $Q(s, a)$ | Action-value function is similar to $V(s)$, but it assesses the expected return of a pair of state and action $(s, a)$; $Q_w(.)$ is a action value function parameterized by $w$. |
| $Q^\pi(s, a)$ | Similar to $V^\pi(.)$, the value of (state, action) pair when we follow a policy $\pi$; $Q^\pi(s, a) = \mathbb{E}_{a\sim \pi} [G_t \vert S_t = s, A_t = a]$. |
| $A(s, a)$ | Advantage function, $A(s, a) = Q(s, a) - V(s)$; it can be considered as another version of Q-value with lower variance by taking the state-value off as the baseline. |

#### 策略梯度

> Policy Gradient

强化学习的目标是为智能体找到一个最优行为策略以获得最优奖励。**策略梯度**方法旨在直接建模和优化策略。策略通常用一个关于 `\theta`, $\pi_\theta(a \vert s)$ 的参数化函数来建模。奖励（目标）函数的值取决于此策略，然后可以应用各种算法来优化 `\theta` 以获得最佳奖励。

英文原文：The goal of reinforcement learning is to find an optimal behavior strategy for the agent to obtain optimal rewards. The policy gradient methods target at modeling and optimizing the policy directly. The policy is usually modeled with a parameterized function respect to `\theta`, 

$\pi_\theta(a \vert s)$. The value of the reward (objective) function depends on this policy and then various algorithms can be applied to optimize `\theta` for the best reward.

奖励函数定义为：

> The reward function is defined as:

$$
J(\theta) 
= \sum_{s \in \mathcal{S}} d^\pi(s) V^\pi(s) 
= \sum_{s \in \mathcal{S}} d^\pi(s) \sum_{a \in \mathcal{A}} \pi_\theta(a \vert s) Q^\pi(s, a)
$$

其中$d^\pi(s)$是马尔可夫链的平稳分布，对应于$\pi_\theta$（在$\pi$下的在策略状态分布）。为简化起见，参数$\theta$将为策略$\pi_\theta$而省略，当该策略出现在其他函数的下标中时；例如，$d^{\pi}$和$Q^\pi$应为$d^{\pi_\theta}$和$Q^{\pi_\theta}$如果完整书写的话。

> where $d^\pi(s)$ is the stationary distribution of Markov chain for $\pi_\theta$ (on-policy state distribution under $\pi$). For simplicity, the parameter $\theta$ would be omitted for the policy $\pi_\theta$ when the policy is present in the subscript of other functions; for example, $d^{\pi}$ and $Q^\pi$ should be $d^{\pi_\theta}$ and $Q^{\pi_\theta}$ if written in full.

想象你可以沿着马尔可夫链的状态永远旅行，最终，随着时间的推移，你最终处于某个状态的概率保持不变——这就是$\pi_\theta$。$d^\pi(s) = \lim_{t \to \infty} P(s_t = s \vert s_0, \pi_\theta)$是概率，即$s_t=s$当从$s_0$并遵循策略$\pi_\theta$持续 t 步。实际上，马尔可夫链平稳分布的存在是 PageRank 算法有效的一个主要原因。如果你想了解更多，请查看[此处](https://jeremykun.com/2015/04/06/markov-chain-monte-carlo-without-all-the-bullshit/)。

> Imagine that you can travel along the Markov chain’s states forever, and eventually, as the time progresses, the probability of you ending up with one state becomes unchanged — this is the stationary probability for $\pi_\theta$. $d^\pi(s) = \lim_{t \to \infty} P(s_t = s \vert s_0, \pi_\theta)$ is the probability that $s_t=s$ when starting from $s_0$ and following policy $\pi_\theta$ for t steps. Actually, the existence of the stationary distribution of Markov chain is one main reason for why PageRank algorithm works. If you want to read more, check [this](https://jeremykun.com/2015/04/06/markov-chain-monte-carlo-without-all-the-bullshit/).

自然地，人们会认为基于策略的方法在连续空间中更有用。因为在连续空间中，需要估计无限数量的动作和（或）状态的值，因此基于值的方法在计算上过于昂贵。例如，在 [广义策略迭代](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#policy-iteration) 中，策略改进步骤 $\arg\max_{a \in \mathcal{A}} Q^\pi(s, a)$ 需要对动作空间进行全面扫描，从而受到 [维度灾难](https://en.wikipedia.org/wiki/Curse_of_dimensionality) 的影响。

> It is natural to expect policy-based methods are more useful in the continuous space. Because there is an infinite number of actions and (or) states to estimate the values for and hence value-based approaches are way too expensive computationally in the continuous space. For example, in [generalized policy iteration](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#policy-iteration), the policy improvement step $\arg\max_{a \in \mathcal{A}} Q^\pi(s, a)$ requires a full scan of the action space, suffering from the [curse of dimensionality](https://en.wikipedia.org/wiki/Curse_of_dimensionality).

使用 *梯度上升*，我们可以将 $\theta$ 朝着梯度 $\nabla_\theta J(\theta)$ 所指示的方向移动，以找到能产生最高回报的 $\theta$ 的最佳 $\pi_\theta$。

> Using *gradient ascent*, we can move $\theta$ toward the direction suggested by the gradient $\nabla_\theta J(\theta)$ to find the best $\theta$ for $\pi_\theta$ that produces the highest return.

#### 策略梯度定理

> Policy Gradient Theorem

计算梯度$\nabla_\theta J(\theta)$很棘手，因为它既取决于动作选择（由$\pi_\theta$直接决定），也取决于遵循目标选择行为的状态的平稳分布（由$\pi_\theta$间接决定）。鉴于环境通常是未知的，因此很难估计策略更新对状态分布的影响。

> Computing the gradient $\nabla_\theta J(\theta)$ is tricky because it depends on both the action selection (directly determined by $\pi_\theta$) and the stationary distribution of states following the target selection behavior (indirectly determined by $\pi_\theta$). Given that the environment is generally unknown, it is difficult to estimate the effect on the state distribution by a policy update.

幸运的是，**策略梯度定理**来拯救世界了！太棒了！它提供了一种很好的目标函数导数重构，使其不涉及状态分布的导数$d^\pi(.)$，并大大简化了梯度计算$\nabla_\theta J(\theta)$。

英文原文：Luckily, the policy gradient theorem comes to save the world! Woohoo! It provides a nice reformation of the derivative of the objective function to not involve the derivative of the state distribution 

$d^\pi(.)$ and simplify the gradient computation 

$\nabla_\theta J(\theta)$ a lot.

$$
\begin{aligned}
\nabla_\theta J(\theta) 
&= \nabla_\theta \sum_{s \in \mathcal{S}} d^\pi(s) \sum_{a \in \mathcal{A}} Q^\pi(s, a) \pi_\theta(a \vert s) \\
&\propto \sum_{s \in \mathcal{S}} d^\pi(s) \sum_{a \in \mathcal{A}} Q^\pi(s, a) \nabla_\theta \pi_\theta(a \vert s) 
\end{aligned}
$$

#### 策略梯度定理的证明

> Proof of Policy Gradient Theorem

本节内容相当密集，因为是时候我们来回顾证明（[Sutton & Barto, 2017](http://incompleteideas.net/book/bookdraft2017nov5.pdf)；第13.1节），并弄清楚为什么策略梯度定理是正确的了。

> This session is pretty dense, as it is the time for us to go through the proof ([Sutton & Barto, 2017](http://incompleteideas.net/book/bookdraft2017nov5.pdf); Sec. 13.1) and figure out why the policy gradient theorem is correct.

我们首先从状态值函数的导数开始：

> We first start with the derivative of the state value function:

$$
\begin{aligned}
& \nabla_\theta V^\pi(s) \\
=& \nabla_\theta \Big(\sum_{a \in \mathcal{A}} \pi_\theta(a \vert s)Q^\pi(s, a) \Big) & \\
=& \sum_{a \in \mathcal{A}} \Big( \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a) + \pi_\theta(a \vert s) \color{red}{\nabla_\theta Q^\pi(s, a)} \Big) & \scriptstyle{\text{; Derivative product rule.}} \\
=& \sum_{a \in \mathcal{A}} \Big( \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a) + \pi_\theta(a \vert s) \color{red}{\nabla_\theta \sum_{s', r} P(s',r \vert s,a)(r + V^\pi(s'))} \Big) & \scriptstyle{\text{; Extend } Q^\pi \text{ with future state value.}} \\
=& \sum_{a \in \mathcal{A}} \Big( \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a) + \pi_\theta(a \vert s) \color{red}{\sum_{s', r} P(s',r \vert s,a) \nabla_\theta V^\pi(s')} \Big) & \scriptstyle{P(s',r \vert s,a) \text{ or } r \text{ is not a func of }\theta}\\
=& \sum_{a \in \mathcal{A}} \Big( \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a) + \pi_\theta(a \vert s) \color{red}{\sum_{s'} P(s' \vert s,a) \nabla_\theta V^\pi(s')} \Big) & \scriptstyle{\text{; Because }  P(s' \vert s, a) = \sum_r P(s', r \vert s, a)}
\end{aligned}
$$

现在我们有：

> Now we have:

$$
\color{red}{\nabla_\theta V^\pi(s)} 
= \sum_{a \in \mathcal{A}} \Big( \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a) + \pi_\theta(a \vert s) \sum_{s'} P(s' \vert s,a) \color{red}{\nabla_\theta V^\pi(s')} \Big)
$$

这个方程有一个很好的递归形式（参见红色部分！），并且未来状态值函数$V^\pi(s’)$可以通过遵循相同的方程重复展开。

> This equation has a nice recursive form (see the red parts!) and the future state value function $V^\pi(s’)$ can be repeated unrolled by following the same equation.

让我们考虑以下访问序列，并将通过策略$\pi_\theta$在k步后从状态s转移到状态x的概率标记为$\rho^\pi(s \to x, k)$。

> Let’s consider the following visitation sequence and label the probability of transitioning from state s to state x with policy $\pi_\theta$ after k step as $\rho^\pi(s \to x, k)$.

$$
s \xrightarrow[ ]{a \sim \pi_\theta(.\vert s)} s' \xrightarrow[ ]{a \sim \pi_\theta(.\vert s')} s'' \xrightarrow[ ]{a \sim \pi_\theta(.\vert s'')} \dots
$$

• 当 k = 0 时：$\rho^\pi(s \to s, k=0) = 1$。

• 当 k = 1 时，我们遍历所有可能的动作，并汇总到目标状态的转移概率：$\rho^\pi(s \to s’, k=1) = \sum_a \pi_\theta(a \vert s) P(s’ \vert s, a)$。

• 想象一下，目标是在遵循策略$\pi_\theta$的情况下，在k+1步后从状态s到达x。我们可以首先在k步后从s到达一个中间点s'（任何状态都可以是中间点，$s’ \in \mathcal{S}$），然后在最后一步到达最终状态x。通过这种方式，我们能够递归地更新访问概率：$\rho^\pi(s \to x, k+1) = \sum_{s’} \rho^\pi(s \to s’, k) \rho^\pi(s’ \to x, 1)$。

英文原文：

• When k = 0: $\rho^\pi(s \to s, k=0) = 1$.

• When k = 1, we scan through all possible actions and sum up the transition probabilities to the target state: $\rho^\pi(s \to s’, k=1) = \sum_a \pi_\theta(a \vert s) P(s’ \vert s, a)$.

• Imagine that the goal is to go from state s to x after k+1 steps while following policy $\pi_\theta$. We can first travel from s to a middle point s’ (any state can be a middle point, $s’ \in \mathcal{S}$) after k steps and then go to the final state x during the last step. In this way, we are able to update the visitation probability recursively: $\rho^\pi(s \to x, k+1) = \sum_{s’} \rho^\pi(s \to s’, k) \rho^\pi(s’ \to x, 1)$.

然后我们回到展开$\nabla_\theta V^\pi(s)$的递归表示！让$\phi(s) = \sum_{a \in \mathcal{A}} \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a)$来简化数学。如果我们无限地扩展$\nabla_\theta V^\pi(.)$，很容易发现我们可以在这个展开过程中，在任意步数后从起始状态s转移到任何状态，并且通过汇总所有访问概率，我们得到$\nabla_\theta V^\pi(s)$！

> Then we go back to unroll the recursive representation of $\nabla_\theta V^\pi(s)$! Let $\phi(s) = \sum_{a \in \mathcal{A}} \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a)$ to simplify the maths. If we keep on extending $\nabla_\theta V^\pi(.)$ infinitely, it is easy to find out that we can transition from the starting state s to any state after any number of steps in this unrolling process and by summing up all the visitation probabilities, we get $\nabla_\theta V^\pi(s)$!

$$
\begin{aligned}
& \color{red}{\nabla_\theta V^\pi(s)} \\
=& \phi(s) + \sum_a \pi_\theta(a \vert s) \sum_{s'} P(s' \vert s,a) \color{red}{\nabla_\theta V^\pi(s')} \\
=& \phi(s) + \sum_{s'} \sum_a \pi_\theta(a \vert s) P(s' \vert s,a) \color{red}{\nabla_\theta V^\pi(s')} \\
=& \phi(s) + \sum_{s'} \rho^\pi(s \to s', 1) \color{red}{\nabla_\theta V^\pi(s')} \\
=& \phi(s) + \sum_{s'} \rho^\pi(s \to s', 1) \color{red}{\sum_{a \in \mathcal{A}} \Big( \nabla_\theta \pi_\theta(a \vert s')Q^\pi(s', a) + \pi_\theta(a \vert s') \sum_{s'} P(s'' \vert s',a) \nabla_\theta V^\pi(s'') \Big)} \\
=& \phi(s) + \sum_{s'} \rho^\pi(s \to s', 1) \color{red}{[ \phi(s') + \sum_{s''} \rho^\pi(s' \to s'', 1) \nabla_\theta V^\pi(s'')]} \\
=& \phi(s) + \sum_{s'} \rho^\pi(s \to s', 1) \phi(s') + \sum_{s''} \rho^\pi(s \to s'', 2)\color{red}{\nabla_\theta V^\pi(s'')} \scriptstyle{\text{ ; Consider }s'\text{ as the middle point for }s \to s''}\\
=& \phi(s) + \sum_{s'} \rho^\pi(s \to s', 1) \phi(s') + \sum_{s''} \rho^\pi(s \to s'', 2)\phi(s'') + \sum_{s'''} \rho^\pi(s \to s''', 3)\color{red}{\nabla_\theta V^\pi(s''')} \\
=& \dots \scriptstyle{\text{; Repeatedly unrolling the part of }\nabla_\theta V^\pi(.)} \\
=& \sum_{x\in\mathcal{S}}\sum_{k=0}^\infty \rho^\pi(s \to x, k) \phi(x)
\end{aligned}
$$

上述出色的重写使我们能够排除 Q 值函数的导数，$\nabla_\theta Q^\pi(s, a)$。通过将其代入目标函数 $J(\theta)$，我们得到以下结果：

> The nice rewriting above allows us to exclude the derivative of Q-value function, $\nabla_\theta Q^\pi(s, a)$. By plugging it into the objective function $J(\theta)$, we are getting the following:

$$
\begin{aligned}
\nabla_\theta J(\theta)
&= \nabla_\theta V^\pi(s_0) & \scriptstyle{\text{; Starting from a random state } s_0} \\
&= \sum_{s}\color{blue}{\sum_{k=0}^\infty \rho^\pi(s_0 \to s, k)} \phi(s) &\scriptstyle{\text{; Let }\color{blue}{\eta(s) = \sum_{k=0}^\infty \rho^\pi(s_0 \to s, k)}} \\
&= \sum_{s}\eta(s) \phi(s) & \\
&= \Big( {\sum_s \eta(s)} \Big)\sum_{s}\frac{\eta(s)}{\sum_s \eta(s)} \phi(s) & \scriptstyle{\text{; Normalize } \eta(s), s\in\mathcal{S} \text{ to be a probability distribution.}}\\
&\propto \sum_s \frac{\eta(s)}{\sum_s \eta(s)} \phi(s) & \scriptstyle{\sum_s \eta(s)\text{  is a constant}} \\
&= \sum_s d^\pi(s) \sum_a \nabla_\theta \pi_\theta(a \vert s)Q^\pi(s, a) & \scriptstyle{d^\pi(s) = \frac{\eta(s)}{\sum_s \eta(s)}\text{ is stationary distribution.}}
\end{aligned}
$$

在分幕式情况下，比例常数($\sum_s \eta(s)$)是一个幕的平均长度；在持续式情况下，它是 1 ([Sutton & Barto, 2017](http://incompleteideas.net/book/bookdraft2017nov5.pdf); 第 13.2 节)。梯度可以进一步写为：

> In the episodic case, the constant of proportionality ($\sum_s \eta(s)$) is the average length of an episode; in the continuing case, it is 1 ([Sutton & Barto, 2017](http://incompleteideas.net/book/bookdraft2017nov5.pdf); Sec. 13.2). The gradient can be further written as:

$$
\begin{aligned}
\nabla_\theta J(\theta) 
&\propto \sum_{s \in \mathcal{S}} d^\pi(s) \sum_{a \in \mathcal{A}} Q^\pi(s, a) \nabla_\theta \pi_\theta(a \vert s)  &\\
&= \sum_{s \in \mathcal{S}} d^\pi(s) \sum_{a \in \mathcal{A}} \pi_\theta(a \vert s) Q^\pi(s, a) \frac{\nabla_\theta \pi_\theta(a \vert s)}{\pi_\theta(a \vert s)} &\\
&= \mathbb{E}_\pi [Q^\pi(s, a) \nabla_\theta \ln \pi_\theta(a \vert s)] & \scriptstyle{\text{; Because } (\ln x)' = 1/x}
\end{aligned}
$$

其中 $\mathbb{E}_\pi$ 指代 $\mathbb{E}_{s \sim d_\pi, a \sim \pi_\theta}$，当状态和动作分布都遵循策略 $\pi_\theta$ 时（同策略）。

> Where $\mathbb{E}_\pi$ refers to $\mathbb{E}_{s \sim d_\pi, a \sim \pi_\theta}$ when both state and action distributions follow the policy $\pi_\theta$ (on policy).

策略梯度定理为各种策略梯度算法奠定了理论基础。这种原始策略梯度更新没有偏差但方差很高。许多后续算法被提出，旨在在保持偏差不变的情况下降低方差。

> The policy gradient theorem lays the theoretical foundation for various policy gradient algorithms. This vanilla policy gradient update has no bias but high variance. Many following algorithms were proposed to reduce the variance while keeping the bias unchanged.

$$
\nabla_\theta J(\theta)  = \mathbb{E}_\pi [Q^\pi(s, a) \nabla_\theta \ln \pi_\theta(a \vert s)]
$$

这里是策略梯度方法通用形式的一个很好的总结，它借鉴自[GAE](https://arxiv.org/pdf/1506.02438.pdf)（广义优势估计）论文（[Schulman 等人，2016](https://arxiv.org/abs/1506.02438)）以及这篇[文章](https://danieltakeshi.github.io/2017/04/02/notes-on-the-generalized-advantage-estimation-paper/)，它详细讨论了 GAE 中的几个组成部分，强烈推荐。

> Here is a nice summary of a general form of policy gradient methods borrowed from the [GAE](https://arxiv.org/pdf/1506.02438.pdf) (general advantage estimation) paper ([Schulman et al., 2016](https://arxiv.org/abs/1506.02438)) and this [post](https://danieltakeshi.github.io/2017/04/02/notes-on-the-generalized-advantage-estimation-paper/) thoroughly discussed several components in GAE , highly recommended.

![A general form of policy gradient methods. (Image source: Schulman et al., 2016 )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/general_form_policy_gradient.png)

### 策略梯度算法

> Policy Gradient Algorithms

近年来，已经提出了大量的策略梯度算法，我无法一一列举。我将介绍其中一些我恰好了解和阅读过的算法。

> Tons of policy gradient algorithms have been proposed during recent years and there is no way for me to exhaust them. I’m introducing some of them that I happened to know and read about.

#### REINFORCE

> REINFORCE

**REINFORCE**（蒙特卡洛策略梯度）依赖于通过[蒙特卡洛](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#monte-carlo-methods)方法使用回合样本估计的收益来更新策略参数`\theta`。REINFORCE之所以有效，是因为样本梯度的期望等于实际梯度：

英文原文：REINFORCE (Monte-Carlo policy gradient) relies on an estimated return by [Monte-Carlo](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#monte-carlo-methods) methods using episode samples to update the policy parameter `\theta`. REINFORCE works because the expectation of the sample gradient is equal to the actual gradient:

$$
\begin{aligned}
\nabla_\theta J(\theta)
&= \mathbb{E}_\pi [Q^\pi(s, a) \nabla_\theta \ln \pi_\theta(a \vert s)] & \\
&= \mathbb{E}_\pi [G_t \nabla_\theta \ln \pi_\theta(A_t \vert S_t)] & \scriptstyle{\text{; Because } Q^\pi(S_t, A_t) = \mathbb{E}_\pi[G_t \vert S_t, A_t]}
\end{aligned}
$$

因此，我们能够从真实的样本轨迹中测量$G_t$，并用它来更新我们的策略梯度。它依赖于完整的轨迹，这就是它是一种蒙特卡洛方法的原因。

> Therefore we are able to measure $G_t$ from real sample trajectories and use that to update our policy gradient. It relies on a full trajectory and that’s why it is a Monte-Carlo method.

这个过程非常简单：

> The process is pretty straightforward:

1\. 随机初始化策略参数$\theta$。

2\. 在策略$\pi_\theta$上生成一条轨迹：$S_1, A_1, R_2, S_2, A_2, \dots, S_T$。

3\. 对于 t=1, 2, … , T:\n\n

1\. 估计收益$G_t$；



2\. 更新策略参数：$\theta \leftarrow \theta + \alpha \gamma^t G_t \nabla_\theta \ln \pi_\theta(A_t \vert S_t)$

英文原文：

1\. Initialize the policy parameter $\theta$ at random.

2\. Generate one trajectory on policy $\pi_\theta$: $S_1, A_1, R_2, S_2, A_2, \dots, S_T$.

3\. For t=1, 2, … , T:



1\. Estimate the the return $G_t$;



2\. Update policy parameters: $\theta \leftarrow \theta + \alpha \gamma^t G_t \nabla_\theta \ln \pi_\theta(A_t \vert S_t)$

REINFORCE的一个广泛使用的变体是从收益$G_t$中减去一个基线值，以*在保持偏差不变的情况下减少梯度估计的方差*（记住，只要可能，我们总是希望这样做）。例如，一个常见的基线是从动作值中减去状态值，如果应用，我们将在梯度上升更新中使用优势$A(s, a) = Q(s, a) - V(s)$。这篇[文章](https://danieltakeshi.github.io/2017/03/28/going-deeper-into-reinforcement-learning-fundamentals-of-policy-gradients/)很好地解释了为什么基线能够减少方差，此外还介绍了一系列策略梯度的基本原理。

> A widely used variation of REINFORCE is to subtract a baseline value from the return $G_t$ to *reduce the variance of gradient estimation while keeping the bias unchanged* (Remember we always want to do this when possible). For example, a common baseline is to subtract state-value from action-value, and if applied, we would use advantage $A(s, a) = Q(s, a) - V(s)$ in the gradient ascent update. This [post](https://danieltakeshi.github.io/2017/03/28/going-deeper-into-reinforcement-learning-fundamentals-of-policy-gradients/) nicely explained why a baseline works for reducing the variance, in addition to a set of fundamentals of policy gradient.

#### Actor-Critic

> Actor-Critic

策略梯度中的两个主要组成部分是策略模型和价值函数。除了策略之外，学习价值函数非常有意义，因为了解价值函数可以辅助策略更新，例如通过减少普通策略梯度中的梯度方差，而这正是**Actor-Critic**方法所做的。

> Two main components in policy gradient are the policy model and the value function. It makes a lot of sense to learn the value function in addition to the policy, since knowing the value function can assist the policy update, such as by reducing gradient variance in vanilla policy gradients, and that is exactly what the **Actor-Critic** method does.

Actor-critic 方法由两个模型组成，它们可以选择性地共享参数：

> Actor-critic methods consist of two models, which may optionally share parameters:

• **评价器**更新值函数参数 w，并且根据算法，它可能是动作值 $Q_w(a \vert s)$ 或状态值 $V_w(s)$。

• **Actor** 更新策略参数 $\theta$ 针对 $\pi_\theta(a \vert s)$，方向由评论者建议。

英文原文：

• **Critic** updates the value function parameters w and depending on the algorithm it could be action-value $Q_w(a \vert s)$ or state-value $V_w(s)$.

• **Actor** updates the policy parameters $\theta$ for $\pi_\theta(a \vert s)$, in the direction suggested by the critic.

让我们看看它在一个简单的动作-价值型actor-critic算法中是如何工作的。

> Let’s see how it works in a simple action-value actor-critic algorithm.

1\. 随机初始化 $s, \theta, w$；采样 $a \sim \pi_\theta(a \vert s)$。

2\. 对于 $t = 1 \dots T$：



1\. 采样奖励 $r_t \sim R(s, a)$ 和下一个状态 $s’ \sim P(s’ \vert s, a)$;



2\. 然后采样下一个动作 $a’ \sim \pi_\theta(a’ \vert s’)$;



3\. 更新策略参数： $\theta \leftarrow \theta + \alpha_\theta Q_w(s, a) \nabla_\theta \ln \pi_\theta(a \vert s)$;



4\. 计算时间 t 处动作值的校正（TD 误差）：   

$\delta_t = r_t + \gamma Q_w(s’, a’) - Q_w(s, a)$   

并用它来更新动作值函数的参数：  

 $w \leftarrow w + \alpha_w \delta_t \nabla_w Q_w(s, a)$



5\. 更新 $a \leftarrow a’$ 和 $s \leftarrow s’$。

英文原文：

1\. Initialize $s, \theta, w$ at random; sample $a \sim \pi_\theta(a \vert s)$.

2\. For $t = 1 \dots T$:



1\. Sample reward $r_t \sim R(s, a)$ and next state $s’ \sim P(s’ \vert s, a)$;



2\. Then sample the next action $a’ \sim \pi_\theta(a’ \vert s’)$;



3\. Update the policy parameters: $\theta \leftarrow \theta + \alpha_\theta Q_w(s, a) \nabla_\theta \ln \pi_\theta(a \vert s)$;



4\. Compute the correction (TD error) for action-value at time t:   

$\delta_t = r_t + \gamma Q_w(s’, a’) - Q_w(s, a)$   

and use it to update the parameters of action-value function:  

 $w \leftarrow w + \alpha_w \delta_t \nabla_w Q_w(s, a)$



5\. Update $a \leftarrow a’$ and $s \leftarrow s’$.

两个学习率， $\alpha_\theta$ 和 $\alpha_w$，分别预定义用于策略和值函数参数更新。

> Two learning rates, $\alpha_\theta$ and $\alpha_w$, are predefined for policy and value function parameter updates respectively.

#### 离策略策略梯度

> Off-Policy Policy Gradient

REINFORCE 和原始版本的 actor-critic 方法都是在策略（on-policy）的：训练样本是根据目标策略（即我们试图优化的策略）收集的。然而，离策略（off-policy）方法带来了几个额外的优势：

> Both REINFORCE and the vanilla version of actor-critic method are on-policy: training samples are collected according to the target policy — the very same policy that we try to optimize for. Off policy methods, however, result in several additional advantages:

1. 离策略方法不需要完整的轨迹，并且可以重用任何过去的片段（[“经验回放”](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network)），从而大大提高样本效率。
2. 样本收集遵循与目标策略不同的行为策略，带来更好的[探索](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#exploration-exploitation-dilemma)。

> • The off-policy approach does not require full trajectories and can reuse any past episodes ([“experience replay”](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network)) for much better sample efficiency.
> • The sample collection follows a behavior policy different from the target policy, bringing better [exploration](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#exploration-exploitation-dilemma).

现在我们来看看离策略策略梯度是如何计算的。用于收集样本的行为策略是一个已知策略（像超参数一样预定义），标记为$\beta(a \vert s)$。目标函数将奖励累加到由该行为策略定义的状态分布上：

> Now let’s see how off-policy policy gradient is computed. The behavior policy for collecting samples is a known policy (predefined just like a hyperparameter), labelled as $\beta(a \vert s)$. The objective function sums up the reward over the state distribution defined by this behavior policy:

$$
J(\theta)
= \sum_{s \in \mathcal{S}} d^\beta(s) \sum_{a \in \mathcal{A}} Q^\pi(s, a) \pi_\theta(a \vert s)
= \mathbb{E}_{s \sim d^\beta} \big[ \sum_{a \in \mathcal{A}} Q^\pi(s, a) \pi_\theta(a \vert s) \big]
$$

其中$d^\beta(s)$是行为策略$\beta$的平稳分布；回想一下$d^\beta(s) = \lim_{t \to \infty} P(S_t = s \vert S_0, \beta)$；$Q^\pi$是根据目标策略$\pi$（而不是行为策略！）估计的动作值函数。

> where $d^\beta(s)$ is the stationary distribution of the behavior policy $\beta$; recall that $d^\beta(s) = \lim_{t \to \infty} P(S_t = s \vert S_0, \beta)$; and $Q^\pi$ is the action-value function estimated with regard to the target policy $\pi$ (not the behavior policy!).

鉴于训练观测值由 $a \sim \beta(a \vert s)$ 采样，我们可以将梯度重写为：

> Given that the training observations are sampled by $a \sim \beta(a \vert s)$, we can rewrite the gradient as:

$$
\begin{aligned}
\nabla_\theta J(\theta)
&= \nabla_\theta \mathbb{E}_{s \sim d^\beta} \Big[ \sum_{a \in \mathcal{A}} Q^\pi(s, a) \pi_\theta(a \vert s)  \Big] & \\ 
&= \mathbb{E}_{s \sim d^\beta} \Big[ \sum_{a \in \mathcal{A}} \big( Q^\pi(s, a) \nabla_\theta \pi_\theta(a \vert s) + \color{red}{\pi_\theta(a \vert s) \nabla_\theta Q^\pi(s, a)} \big) \Big] & \scriptstyle{\text{; Derivative product rule.}}\\
&\stackrel{(i)}{\approx} \mathbb{E}_{s \sim d^\beta} \Big[ \sum_{a \in \mathcal{A}} Q^\pi(s, a) \nabla_\theta \pi_\theta(a \vert s) \Big] & \scriptstyle{\text{; Ignore the red part: } \color{red}{\pi_\theta(a \vert s) \nabla_\theta Q^\pi(s, a)}}. \\
&= \mathbb{E}_{s \sim d^\beta} \Big[ \sum_{a \in \mathcal{A}} \beta(a \vert s) \frac{\pi_\theta(a \vert s)}{\beta(a \vert s)} Q^\pi(s, a) \frac{\nabla_\theta \pi_\theta(a \vert s)}{\pi_\theta(a \vert s)} \Big] & \\
&= \mathbb{E}_\beta \Big[\frac{\color{blue}{\pi_\theta(a \vert s)}}{\color{blue}{\beta(a \vert s)}} Q^\pi(s, a) \nabla_\theta \ln \pi_\theta(a \vert s) \Big] & \scriptstyle{\text{; The blue part is the importance weight.}}
\end{aligned}
$$

其中 $\frac{\pi_\theta(a \vert s)}{\beta(a \vert s)}$ 是 [重要性权重](http://timvieira.github.io/blog/post/2014/12/21/importance-sampling/)。因为 $Q^\pi$ 是目标策略的函数，因此也是策略参数 $\theta$ 的函数，所以根据乘积法则，我们也应该对 $\nabla_\theta Q^\pi(s, a)$ 求导。然而，在实际中计算 $\nabla_\theta Q^\pi(s, a)$ 是非常困难的。幸运的是，如果我们使用忽略 Q 梯度的近似梯度，我们仍然能保证策略改进并最终达到真正的局部最小值。这在 [此处](https://arxiv.org/pdf/1205.4839.pdf) 的证明中得到了证实 (Degris, White & Sutton, 2012)。

> where $\frac{\pi_\theta(a \vert s)}{\beta(a \vert s)}$ is the [importance weight](http://timvieira.github.io/blog/post/2014/12/21/importance-sampling/). Because $Q^\pi$ is a function of the target policy and thus a function of policy parameter $\theta$,  we should take the derivative of $\nabla_\theta Q^\pi(s, a)$ as well according to the product rule. However, it is super hard to compute $\nabla_\theta Q^\pi(s, a)$ in reality. Fortunately if we use an approximated gradient with the gradient of Q ignored, we still guarantee the policy improvement and eventually achieve the true local minimum. This is justified in the proof [here](https://arxiv.org/pdf/1205.4839.pdf) (Degris, White & Sutton, 2012).

总而言之，在离策略设置中应用策略梯度时，我们可以简单地通过加权和对其进行调整，其中权重是目标策略与行为策略的比率，即 $\frac{\pi_\theta(a \vert s)}{\beta(a \vert s)}$。

> In summary, when applying policy gradient in the off-policy setting, we can simple adjust it with a weighted sum and the weight is the ratio of the target policy to the behavior policy, $\frac{\pi_\theta(a \vert s)}{\beta(a \vert s)}$.

#### A3C

> A3C

[[论文](https://arxiv.org/abs/1602.01783)|[代码](https://github.com/dennybritz/reinforcement-learning/tree/master/PolicyGradient/a3c)]

> [[paper](https://arxiv.org/abs/1602.01783)|[code](https://github.com/dennybritz/reinforcement-learning/tree/master/PolicyGradient/a3c)]

**异步优势演员-评论家** ([Mnih 等人，2016](https://arxiv.org/abs/1602.01783))，简称 **A3C**，是一种经典的策略梯度方法，特别侧重于并行训练。

> **Asynchronous Advantage Actor-Critic** ([Mnih et al., 2016](https://arxiv.org/abs/1602.01783)), short for **A3C**, is a classic policy gradient method with a special focus on parallel training.

在 A3C 中，评论家学习价值函数，而多个演员并行训练并定期与全局参数同步。因此，A3C 被设计为非常适合并行训练。

> In A3C, the critics learn the value function while multiple actors are trained in parallel and get synced with global parameters from time to time. Hence, A3C is designed to work well for parallel training.

我们以状态值函数为例。状态值的损失函数是最小化均方误差，$J_v(w) = (G_t - V_w(s))^2$并且可以应用梯度下降来找到最优的 w。此状态值函数在策略梯度更新中用作基线。

> Let’s use the state-value function as an example. The loss function for state value is to minimize the mean squared error, $J_v(w) = (G_t - V_w(s))^2$ and gradient descent can be applied to find the optimal w. This state-value function is used as the baseline in the policy gradient update.

以下是算法概述：

> Here is the algorithm outline:

1\. 我们有全局参数，$\theta$和$w$；类似的线程特定参数，$\theta’$和$w’$。

2\. 初始化时间步长$t = 1$

3\. 当$T \leq T_\text{MAX}$时：6. 对于$i = t-1, \dots, t\_\text{start}$：1. $R \leftarrow \gamma R + R\_i$；其中 R 是$G\_i$的 MC 度量。2. 累积关于$\theta'$的梯度：$d\theta \leftarrow d\theta + \nabla\_{\theta'} \log \pi\_{\theta'}(a\_i \vert s\_i)(R - V\_{w'}(s\_i))$；  
累积关于 w' 的梯度：$dw \leftarrow dw + 2 (R - V\_{w'}(s\_i)) \nabla\_{w'} (R - V\_{w'}(s\_i))$。

1\. 重置梯度：$\mathrm{d}\theta = 0$和$\mathrm{d}w = 0$。



2\. 将线程特定参数与全局参数同步：$\theta’ = \theta$和$w’ = w$。



3\. $t_\text{start}$ = t 并采样一个起始状态$s_t$。



4\. 当 ($s_t$ != TERMINAL) 且 $t - t_\text{start} \leq t_\text{max}$ 时：



1\. 选择动作$A_t \sim \pi_{\theta’}(A_t \vert S_t)$并接收新的奖励$R_t$和新的状态$s_{t+1}$。







2\. 更新$t = t + 1$和$T = T + 1$



5\. 初始化保存回报估计的变量

1\. 异步更新 $\theta$ 使用 $\mathrm{d}\theta$，以及 $w$ 使用 $\mathrm{d}w$。

英文原文：

1\. 
We have global parameters, $\theta$ and $w$; similar thread-specific parameters, $\theta’$ and $w’$.


2\. 
Initialize the time step $t = 1$


3\. 
While $T \leq T_\text{MAX}$:


 6. For $i = t-1, \dots, t\_\text{start}$:
     1. $R \leftarrow \gamma R + R\_i$; here R is a MC measure of $G\_i$.
     2. Accumulate gradients w.r.t. $\theta'$: $d\theta \leftarrow d\theta + \nabla\_{\theta'} \log \pi\_{\theta'}(a\_i \vert s\_i)(R - V\_{w'}(s\_i))$;  
Accumulate gradients w.r.t. w': $dw \leftarrow dw + 2 (R - V\_{w'}(s\_i)) \nabla\_{w'} (R - V\_{w'}(s\_i))$.



1\. Reset gradient: $\mathrm{d}\theta = 0$ and $\mathrm{d}w = 0$.



2\. Synchronize thread-specific parameters with global ones: $\theta’ = \theta$ and $w’ = w$.



3\. $t_\text{start}$ = t and sample a starting state $s_t$.



4\. While ($s_t$ != TERMINAL) and $t - t_\text{start} \leq t_\text{max}$:







1\. Pick the action $A_t \sim \pi_{\theta’}(A_t \vert S_t)$ and receive a new reward $R_t$ and a new state $s_{t+1}$.







2\. Update $t = t + 1$ and $T = T + 1$



5\. Initialize the variable that holds the return estimation

1\. Update asynchronously $\theta$ using $\mathrm{d}\theta$, and $w$ using $\mathrm{d}w$.

$$
R = \begin{cases} 
 0 & \text{if } s_t \text{ is TERMINAL} \\
 V_{w'}(s_t) & \text{otherwise}
 \end{cases}
$$

A3C 实现了多智能体训练中的并行性。梯度累积步骤 (6.2) 可以被视为基于小批量随机梯度更新的并行化重构：$w$ 或 $\theta$ 的值在每个训练线程的方向上独立地得到一点修正。

> A3C enables the parallelism in multiple agent training. The gradient accumulation step (6.2) can be considered as a parallelized reformation of minibatch-based stochastic gradient update: the values of $w$ or $\theta$ get corrected by a little bit in the direction of each training thread independently.

#### A2C

> A2C

[[论文](https://arxiv.org/abs/1602.01783)|[代码](https://github.com/openai/baselines/blob/master/baselines/a2c/a2c.py)]

> [[paper](https://arxiv.org/abs/1602.01783)|[code](https://github.com/openai/baselines/blob/master/baselines/a2c/a2c.py)]

**A2C** 是 A3C 的同步、确定性版本；这就是它被命名为“A2C”，去掉了第一个“A”（“异步”）的原因。在 A3C 中，每个智能体独立地与全局参数通信，因此有时线程特定的智能体可能会使用不同版本的策略，从而导致聚合更新不是最优的。为了解决这种不一致性，A2C 中的协调器会等待所有并行执行器完成工作，然后才更新全局参数，接着在下一次迭代中，并行执行器从相同的策略开始。同步的梯度更新使训练更具凝聚力，并可能加快收敛速度。

> **A2C** is a synchronous, deterministic version of A3C; that’s why it is named as “A2C” with the first “A” (“asynchronous”) removed. In A3C each agent talks to the global parameters independently, so it is possible sometimes the thread-specific agents would be playing with policies of different versions and therefore the aggregated update would not be optimal. To resolve the inconsistency, a coordinator in A2C waits for all the parallel actors to finish their work before updating the global parameters and then in the next iteration parallel actors starts from the same policy. The synchronized gradient update keeps the training more cohesive and potentially to make convergence faster.

A2C 已被[证明](https://blog.openai.com/baselines-acktr-a2c/)能够更有效地利用 GPU，并且在处理大批量数据时表现更好，同时达到与 A3C 相同或更优的性能。

> A2C has been [shown](https://blog.openai.com/baselines-acktr-a2c/) to be able to utilize GPUs more efficiently and work better with large batch sizes while achieving same or better performance than A3C.

![The architecture of A3C versus A2C.](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/A3C_vs_A2C.png)

#### DPG

> DPG

[[论文](https://hal.inria.fr/file/index/docid/938992/filename/dpg-icml2014.pdf)|代码]

> [[paper](https://hal.inria.fr/file/index/docid/938992/filename/dpg-icml2014.pdf)|code]

在上述方法中，策略函数 $\pi(. \vert s)$ 总是被建模为给定当前状态下动作 $\mathcal{A}$ 的概率分布，因此它是*随机的*。**确定性策略梯度 (DPG)** 则将策略建模为确定性决策：$a = \mu(s)$。这可能看起来很奇怪——当它输出单个动作时，你如何计算动作概率的梯度？让我们一步步地探讨。

英文原文：In methods described above, the policy function 

$\pi(. \vert s)$ is always modeled as a probability distribution over actions 

$\mathcal{A}$ given the current state and thus it is *stochastic*. Deterministic policy gradient (DPG) instead models the policy as a deterministic decision: 

$a = \mu(s)$. It may look bizarre — how can you calculate the gradient of the action probability when it outputs a single action? Let’s look into it step by step.

回顾一些符号以方便讨论：

> Refresh on a few notations to facilitate the discussion:

• $\rho_0(s)$: 状态的初始分布

• $\rho^\mu(s \to s’, k)$: 从状态 s 开始，在策略 $\mu$ 下移动 k 步后，在状态 s’ 的访问概率密度。

• $\rho^\mu(s’)$: 折扣状态分布，定义为 $\rho^\mu(s’) = \int_\mathcal{S} \sum_{k=1}^\infty \gamma^{k-1} \rho_0(s) \rho^\mu(s \to s’, k) ds$。

英文原文：

• $\rho_0(s)$: The initial distribution over states

• $\rho^\mu(s \to s’, k)$: Starting from state s, the visitation probability density at state s’ after moving k steps by policy $\mu$.

• $\rho^\mu(s’)$: Discounted state distribution, defined as $\rho^\mu(s’) = \int_\mathcal{S} \sum_{k=1}^\infty \gamma^{k-1} \rho_0(s) \rho^\mu(s \to s’, k) ds$.

要优化的目标函数如下所示：

> The objective function to optimize for is listed as follows:

$$
J(\theta) = \int_\mathcal{S} \rho^\mu(s) Q(s, \mu_\theta(s)) ds
$$

**确定性策略梯度定理**：现在是计算梯度的时候了！根据链式法则，我们首先计算Q对动作a的梯度，然后计算确定性策略函数`\mu`对`\theta`的梯度：

英文原文：Deterministic policy gradient theorem: Now it is the time to compute the gradient! According to the chain rule, we first take the gradient of Q w.r.t. the action a and then take the gradient of the deterministic policy function `\mu` w.r.t. `\theta`:

$$
\begin{aligned}
\nabla_\theta J(\theta) 
&= \int_\mathcal{S} \rho^\mu(s) \nabla_a Q^\mu(s, a) \nabla_\theta \mu_\theta(s) \rvert_{a=\mu_\theta(s)} ds \\
&= \mathbb{E}_{s \sim \rho^\mu} [\nabla_a Q^\mu(s, a) \nabla_\theta \mu_\theta(s) \rvert_{a=\mu_\theta(s)}]
\end{aligned}
$$

我们可以将确定性策略视为随机策略的*特例*，此时概率分布在单个动作上只包含一个极端的非零值。实际上，在DPG[论文](https://hal.inria.fr/file/index/docid/938992/filename/dpg-icml2014.pdf)中，作者已经表明，如果随机策略$\pi_{\mu_\theta, \sigma}$通过确定性策略$\mu_\theta$和一个变异变量$\sigma$进行重新参数化，那么当$\sigma=0$时，随机策略最终等同于确定性情况。与确定性策略相比，我们预计随机策略需要更多的样本，因为它整合了整个状态和动作空间的数据。

> We can consider the deterministic policy as a *special case* of the stochastic one, when the probability distribution contains only one extreme non-zero value over one action. Actually, in the DPG [paper](https://hal.inria.fr/file/index/docid/938992/filename/dpg-icml2014.pdf), the authors have shown that if the stochastic policy $\pi_{\mu_\theta, \sigma}$ is re-parameterized by a deterministic policy $\mu_\theta$ and a variation variable $\sigma$, the stochastic policy is eventually equivalent to the deterministic case when $\sigma=0$. Compared to the deterministic policy, we expect the stochastic policy to require more samples as it integrates the data over the whole state and action space.

确定性策略梯度定理可以被整合到常见的策略梯度框架中。

> The deterministic policy gradient theorem can be plugged into common policy gradient frameworks.

让我们考虑一个在策略（on-policy）actor-critic算法的例子来展示这个过程。在在策略actor-critic的每次迭代中，两个动作都是确定性地采取的$a = \mu_\theta(s)$，并且策略参数上的[SARSA](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#sarsa-on-policy-td-control)更新依赖于我们刚刚计算出的新梯度：

> Let’s consider an example of on-policy actor-critic algorithm to showcase the procedure. In each iteration of on-policy actor-critic, two actions are taken deterministically $a = \mu_\theta(s)$ and the [SARSA](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#sarsa-on-policy-td-control) update on policy parameters relies on the new gradient that we just computed above:

$$
\begin{aligned}
\delta_t &= R_t + \gamma Q_w(s_{t+1}, a_{t+1}) - Q_w(s_t, a_t) & \small{\text{; TD error in SARSA}}\\
w_{t+1} &= w_t + \alpha_w \delta_t \nabla_w Q_w(s_t, a_t) & \\
\theta_{t+1} &= \theta_t + \alpha_\theta \color{red}{\nabla_a Q_w(s_t, a_t) \nabla_\theta \mu_\theta(s) \rvert_{a=\mu_\theta(s)}} & \small{\text{; Deterministic policy gradient theorem}}
\end{aligned}
$$

然而，除非环境中存在足够的噪声，否则由于策略的确定性，很难保证足够的[探索](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#exploration-exploitation-dilemma)。我们可以选择向策略中添加噪声（讽刺的是，这使其变为非确定性！），或者通过遵循不同的随机行为策略来收集样本，从而进行离策略（off-policy）学习。

> However, unless there is sufficient noise in the environment, it is very hard to guarantee enough [exploration](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#exploration-exploitation-dilemma) due to the determinacy of the policy. We can either add noise into the policy (ironically this makes it nondeterministic!) or learn it off-policy-ly by following a different stochastic behavior policy to collect samples.

例如，在离策略方法中，训练轨迹由随机策略 $\beta(a \vert s)$ 生成，因此状态分布遵循相应的折扣状态密度 $\rho^\beta$：

> Say, in the off-policy approach, the training trajectories are generated by a stochastic policy $\beta(a \vert s)$ and thus the state distribution follows the corresponding discounted state density $\rho^\beta$:

$$
\begin{aligned}
J_\beta(\theta) &= \int_\mathcal{S} \rho^\beta Q^\mu(s, \mu_\theta(s)) ds \\
\nabla_\theta J_\beta(\theta) &= \mathbb{E}_{s \sim \rho^\beta} [\nabla_a Q^\mu(s, a) \nabla_\theta \mu_\theta(s)  \rvert_{a=\mu_\theta(s)} ]
\end{aligned}
$$

请注意，由于策略是确定性的，我们只需要 $Q^\mu(s, \mu_\theta(s))$ 而不是 $\sum_a \pi(a \vert s) Q^\pi(s, a)$ 作为给定状态 s 的估计奖励。在具有随机策略的离策略方法中，重要性采样常用于纠正行为策略和目标策略之间的不匹配，正如我们 [上面](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#off-policy-policy-gradient) 所述。然而，由于确定性策略梯度消除了对动作的积分，我们可以避免重要性采样。

> Note that because the policy is deterministic, we only need $Q^\mu(s, \mu_\theta(s))$ rather than $\sum_a \pi(a \vert s) Q^\pi(s, a)$ as the estimated reward of a given state s.
> In the off-policy approach with a stochastic policy, importance sampling is often used to correct the mismatch between behavior and target policies, as what we have described [above](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#off-policy-policy-gradient). However, because the deterministic policy gradient removes the integral over actions, we can avoid importance sampling.

#### DDPG

> DDPG

[[论文](https://arxiv.org/pdf/1509.02971.pdf)|[代码](https://github.com/openai/baselines/tree/master/baselines/ddpg)]

> [[paper](https://arxiv.org/pdf/1509.02971.pdf)|[code](https://github.com/openai/baselines/tree/master/baselines/ddpg)]

**DDPG** ([Lillicrap, et al., 2015](https://arxiv.org/pdf/1509.02971.pdf))，是**深度确定性策略梯度**的简称，是一种无模型、异策略的Actor-Critic算法，它结合了[DPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg)和[DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network)。回想一下，DQN（深度Q网络）通过经验回放和冻结目标网络来稳定Q函数的学习。原始的DQN在离散空间中工作，而DDPG通过Actor-Critic框架将其扩展到连续空间，同时学习确定性策略。

> **DDPG** ([Lillicrap, et al., 2015](https://arxiv.org/pdf/1509.02971.pdf)), short for **Deep Deterministic Policy Gradient**, is a model-free off-policy actor-critic algorithm, combining [DPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg) with [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network). Recall that DQN (Deep Q-Network) stabilizes the learning of Q-function by experience replay and the frozen target network. The original DQN works in discrete space, and DDPG extends it to continuous space with the actor-critic framework while learning a deterministic policy.

为了更好地进行探索，一个探索策略 $\mu’$ 通过添加噪声 $\mathcal{N}$ 来构建：

> In order to do better exploration, an exploration policy $\mu’$ is constructed by adding noise $\mathcal{N}$:

$$
\mu'(s) = \mu_\theta(s) + \mathcal{N}
$$

此外，DDPG 对 actor 和 critic 的参数进行软更新（“保守策略迭代”），使用 $\tau \ll 1$：$\theta’ \leftarrow \tau \theta + (1 - \tau) \theta’$。这样，目标网络的值被限制为缓慢变化，这与 DQN 中目标网络在一段时间内保持冻结的设计不同。

> In addition, DDPG does soft updates (“conservative policy iteration”) on the parameters of both actor and critic, with $\tau \ll 1$: $\theta’ \leftarrow \tau \theta + (1 - \tau) \theta’$. In this way, the target network values are constrained to change slowly, different from the design in DQN that the target network stays frozen for some period of time.

论文中有一个在机器人领域特别有用的细节，即如何归一化低维特征的不同物理单位。例如，一个模型被设计为以机器人的位置和速度作为输入来学习策略；这些物理统计数据本质上是不同的，甚至相同类型的统计数据在多个机器人之间也可能差异很大。通过在每个小批量中对样本的每个维度进行归一化，应用 [批量归一化](http://proceedings.mlr.press/v37/ioffe15.pdf) 来解决这个问题。

> One detail in the paper that is particularly useful in robotics is on how to normalize the different physical units of low dimensional features. For example, a model is designed to learn a policy with the robot’s positions and velocities as input; these physical statistics are different by nature and even statistics of the same type may vary a lot across multiple robots. [Batch normalization](http://proceedings.mlr.press/v37/ioffe15.pdf) is applied to fix it by normalizing every dimension across samples in one minibatch.

![Fig 3. DDPG Algorithm. (Image source: Lillicrap, et al., 2015 )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/DDPG_algo.png)

#### D4PG

> D4PG

[[论文](https://openreview.net/forum?id=SyZipzbCb)|代码 (搜索“github d4pg”你会看到一些。)]

> [[paper](https://openreview.net/forum?id=SyZipzbCb)|code (Search “github d4pg” and you will see a few.)]

**Distributed Distributional DDPG (D4PG)** 在 DDPG 上应用了一系列改进，使其以分布式的形式运行。

> **Distributed Distributional DDPG (D4PG)** applies a set of improvements on DDPG to make it run in the distributional fashion.

(1) **分布式评论家**: 评论家将期望 Q 值估计为一个随机变量 ~ 一个分布 `Z_w`，该分布由 `w` 参数化，因此 $Q_w(s, a) = \mathbb{E} Z_w(x, a)$。学习分布参数的损失是最小化两个分布之间距离的某个度量 — 分布式 TD 误差：$L(w) = \mathbb{E}[d(\mathcal{T}_{\mu_\theta}, Z_{w’}(s, a), Z_w(s, a)]$，其中 $\mathcal{T}_{\mu_\theta}$ 是贝尔曼算子。

英文原文：(1) Distributional Critic: The critic estimates the expected Q value as a random variable ~ a distribution `Z_w` parameterized by `w` and therefore 

$Q_w(s, a) = \mathbb{E} Z_w(x, a)$. The loss for learning the distribution parameter is to minimize some measure of the distance between two distributions — distributional TD error: 

$L(w) = \mathbb{E}[d(\mathcal{T}_{\mu_\theta}, Z_{w’}(s, a), Z_w(s, a)]$, where 

$\mathcal{T}_{\mu_\theta}$ is the Bellman operator.

确定性策略梯度更新变为：

> The deterministic policy gradient update becomes:

$$
\begin{aligned}
\nabla_\theta J(\theta) 
&\approx \mathbb{E}_{\rho^\mu} [\nabla_a Q_w(s, a) \nabla_\theta \mu_\theta(s) \rvert_{a=\mu_\theta(s)}] & \scriptstyle{\text{; gradient update in DPG}} \\
&= \mathbb{E}_{\rho^\mu} [\mathbb{E}[\nabla_a Z_w(s, a)] \nabla_\theta \mu_\theta(s) \rvert_{a=\mu_\theta(s)}] & \scriptstyle{\text{; expectation of the Q-value distribution.}}
\end{aligned}
$$

(2) **`N`步回报**：在计算TD误差时，D4PG计算的是`N`步TD目标而不是一步TD目标，以纳入更多未来步骤的奖励。因此，新的TD目标是：

英文原文：(2) `N` -step returns: When calculating the TD error, D4PG computes `N` -step TD target rather than one-step to incorporate rewards in more future steps. Thus the new TD target is:

$$
r(s_0, a_0) + \mathbb{E}[\sum_{n=1}^{N-1} r(s_n, a_n) + \gamma^N Q(s_N, \mu_\theta(s_N)) \vert s_0, a_0 ]
$$

(3) **多个分布式并行Actor**：D4PG利用`K`个独立的actor，并行收集经验并向同一个回放缓冲区馈送数据。

英文原文：(3) Multiple Distributed Parallel Actors: D4PG utilizes `K` independent actors, gathering experience in parallel and feeding data into the same replay buffer.

(4) **优先经验回放 ([PER](https://arxiv.org/abs/1511.05952))**：最后一项修改是从大小为`R`的回放缓冲区中以非均匀概率`p_i`进行采样。通过这种方式，样本`i`被选中的概率为$(Rp_i)^{-1}$，因此重要性权重为$(Rp_i)^{-1}$。

英文原文：(4) Prioritized Experience Replay ([PER](https://arxiv.org/abs/1511.05952)): The last piece of modification is to do sampling from the replay buffer of size `R` with an non-uniform probability `p_i`. In this way, a sample `i` has the probability 

$(Rp_i)^{-1}$ to be selected and thus the importance weight is 

$(Rp_i)^{-1}$.

![D4PG algorithm (Image source: Barth-Maron, et al. 2018 ); Note that in the original paper, the variable letters are chosen slightly differently from what in the post; i.e. I use $\mu(.)$ for representing a deterministic policy instead of $\pi(.)$.](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/D4PG_algo.png)

#### MADDPG

> MADDPG

[[论文](https://arxiv.org/pdf/1706.02275.pdf)|[代码](https://github.com/openai/maddpg)]

> [[paper](https://arxiv.org/pdf/1706.02275.pdf)|[code](https://github.com/openai/maddpg)]

**多智能体DDPG** (**MADDPG**) ([Lowe et al., 2017](https://arxiv.org/pdf/1706.02275.pdf)) 将DDPG扩展到一个多智能体仅凭局部信息协调完成任务的环境。从一个智能体的角度来看，环境是非平稳的，因为其他智能体的策略会迅速升级且未知。MADDPG是一种专门为处理这种变化环境和智能体之间交互而重新设计的actor-critic模型。

> **Multi-agent DDPG** (**MADDPG**) ([Lowe et al., 2017](https://arxiv.org/pdf/1706.02275.pdf)) extends DDPG to an environment where multiple agents are coordinating to complete tasks with only local information. In the viewpoint of one agent, the environment is non-stationary as policies of other agents are quickly upgraded and remain unknown. MADDPG is an actor-critic model redesigned particularly for handling such a changing environment and interactions between agents.

该问题可以在MDP的多智能体版本中形式化，也称为*马尔可夫博弈*。MADDPG是为部分可观测的马尔可夫博弈提出的。假设总共有N个智能体，具有一组状态$\mathcal{S}$。每个智能体拥有一组可能的动作$\mathcal{A}_1, \dots, \mathcal{A}_N$和一组观测$\mathcal{O}_1, \dots, \mathcal{O}_N$。状态转移函数涉及所有状态、动作和观测空间$\mathcal{T}: \mathcal{S} \times \mathcal{A}_1 \times \dots \mathcal{A}_N \mapsto \mathcal{S}$。每个智能体的随机策略只涉及其自身的状态和动作：$\pi_{\theta_i}: \mathcal{O}_i \times \mathcal{A}_i \mapsto [0, 1]$，即给定其自身观测的动作概率分布，或者确定性策略：$\mu_{\theta_i}: \mathcal{O}_i \mapsto \mathcal{A}_i$。

> The problem can be formalized in the multi-agent version of MDP, also known as *Markov games*. MADDPG is proposed for partially observable Markov games. Say, there are N agents in total with a set of states $\mathcal{S}$. Each agent owns a set of possible action, $\mathcal{A}_1, \dots, \mathcal{A}_N$, and a set of observation, $\mathcal{O}_1, \dots, \mathcal{O}_N$. The state transition function involves all states, action and observation spaces  $\mathcal{T}: \mathcal{S} \times \mathcal{A}_1 \times \dots \mathcal{A}_N \mapsto \mathcal{S}$. Each agent’s stochastic policy only involves its own state and action: $\pi_{\theta_i}: \mathcal{O}_i \times \mathcal{A}_i \mapsto [0, 1]$, a probability distribution over actions given its own observation, or a deterministic policy: $\mu_{\theta_i}: \mathcal{O}_i \mapsto \mathcal{A}_i$.

令$\vec{o} = {o_1, \dots, o_N}$，$\vec{\mu} = {\mu_1, \dots, \mu_N}$，且策略由$\vec{\theta} = {\theta_1, \dots, \theta_N}$参数化。

> Let $\vec{o} = {o_1, \dots, o_N}$, $\vec{\mu} = {\mu_1, \dots, \mu_N}$ and the policies are parameterized by $\vec{\theta} = {\theta_1, \dots, \theta_N}$.

MADDPG中的评论家为第i个智能体学习一个集中式动作值函数$Q^\vec{\mu}_i(\vec{o}, a_1, \dots, a_N)$，其中$a_1 \in \mathcal{A}_1, \dots, a_N \in \mathcal{A}_N$是所有智能体的动作。每个$Q^\vec{\mu}_i$都是为$i=1, \dots, N$单独学习的，因此多个智能体可以拥有任意的奖励结构，包括竞争环境中的冲突奖励。同时，多个执行者（每个智能体一个）正在各自探索和升级策略参数$\theta_i$。

> The critic in MADDPG learns a centralized action-value function $Q^\vec{\mu}_i(\vec{o}, a_1, \dots, a_N)$ for the i-th agent, where $a_1 \in \mathcal{A}_1, \dots, a_N \in \mathcal{A}_N$ are actions of all agents. Each $Q^\vec{\mu}_i$ is learned separately for $i=1, \dots, N$ and therefore multiple agents can have arbitrary reward structures, including conflicting rewards in a competitive setting. Meanwhile, multiple actors, one for each agent, are exploring and upgrading the policy parameters $\theta_i$ on their own.

**执行者更新**：

> **Actor update**:

$$
\nabla_{\theta_i} J(\theta_i) = \mathbb{E}_{\vec{o}, a \sim \mathcal{D}} [\nabla_{a_i} Q^{\vec{\mu}}_i (\vec{o}, a_1, \dots, a_N) \nabla_{\theta_i} \mu_{\theta_i}(o_i) \rvert_{a_i=\mu_{\theta_i}(o_i)} ]
$$

其中$\mathcal{D}$是用于经验回放的记忆缓冲区，包含多个情节样本$(\vec{o}, a_1, \dots, a_N, r_1, \dots, r_N, \vec{o}’)$——给定当前观测$\vec{o}$，智能体采取动作$a_1, \dots, a_N$并获得奖励$r_1, \dots, r_N$，从而导致新的观测$\vec{o}’$。

> Where $\mathcal{D}$ is the memory buffer for experience replay, containing multiple episode samples $(\vec{o}, a_1, \dots, a_N, r_1, \dots, r_N, \vec{o}’)$ — given current observation $\vec{o}$, agents take action $a_1, \dots, a_N$ and get rewards $r_1, \dots, r_N$, leading to the new observation $\vec{o}’$.

**评论家更新**：

> **Critic update**:

$$
\begin{aligned}
\mathcal{L}(\theta_i) &= \mathbb{E}_{\vec{o}, a_1, \dots, a_N, r_1, \dots, r_N, \vec{o}'}[ (Q^{\vec{\mu}}_i(\vec{o}, a_1, \dots, a_N) - y)^2 ] & \\
\text{where } y &= r_i + \gamma Q^{\vec{\mu}'}_i (\vec{o}', a'_1, \dots, a'_N) \rvert_{a'_j = \mu'_{\theta_j}} & \scriptstyle{\text{; TD target!}}
\end{aligned}
$$

其中$\vec{\mu}’$是具有延迟软更新参数的目标策略。

> where $\vec{\mu}’$ are the target policies with delayed softly-updated parameters.

如果在评论家更新期间策略$\vec{\mu}$未知，我们可以要求每个智能体学习并演化其对其他智能体策略的近似。使用近似策略，MADDPG仍然可以高效学习，尽管推断出的策略可能不准确。

> If the policies $\vec{\mu}$ are unknown during the critic update, we can ask each agent to learn and evolve its own approximation of others’ policies. Using the approximated policies, MADDPG still can learn efficiently although the inferred policies might not be accurate.

为了减轻环境中竞争或协作智能体之间交互引起的高方差，MADDPG提出了另一个要素——*策略集成*：

> To mitigate the high variance triggered by the interaction between competing or collaborating agents in the environment, MADDPG proposed one more element - *policy ensembles*:

1. 为一个智能体训练K个策略；
2. 为情节展开选择一个随机策略；
3. 对这K个策略进行集成以进行梯度更新。

> • Train K policies for one agent;
> • Pick a random policy for episode rollouts;
> • Take an ensemble of these K policies to do gradient update.

总而言之，MADDPG 在 DDPG 的基础上增加了三个额外的要素，使其适应多智能体环境：

> In summary, MADDPG added three additional ingredients on top of DDPG to make it adapt to the multi-agent environment:

- 集中式评论家 + 分散式行动者；
- 行动者能够利用其他智能体的估计策略进行学习；
- 策略集成有利于减少方差。

> • Centralized critic + decentralized actors;
> • Actors are able to use estimated policies of other agents for learning;
> • Policy ensembling is good for reducing variance.

![The architecture design of MADDPG. (Image source: Lowe et al., 2017 )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/MADDPG.png)

#### TRPO

> TRPO

[[论文](https://arxiv.org/pdf/1502.05477.pdf)|[代码](https://github.com/openai/baselines/tree/master/baselines/trpo_mpi)]

> [[paper](https://arxiv.org/pdf/1502.05477.pdf)|[code](https://github.com/openai/baselines/tree/master/baselines/trpo_mpi)]

为了提高训练稳定性，我们应该避免在一步中过度改变策略的参数更新。**信任区域策略优化 (TRPO)** ([Schulman 等人，2015](https://arxiv.org/pdf/1502.05477.pdf)) 通过在每次迭代中对策略更新的大小施加 [KL 散度](https://lilianweng.github.io/posts/2017-08-20-gan/#kullbackleibler-and-jensenshannon-divergence)约束来实现这一思想。

> To improve training stability, we should avoid parameter updates that change the policy too much at one step. **Trust region policy optimization (TRPO)** ([Schulman, et al., 2015](https://arxiv.org/pdf/1502.05477.pdf)) carries out this idea by enforcing a [KL divergence](https://lilianweng.github.io/posts/2017-08-20-gan/#kullbackleibler-and-jensenshannon-divergence) constraint on the size of policy update at each iteration.

考虑我们进行离策略强化学习（off-policy RL）的情况，在 rollout worker 上用于收集轨迹的策略 $\beta$ 与要优化的策略 $\pi$ 不同。离策略模型中的目标函数衡量状态访问分布和动作上的总优势，而训练数据分布与真实策略状态分布之间的不匹配通过重要性采样估计器进行补偿：

> Consider the case when we are doing off-policy RL, the policy $\beta$ used for collecting trajectories on rollout workers is different from the policy $\pi$ to optimize for. The objective function in an off-policy model measures the total advantage over the state visitation distribution and actions, while the mismatch between the training data distribution and the true policy state distribution is compensated by importance sampling estimator:

$$
\begin{aligned}
J(\theta)
&= \sum_{s \in \mathcal{S}} \rho^{\pi_{\theta_\text{old}}} \sum_{a \in \mathcal{A}} \big( \pi_\theta(a \vert s) \hat{A}_{\theta_\text{old}}(s, a) \big) & \\
&= \sum_{s \in \mathcal{S}} \rho^{\pi_{\theta_\text{old}}} \sum_{a \in \mathcal{A}} \big( \beta(a \vert s) \frac{\pi_\theta(a \vert s)}{\beta(a \vert s)} \hat{A}_{\theta_\text{old}}(s, a) \big) & \scriptstyle{\text{; Importance sampling}} \\
&= \mathbb{E}_{s \sim \rho^{\pi_{\theta_\text{old}}}, a \sim \beta} \big[ \frac{\pi_\theta(a \vert s)}{\beta(a \vert s)} \hat{A}_{\theta_\text{old}}(s, a) \big] &
\end{aligned}
$$

其中 $\theta_\text{old}$ 是更新前的策略参数，因此我们已知；$\rho^{\pi_{\theta_\text{old}}}$ 的定义与 [上面](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg) 相同；$\beta(a \vert s)$ 是用于收集轨迹的行为策略。值得注意的是，我们使用估计优势 $\hat{A}(.)$ 而不是真实优势函数 $A(.)$，因为真实奖励通常是未知的。

> where $\theta_\text{old}$ is the policy parameters before the update and thus known to us; $\rho^{\pi_{\theta_\text{old}}}$ is defined in the same way as [above](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg); $\beta(a \vert s)$ is the behavior policy for collecting trajectories. Noted that we use an estimated advantage $\hat{A}(.)$ rather than the true advantage function $A(.)$ because the true rewards are usually unknown.

在策略内训练时，理论上用于收集数据的策略与我们想要优化的策略是相同的。然而，当 rollout worker 和优化器并行异步运行时，行为策略可能会过时。TRPO 考虑了这种细微的差异：它将行为策略标记为 $\pi_{\theta_\text{old}}(a \vert s)$，因此目标函数变为：

> When training on policy, theoretically the policy for collecting data is same as the policy that we want to optimize. However, when rollout workers and optimizers are running in parallel asynchronously, the behavior policy can get stale. TRPO considers this subtle difference: It labels the behavior policy as $\pi_{\theta_\text{old}}(a \vert s)$ and thus the objective function becomes:

$$
J(\theta) = \mathbb{E}_{s \sim \rho^{\pi_{\theta_\text{old}}}, a \sim \pi_{\theta_\text{old}}} \big[ \frac{\pi_\theta(a \vert s)}{\pi_{\theta_\text{old}}(a \vert s)} \hat{A}_{\theta_\text{old}}(s, a) \big]
$$

TRPO 旨在最大化目标函数 $J(\theta)$，同时满足 *信任区域约束*，该约束要求旧策略和新策略之间通过 [KL 散度](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)衡量的距离足够小，在参数 δ 范围内：

> TRPO aims to maximize the objective function $J(\theta)$ subject to, *trust region constraint* which enforces the distance between old and new policies measured by [KL-divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence) to be small enough, within a parameter δ:

$$
\mathbb{E}_{s \sim \rho^{\pi_{\theta_\text{old}}}} [D_\text{KL}(\pi_{\theta_\text{old}}(.\vert s) \| \pi_\theta(.\vert s)] \leq \delta
$$

通过这种方式，当满足这个硬约束时，旧策略和新策略就不会偏离太多。同时，TRPO 仍然可以保证策略迭代的单调改进（很棒，对吧？）。如果感兴趣，请阅读 [论文](https://arxiv.org/pdf/1502.05477.pdf) 中的证明 :)

> In this way, the old and new policies would not diverge too much when this hard constraint is met. While still, TRPO can guarantee a monotonic improvement over policy iteration (Neat, right?). Please read the proof in the [paper](https://arxiv.org/pdf/1502.05477.pdf) if interested :)

#### PPO

> PPO

[[论文](https://arxiv.org/pdf/1707.06347.pdf)|[代码](https://github.com/openai/baselines/tree/master/baselines/ppo1)]

> [[paper](https://arxiv.org/pdf/1707.06347.pdf)|[code](https://github.com/openai/baselines/tree/master/baselines/ppo1)]

鉴于TRPO相对复杂，并且我们仍然希望实现类似的约束，**近端策略优化（PPO）**通过使用裁剪的替代目标来简化它，同时保持相似的性能。

> Given that TRPO is relatively complicated and we still want to implement a similar constraint, **proximal policy optimization (PPO)** simplifies it by using a clipped surrogate objective while retaining similar performance.

首先，我们将旧策略和新策略之间的概率比表示为：

> First, let’s denote the probability ratio between old and new policies as:

$$
r(\theta) = \frac{\pi_\theta(a \vert s)}{\pi_{\theta_\text{old}}(a \vert s)}
$$

那么，TRPO（在策略上）的目标函数变为：

> Then, the objective function of TRPO (on policy) becomes:

$$
J^\text{TRPO} (\theta) = \mathbb{E} [ r(\theta) \hat{A}_{\theta_\text{old}}(s, a) ]
$$

如果不对$\theta_\text{old}$和$\theta$之间的距离进行限制，最大化$J^\text{TRPO} (\theta)$将导致参数更新过大和策略比率过高，从而造成不稳定。PPO通过强制$r(\theta)$保持在1附近的一个小区间内（精确地说是$[1-\epsilon, 1+\epsilon]$，其中$\epsilon$是一个超参数）来施加约束。

> Without a limitation on the distance between $\theta_\text{old}$ and $\theta$, to maximize $J^\text{TRPO} (\theta)$ would lead to instability with extremely large parameter updates and big policy ratios. PPO imposes the constraint by forcing $r(\theta)$ to stay within a small interval around 1, precisely $[1-\epsilon, 1+\epsilon]$, where $\epsilon$ is a hyperparameter.

$$
J^\text{CLIP} (\theta) = \mathbb{E} [ \min( r(\theta) \hat{A}_{\theta_\text{old}}(s, a), \text{clip}(r(\theta), 1 - \epsilon, 1 + \epsilon) \hat{A}_{\theta_\text{old}}(s, a))]
$$

函数$\text{clip}(r(\theta), 1 - \epsilon, 1 + \epsilon)$将比率裁剪为不大于$1+\epsilon$且不小于$1-\epsilon$。PPO的目标函数取原始值和裁剪版本中的最小值，因此我们失去了为了获得更好奖励而将策略更新推向极端的动机。

> The function $\text{clip}(r(\theta), 1 - \epsilon, 1 + \epsilon)$ clips the ratio to be no more than $1+\epsilon$ and no less than $1-\epsilon$. The objective function of PPO takes the minimum one between the original value and the clipped version and therefore we lose the motivation for increasing the policy update to extremes for better rewards.

当在策略（actor）和价值（critic）函数共享参数的网络架构上应用PPO时，除了裁剪奖励之外，目标函数还通过价值估计的误差项（红色公式）和熵项（蓝色公式）进行增强，以鼓励充分探索。

> When applying PPO on the network architecture with shared parameters for both policy (actor) and value (critic) functions, in addition to the clipped reward, the objective function is augmented with an error term on the value estimation (formula in red) and an entropy term (formula in blue) to encourage sufficient exploration.

$$
J^\text{CLIP'} (\theta) = \mathbb{E} [ J^\text{CLIP} (\theta) - \color{red}{c_1 (V_\theta(s) - V_\text{target})^2} + \color{blue}{c_2 H(s, \pi_\theta(.))} ]
$$

其中$c_1$和$c_2$都是两个超参数常数。

> where Both $c_1$ and $c_2$ are two hyperparameter constants.

PPO已在一系列基准任务上进行了测试，并被证明以更高的简洁性产生了出色的结果。

> PPO has been tested on a set of benchmark tasks and proved to produce awesome results with much greater simplicity.

在[Hsu et al., 2020](https://arxiv.org/abs/2009.10897)后来的一篇论文中，PPO的两个常见设计选择被重新审视，即（1）用于策略正则化的裁剪概率比和（2）通过连续高斯或离散softmax分布参数化策略动作空间。他们首先确定了PPO中的三种失效模式，并提出了这两种设计的替代方案。

> In a later paper by [Hsu et al., 2020](https://arxiv.org/abs/2009.10897), two common design choices in PPO are revisited, precisely (1) clipped probability ratio for policy regularization and (2) parameterize policy action space by continuous Gaussian or discrete softmax distribution. They first identified three failure modes in PPO and proposed replacements for these two designs.

失效模式包括：

> The failure modes are:

1. 在连续动作空间中，当奖励在有界支持之外消失时，标准PPO不稳定。
2. 在具有稀疏高奖励的离散动作空间中，标准PPO经常停留在次优动作上。
3. 当存在接近初始化的局部最优动作时，策略对初始化敏感。

> • On continuous action spaces, standard PPO is unstable when rewards vanish outside bounded support.
> • On discrete action spaces with sparse high rewards, standard PPO often gets stuck at suboptimal actions.
> • The policy is sensitive to initialization when there are locally optimal actions close to initialization.

离散化动作空间或使用Beta分布有助于避免与高斯策略相关的失效模式1和3。使用KL正则化（与[TRPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#trpo)中的动机相同）作为替代代理模型有助于解决失效模式1和2。

> Discretizing the action space or use Beta distribution helps avoid failure mode 1&3 associated with Gaussian policy. Using KL regularization (same motivation as in [TRPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#trpo)) as an alternative surrogate model helps resolve failure mode 1&2.

![The algorithm of PPG. (Image source: Cobbe, et al 2020 )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/ppo-loss-functions.png)

#### PPG

> PPG

[[论文](https://arxiv.org/abs/2009.04416)|[代码](https://github.com/openai/phasic-policy-gradient)]

> [[paper](https://arxiv.org/abs/2009.04416)|[code](https://github.com/openai/phasic-policy-gradient)]

策略网络和价值网络之间共享参数有利有弊。它允许策略和价值函数相互共享学习到的特征，但可能导致竞争目标之间的冲突，并要求同时使用相同的数据来训练两个网络。**分阶段策略梯度**（**PPG**；[Cobbe, et al 2020](https://arxiv.org/abs/2009.04416)）修改了传统的在策略[actor-critic](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#actor-critic)策略梯度算法，特别是[PPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo)，使其具有独立的策略和价值函数训练阶段。在两个交替阶段中：

> Sharing parameters between policy and value networks have pros and cons. It allows policy and value functions to share the learned features with each other, but it may cause conflicts between competing objectives and demands the same data for training two networks at the same time. **Phasic policy gradient** (**PPG**; [Cobbe, et al 2020](https://arxiv.org/abs/2009.04416)) modifies the traditional on-policy [actor-critic](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#actor-critic) policy gradient algorithm. precisely [PPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo), to have separate training phases for policy and value functions. In two alternating phases:

1\. *策略阶段*：通过优化PPO[目标](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo_loss)$L^\text{CLIP} (\theta)$来更新策略网络；

2\. *辅助阶段*：优化一个辅助目标以及行为克隆损失。在论文中，价值函数误差是唯一的辅助目标，但它可以非常通用，并包括任何其他额外的辅助损失。

英文原文：

1\. The *policy phase*: updates the policy network by optimizing the PPO [objective](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo_loss) $L^\text{CLIP} (\theta)$;

2\. The *auxiliary phase*: optimizes an auxiliary objective alongside a behavioral cloning loss. In the paper, value function error is the sole auxiliary objective, but it can be quite general and includes any other additional auxiliary losses.

$$
\begin{aligned}
L^\text{joint} &= L^\text{aux} + \beta_\text{clone} \cdot \mathbb{E}_t[\text{KL}[\pi_{\theta_\text{old}}(\cdot\mid s_t), \pi_\theta(\cdot\mid s_t)]] \\
L^\text{aux} &= L^\text{value} = \mathbb{E}_t \big[\frac{1}{2}\big( V_w(s_t) - \hat{V}_t^\text{targ} \big)^2\big]
\end{aligned}
$$

其中$\beta_\text{clone}$是一个超参数，用于控制在优化辅助目标时，我们希望策略不偏离其原始行为的程度。

> where $\beta_\text{clone}$ is a hyperparameter for controlling how much we would like to keep the policy not diverge too much from its original behavior while optimizing the auxiliary objectives.

![The algorithm of PPG. (Image source: Cobbe, et al 2020 )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/PPG_algo.png)

其中

> where

• $N_\pi$是策略阶段中策略更新的迭代次数。请注意，策略阶段在每个辅助阶段执行多次更新迭代。

• $E_\pi$和$E_V$分别控制策略和价值函数的样本重用（即在回复缓冲区中对数据执行的训练周期数）。请注意，这发生在策略阶段内，因此$E_V$影响的是真实价值函数的学习，而不是辅助价值函数。

• $E_\text{aux}$定义了辅助阶段中的样本重用。在PPG中，价值函数优化可以容忍更高水平的样本重用；例如，在论文的实验中，$E_\text{aux} = 6$而$E_\pi = E_V = 1$。

英文原文：

• $N_\pi$ is the number of policy update iterations in the policy phase. Note that the policy phase performs multiple iterations of updates per single auxiliary phase.

• $E_\pi$ and $E_V$ control the sample reuse (i.e. the number of training epochs performed across data in the reply buffer) for the policy and value functions, respectively. Note that this happens within the policy phase and thus $E_V$ affects the learning of true value function not the auxiliary value function.

• $E_\text{aux}$ defines the sample reuse in the auxiliary phrase. In PPG, value function optimization can tolerate a much higher level sample reuse; for example, in the experiments of the paper, $E_\text{aux} = 6$ while $E_\pi = E_V = 1$.

与PPO相比，PPG在样本效率方面取得了显著提升。

> PPG leads to a significant improvement on sample efficiency compared to PPO.

![The mean normalized performance of PPG vs PPO on the Procgen benchmark. (Image source: Cobbe, et al 2020 )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/PPG_exp.png)

#### ACER

> ACER

[[论文](https://arxiv.org/pdf/1611.01224.pdf)|[代码](https://github.com/openai/baselines/tree/master/baselines/acer)]

> [[paper](https://arxiv.org/pdf/1611.01224.pdf)|[code](https://github.com/openai/baselines/tree/master/baselines/acer)]

**ACER**，全称**带经验回放的Actor-Critic**（[Wang等人，2017](https://arxiv.org/pdf/1611.01224.pdf)），是一种带有经验回放的离策略Actor-Critic模型，它极大地提高了样本效率并降低了数据相关性。A3C为ACER奠定了基础，但它是同策略的；ACER是A3C的离策略对应物。使A3C成为离策略的主要障碍是如何控制离策略估计器的稳定性。ACER提出了三种设计来克服这个问题：

> **ACER**, short for **actor-critic with experience replay** ([Wang, et al., 2017](https://arxiv.org/pdf/1611.01224.pdf)), is an off-policy actor-critic model with experience replay, greatly increasing the sample efficiency and decreasing the data correlation. A3C builds up the foundation for ACER, but it is on policy; ACER is A3C’s off-policy counterpart. The major obstacle to making A3C off policy is how to control the stability of the off-policy estimator. ACER proposes three designs to overcome it:

- 使用Retrace Q值估计；
- 截断重要性权重并进行偏差校正；
- 应用高效的TRPO。

> • Use Retrace Q-value estimation;
> • Truncate the importance weights with bias correction;
> • Apply efficient TRPO.

**Retrace Q值估计**

> **Retrace Q-value Estimation**

[Retrace](http://papers.nips.cc/paper/6538-safe-and-efficient-off-policy-reinforcement-learning.pdf)是一种基于离策略回报的Q值估计算法，它对任何目标策略和行为策略对$(\pi, \beta)$的收敛性都有很好的保证，并且具有良好的数据效率。

> [Retrace](http://papers.nips.cc/paper/6538-safe-and-efficient-off-policy-reinforcement-learning.pdf) is an off-policy return-based Q-value estimation algorithm with a nice guarantee for convergence for any target and behavior policy pair $(\pi, \beta)$, plus good data efficiency.

回顾TD学习如何进行预测：

> Recall how TD learning works for prediction:

1\. 计算TD误差：$\delta_t = R_t + \gamma \mathbb{E}_{a \sim \pi} Q(S_{t+1}, a) - Q(S_t, A_t)$；术语$r_t + \gamma \mathbb{E}_{a \sim \pi} Q(s_{t+1}, a)$被称为“TD目标”。使用期望$\mathbb{E}_{a \sim \pi}$是因为对于未来的步骤，我们能做出的最佳估计是如果我们遵循当前策略$\pi$，回报会是多少。

2\. 通过纠正误差来更新值以趋向目标：$Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha \delta_t$。换句话说，Q的增量更新与TD误差成比例：$\Delta Q(S_t, A_t) = \alpha \delta_t$。

英文原文：

1\. Compute TD error: $\delta_t = R_t + \gamma \mathbb{E}_{a \sim \pi} Q(S_{t+1}, a) - Q(S_t, A_t)$; the term $r_t + \gamma \mathbb{E}_{a \sim \pi} Q(s_{t+1}, a)$ is known as “TD target”. The expectation $\mathbb{E}_{a \sim \pi}$ is used because for the future step the best estimation we can make is what the return would be if we follow the current policy $\pi$.

2\. Update the value by correcting the error to move toward the goal: $Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha \delta_t$. In other words, the incremental update on Q is proportional to the TD error: $\Delta Q(S_t, A_t) = \alpha \delta_t$.

当rollout是离策略时，我们需要在Q更新上应用重要性采样：

> When the rollout is off policy, we need to apply importance sampling on the Q update:

$$
\Delta Q^\text{imp}(S_t, A_t) 
= \gamma^t \prod_{1 \leq \tau \leq t} \frac{\pi(A_\tau \vert S_\tau)}{\beta(A_\tau \vert S_\tau)} \delta_t
$$

当我们开始想象重要性权重的乘积如何导致超高方差甚至爆炸时，这看起来相当可怕。Retrace Q值估计方法修改了$\Delta Q$，使重要性权重被截断，不超过常数$c$：

> The product of importance weights looks pretty scary when we start imagining how it can cause super high variance and even explode. Retrace Q-value estimation method modifies $\Delta Q$ to have importance weights truncated by no more than a constant $c$:

$$
\Delta Q^\text{ret}(S_t, A_t) 
= \gamma^t \prod_{1 \leq \tau \leq t} \min(c, \frac{\pi(A_\tau \vert S_\tau)}{\beta(A_\tau \vert S_\tau)})  \delta_t
$$

ACER使用$Q^\text{ret}$作为目标，通过最小化L2误差项$(Q^\text{ret}(s, a) - Q(s, a))^2$来训练评论家。

> ACER uses $Q^\text{ret}$ as the target to train the critic by minimizing the L2 error term: $(Q^\text{ret}(s, a) - Q(s, a))^2$.

**重要性权重截断**

> **Importance weights truncation**

为了降低策略梯度$\hat{g}$的高方差，ACER将重要性权重截断为一个常数c，并加上一个校正项。标签$\hat{g}_t^\text{acer}$是时间t的ACER策略梯度。

> To reduce the high variance of the policy gradient $\hat{g}$, ACER truncates the importance weights by a constant c, plus a correction term. The label $\hat{g}_t^\text{acer}$ is the ACER policy gradient at time t.

$$
\begin{aligned}
\hat{g}_t^\text{acer}
= & \omega_t \big( Q^\text{ret}(S_t, A_t) - V_{\theta_v}(S_t) \big) \nabla_\theta \ln \pi_\theta(A_t \vert S_t) 
  & \scriptstyle{\text{; Let }\omega_t=\frac{\pi(A_t \vert S_t)}{\beta(A_t \vert S_t)}} \\
= & \color{blue}{\min(c, \omega_t) \big( Q^\text{ret}(S_t, A_t) - V_w(S_t) \big) \nabla_\theta \ln \pi_\theta(A_t \vert S_t)} \\
  & + \color{red}{\mathbb{E}_{a \sim \pi} \big[ \max(0, \frac{\omega_t(a) - c}{\omega_t(a)}) \big( Q_w(S_t, a) - V_w(S_t) \big) \nabla_\theta \ln \pi_\theta(a \vert S_t) \big]}
  & \scriptstyle{\text{; Let }\omega_t (a) =\frac{\pi(a \vert S_t)}{\beta(a \vert S_t)}}
\end{aligned}
$$

其中$Q_w(.)$和$V_w(.)$是评论家使用参数w预测的值函数。第一项（蓝色）包含截断后的重要权重。截断有助于降低方差，此外还减去了状态值函数$V_w(.)$作为基线。第二项（红色）进行校正以实现无偏估计。

> where $Q_w(.)$ and $V_w(.)$ are value functions predicted by the critic with parameter w. The first term (blue) contains the clipped important weight. The clipping helps reduce the variance, in addition to subtracting state value function $V_w(.)$ as a baseline. The second term (red) makes a correction to achieve unbiased estimation.

**高效TRPO**

> **Efficient TRPO**

此外，ACER采纳了TRPO的思想，但做了一个小调整以使其计算效率更高：ACER不是测量一次更新前后策略之间的KL散度，而是维护过去策略的运行平均值，并强制更新后的策略不偏离这个平均值太远。

> Furthermore, ACER adopts the idea of TRPO but with a small adjustment to make it more computationally efficient: rather than measuring the KL divergence between policies before and after one update, ACER maintains a running average of past policies and forces the updated policy to not deviate far from this average.

ACER[论文](https://arxiv.org/pdf/1611.01224.pdf)内容相当密集，包含许多公式。希望凭借对TD学习、Q学习、重要性采样和TRPO的先验知识，你会发现这篇[论文](https://arxiv.org/pdf/1611.01224.pdf)稍微更容易理解 :)

> The ACER [paper](https://arxiv.org/pdf/1611.01224.pdf) is pretty dense with many equations. Hopefully, with the prior knowledge on TD learning, Q-learning, importance sampling and TRPO, you will find the [paper](https://arxiv.org/pdf/1611.01224.pdf) slightly easier to follow :)

#### ACTKR

> ACTKR

[[论文](https://arxiv.org/pdf/1708.05144.pdf)|[代码](https://github.com/openai/baselines/tree/master/baselines/acktr)]

> [[paper](https://arxiv.org/pdf/1708.05144.pdf)|[code](https://github.com/openai/baselines/tree/master/baselines/acktr)]

**ACKTR（使用Kronecker因子化信任区域的Actor-Critic）**（[Yuhuai Wu等人，2017](https://arxiv.org/pdf/1708.05144.pdf)）提出使用Kronecker因子化近似曲率（[K-FAC](https://arxiv.org/pdf/1503.05671.pdf)）来对评论家和行动者进行梯度更新。K-FAC改进了*自然梯度*的计算，这与我们的*标准梯度*有很大不同。[这里](http://kvfrans.com/a-intuitive-explanation-of-natural-gradient-descent/)有一个关于自然梯度的很好、很直观的解释。一句话总结可能是：

> **ACKTR (actor-critic using Kronecker-factored trust region)** ([Yuhuai Wu, et al., 2017](https://arxiv.org/pdf/1708.05144.pdf)) proposed to use Kronecker-factored approximation curvature ([K-FAC](https://arxiv.org/pdf/1503.05671.pdf)) to do the gradient update for both the critic and actor. K-FAC made an improvement on the computation of *natural gradient*, which is quite different from our *standard gradient*. [Here](http://kvfrans.com/a-intuitive-explanation-of-natural-gradient-descent/) is a nice, intuitive explanation of natural gradient. One sentence summary is probably:

> “我们首先考虑所有参数组合，这些组合会使新网络与旧网络之间保持恒定的KL散度。这个常数值可以被视为步长或学习率。在所有这些可能的组合中，我们选择使损失函数最小化的那个。”

> “we first consider all combinations of parameters that result in a new network a constant KL divergence away from the old network. This constant value can be viewed as the step size or learning rate. Out of all these possible combinations, we choose the one that minimizes our loss function.”

我在这里列出 ACTKR 主要是为了本文的完整性，但我不会深入细节，因为它涉及大量关于自然梯度和优化方法的理论知识。如果感兴趣，在阅读 ACKTR 论文之前，请查阅这些论文/帖子：

> I listed ACTKR here mainly for the completeness of this post, but I would not dive into details, as it involves a lot of theoretical knowledge on natural gradient and optimization methods. If interested, check these papers/posts, before reading the ACKTR paper:

- Amari. [自然梯度在学习中高效工作](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.452.7280&rep=rep1&type=pdf). 1998
- Kakade. [一种自然策略梯度](https://papers.nips.cc/paper/2073-a-natural-policy-gradient.pdf). 2002
- [自然梯度下降的直观解释](http://kvfrans.com/a-intuitive-explanation-of-natural-gradient-descent/)
- [维基百科：克罗内克积](https://en.wikipedia.org/wiki/Kronecker_product)
- Martens & Grosse. [使用克罗内克因子近似曲率优化神经网络。](http://proceedings.mlr.press/v37/martens15.pdf) 2015.

> • Amari. [Natural Gradient Works Efficiently in Learning](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.452.7280&rep=rep1&type=pdf). 1998
> • Kakade. [A Natural Policy Gradient](https://papers.nips.cc/paper/2073-a-natural-policy-gradient.pdf). 2002
> • [A intuitive explanation of natural gradient descent](http://kvfrans.com/a-intuitive-explanation-of-natural-gradient-descent/)
> • [Wiki: Kronecker product](https://en.wikipedia.org/wiki/Kronecker_product)
> • Martens & Grosse. [Optimizing neural networks with kronecker-factored approximate curvature.](http://proceedings.mlr.press/v37/martens15.pdf) 2015.

这是 K-FAC [论文](https://arxiv.org/pdf/1503.05671.pdf)中的一个高层总结：

> Here is a high level summary from the K-FAC [paper](https://arxiv.org/pdf/1503.05671.pdf):

> “这种近似分两个阶段构建。首先，Fisher 矩阵的行和列被分成组，每组对应于给定层中的所有权重，这导致了矩阵的块划分。然后，这些块被近似为小得多的矩阵之间的克罗内克积，我们表明这等同于对网络梯度的统计数据做出某些近似假设。

> “This approximation is built in two stages. In the first, the rows and columns of the Fisher are divided into groups, each of which corresponds to all the weights in a given layer, and this gives rise to a block-partitioning of the matrix. These blocks are then approximated as Kronecker products between much smaller matrices, which we show is equivalent to making certain approximating assumptions regarding the statistics of the network’s gradients.

> 在第二阶段，该矩阵被进一步近似为具有块对角或块三对角逆矩阵。我们通过仔细检查逆协方差、树状图模型和线性回归之间的关系来证明这种近似的合理性。值得注意的是，这种证明不适用于 Fisher 矩阵本身，我们的实验证实，虽然逆 Fisher 矩阵确实具有这种结构（近似地），但 Fisher 矩阵本身不具备。”

> In the second stage, this matrix is further approximated as having an inverse which is either block-diagonal or block-tridiagonal. We justify this approximation through a careful examination of the relationships between inverse covariances, tree-structured graphical models, and linear regression. Notably, this justification doesn’t apply to the Fisher itself, and our experiments confirm that while the inverse Fisher does indeed possess this structure (approximately), the Fisher itself does not.”

#### SAC

> SAC

[[论文](https://arxiv.org/abs/1801.01290)|[代码](https://github.com/haarnoja/sac)]

> [[paper](https://arxiv.org/abs/1801.01290)|[code](https://github.com/haarnoja/sac)]

**软行动者-评论家 (SAC)** ([Haarnoja 等人 2018](https://arxiv.org/abs/1801.01290)) 将策略的熵度量纳入奖励中以鼓励探索：我们期望学习一个尽可能随机行动但仍能成功完成任务的策略。它是一个遵循最大熵强化学习框架的离策略行动者-评论家模型。一项先前的研究是 [软 Q 学习](https://arxiv.org/abs/1702.08165)。

> **Soft Actor-Critic (SAC)** ([Haarnoja et al. 2018](https://arxiv.org/abs/1801.01290)) incorporates the entropy measure of the policy into the reward to encourage exploration: we expect to learn a policy that acts as randomly as possible while it is still able to succeed at the task. It is an off-policy actor-critic model following the maximum entropy reinforcement learning framework. A precedent work is [Soft Q-learning](https://arxiv.org/abs/1702.08165).

SAC 中的三个关键组成部分：

> Three key components in SAC:

- 一个具有独立策略网络和价值函数网络的 [actor-critic](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#actor-critic) 架构；
- 一个 [off-policy](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#off-policy-policy-gradient) 公式，能够重用先前收集的数据以提高效率；
- 熵最大化以实现稳定性和探索。

> • An [actor-critic](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#actor-critic) architecture with separate policy and value function networks;
> • An [off-policy](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#off-policy-policy-gradient) formulation that enables reuse of previously collected data for efficiency;
> • Entropy maximization to enable stability and exploration.

策略的训练目标是同时最大化预期回报和熵：

> The policy is trained with the objective to maximize the expected return and the entropy at the same time:

$$
J(\theta) = \sum_{t=1}^T \mathbb{E}_{(s_t, a_t) \sim \rho_{\pi_\theta}} [r(s_t, a_t) + \alpha \mathcal{H}(\pi_\theta(.\vert s_t))]
$$

其中 $\mathcal{H}(.)$ 是熵度量，$\alpha$ 控制熵项的重要性，被称为 *温度* 参数。熵最大化导致策略能够 (1) 进行更多探索，以及 (2) 捕获近乎最优策略的多种模式（即，如果存在多个看起来同样好的选项，策略应该以相等的概率选择每个选项）。

> where $\mathcal{H}(.)$ is the entropy measure and $\alpha$ controls how important the entropy term is, known as *temperature* parameter. The entropy maximization leads to policies that can (1) explore more and (2) capture multiple modes of near-optimal strategies (i.e., if there exist multiple options that seem to be equally good, the policy should assign each with an equal probability to be chosen).

具体来说，SAC 旨在学习三个函数：

> Precisely, SAC aims to learn three functions:

• 带有参数 $\theta$ 的策略，$\pi_\theta$。

• 由 $w$ 参数化的软 Q 值函数，$Q_w$。

• 软状态值函数由$\psi$、$V_\psi$；理论上我们可以推断出$V$通过了解$Q$和$\pi$，但在实践中，它有助于稳定训练。

英文原文：

• The policy with parameter $\theta$, $\pi_\theta$.

• Soft Q-value function parameterized by $w$, $Q_w$.

• Soft state value function parameterized by $\psi$, $V_\psi$; theoretically we can infer $V$ by knowing $Q$ and $\pi$, but in practice, it helps stabilize the training.

软Q值和软状态值定义为：

> Soft Q-value and soft state value are defined as:

$$
\begin{aligned}
Q(s_t, a_t) &= r(s_t, a_t) + \gamma \mathbb{E}_{s_{t+1} \sim \rho_{\pi}(s)} [V(s_{t+1})] & \text{; according to Bellman equation.}\\
\text{where }V(s_t) &= \mathbb{E}_{a_t \sim \pi} [Q(s_t, a_t) - \alpha \log \pi(a_t \vert s_t)] & \text{; soft state value function.}
\end{aligned}
$$

$$
\text{Thus, } Q(s_t, a_t) = r(s_t, a_t) + \gamma \mathbb{E}_{(s_{t+1}, a_{t+1}) \sim \rho_{\pi}} [Q(s_{t+1}, a_{t+1}) - \alpha \log \pi(a_{t+1} \vert s_{t+1})]
$$

$\rho_\pi(s)$ 和 $\rho_\pi(s, a)$ 表示策略 $\pi(a \vert s)$ 引起的状态分布的状态和状态-动作边际；请参阅 [DPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg) 部分中的类似定义。

> $\rho_\pi(s)$ and $\rho_\pi(s, a)$ denote the state and the state-action marginals of the state distribution induced by the policy $\pi(a \vert s)$; see the similar definitions in [DPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg) section.

软状态值函数经过训练以最小化均方误差：

> The soft state value function is trained to minimize the mean squared error:

$$
\begin{aligned}
J_V(\psi) &= \mathbb{E}_{s_t \sim \mathcal{D}} [\frac{1}{2} \big(V_\psi(s_t) - \mathbb{E}[Q_w(s_t, a_t) - \log \pi_\theta(a_t \vert s_t)] \big)^2] \\
\text{with gradient: }\nabla_\psi J_V(\psi) &= \nabla_\psi V_\psi(s_t)\big( V_\psi(s_t) - Q_w(s_t, a_t) + \log \pi_\theta (a_t \vert s_t) \big)
\end{aligned}
$$

其中 $\mathcal{D}$ 是重放缓冲区。

> where $\mathcal{D}$ is the replay buffer.

软 Q 函数的训练目标是最小化软贝尔曼残差：

> The soft Q function is trained to minimize the soft Bellman residual:

$$
\begin{aligned}
J_Q(w) &= \mathbb{E}_{(s_t, a_t) \sim \mathcal{D}} [\frac{1}{2}\big( Q_w(s_t, a_t) - (r(s_t, a_t) + \gamma \mathbb{E}_{s_{t+1} \sim \rho_\pi(s)}[V_{\bar{\psi}}(s_{t+1})]) \big)^2] \\
\text{with gradient: } \nabla_w J_Q(w) &= \nabla_w Q_w(s_t, a_t) \big( Q_w(s_t, a_t) - r(s_t, a_t) - \gamma V_{\bar{\psi}}(s_{t+1})\big) 
\end{aligned}
$$

其中 $\bar{\psi}$ 是目标值函数，它是指数移动平均（或者只以“硬”方式定期更新），就像在 [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network) 中处理目标 Q 网络的参数以稳定训练一样。

> where $\bar{\psi}$ is the target value function which is the exponential moving average (or only gets updated periodically in a “hard” way), just like how the parameter of the target Q network is treated in [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network) to stabilize the training.

SAC 更新策略以最小化 [KL 散度](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)：

> SAC updates the policy to minimize the [KL-divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence):

$$
\begin{aligned}
\pi_\text{new} 
&= \arg\min_{\pi' \in \Pi} D_\text{KL} \Big( \pi'(.\vert s_t) \| \frac{\exp(Q^{\pi_\text{old}}(s_t, .))}{Z^{\pi_\text{old}}(s_t)} \Big) \\[6pt]
&= \arg\min_{\pi' \in \Pi} D_\text{KL} \big( \pi'(.\vert s_t) \| \exp(Q^{\pi_\text{old}}(s_t, .) - \log Z^{\pi_\text{old}}(s_t)) \big) \\[6pt]
\text{objective for update: } J_\pi(\theta) &= \nabla_\theta D_\text{KL} \big( \pi_\theta(. \vert s_t) \| \exp(Q_w(s_t, .) - \log Z_w(s_t)) \big) \\[6pt]
&= \mathbb{E}_{a_t\sim\pi} \Big[ - \log \big( \frac{\exp(Q_w(s_t, a_t) - \log Z_w(s_t))}{\pi_\theta(a_t \vert s_t)} \big) \Big] \\[6pt]
&= \mathbb{E}_{a_t\sim\pi} [ \log \pi_\theta(a_t \vert s_t) - Q_w(s_t, a_t) + \log Z_w(s_t) ]
\end{aligned}
$$

其中 $\Pi$ 是潜在策略的集合，我们可以将我们的策略建模为其中之一以使其易于处理；例如，$\Pi$ 可以是高斯混合分布族，建模成本高但表达能力强且仍然易于处理。$Z^{\pi_\text{old}}(s_t)$ 是用于归一化分布的配分函数。它通常难以处理，但对梯度没有贡献。如何最小化 $J_\pi(\theta)$ 取决于我们对 $\Pi$ 的选择。

> where $\Pi$ is the set of potential policies that we can model our policy as to keep them tractable; for example, $\Pi$ can be the family of Gaussian mixture distributions, expensive to model but highly expressive and still tractable. $Z^{\pi_\text{old}}(s_t)$ is the partition function to normalize the distribution. It is usually intractable but does not contribute to the gradient. How to minimize $J_\pi(\theta)$ depends our choice of $\Pi$.

此更新保证 $Q^{\pi_\text{new}}(s_t, a_t) \geq Q^{\pi_\text{old}}(s_t, a_t)$，请查阅原始 [论文](https://arxiv.org/abs/1801.01290) 附录 B.2 中关于此引理的证明。

> This update guarantees that $Q^{\pi_\text{new}}(s_t, a_t) \geq Q^{\pi_\text{old}}(s_t, a_t)$, please check the proof on this lemma in the Appendix B.2 in the original [paper](https://arxiv.org/abs/1801.01290).

一旦我们定义了软动作-状态值、软状态值和策略网络的目标函数和梯度，软 Actor-Critic 算法就变得简单明了：

> Once we have defined the objective functions and gradients for soft action-state value, soft state value and the policy network, the soft actor-critic algorithm is straightforward:

![The soft actor-critic algorithm. (Image source: original paper )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/SAC_algo.png)

#### 具有自动调整温度的 SAC

> SAC with Automatically Adjusted Temperature

[[论文](https://arxiv.org/abs/1812.05905)|[代码](https://github.com/rail-berkeley/softlearning)]

> [[paper](https://arxiv.org/abs/1812.05905)|[code](https://github.com/rail-berkeley/softlearning)]

SAC 对温度参数很敏感。不幸的是，温度很难调整，因为熵在不同任务之间以及在训练过程中随着策略的改进都可能发生不可预测的变化。SAC 的一项改进提出了一种约束优化问题：在最大化预期回报的同时，策略应满足最小熵约束：

> SAC is brittle with respect to the temperature parameter. Unfortunately it is difficult to adjust temperature, because the entropy can vary unpredictably both across tasks and during training as the policy becomes better. An improvement on SAC formulates a constrained optimization problem: while maximizing the expected return, the policy should satisfy a minimum entropy constraint:

$$
\max_{\pi_0, \dots, \pi_T} \mathbb{E} \Big[ \sum_{t=0}^T r(s_t, a_t)\Big] \text{s.t. } \forall t\text{, } \mathcal{H}(\pi_t) \geq \mathcal{H}_0
$$

其中 $\mathcal{H}_0$ 是预定义的最小策略熵阈值。

> where $\mathcal{H}_0$ is a predefined minimum policy entropy threshold.

预期回报 $\mathbb{E} \Big[ \sum_{t=0}^T r(s_t, a_t)\Big]$ 可以分解为所有时间步的奖励之和。由于时间 t 的策略 `\pi_t` 对较早时间步的策略 `\pi_{t-1}` 没有影响，我们可以反向在不同时间步最大化回报——这本质上是 **DP**。

英文原文：The expected return 

$\mathbb{E} \Big[ \sum_{t=0}^T r(s_t, a_t)\Big]$ can be decomposed into a sum of rewards at all the time steps. Because the policy `\pi_t` at time t has no effect on the policy at the earlier time step, `\pi_{t-1}`, we can maximize the return at different steps backward in time — this is essentially DP.

$$
\underbrace{\max_{\pi_0} \Big( \mathbb{E}[r(s_0, a_0)]+ \underbrace{\max_{\pi_1} \Big(\mathbb{E}[...] + \underbrace{\max_{\pi_T} \mathbb{E}[r(s_T, a_T)]}_\text{1st maximization} \Big)}_\text{second but last maximization} \Big)}_\text{last maximization}
$$

其中我们考虑$\gamma=1$。

> where we consider $\gamma=1$.

因此我们从最后一个时间步开始优化$T$：

> So we start the optimization from the last timestep $T$:

$$
\text{maximize } \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [ r(s_T, a_T) ] \text{ s.t. } \mathcal{H}(\pi_T) - \mathcal{H}_0 \geq 0
$$

首先，让我们定义以下函数：

> First, let us define the following functions:

$$
\begin{aligned}
h(\pi_T) &= \mathcal{H}(\pi_T) - \mathcal{H}_0 = \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [-\log \pi_T(a_T\vert s_T)] - \mathcal{H}_0\\
f(\pi_T) &= \begin{cases}
\mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [ r(s_T, a_T) ], & \text{if }h(\pi_T) \geq 0 \\
-\infty, & \text{otherwise}
\end{cases}
\end{aligned}
$$

优化变为：

> And the optimization becomes:

$$
\text{maximize } f(\pi_T) \text{ s.t. } h(\pi_T) \geq 0
$$

为了解决带不等式约束的最大化优化问题，我们可以构建一个[拉格朗日表达式](https://cs.stanford.edu/people/davidknowles/lagrangian_duality.pdf)，并引入拉格朗日乘数（也称为“对偶变量”），$\alpha_T$：

> To solve the maximization optimization with inequality constraint, we can construct a [Lagrangian expression](https://cs.stanford.edu/people/davidknowles/lagrangian_duality.pdf) with a Lagrange multiplier (also known as “dual variable”), $\alpha_T$:

$$
L(\pi_T, \alpha_T) = f(\pi_T) + \alpha_T h(\pi_T)
$$

考虑我们尝试*最小化$L(\pi_T, \alpha_T)$关于$\alpha_T$*的情况——给定一个特定值$\pi_T$，

> Considering the case when we try to *minimize $L(\pi_T, \alpha_T)$ with respect to $\alpha_T$* - given a particular value $\pi_T$,

• 如果约束条件得到满足，$h(\pi_T) \geq 0$，我们最多可以设置$\alpha_T=0$，因为我们无法控制$f(\pi_T)$的值。因此，$L(\pi_T, 0) = f(\pi_T)$。

• 如果约束失效，$h(\pi_T) < 0$，我们可以实现$L(\pi_T, \alpha_T) \to -\infty$通过采取$\alpha_T \to \infty$。因此，$L(\pi_T, \infty) = -\infty = f(\pi_T)$。

英文原文：

• If the constraint is satisfied, $h(\pi_T) \geq 0$, at best we can set $\alpha_T=0$ since we have no control over the value of $f(\pi_T)$. Thus, $L(\pi_T, 0) = f(\pi_T)$.

• If the constraint is invalidated, $h(\pi_T) < 0$, we can achieve $L(\pi_T, \alpha_T) \to -\infty$ by taking  $\alpha_T \to \infty$. Thus, $L(\pi_T, \infty) = -\infty = f(\pi_T)$.

在任何一种情况下，我们都可以得到以下方程，

> In either case, we can recover the following equation,

$$
f(\pi_T) = \min_{\alpha_T \geq 0} L(\pi_T, \alpha_T)
$$

同时，我们希望最大化 $f(\pi_T)$，

> At the same time, we want to maximize $f(\pi_T)$,

$$
\max_{\pi_T} f(\pi_T) = \min_{\alpha_T \geq 0} \max_{\pi_T} L(\pi_T, \alpha_T)
$$

因此，为了最大化 $f(\pi_T)$，对偶问题列举如下。请注意，为确保 $\max_{\pi_T} f(\pi_T)$ 得到适当最大化且不会变为 $-\infty$，必须满足该约束。

> Therefore, to maximize $f(\pi_T)$, the dual problem is listed as below. Note that to make sure $\max_{\pi_T} f(\pi_T)$ is properly maximized and would not become $-\infty$, the constraint has to be satisfied.

$$
\begin{aligned}
\max_{\pi_T} \mathbb{E}[ r(s_T, a_T) ]
&= \max_{\pi_T} f(\pi_T) \\
&= \min_{\alpha_T \geq 0}  \max_{\pi_T} L(\pi_T, \alpha_T) \\
&= \min_{\alpha_T \geq 0}  \max_{\pi_T} f(\pi_T) + \alpha_T h(\pi_T) \\ 
&= \min_{\alpha_T \geq 0}  \max_{\pi_T} \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [ r(s_T, a_T) ] + \alpha_T ( \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [-\log \pi_T(a_T\vert s_T)] - \mathcal{H}_0) \\ 
&= \min_{\alpha_T \geq 0}  \max_{\pi_T} \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [ r(s_T, a_T)  - \alpha_T \log \pi_T(a_T\vert s_T)] - \alpha_T \mathcal{H}_0 \\
&= \min_{\alpha_T \geq 0}  \max_{\pi_T} \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [ r(s_T, a_T)  + \alpha_T \mathcal{H}(\pi_T) - \alpha_T \mathcal{H}_0 ]
\end{aligned}
$$

我们可以计算出最优的$\pi_T$和$\alpha_T$。迭代地进行。首先，给定当前的$\alpha_T$，得到最优策略$\pi_T^{*}$，使其最大化$L(\pi_T^{*}, \alpha_T)$。然后代入$\pi_T^{*}$并计算$\alpha_T^{*}$，使其最小化$L(\pi_T^{*}, \alpha_T)$。假设我们有一个用于策略的神经网络和一个用于温度参数的网络，那么这种迭代更新过程与我们在训练期间更新网络参数的方式更为一致。

> We could compute the optimal $\pi_T$ and $\alpha_T$ iteratively. First given the current $\alpha_T$, get the best policy $\pi_T^{*}$ that maximizes $L(\pi_T^{*}, \alpha_T)$. Then plug in $\pi_T^{*}$ and compute $\alpha_T^{*}$ that minimizes $L(\pi_T^{*}, \alpha_T)$. Assuming we have one neural network for policy and one network for temperature parameter, the iterative update process is more aligned with how we update network parameters during training.

$$
\begin{aligned}
\pi^{*}_T
&= \arg\max_{\pi_T} \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi}} [ r(s_T, a_T)  + \alpha_T \mathcal{H}(\pi_T) - \alpha_T \mathcal{H}_0 ] \\
\color{blue}{\alpha^{*}_T}
&\color{blue}{=} \color{blue}{\arg\min_{\alpha_T \geq 0} \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi^{*}}} [\alpha_T \mathcal{H}(\pi^{*}_T) - \alpha_T \mathcal{H}_0 ]}
\end{aligned}
$$

$$
\text{Thus, }\max_{\pi_T} \mathbb{E} [ r(s_T, a_T) ] 
= \mathbb{E}_{(s_T, a_T) \sim \rho_{\pi^{*}}} [ r(s_T, a_T)  + \alpha^{*}_T \mathcal{H}(\pi^{*}_T) - \alpha^{*}_T \mathcal{H}_0 ]
$$

现在我们回到软Q值函数：

> Now let’s go back to the soft Q value function:

$$
\begin{aligned}
Q_{T-1}(s_{T-1}, a_{T-1}) 
&= r(s_{T-1}, a_{T-1}) + \mathbb{E} [Q(s_T, a_T) - \alpha_T \log \pi(a_T \vert s_T)] \\
&= r(s_{T-1}, a_{T-1}) + \mathbb{E} [r(s_T, a_T)] + \alpha_T \mathcal{H}(\pi_T) \\
Q_{T-1}^{*}(s_{T-1}, a_{T-1}) 
&= r(s_{T-1}, a_{T-1}) + \max_{\pi_T} \mathbb{E} [r(s_T, a_T)] +  \alpha_T \mathcal{H}(\pi^{*}_T) & \text{; plug in the optimal }\pi_T^{*}
\end{aligned}
$$

因此，当我们再往回一步到时间步 $T-1$ 时，预期回报如下：

> Therefore the expected return is as follows, when we take one step further back to the time step $T-1$:

$$
\begin{aligned}
&\max_{\pi_{T-1}}\Big(\mathbb{E}[r(s_{T-1}, a_{T-1})] + \max_{\pi_T} \mathbb{E}[r(s_T, a_T] \Big) \\
&= \max_{\pi_{T-1}} \Big( Q^{*}_{T-1}(s_{T-1}, a_{T-1}) - \alpha^{*}_T \mathcal{H}(\pi^{*}_T) \Big) & \text{; should s.t. } \mathcal{H}(\pi_{T-1}) - \mathcal{H}_0 \geq 0 \\
&= \min_{\alpha_{T-1} \geq 0}  \max_{\pi_{T-1}} \Big( Q^{*}_{T-1}(s_{T-1}, a_{T-1}) - \alpha^{*}_T \mathcal{H}(\pi^{*}_T) + \alpha_{T-1} \big( \mathcal{H}(\pi_{T-1}) - \mathcal{H}_0 \big) \Big) & \text{; dual problem w/ Lagrangian.} \\
&= \min_{\alpha_{T-1} \geq 0}  \max_{\pi_{T-1}} \Big( Q^{*}_{T-1}(s_{T-1}, a_{T-1}) + \alpha_{T-1} \mathcal{H}(\pi_{T-1}) - \alpha_{T-1}\mathcal{H}_0 \Big) - \alpha^{*}_T \mathcal{H}(\pi^{*}_T)
\end{aligned}
$$

与上一步类似，

> Similar to the previous step,

$$
\begin{aligned}
\pi^{*}_{T-1} &= \arg\max_{\pi_{T-1}} \mathbb{E}_{(s_{T-1}, a_{T-1}) \sim \rho_\pi} [Q^{*}_{T-1}(s_{T-1}, a_{T-1}) + \alpha_{T-1} \mathcal{H}(\pi_{T-1}) - \alpha_{T-1} \mathcal{H}_0 ] \\
\color{green}{\alpha^{*}_{T-1}} &\color{green}{=} \color{green}{\arg\min_{\alpha_{T-1} \geq 0} \mathbb{E}_{(s_{T-1}, a_{T-1}) \sim \rho_{\pi^{*}}} [ \alpha_{T-1} \mathcal{H}(\pi^{*}_{T-1}) - \alpha_{T-1}\mathcal{H}_0 ]}
\end{aligned}
$$

绿色部分更新 $\alpha_{T-1}$ 的方程与上方蓝色部分更新 $\alpha_{T-1}$ 的方程格式相同。通过重复此过程，我们可以通过最小化相同的目标函数，在每一步中学习到最优温度参数：

> The equation for updating $\alpha_{T-1}$ in green has the same format as the equation for updating $\alpha_{T-1}$ in blue above. By repeating this process, we can learn the optimal temperature parameter in every step by minimizing the same objective function:

$$
J(\alpha) = \mathbb{E}_{a_t \sim \pi_t} [-\alpha \log \pi_t(a_t \mid s_t) - \alpha \mathcal{H}_0]
$$

最终算法与 SAC 相同，只是显式地学习 $\alpha$，其目标是 $J(\alpha)$（参见图 7）：

> The final algorithm is same as SAC except for learning $\alpha$ explicitly with respect to the objective $J(\alpha)$ (see Fig. 7):

![The soft actor-critic algorithm with automatically adjusted temperature. (Image source: original paper )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/SAC2_algo.png)

#### TD3

> TD3

[[论文](https://arxiv.org/abs/1802.09477)|[代码](https://github.com/sfujim/TD3)]

> [[paper](https://arxiv.org/abs/1802.09477)|[code](https://github.com/sfujim/TD3)]

Q-learning 算法通常已知会遭受价值函数的过高估计。这种过高估计会通过训练迭代传播，并对策略产生负面影响。这一特性直接促成了 [Double Q-learning](https://papers.nips.cc/paper/3964-double-q-learning) 和 [Double DQN](https://arxiv.org/abs/1509.06461)：通过使用两个价值网络来解耦动作选择和 Q 值更新。

> The Q-learning algorithm is commonly known to suffer from the overestimation of the value function. This overestimation can propagate through the training iterations and negatively affect the policy. This property directly motivated [Double Q-learning](https://papers.nips.cc/paper/3964-double-q-learning) and [Double DQN](https://arxiv.org/abs/1509.06461): the action selection and Q-value update are decoupled by using two value networks.

**双延迟深度确定性策略梯度**（简称 **TD3**；[Fujimoto et al., 2018](https://arxiv.org/abs/1802.09477)）在 [DDPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ddpg) 上应用了一些技巧来防止价值函数的过高估计：

> **Twin Delayed Deep Deterministic** (short for **TD3**; [Fujimoto et al., 2018](https://arxiv.org/abs/1802.09477)) applied a couple of tricks on [DDPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ddpg) to prevent the overestimation of the value function:

(1) **截断双 Q 学习**：在双 Q 学习中，动作选择和 Q 值估计由两个网络分别进行。在 DDPG 设置中，给定两个确定性策略网络 $(\mu_{\theta_1}, \mu_{\theta_2})$ 和两个对应的评论家网络 $(Q_{w_1}, Q_{w_2})$，双 Q 学习的贝尔曼目标如下所示：

英文原文：(1) Clipped Double Q-learning: In Double Q-Learning, the action selection and Q-value estimation are made by two networks separately. In the DDPG setting, given two deterministic actors 

$(\mu_{\theta_1}, \mu_{\theta_2})$ with two corresponding critics 

$(Q_{w_1}, Q_{w_2})$, the Double Q-learning Bellman targets look like:

$$
\begin{aligned}
y_1 &= r + \gamma Q_{w_2}(s', \mu_{\theta_1}(s'))\\
y_2 &= r + \gamma Q_{w_1}(s', \mu_{\theta_2}(s'))
\end{aligned}
$$

然而，由于策略变化缓慢，这两个网络可能过于相似，无法做出独立的决策。*截断双 Q 学习*转而使用两者中的最小估计值，以偏向低估偏差，这种偏差难以通过训练传播：

> However, due to the slow changing policy, these two networks could be too similar to make independent decisions. The *Clipped Double Q-learning* instead uses the minimum estimation among two so as to favor underestimation bias which is hard to propagate through training:

$$
\begin{aligned}
y_1 &= r + \gamma \min_{i=1,2}Q_{w_i}(s', \mu_{\theta_1}(s'))\\
y_2 &= r + \gamma \min_{i=1,2} Q_{w_i}(s', \mu_{\theta_2}(s'))
\end{aligned}
$$

(2) **目标网络和策略网络的延迟更新**：在 [actor-critic](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#actor-critic) 模型中，策略和价值更新是深度耦合的：当策略不佳时，价值估计会因过高估计而发散，如果价值估计本身不准确，策略也会变得不佳。

> (2) **Delayed update of Target and Policy Networks**:  In the [actor-critic](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#actor-critic) model, policy and value updates are deeply coupled: Value estimates diverge through overestimation when the policy is poor, and the policy will become poor if the value estimate itself is inaccurate.

为了减少方差，TD3 以低于 Q 函数的频率更新策略。策略网络保持不变，直到经过几次更新后价值误差足够小。这个想法类似于 [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#dqn) 中周期性更新的目标网络如何保持一个稳定的目标。

> To reduce the variance, TD3 updates the policy at a lower frequency than the Q-function. The policy network stays the same until the value error is small enough after several updates. The idea is similar to how the periodically-updated target network stay as a stable objective in [DQN](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#dqn).

(3) **目标策略平滑**：考虑到确定性策略可能过度拟合价值函数中的狭窄峰值，TD3引入了一种在价值函数上进行平滑正则化的策略：向选定的动作添加少量裁剪后的随机噪声，并在小批量数据上进行平均。

> (3) **Target Policy Smoothing**: Given a concern with deterministic policies that they can overfit to narrow peaks in the value function, TD3 introduced a smoothing regularization strategy on the value function: adding a small amount of clipped random noises to the selected action and averaging over mini-batches.

$$
\begin{aligned}
y &= r + \gamma Q_w (s', \mu_{\theta}(s') + \epsilon) & \\
\epsilon &\sim \text{clip}(\mathcal{N}(0, \sigma), -c, +c) & \scriptstyle{\text{ ; clipped random noises.}}
\end{aligned}
$$

这种方法模仿了[SARSA](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#sarsa-on-policy-td-control)更新的思想，并强制要求相似的动作应具有相似的价值。

> This approach mimics the idea of [SARSA](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#sarsa-on-policy-td-control) update and enforces that similar actions should have similar values.

最终算法如下：

> Here is the final algorithm:

![TD3 Algorithm. (Image source: Fujimoto et al., 2018 )](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/TD3.png)

#### SVPG

> SVPG

[[论文](https://arxiv.org/abs/1704.02399)|[代码](https://github.com/dilinwang820/Stein-Variational-Gradient-Descent)（SVPG）]

> [[paper](https://arxiv.org/abs/1704.02399)|[code](https://github.com/dilinwang820/Stein-Variational-Gradient-Descent) for SVPG]

Stein变分策略梯度（**SVPG**；[Liu et al, 2017](https://arxiv.org/abs/1704.02399)）应用[Stein](https://www.cs.dartmouth.edu/~qliu/stein.html)变分梯度下降（**SVGD**；[Liu and Wang, 2016](https://arxiv.org/abs/1608.04471)）算法来更新策略参数`\theta`。

英文原文：Stein Variational Policy Gradient (SVPG; [Liu et al, 2017](https://arxiv.org/abs/1704.02399)) applies the [Stein](https://www.cs.dartmouth.edu/~qliu/stein.html) variational gradient descent (SVGD; [Liu and Wang, 2016](https://arxiv.org/abs/1608.04471)) algorithm to update the policy parameter `\theta`.

在最大熵策略优化的设置中，$\theta$被视为随机变量$\theta \sim q(\theta)$，模型期望学习这个分布$q(\theta)$。假设我们知道关于$q$可能是什么样子的先验知识$q_0$，并且我们希望通过优化以下目标函数来引导学习过程，使$\theta$不要离$q_0$太远：

> In the setup of maximum entropy policy optimization, $\theta$ is considered as a random variable $\theta \sim q(\theta)$ and the model is expected to learn this distribution $q(\theta)$. Assuming we know a prior on how $q$ might look like, $q_0$, and we would like to guide the learning process to not make $\theta$ too far away from $q_0$ by optimizing the following objective function:

$$
\hat{J}(\theta) = \mathbb{E}_{\theta \sim q} [J(\theta)] - \alpha D_\text{KL}(q\|q_0)
$$

其中$\mathbb{E}_{\theta \sim q} [R(\theta)]$是当$\theta \sim q(\theta)$时的期望奖励，$D_\text{KL}$是KL散度。

> where $\mathbb{E}_{\theta \sim q} [R(\theta)]$ is the expected reward when $\theta \sim q(\theta)$ and $D_\text{KL}$ is the KL divergence.

如果我们没有任何先验信息，我们可能会将$q_0$设置为均匀分布，并将$q_0(\theta)$设置为常数。那么上述目标函数就变成了[SAC](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#SAC)，其中熵项鼓励探索：

> If we don’t have any prior information, we might set $q_0$ as a uniform distribution and set $q_0(\theta)$ to a constant. Then the above objective function becomes [SAC](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#SAC), where the entropy term encourages exploration:

$$
\begin{aligned}
\hat{J}(\theta) 
&= \mathbb{E}_{\theta \sim q} [J(\theta)] - \alpha D_\text{KL}(q\|q_0) \\
&= \mathbb{E}_{\theta \sim q} [J(\theta)] - \alpha \mathbb{E}_{\theta \sim q} [\log q(\theta) - \log q_0(\theta)] \\
&= \mathbb{E}_{\theta \sim q} [J(\theta)] + \alpha H(q(\theta))
\end{aligned}
$$

让我们对$\hat{J}(\theta) = \mathbb{E}_{\theta \sim q} [J(\theta)] - \alpha D_\text{KL}(q|q_0)$关于$q$求导：

> Let’s take the derivative of $\hat{J}(\theta) = \mathbb{E}_{\theta \sim q} [J(\theta)] - \alpha D_\text{KL}(q|q_0)$ w.r.t. $q$:

$$
\begin{aligned}
\nabla_q \hat{J}(\theta) 
&= \nabla_q \big( \mathbb{E}_{\theta \sim q} [J(\theta)] - \alpha D_\text{KL}(q\|q_0) \big) \\
&= \nabla_q \int_\theta \big( q(\theta) J(\theta) - \alpha q(\theta)\log q(\theta) + \alpha q(\theta) \log q_0(\theta) \big) \\
&= \int_\theta \big( J(\theta) - \alpha \log q(\theta) -\alpha + \alpha \log q_0(\theta) \big) \\
&= 0
\end{aligned}
$$

最优分布为：

> The optimal distribution is:

$$
\log q^{*}(\theta) = \frac{1}{\alpha} J(\theta) + \log q_0(\theta) - 1 \text{ thus } \underbrace{ q^{*}(\theta) }_\text{posterior} \propto \underbrace{\exp ( J(\theta) / \alpha )}_\text{likelihood} \underbrace{q_0(\theta)}_\textrm{prior}
$$

温度$\alpha$决定了利用和探索之间的权衡。当$\alpha \rightarrow 0$时，$\theta$仅根据期望回报$J(\theta)$进行更新。当$\alpha \rightarrow \infty$时，$\theta$始终遵循先验信念。

> The temperature $\alpha$ decides a tradeoff between exploitation and exploration. When $\alpha \rightarrow 0$, $\theta$ is updated only according to the expected return $J(\theta)$. When $\alpha \rightarrow \infty$, $\theta$ always follows the prior belief.

当使用SVGD方法估计目标后验分布$q(\theta)$时，它依赖于一组粒子$\{\theta_i\}_{i=1}^n$（独立训练的策略智能体），并且每个粒子都会更新：

> When using the SVGD method to estimate the target posterior distribution $q(\theta)$, it relies on a set of particle $\{\theta_i\}_{i=1}^n$ (independently trained policy agents) and each is updated:

$$
\theta_i \gets \theta_i + \epsilon \phi^{*}(\theta_i) \text{ where } \phi^{*} = \max_{\phi \in \mathcal{H}} \{ - \nabla_\epsilon D_\text{KL} (q'_{[\theta + \epsilon \phi(\theta)]} \| q) \text{ s.t. } \|\phi\|_{\mathcal{H}} \leq 1\}
$$

其中 $\epsilon$ 是学习率，$\phi^{*}$ 是 [RKHS](http://mlss.tuebingen.mpg.de/2015/slides/gretton/part_1.pdf)（再生核希尔伯特空间）的单位球，$\mathcal{H}$ 由 $\theta$ 形的值向量组成，它最大程度地减小了粒子与目标分布之间的 KL 散度。$q’(.)$ 是 $\theta + \epsilon \phi(\theta)$ 的分布。

> where $\epsilon$ is a learning rate and $\phi^{*}$ is the unit ball of a [RKHS](http://mlss.tuebingen.mpg.de/2015/slides/gretton/part_1.pdf) (reproducing kernel Hilbert space) $\mathcal{H}$ of $\theta$ -shaped value vectors that maximally decreases the KL divergence between the particles and the target distribution. $q’(.)$ is the distribution of $\theta + \epsilon \phi(\theta)$.

比较不同的基于梯度的更新方法：

> Comparing different gradient-based update methods:

| 方法 | 更新空间 |
| --- | --- |
| 普通梯度 | 参数空间上的 $\Delta \theta$ |
| 自然梯度 | 搜索分布空间上的 $\Delta \theta$ |
| SVGD | 核函数空间上的 $\Delta \theta$（已编辑） |

> 英文原表 / English original

| Method | Update space |
| --- | --- |
| Plain gradient | $\Delta \theta$ on the parameter space |
| Natural gradient | $\Delta \theta$ on the search distribution space |
| SVGD | $\Delta \theta$ on the kernel function space (edited) |

$\phi^{*}$ 的一种 [估计](https://arxiv.org/abs/1608.04471) 形式如下。一个正定核 $k(\vartheta, \theta)$，即高斯 [径向基函数](https://en.wikipedia.org/wiki/Radial_basis_function)，用于衡量粒子之间的相似性。

> One [estimation](https://arxiv.org/abs/1608.04471) of $\phi^{*}$ has the following form. A positive definite kernel $k(\vartheta, \theta)$, i.e. a Gaussian [radial basis function](https://en.wikipedia.org/wiki/Radial_basis_function), measures the similarity between particles.

$$
\begin{aligned}
\phi^{*}(\theta_i) 
&= \mathbb{E}_{\vartheta \sim q'} [\nabla_\vartheta \log q(\vartheta) k(\vartheta, \theta_i) + \nabla_\vartheta k(\vartheta, \theta_i)]\\
&= \frac{1}{n} \sum_{j=1}^n [\color{red}{\nabla_{\theta_j} \log q(\theta_j) k(\theta_j, \theta_i)} + \color{green}{\nabla_{\theta_j} k(\theta_j, \theta_i)}] & \scriptstyle{\text{;approximate }q'\text{ with current particle values}}
\end{aligned}
$$

• 红色部分的第一项鼓励 $\theta_i$ 学习趋向于 $q$ 的高概率区域，该区域在相似粒子之间共享。=> 与其他粒子相似

• 绿色的第二项将粒子相互推开，从而使策略多样化。=> 与其他粒子不同

英文原文：

• The first term in red encourages $\theta_i$ learning towards the high probability regions of $q$ that is shared across similar particles. => to be similar to other particles

• The second term in green pushes particles away from each other and therefore diversifies the policy. => to be dissimilar to other particles

![](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/SVPG.png)

通常，温度$\alpha$遵循退火方案，以便训练过程在开始时进行更多探索，但在后期进行更多利用。

> Usually the temperature $\alpha$ follows an annealing scheme so that the training process does more exploration at the beginning but more exploitation at a later stage.

#### IMPALA

> IMPALA

[[论文](https://arxiv.org/abs/1802.01561)|[代码](https://github.com/deepmind/scalable_agent)]

> [[paper](https://arxiv.org/abs/1802.01561)|[code](https://github.com/deepmind/scalable_agent)]

为了扩展强化学习训练以实现极高的吞吐量，**IMPALA**（“重要性加权Actor-Learner架构”）框架在基本actor-critic设置的基础上将行动与学习解耦，并利用**V-trace**离策略校正从所有经验轨迹中学习。

> In order to scale up RL training to achieve a very high throughput, **IMPALA** (“Importance Weighted Actor-Learner Architecture”) framework decouples acting from learning on top of basic actor-critic setup and learns from all experience trajectories with **V-trace** off-policy correction.

多个actor并行生成经验，而learner则利用所有生成的经验优化策略和价值函数参数。Actor定期使用learner的最新策略更新其参数。由于行动和学习是解耦的，我们可以添加更多的actor机器，以便在每个时间单位生成更多的轨迹。由于训练策略和行为策略并非完全同步，它们之间存在*差距*，因此我们需要离策略校正。

> Multiple actors generate experience in parallel, while the learner optimizes both policy and value function parameters using all the generated experience. Actors update their parameters with the latest policy from the learner periodically. Because acting and learning are decoupled, we can add many more actor machines to generate a lot more trajectories per time unit. As the training policy and the behavior policy are not totally synchronized, there is a *gap* between them and thus we need off-policy corrections.

![](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/IMPALA.png)

设价值函数 $V_\theta$ 由 $\theta$ 参数化，策略 $\pi_\phi$ 由 $\phi$ 参数化。我们还知道，回放缓冲区中的轨迹是由稍旧的策略 $\mu$ 收集的。

> Let the value function $V_\theta$ parameterized by $\theta$ and the policy $\pi_\phi$ parameterized by $\phi$. Also we know the trajectories in the replay buffer are collected by a slightly older policy $\mu$.

在训练时 $t$，给定 $(s_t, a_t, s_{t+1}, r_t)$，价值函数参数 $\theta$ 通过当前价值与 V-trace 价值目标之间的 L2 损失进行学习。$n$ 步 V-trace 目标定义为：

> At the training time $t$, given $(s_t, a_t, s_{t+1}, r_t)$, the value function parameter $\theta$ is learned through an L2 loss between the current value and a V-trace value target. The $n$ -step V-trace target is defined as:

$$
\begin{aligned}
v_t  &= V_\theta(s_t) + \sum_{i=t}^{t+n-1} \gamma^{i-t} \big(\prod_{j=t}^{i-1} c_j\big) \color{red}{\delta_i V} \\
&= V_\theta(s_t) + \sum_{i=t}^{t+n-1} \gamma^{i-t} \big(\prod_{j=t}^{i-1} c_j\big) \color{red}{\rho_i (r_i + \gamma V_\theta(s_{i+1}) - V_\theta(s_i))}
\end{aligned}
$$

其中红色部分$\delta_i V$是一个时间差分，用于$V$。$\rho_i = \min\big(\bar{\rho}, \frac{\pi(a_i \vert s_i)}{\mu(a_i \vert s_i)}\big)$和$c_j = \min\big(\bar{c}, \frac{\pi(a_j \vert s_j)}{\mu(a_j \vert s_j)}\big)$是*截断的[重要性采样 (IS)](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#off-policy-policy-gradient)权重*。的乘积$c_t, \dots, c_{i-1}$衡量一个时间差分在多大程度上$\delta_i V$在时间点被观察到$i$影响在之前的时间点上价值函数的更新。$t$。在同策略情况下，我们有$\rho_i=1$和$c_j=1$（假设$\bar{c} \geq 1$）因此V-trace目标变为同策略$n$步贝尔曼目标。

> where the red part $\delta_i V$ is a temporal difference for $V$. $\rho_i = \min\big(\bar{\rho}, \frac{\pi(a_i \vert s_i)}{\mu(a_i \vert s_i)}\big)$ and $c_j = \min\big(\bar{c}, \frac{\pi(a_j \vert s_j)}{\mu(a_j \vert s_j)}\big)$ are *truncated [importance sampling (IS)](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#off-policy-policy-gradient) weights*. The product of $c_t, \dots, c_{i-1}$ measures how much a temporal difference $\delta_i V$ observed at time $i$ impacts the update of the value function at a previous time $t$. In the on-policy case, we have $\rho_i=1$ and $c_j=1$ (assuming $\bar{c} \geq 1$) and therefore the V-trace target becomes on-policy $n$ -step Bellman target.

$\bar{\rho}$ 和 $\bar{c}$ 是两个截断常数，具有 $\bar{\rho} \geq \bar{c}$。$\bar{\rho}$ 影响我们收敛到的值函数的定点，而 $\bar{c}$ 影响收敛速度。当 $\bar{\rho} =\infty$（未截断）时，我们收敛到目标策略 $V^\pi$ 的值函数；当 $\bar{\rho}$ 接近 0 时，我们评估行为策略 $V^\mu$ 的值函数；当介于两者之间时，我们评估 $\pi$ 和 $\mu$ 之间的策略。

> $\bar{\rho}$ and $\bar{c}$ are two truncation constants with $\bar{\rho} \geq \bar{c}$. $\bar{\rho}$ impacts the fixed-point of the value function we converge to and $\bar{c}$ impacts the speed of convergence. When $\bar{\rho} =\infty$ (untruncated), we converge to the value function of the target policy $V^\pi$; when $\bar{\rho}$ is close to 0, we evaluate the value function of the behavior policy $V^\mu$; when in-between, we evaluate a policy between $\pi$ and $\mu$.

因此，值函数参数的更新方向为：

> The value function parameter is therefore updated in the direction of:

$$
\Delta\theta = (v_t - V_\theta(s_t))\nabla_\theta V_\theta(s_t)
$$

策略参数 $\phi$ 通过策略梯度进行更新，

> The policy parameter $\phi$ is updated through policy gradient,

$$
\begin{aligned}
\Delta \phi 
&= \rho_t \nabla_\phi \log \pi_\phi(a_t \vert s_t) \big(r_t + \gamma v_{t+1} - V_\theta(s_t)\big) + \nabla_\phi H(\pi_\phi)\\
&= \rho_t \nabla_\phi \log \pi_\phi(a_t \vert s_t) \big(r_t + \gamma v_{t+1} - V_\theta(s_t)\big) - \nabla_\phi \sum_a \pi_\phi(a\vert s_t)\log \pi_\phi(a\vert s_t)
\end{aligned}
$$

其中 $r_t + \gamma v_{t+1}$ 是估计的 Q 值，从中减去一个状态相关的基线 $V_\theta(s_t)$。$H(\pi_\phi)$ 是一个熵奖励，用于鼓励探索。

> where $r_t + \gamma v_{t+1}$ is the estimated Q value, from which a state-dependent baseline $V_\theta(s_t)$ is subtracted. $H(\pi_\phi)$ is an entropy bonus to encourage exploration.

在实验中，IMPALA 用于在多个任务上训练一个智能体。涉及两种不同的模型架构，一个浅层模型（左）和一个深度残差模型（右）。

> In the experiments, IMPALA is used to train one agent over multiple tasks. Two different model architectures are involved, a shallow model (left) and a deep residual model (right).

![](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/IMPALA-arch.png)

### 快速总结

> Quick Summary

阅读完上述所有算法后，我列出了一些它们之间似乎共同的构建块或原则：

> After reading through all the algorithms above, I list a few building blocks or principles that seem to be common among them:

- 尝试减少方差并保持偏差不变以稳定学习。
- 离策略为我们提供了更好的探索，并帮助我们更有效地利用数据样本。
- 经验回放（从回放记忆缓冲区采样的训练数据）；
- 目标网络，它要么定期冻结，要么比主动学习的策略网络更新得慢；
- 批量归一化；
- 熵正则化奖励；
- 评论家和行动者可以共享网络的较低层参数以及策略和价值函数的两个输出头。
- 可以使用确定性策略而不是随机策略进行学习。
- 对策略更新之间的散度施加约束。
- 新的优化方法（例如 K-FAC）。
- 策略的熵最大化有助于鼓励探索。
- 尽量不要高估价值函数。
- 仔细考虑策略网络和价值网络是否应该共享参数。
- 待补充。

> • Try to reduce the variance and keep the bias unchanged to stabilize learning.
> • Off-policy gives us better exploration and helps us use data samples more efficiently.
> • Experience replay (training data sampled from a replay memory buffer);
> • Target network that is either frozen periodically or updated slower than the actively learned policy network;
> • Batch normalization;
> • Entropy-regularized reward;
> • The critic and actor can share lower layer parameters of the network and two output heads for policy and value functions.
> • It is possible to learn with deterministic policy rather than stochastic one.
> • Put constraint on the divergence between policy updates.
> • New optimization methods (such as K-FAC).
> • Entropy maximization of the policy helps encourage exploration.
> • Try not to overestimate the value function.
> • Think twice whether the policy and value network should share parameters.
> • TBA more.

引用方式：

> Cited as:

```
@article{weng2018PG,
  title   = "Policy Gradient Algorithms",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-04-08-policy-gradient/"
}
```

### 参考文献

> References

[1] jeremykun.com [马尔可夫链蒙特卡洛，去芜存菁](https://jeremykun.com/2015/04/06/markov-chain-monte-carlo-without-all-the-bullshit/)

> [1] jeremykun.com [Markov Chain Monte Carlo Without all the Bullshit](https://jeremykun.com/2015/04/06/markov-chain-monte-carlo-without-all-the-bullshit/)

[2] Richard S. Sutton and Andrew G. Barto. [强化学习：导论；第2版](http://incompleteideas.net/book/bookdraft2017nov5.pdf). 2017。

> [2] Richard S. Sutton and Andrew G. Barto. [Reinforcement Learning: An Introduction; 2nd Edition](http://incompleteideas.net/book/bookdraft2017nov5.pdf). 2017.

[3] John Schulman, et al. [“使用广义优势估计进行高维连续控制。”](https://arxiv.org/pdf/1506.02438.pdf) ICLR 2016。

> [3] John Schulman, et al. [“High-dimensional continuous control using generalized advantage estimation.”](https://arxiv.org/pdf/1506.02438.pdf) ICLR 2016.

[4] Thomas Degris, Martha White, and Richard S. Sutton. [“离策略行动者-评论家。”](https://arxiv.org/pdf/1205.4839.pdf) ICML 2012。

> [4] Thomas Degris, Martha White, and Richard S. Sutton. [“Off-policy actor-critic.”](https://arxiv.org/pdf/1205.4839.pdf) ICML 2012.

[5] timvieira.github.io [重要性采样](http://timvieira.github.io/blog/post/2014/12/21/importance-sampling/)

> [5] timvieira.github.io [Importance sampling](http://timvieira.github.io/blog/post/2014/12/21/importance-sampling/)

[6] Mnih, Volodymyr, et al. [“深度强化学习的异步方法。”](https://arxiv.org/abs/1602.01783) ICML. 2016。

> [6] Mnih, Volodymyr, et al. [“Asynchronous methods for deep reinforcement learning.”](https://arxiv.org/abs/1602.01783) ICML. 2016.

[7] David Silver, et al. [“确定性策略梯度算法。”](https://hal.inria.fr/file/index/docid/938992/filename/dpg-icml2014.pdf) ICML. 2014.

> [7] David Silver, et al. [“Deterministic policy gradient algorithms.”](https://hal.inria.fr/file/index/docid/938992/filename/dpg-icml2014.pdf) ICML. 2014.

[8] Timothy P. Lillicrap, et al. [“基于深度强化学习的连续控制。”](https://arxiv.org/pdf/1509.02971.pdf) arXiv preprint arXiv:1509.02971 (2015).

> [8] Timothy P. Lillicrap, et al. [“Continuous control with deep reinforcement learning.”](https://arxiv.org/pdf/1509.02971.pdf) arXiv preprint arXiv:1509.02971 (2015).

[9] Ryan Lowe, et al. [“用于混合合作竞争环境的多智能体Actor-Critic。”](https://arxiv.org/pdf/1706.02275.pdf) NIPS. 2017.

> [9] Ryan Lowe, et al. [“Multi-agent actor-critic for mixed cooperative-competitive environments.”](https://arxiv.org/pdf/1706.02275.pdf) NIPS. 2017.

[10] John Schulman, et al. [“信任区域策略优化。”](https://arxiv.org/pdf/1502.05477.pdf) ICML. 2015.

> [10] John Schulman, et al. [“Trust region policy optimization.”](https://arxiv.org/pdf/1502.05477.pdf) ICML. 2015.

[11] Ziyu Wang, et al. [“带经验回放的样本高效Actor-Critic。”](https://arxiv.org/pdf/1611.01224.pdf) ICLR 2017.

> [11] Ziyu Wang, et al. [“Sample efficient actor-critic with experience replay.”](https://arxiv.org/pdf/1611.01224.pdf) ICLR 2017.

[12] Rémi Munos, Tom Stepleton, Anna Harutyunyan, and Marc Bellemare. [“安全高效的离策略强化学习”](http://papers.nips.cc/paper/6538-safe-and-efficient-off-policy-reinforcement-learning.pdf) NIPS. 2016.

> [12] Rémi Munos, Tom Stepleton, Anna Harutyunyan, and Marc Bellemare. [“Safe and efficient off-policy reinforcement learning”](http://papers.nips.cc/paper/6538-safe-and-efficient-off-policy-reinforcement-learning.pdf) NIPS. 2016.

[13] Yuhuai Wu, et al. [“使用克罗内克因子分解近似的深度强化学习可扩展信任区域方法。”](https://arxiv.org/pdf/1708.05144.pdf) NIPS. 2017.

> [13] Yuhuai Wu, et al. [“Scalable trust-region method for deep reinforcement learning using Kronecker-factored approximation.”](https://arxiv.org/pdf/1708.05144.pdf) NIPS. 2017.

[14] kvfrans.com [自然梯度下降的直观解释](http://kvfrans.com/a-intuitive-explanation-of-natural-gradient-descent/)

> [14] kvfrans.com [A intuitive explanation of natural gradient descent](http://kvfrans.com/a-intuitive-explanation-of-natural-gradient-descent/)

[15] Sham Kakade. [“一种自然策略梯度。”](https://papers.nips.cc/paper/2073-a-natural-policy-gradient.pdf). NIPS. 2002.

> [15] Sham Kakade. [“A Natural Policy Gradient.”](https://papers.nips.cc/paper/2073-a-natural-policy-gradient.pdf). NIPS. 2002.

[16] [“深入强化学习：策略梯度的基础。”](https://danieltakeshi.github.io/2017/03/28/going-deeper-into-reinforcement-learning-fundamentals-of-policy-gradients/) - Seita’s Place, Mar 2017.

> [16] [“Going Deeper Into Reinforcement Learning: Fundamentals of Policy Gradients.”](https://danieltakeshi.github.io/2017/03/28/going-deeper-into-reinforcement-learning-fundamentals-of-policy-gradients/) - Seita’s Place, Mar 2017.

[17] [“关于广义优势估计论文的笔记。”](https://danieltakeshi.github.io/2017/04/02/notes-on-the-generalized-advantage-estimation-paper/) - Seita’s Place, Apr, 2017.

> [17] [“Notes on the Generalized Advantage Estimation Paper.”](https://danieltakeshi.github.io/2017/04/02/notes-on-the-generalized-advantage-estimation-paper/) - Seita’s Place, Apr, 2017.

[18] Gabriel Barth-Maron, et al. [“分布式分布确定性策略梯度。”](https://arxiv.org/pdf/1804.08617.pdf) ICLR 2018 poster.

> [18] Gabriel Barth-Maron, et al. [“Distributed Distributional Deterministic Policy Gradients.”](https://arxiv.org/pdf/1804.08617.pdf) ICLR 2018 poster.

[19] Tuomas Haarnoja, Aurick Zhou, Pieter Abbeel, and Sergey Levine. [“软Actor-Critic：带随机Actor的离策略最大熵深度强化学习。”](https://arxiv.org/pdf/1801.01290.pdf) arXiv preprint arXiv:1801.01290 (2018).

> [19] Tuomas Haarnoja, Aurick Zhou, Pieter Abbeel, and Sergey Levine. [“Soft Actor-Critic: Off-Policy Maximum Entropy Deep Reinforcement Learning with a Stochastic Actor.”](https://arxiv.org/pdf/1801.01290.pdf) arXiv preprint arXiv:1801.01290 (2018).

[20] Scott Fujimoto, Herke van Hoof, and Dave Meger. [“解决Actor-Critic方法中的函数逼近误差。”](https://arxiv.org/abs/1802.09477) arXiv preprint arXiv:1802.09477 (2018).

> [20] Scott Fujimoto, Herke van Hoof, and Dave Meger. [“Addressing Function Approximation Error in Actor-Critic Methods.”](https://arxiv.org/abs/1802.09477) arXiv preprint arXiv:1802.09477 (2018).

[21] Tuomas Haarnoja, et al. [“软Actor-Critic算法及应用。”](https://arxiv.org/abs/1812.05905) arXiv preprint arXiv:1812.05905 (2018).

> [21] Tuomas Haarnoja, et al. [“Soft Actor-Critic Algorithms and Applications.”](https://arxiv.org/abs/1812.05905) arXiv preprint arXiv:1812.05905 (2018).

[22] David Knowles. [“傻瓜式拉格朗日对偶”](https://cs.stanford.edu/people/davidknowles/lagrangian_duality.pdf) Nov 13, 2010.

> [22] David Knowles. [“Lagrangian Duality for Dummies”](https://cs.stanford.edu/people/davidknowles/lagrangian_duality.pdf) Nov 13, 2010.

[23] Yang Liu, et al. [“Stein变分策略梯度。”](https://arxiv.org/abs/1704.02399) arXiv preprint arXiv:1704.02399 (2017).

> [23] Yang Liu, et al. [“Stein variational policy gradient.”](https://arxiv.org/abs/1704.02399) arXiv preprint arXiv:1704.02399 (2017).

[24] Qiang Liu and Dilin Wang. [“Stein变分梯度下降：一种通用贝叶斯推理算法。”](https://papers.nips.cc/paper/6338-stein-variational-gradient-descent-a-general-purpose-bayesian-inference-algorithm.pdf) NIPS. 2016.

> [24] Qiang Liu and Dilin Wang. [“Stein variational gradient descent: A general purpose bayesian inference algorithm.”](https://papers.nips.cc/paper/6338-stein-variational-gradient-descent-a-general-purpose-bayesian-inference-algorithm.pdf) NIPS. 2016.

[25] Lasse Espeholt, et al. [“IMPALA：带重要性加权Actor-Learner架构的可扩展分布式深度强化学习”](https://arxiv.org/abs/1802.01561) arXiv preprint 1802.01561 (2018).

> [25] Lasse Espeholt, et al. [“IMPALA: Scalable Distributed Deep-RL with Importance Weighted Actor-Learner Architectures”](https://arxiv.org/abs/1802.01561) arXiv preprint 1802.01561 (2018).

[26] Karl Cobbe, et al. [“分阶段策略梯度。”](https://arxiv.org/abs/2009.04416) arXiv preprint arXiv:2009.04416 (2020).

> [26] Karl Cobbe, et al. [“Phasic Policy Gradient.”](https://arxiv.org/abs/2009.04416) arXiv preprint arXiv:2009.04416 (2020).

[27] Chloe Ching-Yun Hsu, et al. [“重新审视近端策略优化中的设计选择。”](https://arxiv.org/abs/2009.10897) arXiv preprint arXiv:2009.10897 (2020).

> [27] Chloe Ching-Yun Hsu, et al. [“Revisiting Design Choices in Proximal Policy Optimization.”](https://arxiv.org/abs/2009.10897) arXiv preprint arXiv:2009.10897 (2020).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Policy Gradient | 策略梯度 | 一种强化学习方法，直接建模和优化策略以获得最优奖励。 |
| Reinforcement Learning | 强化学习 | 一种机器学习范式，智能体通过与环境交互学习最优行为策略。 |
| Monte Carlo methods | 蒙特卡洛方法 | 通过从完整轨迹中采样来估计收益，用于策略梯度更新。 |
| Actor-Critic | 演员-评论家 | 一种强化学习架构，包含一个更新策略的“演员”和一个更新价值函数的“评论家”。 |
| On-policy | 在策略 | 训练样本根据目标策略收集的强化学习方法。 |
| Off-policy | 离策略 | 训练样本根据与目标策略不同的行为策略收集的强化学习方法。 |
| Importance Sampling | 重要性采样 | 一种统计技术，用于在离策略学习中校正行为策略和目标策略之间的不匹配。 |
| Asynchronous Advantage Actor-Critic (A3C) | 异步优势演员-评论家 | 一种经典的策略梯度方法，通过并行训练多个演员与全局参数同步。 |
| Deep Deterministic Policy Gradient (DDPG) | 深度确定性策略梯度 | 结合DPG和DQN的无模型、异策略Actor-Critic算法，适用于连续动作空间。 |
| Trust Region Policy Optimization (TRPO) | 信任区域策略优化 | 通过对策略更新大小施加KL散度约束来提高训练稳定性。 |
| Proximal Policy Optimization (PPO) | 近端策略优化 | 通过使用裁剪的替代目标来简化TRPO，同时保持相似性能。 |
| Soft Actor-Critic (SAC) | 软行动者-评论家 | 一种离策略Actor-Critic模型，将策略的熵度量纳入奖励中以鼓励探索。 |
| Twin Delayed Deep Deterministic Policy Gradient (TD3) | 双延迟深度确定性策略梯度 | 在DDPG基础上改进，通过截断双Q学习、延迟更新和目标策略平滑防止价值函数过高估计。 |
| Importance Weighted Actor-Learner Architectures (IMPALA) | 重要性加权演员-学习者架构 | 一种分布式强化学习框架，解耦行动与学习，并利用V-trace离策略校正。 |
| Phasic Policy Gradient (PPG) | 分阶段策略梯度 | 修改了传统的Actor-Critic算法，使其具有独立的策略和价值函数训练阶段，以提高样本效率。 |
