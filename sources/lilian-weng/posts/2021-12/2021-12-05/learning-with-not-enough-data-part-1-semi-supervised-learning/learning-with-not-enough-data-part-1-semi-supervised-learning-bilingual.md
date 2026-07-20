# 数据不足下的学习 第一部分：半监督学习

> Learning with not Enough Data Part 1: Semi-Supervised Learning

> 来源：Lil'Log / Lilian Weng，2021-12-05
> 原文链接：https://lilianweng.github.io/posts/2021-12-05-semi-supervised/
> 分类：机器学习 / 半监督学习

## 核心要点

- 半监督学习利用少量标注数据和大量未标注数据来训练模型，以应对数据不足的挑战。
- 半监督学习方法通常基于平滑性、聚类、低密度分离和流形等假设来设计。
- 一致性正则化是半监督学习中的核心思想，它要求模型对同一输入的不同扰动版本产生一致的预测。
- Π模型、时间集成和平均教师模型是实现一致性正则化的主要方法，通过对模型输出或权重进行平均来稳定预测。
- 伪标签方法通过模型对未标注数据生成高置信度预测作为标签，然后将其用于进一步训练，这等同于熵正则化。
- 虚拟对抗训练、插值一致性训练和无监督数据增强等方法通过引入噪声或数据增强来生成学习目标，以提高模型鲁棒性和泛化能力。
- 自训练（特别是噪声学生模型）通过迭代地使用模型预测为未标注数据生成伪标签，并引入噪声以促使学生模型超越教师模型。
- MixMatch、ReMixMatch、DivideMix和FixMatch等集成方法结合了多种半监督学习技术，如一致性正则化、熵最小化、MixUp和数据增强，以提升性能。
- 减少确认偏差是半监督学习中的一个重要挑战，可以通过MixUp、元伪标签和数据平衡等技术来缓解。
- 半监督学习可以与强大的预训练模型相结合，通过自监督预训练、监督微调和自训练蒸馏等步骤，在数据稀缺场景下进一步提升模型性能。

## 正文

当监督学习任务面临有限的标注数据时，通常会讨论四种方法。

> When facing a limited amount of labeled data for supervised learning tasks, four approaches are commonly discussed.

