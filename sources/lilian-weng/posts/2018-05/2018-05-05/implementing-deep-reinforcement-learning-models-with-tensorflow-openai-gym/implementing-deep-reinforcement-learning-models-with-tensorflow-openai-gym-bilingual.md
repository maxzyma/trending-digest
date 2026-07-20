# 使用 Tensorflow + OpenAI Gym 实现深度强化学习模型

> Implementing Deep Reinforcement Learning Models with Tensorflow + OpenAI Gym

> 来源：Lil'Log / Lilian Weng，2018-05-05
> 原文链接：https://lilianweng.github.io/posts/2018-05-05-drl-implementation/
> 分类：深度强化学习 / 模型实现

## 核心要点

- 本文旨在指导读者使用Tensorflow和OpenAI Gym环境，从实践角度实现多种深度强化学习模型。
- 环境设置包括安装Homebrew、创建Python虚拟环境、安装OpenAI Gym及其高级软件包，并克隆项目代码。
- OpenAI Gym工具包提供了一系列物理仿真环境和API，通过`gym.make`初始化环境，并使用`env.reset()`和`env.step()`进行交互。
- 朴素Q学习通过字典跟踪Q值，并采用ε-贪婪策略进行动作选择和探索，同时利用包装器离散化连续观察空间。
- 深度Q网络（DQN）通过引入经验回放和独立更新的目标网络，显著提高了Q学习在非线性函数近似下的训练稳定性和数据效率。
- 双Q学习通过使用两个Q网络解耦动作选择和动作值估计，有效解决了标准Q学习中可能出现的Q值过高估计问题。
- 对偶Q网络采用增强的网络架构，将输出层分支为状态值V和优势A，然后重构Q值以提升学习性能。
- 蒙特卡洛策略梯度（REINFORCE）是一种在策略方法，它通过从完整的在策略轨迹中估计收益，并用策略梯度更新策略参数来学习策略模型。
- Actor-Critic算法同时学习一个用于最佳策略的actor网络和一个用于估计状态值的critic网络，并通过TD目标和TD误差更新两者。

## 正文

