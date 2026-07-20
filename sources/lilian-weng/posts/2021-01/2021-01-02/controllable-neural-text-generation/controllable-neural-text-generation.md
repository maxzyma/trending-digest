# 可控神经文本生成

> Controllable Neural Text Generation

> 来源：Lil'Log / Lilian Weng，2021-01-02
> 原文链接：https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/
> 分类：自然语言处理 / 文本生成

## 核心要点

- 可控神经文本生成旨在引导无条件语言模型输出具有特定属性（如主题、风格、情感）的文本。
- 实现可控文本生成主要有三种方法：应用引导式解码策略、优化提示设计以及微调基础模型或可引导层。
- 解码策略包括贪婪搜索、集束搜索、Top-k采样、核采样和惩罚采样，它们在不修改模型权重的情况下改变生成样本。
- 引导式解码通过将人类偏好（如主题词、情感、重复惩罚）融入候选排名函数来指导文本生成。
- 智能提示设计（如AutoPrompt、Prefix-Tuning、P-tuning、Prompt Tuning）通过优化连续提示嵌入或触发词元，在低数据量下能有效引导大型语言模型。
- 微调方法包括条件训练（如CTRL）和强化学习微调，后者通过优化序列级任务特定指标或人类偏好奖励函数来改进生成。
- 基于人类偏好的强化学习微调通过学习奖励函数来更好地对齐模型输出与人类判断的质量。
- 通过可控层进行引导式微调（如PPLM、DELOREAN、Side-tuning、Auxiliary Tuning、GeDi）在保持基础模型不变的同时，微调少量额外参数以实现高效控制。
- 基于分布控制的生成将受控文本生成视为带约束的概率分布优化，通过学习目标模型的能量基模型和自回归策略来实现。
- 非似然训练通过结合最大似然更新和避免不需要内容的非似然更新，解决语言模型过度自信和重复生成的问题。

## 正文

[2021-02-01 更新：更新至 2.0 版本，增加了几项工作并修复了许多错别字。]
  

