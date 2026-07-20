# 广义视觉语言模型

> Generalized Visual Language Models

> 来源：Lil'Log / Lilian Weng，2022-06-09
> 原文链接：https://lilianweng.github.io/posts/2022-06-09-vlm/
> 分类：人工智能 / 视觉语言模型

## 核心要点

- 广义视觉语言模型旨在通过扩展预训练的语言模型来处理视觉信号，以实现图像字幕和视觉问答等任务。
- 这类模型大致可分为四类：将图像转换为嵌入特征与词元联合训练、学习图像嵌入作为冻结语言模型的前缀、使用交叉注意力机制融合视觉信息，以及无需训练即可结合视觉和语言模型。
- 联合训练方法如VisualBERT和SimVLM将图像块视为词元，与文本共同输入模型进行训练，通过自注意力或前缀语言模型目标学习视觉与文本的联合表示。
- Frozen和ClipCap等模型通过仅训练视觉模块或轻量级映射网络，将图像嵌入转换为与冻结预训练语言模型兼容的空间，从而在保留强大语言能力的同时处理视觉信息。
- 交叉注意力融合机制如VisualGPT、VC-GPT、MERLOT、Flamingo和CoCa，通过专门设计的注意力层或重采样器，将视觉信息更有效地融入语言模型的不同层中，以平衡文本生成和视觉理解。
- Flamingo模型通过基于Perceiver的重采样器生成固定大小的视觉词元，并使用与冻结语言模型层交错的门控交叉注意力层，实现少样本学习和处理交错图像文本的能力。
- CoCa模型结合了对比学习和图像描述生成，通过双编码器对比损失和编码器-解码器图像描述损失进行联合训练，并在多种多模态任务上表现出色。
- 无需训练的方法，如MAGiC、PICa和苏格拉底模型，利用预训练视觉模型和语言模型，通过引导式解码或语言提示作为通信接口，实现视觉语言任务。
- MAGiC通过CLIP引导的解码，在不微调的情况下生成与图像相关的文本；PICa通过图像字幕和少样本提示GPT-3解决知识型VQA。
- 苏格拉底模型框架通过多模型多模态提示，将不同模态的预训练模型通过语言组合起来，无需额外训练即可进行零样本多模态推理。

## 正文

