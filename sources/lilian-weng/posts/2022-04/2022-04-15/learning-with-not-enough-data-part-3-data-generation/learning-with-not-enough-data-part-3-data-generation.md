# 数据不足时的学习 第三部分：数据生成

> Learning with not Enough Data Part 3: Data Generation

> 来源：Lil'Log / Lilian Weng，2022-04-15
> 原文链接：https://lilianweng.github.io/posts/2022-04-15-data-gen/
> 分类：机器学习 / 数据生成

## 核心要点

- 本文探讨了数据不足时通过数据生成来扩充训练数据的方法，主要分为数据增强和数据合成两类。
- 数据增强通过对现有训练样本应用各种变换来派生新数据点，同时保持语义不变，涵盖图像、文本和音频等多种模态。
- 图像增强包括基本的图像处理操作、任务特定的策略（如AutoAugment、RandAugment）以及图像混合方法（如Mixup、Cutmix）。
- 文本增强涉及词汇编辑（如EDA、上下文增强）和回译技术，旨在修改文本表达而不改变语义。
- 数据合成主要利用大型预训练语言模型生成新的文本数据，这些模型可以作为弱标注器或直接作为数据生成器。
- 评估生成数据质量的关键指标是亲和力（衡量分布偏移）和多样性（衡量增强复杂性），两者都需足够高以提升模型性能。
- 在训练中使用噪声数据时，可采用正则化、鲁棒架构、鲁棒学习目标（如GCE、课程损失）以及标签校正（如F-校正、蒸馏）等技术来提高模型鲁棒性。
- 样本重加权与选择方法（如重要性重加权、L2R、MentorNet、Co-teaching）通过为不同样本分配权重或选择高质量样本来应对噪声标签和类别不平衡问题。

## 正文

