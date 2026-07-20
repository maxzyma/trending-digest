# 深度学习概述：致好奇的人

> An Overview of Deep Learning for Curious People

> 来源：Lil'Log / Lilian Weng，2017-06-21
> 原文链接：https://lilianweng.github.io/posts/2017-06-21-overview/
> 分类：人工智能 / 深度学习

## 核心要点

- 2016年AlphaGo战胜围棋世界冠军李世石的事件，标志着人工智能领域取得重大进展，深度学习是其核心驱动力之一。
- 深度学习模型作为大型深层人工神经网络，其成功得益于海量数据和强大的计算能力。
- 卷积神经网络（CNN）受视觉皮层启发，通过卷积层和池化层进行特征提取，广泛应用于图像识别。
- 循环神经网络（RNN）擅长处理序列数据，如手写识别和机器翻译，其中长短期记忆（LSTM）单元有效解决了长期依赖问题。
- 序列到序列（Seq2Seq）模型是RNN的扩展，由编码器和解码器组成，常用于开发聊天机器人和个人助理。
- 自编码器是一种无监督学习模型，旨在学习高维数据的低维表示，实现高效数据压缩。
- 强化学习（RL）是AlphaGo成功的关键之一，通过代理在特定环境中学习最佳行为以最大化长期性能。
- 生成对抗网络（GAN）由生成器和判别器构成，通过零和博弈学习真实数据并生成新的示例。
- TensorFlow等开源工具包和库极大地促进了深度学习模型的实现与应用。
- 学习深度学习建议从经典书籍和课程入手，并持续关注学术论文以跟进领域前沿进展。

## 正文