处理图像以生成文本，例如图像字幕和视觉问答，已经研究多年。传统上，此类系统依赖于目标检测网络作为视觉编码器来捕获视觉特征，然后通过文本解码器生成文本。鉴于现有的大量文献，在这篇文章中，我只想专注于解决视觉语言任务的一种方法，即*扩展预训练的[广义语言模型](https://lilianweng.github.io/posts/2019-01-31-lm/)使其能够处理视觉信号*。

> Processing images to generate text, such as image captioning and visual question-answering, has been studied for years. Traditionally such systems rely on an object detection network as a vision encoder to capture visual features and then produce text via a text decoder. Given a large amount of existing literature, in this post, I would like to only focus on one approach for solving vision language tasks, which is to *extend pre-trained [generalized language models](https://lilianweng.github.io/posts/2019-01-31-lm/) to be capable of consuming visual signals*.

我大致将这类视觉语言模型（VLM）分为四类：

> I roughly group such vision language models (VLMs) into four buckets:

1. 将图像转换为可以与词元嵌入联合训练的嵌入特征。
2. 学习良好的图像嵌入，使其可以作为冻结的预训练语言模型的前缀。
3. 使用专门设计的交叉注意力机制将视觉信息融合到语言模型的层中。
4. 无需任何训练即可结合视觉和语言模型。

> • Translating images into embedding features that can be jointly trained with token embeddings.
> • Learning good image embeddings that can work as a prefix for a frozen, pre-trained language model.
> • Using a specially designed cross-attention mechanism to fuse visual information into layers of the language model.
> • Combine vision and language models without any training.

### 图像与文本联合训练

> Jointly Training with Image and Text

将视觉信息融合到语言模型中的一种直接方法是将图像视为普通文本词元，并对模型进行文本和图像联合表示序列的训练。具体来说，图像被分成多个较小的块，每个块在输入序列中被视为一个“词元”。

> One straightforward approach to fuse visual information into language models is to treat images as normal text tokens and train the model on a sequence of joint representations of both text and images. Precisely, images are divided into multiple smaller patches and each patch is treated as one “token” in the input sequence.

**VisualBERT**（[Li 等人，2019](https://arxiv.org/abs/1908.03557)）将文本输入和图像区域都输入到[BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert)中，使其能够通过自注意力机制发现图像和文本之间的内部对齐。

> **VisualBERT** ([Li et al. 2019](https://arxiv.org/abs/1908.03557)) feeds both text inputs and image regions into [BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#bert) such that it is able to discover the internal alignment between images and text with self-attention mechanism.

![VisualBERT is trained on the combination of both text and image embeddings. (Image source: Li et al. 2019 )](https://lilianweng.github.io/posts/2022-06-09-vlm/VisualBERT-arch.png)

类似于[BERT中的文本嵌入](https://lilianweng.github.io/posts/2019-01-31-lm/#input-embedding)，VisualBERT中的每个视觉嵌入也汇总了三种类型的嵌入：词元化特征$f_o$、分割嵌入$f_s$和位置嵌入$f_p$，具体如下：

> Similar to [text embedding in BERT](https://lilianweng.github.io/posts/2019-01-31-lm/#input-embedding), each visual embedding in VisualBERT also sums up three types of embeddings, tokenized features $f_o$, segmentation embedding $f_s$ and position embedding $f_p$, precisely:

1\. $f_o$是由卷积神经网络为图像的边界区域计算的视觉特征向量；

2\. $f_s$是用于指示嵌入是用于视觉而非文本的片段嵌入；

3\. $f_p$是用于对齐边界区域顺序的位置嵌入。

英文原文：

1\. $f_o$ is a visual feature vector computed for a bounding region of the image by a convolutional neural network;

2\. $f_s$ is a segment embedding to indicate whether the embedding is for vision not for text;

3\. $f_p$ is a position embedding used for aligning the order of bounding regions.

该模型在MS COCO图像字幕数据集上进行训练，以文本和图像作为输入来预测文本字幕，使用了两个基于视觉的语言模型目标：

> The model is trained on MS COCO image caption dataset with both text and image as inputs to predict text captions, using two visually-grounded language model objectives:

1. *[MLM](https://lilianweng.github.io/posts/2019-01-31-lm/#pre-training-tasks)与图像*。模型需要预测被遮蔽的文本词元，而图像嵌入始终保持不被遮蔽。
2. *句子-图像预测*。当提供一张图像和两个相关联的字幕时，其中一个字幕有50%的概率是随机的不相关字幕。模型被要求区分这两种情况。

> • *[MLM](https://lilianweng.github.io/posts/2019-01-31-lm/#pre-training-tasks) with the image*. The model needs to predict masked text tokens, while image embeddings always stay not masked.
> • *Sentence-image prediction*. When provided with an image and two associated captions, one of two captions might be a random unrelated caption with 50% probability. The model is asked to distinguish these two situations.

根据消融实验，最重要的配置是尽早将视觉信息融合到Transformer层中，并在COCO字幕数据集上预训练模型。从预训练的BERT初始化以及采用句子-图像预测训练目标的影响相对较小。

> According to ablation experiments, the most important configuration is to fuse visual information early on into the transformer layers and to pretrain the model on the COCO caption dataset. Initialization from a pre-trained BERT and the adoption of the sentence-image prediction training objective have relatively small impacts.

![Ablation study results of VisualBERT on NLVR. (Image source: Li et al. 2019 )](https://lilianweng.github.io/posts/2022-06-09-vlm/VisualBERT-ablation.png)

VisualBERT在当时在NLVR和Flickr30K上超越了SoTA，但在VQA上与SoTA仍存在一定的性能差距。

> VisualBERT outperforms SoTA at the time on NLVR and Flickr30K, but still has some performance gap with SoTA on VQA.

**SimVLM**（Simple Visual Language Model；[Wang 等人，2022](https://arxiv.org/abs/2108.10904)）是一个简单的*前缀语言模型*，其中前缀序列通过像BERT一样的双向注意力进行处理，但主要输入序列只具有像[GPT](https://lilianweng.github.io/posts/2022-06-09-vlm/#gpt)一样的因果注意力。图像被编码为前缀词元，以便模型可以完全消耗视觉信息，然后以自回归方式生成相关文本。

> **SimVLM** (Simple Visual Language Model; [Wang et al. 2022](https://arxiv.org/abs/2108.10904)) is a simple *prefix language model*, where the prefix sequence is processed with bi-directional attention like BERT, but the main input sequence only has causal attention like [GPT](https://lilianweng.github.io/posts/2022-06-09-vlm/#gpt). Images are encoded as prefix tokens such that the model can fully consume the visual information and then generates associated text in an autoregressive manner.

受[ViT](https://arxiv.org/abs/2010.11929)和[CoAtNet](https://arxiv.org/abs/2106.04803)的启发，SimVLM将图像分割成更小的块，形成一个扁平的1D块序列。他们使用由ResNet的前3个块组成的卷积阶段来提取上下文相关的块，并且发现这种设置比简单的线性投影效果更好。

> Inspired by [ViT](https://arxiv.org/abs/2010.11929) and [CoAtNet](https://arxiv.org/abs/2106.04803), SimVLM splits the image into smaller patches in a flatten 1D sequence of patches. They use the convolutional stage consisting of the first 3 blocks of ResNet to extract contextualized patches and this setup is found to work better than a naive linear projection.

![Training architecture for SimVLM, where the image patches are processed by the cross-attention encoder and the text decoder has causal attention. (Image source: Wang et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/SimVLM-arch.png)

SimVLM的训练数据包括来自ALIGN（[Jia 等人，2021](https://arxiv.org/abs/2102.05918)）的大量图像-文本对以及来自C4数据集（[Raffel 等人，2019](https://arxiv.org/abs/1910.10683)）的纯文本数据。他们在每个批次中混合这两个预训练数据集，其中包含4,096个图像-文本对（ALIGN）和512个纯文本文档（C4）。

> Training data for SimVLM consists of a large number of image-text pairs from ALIGN ([Jia et al. 2021](https://arxiv.org/abs/2102.05918)) and text-only data from C4 dataset ([Raffel et al. 2019](https://arxiv.org/abs/1910.10683)). They mix the two pretraining datasets within each batch, containing 4,096 image-text pairs (ALIGN) and 512 text-only documents (C4).

根据消融研究，训练时同时拥有图像-文本数据和纯文本数据非常重要。PrefixLM 目标优于[跨度损坏](https://arxiv.org/abs/1910.10683)和朴素 LM。

> According to ablation studies, it is important to have both image-text and text-only data for training. The PrefixLM objective outperforms both [span corruption](https://arxiv.org/abs/1910.10683) and naive LM.

![Ablation study results of SimVLM on VQA. (Image source: Wang et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/SimVLM-ablation.png)

**CM3**（因果掩码多模态建模；[Aghajanyan, et al. 2022](https://arxiv.org/abs/2201.07520)）是一种超文本语言模型，学习生成 CC-NEWS 和维基百科文章的大规模 HTML 网页内容（超文本标记、超链接和图像）。由此产生的 CM3 模型能够在任意掩码文档上下文的条件下生成丰富的结构化多模态输出。

> **CM3** (Causally-Masked Multimodal Modeling; [Aghajanyan, et al. 2022](https://arxiv.org/abs/2201.07520)) is a hyper-text language model, learning to generate the content (hypertext markup, hyperlinks and images) of large scale HTML web pages of CC-NEWS and Wikipedia articles. The resulting CM3 models can generate rich structured, multi-modal outputs while conditioning on arbitrary masked document contexts.

从架构上看，CM3 是一个自回归模型。然而，为了结合因果语言建模和掩码语言建模，CM3 还会掩盖少量长标记跨度，并尝试在序列的*末尾*生成它们。

> Architecture-wise, CM3 is an autoregressive model. However, in order to combine causal and masked language modeling, CM3 also masks out a small number of long token spans and tries to generate them at the *end* of the sequences.

![Illustration of how a causally masked language model works. (Image source: Aghajanyan, et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/CM3-arch.png)

CM3 的训练数据集包含近 1T 的网络数据。在预处理过程中，图像首先从 `src` 下载并随机裁剪到 256 x 256 大小。然后它们通过 [VQVAE-GAN](https://arxiv.org/abs/2012.09841) 进行标记化，每张图像产生 256 个标记。这些标记用空格连接，然后插入回 `src` 属性中。

> The training dataset for CM3 contains close to 1T Web data. During preprocessing, images are first downloaded from `src` and resized to 256 x 256 with random cropping. Then they are tokenized by [VQVAE-GAN](https://arxiv.org/abs/2012.09841), resulting in 256 tokens per image. These tokens, joined with spaces, are inserted back into the `src` attribute.

CM3 可以通过提示工程完成多种类型的任务：

> CM3 can be used to complete several types of tasks by prompt engineering:

- 图像填充：

> • Image in-filling:

```
Infilling Prompt: <figure>
	<img src="{prefix}<mask:0>{postfix}"><mask:0>
```

- 条件图像填充：

> • Conditional image in-filling:

```
Conditional Infilling Prompt:
<figure>
	<img alt="Photo: {text}" src="{prefix}<mask:0>{postfix}"><mask:0>
```

- 条件图像生成：

> • Conditional image generation:

```
Conditional Generation Prompt: <figure>
	<img alt="{prompt}
```

- 图像字幕：

> • Image captions:

```
Captioning Masked Prompt #1: 
<figure>
	<img alt="Photo: A photo taken of<mask:0>" src="{image}">

Captioning Causal Prompt #1: 
<figure>
	<img src="{image}" title="Photo: A photo taken of
```

- 实体消歧

> • Entity disambiguation

```
Original: Manetho writes that these kings ruled from <a title="Memphis, Egypt">Memphis</a>

Prompt: Manetho writes that these kings ruled from <a title="<mask:0>">Memphis</a>...<mask:0>

Target: Manetho writes that these kings ruled from <a title="<mask:0>">Memphis</a>...<mask:0> Memphis, Egypt
```

### 学习到的图像嵌入作为（冻结的）LM 前缀

> Learned Image Embedding as (Frozen) LM Prefix

如果我们不想在调整语言模型以处理视觉信号时改变其参数怎么办？相反，我们为图像学习一个嵌入空间，使其与语言模型的嵌入空间兼容。

> What if we don’t want to change the language model parameters when adapting it to handle visual signals? Instead we learn such an embedding space for images that it is compatible with the language model’s.

受 [prefix](https://arxiv.org/abs/2101.00190) 或 [prompt](https://arxiv.org/abs/2104.08691) [tuning](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#prefix-tuning) 的启发，**Frozen** ([Tsimpoukelli et al. 2021](https://arxiv.org/abs/2106.13884)) 和 **ClipCap** ([Mokady, Hertz & Hertz, 2021](https://arxiv.org/abs/2111.09734)) 都只在训练期间更新视觉模块的参数，以生成可以与预训练的、*冻结的* 语言模型协同工作的图像嵌入。两者都使用对齐的图像字幕 [数据集](https://lilianweng.github.io/posts/2022-06-09-vlm/#image-caption-datasets) 进行训练，以在给定图像和先前文本标记的条件下生成字幕中的下一个文本标记。通过冻结语言模型参数，保留了强大的语言能力。此外，尽管这种设置是用有限的图像字幕数据训练的，但它们在测试时也可以依赖语言模型的百科全书式知识。

> Inspired by [prefix](https://arxiv.org/abs/2101.00190) or [prompt](https://arxiv.org/abs/2104.08691) [tuning](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#prefix-tuning), both **Frozen** ([Tsimpoukelli et al. 2021](https://arxiv.org/abs/2106.13884)) and **ClipCap** ([Mokady, Hertz & Hertz, 2021](https://arxiv.org/abs/2111.09734)) only update the parameters of the vision module during training to produce image embeddings that can work with a pretrained, *frozen* language model. Both are trained with aligned image caption [datasets](https://lilianweng.github.io/posts/2022-06-09-vlm/#image-caption-datasets) to produce the next text token in caption conditioned on the image and previous text tokens. The powerful language capability is retained by freezing LM parameters. In addition, even though such setup is trained with limited image caption data, they can also rely on the encyclopedic knowledge of the language model at test time.

Frozen 的视觉编码器基于 NF-ResNet-50，并使用全局池化层后 NF-Resnet 的最终输出向量。Frozen VLM 可以用作多模型少样本学习器，在测试时通过一系列交错的图像和文本适应新任务，进行零样本或少样本迁移。

> The vision encoder of Frozen is based on NF-ResNet-50 and uses the final output vector of the NF-Resnet after the global pooling layer. The Frozen VLM can be used as a multi-model few-shot learner to adapt to new tasks at test time for zero-shot or few-shot transfer with a sequence of interleaved images and text.

![Illustration of Frozen model (left) training architecture and (right) testing pipeline. (Image source: Tsimpoukelli et al. 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/Frozen-arch.png)

实验表明，有趣的是，微调预训练的语言模型会导致 VQA 任务的性能下降。从预训练版本初始化语言模型很重要，因为从头开始训练 (${Frozen}_\text{scratch}$) 没有显示出任何有意义的进展。基线 ${Frozen}_\text{train-blind}$ 遮蔽了图像，但由于预训练语言模型的内在能力，仍然可以达到不错的性能。

> Experiments showed that fine-tuning the pre-trained LM interestingly leads to worse performance on VQA tasks. It is important to initialize the language model from a pre-trained version, as training from scratch (${Frozen}_\text{scratch}$) does not show any meaningful progress. The baseline ${Frozen}_\text{train-blind}$ blacks out the image but still can achieve decent performance because of the innate power of the pre-trained LM.

![Performance of different versions of Frozen on (left) VQAv2 and (right) OKVQA, trained on Conceptual Captions. "Frozen scratch" does not load a pre-trained LM and is trained from scratch. "Frozen finetuned" has the language model finetuned, while "Frozen" keeps LM frozen. "Frozen train-blind" blacks out the image. (Image source: Tsimpoukelli et al. 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/Frozen-results.png)

ClipCap 依赖 [CLIP](https://lilianweng.github.io/posts/2021-05-31-contrastive/#clip) ([Radford et al. 2021](https://arxiv.org/abs/2103.00020)) 进行视觉编码，但它需要通过一个轻量级映射网络 $F$ 进行处理，以便将图像嵌入向量转换到与预训练语言模型相同的语义空间。该网络 $F$ 将 CLIP 嵌入映射到一系列 $k$ 嵌入向量，每个向量的维度与 GPT2 中的词嵌入相同。增加前缀大小 $k$ 有助于提高性能。在训练期间，CLIP 视觉编码器和语言模型都处于 *冻结* 状态，只学习映射网络 $F$。他们发现，当语言模型冻结时，$F$ 应该是一个 Transformer，具有 8 个多头自注意力层，每个层有 8 个头；但当语言模型可以微调时，一个 MLP 就足够了。

> ClipCap relies on [CLIP](https://lilianweng.github.io/posts/2021-05-31-contrastive/#clip) ([Radford et al. 2021](https://arxiv.org/abs/2103.00020)) for vision encoding, but it needs to be processed by a light mapping network $F$ such that image embedding vectors are translated into the same semantic space as the pre-trained LM. The network $F$ maps CLIP embeddings into a sequence of $k$ embedding vectors, each with the same dimension as a word embedding in GPT2. Increasing the prefix size $k$ helps improve the performance. Both CLIP vision encoder and the LM are *frozen* during training and only the mapping network $F$ is learned. They found that when LM is frozen, $F$ should be a transformer, with 8 multi-head self-attention layers with 8 heads each, but when LM can be fine-tuned, a MLP is enough.

尽管 ClipCap 只训练了这样一组最小的参数，它在图像字幕任务上仍然取得了不错的性能，与当时的最先进技术（例如 [Oscar](https://arxiv.org/abs/2004.06165), [VLP](https://arxiv.org/abs/1909.11059), [BUTD](https://arxiv.org/abs/1707.07998)）相当。因此他们推断，“CLIP 空间已经包含了所需的信息，将其适应特定风格并不能增加灵活性。”

> Even though ClipCap only trains such a minimum set of parameters, it still achieves decent performance on image captioning tasks, comparable with SoTA at the time (e.g. [Oscar](https://arxiv.org/abs/2004.06165), [VLP](https://arxiv.org/abs/1909.11059), [BUTD](https://arxiv.org/abs/1707.07998)). Hence they postulate that “the CLIP space already encapsulates the required information, and adapting it towards specific styles does not contribute to flexibility.”

![Overview of ClipCap training pipeline where only the mapping network needs to be train to transform CLIP image embedding to work with the pre-trained LM. (Image source: Mokady, Hertz & Hertz, 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/ClipCap-arch.png)

有趣的事实是——因为 ClipCap 将 CLIP 图像嵌入转换为 LM 空间，所以处理后的前缀甚至可以被解释为单词。

> The fun fact is - because ClipCap translates CLIP image embeddings into LM space, the processed prefixes can be even interpreted as words.

![The learned image embedding can be interpreted as text, containing words related to the image context. (Image source: Mokady, Hertz & Hertz, 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/ClipCap-words.png)

### 文本-图像交叉注意力融合机制

> Text-Image Cross-Attention Fuse Mechanisms

为了更有效地将视觉信息融合到语言模型的不同层中，我们可以考虑一种专门设计的交叉注意力融合机制，以平衡文本生成能力和视觉信息的混合。

> To more efficiently fuse visual information into different layers of the language model, we can consider a specially designed cross-attention fuse mechanism to balance the mixture of text generation capacity and visual information.

**VisualGPT** ([Chen et al. 2021](https://arxiv.org/abs/2102.10407)) 采用一种自我复活的编码器-解码器注意力机制，以少量领域内图像-文本数据快速适应预训练的语言模型。

> **VisualGPT** ([Chen et al. 2021](https://arxiv.org/abs/2102.10407)) employs a self-resurrecting encoder-decoder attention mechanism to quickly adapt the pre-trained LM with a small amount of in-domain image-text data.

![Illustration of VisualGPT architecture. (Image source: Chen et al. 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/VisualGPT.png)

令$I$是视觉编码器的输出，$H$是LM解码器的隐藏状态。VisualGPT引入了一种自复活激活单元（SRAU），以控制预训练语言信息$H$和视觉组件之间的权衡，$\text{EncDecAttn}(H, I)$通过两个互补门$B^\text{vis}$和$B^\text{lan}$：

> Let $I$ be the output of a visual encoder and $H$ be the hidden state of the LM decoder. VisualGPT introduced a self-resurrecting activation unit (SRAU) to control the tradeoff between a mixture of pre-trained linguistic information $H$ and visual component, $\text{EncDecAttn}(H, I)$ via two complementary gates $B^\text{vis}$ and $B^\text{lan}$:



$$
\begin{aligned}
& B^\text{vis} \otimes \text{EncDecAttn}(H, I) + B^\text{lan} \otimes H \\
\text{where }
& B^\text{vis}[i,j] = \sigma(H[i,j]) \mathbb{1}[\sigma(H[i,j]) > \tau] \\
& B^\text{lan}[i,j] = (1 - \sigma(H[i,j])) \mathbb{1}[1 - \sigma(H[i,j]) > \tau] \\
\end{aligned}
$$


其中 $\otimes$ 表示逐元素相乘，$[i,j]$ 表示矩阵中的一个元素。$\tau$ 是一个预定义的阈值超参数。

>
>
> $$
> \begin{aligned}
> & B^\text{vis} \otimes \text{EncDecAttn}(H, I) + B^\text{lan} \otimes H \\
> \text{where }
> & B^\text{vis}[i,j] = \sigma(H[i,j]) \mathbb{1}[\sigma(H[i,j]) > \tau] \\
> & B^\text{lan}[i,j] = (1 - \sigma(H[i,j])) \mathbb{1}[1 - \sigma(H[i,j]) > \tau] \\
> \end{aligned}
> $$
>
>
> where $\otimes$ is element-wise multiplication and $[i,j]$ denotes one element in the matrix. $\tau$ is a predefined threshold hyperparameter.

![Comparison of different models trained on 0.1% and 1% of the MS COCO and Conceptual Caption datasets. (Image source: Chen et al. 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/VisualGPT-results.png)

**VC-GPT** (视觉条件化GPT; [Luo et al. 2022](https://arxiv.org/abs/2201.12723)) 将预训练的视觉Transformer（CLIP-ViT）作为视觉编码器，将预训练的语言模型（LM）作为语言解码器。

> **VC-GPT** (Visual Conditioned GPT; [Luo et al. 2022](https://arxiv.org/abs/2201.12723)) combines a pretrained visual transformer (CLIP-ViT) as visual encoder and a pretrained LM as language decoder.

![Illustration of VC-GPT training framework. (Image source: Luo et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/VC-GPT.png)

CLIP-ViT 将一系列图像块作为输入，并为每个图像块输出表示。为避免灾难性遗忘，VC-GPT 没有将视觉信息直接注入 GPT2，而是在视觉编码器和语言解码器的输出之上引入了额外的交叉注意力层。然后，一个*自集成*模块线性组合了单一模型语言解码器 logits $h^G$ 和跨模型视觉-语言融合模块 logits $h^\text{fuse}$。自集成模块（参见图 13 中的“VC-GPT w/o SE”）对性能至关重要。

> The CLIP-ViT takes a sequence of image patches as inputs and outputs representation for each patch. To avoid catastrophic forgetting, instead of injecting the visual information directly into GPT2, VC-GPT introduces extra cross-attention layers on top of the output of visual encoder and language decoder. Then a *self-ensemble* module linearly combines the single model language decoder logits $h^G$ and cross-model vision-language fused module logits $h^\text{fuse}$. The self-ensemble module (see “VC-GPT w/o SE” in Fig. 13) is important for the performance.

$$
\text{logits} = W^G h^G + W^\text{fuse}h^\text{fuse}
$$

其中 $W^G$ 是语言解码器的线性投影，由 GPT2 的词嵌入矩阵初始化，$W^\text{fuse}$ 是融合模块的线性投影，并随机初始化。

> where $W^G$ is a linear projection of the language decoder, initialized by the word embedding matrix of GPT2 and $W^\text{fuse}$ is a linear projection of the fusion module and initialized randomly.

![Performance of VC-GPT on the MS COCO test set, in comparison with other end-to-end image captioning baseline models. Metric abbreviation:  C = CIDEr; B = BLEU; M = METEOR; S = SPICE. (Image source: Luo et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/VC-GPT-results.png)

**MERLOT** ([Zellers, et al. 2021](https://arxiv.org/abs/2106.02636)) 使用 600 万个带有转录语音的 YouTube 视频（[YT-Temporal-180M](https://rowanzellers.com/merlot/#data)）进行训练，以学习空间（帧级）和时间（视频级）目标，并在微调后在 VQA 和视觉推理任务上表现出强大的性能。

> **MERLOT** ([Zellers, et al. 2021](https://arxiv.org/abs/2106.02636)) is trained with 6 millions of YouTube videos with transcribed speech ([YT-Temporal-180M](https://rowanzellers.com/merlot/#data)) to learn both spatial (frame-level) and temporal (video-level) objectives and demonstrated strong performance on VQA and visual reasoning tasks when fine-tuned.

每个视频 $\mathcal{V}$ 被分成多个片段 $\{ \boldsymbol{s}_t \}$，每个片段 $\boldsymbol{s}_t$ 包含一个从中间时间步提取的图像帧 $\mathbf{I}_t$ 和 $L=32$ 个相关词语的 token。图像由学习到的图像编码器编码，词语使用学习到的嵌入进行编码。然后两者在联合视觉-语言 Transformer 中一起编码。

> Each video $\mathcal{V}$ is split into multiple segments $\{ \boldsymbol{s}_t \}$, each segment $\boldsymbol{s}_t$ containing an image frame $\mathbf{I}_t$ extracted from the middle timestep and $L=32$ tokens of words associated. Images are encoded by a learned image encoder and words are encoded using a learned embedding. Then both are encoded together within a joint vision-language transformer.

MERLOT 中有 3 个学习目标：

> There are 3 learning objectives in MERLOT:

1\. *掩码语言建模*（MLM）特别有用，因为在视频中，人们往往会漫无边际地说话，导致许多重复的关键词或填充词。

2\. *对比帧-字幕匹配*使用联合视觉-语言 Transformer 中的纯语言部分。每个帧 $\mathbf{I}_t$ 和字幕 $\boldsymbol{w}_t$ 的匹配表示被视为正例，而负例则来自小批量中所有其他帧-字幕对。

3\. *时间重排序*学习时间推理：打乱随机 $i$ 帧，并用随机且唯一的片段级位置嵌入替换片段级位置嵌入。学习随机位置嵌入，使模型能够根据正确排序的帧来解开这些“打乱的”帧。损失是预测每个帧-帧对是 $t_i < t_j$ 还是 $t_j < t_i$。

英文原文：

1\. *Masked language modeling* (MLM) is useful especially because in videos, people tend to ramble, resulting in many repeated keywords or filler words.

2\. *Contrastive frame-caption matching* uses the language-only part from the joint vision-language transformer. Matched representations for each frame $\mathbf{I}_t$ and caption $\boldsymbol{w}_t$ are treated as positive examples, while the negative examples come from all other frame-caption pairs in the minibatch.

3\. *Temporal reordering* learns temporal reasoning: scramble random $i$ frames and replace the segment-level position embeddings with a random and unique position embedding. The random position embeddings are learned, allowing the model to unshuffle these “‘shuffled’” frames conditioned on correctly-ordered ones. The loss is to predict whether $t_i < t_j$ or $t_j < t_i$ for each frame-frame pair.

![Illustration of MERLOT training framework: (Left) contrastive frame-caption matching training; (Right) joint vision-language transformer is trained with MLM loss, as well as on the temporal reordering task to unshuffle scrambled video frames. (Image source: Zellers, et al. 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/MERLOT.png)

消融研究表明，重要的是 (1) 在视频而不是图像上进行训练，(2) 扩大训练数据集的规模和多样性，以及 (3) 使用多样化的目标来鼓励全栈多模态推理。

> Ablation studies showed that it is important to (1) train on videos instead of images, (2) scale up the size and diversity of the training dataset and (3) use diverse objectives to encourage full-stack multimodal reasoning.

**Flamingo** ([Alayrac et al. 2022](https://arxiv.org/abs/2204.14198)) 是一种视觉语言模型，它接受与图像/视频交错的文本并输出自由形式的文本。Flamingo 通过基于 Transformer 的映射器连接预训练的语言模型和预训练的视觉编码器（即 CLIP 图像编码器）。为了更有效地整合视觉信号，Flamingo 采用了一种基于 [Perceiver](https://arxiv.org/abs/2103.03206) 的架构，从大量的视觉输入特征中生成数百个 token，然后使用与语言模型层交错的交叉注意力层将视觉信息融合到语言解码过程中。训练目标是自回归的 NLL 损失。

> **Flamingo** ([Alayrac et al. 2022](https://arxiv.org/abs/2204.14198)) is a visual language model that accepts text interleaved with images/videos and outputs free-form text. Flamingo connects a pretrained LM and a pretrained vision encoder (i.e. CLIP image encoder) via a transformer-based mapper. To more efficiently incorporate vision signals, Flamingo adopts a [Perceiver](https://arxiv.org/abs/2103.03206)-based architecture to produce a few hundreds of tokens out of a large number of visual input features and then use cross-attention layers interleaved with the LM layers to fuse visual information into the language decoding process. The training objective is an autoregressive, NLL loss.

- Perceiver 重采样器从图像/视频输入的视觉编码器接收时空特征，以生成固定大小的视觉 token。
- 冻结的语言模型配备了新初始化的交叉注意力层，这些层交错在预训练的语言模型层之间。因此，语言模型可以根据上述视觉 token 生成文本。

> • The Perceiver resampler receives spatio-temporal features from the vision encoder of image/video inputs to produce fixed-size visual tokens.
> • The frozen LM is equipped with newly initialized cross-attention layers interleaved between the pretrained LM layers. Thus the LM can generate text conditioned on the above visual tokens.

与 ClipCap 类似，两个预训练模型在训练期间都是*冻结*的，因此 Flamingo 仅被训练用于和谐地连接现有的强大语言和视觉模型。ClipCap 和 Flamingo 的主要区别在于，前者将图像嵌入视为语言模型的简单前缀，而后者使用门控交叉注意力密集层来融合图像信息。此外，Flamingo 比 ClipCap 整合了更多的训练数据。

> Similar to ClipCap, both pretrained models are *frozen* during training and thus Flamingo is only trained to harmoniously connect existing, powerful language and vision models together. Tha main difference between ClipCap and Flamingo is that the former treats the image embedding as simple prefix for LM, while the latter uses the gated cross-attention-dense layer to fuse image information. In addition, Flamingo incorporates a lot more training data than ClipCap.

![Overview of the Flamingo model. (Image source: Alayrac et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/Flamingo.png)

![The architecture illustration and pseudo code of the gated cross-attention-dense layer in Flamingo. (Image source: Alayrac et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/Flamingo-cross-attention.png)

为了方便处理带有交错图像的文本，Flamingo 中的掩码设计使得文本 token 只交叉关注与*最后*一个前置图像对应的视觉 token，这大大减少了某个文本 token 可以看到的视觉 token 数量。他们发现这种方法比允许文本 token 直接关注所有前置图像效果更好。文本仍然可以关注所有之前的图像，因为文本编码器中存在因果自注意力依赖。这种设计可以处理上下文中任意数量的图像。

> To easily handle text with interleaved images, masking in Flamingo is designed such that text token only cross-attends to visual tokens corresponding to the *last* preceding image, largely reducing the number of visual tokens that a certain text token can see. They found this works better than allowing text tokens to attend to all preceding images directly. Text still can attend to all previous images because there is a causal self-attention dependency in the text encoder. This design can deal with an arbitrary number of images in the context.

他们从互联网上抓取了 4300 万个网页，命名为 MultiModal MassiveWeb (M3W) 数据集，其中包含带有交错图像的文本。此外，Flamingo 还在配对的图像/文本和视频/文本数据集上进行训练，包括 [ALIGN, LTIP and VTP](https://lilianweng.github.io/posts/2022-06-09-vlm/#pair-image-text-datasets)。

> They scraped 43 million webpages from the Internet, named MultiModal MassiveWeb (M3W) dataset, containing text with interleaved images. In addition, Flamingo is also trained on paired image/text and video/text datasets, including [ALIGN, LTIP and VTP](https://lilianweng.github.io/posts/2022-06-09-vlm/#pair-image-text-datasets).

互联网数据集的数据处理包括：

> Data processing of the Internet dataset includes:

• 通过在视觉输入位置插入 `<image>` 标签，以及特殊 token `<BOS>`（句子开头）和 `<EOC>`（块结束；总是在文档末尾，在任何图像标签之前）来处理输入的网页文本。

• 他们从每个文档中采样一个包含 $L = 256$ 个 token 的随机子序列，并获取采样序列中包含的最多 $N = 5$ 张图像（如果图像数量更多，则只使用该采样子序列中的前 $N$ 张；如果图像数量更少，则填充至 $N$ 张）

• 计算函数 $\phi: [1,L] \to [0,N]$ 以跟踪文本和图像的交错顺序，该函数为每个文本位置分配在此位置之前出现的最后一个图像/视频的索引；如果没有前面的视觉数据，则为 0。

英文原文：

• The input Web page text is processed by inserting `<image>` tags at the location of visual inputs, as well as special tokens, `<BOS>` (beginning of sentence) and `<EOC>` (end of chunks; always at the end of the document, before any image tag).

• From each document, they sample a random subsequence of $L = 256$ tokens and take up to $N = 5$ images included in the sampled sequence (using only the first $N$ within that sampled subsequence if there are more, or padding to $N$ if fewer)

• A function $\phi: [1,L] \to [0,N]$ is computed to track the text and image interleaving order, which assigns to each text position the index of the last image/video appearing before this position; 0 if no preceding visual data.

由于 Flamingo 是在三种不同数据集的混合上训练的，因此它优化的是数据集特定 NLL 损失的加权和。调整数据集权重对于最终性能非常重要。在实践中，他们不是在数据集之间进行轮询，而是从每个数据集中采样一个批次，并在每次更新中应用这些梯度的加权和。跨不同异构数据集的梯度累积可以被视为稳定训练的一种方法，因为它减少了每次更新之间的梯度方差。

> Since Flamingo is trained on a mixture of three different datasets, it optimizes for a weighted sum of dataset-specific NLL losses. Tuning the dataset weights is very important for the final performance. In practice, instead of round-robin between datasets, they actually sample one batch from each dataset and apply a weighted sum of these gradients in each update. Gradient accumulation across different heterogeneous datasets can be viewed as a mean to stabilize training, as it reduces the gradient variance between each update.

在测试时，Flamingo 自然支持少样本学习，因为它可以通过任何文本和图像交错的序列进行工作。上下文中的更多示例有助于获得更好的性能。

> At test time, Flamingo naturally supports few-shot learning since it can work with any sequence of interleaved text and images. And more examples in the context contribute to better performance.

![Larger model sizes and more few-shot examples lead to better performance. (Image source: Alayrac et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/Flamingo-fewshot.png)

尽管 Flamingo 未使用任何微调，仅使用少样本提示，它在 16 项任务中的 6 项上仍优于 SoTA 微调模型。微调 Flamingo 成本高昂且难以进行超参数调整，但它确实能带来更好的结果。

> Flamingo outperforms SoTA fine-tuned models on 6 out of the 16 tasks despite even when not using any fine-tuning but only few-shot prompting. Fine-tuning Flamingo is expensive and it is difficult to do hyperparemeter tuning, but it does lead to better results.

![Performance of Flamingo model using different numbers of shots and of different sizes, in comparison with SoTA fine-tuned baseline. (Image source: Alayrac et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/Flamingo-results.png)

**CoCa** (对比式图像描述器；[Yu & Wang et al., 2022](https://arxiv.org/abs/2205.01917)) 兼具对比学习和图像到描述生成两者的优点。它是一个模型，通过在 CLIP 风格表示上使用对比损失和在图像描述上使用生成损失进行联合训练，在各种多模态评估任务上实现了 SoTA 零样本迁移。

> **CoCa** (Contrastive Captioner; [Yu & Wang et al., 2022](https://arxiv.org/abs/2205.01917)) captures both the merits of contrastive learning and image-to-caption generation. It is a model jointly trained with contrastive loss on CLIP-style representation and generative loss on image captioning, achieving SoTA zero-shot transfer on a variety of multi-modal evaluation tasks.

![Overview of CoCa training framework. (Image source: Yu & Wang et al., 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/CoCa-arch.png)

CoCa 是从 *头开始*预训练的，使用了网络规模的 alt-text 数据 [ALIGN](https://lilianweng.github.io/posts/2022-06-09-vlm/#pair-image-text-datasets) 和通过将所有标签视为文本的 [JTB-3B](https://lilianweng.github.io/posts/2022-06-09-vlm/#pair-image-text-datasets) 中的标注图像。

> CoCa is pretrained from *scratch*, using web-scale alt-text data [ALIGN](https://lilianweng.github.io/posts/2022-06-09-vlm/#pair-image-text-datasets) and annotated images by treating all labels as texts in [JTB-3B](https://lilianweng.github.io/posts/2022-06-09-vlm/#pair-image-text-datasets).

CoCa 中有两个主要的训练组件。最终损失是以下两种损失的加权和，权重标量为 $\lambda_\text{cap}=2.0, \lambda_\text{con} = 1.0$。

> There are two major training components in CoCa. The final loss is a weighted sum of the following two losses, with weight scalars $\lambda_\text{cap}=2.0, \lambda_\text{con} = 1.0$.:

1\. $\mathcal{L}_\text{con}$ - *双编码器对比学习*优化对称对比学习损失，类似于 CLIP。

2\. $\mathcal{L}_\text{cap}$ - *编码器-解码器图像描述*通过优化自回归损失，使解码器根据图像编码器中的潜在编码特征预测图像描述。文本解码器被解耦为两个组件：*单模态*和*多模态*；一个好的平衡是将解码器对半分为这两个组件：

   - 底部单模态组件使用因果掩码自注意力对输入文本进行编码。

   - 顶部多模态组件将因果掩码自注意力和交叉注意力应用于视觉编码器的输出。

英文原文：

1\. $\mathcal{L}_\text{con}$ -  *Dual-encoder contrastive learning* optimizes the symmetric contrastive learning loss, similar to CLIP.

2\. $\mathcal{L}_\text{cap}$ - *Encoder-decoder captioning* has the decoder predict the caption based on the latent encoded features from the image encoder, by optimizing an autoregressive loss. The text decoder is decoupled into two components, *unimodal* and *multimodal*; a good balance is to split the decoder by half for these two components:



   - The bottom unimodal component encodes the input text with causally-masked self-attention.

   - The top multimodal component applies both causally-masked self-attention and cross-attention to the output of the vision encoder.

CoCa 在 VQA 上的表现优于仅对比模型，与仅字幕模型持平。字幕损失也被发现对零样本分类能力有益。

> CoCa performs better than the contrastive-only model and on par with the captioning-only model on VQA. Captioning loss is found to be beneficial to the zero-shot classification capacity too.

![Illustration of how CoCa can be used to solve various downstream tasks at test time. (Image source: Yu & Wang et al., 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/CoCa.png)

他们使用任务特定的注意力池化，或称注意力池化器，作为一种自然的任务适配器，因为他们发现单一的池化图像嵌入有助于视觉识别任务（例如 ImageNet 分类），而更细粒度的嵌入有助于多模态理解任务（例如 VQA）。池化器是一个单头多注意力层，具有 $n_\text{query}$ 个可学习查询（请注意 $\mathbf{X} \in \mathbb{R}^{L \times d}$、$\mathbf{W}^q \in \mathbb{R}^{d \times d_q}$ 和 $d_k = d_q$），其中编码器输出作为键和值。CoCa 在预训练中使用注意力池化器进行生成损失 $n_\text{query} = 256$ 和对比损失 $n_\text{query} = 1$。这使得模型能够作为 *冻结* 编码器获得强大的性能，在这种情况下，我们只学习一个新的池化器来聚合特征。

> They use task-specific attention pooling, or attention pooler, as a natural task adapter, as they found that a single pooled image embedding helps visual recognition tasks (e.g. ImageNet classification), while a more fine-grained embedding helps multimodal understanding tasks (e.g. VQA). A pooler is a single multi-head attention layer with $n_\text{query}$ learnable queries (note that $\mathbf{X} \in \mathbb{R}^{L \times d}$, $\mathbf{W}^q \in \mathbb{R}^{d \times d_q}$, and $d_k = d_q$), with the encoder output as both keys and values. CoCa uses attentional poolers in pretraining for generative loss $n_\text{query} = 256$ and contrastive loss $n_\text{query} = 1$. This enables the model to obtain strong performance as a *frozen* encoder where we only learn a new pooler to aggregate features.

![Pseudo code for CoCa architecture and training. (Image source: Yu & Wang et al., 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/CoCa-code.png)

### 无需训练

> No Training

最终，可以通过将预训练的语言模型和视觉模型拼接在一起，而无需训练任何额外的参数，来解决视觉语言任务。

> Finally it is possible to solve vision language tasks by stitching pretrained language and vision models together without training any additional parameters.

#### 基于视觉分数引导的解码

> Decoding Guided with Vision-based Scores

**MAGiC**（基于CLIP的图像引导文本生成；[Su et al. 2022](https://arxiv.org/abs/2205.02655)）通过[引导式解码](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#guided-decoding)，根据一个名为*魔法分数*的基于CLIP的分数来采样下一个token，无需微调。生成的文本被鼓励与给定图像相关，同时仍与先前生成的文本保持连贯。

> **MAGiC** (iMAge-Guided text generatIon with CLIP; [Su et al. 2022](https://arxiv.org/abs/2205.02655)) does [guided decoding](https://lilianweng.github.io/posts/2021-01-02-controllable-text-generation/#guided-decoding) according to a CLIP-based score named *magic score* to sample the next token, without fine-tuning. The generated text is encouraged to be relevant to the given image, while still stay coherent to the previously generated text.

下一个 token $x_t$ 在时间步 $t$ 根据以下方程选择。模型置信度和退化惩罚（[Su et al. 2022](https://arxiv.org/abs/2202.06417)）被添加以避免语言模型生成损坏的内容。

> The next token $x_t$ at a time step $t$ is selected according to the following equation. Model confidence and degeneration penalty ([Su et al. 2022](https://arxiv.org/abs/2202.06417)) are added to avoid corrupted generation from LM.

$$
\begin{aligned}
& x_t = \arg\max_{v \in \mathcal{V}^{(k)}} \big\{ (1-\alpha) \underbrace{p(v \vert \boldsymbol{x}_{<t})}_\text{model confidence} - \alpha \underbrace{\max_{1 \leq j \leq t-1} { \text{cosine}(h_v, h_{x_j})}}_\text{degeneration penalty} + \beta \underbrace{f_\text{magic}(v \vert \mathcal{I}, \boldsymbol{x}_{<t}, \mathcal{V}^{(k)})}_\text{magic score} \big\} \\
\text{where } & f_\text{magic} ( v \vert \mathcal{I}, \mathbf{x}_{<t}, \mathcal{V}^{(k)} )
= \frac{ \exp(\text{CLIP}(\mathcal{I}, [\boldsymbol{x}_{<t}:v])) }{ \sum_{z \in \mathcal{V}^{(k)}} \exp(\text{CLIP}(\mathcal{I}, [\boldsymbol{x}_{<t}:z])) }
= \frac{ \exp\big({h^\text{image}(\mathcal{I})}^\top h^\text{text}([\boldsymbol{x}_{<t}:v])\big) }{ \sum_{z \in \mathcal{V}^{(k)}} \exp\big({h^\text{image}(\mathcal{I})}^\top h^\text{text}([\boldsymbol{x}_{<t}:z])\big) }
\end{aligned}
$$

其中$\mathcal{I}$是输入图像；$\mathcal{V}^{(k)}$包含前$k$个由语言模型预测的可能token$p$；$\boldsymbol{x}_{<t}$指时间步长之前的已生成token$t$；$h_v$是token的表示$v$由LM根据的拼接计算得到$\boldsymbol{x}_{<t}$和$v$；$h^\text{image}(.)$和$h^\text{text}(.)$分别是CLIP图像编码器和文本编码器生成的嵌入。

> where $\mathcal{I}$ is the input image; $\mathcal{V}^{(k)}$ contains top-$k$ possible tokens predicted by the language model $p$; $\boldsymbol{x}_{<t}$ refers to the past generated tokens before time step $t$; $h_v$ is the representation of the token $v$ computed by LM conditioned on the concatenation of $\boldsymbol{x}_{<t}$ and $v$; $h^\text{image}(.)$ and $h^\text{text}(.)$ are embeddings generated by CLIP image and text encoders, respectively.

与其他无监督方法相比，MAGiC 具有不错的性能，但与监督方法仍有很大差距。

> MAGiC has decent performance compared to other unsupervised approaches, but still has big gaps with supervised methods.

![Image captioning performance on COCO and Flickr30k. (Image source: Su et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/MAGiC-results.png)

#### 语言作为通信接口

> Language as Communication Interface

对于基于知识的VQA任务，PICa（通过使用图像字幕提示GPT-3；[Yang et al. 2021](https://arxiv.org/abs/2109.05014)）首先将图像转换为字幕或标签，然后使用少样本示例提示GPT3提供答案。图像字幕或标签通过一些现有模型（例如[VinVL](https://openaccess.thecvf.com/content/CVPR2021/html/Zhang_VinVL_Revisiting_Visual_Representations_in_Vision-Language_Models_CVPR_2021_paper.html)）或Azure Tagging API提取。GPT3被视为一个非结构化的隐式知识库。

> For knowledge-based VQA tasks, PICa (Prompts GPT-3 via the use of Image Captions; [Yang et al. 2021](https://arxiv.org/abs/2109.05014)) first converts the images into captions or tags and then uses few-shot examples to prompt GPT3 to provide answers. Image captions or tags are extracted by some existing models (e.g. [VinVL](https://openaccess.thecvf.com/content/CVPR2021/html/Zhang_VinVL_Revisiting_Visual_Representations_in_Vision-Language_Models_CVPR_2021_paper.html)) or Azure Tagging API. And GPT3 is considered as an unstructured, implicit knowledge base.

![How PICa works for $n$-shot VQA at inference time. (Image source: Yang et al. 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/PICa-fewshot.png)

PICa探索了两种改进少样本示例以获得更好结果的方法：

> PICa explored two ways to improve few-shot examples to achieve better results:

- 上下文示例是根据它们与问题使用CLIP嵌入的*相似*程度来选择的。
- *多查询集成*是指多次提示模型以获取多个答案，并选择具有最高对数概率的答案。

> • In-context examples are selected based on how *similar* they are to the question using CLIP embedding.
> • *Multi-query ensembling* is to prompt the model multiple times to get multiple answers and the one with highest logprob is selected.

这种仅使用16个示例的简单方法将OK-VQA上的最新技术（SoTA）提高了8.6个百分点，并在VQAv2上取得了不错的性能。

> This simple approach with only 16 examples improved SoTA on OK-VQA by +8.6 points and got decent performance on VQAv2.

![Performance of PICa on OK-VQA. "PICa-Base" has random in-context examples, while "PICa-Full" incorporates both similar in-context example selection and multi-query ensembling. (Image source: Yang et al. 2021 )](https://lilianweng.github.io/posts/2022-06-09-vlm/PICa-OKVQA.png)

**苏格拉底模型** (SM) ([Zeng et al. 2022](https://arxiv.org/abs/2204.00598)) 是一个框架，用于通过语言（提示）将针对不同模态的多个预训练模型*组合*成一个模型，而无需进一步训练。这里语言被视为中间表示，不同模型可以通过它交换信息。其核心思想是使用*多模型多模态提示*，其中非语言模型的输出被插入到语言提示中，然后用于语言模型进行推理。

> **Socratic Models** (SM) ([Zeng et al. 2022](https://arxiv.org/abs/2204.00598)) is a framework to *compose* multiple pretrained models for different modality via language (prompting) into one model without further training. Here language is considered as the intermediate representation by which different models can exchange information. The key idea is to use *multi-model multimodal prompting*, in which output of a non-language model is inserted into a language prompt and then it is used for LM for reasoning.

让我们来看一个具体的例子。给定一个以自我为中心的视频（图像+音频），SM 可以使用文本到文本语言模型（LM）、图像到文本视觉语言模型（VLM）和语音到文本音频语言模型（ALM）生成人物活动的摘要。它们按以下方式链接：

> Let’s examine a concrete example. Given an ego-centric video (images + audio), SM can produce a summary of the person’s activity using text-to-text LM,  image-to-text VLM and speech-to-text ALM. They are chained as follows:

![(Image source: Zeng et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/SM-example.png)

1. VLM 检测视觉实体；
2. LM 建议可能听到的声音；
3. ALM 选择最有可能的声音；
4. LM 建议可能的活动；
5. VLM 对最有可能的活动进行排序；
6. LM 生成苏格拉底式交互的摘要。

> • the VLM detects visual entities;
> • the LM suggests sounds that may be heard;
> • the ALM chooses the most likely sound;
> • the LM suggests possible activities;
> • the VLM ranks the most likely activity;
> • the LM generates a summary of the Socratic interaction.

![Illustration of the Socratic Model solution for image captioning. (Image source: Zeng et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/SM-caption-example.png)

SM 可以生成图像标题，方法是首先使用 VLM 零样本预测不同的地点类别、物体类别、图像类型和人数；然后将 VLM 填充的语言提示输入到因果 LM 中以生成标题候选。苏格拉底方法在图像标题生成方面与 ClipCap 仍有性能差距，但考虑到它不涉及任何训练，表现相当不错。

> SM can generate image captions by first using VLM to zero-shot predict different place categories, object categories, image type and the number of people; and then the VLM-filled language prompt is fed into a causal LM to generate caption candidates. The Socratic approach still has performance gap with ClipCap on image captioning but pretty decent given it does not involve any training.

![Comparison of image captioning performance of different models on random 100 COCO text examples. (Image source: Zeng et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/SM-caption.png)

SM 框架非常灵活，可以用于图像标题之外的许多更复杂的任务。例如，以自我为中心的感知（用户输入 + VLM + LM + ALM）任务是将以自我为中心的视频作为输入，以 (1) 总结内容；(2) 回答自由形式的推理问题；(3) 并进行预测。

> SM framework is very flexible and can be used on a lot more complicated tasks other than image captions. For example, the egocentric perception (User inputs + VLM + LM + ALM) task is to take as inputs egocentric videos to (1) summarize content; (2) answer free-form reasoning questions; (3) and do forecasting.

![The Socratic Model approach for generating captions and question answering based on the egocentric videos. (Image source: Zeng et al. 2022 )](https://lilianweng.github.io/posts/2022-06-09-vlm/SM-egocentric.png)

### 数据集

> Datasets

#### 图像字幕数据集

> Image Caption Datasets

- *MS COCO* ([Chen et al. 2015](https://arxiv.org/abs/1504.00325))：包含 328K 张图像，每张图像都配有 5 个独立的字幕。
- *NoCaps* ([Agrawal et al., 2019](https://arxiv.org/abs/1812.08658)) 旨在衡量对未见类别和概念的泛化能力，其中域内包含仅描绘 COCO 类别的图像，近域包含 COCO 和新颖类别，而域外仅包含新颖类别。
- *Conceptual Captions* ([Sharma et al. 2018](https://aclanthology.org/P18-1238/)) 包含 300 万对图像和字幕，这些数据从网络中挖掘并经过后期处理。为了专注于概念，此数据集中的特定实体被替换为通用概念（例如，政治家的名字被替换为“政治家”）
- *Crisscrossed Captions (CxC)* ([Parekh et al. 2021](https://arxiv.org/abs/2004.15020)) 包含 247,315 个人工标注，其中包括图像对、字幕对和图像-字幕对之间的正向和负向关联。
- *Concadia* ([Kreiss et al. 2021](https://arxiv.org/abs/2104.08376)) 是一个基于维基百科的数据集，包含 96,918 张图像，以及相应的英文描述、字幕和周围上下文。

> • *MS COCO* ([Chen et al. 2015](https://arxiv.org/abs/1504.00325)): contains 328K images and each paired with 5 independent captions.
> • *NoCaps* ([Agrawal et al., 2019](https://arxiv.org/abs/1812.08658)) is designed to measure generalization to unseen classes and concepts, where in-domain contains images portraying only COCO classes, near-domain contains both COCO and novel classes, and out-of-domain consists of only novel classes.
> • *Conceptual Captions* ([Sharma et al. 2018](https://aclanthology.org/P18-1238/)) contains 3 million pairs of images and captions, mined from the web and post-processed. To focus on the concepts, specific entities in this dataset are replaced with general notions (e.g. a politician’s name is replaced with “politician”)
> • *Crisscrossed Captions (CxC)* ([Parekh et al. 2021](https://arxiv.org/abs/2004.15020)) contains 247,315 human-labeled annotations including positive and negative associations between image pairs, caption pairs and image-caption pairs.
> • *Concadia* ([Kreiss et al. 2021](https://arxiv.org/abs/2104.08376)) is a Wikipedia-based dataset containing 96,918 images with corresponding English-language descriptions, captions, and surrounding context.

#### 图像-文本配对数据集

> Pair Image-Text Datasets

(*) 非公开数据集。

> (*) Not a public dataset.

- *ALIGN* ([Jia et al., 2021](https://arxiv.org/abs/2102.05918)) 包含 18 亿张带有 alt-text 的图像。该数据集规模庞大但噪声较多，仅进行了最基本的基于频率的过滤。
- (*) *LTIP* (Long text & image pairs; [Alayrac et al. 2022](https://arxiv.org/abs/2204.14198))：3.12 亿张图像，与描述性字幕配对。
- (*) *VTP* (Video & text pairs; [Alayrac et al. 2022](https://arxiv.org/abs/2204.14198))：2700 万个短视频（平均约 22 秒），与描述性字幕配对。
- (*) *JFT-300M* / *JFT-3B* 是谷歌内部数据集，包含 3 亿 / 30 亿张图像，通过半自动化流程使用约 3 万个标签的类别层级进行标注。因此，数据和相关标签存在噪声。

> • *ALIGN* ([Jia et al., 2021](https://arxiv.org/abs/2102.05918)) contains 1.8 billion images with alt-text. The dataset is large but noisy with only minimal frequency-based filtration.
> • (*) *LTIP* (Long text & image pairs; [Alayrac et al. 2022](https://arxiv.org/abs/2204.14198)): 312 million images, paired with descriptive captions.
> • (*) *VTP* (Video & text pairs; [Alayrac et al. 2022](https://arxiv.org/abs/2204.14198)): 27 million short videos (~22 seconds on average), paired with descriptive captions.
> • (*) *JFT-300M* / *JFT-3B* are internal Google datasets, containing 300M / 3B images annotated with a class-hierarchy of around 30k labels via a semi-automatic pipeline. Thus the data and associated labels are noisy.

### 评估任务

> Evaluation Tasks

#### 视觉问答

> Visual Question-Answering

给定一张图像和一个问题，任务是正确回答该问题。

> Given an image and a question, the task is to correctly answer the question.

- *VQAv2* ([Goyal et al., 2017](https://arxiv.org/abs/1612.00837)) 包含 100 多万个关于 COCO 数据集中 20 万张图像的问题。
- *OK-VQA* ([Marino et al. 2019](https://arxiv.org/abs/1906.00067)) 包含 1.4 万个开放式问题，这些问题需要外部知识（例如来自维基百科）。


   - *A-OKVQA*：OK-VQA 的增强版继任者，与 OK-VAQ 没有重叠问题。
- *TextVQA*（[Singh 等人，2019](https://arxiv.org/abs/1904.08920)）包含 45,336 个问题，涉及 28,408 张图像，这些问题需要通过文本推理来回答。
- *VizWiz*（[Gurari 等人，2018](https://arxiv.org/abs/1802.08218)）包含超过 31,000 个视觉问题，这些问题源于盲人使用手机拍照并录制口头提问，每个视觉问题还附带 10 个众包答案。

> • *VQAv2* ([Goyal et al., 2017](https://arxiv.org/abs/1612.00837)) contains 1+ million questions about 200K images from COCO.

> • *OK-VQA* ([Marino et al. 2019](https://arxiv.org/abs/1906.00067)) contains 14K open-ended questions that require outside knowledge (e.g. from Wikipedia).
>

> ◦ *A-OKVQA*: the augmented successor of OK-VQA, with no overlapped questions with OK-VAQ.

> • *TextVQA* ([Singh, et al. 2019](https://arxiv.org/abs/1904.08920)) contains 45,336 questions on 28,408 images that require reasoning about text to answer.

> • *VizWiz* ([Gurari, et al. 2018](https://arxiv.org/abs/1802.08218)) contains over 31,000 visual questions originating from blind people who each took a picture using a mobile phone and recorded a spoken question about it, together with 10 crowdsourced answers per visual question.

#### 视觉语言推理

> Visual Language Reasoning

- *VCR*（视觉常识推理；[Zellers 等人，2018](https://arxiv.org/abs/1811.10830)）包含 29 万个多项选择问答题，这些问题来源于 11 万个电影场景，侧重于视觉常识。
- *NLVR2*（视觉推理的自然语言；[Suhr 等人，2019](https://arxiv.org/abs/1811.00491)）包含 10 万多个句子与网络图像配对的示例，任务是判断自然语言描述是否真实地描述了一对图像，侧重于语义多样性。
- *Flickr30K*（[Jia 等人，2015](https://arxiv.org/abs/1509.04942)）包含从 Flickr 收集的 3 万张图像和 25 万个标注，任务是根据句子片段选择边界区域。
- *SNLI-VE*（视觉蕴涵；[Xie 等人，2019](https://arxiv.org/abs/1901.06706)）建立在 SNLI 和 Flickr30K 的基础上，任务是推理图像前提和文本假设之间的关系。

> • *VCR* (Visual Commonsense Reasoning; [Zellers et al. 2018](https://arxiv.org/abs/1811.10830)) contains 290k multiple choice QA questions derived from 110k movie scenes, with focus on visual commonsense.
> • *NLVR2* (Natural Language for Visual Reasoning; [Suhr et al. 2019](https://arxiv.org/abs/1811.00491)) contains 100k+ examples of sentences paired with web images and the task is to determine whether a natural language caption is true about a pair of images, with a focus on semantic diversity.
> • *Flickr30K* ([Jia et al. 2015](https://arxiv.org/abs/1509.04942)) contains 30k images collected from Flickr and 250k annotations and the task is to select the bounding regions given spans of a sentence.
> • *SNLI-VE* (Visual Entailment; [Xie et al. 2019](https://arxiv.org/abs/1901.06706)) is built on top of SNLI and Flickr30K and the task is to reason about the relationship between an image premise and a text hypothesis.

#### 视频问答与理解

> Video QA and Understanding

- *MSR-VTT*（MSR 视频到文本；[Xu 等人，2016](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/06/cvpr16.msr-vtt.tmei_-1.pdf)）包含 1 万个网络视频片段，总时长 41.2 小时，共 20 万个片段-句子对；任务是将视频翻译成文本。
- *ActivityNet-QA*（[Yu 等人，2019](https://arxiv.org/abs/1906.02467)）包含 5,800 个视频上的 58,000 个人工标注问答对，这些视频来源于流行的 [ActivityNet](http://activity-net.org/index.html) 数据集。
- *TGIF*（Tumblr GIF；[Li 等人，2016](https://arxiv.org/abs/1604.02748)）包含 10 万个动画 GIF 和 12 万个描述动画 GIF 视觉内容的句子，这些内容是随机选择的 2015 年 5 月至 6 月在 Tumblr 上发布的帖子。
   - *TGIF-QA* 包含来自 TGIF 数据集的动画 GIF 的 16.5 万个问答对。
- *LSMDC*（大规模电影描述挑战；[Rohrbach 等人，2015](https://arxiv.org/abs/1501.02530)）包含从 202 部电影中提取的 118,081 个短视频片段。每个视频都带有一个字幕，这些字幕要么从电影剧本中提取，要么从为视障人士提供的转录 DVS（描述性视频服务）中提取。
- *TVQA* ([Lei et al. 2018](https://arxiv.org/abs/1809.01696)) / *TVQA+* ([Lei et al. 2019](https://arxiv.org/abs/1904.11574)) 是一个大规模视频问答数据集，基于6个热门电视节目（《老友记》、《生活大爆炸》、《老爸老妈的浪漫史》、《豪斯医生》、《实习医生格蕾》、《灵书妙探》）。它包含来自21.8K个视频片段的152.5K个问答对，视频总时长超过460小时。
- *DramaQA* ([Choi et al. 2020](https://arxiv.org/abs/2005.03356)) 是一个大规模视频问答数据集，基于韩国热门电视节目《又是吴海英》。该数据集包含四个难度级别的问答和多层次以角色为中心的故事描述。
- *VLEP* (视频与语言事件预测; [Lei et al. 2020](https://arxiv.org/abs/2010.07999)) 包含来自10,234个不同电视节目和YouTube生活方式Vlog视频片段的28,726个未来事件预测示例（及其理由）。

> • *MSR-VTT* (MSR Video to Text; [Xu et al. 2016](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/06/cvpr16.msr-vtt.tmei_-1.pdf)) contains 10K web video clips with 41.2 hours and 200K clip-sentence pairs in total; the task is to translate videos to text.

> • *ActivityNet-QA* ([Yu et al. 2019](https://arxiv.org/abs/1906.02467)) contains 58,000 human-annotated QA pairs on 5,800 videos derived from the popular [ActivityNet](http://activity-net.org/index.html) dataset.

> • *TGIF* (Tumblr GIF; [Li et al. .2016](https://arxiv.org/abs/1604.02748)) contains 100K animated GIFs and 120K sentences describing visual content of the animated GIFs, randomly selected posts published between May and June of 2015 on Tumblr.
>

> ◦ *TGIF-QA* contains 165K QA pairs for the animated GIFs from the TGIF dataset.

> • *LSMDC* (Large Scale Movie Description Challenge; [Rohrbach et al. 2015](https://arxiv.org/abs/1501.02530)) contains 118,081 short video clips extracted from 202 movies. Each video has a caption, either extracted from the movie script or from transcribed DVS (descriptive video services) for the visually impaired.

> • *TVQA* ([Lei et al. 2018](https://arxiv.org/abs/1809.01696))  / *TVQA+* ([Lei et al. 2019](https://arxiv.org/abs/1904.11574)) is a large-scale video QA dataset based on 6 popular TV shows (Friends, The Big Bang Theory, How I Met Your Mother, House M.D., Grey’s Anatomy, Castle). It consists of 152.5K QA pairs from 21.8K video clips, spanning over 460 hours of video.

> • *DramaQA* ([Choi et al. 2020](https://arxiv.org/abs/2005.03356)) is a large-scale video QA dataset based on a Korean popular TV show, “Another Miss Oh”. This dataset contains four levels of QA on difficulty and multi-level character-centered story descriptions.

> • *VLEP* (Video-and-Language Event Prediction; [Lei et al. 2020](https://arxiv.org/abs/2010.07999)) contains 28,726 future event prediction examples (along with their rationales) from 10,234 diverse TV Show and YouTube Lifestyle Vlog video clips.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2022年6月). 广义视觉语言模型. Lil’Log. https://lilianweng.github.io/posts/2022-06-09-vlm/.

> Weng, Lilian. (Jun 2022). Generalized visual language models. Lil’Log. https://lilianweng.github.io/posts/2022-06-09-vlm/.

或

> Or

```
@article{weng2022vlm,
  title   = "Generalized Visual Language Models",
  author  = "Weng, Lilian",
  journal = "Lil'Log",
  year    = "2022",
  month   = "Jun",
  url     = "https://lilianweng.github.io/posts/2022-06-09-vlm/"
}
```

### 参考文献

> References

[1] Li et al. [“VisualBERT: 视觉与语言的简单高效基线。”](https://arxiv.org/abs/1908.03557) arXiv preprint:1908.03557 (2019)。

> [1] Li et al. [“VisualBERT: A Simple and Performant Baseline for Vision and Language.”](https://arxiv.org/abs/1908.03557) arXiv preprint:1908.03557 (2019).

[2] Wang et al. [“SimVLM: 弱监督下的简单视觉语言模型预训练。”](https://arxiv.org/abs/2108.10904) ICLR 2022。

> [2] Wang et al. [“SimVLM: Simple Visual Language Model Pretraining with Weak Supervision.”](https://arxiv.org/abs/2108.10904) ICLR 2022.

[3] Aghajanyan, et al. [“CM3: 互联网的因果掩码多模态模型。”](https://arxiv.org/abs/2201.07520) arXiv preprint arXiv: 2201.07520 (2022)。

> [3] Aghajanyan, et al. [“CM3: A Causal Masked Multimodal Model of the Internet.”](https://arxiv.org/abs/2201.07520) arXiv preprint arXiv: 2201.07520 (2022).

[4] Tsimpoukelli et al. [“使用冻结语言模型进行多模态少样本学习。”](https://arxiv.org/abs/2106.13884) NeuriPS 2021。

> [4] Tsimpoukelli et al. [“Multimodal Few-Shot Learning with Frozen Language Models.”](https://arxiv.org/abs/2106.13884) NeuriPS 2021.

[5] Mokady, Hertz & Hertz. [“ClipCap: 用于图像字幕的CLIP前缀。”](https://arxiv.org/abs/2111.09734) 2021。

> [5] Mokady, Hertz & Hertz. [“ClipCap: CLIP Prefix for Image Captioning.”](https://arxiv.org/abs/2111.09734) 2021.

[6] Chen et al. [“VisualGPT: 预训练语言模型在图像字幕中的数据高效适应。”](https://arxiv.org/abs/2102.10407) arXiv preprint arXiv:2111.09734 (2021)。

> [6] Chen et al. [“VisualGPT: Data-efficient Adaptation of Pretrained Language Models for Image Captioning.”](https://arxiv.org/abs/2102.10407) arXiv preprint arXiv:2111.09734 (2021).

[7] Luo et al. [“一种令人沮丧的简单端到端图像字幕方法。”](https://arxiv.org/abs/2201.12723) arXiv preprint arXiv:2201.12723 (2022)。

> [7] Luo et al. [“A Frustratingly Simple Approach for End-to-End Image Captioning.”](https://arxiv.org/abs/2201.12723) arXiv preprint arXiv:2201.12723 (2022).

[8] Zellers et al. [“MERLOT: 多模态神经脚本知识模型。”](https://arxiv.org/abs/2106.02636) NeuriPS 2021。

> [8] Zellers et al. [“MERLOT: Multimodal neural script knowledge models.”](https://arxiv.org/abs/2106.02636) NeuriPS 2021.

[9] Alayrac et al. [“Flamingo: 一种用于少样本学习的视觉语言模型。”](https://arxiv.org/abs/2204.14198) arXiv preprint arXiv:2204.14198 (2022)。

> [9] Alayrac et al. [“Flamingo: a Visual Language Model for Few-Shot Learning.”](https://arxiv.org/abs/2204.14198) arXiv preprint arXiv:2204.14198 (2022).

[10] Yu & Wang et al. [“CoCa: 对比式字幕生成器是图像-文本基础模型。”](https://arxiv.org/abs/2205.01917) arXiv preprint arXiv:2205.01917 (2022)。

> [10] Yu & Wang et al. [“CoCa: Contrastive Captioners are Image-Text Foundation Models.”](https://arxiv.org/abs/2205.01917) arXiv preprint arXiv:2205.01917 (2022).

[11] Yang et al. [“GPT-3在少样本基于知识的VQA中的实证研究。”](https://arxiv.org/abs/2109.05014) arXiv preprint arXiv:2109.05014 (2021)。

> [11] Yang et al. [“An Empirical Study of GPT-3 for Few-Shot Knowledge-Based VQA.”](https://arxiv.org/abs/2109.05014) arXiv preprint arXiv:2109.05014 (2021).

[12] Su et al. [“语言模型能看：在文本生成中插入视觉控制。”](https://arxiv.org/abs/2205.02655) arXiv preprint arXiv:2205.02655 (2022)。

> [12] Su et al. [“Language models can see: Plugging visual controls in text generation.”](https://arxiv.org/abs/2205.02655) arXiv preprint arXiv:2205.02655 (2022).

[13] Zeng et al. [“苏格拉底模型：用语言组合零样本多模态推理。”](https://arxiv.org/abs/2204.00598) arXiv preprint arXiv:2204.00598 (2022)。

> [13] Zeng et al. [“Socratic Models: Composing Zero-Shot Multimodal Reasoning with Language.”](https://arxiv.org/abs/2204.00598) arXiv preprint arXiv:2204.00598 (2022).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Visual Language Model (VLM) | 视觉语言模型 | 能够同时处理和理解视觉与语言信息的人工智能模型。 |
| Generalized Language Model (GLM) | 广义语言模型 | 能够处理多种模态输入（如文本、图像）并生成相应输出的语言模型。 |
| Image Captioning | 图像字幕 | 根据图像内容自动生成描述性文本的任务。 |
| Visual Question Answering (VQA) | 视觉问答 | 根据图像和相关问题，生成正确答案的任务。 |
| Visual Encoder | 视觉编码器 | 将图像或视频信息转换为模型可理解的数值表示的组件。 |
| Self-Attention Mechanism | 自注意力机制 | Transformer模型中的一种机制，允许模型在处理序列时权衡不同部分的重要性。 |
| Cross-Attention Mechanism | 交叉注意力机制 | Transformer模型中的一种机制，允许模型在处理一种模态（如文本）时关注另一种模态（如图像）的相关信息。 |
| Prefix Tuning | 前缀微调 | 一种参数高效的微调方法，通过在输入序列前添加可学习的前缀来调整预训练模型。 |
| Prompt Engineering | 提示工程 | 设计和优化输入提示以引导语言模型生成所需输出的技术。 |
| Autoregressive Model | 自回归模型 | 一种序列模型，其当前输出依赖于所有先前的输出。 |
| Masked Language Modeling (MLM) | 掩码语言建模 | 一种预训练任务，模型需要预测输入序列中被遮蔽的词元。 |
| Guided Decoding | 引导式解码 | 在生成文本时，通过外部分数或约束来指导模型选择下一个词元的方法。 |
| Few-shot Learning | 少样本学习 | 模型在只有少量示例的情况下学习新任务的能力。 |
| Zero-shot Learning | 零样本学习 | 模型在没有见过任何示例的情况下执行新任务的能力。 |
| CLIP (Contrastive Language-Image Pre-training) | CLIP（对比语言-图像预训练） | 一种通过对比学习在大量图像-文本对上预训练的模型，能够理解图像和文本之间的语义关系。 |