[2021-05-26 更新：在[“提示设计”](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#gradient-based-search)部分添加了 P-tuning 和 Prompt Tuning。]
  

[2021-09-19 更新：添加了[“unlikelihood training”](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/##unlikelihood-training)。]

> [Updated on 2021-02-01: Updated to version 2.0 with several work added and many typos fixed.]
>
>
> [Updated on 2021-05-26: Add P-tuning and Prompt Tuning in the [“prompt design”](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#gradient-based-search) section.]
>
>
> [Updated on 2021-09-19: Add [“unlikelihood training”](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/##unlikelihood-training).]

网络上有海量的自由文本，其数量比标注的基准数据集多出几个数量级。最先进的语言模型（LM）是利用大规模无监督网络数据训练的。当通过迭代采样下一个token从语言模型生成样本时，我们对输出文本的属性（如主题、风格、情感等）没有太多控制。许多应用需要对模型输出有良好的控制。例如，如果我们计划使用语言模型为儿童生成阅读材料，我们希望引导输出的故事是安全的、有教育意义的，并且易于儿童理解的。

> There is a gigantic amount of free text on the Web, several magnitude more than labelled benchmark datasets. The state-of-the-art language models (LM) are trained with unsupervised Web data in large scale. When generating samples from LM by iteratively sampling the next token, we do not have much control over attributes of the output text, such as the topic, the style, the sentiment, etc. Many applications would demand a good control over the model output. For example, if we plan to use LM to generate reading materials for kids, we would like to guide the output stories to be safe, educational and easily understood by children.

如何引导一个强大的无条件语言模型？在这篇文章中，我们将深入探讨几种使用无条件语言模型进行可控内容生成的方法。
请注意，模型的可引导性仍然是一个开放的研究问题。每种介绍的方法都有其优缺点。

> How to steer a powerful unconditioned language model? In this post, we will delve into several approaches for controlled content generation with an unconditioned langage model.
> Note that model steerability is still an open research question. Each introduced method has certain pros & cons.

1. 应用引导式解码策略并在测试时选择期望的输出。
2. 通过良好的提示设计优化以获得最期望的结果。
3. 微调基础模型或可引导层以进行条件内容生成。

> • Apply guided decoding strategies and select desired outputs at test time.
> • Optimize for the most desired outcomes via good prompt design.
> • Fine-tune the base model or steerable layers to do conditioned content generation.

在下面的讨论中，我们假设我们能够访问一个预训练的生成式语言模型 $p_\theta$。该模型通过优化下一个token预测来学习token序列的分布：$\mathcal{L}_\text{ML} = - \sum_t \log p_\theta(x_t \vert x_{<t})$。

> In the following discussion, we assume we have access to a pretrained generative language model $p_\theta$. The model has learned the distribution over token sequences by optimizing for the next token prediction: $\mathcal{L}_\text{ML} = - \sum_t \log p_\theta(x_t \vert x_{<t})$.

### 解码策略

> Decoding Strategies

通过采用不同的解码方法，我们可以在采样过程中施加限制或偏好，从而改变生成的样本，而无需修改任何模型权重。尽管解码策略不改变任何可训练参数的值，但它是一个非常重要的组成部分。

> By adopting different decoding methods, we can place restrictions or preferences on the sampling process to alter the generated samples without modifying any model weights. Even though decoding strategies do not change the values of any trainable parameter, it is a quite important component.

#### 常见解码方法

> Common Decoding Methods

由于模型的最后一层预测词汇空间上的对数几率 $o$，因此可以通过应用带温度的 softmax $T$ 来采样下一个词元。采样第 $i$ 个词元的概率为

> Since the final layer of the model predicts logits $o$ over the vocabulary space, the next token can be sampled by applying softmax with temperature $T$. The probability of sampling the $i$ -th token is

$$
p_i \propto \frac{\exp(o_i / T)}{\sum_j \exp(o_j/T)}
$$

低温度会使分布更尖锐，而高温度会使其更平滑。

> A low temperature would make the distribution sharper and a high value makes it softer.

**贪婪搜索**：总是选择概率 *最高* 的下一个词元，相当于设置温度 $T=0$。然而，即使对于训练有素的模型，它也倾向于产生短语重复。

英文原文：Greedy search: Always pick the next token with the *highest* probability, equivalent to setting temperature 

$T=0$. However, it tends to create repetitions of phrases, even for well-trained models.

**集束搜索**：它本质上是广度优先搜索，每层树一个词元，但带宽有限。在搜索树的每一层，集束搜索会跟踪 `n` 个（称为“集束宽度”）最佳候选，并在下一层扩展这些候选的所有后继。如果集束搜索遇到 EOS（句尾）词元，它可能会停止扩展节点。

英文原文：Beam search: It essentially does breadth-first search, one token per tree level, but with a limited bandwidth. At each level of the search tree, beam search keeps track of `n` (named “beam width”) best candidates and expands all the successors of these candidates in the next level. Beam search could stop expanding a node if it hits the EOS (end-of-sentence) token.

然而，基于最大化的解码并不能保证高质量的生成。

> However, maximization-based decoding does not guarantee high-quality generation.

![The probability assigned to the next token by beam search versus by humans. The human selected tokens have much higher variance in predicted probability and thus more surprising. (Image source: Holtzman et al. 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/beam_search_less_surprising.png)

**Top-k 采样** ([Fan et al., 2018](https://arxiv.org/abs/1805.04833))：在每个采样步骤中，只选择前 `k` 个最有可能的词元，并在它们之间重新分配概率质量。在 [Fan et al., 2018](https://arxiv.org/abs/1805.04833) 中，作者提出使用 *top-k 随机采样*，其中下一个词元是从前 `k` 个最有可能的候选词中随机选择的，他们认为这种方法可以生成比集束搜索更具新颖性且重复性更少的内容。

英文原文：Top-k sampling ([Fan et al., 2018](https://arxiv.org/abs/1805.04833)): At each sampling step, only the top `k` most likely tokens are selected and the probability mass is redistributed among them. In [Fan et al., 2018](https://arxiv.org/abs/1805.04833), the authors proposed to use *top-k random sampling* where the next token is randomly selected among the top `k` most likely candidates and they argued that this approach can generate more novel and less repetitive content than beam search.

**核采样** ([Holtzman et al. 2019](https://arxiv.org/abs/1904.09751))：也称为“Top-p 采样”。top-k 采样的一个缺点是预定义的数字 `k` 没有考虑到概率分布可能有多 *偏斜*。核采样选择累积概率超过阈值（例如 0.95）的最小顶级候选集，然后重新调整所选候选之间的分布。

英文原文：Nucleus sampling ([Holtzman et al. 2019](https://arxiv.org/abs/1904.09751)): Also known as “Top-p sampling”. One drawback of top-k sampling is that the predefined number `k` does not take into consideration how *skewed* the probability distribution might be. The nucleus sampling selects the smallest set of top candidates with the cumulative probability exceeding a threshold (e.g. 0.95) and then the distribution is rescaled among selected candidates.

Top-k 采样和核采样在适当的超参数设置下都能减少重复。

> Both top-k and nucleus sampling have less repetitions with a proper set of hyperparameters.

**惩罚采样** ([Keskar et al. 2019](https://arxiv.org/abs/1909.05858))：为了避免生成重复子字符串的常见失败情况，[CTRL](https://arxiv.org/abs/1909.05858) 论文提出了一种新的采样方法，通过降低先前生成词元的分数来惩罚重复。具有重复惩罚的下一个词元的概率分布定义为：

> **Penalized sampling** ([Keskar et al. 2019](https://arxiv.org/abs/1909.05858)): To avoid the common failure case of generating duplicate substrings, the [CTRL](https://arxiv.org/abs/1909.05858) paper proposed a new sampling method to penalize repetitions by discounting the scores of previously generated tokens. The probability distribution for the next token with repetition penalty is defined as:

$$
p_i = \frac{\exp(o_i / (T \cdot \mathbb{1}(i \in g)))}{\sum_j \exp(o_j / (T \cdot \mathbb{1}(j \in g)))} \quad
\mathbb{1}(c) = \theta \text{ if the condition }c\text{ is True else }1
$$

其中 $g$ 包含一组先前生成的词元，$\mathbb{1}(.)$ 是一个恒等函数。发现 $\theta=1.2$ 在减少重复和真实生成之间取得了良好的平衡。

> where $g$ contains a set of previously generated tokens, $\mathbb{1}(.)$ is an identity function. $\theta=1.2$ is found to yield a good balance between less repetition and truthful generation.

#### 引导式解码

> Guided Decoding

上述所有标准解码策略都根据预测概率采样令牌，不附加任何额外信息。我们对主题或情感的偏好可以融入候选排名函数中，通过改变候选排名分数来指导样本生成。在每个解码步骤中，用于令牌选择的排名分数可以设置为语言模型对数似然和一组期望特征判别器的组合。这些特征旨在通过启发式方法（[Ghazvininejad et al., 2017](https://www.aclweb.org/anthology/P17-4008/)）、监督学习（[Holtzman et al., 2018](https://arxiv.org/abs/1805.06087)）或强化学习（[Li et al., 2017](https://arxiv.org/abs/1701.06549)）来量化人类偏好。

> All the above standard decoding strategies sample tokens according to the predicted probability, with no additional information. Our preferences on topic or sentiment can be baked into the candidate ranking function to guide the sample generation by altering the candidate ranking score. The ranking score for token selection at each decoding step can be set as a combination of LM log-likelihood and a set of desired feature discriminators. The features are designed to quantify human preferences by heuristics ([Ghazvininejad et al., 2017](https://www.aclweb.org/anthology/P17-4008/)), supervised learning ([Holtzman et al., 2018](https://arxiv.org/abs/1805.06087)) or RL ([Li et al., 2017](https://arxiv.org/abs/1701.06549)).

[Ghazvininejad et al. (2017)](https://www.aclweb.org/anthology/P17-4008/) 构建了一个名为“Hafez”的系统，用于通过在解码步骤中调整束搜索的采样权重来生成所需风格的诗歌。下一个标记 $x_{t+1}$ 在步骤 $t$ 的采样可能性通过一个评分函数进行增强：

> [Ghazvininejad et al. (2017)](https://www.aclweb.org/anthology/P17-4008/) built a system called “Hafez” for generating poetry in desired style by adjusting sampling weights in beam search at decoding steps. The likelihood of sampling for the next token $x_{t+1}$ at step $t$ is augmented by a scoring function:

$$
\text{score}(x_{t+1}, b_t) = \text{score}(b_t) + \log p(x_{t+1}) + \color{green}{\sum_i \alpha_i f_i(x_{t+1})}
$$

其中 $\log p(x_{t+1})$ 是 LM 预测的对数似然。$\text{score}(b_t)$ 是当前束状态 $b_t$ 中已生成词的累积得分。绿色部分可以包含许多不同的特征，用于引导输出的风格。一组特征函数 $f_i(.)$ 定义了偏好，并且相关的权重 $alpha_i$ 就像“控制旋钮”，可以在解码时轻松定制。特征可以衡量各种属性，并且可以轻松组合；例如，

> where $\log p(x_{t+1})$ is the log-likelihood predicted by LM. $\text{score}(b_t)$ is the accumulated score of the already-generated words in the current beam state $b_t$. The green part can incorporate many different features for steering the style of the output. A set of feature functions $f_i(.)$ define the preferences and the associated weights $alpha_i$ work like “control knobs” that can be easily customized at decoding time. Features can measure a variety of attributes and can be easily combined; for example,

• $x_{t+1}$是否存在于一组期望或禁止的主题词中。

• $x_{t+1}$是否表示某种情绪。

• $x_{t+1}$是否是重复的标记（因此$f_i$也需要将历史作为输入）。

• 如果特别偏好更长或更短的词，则$x_{t+1}$的长度。

英文原文：

• whether $x_{t+1}$ exists in a bag of desired or banned topical words.

• whether $x_{t+1}$ indicates certain sentiments.

• whether $x_{t+1}$ is a repeated token (and thus $f_i$ needs to take the history as input too).

• the length of $x_{t+1}$ if longer or shorter words are in particular preferred.

与Hafez类似，[Baheti et al. (2018)](https://arxiv.org/abs/1809.01215)手动设计了用于排序的特征，并通过在上下文和补全的专题分布或嵌入之间附加相似性分数来改变采样分布。

> Similar to Hafez, [Baheti et al. (2018)](https://arxiv.org/abs/1809.01215) manually designed features for ranking and altered the sampling distribution by appending similarity scores between topic distribution or embeddings of the context and the completion.

[Holtzman et al. (2018)](https://arxiv.org/abs/1805.06087)采用了一组学习到的判别器，每个判别器都专注于由[Grice’s maxims](https://en.wikipedia.org/wiki/Cooperative_principle)指导的不同通信原则：质量、数量、关系和方式。判别器通过分别测量重复、蕴涵、相关性和词汇多样性来学习编码这些期望的原则。给定一些真实补全，所有判别器模型都经过训练以最小化排序对数似然，$\log\sigma(f_i(y_g) - f_i(y))$，因为黄金延续$y_g$预计会比生成的延续$y$获得更高的分数。在这里，权重系数$\alpha_i$也被学习以最小化黄金标准和生成的补全之间的分数差异。判别对抗搜索（DAS；[Scialom et al., 2020](https://arxiv.org/abs/2002.10375)）受GAN启发，并训练判别器区分人类创建的文本和机器生成的文本。判别器为每个标记而不是整个序列预测一个标签。判别器对数概率被添加到分数中，以引导采样趋向于人类书写的风格。

> [Holtzman et al. (2018)](https://arxiv.org/abs/1805.06087) adopted a set of learned discriminators, each specializing in a different principle of communication guided by [Grice’s maxims](https://en.wikipedia.org/wiki/Cooperative_principle): quality, quantity, relation and manner. The discriminators learn to encode these desired principles by measuring repetition, entailment, relevance, and lexical diversity, respectively. Given some ground truth completion, all the discriminator models are trained to minimize the ranking log-likelihood, $\log\sigma(f_i(y_g) - f_i(y))$, because the gold continuation $y_g$ is expected to obtain a higher score than the generated one $y$. Here the weight coefficients $\alpha_i$ are also learned to minimize the score difference between the golden standard and the generated completion.  Discriminative Adversarial Search (DAS; [Scialom et al., 2020](https://arxiv.org/abs/2002.10375)) is inspired by GAN and trains the discriminator to tell apart human created text from machine generated text. The discriminator predicts a label for each token instead of for the entire sequence. The discriminator logprob is added to the score to guide sampling towards the human-written style.

[Meister et al. (2020)](https://arxiv.org/abs/2010.02650)在正则化解码框架中研究了束搜索：

> [Meister et al. (2020)](https://arxiv.org/abs/2010.02650) studied beam search in a regularized decoding framework:

$$
\mathbf{y}^* = \arg\max_{\mathbf{y}\in\mathcal{Y}} \big( \underbrace{\log p_\theta(\mathbf{y}\vert\mathbf{x})}_\text{MAP} - \underbrace{\lambda\mathcal{R}(\mathbf{y})}_\text{regularizer} \big)
$$

由于我们期望最大概率对应最小惊奇度，因此语言模型在时间步 $t$ 的惊奇度可以定义如下：

> Since we expect maximum probability to have minimum surprise, the surprisal of a LM at time step $t$ can be defined as follows:

$$
\begin{aligned}
u_0(\texttt{BOS}) &= 0 \text{  ; BOS is a placeholder token for the beginning of a sentence.}\\
u_t(y) &= -\log P_\theta(y \vert \mathbf{x}, \mathbf{y}_{<{t}}) \text{ for }t \geq 1
\end{aligned}
$$

MAP（最大后验）部分要求在给定上下文的情况下序列具有最大概率，而正则化器则引入了其他约束。全局最优策略可能偶尔需要一个高惊奇度步骤，以便缩短输出长度或之后产生更多低惊奇度步骤。

> The MAP (maximum a posteriori) part demands for sequences with maximum probability given context, while the regularizer introduces other constraints. It is possible a global optimal strategy may need to have a high-surprisal step occasionally so that it can shorten the output length or produce more low-surprisal steps afterwards.

束搜索在自然语言处理领域经受住了时间的考验。问题是：*如果我们要将束搜索建模为正则化解码框架中的精确搜索，那么 $\mathcal{R}(\mathbf{y})$ 应该如何建模？* 该论文提出了束搜索与 *均匀信息密度* (UID) 假设之间的联系。

> Beam search has gone through the test of time in the field of NLP. The question is: *If we want to model beam search as exact search in a regularized decoding framework, how should $\mathcal{R}(\mathbf{y})$ be modeled?* The paper proposed a connection between beam search and the *uniform information density* (UID) hypothesis.

> “均匀信息密度假设（UID；Levy 和 Jaeger，2007）指出——在语法约束下——人类更喜欢将信息（信息论意义上的）均匀分布在语言信号（例如句子）中的句子。”

> “The uniform information density hypothesis (UID; Levy and Jaeger, 2007)  states that—subject to the constraints of the grammar—humans prefer sentences that distribute information (in the sense of information theory) equally across the linguistic signal, e.g., a sentence.”

换句话说，它假设人类更喜欢惊奇度均匀分布的文本。流行的解码方法，如 top-k 采样或核采样，实际上会过滤掉高惊奇度选项，从而隐式地鼓励输出序列中的 UID 特性。

> In other words, it hypothesizes that humans prefer text with evenly distributed surprisal. Popular decoding methods like top-k sampling or nuclear sampling actually filter out high-surprisal options, thus implicitly encouraging the UID property in output sequences.

该论文实验了多种形式的正则化器：

> The paper experimented with several forms of regularizers:

1\. *贪婪*：$\mathcal{R}_\text{greedy}(\mathbf{y}) = \sum_{t=1}^{\vert\mathbf{y}\vert} \big(u_t(y_t) - \min_{y’ \in \mathcal{V}} u_t(y’) \big)^2$；如果设置 $\lambda \to \infty$，我们得到贪婪搜索。请注意，在每个单独的步骤中贪婪并不能保证全局最优性。

2\. *方差正则化器*：$\mathcal{R}_\text{var}(\mathbf{y}) = \frac{1}{\vert\mathbf{y}\vert}\sum_{t=1}^{\vert\mathbf{y}\vert} \big(u_t(y_t) - \bar{u} \big)^2$，其中 $\bar{u}$ 是所有时间步的平均惊奇度。它直接编码了 UID 假设。

3\. *局部一致性*：$\mathcal{R}_\text{local}(\mathbf{y}) = \frac{1}{\vert\mathbf{y}\vert}\sum_{t=1}^{\vert\mathbf{y}\vert} \big(u_t(y_t) - u_{t-1}(y_{t-1}) \big)^2$；这种解码正则化器鼓励相邻的 token 具有相似的惊奇度。

4\. *最大值正则化器*：$\mathcal{R}_\text{max}(\mathbf{y}) = \max_t u_t(y_t)$ 惩罚惊奇度的最大补偿。

5\. *平方正则化器*：$\mathcal{R}_\text{square}(\mathbf{y}) = \sum_{t=1}^{\vert\mathbf{y}\vert} u_t(y_t)^2$ 鼓励所有 token 的惊奇度接近 0。

英文原文：

1\. *Greedy*: $\mathcal{R}_\text{greedy}(\mathbf{y}) = \sum_{t=1}^{\vert\mathbf{y}\vert} \big(u_t(y_t) - \min_{y’ \in \mathcal{V}} u_t(y’) \big)^2$; if set $\lambda \to \infty$, we have greedy search. Note that being greedy at each individual step does not guarantee global optimality.

2\. *Variance regularizer*: $\mathcal{R}_\text{var}(\mathbf{y}) = \frac{1}{\vert\mathbf{y}\vert}\sum_{t=1}^{\vert\mathbf{y}\vert} \big(u_t(y_t) - \bar{u} \big)^2$ , where $\bar{u}$ is the average surprisal over all timesteps. It directly encodes the UID hypothesis.

3\. *Local consistency*: $\mathcal{R}_\text{local}(\mathbf{y}) = \frac{1}{\vert\mathbf{y}\vert}\sum_{t=1}^{\vert\mathbf{y}\vert} \big(u_t(y_t) - u_{t-1}(y_{t-1}) \big)^2$; this decoding regularizer encourages adjacent tokens to have similar surprisal.

4\. *Max regularizer*: $\mathcal{R}_\text{max}(\mathbf{y}) = \max_t u_t(y_t)$ penalizes the maximum compensation of surprisal.

5\. *Squared regularizer*: $\mathcal{R}_\text{square}(\mathbf{y}) = \sum_{t=1}^{\vert\mathbf{y}\vert} u_t(y_t)^2$ encourages all the tokens to have surprisal close to 0.

一项使用贪婪正则化器的实验表明，更大的 $\lambda$ 会带来更好的性能（例如，通过 NMT 任务的 BLEU 衡量）和更低的信息熵标准差。

> An experiment with greedy regularizers showed that larger $\lambda$ results in better performance (e.g. measured by BLEU for NMT task) and lower std dev of surprisal.

![The plot of BLEU and std. dev of surprisals as functions of the strength of the regularizer $\lambda$. The subgraph in grey shows the relationship between BLEU and surprisal std. dev. (Image source: Meister et al. 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/beam-search-greedy-regularizer.png)

默认的束搜索在束大小增加时会导致文本生成质量下降。正则化束搜索极大地有助于缓解这个问题。组合正则化器进一步提高了性能。在他们的 NMT 实验中，他们发现贪婪正则化器的 $\lambda=5$ 和平方正则化器的 $\lambda=2$ 是最优的组合正则化器。

> A default beam search would have text generation of decreased quality when beam size increases. Regularized beam search greatly helps alleviate this issue. A combined regularizer further improves the performance. In their experiments for NMT, they found $\lambda=5$ for greedy and $\lambda=2$ for squared work out as the optimal combined regularizer.

![The plot of BLEU of a function of beam size (left) and BLEU scores for translations created by different regularized decoding strategies. (Image source: Meister et al. 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/beam-search-size-regularized.png)

引导式解码本质上是运行一种更昂贵的束搜索，其中采样概率分布会根据关于人类偏好的辅助信息进行修改。

> Guided decoding essentially runs a more expensive beam search where the sampling probability distribution is altered by side information about human preferences.

#### 可训练解码

> Trainable Decoding

给定一个训练好的语言模型，[Gu 等人 (2017)](https://arxiv.org/abs/1702.02429) 提出了一种 **可训练的贪婪解码** 算法，用于最大化任意目标以采样序列。该思想基于 *噪声、并行近似解码* ([NPAD](https://arxiv.org/abs/1605.03835))。NPAD 将非结构化噪声注入模型隐藏状态，并并行运行多次噪声解码以避免潜在的性能下降。更进一步，可训练的贪婪解码用一个可学习的随机变量取代了非结构化噪声，该变量由一个强化学习（RL）智能体预测，该智能体将先前的隐藏状态、先前的解码标记和上下文作为输入。换句话说，解码算法学习一个 RL 参与者来操纵模型隐藏状态以获得更好的结果。

> Given a trained language model, [Gu et al (2017)](https://arxiv.org/abs/1702.02429) proposed a **trainable greedy decoding** algorithm to maximize an arbitrary objective for sampling sequences. The idea is based on the *noisy, parallel approximate decoding* ([NPAD](https://arxiv.org/abs/1605.03835)). NPAD injects unstructured noise into the model hidden states and runs noisy decoding multiple times in parallel to avoid potential degradation. To take a step further, trainable greedy decoding replaces the unstructured noise with a learnable random variable, predicted by a RL agent that takes the previous hidden state, the previous decoded token and the context as input. In other words, the decoding algorithm learns a RL actor to manipulate the model hidden states for better outcomes.

[Grover 等人 (2019)](https://arxiv.org/abs/1906.09531) 训练了一个二元分类器，用于区分来自数据分布的样本和来自生成模型的样本。该分类器用于估计 *重要性权重*，以构建新的未归一化分布。所提出的策略称为 **无似然重要性加权 (LFIW)**。

> [Grover et al. (2019)](https://arxiv.org/abs/1906.09531) trained a binary classifier to distinguish samples from data distribution and samples from the generative model. This classifier is used to estimate *importance weights* for constructing a new unnormalized distribution. The proposed strategy is called **likelihood-free importance weighting (LFIW)**.

设 $p$ 为真实数据分布，$p_\theta$ 为学习到的生成模型。一种经典的评估给定函数 $f$ 在 $p$ 下的期望，并使用来自 $p_\theta$ 的样本的方法是使用重要性采样。

> Let $p$ be the real data distribution and $p_\theta$ be a learned generative model. A classical approach for evaluating the expectation of a given function $f$ under $p$ using samples from $p_\theta$ is to use importance sampling.

$$
\mathbb{E}_{\mathbf{x}\sim p} [f(\mathbf{x})] 
= \mathbb{E}_{\mathbf{x}\sim p_\theta} \Big[\frac{p(\mathbf{x})}{p_\theta(\mathbf{x})} f(\mathbf{x})\Big]
\approx \frac{1}{N} \sum_{i=1}^N w(\mathbf{x}_i)f(\mathbf{x}_i)
$$

然而，$p(\mathbf{x})$ 只能通过有限数据集进行估计。设 $c_\phi: \mathcal{X} \to [0,1]$ 是一个概率二元分类器，用于预测样本 $\mathbf{x}$ 是否来自真实数据分布 ($y=1$)。$\mathcal{X}\times\mathcal{Y}$ 上的联合分布表示为 $q(\mathbf{x}, y)$。

> However, $p(\mathbf{x})$ can only be estimated via finite datasets. Let $c_\phi: \mathcal{X} \to [0,1]$ be a probabilistic binary classifier for predicting whether a sample $\mathbf{x}$ is from the true data distribution ($y=1$). The joint distribution over $\mathcal{X}\times\mathcal{Y}$ is denoted as $q(\mathbf{x}, y)$.

$$
q(\mathbf{x}\vert y) = \begin{cases}
p_\theta(\mathbf{x}) & \text{ if }y=0\text{; predicted to be generated data} \\
p(\mathbf{x}) & \text{ otherwise; from the true data distribution}
\end{cases}
$$

那么，如果 $c_\phi$ 是 [贝叶斯最优](https://svivek.com/teaching/lectures/slides/prob-learning/bayes-optimal-classifier.pdf) 的，重要性权重可以通过以下方式估计：

> Then if $c_\phi$ is [Bayes optimal](https://svivek.com/teaching/lectures/slides/prob-learning/bayes-optimal-classifier.pdf), the importance weight can be estimated by:

$$
w_\phi(\mathbf{x}) 
= \frac{p(\mathbf{x})}{p_\theta(\mathbf{x})}
= \frac{q(\mathbf{x} \vert y=1)}{q(\mathbf{x} \vert y=0)}
= \frac{q(y=0)}{q(y=1)} \frac{q(y=1 \vert \mathbf{x})}{q(y=0 \vert \mathbf{x})}
= \gamma \frac{c_\phi(\mathbf{x})}{1 - c_\phi(\mathbf{x})}
$$

其中 $\gamma = \frac{q(y=0)}{q(y=1)} > 0$ 是一个固定的赔率。

> where $\gamma = \frac{q(y=0)}{q(y=1)} > 0$ is a fixed odd ratio.

由于我们无法学习一个完美的最佳分类器，重要性权重将是一个估计值$\hat{w}_\phi$。可以应用一些实用技巧来抵消分类器利用生成样本中的伪影做出非常自信的预测（即非常小的重要性权重）的情况：

> Since we cannot learn a perfect optimal classifier, the importance weight would be an estimation $\hat{w}_\phi$. A couple of practical tricks can be applied to offset cases when the classifier exploits artifacts in the generated samples to make very confident predictions (i.e. very small importance weights):

1\. 自归一化：通过总和$\hat{w}_\phi(\mathbf{x}_i) / \sum_{j=1}^N \hat{w}_\phi(\mathbf{x}_j)$归一化权重。

2\. 平坦化：添加一个幂次缩放参数$\alpha > 0$，$\hat{w}_\phi(\mathbf{x}_i)^\alpha$。

3\. 裁剪：指定一个下限$\max(\hat{w}_\phi(\mathbf{x}_i), \beta)$。

英文原文：

1\. Self-normalization: normalize the weight by the sum $\hat{w}_\phi(\mathbf{x}_i) / \sum_{j=1}^N \hat{w}_\phi(\mathbf{x}_j)$.

2\. Flattening: add a power scaling parameter $\alpha > 0$, $\hat{w}_\phi(\mathbf{x}_i)^\alpha$.

3\. Clipping: specify a lower bound $\max(\hat{w}_\phi(\mathbf{x}_i), \beta)$.

为了从重要性重采样生成模型中采样，$\mathbf{x}\sim p_{\theta, \phi}(\mathbf{x}) \propto p_\theta(\mathbf{x})\hat{w}_\phi(\mathbf{x})$，他们采用了SIR（采样-重要性-重采样），

> To sample from an importance resampled generative model, $\mathbf{x}\sim p_{\theta, \phi}(\mathbf{x}) \propto p_\theta(\mathbf{x})\hat{w}_\phi(\mathbf{x})$, they adopt SIR (Sampling-Importance-Resampling),

![The algorithm for sampling from a generative model according to importance weights $\hat{w}(\mathbf{x}\_i)$ using SIR. (Image source: Grover et al., 2019) )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/SIR-importance-resampling.png)

[Deng 等人 (2020)](https://arxiv.org/abs/2004.11714) 提出学习一个 EBM 来引导 LM 在 [残差空间](https://arxiv.org/abs/1906.03351) 中，$P_\theta(x) \propto P_\text{LM}(x)\exp(-E_\theta(x))$，其中 $P_\theta$ 是联合模型；$E_\theta$ 是要学习的残差能量函数。如果我们知道配分函数 $Z$，我们可以将生成序列 $x_{p+1}, \dots, x_T$ 的生成模型建模为：

> [Deng et al., 2020](https://arxiv.org/abs/2004.11714) proposed to learn a EBM to steer a LM in the [residual space](https://arxiv.org/abs/1906.03351), $P_\theta(x) \propto P_\text{LM}(x)\exp(-E_\theta(x))$, where $P_\theta$ is the joint model; $E_\theta$ is the residual energy function to be learned. If we know the partition function $Z$, we can model the generative model for generative a sequence $x_{p+1}, \dots, x_T$ as:

$$
P_\theta(x_{p+1:T}\vert x_{1:p}) = \frac{P_\text{LM}(x_{p+1:T}\vert x_{1:p}) \exp(-E_\theta(x_{1:T}))}{Z_\theta(x_{1:p})}
$$

目标是学习能量函数 $E_\theta$ 的参数，使得联合模型 $P_\theta$ 更接近所需的数据分布。残差能量函数通过噪声对比估计 ([NCE](https://www.kdnuggets.com/2019/07/introduction-noise-contrastive-estimation.html)) 进行训练，其中 $P_\theta$ 被视为模型分布，$P_\text{LM}$ 被视为噪声分布：

> The goal is to learn the parameters of the energy function $E_\theta$ such that the joint model $P_\theta$ gets closer to the desired data distribution. The residual energy function is trained by noise contrastive estimation ([NCE](https://www.kdnuggets.com/2019/07/introduction-noise-contrastive-estimation.html)), considering $P_\theta$ as the model distribution and $P_\text{LM}$ as the noise distribution:

$$
\theta = \arg\max_{\theta} \mathbb{E}_{x^+ \sim P_\text{data}} \log\frac{1}{1+\exp(E_\theta(x^+))} + \mathbb{E}_{x^- \sim P_\text{LM}} \log\frac{1}{1+\exp(-E_\theta(x^-))}
$$

然而，配分函数在实践中是难以处理的。该论文提出了一种简单的方法，首先从原始 LM 中采样，然后根据能量函数对其进行重采样。不幸的是，这相当昂贵。

> However, the partition function is intractable in practice. The paper proposed a simple way to first sample from the original LM and then to resample from them according to the energy function. This is unfortunately quite expensive.

![Top k samples from the base LM are resampled according to the residual energy function. (Image source: Deng et al., 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/top-k-joint-sampling.png)

### 智能提示设计

> Smart Prompt Design

大型语言模型已被证明在许多自然语言处理任务上非常强大，即使仅通过 *提示* 而无需特定任务的微调 ([GPT2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2), [GPT3](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-3))。提示设计对下游任务的性能有很大影响，并且通常需要耗时的手动制作。例如，在“闭卷考试”中，通过智能提示设计，事实性问题可以获得很大的提升 ([Shin 等人 (2020)](https://arxiv.org/abs/2010.15980), [Jiang 等人 (2020)](https://arxiv.org/abs/1911.12543))。我预计将看到越来越多关于自动智能提示设计的文献。

> Large language models have been shown to be very powerful on many NLP tasks, even with only *prompting* and no task-specific fine-tuning ([GPT2](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-2), [GPT3](https://lilianweng.github.io/posts/2019-01-31-lm/#gpt-3). The prompt design has a big impact on the performance on downstream tasks and often requires time-consuming manual crafting. For example, factual questions can gain a big boost with smart prompt design in “closed-book exam” ([Shin et al., 2020](https://arxiv.org/abs/2010.15980), [Jiang et al., 2020)](https://arxiv.org/abs/1911.12543)). I’m expecting to see an increasing amount of literature on automatic smart prompt design.

#### 基于梯度的搜索

> Gradient-based Search

**AutoPrompt** ([Shin et al., 2020](https://arxiv.org/abs/2010.15980); [代码](http://ucinlp.github.io/autoprompt)) 是一种通过基于梯度的搜索自动为各种任务创建提示的方法。AutoPrompt 通过将原始任务输入 `x` 与一组触发词元 $x_\text{trig}$ 按照模板 `\lambda` 结合来构建提示。这些触发词元在所有输入中共享，因此 *普遍*有效。

英文原文：AutoPrompt ([Shin et al., 2020](https://arxiv.org/abs/2010.15980); [code](http://ucinlp.github.io/autoprompt)) is a method to automatically create prompts for various tasks via gradient-based search. AutoPrompt constructs a prompt by combining the original task inputs `x` with a collection of trigger tokens 

$x_\text{trig}$ according to a template `\lambda`. The trigger tokens are shared across all inputs and thus *universally* effective.

![The overview of AutoPrompt. The trigger tokens are retrieved to optimize for the target outputs across all inputs. (Image source: Shin et al., 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/autoprompt.png)

通用触发器标记是使用梯度引导搜索策略识别的，与[Wallace et al., 2019](https://arxiv.org/abs/1908.07125)中相同。该*通用*设置意味着触发器标记$x_\text{trig}$ 可以针对数据集中所有输入的 $\tilde{y}$ 目标输出进行优化：

> The universal trigger tokens are identified using a gradient-guided search strategy same as in [Wallace et al., 2019](https://arxiv.org/abs/1908.07125). The *universal* setting means that the trigger tokens $x_\text{trig}$ can optimize for the target output $\tilde{y}$ for all inputs from a dataset:

$$
x_\text{trig} = \arg\min_{x’_\text{trig}} \mathbb{E}_{x\sim\mathcal{X}} [\mathcal{L}(\tilde{y}, f(x’_\text{trig}; x))]
$$

搜索在嵌入空间中进行。每个触发词元 $e_{\text{trig}_i}$ 的嵌入首先被初始化为某个默认值，然后更新以最小化围绕当前词元嵌入的任务特定损失的一阶泰勒展开式：

> The search operates in the embedding space. The embedding of every trigger token  $e_{\text{trig}_i}$ is first initialized to some default value and then gets updated to minimize the first-order Taylor expansion of the task-specific loss around the current token embedding:

$$
e^{(t+1)}_\text{trig} = \arg\min_{e\in\mathcal{V}} [e - e^{(t)}_{\text{trig}_i}]^\top \nabla_{e^{(t)}_{\text{trig}_i}} \mathcal{L}
$$

其中$\mathcal{V}$指所有token的嵌入矩阵。$\nabla_{e^{(t)}_{\text{trig}_i}} \mathcal{L}$是迭代过程中一个批次上任务损失的平均梯度$t$。我们可以通过暴力搜索找到最优的$e$通过一个$\vert \mathcal{V} \vert d$维点积，这种方法成本低廉且可以并行计算。

> where $\mathcal{V}$ refers to the embedding matrix of all the tokens. $\nabla_{e^{(t)}_{\text{trig}_i}} \mathcal{L}$ is the average gradient of the task loss over a batch at iteration $t$. We can brute-force the optimal $e$ by a $\vert \mathcal{V} \vert d$ -dimensional dot product, which is cheap and can be computed in parallel.

![We search for trigger tokens by updating their embeddings with the gradient of the task loss per batch. (Image source: Wallace et al., 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/universal-adv-triggers.png)

上述令牌替换方法可以通过束搜索进行增强。在寻找最优令牌嵌入$e$时，我们可以选择前$k$个候选而不是单个候选，从左到右搜索并根据当前数据批次上的$\mathcal{L}$对每个束进行评分。

> The above token replacement method can be augmented with beam search. When looking for the optimal token embedding $e$, we can pick top-$k$ candidates instead of a single one, searching from left to right and score each beam by $\mathcal{L}$ on the current data batch.

![Example prompts discovered by AutoPrompt for different tasks. (Image source: Shin et al., 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/autoprompt-examples.png)

智能提示设计本质上产生高效的上下文，可以引导模型完成期望的输出。受此观察启发，[Li & Liang (2021)](https://arxiv.org/abs/2101.00190) 提出了 **Prefix-Tuning**，它在输入序列的开头（称为“前缀”）分配少量可训练参数来引导语言模型（LM），$[\text{PREFIX}; x; y]$。设 $\mathcal{P}_\text{idx}$ 为前缀索引集，$\text{dim}(h_i)$ 为嵌入大小。前缀参数 $P_\theta$ 的维度为 $\vert\mathcal{P}_\text{idx}\vert \times \text{dim}(h_i)$，并且隐藏状态的形式为：

英文原文：Smart prompt design essentially produces efficient context that can lead to desired completion. Motivated by this observation, [Li & Liang (2021)](https://arxiv.org/abs/2101.00190) proposed Prefix-Tuning which assigns a small number of trainable parameters at the beginning of an input sequence (named “prefix”) to steer a LM, 

$[\text{PREFIX}; x; y]$. Let 

$\mathcal{P}_\text{idx}$ be a set of prefix indices and 

$\text{dim}(h_i)$ be the embedding size. The prefix parameters 

$P_\theta$ has the dimension 

$\vert\mathcal{P}_\text{idx}\vert \times \text{dim}(h_i)$ and the hidden state takes the form:

$$
h_i = \begin{cases}
P_\theta[i,:], & \text{if }i \in \mathcal{P}_\text{idx}\\
\text{LM}_\phi(z_i, h_{<{i}}), & \text{otherwise}
\end{cases}
$$

请注意，只有 $P_\theta$ 是可训练的，而语言模型参数 $\phi$ 在训练期间是冻结的。

> Note that only $P_\theta$ is trainable and the LM parameters $\phi$ is frozen during training.

![Illustrations of fine-tuning versus prefix-tuning. (Image source: Li & Liang 2021 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/prefix-tuning.png)

前缀参数不与任何与真实词语相关的嵌入绑定，因此它们在引导上下文方面更具 *表达力*。直接优化 $P_\theta$ 不幸会导致性能不佳。为了降低高维度训练的难度，矩阵 $P_\theta$ 通过一个较小的矩阵 $P’_\theta \in \mathbb{R}^{\vert\mathcal{P}_\text{idx}\vert \times c}$ 和一个大型前馈网络 $\text{MLP}_\theta \in \mathbb{R}^{c\times \text{dim}(h_i)}$ 进行重新参数化。

> The prefix parameters do not tie to any embeddings associated with the real words and thus they are more *expressive* for steering the context. Direct optimizing $P_\theta$ unfortunately results in poor performance. To reduce the difficulty associated with high dimensionality training, the matrix $P_\theta$ is reparameterized by a smaller matrix $P’_\theta \in \mathbb{R}^{\vert\mathcal{P}_\text{idx}\vert \times c}$ and a large feed forward network $\text{MLP}_\theta \in \mathbb{R}^{c\times \text{dim}(h_i)}$.

性能随着前缀长度 $\vert\mathcal{P}_\text{idx}\vert$ 的增加而提高，直至达到某个值。这个值因任务而异。

> The performance increases with the prefix length $\vert\mathcal{P}_\text{idx}\vert$ up to some value. And this value varies with tasks.

![Task performance, summarization (left) and table-to-text (right), as a function of prefix length. (Image source: Li & Liang 2021 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/prefix-tuning-length.png)

他们的消融研究还有一些其他有趣的发现，包括：

> A few other interesting learnings from their ablation studies include:

• 仅调整嵌入层（不带前缀）的表达能力不足。

• 将可训练参数放置在 $x$ 和 $y$ 之间，$[x; \text{INFIX}; y]$，其性能略低于前缀调优，这可能是因为它只影响 $y$ 的上下文，而前缀则影响两者。

• $P_\theta$ 的随机初始化会导致性能低下且方差较大。相比之下，用真实词语的激活来初始化 $P_\theta$ 可以改善生成效果，即使这些词语与任务无关。

英文原文：

• Tuning only the embedding layer (without prefix) is not sufficiently expressive.

• Placing the trainable parameter between $x$ and $y$, $[x; \text{INFIX}; y]$, slightly underperforms prefix-tuning, likely because it only affects the context for $y$ while prefix affects both.

• Random initialization of $P_\theta$ leads to low performance with high variance. In contrast, initializing $P_\theta$ with activations of real words improves generation, even the words are irrelevant to the task.

微调模型能实现更好的任务性能，但在低数据量情况下可能会失败。AutoPrompt 和 Prefix-Tuning 都被发现在训练数据集较小（即 $10^2-10^3$ 样本）的情况下优于微调。作为微调的替代方案，提示设计或学习上下文嵌入要便宜得多。AutoPrompt 在情感分类任务中比手动提示显著提高了准确性，并取得了与线性探测相似的性能。对于 NLI 任务，AutoPrompt 获得了比线性探测更高的准确性。它也能够比手动提示更准确地检索事实。在低数据量情况下，Prefix-Tuning 在表格到文本生成和摘要任务上取得了与微调相当的性能。

> Fine-tuned models achieve better task performance but they can fail in the low data regime. Both AutoPrompt and Prefix-Tuning were found to outperform fine-tuning in the regime where the training dataset is small (i.e. $10^2-10^3$ samples). As an alternative to fine-tuning, prompt design or learning the context embedding is much cheaper. AutoPrompt improves the accuracy for sentiment classification a lot more than manual prompts and achieves similar performance as linear probing. For the NLI task, AutoPrompt obtains higher accuracy than linear probing. It is able to retrieve facts more accurately than manual prompts too. In low data regime, Prefix-Tuning achieves performance comparable with fine-tuning on table-to-text generation and summarization.

两项后续工作，**P-tuning** ([Liu et al. 2021](https://arxiv.org/abs/2103.10385); [code](https://github.com/THUDM/P-tuning)) 和 **Prompt Tuning** ([Lester et al. 2021](https://arxiv.org/abs/2104.08691))，都遵循了显式训练连续提示嵌入的相似思想，但在可训练参数和架构上有一些不同的选择。与 Prefix-Tuning 在 Transformer 的每个隐藏状态层中连接连续提示标记不同，P-tuning 和 Prompt Tuning 都以非侵入式方式*仅在输入中*添加连续提示以实现良好效果。

> Two successive works, **P-tuning** ([Liu et al. 2021](https://arxiv.org/abs/2103.10385); [code](https://github.com/THUDM/P-tuning)) and **Prompt Tuning** ([Lester et al. 2021](https://arxiv.org/abs/2104.08691)), follow the similar idea of explicit training continuous prompt embeddings but with a few different choices over the trainable parameters and architecture. Different from Prefix-Tuning which concatenates continuous prompt tokens in every hidden state layer of the transformer, both P-tuning and Prompt Tuning non-invasively add continuous prompts *only in the input* to work well.

设 $[P_i]$ 是 **P-tuning** ([Liu et al. 2021](https://arxiv.org/abs/2103.10385)) 提示模板中的第 `i` 个标记，我们可以将提示表示为序列 $T=\{[P_{0:i}], \mathbf{x}, [P_{i+1:m}], \mathbf{y}\}$。每个标记 $[P_i]$ 不必是模型词汇表中的真实标记（“伪标记”），因此编码后的模板 $T^e$ 如下所示，并且伪标记的隐藏状态可以通过梯度下降进行优化。

英文原文：Let 

$[P_i]$ be the `i` -th token in the prompt template of P-tuning ([Liu et al. 2021](https://arxiv.org/abs/2103.10385)), we can denote a prompt as a sequence 

$T=\{[P_{0:i}], \mathbf{x}, [P_{i+1:m}], \mathbf{y}\}$. Each token 

$[P_i]$ does not have to be a real token in the model vocabulary (“pseudo-token”), and thus the encoded template 

$T^e$ looks like the following and the pseudo-token hidden state can be optimized with gradient descent.

$$
T^e = \{ h_0, \dots, h_i, \text{embed}(\mathbf{x}), h_{i+1}, \dots, h_m, \text{embed}(\mathbf{y})\}
$$

![The illustration of P-tuning. Sometimes, adding a few task-related anchor tokens, such as “capital” in the figure, can bring further improvement. (Image source: Liu et al. 2021 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/p-tuning.png)

P-tuning 中存在两个主要的优化挑战：

> There are two major optimization challenges in P-tuning:

1\. 离散性：预训练语言模型的词嵌入是高度离散的。如果 $h_i$ 随机初始化，则很难对其进行优化。

2\. 关联性：$h_i$ 应该相互依赖。因此，他们开发了一种机制，通过训练一个轻量级的基于 LSTM 的提示编码器来建模这种依赖关系：

英文原文：

1\. Discreteness: The word embedding of a pretrained language model are highly discrete. It is hard to optimize $h_i$ if they are intialized at random.

2\. Association: $h_i$ should be dependent on each other. Thus they develop a mechanism to model this dependency by training a light-weighted LSTM-based prompt encoder:

$$
h_i = \text{MLP}([\text{LSTM}(h_{0:i}): \text{LSTM}(h_{i:m})])
$$

P-tuning 比 prefix-tuning 更灵活，因为它不仅在提示的开头，还可以在提示的中间插入可训练标记。使用任务特定的锚点标记就像将手动提示工程与可训练提示结合起来。

> P-tuning is more flexible than prefix-tuning, as it inserts trainable tokens in the middle of a prompt not just at the beginning. The usage of task-specific anchor tokens is like combining manual prompt engineering with trainable prompts.

**提示词微调** ([Lester et al. 2021](https://arxiv.org/abs/2104.08691)) 大大简化了前缀微调的思想，它只允许为每个下游任务额外添加 `k` 个可调的 token 预置到输入文本中。条件生成是 $p_{\theta, \theta_P}(Y \vert [P; X])$，其中 `P` 是“伪提示词”，其参数 `\theta_P` 可通过反向传播进行训练。`X` 和 `P` 都是嵌入向量，我们有 $X \in \mathbb{R}^{n \times d^e}, P \in \mathbb{R}^{k \times d^e}$ 和 $[P;X] \in \mathbb{R}^{(n+k) \times d^e}$，其中 $d^e$ 是嵌入空间维度。

英文原文：Prompt Tuning ([Lester et al. 2021](https://arxiv.org/abs/2104.08691)) largely simplifies the idea of prefix tuning by only allowing an additional `k` tunable tokens per downstream task to be prepended to the input text. The conditional generation is 

$p_{\theta, \theta_P}(Y \vert [P; X])$, where `P` is the “pseudo prompt” with parameters `\theta_P` trainable via back-propagation. Both `X` and `P` are embedding vectors and we have 

$X \in \mathbb{R}^{n \times d^e}, P \in \mathbb{R}^{k \times d^e}$ and 

$[P;X] \in \mathbb{R}^{(n+k) \times d^e}$, where 

$d^e$ is the embedding space dimensionality.

- 当模型变得 *庞大*（数十亿参数及以上）时，提示词微调能产生与模型微调相当的竞争性结果。考虑到大型模型在微调和推理时执行成本高昂，这一结果尤其引人注目。
- 通过学习任务特定的参数，提示词微调在适应新领域时实现了更好的迁移学习。它在领域迁移问题上优于微调。
- 他们还表明，针对同一任务对多个提示词进行集成可以带来进一步的改进。

> • Prompt tuning produces competitive results as model fine-tuning when the model gets *large* (billions of parameters and up). This result is especially interesting given that large models are expensive to fine-tune and execute at inference time.
> • With learned task-specific parameters, prompt tuning achieves better transfer learning when adapting to new domains. It outperforms fine-tuning on domain shift problems.
> • They also showed that prompt ensembling of multiple prompts for the same task introduces further improvement.

![The illustration of how Prompt Tuning works. (Image source: Lester et al. 2021 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/prompt-tuning.png)

实验研究了几种提示词初始化方案：

> The experiments investigated several prompt initialization schemes:

1. 通过在 [-0.5, 0.5] 范围内均匀采样进行随机初始化；
2. 采样前 5000 个常用 token 的嵌入；
3. 使用类别标签字符串的嵌入值。如果类别标签不足以初始化软提示词，则回退到方案 2。随机初始化的表现明显差于其他两种选项。

> • Random initialization by uniformly sampling from [-0.5, 0.5];
> • Sample embeddings of top 5000 common tokens;
> • Use the embedding values of the class label strings. If we don’t have enough class labels to initialize the soft-prompt, we fall back to scheme 2.
> Random initialization performs noticeably worse than the other two options.

![The effect of (a) different prompt initialization schemes and (b) different prompt lengths. (Image source: Lester et al. 2021 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/prompt-tuning-exp1.png)

预训练目标也对提示词微调的质量有很大影响。T5 的“span corruption”在这里不是一个好的选择。

> The pre-training objectives also have a big impact on the quality of prompt tuning. T5’s “span corruption” is not a good option here.

发现提示调优不太可能过度拟合特定数据集。为了评估对数据漂移问题的鲁棒性，他们在某个任务的一个数据集上训练模型，并在测试数据集上进行评估，但评估是在*不同领域*进行的。提示调优更具弹性，能够更好地泛化到不同领域。

> Prompt tuning is found to be less likely to overfit to a specific dataset. To evaluate the robustness to data shifting problem, they trained the model on one dataset of one task and evaluated it on the test dataset but in a *different domain*. Prompt tuning is more resilient and can generalize to different domains better.

![Prompt tuning is more resilient to domain shift between train and test sets. (Image source: Lester et al. 2021 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/prompt-tuning-exp2.png)

#### 基于启发式的搜索

> Heuristic-based Search

释义是探索与已知版本相似的更多提示的一种快速方法，这可以通过*回译*完成。使用回译，初始提示被翻译成另一种语言的$B$个候选，然后每个候选被翻译回原始语言的$B$个候选。由此产生的总共$B^2$个候选根据其往返概率进行评分和排名。

> Paraphrasing is a quick way to explore more prompts similar to the known version, which can be done via *back-translation*.  Using back-translation, the initial prompt is translated into $B$ candidates in another language and then each is translated back into $B$ candidates in the original language. The resulting total $B^2$ candidates are scored and ranked by their round-trip probabilities.

[Ribeiro 等人 (2018)](https://www.aclweb.org/anthology/P18-1079/) 通过生成各种释义 $\{x’\}$ 的输入 $x$，直到它触发目标函数 $f$ 的不同预测，从而识别出 *语义等效对抗样本 (SEA)*：

> [Ribeiro et al (2018)](https://www.aclweb.org/anthology/P18-1079/) identified *semantically equivalent adversaries (SEA)* by generating a variety of paraphrases $\{x’\}$ of input $x$ until it triggers a different prediction of target function $f$:

$$
\begin{aligned}
SEA(x, x') &= \mathbb{1}[\text{SemEq}(x, x') \land f(x) \neq f(x')] \\
\text{where SemEq}(x, x') &= \mathbb{1}[\min\Big(1, \frac{p(x'\vert x)}{p(x\vert x)} \Big) \geq \tau]
\end{aligned}
$$

其中分数 $p(x’\vert x)$ 与将 $x$ 翻译成多种语言再翻译回原始语言的比例成正比。

> where the score $p(x’\vert x)$ is proportional to translating $x$ into multiple languages and then translating it back to the original language.

SEA 规则的例子包括 (*What `NOUN`→Which `NOUN`*)、(*`WP` is → `WP`’s’*)、(*was→is*) 等。它们被认为是模型中的“错误”。在模型训练中将这些规则作为数据增强应用，有助于增强模型的鲁棒性并修复错误。

> Examples of SEA rules include (*What `NOUN`→Which `NOUN`*), (*`WP` is → `WP`’s’*), (*was→is*), etc. They are considered as “bugs” in the model. Applying those rules as data augmentation in model training helps robustify the model and fix bugs.

[Jiang 等人 (2020)](https://arxiv.org/abs/1911.12543) 试图通过自动发现更好的查询提示来验证训练过的语言模型是否知道某些知识。在知识检索的范围内，事实知识以三元组 $\langle x, r, y \rangle$（主语、关系、宾语）的形式表示。这些提示可以从训练句子（例如维基百科描述）中挖掘，或者通过释义进行扩展。

> [Jiang et al (2020)](https://arxiv.org/abs/1911.12543) attempts to validate whether a trained language model knows certain knowledge by automatically discovering better prompts to query. Within the scope of knowledge retrieval where factual knowledge is represented in the form of a triple $\langle x, r, y \rangle$ (subject, relation, object). The prompts can be mined from training sentences (e.g. Wikipedia description) or expanded by paraphrase.

有趣的是，提示中的一些小修改可能会带来巨大的收益，如图 X 所示。

> Interestingly some small modifications in the prompts may lead to big gain, as shown in Fig. X.

![Small modifications in prompt templates can lead to big performance gains: replacement in blue, insertion in green, deletion in red. (Image source: Jiang et al., 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/prompt-small-modifications.png)

### 微调

> Fine-tuning

微调是一种直观的方式，通过在监督数据集上训练或通过强化学习，引导语言模型输出期望的内容。我们可以微调模型中的所有权重，或者将微调限制在仅顶层或附加层。

> Fine-tuning is an intuitive way to guide a LM to output desired content, commonly by training on supervised datasets or by RL. We can fine-tune all the weights in the model or restrict the fine-tuning to only top or additional layers.

#### 条件训练

> Conditional Training

条件训练旨在学习一个以控制变量为条件的生成模型 $z$，$p(y \vert x, z)$。

> Conditional training aims to learn a generative model conditioned on a control variable $z$, $p(y \vert x, z)$.

[Fan 等人 (2018)](https://arxiv.org/abs/1805.04833) 训练了一个条件语言模型用于两步故事生成。首先，一个模型输出故事草图，然后一个故事写作模型根据该草图创作故事。以草图为条件的机制是通过一个 *融合* 模型架构实现的。融合模型强制执行一种 *残差学习* 形式，使故事写作模型能够专注于学习第一个草图生成模型所缺失的内容。同样在故事生成方面，[Peng 等人 (2018)](https://www.aclweb.org/anthology/W18-1505/) 实验了一种结局效价条件的故事生成器语言模型，$p(x_t \vert x_{<t}, z)$ 其中 $z$ 是故事结局的标签（悲伤、快乐或中性）。他们的语言模型是一个双向 LSTM，标签被映射到一个学习到的嵌入中，然后融入 LSTM 单元。

> [Fan et al (2018)](https://arxiv.org/abs/1805.04833) trained a conditional language model for 2-step story generation. First, a model outputs the story sketch and then a story writing model creates a story following that sketch. The mechanism of conditioning on the sketch is implemented by a *fusion* model architecture. The fusion model enforces a form of *residual learning* that allows the story writing model to focus on learning what the first sketch generation model is missing. Also for story generation, [Peng et al (2018)](https://www.aclweb.org/anthology/W18-1505/) experimented with an ending valence-conditioned story generator LM, $p(x_t \vert x_{<t}, z)$ where $z$ is the label of the story ending (sad, happy or neutral). Their language model is a bidirectional LSTM and the label is mapped into a learned embedding which then blends into the LSTM cell.

**CTRL** ([Keskar 等人，2019](https://arxiv.org/abs/1909.05858)；[代码](https://github.com/salesforce/ctrl)) 旨在训练一个使用可控数据集的条件控制代码语言模型 `z`。CTRL 通过在带有 *控制代码前缀* 的原始文本序列上进行训练来学习条件分布 $p(x \vert z)$，例如 `[horror]`、`[legal]` 等。然后，学习到的模型能够根据提示前缀生成文本。训练数据包含维基百科、OpenWebText、书籍、亚马逊评论、Reddit 语料库等等，其中每个数据集都被分配了一个控制代码，Reddit 语料库中的子版块也有其自己的主题作为控制代码。

英文原文：CTRL ([Keskar et al., 2019](https://arxiv.org/abs/1909.05858); [code](https://github.com/salesforce/ctrl)) aims to train a language model conditioned control code `z` using controllable datasets. CTRL learns the conditioned distribution 

$p(x \vert z)$ by training on raw text sequences with *control code prefixes*, such as `[horror]`, `[legal]`, etc. Then the learned model is able to generate text with respect to the prompt prefix. The training data contains Wikipedia, OpenWebText, books, Amazon reviews, reddit corpus and many more, where each dataset is assigned with a control code and subreddit in the reddit corpus has its own topic as control code.

![Datasets used for training CTRL and associated control codes. (Image source: Edited from Table 7 in Keskar et al., 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/CTRL-control-code.png)

给定令牌，控制代码也可以用于 *领域标注*，因为 $p(z \vert x) \propto p(x \vert z) p(z)$，假设领域上的先验是均匀的。CTRL 的一个局限性是缺乏对 *不生成什么* 的控制（例如，避免毒性内容）。

> The control code also can be used for *domain annotation* given tokens, because $p(z \vert x) \propto p(x \vert z) p(z)$, assuming the prior over domains is uniform. One limitation of CTRL is the lack of control for *what not to generate* (e.g. avoid toxicity).

![The examples of conditioned sample generation by CTRL. (Image source: Keskar et al., 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/CTRL-examples.png)

请注意，CTRL 从头开始训练一个 Transformer 模型。然而，用相同的控制代码标记同一数据集中所有文本（例如，所有维基百科文章都使用“wikipedia”作为控制代码）感觉相当受限。考虑到我们经常需要高度定制的控制代码，但只有有限的标注数据，我预计以与 CTRL 相同的方式，用少量标注数据集对无条件语言模型进行微调也能很好地工作。尽管需要多少数据以及样本质量如何，都还有待实验验证。

> Note that CTRL trains a transformer model from scratch. However, labelling all the text within the same dataset with the same control code (e.g. All the wikipedia articles have “wikipedia” as control code) feels quite constrained. Considering that often we need highly customized control codes but only have a limited amount of labelled data, I would expect fine-tuning an unconditional LM with a small labelled dataset in the same way as CTRL to work out well too. Although how much data is needed and how good the sample quality might be are subject to experimentation.

#### 强化学习微调

> RL Fine-tuning

多年前就已经证明，使用强化学习对序列模型进行微调，以任意且可能不可微分的奖励函数为目标，能够很好地工作 ([Ranzato 等人，2015](https://arxiv.org/abs/1511.06732))。强化学习微调可以解决 *教师强制* 方法的几个问题。在使用教师强制时，模型在训练期间仅在每个单独的解码步骤中最小化最大似然损失，但在测试时却被要求从头开始预测整个序列。这种训练和测试之间的差异可能导致暴露偏差和累积误差。相比之下，强化学习微调能够直接优化序列级别的任务特定指标，例如用于翻译的 BLEU ([Ranzato 等人，2015](https://arxiv.org/abs/1511.06732), [Wu 等人，2016](https://arxiv.org/abs/1609.08144), [Nguyen 等人，2017](https://arxiv.org/abs/1707.07402))，用于摘要的 ROUGE ([Ranzato 等人，2015](https://arxiv.org/abs/1511.06732), [Paulus 等人，2017](https://arxiv.org/abs/1705.04304), [Wu 和 Hu，2018](https://arxiv.org/abs/1804.07036)) 以及用于故事生成的定制指标 ([Tambwekar 等人，2018](https://arxiv.org/abs/1809.10736))。

> Fine-tuning a sequential model with RL regarding any arbitrary and possibly non-differentiable reward function has been proved to work well years ago ([Ranzato et al., 2015](https://arxiv.org/abs/1511.06732)). RL fine-tuning can resolve several problems with *teacher forcing* method. With teacher forcing, the model only minimizes a maximum-likelihood loss at each individual decoding step during training but it is asked to predict the entire sequence from scratch at test time. Such a discrepancy between train and test could lead to exposure bias and accumulated error. In contrast, RL fine-tuning is able to directly optimize task-specific metrics on the sequence level, such as BLEU for translation ([Ranzato et al., 2015](https://arxiv.org/abs/1511.06732), [Wu et al., 2016](https://arxiv.org/abs/1609.08144), [Nguyen et al., 2017](https://arxiv.org/abs/1707.07402)), ROUGE for summarization ([Ranzato et al., 2015](https://arxiv.org/abs/1511.06732), [Paulus et al., 2017](https://arxiv.org/abs/1705.04304), [Wu and Hu, 2018](https://arxiv.org/abs/1804.07036)) and customized metric for story generation ([Tambwekar et al., 2018](https://arxiv.org/abs/1809.10736)).

[Ranzato 等人 (2015)](https://arxiv.org/abs/1511.06732) 应用 REINFORCE 训练 RNN 模型用于序列生成任务。模型首先使用交叉熵损失（ML 损失）训练以预测下一个令牌，然后通过 ML 损失和 REINFORCE（RL 损失）交替进行微调。在第二个微调阶段，下一个令牌预测的训练步数逐渐减少直至为零，最终只使用 RL 损失。实验表明，这种序列级强化学习微调在当时比几种监督学习基线取得了显著的改进。

> [Ranzato et al (2015)](https://arxiv.org/abs/1511.06732) applied REINFORCE to train RNN models for sequence generation tasks. The model is first trained to predict the next token using cross-entropy loss (ML loss) and then fine-tuned alternatively by both ML loss and REINFORCE (RL loss). At the second fine-tuning stage, the number of training steps for next-token prediction is gradually decreasing until none and eventually only RL loss is used. This sequence-level RL fine-tuning was shown by experiments to lead to great improvements over several supervised learning baselines back then.

Google 在其神经机器翻译系统 ([Wu 等人，2016](https://arxiv.org/abs/1609.08144)) 中实现了类似的方法，[Paulus 等人 (2017)](https://arxiv.org/abs/1705.04304) 将这种方法应用于摘要任务。训练目标包含两部分：用于下一个 token 预测的 ML 损失，$\mathcal{L}_\text{ML} = \sum_{(x, y^{\ast})\sim\mathcal{D}} \log p_\theta(y^{\ast} \vert x)$，以及用于最大化预期奖励的 RL 损失 $\mathcal{L}_\text{RL}$，其中每个序列的奖励通过 BLEU 或 ROUGE 衡量。模型首先使用 $\mathcal{L}_\text{ML}$ 进行训练直到收敛，然后使用两种损失的线性组合 $\mathcal{L}_\text{mix} = \alpha \mathcal{L}_\text{ML} + (1 - \alpha)\mathcal{L}_\text{RL}$ 进行微调。

> Google implemented the similar approach in their neural machine translation system ([Wu et al., 2016](https://arxiv.org/abs/1609.08144)) and [Paulus et al (2017)](https://arxiv.org/abs/1705.04304) adopted such approach for summarization task. The training objective contains two parts, ML loss for next token prediction, $\mathcal{L}_\text{ML} = \sum_{(x, y^{\ast})\sim\mathcal{D}} \log p_\theta(y^{\ast} \vert x)$, and RL loss $\mathcal{L}_\text{RL}$ for maximizing the expected reward where the reward per sequence is measured by BLEU or ROUGE. The model is first trained with $\mathcal{L}_\text{ML}$ until convergence and then fine-tuned with a linear combination of two losses, $\mathcal{L}_\text{mix} = \alpha \mathcal{L}_\text{ML} + (1 - \alpha)\mathcal{L}_\text{RL}$.

Google NMT 的 RL 损失旨在最大化预期的 BLEU 分数：

> The RL loss of Google NMT is to maximize the expected BLEU score:

$$
\mathcal{L}_\text{RL} = - \sum_{(x, y^*)\sim\mathcal{D}} \mathbb{E}_{y\sim p_\theta(.\vert x)} [R(y, y^*)]
$$

其中 $y$ 是预测序列，$y^{\ast}$ 是真实值。

> where $y$ is the predicted sequence and $y^{\ast}$ is the ground truth.

[Paulus 等人 (2017)](https://arxiv.org/abs/1705.04304) 添加了一个额外的加权项，该项基于两个输出序列之间的奖励差异，$y$ 通过根据预测概率采样下一个 token，$\hat{y}$ 通过贪婪地选择最可能的 token。这种强化学习损失最大化了采样序列的条件似然，$y$ 如果它获得了比贪婪基线更高的奖励 $\hat{y}$:

> [Paulus et al (2017)](https://arxiv.org/abs/1705.04304) added an extra weighting term based on the reward difference between two output sequences, $y$ by sampling the next token according to the predicted probability and $\hat{y}$ by greedily taking the most likely token. This RL loss maximizes the conditional likelihood of the sampled sequence $y$ if it obtains a higher reward than the greedy baseline $\hat{y}$:

$$
\mathcal{L}_\text{RL} = \sum_{(x, y^*)\sim\mathcal{D}} (R(\hat{y}, y^*) - R(y, y^*)) \sum_{t=1}^{n'} \log p(y_t \vert y_{<{t}}, x)
$$

#### 基于人类偏好的强化学习微调

> RL Fine-tuning with Human Preferences

奖励学习对于定义人类偏好至关重要。像BLEU或ROUGE这样的定量测量计算序列之间单词和n-gram短语的重叠，但并不总是与人类评判的更高质量相关。从人类反馈中学习奖励（[Christiano et al., 2017](https://arxiv.org/abs/1706.03741)）是使我们所测量的与我们实际关心的保持一致的更好方法。人类反馈已被应用于学习奖励函数，用于故事生成（[Yi et al., 2019](https://arxiv.org/abs/1904.13015)）和摘要（[Böhm et al., 2019](https://arxiv.org/abs/1909.01214), [Ziegler et al., 2019](https://arxiv.org/abs/1909.08593), [Stiennon et al., 2020](https://arxiv.org/abs/2009.01325)）等应用。

> Reward learning is critical for defining human preferences. Quantitative measurement like BLEU or ROUGE computes the overlap of words and n-gram phrases between sequences and does not always correlate with better quality by human judges. Reward learning from human feedback ([Christiano et al., 2017](https://arxiv.org/abs/1706.03741)) is a better way to align what we measure with what we actually care about. Human feedback has been applied to learn a reward function for applications like story generation ([Yi et al., 2019](https://arxiv.org/abs/1904.13015)) and summarization ([Böhm et al., 2019](https://arxiv.org/abs/1909.01214), [Ziegler et al., 2019](https://arxiv.org/abs/1909.08593), [Stiennon et al., 2020](https://arxiv.org/abs/2009.01325)).

为了生成更连贯的对话，[Yi et al (2019)](https://arxiv.org/abs/1904.13015) 针对对话对（用户话语，系统响应）收集了4种二元人类反馈，即系统响应是否（1）全面，（2）切题，（3）有趣，以及（4）能引导对话继续。训练一个评估器来预测人类反馈，然后将其用于重新排序束搜索样本、微调模型或两者兼而有之。（实际上，他们没有使用RL微调，而是使用评估器在监督微调中提供判别器损失。）

> In order to generate more coherent conversation, [Yi et al (2019)](https://arxiv.org/abs/1904.13015) collected 4 types of binary human feedback given a conversation pair (user utterance, system response), whether the system response is (1) comprehensive, (2) on topic, (3) interesting and (4) leading to continuation of the conversation.
> An evaluator is trained to predict human feedback and then is used to rerank the beam search samples, to finetune the model or to do both. (Actually they didn’t use RL fine-tuning but rather use the evaluator to provide a discriminator loss in supervised fine-tuning.)

我们来定义一个学习到的奖励函数$R_\psi(x, y)$，其参数为$\psi$，作为衡量输出质量的指标$y$，给定输入$x$。

> Let’s define a learned reward function $R_\psi(x, y)$ parameterized by $\psi$ as a measurement for the quality of output $y$ given the input $x$.

为了学习由人类判断定义的真实奖励$R^{\ast}$，[Böhm et al (2019)](https://arxiv.org/abs/1909.01214)比较了两种损失函数：

> To learn the ground truth reward $R^{\ast}$ defined by human judgements, [Böhm et al (2019)](https://arxiv.org/abs/1909.01214) compared two loss functions:

(1) 回归损失：简单地最小化均方误差。

> (1) Regression loss: simply minimizing the mean squared error.

$$
\mathcal{L}^\text{MSE}_\text{rm} = [R^*(x, y) - R_\psi(x, y)]^2
$$

(2) 偏好损失：学习与真实奖励保持一致，

> (2) Preference loss: learning to agree with the ground truth reward,

$$
\begin{aligned}
\mathcal{L}^\text{pref}_\text{rm} =& - \sum_{i,j} \big(\mathbb{1}[R^*(x, y_i) > R^*(x, y_j)] \log P(y_i \succ y_j) + \\
&\mathbb{1}[R^*(x, y_j) > R^*(x, y_i)] \log P(y_j \succ y_i) \big)\\ 
\text{where }P(y_i \succ y_j) =& \frac{\exp(R_\psi(x, y_i))}{\exp(R_\psi(x, y_i)) + \exp(R_\psi(x, y_j))}
\end{aligned}
$$

他们的实验表明，*偏好损失*实现了最佳性能，其中奖励模型是BERT句子嵌入之上的一个薄MLP层。

> Their experiments showed that the *preference loss* achieves the best performance, where the reward model is a thin MLP layer on top of BERT sentence embedding.

[Ziegler 等人 (2019)](https://arxiv.org/abs/1909.08593) 通过要求人类从几个选项中选择最佳候选者 $y_b$ $\{y_i\}$，给定输入 $x \sim \mathcal{D}$ 来收集人类标签。候选者由 $y_0, y_1 \sim p(.\vert x), y_2, y_3 \sim \pi(.\vert x)$ 采样。我们应该意识到，当真实情况模糊时，人工标注可能会有很高的分歧。

> [Ziegler et al (2019)](https://arxiv.org/abs/1909.08593) collected human labels by asking humans to select the best candidate $y_b$ out of a few options $\{y_i\}$ given the input $x \sim \mathcal{D}$. The candidates are sampled by $y_0, y_1 \sim p(.\vert x), y_2, y_3 \sim \pi(.\vert x)$. We should be aware that human labeling might have very high disagreement when the ground truth is fuzzy.

![The overview of the training framework for fine-tuning a language model policy with reward learned from human feedback. (Image source: Ziegler et al., 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/finetune-human-feedback.png)

奖励模型由一个预训练语言模型实现，该模型在最终嵌入输出上带有一个额外的随机线性层。它被训练以最小化损失：

> The reward model is implemented by a pretrained language model with an extra random linear layer of the final embedding output. It it trained to minimize the loss:

$$
\mathcal{L}_\text{rm} = -\mathbb{E}_{(x, \{y_i\}, b) \sim \mathcal{D}} \Big[ \log \frac{\exp(R_\psi(x, y_b))}{\sum_i \exp(R_\psi(x, y_i))} \Big]
$$

为了在训练期间保持尺度一致，奖励模型被归一化，使其均值为0，方差为1。

> To keep the scale consistent during training, the reward model is normalized to have mean 0 and variance 1.

在RL微调期间，策略`\pi`，由预训练语言模型`p`初始化，通过[PPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo)和上述学习到的奖励模型进行优化。为了避免策略偏离其原始行为过多，添加了一个**KL惩罚**：

英文原文：During RL fine-tuning, the policy `\pi`, initialized by a pretrained language model `p`, is optimized via [PPO](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#ppo) with the above learned reward model. To avoid the policy’s deviating from its original behavior too much, a KL penalty is added:

$$
R(x, y) = R_\psi(x, y) - \beta\log\frac{\pi(y \vert x)}{p(y \vert x)}
$$

如果进行在线数据收集，在RL微调期间会继续进行人工标签收集过程，因此人工标注者可以审查由最新策略生成的结果。人工标签的数量在训练过程中均匀分布。同时，奖励模型也会定期重新训练。在线数据收集对于摘要任务很重要，但对于文本续写任务则不然。在他们的实验中，联合训练奖励模型和具有共享参数的策略效果不佳，并且由于数据集大小之间的巨大不平衡可能导致过拟合。

> If running online data collection, human label collection process is continued during RL fine-tuning and thus the human labelers can review results generated by the latest policy. The number of human labels are evenly spread out during the training process. Meanwhile the reward model is also retrained periodically. Online data collection turns out to be important for the summarization task but not for the text continuation task. In their experiments, jointly training the reward model and the policy with shared parameters did not work well and can lead to overfitting due to the big imbalance between dataset sizes.

在后续工作中（[Stiennon et al., 2020](https://arxiv.org/abs/2009.01325)），人工标签收集被进一步简化为在一对摘要中选择最佳选项，$y_b \in\{y_0, y_1\}$ 奖励模型损失被更新以优化所选摘要的对数几率：

> In the following work ([Stiennon et al., 2020](https://arxiv.org/abs/2009.01325)), the human label collection was further simplified to select the best option between a pair of summaries, $y_b \in\{y_0, y_1\}$ The reward model loss was updated to optimize the log odds of the selected summary:

$$
\mathcal{L}_\text{rm} = - \mathbb{E}_{(x, y_0, y_1, b)\sim\mathcal{D}} [\log(\sigma(r_\theta(x, y_b) − r_\theta(x, y_{1−b})))]
$$

![The overview of fine-tuning the language model policy from human feedback for summarization, including (1) human feedback collection, (2) reward model training, and (3) policy training. (Image source: Stiennon et al., 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/summarize-human-feedback.png)

#### 带可控层的引导式微调

> Guided Fine-tuning with Steerable Layer

与微调整个模型不同，只微调一小组额外的参数同时保持基础模型不变，在计算上更经济。

> Instead of fine-tuning the entire model, only fine-tuning a small extra set of parameters while the base model stays fixed is computationally cheaper.

在计算机视觉领域，即插即用生成网络（PPGN；[Nguyen et al., 2017](https://arxiv.org/abs/1612.00005)）通过将鉴别器 $p(a \vert x)$ 插入基础生成模型 $p(x)$ 来生成具有不同属性的图像。然后，具有所需属性 `a` 的样本可以从 $p(x \vert a) \propto p(a \vert x)p(x)$ 中采样。受PPGN启发，**即插即用语言模型**（**PPLM**；[Dathathri et al., 2019](https://arxiv.org/abs/1912.02164)）将一个或多个简单属性模型与预训练语言模型结合，用于可控文本生成。

英文原文：In computer vision, plug-and-play generative networks (PPGN; [Nguyen et al., 2017](https://arxiv.org/abs/1612.00005)) generate images with different attributes by plugging a discriminator 

$p(a \vert x)$ into a base generative model 

$p(x)$. Then the sample with a desired attribute `a` can be sampled from 

$p(x \vert a) \propto p(a \vert x)p(x)$. Inspired by PPGN, the plug-and-play language model (PPLM; [Dathathri et al., 2019](https://arxiv.org/abs/1912.02164)) combines one or multiple simple attribute models with a pretrained language model for controllable text generation.

给定属性 $a$ 和生成的样本 $x$，令属性模型为 $p(a\vert x)$。为了控制内容生成，时间 $t$ 的当前潜在表示 $H_t$（包含每层的键值对列表）可以通过 $\Delta H_t$ 沿两个梯度之和的方向进行偏移：

> Given an attribute $a$ and the generated sample $x$, let an attribute model be $p(a\vert x)$. To control content generation, the current latent representation at time $t$, $H_t$ (containing a list of key-value pairs per layer), can be shifted by $\Delta H_t$  in the direction of the sum of two gradients:

• 一个方向是使属性 $a$ 在 $p(a \vert x)$ 下的对数似然更高 — 从而使输出内容获得所需的属性。

• 另一个趋向于未修改语言模型更高的对数似然 $p(x)$ —— 以便生成的文本仍然是流畅自然的语言。

英文原文：

• One toward higher log-likelihood of the attribute $a$ under $p(a \vert x)$ — so that the output content acquires a desired attribute.

• The other toward higher log-likelihood of the unmodified language model $p(x)$ — so that the generated text is still in fluent and smooth natural language.

为了在解码时调整输出，PPLM 总共运行三次：一次前向 → 一次后向 → 一次前向：

> To shift the output, at decoding time, PPLM runs one forward → one backward → one forward, three passes in total:

1\. 首先，执行一次前向传播，以计算属性 $a$ 的似然，通过 $p(a\vert x)$；

2\. 令 $\Delta H_t$ 是对隐藏状态 $H_t$ 的逐步更新，使得 $(H_t + \Delta H_t)$ 将生成文本的分布推向更接近具有属性 $a$。$\Delta H_t$ 初始化为零。
然后，反向传播使用来自属性模型 $\nabla_{\Delta H_t} \log p(a \vert H_t + \Delta H_t)$ 的归一化梯度更新 LM 隐藏状态，如下所示

英文原文：

1\. First a forward pass is performed to compute the likelihood of attribute $a$ by $p(a\vert x)$;

2\. Let $\Delta H_t$ be a stepwise update to the hidden state $H_t$ such that $(H_t + \Delta H_t)$ shifts the distribution of generated text closer to having the attribute $a$. $\Delta H_t$ is initialized at zero.
Then a backward pass updates the LM hidden states using normalized gradients from the attribute model $\nabla_{\Delta H_t} \log p(a \vert H_t + \Delta H_t)$ as

$$
\Delta H_t \leftarrow \Delta H_t + \alpha \frac{\nabla_{\Delta H_t} \log p(a|H_t + \Delta H_t)}{\| \nabla_{\Delta H_t} \log p(a|H_t + \Delta H_t) \|^\gamma}
$$

其中 $\gamma$ 是一个归一化缩放系数，按层设置。$\alpha$ 是步长。此更新可以重复 $m \in [3, 10]$ 次
3. 最终的前向传播会重新计算词汇表上的新分布，该分布由更新后的潜在变量 $\tilde{H}_t = H_t + \Delta H_t$ 生成。下一个 token 从更新后的分布中采样。

> where $\gamma$ is a normalization scaling coefficient, set per layer. $\alpha$ is step size. This update can be repeated $m \in [3, 10]$ times
> 3. The final forward pass recomputes a new distribution over the vocabulary, generated from the updated latents $\tilde{H}_t = H_t + \Delta H_t$. The next token is sampled from the updated distribution.

![The overview of how PPLM runs three passes to update the model output to increase the likelihood of a desired attribute. (Image source: Dathathri et al., 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/PPLM.png)

多个属性模型可以在生成过程中通过自定义权重进行混合搭配，充当一组“控制旋钮”。PPLM 论文探讨了两种类型的属性模型：

> Multiple attribute models can be mix-and-matched during generation with customized weights, acting as a set of “control knobs”. The PPLM paper explored two types of attribute models:

1\. 最简单的归因模型基于预定义的*词袋*（BoW），$\{w_1, \dots, w_k\}$，它指定了一个感兴趣的主题。  


英文原文：

1\. The simplest attribution model is based on a predefined *bag of words* (BoW), $\{w_1, \dots, w_k\}$, that specifies a topic of interest.  


$$
\log p(a \vert x) = \log\big( \sum_{i=1}^k p_{t+1} [w_i] \big)
$$

  
为了鼓励模型至少输出一次所需词语，而不是在每一步都输出，他们通过最大梯度范数来归一化梯度。
  
有趣的是，他们发现增加生成词袋中词语的概率也增加了生成*相关*但并非完全相同的关于同一主题的词语的概率。
2. 判别器属性模型基于学习到的分类器，这些分类器通过分布而不是硬样本来定义偏好。

>
> To encourage the model to output the desired words at least once but not at every step, they normalize the gradient by the maximum gradient norm.
>
> Interestingly, they found that increasing the probability of generating words in the bag also increases the probability of generating *related* but not identical words about the same topic.
> 2. The discriminator attribute models are based on learned classifiers which define preferences by a distribution instead of hard samples.

为了确保语言的流畅性，PPLM 应用了两种额外的设计：

> To ensure the fluency in language, PPLM applied two additional designs:

1\. 最小化修改后和未修改的语言模型之间的KL散度，这在其他强化学习微调方法中很常见（参见[上文](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#kl-penalty)）。

2\. 它执行[后范数融合](https://arxiv.org/abs/1809.00125)，以将生成的文本持续绑定到无条件语言模型$p(x)$，$x_{t+1} \sim \frac{1}{\beta}(\tilde{p}_{t+1}^{\gamma_\text{gm}} p_{t+1}^{1-\gamma_\text{gm}})$，其中$p_{t+1}$和$\tilde{p}_{t+1}$分别是未修改和修改后的输出分布。$\beta$是一个归一化因子。$\gamma_\text{gm} \in [0.8, 0.95]$平衡了模型修改前后之间的预测。

英文原文：

1\. Minimizing the KL diverge between modified and unmodified LM, commonly seen in other RL fine-tuning approaches (see [above](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#kl-penalty)).

2\. It performs [post-norm fusion](https://arxiv.org/abs/1809.00125) to constantly tie the generated text to the unconditional LM $p(x)$, $x_{t+1} \sim \frac{1}{\beta}(\tilde{p}_{t+1}^{\gamma_\text{gm}} p_{t+1}^{1-\gamma_\text{gm}})$, where $p_{t+1}$ and $\tilde{p}_{t+1}$ are the unmodified and modified output distributions, respectively. $\beta$ is a normalizing factor. $\gamma_\text{gm} \in [0.8, 0.95]$ balances between prediction from before and after models.

![Examples of controllable text generation by PPLM. (Image source: Dathathri et al., 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/PPLM-examples.png)

有趣的是，他们发现不同主题的可控程度存在很大差异。与某些主题（计算机、空间）相比，另一些主题（宗教、科学、政治）更容易控制。

> Interestingly, they found a large variance in the extent of controllability across topics. Some topics (religion, science, politics) are easier to control for compared to others (computers, space).

PPLM的一个明显缺点是，由于在每个解码步骤中需要多次传递，测试时间的计算成本变得高得多。

> One obvious drawback of PPLM is that due to multiple passes at every decoding step, the test time computation becomes much more expensive.

与PPLM类似，**DELOREAN**（DEcoding for nonmonotonic LOgical REAsoNing; [Qin et al., 2020](https://arxiv.org/abs/2010.05906)）通过反向传播整合未来上下文。给定输入文本$\mathbf{x}$，DELOREAN旨在生成续写完成$\mathbf{y} = [y_1, \dots, y_N]$，使得`y`满足由上下文`z`定义的某些约束。为了保持生成的可微分性，会跟踪`y`的软表示，即$\tilde{\mathbf{y}}=(\tilde{y}_1, \dots, \tilde{y}_N)$，其中$\tilde{y}_i \in \mathbb{R}^V$是词汇表上的logits。$\tilde{\mathbf{y}}^{(t)}$是迭代`t`时的软表示。

英文原文：Similar to PPLM, DELOREAN (DEcoding for nonmonotonic LOgical REAsoNing; [Qin et al., 2020](https://arxiv.org/abs/2010.05906)) incorporates the future context by back-propagation. Given input text 

$\mathbf{x}$, DELOREAN aims to generate continuation completion 

$\mathbf{y} = [y_1, \dots, y_N]$ such that `y` satisfies certain constraints defined by a context `z`. To keep the generation differentiable, a soft representation of `y` is tracked, 

$\tilde{\mathbf{y}}=(\tilde{y}_1, \dots, \tilde{y}_N)$ where 

$\tilde{y}_i \in \mathbb{R}^V$ are logits over the vocabulary. 

$\tilde{\mathbf{y}}^{(t)}$ is the soft representation at iteration `t`.

给定表示 $\tilde{y}^{(t-1)}$ 在迭代 $t$ 时，它运行以下过程：

> Given the representation $\tilde{y}^{(t-1)}$ at iteration $t$, it runs the following procedures:

1\. **反向**：约束表示为损失函数 $\mathcal{L}(\mathbf{x}, \tilde{\mathbf{y}}^{(t-1)}, z))$。Logits 通过梯度下降更新：$\tilde{y}^{(t), b}_n = \tilde{y}_n^{(t-1)} - \lambda \nabla_{\tilde{y}_n} \mathcal{L}(\mathbf{x}, \tilde{\mathbf{y}}^{(t-1)}, z)$。

2\. **正向**：运行正向传播以确保生成的文本流畅。$\tilde{y}^{(t),f}_n = \text{LM}(\mathbf{x}, \tilde{\mathbf{y}}^{(t)}_{1:n-1})$。

3\. 然后将两个 logits 线性组合在一起，创建一个新的表示 $\tilde{y}^{(t)}_n = \gamma \tilde{y}^{(t), f}_n + (1-\gamma) \tilde{y}^{(t), b}_n$。请注意，每个 $\tilde{y}^{(t)}_n$ 都需要用于采样下一个 $\tilde{y}^{(t),f}_{n+1}$。

英文原文：

1\. **Backward**: The constraint is represented as a loss function $\mathcal{L}(\mathbf{x}, \tilde{\mathbf{y}}^{(t-1)}, z))$. The logits are updated via gradient descent: $\tilde{y}^{(t), b}_n = \tilde{y}_n^{(t-1)} - \lambda \nabla_{\tilde{y}_n} \mathcal{L}(\mathbf{x}, \tilde{\mathbf{y}}^{(t-1)}, z)$.

2\. **Forward**: Run forward pass to ensure the generated text is fluent. $\tilde{y}^{(t),f}_n = \text{LM}(\mathbf{x}, \tilde{\mathbf{y}}^{(t)}_{1:n-1})$.

3\. Then linearly combine two logits together to create a new representation $\tilde{y}^{(t)}_n = \gamma \tilde{y}^{(t), f}_n + (1-\gamma) \tilde{y}^{(t), b}_n$. Note that each $\tilde{y}^{(t)}_n$ is needed to sample the next $\tilde{y}^{(t),f}_{n+1}$.

**Side-tuning** ([Zhang et al., 2019](https://arxiv.org/abs/1912.13503)) 训练一个轻量级的辅助网络，该网络在原始模型输出的基础上学习一个残差，而无需修改预训练模型的权重。与 PPLM 不同，隐藏状态上不应用梯度更新。这是一种简单而有效的增量学习方法。基础模型被视为一个黑盒模型，不一定非得是神经网络。Side-tuning 设置假设基础模型和辅助模型输入完全相同，并且辅助模型是独立学习的。

> **Side-tuning** ([Zhang et al., 2019](https://arxiv.org/abs/1912.13503)) trains a light-weighted side network that learns a residual on top of the original model outputs without modifying the pre-trained model weights. Unlike PPLM, no gradient update is applied on the hidden states. It is a simple yet effective approach for incremental learning. The base model is treated as a black-box model and does not necessarily have to be a neural network. Side-tuning setup assumes the base and side models are fed exactly the same input and the side model is independently learned.

![Comparison of fixed weights, fine-tuning and side-tuning. (Image source: Zhang et al., 2019 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/side-tuning.png)

该论文探讨了融合基础模型和辅助模型预测的不同策略：`product` 是最差的，而 `sum` ($\alpha$ -blending)、MLP 和 [FiLM](https://arxiv.org/abs/1709.07871) 是可比的。当使用中等量数据进行训练且基础网络较大时，Side-tuning 能够取得更好的性能。

> The paper explored different strategies of fusing predictions from the base and side models: `product` is the worst while `sum` ($\alpha$ -blending), MLP, and [FiLM](https://arxiv.org/abs/1709.07871) are comparable. Side-tuning is able to achieve better performance, when it is trained with intermediate amounts of data and when the base network is large.

**辅助调优** ([Zeldes et al., 2020](https://arxiv.org/abs/2006.16823)) 通过一个*辅助*模型来补充原始预训练模型，该模型根据目标任务调整输出分布。基础模型和辅助模型的输出在 logits 层面进行合并。组合模型经过训练，旨在最大化目标输出的似然 $p(x_t\vert x_{<t}, z)$。

英文原文：Auxiliary tuning ([Zeldes et al., 2020](https://arxiv.org/abs/2006.16823)) supplements the original pre-trained model with an *auxiliary* model that shifts the output distribution according to the target task. The base and auxiliary model outputs are merged on the logits level. The combined model is trained to maximize the likelihood 

$p(x_t\vert x_{<t}, z)$ of target output.

$p(x_t\vert x_{<t}, z)$ 的条件概率可以分解为两部分：

> The conditional probability of $p(x_t\vert x_{<t}, z)$ can be decomposed into two parts:

1\. $p(x_t\vert x_{<t})$ 为流畅的 token 序列分配高概率；

2\. $p(x_t\vert x_{<t})$ 向 $p(x_t\vert x_{<t}, z)$ 的偏移。

英文原文：

1\. $p(x_t\vert x_{<t})$ assigns high probabilities to fluent sequences of tokens;

2\. a shift on $p(x_t\vert x_{<t})$ towards $p(x_t\vert x_{<t}, z)$.

$$
p(x_t\vert x_{<{t}}, z) = \text{softmax}(\text{logits}_\text{LM}(x_t \vert x_{<{t}}) + \text{logits}_\text{aux}(x_t \vert x_{<{t}}, z))
$$

根据贝叶斯法则，我们有

> By Bayesian rule, we have

$$
p(x_t\vert x_{<{t}}, z)
= \frac{p(z \vert x_{\leq t})}{p(z)} p(x_t \vert x_{<{t}}) 
\propto p(z \vert x_{\leq t}) p(x_t \vert x_{<{t}})
$$

因此，辅助模型 $\text{logits}_\text{aux}(x_t \vert x_{<t}, z))$ 应该有效地学习预测 $p(z \vert x_{\leq t})$。在 [Zeldes et al., 2020](https://arxiv.org/abs/2006.16823) 的实验中，辅助模型可以重用预训练语言模型的中间层进行特征提取。

> And therefore the auxiliary model $\text{logits}_\text{aux}(x_t \vert x_{<t}, z))$ effectively should learn to predict $p(z \vert x_{\leq t})$. In the experiments of [Zeldes et al., 2020](https://arxiv.org/abs/2006.16823), the auxiliary model can re-use the intermediate layers of the pre-trained LM for feature extraction.

![The auxiliary model is trained by reusing features extracted from multiple layers of the base model. (Image source: Zeldes et al., 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/side-auxiliary.png)

**GeDi** ([Kruse et al., 2020](https://arxiv.org/abs/2009.06367)) 通过*生成式判别器*引导文本生成。该判别器被实现为一个类别条件语言模型 (CC-LM)，$p_\theta(x_{1:t} \vert z)$。判别器通过贝叶斯法则，对*两个*对比的类别条件分布进行归一化，计算所有可能的下一个 token 的分类概率，从而在每个解码步骤引导生成：

英文原文：GeDi ([Kruse et al., 2020](https://arxiv.org/abs/2009.06367)) guides the text generation by *Generative Discriminator*. The discriminator is implemented as a class conditional language model (CC-LM), 

$p_\theta(x_{1:t} \vert z)$. The discriminator guides generation at each decoding step by computing classification probabilities for all possible next tokens via Bayes rule by normalizing over *two* contrastive class-conditional distributions:

1\. 一个以控制码 $z$ 为条件，用于所需属性。

2\. 另一个以反控制码 $\bar{z}$ 为条件，用于不需要的属性。

英文原文：

1\. One conditioned on the control code $z$ for desired attribute.

2\. The other conditioned on the anti-control code $\bar{z}$ for undesired attributes.

GeDi 依赖于 $p_\theta(x_{1:t} \vert z)$ 和 $p_\theta(x_{1:t} \vert \bar{z})$ 之间的约定来计算序列属于所需类别的概率。判别器损失旨在最大化所需属性 $z$ 的概率：

> GeDi relies on the contract between $p_\theta(x_{1:t} \vert z)$ and $p_\theta(x_{1:t} \vert \bar{z})$ to compute the probability of the sequence belonging to the desired class. The discriminator loss is to maximize the probability of desired attribute $z$:

$$
\begin{aligned}
p_\theta(z \vert x_{1:t}) &= \frac{p(z) p_\theta(x_{1:\tau} \vert z)^{\alpha/\tau}}{\sum_{z' \in \{z, \bar{z}\}} p(z') p_\theta(x_{1:\tau} \vert z')^{\alpha/\tau} } \\
\mathcal{L}_\text{desc} 
&= -\frac{1}{N} \sum_{i=1}^N \log p_\theta(z^{(i)} \vert x^{(i)}_{1:\tau_i}) \\
&= -\frac{1}{N} \sum_{i=1}^N \log \frac{p(z) p_\theta(x^{(i)}_{1:\tau_i} \vert z^{(i)})^{\alpha/t_i}}{\sum_{z' \in \{z, \bar{z}\} } p(z')p_\theta(x^{(i)}_{1:\tau_i} \vert z')^{\alpha/\tau_i}}
\end{aligned}
$$

其中 $p(z) = \exp(b_z) / \sum_{z’} \exp(b_{z’})$ 和 $b_z$ 是学习到的类别先验。概率通过当前序列长度 $\tau$ 进行归一化，以增强可变长度生成序列的鲁棒性。$\tau_i$ 是数据集中第 $i$ 个输入 $x^{(i)}$ 的序列长度。

> where $p(z) = \exp(b_z) / \sum_{z’} \exp(b_{z’})$ and $b_z$ is a learned class prior. The probabilities are normalized by the current sequence length $\tau$ to robustify generation sequences of variable lengths. $\tau_i$ is the sequence length of the $i$ -th input $x^{(i)}$ in the dataset.

![An illustration of how GeDi works via Bayesian rule. (Image source: Kruse et al., 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/GeDi.png)

他们使用与训练 [CTRL](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#ctrl) 类似的方式，通过控制代码对 GPT2-medium 模型进行微调，并结合判别损失和生成损失的线性组合来形成一个 CC-LM。然后，这个判别器模型被用作 GiDe，以指导像 GPT2-XL 这样更大的语言模型进行生成。

> They finetuned a GPT2-medium model with control code similar to how [CTRL](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#ctrl) is trained to form a CC-LM using a linear combination of discriminative loss and generative loss. This discriminator model is then used as GiDe to guide generation by a larger language model like GPT2-XL.

从 GeDi 解码的一种方法是从加权后验 $p^w(x_{t+1}\vert x_{1:t}, z) \propto p(z \vert x_{1:t+1})^w p(x_{t+1} \vert x_{1:t})$ 中采样，其中 $w>1$ 对所需类别 $z$ 施加了额外的偏差。在采样过程中，只选择类别或下一个词元概率大于某个阈值的词元。

> One way of decoding from GeDi is to sample from a weighted posterior $p^w(x_{t+1}\vert x_{1:t}, z) \propto p(z \vert x_{1:t+1})^w p(x_{t+1} \vert x_{1:t})$ where $w>1$ applies additional bias toward the desired class $z$. In the sampling process, only tokens with the class or next-token probability larger than a certain threshold are selected.

在他们的实验中，GeDi 指导的生成显示出强大的可控性，并且运行速度比 [PPLM](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#pplm) 快 30 倍。

> GeDi guided generation in their experiments showed strong controllability and ran 30x faster than [PPLM](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#pplm).

#### 分布方法

> Distributional Approach

**基于分布控制的生成** (GDC; [Khalifa, et al. 2020](https://arxiv.org/abs/2012.11635)) 将受控文本生成视为带约束的概率分布优化。它包括两个主要步骤。

> **Generation with Distributional Control** (GDC; [Khalifa, et al. 2020](https://arxiv.org/abs/2012.11635)) frames controlled text generation as the optimization of a probability distribution with a constraint. It involves two major steps.

**步骤 1：学习目标模型的 EBM**

> **Step 1: Learn a EBM of the target model**

让我们将预训练的语言模型标记为$a$并将具有所需特征的目标语言模型标记为$p$。所需特征可以通过一组预定义的实值特征函数来定义$\phi_i(x), i=1,\dots,k$作用于$x \in X$，表示为一个向量$\boldsymbol{\phi}$。当序列$x \in X$根据期望模型进行采样时$p$，特征的期望值$\mathbb{E}_{x\sim p}\boldsymbol{\phi}(x)$应该接近$\bar{\boldsymbol{\mu}}$，称为“*矩约束*”。特征函数$\phi_i$可以具有不同的值（例如，二元分类器的恒等函数）或连续概率。同时，微调后的模型$p$不应偏离$a$太远，应保持较小的KL散度。

> Let’s label a pretrained LM as $a$ and a target LM with desired features as $p$. The desired features can be defined by a set of pre-defined real-valued feature functions $\phi_i(x), i=1,\dots,k$ over $x \in X$, denoted as a vector $\boldsymbol{\phi}$. When sequences $x \in X$ are sampled according to the desired model $p$, the expectations of features $\mathbb{E}_{x\sim p}\boldsymbol{\phi}(x)$ should be close to $\bar{\boldsymbol{\mu}}$ , named “*moment constraints*”. The feature function $\phi_i$ can have distinct values (e.g. identity function for binary classifier) or continuous probabilities. In the meantime, the fine-tuned model $p$ should not diverge from $a$ too much by maintaining a small KL divergence measure.

总而言之，给定一个预训练模型 $a$，我们希望找到一个目标模型 $p$，使得：

> In summary, given a pretrained model $a$, we would like to find a target model $p$ such that:

$$
\begin{aligned}
\bar{\boldsymbol{\mu}} &= \mathbb{E}_{x\sim p}\boldsymbol{\phi}(x) \\
p &= \arg\min_{c \in \mathcal{C}} D_\text{KL}(c, a)
\end{aligned}
$$

其中 $\mathcal{C}$ 是 $X$ 上满足矩约束的所有分布的集合。

> where $\mathcal{C}$ is the set of all distributions over $X$ that satisfy the moment constraints.

根据信息几何中的定理，$p$ 可以通过EBM（基于能量的模型；一种未归一化的概率分布）$P$ 以指数函数的形式近似，使得$p(x) \propto P(x)$ 和 $p(x)=\frac{1}{Z}P(x)$ 其中 $Z=\sum_x P(x)$。基于能量的模型可以通过以下方式近似：

> According to theorems in Information Geometry, $p$ can be approximated by an EBM (energy-based model; an unnormalized probability distribution) $P$ in the form of exponential function, such that $p(x) \propto P(x)$ and $p(x)=\frac{1}{Z}P(x)$ where $Z=\sum_x P(x)$. The energy-based model can be approximated by:

$$
P(x)=a(x)\exp\big(\sum_i \lambda_i \phi_i(x)\big)=a(x)\exp(\boldsymbol{\lambda}\cdot\boldsymbol{\phi}(x))
$$

我们定义 *重要性权重* $w(x, \boldsymbol{\lambda}) = \frac{P(x)}{a(x)} = \exp\langle\boldsymbol{\lambda}\cdot\boldsymbol{\phi}(x)\rangle$。给定从预训练模型 $x_1, \dots, x_N \sim a(x)$ 中采样的D大量序列，

> Let’s define *importance weight* $w(x, \boldsymbol{\lambda}) = \frac{P(x)}{a(x)} = \exp\langle\boldsymbol{\lambda}\cdot\boldsymbol{\phi}(x)\rangle$. Given a large number of sequences sampled from the pretrained model $x_1, \dots, x_N \sim a(x)$,

$$
\begin{aligned}
\mu(\boldsymbol{\lambda}) 
&= \mathbb{E}_{x\sim p}\boldsymbol{\phi}(x)
= \mathbb{E}_{x\sim a} \frac{p(x)}{a(x)}\boldsymbol{\phi}(x)
= \frac{1}{Z}\mathbb{E}_{x\sim a} w(x, \boldsymbol{\lambda}) \boldsymbol{\phi}(x) \\
&= \frac{\mathbb{E}_{x\sim a} w(x, \boldsymbol{\lambda}) \boldsymbol{\phi}(x)}{\sum_{x\in X} P(x)}
= \frac{\mathbb{E}_{x\sim a} w(x, \boldsymbol{\lambda}) \boldsymbol{\phi}(x)}{\sum_{x\in X} w(x, \boldsymbol{\lambda})a(x)}
= \frac{\mathbb{E}_{x\sim a} w(x, \boldsymbol{\lambda}) \boldsymbol{\phi}(x)}{\mathbb{E}_{x\sim a} w(x, \boldsymbol{\lambda})} \\
&\simeq \frac{\sum_{i=1}^N w(x_i,\boldsymbol{\lambda}) \boldsymbol{\phi}(x_i)}{\sum_{i=1}^N w(x_i, \boldsymbol{\lambda})}
= \frac{\sum_{i=1}^N \exp\langle\boldsymbol{\lambda}\cdot\boldsymbol{\phi}(x)\rangle \boldsymbol{\phi}(x_i)}{\sum_{i=1}^N \exp\langle\boldsymbol{\lambda}\cdot\boldsymbol{\phi}(x)\rangle}
\end{aligned}
$$

对目标 $|\boldsymbol{\mu}(\boldsymbol{\lambda}) - \bar{\boldsymbol{\mu}}|^2_2$ 使用SGD，我们可以获得 $\boldsymbol{\lambda}$ 的估计值和 $P(x)=a(x)\exp\langle\boldsymbol{\lambda}\cdot\boldsymbol{\phi}(x)\rangle$ 的表示。$P(x)$ 是一个序列EBM，因为 $a$ 是一个自回归模型。

> Using SGD over the objective $|\boldsymbol{\mu}(\boldsymbol{\lambda}) - \bar{\boldsymbol{\mu}}|^2_2$, we can obtain an estimated value for $\boldsymbol{\lambda}$ and a representation of $P(x)=a(x)\exp\langle\boldsymbol{\lambda}\cdot\boldsymbol{\phi}(x)\rangle$. $P(x)$ is a sequential EBM because $a$ is an autoregressive model.

**步骤 2: 学习目标概率分布**

> **Step 2: Learn the target probability distribution**

EBM$P(x)$能够计算两个序列的概率比，但无法从$p(x)$在已知的情况下进行采样。$Z$为了从序列EBM中采样，该论文提出使用[Distributional Policy Gradient](https://arxiv.org/abs/1912.08517)（DPG；但不是这个[DPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg)）其目标是获得一个自回归策略$\pi_\theta$以近似目标分布$p$通过最小化交叉熵$H(p, \pi_\theta)$DPG 运行一系列迭代。在每次迭代中，所提出的分布$q$用于采样，我们也可以用重要性权重来修正交叉熵损失：

> The EBM $P(x)$ can compute ratios of probabilities of two sequences, but cannot sample from $p(x)$ with knowing $Z$. In order to sample from a sequential EBM, the paper proposed to use [Distributional Policy Gradient](https://arxiv.org/abs/1912.08517) (DPG; but not this [DPG](https://lilianweng.github.io/posts/2018-04-08-policy-gradient/#dpg)) with the objective to obtain an autoregressive policy $\pi_\theta$ to approximate a target distribution $p$ by minimizing the cross entropy $H(p, \pi_\theta)$. DPG runs through a sequence of iterations. Within each iteration, the proposed distribution $q$ is used for sampling and we can correct the cross entropy loss with importance weights too:

$$
\begin{aligned}
\nabla_\theta H(p, \pi_\theta) 
&= - \nabla_\theta \mathbb{E}_{x\sim p} \log \pi_\theta(x)
= - \mathbb{E}_{x\sim p} \nabla_\theta  \log \pi_\theta(x) \\
&= - \mathbb{E}_{x\sim q} \frac{p(x)}{q(x)} \nabla_\theta  \log \pi_\theta(x)
= - \frac{1}{Z}\mathbb{E}_{x\sim q} \frac{P(x)}{q(x)} \nabla_\theta  \log \pi_\theta(x)
\end{aligned}
$$

为了学习这样一种$\pi_\theta$，本文采用KL自适应版本的DPG：它只更新$q$当估计策略$\pi_\theta$接近$p$。这种自适应步骤对于快速收敛很重要。

> To learn such a $\pi_\theta$, the paper adopts a KL-adaptive version of DPG: It only updates $q$ when the estimated policy $\pi_\theta$ gets closer to $p$. This adaptive step is important for fast convergence.

![The algorithm of distributional policy gradient to make it possible to sample from a EBM $P(x)$, where $q$ is initialized to be $a$. (Image source: Khalifa, et al. 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/GDC-KL-adaptive-DPG.png)

这种方法可用于在可控文本生成中建模各种约束：

> This approach can be used to model various constraints in controllable text generation:

1\. 逐点约束：$\phi_i$ 是一个二元特征；例如约束词语的存在或缺失，或基于分类器的约束。

2\. 分布约束：$\phi_i$ 代表一个概率分布；例如约束性别、主题等的概率。他们的实验表明，在对一个在维基百科传记语料库上训练的 GPT-2 模型进行去偏方面取得了巨大进展。生成的女性传记的百分比从 7.4% 增加到 35.6%。

3\. 混合约束：通过简单地将它们相加来组合多个约束。

英文原文：

1\. Pointwise constraints: $\phi_i$ is a binary feature; such as constraining the presence or absence of words, or classifier-based constraints.

2\. Distributional constraints: $\phi_i$ represents a probability distribution; such as constraining the probability of gender, topic, etc. Their experiments showed great progress in debiasing a GPT-2 model that was trained on Wikipedia Biographies corpus. The percentage of generated biographies on females increased from 7.4% to 35.6%.

3\. Hybrid constraints: combine multiple constraints by simply summing them up.

![Debiasing experiments using GDC with various constraints. (Image source: Khalifa, et al. 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/GDC-debiasing.png)

与其他基线相比，使用逐点约束的 GDC 与基础模型偏离较小 $a$ 并生成更平滑的曲线。

> Compared to other baselines, GDC using pointwise constraints diverges less from the base model $a$ and produces smoother curves.

![Compare pointwise constrained GDC with several baselines. Low Self-BLEU-5 and high Dist-1 indicate high diversity. (Image source: Khalifa, et al. 2020 )](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/GDC-ablation.png)

• 直接优化奖励 $\phi$ 的 REINFORCE （图 X 中的 $\text{REINFORCE}$）在没有约束的情况下收敛速度快，但与原始模型存在较大偏差。

• 优化$P(x)$（图X中的$\text{REINFORCE}_{P(x)}$）的REINFORCE，其样本多样性较低。

• 与[Ziegler et al., 2019](https://arxiv.org/abs/1909.08593)相比，GDC具有更平滑的学习曲线并产生更丰富的词汇。

英文原文：

• REINFORCE that optimizes the reward $\phi$ directly ($\text{REINFORCE}$ in Fig. X.) without constraints converges fast but has a high deviation from the original model.

• REINFORCE that optimizes $P(x)$ ($\text{REINFORCE}_{P(x)}$ in Fig. X.) has low sample diversity.

• Compared to [Ziegler et al., 2019](https://arxiv.org/abs/1909.08593) GDC has smoother learning curves and produces a richer vocabulary.

#### 非似然训练

> Unlikelihood Training

在语言模型训练中，最大化对数似然损失的标准方法会导致[不正确的词元分布](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#beam-search-surprise)，这无法仅通过智能解码方法来修复。此类模型倾向于过于频繁地输出高频词，而过于罕见地输出低频词，尤其是在使用确定性解码（例如贪婪搜索、束搜索）时。换句话说，它们对其预测过于自信。

> The standard way of maximizing the log-likelihood loss in language model training leads to [incorrect token distribution](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#beam-search-surprise), which cannot be fixed with only smart decoding methods. Such models tend to output high-frequency words too often and low-frequency words too rarely, especially when using deterministic decoding (e.g. greedy, beam search). In other words, they are overconfident in their predictions.

不可能性训练 ([Welleck & Kulikov et al. 2019](https://arxiv.org/abs/1908.04319)] 试图解决这个问题，并将对*不希望的*内容偏好直接纳入训练目标。它结合了两种更新：

> Unlikelihood training ([Welleck & Kulikov et al. 2019](https://arxiv.org/abs/1908.04319)] tries to combat this and incorporates preference to *unwanted* content into the training objective directly. It combines two updates:

- 一个常规的最大似然更新，以高概率分配真实标记；
- 一种新型的非似然更新，以高概率避免不需要的标记。

> • A routine maximized likelihood update to assign true tokens with high probability;
> • A new type of unlikelihood update to avoid unwanted tokens with high probability.

给定一个 token 序列 $(x_1, \dots, x_T)$ 和一个负候选 token 集合 $\mathcal{C}^t = \{c_1, \dots , c_m\}$ 在步骤 $t$，其中每个 token $x_i, c_j \in \mathcal{V}$，步骤 $t$ 的组合损失定义为：

> Given a sequence of tokens $(x_1, \dots, x_T)$ and a set of negative candidate tokens $\mathcal{C}^t = \{c_1, \dots , c_m\}$ at step $t$, where each token $x_i, c_j \in \mathcal{V}$, the combined loss for step $t$ is defined as:

$$
\mathcal{L}^t_\text{UL}(p_\theta (. \vert x_{<{t}}), \mathcal{C}^t)
= - \alpha \cdot \underbrace{\sum_{c \in \mathcal{C}^t} \log(1 - p_\theta(c \vert x_{<{t}}))}_\text{unlikelihood} - \underbrace{\log p_\theta (x_t \vert x_{<{t}})}_\text{likelihood}
$$

构建$\mathcal{C}^t$的一种方法是从模型生成的序列中随机选择候选。

> One approach for constructing $\mathcal{C}^t$ is to randomly select candidates from model-generated sequences.

非似然训练可以扩展到*序列*级别，其中负向延续由一系列每步负向候选集定义。它们应该被设计成惩罚我们不喜欢的属性。例如，我们可以按如下方式惩罚重复的 n-gram：

> The unlikelihood training can be extended to be on the *sequence*-level, where the negative continuation is defined by a sequence of per-step negative candidate sets. They should be designed to penalize properties that we don’t like. For example, we can penalize repeating n-grams as follows:

$$
\mathcal{C}^t_\text{repeat-n} = \{x_t\} \text{ if }(x_{t-i}, \dots, x_{t+j}) \in x_{<{t-i}} \text{ for any } (j-i)=n, i\leq n \leq j.
$$

他们的实验使用非似然训练来避免语言模型输出中的重复，与标准MLE训练相比，确实在减少重复和增加独特token方面显示出更好的结果。

> Their experiments used unlikelihood training to avoid repetitions in language model outputs and indeed showed better results on less repetition and more unique tokens compared to standard MLE training.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2021年1月). 可控神经文本生成. Lil’Log. https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/.

> Weng, Lilian. (Jan 2021). Controllable neural text generation. Lil’Log. https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/.

或

> Or

```
@article{weng2021conditional,
  title   = "Controllable Neural Text Generation.",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2021",
  month   = "Jan",
  url     = "https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/"
}
```

### 参考文献

> References

[1] Patrick von Platen. [“如何生成文本：使用不同的解码方法进行基于 Transformer 的语言生成”](https://huggingface.co/blog/how-to-generate) Hugging face 博客，2020 年 3 月 18 日。

> [1] Patrick von Platen. [“How to generate text: using different decoding methods for language generation with Transformers”](https://huggingface.co/blog/how-to-generate) Hugging face blog, March 18, 2020.

[2] Angela Fan 等人。 [“分层神经故事生成”](https://arxiv.org/abs/1805.04833) arXiv 预印本 arXiv:1805.04833 (2018)。

> [2] Angela Fan, et al. [“Hierarchical Neural Story Generation/”](https://arxiv.org/abs/1805.04833) arXiv preprint arXiv:1805.04833 (2018).

[3] Ari Holtzman 等人。 [“神经文本退化的奇特案例。”](https://arxiv.org/abs/1904.09751) ICLR 2020。

> [3] Ari Holtzman et al. [“The Curious Case of Neural Text Degeneration.”](https://arxiv.org/abs/1904.09751) ICLR 2020.

[4] Marjan Ghazvininejad 等人。 [“Hafez：一个交互式诗歌生成系统。”](https://www.aclweb.org/anthology/P17-4008) ACL 2017。

> [4] Marjan Ghazvininejad et al. [“Hafez: an interactive poetry generation system.”](https://www.aclweb.org/anthology/P17-4008) ACL 2017.

[5] Ari Holtzman 等人。 [“学习使用协作判别器进行写作。”](https://arxiv.org/abs/1805.06087) ACL 2018。

> [5] Ari Holtzman et al. [“Learning to write with cooperative discriminators.”](https://arxiv.org/abs/1805.06087) ACL 2018.

[6] Ashutosh Baheti 等人。 [“在具有分布约束的神经对话模型中生成更有趣的响应。”](https://arxiv.org/abs/1809.01215) EMNLP 2018。

> [6] Ashutosh Baheti et al. [“Generating More Interesting Responses in Neural Conversation Models with Distributional Constraints.”](https://arxiv.org/abs/1809.01215) EMNLP 2018.

[7] Jiatao Gu 等人。 [“用于神经机器翻译的可训练贪婪解码。”](https://arxiv.org/abs/1702.02429) EMNLP 2017。

> [7] Jiatao Gu et al. [“Trainable greedy decoding for neural machine translation.”](https://arxiv.org/abs/1702.02429) EMNLP 2017.

[8] Kyunghyun Cho. [“用于条件循环语言模型的噪声并行近似解码。”](https://arxiv.org/abs/1605.03835) arXiv 预印本 arXiv:1605.03835. (2016)。

> [8] Kyunghyun Cho. [“Noisy Parallel Approximate Decoding for Conditional Recurrent Language Model.”](https://arxiv.org/abs/1605.03835) arXiv preprint arXiv:1605.03835. (2016).

[9] Marco Tulio Ribeiro 等人。 [“用于调试 NLP 模型的语义等效对抗规则。”](https://www.aclweb.org/anthology/P18-1079/) ACL 2018。

> [9] Marco Tulio Ribeiro et al. [“Semantically equivalent adversarial rules for debugging NLP models.”](https://www.aclweb.org/anthology/P18-1079/) ACL 2018.

[10] Eric Wallace 等人。 [“用于攻击和分析 NLP 的通用对抗性触发器。”](https://arxiv.org/abs/1908.07125) EMNLP 2019. [[代码](https://github.com/Eric-Wallace/universal-triggers)]

> [10] Eric Wallace et al. [“Universal Adversarial Triggers for Attacking and Analyzing NLP.”](https://arxiv.org/abs/1908.07125) EMNLP 2019. [[code](https://github.com/Eric-Wallace/universal-triggers)]

[11] Taylor Shin 等人。 [“AutoPrompt：通过自动生成的提示从语言模型中获取知识。”](https://arxiv.org/abs/2010.15980) EMNLP 2020. [[代码](http://ucinlp.github.io/autoprompt)]

> [11] Taylor Shin et al. [“AutoPrompt: Eliciting Knowledge from Language Models with Automatically Generated Prompts.”](https://arxiv.org/abs/2010.15980) EMNLP 2020. [[code](http://ucinlp.github.io/autoprompt)]

[12] Zhengbao Jiang 等人。 [“我们如何知道语言模型知道什么？”](https://arxiv.org/abs/1911.12543) TACL 2020。

> [12] Zhengbao Jiang et al. [“How Can We Know What Language Models Know?”](https://arxiv.org/abs/1911.12543) TACL 2020.

[13] Nanyun Peng 等人。 [“迈向可控的故事生成。”](https://www.aclweb.org/anthology/W18-1505/) NAACL 2018。

> [13] Nanyun Peng et al. [“Towards Controllable Story Generation.”](https://www.aclweb.org/anthology/W18-1505/) NAACL 2018.

[14] Nitish Shirish Keskar 等人。[“CTRL：一种用于可控生成的条件Transformer语言模型”](https://arxiv.org/abs/1909.05858) arXiv 预印本 arXiv:1909.05858 (2019)。[[代码](https://github.com/salesforce/ctrl)]

> [14] Nitish Shirish Keskar, et al. [“CTRL: A Conditional Transformer Language Model for Controllable Generation”](https://arxiv.org/abs/1909.05858) arXiv preprint arXiv:1909.05858 (2019).[[code](https://github.com/salesforce/ctrl)]

[15] Marc’Aurelio Ranzato 等人。[“使用循环神经网络进行序列级训练。”](https://arxiv.org/abs/1511.06732) ICLR 2016。

> [15] Marc’Aurelio Ranzato et al. [“Sequence Level Training with Recurrent Neural Networks.”](https://arxiv.org/abs/1511.06732) ICLR 2016.

[16] Yonghui Wu 等人。[“谷歌的神经机器翻译系统：弥合人机翻译之间的鸿沟。”](https://arxiv.org/abs/1609.08144) CoRR 2016。

> [16] Yonghui Wu et al. [“Google’s Neural Machine Translation System: Bridging the Gap between Human and Machine Translation.”](https://arxiv.org/abs/1609.08144) CoRR 2016.

[17] Romain Paulus 等人。[“一种用于抽象摘要的深度强化模型。”](https://arxiv.org/abs/1705.04304) ICLR 2018。

> [17] Romain Paulus et al. [“A Deep Reinforced Model for Abstractive Summarization.”](https://arxiv.org/abs/1705.04304) ICLR 2018.

[18] Paul Christiano 等人。[“从人类偏好中进行深度强化学习。”](https://arxiv.org/abs/1706.03741) NIPS 2017。

> [18] Paul Christiano et al. [“Deep Reinforcement Learning from Human Preferences.”](https://arxiv.org/abs/1706.03741) NIPS 2017.

[19] Sanghyun Yi 等人。[“使用自动对话评估器生成连贯且引人入胜的口语对话响应。”](https://arxiv.org/abs/1904.13015) INLG 2019。

> [19] Sanghyun Yi et al. [“Towards coherent and engaging spoken dialog response generation using automatic conversation evaluators.”](https://arxiv.org/abs/1904.13015) INLG 2019.

[20] Florian Böhm 等人。[“更好的奖励带来更好的摘要：学习在没有参考的情况下进行摘要。”](https://arxiv.org/abs/1909.01214) EMNLP 2019。 [[代码](https://github.com/yg211/summary-reward-no-reference)]

> [20] Florian Böhm et al. [“Better rewards yield better summaries: Learning to summarise without references.”](https://arxiv.org/abs/1909.01214) EMNLP 2019. [[code](https://github.com/yg211/summary-reward-no-reference)]

[21] Daniel M Ziegler 等人。[“根据人类偏好微调语言模型。”](https://arxiv.org/abs/1909.08593) arXiv 预印本 arXiv:1909.08593 (2019)。 [[代码](https://github.com/openai/lm-human-preferences)]

> [21] Daniel M Ziegler et al. [“Fine-tuning language models from human preferences.”](https://arxiv.org/abs/1909.08593) arXiv preprint arXiv:1909.08593 (2019). [[code](https://github.com/openai/lm-human-preferences)]

[22] Nisan Stiennon 等人。[“从人类反馈中学习摘要。”](https://arxiv.org/abs/2009.01325) arXiv 预印本 arXiv:2009.01325 (2020)。

> [22] Nisan Stiennon, et al. [“Learning to summarize from human feedback.”](https://arxiv.org/abs/2009.01325) arXiv preprint arXiv:2009.01325 (2020).

[23] Sumanth Dathathri 等人。[“即插即用语言模型：一种受控文本生成的简单方法。”](https://arxiv.org/abs/1912.02164) ICLR 2020。 [[代码](https://github.com/uber-research/PPLM)]

> [23] Sumanth Dathathri et al. [“Plug and play language models: a simple approach to controlled text generation.”](https://arxiv.org/abs/1912.02164) ICLR 2020. [[code](https://github.com/uber-research/PPLM)]

[24] Jeffrey O Zhang 等人。[“侧调：通过附加侧网络进行网络适应”](https://arxiv.org/abs/1912.13503) ECCV 2020。

> [24] Jeffrey O Zhang et al. [“Side-tuning: Network adaptation via additive side networks”](https://arxiv.org/abs/1912.13503) ECCV 2020.

[25] Ben Kruse 等人。[“GeDi：生成式判别器引导的序列生成。”](https://arxiv.org/abs/2009.06367) arXiv 预印本 arXiv:2009.06367。

> [25] Ben Kruse et al. [“GeDi: Generative Discriminator Guided Sequence Generation.”](https://arxiv.org/abs/2009.06367) arXiv preprint arXiv:2009.06367.

[26] Yoel Zeldes 等人。[“技术报告：辅助调优及其在条件文本生成中的应用。”](https://arxiv.org/abs/2006.16823) arXiv 预印本 arXiv:2006.16823。

> [26] Yoel Zeldes et al. [“Technical Report: Auxiliary Tuning and its Application to Conditional Text Generatio.”](https://arxiv.org/abs/2006.16823) arXiv preprint arXiv:2006.16823.

[27] Thomas Scialom 等人。[“用于抽象摘要的判别性对抗搜索”](https://arxiv.org/abs/2002.10375) ICML 2020。

> [27] Thomas Scialom, et al. [“Discriminative Adversarial Search for Abstractive Summarization”](https://arxiv.org/abs/2002.10375) ICML 2020.

[28] Clara Meister 等人。[“如果束搜索是答案，那么问题是什么？”](https://arxiv.org/abs/2010.02650) EMNLP 2020。

> [28] Clara Meister, et al. [“If beam search is the answer, what was the question?”](https://arxiv.org/abs/2010.02650) EMNLP 2020.

[29] Xiang Lisa Li 和 Percy Liang。[“前缀调优：优化连续提示以进行生成。”](https://arxiv.org/abs/2101.00190) arXiv 预印本 arXiv:2101.00190 (2021)。

> [29] Xiang Lisa Li and Percy Liang. [“Prefix-Tuning: Optimizing Continuous Prompts for Generation.”](https://arxiv.org/abs/2101.00190) arXiv preprint arXiv:2101.00190 (2021).

[30] Lianhui Qin 等人。[“回到未来：基于无监督反向传播的解码，用于反事实和溯因常识推理。”](https://arxiv.org/abs/2010.05906) arXiv 预印本 arXiv:2010.05906 (2020)。

> [30] Lianhui Qin, et al. [“Back to the Future: Unsupervised Backprop-based Decoding for Counterfactual and Abductive Commonsense Reasoning.”](https://arxiv.org/abs/2010.05906) arXiv preprint arXiv:2010.05906 (2020).

[31] Muhammad Khalifa 等人。[“一种受控文本生成的分布方法”](https://arxiv.org/abs/2012.11635) 被 ICLR 2021 接受。

> [31] Muhammad Khalifa, et al. [“A Distributional Approach to Controlled Text Generation”](https://arxiv.org/abs/2012.11635) Accepted by ICLR 2021.

[32] Aditya Grover 等人。[“使用无似然重要性加权对学习到的生成模型进行偏差校正。”](https://arxiv.org/abs/1906.09531) NeuriPS 2019。

> [32] Aditya Grover, et al. [“Bias correction of learned generative models using likelihood-free importance weighting.”](https://arxiv.org/abs/1906.09531) NeuriPS 2019.

[33] Yuntian Deng 等人。[“用于文本生成的残差能量模型。”](https://arxiv.org/abs/2004.11714) ICLR 2020。

> [33] Yuntian Deng et al. [“Residual Energy-Based Models for Text Generation.”](https://arxiv.org/abs/2004.11714) ICLR 2020.

[34] Brian Lester 等人。[“规模化在参数高效提示调优中的力量。”](https://arxiv.org/abs/2104.08691) arXiv 预印本 arXiv:2104.08691 (2021)。

> [34] Brian Lester et al. [“The Power of Scale for Parameter-Efficient Prompt Tuning.”](https://arxiv.org/abs/2104.08691) arXiv preprint arXiv:2104.08691 (2021).

[35] Xiao Liu 等人。[“GPT 也懂。”](https://arxiv.org/abs/2103.10385) arXiv 预印本 arXiv:2103.10385 (2021)。

> [35] Xiao Liu et al. [“GPT Understands, Too.”](https://arxiv.org/abs/2103.10385) arXiv preprint arXiv:2103.10385 (2021).

[36] Welleck 和 Kulikov 等人。[“使用非似然训练的神经文本生成”](https://arxiv.org/abs/1908.04319) arXiv:1908.04319 (2019)。

> [36] Welleck & Kulikov et al. [“Neural Text Generation with Unlikelihood Training”](https://arxiv.org/abs/1908.04319) arXiv:1908.04319 (2019).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Language Model (LM) | 语言模型 | 一种学习词元序列分布并预测下一个词元的模型。 |
| Token | 词元 | 文本中的基本单位，可以是单词、子词或字符。 |
| Greedy Search | 贪婪搜索 | 一种解码策略，在每一步都选择概率最高的下一个词元。 |
| Beam Search | 集束搜索 | 一种解码策略，在每一步跟踪并扩展多个最佳候选序列。 |
| Top-k Sampling | Top-k采样 | 一种解码策略，在每个采样步骤中只从前k个最有可能的词元中选择。 |
| Nucleus Sampling (Top-p Sampling) | 核采样 (Top-p采样) | 一种解码策略，选择累积概率超过阈值p的最小顶级候选集。 |
| Penalty Sampling | 惩罚采样 | 一种解码策略，通过降低先前生成词元的分数来惩罚重复。 |
| Guided Decoding | 引导式解码 | 一种解码策略，通过将额外信息（如主题、情感偏好）融入候选排名函数来指导生成。 |
| Prompt Design | 提示设计 | 通过精心构造输入文本（提示）来引导大型语言模型完成特定任务。 |
| Prefix-Tuning | 前缀调优 | 一种参数高效的微调方法，在输入序列开头添加少量可训练参数来引导语言模型。 |
| P-tuning | P-调优 | 一种参数高效的微调方法，通过训练连续提示嵌入来优化提示模板中的伪标记。 |
| Prompt Tuning | 提示词微调 | 一种参数高效的微调方法，为每个下游任务添加少量可调的伪提示词到输入文本中。 |
| Fine-tuning | 微调 | 在特定任务的监督数据集上进一步训练预训练模型以适应新任务。 |
| Reinforcement Learning (RL) | 强化学习 | 一种机器学习范式，通过智能体与环境的交互学习以最大化累积奖励。 |
| Unlikelihood Training | 非似然训练 | 一种训练方法，通过惩罚不希望出现的词元或序列来解决语言模型过度自信和重复生成的问题。 |
