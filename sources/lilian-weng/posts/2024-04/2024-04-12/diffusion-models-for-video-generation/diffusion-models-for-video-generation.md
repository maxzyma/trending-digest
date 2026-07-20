# 扩散模型用于视频生成

> Diffusion Models for Video Generation

> 来源：Lil'Log / Lilian Weng，2024-04-12
> 原文链接：https://lilianweng.github.io/posts/2024-04-12-diffusion-video/
> 分类：扩散模型 / 视频生成

## 核心要点

- 扩散模型在图像合成领域取得显著成就后，正被应用于更具挑战性的视频生成任务。
- 视频生成比图像生成更困难，因为它需要帧间时间一致性，且高质量视频数据收集更具挑战性。
- 从零开始设计视频扩散模型通常采用3D U-Net或Transformer架构，并针对时空处理进行修改。
- 另一种方法是通过添加时间层来“膨胀”预训练的图像扩散模型，并在视频数据上进行微调。
- v-预测参数化、重建引导和级联扩散模型等技术被用于提升视频生成质量和分辨率。
- VDM、Imagen Video、Make-A-Video、Tune-A-Video、Gen-1、Video LDM、SVD和Sora等模型展示了不同的架构和训练策略。
- Text2Video-Zero和ControlVideo等方法通过引入运动动力学和跨帧注意力机制，实现了零样本或免训练的视频生成。
- 数据集的精心策划和高质量管理对视频扩散模型的性能至关重要。
- Lumiere模型采用时空U-Net架构，能够一次性生成整个视频长度，从而避免了对时间超分辨率组件的依赖。

## 正文

[扩散模型](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/)在过去几年中在图像合成方面取得了显著成果。现在，研究界已经开始着手一项更具挑战性的任务——将其用于视频生成。这项任务本身是图像情况的超集，因为图像是1帧的视频，而且它更具挑战性，原因如下：

> [Diffusion models](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/) have demonstrated strong results on image synthesis in past years. Now the research community has started working on a harder task—using it for video generation. The task itself is a superset of the image case, since an image is a video of 1 frame, and it is much more challenging because:

1. 它对帧之间的时间一致性有额外的要求，这自然需要将更多的世界知识编码到模型中。
2. 与文本或图像相比，收集大量高质量、高维度的视频数据更加困难，更不用说文本-视频对了。

> • It has extra requirements on temporal consistency across frames in time, which naturally demands more world knowledge to be encoded into the model.
> • In comparison to text or images, it is more difficult to collect large amounts of high-quality, high-dimensional video data, let along text-video pairs.

>
> **🥑 必读预备知识：请确保您已阅读之前关于[“什么是扩散模型？”](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/)的博客，了解图像生成，然后再继续阅读本文。**  
>

>
> **
> 🥑 Required Pre-read: Please make sure you have read the previous blog on [“What are Diffusion Models?”](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/) for image generation before continue here.
> **  
>

### 从零开始的视频生成建模

> Video Generation Modeling from Scratch

首先，我们来回顾一下从头设计和训练扩散视频模型的方法，这意味着我们不依赖预训练的图像生成器。

> First let’s review approaches for designing and training diffusion video models from scratch, meaning that we do not rely on pre-trained image generators.

#### 参数化与采样基础

> Parameterization & Sampling Basics

这里我们使用了与[上一篇文章](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/)略有不同的变量定义，但数学原理保持不变。设$\mathbf{x} \sim q_\text{real}$是从真实数据分布中采样的数据点。现在我们随时间少量添加高斯噪声，创建$\mathbf{x}$的一系列噪声变体，表示为$\{\mathbf{z}_t \mid t =1 \dots, T\}$，随着$t$的增加，噪声量也随之增加，直到最后的$q(\mathbf{z}_T) \sim \mathcal{N}(\mathbf{0}, \mathbf{I})$。添加噪声的前向过程是一个高斯过程。设$\alpha_t, \sigma_t$定义了高斯过程的一个可微分噪声调度：

> Here we use a slightly different variable definition from the [previous post](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/), but the math stays the same. Let $\mathbf{x} \sim q_\text{real}$ be a data point sampled from the real data distribution. Now we are adding Gaussian noise in small amount in time, creating a sequence of noisy variations of $\mathbf{x}$, denoted as $\{\mathbf{z}_t \mid t =1 \dots, T\}$, with increasing amount of noise as $t$ increases and the last $q(\mathbf{z}_T) \sim \mathcal{N}(\mathbf{0}, \mathbf{I})$. The noise-adding forward process is a Gaussian process. Let $\alpha_t, \sigma_t$ define a differentiable noise schedule of the Gaussian process:

$$
q(\mathbf{z}_t \vert \mathbf{x}) = \mathcal{N}(\mathbf{z}_t; \alpha_t \mathbf{x}, \sigma^2_t\mathbf{I})
$$

为了表示 $q(\mathbf{z}_t \vert \mathbf{z}_s)$ 对于 $0 \leq s < t \leq T$，我们有：

> To represent $q(\mathbf{z}_t \vert \mathbf{z}_s)$ for $0 \leq s < t \leq T$, we have:

$$
\begin{aligned}
\mathbf{z}_t &= \alpha_t \mathbf{x} + \sigma_t\boldsymbol{\epsilon}_t \\
\mathbf{z}_s &= \alpha_s \mathbf{x} + \sigma_s\boldsymbol{\epsilon}_s \\
\mathbf{z}_t &= \alpha_t \Big(\frac{\mathbf{z}_s - \sigma_s\boldsymbol{\epsilon}_s}{\alpha_s}\Big) + \sigma_t\boldsymbol{\epsilon}_t \\
\mathbf{z}_t &= \frac{\alpha_t}{\alpha_s}\mathbf{z}_s + \sigma_t\boldsymbol{\epsilon}_t - \frac{\alpha_t\sigma_s}{\alpha_s} \boldsymbol{\epsilon}_s \\
\text{Thus }q(\mathbf{z}_t \vert \mathbf{z}_s) &= \mathcal{N}\Big(\mathbf{z}_t; \frac{\alpha_t}{\alpha_s}\mathbf{z}_s, \big(1 - \frac{\alpha^2_t\sigma^2_s}{\sigma^2_t\alpha^2_s}\big)\sigma^2_t \mathbf{I}\Big)
\end{aligned}
$$

