# 数据不足下的学习 第二部分：主动学习

> Learning with not Enough Data Part 2: Active Learning

> 来源：Lil'Log / Lilian Weng，2022-02-20
> 原文链接：https://lilianweng.github.io/posts/2022-02-20-active-learning/
> 分类：机器学习 / 主动学习

## 核心要点

- 主动学习旨在从大量未标记数据中智能选择少量样本进行人工标注，以在预算限制内最大化模型性能提升。
- 采集函数是主动学习中的核心评分机制，用于识别对模型训练最有价值的样本，主要策略包括不确定性采样、多样性采样和预期模型变化。
- 不确定性采样通过评估模型预测的置信度或熵来选择最不确定的样本，而委员会查询（QBC）则基于专家模型委员会的分歧来衡量不确定性。
- 深度学习模型的不确定性可分为由数据噪声引起的偶然不确定性（Aleatoric Uncertainty）和模型参数内部的认知不确定性（Epistemic Uncertainty），后者可通过获取更多数据来减少。
- 蒙特卡洛 dropout (MC dropout) 是一种经济有效的方法，通过在推理时应用不同的 dropout 掩码来近似集成，从而估计模型不确定性。
- 损失预测模块通过预测未标记输入的损失值来估计模型预测质量，选择预测损失高的样本进行标注。
- 变分对抗主动学习 (VAAL) 和极小极大主动学习 (MAL) 等对抗性方法利用判别器区分已标记和未标记数据，以选择与已知数据差异大的样本。
- 核心集方法将主动学习视为核心集选择问题，旨在找到一小组能近似代表整个数据集的点，以确保模型泛化能力。
- BADGE方法在梯度空间中同时跟踪模型不确定性和数据多样性，通过梯度幅度衡量不确定性，并通过k-means++捕获多样性。
- 混合策略结合了不确定性和多样性等多种采样偏好，例如启发式标注 (SA) 和结合半监督学习的成本效益主动学习 (CEAL)，以优化批处理模式下的主动学习效果。

## 正文

这是关于在监督学习任务中面临有限标注数据时如何处理的第二部分。这一次，我们将涉及一定量的人工标注工作，但需在预算限制内，因此我们需要在选择要标注的样本时保持明智。

> This is part 2 of what to do when facing a limited amount of labeled data for supervised learning tasks. This time we will get some amount of human labeling work involved, but within a budget limit, and therefore we need to be smart when selecting which samples to label.

### 符号

> Notations

| 符号 | 含义 |
| --- | --- |
| $K$ | 唯一类别标签的数量。 |
| $(\mathbf{x}^l, y) \sim \mathcal{X}, y \in \{0, 1\}^K$ | 已标注数据集。$y$ 是真实标签的独热表示。 |
| $\mathbf{u} \sim \mathcal{U}$ | 未标注数据集。 |
| $\mathcal{D} = \mathcal{X} \cup \mathcal{U}$ | 整个数据集，包括已标注和未标注的样本。 |
| $\mathbf{x}$ | 可以是已标注或未标注的任何样本。 |
| $\mathbf{x}_i$ | 第 $i$ 个样本。 |
| $U(\mathbf{x})$ | 用于主动学习选择的评分函数。 |
| $P_\theta(y \vert \mathbf{x})$ | 由 $\theta$ 参数化的 softmax 分类器。 |
| $\hat{y} = \arg\max_{y \in \mathcal{Y}} P_\theta(y \vert \mathbf{x})$ | 分类器最自信的预测。 |
| $B$ | 标注预算（要标注的最大样本数）。 |
| $b$ | 批次大小。 |

> 英文原表 / English original

| Symbol | Meaning |
| --- | --- |
| $K$ | Number of unique class labels. |
| $(\mathbf{x}^l, y) \sim \mathcal{X}, y \in \{0, 1\}^K$ | Labeled dataset. $y$ is a one-hot representation of the true label. |
| $\mathbf{u} \sim \mathcal{U}$ | Unlabeled dataset. |
| $\mathcal{D} = \mathcal{X} \cup \mathcal{U}$ | The entire dataset, including both labeled and unlabeled examples. |
| $\mathbf{x}$ | Any sample which can be either labeled or unlabeled. |
| $\mathbf{x}_i$ | The $i$-th sample. |
| $U(\mathbf{x})$ | Scoring function for active learning selection. |
| $P_\theta(y \vert \mathbf{x})$ | A softmax classifier parameterized by $\theta$. |
| $\hat{y} = \arg\max_{y \in \mathcal{Y}} P_\theta(y \vert \mathbf{x})$ | The most confident prediction by the classifier. |
| $B$ | Labeling budget (the maximum number of samples to label). |
| $b$ | Batch size. |

### 什么是主动学习？

> What is Active Learning?

