# 如何在多 GPU 上训练超大型模型？

> How to Train Really Large Models on Many GPUs?

> 来源：Lil'Log / Lilian Weng，2021-09-24
> 原文链接：https://lilianweng.github.io/posts/2021-09-25-train-large/
> 分类：深度学习 / 大模型训练

## 核心要点

- 训练超大型深度神经网络面临GPU内存和训练时间限制，单个GPU难以承载。
- 为解决此问题，需采用数据并行、模型并行和张量并行等多种并行范式。
- 数据并行通过复制模型和分配数据实现，需同步梯度或权重，包括批量同步和异步并行。
- 模型并行将模型参数划分到多个设备，而流水线并行通过微批次处理减少计算气泡，提高效率。
- 张量并行将单个张量操作水平划分到多个设备，如Transformer模型中的MLP和自注意力块。
- 专家混合（MoE）方法通过门控机制将输入路由到部分专家，实现模型规模的突破，如GShard、Switch Transformer和专家选择路由。
- 文章还介绍了CPU卸载、激活重计算、混合精度训练和中间结果压缩等内存节省设计。
- 内存高效优化器如Adafactor、SM3和ZeRO通过优化器状态管理，显著减少内存消耗，其中ZeRO通过增强数据并行和分区激活重计算进一步优化。

## 正文

