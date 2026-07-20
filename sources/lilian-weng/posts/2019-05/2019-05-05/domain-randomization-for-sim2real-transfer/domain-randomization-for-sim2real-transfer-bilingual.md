# 域随机化用于Sim2Real迁移

> Domain Randomization for Sim2Real Transfer

> 来源：Lil'Log / Lilian Weng，2019-05-05
> 原文链接：https://lilianweng.github.io/posts/2019-05-05-domain-randomization/
> 分类：机器人学 / 域随机化

## 核心要点

- Sim2Real差距是机器人学中的一个核心挑战，源于物理参数不一致和不准确的物理建模。
- 弥合Sim2Real差距的方法包括系统辨识、领域适应和领域随机化。
- 领域随机化（DR）通过创建具有随机属性的模拟环境来训练模型，使其能够泛化到真实世界。
- 与领域适应（DA）不同，DR可能只需要很少或根本不需要真实数据即可实现Sim2Real迁移。
- DR将模拟器定义为源域，物理世界定义为目标域，通过在源域中引入可变性来建模源域与目标域的差异。
- 均匀域随机化通过在预设范围内均匀采样随机化参数，以控制场景外观和物理动力学。
- 域随机化的有效性可以通过双层优化和元学习两种非排他性解释来理解。
- 引导式域随机化旨在通过任务性能、真实数据或模拟器中的数据指导随机化参数的采样，以提高效率并避免不可行解。
- 任务性能优化方法将随机化参数的学习视为强化学习问题，利用下游任务反馈进行调整。
- 匹配真实数据分布的方法通过最小化模拟和真实轨迹之间的差异来学习随机化参数，以使模拟器中的状态分布接近真实世界。

## 正文

在机器人学中，最困难的问题之一是如何使模型迁移到现实世界。由于深度强化学习算法的样本效率低下以及在真实机器人上收集数据的成本，我们通常需要在模拟器中训练模型，模拟器理论上可以提供无限量的数据。然而，模拟器与物理世界之间的现实差距常常导致在与物理机器人交互时出现故障。这种差距是由物理参数（即摩擦力、kp、阻尼、质量、密度）之间不一致，以及更致命的，不正确的物理建模（即软表面之间的碰撞）所引发的。

> In Robotics, one of the hardest problems is how to make your model transfer to the real world. Due to the sample inefficiency of deep RL algorithms and the cost of data collection on real robots, we often need to train models in a simulator which theoretically provides an infinite amount of data. However, the reality gap between the simulator and the physical world often leads to failure when working with physical robots. The gap is triggered by an inconsistency between physical parameters (i.e. friction, kp, damping, mass, density) and, more fatally, the incorrect physical modeling (i.e. collision between soft surfaces).

为了弥合sim2real差距，我们需要改进模拟器，使其更接近现实。有几种方法：

> To close the sim2real gap, we need to improve the simulator and make it closer to reality. A couple of approaches:

- **系统辨识**


   - *系统辨识*是为物理系统建立数学模型；在强化学习的背景下，数学模型就是模拟器。为了使模拟器更真实，仔细的校准是必要的。
   - 不幸的是，校准成本高昂。此外，同一机器的许多物理参数可能会因温度、湿度、位置或其随时间的磨损而显著变化。
