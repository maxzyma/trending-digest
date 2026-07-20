# 使用 RNN 预测股票价格：第一部分

> Predict Stock Prices Using RNN: Part 1

> 来源：Lil'Log / Lilian Weng，2017-07-08
> 原文链接：https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/
> 分类：机器学习 / 股票预测

## 核心要点

- 本文旨在演示如何使用Tensorflow构建和训练循环神经网络（RNN）模型以预测股票价格，而非专注于提高预测精度。
- 作者指出现有Tensorflow RNN教程存在API过时、使用合成数据以及对Tensorflow API知识有较高要求等问题。
- 目标是利用带有长短期记忆（LSTM）单元的RNN模型，基于S&P500指数的每日收盘价进行价格预测。
- 数据准备涉及将股票价格序列分割成固定大小的滑动窗口，并采用“展开式”RNN版本进行训练，其中`num_steps`定义了反向传播的长度。
- 为解决测试集价格超出训练集范围的问题，文章提出对每个滑动窗口内的价格进行归一化，以预测相对变化率。
- 模型构建包括定义多层堆叠的LSTM单元，并应用dropout防止过拟合，同时详细阐述了Tensorflow图的定义和训练会话的启动过程。
- 文章强调了使用TensorBoard进行图结构可视化、变量跟踪和调试的重要性，并提供了相关API的使用指导。
- 实验结果表明，预测股票价格具有挑战性，尤其是在价格归一化后趋势显得嘈杂。

## 正文

