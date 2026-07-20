# 元学习：学会快速学习

> Meta-Learning: Learning to Learn Fast

> 来源：Lil'Log / Lilian Weng，2018-11-30
> 原文链接：https://lilianweng.github.io/posts/2018-11-30-meta-learning/
> 分类：机器学习 / 元学习

## 核心要点

- 元学习旨在使机器学习模型能够像人类一样，通过少量样本快速学习新概念和技能。
- 元学习模型应能很好地适应或泛化到训练期间未曾遇到的新任务和新环境，因此也被称为“学会学习”。
- 元学习的训练过程通过采样标签子集和支持集来模拟推理过程，以鼓励模型快速学习和泛化。
- 元学习主要有基于度量、基于模型和基于优化三种常见方法，每种方法都有其独特的模型架构和学习机制。
- 基于度量的元学习通过学习高效的嵌入和相似性度量来识别新类别，代表模型包括孪生网络、匹配网络和原型网络。
- 基于模型的元学习利用记忆增强神经网络或快权重机制，使模型能够快速整合新信息并实现跨任务泛化。
- 基于优化的元学习通过调整优化算法本身，如LSTM元学习器、MAML和Reptile，使模型能够通过少量梯度下降步骤快速适应新任务。
- MAML（模型无关元学习）是一种通用优化算法，通过元优化找到一个初始参数，使其能通过少量梯度下降步骤快速适应新任务。
- Reptile是一种与MAML相似的元学习优化算法，通过重复任务训练和权重更新，旨在优化更好的任务性能和泛化能力。

## 正文

