# 降低语言模型中的毒性

> Reducing Toxicity in Language Models

> 来源：Lil'Log / Lilian Weng，2021-03-21
> 原文链接：https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/
> 分类：自然语言处理 / 语言模型安全

## 核心要点

- 大型预训练语言模型因训练数据来源广泛而不可避免地习得有害行为和偏见。
- 减少语言模型中不安全内容的工作面临内容类型多样和缺乏统一分类标准的挑战。
- “毒性”是一个广义术语，用于描述多种不安全内容，其具体定义因社会背景和个体认知而异。
- 有毒内容的分类是主观的，常采用分层分类法，如OLID数据集所基于的方法。
- 毒性检测的数据集可通过人工标注（专家、众包、专业审核员）或半监督方法（如黑名单、协同训练）构建。
- 毒性检测模型可通过从头训练分类器、微调预训练模型或采用对抗性攻击与训练策略来提升鲁棒性。
- Perspective API是广泛使用的商业毒性检测工具，但存在对少数群体表现出偏见等已知问题。
- 自诊断和自去偏等基于提示的方法，利用预训练语言模型的内部知识，无需标注数据即可检测和降低不期望属性。
- 去毒化方法包括黑名单过滤、词汇转移、基于提示的自去偏以及无监督文本风格迁移。
- 构建安全聊天机器人需要系统级解决方案，涵盖不安全内容检测、安全生成、避免敏感话题和缓解性别偏见。

## 正文

