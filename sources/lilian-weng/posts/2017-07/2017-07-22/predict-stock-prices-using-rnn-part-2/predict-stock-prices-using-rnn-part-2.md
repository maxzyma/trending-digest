# 使用 RNN 预测股票价格：第 2 部分

> Predict Stock Prices Using RNN: Part 2

> 来源：Lil'Log / Lilian Weng，2017-07-22
> 原文链接：https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/
> 分类：深度学习 / 股票预测

## 核心要点

- 本教程是股票价格预测系列的第二部分，旨在赋予循环神经网络处理多只股票的能力。
- 为了区分不同股票的价格序列模式，模型将股票代码嵌入向量作为输入的一部分。
- 文章介绍了从Google财经等免费数据源获取历史股票价格数据的方法。
- 模型构建中，股票代码采用嵌入（embedding）而非独热编码，以实现更紧凑的表示并允许相似股票相互辅助预测。
- 在循环神经网络中，价格向量与股票嵌入向量连接后输入LSTM单元，以使模型能够区分不同股票的价格。
- 图定义部分详细说明了如何设置嵌入矩阵、平铺股票标签以及将价格与嵌入向量结合的代码实现。
- 训练会话前，股票代码需通过标签编码转换为唯一的整数，并采用90%训练、10%测试的分割比例。
- Tensorboard支持嵌入可视化，允许用户根据行业部门等元数据对股票嵌入进行着色和聚类分析。
- t-SNE技术被用于可视化嵌入空间中的聚类，例如GOOG和GOOGL在学习到的嵌入中显示出高度相似性。
- 模型存在预测值大幅减小并趋于平坦以及损失函数偶尔爆炸的问题，可能需要改进损失函数来解决。

## 正文

在第 2 部分教程中，我将继续股票价格预测的话题，并赋予我在[第 1 部分](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/)中构建的循环神经网络处理多只股票的能力。为了区分与不同价格序列相关的模式，我使用股票代码嵌入向量作为输入的一部分。

> In the Part 2 tutorial, I would like to continue the topic on stock price prediction and to endow the recurrent neural network that I have built in [Part 1](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/) with the capability of responding to multiple stocks. In order to distinguish the patterns associated with different price sequences, I use the stock symbol embedding vectors as part of the input.

### 数据集

> Dataset

