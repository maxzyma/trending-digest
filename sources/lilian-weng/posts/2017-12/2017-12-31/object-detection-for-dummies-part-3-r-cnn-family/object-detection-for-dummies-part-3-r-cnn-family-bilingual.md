# 傻瓜式目标检测系列之三：R-CNN 家族

> Object Detection for Dummies Part 3: R-CNN Family

> 来源：Lil'Log / Lilian Weng，2017-12-31
> 原文链接：https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/
> 分类：计算机视觉 / 目标检测

## 核心要点

- R-CNN通过选择性搜索生成区域候选，然后使用CNN提取特征并由SVM进行分类，并引入边界框回归以校正定位。
- R-CNN模型存在速度瓶颈，主要由于为每个区域独立提取CNN特征以及三个独立模型的计算开销。
- Fast R-CNN通过将三个独立模型统一到联合训练框架中，并引入RoI池化层共享整个图像的CNN特征，显著提升了训练和测试速度。
- Fast R-CNN的瓶颈在于区域提议仍由外部算法（如选择性搜索）生成，耗时较长。
- Faster R-CNN通过引入区域提议网络（RPN）将区域提议算法集成到CNN模型中，实现了端到端的训练，进一步加速了目标检测。
- Faster R-CNN通过共享卷积特征层，使得RPN和Fast R-CNN能够协同工作，形成一个统一的检测框架。
- Mask R-CNN在Faster R-CNN的基础上增加了第三个分支，用于像素级实例分割，并引入RoIAlign层以解决RoI池化中的量化误差，实现更精确的对齐。
- R-CNN家族模型在发展过程中，通过计算共享、模型集成和精细化对齐等技术，逐步提高了目标检测的速度和精度，并扩展到实例分割任务。
- 非极大值抑制（NMS）和难例挖掘是R-CNN及其他检测模型中常用的技巧，分别用于消除重复检测和改进分类器性能。

## 正文

[2018-12-20 更新：此处移除 YOLO。第四部分将涵盖多种快速目标检测算法，包括 YOLO。]
  

