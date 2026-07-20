# 大型Transformer模型推理优化

> Large Transformer Model Inference Optimization

> 来源：Lil'Log / Lilian Weng，2023-01-10
> 原文链接：https://lilianweng.github.io/posts/2023-01-10-inference-optimization/
> 分类：AI / Transformer推理优化

## 核心要点

- 大型Transformer模型因其巨大的内存占用和自回归推理的低并行性，导致推理成本高昂。
- Transformer模型推理优化的目标是减少内存占用、计算复杂度（FLOPs）和推理延迟。
- 推理优化方法包括并行技术、内存卸载、智能批处理、网络压缩（剪枝、量化、蒸馏）和架构改进。
- 知识蒸馏通过将大型教师模型的知识转移给小型学生模型来加速推理，如DistilBERT。
- 量化通过降低模型权重和激活的精度来减少内存和加速计算，分为训练后量化和量化感知训练。
- Transformer模型量化面临激活高动态范围和离群值挑战，可通过混合精度量化、细粒度量化和异常值平滑等方法解决。
- 剪枝通过移除不重要的权重或连接来减小模型大小，结构化剪枝（如N:M稀疏性）与硬件优化结合可实现推理加速。
- 稀疏性通过稀疏化密集层或整合专家混合（MoE）架构来扩展模型容量并提高推理效率。
- MoE模型通过路由网络为每个输入token分配部分专家，路由策略（如批优先级路由、任务级MoE）和内核改进可进一步优化其性能。
- 架构优化通过稀疏注意力模式、循环机制、内存节省设计和自适应注意力等方式，解决自注意力机制的二次复杂度瓶颈。

## 正文