(本文源自我为[WiMLDS x Fintech meetup](http://wimlds.org/chapters/about-bay-area/)所做的演讲，该演讲由[Affirm](https://lilianweng.github.io/posts/2017-06-21-overview/www.affirm.com)主办。)

> (The post was originated from my talk for [WiMLDS x Fintech meetup](http://wimlds.org/chapters/about-bay-area/) hosted by [Affirm](https://lilianweng.github.io/posts/2017-06-21-overview/www.affirm.com).)

我相信你们许多人都看过或听说过2016年[比赛](https://youtu.be/vFr3K2DORc8)，即AlphaGo与职业围棋选手[李世石](https://en.wikipedia.org/wiki/Lee_Sedol)之间的对弈。李世石拥有九段最高段位和多项世界冠军。毫无疑问，他是世界上最好的围棋选手之一，但他在与AlphaGo的系列赛中[以1-4落败](https://www.scientificamerican.com/article/how-the-computer-beat-the-go-master/)。在此之前，围棋被认为是计算机难以掌握的棘手游戏，因为其简单的规则在棋盘位置上产生了指数级的变化，比国际象棋多得多。这一事件无疑凸显了2016年是人工智能的重要一年。由于AlphaGo，人工智能的进展受到了广泛关注。

> I believe many of you have watched or heard of the [games](https://youtu.be/vFr3K2DORc8) between AlphaGo and professional Go player [Lee Sedol](https://en.wikipedia.org/wiki/Lee_Sedol) in 2016. Lee has the highest rank of nine dan and many world championships. No doubt, he is one of the best Go players in the world, but he [lost by 1-4](https://www.scientificamerican.com/article/how-the-computer-beat-the-go-master/) in this series versus AlphaGo. Before this, Go was considered to be an intractable game for computers to master, as its simple rules lay out an exponential number of variations in the board positions, many more than what in Chess. This event surely highlighted 2016 as a big year for AI. Because of AlphaGo, much attention has been attracted to the progress of AI.

与此同时，许多公司正在投入资源，推动人工智能应用的边界，这些应用确实有可能改变甚至彻底改变我们的生活方式。常见的例子包括自动驾驶汽车、聊天机器人、家庭助理设备等等。近年来我们取得进步的秘诀之一是深度学习。

> Meanwhile, many companies are spending resources on pushing the edges of AI applications, that indeed have the potential to change or even revolutionize how we are gonna live. Familiar examples include self-driving cars, chatbots, home assistant devices and many others. One of the secret receipts behind the progress we have had in recent years is deep learning.

### 深度学习为何现在才奏效？

> Why Does Deep Learning Work Now?

简单来说，深度学习模型是大型且深层的人工神经网络。神经网络（“NN”）可以用[有向无环图](https://en.wikipedia.org/wiki/Directed_acyclic_graph)很好地表示：输入层接收信号向量；一个或多个隐藏层处理前一层的输出。神经网络的最初概念可以追溯到[半个多世纪前](https://cs.stanford.edu/people/eroberts/courses/soco/projects/neural-networks/History/history1.html)。但它为什么现在才奏效？为什么人们突然开始谈论它们？

> Deep learning models, in simple words, are large and deep artificial neural nets. A neural network (“NN”) can be well presented in a [directed acyclic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph): the input layer takes in signal vectors; one or multiple hidden layers process the outputs of the previous layer. The initial concept of a neural network can be traced back to more than [half a century ago](https://cs.stanford.edu/people/eroberts/courses/soco/projects/neural-networks/History/history1.html). But why does it work now? Why do people start talking about them all of a sudden?

![A three-layer artificial neural network. (Image source: http://cs231n.github.io/convolutional-networks/#conv )](https://lilianweng.github.io/posts/2017-06-21-overview/ANN.png)

原因出奇地简单：

> The reason is surprisingly simple:

- 我们拥有**更多数据**。
- 我们拥有**更强大的计算机**。

> • We have a lot **more data**.
> • We have **much powerful computers**.

一个大型深度神经网络拥有更多的层和每层更多的节点，这导致需要调整的参数呈指数级增长。如果没有足够的数据，我们无法有效地学习参数。如果没有强大的计算机，学习将会太慢且不足。

> A large and deep neural network has many more layers + many more nodes in each layer, which results in exponentially many more parameters to tune. Without enough data, we cannot learn parameters efficiently. Without powerful computers, learning would be too slow and insufficient.

这里有一个有趣的图表，展示了数据规模与模型性能之间的关系，由 Andrew Ng 在他的“[深度学习的实用技巧](https://youtu.be/F1ka6a13S9I)”演讲中提出。在小型数据集上，传统算法（回归、随机森林、支持向量机、梯度提升机等）或统计学习表现出色，但一旦数据规模急剧增加，大型神经网络就会超越其他模型。部分原因是，与传统机器学习模型相比，神经网络模型拥有更多的参数，并能够学习复杂的非线性模式。因此，我们期望模型能够自行选择最有用的特征，而无需过多专家参与的手动特征工程。

> Here is an interesting plot presenting the relationship between the data scale and the model performance, proposed by Andrew Ng in his “[Nuts and Bolts of Applying Deep Learning](https://youtu.be/F1ka6a13S9I)” talk. On a small dataset, traditional algorithms (Regression, Random Forests, SVM, GBM, etc.) or statistical learning does a great job, but once the data scale goes up to the sky, the large NN outperforms others. Partially because compared to a traditional ML model, a neural network model has many more parameters and has the capability to learn complicated nonlinear patterns. Thus we expect the model to pick the most helpful features by itself without too much expert-involved manual feature engineering.

![The data scale versus the model performance. (Recreated based on: https://youtu.be/F1ka6a13S9I )](https://lilianweng.github.io/posts/2017-06-21-overview/data_size_vs_model_performance.png)

### 深度学习模型

> Deep Learning Models

接下来，我们来了解几个经典的深度学习模型。

> Next, let’s go through a few classical deep learning models.

#### 卷积神经网络

> Convolutional Neural Network

卷积神经网络，简称“CNN”，是一种前馈人工神经网络，其神经元之间的连接模式受到视觉皮层系统组织的启发。初级视觉皮层（V1）从视网膜的原始视觉输入中进行边缘检测。次级视觉皮层（V2），也称为纹外皮层，接收来自V1的边缘特征并提取简单的视觉属性，如方向、空间频率和颜色。视觉区域V4处理更复杂的对象属性。所有处理过的视觉特征流入最终的逻辑单元——颞下回（IT），用于对象识别。V1和V4之间的捷径启发了一种特殊类型的CNN，它具有非相邻层之间的连接：残差网络（[He, et al. 2016](http://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/He_Deep_Residual_Learning_CVPR_2016_paper.pdf)），其中包含“残差块”，支持将一层的一些输入传递给两层后的组件。

> Convolutional neural networks, short for “CNN”, is a type of feed-forward artificial neural networks, in which the connectivity pattern between its neurons is inspired by the organization of the visual cortex system. The primary visual cortex (V1) does edge detection out of the raw visual input from the retina. The secondary visual cortex (V2), also called prestriate cortex, receives the edge features from V1 and extracts simple visual properties such as orientation, spatial frequency, and color. The visual area V4 handles more complicated object attributes. All the processed visual features flow into the final logic unit, inferior temporal gyrus (IT), for object recognition. The shortcut between V1 and V4 inspires a special type of CNN with connections between non-adjacent layers: Residual Net ([He, et al. 2016](http://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/He_Deep_Residual_Learning_CVPR_2016_paper.pdf)) containing “Residual Block” which supports some input of one layer to be passed to the component two layers later.

![Illustration of the human visual cortex system. (Image source: Wang & Raj 2017 )](https://lilianweng.github.io/posts/2017-06-21-overview/visual_cortex_system.png)

卷积是一个数学术语，这里指两个矩阵之间的运算。卷积层有一个固定的、定义好的小矩阵，也称为核或滤波器。当核在输入图像的矩阵表示上滑动或卷积时，它会计算核矩阵中的值与原始图像值之间的逐元素乘法。[特殊设计的核](http://setosa.io/ev/image-kernels/)可以快速高效地处理图像，用于模糊、锐化、边缘检测等常见目的。

> Convolution is a mathematical term, here referring to an operation between two matrices. The convolutional layer has a fixed small matrix defined, also called kernel or filter. As the kernel is sliding, or convolving, across the matrix representation of the input image, it is computing the element-wise multiplication of the values in the kernel matrix and the original image values. [Specially designed kernels](http://setosa.io/ev/image-kernels/) can process images for common purposes like blurring, sharpening, edge detection and many others, fast and efficiently.

![The LeNet architecture consists of two sets of convolutional, activation, and pooling layers, followed by a fully-connected layer, activation, another fully-connected layer, and finally a softmax classifier (Image source: http://deeplearning.net/tutorial/lenet.html )](https://lilianweng.github.io/posts/2017-06-21-overview/lenet.png)

[卷积层](http://ufldl.stanford.edu/tutorial/supervised/FeatureExtractionUsingConvolution/)和[池化层](http://ufldl.stanford.edu/tutorial/supervised/Pooling/)（或图4中的“子采样”）的作用类似于V1、V2和V4视觉皮层单元，负责特征提取。对象识别的推理发生在后续的全连接层中，这些层消耗提取的特征。

> [Convolutional](http://ufldl.stanford.edu/tutorial/supervised/FeatureExtractionUsingConvolution/) and [pooling](http://ufldl.stanford.edu/tutorial/supervised/Pooling/) (or “sub-sampling” in Fig. 4) layers act like the V1, V2 and V4 visual cortex units, responding to feature extraction. The object recognition reasoning happens in the later fully-connected layers which consume the extracted features.

#### 循环神经网络

> Recurrent Neural Network

序列模型通常旨在将输入序列转换为位于不同领域的输出序列。循环神经网络，简称“RNN”，适用于此目的，并在手写识别、语音识别和机器翻译等问题中取得了巨大进步（[Sutskever et al. 2011](http://machinelearning.wustl.edu/mlpapers/paper_files/ICML2011Sutskever_524.pdf), [Liwicki et al. 2007](http://www6.in.tum.de/Main/Publications/Liwicki2007a.pdf)）。

> A sequence model is usually designed to transform an input sequence into an output sequence that lives in a different domain. Recurrent neural network, short for “RNN”, is suitable for this purpose and has shown tremendous improvement in problems like handwriting recognition, speech recognition, and machine translation ([Sutskever et al. 2011](http://machinelearning.wustl.edu/mlpapers/paper_files/ICML2011Sutskever_524.pdf), [Liwicki et al. 2007](http://www6.in.tum.de/Main/Publications/Liwicki2007a.pdf)).

循环神经网络模型天生具备处理长序列数据和解决时间上下文传播任务的能力。该模型在一个时间步处理序列中的一个元素。计算完成后，新更新的单元状态会传递到下一个时间步，以促进下一个元素的计算。想象一下，当一个RNN模型逐字符读取所有维基百科文章后，它能够根据上下文预测后续单词的情况。

> A recurrent neural network model is born with the capability to process long sequential data and to tackle tasks with context spreading in time. The model processes one element in the sequence at one time step. After computation, the newly updated unit state is passed down to the next time step to facilitate the computation of the next element. Imagine the case when an RNN model reads all the Wikipedia articles, character by character, and then it can predict the following words given the context.

![A recurrent neural network with one hidden unit (left) and its unrolling version in time (right). The unrolling version illustrates what happens in time: $s\_{t-1}$, $s\_{t}$, and $s\_{t+1}$ are the same unit with different states at different time steps $t-1$, $t$, and $t+1$. (Image source: LeCun, Bengio, and Hinton, 2015 ; Fig. 5 )](https://lilianweng.github.io/posts/2017-06-21-overview/RNN.png)

然而，简单地将当前输入元素和上一个单元状态线性组合的感知器神经元很容易丢失长期依赖关系。例如，我们用“Alice is working at …”开始一个句子，然后在一整段之后，我们想正确地用“She”或“He”开始下一个句子。如果模型忘记了人物的名字“Alice”，我们就永远无法知道。为了解决这个问题，研究人员创建了一种具有更复杂内部结构的特殊神经元，用于记忆长期上下文，命名为[“长短期记忆（LSTM）”](http://web.eecs.utk.edu/~itamar/courses/ECE-692/Bobby_paper1.pdf)单元。它足够智能，可以学习应该记忆旧信息多长时间，何时遗忘，何时利用新数据，以及如何将旧记忆与新输入结合。这篇[介绍](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)写得非常好，我推荐所有对LSTM感兴趣的人阅读。它已在[Tensorflow documentation](https://www.tensorflow.org/tutorials/recurrent)中得到官方推广 ;-)

> However, simple perceptron neurons that linearly combine the current input element and the last unit state may easily lose the long-term dependencies. For example, we start a sentence with “Alice is working at …” and later after a whole paragraph, we want to start the next sentence with “She” or “He” correctly. If the model forgets the character’s name “Alice”, we can never know. To resolve the issue, researchers created a special neuron with a much more complicated internal structure for memorizing long-term context, named [“Long-short term memory (LSTM)”](http://web.eecs.utk.edu/~itamar/courses/ECE-692/Bobby_paper1.pdf) cell. It is smart enough to learn for how long it should memorize the old information, when to forget, when to make use of the new data, and how to combine the old memory with new input. This [introduction](http://colah.github.io/posts/2015-08-Understanding-LSTMs/) is so well written that I recommend everyone with interest in LSTM to read it. It has been officially promoted in the [Tensorflow documentation](https://www.tensorflow.org/tutorials/recurrent) ;-)

![The structure of a LSTM cell. (Image source: http://colah.github.io/posts/2015-08-Understanding-LSTMs )](https://lilianweng.github.io/posts/2017-06-21-overview/LSTM.png)

为了展示RNN的强大功能，[Andrej Karpathy](http://karpathy.github.io/2015/05/21/rnn-effectiveness/)使用带有LSTM单元的RNN构建了一个基于字符的语言模型。在不预先了解任何英语词汇的情况下，该模型可以学习字符之间的关系以形成单词，然后学习单词之间的关系以形成句子。即使没有大量的训练数据，它也能达到不错的性能。

> To demonstrate the power of RNNs, [Andrej Karpathy](http://karpathy.github.io/2015/05/21/rnn-effectiveness/) built a character-based language model using RNN with LSTM cells.  Without knowing any English vocabulary beforehand, the model could learn the relationship between characters to form words and then the relationship between words to form sentences. It could achieve a decent performance even without a huge set of training data.

![A character-based recurrent neural network model writes like a Shakespeare. (Image source: http://karpathy.github.io/2015/05/21/rnn-effectiveness )](https://lilianweng.github.io/posts/2017-06-21-overview/rnn_shakespeare.png)

#### RNN：序列到序列模型

> RNN: Sequence-to-Sequence Model

[序列到序列模型](https://arxiv.org/pdf/1406.1078.pdf)是RNN的扩展版本，但其应用领域足够独特，我希望将其单独列出。与RNN相同，序列到序列模型在序列数据上运行，但它特别常用于开发聊天机器人或个人助理，两者都能为输入问题生成有意义的响应。序列到序列模型由两个RNN组成：编码器和解码器。编码器从输入词中学习上下文信息，然后通过一个“**上下文向量**”（或“思想向量”，如图8所示）将知识传递给解码器。最后，解码器消耗上下文向量并生成适当的响应。

> The [sequence-to-sequence model](https://arxiv.org/pdf/1406.1078.pdf) is an extended version of RNN, but its application field is distinguishable enough that I would like to list it in a separated section. Same as RNN, a sequence-to-sequence model operates on sequential data, but particularly it is commonly used to develop chatbots or personal assistants, both generating meaningful response for input questions. A sequence-to-sequence model consists of two RNNs, encoder and decoder. The encoder learns the contextual information from the input words and then hands over the knowledge to the decoder side through a “**context vector**” (or “thought vector”, as shown in Fig 8.). Finally, the decoder consumes the context vector and generates proper responses.

![A sequence-to-sequence model for generating Gmail auto replies. (Image source: https://research.googleblog.com/2015/11/computer-respond-to-this-email.html )](https://lilianweng.github.io/posts/2017-06-21-overview/seq2seq_gmail.png)

#### 自编码器

> Autoencoders

与之前的模型不同，自编码器用于无监督学习。它旨在学习**高维**数据集的**低维**表示，类似于[主成分分析（PCA）](https://en.wikipedia.org/wiki/Principal_component_analysis)所做的工作。自编码器模型试图学习一个近似函数$f(x) \approx x$来重现输入数据。然而，它受到中间一个节点数量非常少的瓶颈层的限制。由于容量有限，模型被迫形成一种非常高效的数据编码，这本质上就是我们学到的低维代码。

英文原文：Different from the previous models, autoencoders are for unsupervised learning. It is designed to learn a low-dimensional representation of a high-dimensional data set, similar to what [Principal Components Analysis (PCA)](https://en.wikipedia.org/wiki/Principal_component_analysis) does. The autoencoder model tries to learn an approximation function 

$f(x) \approx x$ to reproduce the input data. However, it is restricted by a bottleneck layer in the middle with a very small number of nodes. With limited capacity, the model is forced to form a very efficient encoding of the data, that is essentially the low-dimensional code we learned.

![An autoencoder model has a bottleneck layer with only a few neurons. (Image source: Geoffrey Hinton’s Coursera class "Neural Networks for Machine Learning" - Week 15 )](https://lilianweng.github.io/posts/2017-06-21-overview/autoencoder.png)

[Hinton and Salakhutdinov](https://pdfs.semanticscholar.org/7d76/b71b700846901ac4ac119403aa737a285e36.pdf)使用自编码器压缩各种主题的文档。如图10所示，当PCA和自编码器都被应用于将文档降维到两维时，自编码器表现出更好的结果。借助自编码器，我们可以进行高效的数据压缩，以加速包括文档和图像在内的信息检索。

> [Hinton and Salakhutdinov](https://pdfs.semanticscholar.org/7d76/b71b700846901ac4ac119403aa737a285e36.pdf) used autoencoders to compress documents on a variety of topics. As shown in Fig 10, when both PCA and autoencoder were applied to reduce the documents onto two dimensions, autoencoder demonstrated a much better outcome. With the help of autoencoder, we can do efficient data compression to speed up the information retrieval including both documents and images.

![The outputs of PCA (left) and autoencoder (right) when both try to compress documents into two numbers. (Image source: Hinton & Salakhutdinov 2006 )](https://lilianweng.github.io/posts/2017-06-21-overview/autoencoder_experiment.png)

### 强化（深度）学习

> Reinforcement (Deep) Learning

既然我以AlphaGo开始我的文章，那么让我们深入探讨一下AlphaGo为何成功。[强化学习（“RL”）](https://en.wikipedia.org/wiki/Reinforcement_learning)是其成功背后的秘密之一。RL是机器学习的一个子领域，它允许机器和软件代理在给定上下文中自动确定最佳行为，目标是最大化由给定指标衡量的长期性能。

> Since I started my post with AlphaGo, let us dig a bit more on why AlphaGo worked out. [Reinforcement learning (“RL”)](https://en.wikipedia.org/wiki/Reinforcement_learning) is one of the secrets behind its success. RL is a subfield of machine learning which allows machines and software agents to automatically determine the optimal behavior within a given context, with a goal to maximize the long-term performance measured by a given metric.

![AlphaGo neural network training pipeline and architecture. (Image source: Silver et al. 2016 )](https://lilianweng.github.io/posts/2017-06-21-overview/alphago_paper.png)

![AlphaGo neural network training pipeline and architecture. (Image source: Silver et al. 2016 )](https://lilianweng.github.io/posts/2017-06-21-overview/alphago_model.png)

AlphaGo系统首先通过监督学习过程来训练一个快速展开策略和一个策略网络，这依赖于专业棋手对弈的人工整理训练数据集。它学习在给定当前棋盘位置下的最佳策略。然后，它通过设置自对弈游戏来应用强化学习。当RL策略网络在与之前版本的策略网络的对弈中赢得越来越多的比赛时，它会得到改进。在自对弈阶段，AlphaGo通过与自己对弈而变得越来越强大，无需额外的外部训练数据。

> The AlphaGo system starts with a supervised learning process to train a fast rollout policy and a policy network, relying on the manually curated training dataset of professional players’ games. It learns what is the best strategy given the current position on the game board. Then it applies reinforcement learning by setting up self-play games. The RL policy network gets improved when it wins more and more games against previous versions of the policy network. In the self-play stage, AlphaGo becomes stronger and stronger by playing against itself without requiring additional external training data.

#### 生成对抗网络

> Generative Adversarial Network

[生成对抗网络](https://arxiv.org/pdf/1406.2661.pdf)，简称“GAN”，是一种深度生成模型。GAN能够在学习真实数据后创建新的示例。它由两个模型在一个零和博弈框架中相互竞争组成。著名的深度学习研究员[Yann LeCun](http://yann.lecun.com/)对其给予了极高的评价：生成对抗网络是过去十年机器学习中最有趣的想法。（参见Quora问题：[“What are some recent and potentially upcoming breakthroughs in deep learning?”](https://www.quora.com/What-are-some-recent-and-potentially-upcoming-breakthroughs-in-deep-learning)）

> [Generative adversarial network](https://arxiv.org/pdf/1406.2661.pdf), short for “GAN”, is a type of deep generative models. GAN is able to create new examples after learning through the real data.  It is consist of two models competing against each other in a zero-sum game framework. The famous deep learning researcher [Yann LeCun](http://yann.lecun.com/) gave it a super high praise: Generative Adversarial Network is the most interesting idea in the last ten years in machine learning. (See the Quora question: [“What are some recent and potentially upcoming breakthroughs in deep learning?”](https://www.quora.com/What-are-some-recent-and-potentially-upcoming-breakthroughs-in-deep-learning))

![The architecture of a generative adversarial network. (Image source: http://www.kdnuggets.com/2017/01/generative-adversarial-networks-hot-topic-machine-learning.html )](https://lilianweng.github.io/posts/2017-06-21-overview/GAN.png)

在[原始GAN论文](https://arxiv.org/pdf/1406.2661.pdf)中，GAN被提出用于在学习真实照片后生成有意义的图像。它由两个独立的模型组成：**生成器**和**判别器**。生成器生成假图像并将其输出发送给判别器模型。判别器像一个裁判，因为它被优化用于从假图像中识别真实照片。生成器模型努力欺骗判别器，而判别器则努力不被欺骗。这两个模型之间这种有趣的零和博弈促使两者都发展其设计技能并改进其功能。最终，我们使用生成器模型来生成新图像。

> In the [original GAN paper](https://arxiv.org/pdf/1406.2661.pdf), GAN was proposed to generate meaningful images after learning from real photos. It comprises two independent models: the **Generator** and the **Discriminator**. The generator produces fake images and sends the output to the discriminator model. The discriminator works like a judge, as it is optimized for identifying the real photos from the fake ones. The generator model is trying hard to cheat the discriminator while the judge is trying hard not to be cheated. This interesting zero-sum game between these two models motivates both to develop their designed skills and improve their functionalities. Eventually, we take the generator model for producing new images.

### 工具包和库

> Toolkits and Libraries

在学习了所有这些模型之后，你可能会开始思考如何实现这些模型并将其用于实际。幸运的是，我们有许多开源工具包和库来构建深度学习模型。[Tensorflow](https://www.tensorflow.org/) 相对较新，但已吸引了大量关注。事实证明，TensorFlow 是 [2015年GitHub上被fork最多的项目](http://deliprao.com/archives/168)。所有这些都发生在其于2015年11月发布后的2个月内。

> After learning all these models, you may start wondering how you can implement the models and use them for real. Fortunately, we have many open source toolkits and libraries for building deep learning models. [Tensorflow](https://www.tensorflow.org/) is fairly new but has attracted a lot of popularity. It turns out, TensorFlow was [the most forked Github project of 2015](http://deliprao.com/archives/168). All that happened in a period of 2 months after its release in Nov 2015.

![](https://lilianweng.github.io/posts/2017-06-21-overview/deep_learning_toolkits.png)

### 如何学习？

> How to Learn?

如果你是这个领域的新手，并且愿意投入一些时间以更系统的方式学习深度学习，我建议你从这本书开始：《[Deep Learning](https://www.amazon.com/Deep-Learning-Adaptive-Computation-Machine/dp/0262035618/ref=sr_1_1?s=books&ie=UTF8&qid=1499413305&sr=1-1&keywords=deep+learning)》，作者是 Ian Goodfellow、Yoshua Bengio 和 Aaron Courville。还有 Geoffrey Hinton 的 Coursera 课程 [“Neural Networks for Machine Learning”](https://www.coursera.org/learn/neural-networks)（[深度学习教父！](https://youtu.be/uAu3jQWaN6E)）。该课程的内容大约在2006年准备，虽然有些旧，但它能帮助你为理解深度学习模型打下坚实的基础，并加速进一步的探索。

> If you are very new to the field and willing to devote some time to studying deep learning in a more systematic way, I would recommend you to start with the book [Deep Learning](https://www.amazon.com/Deep-Learning-Adaptive-Computation-Machine/dp/0262035618/ref=sr_1_1?s=books&ie=UTF8&qid=1499413305&sr=1-1&keywords=deep+learning) by Ian Goodfellow, Yoshua Bengio, and Aaron Courville. The Coursera course [“Neural Networks for Machine Learning”](https://www.coursera.org/learn/neural-networks) by Geoffrey Hinton ([Godfather of deep learning!](https://youtu.be/uAu3jQWaN6E)). The content for the course was prepared around 2006, pretty old, but it helps you build up a solid foundation for understanding deep learning models and expedite further exploration.

同时，保持你的好奇心和热情。这个领域每天都在进步。即使是经典或广泛采用的深度学习模型，也可能只是在1-2年前才被提出。阅读学术论文可以帮助你深入学习并跟上最前沿的发现。

> Meanwhile, maintain your curiosity and passion. The field is making progress every day. Even classical or widely adopted deep learning models may just have been proposed 1-2 years ago. Reading academic papers can help you learn stuff in depth and keep up with the cutting-edge findings.

##### 有用资源

> Useful resources

- Google 学术搜索：[http://scholar.google.com](http://scholar.google.com)
- arXiv 计算机科学版块：[https://arxiv.org/list/cs/recent](https://arxiv.org/list/cs/recent)
- [Unsupervised Feature Learning and Deep Learning Tutorial](http://ufldl.stanford.edu/tutorial/)
- [Tensorflow 教程](https://www.tensorflow.org/tutorials/)
- 数据科学周刊
- [KDnuggets](http://www.kdnuggets.com/2017/01/generative-adversarial-networks-hot-topic-machine-learning.html)
- 大量的博客文章和在线教程
- 相关 [Cousera](http://coursera.com) 课程
- [awesome-deep-learning-papers](https://github.com/terryum/awesome-deep-learning-papers)

> • Google Scholar: [http://scholar.google.com](http://scholar.google.com)
> • arXiv cs section: [https://arxiv.org/list/cs/recent](https://arxiv.org/list/cs/recent)
> • [Unsupervised Feature Learning and Deep Learning Tutorial](http://ufldl.stanford.edu/tutorial/)
> • [Tensorflow Tutorials](https://www.tensorflow.org/tutorials/)
> • Data Science Weekly
> • [KDnuggets](http://www.kdnuggets.com/2017/01/generative-adversarial-networks-hot-topic-machine-learning.html)
> • Tons of blog posts and online tutorials
> • Related [Cousera](http://coursera.com) courses
> • [awesome-deep-learning-papers](https://github.com/terryum/awesome-deep-learning-papers)

##### 提及的博客文章

> Blog posts mentioned

- [视觉解释：图像核](http://setosa.io/ev/image-kernels)
- [理解 LSTM 网络](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)
- [循环神经网络的非凡有效性](http://karpathy.github.io/2015/05/21/rnn-effectiveness/)
- [电脑，回复这封邮件。](https://research.googleblog.com/2015/11/computer-respond-to-this-email.html)

> • [Explained Visually: Image Kernels](http://setosa.io/ev/image-kernels)
> • [Understanding LSTM Networks](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)
> • [The Unreasonable Effectiveness of Recurrent Neural Networks](http://karpathy.github.io/2015/05/21/rnn-effectiveness/)
> • [Computer, respond to this email.](https://research.googleblog.com/2015/11/computer-respond-to-this-email.html)

##### 值得一看的有趣博客

> Interesting blogs worthy of checking

- [www.wildml.com](http://www.wildml.com)
- [colah.github.io](http://colah.github.io/)
- [karpathy.github.io](http://karpathy.github.io/)
- [blog.openai.com](https://blog.openai.com)

> • [www.wildml.com](http://www.wildml.com)
> • [colah.github.io](http://colah.github.io/)
> • [karpathy.github.io](http://karpathy.github.io/)
> • [blog.openai.com](https://blog.openai.com)

##### 提及的论文

> Papers mentioned

[1] He, Kaiming, et al. [“用于图像识别的深度残差学习。”](http://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/He_Deep_Residual_Learning_CVPR_2016_paper.pdf) Proc. IEEE Conf. on computer vision and pattern recognition. 2016.

> [1] He, Kaiming, et al. [“Deep residual learning for image recognition.”](http://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/He_Deep_Residual_Learning_CVPR_2016_paper.pdf) Proc. IEEE Conf. on computer vision and pattern recognition. 2016.

[2] Wang, Haohan, Bhiksha Raj, and Eric P. Xing. [“深度学习的起源。”](https://arxiv.org/pdf/1702.07800.pdf) arXiv preprint arXiv:1702.07800, 2017.

> [2] Wang, Haohan, Bhiksha Raj, and Eric P. Xing. [“On the Origin of Deep Learning.”](https://arxiv.org/pdf/1702.07800.pdf) arXiv preprint arXiv:1702.07800, 2017.

[3] Sutskever, Ilya, James Martens, and Geoffrey E. Hinton. [“使用循环神经网络生成文本。”](http://machinelearning.wustl.edu/mlpapers/paper_files/ICML2011Sutskever_524.pdf) Proc. of the 28th Intl. Conf. on Machine Learning (ICML). 2011.

> [3] Sutskever, Ilya, James Martens, and Geoffrey E. Hinton. [“Generating text with recurrent neural networks.”](http://machinelearning.wustl.edu/mlpapers/paper_files/ICML2011Sutskever_524.pdf) Proc. of the 28th Intl. Conf. on Machine Learning (ICML). 2011.

[4] Liwicki, Marcus, et al. [“一种基于双向长短期记忆网络的在线手写识别新方法。”](http://www6.in.tum.de/Main/Publications/Liwicki2007a.pdf) Proc. of 9th Intl. Conf. on Document Analysis and Recognition. 2007.

> [4] Liwicki, Marcus, et al. [“A novel approach to on-line handwriting recognition based on bidirectional long short-term memory networks.”](http://www6.in.tum.de/Main/Publications/Liwicki2007a.pdf) Proc. of 9th Intl. Conf. on Document Analysis and Recognition. 2007.

[5] LeCun, Yann, Yoshua Bengio, and Geoffrey Hinton. [“深度学习。”](http://pages.cs.wisc.edu/~dyer/cs540/handouts/deep-learning-nature2015.pdf) Nature 521.7553 (2015): 436-444.

> [5] LeCun, Yann, Yoshua Bengio, and Geoffrey Hinton. [“Deep learning.”](http://pages.cs.wisc.edu/~dyer/cs540/handouts/deep-learning-nature2015.pdf) Nature 521.7553 (2015): 436-444.

[6] Hochreiter, Sepp, and Jurgen Schmidhuber. [“长短期记忆。”](http://web.eecs.utk.edu/~itamar/courses/ECE-692/Bobby_paper1.pdf) Neural computation 9.8 (1997): 1735-1780.

> [6] Hochreiter, Sepp, and Jurgen Schmidhuber. [“Long short-term memory.”](http://web.eecs.utk.edu/~itamar/courses/ECE-692/Bobby_paper1.pdf) Neural computation 9.8 (1997): 1735-1780.

[7] Cho, Kyunghyun. et al. [“使用RNN编码器-解码器学习短语表示以进行统计机器翻译。”](https://arxiv.org/pdf/1406.1078.pdf) Proc. Conference on Empirical Methods in Natural Language Processing 1724–1734 (2014).

> [7] Cho, Kyunghyun. et al. [“Learning phrase representations using RNN encoder-decoder for statistical machine translation.”](https://arxiv.org/pdf/1406.1078.pdf) Proc. Conference on Empirical Methods in Natural Language Processing 1724–1734 (2014).

[8] Hinton, Geoffrey E., and Ruslan R. Salakhutdinov. [“使用神经网络降低数据维度。”](https://pdfs.semanticscholar.org/7d76/b71b700846901ac4ac119403aa737a285e36.pdf) science 313.5786 (2006): 504-507.

> [8] Hinton, Geoffrey E., and Ruslan R. Salakhutdinov. [“Reducing the dimensionality of data with neural networks.”](https://pdfs.semanticscholar.org/7d76/b71b700846901ac4ac119403aa737a285e36.pdf) science 313.5786 (2006): 504-507.

[9] Silver, David, et al. [“使用深度神经网络和树搜索掌握围棋。”](http://web.iitd.ac.in/~sumeet/Silver16.pdf) Nature 529.7587 (2016): 484-489.

> [9] Silver, David, et al. [“Mastering the game of Go with deep neural networks and tree search.”](http://web.iitd.ac.in/~sumeet/Silver16.pdf) Nature 529.7587 (2016): 484-489.

[10] Goodfellow, Ian, et al. [“生成对抗网络。”](https://arxiv.org/pdf/1406.2661.pdf) NIPS, 2014.

> [10] Goodfellow, Ian, et al. [“Generative adversarial nets.”](https://arxiv.org/pdf/1406.2661.pdf) NIPS, 2014.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Deep Learning | 深度学习 | 一种机器学习方法，使用多层人工神经网络从数据中学习复杂模式。 |
| Artificial Neural Network (ANN) | 人工神经网络 | 模拟生物神经系统结构和功能的计算模型，由相互连接的节点组成。 |
| Convolutional Neural Network (CNN) | 卷积神经网络 | 一种特殊类型的前馈神经网络，通过卷积层和池化层进行特征提取，主要用于图像处理。 |
| Recurrent Neural Network (RNN) | 循环神经网络 | 一种适用于处理序列数据的神经网络，其内部状态可以记忆历史信息。 |
| Long Short-Term Memory (LSTM) | 长短期记忆 | 一种特殊的RNN单元，通过门控机制有效解决了传统RNN的长期依赖问题。 |
| Sequence-to-Sequence (Seq2Seq) Model | 序列到序列模型 | 由编码器和解码器组成的RNN扩展，用于将输入序列转换为不同领域的输出序列，常用于机器翻译和聊天机器人。 |
| Autoencoder | 自编码器 | 一种无监督学习神经网络，旨在学习高维数据的低维表示或编码。 |
| Reinforcement Learning (RL) | 强化学习 | 机器学习的一个子领域，通过代理与环境交互，学习在特定情境下最大化奖励的最佳行为。 |
| Generative Adversarial Network (GAN) | 生成对抗网络 | 由生成器和判别器组成的深度生成模型，通过零和博弈学习并生成新的数据样本。 |
| TensorFlow | TensorFlow | 一个由Google开发的开源机器学习框架，广泛用于构建和训练深度学习模型。 |
| Feature Engineering | 特征工程 | 从原始数据中选择、转换和创建新特征的过程，以提高机器学习模型的性能。 |
| Context Vector | 上下文向量 | 在序列到序列模型中，编码器将输入序列的语义信息压缩成的固定长度向量，传递给解码器。 |
| Unsupervised Learning | 无监督学习 | 机器学习的一种类型，模型在没有标签数据的情况下，从数据中发现模式或结构。 |
| AlphaGo | AlphaGo | 由DeepMind开发的人工智能围棋程序，结合了深度学习和强化学习技术。 |
