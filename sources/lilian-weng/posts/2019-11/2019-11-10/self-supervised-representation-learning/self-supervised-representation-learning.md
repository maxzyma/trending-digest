# 自监督表征学习

> Self-Supervised Representation Learning

> 来源：Lil'Log / Lilian Weng，2019-11-10
> 原文链接：https://lilianweng.github.io/posts/2019-11-10-self-supervised/
> 分类：机器学习 / 自监督学习

## 核心要点

- 自监督学习通过构建特殊形式的监督任务，利用未标记数据生成“免费”标签，从而以监督方式训练模型。
- 自监督学习的目标并非前置任务本身的性能，而是学习到对各种下游任务有益的、具有良好语义或结构意义的中间表征。
- 基于图像的自监督学习方法包括利用图像扭曲（如旋转）、图像块关系（如相对位置、拼图）和图像着色等前置任务。
- 生成模型（如去噪自编码器、上下文编码器）通过重建原始输入来学习有意义的潜在表示，但自监督表征学习更侧重于生成对许多任务普遍有用的良好特征。
- 对比学习（如对比预测编码CPC）将生成建模问题转化为分类问题，通过最大化输入与上下文之间的互信息来学习表示。
- 基于视频的自监督学习利用视频帧的时间连贯性，通过跟踪物体、验证帧顺序、预测时间之箭或视频着色等任务来学习表示。
- 在控制领域，自监督学习通过多视图度量学习（如Grasp2Vec、TCN）和自主目标生成（如RIG、CC-VAE）来学习有用的状态嵌入。
- Bisimulation-based方法（如DeepMDP、DBC）旨在根据MDP中状态的行为相似性对状态进行分组，学习与控制相关的表示，而非依赖像素级重建。
- 结合多个前置任务、使用更深的网络可以提高表示质量，但监督学习基线目前仍远远超过所有这些自监督方法。

## 正文

