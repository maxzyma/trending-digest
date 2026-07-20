# 对比表示学习

> Contrastive Representation Learning

> 来源：Lil'Log / Lilian Weng，2021-05-31
> 原文链接：https://lilianweng.github.io/posts/2021-05-31-contrastive/
> 分类：机器学习 / 表示学习

## 核心要点

- 对比表示学习旨在构建一个嵌入空间，使相似样本彼此靠近，不相似样本彼此远离，是无监督自监督学习的强大方法。
- 对比学习损失函数从早期仅涉及一个正负样本对，发展到在批次中包含多个正负样本对，如对比损失、三元组损失、提升结构化损失和N-pair损失。
- 噪声对比估计（NCE）及其变体InfoNCE通过区分目标数据和噪声数据来估计模型参数，并广泛应用于从噪声样本中识别正样本。
- 数据增强、大批量大小和难负样本挖掘是对比学习成功的关键要素，其中数据增强创建样本的噪声版本，大批量提供多样化负样本，难负样本挖掘则挑战模型学习更鲁棒的表示。
- 视觉领域中的对比学习方法包括SimCLR、Barlow Twins和BYOL，它们通过并行增强、互相关矩阵优化或在线/目标网络交互来学习图像表示。
- 记忆库机制（如MoCo）和特征聚类方法（如DeepCluster、SwAV）通过存储历史表示或迭代聚类来处理大量负样本或生成伪标签，以提高计算效率或提供监督信号。
- 有监督对比学习方法，如CLIP和监督对比损失，利用标签信息或自然语言监督来联合训练编码器，以学习可迁移的视觉或多模态表示。
- 文本领域的对比学习面临文本增强的挑战，但通过词汇编辑、回译、Dropout和Cutoff等方法生成增强样本，并结合NLI监督或无监督互信息最大化来学习句子嵌入。
- 针对预训练BERT模型句子嵌入的各向异性问题，BERT-flow和白化操作通过归一化流或线性变换将其转换为更平滑、各向同性的分布，从而提升语义相似度任务性能。
- BYOL通过在线和目标网络相互学习，声称不使用负样本也能达到先进性能，但其成功可能隐式依赖于批归一化带来的对比效应。

## 正文