2023-01-24更新：新增关于[蒸馏](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#distillation)的小节。  


> [Updated on 2023-01-24: add a small section on [Distillation](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#distillation).]  

大型Transformer模型如今已成为主流，在各种任务中都取得了最先进（SoTA）的结果。它们功能强大，但训练和使用成本非常高昂。极高的推理成本，无论是在时间还是内存方面，都是大规模采用强大Transformer模型解决实际任务的一大瓶颈。

> Large transformer models are mainstream nowadays, creating SoTA results for a variety of tasks. They are powerful but very expensive to train and use. The extremely high inference cost, in both time and memory, is a big bottleneck for adopting a powerful transformer for solving real-world tasks at scale.

**为什么大型Transformer模型难以进行推理？**除了SoTA模型规模不断增大之外，还有两个主要因素导致了推理挑战（[Pope et al. 2022](https://arxiv.org/abs/2211.05102)）：

> **Why is it hard to run inference for large transformer models?** Besides the increasing size of SoTA models, there are two main factors contributing to the inference challenge ([Pope et al. 2022](https://arxiv.org/abs/2211.05102)):

1. *巨大的内存占用*。在推理时，模型参数和中间状态都需要存储在内存中。例如，
   - KV缓存应在解码期间存储在内存中；例如，对于批处理大小为512、上下文长度为2048的情况，KV缓存总量为3TB，是模型大小的3倍（！）。
   - 注意力机制的推理成本与输入序列长度呈二次方关系。
2. *低并行性。*推理生成以自回归方式执行，使得解码过程难以并行。

> • *Large memory footprint*. Both model parameters and intermediate states are needed in memory at inference time. For example,
>

> ◦ The KV cache should be stored in memory during decoding time; E.g. For a batch size of 512 and context length of 2048, the KV cache totals 3TB, that is 3x the model size (!).

> ◦ Inference cost from the attention mechanism scales quadratically with input sequence length.

> • *Low parallelizability.* Inference generation is executed in an autoregressive fashion, making the decoding process hard to parallel.

在这篇文章中，我们将探讨几种提高Transformer推理效率的方法。其中一些是通用的网络压缩方法，而另一些则特定于Transformer架构。

> In this post, we will look into several approaches for making transformer inference more efficient. Some are general network compression methods, while others are specific to transformer architecture.

### 方法概述

> Methods Overview

我们通常将以下几点视为模型推理优化的目标：

> We in general consider the following as goals for model inference optimization:

- 通过使用更少的GPU设备和更少的GPU内存来减少模型的内存占用；
- 通过降低所需的FLOPs数量来减少所需的计算复杂度；
- 减少推理延迟，使运行速度更快。

> • Reduce the memory footprint of the model by using fewer GPU devices and less GPU memory;
> • Reduce the desired computation complexity by lowering the number of FLOPs needed;
> • Reduce the inference latency and make things run faster.

有几种方法可以降低推理的内存成本和/或加快推理时间。

> Several methods can be used to make inference cheaper in memory or/and faster in time.

1. 应用各种*并行*技术，将模型扩展到大量GPU上。模型组件和数据的智能并行使得运行具有数万亿参数的模型成为可能。
2. 内存*卸载*，将暂时未用的数据卸载到CPU，并在稍后需要时再读回。这有助于内存使用，但会导致更高的延迟。
3. 智能批处理策略；例如，[EffectiveTransformer](https://github.com/bytedance/effective_transformer) 将连续序列打包在一起，以消除一个批次内的填充。
4. 网络*压缩*技术，例如*剪枝、量化、蒸馏*。在参数数量或位宽方面尺寸更小的模型，应该需要更少的内存并运行更快。
5. 针对目标模型架构的改进。许多*架构更改*，特别是针对注意力层的更改，有助于提高 Transformer 的解码速度。

> • Apply various *parallelism* to scale up the model across a large number of GPUs. Smart parallelism of model components and data makes it possible to run a model of trillions of parameters.
> • Memory *offloading* to offload temporarily unused data to the CPU and read them back when needed later. This helps with memory usage but causes higher latency.
> • Smart batching strategy; E.g. [EffectiveTransformer](https://github.com/bytedance/effective_transformer) packs consecutive sequences together to remove padding within one batch.
> • Network *compression* techniques, such as *pruning, quantization, distillation*. A model of smaller size, in terms of parameter count or bitwidth, should demand less memory and run faster.
> • Improvement specific to a target model architecture. Many *architectural changes*, especially those for attention layers, help with transformer decoding speed.

查看[关于大型模型训练的上一篇文章](https://lilianweng.github.io/posts/2021-09-25-train-large/)，其中介绍了不同类型的训练并行化和内存节省设计，包括CPU内存卸载。本文重点介绍网络压缩技术和针对Transformer模型的架构特定改进。

> Check [the previous post on large model training](https://lilianweng.github.io/posts/2021-09-25-train-large/) on different types of training parallelism and memory saving designs including CPU memory offloading. This post focuses on network compression techniques and architecture-specific improvement for transformer models.

### 蒸馏

> Distillation

**知识蒸馏** (**KD**; [Hinton et al. 2015](https://arxiv.org/abs/1503.02531), [Gou et al. 2020](https://arxiv.org/abs/2006.05525)) 是一种构建更小、更廉价模型（*“学生模型”*）的直接方法，通过将预训练的昂贵模型（*“教师模型”*）的技能转移给学生模型来加速推理。除了为了构建适当的学习目标而需要与教师模型具有匹配的输出空间外，对学生模型的架构如何构建没有太多限制。

> **Knowledge Distillation** (**KD**; [Hinton et al. 2015](https://arxiv.org/abs/1503.02531), [Gou et al. 2020](https://arxiv.org/abs/2006.05525)) is a straightforward way to build a smaller, cheaper model (*“student model”*) to speed up inference by transferring skills from a pre-trained expensive model (*“teacher model”*) into the student. There is no much restriction on how the student architecture should be constructed, except for a matched output space with the teacher in order to construct a proper learning objective.

![The generic framework of teacher-student knowledge distillation training. (Image source: Gou et al. 2020 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/distillation.png)

给定一个数据集，学生模型通过蒸馏损失训练来模仿教师模型的输出。通常，神经网络有一个softmax层；例如，大型语言模型（LLM）输出一个关于token的概率分布。让我们将softmax之前的logits层分别表示为教师模型和学生模型的$\mathbf{z}_t$和$\mathbf{z}_s$。*蒸馏损失*通过高温度$T$最小化两个softmax输出之间的差异。当已知真实标签$\mathbf{y}$时，我们可以将其与一个*监督*学习目标结合起来，该目标使用例如交叉熵来衡量真实标签与学生模型的软logits之间的差异。

> Given a dataset, a student model is trained to mimic outputs of a teacher via distillation loss. Usually a neural network has a softmax layer; For example, a LLM outputs a probability distribution over tokens. Let’s denote the logits layer right before softmax as $\mathbf{z}_t$ and $\mathbf{z}_s$ for teacher and student models, respectively. The *distillation loss* minimizes the difference between two softmax outputs with a high temperature $T$. When ground truth labels $\mathbf{y}$ are known, we can combine it with a *supervised* learning objective between ground truth and the student’s soft logits using e.g. cross-entropy.

$$
\mathcal{L}_\text{KD} = \mathcal{L}_\text{distll}(\text{softmax}(\mathbf{z}_t, T), \text{softmax}(\mathbf{z}_s, T)) + \lambda\mathcal{L}_\text{CE}(\mathbf{y}, \mathbf{z}_s)
$$

其中$\lambda$是一个超参数，用于平衡软学习目标和硬学习目标。$\mathcal{L}_\text{distll}$的常见选择是KL散度/交叉熵。

> where $\lambda$ is a hyperparameter to balance between soft and hard learning objectives. A common choice for $\mathcal{L}_\text{distll}$ is KL divergence / cross entropy.

一个成功的早期尝试是**DistilBERT**（[Sanh et al. 2019](https://arxiv.org/abs/1910.01108)），它能够将BERT的参数减少40%，同时在微调的下游任务上保持BERT 97%的性能，并且运行速度快71%。DistilBERT预训练的损失是软蒸馏损失、监督训练损失（即BERT情况下的[掩码语言建模损失](https://lilianweng.github.io/posts/2019-01-31-lm/#MLM)$\mathcal{L}_\text{MLM}$）以及一种特殊的*余弦嵌入损失*的组合，用于对齐教师和学生模型之间的隐藏状态向量。

英文原文：A successful early trial is DistilBERT ([Sanh et al. 2019](https://arxiv.org/abs/1910.01108)) that is able to reduce the parameters of a BERT by 40% while maintaining 97% performance of BERT on fine-tuned downstream tasks and running 71% faster. The loss of pre-training DistilBERT is a combination of soft distillation loss, supervised training loss (i.e. [Masked language modeling loss](https://lilianweng.github.io/posts/2019-01-31-lm/#MLM) 

$\mathcal{L}_\text{MLM}$ in the case of BERT) and a special *cosine embedding loss* to align the hidden state vectors between teacher and student.

蒸馏可以很容易地与[量化](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#quantization)、[剪枝](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#pruning)或[稀疏化](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#sparsity)技术结合，其中教师模型是原始的全精度、密集模型，而学生模型则被量化、剪枝或修剪以具有更高的稀疏度。

> Distillation can be easily combined with [quantization](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#quantization), [pruning](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#pruning) or [sparsification](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#sparsity) techniques, where the teacher model is the original full-precision, dense model and the student is quantized, pruned, or trimmed to have higher sparsity level.

### 量化

> Quantization

在深度神经网络上应用量化有两种常见方法：

> There are two common approaches for applying quantization on a deep neural network:

1. *训练后量化 (PTQ)*：模型首先训练至收敛，然后我们将其权重转换为较低精度，无需额外训练。与训练相比，它通常实现成本较低。
2. *量化感知训练 (QAT)*：量化在预训练或进一步微调期间应用。QAT能够获得更好的性能，但需要额外的计算资源和对代表性训练数据的访问。

> • *Post-Training Quantization (PTQ)*: A model is first trained to convergence and then we convert its weights to lower precision without more training. It is usually quite cheap to implement, in comparison to training.
> • *Quantization-Aware Training (QAT)*: Quantization is applied during pre-training or further fine-tuning. QAT is able to attain better performance but requires extra computation resources and access to representative training data.

我们应该注意理论最优量化策略与硬件内核支持之间的差距。由于GPU内核缺乏对某些类型矩阵乘法（例如INT4 x FP16）的支持，并非所有以下方法都能在实际推理中带来加速。

> We should be aware of the gap between theoretical optimal quantization strategy and the hardware kernel support. Due to the lack of GPU kernel support for certain types of matrix multiplication (e.g. INT4 x FP16), not all the methods below result in speedup for the actual inference.

#### Transformer 量化的挑战

> Challenges for Transformer Quantization

许多关于Transformer模型量化的研究都有相同的观察结果：简单的低精度（例如8位）训练后量化会导致显著的性能下降，这主要是由于激活的高动态范围，以及朴素的激活量化策略未能保持模型容量。

> Many studies on Transformer model quantization have the same observation: A simple low-precision (e.g. 8-bit) post-training quantization leads to significant performance drop mainly due to the high dynamic ranges of activation and a naive activation quantization strategy fails to maintain the capacity.

![Only quantizing model weights to 8-bit while keeping activation at full precision (`W8A32`) achieves much better results when activations are quantized to 8-bit irrespective of whether weights are in lower precision (`W8A8` and `W32A8`). (Image source: Bondarenko et al. 2021 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/quantization-experiment-table.png)

[Bondarenko et al. (2021)](https://arxiv.org/abs/2109.12948)在一个小型BERT模型中观察到，由于输出张量中存在强离群值，FFN的输入和输出具有非常不同的动态范围。因此，对FFN的残差和进行逐张量量化很可能导致显著误差。

> [Bondarenko et al. (2021)](https://arxiv.org/abs/2109.12948) observed in a small BERT model that FFN’s input and output have very different dynamic ranges due to strong outliers in the output tensor. Therefore per-tensor quantization for the FFN’s residual sum is likely to cause a notable error.

随着模型规模持续增长到数十亿参数，高幅度的离群特征开始出现在*所有*Transformer层中，导致简单的低位量化失败。[Dettmers et al. (2022)](https://arxiv.org/abs/2208.07339)观察到，对于大于6.7B参数的[OPT](https://arxiv.org/abs/2205.01068)模型存在这种现象。更大的模型具有更多包含极端离群值的层，并且这些离群特征对模型性能有显著影响。少数维度中激活离群值的规模可能比大多数其他值大大约100倍。

> As the model size continues to grow to billions of parameters, outlier features of high magnitude start to emerge in *all* transformer layers, causing failure of simple low-bit quantization. [Dettmers et al. (2022)](https://arxiv.org/abs/2208.07339) observed such a phenomenon for [OPT](https://arxiv.org/abs/2205.01068) models larger than 6.7B parameters. Larger models have more layers with extreme outliers and these outlier features have a significant impact on the model performance. The scale of activation outliers in a few dimensions can be ~100× larger than most of the other values.

![The mean zero-shot accuracy over a set of language tasks (WinoGrande, HellaSwag, PIQA, LAMBADA) of OPT models of increasing sizes. (Image source: Dettmers et al. 2022 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/OPT-models-outlier.png)

#### 训练后量化 (PTQ)

> Post-training quantization (PTQ)

##### 混合精度量化

> Mixed-precision quantization

解决上述量化挑战最直接的方法是为权重和激活实现不同精度的量化。

> The most straightforward approach for resolving the above quantization challenge is to implement quantization at different precision for weights vs activation.

GOBO（[Zadeh et al. 2020](https://arxiv.org/abs/2005.03842)）是首批在Transformer（即小型BERT模型）上应用训练后量化的模型之一。它假设每层的模型权重遵循高斯分布，因此通过跟踪每层的均值和标准差来检测离群值。离群特征保持原始形式，而其他值则被分成多个bin，并且只存储相应的权重bin索引和质心值。

> GOBO ([Zadeh et al. 2020](https://arxiv.org/abs/2005.03842)) is one of the first models to apply post-training quantization on transformers (i.e. a small BERT model). It assumes that model weights of each layer follow a Gaussian distribution and therefore detects outliers by tracking mean and standard deviation per layer. Outlier features remain in original form, while other values are split into multiple bins and only corresponding bin indices of weights and the centroid values are stored.

基于BERT中只有某些激活层（例如FFN后的残差连接）会导致性能大幅下降的观察，[Bondarenko et al. (2021)](https://arxiv.org/abs/2109.12948)采用了混合精度量化，对有问题的激活使用16位量化，而对其他激活使用8位量化。

> Based on the observation that only certain activation layers (e.g. residual connections after FFN) in BERT cause big performance drop, [Bondarenko et al. (2021)](https://arxiv.org/abs/2109.12948) adopted mixed-precision quantization by using 16-bit quantization on problematic activations but 8-bit on others.

`LLM.int8()`中的混合精度量化（[Dettmers et al. 2022](https://arxiv.org/abs/2208.07339)）通过两种混合精度分解实现：

> Mixed-precision quantization in `LLM.int8()` ([Dettmers et al. 2022](https://arxiv.org/abs/2208.07339)) is implemented via two mixed-precision decompositions:

1. 由于矩阵乘法包含一组行向量和列向量之间的独立内积，我们可以对每个内积施加独立的量化：每行和每列都通过绝对最大值进行缩放，然后量化为INT8。
2. 离群激活特征（例如比其他维度大20倍）保留在FP16中，但它们仅占总权重的一小部分。如何识别离群值是经验性的。

> • Because matrix multiplication contains a set of independent inner products between row and column vectors, we can impose independent quantization per inner product: Each row and column are scaled by the absolution maximum values and then quantized to INT8.
> • Outlier activation features (e.g. 20x larger than other dimensions) remain in FP16 but they represent only a tiny fraction of total weights. How to identify outliers is empirical.

![Two mixed-precision decompositions of `LLM.int8()`. (Image source: Dettmers et al. 2022 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/LLM-int8.png)

##### 细粒度量化

> Quantization at fine-grained granularity

![Comparison of quantization at different granularity. $d$ is the model size / hidden state dimension and $h$ is the number of heads in one MHSA (multi-head self-attention) component.](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/quantization-granularity.png)

天真地将一层中的整个权重矩阵进行量化（“逐张量”或“逐层”量化）最容易实现，但不会带来良好的量化粒度。

> Naively quantizing the entire weight matrix in one layer (“per-tensor” or “per-layer” quantization) is easiest to implement but does not lead to good granularity of quantization.

**Q-BERT**（[Shen, Dong & Ye, et al. 2020](https://arxiv.org/abs/1909.05840)）对微调的BERT模型应用了*组式量化*，将MHSA（多头自注意力）中*每个头*对应的单个矩阵`W`视为一个组，然后应用基于Hessian的混合精度量化。

英文原文：Q-BERT ([Shen, Dong & Ye, et al. 2020](https://arxiv.org/abs/1909.05840)) applied *group-wise quantization* to a fine-tuned BERT model, treating an individual matrix `W` with respect to *each head* in MHSA (multi-head self-attention) as one group and then applies Hessian based mixed precision quantization.

*逐嵌入组（PEG）*激活量化的动机是观察到异常值仅出现在$d$（隐藏状态/模型大小）维度中的少数几个维度中（[Bondarenko et al. 2021](https://arxiv.org/abs/2109.12948)）。逐嵌入量化计算成本相当高。相比之下，PEG 量化将激活张量沿嵌入维度分成几个大小均匀的组，同一组中的元素共享量化参数。为了确保所有异常值都分组在一起，他们应用了一种基于范围的确定性嵌入维度置换，其中维度按其值范围排序。

> *Per-embedding group (PEG)* activation quantization was motivated by the observation that outlier values only appear in a few out of $d$ (hidden state / model size) dimensions ([Bondarenko et al. 2021](https://arxiv.org/abs/2109.12948)). Per-embedding is pretty computationally expensive. In comparison, PEG quantization splits the activation tensor into several evenly sized groups along the embedding dimension where elements in the same group share quantization parameters. To ensure all outliers are grouped together, they apply a deterministic range-based permutation of embedding dimensions, where dimensions are sorted by their value ranges.

**ZeroQuant**（[Yao et al. 2022](https://arxiv.org/abs/2206.01861)）对权重使用*组式量化*，与 Q-BERT 中相同，并对激活使用*逐令牌量化*。为了避免昂贵的量化和反量化计算，ZeroQuant 构建了定制的*核*，以将量化操作与其前一个运算符*融合*。

> **ZeroQuant** ([Yao et al. 2022](https://arxiv.org/abs/2206.01861)) uses *group-wise quantization* for weights, same as in Q-BERT, and *token-wise quantization* for activation. To avoid expensive quantization and de-quantization computation, ZeroQuant built customized *kernel* to *fuse* quantization operation with its previous operator.

##### 量化的二阶信息

> Second order information for quantization

Q-BERT（[Shen, Dong & Ye, et al. 2020](https://arxiv.org/abs/1909.05840)）为其混合精度量化开发了 Hessian 感知量化（HAWQ）。其动机是具有更高 Hessian 谱（即，更大的顶部特征值）的参数对量化更敏感，因此需要更高的精度。这本质上是一种识别异常值的方法。

> Q-BERT ([Shen, Dong & Ye, et al. 2020](https://arxiv.org/abs/1909.05840)) developed Hessian AWare Quantization (HAWQ) for its mixed-precision quantization. The motivation is that parameters with higher Hessian spectrum (i.e., larger top eigenvalues) are more sensitive to quantization and thus require higher precision. It is essentially a way to identify outliers.

从另一个角度来看，量化问题是一个优化问题。给定一个权重矩阵$\mathbf{W}$和一个输入矩阵$\mathbf{X}$，我们希望找到一个量化权重矩阵$\hat{\mathbf{W}}$来最小化均方误差（MSE）：

> In another viewpoint, the problem of quantization is an optimization problem. Given a weight matrix $\mathbf{W}$ and an input matrix $\mathbf{X}$ , we want to find a quantized weight matrix $\hat{\mathbf{W}}$ to minimize the MSE:

$$
\hat{\mathbf{W}}^* = {\arg\min}_{\hat{\mathbf{W}}} | \mathbf{W}\mathbf{X} - \hat{\mathbf{W}}\mathbf{X}|
$$

**GPTQ**（[Frantar et al. 2022](https://arxiv.org/abs/2210.17323)）将权重矩阵$\mathbf{W}$视为行向量${\mathbf{w}}$的集合，并独立地对每一行应用量化。GPTQ 迭代地量化更多权重，这些权重是贪婪选择的，以最小化量化误差。对选定权重的更新具有闭式公式，利用了 Hessian 矩阵。如果感兴趣，请阅读论文和 OBQ（Optimal Brain Quantization；[Frantar & Alistarh 2022](https://arxiv.org/abs/2208.11580)）方法的更多细节。GPTQ 可以将 OPT-175B 中权重的位宽降低到 3 或 4 位，而不会造成太多性能损失，但它只适用于模型权重而非激活。

英文原文：GPTQ ([Frantar et al. 2022](https://arxiv.org/abs/2210.17323)) treats the weight matrix 

$\mathbf{W}$ as a collection of row vectors 

${\mathbf{w}}$ and applies quantization to each row independently. GPTQ iteratively quantizes more weights that are selected greedily to minimize the quantization error. The update on selected weights has a closed-form formula, utilizing Hessian matrices. Read more details in the paper and the OBQ (Optimal Brain Quantization; [Frantar & Alistarh 2022](https://arxiv.org/abs/2208.11580)) method if interested. GPTQ can reduce the bitwidth of weights in OPT-175B down to 3 or 4 bits without much performance loss, but it only applies to model weights not activation.

##### 异常值平滑

> Outlier smoothing

众所周知，在 Transformer 模型中，激活比权重更难量化。**SmoothQuant**（[Xiao & Lin 2022](https://arxiv.org/abs/2211.10438)）提出了一种智能解决方案，通过数学等效变换将激活中的异常特征平滑到权重，然后对权重和激活都进行量化（`W8A8`）。因此，SmoothQuant 比混合精度量化具有更好的硬件效率。

> It is known that activations are harder to quantize than weights in transformer models. **SmoothQuant** ([Xiao & Lin 2022](https://arxiv.org/abs/2211.10438)) proposed a smart solution to smooth outlier features from activations to weights via mathematically equivalent transformation and then enable quantization on both weights and activations (`W8A8`). Because of this, SmoothQuant has better hardware efficiency than mixed-precision quantization.

![SmoothQuant migrates the scale variance from activations to weights offline to reduce the difficulty of activation quantization. Both the resulting new weight and activation matrices are easy to quantize. (Image source: Xiao & Lin 2022 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/SmoothQuant.png)

考虑到逐通道平滑因子$\mathbf{s}$，SmoothQuant 根据以下方式缩放权重：

> Considering a per-channel smooth factor $\mathbf{s}$, SmoothQuant scales the weights according to:

$$
\mathbf{Y} = (\mathbf{X} \text{diag}(\mathbf{s})^{-1}) \cdot (\text{diag}(\mathbf{s})\mathbf{W}) = \hat{\mathbf{X}}\hat{\mathbf{W}}
$$

平滑因子可以轻松地离线融合到前一层的参数中。超参数$\alpha$控制着我们将量化难度从激活迁移到权重的程度：$\mathbf{s} = \max (\vert \mathbf{X}_j \vert)^\alpha / \max( \vert \mathbf{W}_j \vert )^{1-\alpha}$。该论文发现在实验中，$\alpha=0.5$是许多大型语言模型的最佳选择。对于激活中存在更显著异常值的模型，$\alpha$可以调整得更大。

> The smoothing factor can be easily fused into previous layers’ parameters offline. A hyperparameter $\alpha$ controls how much we migrate the quantization difficulty from activations to weights: $\mathbf{s} = \max (\vert \mathbf{X}_j \vert)^\alpha / \max( \vert \mathbf{W}_j \vert )^{1-\alpha}$. The paper found that $\alpha=0.5$ is a sweet spot for many LLMs in the experiments. For models with more significant outliers in activation, $\alpha$ can be adjusted to be larger.

#### 量化感知训练 (QAT)

> Quantization-aware training (QAT)

量化感知训练将量化操作融合到预训练或微调过程中。它直接学习低位表示的模型权重，以额外训练时间和计算为代价，带来更好的性能。

> Quantization-aware training fuses the quantization operation into the pre-training or fine-tuning process. It learns model weights in low-bit representation directly and leads to better performance at the cost of additional training time and computation.

最直接的方法是在量化后，使用与预训练数据集相同或具有代表性的训练数据集对模型进行**微调**。训练目标可以与预训练的目标相同（例如，在通用语言模型训练中的NLL/MLM），也可以是针对我们关心的下游任务的特定目标（例如，分类的交叉熵）。

> The most straightforward approach is to **fine-tune** the model after quantization on a training dataset that is the same as or representative of the pre-training dataset. The training objective can be the same as the one for pre-training (e.g. NLL/MLM in general language model training) or specific to a downstream task that we care about (e.g. Cross entropy for classification).

另一种方法是将全精度模型视为教师模型，将低精度模型视为学生模型，然后使用**蒸馏**损失来优化低精度模型。蒸馏通常不需要使用原始数据集；例如，维基百科数据集是一个不错的选择，甚至随机令牌也能带来可观的性能提升。*逐层知识蒸馏*（*LKD*；[Yao et al. 2022](https://arxiv.org/abs/2206.01861)）方法逐层量化网络，并使用其原始的、未量化版本作为教师模型。在给定相同输入的情况下，LKD 最小化层权重乘法与量化层权重乘法之间的 MSE。

> Another approach is to consider the full-precision model as the teacher and the lower-precision model as the student, and then optimize the low-precision model with **distillation** loss. Distillation usually doesn’t need to use the original dataset; E.g. Wikipedia dataset is a good choice and even random tokens can give decent performance gain. The *Layer-by-layer Knowledge Distillation* (*LKD*; [Yao et al. 2022](https://arxiv.org/abs/2206.01861)) method quantizes the network layer by layer and uses its original, unquantized version as the teacher model. Given the same inputs, LKD minimizes the MSE between the multiplication with layer weights and the multiplication of quantized layer weights.

### 剪枝

> Pruning

网络剪枝旨在通过修剪不重要的模型权重或连接来减小模型大小，同时保持模型容量。它可能需要或可能不需要重新训练。剪枝可以是**非结构化**的或**结构化**的。

> Network pruning is to reduce the model size by trimming unimportant model weights or connections while the model capacity remains. It may or may not require re-training. Pruning can be **unstructured** or **structured**.

- *非结构化剪枝*允许丢弃任何权重或连接，因此它不保留原始网络架构。非结构化剪枝通常与现代硬件配合不佳，并且不会带来实际的推理加速。
- *结构化剪枝*旨在保持密集矩阵乘法的形式，其中一些元素为零。它们可能需要遵循某些模式限制才能与硬件内核支持的功能配合使用。在这里，我们专注于结构化剪枝，以在Transformer模型中实现*高稀疏性*。

> • *Unstructured pruning* is allowed to drop any weight or connection, so it does not retain the original network architecture. Unstructured pruning often does not work well with modern hardware and doesn’t lead to actual inference speedup.
> • *Structured pruning* aims to maintain the dense matrix multiplication form where some elements are zeros. They may need to follow certain pattern restrictions to work with what hardware kernel supports. Here we focus on structured pruning to achieve *high sparsity* in transformer models.

构建剪枝网络的常规工作流程包含三个步骤：

> A routine workflow to construct a pruned network has three steps:

1. 训练一个密集网络直至收敛；
2. 剪枝网络以移除不需要的结构；
3. 可选地重新训练网络，以使用新权重恢复性能。

> • Train a dense network until convergence;
> • Prune the network to remove unwanted structure;
> • Optionally retrain the network to recover the performance with new weights.

通过网络剪枝在密集模型中发现稀疏结构，同时稀疏网络仍能保持相似性能的想法，其灵感来源于[彩票假说](https://lilianweng.github.io/posts/2019-03-14-overfit/#the-lottery-ticket-hypothesis)（**LTH**）：一个随机初始化、密集的前馈网络包含一个子网络池，其中只有一部分（一个稀疏网络）是*“中奖彩票”*，它们在单独训练时可以达到最佳性能。

> The idea of discovering a sparse structure within a dense model via network pruning while the sparse network can still maintain similar performance is motivated by [Lottery Ticket Hypothesis](https://lilianweng.github.io/posts/2019-03-14-overfit/#the-lottery-ticket-hypothesis) (**LTH**): A randomly initialized, dense, feed-forward network contains a pool of subnetworks and among them only a subset (a sparse network) are *“winning tickets”* which can achieve the optimal performance when trained in isolation.

#### 如何剪枝？

> How to prune?

**幅度剪枝**是最简单但相当有效的剪枝方法——修剪绝对值最小的权重。事实上，一些研究（[Gale et al. 2019](https://arxiv.org/abs/1902.09574)）发现，*简单的幅度剪枝方法可以达到与复杂剪枝方法相当或更好的结果*，例如变分 dropout（[Molchanov et al. 2017](https://arxiv.org/abs/1701.05369)）和`l_0`正则化（[Louizos et al. 2017](https://arxiv.org/abs/1712.01312)）。幅度剪枝易于应用于大型模型，并在广泛的超参数范围内实现相当一致的性能。

英文原文：Magnitude pruning is simplest yet quite effective pruning method - weights with smallest absolute values are trimmed. In fact, some studies ([Gale et al. 2019](https://arxiv.org/abs/1902.09574)) found that *simple magnitude pruning approaches can achieve comparable or better results than complicated pruning methods*, such as variational dropout ([Molchanov et al. 2017](https://arxiv.org/abs/1701.05369)) and `l_0` regularization ([Louizos et al. 2017](https://arxiv.org/abs/1712.01312)). Magnitude pruning is simple to apply to large models and achieves reasonably consistent performance across a wide range of hyperparameters.

[Zhu & Gupta (2017)](https://arxiv.org/abs/1710.01878)发现，*大型稀疏模型能够比其小型但密集的对应模型实现更好的性能*。他们提出了**渐进幅度剪枝（GMP）**算法，该算法在训练过程中逐渐增加网络的稀疏性。在每个训练步骤中，绝对值最小的权重被遮蔽为零，以达到所需的稀疏度`s`，并且被遮蔽的权重在反向传播期间不会获得梯度更新。所需的稀疏度`s`随着训练步骤的增加而提高。GMP 的过程对学习率调度很敏感，学习率应高于密集网络训练中使用的学习率，但又不能过高以防止收敛。

英文原文：[Zhu & Gupta (2017)](https://arxiv.org/abs/1710.01878) found that *large sparse models were able to achieve better performance than their small but dense counterparts*. They proposed Gradual Magnitude Pruning (GMP) algorithm that increases the sparsity of a network gradually over the course of training. At each training step, weights with smallest absolute values are masked to be zeros to achieve a desired sparsity level `s` and masked weights do not get gradient update during back-propagation. The desired sparsity level `s` goes up with more training steps. The process of GMP is sensitive to the learning rate schedule, which should be higher than what’s used in dense network training, but not too high to prevent convergence.

**迭代剪枝**（[Renda et al. 2020](https://arxiv.org/abs/2003.02389)）多次迭代步骤 2（剪枝）和步骤 3（重新训练）：在每次迭代中，只剪枝一小部分权重并重新训练模型。该过程重复进行，直到达到所需的稀疏度。

> **Iterative pruning** ([Renda et al. 2020](https://arxiv.org/abs/2003.02389)) iterates step 2 (prune) & step 3 (retrain) multiple times: Only a small fraction of weights are pruned and the model is retrained in each iteration. The process repeats until a desired sparsity level is reached.

#### 如何重新训练？

> How to retrain?

再训练步骤可以是使用相同的预训练数据或其他特定任务数据集进行的简单微调。

> The retraining step can be simple fine-tuning using the same pre-training data or other task-specific datasets.

[彩票假设](https://lilianweng.github.io/posts/2019-03-14-overfit/#the-lottery-ticket-hypothesis)提出了一种**权重回溯**再训练技术：剪枝后，未剪枝的权重在训练早期*重新初始化回原始值*，然后使用相同的学习率调度进行再训练。

> [Lottery Ticket Hypothesis](https://lilianweng.github.io/posts/2019-03-14-overfit/#the-lottery-ticket-hypothesis) proposed a **weight rewinding** retraining technique: After pruning, the unpruned weights are *reinitialized back to original values* earlier in the training and then retrain with the same learning rate schedule.

**学习率回溯** ([Renda et al. 2020](https://arxiv.org/abs/2003.02389)) 仅将学习率重置回其早期值，而未剪枝的权重自上次训练阶段结束以来保持不变。他们观察到 (1) 使用权重回溯进行再训练在所有网络和数据集上都优于使用微调进行再训练，并且 (2) 学习率回溯在所有测试场景中都与权重回溯持平或优于权重回溯。

> **Learning rate rewinding** ([Renda et al. 2020](https://arxiv.org/abs/2003.02389)) only resets the learning rate back to its early value, while the unpruned weights stay unchanged since the end of the last train stage. They observed that (1) retraining with weight rewinding outperforms retraining with fine-tuning across networks and datasets and (2) learning rate rewinding matches or outperforms weight rewinding in all tested scenarios.

### 稀疏性

> Sparsity

稀疏性是一种有效的方法，可以在保持模型推理计算效率的同时扩展模型容量。这里我们考虑两种用于 Transformer 的稀疏性：

> Sparsity is an effective way to scale up model capacity while keeping model inference computationally efficient. Here we consider two types of sparsity for transformers:

- 稀疏化的密集层，包括自注意力层和前馈网络层。
- 稀疏模型架构；即通过整合专家混合（MoE）组件。

> • Sparsified dense layers, including both self-attention and FFN layers.
> • Sparse model architecture; i.e. via incorporating the Mixture-of-Experts (MoE) component.

#### 通过剪枝实现 N:M 稀疏性

> N:M Sparsity via Pruning

**N:M 稀疏性**是一种结构化稀疏模式，与现代 GPU 硬件优化配合良好，其中`N`在每`M`个连续元素中，有 `N` 个是零。例如，Nvidia A100 GPU 的稀疏张量核心支持 2:4 稀疏性以实现更快的推理（[Nvidia 2020](https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf)）

英文原文：N:M sparsity is a structured sparsity pattern that works well with modern GPU hardware optimization, in which `N` out of every `M` consecutive elements are zeros. For example, the sparse tensor core of Nvidia A100 GPU has support for 2:4 sparsity for faster inference ([Nvidia 2020](https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf)).

![A matrix of 2:4 structured sparsity and its compressed representation. (Image source: Nvidia blog )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/2-to-4-sparsity.png)

为了使密集神经网络稀疏化以遵循N:M结构化稀疏模式，[Nvidia (2020)](https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf) 建议使用三步[常规工作流程](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#routine-workflow)来训练剪枝网络：训练 –> 剪枝以满足2:4稀疏性 –> 再训练。

> To sparsify a dense neural network to follow a N:M structured sparsity pattern, [Nvidia (2020)](https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf) suggested using the three-step [routine workflow](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/#routine-workflow) for training a pruned network: train –> prune to satisfy 2:4 sparsity –> retrain.

重新排列列可以在剪枝过程中提供更多选项，以保持大参数的量级或满足N:M稀疏性等特殊限制 ([Pool & Yu 2021](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html))。只要两个矩阵的配对轴以相同的顺序排列，矩阵乘法的结果就不会改变。例如，

> Permuting columns can provide more options in the pruning process to maintain parameters of large magnitude or to satisfy a special restriction like N:M sparsity ([Pool & Yu 2021](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html)). As long as paired axes of two matrices are permuted in the same order, the results of matrix multiplication would not change. For example,

(1) 在自注意力模块中，如果对查询嵌入矩阵 $\mathbf{Q}$ 的轴 1 和键嵌入矩阵 $\mathbf{K}^\top$ 的轴 0 应用相同的置换顺序，则矩阵乘法 $\mathbf{Q}\mathbf{K}^\top$ 的最终结果将保持不变。

> (1) Within the self-attention module, if the same permutation order is applied on the axis 1 of query embedding matrix $\mathbf{Q}$ and the axis 0 of key embedding matrix $\mathbf{K}^\top$, the final result of matrix multiplication of $\mathbf{Q}\mathbf{K}^\top$ would stay the same.

![Illustration of same permutation on $\mathbf{Q}$ (axis 1) and $\mathbf{K}^\top$ (axis 0) to keep the results of a self-attention module unchanged.](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/permutation-QK.png)

(2) 在包含两个 MLP 层和一个 ReLU 非线性层的 FFN 层中，我们可以以相同的顺序置换第一个线性权重矩阵 $\mathbf{W}_1$ 的轴 1 和第二个线性权重矩阵 $\mathbf{W}_2$ 的轴 0。

> (2) Within the FFN layer that contains two MLP layers and one ReLU non-linear layer, we can permute the first linear weight matrix $\mathbf{W}_1$ along the axis 1 and the second linear weight matrix $\mathbf{W}_2$ along the axis 0 in the same order.

![Illustration of the same permutation on $\mathbf{W}_1$ (axis 1) and $\mathbf{W}_2$ (axis 0) to keep the FFN layer's output unchanged. For simplicity, the bias terms are skipped but the same permutation should be applied on them too.](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/permutation-FFN.png)

为了强制执行 N:M 结构化稀疏性，我们将一个矩阵的列分成多个 $M$ 列的片段（称为“条纹”），我们可以很容易地观察到，每个条纹内列的顺序和条纹的顺序都不会影响 N:M 稀疏性限制。

> To enforce N:M structured sparsity, let’s split the columns of one matrix into multiple slides of $M$ columns (named “stripe”) and we can easily observe that both the order of columns within each stripe and the order of stripes have no effect on the N:M sparsity restriction.

[Pool & Yu (2021)](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html) 提出了一种迭代贪婪算法，用于寻找最优置换，以最大化 N:M 稀疏性的权重幅度。所有通道对都被试探性地交换，并且只采用导致幅度增加最大的交换，从而生成新的置换并完成一次迭代。贪婪算法可能只找到局部最小值，因此他们引入了两种技术来逃离局部最小值：

> [Pool & Yu (2021)](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html) proposed an iterative greedy algorithm to find optimal permutation that maximizes the weight magnitude for N:M sparsity. All pairs of channels are speculatively swapped and only the swap that leads to the greatest increase in magnitude is adopted, generating a new permutation and concluding a single iteration. Greedy algorithm may only find local minima, so they introduced two techniques to escape local minima:

1. 有界回归：在实践中，两个随机通道被交换，最多交换固定次数。解决方案搜索的深度仅限于一次通道交换，以保持搜索空间广阔而浅显。
2. 窄而深搜索：选择多个条带并同时优化它们。

> • Bounded regressions: In practice two random channels are swapped, up to a fixed number of times. The solution search is limited to a depth of only one channel swap to keep the search space broad and shallow.
> • Narrow, deep search: Choose multiple stripes and optimize them at the same time.

![Algorithm of finding the best permutation for N:M sparsity greedily and iteratively. (Image source: Pool & Yu 2021 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/N-to-M-sparsity-permutation-algo.png)

与按照默认通道顺序修剪网络相比，如果在修剪之前对网络进行置换，网络可以获得更好的性能。

> The network can achieve better performance if it was permuted before pruning, compared to pruning the network in its default channel order.

为了从头开始训练具有 N:M 稀疏性的模型，[Zhou & Ma, et al. (2021)](https://arxiv.org/abs/2102.04010) 扩展了 STE（Straight-Through Estimator；[Bengio et al. 2013](https://arxiv.org/abs/1308.3432)），该方法通常用于模型量化中的反向传播更新，使其适用于幅度剪枝和稀疏参数更新。

> To train a model with N:M sparsity from scratch, [Zhou & Ma, et al. (2021)](https://arxiv.org/abs/2102.04010) extended STE (Straight-Through Estimator; [Bengio et al. 2013](https://arxiv.org/abs/1308.3432)), which is commonly used for back-propagation update in model quantization, to work for magnitude pruning and sparse parameter update.

STE 计算密集参数相对于剪枝网络的梯度 $\widetilde{W}$, $\partial \mathcal{L}/\partial \widetilde{W}$，并将其作为近似值应用于密集网络 $W$：

> STE computes the gradients of dense parameters wrt the pruned network $\widetilde{W}$, $\partial \mathcal{L}/\partial \widetilde{W}$, and applies that to the dense network $W$ as an approximation:

$$
W_{t+1} \gets W_t - \gamma \frac{\partial\mathcal{L}}{\partial\widetilde{W}}
$$

扩展版本，**SR-STE**（稀疏精炼STE），通过以下方式更新密集权重`W`：

英文原文：The extended version, SR-STE (Sparse-refined STE), updates the dense weights `W` by:



$$
W_{t+1} \gets W_t - \gamma \frac{\partial\mathcal{L}}{\partial\widetilde{W}}  + \lambda_W (\bar{\mathcal{E}} \odot W_t)
$$


其中 $\bar{\mathcal{E}}$ 是 $\widetilde{W}$ 的掩码矩阵，$\odot$ 表示逐元素乘法。SR-STE 的提出是为了防止二值掩码发生大幅变化，其做法是（1）限制在 $\widetilde{W}_t$ 中被剪枝权重的取值，以及（2）促进 $\widetilde{W}_t$ 中未被剪枝的权重。

>
>
> $$
> W_{t+1} \gets W_t - \gamma \frac{\partial\mathcal{L}}{\partial\widetilde{W}}  + \lambda_W (\bar{\mathcal{E}} \odot W_t)
> $$
>
>
> where $\bar{\mathcal{E}}$ is the mask matrix for $\widetilde{W}$ and $\odot$ is element-wise multiplication. SR-STE is proposed to prevent large change in the binary mask by (1) restricting the values of weights pruned in $\widetilde{W}_t$, and (2) promoting the non-pruned weights in $\widetilde{W}_t$.

![Comparison of STE and SR-STE. $\odot$ is element-wise product; $\otimes$ is matrix multiplication. (Image source: Zhou & Ma, et al. 2021 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/SR-STE.png)

与 STE 或 SR-STE 不同，**Top-KAST**（[Jayakumar et al. 2021](https://arxiv.org/abs/2106.03517)）方法可以在训练过程中在正向和反向传播中保持恒定的稀疏性，但不需要使用密集参数或密集梯度的正向传播。

> Different from STE or SR-STE, the **Top-KAST** ([Jayakumar et al. 2021](https://arxiv.org/abs/2106.03517)) method can preserve constant sparsity throughout training in both the forward and backward-passes but does not require forward passes with dense parameters or dense gradients.

在一个训练步骤中 $t$，Top-KAST 的处理过程如下：

> At one training step $t$, Top-KAST processes as follows:

1\. *稀疏前向传播*：选择一个参数子集 $A^t \subset \Theta$，包含按每个层的幅度计算的前$K$个参数，且仅限于前 $D$比例的权重。参数化 $\alpha^t$ 在时间 $t$ 时，如果不在 $A^t$（活动权重）中，则其参数被置零。

英文原文：

1\. *Sparse forward pass*: Select a subset of parameters $A^t \subset \Theta$, containing top-$K$ parameters by magnitude by each layer, restricted to top $D$ -proportion of weights. The parameterization $\alpha^t$ at time $t$ has parameters zeroed out if it is not in $A^t$ (active weights).

$$
\alpha^t_i = \begin{cases}
\theta^t_i & \text{ if } i \in A^t = \{i \mid \theta^t_i \in \text{TopK}(\theta^t, D) \}\\ 
0 & \text{ otherwise}
\end{cases}
$$

其中$\text{TopK}(\theta, x)$选择前$x$比例的权重来自$\theta$根据大小

> where $\text{TopK}(\theta, x)$ selected top $x$ proportion of weights from $\theta$ based on magnitude.

1\. *稀疏反向传播*: 然后将梯度应用于更大的参数子集$B \subset \Theta$，其中$B$包含$(D+M)$比例的权重和$A \subset B$。更新更大比例的权重可以更有效地探索不同的剪枝掩码，从而更有可能导致前$D$比例的活跃权重发生置换。

英文原文：

1\. *Sparse backward pass*: Then apply gradients to a larger parameter subset $B \subset \Theta$ where $B$ contains $(D+M)$ -proportion of weights and $A \subset B$. Updating a larger proportion of weights enables more effective exploration of different pruning masks, making it more likely to cause permutations in the top $D$ -proportion active weights.

$$
\Delta_{\theta^t_i} = \begin{cases}
-\eta \nabla_{\alpha_t} \mathcal{L}(y, x, \alpha^t)_i & \text{ if } i\in  B^t = \{i \mid \theta^t_i \in \text{TopK}(\theta^t, D+M) \} \\
0 & \text{ otherwise }
\end{cases}
$$

训练分为两个阶段，集合$B \setminus A$中的额外坐标控制引入的探索量。探索量预计在训练过程中逐渐减少，掩码最终稳定下来。

> Training is split into two stages and the additional coordinates in the set $B \setminus A$ controls how much exploration is brought in. The amount of exploration is expected to diminish gradually through the training process and the mask eventually stabilizes.

![The pruning mask of Top-KAST stabilizes in time. (Image source: Jayakumar et al. 2021 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/Top-KAST-stabilize.png)

为了防止强者愈强的现象，Top-KAST通过L2正则化损失惩罚活跃权重的幅度，以鼓励对新项目进行更多探索。为了在更新过程中稳定掩码，$B \setminus A$中的参数比$A$受到更重的惩罚，以提高选择门槛。

> To prevent rich-get-richer phenomenon, Top-KAST penalizes the magnitude of active weights via a L2 regularization loss to encourage more exploration of new items. Parameters in $B \setminus A$ are penalized more than $A$ for a higher selection bar during updates to stabilize the mask.

$$
L_\text{penalty}(\alpha^t_i) = \begin{cases}
\vert \theta^t_i\vert  & \text{ if } i \in A^t \\ 
\vert \theta^t_i\vert / D  & \text{ if } i \in B^t \setminus A^t \\ 
0 & \text{ otherwise}
\end{cases}
$$

#### 稀疏化Transformer

> Sparsified Transformer

*Scaling Transformer* ([Jaszczur et al. 2021](https://arxiv.org/abs/2111.12763)) 稀疏化了 Transformer 架构中的自注意力层和 FFN 层，实现了单样本推理 37 倍的加速。

> *Scaling Transformer* ([Jaszczur et al. 2021](https://arxiv.org/abs/2111.12763)) sparsifies both self-attention and FFN layers in transformer architecture, achieving 37x speedup for single-example inference.

![The speed of decoding a single token (unbatched inference) by a transformer model when sparsification is applied on different layers. (Image source: Jaszczur et al. 2021 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/scaling-transformer-speedup-table.png)

**稀疏 FFN 层**：每个 FFN 层包含 2 个 MLP 和一个 ReLU 激活函数。由于 ReLU 会引入大量零值，他们对激活函数实现了一种固定结构，以强制在 `N` 个元素的一个块中只存在 1 个非零值。稀疏模式是动态的，每个 token 都不同。

英文原文：Sparse FFN layer: Each FFN layer contains 2 MLP and one ReLU in-between. Because ReLU will introduce a lot of zeros, they implement a fixed structure on activations to enforce only 1 non-zero value in one block of `N` elements. The sparsity pattern is dynamic, different for each token.

$$
\begin{aligned}
Y_\text{sparse} &= \max(0, xW_1 + b_1) \odot \text{Controller}(x) \\
\text{SparseFFN}(x) &= Y_\text{sparse} W_2 + b_2 \\
\text{Controller}(x) &= \arg\max(\text{Reshape}(x C_1 C_2, (-1, N)))
\end{aligned}
$$

其中 $Y_\text{sparse}$ 中的每个激活对应于 $W_1$ 中的一列和 $W_2$ 中的一行。控制器被实现为一个低秩瓶颈密集层，$C_1 \in \mathbb{R}^{d_\text{model} \times d_\text{lowrank}}, C_2 \in \mathbb{R}^{d_\text{lowrank} \times d_\text{ff}}$ 和 $d_\text{lowrank} = d_\text{model} / N$。它在推理时使用 $\arg\max$ 来选择哪些列应该是非零的，并在训练时使用 Gumbel-softmax 技巧 ([Jang et al. 2016](https://arxiv.org/abs/1611.01144))。因为我们可以在加载 FFN 权重矩阵之前计算 $\text{Controller}(x)$，所以我们知道哪些列将被置零，因此选择*不加载*它们到内存中以加速推理。

> where each activation in $Y_\text{sparse}$ corresponds to one column in $W_1$ and one row in $W_2$. The controller is implemented as a low-rank bottleneck dense layer, $C_1 \in \mathbb{R}^{d_\text{model} \times d_\text{lowrank}}, C_2 \in \mathbb{R}^{d_\text{lowrank} \times d_\text{ff}}$ and $d_\text{lowrank} = d_\text{model} / N$. It uses $\arg\max$ for inference to select which columns should be non-zero and Gumbel-softmax trick ([Jang et al. 2016](https://arxiv.org/abs/1611.01144)) during training. Because we can compute $\text{Controller}(x)$ before loading FFN weight matrices, we know which columns will be zeroed out and thus choose *not to load* them into memory for inference speedup.

![(a) Sparse FFN layer; columns in red are not loaded in memory for faster inference. (b) Sparse FFN controller for 1:4 sparsity. (Image source: Jaszczur et al. 2021 ) *Lilian's side note*: Fig (a) in the illustration from the paper is actually $Y_\text{sparse} = \max\big(0, (xW_1 + b_1) \odot \text{Controller}(x)\big)$, but it doesn't change the results.](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/sparse-FFN.png)

**稀疏 QKV（注意力）层**：在注意力层中，维度 $d_\text{model}$ 被分成 `S` 个模块，每个模块的大小为 $M=d_\text{model} /S$。为了确保每个细分都能访问嵌入的任何部分，Scaling Transformer 引入了一个乘法层（即，一个乘法层将来自多个神经网络层的输入进行逐元素相乘），该层可以表示任意排列，但参数比密集层少。

英文原文：Sparse QKV (attention) layer: In the attention layer, the dimensionality 

$d_\text{model}$ is divided into `S` modules, each of size 

$M=d_\text{model} /S$. To make sure each subdivision can access any part of the embedding, Scaling Transformer introduces a multiplicative layer (i.e., a multiplication layer multiplies inputs from multiple neural network layers element-wise) which can represent arbitrary permutation but contains fewer parameters than a dense layer.

给定输入向量 $x \in \mathbb{R}^{d_\text{model}}$，乘法层输出 $y \in \mathbb{R}^{S \times M}$：

> Given an input vector $x \in \mathbb{R}^{d_\text{model}}$, the multiplicative layer outputs $y \in \mathbb{R}^{S \times M}$:

$$
y_{s,m} = \sum_i x_i D_{i,s} E_{i,m}
\quad\text{where }D \in \mathbb{R}^{d_\text{model} \times S}, D \in \mathbb{R}^{d_\text{model} \times M}
$$

乘法层的输出是一个大小为 $\in \mathbb{R}^{\text{batch size}\times \text{length} \times S \times M}$ 的张量。然后它由一个二维卷积层处理，其中 $\text{length}$ 和 $S$ 被视为图像的高度和宽度。这样的卷积层进一步减少了注意力层的参数数量和计算时间。

> The output of the multiplicative layer is a tensor of size $\in \mathbb{R}^{\text{batch size}\times \text{length} \times S \times M}$. It then gets processed by a two-dimensional convolutional layer, where $\text{length}$ and $S$ are treated as the height and width of an image. Such a convolution layer further reduces the parameter count and computation time of attention layer.

![(a) A multiplicative layer is introduced to enable partitions to access any part of an embedding. (b) Combination of multiplicative dense layer and 2-D convolutional layer reduces the number of parameters and computation time of the attention layer. (Image source: Jaszczur et al. 2021 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/sparse-QKV.png)

为了更好地处理长序列，Scaling Transformer 进一步配备了来自 [Reformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#locality-sensitive-hashing-reformer) ([Kitaev, et al. 2020](https://arxiv.org/abs/2001.04451)) 的 LSH（局部敏感哈希）注意力机制和 FFN 块循环，从而产生了 *Terraformer*。

> To better work with long sequences, Scaling Transformer is further equipped with LSH (locality-sensitive hashing) attention from [Reformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#locality-sensitive-hashing-reformer) ([Kitaev, et al. 2020](https://arxiv.org/abs/2001.04451)) and FFN block recurrence, resulting in *Terraformer*.

#### 专家混合模型

> Mixture-of-Experts

专家混合（MoE）模型依赖于一组“专家”网络，每个示例只激活其中一部分网络来获取预测。这个想法起源于 20 世纪 90 年代 ([Jacobs et al. 1991](https://www.cs.toronto.edu/~hinton/absps/jjnh91.pdf))，并与集成方法密切相关。有关如何将 MoE 模块整合到 Transformer 中的详细信息，请查阅我[之前关于大型模型训练技术的文章](https://lilianweng.github.io/posts/2021-09-25-train-large/)以及 [Fedus et al. 2022](https://arxiv.org/abs/2209.01667) 关于 MoE 的综述论文。

> Mixture-of-experts (MoE) models depend on a collection of “expert” networks and each example only activates a subset of networks to get predictions. The idea originated back to the 1990s ([Jacobs et al. 1991](https://www.cs.toronto.edu/~hinton/absps/jjnh91.pdf)) and is strongly related to ensemble methods. For details on how to incorporate MoE module into transformer, please check my [previous post on large model training techniques](https://lilianweng.github.io/posts/2021-09-25-train-large/) and a survey paper on MoE by [Fedus et al. 2022](https://arxiv.org/abs/2209.01667).

采用 MoE 架构，在解码时只利用部分参数，因此节省了推理成本。每个专家的容量可以通过超参数容量因子 $C$ 进行调整，专家容量定义为：

> With MoE architecture, only partial parameters are utilized at decoding time and therefore it saves inference cost. The capacity of each expert can be adjusted with a hyperparameter, capacity factor $C$, and the expert capacity is defined as:

$$
\text{Expert capacity} = \text{round}(C \cdot k \cdot \frac{\text{total # tokens in one batch}}{\text{# experts}})
$$

其中每个 token 选择 top-$k$ 个专家。更大的 $C$ 会带来更高的专家容量和更好的性能，但计算成本更高。当 $C>1$ 时，会增加一个松弛容量；否则，当 $C<1$ 时，路由网络需要忽略一些 token。

> where top-$k$ experts are selected per token. Larger $C$ leads to higher expert capacity and improved performance but more expensive computationally. When $C>1$, a slack capacity is added; otherwise, when $C<1$, the routing network needs to ignore some tokens.

##### 路由策略改进

> Routing Strategy Improvement

MoE 层有一个路由网络，用于为每个输入 token 分配一部分专家。在传统 MoE 模型中，路由策略是根据 token 出现的自然顺序，将每个 token 路由到不同的首选专家。如果一个 token 被路由到已达到容量的专家，该 token 将被标记为*“溢出”并跳过*。

> MoE layer has a routing network to assign a subset of experts for each input token. The routing strategy in vanilla MoE models is to route each token toward preferred experts differently as they come up in the natural order. If a token is routed to experts that have reached their capacity, the token would be marked *“overflowed” and skipped*.

**V-MoE** (Vision MoE; [Riquelme et al. 2021](https://arxiv.org/abs/2106.05974)) 将 MoE 层添加到 ViT (Vision Transformer) 中。它达到了之前最先进的性能，但推理计算量仅需*一半*。V-MoE 可以扩展到 150 亿参数。他们的实验使用了 $k=2$、32 个专家和每隔一层放置专家（意味着 MoE 层放置在每隔一个层中）。

英文原文：V-MoE (Vision MoE; [Riquelme et al. 2021](https://arxiv.org/abs/2106.05974)) adds MoE layers into ViT (Vision Transformer). It matches the performance of previous SoTA but only requires *half* of inference compute. V-MoE can be scaled up to 15B parameters. Their experiments used 

$k=2$, 32 experts and every-2 expert placement (meaning that MoEs are placed in every other layer).

由于每个专家容量有限，一些重要且信息丰富的 token 如果在预定义的序列顺序（例如，句子中单词的顺序或图像块的顺序）中出现得太晚，可能不得不被丢弃。为了避免传统路由方案中的这一缺点，V-MoE 采用了 **BPR（批优先级路由）**，优先将专家分配给具有高优先级分数的 token。BPR 在专家分配之前计算每个 token 的优先级分数（top-`k` 路由器分数的最大值或总和），并相应地改变 token 的顺序。这保证了专家容量缓冲区将首先被关键 token 填充。

英文原文：Since each expert has a limited capacity, some important and informative tokens may have to be discarded if they come up too late in the predefined sequence order (e.g. the order of words in a sentence, or the order of image patches). To avoid such a drawback in the vanilla routing scheme, V-MoE adopts BPR (Batch Priority Routing) to assign experts to tokens with a high priority score first. BPR computes a priority score (max or sum of top-`k` router scores) per token before expert assignment and alters the order of tokens accordingly. This guarantees that the expert capacity buffer would be fulfilled with key tokens first.

![How image patches are discarded according to priority scores when $C < 1$. (Image source: Riquelme et al. 2021 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/BPR.png)

当 $C\leq 0.5$ 时，BPR 比传统路由效果好得多，此时模型开始丢弃大量 token。它使模型即使在相当低的容量下也能与密集网络竞争。

> BPR works much better than vanilla routing when $C\leq 0.5$, where the model starts dropping a significant amount of tokens. It capacitates the model to be competitive with the dense network even at quite low capacities.

在研究如何解释图像类别与专家关联时，他们观察到早期的 MoE 层更通用，而后续的 MoE 层可能专门用于少数图像类别。

> When looking into how to interpret image class-expert association, they observed that early MoE layers are more general, while later MoE layers could be specialized for a few image classes.

**任务 MoE** (Task-level Mixture-of-Experts; [Kudugunta et al. 2021](https://arxiv.org/abs/2110.03742)) 在机器翻译中考虑了任务信息，并在*任务*级别而不是单词或 token 级别路由 token。他们以 MNMT（多语言神经机器翻译）为例，根据目标语言或语言对对翻译任务进行分组。

> **Task MoE** (Task-level Mixture-of-Experts; [Kudugunta et al. 2021](https://arxiv.org/abs/2110.03742) ) takes the task information into consideration and routes tokens at the *task* level instead of the word or token level for machine translation. They used MNMT (multilingual neural machine translation) as an example and group translation tasks based on the target language or language pairs.

token 级别路由是动态的，每个 token 的路由决策是独立做出的。因此，在推理时，服务器需要预加载所有专家。相比之下，给定一个固定任务，任务级别路由是*静态的*，因此一个任务的推理服务器只需要预加载 $k$ 个专家（假设是 top-$k$ 路由）。根据他们的实验，与密集模型基线相比，任务 MoE 可以实现与 token MoE 相似的性能提升，同时峰值吞吐量提高 2.6 倍，解码器大小仅为 1.6%。

> Token level routing is dynamic and the routing decision for each token is made disjointly. Hence, at inference time, the server needs to preload all the experts. In comparison, task level routing is *static* given a fixed task, so the inference server for one task only needs to preload $k$ experts (assuming top-$k$ routing). According to their experiments, Task MoE can achieve similar performance gain as token MoE compared to dense model baseline with 2.6x higher peak throughput and 1.6% of the decoder size.

任务级别 MoE 本质上是根据预定义的*启发式规则*对任务分布进行分类，并将这种人类知识融入到路由器中。当不存在此类启发式规则时（例如，考虑一个通用的句子续写任务），如何利用任务 MoE 将不那么直接。

> Task level MoE is essentially to categorize a distribution of tasks according to predefined  *heuristics* and incorporate such human knowledge into the router. When such heuristics do not exist (e.g. consider a general sentence continuation task), it would not be straightforward how to utilize Task MoE.

**PR-MoE**（金字塔残差MoE；[Rajbhandari et al. 2022](https://arxiv.org/abs/2201.05596)）让每个token通过一个固定的MLP和一个选定的专家。由于观察到MoE在后期层更具优势，PR-MoE在后期层采用了更多的专家。DeepSpeed库实现了一种灵活的多专家、多数据并行机制，以支持在不同层使用不同数量的专家来训练PR-MoE。

> **PR-MoE** (Pyramid residual MoE; [Rajbhandari et al. 2022](https://arxiv.org/abs/2201.05596)) has each token pass one fixed MLP and one chosen expert. Due to the observation that MoE at later layers is more beneficial, PR-MoE adopts more exports at later layers. DeepSpeed library implements a flexible multi-expert, multi-data parallelism to enable training PR-MoE with different numbers of experts across layers.

![Illustration of PR-MoE architecture in comparison with a standard MoE. (Image source: Rajbhandari et al. 2022 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/PR-MoE.png)

##### 内核改进

> Kernel Improvement

专家网络可以托管在不同的设备上。然而，当GPU数量增加时，每个GPU的专家数量会减少，并且专家之间的通信（“All-to-all”）变得更加昂贵。跨多个GPU的专家之间的All-to-all通信依赖于NCCL的P2P API，这在大规模情况下无法饱和高速链路（例如NVLink、HDR InfiniBand）的带宽，因为随着使用更多节点，单个数据块会变小。现有的all-to-all算法在小工作负载的大规模情况下表现不佳。有多种内核改进可以实现更高效的MoE计算，例如使all-to-all通信更便宜/更快。

> Expert networks can be hosted on different devices. However, when the number of GPUs increases, the number of experts per GPU decreases and the communication between experts (“All-to-all”) grows to be more expensive. All-to-all communication between experts across a number of GPUs relies on P2P APIs of NCCL, which cannot saturate the bandwidth of high-speed links (e.g. NVLink, HDR InfiniBand) at a large scale, as individual chunk gets smaller with more nodes used. The existing all-to-all algorithm performs poorly at large scale with a small workload. There are a variety of kernel improvements to enable more efficient MoE computation, such as making all-to-all communication cheaper/faster.

*DeepSpeed*库（[Rajbhandari et al. 2022](https://arxiv.org/abs/2201.05596)）和TUTEL（[Hwang et al. 2022](https://arxiv.org/abs/2206.03382)）都实现了一种基于树的**分层all-to-all**算法，该算法先运行节点内all-to-all，然后运行节点间all-to-all。它将通信跳数从$O(G)$减少到$O(G_\text{node} + G / G_\text{node})$，其中`G`是GPU节点的总数，$G_\text{node}$是每个节点的GPU核心数。尽管在这种实现中通信量翻倍，但它在大规模小批量情况下实现了更好的扩展性，因为当批量较小时，瓶颈在于延迟而不是通信带宽。

英文原文：Both the *DeepSpeed* library ([Rajbhandari et al. 2022](https://arxiv.org/abs/2201.05596)) and TUTEL ([Hwang et al. 2022](https://arxiv.org/abs/2206.03382)) implemented a tree-based hierarchical all-to-all algorithm, which runs an intra-node all-to-all followed by an inter-node all-to-all. It reduces the communication hops from 

$O(G)$ to 

$O(G_\text{node} + G / G_\text{node})$, where `G` is the total number of GPU nodes and 

$G_\text{node}$ is the number of GPU cores per node. Although the communication volume is doubled in such implementation, it enables better scaling with small batches at large scale as the bottleneck is on latency instead of communication bandwidth when the batch size is small.

*DynaMoE*（[Kossmann et al. 2022](https://arxiv.org/abs/2205.01848)）使用**动态重编译**来使计算资源适应专家之间动态的工作负载。`RECOMPILE`机制从头开始编译计算图，并且只在需要时重新分配资源。它测量分配给每个专家的样本数量，并动态调整其容量因子`C`，以减少运行时的内存和计算需求。基于样本-专家分配在训练早期收敛的观察，在收敛后引入了*样本分配缓存*，然后使用`RECOMPILE`来消除门控网络和专家之间的依赖关系。

英文原文：*DynaMoE* ([Kossmann et al. 2022](https://arxiv.org/abs/2205.01848)) uses dynamic recompilation to adapt the computational resources to dynamic workloads among experts. The `RECOMPILE` mechanism compiles the computation graph from scratch and only reallocates resources when needed. It measures how many samples are assigned to each expert and adjusts their capacity factors `C` dynamically, in order to reduce the memory and computation requirements at run time. Based on the observation that sample-expert assignments converge early in training, *sample assignment caching* is introduced after convergence and then `RECOMPILE` is used to eliminate the dependency between the gating network and experts.

### 架构优化

> Architectural Optimization

关于*高效Transformer*的综述论文（[Tay et al. 2020](https://arxiv.org/abs/2009.06732)）回顾了一系列新的Transformer架构，这些架构旨在提高*计算和内存效率*。强烈推荐阅读。您也可以查看我的文章[“The Transformer Family Version 2.0”](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/)，深入了解各种Transformer架构改进，包括使模型运行成本更低的更改。

> The survey paper on *Efficient Transformers* ([Tay et al. 2020](https://arxiv.org/abs/2009.06732)) reviewed a collection of new transformer architectures with improvement for better *computational and memory efficiency*. Strongly recommend a read. You can also check out my post [“The Transformer Family Version 2.0”](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/) for introduction to a diverse set of transformer archiecture improvements in depth, including changes to make the model cheaper to run.

![Categorization of efficient transformer models. (Image source: Tay et al. 2020 )](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/efficient-transformer.png)

由于自注意力机制具有二次时间复杂度与内存复杂度，这是提高Transformer解码效率的主要瓶颈，所有高效的Transformer模型都对原本稠密的注意力层应用了某种形式的稀疏性。这里只列出高层概述，其中一些源自[Tay et al. 2020](https://arxiv.org/abs/2009.06732)。

> Since the self-attention mechanism has quadratic time and memory complexity and that is the main bottleneck for better transformer decoding efficiency, all the efficient transformer models have applied some form of sparsity to the otherwise dense attention layer. Here only lists a high-level overview, several derived from [Tay et al. 2020](https://arxiv.org/abs/2009.06732).

#### 稀疏注意力模式

> Sparse Attention Patterns

1\. *固定模式*通过使用预定义、固定的模式来限制注意力矩阵的视野。

   - 将输入序列分块为固定块，例如[分块注意力](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/##strided-context)；

   - [Image Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/##fixed-local-context)使用局部注意力；

   - [Sparse Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/##strided-context)使用跨步注意力模式。

2\. *组合模式*学习对输入token进行排序/聚类——在保持固定模式效率优势的同时，实现对序列更优化的全局视图。

   - [Sparse Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#sparse-attention-matrix-factorization-sparse-transformers)结合了跨步注意力和局部注意力；

   - 给定一个高维输入张量，[Axial Transformer](https://arxiv.org/abs/1912.12180)不是对输入的扁平化版本应用注意力，而是沿着输入张量的单个轴应用多个注意力。

   - [ETC、Longformer和Big Bird](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#combination-of-local-and-global-context)结合了局部和全局上下文，以及跨步或随机注意力。

3\. *可学习模式*通过学习识别最优注意力模式。

• [Reformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#content-based-attention)根据基于哈希的相似性（LSH）将token聚类；



• [Routing Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#content-based-attention)对token运行$k$ -均值聚类；



• [Sinkhorn Sorting Network](https://arxiv.org/abs/2002.11296)学习对输入序列的块进行排序。

英文原文：

1\. 
*Fixed Patterns* limit the field of view for the attention matrix, using predefined, fixed patterns.



   - Chunk input sequences into fixed blocks, such as [Blockwise Attention](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/##strided-context);

   - [Image Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/##fixed-local-context) uses local attention;

   - [Sparse Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/##strided-context) uses strided attention patterns.

2\. 
*Combined Patterns* learn to sort/cluster the input tokens - enabling a more optimal global view of the sequence while maintaining the efficiency benefits of fixed patterns.



   - [Sparse Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#sparse-attention-matrix-factorization-sparse-transformers) combines strided and local attention;

   - Given a high dimensional input tensor, instead of applying attention to the flattened version of the input, [Axial Transformer](https://arxiv.org/abs/1912.12180) applies multiple attentions, each along a single axis of the input tensor.

   - [ETC, Longformer and Big Bird](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#combination-of-local-and-global-context) combines local and global context, as well as strided or random attention.

3\. 
*Learnable Patterns* identify the optimal attention pattern via learning.



• [Reformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#content-based-attention) clusters tokens into clusters based on hash-based similarity (LSH);



• [Routing Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#content-based-attention) runs $k$ -means clustering on tokens;



• [Sinkhorn Sorting Network](https://arxiv.org/abs/2002.11296) learns to sort blocks of input sequence.

#### 循环

> Recurrence

循环机制通过循环连接多个块/段。

> Recurrence mechanism connects multiple blocks/segments via recurrence.

- [Transformer-XL](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#context-memory)通过重用段之间的隐藏状态来利用更长的上下文。
- [Universal Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#make-it-recurrent)将自注意力与RNN中的循环机制相结合。
- [Compressive Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#context-memory)是Transformer-XL的扩展，增加了额外的内存，包含一组用于过去激活的内存槽和用于压缩激活的压缩内存槽。每当模型接受新的输入段时，主内存中最旧的激活会被移动到压缩内存中，并在那里应用压缩函数。

> • [Transformer-XL](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#context-memory) makes use of longer context by reusing hidden states between segments.
> • [Universal Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#make-it-recurrent) combines self-attention with the recurrent mechanism in RNN.
> • [Compressive Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#context-memory) is an extension of Transformer-XL with additional memory, containing a set of memory slots for past activiations and compressive memory slots for compressed activations. Whenever the model accepts a new input segment, the oldest activations in the primary memory are moved to the compressed memory where a compression function is applied.

#### 内存节省设计

> Memory Saving Designs

内存节省设计指的是改变架构以使用更少内存。

> Memory saving designs refer to changes of the architecture to use less memory.

• [Linformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#low-rank-attention)将键和值的长度维度投影到较低维度的表示（$N \to k$），从而将内存复杂度从$N \times N$降低到$N \times k$。

• [Shazeer (2019)](https://arxiv.org/abs/1911.02150)提出了*多查询注意力*，它在不同的注意力“头”之间共享键和值，大大减少了这些张量的大小和内存成本。

• [随机特征注意力和Performer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#low-rank-attention)使用[核方法](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/(https:/lilianweng.github.io/posts/2022-09-08-ntk/#kernel--kernel-methods))来实现自注意力机制更经济的数学形式。

英文原文：

• [Linformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#low-rank-attention) projects the length dimension of keys and values to a lower-dimensional representation ($N \to k$) and thus the memory complexity is reduced from $N \times N$ to $N \times k$.

• [Shazeer (2019)](https://arxiv.org/abs/1911.02150) proposed *multi-query attention* which has the keys and values shared across different attention “heads”, greatly reducing the size of these tensors and the memory cost.

• [Random feature attention and Performer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#low-rank-attention) use [kernel methods](https://lilianweng.github.io/posts/2023-01-10-inference-optimization/(https:/lilianweng.github.io/posts/2022-09-08-ntk/#kernel--kernel-methods)) to achieve a cheaper mathematical format of the self-attention mechanism.

#### 自适应注意力

> Adaptive Attention

*自适应注意力*使模型能够学习最佳注意力跨度，或决定何时对不同的输入token进行提前退出。

> *Adaptive attention* enables the model to learn the optimal attention span or decide on when to do early exiting for different input tokens.

- [自适应注意力跨度](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#adaptive-attention-span)通过在token和其他键之间使用软掩码，训练模型学习每个token每个头的最佳注意力跨度。
- [Universal Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#make-it-recurrent)结合了循环机制，并使用[ACT（自适应计算时间）](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act)来动态决定循环步数。
- [深度自适应Transformer和CALM](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#depth-adaptive-transformer)学习何时使用一些置信度度量来对每个token提前退出计算层，以实现良好的性能-效率权衡。

> • [Adaptive Attention Span](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#adaptive-attention-span) trains the model to learn the optimal attention span per token per head via a soft mask between the token and other keys.
> • [Universal Transformer](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#make-it-recurrent) incorporates recurrent mechanism and uses [ACT (Adaptive computation time)](https://lilianweng.github.io/posts/2020-04-07-the-transformer-family/#adaptive-computation-time-act) to dynamically decide the number of recurrent steps.
> • [Depth-Adaptive Transformer and CALM](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#depth-adaptive-transformer) learns when to early exit the computation layers per token using some confidence measures to achieve good performance-efficiency tradeoffs.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2023年1月). Large Transformer Model Inference Optimization. Lil’Log. https://lilianweng.github.io/posts/2023-01-10-inference-optimization/.

> Weng, Lilian. (Jan 2023). Large Transformer Model Inference Optimization. Lil’Log. https://lilianweng.github.io/posts/2023-01-10-inference-optimization/.

或

> Or

```
@article{weng2023inference,
  title   = "Large Transformer Model Inference Optimization",
  author  = "Weng, Lilian",
  journal = "Lil'Log",
  year    = "2023",
  month   = "Jan",
  url     = "https://lilianweng.github.io/posts/2023-01-10-inference-optimization/"
}
```

### 参考文献

> References

[1] Bondarenko et al. [“理解并克服高效Transformer量化的挑战”](https://arxiv.org/abs/2109.12948) ACL 2021。

> [1] Bondarenko et al. [“Understanding and overcoming the challenges of efficient transformer quantization”](https://arxiv.org/abs/2109.12948) ACL 2021.

[2] Dettmers et al. [“LLM.int8(): 大规模Transformer的8位矩阵乘法”](https://arxiv.org/abs/2208.07339) NeuriPS 2022

> [2] Dettmers et al. [“LLM.int8(): 8-bit Matrix Multiplication for Transformers at Scale”](https://arxiv.org/abs/2208.07339) NeuriPS 2022

[3] Zadeh et al. [“Gobo: 量化基于注意力的NLP模型以实现低延迟和高能效推理。”](https://arxiv.org/abs/2005.03842) MICRO 2020

> [3] Zadeh et al. [“Gobo: Quantizing attention-based NLP models for low latency and energy efficient inference.”](https://arxiv.org/abs/2005.03842) MICRO 2020

[4] Shen, Dong & Ye, et al. [“Q-BERT: 基于Hessian的BERT超低精度量化”](https://arxiv.org/abs/1909.05840) AAAI 2020。

> [4] Shen, Dong & Ye, et al. [“Q-BERT: Hessian based ultra low precision quantization of BERT”](https://arxiv.org/abs/1909.05840) AAAI 2020.

[5] Yao et al. [“ZeroQuant: 大规模Transformer高效且经济的训练后量化”](https://arxiv.org/abs/2206.01861) arXiv preprint arXiv:2206.01861 (2022)。

> [5] Yao et al. [“ZeroQuant: Efficient and affordable post-training quantization for large-scale transformers”](https://arxiv.org/abs/2206.01861) arXiv preprint arXiv:2206.01861 (2022).

[6] Frantar et al. [“GPTQ: 生成式预训练Transformer的精确量化”](https://arxiv.org/abs/2210.17323) arXiv preprint arXiv:2210.17323 (2022)。

> [6] Frantar et al. [“GPTQ: Accurate Quantization for Generative Pre-trained Transformers”](https://arxiv.org/abs/2210.17323) arXiv preprint arXiv:2210.17323 (2022).

[7] Xiao & Lin [“SmoothQuant: 加速稀疏神经网络训练：一种可证明且高效的N:M可转置掩码查找方法。”](https://arxiv.org/abs/2211.10438) arXiv preprint arXiv:2211.10438 (2022)。 | [代码](https://github.com/mit-han-lab/smoothquant)

> [7] Xiao & Lin [“SmoothQuant: Accelerated sparse neural training: A provable and efficient method to find N:M transposable masks.”](https://arxiv.org/abs/2211.10438) arXiv preprint arXiv:2211.10438 (2022). | [code](https://github.com/mit-han-lab/smoothquant)

[8] Pool & Yu. [“N:M稀疏性的通道置换。”](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html) NeuriPS 2021。 | [代码](https://github.com/NVIDIA/apex/tree/master/apex/contrib/sparsity)

> [8] Pool & Yu. [“Channel Permutations for N:M Sparsity.”](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html) NeuriPS 2021. | [code](https://github.com/NVIDIA/apex/tree/master/apex/contrib/sparsity)

[9] Zhou & Ma, et al. [“从头开始学习N:M细粒度结构化稀疏神经网络。”](https://arxiv.org/abs/2102.04010) arXiv preprint arXiv:2102.04010 (2021)。

> [9] Zhou & Ma, et al. [“Learning N:M fine-grained structured sparse neural networks from scratch.”](https://arxiv.org/abs/2102.04010) arXiv preprint arXiv:2102.04010 (2021).

[10] Jayakumar et al. [“Top-KAST: Top-K Always Sparse Training.”](https://arxiv.org/abs/2106.03517) NeuriPS 2020.

> [10] Jayakumar et al. [“Top-KAST: Top-K Always Sparse Training.”](https://arxiv.org/abs/2106.03517) NeuriPS 2020.

[11] Nvidia. [“Nvidia A100 tensor core GPU architecture.”](https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf) 2020.

> [11] Nvidia. [“Nvidia A100 tensor core GPU architecture.”](https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf) 2020.

[12] Gale, Elsen & Hooker [“The State of Sparsity in Deep Neural Networks.”](https://arxiv.org/abs/1902.09574) arXiv preprint arXiv:1902.09574 (2019).

> [12] Gale, Elsen & Hooker [“The State of Sparsity in Deep Neural Networks.”](https://arxiv.org/abs/1902.09574) arXiv preprint arXiv:1902.09574 (2019).

[13] Zhu & Gupta. [“To Prune, or Not to Prune: Exploring the Efficacy of Pruning for Model Compression.”](https://arxiv.org/abs/1710.01878) arXiv preprint arXiv:1710.01878 (2017).

> [13] Zhu & Gupta. [“To Prune, or Not to Prune: Exploring the Efficacy of Pruning for Model Compression.”](https://arxiv.org/abs/1710.01878) arXiv preprint arXiv:1710.01878 (2017).

[14] Renda et al. [“Comparing rewinding and fine-tuning in neural network pruning.”](https://arxiv.org/abs/2003.02389) arXiv preprint arXiv:2003.02389 (2020).

> [14] Renda et al. [“Comparing rewinding and fine-tuning in neural network pruning.”](https://arxiv.org/abs/2003.02389) arXiv preprint arXiv:2003.02389 (2020).

[15] Zhou & Ma, et al. [“Learning N:M fine-grained structured sparse neural networks from scratch.”](https://arxiv.org/abs/2102.04010) arXiv preprint arXiv:2102.04010 (2021).

> [15] Zhou & Ma, et al. [“Learning N:M fine-grained structured sparse neural networks from scratch.”](https://arxiv.org/abs/2102.04010) arXiv preprint arXiv:2102.04010 (2021).

[16] Pool & Yu. [“Channel Permutations for N:M Sparsity.”](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html) NeuriPS 2021. | [code](https://github.com/NVIDIA/apex/tree/master/apex/contrib/sparsity)

> [16] Pool & Yu. [“Channel Permutations for N:M Sparsity.”](https://proceedings.neurips.cc/paper/2021/hash/6e8404c3b93a9527c8db241a1846599a-Abstract.html) NeuriPS 2021. | [code](https://github.com/NVIDIA/apex/tree/master/apex/contrib/sparsity)

[17] Jaszczur et al. [“Sparse is Enough in Scaling Transformers.”](https://arxiv.org/abs/2111.12763) NeuriPS 2021.

> [17] Jaszczur et al. [“Sparse is Enough in Scaling Transformers.”](https://arxiv.org/abs/2111.12763) NeuriPS 2021.

[18] Mishra et al. [“An Survey of Neural Network Compression.”](https://arxiv.org/abs/2010.03954) arXiv preprint arXiv:1710.09282 (2017).

> [18] Mishra et al. [“An Survey of Neural Network Compression.”](https://arxiv.org/abs/2010.03954) arXiv preprint arXiv:1710.09282 (2017).

[19] Fedus et al. [“A Review of Sparse Expert Models in Deep Learning.”](https://arxiv.org/abs/2209.01667) arXiv preprint arXiv:2209.01667 (2022)..

> [19] Fedus et al. [“A Review of Sparse Expert Models in Deep Learning.”](https://arxiv.org/abs/2209.01667) arXiv preprint arXiv:2209.01667 (2022)..

[20] Riquelme et al. [“Scaling vision with sparse mixture of experts.”](https://arxiv.org/abs/2106.05974) NeuriPS 2021.

> [20] Riquelme et al. [“Scaling vision with sparse mixture of experts.”](https://arxiv.org/abs/2106.05974) NeuriPS 2021.

[21] Kudugunta et al. [“Beyond Distillation: Task-level Mixture-of-Experts for Efficient Inference.”](https://arxiv.org/abs/2110.03742) arXiv preprint arXiv:2110.03742 (2021).

> [21] Kudugunta et al. [“Beyond Distillation: Task-level Mixture-of-Experts for Efficient Inference.”](https://arxiv.org/abs/2110.03742) arXiv preprint arXiv:2110.03742 (2021).

[22] Rajbhandari et al. [“DeepSpeed-MoE: Advancing mixture-of-experts inference and training to power next-generation ai scale.”](https://arxiv.org/abs/2201.05596) arXiv preprint arXiv:2201.05596 (2022).

> [22] Rajbhandari et al. [“DeepSpeed-MoE: Advancing mixture-of-experts inference and training to power next-generation ai scale.”](https://arxiv.org/abs/2201.05596) arXiv preprint arXiv:2201.05596 (2022).

[23] Kossmann et al. [“Optimizing mixture of experts using dynamic recompilations.”](https://arxiv.org/abs/2205.01848)  arXiv preprint arXiv:2205.01848 (2022).

> [23] Kossmann et al. [“Optimizing mixture of experts using dynamic recompilations.”](https://arxiv.org/abs/2205.01848)  arXiv preprint arXiv:2205.01848 (2022).

[24] Hwang et al. [“Tutel: Adaptive mixture-of-experts at scale.”](https://arxiv.org/abs/2206.03382)  arXiv preprint arXiv:2206.03382 (2022). | [code](https://github.com/microsoft/tutel)

> [24] Hwang et al. [“Tutel: Adaptive mixture-of-experts at scale.”](https://arxiv.org/abs/2206.03382)  arXiv preprint arXiv:2206.03382 (2022). | [code](https://github.com/microsoft/tutel)

[25] Noam Shazeer. [“Fast Transformer Decoding: One Write-Head is All You Need.”](https://arxiv.org/abs/1911.02150) arXiv preprint arXiv:1911.02150 (2019).

> [25] Noam Shazeer. [“Fast Transformer Decoding: One Write-Head is All You Need.”](https://arxiv.org/abs/1911.02150) arXiv preprint arXiv:1911.02150 (2019).

[26] Tay et al. [“Efficient Transformers: A Survey.”](https://arxiv.org/abs/2009.06732) ACM Computing Surveys 55.6 (2022): 1-28.

> [26] Tay et al. [“Efficient Transformers: A Survey.”](https://arxiv.org/abs/2009.06732) ACM Computing Surveys 55.6 (2022): 1-28.

[27] Pope et al. [“Efficiently Scaling Transformer Inference.”](https://arxiv.org/abs/2211.05102) arXiv preprint arXiv:2211.05102 (2022).

> [27] Pope et al. [“Efficiently Scaling Transformer Inference.”](https://arxiv.org/abs/2211.05102) arXiv preprint arXiv:2211.05102 (2022).

[28] Frankle & Carbin. [“The Lottery Ticket Hypothesis: Finding Sparse, Trainable Neural Networks”](https://arxiv.org/abs/1803.03635) ICLR 2019.

> [28] Frankle & Carbin. [“The Lottery Ticket Hypothesis: Finding Sparse, Trainable Neural Networks”](https://arxiv.org/abs/1803.03635) ICLR 2019.

[29] Elabyad et al. [“Depth-Adaptive Transformer”](https://arxiv.org/abs/1910.10073) ICLR 2020.

> [29] Elabyad et al. [“Depth-Adaptive Transformer”](https://arxiv.org/abs/1910.10073) ICLR 2020.

[30] Schuster et al. [“Confident Adaptive Language Modeling”](https://arxiv.org/abs/2207.07061) arXiv preprint arXiv:2207.07061 (2022).

> [30] Schuster et al. [“Confident Adaptive Language Modeling”](https://arxiv.org/abs/2207.07061) arXiv preprint arXiv:2207.07061 (2022).

[31] Gou et al. [“https://arxiv.org/abs/2006.05525”](https://arxiv.org/abs/2006.05525) arXiv preprint arXiv:2006.05525 (2020).

> [31] Gou et al. [“https://arxiv.org/abs/2006.05525”](https://arxiv.org/abs/2006.05525) arXiv preprint arXiv:2006.05525 (2020).

[32] Hinton et al. [“Distilling the Knowledge in a Neural Network”](https://arxiv.org/abs/1503.02531) NIPS 2014.

> [32] Hinton et al. [“Distilling the Knowledge in a Neural Network”](https://arxiv.org/abs/1503.02531) NIPS 2014.

[33] Sanh et al. [“DistilBERT, a distilled version of BERT: smaller, faster, cheaper and lighter”](https://arxiv.org/abs/1910.01108) Workshop on Energy Efficient Machine Learning and Cognitive Computing @ NeuriPS 2019.

> [33] Sanh et al. [“DistilBERT, a distilled version of BERT: smaller, faster, cheaper and lighter”](https://arxiv.org/abs/1910.01108) Workshop on Energy Efficient Machine Learning and Cognitive Computing @ NeuriPS 2019.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Transformer | Transformer模型 | 一种基于自注意力机制的神经网络架构，广泛应用于自然语言处理和计算机视觉任务。 |
| Inference Optimization | 推理优化 | 旨在减少模型在部署阶段的计算资源消耗（如时间、内存和FLOPs）的技术。 |
| SoTA (State-of-the-Art) | 最先进 | 指在特定任务或数据集上达到当前最佳性能的算法或模型。 |
| KV Cache | KV缓存 | 在Transformer解码过程中，用于存储先前计算的键（Key）和值（Value）向量，以避免重复计算。 |
| FLOPs (Floating Point Operations) | 浮点运算次数 | 衡量模型计算复杂度的指标，表示模型执行的浮点运算总数。 |
| Knowledge Distillation (KD) | 知识蒸馏 | 一种模型压缩技术，通过训练一个小型“学生模型”来模仿大型“教师模型”的行为和输出。 |
| Quantization | 量化 | 将模型权重和/或激活从高精度（如浮点数）转换为低精度（如8位整数）的过程，以减少内存和加速计算。 |
| Pruning | 剪枝 | 一种模型压缩技术，通过移除神经网络中不重要或冗余的权重、连接或神经元来减小模型大小。 |
| Sparsity | 稀疏性 | 指模型参数中存在大量零值，可以减少存储和计算需求。 |
| Mixture-of-Experts (MoE) | 专家混合模型 | 一种神经网络架构，包含多个“专家”网络，每个输入示例只激活其中一部分专家进行处理。 |
| Post-Training Quantization (PTQ) | 训练后量化 | 在模型训练完成后，无需额外训练即可将模型权重转换为较低精度的量化方法。 |
| Quantization-Aware Training (QAT) | 量化感知训练 | 在模型训练或微调过程中引入量化操作，使模型能够学习低精度表示，以获得更好的量化性能。 |
| N:M Sparsity | N:M稀疏性 | 一种结构化稀疏模式，在每M个连续元素中，有N个是非零的，常用于硬件加速。 |
| Hessian Matrix | Hessian矩阵 | 一个多元函数的二阶偏导数组成的方阵，在优化中用于分析函数的曲率和敏感度。 |
| Self-Attention Mechanism | 自注意力机制 | Transformer模型的核心组件，允许模型在处理序列时，根据序列中不同位置的重要性来加权输入。 |