[2022-03-13 更新：新增[专家选择路由](https://lilianweng.github.io/posts/2021-09-25-train-large/#ec)。]  

[2022-06-10 更新]：[Greg](https://gregbrockman.com/)和我撰写了本文的精简升级版，发表在 OpenAI 博客上：[“训练大型神经网络的技术”](https://openai.com/blog/techniques-for-training-large-neural-networks/)

> [Updated on 2022-03-13: add [expert choice routing](https://lilianweng.github.io/posts/2021-09-25-train-large/#ec).]  
>
> [Updated on 2022-06-10]: [Greg](https://gregbrockman.com/) and I wrote a shorted and upgraded version of this post, published on OpenAI Blog: [“Techniques for Training Large Neural Networks”](https://openai.com/blog/techniques-for-training-large-neural-networks/)

近年来，我们看到更大的预训练[语言模型](https://lilianweng.github.io/posts/2019-01-31-lm/)在许多 NLP 基准任务上取得了更好的结果。训练大型深度神经网络具有挑战性，因为它需要大量的 GPU 内存和漫长的训练时间。

> In recent years, we are seeing better results on many NLP benchmark tasks with larger pre-trained [language models](https://lilianweng.github.io/posts/2019-01-31-lm/). How to train large and deep neural networks is challenging, as it demands a large amount of GPU memory and a long horizon of training time.

然而，单个 GPU 工作器内存有限，许多大型模型的规模已经超出了单个 GPU 的范围。有几种并行范式可以实现在多个 GPU 上进行模型训练，以及各种模型架构和内存节省设计，以帮助实现训练*超大型*神经网络。

> However an individual GPU worker has limited memory and the sizes of many large models have grown beyond a single GPU. There are several parallelism paradigms to enable model training across multiple GPUs, as well as a variety of model architecture and memory saving designs to help make it possible to train *very large* neural networks.

### 训练并行性

> Training Parallelism

训练超大型神经网络模型的主要瓶颈是对大量 GPU 内存的强烈需求，远远超出了单个 GPU 机器所能承载的范围。除了模型权重（例如数百亿个浮点数）之外，存储中间计算输出（例如梯度和优化器状态，如 Adam 中的动量&变异）通常甚至更昂贵。此外，训练大型模型通常需要大型训练语料库，因此单个进程可能需要永远。

> The main bottleneck for training very large neural network models is the intense demand for a large amount of GPU memory, way above what can be hosted on an individual GPU machine. Besides the model weights (e.g. tens of billions of floating point numbers), it is usually even more expensive to store intermediate computation outputs such as gradients and optimizer states (e.g. momentums & variations in Adam). Additionally training a large model often pairs with a large training corpus and thus a single process may just take forever.

因此，并行性是必要的。并行性可以在不同的维度上发生，包括数据、模型架构和张量操作。

> As a result, parallelism is necessary. Parallelism can happen at different dimensions, including data, model architecture, and tensor operation.

#### 数据并行

> Data Parallelism

**数据并行 (DP)** 最简单的方法是将相同的模型权重复制到多个工作器中，并为每个工作器分配一部分数据以同时进行处理。

> The most naive way for **Data parallelism (DP)**  is to copy the same model weights into multiple workers and assign a fraction of data to each worker to be processed at the same time.

如果模型大小超过单个 GPU 节点的内存，朴素的 DP 无法很好地工作。像 *GeePS* ([Cui et al. 2016](https://www.pdl.cmu.edu/PDL-FTP/CloudComputing/GeePS-cui-eurosys16.pdf)) 这样的方法，当模型太大无法适应一台机器时，会将暂时未使用的参数卸载回 CPU，以在有限的 GPU 内存下工作。数据交换传输应该在后端进行，并且不干扰训练计算。

> Naive DP cannot work well if the model size is larger than a single GPU node’s memory. Methods like *GeePS* ([Cui et al. 2016](https://www.pdl.cmu.edu/PDL-FTP/CloudComputing/GeePS-cui-eurosys16.pdf)) offload temporarily unused parameters back to CPU to work with limited GPU memory when the model is too big to fit into one machine. The data swapping transfer should happen at the backend and not interfere with training computation.

在每个小批量结束时，工作节点需要同步梯度或权重以避免陈旧。存在两种主要的同步方法，并且两者都有明显的优缺点。

> At the end of each minibatch, workers need to synchronize gradients or weights to avoid staleness. There are two main synchronization approaches and both have clear pros & cons.

1. *批量同步并行 (BSP)*: 工作器在每个小批量处理结束时同步数据。这可以防止模型权重过时并提高学习效率，但每台机器都必须停止并等待其他机器发送梯度。
2. *异步并行 (ASP)*: 每个 GPU 工作器异步处理数据，无需等待或停滞。然而，这很容易导致使用过时的权重，从而降低统计学习效率。即使它增加了计算时间，也可能无法加快训练收敛时间。

> • *Bulk synchronous parallels (BSP)*: Workers sync data at the end of every minibatch. It prevents model weights staleness and good learning efficiency but each machine has to halt and wait for others to send gradients.
> • *Asynchronous  parallel (ASP)*: Every GPU worker processes the data asynchronously, no waiting or stalling. However, it can easily lead to stale weights being used and thus lower the statistical learning efficiency. Even though it increases the computation time, it may not speed up training time to convergence.

介于两者之间的方法是每隔 $x$ 迭代 ($x > 1$) 全局同步一次梯度。此功能在分布式数据并行 ([DDP](https://pytorch.org/tutorials/intermediate/ddp_tutorial.html)) 中被称为“梯度累积”，自 Pytorch v1.5 ([Li et al. 2021](https://arxiv.org/abs/2006.15704)) 起。梯度分桶避免了即时 `AllReduce` 操作，而是将多个梯度分桶到一个 `AllReduce` 中以提高吞吐量。可以根据计算图进行计算和通信调度优化。

> Somewhere in the middle is to synchronize gradients globally once every $x$ iterations ($x > 1$). This feature is called “gradient accumulation” in Distribution Data Parallel ([DDP](https://pytorch.org/tutorials/intermediate/ddp_tutorial.html)) since Pytorch v1.5 ([Li et al. 2021](https://arxiv.org/abs/2006.15704)). Bucketing gradients avoid immediate `AllReduce` operations but instead buckets multiple gradients into one `AllReduce` to improve throughput. Computation and communication scheduling optimization can be made based on the computation graph.

![Pseudo code for Pytorch DDP. (Image source: Li et al. 2021 )](https://lilianweng.github.io/posts/2021-09-25-train-large/pytorch-ddp.png)

#### 模型并行

> Model Parallelism

**模型并行（MP）**旨在解决模型权重无法适应单个节点的情况。计算和模型参数被划分到多台机器上。与数据并行中每个工作节点都托管整个模型的完整副本不同，MP只在一个工作节点上分配一小部分模型参数，从而减少了内存使用和计算量。

> **Model parallelism (MP)** aims to solve the case when the model weights cannot fit into a single node. The computation and model parameters are partitioned across multiple machines. Different from data parallelism where each worker hosts a full copy of the entire model, MP only allocates a fraction of model parameters on one worker and thus both the memory usage and the computation are reduced.

由于深度神经网络通常包含一堆垂直层，因此按层拆分大型模型似乎是直接的方法，其中一小组连续的层被分组到一个工作节点上的一个分区中。然而，一个天真的实现，让每个数据批次通过多个具有顺序依赖性的此类工作节点运行，会导致大量的等待时间气泡和计算资源的严重利用不足。

> Since deep neural networks usually contain a stack of vertical layers, it feels straightforward to split a large model by layer, where a small consecutive set of layers are grouped into one partition on one worker. However, a naive implementation for running every data batch through multiple such workers with sequential dependency leads to big bubbles of waiting time and severe under-utilization of computation resources.

![A naive model parallelism setup where the model is vertically split into 4 partitions. Data is processed by one worker at a time due to sequential dependency, leading to large “bubbles” of idle time. (Image source: Huang et al. 2019 )](https://lilianweng.github.io/posts/2021-09-25-train-large/naive-data-parallelism.png)

#### 流水线并行

> Pipeline Parallelism

**流水线并行（PP）**将模型并行与数据并行结合起来，以减少低效的“时间气泡”。主要思想是将一个迷你批次拆分成多个微批次，并使每个阶段的工作节点能够同时处理一个微批次。请注意，每个微批次都需要两次通过，一次前向和一次后向。工作节点间的通信只传输激活（前向）和梯度（后向）。这些通过如何调度以及梯度如何聚合在不同的方法中有所不同。分区（工作节点）的数量也称为*流水线深度*。

> **Pipeline parallelism (PP)** combines model parallelism with data parallelism to reduce inefficient time “bubbles’’. The main idea is to split one minibatch into multiple microbatches and enable each stage worker to process one microbatch simultaneously. Note that every microbatch needs two passes, one forward and one backward. Inter-worker communication only transfers activations (forward) and gradients (backward). How these passes are scheduled and how the gradients are aggregated vary in different approaches. The number of partitions (workers) is also known as *pipeline depth*.

在 *GPipe* ([Huang et al. 2019](https://arxiv.org/abs/1811.06965)) 中，来自多个微批次的梯度在最后被聚合并同步应用。同步梯度下降保证了学习的一致性和效率，无论工作器数量多少。如图 3 所示，气泡仍然存在，但比在给定 $m$ 均匀分割的微批次和 $d$ 分区的情况下小得多，假设每个微批次的前向和后向都花费一个时间单位，气泡的比例为：

> In *GPipe* ([Huang et al. 2019](https://arxiv.org/abs/1811.06965)) gradients from multiple microbatches are aggregated and applied synchronously at the end. The synchronous gradient descent guarantees learning consistency and efficiency irrespective of the number of workers. As shown in Fig. 3, bubbles still exist but are much smaller than what’s in Given $m$ evenly split microbatches and $d$ partitions, assuming both forward and backward per microbatch take one unit of time, the fraction of bubble is:

$$
1 - \frac{2md}{(2m + 2(d-1))d} = \frac{d-1}{m+d-1}
$$

GPipe 论文观察到，如果微批次数量是分区数量的 4 倍以上 $m > 4d$（当应用 [激活重计算](https://lilianweng.github.io/posts/2021-09-25-train-large/#activation-recomputation) 时），气泡开销几乎可以忽略不计。

> The GPipe paper observed that the bubble overhead is almost negligible if the number of microbatches is more than 4x the number of partitions $m > 4d$ (when [activation recomputation](https://lilianweng.github.io/posts/2021-09-25-train-large/#activation-recomputation) is applied).

![Illustration of pipeline parallelism in GPipe with 4 microbatches and 4 partitions. GPipe aggregates and updates gradients across devices synchronously at the end of every batch. (Image source: Huang et al. 2019 )](https://lilianweng.github.io/posts/2021-09-25-train-large/gpipe.png)

GPipe 在吞吐量方面实现了与设备数量几乎线性的加速，尽管如果模型参数未在工作器之间均匀分布，则不总是能保证这一点。

> GPipe achieves almost linear speedup in throughput with the number of devices, although it is not always guaranteed if the model parameters are not evenly distributed across workers.

*PipeDream* ([Narayanan et al. 2019](https://cs.stanford.edu/~matei/papers/2019/sosp_pipedream.pdf)) 调度每个工作器交替处理前向和后向传播 (`1F1B`)。\nPipeDream 将每个模型分区命名为“阶段”，每个阶段工作器可以有多个副本以运行数据并行。在此过程中，PipeDream 使用确定性的轮询负载均衡策略在阶段的多个副本之间分配工作，以确保同一小批次的前向和后向传播发生在同一副本上。

> *PipeDream* ([Narayanan et al. 2019](https://cs.stanford.edu/~matei/papers/2019/sosp_pipedream.pdf)) schedules each worker to alternatively process the forward and backward passes (`1F1B`).
> PipeDream names each model partition “stage” and each stage worker can have multiple replicas to run data parallelism. In this process, PipeDream uses a deterministic round-robin load balancing strategy to assign work among multiple replicas of stages to ensure that the forward and backward passes for the same minibatch happen on the same replica.

![Illustration of `1F1B` microbatch scheduling in PipeDream. (Image source: Harlap et al. 2018 )](https://lilianweng.github.io/posts/2021-09-25-train-large/pipedream.png)

由于 PipeDream 没有跨所有工作器的批次结束全局梯度同步，1F1B 的原生实现很容易导致一个微批次的前向和后向传播使用不同版本的模型权重，从而降低学习效率。PipeDream 提出了几种设计来解决这个问题：

> Since PipeDream does not have an end-of-batch global gradient sync across all the workers, an native implementation of 1F1B can easily lead to the forward and backward passes of one microbatch using different versions of model weights, thus lowering the learning efficiency. PipeDream proposed a few designs to tackle this issue:

- *权重暂存 (Weight stashing)*：每个工作器跟踪多个模型版本，并确保在给定一个数据批次时，前向和后向传播中使用相同版本的权重。
- *垂直同步 (Vertical sync)*（可选）：模型权重的版本与激活和梯度一起在阶段工作器之间流动。然后计算采用从前一个工作器传播过来的相应暂存版本。这个过程保持了工作器之间的版本一致性。请注意，它是异步的，与 GPipe 不同。

> • *Weight stashing*: Each worker keeps track of several model versions and makes sure that the same version of weights are used in the forward and backward passes given one data batch.
> • *Vertical sync* (Optional): The version of model weights flows between stage workers together with activations and gradients. Then the computation adopts the corresponding stashed version propagated from the previous worker. This process keeps version consistency across workers. Note that it is asynchronous, different from GPipe.

在训练运行开始时，PipeDream 首先分析模型中每一层的计算内存成本和时间，然后优化将层划分为阶段的解决方案，这是一个动态规划问题。

> At the beginning of a training run, PipeDream first profiles the computation memory cost and time of each layer in the model and then optimizes a solution for partitioning layers into stages, which is a dynamic programming problem.

![Results for VGG16 on ILSVRC12. (Top) Accuracy vs time. The integer marks the number of stage workers. ASP =  Asynchronous  parallel & BSP = Bulk synchronous parallels. (Bottom) Training time speedup for different parallelism configurations. Straight pipeline refers to pipeline parallelism without data parallelism. (Image source: Harlap et al. 2018 )](https://lilianweng.github.io/posts/2021-09-25-train-large/pipedream-results.png)

后来提出了 PipeDream 的两种变体，通过暂存的模型版本来减少内存占用 ([Narayanan et al. 2021](https://arxiv.org/abs/2006.09503))。

> Two variations of PipeDream were later proposed to reduce the memory footprint by stashed model versions ([Narayanan et al. 2021](https://arxiv.org/abs/2006.09503)).

*PipeDream-flush* 周期性地添加全局同步的流水线刷新，就像 GPipe 一样。通过这种方式，它通过牺牲一点吞吐量来大大减少内存占用（即只维护一个版本的模型权重）。

> *PipeDream-flush* adds a globally synchronized pipeline flush periodically, just like GPipe. In this way, it greatly reduces the memory footprint (i.e. only maintain a single version of model weights) by sacrificing a little throughput.

![Illustration of pipeline scheduling in PipeDream-flush. (Image source: ( Narayanan et al. 2021 )](https://lilianweng.github.io/posts/2021-09-25-train-large/pipedream-flush.png)

*PipeDream-2BW* 只维护两个版本的模型权重，其中“2BW”是“double-buffered weights”的缩写。它每 $k$ 个微批次生成一个新模型版本，并且 $k$ 应该大于流水线深度 $d$，$k > d$。新更新的模型版本不能立即完全替换旧版本，因为一些剩余的后向传播仍然依赖于旧版本。总共只需要保存两个版本，因此内存成本大大降低。

> *PipeDream-2BW* maintains only two versions of model weights, where “2BW” is short for “double-buffered weights”. It generates a new model version every $k$ microbatches and $k$ should be larger than the pipeline depth $d$, $k > d$. A newly updated model version cannot fully replace the old version immediately since some leftover backward passes still depend on the old version. In total only two versions need to be saved so the memory cost is much reduced.

![Illustration of pipeline scheduling in PipeDream-2BW. (Image source: ( Narayanan et al. 2021 )](https://lilianweng.github.io/posts/2021-09-25-train-large/pipedream-2bw.png)

#### 张量并行

> Tensor Parallelism

模型并行和流水线并行都垂直地分割模型。另一方面，我们可以将一个张量操作的计算水平地划分到多个设备上，这被称为 **张量并行 (TP)**。

> Both model and pipeline parallelisms split a model vertically. OTOH we can horizontally partition the computation for one tensor operation across multiple devices, named **Tensor parallelism (TP)**.

鉴于其流行性，我们以 Transformer 为例。Transformer 模型主要由多层 MLP 和自注意力块组成。*Megatron-LM* ([Shoeybi et al. 2020](https://arxiv.org/abs/1909.08053)) 采用一种简单的方法来并行化 MLP 和自注意力的层内计算。

> Let’s take the transformer as an example given its popularity. The transformer model mainly consists of layers of MLP and self-attention blocks. *Megatron-LM* ([Shoeybi et al. 2020](https://arxiv.org/abs/1909.08053)) adopts a simple way to parallelize intra-layer computation for MLP and self-attention.

Transformer 中的 MLP 层包含一个 GEMM（通用矩阵乘法），后跟一个非线性 GeLU 转换。让我们按列分割权重矩阵 $A$：

> A MLP layer in a transformer contains a GEMM (General matrix multiply) followed by an non-linear GeLU transfer. Let’s split weight matrix $A$ by column:

$$
\begin{aligned}
\text{Split }A &= [A_1, A_2] \\
Y &=\text{GeLU}(XA) \\
[Y_1, Y_2] &= [\text{GeLU}(XA_1), \text{GeLU}(XA_2)]
\end{aligned}
$$

注意力块根据上述分区并行地使用查询 ($Q$)、键 ($K$) 和值权重 ($V$) 运行 GEMM，然后将它们与另一个 GEMM 结合以产生注意力头结果。

> The attention block runs GEMM with query ($Q$), key ($K$), and value weights ($V$) according to the above partitioning in parallel and then combines them with another GEMM to produce the attention head results.

$$
\text{Attention}(X, Q, K, V) = \text{softmax}(\frac{(XQ) (XK)^\top}{\sqrt{d_k}}) XV
$$

![Illustration of tensor parallelism for key transformer components proposed in Megatron-LM. (Image source: Shoeybi et al. 2020 )](https://lilianweng.github.io/posts/2021-09-25-train-large/Megatron-LM.png)

[Narayanan et al. (2021)](https://arxiv.org/abs/2104.04473) 将流水线、张量和数据并行与一种新的流水线调度策略相结合，并将其方法命名为 *PTD-P*。每个工作器可以被分配多个较小的连续层子集块（例如，设备 1 有层 1、2、9、10；设备 2 有层 3、4、11、12；每个设备有两个模型块），而不是只在一个设备上放置一组连续的层（“模型块”）。一个批次中的微批次数量应该能被工作器数量整除 ($m % d = 0$)。如果每个工作器有 $v$ 个模型块，与 GPipe 调度相比，流水线气泡时间可以减少 $v$ 倍。

> [Narayanan et al. (2021)](https://arxiv.org/abs/2104.04473) combined pipeline, tensor and data parallelism with a new pipeline scheduling strategy and named their approach *PTD-P*. Instead of only positioning a continuous set of layers (“model chunk”) on a device, each worker can be assigned with multiple chunks of smaller continuous subsets of layers (e.g. device 1 has layers 1, 2, 9, 10; device 2 has layers 3, 4, 11, 12; each has two model chunks). The number of microbatches in one batch should be exactly divided by the number of workers ($m % d = 0$). If there are $v$ model chunks per worker, the pipeline bubble time can be reduced by a multiplier of $v$ compared to a GPipe scheduling.

![(Top) Default `1F1B` pipeline schedule as in PipeDream-flush. (Bottom) Interleaved 1F1B pipeline schedule. First model chunks are in dark colors and second chunks are in light colors. (Image source: Narayanan et al. 202) )](https://lilianweng.github.io/posts/2021-09-25-train-large/PTD-P-interleaved.png)

### 专家混合 (Mixture-of-Experts, MoE)

> Mixture-of-Experts (MoE)

**专家混合 (Mixture-of-Experts, MoE)** 方法最近引起了广泛关注，因为研究人员（主要来自 Google）试图突破模型大小的限制。其核心思想是 [集成学习](https://en.wikipedia.org/wiki/Ensemble_learning)：*多个弱学习器的组合会给你一个强学习器！*

> The **Mixture-of-Experts (MoE)** approach attracts a lot of attention recently as researchers (mainly from Google) try to push the limit of model size. The core of the idea is [ensembling learning](https://en.wikipedia.org/wiki/Ensemble_learning): *Combination of multiple weak learners gives you a strong learner!*

在一个深度神经网络中，集成可以通过连接多个专家的门控机制来实现（[Shazeer et al., 2017](https://arxiv.org/abs/1701.06538)）。门控机制控制网络的哪个子集（例如哪些专家）应该被激活以产生输出。该论文将其命名为“稀疏门控专家混合”（MoE）层。

> Within one deep neural network, ensembling can be implemented with a gating mechanism connecting multiple experts ([Shazeer et al., 2017](https://arxiv.org/abs/1701.06538)). The gating mechanism controls which subset of the network (e.g. which experts) should be activated to produce outputs. The paper named it “sparsely gated mixture-of-experts” (MoE) layer.

一个MoE层精确地包含

> Precisely one MoE layer contains

• $n$前馈网络作为专家$\{E_i\}^n_{i=1}$

• 一个可训练的门控网络$G$学习一个概率分布$n$专家，以便将流量路由到少数选定的专家。

英文原文：

• $n$ feed-forward networks as experts $\{E_i\}^n_{i=1}$

• A trainable gating network $G$ to learn a probability distribution over $n$ experts so as to route the traffic to a few selected experts.

根据门控输出，并非每个专家都必须进行评估。当专家数量过多时，我们可以考虑使用两级分层MoE。

> Depending on the gating outputs, not every expert has to be evaluated. When the number of experts is too large, we can consider using a two-level hierarchical MoE.

![Illustration of a mixture-of-experts (MoE) layer. Only 2 out of $n$ experts are selected and activated by the gating network. (Image source: Shazeer et al., 2017 )](https://lilianweng.github.io/posts/2021-09-25-train-large/moe.png)

一个简单的选择 $G$ 是将输入与一个可训练的权重矩阵 $G_g$ 相乘，然后进行 softmax 操作：$G_\sigma (x) = \text{softmax}(x W_g)$。然而，这会产生一个用于门控的密集控制向量，并且无助于节省计算资源，因为我们不需要仅在 $G^{(i)}(x)=0$ 时才评估一个专家。因此，MoE 层只保留前 $k$ 个值。它还将可调高斯噪声添加到 $G$ 中以改善负载均衡。这种机制被称为 *噪声 Top-k 门控*。

> A simple choice of $G$ is to multiply the input with a trainable weight matrix $G_g$ and then do softmax: $G_\sigma (x) = \text{softmax}(x W_g)$. However, this produces a dense control vector for gating and does not help save computation resources because we don’t need to evaluate an expert only when $G^{(i)}(x)=0$. Thus the MoE layer only keeps the top $k$ values. It also adds tunable Gaussian noise into $G$ to improve load balancing. This mechanism is called *noisy top-k gating*.

$$
\begin{aligned} 
G(x) &= \text{softmax}( \text{topk}(H(x), k)) \\
H^{(i)}(x) &= (xW_g)^{(i)} + \epsilon \cdot \text{softplus}((xW_\text{noise})^{(i)} ); \quad \epsilon \sim \mathcal{N}(0, \mathbf{1}) \\
\text{topk}^{(i)}(v, k) &= \begin{cases} v^{(i)} & \text{if }v^{(i)}\text{ is in the top }k\text{ elements of }v \\ -\infty & \text{otherwise} 
\end{cases} 
\end{aligned}
$$

其中上标$v^{(i)}$表示向量$v$的第 i 维。函数$\text{topk}(., k)$选择了前$k$个具有最高值的维度，将其他维度设置为$-\infty$。

> where the superscript $v^{(i)}$ denotes the i-th dimension of the vector $v$. The function $\text{topk}(., k)$ selected the top $k$ dimensions with highest values by setting other dimensions to $-\infty$.

为了避免门控网络可能一直偏爱少数几个强专家而产生的自我强化效应，[Shazeer et al. (2017)](https://arxiv.org/abs/1701.06538) 提出了一种软约束，通过额外的“重要性损失”来鼓励所有专家具有相同的权重。这等同于每个专家批次平均值的[变异系数](https://en.wikipedia.org/wiki/Coefficient_of_variation)的平方。

> To avoid the self-reinforcing effect that the gating network may favor a few strong experts all the time, [Shazeer et al. (2017)](https://arxiv.org/abs/1701.06538) proposed a soft constraint via an additional importance loss to encourage all the experts to have the same weights. It is equivalent to the square of the [coefficient of variation](https://en.wikipedia.org/wiki/Coefficient_of_variation) of batchwise average value per expert.

$$
L_\text{aux} = w_\text{aux} \cdot \text{CV}(\sum_{x \in X} G(x))^2
$$

其中 $\text{CV}$ 是变异系数，损失权重 $w_\text{aux}$ 是一个需要调整的超参数。

> where $\text{CV}$ is the coefficient of variation and the loss weight $w_\text{aux}$ is a hyperparameter to tune.

因为每个专家网络只获得一小部分训练样本（“批次缩小问题”），我们应该在MoE中尝试使用尽可能大的批次大小。然而，这受到GPU内存的限制。可以应用数据并行和模型并行来提高吞吐量。

> Because every expert network only gets a fraction of training samples (“The shrinking batch problem”), we should try to use a batch size as large as possible in MoE. However, it is restricted by GPU memory. Data parallelism and model parallelism can be applied to improve the throughput.

![Test perplexity on 1-Billion-Word language modeling benchmark. (Left) The model capacity increases from left to right, containing 4, 32, 256, 256, 1024 and 4096 experts. (Right) Performance of the 4 billion parameters MoE model, the largest one in the left figure, under different computation budgets. (Image source: Shazeer et al., 2017 )](https://lilianweng.github.io/posts/2021-09-25-train-large/moe-experiments.png)

**GShard** ([Lepikhin et al., 2020](https://arxiv.org/abs/2006.16668)) 通过分片将 MoE transformer 模型扩展到 6000 亿个参数。MoE transformer 用 MoE 层替换了其他所有前馈层。*分片 MoE transformer* 仅将 MoE 层分片到多台机器上，而其他层则简单地复制。

> **GShard** ([Lepikhin et al., 2020](https://arxiv.org/abs/2006.16668)) scales the MoE transformer model up to 600 billion parameters with sharding. The MoE transformer replaces every other feed forward layer with a MoE layer. The *sharded MoE transformer* only has the MoE layers sharded across multiple machines, while other layers are simply duplicated.

在 GShard 中，门控函数 $G$ 有几种改进设计：

> There are several improved designs for the gating function $G$ in GShard:

- *专家容量*：通过一个专家的令牌数量不应超过一个阈值，该阈值被称为“专家容量”。如果一个令牌被路由到已达到其容量的专家，该令牌将被标记为“溢出”，并且门控输出将变为零向量。
- *局部组调度*：令牌被均匀地划分到多个局部组中，并且专家容量在组级别上强制执行。
- *辅助损失*：其动机与原始 MoE 辅助损失相似。他们添加了一个辅助损失，以最小化路由到每个专家的数据比例的均方。
- *随机路由*: 第二好的专家以与其权重成比例的概率被选中；否则，GShard 遵循随机路由，以增加一些随机性。

> • *Expert capacity*: The amount of tokens going through one expert should not go above a threshold, named “expert capacity”. If a token is routed to experts that have reached their capacity, the token would be marked “overflowed” and the gating output is changed to a zero vector.
> • *Local group dispatching*: Tokens are evenly partitioned into multiple local groups and the expert capacity is enforced on the group level.
> • *Auxiliary loss*: The motivation is similar to the original MoE aux loss. They add an auxiliary loss to minimize the mean square of the fraction of data routed to each expert.
> • *Random routing*: The 2nd-best expert is selected with a probability proportional to its weight; otherwise, GShard follows a random routing, so as to add some randomness.

![Pseudo code of the group-level top-2 gating mechanism with auxiliary loss in GShard. (Image source: Lepikhin et al., 2020 )](https://lilianweng.github.io/posts/2021-09-25-train-large/gshard-algo.png)

**Switch Transformer** ([Fedus 等人 2021](https://arxiv.org/abs/2101.03961)) 通过用*稀疏 Switch FFN 层*替换密集前馈层，将模型大小扩展到数万亿个参数 (!!)，其中每个输入只路由到*一个*专家网络。负载均衡的辅助损失是 $\text{loss}_\text{aux} = w_\text{aux} \sum_{i=1}^n f_i p_i$，给定 `n` 个专家，其中 `f_i` 是路由到第 `i` 个专家的 token 比例，`p_i` 是门控网络预测的专家 `i` 的路由概率。

英文原文：Switch Transformer ([Fedus et al. 2021](https://arxiv.org/abs/2101.03961)) scales the model size up to trillions of parameters (!!) by replacing the dense feed forward layer with a *sparse switch FFN layer* in which each input is only routed to *one* expert network. The auxiliary loss for load balancing is 

$\text{loss}_\text{aux} = w_\text{aux} \sum_{i=1}^n f_i p_i$ given `n` experts, where `f_i` is the fraction of tokens routed to the `i` -th expert and `p_i` is the routing probability for expert `i` predicted by the gating network.

![Switch transformer. The sparse switch FFN layer is in the blue boxes. (Image source: Fedus et al. 2021 )](https://lilianweng.github.io/posts/2021-09-25-train-large/switch-transformer.png)

为了提高训练稳定性，Switch Transformer 采用了以下设计：

> To improve training stability, switch transformer incorporates the following designs:

• *选择性精度*。他们表明，选择性地将模型的局部部分转换为 FP32 精度可以提高稳定性，同时避免了 FP32 张量昂贵的通信成本。FP32 精度仅在路由器函数主体内部使用，结果被重新转换为 FP16。

• *更小的初始化*。权重矩阵的初始化是从均值为 $\mu=0$ 且标准差为 $\sigma = \sqrt{s/n}$ 的截断正态分布中采样的。他们还建议将 Transformer 初始化比例参数 $s=1$ 减小到 $s=0.1$。

• *使用更高的专家 dropout*。微调通常适用于小型数据集。为了避免过拟合，每个专家内部的 dropout 率显著增加。有趣的是，他们发现增加所有层的 dropout 会导致性能不佳。在论文中，他们在非专家层使用 0.1 的 dropout 率，但在专家 FF 层内部使用 0.4。

英文原文：

• *Selective precision*. They showed that selectively casting only a local part of the model to FP32 precision improves stability, while avoiding the expensive communication cost of FP32 tensors. The FP32 precision is only used within the body of the router function and the results are recast to FP16.

• *Smaller initialization*. The initialization of weight matrices is sampled from a truncated normal distribution with mean $\mu=0$ and stdev $\sigma = \sqrt{s/n}$. They also recommended reducing the transformer initialization scale parameter $s=1$ to $s=0.1$.

• *Use higher expert dropout*. Fine-tuning often works with a small dataset. To avoid overfitting, the dropout rate within each expert is increased by a significant amount. Interestingly they found that increasing dropout across all layers lead to poor performance. In the paper, they used a dropout rate 0.1 at non-expert layers but 0.4 within expert FF layers.

Switch Transformer 论文总结了训练大型模型的不同数据和模型并行策略，并附有很好的图示：

> The switch transformer paper summarized different data and model parallelism strategies for training large models with a nice illustration:

![An illustration of various parallelism strategies on how (Top) model weights and (Bottom) data are split over multiple GPU cores. In the top row, each color denotes a unique weight matrix. In the bottom row, different colors indicate different sets of tokens.  (Image source: Fedus et al. 2021 )](https://lilianweng.github.io/posts/2021-09-25-train-large/switch-transformer-parallelism.png)

GShard top-2 和 Switch Transformer top-1 都依赖于*token choice*，其中每个 token 选择最佳的一个或两个专家进行路由。它们都采用辅助损失来鼓励更均衡的负载分配，但这并不能保证最佳性能。此外，专家容量限制可能导致 token 浪费，因为如果专家达到其容量限制，这些 token 将被丢弃。

> Both GShard top-2 and Switch Transformer top-1 depend on *token choice*, where each token picks the best one or two experts to route through. They both adopt an auxiliary loss to encourage more balanced load allocation but it does not guarantee the best performance. Furthermore, the expert capacity limit may lead to wasted tokens as they would be discarded if an expert reaches its capacity limit.

**专家选择 (EC)** ([Zhou et al. 2022](https://arxiv.org/abs/2202.09368)) 路由机制则允许每个专家选择前`k`个 token。通过这种方式，每个专家自然地保证了固定的容量，并且每个 token 可以被路由到多个专家。EC 可以实现完美的负载均衡，并被证明可以将训练收敛速度提高 2 倍。

英文原文：Export Choice (EC) ([Zhou et al. 2022](https://arxiv.org/abs/2202.09368)) routing instead enables each expert to select the top-`k` tokens. In this way, each expert naturally guarantees a fixed capacity and each token may be routed to multiple experts. EC can achieve perfect load balancing and is shown to improve training convergence by 2x.

给定 $e$ 个专家和一个输入矩阵 $X \in \mathbb{R}^{n \times d}$，token 到专家的亲和度分数通过以下方式计算：


$$
S = \text{softmax}(X \cdot W_g), \text{where } W_g \in \mathbb{R}^{d \times e}, S \in \mathbb{R}^{n \times e}
$$



> Given $e$ experts and an input matrix $X \in \mathbb{R}^{n \times d}$, the token-to-expert affinity scores are computed by:
>
>
> $$
> S = \text{softmax}(X \cdot W_g), \text{where } W_g \in \mathbb{R}^{d \times e}, S \in \mathbb{R}^{n \times e}
> $$
>

token 到专家的分配由三个矩阵表示，$I, G \in \mathbb{R}^{e\times k}$和$P \in \mathbb{R}^{e \times k \times n}$。$I[i,j]$标注了哪个 token 是第$j$次被第$i$个专家选中。门控矩阵$G$存储了被选中 token 的路由权重。$P$是$I$的 one-hot 版本，用于为门控 FFN 层生成输入矩阵（$P \cdot X \in \mathbb{R}^{e \times k \times d}$）。


$$
G, I = \text{top-k}(S^\top, k)\quad P = \text{one-hot}(I)
$$



> A token-to-expert assignment is represented by three matrices, $I, G \in \mathbb{R}^{e\times k}$ and $P \in \mathbb{R}^{e \times k \times n}$. $I[i,j]$ annotates which token is the $j$ -th selection by the $i$ -th expert. The gating matrix $G$ stores the routing weights of selected tokens. $P$ is the one-hot version of $I$, used to produce the input matrix ($P \cdot X \in \mathbb{R}^{e \times k \times d}$) for the gated FFN layer.
>
>
> $$
> G, I = \text{top-k}(S^\top, k)\quad P = \text{one-hot}(I)
> $$
>

专家选择路由探索的一种正则化方法是限制每个 token 的最大专家数量。

> One regularization that export choice routing explored is to limit the maximum number of experts per token.

$$
\begin{aligned}
& \max_A \langle S^\top, A\rangle + \lambda H(A) \\
\text{s.t.} & 
\forall i: \sum_{j'} A[i, j'] = k,\quad
\forall j: \sum_{i'} A[i', j] \leq b,\quad
\forall i,j: 0 \leq A[i,j] \leq 1
\end{aligned}
$$

其中 $A[i,j]$ 在 $A \in \mathbb{R}^{e \times n}$ 中标记第 $i$ 个专家是否选择了第 $j$ 个 token。解决这个问题并非易事。该论文使用了 [Dykstra 算法](https://projecteuclid.org/journals/annals-of-probability/volume-13/issue-3/An-Iterative-Procedure-for-Obtaining-I-Projections-onto-the-Intersection/10.1214/aop/1176992918.full)，该算法运行一系列多个迭代计算步骤。限制专家选择导致实验中微调性能略有下降。

> where each entry $A[i,j]$ in $A \in \mathbb{R}^{e \times n}$ marks whether the $i$ -the expert selects the $j$ -th token. Solving this is non-trivial. The paper used [Dykstra’s algorithm](https://projecteuclid.org/journals/annals-of-probability/volume-13/issue-3/An-Iterative-Procedure-for-Obtaining-I-Projections-onto-the-Intersection/10.1214/aop/1176992918.full) that runs a sequence of multiple iterative computation steps. Capped expert choice results in a slight decrease in the fine-tuning performance in the experiments.

参数 $k$ 由 $k=nc/e$ 决定，其中 $n$ 是一个批次中的令牌总数，$c$ 是一个容量因子，表示一个令牌使用的专家平均数量。该论文在大多数实验中使用了 $c=2$，但采用 $c=1$ 的 EC 仍然优于 top-1 令牌选择门控。有趣的是，$c=0.5$ 对训练性能的损害微乎其微。

> The parameter $k$ is determined by $k=nc/e$, where $n$ is the total number of tokens in one batch and $c$ is a capacity factor indicating the average number of experts used by one token. The paper used $c=2$ in most experiments, but EC with $c=1$ still outperforms the top-1 token choice gating. Interestingly, $c=0.5$ only marginally hurts the training performance.

EC 的一个主要缺点是，当批次大小过小时它无法工作，对于自回归文本生成也一样，因为它需要知道未来的令牌才能进行 top-$k$ 选择。

> One big drawback of EC is that it does not work when the batch size is too small, neither for auto-regressive text generation, because it needs to know the future tokens to do the top-$k$ selection.

### 其他内存节省设计

> Other Memory Saving Designs

#### CPU 卸载

> CPU Offloading

当 GPU 内存已满时，一种选择是将暂时未用的数据卸载到 CPU，并在稍后需要时再读回（[Rhu et al. 2016](https://arxiv.org/abs/1602.08124)）。**CPU 卸载**的思想很简单，但由于它会减慢训练时间，近年来已不那么流行。

> When the GPU memory is full, one option is to offload temporarily unused data to CPU and read them back when needed later ([Rhu et al. 2016](https://arxiv.org/abs/1602.08124)). The idea of **CPU offloading** is straightforward but is less popular in recent years due to the slowdown it brings into the training time.

#### 激活重计算

> Activation Recomputation

**激活重计算**（也称为“激活检查点”或“梯度检查点”；[Chen et al. 2016](https://arvix.org/abs/1604.06174)）是一个巧妙而简单的想法，可以在牺牲计算时间的情况下减少内存占用。它将训练一个`\ell`层深度神经网络的内存成本降低到$O(\sqrt{\ell})$，这只会额外消耗每个批次的一次前向传播计算。

英文原文：Activation recomputation (also known as “activation checkpointing” or “gradient checkpointing”; [Chen et al. 2016](https://arvix.org/abs/1604.06174)) is a smart yet simple idea to reduce memory footprint at the cost of computation time. It reduces the memory cost of training a `\ell` layer deep neural net to 

$O(\sqrt{\ell})$, which only additionally consumes an extra forward pass computation per batch.

假设我们将一个$\ell$层网络平均分成$d$个分区。只有分区边界处的激活被保存并在工作节点之间通信。分区内部层的中间激活仍然需要用于计算梯度，因此它们在反向传播期间会被重新计算。通过激活重计算，训练$M(\ell)$的内存成本为：

> Let’s say, we evenly divide an $\ell$ -layer network into $d$ partitions. Only activations at partition boundaries are saved and communicated between workers. Intermediate activations at intra-partition layers are still needed for computing gradients so they are recomputed during backward passes. With activation recomputation, the memory cost for training $M(\ell)$ is:

$$
M(\ell) 
=\max_{i=1,\dots,k} \underbrace{\text{cost-of-one-partition}(i)}_\text{cost of back-propagation on the i-th partition} + \underbrace{O(d)}_\text{store intermediate outputs} 
= O(\frac{\ell}{d}) + O(d)
$$

最小成本为$O(\sqrt{\ell})$，在$d=\sqrt{\ell}$。

> The minimum cost is $O(\sqrt{\ell})$ at $d=\sqrt{\ell}$.

激活重计算技巧可以使内存成本相对于模型大小呈亚线性增长。

> Activation recompuation trick can give sublinear memory cost with respect to the model size.

![The memory cost of different memory saving algorithms. Sharing : Memory used by intermediate results is recycled when no longer needed. Inplace : Save the output directly into memory of an input value. (Image source: Chen et al. 2016 )](https://lilianweng.github.io/posts/2021-09-25-train-large/activation-checkpointing.png)

#### 混合精度训练

> Mixed Precision Training

[Narang & Micikevicius et al. (2018)](https://arxiv.org/abs/1710.03740) 引入了一种使用半精度浮点数（FP16）训练模型而不损失模型精度的方法。

> [Narang & Micikevicius et al. (2018)](https://arxiv.org/abs/1710.03740) introduced a method to train models using half-precision floating point (FP16) numbers without losing model accuracy.

![The procedure of mixed precision training at one layer. (Image source: Narang & Micikevicius, et al. 2018 )](https://lilianweng.github.io/posts/2021-09-25-train-large/mixed-precision-training.png)

避免在半精度下丢失关键信息的三种技术：

> Three techniques to avoid losing critical information at half-precision:

• *权重的全精度主副本*。维护一个全精度（FP32）的模型权重副本，用于累积梯度。在正向和反向传播中，这些数字被四舍五入到半精度。这样做的动机是，每个梯度更新（即梯度乘以学习率）可能太小，无法完全包含在 FP16 范围内（即$2^{-24}$在 FP16 中变为零）。

• *损失缩放*。放大损失以更好地处理小幅度的梯度（参见图 16）。放大梯度有助于将其移至可表示范围的右侧（包含较大值）占据更大的部分，从而保留否则会丢失的值。

• *算术精度*。对于常见的网络算术运算（例如向量点积、通过对向量元素求和进行归约），我们可以将部分结果累积在 FP32 中，然后在保存到内存之前将最终输出保存为 FP16。逐点操作可以在 FP16 或 FP32 中执行。

英文原文：

• *Full-precision master copy of weights*. Maintain a full precision (FP32) copy of model weights that accumulates gradients. The numbers are rounded up to half-precision for forward & backward passes. The motivation is that each gradient update (i.e. gradient times the learning rate) might be too small to be fully contained within the FP16 range (i.e. $2^{-24}$ becomes zero in FP16).

• *Loss scaling*. Scale up the loss to better handle gradients with small magnitudes (See Fig. 16). Scaling up the gradients helps shift them to occupy a larger section towards the right section (containing larger values) of the representable range, preserving values that are otherwise lost.

• *Arithmetic precision*. For common network arithmetic (e.g. vector dot-product, reduction by summing up vector elements), we can accumulate the partial results in FP32 and then save the final output as FP16 before saving into memory. Point-wise operations can be executed in either FP16 or FP32.

![The histogram of gradients in full precision. The left part up to $2^{-24}$ will be zero-ed off once the model switches to FP16. (Image source: Narang & Micikevicius, et al. 2018 )](https://lilianweng.github.io/posts/2021-09-25-train-large/gradient-histogram.png)

在他们的实验中，某些网络（例如图像分类、Faster R-CNN）不需要损失缩放，但对于其他网络（例如 Multibox SSD、大型 LSTM 语言模型）则是必需的。

> In their experiments, loss scaling is not needed for some networks (e.g. image classification, Faster R-CNN), but necessary for others (e.g. Multibox SSD, big LSTM language model).

#### 压缩

> Compression

中间结果通常会消耗大量内存，尽管它们只在一个前向传播和一个反向传播中需要。这两种使用之间存在明显的时序间隔。因此，[Jain 等人 (2018)](https://www.microsoft.com/en-us/research/uploads/prod/2018/04/fiddle-gist-isca18.pdf) 提出了一种数据编码策略，用于在第一次前向传播中使用后压缩中间结果，然后在反向传播时将其解码回来。

> Intermediate results often consume a lot of memory, although they are only needed in one forward pass and one backward pass. There is a noticeable temporal gap between these two uses. Thus [Jain et al. (2018)](https://www.microsoft.com/en-us/research/uploads/prod/2018/04/fiddle-gist-isca18.pdf) proposed a data encoding strategy to compress the intermediate results after the first use in the first pass and then decode it back for back-propagation later.

他们的系统 *Gist* 包含了两种编码方案: *层特定无损编码*; 侧重于 ReLU-Pool (“二值化”) 和 ReLU-Conv (“稀疏存储和密集计算”) 模式。 *激进有损编码*; 使用延迟精度降低 (DPR)。他们观察到，特征图的第一次即时使用应保持高精度，但第二次使用可以容忍较低精度。

> Their system *Gist* incorporates two encoding schemes:
> *Layer-specific lossless encoding*; focus on ReLU-Pool (“Binarize”) and ReLU-Conv (“Sparse storage and dense computation”) patterns.
> *Aggressive lossy encoding*; use delayed precision reduction (DPR). They observed that the first immediate use of feature maps should be kept at high precision but the second use can tolerate lower precision.

实验表明，Gist 可以在 5 个 SOTA 图像分类 DNN 中将内存成本降低 2 倍，平均降低 1.8 倍，而性能开销仅为 4%。

> The experiments showed that Gist can reduce the memory cost by 2x across 5 SOTA image classification DNNs, with an average of 1.8x with only 4% performance overhead.

#### 内存高效优化器

> Memory Efficient Optimizer

优化器对内存消耗非常渴望。以流行的 Adam 优化器为例，它内部需要维护动量和方差，两者都与梯度和模型参数处于相同的规模。突然之间，我们需要节省模型权重 4 倍的内存。

> Optimizers are eager for memory consumption. Take the popular Adam optimizer as an example, it internally needs to maintain momentums and variances, both at the same scale as gradients and model parameters. All out of a sudden, we need to save 4x the memory of model weights.

已经提出了几种优化器来减少内存占用。例如，*Adafactor* ([Shazeer et al. 2018](https://arxiv.org/abs/1804.04235)) 没有像 Adam 那样存储完整的动量和方差，而是只跟踪移动平均值的每行和每列总和，然后根据这些总和估计二阶矩。*SM3* ([Anil et al. 2019](https://arxiv.org/abs/1901.11150)) 描述了一种不同的自适应优化方法，也大大减少了内存。

> Several optimizers have been proposed to reduce the memory footprint.
> For example, instead of storing the full momentums and variations as in Adam, *Adafactor* ([Shazeer et al. 2018](https://arxiv.org/abs/1804.04235)) only tracks the per-row and per-column sums of the moving averages and then estimates the second moments based on these sums. *SM3* ([Anil et al. 2019](https://arxiv.org/abs/1901.11150)) describes a different adaptive optimization method, leading to largely reduced memory as well.

*ZeRO* (*Zero Redundancy Optimizer*; [Rajbhandari et al. 2019](https://arxiv.org/abs/1910.02054)) 基于对大型模型训练中两大内存消耗的观察，优化了用于训练大型模型的内存：

> *ZeRO* (*Zero Redundancy Optimizer*; [Rajbhandari et al. 2019](https://arxiv.org/abs/1910.02054)) optimizes the memory used for training large models based on the observation about two major memory consumption of large model training:

1. 大部分内存被*模型状态*占用，包括优化器状态（例如 Adam 动量和方差）、梯度和参数。混合精度训练需要大量内存，因为优化器除了 FP16 版本外，还需要保留一份 FP32 参数和其他优化器状态的副本。
2. 剩余部分被激活、临时缓冲区和不可用的碎片内存（在论文中称为*残余状态*）消耗。

> • The majority is occupied by *model states*, including optimizer states (e.g. Adam momentums and variances), gradients and parameters. Mixed-precision training demands a lot of memory since the optimizer needs to keep a copy of FP32 parameters and other optimizer states, besides the FP16 version.
> • The remaining is consumed by activations, temporary buffers and unusable fragmented memory (named *residual states* in the paper).

ZeRO 结合了两种方法：*ZeRO-DP* 和 *ZeRO-R*。ZeRO-DP 是一种增强的数据并行性，旨在避免模型状态上的简单冗余。它通过动态通信调度将优化器状态、梯度和参数划分到多个数据并行进程中，以最小化通信量。ZeRO-R 通过使用分区激活重计算、恒定缓冲区大小和即时内存碎片整理来优化残余状态的内存消耗。

> ZeRO combines two approaches, *ZeRO-DP* and *ZeRO-R*.
> ZeRO-DP is an enhanced data parallelism to avoid simple redundancy over model states. It partitions optimizer state, gradients and parameters across multiple data parallel processes via a dynamic communication schedule to minimize the communication volume.
> ZeRO-R optimizes the memory consumption of residual states, using partitioned activation recomputation, constant buffer size and on-the-fly memory defragmentation.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Sep 2021). How to train really large models on many GPUs? Lil’Log. https://lilianweng.github.io/posts/2021-09-25-train-large/.

> Weng, Lilian. (Sep 2021). How to train really large models on many GPUs? Lil’Log. https://lilianweng.github.io/posts/2021-09-25-train-large/.

或

> Or

```
@article{weng2021large,
  title   = "How to Train Really Large Models on Many GPUs?",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2021",
  month   = "Sep",
  url     = "https://lilianweng.github.io/posts/2021-09-25-train-large/"
}
```

### 参考文献

> References

[1] Li et al. [“PyTorch 分布式：加速数据并行训练的经验”](https://arxiv.org/abs/2006.15704) VLDB 2020.

> [1] Li et al. [“PyTorch Distributed: Experiences on Accelerating Data Parallel Training”](https://arxiv.org/abs/2006.15704) VLDB 2020.

[2] Cui et al. [“GeePS：使用 GPU 专用参数服务器在分布式 GPU 上进行可扩展深度学习”](https://www.pdl.cmu.edu/PDL-FTP/CloudComputing/GeePS-cui-eurosys16.pdf) EuroSys 2016

> [2] Cui et al. [“GeePS: Scalable deep learning on distributed GPUs with a GPU-specialized parameter server”](https://www.pdl.cmu.edu/PDL-FTP/CloudComputing/GeePS-cui-eurosys16.pdf) EuroSys 2016

[3] Shoeybi et al. [“Megatron-LM：使用模型并行训练数十亿参数语言模型。”](https://arxiv.org/abs/1909.08053) arXiv preprint arXiv:1909.08053 (2019).

> [3] Shoeybi et al. [“Megatron-LM: Training Multi-Billion Parameter Language Models Using Model Parallelism.”](https://arxiv.org/abs/1909.08053) arXiv preprint arXiv:1909.08053 (2019).

[4] Narayanan et al. [“使用 Megatron-LM 在 GPU 集群上高效训练大规模语言模型。”](https://arxiv.org/abs/2104.04473) arXiv preprint arXiv:2104.04473 (2021).

> [4] Narayanan et al. [“Efficient Large-Scale Language Model Training on GPU Clusters Using Megatron-LM.”](https://arxiv.org/abs/2104.04473) arXiv preprint arXiv:2104.04473 (2021).

[5] Huang et al. [“GPipe：使用流水线并行高效训练巨型神经网络。”](https://arxiv.org/abs/1811.06965) arXiv preprint arXiv:1811.06965 (2018).

> [5] Huang et al. [“GPipe: Efficient Training of Giant Neural Networks using Pipeline Parallelism.”](https://arxiv.org/abs/1811.06965) arXiv preprint arXiv:1811.06965 (2018).

[6] Narayanan et al. [“PipeDream：用于 DNN 训练的广义流水线并行。”](https://cs.stanford.edu/~matei/papers/2019/sosp_pipedream.pdf) SOSP 2019.

> [6] Narayanan et al. [“PipeDream: Generalized Pipeline Parallelism for DNN Training.”](https://cs.stanford.edu/~matei/papers/2019/sosp_pipedream.pdf) SOSP 2019.

[7] Narayanan et al.  [“内存高效的流水线并行 DNN 训练。”](https://arxiv.org/abs/2006.09503) ICML 2021.

> [7] Narayanan et al.  [“Memory-Efficient Pipeline-Parallel DNN Training.”](https://arxiv.org/abs/2006.09503) ICML 2021.

[8] Shazeer et al. [“稀疏门控专家混合层 Noam。”](https://arxiv.org/abs/1701.06538) arXiv preprint arXiv:1701.06538 (2017).

> [8] Shazeer et al. [“The Sparsely-Gated Mixture-of-Experts Layer Noam.”](https://arxiv.org/abs/1701.06538) arXiv preprint arXiv:1701.06538 (2017).

[9] Lepikhin et al. [“GShard：通过条件计算和自动分片扩展巨型模型。”](https://arxiv.org/abs/2006.16668) arXiv preprint arXiv:2006.16668 (2020).

> [9] Lepikhin et al. [“GShard: Scaling Giant Models with Conditional Computation and Automatic Sharding.”](https://arxiv.org/abs/2006.16668) arXiv preprint arXiv:2006.16668 (2020).

[10] Fedus et al. [“Switch Transformers：通过简单高效的稀疏性扩展到万亿参数模型。”](https://arxiv.org/abs/2101.03961) arXiv preprint arXiv:2101.03961 (2021).

> [10] Fedus et al. [“Switch Transformers: Scaling to Trillion Parameter Models with Simple and Efficient Sparsity.”](https://arxiv.org/abs/2101.03961) arXiv preprint arXiv:2101.03961 (2021).

[11] Narang & Micikevicius, et al.  [“混合精度训练。”](https://arxiv.org/abs/1710.03740) ICLR 2018.

> [11] Narang & Micikevicius, et al.  [“Mixed precision training.”](https://arxiv.org/abs/1710.03740) ICLR 2018.

[12] Chen et al. 2016 [“以亚线性内存成本训练深度网络。”](https://arxiv.org/abs/1604.06174) arXiv preprint arXiv:1604.06174 (2016).

> [12] Chen et al. 2016 [“Training Deep Nets with Sublinear Memory Cost.”](https://arxiv.org/abs/1604.06174) arXiv preprint arXiv:1604.06174 (2016).

[13] Jain et al. [“Gist：用于深度神经网络训练的高效数据编码。”](https://www.microsoft.com/en-us/research/uploads/prod/2018/04/fiddle-gist-isca18.pdf) ISCA 2018.

> [13] Jain et al. [“Gist: Efficient data encoding for deep neural network training.”](https://www.microsoft.com/en-us/research/uploads/prod/2018/04/fiddle-gist-isca18.pdf) ISCA 2018.

[14] Shazeer & Stern. [“Adafactor：具有亚线性内存成本的自适应学习率。”](https://arxiv.org/abs/1804.04235) arXiv preprint arXiv:1804.04235 (2018).

> [14] Shazeer & Stern. [“Adafactor: Adaptive learning rates with sublinear memory cost.”](https://arxiv.org/abs/1804.04235) arXiv preprint arXiv:1804.04235 (2018).

[15] Anil et al. [“内存高效的自适应优化。”](https://arxiv.org/abs/1901.11150) arXiv preprint arXiv:1901.11150 (2019).

> [15] Anil et al. [“Memory-Efficient Adaptive Optimization.”](https://arxiv.org/abs/1901.11150) arXiv preprint arXiv:1901.11150 (2019).

[16] Rajbhandari et al. [“ZeRO：面向训练万亿参数模型 Samyam 的内存优化。”](https://arxiv.org/abs/1910.02054) arXiv preprint arXiv:1910.02054 (2019).

> [16] Rajbhandari et al. [“ZeRO: Memory Optimization Towards Training A Trillion Parameter Models Samyam.”](https://arxiv.org/abs/1910.02054) arXiv preprint arXiv:1910.02054 (2019).

[17] Zhou et al. [“带有专家选择路由的专家混合模型”](https://arxiv.org/abs/2202.09368) arXiv preprint arXiv:2202.09368 (2022).

> [17] Zhou et al. [“Mixture-of-Experts with Expert Choice Routing”](https://arxiv.org/abs/2202.09368) arXiv preprint arXiv:2202.09368 (2022).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| GPU memory | GPU 内存 | 图形处理器上的显存，用于存储模型、数据和中间计算结果。 |
| Parallelism | 并行性 | 在多个计算设备上同时执行任务以加速训练过程。 |
| Data Parallelism (DP) | 数据并行 | 将相同模型复制到多个工作器，每个工作器处理一部分数据并同步梯度或权重。 |
| Model Parallelism (MP) | 模型并行 | 将模型参数划分到多个设备上，每个设备负责模型的一部分进行训练。 |
| Pipeline Parallelism (PP) | 流水线并行 | 结合模型并行和数据并行，通过将迷你批次拆分为微批次来减少计算等待时间。 |
| Tensor Parallelism (TP) | 张量并行 | 将单个张量操作的计算水平划分到多个设备上，以并行处理。 |
| Mixture-of-Experts (MoE) | 专家混合 | 一种模型架构，通过门控机制将输入路由到少数选定的专家网络以实现大规模扩展。 |
| Activation Recomputation | 激活重计算 | 在反向传播期间重新计算中间激活值，以减少内存占用，也称激活检查点。 |
| Mixed-precision Training | 混合精度训练 | 结合使用半精度浮点数（FP16）和全精度浮点数（FP32）来训练模型，以提高效率和减少内存。 |
| Optimizer State | 优化器状态 | 优化器（如Adam）内部维护的动量、方差等状态信息，与模型参数规模相同。 |
| ZeRO (Zero Redundancy Optimizer) | 零冗余优化器 | 一种内存优化器，通过分区优化器状态、梯度和参数来减少大型模型训练的内存消耗。 |
| Gradient Accumulation | 梯度累积 | 在多次迭代中累积梯度，然后进行一次参数更新，以模拟使用更大的批次大小进行训练。 |
| Weight Stashing | 权重暂存 | 在流水线并行中，每个工作器跟踪多个模型版本，确保前向和后向传播使用相同版本的权重。 |
| Gating Mechanism | 门控机制 | 在专家混合模型中，控制网络的哪个子集（专家）被激活以产生输出的机制。 |
| Expert Choice (EC) | 专家选择 | 一种MoE路由机制，允许每个专家选择前k个token进行处理，以实现负载均衡。 |