在搜索过程中，我找到了一个[库](https://github.com/lukaszbanasiak/yahoo-finance)用于查询 Yahoo! 财经 API。如果雅虎没有关闭历史数据获取 API，它会非常有用。不过，你可能会发现它在查询其他信息时很有用。在这里，我从[几个免费数据源](https://www.quantshare.com/sa-43-10-ways-to-download-historical-stock-quotes-data-for-free)中选择了 Google 财经链接来下载历史股票价格。

> During the search, I found [this library](https://github.com/lukaszbanasiak/yahoo-finance) for querying Yahoo! Finance API. It would be very useful if Yahoo hasn’t shut down the historical data fetch API. You may find it useful for querying other information though. Here I pick the Google Finance link, among [a couple of free data sources](https://www.quantshare.com/sa-43-10-ways-to-download-historical-stock-quotes-data-for-free) for downloading historical stock prices.

数据获取代码可以写得非常简单，如下所示：

> The data fetch code can be written as simple as:

```python
import urllib2
from datetime import datetime
BASE_URL = "https://www.google.com/finance/historical?"
           "output=csv&q={0}&startdate=Jan+1%2C+1980&enddate={1}"
symbol_url = BASE_URL.format(
    urllib2.quote('GOOG'), # Replace with any stock you are interested.
    urllib2.quote(datetime.now().strftime("%b+%d,+%Y"), '+')
)
```

获取内容时，请记住添加 try-catch 包装器，以防链接失败或提供的股票代码无效。

> When fetching the content, remember to add try-catch wrapper in case the link fails or the provided stock symbol is not valid.

```python
try:
    f = urllib2.urlopen(symbol_url)
    with open("GOOG.csv", 'w') as fin:
        print >> fin, f.read()
except urllib2.HTTPError:
    print "Fetching Failed: {}".format(symbol_url)
```

完整可用的数据获取器代码可在[此处](https://github.com/lilianweng/stock-rnn/blob/master/data_fetcher.py)获取。

> The full working data fetcher code is available [here](https://github.com/lilianweng/stock-rnn/blob/master/data_fetcher.py).

### 模型构建

> Model Construction

模型有望学习不同股票随时间变化的股价序列。由于底层模式不同，我希望明确告知模型它正在处理哪只股票。[嵌入](https://en.wikipedia.org/wiki/Embedding)比独热编码更受青睐，原因如下：

> The model is expected to learn the price sequences of different stocks in time. Due to the different underlying patterns, I would like to tell the model which stock it is dealing with explicitly. [Embedding](https://en.wikipedia.org/wiki/Embedding) is more favored than one-hot encoding, because:

1\. 鉴于训练集包含 $N$ 只股票，独热编码将引入 $N$（或 $N-1$）个额外的稀疏特征维度。一旦每个股票符号被映射到一个长度为 $k$ 的小得多的嵌入向量上，$k \ll N$，我们最终会得到一个更紧凑的表示和一个更小的数据集来处理。

2\. 由于嵌入向量是需要学习的变量。相似的股票可以与相似的嵌入相关联，并有助于相互预测，例如“GOOG”和“GOOGL”，这将在后面看到。

英文原文：

1\. Given that the train set includes $N$ stocks, the one-hot encoding would introduce $N$ (or $N-1$) additional sparse feature dimensions. Once each stock symbol is mapped onto a much smaller embedding vector of length $k$, $k \ll N$, we end up with a much more compressed representation and smaller dataset to take care of.

2\. Since embedding vectors are variables to learn. Similar stocks could be associated with similar embeddings and help the prediction of each others, such as “GOOG” and “GOOGL” which you will see in later.

在循环神经网络中，在某个时间步$t$，输入向量包含`input_size`（标记为$w$）的第$i$只股票的每日价格值，$(p_{i, tw}, p_{i, tw+1}, \dots, p_{i, (t+1)w-1})$。股票代码唯一映射到一个长度为`embedding_size`（标记为$k$）的向量，$(e_{i,0}, e_{i,1}, \dots, e_{i,k})$。如图1所示，价格向量与嵌入向量连接，然后输入到LSTM单元。

> In the recurrent neural network, at one time step $t$, the input vector contains `input_size` (labelled as $w$) daily price values of $i$ -th stock, $(p_{i, tw}, p_{i, tw+1}, \dots, p_{i, (t+1)w-1})$. The stock symbol is uniquely mapped to a vector of length `embedding_size` (labelled as $k$), $(e_{i,0}, e_{i,1}, \dots, e_{i,k})$. As illustrated in Fig. 1., the price vector is concatenated with the embedding vector and then fed into the LSTM cell.

另一种替代方法是将嵌入向量与 LSTM 单元的最后状态连接起来，并在输出层学习新的权重 $W$ 和偏置 $b$。然而，通过这种方式，LSTM 单元无法区分不同股票的价格，其能力将受到很大限制。因此，我决定采用前一种方法。

> Another alternative is to concatenate the embedding vectors with the last state of the LSTM cell and learn new weights $W$ and bias $b$ in the output layer. However, in this way, the LSTM cell cannot tell apart prices of one stock from another and its power would be largely restrained. Thus I decided to go with the former approach.

![The architecture of the stock price prediction RNN model with stock symbol embeddings.](https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/rnn_with_embedding.png)

两个新的配置设置被添加到 `RNNConfig` 中：

> Two new configuration settings are added into `RNNConfig`:

- `embedding_size` 控制每个嵌入向量的大小；
- `stock_count` 指代数据集中唯一股票的数量。

> • `embedding_size` controls the size of each embedding vector;
> • `stock_count` refers to the number of unique stocks in the dataset.

它们共同定义了嵌入矩阵的大小，为此模型必须学习`embedding_size`$\times$`stock_count`额外的变量，与[Part 1](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/)中的模型相比。

> Together they define the size of the embedding matrix, for which the model has to learn `embedding_size` $\times$ `stock_count` additional variables compared to the model in [Part 1](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/).

```python
class RNNConfig():
   # ... old ones
   embedding_size = 3
   stock_count = 50
```

#### 定义图

> Define the Graph

**— 让我们开始浏览一些代码 —**

> **— Let’s start going through some code —**

(1) 正如教程[Part 1: Define the Graph](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#define-graph)中所示，让我们定义一个`tf.Graph()`名为`lstm_graph`以及一组用于保存输入数据的张量，`inputs`、`targets`和`learning_rate`，以相同的方式。还需要定义一个占位符，用于存储与输入价格相关的股票代码列表。股票代码已预先通过[label encoding](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.LabelEncoder.html)进行映射，转换为唯一的整数。

> (1) As demonstrated in tutorial [Part 1: Define the Graph](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#define-graph), let us define a `tf.Graph()` named `lstm_graph` and a set of tensors to hold input data, `inputs`, `targets`, and `learning_rate` in the same way. One more placeholder to define is a list of stock symbols associated with the input prices. Stock symbols have been mapped to unique integers beforehand with [label encoding](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.LabelEncoder.html).

```python
# Mapped to an integer. one label refers to one stock symbol.
stock_labels = tf.placeholder(tf.int32, [None, 1])
```

(2) 接下来，我们需要设置一个嵌入矩阵作为查找表，其中包含所有股票的嵌入向量。该矩阵用区间 [-1, 1] 中的随机数初始化，并在训练期间进行更新。

> (2) Then we need to set up an embedding matrix to play as a lookup table, containing the embedding vectors of all the stocks. The matrix is initialized with random numbers in the interval [-1, 1] and gets updated during training.

```python
# NOTE: config = RNNConfig() and it defines hyperparameters.
# Convert the integer labels to numeric embedding vectors.
embedding_matrix = tf.Variable(
    tf.random_uniform([config.stock_count, config.embedding_size], -1.0, 1.0)
)
```

(3) 将股票标签重复`num_steps`次，以匹配 RNN 的展开版本和`inputs`张量在训练期间的形状。转换操作[tf.tile](https://www.tensorflow.org/api_docs/python/tf/tile)接收一个基础张量，并通过多次复制其某些维度来创建一个新张量；具体来说，输入张量的第$i$个维度被乘以`multiples[i]`次。例如，如果`stock_labels`是`[[0], [0], [2], [1]]`
将其平铺`[1, 5]`次会生成`[[0 0 0 0 0], [0 0 0 0 0], [2 2 2 2 2], [1 1 1 1 1]]`。

> (3) Repeat the stock labels `num_steps` times to match the unfolded version of RNN and the shape of `inputs` tensor during training.
> The transformation operation [tf.tile](https://www.tensorflow.org/api_docs/python/tf/tile) receives a base tensor and creates a new tensor by replicating its certain dimensions multiples times; precisely the $i$ -th dimension of the input tensor gets multiplied by `multiples[i]` times. For example, if the `stock_labels` is `[[0], [0], [2], [1]]`
> tiling it by `[1, 5]` produces `[[0 0 0 0 0], [0 0 0 0 0], [2 2 2 2 2], [1 1 1 1 1]]`.

```python
stacked_stock_labels = tf.tile(stock_labels, multiples=[1, config.num_steps])
```

(4) 然后，我们根据查找表`embedding_matrix`将符号映射到嵌入向量。

> (4) Then we map the symbols to embedding vectors according to the lookup table `embedding_matrix`.

```python
# stock_label_embeds.get_shape() = (?, num_steps, embedding_size).
stock_label_embeds = tf.nn.embedding_lookup(embedding_matrix, stacked_stock_labels)
```

(5) 最后，将价格值与嵌入向量结合起来。操作[tf.concat](https://www.tensorflow.org/api_docs/python/tf/concat)沿着维度`axis`连接一系列张量。在我们的例子中，我们希望保持批次大小和步数不变，但只将长度为`input_size`的输入向量扩展以包含嵌入特征。

> (5) Finally, combine the price values with the embedding vectors. The operation [tf.concat](https://www.tensorflow.org/api_docs/python/tf/concat) concatenates a list of tensors along the dimension `axis`. In our case, we want to keep the batch size and the number of steps unchanged, but only extend the input vector of length `input_size` to include embedding features.

```python
# inputs.get_shape() = (?, num_steps, input_size)
# stock_label_embeds.get_shape() = (?, num_steps, embedding_size)
# inputs_with_embeds.get_shape() = (?, num_steps, input_size + embedding_size)
inputs_with_embeds = tf.concat([inputs, stock_label_embeds], axis=2)
```

其余代码运行动态 RNN，提取 LSTM 单元的最后一个状态，并处理输出层中的权重和偏置。详情请参阅[Part 1: Define the Graph](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#define-graph)。

> The rest of code runs the dynamic RNN, extracts the last state of the LSTM cell, and handles weights and bias in the output layer. See [Part 1: Define the Graph](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#define-graph) for the details.

#### 训练会话

> Training Session

如果您还没有阅读[第一部分：开始训练会话](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#start-training-session)，请阅读它以了解如何在 Tensorflow 中运行训练会话。

> Please read [Part 1: Start Training Session](https://lilianweng.github.io/posts/2017-07-08-stock-rnn-part-1/#start-training-session) if you haven’t for how to run a training session in Tensorflow.

在将数据输入图之前，股票代码应使用[标签编码](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.LabelEncoder.html)转换为唯一的整数。

> Before feeding the data into the graph, the stock symbols should be transformed to unique integers with [label encoding](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.LabelEncoder.html).

```python
from sklearn.preprocessing import LabelEncoder
label_encoder = LabelEncoder()
label_encoder.fit(list_of_symbols)
```

训练/测试分割比例保持不变，90% 用于训练，10% 用于测试，适用于每只个股。

> The train/test split ratio remains same, 90% for training and 10% for testing, for every individual stock.

#### 可视化图

> Visualize the Graph

在代码中定义图之后，让我们检查 Tensorboard 中的可视化，以确保组件构建正确。本质上，它与我们架构图中的插图非常相似

> After the graph is defined in code, let us check the visualization in Tensorboard to make sure that components are constructed correctly. Essentially it looks very much like our architecture illustration in 

![Tensorboard visualization of the graph defined above. Two modules, “train” and “save”, have been removed from the main graph.](https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/rnn_with_embedding_tensorboard.png)

除了展示图结构或跟踪变量随时间变化之外，Tensorboard 还支持[嵌入可视化](https://www.tensorflow.org/get_started/embedding_viz)。为了将嵌入值传递给 Tensorboard，我们需要在训练日志中添加适当的跟踪。

> Other than presenting the graph structure or tracking the variables in time, Tensorboard also supports [embeddings visualization](https://www.tensorflow.org/get_started/embedding_viz). In order to communicate the embedding values to Tensorboard, we need to add proper tracking in the training logs.

(0) 在我的嵌入可视化中，我希望根据行业部门为每只股票着色。这些元数据应存储在一个 CSV 文件中。该文件有两列，分别是股票代码和行业部门。CSV 文件是否有标题并不重要，但所列股票的顺序必须与`label_encoder.classes_`一致。

> (0) In my embedding visualization, I want to color each stock with its industry sector. This metadata should stored in a csv file. The file has two columns, the stock symbol and the industry sector. It does not matter whether the csv file has header, but the order of the listed stocks must be consistent with `label_encoder.classes_`.

```python
import csv
embedding_metadata_path = os.path.join(your_log_file_folder, 'metadata.csv')
with open(embedding_metadata_path, 'w') as fout:
    csv_writer = csv.writer(fout)
    # write the content into the csv file.
    # for example, csv_writer.writerows(["GOOG", "information_technology"])
```

(1) 首先在训练`tf.Session`中设置摘要写入器。

> (1) Set up the summary writer first within the training `tf.Session`.

```python
from tensorflow.contrib.tensorboard.plugins import projector
with tf.Session(graph=lstm_graph) as sess:
    summary_writer = tf.summary.FileWriter(your_log_file_folder)
    summary_writer.add_graph(sess.graph)
```

(2) 将在我们的图`embedding_matrix`中定义的张量`lstm_graph`添加到投影仪配置变量中，并附加元数据 CSV 文件。

> (2) Add the tensor `embedding_matrix` defined in our graph `lstm_graph` into the projector config variable and attach the metadata csv file.

```python
    projector_config = projector.ProjectorConfig()
    # You can add multiple embeddings. Here we add only one.
    added_embedding = projector_config.embeddings.add()
    added_embedding.tensor_name = embedding_matrix.name
    # Link this tensor to its metadata file.
    added_embedding.metadata_path = embedding_metadata_path
```

(3) 这一行创建了一个文件`projector_config.pbtxt`在文件夹`your_log_file_folder`中。TensorBoard 将在启动时读取此文件。

> (3) This line creates a file `projector_config.pbtxt` in the folder `your_log_file_folder`. TensorBoard will read this file during startup.

```python
    projector.visualize_embeddings(summary_writer, projector_config)
```

### 结果

> Results

该模型使用标准普尔500指数中市值最大的50只股票进行训练。

> The model is trained with top 50 stocks with largest market values in the S&P 500 index.

（在[github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn)中运行以下命令）

> (Run the following command within [github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn))

```bash
python main.py --stock_count=50 --embed_size=3 --input_size=3 --max_epoch=50 --train
```

并使用以下配置：

> And the following configuration is used:

```
stock_count = 100
input_size = 3
embed_size = 3
num_steps = 30
lstm_size = 256
num_layers = 1
max_epoch = 50
keep_prob = 0.8
batch_size = 64
init_learning_rate = 0.05
learning_rate_decay = 0.99
init_epoch = 5
```

#### 价格预测

> Price Prediction

作为预测质量的简要概述，图3绘制了“KO”、“AAPL”、“GOOG”和“NFLX”测试数据的预测结果。真实值和预测值之间的总体趋势是匹配的。考虑到预测任务的设计方式，模型依赖所有历史数据点来预测接下来的5 (`input_size`) 天。在`input_size`较小的情况下，模型无需担心长期增长曲线。一旦我们增加`input_size`，预测将变得更加困难。

> As a brief overview of the prediction quality, Fig. 3 plots the predictions for test data of “KO”, “AAPL”, “GOOG” and “NFLX”. The overall trends matched up between the true values and the predictions. Considering how the prediction task is designed, the model relies on all the historical data points to predict only next 5 (`input_size`) days. With a small `input_size`, the model does not need to worry about the long-term growth curve. Once we increase `input_size`, the prediction would be much harder.

![True and predicted stock prices of AAPL, MSFT and GOOG in the test set. The prices are normalized across consecutive prediction sliding windows (See Part 1: Normalization . The y-axis values get multiplied by 5 for a better comparison between true and predicted trends.](https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/rnn_embedding_AAPL.png)

![True and predicted stock prices of AAPL, MSFT and GOOG in the test set. The prices are normalized across consecutive prediction sliding windows (See Part 1: Normalization . The y-axis values get multiplied by 5 for a better comparison between true and predicted trends.](https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/rnn_embedding_MSFT.png)

![True and predicted stock prices of AAPL, MSFT and GOOG in the test set. The prices are normalized across consecutive prediction sliding windows (See Part 1: Normalization . The y-axis values get multiplied by 5 for a better comparison between true and predicted trends.](https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/rnn_embedding_GOOG.png)

#### 嵌入可视化

> Embedding Visualization

一种常见的可视化嵌入空间中聚类的技术是[t-SNE](https://en.wikipedia.org/wiki/T-distributed_stochastic_neighbor_embedding)（[Maaten and Hinton, 2008](http://www.jmlr.org/papers/volume9/vandermaaten08a/vandermaaten08a.pdf)），它在Tensorboard中得到了很好的支持。t-SNE是“t-分布式随机邻域嵌入”的缩写，是随机邻域嵌入（[Hinton and Roweis, 2002](http://www.cs.toronto.edu/~fritz/absps/sne.pdf)）的一种变体，但其成本函数经过修改，更易于优化。

> One common technique to visualize the clusters in embedding space is [t-SNE](https://en.wikipedia.org/wiki/T-distributed_stochastic_neighbor_embedding) ([Maaten and Hinton, 2008](http://www.jmlr.org/papers/volume9/vandermaaten08a/vandermaaten08a.pdf)), which is well supported in Tensorboard. t-SNE, short for “t-Distributed Stochastic Neighbor Embedding, is a variation of Stochastic Neighbor Embedding ([Hinton and Roweis, 2002](http://www.cs.toronto.edu/~fritz/absps/sne.pdf)), but with a modified cost function that is easier to optimize.

1. 与SNE类似，t-SNE首先将数据点之间的高维欧几里得距离转换为表示相似性的条件概率。
2. t-SNE在低维空间中的数据点上定义了一个相似的概率分布，并且它最小化了两个分布之间关于图中点位置的[Kullback–Leibler散度](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)。

> • Similar to SNE, t-SNE first converts the high-dimensional Euclidean distances between data points into conditional probabilities that represent similarities.
> • t-SNE defines a similar probability distribution over the data points in the low-dimensional space, and it minimizes the [Kullback–Leibler divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence) between the two distributions with respect to the locations of the points on the map.

请查看[这篇文章](http://distill.pub/2016/misread-tsne/)，了解如何在t-SNE可视化中调整参数，即困惑度（Perplexity）和学习率（epsilon）。

> Check [this post](http://distill.pub/2016/misread-tsne/) for how to adjust the parameters, Perplexity and learning rate (epsilon), in t-SNE visualization.

![Visualization of the stock embeddings using t-SNE. Each label is colored based on the stock industry sector. We have 5 clusters. Interstingly, GOOG, GOOGL and FB belong to the same cluster, while AMZN and AAPL stay in another.](https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/embedding_clusters.png)

在嵌入空间中，我们可以通过检查两只股票的嵌入向量之间的相似性来衡量它们的相似性。例如，在学习到的嵌入中，GOOG与GOOGL的相似度最高（参见图5）。

> In the embedding space, we can measure the similarity between two stocks by examining the similarity between their embedding vectors. For example, GOOG is mostly similar to GOOGL in the learned embeddings (See Fig. 5).

!["GOOG" is clicked in the embedding visualization graph and top 20 similar neighbors are highlighted with colors from dark to light as the similarity decreases.](https://lilianweng.github.io/posts/2017-07-22-stock-rnn-part-2/embedding_clusters_2.png)

#### 已知问题

> Known Problems

- 随着训练的进行，预测值会大幅减小并趋于平坦。这就是为什么我将绝对值乘以一个常数，以使图3中的趋势更明显，因为我更关心预测方向是否正确。然而，预测值减小的问题一定有其原因。我们可能可以采用另一种形式的损失函数，而不是简单的MSE作为损失，以便在方向预测错误时施加更大的惩罚。
- 损失函数在开始时下降很快，但偶尔会出现值爆炸（突然出现一个峰值然后立即回落）。我怀疑这也与损失函数的形式有关。一个更新、更智能的损失函数或许能够解决这个问题。

> • The prediction values get diminished and flatten quite a lot as the training goes. That’s why I multiplied the absolute values by a constant to make the trend is more visible in Fig. 3., as I’m more curious about whether the prediction on the up-or-down direction right. However, there must be a reason for the diminishing prediction value problem. Potentially rather than using simple MSE as the loss, we can adopt another form of loss function to penalize more when the direction is predicted wrong.
> • The loss function decreases fast at the beginning, but it suffers from occasional value explosion (a sudden peak happens and then goes back immediately). I suspect it is related to the form of loss function too. A updated and smarter loss function might be able to resolve the issue.

本教程的完整代码可在[github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn)中找到。

> The full code in this tutorial is available in [github.com/lilianweng/stock-rnn](https://github.com/lilianweng/stock-rnn).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| RNN | 循环神经网络 | 一种适用于处理序列数据的神经网络模型。 |
| Embedding | 嵌入 | 将离散变量映射到连续向量空间的技术，常用于表示词语或实体。 |
| One-hot encoding | 独热编码 | 将分类变量转换为二进制向量表示的方法，每个类别对应一个维度。 |
| LSTM | 长短期记忆网络 | 一种特殊的循环神经网络，能够学习长期依赖关系。 |
| TensorFlow | TensorFlow | 一个开源的机器学习框架，用于构建和训练各种神经网络模型。 |
| tf.Graph | tf.Graph | TensorFlow中用于定义计算图的类。 |
| tf.tile | tf.tile | TensorFlow操作，通过复制现有张量的维度来创建新张量。 |
| tf.concat | tf.concat | TensorFlow操作，沿着指定维度连接一系列张量。 |
| Label encoding | 标签编码 | 将分类标签转换为数字形式的编码方法。 |
| Tensorboard | Tensorboard | TensorFlow的可视化工具，用于理解、调试和优化机器学习模型。 |
| t-SNE | t-分布式随机邻域嵌入 | 一种非线性降维技术，常用于高维数据的可视化。 |
| Kullback–Leibler divergence | Kullback–Leibler散度 | 衡量两个概率分布之间差异的非对称度量。 |
| Perplexity | 困惑度 | 在t-SNE中，表示每个点有效邻居的数量，影响局部和全局结构的平衡。 |
| Learning rate | 学习率 | 机器学习算法中控制模型权重更新步长的超参数。 |
| MSE | 均方误差 | 一种常用的回归损失函数，衡量预测值与真实值之间差异的平方平均值。 |