完整实现可在 [lilianweng/deep-reinforcement-learning-gym](https://github.com/lilianweng/deep-reinforcement-learning-gym) 中找到

> The full implementation is available in [lilianweng/deep-reinforcement-learning-gym](https://github.com/lilianweng/deep-reinforcement-learning-gym)

在之前的两篇文章中，我介绍了许多深度强化学习模型的算法。现在是时候动手实践，学习如何在实际中实现这些模型了。该实现将基于 Tensorflow 和 OpenAI [gym](https://github.com/openai/gym) 环境。本教程的完整代码版本可在 [[lilian/deep-reinforcement-learning-gym]](https://github.com/lilianweng/deep-reinforcement-learning-gym) 中找到。

> In the previous two posts, I have introduced the algorithms of many deep reinforcement learning models. Now it is the time to get our hands dirty and practice how to implement the models in the wild. The implementation is gonna be built in Tensorflow and OpenAI [gym](https://github.com/openai/gym) environment. The full version of the code in this tutorial is available in [[lilian/deep-reinforcement-learning-gym]](https://github.com/lilianweng/deep-reinforcement-learning-gym).

### 环境设置

> Environment Setup

1. 确保您已安装 [Homebrew](https://docs.brew.sh/Installation)：

> • Make sure you have [Homebrew](https://docs.brew.sh/Installation) installed:

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

1. 我建议为您的开发启动一个 virtualenv。当您有多个项目且它们的需求相互冲突时，这会使事情变得容易得多；例如，一个项目在 Python 2.7 中运行，而另一个项目仅兼容 Python 3.5+。

> • I would suggest starting a virtualenv for your development. It makes life so much easier when you have multiple projects with conflicting requirements; i.e. one works in Python 2.7 while the other is only compatible with Python 3.5+.

```bash
# Install python virtualenv
brew install pyenv-virtualenv
# Create a virtual environment of any name you like with Python 3.6.4 support
pyenv virtualenv 3.6.4 workspace
# Activate the virtualenv named "workspace"
pyenv activate workspace
```

*[*] 对于下面的每一次新安装，请确保您处于 virtualenv 中。*

> *[*] For every new installation below, please make sure you are in the virtualenv.*

1. 根据 [说明](https://github.com/openai/gym#installation) 安装 OpenAI gym。对于最小安装，运行：

> • Install OpenAI gym according to the [instruction](https://github.com/openai/gym#installation). For a minimal installation, run:

```bash
git clone https://github.com/openai/gym.git 
cd gym 
pip install -e .
```

如果您有兴趣玩 Atari 游戏或其他高级软件包，请继续安装几个系统软件包。

> If you are interested in playing with Atari games or other advanced packages, please continue to get a couple of system packages installed.

```bash
brew install cmake boost boost-python sdl2 swig wget
```

对于 Atari，进入 gym 目录并使用 pip 安装。如果您在 ALE（街机学习环境）安装方面遇到问题，这篇 [文章](http://alvinwan.com/installing-arcade-learning-environment-with-python3-on-macosx/) 会很有帮助。

> For Atari, go to the gym directory and pip install it. This [post](http://alvinwan.com/installing-arcade-learning-environment-with-python3-on-macosx/) is pretty helpful if you have troubles with ALE (arcade learning environment) installation.

```bash
pip install -e '.[atari]'
```

1. 最后克隆“playground”代码并安装依赖项。

> • Finally clone the “playground” code and install the requirements.

```bash
git clone git@github.com:lilianweng/deep-reinforcement-learning-gym.git
cd deep-reinforcement-learning-gym
pip install -e .  # install the "playground" project.
pip install -r requirements.txt  # install required packages.
```

### Gym 环境

> Gym Environment

[OpenAI Gym](https://gym.openai.com/) 工具包提供了一组物理仿真环境、游戏和机器人模拟器，我们可以用它们来玩耍并设计强化学习智能体。环境对象可以通过 `gym.make("{environment name}"` 进行初始化：

> The [OpenAI Gym](https://gym.openai.com/) toolkit provides a set of physical simulation environments, games, and robot simulators that we can play with and design reinforcement learning agents for. An environment object can be initialized by `gym.make("{environment name}"`:

```python
import gym
env = gym.make("MsPacman-v0")
```

![(Image source: tf.gather() docs )](https://lilianweng.github.io/posts/2018-05-05-drl-implementation/pacman-original.gif)

环境的动作和观察格式分别由 `env.action_space` 和 `env.observation_space` 定义。

> The formats of action and observation of an environment are defined by `env.action_space` and `env.observation_space`, respectively.

gym [空间](https://gym.openai.com/docs/#spaces) 的类型：

> Types of gym [spaces](https://gym.openai.com/docs/#spaces):

- `gym.spaces.Discrete(n)`：从 0 到 n-1 的离散值。
- `gym.spaces.Box`：一个多维数值向量，每个维度的上限和下限由 `Box.low` 和 `Box.high` 定义。

> • `gym.spaces.Discrete(n)`: discrete values from 0 to n-1.
> • `gym.spaces.Box`: a multi-dimensional vector of numeric values, the upper and lower bounds of each dimension are defined by `Box.low` and `Box.high`.

我们通过两个主要的 API 调用与环境交互：

> We interact with the env through two major api calls:

**`ob = env.reset()`**

> **`ob = env.reset()`**

- 将环境重置为原始设置。
- 返回初始观察。

> • Resets the env to the original setting.
> • Returns the initial observation.

**`ob_next, reward, done, info = env.step(action)`**

> **`ob_next, reward, done, info = env.step(action)`**

- 在环境中应用一个动作，该动作应与 `env.action_space` 兼容。
- 返回新的观察 `ob_next` (env.observation_space)、一个奖励 (float)、一个 `done` 标志 (bool) 和其他元信息 (dict)。如果 `done=True`，则表示回合完成，我们应该重置环境以重新开始。在此处阅读更多 [内容](https://gym.openai.com/docs/#observations)。

> • Applies one action in the env which should be compatible with `env.action_space`.
> • Gets back the new observation `ob_next` (env.observation_space), a reward (float), a `done` flag (bool), and other meta information (dict). If `done=True`, the episode is complete and we should reset the env to restart. Read more [here](https://gym.openai.com/docs/#observations).

### 朴素 Q 学习

> Naive Q-Learning

[Q 学习](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control)（Watkins & Dayan, 1992）学习动作值（“Q 值”）并根据 [贝尔曼方程](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#bellman-equations) 更新它。关键在于，在估计下一个动作时，它不遵循当前策略，而是独立地采用最佳 Q 值（红色部分）。

> [Q-learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control) (Watkins & Dayan, 1992) learns the action value (“Q-value”) and update it according to the [Bellman equation](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#bellman-equations). The key point is while estimating what is the next action, it does not follow the current policy but rather adopt the best Q value (the part in red) independently.

$$
Q(s, a) \leftarrow (1 - \alpha) Q(s, a) + \alpha (r + \gamma \color{red}{\max_{a' \in \mathcal{A}} Q(s', a')})
$$

在朴素实现中，所有 (s, a) 对的 Q 值可以简单地在一个字典中跟踪。目前还没有涉及复杂的机器学习模型。

> In a naive implementation, the Q value for all (s, a) pairs can be simply tracked in a dict. No complicated machine learning model is involved yet.

```python
from collections import defaultdict
Q = defaultdict(float)
gamma = 0.99  # Discounting factor
alpha = 0.5  # soft update param

env = gym.make("CartPole-v0")
actions = range(env.action_space)

def update_Q(s, r, a, s_next, done):
    max_q_next = max([Q[s_next, a] for a in actions]) 
    # Do not include the next state's value if currently at the terminal state.
    Q[s, a] += alpha * (r + gamma * max_q_next * (1.0 - done) - Q[s, a])
```

大多数 gym 环境都有一个多维连续观察空间 (`gym.spaces.Box`)。为了确保我们的 Q 字典不会因为试图记住无限数量的键而“爆炸”，我们应用一个包装器来离散化观察。 [包装器](https://github.com/openai/gym/tree/master/gym/wrappers) 的概念非常强大，通过它我们能够自定义环境的观察、动作、步进函数等。无论应用了多少个包装器，`env.unwrapped` 总是返回内部的原始环境对象。

> Most gym environments have a multi-dimensional continuous observation space (`gym.spaces.Box`). To make sure our Q dictionary will not explode by trying to memorize an infinite number of keys, we apply a wrapper to discretize the observation. The concept of [wrappers](https://github.com/openai/gym/tree/master/gym/wrappers) is very powerful, with which we are capable to customize observation, action, step function, etc. of an env. No matter how many wrappers are applied, `env.unwrapped` always gives back the internal original environment object.

```python
import gym

class DiscretizedObservationWrapper(gym.ObservationWrapper):
    """This wrapper converts a Box observation into a single integer.
    """
    def __init__(self, env, n_bins=10, low=None, high=None):
        super().__init__(env)
        assert isinstance(env.observation_space, Box)

        low = self.observation_space.low if low is None else low
        high = self.observation_space.high if high is None else high

        self.n_bins = n_bins
        self.val_bins = [np.linspace(l, h, n_bins + 1) for l, h in
                         zip(low.flatten(), high.flatten())]
        self.observation_space = Discrete(n_bins ** low.flatten().shape[0])

    def _convert_to_one_number(self, digits):
        return sum([d * ((self.n_bins + 1) ** i) for i, d in enumerate(digits)])

    def observation(self, observation):
        digits = [np.digitize([x], bins)[0]
                  for x, bins in zip(observation.flatten(), self.val_bins)]
        return self._convert_to_one_number(digits)


env = DiscretizedObservationWrapper(
    env, 
    n_bins=8, 
    low=[-2.4, -2.0, -0.42, -3.5], 
    high=[2.4, 2.0, 0.42, 3.5]
)
```

让我们接入与 gym 环境的交互，并在每次生成新转换时更新 Q 函数。在选择动作时，我们使用 ε-贪婪策略来强制探索。

> Let’s plug in the interaction with a gym env and update the Q function every time a new transition is generated. When picking the action, we use ε-greedy to force exploration.

```python
import gym
import numpy as np
n_steps = 100000
epsilon = 0.1  # 10% chances to apply a random action

def act(ob):
    if np.random.random() < epsilon:
        # action_space.sample() is a convenient function to get a random action
        # that is compatible with this given action space.
        return env.action_space.sample()

    # Pick the action with highest q value.
    qvals = {a: q[state, a] for a in actions}
    max_q = max(qvals.values())
    # In case multiple actions have the same maximum q value.
    actions_with_max_q = [a for a, q in qvals.items() if q == max_q]
    return np.random.choice(actions_with_max_q)

ob = env.reset()
rewards = []
reward = 0.0

for step in range(n_steps):
    a = act(ob)
    ob_next, r, done, _ = env.step(a)
    update_Q(ob, r, a, ob_next, done)
    reward += r
    if done:
        rewards.append(reward)
        reward = 0.0
        ob = env.reset()
    else:
        ob = ob_next
```

通常我们从一个较高的 `epsilon` 开始，并在训练过程中逐渐减小它，这被称为“epsilon 退火”。`QLearningPolicy` 的完整代码可在此处 [获取](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/qlearning.py)。

> Often we start with a high `epsilon` and gradually decrease it during the training, known as “epsilon annealing”. The full code of `QLearningPolicy` is available [here](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/qlearning.py).

### 深度 Q 网络

> Deep Q-Network

[深度 Q 网络](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network) 是一项开创性工作，它使得当 Q 值通过非线性函数近似时，Q 学习的训练更加稳定和数据高效。两个关键要素是经验回放和独立更新的目标网络。

> [Deep Q-network](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#deep-q-network) is a seminal piece of work to make the training of Q-learning more stable and more data-efficient, when the Q value is approximated with a nonlinear function. Two key ingredients are experience replay and a separately updated target network.

主要损失函数如下所示，

> The main loss function looks like the following,

$$
\begin{aligned}
& Y(s, a, r, s') = r + \gamma \max_{a'} Q_{\theta^{-}}(s', a') \\
& \mathcal{L}(\theta) = \mathbb{E}_{(s, a, r, s') \sim U(D)} \Big[ \big( Y(s, a, r, s') - Q_\theta(s, a) \big)^2 \Big]
\end{aligned}
$$

Q 网络可以是多层密集神经网络、卷积网络或循环网络，具体取决于问题。在 DQN 策略的 [完整实现](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/dqn.py) 中，它由 `model_type` 参数决定，该参数是 (“dense”, “conv”, “lstm”) 之一。

> The Q network can be a multi-layer dense neural network, a convolutional network, or a recurrent network, depending on the problem. In the [full implementation](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/dqn.py) of the DQN policy, it is determined by the `model_type` parameter, one of (“dense”, “conv”, “lstm”).

在下面的示例中，我使用一个 2 层密集连接神经网络来学习倒立摆平衡问题的 Q 值。

> In the following example,  I’m using a 2-layer densely connected neural network to learn Q values for the cart pole balancing problem.

```python
import gym
env = gym.make('CartPole-v1')
# The observation space is `Box(4,)`, a 4-element vector.
observation_size = env.observation_space.shape[0]
```

我们有一个用于创建网络的辅助函数，如下所示：

> We have a helper function for creating the networks below:

```python
import tensorflow as tf
def dense_nn(inputs, layers_sizes, scope_name):
    """Creates a densely connected multi-layer neural network.
    inputs: the input tensor
    layers_sizes (list<int>): defines the number of units in each layer. The output 
        layer has the size layers_sizes[-1].
    """
    with tf.variable_scope(scope_name):
        for i, size in enumerate(layers_sizes):
            inputs = tf.layers.dense(
                inputs,
                size,
                # Add relu activation only for internal layers.
                activation=tf.nn.relu if i < len(layers_sizes) - 1 else None,
                kernel_initializer=tf.contrib.layers.xavier_initializer(),
                name=scope_name + '_l' + str(i)
            )
    return inputs
```

Q 网络和目标网络通过一批转换（状态、动作、奖励、下一个状态、完成标志）进行更新。输入张量是：

> The Q-network and the target network are updated with a batch of transitions (state, action, reward, state_next, done_flag). The input tensors are:

```python
batch_size = 32  # A tunable hyperparameter.

states = tf.placeholder(tf.float32, shape=(batch_size, observation_size), name='state')
states_next = tf.placeholder(tf.float32, shape=(batch_size, observation_size), name='state_next')
actions = tf.placeholder(tf.int32, shape=(batch_size,), name='action')
rewards = tf.placeholder(tf.float32, shape=(batch_size,), name='reward')
done_flags = tf.placeholder(tf.float32, shape=(batch_size,), name='done')
```

我们有两个结构相同的网络。两者都具有相同的网络架构，以状态观测作为输入，并以所有动作的Q值作为输出。

> We have two networks of the same structure. Both have the same network architectures with the state observation as the inputs and Q values over all the actions as the outputs.

```python
q = dense(states, [32, 32, 2], name='Q_primary')
q_target = dense(states_next, [32, 32, 2], name='Q_target')
```

目标网络“Q_target”将 `states_next` 张量作为输入，因为我们使用其预测来在贝尔曼方程中选择最优的下一个状态。

> The target network “Q_target” takes the `states_next` tensor as the input, because we use its prediction to select the optimal next state in the Bellman equation.

```python
# The prediction by the primary Q network for the actual actions.
action_one_hot = tf.one_hot(actions, act_size, 1.0, 0.0, name='action_one_hot')
pred = tf.reduce_sum(q * action_one_hot, reduction_indices=-1, name='q_acted')

# The optimization target defined by the Bellman equation and the target network.
max_q_next_by_target = tf.reduce_max(q_target, axis=-1)
y = rewards + (1. - done_flags) * gamma * max_q_next_by_target

# The loss measures the mean squared error between prediction and target.
loss = tf.reduce_mean(tf.square(pred - tf.stop_gradient(y)), name="loss_mse_train")
optimizer = tf.train.AdamOptimizer(0.001).minimize(loss, name="adam_optim")
```

请注意，目标 y 上有 [tf.stop_gradient()](https://www.tensorflow.org/api_docs/python/tf/stop_gradient)，因为目标网络在最小化损失的梯度更新期间应保持固定。

> Note that [tf.stop_gradient()](https://www.tensorflow.org/api_docs/python/tf/stop_gradient) on the target y, because the target network should stay fixed during the loss-minimizing gradient update.

![(Image source: tf.gather() docs )](https://lilianweng.github.io/posts/2018-05-05-drl-implementation/dqn-tensorboard-graph.png)

目标网络通过每 `C` 步复制主Q网络参数（“硬更新”）或通过向主网络进行 Polyak 平均（“软更新”）来更新。

> The target network is updated by copying the primary Q network parameters over every `C` number of steps (“hard update”) or polyak averaging towards the primary network (“soft update”)

```python
# Get all the variables in the Q primary network.
q_vars = tf.get_collection(tf.GraphKeys.GLOBAL_VARIABLES, scope="Q_primary")
# Get all the variables in the Q target network.
q_target_vars = tf.get_collection(tf.GraphKeys.GLOBAL_VARIABLES, scope="Q_target")
assert len(q_vars) == len(q_target_vars)

def update_target_q_net_hard():
    # Hard update
    sess.run([v_t.assign(v) for v_t, v in zip(q_target_vars, q_vars)])

def update_target_q_net_soft(tau=0.05):
    # Soft update: polyak averaging.
    sess.run([v_t.assign(v_t * (1. - tau) + v * tau) for v_t, v in zip(q_target_vars, q_vars)])
```

#### 双Q学习

> Double Q-Learning

如果我们查看Q值目标的标准形式 $Y(s, a) = r + \gamma \max_{a’ \in \mathcal{A}} Q_\theta (s’, a’)$，很容易注意到我们使用 $Q_\theta$ 来选择状态 s' 下的最佳下一个动作，然后应用由相同的 $Q_\theta$ 预测的动作值。这种两步强化过程可能会导致对（已经）高估的值的进一步高估，从而导致训练不稳定。双Q学习（[Hasselt, 2010](http://papers.nips.cc/paper/3964-double-q-learning.pdf)）提出的解决方案是使用两个Q网络 $Q_1$ 和 $Q_2$ 来解耦动作选择和动作值估计：当 $Q_1$ 正在更新时，$Q_2$ 决定最佳的下一个动作，反之亦然。

> If we look into the standard form of the Q value target, $Y(s, a) = r + \gamma \max_{a’ \in \mathcal{A}} Q_\theta (s’, a’)$, it is easy to notice that we use $Q_\theta$ to select the best next action at state s’ and then apply the action value predicted by the same $Q_\theta$. This two-step reinforcing procedure could potentially lead to overestimation of an (already) overestimated value, further leading to training instability. The solution proposed by double Q-learning ([Hasselt, 2010](http://papers.nips.cc/paper/3964-double-q-learning.pdf)) is to decouple the action selection and action value estimation by using two Q networks, $Q_1$ and $Q_2$: when $Q_1$ is being updated, $Q_2$ decides the best next action, and vice versa.

$$
Y_1(s, a, r, s') = r + \gamma Q_1 (s', \arg\max_{a' \in \mathcal{A}}Q_2(s', a'))\\
Y_2(s, a, r, s') = r + \gamma Q_2 (s', \arg\max_{a' \in \mathcal{A}}Q_1(s', a'))
$$

为了将双Q学习整合到DQN中，最小的修改（[Hasselt, Guez, & Silver, 2016](https://arxiv.org/pdf/1509.06461.pdf)）是使用主Q网络来选择动作，同时动作值由目标网络估计：

> To incorporate double Q-learning into DQN, the minimum modification ([Hasselt, Guez, & Silver, 2016](https://arxiv.org/pdf/1509.06461.pdf)) is to use the primary Q network to select the action while the action value is estimated by the target network:

$$
Y(s, a, r, s') = r + \gamma Q_{\theta^{-}}(s', \arg\max_{a' \in \mathcal{A}} Q_\theta(s', a'))
$$

在代码中，我们添加了一个新的张量，用于获取由主Q网络选择的动作作为输入，以及一个用于选择此动作的张量操作。

> In the code, we add a new tensor for getting the action selected by the primary Q network as the input and a tensor operation for selecting this action.

```python
actions_next = tf.placeholder(tf.int32, shape=(None,), name='action_next')
actions_selected_by_q = tf.argmax(q, axis=-1, name='action_selected')
```

损失函数中的预测目标 y 变为：

> The prediction target y in the loss function becomes:

```python
actions_next_flatten = actions_next + tf.range(0, batch_size) * q_target.shape[1]
max_q_next_target = tf.gather(tf.reshape(q_target, [-1]), actions_next_flatten)
y = rewards + (1. - done_flags) * gamma * max_q_next_by_target
```

这里我使用了[tf.gather()](https://www.tensorflow.org/api_docs/python/tf/gather)来选择感兴趣的动作值。

> Here I used [tf.gather()](https://www.tensorflow.org/api_docs/python/tf/gather) to select the action values of interests.

![(Image source: tf.gather() docs )](https://lilianweng.github.io/posts/2018-05-05-drl-implementation/tf_gather.png)

在回合展开期间，我们计算`actions_next`，通过将下一状态的数据输入到`actions_selected_by_q`操作中。

> During the episode rollout, we compute the `actions_next` by feeding the next states’ data into the `actions_selected_by_q` operation.

```python
# batch_data is a dict with keys, ‘s', ‘a', ‘r', ‘s_next' and ‘done', containing a batch of transitions.
actions_next = sess.run(actions_selected_by_q, {states: batch_data['s_next']})
```

#### 对偶Q网络

> Dueling Q-Network

对偶Q网络（[Wang 等人，2016](https://arxiv.org/pdf/1511.06581.pdf)）配备了增强的网络架构：输出层分支为两个头部，一个用于预测状态值V，另一个用于[优势](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-function)A。然后重构Q值，$Q(s, a) = V(s) + A(s, a)$。

> The dueling Q-network ([Wang et al., 2016](https://arxiv.org/pdf/1511.06581.pdf)) is equipped with an enhanced network architecture: the output layer branches out into two heads, one for predicting state value, V, and the other for [advantage](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#value-function), A. The Q-value is then reconstructed, $Q(s, a) = V(s) + A(s, a)$.

$$
\begin{aligned}
A(s, a) &= Q(s, a) - V(s)\\
V(s) &= \sum_a Q(s, a) \pi(a \vert s) = \sum_a (V(s) + A(s, a)) \pi(a \vert s) = V(s) + \sum_a A(s, a)\pi(a \vert s)\\
\text{Thus, }& \sum_a A(s, a)\pi(a \vert s) = 0
\end{aligned}
$$

为确保估计的优势值总和为零，$\sum_a A(s, a)\pi(a \vert s) = 0$，我们从预测中减去平均值。

> To make sure the estimated advantage values sum up to zero, $\sum_a A(s, a)\pi(a \vert s) = 0$, we deduct the mean value from the prediction.

$$
Q(s, a) = V(s) + (A(s, a) - \frac{1}{|\mathcal{A}|} \sum_a A(s, a))
$$

代码更改很简单：

> The code change is straightforward:

```python
q_hidden = dense_nn(states, [32], name='Q_primary_hidden')
adv = dense_nn(q_hidden, [32, env.action_space.n], name='Q_primary_adv')
v = dense_nn(q_hidden, [32, 1], name='Q_primary_v')

# Average dueling
q = v + (adv - tf.reduce_mean(adv, reduction_indices=1, keepdims=True))
```

![(Image source: Wang et al., 2016 )](https://lilianweng.github.io/posts/2018-05-05-drl-implementation/dueling-q-network.png)

查看[代码](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/dqn.py)以了解完整流程。

> Check the [code](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/dqn.py) for the complete flow.

### 蒙特卡洛策略梯度

> Monte-Carlo Policy Gradient

我在[上一篇文章](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/)中回顾了一些流行的策略梯度方法。蒙特卡洛策略梯度，也称为[REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce)，是一种经典的在策略方法，它明确地学习策略模型。它使用从完整的在策略轨迹中估计的收益，并用策略梯度更新策略参数。

> I reviewed a number of popular policy gradient methods in my [last post](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/). Monte-Carlo policy gradient, also known as [REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce), is a classic on-policy method that learns the policy model explicitly. It uses the return estimated from a full on-policy trajectory and updates the policy parameters with policy gradient.

收益在rollout期间计算，然后作为输入馈送到Tensorflow图中。

> The returns are computed during rollouts and then fed into the Tensorflow graph as inputs.

```python
# Inputs
states = tf.placeholder(tf.float32, shape=(None, obs_size), name='state')
actions = tf.placeholder(tf.int32, shape=(None,), name='action')
returns = tf.placeholder(tf.float32, shape=(None,), name='return')
```

策略网络已构建。我们通过最小化损失函数 $\mathcal{L} = - (G_t - V(s)) \log \pi(a \vert s)$ 来更新策略参数。
[tf.nn.sparse_softmax_cross_entropy_with_logits()](https://www.tensorflow.org/api_docs/python/tf/nn/sparse_softmax_cross_entropy_with_logits) 要求将原始 logits 作为输入，而不是 softmax 后的概率，这就是为什么我们不在策略网络之上添加 softmax 层的原因。

> The policy network is contructed. We update the policy parameters by minimizing the loss function, $\mathcal{L} = - (G_t - V(s)) \log \pi(a \vert s)$.
> [tf.nn.sparse_softmax_cross_entropy_with_logits()](https://www.tensorflow.org/api_docs/python/tf/nn/sparse_softmax_cross_entropy_with_logits) asks for the raw logits as inputs, rather then the probabilities after softmax, and that’s why we do not have a softmax layer on top of the policy network.

```python
# Policy network
pi = dense_nn(states, [32, 32, env.action_space.n], name='pi_network')
sampled_actions = tf.squeeze(tf.multinomial(pi, 1))  # For sampling actions according to probabilities.

with tf.variable_scope('pi_optimize'):
    loss_pi = tf.reduce_mean(
        returns * tf.nn.sparse_softmax_cross_entropy_with_logits(
            logits=pi, labels=actions), name='loss_pi')
    optim_pi = tf.train.AdamOptimizer(0.001).minimize(loss_pi, name='adam_optim_pi')
```

在回合展开期间，回报计算如下：

> During the episode rollout, the return is calculated as follows:

```python
# env = gym.make(...)
# gamma = 0.99
# sess = tf.Session(...)

def act(ob):
    return sess.run(sampled_actions, {states: [ob]})

for _ in range(n_episodes):
    ob = env.reset()
    done = False

    obs = []
    actions = []
    rewards = []
    returns = []

    while not done:
        a = act(ob)
        new_ob, r, done, info = env.step(a)

        obs.append(ob)
        actions.append(a)
        rewards.append(r)
        ob = new_ob

    # Estimate returns backwards.
    return_so_far = 0.0
    for r in rewards[::-1]:
        return_so_far = gamma * return_so_far + r
        returns.append(return_so_far)

    returns = returns[::-1]

    # Update the policy network with the data from one episode.
    sess.run([optim_pi], feed_dict={
        states: np.array(obs),
        actions: np.array(actions),
        returns: np.array(returns),
    })
```

REINFORCE 的完整实现请见[此处](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/reinforce.py)。

> The full implementation of REINFORCE is [here](https://github.com/lilianweng/deep-reinforcement-learning-gym/blob/master/playground/policies/reinforce.py).

### Actor-Critic

> Actor-Critic

[Actor-critic](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#actor-critic) 算法同时学习两个模型：actor 用于学习最佳策略，critic 用于估计状态值。

> The [actor-critic](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#actor-critic) algorithm learns two models at the same time, the actor for learning the best policy and the critic for estimating the state value.

1\. 初始化 actor 网络 $\pi(a \vert s)$ 和 critic $V(s)$

2\. 收集新的转换 (s, a, r, s’): 为当前状态 s 采样动作 $a \sim \pi(a \vert s)$，并获得奖励 r 和下一个状态 s'。

3\. 在回合展开期间计算 TD 目标 $G_t = r + \gamma V(s’)$ 和 TD 误差 $\delta_t = r + \gamma V(s’) - V(s)$。

4\. 通过最小化 critic 损失来更新 critic 网络：$L_c = (V(s) - G_t)$。

5\. 通过最小化 actor 损失来更新 actor 网络：$L_a = - \delta_t \log \pi(a \vert s)$。

6\. 设置 s’ = s 并重复步骤 2-5。

英文原文：

1\. Initialize the actor network, $\pi(a \vert s)$ and the critic, $V(s)$

2\. Collect a new transition (s, a, r, s’): Sample the action $a \sim \pi(a \vert s)$ for the current state s, and get the reward r and the next state s'.

3\. Compute the TD target during episode rollout, $G_t = r + \gamma V(s’)$ and TD error, $\delta_t = r + \gamma V(s’) - V(s)$.

4\. Update the critic network by minimizing the critic loss: $L_c = (V(s) - G_t)$.

5\. Update the actor network by minimizing the actor loss: $L_a = - \delta_t \log \pi(a \vert s)$.

6\. Set s’ = s and repeat step 2.-5.

总的来说，该实现与带有额外 critic 网络的 REINFORCE 非常相似。完整实现请见此处。

> Overall the implementation looks pretty similar to REINFORCE with an extra critic network. The full implementation is here.

```python
# Inputs
states = tf.placeholder(tf.float32, shape=(None, observation_size), name='state')
actions = tf.placeholder(tf.int32, shape=(None,), name='action')
td_targets = tf.placeholder(tf.float32, shape=(None,), name='td_target')

# Actor: action probabilities
actor = dense_nn(states, [32, 32, env.action_space.n], name='actor')

# Critic: action value (Q-value)
critic = dense_nn(states, [32, 32, 1], name='critic')

action_ohe = tf.one_hot(actions, act_size, 1.0, 0.0, name='action_one_hot')
pred_value = tf.reduce_sum(critic * action_ohe, reduction_indices=-1, name='q_acted')
td_errors = td_targets - tf.reshape(pred_value, [-1])

with tf.variable_scope('critic_train'):
    loss_c = tf.reduce_mean(tf.square(td_errors))
    optim_c = tf.train.AdamOptimizer(0.01).minimize(loss_c)

with tf.variable_scope('actor_train'):
    loss_a = tf.reduce_mean(
        tf.stop_gradient(td_errors) * tf.nn.sparse_softmax_cross_entropy_with_logits(
            logits=actor, labels=actions),
        name='loss_actor')
    optim_a = tf.train.AdamOptimizer(0.01).minimize(loss_a)

train_ops = [optim_c, optim_a]
```

Tensorboard 图表总是很有帮助：

> The tensorboard graph is always helpful:

![](https://lilianweng.github.io/posts/2018-05-05-drl-implementation/actor-critic-tensorboard-graph.png)

### 参考文献

> References

[1] [Tensorflow API 文档](https://www.tensorflow.org/api_docs/)

> [1] [Tensorflow API Docs](https://www.tensorflow.org/api_docs/)

[2] Christopher JCH Watkins 和 Peter Dayan。[“Q-learning.”](https://link.springer.com/content/pdf/10.1007/BF00992698.pdf) Machine learning 8.3-4 (1992): 279-292。

> [2] Christopher JCH Watkins, and Peter Dayan. [“Q-learning.”](https://link.springer.com/content/pdf/10.1007/BF00992698.pdf) Machine learning 8.3-4 (1992): 279-292.

[3] Hado Van Hasselt, Arthur Guez 和 David Silver。[“Deep Reinforcement Learning with Double Q-Learning.”](https://arxiv.org/pdf/1509.06461.pdf) AAAI. Vol. 16. 2016。

> [3] Hado Van Hasselt, Arthur Guez, and David Silver. [“Deep Reinforcement Learning with Double Q-Learning.”](https://arxiv.org/pdf/1509.06461.pdf) AAAI. Vol. 16. 2016.

[4] Hado van Hasselt。[“Double Q-learning.”](http://papers.nips.cc/paper/3964-double-q-learning.pdf) NIPS, 23:2613–2621, 2010。

> [4] Hado van Hasselt. [“Double Q-learning.”](http://papers.nips.cc/paper/3964-double-q-learning.pdf) NIPS, 23:2613–2621, 2010.

[5] Ziyu Wang 等。[Dueling network architectures for deep reinforcement learning.](https://arxiv.org/pdf/1511.06581.pdf) ICML. 2016。

> [5] Ziyu Wang, et al. [Dueling network architectures for deep reinforcement learning.](https://arxiv.org/pdf/1511.06581.pdf) ICML. 2016.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Tensorflow | 深度学习框架 | 一个开源机器学习框架，用于构建和训练神经网络。 |
| OpenAI Gym | 强化学习工具包 | 一个用于开发和比较强化学习算法的工具包，提供各种环境。 |
| virtualenv | Python虚拟环境 | 一个独立的Python运行环境，用于管理项目依赖。 |
| Q-learning | Q学习 | 一种无模型强化学习算法，用于学习动作值函数。 |
| Bellman Equation | 贝尔曼方程 | 强化学习中用于描述最优值函数或Q值函数之间关系的方程。 |
| epsilon-greedy strategy | ε-贪婪策略 | 一种在强化学习中平衡探索与利用的策略，以小概率随机选择动作。 |
| Deep Q Network (DQN) | 深度Q网络 | 一种结合深度学习和Q学习的算法，使用神经网络近似Q值函数。 |
| experience replay | 经验回放 | DQN中用于存储和随机采样历史经验，以打破数据相关性并提高训练稳定性。 |
| target network | 目标网络 | DQN中用于计算Q值目标的一个独立网络，其参数定期从主网络复制。 |
| Double Q-learning | 双Q学习 | 一种改进的Q学习算法，通过使用两个Q网络解耦动作选择和值估计，以减少Q值过高估计。 |
| Dueling Q-network | 对偶Q网络 | 一种DQN架构，将Q值分解为状态值和优势函数，以提高学习效率。 |
| state value (V) | 状态值 | 衡量在给定策略下，从某个状态开始的预期累积奖励。 |
| advantage (A) | 优势 | 衡量在给定状态下，某个动作相对于平均动作的额外价值。 |
| Monte Carlo Policy Gradient (REINFORCE) | 蒙特卡洛策略梯度 (REINFORCE) | 一种基于蒙特卡洛采样的策略梯度算法，通过完整轨迹的收益更新策略。 |
| Actor-Critic | Actor-Critic | 一类强化学习算法，同时学习一个策略（actor）和一个值函数（critic）。 |