设对数信噪比为 $\lambda_t = \log[\alpha^2_t / \sigma^2_t]$，我们可以将 DDIM ([Song et al. 2020](https://arxiv.org/abs/2010.02502)) 更新表示为：

> Let the log signal-to-noise-ratio be $\lambda_t = \log[\alpha^2_t / \sigma^2_t]$, we can represent the DDIM ([Song et al. 2020](https://arxiv.org/abs/2010.02502)) update as:

$$
q(\mathbf{z}_t \vert \mathbf{z}_s) = \mathcal{N}\Big(\mathbf{z}_t; \frac{\alpha_t}{\alpha_s}\mathbf{z}_s, \sigma^2_{t\vert s} \mathbf{I}\Big) \quad
\text{where }\sigma^2_{t\vert s} = (1 - e^{\lambda_t - \lambda_s})\sigma^2_t
$$

存在一种特殊的 $\mathbf{v}$ -预测 ($\mathbf{v} = \alpha_t \boldsymbol{\epsilon} - \sigma_t \mathbf{x}$) 参数化，由 [Salimans & Ho (2022)](https://arxiv.org/abs/2202.00512) 提出。与 $\boldsymbol{\epsilon}$ -参数化相比，它已被证明有助于避免视频生成中的色彩偏移。

> There is a special $\mathbf{v}$ -prediction ($\mathbf{v} = \alpha_t \boldsymbol{\epsilon} - \sigma_t \mathbf{x}$) parameterization, proposed by [Salimans & Ho (2022)](https://arxiv.org/abs/2202.00512). It has been shown to be helpful for avoiding color shift in video generation compared to $\boldsymbol{\epsilon}$ -parameterization.

$\mathbf{v}$参数化是通过角坐标中的一个技巧推导出来的。首先，我们定义$\phi_t = \arctan(\sigma_t / \alpha_t)$，因此我们有$\alpha_\phi = \cos\phi, \sigma_t = \sin\phi, \mathbf{z}_\phi = \cos\phi \mathbf{x} + \sin\phi\boldsymbol{\epsilon}$。$\mathbf{z}_\phi$的速度可以写成：

> The $\mathbf{v}$ -parameterization is derived with a trick in the angular coordinate. First, we define $\phi_t = \arctan(\sigma_t / \alpha_t)$ and thus we have $\alpha_\phi = \cos\phi, \sigma_t = \sin\phi, \mathbf{z}_\phi = \cos\phi \mathbf{x} + \sin\phi\boldsymbol{\epsilon}$. The velocity of $\mathbf{z}_\phi$ can be written as:

$$
\mathbf{v}_\phi = \nabla_\phi \mathbf{z}_\phi = \frac{d\cos\phi}{d\phi} \mathbf{x} + \frac{d\sin\phi}{d\phi}\boldsymbol{\epsilon} = \cos\phi\boldsymbol{\epsilon} -\sin\phi\mathbf{x}
$$

然后我们可以推断出，

> Then we can infer,

$$
\begin{aligned}
\sin\phi\mathbf{x} 
&= \cos\phi\boldsymbol{\epsilon}  - \mathbf{v}_\phi \\
&= \frac{\cos\phi}{\sin\phi}\big(\mathbf{z}_\phi - \cos\phi\mathbf{x}\big) - \mathbf{v}_\phi \\
\sin^2\phi\mathbf{x} 
&= \cos\phi\mathbf{z}_\phi - \cos^2\phi\mathbf{x} - \sin\phi \mathbf{v}_\phi \\
\mathbf{x} &= \cos\phi\mathbf{z}_\phi - \sin\phi\mathbf{v}_\phi \\
\text{Similarly }
\boldsymbol{\epsilon} &= \sin\phi\mathbf{z}_\phi + \cos\phi \mathbf{v}_\phi
\end{aligned}
$$

DDIM更新规则也相应地进行了更新，

> The DDIM update rule is updated accordingly,

$$
\begin{aligned}
\mathbf{z}_{\phi_s} 
&= \cos\phi_s\hat{\mathbf{x}}_\theta(\mathbf{z}_{\phi_t}) + \sin\phi_s\hat{\epsilon}_\theta(\mathbf{z}_{\phi_t}) \quad\quad{\small \text{; }\hat{\mathbf{x}}_\theta(.), \hat{\epsilon}_\theta(.)\text{ are two models to predict }\mathbf{x}, \boldsymbol{\epsilon}\text{ based on }\mathbf{z}_{\phi_t}}\\
&= \cos\phi_s \big( \cos\phi_t \mathbf{z}_{\phi_t} - \sin\phi_t \hat{\mathbf{v}}_\theta(\mathbf{z}_{\phi_t} ) \big) +
\sin\phi_s \big( \sin\phi_t \mathbf{z}_{\phi_t} + \cos\phi_t \hat{\mathbf{v}}_\theta(\mathbf{z}_{\phi_t} ) \big) \\
&= {\color{red} \big( \cos\phi_s\cos\phi_t + \sin\phi_s\sin\phi_t \big)} \mathbf{z}_{\phi_t} + 
{\color{green} \big( \sin\phi_s \cos\phi_t - \cos\phi_s \sin\phi_t \big)} \hat{\mathbf{v}}_\theta(\mathbf{z}_{\phi_t} ) \\
&= {\color{red} cos(\phi_s - \phi_t)} \mathbf{z}_{\phi_t} +
{\color{green} \sin(\phi_s - \phi_t)} \hat{\mathbf{v}}_\theta(\mathbf{z}_{\phi_t}) \quad\quad{\small \text{; trigonometric identity functions.}}
\end{aligned}
$$

![Visualizing how the diffusion update step works in the angular coordinate, where DDIM evolves $\mathbf{z}_{\phi_s}$ by moving it along the $-\hat{\mathbf{v}}_{\phi_t}$ direction. (Image source: Salimans & Ho, 2022 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/v-param.png)

模型的$\mathbf{v}$参数化是为了预测$\mathbf{v}_\phi = \cos\phi\boldsymbol{\epsilon} -\sin\phi\mathbf{x} = \alpha_t\boldsymbol{\epsilon} - \sigma_t\mathbf{x}$。

> The $\mathbf{v}$ -parameterization for the model is to predict $\mathbf{v}_\phi = \cos\phi\boldsymbol{\epsilon} -\sin\phi\mathbf{x} = \alpha_t\boldsymbol{\epsilon} - \sigma_t\mathbf{x}$.

在视频生成的情况下，我们需要扩散模型运行多步上采样以延长视频长度或增加帧率。这需要能够对第二个视频$\mathbf{x}^b$进行采样，并以第一个视频$\mathbf{x}^a$、$\mathbf{x}^b \sim p_\theta(\mathbf{x}^b \vert \mathbf{x}^a)$为条件，其中$\mathbf{x}^b$可能是$\mathbf{x}^a$的自回归扩展，或者是低帧率视频$\mathbf{x}^a$中缺失的帧。

> In the case of video generation, we need the diffusion model to run multiple steps of upsampling for extending video length or increasing the frame rate. This requires the capability of sampling a second video $\mathbf{x}^b$ conditioned on the first $\mathbf{x}^a$, $\mathbf{x}^b \sim p_\theta(\mathbf{x}^b \vert \mathbf{x}^a)$, where $\mathbf{x}^b$ might be an autoregressive extension of $\mathbf{x}^a$ or be the missing frames in-between for a video $\mathbf{x}^a$ at a low frame rate.

$\mathbf{x}_b$的采样除了其自身对应的噪声变量外，还需要以$\mathbf{x}_a$为条件。**视频扩散模型**（**VDM**；[Ho & Salimans, et al. 2022](https://arxiv.org/abs/2204.03458)）提出了一种*重建引导*方法，该方法使用调整后的去噪模型，使得$\mathbf{x}^b$的采样可以适当地以$\mathbf{x}^a$为条件：

英文原文：The sampling of 

$\mathbf{x}_b$ needs to condition on 

$\mathbf{x}_a$ besides its own corresponding noisy variable. Video Diffusion Models (VDM; [Ho & Salimans, et al. 2022](https://arxiv.org/abs/2204.03458)) proposed the *reconstruction guidance* method using an adjusted denoising model such that the sampling of 

$\mathbf{x}^b$ can be properly conditioned on 

$\mathbf{x}^a$:

$$
\begin{aligned}
\mathbb{E}_q [\mathbf{x}_b \vert \mathbf{z}_t, \mathbf{x}^a] &= \mathbb{E}_q [\mathbf{x}^b \vert \mathbf{z}_t] + \frac{\sigma_t^2}{\alpha_t} \nabla_{\mathbf{z}^b_t} \log q(\mathbf{x}^a \vert \mathbf{z}_t) \\
q(\mathbf{x}^a \vert \mathbf{z}_t) &\approx \mathcal{N}\big[\hat{\mathbf{x}}^a_\theta (\mathbf{z}_t), \frac{\sigma_t^2}{\alpha_t^2}\mathbf{I}\big] & {\small \text{; the closed form is unknown.}}\\
\tilde{\mathbf{x}}^b_\theta (\mathbf{z}_t) &= \hat{\mathbf{x}}^b_\theta (\mathbf{z}_t) - \frac{w_r \alpha_t}{2} \nabla_{\mathbf{z}_t^b} \| \mathbf{x}^a - \hat{\mathbf{x}}^a_\theta (\mathbf{z}_t) \|^2_2 & {\small \text{; an adjusted denoising model for }\mathbf{x}^b}
\end{aligned}
$$

其中$\hat{\mathbf{x}}^a_\theta (\mathbf{z}_t), \hat{\mathbf{x}}^b_\theta (\mathbf{z}_t)$是由去噪模型提供的$\mathbf{x}^a, \mathbf{x}^b$的重建。$w_r$是一个权重因子，并且发现较大的$w_r >1$可以提高样本质量。请注意，也可以使用相同的重建引导方法，同时以低分辨率视频为条件，将样本扩展到高分辨率。

> where $\hat{\mathbf{x}}^a_\theta (\mathbf{z}_t), \hat{\mathbf{x}}^b_\theta (\mathbf{z}_t)$ are reconstructions of $\mathbf{x}^a, \mathbf{x}^b$ provided by the denoising model. And $w_r$ is a weighting factor and a large one $w_r >1$ is found to improve sample quality. Note that it is also possible to simultaneously condition on low resolution videos to extend samples to be at the high resolution using the same reconstruction guidance method.

#### 模型架构：3D U-Net 与 DiT

> Model Architecture: 3D U-Net & DiT

与文本到图像扩散模型类似，U-net和Transformer仍然是两种[常见的架构选择](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture)。Google有一系列基于U-net架构的扩散视频建模论文，而OpenAI最近的Sora模型则利用了Transformer架构。

> Similar to text-to-image diffusion models, U-net and Transformer are still two [common architecture choices](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture). There are a series of diffusion video modeling papers from Google based on the U-net architecture and a recent Sora model from OpenAI leveraged the Transformer architecture.

**VDM**（[Ho & Salimans, et al. 2022](https://arxiv.org/abs/2204.03458)）采用了标准的扩散模型设置，但其架构经过修改以适应视频建模。它将[2D U-net](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture)扩展为适用于3D数据（[Cicek et al. 2016](https://arxiv.org/abs/1606.06650)），其中每个特征图表示一个帧数 x 高度 x 宽度 x 通道的4D张量。这个3D U-net在空间和时间上进行了分解，这意味着每一层只在空间或时间维度上操作，而不是两者兼顾：

> **VDM** ([Ho & Salimans, et al. 2022](https://arxiv.org/abs/2204.03458)) adopts the standard diffusion model setup but with an altered architecture suitable for video modeling. It extends the [2D U-net](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture) to work for 3D data ([Cicek et al. 2016](https://arxiv.org/abs/1606.06650)), where each feature map represents a 4D tensor of frames x height x width x channels. This 3D U-net is factorized over space and time, meaning that each layer only operates on the space or time dimension, but not both:

- 处理*空间*：


   - 2D U-net中的每个旧2D卷积层都被扩展为仅空间3D卷积；具体来说，3x3卷积变为1x3x3卷积。
   - 每个空间注意力块仍然是空间上的注意力，其中第一个轴（`frames`）被视为批处理维度。
- 处理*时间*:


   - 在每个空间注意力块之后添加一个时间注意力块。它对第一个轴（`frames`）执行注意力，并将空间轴视为批处理维度。[相对位置](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#relative-position-encoding)嵌入用于跟踪帧的顺序。时间注意力块对于模型捕获良好的时间连贯性至关重要。

> • Processing *Space*:
>

> ◦ Each old 2D convolution layer as in the 2D U-net is extended to be space-only 3D convolution; precisely, 3x3 convolutions become 1x3x3 convolutions.

> ◦ Each spatial attention block remains as attention over space, where the first axis (`frames`) is treated as batch dimension.

> • Processing *Time*:
>

> ◦ A temporal attention block is added after each spatial attention block. It performs attention over the first axis (`frames`) and treats spatial axes as the batch dimension. The [relative position](https://lilianweng.github.io/posts/2023-01-27-the-transformer-family-v2/#relative-position-encoding) embedding is used for tracking the order of frames. The temporal attention block is important for the model to capture good temporal coherence.

![The 3D U-net architecture. The noisy video $\mathbf{z}_t$ , conditioning information $\boldsymbol{c}$ and the log signal-to-noise ratio (log-SNR) $\lambda_t$ are inputs to the network. The channel multipliers $M_1, \dots, M_K$ represent the channel counts across layers. (Image source: Salimans & Ho, 2022 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/3D-U-net.png)

**Imagen Video**（[Ho 等人，2022](https://arxiv.org/abs/2210.02303)）建立在扩散模型的级联之上，以增强视频生成质量，并升级到以 24 fps 输出 1280x768 视频。Imagen Video 架构由以下组件组成，总计 7 个扩散模型。

> **Imagen Video** ([Ho, et al. 2022](https://arxiv.org/abs/2210.02303)) is constructed on a cascade of diffusion models to enhance the video generation quality and upgrades to output 1280x768 videos at 24 fps. The Imagen Video architecture consists of the following components, counting 7 diffusion models in total.

- 一个冻结的 [T5](https://lilianweng.github.io/posts/2019-01-31-lm/#t5) 文本编码器，用于提供文本嵌入作为条件输入。
- 一个基础视频扩散模型。
- 一个交错的*空间和时间超分辨率*扩散模型级联，包括 3 个 TSR（时间超分辨率）和 3 个 SSR（空间超分辨率）组件。

> • A frozen [T5](https://lilianweng.github.io/posts/2019-01-31-lm/#t5) text encoder to provide text embedding as the conditioning input.
> • A base video diffusion model.
> • A cascade of interleaved *spatial and temporal super-resolution* diffusion models, including 3 TSR (Temporal Super-Resolution) and 3 SSR (Spatial Super-Resolution) components.

![The cascaded sampling pipeline in Imagen Video. In practice, the text embeddings are injected into all components, not just the base model. (Image source: Ho et al. 2022 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/imagen-video.png)

基础去噪模型同时对所有帧执行共享参数的空间操作，然后时间层混合跨帧的激活以更好地捕获时间连贯性，这被发现比帧自回归方法效果更好。

> The base denoising models performs spatial operations over all the frames with shared parameters simultaneously and then the temporal layer mixes activations across frames to better capture temporal coherence, which is found to work better than frame-autoregressive approaches.

![The architecture of one space-time separable block in the Imagen Video diffusion model. (Image source: Ho et al. 2022 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/imagen-video-Unet-block.png)

SSR 和 TSR 模型都以与噪声数据 $\mathbf{z}_t$ 通道级联的上采样输入为条件。SSR 通过[双线性调整大小](https://chao-ji.github.io/jekyll/update/2018/07/19/BilinearResize.html)进行上采样，而 TSR 通过重复帧或填充空白帧进行上采样。

> Both SSR and TSR models condition on the upsampled inputs concatenated with noisy data $\mathbf{z}_t$ channel-wise. SSR upsamples by [bilinear resizing](https://chao-ji.github.io/jekyll/update/2018/07/19/BilinearResize.html), while TSR upsamples by repeating the frames or filling in blank frames.

Imagen Video 还应用了[渐进式蒸馏](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#prog-distll)来加速采样，每次蒸馏迭代可以将所需的采样步骤减少一半。他们的实验能够将所有 7 个视频扩散模型蒸馏到每个模型仅需 8 个采样步骤，而感知质量没有明显损失。

> Imagen Video also applies [progressive distillation](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#prog-distll) to speed up sampling and each distillation iteration can reduce the required sampling steps by half. Their experiments were able to distill all 7 video diffusion models down to just 8 sampling steps per model without any noticeable loss in perceptual quality.

为了实现更好的扩展效果，**Sora**（[Brooks 等人，2024](https://openai.com/research/video-generation-models-as-world-simulators)）利用了[DiT（扩散 Transformer）](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture)架构，该架构对视频和图像潜在代码的时空补丁进行操作。视觉输入被表示为时空补丁序列，这些补丁充当 Transformer 输入令牌。

> To achieve better scaling efforts, **Sora** ([Brooks et al. 2024](https://openai.com/research/video-generation-models-as-world-simulators)) leverages [DiT (Diffusion Transformer)](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#model-architecture) architecture that operates on spacetime patches of video and image latent codes. Visual input is represented as a sequence of spacetime patches which act as Transformer input tokens.

![Sora is a diffusion transformer model. (Image source: Brooks et al. 2024 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/sora.png)

### 调整图像模型以生成视频

> Adapting Image Models to Generate Videos

扩散视频建模的另一个突出方法是通过插入时间层来“膨胀”预训练的图像到文本扩散模型，然后我们可以选择*只*在视频数据上微调新层，或者完全避免额外的训练。文本-图像对的先验知识被新模型继承，因此这有助于减轻对文本-视频对数据的要求。

> Another prominent approach for diffusion video modeling is to “inflate” a pre-trained image-to-text diffusion model by inserting temporal layers and then we can choose to *only* fine-tune new layers on video data, or avoid extra training at all. The prior knowledge of text-image pairs is inherited by the new model and thus it can help alleviate the requirement on text-video pair data.

#### 在视频数据上进行微调

> Fine-tuning on Video Data

**Make-A-Video** ([Singer 等人，2022](https://arxiv.org/abs/2209.14792)) 通过增加时间维度扩展了预训练的扩散图像模型，该模型包含三个关键组件：

> **Make-A-Video** ([Singer et al. 2022](https://arxiv.org/abs/2209.14792)) extends a pre-trained diffusion image model with a temporal dimension, consisting of three key components:

1. 一个基于文本-图像对数据训练的基础文本到图像模型。
2. 时空卷积和注意力层，用于将网络扩展到覆盖时间维度。
3. 一个用于高帧率生成的帧插值网络

> • A base text-to-image model trained on text-image pair data.
> • Spatiotemporal convolution and attention layers to extend the network to cover temporal dimension.
> • A frame interpolation network for high frame rate generation

![The illustration of Make-A-Video pipeline. (Image source: Singer et al. 2022 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/make-a-video.png)

最终的视频推理方案可以表述为：

> The final video inference scheme can be formulated as:

$$
\hat{\mathbf{y}}_t = \text{SR}_h \circ \text{SR}^t_l \circ \uparrow_F \circ D^t \circ P \circ (\hat{\mathbf{x}}, \text{CLIP}_\text{text}(\mathbf{x}))
$$

其中：

> where:

• $\mathbf{x}$ 是输入文本。

• $\hat{\mathbf{x}}$ 是 BPE 编码的文本。

• $\text{CLIP}_\text{text}(.)$ 是 CLIP 文本编码器，$\mathbf{x}_e = \text{CLIP}_\text{text}(\mathbf{x})$。

• $P(.)$ 是先验模型，生成图像嵌入 $\mathbf{y}_e$，给定文本嵌入 $\mathbf{x}_e$ 和 BPE 编码文本 $\hat{\mathbf{x}}$：$\mathbf{y}_e = P(\mathbf{x}_e, \hat{\mathbf{x}})$。这部分在文本-图像对数据上进行训练，未在视频数据上进行微调。

• $D^t(.)$ 是时空解码器，生成一系列 16 帧，其中每一帧都是低分辨率的 64x64 RGB 图像 $\hat{\mathbf{y}}_l$。

• $\uparrow_F(.)$ 是帧插值网络，通过在生成的帧之间进行插值来提高有效帧率。这是一个经过微调的模型，用于预测视频超分辨率中被遮蔽帧的任务。

• $\text{SR}_h(.), \text{SR}^t_l(.)$ 是空间和时空超分辨率模型，分别将图像分辨率提高到 256x256 和 768x768。

• $\hat{\mathbf{y}}_t$ 是最终生成的视频。

英文原文：

• $\mathbf{x}$ is the input text.

• $\hat{\mathbf{x}}$ is the BPE-encoded text.

• $\text{CLIP}_\text{text}(.)$ is the CLIP text encoder, $\mathbf{x}_e = \text{CLIP}_\text{text}(\mathbf{x})$.

• $P(.)$ is the prior, generating image embedding $\mathbf{y}_e$ given text embedding $\mathbf{x}_e$ and BPE encoded text $\hat{\mathbf{x}}$ : $\mathbf{y}_e = P(\mathbf{x}_e, \hat{\mathbf{x}})$. This part is trained on text-image pair data and not fine-tuned on video data.

• $D^t(.)$ is the spatiotemporal decoder that generates a series of 16 frames, where each frame is a low-resolution 64x64 RGB image $\hat{\mathbf{y}}_l$.

• $\uparrow_F(.)$ is the frame interpolation network, increasing the effective frame rate by interpolating between generated frames. This is a fine-tuned model for the task of predicting masked frames for video upsampling.

• $\text{SR}_h(.), \text{SR}^t_l(.)$ are the spatial and spatiotemporal super-resolution models, increasing the image resolution to 256x256 and 768x768, respectively.

• $\hat{\mathbf{y}}_t$ is the final generated video.

时空 SR 层包含伪 3D 卷积层和伪 3D 注意力层：

> Spatiotemporal SR layers contain pseudo-3D convo layers and pseudo-3D attention layers:

- 伪 3D 卷积层：每个空间 2D 卷积层（从预训练图像模型初始化）后接一个时间 1D 层（初始化为恒等函数）。概念上，2D 卷积层首先生成多个帧，然后将这些帧重塑为视频片段。
- 伪 3D 注意力层：在每个（预训练的）空间注意力层之后，堆叠一个时间注意力层，用于近似一个完整的时空注意力层。

> • Pseudo-3D convo layer : Each spatial 2D convo layer (initialized from the pre-training image model) is followed by a temporal 1D layer (initialized as the identity function). Conceptually, the convo 2D layer first generates multiple frames and then frames are reshaped to be a video clip.
> • Pseudo-3D attention layer: Following each (pre-trained) spatial attention layer, a temporal attention layer is stacked and used to approximate a full spatiotemporal attention layer.

![How pseudo-3D convolution (left) and attention (right) layers work. (Image source: Singer et al. 2022 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/make-a-video-layers.png)

它们可以表示为：

> They can be represented as:

$$
\begin{aligned}
\text{Conv}_\text{P3D} &= \text{Conv}_\text{1D}(\text{Conv}_\text{2D}(\mathbf{h}) \circ T) \circ T \\
\text{Attn}_\text{P3D} &= \text{flatten}^{-1}(\text{Attn}_\text{1D}(\text{Attn}_\text{2D}(\text{flatten}(\mathbf{h})) \circ T) \circ T)
\end{aligned}
$$

其中输入张量 $\mathbf{h} \in \mathbb{R}^{B\times C \times F \times H \times W}$（对应于批大小、通道、帧、高度和宽度）；$\circ T$ 在时间维度和空间维度之间进行交换；$\text{flatten}(.)$ 是一个矩阵运算符，用于将 $\mathbf{h}$ 转换为 $\mathbf{h}’ \in \mathbb{R}^{B \times C \times F \times HW}$，而 $\text{flatten}^{-1}(.)$ 则反转该过程。

> where an input tensor $\mathbf{h} \in \mathbb{R}^{B\times C \times F \times H \times W}$  (corresponding to batch size, channels, frames, height and weight); and $\circ T$ swaps between temporal and spatial dimensions; $\text{flatten}(.)$ is a matrix operator to convert $\mathbf{h}$ to be $\mathbf{h}’ \in \mathbb{R}^{B \times C \times F \times HW}$ and $\text{flatten}^{-1}(.)$ reverses that process.

在训练期间，Make-A-Video 流水线的不同组件是独立训练的。

> During training, different components of Make-A-Video pipeline are trained independently.

1\. 解码器 $D^t$、先验 $P$ 和两个超分辨率组件 $\text{SR}_h, \text{SR}^t_l$ 首先单独在图像上进行训练，不使用配对文本。

2\. 接下来，新的时间层被添加，初始化为恒等函数，然后在未标记的视频数据上进行微调。

英文原文：

1\. Decoder $D^t$, prior $P$ and two super-resolution components $\text{SR}_h, \text{SR}^t_l$ are first trained on images alone, without paired text.

2\. Next the new temporal layers are added, initialized as identity function, and then fine-tuned on unlabeled video data.

**Tune-A-Video**（[Wu et al. 2023](https://openaccess.thecvf.com/content/ICCV2023/html/Wu_Tune-A-Video_One-Shot_Tuning_of_Image_Diffusion_Models_for_Text-to-Video_Generation_ICCV_2023_paper.html)）通过膨胀预训练图像扩散模型来实现单次视频微调：给定一个包含`m`帧的视频，$\mathcal{V} = \{v_i \mid i = 1, \dots, m\}$，并配有一个描述性提示词`\tau`，任务是生成一个新视频$\mathcal{V}^{\ast}$，基于一个略微编辑且相关的文本提示词$\tau^{\ast}$。例如，`\tau` = `"A man is skiing"`可以扩展为$\tau^{\ast}$ = `"Spiderman is skiing on the beach"`。Tune-A-Video 旨在用于对象编辑、背景更改和风格迁移。

英文原文：Tune-A-Video ([Wu et al. 2023](https://openaccess.thecvf.com/content/ICCV2023/html/Wu_Tune-A-Video_One-Shot_Tuning_of_Image_Diffusion_Models_for_Text-to-Video_Generation_ICCV_2023_paper.html)) inflates a pre-trained image diffusion model to enable one-shot video tuning: Given a video containing `m` frames, 

$\mathcal{V} = \{v_i \mid i = 1, \dots, m\}$, paired with a descriptive prompt `\tau`, the task is to generate a new video 

$\mathcal{V}^{\ast}$ based on a slightly edited & related text prompt 

$\tau^{\ast}$. For example, `\tau` = `"A man is skiing"` can be extended to 

$\tau^{\ast}$=`"Spiderman is skiing on the beach"`. Tune-A-Video is meant to be used for object editing, background change, and style transfer.

除了膨胀2D卷积层，Tune-A-Video的U-Net架构还结合了ST-Attention（时空注意力）块，通过查询先前帧中的相关位置来捕获时间一致性。给定帧$v_i$的潜在特征，将先前帧$v_{i-1}$和第一帧$v_1$投影到查询$\mathbf{Q}$、键$\mathbf{K}$和值$\mathbf{V}$，ST-attention定义为：

> Besides inflating the 2D convo layer, the U-Net architecture of Tune-A-Video incorporates the ST-Attention (spatiotemporal attention) block to capture temporal consistency by querying relevant positions in previous frames. Given latent features of frame $v_i$, previous frames $v_{i-1}$ and the first frame $v_1$ are projected to query $\mathbf{Q}$, key $\mathbf{K}$ and value $\mathbf{V}$, the ST-attention is defined as:

$$
\begin{aligned}
&\mathbf{Q} = \mathbf{W}^Q \mathbf{z}_{v_i}, \quad \mathbf{K} = \mathbf{W}^K [\mathbf{z}_{v_1}, \mathbf{z}_{v_{i-1}}], \quad \mathbf{V} = \mathbf{W}^V [\mathbf{z}_{v_1}, \mathbf{z}_{v_{i-1}}] \\
&\mathbf{O} = \text{softmax}\Big(\frac{\mathbf{Q} \mathbf{K}^\top}{\sqrt{d}}\Big) \cdot \mathbf{V}
\end{aligned}
$$

![The Tune-A-Video architecture overview. It first runs a light-weighted fine-tuning stage on a single video before the sampling stage. Note that the entire temporal self-attention (T-Attn) layers get fine-tuned because they are newly added, but only query projections in ST-Attn and Cross-Attn are updated during fine-tuning to preserve prior text-to-image knowledge. ST-Attn improves spatial-temporal consistency, Cross-Attn refines text-video alignment. (Image source: Wu et al. 2023 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/tune-a-video.png)

**Gen-1** 模型（[Esser 等人 2023](https://arxiv.org/abs/2302.03011)）由 Runway 推出，旨在根据文本输入编辑给定视频。它将视频的*结构*和*内容*的考量$p(\mathbf{x} \mid s, c)$分解，用于生成条件。然而，要清晰地分解这两个方面并不容易。

英文原文：Gen-1 model  ([Esser et al. 2023](https://arxiv.org/abs/2302.03011)) by Runway targets the task of editing a given video according to text inputs. It decomposes the consideration of *structure* and *content* of a video 

$p(\mathbf{x} \mid s, c)$ for generation conditioning. However, to do a clear decomposition of these two aspects is not easy.

• *内容* $c$ 指的是视频的外观和语义，这些是从文本中采样用于条件编辑的。帧的 CLIP 嵌入是内容的良好表示，并且在很大程度上与结构特征正交。

• *结构* $s$ 描绘了几何和动态，包括物体的形状、位置、时间变化，并且 $s$ 是从输入视频中采样的。可以使用深度估计或其他特定任务的辅助信息（例如，用于人类视频合成的人体姿态或面部地标）。

英文原文：

• *Content* $c$ refers to appearance and semantics of the video, that is sampled from the text for conditional editing. CLIP embedding of the frame is a good representation of content, and stays largely orthogonal to structure traits.

• *Structure* $s$ depicts greometry and dynamics, including shapes, locations, temporal changes of objects, and $s$ is sampled from the input video. Depth estimation or other task-specific side information (e.g. human body pose or face landmarks for human video synthesis) can be used.

Gen-1 中的架构变化相当标准，即在其残差块中每个 2D 空间卷积层之后添加 1D 时间卷积层，并在其注意力块中每个 2D 空间注意力块之后添加 1D 时间注意力块。在训练期间，结构变量 $s$ 与扩散潜在变量 $\mathbf{z}$ 连接，其中内容变量 $c$ 在交叉注意力层中提供。在推理时，通过先验将 CLIP 嵌入转换为 CLIP 图像嵌入，以将 CLIP 文本嵌入转换为 CLIP 图像嵌入。

> The architecture changes in Gen-1 are quite standard, i.e. adding 1D temporal convo layer after each 2D spatial convo layer in its residual blocks and adding 1D temporal attention block after each 2D spatial attention block in its attention blocks. During training, the structure variable $s$ is concatenated with the diffusion latent variable $\mathbf{z}$, where the content variable $c$ is provided in the cross-attention layer. At inference time, the clip embedding is converted via a prior to convert CLIP text embedding to be CLIP image embedding.

![The overview of the Gen-1 model training pipeline. (Image source: Esser et al. 2023 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/gen-1.png)

**视频 LDM** ([Blattmann 等人 2023](https://arxiv.org/abs/2304.08818)) 首先训练一个 [LDM](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#latent-variable-space)（潜在扩散模型）图像生成器。然后对模型进行微调，以生成添加了时间维度的视频。微调仅应用于编码图像序列上这些新添加的时间层。视频 LDM 中的时间层 $\{l^i_\phi \mid i = \ 1, \dots, L\}$（参见图 10）与现有的空间层 $l^i_\theta$ 交错排列，这些空间层在微调期间保持 *冻结*。也就是说，我们只微调新参数 `\phi`，而不微调预训练的图像骨干模型参数 `\theta`。视频 LDM 的流程是首先以低帧率生成关键帧，然后通过 2 步潜在帧插值来提高帧率。

英文原文：Video LDM ([Blattmann et al. 2023](https://arxiv.org/abs/2304.08818)) trains a [LDM](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#latent-variable-space) (Latent diffusion models) image generator first. Then the model is fine-tuned to produce videos with a temporal dimension added. The fine-tuning only applies to these newly added temporal layers on encoded image sequences. The temporal layers 

$\{l^i_\phi \mid i = \ 1, \dots, L\}$ in the Video LDM (See Fig. 10) are interleaved with existing spatial layers 

$l^i_\theta$ which stays *frozen* during fine-tuning. That’s being said, we only fine-tune the new parameters `\phi` but not the pre-trained image backbone model parameters `\theta`. The pipeline of Video LDM first generates key frames at low fps and then processes through 2 steps of latent frame interpolations to increase fps.

长度为$T$被解释为一批图像（即$B \cdot T$）用于基础图像模型$\theta$，然后被重塑为视频格式，用于$l^i_\phi$个时间层。存在一个跳跃连接，它将时间层输出$\mathbf{z}’$与空间输出$\mathbf{z}$通过一个学习到的合并参数$\alpha$。实践中实现了两种类型的时间混合层：（1）时间注意力机制和（2）基于3D卷积的残差块。

> The input sequence of length $T$ is interpreted as a batch of images (i.e. $B \cdot T$) for the base image model $\theta$ and then gets reshaped into video format for $l^i_\phi$ temporal layers. There is a skip connection leads to a combination of temporal layer output $\mathbf{z}’$ and the spatial output $\mathbf{z}$ via a learned merging parameter $\alpha$. There are two types of temporal mixing layers implemented in practice: (1) temporal attention and (2) residual blocks based on 3D convolutions.

![A pre-training LDM for image synthesis is extended to be a video generator. $B, T, C, H, W$ are batch size, sequence length, channels, height and width, respectively. $\mathbf{c}_S$ is an optional conditioning/context frame. (Image source: Blattmann et al. 2023 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/video-LDM.png)

然而，LDM 的预训练自编码器存在一个遗留问题，它只处理图像，从未处理过视频。天真地将其用于视频生成可能会导致闪烁伪影，缺乏良好的时间连贯性。因此，Video LDM 在解码器中添加了额外的时间层，并使用由 3D 卷积构建的逐块时间判别器在视频数据上进行了微调，而编码器保持不变，以便我们仍然可以重用预训练的 LDM。在时间解码器微调期间，冻结的编码器独立处理视频中的每一帧，并使用视频感知判别器强制实现跨帧的时间连贯重建。

> However, there is a remaining issue with LDM’s pretrainined autoencoder which only sees images never videos. Naively using that for video generation can cause flickering artifacts without good temporal coherence. So Video LDM adds additional temporal layers into the decoder and fine-tuned on video data with a patch-wise temporal discriminator built from 3D convolutions, while the encoder remains unchanged so that we still can reuse the pretrained LDM. During temporal decoder fine-tuning, the frozen encoder processes each frame in the video independently, and enforce temporally coherent reconstructions across frames with a video-aware discriminator.

![The training pipeline of autoencoder in video latent diffusion models. The decoder is fine-tuned to have temporal coherency with a new across-frame discriminator while the encoder stays frozen. (Image source: Blattmann et al. 2023 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/video-LDM-autoencoder.png)

与Video LDM类似，**Stable Video Diffusion**（**SVD**；[Blattmann et al. 2023](https://arxiv.org/abs/2311.15127)）的架构设计也基于LDM，并在每个空间卷积和注意力层之后插入了时间层，但SVD对整个模型进行了微调。视频LDM的训练分为三个阶段：

> Similar to Video LDM, the architecture design of **Stable Video Diffusion** (**SVD**; [Blattmann et al. 2023](https://arxiv.org/abs/2311.15127)) is also based on LDM with temporal layers inserted after every spatial convolution and attention layer, but SVD fine-tunes the entire model. There are three stages for training video LDMs:

1. *文本到图像预训练*很重要，有助于提高质量和提示遵循能力。
2. *视频预训练*最好是单独进行，并且理想情况下应在一个更大规模、经过精心策划的数据集上进行。
3. *高质量视频微调*适用于较小规模、预先标注且视觉保真度高的视频。

> • *Text-to-image pretraining* is important and helps improve both quality and prompt following.
> • *Video pretraining* is beneficial to be separated and should ideally occur on a larger scale, curated dataset.
> • *High-quality video finetuning* works with a smaller, pre-captioned video of high visual fidelity.

SVD 特别强调了*数据集管理*在模型性能中的关键作用。他们应用了剪辑检测管道来获取每个视频的更多剪辑，然后应用了三种不同的字幕模型：(1) CoCa 用于中帧，(2) V-BLIP 用于视频字幕，以及 (3) 基于前两个字幕的 LLM 字幕生成。然后，他们通过移除运动较少的片段（通过以 2 fps 计算的低光流分数进行过滤）、文本过多（应用光学字符识别来识别包含大量文本的视频），或普遍审美价值较低（使用 CLIP 嵌入注释每个片段的第一帧、中间帧和最后一帧，并计算美学分数&文本-图像相似度）来持续改进视频数据集。实验表明，经过过滤的、更高质量的数据集能够带来更好的模型质量，即使该数据集小得多。

> SVD specially emphasizes the critical role of *dataset curation* in model performance. They applied a cut detection pipeline to get more cuts per video and then applied three different captioner models: (1) CoCa for mid-frame, (2) V-BLIP for a video caption, and (3) LLM based captioning based on previous two captions. Then they were able to continue to improve video datasets, by removing clips with less motion (filtered by low optical flow scores calculated at 2 fps), excessive text presence (apply optical character recognition to identify videos with lots of text), or generally low aesthetic value (annotate the first, middle, and last frames of each clip with CLIP embeddings and calculate aesthetics scores & text-image similarities). The experiments showed that a filtered, higher quality dataset leads to better model quality, even when this dataset is much smaller.

首先生成远距离关键帧，然后通过时间超分辨率添加插值，其关键挑战是如何保持高质量的时间一致性。**Lumiere** ([Bar-Tal et al. 2024](https://arxiv.org/abs/2401.12945)) 则采用了一种**时空U-Net (STUNet)** 架构，通过*一次性*生成视频的整个时间长度，从而消除了对TSR（时间超分辨率）组件的依赖。STUNet 在时间和空间维度上对视频进行下采样，因此昂贵的计算发生在紧凑的时空潜在空间中。

> The key challenge of generating distant key frames first and then adding interpolation with temporal super-resolution is how to maintain high-quality temporal consistency. **Lumiere** ([Bar-Tal et al. 2024](https://arxiv.org/abs/2401.12945)) instead adopts a **space-time U-Net (STUNet)** architecture that generates the entire temporal duration of the video *at once* through a single pass, removing the dependency on TSR (temporal super-resolution) components. STUNet downsamples the video in both time and space dimensions and thus expensive computation happens in a compact time-space latent space.

![Lumiere removes TSR (temporal super-resolution) models. The inflated SSR network can operate only on short segments of the video due to memory constraints and thus SSR models operate on a set of shorter but overlapped video snippets. (Image source: Bar-Tal et al. 2024 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/lumiere.png)

STUNet 扩展了一个*预训练的*文本到图像U-net，使其能够在时间和空间维度上对视频进行下采样和上采样。基于卷积的块由预训练的文本到图像层组成，然后是分解的时空卷积。而U-Net最粗糙层级的基于注意力的块包含预训练的文本到图像，然后是时间注意力。进一步的训练*只*发生在新增的层上。

> STUNet inflates a *pretrained* text-to-image U-net to be able to downsample and upsample videos at both time and space dimensions. Convo-based blocks consist of pre-trained text-to-image layers, followed by a factorized space-time convolution. And attention-based blocks at the coarsest U-Net level contains the pre-trained text-to-image, followed by temporal attention. Further training *only* happens with the newly added layers.

![The architecture of (a) Space-Time U-Net (STUNet), (b) the convolution-based block, and (c) the attention-based block. (Image source: Bar-Tal et al. 2024 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/lumiere-STUnet.png)

#### 训练免调优适应

> Training-Free Adaptation

令人惊讶的是，无需任何训练，就可以使预训练的文本到图像模型输出视频 🤯。

> Somehow surprisingly, it is possible to adapt a pre-trained text-to-image model to output videos without any training 🤯.

如果我们随机地简单采样一系列潜在编码，然后构建一个由解码后的对应图像组成的视频，则无法保证物体和语义在时间上的一致性。**Text2Video-Zero** ([Khachatryan et al. 2023](https://arxiv.org/abs/2303.13439)) 通过用两个关键的时间一致性机制增强预训练图像扩散模型，实现了零样本、免训练的视频生成：

> If we naively sample a sequence of latent codes at random and then construct a video of decoded corresponding images, there is no guarantee in the consistency in objects and semantics in time. **Text2Video-Zero** ([Khachatryan et al. 2023](https://arxiv.org/abs/2303.13439)) enables zero-shot, training-free video generation by enhancing a pre-trained image diffusion model with two key mechanisms for temporal consistency:

1. 通过*运动动力学*采样潜在编码序列，以保持全局场景和背景的时间一致性；
2. 使用*新的跨帧注意力机制*（即每帧对第一帧的注意力）重新编程帧级自注意力，以保留前景物体的上下文、外观和身份。

> • Sampling the sequence of latent codes with *motion dynamics* to keep the global scene and the background time consistent;
> • Reprogramming frame-level self-attention using a *new cross-frame attention* of each frame on the first frame, to preserve the context, appearance, and identity of the foreground object.

![An overview of the Text2Video-Zero pipeline. (Image source: Khachatryan et al. 2023 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/text2video-zero.png)

采样带有运动信息的潜在变量序列$\mathbf{x}^1_T, \dots, \mathbf{x}^m_T$的过程描述如下：

> The process of sampling a sequence of latent variables, $\mathbf{x}^1_T, \dots, \mathbf{x}^m_T$, with motion information is described as follows:

1\. 定义一个方向$\boldsymbol{\delta} = (\delta_x, \delta_y) \in \mathbb{R}^2$来控制全局场景和摄像机运动；默认情况下，我们设置$\boldsymbol{\delta} = (1, 1)$。同时定义一个超参数$\lambda > 0$来控制全局运动的量。

2\. 首先随机采样第一帧的潜在编码$\mathbf{x}^1_T \sim \mathcal{N}(0, I)$；

3\. 使用预训练图像扩散模型（例如论文中的Stable Diffusion (SD) 模型）执行$\Delta t \geq 0$次DDIM反向更新步骤，并获得相应的潜在编码$\mathbf{x}^1_{T’}$，其中$T’ = T - \Delta t$。

4\. 对于潜在编码序列中的每一帧，我们应用由$\boldsymbol{\delta}^k = \lambda(k-1)\boldsymbol{\delta}$定义的形变操作进行相应的运动平移，以获得$\tilde{\mathbf{x}}^k_{T’}$。

5\. 最后，对所有$\tilde{\mathbf{x}}^{2:m}_{T’}$应用DDIM正向步骤，以获得$\mathbf{x}^{2:m}_T$。

英文原文：

1\. Define a direction $\boldsymbol{\delta} = (\delta_x, \delta_y) \in \mathbb{R}^2$ for controlling the global scene and camera motion; by default, we set $\boldsymbol{\delta} = (1, 1)$. Also define a hyperparameter $\lambda > 0$ controlling the amount of global motion.

2\. First sample the latent code of the first frame at random, $\mathbf{x}^1_T \sim \mathcal{N}(0, I)$;

3\. Perform $\Delta t \geq 0$ DDIM backward update steps using the pre-trained image diffusion model, e.g. Stable Diffusion (SD) model in the paper, and obtain the corresponding latent code $\mathbf{x}^1_{T’}$ where $T’ = T - \Delta t$.

4\. For each frame in the latent code sequence, we apply corresponding motion translation with a warping operation defined by $\boldsymbol{\delta}^k = \lambda(k-1)\boldsymbol{\delta}$ to obtain $\tilde{\mathbf{x}}^k_{T’}$.

5\. Finally apply DDIM forward steps to all $\tilde{\mathbf{x}}^{2:m}_{T’}$ to obtain $\mathbf{x}^{2:m}_T$.

$$
\begin{aligned}
\mathbf{x}^1_{T'} &= \text{DDIM-backward}(\mathbf{x}^1_T, \Delta t)\text{ where }T' = T - \Delta t \\
W_k &\gets \text{a warping operation of }\boldsymbol{\delta}^k = \lambda(k-1)\boldsymbol{\delta} \\
\tilde{\mathbf{x}}^k_{T'} &= W_k(\mathbf{x}^1_{T'})\\
\mathbf{x}^k_T &= \text{DDIM-forward}(\tilde{\mathbf{x}}^k_{T'}, \Delta t)\text{ for }k=2, \dots, m
\end{aligned}
$$

此外，Text2Video-Zero 将预训练SD模型中的自注意力层替换为一种新的跨帧注意力机制，该机制参考*第一*帧。这样做的动机是为了在生成的视频中保留前景物体的外观、形状和身份信息。

> Besides, Text2Video-Zero replaces the self-attention layer in a pre-trained SD model with a new cross-frame attention mechanism with reference to the *first* frame. The motivation is to preserve the information about the foreground object’s appearance, shape, and identity throughout the generated video.

$$
\text{Cross-Frame-Attn}(\mathbf{Q}^k, \mathbf{K}^{1:m}, \mathbf{V}^{1:m}) = \text{Softmax}\Big( \frac{\mathbf{Q}^k (\mathbf{K}^1)^\top}{\sqrt{c}} \Big) \mathbf{V}^1
$$

可选地，背景掩码可用于进一步平滑并改善背景一致性。假设我们获得了一个相应的前景掩码$\mathbf{M}_k$用于第$k$帧，使用某种现有方法，并且背景平滑在扩散步骤$t$，相对于背景矩阵：

> Optionally, the background mask can be used to further smoothen and improve background consistency. Let’s say, we obtain a corresponding foreground mask $\mathbf{M}_k$ for the $k$ -th frame using some existing method, and background smoothing merges the actual and the warped latent code at the diffusion step $t$, w.r.t. the background matrix:

$$
\bar{\mathbf{x}}^k_t = \mathbf{M}^k \odot \mathbf{x}^k_t + (1 − \mathbf{M}^k) \odot (\alpha\tilde{\mathbf{x}}^k_t +(1−\alpha)\mathbf{x}^k_t)\quad\text{for }k=1, \dots, m
$$

其中$\mathbf{x}^k_t$是实际的潜在代码，$\tilde{\mathbf{x}}^k_t$是背景上扭曲的潜在代码；$\alpha$是一个超参数，论文在实验中设置$\alpha=0.6$。

> where $\mathbf{x}^k_t$ is the actual latent code and $\tilde{\mathbf{x}}^k_t$ is the warped latent code on the background; $\alpha$ is a hyperparameter and the papers set $\alpha=0.6$ in the experiments.

Text2video-zero 可以与 [ControlNet](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#controlnet) 结合使用，其中 ControlNet 预训练的复制分支在每个帧上应用于每个 $\mathbf{x}^k_t$，用于 $k = 1, \dots, m$ 在每个扩散时间步 $t = T , \dots, 1$，并将 ControlNet 分支的输出添加到主 U-net 的跳跃连接中。

> Text2video-zero can be combined with [ControlNet](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#controlnet) where the ControlNet pretrained copy branch is applied per frame on each $\mathbf{x}^k_t$ for $k = 1, \dots, m$ in each diffusion time-step $t = T , \dots, 1$ and add the ControlNet branch outputs to the skip-connections of the main U-net.

**ControlVideo** ([Zhang et al. 2023](https://arxiv.org/abs/2305.13077)) 旨在生成以文本提示 `\tau` 和运动序列（例如，深度图或边缘图）为条件的视频 $\mathbf{c} = \{c^i\}_{i=0}^{N-1}$。它是在 [ControlNet](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#controlnet) 的基础上进行改编的，并增加了三种新机制：

英文原文：ControlVideo ([Zhang et al. 2023](https://arxiv.org/abs/2305.13077)) aims to generate videos conditioned on text prompt `\tau` and a motion sequence (e.g., depth or edge maps), 

$\mathbf{c} = \{c^i\}_{i=0}^{N-1}$. It is adapted from [ControlNet](https://lilianweng.github.io/posts/2021-07-11-diffusion-models/#controlnet) with three new mechanisms added:

1\. *跨帧注意力*：在自注意力模块中添加了完全的跨帧交互。它通过将 *所有时间步* 的潜在帧映射到 $\mathbf{Q}, \mathbf{K}, \mathbf{V}$ 矩阵中，引入了所有帧之间的交互，这与 Text2Video-zero 不同，后者只配置所有帧关注 *第一* 帧。

2\. *交错帧平滑器* 是一种对交替帧进行帧插值以减少闪烁效应的机制。在每个时间步 $t$，平滑器会插值偶数帧或奇数帧，以平滑它们对应的三帧片段。请注意，在平滑步骤后，帧数会随时间减少。

3\. *分层采样器*利用分层采样器，在内存限制下实现具有时间一致性的长视频。长视频被分割成多个短片段，每个片段都选择一个关键帧。模型预先生成这些关键帧，并采用完整的跨帧注意力以实现长期连贯性，然后依次合成每个对应的短片段，并以关键帧为条件。

英文原文：

1\. *Cross-frame attention*: Adds fully cross-frame interaction in self-attention modules. It introduces interactions between all the frames, by mapping the latent frames at *all the time steps* into $\mathbf{Q}, \mathbf{K}, \mathbf{V}$ matrices, different from Text2Video-zero which only configures all the frames to attend to the *first* frame.

2\. *Interleaved-frame smoother* is a mechanism to employ frame interpolation on alternated frames to reduce the flickering effect. At each time step $t$, the smoother interpolates the even or odd frames to smooth their corresponding three-frame clips. Note that the number of frames decreases in time after smoothing steps.

3\. *Hierarchical sampler* utilizes a hierarchical sampler to enable long videos with time consistency under memory constraints. A long video is split into multiple short clips and each has a key frame selected. The model pre-generates these keyframes with full cross-frame attention for long-term coherency and each corresponding short clip is synthesized sequentially conditioned on the keyframes.

![The overview of ControlVideo. (Image source: Zhang et al. 2023 )](https://lilianweng.github.io/posts/2024-04-12-diffusion-video/control-video.png)

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (Apr 2024). Diffusion Models Video Generation. Lil’Log. https://lilianweng.github.io/posts/2024-04-12-diffusion-video/.

> Weng, Lilian. (Apr 2024). Diffusion Models Video Generation. Lil’Log. https://lilianweng.github.io/posts/2024-04-12-diffusion-video/.

或

> Or

```
@article{weng2024video,
  title   = "Diffusion Models Video Generation.",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2024",
  month   = "Apr",
  url     = "https://lilianweng.github.io/posts/2024-04-12-diffusion-video/"
}
```

### 参考文献

> References

[1] Cicek 等人 2016 年。[“3D U-Net：从稀疏标注中学习密集体积分割。”](https://arxiv.org/abs/1606.06650)

> [1] Cicek et al. 2016. [“3D U-Net: Learning Dense Volumetric Segmentation from Sparse Annotation.”](https://arxiv.org/abs/1606.06650)

[2] Ho & Salimans 等人。[“视频扩散模型。”](https://arxiv.org/abs/2204.03458) 2022 | [网页](https://video-diffusion.github.io/)

> [2] Ho & Salimans, et al. [“Video Diffusion Models.”](https://arxiv.org/abs/2204.03458) 2022 | [webpage](https://video-diffusion.github.io/)

[3] Bar-Tal 等人 2024 年 [“Lumiere：用于视频生成的时空扩散模型。”](https://arxiv.org/abs/2401.12945)

> [3] Bar-Tal et al. 2024 [“Lumiere: A Space-Time Diffusion Model for Video Generation.”](https://arxiv.org/abs/2401.12945)

[4] Brooks 等人。[“作为世界模拟器的视频生成模型。”](https://openai.com/research/video-generation-models-as-world-simulators) OpenAI 博客，2024 年。

> [4] Brooks et al. [“Video generation models as world simulators.”](https://openai.com/research/video-generation-models-as-world-simulators) OpenAI Blog, 2024.

[5] Zhang 等人 2023 年 [“ControlVideo：免训练可控文本到视频生成。”](https://arxiv.org/abs/2305.13077)

> [5] Zhang et al. 2023 [“ControlVideo: Training-free Controllable Text-to-Video Generation.”](https://arxiv.org/abs/2305.13077)

[6] Khachatryan 等人 2023 年 [“Text2Video-Zero：文本到图像扩散模型是零样本视频生成器。”](https://arxiv.org/abs/2303.13439)

> [6] Khachatryan et al. 2023 [“Text2Video-Zero: Text-to-image diffusion models are zero-shot video generators.”](https://arxiv.org/abs/2303.13439)

[7] Ho 等人 2022 年 [“Imagen Video：使用扩散模型进行高清视频生成。”](https://arxiv.org/abs/2210.02303)

> [7] Ho, et al. 2022 [“Imagen Video: High Definition Video Generation with Diffusion Models.”](https://arxiv.org/abs/2210.02303)

[8] Singer 等人。[“Make-A-Video：无需文本视频数据的文本到视频生成。”](https://arxiv.org/abs/2209.14792) 2022 年。

> [8] Singer et al. [“Make-A-Video: Text-to-Video Generation without Text-Video Data.”](https://arxiv.org/abs/2209.14792) 2022.

[9] Wu 等人。[“Tune-A-Video：用于文本到视频生成的一次性图像扩散模型微调。”](https://openaccess.thecvf.com/content/ICCV2023/html/Wu_Tune-A-Video_One-Shot_Tuning_of_Image_Diffusion_Models_for_Text-to-Video_Generation_ICCV_2023_paper.html) ICCV 2023。

> [9] Wu et al. [“Tune-A-Video: One-Shot Tuning of Image Diffusion Models for Text-to-Video Generation.”](https://openaccess.thecvf.com/content/ICCV2023/html/Wu_Tune-A-Video_One-Shot_Tuning_of_Image_Diffusion_Models_for_Text-to-Video_Generation_ICCV_2023_paper.html) ICCV 2023.

[10] Blattmann 等人 2023 年 [“对齐你的潜在空间：使用潜在扩散模型进行高分辨率视频合成。”](https://arxiv.org/abs/2304.08818)

> [10] Blattmann et al. 2023 [“Align your Latents: High-Resolution Video Synthesis with Latent Diffusion Models.”](https://arxiv.org/abs/2304.08818)

[11] Blattmann 等人 2023 年 [“稳定视频扩散：将潜在视频扩散模型扩展到大型数据集。”](https://arxiv.org/abs/2311.15127)

> [11] Blattmann et al. 2023 [“Stable Video Diffusion: Scaling Latent Video Diffusion Models to Large Datasets.”](https://arxiv.org/abs/2311.15127)

[12] Esser 等人 2023 年 [“使用扩散模型进行结构和内容引导的视频合成。”](https://arxiv.org/abs/2302.03011)

> [12] Esser et al. 2023 [“Structure and Content-Guided Video Synthesis with Diffusion Models.”](https://arxiv.org/abs/2302.03011)

[13] Bar-Tal 等人 2024 年 [“Lumiere：用于视频生成的时空扩散模型。”](https://arxiv.org/abs/2401.12945)

> [13] Bar-Tal et al. 2024 [“Lumiere: A Space-Time Diffusion Model for Video Generation.”](https://arxiv.org/abs/2401.12945)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Diffusion Models | 扩散模型 | 一类生成模型，通过逐步去噪过程从随机噪声中生成数据。 |
| Temporal Consistency | 时间一致性 | 视频中连续帧之间内容和运动的连贯性。 |
| v-prediction parameterization | v-预测参数化 | 扩散模型中一种预测噪声的参数化方法，有助于避免视频生成中的色彩偏移。 |
| Reconstruction Guidance | 重建引导 | 一种方法，通过调整去噪模型，使视频采样能够以其他视频或低分辨率视频为条件。 |
| 3D U-Net | 3D U-Net | U-Net架构的扩展，适用于处理三维数据（如视频），在空间和时间维度上进行操作。 |
| DiT (Diffusion Transformer) | 扩散Transformer | 一种基于Transformer架构的扩散模型，对视频和图像潜在代码的时空补丁进行操作。 |
| Cascaded Diffusion Models | 级联扩散模型 | 多个扩散模型按顺序连接，用于逐步提高生成内容的质量和分辨率。 |
| Progressive Distillation | 渐进式蒸馏 | 一种加速扩散模型采样过程的方法，通过蒸馏减少所需采样步骤。 |
| Frame Interpolation Network | 帧插值网络 | 通过在现有帧之间生成新帧来提高视频帧率的网络。 |
| Spatio-Temporal Attention (ST-Attention) | 时空注意力 | 结合空间和时间维度上的注意力机制，以捕获视频中的时空关系。 |
| Zero-shot Video Generation | 零样本视频生成 | 无需在视频数据上进行额外训练，直接使用预训练图像模型生成视频的方法。 |
| Cross-frame Attention | 跨帧注意力 | 一种注意力机制，允许模型在生成当前帧时参考其他帧的信息，以保持时间一致性。 |
| ControlNet | ControlNet | 一种神经网络架构，用于在保持预训练扩散模型质量的同时，通过额外输入控制生成过程。 |
| Latent Diffusion Model (LDM) | 潜在扩散模型 | 在潜在空间而非像素空间进行扩散过程的生成模型，以提高效率。 |