- **领域适应**


   - *领域适应（DA）*是指一套迁移学习技术，旨在通过任务模型强制执行的映射或正则化，更新模拟环境中的数据分布以匹配真实环境中的数据分布。
   - 许多DA模型，特别是用于图像分类或端到端基于图像的强化学习任务的模型，都建立在对抗性损失或[GAN](https://lilianweng.github.io/posts/2017-08-20-gan/)之上。
- **领域随机化**


   - 通过*领域随机化（DR）*，我们能够创建各种具有随机属性的模拟环境，并训练一个适用于所有这些环境的模型。
   - 该模型很可能能够适应真实世界环境，因为真实系统预计是训练变体丰富分布中的一个样本。

> • **System identification**
>

> ◦ *System identification* is to build a mathematical model for a physical system; in the context of RL, the mathematical model is the simulator. To make the simulator more realistic, careful calibration is necessary.

> ◦ Unfortunately, calibration is expensive. Furthermore, many physical parameters of the same machine might vary significantly due to temperature, humidity, positioning or its wear-and-tear in time.

> • **Domain adaptation**
>

> ◦ *Domain adaptation (DA)* refers to a set of transfer learning techniques developed to update the data distribution in sim to match the real one through a mapping or regularization enforced by the task model.

> ◦ Many DA models, especially for image classification or end-to-end image-based RL task, are built on adversarial loss or [GAN](https://lilianweng.github.io/posts/2017-08-20-gan/).

> • **Domain randomization**
>

> ◦ With *domain randomization (DR)*, we are able to create a variety of simulated environments with randomized properties and train a model that works across all of them.

> ◦ Likely this model can adapt to the real-world environment, as the real system is expected to be one sample in that rich distribution of training variations.

DA 和 DR 都是无监督的。与 DA 需要大量真实数据样本来捕捉分布不同，DR 可能只需要*很少或根本不需要*真实数据。DR 是本文的重点。

> Both DA and DR are unsupervised. Compared to DA which requires a decent amount of real data samples to capture the distribution, DR may need *only a little or no* real data. DR is the focus of this post.

![Conceptual illustrations of three approaches for sim2real transfer.](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/sim2real-transfer.png)

### 什么是域随机化？

> What is Domain Randomization?

为了使定义更通用，我们将我们拥有完全访问权限的环境（即模拟器）称为**源域**，将我们希望将模型迁移到的环境（即物理世界）称为**目标域**。训练发生在源域中。我们可以控制源域中的一组`N`随机化参数$e_\xi$，通过从随机化空间中采样的配置`\xi`$\xi \in \Xi \subset \mathbb{R}^N$。

英文原文：To make the definition more general, let us call the environment that we have full access to (i.e. simulator) source domain and the environment that we would like to transfer the model to target domain (i.e. physical world). Training happens in the source domain. We can control a set of `N` randomization parameters in the source domain 

$e_\xi$ with a configuration `\xi`, sampled from a randomization space, 

$\xi \in \Xi \subset \mathbb{R}^N$.

在策略训练期间，从应用了随机化的源域中收集情节。因此，策略暴露在各种环境中并学习泛化。策略参数$\theta$经过训练，以最大化在配置分布中平均的预期奖励$R(.)$：

> During policy training, episodes are collected from source domain with randomization applied. Thus the policy is exposed to a variety of environments and learns to generalize. The policy parameter $\theta$ is trained to maximize the expected reward $R(.)$ average across a distribution of configurations:

$$
\theta^* = \arg\max_\theta \mathbb{E}_{\xi \sim \Xi} [\mathbb{E}_{\pi_\theta, \tau \sim e_\xi} [R(\tau)]]
$$

其中$\tau_\xi$是在用$\xi$随机化的源域中收集的轨迹。在某种程度上，*“源域和目标域之间的差异被建模为源域中的可变性。”*（引自[Peng et al. 2018](https://arxiv.org/abs/1710.06537)）。

> where $\tau_\xi$ is a trajectory collected in source domain randomized with $\xi$. In a way, *“discrepancies between the source and target domains are modeled as variability in the source domain.”* (quote from [Peng et al. 2018](https://arxiv.org/abs/1710.06537)).

### 均匀域随机化

> Uniform Domain Randomization

在 DR 的原始形式中 ([Tobin 等人，2017](https://arxiv.org/abs/1703.06907); [Sadeghi 等人，2016](https://arxiv.org/pdf/1611.04201.pdf))，每个随机化参数 $\xi_i$ 都由一个区间 $\xi_i \in [\xi_i^\text{low}, \xi_i^\text{high}], i=1,\dots,N$ 限制，并且每个参数在该范围内均匀采样。

> In the original form of DR ([Tobin et al, 2017](https://arxiv.org/abs/1703.06907); [Sadeghi et al. 2016](https://arxiv.org/pdf/1611.04201.pdf)), each randomization parameter $\xi_i$ is bounded by an interval, $\xi_i \in [\xi_i^\text{low}, \xi_i^\text{high}], i=1,\dots,N$ and each parameter is uniformly sampled within the range.

随机化参数可以控制场景的外观，包括但不限于以下各项（参见图 2）。在模拟和随机化图像上训练的模型能够迁移到真实的非随机化图像。

> The randomization parameters can control appearances of the scene, including but not limited to the followings (see Fig. 2). A model trained on simulated and randomized images is able to transfer to real non-randomized images.

- 物体的位置、形状和颜色，
- 材质纹理，
- 光照条件，
- 添加到图像中的随机噪声，
- 模拟器中摄像机的位置、方向和视野。

> • Position, shape, and color of objects,
> • Material texture,
> • Lighting condition,
> • Random noise added to images,
> • Position, orientation, and field of view of the camera in the simulator.

![Images captured in the training environment are randomized. (Image source: Tobin et al, 2017 )](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/DR.png)

模拟器中的物理动力学也可以随机化（[Peng et al. 2018](https://arxiv.org/abs/1710.06537)）。研究表明，*循环*策略可以适应不同的物理动力学，包括部分可观察的现实。一组物理动力学特征包括但不限于：

> Physical dynamics in the simulator can also be randomized ([Peng et al. 2018](https://arxiv.org/abs/1710.06537)). Studies have showed that a *recurrent* policy can adapt to different physical dynamics including the partially observable reality. A set of physical dynamics features include but are not limited to:

- 物体的质量和尺寸，
- 机器人本体的质量和尺寸，
- 关节的阻尼、kp、摩擦力，
- PID 控制器（P 项）的增益，
- 关节限制，
- 动作延迟，
- 观测噪声。

> • Mass and dimensions of objects,
> • Mass and dimensions of robot bodies,
> • Damping, kp, friction of the joints,
> • Gains for the PID controller (P term),
> • Joint limit,
> • Action delay,
> • Observation noise.

借助视觉和动力学域随机化（DR），在 OpenAI Robotics，我们能够学习到一个在真实灵巧机器人手上工作的策略（[OpenAI, 2018](https://arxiv.org/abs/1808.00177)）。我们的操作任务是教机器人手连续旋转一个物体，以实现 50 个连续的随机目标方向。这项任务中的模拟到现实（sim2real）差距非常大，原因在于 (a) 机器人与物体之间同时接触的数量很多，以及 (b) 物体碰撞和其他运动的模拟不完善。起初，该策略在不掉落物体的情况下，几乎无法存活超过 5 秒。但借助 DR 的帮助，该策略最终在现实中表现出惊人的良好效果。

> With visual and dynamics DR, at OpenAI Robotics, we were able to learn a policy that works on real dexterous robot hand ([OpenAI, 2018](https://arxiv.org/abs/1808.00177)). Our manipulation task is to teach the robot hand to rotate an object continously to achieve 50 successive random target orientations. The sim2real gap in this task is very large, due to (a) a high number of simultaneous contacts between the robot and the object and (b) imperfect simulation of object collision and other motions. At first, the policy could barely survive for more than 5 seconds without dropping the object. But with the help of DR, the policy evolved to work surprisingly well in reality eventually.

### 为什么域随机化有效？

> Why does Domain Randomization Work?

现在你可能会问，为什么域随机化效果如此之好？这个想法听起来确实很简单。以下是我发现最令人信服的两个非排他性解释。

> Now you may ask, why does domain randomization work so well? The idea sounds really simple. Here are two non-exclusive explanations I found most convincing.

#### 作为优化的DR

> DR as Optimization

一个想法 ([Vuong, et al, 2019](https://arxiv.org/abs/1903.11774)) 是将 DR 中学习随机化参数视为一种 *双层优化*。假设我们可以访问真实环境 $e_\text{real}$ 并且随机化配置是从由 $\phi$、$\xi \sim P_\phi(\xi)$ 参数化的分布中采样的，我们希望学习一个分布，在此分布上训练的策略 $\pi_\theta$ 可以在 $e_\text{real}$ 中实现最大性能：

> One idea ([Vuong, et al, 2019](https://arxiv.org/abs/1903.11774)) is to view learning randomization parameters in DR as a *bilevel optimization*. Assuming we have access to the real environment $e_\text{real}$ and the randomization config is sampled from a distribution parameterized by $\phi$, $\xi \sim P_\phi(\xi)$, we would like to learn a distribution on which a policy $\pi_\theta$ is trained on can achieve maximal performance in $e_\text{real}$:

$$
\begin{aligned}
&\phi^* = \arg\min_{\phi} \mathcal{L}(\pi_{\theta^*(\phi)}; e_\text{real}) \\
\text{where } &\theta^*(\phi) = \arg\min_\theta \mathbb{E}_{\xi \sim P_\phi(\xi)}[\mathcal{L}(\pi_\theta; e_\xi)]
\end{aligned}
$$

其中 $\mathcal{L}(\pi; e)$ 是策略 $\pi$ 在环境 $e$ 中评估的损失函数。

> where $\mathcal{L}(\pi; e)$ is the loss function of policy $\pi$ evaluated in the environment $e$.

尽管在均匀DR中随机化范围是手动选择的，但它通常涉及领域知识以及基于迁移性能的几轮试错调整。本质上，这是一个手动优化过程，用于调整$\phi$以获得最佳的$\mathcal{L}(\pi_{\theta^{\ast}(\phi)}; e_\text{real})$。

> Although randomization ranges are hand-picked in uniform DR, it often involves domain knowledge and a couple rounds of trial-and-error adjustment based on the transfer performance. Essentially this is a manual optimization process on tuning $\phi$ for the optimal $\mathcal{L}(\pi_{\theta^{\ast}(\phi)}; e_\text{real})$.

下一节中的引导式域随机化在很大程度上受到了这一观点的启发，旨在进行双层优化并自动学习最佳参数分布。

> Guided domain randomization in the next section is largely inspired by this view, aiming to do bilevel optimization and learn the best parameter distribution automatically.

#### 作为元学习的域随机化

> DR as Meta-Learning

在我们的灵巧学习项目中（[OpenAI, 2018](https://arxiv.org/abs/1808.00177)），我们训练了一个LSTM策略，使其能够泛化到不同的环境动力学中。我们观察到，一旦机器人完成了第一次旋转，它在后续成功所需的时间就大大缩短了。此外，一个没有记忆的前馈（FF）策略被发现无法转移到物理机器人上。这两点都证明了策略能够动态学习并适应新环境。

> In our learning dexterity project ([OpenAI, 2018](https://arxiv.org/abs/1808.00177)), we trained an LSTM policy to generalize across different environmental dynamics. We observed that once a robot achieved the first rotation, the time it needed for the following successes was much shorter. Also, a FF policy without memory was found not able to transfer to a physical robot. Both are evidence of the policy dynamically learning and adapting to a new environment.

在某些方面，域随机化构成了不同任务的集合。循环网络中的记忆使策略能够实现跨任务的[元学习](https://lilianweng.github.io/posts/2018-11-30-meta-learning/)，并进一步在真实世界环境中工作。

> In some ways, domain randomization composes a collection of different tasks. Memory in the recurrent network empowers the policy to achieve [meta-learning](https://lilianweng.github.io/posts/2018-11-30-meta-learning/) across tasks and further work on a real-world setting.

### 引导式域随机化

> Guided Domain Randomization

香草DR（Vanilla DR）假设无法访问真实数据，因此在模拟中尽可能广泛和均匀地采样随机化配置，希望真实环境能够被这种广泛的分布所覆盖。考虑一种更复杂的策略是合理的——用来自*任务性能*、*真实数据*或*模拟器*的指导来取代均匀采样。

> The vanilla DR assumes no access to the real data, and thus the randomization config is sampled as broadly and uniformly as possible in sim, hoping that the real environment could be covered under this broad distribution. It is reasonable to think of a more sophisticated strategy — replacing uniform sampling with guidance from *task performance*, *real data*, or *simulator*.

引导式DR的一个动机是通过避免在不真实的环境中训练模型来节省计算资源。另一个动机是避免由于过宽的随机化分布可能导致不可行的解决方案，从而阻碍成功的策略学习。

> One motivation for guided DR is to save computation resources by avoiding training models in unrealistic environments. Another is to avoid infeasible solutions that might arise from overly wide randomization distributions and thus might hinder successful policy learning.

#### 任务性能优化

> Optimization for Task Performance

假设我们训练了一系列具有不同随机化参数的策略$\xi \sim P_\phi(\xi)$，其中$P_\xi$是$\xi$的分布，由$\phi$参数化。随后，我们决定在目标域的下游任务（即在现实中控制机器人或在验证集上评估）中尝试每一个策略，以收集反馈。此反馈告诉我们配置$\xi$的优劣，并为优化$\phi$提供信号。

> Say we train a family of policies with different randomization parameters $\xi \sim P_\phi(\xi)$, where $P_\xi$ is the distribution for $\xi$ parameterized by $\phi$. Later we decide to try every one of them on the downstream task in the target domain (i.e. control a robot in reality or evaluate on a validation set) to collect feedback. This feedback tells us how good a configuration $\xi$ is and provides signals for optimizing $\phi$.

受[NAS](https://ai.google/research/pubs/pub45826)的启发，**AutoAugment**（[Cubuk, et al. 2018](https://arxiv.org/abs/1805.09501)）将学习图像分类的最佳数据增强操作（即剪切、旋转、反转等）的问题框定为强化学习问题。请注意，AutoAugment并非为sim2real迁移而提出，但它属于由任务性能指导的DR范畴。单个增强配置在评估集上进行测试，性能提升被用作训练PPO策略的奖励。该策略为不同的数据集输出不同的增强策略；例如，对于CIFAR-10，AutoAugment主要选择基于颜色的变换，而ImageNet则偏爱基于几何的变换。

> Inspired by [NAS](https://ai.google/research/pubs/pub45826), **AutoAugment** ([Cubuk, et al. 2018](https://arxiv.org/abs/1805.09501)) frames the problem of learning best data augmentation operations (i.e.  shearing, rotation, invert, etc.) for image classification as an RL problem. Note that AutoAugment is not proposed for sim2real transfer, but falls in the bucket of DR guided by task performance. Individual augmentation configuration is tested on the evaluation set and the performance improvement is used as a reward to train a PPO policy. This policy outputs different augmentation strategies for different datasets; for example, for CIFAR-10 AutoAugment mostly  picks color-based transformations, while ImageNet prefers geometric based.

[Ruiz (2019)](https://arxiv.org/abs/1810.02513) 将*任务反馈*视为强化学习问题中的*奖励*，并提出了一种基于强化学习的方法，名为“学习模拟”，用于调整$\xi$。训练一个策略来预测$\xi$，使用主任务验证数据上的性能指标作为奖励，这被建模为多元高斯分布。总的来说，这个想法与AutoAugment类似，将NAS应用于数据生成。根据他们的实验，即使主任务模型尚未收敛，它仍然可以为数据生成策略提供合理的信号。

> [Ruiz (2019)](https://arxiv.org/abs/1810.02513) considered the *task feedback* as *reward* in RL problem and proposed a RL-based method, named “learning to simulate”, for adjusting $\xi$. A policy is trained to predict $\xi$ using performance metrics on the validation data of the main task as rewards, which is modeled as a multivariate Gaussian. Overall the idea is similar to AutoAugment, applying NAS on data generation. According to their experiments, even if the main task model is not converged, it still can provide a reasonable signal to the data generation policy.

![An overview of the "learning to simulate" approach. (Image source: Ruiz (2019) )](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/learning-to-simulate.png)

进化算法是另一种方法，其中*反馈*被视为指导进化的*适应度*（[Yu et al, 2019](https://openreview.net/forum?id=H1g6osRcFQ)）。在这项研究中，他们使用了[CMA-ES](https://en.wikipedia.org/wiki/CMA-ES)（协方差矩阵自适应进化策略），而适应度是目标环境中$\xi$条件策略的性能。在附录中，他们将CMA-ES与建模$\xi$动态的其他方法进行了比较，包括贝叶斯优化或神经网络。主要论点是这些方法不如CMA-ES稳定或样本效率高。有趣的是，当将$P(\xi)$建模为神经网络时，发现LSTM的性能显著优于FF。

> Evolutionary algorithm is another way to go, where the *feedback* is treated as *fitness* for guiding evolution ([Yu et al, 2019](https://openreview.net/forum?id=H1g6osRcFQ)). In this study, they used [CMA-ES](https://en.wikipedia.org/wiki/CMA-ES) (covariance matrix adaptation evolution strategy) while fitness is the performance of a $\xi$ -conditional policy in target environment. In the appendix, they compared CMA-ES with other ways of modeling the dynamics of $\xi$, including Bayesian optimization or a neural network. The main claim was those methods are not as stable or sample efficient as CMA-ES. Interestly, when modeling $P(\xi)$ as a neural network, LSTM is found to notably outperform FF.

一些人认为sim2real鸿沟是外观鸿沟和内容鸿沟的结合；即，大多数受GAN启发的DA模型侧重于外观鸿沟。**Meta-Sim**（[Kar, et al. 2019](https://arxiv.org/abs/1904.11621)）旨在通过生成特定任务的合成数据集来弥合内容鸿沟。Meta-Sim以自动驾驶汽车训练为例，因此场景可能非常复杂。在这种情况下，合成场景通过具有属性（即位置、颜色）以及对象之间关系的对象层次结构进行参数化。该层次结构由类似于结构域随机化（**SDR**；[Prakash et al., 2018](https://arxiv.org/abs/1810.10093)）的概率场景语法指定，并且假定是预先已知的。模型`G`通过以下方式训练以增强场景属性`s`的分布：

英文原文：Some believe that sim2real gap is a combination of appearance gap and content gap; i.e. most GAN-inspired DA models focus on appearance gap. Meta-Sim ([Kar, et al. 2019](https://arxiv.org/abs/1904.11621)) aims to close the content gap by generating task-specific synthetic datasets. Meta-Sim uses self-driving car training as an example and thus the scene could be very complicated. In this case, the synthetic scenes are parameterized by a hierarchy of objects with properties (i.e., location, color) as well as relationships between objects. The hierarchy is specified by a probabilistic scene grammar akin to structure domain randomization (SDR; [Prakash et al., 2018](https://arxiv.org/abs/1810.10093)) and it is assumed to be known beforehand. A model `G` is trained to augment the distribution of scene properties `s` by following:

1\. 首先学习先验：预训练$G$以学习恒等函数$G(s) = s$。

2\. 最小化真实数据分布和模拟数据分布之间的MMD损失。这涉及通过不可微分渲染器进行反向传播。该论文通过扰动$G(s)$的属性来数值计算它。

3\. 在合成数据上训练但在真实数据上评估时，最小化REINFORCE任务损失。同样，这与AutoAugment非常相似。

英文原文：

1\. Learn the prior first: pre-train $G$ to learn the identity function $G(s) = s$.

2\. Minimize MMD loss between the real and sim data distributions. This involves backpropagation through non-differentiable renderer. The paper computes it numerically by perturbing the attributes of $G(s)$.

3\. Minimize REINFORCE task loss when trained on synthetic data but evaluated on real data. Again, very similar to AutoAugment.

不幸的是，这类方法不适用于sim2real情况。无论是强化学习策略还是进化算法模型，都需要大量的真实样本。将物理机器人上的实时反馈收集纳入训练循环的成本非常高。是否愿意用较少的计算资源换取真实数据收集将取决于您的任务。

> Unfortunately, this family of methods are not suitable for sim2real case. Either an RL policy or an EA model requires a large number of real samples. And it is really expensive to include real-time feedback collection on a physical robot into the training loop. Whether you want to trade less computation resource for real data collection would depend on your task.

#### 匹配真实数据分布

> Match Real Data Distribution

使用真实数据指导域随机化感觉很像进行系统识别或DA。DA的核心思想是改进合成数据以匹配真实数据分布。在真实数据引导的DR情况下，我们希望学习随机化参数$\xi$，使模拟器中的状态分布接近真实世界中的状态分布。

> Using real data to guide domain randomization feels a lot like doing system identification or DA. The core idea behind DA is to improve the synthetic data to match the real data distribution. In the case of real-data-guided DR, we would like to learn the randomization parameters $\xi$ that bring the state distribution in simulator close to the state distribution in the real world.

**SimOpt**模型（[Chebotar et al, 2019](https://arxiv.org/abs/1810.05687)）首先在初始随机化分布$P_\phi(\xi)$下进行训练，得到一个策略`\pi_{\theta, P_\phi}`。然后将该策略部署到模拟器和物理机器人上，分别收集轨迹$\tau_\xi$和$\tau_\text{real}$。优化目标是最小化模拟和真实轨迹之间的差异：

英文原文：The SimOpt model ([Chebotar et al, 2019](https://arxiv.org/abs/1810.05687)) is trained under an initial randomization distribution 

$P_\phi(\xi)$ first, getting a policy `\pi_{\theta, P_\phi}`. Then this policy is deployed on both simulator and physical robot to collect trajectories 

$\tau_\xi$ and 

$\tau_\text{real}$ respectively. The optimization objective is to minimize the discrepancy between sim and real trajectories:

$$
\phi^* = \arg\min_{\phi}\mathbb{E}_{\xi \sim P_\phi(\xi)} [\mathbb{E}_{\pi_{\theta, P_\phi}} [D(\tau_\text{sim}, \tau_\text{real})]]
$$

其中$D(.)$是基于轨迹的差异度量。与“学习模拟”论文一样，SimOpt也必须解决如何通过不可微分模拟器传播梯度的棘手问题。它使用了一种名为[相对熵策略搜索](https://www.aaai.org/ocs/index.php/AAAI/AAAI10/paper/viewFile/1851/2264)的方法，更多细节请参阅论文。

> where $D(.)$ is a trajectory-based discrepancy measure. Like the “Learning to simulate” paper, SimOpt also has to solve the tricky problem of how to propagate gradient through non-differentiable simulator. It used a method called [relative entropy policy search](https://www.aaai.org/ocs/index.php/AAAI/AAAI10/paper/viewFile/1851/2264), see paper for more details.

![An overview of the SimOpt framework. (Image source: Chebotar et al, 2019 )](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/simopt.png)

**RCAN**（[James et al., 2019](https://arxiv.org/abs/1812.07252)），是“随机化到规范适应网络”的缩写，是DA和DR在端到端强化学习任务中的一个很好的结合。在模拟器中训练一个图像条件GAN（[cGAN](https://arxiv.org/abs/1611.07004)），将域随机化图像转换为非随机化版本（即“规范版本”）。随后，相同的模型用于将真实图像转换为相应的模拟版本，以便智能体能够接收到与训练中遇到的一致的观察。然而，其基本假设是域随机化模拟图像的分布足够广泛，可以覆盖真实世界的样本。

> **RCAN** ([James et al., 2019](https://arxiv.org/abs/1812.07252)), short for “Randomized-to-Canonical Adaptation Networks”, is a nice combination of DA and DR for end-to-end RL tasks. An image-conditional GAN ([cGAN](https://arxiv.org/abs/1611.07004)) is trained in sim to translate a domain-randomized image into a non-randomized version (aka “canonical version”). Later the same model is used to translate real images into corresponding simulated version so that the agent would consume consistent observation as what it has encountered in training. Still, the underlying assumption is that the distribution of domain-randomized sim images is broad enough to cover real-world samples.

![RCAN is an image-conditional generator that can convert a domain-randomized or real image into its corresponding non-randomized simulator version. (Image source: James et al., 2019 )](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/RCAN.png)

强化学习模型在模拟器中进行端到端训练，以实现基于视觉的机械臂抓取。随机化在每个时间步应用，包括托盘分隔器的位置、要抓取的物体、随机纹理，以及灯光的位置、方向和颜色。规范版本是默认的模拟器外观。RCAN试图学习一个生成器

> The RL model is trained end-to-end in a simulator to do vision-based robot arm grasping. Randomization is applied at each timestep, including the position of tray divider, objects to grasp, random textures, as well as the position, direction, and color of the lighting. The canonical version is the default simulator look. RCAN is trying to learn a generator

$G$：随机化图像$\to$ {规范图像，分割，深度}

> $G$: randomized image $\to$ {canonical image, segmentation, depth}

其中分割掩码和深度图像用作辅助任务。与均匀DR相比，RCAN具有更好的零样本迁移能力，尽管两者都被证明不如仅在真实图像上训练的模型。从概念上讲，RCAN的操作方向与[GraspGAN](https://arxiv.org/abs/1709.07857)相反，后者通过域适应将合成图像转换为真实图像。

> where segmentation masks and depth images are used as auxiliary tasks. RCAN had a better zero-shot transfer compared to uniform DR, although both were shown to be worse than the model trained on only real images. Conceptually, RCAN operates in a reverse direction of [GraspGAN](https://arxiv.org/abs/1709.07857) which translates synthetic images into real ones by domain adaptation.

#### 由模拟器中的数据引导

> Guided by Data in Simulator

网络驱动的域随机化（[Zakharov et al., 2019](https://arxiv.org/abs/1904.02750)），也称为**DeceptionNet**，其动机是学习哪些随机化对于弥合图像分类任务的域鸿沟实际上是有用的。

> Network-driven domain randomization ([Zakharov et al., 2019](https://arxiv.org/abs/1904.02750)), also known as **DeceptionNet**,  is motivated by learning which randomizations are actually useful to bridge the domain gap for image classification tasks.

随机化通过一组具有编码器-解码器架构的欺骗模块应用。这些欺骗模块专门设计用于转换图像；例如改变背景、添加失真、改变光照等。另一个识别网络通过对转换后的图像运行分类来处理主要任务。

> Randomization is applied through a set of deception modules with encoder-decoder architecture. The deception modules are specifically designed to transform images; such as change backgrounds, add distortion, change lightings, etc. The other recognition network handles the main task by running classification on transformed images.

训练包括两个步骤：

> The training involves two steps:

1. 在识别网络固定的情况下，通过在反向传播期间应用反向梯度来*最大化预测与标签之间的差异*。这样欺骗模块就可以学习到最令人困惑的技巧。
2. 在欺骗模块固定的情况下，使用修改后的输入图像训练识别网络。

> • With the recognition network fixed, *maximize the difference* between the prediction and the labels by applying reversed gradients during backpropagation.  So that the deception module can learn the most confusing tricks.
> • With the deception modules fixed, train the recognition network with input images altered.

![How DeceptionNet works. (Image source: Zakharov et al., 2019 )](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/deception-net.png)

用于训练欺骗模块的反馈由下游分类器提供。但随机化模块的目标是创建更难的案例，而不是像[上面这一节](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#optimization-for-task-performance)那样试图最大化任务性能。一个很大的缺点是，你需要为不同的数据集或任务手动设计不同的欺骗模块，这使得它不容易扩展。考虑到它是零样本的，其结果在MNIST和LineMOD上仍然比SOTA DA方法差。

> The feedback for training deception modules is provided by the downstream classifier. But rather than trying to maximize the task performance like [the section](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#optimization-for-task-performance) above, the randomization modules aim to create harder cases. One big disadvantage is you need to manually design different deception modules for different datasets or tasks, making it not easily scalable. Given the fact that it is zero-shot, the results are still worse than SOTA DA methods on MNIST and LineMOD.

类似地，主动域随机化（**ADR**；[Mehta 等人，2019](https://arxiv.org/abs/1904.04762)）也依赖于模拟数据来创建更难的训练样本。ADR 在给定的随机化范围内搜索*信息量最大*的环境变体，其中*信息量*通过策略在随机化和参考（原始、非随机化）环境实例中的执行差异来衡量。听起来有点像[SimOpt](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#match-real-data-distribution)？请注意，SimOpt 衡量的是模拟和真实执行之间的差异，而 ADR 衡量的是随机化和非随机化模拟之间的差异，从而避免了昂贵的真实数据收集部分。

> Similarly, Active domain randomization (**ADR**; [Mehta et al., 2019](https://arxiv.org/abs/1904.04762)) also relies on sim data to create harder training samples. ADR searches for the *most informative* environment variations within the given randomization ranges, where the *informativeness* is measured as the discrepancies of policy rollouts in randomized and reference (original, non-randomized) environment instances. Sounds a bit like [SimOpt](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/#match-real-data-distribution)? Well, noted that SimOpt measures the discrepancy between sim and real rollouts, while ADR measures between randomized and non-randomized sim, avoiding the expensive real data collection part.

![How active domain randomization (ADR) works. (Image source: Mehta et al., 2019 )](https://lilianweng.github.io/posts/2019-05-05-domain-randomization/ADR.png)

具体训练过程如下：

> Precisely the training happens as follows:

1\. 给定一个策略，分别在参考环境和随机化环境中运行它，并收集两组轨迹。

2\. 训练一个判别器模型，以区分执行轨迹是随机化的还是参考运行的。预测的$\log p$（被随机化的概率）用作奖励。随机化和参考执行之间的差异越大，预测越容易，奖励越高。

   - 直觉是，如果一个环境很容易，相同的策略代理可以产生与参考环境相似的轨迹。那么模型应该通过鼓励不同的行为来奖励和探索困难的环境。

3\. 判别器提供的奖励被输入到*Stein 变分策略梯度*（[SVPG](https://arxiv.org/abs/1704.02399)）粒子中，输出一组多样化的随机化配置。

英文原文：

1\. Given a policy, run it on both reference and randomized envs and collect two sets of trajectories respectively.

2\. Train a discriminator model to tell whether a rollout trajectory is randomized apart from reference run. The predicted $\log p$ (probability of being randomized) is used as reward. The more different randomized and reference rollouts, the easier the prediction, the higher the reward.



   - The intuition is that if an environment is easy, the same policy agent can produce similar trajectories as in the reference one. Then the model should reward and explore hard environments by encouraging different behaviors.

3\. The reward by discriminator is fed into *Stein Variational Policy Gradient* ([SVPG](https://arxiv.org/abs/1704.02399)) particles, outputting a diverse set of randomization configurations.

ADR 的想法非常有吸引力，但有两个小问题。当运行随机策略时，轨迹之间的相似性可能不是衡量环境难度的好方法。sim2real 的结果不幸看起来不那么令人兴奋，但论文指出 ADR 的优势在于它探索了更小范围的随机化参数。

> The idea of ADR is very appealing with two small concerns. The similarity between trajectories might not be a good way to measure the env difficulty when running a stochastic policy. The sim2real results look unfortunately not as exciting, but the paper pointed out the win being ADR explores a smaller range of randomization parameters.

引用来源：

> Cited as:

```
@article{weng2019DR,
  title   = "Domain Randomization for Sim2Real Transfer",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2019",
  url     = "https://lilianweng.github.io/posts/2019-05-05-domain-randomization/"
}
```

总而言之，读完这篇文章后，我希望你和我一样喜欢域随机化 :)

> Overall, after reading this post, I hope you like domain randomization as much as I do :).

### 参考文献

> References

[1] Josh Tobin 等人。[“Domain randomization for transferring deep neural networks from simulation to the real world.”](https://arxiv.org/pdf/1703.06907.pdf) IROS, 2017。

> [1] Josh Tobin, et al. [“Domain randomization for transferring deep neural networks from simulation to the real world.”](https://arxiv.org/pdf/1703.06907.pdf) IROS, 2017.

[2] Fereshteh Sadeghi 和 Sergey Levine。[“CAD2RL: Real single-image flight without a single real image.”](https://arxiv.org/abs/1611.04201) arXiv:1611.04201 (2016)。

> [2] Fereshteh Sadeghi and Sergey Levine. [“CAD2RL: Real single-image flight without a single real image.”](https://arxiv.org/abs/1611.04201) arXiv:1611.04201 (2016).

[3] Xue Bin Peng 等人。[“Sim-to-real transfer of robotic control with dynamics randomization.”](https://arxiv.org/abs/1710.06537) ICRA, 2018。

> [3] Xue Bin Peng, et al. [“Sim-to-real transfer of robotic control with dynamics randomization.”](https://arxiv.org/abs/1710.06537) ICRA, 2018.

[4] Nataniel Ruiz 等人。[“Learning to Simulate.”](https://openreview.net/forum?id=HJgkx2Aqt7) ICLR 2019

> [4] Nataniel Ruiz, et al. [“Learning to Simulate.”](https://openreview.net/forum?id=HJgkx2Aqt7) ICLR 2019

[5] OpenAI。[“Learning Dexterous In-Hand Manipulation.”](https://arxiv.org/abs/1808.00177) arXiv:1808.00177 (2018)。

> [5] OpenAI. [“Learning Dexterous In-Hand Manipulation.”](https://arxiv.org/abs/1808.00177) arXiv:1808.00177 (2018).

[6] OpenAI 博客。[“Learning dexterity”](https://openai.com/blog/learning-dexterity/) 2018 年 7 月 30 日。

> [6] OpenAI Blog. [“Learning dexterity”](https://openai.com/blog/learning-dexterity/) July 30, 2018.

[7] Quan Vuong 等人。[“How to pick the domain randomization parameters for sim-to-real transfer of reinforcement learning policies?.”](https://arxiv.org/abs/1903.11774) arXiv:1903.11774 (2019)。

> [7] Quan Vuong, et al. [“How to pick the domain randomization parameters for sim-to-real transfer of reinforcement learning policies?.”](https://arxiv.org/abs/1903.11774) arXiv:1903.11774 (2019).

[8] Ekin D. Cubuk 等人。[“AutoAugment: Learning augmentation policies from data.”](https://arxiv.org/abs/1805.09501) arXiv:1805.09501 (2018)。

> [8] Ekin D. Cubuk, et al. [“AutoAugment: Learning augmentation policies from data.”](https://arxiv.org/abs/1805.09501) arXiv:1805.09501 (2018).

[9] Wenhao Yu 等人。[“Policy Transfer with Strategy Optimization.”](https://openreview.net/forum?id=H1g6osRcFQ) ICLR 2019

> [9] Wenhao Yu et al. [“Policy Transfer with Strategy Optimization.”](https://openreview.net/forum?id=H1g6osRcFQ) ICLR 2019

[10] Yevgen Chebotar 等人。[“Closing the Sim-to-Real Loop: Adapting Simulation Randomization with Real World Experience.”](https://arxiv.org/abs/1810.05687) Arxiv: 1810.05687 (2019)。

> [10] Yevgen Chebotar et al. [“Closing the Sim-to-Real Loop: Adapting Simulation Randomization with Real World Experience.”](https://arxiv.org/abs/1810.05687) Arxiv: 1810.05687 (2019).

[11] Stephen James 等人。[“通过模拟到模拟实现从模拟到现实：通过随机化到规范化适应网络实现数据高效的机器人抓取”](https://arxiv.org/abs/1812.07252) CVPR 2019。

> [11] Stephen James et al. [“Sim-to-real via sim-to-sim: Data-efficient robotic grasping via randomized-to-canonical adaptation networks”](https://arxiv.org/abs/1812.07252) CVPR 2019.

[12] Bhairav Mehta 等人。[“主动域随机化”](https://arxiv.org/abs/1904.04762) arXiv:1904.04762

> [12] Bhairav Mehta et al. [“Active Domain Randomization”](https://arxiv.org/abs/1904.04762) arXiv:1904.04762

[13] Sergey Zakharov 等人。[“DeceptionNet：网络驱动的域随机化。”](https://arxiv.org/abs/1904.02750) arXiv:1904.02750 (2019)。

> [13] Sergey Zakharov,et al. [“DeceptionNet: Network-Driven Domain Randomization.”](https://arxiv.org/abs/1904.02750) arXiv:1904.02750 (2019).

[14] Amlan Kar 等人。[“Meta-Sim：学习生成合成数据集。”](https://arxiv.org/abs/1904.11621) arXiv:1904.11621 (2019)。

> [14] Amlan Kar, et al. [“Meta-Sim: Learning to Generate Synthetic Datasets.”](https://arxiv.org/abs/1904.11621) arXiv:1904.11621 (2019).

[15] Aayush Prakash 等人。[“结构化域随机化：通过上下文感知合成数据弥合现实差距。”](https://arxiv.org/abs/1810.10093) arXiv:1810.10093 (2018)。

> [15] Aayush Prakash, et al. [“Structured Domain Randomization: Bridging the Reality Gap by Context-Aware Synthetic Data.”](https://arxiv.org/abs/1810.10093) arXiv:1810.10093 (2018).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Sim2Real | 模拟到现实迁移 | 指将模拟环境中训练的模型部署到真实物理世界的过程。 |
| Domain Randomization (DR) | 域随机化 | 一种通过在模拟器中随机化环境参数来提高模型泛化能力，以适应真实世界的技术。 |
| Domain Adaptation (DA) | 领域适应 | 一套迁移学习技术，旨在通过调整数据分布使模拟环境与真实环境匹配。 |
| System Identification | 系统辨识 | 为物理系统建立数学模型的过程，在强化学习中指建立模拟器模型。 |
| Source Domain | 源域 | 指拥有完全访问权限的训练环境，通常是模拟器。 |
| Target Domain | 目标域 | 指希望将模型迁移到的真实物理世界环境。 |
| Uniform Domain Randomization | 均匀域随机化 | 域随机化的原始形式，在预设范围内均匀采样随机化参数。 |
| Guided Domain Randomization | 引导式域随机化 | 通过任务性能、真实数据或模拟器数据指导随机化参数采样的DR方法。 |
| Meta-Learning | 元学习 | 使模型能够学习如何学习，从而快速适应新任务或环境的能力。 |
| Double-level Optimization | 双层优化 | 一种优化框架，其中一个优化问题嵌套在另一个优化问题中。 |
| Generative Adversarial Networks (GAN) | 生成对抗网络 | 一种深度学习模型，通过生成器和判别器的对抗过程生成新数据。 |
| Reinforcement Learning (RL) | 强化学习 | 一种机器学习范式，智能体通过与环境交互学习最优策略。 |
| Covariance Matrix Adaptation Evolution Strategy (CMA-ES) | 协方差矩阵自适应进化策略 | 一种用于连续优化问题的进化算法。 |
| Relative Entropy Policy Search (REPS) | 相对熵策略搜索 | 一种强化学习算法，通过限制策略更新的相对熵来优化策略。 |
| Active Domain Randomization (ADR) | 主动域随机化 | 一种依赖模拟数据创建更具挑战性训练样本的DR方法，通过衡量策略执行差异来评估信息量。 |