这是关于数据不足时学习的第三部分（前文：[第一部分](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/) 和 [第二部分](https://lilianweng.github.io/posts/2022-02-20-active-learning/)）。让我们考虑两种生成用于训练的合成数据的方法。

> Here comes the Part 3 on learning with not enough data (Previous: [Part 1](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/) and [Part 2](https://lilianweng.github.io/posts/2022-02-20-active-learning/)). Let’s consider two approaches for generating synthetic data for training.

- **数据增强**。给定一组现有的训练样本，我们可以应用各种增强、扭曲和变换来派生新的数据点，而不会丢失关键属性。我们在一篇关于对比学习的[前文](https://lilianweng.github.io/posts/2021-05-31-contrastive/)中介绍了一系列针对文本和图像的增强方法。为了文章的完整性，我在此*重复*数据增强部分并进行了一些编辑。
- **新数据**。即使只有少量甚至没有数据点，我们也可以依靠强大的预训练模型来生成许多*新*数据点。鉴于大型预训练[语言模型 (LM)](https://lilianweng.github.io/posts/2019-01-31-lm/)的快速发展，这一点在近年来尤为突出。少量样本提示已被证明能有效帮助语言模型在无需额外训练的情况下进行上下文学习。

> • **Augmented data**. Given a set of existing training samples, we can apply a variety of augmentation, distortion and transformation to derive new data points without losing the key attributes. We have covered a bunch of augmentation methods on text and images in a [previous post](https://lilianweng.github.io/posts/2021-05-31-contrastive/) on contrastive learning. For the sake of post completeness, I *duplicate* the section on data augmentation here with some edits.
> • **New data**. Given few or even no data points, we can rely on powerful pretrained models to generate a number of *new* data points. This is especially true in recent years given the fast progress in large pretrained [language models (LM)](https://lilianweng.github.io/posts/2019-01-31-lm/). Few shot prompting is shown to be effective for LM to learn within context without extra training.

### 数据增强

> Data Augmentation

数据增强的目标是修改输入格式（例如文本措辞、视觉外观），同时保持语义不变。

> The goal of data augmentation is to modify the input format (e.g. text wording, visual appearance) while the semantic meaning stays unchanged.

#### 图像增强

> Image Augmentation

##### 基本的图像处理操作

> Basic Image Processing Operations

有几种方法可以在保留图像语义信息的同时修改图像。我们可以使用以下任何一种增强或多种操作的组合。

> There are several ways to modify an image while retaining its semantic information. We can use any one of the following augmentation or a composition of multiple operations.

- 随机裁剪，然后调整回原始大小。
- 随机颜色失真
- 随机高斯模糊
- 随机颜色抖动
- 随机水平翻转
- 随机灰度转换
- 还有更多。请查看[PIL.ImageOps](https://pillow.readthedocs.io/en/stable/reference/ImageOps.html)以获取灵感。

> • Random cropping and then resize back to the original size.
> • Random color distortions
> • Random Gaussian blur
> • Random color jittering
> • Random horizontal flip
> • Random grayscale conversion
> • And many more. Check [PIL.ImageOps](https://pillow.readthedocs.io/en/stable/reference/ImageOps.html) for inspiration.

##### 任务特定的数据增强策略

> Task-Specific Augmentation Strategies

如果已知下游任务，就可以学习最优的数据增强策略（即使用哪些处理操作以及如何按顺序组合它们）以最大化下游任务的性能。

> If the downstream task is known, it is possible to learn the optimal augmentation strategies (i.e. what processing operations to use and how to combine them in sequence) to maximize the downstream task performance.

- [AutoAugment](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#AutoAugment) ([Cubuk, et al. 2018](https://arxiv.org/abs/1805.09501)) 的灵感来源于 [神经架构搜索](https://lilianweng.github.io/posts/2020-08-06-nas/)，AutoAugment 将学习图像分类的最佳数据增强操作（即剪切、旋转、反转等）的问题构建为强化学习问题，并寻找能在评估集上产生最高准确率的组合。AutoAugment 可以对抗性地执行 ([Zhang, et al 2019](https://arxiv.org/abs/1912.11188))。
- *RandAugment* ([Cubuk et al., 2019](https://arxiv.org/abs/1909.13719)) 通过使用单个幅度参数控制不同变换操作的幅度，大大减少了 AutoAugment 的搜索空间。
- *基于种群的增强* (PBA; [Ho et al., 2019](https://arxiv.org/abs/1905.05393)) 将 PBT（“基于种群的训练”；[Jaderberg et al, 2017](https://arxiv.org/abs/1711.09846)）与 AutoAugment 相结合，使用进化算法并行训练一组子模型，以演化出最佳的增强策略。
- *无监督数据增强* (UDA; [Xie et al., 2019](https://arxiv.org/abs/1904.12848))，在一组可能的增强策略中，选择一个子集，以最小化未标记示例的预测分布与其未标记增强版本之间的 KL 散度。

> • [AutoAugment](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#AutoAugment) ([Cubuk, et al. 2018](https://arxiv.org/abs/1805.09501)) is inspired by [neural architecture search](https://lilianweng.github.io/posts/2020-08-06-nas/), AutoAugment frames the problem of learning best data augmentation operations (i.e. shearing, rotation, invert, etc.) for image classification as an RL problem and looks for the combination that leads to the highest accuracy on the evaluation set. AutoAugment can be executed in adversarial fashion ([Zhang, et al 2019](https://arxiv.org/abs/1912.11188)).
> • *RandAugment* ([Cubuk et al., 2019](https://arxiv.org/abs/1909.13719)) greatly reduces the search space of AutoAugment by controlling the magnitudes of different transformation operations with a single magnitude parameter.
> • *Population based augmentation* (PBA; [Ho et al., 2019](https://arxiv.org/abs/1905.05393)) combines PBT (“population based training”; [Jaderberg et al, 2017](https://arxiv.org/abs/1711.09846)) with AutoAugment, using the evolutionary algorithm to train a population of children models in parallel to evolve the best augmentation strategies.
> • *Unsupervised Data Augmentation* (UDA; [Xie et al., 2019](https://arxiv.org/abs/1904.12848)), among a set of possible augmentation strategies, selects a subset to minimize the KL divergence between the predicted distribution over an unlabelled example and its unlabelled augmented version.

##### 图像混合

> Image Mixture

图像混合方法可以从现有数据点构建新的训练示例。

> Image mixture methods can construct new training examples from existing data points.

• *Mixup* ([Zhang et al., 2018](https://arxiv.org/abs/1710.09412)) 通过创建两个现有图像 $I_1$ 和 $I_2$ 的加权像素级组合来运行全局级混合：$I_\text{mixup} \gets \alpha I_1 + (1-\alpha) I_2$ 和 $\alpha \in [0, 1]$。

• *Cutmix* ([Yun 等人，2019](https://arxiv.org/abs/1905.04899)) 通过将一张图像的局部区域与另一张图像的其余部分结合起来生成一个新示例，从而进行区域级混合。$I_\text{cutmix} \gets \mathbf{M}_b \odot I_1 + (1-\mathbf{M}_b) \odot I_2$，其中 $\mathbf{M}_b \in \{0, 1\}^I$ 是一个二值掩码，$\odot$ 是逐元素乘法。这等同于用另一张图像的相同区域填充 *cutout* ([DeVries & Taylor 2017](https://arxiv.org/abs/1708.04552)) 区域。

• 给定一个查询 $\mathbf{q}$，*MoCHi*（“混合对比硬负样本”；[Kalantidis 等人 2020](https://arxiv.org/abs/2010.01028)）维护一个包含 $K$ 个负特征 $Q={\mathbf{n}_1, \dots, \mathbf{n}_K }$ 的队列，并按与查询 $\mathbf{q}^\top \mathbf{n}$ 的相似度降序排列这些负特征。队列中的前 $N$ 项被认为是硬负样本 $Q^N$。然后可以通过 $\mathbf{h} = \tilde{\mathbf{h}} / |\tilde{\mathbf{h}}|_2$ 生成合成硬样本，其中 $\tilde{\mathbf{h}} = \alpha\mathbf{n}_i + (1-\alpha) \mathbf{n}_j$ 和 $\alpha \in (0, 1)$。甚至可以通过与查询特征 $\mathbf{h}’ = \tilde{\mathbf{h}’} / |\tilde{\mathbf{h}’}|_2$ 混合来创建更硬的样本，其中 $\tilde{\mathbf{h}’} = \beta\mathbf{q} + (1-\beta) \mathbf{n}_j$ 和 $\beta \in (0, 0.5)$。

英文原文：

• *Mixup* ([Zhang et al., 2018](https://arxiv.org/abs/1710.09412)) runs global-level mixture by creating a weighted pixel-wise combination of two existing images $I_1$ and $I_2$: $I_\text{mixup} \gets \alpha I_1 + (1-\alpha) I_2$ and $\alpha \in [0, 1]$.

• *Cutmix* ([Yun et al., 2019](https://arxiv.org/abs/1905.04899)) does region-level mixture by generating a new example by combining a local region of one image with the rest of the other image. $I_\text{cutmix} \gets \mathbf{M}_b \odot I_1 + (1-\mathbf{M}_b) \odot I_2$, where $\mathbf{M}_b \in \{0, 1\}^I$ is a binary mask and $\odot$ is element-wise multiplication. It is equivalent to filling the *cutout* ([DeVries & Taylor 2017](https://arxiv.org/abs/1708.04552)) region with the same region from another image.

• Given a query $\mathbf{q}$, *MoCHi* (“mixing of contrastive hard negatives”; [Kalantidis et al. 2020](https://arxiv.org/abs/2010.01028)) maintains a queue of $K$ negative features $Q={\mathbf{n}_1, \dots, \mathbf{n}_K }$ and sorts these negative features by similarity to the query, $\mathbf{q}^\top \mathbf{n}$, in descending order. The first $N$ items in the queue are considered as the hardest negatives, $Q^N$. Then synthetic hard examples can be generated by $\mathbf{h} = \tilde{\mathbf{h}} / |\tilde{\mathbf{h}}|_2$ where $\tilde{\mathbf{h}} = \alpha\mathbf{n}_i + (1-\alpha) \mathbf{n}_j$ and $\alpha \in (0, 1)$. Even harder examples can be created by mixing with the query feature, $\mathbf{h}’ = \tilde{\mathbf{h}’} / |\tilde{\mathbf{h}’}|_2$ where $\tilde{\mathbf{h}’} = \beta\mathbf{q} + (1-\beta) \mathbf{n}_j$ and $\beta \in (0, 0.5)$.

#### 文本增强

> Text Augmentation

##### 词汇编辑

> Lexical Edits

*Easy Data Augmentation* (EDA; [Wei & Zou 2019](https://arxiv.org/abs/1901.11196)) 定义了一组简单而强大的文本增强操作。给定一个句子，EDA 随机选择并应用以下四种简单操作之一：

> *Easy Data Augmentation* (EDA; [Wei & Zou 2019](https://arxiv.org/abs/1901.11196)) defines a set of simple but powerful operations for text augmentation. Given a sentence, EDA randomly chooses and applies one of four simple operations:

1\. 同义词替换 (SR)：将 $n$ 随机的非停用词替换为其同义词。

2\. 随机插入（RI）：在句子中随机选择一个非停用词的随机同义词，并将其放置在随机位置。

3\. 随机交换（RS）：随机交换两个词并重复 $n$ 次。

4\. 随机删除（RD）：以概率 $p$ 随机删除句子中的每个词。

英文原文：

1\. Synonym replacement (SR): Replace $n$ random non-stop words with their synonyms.

2\. Random insertion (RI): Place a random synonym of a randomly selected non-stop word in the sentence at a random position.

3\. Random swap (RS): Randomly swap two words and repeat $n$ times.

4\. Random deletion (RD): Randomly delete each word in the sentence with probability $p$.

其中 $p=\alpha$ 和 $n=\alpha \times \text{sentence_length}$，直观地讲，较长的句子可以吸收更多噪声，同时保持原始标签。超参数 $\alpha$ 大致表示一个句子中可能通过一次增强而改变的词语的百分比。

> where $p=\alpha$ and $n=\alpha \times \text{sentence_length}$, with the intuition that longer sentences can absorb more noise while maintaining the original label. The hyperparameter $\alpha$ roughly indicates the percent of words in one sentence that may be changed by one augmentation.

EDA 被证明在多个分类基准数据集上比没有 EDA 的基线提高了分类准确率。性能提升在 *较小* 的训练集上更为显著。EDA 中的所有四种操作都有助于提高分类准确率，但在不同的 $\alpha$ 处达到最佳。

> EDA is shown to improve the classification accuracy on several classification benchmark datasets compared to baseline without EDA. The performance lift is more significant on a *smaller* training set. All the four operations in EDA help improve the classification accuracy, but get to optimal at different $\alpha$’s.

![EDA leads to performance improvement on several classification benchmarks. (Image source: Wei & Zou 2019 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/EDA-exp1.png)

*上下文*增强（[Kobayashi, 2018](https://arxiv.org/abs/1805.06201)）替换词语$w_i$在位置$i$通过从BERT等双向语言模型学习到的概率分布中采样$p(.\mid S\setminus{w_i})$。通过这种方式，词语被同义词或适合上下文的相似词替换。为确保此类操作不改变标签，语言模型被训练成标签条件双向语言模型。条件BERT（CBERT；[Xing Wu et al. 2018](https://arxiv.org/abs/1812.06705)）扩展了BERT，以预测基于类别标签的掩码标记，并可用于上下文增强预测。

> *Contextual* Augmentation ([Kobayashi, 2018](https://arxiv.org/abs/1805.06201)) replaces word $w_i$ at position $i$ by sampling from a probability distribution learned by a bidirectional LM such as BERT, $p(.\mid S\setminus{w_i})$. In this way, the words are substituted by synonyms, or similar words suitable for the context. To guarantee such operations do not alter the labels, the LM is fit to be label-conditioned bidirectional LM. Conditional BERT (CBERT; [Xing Wu et al. 2018](https://arxiv.org/abs/1812.06705)) extends BERT to predict masked tokens conditioned on the class label and can be used for contextual augmentation prediction.

##### 回译

> Back-translation

*回译*通过将文本样本翻译成另一种语言，然后再翻译回来，生成增强数据。翻译以两种方式进行，并且两个方向都应具有足够好的性能，以避免语义意义的显著损失。

> *Back-translation* produces augmented data by translating text samples to another language and then translating them back. The translation happens in two ways and both directions should have decent enough performance to avoid significant loss of semantic meaning.

##### 混合增强

> Mix-up

也可以将[Mixup](https://lilianweng.github.io/posts/2022-04-15-data-gen/#image-mixture)应用于文本（[Guo et al. 2019](https://arxiv.org/abs/1905.08941)），但作用于嵌入空间以获得一些性能提升。所提出的方法依赖于专门设计的模型架构，以在词或句子嵌入上进行预测。在嵌入空间中添加对抗性噪声作为数据增强的一种方式，已被证明可以提高模型训练的泛化能力（[Zhu et al. 2019](https://arxiv.org/abs/1909.11764)）。

> It is also possible to apply [Mixup](https://lilianweng.github.io/posts/2022-04-15-data-gen/#image-mixture) to text ([Guo et al. 2019](https://arxiv.org/abs/1905.08941)) but on the embedding space to obtain some performance gain. The proposed method relies on a specially designed model architecture to operate the prediction on the word or sentence embedding. Adding adversarial noise in the embedding space as a way of data augmentation is shown to improve the generalization of model training ([Zhu et al. 2019](https://arxiv.org/abs/1909.11764)).

#### 音频增强

> Audio Augmentation

以下是几种常用的音频数据增强方法，它们作用于原始音频或频谱图，由[Wang & van den Oord (2021)](https://arxiv.org/abs/2103.06508)总结。

> Here is a list of several commonly used audio data augmentation methods, operated on raw audio or spectrograms, summarized by [Wang & van den Oord (2021)](https://arxiv.org/abs/2103.06508).

**音频混合增强。**给定两个音频片段$\mathbf{x}_1$和$\mathbf{x}_2$，混合后的版本$\hat{\mathbf{x}} = \alpha \mathbf{x}_1 + (1-\alpha)\mathbf{x}_2$应与更具主导性的输入的标签相关联。音频混合增强了数据，使其具有更真实的噪声。

英文原文：Audio mixup. Given two audio clips 

$\mathbf{x}_1$ and 

$\mathbf{x}_2$, the mixed-up version 

$\hat{\mathbf{x}} = \alpha \mathbf{x}_1 + (1-\alpha)\mathbf{x}_2$ should be associated with the label of the more dominant input. The audio mixup augments the data with more realistic noise.

**时间遮蔽。**音频的一小段连续片段可以被遮蔽，而不会丢失语义信息。

> **Time masking.** A small consecutive chunk of the audio can be masked without losing semantic information.

**频率遮蔽。**频谱图上少量频率分量可以被丢弃，并且不应改变其关联标签。

> **Frequency masking.** A small amount of frequency components on the spectrogram can be dropped off and it should not change the associated label.

**频率移位。**频谱图可以按介于$[-F, F]$之间的一个整数进行移位，其中`F`是最大移位大小。这是一种廉价的增强方法，用于改变音频的音高。

英文原文：Frequency shift. The spectrogram can be shifted by an integer between 

$[-F, F]$, where `F` is the maximum shift size. It is a cheap augmentation to change the pitch of the audio.

#### 架构增强

> Architectural Augmentation

带有**dropout**层的模型可以通过对同一输入样本应用不同的 dropout 掩码来创建增强样本。例如，在对比学习模型[SimCSE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simcse)（[Guo et al. 2021](https://arxiv.org/abs/2104.08821)）中，一个样本被简单地两次送入编码器，每次使用不同的 dropout 掩码，这两个版本构成正样本对，而批次中的其他样本则被视为负样本对。

> Models with **dropout** layers can create augmented samples by applying different dropout masks on the same input sample. For example, in the contrastive learning model [SimCSE](https://lilianweng.github.io/posts/2021-05-31-contrastive/#simcse) ([Guo et al. 2021](https://arxiv.org/abs/2104.08821)), a sample is simply fed into the encoder twice with different dropout masks and these two versions are the positive pair where the other in-batch samples are considered as negative pairs.

Dropout 通过向模型的内部表示添加噪声来增强数据。它可以以更结构化的方式应用，例如在**cutoff**（[Shen et al. (2020)](https://arxiv.org/abs/2009.13818)）中，随机移除 token 嵌入矩阵的块。

> Dropout augments data by adding noise onto the internal representation of the model. It can be applied in a more structured way, such as in **cutoff** ([Shen et al. (2020)](https://arxiv.org/abs/2009.13818)), where random chunks of the token embedding matrix are removed.

### 数据合成

> Data Synthesis

鉴于生成高质量、逼真的图像比生成类人自然语言文本要困难得多，并且考虑到大型预训练语言模型最近的成功，本节仅关注文本生成。要了解更多关于如何合成逼真图像的信息，请查阅关于 [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/)、[VAE](https://lilianweng.github.io/posts/2018-08-12-vae/)、[flow](https://lilianweng.github.io/posts/2018-10-13-flow-models/) 和 [diffusion](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/) 模型的文章。

> Given that generating high-quality, photorealistic images is a lot more difficult than generating human-like natural language text and recent success with large pretrained language models, this section only focuses on text generation. To read more on how to synthesize realistic images, check posts on [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/), [VAE](https://lilianweng.github.io/posts/2018-08-12-vae/), [flow](https://lilianweng.github.io/posts/2018-10-13-flow-models/) and [diffusion](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/) models.

#### 作为噪声标注器的语言模型

> Language Model as Noisy Annotator

[Wang et al. (2021)](https://arxiv.org/abs/2108.13487) 探索了通过少样本提示利用 GPT-3 作为弱标注器的方法，实现了比人工标注便宜 10 倍的成本。该论文认为，通过使用 GPT-3 标注的数据，它本质上执行了 [自训练](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#self-training)：对未标注样本的预测对模型应用了熵正则化，以避免高类别重叠，从而有助于提高模型性能。

> [Wang et al. (2021)](https://arxiv.org/abs/2108.13487) explored ways to leverage GPT-3 as a weak annotator via few-shot prompting, achieving 10x cheaper than human labeling. The paper argues that by using data labeled by GPT-3, it essentially performs [self-training](https://lilianweng.github.io/posts/2021-12-05-semi-supervised/#self-training): The predictions on unlabeled samples apply entropy regularization on the model to avoid high class overlaps so as to help improve the model performance.

![Illustration of how to use GPT-3 to generate more training data with the human-in-the-loop active learning pipeline to improve the data quality. (Image source: Wang et al. 2021 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/GPT3-data-gen.png)

通过 [主动学习](https://lilianweng.github.io/posts/2022-02-20-active-learning/) 选择的具有最高不确定性的 GPT-3 标注样本被发送给人工标注员进行重新标注。少样本提示包含少量人工标注的示例，因此标注成本受到限制。合成样本根据标签 $y$ 的预测 logits 进行排名，得分最低的样本将进行重新标注。

> GPT-3-labeled samples selected by [active learning](https://lilianweng.github.io/posts/2022-02-20-active-learning/) with highest uncertainty are sent to human labelers to be re-annotated. The few-shot prompt contains a small number of human labeled examples and thus the labeling cost is restricted. Synthetic samples are ranked by predicted logits of label $y$ and those with the lowest scores go through relabeling.

GPT-3 标注在低成本方案中取得了更好的结果，但在数据收集投入足够资金时与人工标注存在差距。这暗示了以下不等式，尽管“大量”或“嘈杂”的程度取决于任务细节。

> GPT-3 labeling achieves better results in the low-cost regime, but has a gap with human labeling when enough money is spent on data collection. This implies the following inequation, although to what extent “a lot” or “noisy” means depends on the task details.

> **大量高质量数据 > 大量噪声数据 > 少量高质量数据**。

> **A lot of high-quality data > A lot of noisy data > A little high quality data**.

![GPT-3 labeling technique improves the classification performance in the low-cost regime. (Image source: Wang et al. 2021 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/GPT3-data-gen-exp.png)

#### 语言模型作为数据生成器

> Language Model as Data Generator

如果文本分类任务有足够的训练数据集，我们可以微调语言模型，根据标签合成更多的训练样本（[Anaby-Tavor et al. 2019](https://arxiv.org/abs/1911.03118), [Kumar et al. 2021](https://arxiv.org/abs/2003.02245)）。

> If enough training dataset for text classification tasks are available, we can fine-tune language models to synthesize more training samples conditioned on labels ([Anaby-Tavor et al. 2019](https://arxiv.org/abs/1911.03118), [Kumar et al. 2021](https://arxiv.org/abs/2003.02245)).

*基于语言模型的数据增强* (**LAMBADA**; [Anaby-Tavor et al. 2019](https://arxiv.org/abs/1911.03118)) 采用了这种思想，其中过程涉及微调分类器和样本生成模型。

> *Language-model-based data augmentation* (**LAMBADA**; [Anaby-Tavor et al. 2019](https://arxiv.org/abs/1911.03118)) takes such an idea, where the process involves fine-tuning both a classifier and a sample generation model.

1\. 使用现有训练数据集训练基线分类器：$h = \mathcal{A}(\mathcal{D}_\text{train})$。

2\. 独立于步骤 1，LM $\mathcal{M}$ 在 $\mathcal{D}_{\text{train}}$ 上进行微调以获得 $\mathcal{M}_{\text{tuned}}$。

3\. 合成一个标记数据集 $\mathcal{D}^{\ast}$，方法是生成序列 `y[SEP]` 的延续，直到 `EOS`，使用 $\mathcal{M}_\text{tuned}$。

4\. 通过以下方式过滤合成数据集：



• (1) 验证预测标签是否正确 $h(x)=y$；



• (2) 当样本按分类器概率排序时，选择排名靠前的样本。$\mathcal{D}_\text{syn} \subset \mathcal{D}^{\ast}$。他们生成了10倍于增强所需的样本，并且只保留了置信度得分最高的10%合成样本。

英文原文：

1\. Train a baseline classifier using the existing training dataset: $h = \mathcal{A}(\mathcal{D}_\text{train})$.

2\. Independently of step 1, a LM $\mathcal{M}$ is fine-tuned on $\mathcal{D}_{\text{train}}$ to obtain $\mathcal{M}_{\text{tuned}}$.

3\. Synthesize a labeled dataset $\mathcal{D}^{\ast}$ by generating the continuation of the sequence `y[SEP]` until `EOS` using $\mathcal{M}_\text{tuned}$.

4\. Filter synthesized dataset by,



• (1) Verifying that the predicted label is correct $h(x)=y$;



• (2) Selecting the top ranked samples when they are ranked by the classifier probability. $\mathcal{D}_\text{syn} \subset \mathcal{D}^{\ast}$. They generate 10x more samples needed for augmentation and only the top 10% synthesized samples with highest confidence scores remain.

最终分类器在 $\mathcal{D}_\text{syn} \cup \mathcal{D}_\text{train}$ 上进行训练。这个过程可以重复多次，但目前尚不清楚其益处是否会迅速减少，或者重复过程是否会引入自我偏差。

> The final classifier is trained on $\mathcal{D}_\text{syn} \cup \mathcal{D}_\text{train}$ . The process can be repeated multiple times, but it is unclear whether the benefit would quickly diminish or the repetitive process would bring in self-bias.

![Accuracy of LAMBADA vs. other generative approaches over all datasets and classifiers. (Image source: Anaby-Tavor et al. 2019 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/LAMBADA.png)

为了简化 LAMBADA，我们实际上可以消除对微调生成模型和现有相当规模训练数据集的依赖（[步骤2](https://lilianweng.github.io/posts/2022-04-15-data-gen/#step2)如上）。*无监督数据生成*（**UDG**；[Wang et al. 2021](https://arxiv.org/abs/2109.09193)）依赖于对大型预训练语言模型进行少样本提示，以生成高质量的合成数据进行训练。与上述方法（其中LM被要求预测`y`，给定$\mathbf{x}$，UDG转而合成输入$\mathbf{x}$，给定标签`y`。然后，在此合成数据集上训练一个任务专用模型。

英文原文：To simplify LAMBADA,  we can actually remove the dependency of a fine-tuned generation model  and an existing training dataset of a decent size ([Step 2](https://lilianweng.github.io/posts/2022-04-15-data-gen/#step2) above). *Unsupervised data generation* (UDG; [Wang et al. 2021](https://arxiv.org/abs/2109.09193)) relies on few-shot prompting on a large pretrained language model to generate high-quality synthetic data for training. Opposite to the above approach where LM is asked to predict `y` given 

$\mathbf{x}$, UDG instead synthetizes the inputs 

$\mathbf{x}$ given labels `y`. Then a task-specific model is trained on this synthetic dataset.

[Schick & Schutze (2021)](https://arxiv.org/abs/2104.07540) 提出了一种类似的想法，但应用于 NLI 任务而非分类任务，要求 PLM 在模型被提示任务特定指令时，编写相似或不同的句子对。

> [Schick & Schutze (2021)](https://arxiv.org/abs/2104.07540) proposed a similar idea but on the NLI task instead of classification, asking PLM to write sentence pairs that are similar or different while the model is prompted with task-specific instructions.

![Illustration of the unsupervised data generation (UDG) framework. (Image source: Wang et al., 2021 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/UDG.png)

UDG 的少样本提示包含少量未标记示例，以及对所需标签的任务特定自然语言描述。由于一些生成的示例是嘈杂的，他们实施了 **噪声标签退火** (**NLA**) 技术，以在训练过程中过滤掉潜在未对齐的样本。当模型开始高度自信地不同意其伪标签时，NLA 会在训练过程中逐渐及时移除噪声训练信号。在每个训练步骤 `t` 中，如果给定示例 $(\mathbf{x}_i, \hat{y}_i)$ 满足以下条件，则被认为是噪声并应被移除：

英文原文：The few-shot prompts of UDG contain a small number of unlabeled examples, as well as a task-specific natural language description of the desired label. Because some generated examples are noisy, they implemented noisy label annealing (NLA) techniques to filter potentially misaligned samples out during the training processes. NLA gradually removes noisy training signals in time during training when the model starts to disagree with its pseudo label with high confidence. At each training step `t`, a given example 

$(\mathbf{x}_i, \hat{y}_i)$ is considered noisy and should be removed if:

• 模型预测概率高于阈值 $p(\bar{y}_i \vert \mathbf{x}_i) > \mu_t$，其中 $\bar{y}_i = \arg\max_y p(y \vert \mathbf{x}_i)$；

• 并且预测标签与合成标签不同，$\bar{y}_i \neq \hat{y}_i$。

英文原文：

• The model predicted probability is higher than a threshold $p(\bar{y}_i \vert \mathbf{x}_i) > \mu_t$ where $\bar{y}_i = \arg\max_y p(y \vert \mathbf{x}_i)$;

• And the predicted label is different from the synthetic label, $\bar{y}_i \neq \hat{y}_i$.

请注意，阈值 $\mu_t$ 是时间相关的，初始化为 0.9，然后随时间逐渐退火到 $1/\text{num_of_classes}$。

> Note that the threshold $\mu_t$ is time-dependent, initialized as 0.9 and then gradually annealed to $1/\text{num_of_classes}$ in time.

正如他们的实验所示，UDG 相对于少样本推理的改进非常显著，其中 NLA 带来了一些额外的提升。在某些情况下，结果甚至可以与监督微调相媲美。

> As shown in their experiments, the improvement of UDG over few-shot inference is quit significant, where NLA brings in some extra boost. The results are even comparable with supervised fine-tuning on several cases.

![Comparison of accuracy of UDG and other methods on different classification datasets. (Image source: Wang et al., 2021 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/UDG-exp.png)

[Han et al (2021)](https://arxiv.org/abs/2110.05448) 利用少样本数据生成、蒸馏和反向翻译，在翻译任务上取得了SOTA结果。所提出的方法包含以下步骤，假设无法访问配对的翻译数据：

> [Han et al (2021)](https://arxiv.org/abs/2110.05448) achieved SOTA results on translation tasks using few-shot data generation, distillation and back-translation. The proposed method contains the following steps, assuming no access to paired translation data:

1. *零样本生成。*首先利用预训练语言模型的零样本翻译能力，为一小部分未标注句子生成翻译。
2. *少样本生成。*然后将这些零样本翻译作为少样本示例，以扩充生成更大的合成数据集。
3. *蒸馏。*在此数据集上对模型进行微调。翻译任务被表述为一个语言建模任务 `[L1] <seq1> [[TRANSLATE]] [L2] <seq2>.`，给定一对两种不同语言的序列 `<seq1, seq2>`。在测试时，语言模型会收到提示 `[L1] <seq> [[TRANSLATE]] [L2]`，并从采样的补全中解析出候选翻译 `<sampledSeq>`。
4. *反向翻译。*继续在反向翻译数据集上进行微调，其中样本的顺序是反转的，`<sampledSeq, seq>`。
5. 步骤1-4可以重复。

> • *Zero-shot Generation.* First use the zero-shot translation ability of a pre-trained LM to generate translations for a small set of unlabeled sentences.
> • *Few-shot Generation.* Then amplify these zero-shot translations by using them as few-shot demonstrations to gather an even larger synthetic dataset.
> • *Distillation.* Fine-tune the model on this dataset. The translation task is formulated as a language modeling task `[L1] <seq1> [[TRANSLATE]] [L2] <seq2>.` given a pair of two sequences `<seq1, seq2>` in two different languages. At test-time, the LM is prompted with `[L1] <seq> [[TRANSLATE]] [L2]` and a candidate translation `<sampledSeq>` is parsed from the sampled completion.
> • *Back-translation.* Continue fine-tuning on the back-translation dataset where the order of samples is reversed, `<sampledSeq, seq>`.
> • Step 1-4 can be repeated.

![Algorithm of using distillation and back-translation to train a language model on translation tasks. (Image source: Han et al. 2021 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/back-translation-data-gen.png)

上述方法的成功取决于一个良好的预训练语言模型来启动初始翻译数据集。迭代的少样本生成和带有反向翻译的蒸馏是提取和提炼预训练语言模型翻译能力并进一步将其蒸馏到新模型中的有效方法。

> The success of the above method depends on a good pretrained LM to kick off the initial translation dataset. Iterative few-shot generation and distillation with back-translation is an effective way to extract and refine the translation capability out of a pretrained LM and further to distill that into a new model.

![Comparison of BLEU scores of the translation models of different training runs using: only distillation, back-translation, both and with more monolingual training data. (Image source: Han et al. 2021 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/back-translation-data-gen-exp.png)

### 如何量化生成数据质量？

> How to Quantify Generated Data Quality?

考虑到所有通过数据增强或数据合成生成的数据，我们如何量化数据质量，即它们如何改善模型的泛化能力？[Gontijo-Lopes et al. (2020)](https://arxiv.org/abs/2002.08973) 引入了两个维度来跟踪：亲和力（affinity）和多样性（diversity）。

> Given all the generated data, either by data augmentation or data synthesis, how can we quantify data quality in terms of how they improve model generalization? [Gontijo-Lopes et al. (2020)](https://arxiv.org/abs/2002.08973) introduced two dimensions to track, affinity and diversity.

- **亲和力**是一种模型敏感的*分布偏移*度量，量化了增强操作将训练数据分布从模型所学到的分布中偏移了多少。


   - 定义：模型在干净数据上训练，然后在干净数据与增强数据上测试时的性能差异。
   - 作为比较，KL散度也可以衡量分布偏移，但不考虑模型性能。
- **多样性**是*增强复杂性*的度量，衡量增强数据相对于模型和学习过程的复杂程度。


   - 定义：使用给定增强训练的模型最终的训练损失。
   - 另一个潜在的多样性度量是转换后数据的熵。
   - 第三个潜在的多样性度量是模型达到给定训练准确度阈值所需的训练时间。
   - 以上三个指标都是相互关联的。

> • **Affinity** is a model-sensitive metric for *distribution shift*, quantifying how much an augmentation shifts the training data distribution from what a model learned.
>

> ◦ Definition: The performance difference between the model tested on clean data vs augmented data, while the model is trained on clean data.

> ◦ As a comparison, KL can also measure distribution shift but does not consider the model performance.

> • **Diversity** is a measure of *augmentation complexity*, measuring the complexity of the augmented data with respect to the model and learning procedure.
>

> ◦ Definition: The final training loss of a model trained with a given augmentation.

> ◦ Another potential diversity measure is the entropy of the transformed data.

> ◦ A third potential diversity measure is the training time needed for a model to reach a given training accuracy threshold.

> ◦ All three metrics above are correlated.

最终的模型性能取决于这两个指标都足够高。

> The final model performance is dependent on both metrics to be high enough.

![(a) Left: A scatter plot of affinity vs diversity metric, where each point represents a different augmentation method and its color indicates the final test accuracy. (b) Right: The conceptual illustration of the relationship between clean and augmented data in different regions of affinity and diversity metrics. (Image source: Gontijo-Lopes et al. 2020 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/affinity-diversity.png)

关于相关性和多样性有许多量化指标，根据是否有参考可用而形式各异，例如文本的困惑度（perplexity）、BLEU分数，以及图像的Inception Score。鉴于具体的质量量化指标列表可能非常长，我在此省略。

> There are many quantitative metrics on relevancy and diversity, in different formations depending on whether a reference is available, such as perplexity, BLEU for text and inception score for images. I’m skipping the list of concrete quantitative metrics on quality here, given it could be very long.

### 使用噪声数据进行训练

> Training with Noisy Data

通过模型生成或数据增强收集大量噪声数据很方便，但很难保证增强和生成的数据能100%准确。鉴于深度神经网络很容易过拟合噪声标签并“记忆”损坏的标签，在使用生成数据时，我们可以应用针对噪声标签训练的技术（*噪声鲁棒训练*）来稳定和优化性能。请查阅这篇关于从噪声标签学习的[综述论文 (Song et al. 2021)](https://arxiv.org/abs/2007.08199)，以获取更全面的相关工作介绍。

> It is convenient to collect a large amount of noisy data via model generation or data augmentation, but it is hard to guarantee that augmented and generated data can be 100% accurate. Knowing that deep neural networks can easily overfit noisy labels and “memotize” corrupted labels, we can apply the techniques for training on noisy labels (*noise-robust training*) when using generated data to stabilize and optimize the performance. Please check this [survey paper (Song et al. 2021)](https://arxiv.org/abs/2007.08199) on learning from noisy labels for a more thorough coverage of related work.

#### 正则化和鲁棒架构

> Regularization and Robust Architecture

一般来说，旨在避免过拟合的机制应有助于在使用适度噪声数据时提高训练的鲁棒性，例如权重衰减、dropout、批量归一化。事实上，良好的数据增强（即只修改非本质属性）也可以被视为一种正则化方式。

> Generally speaking, mechanisms designed for avoiding overfitting should help improve training robustness when working with moderately noisy data, such as weight decay, dropout, batch normalization. In fact, good data augmentation (i.e. only non-essential attributes are modified) can be considered as a way of regularization as well.

另一种方法是为网络添加一个专门的**噪声适应层**，以近似标签损坏的未知投影（[Sukhbaatar et al. 2015](https://arxiv.org/abs/1406.2080), [Goldberger & Ben-Reuven, 2017](https://openreview.net/forum?id=H12GRgcxg)）。

> A different approach is to enhance the network with a dedicated **noisy adaptation layer** to approximate the unknown projection of label corruption ([Sukhbaatar et al. 2015](https://arxiv.org/abs/1406.2080), [Goldberger & Ben-Reuven, 2017](https://openreview.net/forum?id=H12GRgcxg)).

[Sukhbaatar et al. (2015)](https://arxiv.org/abs/1406.2080) 在网络架构中引入了一个额外的线性层 $Q$，以使预测适应噪声标签分布。噪声矩阵 $Q$ 最初被 *固定* 为单位函数，同时只更新基础模型参数。一段时间后，$Q$ 开始更新，并有望捕获数据中的噪声。噪声矩阵通过正则化进行训练，以鼓励其匹配噪声分布，同时保持基础模型对真实标签的预测准确。

> [Sukhbaatar et al. (2015)](https://arxiv.org/abs/1406.2080) introduced an extra linear layer $Q$ into the network architecture to adapt the predictions to match the noisy label distribution. The noise matrix $Q$ is initially *fixed* to the identity function while only the base model parameters is updated. After some time, $Q$ starts to be updated and expected to capture the noise in the data. The noise matrix is trained with regularization to encourage it to match the noise distribution while keeping the base model prediction accurate for true labels.

![(a) Left: A noise matrix $Q$ is added between softmax and the final output for the loss. (b) Right: The noise matrix $Q$ is fixed at the identity function initially and only gets updated with regularization after some training. (Image source: Sukhbaatar et al. 2015 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/noise-adaptation-layer.png)

然而，很难保证这样的噪声矩阵层只会捕获噪声转换分布，而且它实际上并非易于学习。[Goldberger & Ben-Reuven (2017)](https://openreview.net/forum?id=H12GRgcxg)) 提出在基础模型中端到端地添加一个额外的 softmax 层，并通过将正确标签视为潜在随机变量、将噪声过程视为具有未知参数的通信信道来应用 [EM 算法](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm)。

> However, it is hard to guarantee such a noise matrix layer would only capture the noise transition distribution and it is actually non-trivial to learn. [Goldberger & Ben-Reuven (2017)](https://openreview.net/forum?id=H12GRgcxg))  proposed to add an additional softmax layer end-to-end with the base model and apply the [EM algorithm](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm) by treating the correct labels as latent random variable and the noise processes as a communication channel with unknown parameters.

#### 鲁棒学习目标

> Robust Learning Objective

除了最常用的交叉熵损失之外，其他一些学习目标选择也被证明对噪声标签更具鲁棒性。

> Besides the most commonly used cross entropy loss, some other choices of learning objectives are shown to be more robust to noisy labels.

例如，**MAE**（平均绝对误差）比 CCE（分类交叉熵）对噪声标签更具鲁棒性，因为它平等对待每个样本（[Ghosh et al. 2017](https://arxiv.org/abs/1712.09482)）。MAE 训练样本之间缺乏不同的权重导致训练时间显著延长。受 MAE 和 CCE 之间权衡的启发，[Zhang & Sabuncu (2018)](https://arxiv.org/abs/1805.07836) 提出了 *广义交叉熵*（**GCE**），它是 CCE 损失的一种泛化，旨在对噪声数据具有鲁棒性。

> For example, **MAE** (mean absolute error) is more robust to noisy labels than CCE (categorical cross entropy), as it treats every sample equally ([Ghosh et al. 2017](https://arxiv.org/abs/1712.09482)). Lack of different weighting among training samples of MAE lead to significantly longer training time. Motivated by the tradeoff between MAE and CCE, [Zhang & Sabuncu (2018)](https://arxiv.org/abs/1805.07836) proposed *generalized cross entropy* (**GCE**), a generalization of CCE loss to be robust to noisy data.

为了利用MAE提供的噪声鲁棒性和CCE的隐式加权方案的优点，GCE采用负Box-Cox变换作为损失函数：

> To exploit the benefits of both the noise-robustness provided by MAE and the implicit weighting scheme of CCE, GCE adopts the the negative Box-Cox transformation as a loss function:

$$
\mathcal{L}_q(f(\mathbf{x}_i, y_i = j)) = \frac{1 - f^{(j)}(\mathbf{x}_i)^q}{q}
$$

其中$f^{(j)}$表示$j$个元素$f(.)$和$q \in (0, 1]$。$\mathcal{L}_q$等同于 CCE，当$q \to 0$时，并当$q=1$。经验实验表明，存在一个$q$的阈值，在该阈值下，过拟合永远不会出现，并且数据越嘈杂，该阈值应该越高。

> where $f^{(j)}$ denotes the $j$ -th element of $f(.)$ and $q \in (0, 1]$.
> $\mathcal{L}_q$ is equivalent to CCE when $q \to 0$ and becomes MAE when $q=1$. Empirical experiments show that there exists a threshold of $q$ with which overfitting never emerges and the noisier the data the higher such a threshold should be.

给定真实标签和预测标签，$y_i, \hat{y}_i \in \{0, 1\}$ 并令 $u_i=y_i \cdot \hat{y}_i$，**零一损失**，$\mathcal{L}_{01}(\mathbf{u}) = \sum_{i=1}^n \mathbb{1}[u_i < 0]$，是另一种被证明对噪声数据具有鲁棒性的学习目标。最小化带有零一损失的经验风险被证明等同于最小化经验对抗性（最坏情况）风险（[Hu et al 2018](https://arxiv.org/abs/1611.02041)）。由于最坏情况风险是干净数据分布的分类风险的上限，因此最小化最坏情况风险可以导致真实风险降低，这使得零一损失特别鲁棒。然而，零一损失是不可微分的，不能直接优化。一种解决方案是近似零一损失的*上限*，并转而最小化该上限损失。

英文原文：Given true and predicted labels, 

$y_i, \hat{y}_i \in \{0, 1\}$ and let 

$u_i=y_i \cdot \hat{y}_i$, the zero-one loss, 

$\mathcal{L}_{01}(\mathbf{u}) = \sum_{i=1}^n \mathbb{1}[u_i < 0]$, is another learning subjective shown to be robust to noisy data. Minimizing the empirical risk with the zero-one loss is shown to be equivalent to minimizing the empirical adversarial (worse-case) risk ([Hu et al 2018](https://arxiv.org/abs/1611.02041)). Because the worst-case risk is the upper bound of the classification risk of the clean data distribution, minimizing the worst-case risk can lead to decreased true risk, which makes the zero-one loss especially robust. However, the zero-one loss is non-differentiable and cannot be optimized directly. One solution is to approximate an *upper bound* of the zero-one loss and to minimize the upper bound loss instead.

[合页损失](https://en.wikipedia.org/wiki/Hinge_loss)，$\mathcal{L}_\text{hinge}(\mathbf{u}) = \sum_{i=1}^n \max(0, 1 - u_i)$，定义了零一损失的一个粗略上限。[Lyu & Tsang (2020)](https://arxiv.org/abs/1905.10045) 提出了一种*课程损失*（**CL**），与合页损失等传统替代损失（如合页损失）相比，它是一个更紧密的上限，$\mathcal{L}_\text{01}(\mathbf{u}) \leq \mathcal{L}_\text{CL}(\mathbf{u}) \leq \mathcal{L}_\text{hinge}(\mathbf{u})$。

英文原文：The [hinge loss](https://en.wikipedia.org/wiki/Hinge_loss), 

$\mathcal{L}_\text{hinge}(\mathbf{u}) = \sum_{i=1}^n \max(0, 1 - u_i)$, defines a rough upper bound of the zero-one loss. [Lyu & Tsang (2020)](https://arxiv.org/abs/1905.10045) proposed a *curriculum loss* (CL), which is a tighter upper bound compared to a conventional surrogate loss like the hinge loss, 

$\mathcal{L}_\text{01}(\mathbf{u}) \leq \mathcal{L}_\text{CL}(\mathbf{u}) \leq \mathcal{L}_\text{hinge}(\mathbf{u})$.

$$
\mathcal{L}_\text{CL}(\mathbf{u}) = \min_{\mathbf{w}\in\{0,1\}^n}\max(\sum_{i=1}^n w_i \ell(u_i), n - \sum_{i=1}^n w_i + \sum_{i=1}^n\mathbb{1}[u_i < 0])
$$

其中 $\ell(u_i)$ 是零一损失（例如，合页损失）的基代理损失，并且需要学习最优加权变量 $\mathbf{w}$。

> where $\ell(u_i)$ is a base surrogate loss for the zero-one loss (e.g. hinge loss) and the optimal weighting variable $\mathbf{w}$ is to be learned.

给定标签损坏率 `\rho`，*噪声剪枝课程损失*（**NPCL**）的构建基于这样的直觉：一个理想模型应该正确分类带有干净标签的 $n(1-\rho)$ 样本，但错误分类 $n\rho$ 损坏的标签。如果 `\rho` 是一个已知先验，我们将知道需要剪枝多少样本（具有最大损失的）。假设 $\ell(u_1) \leq \dots \leq \ell(u_n)$，那么 $u_{n(1-\rho)+1} = \dots = u_n =0$，并且以下 NPCL 是仅针对 $n(1-\rho)$ 样本的基本 CL：

英文原文：Given a label corruption rate `\rho`, the *noise pruned curriculum loss* (NPCL) is constructed based on the intuition that an ideal model should correctly classify 

$n(1-\rho)$ samples with clean labels but misclassify 

$n\rho$ corrupted labels. If `\rho` is a known prior, we would know how many samples (with largest losses) to be pruned. Assuming 

$\ell(u_1) \leq \dots \leq \ell(u_n)$, then 

$u_{n(1-\rho)+1} = \dots = u_n =0$ and the following NPCL is the basic CL for only 

$n(1-\rho)$ samples:

$$
\text{NPCL}(\mathbf{u}) = \min_{\mathbf{w}\in\{0,1\}^{n(1-\rho)}} \max(\sum_{i=1}^{n(1-\rho)} w_i \ell(u_i), n(1-\rho) - \sum_{i=1}^{n(1-\rho)} w_i)
$$

在 CIFAR-10 上进行实验时，NPCL 与 GCE 相当，并且在噪声率增加时表现更好。

> When experimenting on CIFAR-10, NPCL is comparable with GCE and performs better when the noise rate increases.

#### 标签校正

> Label Correction

由于已知某些标签不正确，噪声鲁棒训练可以明确地将标签校正考虑在内。

> Since it is known some labels are incorrect, noise-robust training can explicitly take the label correction into consideration.

一种方法是依赖于噪声转移矩阵的估计，并用它来校正前向或后向损失，这被称为 **F-校正**（[Patrini 等人 2017](https://arxiv.org/abs/1609.03683)）。我们首先假设有 `k` 个类别，并且噪声转移矩阵 $C \in [0, 1]^{k\times k}$ 是可观测的，标签翻转概率不依赖于样本输入，而只依赖于标签（即，被称为随机分类噪声，RCN）。让 $\tilde{y}$ 表示一个损坏的标签。`C` 的每个条目表示一个标签翻转到另一个标签的概率[1](https://lilianweng.github.io/posts/2022-04-15-data-gen/#fn:1)，

英文原文：One approach is to rely on the estimation of a noise transition matrix and use that to correct the forward or backward loss, named F-correction ([Patrini et al. 2017](https://arxiv.org/abs/1609.03683)). Let’s first assume that there are `k` classes and the noise transition matrix 

$C \in [0, 1]^{k\times k}$ is observable and the label flipping probability does not depend on the sample input but only the label (i.e. known as random classification noise, RCN). Let 

$\tilde{y}$ denote a corrupted label. Each entry of `C` represents the probability of one label flipping to another[1](https://lilianweng.github.io/posts/2022-04-15-data-gen/#fn:1),

$$
C_{ij} = p(\tilde{y}= j \vert y =i, \mathbf{x}) \approx p(\tilde{y}= j \vert y =i)
$$

然后我们可以进行前向标签校正过程，将噪声转移矩阵的先验知识纳入预测中。

> Then we can proceed a forward label correction procedure to incorporate the prior knowledge of noisy transition matrix into the prediction.

$$
\begin{aligned}
\mathcal{L}(\hat{p}(\tilde{y}\vert\mathbf{x}), y)
&= - \log \hat{p}(\tilde{y}=i\vert\mathbf{x}) \\
&= - \log \sum_{j=1}^k p(\tilde{y}=i\vert y=j) \hat{p}(y=j\vert\mathbf{x}) \\
&= - \log \sum_{j=1}^k C_{ji} \hat{p}(y=j\vert\mathbf{x})
\end{aligned}
$$

以矩阵形式，我们有 $\mathcal{L}(\hat{p}(y \vert \mathbf{x})) = - \log C^\top \hat{p}(y \vert \mathbf{x})$。然而，这样的噪声转移矩阵通常是*未知*的。如果我们能够访问一个干净的数据集，噪声矩阵 $C$ 可以通过计算干净数据上的混淆矩阵来估计（[Hendrycks 等人 2018](https://arxiv.org/abs/1802.05300)）。接下来，我们将一个干净的、可信的数据集表示为 $\mathcal{D}_c$，一个噪声数据集表示为 $\mathcal{D}_n$。

> In matrix form, we have $\mathcal{L}(\hat{p}(y \vert \mathbf{x})) = - \log C^\top \hat{p}(y \vert \mathbf{x})$. However, such a noise transition matrix is usually *unknown*. If we have access to a clean dataset, the noise matrix $C$ can be estimated ([Hendrycks et al. 2018](https://arxiv.org/abs/1802.05300)) by calculating confusion matrix on the clean data. Let’s denote a clean trusted dataset as $\mathcal{D}_c$ and a noisy dataset as $\mathcal{D}_n$ going forward.

$$
\hat{C}_{ij}
= \frac{1}{\vert \mathcal{A}_i\vert} \sum_{\mathbf{x} \in \mathcal{A}_i} \hat{p}(\tilde{y}=j \vert y=i, \mathbf{x})
\approx p(\tilde{y}=j \vert y=i)
$$

其中 $\mathcal{A}_i$ 是来自 $\mathcal{D}_c$ 的数据点的一个子集，其标签为 $i$。

> where $\mathcal{A}_i$ is a subset of data points from $\mathcal{D}_c$ with label $i$.

令 $f(x) = \hat{p}(\tilde{y} \vert \mathbf{x}; \theta)$，并且该模型应该使用 $\mathcal{L}(f(\mathbf{x}), y)$ 在干净数据 $\mathcal{D}_c$ 上进行训练，并使用 $\mathcal{L}(\hat{C}^\top f(\mathbf{x}), \hat{y})$ 在噪声数据 $\mathcal{D}_n$ 上进行训练。

> Let $f(x) = \hat{p}(\tilde{y} \vert \mathbf{x}; \theta)$ and this model should be trained with $\mathcal{L}(f(\mathbf{x}), y)$ on clean data $\mathcal{D}_c$ and with $\mathcal{L}(\hat{C}^\top f(\mathbf{x}), \hat{y})$ on noisy data $\mathcal{D}_n$.

![Algorithm of gold loss correction (GLC), estimating the noise transition matrix with a trusted dataset. (Image source: Hendrycks et al. 2018 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/GLC.png)

如果可信训练数据集 $\mathcal{D}_c$ 变得很大，我们可以只用干净数据训练一个神经网络，并*蒸馏*其知识到主模型（即在测试时进行预测的最终模型）中，使用修正的**伪标签**（[Li et al. 2017](https://arxiv.org/abs/1703.02391)）。主模型在整个数据集上进行训练，$\mathcal{D} = \mathcal{D}_c \cup \mathcal{D}_n$。如果可用，知识图谱中标签关系的“辅助”信息可以选择性地融入蒸馏过程，以帮助提高在有限数据上训练的网络预测的鲁棒性。

英文原文：If the trusted training dataset 

$\mathcal{D}_c$ gets large, we can train a neural network only on clean data and *distill* its knowledge into the primary model (i.e. the final model to make predictions at test time) using corrected pseudo labels ([Li et al. 2017](https://arxiv.org/abs/1703.02391)). The primary model is trained on the entire dataset, 

$\mathcal{D} = \mathcal{D}_c \cup \mathcal{D}_n$. Optionally the “side” information of label relations in the knowledge graph, if available, can be incorporated into distillation to help the robustness of the predictions of the network that is trained on limited data.

标签校正蒸馏的工作原理如下：

> The label correction distillation works as following:

1\. 首先训练一个辅助模型 $f_c$ 来自小型干净数据集 $\mathcal{D}_c$ 为每个样本提供软标签 $x_i$，$s_i = \delta(f_c(\mathbf{x}_i)/T)$ 是带有温度 $T$ 的 sigmoid 激活函数。

2\. 由于干净数据集不大，$f_c$ 容易过拟合，[Li et al. (2017)](https://arxiv.org/abs/1703.02391) 转向一个知识图谱 $\mathcal{G}$，该图谱定义了标签空间中的关系，并相应地在标签之间*传播*预测。新的软标签表示为 $\hat{s}_i = \mathcal{G}(s_i)$。

3\. 主要模型 $f$ 使用来自 $f_c$ 的预测进行训练以进行模仿，

英文原文：

1\. First train an auxiliary model $f_c$ from the small clean dataset $\mathcal{D}_c$ to provide a soft label for each sample $x_i$, $s_i = \delta(f_c(\mathbf{x}_i)/T)$ is the sigmoid activation with temperature $T$.

2\. Because the clean dataset is not large, $f_c$ is likely to overfit, [Li et al. (2017)](https://arxiv.org/abs/1703.02391) turn to a knowledge graph $\mathcal{G}$ that defines the relations in the label space and *propagate* the prediction among labels accordingly. The new soft label is donated as $\hat{s}_i = \mathcal{G}(s_i)$.

3\. The primary model $f$ is trained with predictions from $f_c$ to imitate,

$$
\mathcal{L}(y_i, f(\mathbf{x}_i)) = \text{CE}(\underbrace{\lambda y_i + (1 - \lambda) \hat{s}_i}_\text{pseudo label}, f(\mathbf{x}_i))
$$

#### 样本重加权与选择

> Sample Reweighting and Selection

有些样本比其他样本更有可能具有不准确的标签。这种估计为我们提供了直觉，即在损失函数中哪些样本应该被赋予更小或更大的权重。然而，考虑到训练数据中的两种偏差：类别不平衡和噪声标签，实际上存在一种矛盾的偏好——我们倾向于选择损失较大的样本来平衡标签分布，但又倾向于选择损失较小的样本来减轻潜在的噪声。因此，一些工作（[Ren et al. 2018](https://arxiv.org/abs/1803.09050)）认为，为了学习训练数据偏差的一般形式，*有必要*拥有*一个小的无偏验证集*来指导训练。本节介绍的样本重加权方法都假设可以访问一小部分可信的干净数据。

> Some samples may be more likely to have inaccurate labels than others. Such estimation gives us intuition on which samples should be weighted less or more in the loss function. However, considering two types of biases in training data, class imbalance and noisy labels, there is actually a contradictory preference — We would prefer samples with larger loss to balance the label distribution but those with smaller loss for mitigating the potential noise. Some work ([Ren et al. 2018](https://arxiv.org/abs/1803.09050)) thus argue that in order to learn general forms of training data biases, it is *necessary* to have *a small unbiased validation* to guide training. The sample reweighting methods presented in this section all assume access to a small trusted set of clean data.

考虑一个带有随机分类噪声的二分类任务，$y, \hat{y} \in \{-1, +1\}$，标签翻转概率 $\rho_{-1}, \rho_{+1} \in [0, 0.5)$ 定义为：

> Considering a binary classification task with random classification noise, $y, \hat{y} \in \{-1, +1\}$, the label flipping probabilities, $\rho_{-1}, \rho_{+1} \in [0, 0.5)$, are defined as:

$$
\rho_{-1} = P(\tilde{y} = +1 \vert y=-1)\quad\rho_{+1} = P(\tilde{y}=-1 \vert y =+1)
$$

[Liu & Tao (2015)](https://arxiv.org/abs/1411.7718) 应用 **重要性重加权** 来调整观测到的 $\hat{y}$ 的加权分布，使其与不可观测的 `y` 的分布相匹配。设 $\mathcal{D}$ 为真实数据分布，$\mathcal{D}_\rho$ 为损坏版本。

英文原文：[Liu & Tao (2015)](https://arxiv.org/abs/1411.7718) applies importance reweighting to adjust the weighted distribution of observed 

$\hat{y}$ to match the distribution of unobservable `y`. Let 

$\mathcal{D}$ be the true data distribution and 

$\mathcal{D}_\rho$ be the corrupted version.

$$
\begin{aligned}
\mathcal{L}_{\ell,\mathcal{D}}(f)
&= \mathbb{E}_{(\mathbf{x},y)\sim \mathcal{D}}[\ell(f(\mathbf{x}), y)] \\
&= \mathbb{E}_{(\mathbf{x},\tilde{y})\sim \mathcal{D}_\rho} \Big[ \frac{P_\mathcal{D}(\mathbf{x}, y=\tilde{y})}{P_{\mathcal{D}_\rho}(\mathbf{x}, \tilde{y})} \ell(f(\mathbf{x}), \tilde{y}) \Big] \\
&= \mathbb{E}_{(\mathbf{x},\tilde{y})\sim \mathcal{D}_\rho} \Big[ \frac{P_\mathcal{D}(y=\tilde{y} \vert \mathbf{x})}{P_{\mathcal{D}_\rho}(\tilde{y} \vert \mathbf{x})} \ell(f(\mathbf{x}), \tilde{y}) \Big] & \text{; because }P_\mathcal{D}(\mathbf{x})=P_{\mathcal{D}_\rho}(\mathbf{x}) \\
&= \mathbb{E}_{(\mathbf{x},\tilde{y})\sim \mathcal{D}_\rho} [ w(\mathbf{x}, \hat{y})\ell(f(\mathbf{x}), \tilde{y}) ]
= \mathcal{L}_{w\ell,\mathcal{D}}(f)
\end{aligned}
$$

因为，

> Because,

$$
\begin{aligned}
P_{\mathcal{D}_\rho}(\tilde{y} \vert \mathbf{x})
&= P_\mathcal{D}(y = \tilde{y} \vert \mathbf{x}) P_{\mathcal{D}_\rho}(\tilde{y} \vert y=\tilde{y}) +
P_\mathcal{D}(y = - \tilde{y} \vert \mathbf{x}) P_{\mathcal{D}_\rho}(\tilde{y} \vert y = - \tilde{y}) \\
&= P_\mathcal{D}(y = \tilde{y} \vert \mathbf{x}) (1 - P_{\mathcal{D}_\rho}(- \tilde{y} \vert y=\tilde{y})) +
(1 - P_\mathcal{D}(y = \tilde{y} \vert \mathbf{x})) P_{\mathcal{D}_\rho}(\tilde{y} \vert y = - \tilde{y}) \\
&= P_\mathcal{D}(y = \tilde{y} \vert \mathbf{x}) (1 - \rho_{\tilde{y}}) +
(1 - P_\mathcal{D}(y = \tilde{y} \vert \mathbf{x})) \rho_{-\tilde{y}} \\
&= P_\mathcal{D}(y = \tilde{y} \vert \mathbf{x})(1 - \rho_{\tilde{y}} - \rho_{-\tilde{y}}) + \rho_{-\tilde{y}}
\end{aligned}
$$

因此，分配给噪声样本的权重为，

> Thus the weight assigned to a noisy sample is,

$$
w(x, \tilde{y})
= \frac{P_\mathcal{D}(y=\tilde{y} \vert \mathbf{x})}{P_{\mathcal{D}_\rho}(\tilde{y} \vert \mathbf{x})}
= \frac{P_{\mathcal{D}_\rho}(\tilde{y} \vert \mathbf{x}) - \rho_{-\tilde{y}}}{(1-\rho_0-\rho_1) P_{\mathcal{D}_\rho}(\tilde{y} \vert \mathbf{x})}
$$

其中 $P_{\mathcal{D}_\rho}(\tilde{y} \vert \mathbf{x})$ 可以使用简单的逻辑回归进行估计，但估计噪声率更具挑战性。朴素交叉验证可能有效，但成本很高，因为其质量取决于可用可信标签的数量。该论文首先近似噪声率的上限，$\rho_\tilde{y} \leq P_{\mathcal{D}_\rho}(- \tilde{y} \vert \mathbf{x})$ 然后使用一个温和的假设来有效地估计它们，$\hat{\rho}_{\tilde{y}} = \min_{\mathbf{x} \in {\mathbf{x}_1, \dots, \mathbf{x}_n}} \hat{P}_{\mathcal{D}_\rho}(- \tilde{y} \vert \mathbf{x})$。在他们的实验中，重要性重加权的优势仅在不同数据集之间有所不同，并且通常在噪声率较高时更有益。

> where $P_{\mathcal{D}_\rho}(\tilde{y} \vert \mathbf{x})$ can be estimated using a simple logistic regression, but estimating the note rates is more challenging. Naive cross-validation can work out but is costly as the quality depends on the amount of trusted labels available. The paper approximates the upper bounds for noise rates first, $\rho_\tilde{y} \leq P_{\mathcal{D}_\rho}(- \tilde{y} \vert \mathbf{x})$ and then use a mild assumption to efficiently estimate them, $\hat{\rho}_{\tilde{y}} = \min_{\mathbf{x} \in {\mathbf{x}_1, \dots, \mathbf{x}_n}} \hat{P}_{\mathcal{D}_\rho}(- \tilde{y} \vert \mathbf{x})$. In their experiments, the advantage of importance reweighting only varies across datasets and is more beneficial when the noise rates are high in general.

样本重加权方案可以通过单独的网络学习。*学习重加权* (**L2R**; [Ren et al. 2018](https://arxiv.org/abs/1803.09050)) 是一种元学习方法，旨在直接优化权重，以在已知干净数据集上追求最佳验证性能。每个示例根据其梯度方向被分配权重。要最小化的加权损失 $\theta^{\ast}(\mathbf{w})$ 涉及一组训练权重 $\{w_i\}_{i=1}^n$ 作为未知超参数。这些样本训练权重 `w_i` 被学习以最小化在这个无偏验证集上的损失，$\mathcal{D}_c = \{x^\text{valid}_j\}_{j=1}^m$。

英文原文：Sample reweighting schemes can be learned by a separate network. *Learning to reweight* (L2R; [Ren et al. 2018](https://arxiv.org/abs/1803.09050)) is a meta-learning approach to directly optimize the weights in pursuit of best validation performance on a known set of clean data. Each example gets assigned with the weight based on its gradient direction. The weighted loss to minimize 

$\theta^{\ast}(\mathbf{w})$ involves a set of training weights 

$\{w_i\}_{i=1}^n$ as unknown hyperparameters. These sample training weights `w_i` are learned to minimize the loss on this unbiased validate set, 

$\mathcal{D}_c = \{x^\text{valid}_j\}_{j=1}^m$.

$$
\begin{aligned}
\theta^{*}(\mathbf{w}) &= \arg\min_\theta \sum_{i=1}^n w_i f(x_i; \theta) \\
\text{where optimal }\mathbf{w}^{*} &= \arg\min_{\mathbf{w}, \mathbf{w} \geq \mathbf{0}} \frac{1}{m} \sum_{j=1}^m f(\mathbf{x}^\text{valid}_j; \theta^{*}(\mathbf{w}))
\end{aligned}
$$

学习过程涉及两个嵌套的优化循环，因此相当昂贵，训练时间是3倍。

> The learning process involves two nested loops of optimization, so pretty expensive, 3x training time.

![Illustration of updates implemented by second order automatic differentiation . (Image source: Ren et al. 2018 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/L2R-backprop.png)

他们进行了实验，包括 (1) 在二分类 MNIST 上测试 L2R 在类别分布不平衡时的鲁棒性，以及 (2) 在带有噪声标签的 CIFAR-10 上进行实验。L2R 在当时的两项任务中均表现优于其他基线方法。

> They ran experiments on (1) two-class MNIST to test the robustness of L2R when the class distribution is imbalanced and (2) CIFAR-10 with noisy labels.  L2R is shown to be better than other baseline methods at the time on both tasks.

![Left: Imbalanced classes on MNIST (class 4 and 9); Right: Effect of the number of clean samples. Task is on CIFAR-10 with 40% of data flipped to label 3. (Image source: Ren et al. 2018 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/L2R-exp.png)

**MentorNet** ([Jiang et al. 2018](https://arxiv.org/abs/1712.05055)) 使用师生课程学习来加权数据。它包含两个不同的网络，一个导师网络和一个学生网络。导师网络为学生提供了一个数据驱动的课程（即样本训练加权方案），以便学生专注于学习可能正确的标签。

> **MentorNet** ([Jiang et al. 2018](https://arxiv.org/abs/1712.05055)) uses teach-student curriculum learning to weight data. It incorporates two different networks, a mentor and a student. The mentor network provides a data-driven curriculum (i.e. sample training weighting scheme) for the student to focus on learning likely correct labels.

设$g_\psi$为由$\psi$，$f_\theta$为由$\theta$以及$G$为由$\lambda$。给定训练数据$\mathcal{D} = \{(\mathbf{x}_i, y_i)\}_{i=1}^n$用于$k$ -类分类任务，MentorNet需要预测一个时变潜在权重变量$\mathbf{w} \in [0, 1]^{n \times k}$以指导StudentNet的学习，并以StudentNet处理的中间特征$f$，$\mathbf{z}_i = \phi_{f_\theta}(\mathbf{x}_i, y_i)$：

> Let $g_\psi$ be the MentorNet parameterized by $\psi$ , $f_\theta$  be the StudentNet parametrized by $\theta$ and $G$ be a predefined curriculum parameterized by $\lambda$. Given the training data $\mathcal{D} = \{(\mathbf{x}_i, y_i)\}_{i=1}^n$ for a $k$ -class classification task, the MentorNet needs to predict a time-varying latent weight variable $\mathbf{w} \in [0, 1]^{n \times k}$ to guide the learning of StudentNet, taking an intermediate feature processed by StudentNet $f$ , $\mathbf{z}_i = \phi_{f_\theta}(\mathbf{x}_i, y_i)$:

$$
g_{\psi^{*}}(\mathbf{z}_i) = \arg\min_{w_i \in [0,1]} \mathcal{L}(\theta, \mathbf{w}), \forall i \in [1, n]
$$

StudentNet 旨在最小化以下学习目标，

> StudentNet learns to minimize the following learning objective,

$$
\begin{aligned}
\mathcal{L}(\theta, \mathbf{w})
&= \frac{1}{n}\sum_{i=1}^n \mathbf{w}_i^\top \ell(y_i, f_\theta(\mathbf{x}_i)) + G_\lambda(\mathbf{w}) + \alpha |\theta|^2_2 \\
&= \frac{1}{n}\sum_{i=1}^n g_\psi(\mathbf{z}_i)^\top \ell_i + G_\lambda(\mathbf{w}) + \alpha |\theta|^2_2 & \text{; Let }\ell_i = \ell(y_i, f_\theta(\mathbf{x}_i)) \\
\end{aligned}
$$

导师网络 $g_\psi$ 使用交叉熵在输入 $(\phi_{f_\theta}(\mathbf{x}_i, y_i), w^{*}_i)$ 上进行训练，其中 $v^{\ast}_i=1$ 如果 $y_i$ 已知是正确标签，否则为0。MentorNet 的架构不必非常复杂。在该论文中，他们采用了一个 LSTM 层来捕获时间上的预测方差。

> The mentor network $g_\psi$ is trained with cross entropy on the input $(\phi_{f_\theta}(\mathbf{x}_i, y_i), w^{*}_i)$ , where $v^{\ast}_i=1$ if $y_i$ is known to be a correct label, otherwise 0. The architecture of MentorNet does not have to be very complicated. In the paper, they adopted a LSTM layer to capture the prediction variance in time.

![Model architecture of MentorNet and StudentNet which are trained simultaneously, where MentorNet predicts the sample weights for StudentNet to train on. (Image source: Jiang et al. 2018 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/MentorNet.png)

不同于 MentorNet（其中一个网络明确地为另一个网络学习加权方案和课程），**Co-teaching**（[Han et al. 2018](https://arxiv.org/abs/1804.06872)）同时训练两个神经网络，`f_1` 和 `f_2`，并通过选择性地相互馈送数据来让它们相互教学。Co-teaching 包含三个步骤：

英文原文：Different from MentorNet where one network explicitly learns weighting scheme and curriculum for the other network, Co-teaching ([Han et al. 2018](https://arxiv.org/abs/1804.06872)) trains two neural networks, `f_1` and `f_2`, simultaneously and lets them teach each other by feeding data to each other selectively. Co-teaching consists of three steps:

1\. 首先，每个网络前向传播当前的小批量数据，并选择可能带有干净标签的样本；

2\. 然后，两个网络交换关于批次中哪些样本应该用于训练的信息。选择小损失实例，因为它们更有可能与正确标签相关联。要选择的批次百分比由时间相关函数 $R(T)$ 确定。$R(T)$ 的值随时间减少，因为随着训练的进行，网络更有可能过拟合并记住噪声标签，因此我们使用较小的采样百分比来保持所选数据的高质量。

3\. 最后，每个网络使用其对等网络选择的数据运行反向传播更新。

英文原文：

1\. First, each network feeds forward the current mini-batch and selects samples with potentially clean labels;

2\. Then two networks exchange information on which samples in the batch should be used for training.  Small-loss instances are selected as they are more likely to be associated with correct labels. The percentage of the batch to select is determined by a time-dependent function $R(T)$. The value of $R(T)$ decreases in time because the network is more likely to overfit and memorize noisy labels as training progresses and thus we use a smaller sampling percentage to keep the selected data quality high.

3\. Finally, each network runs back-propagation updates with the data selected by its peer.

根据他们的实验，当噪声率高或损坏转移矩阵不对称时，co-teaching 的表现优于 [F-correction](https://lilianweng.github.io/posts/2022-04-15-data-gen/#fcorrection)。

> According to their experiments, co-teaching performs better than [F-correction](https://lilianweng.github.io/posts/2022-04-15-data-gen/#fcorrection) where the noise rates are high or the corruption transition matrix is not symmetric.

![Algorithm of co-teaching in which two networks are trained separately in parallel and each selects samples for the other to train on. (Image source: Han et al. 2018 )](https://lilianweng.github.io/posts/2022-04-15-data-gen/co-teaching.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Apr 2022). Learning with not enough data part 3: data generation. Lil’Log. https://lilianweng.github.io/posts/2022-04-15-data-gen/.

> Weng, Lilian. (Apr 2022). Learning with not enough data part 3: data generation. Lil’Log. https://lilianweng.github.io/posts/2022-04-15-data-gen/.

或

> Or

```
@article{weng2022datagen,
  title   = "Learning with not Enough Data Part 3: Data Generation",
  author  = "Weng, Lilian",
  journal = "Lil'Log",
  year    = "2022",
  month   = "Apr",
  url     = "https://lilianweng.github.io/posts/2022-04-15-data-gen/"
}
```

### 参考文献

> Reference

[1] Zhang et al. [“Adversarial AutoAgument”](https://arxiv.org/abs/1912.11188) ICLR 2020.

> [1] Zhang et al. [“Adversarial AutoAgument”](https://arxiv.org/abs/1912.11188) ICLR 2020.

[2] Kumar et al. [“Data Augmentation using Pre-trained Transformer Models.”](https://arxiv.org/abs/2003.02245) AACL 2020 Workshop.

> [2] Kumar et al. [“Data Augmentation using Pre-trained Transformer Models.”](https://arxiv.org/abs/2003.02245) AACL 2020 Workshop.

[3] Anaby-Tavor et al. [“Not enough data? Deep learning to rescue!”](https://arxiv.org/abs/1911.03118) AAAI 2020.

> [3] Anaby-Tavor et al. [“Not enough data? Deep learning to rescue!”](https://arxiv.org/abs/1911.03118) AAAI 2020.

[4] Wang et al. [“Want To Reduce Labeling Cost? GPT-3 Can Help.”](https://arxiv.org/abs/2108.13487) EMNLP 2021.

> [4] Wang et al. [“Want To Reduce Labeling Cost? GPT-3 Can Help.”](https://arxiv.org/abs/2108.13487) EMNLP 2021.

[5] Wang et al. [“Towards Zero-Label Language Learning.”](https://arxiv.org/abs/2109.09193) arXiv preprint arXiv:2109.09193 (2021).

> [5] Wang et al. [“Towards Zero-Label Language Learning.”](https://arxiv.org/abs/2109.09193) arXiv preprint arXiv:2109.09193 (2021).

[6] Schick & Schutze. [Generating Datasets with Pretrained Language Models."](https://arxiv.org/abs/2104.07540) EMNLP 2021.

> [6] Schick & Schutze. [Generating Datasets with Pretrained Language Models."](https://arxiv.org/abs/2104.07540) EMNLP 2021.

[7] Han et al. [“Unsupervised Neural Machine Translation with Generative Language Models Only.”](https://arxiv.org/abs/2110.05448) arXiv preprint arXiv:2110.05448 (2021).

> [7] Han et al. [“Unsupervised Neural Machine Translation with Generative Language Models Only.”](https://arxiv.org/abs/2110.05448) arXiv preprint arXiv:2110.05448 (2021).

[8] Guo et al. [“Augmenting data with mixup for sentence classification: An empirical study.”](https://arxiv.org/abs/1905.08941) arXiv preprint arXiv:1905.08941 (2019).

> [8] Guo et al. [“Augmenting data with mixup for sentence classification: An empirical study.”](https://arxiv.org/abs/1905.08941) arXiv preprint arXiv:1905.08941 (2019).

[9] Ekin D. Cubuk et al. [“AutoAugment: Learning augmentation policies from data.”](https://arxiv.org/abs/1805.09501) arXiv preprint arXiv:1805.09501 (2018).

> [9] Ekin D. Cubuk et al. [“AutoAugment: Learning augmentation policies from data.”](https://arxiv.org/abs/1805.09501) arXiv preprint arXiv:1805.09501 (2018).

[10] Daniel Ho 等人。 [“基于种群的增强：高效学习增强策略调度。”](https://arxiv.org/abs/1905.05393) ICML 2019。

> [10] Daniel Ho et al. [“Population Based Augmentation: Efficient Learning of Augmentation Policy Schedules.”](https://arxiv.org/abs/1905.05393) ICML 2019.

[11] Cubuk 和 Zoph 等人。 [“RandAugment：减少搜索空间的实用自动化数据增强。”](https://arxiv.org/abs/1909.13719) arXiv 预印本 arXiv:1909.13719 (2019)。

> [11] Cubuk & Zoph et al. [“RandAugment: Practical automated data augmentation with a reduced search space.”](https://arxiv.org/abs/1909.13719) arXiv preprint arXiv:1909.13719 (2019).

[12] Zhang 等人。 [“mixup：超越经验风险最小化。”](https://arxiv.org/abs/1710.09412) ICLR 2017。

> [12] Zhang et al. [“mixup: Beyond Empirical Risk Minimization.”](https://arxiv.org/abs/1710.09412) ICLR 2017.

[13] Yun 等人。 [“CutMix：使用可定位特征训练强分类器的正则化策略。”](https://arxiv.org/abs/1905.04899) ICCV 2019。

> [13] Yun et al. [“CutMix: Regularization Strategy to Train Strong Classifiers with Localizable Features.”](https://arxiv.org/abs/1905.04899) ICCV 2019.

[14] Kalantidis 等人。 [“对比硬负样本混合”](https://arxiv.org/abs/2010.01028) NeuriPS 2020。

> [14] Kalantidis et al. [“Mixing of Contrastive Hard Negatives”](https://arxiv.org/abs/2010.01028) NeuriPS 2020.

[15] Wei 和 Zou。 [“EDA：用于提升文本分类任务性能的简易数据增强技术。”](https://arxiv.org/abs/1901.11196) EMNLP-IJCNLP 2019。

> [15] Wei & Zou. [“EDA: Easy data augmentation techniques for boosting performance on text classification tasks.”](https://arxiv.org/abs/1901.11196)  EMNLP-IJCNLP 2019.

[16] Kobayashi。 [“上下文增强：通过具有范式关系的词进行数据增强。”](https://arxiv.org/abs/1805.06201) NAACL 2018

> [16] Kobayashi. [“Contextual Augmentation: Data Augmentation by Words with Paradigmatic Relations.”](https://arxiv.org/abs/1805.06201) NAACL 2018

[17] Fang 等人。 [“CERT：用于语言理解的对比自监督学习。”](https://arxiv.org/abs/2005.12766) arXiv 预印本 arXiv:2005.12766 (2020)。

> [17] Fang et al. [“CERT: Contrastive self-supervised learning for language understanding.”](https://arxiv.org/abs/2005.12766) arXiv preprint arXiv:2005.12766 (2020).

[18] Gao 等人。 [“SimCSE：简单的句子嵌入对比学习。”](https://arxiv.org/abs/2104.08821) arXiv 预印本 arXiv:2104.08821 (2020)。 [[代码](https://github.com/princeton-nlp/SimCSE)]

> [18] Gao et al. [“SimCSE: Simple Contrastive Learning of Sentence Embeddings.”](https://arxiv.org/abs/2104.08821) arXiv preprint arXiv:2104.08821 (2020). [[code](https://github.com/princeton-nlp/SimCSE)]

[19] Shen 等人。 [“一种简单但难以超越的自然语言理解和生成数据增强方法。”](https://arxiv.org/abs/2009.13818) arXiv 预印本 arXiv:2009.13818 (2020) [[代码](https://github.com/dinghanshen/cutoff)]

> [19] Shen et al. [“A Simple but Tough-to-Beat Data Augmentation Approach for Natural Language Understanding and Generation.”](https://arxiv.org/abs/2009.13818) arXiv preprint arXiv:2009.13818 (2020) [[code](https://github.com/dinghanshen/cutoff)]

[20] Wang 和 van den Oord。 [“音频表示的多格式对比学习。”](https://arxiv.org/abs/2103.06508) NeuriPS Workshop 2020。

> [20] Wang & van den Oord. [“Multi-Format Contrastive Learning of Audio Representations.”](https://arxiv.org/abs/2103.06508)  NeuriPS Workshop 2020.

[21] Wu 等人。 [“条件BERT上下文增强”](https://arxiv.org/abs/1812.06705) arXiv 预印本 arXiv:1812.06705 (2018)。

> [21] Wu et al. [“Conditional BERT Contextual Augmentation”](https://arxiv.org/abs/1812.06705) arXiv preprint arXiv:1812.06705 (2018).

[22 Zhu 等人。 [“FreeLB：用于自然语言理解的增强对抗训练。”](https://arxiv.org/abs/1909.11764) ICLR 2020。

> [22 Zhu et al. [“FreeLB: Enhanced Adversarial Training for Natural Language Understanding.”](https://arxiv.org/abs/1909.11764) ICLR 2020.

[23] 亲和性与多样性：量化数据增强机制\nGontijo-Lopes 等人。 2020 ([https://arxiv.org/abs/2002.08973](https://arxiv.org/abs/2002.08973))

> [23] Affinity and Diversity: Quantifying Mechanisms of Data Augmentation
> Gontijo-Lopes et al. 2020 ([https://arxiv.org/abs/2002.08973](https://arxiv.org/abs/2002.08973))

[24] Song 等人。 [“使用深度神经网络从噪声标签中学习：一项综述。”](https://arxiv.org/abs/2007.08199) TNNLS 2020。

> [24] Song et al. [“Learning from Noisy Labels with Deep Neural Networks: A Survey.”](https://arxiv.org/abs/2007.08199) TNNLS 2020.

[25] Zhang 和 Sabuncu。 [“用于训练带有噪声标签的深度神经网络的广义交叉熵损失。”](https://arxiv.org/abs/1805.07836) NeuriPS 2018。

> [25] Zhang & Sabuncu. [“Generalized cross entropy loss for training deep neural networks with noisy labels.”](https://arxiv.org/abs/1805.07836) NeuriPS 2018.

[26] Goldberger 和 Ben-Reuven。 [“使用噪声适应层训练深度神经网络。”](https://openreview.net/forum?id=H12GRgcxg) ICLR 2017。

> [26] Goldberger & Ben-Reuven. [“Training deep neural-networks using a noise adaptation layer.”](https://openreview.net/forum?id=H12GRgcxg) ICLR 2017.

[27] Sukhbaatar 等人。 [“使用噪声标签训练卷积网络。”](https://arxiv.org/abs/1406.2080) ICLR Workshop 2015。

> [27] Sukhbaatar et al. [“Training convolutional networks with noisy labels.”](https://arxiv.org/abs/1406.2080) ICLR Workshop 2015.

[28] Patrini 等人。 [“使深度神经网络对标签噪声具有鲁棒性：一种损失校正方法”](https://arxiv.org/abs/1609.03683) CVPR 2017。

> [28] Patrini et al. [“Making Deep Neural Networks Robust to Label Noise: a Loss Correction Approach”](https://arxiv.org/abs/1609.03683) CVPR 2017.

[29] Hendrycks 等人。 [“使用可信数据训练深度网络，以应对受严重噪声损坏的标签。”](https://arxiv.org/abs/1802.05300) NeuriPS 2018。

> [29] Hendrycks et al. [“Using trusted data to train deep networks on labels corrupted by severe noise.”](https://arxiv.org/abs/1802.05300) NeuriPS 2018.

[30] Zhang 和 Sabuncu。 [“用于训练带有噪声标签的深度神经网络的广义交叉熵损失。”](https://arxiv.org/abs/1805.07836) NeuriPS 2018。

> [30] Zhang & Sabuncu. [“Generalized cross entropy loss for training deep neural networks with noisy labels.”](https://arxiv.org/abs/1805.07836) NeuriPS 2018.

[31] Lyu 和 Tsang。 [“课程损失：针对标签损坏的鲁棒学习和泛化。”](https://arxiv.org/abs/1905.10045) ICLR 2020。

> [31] Lyu & Tsang. [“Curriculum loss: Robust learning and generalization against label corruption.”](https://arxiv.org/abs/1905.10045) ICLR 2020.

[32] Han 等人。 [“协同教学：使用极端噪声标签对深度神经网络进行鲁棒训练。”](https://arxiv.org/abs/1804.06872) NeuriPS 2018。 ([代码](https://github.com/bhanML/Co-teaching))

> [32] Han et al. [“Co-teaching: Robust training of deep neural networks with extremely noisy labels.”](https://arxiv.org/abs/1804.06872) NeuriPS 2018. ([code](https://github.com/bhanML/Co-teaching))

[33] Ren 等人。 [“学习重新加权样本以实现鲁棒深度学习。”](https://arxiv.org/abs/1803.09050) ICML 2018。

> [33] Ren et al.  [“Learning to reweight examples for robust deep learning.”](https://arxiv.org/abs/1803.09050) ICML 2018.

[34] Jiang 等人。 [“MentorNet：为损坏标签上的超深度神经网络学习数据驱动的课程。”](https://arxiv.org/abs/1712.05055) ICML 2018。

> [34] Jiang et al. [“MentorNet: Learning data-driven curriculum for very deep neural networks on corrupted labels.”](https://arxiv.org/abs/1712.05055) ICML 2018.

[35] Li 等人。[“用蒸馏法从噪声标签中学习。”](https://arxiv.org/abs/1703.02391) ICCV 2017。

> [35] Li et al. [“Learning from noisy labels with distillation.”](https://arxiv.org/abs/1703.02391) ICCV 2017.

[36] Liu 和 Tao。[“通过重要性重加权进行噪声标签分类。”](https://arxiv.org/abs/1411.7718) TPAMI 2015。

> [36] Liu & Tao. [“Classification with noisy labels by importance reweighting.”](https://arxiv.org/abs/1411.7718) TPAMI 2015.

[37] Ghosh 等人。[“深度神经网络在标签噪声下的鲁棒损失函数。”](https://arxiv.org/abs/1712.09482) AAAI 2017。

> [37] Ghosh, et al. [“Robust loss functions under label noise for deep neural networks.”](https://arxiv.org/abs/1712.09482) AAAI 2017.

[38] Hu 等人。[“分布鲁棒监督学习能否产生鲁棒分类器？”](https://arxiv.org/abs/1611.02041) ICML 2018。

> [38] Hu et al. [“Does Distributionally Robust Supervised Learning Give Robust Classifiers? “](https://arxiv.org/abs/1611.02041) ICML 2018.

1\. $y=i$ 并非标注标签为特定值的技术上正确方式，因为我们通常使用独热编码（即 $\mathbf{y} = \mathbf{e}_i$）。我们使用这种形式是为了简化。[↩︎](https://lilianweng.github.io/posts/2022-04-15-data-gen/#fnref:1)

英文原文：

1\. 
$y=i$ is not a technically correct way to annotate a label being a certain value, since we usually use one-hot encoding (i.e. $\mathbf{y} = \mathbf{e}_i$). We use this form for simplicity. [↩︎](https://lilianweng.github.io/posts/2022-04-15-data-gen/#fnref:1)


## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Data Augmentation | 数据增强 | 通过对现有数据进行变换生成新数据，以扩充训练集并提高模型泛化能力。 |
| Data Synthesis | 数据合成 | 利用模型（如生成模型）从头生成全新的数据点。 |
| Language Model (LM) | 语言模型 | 预测文本序列中下一个词或字符概率的模型。 |
| AutoAugment | 自动增强 | 一种通过强化学习搜索最优数据增强策略的方法。 |
| RandAugment | 随机增强 | 简化AutoAugment的搜索空间，通过单个幅度参数控制变换操作的强度。 |
| Mixup | 混合增强 | 通过线性插值组合两个现有样本及其标签来生成新训练样本。 |
| Cutmix | 剪切混合 | 通过将一张图像的局部区域与另一张图像的其余部分结合来生成新样本。 |
| Back-translation | 回译 | 将文本翻译成另一种语言再翻译回来，以生成增强数据。 |
| Dropout | 随机失活 | 一种正则化技术，在训练时随机关闭神经网络中的一部分神经元。 |
| Affinity | 亲和力 | 量化增强操作使训练数据分布偏离模型所学分布的程度。 |
| Diversity | 多样性 | 衡量增强数据相对于模型和学习过程的复杂程度。 |
| Generalized Cross Entropy (GCE) | 广义交叉熵 | 一种对噪声标签具有鲁棒性的交叉熵损失函数泛化形式。 |
| F-correction | F-校正 | 一种标签校正方法，通过估计噪声转移矩阵来修正损失函数。 |
| Importance Reweighting | 重要性重加权 | 根据样本的重要性调整其在损失函数中的权重，以处理噪声标签。 |
| Co-teaching | 协同教学 | 两个神经网络相互选择可能带有干净标签的样本进行训练，以应对噪声标签。 |
