# 神经网络架构搜索

> Neural Architecture Search

> 来源：Lil'Log / Lilian Weng，2020-08-06
> 原文链接：https://lilianweng.github.io/posts/2020-08-06-nas/
> 分类：机器学习 / 神经网络架构搜索

## 核心要点

- 神经网络架构搜索（NAS）旨在通过自动化方法发现高性能模型架构，超越人类专家设计。
- NAS系统通常由搜索空间、搜索算法和评估策略三个核心组件构成。
- 搜索空间定义了网络操作及其连接方式，可分为顺序逐层、基于单元、分层结构和记忆库表示等类型。
- 搜索算法包括随机搜索、强化学习、演化算法、渐进式决策过程和基于梯度下降的方法。
- 评估策略旨在高效衡量子模型性能，涵盖从头训练、代理任务、参数共享、基于预测和一次性方法。
- 可微分架构搜索（DARTS）通过连续松弛使架构参数可微分，实现了架构与权重联合优化，显著降低了计算成本。
- ProxylessNAS将NAS视为路径级剪枝，并考虑设备延迟作为优化指标，进一步节省了内存并适应特定硬件。
- 未来的NAS研究将侧重于理解架构性能原因、提高泛化能力、考虑设备特定约束以及探索无监督和自动化机器学习算法本身。

## 正文

尽管大多数流行且成功的模型架构都是由人类专家设计的，但这并不意味着我们已经探索了整个网络架构空间并找到了最佳选择。如果我们采用系统化、自动化的方式来学习高性能模型架构，我们将有更好的机会找到最优解。

> Although most popular and successful model architectures are designed by human experts, it doesn’t mean we have explored the entire network architecture space and settled down with the best option. We would have a better chance to find the optimal solution if we adopt a systematic and automatic way of learning high-performance model architectures.

