# 多臂老虎机问题及其解决方案

> The Multi-Armed Bandit Problem and Its Solutions

> 来源：Lil'Log / Lilian Weng，2018-01-23
> 原文链接：https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/
> 分类：强化学习 / 多臂老虎机

## 核心要点

- 探索与利用是许多决策场景中的核心困境，需要在收集信息和利用已知最佳选项之间取得平衡。
- 多臂老虎机问题是一个经典的探索与利用困境模型，目标是在面对多台具有未知奖励概率的老虎机时，最大化长期累积奖励。
- 伯努利多臂老虎机问题可以形式化为没有状态的马尔可夫决策过程简化版，目标是最大化累积奖励或最小化遗憾。
- 解决多臂老虎机问题有多种策略，包括不探索、随机探索和偏向不确定性的智能探索。
- ε-贪婪算法是一种常见的随机探索策略，它以小概率随机探索，以大概率选择当前已知最佳行动。
- 置信上限（UCB）算法通过对具有高不确定性的选项保持乐观来改进探索效率，选择最大化奖励值置信上限的行动。
- 霍夫丁不等式可用于在不假设奖励分布先验知识的情况下，估计置信上限，从而推导出UCB1算法。
- 汤普森采样是一种基于贝叶斯推断的有效策略，它根据动作是最优的概率来选择动作，并利用Beta分布更新奖励概率的后验。
- 汤普森采样通过从后验分布中抽取预期奖励并选择最佳动作来实现概率匹配，即使在计算复杂的情况下也可通过近似方法应用。
- 智能探索策略，如UCB和汤普森采样，通过权衡信息增益和潜在回报，比简单随机探索更有效地解决多臂老虎机问题。

## 正文

