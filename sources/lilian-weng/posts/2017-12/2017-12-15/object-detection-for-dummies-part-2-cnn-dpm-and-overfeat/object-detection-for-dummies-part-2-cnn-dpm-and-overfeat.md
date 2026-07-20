# 傻瓜式目标检测 第二部分：CNN、DPM 和 Overfeat

> Object Detection for Dummies Part 2: CNN, DPM and Overfeat

> 来源：Lil'Log / Lilian Weng，2017-12-15
> 原文链接：https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/
> 分类：深度学习 / 目标检测

## 核心要点

- 本文作为《傻瓜式目标检测》系列的第二部分，主要探讨了用于图像分类的经典卷积神经网络架构。
- 卷积神经网络（CNN）是解决计算机视觉问题的首选方案，其核心卷积操作通过核与输入特征图的乘加生成输出。
- AlexNet、VGG和ResNet是重要的CNN架构，它们分别引入了数据增强、简化深层结构和残差块等关键技术。
- 残差块对于训练深度网络至关重要，它通过允许某些输入跳过层来解决深度学习中的梯度消失和梯度爆炸问题。
- 平均精度均值（mAP）是目标识别和检测任务中常用的评估指标，通过计算各类别精确率-召回率曲线下的面积并取平均值获得。
- 可变形部件模型（DPM）通过根滤波器、部件滤波器和空间模型识别对象，其检测质量由滤波器分数减去形变成本衡量。
- DPM模型可以被重新表述为卷积神经网络，表明两者并非完全不同的方法。
- Overfeat是一个开创性的模型，它将目标检测、定位和分类集成到一个CNN中，通过滑动窗口分类和回归器预测边界框。
- Overfeat的训练过程包括先进行图像分类，然后用回归网络替换分类器层来预测边界框。
- Overfeat在检测时会合并来自定位和分类器的具有足够重叠和置信度的边界框。

## 正文

《傻瓜式目标检测》系列文章的[第一部分](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)介绍了：(1) 图像梯度向量的概念以及 HOG 算法如何总结一张图像中所有梯度向量的信息；(2) 图像分割算法如何工作以检测可能包含对象的区域；(3) Selective Search 算法如何改进图像分割结果以获得更好的区域提议。

> [Part 1](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/) of the “Object Detection for Dummies” series introduced: (1) the concept of image gradient vector and how HOG algorithm summarizes the information across all the gradient vectors in one image; (2) how the image segmentation algorithm works to detect regions that potentially contain objects; (3) how the Selective Search algorithm refines the outcomes of image segmentation for better region proposal.

在第二部分中，我们将深入探讨用于图像分类的经典卷积神经网络架构。它们为目标检测深度学习模型的进一步发展奠定了***基础***。如果您想了解更多关于 R-CNN 及相关模型的信息，请查看[第三部分](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)。

> In Part 2, we are about to find out more on the classic convolution neural network architectures for image classification. They lay the ***foundation*** for further progress on the deep learning models for object detection. Go check [Part 3](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/) if you want to learn more on R-CNN and related models.

本系列所有文章的链接:
[[第一部分](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)]
[[第二部分](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)]
[[第三部分](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)]
[[第四部分](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)]。

> Links to all the posts in the series:
> [[Part 1](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)]
> [[Part 2](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)]
> [[Part 3](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)]
> [[Part 4](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)].

### 用于图像分类的 CNN

> CNN for Image Classification