[2019-10-01 更新：感谢 Tianhao，本文已翻译成[中文](https://wei-tianhao.github.io/blog/2019/09/17/meta-learning.html)！]

> [Updated on 2019-10-01: thanks to Tianhao, we have this post translated in [Chinese](https://wei-tianhao.github.io/blog/2019/09/17/meta-learning.html)!]

一个好的机器学习模型通常需要大量样本进行训练。相比之下，人类学习新概念和技能的速度和效率要快得多。只见过几次猫和鸟的孩子就能很快将它们区分开来。会骑自行车的人很可能在很少甚至没有演示的情况下，快速学会骑摩托车。是否有可能设计出一种具有类似特性的机器学习模型——用少量训练样本快速学习新概念和技能？这正是**元学习**旨在解决的问题。

> A good machine learning model often requires training with a large number of samples. Humans, in contrast, learn new concepts and skills much faster and more efficiently. Kids who have seen cats and birds only a few times can quickly tell them apart. People who know how to ride a bike are likely to discover the way to ride a motorcycle fast with little or even no demonstration. Is it possible to design a machine learning model with similar properties — learning new concepts and skills fast with a few training examples? That’s essentially what **meta-learning** aims to solve.

我们期望一个好的元学习模型能够很好地适应或泛化到训练期间从未遇到过的新任务和新环境。适应过程本质上是一个迷你学习会话，它发生在测试期间，但对新任务配置的接触有限。最终，适应后的模型可以完成新任务。这就是元学习也被称为[学会学习](https://www.cs.cmu.edu/~rsalakhu/papers/LakeEtAl2015Science.pdf)的原因。

> We expect a good meta-learning model capable of well adapting or generalizing to new tasks and new environments that have never been encountered during training time. The adaptation process, essentially a mini learning session, happens during test but with a limited exposure to the new task configurations. Eventually, the adapted model can complete new tasks. This is why meta-learning is also known as [learning to learn](https://www.cs.cmu.edu/~rsalakhu/papers/LakeEtAl2015Science.pdf).

这些任务可以是任何定义明确的机器学习问题族：监督学习、强化学习等。例如，以下是一些具体的元学习任务：

> The tasks can be any well-defined family of machine learning problems: supervised learning, reinforcement learning, etc. For example, here are a couple concrete meta-learning tasks:

- 一个在非猫图像上训练的分类器，在看过少量猫图片后，能够判断给定图像是否包含猫。
- 一个游戏机器人能够快速掌握一款新游戏。
- 一个小型机器人在测试期间能在上坡表面完成预期任务，即使它只在平坦表面环境中接受过训练。

> • A classifier trained on non-cat images can tell whether a given image contains a cat after seeing a handful of cat pictures.
> • A game bot is able to quickly master a new game.
> • A mini robot completes the desired task on an uphill surface during test even through it was only trained in a flat surface environment.

### 定义元学习问题

> Define the Meta-Learning Problem

在这篇文章中，我们重点关注每个预期任务都是监督学习问题（如图像分类）的情况。关于强化学习问题中的元学习（又称“元强化学习”）有很多有趣的文献，但我们在此不予讨论。

> In this post, we focus on the case when each desired task is a supervised learning problem like image classification. There is a lot of interesting literature on meta-learning with reinforcement learning problems (aka “Meta Reinforcement Learning”), but we would not cover them here.

#### 一个简单的视角

> A Simple View

一个好的元学习模型应该在各种学习任务上进行训练，并针对任务分布（包括潜在的未见任务）的最佳性能进行优化。每个任务都与一个数据集$\mathcal{D}$相关联，其中包含特征向量和真实标签。最优模型参数为：

> A good meta-learning model should be trained over a variety of learning tasks and optimized for the best performance on a distribution of tasks, including potentially unseen tasks. Each task is associated with a dataset $\mathcal{D}$, containing both feature vectors and true labels. The optimal model parameters are:

$$
\theta^* = \arg\min_\theta \mathbb{E}_{\mathcal{D}\sim p(\mathcal{D})} [\mathcal{L}_\theta(\mathcal{D})]
$$

这看起来与普通的学习任务非常相似，但*一个数据集*被视为*一个数据样本*。

> It looks very similar to a normal learning task, but *one dataset* is considered as *one data sample*.

*少样本分类*是监督学习领域中元学习的一个实例。数据集$\mathcal{D}$通常分为两部分：用于学习的支持集$S$和用于训练或测试的预测集$B$$\mathcal{D}=\langle S, B\rangle$。我们通常考虑一个*K-shot N-class 分类*任务：支持集包含N个类别中每个类别的K个带标签样本。

> *Few-shot classification* is an instantiation of meta-learning in the field of supervised learning. The dataset $\mathcal{D}$ is often split into two parts, a support set $S$ for learning and a prediction set $B$ for training or testing, $\mathcal{D}=\langle S, B\rangle$. Often we consider a *K-shot N-class classification* task: the support set contains K labelled examples for each of N classes.

![An example of 4-shot 2-class image classification. (Image thumbnails are from Pinterest )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/few-shot-classification.png)

#### 以与测试相同的方式进行训练

> Training in the Same Way as Testing

一个数据集 $\mathcal{D}$ 包含特征向量和标签对， $\mathcal{D} = \{(\mathbf{x}_i, y_i)\}$ 并且每个标签都属于一个已知的标签集 $\mathcal{L}^\text{label}$。 假设我们的分类器 $f_\theta$ 带有参数 $\theta$ 输出一个数据点属于该类别的概率 $y$ 给定特征向量 $\mathbf{x}$, $P_\theta(y\vert\mathbf{x})$。

> A dataset $\mathcal{D}$ contains pairs of feature vectors and labels, $\mathcal{D} = \{(\mathbf{x}_i, y_i)\}$ and each label belongs to a known label set $\mathcal{L}^\text{label}$.  Let’s say, our classifier $f_\theta$ with parameter $\theta$ outputs a probability of a data point belonging to the class $y$ given the feature vector $\mathbf{x}$, $P_\theta(y\vert\mathbf{x})$.

最优参数应最大化多个训练批次中真实标签的概率 $B \subset \mathcal{D}$:

> The optimal parameters should maximize the probability of true labels across multiple training batches $B \subset \mathcal{D}$:

$$
\begin{aligned}
\theta^* &= {\arg\max}_{\theta} \mathbb{E}_{(\mathbf{x}, y)\in \mathcal{D}}[P_\theta(y \vert \mathbf{x})] &\\
\theta^* &= {\arg\max}_{\theta} \mathbb{E}_{B\subset \mathcal{D}}[\sum_{(\mathbf{x}, y)\in B}P_\theta(y \vert \mathbf{x})] & \scriptstyle{\text{; trained with mini-batches.}}
\end{aligned}
$$

在少样本分类中，目标是给定一个用于“快速学习”的小型支持集（想想“微调”是如何工作的），减少对未知标签数据样本的预测误差。为了使训练过程模仿推理过程中发生的情况，我们希望使用标签子集“伪造”数据集，以避免将所有标签暴露给模型，并相应地修改优化过程以鼓励快速学习：

> In few-shot classification, the goal is to reduce the prediction error on data samples with unknown labels given a small support set for “fast learning” (think of how “fine-tuning” works). To make the training process mimics what happens during inference, we would like to “fake” datasets with a subset of labels to avoid exposing all the labels to the model and modify the optimization procedure accordingly to encourage fast learning:

1\. 采样一个标签子集，$L\subset\mathcal{L}^\text{label}$。

2\. 采样一个支持集 $S^L \subset \mathcal{D}$ 和一个训练批次 $B^L \subset \mathcal{D}$。它们都只包含标签属于采样标签集 $L$ 的数据点，$y \in L, \forall (x, y) \in S^L, B^L$。

3\. 支持集是模型输入的一部分。，$\hat{y}=f\_\theta(\mathbf{x}, S^L)$ 

4\. 最终优化使用小批量 $B^L$ 来计算损失并通过反向传播更新模型参数，其方式与我们在监督学习中使用它的方式相同。

英文原文：

1\. Sample a subset of labels, $L\subset\mathcal{L}^\text{label}$.

2\. Sample a support set $S^L \subset \mathcal{D}$ and a training batch $B^L \subset \mathcal{D}$. Both of them only contain data points with labels belonging to the sampled label set $L$, $y \in L, \forall (x, y) \in S^L, B^L$.

3\. The support set is part of the model input.  , $\hat{y}=f\_\theta(\mathbf{x}, S^L)$ 

4\. The final optimization uses the mini-batch $B^L$ to compute the loss and update the model parameters through backpropagation, in the same way as how we use it in the supervised learning.

您可以将每对采样数据集 $(S^L, B^L)$ 视为一个数据点。模型经过训练，使其能够泛化到其他数据集。红色符号是除了监督学习目标之外为元学习添加的。

> You may consider each pair of sampled dataset $(S^L, B^L)$ as one data point. The model is trained such that it can generalize to other datasets.  Symbols in red are added for meta-learning in addition to the supervised learning objective.

$$
\theta = \arg\max_\theta \color{red}{E_{L\subset\mathcal{L}}[} E_{\color{red}{S^L \subset\mathcal{D}, }B^L \subset\mathcal{D}} [\sum_{(x, y)\in B^L} P_\theta(x, y\color{red}{, S^L})] \color{red}{]}
$$

这个想法在某种程度上类似于在只有有限的任务特定数据样本可用时，在图像分类（ImageNet）或语言建模（大型文本语料库）中使用预训练模型。元学习将这个想法更进一步，它不是根据一个下游任务进行微调，而是优化模型使其擅长许多任务，如果不是全部的话。

> The idea is to some extent similar to using a pre-trained model in image classification (ImageNet) or language modeling (big text corpora) when only a limited set of task-specific data samples are available. Meta-learning takes this idea one step further, rather than fine-tuning according to one down-steam task, it optimizes the model to be good at many, if not all.

#### 学习器和元学习器

> Learner and Meta-Learner

元学习的另一种流行观点将模型更新分解为两个阶段：

> Another popular view of meta-learning decomposes the model update into two stages:

• 分类器 $f_\theta$ 是“学习器”模型，用于执行给定任务；

• 同时，优化器 $g_\phi$ 学习如何通过支持集 $S$ 更新学习器模型的参数，$\theta’ = g_\phi(\theta, S)$。

英文原文：

• A classifier $f_\theta$ is the “learner” model, trained for operating a given task;

• In the meantime, a optimizer $g_\phi$ learns how to update the learner model’s parameters via the support set $S$, $\theta’ = g_\phi(\theta, S)$.

然后在最终优化步骤中，我们需要更新 $\theta$ 和 $\phi$ 以最大化：

> Then in final optimization step, we need to update both $\theta$ and $\phi$ to maximize:

$$
\mathbb{E}_{L\subset\mathcal{L}}[ \mathbb{E}_{S^L \subset\mathcal{D}, B^L \subset\mathcal{D}} [\sum_{(\mathbf{x}, y)\in B^L} P_{g_\phi(\theta, S^L)}(y \vert \mathbf{x})]]
$$

#### 常见方法

> Common Approaches

元学习有三种常见方法：基于度量、基于模型和基于优化。Oriol Vinyals 在 NIPS 2018 元学习研讨会上的 [演讲](http://metalearning-symposium.ml/files/vinyals.pdf) 中对此进行了很好的总结：

> There are three common approaches to meta-learning: metric-based, model-based, and optimization-based. Oriol Vinyals has a nice summary in his [talk](http://metalearning-symposium.ml/files/vinyals.pdf) at meta-learning symposium @ NIPS 2018:

|  | 基于模型 | 基于度量 | 基于优化 |
| --- | --- | --- | --- |
| 核心思想 | RNN；记忆 | 度量学习 | 梯度下降 |
| $P_\theta(y \vert \mathbf{x})$ 如何建模？ | $f_\theta(\mathbf{x}, S)$ | $\sum_{(\mathbf{x}_i, y_i) \in S} k_\theta(\mathbf{x}, \mathbf{x}_i)y_i$ (*) | $P_{g_\phi(\theta, S^L)}(y \vert \mathbf{x})$ |

> 英文原表 / English original

|  | Model-based | Metric-based | Optimization-based |
| --- | --- | --- | --- |
| Key idea | RNN; memory | Metric learning | Gradient descent |
| How $P_\theta(y \vert \mathbf{x})$ is modeled? | $f_\theta(\mathbf{x}, S)$ | $\sum_{(\mathbf{x}_i, y_i) \in S} k_\theta(\mathbf{x}, \mathbf{x}_i)y_i$ (*) | $P_{g_\phi(\theta, S^L)}(y \vert \mathbf{x})$ |

(*) $k_\theta$ 是一个核函数，用于衡量 $\mathbf{x}_i$ 和 $\mathbf{x}$ 之间的相似性。

> (*) $k_\theta$ is a kernel function measuring the similarity between $\mathbf{x}_i$ and $\mathbf{x}$.

接下来我们将回顾每种方法中的经典模型。

> Next we are gonna review classic models in each approach.

### 基于度量

> Metric-Based

基于度量的元学习的核心思想类似于最近邻算法（即 [k-NN](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm) 分类器和 [k-means](https://en.wikipedia.org/wiki/K-means_clustering) 聚类）和 [核密度估计](https://en.wikipedia.org/wiki/Kernel_density_estimation)。在已知标签集 $y$ 上的预测概率是支持集样本标签的加权和。权重由核函数 $k_\theta$ 生成，用于衡量两个数据样本之间的相似性。

> The core idea in metric-based meta-learning is similar to nearest neighbors algorithms (i.e., [k-NN](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm) classificer and [k-means](https://en.wikipedia.org/wiki/K-means_clustering) clustering) and [kernel density estimation](https://en.wikipedia.org/wiki/Kernel_density_estimation). The predicted probability over a set of known labels $y$ is a weighted sum of labels of support set samples. The weight is generated by a kernel function $k_\theta$, measuring the similarity between two data samples.

$$
P_\theta(y \vert \mathbf{x}, S) = \sum_{(\mathbf{x}_i, y_i) \in S} k_\theta(\mathbf{x}, \mathbf{x}_i)y_i
$$

学习一个好的核函数对于基于度量的元学习模型的成功至关重要。[度量学习](https://en.wikipedia.org/wiki/Similarity_learning#Metric_learning) 与此意图高度契合，因为它旨在学习对象上的度量或距离函数。良好度量的概念是问题相关的。它应该表示任务空间中输入之间的关系并促进问题解决。

> To learn a good kernel is crucial to the success of a metric-based meta-learning model. [Metric learning](https://en.wikipedia.org/wiki/Similarity_learning#Metric_learning) is well aligned with this intention, as it aims to learn a metric or distance function over objects. The notion of a good metric is problem-dependent. It should represent the relationship between inputs in the task space and facilitate problem solving.

下面介绍的所有模型都显式地学习输入数据的嵌入向量，并使用它们来设计合适的核函数。

> All the models introduced below learn embedding vectors of input data explicitly and use them to design proper kernel functions.

#### 卷积孪生神经网络

> Convolutional Siamese Neural Network

 [孪生神经网络](https://papers.nips.cc/paper/769-signature-verification-using-a-siamese-time-delay-neural-network.pdf)由两个孪生网络组成，它们的输出通过一个函数进行联合训练，以学习输入数据样本对之间的关系。这两个孪生网络是相同的，共享相同的权重和网络参数。换句话说，两者都指的是同一个嵌入网络，该网络学习一种高效的嵌入方式，以揭示数据点对之间的关系。

> The [Siamese Neural Network](https://papers.nips.cc/paper/769-signature-verification-using-a-siamese-time-delay-neural-network.pdf) is composed of two twin networks and their outputs are jointly trained on top with a function to learn the relationship between pairs of input data samples. The twin networks are identical, sharing the same weights and network parameters. In other words, both refer to the same embedding network that learns an efficient embedding to reveal relationship between pairs of data points.

[Koch, Zemel & Salakhutdinov (2015)](http://www.cs.toronto.edu/~rsalakhu/papers/oneshot1.pdf)提出了一种使用孪生神经网络进行一次性图像分类的方法。首先，孪生网络被训练用于一个验证任务，以判断两张输入图像是否属于同一类别。它输出两张图像属于同一类别的概率。然后，在测试时，孪生网络处理测试图像与支持集中的每张图像之间的所有图像对。最终的预测是具有最高概率的支持图像的类别。

> [Koch, Zemel & Salakhutdinov (2015)](http://www.cs.toronto.edu/~rsalakhu/papers/oneshot1.pdf) proposed a method to use the siamese neural network to do one-shot image classification. First, the siamese network is trained for a verification task for telling whether two input images are in the same class. It outputs the probability of two images belonging to the same class. Then, during test time, the siamese network processes all the image pairs between a test image and every image in the support set. The final prediction is the class of the support image with the highest probability.

![The architecture of convolutional siamese neural network for few-show image classification.](https://lilianweng.github.io/posts/2018-11-30-meta-learning/siamese-conv-net.png)

1\. 首先，卷积孪生网络通过一个嵌入函数$f_\theta$学习将两张图像编码成特征向量，该函数包含若干个卷积层。

2\. 两个嵌入之间的L1距离是$\vert f_\theta(\mathbf{x}_i) - f_\theta(\mathbf{x}_j) \vert$。

3\. 该距离通过一个线性前馈层和sigmoid函数转换为概率$p$。它是两张图像是否来自同一类别的概率。

4\. 直观上，由于标签是二元的，损失是交叉熵。

英文原文：

1\. First, convolutional siamese network learns to encode two images into feature vectors via a embedding function $f_\theta$ which contains a couple of convolutional layers.

2\. The L1-distance between two embeddings is $\vert f_\theta(\mathbf{x}_i) - f_\theta(\mathbf{x}_j) \vert$.

3\. The distance is converted to a probability $p$ by a linear feedforward layer and sigmoid. It is the probability of whether two images are drawn from the same class.

4\. Intuitively the loss is cross entropy because the label is binary.

$$
\begin{aligned}
p(\mathbf{x}_i, \mathbf{x}_j) &= \sigma(\mathbf{W}\vert f_\theta(\mathbf{x}_i) - f_\theta(\mathbf{x}_j) \vert) \\
\mathcal{L}(B) &= \sum_{(\mathbf{x}_i, \mathbf{x}_j, y_i, y_j)\in B} \mathbf{1}_{y_i=y_j}\log p(\mathbf{x}_i, \mathbf{x}_j) + (1-\mathbf{1}_{y_i=y_j})\log (1-p(\mathbf{x}_i, \mathbf{x}_j))
\end{aligned}
$$

训练批次中的图像$B$可以通过失真进行增强。当然，你可以用其他距离度量（L2、余弦等）替换L1距离。只需确保它们是可微分的，然后其他一切都以相同的方式工作。

> Images in the training batch $B$ can be augmented with distortion. Of course, you can replace the L1 distance with other distance metric, L2, cosine, etc. Just make sure they are differential and then everything else works the same.

给定一个支持集$S$和一个测试图像$\mathbf{x}$，最终预测的类别是：

> Given a support set $S$ and a test image $\mathbf{x}$, the final predicted class is:

$$
\hat{c}_S(\mathbf{x}) = c(\arg\max_{\mathbf{x}_i \in S} P(\mathbf{x}, \mathbf{x}_i))
$$

其中$c(\mathbf{x})$是图像$\mathbf{x}$的类别标签，$\hat{c}(.)$是预测标签。

> where $c(\mathbf{x})$ is the class label of an image $\mathbf{x}$ and $\hat{c}(.)$ is the predicted label.

其假设是，所学习的嵌入可以泛化，用于测量未知类别图像之间的距离。这与通过采用预训练模型进行迁移学习背后的假设相同；例如，在ImageNet上预训练的模型中学习到的卷积特征有望帮助其他图像任务。然而，当新任务与模型训练的原始任务偏离时，预训练模型的好处会减小。

> The assumption is that the learned embedding can be generalized to be useful for measuring the distance between images of unknown categories. This is the same assumption behind transfer learning via the adoption of a pre-trained model; for example, the convolutional features learned in the model pre-trained with ImageNet are expected to help other image tasks. However, the benefit of a pre-trained model decreases when the new task diverges from the original task that the model was trained on.

#### 匹配网络

> Matching Networks

**匹配网络**（[Vinyals 等人，2016](http://papers.nips.cc/paper/6385-matching-networks-for-one-shot-learning.pdf)）的任务是学习一个分类器`c_S`，用于任何给定的（小）支持集$S=\{x_i, y_i\}_{i=1}^k$（*k-shot* 分类）。该分类器定义了输出标签`y`上的概率分布，给定一个测试样本$\mathbf{x}$。与其他基于度量的模型类似，分类器输出被定义为支持样本标签的总和，并由注意力核$a(\mathbf{x}, \mathbf{x}_i)$加权——这应该与$\mathbf{x}$和$\mathbf{x}_i$的相似性成比例。

英文原文：The task of Matching Networks ([Vinyals et al., 2016](http://papers.nips.cc/paper/6385-matching-networks-for-one-shot-learning.pdf)) is to learn a classifier `c_S` for any given (small) support set 

$S=\{x_i, y_i\}_{i=1}^k$ (*k-shot* classification). This classifier defines a probability distribution over output labels `y` given a test example 

$\mathbf{x}$. Similar to other metric-based models, the classifier output is defined as a sum of labels of support samples weighted by attention kernel 

$a(\mathbf{x}, \mathbf{x}_i)$ - which should be proportional to the similarity between 

$\mathbf{x}$ and 

$\mathbf{x}_i$.

![The architecture of Matching Networks. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/matching-networks.png)

$$
c_S(\mathbf{x}) = P(y \vert \mathbf{x}, S) = \sum_{i=1}^k a(\mathbf{x}, \mathbf{x}_i) y_i
\text{, where }S=\{(\mathbf{x}_i, y_i)\}_{i=1}^k
$$

注意力核依赖于两个嵌入函数，$f$ 和 $g$，分别用于编码测试样本和支持集样本。两个数据点之间的注意力权重是余弦相似度，$\text{cosine}(.)$，在其嵌入向量之间，并通过 softmax 进行归一化：

> The attention kernel depends on two embedding functions, $f$ and $g$, for encoding the test sample and the support set samples respectively. The attention weight between two data points is the cosine similarity, $\text{cosine}(.)$, between their embedding vectors, normalized by softmax:

$$
a(\mathbf{x}, \mathbf{x}_i) = \frac{\exp(\text{cosine}(f(\mathbf{x}), g(\mathbf{x}_i))}{\sum_{j=1}^k\exp(\text{cosine}(f(\mathbf{x}), g(\mathbf{x}_j))}
$$

##### 简单嵌入

> Simple Embedding

在简单版本中，嵌入函数是一个以单个数据样本作为输入的神经网络。我们可能会设置$f=g$。

> In the simple version, an embedding function is a neural network with a single data sample as input. Potentially we can set $f=g$.

##### 全上下文嵌入

> Full Context Embeddings

嵌入向量是构建良好分类器的关键输入。以单个数据点作为输入可能不足以有效地衡量整个特征空间。因此，Matching Network 模型进一步提出通过除了原始输入之外，还将整个支持集 $S$ 作为输入来增强嵌入函数，从而可以根据与其他支持样本的关系来调整学习到的嵌入。

> The embedding vectors are critical inputs for building a good classifier. Taking a single data point as input might not be enough to efficiently gauge the entire feature space. Therefore, the Matching Network model further proposed to enhance the embedding functions by taking as input the whole support set $S$ in addition to the original input, so that the learned embedding can be adjusted based on the relationship with other support samples.

• 
$g_\theta(\mathbf{x}_i, S)$ 使用双向 LSTM 编码 $\mathbf{x}_i$ 在整个支持集的上下文中 $S$。


• 
$f_\theta(\mathbf{x}, S)$ 对测试样本 $\mathbf{x}$ 进行编码，通过一个在支持集 $S$ 上带有读取注意力的LSTM。





1\. 首先，测试样本会通过一个简单的神经网络（例如CNN）来提取基本特征，$f’(\mathbf{x})$。



2\. 然后，使用一个在支持集上带有读取注意力向量的 LSTM 进行训练，该向量作为隐藏状态的一部分：  

1\. 最终，$f(\mathbf{x}, S)=\mathbf{h}_K$ 如果我们执行 K 步“读取”操作。

英文原文：

• 
$g_\theta(\mathbf{x}_i, S)$ uses a bidirectional LSTM to encode $\mathbf{x}_i$ in the context of the entire support set $S$.


• 
$f_\theta(\mathbf{x}, S)$ encodes the test sample $\mathbf{x}$ visa an LSTM with read attention over the support set $S$.





1\. First the test sample goes through a simple neural network, such as a CNN, to extract basic features, $f’(\mathbf{x})$.



2\. Then an LSTM is trained with a read attention vector over the support set as part of the hidden state:   

1\. Eventually $f(\mathbf{x}, S)=\mathbf{h}_K$ if we do K steps of “read”.

$$
\begin{aligned}
  \hat{\mathbf{h}}_t, \mathbf{c}_t &= \text{LSTM}(f'(\mathbf{x}), [\mathbf{h}_{t-1}, \mathbf{r}_{t-1}], \mathbf{c}_{t-1}) \\
  \mathbf{h}_t &= \hat{\mathbf{h}}_t + f'(\mathbf{x}) \\
  \mathbf{r}_{t-1} &= \sum_{i=1}^k a(\mathbf{h}_{t-1}, g(\mathbf{x}_i)) g(\mathbf{x}_i) \\
  a(\mathbf{h}_{t-1}, g(\mathbf{x}_i)) &= \text{softmax}(\mathbf{h}_{t-1}^\top g(\mathbf{x}_i)) = \frac{\exp(\mathbf{h}_{t-1}^\top g(\mathbf{x}_i))}{\sum_{j=1}^k \exp(\mathbf{h}_{t-1}^\top g(\mathbf{x}_j))}
  \end{aligned}
$$

这种嵌入方法被称为“全上下文嵌入（FCE）”。有趣的是，它确实有助于提高在困难任务（mini ImageNet 上的少样本分类）上的性能，但在简单任务（Omniglot）上没有区别。

> This embedding method is called “Full Contextual Embeddings (FCE)”. Interestingly it does help improve the performance on a hard task (few-shot classification on mini ImageNet), but makes no difference on a simple task (Omniglot).

匹配网络中的训练过程旨在与测试时的推理相匹配，详见前面的[章节](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#training-in-the-same-way-as-testing)。值得一提的是，匹配网络论文完善了训练和测试条件应匹配的理念。

> The training process in Matching Networks is designed to match inference at test time, see the details in the earlier [section](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#training-in-the-same-way-as-testing). It is worthy of mentioning that the Matching Networks paper refined the idea that training and testing conditions should match.

$$
\theta^* = \arg\max_\theta \mathbb{E}_{L\subset\mathcal{L}}[ \mathbb{E}_{S^L \subset\mathcal{D}, B^L \subset\mathcal{D}} [\sum_{(\mathbf{x}, y)\in B^L} P_\theta(y\vert\mathbf{x}, S^L)]]
$$

#### 关系网络

> Relation Network

**关系网络 (RN)** ([Sung 等人，2018](http://openaccess.thecvf.com/content_cvpr_2018/papers_backup/Sung_Learning_to_Compare_CVPR_2018_paper.pdf)) 类似于[孪生网络](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#convolutional-siamese-neural-network)，但有一些区别：

> **Relation Network (RN)** ([Sung et al., 2018](http://openaccess.thecvf.com/content_cvpr_2018/papers_backup/Sung_Learning_to_Compare_CVPR_2018_paper.pdf)) is similar to [siamese network](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#convolutional-siamese-neural-network) but with a few differences:

1\. 关系不是通过特征空间中的简单 L1 距离捕获的，而是由 CNN 分类器预测的$g_\phi$。一对输入$\mathbf{x}_i$和$\mathbf{x}_j$之间的关系分数是$r_{ij} = g_\phi([\mathbf{x}_i, \mathbf{x}_j])$，其中$[.,.]$是连接。

2\. 目标函数是 MSE 损失而不是交叉熵，因为从概念上讲，RN 更侧重于预测关系分数，这更像是回归而不是二元分类$\mathcal{L}(B) = \sum_{(\mathbf{x}_i, \mathbf{x}_j, y_i, y_j)\in B} (r_{ij} - \mathbf{1}_{y_i=y_j})^2$。

英文原文：

1\. The relationship is not captured by a simple L1 distance in the feature space, but predicted by a CNN classifier $g_\phi$. The relation score between a pair of inputs, $\mathbf{x}_i$ and $\mathbf{x}_j$, is $r_{ij} = g_\phi([\mathbf{x}_i, \mathbf{x}_j])$ where $[.,.]$ is concatenation.

2\. The objective function is MSE loss instead of cross-entropy, because conceptually RN focuses more on predicting relation scores which is more like regression, rather than binary classification, $\mathcal{L}(B) = \sum_{(\mathbf{x}_i, \mathbf{x}_j, y_i, y_j)\in B} (r_{ij} - \mathbf{1}_{y_i=y_j})^2$.

![Relation Network architecture for a 5-way 1-shot problem with one query example. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/relation-network.png)

（注意：DeepMind 提出了另一个用于关系推理的[关系网络](https://deepmind.com/blog/neural-approach-relational-reasoning/)。请勿混淆。）

> (Note: There is another [Relation Network](https://deepmind.com/blog/neural-approach-relational-reasoning/) for relational reasoning, proposed by DeepMind. Don’t get confused.)

#### 原型网络

> Prototypical Networks

**原型网络** ([Snell, Swersky & Zemel, 2017](http://papers.nips.cc/paper/6996-prototypical-networks-for-few-shot-learning.pdf)) 使用嵌入函数 $f_\theta$ 将每个输入编码成一个 `M` 维特征向量。一个 *原型* 特征向量被定义为每个类别 $c \in \mathcal{C}$ 中嵌入支持数据样本的平均向量。

英文原文：Prototypical Networks ([Snell, Swersky & Zemel, 2017](http://papers.nips.cc/paper/6996-prototypical-networks-for-few-shot-learning.pdf)) use an embedding function 

$f_\theta$ to encode each input into a `M` -dimensional feature vector. A *prototype* feature vector is defined for every class 

$c \in \mathcal{C}$, as the mean vector of the embedded support data samples in this class.

$$
\mathbf{v}_c = \frac{1}{|S_c|} \sum_{(\mathbf{x}_i, y_i) \in S_c} f_\theta(\mathbf{x}_i)
$$

![Prototypical networks in the few-shot and zero-shot scenarios. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/prototypical-networks.png)

给定测试输入下的类别分布$\mathbf{x}$是测试数据嵌入与原型向量之间距离倒数的 softmax。

> The distribution over classes for a given test input $\mathbf{x}$ is a softmax over the inverse of distances between the test data embedding and prototype vectors.

$$
P(y=c\vert\mathbf{x})=\text{softmax}(-d_\varphi(f_\theta(\mathbf{x}), \mathbf{v}_c)) = \frac{\exp(-d_\varphi(f_\theta(\mathbf{x}), \mathbf{v}_c))}{\sum_{c' \in \mathcal{C}}\exp(-d_\varphi(f_\theta(\mathbf{x}), \mathbf{v}_{c'}))}
$$

其中 $d_\varphi$ 可以是任何距离函数，只要 $\varphi$ 是可微分的。在论文中，他们使用了平方欧几里得距离。

> where $d_\varphi$ can be any distance function as long as $\varphi$ is differentiable. In the paper, they used the squared euclidean distance.

损失函数是负对数似然： $\mathcal{L}(\theta) = -\log P_\theta(y=c\vert\mathbf{x})$。

> The loss function is the negative log-likelihood: $\mathcal{L}(\theta) = -\log P_\theta(y=c\vert\mathbf{x})$.

### 基于模型

> Model-Based

基于模型的元学习模型对$P_\theta(y\vert\mathbf{x})$的形式不作任何假设。相反，它依赖于一个专门为快速学习设计的模型——一个通过少量训练步骤就能快速更新其参数的模型。这种快速的参数更新可以通过其内部架构实现，也可以由另一个元学习器模型控制。

> Model-based meta-learning models make no assumption on the form of $P_\theta(y\vert\mathbf{x})$. Rather it depends on a model designed specifically for fast learning — a model that updates its parameters rapidly with a few training steps. This rapid parameter update can be achieved by its internal architecture or controlled by another meta-learner model.

#### 记忆增强神经网络

> Memory-Augmented Neural Networks

一系列模型架构使用外部存储器来促进神经网络的学习过程，包括[神经图灵机](https://lilianweng.github.io/posts/2018-06-24-attention/#neural-turing-machines)和[记忆网络](https://arxiv.org/abs/1410.3916)。有了显式的存储缓冲区，网络更容易快速地整合新信息，并且在未来不会遗忘。这种模型被称为**MANN**，是“**记忆增强神经网络**”的缩写。请注意，仅具有*内部记忆*的循环神经网络，如普通RNN或LSTM，不是MANN。

> A family of model architectures use external memory storage to facilitate the learning process of neural networks, including [Neural Turing Machines](https://lilianweng.github.io/posts/2018-06-24-attention/#neural-turing-machines) and [Memory Networks](https://arxiv.org/abs/1410.3916). With an explicit storage buffer, it is easier for the network to rapidly incorporate new information and not to forget in the future. Such a model is known as **MANN**, short for “**Memory-Augmented Neural Network**”.  Note that recurrent neural networks with only *internal memory* such as vanilla RNN or LSTM are not MANNs.

由于MANN有望快速编码新信息，从而在仅有少量样本后就能适应新任务，因此它非常适合元学习。以神经图灵机（NTM）为基础模型，[Santoro et al. (2016)](http://proceedings.mlr.press/v48/santoro16.pdf)提出了一系列关于训练设置和记忆检索机制（或“寻址机制”，决定如何将注意力权重分配给记忆向量）的修改。如果您不熟悉此问题，请在继续阅读之前先查阅我另一篇文章中的[NTM部分](https://lilianweng.github.io/posts/2018-06-24-attention/#neural-turing-machines)。

> Because MANN is expected to encode new information fast and thus to adapt to new tasks after only a few samples, it fits well for meta-learning. Taking the Neural Turing Machine (NTM) as the base model, [Santoro et al. (2016)](http://proceedings.mlr.press/v48/santoro16.pdf) proposed a set of modifications on the training setup and the memory retrieval mechanisms (or “addressing mechanisms”, deciding how to assign attention weights to memory vectors). Please go through [the NTM section](https://lilianweng.github.io/posts/2018-06-24-attention/#neural-turing-machines) in my other post first if you are not familiar with this matter before reading forward.

快速回顾一下，NTM将一个控制器神经网络与外部存储器耦合。控制器通过软注意力学习读写记忆行，而记忆则充当知识库。注意力权重由其寻址机制生成：基于内容+基于位置。

> As a quick recap, NTM couples a controller neural network with external memory storage. The controller learns to read and write memory rows by soft attention, while the memory serves as a knowledge repository. The attention weights are generated by its addressing mechanism: content-based + location based.

![The architecture of Neural Turing Machine (NTM). The memory at time t, $\mathbf{M}\_t$ is a matrix of size $N \times M$, containing N vector rows and each has M dimensions.](https://lilianweng.github.io/posts/2018-11-30-meta-learning/NTM.png)

##### 用于元学习的MANN

> MANN for Meta-Learning

为了将MANN用于元学习任务，我们需要以一种方式对其进行训练，使得记忆能够快速编码和捕获新任务的信息，同时，任何存储的表示都易于且稳定地访问。

> To use MANN for meta-learning tasks, we need to train it in a way that the memory can encode and capture information of new tasks fast and, in the meantime, any stored representation is easily and stably accessible.

[Santoro et al., 2016](http://proceedings.mlr.press/v48/santoro16.pdf)中描述的训练以一种有趣的方式进行，使得记忆被迫更长时间地保存信息，直到稍后呈现适当的标签。在每个训练回合中，真实标签`y_t`以**一步偏移**呈现，$(\mathbf{x}_{t+1}, y_t)$：它是前一时间步t的输入的真实标签，但作为时间步t+1输入的一部分呈现。

英文原文：The training described in [Santoro et al., 2016](http://proceedings.mlr.press/v48/santoro16.pdf) happens in an interesting way so that the memory is forced to hold information for longer until the appropriate labels are presented later. In each training episode, the truth label `y_t` is presented with one step offset, 

$(\mathbf{x}_{t+1}, y_t)$: it is the true label for the input at the previous time step t, but presented as part of the input at time step t+1.

![Task setup in MANN for meta-learning (Image source: original paper ).](https://lilianweng.github.io/posts/2018-11-30-meta-learning/mann-meta-learning.png)

通过这种方式，MANN被激励去记忆新数据集的信息，因为记忆必须保存当前输入直到稍后标签出现，然后检索旧信息以进行相应的预测。

> In this way, MANN is motivated to memorize the information of a new dataset, because the memory has to hold the current input until the label is present later and then retrieve the old information to make a prediction accordingly.

接下来让我们看看记忆是如何更新以实现高效信息检索和存储的。

> Next let us see how the memory is updated for efficient information retrieval and storage.

##### 元学习的寻址机制

> Addressing Mechanism for Meta-Learning

除了训练过程，还利用了一种新的纯粹基于内容的寻址机制，以使模型更适合元学习。

> Aside from the training process, a new pure content-based addressing mechanism is utilized to make the model better suitable for meta-learning.

**» 如何从内存中读取？**  
读取注意力完全基于内容相似性构建。

> **» How to read from memory?**
>
>
> The read attention is constructed purely based on the content similarity.

首先，控制器在时间步 t 生成一个关键特征向量 $\mathbf{k}_t$，作为输入 $\mathbf{x}$ 的函数。与 NTM 类似，一个包含 N 个元素的读取权重向量 $\mathbf{w}_t^r$ 被计算为关键向量与每个内存向量行之间的余弦相似度，并通过 softmax 进行归一化。读取向量 $\mathbf{r}_t$ 是由这些权重加权的内存记录之和：

> First, a key feature vector $\mathbf{k}_t$ is produced at the time step t by the controller as a function of the input $\mathbf{x}$. Similar to NTM, a read weighting vector $\mathbf{w}_t^r$ of N elements is computed as the cosine similarity between the key vector and every memory vector row, normalized by softmax. The read vector $\mathbf{r}_t$ is a sum of memory records weighted by such weightings:

$$
\mathbf{r}_i = \sum_{i=1}^N w_t^r(i)\mathbf{M}_t(i)
\text{, where } w_t^r(i) = \text{softmax}(\frac{\mathbf{k}_t \cdot \mathbf{M}_t(i)}{\|\mathbf{k}_t\| \cdot \|\mathbf{M}_t(i)\|})
$$

其中 $M_t$ 是时间 t 的内存矩阵，$M_t(i)$ 是该矩阵中的第 i 行。

> where $M_t$ is the memory matrix at time t and $M_t(i)$ is the i-th row in this matrix.

**» 如何写入内存？**  
将新接收到的信息写入内存的寻址机制与 [缓存替换](https://en.wikipedia.org/wiki/Cache_replacement_policies) 策略非常相似。**最近最少使用访问（LRUA）**写入器旨在使 MANN 在元学习场景中更好地工作。LRUA 写入头倾向于将新内容写入 *最少使用* 的内存位置或 *最近使用* 的内存位置。

> **» How to write into memory?**
>
>
> The addressing mechanism for writing newly received information into memory operates a lot like the [cache replacement](https://en.wikipedia.org/wiki/Cache_replacement_policies) policy. The **Least Recently Used Access (LRUA)** writer is designed for MANN to better work in the scenario of meta-learning. A LRUA write head prefers to write new content to either the *least used* memory location or the *most recently used* memory location.

- 很少使用的位置：这样我们可以保留经常使用的信息（参见 [LFU](https://en.wikipedia.org/wiki/Least_frequently_used)）；
- 上次使用的位置：其动机是，一旦一条信息被检索过一次，它可能在一段时间内不会再次被调用（参见 [MRU](https://en.wikipedia.org/wiki/Cache_replacement_policies#Most_recently_used_(MRU))）。

> • Rarely used locations: so that we can preserve frequently used information (see [LFU](https://en.wikipedia.org/wiki/Least_frequently_used));
> • The last used location: the motivation is that once a piece of information is retrieved once, it probably won’t be called again for a while (see [MRU](https://en.wikipedia.org/wiki/Cache_replacement_policies#Most_recently_used_(MRU))).

有许多缓存替换算法，每种算法都可能在不同的用例中以更好的性能取代这里的设计。此外，了解内存使用模式和寻址策略而不是随意设置它会是一个好主意。

> There are many cache replacement algorithms and each of them could potentially replace the design here with better performance in different use cases. Furthermore, it would be a good idea to learn the memory usage pattern and addressing strategies rather than arbitrarily set it.

LRUA 的偏好以一切皆可微分的方式实现：

> The preference of LRUA is carried out in a way that everything is differentiable:

1\. 在时间 t 的使用权重 $\mathbf{w}^u_t$ 是当前读向量和写向量的总和，此外还有衰减的上次使用权重 $\gamma \mathbf{w}^u_{t-1}$，其中 $\gamma$ 是一个衰减因子。

2\. 写向量是前一个读权重（偏好“上次使用的位置”）和前一个最少使用权重（偏好“很少使用的位置”）之间的插值。插值参数是超参数 $\alpha$ 的 sigmoid 函数。

3\. 最少使用权重 $\mathbf{w}^{lu}$ 根据使用权重 $\mathbf{w}_t^u$ 进行缩放，其中任何维度如果小于向量中第 n 个最小元素则保持为 1，否则为 0。

英文原文：

1\. The usage weight $\mathbf{w}^u_t$ at time t is a sum of current read and write vectors, in addition to the decayed last usage weight, $\gamma \mathbf{w}^u_{t-1}$, where $\gamma$ is a decay factor.

2\. The write vector is an interpolation between the previous read weight (prefer “the last used location”) and the previous least-used weight (prefer “rarely used location”). The interpolation parameter is the sigmoid of a hyperparameter $\alpha$.

3\. The least-used weight $\mathbf{w}^{lu}$ is scaled according to usage weights $\mathbf{w}_t^u$, in which any dimension remains at 1 if smaller than the n-th smallest element in the vector and 0 otherwise.

$$
\begin{aligned}
\mathbf{w}_t^u &= \gamma \mathbf{w}_{t-1}^u + \mathbf{w}_t^r + \mathbf{w}_t^w \\
\mathbf{w}_t^r &= \text{softmax}(\text{cosine}(\mathbf{k}_t, \mathbf{M}_t(i))) \\
\mathbf{w}_t^w &= \sigma(\alpha)\mathbf{w}_{t-1}^r + (1-\sigma(\alpha))\mathbf{w}^{lu}_{t-1}\\
\mathbf{w}_t^{lu} &= \mathbf{1}_{w_t^u(i) \leq m(\mathbf{w}_t^u, n)}
\text{, where }m(\mathbf{w}_t^u, n)\text{ is the }n\text{-th smallest element in vector }\mathbf{w}_t^u\text{.}
\end{aligned}
$$

最后，在由 $\mathbf{w}_t^{lu}$ 指示的最少使用的内存位置被设置为零之后，每一行内存都会更新：

> Finally, after the least used memory location, indicated by $\mathbf{w}_t^{lu}$, is set to zero, every memory row is updated:

$$
\mathbf{M}_t(i) = \mathbf{M}_{t-1}(i) + w_t^w(i)\mathbf{k}_t, \forall i
$$

#### 元网络

> Meta Networks

**元网络** ([Munkhdalai & Yu, 2017](https://arxiv.org/abs/1703.00837))，简称 **MetaNet**，是一种元学习模型，其架构和训练过程旨在实现 *快速* 跨任务泛化。

> **Meta Networks** ([Munkhdalai & Yu, 2017](https://arxiv.org/abs/1703.00837)), short for **MetaNet**, is a meta-learning model with architecture and training process designed for *rapid* generalization across tasks.

##### 快速权重

> Fast Weights

MetaNet 的快速泛化依赖于“快权重”。关于这个主题的论文有很多，但我没有详细阅读所有论文，也未能找到一个非常具体的定义，只有一个模糊的概念共识。通常，神经网络中的权重通过目标函数中的随机梯度下降进行更新，这个过程众所周知是缓慢的。一种更快的学习方法是利用一个神经网络来预测另一个神经网络的参数，生成的权重被称为*快权重*。相比之下，普通的基于 SGD 的权重被称为*慢权重*。

> The rapid generalization of MetaNet relies on “fast weights”. There are a handful of papers on this topic, but I haven’t read all of them in detail and I failed to find a very concrete definition, only a vague agreement on the concept. Normally weights in the neural networks are updated by stochastic gradient descent in an objective function and this process is known to be slow. One faster way to learn is to utilize one neural network to predict the parameters of another neural network and the generated weights are called *fast weights*. In comparison, the ordinary SGD-based weights are named *slow weights*.

在 MetaNet 中，损失梯度被用作*元信息*，以填充学习快权重的模型。慢权重和快权重结合起来在神经网络中进行预测。

> In MetaNet, loss gradients are used as *meta information* to populate models that learn fast weights. Slow and fast weights are combined to make predictions in neural networks.

![Combining slow and fast weights in a MLP. $\bigoplus$ is element-wise sum. (Image source: original paper ).](https://lilianweng.github.io/posts/2018-11-30-meta-learning/combine-slow-fast-weights.png)

##### 模型组件

> Model Components

> 免责声明：以下我的注释与论文中的不同。在我看来，这篇论文写得不好，但其思想仍然很有趣。因此，我将用我自己的语言来阐述这个思想。

> Disclaimer: Below you will find my annotations are different from those in the paper. imo, the paper is poorly written, but the idea is still interesting. So I’m presenting the idea in my own language.

MetaNet 的关键组成部分是：

> Key components of MetaNet are:

• 一个嵌入函数 $f_\theta$，由 $\theta$ 参数化，将原始输入编码成特征向量。类似于 [Siamese Neural Network](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#convolutional-siamese-neural-network)，这些嵌入被训练成能够有效地判断两个输入是否属于同一类别（验证任务）。

• 一个基础学习器模型$g_\phi$，由权重参数化$\phi$，完成实际的学习任务。

英文原文：

• An embedding function $f_\theta$, parameterized by $\theta$, encodes raw inputs into feature vectors. Similar to [Siamese Neural Network](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#convolutional-siamese-neural-network), these embeddings are trained to be useful for telling whether two inputs are of the same class (verification task).

• A base learner model $g_\phi$, parameterized by weights $\phi$, completes the actual learning task.

如果我们到此为止，它看起来就像[关系网络](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#relation-network)。此外，MetaNet 明确地建模了这两个函数的快速权重，然后将它们聚合回模型中（参见图 8）。

> If we stop here, it looks just like [Relation Network](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#relation-network). MetaNet, in addition, explicitly models the fast weights of both functions and then aggregates them back into the model (See Fig. 8).

因此，我们需要另外两个函数来分别输出 $f$ 和 $g$ 的快速权重。

> Therefore we need additional two functions to output fast weights for $f$ and $g$ respectively.

• $F_w$：一个由$w$参数化的 LSTM，用于学习$\theta^+$的快速权重，该权重属于嵌入函数$f$。它将$f$的嵌入损失梯度作为验证任务的输入。

• $G_v$: 一个由$v$参数化的神经网络，它从其损失梯度中为$\phi^+$基础学习器$g$学习快速权重。在 MetaNet 中，学习器的损失梯度被视为任务的*元信息*。

英文原文：

• $F_w$: a LSTM parameterized by $w$ for learning fast weights $\theta^+$ of the embedding function $f$. It takes as input gradients of $f$’s embedding loss for verification task.

• $G_v$: a neural network parameterized by $v$ learning fast weights $\phi^+$ for the base learner $g$ from its loss gradients. In MetaNet, the learner’s loss gradients are viewed as the *meta information* of the task.

好的，现在我们来看看元网络是如何训练的。训练数据包含多对数据集：一个支持集$S=\{\mathbf{x}’_i, y’_i\}_{i=1}^K$和一个测试集$U=\{\mathbf{x}_i, y_i\}_{i=1}^L$。回想一下，我们有四个网络和四组模型参数需要学习，$(\theta, \phi, w, v)$。

> Ok, now let’s see how meta networks are trained. The training data contains multiple pairs of datasets: a support set $S=\{\mathbf{x}’_i, y’_i\}_{i=1}^K$ and a test set  $U=\{\mathbf{x}_i, y_i\}_{i=1}^L$. Recall that we have four networks and four sets of model parameters to learn, $(\theta, \phi, w, v)$.

![Fig.9. The MetaNet architecture.](https://lilianweng.github.io/posts/2018-11-30-meta-learning/meta-network.png)

##### 训练过程

> Training Process

1\. 
在每个时间步 t，从支持集 $S$、$(\mathbf{x}’_i, y’_i)$ 和 $(\mathbf{x}’_j, y_j)$ 中随机抽取一对输入。令 $\mathbf{x}_{(t,1)}=\mathbf{x}’_i$ 和 $\mathbf{x}_{(t,2)}=\mathbf{x}’_j$。  

对于 $t = 1, \dots, K$：



• a. 计算表示学习的损失；即，验证任务的交叉熵：  



$\mathcal{L}^\text{emb}_t = \mathbf{1}_{y’_i=y’_j} \log P_t + (1 - \mathbf{1}_{y’_i=y’_j})\log(1 - P_t)\text{, where }P_t = \sigma(\mathbf{W}\vert f_\theta(\mathbf{x}_{(t,1)}) - f_\theta(\mathbf{x}_{(t,2)})\vert)$

2\. 
计算任务级别的快速权重：
$\theta^+ = F_w(\nabla_\theta \mathcal{L}^\text{emb}_1, \dots, \mathcal{L}^\text{emb}_T)$


3\. 接下来遍历支持集中的示例$S$并计算示例级的快速权重。同时，用学习到的表示更新记忆。  
对于$i=1, \dots, K$：

• a. 基础学习器输出一个概率分布：$P(\hat{y}_i \vert \mathbf{x}_i) = g_\phi(\mathbf{x}_i)$损失可以是交叉熵或MSE：$\mathcal{L}^\text{task}_i = y’_i \log g_\phi(\mathbf{x}’_i) + (1- y’_i) \log (1 - g_\phi(\mathbf{x}’_i))$



• b. 提取任务的元信息（损失梯度）并计算示例级的快速权重：$\phi_i^+ = G_v(\nabla_\phi\mathcal{L}^\text{task}_i)$



• 然后将 $\phi^+_i$ 存储到“值”内存的第 $i$ 个位置 $\mathbf{M}$。  



• d. 使用慢速和快速权重将支持样本编码为任务特定的输入表示：$r’_i = f_{\theta, \theta^+}(\mathbf{x}’_i)$







• 然后将$r’_i$存储到$i$个“键”内存位置$\mathbf{R}$。

4\. 最后，是时候使用测试集构建训练损失了$U=\{\mathbf{x}_i, y_i\}_{i=1}^L$。  
从$\mathcal{L}_\text{train}=0$开始：  
对于$j=1, \dots, L$：

• a. 将测试样本编码为特定任务的输入表示：$r_j = f_{\theta, \theta^+}(\mathbf{x}_j)$



• b. 通过关注内存中支持集样本的表示来计算快速权重$\mathbf{R}$。注意力函数可以自行选择。这里MetaNet使用余弦相似度：  

• c. 更新训练损失：$\mathcal{L}_\text{train} \leftarrow \mathcal{L}_\text{train} + \mathcal{L}^\text{task}(g_{\phi, \phi^+}(\mathbf{x}_i), y_i)$

5\. 
更新所有参数 $(\theta, \phi, w, v)$ 使用 $\mathcal{L}_\text{train}$。


英文原文：

1\. 
Sample a random pair of inputs at each time step t from the support set $S$, $(\mathbf{x}’_i, y’_i)$ and $(\mathbf{x}’_j, y_j)$. Let $\mathbf{x}_{(t,1)}=\mathbf{x}’_i$ and $\mathbf{x}_{(t,2)}=\mathbf{x}’_j$.  

for $t = 1, \dots, K$:



• a. Compute a loss for representation learning; i.e., cross entropy for the verification task:  



$\mathcal{L}^\text{emb}_t = \mathbf{1}_{y’_i=y’_j} \log P_t + (1 - \mathbf{1}_{y’_i=y’_j})\log(1 - P_t)\text{, where }P_t = \sigma(\mathbf{W}\vert f_\theta(\mathbf{x}_{(t,1)}) - f_\theta(\mathbf{x}_{(t,2)})\vert)$

2\. 
Compute the task-level fast weights:
$\theta^+ = F_w(\nabla_\theta \mathcal{L}^\text{emb}_1, \dots, \mathcal{L}^\text{emb}_T)$


3\. 
Next go through examples in the support set $S$ and compute the example-level fast weights. Meanwhile, update the memory with learned representations.  

for $i=1, \dots, K$:



• a. The base learner outputs a probability distribution: $P(\hat{y}_i \vert \mathbf{x}_i) = g_\phi(\mathbf{x}_i)$ and the loss can be cross-entropy or MSE: $\mathcal{L}^\text{task}_i = y’_i \log g_\phi(\mathbf{x}’_i) + (1- y’_i) \log (1 - g_\phi(\mathbf{x}’_i))$



• b. Extract meta information (loss gradients) of the task and compute the example-level fast weights:

$\phi_i^+ = G_v(\nabla_\phi\mathcal{L}^\text{task}_i)$







• Then store $\phi^+_i$ into $i$ -th location of the “value” memory $\mathbf{M}$.  



• d. Encode the support sample into a task-specific input representation using both slow and fast weights: $r’_i = f_{\theta, \theta^+}(\mathbf{x}’_i)$







• Then store $r’_i$ into $i$ -th location of the “key” memory $\mathbf{R}$.

4\. 
Finally it is the time to construct the training loss using the test set $U=\{\mathbf{x}_i, y_i\}_{i=1}^L$.  

Starts with $\mathcal{L}_\text{train}=0$:  

for $j=1, \dots, L$:





• a. Encode the test sample into a task-specific input representation:

$r_j = f_{\theta, \theta^+}(\mathbf{x}_j)$



• b. The fast weights are computed by attending to representations of support set samples in memory $\mathbf{R}$. The attention function is of your choice. Here MetaNet uses cosine similarity:  

• c. Update the training loss: $\mathcal{L}_\text{train} \leftarrow \mathcal{L}_\text{train} + \mathcal{L}^\text{task}(g_{\phi, \phi^+}(\mathbf{x}_i), y_i)$

5\. 
Update all the parameters $(\theta, \phi, w, v)$ using $\mathcal{L}_\text{train}$.


$$
\begin{aligned}
 a_j &= \text{cosine}(\mathbf{R}, r_j) = [\frac{r'_1\cdot r_j}{\|r'_1\|\cdot\|r_j\|}, \dots, \frac{r'_N\cdot r_j}{\|r'_N\|\cdot\|r_j\|}]\\
 \phi^+_j &= \text{softmax}(a_j)^\top \mathbf{M}
 \end{aligned}
$$

### 基于优化的

> Optimization-Based

深度学习模型通过梯度反向传播进行学习。然而，基于梯度的优化既不是为了处理少量训练样本而设计的，也不是为了在少量优化步骤内收敛而设计的。有没有办法调整优化算法，使模型能够很好地从少量示例中学习？这正是基于优化的元学习算法所旨在实现的目标。

> Deep learning models learn through backpropagation of gradients. However, the gradient-based optimization is neither designed to cope with a small number of training samples, nor to converge within a small number of optimization steps. Is there a way to adjust the optimization algorithm so that the model can be good at learning with a few examples? This is what optimization-based approach meta-learning algorithms intend for.

#### LSTM 元学习器

> LSTM Meta-Learner

优化算法可以被显式建模。[Ravi & Larochelle (2017)](https://openreview.net/pdf?id=rJY0-Kcll) 这样做了，并将其命名为“元学习器”，而用于处理任务的原始模型则称为“学习器”。元学习器的目标是使用少量支持集高效更新学习器的参数，以便学习器能够快速适应新任务。

> The optimization algorithm can be explicitly modeled. [Ravi & Larochelle (2017)](https://openreview.net/pdf?id=rJY0-Kcll) did so and named it “meta-learner”, while the original model for handling the task is called “learner”. The goal of the meta-learner is to efficiently update the learner’s parameters using a small support set so that the learner can adapt to the new task quickly.

让我们将学习器模型表示为 $M_\theta$，其参数为 $\theta$；将元学习器表示为 $R_\Theta$，其参数为 $\Theta$；以及损失函数 $\mathcal{L}$。

> Let’s denote the learner model as $M_\theta$ parameterized by $\theta$, the meta-learner as $R_\Theta$ with parameters $\Theta$, and the loss function $\mathcal{L}$.

##### 为什么选择 LSTM？

> Why LSTM?

元学习器被建模为 LSTM，因为：

> The meta-learner is modeled as a LSTM, because:

1. 反向传播中基于梯度的更新与 LSTM 中的单元状态更新之间存在相似性。
2. 了解梯度的历史有助于梯度更新；想想[动量](http://ruder.io/optimizing-gradient-descent/index.html#momentum)是如何工作的。

> • There is similarity between the gradient-based update in backpropagation and the cell-state update in LSTM.
> • Knowing a history of gradients benefits the gradient update; think about how [momentum](http://ruder.io/optimizing-gradient-descent/index.html#momentum) works.

学习器参数在时间步 t 处以学习率 $\alpha_t$ 进行的更新为：

> The update for the learner’s parameters at time step t with a learning rate $\alpha_t$ is:

$$
\theta_t = \theta_{t-1} - \alpha_t \nabla_{\theta_{t-1}}\mathcal{L}_t
$$

它与 LSTM 中的单元状态更新形式相同，如果我们设置遗忘门 $f_t=1$、输入门 $i_t = \alpha_t$、单元状态 $c_t = \theta_t$ 和新单元状态 $\tilde{c}_t = -\nabla_{\theta_{t-1}}\mathcal{L}_t$：

> It has the same form as the cell state update in LSTM, if we set forget gate $f_t=1$, input gate $i_t = \alpha_t$, cell state $c_t = \theta_t$, and new cell state $\tilde{c}_t = -\nabla_{\theta_{t-1}}\mathcal{L}_t$:

$$
\begin{aligned}
c_t &= f_t \odot c_{t-1} + i_t \odot \tilde{c}_t\\
    &= \theta_{t-1} - \alpha_t\nabla_{\theta_{t-1}}\mathcal{L}_t
\end{aligned}
$$

虽然固定 $f_t=1$ 和 $i_t=\alpha_t$ 可能不是最优的，但它们都可以是可学习的，并且可以适应不同的数据集。

> While fixing $f_t=1$ and $i_t=\alpha_t$ might not be the optimal, both of them can be learnable and adaptable to different datasets.

$$
\begin{aligned}
f_t &= \sigma(\mathbf{W}_f \cdot [\nabla_{\theta_{t-1}}\mathcal{L}_t, \mathcal{L}_t, \theta_{t-1}, f_{t-1}] + \mathbf{b}_f) & \scriptstyle{\text{; how much to forget the old value of parameters.}}\\
i_t &= \sigma(\mathbf{W}_i \cdot [\nabla_{\theta_{t-1}}\mathcal{L}_t, \mathcal{L}_t, \theta_{t-1}, i_{t-1}] + \mathbf{b}_i) & \scriptstyle{\text{; corresponding to the learning rate at time step t.}}\\
\tilde{\theta}_t &= -\nabla_{\theta_{t-1}}\mathcal{L}_t &\\
\theta_t &= f_t \odot \theta_{t-1} + i_t \odot \tilde{\theta}_t &\\
\end{aligned}
$$

##### 模型设置

> Model Setup

![How the learner $M\_\theta$ and the meta-learner $R\_\Theta$ are trained. (Image source: original paper with more annotations)](https://lilianweng.github.io/posts/2018-11-30-meta-learning/lstm-meta-learner.png)

训练过程模拟了测试期间发生的情况，因为它已被证明在 [匹配网络](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#matching-networks) 中是有益的。在每个训练周期中，我们首先采样一个数据集 $\mathcal{D} = (\mathcal{D}_\text{train}, \mathcal{D}_\text{test}) \in \hat{\mathcal{D}}_\text{meta-train}$，然后从 $\mathcal{D}_\text{train}$ 中采样小批量数据，以更新 $\theta$ 共 $T$ 轮。学习器参数 $\theta_T$ 的最终状态用于在测试数据 $\mathcal{D}_\text{test}$ 上训练元学习器。

> The training process mimics what happens during test, since it has been proved to be beneficial in [Matching Networks](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#matching-networks). During each training epoch, we first sample a dataset $\mathcal{D} = (\mathcal{D}_\text{train}, \mathcal{D}_\text{test}) \in \hat{\mathcal{D}}_\text{meta-train}$ and then sample mini-batches out of $\mathcal{D}_\text{train}$ to update $\theta$ for $T$ rounds. The final state of the learner parameter $\theta_T$ is used to train the meta-learner on the test data $\mathcal{D}_\text{test}$.

需要特别注意的两个实现细节：

> Two implementation details to pay extra attention to:

1\. 如何在 LSTM 元学习器中压缩参数空间？由于元学习器正在建模另一个神经网络的参数，它将有数十万个变量需要学习。遵循跨坐标共享参数的[思想](https://arxiv.org/abs/1606.04474)，

2\. 为了简化训练过程，元学习器假设损失 $\mathcal{L}_t$ 和梯度 $\nabla_{\theta_{t-1}} \mathcal{L}_t$ 是独立的。

英文原文：

1\. How to compress the parameter space in LSTM meta-learner? As the meta-learner is modeling parameters of another neural network, it would have hundreds of thousands of variables to learn. Following the [idea](https://arxiv.org/abs/1606.04474) of sharing parameters across coordinates,

2\. To simplify the training process, the meta-learner assumes that the loss $\mathcal{L}_t$ and the gradient $\nabla_{\theta_{t-1}} \mathcal{L}_t$ are independent.

![Diagram of MAML. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/train-meta-learner.png)

#### MAML

> MAML

**MAML**，是 **Model-Agnostic Meta-Learning**（[Finn 等人，2017](https://arxiv.org/abs/1703.03400)）的缩写，是一种相当通用的优化算法，与任何通过梯度下降学习的模型兼容。

> **MAML**, short for **Model-Agnostic Meta-Learning** ([Finn, et al. 2017](https://arxiv.org/abs/1703.03400)) is a fairly general optimization algorithm, compatible with any model that learns through gradient descent.

假设我们的模型是 $f_\theta$，参数为 $\theta$。给定一个任务 $\tau_i$ 及其相关数据集 $(\mathcal{D}^{(i)}_\text{train}, \mathcal{D}^{(i)}_\text{test})$，我们可以通过一个或多个梯度下降步骤更新模型参数（以下示例只包含一个步骤）：

> Let’s say our model is $f_\theta$ with parameters $\theta$. Given a task $\tau_i$ and its associated dataset $(\mathcal{D}^{(i)}_\text{train}, \mathcal{D}^{(i)}_\text{test})$, we can update the model parameters by one or more gradient descent steps (the following example only contains one step):

$$
\theta'_i = \theta - \alpha \nabla_\theta\mathcal{L}^{(0)}_{\tau_i}(f_\theta)
$$

其中 $\mathcal{L}^{(0)}$ 是使用 ID 为 (0) 的小批量数据计算的损失。

> where $\mathcal{L}^{(0)}$ is the loss computed using the mini data batch with id (0).

![Diagram of MAML. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/maml.png)

然而，上述公式只针对一个任务进行优化。为了在各种任务中实现良好的泛化，我们希望找到最优的 $\theta^{\ast}$，以便任务特定的微调更高效。现在，我们采样一个 ID 为 (1) 的新数据批次来更新元目标。损失，表示为 $\mathcal{L}^{(1)}$，取决于小批量数据 (1)。$\mathcal{L}^{(0)}$ 和 $\mathcal{L}^{(1)}$ 中的上标仅表示不同的数据批次，它们指的是同一任务的相同损失目标。

> Well, the above formula only optimizes for one task. To achieve a good generalization across a variety of tasks, we would like to find the optimal $\theta^{\ast}$ so that the task-specific fine-tuning is more efficient. Now, we sample a new data batch with id (1) for updating the meta-objective. The loss, denoted as $\mathcal{L}^{(1)}$, depends on the mini batch (1). The superscripts in $\mathcal{L}^{(0)}$ and $\mathcal{L}^{(1)}$ only indicate different data batches, and they refer to the same loss objective for the same task.

$$
\begin{aligned}
\theta^* 
&= \arg\min_\theta \sum_{\tau_i \sim p(\tau)} \mathcal{L}_{\tau_i}^{(1)} (f_{\theta'_i}) = \arg\min_\theta \sum_{\tau_i \sim p(\tau)} \mathcal{L}_{\tau_i}^{(1)} (f_{\theta - \alpha\nabla_\theta \mathcal{L}_{\tau_i}^{(0)}(f_\theta)}) & \\
\theta &\leftarrow \theta - \beta \nabla_{\theta} \sum_{\tau_i \sim p(\tau)} \mathcal{L}_{\tau_i}^{(1)} (f_{\theta - \alpha\nabla_\theta \mathcal{L}_{\tau_i}^{(0)}(f_\theta)}) & \scriptstyle{\text{; updating rule}}
\end{aligned}
$$

![The general form of MAML algorithm. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/maml-algo.png)

##### 一阶 MAML

> First-Order MAML

上述元优化步骤依赖于二阶导数。为了降低计算成本，MAML 的一个修改版本省略了二阶导数，从而产生了一个简化且成本更低的实现，称为 **一阶 MAML (FOMAML)**。

> The meta-optimization step above relies on second derivatives. To make the computation less expensive, a modified version of MAML omits second derivatives, resulting in a simplified and cheaper implementation, known as **First-Order MAML (FOMAML)**.

让我们考虑执行 $k$ 个内部梯度步骤 $k\geq1$ 的情况。从初始模型参数 $\theta_\text{meta}$ 开始：

> Let’s consider the case of performing $k$ inner gradient steps, $k\geq1$. Starting with the initial model parameter $\theta_\text{meta}$:

$$
\begin{aligned}
\theta_0 &= \theta_\text{meta}\\
\theta_1 &= \theta_0 - \alpha\nabla_\theta\mathcal{L}^{(0)}(\theta_0)\\
\theta_2 &= \theta_1 - \alpha\nabla_\theta\mathcal{L}^{(0)}(\theta_1)\\
&\dots\\
\theta_k &= \theta_{k-1} - \alpha\nabla_\theta\mathcal{L}^{(0)}(\theta_{k-1})
\end{aligned}
$$

然后在外循环中，我们采样一个新的数据批次来更新元目标。

> Then in the outer loop, we sample a new data batch for updating the meta-objective.

$$
\begin{aligned}
\theta_\text{meta} &\leftarrow \theta_\text{meta} - \beta g_\text{MAML} & \scriptstyle{\text{; update for meta-objective}} \\[2mm]
\text{where } g_\text{MAML}
&= \nabla_{\theta} \mathcal{L}^{(1)}(\theta_k) &\\[2mm]
&= \nabla_{\theta_k} \mathcal{L}^{(1)}(\theta_k) \cdot (\nabla_{\theta_{k-1}} \theta_k) \dots (\nabla_{\theta_0} \theta_1) \cdot (\nabla_{\theta} \theta_0) & \scriptstyle{\text{; following the chain rule}} \\
&= \nabla_{\theta_k} \mathcal{L}^{(1)}(\theta_k) \cdot \Big( \prod_{i=1}^k \nabla_{\theta_{i-1}} \theta_i \Big) \cdot I &  \\
&= \nabla_{\theta_k} \mathcal{L}^{(1)}(\theta_k) \cdot \prod_{i=1}^k \nabla_{\theta_{i-1}} (\theta_{i-1} - \alpha\nabla_\theta\mathcal{L}^{(0)}(\theta_{i-1})) &  \\
&= \nabla_{\theta_k} \mathcal{L}^{(1)}(\theta_k) \cdot \prod_{i=1}^k (I - \alpha\nabla_{\theta_{i-1}}(\nabla_\theta\mathcal{L}^{(0)}(\theta_{i-1}))) &
\end{aligned}
$$

MAML 梯度为：

> The MAML gradient is:

$$
g_\text{MAML} = \nabla_{\theta_k} \mathcal{L}^{(1)}(\theta_k) \cdot \prod_{i=1}^k (I - \alpha \color{red}{\nabla_{\theta_{i-1}}(\nabla_\theta\mathcal{L}^{(0)}(\theta_{i-1}))})
$$

一阶 MAML 忽略了红色部分的二阶导数。它简化如下，等同于最后一个内部梯度更新结果的导数。

> The First-Order MAML ignores the second derivative part in red. It is simplified as follows, equivalent to the derivative of the last inner gradient update result.

$$
g_\text{FOMAML} = \nabla_{\theta_k} \mathcal{L}^{(1)}(\theta_k)
$$

#### Reptile

> Reptile

**Reptile**（[Nichol, Achiam & Schulman, 2018](https://arxiv.org/abs/1803.02999)）是一种非常简单的元学习优化算法。它在许多方面与 MAML 相似，因为两者都依赖于通过梯度下降进行的元优化，并且两者都是模型无关的。

> **Reptile** ([Nichol, Achiam & Schulman, 2018](https://arxiv.org/abs/1803.02999)) is a remarkably simple meta-learning optimization algorithm. It is similar to MAML in many ways, given that both rely on meta-optimization through gradient descent and both are model-agnostic.

Reptile 通过重复以下步骤工作：

> The Reptile works by repeatedly:

1. 采样一个任务，
2. 通过多个梯度下降步骤对其进行训练，
3. 然后将模型权重移向新参数。

> • sampling a task,
> • training on it by multiple gradient descent steps,
> • and then moving the model weights towards the new parameters.

参见以下算法：$\text{SGD}(\mathcal{L}_{\tau_i}, \theta, k)$ 对损失 $\mathcal{L}_{\tau_i}$ 执行 k 步随机梯度更新，从初始参数 $\theta$ 开始，并返回最终参数向量。批处理版本在每次迭代中采样多个任务而不是一个。Reptile 梯度定义为 $(\theta - W)/\alpha$，其中 $\alpha$ 是 SGD 操作使用的步长。

> See the algorithm below:
> $\text{SGD}(\mathcal{L}_{\tau_i}, \theta, k)$ performs stochastic gradient update for k steps on the loss $\mathcal{L}_{\tau_i}$ starting with initial parameter $\theta$ and returns the final parameter vector. The batch version samples multiple tasks instead of one within each iteration. The reptile gradient is defined as $(\theta - W)/\alpha$, where $\alpha$ is the stepsize used by the SGD operation.

![The batched version of Reptile algorithm. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/reptile-algo.png)

乍一看，该算法与普通的 SGD 非常相似。然而，由于特定任务的优化可能需要不止一步，当 k > 1 时，它最终会使 $\text{SGD}(\mathbb{E} _\tau[\mathcal{L}_{\tau}], \theta, k)$ 偏离 $\mathbb{E}_\tau [\text{SGD}(\mathcal{L}_{\tau}, \theta, k)]$。

> At a glance, the algorithm looks a lot like an ordinary SGD. However, because the task-specific optimization can take more than one step. it eventually makes $\text{SGD}(\mathbb{E} _\tau[\mathcal{L}_{\tau}], \theta, k)$ diverge from $\mathbb{E}_\tau [\text{SGD}(\mathcal{L}_{\tau}, \theta, k)]$ when k > 1.

##### 优化假设

> The Optimization Assumption

假设一个任务 $\tau \sim p(\tau)$ 具有最优网络配置的流形，$\mathcal{W}_{\tau}^{\ast}$。模型 $f_\theta$ 在任务 $\tau$ 上实现了最佳性能，当 $\theta$ 位于 $\mathcal{W}_{\tau}^{\ast}$ 的表面时。为了找到一个在所有任务中都表现良好的解决方案，我们希望找到一个接近所有任务最优流形的参数：

> Assuming that a task $\tau \sim p(\tau)$ has a manifold of optimal network configuration, $\mathcal{W}_{\tau}^{\ast}$. The model $f_\theta$ achieves the best performance for task $\tau$ when $\theta$ lays on the surface of $\mathcal{W}_{\tau}^{\ast}$. To find a solution that is good across tasks, we would like to find a parameter close to all the optimal manifolds of all tasks:

$$
\theta^* = \arg\min_\theta \mathbb{E}_{\tau \sim p(\tau)} [\frac{1}{2} \text{dist}(\theta, \mathcal{W}_\tau^*)^2]
$$

![The Reptile algorithm updates the parameter alternatively to be closer to the optimal manifolds of different tasks. (Image source: original paper )](https://lilianweng.github.io/posts/2018-11-30-meta-learning/reptile-optim.png)

我们使用L2距离作为$\text{dist}(.)$，一个点$\theta$和一个集合$\mathcal{W}_\tau^{\ast}$之间的距离等于$\theta$和一个点$W_{\tau}^{\ast}(\theta)$在流形上，它最接近$\theta$：

> Let’s use the L2 distance as $\text{dist}(.)$ and the distance between a point $\theta$ and a set $\mathcal{W}_\tau^{\ast}$ equals to the distance between $\theta$ and a point $W_{\tau}^{\ast}(\theta)$ on the manifold that is closest to $\theta$:

$$
\text{dist}(\theta, \mathcal{W}_{\tau}^*) = \text{dist}(\theta, W_{\tau}^*(\theta)) \text{, where }W_{\tau}^*(\theta) = \arg\min_{W\in\mathcal{W}_{\tau}^*} \text{dist}(\theta, W)
$$

平方欧几里得距离的梯度为：

> The gradient of the squared euclidean distance is:

$$
\begin{aligned}
\nabla_\theta[\frac{1}{2}\text{dist}(\theta, \mathcal{W}_{\tau_i}^*)^2]
&= \nabla_\theta[\frac{1}{2}\text{dist}(\theta, W_{\tau_i}^*(\theta))^2] & \\
&= \nabla_\theta[\frac{1}{2}(\theta - W_{\tau_i}^*(\theta))^2] & \\
&= \theta - W_{\tau_i}^*(\theta) & \scriptstyle{\text{; See notes.}}
\end{aligned}
$$

注：根据 Reptile 论文，*“点 $\Theta$ 与集合 $S$ 之间平方欧几里得距离的梯度是向量 $2(\Theta − p)$，其中 p 是 $S$ 中距离 $\Theta$ 最近的点”*。从技术上讲，$S$ 中最近的点也是 $\Theta$ 的函数，但我不知道为什么梯度不需要考虑 $p$ 的导数。（如果您有任何想法，请随时给我留言或发送电子邮件。）

> Notes: According to the Reptile paper, *“the gradient of the squared euclidean distance between a point $\Theta$ and a set $S$ is the vector $2(\Theta − p)$, where p is the closest point in $S$ to $\Theta$”*. Technically the closest point in $S$ is also a function of $\Theta$, but I’m not sure why the gradient does not need to worry about the derivative of $p$. (Please feel free to leave me a comment or send me an email about this if you have ideas.)

因此，一个随机梯度步的更新规则是：

> Thus the update rule for one stochastic gradient step is:

$$
\theta = \theta - \alpha \nabla_\theta[\frac{1}{2} \text{dist}(\theta, \mathcal{W}_{\tau_i}^*)^2] = \theta - \alpha(\theta - W_{\tau_i}^*(\theta)) = (1-\alpha)\theta + \alpha W_{\tau_i}^*(\theta)
$$

最优任务流形 $W_{\tau_i}^{\ast}(\theta)$ 上的最近点无法精确计算，但 Reptile 使用 $\text{SGD}(\mathcal{L}_\tau, \theta, k)$ 对其进行近似。

> The closest point on the optimal task manifold $W_{\tau_i}^{\ast}(\theta)$ cannot be computed exactly, but Reptile approximates it using $\text{SGD}(\mathcal{L}_\tau, \theta, k)$.

##### Reptile 与 FOMAML

> Reptile vs FOMAML

为了展示 Reptile 和 MAML 之间更深层次的联系，让我们通过一个执行两个梯度步（$\text{SGD}(.)$ 中 k=2）的例子来展开更新公式。与 [上面](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#maml) 定义的相同，$\mathcal{L}^{(0)}$ 和 $\mathcal{L}^{(1)}$ 是使用不同数据小批量计算的损失。为了便于阅读，我们采用两种简化标注：$g^{(i)}_j = \nabla_{\theta} \mathcal{L}^{(i)}(\theta_j)$ 和 $H^{(i)}_j = \nabla^2_{\theta} \mathcal{L}^{(i)}(\theta_j)$。

> To demonstrate the deeper connection between Reptile and MAML, let’s expand the update formula with an example performing two gradient steps, k=2 in $\text{SGD}(.)$. Same as defined [above](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#maml), $\mathcal{L}^{(0)}$ and $\mathcal{L}^{(1)}$ are losses using different mini-batches of data. For ease of reading, we adopt two simplified annotations: $g^{(i)}_j = \nabla_{\theta} \mathcal{L}^{(i)}(\theta_j)$ and $H^{(i)}_j = \nabla^2_{\theta} \mathcal{L}^{(i)}(\theta_j)$.

$$
\begin{aligned}
\theta_0 &= \theta_\text{meta}\\
\theta_1 &= \theta_0 - \alpha\nabla_\theta\mathcal{L}^{(0)}(\theta_0)= \theta_0 - \alpha g^{(0)}_0 \\
\theta_2 &= \theta_1 - \alpha\nabla_\theta\mathcal{L}^{(1)}(\theta_1) = \theta_0 - \alpha g^{(0)}_0 - \alpha g^{(1)}_1
\end{aligned}
$$

根据[早期章节](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#first-order-maml)，FOMAML 的梯度是最后一次内部梯度更新结果。因此，当 k=1 时：

> According to the [early section](https://lilianweng.github.io/posts/2018-11-30-meta-learning/#first-order-maml), the gradient of FOMAML is the last inner gradient update result. Therefore, when k=1:

$$
\begin{aligned}
g_\text{FOMAML} &= \nabla_{\theta_1} \mathcal{L}^{(1)}(\theta_1) = g^{(1)}_1 \\
g_\text{MAML} &= \nabla_{\theta_1} \mathcal{L}^{(1)}(\theta_1) \cdot (I - \alpha\nabla^2_{\theta} \mathcal{L}^{(0)}(\theta_0)) = g^{(1)}_1 - \alpha H^{(0)}_0 g^{(1)}_1
\end{aligned}
$$

Reptile 梯度定义为：

> The Reptile gradient is defined as:

$$
g_\text{Reptile} = (\theta_0 - \theta_2) / \alpha = g^{(0)}_0 + g^{(1)}_1
$$

到目前为止，我们有：

> Up to now we have:

![Reptile versus FOMAML in one loop of meta-optimization. (Image source: slides on Reptile by Yoonho Lee.)](https://lilianweng.github.io/posts/2018-11-30-meta-learning/reptile_vs_FOMAML.png)

$$
\begin{aligned}
g_\text{FOMAML} &= g^{(1)}_1 \\
g_\text{MAML} &= g^{(1)}_1 - \alpha H^{(0)}_0 g^{(1)}_1 \\
g_\text{Reptile} &= g^{(0)}_0 + g^{(1)}_1
\end{aligned}
$$

接下来我们尝试进一步展开 $g^{(1)}_1$ 使用 [泰勒展开](https://en.wikipedia.org/wiki/Taylor_series)。回想一下，函数 $f(x)$ 在数字 $a$ 处可微的泰勒展开式为：

> Next let’s try further expand $g^{(1)}_1$ using [Taylor expansion](https://en.wikipedia.org/wiki/Taylor_series). Recall that Taylor expansion of a function $f(x)$ that is differentiable at a number $a$ is:

$$
f(x) = f(a) + \frac{f'(a)}{1!}(x-a) + \frac{f''(a)}{2!}(x-a)^2 + \dots = \sum_{i=0}^\infty \frac{f^{(i)}(a)}{i!}(x-a)^i
$$

我们可以将$\nabla_{\theta}\mathcal{L}^{(1)}(.)$视为一个函数，将$\theta_0$视为一个值点。$g_1^{(1)}$在值点$\theta_0$处的泰勒展开式为：

> We can consider $\nabla_{\theta}\mathcal{L}^{(1)}(.)$ as a function and $\theta_0$ as a value point. The Taylor expansion of $g_1^{(1)}$ at the value point $\theta_0$ is:

$$
\begin{aligned}
g_1^{(1)} &= \nabla_{\theta}\mathcal{L}^{(1)}(\theta_1) \\
&= \nabla_{\theta}\mathcal{L}^{(1)}(\theta_0) + \nabla^2_\theta\mathcal{L}^{(1)}(\theta_0)(\theta_1 - \theta_0) + \frac{1}{2}\nabla^3_\theta\mathcal{L}^{(1)}(\theta_0)(\theta_1 - \theta_0)^2 + \dots & \\
&= g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + \frac{\alpha^2}{2}\nabla^3_\theta\mathcal{L}^{(1)}(\theta_0) (g_0^{(0)})^2 + \dots & \scriptstyle{\text{; because }\theta_1-\theta_0=-\alpha g_0^{(0)}} \\
&= g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + O(\alpha^2)
\end{aligned}
$$

将$g_1^{(1)}$的展开形式代入到具有一步内部梯度更新的 MAML 梯度中：

> Plug in the expanded form of $g_1^{(1)}$ into the MAML gradients with one step inner gradient update:

$$
\begin{aligned}
g_\text{FOMAML} &= g^{(1)}_1 = g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + O(\alpha^2)\\
g_\text{MAML} &= g^{(1)}_1 - \alpha H^{(0)}_0 g^{(1)}_1 \\
&= g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + O(\alpha^2) - \alpha H^{(0)}_0 (g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + O(\alpha^2))\\
&= g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} - \alpha H^{(0)}_0 g_0^{(1)} + \alpha^2 \alpha H^{(0)}_0 H^{(1)}_0 g_0^{(0)} + O(\alpha^2)\\
&= g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} - \alpha H^{(0)}_0 g_0^{(1)} + O(\alpha^2)
\end{aligned}
$$

Reptile 梯度变为：

> The Reptile gradient becomes:

$$
\begin{aligned}
g_\text{Reptile} 
&= g^{(0)}_0 + g^{(1)}_1 \\
&= g^{(0)}_0 + g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + O(\alpha^2)
\end{aligned}
$$

至此，我们得到了三种梯度的公式：

> So far we have the formula of three types of gradients:

$$
\begin{aligned}
g_\text{FOMAML} &= g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + O(\alpha^2)\\
g_\text{MAML} &= g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} - \alpha H^{(0)}_0 g_0^{(1)} + O(\alpha^2)\\
g_\text{Reptile}  &= g^{(0)}_0 + g_0^{(1)} - \alpha H^{(1)}_0 g_0^{(0)} + O(\alpha^2)
\end{aligned}
$$

在训练过程中，我们经常对多个数据批次进行平均。在我们的例子中，小批次 (0) 和 (1) 是可互换的，因为它们都是随机抽取的。期望值 $\mathbb{E}_{\tau,0,1}$ 是对任务 $\tau$ 的两个数据批次，id (0) 和 (1)，进行平均的。

> During training, we often average over multiple data batches. In our example, the mini batches (0) and (1) are interchangeable since both are drawn at random. The expectation $\mathbb{E}_{\tau,0,1}$ is averaged over two data batches, ids (0) and (1), for task $\tau$.

令，

> Let,

• $A = \mathbb{E}_{\tau,0,1} [g_0^{(0)}] = \mathbb{E}_{\tau,0,1} [g_0^{(1)}]$；它是任务损失的平均梯度。我们期望通过遵循 $A$ 指示的方向来改进模型参数，以实现更好的任务性能。

• $B = \mathbb{E}_{\tau,0,1} [H^{(1)}_0 g_0^{(0)}] = \frac{1}{2}\mathbb{E}_{\tau,0,1} [H^{(1)}_0 g_0^{(0)} + H^{(0)}_0 g_0^{(1)}] = \frac{1}{2}\mathbb{E}_{\tau,0,1} [\nabla_\theta(g^{(0)}_0 g_0^{(1)})]$；它是增加同一任务的两个不同小批次梯度内积的方向（梯度）。我们期望通过遵循 $B$ 指示的方向来改进模型参数，以实现对不同数据的更好泛化。

英文原文：

• $A = \mathbb{E}_{\tau,0,1} [g_0^{(0)}] = \mathbb{E}_{\tau,0,1} [g_0^{(1)}]$; it is the average gradient of task loss. We expect to improve the model parameter to achieve better task performance by following this direction pointed by $A$.

• $B = \mathbb{E}_{\tau,0,1} [H^{(1)}_0 g_0^{(0)}] = \frac{1}{2}\mathbb{E}_{\tau,0,1} [H^{(1)}_0 g_0^{(0)} + H^{(0)}_0 g_0^{(1)}] = \frac{1}{2}\mathbb{E}_{\tau,0,1} [\nabla_\theta(g^{(0)}_0 g_0^{(1)})]$; it is the direction (gradient) that increases the inner product of gradients of two different mini batches for the same task. We expect to improve the model parameter to achieve better generalization over different data by following this direction pointed by $B$.

总而言之，当梯度更新由前三个主导项近似时，MAML 和 Reptile 都旨在优化相同的目标：更好的任务性能（由 A 指导）和更好的泛化能力（由 B 指导）。

> To conclude, both MAML and Reptile aim to optimize for the same goal, better task performance (guided by A) and better generalization (guided by B), when the gradient update is approximated by first three leading terms.

$$
\begin{aligned}
\mathbb{E}_{\tau,1,2}[g_\text{FOMAML}] &= A - \alpha B + O(\alpha^2)\\
\mathbb{E}_{\tau,1,2}[g_\text{MAML}] &= A - 2\alpha B + O(\alpha^2)\\
\mathbb{E}_{\tau,1,2}[g_\text{Reptile}]  &= 2A - \alpha B + O(\alpha^2)
\end{aligned}
$$

我不太清楚被忽略的项 $O(\alpha^2)$ 是否会对参数学习产生重大影响。但考虑到 FOMAML 能够获得与 MAML 完整版相似的性能，可以肯定地说，在梯度下降更新过程中，高阶导数不会是关键。

> It is not clear to me whether the ignored term $O(\alpha^2)$ might play a big impact on the parameter learning. But given that FOMAML is able to obtain a similar performance as the full version of MAML, it might be safe to say higher-level derivatives would not be critical during gradient descent update.

引用来源：

> Cited as:

```
@article{weng2018metalearning,
  title   = "Meta-Learning: Learning to Learn Fast",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-11-30-meta-learning/"
}
```

### 参考文献

> Reference

[1] Brenden M. Lake, Ruslan Salakhutdinov, and Joshua B. Tenenbaum. [“通过概率程序归纳实现人类水平的概念学习。”](https://www.cs.cmu.edu/~rsalakhu/papers/LakeEtAl2015Science.pdf) Science 350.6266 (2015): 1332-1338。

> [1] Brenden M. Lake, Ruslan Salakhutdinov, and Joshua B. Tenenbaum. [“Human-level concept learning through probabilistic program induction.”](https://www.cs.cmu.edu/~rsalakhu/papers/LakeEtAl2015Science.pdf) Science 350.6266 (2015): 1332-1338.

[2] Oriol Vinyals 关于 [“模型与优化元学习”](http://metalearning-symposium.ml/files/vinyals.pdf) 的演讲

> [2] Oriol Vinyals’ talk on [“Model vs Optimization Meta Learning”](http://metalearning-symposium.ml/files/vinyals.pdf)

[3] Gregory Koch, Richard Zemel, and Ruslan Salakhutdinov. [“用于一次性图像识别的孪生神经网络。”](http://www.cs.toronto.edu/~rsalakhu/papers/oneshot1.pdf) ICML Deep Learning Workshop. 2015。

> [3] Gregory Koch, Richard Zemel, and Ruslan Salakhutdinov. [“Siamese neural networks for one-shot image recognition.”](http://www.cs.toronto.edu/~rsalakhu/papers/oneshot1.pdf) ICML Deep Learning Workshop. 2015.

[4] Oriol Vinyals, et al. [“用于一次性学习的匹配网络。”](http://papers.nips.cc/paper/6385-matching-networks-for-one-shot-learning.pdf) NIPS. 2016。

> [4] Oriol Vinyals, et al. [“Matching networks for one shot learning.”](http://papers.nips.cc/paper/6385-matching-networks-for-one-shot-learning.pdf) NIPS. 2016.

[5] Flood Sung, et al. [“学习比较：用于少样本学习的关系网络。”](http://openaccess.thecvf.com/content_cvpr_2018/papers_backup/Sung_Learning_to_Compare_CVPR_2018_paper.pdf) CVPR. 2018。

> [5] Flood Sung, et al. [“Learning to compare: Relation network for few-shot learning.”](http://openaccess.thecvf.com/content_cvpr_2018/papers_backup/Sung_Learning_to_Compare_CVPR_2018_paper.pdf) CVPR. 2018.

[6] Jake Snell, Kevin Swersky, and Richard Zemel. [“用于少样本学习的原型网络。”](http://papers.nips.cc/paper/6996-prototypical-networks-for-few-shot-learning.pdf) CVPR. 2018。

> [6] Jake Snell, Kevin Swersky, and Richard Zemel. [“Prototypical Networks for Few-shot Learning.”](http://papers.nips.cc/paper/6996-prototypical-networks-for-few-shot-learning.pdf) CVPR. 2018.

[7] Adam Santoro, et al. [“使用记忆增强神经网络进行元学习。”](http://proceedings.mlr.press/v48/santoro16.pdf) ICML. 2016。

> [7] Adam Santoro, et al. [“Meta-learning with memory-augmented neural networks.”](http://proceedings.mlr.press/v48/santoro16.pdf) ICML. 2016.

[8] Alex Graves, Greg Wayne, and Ivo Danihelka. [“神经图灵机。”](https://arxiv.org/abs/1410.5401) arXiv preprint arXiv:1410.5401 (2014)。

> [8] Alex Graves, Greg Wayne, and Ivo Danihelka. [“Neural turing machines.”](https://arxiv.org/abs/1410.5401) arXiv preprint arXiv:1410.5401 (2014).

[9] Tsendsuren Munkhdalai and Hong Yu. [“元网络。”](https://arxiv.org/abs/1703.00837) ICML. 2017。

> [9] Tsendsuren Munkhdalai and Hong Yu. [“Meta Networks.”](https://arxiv.org/abs/1703.00837) ICML. 2017.

[10] Sachin Ravi and Hugo Larochelle. [“将优化作为少样本学习的模型。”](https://openreview.net/pdf?id=rJY0-Kcll) ICLR. 2017。

> [10] Sachin Ravi and Hugo Larochelle. [“Optimization as a Model for Few-Shot Learning.”](https://openreview.net/pdf?id=rJY0-Kcll) ICLR. 2017.

[11] Chelsea Finn 在 BAIR 博客上关于 [“学会学习”](https://bair.berkeley.edu/blog/2017/07/18/learning-to-learn/) 的文章。

> [11] Chelsea Finn’s BAIR blog on [“Learning to Learn”](https://bair.berkeley.edu/blog/2017/07/18/learning-to-learn/).

[12] Chelsea Finn, Pieter Abbeel, and Sergey Levine. [“用于深度网络快速适应的模型无关元学习。”](https://arxiv.org/abs/1703.03400) ICML 2017。

> [12] Chelsea Finn, Pieter Abbeel, and Sergey Levine. [“Model-agnostic meta-learning for fast adaptation of deep networks.”](https://arxiv.org/abs/1703.03400) ICML 2017.

[13] Alex Nichol, Joshua Achiam, John Schulman. [“关于一阶元学习算法。”](https://arxiv.org/abs/1803.02999) arXiv preprint arXiv:1803.02999 (2018)。

> [13] Alex Nichol, Joshua Achiam, John Schulman. [“On First-Order Meta-Learning Algorithms.”](https://arxiv.org/abs/1803.02999) arXiv preprint arXiv:1803.02999 (2018).

[14] Yoonho Lee 的 [Reptile 幻灯片](https://www.slideshare.net/YoonhoLee4/on-firstorder-metalearning-algorithms)。

> [14] [Slides on Reptile](https://www.slideshare.net/YoonhoLee4/on-firstorder-metalearning-algorithms) by Yoonho Lee.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Meta-learning | 元学习 | 一种机器学习范式，旨在使模型学会如何学习，从而能快速适应新任务和新环境。 |
| Few-shot classification | 少样本分类 | 一种监督学习任务，模型需要仅通过少量带标签的样本来学习识别新类别。 |
| Support set | 支持集 | 在元学习中，用于模型“快速学习”或适应新任务的小型带标签数据集。 |
| Metric-based meta-learning | 基于度量的元学习 | 通过学习数据点之间的相似性度量或距离函数来进行分类或聚类的元学习方法。 |
| Siamese Neural Network | 孪生神经网络 | 一种包含两个共享相同权重的相同子网络的架构，常用于学习输入对之间的相似性。 |
| Matching Networks | 匹配网络 | 一种基于度量的元学习模型，通过注意力机制加权支持集样本的标签来对测试样本进行分类。 |
| Prototypical Networks | 原型网络 | 一种基于度量的元学习模型，通过计算每个类别的嵌入均值作为原型，并基于距离进行分类。 |
| Model-Agnostic Meta-Learning (MAML) | 模型无关元学习 | 一种通用的元学习优化算法，旨在找到一个初始模型参数，使其能通过少量梯度下降步骤快速适应任何新任务。 |
| Memory-Augmented Neural Networks (MANN) | 记忆增强神经网络 | 一种结合了外部存储器的神经网络架构，旨在提高模型快速学习和记忆新信息的能力。 |
| Optimization-based meta-learning | 基于优化的元学习 | 通过调整或学习优化算法本身，使模型能够高效地从少量数据中学习的元学习方法。 |
| Reptile | Reptile | 一种简单的元学习优化算法，通过重复任务训练和权重更新，使模型参数向任务最优流形靠近。 |
| Learner | 学习器 | 在元学习框架中，执行特定任务的底层模型。 |
| Meta-learner | 元学习器 | 在元学习框架中，学习如何更新或优化学习器模型参数的模型。 |
| Embedding function | 嵌入函数 | 将原始输入数据映射到低维特征空间中的函数，旨在捕获数据的语义信息。 |
| Fast weights | 快权重 | 通过另一个神经网络预测生成的权重，与传统的通过梯度下降缓慢更新的“慢权重”相对，旨在实现快速学习。 |