这些算法是针对伯努利赌博机在[lilianweng/multi-armed-bandit](http://github.com/lilianweng/multi-armed-bandit)中实现的。

> The algorithms are implemented for Bernoulli bandit in [lilianweng/multi-armed-bandit](http://github.com/lilianweng/multi-armed-bandit).

### 利用与探索

> Exploitation vs Exploration

探索与利用的困境存在于我们生活的许多方面。比如说，你最喜欢的餐厅就在街角。如果你每天都去那里，你会对你将得到的东西充满信心，但会错过发现一个更好选择的机会。如果你一直尝试新地方，你很可能会时不时吃到不愉快的食物。同样，在线顾问试图在已知最吸引人的广告和可能更成功的新广告之间取得平衡。

> The exploration vs exploitation dilemma exists in many aspects of our life. Say, your favorite restaurant is right around the corner. If you go there every day, you would be confident of what you will get, but miss the chances of discovering an even better option. If you try new places all the time, very likely you are gonna have to eat unpleasant food from time to time. Similarly, online advisors try to balance between the known most attractive ads and the new ads that might be even more successful.

![A real-life example of the exploration vs exploitation dilemma: where to eat? (Image source: UC Berkeley AI course slide , lecture 11 .)](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/exploration_vs_exploitation.png)

如果我们已经了解了关于环境的所有信息，我们甚至可以通过模拟暴力破解来找到最佳策略，更不用说许多其他智能方法了。困境来自于*不完整*的信息：我们需要收集足够的信息来做出最佳的整体决策，同时控制风险。通过利用，我们利用我们所知的最佳选项。通过探索，我们承担一些风险来收集关于未知选项的信息。最佳的长期策略可能涉及短期牺牲。例如，一次探索尝试可能完全失败，但这会警告我们未来不要过于频繁地采取该行动。

> If we have learned all the information about the environment, we are able to find the best strategy by even just simulating brute-force, let alone many other smart approaches. The dilemma comes from the *incomplete* information: we need to gather enough information to make best overall decisions while keeping the risk under control. With exploitation, we take advantage of the best option we know. With exploration, we take some risk to collect information about unknown options. The best long-term strategy may involve short-term sacrifices. For example, one exploration trial could be a total failure, but it warns us of not taking that action too often in the future.

### 什么是多臂老虎机？

> What is Multi-Armed Bandit?

[多臂老虎机](https://en.wikipedia.org/wiki/Multi-armed_bandit)问题是一个经典问题，它很好地展示了探索与利用的困境。想象一下你身处赌场，面对多台老虎机，每台老虎机都配置了一个未知的概率，表示你一次玩能获得奖励的可能性。问题是：*实现最高长期奖励的最佳策略是什么？*

> The [multi-armed bandit](https://en.wikipedia.org/wiki/Multi-armed_bandit) problem is a classic problem that well demonstrates the exploration vs exploitation dilemma. Imagine you are in a casino facing multiple slot machines and each is configured with an unknown probability of how likely you can get a reward at one play. The question is: *What is the best strategy to achieve highest long-term rewards?*

在这篇文章中，我们将只讨论试验次数无限的情况。对有限试验次数的限制引入了一种新型的探索问题。例如，如果试验次数少于老虎机数量，我们甚至无法尝试每台机器来估计奖励概率（！），因此我们必须根据有限的知识和资源（即时间）来巧妙行事。

> In this post, we will only discuss the setting of having an infinite number of trials. The restriction on a finite number of trials introduces a new type of exploration problem. For instance, if the number of trials is smaller than the number of slot machines, we cannot even try every machine to estimate the reward probability (!) and hence we have to behave smartly w.r.t. a limited set of knowledge and resources (i.e. time).

![An illustration of how a Bernoulli multi-armed bandit works. The reward probabilities are **unknown** to the player.](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/bern_bandit.png)

一种天真的方法是，你继续玩一台机器很多很多轮，以便最终根据[大数定律](https://en.wikipedia.org/wiki/Law_of_large_numbers)估计“真实”的奖励概率。然而，这相当浪费，并且肯定不能保证最佳的长期奖励。

> A naive approach can be that you continue to playing with one machine for many many rounds so as to eventually estimate the “true” reward probability according to the [law of large numbers](https://en.wikipedia.org/wiki/Law_of_large_numbers). However, this is quite wasteful and surely does not guarantee the best long-term reward.

#### 定义

> Definition

现在我们给它一个科学定义。

> Now let’s give it a scientific definition.

一个伯努利多臂老虎机可以描述为一个元组$\langle \mathcal{A}, \mathcal{R} \rangle$，其中：

> A Bernoulli multi-armed bandit can be described as a tuple of $\langle \mathcal{A}, \mathcal{R} \rangle$, where:

• 我们有 $K$ 台具有奖励概率的机器，$\{ \theta_1, \dots, \theta_K \}$。

• 在每个时间步 t，我们对一台老虎机采取行动 a 并获得奖励 r。

• $\mathcal{A}$ 是一组行动，每个行动都指与一台老虎机的交互。行动 a 的值是预期奖励，$Q(a) = \mathbb{E} [r \vert a] = \theta$。如果行动 $a_t$ 在时间步 t 作用于第 i 台机器，那么 $Q(a_t) = \theta_i$。

• $\mathcal{R}$ 是一个奖励函数。在伯努利赌博机的情况下，我们以一种 *随机的* 方式观察到奖励 r。在时间步 t，$r_t = \mathcal{R}(a_t)$ 可能以概率 $Q(a_t)$ 返回奖励 1，否则返回 0。

英文原文：

• We have $K$ machines with reward probabilities, $\{ \theta_1, \dots, \theta_K \}$.

• At each time step t, we take an action a on one slot machine and receive a reward r.

• $\mathcal{A}$ is a set of actions, each referring to the interaction with one slot machine. The value of action a is the expected reward, $Q(a) = \mathbb{E} [r \vert a] = \theta$. If action $a_t$ at the time step t is on the i-th machine, then $Q(a_t) = \theta_i$.

• $\mathcal{R}$ is a reward function. In the case of Bernoulli bandit, we observe a reward r in a *stochastic* fashion. At the time step t, $r_t = \mathcal{R}(a_t)$ may return reward 1 with a probability $Q(a_t)$ or 0 otherwise.

它是 [马尔可夫决策过程](https://en.wikipedia.org/wiki/Markov_decision_process) 的简化版本，因为没有状态 $\mathcal{S}$。

> It is a simplified version of [Markov decision process](https://en.wikipedia.org/wiki/Markov_decision_process), as there is no state $\mathcal{S}$.

目标是最大化累积奖励 $\sum_{t=1}^T r_t$.如果我们知道具有最佳奖励的最优行动，那么目标与最小化潜在的 [遗憾](https://en.wikipedia.org/wiki/Regret_(decision_theory)) 或因未选择最优行动而造成的损失相同。

> The goal is to maximize the cumulative reward $\sum_{t=1}^T r_t$.
> If we know the optimal action with the best reward, then the goal is same as to minimize the potential [regret](https://en.wikipedia.org/wiki/Regret_(decision_theory)) or loss by not picking the optimal action.

最优奖励概率$\theta^{*}$的最优行动$a^{*}$是：

> The optimal reward probability $\theta^{*}$ of the optimal action $a^{*}$ is:

$$
\theta^{*}=Q(a^{*})=\max_{a \in \mathcal{A}} Q(a) = \max_{1 \leq i \leq K} \theta_i
$$

我们的损失函数是截至时间步 T 未选择最优行动可能产生的总遗憾：

> Our loss function is the total regret we might have by not selecting the optimal action up to the time step T:

$$
\mathcal{L}_T = \mathbb{E} \Big[ \sum_{t=1}^T \big( \theta^{*} - Q(a_t) \big) \Big]
$$

#### 赌博机策略

> Bandit Strategies

根据我们进行探索的方式，有几种方法可以解决多臂赌博机问题。

> Based on how we do exploration, there several ways to solve the multi-armed bandit.

- 不探索：最幼稚且糟糕的方法。
- 随机探索
- 智能探索，偏向不确定性

> • No exploration: the most naive approach and a bad one.
> • Exploration at random
> • Exploration smartly with preference to uncertainty

### ε-贪婪算法

> ε-Greedy Algorithm

ε-贪婪算法在大多数时间采取最佳行动，但偶尔会进行随机探索。行动价值根据过去的经验进行估计，方法是平均我们迄今为止（直到当前时间步 t）观察到的与目标行动 a 相关的奖励：

> The ε-greedy algorithm takes the best action most of the time, but does random exploration occasionally. The action value is estimated according to the past experience by averaging the rewards associated with the target action a that we have observed so far (up to the current time step t):

$$
\hat{Q}_t(a) = \frac{1}{N_t(a)} \sum_{\tau=1}^t r_\tau \mathbb{1}[a_\tau = a]
$$

其中 $\mathbb{1}$ 是一个二元指示函数，$N_t(a)$ 是行动 a 迄今为止被选择的次数，$N_t(a) = \sum_{\tau=1}^t \mathbb{1}[a_\tau = a]$。

> where $\mathbb{1}$ is a binary indicator function and $N_t(a)$ is how many times the action a has been selected so far, $N_t(a) = \sum_{\tau=1}^t \mathbb{1}[a_\tau = a]$.

根据 ε-贪婪算法，我们以小概率 $\epsilon$ 采取随机行动，但在其他情况下（这应该是大多数时间，概率为 1-$\epsilon$），我们选择迄今为止学到的最佳行动：$\hat{a}^{*}_t = \arg\max_{a \in \mathcal{A}} \hat{Q}_t(a)$。

> According to the ε-greedy algorithm, with a small probability $\epsilon$ we take a random action, but otherwise (which should be the most of the time, probability 1-$\epsilon$) we pick the best action that we have learnt so far: $\hat{a}^{*}_t = \arg\max_{a \in \mathcal{A}} \hat{Q}_t(a)$.

在此处查看我的玩具实现 [here](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L45)。

> Check my toy implementation [here](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L45).

### 置信上限

> Upper Confidence Bounds

随机探索为我们提供了尝试我们不甚了解的选项的机会。然而，由于随机性，我们可能会探索一个过去已确认的糟糕行动（运气不佳！）。为了避免这种低效探索，一种方法是随时间减少参数 ε，另一种方法是对具有 *高不确定性* 的选项保持乐观，从而偏好那些我们尚未有可靠价值估计的行动。换句话说，我们倾向于探索那些具有强大潜力以获得最优价值的行动。

> Random exploration gives us an opportunity to try out options that we have not known much about. However, due to the randomness, it is possible we end up exploring a bad action which we have confirmed in the past (bad luck!). To avoid such inefficient exploration, one approach is to decrease the parameter ε in time and the other is to be optimistic about options with *high uncertainty* and thus to prefer actions for which we haven’t had a confident value estimation yet. Or in other words, we favor exploration of actions with a strong potential to have a optimal value.

置信上限（UCB）算法通过奖励值的置信上限 $\hat{U}_t(a)$ 来衡量这种潜力，使得真实值以高概率低于界限 $Q(a) \leq \hat{Q}_t(a) + \hat{U}_t(a)$。置信上限 $\hat{U}_t(a)$ 是 $N_t(a)$ 的函数；更多的试验次数 $N_t(a)$ 应该会给我们一个更小的界限 $\hat{U}_t(a)$。

> The Upper Confidence Bounds (UCB) algorithm measures this potential by an upper confidence bound of the reward value, $\hat{U}_t(a)$, so that the true value is below with bound $Q(a) \leq \hat{Q}_t(a) + \hat{U}_t(a)$ with high probability. The upper bound $\hat{U}_t(a)$ is a function of $N_t(a)$; a larger number of trials $N_t(a)$ should give us a smaller bound $\hat{U}_t(a)$.

在 UCB 算法中，我们总是选择最贪婪的行动来最大化置信上限：

> In UCB algorithm, we always select the greediest action to maximize the upper confidence bound:

$$
a^{UCB}_t = argmax_{a \in \mathcal{A}} \hat{Q}_t(a) + \hat{U}_t(a)
$$

现在，问题是 *如何估计置信上限*。

> Now, the question is *how to estimate the upper confidence bound*.

#### 霍夫丁不等式

> Hoeffding’s Inequality

如果我们不想对分布的形状施加任何先验知识，我们可以借助 [“霍夫丁不等式”](http://cs229.stanford.edu/extra-notes/hoeffding.pdf)——一个适用于任何有界分布的定理。

> If we do not want to assign any prior knowledge on how the distribution looks like, we can get help from [“Hoeffding’s Inequality”](http://cs229.stanford.edu/extra-notes/hoeffding.pdf) — a theorem applicable to any bounded distribution.

设 $X_1, \dots, X_t$ 是独立同分布 (i.i.d.) 的随机变量，它们都由区间 [0, 1] 界定。样本均值为 $\overline{X}_t = \frac{1}{t}\sum_{\tau=1}^t X_\tau$。那么对于 $u > 0$，我们有：

> Let $X_1, \dots, X_t$ be i.i.d. (independent and identically distributed) random variables and they are all bounded by the interval [0, 1]. The sample mean is $\overline{X}_t = \frac{1}{t}\sum_{\tau=1}^t X_\tau$. Then for $u > 0$, we have:

$$
\mathbb{P} [ \mathbb{E}[X] > \overline{X}_t + u] \leq e^{-2tu^2}
$$

给定一个目标行动 $a$，让我们考虑：

> Given one target action $a$, let us consider:

• 将 $r_t(a)$ 作为随机变量，

• 将 $Q(a)$ 作为真实均值，

• 将 $\hat{Q}_t(a)$ 作为样本均值，

• 并将 $u$ 作为置信上限，$u = U_t(a)$

英文原文：

• $r_t(a)$ as the random variables,

• $Q(a)$ as the true mean,

• $\hat{Q}_t(a)$ as the sample mean,

• And $u$ as the upper confidence bound, $u = U_t(a)$

那么我们有，

> Then we have,

$$
\mathbb{P} [ Q(a) > \hat{Q}_t(a) + U_t(a)] \leq e^{-2t{U_t(a)}^2}
$$

我们希望选择一个界限，使得真实均值有很大机会低于样本均值 + 置信上限。因此 $e^{-2t U_t(a)^2}$ 应该是一个小概率。假设我们接受一个微小的阈值 p：

> We want to pick a bound so that with high chances the true mean is blow the sample mean + the upper confidence bound. Thus $e^{-2t U_t(a)^2}$ should be a small probability. Let’s say we are ok with a tiny threshold p:

$$
e^{-2t U_t(a)^2} = p \text{  Thus, } U_t(a) = \sqrt{\frac{-\log p}{2 N_t(a)}}
$$

#### UCB1

> UCB1

一种启发式方法是随时间减少阈值 p，因为我们希望在观察到更多奖励时进行更可靠的界限估计。设置 $p=t^{-4}$，我们得到 **UCB1** 算法：

英文原文：One heuristic is to reduce the threshold p in time, as we want to make more confident bound estimation with more rewards observed. Set 

$p=t^{-4}$ we get UCB1 algorithm:

$$
U_t(a) = \sqrt{\frac{2 \log t}{N_t(a)}} \text{  and  }
a^{UCB1}_t = \arg\max_{a \in \mathcal{A}} Q(a) + \sqrt{\frac{2 \log t}{N_t(a)}}
$$

#### 贝叶斯 UCB

> Bayesian UCB

在 UCB 或 UCB1 算法中，我们不对奖励分布做任何先验假设，因此我们必须依赖霍夫丁不等式进行非常泛化的估计。如果我们能够预先知道分布，我们将能够做出更好的界限估计。

> In UCB or UCB1 algorithm, we do not assume any prior on the reward distribution and therefore we have to rely on the Hoeffding’s Inequality for a very generalize estimation. If we are able to know the distribution upfront, we would be able to make better bound estimation.

例如，如果我们期望每个老虎机的平均奖励呈高斯分布，如图 2 所示，我们可以通过将 $\hat{U}_t(a)$ 设置为标准差的两倍来将上限设置为 95% 置信区间。

> For example, if we expect the mean reward of every slot machine to be Gaussian as in Fig 2, we can set the upper bound as 95% confidence interval by setting $\hat{U}_t(a)$ to be twice the standard deviation.

![When the expected reward has a Gaussian distribution. $\sigma(a\_i)$ is the standard deviation and $c\sigma(a\_i)$ is the upper confidence bound. The constant $c$ is a adjustable hyperparameter. (Image source: UCL RL course lecture 9's slides )](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/bern_UCB.png)

查看我用 Beta 先验在 θ 上实现的 [UCB1](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L76) 和 [贝叶斯 UCB](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L99) 的玩具实现。

> Check my toy implementation of [UCB1](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L76) and [Bayesian UCB](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L99) with Beta prior on θ.

### 汤普森采样

> Thompson Sampling

汤普森采样思想简单，但在解决多臂老虎机问题上效果显著。

> Thompson sampling has a simple idea but it works great for solving the multi-armed bandit problem.

![Oops, I guess not this Thompson? (Credit goes to Ben Taborsky ; he has a full theorem of how Thompson invented while pondering over who to pass the ball. Yes I stole his joke.)](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/klay-thompson.jpg)

在每个时间步，我们希望根据动作 a 是 **最优** 的概率来选择动作 a：

> At each time step, we want to select action a according to the probability that a is **optimal**:

$$
\begin{aligned}
\pi(a \; \vert \; h_t) 
&= \mathbb{P} [ Q(a) > Q(a'), \forall a' \neq a \; \vert \; h_t] \\
&= \mathbb{E}_{\mathcal{R} \vert h_t} [ \mathbb{1}(a = \arg\max_{a \in \mathcal{A}} Q(a)) ]
\end{aligned}
$$

其中 $\pi(a ; \vert ; h_t)$ 是在给定历史 $h_t$ 的情况下采取动作 a 的概率。

> where $\pi(a ; \vert ; h_t)$ is the probability of taking action a given the history $h_t$.

对于伯努利多臂赌博机，很自然地假设$Q(a)$遵循[Beta](https://en.wikipedia.org/wiki/Beta_distribution)分布，因为$Q(a)$本质上是[伯努利](https://en.wikipedia.org/wiki/Bernoulli_distribution)分布中的成功概率θ。$\text{Beta}(\alpha, \beta)$的值在区间[0, 1]内；α和β分别对应于我们**成功**或**未能**获得奖励的次数。

英文原文：For the Bernoulli bandit, it is natural to assume that 

$Q(a)$ follows a [Beta](https://en.wikipedia.org/wiki/Beta_distribution) distribution, as 

$Q(a)$ is essentially the success probability θ in [Bernoulli](https://en.wikipedia.org/wiki/Bernoulli_distribution) distribution.  The value of 

$\text{Beta}(\alpha, \beta)$ is within the interval [0, 1]; α and β correspond to the counts when we succeeded or failed to get a reward respectively.

首先，让我们根据对每个行动的一些先验知识或信念来初始化Beta参数α和β。例如，

> First, let us initialize the Beta parameters α and β based on some prior knowledge or belief for every action. For example,

- α = 1且β = 1；我们预期奖励概率为50%，但我们对此不是很确定。
- α = 1000 且 β = 9000; 我们强烈认为奖励概率为 10%。

> • α = 1 and β = 1; we expect the reward probability to be 50% but we are not very confident.
> • α = 1000 and β = 9000; we strongly believe that the reward probability is 10%.

在每个时间 t，我们抽取一个预期奖励，$\tilde{Q}(a)$，从先验分布中$\text{Beta}(\alpha_i, \beta_i)$针对每个动作。从样本中选择最佳动作：$a^{TS}_t = \arg\max_{a \in \mathcal{A}} \tilde{Q}(a)$。观察到真实奖励后，我们可以相应地更新 Beta 分布，这本质上是进行贝叶斯推断，以已知先验和采样数据似然来计算后验。

> At each time t, we sample an expected reward, $\tilde{Q}(a)$, from the prior distribution $\text{Beta}(\alpha_i, \beta_i)$ for every action. The best action is selected among samples: $a^{TS}_t = \arg\max_{a \in \mathcal{A}} \tilde{Q}(a)$. After the true reward is observed, we can update the Beta distribution accordingly, which is essentially doing Bayesian inference to compute the posterior with the known prior and the likelihood of getting the sampled data.

$$
\begin{aligned}
\alpha_i & \leftarrow \alpha_i + r_t \mathbb{1}[a^{TS}_t = a_i] \\ 
\beta_i & \leftarrow \beta_i + (1-r_t) \mathbb{1}[a^{TS}_t = a_i]
\end{aligned}
$$

Thompson 采样实现了[概率匹配](https://en.wikipedia.org/wiki/Probability_matching)的思想。由于其奖励估计$\tilde{Q}$是从后验分布中采样的，因此这些概率中的每一个都等同于在观察到的历史条件下，相应动作是最优的概率。

> Thompson sampling implements the idea of [probability matching](https://en.wikipedia.org/wiki/Probability_matching). Because its reward estimations $\tilde{Q}$ are sampled from posterior distributions, each of these probabilities is equivalent to the probability that the corresponding action is optimal, conditioned on observed history.

然而，对于许多实际和复杂的问题，使用贝叶斯推断估计具有观测真实奖励的后验分布在计算上是难以处理的。如果我们能够使用吉布斯采样、拉普拉斯近似和自举法等方法近似后验分布，汤普森采样仍然可以奏效。这篇[教程](https://arxiv.org/pdf/1707.02038.pdf)提供了一个全面的回顾；如果你想了解更多关于汤普森采样，强烈推荐它。

> However, for many practical and complex problems, it can be computationally intractable to estimate the posterior distributions with observed true rewards using Bayesian inference. Thompson sampling still can work out if we are able to approximate the posterior distributions using methods like Gibbs sampling, Laplace approximate, and the bootstraps. This [tutorial](https://arxiv.org/pdf/1707.02038.pdf) presents a comprehensive review; strongly recommend it if you want to learn more about Thompson sampling.

### 案例研究

> Case Study

我在[lilianweng/multi-armed-bandit](https://github.com/lilianweng/multi-armed-bandit)中实现了上述算法。一个[BernoulliBandit](https://github.com/lilianweng/multi-armed-bandit/blob/master/bandits.py#L13)对象可以通过随机或预定义的奖励概率列表来构建。这些强盗算法被实现为[Solver](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L9)的子类，将一个 Bandit 对象作为目标问题。累积遗憾随时间被跟踪。

> I implemented the above algorithms in [lilianweng/multi-armed-bandit](https://github.com/lilianweng/multi-armed-bandit). A [BernoulliBandit](https://github.com/lilianweng/multi-armed-bandit/blob/master/bandits.py#L13) object can be constructed with a list of random or predefined reward probabilities. The bandit algorithms are implemented as subclasses of [Solver](https://github.com/lilianweng/multi-armed-bandit/blob/master/solvers.py#L9), taking a Bandit object as the target problem. The cumulative regrets are tracked in time.

![The result of a small experiment on solving a Bernoulli bandit with K = 10 slot machines with reward probabilities, {0.0, 0.1, 0.2, ..., 0.9}. Each solver runs 10000 steps.](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/bandit_experiment.png)

### 总结

> Summary

我们需要探索，因为信息是有价值的。就探索策略而言，我们可以完全不进行探索，只关注短期回报。或者我们偶尔随机探索。或者更进一步，我们进行探索，并且对探索哪些选项很挑剔——具有更高不确定性的行动更受青睐，因为它们可以提供更高的信息增益。

> We need exploration because information is valuable. In terms of the exploration strategies, we can do no exploration at all, focusing on the short-term returns. Or we occasionally explore at random. Or even further, we explore and we are picky about which options to explore — actions with higher uncertainty are favored because they can provide higher information gain.

![](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/bandit_solution_summary.png)

引用方式：

> Cited as:

```
@article{weng2018bandit,
  title   = "The Multi-Armed Bandit Problem and Its Solutions",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/"
}
```

### 参考文献

> References

[1] CS229 补充讲义：[霍夫丁不等式](http://cs229.stanford.edu/extra-notes/hoeffding.pdf)。

> [1] CS229 Supplemental Lecture notes: [Hoeffding’s inequality](http://cs229.stanford.edu/extra-notes/hoeffding.pdf).

[2] David Silver 强化学习课程 - 第 9 讲：[探索与利用](https://youtu.be/sGuiWX07sKw)

> [2] RL Course by David Silver - Lecture 9: [Exploration and Exploitation](https://youtu.be/sGuiWX07sKw)

[3] Olivier Chapelle 和 Lihong Li. [“汤普森抽样的实证评估。”](http://papers.nips.cc/paper/4321-an-empirical-evaluation-of-thompson-sampling.pdf) NIPS. 2011。

> [3] Olivier Chapelle and Lihong Li. [“An empirical evaluation of thompson sampling.”](http://papers.nips.cc/paper/4321-an-empirical-evaluation-of-thompson-sampling.pdf) NIPS. 2011.

[4] Russo, Daniel, et al. [“汤普森抽样教程。”](https://arxiv.org/pdf/1707.02038.pdf) arXiv:1707.02038 (2017)。

> [4] Russo, Daniel, et al. [“A Tutorial on Thompson Sampling.”](https://arxiv.org/pdf/1707.02038.pdf) arXiv:1707.02038 (2017).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Multi-armed Bandit | 多臂老虎机 | 一个经典的决策问题，涉及在多个具有未知奖励概率的选项中进行选择，以最大化长期累积奖励。 |
| Exploration-Exploitation Dilemma | 探索与利用困境 | 在决策过程中，需要在尝试新选项（探索）和利用已知最佳选项（利用）之间取得平衡的难题。 |
| Bernoulli Bandit | 伯努利赌博机 | 一种多臂老虎机，其每个“臂”的奖励遵循伯努利分布，即每次尝试只有成功（1）或失败（0）两种结果。 |
| Law of Large Numbers | 大数定律 | 统计学定理，指在大量重复试验中，样本均值会趋近于总体期望值。 |
| Regret | 遗憾 | 在决策理论中，指因未选择最优行动而造成的累积损失。 |
| ε-greedy algorithm | ε-贪婪算法 | 一种简单的探索策略，以小概率随机探索，以大概率选择当前已知最佳行动。 |
| Confidence Upper Bound (UCB) | 置信上限 | 一种探索策略，通过选择具有最高奖励值置信上限的行动，偏向于探索不确定性高的选项。 |
| Hoeffding's Inequality | 霍夫丁不等式 | 一个概率不等式，用于估计有界随机变量样本均值与其期望值之间偏差的概率上限。 |
| Bayesian Inference | 贝叶斯推断 | 一种统计推断方法，通过结合先验知识和观测数据来更新对未知参数的信念。 |
| Thompson Sampling | 汤普森采样 | 一种基于贝叶斯推断的探索策略，根据每个行动是最优的概率来选择行动。 |
| Beta Distribution | Beta分布 | 一种连续概率分布，定义在[0, 1]区间上，常用于表示概率的先验分布或后验分布。 |
| Probability Matching | 概率匹配 | 一种决策策略，其中选择某个选项的概率与该选项获得奖励的概率相匹配。 |