给定一个未标记的数据集$\mathcal{U}$以及固定的标注成本$B$，主动学习旨在选择一个子集$B$个样本，从$\mathcal{U}$进行标注，以期在模型性能上获得最大程度的提升。这是一种有效的学习方式，尤其是在数据标注困难且成本高昂时，例如医学图像。这篇经典的[综述论文](https://burrsettles.com/pub/settles.activelearning.pdf)于2010年列出了许多关键概念。虽然一些传统方法可能不适用于深度学习，但本文的讨论主要集中在深度神经网络模型和批处理模式训练上。

> Given an unlabeled dataset $\mathcal{U}$ and a fixed amount of labeling cost $B$, active learning aims to select a subset of $B$ examples from $\mathcal{U}$ to be labeled such that they can result in maximized improvement in model performance. This is an effective way of learning especially when data labeling is difficult and costly, e.g. medical images. This classical [survey paper](https://burrsettles.com/pub/settles.activelearning.pdf) in 2010 lists many key concepts. While some conventional approaches may not apply to deep learning, discussion in this post mainly focuses on deep neural models and training in batch mode.

![Illustration of a cyclic workflow of active learning, producing better models more efficiently by smartly choosing which samples to label.](https://lilianweng.github.io/posts/2022-02-20-active-learning/active-learning-workflow.png)

为了简化讨论，我们在以下所有章节中都假设任务是一个 $K$ 类分类问题。具有参数 $\theta$ 的模型输出标签候选的概率分布，该分布可能经过校准，也可能未经校准，$P_\theta(y \vert \mathbf{x})$ 最可能的预测是 $\hat{y} = \arg\max_{y \in \mathcal{Y}} P_\theta(y \vert \mathbf{x})$。

> To simplify the discussion, we assume that the task is a $K$ -class classification problem in all the following sections. The model with parameters $\theta$ outputs a probability distribution over the label candidates, which may or may not be calibrated, $P_\theta(y \vert \mathbf{x})$ and the most likely prediction is $\hat{y} = \arg\max_{y \in \mathcal{Y}} P_\theta(y \vert \mathbf{x})$.

### 采集函数

> Acquisition Function

识别接下来最有价值的样本进行标注的过程被称为“采样策略”或“查询策略”。采样过程中的评分函数被称为“获取函数”，表示为$U(\mathbf{x})$。具有更高分数的数据点在被标注后，预计会为模型训练带来更高的价值。

> The process of identifying the most valuable examples to label next is referred to as “sampling strategy” or “query strategy”. The scoring function in the sampling process is named “acquisition function”, denoted as $U(\mathbf{x})$. Data points with higher scores are expected to produce higher value for model training if they get labeled.

以下是一些基本的采样策略。

> Here is a list of basic sampling strategies.

#### 不确定性采样

> Uncertainty Sampling

**不确定性采样**选择模型产生最不确定预测的样本。对于单个模型，不确定性可以通过预测概率来估计，尽管一个常见的抱怨是深度学习模型的预测通常未经过校准，并且与真实不确定性关联不佳。事实上，深度学习模型通常过于自信。

> **Uncertainty sampling** selects examples for which the model produces most uncertain predictions. Given a single model, uncertainty can be estimated by the predicted probabilities, although one common complaint is that deep learning model predictions are often not calibrated and not correlated with true uncertainty well. In fact, deep learning models are often overconfident.

• *最低置信度分数*，也称为*变异比率*：$U(\mathbf{x}) = 1 - P_\theta(\hat{y} \vert \mathbf{x})$。

• *边际分数*：$U(\mathbf{x}) = P_\theta(\hat{y}_1 \vert \mathbf{x}) - P_\theta(\hat{y}_2 \vert \mathbf{x})$，其中$\hat{y}_1$和$\hat{y}_2$是最有可能和次有可能的预测标签。

• *熵*: $U(\mathbf{x}) = \mathcal{H}(P_\theta(y \vert \mathbf{x})) = - \sum_{y \in \mathcal{Y}} P_\theta(y \vert \mathbf{x}) \log P_\theta(y \vert \mathbf{x})$。

英文原文：

• *Least confident score*, also known as *variation ratio*: $U(\mathbf{x}) = 1 - P_\theta(\hat{y} \vert \mathbf{x})$.

• *Margin score*: $U(\mathbf{x}) = P_\theta(\hat{y}_1 \vert \mathbf{x}) - P_\theta(\hat{y}_2 \vert \mathbf{x})$, where $\hat{y}_1$ and $\hat{y}_2$ are the most likely and the second likely predicted labels.

• *Entropy*: $U(\mathbf{x}) = \mathcal{H}(P_\theta(y \vert \mathbf{x})) = - \sum_{y \in \mathcal{Y}} P_\theta(y \vert \mathbf{x}) \log P_\theta(y \vert \mathbf{x})$.

量化不确定性的另一种方法是依赖于专家模型委员会，即委员会查询（Query-By-Committee, QBC）。QBC 基于意见池来衡量不确定性，因此保持委员会成员之间存在一定程度的分歧至关重要。给定委员会池中的 $C$ 个模型，每个模型都由 $\theta_1, \dots, \theta_C$ 参数化。

> Another way to quantify uncertainty is to rely on a committee of expert models, known as Query-By-Committee (QBC). QBC measures uncertainty based on a pool of opinions and thus it is critical to keep a level of disagreement among committee members. Given $C$ models in the committee pool, each parameterized by $\theta_1, \dots, \theta_C$.

• *投票者熵*: $U(\mathbf{x}) = \mathcal{H}(\frac{V(y)}{C})$，其中 $V(y)$ 统计委员会对标签 $y$ 的投票数量。

• *共识熵*: $U(\mathbf{x}) = \mathcal{H}(P_\mathcal{C})$，其中 $P_\mathcal{C}$ 是委员会的平均预测。

• *KL 散度*: $U(\mathbf{x}) = \frac{1}{C} \sum_{c=1}^C D_\text{KL} (P_{\theta_c} | P_\mathcal{C})$

英文原文：

• *Voter entropy*: $U(\mathbf{x}) = \mathcal{H}(\frac{V(y)}{C})$, where $V(y)$ counts the number of votes from the committee on the label $y$.

• *Consensus entropy*: $U(\mathbf{x}) = \mathcal{H}(P_\mathcal{C})$, where $P_\mathcal{C}$ is the prediction averaging across the committee.

• *KL divergence*: $U(\mathbf{x}) = \frac{1}{C} \sum_{c=1}^C D_\text{KL} (P_{\theta_c} | P_\mathcal{C})$

#### 多样性采样

> Diversity Sampling

**多样性采样**旨在找到一组能够很好地代表整个数据分布的样本。多样性很重要，因为模型应该在任何实际数据上都能很好地工作，而不仅仅是在狭窄的子集上。选定的样本应该能代表底层分布。常见的方法通常依赖于量化样本之间的相似性。

> **Diversity sampling** intend to find a collection of samples that can well represent the entire data distribution. Diversity is important because the model is expected to work well on any data in the wild, just not on a narrow subset. Selected samples should be representative of the underlying distribution. Common approaches often rely on quantifying the similarity between samples.

#### 预期模型变化

> Expected Model Change

**预期模型变化**是指样本对模型训练产生的影响。这种影响可以是模型权重上的影响，也可以是训练损失上的改进。一个[后续章节](https://lilianweng.github.io/posts/2022-02-20-active-learning/#measuring-training-effects)回顾了几项关于如何衡量由选定数据样本触发的模型影响的工作。

> **Expected model change** refers to the impact that a sample brings onto the model training. The impact can be the influence on the model weights or the improvement over the training loss. A [later section](https://lilianweng.github.io/posts/2022-02-20-active-learning/#measuring-training-effects) reviews several works on how to measure model impact triggered by selected data samples.

#### 混合策略

> Hybrid Strategy

上述许多方法并非相互排斥。一种**混合**采样策略会评估数据点的不同属性，将不同的采样偏好结合起来。我们通常希望选择不确定但又具有高度代表性的样本。

> Many methods above are not mutually exclusive. A **hybrid** sampling strategy values different attributes of data points, combining different sampling preferences into one. Often we want to select uncertain but also highly representative samples.

### 深度采集函数

> Deep Acquisition Function

#### 不确定性度量

> Measuring Uncertainty

模型不确定性通常分为两类（[Der Kiureghian & Ditlevsen 2009](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.455.9057&rep=rep1&type=pdf), [Kendall & Gal 2017](https://arxiv.org/abs/1703.04977)）：

> The model uncertainty is commonly categorized into two buckets ([Der Kiureghian & Ditlevsen 2009](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.455.9057&rep=rep1&type=pdf), [Kendall & Gal 2017](https://arxiv.org/abs/1703.04977)):

- *偶然不确定性*是由数据中的噪声（例如传感器数据、测量过程中的噪声）引入的，它可以是输入相关的或输入无关的。由于缺少关于真实情况的信息，它通常被认为是不可约的。
- *认知不确定性*是指模型参数内部的不确定性，因此我们不知道模型是否能最好地解释数据。理论上，这种不确定性在获得更多数据后是可以减少的。

> • *Aleatoric uncertainty* is introduced by noise in the data (e.g. sensor data, noise in the measurement process) and it can be input-dependent or input-independent. It is generally considered as irreducible since there is missing information about the ground truth.
> • *Epistemic uncertainty* refers to the uncertainty within the model parameters and therefore we do not know whether the model can best explain the data. This type of uncertainty is theoretically reducible given more data

##### 集成和近似集成

> Ensemble and Approximated Ensemble

在机器学习中，使用集成方法来提高模型性能有着悠久的传统。当模型之间存在显著多样性时，集成方法有望产生更好的结果。许多机器学习算法都证明了这种集成理论的正确性；例如，[AdaBoost](https://en.wikipedia.org/wiki/AdaBoost) 聚合了许多弱学习器，使其表现与单个强学习器相似甚至更好。[Bootstrapping](https://en.wikipedia.org/wiki/Bootstrapping_(statistics)) 集成了多次重采样试验，以实现更准确的指标估计。随机森林或 [GBM](https://en.wikipedia.org/wiki/Gradient_boosting) 也是集成有效性的一个很好的例子。

> There is a long tradition in machine learning of using ensembles to improve model performance. When there is a significant diversity among models, ensembles are expected to yield better results. This ensemble theory is proved to be correct by many ML algorithms; for example, [AdaBoost](https://en.wikipedia.org/wiki/AdaBoost) aggregates many weak learners to perform similar or even better than a single strong learner. [Bootstrapping](https://en.wikipedia.org/wiki/Bootstrapping_(statistics)) ensembles multiple trials of resampling to achieve more accurate estimation of metrics. Random forests or [GBM](https://en.wikipedia.org/wiki/Gradient_boosting) is also a good example for the effectiveness of ensembling.

为了获得更好的不确定性估计，直观的做法是聚合一组独立训练的模型。然而，训练单个深度神经网络模型成本高昂，更不用说训练多个模型了。在强化学习中，Bootstrapped DQN ([Osband, et al. 2016](https://arxiv.org/abs/1602.04621)) 配备了多个价值头，并依赖于 Q 值近似集成中的不确定性来指导强化学习中的[探索](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#q-value-exploration)。

> To get better uncertainty estimation, it is intuitive to aggregate a collection of independently trained models. However, it is expensive to train a single deep neural network model, let alone many of them. In reinforcement learning, Bootstrapped DQN  ([Osband, et al. 2016](https://arxiv.org/abs/1602.04621)) is equipped with multiple value heads and relies on the uncertainty among an ensemble of Q value approximation to guide [exploration](https://lilianweng.github.io/posts/2020-06-07-exploration-drl/#q-value-exploration) in RL.

在主动学习中，一种更常见的方法是使用*dropout*来“模拟”概率高斯过程（[Gal & Ghahramani 2016](https://arxiv.org/abs/1506.02142)）。因此，我们对从同一模型收集的多个样本进行集成，但在前向传播过程中应用不同的 dropout 掩码来估计模型不确定性（认知不确定性）。这个过程被称为**MC dropout**（蒙特卡洛 dropout），其中 dropout 应用于每个权重层之前，被证明在数学上等同于概率深度高斯过程的近似（[Gal & Ghahramani 2016](https://arxiv.org/abs/1506.02157)）。这个简单的想法已被证明对小数据集的分类有效，并广泛应用于需要高效模型不确定性估计的场景。

> In active learning, a commoner approach is to use *dropout* to “simulate” a probabilistic Gaussian process ([Gal & Ghahramani 2016](https://arxiv.org/abs/1506.02142)). We thus ensemble multiple samples collected from the same model but with different dropout masks applied during the forward pass to estimate the model uncertainty (epistemic uncertainty). The process is named **MC dropout** (Monte Carlo dropout), where dropout is applied before every weight layer, is approved to be mathematically equivalent to an approximation to the probabilistic deep Gaussian process ([Gal & Ghahramani 2016](https://arxiv.org/abs/1506.02157)). This simple idea has been shown to be effective for classification with small datasets and widely adopted in scenarios when efficient model uncertainty estimation is needed.

**DBAL**（深度贝叶斯主动学习；[Gal et al. 2017](https://arxiv.org/abs/1703.02910)）使用 MC dropout 近似贝叶斯神经网络，从而学习模型权重的分布。在他们的实验中，MC dropout 的表现优于随机基线和平均标准差（Mean STD），与变异比和熵测量相似。

> **DBAL** (Deep Bayesian active learning; [Gal et al. 2017](https://arxiv.org/abs/1703.02910)) approximates Bayesian neural networks with MC dropout such that it learns a distribution over model weights. In their experiment, MC dropout performed better than random baseline and mean standard deviation (Mean STD), similarly to variation ratios and entropy measurement.

![Active learning results of DBAL on MNIST. (Image source: Gal et al. 2017 ).](https://lilianweng.github.io/posts/2022-02-20-active-learning/DBAL-exp.png)

[Beluch et al. (2018)](https://openaccess.thecvf.com/content_cvpr_2018/papers/Beluch_The_Power_of_CVPR_2018_paper.pdf) 将基于集成的方法与 MC dropout 进行了比较，发现朴素集成（即分别独立训练多个模型）和变异比的组合比其他方法产生了更好的校准预测。然而，朴素集成*非常*昂贵，因此他们探索了一些更便宜的替代方案：

> [Beluch et al. (2018)](https://openaccess.thecvf.com/content_cvpr_2018/papers/Beluch_The_Power_of_CVPR_2018_paper.pdf) compared ensemble-based models with MC dropout and found that the combination of naive ensemble (i.e. train multiple models separately and independently) and variation ratio yields better calibrated predictions than others. However, naive ensembles are *very* expensive, so they explored a few alternative cheaper options:

• 快照集成：使用循环学习率调度来训练隐式集成，使其收敛到不同的局部最小值。

• 鼓励多样性集成（DEE）：使用经过少量 epoch 训练的基础网络作为 $n$ 不同网络的初始化，每个网络都通过 dropout 进行训练以鼓励多样性。

• 分头法：一个基础模型有多个头，每个头对应一个分类器。

英文原文：

• Snapshot ensemble: Use a cyclic learning rate schedule to train an implicit ensemble such that it converges to different local minima.

• Diversity encouraging ensemble (DEE): Use a base network trained for a small number of epochs as initialization for $n$ different networks, each trained with dropout to encourage diversity.

• Split head approach: One base model has multiple heads, each corresponding to one classifier.

不幸的是，上述所有廉价的隐式集成方法都比朴素集成表现更差。考虑到计算资源的限制，MC dropout 仍然是一个相当不错且经济的选择。自然地，人们也尝试结合集成和 MC dropout ([Pop & Fulop 2018](https://arxiv.org/abs/1811.03897)) 以通过随机集成获得一些额外的性能增益。

> Unfortunately all the cheap implicit ensemble options above perform worse than naive ensembles. Considering the limit on computational resources, MC dropout is still a pretty good and economical choice. Naturally, people also try to combine ensemble and MC dropout ([Pop & Fulop 2018](https://arxiv.org/abs/1811.03897)) to get a bit of additional performance gain by stochastic ensemble.

##### 参数空间中的不确定性

> Uncertainty in Parameter Space

**Bayes-by-backprop** ([Blundell 等人 2015](https://arxiv.org/abs/1505.05424)) 直接测量神经网络中的权重不确定性。该方法维护一个关于权重 $\mathbf{w}$ 的概率分布，该分布被建模为变分分布 $q(\mathbf{w} \vert \theta)$，因为真实的后验分布 $p(\mathbf{w} \vert \mathcal{D})$ 无法直接处理。损失函数旨在最小化 $q(\mathbf{w} \vert \theta)$ 和 $p(\mathbf{w} \vert \mathcal{D})$ 之间的 KL 散度，

英文原文：Bayes-by-backprop ([Blundell et al. 2015](https://arxiv.org/abs/1505.05424)) measures weight uncertainty in neural networks directly. The method maintains a probability distribution over the weights 

$\mathbf{w}$, which is modeled as a variational distribution 

$q(\mathbf{w} \vert \theta)$ since the true posterior 

$p(\mathbf{w} \vert \mathcal{D})$ is not tractable directly. The loss is to minimize the KL divergence between 

$q(\mathbf{w} \vert \theta)$ and 

$p(\mathbf{w} \vert \mathcal{D})$,

$$
\begin{aligned}
\mathcal{L}(\theta)
&= \text{KL}[q(\mathbf{w}\vert\theta) \| p(\mathbf{w} \vert \mathcal{D})] \\ 
&= \int q(\mathbf{w}\vert\theta) \log \frac{q(\mathbf{w}\vert\theta)}{p(\mathbf{w}) p(\mathcal{D}\vert \mathbf{w})} d\mathbf{w} \\ 
&= \text{KL}[q(\mathbf{w}\vert\theta) \| p(w)] - \mathbb{E}_{q(\mathbf{w}\vert\theta)} [\log p(\mathcal{D} \vert \mathbf{w})] \\
&\approx \log q(\mathbf{w} \vert \theta) - \log p(\mathbf{w}) p(\mathcal{D}\vert \mathbf{w}) & \text{; monte carlo sampling; }q(\mathbf{w} \vert \theta)\text{ & }p(\mathbf{w})\text{ are close.}
\end{aligned}
$$

变分分布 $q$ 通常是具有对角协方差的高斯分布，每个权重都从 $\mathcal{N}(\mu_i, \sigma_i^2)$ 中采样。为了确保 $\sigma_i$ 的非负性，它通过 softplus 进一步参数化，$\sigma_i = \log(1 + \exp(\rho_i))$ 其中变分参数为 $\theta = \{\mu_i , \rho_i\}^d_{i=1}$。

> The variational distribution $q$ is typically a Gaussian with diagonal covariance and each weight is sampled from $\mathcal{N}(\mu_i, \sigma_i^2)$. To ensure non-negativity of $\sigma_i$, it is further parameterized via softplus, $\sigma_i = \log(1 + \exp(\rho_i))$ where the variational parameters are $\theta = \{\mu_i , \rho_i\}^d_{i=1}$.

Bayes-by-backprop 的过程可以总结为：

> The process of Bayes-by-backprop can be summarized as:

1\. 示例 $\epsilon \sim \mathcal{N}(0, I)$

2\. 令 $\mathbf{w} = \mu + \log(1+ \exp(\rho)) \circ \epsilon$

3\. 令 $\theta = (\mu, \rho)$

4\. 令 $f(\mathbf{w}, \theta) = \log q(\mathbf{w} \vert \theta) - \log p(\mathbf{w})p(\mathcal{D}\vert \mathbf{w})$

5\. 计算 $f(\mathbf{w}, \theta)$ 相对于 $\mu$ 和 $\rho$ 的梯度，然后更新 $\theta$。

6\. 不确定性通过在推理过程中采样不同的模型权重来衡量。

英文原文：

1\. Sample $\epsilon \sim \mathcal{N}(0, I)$

2\. Let $\mathbf{w} = \mu + \log(1+ \exp(\rho)) \circ \epsilon$

3\. Let $\theta = (\mu, \rho)$

4\. Let $f(\mathbf{w}, \theta) = \log q(\mathbf{w} \vert \theta) - \log p(\mathbf{w})p(\mathcal{D}\vert \mathbf{w})$

5\. Calculate the gradient of $f(\mathbf{w}, \theta)$ w.r.t. to $\mu$ and $\rho$ and then update $\theta$.

6\. Uncertainty is measured by sampling different model weights during inference.

##### 损失预测

> Loss Prediction

损失目标指导模型训练。低损失值表明模型可以做出良好且准确的预测。[Yoo & Kweon (2019)](https://arxiv.org/abs/1905.03677)设计了一个**损失预测模块**，用于预测未标记输入的损失值，以此估计模型在给定数据上的预测质量。如果损失预测模块对数据样本做出不确定的预测（高损失值），则选择这些样本。损失预测模块是一个带有 dropout 的简单 MLP，它将多个中间层特征作为输入，并在全局平均池化后将它们连接起来。

> The loss objective guides model training. A low loss value indicates that a model can make good and accurate predictions. [Yoo & Kweon (2019)](https://arxiv.org/abs/1905.03677) designed a **loss prediction module** to predict the loss value for unlabeled inputs, as an estimation of how good a model prediction is on the given data. Data samples are selected if the loss prediction module makes uncertain predictions (high loss value) for them. The loss prediction module is a simple MLP with dropout, that takes several intermediate layer features as inputs and concatenates them after a global average pooling.

![Use the model with a loss prediction module to do active learning selection. (Image source: Yoo & Kweon 2019 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/active-learning-loss-prediction.png)

设$\hat{l}$是损失预测模块的输出，$l$是真实损失。在训练损失预测模块时，简单的 MSE 损失$=(l - \hat{l})^2$不是一个好的选择，因为随着模型学习表现得更好，损失会随时间减少。一个好的学习目标应该独立于目标损失的尺度变化。他们转而依赖样本对的比较。在每个大小为$b$的批次中，有$b/2$对样本$(\mathbf{x}_i, \mathbf{x}_j)$，并且损失预测模型有望正确预测哪个样本具有更大的损失。

> Let $\hat{l}$ be the output of the loss prediction module and $l$ be the true loss. When training the loss prediction module, a simple MSE loss $=(l - \hat{l})^2$ is not a good choice, because the loss decreases in time as the model learns to behave better. A good learning objective should be independent of the scale changes of the target loss. They instead rely on the comparison of sample pairs. Within each batch of size $b$, there are $b/2$ pairs of samples $(\mathbf{x}_i, \mathbf{x}_j)$ and the loss prediction model is expected to correctly predict which sample has a larger loss.

$$
\begin{aligned}
\mathcal{L}_\text{loss}(\mathbf{x}_i, \mathbf{x}_j) &= \max\big( 0, -\mathbb{1}(l(\mathbf{x}_i), l(\mathbf{x}_j)) \cdot (\hat{l}(\mathbf{x}_i) - \hat{l}(\mathbf{x}_j)) + \epsilon \big) \\ 
\text{where } \mathbb{1}(l_i, l_j) &= \begin{cases} +1 & \text{if }l_i > l_j \\ -1 & \text{otherwise} \end{cases} 
\end{aligned}
$$

其中$\epsilon$是一个预定义的正边际常数。

> where $\epsilon$ is a predefined positive margin constant.

在三个视觉任务的实验中，基于损失预测的主动学习选择表现优于随机基线、基于熵的采集和[core-set](https://lilianweng.github.io/posts/2022-02-20-active-learning/#core-sets-approach)。

> In experiments on three vision tasks, active learning selection based on the loss prediction performs better than random baseline, entropy based acquisition and [core-set](https://lilianweng.github.io/posts/2022-02-20-active-learning/#core-sets-approach).

![Active learning results of loss prediction module based selection, in comparison with other approaches. (Image source: Yoo & Kweon 2019 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/active-learning-loss-prediction-exp.png)

##### 对抗性设置

> Adversarial Setup

[Sinha et al. (2019)](https://arxiv.org/abs/1904.00370)提出了一种类似 GAN 的设置，名为**VAAL**（变分对抗主动学习），其中训练一个判别器来区分未标记数据和已标记数据。有趣的是，VAAL 中的主动学习采集标准不依赖于任务性能。

> [Sinha et al. (2019)](https://arxiv.org/abs/1904.00370) proposed a GAN-like setup, named **VAAL** (Variational Adversarial Active Learning), where a discriminator is trained to distinguish unlabeled data from labeled data. Interestingly, active learning acquisition criteria does not depend on the task performance in VAAL.

![Illustration of VAAL (Variational adversarial active learning). (Image source: Sinha et al. 2019 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/VAAL.png)

• $\beta$ -VAE 分别为已标记和未标记数据学习一个潜在特征空间$\mathbf{z}^l \cup \mathbf{z}^u$，旨在*欺骗*判别器$D(.)$，使其认为所有数据点都来自已标记池；

• 判别器$D(.)$根据潜在表示$\mathbf{z}$预测样本是否已标记（1）或未标记（0）。VAAL 选择判别器分数低的未标记样本，这表明这些样本与先前已标记的样本有足够的差异。

英文原文：

• The $\beta$ -VAE learns a latent feature space $\mathbf{z}^l \cup \mathbf{z}^u$, for labeled and unlabeled data respectively, aiming to *trick* the discriminator $D(.)$ that all the data points are from the labeled pool;

• The discriminator $D(.)$ predicts whether a sample is labeled (1) or not (0) based on a latent representation $\mathbf{z}$. VAAL selects unlabeled samples with low discriminator scores, which indicates that those samples are sufficiently different from previously labeled ones.

VAAL 中 VAE 表示学习的损失包含重建部分（最小化给定样本的 ELBO）和对抗部分（已标记和未标记数据都来自相同的概率分布$q_\phi$）：

> The loss for VAE representation learning in VAAL contains both a reconstruction part (minimizing the ELBO of given samples) and an adversarial part (labeled and unlabeled data is drawn from the same probability distribution $q_\phi$):

$$
\begin{aligned}
\mathcal{L}_\text{VAE} &= \lambda_1 \mathcal{L}^\text{rec}_\text{VAE} + \lambda_2 \mathcal{L}^\text{adv}_\text{VAE} \\
\mathcal{L}^\text{rec}_\text{VAE} &= \mathbb{E}[\log p_\theta(\mathbf{x}^l \vert \mathbf{z}^l)] - \beta \text{KL}(q_\phi(\mathbf{z}^l \vert \mathbf{x}^l) \| p(\mathbf{\tilde{z}})) + \mathbb{E}[\log p_\theta(\mathbf{u} \vert \mathbf{z}^u)] - \beta \text{KL}(q_\phi(\mathbf{z}^u \vert \mathbf{u}) \| p(\mathbf{\tilde{z}})) \\
\mathcal{L}^\text{adv}_\text{VAE} &= - \mathbb{E}[\log D(q_\phi (\mathbf{z}^l \vert \mathbf{x}^l))] - \mathbb{E}[\log D(q_\phi(\mathbf{z}^u \vert \mathbf{u}))]
\end{aligned}
$$

其中$p(\mathbf{\tilde{z}})$是预定义的先验单位高斯分布，$\beta$是拉格朗日参数。

> where $p(\mathbf{\tilde{z}})$ is a unit Gaussian as a predefined prior and $\beta$ is the Lagrangian parameter.

判别器损失为：

> The discriminator loss is:

$$
\mathcal{L}_D = -\mathbb{E}[\log D(q_\phi (\mathbf{z}^l \vert \mathbf{x}^l))] - \mathbb{E}[\log (1 - D(q_\phi (\mathbf{z}^u \vert \mathbf{u})))]
$$

![Experiment results of VAAL (variational adversarial active learning) on several image classification tasks. (Image source: Sinha et al. 2019](https://lilianweng.github.io/posts/2022-02-20-active-learning/VAAL-exp.png)

消融研究表明，联合训练 VAE 和判别器至关重要。他们的结果对有偏的初始标记池、不同的标记预算和有噪声的预言机都具有鲁棒性。

> Ablation studies showed that jointly training VAE and discriminator is critical. Their results are robust to the biased initial labeled pool, different labeling budgets and noisy oracle.

**MAL**（极小极大主动学习；[Ebrahimiet al. 2021](https://arxiv.org/abs/2012.10467)）是 VAAL 的一个扩展。MAL 框架由一个熵最小化的特征编码网络 `F` 和一个熵最大化的分类器 `C` 组成。这种极小极大设置减少了标记数据和未标记数据之间的分布差距。

英文原文：MAL (Minimax Active Learning; [Ebrahimiet al. 2021](https://arxiv.org/abs/2012.10467)) is an extension of VAAL. The MAL framework consists of an entropy minimizing feature encoding network `F` followed by an entropy maximizing classifier `C`. This minimax setup reduces the distribution gap between labeled and unlabeled data.

![Illustration of the MAL (minimax active learning) framework. (Image source: Ebrahimiet al. 2021 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/MAL.png)

一个特征编码器 $F$ 将样本编码成一个 $\ell_2$ 归一化的 $d$ 维潜在向量。假设有 $K$ 个类别，分类器 $C$ 由 $\mathbf{W} \in \mathbb{R}^{d \times K}$ 参数化。

> A feature encoder $F$ encodes a sample into a $\ell_2$ -normalized $d$ -dimensional latent vector. Assuming there are $K$ classes, a classifier $C$ is parameterized by $\mathbf{W} \in \mathbb{R}^{d \times K}$.

（1）首先，$F$ 和 $C$ 通过简单的交叉熵损失在标记样本上进行训练，以获得良好的分类结果，

> (1) First $F$ and $C$ are trained on labeled samples by a simple cross entropy loss to achieve good classification results,

$$
\mathcal{L}_\text{CE} = -\mathbb{E}_{(\mathbf{x}^l, y) \sim \mathcal{X}} \sum_{k=1}^K \mathbb{1}[k=y] \log\Big( \sigma(\frac{1}{T} \frac{\mathbf{W}^\top F\big(\mathbf{x}^l)}{\|F(\mathbf{x}^l)\|}\big) \Big)
$$

（2）在未标记样本上训练时，MAL 依赖于一个*极小极大*博弈设置

> (2) When training on the unlabeled examples, MAL relies on a *minimax* game setup

$$
\begin{aligned}
\mathcal{L}_\text{Ent} &= -\sum^K_{k=1} p(y=k \vert \mathbf{u}) \log p(y=k\vert \mathbf{u}) \\
\theta^*_F, \theta^*_C &= \min_F\max_C \mathcal{L}_\text{Ent} \\
\theta_F &\gets \theta_F - \alpha_1 \nabla \mathcal{L}_\text{Ent} \\
\theta_C &\gets \theta_C + \alpha_2 \nabla \mathcal{L}_\text{Ent}
\end{aligned}
$$

其中，

> where,

• 首先，最小化 $F$ 中的熵鼓励与相似预测标签相关的未标记样本具有相似的特征。

• 最大化 $C$ 中的熵以对抗方式使预测遵循更均匀的类别分布。（我在这里的理解是，由于未标记样本的真实标签未知，我们不应立即优化分类器以最大化预测标签。）

英文原文：

• First, minimizing the entropy in $F$ encourages unlabeled samples associated with similar predicted labels to have similar features.

• Maximizing the entropy in $C$ adversarially makes the prediction to follow a more uniform class distribution. (My understanding here is that because the true label of an unlabeled sample is unknown, we should not optimize the classifier to maximize the predicted labels just yet.)

判别器以与 VAAL 中相同的方式进行训练。

> The discriminator is trained in the same way as in VAAL.

MAL 中的采样策略同时考虑了多样性和不确定性：

> Sampling strategy in MAL considers both diversity and uncertainty:

• 多样性：$D$ 的分数表示样本与先前见过示例的相似程度。分数越接近 0 越有利于选择不熟悉的数据点。

• 不确定性：使用 $C$ 获得的熵。熵分数越高表示模型尚未能做出自信的预测。

英文原文：

• Diversity: the score of $D$ indicates how similar a sample is to previously seen examples. A score closer to 0 is better to select unfamiliar data points.

• Uncertainty: use the entropy obtained by $C$. A higher entropy score indicates that the model cannot make a confident prediction yet.

实验将 MAL 与随机、熵、核心集、BALD 和 VAAL 基线在图像分类和分割任务上进行了比较。结果看起来相当有力。

> The experiments compared MAL to random, entropy, core-set, BALD and VAAL baselines, on image classification and segmentation tasks. The results look pretty strong.

![Performance of MAL on ImageNet. (Table source: Ebrahimiet al. 2021 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/MAL-exp.png)

**CAL**（对比主动学习；[Margatina et al. 2021](https://arxiv.org/abs/2109.03764)）旨在选择[对比](https://lilianweng.github.io/posts/2021-05-31-contrastive/)示例。如果两个具有不同标签的数据点共享相似的网络表示$\Phi(.)$，它们在 CAL 中被视为对比示例。给定一对对比示例$(\mathbf{x}_i, \mathbf{x}_j)$，它们应该

英文原文：CAL (Contrastive Active Learning; [Margatina et al. 2021](https://arxiv.org/abs/2109.03764)) intends to select [contrastive](https://lilianweng.github.io/posts/2021-05-31-contrastive/) examples. If two data points with different labels share similar network representations 

$\Phi(.)$, they are considered as contrastive examples in CAL. Given a pair of contrastive examples 

$(\mathbf{x}_i, \mathbf{x}_j)$, they should

$$
d(\Phi(\mathbf{x}_i), \Phi(\mathbf{x}_j)) < \epsilon \quad\text{and}\quad \text{KL}(p(y\vert \mathbf{x}_i) \| p(y\vert \mathbf{x}_j)) \rightarrow \infty
$$

给定一个未标记的样本$\mathbf{x}$，CAL 运行以下过程：

> Given an unlabeled sample $\mathbf{x}$, CAL runs the following process:

1\. 在已标记样本中，选择模型特征空间中前 $k$ 个最近邻，$\{(\mathbf{x}^l_i, y_i\}_{i=1}^M \subset \mathcal{X}$。

2\. 计算 $\mathbf{x}$ 和 $\{\mathbf{x}^l\}$ 中每个样本的模型输出概率之间的 KL 散度。$\mathbf{x}$ 的对比分数是这些 KL 散度值的平均值：$s(\mathbf{x}) = \frac{1}{M} \sum_{i=1}^M \text{KL}(p(y \vert \mathbf{x}^l_i | p(y \vert \mathbf{x}))$。

3\. 选择具有*高对比分数*的样本进行主动学习。

英文原文：

1\. Select the top $k$ nearest neighbors in the model feature space among the labeled samples, $\{(\mathbf{x}^l_i, y_i\}_{i=1}^M \subset \mathcal{X}$.

2\. Compute the KL divergence between the model output probabilities of $\mathbf{x}$ and each in $\{\mathbf{x}^l\}$. The contrastive score of $\mathbf{x}$ is the average of these KL divergence values: $s(\mathbf{x}) = \frac{1}{M} \sum_{i=1}^M \text{KL}(p(y \vert \mathbf{x}^l_i | p(y \vert \mathbf{x}))$.

3\. Samples with *high contrastive scores* are selected for active learning.

在各种分类任务中，CAL 的实验结果与熵基线相似。

> On a variety of classification tasks, the experiment results of CAL look similar to the entropy baseline.

#### 衡量代表性

> Measuring Representativeness

##### 核心集方法

> Core-sets Approach

**核心集**是计算几何中的一个概念，指一小组点，它们近似于一个更大的点集的形状。近似度可以通过一些几何度量来捕捉。在主动学习中，我们期望在核心集上训练的模型与在整个数据点上训练的模型表现相当。

> A **core-set** is a concept in computational geometry, referring to a small set of points that approximates the shape of a larger point set. Approximation can be captured by some geometric measure. In the active learning, we expect a model that is trained over the core-set to behave comparably with the model on the entire data points.

[Sener & Savarese (2018)](https://arxiv.org/abs/1708.00489) 将主动学习视为一个核心集选择问题。假设在训练期间总共有 $N$ 个可访问的样本。在主动学习期间，每隔一个时间步 $t$ 会有一小组数据点被标记，表示为 $\mathcal{S}^{(t)}$。学习目标的上限可以写成如下形式，其中*核心集损失*定义为已标记样本的平均经验损失与包括未标记样本在内的整个数据集的损失之间的差值。

> [Sener & Savarese (2018)](https://arxiv.org/abs/1708.00489) treats active learning as a core-set selection problem. Let’s say, there are $N$ samples in total accessible during training. During active learning, a small set of data points get labeled at every time step $t$, denoted as $\mathcal{S}^{(t)}$. The upper bound of the learning objective can be written as follows, where the *core-set loss* is defined as the difference between average empirical loss over the labeled samples and the loss over the entire dataset including unlabelled ones.

$$
\begin{aligned}
\mathbb{E}_{(\mathbf{x}, y) \sim p} [\mathcal{L}(\mathbf{x}, y)]
\leq& \bigg\vert \mathbb{E}_{(\mathbf{x}, y) \sim p} [\mathcal{L}(\mathbf{x}, y)] - \frac{1}{N} \sum_{i=1}^N \mathcal{L}(\mathbf{x}_i, y_i) \bigg\vert & \text{; Generalization error}\\
+& \frac{1}{\vert \mathcal{S}^{(t)} \vert} \sum_{j=1}^{\vert \mathcal{S}^{(t)} \vert} \mathcal{L}(\mathbf{x}^l_j, y_j) & \text{; Training error}\\
+& \bigg\vert \frac{1}{N} \sum_{i=1}^N \mathcal{L}(\mathbf{x}_i, y_i) - \frac{1}{\vert \mathcal{S}^{(t)} \vert} \sum_{j=1}^{\vert \mathcal{S}^{(t)} \vert} \mathcal{L}(\mathbf{x}^l_j, y_j) \bigg\vert & \text{; Core-set error}
\end{aligned}
$$

那么主动学习问题可以重新定义为：

> Then the active learning problem can be redefined as:

$$
\min_{\mathcal{S}^{(t+1)} : \vert \mathcal{S}^{(t+1)} \vert \leq b} \bigg\vert \frac{1}{N}\sum_{i=1}^N \mathcal{L}(\mathbf{x}_i, y_i) - \frac{1}{\vert \mathcal{S}^{(t)} \cup \mathcal{S}^{(t+1)} \vert} \sum_{j=1}^{\vert \mathcal{S}^{(t)} \cup \mathcal{S}^{(t+1)} \vert} \mathcal{L}(\mathbf{x}^l_j, y_j) \bigg\vert
$$

它等价于[k-中心问题](https://en.wikipedia.org/wiki/Metric_k-center)：选择$b$个中心点，使得数据点与其最近中心点之间的最大距离最小化。这个问题是NP难的。一个近似解依赖于贪婪算法。

> It is equivalent to [the k-Center problem](https://en.wikipedia.org/wiki/Metric_k-center): choose $b$ center points such that the largest distance between a data point and its nearest center is minimized. This problem is NP-hard. An approximate solution depends on the greedy algorithm.

![Active learning results of core-sets algorithm in comparison with several common baselines on CIFAR-10, CIFAR-100, SVHN. (Image source: Sener & Savarese 2018 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/core-sets-exp.png)

当类别数量较少时，它在图像分类任务上表现良好。当类别数量变得很大或数据维度增加（“维度灾难”）时，核心集方法的效果会降低（[Sinha et al. 2019](https://arxiv.org/abs/1904.00370)）。

> It works well on image classification tasks when there is a small number of classes. When the number of classes grows to be large or the data dimensionality increases (“curse of dimensionality”), the core-set method becomes less effective ([Sinha et al. 2019](https://arxiv.org/abs/1904.00370)).

由于核心集选择成本高昂，[Coleman et al. (2020)](https://arxiv.org/abs/1906.11829)尝试使用一个较弱的模型（例如，更小、更弱的架构，未完全训练），并发现经验上使用较弱模型作为代理可以显著缩短训练模型和选择样本的每个重复数据选择周期，而不会对最终误差造成太大损害。他们的方法被称为**SVP**（Selection via Proxy）。

> Because the core-set selection is expensive, [Coleman et al. (2020)](https://arxiv.org/abs/1906.11829) experimented with a weaker model (e.g. smaller, weaker architecture, not fully trained) and found that empirically using a weaker model as a proxy can significantly shorten each repeated data selection cycle of training models and selecting samples, without hurting the final error much. Their method is referred to as **SVP** (Selection via Proxy).

##### 多样化梯度嵌入

> Diverse Gradient Embedding

**BADGE**（Batch Active learning by Diverse Gradient Embeddings；[Ash et al. 2020](https://arxiv.org/abs/1906.03671)）在梯度空间中跟踪模型不确定性和数据多样性。不确定性通过网络最后一层相对于梯度的幅度来衡量，多样性则通过在梯度空间中分布的多种样本集来捕获。

> **BADGE** (Batch Active learning by Diverse Gradient Embeddings; [Ash et al. 2020](https://arxiv.org/abs/1906.03671)) tracks both model uncertainty and data diversity in the gradient space. Uncertainty is measured by the gradient magnitude w.r.t. the final layer of the network and diversity is captured by a diverse set of samples that span in the gradient space.

• 不确定性。给定一个未标记的样本$\mathbf{x}$，BADGE 首先计算预测值$\hat{y}$和梯度$g_\mathbf{x}$在$(\mathbf{x}, \hat{y})$上的损失相对于最后一层参数的梯度。他们观察到$g_\mathbf{x}$保守地估计了样本对模型学习的影响，并且高置信度样本的梯度嵌入往往幅度较小。

• 多样性。给定许多样本的许多梯度嵌入，$g_\mathbf{x}$，BADGE 运行 [k-means++](https://en.wikipedia.org/wiki/K-means%2B%2B) 以相应地采样数据点。

英文原文：

• Uncertainty. Given an unlabeled sample $\mathbf{x}$, BADGE first computes the prediction $\hat{y}$ and the gradient $g_\mathbf{x}$ of the loss on $(\mathbf{x}, \hat{y})$ w.r.t. the last layer’s parameters. They observed that the norm of $g_\mathbf{x}$ conservatively estimates the example’s influence on the model learning and high-confidence samples tend to have gradient embeddings of small magnitude.

• Diversity. Given many gradient embeddings of many samples, $g_\mathbf{x}$, BADGE runs [k-means++](https://en.wikipedia.org/wiki/K-means%2B%2B) to sample data points accordingly.

![Algorithm of BADGE (batch active learning by diverse gradient embeddings). (Image source: Ash et al. 2020 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/BADGE-algo.png)

#### 衡量训练效果

> Measuring Training Effects

##### 量化模型变化

> Quantify Model Changes

[Settles 等人 (2008)](https://papers.nips.cc/paper/2007/hash/a1519de5b5d44b31a01de013b9b51a80-Abstract.html)引入了一种主动学习查询策略，名为**EGL**（期望梯度长度）。其动机是找到那些如果标签已知，能够对模型触发最大更新的样本。

> [Settles et al. (2008)](https://papers.nips.cc/paper/2007/hash/a1519de5b5d44b31a01de013b9b51a80-Abstract.html) introduced an active learning query strategy, named **EGL** (Expected Gradient Length). The motivation is to find samples that can trigger the greatest update on the model if their labels are known.

令 $\nabla \mathcal{L}(\theta)$ 为损失函数相对于模型参数的梯度。具体来说，给定一个未标记样本 $\mathbf{x}_i$，我们需要计算假设标签为 $y \in \mathcal{Y}$，$\nabla \mathcal{L}^{(y)}(\theta)$ 时的梯度。由于真实标签 $y_i$ 未知，EGL 依赖于当前模型信念来计算期望梯度变化：

> Let $\nabla \mathcal{L}(\theta)$ be the gradient of the loss function with respect to the model parameters. Specifically, given an unlabeled sample $\mathbf{x}_i$, we need to calculate the gradient assuming the label is $y \in \mathcal{Y}$, $\nabla \mathcal{L}^{(y)}(\theta)$. Because the true label $y_i$ is unknown, EGL relies on the current model belief to compute the expected gradient change:

$$
\text{EGL}(\mathbf{x}_i) = \sum_{y_i \in \mathcal{Y}} p(y=y_i \vert \mathbf{x}) \|\nabla \mathcal{L}^{(y_i)}(\theta)\|
$$

**BALD**（基于分歧的贝叶斯主动学习；[Houlsby 等人 2011](https://arxiv.org/abs/1112.5745)）旨在识别样本以最大化模型权重的信息增益，这等同于最大化预期后验熵的减少。

> **BALD** (Bayesian Active Learning by Disagreement; [Houlsby et al. 2011](https://arxiv.org/abs/1112.5745)) aims to identify samples to maximize the information gain about the model weights, that is equivalent to maximize the decrease in expected posterior entropy.

$$
\begin{aligned}
I[\boldsymbol{\theta}, y \vert x,\mathcal{D}] 
&= H(\boldsymbol{\theta} \vert \mathcal{D}) - \mathbb{E}_{y \sim p(y \vert \boldsymbol{x}, \mathcal{D})} \big[ H(\boldsymbol{\theta} \vert y, \boldsymbol{x}, \mathcal{D}) \big] & \text{; Decrease in expected posterior entropy}\\ 
&= H(y \vert \boldsymbol{x}, \mathcal{D}) - \mathbb{E}_{\boldsymbol{\theta} \sim p(\boldsymbol{\theta} \vert \mathcal{D})} \big[ H(y \vert \boldsymbol{x}, \mathcal{\theta}) \big]
\end{aligned}
$$

其潜在的解释是“寻找 $\mathbf{x}$，模型对 $y$ 边际上最不确定（高 $H(y \vert \mathbf{x}, \mathcal{D})$），但参数的个体设置是确定的（低 $H(y \vert \mathbf{x}, \boldsymbol{\theta})$）。”换句话说，每个单独的后验抽样都是确定的，但一系列抽样却带有不同的意见。

> The underlying interpretation is to “seek $\mathbf{x}$ for which the model is marginally most uncertain about $y$ (high $H(y \vert \mathbf{x}, \mathcal{D})$), but for which individual settings of the parameters are confident (low $H(y \vert \mathbf{x}, \boldsymbol{\theta})$).” In other words, each individual posterior draw is confident but a collection of draws carry diverse opinions.

BALD 最初是为单个样本提出的，[Kirsch 等人 (2019)](https://arxiv.org/abs/1906.08158) 将其扩展到批处理模式下工作。

> BALD was originally proposed for an individual sample and [Kirsch et al. (2019)](https://arxiv.org/abs/1906.08158) extended it to work in batch mode.

##### 遗忘事件

> Forgetting Events

为了调查神经网络是否倾向于**遗忘**先前学习到的信息，[Mariya Toneva 等人 (2019)](https://arxiv.org/abs/1812.05159) 设计了一个实验：他们跟踪训练过程中每个样本的模型预测，并计算每个样本从正确分类到错误分类或反之的转换。然后样本可以相应地分类，

> To investigate whether neural networks have a tendency to **forget** previously learned information, [Mariya Toneva et al. (2019)](https://arxiv.org/abs/1812.05159) designed an experiment: They track the model prediction for each sample during the training process and count the transitions for each sample from being classified correctly to incorrectly or vice-versa. Then samples can be categorized accordingly,

- *可遗忘*（冗余）样本：如果类别标签在训练周期中发生变化。
- *不可遗忘*样本：如果类别标签分配在训练周期中保持一致。这些样本一旦学习就不会被遗忘。

> • *Forgettable* (redundant) samples: If the class label changes across training epochs.
> • *Unforgettable* samples: If the class label assignment is consistent across training epochs. Those samples are never forgotten once learned.

他们发现有大量不可遗忘的例子，一旦学习就不会被遗忘。带有噪声标签的例子或具有“不常见”特征（视觉上难以分类）的图像是遗忘最多的例子。实验经验性地验证了不可遗忘的例子可以安全移除而不会损害模型性能。

> They found that there are a large number of unforgettable examples that are never forgotten once learnt. Examples with noisy labels or images with “uncommon” features (visually complicated to classify) are among the most forgotten examples. The experiments empirically validated that unforgettable examples can be safely removed without compromising model performance.

在实现中，遗忘事件仅在样本包含在当前训练批次中时才计数；也就是说，他们计算同一示例在后续小批次中出现时的遗忘情况。每个样本的遗忘事件数量在不同随机种子下相当稳定，并且可遗忘的例子有较小的倾向在训练后期首次被学习。遗忘事件也被发现在整个训练期间和不同架构之间是可迁移的。

> In the implementation, the forgetting event is only counted when a sample is included in the current training batch; that is, they compute forgetting across presentations of the same example in subsequent mini-batches. The number of forgetting events per sample is quite stable across different seeds and forgettable examples have a small tendency to be first-time learned later in the training. The forgetting events are also found to be transferable throughout the training period and between architectures.

如果我们假设模型在训练过程中改变预测是模型不确定性的一个指标，那么遗忘事件可以作为主动学习获取的信号。然而，对于未标记的样本，真实标签是未知的。[Bengar 等人 (2021)](https://arxiv.org/abs/2107.14707) 为此目的提出了一种新指标，称为**标签离散度**。让我们看看在训练过程中，$c^{\ast}$ 是输入 $\mathbf{x}$ 最常预测的标签，标签离散度衡量模型未将 $c^{\ast\ast}$ 分配给此样本的训练步骤的比例：

英文原文：Forgetting events can be used as a signal for active learning acquisition if we hypothesize a model changing predictions during training is an indicator of model uncertainty. However, ground truth is unknown for unlabeled samples. [Bengar et al. (2021)](https://arxiv.org/abs/2107.14707) proposed a new metric called label dispersion for such a purpose. Let’s see across the training time, 

$c^{\ast}$ is the most commonly predicted label for the input 

$\mathbf{x}$ and the label dispersion measures the fraction of training steps when the model does not assign 

$c^{\ast\ast}$ to this sample:

$$
\text{Dispersion}(\mathbf{x}) = 1 - \frac{f_\mathbf{x}}{T} \text{ where }
f_\mathbf{x} = \sum_{t=1}^T \mathbb{1}[\hat{y}_t = c^*], c^* = \arg\max_{c=1,\dots,C}\sum_{t=1}^T \mathbb{1}[\hat{y}_t = c]
$$

在他们的实现中，离散度在每个周期计算。如果模型始终将相同的标签分配给相同的样本，则标签离散度较低；如果预测经常变化，则标签离散度较高。标签离散度与网络不确定性相关，如 

> In their implementation, dispersion is computed at every epoch. Label dispersion is low if the model consistently assigns the same label to the same sample but high if the prediction changes often. Label dispersion is correlated with network uncertainty, as shown in 

![Label dispersion is correlated with network uncertainty. On the x-axis, data points are sorted by label dispersion scores. The y-axis is the model prediction accuracy when the model trys to infer the labels for those samples. (Image source: Bengar et al. 2021 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/label-dispersion-vs-uncertainty.png)

#### 混合

> Hybrid

在批处理模式下运行主动学习时，控制批次内的多样性非常重要。**启发式标注** (**SA**; [Yang et al. 2017](https://arxiv.org/abs/1706.04737)) 是一种两步混合策略，旨在选择高不确定性和高代表性的已标注样本。它利用从在已标注数据上训练的模型集成中获得的不确定性，并使用核心集来选择有代表性的数据样本。

> When running active learning in batch mode, it is important to control diversity within a batch. **Suggestive Annotation** (**SA**; [Yang et al. 2017](https://arxiv.org/abs/1706.04737)) is a two-step hybrid strategy, aiming to select both high uncertainty & highly representative labeled samples. It uses uncertainty obtained from an ensemble of models trained on the labeled data and core-sets for choosing representative data samples.

1\. 首先，SA 选择具有高不确定性分数的顶部 $K$ 图像，以形成候选池 $\mathcal{S}_c \subseteq \mathcal{S}_U$。不确定性通过多个模型在自举训练中的分歧来衡量。

2\. 下一步是找到一个具有最高代表性的子集 $\mathcal{S}_a \subseteq \mathcal{S}_c$。两个输入的特征向量之间的余弦相似度近似地表示它们有多相似。$\mathcal{S}_a$ 对于 $\mathcal{S}_U$ 的代表性反映了 $\mathcal{S}_a$ 能多好地代表 $\mathcal{S}_u$ 中的所有样本，定义为：

英文原文：

1\. First, SA selects top $K$ images with high uncertainty scores to form a candidate pool $\mathcal{S}_c \subseteq \mathcal{S}_U$. The uncertainty is measured as disagreement between multiple models training with bootstrapping.

2\. The next step is to find a subset $\mathcal{S}_a \subseteq \mathcal{S}_c$ with highest representativeness. The cosine similarity between feature vectors of two inputs approximates how similar they are. The representativeness of $\mathcal{S}_a$ for $\mathcal{S}_U$ reflects how well $\mathcal{S}_a$ can represent all the samples in $\mathcal{S}_u$, defined as:

$$
F(\mathcal{S}_a, \mathcal{S}_u) = \sum_{\mathbf{x}_j \in \mathcal{S}_u} f(\mathcal{S}_a, \mathbf{x}_j) = \sum_{\mathbf{x}_j \in \mathcal{S}_u} \max_{\mathbf{x}_i \in \mathcal{S}_a} \text{sim}(\mathbf{x}_i, \mathbf{x}_j)
$$

制定$\mathcal{S}_a \subseteq \mathcal{S}_c$，使用$k$数据点，使$F(\mathcal{S}_a, \mathcal{S}_u)$最大化，是最大集合覆盖问题的一个广义版本。它是NP难的，其最佳多项式时间近似算法是一种简单的贪婪方法。

> Formulating $\mathcal{S}_a \subseteq \mathcal{S}_c$ with $k$ data points that maximizes $F(\mathcal{S}_a, \mathcal{S}_u)$ is a generalized version of the maximum set cover problem. It is NP-hard and its best possible polynomial time approximation algorithm is a simple greedy method.

1\. 最初，$\mathcal{S}_a = \emptyset$和$F(\mathcal{S}_a, \mathcal{S}_u) = 0$。

2\. 然后，迭代地添加 $\mathbf{x}_i \in \mathcal{S}_c$，以最大化 $F(\mathcal{S}_a \cup I_i, \mathcal{S}_u)$ 在 $\mathcal{S}_a$ 上的值，直到 $\mathcal{S}_s$ 包含 $k$ 张图像。

英文原文：

1\. Initially, $\mathcal{S}_a = \emptyset$ and $F(\mathcal{S}_a, \mathcal{S}_u) = 0$.

2\. Then,  iteratively add $\mathbf{x}_i \in \mathcal{S}_c$ that maximizes $F(\mathcal{S}_a \cup I_i, \mathcal{S}_u)$ over $\mathcal{S}_a$, until $\mathcal{S}_s$ contains $k$ images.

[Zhdanov (2019)](https://arxiv.org/abs/1901.05954) 运行与 SA 类似的过程，但在步骤 2 中，它依赖于 $k$ -means 而不是核心集，其中候选池的大小是根据批次大小配置的。给定批次大小 $b$ 和常数 $beta$（介于 10 到 50 之间），它遵循以下步骤：

> [Zhdanov (2019)](https://arxiv.org/abs/1901.05954) runs a similar process as SA, but at step 2, it relies on $k$ -means instead of core-set, where the size of the candidate pool is configured relative to the batch size. Given batch size $b$ and a constant $beta$ (between 10 and 50), it follows these steps:

1\. 在标记数据上训练分类器；

2\. 衡量每个未标记示例的信息量（例如，使用不确定性指标）；

3\. 预过滤前 $\beta b \geq b$ 个信息量最大的示例；

4\. 将 $\beta b$ 个示例聚类成 $B$ 个簇；

5\. 选择 $b$ 个最接近簇中心的样本，用于本轮主动学习。

英文原文：

1\. Train a classifier on the labeled data;

2\. Measure informativeness of every unlabeled example (e.g. using uncertainty metrics);

3\. Prefilter top $\beta b \geq b$ most informative examples;

4\. Cluster $\beta b$ examples into $B$ clusters;

5\. Select $b$ different examples closest to the cluster centers for this round of active learning.

主动学习可以与 [半监督学习](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/) 进一步结合，以节省预算。**CEAL**（Cost-Effective Active Learning；[Yang et al. 2017](https://arxiv.org/abs/1701.03551)）并行运行两项任务：

> Active learning can be further combined with [semi-supervised learning](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/) to save the budget. **CEAL** (Cost-Effective Active Learning; [Yang et al. 2017](https://arxiv.org/abs/1701.03551)) runs two things in parallel:

1\. 通过主动学习选择不确定样本并进行标注；

2\. 选择预测置信度最高的样本并为其分配 [伪标签](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#pseudo-labeling)。置信度预测通过预测熵是否低于阈值 $\delta$ 来判断。随着模型随时间推移变得更好，阈值 $\delta$ 也会随时间衰减。

英文原文：

1\. Select uncertain samples via active learning and get them labeled;

2\. Select samples with the most confident prediction and assign them [pseudo labels](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#pseudo-labeling). The confidence prediction is judged by whether the prediction entropy is below a threshold $\delta$. As the model is getting better in time, the threshold $\delta$ decays in time as well.

![Illustration of CEAL (cost-effective active learning). (Image source: Yang et al. 2017 )](https://lilianweng.github.io/posts/2022-02-20-active-learning/CEAL.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2022年2月). Learning with not enough data part 2: active learning. Lil’Log. https://lilianweng.github.io/posts/2022-02-20-active-learning/.

> Weng, Lilian. (Feb 2022). Learning with not enough data part 2: active learning. Lil’Log. https://lilianweng.github.io/posts/2022-02-20-active-learning/.

或

> Or

```
@article{weng2022active,
  title   = "Learning with not Enough Data Part 2: Active Learning",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2022",
  month   = "Feb",
  url     = "https://lilianweng.github.io/posts/2022-02-20-active-learning/"
}
```

### 参考文献

> References

[1] Burr Settles. [主动学习文献综述。](https://burrsettles.com/pub/settles.activelearning.pdf) University of Wisconsin, Madison, 52(55-66):11, 2010.

> [1] Burr Settles. [Active learning literature survey.](https://burrsettles.com/pub/settles.activelearning.pdf) University of Wisconsin, Madison, 52(55-66):11, 2010.

[2] [https://jacobgil.github.io/deeplearning/activelearning](https://jacobgil.github.io/deeplearning/activelearning)

> [2] [https://jacobgil.github.io/deeplearning/activelearning](https://jacobgil.github.io/deeplearning/activelearning)

[3] Yang et al. [“深度图像分类的成本效益主动学习”](https://arxiv.org/abs/1701.03551) TCSVT 2016.

> [3] Yang et al. [“Cost-effective active learning for deep image classification”](https://arxiv.org/abs/1701.03551) TCSVT 2016.

[4] Yarin Gal et al. [“Dropout 作为贝叶斯近似：表示深度学习中的模型不确定性。”](https://arxiv.org/abs/1506.02142) ICML 2016.

> [4] Yarin Gal et al. [“Dropout as a Bayesian Approximation: representing model uncertainty in deep learning.”](https://arxiv.org/abs/1506.02142) ICML 2016.

[5] Blundell et al. [“神经网络中的权重不确定性（Bayes-by-Backprop）”](https://arxiv.org/abs/1505.05424) ICML 2015.

> [5] Blundell et al. [“Weight uncertainty in neural networks (Bayes-by-Backprop)”](https://arxiv.org/abs/1505.05424) ICML 2015.

[6] Settles et al. [“多实例主动学习。”](https://papers.nips.cc/paper/2007/hash/a1519de5b5d44b31a01de013b9b51a80-Abstract.html) NIPS 2007.

> [6] Settles et al. [“Multiple-Instance Active Learning.”](https://papers.nips.cc/paper/2007/hash/a1519de5b5d44b31a01de013b9b51a80-Abstract.html) NIPS 2007.

[7] Houlsby et al. [分类和偏好学习的贝叶斯主动学习。](https://arxiv.org/abs/1112.5745) arXiv preprint arXiv:1112.5745 (2020).

> [7] Houlsby et al. [Bayesian Active Learning for Classification and Preference Learning."](https://arxiv.org/abs/1112.5745) arXiv preprint arXiv:1112.5745 (2020).

[8] Kirsch et al. [“BatchBALD：深度贝叶斯主动学习的高效多样化批量获取。”](https://arxiv.org/abs/1906.08158) NeurIPS 2019.

> [8] Kirsch et al. [“BatchBALD: Efficient and Diverse Batch Acquisition for Deep Bayesian Active Learning.”](https://arxiv.org/abs/1906.08158) NeurIPS 2019.

[9] Beluch et al. [“集成学习在图像分类主动学习中的力量。”](https://openaccess.thecvf.com/content_cvpr_2018/papers/Beluch_The_Power_of_CVPR_2018_paper.pdf) CVPR 2018.

> [9] Beluch et al. [“The power of ensembles for active learning in image classification.”](https://openaccess.thecvf.com/content_cvpr_2018/papers/Beluch_The_Power_of_CVPR_2018_paper.pdf) CVPR 2018.

[10] Sener & Savarese. [“卷积神经网络的主动学习：一种核心集方法。”](https://arxiv.org/abs/1708.00489) ICLR 2018.

> [10] Sener & Savarese. [“Active learning for convolutional neural networks: A core-set approach.”](https://arxiv.org/abs/1708.00489) ICLR 2018.

[11] Donggeun Yoo & In So Kweon. [“主动学习的损失学习。”](https://arxiv.org/abs/1905.03677) CVPR 2019.

> [11] Donggeun Yoo & In So Kweon. [“Learning Loss for Active Learning.”](https://arxiv.org/abs/1905.03677) CVPR 2019.

[12] Margatina et al. [“通过获取对比示例进行主动学习。”](https://arxiv.org/abs/2109.03764) EMNLP 2021.

> [12] Margatina et al. [“Active Learning by Acquiring Contrastive Examples.”](https://arxiv.org/abs/2109.03764) EMNLP 2021.

[13] Sinha et al. [“变分对抗主动学习”](https://arxiv.org/abs/1904.00370) ICCV 2019

> [13] Sinha et al. [“Variational Adversarial Active Learning”](https://arxiv.org/abs/1904.00370) ICCV 2019

[14] Ebrahimiet al. [“Minmax主动学习”](https://arxiv.org/abs/2012.10467) arXiv preprint arXiv:2012.10467 (2021).

> [14] Ebrahimiet al. [“Minmax Active Learning”](https://arxiv.org/abs/2012.10467) arXiv preprint arXiv:2012.10467 (2021).

[15] Mariya Toneva et al. [“深度神经网络学习过程中示例遗忘的实证研究。”](https://arxiv.org/abs/1812.05159) ICLR 2019.

> [15] Mariya Toneva et al. [“An empirical study of example forgetting during deep neural network learning.”](https://arxiv.org/abs/1812.05159) ICLR 2019.

[16] Javad Zolfaghari Bengar et al. [“当深度学习器改变主意时：主动学习的学习动态。”](https://arxiv.org/abs/2107.14707) CAIP 2021.

> [16] Javad Zolfaghari Bengar et al. [“When Deep Learners Change Their Mind: Learning Dynamics for Active Learning.”](https://arxiv.org/abs/2107.14707) CAIP 2021.

[17] Yang et al. [“启发式标注：一种用于生物医学图像分割的深度主动学习框架。”](https://arxiv.org/abs/1706.04737) MICCAI 2017.

> [17] Yang et al. [“Suggestive annotation: A deep active learning framework for biomedical image segmentation.”](https://arxiv.org/abs/1706.04737) MICCAI 2017.

[18] Fedor Zhdanov. [“多样化小批量主动学习”](https://arxiv.org/abs/1901.05954) arXiv preprint arXiv:1901.05954 (2019).

> [18] Fedor Zhdanov. [“Diverse mini-batch Active Learning”](https://arxiv.org/abs/1901.05954) arXiv preprint arXiv:1901.05954 (2019).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Active Learning | 主动学习 | 一种机器学习范式，旨在通过选择最有信息量的未标记数据进行人工标注，以最小化标注成本并最大化模型性能。 |
| Acquisition Function | 采集函数 | 在主动学习中用于评估未标记样本价值的评分函数，分数越高表示样本对模型训练的潜在价值越大。 |
| Uncertainty Sampling | 不确定性采样 | 一种主动学习策略，选择模型预测最不确定的样本进行标注，以提高模型性能。 |
| Query-By-Committee (QBC) | 委员会查询 | 一种主动学习方法，通过聚合多个模型（委员会）的预测分歧来衡量样本的不确定性。 |
| Diversity Sampling | 多样性采样 | 一种主动学习策略，旨在选择能够很好地代表整个数据分布的样本，以提高模型的泛化能力。 |
| Aleatoric Uncertainty | 偶然不确定性 | 由数据中的固有噪声（如传感器误差）引起，通常被认为是不可约减的。 |
| Epistemic Uncertainty | 认知不确定性 | 由模型参数内部的不确定性引起，理论上可以通过获取更多数据来减少。 |
| MC dropout (Monte Carlo dropout) | 蒙特卡洛 dropout | 一种通过在推理过程中应用不同的 dropout 掩码来近似贝叶斯神经网络，从而估计模型不确定性的方法。 |
| Bayes-by-backprop | 反向传播贝叶斯 | 一种直接测量神经网络中权重不确定性的方法，通过维护权重上的概率分布来估计。 |
| Loss Prediction Module | 损失预测模块 | 一个用于预测未标记输入损失值的模块，通过选择预测损失高的样本来估计模型预测质量。 |
| VAAL (Variational Adversarial Active Learning) | 变分对抗主动学习 | 一种类似GAN的主动学习设置，训练判别器区分已标记和未标记数据，选择与已知数据差异大的样本。 |
| Core-set | 核心集 | 计算几何中的概念，指一小组点，它们能近似代表一个更大的点集的形状；在主动学习中用于选择代表性样本。 |
| BADGE (Batch Active learning by Diverse Gradient Embeddings) | 基于多样化梯度嵌入的批量主动学习 | 一种在梯度空间中同时跟踪模型不确定性和数据多样性的主动学习方法。 |
| BALD (Bayesian Active Learning by Disagreement) | 基于分歧的贝叶斯主动学习 | 旨在识别样本以最大化模型权重的信息增益，即最大化预期后验熵的减少。 |
| Pseudo-labeling | 伪标签 | 一种半监督学习技术，将模型对未标记数据的高置信度预测作为其“真实”标签进行训练。 |