这是一个关于如何使用 Tensorflow 构建循环神经网络来预测股票市场价格的教程。完整的工作代码可在 [github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn) 获取。如果您不知道什么是循环神经网络或 LSTM 单元，请随时查看 [我之前的文章](https://lilianweng.github.io/posts/2017-06-21-overview/#recurrent-neural-network)。

> This is a tutorial for how to build a recurrent neural network using Tensorflow to predict stock market prices. The full working code is available in [github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn). If you don’t know what is recurrent neural network or LSTM cell, feel free to check [my previous post](https://lilianweng.github.io/posts/2017-06-21-overview/#recurrent-neural-network).

> *我想强调一点，因为我写这篇文章的动机更多是为了演示如何在 Tensorflow 中构建和训练 RNN 模型，而不是为了解决股票预测问题，所以我没有在改进预测结果上投入太多精力。非常欢迎您将我的 [代码](https://github.com/lilianweng/stock-rnn) 作为参考点，并添加更多与股票预测相关的想法来改进它。祝您使用愉快！*

> *One thing I would like to emphasize that because my motivation for writing this post is more on demonstrating how to build and train an RNN model in Tensorflow and less on solve the stock prediction problem, I didn’t try hard on improving the prediction outcomes. You are more than welcome to take my [code](https://github.com/lilianweng/stock-rnn) as a reference point and add more stock prediction related ideas to improve it. Enjoy!*

### 现有教程概述

> Overview of Existing Tutorials

互联网上有很多教程，例如：

> There are many tutorials on the Internet, like:

- [Tensorflow 中 RNN-LSTM 实现新手指南](http://monik.in/a-noobs-guide-to-implementing-rnn-lstm-using-tensorflow/)
- [TensorFlow RNN 教程](https://svds.com/tensorflow-rnn-tutorial/)
- [使用 Tensorflow 的 LSTM 示例](https://medium.com/towards-data-science/lstm-by-example-using-tensorflow-feb0c1968537)
- [如何在 TensorFlow 中构建循环神经网络](https://medium.com/@erikhallstrm/hello-world-rnn-83cd7105b767)
- [Tensorflow 中的 RNN：实用指南和未公开特性](http://www.wildml.com/2016/08/rnns-in-tensorflow-a-practical-guide-and-undocumented-features/)
- [使用 TensorFlow 的循环神经网络（LSTM）进行序列预测](http://mourafiq.com/2016/05/15/predicting-sequences-using-rnn-in-tensorflow.html)
- [任何人都可以学习用 Python 编写 LSTM-RNN 代码](https://iamtrask.github.io/2015/11/15/anyone-can-code-lstm/)
- [如何使用 RNN、TensorFlow 和 Cloud ML Engine 进行时间序列预测](https://medium.com/google-cloud/how-to-do-time-series-prediction-using-rnns-and-tensorflow-and-cloud-ml-engine-2ad2eeb189e8)

> • [A noob’s guide to implementing RNN-LSTM using Tensorflow](http://monik.in/a-noobs-guide-to-implementing-rnn-lstm-using-tensorflow/)
> • [TensorFlow RNN Tutorial](https://svds.com/tensorflow-rnn-tutorial/)
> • [LSTM by Example using Tensorflow](https://medium.com/towards-data-science/lstm-by-example-using-tensorflow-feb0c1968537)
> • [How to build a Recurrent Neural Network in TensorFlow](https://medium.com/@erikhallstrm/hello-world-rnn-83cd7105b767)
> • [RNNs in Tensorflow, a Practical Guide and Undocumented Features](http://www.wildml.com/2016/08/rnns-in-tensorflow-a-practical-guide-and-undocumented-features/)
> • [Sequence prediction using recurrent neural networks(LSTM) with TensorFlow](http://mourafiq.com/2016/05/15/predicting-sequences-using-rnn-in-tensorflow.html)
> • [Anyone Can Learn To Code an LSTM-RNN in Python](https://iamtrask.github.io/2015/11/15/anyone-can-code-lstm/)
> • [How to do time series prediction using RNNs, TensorFlow and Cloud ML Engine](https://medium.com/google-cloud/how-to-do-time-series-prediction-using-rnns-and-tensorflow-and-cloud-ml-engine-2ad2eeb189e8)

尽管有所有这些现有的教程，我仍然想写一篇新的，主要有三个原因：

> Despite all these existing tutorials, I still want to write a new one mainly for three reasons:

1. 早期的教程已经无法应对新版本了，因为 Tensorflow 仍在开发中，API 接口的更改速度很快。
2. 许多教程在示例中使用合成数据。嗯，我更喜欢使用真实世界的数据。
3. 有些教程假设你事先了解 Tensorflow API，这使得阅读有些困难。

> • Early tutorials cannot cope with the new version any more, as Tensorflow is still under development and changes on API interfaces are being made fast.
> • Many tutorials use synthetic data in the examples. Well, I would like to play with the real world data.
> • Some tutorials assume that you have known something about Tensorflow API beforehand, which makes the reading a bit difficult.

在阅读了大量示例之后，我建议以 Penn Tree Bank (PTB) 数据集上的[官方示例](https://github.com/tensorflow/models/tree/master/tutorials/rnn/ptb)作为你的起点。PTB 示例以一种漂亮且模块化的设计模式展示了一个 RNN 模型，但这可能会阻碍你轻松理解模型结构。因此，我将在这里以一种非常直接的方式构建图。

> After reading a bunch of examples, I would like to suggest taking the [official example](https://github.com/tensorflow/models/tree/master/tutorials/rnn/ptb) on Penn Tree Bank (PTB) dataset as your starting point. The PTB example showcases a RNN model in a pretty and modular design pattern, but it might prevent you from easily understanding the model structure. Hence, here I will build up the graph in a very straightforward manner.

### 目标

> The Goal

我将解释如何使用带有 LSTM 单元的 RNN 模型来预测 S&P500 指数的价格。数据集可以从 [Yahoo! Finance ^GSPC](https://finance.yahoo.com/quote/%5EGSPC/history?p=%5EGSPC) 下载。在下面的例子中，我使用了从 1950 年 1 月 3 日（Yahoo! Finance 能够追溯到的最远日期）到 2017 年 6 月 23 日的 S&P 500 数据。该数据集每天提供多个价格点。为简单起见，我们只使用每日的 **收盘价** 进行预测。同时，我将演示如何使用 [TensorBoard](https://www.tensorflow.org/get_started/summaries_and_tensorboard) 进行便捷的调试和模型跟踪。

> I will explain how to build an RNN model with LSTM cells to predict the prices of S&P500 index. The dataset can be downloaded from [Yahoo! Finance ^GSPC](https://finance.yahoo.com/quote/%5EGSPC/history?p=%5EGSPC). In the following example, I used S&P 500 data from Jan 3, 1950 (the maximum date that Yahoo! Finance is able to trace back to) to Jun 23, 2017. The dataset provides several price points per day. For simplicity, we will only use the daily **close prices** for prediction. Meanwhile, I will demonstrate how to use [TensorBoard](https://www.tensorflow.org/get_started/summaries_and_tensorboard) for easily debugging and model tracking.

快速回顾一下：循环神经网络（RNN）是一种人工神经网络，其隐藏层中存在自循环，这使得 RNN 能够利用隐藏神经元（或多个神经元）的先前状态，根据新的输入学习当前状态。RNN 擅长处理序列数据。长短期记忆（LSTM）单元是一种特殊设计的工作单元，它有助于 RNN 更好地记忆长期上下文。

> As a quick recap: the recurrent neural network (RNN) is a type of artificial neural network with self-loop in its hidden layer(s), which enables RNN to use the previous state of the hidden neuron(s) to learn the current state given the new input. RNN is good at processing sequential data. Long short-term memory (LSTM) cell is a specially designed working unit that helps RNN better memorize the long-term context.

如需更深入的信息，请阅读[我之前的文章](https://lilianweng.github.io/posts/2017-06-21-overview/#recurrent-neural-network)或[这篇很棒的文章](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)。

> For more information in depth, please read [my previous post](https://lilianweng.github.io/posts/2017-06-21-overview/#recurrent-neural-network) or [this awesome post](http://colah.github.io/posts/2015-08-Understanding-LSTMs/).

### 数据准备

> Data Preparation

股票价格是一个长度为 $N$ 的时间序列，定义为 $p_0, p_1, \dots, p_{N-1}$，其中 $p_i$ 是第 $i$ 天的收盘价，$0 \le i < N$。假设我们有一个固定大小为 $w$ 的滑动窗口（稍后我们将其称为 `input_size`），并且每次我们将窗口向右移动 $w$ 大小，这样所有滑动窗口中的数据之间就没有重叠。

> The stock prices is a time series of length $N$, defined as $p_0, p_1, \dots, p_{N-1}$ in which $p_i$ is the close price on day $i$, $0 \le i < N$. Imagine that we have a sliding window of a fixed size $w$ (later, we refer to this as `input_size`) and every time we move the window to the right by size $w$, so that there is no overlap between data in all the sliding windows.

![The S&P 500 prices in time. We use content in one sliding windows to make prediction for the next, while there is no overlap between two consecutive windows.](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/sliding_window_time_series.svg)

我们即将构建的 RNN 模型以 LSTM 单元作为基本的隐藏单元。我们使用从第一个滑动窗口最开始的值$W_0$到窗口$W_t$在时间$t$:

> The RNN model we are about to build has LSTM cells as basic hidden units. We use values from the very beginning in the first sliding window $W_0$ to the window $W_t$ at time $t$:

$$
\begin{aligned}
W_0 &= (p_0, p_1, \dots, p_{w-1}) \\
W_1 &= (p_w, p_{w+1}, \dots, p_{2w-1}) \\
\dots \\
W_t &= (p_{tw}, p_{tw+1}, \dots, p_{(t+1)w-1})
\end{aligned}
$$

以预测后续窗口中的价格 $w_{t+1}$:

> to predict the prices in the following window $w_{t+1}$:

$$
W_{t+1} = (p_{(t+1)w}, p_{(t+1)w+1}, \dots, p_{(t+2)w-1})
$$

本质上，我们试图学习一个近似函数，$f(W_0, W_1, \dots, W_t) \approx W_{t+1}$。

> Essentially we try to learn an approximation function, $f(W_0, W_1, \dots, W_t) \approx W_{t+1}$.

![Fig. 2 The unrolled version of RNN.](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/unrolled_RNN.png)

考虑到 [通过时间反向传播 (BPTT)](https://en.wikipedia.org/wiki/Backpropagation_through_time) 的工作原理，我们通常以“展开”版本训练 RNN，这样就不必进行过远的传播计算，从而简化训练过程。

> Considering how [back propagation through time (BPTT)](https://en.wikipedia.org/wiki/Backpropagation_through_time) works, we usually train RNN in a “unrolled” version so that we don’t have to do propagation computation too far back and save the training complication.

以下是关于`num_steps`来自[Tensorflow 教程](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/tensorflow.org/tutorials/recurrent)的解释：

> Here is the explanation on `num_steps` from [Tensorflow’s tutorial](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/tensorflow.org/tutorials/recurrent):

> 根据设计，循环神经网络 (RNN) 的输出取决于任意远距离的输入。不幸的是，这使得反向传播计算变得困难。为了使学习过程易于处理，通常的做法是创建一个网络的“展开”版本，其中包含固定数量（`num_steps`）的 LSTM 输入和输出。然后，模型在这个 RNN 的有限近似上进行训练。这可以通过一次馈送长度为`num_steps`的输入，并在每个此类输入块之后执行一次反向传播来实现。

> By design, the output of a recurrent neural network (RNN) depends on arbitrarily distant inputs. Unfortunately, this makes backpropagation computation difficult. In order to make the learning process tractable, it is common practice to create an “unrolled” version of the network, which contains a fixed number (`num_steps`) of LSTM inputs and outputs. The model is then trained on this finite approximation of the RNN. This can be implemented by feeding inputs of length `num_steps` at a time and performing a backward pass after each such input block.

价格序列首先被分割成不重叠的小窗口。每个窗口包含 `input_size` 个数字，并且每个窗口都被视为一个独立的输入元素。然后，任意 `num_steps` 个连续的输入元素被分组为一个训练输入，形成一个用于在 TensorFlow 上训练的 **“展开式”** RNN 版本。相应的标签是紧随其后的输入元素。

> The sequence of prices are first split into non-overlapped small windows. Each contains `input_size` numbers and each is considered as one independent input element. Then any `num_steps` consecutive input elements are grouped into one training input, forming an **“un-rolled”** version of RNN for training on Tensorfow. The corresponding label is the input element right after them.

例如，如果 `input_size=3` 和 `num_steps=2`，我的前几个训练样本将如下所示：

> For instance, if `input_size=3` and `num_steps=2`, my first few training examples would look like:

$$
\begin{aligned}
\text{Input}_1 &= [[p_0, p_1, p_2], [p_3, p_4, p_5]]\quad\text{Label}_1 = [p_6, p_7, p_8] \\
\text{Input}_2 &= [[p_3, p_4, p_5], [p_6, p_7, p_8]]\quad\text{Label}_2 = [p_9, p_{10}, p_{11}] \\
\text{Input}_3 &= [[p_6, p_7, p_8], [p_9, p_{10}, p_{11}]]\quad\text{Label}_3 = [p_{12}, p_{13}, p_{14}] 
\end{aligned}
$$

以下是数据格式化的关键部分：

> Here is the key part for formatting the data:

```python
seq = [np.array(seq[i * self.input_size: (i + 1) * self.input_size]) 
       for i in range(len(seq) // self.input_size)]

# Split into groups of `num_steps`
X = np.array([seq[i: i + self.num_steps] for i in range(len(seq) - self.num_steps)])
y = np.array([seq[i + self.num_steps] for i in range(len(seq) - self.num_steps)])
```

数据格式化的完整代码在 [这里](https://github.com/lilianweng/stock-rnn/blob/master/data_wrapper.py)。

> The complete code of data formatting is [here](https://github.com/lilianweng/stock-rnn/blob/master/data_wrapper.py).

#### 训练/测试集划分

> Train / Test Split

由于我们总是希望预测未来，因此我们将 **最新 10%** 的数据作为测试数据。

> Since we always want to predict the future, we take the **latest 10%** of data as the test data.

#### 归一化

> Normalization

标普500指数随时间增长，导致测试集中的大多数值超出了训练集的范围，因此模型必须*预测一些它从未见过的值*。遗憾但不出所料，它的表现非常糟糕。参见

> The S&P 500 index increases in time, bringing about the problem that most values in the test set are out of the scale of the train set and thus the model has to *predict some numbers it has never seen before*. Sadly and unsurprisingly, it does a tragic job. See 

![Fig. 3 A very sad example when the RNN model have to predict numbers out of the scale of the training data.](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/a_sad_example_stock_prediction.png)

为了解决超出范围的问题，我将每个滑动窗口中的价格进行归一化。任务变成了预测相对变化率而不是绝对值。在一个归一化的滑动窗口$W’_t$在时间$t$，所有值都除以最后一个未知价格——即$W_{t-1}$中的最后一个价格：

> To solve the out-of-scale issue, I normalize the prices in each sliding window. The task becomes predicting the relative change rates instead of the absolute values. In a normalized sliding window $W’_t$ at time $t$, all the values are divided by the last unknown price—the last price in $W_{t-1}$:

$$
W’_t = (\frac{p_{tw}}{p_{tw-1}}, \frac{p_{tw+1}}{p_{tw-1}}, \dots, \frac{p_{(t+1)w-1}}{p_{tw-1}})
$$

这里有一个数据存档[stock-data-lilianweng.tar.gz](https://drive.google.com/open?id=1QKVkiwgCNJsdQMEsfoi6KpqoPgc4O6DD)，包含我截至2017年7月抓取的标普500股票价格。欢迎随意使用 :)

> Here is a data archive [stock-data-lilianweng.tar.gz](https://drive.google.com/open?id=1QKVkiwgCNJsdQMEsfoi6KpqoPgc4O6DD) of S & P 500 stock prices I crawled up to Jul, 2017. Feel free to play with it :)

### 模型构建

> Model Construction

#### 定义

> Definitions

- `lstm_size`：一个LSTM层中的单元数量。
- `num_layers`：堆叠LSTM层的数量。
- `keep_prob`：在[dropout](https://www.cs.toronto.edu/~hinton/absps/JMLRdropout.pdf)操作中保留的单元百分比。
- `init_learning_rate`：初始学习率。
- `learning_rate_decay`：在后续训练周期中的衰减率。
- `init_epoch`：使用常量`init_learning_rate`的周期数。
- `max_epoch`: 训练中的总 epoch 数
- `input_size`: 滑动窗口的大小 / 一个训练数据点
- `batch_size`: 在一个mini-batch中使用的训练数据点的数量。

> • `lstm_size`: number of units in one LSTM layer.
> • `num_layers`: number of stacked LSTM layers.
> • `keep_prob`: percentage of cell units to keep in the [dropout](https://www.cs.toronto.edu/~hinton/absps/JMLRdropout.pdf) operation.
> • `init_learning_rate`: the learning rate to start with.
> • `learning_rate_decay`: decay ratio in later training epochs.
> • `init_epoch`: number of epochs using the constant `init_learning_rate`.
> • `max_epoch`: total number of epochs in training
> • `input_size`: size of the sliding window / one training data point
> • `batch_size`: number of data points to use in one mini-batch.

LSTM 模型具有`num_layers`个堆叠的 LSTM 层，每个层包含`lstm_size`个 LSTM 单元。然后，将一个[dropout](https://www.cs.toronto.edu/~hinton/absps/JMLRdropout.pdf)掩码（其保留概率为`keep_prob`）应用于每个 LSTM 单元的输出。dropout 的目标是消除对某一维度的潜在强依赖性，从而防止过拟合。

> The LSTM model has `num_layers` stacked LSTM layer(s) and each layer contains `lstm_size` number of LSTM cells. Then a [dropout](https://www.cs.toronto.edu/~hinton/absps/JMLRdropout.pdf) mask with keep probability `keep_prob` is applied to the output of every LSTM cell. The goal of dropout is to remove the potential strong dependency on one dimension so as to prevent overfitting.

训练需要 `max_epoch` 个 epoch；一个 [epoch](http://www.fon.hum.uva.nl/praat/manual/epoch.html) 是指所有训练数据点的一次完整遍历。在一个 epoch 中，训练数据点被分成大小为 `batch_size` 的 mini-batch。我们将一个 mini-batch 发送到模型进行一次 BPTT 学习。学习率被设置为 `init_learning_rate` 在最初的 `init_epoch` 个 epoch 期间，然后衰减 $\times$ `learning_rate_decay` 在每个后续 epoch 期间。

> The training requires `max_epoch` epochs in total; an [epoch](http://www.fon.hum.uva.nl/praat/manual/epoch.html) is a single full pass of all the training data points. In one epoch, the training data points are split into mini-batches of size `batch_size`. We send one mini-batch to the model for one BPTT learning. The learning rate is set to `init_learning_rate` during the first `init_epoch` epochs and then decay by $\times$ `learning_rate_decay` during every succeeding epoch.

```python
# Configuration is wrapped in one object for easy tracking and passing.
class RNNConfig():
    input_size=1
    num_steps=30
    lstm_size=128
    num_layers=1
    keep_prob=0.8
    batch_size = 64
    init_learning_rate = 0.001
    learning_rate_decay = 0.99
    init_epoch = 5
    max_epoch = 50

config = RNNConfig()
```

#### 定义图

> Define Graph

一个[tf.Graph](https://www.tensorflow.org/api_docs/python/tf/Graph)不附带任何真实数据。它定义了如何处理数据以及如何运行计算的流程。稍后，这个图可以在一个[tf.session](https://www.tensorflow.org/api_docs/python/tf/Session)中被喂入数据，此时计算才会真正发生。

> A [tf.Graph](https://www.tensorflow.org/api_docs/python/tf/Graph) is not attached to any real data. It defines the flow of how to process the data and how to run the computation. Later, this graph can be fed with data within a [tf.session](https://www.tensorflow.org/api_docs/python/tf/Session) and at this moment the computation happens for real.

**— 让我们开始浏览一些代码 —**

> **— Let’s start going through some code —**

(1) 首先初始化一个新图。

> (1) Initialize a new graph first.

```python
import tensorflow as tf
tf.reset_default_graph()
lstm_graph = tf.Graph()
```

(2) 图的工作方式应在其作用域内定义。

> (2) How the graph works should be defined within its scope.

```python
with lstm_graph.as_default():
```

(3) 定义计算所需的数据。这里我们需要三个输入变量，它们都被定义为 [tf.placeholder](https://www.tensorflow.org/versions/master/api_docs/python/tf/placeholder)，因为在图构建阶段我们不知道它们是什么。

> (3) Define the data required for computation. Here we need three input variables, all defined as [tf.placeholder](https://www.tensorflow.org/versions/master/api_docs/python/tf/placeholder) because we don’t know what they are at the graph construction stage.

- `inputs`：训练数据 *X*，一个形状为（# 数据示例，`num_steps`，`input_size`）的张量；数据示例的数量未知，因此它是 `None`。在我们的例子中，它在训练会话中将是 `batch_size`。如果感到困惑，请查看 [输入格式示例](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#input_format_example)。
- `targets`：训练标签 *y*，一个形状为（# 数据示例，`input_size`）的张量。
- `learning_rate`：一个简单的浮点数。

> • `inputs`: the training data *X*, a tensor of shape (# data examples, `num_steps`, `input_size`); the number of data examples is unknown, so it is `None`. In our case, it would be `batch_size` in training session. Check the [input format example](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#input_format_example) if confused.
> • `targets`: the training label *y*, a tensor of shape (# data examples, `input_size`).
> • `learning_rate`: a simple float.

```python
    # Dimension = (
    #     number of data examples, 
    #     number of input in one computation step, 
    #     number of numbers in one input
    # )
    # We don't know the number of examples beforehand, so it is None.
    inputs = tf.placeholder(tf.float32, [None, config.num_steps, config.input_size])
    targets = tf.placeholder(tf.float32, [None, config.input_size])
    learning_rate = tf.placeholder(tf.float32, None)
```

(4) 此函数返回一个带或不带 dropout 操作的 [LSTMCell](https://www.tensorflow.org/versions/r1.0/api_docs/python/tf/contrib/rnn/LSTMCell)。

> (4) This function returns one [LSTMCell](https://www.tensorflow.org/versions/r1.0/api_docs/python/tf/contrib/rnn/LSTMCell) with or without dropout operation.

```python
    def _create_one_cell():
        return tf.contrib.rnn.LSTMCell(config.lstm_size, state_is_tuple=True)
        if config.keep_prob < 1.0:
            return tf.contrib.rnn.DropoutWrapper(lstm_cell, output_keep_prob=config.keep_prob)
```

(5) 如果需要，我们将这些单元堆叠成多层。`MultiRNNCell` 有助于顺序连接多个简单单元以组成一个单元。

> (5) Let’s stack the cells into multiple layers if needed. `MultiRNNCell` helps connect sequentially multiple simple cells to compose one cell.

```python
    cell = tf.contrib.rnn.MultiRNNCell(
        [_create_one_cell() for _ in range(config.num_layers)], 
        state_is_tuple=True
    ) if config.num_layers > 1 else _create_one_cell()
```

(6) [tf.nn.dynamic_rnn](https://www.tensorflow.org/api_docs/python/tf/nn/dynamic_rnn) 构建一个由 `cell` (RNNCell) 指定的循环神经网络。它返回一对（模型输出，状态），其中输出 `val` 默认大小为（`batch_size`，`num_steps`，`lstm_size`）。状态指的是 LSTM 单元的当前状态，此处不使用。

> (6) [tf.nn.dynamic_rnn](https://www.tensorflow.org/api_docs/python/tf/nn/dynamic_rnn) constructs a recurrent neural network specified by `cell` (RNNCell). It returns a pair of (model outpus, state), where the outputs `val` is of size (`batch_size`, `num_steps`, `lstm_size`) by default. The state refers to the current state of the LSTM cell, not consumed here.

```python
    val, _ = tf.nn.dynamic_rnn(cell, inputs, dtype=tf.float32)
```

(7) [tf.transpose](https://www.tensorflow.org/api_docs/python/tf/transpose) 将输出从维度（`batch_size`，`num_steps`，`lstm_size`）转换为（`num_steps`，`batch_size`，`lstm_size`）。然后选择最后一个输出。

> (7) [tf.transpose](https://www.tensorflow.org/api_docs/python/tf/transpose) converts the outputs from the dimension (`batch_size`, `num_steps`, `lstm_size`) to (`num_steps`, `batch_size`, `lstm_size`). Then the last output is picked.

```python
    # Before transpose, val.get_shape() = (batch_size, num_steps, lstm_size)
    # After transpose, val.get_shape() = (num_steps, batch_size, lstm_size)
    val = tf.transpose(val, [1, 0, 2])
    # last.get_shape() = (batch_size, lstm_size)
    last = tf.gather(val, int(val.get_shape()[0]) - 1, name="last_lstm_output")
```

(8) 定义隐藏层和输出层之间的权重和偏置。

> (8) Define weights and biases between the hidden and output layers.

```python
    weight = tf.Variable(tf.truncated_normal([config.lstm_size, config.input_size]))
    bias = tf.Variable(tf.constant(0.1, shape=[config.input_size]))
    prediction = tf.matmul(last, weight) + bias
```

(9) 我们使用均方误差作为损失度量，并使用 [RMSPropOptimizer 算法](http://www.cs.toronto.edu/~tijmen/csc321/slides/lecture_slides_lec6.pdf) 进行梯度下降优化。

> (9) We use mean square error as the loss metric and [the RMSPropOptimizer algorithm](http://www.cs.toronto.edu/~tijmen/csc321/slides/lecture_slides_lec6.pdf) for gradient descent optimization.

```python
    loss = tf.reduce_mean(tf.square(prediction - targets))
    optimizer = tf.train.RMSPropOptimizer(learning_rate)
    minimize = optimizer.minimize(loss)
```

#### 开始训练会话

> Start Training Session

(1) 要开始用真实数据训练图，我们首先需要启动一个 [tf.session](https://www.tensorflow.org/api_docs/python/tf/Session)。

> (1) To start training the graph with real data, we need to start a [tf.session](https://www.tensorflow.org/api_docs/python/tf/Session) first.

```python
with tf.Session(graph=lstm_graph) as sess:
```

(2) 按照定义初始化变量。

> (2) Initialize the variables as defined.

```python
    tf.global_variables_initializer().run()
```

(0) 训练周期的学习率应该事先预计算好。索引指的是周期索引。

> (0) The learning rates for training epochs should have been precomputed beforehand. The index refers to the epoch index.

```python
learning_rates_to_use = [
    config.init_learning_rate * (
        config.learning_rate_decay ** max(float(i + 1 - config.init_epoch), 0.0)
    ) for i in range(config.max_epoch)]
```

(3) 下面的每个循环完成一个周期的训练。

> (3) Each loop below completes one epoch training.

```python
    for epoch_step in range(config.max_epoch):
        current_lr = learning_rates_to_use[epoch_step]
        
        # Check https://github.com/lilianweng/stock-rnn/blob/master/data_wrapper.py
        # if you are curious to know what is StockDataSet and how generate_one_epoch() 
        # is implemented.
        for batch_X, batch_y in stock_dataset.generate_one_epoch(config.batch_size):
            train_data_feed = {
                inputs: batch_X, 
                targets: batch_y, 
                learning_rate: current_lr
            }
            train_loss, _ = sess.run([loss, minimize], train_data_feed)
```

(4) 最后不要忘记保存你训练好的模型。

> (4) Don’t forget to save your trained model at the end.

```python
    saver = tf.train.Saver()
    saver.save(sess, "your_awesome_model_path_and_name", global_step=max_epoch_step)
```

完整的代码可在此处[获取](https://github.com/lilianweng/stock-rnn/blob/master/build_graph.py)。

> The complete code is available [here](https://github.com/lilianweng/stock-rnn/blob/master/build_graph.py).

#### 使用 TensorBoard

> Use TensorBoard

没有可视化地构建图就像在黑暗中绘画，非常模糊且容易出错。[Tensorboard](https://github.com/tensorflow/tensorboard) 提供了图结构和学习过程的便捷可视化。请查看这个 [动手教程](https://youtu.be/eBbEDRsCmv4)，虽然只有 20 分钟，但它非常实用并展示了几个实时演示。

> Building the graph without visualization is like drawing in the dark, very obscure and error-prone. [Tensorboard](https://github.com/tensorflow/tensorboard) provides easy visualization of the graph structure and the learning process. Check out this [hand-on tutorial](https://youtu.be/eBbEDRsCmv4), only 20 min, but it is very practical and showcases several live demos.

**简要总结**

> **Brief Summary**

- 使用 `with [tf.name_scope](https://www.tensorflow.org/api_docs/python/tf/name_scope)("your_awesome_module_name"):` 将实现相似目标的元素封装在一起。
- 许多 `tf.*` 方法接受 `name=` 参数。分配一个自定义名称可以让你在阅读图时轻松得多。
- 像 [tf.summary.scalar](https://www.tensorflow.org/api_docs/python/tf/summary/scalar) 和 [tf.summary.histogram](https://www.tensorflow.org/api_docs/python/tf/summary/histogram) 这样的方法有助于在迭代过程中跟踪图中变量的值。
- 在训练会话中，使用 [tf.summary.FileWriter](https://www.tensorflow.org/api_docs/python/tf/summary/FileWriter) 定义一个日志文件。

> • Use `with [tf.name_scope](https://www.tensorflow.org/api_docs/python/tf/name_scope)("your_awesome_module_name"):` to wrap elements working on the similar goal together.
> • Many `tf.*` methods accepts `name=` argument. Assigning a customized name can make your life much easier when reading the graph.
> • Methods like [tf.summary.scalar](https://www.tensorflow.org/api_docs/python/tf/summary/scalar) and [tf.summary.histogram](https://www.tensorflow.org/api_docs/python/tf/summary/histogram) help track the values of variables in the graph during iterations.
> • In the training session, define a log file using [tf.summary.FileWriter](https://www.tensorflow.org/api_docs/python/tf/summary/FileWriter).

```python
with tf.Session(graph=lstm_graph) as sess:
    merged_summary = tf.summary.merge_all()
    writer = tf.summary.FileWriter("location_for_keeping_your_log_files", sess.graph)
    writer.add_graph(sess.graph)
```

稍后，将训练进度和摘要结果写入文件。

> Later, write the training progress and summary results into the file.

```python
_summary = sess.run([merged_summary], test_data_feed)
writer.add_summary(_summary, global_step=epoch_step)  # epoch_step in range(config.max_epoch)
```

![Fig. 4a The RNN graph built by the example code. The "train" module has been "removed from the main graph", as it is not a real part of the model during the prediction time.](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/tensorboard1.png)

![Fig. 4b Click the "output_layer" module to expand it and check the structure in details.](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/tensorboard2.png)

完整的可运行代码可在 [github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn) 获取。

> The full working code is available in [github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn).

### 结果

> Results

我在实验中使用了以下配置。

> I used the following configuration in the experiment.

```python
num_layers=1
keep_prob=0.8
batch_size = 64
init_learning_rate = 0.001
learning_rate_decay = 0.99
init_epoch = 5
max_epoch = 100
num_steps=30
```

(感谢 Yury 发现我在价格归一化中存在的一个错误。我最终使用了同一时间窗口的最后一个价格，而不是前一个时间窗口的最后一个价格。以下图表已更正。)

> (Thanks to Yury for cathcing a bug that I had in the price normalization. Instead of using the last price of the previous time window, I ended up with using the last price in the same window. The following plots have been corrected.)

总的来说，预测股票价格并非易事。尤其是在归一化之后，价格趋势看起来非常嘈杂。

> Overall predicting the stock prices is not an easy task. Especially after normalization, the price trends look very noisy.

![Fig. 5a Predictoin results for the last 200 days in test data. Model is trained with input_size=1 and lstm_size=32.](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/rnn_input1_lstm32.png)

![Fig. 5b Predictoin results for the last 200 days in test data. Model is trained with input_size=1 and lstm_size=128.](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/rnn_input1_lstm128.png)

![Fig. 5c Predictoin results for the last 200 days in test data. Model is trained with input_size=5, lstm_size=128 and max_epoch=75 (instead of 50).](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/rnn_input5_lstm128.png)

本教程中的示例代码可在 [github.com/lilianweng/stock-rnn:scripts](https://github.com/lilianweng/stock-rnn/tree/master/scripts) 获取。

> The example code in this tutorial is available in [github.com/lilianweng/stock-rnn:scripts](https://github.com/lilianweng/stock-rnn/tree/master/scripts).

(2017 年 9 月 14 日更新)模型代码已更新并封装到一个类中：[LstmRNN](https://github.com/lilianweng/stock-rnn/blob/master/model_rnn.py)。模型训练可以通过 [main.py](https://github.com/lilianweng/stock-rnn/blob/master/main.py) 触发，例如：

> (Updated on Sep 14, 2017)
> The model code has been updated to be wrapped into a class: [LstmRNN](https://github.com/lilianweng/stock-rnn/blob/master/model_rnn.py). The model training can be triggered by [main.py](https://github.com/lilianweng/stock-rnn/blob/master/main.py), such as:

```
python main.py --stock_symbol=SP500 --train --input_size=1 --lstm_size=128
```

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Recurrent Neural Network (RNN) | 循环神经网络 | 一种人工神经网络，其隐藏层中存在自循环，擅长处理序列数据。 |
| Long Short-Term Memory (LSTM) | 长短期记忆 | 一种特殊的RNN单元，旨在解决传统RNN的长期依赖问题，更好地记忆长期上下文。 |
| TensorFlow | TensorFlow | 一个开源机器学习框架，用于构建和训练各种机器学习模型。 |
| Stock Price Prediction | 股票价格预测 | 利用历史数据和机器学习模型预测未来股票价格的趋势或具体数值。 |
| Sliding Window | 滑动窗口 | 在时间序列数据处理中，一种固定大小的连续数据段，用于提取特征或作为模型输入。 |
| Backpropagation Through Time (BPTT) | 通过时间反向传播 | 循环神经网络中用于计算梯度和更新模型参数的反向传播算法。 |
| Normalization | 归一化 | 将数据按比例缩放到特定范围，以消除量纲影响并改善模型训练效果。 |
| Dropout | Dropout | 一种正则化技术，在训练过程中随机“丢弃”神经网络中的部分神经元，以防止过拟合。 |
| Epoch | 训练周期 | 机器学习训练中，所有训练数据完成一次前向传播和反向传播的完整过程。 |
| Learning Rate | 学习率 | 优化算法中控制模型参数更新步长大小的超参数。 |
| TensorBoard | TensorBoard | TensorFlow提供的可视化工具，用于展示图结构、跟踪训练指标和调试模型。 |
| tf.placeholder | TensorFlow占位符 | TensorFlow图中用于在运行时输入数据的张量，其值在会话执行时提供。 |
| Mean Squared Error (MSE) | 均方误差 | 一种常用的回归损失函数，计算预测值与真实值之间差的平方的平均值。 |
| RMSPropOptimizer | RMSProp优化器 | 一种自适应学习率优化算法，通过调整每个参数的学习率来加速训练。 |