对比表示学习的目标是学习一个嵌入空间，其中相似的样本对彼此靠近，而不相似的样本对则相距遥远。对比学习可以应用于监督和无监督设置。当处理无监督数据时，对比学习是[自监督学习](https://lilianweng.github.io/posts/2019-11-10-self-supervised/)中最强大的方法之一。

> The goal of contrastive representation learning is to learn such an embedding space in which similar sample pairs stay close to each other while dissimilar ones are far apart. Contrastive learning can be applied to both supervised and unsupervised settings. When working with unsupervised data, contrastive learning is one of the most powerful approaches in [self-supervised learning](https://lilianweng.github.io/posts/2019-11-10-self-supervised/).

### 对比训练目标

> Contrastive Training Objectives

在对比学习损失函数的早期版本中，只涉及一个正样本和一个负样本。最近的训练目标趋势是在一个批次中包含多个正负样本对。

> In early versions of loss functions for contrastive learning, only one positive and one negative sample are involved. The trend in recent training objectives is to include multiple positive and negative pairs in one batch.

#### 对比损失

> Contrastive Loss

**对比损失** ([Chopra et al. 2005](http://yann.lecun.com/exdb/publis/pdf/chopra-05.pdf)) 是最早用于深度度量学习的对比式训练目标之一。

> **Contrastive loss** ([Chopra et al. 2005](http://yann.lecun.com/exdb/publis/pdf/chopra-05.pdf)) is one of the earliest training objectives used for deep metric learning in a contrastive fashion.

给定一个输入样本列表$\{ \mathbf{x}_i \}$，每个样本都有一个对应的标签$y_i \in \{1, \dots, L\}$，属于$L$个类别。我们希望学习一个函数$f_\theta(.): \mathcal{X}\to\mathbb{R}^d$，将$x_i$编码成一个嵌入向量，使得同一类别的样本具有相似的嵌入，而不同类别的样本具有非常不同的嵌入。因此，对比损失函数接收一对输入$(x_i, x_j)$，并在它们属于同一类别时最小化嵌入距离，否则最大化距离。

> Given a list of input samples $\{ \mathbf{x}_i \}$, each has a corresponding label $y_i \in \{1, \dots, L\}$ among $L$ classes. We would like to learn a function $f_\theta(.): \mathcal{X}\to\mathbb{R}^d$ that encodes $x_i$ into an embedding vector such that examples from the same class have similar embeddings and samples from different classes have very different ones. Thus, contrastive loss takes a pair of inputs $(x_i, x_j)$ and minimizes the embedding distance when they are from the same class but maximizes the distance otherwise.

$$
\mathcal{L}_\text{cont}(\mathbf{x}_i, \mathbf{x}_j, \theta) = \mathbb{1}[y_i=y_j] \| f_\theta(\mathbf{x}_i) - f_\theta(\mathbf{x}_j) \|^2_2 + \mathbb{1}[y_i\neq y_j]\max(0, \epsilon - \|f_\theta(\mathbf{x}_i) - f_\theta(\mathbf{x}_j)\|_2)^2
$$

其中 $\epsilon$ 是一个超参数，定义了不同类别样本之间的距离下限。

> where $\epsilon$ is a hyperparameter, defining the lower bound distance between samples of different classes.

#### 三元组损失

> Triplet Loss

**三元组损失**最初在 FaceNet ([Schroff 等人 2015](https://arxiv.org/abs/1503.03832)) 论文中提出，并用于学习在不同姿态和角度下同一人的面部识别。

> **Triplet loss** was originally proposed in the FaceNet ([Schroff et al. 2015](https://arxiv.org/abs/1503.03832)) paper and was used to learn face recognition of the same person at different poses and angles.

![Illustration of triplet loss given one positive and one negative per anchor. (Image source: Schroff et al. 2015 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/triplet-loss.png)

给定一个锚点输入 $\mathbf{x}$，我们选择一个正样本 $\mathbf{x}^+$ 和一个负样本 $\mathbf{x}^-$，这意味着 $\mathbf{x}^+$ 和 $\mathbf{x}$ 属于同一类别，而 $\mathbf{x}^-$ 则从另一个不同类别中采样。三元组损失旨在同时最小化锚点 $\mathbf{x}$ 和正样本 $\mathbf{x}^+$ 之间的距离，并最大化锚点 $\mathbf{x}$ 和负样本 $\mathbf{x}^-$ 之间的距离，其公式如下：

> Given one anchor input $\mathbf{x}$, we select one positive sample $\mathbf{x}^+$ and one negative $\mathbf{x}^-$, meaning that $\mathbf{x}^+$ and $\mathbf{x}$ belong to the same class and $\mathbf{x}^-$ is sampled from another different class. Triplet loss learns to minimize the distance between the anchor $\mathbf{x}$ and positive $\mathbf{x}^+$ and maximize the distance between the anchor $\mathbf{x}$ and negative $\mathbf{x}^-$ at the same time with the following equation:

$$
\mathcal{L}_\text{triplet}(\mathbf{x}, \mathbf{x}^+, \mathbf{x}^-) = \sum_{\mathbf{x} \in \mathcal{X}} \max\big( 0, \|f(\mathbf{x}) - f(\mathbf{x}^+)\|^2_2 - \|f(\mathbf{x}) - f(\mathbf{x}^-)\|^2_2 + \epsilon \big)
$$

其中，边距参数 $\epsilon$ 被配置为相似对与不相似对之间距离的最小偏移量。

> where the margin parameter $\epsilon$ is configured as the minimum offset between distances of similar vs dissimilar pairs.

选择具有挑战性的$\mathbf{x}^-$对于真正改进模型至关重要。

> It is crucial to select challenging $\mathbf{x}^-$ to truly improve the model.

#### 提升结构化损失

> Lifted Structured Loss

**提升结构化损失** ([Song et al. 2015](https://arxiv.org/abs/1511.06452)) 利用一个训练批次中的所有成对边，以提高计算效率。

> **Lifted Structured Loss** ([Song et al. 2015](https://arxiv.org/abs/1511.06452)) utilizes all the pairwise edges within one training batch for better computational efficiency.

![Illustration compares contrastive loss, triplet loss and lifted structured loss. Red and blue edges connect similar and dissimilar sample pairs respectively. (Image source: Song et al. 2015 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/lifted-structured-loss.png)

令$D_{ij} = | f(\mathbf{x}_i) - f(\mathbf{x}_j) |_2$，结构化损失函数定义为

> Let $D_{ij} = | f(\mathbf{x}_i) - f(\mathbf{x}_j) |_2$, a structured loss function is defined as

$$
\begin{aligned}
\mathcal{L}_\text{struct} &= \frac{1}{2\vert \mathcal{P} \vert} \sum_{(i,j) \in \mathcal{P}} \max(0, \mathcal{L}_\text{struct}^{(ij)})^2 \\
\text{where } \mathcal{L}_\text{struct}^{(ij)} &= D_{ij} + \color{red}{\max \big( \max_{(i,k)\in \mathcal{N}} \epsilon - D_{ik}, \max_{(j,l)\in \mathcal{N}} \epsilon - D_{jl} \big)}
\end{aligned}
$$

其中$\mathcal{P}$包含正样本对集，$\mathcal{N}$是负样本对集。请注意，密集的成对平方距离矩阵可以很容易地按训练批次计算。

> where $\mathcal{P}$ contains the set of positive pairs and $\mathcal{N}$ is the set of negative pairs. Note that the dense pairwise squared distance matrix can be easily computed per training batch.

$\mathcal{L}_\text{struct}^{(ij)}$中的红色部分用于挖掘难负样本。然而，它不平滑，在实践中可能导致收敛到不好的局部最优。因此，它被放宽为：

> The red part in $\mathcal{L}_\text{struct}^{(ij)}$ is used for mining hard negatives. However, it is not smooth and may cause the convergence to a bad local optimum in practice. Thus, it is relaxed to be:

$$
\mathcal{L}_\text{struct}^{(ij)} = D_{ij} + \log \Big( \sum_{(i,k)\in\mathcal{N}} \exp(\epsilon - D_{ik}) + \sum_{(j,l)\in\mathcal{N}} \exp(\epsilon - D_{jl}) \Big)
$$

在论文中，他们还提出通过主动纳入给定少量随机正样本对的困难负样本，来提高每个批次中负样本的质量。

> In the paper, they also proposed to enhance the quality of negative samples in each batch by actively incorporating difficult negative samples given a few random positive pairs.

#### N-pair 损失

> N-pair Loss

**多类别 N-pair 损失** ([Sohn 2016](https://papers.nips.cc/paper/2016/hash/6b180037abbebea991d8b1232f8a8ca9-Abstract.html)) 将三元组损失泛化，以包含与多个负样本的比较。

> **Multi-Class N-pair loss** ([Sohn 2016](https://papers.nips.cc/paper/2016/hash/6b180037abbebea991d8b1232f8a8ca9-Abstract.html)) generalizes triplet loss to include comparison with multiple negative samples.

给定一个 $(N + 1)$ 元组的训练样本，$\{ \mathbf{x}, \mathbf{x}^+, \mathbf{x}^-_1, \dots, \mathbf{x}^-_{N-1} \}$，其中包括一个正样本和 $N-1$ 个负样本，N-pair 损失定义为：

> Given a $(N + 1)$ -tuplet of training samples, $\{ \mathbf{x}, \mathbf{x}^+, \mathbf{x}^-_1, \dots, \mathbf{x}^-_{N-1} \}$, including one positive and $N-1$ negative ones, N-pair loss is defined as:

$$
\begin{aligned}
\mathcal{L}_\text{N-pair}(\mathbf{x}, \mathbf{x}^+, \{\mathbf{x}^-_i\}^{N-1}_{i=1}) 
&= \log\big(1 + \sum_{i=1}^{N-1} \exp(f(\mathbf{x})^\top f(\mathbf{x}^-_i) - f(\mathbf{x})^\top f(\mathbf{x}^+))\big) \\
&= -\log\frac{\exp(f(\mathbf{x})^\top f(\mathbf{x}^+))}{\exp(f(\mathbf{x})^\top f(\mathbf{x}^+)) + \sum_{i=1}^{N-1} \exp(f(\mathbf{x})^\top f(\mathbf{x}^-_i))}
\end{aligned}
$$

如果我们每个类别只采样一个负样本，这等同于多类别分类的 softmax 损失。

> If we only sample one negative sample per class, it is equivalent to the softmax loss for multi-class classification.

#### NCE

> NCE

**噪声对比估计**，简称**NCE**，是一种用于估计统计模型参数的方法，由[Gutmann & Hyvarinen](http://proceedings.mlr.press/v9/gutmann10a.html)于2010年提出。其思想是运行逻辑回归来区分目标数据和噪声数据。阅读更多关于NCE如何用于学习词嵌入的信息[此处](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#noise-contrastive-estimation-nce)。

> **Noise Contrastive Estimation**, short for **NCE**, is a method for estimating parameters of a statistical model, proposed by [Gutmann & Hyvarinen](http://proceedings.mlr.press/v9/gutmann10a.html) in 2010. The idea is to run logistic regression to tell apart the target data from noise. Read more on how NCE is used for learning word embedding [here](https://lilianweng.github.io/posts/2017-10-15-word-embedding/#noise-contrastive-estimation-nce).

令 $\mathbf{x}$ 为目标样本 $\sim P(\mathbf{x} \vert C=1; \theta) = p_\theta(\mathbf{x})$，$\tilde{\mathbf{x}}$ 为噪声样本 $\sim P(\tilde{\mathbf{x}} \vert C=0) = q(\tilde{\mathbf{x}})$。请注意，逻辑回归模型对 logit（即对数几率）进行建模，在这种情况下，我们希望对来自目标数据分布而不是噪声分布的样本 $u$ 的 logit 进行建模：

> Let $\mathbf{x}$ be the target sample $\sim P(\mathbf{x} \vert C=1; \theta) = p_\theta(\mathbf{x})$ and $\tilde{\mathbf{x}}$ be the noise sample $\sim P(\tilde{\mathbf{x}} \vert C=0) = q(\tilde{\mathbf{x}})$. Note that the logistic regression models the logit (i.e. log-odds) and in this case we would like to model the logit of a sample $u$ from the target data distribution instead of the noise distribution:

$$
\ell_\theta(\mathbf{u}) = \log \frac{p_\theta(\mathbf{u})}{q(\mathbf{u})} = \log p_\theta(\mathbf{u}) - \log q(\mathbf{u})
$$

在使用 sigmoid $\sigma(.)$ 将 logits 转换为概率后，我们可以应用交叉熵损失：

> After converting logits into probabilities with sigmoid $\sigma(.)$, we can apply cross entropy loss:

$$
\begin{aligned}
\mathcal{L}_\text{NCE} &= - \frac{1}{N} \sum_{i=1}^N \big[ \log \sigma (\ell_\theta(\mathbf{x}_i)) + \log (1 - \sigma (\ell_\theta(\tilde{\mathbf{x}}_i))) \big] \\
\text{ where }\sigma(\ell) &= \frac{1}{1 + \exp(-\ell)} = \frac{p_\theta}{p_\theta + q}
\end{aligned}
$$

这里我列出了 NCE 损失的原始形式，它只适用于一个正样本和一个噪声样本。在许多后续工作中，包含多个负样本的对比损失也被广泛称为 NCE。

> Here I listed the original form of NCE loss which works with only one positive and one noise sample. In many follow-up works, contrastive loss incorporating multiple negative samples is also broadly referred to as NCE.

#### InfoNCE

> InfoNCE

在 **InfoNCE 损失** 的 CPC（[对比预测编码](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#contrastive-predictive-coding)；[van den Oord 等人，2018](https://arxiv.org/abs/1807.03748)）中，受 [NCE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#NCE) 启发，使用分类交叉熵损失从一组不相关的噪声样本中识别出正样本。

> The **InfoNCE loss** in CPC ([Contrastive Predictive Coding](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#contrastive-predictive-coding); [van den Oord, et al. 2018](https://arxiv.org/abs/1807.03748)), inspired by [NCE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#NCE), uses categorical cross-entropy loss to identify the positive sample amongst a set of unrelated noise samples.

给定一个上下文向量 $\mathbf{c}$，正样本应从条件分布 $p(\mathbf{x} \vert \mathbf{c})$ 中抽取，而 $N-1$ 个负样本则从提议分布 $p(\mathbf{x})$ 中抽取，这与上下文 $\mathbf{c}$ 无关。为简洁起见，我们将所有样本标记为 $X=\{ \mathbf{x}_i \}^N_{i=1}$，其中只有一个样本 $\mathbf{x}_\texttt{pos}$ 是正样本。我们正确检测到正样本的概率是：

> Given a context vector $\mathbf{c}$, the positive sample should be drawn from the conditional distribution $p(\mathbf{x} \vert \mathbf{c})$, while $N-1$ negative samples are drawn from the proposal distribution $p(\mathbf{x})$, independent from the context $\mathbf{c}$. For brevity, let us label all the samples as $X=\{ \mathbf{x}_i \}^N_{i=1}$ among which only one of them $\mathbf{x}_\texttt{pos}$ is a positive sample. The probability of we detecting the positive sample correctly is:

$$
p(C=\texttt{pos} \vert X, \mathbf{c}) 
= \frac{p(x_\texttt{pos} \vert \mathbf{c}) \prod_{i=1,\dots,N; i \neq \texttt{pos}} p(\mathbf{x}_i)}{\sum_{j=1}^N \big[ p(\mathbf{x}_j \vert \mathbf{c}) \prod_{i=1,\dots,N; i \neq j} p(\mathbf{x}_i) \big]}
= \frac{ \frac{p(\mathbf{x}_\texttt{pos}\vert c)}{p(\mathbf{x}_\texttt{pos})} }{ \sum_{j=1}^N \frac{p(\mathbf{x}_j\vert \mathbf{c})}{p(\mathbf{x}_j)} }
= \frac{f(\mathbf{x}_\texttt{pos}, \mathbf{c})}{ \sum_{j=1}^N f(\mathbf{x}_j, \mathbf{c}) }
$$

其中评分函数为 $f(\mathbf{x}, \mathbf{c}) \propto \frac{p(\mathbf{x}\vert\mathbf{c})}{p(\mathbf{x})}$。

> where the scoring function is $f(\mathbf{x}, \mathbf{c}) \propto \frac{p(\mathbf{x}\vert\mathbf{c})}{p(\mathbf{x})}$.

InfoNCE 损失优化了正确分类正样本的负对数概率：

> The InfoNCE loss optimizes the negative log probability of classifying the positive sample correctly:

$$
\mathcal{L}_\text{InfoNCE} = - \mathbb{E} \Big[\log \frac{f(\mathbf{x}, \mathbf{c})}{\sum_{\mathbf{x}' \in X} f(\mathbf{x}', \mathbf{c})} \Big]
$$

$f(x, c)$ 估计密度比 $\frac{p(x\vert c)}{p(x)}$ 这一事实与互信息优化有关。为了最大化输入 $x$ 和上下文向量 $c$ 之间的互信息，我们有：

> The fact that $f(x, c)$ estimates the density ratio $\frac{p(x\vert c)}{p(x)}$ has a connection with mutual information optimization. To maximize the the mutual information between input $x$ and context vector $c$, we have:

$$
I(\mathbf{x}; \mathbf{c}) = \sum_{\mathbf{x}, \mathbf{c}} p(\mathbf{x}, \mathbf{c}) \log\frac{p(\mathbf{x}, \mathbf{c})}{p(\mathbf{x})p(\mathbf{c})} = \sum_{\mathbf{x}, \mathbf{c}} p(\mathbf{x}, \mathbf{c})\log\color{blue}{\frac{p(\mathbf{x}|\mathbf{c})}{p(\mathbf{x})}}
$$

其中蓝色的对数项由 $f$ 估计。

> where the logarithmic term in blue is estimated by $f$.

对于序列预测任务，CPC 不直接建模未来的观测值 $p_k(\mathbf{x}_{t+k} \vert \mathbf{c}_t)$（这可能相当昂贵），而是建模一个密度函数来保留 $\mathbf{x}_{t+k}$ 和 $\mathbf{c}_t$ 之间的互信息：

> For sequence prediction tasks, rather than modeling the future observations $p_k(\mathbf{x}_{t+k} \vert \mathbf{c}_t)$ directly (which could be fairly expensive), CPC models a density function to preserve the mutual information between $\mathbf{x}_{t+k}$ and $\mathbf{c}_t$:

$$
f_k(\mathbf{x}_{t+k}, \mathbf{c}_t) = \exp(\mathbf{z}_{t+k}^\top \mathbf{W}_k \mathbf{c}_t) \propto \frac{p(\mathbf{x}_{t+k}\vert\mathbf{c}_t)}{p(\mathbf{x}_{t+k})}
$$

其中 $\mathbf{z}_{t+k}$ 是编码输入，$\mathbf{W}_k$ 是一个可训练的权重矩阵。

> where $\mathbf{z}_{t+k}$ is the encoded input and $\mathbf{W}_k$ is a trainable weight matrix.

#### 软近邻损失

> Soft-Nearest Neighbors Loss

**软近邻损失** ([Salakhutdinov & Hinton 2007](http://proceedings.mlr.press/v2/salakhutdinov07a.html), [Frosst et al. 2019](https://arxiv.org/abs/1902.01889)) 将其扩展为包含多个正样本。

> **Soft-Nearest Neighbors Loss** ([Salakhutdinov & Hinton 2007](http://proceedings.mlr.press/v2/salakhutdinov07a.html), [Frosst et al. 2019](https://arxiv.org/abs/1902.01889)) extends it to include multiple positive samples.

给定一批样本，$\{\mathbf{x}_i, y_i)\}^B_{i=1}$ 其中 $y_i$ 是 $\mathbf{x}_i$ 的类别标签，以及一个函数 $f(.,.)$ 用于衡量两个输入之间的相似度，在温度 $\tau$ 下的软近邻损失定义为：

> Given a batch of samples, $\{\mathbf{x}_i, y_i)\}^B_{i=1}$ where $y_i$ is the class label of $\mathbf{x}_i$ and a function $f(.,.)$ for measuring similarity between two inputs, the soft nearest neighbor loss at temperature $\tau$ is defined as:

$$
\mathcal{L}_\text{snn} = -\frac{1}{B}\sum_{i=1}^B \log \frac{\sum_{i\neq j, y_i = y_j, j=1,\dots,B} \exp(- f(\mathbf{x}_i, \mathbf{x}_j) / \tau)}{\sum_{i\neq k, k=1,\dots,B} \exp(- f(\mathbf{x}_i, \mathbf{x}_k) /\tau)}
$$

温度 $\tau$ 用于调整特征在表示空间中的集中程度。例如，当温度较低时，损失主要由小距离决定，而广泛分离的表示无法贡献太多并变得无关紧要。

> The temperature $\tau$ is used for tuning how concentrated the features are in the representation space. For example, when at low temperature, the loss is dominated by the small distances and widely separated representations cannot contribute much and become irrelevant.

#### 常见设置

> Common Setup

我们可以放宽软近邻损失中“类别”和“标签”的定义，通过例如对原始样本应用数据增强来创建噪声版本，从而从无监督数据中创建正负样本对。

> We can loosen the definition of “classes” and “labels” in soft nearest-neighbor loss to create positive and negative sample pairs out of unsupervised data by, for example, applying data augmentation to create noise versions of original samples.

大多数最新研究遵循以下对比学习目标定义，以纳入多个正样本和负样本。根据（[Wang & Isola 2020](https://arxiv.org/abs/2005.10242)）中的设置，令 $p_\texttt{data}(.)$ 为 $\mathbb{R}^n$ 上的数据分布，$p_\texttt{pos}(., .)$ 为 $\mathbb{R}^{n \times n}$ 上的正样本对分布。这两个分布应满足：

> Most recent studies follow the following definition of contrastive learning objective to incorporate multiple positive and negative samples. According to the setup in ([Wang & Isola 2020](https://arxiv.org/abs/2005.10242)), let $p_\texttt{data}(.)$ be the data distribution over $\mathbb{R}^n$ and $p_\texttt{pos}(., .)$ be the distribution of positive pairs over $\mathbb{R}^{n \times n}$. These two distributions should satisfy:

• 对称性：$\forall \mathbf{x}, \mathbf{x}^+, p_\texttt{pos}(\mathbf{x}, \mathbf{x}^+) = p_\texttt{pos}(\mathbf{x}^+, \mathbf{x})$

• 边际匹配：$\forall \mathbf{x}, \int p_\texttt{pos}(\mathbf{x}, \mathbf{x}^+) d\mathbf{x}^+ = p_\texttt{data}(\mathbf{x})$

英文原文：

• Symmetry: $\forall \mathbf{x}, \mathbf{x}^+, p_\texttt{pos}(\mathbf{x}, \mathbf{x}^+) = p_\texttt{pos}(\mathbf{x}^+, \mathbf{x})$

• Matching marginal: $\forall \mathbf{x}, \int p_\texttt{pos}(\mathbf{x}, \mathbf{x}^+) d\mathbf{x}^+ = p_\texttt{data}(\mathbf{x})$

为了学习一个编码器 $f(\mathbf{x})$ 来学习一个 *L2 归一化特征向量*，对比学习目标是：

> To learn an encoder $f(\mathbf{x})$ to learn a *L2-normalized feature vector*, the contrastive learning objective is:

$$
\begin{aligned}
\mathcal{L}_\text{contrastive} 
&= \mathbb{E}_{(\mathbf{x},\mathbf{x}^+)\sim p_\texttt{pos}, \{\mathbf{x}^-_i\}^M_{i=1} \overset{\text{i.i.d}}{\sim} p_\texttt{data} } \Big[ -\log\frac{\exp(f(\mathbf{x})^\top f(\mathbf{x}^+) / \tau)}{ \exp(f(\mathbf{x})^\top f(\mathbf{x}^+) / \tau) + \sum_{i=1}^M \exp(f(\mathbf{x})^\top f(\mathbf{x}_i^-) / \tau)} \Big] & \\
&\approx \mathbb{E}_{(\mathbf{x},\mathbf{x}^+)\sim p_\texttt{pos}, \{\mathbf{x}^-_i\}^M_{i=1} \overset{\text{i.i.d}}{\sim} p_\texttt{data} }\Big[ - f(\mathbf{x})^\top f(\mathbf{x}^+) / \tau + \log\big(\sum_{i=1}^M \exp(f(\mathbf{x})^\top f(\mathbf{x}_i^-) / \tau)\big) \Big] & \scriptstyle{\text{; Assuming infinite negatives}} \\
&= -\frac{1}{\tau}\mathbb{E}_{(\mathbf{x},\mathbf{x}^+)\sim p_\texttt{pos}}f(\mathbf{x})^\top f(\mathbf{x}^+) + \mathbb{E}_{ \mathbf{x} \sim p_\texttt{data}} \Big[ \log \mathbb{E}_{\mathbf{x}^- \sim p_\texttt{data}} \big[ \sum_{i=1}^M \exp(f(\mathbf{x})^\top f(\mathbf{x}_i^-) / \tau)\big] \Big] &
\end{aligned}
$$

### 关键要素

> Key Ingredients

#### 大量数据增强

> Heavy Data Augmentation

给定一个训练样本，需要数据增强技术来创建其自身的噪声版本，作为正样本输入到损失函数中。适当的数据增强设置对于学习良好且可泛化的嵌入特征至关重要。它在不改变语义含义的情况下，将非本质的变异引入到样本中，从而鼓励模型学习表示的本质部分。例如，[SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr) 中的实验表明，随机裁剪和随机颜色失真的组合对于在学习图像视觉表示方面取得良好性能至关重要。

> Given a training sample, data augmentation techniques are needed for creating noise versions of itself to feed into the loss as positive samples. Proper data augmentation setup is critical for learning good and generalizable embedding features. It introduces the non-essential variations into examples without modifying semantic meanings and thus encourages the model to learn the essential part of the representation. For example, experiments in [SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr) showed that the composition of random cropping and random color distortion is crucial for good performance on learning visual representation of images.

#### 大批量大小

> Large Batch Size

在训练期间使用大批量大小是许多对比学习方法（例如[SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr)、[CLIP](https://lilianweng.github.io/posts/2021-05-31-contrastive/#clip)）成功的另一个关键因素，特别是当它依赖于批内负样本时。只有当批量大小足够大时，损失函数才能覆盖足够多样化的负样本集合，这些样本具有足够的挑战性，使模型能够学习有意义的表示来区分不同的示例。

> Using a large batch size during training is another key ingredient in the success of many contrastive learning methods (e.g. [SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr), [CLIP](https://lilianweng.github.io/posts/2021-05-31-contrastive/#clip)), especially when it relies on in-batch negatives. Only when the batch size is big enough, the loss function can cover a diverse enough collection of negative samples, challenging enough for the model to learn meaningful representation to distinguish different examples.

#### 难负样本挖掘

> Hard Negative Mining

难负样本应该与锚点样本具有不同的标签，但其嵌入特征与锚点嵌入非常接近。在有监督数据集中，通过访问真实标签，很容易识别特定任务的难负样本。例如，在学习句子嵌入时，我们可以将NLI数据集中标记为“矛盾”的句子对视为难负样本对（例如[SimCSE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#dropout-and-cutoff)），或者使用BM25返回的匹配最多关键词的排名靠前的错误候选作为难负样本（[DPR](https://lilianweng.github.io/posts/2020-10-29-odqa/#DPR)；[Karpukhin et al., 2020](https://arxiv.org/abs/2004.04906)）。

> Hard negative samples should have different labels from the anchor sample, but have embedding features very close to the anchor embedding. With access to ground truth labels in supervised datasets, it is easy to identify task-specific hard negatives. For example when learning sentence embedding, we can treat sentence pairs labelled as “contradiction” in NLI datasets as hard negative pairs (e.g. [SimCSE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#dropout-and-cutoff), or use top incorrect candidates returned by BM25 with most keywords matched as hard negative samples ([DPR](https://lilianweng.github.io/posts/2020-10-29-odqa/#DPR); [Karpukhin et al., 2020](https://arxiv.org/abs/2004.04906)).

然而，当我们希望保持无监督时，进行难负样本挖掘变得棘手。增加训练批量大小或[记忆库](https://lilianweng.github.io/posts/2021-05-31-contrastive/#memory-bank)大小会隐式引入更多难负样本，但这会带来内存使用量大的沉重负担，作为副作用。

> However, it becomes tricky to do hard negative mining when we want to remain unsupervised. Increasing training batch size or [memory bank](https://lilianweng.github.io/posts/2021-05-31-contrastive/#memory-bank) size implicitly introduces more hard negative samples, but it leads to a heavy burden of large memory usage as a side effect.

[Chuang et al. (2020)](https://arxiv.org/abs/2007.00224)研究了对比学习中的采样偏差并提出了去偏损失。在无监督设置中，由于我们不知道真实标签，我们可能会意外地采样到假负样本。采样偏差可能导致性能显著下降。

> [Chuang et al. (2020)](https://arxiv.org/abs/2007.00224) studied the sampling bias in contrastive learning and proposed debiased loss. In the unsupervised setting, since we do not know the ground truth labels, we may accidentally sample false negative samples. Sampling bias can lead to significant performance drop.

![Sampling bias which refers to false negative samples in contrastive learning can lead to a big performance drop. (Image source: Chuang et al., 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/contrastive-sampling-bias.png)

让我们假设锚点类别 $c$ 的概率是均匀的 $\rho(c)=\eta^+$，并且观察到不同类别的概率是 $\eta^- = 1-\eta^+$。

> Let us assume the probability of anchor class $c$ is uniform $\rho(c)=\eta^+$ and the probability of observing a different class is $\eta^- = 1-\eta^+$.

• 观察到 $\mathbf{x}$ 的正例的概率是 $p^+_x(\mathbf{x}’)=p(\mathbf{x}’\vert \mathbf{h}_{x’}=\mathbf{h}_x)$；

• 获得 $\mathbf{x}$ 的负样本的概率是 $p^-_x(\mathbf{x}’)=p(\mathbf{x}’\vert \mathbf{h}_{x’}\neq\mathbf{h}_x)$。

英文原文：

• The probability of observing a positive example for $\mathbf{x}$ is $p^+_x(\mathbf{x}’)=p(\mathbf{x}’\vert \mathbf{h}_{x’}=\mathbf{h}_x)$;

• The probability of getting a negative sample for $\mathbf{x}$ is $p^-_x(\mathbf{x}’)=p(\mathbf{x}’\vert \mathbf{h}_{x’}\neq\mathbf{h}_x)$.

当我们进行采样时$\mathbf{x}^-$，我们无法访问真实的$p^-_x(\mathbf{x}^-)$因此$\mathbf{x}^-$可能从（不期望的）锚点类中采样$c$，概率为$\eta^+$。实际的采样数据分布变为：

> When we are sampling $\mathbf{x}^-$ , we cannot access the true $p^-_x(\mathbf{x}^-)$ and thus $\mathbf{x}^-$ may be sampled from the (undesired) anchor class $c$ with probability $\eta^+$. The actual sampling data distribution becomes:

$$
p(\mathbf{x}') = \eta^+ p^+_x(\mathbf{x}') + \eta^- p_x^-(\mathbf{x}')
$$

因此我们可以使用$p^-_x(\mathbf{x}’) = (p(\mathbf{x}’) - \eta^+ p^+_x(\mathbf{x}’))/\eta^-$用于采样$\mathbf{x}^-$以消除损失的偏差。利用$N$个样本$\{\mathbf{u}_i\}^N_{i=1}$来自$p$和$M$个样本$\{ \mathbf{v}_i \}_{i=1}^M$来自$p^+_x$，我们可以估计第二项的期望$\mathbb{E}_{\mathbf{x}^-\sim p^-_x}[\exp(f(\mathbf{x})^\top f(\mathbf{x}^-))]$在对比学习损失的分母中：

> Thus we can use $p^-_x(\mathbf{x}’) = (p(\mathbf{x}’) - \eta^+ p^+_x(\mathbf{x}’))/\eta^-$ for sampling $\mathbf{x}^-$ to debias the loss. With $N$ samples $\{\mathbf{u}_i\}^N_{i=1}$ from $p$ and $M$ samples $\{ \mathbf{v}_i \}_{i=1}^M$ from $p^+_x$ , we can estimate the expectation of the second term $\mathbb{E}_{\mathbf{x}^-\sim p^-_x}[\exp(f(\mathbf{x})^\top f(\mathbf{x}^-))]$ in the denominator of contrastive learning loss:

$$
g(\mathbf{x}, \{\mathbf{u}_i\}^N_{i=1}, \{\mathbf{v}_i\}_{i=1}^M) = \max\Big\{ \frac{1}{\eta^-}\Big( \frac{1}{N}\sum_{i=1}^N \exp(f(\mathbf{x})^\top f(\mathbf{u}_i)) - \frac{\eta^+}{M}\sum_{i=1}^M \exp(f(\mathbf{x})^\top f(\mathbf{v}_i)) \Big), \exp(-1/\tau) \Big\}
$$

其中 $\tau$ 是温度，且 $\exp(-1/\tau)$ 是 $\mathbb{E}_{\mathbf{x}^-\sim p^-_x}[\exp(f(\mathbf{x})^\top f(\mathbf{x}^-))]$ 的理论下限。

> where $\tau$ is the temperature and $\exp(-1/\tau)$ is the theoretical lower bound of $\mathbb{E}_{\mathbf{x}^-\sim p^-_x}[\exp(f(\mathbf{x})^\top f(\mathbf{x}^-))]$.

最终的去偏对比损失函数如下所示：

> The final debiased contrastive loss looks like:

$$
\mathcal{L}^{N,M}_\text{debias}(f) = \mathbb{E}_{\mathbf{x},\{\mathbf{u}_i\}^N_{i=1}\sim p;\;\mathbf{x}^+, \{\mathbf{v}_i\}_{i=1}^M\sim p^+} \Big[ -\log\frac{\exp(f(\mathbf{x})^\top f(\mathbf{x}^+)}{\exp(f(\mathbf{x})^\top f(\mathbf{x}^+) + N g(x,\{\mathbf{u}_i\}^N_{i=1}, \{\mathbf{v}_i\}_{i=1}^M)} \Big]
$$

![t-SNE visualization of learned representation with debiased contrastive learning. (Image source: Chuang et al., 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/contrastive-debias-t-SNE.png)

根据上述标注，[Robinson 等人 (2021)](https://arxiv.org/abs/2010.04592) 修改了采样概率，通过将概率 $p^-_x(x’)$ 权重提高使其与锚点样本的相似度成比例，从而针对难负样本。新的采样概率 $q_\beta(x^-)$ 为：

> Following the above annotation, [Robinson et al. (2021)](https://arxiv.org/abs/2010.04592) modified the sampling probabilities to target at hard negatives by up-weighting the probability $p^-_x(x’)$ to be proportional to its similarity to the anchor sample. The new sampling probability $q_\beta(x^-)$ is:

$$
q_\beta(\mathbf{x}^-) \propto \exp(\beta f(\mathbf{x})^\top f(\mathbf{x}^-)) \cdot p(\mathbf{x}^-)
$$

其中 $\beta$ 是一个需要调整的超参数。

> where $\beta$ is a hyperparameter to tune.

我们可以使用重要性采样来估计分母中的第二项 $\mathbb{E}_{\mathbf{x}^- \sim q_\beta} [\exp(f(\mathbf{x})^\top f(\mathbf{x}^-))]$，其中两个配分函数 $Z_\beta, Z^+_\beta$ 都可以通过经验进行估计。

> We can estimate the second term in the denominator $\mathbb{E}_{\mathbf{x}^- \sim q_\beta} [\exp(f(\mathbf{x})^\top f(\mathbf{x}^-))]$ using importance sampling where both the partition functions $Z_\beta, Z^+_\beta$ can be estimated empirically.

$$
\begin{aligned}
\mathbb{E}_{\mathbf{u} \sim q_\beta} [\exp(f(\mathbf{x})^\top f(\mathbf{u}))] &= \mathbb{E}_{\mathbf{u} \sim p} [\frac{q_\beta}{p}\exp(f(\mathbf{x})^\top f(\mathbf{u}))] = \mathbb{E}_{\mathbf{u} \sim p} [\frac{1}{Z_\beta}\exp((\beta + 1)f(\mathbf{x})^\top f(\mathbf{u}))] \\
\mathbb{E}_{\mathbf{v} \sim q^+_\beta} [\exp(f(\mathbf{x})^\top f(\mathbf{v}))] &= \mathbb{E}_{\mathbf{v} \sim p^+} [\frac{q^+_\beta}{p}\exp(f(\mathbf{x})^\top f(\mathbf{v}))] = \mathbb{E}_{\mathbf{v} \sim p} [\frac{1}{Z^+_\beta}\exp((\beta + 1)f(\mathbf{x})^\top f(\mathbf{v}))]
\end{aligned}
$$

![Pseudo code for computing NCE loss, debiased contrastive loss, and hard negative sample objective when setting $M=1$. (Image source: Robinson et al., 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/contrastive-hard-negatives-code.png)

### 视觉：图像嵌入

> Vision: Image Embedding

#### 图像增强

> Image Augmentations

视觉领域中对比表示学习的大多数方法都依赖于通过应用一系列数据增强技术来创建样本的噪声版本。增强应该显著改变其视觉外观，但保持语义含义不变。

> Most approaches for contrastive representation learning in the vision domain rely on creating a noise version of a sample by applying a sequence of data augmentation techniques. The augmentation should significantly change its visual appearance but keep the semantic meaning unchanged.

##### 基本图像增强

> Basic Image Augmentation

有许多方法可以在保留图像语义含义的同时对其进行修改。我们可以使用以下任何一种增强方法或多种操作的组合。

> There are many ways to modify an image while retaining its semantic meaning. We can use any one of the following augmentation or a composition of multiple operations.

- 随机裁剪，然后调整回原始大小。
- 随机颜色失真
- 随机高斯模糊
- 随机颜色抖动
- 随机水平翻转
- 随机灰度转换
- 多裁剪增强：使用两个标准分辨率裁剪，并采样一组额外的低分辨率裁剪，这些裁剪仅覆盖图像的小部分。使用低分辨率裁剪可以降低计算成本。 ([SwAV](https://lilianweng.github.io/posts/2021-05-31-contrastive/#swav))
- 还有更多……

> • Random cropping and then resize back to the original size.
> • Random color distortions
> • Random Gaussian blur
> • Random color jittering
> • Random horizontal flip
> • Random grayscale conversion
> • Multi-crop augmentation: Use two standard resolution crops and sample a set of additional low resolution crops that cover only small parts of the image. Using low resolution crops reduces the compute cost. ([SwAV](https://lilianweng.github.io/posts/2021-05-31-contrastive/#swav))
> • And many more …

##### 增强策略

> Augmentation Strategies

许多框架旨在学习好的数据增强策略（即多种变换的组合）。以下是一些常见的策略。

> Many frameworks are designed for learning good data augmentation strategies (i.e. a composition of multiple transforms). Here are a few common ones.

- [AutoAugment](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#AutoAugment) ([Cubuk, et al. 2018](https://arxiv.org/abs/1805.09501))：受 [NAS](https://lilianweng.github.io/posts/2020-08-06-nas/) 启发，AutoAugment 将学习图像分类最佳数据增强操作（即剪切、旋转、反转等）的问题框定为强化学习问题，并寻找在评估集上产生最高准确率的组合。
- RandAugment ([Cubuk et al., 2019](https://arxiv.org/abs/1909.13719))：RandAugment 通过使用单个幅度参数控制不同变换操作的幅度，大大减小了 AutoAugment 的搜索空间。
- PBA (基于种群的增强；[Ho et al., 2019](https://arxiv.org/abs/1905.05393))：PBA 将 PBT ([Jaderberg et al, 2017](https://arxiv.org/abs/1711.09846)) 与 AutoAugment 结合，使用进化算法并行训练一组子模型，以演化出最佳增强策略。
- UDA (无监督数据增强；[Xie et al., 2019](https://arxiv.org/abs/1904.12848))：在一组可能的增强策略中，UDA 选择那些能够最小化未标记示例的预测分布与其未标记增强版本之间 KL 散度的策略。

> • [AutoAugment](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#AutoAugment) ([Cubuk, et al. 2018](https://arxiv.org/abs/1805.09501)): Inspired by [NAS](https://lilianweng.github.io/posts/2020-08-06-nas/), AutoAugment frames the problem of learning best data augmentation operations (i.e. shearing, rotation, invert, etc.) for image classification as an RL problem and looks for the combination that leads to the highest accuracy on the evaluation set.
> • RandAugment ([Cubuk et al., 2019](https://arxiv.org/abs/1909.13719)): RandAugment greatly reduces the search space of AutoAugment by controlling the magnitudes of different transformation operations with a single magnitude parameter.
> • PBA (Population based augmentation; [Ho et al., 2019](https://arxiv.org/abs/1905.05393)): PBA combined PBT ([Jaderberg et al, 2017](https://arxiv.org/abs/1711.09846)) with AutoAugment, using the evolutionary algorithm to train a population of children models in parallel to evolve the best augmentation strategies.
> • UDA (Unsupervised Data Augmentation; [Xie et al., 2019](https://arxiv.org/abs/1904.12848)): Among a set of possible augmentation strategies, UDA selects those to minimize the KL divergence between the predicted distribution over an unlabelled example and its unlabelled augmented version.

##### 图像混合

> Image Mixture

图像混合方法可以从现有数据点构建新的训练示例。

> Image mixture methods can construct new training examples from existing data points.

• Mixup ([Zhang et al., 2018](https://arxiv.org/abs/1710.09412))：它通过创建两个现有图像 $I_1$ 和 $I_2$ 的加权像素级组合来运行全局级混合：$I_\text{mixup} \gets \alpha I_1 + (1-\alpha) I_2$ 和 $\alpha \in [0, 1]$。

• Cutmix ([Yun et al., 2019](https://arxiv.org/abs/1905.04899))：Cutmix 通过将一幅图像的局部区域与另一幅图像的其余部分结合来生成新示例，从而进行区域级混合。$I_\text{cutmix} \gets \mathbf{M}_b \odot I_1 + (1-\mathbf{M}_b) \odot I_2$，其中 $\mathbf{M}_b \in \{0, 1\}^I$ 是二值掩码，$\odot$ 是逐元素乘法。这等同于用另一幅图像的相同区域填充 cutout ([DeVries & Taylor 2017](https://arxiv.org/abs/1708.04552)) 区域。

• MoCHi (“对比硬负样本混合”；[Kalantidis et al. 2020](https://arxiv.org/abs/2010.01028))：给定一个查询 $\mathbf{q}$，MoCHi 维护一个包含 $K$ 个负特征 $Q=\{\mathbf{n}_1, \dots, \mathbf{n}_K \}$ 的队列，并按与查询 $\mathbf{q}^\top \mathbf{n}$ 的相似度降序排列这些负特征。队列中的前 $N$ 项被认为是“最硬”的负样本 $Q^N$。然后可以通过 $\mathbf{h} = \tilde{\mathbf{h}} / |\tilde{\mathbf{h}}|$ 生成合成硬样本，其中 $\tilde{\mathbf{h}} = \alpha\mathbf{n}_i + (1-\alpha) \mathbf{n}_j$ 和 $\alpha \in (0, 1)$。通过与查询特征 $\mathbf{h}’ = \tilde{\mathbf{h}’} / |\tilde{\mathbf{h}’}|_2$ 混合可以创建更硬的样本，其中 $\tilde{\mathbf{h}’} = \beta\mathbf{q} + (1-\beta) \mathbf{n}_j$ 和 $\beta \in (0, 0.5)$。

英文原文：

• Mixup ([Zhang et al., 2018](https://arxiv.org/abs/1710.09412)): It runs global-level mixture by creating a weighted pixel-wise combination of two existing images $I_1$ and $I_2$: $I_\text{mixup} \gets \alpha I_1 + (1-\alpha) I_2$ and $\alpha \in [0, 1]$.

• Cutmix ([Yun et al., 2019](https://arxiv.org/abs/1905.04899)): Cutmix does region-level mixture by generating a new example by combining a local region of one image with the rest of the other image. $I_\text{cutmix} \gets \mathbf{M}_b \odot I_1 + (1-\mathbf{M}_b) \odot I_2$, where $\mathbf{M}_b \in \{0, 1\}^I$ is a binary mask and $\odot$ is element-wise multiplication. It is equivalent to filling the cutout ([DeVries & Taylor 2017](https://arxiv.org/abs/1708.04552)) region with the same region from another image.

• MoCHi (“Mixing of Contrastive Hard Negatives”; [Kalantidis et al. 2020](https://arxiv.org/abs/2010.01028)): Given a query $\mathbf{q}$, MoCHi maintains a queue of $K$ negative features $Q=\{\mathbf{n}_1, \dots, \mathbf{n}_K \}$ and sorts these negative features by similarity to the query, $\mathbf{q}^\top \mathbf{n}$, in descending order. The first $N$ items in the queue are considered as the hardest negatives, $Q^N$. Then synthetic hard examples can be generated by $\mathbf{h} = \tilde{\mathbf{h}} / |\tilde{\mathbf{h}}|$ where $\tilde{\mathbf{h}} = \alpha\mathbf{n}_i + (1-\alpha) \mathbf{n}_j$ and $\alpha \in (0, 1)$. Even harder examples can be created by mixing with the query feature, $\mathbf{h}’ = \tilde{\mathbf{h}’} / |\tilde{\mathbf{h}’}|_2$ where $\tilde{\mathbf{h}’} = \beta\mathbf{q} + (1-\beta) \mathbf{n}_j$ and $\beta \in (0, 0.5)$.

#### 并行增强

> Parallel Augmentation

这类方法生成一个锚点图像的两个噪声版本，旨在学习表示，使这两个增强样本共享相同的嵌入。

> This category of approaches produce two noise versions of one anchor image and aim to learn representation such that these two augmented samples share the same embedding.

##### SimCLR

> SimCLR

**SimCLR** ([Chen et al, 2020](https://arxiv.org/abs/2002.05709)) 提出了一个用于视觉表示对比学习的简单框架。它通过在潜在空间中通过对比损失最大化同一样本的不同增强视图之间的一致性来学习视觉输入的表示。

> **SimCLR** ([Chen et al, 2020](https://arxiv.org/abs/2002.05709)) proposed a simple framework for contrastive learning of visual representations. It learns representations for visual inputs by maximizing agreement between differently augmented views of the same sample via a contrastive loss in the latent space.

![A simple framework for contrastive learning of visual representations. (Image source: Chen et al, 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/SimCLR.png)

1\. 随机采样一个包含 $N$ 个样本的小批量，每个样本应用两种不同的数据增强操作，总共得到 $2N$ 个增强样本。

英文原文：

1\. Randomly sample a minibatch of $N$ samples and each sample is applied with two different data augmentation operations, resulting in $2N$ augmented samples in total.

$$
\tilde{\mathbf{x}}_i = t(\mathbf{x}),\quad\tilde{\mathbf{x}}_j = t'(\mathbf{x}),\quad t, t' \sim \mathcal{T}
$$

其中两个独立的数据增强操作符，$t$ 和 $t’$，从同一增强族 $\mathcal{T}$ 中采样。数据增强包括随机裁剪、随机翻转调整大小、颜色失真和高斯模糊。

> where two separate data augmentation operators, $t$ and $t’$, are sampled from the same family of augmentations $\mathcal{T}$. Data augmentation includes random crop, resize with random flip, color distortions, and Gaussian blur.

1\. 给定一个正样本对，其他 $2(N-1)$ 个数据点被视为负样本。表示由基础编码器 $f(.)$ 生成：

英文原文：

1\. Given one positive pair, other $2(N-1)$ data points are treated as negative samples. The representation is produced by a base encoder $f(.)$:

$$
\mathbf{h}_i = f(\tilde{\mathbf{x}}_i),\quad \mathbf{h}_j = f(\tilde{\mathbf{x}}_j)
$$

1\. 对比学习损失使用余弦相似度 $\text{sim}(.,.)$ 定义。请注意，损失作用于表示 $g(.)$ 的一个额外投影层，而不是直接作用于表示空间。但只有表示 $\mathbf{h}$ 用于下游任务。

英文原文：

1\. The contrastive learning loss is defined using cosine similarity $\text{sim}(.,.)$. Note that the loss operates on an extra projection layer of the representation $g(.)$ rather than on the representation space directly. But only the representation $\mathbf{h}$ is used for downstream tasks.

$$
\begin{aligned}
\mathbf{z}_i &= g(\mathbf{h}_i),\quad
\mathbf{z}_j = g(\mathbf{h}_j) \\
\mathcal{L}_\text{SimCLR}^{(i,j)} &= - \log\frac{\exp(\text{sim}(\mathbf{z}_i, \mathbf{z}_j) / \tau)}{\sum_{k=1}^{2N} \mathbb{1}_{[k \neq i]} \exp(\text{sim}(\mathbf{z}_i, \mathbf{z}_k) / \tau)}
\end{aligned}
$$

其中 $\mathbb{1}_{[k \neq i]}$ 是指示函数：如果 $k\neq i$ 则为 1，否则为 0。

> where $\mathbb{1}_{[k \neq i]}$ is an indicator function: 1 if $k\neq i$ 0 otherwise.

SimCLR 需要较大的批量大小以包含足够的负样本来获得良好性能。

> SimCLR needs a large batch size to incorporate enough negative samples to achieve good performance.

![The algorithm for SimCLR. (Image source: Chen et al, 2020 ).](https://lilianweng.github.io/posts/2021-05-31-contrastive/SimCLR-algo.png)

##### Barlow Twins

> Barlow Twins

**Barlow Twins** ([Zbontar et al. 2021](https://arxiv.org/abs/2103.03230)) 将样本的两个扭曲版本输入到同一个网络中以提取特征，并学习使这两组输出特征之间的*互相关矩阵*接近单位矩阵。目标是使一个样本的不同扭曲版本的表示向量保持相似，同时最小化这些向量之间的冗余。

> **Barlow Twins** ([Zbontar et al. 2021](https://arxiv.org/abs/2103.03230)) feeds two distorted versions of samples into the same network to extract features and learns to make the *cross-correlation matrix* between these two groups of output features close to the identity. The goal is to keep the representation vectors of different distorted versions of one sample similar, while minimizing the redundancy between these vectors.

![Illustration of Barlow Twins learning pipeline. (Image source: Zbontar et al. 2021 ).](https://lilianweng.github.io/posts/2021-05-31-contrastive/barlow-twins.png)

设 $\mathcal{C}$ 是在批处理维度上，由两个相同网络的输出之间计算得到的互相关矩阵。$\mathcal{C}$ 是一个方阵，其大小与特征网络的输出维度相同。矩阵 $\mathcal{C}_{ij}$ 中的每个条目是网络输出向量维度在索引 $i, j$ 和批处理索引 $b$、$\mathbf{z}_{b,i}^A$ 和 $\mathbf{z}_{b,j}^B$ 之间的余弦相似度，其值介于 -1（即完美负相关）和 1（即完美正相关）之间。

> Let $\mathcal{C}$ be a cross-correlation matrix computed between outputs from two identical networks along the batch dimension. $\mathcal{C}$ is a square matrix with the size same as the feature network’s output dimensionality. Each entry in the matrix $\mathcal{C}_{ij}$ is the cosine similarity between network output vector dimension at index $i, j$ and batch index $b$, $\mathbf{z}_{b,i}^A$ and $\mathbf{z}_{b,j}^B$, with a value between -1 (i.e. perfect anti-correlation) and 1 (i.e. perfect correlation).

$$
\begin{aligned}
\mathcal{L}_\text{BT} &= \underbrace{\sum_i (1-\mathcal{C}_{ii})^2}_\text{invariance term} + \lambda \underbrace{\sum_i\sum_{i\neq j} \mathcal{C}_{ij}^2}_\text{redundancy reduction term} \\ \text{where } \mathcal{C}_{ij} &= \frac{\sum_b \mathbf{z}^A_{b,i} \mathbf{z}^B_{b,j}}{\sqrt{\sum_b (\mathbf{z}^A_{b,i})^2}\sqrt{\sum_b (\mathbf{z}^B_{b,j})^2}}
\end{aligned}
$$

Barlow Twins 在自监督学习方面与 SOTA 方法具有竞争力。它自然地避免了平凡常数（即坍塌表示），并且对不同的训练批次大小具有鲁棒性。

> Barlow Twins is competitive with SOTA methods for self-supervised learning. It naturally avoids trivial constants (i.e. collapsed representations), and is robust to different training batch sizes.

![Algorithm of Barlow Twins in Pytorch style pseudo code. (Image source: Zbontar et al. 2021 ).](https://lilianweng.github.io/posts/2021-05-31-contrastive/barlow-twins-algo.png)

##### BYOL

> BYOL

与上述方法不同的是，有趣的是，**BYOL** (Bootstrap Your Own Latent; [Grill, et al 2020](https://arxiv.org/abs/2006.07733)) 声称*不使用负样本*即可达到新的最先进结果。它依赖于两个神经网络，分别称为*在线*网络和*目标*网络，它们相互作用并相互学习。目标网络（由 `\xi` 参数化）与在线网络（由 `\theta` 参数化）具有相同的架构，但使用 Polyak 平均权重 $\xi \leftarrow \tau \xi + (1-\tau) \theta$。

英文原文：Different from the above approaches, interestingly, BYOL (Bootstrap Your Own Latent; [Grill, et al 2020](https://arxiv.org/abs/2006.07733)) claims to achieve a new state-of-the-art results *without using negative samples*. It relies on two neural networks, referred to as *online* and *target* networks that interact and learn from each other. The target network (parameterized by `\xi`) has the same architecture as the online one (parameterized by `\theta`), but with polyak averaged weights, 

$\xi \leftarrow \tau \xi + (1-\tau) \theta$.

目标是学习一个可用于下游任务的表示 $y$。由 $\theta$ 参数化的在线网络包含：

> The goal is to learn a presentation $y$ that can be used in downstream tasks. The online network parameterized by $\theta$ contains:

• 一个编码器 $f_\theta$；

• 一个投影器 $g_\theta$；

• 一个预测器 $q_\theta$。

英文原文：

• An encoder $f_\theta$;

• A projector $g_\theta$;

• A predictor $q_\theta$.

目标网络具有相同的网络架构，但参数 $\xi$ 不同，通过 Polyak 平均 $\theta$ 进行更新：$\xi \leftarrow \tau \xi + (1-\tau) \theta$。

> The target network has the same network architecture, but with different parameter $\xi$, updated by polyak averaging $\theta$: $\xi \leftarrow \tau \xi + (1-\tau) \theta$.

![The model architecture of BYOL. After training, we only care about $f\_\theta$ for producing representation, $y=f\_\theta(x)$, and everything else is discarded. $\text{sg}$ means stop gradient. (Image source: Grill, et al 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/BYOL.png)

给定图像 $\mathbf{x}$，BYOL 损失的构建方式如下：

> Given an image $\mathbf{x}$, the BYOL loss is constructed as follows:

• 创建两个增强视图：$\mathbf{v}=t(\mathbf{x}); \mathbf{v}’=t’(\mathbf{x})$，其中增强采样自 $t \sim \mathcal{T}, t’ \sim \mathcal{T}’$；

• 然后它们被编码成表示 $\mathbf{y}_\theta=f_\theta(\mathbf{v}), \mathbf{y}’=f_\xi(\mathbf{v}’)$；

• 然后它们被投影到潜在变量 $\mathbf{z}_\theta=g_\theta(\mathbf{y}_\theta), \mathbf{z}’=g_\xi(\mathbf{y}’)$；

• 在线网络输出一个预测 $q_\theta(\mathbf{z}_\theta)$；

• $q_\theta(\mathbf{z}_\theta)$ 和 $\mathbf{z}’$ 都经过 L2 归一化，得到 $\bar{q}_\theta(\mathbf{z}_\theta) = q_\theta(\mathbf{z}_\theta) / | q_\theta(\mathbf{z}_\theta) |$ 和 $\bar{\mathbf{z}’} = \mathbf{z}’ / |\mathbf{z}’|$；

• 损失 $\mathcal{L}^\text{BYOL}_\theta$ 是 L2 归一化预测 $\bar{q}_\theta(\mathbf{z})$ 和 $\bar{\mathbf{z}’}$ 之间的均方误差；

• 另一个对称损失 $\tilde{\mathcal{L}}^\text{BYOL}_\theta$ 可以通过切换 $\mathbf{v}’$ 和 $\mathbf{v}$ 来生成；也就是说，将 $\mathbf{v}’$ 输入到在线网络，将 $\mathbf{v}$ 输入到目标网络。

• 最终损失是 $\mathcal{L}^\text{BYOL}_\theta + \tilde{\mathcal{L}}^\text{BYOL}_\theta$，并且只优化参数 $\theta$。

英文原文：

• Create two augmented views: $\mathbf{v}=t(\mathbf{x}); \mathbf{v}’=t’(\mathbf{x})$ with augmentations sampled $t \sim \mathcal{T}, t’ \sim \mathcal{T}’$;

• Then they are encoded into representations, $\mathbf{y}_\theta=f_\theta(\mathbf{v}), \mathbf{y}’=f_\xi(\mathbf{v}’)$;

• Then they are projected into latent variables, $\mathbf{z}_\theta=g_\theta(\mathbf{y}_\theta), \mathbf{z}’=g_\xi(\mathbf{y}’)$;

• The online network outputs a prediction $q_\theta(\mathbf{z}_\theta)$;

• Both $q_\theta(\mathbf{z}_\theta)$ and $\mathbf{z}’$ are L2-normalized, giving us $\bar{q}_\theta(\mathbf{z}_\theta) = q_\theta(\mathbf{z}_\theta) / | q_\theta(\mathbf{z}_\theta) |$ and $\bar{\mathbf{z}’} = \mathbf{z}’ / |\mathbf{z}’|$;

• The loss $\mathcal{L}^\text{BYOL}_\theta$ is MSE between L2-normalized prediction $\bar{q}_\theta(\mathbf{z})$ and $\bar{\mathbf{z}’}$;

• The other symmetric loss $\tilde{\mathcal{L}}^\text{BYOL}_\theta$ can be generated by switching $\mathbf{v}’$ and $\mathbf{v}$; that is, feeding $\mathbf{v}’$ to online network and $\mathbf{v}$ to target network.

• The final loss is $\mathcal{L}^\text{BYOL}_\theta + \tilde{\mathcal{L}}^\text{BYOL}_\theta$ and only  parameters $\theta$ are optimized.

与大多数流行的基于对比学习的方法不同，BYOL 不使用负样本对。大多数自举方法依赖于伪标签或聚类索引，但 BYOL 直接自举潜在表示。

> Unlike most popular contrastive learning based approaches, BYOL does not use negative pairs. Most bootstrapping approaches rely on pseudo-labels or cluster indices, but BYOL directly boostrapps the latent representation.

令人非常有趣和惊讶的是，*没有*负样本，BYOL 仍然表现良好。后来我偶然看到了 Abe Fetterman 和 Josh Albrecht 的这篇[文章](https://untitled-ai.github.io/understanding-self-supervised-contrastive-learning.html)，他们在尝试复现 BYOL 时强调了两个令人惊讶的发现：

> It is quite interesting and surprising that *without* negative samples, BYOL still works well. Later I ran into this [post](https://untitled-ai.github.io/understanding-self-supervised-contrastive-learning.html) by Abe Fetterman & Josh Albrecht, they highlighted two surprising findings while they were trying to reproduce BYOL:

1\. 当*移除批归一化*时，BYOL 的性能通常不优于随机。

2\. 批归一化的存在隐式地导致了一种对比学习。他们认为使用负样本对于避免模型崩溃很重要（即，如果你对每个数据点都使用全零表示会怎样？）。批归一化*隐式地*注入了对负样本的依赖，因为无论一批输入有多相似，其值都会被重新分布（分散$\sim \mathcal{N}(0, 1$），因此批归一化可以防止模型崩溃。如果你正在这个领域工作，强烈建议你阅读[完整文章](https://untitled-ai.github.io/understanding-self-supervised-contrastive-learning.html)。

英文原文：

1\. BYOL generally performs no better than random when *batch normalization is removed*.

2\. The presence of batch normalization implicitly causes a form of contrastive learning.
They believe that using negative samples is important for avoiding model collapse (i.e. what if you use all-zeros representation for every data point?). Batch normalization injects dependency on negative samples *inexplicitly* because no matter how similar a batch of inputs are, the values are re-distributed (spread out $\sim \mathcal{N}(0, 1$) and therefore batch normalization prevents model collapse. Strongly recommend you to read the [full article](https://untitled-ai.github.io/understanding-self-supervised-contrastive-learning.html) if you are working in this area.

#### 记忆库

> Memory Bank

在每个批次中计算大量负样本的嵌入是非常昂贵的。一种常见的方法是将表示存储在内存中，以牺牲数据新鲜度来换取更低的计算成本。

> Computing embeddings for a large number of negative samples in every batch is extremely expensive. One common approach is to store the representation in memory to trade off data staleness for cheaper compute.

##### 基于记忆库的实例判别

> Instance Discrimination with Memoy Bank

**实例对比学习** ([Wu 等人，2018](https://arxiv.org/abs/1805.01978v1)) 通过将每个实例视为*一个独立的类别*，将类别监督推向极致。这意味着“类别”的数量将与训练数据集中的样本数量相同。因此，用如此多的头训练一个softmax层是不可行的，但它可以通过[NCE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#nce)来近似。

> **Instance contrastive learning** ([Wu et al, 2018](https://arxiv.org/abs/1805.01978v1)) pushes the class-wise supervision to the extreme by considering each instance as *a distinct class of its own*. It implies that the number of “classes” will be the same as the number of samples in the training dataset. Hence, it is unfeasible to train a softmax layer with these many heads, but instead it can be approximated by [NCE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#nce).

![The training pipeline of instance-level contrastive learning. The learned embedding is L2-normalized. (Image source: Wu et al, 2018 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/instance-level-discrimination.png)

设$\mathbf{v} = f_\theta(x)$是一个要学习的嵌入函数，并且该向量被归一化为具有$|\mathbf{v}|=1$。一个非参数分类器预测样本$\mathbf{v}$属于类别$i$的概率，其温度参数为$\tau$：

> Let $\mathbf{v} = f_\theta(x)$ be an embedding function to learn and the vector is normalized to have $|\mathbf{v}|=1$. A non-parametric classifier predicts the probability of a sample $\mathbf{v}$ belonging to class $i$ with a temperature parameter $\tau$:

$$
P(C=i\vert \mathbf{v}) = \frac{\exp(\mathbf{v}_i^\top \mathbf{v} / \tau)}{\sum_{j=1}^n \exp(\mathbf{v}_j^\top \mathbf{v} / \tau)}
$$

他们没有每次都计算所有样本的表示，而是实现了一个**记忆库**，用于存储来自过去迭代的样本表示到数据库中。令$V=\{ \mathbf{v}_i \}$为记忆库，$\mathbf{f}_i = f_\theta(\mathbf{x}_i)$为通过网络前向传播生成的特征。在比较成对相似性时，我们可以使用来自记忆库的表示$\mathbf{v}_i$，而不是从网络前向传播的特征$\mathbf{f}_i$。

英文原文：Instead of computing the representations for all the samples every time, they implement an Memory Bank for storing sample representation in the database from past iterations. Let 

$V=\{ \mathbf{v}_i \}$ be the memory bank and 

$\mathbf{f}_i = f_\theta(\mathbf{x}_i)$ be the feature generated by forwarding the network. We can use the representation from the memory bank 

$\mathbf{v}_i$ instead of the feature forwarded from the network 

$\mathbf{f}_i$ when comparing pairwise similarity.

分母理论上需要访问所有样本的表示，但这在实践中过于昂贵。相反，我们可以通过蒙特卡洛近似，使用$M$个随机子集索引$\{j_k\}_{k=1}^M$来估计它。

> The denominator theoretically requires access to the representations of all the samples, but that is too expensive in practice. Instead we can estimate it via Monte Carlo approximation using a random subset of $M$ indices $\{j_k\}_{k=1}^M$.

$$
P(i\vert \mathbf{v}) 
= \frac{\exp(\mathbf{v}^\top \mathbf{f}_i / \tau)}{\sum_{j=1}^N \exp(\mathbf{v}_j^\top \mathbf{f}_i / \tau)}
\simeq \frac{\exp(\mathbf{v}^\top \mathbf{f}_i / \tau)}{\frac{N}{M} \sum_{k=1}^M \exp(\mathbf{v}_{j_k}^\top \mathbf{f}_i / \tau)}
$$

由于每个类别只有一个实例，训练不稳定且波动很大。为了提高训练的平滑性，他们基于[近端优化方法](https://web.stanford.edu/~boyd/papers/prox_algs.html)在损失函数中为正样本引入了一个额外项。最终的NCE损失目标如下所示：

> Because there is only one instance per class, the training is unstable and fluctuates a lot. To improve the training smoothness, they introduced an extra term for positive samples in the loss function based on the [proximal optimization method](https://web.stanford.edu/~boyd/papers/prox_algs.html). The final NCE loss objective looks like:

$$
\begin{aligned}
\mathcal{L}_\text{instance} &= - \mathbb{E}_{P_d}\big[\log h(i, \mathbf{v}^{(t-1)}_i) - \lambda \|\mathbf{v}^{(t)}_i - \mathbf{v}^{(t-1)}_i\|^2_2\big] - M\mathbb{E}_{P_n}\big[\log(1 - h(i, \mathbf{v}'^{(t-1)})\big] \\
h(i, \mathbf{v}) &= \frac{P(i\vert\mathbf{v})}{P(i\vert\mathbf{v}) + MP_n(i)} \text{ where the noise distribution is uniform }P_n = 1/N
\end{aligned}
$$

其中$\{ \mathbf{v}^{(t-1)} \}$是存储在记忆库中来自上一次迭代的嵌入。随着学习到的嵌入收敛，迭代之间的差异$|\mathbf{v}^{(t)}_i - \mathbf{v}^{(t-1)}_i|^2_2$将逐渐消失。

> where $\{ \mathbf{v}^{(t-1)} \}$ are embeddings stored in the memory bank from the previous iteration. The difference between iterations $|\mathbf{v}^{(t)}_i - \mathbf{v}^{(t-1)}_i|^2_2$ will gradually vanish as the learned embedding converges.

##### MoCo 与 MoCo-V2

> MoCo & MoCo-V2

**动量对比**（**MoCo**；[He et al, 2019](https://arxiv.org/abs/1911.05722)）提供了一个无监督学习视觉表示的框架，作为一种*动态字典查找*。该字典被构建为一个大型的FIFO队列，其中包含数据样本的编码表示。

> **Momentum Contrast** (**MoCo**; [He et al, 2019](https://arxiv.org/abs/1911.05722)) provides a framework of unsupervised learning visual representation as a *dynamic dictionary look-up*. The dictionary is structured as a large FIFO queue of encoded representations of data samples.

给定一个查询样本$\mathbf{x}_q$，我们通过编码器获得一个查询表示$\mathbf{q} = f_q(\mathbf{x}_q)$。字典中的一系列键表示$\{\mathbf{k}_1, \mathbf{k}_2, \dots \}$由动量编码器编码$\mathbf{k}_i = f_k (\mathbf{x}^k_i)$。假设其中有一个*正*键$\mathbf{k}^+$在字典中与$\mathbf{q}$匹配。在论文中，他们创建了$\mathbf{k}^+$，方法是使用$\mathbf{x}_q$的不同[增强](https://lilianweng.github.io/posts/2021-05-31-contrastive/#image-augmentations)。然后[InfoNCE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#infonce)对比损失，其温度参数为$\tau$用于一个正样本和$N-1$个负样本：

> Given a query sample $\mathbf{x}_q$, we get a query representation through an encoder $\mathbf{q} = f_q(\mathbf{x}_q)$. A list of key representations $\{\mathbf{k}_1, \mathbf{k}_2, \dots \}$ in the dictionary are encoded by a momentum encoder $\mathbf{k}_i = f_k (\mathbf{x}^k_i)$. Let’s assume among them there is a single *positive* key $\mathbf{k}^+$ in the dictionary that matches $\mathbf{q}$. In the paper, they create $\mathbf{k}^+$ using a noise copy of $\mathbf{x}_q$ with different [augmentation](https://lilianweng.github.io/posts/2021-05-31-contrastive/#image-augmentations). Then the [InfoNCE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#infonce) contrastive loss with temperature $\tau$ is used over one positive and $N-1$ negative samples:

$$
\mathcal{L}_\text{MoCo} = - \log \frac{\exp(\mathbf{q} \cdot \mathbf{k}^+ / \tau)}{\sum_{i=1}^N \exp(\mathbf{q} \cdot \mathbf{k}_i / \tau)}
$$

与[记忆库](https://lilianweng.github.io/posts/2021-05-31-contrastive/#instance-discrimination-with-memoy-bank)相比，MoCo 中基于队列的字典使我们能够重用紧邻前一个 mini-batch 数据的表示。

> Compared to the [memory bank](https://lilianweng.github.io/posts/2021-05-31-contrastive/#instance-discrimination-with-memoy-bank), a queue-based dictionary in MoCo enables us to reuse representations of immediately preceding mini-batches of data.

MoCo 字典作为队列是不可微分的，因此我们不能依赖反向传播来更新键编码器 $f_k$。一种朴素的方法可能是对 $f_q$ 和 $f_k$ 都使用相同的编码器。不同的是，MoCo 提出使用带有动量系数 $m \in [0, 1)$ 的基于动量的更新。假设 $f_q$ 和 $f_k$ 的参数分别标记为 $\theta_q$ 和 $\theta_k$。

> The MoCo dictionary is not differentiable as a queue, so we cannot rely on back-propagation to update the key encoder $f_k$. One naive way might be to use the same encoder for both $f_q$ and $f_k$. Differently, MoCo proposed to use a momentum-based update with a momentum coefficient $m \in [0, 1)$. Say, the parameters of $f_q$ and $f_k$ are labeled as $\theta_q$ and $\theta_k$, respectively.

$$
\theta_k \leftarrow m \theta_k + (1-m) \theta_q
$$

![Illustration of how Momentum Contrast (MoCo) learns visual representations. (Image source: He et al, 2019 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/MoCo.png)

MoCo 相较于 [SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr) 的优势在于 MoCo 将批次大小与负样本数量解耦，而 SimCLR 需要较大的批次大小才能获得足够的负样本，并且在批次大小减小时性能会下降。

> The advantage of MoCo compared to [SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr) is that MoCo decouples the batch size from the number of negatives, but SimCLR requires a large batch size in order to have enough negative samples and suffers performance drops when their batch size is reduced.

SimCLR 中的两项设计，即 (1) MLP 投影头和 (2) 更强的数据增强，被证明非常高效。**MoCo V2** ([Chen et al, 2020](https://arxiv.org/abs/2003.04297)) 结合了这两项设计，在不依赖超大批次大小的情况下，实现了更好的迁移性能。

> Two designs in SimCLR, namely, (1) an MLP projection head and (2) stronger data augmentation, are proved to be very efficient. **MoCo V2** ([Chen et al, 2020](https://arxiv.org/abs/2003.04297)) combined these two designs, achieving even better transfer performance with no dependency on a very large batch size.

##### CURL

> CURL

**CURL**（[Srinivas, et al. 2020](https://arxiv.org/abs/2004.04136)）将上述思想应用于[强化学习](https://lilianweng.github.io/posts/2018-02-19-rl-overview/)。它通过匹配原始观测的两个数据增强版本（`o_q`和`o_k`）的嵌入，为强化学习任务学习视觉表示，`o`通过对比损失。CURL 主要依赖随机裁剪数据增强。键编码器被实现为一个动量编码器，其权重是查询编码器权重的 EMA，与[MoCo](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2)中相同。

英文原文：CURL ([Srinivas, et al. 2020](https://arxiv.org/abs/2004.04136)) applies the above ideas in [Reinforcement Learning](https://lilianweng.github.io/posts/2018-02-19-rl-overview/). It learns a visual representation for RL tasks by matching embeddings of two data-augmented versions, `o_q` and `o_k`, of the raw observation `o` via contrastive loss. CURL primarily relies on random crop data augmentation. The key encoder is implemented as a momentum encoder with weights as EMA of the query encoder weights, same as in [MoCo](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2).

RL 与监督视觉任务之间的一个显著区别在于，RL 依赖于连续帧之间的*时间一致性*。因此，CURL 对每组帧一致地应用数据增强，以保留关于观测时间结构的信息。

> One significant difference between RL and supervised visual tasks is that RL depends on *temporal consistency* between consecutive frames. Therefore, CURL applies augmentation consistently on each stack of frames to retain information about the temporal structure of the observation.

![The architecture of CURL. (Image source: Srinivas, et al. 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/CURL.png)

#### 特征聚类

> Feature Clustering

##### DeepCluster

> DeepCluster

**DeepCluster** ([Caron et al. 2018](https://arxiv.org/abs/1807.05520)) 通过 k-means 迭代地聚类特征，并使用聚类分配作为伪标签来提供监督信号。

> **DeepCluster** ([Caron et al. 2018](https://arxiv.org/abs/1807.05520)) iteratively clusters features via k-means and uses cluster assignments as pseudo labels to provide supervised signals.

![Illustration of DeepCluster method which iteratively clusters deep features and uses the cluster assignments as pseudo-labels. (Image source: Caron et al. 2018 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/deepcluster.png)

在每次迭代中，DeepCluster 使用先前的表示对数据点进行聚类，然后将新的聚类分配作为新表示的分类目标。然而，这种迭代过程容易产生平凡解。虽然避免了使用负样本对，但它需要一个昂贵的聚类阶段和特定的预防措施，以避免陷入平凡解。

> In each iteration, DeepCluster clusters data points using the prior representation and then produces the new cluster assignments as the classification targets for the new representation. However this iterative process is prone to trivial solutions. While avoiding the use of negative pairs, it requires a costly clustering phase and specific precautions to avoid collapsing to trivial solutions.

##### SwAV

> SwAV

**SwAV** (*多视图间交换分配*; [Caron 等人 2020](https://arxiv.org/abs/2006.09882)) 是一种在线对比学习算法。它从图像的增强版本中计算出一个代码，并尝试使用同一图像的另一个增强版本来预测这个代码。

> **SwAV** (*Swapping Assignments between multiple Views*; [Caron et al. 2020](https://arxiv.org/abs/2006.09882)) is an online contrastive learning algorithm. It computes a code from an augmented version of the image and tries to predict this code using another augmented version of the same image.

![Comparison of SwAV and \[contrastive instance learning\](#instance-discrimination-with-memoy-bank). (Image source: Caron et al. 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/SwAV.png)

给定具有两种不同增强的图像特征，$\mathbf{z}_t$ 和 $\mathbf{z}_s$，SwAV 计算出相应的代码 $\mathbf{q}_t$ 和 $\mathbf{q}_s$，损失通过使用 $\ell(.)$ 交换两个代码来量化拟合度，以衡量特征和代码之间的拟合度。

> Given features of images with two different augmentations, $\mathbf{z}_t$ and $\mathbf{z}_s$, SwAV computes corresponding codes $\mathbf{q}_t$ and $\mathbf{q}_s$ and the loss quantifies the fit by swapping two codes using $\ell(.)$ to measure the fit between a feature and a code.

$$
\mathcal{L}_\text{SwAV}(\mathbf{z}_t, \mathbf{z}_s) = \ell(\mathbf{z}_t, \mathbf{q}_s) + \ell(\mathbf{z}_s, \mathbf{q}_t)
$$

交换拟合预测取决于预测代码与一组 $K$ 可训练原型向量 $\mathbf{C} = \{\mathbf{c}_1, \dots, \mathbf{c}_K\}$ 之间的交叉熵。原型向量矩阵在不同批次之间共享，代表每个实例应聚类到的 *锚点簇*。

> The swapped fit prediction depends on the cross entropy between the predicted code and a set of $K$ trainable prototype vectors $\mathbf{C} = \{\mathbf{c}_1, \dots, \mathbf{c}_K\}$. The prototype vector matrix is shared across different batches and represents *anchor clusters* that each instance should be clustered to.

$$
\ell(\mathbf{z}_t, \mathbf{q}_s) = - \sum_k \mathbf{q}^{(k)}_s\log\mathbf{p}^{(k)}_t \text{ where } \mathbf{p}^{(k)}_t = \frac{\exp(\mathbf{z}_t^\top\mathbf{c}_k  / \tau)}{\sum_{k'}\exp(\mathbf{z}_t^\top \mathbf{c}_{k'} / \tau)}
$$

在一个包含 $B$ 特征向量 $\mathbf{Z} = [\mathbf{z}_1, \dots, \mathbf{z}_B]$ 的小批量中，特征和原型向量之间的映射矩阵定义为 $\mathbf{Q} = [\mathbf{q}_1, \dots, \mathbf{q}_B] \in \mathbb{R}_+^{K\times B}$。我们希望最大化特征和原型之间的相似性：

> In a mini-batch containing $B$ feature vectors $\mathbf{Z} = [\mathbf{z}_1, \dots, \mathbf{z}_B]$, the mapping matrix between features and prototype vectors is defined as $\mathbf{Q} = [\mathbf{q}_1, \dots, \mathbf{q}_B] \in \mathbb{R}_+^{K\times B}$. We would like to maximize the similarity between the features and the prototypes:

$$
\begin{aligned}
\max_{\mathbf{Q}\in\mathcal{Q}} &\text{Tr}(\mathbf{Q}^\top \mathbf{C}^\top \mathbf{Z}) + \varepsilon \mathcal{H}(\mathbf{Q}) \\
\text{where }\mathcal{Q} &= \big\{ \mathbf{Q} \in \mathbb{R}_{+}^{K \times B} \mid \mathbf{Q}\mathbf{1}_B = \frac{1}{K}\mathbf{1}_K, \mathbf{Q}^\top\mathbf{1}_K = \frac{1}{B}\mathbf{1}_B \big\}
\end{aligned}
$$

其中 $\mathcal{H}$ 是熵，$\mathcal{H}(\mathbf{Q}) = - \sum_{ij} \mathbf{Q}_{ij} \log \mathbf{Q}_{ij}$，控制代码的平滑度。系数 $\epsilon$ 不应过大；否则，所有样本将被均匀分配到所有簇中。$\mathbf{Q}$ 的候选解集要求每个映射矩阵的每行和为 $1/K$，每列和为 $1/B$，从而确保每个原型平均至少被选择 $B/K$ 次。

> where $\mathcal{H}$ is the entropy, $\mathcal{H}(\mathbf{Q}) = - \sum_{ij} \mathbf{Q}_{ij} \log \mathbf{Q}_{ij}$, controlling the smoothness of the code. The coefficient $\epsilon$ should not be too large; otherwise, all the samples will be assigned uniformly to all the clusters. The candidate set of solutions for $\mathbf{Q}$ requires every mapping matrix to have each row sum up to $1/K$ and each column to sum up to $1/B$, enforcing that each prototype gets selected at least $B/K$ times on average.

SwAV 依赖于迭代的 Sinkhorn-Knopp 算法 ([Cuturi 2013](https://arxiv.org/abs/1306.0895)) 来寻找 $\mathbf{Q}$ 的解。

> SwAV relies on the iterative Sinkhorn-Knopp algorithm ([Cuturi 2013](https://arxiv.org/abs/1306.0895)) to find the solution for $\mathbf{Q}$.

#### 使用有监督数据集

> Working with Supervised Datasets

##### CLIP

> CLIP

**CLIP** (*对比语言-图像预训练*; [Radford 等人 2021](https://arxiv.org/abs/2103.00020)) 通过预训练任务联合训练一个文本编码器和一个图像特征提取器，该任务预测哪个标题与哪个图像匹配。

> **CLIP** (*Contrastive Language-Image Pre-training*; [Radford et al. 2021](https://arxiv.org/abs/2103.00020)) jointly trains a text encoder and an image feature extractor over the pretraining task that predicts which caption goes with which image.

![Illustration of CLIP contrastive pre-training over text-image pairs. (Image source: Radford et al. 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/CLIP.png)

给定一批 $N$ 个（图像，文本）对，CLIP 计算该批次中所有 $N\times N$ 个可能的（图像，文本）候选对之间的密集余弦相似度矩阵。文本和图像编码器联合训练，以最大化 $N$ 个正确（图像，文本）关联对之间的相似度，同时通过密集矩阵上的对称交叉熵损失最小化 $N(N-1)$ 个不正确对的相似度。

> Given a batch of $N$ (image, text) pairs, CLIP computes the dense cosine similarity matrix between all $N\times N$ possible (image, text) candidates within this batch. The text and image encoders are jointly trained to maximize the similarity between $N$ correct pairs of (image, text) associations while minimizing the similarity for $N(N-1)$ incorrect pairs via a symmetric cross entropy loss over the dense matrix.

请参阅 CLIP 的类似 NumPy 的伪代码

> See the numy-like pseudo code for CLIP in 

![CLIP algorithm in Numpy style pseudo code. (Image source: Radford et al. 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/CLIP-algo.png)

与上述其他学习良好视觉表示的方法相比，CLIP 真正特别之处在于 *“对使用自然语言作为训练信号的重视”*。它确实需要访问有监督数据集，其中我们知道哪个文本与哪个图像匹配。它在从互联网收集的 4 亿个（文本，图像）对上进行训练。查询列表包含在英文维基百科中出现至少 100 次的所有单词。有趣的是，他们发现基于 Transformer 的语言模型在零样本 ImageNet 分类中比词袋（BoW）文本编码器慢 3 倍。使用对比目标而不是尝试预测与图像相关的确切单词（即图像字幕预测任务中常用的方法）可以进一步将数据效率提高 4 倍。

> Compared to other methods above for learning good visual representation, what makes CLIP really special is *“the appreciation of using natural language as a training signal”*. It does demand access to supervised dataset in which we know which text matches which image. It is trained on 400 million (text, image) pairs, collected from the Internet. The query list contains all the words occurring at least 100 times in the English version of Wikipedia. Interestingly, they found that Transformer-based language models are 3x slower than a bag-of-words (BoW) text encoder at zero-shot ImageNet classification. Using contrastive objective instead of trying to predict the exact words associated with images (i.e. a method commonly adopted by image caption prediction tasks) can further improve the data efficiency another 4x.

![Using bag-of-words text encoding and contrastive training objectives can bring in multiple folds of data efficiency improvement. (Image source: Radford et al. 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/CLIP-efficiency.png)

CLIP 产生了良好的视觉表示，可以非平凡地迁移到许多计算机视觉基准数据集，达到与有监督基线相当的结果。在测试的迁移任务中，CLIP 在非常细粒度的分类以及抽象或系统性任务（例如计数对象数量）方面表现不佳。CLIP 模型的迁移性能与模型计算量平稳相关。

> CLIP produces good visual representation that can non-trivially transfer to many CV benchmark datasets, achieving results competitive with supervised baseline. Among tested transfer tasks, CLIP struggles with very fine-grained classification, as well as abstract or systematic tasks such as counting the number of objects. The transfer performance of CLIP models is smoothly correlated with the amount of model compute.

##### 有监督对比学习

> Supervised Contrastive Learning

交叉熵损失存在几个已知问题，例如对噪声标签缺乏鲁棒性以及可能存在较差的裕度。现有对交叉熵损失的改进包括更好的训练数据整理，例如标签平滑和数据增强。**有监督对比损失** ([Khosla 等人 2021](https://arxiv.org/abs/2004.11362)) 旨在比交叉熵更有效地利用标签信息，强制同一类别的归一化嵌入比不同类别的嵌入更接近。

> There are several known issues with cross entropy loss, such as the lack of robustness to noisy labels and the possibility of poor margins. Existing improvement for cross entropy loss involves the curation of better training data, such as label smoothing and data augmentation. **Supervised Contrastive Loss** ([Khosla et al. 2021](https://arxiv.org/abs/2004.11362)) aims to leverage label information more effectively than cross entropy, imposing that normalized embeddings from the same class are closer together than embeddings from different classes.

![Supervised vs self-supervised contrastive losses. Supervised contrastive learning considers different samples from the same class as positive examples, in addition to augmented versions. (Image source: Khosla et al. 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/sup-con.png)

给定一组随机采样的 $n$ 个（图像，标签）对，$\{\mathbf{x}_i, y_i\}_{i=1}^n$，可以通过对每个样本应用两次随机增强来创建 $2n$ 个训练对，$\{\tilde{\mathbf{x}}_i, \tilde{y}_i\}_{i=1}^{2n}$。

> Given a set of randomly sampled $n$ (image, label) pairs, $\{\mathbf{x}_i, y_i\}_{i=1}^n$, $2n$ training pairs can be created by applying two random augmentations of every sample, $\{\tilde{\mathbf{x}}_i, \tilde{y}_i\}_{i=1}^{2n}$.

有监督对比损失 $\mathcal{L}_\text{supcon}$ 利用多个正样本和负样本，与 [软近邻损失](https://lilianweng.github.io/posts/2021-05-31-contrastive/#soft-nearest-neighbors-loss) 非常相似：

> Supervised contrastive loss $\mathcal{L}_\text{supcon}$ utilizes multiple positive and negative samples, very similar to [soft nearest-neighbor loss](https://lilianweng.github.io/posts/2021-05-31-contrastive/#soft-nearest-neighbors-loss):

$$
\mathcal{L}_\text{supcon} = - \sum_{i=1}^{2n} \frac{1}{2 \vert N_i \vert - 1} \sum_{j \in N(y_i), j \neq i} \log \frac{\exp(\mathbf{z}_i \cdot \mathbf{z}_j / \tau)}{\sum_{k \in I, k \neq i}\exp({\mathbf{z}_i \cdot \mathbf{z}_k / \tau})}
$$

其中 $\mathbf{z}_k=P(E(\tilde{\mathbf{x}_k}))$，其中 $E(.)$ 是一个编码器网络（将增强图像映射到向量），$P(.)$ 是一个投影网络（将一个向量映射到另一个向量）。$N_i= \{j \in I: \tilde{y}_j = \tilde{y}_i \}$ 包含带有标签 $y_i$ 的样本索引集。将更多正样本包含到集合 $N_i$ 中会带来改进的结果。

> where $\mathbf{z}_k=P(E(\tilde{\mathbf{x}_k}))$, in which $E(.)$ is an encoder network (augmented image mapped to vector) $P(.)$ is a projection network (one vector mapped to another). $N_i= \{j \in I: \tilde{y}_j = \tilde{y}_i \}$ contains a set of indices of samples with label $y_i$. Including more positive samples into the set $N_i$ leads to improved results.

根据他们的实验，有监督对比损失：

> According to their experiments, supervised contrastive loss:

- 确实优于基础交叉熵，但优势不大。
- 在鲁棒性基准（ImageNet-C，它对 ImageNet 数据集应用了常见的自然扰动，如噪声、模糊和对比度变化）上优于交叉熵。
- 对超参数变化不那么敏感。

> • does outperform the base cross entropy, but only by a small amount.
> • outperforms the cross entropy on robustness benchmark (ImageNet-C, which applies common naturally occuring perturbations such as noise, blur and contrast changes to the ImageNet dataset).
> • is less sensitive to hyperparameter changes.

### 语言：句子嵌入

> Language: Sentence Embedding

在本节中，我们重点介绍如何学习句子嵌入。

> In this section, we focus on how to learn sentence embedding.

#### 文本增强

> Text Augmentation

视觉应用中的大多数对比方法都依赖于创建每个图像的增强版本。然而，构建不改变句子语义的文本增强更具挑战性。在本节中，我们将探讨三种文本序列增强方法，包括词汇编辑、回译以及应用截断或丢弃。

> Most contrastive methods in vision applications depend on creating an augmented version of each image. However, it is more challenging to construct text augmentation which does not alter the semantics of a sentence.  In this section we look into three approaches for augmenting text sequences, including lexical edits, back-translation and applying cutoff or dropout.

##### 词汇编辑

> Lexical Edits

**EDA** (*简易数据增强*; [Wei 和 Zou 2019](https://arxiv.org/abs/1901.11196)) 定义了一组简单但强大的文本增强操作。给定一个句子，EDA 随机选择并应用以下四种简单操作之一：

> **EDA** (*Easy Data Augmentation*; [Wei & Zou 2019](https://arxiv.org/abs/1901.11196)) defines a set of simple but powerful operations for text augmentation. Given a sentence, EDA randomly chooses and applies one of four simple operations:

1\. 同义词替换 (SR)：将 $n$ 个随机非停用词替换为其同义词。

2\. 随机插入 (RI)：将随机选择的非停用词的随机同义词插入句子中的随机位置。

3\. 随机交换 (RS)：随机交换两个词并重复 $n$ 次。

4\. 随机删除 (RD)：以概率 $p$ 随机删除句子中的每个词。

英文原文：

1\. Synonym replacement (SR): Replace $n$ random non-stop words with their synonyms.

2\. Random insertion (RI): Place a random synonym of a randomly selected non-stop word in the sentence at a random position.

3\. Random swap (RS): Randomly swap two words and repeat $n$ times.

4\. Random deletion (RD): Randomly delete each word in the sentence with probability $p$.

其中 $p=\alpha$ 和 $n=\alpha \times \text{sentence_length}$，其直觉是较长的句子可以吸收更多噪声，同时保持原始标签。超参数 $\alpha$ 大致表示一个句子中可能通过一次增强改变的词的百分比。

> where $p=\alpha$ and $n=\alpha \times \text{sentence_length}$, with the intuition that longer sentences can absorb more noise while maintaining the original label. The hyperparameter $\alpha$ roughly indicates the percent of words in one sentence that may be changed by one augmentation.

与没有 EDA 的基线相比，EDA 被证明可以提高多个分类基准数据集上的分类准确性。在较小的训练集上，性能提升更为显著。EDA 中的所有四种操作都有助于提高分类准确性，但在不同的 $\alpha$ 值下达到最佳。

> EDA is shown to improve the classification accuracy on several classification benchmark datasets compared to baseline without EDA. The performance lift is more significant on a smaller training set. All the four operations in EDA help improve the classification accuracy, but get to optimal at different $\alpha$’s.

![EDA leads to performance improvement on several classification benchmarks. (Image source: Wei & Zou 2019 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/EDA-exp1.png)

在 **上下文增强** ([Sosuke Kobayashi, 2018](https://arxiv.org/abs/1805.06201)) 中，词 `w_i` 在位置 `i` 的新替代词可以从给定的概率分布 $p(.\mid S\setminus\{w_i\})$ 中平滑采样，该分布由像 BERT 这样的双向语言模型预测。

英文原文：In Contextual Augmentation ([Sosuke Kobayashi, 2018](https://arxiv.org/abs/1805.06201)), new substitutes for word `w_i` at position `i` can be smoothly sampled from a given probability distribution, 

$p(.\mid S\setminus\{w_i\})$, which is predicted by a bidirectional LM like BERT.

##### 回译

> Back-translation

**CERT** (*基于 Transformer 的对比自监督编码器表示*; [Fang 等人 (2020)](https://arxiv.org/abs/2005.12766); [代码](https://github.com/UCSD-AI4H/CERT)) 通过 **回译** 生成增强句子。可以采用针对不同语言的各种翻译模型来创建不同版本的增强。一旦我们有了文本样本的噪声版本，上面介绍的许多对比学习框架，例如 [MoCo](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2)，都可以用于学习句子嵌入。

> **CERT** (*Contrastive self-supervised Encoder Representations from Transformers*; [Fang et al. (2020)](https://arxiv.org/abs/2005.12766); [code](https://github.com/UCSD-AI4H/CERT)) generates augmented sentences via **back-translation**. Various translation models for different languages can be employed for creating different versions of augmentations. Once we have a noise version of text samples, many contrastive learning frameworks introduced above, such as [MoCo](https://lilianweng.github.io/posts/2021-05-31-contrastive/#moco--moco-v2), can be used to learn sentence embedding.

##### Dropout 和 Cutoff

> Dropout and Cutoff

[Shen 等人 (2020)](https://arxiv.org/abs/2009.13818) 提出将 **Cutoff** 应用于文本增强，灵感来源于 [跨视图训练](https://lilianweng.github.io/posts/2019-01-31-lm/#cross-view-training)。他们提出了三种 Cutoff 增强策略：

> [Shen et al. (2020)](https://arxiv.org/abs/2009.13818) proposed to apply **Cutoff** to text augmentation, inspired by [cross-view training](https://lilianweng.github.io/posts/2019-01-31-lm/#cross-view-training). They proposed three cutoff augmentation strategies:

1. *Token Cutoff* 移除少量选定词元的信息。为确保没有数据泄露，输入、位置和其他相关嵌入矩阵中的相应词元都应归零。
2. *Feature Cutoff* 移除少量特征列。
3. *Span Cutoff* 移除连续的文本块。

> • *Token cutoff* removes the information of a few selected tokens. To make sure there is no data leakage, corresponding tokens in the input, positional and other relevant embedding matrices should all be zeroed out.,
> • *Feature cutoff* removes a few feature columns.
> • *Span cutoff* removes a continuous chunk of texts.

![Schematic illustration of token, feature and span cutoff augmentation strategies. (Image source: Shen et al. 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/text-cutoff.png)

可以创建同一样本的多个增强版本。在训练时，[Shen 等人 (2020)](https://arxiv.org/abs/2009.13818) 应用了一个额外的 KL 散度项来衡量来自不同增强样本的预测之间的一致性。

> Multiple augmented versions of one sample can be created. When training, [Shen et al. (2020)](https://arxiv.org/abs/2009.13818) applied an additional KL-divergence term to measure the consensus between predictions from different augmented samples.

**SimCSE** ([Gao 等人 2021](https://arxiv.org/abs/2104.08821); [代码](https://github.com/princeton-nlp/SimCSE)) 通过仅使用 **dropout** 噪声，从无监督数据中学习，通过自身预测句子。换句话说，他们将 dropout 视为文本序列的数据增强。一个样本被简单地两次输入编码器，使用不同的 dropout 掩码，这两个版本构成正样本对，而批次中的其他样本则被视为负样本对。这与 cutoff 增强非常相似，但 dropout 更灵活，对于可以掩盖哪些内容的语义含义定义不那么明确。

> **SimCSE** ([Gao et al. 2021](https://arxiv.org/abs/2104.08821); [code](https://github.com/princeton-nlp/SimCSE)) learns from unsupervised data by predicting a sentence from itself with only **dropout** noise. In other words, they treat dropout as data augmentation for text sequences. A sample is simply fed into the encoder twice with different dropout masks and these two versions are the positive pair where the other in-batch samples are considered as negative pairs. It feels quite similar to the cutoff augmentation, but dropout is more flexible with less well-defined semantic meaning of what content can be masked off.

![SimCSE creates augmented samples by applying different dropout masks. The supervised version leverages NLI datasets to predict positive (entailment) or negative (contradiction) given a pair of sentences. (Image source: Gao et al. 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/SimCSE.png)

他们在 7 个 STS（语义文本相似度）数据集上进行了实验，并计算了句子嵌入之间的余弦相似度。他们还尝试了一种可选的 MLM 辅助目标损失，以帮助避免标记级知识的灾难性遗忘。发现这种辅助损失有助于提高迁移任务的性能，但在主要的 STS 任务上却出现了持续下降。

> They ran experiments on 7 STS (Semantic Text Similarity) datasets and computed cosine similarity between sentence embeddings.  They also tried out an optional MLM auxiliary objective loss to help avoid catastrophic forgetting of token-level knowledge. This aux loss was found to help improve performance on transfer tasks, but a consistent drop on the main STS tasks.

![Experiment numbers on a collection of STS benchmarks with SimCES. (Image source: Gao et al. 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/SimCSE-STS-exp.png)

#### 来自 NLI 的监督

> Supervision from NLI

预训练的BERT句子嵌入在没有任何微调的情况下，在语义相似性任务中表现不佳。我们不能直接使用原始嵌入，而是需要通过进一步微调来优化嵌入。

> The pre-trained BERT sentence embedding without any fine-tuning has been found to have poor performance for semantic similarity tasks. Instead of using the raw embeddings directly, we need to refine the embedding with further fine-tuning.

**自然语言推理（NLI）**任务是为学习句子嵌入提供监督信号的主要数据源；例如[SNLI](https://nlp.stanford.edu/projects/snli/)、[MNLI](https://cims.nyu.edu/~sbowman/multinli/)和[QQP](https://www.kaggle.com/c/quora-question-pairs)。

> **Natural Language Inference (NLI)** tasks are the main data sources to provide supervised signals for learning sentence embedding; such as [SNLI](https://nlp.stanford.edu/projects/snli/), [MNLI](https://cims.nyu.edu/~sbowman/multinli/), and [QQP](https://www.kaggle.com/c/quora-question-pairs).

##### Sentence-BERT

> Sentence-BERT

**SBERT (Sentence-BERT)** ([Reimers & Gurevych, 2019](https://arxiv.org/abs/1908.10084)) 依赖于孪生网络和三元组网络架构来学习句子嵌入，从而可以通过嵌入对之间的余弦相似度来估计句子相似度。请注意，SBERT 的学习依赖于监督数据，因为它在多个NLI数据集上进行了微调。

> **SBERT (Sentence-BERT)** ([Reimers & Gurevych, 2019](https://arxiv.org/abs/1908.10084)) relies on siamese and triplet network architectures to learn sentence embeddings such that the sentence similarity can be estimated by cosine similarity between pairs of embeddings. Note that learning SBERT depends on supervised data, as it is fine-tuned on several NLI datasets.

他们在BERT模型之上实验了几种不同的预测头：

> They experimented with a few different prediction heads on top of BERT model:

• Softmax分类目标：孪生网络的分类头建立在两个嵌入$f(\mathbf{x}), f(\mathbf{x}’)$和$\vert f(\mathbf{x}) - f(\mathbf{x}’) \vert$的拼接之上。预测输出是$\hat{y}=\text{softmax}(\mathbf{W}_t [f(\mathbf{x}); f(\mathbf{x}’); \vert f(\mathbf{x}) - f(\mathbf{x}’) \vert])$。他们表明，最重要的组成部分是逐元素差值$\vert f(\mathbf{x}) - f(\mathbf{x}’) \vert$。

• 回归目标：这是$\cos(f(\mathbf{x}), f(\mathbf{x}’))$上的回归损失，其中池化策略影响很大。在实验中，他们观察到`max`的表现远不如`mean`和`CLS`-token。

• 三元组目标：$\max(0, |f(\mathbf{x}) - f(\mathbf{x}^+)|- |f(\mathbf{x}) - f(\mathbf{x}^-)| + \epsilon)$，其中$\mathbf{x}, \mathbf{x}^+, \mathbf{x}^-$是锚点句、正例句和负例句的嵌入。

英文原文：

• Softmax classification objective: The classification head of the siamese network is built on the concatenation of two embeddings $f(\mathbf{x}), f(\mathbf{x}’)$ and $\vert f(\mathbf{x}) - f(\mathbf{x}’) \vert$. The predicted output is $\hat{y}=\text{softmax}(\mathbf{W}_t [f(\mathbf{x}); f(\mathbf{x}’); \vert f(\mathbf{x}) - f(\mathbf{x}’) \vert])$. They showed that the most important component is the element-wise difference $\vert f(\mathbf{x}) - f(\mathbf{x}’) \vert$.

• Regression objective: This is the regression loss on $\cos(f(\mathbf{x}), f(\mathbf{x}’))$, in which the pooling strategy has a big impact. In the experiments, they observed that `max` performs much worse than `mean` and `CLS`-token.

• Triplet objective: $\max(0, |f(\mathbf{x}) - f(\mathbf{x}^+)|- |f(\mathbf{x}) - f(\mathbf{x}^-)| + \epsilon)$, where $\mathbf{x}, \mathbf{x}^+, \mathbf{x}^-$ are embeddings of the anchor, positive and negative sentences.

在实验中，哪种目标函数效果最好取决于数据集，因此没有普遍的赢家。

> In the experiments, which objective function works the best depends on the datasets, so there is no universal winner.

![Illustration of Sentence-BERT training framework with softmax classification head and regression head. (Image source: Reimers & Gurevych, 2019 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/SBERT.png)

[SentEval](https://github.com/facebookresearch/SentEval)库（[Conneau and Kiela, 2018](https://arxiv.org/abs/1803.05449)）常用于评估学习到的句子嵌入的质量。SBERT在当时（2019年8月）在7项任务中的5项上优于其他基线。

> The [SentEval](https://github.com/facebookresearch/SentEval) library ([Conneau and Kiela, 2018](https://arxiv.org/abs/1803.05449)) is commonly used for evaluating the quality of learned sentence embedding. SBERT outperformed other baselines at that time (Aug 2019) on 5 out of 7 tasks.

![The performance of Sentence-BERT on the SentEval benchmark. (Image source: Reimers & Gurevych, 2019 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/SBERT-SentEval.png)

##### BERT-flow

> BERT-flow

如果嵌入在每个维度上均匀分布，则嵌入表示空间被认为是*各向同性的*；否则，它是*各向异性的*。[Li et al, (2020)](https://arxiv.org/abs/2011.05864)表明，预训练的BERT学习了一个非平滑的*各向异性*句子嵌入语义空间，因此在没有微调的情况下，文本相似性任务表现不佳。根据经验，他们观察到BERT句子嵌入存在两个问题：
词频偏置了嵌入空间。高频词靠近原点，而低频词远离原点。
低频词稀疏分散。低频词的嵌入往往离它们的$k$ -NN邻居更远，而高频词的嵌入则更密集地集中。

> The embedding representation space is deemed *isotropic* if embeddings are uniformly distributed on each dimension; otherwise, it is *anisotropic*. [Li et al, (2020)](https://arxiv.org/abs/2011.05864) showed that a pre-trained BERT learns a non-smooth *anisotropic* semantic space of sentence embeddings and thus leads to poor performance for text similarity tasks without fine-tuning. Empirically, they observed two issues with BERT sentence embedding:
> Word frequency biases the embedding space. High-frequency words are close to the origin, but low-frequency ones are far away from the origin.
> Low-frequency words scatter sparsely. The embeddings of low-frequency words tend to be farther to their $k$ -NN neighbors, while the embeddings of high-frequency words concentrate more densely.

**BERT-flow** ([Li 等人，2020](https://arxiv.org/abs/2011.05864)；[代码](https://github.com/bohanli/BERT-flow)) 被提出用于通过[归一化流](https://lilianweng.github.io/posts/2018-10-13-flow-models/#what-is-normalizing-flows)将嵌入转换为平滑且各向同性的高斯分布。

> **BERT-flow** ([Li et al, 2020](https://arxiv.org/abs/2011.05864); [code](https://github.com/bohanli/BERT-flow)) was proposed to transform the embedding to a smooth and isotropic Gaussian distribution via [normalizing flows](https://lilianweng.github.io/posts/2018-10-13-flow-models/#what-is-normalizing-flows).

![Illustration of the flow-based calibration over the original sentence embedding space in BERT-flow. (Image source: Li et al, 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/BERT-flow.png)

令 $\mathcal{U}$ 为观测到的 BERT 句子嵌入空间，$\mathcal{Z}$ 为期望的潜在空间，它是一个标准高斯分布。因此，$p_\mathcal{Z}$ 是一个高斯密度函数，$f_\phi: \mathcal{Z}\to\mathcal{U}$ 是一个可逆变换：

> Let $\mathcal{U}$ be the observed BERT sentence embedding space and $\mathcal{Z}$ be the desired latent space which is a standard Gaussian. Thus, $p_\mathcal{Z}$ is a Gaussian density function and $f_\phi: \mathcal{Z}\to\mathcal{U}$ is an invertible transformation:

$$
\mathbf{z}\sim p_\mathcal{Z}(\mathbf{z}) \quad 
\mathbf{u}=f_\phi(\mathbf{z}) \quad
\mathbf{z}=f^{-1}_\phi(\mathbf{u})
$$

一个基于流的生成模型通过最大化 $\mathcal{U}$ 的边际似然来学习可逆映射函数：

> A flow-based generative model learns the invertible mapping function by maximizing the likelihood of $\mathcal{U}$’s marginal:

$$
\max_\phi\mathbb{E}_{\mathbf{u}=\text{BERT}(s), s\sim\mathcal{D}} \Big[ \log p_\mathcal{Z}(f^{-1}_\phi(\mathbf{u})) + \log\big\vert\det\frac{\partial f^{-1}_\phi(\mathbf{u})}{\partial\mathbf{u}}\big\vert \Big]
$$

其中 $s$ 是从文本语料库 $\mathcal{D}$ 中采样的一个句子。只有流参数 $\phi$ 被优化，而预训练 BERT 中的参数保持不变。

> where $s$ is a sentence sampled from the text corpus $\mathcal{D}$. Only the flow parameters $\phi$ are optimized while parameters in the pretrained BERT stay unchanged.

BERT-flow 被证明在大多数 STS 任务上都能提高性能，无论是否受到 NLI 数据集的监督。由于学习用于校准的归一化流不需要标签，因此它可以利用整个数据集，包括验证集和测试集。

> BERT-flow was shown to improve the performance on most STS tasks either with or without supervision from NLI datasets. Because learning normalizing flows for calibration does not require labels, it can utilize the entire dataset including validation and test sets.

##### 白化操作

> Whitening Operation

[Su et al. (2021)](https://arxiv.org/abs/2103.15316)应用了**白化**操作，以改善学习到的表示的[各向同性](https://lilianweng.github.io/posts/2021-05-31-contrastive/#isotropy)，并降低句子嵌入的维度。

> [Su et al. (2021)](https://arxiv.org/abs/2103.15316) applied **whitening** operation to improve the [isotropy](https://lilianweng.github.io/posts/2021-05-31-contrastive/#isotropy) of the learned representation and also to reduce the dimensionality of sentence embedding.

他们将句子向量的均值转换为0，并将协方差矩阵转换为单位矩阵。给定一组样本$\{\mathbf{x}_i\}_{i=1}^N$，令$\tilde{\mathbf{x}}_i$和$\tilde{\Sigma}$为转换后的样本和相应的协方差矩阵：

> They transform the mean value of the sentence vectors to 0 and the covariance matrix to the identity matrix. Given a set of samples $\{\mathbf{x}_i\}_{i=1}^N$, let $\tilde{\mathbf{x}}_i$ and $\tilde{\Sigma}$ be the transformed samples and corresponding covariance matrix:

$$
\begin{aligned}
\mu &= \frac{1}{N}\sum_{i=1}^N \mathbf{x}_i \quad \Sigma = \frac{1}{N}\sum_{i=1}^N (\mathbf{x}_i - \mu)^\top (\mathbf{x}_i - \mu) \\
\tilde{\mathbf{x}}_i &= (\mathbf{x}_i - \mu)W \quad \tilde{\Sigma} = W^\top\Sigma W = I \text{ thus } \Sigma = (W^{-1})^\top W^{-1}
\end{aligned}
$$

如果我们得到$\Sigma = U\Lambda U^\top$的[SVD](https://en.wikipedia.org/wiki/Singular_value_decomposition)分解，我们将得到$W^{-1}=\sqrt{\Lambda} U^\top$和$W=U\sqrt{\Lambda^{-1}}$。请注意，在SVD中，$U$是一个正交矩阵，其列向量是特征向量，而$\Lambda$是一个对角矩阵，其所有正元素都是排序后的特征值。

> If we get [SVD](https://en.wikipedia.org/wiki/Singular_value_decomposition) decomposition of $\Sigma = U\Lambda U^\top$, we will have $W^{-1}=\sqrt{\Lambda} U^\top$ and  $W=U\sqrt{\Lambda^{-1}}$. Note that within SVD, $U$ is an orthogonal matrix with column vectors as eigenvectors and $\Lambda$ is a diagonal matrix with all positive elements as sorted eigenvalues.

可以通过仅取前$k$列$W$，命名为`Whitening`-$k$。

> A dimensionality reduction strategy can be applied by only taking the first $k$ columns of $W$, named `Whitening`-$k$.

![Pseudo code of the whitening-$k$ operation. (Image source: Su et al. 2021 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/whitening-SBERT.png)

白化操作被证明在许多 STS 基准测试中优于 BERT-flow，并在句子维度为 256 的情况下实现了 SOTA，无论是否使用 NLI 监督。

> Whitening operations were shown to outperform BERT-flow and achieve SOTA with 256 sentence dimensionality on many STS benchmarks, either with or without NLI supervision.

#### 无监督语句嵌入学习

> Unsupervised Sentence Embedding Learning

##### 上下文预测

> Context Prediction

**Quick-Thought (QT) 向量** ([Logeswaran & Lee, 2018](https://arxiv.org/abs/1803.02893)) 将句子表示学习表述为一个 *分类* 问题：给定一个句子及其上下文，分类器根据它们的向量表示来区分上下文句子和其他对比句子 ([“完形填空测试”](https://lilianweng.github.io/posts/2019-01-31-lm/#MLM))。这种表述方式移除了导致训练速度减慢的 softmax 输出层。

> **Quick-Thought (QT) vectors** ([Logeswaran & Lee, 2018](https://arxiv.org/abs/1803.02893)) formulate sentence representation learning as a *classification* problem: Given a sentence and its context, a classifier distinguishes context sentences from other contrastive sentences based on their vector representations ([“cloze test”](https://lilianweng.github.io/posts/2019-01-31-lm/#MLM)). Such a formulation removes the softmax output layer which causes training slowdown.

![Illustration of how Quick-Thought sentence embedding vectors are learned. (Image source: Logeswaran & Lee, 2018 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/quick-thought.png)

设 $f(.)$ 和 $g(.)$ 是将句子 $s$ 编码为固定长度向量的两个函数。设 $C(s)$ 是 $s$ 上下文中的句子集合，$S(s)$ 是候选句子集合，其中只包含一个句子 $s_c \in C(s)$ 和许多其他非上下文的负样本句子。Quick Thoughts 模型学习优化预测唯一真实上下文句子 $s_c \in S(s)$ 的概率。当将句子 $(s, s_c)$ 视为正样本对，而将其他对 $(s, s’)$（其中 $s’ \in S(s), s’\neq s_c$）视为负样本时，这本质上是 NCE 损失。

> Let $f(.)$ and $g(.)$ be two functions that encode a sentence $s$ into a fixed-length vector. Let $C(s)$ be the set of sentences in the context of $s$ and $S(s)$ be the set of candidate sentences including only one sentence $s_c \in C(s)$ and many other non-context negative sentences. Quick Thoughts model learns to optimize the probability of predicting the only true context sentence $s_c \in S(s)$. It is essentially NCE loss when considering the sentence $(s, s_c)$ as the positive pairs while other pairs $(s, s’)$ where $s’ \in S(s), s’\neq s_c$ as negatives.

$$
\mathcal{L}_\text{QT} 
= - \sum_{s \in \mathcal{D}} \sum_{s_c \in C(s)} \log p(s_c \vert s, S(s)) 
= - \sum_{s \in \mathcal{D}} \sum_{s_c \in C(s)}\frac{\exp(f(s)^\top g(s_c))}{\sum_{s'\in S(s)} \exp(f(s)^\top g(s'))}
$$

##### 互信息最大化

> Mutual Information Maximization

**IS-BERT (信息-句子 BERT)** ([Zhang et al. 2020](https://arxiv.org/abs/2009.12061); [代码](https://github.com/yanzhangnlp/IS-BERT)) 采用基于 *互信息最大化* 的自监督学习目标，以 *无监督* 方式学习良好的句子嵌入。

> **IS-BERT (Info-Sentence BERT)** ([Zhang et al. 2020](https://arxiv.org/abs/2009.12061); [code](https://github.com/yanzhangnlp/IS-BERT)) adopts a self-supervised learning objective based on *mutual information maximization* to learn good sentence embeddings in the *unsupervised* manners.

![Illustration of Info-Sentence BERT. (Image source: Zhang et al. 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/IS-BERT.png)

IS-BERT 的工作方式如下：

> IS-BERT works as follows:

1\. 使用 BERT 将输入句子 $s$ 编码为长度为 $l$ 的词元嵌入 $\mathbf{h}_{1:l}$。

2\. 然后应用具有不同核大小（例如 1、3、5）的一维卷积网络来处理词元嵌入序列，以捕获 n-gram 局部上下文依赖性：$\mathbf{c}_i = \text{ReLU}(\mathbf{w} \cdot \mathbf{h}_{i:i+k-1} + \mathbf{b})$。输出序列经过填充以保持与输入相同的大小。

3\. 第 $i$ 个词元 $\mathcal{F}_\theta^{(i)} (\mathbf{x})$ 的最终局部表示是不同核大小表示的拼接。

4\. 全局句子表示 $\mathcal{E}_\theta(\mathbf{x})$ 是通过对词元表示 $\mathcal{F}_\theta(\mathbf{x}) = \{\mathcal{F}_\theta^{(i)} (\mathbf{x}) \in \mathbb{R}^d\}_{i=1}^l$ 应用时间平均池化层计算得出的。

英文原文：

1\. 
Use BERT to encode an input sentence $s$ to a token embedding of length $l$, $\mathbf{h}_{1:l}$.


2\. 
Then apply 1-D conv net with different kernel sizes (e.g. 1, 3, 5) to process the token embedding sequence to capture the n-gram local contextual dependencies: $\mathbf{c}_i = \text{ReLU}(\mathbf{w} \cdot \mathbf{h}_{i:i+k-1} + \mathbf{b})$. The output sequences are padded to stay the same sizes of the inputs.


3\. 
The final local representation of the $i$ -th token $\mathcal{F}_\theta^{(i)} (\mathbf{x})$ is the concatenation of representations of different kernel sizes.


4\. 
The global sentence representation $\mathcal{E}_\theta(\mathbf{x})$ is computed by applying a mean-over-time pooling layer on the token representations $\mathcal{F}_\theta(\mathbf{x}) = \{\mathcal{F}_\theta^{(i)} (\mathbf{x}) \in \mathbb{R}^d\}_{i=1}^l$.


由于互信息估计对于连续高维随机变量通常是难以处理的，IS-BERT 依赖于 Jensen-Shannon 估计器 ([Nowozin et al., 2016](https://arxiv.org/abs/1606.00709), [Hjelm et al., 2019](https://arxiv.org/abs/1808.06670)) 来最大化 $\mathcal{E}_\theta(\mathbf{x})$ 和 $\mathcal{F}_\theta^{(i)} (\mathbf{x})$ 之间的互信息。

> Since the mutual information estimation is generally intractable for continuous and high-dimensional random variables, IS-BERT relies on the Jensen-Shannon estimator ([Nowozin et al., 2016](https://arxiv.org/abs/1606.00709), [Hjelm et al., 2019](https://arxiv.org/abs/1808.06670)) to maximize the mutual information between $\mathcal{E}_\theta(\mathbf{x})$ and $\mathcal{F}_\theta^{(i)} (\mathbf{x})$.

$$
I^\text{JSD}_\omega(\mathcal{F}_\theta^{(i)} (\mathbf{x}); \mathcal{E}_\theta(\mathbf{x})) = \mathbb{E}_{\mathbf{x}\sim P} [-\text{sp}(-T_\omega(\mathcal{F}_\theta^{(i)} (\mathbf{x}); \mathcal{E}_\theta(\mathbf{x})))] \\ - \mathbb{E}_{\mathbf{x}\sim P, \mathbf{x}' \sim\tilde{P}} [\text{sp}(T_\omega(\mathcal{F}_\theta^{(i)} (\mathbf{x}'); \mathcal{E}_\theta(\mathbf{x})))]
$$

其中 $T_\omega: \mathcal{F}\times\mathcal{E} \to \mathbb{R}$ 是一个带有参数 $\omega$ 的可学习网络，用于生成判别器分数。负样本 $\mathbf{x}’$ 从分布 $\tilde{P}=P$ 中采样。而 $\text{sp}(x)=\log(1+e^x)$ 是 softplus 激活函数。

> where $T_\omega: \mathcal{F}\times\mathcal{E} \to \mathbb{R}$ is a learnable network with parameters $\omega$, generating discriminator scores. The negative sample $\mathbf{x}’$ is sampled from the distribution $\tilde{P}=P$. And $\text{sp}(x)=\log(1+e^x)$ is the softplus activation function.

IS-BERT 在 SentEval 上的无监督结果优于大多数无监督基线（2020 年 9 月），但不出所料地弱于有监督运行。当使用带标签的 NLI 数据集时，IS-BERT 产生的结果与 SBERT 相当（参见图 25 和 30）。

> The unsupervised numbers on SentEval with IS-BERT outperforms most of the unsupervised baselines (Sep 2020), but unsurprisingly weaker than supervised runs. When using labelled NLI datasets, IS-BERT produces results comparable with SBERT (See Fig. 25 & 30).

![The performance of IS-BERT on the SentEval benchmark. (Image source: Zhang et al. 2020 )](https://lilianweng.github.io/posts/2021-05-31-contrastive/IS-BERT-SentEval.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2021 年 5 月). 对比表示学习. Lil’Log. https://lilianweng.github.io/posts/2021-05-31-contrastive/.

> Weng, Lilian. (May 2021). Contrastive representation learning. Lil’Log. https://lilianweng.github.io/posts/2021-05-31-contrastive/.

或

> Or

```
@article{weng2021contrastive,
  title   = "Contrastive Representation Learning",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2021",
  month   = "May",
  url     = "https://lilianweng.github.io/posts/2021-05-31-contrastive/"
}
```

### 参考文献

> References

[1] Sumit Chopra, Raia Hadsell 和 Yann LeCun. [“判别式学习相似性度量，及其在人脸验证中的应用。”](http://yann.lecun.com/exdb/publis/pdf/chopra-05.pdf) CVPR 2005.

> [1] Sumit Chopra, Raia Hadsell and Yann LeCun. [“Learning a similarity metric discriminatively, with application to face verification.”](http://yann.lecun.com/exdb/publis/pdf/chopra-05.pdf) CVPR 2005.

[2] Florian Schroff, Dmitry Kalenichenko 和 James Philbin. [“FaceNet: 用于人脸识别和聚类的统一嵌入。”](https://arxiv.org/abs/1503.03832) CVPR 2015.

> [2] Florian Schroff, Dmitry Kalenichenko and James Philbin. [“FaceNet: A Unified Embedding for Face Recognition and Clustering.”](https://arxiv.org/abs/1503.03832) CVPR 2015.

[3] Hyun Oh Song 等人. [“通过提升结构化特征嵌入的深度度量学习。”](https://arxiv.org/abs/1511.06452) CVPR 2016. [[代码](https://github.com/rksltnl/Deep-Metric-Learning-CVPR16)]

> [3] Hyun Oh Song et al. [“Deep Metric Learning via Lifted Structured Feature Embedding.”](https://arxiv.org/abs/1511.06452) CVPR 2016. [[code](https://github.com/rksltnl/Deep-Metric-Learning-CVPR16)]

[4] Ruslan Salakhutdinov 和 Geoff Hinton. [“通过保留类别邻域结构学习非线性嵌入”](http://proceedings.mlr.press/v2/salakhutdinov07a.html) AISTATS 2007.

> [4] Ruslan Salakhutdinov and Geoff Hinton. [“Learning a Nonlinear Embedding by Preserving Class Neighbourhood Structure”](http://proceedings.mlr.press/v2/salakhutdinov07a.html) AISTATS 2007.

[5] Michael Gutmann 和 Aapo Hyvärinen. [“噪声对比估计：一种用于非归一化统计模型的新估计原理。”](http://proceedings.mlr.press/v9/gutmann10a.html) AISTATS 2010.

> [5] Michael Gutmann and Aapo Hyvärinen. [“Noise-contrastive estimation: A new estimation principle for unnormalized statistical models.”](http://proceedings.mlr.press/v9/gutmann10a.html) AISTATS 2010.

[6] Kihyuk Sohn 等人. [“使用多类别 N-pair 损失目标改进深度度量学习”](https://papers.nips.cc/paper/2016/hash/6b180037abbebea991d8b1232f8a8ca9-Abstract.html) NIPS 2016.

> [6] Kihyuk Sohn et al. [“Improved Deep Metric Learning with Multi-class N-pair Loss Objective”](https://papers.nips.cc/paper/2016/hash/6b180037abbebea991d8b1232f8a8ca9-Abstract.html) NIPS 2016.

[7] Nicholas Frosst, Nicolas Papernot 和 Geoffrey Hinton. [“使用软最近邻损失分析和改进表示。”](http://proceedings.mlr.press/v97/frosst19a.html) ICML 2019

> [7] Nicholas Frosst, Nicolas Papernot and Geoffrey Hinton. [“Analyzing and Improving Representations with the Soft Nearest Neighbor Loss.”](http://proceedings.mlr.press/v97/frosst19a.html) ICML 2019

[8] Tongzhou Wang 和 Phillip Isola. [“通过超球面上的对齐和均匀性理解对比表示学习。”](https://arxiv.org/abs/2005.10242) ICML 2020. [[代码](https://ssnl.github.io/hypersphere/)]

> [8] Tongzhou Wang and Phillip Isola. [“Understanding Contrastive Representation Learning through Alignment and Uniformity on the Hypersphere.”](https://arxiv.org/abs/2005.10242) ICML 2020. [[code](https://ssnl.github.io/hypersphere/)]

[9] Zhirong Wu et al. [“通过非参数实例级判别进行无监督特征学习。”](https://arxiv.org/abs/1805.01978) CVPR 2018.

> [9] Zhirong Wu et al. [“Unsupervised feature learning via non-parametric instance-level discrimination.”](https://arxiv.org/abs/1805.01978) CVPR 2018.

[10] Ekin D. Cubuk et al. [“AutoAugment：从数据中学习增强策略。”](https://arxiv.org/abs/1805.09501) arXiv preprint arXiv:1805.09501 (2018).

> [10] Ekin D. Cubuk et al. [“AutoAugment: Learning augmentation policies from data.”](https://arxiv.org/abs/1805.09501) arXiv preprint arXiv:1805.09501 (2018).

[11] Daniel Ho et al. [“基于群体的增强：高效学习增强策略调度。”](https://arxiv.org/abs/1905.05393) ICML 2019.

> [11] Daniel Ho et al. [“Population Based Augmentation: Efficient Learning of Augmentation Policy Schedules.”](https://arxiv.org/abs/1905.05393) ICML 2019.

[12] Ekin D. Cubuk & Barret Zoph et al. [“RandAugment：具有缩小搜索空间的实用自动化数据增强。”](https://arxiv.org/abs/1909.13719) arXiv preprint arXiv:1909.13719 (2019).

> [12] Ekin D. Cubuk & Barret Zoph et al. [“RandAugment: Practical automated data augmentation with a reduced search space.”](https://arxiv.org/abs/1909.13719) arXiv preprint arXiv:1909.13719 (2019).

[13] Hongyi Zhang et al. [“mixup：超越经验风险最小化。”](https://arxiv.org/abs/1710.09412) ICLR 2017.

> [13] Hongyi Zhang et al. [“mixup: Beyond Empirical Risk Minimization.”](https://arxiv.org/abs/1710.09412) ICLR 2017.

[14] Sangdoo Yun et al. [“CutMix：训练具有可定位特征的强分类器的正则化策略。”](https://arxiv.org/abs/1905.04899) ICCV 2019.

> [14] Sangdoo Yun et al. [“CutMix: Regularization Strategy to Train Strong Classifiers with Localizable Features.”](https://arxiv.org/abs/1905.04899) ICCV 2019.

[15] Yannis Kalantidis et al. [“对比硬负样本的混合”](https://arxiv.org/abs/2010.01028) NeuriPS 2020.

> [15] Yannis Kalantidis et al. [“Mixing of Contrastive Hard Negatives”](https://arxiv.org/abs/2010.01028) NeuriPS 2020.

[16] Ashish Jaiswal et al. [“对比自监督学习综述。”](https://arxiv.org/abs/2011.00362) arXiv preprint arXiv:2011.00362 (2021)

> [16] Ashish Jaiswal et al. [“A Survey on Contrastive Self-Supervised Learning.”](https://arxiv.org/abs/2011.00362) arXiv preprint arXiv:2011.00362 (2021)

[17] Jure Zbontar et al. [“Barlow Twins：通过冗余减少进行自监督学习。”](https://arxiv.org/abs/2103.03230) arXiv preprint arXiv:2103.03230 (2021) [[代码](https://github.com/facebookresearch/barlowtwins)]

> [17] Jure Zbontar et al. [“Barlow Twins: Self-Supervised Learning via Redundancy Reduction.”](https://arxiv.org/abs/2103.03230) arXiv preprint arXiv:2103.03230 (2021) [[code](https://github.com/facebookresearch/barlowtwins)]

[18] Alec Radford, et al. [“从自然语言监督中学习可迁移视觉模型”](https://arxiv.org/abs/2103.00020) arXiv preprint arXiv:2103.00020 (2021)

> [18] Alec Radford, et al. [“Learning Transferable Visual Models From Natural Language Supervision”](https://arxiv.org/abs/2103.00020) arXiv preprint arXiv:2103.00020 (2021)

[19] Mathilde Caron et al. [“通过对比聚类分配进行视觉特征的无监督学习 (SwAV)。”](https://arxiv.org/abs/2006.09882) NeuriPS 2020.

> [19] Mathilde Caron et al. [“Unsupervised Learning of Visual Features by Contrasting Cluster Assignments (SwAV).”](https://arxiv.org/abs/2006.09882) NeuriPS 2020.

[20] Mathilde Caron et al. [“用于视觉特征无监督学习的深度聚类。”](https://arxiv.org/abs/1807.05520) ECCV 2018.

> [20] Mathilde Caron et al. [“Deep Clustering for Unsupervised Learning of Visual Features.”](https://arxiv.org/abs/1807.05520) ECCV 2018.

[21] Prannay Khosla et al. [“监督对比学习。”](https://arxiv.org/abs/2004.11362) NeurIPS 2020.

> [21] Prannay Khosla et al. [“Supervised Contrastive Learning.”](https://arxiv.org/abs/2004.11362) NeurIPS 2020.

[22] Aaron van den Oord, Yazhe Li & Oriol Vinyals. [“使用对比预测编码进行表示学习”](https://arxiv.org/abs/1807.03748) arXiv preprint arXiv:1807.03748 (2018).

> [22] Aaron van den Oord, Yazhe Li & Oriol Vinyals. [“Representation Learning with Contrastive Predictive Coding”](https://arxiv.org/abs/1807.03748) arXiv preprint arXiv:1807.03748 (2018).

[23] Jason Wei and Kai Zou. [“EDA：用于提升文本分类任务性能的简易数据增强技术。”](https://arxiv.org/abs/1901.11196) EMNLP-IJCNLP 2019.

> [23] Jason Wei and Kai Zou. [“EDA: Easy data augmentation techniques for boosting performance on text classification tasks.”](https://arxiv.org/abs/1901.11196)  EMNLP-IJCNLP 2019.

[24] Sosuke Kobayashi. [“上下文增强：通过具有范式关系的词进行数据增强。”](https://arxiv.org/abs/1805.06201) NAACL 2018

> [24] Sosuke Kobayashi. [“Contextual Augmentation: Data Augmentation by Words with Paradigmatic Relations.”](https://arxiv.org/abs/1805.06201) NAACL 2018

[25] Hongchao Fang et al. [“CERT：用于语言理解的对比自监督学习。”](https://arxiv.org/abs/2005.12766) arXiv preprint arXiv:2005.12766 (2020).

> [25] Hongchao Fang et al. [“CERT: Contrastive self-supervised learning for language understanding.”](https://arxiv.org/abs/2005.12766) arXiv preprint arXiv:2005.12766 (2020).

[26] Dinghan Shen et al. [“一种简单但难以超越的自然语言理解和生成数据增强方法。”](https://arxiv.org/abs/2009.13818) arXiv preprint arXiv:2009.13818 (2020) [[代码](https://github.com/dinghanshen/cutoff)]

> [26] Dinghan Shen et al. [“A Simple but Tough-to-Beat Data Augmentation Approach for Natural Language Understanding and Generation.”](https://arxiv.org/abs/2009.13818) arXiv preprint arXiv:2009.13818 (2020) [[code](https://github.com/dinghanshen/cutoff)]

[27] Tianyu Gao et al. [“SimCSE：简单的句子嵌入对比学习。”](https://arxiv.org/abs/2104.08821) arXiv preprint arXiv:2104.08821 (2020). [[代码](https://github.com/princeton-nlp/SimCSE)]

> [27] Tianyu Gao et al. [“SimCSE: Simple Contrastive Learning of Sentence Embeddings.”](https://arxiv.org/abs/2104.08821) arXiv preprint arXiv:2104.08821 (2020). [[code](https://github.com/princeton-nlp/SimCSE)]

[28] Nils Reimers and Iryna Gurevych. [“Sentence-BERT：使用 Siamese BERT 网络进行句子嵌入。”](https://arxiv.org/abs/1908.10084) EMNLP 2019.

> [28] Nils Reimers and Iryna Gurevych. [“Sentence-BERT: Sentence embeddings using Siamese BERT-networks.”](https://arxiv.org/abs/1908.10084) EMNLP 2019.

[29] Jianlin Su et al. [“白化句子表示以获得更好的语义和更快的检索。”](https://arxiv.org/abs/2103.15316) arXiv preprint arXiv:2103.15316 (2021). [[代码](https://github.com/bojone/BERT-whitening)]

> [29] Jianlin Su et al. [“Whitening sentence representations for better semantics and faster retrieval.”](https://arxiv.org/abs/2103.15316) arXiv preprint arXiv:2103.15316 (2021). [[code](https://github.com/bojone/BERT-whitening)]

[30] Yan Zhang et al. [“一种通过互信息最大化的无监督句子嵌入方法。”](https://arxiv.org/abs/2009.12061) EMNLP 2020. [[代码](https://github.com/yanzhangnlp/IS-BERT)]

> [30] Yan Zhang et al. [“An unsupervised sentence embedding method by mutual information maximization.”](https://arxiv.org/abs/2009.12061) EMNLP 2020. [[code](https://github.com/yanzhangnlp/IS-BERT)]

[31] Bohan Li et al. [“关于预训练语言模型的句子嵌入。”](https://arxiv.org/abs/2011.05864) EMNLP 2020.

> [31] Bohan Li et al. [“On the sentence embeddings from pre-trained language models.”](https://arxiv.org/abs/2011.05864) EMNLP 2020.

[32] Lajanugen Logeswaran and Honglak Lee. [“一种学习句子表示的有效框架。”](https://arxiv.org/abs/1803.02893) ICLR 2018.

> [32] Lajanugen Logeswaran and Honglak Lee. [“An efficient framework for learning sentence representations.”](https://arxiv.org/abs/1803.02893) ICLR 2018.

[33] Joshua Robinson, et al. [“使用硬负样本的对比学习。”](https://arxiv.org/abs/2010.04592) ICLR 2021.

> [33] Joshua Robinson, et al. [“Contrastive Learning with Hard Negative Samples.”](https://arxiv.org/abs/2010.04592) ICLR 2021.

[34] Ching-Yao Chuang et al. [“去偏对比学习。”](https://arxiv.org/abs/2007.00224) NeuriPS 2020.

> [34] Ching-Yao Chuang et al. [“Debiased Contrastive Learning.”](https://arxiv.org/abs/2007.00224) NeuriPS 2020.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Contrastive Representation Learning | 对比表示学习 | 一种机器学习范式，旨在学习一个嵌入空间，使相似样本彼此靠近，不相似样本彼此远离。 |
| Embedding Space | 嵌入空间 | 将高维数据映射到低维向量表示的空间，其中语义相似性通过距离或相似度衡量。 |
| Self-supervised Learning | 自监督学习 | 一种无监督学习方法，通过从数据本身生成监督信号来训练模型，无需人工标注。 |
| Contrastive Loss | 对比损失 | 一种损失函数，用于最小化同类样本嵌入之间的距离，同时最大化不同类样本嵌入之间的距离。 |
| Triplet Loss | 三元组损失 | 一种损失函数，通过锚点、正样本和负样本三元组，最小化锚点与正样本距离，最大化锚点与负样本距离。 |
| Hard Negative Mining | 难负样本挖掘 | 在训练过程中识别那些与锚点样本相似但标签不同的负样本，以提高模型区分能力的技术。 |
| InfoNCE Loss | InfoNCE损失 | 一种基于分类交叉熵的对比损失，用于从一组噪声样本中识别出正样本，与互信息最大化相关。 |
| Data Augmentation | 数据增强 | 通过对现有数据应用变换（如裁剪、颜色失真）来创建新训练样本的技术，以增加数据多样性并提高模型泛化能力。 |
| Batch Normalization | 批归一化 | 一种神经网络层，通过归一化每个批次输入的均值和方差来加速训练并提高模型稳定性。 |
| Momentum Encoder | 动量编码器 | 在对比学习中，用于生成负样本键表示的编码器，其权重通过动量更新机制从查询编码器缓慢复制。 |
| Polyak Averaging | Polyak平均 | 一种模型参数更新策略，通过对历史参数进行指数移动平均来平滑模型权重，常用于目标网络。 |
| Anisotropic | 各向异性 | 描述嵌入空间中向量分布不均匀的特性，可能导致语义相似度衡量不准确。 |
| Normalizing Flows | 归一化流 | 一类生成模型，通过一系列可逆变换将简单分布（如高斯分布）映射到复杂数据分布。 |
| Whitening Operation | 白化操作 | 一种数据预处理技术，将数据转换为均值为零、协方差矩阵为单位矩阵的形式，以改善表示的各向同性。 |
| Mutual Information Maximization | 互信息最大化 | 一种自监督学习目标，旨在最大化不同视图或表示之间共享的信息量。 |