[2020-01-09更新：新增关于[对比预测编码](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#contrastive-predictive-coding)的部分]。  
[2020-04-13更新：新增关于MoCo、SimCLR和CURL的“动量对比”部分。]  
[2020-07-08更新：新增关于DeepMDP和DBC的[“双模拟”](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#bisimulation)部分。]  
[2020-09-12更新：在“动量对比”部分新增[MoCo V2](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2)和[BYOL](https://lilianweng.github.io/posts/2021-05-31-contrastive/#byol)。]  
[2021-05-31更新：移除“动量对比”部分，并添加指向[“对比表征学习”](https://lilianweng.github.io/posts/2021-05-31-contrastive/)完整文章的链接。]

> [Updated on 2020-01-09: add a new section on [Contrastive Predictive Coding](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#contrastive-predictive-coding)].
>
>
> [Updated on 2020-04-13: add a “Momentum Contrast” section on MoCo, SimCLR and CURL.]
>
>
> [Updated on 2020-07-08: add a [“Bisimulation”](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#bisimulation) section on DeepMDP and DBC.]
>
>
> [Updated on 2020-09-12: add [MoCo V2](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2) and [BYOL](https://lilianweng.github.io/posts/2021-05-31-contrastive/#byol) in the “Momentum Contrast” section.]
>
>
> [Updated on 2021-05-31: remove section on “Momentum Contrast” and add a pointer to a full post on [“Contrastive Representation Learning”](https://lilianweng.github.io/posts/2021-05-31-contrastive/)]

给定一个任务和足够的标签，监督学习可以很好地解决它。良好的性能通常需要相当数量的标签，但收集手动标签成本高昂（例如ImageNet），并且难以扩展。考虑到未标记数据（例如，自由文本、互联网上的所有图像）的数量远超有限的人工整理标记数据集，不使用它们有点浪费。然而，无监督学习并不容易，并且通常比监督学习的效率低得多。

> Given a task and enough labels, supervised learning can solve it really well. Good performance usually requires a decent amount of labels, but collecting manual labels is expensive (i.e. ImageNet) and hard to be scaled up. Considering the amount of unlabelled data (e.g. free text, all the images on the Internet) is substantially more than a limited number of human curated labelled datasets, it is kinda wasteful not to use them. However, unsupervised learning is not easy and usually works much less efficiently than supervised learning.

如果我们能免费获得未标记数据的标签，并以监督方式训练无监督数据集呢？我们可以通过将监督学习任务以特殊形式构建，仅使用其余信息来预测部分信息，从而实现这一点。通过这种方式，所有需要的信息，包括输入和标签，都已提供。这被称为*自监督学习*。

> What if we can get labels for free for unlabelled data and train unsupervised dataset in a supervised manner? We can achieve this by framing a supervised learning task in a special form to predict only a subset of information using the rest. In this way, all the information needed, both inputs and labels, has been provided. This is known as *self-supervised learning*.

这一思想已广泛应用于语言建模。语言模型的默认任务是根据过去的序列预测下一个词。[BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert)增加了另外两个辅助任务，两者都依赖于自生成的标签。

> This idea has been widely used in language modeling. The default task for a language model is to predict the next word given the past sequence. [BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert) adds two other auxiliary tasks and both rely on self-generated labels.

![A great summary of how self-supervised learning tasks can be constructed (Image source: LeCun’s talk )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/self-sup-lecun.png)

[这里](https://github.com/jason718/awesome-self-supervised-learning)有一份精心整理的自监督学习论文列表。如果您有兴趣深入阅读，请查阅。

> [Here](https://github.com/jason718/awesome-self-supervised-learning) is a nicely curated list of papers in self-supervised learning. Please check it out if you are interested in reading more in depth.

请注意，本文不侧重于自然语言处理/[语言建模](https://lilianweng.github.io/posts/2019-01-31-lm/)或[生成建模](https://lilianweng.github.io/tags/generative-model/)。

> Note that this post does not focus on either NLP / [language modeling](https://lilianweng.github.io/posts/2019-01-31-lm/) or [generative modeling](https://lilianweng.github.io/tags/generative-model/).

### 为什么选择自监督学习？

> Why Self-Supervised Learning?

自监督学习使我们能够利用数据自带的各种免费标签。其动机相当直接。生成带有干净标签的数据集成本高昂，但未标记数据却一直在生成。为了利用这些数量庞大的未标记数据，一种方法是正确设置学习目标，从而从数据本身获取监督信息。

> Self-supervised learning empowers us to exploit a variety of labels that come with the data for free. The motivation is quite straightforward. Producing a dataset with clean labels is expensive but unlabeled data is being generated all the time. To make use of this much larger amount of unlabeled data, one way is to set the learning objectives properly so as to get supervision from the data itself.

*自监督任务*，也称为*前置任务*，引导我们得到一个监督损失函数。然而，我们通常不关心这个发明任务的最终性能。相反，我们对学习到的中间表征感兴趣，并期望这种表征能够承载良好的语义或结构意义，并对各种实际的下游任务有所裨益。

> The *self-supervised task*, also known as *pretext task*, guides us to a supervised loss function. However, we usually don’t care about the final performance of this invented task. Rather we are interested in the learned intermediate representation with the expectation that this representation can carry good semantic or structural meanings and can be beneficial to a variety of practical downstream tasks.

例如，我们可能会随机旋转图像，并训练模型来预测每张输入图像是如何旋转的。旋转预测任务是虚构的，因此实际准确性并不重要，就像我们对待辅助任务一样。但我们期望模型能为真实世界的任务学习高质量的潜在变量，例如用极少量标记样本构建一个物体识别分类器。

> For example, we might rotate images at random and train a model to predict how each input image is rotated. The rotation prediction task is made-up, so the actual accuracy is unimportant, like how we treat auxiliary tasks. But we expect the model to learn high-quality latent variables for real-world tasks, such as constructing an object recognition classifier with very few labeled samples.

广义上讲，所有生成模型都可以被视为自监督的，但目标不同：生成模型侧重于创建多样化且真实的图像，而自监督表征学习则关注生成对许多任务普遍有用的良好特征。生成建模不是本文的重点，但欢迎查阅我的[往期文章](https://lilianweng.github.io/tags/generative-model/)。

> Broadly speaking, all the generative models can be considered as self-supervised, but with different goals: Generative models focus on creating diverse and realistic images, while self-supervised representation learning care about producing good features generally helpful for many tasks. Generative modeling is not the focus of this post, but feel free to check my [previous posts](https://lilianweng.github.io/tags/generative-model/).

### 基于图像

> Images-Based

针对图像的自监督表征学习已经提出了许多想法。常见的工作流程是使用未标记图像在一个或多个前置任务上训练模型，然后使用该模型的一个中间特征层来喂给ImageNet分类上的多项式逻辑回归分类器。最终的分类准确率量化了学习到的表征有多好。

> Many ideas have been proposed for self-supervised representation learning on images. A common workflow is to train a model on one or multiple pretext tasks with unlabelled images and then use one intermediate feature layer of this model to feed a multinomial logistic regression classifier on ImageNet classification. The final classification accuracy quantifies how good the learned representation is.

最近，一些研究人员提出同时在标记数据上进行监督学习，并在未标记数据上进行自监督前置任务训练，且权重共享，例如在[Zhai et al, 2019](https://arxiv.org/abs/1905.03670)和[Sun et al, 2019](https://arxiv.org/abs/1909.11825)中。

> Recently, some researchers proposed to train supervised learning on labelled data and self-supervised pretext tasks on unlabelled data simultaneously with shared weights, like in [Zhai et al, 2019](https://arxiv.org/abs/1905.03670) and [Sun et al, 2019](https://arxiv.org/abs/1909.11825).

#### 扭曲

> Distortion

我们期望图像上的轻微扭曲不会改变其原始语义含义或几何形状。轻微扭曲的图像被视为与原始图像相同，因此学习到的特征应具有对扭曲的不变性。

> We expect small distortion on an image does not modify its original semantic meaning or geometric forms. Slightly distorted images are considered the same as original and thus the learned features are expected to be invariant to distortion.

**Exemplar-CNN** ([Dosovitskiy et al., 2015](https://arxiv.org/abs/1406.6909)) 使用未标记的图像块创建替代训练数据集：

> **Exemplar-CNN** ([Dosovitskiy et al., 2015](https://arxiv.org/abs/1406.6909)) create surrogate training datasets with unlabeled image patches:

1\. 从不同图像中以不同位置和比例采样大小为32 × 32像素的$N$个图像块，仅从包含显著梯度的区域采样，因为这些区域覆盖边缘并倾向于包含物体或物体的一部分。它们是*“示例性”*图像块。

2\. 每个图像块通过应用各种随机变换（即平移、旋转、缩放等）进行扭曲。所有由此产生的扭曲图像块都被视为属于*同一个替代类别*。

3\. 前置任务是区分一组替代类别。我们可以随意创建任意数量的替代类别。

英文原文：

1\. Sample $N$ patches of size 32 × 32 pixels from different images at varying positions and scales, only from regions containing considerable gradients as those areas cover edges and tend to contain objects or parts of objects. They are *“exemplary”* patches.

2\. Each patch is distorted by applying a variety of random transformations (i.e., translation, rotation, scaling, etc.). All the resulting distorted patches are considered to belong to the *same surrogate class*.

3\. The pretext task is to discriminate between a set of surrogate classes. We can arbitrarily create as many surrogate classes as we want.

![The original patch of a cute deer is in the top left corner. Random transformations are applied, resulting in a variety of distorted patches. All of them should be classified into the same class in the pretext task. (Image source: Dosovitskiy et al., 2015 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/examplar-cnn.png)

整个图像的**旋转**（[Gidaris et al. 2018](https://arxiv.org/abs/1803.07728)）是另一种有趣且廉价的修改输入图像的方式，同时语义内容保持不变。每个输入图像首先随机旋转$90^\circ$的倍数，对应于$[0^\circ, 90^\circ, 180^\circ, 270^\circ]$。模型被训练来预测应用了哪种旋转，因此这是一个4类分类问题。

英文原文：Rotation of an entire image ([Gidaris et al. 2018](https://arxiv.org/abs/1803.07728) is another interesting and cheap way to modify an input image while the semantic content stays unchanged. Each input image is first rotated by a multiple of 

$90^\circ$ at random, corresponding to 

$[0^\circ, 90^\circ, 180^\circ, 270^\circ]$. The model is trained to predict which rotation has been applied, thus a 4-class classification problem.

为了识别具有不同旋转的同一图像，模型必须学习识别高级别的物体部件，例如头部、鼻子和眼睛，以及这些部件的相对位置，而不是局部模式。这种前置任务以这种方式驱动模型学习物体的语义概念。

> In order to identify the same image with different rotations, the model has to learn to recognize high level object parts, such as heads, noses, and eyes, and the relative positions of these parts, rather than local patterns. This pretext task drives the model to learn semantic concepts of objects in this way.

![Illustration of self-supervised learning by rotating the entire input images. The model learns to predict which rotation is applied. (Image source: Gidaris et al. 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/self-sup-rotation.png)

#### 图像块

> Patches

第二类自监督学习任务从一张图像中提取多个图像块，并要求模型预测这些图像块之间的关系。

> The second category of self-supervised learning tasks extract multiple patches from one image and ask the model to predict the relationship between these patches.

[Doersch et al. (2015)](https://arxiv.org/abs/1505.05192) 将前置任务表述为预测一张图像中两个随机图像块之间的**相对位置**。模型需要理解物体的空间上下文，才能判断部件之间的相对位置。

> [Doersch et al. (2015)](https://arxiv.org/abs/1505.05192) formulates the pretext task as predicting the **relative position** between two random patches from one image. A model needs to understand the spatial context of objects in order to tell the relative position between parts.

训练图像块按以下方式采样：

> The training patches are sampled in the following way:

1. 随机采样第一个图像块，不参考任何图像内容。
2. 假设第一个图像块放置在3x3网格的中间，第二个图像块则从其周围的8个相邻位置中采样。
3. 为了避免模型只捕捉低级琐碎信号，例如跨边界连接直线或匹配局部模式，通过以下方式引入额外噪声：
   - 在图像块之间添加间隙
   - 小幅抖动
   - 随机将一些图像块下采样至总像素仅为100，然后进行上采样，以增强对像素化的鲁棒性。
   - 将绿色和洋红色向灰色偏移，或随机丢弃3个颜色通道中的2个（参见下文[“色差”](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#chromatic-aberration)）
4. 模型被训练来预测第二个图像块是从8个相邻位置中的哪一个选取的，这是一个8类分类问题。

> • Randomly sample the first patch without any reference to image content.

> • Considering that the first patch is placed in the middle of a 3x3 grid, and the second patch is sampled from its 8 neighboring locations around it.

> • To avoid the model only catching low-level trivial signals, such as connecting a straight line across boundary or matching local patterns, additional noise is introduced by:
>

> ◦ Add gaps between patches

> ◦ Small jitters

> ◦ Randomly downsample some patches to as little as 100 total pixels, and then upsampling it, to build robustness to pixelation.

> ◦ Shift green and magenta toward gray or randomly drop 2 of 3 color channels (See [“chromatic aberration”](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#chromatic-aberration) below)

> • The model is trained to predict which one of 8 neighboring locations the second patch is selected from, a classification problem over 8 classes.

![Illustration of self-supervised learning by predicting the relative position of two random patches. (Image source: Doersch et al., 2015 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/self-sup-by-relative-position.png)

[https://lilianweng.github.io/posts/2019-11-10-self-supervised/#chromatic-aberration](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#chromatic-aberration)除了边界模式或纹理延续等琐碎信号外，还发现了一个有趣且有点令人惊讶的琐碎解决方案，称为[“色差”](https://en.wikipedia.org/wiki/Chromatic_aberration)。它是由不同波长的光线通过镜头时焦距不同引起的。在此过程中，颜色通道之间可能存在微小偏移。因此，模型可以通过简单比较绿色和洋红色在两个图像块中分离方式的差异来学习判断相对位置。这是一个琐碎的解决方案，与图像内容无关。通过将绿色和洋红色向灰色偏移或随机丢弃3个颜色通道中的2个来预处理图像可以避免这种琐碎的解决方案。

> [https://lilianweng.github.io/posts/2019-11-10-self-supervised/#chromatic-aberration](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#chromatic-aberration)Other than trivial signals like boundary patterns or textures continuing, another interesting and a bit surprising trivial solution was found, called [“chromatic aberration”](https://en.wikipedia.org/wiki/Chromatic_aberration). It is triggered by different focal lengths of lights at different wavelengths passing through the lens. In the process, there might exist small offsets between color channels. Hence, the model can learn to tell the relative position by simply comparing how green and magenta are separated differently in two patches. This is a trivial solution and has nothing to do with the image content. Pre-processing images by shifting green and magenta toward gray or randomly dropping 2 of 3 color channels can avoid this trivial solution.

![Illustration of how chromatic aberration happens. (Image source: wikipedia )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/chromatic-aberration.png)

既然我们已经在上述任务中为每张图像设置了一个3x3网格，为什么不使用全部9个图像块而不是仅仅2个来增加任务难度呢？遵循这一想法，[Noroozi & Favaro (2016)](https://arxiv.org/abs/1603.09246) 设计了一个**拼图游戏**作为前置任务：模型被训练将9个打乱的图像块放回原始位置。

> Since we have already set up a 3x3 grid in each image in the above task, why not use all of 9 patches rather than only 2 to make the task more difficult? Following this idea, [Noroozi & Favaro (2016)](https://arxiv.org/abs/1603.09246) designed a **jigsaw puzzle** game as pretext task: The model is trained to place 9 shuffled patches back to the original locations.

卷积网络以共享权重独立处理每个图像块，并为每个图像块索引输出一个来自预定义置换集的概率向量。为了控制拼图游戏的难度，该论文提出根据预定义的置换集打乱图像块，并配置模型来预测该集中所有索引的概率向量。

> A convolutional network processes each patch independently with shared weights and outputs a probability vector per patch index out of a predefined set of permutations. To control the difficulty of jigsaw puzzles, the paper proposed to shuffle patches according to a predefined permutation set and configured the model to predict a probability vector over all the indices in the set.

因为输入图像块的打乱方式不会改变预测的正确顺序。一个潜在的训练加速改进是使用置换不变图卷积网络（GCN），这样我们就不必多次打乱同一组图像块，这与这篇[论文](https://arxiv.org/abs/1911.00025)中的想法相同。

> Because how the input patches are shuffled does not alter the correct order to predict. A potential improvement to speed up training is to use permutation-invariant graph convolutional network (GCN) so that we don’t have to shuffle the same set of patches multiple times, same idea as in this [paper](https://arxiv.org/abs/1911.00025).

![Illustration of self-supervised learning by solving jigsaw puzzle. (Image source: Noroozi & Favaro, 2016 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/self-sup-jigsaw-puzzle.png)

另一个想法是将“特征”或“视觉基元”视为一个标量值属性，可以在多个图像块上求和并在不同图像块之间进行比较。然后，图像块之间的关系可以通过**计数特征**和简单算术来定义（[Noroozi, et al, 2017](https://arxiv.org/abs/1708.06734)）。

> Another idea is to consider “feature” or “visual primitives” as a scalar-value attribute that can be summed up over multiple patches and compared across different patches. Then the relationship between patches can be defined by **counting features** and simple arithmetic ([Noroozi, et al, 2017](https://arxiv.org/abs/1708.06734)).

该论文考虑了两种变换：

> The paper considers two transformations:

1. *缩放*：如果图像放大2倍，视觉基元的数量应保持不变。
2. *平铺*：如果图像被平铺成2x2网格，视觉基元的数量预计将是原始特征计数的总和，即4倍。

> • *Scaling*:  If an image is scaled up by 2x, the number of visual primitives should stay the same.
> • *Tiling*: If an image is tiled into a 2x2 grid, the number of visual primitives is expected to be the sum, 4 times the original feature counts.

该模型利用上述特征计数关系学习一个特征编码器$\phi(.)$。给定一个输入图像$\mathbf{x} \in \mathbb{R}^{m \times n \times 3}$，考虑两种类型的变换算子：

> The model learns a feature encoder $\phi(.)$ using the above feature counting relationship. Given an input image $\mathbf{x} \in \mathbb{R}^{m \times n \times 3}$, considering two types of transformation operators:

1\. 下采样算子，$D: \mathbb{R}^{m \times n \times 3} \mapsto \mathbb{R}^{\frac{m}{2} \times \frac{n}{2} \times 3}$：按2的因子进行下采样

2\. 平铺算子$T_i: \mathbb{R}^{m \times n \times 3} \mapsto \mathbb{R}^{\frac{m}{2} \times \frac{n}{2} \times 3}$：从图像的2x2网格中提取第$i$个图块。

英文原文：

1\. Downsampling operator, $D: \mathbb{R}^{m \times n \times 3} \mapsto \mathbb{R}^{\frac{m}{2} \times \frac{n}{2} \times 3}$: downsample by a factor of 2

2\. Tiling operator $T_i: \mathbb{R}^{m \times n \times 3} \mapsto \mathbb{R}^{\frac{m}{2} \times \frac{n}{2} \times 3}$: extract the $i$ -th tile from a 2x2 grid of the image.

我们期望学习到：

> We expect to learn:

$$
\phi(\mathbf{x}) = \phi(D \circ \mathbf{x}) = \sum_{i=1}^4 \phi(T_i \circ \mathbf{x})
$$

[https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss)因此，MSE损失为：$\mathcal{L}_\text{feat} = |\phi(D \circ \mathbf{x}) - \sum_{i=1}^4 \phi(T_i \circ \mathbf{x})|^2_2$。为了避免平凡解$\phi(\mathbf{x}) = \mathbf{0}, \forall{\mathbf{x}}$，添加了另一个损失项以鼓励两个不同图像的特征之间的差异：$\mathcal{L}_\text{diff} = \max(0, c -|\phi(D \circ \mathbf{y}) - \sum_{i=1}^4 \phi(T_i \circ \mathbf{x})|^2_2)$，其中$\mathbf{y}$是与$\mathbf{x}$不同的另一个输入图像，$c$是一个标量常数。最终损失为：

> [https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss)Thus the MSE loss is: $\mathcal{L}_\text{feat} = |\phi(D \circ \mathbf{x}) - \sum_{i=1}^4 \phi(T_i \circ \mathbf{x})|^2_2$. To avoid trivial solution $\phi(\mathbf{x}) = \mathbf{0}, \forall{\mathbf{x}}$, another loss term is added to encourage the difference between features of two different images: $\mathcal{L}_\text{diff} = \max(0, c -|\phi(D \circ \mathbf{y}) - \sum_{i=1}^4 \phi(T_i \circ \mathbf{x})|^2_2)$, where $\mathbf{y}$ is another input image different from $\mathbf{x}$ and $c$ is a scalar constant. The final loss is:

$$
\mathcal{L} 
= \mathcal{L}_\text{feat} + \mathcal{L}_\text{diff} 
= \|\phi(D \circ \mathbf{x}) - \sum_{i=1}^4 \phi(T_i \circ \mathbf{x})\|^2_2 + \max(0, M -\|\phi(D \circ \mathbf{y}) - \sum_{i=1}^4 \phi(T_i \circ \mathbf{x})\|^2_2)
$$

![Self-supervised representation learning by counting features. (Image source: Noroozi, et al, 2017 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/self-sup-counting-features.png)

#### 着色

> Colorization

**着色**可以作为一个强大的自监督任务：模型被训练来为灰度输入图像着色；具体来说，任务是将该图像映射到量化颜色值输出的分布上（[Zhang et al. 2016](https://arxiv.org/abs/1603.08511)）。

> **Colorization** can be used as a powerful self-supervised task: a model is trained to color a grayscale input image; precisely the task is to map this image to a distribution over quantized color value outputs ([Zhang et al. 2016](https://arxiv.org/abs/1603.08511)).

模型在[CIE Lab* 色彩空间](https://en.wikipedia.org/wiki/CIELAB_color_space)中输出颜色。L*a*b* 颜色旨在近似人类视觉，而相比之下，RGB 或 CMYK 模拟的是物理设备的颜色输出。

> The model outputs colors in the the [CIE Lab* color space](https://en.wikipedia.org/wiki/CIELAB_color_space). The L*a*b* color is designed to approximate human vision, while, in contrast, RGB or CMYK models the color output of physical devices.

- L* 分量与人类对亮度的感知相匹配；L* = 0 是黑色，L* = 100 表示白色。
- a* 分量表示绿色（负值）/洋红色（正值）。
- b* 分量模型蓝色（负值）/黄色（正值）。

> • L* component matches human perception of lightness; L* = 0 is black and L* = 100 indicates white.
> • a* component represents green (negative) / magenta (positive) value.
> • b* component models blue (negative) /yellow (positive) value.

由于着色问题的多模态性质，预测概率分布在分箱颜色值上的交叉熵损失比原始颜色值的L2损失效果更好。a*b*色彩空间以桶大小10进行量化。

> Due to the multimodal nature of the colorization problem, cross-entropy loss of predicted probability distribution over binned color values works better than L2 loss of the raw color values. The a*b* color space is quantized with bucket size 10.

为了平衡常见颜色（通常是低a*b*值，如云、墙壁和泥土等常见背景）和稀有颜色（可能与图像中的关键对象相关），损失函数通过一个加权项进行重新平衡，该加权项提高了不常见颜色桶的损失。这就像为什么在信息检索模型中我们需要[tf和idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)来对词语进行评分一样。加权项的构造方式为：(1-λ) * 高斯核平滑的经验概率分布 + λ * 均匀分布，其中两种分布都在量化的a*b*色彩空间上。

> To balance between common colors (usually low a*b* values, of common backgrounds like clouds, walls, and dirt) and rare colors (which are likely associated with key objects in the image), the loss function is rebalanced with a weighting term that boosts the loss of infrequent color buckets. This is just like why we need both [tf and idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf) for scoring words in information retrieval model. The weighting term is constructed as: (1-λ) * Gaussian-kernel-smoothed empirical probability distribution + λ * a uniform distribution, where both distributions are over the quantized a*b* color space.

#### 生成模型

> Generative Modeling

生成模型中的前置任务是在学习有意义的潜在表示的同时重建原始输入。

> The pretext task in generative modeling is to reconstruct the original input while learning meaningful latent representation.

 **去噪自编码器** ([Vincent 等人，2008](https://www.cs.toronto.edu/~larocheh/publications/icml-2008-denoising-autoencoders.pdf)) 学习从部分损坏或含有随机噪声的图像版本中恢复图像。这种设计灵感来源于人类即使在有噪声的图片中也能轻易识别物体，这表明关键的视觉特征可以被提取并与噪声分离。参见我的 [旧文章](https://lilianweng.github.io/posts/2018-08-12-vae/#denoising-autoencoder)。

> The **denoising autoencoder** ([Vincent, et al, 2008](https://www.cs.toronto.edu/~larocheh/publications/icml-2008-denoising-autoencoders.pdf)) learns to recover an image from a version that is partially corrupted or has random noise. The design is inspired by the fact that humans can easily recognize objects in pictures even with noise, indicating that key visual features can be extracted and separated from noise. See my [old post](https://lilianweng.github.io/posts/2018-08-12-vae/#denoising-autoencoder).

 **上下文编码器** ([Pathak 等人，2016](https://arxiv.org/abs/1604.07379)) 旨在填补图像中缺失的部分。令 $\hat{M}$ 为一个二值掩码，0 表示丢弃的像素，1 表示保留的输入像素。该模型通过结合重建（L2）损失和对抗性损失进行训练。掩码定义的移除区域可以是任何形状。

英文原文：The context encoder ([Pathak, et al., 2016](https://arxiv.org/abs/1604.07379)) is trained to fill in a missing piece in the image. Let 

$\hat{M}$ be a binary mask, 0 for dropped pixels and 1 for remaining input pixels. The model is trained with a combination of the reconstruction (L2) loss and the adversarial loss. The removed regions defined by the mask could be of any shape.

$$
\begin{aligned}
\mathcal{L}(\mathbf{x}) &= \mathcal{L}_\text{recon}(\mathbf{x}) + \mathcal{L}_\text{adv}(\mathbf{x})\\
\mathcal{L}_\text{recon}(\mathbf{x}) &= \|(1 - \hat{M}) \odot (\mathbf{x} - F(\hat{M} \odot \mathbf{x})) \|_2^2 \\
\mathcal{L}_\text{adv}(\mathbf{x}) &= \max_D \mathbb{E}_{\mathbf{x}} [\log D(\mathbf{x}) + \log(1 - D(F(\hat{M} \odot \mathbf{x})))]
\end{aligned}
$$

其中 $F(.)$ 是通过图像修复重建具有缺失区域的输入图像的完整流程，包括编码器和解码器部分，在 $D(.)$ 中是像 [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/) 中那样联合训练的判别器模型。

> where $F(.)$ is the full pipeline of reconstructing the input image with missing regions via impainting, including both encoder and decoder portions in $D(.)$ is the discriminator model jointly trained, like in [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/).

![Illustration of context encoder. (Image source: Pathak, et al., 2016 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/context-encoder.png)

当对图像应用掩码时，上下文编码器会移除部分区域中所有颜色通道的信息。如果只隐藏一部分通道呢？**分脑自编码器**（[Zhang et al., 2017](https://arxiv.org/abs/1611.09842)）通过从其余通道预测一部分颜色通道来实现这一点。设数据张量$\mathbf{x} \in \mathbb{R}^{h \times w \times \vert C \vert }$具有`C`个颜色通道作为网络的`l`层网络的输入。它被分成两个不相交的部分，$\mathbf{x}_1 \in \mathbb{R}^{h \times w \times \vert C_1 \vert}$和$\mathbf{x}_2 \in \mathbb{R}^{h \times w \times \vert C_2 \vert}$，其中$C_1 , C_2 \subseteq C$。然后训练两个子网络进行两个互补的预测：一个网络`f_1`预测$\mathbf{x}_2$从$\mathbf{x}_1$而另一个网络`f_1`预测$\mathbf{x}_1$从$\mathbf{x}_2$。如果颜色值被量化，损失函数可以是L1损失或交叉熵。

英文原文：When applying a mask on an image, the context encoder removes information of all the color channels in partial regions. How about only hiding a subset of channels? The split-brain autoencoder ([Zhang et al., 2017](https://arxiv.org/abs/1611.09842)) does this by predicting a subset of color channels from the rest of channels. Let the data tensor 

$\mathbf{x} \in \mathbb{R}^{h \times w \times \vert C \vert }$ with `C` color channels be the input for the `l` -th layer of the network. It is split into two disjoint parts, 

$\mathbf{x}_1 \in \mathbb{R}^{h \times w \times \vert C_1 \vert}$ and 

$\mathbf{x}_2 \in \mathbb{R}^{h \times w \times \vert C_2 \vert}$, where 

$C_1 , C_2 \subseteq C$. Then two sub-networks are trained to do two complementary predictions: one network `f_1` predicts 

$\mathbf{x}_2$ from 

$\mathbf{x}_1$ and the other network `f_1` predicts 

$\mathbf{x}_1$ from 

$\mathbf{x}_2$. The loss is either L1 loss or cross entropy if color values are quantized.

这种分割可以一次性发生在 RGB-D 或 L*a*b* 色彩空间上，也可以发生在 CNN 网络的每一层中，其中通道的数量可以是任意的。

> The split can happen once on the RGB-D or L*a*b* colorspace, or happen even in every layer of a CNN network in which the number of channels can be arbitrary.

![Illustration of split-brain autoencoder. (Image source: Zhang et al., 2017 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/split-brain-autoencoder.png)

生成对抗网络（GAN）能够学习从简单的潜在变量映射到任意复杂的数据分布。研究表明，此类生成模型的潜在空间捕获了数据中的语义变化；例如，在人脸图像上训练 GAN 模型时，一些潜在变量与面部表情、眼镜、性别等相关联 ([Radford et al., 2016](https://arxiv.org/abs/1511.06434))。

> The generative adversarial networks (GANs) are able to learn to map from simple latent variables to arbitrarily complex data distributions. Studies have shown that the latent space of such generative models captures semantic variation in the data; e.g. when training GAN models on human faces, some latent variables are associated with facial expression, glasses, gender, etc  ([Radford et al., 2016](https://arxiv.org/abs/1511.06434)).

**双向GANs** ([Donahue, et al, 2017](https://arxiv.org/abs/1605.09782)) 引入了一个额外的编码器 $E(.)$ 来学习从输入到潜在变量 $\mathbf{z}$ 的映射。判别器 $D(.)$ 在输入数据和潜在表示的联合空间中进行预测，$(\mathbf{x}, \mathbf{z})$，以区分生成的对 $(\mathbf{x}, E(\mathbf{x}))$ 和真实的对 $(G(\mathbf{z}), \mathbf{z})$。该模型经过训练以优化目标：$\min_{G, E} \max_D V(D, E, G)$，其中生成器 `G` 和编码器 `E` 学习生成足够真实的数据和潜在变量以混淆判别器，同时判别器 `D` 试图区分真实数据和生成数据。

英文原文：Bidirectional GANs ([Donahue, et al, 2017](https://arxiv.org/abs/1605.09782)) introduces an additional encoder 

$E(.)$ to learn the mappings from the input to the latent variable 

$\mathbf{z}$. The discriminator 

$D(.)$ predicts in the joint space of the input data and latent representation, 

$(\mathbf{x}, \mathbf{z})$, to tell apart the generated pair 

$(\mathbf{x}, E(\mathbf{x}))$ from the real one 

$(G(\mathbf{z}), \mathbf{z})$. The model is trained to optimize the objective: 

$\min_{G, E} \max_D V(D, E, G)$, where the generator `G` and the encoder `E` learn to generate data and latent variables that are realistic enough to confuse the discriminator and at the same time the discriminator `D` tries to differentiate real and generated data.

$$
V(D, E, G) = \mathbb{E}_{\mathbf{x} \sim p_\mathbf{x}} [ \underbrace{\mathbb{E}_{\mathbf{z} \sim p_E(.\vert\mathbf{x})}[\log D(\mathbf{x}, \mathbf{z})]}_{\log D(\text{real})} ] + \mathbb{E}_{\mathbf{z} \sim p_\mathbf{z}} [ \underbrace{\mathbb{E}_{\mathbf{x} \sim p_G(.\vert\mathbf{z})}[\log 1 - D(\mathbf{x}, \mathbf{z})]}_{\log(1- D(\text{fake}))}) ]
$$

![Illustration of how Bidirectional GAN works. (Image source: Donahue, et al, 2017 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/bi-GAN.png)

#### 对比学习

> Contrastive Learning

**对比预测编码 (CPC)** ([van den Oord, et al. 2018](https://arxiv.org/abs/1807.03748)) 是一种通过将生成建模问题转化为分类问题，从高维数据中进行无监督学习的方法。CPC 中的*对比损失*或*InfoNCE 损失*，灵感来源于[噪声对比估计 (NCE)](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#noise-contrastive-estimation-nce)，使用交叉熵损失来衡量模型在给定一组不相关的“负”样本中对“未来”表示进行分类的能力。这种设计部分是由于单峰损失（如 MSE）没有足够的容量，但学习一个完整的生成模型可能过于昂贵。

> The **Contrastive Predictive Coding (CPC)** ([van den Oord, et al. 2018](https://arxiv.org/abs/1807.03748)) is an approach for unsupervised learning from high-dimensional data by translating a generative modeling problem to a classification problem. The *contrastive loss* or *InfoNCE loss* in CPC, inspired by [Noise Contrastive Estimation (NCE)](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#noise-contrastive-estimation-nce), uses cross-entropy loss to measure how well the model can classify the “future” representation amongst a set of unrelated “negative” samples. Such design is partially motivated by the fact that the unimodal loss like MSE has no enough capacity but learning a full generative model could be too expensive.

![Illustration of applying Contrastive Predictive Coding on the audio input. (Image source: van den Oord, et al. 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/CPC-audio.png)

CPC 使用一个编码器来压缩输入数据 $z_t = g_\text{enc}(x_t)$，并使用一个*自回归*解码器来学习可能在未来预测中共享的高级上下文，$c_t = g_\text{ar}(z_{\leq t})$。端到端训练依赖于受 NCE 启发的对比损失。

> CPC uses an encoder to compress the input data $z_t = g_\text{enc}(x_t)$ and an *autoregressive* decoder to learn the high-level context that is potentially shared across future predictions, $c_t = g_\text{ar}(z_{\leq t})$. The end-to-end training relies on the NCE-inspired contrastive loss.

在预测未来信息时，CPC 被优化以最大化输入 $x$ 和上下文向量 $c$ 之间的互信息：

> While predicting future information, CPC is optimized to maximize the the mutual information between input $x$ and context vector $c$:

$$
I(x; c) = \sum_{x, c} p(x, c) \log\frac{p(x, c)}{p(x)p(c)} = \sum_{x, c} p(x, c)\log\frac{p(x|c)}{p(x)}
$$

与其直接建模未来的观测值 $p_k(x_{t+k} \vert c_t)$（这可能相当昂贵），CPC 建模了一个密度函数以保留 $x_{t+k}$ 和 $c_t$ 之间的互信息：

> Rather than modeling the future observations $p_k(x_{t+k} \vert c_t)$ directly (which could be fairly expensive), CPC models a density function to preserve the mutual information between $x_{t+k}$ and $c_t$:

$$
f_k(x_{t+k}, c_t) = \exp(z_{t+k}^\top W_k c_t) \propto \frac{p(x_{t+k}|c_t)}{p(x_{t+k})}
$$

其中$f_k$可以是非标准化的，并且一个线性变换$W_k^\top c_t$用于预测，其中使用了不同的$W_k$矩阵，用于每一步$k$。

> where $f_k$ can be unnormalized and a linear transformation $W_k^\top c_t$ is used for the prediction with a different $W_k$ matrix for every step $k$.

给定一组 $N$ 随机样本 $X = \{x_1, \dots, x_N\}$，其中只包含一个正样本 $x_t \sim p(x_{t+k} \vert c_t)$ 和 $N-1$ 个负样本 $x_{i \neq t} \sim p(x_{t+k})$，正确分类正样本（其中 $\frac{f_k}{\sum f_k}$ 是预测值）的交叉熵损失为：

> Given a set of $N$ random samples $X = \{x_1, \dots, x_N\}$ containing only one positive sample $x_t \sim p(x_{t+k} \vert c_t)$ and $N-1$ negative samples $x_{i \neq t} \sim p(x_{t+k})$, the cross-entropy loss for classifying the positive sample (where $\frac{f_k}{\sum f_k}$ is the prediction) correctly is:

$$
\mathcal{L}_N = - \mathbb{E}_X \Big[\log \frac{f_k(x_{t+k}, c_t)}{\sum_{i=1}^N f_k (x_i, c_t)}\Big]
$$

![Illustration of applying Contrastive Predictive Coding on images. (Image source: van den Oord, et al. 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/CPC-image.png)

当在图像上使用 CPC 时 ([Henaff, et al. 2019](https://arxiv.org/abs/1905.09272))，预测器网络应仅访问掩码特征集，以避免出现平凡预测。具体来说：

> When using CPC on images ([Henaff, et al. 2019](https://arxiv.org/abs/1905.09272)), the predictor network should only access a masked feature set to avoid a trivial prediction. Precisely:

1\. 每个输入图像被划分为一组重叠的块，每个块由一个 ResNet 编码器编码，从而得到压缩特征向量 $z_{i,j}$。

2\. 一个掩码卷积网络通过掩码进行预测，使得给定输出神经元的感受野只能看到图像中其上方的内容。否则，预测问题将变得微不足道。预测可以双向进行（自上而下和自下而上）。

3\. 预测是针对 $z_{i+k, j}$ 从上下文 $c_{i,j}$ 进行的：$\hat{z}_{i+k, j} = W_k c_{i,j}$。

英文原文：

1\. Each input image is divided into a set of overlapped patches and each patch is encoded by a resnet encoder, resulting in compressed feature vector $z_{i,j}$.

2\. A masked conv net makes prediction with a mask such that the receptive field of a given output neuron can only see things above it in the image. Otherwise, the prediction problem would be trivial. The prediction can be made in both directions (top-down and bottom-up).

3\. The prediction is made for $z_{i+k, j}$ from context $c_{i,j}$: $\hat{z}_{i+k, j} = W_k c_{i,j}$.

对比损失量化了这种预测，目标是在一组负表示 $\{z_l\}$ 中正确识别目标，这些负表示从同一图像中的其他补丁和同一批次中的其他图像中采样得到：

> A contrastive loss quantifies this prediction with a goal to correctly identify the target among a set of negative representation $\{z_l\}$ sampled from other patches in the same image and other images in the same batch:

$$
\mathcal{L}_\text{CPC} 
= -\sum_{i,j,k} \log p(z_{i+k, j} \vert \hat{z}_{i+k, j}, \{z_l\}) 
= -\sum_{i,j,k} \log \frac{\exp(\hat{z}_{i+k, j}^\top z_{i+k, j})}{\exp(\hat{z}_{i+k, j}^\top z_{i+k, j}) + \sum_l \exp(\hat{z}_{i+k, j}^\top z_l)}
$$

有关对比学习的更多内容，请查看关于 [“对比表示学习”](https://lilianweng.github.io/posts/2021-05-31-contrastive/) 的文章。

> For more content on contrastive learning, check out the post on [“Contrastive Representation Learning”](https://lilianweng.github.io/posts/2021-05-31-contrastive/).

### 基于视频的

> Video-Based

视频包含一系列语义相关的帧。相邻帧在时间上更接近，并且比距离较远的帧更具相关性。帧的顺序描述了某些推理规则和物理逻辑；例如物体运动应该是平滑的，并且重力是向下的。

> A video contains a sequence of semantically related frames. Nearby frames are close in time and more correlated than frames further away. The order of frames describes certain rules of reasonings and physical logics; such as that object motion should be smooth and gravity is pointing down.

常见的工作流程是使用未标记的视频在一个或多个前置任务上训练模型，然后将该模型的一个中间特征层输入，以在动作分类、分割或对象跟踪等下游任务上微调一个简单模型。

> A common workflow is to train a model on one or multiple pretext tasks with unlabelled videos and then feed one intermediate feature layer of this model to fine-tune a simple model on downstream tasks of action classification, segmentation or object tracking.

#### 跟踪

> Tracking

物体的运动通过一系列视频帧进行追踪。在相邻帧中，同一物体在屏幕上的捕捉方式差异通常不大，这通常是由物体或摄像机的微小移动引起的。因此，为同一物体在相邻帧之间学习到的任何视觉表示在潜在特征空间中都应该接近。受此启发，[Wang & Gupta, 2015](https://arxiv.org/abs/1505.00687) 提出了一种通过在视频中**跟踪移动物体**来无监督学习视觉表示的方法。

> The movement of an object is traced by a sequence of video frames. The difference between how the same object is captured on the screen in close frames is usually not big, commonly triggered by small motion of the object or the camera. Therefore any visual representation learned for the same object across close frames should be close in the latent feature space. Motivated by this idea, [Wang & Gupta, 2015](https://arxiv.org/abs/1505.00687) proposed a way of unsupervised learning of visual representation by **tracking moving objects** in videos.

精确地，带有运动的图像块在一个小时间窗口（例如30帧）内被跟踪。选择第一个图像块 $\mathbf{x}$ 和最后一个图像块 $\mathbf{x}^+$ 并用作训练数据点。如果我们直接训练模型以最小化两个图像块的特征向量之间的差异，模型可能只会学习将所有内容映射到相同的值。为了避免这种琐碎的解决方案，与[上文](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss)相同，添加了一个随机的第三个图像块 $\mathbf{x}^-$。模型通过强制两个被跟踪图像块之间的距离在特征空间中比第一个图像块与随机图像块之间的距离更近来学习表示，$D(\mathbf{x}, \mathbf{x}^-)) > D(\mathbf{x}, \mathbf{x}^+)$，其中 $D(.)$ 是余弦距离，

> Precisely patches with motion are tracked over a small time window (e.g. 30 frames). The first patch $\mathbf{x}$ and the last patch $\mathbf{x}^+$ are selected and used as training data points. If we train the model directly to minimize the difference between feature vectors of two patches, the model may only learn to map everything to the same value. To avoid such a trivial solution, same as [above](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss), a random third patch $\mathbf{x}^-$ is added. The model learns the representation by enforcing the distance between two tracked patches to be closer than the distance between the first patch and a random one in the feature space, $D(\mathbf{x}, \mathbf{x}^-)) > D(\mathbf{x}, \mathbf{x}^+)$, where $D(.)$ is the cosine distance,

$$
D(\mathbf{x}_1, \mathbf{x}_2) = 1 - \frac{f(\mathbf{x}_1) f(\mathbf{x}_2)}{\|f(\mathbf{x}_1)\| \|f(\mathbf{x}_2\|)}
$$

损失函数为：

> The loss function is:

$$
\mathcal{L}(\mathbf{x}, \mathbf{x}^+, \mathbf{x}^-) 
= \max\big(0, D(\mathbf{x}, \mathbf{x}^+) - D(\mathbf{x}, \mathbf{x}^-) + M\big) + \text{weight decay regularization term}
$$

其中 $M$ 是一个标量常数，用于控制两个距离之间的最小间隙；论文中的 $M=0.5$。在最优情况下，损失函数强制执行 $D(\mathbf{x}, \mathbf{x}^-) >= D(\mathbf{x}, \mathbf{x}^+) + M$。

> where $M$ is a scalar constant controlling for the minimum gap between two distances; $M=0.5$ in the paper. The loss enforces $D(\mathbf{x}, \mathbf{x}^-) >= D(\mathbf{x}, \mathbf{x}^+) + M$ at the optimal case.

[https://lilianweng.github.io/posts/2019-11-10-self-supervised/#triplet-loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#triplet-loss)这种形式的损失函数也称为[三元组损失](https://arxiv.org/abs/1503.03832)在人脸识别任务中，数据集包含来自多个摄像角度的多个人的图像。令$\mathbf{x}^a$是特定人物的锚点图像，$\mathbf{x}^p$是同一人物从不同角度拍摄的正样本图像，$\mathbf{x}^n$是不同人物的负样本图像。在嵌入空间中，$\mathbf{x}^a$应该更接近$\mathbf{x}^p$而不是$\mathbf{x}^n$：

> [https://lilianweng.github.io/posts/2019-11-10-self-supervised/#triplet-loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#triplet-loss)This form of loss function is also known as [triplet loss](https://arxiv.org/abs/1503.03832) in the face recognition task, in which the dataset contains images of multiple people from multiple camera angles. Let $\mathbf{x}^a$ be an anchor image of a specific person, $\mathbf{x}^p$ be a positive image of this same person from a different angle and $\mathbf{x}^n$ be a negative image of a different person. In the embedding space, $\mathbf{x}^a$ should be closer to $\mathbf{x}^p$ than $\mathbf{x}^n$:

$$
\mathcal{L}_\text{triplet}(\mathbf{x}^a, \mathbf{x}^p, \mathbf{x}^n) = \max(0, \|\phi(\mathbf{x}^a) - \phi(\mathbf{x}^p) \|_2^2 -  \|\phi(\mathbf{x}^a) - \phi(\mathbf{x}^n) \|_2^2 + M)
$$

[https://lilianweng.github.io/posts/2019-11-10-self-supervised/#n-pair-loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#n-pair-loss)一种略有不同的三元组损失形式，名为[n-pair 损失](https://papers.nips.cc/paper/6200-improved-deep-metric-learning-with-multi-class-n-pair-loss-objective)，也常用于机器人任务中学习观测嵌入。有关更多相关内容，请参阅[后续章节](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#multi-view-metric-learning)。

> [https://lilianweng.github.io/posts/2019-11-10-self-supervised/#n-pair-loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#n-pair-loss)A slightly different form of the triplet loss, named [n-pair loss](https://papers.nips.cc/paper/6200-improved-deep-metric-learning-with-multi-class-n-pair-loss-objective) is also commonly used for learning observation embedding in robotics tasks. See a [later section](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#multi-view-metric-learning) for more related content.

![Overview of learning representation by tracking objects in videos. (a) Identify moving patches in short traces; (b) Feed two related patched and one random patch into a conv network with shared weights. (c) The loss function enforces the distance between related patches to be closer than the distance between random patches. (Image source: Wang & Gupta, 2015 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/tracking-videos.png)

通过两步无监督[光流](https://en.wikipedia.org/wiki/Optical_flow)方法跟踪和提取相关补丁：

> Relevant patches are tracked and extracted through a two-step unsupervised [optical flow](https://en.wikipedia.org/wiki/Optical_flow) approach:

1. 获取[SURF](https://www.vision.ee.ethz.ch/~surf/eccv06.pdf)兴趣点，并使用[IDT](https://hal.inria.fr/hal-00873267v2/document)来获取每个 SURF 点的运动。
2. 给定 SURF 兴趣点的轨迹，如果光流幅度大于 0.5 像素，则将这些点分类为移动点。

> • Obtain [SURF](https://www.vision.ee.ethz.ch/~surf/eccv06.pdf) interest points and use [IDT](https://hal.inria.fr/hal-00873267v2/document) to obtain motion of each SURF point.
> • Given the trajectories of SURF interest points, classify these points as moving if the flow magnitude is more than 0.5 pixels.

在训练期间，给定一对相关的图像块 $\mathbf{x}$ 和 $\mathbf{x}^+$，从同一批次中采样 $K$ 个随机图像块 $\{\mathbf{x}^-\}$，以形成 $K$ 个训练三元组。在几个 epoch 之后，应用 *难负样本挖掘*，使训练更困难、更高效，即搜索使损失最大化的随机图像块，并使用它们进行梯度更新。

> During training, given a pair of correlated patches $\mathbf{x}$ and $\mathbf{x}^+$, $K$ random patches $\{\mathbf{x}^-\}$ are sampled in this same batch to form $K$ training triplets. After a couple of epochs, *hard negative mining* is applied to make the training harder and more efficient, that is, to search for random patches that maximize the loss and use them to do gradient updates.

#### 帧序列

> Frame Sequence

视频帧自然地按时间顺序排列。研究人员提出了几种自监督任务，其动机是期望良好的表示应该学习帧的*正确序列*。

> Video frames are naturally positioned in chronological order. Researchers have proposed several self-supervised tasks, motivated by the expectation that good representation should learn the *correct sequence* of frames.

一个想法是**验证帧顺序**（[Misra, et al 2016](https://arxiv.org/abs/1603.08561)）。前置任务是确定视频中的帧序列是否按正确的时间顺序排列（“时间有效”）。模型需要跟踪并推断对象在帧间的小运动以完成此类任务。

> One idea is to **validate frame order** ([Misra, et al 2016](https://arxiv.org/abs/1603.08561)). The pretext task is to determine whether a sequence of frames from a video is placed in the correct temporal order (“temporal valid”). The model needs to track and reason about small motion of an object across frames to complete such a task.

训练帧从高运动窗口中采样。每次采样5帧$(f_a, f_b, f_c, f_d, f_e)$，且时间戳按顺序排列$a < b < c < d < e$。从5帧中，创建一个正元组$(f_b, f_c, f_d)$和两个负元组，$(f_b, f_a, f_d)$和$(f_b, f_e, f_d)$。参数$\tau_\max = \vert b-d \vert$控制正训练实例的难度（即，值越高 → 难度越大），参数$\tau_\min = \min(\vert a-b \vert, \vert d-e \vert)$控制负实例的难度（即，值越低 → 难度越大）。

> The training frames are sampled from high-motion windows. Every time 5 frames are sampled $(f_a, f_b, f_c, f_d, f_e)$ and the timestamps are in order $a < b < c < d < e$. Out of 5 frames, one positive tuple $(f_b, f_c, f_d)$ and two negative tuples, $(f_b, f_a, f_d)$ and $(f_b, f_e, f_d)$ are created. The parameter $\tau_\max = \vert b-d \vert$ controls the difficulty of positive training instances (i.e. higher → harder) and the parameter $\tau_\min = \min(\vert a-b \vert, \vert d-e \vert)$ controls the difficulty of negatives (i.e. lower → harder).

视频帧顺序验证的借口任务，在用作预训练步骤时，被证明可以提高动作识别下游任务的性能。

> The pretext task of video frame order validation is shown to improve the performance on the downstream task of action recognition when used as a pretraining step.

![Overview of learning representation by validating the order of video frames. (a) the data sample process; (b) the model is a triplet siamese network, where all input frames have shared weights. (Image source: Misra, et al 2016 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/frame-order-validation.png)

*O3N*（Odd-One-Out Network；[Fernando et al. 2017](https://arxiv.org/abs/1611.06646)）中的任务也基于视频帧序列验证。更进一步，该任务是从多个视频片段中**选出不正确的序列**。

> The task in *O3N* (Odd-One-Out Network; [Fernando et al. 2017](https://arxiv.org/abs/1611.06646)) is based on video frame sequence validation too. One step further from above, the task is to **pick the incorrect sequence** from multiple video clips.

给定$N+1$个输入视频片段，其中一个的帧被打乱了，因此顺序错误，而其余$N$个则保持正确的时序。O3N 学习预测异常视频片段的位置。在他们的实验中，有6个输入片段，每个包含6帧。

> Given $N+1$ input video clips, one of them has frames shuffled, thus in the wrong order, and the rest $N$ of them remain in the correct temporal order. O3N learns to predict the location of the odd video clip. In their experiments, there are 6 input clips and each contain 6 frames.

视频中的**时间之箭**包含非常丰富的信息，既有低级物理（例如，重力将物体拉向地面；烟雾上升；水向下流动），也有高级事件推理（例如，鱼向前游；你可以打碎一个鸡蛋但无法将其复原）。因此，受此启发，产生了另一个想法，即通过预测时间之箭（AoT）——视频是向前播放还是向后播放——来学习潜在表示（[Wei et al., 2018](https://www.robots.ox.ac.uk/~vgg/publications/2018/Wei18/wei18.pdf)）。

> The **arrow of time** in a video contains very informative messages, on both low-level physics (e.g. gravity pulls objects down to the ground; smoke rises up; water flows downward.) and high-level event reasoning (e.g. fish swim forward; you can break an egg but cannot revert it.). Thus another idea is inspired by this to learn latent representation by predicting the arrow of time (AoT) — whether video playing forwards or backwards ([Wei et al., 2018](https://www.robots.ox.ac.uk/~vgg/publications/2018/Wei18/wei18.pdf)).

分类器应捕获低级物理和高级语义，以预测时间之箭。所提出的*T-CAM*（时间类别激活图）网络接受$T$组，每组包含若干帧光流。来自每组的卷积层输出被连接起来，并输入到二元逻辑回归中，以预测时间之箭。

> A classifier should capture both low-level physics and high-level semantics in order to predict the arrow of time. The proposed *T-CAM* (Temporal Class-Activation-Map) network accepts $T$ groups, each containing a number of frames of optical flow. The conv layer outputs from each group are concatenated and fed into binary logistic regression for predicting the arrow of time.

![Overview of learning representation by predicting the arrow of time. (a) Conv features of multiple groups of frame sequences are concatenated. (b) The top level contains 3 conv layers and average pooling. (Image source: Wei et al, 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/learning-arrow-of-time.png)

有趣的是，数据集中存在一些人工线索。如果处理不当，它们可能导致一个不依赖实际视频内容的简单分类器：

> Interestingly, there exist a couple of artificial cues in the dataset. If not handled properly, they could lead to a trivial classifier without relying on the actual video content:

- 由于视频压缩，黑色边框可能并非完全是黑色，而是可能包含有关时间顺序的某些信息。因此，在实验中应移除黑色边框。
- 大幅度的摄像机运动，如垂直平移或放大/缩小，也为时间之箭提供了强烈的信号，但与内容无关。处理阶段应稳定摄像机运动。

> • Due to the video compression, the black framing might not be completely black but instead may contain certain information on the chronological order. Hence black framing should be removed in the experiments.
> • Large camera motion, like vertical translation or zoom-in/out, also provides strong signals for the arrow of time but independent of content. The processing stage should stabilize the camera motion.

AoT 预训练任务被证明在用作预训练步骤时，能提高动作分类下游任务的性能。请注意，仍然需要进行微调。

> The AoT pretext task is shown to improve the performance on action classification downstream task when used as a pretraining step. Note that fine-tuning is still needed.

#### 视频着色

> Video Colorization

[Vondrick 等人 (2018)](https://arxiv.org/abs/1806.09594) 提出了 **视频着色** 作为一种自监督学习问题，从而产生了一种丰富的表示，可用于视频分割和未标记视觉区域跟踪，*无需额外的微调*。

> [Vondrick et al. (2018)](https://arxiv.org/abs/1806.09594) proposed **video colorization** as a self-supervised learning problem, resulting in a rich representation that can be used for video segmentation and unlabelled visual region tracking, *without extra fine-tuning*.

与基于图像的[着色](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#colorization)不同，这里的任务是通过利用视频帧之间颜色的自然时间连贯性（因此这两个帧在时间上不应相距太远），将颜色从彩色正常参考帧复制到灰度目标帧。为了持续一致地复制颜色，模型被设计为学习跟踪不同帧中相关联的像素。

> Unlike the image-based [colorization](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#colorization), here the task is to copy colors from a normal reference frame in color to another target frame in grayscale by leveraging the natural temporal coherency of colors across video frames (thus these two frames shouldn’t be too far apart in time). In order to copy colors consistently, the model is designed to learn to keep track of correlated pixels in different frames.

![Video colorization by copying colors from a reference frame to target frames in grayscale.  (Image source: Vondrick et al. 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/video-colorization.png)

这个想法相当简单而巧妙。设$c_i$为$i-th$像素的真实颜色，$c_j$为$j$目标帧中第个像素的颜色。预测的$j$目标$\hat{c}_j$中第个颜色的预测值是参考帧中所有像素颜色的加权和，其中权重项衡量相似性：

> The idea is quite simple and smart. Let $c_i$ be the true color of the $i-th$ pixel in the reference frame and $c_j$ be the color of $j$ -th pixel in the target frame. The predicted color of $j$ -th color in the target $\hat{c}_j$ is a weighted sum of colors of all the pixels in reference, where the weighting term measures the similarity:

$$
\hat{c}_j = \sum_i A_{ij} c_i \text{ where } A_{ij} = \frac{\exp(f_i f_j)}{\sum_{i'} \exp(f_{i'} f_j)}
$$

其中 $f$ 是对应像素的学习嵌入；$i’$ 索引参考帧中的所有像素。加权项实现了一种基于注意力的指向机制，类似于[匹配网络](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#matching-networks)和[指针网络](https://lilianweng.github.io/posts/2018-06-24-attention/#pointer-network)。由于完整的相似性矩阵可能非常大，因此两个帧都进行了下采样。$c_j$ 和 $\hat{c}_j$ 之间的分类交叉熵损失与量化颜色一起使用，就像在[Zhang et al. 2016](https://arxiv.org/abs/1603.08511)中一样。

> where $f$ are learned embeddings for corresponding pixels; $i’$ indexes all the pixels in the reference frame. The weighting term implements an attention-based pointing mechanism, similar to [matching network](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#matching-networks) and [pointer network](https://lilianweng.github.io/posts/2018-06-24-attention/#pointer-network). As the full similarity matrix could be really large, both frames are downsampled. The categorical cross-entropy loss between $c_j$ and $\hat{c}_j$ is used with quantized colors, just like in [Zhang et al. 2016](https://arxiv.org/abs/1603.08511).

根据参考帧的标记方式，该模型可用于完成多项基于颜色的下游任务，例如跟踪分割或时间上的人体姿态。无需微调。参见

> Based on how the reference frame are marked, the model can be used to complete several color-based downstream tasks such as tracking segmentation or human pose in time. No fine-tuning is needed. See 

![Use video colorization to track object segmentation and human pose in time. (Image source: Vondrick et al. (2018) )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/video-colorization-examples.png)

> 一些常见的观察结果：
>
> • 结合多个前置任务可以提高性能；
> • 更深的网络可以提高表示的质量；
> • 监督学习基线仍然远远超过所有这些方法。

> A couple common observations:
>
> • Combining multiple pretext tasks improves performance;
> • Deeper networks improve the quality of representation;
> • Supervised learning baselines still beat all of them by far.

### 基于控制

> Control-Based

在现实世界中运行强化学习策略时，例如通过视觉输入控制物理机器人，要正确跟踪状态、获取奖励信号或确定目标是否真正实现并非易事。视觉数据中存在大量与真实状态无关的噪声，因此无法通过像素级比较推断状态的等价性。自监督表示学习在学习有用的状态嵌入方面展现出巨大潜力，这些嵌入可以直接用作控制策略的输入。

> When running a RL policy in the real world, such as controlling a physical robot on visual inputs, it is non-trivial to properly track states, obtain reward signals or determine whether a goal is achieved for real. The visual data has a lot of noise that is irrelevant to the true state and thus the equivalence of states cannot be inferred from pixel-level comparison. Self-supervised representation learning has shown great potential in learning useful state embedding that can be used directly as input to a control policy.

本节讨论的所有案例都属于机器人学习领域，主要用于从多个摄像机视图中进行状态表示和目标表示。

> All the cases discussed in this section are in robotic learning, mainly for state representation from multiple camera views and goal representation.

#### 多视图度量学习

> Multi-View Metric Learning

度量学习的概念在[前面](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss)的[章节](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#tracking)中已被多次提及。一个常见的设置是：给定一个样本三元组（*锚点* $s_a$、*正样本* $s_p$、*负样本* $s_n$），学习到的表示嵌入$\phi(s)$满足$s_a$在潜在空间中与$s_p$保持接近，但与$s_n$保持远离。

> The concept of metric learning has been mentioned multiple times in the [previous](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#counting-feature-loss) [sections](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#tracking). A common setting is: Given a triple of samples, (*anchor* $s_a$, *positive* sample $s_p$, *negative* sample $s_n$), the learned representation embedding $\phi(s)$ fulfills that $s_a$ stays close to $s_p$ but far away from $s_n$ in the latent space.

[https://lilianweng.github.io/posts/2019-11-10-self-supervised/#grasp2vec](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#grasp2vec)**Grasp2Vec**（[Jang & Devin et al., 2018](https://arxiv.org/abs/1811.06964)）旨在从自由、未标记的抓取活动中，在机器人抓取任务中学习以物体为中心的视觉表示。以物体为中心意味着，无论环境或机器人看起来如何，如果两张图像包含相似的物体，它们应该被映射到相似的表示；否则，嵌入应该相距很远。

> [https://lilianweng.github.io/posts/2019-11-10-self-supervised/#grasp2vec](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#grasp2vec)**Grasp2Vec** ([Jang & Devin et al., 2018](https://arxiv.org/abs/1811.06964)) aims to learn an object-centric vision representation in the robot grasping task from free, unlabelled grasping activities. By object-centric, it means that, irrespective of how the environment or the robot looks like, if two images contain similar items, they should be mapped to similar representation; otherwise the embeddings should be far apart.

![A conceptual illustration of how grasp2vec learns an object-centric state embedding. (Image source: Jang & Devin et al., 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/grasp2vec.png)

抓取系统可以判断它是否移动了一个物体，但无法判断是哪个物体。相机被设置用于拍摄整个场景和被抓取物体的图像。在早期训练中，抓取机器人被执行以随机抓取任何物体$o$，生成一个图像三元组$(s_\text{pre}, s_\text{post}, o)$：

> The grasping system can tell whether it moves an object but cannot tell which object it is. Cameras are set up to take images of the entire scene and the grasped object. During early training, the grasp robot is executed to grasp any object $o$ at random, producing a triple of images, $(s_\text{pre}, s_\text{post}, o)$:

• $o$ 是抓取物体举向相机的图像；

• $s_\text{pre}$ 是抓取*之前*的场景图像，物体 $o$ 在托盘中；

• $s_\text{post}$ 是抓取*之后*的同一场景图像，没有物体 $o$ 在托盘中。

英文原文：

• $o$ is an image of the grasped object held up to the camera;

• $s_\text{pre}$ is an image of the scene *before* grasping, with the object $o$ in the tray;

• $s_\text{post}$ is an image of the same scene *after* grasping, without the object $o$ in the tray.

为了学习以对象为中心的表示，我们期望 $s_\text{pre}$ 和 $s_\text{post}$ 的嵌入之间的差异能够捕获被移除的对象 $o$。这个想法非常有趣，类似于在 [词嵌入](https://lilianweng.github.io/posts/2017-10-15-word-embedding/) 中观察到的关系，[例如](https://developers.google.com/machine-learning/crash-course/embeddings/translating-to-a-lower-dimensional-space) distance(“king”, “queen”) ≈ distance(“man”, “woman”)。

> To learn object-centric representation, we expect the difference between embeddings of $s_\text{pre}$ and $s_\text{post}$ to capture the removed object $o$. The idea is quite interesting and similar to relationships that have been observed in [word embedding](https://lilianweng.github.io/posts/2017-10-15-word-embedding/), [e.g.](https://developers.google.com/machine-learning/crash-course/embeddings/translating-to-a-lower-dimensional-space) distance(“king”, “queen”) ≈ distance(“man”, “woman”).

设 $\phi_s$ 和 $\phi_o$ 分别为场景和对象的嵌入函数。模型通过最小化 $\phi_s(s_\text{pre}) - \phi_s(s_\text{post})$ 和 $\phi_o(o)$ 之间的距离来学习表示，使用*n-pair loss*：

> Let $\phi_s$ and $\phi_o$ be the embedding functions for the scene and the object respectively. The model learns the representation by minimizing the distance between $\phi_s(s_\text{pre}) - \phi_s(s_\text{post})$ and $\phi_o(o)$ using *n-pair loss*:

$$
\begin{aligned}
\mathcal{L}_\text{grasp2vec} &= \text{NPair}(\phi_s(s_\text{pre}) - \phi_s(s_\text{post}), \phi_o(o)) + \text{NPair}(\phi_o(o), \phi_s(s_\text{pre}) - \phi_s(s_\text{post})) \\
\text{where }\text{NPair}(a, p) &= \sum_{i<{B}} -\log\frac{\exp(a_i^\top p_j)}{\sum_{j<{B}, i\neq j}\exp(a_i^\top p_j)} + \lambda (\|a_i\|_2^2 + \|p_i\|_2^2)
\end{aligned}
$$

其中 $B$ 指代一批（锚点，正例）样本对。

> where $B$ refers to a batch of (anchor, positive) sample pairs.

当将表示学习视为度量学习时，[n-pair loss](https://papers.nips.cc/paper/6200-improved-deep-metric-learning-with-multi-class-n-pair-loss-objective)是一种常见的选择。n-pair loss 不会显式处理（锚点、正样本、负样本）三元组，而是将一个 mini-batch 中所有其他正样本实例视为负样本。

> When framing representation learning as metric learning, [n-pair loss](https://papers.nips.cc/paper/6200-improved-deep-metric-learning-with-multi-class-n-pair-loss-objective) is a common choice. Rather than processing explicit a triple of (anchor, positive, negative) samples, the n-pairs loss treats all other positive instances in one mini-batch across pairs as negatives.

嵌入函数$\phi_o$非常适合用图像呈现目标$g$。量化实际抓取的物体$o$与目标接近程度的奖励函数定义为$r = \phi_o(g) \cdot \phi_o(o)$。请注意，奖励计算仅依赖于学习到的潜在空间，不涉及真实位置，因此可用于真实机器人的训练。

> The embedding function $\phi_o$ works great for presenting a goal $g$ with an image. The reward function that quantifies how close the actually grasped object $o$ is close to the goal is defined as $r = \phi_o(g) \cdot \phi_o(o)$. Note that computing rewards only relies on the learned latent space and doesn’t involve ground truth positions, so it can be used for training on real robots.

![Localization results of grasp2vec embedding. The heatmap of localizing a goal object in a pre-grasping scene is defined as $\phi\_o(o)^\top \phi\_{s, \text{spatial}} (s\_\text{pre})$, where $\phi\_{s, \text{spatial}}$ is the output of the last resnet block after ReLU. The fourth column is a failure case and the last three columns take real images as goals. (Image source: Jang & Devin et al., 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/grasp2vec-attention-map.png)

除了基于嵌入相似度的奖励函数之外，在 grasp2vec 框架中训练 RL 策略还有一些其他技巧：

> Other than the embedding-similarity-based reward function, there are a few other tricks for training the RL policy in the grasp2vec framework:

• *事后标记*：通过将随机抓取的物体标记为正确目标来扩充数据集，类似于 HER（Hindsight Experience Replay；[Andrychowicz, et al., 2017](https://papers.nips.cc/paper/7090-hindsight-experience-replay.pdf)）。

• *辅助目标增强*：通过用未实现的目标重新标记转换来进一步增强重放缓冲区；具体来说，在每次迭代中，采样两个目标 $(g, g’)$，并且这两个目标都用于向重放缓冲区添加新的转换。

英文原文：

• *Posthoc labeling*: Augment the dataset by labeling a randomly grasped object as a correct goal, like HER (Hindsight Experience Replay; [Andrychowicz, et al., 2017](https://papers.nips.cc/paper/7090-hindsight-experience-replay.pdf)).

• *Auxiliary goal augmentation*: Augment the replay buffer even further by relabeling transitions with unachieved goals; precisely, in each iteration, two goals are sampled $(g, g’)$ and both are used to add new transitions into replay buffer.

[https://lilianweng.github.io/posts/2019-11-10-self-supervised/#tcn](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#tcn)**TCN** (**时间对比网络**; [Sermanet, et al. 2018](https://arxiv.org/abs/1704.06888)) 从多摄像头视角视频中学习，其直觉是同一场景在同一时间步的不同视角应该共享相同的嵌入（如在 [FaceNet](https://arxiv.org/abs/1503.03832) 中），而嵌入应该随时间变化，即使是同一摄像头视角也是如此。因此，嵌入捕获的是底层状态的语义含义，而不是视觉相似性。TCN 嵌入使用 [三元组损失](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#triplet-loss) 进行训练。

> [https://lilianweng.github.io/posts/2019-11-10-self-supervised/#tcn](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#tcn)**TCN** (**Time-Contrastive Networks**; [Sermanet, et al. 2018](https://arxiv.org/abs/1704.06888)) learn from multi-camera view videos with the intuition that different viewpoints at the same timestep of the same scene should share the same embedding (like in [FaceNet](https://arxiv.org/abs/1503.03832)) while embedding should vary in time, even of the same camera viewpoint. Therefore embedding captures the semantic meaning of the underlying state rather than visual similarity. The TCN embedding is trained with [triplet loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#triplet-loss).

训练数据是通过同时从不同角度拍摄同一场景的视频来收集的。所有视频都是未标注的。

> The training data is collected by taking videos of the same scene simultaneously but from different angles. All the videos are unlabelled.

![An illustration of time-contrastive approach for learning state embedding. The blue frames selected from two camera views at the same timestep are anchor and positive samples, while the red frame at a different timestep is the negative sample.](https://lilianweng.github.io/posts/2019-11-10-self-supervised/TCN.png)

TCN 嵌入提取对相机配置不变的视觉特征。它可以用于根据演示视频与潜在空间中观测值之间的欧几里得距离，为模仿学习构建奖励函数。

> TCN embedding extracts visual features that are invariant to camera configurations. It can be used to construct a reward function for imitation learning based on the euclidean distance between the demo video and the observations in the latent space.

TCN 的进一步改进是联合学习多帧而不是单帧的嵌入，从而产生了 **mfTCN**（**多帧时间对比网络**；[Dwibedi et al., 2019](https://arxiv.org/abs/1808.00928)）。给定一组来自多个同步摄像机视角的视频，$v_1, v_2, \dots, v_k$，每个视频中时间点 `t` 的帧以及以步长 $n-1$ 选择的前 `s` 帧被聚合并映射到一个嵌入向量中，从而形成大小为 $(n−1) \times s + 1$ 的回溯窗口。每个帧首先通过一个 CNN 来提取低级特征，然后我们使用 3D 时间卷积来在时间上聚合帧。该模型使用 [n-pairs loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#n-pair-loss) 进行训练。

英文原文：A further improvement over TCN is to learn embedding over multiple frames jointly rather than a single frame, resulting in mfTCN (Multi-frame Time-Contrastive Networks; [Dwibedi et al., 2019](https://arxiv.org/abs/1808.00928)). Given a set of videos from several synchronized camera viewpoints, 

$v_1, v_2, \dots, v_k$, the frame at time `t` and the previous 

$n-1$ frames selected with stride `s` in each video are aggregated and mapped into one embedding vector, resulting in a lookback window of size 

$(n−1) \times s + 1$. Each frame first goes through a CNN to extract low-level features and then we use 3D temporal convolutions to aggregate frames in time. The model is trained with [n-pairs loss](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#n-pair-loss).

![The sampling process for training mfTCN. (Image source: Dwibedi et al., 2019 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/mfTCN.png)

训练数据采样如下：

> The training data is sampled as follows:

1. 首先，我们构建两对视频片段。每对包含来自不同摄像机视角但时间步同步的两个片段。这两组视频在时间上应该相距很远。
2. 从同一对中的每个视频片段中，以相同的步长同时采样固定数量的帧。
3. 具有相同时间步的帧在n-pair损失中作为正样本进行训练，而跨对的帧则作为负样本。

> • First we construct two pairs of video clips. Each pair contains two clips from different camera views but with synchronized timesteps. These two sets of videos should be far apart in time.
> • Sample a fixed number of frames from each video clip in the same pair simultaneously with the same stride.
> • Frames with the same timesteps are trained as positive samples in the n-pair loss, while frames across pairs are negative samples.

mfTCN嵌入可以捕获场景中物体的位置和速度（例如在cartpole中），并且也可以用作策略的输入。

> mfTCN embedding can capture the position and velocity of objects in the scene (e.g. in cartpole) and can also be used as inputs for policy.

#### 自主目标生成

> Autonomous Goal Generation

**RIG** (**基于想象目标的强化学习**; [Nair et al., 2018](https://arxiv.org/abs/1807.04742)) 描述了一种通过无监督表征学习来训练目标条件策略的方法。策略通过首先设想“虚假”目标，然后尝试实现这些目标，从而从自监督实践中学习。

> **RIG** (**Reinforcement learning with Imagined Goals**; [Nair et al., 2018](https://arxiv.org/abs/1807.04742)) described a way to train a goal-conditioned policy with unsupervised representation learning. A policy learns from self-supervised practice by first imagining “fake” goals and then trying to achieve them.

![The workflow of RIG. (Image source: Nair et al., 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/RIG.png)

任务是控制机械臂将桌上的小冰球推到目标位置。目标位置（即目标）呈现在图像中。在训练期间，它学习状态的潜在嵌入$s$和目标$g$通过$\beta$ -VAE 编码器，并且控制策略完全在潜在空间中运行。

> The task is to control a robot arm to push a small puck on a table to a desired position. The desired position, or the goal, is present in an image. During training, it learns latent embedding of both state $s$ and goal $g$ through $\beta$ -VAE encoder and the control policy operates entirely in the latent space.

假设一个 [\beta-VAE](https://lilianweng.github.io/posts/2018-08-12-vae/#beta-vae) 有一个编码器 $q_\phi$ 将输入状态映射到潜在变量 $z$，该变量由高斯分布建模，还有一个解码器 $p_\psi$ 将 $z$ 映射回状态。RIG 中的状态编码器被设置为 $\beta$ -VAE 编码器的均值。

> Let’s say a [\beta-VAE](https://lilianweng.github.io/posts/2018-08-12-vae/#beta-vae) has an encoder $q_\phi$ mapping input states to latent variable $z$ which is modeled by a Gaussian distribution and a decoder $p_\psi$ mapping $z$ back to the states. The state encoder in RIG is set to be the mean of $\beta$ -VAE encoder.

$$
\begin{aligned}
z &\sim q_\phi(z \vert s) = \mathcal{N}(z; \mu_\phi(s), \sigma^2_\phi(s)) \\
\mathcal{L}_{\beta\text{-VAE}} &= - \mathbb{E}_{z \sim q_\phi(z \vert s)} [\log p_\psi (s \vert z)] + \beta D_\text{KL}(q_\phi(z \vert s) \| p_\psi(s)) \\
e(s) &\triangleq \mu_\phi(s)
\end{aligned}
$$

奖励是状态和目标嵌入向量之间的欧几里得距离：$r(s, g) = -|e(s) - e(g)|$。类似于 [grasp2vec](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#grasp2vec)，RIG 也通过潜在目标重标记应用数据增强：精确地一半目标是从先验中随机生成的，另一半是使用 HER 选择的。同样与 grasp2vec 相同，奖励不依赖于任何真实状态，而只依赖于学习到的状态编码，因此它可以用于真实机器人的训练。

> The reward is the Euclidean distance between state and goal embedding vectors: $r(s, g) = -|e(s) - e(g)|$. Similar to [grasp2vec](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#grasp2vec), RIG applies data augmentation as well by latent goal relabeling: precisely half of the goals are generated from the prior at random and the other half are selected using HER. Also same as grasp2vec, rewards do not depend on any ground truth states but only the learned state encoding, so it can be used for training on real robots.

![The algorithm of RIG. (Image source: Nair et al., 2018 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/RIG-algorithm.png)

RIG 的问题在于想象的目标图片中缺少物体变化。如果 `\beta` -VAE 只用一个黑色冰球进行训练，它将无法创建包含其他物体（如不同形状和颜色的积木）的目标。后续的改进是用 **CC-VAE**（上下文条件 VAE；[Nair 等人，2019](https://arxiv.org/abs/1910.11670)）取代 `\beta` -VAE 来生成目标，其灵感来源于 **CVAE**（条件 VAE；[Sohn, Lee & Yan, 2015](https://papers.nips.cc/paper/5775-learning-structured-output-representation-using-deep-conditional-generative-models)）。

英文原文：The problem with RIG is a lack of object variations in the imagined goal pictures. If `\beta` -VAE is only trained with a black puck, it would not be able to create a goal with other objects like blocks of different shapes and colors. A follow-up improvement replaces `\beta` -VAE with a CC-VAE (Context-Conditioned VAE; [Nair, et al., 2019](https://arxiv.org/abs/1910.11670)), inspired by CVAE (Conditional VAE; [Sohn, Lee & Yan, 2015](https://papers.nips.cc/paper/5775-learning-structured-output-representation-using-deep-conditional-generative-models)), for goal generation.

![The workflow of context-conditioned RIG. (Image source: Nair, et al., 2019 ).](https://lilianweng.github.io/posts/2019-11-10-self-supervised/CC-RIG.png)

CVAE 以上下文变量 $c$ 为条件。它训练一个编码器 $q_\phi(z \vert s, c)$ 和一个解码器 $p_\psi (s \vert z, c)$，并且两者都可以访问 $c$。CVAE 损失惩罚从输入状态 $s$ 通过信息瓶颈传递的信息，但允许从 $c$ 到编码器和解码器进行 *无限制的* 信息流。

> A CVAE conditions on a context variable $c$. It trains an encoder $q_\phi(z \vert s, c)$ and a decoder $p_\psi (s \vert z, c)$ and note that both have access to $c$. The CVAE loss penalizes information passing from the input state $s$ through an information bottleneck but allows for *unrestricted* information flow from $c$ to both encoder and decoder.

$$
\mathcal{L}_\text{CVAE} = - \mathbb{E}_{z \sim q_\phi(z \vert s,c)} [\log p_\psi (s \vert z, c)] + \beta D_\text{KL}(q_\phi(z \vert s, c) \| p_\psi(s))
$$

为了创建合理的目标，CC-VAE 以起始状态 $s_0$ 为条件，以便生成的目标呈现与 $s_0$ 中一致的物体类型。这种目标一致性是必要的；例如，如果当前场景包含一个红色冰球，但目标是一个蓝色积木，这会使策略感到困惑。

> To create plausible goals, CC-VAE conditions on a starting state $s_0$ so that the generated goal presents a consistent type of object as in $s_0$. This goal consistency is necessary; e.g. if the current scene contains a red puck but the goal has a blue block, it would confuse the policy.

除了状态编码器 $e(s) \triangleq \mu_\phi(s)$，CC-VAE 还训练第二个卷积编码器 $e_0(.)$，将起始状态 $s_0$ 转换为紧凑的上下文表示 $c = e_0(s_0)$。两个编码器 $e(.)$ 和 $e_0(.)$ 被有意设计为不同且不共享权重，因为它们预期编码图像变化的不同因素。除了 CVAE 的损失函数外，CC-VAE 还添加了一个额外项，以学习将 $c$ 重构回 $s_0$，$\hat{s}_0 = d_0(c)$。

> Other than the state encoder $e(s) \triangleq \mu_\phi(s)$, CC-VAE trains a second convolutional encoder $e_0(.)$ to translate the starting state $s_0$ into a compact context representation $c = e_0(s_0)$. Two encoders, $e(.)$ and $e_0(.)$, are intentionally different without shared weights, as they are expected to encode different factors of image variation. In addition to the loss function of CVAE, CC-VAE adds an extra term to learn to reconstruct $c$ back to $s_0$, $\hat{s}_0 = d_0(c)$.

$$
\mathcal{L}_\text{CC-VAE} = \mathcal{L}_\text{CVAE} + \log p(s_0\vert c)
$$

![Examples of imagined goals generated by CVAE that conditions on the context image (the first row), while VAE fails to capture the object consistency. (Image source: Nair, et al., 2019 ).](https://lilianweng.github.io/posts/2019-11-10-self-supervised/CC-RIG-goal-samples.png)

#### Bisimulation

> Bisimulation

任务无关表示（例如，旨在表示系统中所有动态的模型）可能会分散强化学习算法的注意力，因为也会呈现不相关的信息。例如，如果我们只训练一个自编码器来重建输入图像，则无法保证整个学习到的表示对强化学习有用。因此，如果我们只想学习与控制相关的信息，就需要摆脱基于重建的表示学习，因为不相关的细节对于重建仍然很重要。

> Task-agnostic representation (e.g. a model that intends to represent all the dynamics in the system) may distract the RL algorithms as irrelevant information is also presented. For example, if we just train an auto-encoder to reconstruct the input image, there is no guarantee that the entire learned representation will be useful for RL. Therefore, we need to move away from reconstruction-based representation learning if we only want to learn information relevant to control, as irrelevant details are still important for reconstruction.

基于 Bisimulation 的控制表示学习不依赖于重建，而是旨在根据 MDP 中状态的行为相似性对状态进行分组。

> Representation learning for control based on bisimulation does not depend on reconstruction, but aims to group states based on their behavioral similarity in MDP.

**Bisimulation**（[Givan 等人，2003](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.61.2493&rep=rep1&type=pdf)）指的是两个具有相似长期行为的状态之间的等价关系。*Bisimulation 度量* 量化了这种关系，以便我们可以聚合状态，将高维状态空间压缩成更小的空间，从而实现更高效的计算。两个状态之间的 *bisimulation 距离* 对应于这两个状态在行为上的差异程度。

> **Bisimulation** ([Givan et al. 2003](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.61.2493&rep=rep1&type=pdf)) refers to an equivalence relation between two states with similar long-term behavior. *Bisimulation metrics* quantify such relation so that we can aggregate states to compress a high-dimensional state space into a smaller one for more efficient computation. The *bisimulation distance* between two states corresponds to how behaviorally different these two states are.

给定一个 [MDP](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#markov-decision-processes) $\mathcal{M} = \langle \mathcal{S}, \mathcal{A}, \mathcal{P}, \mathcal{R}, \gamma \rangle$ 和一个 bisimulation 关系 $B$，在关系 $B$ 下相等的两个状态（即 $s_i B s_j$）应该对所有动作具有相同的即时奖励，并且在下一个 bisimilar 状态上具有相同的转移概率：

> Given a [MDP](https://lilianweng.github.io/posts/2018-02-19-rl-overview/#markov-decision-processes) $\mathcal{M} = \langle \mathcal{S}, \mathcal{A}, \mathcal{P}, \mathcal{R}, \gamma \rangle$ and a bisimulation relation $B$, two states that are equal under relation $B$ (i.e. $s_i B s_j$) should have the same immediate reward for all actions and the same transition probabilities over the next bisimilar states:

$$
\begin{aligned}
\mathcal{R}(s_i, a) &= \mathcal{R}(s_j, a) \; \forall a \in \mathcal{A} \\
\mathcal{P}(G \vert s_i, a) &= \mathcal{P}(G \vert s_j, a) \; \forall a \in \mathcal{A} \; \forall G \in \mathcal{S}_B
\end{aligned}
$$

其中 $\mathcal{S}_B$ 是关系 $B$ 下状态空间的一个划分。

> where $\mathcal{S}_B$ is a partition of the state space under the relation $B$.

请注意，$=$ 始终是一个 bisimulation 关系。最有趣的是最大 bisimulation 关系 $\sim$，它定义了一个具有 *最少* 状态组的划分 $\mathcal{S}_\sim$。

> Note that $=$ is always a bisimulation relation. The most interesting one is the maximal bisimulation relation $\sim$, which defines a partition $\mathcal{S}_\sim$ with *fewest* groups of states.

![DeepMDP learns a latent space model by minimizing two losses on a reward model and a dynamics model. (Image source: Gelada, et al. 2019 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/DeepMDP.png)

目标与 bisimulation 度量相似，**DeepMDP**（[Gelada 等人，2019](https://arxiv.org/abs/1906.02736)）通过最小化两个损失来简化强化学习任务中的高维观测并学习一个潜在空间模型：

> With a goal similar to bisimulation metric, **DeepMDP** ([Gelada, et al. 2019](https://arxiv.org/abs/1906.02736)) simplifies high-dimensional observations in RL tasks and learns a latent space model via minimizing two losses:

1. 奖励预测和
2. 下一个潜在状态分布的预测。

> • prediction of rewards and
> • prediction of the distribution over next latent states.

$$
\begin{aligned}
\mathcal{L}_{\bar{\mathcal{R}}}(s, a) = \vert \mathcal{R}(s, a) - \bar{\mathcal{R}}(\phi(s), a) \vert \\
\mathcal{L}_{\bar{\mathcal{P}}}(s, a) = D(\phi \mathcal{P}(s, a), \bar{\mathcal{P}}(. \vert \phi(s), a))
\end{aligned}
$$

其中 $\phi(s)$ 是状态 $s$ 的嵌入；带横线的符号是同一 MDP 中的函数（奖励函数 $R$ 和转移函数 $P$），但在潜在的低维观测空间中运行。这里的嵌入表示 $\phi$ 可以与 bisimulation 度量联系起来，因为 bisimulation 距离被证明受潜在空间中 L2 距离的上限约束。

> where $\phi(s)$ is the embedding of state $s$; symbols with bar are functions (reward function $R$ and transition function $P$) in the same MDP but running in the latent low-dimensional observation space. Here the embedding representation $\phi$ can be connected to bisimulation metrics, as the bisimulation distance is proved to be upper-bounded by the L2 distance in the latent space.

函数 $D$ 量化了两个概率分布之间的距离，应仔细选择。DeepMDP 专注于 *Wasserstein-1* 度量（也称为 [“推土机距离”](https://lilianweng.github.io/posts/2017-08-20-gan/#what-is-wasserstein-distance)）。分布 $P$ 和 $Q$ 在度量空间 $(M, d)$（即 $d: M \times M \to \mathbb{R}$）上的 Wasserstein-1 距离为：

> The function $D$ quantifies the distance between two probability distributions and should be chosen carefully. DeepMDP focuses on *Wasserstein-1* metric (also known as [“earth-mover distance”](https://lilianweng.github.io/posts/2017-08-20-gan/#what-is-wasserstein-distance)). The Wasserstein-1 distance between distributions $P$ and $Q$ on a metric space $(M, d)$ (i.e., $d: M \times M \to \mathbb{R}$) is:

$$
W_d (P, Q) = \inf_{\lambda \in \Pi(P, Q)} \int_{M \times M} d(x, y) \lambda(x, y) \; \mathrm{d}x \mathrm{d}y
$$

其中 $\Pi(P, Q)$ 是 $P$ 和 $Q$ 的所有 [耦合](https://en.wikipedia.org/wiki/Coupling_(probability)) 的集合。$d(x, y)$ 定义了将粒子从点 $x$ 移动到点 $y$ 的成本。

> where $\Pi(P, Q)$ is the set of all [couplings](https://en.wikipedia.org/wiki/Coupling_(probability)) of $P$ and $Q$. $d(x, y)$ defines the cost of moving a particle from point $x$ to point $y$.

根据 Monge-Kantorovich 对偶性，Wasserstein 度量具有对偶形式：

> The Wasserstein metric has a dual form according to the Monge-Kantorovich duality:

$$
W_d (P, Q) = \sup_{f \in \mathcal{F}_d} \vert \mathbb{E}_{x \sim P} f(x) - \mathbb{E}_{y \sim Q} f(y) \vert
$$

其中 $\mathcal{F}_d$ 是在度量 $d$ - $\mathcal{F}_d = \{ f: \vert f(x) - f(y) \vert \leq d(x, y) \}$ 下的 1-Lipschitz 函数的集合。

> where $\mathcal{F}_d$ is the set of 1-Lipschitz functions under the metric $d$ - $\mathcal{F}_d = \{ f: \vert f(x) - f(y) \vert \leq d(x, y) \}$.

DeepMDP 将模型推广到范数最大均值差异（Norm-[MMD](https://en.wikipedia.org/wiki/Kernel_embedding_of_distributions#Measuring_distance_between_distributions)）度量，以提高其深度值函数边界的紧密性，同时节省计算（Wasserstein 计算成本高昂）。在他们的实验中，他们发现转移预测模型的模型架构对性能有很大影响。在训练无模型强化学习智能体时，将这些 DeepMDP 损失作为辅助损失可以显著改善大多数 Atari 游戏的性能。

> DeepMDP generalizes the model to the Norm Maximum Mean Discrepancy (Norm-[MMD](https://en.wikipedia.org/wiki/Kernel_embedding_of_distributions#Measuring_distance_between_distributions)) metrics to improve the tightness of the bounds of its deep value function and, at the same time, to save computation (Wasserstein is expensive computationally). In their experiments, they found the model architecture of the transition prediction model can have a big impact on the performance. Adding these DeepMDP losses as auxiliary losses when training model-free RL agents leads to good improvement on most of the Atari games.

**用于控制的深度双模拟**（简称**DBC**；[Zhang et al. 2020](https://arxiv.org/abs/2006.10742)）学习对强化学习任务中对控制有益的观测的潜在表示，无需领域知识或像素级重建。

> **Deep Bisimulatioin for Control** (short for **DBC**; [Zhang et al. 2020](https://arxiv.org/abs/2006.10742)) learns the latent representation of observations that are good for control in RL tasks, without domain knowledge or pixel-level reconstruction.

![The Deep Bisimulation for Control algorithm learns a bisimulation metric representation via learning a reward model and a dynamics model. The model architecture is a siamese network. (Image source: Zhang et al. 2020 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/DBC-illustration.png)

与DeepMDP类似，DBC通过学习奖励模型和转移模型来建模动力学。这两个模型都在潜在空间中运行，$\phi(s)$。嵌入$\phi$的优化取决于[Ferns, et al. 2004](https://arxiv.org/abs/1207.4114)（定理4.5）和[Ferns, et al 2011](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.295.2114&rep=rep1&type=pdf)（定理2.6）的一个重要结论：

> Similar to DeepMDP, DBC models the dynamics by learning a reward model and a transition model. Both models operate in the latent space, $\phi(s)$. The optimization of embedding $\phi$ depends on one important conclusion from [Ferns, et al. 2004](https://arxiv.org/abs/1207.4114) (Theorem 4.5) and [Ferns, et al 2011](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.295.2114&rep=rep1&type=pdf) (Theorem 2.6):

引用译文：

给定$c \in (0, 1)$一个折扣因子，$\pi$一个正在持续改进的策略，以及$M$状态空间$\mathcal{S}$上有界[伪度量](https://mathworld.wolfram.com/Pseudometric.html)的空间，我们可以定义$\mathcal{F}: M \mapsto M$：

$$
\mathcal{F}(d; \pi)(s_i, s_j) = (1-c) \vert \mathcal{R}_{s_i}^\pi - \mathcal{R}_{s_j}^\pi \vert + c W_d (\mathcal{P}_{s_i}^\pi, \mathcal{P}_{s_j}^\pi)
$$

那么，$\mathcal{F}$有一个唯一的固定点$\tilde{d}$，它是一个$\pi^{\ast}$ -双模拟度量，并且$\tilde{d}(s_i, s_j) = 0 \iff s_i \sim s_j$。

英文原文：

Given $c \in (0, 1)$ a discounting factor, $\pi$ a policy that is being improved continuously, and $M$ the space of bounded [pseudometric](https://mathworld.wolfram.com/Pseudometric.html) on the state space $\mathcal{S}$, we can define $\mathcal{F}: M \mapsto M$:

$$
\mathcal{F}(d; \pi)(s_i, s_j) = (1-c) \vert \mathcal{R}_{s_i}^\pi - \mathcal{R}_{s_j}^\pi \vert + c W_d (\mathcal{P}_{s_i}^\pi, \mathcal{P}_{s_j}^\pi)
$$

Then, $\mathcal{F}$ has a unique fixed point $\tilde{d}$ which is a $\pi^{\ast}$ -bisimulation metric and $\tilde{d}(s_i, s_j) = 0 \iff s_i \sim s_j$.

[证明并非微不足道。我将来可能会也可能不会添加它 _(:3」∠)_ …]

> [The proof is not trivial. I may or may not add it in the future  _(:3」∠)_ …]

给定成批的观测对，$\phi$、$J(\phi)$的训练损失最小化了策略内双模拟度量与潜在空间中欧几里得距离之间的均方误差：

> Given batches of observations pairs, the training loss for $\phi$, $J(\phi)$, minimizes the mean square error between the on-policy bisimulation metric and Euclidean distance in the latent space:

$$
J(\phi) = \Big( \|\phi(s_i) - \phi(s_j)\|_1 - \vert \hat{\mathcal{R}}(\bar{\phi}(s_i)) - \hat{\mathcal{R}}(\bar{\phi}(s_j)) \vert - \gamma W_2(\hat{\mathcal{P}}(\cdot \vert \bar{\phi}(s_i), \bar{\pi}(\bar{\phi}(s_i))), \hat{\mathcal{P}}(\cdot \vert \bar{\phi}(s_j), \bar{\pi}(\bar{\phi}(s_j)))) \Big)^2
$$

其中$\bar{\phi}(s)$表示带有停止梯度的$\phi(s)$，$\bar{\pi}$是平均策略输出。学习到的奖励模型$\hat{\mathcal{R}}$是确定性的，学习到的前向动力学模型$\hat{\mathcal{P}}$输出一个高斯分布。

> where $\bar{\phi}(s)$ denotes $\phi(s)$ with stop gradient and $\bar{\pi}$ is the mean policy output. The learned reward model $\hat{\mathcal{R}}$ is deterministic and the learned forward dynamics model $\hat{\mathcal{P}}$ outputs a Gaussian distribution.

DBC基于SAC，但在潜在空间中操作：

> DBC is based on SAC but operates on the latent space:

![The algorithm of Deep Bisimulation for Control. (Image source: Zhang et al. 2020 )](https://lilianweng.github.io/posts/2019-11-10-self-supervised/DBC-algorithm.png)

引用方式：

> Cited as:

```
@article{weng2019selfsup,
  title   = "Self-Supervised Representation Learning",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2019",
  url     = "https://lilianweng.github.io/posts/2019-11-10-self-supervised/"
}
```

### 参考文献

> References

[1] Alexey Dosovitskiy, et al. [“使用范例卷积神经网络的判别式无监督特征学习。”](https://arxiv.org/abs/1406.6909) IEEE transactions on pattern analysis and machine intelligence 38.9 (2015): 1734-1747。

> [1] Alexey Dosovitskiy, et al. [“Discriminative unsupervised feature learning with exemplar convolutional neural networks.”](https://arxiv.org/abs/1406.6909) IEEE transactions on pattern analysis and machine intelligence 38.9 (2015): 1734-1747.

[2] Spyros Gidaris, Praveer Singh & Nikos Komodakis. [“通过预测图像旋转进行无监督表示学习”](https://arxiv.org/abs/1803.07728) ICLR 2018。

> [2] Spyros Gidaris, Praveer Singh & Nikos Komodakis. [“Unsupervised Representation Learning by Predicting Image Rotations”](https://arxiv.org/abs/1803.07728) ICLR 2018.

[3] Carl Doersch, Abhinav Gupta, and Alexei A. Efros. [“通过上下文预测进行无监督视觉表示学习。”](https://arxiv.org/abs/1505.05192) ICCV. 2015。

> [3] Carl Doersch, Abhinav Gupta, and Alexei A. Efros. [“Unsupervised visual representation learning by context prediction.”](https://arxiv.org/abs/1505.05192) ICCV. 2015.

[4] Mehdi Noroozi & Paolo Favaro. [“通过解决拼图进行视觉表示的无监督学习。”](https://arxiv.org/abs/1603.09246) ECCV, 2016。

> [4] Mehdi Noroozi & Paolo Favaro. [“Unsupervised learning of visual representations by solving jigsaw puzzles.”](https://arxiv.org/abs/1603.09246) ECCV, 2016.

[5] Mehdi Noroozi, Hamed Pirsiavash, and Paolo Favaro. [“通过学习计数进行表示学习。”](https://arxiv.org/abs/1708.06734) ICCV. 2017。

> [5] Mehdi Noroozi, Hamed Pirsiavash, and Paolo Favaro. [“Representation learning by learning to count.”](https://arxiv.org/abs/1708.06734) ICCV. 2017.

[6] Richard Zhang, Phillip Isola & Alexei A. Efros. [“彩色图像着色。”](https://arxiv.org/abs/1603.08511) ECCV, 2016。

> [6] Richard Zhang, Phillip Isola & Alexei A. Efros. [“Colorful image colorization.”](https://arxiv.org/abs/1603.08511) ECCV, 2016.

[7] Pascal Vincent, et al. [“使用去噪自编码器提取和组合鲁棒特征。”](https://www.cs.toronto.edu/~larocheh/publications/icml-2008-denoising-autoencoders.pdf) ICML, 2008。

> [7] Pascal Vincent, et al. [“Extracting and composing robust features with denoising autoencoders.”](https://www.cs.toronto.edu/~larocheh/publications/icml-2008-denoising-autoencoders.pdf) ICML, 2008.

[8] Jeff Donahue, Philipp Krähenbühl, and Trevor Darrell. [“对抗性特征学习。”](https://arxiv.org/abs/1605.09782) ICLR 2017。

> [8] Jeff Donahue, Philipp Krähenbühl, and Trevor Darrell. [“Adversarial feature learning.”](https://arxiv.org/abs/1605.09782) ICLR 2017.

[9] Deepak Pathak, et al. [“上下文编码器：通过图像修复进行特征学习。”](https://arxiv.org/abs/1604.07379) CVPR. 2016。

> [9] Deepak Pathak, et al. [“Context encoders: Feature learning by inpainting.”](https://arxiv.org/abs/1604.07379) CVPR. 2016.

[10] Richard Zhang, Phillip Isola, and Alexei A. Efros. [“分脑自编码器：通过跨通道预测进行无监督学习。”](https://arxiv.org/abs/1611.09842) CVPR. 2017。

> [10] Richard Zhang, Phillip Isola, and Alexei A. Efros. [“Split-brain autoencoders: Unsupervised learning by cross-channel prediction.”](https://arxiv.org/abs/1611.09842) CVPR. 2017.

[11] Xiaolong Wang & Abhinav Gupta. [“使用视频进行视觉表示的无监督学习。”](https://arxiv.org/abs/1505.00687) ICCV. 2015。

> [11] Xiaolong Wang & Abhinav Gupta. [“Unsupervised Learning of Visual Representations using Videos.”](https://arxiv.org/abs/1505.00687) ICCV. 2015.

[12] Carl Vondrick, et al. [“通过视频着色实现跟踪”](https://arxiv.org/pdf/1806.09594.pdf) ECCV. 2018。

> [12] Carl Vondrick, et al. [“Tracking Emerges by Colorizing Videos”](https://arxiv.org/pdf/1806.09594.pdf) ECCV. 2018.

[13] Ishan Misra, C. Lawrence Zitnick, and Martial Hebert. [“洗牌与学习：使用时间顺序验证进行无监督学习。”](https://arxiv.org/abs/1603.08561) ECCV. 2016。

> [13] Ishan Misra, C. Lawrence Zitnick, and Martial Hebert. [“Shuffle and learn: unsupervised learning using temporal order verification.”](https://arxiv.org/abs/1603.08561) ECCV. 2016.

[14] Basura Fernando, et al. [“使用奇一网络进行自监督视频表示学习”](https://arxiv.org/abs/1611.06646) CVPR. 2017。

> [14] Basura Fernando, et al. [“Self-Supervised Video Representation Learning With Odd-One-Out Networks”](https://arxiv.org/abs/1611.06646) CVPR. 2017.

[15] Donglai Wei, et al. [“学习和使用时间之箭”](https://www.robots.ox.ac.uk/~vgg/publications/2018/Wei18/wei18.pdf) CVPR. 2018。

> [15] Donglai Wei, et al. [“Learning and Using the Arrow of Time”](https://www.robots.ox.ac.uk/~vgg/publications/2018/Wei18/wei18.pdf) CVPR. 2018.

[16] Florian Schroff, Dmitry Kalenichenko and James Philbin. [“FaceNet：用于人脸识别和聚类的统一嵌入”](https://arxiv.org/abs/1503.03832) CVPR. 2015。

> [16] Florian Schroff, Dmitry Kalenichenko and James Philbin. [“FaceNet: A Unified Embedding for Face Recognition and Clustering”](https://arxiv.org/abs/1503.03832) CVPR. 2015.

[17] Pierre Sermanet, et al. [“时间对比网络：从视频中进行自监督学习”](https://arxiv.org/abs/1704.06888) CVPR. 2018。

> [17] Pierre Sermanet, et al. [“Time-Contrastive Networks: Self-Supervised Learning from Video”](https://arxiv.org/abs/1704.06888) CVPR. 2018.

[18] Debidatta Dwibedi, et al. [“从视觉观测中学习可操作的表示。”](https://arxiv.org/abs/1808.00928) IROS. 2018。

> [18] Debidatta Dwibedi, et al. [“Learning actionable representations from visual observations.”](https://arxiv.org/abs/1808.00928) IROS. 2018.

[19] Eric Jang & Coline Devin, et al. [“Grasp2Vec：从自监督抓取中学习对象表示”](https://arxiv.org/abs/1811.06964) CoRL. 2018。

> [19] Eric Jang & Coline Devin, et al. [“Grasp2Vec: Learning Object Representations from Self-Supervised Grasping”](https://arxiv.org/abs/1811.06964) CoRL. 2018.

[20] Ashvin Nair, et al. [“带有想象目标的视觉强化学习”](https://arxiv.org/abs/1807.04742) NeuriPS. 2018。

> [20] Ashvin Nair, et al. [“Visual reinforcement learning with imagined goals”](https://arxiv.org/abs/1807.04742) NeuriPS. 2018.

[21] Ashvin Nair, et al. [“用于自监督机器人学习的上下文想象目标”](https://arxiv.org/abs/1910.11670) CoRL. 2019。

> [21] Ashvin Nair, et al. [“Contextual imagined goals for self-supervised robotic learning”](https://arxiv.org/abs/1910.11670) CoRL. 2019.

[22] Aaron van den Oord, Yazhe Li & Oriol Vinyals. [“使用对比预测编码进行表示学习”](https://arxiv.org/abs/1807.03748) arXiv preprint arXiv:1807.03748, 2018。

> [22] Aaron van den Oord, Yazhe Li & Oriol Vinyals. [“Representation Learning with Contrastive Predictive Coding”](https://arxiv.org/abs/1807.03748) arXiv preprint arXiv:1807.03748, 2018.

[23] Olivier J. Henaff, et al. [“使用对比预测编码进行数据高效图像识别”](https://arxiv.org/abs/1905.09272) arXiv preprint arXiv:1905.09272, 2019。

> [23] Olivier J. Henaff, et al. [“Data-Efficient Image Recognition with Contrastive Predictive Coding”](https://arxiv.org/abs/1905.09272) arXiv preprint arXiv:1905.09272, 2019.

[24] Kaiming He, et al. [“用于无监督视觉表示学习的动量对比。”](https://arxiv.org/abs/1911.05722) CVPR 2020。

> [24] Kaiming He, et al. [“Momentum Contrast for Unsupervised Visual Representation Learning.”](https://arxiv.org/abs/1911.05722) CVPR 2020.

[25] Zhirong Wu, et al. [“通过非参数实例级判别进行无监督特征学习。”](https://arxiv.org/abs/1805.01978v1) CVPR 2018。

> [25] Zhirong Wu, et al. [“Unsupervised Feature Learning via Non-Parametric Instance-level Discrimination.”](https://arxiv.org/abs/1805.01978v1) CVPR 2018.

[26] Ting Chen, et al. [“一个用于视觉表示对比学习的简单框架。”](https://arxiv.org/abs/2002.05709) arXiv preprint arXiv:2002.05709, 2020。

> [26] Ting Chen, et al. [“A Simple Framework for Contrastive Learning of Visual Representations.”](https://arxiv.org/abs/2002.05709) arXiv preprint arXiv:2002.05709, 2020.

[27] Aravind Srinivas, Michael Laskin & Pieter Abbeel [“CURL：用于强化学习的对比无监督表示。”](https://arxiv.org/abs/2004.04136) arXiv preprint arXiv:2004.04136, 2020。

> [27] Aravind Srinivas, Michael Laskin & Pieter Abbeel [“CURL: Contrastive Unsupervised Representations for Reinforcement Learning.”](https://arxiv.org/abs/2004.04136) arXiv preprint arXiv:2004.04136, 2020.

[28] Carles Gelada, et al. [“DeepMDP：学习用于表示学习的连续潜在空间模型”](https://arxiv.org/abs/1906.02736) ICML 2019。

> [28] Carles Gelada, et al. [“DeepMDP: Learning Continuous Latent Space Models for Representation Learning”](https://arxiv.org/abs/1906.02736) ICML 2019.

[29] Amy Zhang, et al. [“无需重建的强化学习不变表示学习”](https://arxiv.org/abs/2006.10742) arXiv preprint arXiv:2006.10742, 2020。

> [29] Amy Zhang, et al. [“Learning Invariant Representations for Reinforcement Learning without Reconstruction”](https://arxiv.org/abs/2006.10742) arXiv preprint arXiv:2006.10742, 2020.

[30] Xinlei Chen, et al. [“使用动量对比学习改进基线”](https://arxiv.org/abs/2003.04297) arXiv preprint arXiv:2003.04297, 2020。

> [30] Xinlei Chen, et al. [“Improved Baselines with Momentum Contrastive Learning”](https://arxiv.org/abs/2003.04297) arXiv preprint arXiv:2003.04297, 2020.

[31] Jean-Bastien Grill, et al. [“Bootstrap Your Own Latent：一种新的自监督学习方法”](https://arxiv.org/abs/2006.07733) arXiv preprint arXiv:2006.07733, 2020。

> [31] Jean-Bastien Grill, et al. [“Bootstrap Your Own Latent: A New Approach to Self-Supervised Learning”](https://arxiv.org/abs/2006.07733) arXiv preprint arXiv:2006.07733, 2020.

[32] Abe Fetterman & Josh Albrecht. [“使用Bootstrap Your Own Latent (BYOL) 理解自监督和对比学习”](https://untitled-ai.github.io/understanding-self-supervised-contrastive-learning.html) 未命名博客。2020年8月24日。

> [32] Abe Fetterman & Josh Albrecht. [“Understanding self-supervised and contrastive learning with Bootstrap Your Own Latent (BYOL)”](https://untitled-ai.github.io/understanding-self-supervised-contrastive-learning.html) Untitled blog. Aug 24, 2020.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Self-supervised learning | 自监督学习 | 一种机器学习范式，通过从数据本身生成监督信号来训练模型，无需人工标注。 |
| Pretext task | 前置任务 | 自监督学习中用于生成监督信号的辅助任务，其性能本身不重要，但有助于学习通用表征。 |
| Representation learning | 表征学习 | 机器学习的一个领域，旨在自动发现数据中有效且有用的特征表示。 |
| Downstream task | 下游任务 | 在预训练模型学习到通用表征后，利用这些表征解决的特定实际应用任务。 |
| Contrastive learning | 对比学习 | 一种自监督学习方法，通过拉近相似样本的表示并推开不相似样本的表示来学习特征。 |
| InfoNCE loss | InfoNCE损失 | 对比学习中常用的一种损失函数，旨在最大化正样本对之间的互信息，同时区分负样本。 |
| Generative model | 生成模型 | 能够学习数据分布并生成新样本的机器学习模型，如GAN和VAE。 |
| Autoencoder | 自编码器 | 一种神经网络，通过学习将输入编码为低维表示，再从该表示解码回原始输入来学习特征。 |
| Triplet loss | 三元组损失 | 度量学习中常用的损失函数，确保锚点样本与正样本的距离小于与负样本的距离。 |
| N-pair loss | N-pair损失 | 三元组损失的一种变体，在一个mini-batch中将所有其他正样本实例视为负样本，以提高效率。 |
| Bisimulation | 双模拟 | 强化学习中指两个具有相似长期行为的状态之间的等价关系，用于学习控制相关的表示。 |
| Markov Decision Process (MDP) | 马尔可夫决策过程 | 用于建模决策制定的一种数学框架，其中结果部分随机且部分由决策者控制。 |
| Wasserstein distance | Wasserstein距离 | 衡量两个概率分布之间距离的一种度量，也称为“推土机距离”，常用于GANs和DeepMDP。 |
| Reinforcement Learning (RL) | 强化学习 | 机器学习的一个领域，智能体通过与环境交互学习如何做出决策以最大化累积奖励。 |
| Metric learning | 度量学习 | 旨在学习一个距离函数，使得相似样本在特征空间中距离较近，不相似样本距离较远。 |