大型预训练[语言模型](https://lilianweng.github.io/posts/2019-01-31-lm/)通过大量的在线数据进行训练。它们不可避免地从互联网上习得某些有害行为和偏见。预训练语言模型非常强大，在许多自然语言处理任务中取得了巨大成功。然而，要将它们安全地部署到实际的现实世界应用中，需要对模型生成过程进行严格的安全控制。

> Large pretrained [language models](https://lilianweng.github.io/posts/2019-01-31-lm/) are trained over a sizable collection of online data. They unavoidably acquire certain toxic behavior and biases from the Internet. Pretrained language models are very powerful and have shown great success in many NLP tasks. However, to safely deploy them for practical real-world applications demands a strong safety control over the model generation process.

减少各种不安全内容的工作面临许多挑战：

> Many challenges are associated with the effort to diminish various types of unsafe content:

- 首先，存在各种不安全内容类型，例如毒性、辱骂、仇恨言论、偏见、刻板印象、网络欺凌、身份攻击等，这些可能需要也可能不需要不同的处理方式。
- 其次，对于预训练语言模型中不安全行为的分类和定义，目前没有明确且广泛认同的标准。由于社会背景不同，个体认知可能存在很大差异。

> • First, there are a variety of unsafe content types, such as toxicity, abusiveness, hate speech, biases, stereotypes, cyberbullying, identity attacks and more, which may or may not demand different treatment.
> • Second, there is no clearly and widely agreed-upon categorization and definition of unsafe behavior in pretrained language models. Individual perceptions could vary a lot due to different social backgrounds.

在本文中，我们将深入探讨语言模型中的毒性问题。由于我仍在努力寻找有毒内容的具体定义，因此我在下面列举了一些文献中的定义。

> In this post, we delve into the issue of toxicity in language models. As I’m still struggling to find a concrete definition of toxic content, I list a couple in the literature below.

> [[Perspective API](https://support.perspectiveapi.com/s/about-the-api-attributes-and-languages)] 一种粗鲁、不尊重或不合理的评论；可能导致人们退出讨论。

> [[Perspective API](https://support.perspectiveapi.com/s/about-the-api-attributes-and-languages)] A rude, disrespectful, or unreasonable comment; likely to make people leave a discussion.

> [[Kurita et al. 2019](https://arxiv.org/abs/1912.06872)] 可能冒犯或伤害接收者的内容，包括仇恨言论、种族主义和攻击性语言。

> [[Kurita et al. 2019](https://arxiv.org/abs/1912.06872)] Content that can offend or harm its recipients, including hate speech, racism, and offensive language.

> [[Pavlopoulos et al. 2020](https://arxiv.org/abs/2006.00998)] 我们将“毒性”一词用作一个总括性术语，但我们注意到文献中对不同类型的有毒语言或相关现象使用了多个术语：“冒犯性”、“辱骂性”、“仇恨性”等。

> [[Pavlopoulos et al. 2020](https://arxiv.org/abs/2006.00998)] We use the term ’toxic’ as an umbrella term, but we note that the literature uses several terms for different kinds of toxic language or related phenomena: ‘offensive’, ‘abusive’, ‘hateful’, etc.

总的来说，毒性是一个广义术语，用于描述多种类型的不安全内容。本文中的方法可以在给定某种毒性定义（例如，在标注者说明中提出的定义）的情况下应用。如何正确定义毒性概念并因此收集准确的标注标签超出了本文的范围。

> Overall, toxicity is a broad term to describe several types of unsafe content. Methodologies in this post can be applied given some form of definition of toxicity; e.g. presented in the instruction for annotators. How to properly define the concept of toxicity and thus collect accurate annotation labels is out of the scope of this post.

### 有毒内容的分类

> Categorization of Toxic Content

如何对有毒内容进行分类并非一项简单的任务。哪些内容应被视为有毒以及存在哪些类型的有毒内容可能非常主观。对一个群体来说不具冒犯性的语言，对另一个群体来说可能显得不恰当。

> How to categorize toxic content is not a straightforward task. Which content should be considered toxic and what types of toxic content exist can be very subjective. Language that does not look offensive to one group might seem inappropriate to another.

[Zampieri et al. (2019)](https://arxiv.org/abs/1902.09666) 提出了一种流行的攻击性语言分类方法，这是一个三级分层分类法，同时考虑了攻击的类型和目标。攻击性语言识别数据集（[OLID](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#OLID)）就是基于此分类法收集的。

> One popular categorization of offensive language is proposed by [Zampieri et al. (2019)](https://arxiv.org/abs/1902.09666), a three-level hierarchical taxonomy considering both the type and the target of offense. The Offensive Language Identification Dataset ([OLID](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#OLID)) dataset is collected based on this taxonomy.

![The three-level hierarchical taxonomy for categorizing offensive language, proposed by Zampieri et al. (2019) .](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/offensive-taxonomy.png)

- A 级：“它具有冒犯性吗？”


   - `[OFF]` 冒犯性：不当言论、侮辱或威胁。
   - `[NOT]` 非冒犯性：无冒犯或亵渎。
- B 级：“冒犯性文本是否具有指向性？”


   - `[TIN]` 定向侮辱：针对个人、群体或其他对象的侮辱或威胁。
   - `[UNT]` 无指向性：无指向性的亵渎和咒骂。
- C 级：目标是什么？


   - `[IND]` 冒犯行为针对个人，通常定义为“网络欺凌”。
   - `[GRP]` 冒犯行为针对基于种族、性别、性取向、宗教或其他共同特征的群体，通常定义为“仇恨言论”。
   - `[OTH]` 目标可以属于其他类别，例如组织、事件、问题等。

> • Level A: “Is it offensive?”
>

> ◦ `[OFF]` Offensive: Inappropriate language, insults, or threats.

> ◦ `[NOT]` Not offensive: No offense or profanity.

> • Level B: “Is the offensive text targeted?”
>

> ◦ `[TIN]` Targeted Insult: Targeted insult or threat towards an individual, a group or other.

> ◦ `[UNT]` Untargeted: Non-targeted profanity and swearing.

> • Level C: What is the target?
>

> ◦ `[IND]` The offense targets an individual, often defined as “cyberbullying”.

> ◦ `[GRP]` The offense targets a group of people based on ethnicity, gender, sexual orientation, religion, or other common characteristic, often defined as “hate speech”.

> ◦ `[OTH]` The target can belong to other categories, such as an organization, an event, an issue, etc.

### 数据收集

> Data Collection

准备一个标记为“安全”与“不安全”的样本数据集是训练有毒语言分类器并进一步为模型去毒提供信号的基础。

> Preparing a dataset of samples labelled as “safe” vs “unsafe” is the foundation for training a toxic language classifier and further providing signals for model detoxification.

#### 人工标注

> Human Annotations

[Vidgen & Derczynski (2020)](https://arxiv.org/abs/2004.01670)总结了用于毒性检测的训练数据标注在高层次上可以通过以下方式收集：

> [Vidgen & Derczynski (2020)](https://arxiv.org/abs/2004.01670) summarized that training data annotations for toxicity detection on the high level can be collected by:

1. *专家编码*: 专家拥有足够的知识或培训来高质量地完成标注任务，例如研究偏见的研究人员、受过中等水平培训的学生或NLP从业者。这种方式成本更高，但能产生高质量数据。
2. *众包*: 众包平台将大量非专业标注者与任务配对。这种方式更容易扩展，但需要更多关注质量控制。
3. *专业审核员*: 专业审核员经验丰富，对任务训练有素，但他们的目标可能倾向于优化特定于平台的输出。
4. *合成数据*: 训练数据集也可以由相关内容创作者手动创建，以涵盖广泛的毒性内容类型。

> • *Expert coding*: An expert has enough knowledge or training to complete the annotation tasks with good quality, such as a researcher who studies prejudice, a student with moderate level of training, or a NLP practitioner. It is more expensive but produces high-quality data.
> • *Crowdsourcing*: Crowdsourcing platform pairs a large number of non-expert annotators with tasks. It is easier to scale up but demands more attention on quality control.
> • *Professional moderators*: Professional moderators are experienced, well-trained on the tasks, but their goals are likely to optimize for the output specific to the platform.
> • *Synthetic data*: Training dataset can also be manually created by relevant content creators to cover a broad range of toxic content types.

众包是其中最常见的方法([Davidson et al. 2017](https://arxiv.org/abs/1703.04009), [Zampieri et al. 2019](https://arxiv.org/abs/1902.09666))，并且有几种提高数据质量的良好实践：

> Crowdsourcing is the most common approach among them ([Davidson et al. 2017](https://arxiv.org/abs/1703.04009), [Zampieri et al. 2019](https://arxiv.org/abs/1902.09666)) and there are several good practices to improve the data quality:

1. *测试数据*: 从少数专家那里收集的一小部分标注可以用作测试问题([Zampieri et al. 2019](https://arxiv.org/abs/1902.09666))，以筛选掉众包平台上未能达到特定阈值的人工标注者。
2. *清晰的指导方针*: 详细的说明有助于指导标注者生成一致且连贯的标签。如果没有任何指导方针，标注者会被鼓励应用他们的个人看法，这可能会有问题，因为 (1) 毒性内容的主观解释因人而异，差异很大，并且 (2) 在没有任何指导方针的情况下，标记某些类型的噪音（如讽刺和反语）是很棘手的。
3. *多数投票*: 通常，我们需要每个样本有多个标注者的标签，并采取多数投票。
4. *理解标注者的身份*: 人口统计学背景对标注者对任务的理解有很大影响。我们应该致力于招募多样化且合格的标注者。

> • *Test data*:  A small set of annotations collected from a few experts can be used as test questions ([Zampieri et al. 2019](https://arxiv.org/abs/1902.09666)) to filter out human annotators on the crowdsourcing platform who cannot achieve a certain threshold.
> • *Clear guidelines*: Detailed instructions are useful to guide annotators to produce aligned and consistent labels. Without any guideline, annotators are encouraged to apply their personal perceptions, which could be problematic because (1) subjective interpretation of toxic content varies across individuals greatly and (2) it is tricky to mark certain types of noise like sarcasm and irony without any guideline.
> • *Majority vote*: It is very common that we need labels from multiple annotators per sample and take the majority vote.
> • *Understanding annotators’ identities*: Demographic background has a big impact on the annotator’s understanding of the task. We should aim to recruit diverse and qualified annotators.

#### 半监督数据集

> Semi-supervised Dataset

[Khatri 等人 (2018)](https://arxiv.org/abs/1811.12900) 提出了一种简单的方法，用于引导大量半监督数据集来学习有害内容分类器。他们的方法依赖于一个小型标注数据集和一个大型未标注数据集。

> [Khatri et al. (2018)](https://arxiv.org/abs/1811.12900) proposed a simple approach to bootstrap a large amount of semi-supervised dataset for learning toxic content classifiers. Their approach relies on a small annotated dataset and a large unlabelled dataset.

1. 首先，他们收集了一个包含 800 多个词的黑名单，涵盖了亵渎、仇恨、性内容和侮辱等主题。亵渎词黑名单可能具有高精确度和低召回率，但它可以提供弱监督信号。
2. Subreddit 按黑名单词的百分比排序。然后分别从顶部的 subreddit 中抽取敏感示例，从底部的 subreddit 中抽取非敏感示例。
3. 训练一个弱二元分类器，以从已排序的 subreddit 中进一步选择更多样本，


   - 敏感：包含黑名单词或有害分类器置信度 > 0.8；
   - 非敏感：不包含黑名单词且有害分类器置信度 < 0.3
4. 给定这个大型扩展数据集，训练一个名为“两阶段引导”（**TS bootstrap**）的新分类器。

> • First, they gather a blacklist of 800+ words covering topics of profanity, hate, sexual content and insults. A black list of profanities may have high precision and low recall, but it can provide weak supervised signals.

> • Subreddits are sorted by the percentage of blacklisted words. Then sensitive examples are sampled from the top subreddits and non-sensitive ones from the bottom, respectively.

> • Train a weak binary classifier to further select more samples from the sorted subreddits,
>

> ◦ Sensitive: contain blacklisted words or toxic classifier confidence > 0.8;

> ◦ Non-sensitive: not contain blacklisted words and toxic classifier confidence < 0.3

> • Given this large expanded dataset, train a new classifier named “Two-stage bootstrap” (**TS bootstrap**).

他们的实验表明，TS bootstrap 分类器在 F1 分数、准确率和召回率方面取得了相当好的结果，并且它还可以迁移到域外测试数据。

> Their experiments showed that the TS bootstrap classifier achieved pretty good numbers on F1 score, accuracy and recall and it could also transfer to out-of-domain test data.

![The two-stage bootstrap classifier is trained on a dataset bootstrapped by a weak toxic binary classifier on Reddit data. (Image source: Khatri et al. 2018 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/TS-bootstrap.png)

[SOLID](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#SOLID)（半监督冒犯性语言识别数据集；[Rosenthal 等人 2020](https://arxiv.org/abs/2004.14454)）包含 900 多万条推文，这些推文使用与 [OLID](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#OLID) 相同的分类系统进行标注。SOLID 将 OLID 视为种子，并通过一种名为 **民主协同训练** 的半监督技术对其进行扩展。民主协同训练（[Zhou & Goldman, 2004](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.76.3152&rep=rep1&type=pdf)）通过在小型监督数据集上训练的一组多样化模型提供的噪声标签创建大型数据集。SOLID 的构建方式如下：

> [SOLID](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#SOLID) (Semi-Supervised Offensive Language Identification Dataset; [Rosenthal et al. 2020](https://arxiv.org/abs/2004.14454)) contains 9+ M tweets annotated with the same taxonomy system as for [OLID](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#OLID). SOLID treats OLID as a seed and extends it via a semi-supervised technique called **democratic co-training**. Democratic co-training ([Zhou & Goldman, 2004](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.76.3152&rep=rep1&type=pdf)) creates a large dataset from noisy labels provided by a collection of diverse models trained on a small supervised dataset. SOLID is constructed by:

1. 首先，在标注数据集 OLID 上训练一组多样化的监督模型。该论文实验了 PMI（基于 n-gram 的相似性）、FastText（类似于 BoW 模型的浅层神经网络模型）、LSTM 和 BERT。
2. 对于未标注数据集中的每个样本，每个模型都会预测目标类别的置信度分数。这些分数通过取 `avg()` 或 `min()` 进行聚合。高置信度的样本被添加到数据集中。

> • First, train a diverse set of supervised models on the labeled dataset OLID. The paper experimented with PMI (n-gram-based similarity), FastText (shallow neural model similar to BoW model), LSTM and BERT.
> • For each sample in the unannotated dataset, each model predicts a confidence score for the target class. The scores are aggregated by taking `avg()` or `min()`. Samples with high confidence are added into the dataset.

当监督数据集对于简单任务足够大时，BERT 模型的性能不会提高，但如果原始监督数据集对于该任务来说太小，则可以从大型半监督数据集中受益。

> BERT model performance does not improve when the supervised dataset is large enough for a simple task, but can benefit from a big semi-supervised dataset if the original supervised dataset is too small for the task.

### 毒性检测

> Toxicity Detection

给定一个有监督数据集，我们可以从头开始训练一个文本分类器，或者微调一个预训练语言模型来执行分类任务。但是，如果训练样本不够好或不够充分怎么办？如果我们无法访问这样的有监督数据集怎么办？

> Given a supervised dataset, we can train a text classifier from scratch or fine-tune a pretrained language model to perform the classification task. But what if training samples are not good or sufficient enough? What if we don’t have access to such a supervised dataset?

#### 对抗性攻击

> Adversarial Attacks

为了创建一个对对抗性攻击具有鲁棒性的毒性检测模型，[Dinan 等人 (2019)](https://arxiv.org/abs/1908.06083) 提出了一种迭代的“**构建、破坏、修复**”策略，以在有人参与的情况下提高对话系统的安全性。

> To create a toxicity detection model that is robust to adversarial attacks, [Dinan et al. (2019)](https://arxiv.org/abs/1908.06083) proposed an iterative “**build it, break it, fix it**” strategy to improve the dialogue system safety with humans in the loop.

1. *构建*：训练一个 BERT 模型，用于在 [Jigsaw 数据集](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#jigsaw)上对有毒评论进行分类。
2. *破坏*：众包工作者被要求编写被模型错误标记为“安全”的有毒消息。
3. *修复*：模型在原始数据集和新收集的对抗性样本的组合上重新训练。
4. *重复*：重新部署增强鲁棒性的模型，并从步骤 1 开始新一轮。

> • *Build it*: A BERT model is trained to classify toxic comments on the [Jigsaw dataset](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#jigsaw).
> • *Break it*: Crowdsourced workers are asked to write toxic messages that are mistakenly labelled as “safe” by the model.
> • *Fix it*: The model is re-trained on the combination of the original dataset and newly collected adversarial samples.
> • *Repeat*: Redeploy the robustified model and repeat a new round from step 1.

![The illustration of iteratively improving a toxic content detection model via the "build it, break it, fix it" process. (Image source: Dinan et al. 2019 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/build-break-fix.png)

他们实验中的一个基线是将“破坏”步骤中的对抗性收集替换为标准收集，其中工人被要求直接提交“冒犯性”消息。与标准收集相比，对抗性收集具有更少的显式脏话和更多的否定词来欺骗模型。在后续轮次中，任务变得更具挑战性。

> One baseline in their experiments is to replace the adversarial collection in the “break it” step with the standard collection where workers are asked to submit “offensive” messages directly . Compared to the standard collection, the adversarial collection has less explicit profanity and more negations to trick the model. The tasks become more challenging in the later rounds.

对抗性模型比在标准收集上训练的基线模型对对抗性攻击更具鲁棒性。第三轮对抗性模型在标准任务上的表现比标准模型差，这可能是由于过拟合。我很好奇如果模型同时在对抗性收集和标准收集上进行训练，其性能会如何，但我没有在论文中找到相关信息。

> Adversarial models are more robust against adversarial attacks than baseline models trained on the standard collection.  The third round adversarial model has worse performance on the standard task than the standard model, likely due to overfitting. I’m curious about how the model performance would be like if it is trained on both adversarial and standard collection, but I didn’t find it in the paper.

![The comparison of performance on standard and adversarial tasks of models trained on standard ($S\_i$) and adversarial data collection ($A\_i$). The subscript $i$ indicates the number of training rounds. (Image source: Dinan et al. 2019 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/build-break-fix-it-results.png)

另一种对抗性攻击是通过替换或打乱部分字符来欺骗检测模型，使其错误地将有毒句子分类为安全。[Kurita 等人 (2019)](https://arxiv.org/abs/1912.06872) 开发了一种生成此类模型无关对抗性攻击的方法，其中包含几种字符级扰动：

> Another type of adversarial attack is to trick the detection model to mistakenly classify a toxic sentence as safe by replacing or scrambling a subset of characters. [Kurita et al. (2019)](https://arxiv.org/abs/1912.06872) developed a method of generating such model-agnostic adversarial attacks, incorporating several types of character-level perturbations:

1. *字符打乱*：随机置换字符位置。
2. *同形异义字替换*：用外观相似的国际字母替换一个或多个字母。
3. *基于词典的近邻替换*：根据 Levenshtein 距离查找最接近但不同的标记。
4. *干扰词注入*：通过重复随机选择的非有毒标记序列来注入干扰词标记。

> • *Character scrambling*: randomly permute character positions.
> • *Homoglyph substitution*: replace one or multiple letters with similar looking international letters.
> • *Dictionary-based near-neighbor replacement*: find closest but distinct token in terms of Levenshtein distance.
> • *Distractor injection*: inject distractor tokens by repeating random selected sequences of non-toxic tokens.

结合了标记混淆和干扰词标记的对抗性噪声导致毒性分类器的性能显著下降。字符级扰动比干扰词更能降低性能。

> Adversarial noise combining token obfuscation and distractor tokens leads to substantial performance degradation of a toxic classifier. Character-level perturbation degrades performance more than distractors.

该论文提出了两种解决对抗性攻击的方法：

> The paper proposed two ways to resolve adversarial attacks:

- *对抗性训练* 指的是在带有噪声的数据集上训练模型。然而，你需要提前了解传入攻击的细节。并且无法保证带有任意噪声的训练样本能够泛化到测试集。
- *CDAE（上下文去噪自编码器）* 使用字符级和上下文信息来对混淆的标记进行去噪。CDAE 接收一个噪声样本来预测去噪后的版本。不过，你仍然需要知道可以应用哪些类型的字符级扰动来创建噪声样本。CDAE 的性能与 BERT 相当，但没有显著更好。

> • *Adversarial training* refers to training the model on a dataset with noise. However, you need to know the details of the incoming attacks in advance. And there is no guarantee that training samples with arbitrary noise would generalize to the test set.
> • *CDAE (contextual denoising autoencoder)* uses character-level and contextual information to denoise obfuscated tokens. CDAE takes a noise sample to predict the denoised version. Still, you need to know what types of character-level perturbation can be applied to create noise samples. CDAE performs comparable to BERT, but not substantially better.

#### Perspective API

> Perspective API

**Perspective API** ([www.perspectiveapi.com](https://www.perspectiveapi.com/)) 是最广泛使用的商业有毒内容检测 API。Perspective 训练机器学习模型，为几种不同的[属性](https://support.perspectiveapi.com/s/about-the-api-attributes-and-languages)提供分数：毒性、严重毒性、侮辱、亵渎、身份攻击、威胁和露骨性内容。每个分数都是一个介于 [0, 1] 之间的数字，表示消息包含给定属性的可能性（即二元分类器的置信度），它不表示属性的严重程度。

> **perspective API** ([www.perspectiveapi.com](https://www.perspectiveapi.com/)) is the most widely used commercial API for toxic content detection. Perspective trains machine learning models to provide scores for several different [attributes](https://support.perspectiveapi.com/s/about-the-api-attributes-and-languages): toxicity, severe toxicity, insult, profanity, identity attack, threat, and sexually explicit. Each score is a number between [0, 1], indicating how likely the message contains a given attribute (i.e. confidence of a binary classifier) and it does not signify the severity of the attribute.

![The overview of Perspective API scores. (Image source: About Perspective API )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/about-perspective-api.png)

[Gehman 等人 (2020)](https://arxiv.org/abs/2009.11462) 测量了从几个预训练语言模型中采样的无提示生成内容的 Perspective API 毒性分数。“无提示”意味着生成仅以句子起始标记为条件，不注入任何额外上下文。值得注意的是，所有测试模型在 100 次生成后都达到了预期的最大毒性 > 0.5。他们还指出，大型语言模型的训练数据集包含不可忽略数量的有毒内容。

> [Gehman et al. (2020)](https://arxiv.org/abs/2009.11462) measured the Perspective API toxicity scores of unprompted generations sampled from several pretrained language models. “Unprompted” means that the generation is only conditioned on the start-of-sentence tokens, without injecting any additional context. Noticeably, all the tested models get to the expected maximum toxicity > 0.5 after 100 generations. They also pointed out that training datasets for large LMs contain an non-negligible amount of toxic content.

![Perspective API toxicity scores of unprompted generations. Each model generates a pool of 10k samples and the expected maximum toxicity score is estimated via bootstrapping. (Image source: Gehman et al. 2020 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/unprompted-toxicity.png)

他们收集了 [RealToxicityPrompt 数据集](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#RealToxicityPrompt)，用于研究条件语言模型生成中的毒性。它包含 10 万个自然发生的提示，以及来自 Perspective API 的相关毒性分数。一些不包含任何有毒语言的提示仍然可以触发非常冒犯性的补全。

> They collected the [RealToxicityPrompt dataset](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#RealToxicityPrompt) for studying toxicity in conditional language model generation. It contains 100k naturally occurring prompts with associated toxicity scores from Perspective API. Some prompts that do not contain any toxic language still can trigger very offensive completion.

尽管 Perspective API 广受欢迎，但它包含已知的偏见，正如 [Gehman 等人 (2020)](https://arxiv.org/abs/2009.11462) 所总结的：

> Despite of its popularity, Perspective API contains known biases, as summarized by [Gehman et al. (2020)](https://arxiv.org/abs/2009.11462):

> …对少数群体表现出偏见，并且在标注中存在较低的一致性，部分原因是标注者的身份影响了他们对仇恨言论的感知以及标注任务设置的差异。

> … exhibit biases against minorities and suffer from low agreement in annotations, partially due to annotator identity influencing their perception of hate speech and differences in annotation task setup.

> 值得注意的是，最近的研究发现，系统高估了包含少数群体身份提及（例如，“我是一个男同性恋”）或由少数族裔撰写的文本（例如，非裔美国英语文本）中的毒性普遍性。这部分是由于检测器过度依赖毒性的词汇线索（包括脏话、侮辱性词语和其他“坏”词）。

> Notably, recent work has found that systems are overestimating the prevalence of toxicity in text that contains a minority identity mention (e.g., “I’m a gay man”) or text by racial minorities (e.g., text in African American English). This is partially due to detectors’ over-reliance on lexical cues of toxicity (including swearwords, slurs, and other “bad” words).

#### 基于提示的检测

> Prompt-based Detection

**自诊断** ([Schick, et al. 2021](https://arxiv.org/abs/2103.00453)) 是一种利用预训练语言模型的能力来检测其自身输出中不合社会期望属性的过程。诊断依赖于预定义的提示模板，其中属性以短文本描述，并测量模型输出“是”与“否”的归一化概率。请注意，自诊断不需要访问标记数据集进行训练。

> **Self-diagnosis** ([Schick, et al. 2021](https://arxiv.org/abs/2103.00453)) is a process of exploiting the capacity of a pretrained language model to detect socially undesired attributes in its own outputs. The diagnosis depends on a predefined prompt template where the attributes are described in short text and measures the normalized probability of the model outputting “yes” versus “no”. Note that self-diagnosis does not need to access a labelled dataset for training.

```
# Self-diagnosis template
"{sample text}"
Question: Does the above text contain {undesired attribute}?
Answer: {yes/no}
```

他们在实验中使用了 RealToxicityPrompts 数据集和 Perspective API 进行评估。自诊断性能与模型大小呈正相关。

> They use RealToxicityPrompts dataset and Perspective API for evaluation in the experiments. The self-diagnosis performance is positively correlated with the model size.

![Self-diagnosis abilities for identifying undesired attributes. The ground truth is provided by Perspective API. (Image source: Schick, et al. 2021 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/self-diagnosis-toxicity-score.png)

### 去毒化

> Detoxification

#### 黑名单

> Blacklisting

**脏词过滤** 是一种相当直观有效的方法，可以避免语言模型生成中出现明确的亵渎性[词语](https://github.com/%20LDNOOBW/List-of-Dirty-Naughty-Obscene-%20and-Otherwise-Bad-Words)。在解码时，我们可以手动降低被阻止词语的概率以避免对其进行采样。然而，这并不完美，因为仍然可能存在由安全词元组成的不安全内容。

> **Bad word filtering** is a pretty intuitive and effective way to avoid explicit profane [words](https://github.com/%20LDNOOBW/List-of-Dirty-Naughty-Obscene-%20and-Otherwise-Bad-Words) in the language model generation. At decoding time, we can manually reduce the probabilities of blocked words to avoid sampling them. However, it is not perfect, as it is still possible to have unsafe content composed of safe tokens.

**词汇转移** ([Gehman et al. 2020](https://arxiv.org/abs/2009.11462)) 为预训练模型词汇表中的每个词元学习毒性与非毒性的二维表示。然后，编码非毒性的表示用于在解码时提高非毒性词元的可能性。

> **Vocabulary shifting** ([Gehman et al. 2020](https://arxiv.org/abs/2009.11462)) learns a 2-dimensional representation of toxicity versus non-toxicity for every token in the vocabulary of the pretrained model. Then the representation that encodes the non-toxicity is used to boost the likelihood of non-toxic tokens at decoding time.

#### 基于提示的去毒

> Prompt-based Detox

**自去偏** ([Schick et al. 2021](https://arxiv.org/abs/2103.00453)) 遵循与[自诊断](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#prompt-based-detection)相似的理念。它是一个利用预训练语言模型的内部知识来降低模型生成中不合期望属性概率的过程。

> **Self-debiasing** ([Schick et al. 2021](https://arxiv.org/abs/2103.00453)) follows the similar idea as in [self-diagnosis](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#prompt-based-detection). It is a process for using the internal knowledge of a pretrained language model to reduce the probability of undesired attributes in the model generation.

```
# Self-debiasing template, denoted as sdb(.)
The following text contains {undesired attribute s}:
{sample text x}
```

给定输入提示 $\mathbf{x}$、不合期望属性的文本描述 $s$ 和语言模型 $M$，自去偏计算在没有和有自去偏模板 $\text{sdb}(.)$ 的情况下，下一个词的概率之间的差异：

> Given an input prompt $\mathbf{x}$, a textual description of undesired attributes $s$, and the language model $M$, self-debiasing computes the difference between the probability of next words without and with the self-debiasing template $\text{sdb}(.)$:

$$
\Delta(w, \mathbf{x}, s) = p_M(w\vert\mathbf{x}) - p_M(w\vert\text{sdb}(\mathbf{x}, s))
$$

因为$\text{sdb}(.)$预计会提高不期望词语的概率，所以对于不期望词语，$\Delta(w, \mathbf{x}, s)$应该为负值。

> Because $\text{sdb}(.)$ is expected to boost the probabilities of undesired words, $\Delta(w, \mathbf{x}, s)$ should be negative for undesirable words.

在自去偏解码中，概率差$\alpha(\Delta(w, \mathbf{x}, s)): \mathbb{R}\to[0,1]$的缩放函数用于改变真实的采样分布，

> In self-diasing decoding, a scaling function of the probability difference $\alpha(\Delta(w, \mathbf{x}, s)): \mathbb{R}\to[0,1]$ is used to alter the true sampling distribution,

$$
\tilde{p}_M(w\vert\mathbf{x}) \propto \alpha(\Delta(w, \mathbf{x}, s)) p_M(w\vert\mathbf{x})
$$

在该论文中，他们使用了一种软变体，其中具有负$\Delta$的词语的概率会根据$\Delta(w, \mathbf{x}, s)$的大小而降低：

> In the paper, they used a soft variant where the probabilities of the words with negative $\Delta$ are reduced w.r.t. the magnitude of $\Delta(w, \mathbf{x}, s)$:

$$
\alpha(x)=\begin{cases} 1 & \text{ if } x\geq 0 \\ e^{\lambda\cdot x} & \text{ otherwise} \end{cases}
$$

![Self-diasing decoding can reduce the probabilities of undesirable attributes. The scores are provided by Perspective API. (Image source: Schick et al. 2021 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/self-debiasing-decoding.png)

自去偏解毒存在几个主要局限性：

> There are a couple of major limitations in self-debiasing detoxification:

1. 评估完全依赖于Perspective API，因此它无法捕获Perspective API[未涵盖](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#perspective-api-biases)的偏见和毒性属性，例如性别偏见。使用人工评估是另一种选择，但规模有限。
2. 自去偏有时过于激进，会过滤掉无害词语，并且它无法保持与原始模型相同的困惑度水平。
3. 该方法受限于模型的内部能力。例如，如果模型不知道某些偏见，它将无法纠正它们。

> • The evaluation solely relies on Perspective API, so it cannot capture bias & toxicity attributes that are [not covered](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#perspective-api-biases) by Perspective API, such as gender biases. Using human evaluation is another alternative but the scale is limited.
> • Self-debiasing sometimes acts too aggressively and filters out harmless words and it does not maintain the same level of perplexity as the original model.
> • The approach is constrained by the internal capacity of the model. For example, if the model is not aware of certain biases, it would not be able to correct them.

#### 文本风格迁移

> Text Style Transfer

**无监督风格迁移**可用于将冒犯性句子翻译成无害的句子（[Santos et al. 2018](https://arxiv.org/abs/1805.07685)）。该方法应适用于非并行数据集，这意味着我们只能访问两个独立的冒犯性和非冒犯性样本数据集，而不是配对版本。为了在将文本迁移到另一种风格时保留内容，采用了循环一致性损失（[Zhu et al. 2017](https://arxiv.org/abs/1703.10593)）。

> **Unsupervised style transfer** can be used to translate offensive sentences into innocuous ones ([Santos et al. 2018](https://arxiv.org/abs/1805.07685)). The approach should work for non-parallel datasets, meaning that we only have access to two separate datasets of offensive and non-offensive samples, but not paired versions. To preserve the content when transferring the text into another style, a cycle consistency loss ([Zhu et al. 2017](https://arxiv.org/abs/1703.10593)) is adopted.

![The training process of a neural text style transfer algorithm using non-parallel data. (Image source: Santos et al. 2018 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/offensive-text-style-transfer.png)

设$s_i$为目标风格（$i=0$表示冒犯性，$i=1$表示非冒犯性），$\mathbf{x}^i_k$是$k$风格的第$s_i$个样本，$k = 1, \dots, n$。编码器$E$和解码器$G$接收一个样本（或隐藏状态）以及一个风格标签。分类器$C$根据输入样本预测风格标签的概率分布。

> Let $s_i$ be the desired style ($i=0$ for offensive and $i=1$ for non-offensive), and $\mathbf{x}^i_k$ be the $k$ -th sample of style $s_i$, $k = 1, \dots, n$. Both the encoder $E$ and decoder $G$ take a sample (or hidden state) along with a style label. The classifier $C$ predicts a probability distribution over the style labels given an input sample.

参照图 9 中的插图：

> Following the illustration in Fig. 9:

• 前向传输的顶部分支是自动编码器：​$E(\mathbf{x}^i_k, s_i) \to H^i_k \to G(H^i_k, s_i) \to \hat{\mathbf{x}}^{i\to i}_k$。计算两个损失：



   - 重建损失衡量解码器能将样本重建回来的程度：

英文原文：

• The top branch of forward transfer is auto encoder: ​$E(\mathbf{x}^i_k, s_i) \to H^i_k \to G(H^i_k, s_i) \to \hat{\mathbf{x}}^{i\to i}_k$. Two losses are computed:



   - Reconstruction loss measures how well the decoder can reconstruct the sample back:

$$
\mathcal{L}_\text{self} = \mathbb{E}_{\mathbf{x}^i_k \sim \mathcal{X}} [-\log p_G(\mathbf{x}_k^i \mid E(\mathbf{x}^i_k, s_i), s_i)]
$$

• 前向传输的底部分支：$E(\mathbf{x}^i_k, s_i) \to H^i_k \to G(H^i_k, s_j) \to \hat{\mathbf{x}}^{i\to j}_k$



   - 分类损失衡量风格迁移的有效性：

英文原文：

• The bottom branch of forward transfer: $E(\mathbf{x}^i_k, s_i) \to H^i_k \to G(H^i_k, s_j) \to \hat{\mathbf{x}}^{i\to j}_k$



   - Classification loss measures the effectiveness of style transfer:

$$
\mathcal{L}_\text{style_fwd} = \mathbb{E}_{\hat{\mathbf{x}}^{i\to j}_k \sim \hat{\mathcal{X}}} [-\log p_C(s_j \mid \hat{\mathbf{x}}^{i\to j}_k)]
$$

• 反向传输使用循环一致性损失：$E(\hat{\mathbf{x}}^{i\to j}_k, s_j) \to H^{i\to j}_k \to G(H^{i\to j}_k, s_i) \to \hat{\mathbf{x}}^{i\to j \to i}_k$



   - 循环一致性损失控制迁移后的样本能多好地转换回原始形式，以鼓励内容保留：

英文原文：

• The back transfer uses cycle consistency loss: $E(\hat{\mathbf{x}}^{i\to j}_k, s_j) \to H^{i\to j}_k \to G(H^{i\to j}_k, s_i) \to \hat{\mathbf{x}}^{i\to j \to i}_k$



   - The cycle consistency loss controls how well the transferred sample can be converted back to the original form to encourage content preservation:

$$
\mathcal{L}_\text{cycle} = \mathbb{E}_{\mathbf{x}^i_k \sim \mathcal{X}} [-\log p_G(\mathbf{x}_k^i \mid E(\hat{\mathbf{x}}^{i \to j}_k, s_j), s_i)]
$$

```
- The classification loss ensures that the back-transferred sample has the correct label:
```

$$
\mathcal{L}_\text{style_back} = \mathbb{E}_{\hat{\mathbf{x}}^{i\to j}_k \sim \hat{\mathcal{X}}} [-\log p_C(s_i \mid G(E(\hat{\mathbf{x}}^{i\to j}_k, s_j), s_i))]
$$

- 还有一个额外的监督分类损失，用于训练一个准确的分类器：

> • There is an additional supervised classification loss for training an accurate classifier:

$$
\mathcal{L}_\text{class} = \mathbb{E}_{\hat{\mathbf{x}}^{i\to j}_k \sim \hat{\mathcal{X}}} [-\log p_C(s_i \mid \hat{\mathbf{x}}^i_k)]
$$

最终的训练目标如下，编码器、解码器和分类器是联合训练的：

> The final training objective is as follows and the encoder, decoder and classifier are jointly trained:

$$
\mathcal{L}(\theta_E, \theta_G, \theta_C) = \min_{E, G, C} \mathcal{L}_\text{self} + \mathcal{L}_\text{style_fwd} + \mathcal{L}_\text{cycle} + \mathcal{L}_\text{style_back}+ \mathcal{L}_\text{class}
$$

**Style Transformer** ([Dai et al. 2019](https://arxiv.org/abs/1905.05621)) 也旨在学习无监督文本风格迁移。与[Santos et al. 2018](https://arxiv.org/abs/1805.07685)中的编码器-解码器模型不同，它学习一个基于Transformer的风格迁移函数$f_\theta(\mathbf{x}, s)$，用于给定的输入样本$\mathbf{x}$和期望的风格控制变量`s`。

英文原文：Style Transformer ([Dai et al. 2019](https://arxiv.org/abs/1905.05621)) also aims to learn unsupervised text style transfer. Different from the encoder-decoder model in [Santos et al. 2018](https://arxiv.org/abs/1805.07685), it learns a Transformer-based style transfer function 

$f_\theta(\mathbf{x}, s)$ for a given input sample 

$\mathbf{x}$ and a desired style control variable `s`.

![The comparison of style transformer and previous models that depend on disentangled latent representation. (Image source: Dai et al. 2019 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/style-transformer.png)

在无法访问并行语料库的情况下，风格Transformer采用判别器从非并行数据集中创建监督信号。

> Without access to the parallel corpus, the style transformer adopts a discriminator to create supervision from non-parallel dataset.

设$s$和$\hat{s}$是两个互斥的风格变量，$\mathbf{x}$是风格$s$的一个样本，风格Transformer计算以下几种损失：

> Let $s$ and $\hat{s}$ be two mutually exclusive style variables and $\mathbf{x}$ is a sample of style $s$, style transformer computes several losses:

• 自重建损失：$\mathcal{L}_\text{self} = - p_\theta (\mathbf{x} \vert \mathbf{x}, s)$

• 循环一致性损失：$\mathcal{L}_\text{cycle} = - p_\theta (\mathbf{x} \vert f_\theta(\mathbf{x}, \hat{s}), s)$

• 风格控制损失：这是必要的，因为否则模型只会学习复制输入。

英文原文：

• Self reconstruction loss: $\mathcal{L}_\text{self} = - p_\theta (\mathbf{x} \vert \mathbf{x}, s)$

• Cycle-consistency loss: $\mathcal{L}_\text{cycle} = - p_\theta (\mathbf{x} \vert f_\theta(\mathbf{x}, \hat{s}), s)$

• Style controlling loss: This is necessary because otherwise the model would simply learn to copy the input over.

$$
\mathcal{L}_\text{style} = - p_\phi(\text{class} = 1 \vert f_\theta(\mathbf{x}, \hat{s}), \hat{s})
$$

，其中判别器是一个简单的二元分类器，经过训练以优化正确风格的负对数似然。判别器通过标记

> , where the discriminator is a simple binary classifier trained to optimize the negative log-likelihood of the correct style. The discriminator is trained by labelling

• $\{(\mathbf{x}, s), (f_\theta(\mathbf{x}, s), s), (f_\theta(\mathbf{x}, \hat{s}), \hat{s})\}$ 作为正类 1

• $\{(\mathbf{x}, \hat{s}), (f_\theta(\mathbf{x}, s), \hat{s}), (f_\theta(\mathbf{x}, \hat{s}), s)\}$ 作为负类0。

英文原文：

• $\{(\mathbf{x}, s), (f_\theta(\mathbf{x}, s), s), (f_\theta(\mathbf{x}, \hat{s}), \hat{s})\}$ as positive class 1

• $\{(\mathbf{x}, \hat{s}), (f_\theta(\mathbf{x}, s), \hat{s}), (f_\theta(\mathbf{x}, \hat{s}), s)\}$ as negative class 0.

![The training process of Style Transformer. (Image source: Dai et al. 2019 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/style-transformer-training.png)

在研究问题“我们能否使用仅标注了毒性内容的语料库，对预训练语言模型进行微调，以建议粗鲁评论的文明改写？”的驱动下，[Laugier et al. (2021)](https://arxiv.org/abs/2102.05456) 使用去噪和循环自编码器损失，对预训练的文本到文本转换器进行了微调。

> Driven by the research question “Can we fine-tune a pre-trained language model to suggest civil rephrasings of rude comments using a dataset solely annotated in toxicity?”, [Laugier et al. (2021)](https://arxiv.org/abs/2102.05456) fine-tuned a pretrained text-to-text transformer with a denoising and cyclic auto-encoder loss.

设 $s$ 为 $\mathbf{x}$ 的属性（例如“文明”），而 $\bar{s}$ 为另一个相反的属性（例如“有毒”）。这两个属性是互斥的。目标是学习一个映射函数 $f_\theta$，使其将 $x$ 翻译成一个新的流畅序列 $y$，具有目标属性 $a$，同时保留 $x$ 的内容。

> Let $s$ be the attribute of $\mathbf{x}$ (e.g. “civil”) and $\bar{s}$ be the other opposite attribute (e.g. “toxic”). These two attributes are mutually exclusive. The goal is to learn a mapping function $f_\theta$ such that it translates $x$ to a new fluent sequence $y$ with target attribute $a$ while preserving $x$’s content.

编码器-解码器模型通过以下损失进行训练：

> The encoder-decoder model is trained with the loss:

$$
\mathcal{L} = \lambda_\text{DAE} \mathcal{L}_\text{DAE} + \lambda_\text{cycle} \mathcal{L}_\text{cycle}
$$

• 去噪自编码器损失是用于去噪自编码器的损失，其中 $\eta$ 是一个与 BERT 训练中相同的 [掩码](https://lilianweng.github.io/posts/2019-01-31-lm/#pre-training-tasks) 函数：

英文原文：

• The denoising auto-encoder loss is the loss for denoising auto-encoders, where $\eta$ is a [masking](https://lilianweng.github.io/posts/2019-01-31-lm/#pre-training-tasks) function same as in BERT training:

$$
\mathcal{L}_\text{DAE} = \mathbb{E}_{\mathbf{x} \sim \mathcal{X}} [−\log p_\theta(\mathbf{x} \mid \eta(\mathbf{x}), s)]
$$

• 循环一致性损失（[Zhu et al. 2017](https://arxiv.org/abs/1703.10593)）具有 $\tilde{\theta}$ 以产生一个不可微分的伪预测 $\hat{\mathbf{y}}$，并且它不进行梯度反向传播。

英文原文：

• The cycle consistency loss ([Zhu et al. 2017](https://arxiv.org/abs/1703.10593)) has $\tilde{\theta}$ to produce a non-differentiable pseudo-prediction $\hat{\mathbf{y}}$ and it does not take gradient backpropagation.

$$
\mathcal{L}_\text{cycle} = \mathbb{E}_{\mathbf{x} \sim \mathcal{X}} [−\log p_\theta(\mathbf{x} \mid f_{\tilde{\theta}}(\mathbf{x}, \bar{s}), s)]
$$

他们使用上述损失对 T5 模型进行微调，得到了一个名为 **CAE-T5** 的模型。条件化是通过在序列开头添加控制代码（“civil”或“toxic”）来实现的，类似于 CTRL。

> They used the above loss to fine-tune a T5 model, resulting in a model named **CAE-T5**. The conditioning is implemented like CTRL via control code (“civil” or “toxic”) prepended to the start of a sequence.

文本风格迁移结果的自动评估依赖于三个指标：

> Automatic evaluation of the text style transferred results relies on three metrics:

1. *准确性*：分类准确性衡量风格迁移的成功程度。
2. *流畅性*：流畅性通常通过在非有害样本上单独训练的另一个语言模型计算的困惑度来衡量。
3. *内容保留*：它是指迁移句和原始句之间的内容相似度，通过BLEU或基于嵌入的内容相似度来衡量。

> • *Accuracy*: Classification accuracy measures how successful the style transfer is.
> • *Fluency*: Fluency is commonly measured by perplexity by another separately trained LM on non-toxic samples.
> • *Content preservation*: It is the content similarity between transferred and original sentences, measured by BLEU or embedding based content similarity.

人工评估也是必要的，但成本更高。

> Human evaluation is also necessary but more costly.

与基线（[Shen et al. 2017](https://arxiv.org/abs/1705.09655)）相比，[Santos et al. 2018](https://arxiv.org/abs/1805.07685)的风格迁移方法在分类准确率和内容保留方面表现更好，但在困惑度方面表现更差。与包括Style Transformer在内的一系列基线相比，CAE-T5的分类准确率更差，内容保留具有竞争力，困惑度更好。

> Compared to the baseline ([Shen et al. 2017](https://arxiv.org/abs/1705.09655)), the style transfer method by [Santos et al. 2018](https://arxiv.org/abs/1805.07685) achieves better classification accuracy, better content preservation, but worse perplexity. CAE-T5 has worse classification accuracy, competitive content preservation, and better perplexity compared to a set of baselines including Style Transformer.

#### 可控生成

> Controllable Generation

我们可以尝试通过*可控文本生成*来避免有害输出。有几种流行的方法可以将预训练语言模型引导至所需的风格、主题或安全标准：

> We can try to avoid toxic outputs via *controllable text generation*. There are several popular approaches for steering a pretrained language model toward desired styles, topics or safety criteria:

1. 应用引导解码策略并在测试时选择所需的输出。
2. 通过良好的提示设计来优化最期望的结果。
3. 微调基础模型或可控层以进行条件内容生成。

> • Apply guided decoding strategies and select desired outputs at test time.
> • Optimize for the most desired outcomes via good prompt design.
> • Fine-tune the base model or steerable layers to do conditioned content generation.

在我的[上一篇博文](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/)中阅读更多关于可控神经文本生成的内容，其中介绍了诸如[AutoPrompt](https://arxiv.org/abs/2010.15980)、[CTRL](https://arxiv.org/abs/1909.05858)、[PPLM](https://arxiv.org/abs/1912.02164)、[GeDi](https://arxiv.org/abs/2009.06367)等多种方法。

> Read more in my [last post](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/) on controllable neural text generation, introducing methods like [AutoPrompt](https://arxiv.org/abs/2010.15980), [CTRL](https://arxiv.org/abs/1909.05858), [PPLM](https://arxiv.org/abs/1912.02164), [GeDi](https://arxiv.org/abs/2009.06367) and many more.

[Gehman et al. (2020)](https://arxiv.org/abs/2009.11462)实验了基于数据（监督微调、CTRL训练）和基于解码（词汇转移、词语过滤、PPLM）的方法来对语言模型进行去毒化。他们发现，毒性控制令牌（CTRL）和脏话过滤器*不太成功*，相比之下，在非毒性语料库上进行微调和PPLM等计算或数据密集型方法更有效。

> [Gehman et al. (2020)](https://arxiv.org/abs/2009.11462) experimented with both data-based (supervised fine-tuning, CTRL training) and decoding-based (vocabulary shifting, blocked word filtering, PPLM) methods for language model detoxification. They found that toxicity control tokens (CTRL) and swear word filters are *less successful* than more computationally or data-intensive methods like fine-tuning on non-toxic corpora and PPLM.

![Table list expected maximum toxicity score over 25 generations (left) and the empirical probability of generating toxic text over 25 generations (right) for several detoxification methods. Scores are provided by Perspective API. (Image source: Gehman et al., 2020 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/RealToxicityPrompts-experiments.png)

#### 系统级安全解决方案

> System-level Safety Solution

[Xu et al. (2020)](https://arxiv.org/abs/2010.07079)提出了一个构建安全聊天机器人的全面系统级设计。

> [Xu et al. (2020)](https://arxiv.org/abs/2010.07079) presented a thorough system-level design for building safe chatbots.

![Illustration of a safe chat bot system. (Image source: Xu et al. 2020 )](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/safe-chatbot-system.png)

他们在使机器人更安全的方案中考虑了四种通用策略：

> They consider four general strategies in the recipes for making the bot safer:

• *检测不安全内容*：采用分类器来检测输入和输出端的不安全语言，作为语言模型之上的额外安全层。



   - 该分类器在一个增强版的[Jigsaw毒性](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#jigsaw)评论数据集（安全与不安全二元标签）上进行训练，并扩展了[对抗性人工攻击](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#adversarial-attacks)（[Dinan et al. 2019](https://arxiv.org/abs/1908.06083)）和[半监督](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#semi-supervised-dataset)（[Khatri et al. 2018](https://arxiv.org/abs/1811.12900)）数据。

   - 安全分类器可用于用户输入和模型输出。如果它检测到不安全内容，系统会配置为返回一个预设的、罐头式响应（例如“抱歉，我不确定该说什么。”），或者决定改变话题。值得注意的是，这种方法依赖于高质量的分类器。如果误报过多，对话体验将受到严重干扰。

   - 机器人对抗性对话（BAD）安全：其思想是收集人类对抗性探测系统以使其犯错的数据，然后将这些数据用于进一步训练。在标注过程中，人工标注员可以根据认为机器人响应不安全的人口百分比，给机器人的响应打上不安全-安全等级。这种探测数据收集用于训练一个多轮安全分类器，预测在给定对话上下文的情况下，响应是否具有冒犯性。

• *安全生成*：训练一个不太可能输出不安全响应的模型。



   - 一个预定义的不安全词语/n-gram列表可以在解码时被[阻止](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#blacklisting)。

   - 预训练数据通过上述安全分类器进行过滤，或根据已知作者进行过滤。

   - 仅使用安全数据集进行预训练的问题在于，如果模型在训练期间从未见过有害语言，它将不知道如何在测试时做出响应（OOD；例如，可能只是复制冒犯性内容）。他们反而准备了一组训练样本，其中最后一个话语被标记为“不安全”，然后在该不安全攻击之后附上一个安全响应。然后模型在“内置”安全数据上进行微调。

   - 使用安全分类器通过分配“安全”与“不安全”标签来执行[CTRL](https://arxiv.org/abs/1909.05858)风格训练。

• *避免敏感话题*：



   - 为了避免敏感话题（政治、宗教、吸毒、医疗建议、NSFW以及人际关系/约会），他们训练了一个多类别分类器，利用众包的subreddit列表来检测这些话题。该分类器可以定期重新训练，以捕捉话题随时间的变化。

   - 通过招募众包工人讨论其中一个目标话题，收集了一个小型验证集。

• *性别偏见缓解*:



• 他们使用[CTRL](https://arxiv.org/abs/1909.05858)风格训练来缓解性别偏见。



• 具体来说，给定一个性别词列表，用$F^0 M^0$、$F^0 M^+$、$F^+ M^+$和$F^+ M^0$标签标记训练样本，表示响应是否包含女性/男性词汇（$+$包含，$-$不包含）。在测试时，系统使用控制标签$F^0 M^0$以避免输出性别特定词汇。

英文原文：

• *Detect unsafe content*: Adopt a classifier for detecting unsafe language on both the input and output side, as an extra safety layer on top of the language model.



   - The classifier is trained on an enhanced version of the [Jigsaw toxic](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#jigsaw) comment dataset (safe vs unsafe binary labels), extended with [adversarial human attacks](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#adversarial-attacks) ([Dinan et al. 2019](https://arxiv.org/abs/1908.06083)) and [semi-supervision](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#semi-supervised-dataset) ([Khatri et al. 2018](https://arxiv.org/abs/1811.12900)).

   - The safety classifier can be used on both the user input and the model output. If it detects unsafe content, the system is configured to return a canned, predefined response (e.g “I’m sorry I’m not sure what to say.”), or decide to change topics. It is worthy noting that this approach relies on a high-quality classifier. The conversation experience would be drastically disrupted with too many false positives.

   - Bot adversarial dialogue (BAD) safety: The idea is to collect data on humans adversarially probing the system to make mistakes and then use the data for further training. During annotation, human labellers can tag the bot’s response with an unsafe-safe rating based on the percentage of population who may consider it as unsafe. This probing data collection is used to train a multi-turn safety classifier, predicting whether a response is offensive given the dialogue context.

• *Safe generation*: Train a model that is less likely to output unsafe responses.



   - A predefined list of unsafe words/n-grams can be [blocked](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#blacklisting) at decoding time.

   - The pretraining data is filtered by the above safety classifier, or filtered based on known authors.

   - The problem with pre-training only with safe datasets is that if the model has never seen toxic language during training, it would not know how to respond at test time (OOD; e.g. may just copy the offensive content). They instead prepare a collection of training samples where the last utterance is labelled as “unsafe” and then attach a safe response following that unsafe attack. Then the model is fine-tuned on the “baked-in” safety data.

   - Do [CTRL](https://arxiv.org/abs/1909.05858) style training by assigning “safe” vs “unsafe” label using the safety classifier.

• *Avoid sensitive topics*:



   - In order to avoid sensitive topics (politics, religion, drug use, medical advice, and NSFW and relationships/dating), they trained a multi-class classifier to detect those topics using crowdsourced lists of subreddits. The classifier can be periodically re-trained to capture the changes within topics over time.

   - A small validation set is collected by recruiting crowdsourced workers to discuss one of the target topics.

• *Gender bias mitigation*:



• They used [CTRL](https://arxiv.org/abs/1909.05858) style training to mitigate gender biases.



• Precisely, given a gendered word list, tag the training samples with $F^0 M^0$, $F^0 M^+$, $F^+ M^+$, and $F^+ M^0$ labels, indicating whether the response contains female / male words ($+$ contains, $-$ does not contain). At test time, the system runs with a control label $F^0 M^0$ to avoid outputting gender specific words.

### 附录：数据集

> Appendix: Datasets

（*此处仅列出英文数据集。）

> (*Only datasets in English are listed here.)

**仇恨言论和冒犯性语言**数据集（2017）：包含约2.5万条推文，每条都手动标记为以下三类之一：仇恨言论、冒犯性但非仇恨言论，或既非冒犯性也非仇恨言论。 [[下载](https://github.com/t-davidson/hate-speech-and-offensive-language/blob/master/data/readme.md)]

> **Hate Speech and Offensive Language** Dataset (2017): contains about 25k tweets, each labelled manually as one of three categories: hate speech, offensive but not hate speech, or neither offensive nor hate speech. [[Download](https://github.com/t-davidson/hate-speech-and-offensive-language/blob/master/data/readme.md)]

**Jigsaw Toxic**评论分类数据集（2018）：包含约16万个从维基百科讨论页面提取的示例，每个示例都标注了7个类别：有毒、严重有毒、淫秽、威胁、侮辱、身份仇恨和无毒。标注过程涉及5000名众包标注者。 [[下载](https://www.kaggle.com/c/jigsaw-toxic-comment-classification-challenge)]

> **Jigsaw Toxic** Comments Classification Dataset (2018): contains about 160k examples extracted from Wikipedia discussion pages, each annotated for 7 classes: toxic, severe toxic, obscene, threat, insult, identity hate and non-toxic. The labelling process involved 5000 crowdsourced annotators. [[Download](https://www.kaggle.com/c/jigsaw-toxic-comment-classification-challenge)]

**Jigsaw Unintended Bias in Toxicity**分类数据集（2019）：包含约200万条来自Civil Comments平台的评论，该平台于2017年关闭。这些数据标注了毒性、毒性子类型和身份提及，这使得能够评估与身份提及相关的意外偏见。 [[下载](https://www.kaggle.com/c/jigsaw-unintended-bias-in-toxicity-classification)]

> **Jigsaw Unintended Bias in Toxicity** Classification Dataset (2019): contains about 2 Millions comments from the Civil Comments platform, which shut down in 2017. This data is annotated for toxicity, toxicity sub-types, and mentions of identities, which enables evaluation of unintended bias with respect to identity mentions. [[Download](https://www.kaggle.com/c/jigsaw-unintended-bias-in-toxicity-classification)]

**OLID**（冒犯性语言识别数据集；2019）：包含14,100条英文推文，根据[此处](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#categorization-of-toxic-content)描述的三级分类法进行标注。 [[下载](https://sites.google.com/site/offensevalsharedtask/olid)]

> **OLID** (Offensive Language Identification Dataset; 2019): contains 14,100 English tweets, annotated according to the three-level taxonomy as described [here](https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/#categorization-of-toxic-content). [[Download](https://sites.google.com/site/offensevalsharedtask/olid)]

**SOLID**（半监督冒犯性语言识别数据集；2020）：包含900多万条推文，按照OLID的三级分类法进行标注。 [[下载](https://sites.google.com/site/offensevalsharedtask/solid)]

> **SOLID** (Semi-Supervised Offensive Language Identification Dataset; 2020): contains 9+ Millions tweets annotated following OLID’s three level taxonomy. [[Download](https://sites.google.com/site/offensevalsharedtask/solid)]

**RealToxicityPrompts**数据集（2020）：包含10万个来自网络的句子片段，带有Perspective API毒性评分，用于研究语言模型中神经毒性退化的风险。 [[下载](https://allenai.org/data/real-toxicity-prompts)]

> **RealToxicityPrompts** dataset (2020): contains 100k sentence snippets from the web with Perspective API toxicity scores for studying the risk of neural toxic degeneration in language models. [[Download](https://allenai.org/data/real-toxicity-prompts)]

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Mar 2021). Reducing toxicity in language models. Lil’Log. https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/.

> Weng, Lilian. (Mar 2021). Reducing toxicity in language models. Lil’Log. https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/.

或

> Or

```
@article{weng2021toxic,
  title   = "Reducing Toxicity in Language Models.",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2021",
  month   = "Mar",
  url     = "https://lilianweng.github.io/posts/2021-03-21-lm-toxicity/"
}
```

### 参考文献

> References

[1] Vidgen, et al. [“Challenges and frontiers in abusive content detection.”](https://www.aclweb.org/anthology/W19-3509/) Workshop on Abusive Language Online 2019.

> [1] Vidgen, et al. [“Challenges and frontiers in abusive content detection.”](https://www.aclweb.org/anthology/W19-3509/) Workshop on Abusive Language Online 2019.

[2] Zampieri et al. [“Predicting the type and target of offensive posts in social media.”](https://arxiv.org/abs/1902.09666) NAACL 2019.

> [2] Zampieri et al. [“Predicting the type and target of offensive posts in social media.”](https://arxiv.org/abs/1902.09666) NAACL 2019.

[3] Vidgen & Deczynski. [“Directions in abusive language training data, a systematic review: Garbage in, garbage out.”](https://arxiv.org/abs/2004.01670) PLoS ONE 15(12): e0243300 (2020).

> [3] Vidgen & Deczynski. [“Directions in abusive language training data, a systematic review: Garbage in, garbage out.”](https://arxiv.org/abs/2004.01670) PLoS ONE 15(12): e0243300 (2020).

[4] Davidson et al. [“Automated hate speech detection and the problem of offensive language.”](https://arxiv.org/abs/1703.04009) ICWSM 2017.

> [4] Davidson et al. [“Automated hate speech detection and the problem of offensive language.”](https://arxiv.org/abs/1703.04009) ICWSM 2017.

[5] Khatri et al. [“Detecting offensive content in open-domain conversations using two stage semi-supervision.”](https://arxiv.org/abs/1811.12900) NeuriIPS CONVAI Workshop 2018.

> [5] Khatri et al. [“Detecting offensive content in open-domain conversations using two stage semi-supervision.”](https://arxiv.org/abs/1811.12900) NeuriIPS CONVAI Workshop 2018.

[6] Rosenthal et al. [“A Large-Scale Semi-Supervised Dataset for Offensive Language Identification”](https://arxiv.org/abs/2004.14454) arXiv:2004.14454 (2020).

> [6] Rosenthal et al. [“A Large-Scale Semi-Supervised Dataset for Offensive Language Identification”](https://arxiv.org/abs/2004.14454) arXiv:2004.14454 (2020).

[7] Pavlopoulos et al. [“Toxicity Detection: Does Context Really Matter?”](https://arxiv.org/abs/2006.00998) arXiv:2006.00998 (2020).

> [7] Pavlopoulos et al. [“Toxicity Detection: Does Context Really Matter?”](https://arxiv.org/abs/2006.00998) arXiv:2006.00998 (2020).

[8] Dinan et al. [“Build it, break it, fix it for dialogue safety: Robustness from adversarial human attack.”](https://arxiv.org/abs/1908.06083) arXiv:1908.06083 (2019).

> [8] Dinan et al. [“Build it, break it, fix it for dialogue safety: Robustness from adversarial human attack.”](https://arxiv.org/abs/1908.06083) arXiv:1908.06083 (2019).

[9] Kurita et al. [“Towards Robust Toxic Content Classification”](https://arxiv.org/abs/1912.06872) arXiv:1912.06872 (2019)

> [9] Kurita et al. [“Towards Robust Toxic Content Classification”](https://arxiv.org/abs/1912.06872) arXiv:1912.06872 (2019)

[10] Santos et al. [“Fighting offensive language on social media with unsupervised text style transfer.”](https://arxiv.org/abs/1805.07685) arXiv:1805.07685 (2018)

> [10] Santos et al. [“Fighting offensive language on social media with unsupervised text style transfer.”](https://arxiv.org/abs/1805.07685) arXiv:1805.07685 (2018)

[11] Dai et al. [“Style Transformer: Unpaired Text Style Transfer without Disentangled Latent Representation”](https://arxiv.org/abs/1905.05621) ACL 2019.

> [11] Dai et al. [“Style Transformer: Unpaired Text Style Transfer without Disentangled Latent Representation”](https://arxiv.org/abs/1905.05621) ACL 2019.

[12] Laugier et al. [“Civil Rephrases Of Toxic Texts With Self-Supervised Transformers”](https://arxiv.org/abs/2102.05456)  arXiv:2102.05456 (2021). [代码](https://github.com/LeoLaugier/conditional-auto-encoder-text-to-text-transfer-transformer)

> [12] Laugier et al. [“Civil Rephrases Of Toxic Texts With Self-Supervised Transformers”](https://arxiv.org/abs/2102.05456)  arXiv:2102.05456 (2021). [code](https://github.com/LeoLaugier/conditional-auto-encoder-text-to-text-transfer-transformer)

[13] Schick et al. [“Self-Diagnosis and Self-Debiasing: A Proposal for Reducing Corpus-Based Bias in NLP”](https://arxiv.org/abs/2103.00453) arXiv:2103.00453 (2021).

> [13] Schick et al. [“Self-Diagnosis and Self-Debiasing: A Proposal for Reducing Corpus-Based Bias in NLP”](https://arxiv.org/abs/2103.00453) arXiv:2103.00453 (2021).

[14] Gehman et al. [“RealToxicityPrompts: Evaluating Neural Toxic Degeneration in Language Models”](https://arxiv.org/abs/2009.11462) EMNLP 2020.

> [14] Gehman et al. [“RealToxicityPrompts: Evaluating Neural Toxic Degeneration in Language Models”](https://arxiv.org/abs/2009.11462) EMNLP 2020.

[15] Xu et al. [“Recipes for Safety in Open-domain Chatbots”](https://arxiv.org/abs/2010.07079) arXiv:2010.07079 (2020).

> [15] Xu et al. [“Recipes for Safety in Open-domain Chatbots”](https://arxiv.org/abs/2010.07079) arXiv:2010.07079 (2020).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Language Model (LM) | 语言模型 | 预测文本序列中下一个词概率的模型。 |
| Toxicity | 毒性 | 描述粗鲁、不尊重、不合理或可能冒犯/伤害接收者的内容。 |
| Hate Speech | 仇恨言论 | 针对特定群体（如基于种族、性别）的冒犯性言论。 |
| Bias | 偏见 | 模型从训练数据中习得的不公平或不准确的倾向。 |
| Crowdsourcing | 众包 | 将任务分配给大量非专业标注者以收集数据的方法。 |
| Semi-supervised Learning | 半监督学习 | 利用少量标注数据和大量未标注数据进行模型训练的方法。 |
| Adversarial Attack | 对抗性攻击 | 通过微小扰动欺骗模型使其产生错误分类的输入。 |
| Perspective API | Perspective API | 一种商业API，用于检测文本中的毒性、侮辱、威胁等多种属性。 |
| Self-diagnosis | 自诊断 | 利用预训练语言模型自身能力检测其输出中不合社会期望属性的过程。 |
| Self-debiasing | 自去偏 | 利用预训练语言模型内部知识降低模型生成中不期望属性概率的过程。 |
| Text Style Transfer | 文本风格迁移 | 在保留文本内容的同时，将其风格从一种转换为另一种的技术。 |
| Controllable Generation | 可控生成 | 通过引导解码、提示设计或模型微调来控制语言模型输出特定风格或内容的策略。 |
| Blacklisting | 黑名单 | 阻止特定词语或短语在语言模型生成中出现的方法。 |
| Prompt-based Detection | 基于提示的检测 | 通过预定义提示模板和模型对“是/否”的概率来检测属性。 |
| Perplexity | 困惑度 | 衡量语言模型预测样本的准确性或流畅度的指标，值越低越好。 |