1. **预训练 + 微调**：在一个大型无监督数据语料库上预训练一个强大的任务无关模型，例如在自由文本上[预训练语言模型](https://lilianweng.github.io/posts/2019-01-31-lm/)，或通过[自监督学习](https://lilianweng.github.io/posts/2019-11-10-self-supervised/)在未标注图像上预训练视觉模型，然后使用少量标注样本在下游任务上进行微调。
2. **半监督学习**：同时从标注和未标注样本中学习。在这种方法中，视觉任务已经进行了大量研究。
3. **主动学习**：标注成本高昂，但我们仍希望在给定成本预算的情况下收集更多数据。主动学习旨在选择最有价值的未标注样本进行后续收集，并帮助我们在有限预算内明智地行动。
4. **预训练 + 数据集自动生成**：给定一个有能力的预训练模型，我们可以利用它自动生成更多标注样本。由于少样本学习的成功，这在语言领域尤其受欢迎。

> • **Pre-training + fine-tuning**: Pre-train a powerful task-agnostic model on a large unsupervised data corpus, e.g. [pre-training LMs](https://lilianweng.github.io/posts/2019-01-31-lm/) on free text, or pre-training vision models on unlabelled images via [self-supervised learning](https://lilianweng.github.io/posts/2019-11-10-self-supervised/), and then fine-tune it on the downstream task with a small set of labeled samples.
> • **Semi-supervised learning**: Learn from the labelled and unlabeled samples together. A lot of research has happened on vision tasks within this approach.
> • **Active learning**: Labeling is expensive, but we still want to collect more given a cost budget. Active learning learns to select most valuable unlabeled samples to be collected next and helps us act smartly with a limited budget.
> • **Pre-training + dataset auto-generation**: Given a capable pre-trained model, we can utilize it to auto-generate a lot more labeled samples. This has been especially popular within the language domain driven by the success of few-shot learning.

我计划撰写一系列关于“数据不足下的学习”主题的帖子。第一部分是关于*半监督学习*。

> I plan to write a series of posts on the topic of “Learning with not enough data”. Part 1 is on *Semi-Supervised Learning*.

### 什么是半监督学习？

> What is semi-supervised learning?

半监督学习利用标注数据和未标注数据来训练模型。

> Semi-supervised learning uses both labeled and unlabeled data to train a model.

有趣的是，大多数关于半监督学习的现有文献都集中在视觉任务上。而预训练 + 微调反而是语言任务中更常见的范式。

> Interestingly most existing literature on semi-supervised learning focuses on vision tasks. And instead pre-training + fine-tuning is a more common paradigm for language tasks.

本文介绍的所有方法都包含两部分损失：$\mathcal{L} = \mathcal{L}_s + \mu(t) \mathcal{L}_u$。给定所有标注样本，监督损失$\mathcal{L}_s$很容易获得。我们将重点关注无监督损失$\mathcal{L}_u$是如何设计的。权重项$\mu(t)$的常见选择是一个斜坡函数，它随时间增加$\mathcal{L}_u$的重要性，其中$t$是训练步骤。

> All the methods introduced in this post have a loss combining two parts: $\mathcal{L} = \mathcal{L}_s + \mu(t) \mathcal{L}_u$. The supervised loss $\mathcal{L}_s$ is easy to get given all the labeled examples. We will focus on how the unsupervised loss $\mathcal{L}_u$ is designed. A common choice of the weighting term $\mu(t)$ is a ramp function increasing the importance of $\mathcal{L}_u$ in time, where $t$ is the training step.

> *免责声明*：本文不涉及侧重于模型架构修改的半监督方法。关于如何在半监督学习中使用生成模型和基于图的方法，请查阅[这项调查](https://arxiv.org/abs/2006.05278)。

> *Disclaimer*: The post is not gonna cover semi-supervised methods with focus on model architecture modification. Check [this survey](https://arxiv.org/abs/2006.05278) for how to use generative models and graph-based methods in semi-supervised learning.

### 符号

> Notations

| 符号 | 含义 |
| --- | --- |
| $L$ | 唯一标签的数量。 |
| $(\mathbf{x}^l, y) \sim \mathcal{X}, y \in \{0, 1\}^L$ | 标注数据集。$y$ 是真实标签的独热表示。 |
| $\mathbf{u} \sim \mathcal{U}$ | 未标注数据集。 |
| $\mathcal{D} = \mathcal{X} \cup \mathcal{U}$ | 整个数据集，包括标注和未标注样本。 |
| $\mathbf{x}$ | 可以是标注或未标注的任何样本。 |
| $\bar{\mathbf{x}}$ | 应用了数据增强的$\mathbf{x}$。 |
| $\mathbf{x}_i$ | 第 $i$ 个样本。 |
| $\mathcal{L}$、$\mathcal{L}_s$、$\mathcal{L}_u$ | 损失、监督损失和无监督损失。 |
| $\mu(t)$ | 无监督损失权重，随时间增加。 |
| $p(y \vert \mathbf{x}), p_\theta(y \vert \mathbf{x})$ | 给定输入的标签集上的条件概率。 |
| $f_\theta(.)$ | 带有权重$\theta$的已实现神经网络，即我们想要训练的模型。 |
| $\mathbf{z} = f_\theta(\mathbf{x})$ | 由 $f$ 输出的 logits 向量。 |
| $\hat{y} = \text{softmax}(\mathbf{z})$ | 预测的标签分布。 |
| $D[.,.]$ | 两个分布之间的距离函数，例如 MSE、交叉熵、KL 散度等。 |
| $\beta$ | 教师模型权重的 EMA 加权超参数。 |
| $\alpha, \lambda$ | MixUp 的参数，$\lambda \sim \text{Beta}(\alpha, \alpha)$。 |
| $T$ | 用于锐化预测分布的温度。 |
| $\tau$ | 用于选择合格预测的置信度阈值。 |

> 英文原表 / English original

| Symbol | Meaning |
| --- | --- |
| $L$ | Number of unique labels. |
| $(\mathbf{x}^l, y) \sim \mathcal{X}, y \in \{0, 1\}^L$ | Labeled dataset. $y$ is a one-hot representation of the true label. |
| $\mathbf{u} \sim \mathcal{U}$ | Unlabeled dataset. |
| $\mathcal{D} = \mathcal{X} \cup \mathcal{U}$ | The entire dataset, including both labeled and unlabeled examples. |
| $\mathbf{x}$ | Any sample which can be either labeled or unlabeled. |
| $\bar{\mathbf{x}}$ | $\mathbf{x}$ with augmentation applied. |
| $\mathbf{x}_i$ | The $i$-th sample. |
| $\mathcal{L}$, $\mathcal{L}_s$, $\mathcal{L}_u$ | Loss, supervised loss, and unsupervised loss. |
| $\mu(t)$ | The unsupervised loss weight, increasing in time. |
| $p(y \vert \mathbf{x}), p_\theta(y \vert \mathbf{x})$ | The conditional probability over the label set given the input. |
| $f_\theta(.)$ | The implemented neural network with weights $\theta$, the model that we want to train. |
| $\mathbf{z} = f_\theta(\mathbf{x})$ | A vector of logits output by $f$. |
| $\hat{y} = \text{softmax}(\mathbf{z})$ | The predicted label distribution. |
| $D[.,.]$ | A distance function between two distributions, such as MSE, cross entropy, KL divergence, etc. |
| $\beta$ | EMA weighting hyperparameter for teacher model weights. |
| $\alpha, \lambda$ | Parameters for MixUp, $\lambda \sim \text{Beta}(\alpha, \alpha)$. |
| $T$ | Temperature for sharpening the predicted distribution. |
| $\tau$ | A confidence threshold for selecting the qualified prediction. |

### 假设

> Hypotheses

文献中已经讨论了几种假设，以支持半监督学习方法中的某些设计决策。

> Several hypotheses have been discussed in literature to support certain design decisions in semi-supervised learning methods.

- 
H1: **平滑性假设**: 如果两个数据样本在特征空间的高密度区域中彼此接近，则它们的标签应该相同或非常相似。

- 
H2: **聚类假设**: 特征空间既有密集区域也有稀疏区域。密集分组的数据点自然形成一个聚类。同一聚类中的样本预期具有相同的标签。这是H1的一个小扩展。

- 
H3: **低密度分离假设**: 类别之间的决策边界倾向于位于稀疏的低密度区域，因为否则决策边界会将高密度聚类切成两个类别，对应于两个聚类，这会使H1和H2失效。

- 
H4: **流形假设**: 高维数据倾向于位于低维流形上。尽管真实世界的数据可能在非常高的维度中被观察到（例如真实世界物体/场景的图像），但它们实际上可以通过一个低维流形来捕获，在该流形上捕获了某些属性，并且相似点被紧密分组（例如，真实世界物体/场景的图像并非从所有像素组合的均匀分布中抽取）。这使我们能够学习更有效的表示，以便发现和衡量未标记数据点之间的相似性。这也是表示学习的基础。[参见[一个有用的链接](https://stats.stackexchange.com/questions/66939/what-is-the-manifold-assumption-in-semi-supervised-learning)]。


> • 
> H1: **Smoothness Assumptions**: If two data samples are close in a high-density region of the feature space, their labels should be the same or very similar.
> • 
> H2: **Cluster Assumptions**: The feature space has both dense regions and sparse regions. Densely grouped data points naturally form a cluster. Samples in the same cluster are expected to have the same label. This is a small extension of H1.
> • 
> H3: **Low-density Separation Assumptions**: The decision boundary between classes tends to be located in the sparse, low density regions, because otherwise the decision boundary would cut a high-density cluster into two classes, corresponding to two clusters, which invalidates H1 and H2.
> • 
> H4: **Manifold Assumptions**: The high-dimensional data tends to locate on a low-dimensional manifold. Even though real-world data might be observed in very high dimensions (e.g. such as images of real-world objects/scenes), they actually can be captured by a lower dimensional manifold where certain attributes are captured and similar points are grouped closely (e.g. images of real-world objects/scenes are not drawn from a uniform distribution over all pixel combinations). This enables us to learn a more efficient representation for us to discover and measure similarity between unlabeled data points. This is also the foundation for representation learning. [see [a helpful link](https://stats.stackexchange.com/questions/66939/what-is-the-manifold-assumption-in-semi-supervised-learning)].

### 一致性正则化

> Consistency Regularization

**一致性正则化**，也称为**一致性训练**，假设神经网络内部的随机性（例如使用Dropout）或数据增强变换不应在给定相同输入的情况下修改模型预测。本节中的每种方法都具有一致性正则化损失，如$\mathcal{L}_u$。

英文原文：Consistency Regularization, also known as Consistency Training, assumes that randomness within the neural network (e.g. with Dropout) or data augmentation transformations should not modify model predictions given the same input. Every method in this section has a consistency regularization loss as 

$\mathcal{L}_u$.

这一思想已被多种[自监督](https://lilianweng.github.io/posts/2019-11-10-self-supervised/)[学习](https://lilianweng.github.io/posts/2021-05-31-contrastive/)方法采用，例如SimCLR、BYOL、SimCSE等。同一样本的不同增强版本应产生相同的表示。语言建模中的[跨视图训练](https://lilianweng.github.io/posts/2019-01-31-lm/#cross-view-training)和自监督学习中的多视图学习都具有相同的动机。

> This idea has been adopted in several [self-supervised](https://lilianweng.github.io/posts/2019-11-10-self-supervised/) [learning](https://lilianweng.github.io/posts/2021-05-31-contrastive/) methods, such as SimCLR, BYOL, SimCSE, etc. Different augmented versions of the same sample should result in the same representation. [Cross-view training](https://lilianweng.github.io/posts/2019-01-31-lm/#cross-view-training) in language modeling and multi-view learning in self-supervised learning all share the same motivation.

#### Π 模型

> Π-model

![Overview of the Π-model. Two versions of the same input with different stochastic augmentation and dropout masks pass through the network and the outputs are expected to be consistent. (Image source: Laine & Aila (2017) )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/PI-model.png)

[Sajjadi et al. (2016)](https://arxiv.org/abs/1606.04586) 提出了一种无监督学习损失，用于最小化同一数据点经过网络两次（带有随机变换，例如 dropout、随机最大池化）之间的差异。标签未被明确使用，因此该损失可以应用于未标记的数据集。[Laine & Aila (2017)](https://arxiv.org/abs/1610.02242) 后来为这种设置创造了名称，**Π 模型**。

> [Sajjadi et al. (2016)](https://arxiv.org/abs/1606.04586) proposed an unsupervised learning loss to minimize the difference between two passes through the network with stochastic transformations (e.g. dropout, random max-pooling) for the same data point. The label is not explicitly used, so the loss can be applied to unlabeled dataset. [Laine & Aila (2017)](https://arxiv.org/abs/1610.02242) later coined the name, **Π-Model**, for such a setup.

$$
\mathcal{L}_u^\Pi = \sum_{\mathbf{x} \in \mathcal{D}} \text{MSE}(f_\theta(\mathbf{x}), f'_\theta(\mathbf{x}))
$$

其中 $f’$ 是应用了不同随机增强或 dropout 掩码的相同神经网络。这种损失利用了整个数据集。

> where $f’$ is the same neural network with different stochastic augmentation or dropout masks applied. This loss utilizes the entire dataset.

#### 时间集成

> Temporal ensembling

![Overview of Temporal Ensembling. The per-sample EMA label prediction is the learning target. (Image source: Laine & Aila (2017) )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/temperal-ensembling.png)

Π 模型要求网络对每个样本运行两次，计算成本翻倍。为了降低成本，**时间集成** ([Laine & Aila 2017](https://arxiv.org/abs/1610.02242)) 针对每个训练样本 $\tilde{\mathbf{z}}_i$ 维护模型预测的时间指数移动平均 (EMA) 作为学习目标，该目标每个 epoch 只评估和更新一次。由于集成输出 $\tilde{\mathbf{z}}_i$ 被初始化为 $\mathbf{0}$，因此它通过 $(1-\alpha^t)$ 进行归一化以纠正这种启动偏差。Adam 优化器出于同样的原因也具有此类 [偏差校正](https://stats.stackexchange.com/questions/232741/why-is-it-important-to-include-a-bias-correction-term-for-the-adam-optimizer-for) 项。

英文原文：Π-model requests the network to run two passes per sample, doubling the computation cost. To reduce the cost, Temporal Ensembling ([Laine & Aila 2017](https://arxiv.org/abs/1610.02242)) maintains an exponential moving average (EMA) of the model prediction in time per training sample 

$\tilde{\mathbf{z}}_i$ as the learning target, which is only evaluated and updated once per epoch. Because the ensemble output 

$\tilde{\mathbf{z}}_i$ is initialized to 

$\mathbf{0}$, it is normalized by 

$(1-\alpha^t)$ to correct this startup bias. Adam optimizer has such [bias correction](https://stats.stackexchange.com/questions/232741/why-is-it-important-to-include-a-bias-correction-term-for-the-adam-optimizer-for) terms for the same reason.

$$
\tilde{\mathbf{z}}^{(t)}_i = \frac{\alpha \tilde{\mathbf{z}}^{(t-1)}_i + (1-\alpha) \mathbf{z}_i}{1-\alpha^t}
$$

其中 $\tilde{\mathbf{z}}^{(t)}$ 是 epoch $t$ 时的集成预测，$\mathbf{z}_i$ 是当前轮次中的模型预测。请注意，由于 $\tilde{\mathbf{z}}^{(0)} = \mathbf{0}$，经过校正后，$\tilde{\mathbf{z}}^{(1)}$ 在 epoch 1 时简单地等同于 $\mathbf{z}_i$。

> where $\tilde{\mathbf{z}}^{(t)}$ is the ensemble prediction at epoch $t$ and $\mathbf{z}_i$ is the model prediction in the current round. Note that since $\tilde{\mathbf{z}}^{(0)} = \mathbf{0}$, with correction, $\tilde{\mathbf{z}}^{(1)}$ is simply equivalent to $\mathbf{z}_i$ at epoch 1.

#### 平均教师模型

> Mean teachers

![Overview of the Mean Teacher framework. (Image source: Tarvaninen & Valpola, 2017 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/mean-teacher.png)

时间集成跟踪每个训练样本的标签预测的 EMA 作为学习目标。然而，这种标签预测只在 *每个 epoch* 改变一次，这使得当训练数据集很大时，该方法显得笨拙。**平均教师模型** ([Tarvaninen & Valpola, 2017](https://arxiv.org/abs/1703.01780)) 被提出，通过跟踪模型权重的移动平均而不是模型输出来克服目标更新的缓慢。我们将权重为 `\theta` 的原始模型称为 *学生* 模型，将连续学生模型的移动平均权重 $\theta’$ 的模型称为 *平均教师* 模型：$\theta’ \gets \beta \theta’ + (1-\beta)\theta$

英文原文：Temporal Ensembling keeps track of an EMA of label predictions for each training sample as a learning target. However, this label prediction only changes *every epoch*, making the approach clumsy when the training dataset is large. Mean Teacher ([Tarvaninen & Valpola, 2017](https://arxiv.org/abs/1703.01780)) is proposed to overcome the slowness of target update by tracking the moving average of model weights instead of model outputs. Let’s call the original model with weights `\theta` as the *student* model and the model with moving averaged weights 

$\theta’$ across consecutive student models as the *mean teacher*: 

$\theta’ \gets \beta \theta’ + (1-\beta)\theta$

一致性正则化损失是学生模型和教师模型预测之间的距离，学生-教师差距应该被最小化。平均教师模型预计会比学生模型提供更准确的预测。这在实证实验中得到了证实，如所示

> The consistency regularization loss is the distance between predictions by the student and teacher and the student-teacher gap should be minimized. The mean teacher is expected to provide more accurate predictions than the student. It got confirmed in the empirical experiments, as shown in 

![Classification error on SVHN of Mean Teacher and the Π Model. The mean teacher (in orange) has better performance than the student model (in blue). (Image source: Tarvaninen & Valpola, 2017 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/mean-teacher-results.png)

根据他们的消融研究，

> According to their ablation studies,

• 输入增强（例如输入图像的随机翻转、高斯噪声）或学生模型 dropout 对于良好性能是必要的。教师模型不需要 dropout。

• 性能对EMA衰减超参数$\beta$很敏感。一个好的策略是在启动阶段使用较小的$\beta=0.99$，在后期学生模型改进速度减慢时使用较大的$\beta=0.999$。

• 他们发现，将MSE作为一致性成本函数比KL散度等其他成本函数表现更好。

英文原文：

• Input augmentation (e.g. random flips of input images, Gaussian noise) or student model dropout is necessary for good performance. Dropout is not needed on the teacher model.

• The performance is sensitive to the EMA decay hyperparameter $\beta$. A good strategy is to use a small $\beta=0.99$ during the ramp up stage and a larger $\beta=0.999$ in the later stage when the student model improvement slows down.

• They found that MSE as the consistency cost function performs better than other cost functions like KL divergence.

#### 将噪声样本作为学习目标

> Noisy samples as learning targets

最近的几种一致性训练方法学习最小化原始未标记样本与其对应增强版本之间的预测差异。这与Π模型非常相似，但一致性正则化损失*仅*应用于未标记数据。

> Several recent consistency training methods learn to minimize prediction difference between the original unlabeled sample and its corresponding augmented version. It is quite similar to the Π-model but the consistency regularization loss is *only* applied to the unlabeled data.

![Consistency training with noisy samples.](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/consistency-training-with-noisy-samples.png)

对抗训练（[Goodfellow et al. 2014](https://arxiv.org/abs/1412.6572)）将对抗性噪声应用于输入，并训练模型以抵御此类对抗性攻击。该设置在监督学习中有效，

> Adversarial Training ([Goodfellow et al. 2014](https://arxiv.org/abs/1412.6572)) applies adversarial noise onto the input and trains the model to be robust to such adversarial attack. The setup works in supervised learning,

$$
\begin{aligned}
\mathcal{L}_\text{adv}(\mathbf{x}^l, \theta) &= D[q(y\mid \mathbf{x}^l), p_\theta(y\mid \mathbf{x}^l + r_\text{adv})] \\
r_\text{adv} &= {\arg\max}_{r; \|r\| \leq \epsilon} D[q(y\mid \mathbf{x}^l), p_\theta(y\mid \mathbf{x}^l + r_\text{adv})] \\
r_\text{adv} &\approx \epsilon \frac{g}{\|g\|_2} \approx \epsilon\text{sign}(g)\quad\text{where }g = \nabla_{r} D[y, p_\theta(y\mid \mathbf{x}^l + r)]
\end{aligned}
$$

其中 $q(y \mid \mathbf{x}^l)$ 是真实分布，通过对真实标签进行独热编码来近似，$y$。$p_\theta(y \mid \mathbf{x}^l)$ 是模型预测。$D[.,.]$ 是一个距离函数，用于衡量两个分布之间的散度。

> where $q(y \mid \mathbf{x}^l)$ is the true distribution, approximated by one-hot encoding of the ground truth label, $y$. $p_\theta(y \mid \mathbf{x}^l)$ is the model prediction. $D[.,.]$ is a distance function measuring the divergence between two distributions.

**虚拟对抗训练** (**VAT**; [Miyato 等人 2018](https://arxiv.org/abs/1704.03976)) 将这一思想扩展到半监督学习中。由于 $q(y \mid \mathbf{x}^l)$ 是未知的，VAT 用当前模型对原始输入使用当前权重 $\hat{\theta}$ 的预测来代替它。请注意，$\hat{\theta}$ 是模型权重的固定副本，因此在 $\hat{\theta}$ 上没有梯度更新。

英文原文：Virtual Adversarial Training (VAT; [Miyato et al. 2018](https://arxiv.org/abs/1704.03976)) extends the idea to work in semi-supervised learning. Because 

$q(y \mid \mathbf{x}^l)$ is unknown, VAT replaces it with the current model prediction for the original input with the current weights 

$\hat{\theta}$.  Note that 

$\hat{\theta}$ is a fixed copy of model weights, so there is no gradient update on 

$\hat{\theta}$.

$$
\begin{aligned}
\mathcal{L}_u^\text{VAT}(\mathbf{x}, \theta) &= D[p_{\hat{\theta}}(y\mid \mathbf{x}), p_\theta(y\mid \mathbf{x} + r_\text{vadv})] \\
r_\text{vadv} &= {\arg\max}_{r; \|r\| \leq \epsilon} D[p_{\hat{\theta}}(y\mid \mathbf{x}), p_\theta(y\mid \mathbf{x} + r)]
\end{aligned}
$$

VAT 损失适用于有标签和无标签样本。它是当前模型在每个数据点上的预测流形的负平滑度度量。这种损失的优化促使流形更加平滑。

> The VAT loss applies to both labeled and unlabeled samples. It is a negative smoothness measure of the current model’s prediction manifold at each data point. The optimization of such loss motivates the manifold to be smoother.

**插值一致性训练** (**ICT**; [Verma 等人 2019](https://arxiv.org/abs/1903.03825)) 通过添加更多数据点插值来增强数据集，并期望模型预测与相应标签的插值保持一致。MixUp ([Zheng 等人 2018](https://arxiv.org/abs/1710.09412)) 操作通过简单的加权和混合两张图像，并将其与标签平滑结合。遵循 MixUp 的思想，ICT 期望预测模型在混合样本上生成一个标签，以匹配相应输入的预测插值：

> **Interpolation Consistency Training** (**ICT**; [Verma et al. 2019](https://arxiv.org/abs/1903.03825)) enhances the dataset by adding more interpolations of data points and expects the model prediction to be consistent with interpolations of the corresponding labels. MixUp ([Zheng et al. 2018](https://arxiv.org/abs/1710.09412)) operation mixes two images via a simple weighted sum and combines it with label smoothing. Following the idea of MixUp, ICT expects the prediction model to produce a label on a mixup sample to match the interpolation of predictions of corresponding inputs:

$$
\begin{aligned}
\text{mixup}_\lambda (\mathbf{x}_i, \mathbf{x}_j) &= \lambda \mathbf{x}_i + (1-\lambda)\mathbf{x}_j \\
p(\text{mixup}_\lambda (y \mid \mathbf{x}_i, \mathbf{x}_j)) &\approx \lambda p(y \mid \mathbf{x}_i) + (1-\lambda) p(y \mid \mathbf{x}_j)
\end{aligned}
$$

其中 $\theta’$ 是 $\theta$ 的移动平均，它是一个 [平均教师模型](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#mean-teachers)。

> where $\theta’$ is a moving average of $\theta$, which is a [mean teacher](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#mean-teachers).

![Overview of Interpolation Consistency Training. MixUp is applied to produce more interpolated samples with interpolated labels as learning targets. (Image source: Verma et al. 2019 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/ICT.png)

由于两个随机选择的未标记样本属于不同类别的概率很高（例如，ImageNet 中有 1000 个对象类别），因此在两个随机未标记样本之间应用 mixup 进行插值很可能发生在决策边界附近。根据低密度分离[假设](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#hypotheses)，决策边界倾向于位于低密度区域。

> Because the probability of two randomly selected unlabeled samples belonging to different classes is high (e.g. There are 1000 object classes in ImageNet), the interpolation by applying a mixup between two random unlabeled samples is likely to happen around the decision boundary. According to the low-density separation [assumptions](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#hypotheses), the decision boundary tends to locate in the low density regions.

$$
\mathcal{L}^\text{ICT}_{u} = \mathbb{E}_{\mathbf{u}_i, \mathbf{u}_j \sim \mathcal{U}} \mathbb{E}_{\lambda \sim \text{Beta}(\alpha, \alpha)} D[p_\theta(y \mid \text{mixup}_\lambda (\mathbf{u}_i, \mathbf{u}_j)), \text{mixup}_\lambda(p_{\theta’}(y \mid \mathbf{u}_i), p_{\theta'}(y \mid \mathbf{u}_j)]
$$

其中 $\theta’$ 是 $\theta$ 的移动平均值。

> where $\theta’$ is a moving average of $\theta$.

与 VAT 类似，**无监督数据增强**（**UDA**；[Xie et al. 2020](https://arxiv.org/abs/1904.12848)）学习为未标记示例和增强示例预测相同的输出。UDA 特别关注研究噪声的*“质量”*如何通过一致性训练影响半监督学习性能。使用先进的数据增强方法来生成有意义且有效的噪声样本至关重要。好的数据增强应该产生有效（即不改变标签）且多样化的噪声，并带有目标归纳偏置。

> Similar to VAT, **Unsupervised Data Augmentation** (**UDA**; [Xie et al. 2020](https://arxiv.org/abs/1904.12848)) learns to predict the same output for an unlabeled example and the augmented one. UDA especially focuses on studying how the *“quality”* of noise can impact the semi-supervised learning performance with consistency training. It is crucial to use advanced data augmentation methods for producing meaningful and effective noisy samples. Good data augmentation should produce valid (i.e. does not change the label) and diverse noise, and carry targeted inductive biases.

对于图像，UDA 采用 RandAugment（[Cubuk et al. 2019](https://arxiv.org/abs/1909.13719)），它均匀采样 [PIL](https://pillow.readthedocs.io/en/stable/) 中可用的增强操作，无需学习或优化，因此比 AutoAugment 便宜得多。

> For images, UDA adopts RandAugment ([Cubuk et al. 2019](https://arxiv.org/abs/1909.13719)) which uniformly samples augmentation operations available in [PIL](https://pillow.readthedocs.io/en/stable/), no learning or optimization, so it is much cheaper than AutoAugment.

![Comparison of various semi-supervised learning methods on CIFAR-10 classification. Fully supervised Wide-ResNet-28-2 and PyramidNet+ShakeDrop have an error rate of **5.4** and **2.7** respectively when trained on 50,000 examples without RandAugment. (Image source: Xie et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/UDA-image-results.png)

对于语言，UDA 结合了回译和基于 TF-IDF 的词替换。回译保留了高层含义，但可能不会保留某些词，而基于 TF-IDF 的词替换则会删除 TF-IDF 分数较低的非信息性词。在语言任务的实验中，他们发现 UDA 与迁移学习和表示学习互补；例如，在领域内未标记数据上微调的 BERT（即图 8 中的 $\text{BERT}_\text{FINETUNE}$）可以进一步提高性能。

> For language, UDA combines back-translation and TF-IDF based word replacement. Back-translation preserves the high-level meaning but may not retain certain words, while TF-IDF based word replacement drops uninformative words with low TF-IDF scores. In the experiments on language tasks, they found UDA to be complementary to transfer learning and representation learning; For example, BERT fine-tuned (i.e. $\text{BERT}_\text{FINETUNE}$ in Fig. 8.) on in-domain unlabeled data can further improve the performance.

![Comparison of UDA with different initialization configurations on various text classification tasks. (Image source: Xie et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/UDA-language-results.png)

在计算 $\mathcal{L}_u$ 时，UDA 发现了两种有助于改善结果的训练技术。

> When calculating $\mathcal{L}_u$, UDA found two training techniques to help improve the results.

• *低置信度掩码*：如果预测置信度低于阈值 $\tau$，则掩盖低置信度的示例。

• *锐化预测分布*：在 softmax 中使用低温度 $T$ 来锐化预测概率分布。

• *领域内数据过滤*：为了从大型领域外数据集中提取更多领域内数据，他们训练了一个分类器来预测领域内标签，然后保留具有高置信度预测的样本作为领域内候选。

英文原文：

• *Low confidence masking*: Mask out examples with low prediction confidence if lower than a threshold $\tau$.

• *Sharpening prediction distribution*: Use a low temperature $T$ in softmax to sharpen the predicted probability distribution.

• *In-domain data filtration*: In order to extract more in-domain data from a large out-of-domain dataset, they trained a classifier to predict in-domain labels and then retain samples with high confidence predictions as in-domain candidates.

$$
\begin{aligned}
&\mathcal{L}_u^\text{UDA} = \mathbb{1}[\max_{y'} p_{\hat{\theta}}(y'\mid \mathbf{x}) > \tau ] \cdot D[p^\text{(sharp)}_{\hat{\theta}}(y \mid \mathbf{x}; T), p_\theta(y \mid \bar{\mathbf{x}})] \\
&\text{where } p_{\hat{\theta}}^\text{(sharp)}(y \mid \mathbf{x}; T) = \frac{\exp(z^{(y)} / T)}{ \sum_{y'} \exp(z^{(y')} / T) }
\end{aligned}
$$

其中 $\hat{\theta}$ 是模型权重的固定副本，与 VAT 中相同，因此没有梯度更新，$\bar{\mathbf{x}}$ 是增强数据点。$\tau$ 是预测置信度阈值，$T$ 是分布锐化温度。

> where $\hat{\theta}$ is a fixed copy of model weights, same as in VAT, so no gradient update, and $\bar{\mathbf{x}}$ is the augmented data point. $\tau$ is the prediction confidence threshold and $T$ is the distribution sharpening temperature.

### 伪标签

> Pseudo Labeling

**伪标签** ([Lee 2013](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.664.3543&rep=rep1&type=pdf)) 根据当前模型预测的最大softmax概率，为未标记样本分配伪标签，然后在纯监督设置下同时使用标记和未标记样本训练模型。

> **Pseudo Labeling** ([Lee 2013](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.664.3543&rep=rep1&type=pdf)) assigns fake labels to unlabeled samples based on the maximum softmax probabilities predicted by the current model and then trains the model on both labeled and unlabeled samples simultaneously in a pure supervised setup.

为什么伪标签会起作用？伪标签实际上等同于*熵正则化* ([Grandvalet & Bengio 2004](https://papers.nips.cc/paper/2004/hash/96f2b50b5d3613adf9c27049b2a888c7-Abstract.html))，它最小化了未标记数据的类别概率的条件熵，以利于类别之间的低密度分离。换句话说，预测的类别概率实际上是类别重叠的度量，最小化熵等同于减少类别重叠，从而实现低密度分离。

> Why could pseudo labels work? Pseudo label is in effect equivalent to *Entropy Regularization* ([Grandvalet & Bengio 2004](https://papers.nips.cc/paper/2004/hash/96f2b50b5d3613adf9c27049b2a888c7-Abstract.html)), which minimizes the conditional entropy of class probabilities for unlabeled data to favor low density separation between classes. In other words, the predicted class probabilities is in fact a measure of class overlap, minimizing the entropy is equivalent to reduced class overlap and thus low density separation.

![t-SNE visualization of outputs on MNIST test set by models training (a) without and (b) with pseudo labeling on 60000 unlabeled samples, in addition to 600 labeled data. Pseudo labeling leads to better segregation in the learned embedding space.  (Image source: Lee 2013 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/pseudo-label-segregation.png)

使用伪标签进行训练自然是一个迭代过程。我们将生成伪标签的模型称为教师模型，将使用伪标签学习的模型称为学生模型。

> Training with pseudo labeling naturally comes as an iterative process. We refer to the model that produces pseudo labels as teacher and the model that learns with pseudo labels as student.

#### 标签传播

> Label propagation

**标签传播** ([Iscen et al. 2019](https://arxiv.org/abs/1904.04717)) 是一种基于特征嵌入在样本之间构建相似性图的思想。然后，伪标签从已知样本“扩散”到未标记样本，其中传播权重与图中成对相似性分数成比例。从概念上讲，它类似于k-NN分类器，两者都存在无法很好地扩展到大型数据集的问题。

> **Label Propagation** ([Iscen et al. 2019](https://arxiv.org/abs/1904.04717)) is an idea to construct a similarity graph among samples based on feature embedding. Then the pseudo labels are “diffused” from known samples to unlabeled ones where the propagation weights are proportional to pairwise similarity scores in the graph. Conceptually it is similar to a k-NN classifier and both suffer from the problem of not scaling up well with a large dataset.

![Illustration of how Label Propagation works. (Image source: Iscen et al. 2019 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/label-propagation.png)

#### 自训练

> Self-Training

**自训练** 并非一个新概念 ([Scudder 1965](https://ieeexplore.ieee.org/document/1053799), [Nigram & Ghani CIKM 2000](http://www.kamalnigam.com/papers/cotrain-CIKM00.pdf))。它是一种迭代算法，在以下两个步骤之间交替进行，直到每个未标记样本都被分配了标签：

> **Self-Training** is not a new concept ([Scudder 1965](https://ieeexplore.ieee.org/document/1053799), [Nigram & Ghani CIKM 2000](http://www.kamalnigam.com/papers/cotrain-CIKM00.pdf)). It is an iterative algorithm, alternating between the following two steps until every unlabeled sample has a label assigned:

- 最初，它在标记数据上构建一个分类器。
- 然后，它使用此分类器预测未标记数据的标签，并将最确定的预测转换为标记样本。

> • Initially it builds a classifier on labeled data.
> • Then it uses this classifier to predict labels for the unlabeled data and converts the most confident ones into labeled samples.

[Xie et al. (2020)](https://arxiv.org/abs/1911.04252) 将自训练应用于深度学习并取得了很好的结果。在ImageNet分类任务上，他们首先训练了一个EfficientNet ([Tan & Le 2019](https://arxiv.org/abs/1905.11946)) 模型作为教师模型，为3亿张未标记图像生成伪标签，然后训练一个更大的EfficientNet作为学生模型，以同时学习真实标记图像和伪标记图像。他们设置中的一个关键要素是，在学生模型训练期间引入*噪声*，但教师模型在生成伪标签时没有噪声。因此，他们的方法被称为**噪声学生**。他们应用了随机深度 ([Huang et al. 2016](https://arxiv.org/abs/1603.09382))、dropout和RandAugment来对学生模型施加噪声。噪声对于学生模型表现优于教师模型至关重要。添加的噪声具有复合效应，可以促使模型在标记和未标记数据上的决策边界平滑。

> [Xie et al. (2020)](https://arxiv.org/abs/1911.04252) applied self-training in deep learning and achieved great results. On the ImageNet classification task, they first trained an EfficientNet ([Tan & Le 2019](https://arxiv.org/abs/1905.11946)) model as teacher to generate pseudo labels for 300M unlabeled images and then trained a larger EfficientNet as student to learn with both true labeled and pseudo labeled images. One critical element in their setup is to have *noise* during student model training but have no noise for the teacher to produce pseudo labels. Thus their method is called **Noisy Student**. They applied stochastic depth ([Huang et al. 2016](https://arxiv.org/abs/1603.09382)), dropout and RandAugment to noise the student. Noise is important for the student to perform better than the teacher. The added noise has a compound effect to encourage the model’s decision making frontier to be smooth, on both labeled and unlabeled data.

噪声学生自训练中的其他一些重要技术配置包括：

> A few other important technical configs in noisy student self-training are:

- 学生模型应该足够大（即比教师模型更大）以适应更多数据。
- “噪声学生”应该与数据平衡结合使用，尤其重要的是要平衡每个类别中伪标签图像的数量。
- 软伪标签比硬伪标签效果更好。

> • The student model should be sufficiently large (i.e. larger than the teacher) to fit more data.
> • Noisy student should be paired with data balancing, especially important to balance the number of pseudo labeled images in each class.
> • Soft pseudo labels work better than hard ones.

尽管模型并未针对对抗性鲁棒性进行优化，但噪声学生也能提高对抗性鲁棒性，以抵御FGSM（快速梯度符号攻击 = 该攻击利用损失函数相对于输入数据的梯度，并调整输入数据以最大化损失）攻击。

> Noisy student also improves adversarial robustness against an FGSM (Fast Gradient Sign Attack = The attack uses the gradient of the loss w.r.t the input data and adjusts the input data to maximize the loss) attack though the model is not optimized for adversarial robustness.

SentAugment由[Du et al. (2020)](https://arxiv.org/abs/2010.02194)提出，旨在解决语言领域中没有足够的域内未标记数据进行自训练的问题。它依赖于句子嵌入从大型语料库中查找未标记的域内样本，并使用检索到的句子进行自训练。

> SentAugment, proposed by [Du et al. (2020)](https://arxiv.org/abs/2010.02194), aims to solve the problem when there is not enough in-domain unlabeled data for self-training in the language domain. It relies on sentence embedding to find unlabeled in-domain samples from a large corpus and uses the retrieved sentences for self-training.

#### 减少确认偏差

> Reducing confirmation bias

确认偏差是由于不完善的教师模型提供了不正确的伪标签而产生的问题。过度拟合错误的标签可能无法给我们带来更好的学生模型。

> Confirmation bias is a problem with incorrect pseudo labels provided by an imperfect teacher model. Overfitting to wrong labels may not give us a better student model.

为了减少确认偏差，[Arazo 等人 (2019)](https://arxiv.org/abs/1908.02983) 提出了两种技术。一种是采用带有软标签的 MixUp。给定两个样本 $(\mathbf{x}_i, \mathbf{x}_j)$ 及其对应的真实或伪标签 $(y_i, y_j)$，插值标签方程可以转换为带有 softmax 输出的交叉熵损失：

> To reduce confirmation bias, [Arazo et al. (2019)](https://arxiv.org/abs/1908.02983) proposed  two techniques. One is to adopt MixUp with soft labels. Given two samples, $(\mathbf{x}_i, \mathbf{x}_j)$ and their corresponding true or pseudo labels $(y_i, y_j)$, the interpolated label equation can be translated to a cross entropy loss with softmax outputs:

$$
\begin{aligned}
&\bar{\mathbf{x}} = \lambda \mathbf{x}_i + (1-\lambda) \mathbf{x}_j \\
&\bar{y} = \lambda y_i + (1-\lambda) y_j \Leftrightarrow
\mathcal{L} = \lambda [y_i^\top \log f_\theta(\bar{\mathbf{x}})] + (1-\lambda) [y_j^\top \log f_\theta(\bar{\mathbf{x}})]
\end{aligned}
$$

如果标记样本过少，Mixup 是不够的。他们通过对标记样本进行过采样，进一步在每个 mini batch 中设置了最少数量的标记样本。这比提高标记样本的权重效果更好，因为它会导致更频繁的更新，而不是少量大幅度的更新，后者可能不太稳定。与一致性正则化一样，数据增强和 dropout 对于伪标签的良好工作也很重要。

> Mixup is insufficient if there are too few labeled samples. They further set a minimum number of labeled samples in every mini batch by oversampling the labeled samples. This works better than upweighting labeled samples, because it leads to more frequent updates rather than few updates of larger magnitude which could be less stable. Like consistency regularization, data augmentation and dropout are also important for pseudo labeling to work well.

**元伪标签** ([Pham 等人 2021](https://arxiv.org/abs/2003.10580)) 根据学生在标记数据集上的表现反馈，不断调整教师模型。教师和学生并行训练，其中教师学习生成更好的伪标签，学生则从伪标签中学习。

> **Meta Pseudo Labels** ([Pham et al. 2021](https://arxiv.org/abs/2003.10580)) adapts the teacher model constantly with the feedback of how well the student performs on the labeled dataset. The teacher and the student are trained in parallel, where the teacher learns to generate better pseudo labels and the student learns from the pseudo labels.

设教师模型和学生模型的权重分别为$\theta_T$和$\theta_S$。学生模型在带标签样本上的损失被定义为函数$\theta^\text{PL}_S(.)$的$\theta_T$，我们希望通过相应地优化教师模型来最小化此损失。

> Let the teacher and student model weights be $\theta_T$ and $\theta_S$, respectively. The student model’s loss on the labeled samples is defined as a function $\theta^\text{PL}_S(.)$ of $\theta_T$ and we would like to minimize this loss by optimizing the teacher model accordingly.

$$
\begin{aligned}
\min_{\theta_T} &\mathcal{L}_s(\theta^\text{PL}_S(\theta_T)) = \min_{\theta_T} \mathbb{E}_{(\mathbf{x}^l, y) \in \mathcal{X}} \text{CE}[y, f_{\theta_S}(\mathbf{x}^l)]  \\
\text{where } &\theta^\text{PL}_S(\theta_T)
= \arg\min_{\theta_S} \mathcal{L}_u (\theta_T, \theta_S)
= \arg\min_{\theta_S} \mathbb{E}_{\mathbf{u} \sim \mathcal{U}} \text{CE}[(f_{\theta_T}(\mathbf{u}), f_{\theta_S}(\mathbf{u}))]
\end{aligned}
$$

然而，优化上述方程并非易事。借鉴[MAML](https://arxiv.org/abs/1703.03400)，它将多步$\arg\min_{\theta_S}$近似为单步梯度更新的$\theta_S$，

> However, it is not trivial to optimize the above equation. Borrowing the idea of [MAML](https://arxiv.org/abs/1703.03400), it approximates the multi-step $\arg\min_{\theta_S}$ with the one-step gradient update of $\theta_S$,

$$
\begin{aligned}
\theta^\text{PL}_S(\theta_T) &\approx \theta_S - \eta_S \cdot \nabla_{\theta_S} \mathcal{L}_u(\theta_T, \theta_S) \\
\min_{\theta_T} \mathcal{L}_s (\theta^\text{PL}_S(\theta_T)) &\approx \min_{\theta_T} \mathcal{L}_s \big( \theta_S - \eta_S \cdot \nabla_{\theta_S} \mathcal{L}_u(\theta_T, \theta_S) \big)
\end{aligned}
$$

如果使用软伪标签，上述目标是可微分的。但如果使用硬伪标签，它就不可微分，因此我们需要使用强化学习（RL），例如REINFORCE。

> With soft pseudo labels, the above objective is differentiable. But if using hard pseudo labels, it is not differentiable and thus we need to use RL, e.g. REINFORCE.

优化过程在训练两个模型之间交替进行：

> The optimization procedure is alternative between training two models:

• *学生模型更新*：给定一批未标记样本$\{ \mathbf{u} \}$，我们通过$f_{\theta_T}(\mathbf{u})$生成伪标签，并用一步SGD优化$\theta_S$：$\theta’_S = \color{green}{\theta_S - \eta_S \cdot \nabla_{\theta_S} \mathcal{L}_u(\theta_T, \theta_S)}$。

• *教师模型更新*：给定一批已标记样本$\{(\mathbf{x}^l, y)\}$，我们重用学生的更新来优化$\theta_T$：$\theta’_T = \theta_T - \eta_T \cdot \nabla_{\theta_T} \mathcal{L}_s ( \color{green}{\theta_S - \eta_S \cdot \nabla_{\theta_S} \mathcal{L}_u(\theta_T, \theta_S)} )$。此外，UDA目标应用于教师模型以纳入一致性正则化。

英文原文：

• *Student model update*: Given a batch of unlabeled samples $\{ \mathbf{u} \}$, we generate pseudo labels by $f_{\theta_T}(\mathbf{u})$ and optimize $\theta_S$ with one step SGD: $\theta’_S = \color{green}{\theta_S - \eta_S \cdot \nabla_{\theta_S} \mathcal{L}_u(\theta_T, \theta_S)}$.

• *Teacher model update*: Given a batch of labeled samples $\{(\mathbf{x}^l, y)\}$, we reuse the student’s update to optimize $\theta_T$: $\theta’_T = \theta_T - \eta_T \cdot \nabla_{\theta_T} \mathcal{L}_s ( \color{green}{\theta_S - \eta_S \cdot \nabla_{\theta_S} \mathcal{L}_u(\theta_T, \theta_S)} )$. In addition, the UDA objective is applied to the teacher model to incorporate consistency regularization.

![Comparison of Meta Pseudo Labels with other semi- or self-supervised learning methods on image classification tasks. (Image source: Pham et al. 2021 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/MPL-results.png)

### 带有一致性正则化的伪标签

> Pseudo Labeling with Consistency Regularization

可以将上述两种方法结合起来，同时运行带有伪标签和一致性训练的半监督学习。

> It is possible to combine the above two approaches together, running semi-supervised learning with both pseudo labeling and consistency training.

#### MixMatch

> MixMatch

**MixMatch** ([Berthelot et al. 2019](https://arxiv.org/abs/1905.02249)) 作为一种半监督学习的整体方法，通过融合以下技术来利用未标记数据：

> **MixMatch** ([Berthelot et al. 2019](https://arxiv.org/abs/1905.02249)), as a holistic approach to semi-supervised learning, utilizes unlabeled data by merging the following techniques:

1. *一致性正则化*：鼓励模型对扰动的未标记样本输出相同的预测。
2. *熵最小化*：鼓励模型对未标记数据输出置信度高的预测。
3. *MixUp* 数据增强：鼓励模型在样本之间具有线性行为。

> • *Consistency regularization*: Encourage the model to output the same predictions on perturbed unlabeled samples.
> • *Entropy minimization*: Encourage the model to output confident predictions on unlabeled data.
> • *MixUp* augmentation: Encourage the model to have linear behaviour between samples.

给定一批已标记数据$\mathcal{X}$和未标记数据$\mathcal{U}$，我们通过$\text{MixMatch}(.)$、$\bar{\mathcal{X}}$和$\bar{\mathcal{U}}$创建它们的增强版本，其中包含增强样本和未标记示例的猜测标签。

> Given a batch of labeled data $\mathcal{X}$ and unlabeled data $\mathcal{U}$, we create augmented versions of them via $\text{MixMatch}(.)$, $\bar{\mathcal{X}}$ and $\bar{\mathcal{U}}$, containing augmented samples and guessed labels for unlabeled examples.

$$
\begin{aligned}
\bar{\mathcal{X}}, \bar{\mathcal{U}} &= \text{MixMatch}(\mathcal{X}, \mathcal{U}, T, K, \alpha) \\
\mathcal{L}^\text{MM}_s &= \frac{1}{\vert \bar{\mathcal{X}} \vert} \sum_{(\bar{\mathbf{x}}^l, y)\in \bar{\mathcal{X}}} D[y, p_\theta(y \mid \bar{\mathbf{x}}^l)] \\
\mathcal{L}^\text{MM}_u &= \frac{1}{L\vert \bar{\mathcal{U}} \vert} \sum_{(\bar{\mathbf{u}}, \hat{y})\in \bar{\mathcal{U}}} \| \hat{y} - p_\theta(y \mid \bar{\mathbf{u}}) \|^2_2 \\
\end{aligned}
$$

其中$T$是用于减少猜测标签重叠的锐化温度；$K$是每个未标记示例生成的增强数量；$\alpha$是MixUp中的参数。

> where $T$ is the sharpening temperature to reduce the guessed label overlap; $K$ is the number of augmentations generated per unlabeled example; $\alpha$ is the parameter in MixUp.

对于每个$\mathbf{u}$，MixMatch生成$K$个增强，$\bar{\mathbf{u}}^{(k)} = \text{Augment}(\mathbf{u})$用于$k=1, \dots, K$，伪标签基于平均值猜测：$\hat{y} = \frac{1}{K} \sum_{k=1}^K p_\theta(y \mid \bar{\mathbf{u}}^{(k)})$。

> For each $\mathbf{u}$, MixMatch generates $K$ augmentations, $\bar{\mathbf{u}}^{(k)} = \text{Augment}(\mathbf{u})$ for $k=1, \dots, K$ and the pseudo label is guessed based on the average: $\hat{y} = \frac{1}{K} \sum_{k=1}^K p_\theta(y \mid \bar{\mathbf{u}}^{(k)})$.

![The process of "label guessing" in MixMatch: averaging $K$ augmentations, correcting the predicted marginal distribution and finally sharpening the distribution. (Image source: Berthelot et al. 2019 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/MixMatch.png)

根据他们的消融研究，在未标记数据上使用MixUp至关重要。去除伪标签分布上的温度锐化会严重损害性能。对多个增强进行平均以猜测标签也是必要的。

> According to their ablation studies, it is critical to have MixUp especially on the unlabeled data. Removing temperature sharpening on the pseudo label distribution hurts the performance quite a lot. Average over multiple augmentations for label guessing is also necessary.

**ReMixMatch** ([Berthelot et al. 2020](https://arxiv.org/abs/1911.09785)) 通过引入两种新机制改进了MixMatch：

> **ReMixMatch** ([Berthelot et al. 2020](https://arxiv.org/abs/1911.09785)) improves MixMatch by introducing two new mechanisms:

![Illustration of two improvements introduced in ReMixMatch over MixMatch. (Image source: Berthelot et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/ReMixMatch.png)

• *分布对齐。*它鼓励边际分布$p(y)$接近真实标签的边际分布。令$p(y)$为真实标签中的类别分布，$\tilde{p}(\hat{y})$为未标记数据中预测类别分布的运行平均值。模型对未标记样本$p_\theta(y \vert \mathbf{u})$的预测被归一化为$\text{Normalize}\big( \frac{p_\theta(y \vert \mathbf{u}) p(y)}{\tilde{p}(\hat{y})} \big)$以匹配真实的边际分布。



   - 请注意，如果边际分布不均匀，熵最小化不是一个有用的目标。

   - 我确实认为，已标记和未标记数据上的类别分布应该匹配的假设过于强烈，在实际场景中不一定成立。

• *增强锚定*。给定一个未标记样本，它首先生成一个带有弱增强的“锚定”版本，然后使用CTAugment（控制理论增强）对$K$个强增强版本进行平均。CTAugment只采样那些使模型预测保持在网络容差范围内的增强。

英文原文：

• *Distribution alignment.* It encourages the marginal distribution $p(y)$ to be close to the marginal distribution of the ground truth labels. Let $p(y)$ be the class distribution in the true labels and $\tilde{p}(\hat{y})$ be a running average of the predicted class distribution among the unlabeled data. The model prediction on an unlabeled sample $p_\theta(y \vert \mathbf{u})$ is normalized to be $\text{Normalize}\big( \frac{p_\theta(y \vert \mathbf{u}) p(y)}{\tilde{p}(\hat{y})} \big)$ to match the true marginal distribution.



   - Note that entropy minimization is not a useful objective if the marginal distribution is not uniform.

   - I do feel the assumption that the class distributions on the labeled and unlabeled data should match is too strong and not necessarily to be true in the real-world setting.

• *Augmentation anchoring*. Given an unlabeled sample, it first generates an “anchor” version with weak augmentation and then averages $K$ strongly augmented versions using CTAugment (Control Theory Augment). CTAugment only samples augmentations that keep the model predictions within the network tolerance.

ReMixMatch损失是几个项的组合，

> The ReMixMatch loss is a combination of several terms,

- 应用了数据增强和MixUp的监督损失；
- 应用了数据增强和MixUp的无监督损失，使用伪标签作为目标；
- 在单个经过大量增强的未标记图像上计算的CE损失，不使用MixUp；
- 一种类似于自监督学习中的[旋转](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#distortion)损失。

> • a supervised loss with data augmentation and MixUp applied;
> • an unsupervised loss with data augmentation and MixUp applied, using pseudo labels as targets;
> • a CE loss on a single heavily-augmented unlabeled image without MixUp;
> • a [rotation](https://lilianweng.github.io/posts/2019-11-10-self-supervised/#distortion) loss as in self-supervised learning.

#### DivideMix

> DivideMix

**DivideMix** ([Junnan Li et al. 2020](https://arxiv.org/abs/2002.07394)) 结合了半监督学习和带噪声标签学习 (LNL)。它通过一个 [GMM](https://scikit-learn.org/stable/modules/mixture.html) 对逐样本损失分布进行建模，以动态地将训练数据分为包含干净样本的标记集和包含噪声样本的未标记集。遵循 [Arazo et al. 2019](https://arxiv.org/abs/1904.11238) 中的思想，他们对逐样本交叉熵损失 $\ell_i = y_i^\top \log f_\theta(\mathbf{x}_i)$ 拟合了一个双分量 GMM。与噪声样本相比，干净样本预计会更快地获得较低的损失。均值较小的分量是对应于干净标签的簇，我们将其表示为 `c`。如果 GMM 后验概率 $w_i = p_\text{GMM}(c \mid \ell_i)$（即样本属于干净样本集的概率）大于阈值 `\tau`，则该样本被视为干净样本，否则视为噪声样本。

英文原文：DivideMix ([Junnan Li et al. 2020](https://arxiv.org/abs/2002.07394)) combines semi-supervised learning with Learning with noisy labels (LNL). It models the per-sample loss distribution via a [GMM](https://scikit-learn.org/stable/modules/mixture.html) to dynamically divide the training data into a labeled set with clean examples and an unlabeled set with noisy ones. Following the idea in [Arazo et al. 2019](https://arxiv.org/abs/1904.11238), they fit a two-component GMM on the per-sample cross entropy loss 

$\ell_i = y_i^\top \log f_\theta(\mathbf{x}_i)$. Clean samples are expected to get lower loss faster than noisy samples. The component with smaller mean is the cluster corresponding to clean labels and let’s denote it as `c`. If the GMM posterior probability 

$w_i = p_\text{GMM}(c \mid \ell_i)$ (i.e. the probability of the sampling belonging to the clean sample set) is larger than the threshold `\tau`, this sample is considered as a clean sample and otherwise a noisy one.

数据聚类步骤名为*co-divide*。为避免确认偏差，DivideMix 同时训练两个不同的网络，其中每个网络都使用来自另一个网络的数据集划分；例如，可以联想到 Double Q Learning 的工作原理。

> The data clustering step is named *co-divide*. To avoid confirmation bias, DivideMix simultaneously trains two diverged networks where each network uses the dataset division from the other network; e.g. thinking about how Double Q Learning works.

![DivideMix trains two networks independently to reduce confirmation bias. They run co-divide, co-refinement, and co-guessing together. (Image source: Junnan Li et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/DivideMix.png)

与 MixMatch 相比，DivideMix 额外增加了一个*co-divide*阶段用于处理噪声样本，并在训练过程中进行了以下改进：

> Compared to MixMatch, DivideMix has an additional *co-divide* stage for handling noisy samples, as well as the following improvements during training:

• *标签协同细化*: 它将真实标签 $y_i$ 与网络的预测 $\hat{y}_i$ 进行线性组合，其中网络的预测是 $\mathbf{x}_i$ 的多次增强的平均值，并由另一个网络生成的干净集概率 $w_i$ 进行指导。

• *标签协同猜测*: 它对来自两个模型的预测进行平均，用于未标记的数据样本。

英文原文：

• *Label co-refinement*: It linearly combines the ground-truth label $y_i$ with the network’s prediction $\hat{y}_i$, which is averaged across multiple augmentations of $\mathbf{x}_i$, guided by the clean set probability $w_i$ produced by the other network.

• *Label co-guessing*: It averages the predictions from two models for unlabelled data samples.

![The algorithm of DivideMix. (Image source: Junnan Li et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/DivideMix-algo.png)

#### FixMatch

> FixMatch

**FixMatch** ([Sohn et al. 2020](https://arxiv.org/abs/2001.07685)) 使用弱增强在未标记样本上生成伪标签，并且只保留高置信度的预测。在这里，弱增强和高置信度过滤都有助于生成高质量、可信赖的伪标签目标。然后，FixMatch 学习在给定一个经过强增强的样本时预测这些伪标签。

> **FixMatch** ([Sohn et al. 2020](https://arxiv.org/abs/2001.07685)) generates pseudo labels on unlabeled samples with weak augmentation and only keeps predictions with high confidence. Here both weak augmentation and high confidence filtering help produce high-quality trustworthy pseudo label targets. Then FixMatch learns to predict these pseudo labels given a heavily-augmented sample.

![Illustration of how FixMatch works. (Image source: Sohn et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/FixMatch.png)

$$
\begin{aligned}
\mathcal{L}_s &= \frac{1}{B} \sum^B_{b=1} \text{CE}[y_b, p_\theta(y \mid \mathcal{A}_\text{weak}(\mathbf{x}_b))] \\
\mathcal{L}_u &= \frac{1}{\mu B} \sum_{b=1}^{\mu B} \mathbb{1}[\max(\hat{y}_b) \geq \tau]\;\text{CE}(\hat{y}_b, p_\theta(y \mid \mathcal{A}_\text{strong}(\mathbf{u}_b)))
\end{aligned}
$$

其中 $\hat{y}_b$ 是未标记样本的伪标签；$\mu$ 是一个超参数，它决定了 $\mathcal{X}$ 和 $\mathcal{U}$ 的相对大小。

> where $\hat{y}_b$ is the pseudo label for an unlabeled example; $\mu$ is a hyperparameter that determines the relative sizes of $\mathcal{X}$ and $\mathcal{U}$.

• 弱增强 $\mathcal{A}_\text{weak}(.)$：一种标准的翻转和平移增强

• 强数据增强 $\mathcal{A}_\text{strong}(.)$ : AutoAugment, Cutout, RandAugment, CTAugment

英文原文：

• Weak augmentation $\mathcal{A}_\text{weak}(.)$: A standard flip-and-shift augmentation

• Strong augmentation $\mathcal{A}_\text{strong}(.)$ : AutoAugment, Cutout, RandAugment, CTAugment

![Performance of FixMatch and several other semi-supervised learning methods on image classification tasks. (Image source: Sohn et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/FixMatch-results.png)

根据 FixMatch 的消融研究，

> According to the ablation studies of FixMatch,

• 使用温度参数$T$锐化预测分布，在使用阈值$\tau$时没有显著影响。

• Cutout 和 CTAugment 作为强数据增强的一部分，对于良好的性能是必要的。

• 当用于标签猜测的弱数据增强被强数据增强取代时，模型在训练早期就会发散。如果完全放弃弱数据增强，模型会过拟合猜测的标签。

• 使用弱数据增强而非强数据增强进行伪标签预测会导致性能不稳定。强数据增强至关重要。

英文原文：

• Sharpening the predicted distribution with a temperature parameter $T$ does not have a significant impact when the threshold $\tau$ is used.

• Cutout and CTAugment as part of strong augmentations are necessary for good performance.

• When the weak augmentation for label guessing is replaced with strong augmentation, the model diverges early in training. If discarding weak augmentation completely, the model overfit the guessed labels.

• Using weak instead of strong augmentation for pseudo label prediction leads to unstable performance. Strong data augmentation is critical.

### 结合强大的预训练

> Combined with Powerful Pre-Training

这是一种常见的范式，尤其是在语言任务中，即首先通过自监督学习在一个大型无监督数据集上预训练一个与任务无关的模型，然后使用少量标记数据集在下游任务上对其进行微调。研究表明，如果将半监督学习与预训练相结合，我们可以获得额外的收益。

> It is a common paradigm, especially in language tasks, to first pre-train a task-agnostic model on a large unsupervised data corpus via self-supervised learning and then fine-tune it on the downstream task with a small labeled dataset. Research has shown that we can obtain extra gain if combining semi-supervised learning with pretraining.

[Zoph 等人 (2020)](https://arxiv.org/abs/2006.06882) 研究了 [自训练](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#self-training) 在多大程度上可以比预训练表现更好。他们的实验设置是使用 ImageNet 进行预训练或自训练以改进 COCO。请注意，当使用 ImageNet 进行自训练时，它会丢弃标签，仅将 ImageNet 样本用作未标记数据点。[He 等人 (2018)](https://arxiv.org/abs/1811.08883) 已经证明，如果下游任务差异很大，例如目标检测，ImageNet 分类预训练效果不佳。

> [Zoph et al. (2020)](https://arxiv.org/abs/2006.06882) studied to what degree [self-training](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#self-training) can work better than pre-training. Their experiment setup was to use ImageNet for pre-training or self-training to improve COCO. Note that when using ImageNet for self-training, it discards labels and only uses ImageNet samples as unlabeled data points. [He et al. (2018)](https://arxiv.org/abs/1811.08883) has demonstrated that ImageNet classification pre-training does not work well if the downstream task is very different, such as object detection.

![The effect of (a) data augment (from weak to strong) and (b) the labeled dataset size on the object detection performance. In the legend: `Rand Init` refers to a model initialized w/ random weights; `ImageNet` is initialized with a pre-trained checkpoint at 84.5% top-1 ImageNet accuracy; `ImageNet++` is initialized with a checkpoint with a higher accuracy 86.9%. (Image source: Zoph et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/self-training-pre-training.png)

他们的实验展示了一系列有趣的发现：

> Their experiments demonstrated a series of interesting findings:

- 随着下游任务可用标记样本的增加，预训练的有效性会降低。预训练在低数据量（20%）情况下有帮助，但在高数据量情况下则中性或有害。
- 自训练在高数据/强数据增强情况下有帮助，即使预训练有害。
- 自训练可以在预训练的基础上带来额外的改进，即使使用相同的数据源。
- 自监督预训练（例如通过SimCLR）在高数据量情况下会损害性能，类似于监督预训练的情况。
- 联合训练监督和自监督目标有助于解决预训练和下游任务之间的不匹配问题。预训练、联合训练和自训练都是可叠加的。
- 噪声标签或非目标性标注（即预训练标签与下游任务标签不一致）比目标性伪标注更差。
- 自训练在计算上比在预训练模型上进行微调更昂贵。

> • The effectiveness of pre-training diminishes with more labeled samples available for the downstream task. Pre-training is helpful in the low-data regimes (20%) but neutral or harmful in the high-data regime.
> • Self-training helps in high data/strong augmentation regimes, even when pre-training hurts.
> • Self-training can bring in additive improvement on top of pre-training, even using the same data source.
> • Self-supervised pre-training (e.g. via SimCLR) hurts the performance in a high data regime, similar to how supervised pre-training does.
> • Joint-training supervised and self-supervised objectives help resolve the mismatch between the pre-training and downstream tasks. Pre-training, joint-training and self-training are all additive.
> • Noisy labels or un-targeted labeling (i.e. pre-training labels are not aligned with downstream task labels) is worse than targeted pseudo labeling.
> • Self-training is computationally more expensive than fine-tuning on a pre-trained model.

[Chen et al. (2020)](https://arxiv.org/abs/2006.10029) 提出了一种三步程序，以结合自监督预训练、监督微调和自训练的优点：

> [Chen et al. (2020)](https://arxiv.org/abs/2006.10029) proposed a three-step procedure to merge the benefits of self-supervised pretraining, supervised fine-tuning and self-training together:

1\. 无监督或自监督预训练一个大型模型。

2\. 在少量带标签的样本上进行监督微调。使用大型（深而宽）神经网络很重要。*更大的模型在更少的带标签样本下能产生更好的性能。*

3\. 通过在自训练中采用伪标签，使用无标签样本进行蒸馏。



• 可以将知识从大型模型蒸馏到小型模型中，因为特定任务的使用不需要学习到的表示具有额外的容量。



• 蒸馏损失的格式如下，其中教师网络的权重固定为 $\hat{\theta}_T$。

英文原文：

1\. Unsupervised or self-supervised pretrain a big model.

2\. Supervised fine-tune it on a few labeled examples. It is important to use a big (deep and wide) neural network. *Bigger models yield better performance with fewer labeled samples.*

3\. Distillation with unlabeled examples by adopting pseudo labels in self-training.



• It is possible to distill the knowledge from a large model into a small one because the task-specific use does not require extra capacity of the learned representation.



• The distillation loss is formatted as the following, where the teacher network is fixed with weights $\hat{\theta}_T$.

$$
\mathcal{L}_\text{distill} = - (1-\alpha) \underbrace{\sum_{(\mathbf{x}^l_i, y_i) \in \mathcal{X}} \big[ \log p_{\theta_S}(y_i \mid \mathbf{x}^l_i) \big]}_\text{Supervised loss} - \alpha \underbrace{\sum_{\mathbf{u}_i \in \mathcal{U}} \Big[ \sum_{i=1}^L p_{\hat{\theta}_T}(y^{(i)} \mid \mathbf{u}_i; T) \log p_{\theta_S}(y^{(i)} \mid \mathbf{u}_i; T) \Big]}_\text{Distillation loss using unlabeled data}
$$

![A semi-supervised learning framework leverages unlabeled data corpus by (Left) task-agnostic unsupervised pretraining and (Right) task-specific self-training and distillation. (Image source: Chen et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/big-self-supervised-model.png)

他们在 ImageNet 分类任务上进行了实验。自监督预训练使用了 SimCLRv2，它是 [SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr) 的直接改进版本。他们的实证研究观察结果证实了几项学习，与 [Zoph et al. 2020](https://arxiv.org/abs/2006.06882) 的发现一致：

> They experimented on the ImageNet classification task. The self-supervised pre-training uses SimCLRv2, a directly improved version of [SimCLR](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simclr). Observations in their empirical studies confirmed several learnings, aligned with [Zoph et al. 2020](https://arxiv.org/abs/2006.06882):

- 更大的模型标签效率更高；
- SimCLR 中更大/更深的项目头改进了表示学习；
- 使用无标签数据进行蒸馏改进了半监督学习。

> • Bigger models are more label-efficient;
> • Bigger/deeper project heads in SimCLR improve representation learning;
> • Distillation using unlabeled data improves semi-supervised learning.

![Comparison of performance by SimCLRv2 + semi-supervised distillation on ImageNet classification. (Image source: Chen et al. 2020 )](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/big-self-supervised-model-results.png)

💡 近期半监督学习方法的共同主题快速总结，其中许多旨在减少确认偏差：

> 💡 Quick summary of common themes among recent semi-supervised learning methods, many aiming to reduce confirmation bias:

- 通过先进的数据增强方法对样本施加有效且多样化的噪声。
- 在处理图像时，MixUp 是一种有效的增强方法。Mixup 也可以用于语言，带来小的增量改进（[Guo et al. 2019](https://arxiv.org/abs/1905.08941)）。
- 设置阈值并丢弃置信度低的伪标签。
- 设置每个小批量中带标签样本的最小数量。
- 锐化伪标签分布以减少类别重叠。

> • Apply valid and diverse noise to samples by advanced data augmentation methods.
> • When dealing with images, MixUp is an effective augmentation. Mixup could work on language too, resulting in a small incremental improvement ([Guo et al. 2019](https://arxiv.org/abs/1905.08941)).
> • Set a threshold and discard pseudo labels with low confidence.
> • Set a minimum number of labeled samples per mini-batch.
> • Sharpen the pseudo label distribution to reduce the class overlap.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Dec 2021). Learning with not enough data part 1: semi-supervised learning. Lil’Log. https://lilianweng.github.io/posts/2021-12-05-semi-supervised/。

> Weng, Lilian. (Dec 2021). Learning with not enough data part 1: semi-supervised learning. Lil’Log. https://lilianweng.github.io/posts/2021-12-05-semi-supervised/.

或

> Or

```
@article{weng2021semi,
  title   = "Learning with not Enough Data Part 1: Semi-Supervised Learning",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2021",
  month   = "Dec",
  url     = "https://lilianweng.github.io/posts/2021-12-05-semi-supervised/"
}
```

### 参考文献

> References

[1] Ouali, Hudelot & Tami. [“深度半监督学习概述”](https://arxiv.org/abs/2006.05278) arXiv 预印本 arXiv:2006.05278 (2020)。

> [1] Ouali, Hudelot & Tami. [“An Overview of Deep Semi-Supervised Learning”](https://arxiv.org/abs/2006.05278) arXiv preprint arXiv:2006.05278 (2020).

[2] Sajjadi, Javanmardi & Tasdizen [“用于深度半监督学习的随机变换和扰动正则化。”](https://arxiv.org/abs/1606.04586) arXiv 预印本 arXiv:1606.04586 (2016)。

> [2] Sajjadi, Javanmardi & Tasdizen [“Regularization With Stochastic Transformations and Perturbations for Deep Semi-Supervised Learning.”](https://arxiv.org/abs/1606.04586) arXiv preprint arXiv:1606.04586 (2016).

[3] Pham et al. [“元伪标签。”](https://arxiv.org/abs/2003.10580) CVPR 2021。

> [3] Pham et al. [“Meta Pseudo Labels.”](https://arxiv.org/abs/2003.10580) CVPR 2021.

[4] Laine & Aila. [“半监督学习的时间集成”](https://arxiv.org/abs/1610.02242) ICLR 2017.

> [4] Laine & Aila. [“Temporal Ensembling for Semi-Supervised Learning”](https://arxiv.org/abs/1610.02242) ICLR 2017.

[5] Tarvaninen & Valpola. [“平均教师是更好的榜样：权重平均一致性目标改善半监督深度学习结果。”](https://arxiv.org/abs/1703.01780) NeuriPS 2017

> [5] Tarvaninen & Valpola. [“Mean teachers are better role models: Weight-averaged consistency targets improve semi-supervised deep learning results.”](https://arxiv.org/abs/1703.01780) NeuriPS 2017

[6] Xie et al. [“用于一致性训练的无监督数据增强。”](https://arxiv.org/abs/1904.12848) NeuriPS 2020.

> [6] Xie et al. [“Unsupervised Data Augmentation for Consistency Training.”](https://arxiv.org/abs/1904.12848) NeuriPS 2020.

[7] Miyato et al. [“虚拟对抗训练：一种用于监督和半监督学习的正则化方法。”](https://arxiv.org/abs/1704.03976) IEEE transactions on pattern analysis and machine intelligence 41.8 (2018).

> [7] Miyato et al. [“Virtual Adversarial Training: A Regularization Method for Supervised and Semi-Supervised Learning.”](https://arxiv.org/abs/1704.03976) IEEE transactions on pattern analysis and machine intelligence 41.8 (2018).

[8] Verma et al. [“用于半监督学习的插值一致性训练。”](https://arxiv.org/abs/1903.03825) IJCAI 2019

> [8] Verma et al. [“Interpolation consistency training for semi-supervised learning.”](https://arxiv.org/abs/1903.03825) IJCAI 2019

[9] Lee. [“伪标签：一种用于深度神经网络的简单高效半监督学习方法。”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.664.3543&rep=rep1&type=pdf) ICML 2013 Workshop: Challenges in Representation Learning.

> [9] Lee. [“Pseudo-label: The simple and efficient semi-supervised learning method for deep neural networks.”](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.664.3543&rep=rep1&type=pdf) ICML 2013 Workshop: Challenges in Representation Learning.

[10] Iscen et al. [“用于深度半监督学习的标签传播。”](https://arxiv.org/abs/1904.04717) CVPR 2019.

> [10] Iscen et al. [“Label propagation for deep semi-supervised learning.”](https://arxiv.org/abs/1904.04717) CVPR 2019.

[11] Xie et al. [“使用噪声学生进行自训练可改善 ImageNet 分类”](https://arxiv.org/abs/1911.04252) CVPR 2020.

> [11] Xie et al. [“Self-training with Noisy Student improves ImageNet classification”](https://arxiv.org/abs/1911.04252) CVPR 2020.

[12] Jingfei Du et al. [“自训练改进自然语言理解的预训练。”](https://arxiv.org/abs/2010.02194) 2020

> [12] Jingfei Du et al. [“Self-training Improves Pre-training for Natural Language Understanding.”](https://arxiv.org/abs/2010.02194) 2020

[13] Iscen et al. [“用于深度半监督学习的标签传播。”](https://arxiv.org/abs/1904.04717) CVPR 2019

> [13] Iscen et al. [“Label propagation for deep semi-supervised learning.”](https://arxiv.org/abs/1904.04717) CVPR 2019

[14] Arazo et al. [“深度半监督学习中的伪标签和确认偏差。”](https://arxiv.org/abs/1908.02983) IJCNN 2020.

> [14] Arazo et al. [“Pseudo-labeling and confirmation bias in deep semi-supervised learning.”](https://arxiv.org/abs/1908.02983) IJCNN 2020.

[15] Berthelot et al. [“MixMatch：一种半监督学习的整体方法。”](https://arxiv.org/abs/1905.02249) NeuriPS 2019

> [15] Berthelot et al. [“MixMatch: A holistic approach to semi-supervised learning.”](https://arxiv.org/abs/1905.02249) NeuriPS 2019

[16] Berthelot et al. [“ReMixMatch：结合分布对齐和增强锚定的半监督学习。”](https://arxiv.org/abs/1911.09785) ICLR 2020

> [16] Berthelot et al. [“ReMixMatch: Semi-supervised learning with distribution alignment and augmentation anchoring.”](https://arxiv.org/abs/1911.09785) ICLR 2020

[17] Sohn et al. [“FixMatch：通过一致性和置信度简化半监督学习。”](https://arxiv.org/abs/2001.07685) CVPR 2020

> [17] Sohn et al. [“FixMatch: Simplifying semi-supervised learning with consistency and confidence.”](https://arxiv.org/abs/2001.07685)  CVPR 2020

[18] Junnan Li et al. [“DivideMix：将带噪声标签学习视为半监督学习。”](https://arxiv.org/abs/2002.07394) 2020 [[代码](https://github.com/LiJunnan1992/DivideMix)]

> [18] Junnan Li et al. [“DivideMix: Learning with Noisy Labels as Semi-supervised Learning.”](https://arxiv.org/abs/2002.07394) 2020 [[code](https://github.com/LiJunnan1992/DivideMix)]

[19] Zoph et al. [“重新思考预训练和自训练。”](https://arxiv.org/abs/2006.06882) 2020.

> [19] Zoph et al. [“Rethinking pre-training and self-training.”](https://arxiv.org/abs/2006.06882) 2020.

[20] Chen et al. [“大型自监督模型是强大的半监督学习器”](https://arxiv.org/abs/2006.10029) 2020

> [20] Chen et al. [“Big Self-Supervised Models are Strong Semi-Supervised Learners”](https://arxiv.org/abs/2006.10029) 2020

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Semi-supervised Learning (SSL) | 半监督学习 | 一种机器学习范式，同时利用标注数据和未标注数据进行模型训练。 |
| Consistency Regularization | 一致性正则化 | 假设模型对同一输入的不同扰动版本应产生一致的预测，用于训练模型。 |
| Pseudo-Labeling | 伪标签 | 根据模型对未标注数据的高置信度预测生成假标签，用于后续训练。 |
| Mean Teachers | 平均教师模型 | 一种半监督学习方法，通过跟踪学生模型权重的指数移动平均来构建教师模型，以提供更稳定的学习目标。 |
| Virtual Adversarial Training (VAT) | 虚拟对抗训练 | 通过在输入中添加对抗性噪声并最小化模型预测差异来提高模型平滑度和鲁棒性。 |
| Unsupervised Data Augmentation (UDA) | 无监督数据增强 | 利用先进的数据增强技术为未标注数据生成多样化且有效的噪声样本，以进行一致性训练。 |
| Self-Training | 自训练 | 一种迭代算法，通过模型预测为未标注数据生成伪标签，并将其加入训练集以改进模型。 |
| Confirmation Bias | 确认偏差 | 半监督学习中，不完善的教师模型生成错误伪标签，导致学生模型过度拟合这些错误标签的问题。 |
| MixUp | 混合增强 | 一种数据增强技术，通过线性插值两个样本及其标签来生成新的训练样本。 |
| Entropy Minimization | 熵最小化 | 鼓励模型对未标注数据输出高置信度的预测，从而减少类别重叠，实现低密度分离。 |
| RandAugment | 随机增强 | 一种数据增强策略，从预定义的操作集中随机采样并应用增强，无需学习或优化。 |
| Exponential Moving Average (EMA) | 指数移动平均 | 一种加权平均方法，赋予近期数据更高的权重，常用于平滑模型参数或预测。 |
| Low-density Separation Hypothesis | 低密度分离假设 | 类别之间的决策边界倾向于位于特征空间的稀疏低密度区域。 |
| Manifold Hypothesis | 流形假设 | 高维数据倾向于位于低维流形上，使得相似点紧密分组。 |
| Distillation | 知识蒸馏 | 将大型教师模型的知识转移到小型学生模型中的过程，通常通过匹配教师模型的软预测来实现。 |