[2018-12-27 更新：为 R-CNN 添加了[边界框回归](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression)和[技巧](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#common-tricks)部分。]

> [Updated on 2018-12-20: Remove YOLO here. Part 4 will cover multiple fast object detection algorithms, including YOLO.]
>
>
> [Updated on 2018-12-27: Add [bbox regression](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression) and [tricks](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#common-tricks) sections for R-CNN.]

在“傻瓜式目标检测”系列中，我们从[第一部分](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)中图像处理的基本概念开始，例如梯度向量和 HOG。然后，在[第二部分](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)中，我们介绍了用于分类的经典卷积神经网络架构设计以及用于目标识别的先驱模型 Overfeat 和 DPM。在本系列的第三篇文章中，我们将回顾 R-CNN（“基于区域的 CNN”）家族中的一系列模型。

> In the series of “Object Detection for Dummies”, we started with basic concepts in image processing, such as gradient vectors and HOG, in [Part 1](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/). Then we introduced classic convolutional neural network architecture designs for classification and pioneer models for object recognition, Overfeat and DPM, in [Part 2](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/). In the third post of this series, we are about to review a set of models in the R-CNN (“Region-based CNN”) family.

本系列所有文章的链接：
[[第一部分](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)]
[[第二部分](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)]
[[第三部分](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)]
[[第四部分](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)]。

> Links to all the posts in the series:
> [[Part 1](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)]
> [[Part 2](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)]
> [[Part 3](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)]
> [[Part 4](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)].

本文涵盖的论文列表如下 ;)

> Here is a list of papers covered in this post ;)

| 模型 | 目标 | 资源 |
| --- | --- | --- |
| R-CNN | 目标识别 | [ 论文 ][ 代码 ] |
| Fast R-CNN | 目标识别 | [ 论文 ][ 代码 ] |
| Faster R-CNN | 目标识别 | [ 论文 ][ 代码 ] |
| Mask R-CNN | 图像分割 | [ 论文 ][ 代码 ] |

> 英文原表 / English original

| Model | Goal | Resources |
| --- | --- | --- |
| R-CNN | Object recognition | [ paper ][ code ] |
| Fast R-CNN | Object recognition | [ paper ][ code ] |
| Faster R-CNN | Object recognition | [ paper ][ code ] |
| Mask R-CNN | Image segmentation | [ paper ][ code ] |

### R-CNN

> R-CNN

R-CNN（[Girshick 等人，2014](https://arxiv.org/abs/1311.2524)）是“基于区域的卷积神经网络”（Region-based Convolutional Neural Networks）的缩写。其主要思想由两个步骤组成。首先，使用[选择性搜索](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/#selective-search)，它识别出数量可控的边界框目标区域候选（“感兴趣区域”或“RoI”）。然后，它独立地从每个区域提取 CNN 特征进行分类。

> R-CNN ([Girshick et al., 2014](https://arxiv.org/abs/1311.2524)) is short for “Region-based Convolutional Neural Networks”. The main idea is composed of two steps. First, using [selective search](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/#selective-search), it identifies a manageable number of bounding-box object region candidates (“region of interest” or “RoI”). And then it extracts CNN features from each region independently for classification.

![The architecture of R-CNN. (Image source: Girshick et al., 2014 )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/RCNN.png)

#### 模型工作流程

> Model Workflow

R-CNN 的工作原理可总结如下：

> How R-CNN works can be summarized as follows:

1. **预训练**一个 CNN 网络用于图像分类任务；例如，在[ImageNet](http://image-net.org/index)数据集上训练的 VGG 或 ResNet。分类任务涉及 N 个类别。
  


> • **Pre-train** a CNN network on image classification tasks; for example, VGG or ResNet trained on [ImageNet](http://image-net.org/index) dataset. The classification task involves N classes.
>

> 注意：你可以找到一个预训练的[AlexNet](https://github.com/BVLC/caffe/tree/master/models/bvlc_alexnet)在Caffe模型[Zoo](https://github.com/caffe2/caffe2/wiki/Model-Zoo)。我不认为你能够[找到它](https://github.com/tensorflow/models/issues/1394)在Tensorflow中，但Tensorflow-slim模型[库](https://github.com/tensorflow/models/tree/master/research/slim)提供了预训练的ResNet、VGG和其他模型。

> NOTE: You can find a pre-trained [AlexNet](https://github.com/BVLC/caffe/tree/master/models/bvlc_alexnet) in Caffe Model [Zoo](https://github.com/caffe2/caffe2/wiki/Model-Zoo). I don’t think you can [find it](https://github.com/tensorflow/models/issues/1394) in Tensorflow, but Tensorflow-slim model [library](https://github.com/tensorflow/models/tree/master/research/slim) provides pre-trained ResNet, VGG, and others.

1. 通过选择性搜索提出与类别无关的感兴趣区域（每张图像约2k个候选区域）。这些区域可能包含目标对象，并且它们的大小各不相同。
2. 区域候选框被**形变**以具有CNN所需的固定大小。
3. 继续在扭曲的候选区域上对CNN进行K+1个类别的微调；额外的一个类别指的是背景（没有感兴趣的对象）。在微调阶段，我们应该使用小得多的学习率，并且mini-batch会过采样正例，因为大多数候选区域都只是背景。
4. 对于每个图像区域，通过CNN的一次前向传播会生成一个特征向量。然后，这个特征向量会被一个**二分类SVM**所使用，该SVM是为**每个类别**独立训练的。
  

正样本是IoU（交并比）重叠阈值大于等于0.3的候选区域，负样本是其他不相关的区域。
5. 为了减少定位误差，训练了一个回归模型，利用CNN特征来校正预测的检测窗口的边界框校正偏移。

> • Propose category-independent regions of interest by selective search (~2k candidates per image). Those regions may contain target objects and they are of different sizes.
> • Region candidates are **warped** to have a fixed size as required by CNN.
> • Continue fine-tuning the CNN on warped proposal regions for K + 1 classes; The additional one class refers to the background (no object of interest). In the fine-tuning stage, we should use a much smaller learning rate and the mini-batch oversamples the positive cases because most proposed regions are just background.
> • Given every image region, one forward propagation through the CNN generates a feature vector. This feature vector is then consumed by a **binary SVM** trained for **each class** independently.
>
>
> The positive samples are proposed regions with IoU (intersection over union) overlap threshold >= 0.3, and negative samples are irrelevant others.
> • To reduce the localization errors, a regression model is trained to correct the predicted detection window on bounding box correction offset using CNN features.

#### 边界框回归

> Bounding Box Regression

给定预测的边界框坐标 $\mathbf{p} = (p_x, p_y, p_w, p_h)$ （中心坐标、宽度、高度）及其对应的真实框坐标 $\mathbf{g} = (g_x, g_y, g_w, g_h)$ ，回归器被配置为学习两个中心之间的尺度不变变换以及宽度和高度之间的对数尺度变换。所有变换函数都将 $\mathbf{p}$ 作为输入。

> Given a predicted bounding box coordinate $\mathbf{p} = (p_x, p_y, p_w, p_h)$ (center coordinate, width, height) and its corresponding ground truth box coordinates $\mathbf{g} = (g_x, g_y, g_w, g_h)$ , the regressor is configured to learn scale-invariant transformation between two centers and log-scale transformation between widths and heights. All the transformation functions take $\mathbf{p}$ as input.

$$
\begin{aligned}
\hat{g}_x &= p_w d_x(\mathbf{p}) + p_x \\
\hat{g}_y &= p_h d_y(\mathbf{p}) + p_y \\
\hat{g}_w &= p_w \exp({d_w(\mathbf{p})}) \\
\hat{g}_h &= p_h \exp({d_h(\mathbf{p})})
\end{aligned}
$$

![Illustration of transformation between predicted and ground truth bounding boxes.](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/RCNN-bbox-regression.png)

应用这种变换的一个明显好处是，所有边界框校正函数 $d_i(\mathbf{p})$ ，其中 $i \in \{ x, y, w, h \}$ ，可以取 [-∞, +∞] 之间的任何值。它们要学习的目标是：

> An obvious benefit of applying such transformation is that all the bounding box correction functions, $d_i(\mathbf{p})$ where $i \in \{ x, y, w, h \}$, can take any value between [-∞, +∞]. The targets for them to learn are:

$$
\begin{aligned}
t_x &= (g_x - p_x) / p_w \\
t_y &= (g_y - p_y) / p_h \\
t_w &= \log(g_w/p_w) \\
t_h &= \log(g_h/p_h)
\end{aligned}
$$

一个标准的回归模型可以通过最小化带有正则化的 SSE 损失来解决这个问题：

> A standard regression model can solve the problem by minimizing the SSE loss with regularization:

$$
\mathcal{L}_\text{reg} = \sum_{i \in \{x, y, w, h\}} (t_i - d_i(\mathbf{p}))^2 + \lambda \|\mathbf{w}\|^2
$$

正则化项在这里至关重要，RCNN 论文通过交叉验证选择了最佳的 λ。值得注意的是，并非所有预测的边界框都有对应的真实框。例如，如果没有重叠，运行边界框回归就没有意义。在这里，只有与附近真实框的 IoU 至少为 0.6 的预测框才被保留用于训练边界框回归模型。

> The regularization term is critical here and RCNN paper picked the best λ by cross validation. It is also noteworthy that not all the predicted bounding boxes have corresponding ground truth boxes. For example, if there is no overlap, it does not make sense to run bbox regression. Here, only a predicted box with a nearby ground truth box with at least 0.6 IoU is kept for training the bbox regression model.

#### 常见技巧

> Common Tricks

RCNN 和其他检测模型中常用到几种技巧。

> Several tricks are commonly used in RCNN and other detection models.

**非极大值抑制**

> **Non-Maximum Suppression**

模型很可能能够为同一对象找到多个边界框。非极大值抑制有助于避免重复检测同一实例。在我们获得一组针对同一对象类别的匹配边界框后：
按置信度分数对所有边界框进行排序。
丢弃置信度分数低的框。
*当*还有任何剩余边界框时，重复以下步骤：
贪婪地选择分数最高的那个。
跳过与之前选择的框具有高 IoU（即 > 0.5）的剩余框。

> Likely the model is able to find multiple bounding boxes for the same object. Non-max suppression helps avoid repeated detection of the same instance. After we get a set of matched bounding boxes for the same object category:
> Sort all the bounding boxes by confidence score.
> Discard boxes with low confidence scores.
> *While* there is any remaining bounding box, repeat the following:
> Greedily select the one with the highest score.
> Skip the remaining boxes with high IoU (i.e. > 0.5) with previously selected one.

![Multiple bounding boxes detect the car in the image. After non-maximum suppression, only the best remains and the rest are ignored as they have large overlaps with the selected one. (Image source: DPM paper )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/non-max-suppression.png)

**难例挖掘**

> **Hard Negative Mining**

我们将不包含对象的边界框视为负例。并非所有负例都同样难以识别。例如，如果它只包含纯粹的空背景，那很可能是一个“*易负例*”；但如果框中包含奇怪的噪声纹理或部分对象，它可能难以识别，这些就是“*难负例*”。

> We consider bounding boxes without objects as negative examples. Not all the negative examples are equally hard to be identified. For example, if it holds pure empty background, it is likely an “*easy negative*”; but if the box contains weird noisy texture or partial object, it could be hard to be recognized and these are “*hard negative*”.

难负例很容易被错误分类。我们可以在训练循环中明确找到这些假阳性样本，并将它们包含在训练数据中，以改进分类器。

> The hard negative examples are easily misclassified. We can explicitly find those false positive samples during the training loops and include them in the training data so as to improve the classifier.

#### 速度瓶颈

> Speed Bottleneck

回顾 R-CNN 的学习步骤，你会很容易发现训练 R-CNN 模型既昂贵又缓慢，因为以下步骤涉及大量工作：

> Looking through the R-CNN learning steps, you could easily find out that training an R-CNN model is expensive and slow, as the following steps involve a lot of work:

- 对每张图像运行选择性搜索以提出 2000 个区域候选；
- 为每个图像区域生成 CNN 特征向量（N 张图像 * 2000）。
- 整个过程涉及三个独立模型，没有太多共享计算：用于图像分类和特征提取的卷积神经网络；用于识别目标对象的顶级 SVM 分类器；以及用于收紧区域边界框的回归模型。

> • Running selective search to propose 2000 region candidates for every image;
> • Generating the CNN feature vector for every image region (N images * 2000).
> • The whole process involves three models separately without much shared computation: the convolutional neural network for image classification and feature extraction; the top SVM classifier for identifying target objects; and the regression model for tightening region bounding boxes.

### Fast R-CNN

> Fast R-CNN

为了使 R-CNN 更快，Girshick ([2015](https://arxiv.org/pdf/1504.08083.pdf)) 通过将三个独立模型统一到一个联合训练框架中并增加共享计算结果来改进训练过程，该框架名为 **Fast R-CNN**。该模型不是为每个区域提议独立提取 CNN 特征向量，而是将它们聚合为对整个图像的一次 CNN 前向传播，并且区域提议共享此特征矩阵。然后，相同的特征矩阵被分支出来，用于学习对象分类器和边界框回归器。总之，计算共享加快了 R-CNN 的速度。

> To make R-CNN faster, Girshick ([2015](https://arxiv.org/pdf/1504.08083.pdf)) improved the training procedure by unifying three independent models into one jointly trained framework and increasing shared computation results, named **Fast R-CNN**. Instead of extracting CNN feature vectors independently for each region proposal, this model aggregates them into one CNN forward pass over the entire image and the region proposals share this feature matrix. Then the same feature matrix is branched out to be used for learning the object classifier and the bounding-box regressor. In conclusion, computation sharing speeds up R-CNN.

![The architecture of Fast R-CNN. (Image source: Girshick, 2015 )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/fast-RCNN.png)

#### RoI 池化

> RoI Pooling

它是一种最大池化，用于将图像中任意大小 h x w 的投影区域中的特征转换为一个小的固定窗口 H x W。输入区域被划分为 H x W 个网格，每个子窗口的大小大约为 h/H x w/W。然后，在每个网格中应用最大池化。

> It is a type of max pooling to convert features in the projected region of the image of any size, h x w, into a small fixed window, H x W. The input region is divided into H x W grids, approximately every subwindow of size h/H x w/W. Then apply max-pooling in each grid.

![RoI pooling (Image source: Stanford CS231n slides .)](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/roi-pooling.png)

#### 模型工作流程

> Model Workflow

Fast R-CNN 的工作原理总结如下；许多步骤与 R-CNN 相同：

> How Fast R-CNN works is summarized as follows; many steps are same as in R-CNN:

1. 首先，在图像分类任务上预训练一个卷积神经网络。
2. 通过选择性搜索（每张图像约 2k 个候选区域）提出区域。
3. 修改预训练的 CNN:


   - 将预训练 CNN 的最后一个最大池化层替换为 [RoI 池化](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#roi-pooling)层。RoI 池化层输出区域提议的固定长度特征向量。共享 CNN 计算非常有意义，因为同一图像的许多区域提议高度重叠。
   - 将最后一个全连接层和最后一个 softmax 层（K 个类别）替换为全连接层和 K + 1 个类别的 softmax。
4. 最后，模型分支为两个输出层:


   - 一个 K + 1 个类别的 softmax 估计器（与 R-CNN 中相同，+1 是“背景”类别），为每个 RoI 输出一个离散概率分布。
   - 一个边界框回归模型，它为 K 个类别中的每一个预测相对于原始 RoI 的偏移量。

> • First, pre-train a convolutional neural network on image classification tasks.

> • Propose regions by selective search (~2k candidates per image).

> • Alter the pre-trained CNN:
>

> ◦ Replace the last max pooling layer of the pre-trained CNN with a [RoI pooling](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#roi-pooling) layer. The RoI pooling layer outputs fixed-length feature vectors of region proposals. Sharing the CNN computation makes a lot of sense, as many region proposals of the same images are highly overlapped.

> ◦ Replace the last fully connected layer and the last softmax layer (K classes) with a fully connected layer and softmax over K + 1 classes.

> • Finally the model branches into two output layers:
>

> ◦ A softmax estimator of K + 1 classes (same as in R-CNN, +1 is the “background” class), outputting a discrete probability distribution per RoI.

> ◦ A bounding-box regression model which predicts offsets relative to the original RoI for each of K classes.

#### 损失函数

> Loss Function

该模型针对结合了两个任务（分类 + 定位）的损失进行优化：

> The model is optimized for a loss combining two tasks (classification + localization):

| **符号** | **解释** |
| --- | --- |
| $u$ | 真实类别标签，$u \in 0, 1, \dots, K$；按照惯例，包罗万象的背景类别具有 $u = 0$。 |
| $p$ | K + 1 个类别（每个 RoI）上的离散概率分布：$p = (p_0, \dots, p_K)$，通过对全连接层的 K + 1 个输出进行 softmax 计算得到。 |
| $v$ | 真实边界框 $v = (v_x, v_y, v_w, v_h)$。 |
| $t^u$ | 预测的边界框校正，$t^u = (t^u_x, t^u_y, t^u_w, t^u_h)$。参见 [上文](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression)。 |

> 英文原表 / English original

| **Symbol** | **Explanation** |
| --- | --- |
| $u$ | True class label, $u \in 0, 1, \dots, K$; by convention, the catch-all background class has $u = 0$. |
| $p$ | Discrete probability distribution (per RoI) over K + 1 classes: $p = (p_0, \dots, p_K)$, computed by a softmax over the K + 1 outputs of a fully connected layer. |
| $v$ | True bounding box $v = (v_x, v_y, v_w, v_h)$. |
| $t^u$ | Predicted bounding box correction, $t^u = (t^u_x, t^u_y, t^u_w, t^u_h)$. See [above](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression). |

损失函数汇总了分类和边界框预测的成本：$\mathcal{L} = \mathcal{L}_\text{cls} + \mathcal{L}_\text{box}$。对于“背景”RoI，$\mathcal{L}_\text{box}$ 被指示函数 $\mathbb{1} [u \geq 1]$ 忽略，定义为：

> The loss function sums up the cost of classification and bounding box prediction: $\mathcal{L} = \mathcal{L}_\text{cls} + \mathcal{L}_\text{box}$. For “background” RoI, $\mathcal{L}_\text{box}$ is ignored by the indicator function $\mathbb{1} [u \geq 1]$, defined as:

$$
\mathbb{1} [u >= 1] = \begin{cases}
    1  & \text{if } u \geq 1\\
    0  & \text{otherwise}
\end{cases}
$$

总损失函数为：

> The overall loss function is:

$$
\begin{align*}
\mathcal{L}(p, u, t^u, v) &= \mathcal{L}_\text{cls} (p, u) + \mathbb{1} [u \geq 1] \mathcal{L}_\text{box}(t^u, v) \\
\mathcal{L}_\text{cls}(p, u) &= -\log p_u \\
\mathcal{L}_\text{box}(t^u, v) &= \sum_{i \in \{x, y, w, h\}} L_1^\text{smooth} (t^u_i - v_i)
\end{align*}
$$

边界框损失 $\mathcal{L}_{box}$ 应该衡量 $t^u_i$ 与 `v_i` 之间的差异，使用 **鲁棒的** 损失函数。这里采用了 [平滑 L1 损失](https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf)，据称它对异常值不那么敏感。

英文原文：The bounding box loss 

$\mathcal{L}_{box}$ should measure the difference between 

$t^u_i$ and `v_i` using a robust loss function. The [smooth L1 loss](https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf) is adopted here and it is claimed to be less sensitive to outliers.

$$
L_1^\text{smooth}(x) = \begin{cases}
    0.5 x^2             & \text{if } \vert x \vert < 1\\
    \vert x \vert - 0.5 & \text{otherwise}
\end{cases}
$$

![The plot of smooth L1 loss, $y = L\_1^\text{smooth}(x)$. (Image source: link )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/l1-smooth.png)

#### 速度瓶颈

> Speed Bottleneck

Fast R-CNN 在训练和测试时间上都快得多。然而，这种改进并不显著，因为区域提议是由另一个模型单独生成的，这非常耗时。

> Fast R-CNN is much faster in both training and testing time. However, the improvement is not dramatic because the region proposals are generated separately by another model and that is very expensive.

### Faster R-CNN

> Faster R-CNN

一个直观的加速解决方案是将区域提议算法集成到 CNN 模型中。**Faster R-CNN** ([Ren 等人，2016](https://arxiv.org/pdf/1506.01497.pdf)) 正是这样做的：构建一个由 RPN（区域提议网络）和 Fast R-CNN 组成的单一统一模型，并共享卷积特征层。

> An intuitive speedup solution is to integrate the region proposal algorithm into the CNN model. **Faster R-CNN** ([Ren et al., 2016](https://arxiv.org/pdf/1506.01497.pdf)) is doing exactly this: construct a single, unified model composed of RPN (region proposal network) and fast R-CNN with shared convolutional feature layers.

![An illustration of Faster R-CNN model. (Image source: Ren et al., 2016 )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/faster-RCNN.png)

#### 模型工作流程

> Model Workflow

1. 在图像分类任务上预训练一个 CNN 网络。
2. 为区域提议任务端到端地微调 RPN（区域提议网络），该网络由预训练的图像分类器初始化。正样本的 IoU（交并比）> 0.7，而负样本的 IoU < 0.3。


   - 将一个小的 n x n 空间窗口滑过整个图像的卷积特征图。
   - 在每个滑动窗口的中心，我们同时预测多个不同尺度和比例的区域。一个锚点是（滑动窗口中心、尺度、比例）的组合。例如，3 种尺度 + 3 种比例 => 每个滑动位置有 k=9 个锚点。
3. 使用当前 RPN 生成的候选区域训练一个 Fast R-CNN 目标检测模型
4. 然后使用 Fast R-CNN 网络初始化 RPN 训练。在保持共享卷积层不变的情况下，只微调 RPN 特有的层。在此阶段，RPN 和检测网络共享卷积层！
5. 最后微调 Fast R-CNN 的独特层
6. 如果需要，可以重复步骤 4-5 交替训练 RPN 和 Fast R-CNN。

> • Pre-train a CNN network on image classification tasks.

> • Fine-tune the RPN (region proposal network) end-to-end for the region proposal task, which is initialized by the pre-train image classifier. Positive samples have IoU (intersection-over-union) > 0.7, while negative samples have IoU < 0.3.
>

> ◦ Slide a small n x n spatial window over the conv feature map of the entire image.

> ◦ At the center of each sliding window, we predict multiple regions of various scales and ratios simultaneously. An anchor is a combination of (sliding window center, scale, ratio). For example, 3 scales + 3 ratios => k=9 anchors at each sliding position.

> • Train a Fast R-CNN object detection model using the proposals generated by the current RPN

> • Then use the Fast R-CNN network to initialize RPN training. While keeping the shared convolutional layers, only fine-tune the RPN-specific layers. At this stage, RPN and the detection network have shared convolutional layers!

> • Finally fine-tune the unique layers of Fast R-CNN

> • Step 4-5 can be repeated to train RPN and Fast R-CNN alternatively if needed.

#### 损失函数

> Loss Function

Faster R-CNN 针对多任务损失函数进行了优化，类似于 Fast R-CNN。

> Faster R-CNN is optimized for a multi-task loss function, similar to fast R-CNN.

| **符号** | **解释** |
| --- | --- |
| $p_i$ | 锚点 i 是目标的预测概率。 |
| $p^{\ast}_i$ | 锚点 i 是否是目标的真实标签（二元）。 |
| $t_i$ | 预测的四个参数化坐标。 |
| $t^{\ast}_i$ | 真实坐标。 |
| $N_\text{cls}$ | 归一化项，在论文中设置为 mini-batch 大小（约 256）。 |
| $N_\text{box}$ | 归一化项，在论文中设置为锚点位置的数量（约 2400）。 |
| $\lambda$ | 一个平衡参数，在论文中设置为约 10（以便 $\mathcal{L}_\text{cls}$ 和 $\mathcal{L}_\text{box}$ 项大致同等权重）。 |

> 英文原表 / English original

| **Symbol**  | **Explanation** |
| --- | --- |
| $p_i$     | Predicted probability of anchor i being an object. |
| $p^{\ast}_i$   | Ground truth label (binary) of whether anchor i is an object. |
| $t_i$     | Predicted four parameterized coordinates. |
| $t^{\ast}_i$   | Ground truth coordinates. |
| $N_\text{cls}$ | Normalization term, set to be mini-batch size (~256) in the paper. |
| $N_\text{box}$ | Normalization term, set to the number of anchor locations (~2400) in the paper. |
| $\lambda$ | A balancing parameter, set to be ~10 in the paper (so that both $\mathcal{L}_\text{cls}$ and $\mathcal{L}_\text{box}$ terms are roughly equally weighted). |

多任务损失函数结合了分类和边界框回归的损失：

> The multi-task loss function combines the losses of classification and bounding box regression:

$$
\begin{align*}
\mathcal{L} &= \mathcal{L}_\text{cls} + \mathcal{L}_\text{box} \\
\mathcal{L}(\{p_i\}, \{t_i\}) &= \frac{1}{N_\text{cls}} \sum_i \mathcal{L}_\text{cls} (p_i, p^*_i) + \frac{\lambda}{N_\text{box}} \sum_i p^*_i \cdot L_1^\text{smooth}(t_i - t^*_i) \\
\end{align*}
$$

其中 $\mathcal{L}_\text{cls}$ 是两类上的对数损失函数，因为我们可以通过预测样本是否为目标对象，轻松地将多类分类转换为二元分类。$L_1^\text{smooth}$ 是平滑 L1 损失。

> where $\mathcal{L}_\text{cls}$ is the log loss function over two classes, as we can easily translate a multi-class classification into a binary classification by predicting a sample being a target object versus not. $L_1^\text{smooth}$ is the smooth L1 loss.

$$
\mathcal{L}_\text{cls} (p_i, p^*_i) = - p^*_i \log p_i - (1 - p^*_i) \log (1 - p_i)
$$

### Mask R-CNN

> Mask R-CNN

Mask R-CNN ([He et al., 2017](https://arxiv.org/pdf/1703.06870.pdf)) 将 Faster R-CNN 扩展到像素级 [图像分割](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/#image-segmentation-felzenszwalbs-algorithm)。关键在于解耦分类任务和像素级掩码预测任务。基于 [Faster R-CNN](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#faster-r-cnn) 的框架，它增加了一个第三分支，用于与现有的分类和定位分支并行预测对象掩码。掩码分支是一个应用于每个 RoI 的小型全连接网络，以像素到像素的方式预测分割掩码。

> Mask R-CNN ([He et al., 2017](https://arxiv.org/pdf/1703.06870.pdf)) extends Faster R-CNN to pixel-level [image segmentation](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/#image-segmentation-felzenszwalbs-algorithm). The key point is to decouple the classification and the pixel-level mask prediction tasks. Based on the framework of [Faster R-CNN](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#faster-r-cnn), it added a third branch for predicting an object mask in parallel with the existing branches for classification and localization. The mask branch is a small fully-connected network applied to each RoI, predicting a segmentation mask in a pixel-to-pixel manner.

![Mask R-CNN is Faster R-CNN model with image segmentation. (Image source: He et al., 2017 )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/mask-rcnn.png)

因为像素级分割比边界框需要更精细的对齐，mask R-CNN 改进了 RoI 池化层（命名为“RoIAlign 层”），以便 RoI 能够更好、更精确地映射到原始图像的区域。

> Because pixel-level segmentation requires much more fine-grained alignment than bounding boxes, mask R-CNN improves the RoI pooling layer (named “RoIAlign layer”) so that RoI can be better and more precisely mapped to the regions of the original image.

![Predictions by Mask R-CNN on COCO test set. (Image source: He et al., 2017 )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/mask-rcnn-examples.png)

#### RoIAlign

> RoIAlign

RoIAlign 层旨在修复 RoI 池化中量化引起的定位错位。RoIAlign 消除了哈希量化，例如，通过使用 x/16 而不是 [x/16]，从而使提取的特征能够与输入像素正确对齐。[双线性插值](https://en.wikipedia.org/wiki/Bilinear_interpolation)用于计算输入中的浮点位置值。

> The RoIAlign layer is designed to fix the location misalignment caused by quantization in the RoI pooling. RoIAlign removes the hash quantization, for example, by using x/16 instead of [x/16], so that the extracted features can be properly aligned with the input pixels. [Bilinear interpolation](https://en.wikipedia.org/wiki/Bilinear_interpolation) is used for computing the floating-point location values in the input.

![A region of interest is mapped **accurately** from the original image onto the feature map without rounding up to integers. (Image source: link )](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/roi-align.png)

#### 损失函数

> Loss Function

Mask R-CNN 的多任务损失函数结合了分类、定位和分割掩码的损失：$\mathcal{L} = \mathcal{L}_\text{cls} + \mathcal{L}_\text{box} + \mathcal{L}_\text{mask}$，其中 $\mathcal{L}_\text{cls}$ 和 $\mathcal{L}_\text{box}$ 与 Faster R-CNN 中的相同。

> The multi-task loss function of Mask R-CNN combines the loss of classification, localization and segmentation mask: $\mathcal{L} = \mathcal{L}_\text{cls} + \mathcal{L}_\text{box} + \mathcal{L}_\text{mask}$, where $\mathcal{L}_\text{cls}$ and $\mathcal{L}_\text{box}$ are same as in Faster R-CNN.

掩码分支为每个RoI和每个类别生成一个m x m维度的掩码；总共有K个类别。因此，总输出的大小为$K \cdot m^2$。因为模型试图为每个类别学习一个掩码，所以在生成掩码时，类别之间没有竞争。

> The mask branch generates a mask of dimension m x m for each RoI and each class; K classes in total. Thus, the total output is of size $K \cdot m^2$. Because the model is trying to learn a mask for each class, there is no competition among classes for generating masks.

$\mathcal{L}_\text{mask}$被定义为平均二元交叉熵损失，仅当区域与真实类别k相关联时才包含第k个掩码。

> $\mathcal{L}_\text{mask}$ is defined as the average binary cross-entropy loss, only including k-th mask if the region is associated with the ground truth class k.

$$
\mathcal{L}_\text{mask} = - \frac{1}{m^2} \sum_{1 \leq i, j \leq m} \big[ y_{ij} \log \hat{y}^k_{ij} + (1-y_{ij}) \log (1- \hat{y}^k_{ij}) \big]
$$

其中$y_{ij}$是m x m大小区域的真实掩码中单元格(i, j)的标签；$\hat{y}_{ij}^k$是为真实类别k学习到的掩码中同一单元格的预测值。

> where $y_{ij}$ is the label of a cell (i, j) in the true mask for the region of size m x m; $\hat{y}_{ij}^k$ is the predicted value of the same cell in the mask learned for the ground-truth class k.

### R-CNN家族模型总结

> Summary of Models in the R-CNN family

这里我将阐述R-CNN、Fast R-CNN、Faster R-CNN和Mask R-CNN的模型设计。通过比较细微的差异，你可以追踪一个模型是如何演变为下一个版本的。

> Here I illustrate model designs of R-CNN, Fast R-CNN, Faster R-CNN and Mask R-CNN. You can track how one model evolves to the next version by comparing the small differences.

![](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/rcnn-family-summary.png)

引用方式：

> Cited as:

```
@article{weng2017detection3,
  title   = "Object Detection for Dummies Part 3: R-CNN Family",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2017",
  url     = "https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/"
}
```

### 参考文献

> Reference

[1] Ross Girshick, Jeff Donahue, Trevor Darrell, and Jitendra Malik. [“用于精确目标检测和语义分割的丰富特征层次结构。”](https://www.cv-foundation.org/openaccess/content_cvpr_2014/papers/Girshick_Rich_Feature_Hierarchies_2014_CVPR_paper.pdf) In Proc. IEEE Conf. on computer vision and pattern recognition (CVPR), pp. 580-587. 2014.

> [1] Ross Girshick, Jeff Donahue, Trevor Darrell, and Jitendra Malik. [“Rich feature hierarchies for accurate object detection and semantic segmentation.”](https://www.cv-foundation.org/openaccess/content_cvpr_2014/papers/Girshick_Rich_Feature_Hierarchies_2014_CVPR_paper.pdf) In Proc. IEEE Conf. on computer vision and pattern recognition (CVPR), pp. 580-587. 2014.

[2] Ross Girshick. [“Fast R-CNN.”](https://arxiv.org/pdf/1504.08083.pdf) In Proc. IEEE Intl. Conf. on computer vision, pp. 1440-1448. 2015.

> [2] Ross Girshick. [“Fast R-CNN.”](https://arxiv.org/pdf/1504.08083.pdf) In Proc. IEEE Intl. Conf. on computer vision, pp. 1440-1448. 2015.

[3] Shaoqing Ren, Kaiming He, Ross Girshick, and Jian Sun. [“Faster R-CNN：利用区域提议网络实现实时目标检测。”](http://papers.nips.cc/paper/5638-faster-r-cnn-towards-real-time-object-detection-with-region-proposal-networks.pdf) In Advances in neural information processing systems (NIPS), pp. 91-99. 2015.

> [3] Shaoqing Ren, Kaiming He, Ross Girshick, and Jian Sun. [“Faster R-CNN: Towards real-time object detection with region proposal networks.”](http://papers.nips.cc/paper/5638-faster-r-cnn-towards-real-time-object-detection-with-region-proposal-networks.pdf) In Advances in neural information processing systems (NIPS), pp. 91-99. 2015.

[4] Kaiming He, Georgia Gkioxari, Piotr Dollár, and Ross Girshick. [“Mask R-CNN.”](https://arxiv.org/pdf/1703.06870.pdf) arXiv preprint arXiv:1703.06870, 2017.

> [4] Kaiming He, Georgia Gkioxari, Piotr Dollár, and Ross Girshick. [“Mask R-CNN.”](https://arxiv.org/pdf/1703.06870.pdf) arXiv preprint arXiv:1703.06870, 2017.

[5] Joseph Redmon, Santosh Divvala, Ross Girshick, and Ali Farhadi. [“你只看一次：统一的实时目标检测。”](https://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/Redmon_You_Only_Look_CVPR_2016_paper.pdf) In Proc. IEEE Conf. on computer vision and pattern recognition (CVPR), pp. 779-788. 2016.

> [5] Joseph Redmon, Santosh Divvala, Ross Girshick, and Ali Farhadi. [“You only look once: Unified, real-time object detection.”](https://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/Redmon_You_Only_Look_CVPR_2016_paper.pdf) In Proc. IEEE Conf. on computer vision and pattern recognition (CVPR), pp. 779-788. 2016.

[6] [“图像分割中CNN的简史：从R-CNN到Mask R-CNN”](https://blog.athelas.com/a-brief-history-of-cnns-in-image-segmentation-from-r-cnn-to-mask-r-cnn-34ea83205de4) by Athelas.

> [6] [“A Brief History of CNNs in Image Segmentation: From R-CNN to Mask R-CNN”](https://blog.athelas.com/a-brief-history-of-cnns-in-image-segmentation-from-r-cnn-to-mask-r-cnn-34ea83205de4) by Athelas.

[7] 平滑L1损失: [https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf](https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf)

> [7] Smooth L1 Loss: [https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf](https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| R-CNN | 基于区域的卷积神经网络 | 一种早期目标检测模型，结合选择性搜索、CNN特征提取和SVM分类。 |
| Selective Search | 选择性搜索 | 一种图像分割算法，用于生成可能包含对象的区域候选。 |
| RoI | 感兴趣区域 | 图像中可能包含目标对象的候选区域。 |
| IoU | 交并比 | 衡量预测边界框与真实边界框重叠程度的指标。 |
| Bounding Box Regression | 边界框回归 | 一种用于校正预测边界框位置和大小的回归模型。 |
| Non-Maximum Suppression (NMS) | 非极大值抑制 | 一种后处理技术，用于消除同一对象的重复检测框。 |
| Hard Negative Mining | 难例挖掘 | 在训练中识别并包含难以分类的负样本，以提高分类器性能。 |
| Fast R-CNN | 快速R-CNN | R-CNN的改进版，通过共享CNN特征和联合训练，显著提高了速度。 |
| RoI Pooling | 感兴趣区域池化 | 一种最大池化操作，将不同大小的RoI特征图转换为固定大小的特征向量。 |
| Faster R-CNN | 更快R-CNN | Fast R-CNN的改进版，通过引入区域提议网络（RPN）实现端到端的区域提议和目标检测。 |
| RPN | 区域提议网络 | Faster R-CNN中的一个组件，用于生成高质量的区域候选。 |
| Anchor | 锚点 | 在RPN中预定义的、具有不同尺度和比例的候选框。 |
| Mask R-CNN | 掩码R-CNN | Faster R-CNN的扩展，用于像素级实例分割，并引入RoIAlign。 |
| RoIAlign | 感兴趣区域对齐 | Mask R-CNN中改进的RoI池化层，通过双线性插值消除量化误差，实现更精确的特征对齐。 |
| Smooth L1 Loss | 平滑L1损失 | 一种对异常值不敏感的回归损失函数，常用于边界框回归。 |