CNN，是“**卷积神经网络**”的缩写，是深度学习领域中解决计算机视觉问题的首选方案。它在一定程度上[受到了](https://lilianweng.github.io/posts/2017-06-21-overview/#convolutional-neural-network)人类视觉皮层系统工作方式的启发。

> CNN, short for “**Convolutional Neural Network**”, is the go-to solution for computer vision problems in the deep learning world. It was, to some extent, [inspired](https://lilianweng.github.io/posts/2017-06-21-overview/#convolutional-neural-network) by how human visual cortex system works.

#### 卷积操作

> Convolution Operation

我强烈推荐这篇[指南](https://arxiv.org/pdf/1603.07285.pdf)，它提供了清晰而扎实的卷积运算解释，并附有大量的可视化和示例。本文我们将重点关注二维卷积，因为我们正在处理图像。

> I strongly recommend this [guide](https://arxiv.org/pdf/1603.07285.pdf) to convolution arithmetic, which provides a clean and solid explanation with tons of visualizations and examples. Here let’s focus on two-dimensional convolution as we are working with images in this post.

简而言之，卷积操作将预定义的[核](https://en.wikipedia.org/wiki/Kernel_(image_processing))（也称为“滤波器”）滑动到输入特征图（图像像素矩阵）之上，将核的值与部分输入特征相乘并相加，以生成输出。这些值形成一个输出矩阵，因为通常核比输入图像小得多。

> In short, convolution operation slides a predefined [kernel](https://en.wikipedia.org/wiki/Kernel_(image_processing)) (also called “filter”) on top of the input feature map (matrix of image pixels), multiplying and adding the values of the kernel and partial input features to generate the output. The values form an output matrix, as usually, the kernel is much smaller than the input image.

![An illustration of applying a kernel on the input feature map to generate the output. (Image source: River Trail documentation )](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/convolution-operation.png)

图 2 展示了两个真实示例，说明如何将 3x3 的核与 5x5 的二维数值矩阵进行卷积以生成 3x3 矩阵。通过控制填充大小和步长，我们可以生成特定大小的输出矩阵。

> Figure 2 showcases two real examples of how to convolve a 3x3 kernel over a 5x5 2D matrix of numeric values to generate a 3x3 matrix. By controlling the padding size and the stride length, we can generate an output matrix of a certain size.

![Two examples of 2D convolution operation: (top) no padding and 1x1 strides; (bottom) 1x1 border zeros padding and 2x2 strides. (Image source: deeplearning.net )](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/numerical_no_padding_no_strides.gif)

![Two examples of 2D convolution operation: (top) no padding and 1x1 strides; (bottom) 1x1 border zeros padding and 2x2 strides. (Image source: deeplearning.net )](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/numerical_padding_strides.gif)

#### AlexNet (Krizhevsky 等人，2012)

> AlexNet (Krizhevsky et al, 2012)

- 5 个卷积层[+ 可选的最大池化层] + 2 个 MLP 层 + 1 个 LR 层
- 使用数据增强技术来扩展训练数据集，例如图像平移、水平翻转和块提取。

> • 5 convolution [+ optional max pooling] layers + 2 MLP layers + 1 LR layer
> • Use data augmentation techniques to expand the training dataset, such as image translations, horizontal reflections, and patch extractions.

![The architecture of AlexNet. (Image source: link )](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/alex_net_illustration.png)

#### VGG (Simonyan 和 Zisserman，2014)

> VGG (Simonyan and Zisserman, 2014)

- 该网络在当时被认为是“非常深”的；19 层
- 该架构极其简化，仅包含 3x3 卷积层和 2x2 池化层。小滤波器的堆叠模拟了参数更少的大滤波器。

> • The network is considered as “very deep” at its time; 19 layers
> • The architecture is extremely simplified with only 3x3 convolutional layers and 2x2 pooling layers. The stacking of small filters simulates a larger filter with fewer parameters.

#### ResNet (He 等人，2015)

> ResNet (He et al., 2015)

- 该网络确实非常深；152 层简单架构。
- **残差块**：某个层的某些输入可以传递到后面两层的组件。残差块对于保持深度网络可训练并最终工作至关重要。如果没有残差块，由于[梯度消失和梯度爆炸](http://www.wildml.com/2015/10/recurrent-neural-networks-tutorial-part-3-backpropagation-through-time-and-vanishing-gradients/)，普通网络的训练损失不会随着层数的增加而单调递减。

> • The network is indeed very deep; 152 layers of simple architecture.
> • **Residual Block**: Some input of a certain layer can be passed to the component two layers later. Residual blocks are essential for keeping a deep network trainable and eventually work. Without residual blocks, the training loss of a plain network does not monotonically decrease as the number of layers increases due to [vanishing and exploding gradients](http://www.wildml.com/2015/10/recurrent-neural-networks-tutorial-part-3-backpropagation-through-time-and-vanishing-gradients/).

![An illustration of the residual block of ResNet. In some way, we can say the design of residual blocks is inspired by V4 getting input directly from V1 in the human visual cortex system. (left image source: Wang et al., 2017 )](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/residual-block.png)

### 评估指标：mAP

> Evaluation Metrics: mAP

在许多目标识别和检测任务中常用的评估指标是“**mAP**”，是“**平均精度均值**”的缩写。它是一个介于 0 到 100 之间的数字；值越高越好。

> A common evaluation metric used in many object recognition and detection tasks is “**mAP**”, short for “**mean average precision**”. It is a number from 0 to 100; higher value is better.

- 结合所有测试图像中的所有检测结果，为每个类别绘制一条精确率-召回率曲线（PR 曲线）；“平均精度”（AP）是 PR 曲线下的面积。
- 鉴于目标对象属于不同的类别，我们首先为每个类别单独计算 AP，然后对所有类别取平均值。
- 如果检测结果与真实框的**“交并比”（IoU）**大于某个阈值（通常为 0.5；如果是，则该指标为“[mAP@0.5](mailto:mAP@0.5)”）则为真阳性。

> • Combine all detections from all test images to draw a precision-recall curve (PR curve) for each class; The “average precision” (AP) is the area under the PR curve.
> • Given that target objects are in different classes, we first compute AP separately for each class, and then average over classes.
> • A detection is a true positive if it has **“intersection over union” (IoU)** with a ground-truth box greater than some threshold (usually 0.5; if so, the metric is “[mAP@0.5](mailto:mAP@0.5)”)

### 可变形部件模型

> Deformable Parts Model

可变形部件模型 (DPM) ([Felzenszwalb 等人，2010](http://people.cs.uchicago.edu/~pff/papers/lsvm-pami.pdf)) 通过可变形部件的混合图模型（马尔可夫随机场）识别对象。该模型由三个主要组件组成：

> The Deformable Parts Model (DPM) ([Felzenszwalb et al., 2010](http://people.cs.uchicago.edu/~pff/papers/lsvm-pami.pdf)) recognizes objects with a mixture graphical model (Markov random fields) of deformable parts. The model consists of three major components:

1. 一个粗略的***根滤波器***定义了一个大致覆盖整个对象的检测窗口。滤波器为区域特征向量指定权重。
2. 多个***部件滤波器***覆盖对象的较小部分。部件滤波器以根滤波器两倍的分辨率学习。
3. 一个***空间模型***用于评估部件滤波器相对于根的位置。

> • A coarse ***root filter*** defines a detection window that approximately covers an entire object. A filter specifies weights for a region feature vector.
> • Multiple ***part filters*** that cover smaller parts of the object. Parts filters are learned at twice resolution of the root filter.
> • A ***spatial model*** for scoring the locations of part filters relative to the root.

![The DPM model contains (a) a root filter, (b) multiple part filters at twice the resolution, and (c) a model for scoring the location and deformation of parts.](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/DPM.png)

检测对象的质量通过滤波器的分数减去形变成本来衡量。匹配分数$f$，用通俗的话来说，是：

> The quality of detecting an object is measured by the score of filters minus the deformation costs. The matching score $f$, in laymen’s terms, is:

$$
f(\text{model}, x) = f(\beta_\text{root}, x) + \sum_{\beta_\text{part} \in \text{part filters}} \max_y [f(\beta_\text{part}, y) - \text{cost}(\beta_\text{part}, x, y)]
$$

其中，

> in which,

• $x$是具有指定位置和尺度的图像；

• $y$是$x$的子区域。

• $\beta_\text{root}$是根滤波器。

• $\beta_\text{part}$是一个部件滤波器。

• cost() 衡量部件偏离其相对于根的理想位置的惩罚。

英文原文：

• $x$ is an image with a specified position and scale;

• $y$ is a sub region of $x$.

• $\beta_\text{root}$ is the root filter.

• $\beta_\text{part}$ is one part filter.

• cost() measures the penalty of the part deviating from its ideal location relative to the root.

基本分数模型是滤波器$\beta$与区域特征向量$\Phi(x)$的点积：$f(\beta, x) = \beta \cdot \Phi(x)$。特征集$\Phi(x)$可以通过 HOG 或其他类似算法定义。

> The basic score model is the dot product between the filter $\beta$ and the region feature vector $\Phi(x)$: $f(\beta, x) = \beta \cdot \Phi(x)$. The feature set $\Phi(x)$ can be defined by HOG or other similar algorithms.

高分数的根位置检测到包含对象的可能性很高的区域，而高分数的部件位置则证实了已识别的对象假设。该论文采用隐式 SVM 来建模分类器。

> A root location with high score detects a region with high chances to contain an object, while the locations of the parts with high scores confirm a recognized object hypothesis. The paper adopted latent SVM to model the classifier.

![The matching process by DPM. (Image source: Felzenszwalb et al., 2010 )](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/DPM-matching.png)

作者后来声称 DPM 和 CNN 模型并非目标识别的两种不同方法。相反，DPM 模型可以通过展开 DPM 推理算法并将每个步骤映射到等效的 CNN 层来表述为 CNN。（详情请查阅[Girshick 等人，2015](https://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Girshick_Deformable_Part_Models_2015_CVPR_paper.pdf)！）

> The author later claimed that DPM and CNN models are not two distinct approaches to object recognition. Instead, a DPM model can be formulated as a CNN by unrolling the DPM inference algorithm and mapping each step to an equivalent CNN layer. (Check the details in [Girshick et al., 2015](https://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Girshick_Deformable_Part_Models_2015_CVPR_paper.pdf)!)

### Overfeat

> Overfeat

Overfeat [[论文](https://pdfs.semanticscholar.org/f2c2/fbc35d0541571f54790851de9fcd1adde085.pdf)][[代码](https://github.com/sermanet/OverFeat)] 是一个将目标检测、定位和分类任务全部集成到一个卷积神经网络中的开创性模型。其主要思想是 (i) 以滑动窗口的方式在图像多尺度区域的不同位置进行图像分类，以及 (ii) 使用在相同卷积层之上训练的回归器预测边界框位置。

> Overfeat [[paper](https://pdfs.semanticscholar.org/f2c2/fbc35d0541571f54790851de9fcd1adde085.pdf)][[code](https://github.com/sermanet/OverFeat)] is a pioneer model of integrating the object detection, localization and classification tasks all into one convolutional neural network. The main idea is to (i) do image classification at different locations on regions of multiple scales of the image in a sliding window fashion, and (ii) predict the bounding box locations with a regressor trained on top of the same convolution layers.

Overfeat 模型架构与[AlexNet](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#alexnet-krizhevsky-et-al-2012)非常相似。其训练方式如下：

> The Overfeat model architecture is very similar to [AlexNet](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/#alexnet-krizhevsky-et-al-2012). It is trained as follows:

![The training stages of the Overfeat model. (Image source: link )](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/overfeat-training.png)

1\. 在图像分类任务上训练一个 CNN 模型（类似于 AlexNet）。

2\. 然后，我们用一个回归网络替换顶部的分类器层，并训练它来预测每个空间位置和尺度的对象边界框。该回归器是类别特定的，每个回归器为一个图像类别生成。



• 输入：带有分类和边界框的图像。



• 输出：$(x_\text{left}, x_\text{right}, y_\text{top}, y_\text{bottom})$，总共 4 个值，表示边界框边缘的坐标。



• 损失：回归器被训练以最小化每个训练示例中生成的边界框与真实值之间的$l2$范数。

英文原文：

1\. Train a CNN model (similar to AlexNet) on the image classification task.

2\. Then, we replace the top classifier layers by a regression network and train it to predict object bounding boxes at each spatial location and scale. The regressor is class-specific, each generated for one image class.



• Input: Images with classification and bounding box.



• Output: $(x_\text{left}, x_\text{right}, y_\text{top}, y_\text{bottom})$, 4 values in total, representing the coordinates of the bounding box edges.



• Loss: The regressor is trained to minimize $l2$ norm between generated bounding box and the ground truth for each training example.

在检测时，

> At the detection time,

1. 使用预训练的 CNN 模型在每个位置执行分类。
2. 在分类器生成的所有已分类区域上预测对象边界框。
3. 合并来自定位的具有足够重叠的边界框，以及来自分类器的具有足够置信度为同一对象的边界框。

> • Perform classification at each location using the pretrained CNN model.
> • Predict object bounding boxes on all classified regions generated by the classifier.
> • Merge bounding boxes with sufficient overlap from localization and sufficient confidence of being the same object from the classifier.

引用为：

> Cited as:

```
@article{weng2017detection2,
  title   = "Object Detection for Dummies Part 2: CNN, DPM and Overfeat",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2017",
  url     = "https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/"
}
```

### 参考文献

> Reference

[1] Vincent Dumoulin 和 Francesco Visin。[“深度学习卷积运算指南。”](https://arxiv.org/pdf/1603.07285.pdf) arXiv 预印本 arXiv:1603.07285 (2016)。

> [1] Vincent Dumoulin and Francesco Visin. [“A guide to convolution arithmetic for deep learning.”](https://arxiv.org/pdf/1603.07285.pdf) arXiv preprint arXiv:1603.07285 (2016).

[2] Haohan Wang、Bhiksha Raj 和 Eric P. Xing。[“论深度学习的起源。”](https://arxiv.org/pdf/1702.07800.pdf) arXiv 预印本 arXiv:1702.07800 (2017)。

> [2] Haohan Wang, Bhiksha Raj, and Eric P. Xing. [“On the Origin of Deep Learning.”](https://arxiv.org/pdf/1702.07800.pdf) arXiv preprint arXiv:1702.07800 (2017).

[3] Pedro F. Felzenszwalb、Ross B. Girshick、David McAllester 和 Deva Ramanan。[“基于判别训练部件模型的对象检测。”](http://people.cs.uchicago.edu/~pff/papers/lsvm-pami.pdf) IEEE 模式分析与机器智能汇刊 32，第 9 期 (2010)：1627-1645。

> [3] Pedro F. Felzenszwalb, Ross B. Girshick, David McAllester, and Deva Ramanan. [“Object detection with discriminatively trained part-based models.”](http://people.cs.uchicago.edu/~pff/papers/lsvm-pami.pdf) IEEE transactions on pattern analysis and machine intelligence 32, no. 9 (2010): 1627-1645.

[4] Ross B. Girshick、Forrest Iandola、Trevor Darrell 和 Jitendra Malik。[“可变形部件模型是卷积神经网络。”](https://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Girshick_Deformable_Part_Models_2015_CVPR_paper.pdf) 载于 IEEE 计算机视觉与模式识别会议 (CVPR) 论文集，第 437-446 页。2015。

> [4] Ross B. Girshick, Forrest Iandola, Trevor Darrell, and Jitendra Malik. [“Deformable part models are convolutional neural networks.”](https://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Girshick_Deformable_Part_Models_2015_CVPR_paper.pdf) In Proc. IEEE Conf. on Computer Vision and Pattern Recognition (CVPR), pp. 437-446. 2015.

[5] Sermanet, Pierre, David Eigen, Xiang Zhang, Michaël Mathieu, Rob Fergus 和 Yann LeCun。[“OverFeat：使用卷积网络进行集成识别、定位和检测”](https://pdfs.semanticscholar.org/f2c2/fbc35d0541571f54790851de9fcd1adde085.pdf) arXiv 预印本 arXiv:1312.6229 (2013)。

> [5] Sermanet, Pierre, David Eigen, Xiang Zhang, Michaël Mathieu, Rob Fergus, and Yann LeCun. [“OverFeat: Integrated Recognition, Localization and Detection using Convolutional Networks”](https://pdfs.semanticscholar.org/f2c2/fbc35d0541571f54790851de9fcd1adde085.pdf) arXiv preprint arXiv:1312.6229 (2013).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Convolutional Neural Network (CNN) | 卷积神经网络 | 一种深度学习模型，通过卷积操作处理图像等网格状数据，广泛应用于计算机视觉任务。 |
| Kernel | 核 / 滤波器 | 卷积操作中的一个小矩阵，用于与输入特征图进行乘加运算以提取特征。 |
| Feature map | 特征图 | 卷积层输出的矩阵，表示输入数据经过特定滤波器处理后提取的特征。 |
| Residual block | 残差块 | ResNet中引入的结构，允许输入跳过若干层直接传递到更深层，以解决深度网络训练中的梯度问题。 |
| Mean Average Precision (mAP) | 平均精度均值 | 目标检测和识别任务中常用的评估指标，是所有类别平均精度的平均值。 |
| Intersection over Union (IoU) | 交并比 | 衡量预测边界框与真实边界框重叠程度的指标，是两者交集面积与并集面积之比。 |
| Deformable Part Models (DPM) | 可变形部件模型 | 一种通过可变形部件的混合图模型来识别对象的传统目标检测方法。 |
| Root filter | 根滤波器 | DPM中用于定义大致覆盖整个对象的检测窗口的粗略滤波器。 |
| Part filter | 部件滤波器 | DPM中用于覆盖对象较小部分的滤波器，通常以更高分辨率学习。 |
| Overfeat | Overfeat | 一个开创性的卷积神经网络模型，将目标检测、定位和分类集成到单一架构中。 |
| Sliding window | 滑动窗口 | 一种在图像上以固定步长和大小移动窗口，对每个窗口区域进行处理的技术。 |
| Bounding box | 边界框 | 在目标检测中用于框定图像中对象位置的矩形区域。 |
| Gradient vanishing / exploding | 梯度消失 / 梯度爆炸 | 深度神经网络训练中常见的梯度问题，导致网络难以学习或训练不稳定。 |