自动学习和演化网络拓扑结构并非新想法（[Stanley & Miikkulainen, 2002](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf)）。近年来，[Zoph & Le 2017](https://arxiv.org/abs/1611.01578) 和 [Baker et al. 2017](https://arxiv.org/abs/1611.02167) 的开创性工作吸引了大量关注到神经网络架构搜索（NAS）领域，从而产生了许多关于更好、更快、更具成本效益的NAS方法的有趣想法。

> Automatically learning and evolving network topologies is not a new idea ([Stanley & Miikkulainen, 2002](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf)). In recent years, the pioneering work by [Zoph & Le 2017](https://arxiv.org/abs/1611.01578) and [Baker et al. 2017](https://arxiv.org/abs/1611.02167) has attracted a lot of attention into the field of Neural Architecture Search (NAS), leading to many interesting ideas for better, faster and more cost-efficient NAS methods.

当我开始研究NAS时，我发现 [Elsken, et al 2019](https://arxiv.org/abs/1808.05377) 的这篇综述非常有帮助。他们将NAS描述为一个包含三个主要组件的系统，这种描述清晰简洁，并且在其他NAS论文中也常被采用。

> As I started looking into NAS, I found this nice survey very helpful by [Elsken, et al 2019](https://arxiv.org/abs/1808.05377). They characterize NAS as a system with three major components, which is clean & concise, and also commonly adopted in other NAS papers.

1. **搜索空间**：NAS搜索空间定义了一组操作（例如卷积、全连接、池化）以及这些操作如何连接以形成有效的网络架构。搜索空间的设计通常涉及人类专业知识，以及不可避免的人类偏见。
2. **搜索算法**：NAS搜索算法对一组网络架构候选进行采样。它接收子模型的性能指标作为奖励（例如高准确率、低延迟），并进行优化以生成高性能的架构候选。
3. **评估策略**：我们需要测量、估计或预测大量提出的子模型的性能，以便为搜索算法的学习提供反馈。候选评估过程可能非常昂贵，因此已经提出了许多新方法来节省时间或计算资源。

> • **Search space**: The NAS search space defines a set of operations (e.g. convolution, fully-connected, pooling) and how operations can be connected to form valid network architectures. The design of search space usually involves human expertise, as well as unavoidably human biases.
> • **Search algorithm**: A NAS search algorithm samples a population of network architecture candidates. It receives the child model performance metrics as rewards (e.g. high accuracy, low latency) and optimizes to generate high-performance architecture candidates.
> • **Evaluation strategy**: We need to measure, estimate, or predict the performance of a large number of proposed child models in order to obtain feedback for the search algorithm to learn. The process of candidate evaluation could be very expensive and many new methods have been proposed to save time or computation resources.

![Three main components of Neural Architecture Search (NAS) models.  (Image source: Elsken, et al. 2019 with customized annotation in red)](https://lilianweng.github.io/posts/2020-08-06-nas/NAS-high-level.png)

### 搜索空间

> Search Space

NAS搜索空间定义了一组基本的网络操作以及这些操作如何连接以构建有效的网络架构。

> The NAS search space defines a set of basic network operations and how operations can be connected to construct valid network architectures.

#### 顺序逐层操作

> Sequential Layer-wise Operations

设计神经网络架构搜索空间最朴素的方法是使用一系列*顺序逐层操作*来描述网络拓扑结构，无论是CNN还是RNN，这在 [Zoph & Le 2017](https://arxiv.org/abs/1611.01578) 和 [Baker et al. 2017](https://arxiv.org/abs/1611.02167) 的早期工作中可见。网络表示的序列化需要相当多的专业知识，因为每个操作都与不同的层特定参数相关联，并且这些关联需要硬编码。例如，在预测一个 `conv` 操作后，模型应该输出核大小、步长大小等；或者在预测一个 `FC` 操作后，我们需要将单元数量作为下一个预测。

> The most naive way to design the search space for neural network architectures is to depict network topologies, either CNN or RNN, with a list of *sequential layer-wise operations*, as seen in the early work of [Zoph & Le 2017](https://arxiv.org/abs/1611.01578) & [Baker et al. 2017](https://arxiv.org/abs/1611.02167). The serialization of network representation requires a decent amount of expert knowledge, since each operation is associated with different layer-specific parameters and such associations need to be hardcoded. For example, after predicting a `conv` op, the model should output kernel size, stride size, etc; or after predicting an `FC` op, we need to see the number of units as the next prediction.

![(Top) A sequential representation of CNN. (Bottom) A sequential representation of the tree structure of a recurrent cell. (Image source: Zoph & Le 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/NAS-search-space.png)

为了确保生成的架构有效，可能需要额外的规则（[Zoph & Le 2017](https://arxiv.org/abs/1611.01578)）：

> To make sure the generated architecture is valid, additional rules might be needed ([Zoph & Le 2017](https://arxiv.org/abs/1611.01578)):

- 如果一个层没有连接到任何输入层，那么它被用作输入层；
- 在最后一层，获取所有未连接的层输出并将它们连接起来；
- 如果一个层有多个输入层，那么所有输入层都在深度维度上进行连接；
- 如果要连接的输入层大小不同，我们用零填充较小的层，使连接后的层具有相同的大小。

> • If a layer is not connected to any input layer then it is used as the input layer;
> • At the final layer, take all layer outputs that have not been connected and concatenate them;
> • If one layer has many input layers, then all input layers are concatenated in the depth dimension;
> • If input layers to be concatenated have different sizes, we pad the small layers with zeros so that the concatenated layers have the same sizes.

跳跃连接也可以通过 [注意力](https://lilianweng.github.io/posts/2018-06-24-attention/) 机制来预测。在层 $i$ 处，添加一个锚点，带有 $i−1$ 个基于内容的 sigmoid，以指示要连接到哪些前一层。每个 sigmoid 都将当前节点 $h_i$ 和 $i-1$ 个前一个节点 $h_j, j=1, \dots, i-1$ 的隐藏状态作为输入。

> The skip connection can be predicted as well, using an [attention](https://lilianweng.github.io/posts/2018-06-24-attention/)-style mechanism. At layer $i$ , an anchor point is added with $i−1$ content-based sigmoids to indicate which of the previous layers to be connected. Each sigmoid takes as input the hidden states of the current node $h_i$ and $i-1$ previous nodes $h_j, j=1, \dots, i-1$ .

$$
P(\text{Layer j is an input to layer i}) = \text{sigmoid}(v^\top \tanh(\mathbf{W}_\text{prev} h_j + \mathbf{W}_\text{curr} h_i))
$$

顺序搜索空间具有很强的表示能力，但它非常庞大，并且需要消耗大量的计算资源才能穷尽搜索空间。在 [Zoph & Le 2017](https://arxiv.org/abs/1611.01578) 的实验中，他们并行运行了800个GPU长达28天，而 [Baker et al. 2017](https://arxiv.org/abs/1611.02167) 将搜索空间限制为最多包含2个 `FC` 层。

> The sequential search space has a lot of representation power, but it is very large and consumes a ton of computation resources to exhaustively cover the search space. In the experiments by [Zoph & Le 2017](https://arxiv.org/abs/1611.01578), they were running 800 GPUs in parallel for 28 days and [Baker et al. 2017](https://arxiv.org/abs/1611.02167) restricted the search space to contain at most 2 `FC` layers.

#### 基于单元的表示

> Cell-based Representation

受成功视觉模型架构（例如Inception、ResNet）中重复模块设计的启发，*NASNet搜索空间*（[Zoph et al. 2018](https://arxiv.org/abs/1707.07012)）将卷积网络的架构定义为同一个单元重复多次，并且每个单元包含由NAS算法预测的多个操作。精心设计的单元模块实现了数据集之间的可迁移性。通过调整单元重复次数，还可以轻松地缩小或扩大模型大小。

> Inspired by the design of using repeated modules in successful vision model architectures (e.g. Inception, ResNet), the *NASNet search space* ([Zoph et al. 2018](https://arxiv.org/abs/1707.07012)) defines the architecture of a conv net as the same cell getting repeated multiple times and each cell contains several operations predicted by the NAS algorithm. A well-designed cell module enables transferability between datasets. It is also easy to scale down or up the model size by adjusting the number of cell repeats.

具体来说，NASNet搜索空间学习两种类型的单元用于网络构建：

> Precisely, the NASNet search space learns two types of cells for network construction:

1. *普通单元*：输入和输出特征图具有相同的维度。
2. *缩减单元*：输出特征图的宽度和高度减半。

> • *Normal Cell*: The input and output feature maps have the same dimension.
> • *Reduction Cell*: The output feature map has its width and height reduced by half.

![The NASNet search space constrains the architecture as a repeated stack of cells. The cell architecture is optimized via NAS algorithms. (Image source: Zoph et al. 2018 )](https://lilianweng.github.io/posts/2020-08-06-nas/NASNet-search-space.png)

每个单元格的预测被分组为$B$个块（在NASNet论文中是$B=5$），其中每个块有5个预测步骤，由5个不同的softmax分类器完成，对应于块元素的离散选择。请注意，NASNet搜索空间在单元格之间没有残差连接，模型只在块内部自行学习跳跃连接。

> The predictions for each cell are grouped into $B$ blocks ($B=5$ in the NASNet paper), where each block has 5 prediction steps made by 5 distinct softmax classifiers corresponding to discrete choices of the elements of a block. Note that the NASNet search space does not have residual connections between cells and the model only learns skip connections on their own within blocks.

![(a) Each cell consists of $B$ blocks and each block is predicted by 5 discrete decisions. (b) An concrete example of what operations can be chosen in each decision step.](https://lilianweng.github.io/posts/2020-08-06-nas/cell-prediction-steps.png)

在实验过程中，他们发现[DropPath](https://arxiv.org/abs/1605.07648)的一个修改版本，名为*ScheduledDropPath*，显著提高了NASNet实验的最终性能。DropPath以固定概率随机丢弃路径（即NASNet中附带操作的边）。ScheduledDropPath是DropPath的一种，其路径丢弃概率在训练期间线性增加。

> During the experiments, they discovered that a modified version of [DropPath](https://arxiv.org/abs/1605.07648), named *ScheduledDropPath*, significantly improves the final performance of NASNet experiments. DropPath stochastically drops out paths (i.e. edges with operations attached in NASNet) with a fixed probability. ScheduledDropPath is DropPath with a linearly increasing probability of path dropping during training time.

[Elsken等人（2019）](https://arxiv.org/abs/1808.05377)指出了NASNet搜索空间的三个主要优点：

> [Elsken, et al (2019)](https://arxiv.org/abs/1808.05377) point out three major advantages of the NASNet search space:

1. 搜索空间大小大幅减少；
2. 基于[基元](https://en.wikipedia.org/wiki/Network_motif)的架构可以更容易地迁移到不同的数据集。
3. 它有力地证明了在架构工程中重复堆叠模块是一种有用的设计模式。例如，我们可以通过在CNN中堆叠残差块或在Transformer中堆叠多头注意力块来构建强大的模型。

> • The search space size is reduced drastically;
> • The [motif](https://en.wikipedia.org/wiki/Network_motif)-based architecture can be more easily transferred to different datasets.
> • It demonstrates a strong proof of a useful design pattern of repeatedly stacking modules in architecture engineering. For example, we can build strong models by stacking residual blocks in CNN or stacking multi-headed attention blocks in Transformer.

#### 分层结构

> Hierarchical Structure

为了利用已发现的精心设计的网络[基元](https://en.wikipedia.org/wiki/Network_motif)，NAS搜索空间可以被约束为分层结构，如*分层NAS*（**HNAS**；（[Liu et al 2017](https://arxiv.org/abs/1711.00436)））所示。它从一小组原语开始，包括卷积操作、池化、恒等映射等单个操作。然后，由原语操作组成的小型子图（或“基元”）被递归地用于形成更高级别的计算图。

> To take advantage of already discovered well-designed network [motifs](https://en.wikipedia.org/wiki/Network_motif), the NAS search space can be constrained as a hierarchical structure, as in *Hierarchical NAS* (**HNAS**; ([Liu et al 2017](https://arxiv.org/abs/1711.00436))). It starts with a small set of primitives, including individual operations like convolution operation, pooling, identity, etc. Then small sub-graphs (or “motifs”) that consist of primitive operations are recursively used to form higher-level computation graphs.

级别$\ell=1, \dots, L$的计算基元可以用$(G^{(\ell)}, \mathcal{O}^{(\ell)})$表示，其中：

> A computation motif at level $\ell=1, \dots, L$ can be represented by $(G^{(\ell)}, \mathcal{O}^{(\ell)})$, where:

• $\mathcal{O}^{(\ell)}$是一组操作，$\mathcal{O}^{(\ell)} = \{ o^{(\ell)}_1, o^{(\ell)}_2, \dots \}$

• $G^{(\ell)}$是一个邻接矩阵，其中条目$G_{ij}=k$表示操作$o^{(\ell)}_k$位于节点$i$和$j$之间。节点索引遵循DAG中的[拓扑排序](https://en.wikipedia.org/wiki/Topological_sorting)，其中索引$1$是源节点，最大索引是汇点节点。

英文原文：

• $\mathcal{O}^{(\ell)}$ is a set of operations, $\mathcal{O}^{(\ell)} = \{ o^{(\ell)}_1, o^{(\ell)}_2, \dots \}$

• $G^{(\ell)}$ is an adjacency matrix, where the entry $G_{ij}=k$ indicates that operation $o^{(\ell)}_k$ is placed between node $i$ and $j$. The node indices follow [topological ordering](https://en.wikipedia.org/wiki/Topological_sorting) in DAG, where the index $1$ is the source and the maximal index is the sink node.

![(Top) Three level-1 primitive operations are composed into a level-2 motif. (Bottom) Three level-2 motifs are plugged into a base network structure and assembled into a level-3 motif. (Image source: Liu et al 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/hierarchical-NAS-search-space.png)

为了根据层次结构构建网络，我们从最低层 $\ell=1$ 开始，并递归地将第 $m$ 个基序操作定义为在 $\ell$ 层的

> To build a network according to the hierarchical structure, we start from the lowest level $\ell=1$ and recursively define the $m$ -th motif operation at level $\ell$ as

$$
o^{(\ell)}_m = \text{assemble}\Big( G_m^{(\ell)}, \mathcal{O}^{(\ell-1)} \Big)
$$

分层表示变为$\Big( \big\{ \{ G_m^{(\ell)} \}_{m=1}^{M_\ell} \big\}_{\ell=2}^L, \mathcal{O}^{(1)} \Big), \forall \ell=2, \dots, L$，其中$\mathcal{O}^{(1)}$包含一组基本操作。

> A hierarchical representation becomes $\Big( \big\{ \{ G_m^{(\ell)} \}_{m=1}^{M_\ell} \big\}_{\ell=2}^L, \mathcal{O}^{(1)} \Big), \forall \ell=2, \dots, L$, where $\mathcal{O}^{(1)}$ contains a set of primitive operations.

$\text{assemble}()$ 过程等效于按顺序计算节点 $i$ 的特征图，通过聚合其前驱节点 $j$ 的所有特征图，遵循拓扑排序：

> The $\text{assemble}()$ process is equivalent to sequentially compute the feature map of node $i$ by aggregating all the feature maps of its predecessor node $j$ following the topological ordering:

$$
x_i = \text{merge} \big[ \{ o^{(\ell)}_{G^{(\ell)}_{ij}}(x_j) \}_{j < i} \big], i = 2, \dots, \vert G^{(\ell)} \vert
$$

其中 $\text{merge}[]$ 在该[论文](https://arxiv.org/abs/1711.00436)中被实现为深度级联。

> where $\text{merge}[]$ is implemented as depth-wise concatenation in the [paper](https://arxiv.org/abs/1711.00436).

与 NASNet 相同，[Liu et al (2017)](https://arxiv.org/abs/1711.00436) 的实验侧重于在具有重复模块的预定义“宏”结构中发现良好的单元架构。他们表明，通过使用精心设计的搜索空间，可以显著增强简单搜索方法（例如随机搜索或进化算法）的效力。

> Same as NASNet, experiments in [Liu et al (2017)](https://arxiv.org/abs/1711.00436) focused on discovering good cell architecture within a predefined “macro” structure with repeated modules. They showed that the power of simple search methods (e.g. random search or evolutionary algorithms) can be substantially enhanced using well-designed search spaces.

[Cai et al (2018b)](https://arxiv.org/abs/1806.02639) 提出了一种使用路径级网络转换的树结构搜索空间。树结构中的每个节点都定义了一个用于为子节点拆分输入的*分配*方案，以及一个用于组合子节点结果的*合并*方案。如果其对应的合并方案是加法或连接，路径级网络转换允许用多分支主题替换单个层。

> [Cai et al (2018b)](https://arxiv.org/abs/1806.02639) propose a tree-structure search space using path-level network transformation. Each node in a tree structure defines an *allocation* scheme for splitting inputs for child nodes and a *merge* scheme for combining results from child nodes. The path-level network transformation allows replacing a single layer with a multi-branch motif if its corresponding merge scheme is add or concat.

![An illustration of transforming a single layer to a tree-structured motif via path-level transformation operations. (Image source: Cai et al. 2018b )](https://lilianweng.github.io/posts/2020-08-06-nas/path-level-network-transformations.png)

#### 记忆库表示

> Memory-bank Representation

前馈网络的内存库表示由[Brock et al. (2017)](https://arxiv.org/abs/1708.05344)在[SMASH](https://lilianweng.github.io/posts/2020-08-06-nas/#prediction-based)中提出。他们没有将神经网络视为操作图，而是将其视为一个具有多个可读写内存块的系统。每个层操作都旨在：(1) 从内存块的一个子集读取；(2) 计算结果；最后 (3) 将结果写入另一个内存块子集。例如，在顺序模型中，单个内存块会被持续读取和覆盖。

> A memory-bank representation of feed-forward networks is proposed by [Brock et al. (2017)](https://arxiv.org/abs/1708.05344) in [SMASH](https://lilianweng.github.io/posts/2020-08-06-nas/#prediction-based). Instead of a graph of operations, they view a neural network as a system with multiple memory blocks which can read and write. Each layer operation is designed to: (1) read from a subset of memory blocks; (2) computes results; finally (3) write the results into another subset of blocks. For example, in a sequential model, a single memory block would get read and overwritten consistently.

![Memory-bank representation of several popular network architecture blocks. (Image source: Brock et al. 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/NAS-memory-bank-view-representation.png)

### 搜索算法

> Search Algorithms

NAS 搜索算法对子网络群体进行采样。它接收子模型的性能指标作为奖励，并学习生成高性能的架构候选。你可能会发现它与超参数搜索领域有很多共同之处。

> NAS search algorithms sample a population of child networks. It receives the child models’ performance metrics as rewards and learns to generate high-performance architecture candidates. You may a lot in common with the field of hyperparameter search.

#### 随机搜索

> Random Search

随机搜索是最简单的基线。它从搜索空间中*随机*采样一个有效的架构候选，不涉及任何学习模型。随机搜索已被证明在超参数搜索中非常有用（[Bergstra & Bengio 2012](http://www.jmlr.org/papers/volume13/bergstra12a/bergstra12a.pdf)）。如果搜索空间设计得当，随机搜索可能是一个非常难以超越的基线。

> Random search is the most naive baseline. It samples a valid architecture candidate from the search space *at random* and no learning model is involved. Random search has proved to be quite useful in hyperparameter search ([Bergstra & Bengio 2012](http://www.jmlr.org/papers/volume13/bergstra12a/bergstra12a.pdf)). With a well-designed search space, random search could be a very challenging baseline to beat.

#### 强化学习

> Reinforcement Learning

最初的**NAS**设计（[Zoph & Le 2017](https://arxiv.org/abs/1611.01578)）涉及一个基于强化学习的控制器，用于提出子模型架构以进行评估。该控制器实现为一个RNN，输出用于配置网络架构的可变长度的token序列。

> The initial design of **NAS** ([Zoph & Le 2017](https://arxiv.org/abs/1611.01578)) involves a RL-based controller for proposing child model architectures for evaluation. The controller is implemented as a RNN, outputting a variable-length sequence of tokens used for configuring a network architecture.

![A high level overview of NAS, containing a RNN controller and a pipeline for evaluating child models. (Image source: Zoph & Le 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/NAS.png)

控制器被训练为一个*强化学习任务*，使用[REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce)。

> The controller is trained as a *RL task* using [REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce).

• **动作空间**：动作空间是控制器预测的用于定义子网络的令牌列表（详见上方[章节](https://lilianweng.github.io/posts/2020-08-06-nas/#sequential-layer-wise-operations)）。控制器输出*动作*，$a_{1:T}$，其中$T$是令牌的总数。

• **奖励**：子网络在收敛时可以达到的准确性是训练控制器的奖励，$R$。

• **损失**：NAS 使用 REINFORCE 损失优化控制器参数 $\theta$。我们希望通过以下梯度最大化预期奖励（高准确率）。策略梯度在这里的优点是，即使奖励不可微分，它也能奏效。

英文原文：

• **Action space**: The action space is a list of tokens for defining a child network predicted by the controller (See more in the above [section](https://lilianweng.github.io/posts/2020-08-06-nas/#sequential-layer-wise-operations)). The controller outputs *action*, $a_{1:T}$, where $T$ is the total number of tokens.

• **Reward**: The accuracy of a child network that can be achieved at convergence is the reward for training the controller, $R$.

• **Loss**: NAS optimizes the controller parameters $\theta$ with a REINFORCE loss. We want to maximize the expected reward (high accuracy) with the gradient as follows. The nice thing here with policy gradient is that it works even when the reward is non-differentiable.

$$
\nabla_{\theta} J(\theta) = \sum_{t=1}^T \mathbb{E}[\nabla_{\theta} \log P(a_t \vert a_{1:(t-1)}; \theta) R ]
$$

**MetaQNN** ([Baker et al. 2017](https://arxiv.org/abs/1611.02167)) 训练一个智能体，使用 [Q-learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control) 和 [\epsilon-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm) 探索策略以及经验回放来顺序选择 CNN 层。奖励也是验证准确率。

英文原文：MetaQNN ([Baker et al. 2017](https://arxiv.org/abs/1611.02167)) trains an agent to sequentially choose CNN layers using [Q-learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#q-learning-off-policy-td-control) with an [\epsilon-greedy](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#%CE%B5-greedy-algorithm) exploration strategy and experience replay. The reward is the validation accuracy as well.

$$
Q^{(t+1)}(s_t,  a_t) = (1 - \alpha)Q^{(t)}(s_t, a_t) + \alpha (R_t + \gamma \max_{a \in \mathcal{A}} Q^{(t)}(s_{t+1},  a'))
$$

其中状态 $s_t$ 是层操作和相关参数的元组。动作 $a$ 决定了操作之间的连接性。Q 值与我们对两个连接操作能带来高准确率的信心程度成正比。

> where a state $s_t$ is a tuple of layer operation and related parameters. An action $a$ determines the connectivity between operations. The Q-value is proportional to how confident we are in two connected operations leading to high accuracy.

![Overview of MetaQNN - designing CNN models with Q-Learning. (Image source: Baker et al. 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/MetaQNN.png)

#### 演化算法

> Evolutionary Algorithms

**NEAT**（*拓扑增强神经演化*的缩写）是一种利用 [遗传算法 (GA)](https://en.wikipedia.org/wiki/Genetic_algorithm) 演化神经网络拓扑的方法，由 [Stanley & Miikkulainen](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf) 于 2002 年提出。NEAT 同时演化连接权重和网络拓扑。每个基因编码配置网络的完整信息，包括节点权重和边。种群通过对权重和连接进行变异以及两个亲本基因之间的交叉来增长。有关神经演化的更多信息，请参阅 Stanley 等人 (2019) 的深度 [综述](https://www.nature.com/articles/s42256-018-0006-z)。

> **NEAT** (short for *NeuroEvolution of Augmenting Topologies*) is an approach for evolving neural network topologies with [genetic algorithm (GA)](https://en.wikipedia.org/wiki/Genetic_algorithm), proposed by [Stanley & Miikkulainen](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf) in 2002. NEAT evolves both connection weights and network topology together. Each gene encodes the full information for configuring a network, including node weights and edges. The population grows by applying mutation of both weights and connections, as well as crossover between two parent genes. For more in neuroevolution, please refer to the in-depth [survey](https://www.nature.com/articles/s42256-018-0006-z) by Stanley et al. (2019).

![Mutations in the NEAT algorithm. (Image source: Fig 3 & 4 in Stanley & Miikkulainen, 2002 )](https://lilianweng.github.io/posts/2020-08-06-nas/NEAT-mutations.png)

[Real 等人 (2018)](https://arxiv.org/abs/1802.01548) 采用进化算法（EA）来搜索高性能网络架构，命名为 **AmoebaNet**。他们应用了 [锦标赛选择](https://en.wikipedia.org/wiki/Tournament_selection) 方法，该方法在每次迭代中从一组随机样本中选出最佳候选者，并将其变异的后代放回种群中。当锦标赛规模为 $1$ 时，它等同于随机选择。

英文原文：[Real et al. (2018)](https://arxiv.org/abs/1802.01548) adopt the evolutionary algorithms (EA) as a way to search for high-performance network architectures, named AmoebaNet. They apply the [tournament selection](https://en.wikipedia.org/wiki/Tournament_selection) method, which at each iteration picks a best candidate out of a random set of samples and places its mutated offspring back into the population. When the tournament size is 

$1$, it is equivalent to random selection.

[https://lilianweng.github.io/posts/2020-08-06-nas/aging-evolutionary-algorithms](https://lilianweng.github.io/posts/2020-08-06-nas/aging-evolutionary-algorithms)AmoebaNet 修改了锦标赛选择，以偏爱 *更年轻的* 基因型，并始终在每个周期内淘汰最老的模型。这种方法，命名为 *老化演化*，使 AmoebaNet 能够覆盖和探索更多的搜索空间，而不是过早地局限于性能良好的模型。

> [https://lilianweng.github.io/posts/2020-08-06-nas/aging-evolutionary-algorithms](https://lilianweng.github.io/posts/2020-08-06-nas/aging-evolutionary-algorithms)AmoebaNet modified the tournament selection to favor *younger* genotypes and always discard the oldest models within each cycle. Such an approach, named *aging evolution*, allows AmoebaNet to cover and explore more search space, rather than to narrow down on good performance models too early.

具体来说，在每个带有老化正则化的锦标赛选择周期中（参见图 11）：

> Precisely, in every cycle of the tournament selection with aging regularization (See Figure 11):

1\. 从种群中抽取 $S$ 个模型，其中准确率最高的模型被选为 *父代*。

2\. 一个 *子代* 模型通过变异 *父代* 生成。

3\. 然后，子模型被训练、评估并重新添加到种群中。

4\. 最旧的模型从种群中移除。

英文原文：

1\. Sample $S$ models from the population and the one with highest accuracy is chosen as *parent*.

2\. A *child* model is produced by mutating *parent*.

3\. Then the child model is trained, evaluated and added back into the population.

4\. The oldest model is removed from the population.

![The algorithm of aging evolution. (Image source: Real et al. 2018 )](https://lilianweng.github.io/posts/2020-08-06-nas/aging-evolution-algorithm.png)

应用两种类型的突变：

> Two types of mutations are applied:

1. *隐藏状态突变*：随机选择一个成对组合，并重新连接一个随机末端，以确保图中没有循环。
2. *操作突变*：随机用一个随机操作替换现有操作。

> • *Hidden state mutation*: randomly chooses a pairwise combination and rewires a random end such that there is no loop in the graph.
> • *Operation mutation*: randomly replaces an existing operation with a random one.

![Two types of mutations in AmoebaNet. (Image source: Real et al. 2018 )](https://lilianweng.github.io/posts/2020-08-06-nas/AmoebaNet-mutations.png)

在他们的实验中，EA 和 RL 在最终验证准确性方面表现同样出色，但 EA 具有更好的随时性能，并且能够找到更小的模型。在这里，在 NAS 中使用 EA 在计算方面仍然昂贵，因为每个实验使用 450 个 GPU 耗时 7 天。

> In their experiments, EA and RL work equally well in terms of the final validation accuracy, but EA has better anytime performance and is able to find smaller models. Here using EA in NAS is still expensive in terms of computation, as each experiment took 7 days with 450 GPUs.

**HNAS** ([Liu et al 2017](https://arxiv.org/abs/1711.00436)) 也采用进化算法（原始的锦标赛选择）作为其搜索策略。在 [hierarchical structure](https://lilianweng.github.io/posts/2020-08-06-nas/#hierarchical-structure) 搜索空间中，每条边都是一个操作。因此，在他们的实验中，基因型突变是通过用不同的操作替换随机边来实现的。替换集包括一个 `none` 操作，因此它可以修改、删除和添加一条边。初始基因型集是通过对“琐碎”基序（所有恒等映射）应用大量随机突变来创建的。

> **HNAS** ([Liu et al 2017](https://arxiv.org/abs/1711.00436)) also employs the evolutionary algorithms (the original tournament selection) as their search strategy. In the [hierarchical structure](https://lilianweng.github.io/posts/2020-08-06-nas/#hierarchical-structure) search space, each edge is an operation. Thus genotype mutation in their experiments is applied by replacing a random edge with a different operation. The replacement set includes an `none` op, so it can alter, remove and add an edge. The initial set of genotypes is created by applying a large number of random mutations on “trivial” motifs (all identity mappings).

#### 渐进式决策过程

> Progressive Decision Process

构建模型架构是一个顺序过程。每个额外的操作符或层都会带来额外的复杂性。如果我们引导搜索模型从简单模型开始探索，并逐步演化到更复杂的架构，这就像在搜索模型的学习过程中引入了 [“curriculum”](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/)。

> Constructing a model architecture is a sequential process. Every additional operator or layer brings extra complexity. If we guide the search model to start the investigation from simple models and gradually evolve to more complex architectures, it is like to introduce [“curriculum”](https://lilianweng.github.io/posts/2020-01-29-curriculum-rl/) into the search model’s learning process.

*Progressive NAS* (**PNAS**; [Liu, et al 2018](https://arxiv.org/abs/1712.00559)) 将 NAS 问题构建为一个渐进式过程，用于搜索复杂度不断增加的模型。PNAS 没有采用 RL 或 EA，而是采用序列模型贝叶斯优化（SMBO）作为搜索策略。PNAS 的工作方式类似于 A* 搜索，它从简单到复杂地搜索模型，同时学习一个代理函数来指导搜索。

> *Progressive NAS* (**PNAS**; [Liu, et al 2018](https://arxiv.org/abs/1712.00559)) frames the problem of NAS as a progressive procedure for searching models of increasing complexity. Instead of RL or EA, PNAS adopts a Sequential Model-based Bayesian Optimization (SMBO) as the search strategy. PNAS works similar to A* search, as it searches for models from simple to hard while simultaneously learning a surrogate function to guide the search.

引用译文：

[A* search algorithm](https://en.wikipedia.org/wiki/A*_search_algorithm) （“best-first search”）是一种流行的路径查找算法。该问题被定义为在加权图中找到从特定起始节点到给定目标节点的最小成本路径。在每次迭代中，A* 通过最小化以下值来找到要扩展的路径：$f(n)=g(n)+h(n)$，其中 $n$ 是下一个节点，$g(n)$ 是从起点到 $n$ 的成本，并且 $h(n)$ 是启发式函数，它估计从节点 $n$ 到目标的最小成本。

英文原文：

[A* search algorithm](https://en.wikipedia.org/wiki/A*_search_algorithm) (“best-first search”) is a popular algorithm for path finding. The problem is framed as finding a path of smallest cost from a specific starting node to a given target node in a weighted graph. At each iteration, A* finds a path to extend by minimizing: $f(n)=g(n)+h(n)$, where $n$ is the next node, $g(n)$ is the cost from start to $n$, and $h(n)$ is the heuristic function that estimates the minimum cost of going from node $n$ to the goal.

PNAS 使用 [NASNet](https://lilianweng.github.io/posts/2020-08-06-nas/#cell-based-representation) 搜索空间。每个块被指定为一个 5 元素元组，PNAS 只考虑逐元素相加作为第 5 步组合操作符，不进行拼接。不同的是，PNAS 没有将块的数量 $B$ 设置为固定值，而是从 $B=1$（一个单元格中只有一个块的模型）开始，并逐渐增加 $B$。

> PNAS uses the [NASNet](https://lilianweng.github.io/posts/2020-08-06-nas/#cell-based-representation) search space. Each block is specified as a 5-element tuple and PNAS only considers the element-wise addition as the step 5 combination operator, no concatenation. Differently, instead of setting the number of blocks $B$ at a fixed number, PNAS starts with $B=1$, a model with only one block in a cell, and gradually increases $B$.

验证集上的性能被用作反馈，以训练一个 *代理* 模型，用于 *预测* 新架构的性能。有了这个预测器，我们就可以决定哪些模型应该优先进行评估。由于性能预测器应该能够处理各种大小的输入、具有准确性并具有样本效率，他们最终使用了 RNN 模型。

> The performance on a validation set is used as feedback to train a *surrogate* model for *predicting* the performance of novel architectures. With this predictor, we can thus decide which models should be prioritized to be evaluated next. Since the performance predictor should be able to handle various-sized inputs, accuracy, and sample-efficient, they ended up using an RNN model.

![The algorithm of Progressive NAS. (Image source: Liu, et al 2018 )](https://lilianweng.github.io/posts/2020-08-06-nas/progressive-NAS-algorithm.png)

#### 梯度下降

> Gradient descent

使用梯度下降来更新架构搜索模型需要努力使选择离散操作的过程可微分。这些方法通常将架构参数和网络权重的学习结合到一个模型中。更多内容请参见 [section](https://lilianweng.github.io/posts/2020-08-06-nas/#one-shot-approach-search--evaluation) 关于 *“one-shot”* 方法。

> Using gradient descent to update the architecture search model requires an effort to make the process of choosing discrete operations differentiable. These approaches usually combine the learning of both architecture parameters and network weights together into one model. See more in the [section](https://lilianweng.github.io/posts/2020-08-06-nas/#one-shot-approach-search--evaluation) on the *“one-shot”* approach.

### 评估策略

> Evaluation Strategy

我们需要测量、估计或预测每个子模型的性能，以便为优化搜索算法获取反馈。候选模型评估过程可能非常昂贵，许多新的评估方法已被提出以节省时间或计算。在评估子模型时，我们主要关注其在验证集上测量的准确性性能。最近的工作已开始研究模型的其他因素，例如模型大小和延迟，因为某些设备可能存在内存限制或要求快速响应时间。

> We need to measure, estimate or predict the performance of every child model in order to obtain feedback for optimizing the search algorithm. The process of candidate evaluation could be very expensive and many new evaluation methods have been proposed to save time or computation. When evaluating a child model, we mostly care about its performance measured as accuracy on a validation set. Recent work has started looking into other factors of a model, such as model size and latency, as certain devices may have limitations on memory or demand fast response time.

#### 从头开始训练

> Training from Scratch

最朴素的方法是独立地从头开始训练每个子网络，直到 *收敛*，然后测量其在验证集上的准确性 ([Zoph & Le 2017](https://arxiv.org/abs/1611.01578))。它提供了可靠的性能数据，但一个完整的训练-收敛-评估循环只为训练 RL 控制器生成一个数据样本（更不用说 RL 通常是样本效率低下的）。因此，它在计算消耗方面非常昂贵。

> The most naive approach is to train every child network independently from scratch until *convergence* and then measure its accuracy on a validation set ([Zoph & Le 2017](https://arxiv.org/abs/1611.01578)). It provides solid performance numbers, but one complete train-converge-evaluate loop only generates a single data sample for training the RL controller (let alone RL is known to be sample-inefficient in general). Thus it is very expensive in terms of computation consumption.

#### 代理任务性能

> Proxy Task Performance

有几种方法可以使用代理任务性能作为子网络的性能估计器，这些方法通常更便宜、计算速度更快：

> There are several approaches for using a proxy task performance as the performance estimator of a child network, which is generally cheaper and faster to calculate:

• 在较小的数据集上训练。

• 训练更少的 epoch。

• 在搜索阶段训练和评估一个缩小规模的模型。例如，一旦学习了单元格结构，我们就可以调整单元格重复次数或增加滤波器数量 ([Zoph et al. 2018](https://arxiv.org/abs/1707.07012))。

• 预测学习曲线。[Baker et al (2018)](https://arxiv.org/abs/1705.10823) 将验证准确率的预测建模为一个时间序列回归问题。回归模型的特征（$\nu$ -支持向量机回归；$\nu$ -SVR）包括每个 epoch 的早期准确率序列、架构参数和超参数。

英文原文：

• Train on a smaller dataset.

• Train for fewer epochs.

• Train and evaluate a down-scaled model in the search stage. For example, once a cell structure is learned, we can play with the number of cell repeats or scale up the number of filters ([Zoph et al. 2018](https://arxiv.org/abs/1707.07012)).

• Predict the learning curve. [Baker et al (2018)](https://arxiv.org/abs/1705.10823) model the prediction of validation accuracies as a time-series regression problem. The features for the regression model ($\nu$ -support vector machine regressions; $\nu$ -SVR) include the early sequences of accuracy per epoch, architecture parameters, and hyperparameters.

#### 参数共享

> Parameter Sharing

不是从头开始独立训练每个子模型。你可能会问，如果我们制造它们之间的依赖关系并找到一种重用权重的方法呢？一些研究人员成功地使这些方法奏效。

> Instead of training every child model independently from scratch. You may ask, ok, what if we fabricate dependency between them and find a way to reuse weights? Some researchers succeeded to make such approaches work.

受 [Net2net](https://arxiv.org/abs/1511.05641) 转换的启发，[Cai et al (2017)](https://arxiv.org/abs/1707.04873) 提出了 *高效架构搜索* (**EAS**)。EAS 建立了一个 RL 代理，称为元控制器，用于预测保持功能的网络转换，以增加网络深度或层宽度。由于网络是增量增长的，因此先前验证过的网络的权重可以被 *重用* 用于进一步探索。通过继承权重，新构建的网络只需要进行一些轻量级训练。

> Inspired by [Net2net](https://arxiv.org/abs/1511.05641) transformation, [Cai et al (2017)](https://arxiv.org/abs/1707.04873) proposed *Efficient Architecture Search* (**EAS**). EAS sets up an RL agent, known as a meta-controller, to predict function-preserving network transformation so as to grow the network depth or layer width. Because the network is growing incrementally, the weights of previously validated networks can be *reused* for further exploration. With inherited weights, newly constructed networks only need some light-weighted training.

一个元控制器学习生成*网络转换动作*，给定当前网络架构，该架构由一个可变长度字符串指定。为了处理可变长度的架构配置，元控制器被实现为一个双向循环网络。多个执行器网络输出不同的转换决策：

> A meta-controller learns to generate *network transformation actions* given the current network architecture, which is specified with a variable-length string. In order to handle architecture configuration of a variable length, the meta-controller is implemented as a bi-directional recurrent network. Multiple actor networks output different transformation decisions:

1. *Net2WiderNet*操作允许用更宽的层替换一个层，这意味着全连接层有更多的单元，或卷积层有更多的滤波器，同时保留功能。
2. *Net2DeeperNet*操作允许插入一个新层，该层被初始化为在两层之间添加一个恒等映射，以保留功能。

> • *Net2WiderNet* operation allows to replace a layer with a wider layer, meaning more units for fully-connected layers, or more filters for convolutional layers, while preserving the functionality.
> • *Net2DeeperNet* operation allows to insert a new layer that is initialized as adding an identity mapping between two layers so as to preserve the functionality.

![Overview of the RL based meta-controller in Efficient Architecture Search (NAS). After encoding the architecture configuration, it outputs net2net transformation actions through two separate actor networks. (Image source: Cai et al 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/EAS-meta-controller.png)

出于类似的动机，*Efficient NAS* (**ENAS**; [Pham et al. 2018](https://arxiv.org/abs/1802.03268)) 通过在子模型之间积极共享参数，加速了NAS（即减少1000倍）。ENAS背后的核心动机是观察到所有采样的架构图都可以被视为*子图*，是一个更大的*超图*的。所有子网络都共享这个超图的权重。

> With similar motivation, *Efficient NAS* (**ENAS**; [Pham et al. 2018](https://arxiv.org/abs/1802.03268)) speeds up NAS (i.e. 1000x less) by aggressively sharing parameters among child models. The core motivation behind ENAS is the observation that all of the sampled architecture graphs can be viewed as *sub-graphs* of a larger *supergraph*. All the child networks are sharing weights of this supergraph.

![(Left) The graph represents the entire search space for a 4-node recurrent cell, but only connections in red are active. (Middle) An example of how the left active sub-graph can be translated into a child model architecture. (Right) The network parameters produced by an RNN controller for the architecture in the middle. (Image source: Pham et al. 2018 )](https://lilianweng.github.io/posts/2020-08-06-nas/ENAS-example.png)

ENAS 在训练共享模型权重 $\omega$ 和训练控制器 $\theta$ 之间交替进行：

> ENAS alternates between training the shared model weights $\omega$ and training the controller $\theta$:

1\. 控制器 LSTM $\theta$ 的参数使用 [REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce) 进行训练，其中奖励 $R(\mathbf{m}, \omega)$ 在验证集上计算。

2\. 子模型 $\omega$ 的共享参数使用标准监督学习损失进行训练。请注意，超图中与同一节点关联的不同运算符将拥有各自独立的参数。

英文原文：

1\. The parameters of the controller LSTM $\theta$ are trained with [REINFORCE](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#reinforce), where the reward $R(\mathbf{m}, \omega)$ is computed on the validation set.

2\. The shared parameters of the child models $\omega$ are trained with standard supervised learning loss. Note that different operators associated with the same node in the supergraph would have their own distinct parameters.

#### 基于预测

> Prediction-Based

一个常规的子模型评估循环是通过标准梯度下降更新模型权重。SMASH ([Brock et al. 2017](https://arxiv.org/abs/1708.05344)) 提出了一个不同且有趣的想法：*我们能否根据网络架构参数直接预测模型权重？*

> A routine child model evaluation loop is to update model weights via standard gradient descent. SMASH ([Brock et al. 2017](https://arxiv.org/abs/1708.05344)) proposes a different and interesting idea: *Can we predict the model weights directly based on the network architecture parameters?*

他们使用一个[HyperNet](https://blog.otoro.net/2016/09/28/hyper-networks/)（[Ha 等人 2016](https://arxiv.org/abs/1609.09106)）来直接生成模型的权重，该权重以其架构配置的编码为条件。然后直接验证具有HyperNet生成权重的模型。请注意，我们不需要为每个子模型进行额外的训练，但我们需要训练HyperNet。

> They employ a [HyperNet](https://blog.otoro.net/2016/09/28/hyper-networks/) ([Ha et al 2016](https://arxiv.org/abs/1609.09106)) to directly generate the weights of a model conditioned on an encoding of its architecture configuration. Then the model with HyperNet-generated weights is validated directly. Note that we don’t need extra training for every child model but we do need to train the HyperNet.

![The algorithm of SMASH. (Image source: Brock et al. 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/SMASH-algorithm.png)

使用SMASH生成的权重与真实验证误差之间的模型性能相关性表明，预测权重可以在一定程度上用于模型比较。我们确实需要一个足够大容量的HyperNet，因为如果HyperNet模型相对于子模型大小来说太小，相关性就会被破坏。

> The correlation between model performance with SMASH-generated weights and true validation errors suggests that predicted weights can be used for model comparison, to some extent. We do need a HyperNet of large enough capacity, as the correlation would be corrupted if the HyperNet model is too small compared to the child model size.

![The algorithm of SMASH. (Image source: Brock et al. 2017 )](https://lilianweng.github.io/posts/2020-08-06-nas/SMASH-error-correlation.png)

SMASH可以被视为实现[参数共享](https://lilianweng.github.io/posts/2020-08-06-nas/#parameter-sharing)思想的另一种方式。正如[Pham 等人 (2018)](https://arxiv.org/abs/1802.03268)所指出的，SMASH的一个问题是：HyperNet的使用将SMASH子模型的权重限制在*低秩空间*中，因为权重是通过张量积生成的。相比之下，[ENAS](https://lilianweng.github.io/posts/2020-08-06-nas/#ENAS)没有这样的限制。

> SMASH can be viewed as another way to implement the idea of [parameter sharing](https://lilianweng.github.io/posts/2020-08-06-nas/#parameter-sharing). One problem of SMASH as pointed out by [Pham et al. (2018)](https://arxiv.org/abs/1802.03268) is: The usage of HyperNet restricts the weights of SMASH child models to a *low-rank space*, because weights are generated via tensor products. In comparison, [ENAS](https://lilianweng.github.io/posts/2020-08-06-nas/#ENAS) has no such restrictions.

### 一次性方法：搜索 + 评估

> One-Shot Approach: Search + Evaluation

为大量子模型独立运行搜索和评估是昂贵的。我们已经看到了有前景的方法，例如[Brock 等人 (2017)](https://arxiv.org/abs/1708.05344)或[Pham 等人 (2018)](https://arxiv.org/abs/1802.03268)，其中训练一个单一模型足以模拟搜索空间中的任何子模型。

> Running search & evaluation independently for a large population of child models is expensive. We have seen promising approaches like [Brock et al. (2017)](https://arxiv.org/abs/1708.05344) or [Pham et al. (2018)](https://arxiv.org/abs/1802.03268), where training a single model is enough for emulating any child model in the search space.

**一次性**架构搜索扩展了权重共享的思想，并进一步将架构生成学习与权重参数结合起来。以下方法都将子架构视为超图的不同子图，超图中公共边之间共享权重。

> The **one-shot** architecture search extends the idea of weight sharing and further combines the learning of architecture generation together with weight parameters. The following approaches all treat child architectures as different sub-graphs of a supergraph with shared weights between common edges in the supergraph.

[Bender 等人 (2018)](http://proceedings.mlr.press/v80/bender18a/bender18a.pdf)构建了一个单一的、大型的过参数化网络，称为**一次性模型**，使其包含搜索空间中的所有可能操作。通过[ScheduledDropPath](https://lilianweng.github.io/posts/2020-08-06-nas/#ScheduledDropPath)（dropout率随时间增加，在训练结束时为$r^{1/k}$，其中$0 < r < 1$是一个超参数，`k`是传入路径的数量）和一些精心设计的技巧（例如，ghost批归一化，仅对活动架构进行L2正则化），这种巨型模型的训练可以足够稳定，并用于评估从超图采样的任何子模型。

英文原文：[Bender et al (2018)](http://proceedings.mlr.press/v80/bender18a/bender18a.pdf) construct a single large over-parameterized network, known as the One-Shot model, such that it contains every possible operation in the search space. With [ScheduledDropPath](https://lilianweng.github.io/posts/2020-08-06-nas/#ScheduledDropPath) (the dropout rate is increased over time, which is 

$r^{1/k}$ at the end of training, where 

$0 < r < 1$ is a hyperparam and `k` is the number of incoming paths) and some carefully designed tricks (e.g. ghost batch normalization, L2 regularization only on the active architecture), the training of such a giant model can be stabilized enough and used for evaluating any child model sampled from the supergraph.

![The architecture of the One-Shot model in Bender et al 2018 . Each cell has $N$ choice blocks and each choice block can select up to 2 operations. Solid edges are used in every architecture, where dash lines are optional. (Image source: Bender et al 2018 )](https://lilianweng.github.io/posts/2020-08-06-nas/one-shot-model-architecture.png)

一旦一次性模型训练完成，它就被用于通过归零或移除某些操作来评估随机采样的许多不同架构的性能。这个采样过程可以被强化学习（RL）或演化算法取代。

> Once the one-shot model is trained, it is used for evaluating the performance of many different architectures sampled at random by zeroing out or removing some operations. This sampling process can be replaced by RL or evolution.

他们观察到，使用一次性模型测量的准确性与相同架构经过少量微调后的准确性之间的差异可能非常大。他们的假设是，一次性模型会自动学习关注网络中*最有用*的操作，并在这些操作可用时*依赖*它们。因此，归零有用的操作会导致模型准确性大幅下降，而移除不那么重要的组件只会造成很小的影响——因此，在使用一次性模型进行评估时，我们看到分数有更大的方差。

> They observed that the difference between the accuracy measured with the one-shot model and the accuracy of the same architecture after a small fine-tuning could be very large. Their hypothesis is that the one-shot model automatically learns to focus on the *most useful* operations in the network and comes to *rely on* these operations when they are available. Thus zeroing out useful operations lead to big reduction in model accuracy, while removing less important components only causes a small impact — Therefore, we see a larger variance in scores when using the one-shot model for evaluation.

![A stratified sample of models with different one-shot model accuracy versus their true validation accuracy as stand-alone models. (Image source: Bender et al 2018 )](https://lilianweng.github.io/posts/2020-08-06-nas/one-shot-model-accuracy-correlation.png)

显然，设计这样一个搜索图并非易事，但它展示了one-shot方法强大的潜力。它仅通过梯度下降就能很好地工作，无需额外的算法，如RL或EA。

> Clearly designing such a search graph is not a trivial task, but it demonstrates a strong potential with the one-shot approach. It works well with only gradient descent and no additional algorithm like RL or EA is a must.

一些人认为，NAS效率低下的一个主要原因是将架构搜索视为*黑盒优化*，因此我们采用了RL、进化、SMBO等方法。如果我们转而依赖标准梯度下降，我们可能会使搜索过程更有效。因此，[Liu et al (2019)](https://arxiv.org/abs/1806.09055)提出了*可微分架构搜索*（**DARTS**）。DARTS在搜索超图中的每条路径上引入了连续松弛，使得通过梯度下降联合训练架构参数和权重成为可能。

> Some believe that one main cause for inefficiency in NAS is to treat the architecture search as a *black-box optimization* and thus we fall into methods like RL, evolution, SMBO, etc. If we shift to rely on standard gradient descent, we could potentially make the search process more effectively. As a result, [Liu et al (2019)](https://arxiv.org/abs/1806.09055) propose *Differentiable Architecture Search* (**DARTS**). DARTS introduces a continuous relaxation on each path in the search supergraph, making it possible to jointly train architecture parameters and weights via gradient descent.

这里我们使用有向无环图（DAG）表示。一个单元是一个DAG，由拓扑有序的$N$个节点序列组成。每个节点都有一个待学习的潜在表示$x_i$。每条边$(i, j)$都与某个操作$o^{(i,j)} \in \mathcal{O}$相关联，该操作将$x_j$转换为构成$x_i$：

> Let’s use the directed acyclic graph (DAG) representation here. A cell is a DAG consisting of a topologically ordered sequence of $N$ nodes. Each node has a latent representation $x_i$ to be learned. Each edge $(i, j)$ is tied to some operation $o^{(i,j)} \in \mathcal{O}$ that transforms $x_j$ to compose $x_i$:

$$
x_i = \sum_{j < i} o^{(i,j)}(x_j)
$$

为了使搜索空间连续，DARTS将特定操作的分类选择松弛为所有操作上的softmax，架构搜索的任务被简化为学习一组混合概率$\alpha = \{ \alpha^{(i,j)} \}$。

> To make the search space continuous, DARTS relaxes the categorical choice of a particular operation as a softmax over all the operations and the task of architecture search is reduced to learn a set of mixing probabilities $\alpha = \{ \alpha^{(i,j)} \}$.

$$
\bar{o}^{(i,j)}(x) = \sum_{o\in\mathcal{O}} \frac{\exp(\alpha_{ij}^o)}{\sum_{o'\in\mathcal{O}} \exp(\alpha^{o'}_{ij})} o(x)
$$

其中 $\alpha_{ij}$ 是一个维度为 $\vert \mathcal{O} \vert$ 的向量，包含节点 $i$ 和 $j$ 之间在不同操作上的权重。

> where $\alpha_{ij}$ is a vector of dimension $\vert \mathcal{O} \vert$, containing weights between nodes $i$ and $j$ over different operations.

存在双层优化是因为我们希望同时优化网络权重 $w$ 和架构表示 $\alpha$：

> The bilevel optimization exists as we want to optimize both the network weights $w$ and the architecture representation $\alpha$:

$$
\begin{aligned}
\min_\alpha & \mathcal{L}_\text{validate} (w^*(\alpha), \alpha) \\
\text{s.t.} & w^*(\alpha) = \arg\min_w \mathcal{L}_\text{train} (w, \alpha)
\end{aligned}
$$

在步骤$k$，给定当前架构参数$\alpha_{k−1}$，我们首先优化权重$w_k$，通过移动$w_{k−1}$，朝着最小化训练损失的方向$\mathcal{L}_\text{train}(w_{k−1}, \alpha_{k−1})$，以学习率$\xi$。接下来，在保持新更新的权重$w_k$不变的情况下，我们更新混合概率，以最小化验证损失*在对权重进行单步梯度下降之后*：

> At step $k$, given the current architecture parameters $\alpha_{k−1}$, we first optimize weights $w_k$ by moving $w_{k−1}$ in the direction of minimizing the training loss $\mathcal{L}_\text{train}(w_{k−1}, \alpha_{k−1})$ with a learning rate $\xi$. Next, while keeping the newly updated weights $w_k$ fixed, we update the mixing probabilities so as to minimize the validation loss *after a single step of gradient descent w.r.t. the weights*:

$$
J_\alpha = \mathcal{L}_\text{val}(w_k - \xi \nabla_w \mathcal{L}_\text{train}(w_k, \alpha_{k-1}), \alpha_{k-1})
$$

这里的动机是，我们希望找到一种架构，当其权重通过梯度下降优化时，具有较低的验证损失，并且一步展开的权重作为*替代*，用于$w^∗(\alpha)$。

> The motivation here is that we want to find an architecture with a low validation loss when its weights are optimized by gradient descent and the one-step unrolled weights serve as the *surrogate* for $w^∗(\alpha)$.

> 旁注：之前我们曾在[MAML](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#maml)中看到过类似的表述，其中任务损失和元学习器更新之间发生了两步优化，并且将[域随机化](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#dr-as-optimization)框定为一种双层优化，以在真实环境中实现更好的迁移。

> Side note: Earlier we have seen similar formulation in [MAML](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#maml) where the two-step optimization happens between task losses and the meta-learner update, as well as framing [Domain Randomization](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#dr-as-optimization) as a bilevel optimization for better transfer in the real environment.

![An illustration of how DARTS applies continuous relaxation on edges in DAG supergraph and identifies the final model. (Image source: Liu et al 2019 )](https://lilianweng.github.io/posts/2020-08-06-nas/DARTS-illustration.png)

$$
\begin{aligned}
\text{Let }w'_k &= w_k - \xi \nabla_w \mathcal{L}_\text{train}(w_k, \alpha_{k-1}) & \\
J_\alpha &= \mathcal{L}_\text{val}(w_k - \xi \nabla_w \mathcal{L}_\text{train}(w_k, \alpha_{k-1}), \alpha_{k-1}) = \mathcal{L}_\text{val}(w'_k, \alpha_{k-1}) & \\
\nabla_\alpha J_\alpha 
&= \nabla_{\alpha_{k-1}} \mathcal{L}_\text{val}(w'_k, \alpha_{k-1}) \nabla_\alpha \alpha_{k-1} + \nabla_{w'_k} \mathcal{L}_\text{val}(w'_k, \alpha_{k-1})\nabla_\alpha w'_k & \\& \text{; multivariable chain rule}\\
&= \nabla_{\alpha_{k-1}} \mathcal{L}_\text{val}(w'_k, \alpha_{k-1}) + \nabla_{w'_k} \mathcal{L}_\text{val}(w'_k, \alpha_{k-1}) \big( - \xi \color{red}{\nabla^2_{\alpha, w} \mathcal{L}_\text{train}(w_k, \alpha_{k-1})} \big) & \\
&\approx \nabla_{\alpha_{k-1}} \mathcal{L}_\text{val}(w'_k, \alpha_{k-1}) - \xi \nabla_{w'_k} \mathcal{L}_\text{val}(w'_k, \alpha_{k-1}) \color{red}{\frac{\nabla_\alpha \mathcal{L}_\text{train}(w_k^+, \alpha_{k-1}) - \nabla_\alpha \mathcal{L}_\text{train}(w_k^-, \alpha_{k-1}) }{2\epsilon}} & \\
& \text{; apply numerical differentiation approximation}
\end{aligned}
$$

其中红色部分使用了数值微分近似，其中 $w_k^+ = w_k + \epsilon \nabla_{w’_k} \mathcal{L}_\text{val}(w’_k, \alpha_{k-1})$ 和 $w_k^- = w_k - \epsilon \nabla_{w’_k} \mathcal{L}_\text{val}(w’_k, \alpha_{k-1})$。

> where the red part is using numerical differentiation approximation where $w_k^+ = w_k + \epsilon \nabla_{w’_k} \mathcal{L}_\text{val}(w’_k, \alpha_{k-1})$ and $w_k^- = w_k - \epsilon \nabla_{w’_k} \mathcal{L}_\text{val}(w’_k, \alpha_{k-1})$.

![The algorithm overview of DARTS. (Image source: Liu et al 2019 )](https://lilianweng.github.io/posts/2020-08-06-nas/DARTS-algorithm.png)

作为与 DARTS 相似的另一个想法，Stochastic NAS ([Xie et al., 2019](https://arxiv.org/abs/1812.09926)) 通过采用具体分布（CONCRETE = 离散随机变量的连续松弛；[Maddison et al 2017](https://arxiv.org/abs/1611.00712)）和重参数化技巧来应用连续松弛。其目标与 DARTS 相同，即使离散分布可微分，从而通过梯度下降实现优化。

> As another idea similar to DARTS, Stochastic NAS ([Xie et al., 2019](https://arxiv.org/abs/1812.09926)) applies a continuous relaxation by employing the concrete distribution (CONCRETE = CONtinuous relaxations of disCRETE random variables; [Maddison et al 2017](https://arxiv.org/abs/1611.00712)) and reparametrization tricks. The goal is same as DARTS, to make the discrete distribution differentiable and thus enable optimization by gradient descent.

DARTS 能够大大降低 GPU 小时成本。他们搜索 CNN 单元的实验具有 $N=7$，并且仅用单个 GPU 花费了 1.5 天。然而，由于其网络架构的连续表示，它面临着高 GPU 内存消耗问题。为了将模型适配到单个 GPU 的内存中，他们选择了一个小的 $N$。

> DARTS is able to greatly reduce the cost of GPU hours. Their experiments for searching for CNN cells have $N=7$ and only took 1.5 days with a single GPU. However, it suffers from the high GPU memory consumption issue due to its continuous representation of network architecture. In order to fit the model into the memory of a single GPU, they picked a small $N$.

为了限制 GPU 内存消耗，**ProxylessNAS** ([Cai et al., 2019](https://arxiv.org/abs/1812.00332)) 将 NAS 视为 DAG 中的路径级剪枝过程，并对架构参数进行二值化，以强制在任意两个节点之间一次只有一个路径处于活动状态。然后，通过采样一些二值化架构并使用 *BinaryConnect* ([Courbariaux et al., 2015](https://arxiv.org/abs/1511.00363)) 更新相应的概率，来学习边被遮蔽或不被遮蔽的概率。ProxylessNAS 展示了 NAS 与模型压缩之间的紧密联系。通过使用路径级压缩，它能够将内存消耗节省一个数量级。

> To constrain the GPU memory consumption, **ProxylessNAS** ([Cai et al., 2019](https://arxiv.org/abs/1812.00332)) views NAS as a path-level pruning process in DAG and binarizes the architecture parameters to force only one path to be active between two nodes at a time. The probabilities for an edge being either masked out or not are then learned by sampling a few binarized architectures and using *BinaryConnect* ([Courbariaux et al., 2015](https://arxiv.org/abs/1511.00363)) to update the corresponding probabilities. ProxylessNAS demonstrates a strong connection between NAS and model compression. By using path-level compression, it is able to save memory consumption by one order of magnitude.

我们继续图表示。在 DAG 邻接矩阵 $G$ 中，$G_{ij}$ 表示节点 $i$ 和 $j$ 之间的一条边，其值可以从 $\vert \mathcal{O} \vert$ 个候选原始操作的集合中选择，$\mathcal{O} = \{ o_1, \dots \}$。One-Shot 模型、DARTS 和 ProxylessNAS 都将每条边视为操作的混合，$m_\mathcal{O}$，但各有不同的调整。

> Let’s continue with the graph representation. In a DAG adjacency matrix $G$ where $G_{ij}$ represents an edge between node $i$ and $j$ and its value can be chosen from the set of $\vert \mathcal{O} \vert$ candidate primitive operations, $\mathcal{O} = \{ o_1, \dots \}$. The One-Shot model, DARTS and ProxylessNAS all consider each edge as a mixture of operations, $m_\mathcal{O}$, but with different tweaks.

在 One-Shot 中，$m_\mathcal{O}(x)$是所有操作的总和。在 DARTS 中，它是一个加权和，其中权重是实值架构权重向量的 softmax$\alpha$，其长度为$\vert \mathcal{O} \vert$。ProxylessNAS 将 softmax 概率$\alpha$转换为二元门，并使用该二元门一次只激活一个操作。

> In One-Shot, $m_\mathcal{O}(x)$ is the sum of all the operations. In DARTS, it is a weighted sum where weights are softmax over a real-valued architecture weighting vector $\alpha$ of length $\vert \mathcal{O} \vert$. ProxylessNAS transforms the softmax probabilities of $\alpha$ into a binary gate and uses the binary gate to keep only one operation active at a time.

$$
\begin{aligned}
m^\text{one-shot}_\mathcal{O}(x) &= \sum_{i=1}^{\vert \mathcal{O} \vert} o_i(x) \\
m^\text{DARTS}_\mathcal{O}(x) &= \sum_{i=1}^{\vert \mathcal{O} \vert} p_i o_i(x) = \sum_{i=1}^{\vert \mathcal{O} \vert} \frac{\exp(\alpha_i)}{\sum_j \exp(\alpha_j)} o_i(x) \\
m^\text{binary}_\mathcal{O}(x) &= \sum_{i=1}^{\vert \mathcal{O} \vert} g_i o_i(x) = \begin{cases}
o_1(x) & \text{with probability }p_1, \\
\dots &\\
o_{\vert \mathcal{O} \vert}(x) & \text{with probability }p_{\vert \mathcal{O} \vert}
\end{cases} \\
\text{ where } g &= \text{binarize}(p_1, \dots, p_N) = \begin{cases}
[1, 0, \dots, 0] & \text{with probability }p_1, \\
\dots & \\
[0, 0, \dots, 1] & \text{with probability }p_N. \\
\end{cases}
\end{aligned}
$$

![ProxylessNAS has two training steps running alternatively. (Image source: Cai et al., 2019 )](https://lilianweng.github.io/posts/2020-08-06-nas/proxylessNAS-training.png)

ProxylessNAS 交替运行两个训练步骤：

> ProxylessNAS runs two training steps alternatively:

1\. 在训练权重参数时$w$，它会冻结架构参数$\alpha$并随机采样二值门$g$，根据上述$m^\text{binary}_\mathcal{O}(x)$。权重参数可以通过标准梯度下降进行更新。

2\. 当训练架构参数 $\alpha$ 时，它会冻结 $w$，重置二值门，然后在验证集上更新 $\alpha$。遵循 *BinaryConnect* 的思想，相对于架构参数的梯度可以使用 $\partial \mathcal{L} / \partial g_i$ 近似估计，以替代 $\partial \mathcal{L} / \partial p_i$：

英文原文：

1\. When training weight parameters $w$, it freezes the architecture parameters $\alpha$ and stochastically samples binary gates $g$ according to the above $m^\text{binary}_\mathcal{O}(x)$. The weight parameters can be updated with standard gradient descent.

2\. When training architecture parameters $\alpha$, it freezes $w$, resets the binary gates and then updates $\alpha$ on the validation set. Following the idea of *BinaryConnect*,  the gradient w.r.t. architecture parameters can be approximately estimated using $\partial \mathcal{L} / \partial g_i$ in replacement for $\partial \mathcal{L} / \partial p_i$:

$$
\begin{aligned}
\frac{\partial \mathcal{L}}{\partial \alpha_i} 
&= \sum_{j=1}^{\vert \mathcal{O} \vert} \frac{\partial \mathcal{L}}{\partial p_j} \frac{\partial p_j}{\partial \alpha_i} 
\approx \sum_{j=1}^{\vert \mathcal{O} \vert} \frac{\partial \mathcal{L}}{\partial g_j} \frac{\partial p_j}{\partial \alpha_i} 
= \sum_{j=1}^{\vert \mathcal{O} \vert} \frac{\partial \mathcal{L}}{\partial g_j} \frac{\partial \frac{e^{\alpha_j}}{\sum_k e^{\alpha_k}}}{\partial \alpha_i} \\
&= \sum_{j=1}^{\vert \mathcal{O} \vert} \frac{\partial \mathcal{L}}{\partial g_j} \frac{\sum_k e^{\alpha_k} (\mathbf{1}_{i=j} e^{\alpha_j}) - e^{\alpha_j} e^{\alpha_i} }{(\sum_k e^{\alpha_k})^2}
= \sum_{j=1}^{\vert \mathcal{O} \vert} \frac{\partial \mathcal{L}}{\partial g_j} p_j (\mathbf{1}_{i=j} -p_i)
\end{aligned}
$$

除了BinaryConnect，REINFORCE也可以用于参数更新，目标是最大化奖励，同时不涉及RNN元控制器。

> Instead of BinaryConnect, REINFORCE can also be used for parameter updates with the goal for maximizing the reward, while no RNN meta-controller is involved.

计算$\partial \mathcal{L} / \partial g_i$需要计算并存储$o_i(x)$，这需要$\vert \mathcal{O} \vert$倍的GPU内存。为了解决这个问题，他们将从$N$中选择一条路径的任务分解为多个二元选择任务（直觉是：“如果一条路径是最佳选择，它应该比任何其他路径都好”）。在每个更新步骤中，只采样两条路径，而其他路径被遮蔽。这两条选定的路径根据上述方程进行更新，然后进行适当缩放，以使其他路径权重保持不变。在此过程之后，其中一条采样路径得到增强（路径权重增加），另一条被衰减（路径权重减少），而所有其他路径保持不变。

> Computing $\partial \mathcal{L} / \partial g_i$ needs to calculate and store $o_i(x)$, which requires $\vert \mathcal{O} \vert$ times GPU memory. To resolve this issue, they factorize the task of choosing one path out of $N$ into multiple binary selection tasks (Intuition: “if a path is the best choice, it should be better than any other path”). At every update step, only two paths are sampled while others are masked. These two selected paths are updated according to the above equation and then scaled properly so that other path weights are unchanged. After this process, one of the sampled paths is enhanced (path weight increases) and the other is attenuated (path weight decreases), while all other paths stay unaltered.

除了准确性，ProxylessNAS还将*延迟*视为一个重要的优化指标，因为不同的设备可能对推理时间延迟有非常不同的要求（例如GPU、CPU、移动设备）。为了使延迟可微分，他们将延迟建模为网络维度的连续函数。混合操作的预期延迟可以写为$\mathbb{E}[\text{latency}] = \sum_j p_j F(o_j)$，其中$F(.)$是一个延迟预测模型：

> Besides accuracy, ProxylessNAS also considers *latency* as an important metric to optimize, as different devices might have very different requirements on inference time latency (e.g. GPU, CPU, mobile). To make latency differentiable, they model latency as a continuous function of the network dimensions. The expected latency of a mixed operation can be written as $\mathbb{E}[\text{latency}] = \sum_j p_j F(o_j)$, where $F(.)$ is a latency prediction model:

![Add a differentiable latency loss into the training of ProxylessNAS.  (Image source: Cai et al., 2019 )](https://lilianweng.github.io/posts/2020-08-06-nas/proxylessNAS-latency.png)

### 未来如何？

> What’s the Future?

到目前为止，我们已经看到了许多关于通过神经架构搜索自动化网络架构工程的有趣新想法，其中许多都取得了非常令人印象深刻的性能。然而，很难推断出*为什么*某些架构表现良好，以及我们如何开发可跨任务泛化而非高度依赖特定数据集的模块。

> So far we have seen many interesting new ideas on automating the network architecture engineering through neural architecture search and many have achieved very impressive performance. However, it is a bit hard to do inference on *why* some architecture work well and how we can develop modules generalizable across tasks rather than being very dataset-specific.

正如[Elsken等人（2019）](https://arxiv.org/abs/1808.05377)所指出的：

> As also noted in [Elsken, et al (2019)](https://arxiv.org/abs/1808.05377):

> “……，到目前为止，它很少能深入了解为什么特定架构表现良好，以及在独立运行中导出的架构会有多相似。识别共同主题，解释这些主题为何对高性能很重要，并研究这些主题是否能泛化到不同问题上，这将是可取的。”

> “…, so far it provides little insights into why specific architectures work well and how similar the architectures derived in independent runs would be. Identifying common motifs, providing an understanding why those motifs are important for high performance, and investigating if these motifs generalize over different problems would be desirable.”

与此同时，纯粹关注验证准确性的提升可能还不够（[Cai等人，2019](https://arxiv.org/abs/1812.00332)）。日常使用的移动电话等设备通常内存和计算能力有限。虽然AI应用正在影响我们的日常生活，但变得更加*设备特定*是不可避免的。

> In the meantime, purely focusing on improvement over validation accuracy might not be enough ([Cai et al., 2019](https://arxiv.org/abs/1812.00332)). Devices like mobile phones for daily usage in general have limited memory and computation power. While AI applications are on the way to affect our daily life, it is unavoidable to be more *device-specific*.

另一个有趣的探索是考虑将*未标记数据集*和[自监督学习](https://lilianweng.github.io/posts/2019-11-10-self-supervised/)用于NAS。标记数据集的大小总是有限的，而且很难判断这样的数据集是否存在偏差或与真实世界数据分布存在较大偏差。

> Another interesting investigation is to consider *unlabelled dataset* and [self-supervised learning](https://lilianweng.github.io/posts/2019-11-10-self-supervised/) for NAS. The size of labelled dataset is always limited and it is not easy to tell whether such a dataset has biases or big deviation from the real world data distribution.

[Liu等人（2020）](https://arxiv.org/abs/2003.12056)深入探讨了*“我们能否在没有人工标注标签的情况下找到高质量的神经架构？”*这一问题，并提出了一种名为*无监督神经架构搜索*（**UnNAS**）的新设置。架构的质量需要在搜索阶段以无监督的方式进行估计。该论文实验了三种无监督的[前置任务](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#images-based)：图像旋转预测、着色和解决拼图游戏。

> [Liu et al (2020)](https://arxiv.org/abs/2003.12056) delve into the question *“Can we find high-quality neural architecture without human-annotated labels?”* and proposed a new setup called *Unsupervised Neural Architecture Search* (**UnNAS**). The quality of the architecture needs to be estimated in an unsupervised fashion during the search phase. The paper experimented with three unsupervised [pretext tasks](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#images-based): image rotation prediction, colorization, and solving the jigsaw puzzle.

他们在UnNAS的一系列实验中观察到：

> They observed in a set of UnNAS experiments that:

1. 在*相同数据集上*，监督准确性与前置任务准确性之间存在高秩相关性。通常，无论数据集、搜索空间和前置任务如何，秩相关性都高于0.8。
2. 在*不同数据集之间*，监督准确性与前置任务准确性之间存在高秩相关性。
3. 更好的前置任务准确性转化为更好的监督准确性。
4. UnNAS架构的性能与监督对应物相当，尽管尚未更好。

> • High rank correlation between supervised accuracy and pretext accuracy *on the same dataset*. Typically the rank correlation is higher than 0.8, regardless of the dataset, the search space, and the pretext task.
> • High rank correlation between supervised accuracy and pretext accuracy *across datasets*.
> • Better pretext accuracy translates to better supervised accuracy.
> • Performance of UnNAS architecture is comparable to supervised counterparts, though not better yet.

一个假设是架构质量与图像统计数据相关。由于CIFAR-10和ImageNet都基于自然图像，它们具有可比性，并且结果是可迁移的。UnNAS有可能在搜索阶段引入大量未标记数据，从而更好地捕获图像统计数据。

> One hypothesis is that the architecture quality is correlated with image statistics. Because CIFAR-10 and ImageNet are all on the natural images, they are comparable and the results are transferable. UnNAS could potentially enable a much larger amount of unlabelled data into the search phase which captures image statistics better.

超参数搜索是机器学习社区中一个长期存在的话题。而NAS自动化了架构工程。我们正在逐步尝试自动化机器学习中通常需要大量人工努力的过程。更进一步，是否有可能自动发现机器学习算法？**AutoML-Zero**（[Real等人，2020](https://arxiv.org/abs/2003.03384)）研究了这一想法。AutoML-Zero使用[老化进化算法](https://lilianweng.github.io/posts/2020-08-06-nas/#aging-evolutionary-algorithms)，以简单的数学运算作为构建块，在形式上几乎没有限制地自动搜索整个机器学习算法。

> Hyperparameter search is a long-standing topic in the ML community. And NAS automates architecture engineering. Gradually we are trying to automate processes in ML which usually demand a lot of human efforts. Taking even one more step further, is it possible to automatically discover ML algorithms? **AutoML-Zero** ([Real et al 2020](https://arxiv.org/abs/2003.03384)) investigates this idea. Using [aging evolutionary algorithms](https://lilianweng.github.io/posts/2020-08-06-nas/#aging-evolutionary-algorithms), AutoML-Zero automatically searches for whole ML algorithms using little restriction on the form with only simple mathematical operations as building blocks.

它学习了三个组件函数。每个函数只采用非常基本的操作。

> It learns three component functions. Each function only adopts very basic operations.

• `Setup`：初始化内存变量（权重）。

• `Learn`：修改内存变量

• `Predict`：根据输入$x$进行预测。

英文原文：

• `Setup`: initialize memory variables (weights).

• `Learn`: modify memory variables

• `Predict`: make a prediction from an input $x$.

![Algorithm evaluation on one task (Image source: Real et al 2020 )](https://lilianweng.github.io/posts/2020-08-06-nas/AutoML-zero-evaluation.png)

在突变父代基因型时，考虑了三种类型的操作：

> Three types of operations are considered when mutating a parent genotype:

1. 在组件函数中的随机位置插入或删除一条随机指令；
2. 随机化组件函数中的所有指令；
3. 通过随机选择修改指令的一个参数（例如，“交换输出地址”或“更改常量值”）

> • Insert a random instruction or remove an instruction at a random location in a component function;
> • Randomize all the instructions in a component function;
> • Modify one of the arguments of an instruction by replacing it with a random choice (e.g. “swap the output address” or “change the value of a constant”)

![An illustration of evolutionary progress on projected binary CIFAR-10 with example code. (Image source: Real et al 2020 )](https://lilianweng.github.io/posts/2020-08-06-nas/AutoML-zero-progress.png)

### 附录：NAS论文总结

> Appendix: Summary of NAS Papers

| 模型名称 | 搜索空间 | 搜索算法 | 子模型评估 |
| --- | --- | --- | --- |
| NEAT (2002) | - | 进化（遗传算法） | - |
| NAS (2017) | 逐层顺序操作 | 强化学习（REINFORCE） | 从头开始训练直到收敛 |
| MetaQNN (2017) | 逐层顺序操作 | 强化学习（带有$\epsilon$-贪婪的Q学习） | 训练20个周期 |
| HNAS (2017) | 分层结构 | 进化（锦标赛选择） | 训练固定次数的迭代 |
| NASNet (2018) | 基于单元 | 强化学习（PPO） | 训练20个周期 |
| AmoebaNet (2018) | NASNet搜索空间 | 演化（带老化正则化的锦标赛选择） | 训练25个周期 |
| EAS (2018a) | 网络变换 | 强化学习（REINFORCE） | 两阶段训练 |
| PNAS (2018) | NASNet 搜索空间的简化版本 | SMBO；渐进式搜索复杂度递增的架构 | 训练20个周期 |
| ENAS (2018) | 基于序列和基于单元的搜索空间 | 强化学习（REINFORCE） | 训练一个共享权重的模型 |
| SMASH (2017) | 内存库表示 | 随机搜索 | HyperNet 预测评估架构的权重。 |
| One-Shot (2018) | 一个过参数化的一次性模型 | 随机搜索（随机归零一些路径） | 训练一次性模型 |
| DARTS (2019) | NASNet 搜索空间 | 梯度下降（操作上的 Softmax 权重） |
| ProxylessNAS (2019) | 树形结构架构 | 梯度下降（BinaryConnect）或 REINFORCE |
| SNAS (2019) | NASNet 搜索空间 | 梯度下降（具体分布） |

> 英文原表 / English original

| Model name | Search space | Search algorithms | Child model evaluation |
| --- | --- | --- | --- |
| NEAT (2002) | - | Evolution (Genetic algorithm) | - |
| NAS (2017) | Sequential layer-wise ops | RL (REINFORCE) | Train from scratch until convergence |
| MetaQNN (2017) | Sequential layer-wise ops | RL (Q-learning with $\epsilon$-greedy) | Train for 20 epochs |
| HNAS (2017) | Hierarchical structure | Evolution (Tournament selection) | Train for a fixed number of iterations |
| NASNet (2018) | Cell-based | RL (PPO) | Train for 20 epochs |
| AmoebaNet (2018) | NASNet search space | Evolution (Tournament selection with aging regularization) | Train for 25 epochs |
| EAS (2018a) | Network transformation | RL (REINFORCE) | 2-stage training |
| PNAS (2018) | Reduced version of NASNet search space | SMBO; Progressive search for architectures of increasing complexity | Train for 20 epochs |
| ENAS (2018) | Both sequential and cell-based search space | RL (REINFORCE) | Train one model with shared weights |
| SMASH (2017) | Memory-bank representation | Random search | HyperNet predicts weights of evaluated architectures. |
| One-Shot (2018) | An over-parameterized one-shot model | Random search (zero out some paths at random) | Train the one-shot model |
| DARTS (2019) | NASNet search space | Gradient descent (Softmax weights over operations) |
| ProxylessNAS (2019) | Tree structure architecture | Gradient descent (BinaryConnect) or REINFORCE |
| SNAS (2019) | NASNet search space | Gradient descent (concrete distribution) |

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2020年8月). 神经网络架构搜索. Lil’Log. https://lilianweng.github.io/posts/2020-08-06-nas/.

> Weng, Lilian. (Aug 2020). Neural architecture search. Lil’Log. https://lilianweng.github.io/posts/2020-08-06-nas/.

或

> Or

```
@article{weng2020nas,
  title   = "Neural Architecture Search",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2020",
  month   = "Aug",
  url     = "https://lilianweng.github.io/posts/2020-08-06-nas/"
}
```

### 参考文献

> Reference

[1] Thomas Elsken, Jan Hendrik Metzen, Frank Hutter. [“神经网络架构搜索：一项综述”](https://arxiv.org/abs/1808.05377) JMLR 20 (2019) 1-21.

> [1] Thomas Elsken, Jan Hendrik Metzen, Frank Hutter. [“Neural Architecture Search: A Survey”](https://arxiv.org/abs/1808.05377) JMLR 20 (2019) 1-21.

[2] Kenneth O. Stanley, et al. [“通过神经演化设计神经网络”](https://www.nature.com/articles/s42256-018-0006-z) Nature Machine Intelligence volume 1, pages 24–35 (2019).

> [2] Kenneth O. Stanley, et al. [“Designing neural networks through neuroevolution”](https://www.nature.com/articles/s42256-018-0006-z) Nature Machine Intelligence volume 1, pages 24–35 (2019).

[3] Kenneth O. Stanley & Risto Miikkulainen. [“通过增强拓扑演化神经网络”](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf) Evolutionary Computation 10(2): 99-127 (2002).

> [3] Kenneth O. Stanley & Risto Miikkulainen. [“Evolving Neural Networks through Augmenting Topologies”](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf) Evolutionary Computation 10(2): 99-127 (2002).

[4] Barret Zoph, Quoc V. Le. [“基于强化学习的神经网络架构搜索”](https://arxiv.org/abs/1611.01578) ICLR 2017.

> [4] Barret Zoph, Quoc V. Le. [“Neural architecture search with reinforcement learning”](https://arxiv.org/abs/1611.01578) ICLR 2017.

[5] Bowen Baker, et al. [“使用强化学习设计神经网络架构”](https://arxiv.org/abs/1611.02167) ICLR 2017.

> [5] Bowen Baker, et al. [“Designing Neural Network Architectures using Reinforcement Learning”](https://arxiv.org/abs/1611.02167) ICLR 2017.

[6] Bowen Baker, et al. [“使用性能预测加速神经网络架构搜索”](https://arxiv.org/abs/1705.10823) ICLR Workshop 2018.

> [6] Bowen Baker, et al. [“Accelerating neural architecture search using performance prediction”](https://arxiv.org/abs/1705.10823) ICLR Workshop 2018.

[7] Barret Zoph, et al. [“学习可迁移架构以实现可扩展图像识别”](https://arxiv.org/abs/1707.07012) CVPR 2018.

> [7] Barret Zoph, et al. [“Learning transferable architectures for scalable image recognition”](https://arxiv.org/abs/1707.07012) CVPR 2018.

[8] Hanxiao Liu, et al. [“用于高效架构搜索的层次表示。”](https://arxiv.org/abs/1711.00436) ICLR 2018.

> [8] Hanxiao Liu, et al. [“Hierarchical representations for efficient architecture search.”](https://arxiv.org/abs/1711.00436) ICLR 2018.

[9] Esteban Real, et al. [“用于图像分类器架构搜索的正则化演化”](https://arxiv.org/abs/1802.01548) arXiv:1802.01548 (2018).

> [9] Esteban Real, et al. [“Regularized Evolution for Image Classifier Architecture Search”](https://arxiv.org/abs/1802.01548) arXiv:1802.01548 (2018).

[10] Han Cai, et al. [“通过网络变换进行高效架构搜索”] AAAI 2018a.

> [10] Han Cai, et al. [“Efficient architecture search by network transformation”] AAAI 2018a.

[11] Han Cai, et al. [“用于高效架构搜索的路径级网络变换”](https://arxiv.org/abs/1806.02639) ICML 2018b.

> [11] Han Cai, et al. [“Path-Level Network Transformation for Efficient Architecture Search”](https://arxiv.org/abs/1806.02639) ICML 2018b.

[12] Han Cai, Ligeng Zhu & Song Han. [“ProxylessNAS: 在目标任务和硬件上直接进行神经网络架构搜索”](https://arxiv.org/abs/1812.00332) ICLR 2019.

> [12] Han Cai, Ligeng Zhu & Song Han. [“ProxylessNAS: Direct Neural Architecture Search on Target Task and Hardware”](https://arxiv.org/abs/1812.00332) ICLR 2019.

[13] Chenxi Liu, et al. [“渐进式神经网络架构搜索”](https://arxiv.org/abs/1712.00559) ECCV 2018.

> [13] Chenxi Liu, et al. [“Progressive neural architecture search”](https://arxiv.org/abs/1712.00559) ECCV 2018.

[14] Hieu Pham, et al. [“通过参数共享实现高效神经网络架构搜索”](https://arxiv.org/abs/1802.03268) ICML 2018.

> [14] Hieu Pham, et al. [“Efficient neural architecture search via parameter sharing”](https://arxiv.org/abs/1802.03268) ICML 2018.

[15] Andrew Brock, et al. [“SMASH：通过超网络进行一次性模型架构搜索。”](https://arxiv.org/abs/1708.05344) ICLR 2018.

> [15] Andrew Brock, et al. [“SMASH: One-shot model architecture search through hypernetworks.”](https://arxiv.org/abs/1708.05344) ICLR 2018.

[16] Gabriel Bender, et al. [“理解和简化一次性架构搜索。”](http://proceedings.mlr.press/v80/bender18a.html) ICML 2018.

> [16] Gabriel Bender, et al. [“Understanding and simplifying one-shot architecture search.”](http://proceedings.mlr.press/v80/bender18a.html) ICML 2018.

[17] Hanxiao Liu, Karen Simonyan, Yiming Yang. [“DARTS：可微分架构搜索”](https://arxiv.org/abs/1806.09055) ICLR 2019.

> [17] Hanxiao Liu, Karen Simonyan, Yiming Yang. [“DARTS: Differentiable Architecture Search”](https://arxiv.org/abs/1806.09055) ICLR 2019.

[18] Sirui Xie, Hehui Zheng, Chunxiao Liu, Liang Lin. [“SNAS：随机神经架构搜索”](https://arxiv.org/abs/1812.09926) ICLR 2019.

> [18] Sirui Xie, Hehui Zheng, Chunxiao Liu, Liang Lin. [“SNAS: Stochastic Neural Architecture Search”](https://arxiv.org/abs/1812.09926) ICLR 2019.

[19] Chenxi Liu et al. [“神经架构搜索需要标签吗？”](https://arxiv.org/abs/2003.12056) ECCV 2020.

> [19] Chenxi Liu et al. [“Are Labels Necessary for Neural Architecture Search?”](https://arxiv.org/abs/2003.12056) ECCV 2020.

[20] Esteban Real, et al. [“AutoML-Zero：从零开始演化机器学习算法”](https://arxiv.org/abs/2003.03384) ICML 2020.

> [20] Esteban Real, et al. [“AutoML-Zero: Evolving Machine Learning Algorithms From Scratch”](https://arxiv.org/abs/2003.03384) ICML 2020.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Neural Architecture Search (NAS) | 神经网络架构搜索 | 一种自动化设计高性能神经网络架构的方法。 |
| Search Space | 搜索空间 | 定义了NAS中可探索的网络操作及其连接方式的集合。 |
| Search Algorithm | 搜索算法 | 用于在搜索空间中采样和优化网络架构候选的方法。 |
| Evaluation Strategy | 评估策略 | 衡量或预测子模型性能，为搜索算法提供反馈的机制。 |
| Reinforcement Learning (RL) | 强化学习 | 一种机器学习范式，通过智能体与环境的交互学习最优策略。 |
| Evolutionary Algorithms (EA) | 演化算法 | 受生物进化启发的一类优化算法，用于搜索最优解。 |
| One-shot Approach | 一次性方法 | 训练一个包含所有可能操作的超图，然后从中评估子架构。 |
| Differentiable Architecture Search (DARTS) | 可微分架构搜索 | 通过连续松弛使架构选择可微分，从而能用梯度下降优化架构。 |
| ProxylessNAS | 无代理NAS | 一种直接在目标任务和硬件上进行神经网络架构搜索的方法，考虑延迟优化。 |
| HyperNet | 超网络 | 一种神经网络，其输出是另一个网络的权重。 |
| Cell-based Representation | 基于单元的表示 | 通过重复堆叠预定义单元（如普通单元和缩减单元）来构建网络架构。 |
| ScheduledDropPath | 计划路径丢弃 | DropPath的一种变体，其路径丢弃概率在训练期间线性增加。 |
| Aging Evolutionary Algorithms | 老化演化算法 | 一种演化算法，通过偏爱“更年轻”的基因型并淘汰最老的模型来探索搜索空间。 |
| Unsupervised Neural Architecture Search (UnNAS) | 无监督神经网络架构搜索 | 在没有人工标注标签的情况下，通过无监督前置任务估计架构质量的NAS方法。 |
| AutoML-Zero | 零起点自动化机器学习 | 一种使用老化演化算法从基本数学运算开始自动搜索机器学习算法的方法。 |
