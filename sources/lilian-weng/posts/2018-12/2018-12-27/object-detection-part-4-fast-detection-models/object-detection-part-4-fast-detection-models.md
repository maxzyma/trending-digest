# 目标检测第四部分：快速检测模型

> Object Detection Part 4: Fast Detection Models

> 来源：Lil'Log / Lilian Weng，2018-12-27
> 原文链接：https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/
> 分类：计算机视觉 / 目标检测

## 核心要点

- 本文回顾了SSD、RetinaNet和YOLO家族等快速目标检测模型，它们都属于单阶段检测器。
- 单阶段检测器跳过区域提议阶段，直接进行检测，相比两阶段检测器更快更简单，但可能略微降低性能。
- YOLO模型是首个尝试构建快速实时目标检测器的模型，通过将图像分割成网格单元并直接预测边界框和类别概率实现超快推理。
- SSD模型利用卷积神经网络的金字塔特征层次结构，在不同尺度的特征图上预测预定义的锚框偏移量，以有效检测各种尺寸的对象。
- YOLOv2通过批归一化、高分辨率微调、卷积锚框检测、K均值聚类生成锚框、直接位置预测、添加细粒度特征和多尺度训练等改进提升了性能。
- YOLO9000在YOLOv2基础上，结合COCO检测数据集和ImageNet前9000个类别进行联合训练，并利用WordNet构建分层树结构处理标签。
- RetinaNet是一种单阶段密集目标检测器，其核心创新是引入焦点损失来解决前景-背景类别极端不平衡问题，并使用特征金字塔网络构建多尺度特征表示。
- YOLOv3在YOLOv2的基础上，采用逻辑回归预测置信度分数、多个独立逻辑分类器进行类别预测、Darknet-53作为基础模型、多尺度预测和跳层连接等技术进一步优化。
- YOLOv3在性能上优于SSD且速度更快，但精度不如RetinaNet，不过速度快了3.8倍。

## 正文

在[第三部分](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)中，我们回顾了R-CNN家族的模型。它们都是基于区域的目标检测算法。它们可以实现高精度，但对于自动驾驶等某些应用来说可能太慢。在第四部分中，我们只关注快速目标检测模型，包括SSD、RetinaNet和YOLO家族的模型。

> In [Part 3](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/), we have reviewed models in the R-CNN family. All of them are region-based object detection algorithms. They can achieve high accuracy but could be too slow for certain applications such as autonomous driving. In Part 4, we only focus on fast object detection models, including SSD, RetinaNet, and models in the YOLO family.

本系列所有文章的链接：[[KEEP_NEWLINE]][[第一部分](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)][[KEEP_NEWLINE]][[第二部分](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)][[KEEP_NEWLINE]][[第三部分](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)][[KEEP_NEWLINE]][[第四部分](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)]。

> Links to all the posts in the series:
> [[Part 1](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)]
> [[Part 2](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)]
> [[Part 3](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)]
> [[Part 4](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)].

### 两阶段检测器与一阶段检测器

> Two-stage vs One-stage Detectors

R-CNN家族的模型都是基于区域的。检测分两个阶段进行：(1) 首先，模型通过选择性搜索或区域提议网络提出一组感兴趣区域。由于潜在的边界框候选是无限的，因此提议的区域是稀疏的。(2) 然后分类器只处理区域候选。

> Models in the R-CNN family are all region-based. The detection happens in two stages: (1) First, the model proposes a set of regions of interests by select search or regional proposal network. The proposed regions are sparse as the potential bounding box candidates can be infinite. (2) Then a classifier only processes the region candidates.

另一种不同的方法是跳过区域提议阶段，直接在可能的密集采样位置上运行检测。这就是一阶段目标检测算法的工作方式。这种方法更快、更简单，但可能会稍微降低性能。

> The other different approach skips the region proposal stage and runs detection directly over a dense sampling of possible locations. This is how a one-stage object detection algorithm works. This is faster and simpler, but might potentially drag down the performance a bit.

本文介绍的所有模型都是单阶段检测器。

> All the models introduced in this post are one-stage detectors.

### YOLO：你只看一次

> YOLO: You Only Look Once

**YOLO**模型（**“你只看一次”**；[Redmon 等人，2016](https://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/Redmon_You_Only_Look_CVPR_2016_paper.pdf)）是构建快速实时目标检测器的首次尝试。由于YOLO不经过区域提议步骤，并且只对有限数量的边界框进行预测，因此它能够以超快的速度进行推理。

> The **YOLO** model (**“You Only Look Once”**; [Redmon et al., 2016](https://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/Redmon_You_Only_Look_CVPR_2016_paper.pdf)) is the very first attempt at building a fast real-time object detector. Because YOLO does not undergo the region proposal step and only predicts over a limited number of bounding boxes, it is able to do inference super fast.

#### 工作流程

> Workflow

1\. 
**在图像分类任务上预训练**一个CNN网络。


2\. 
将图像分割成$S \times S$个单元格。如果一个物体的中心落入某个单元格，那么该单元格就“负责”检测该物体的存在。每个单元格预测 (a) $B$个边界框的位置，(b) 一个置信度分数，以及 (c) 在边界框中存在物体的情况下，物体类别的概率。



• 边界框的**坐标**由一个包含4个值的元组定义，即（中心x坐标，中心y坐标，宽度，高度）— $(x, y, w, h)$，其中$x$和$y$被设置为单元格位置的偏移量。此外，$x$、$y$、$w$和$h$通过图像的宽度和高度进行归一化，因此它们的值都在(0, 1]之间。



• **置信度分数**表示单元格包含对象的可能性：`Pr(containing an object) x IoU(pred, truth)`；其中`Pr` = 概率，`IoU` = 联合下的交集。



• 如果单元格包含一个对象，它会预测该对象属于每个类别的**概率**$C_i, i=1, \dots, K$：`Pr(the object belongs to the class C_i | containing an object)`。在此阶段，无论边界框的数量如何，模型每个单元格只预测一组类别概率，$B$。



• 总的来说，一张图像包含$S \times S \times B$个边界框，每个框对应4个位置预测、1个置信度分数和K个用于对象分类的条件概率。一张图像的总预测值为$S \times S \times (5B + K)$，这是模型最终卷积层的张量形状。

3\. 预训练CNN的最后一层被修改，以输出大小为$S \times S \times (5B + K)$的预测张量。

英文原文：

1\. 
**Pre-train** a CNN network on image classification task.


2\. 
Split an image into $S \times S$ cells. If an object’s center falls into a cell, that cell is “responsible” for detecting the existence of that object. Each cell predicts (a) the location of $B$ bounding boxes, (b) a confidence score, and (c) a probability of object class conditioned on the existence of an object in the bounding box.



• The **coordinates** of bounding box are defined by a tuple of 4 values, (center x-coord, center y-coord, width, height) — $(x, y, w, h)$, where $x$ and $y$ are set to be offset of a cell location. Moreover, $x$, $y$, $w$ and $h$ are normalized by the image width and height, and thus all between (0, 1].



• A **confidence score** indicates the likelihood that the cell contains an object: `Pr(containing an object) x IoU(pred, truth)`; where `Pr` = probability and `IoU` = interaction under union.



• If the cell contains an object, it predicts a **probability** of this object belonging to every class $C_i, i=1, \dots, K$: `Pr(the object belongs to the class C_i | containing an object)`. At this stage, the model only predicts one set of class probabilities per cell, regardless of the number of bounding boxes, $B$.



• In total, one image contains $S \times S \times B$ bounding boxes, each box corresponding to 4 location predictions, 1 confidence score, and K conditional probabilities for object classification. The total prediction values for one image is $S \times S \times (5B + K)$, which is the tensor shape of the final conv layer of the model.

3\. 
The final layer of the pre-trained CNN is modified to output a prediction tensor of size $S \times S \times (5B + K)$.


![The workflow of YOLO model. (Image source: original paper )](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/yolo.png)

#### 网络架构

> Network Architecture

基础模型类似于[GoogLeNet](https://www.cs.unc.edu/~wliu/papers/GoogLeNet.pdf)，其中Inception模块被1x1和3x3卷积层取代。形状为$S \times S \times (5B + K)$的最终预测由覆盖整个卷积特征图的两个全连接层生成。

> The base model is similar to [GoogLeNet](https://www.cs.unc.edu/~wliu/papers/GoogLeNet.pdf) with inception module replaced by 1x1 and 3x3 conv layers. The final prediction of shape $S \times S \times (5B + K)$ is produced by two fully connected layers over the whole conv feature map.

![The network architecture of YOLO.](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/yolo-network-architecture.png)

#### 损失函数

> Loss Function

损失由两部分组成：用于边界框偏移预测的*定位损失*和用于条件类别概率的*分类损失*。两部分都计算为平方误差之和。使用两个尺度参数来控制我们希望增加多少来自边界框坐标预测的损失（$\lambda_\text{coord}$），以及我们希望减少多少针对没有对象的框的置信度分数预测的损失（$\lambda_\text{noobj}$）。降低背景框造成的损失很重要，因为大多数边界框不包含实例。在论文中，模型设置了$\lambda_\text{coord} = 5$和$\lambda_\text{noobj} = 0.5$。

> The loss consists of two parts, the *localization loss* for bounding box offset prediction and the *classification loss* for conditional class probabilities. Both parts are computed as the sum of squared errors. Two scale parameters are used to control how much we want to increase the loss from bounding box coordinate predictions ($\lambda_\text{coord}$) and how much we want to decrease the loss of confidence score predictions for boxes without objects ($\lambda_\text{noobj}$). Down-weighting the loss contributed by background boxes is important as most of the bounding boxes involve no instance. In the paper, the model sets $\lambda_\text{coord} = 5$ and $\lambda_\text{noobj} = 0.5$.

$$
\begin{aligned}
\mathcal{L}_\text{loc} &= \lambda_\text{coord} \sum_{i=0}^{S^2} \sum_{j=0}^B \mathbb{1}_{ij}^\text{obj} [(x_i - \hat{x}_i)^2 + (y_i - \hat{y}_i)^2 + (\sqrt{w_i} - \sqrt{\hat{w}_i})^2 + (\sqrt{h_i} - \sqrt{\hat{h}_i})^2 ] \\
\mathcal{L}_\text{cls}  &= \sum_{i=0}^{S^2} \sum_{j=0}^B \big( \mathbb{1}_{ij}^\text{obj} + \lambda_\text{noobj} (1 - \mathbb{1}_{ij}^\text{obj})\big) (C_{ij} - \hat{C}_{ij})^2 + \sum_{i=0}^{S^2} \sum_{c \in \mathcal{C}} \mathbb{1}_i^\text{obj} (p_i(c) - \hat{p}_i(c))^2\\
\mathcal{L} &= \mathcal{L}_\text{loc} + \mathcal{L}_\text{cls}
\end{aligned}
$$

引用译文：

注意：在原始YOLO论文中，损失函数使用$C_i$而不是$C_{ij}$作为置信度分数。我根据自己的理解进行了修正，因为每个边界框都应该有自己的置信度分数。如果您不同意，请告诉我。非常感谢。

英文原文：

NOTE: In the original YOLO paper, the loss function uses $C_i$ instead of $C_{ij}$ as confidence score. I made the correction based on my own understanding, since every bounding box should have its own confidence score. Please kindly let me if you do not agree. Many thanks.

其中，

> where,

• $\mathbb{1}_i^\text{obj}$：一个指示函数，表示单元格i是否包含对象。

• $\mathbb{1}_{ij}^\text{obj}$：它指示单元格i的第j个边界框是否“负责”对象预测（参见图3）。

• $C_{ij}$: 单元格 i 的置信度分数，`Pr(containing an object) * IoU(pred, truth)`。

• $\hat{C}_{ij}$: 预测的置信度分数。

• $\mathcal{C}$: 所有类别的集合。

• $p_i(c)$: 单元格 i 是否包含 $c \in \mathcal{C}$ 类对象的条件概率。

• $\hat{p}_i(c)$: 预测的条件类别概率。

英文原文：

• $\mathbb{1}_i^\text{obj}$: An indicator function of whether the cell i contains an object.

• $\mathbb{1}_{ij}^\text{obj}$: It indicates whether the j-th bounding box of the cell i is “responsible” for the object prediction (see Fig. 3).

• $C_{ij}$: The confidence score of cell i, `Pr(containing an object) * IoU(pred, truth)`.

• $\hat{C}_{ij}$: The predicted confidence score.

• $\mathcal{C}$: The set of all classes.

• $p_i(c)$: The conditional probability of whether cell i contains an object of class $c \in \mathcal{C}$.

• $\hat{p}_i(c)$: The predicted conditional class probability.

![At one location, in cell i, the model proposes B bounding box candidates and the one that has highest overlap with the ground truth is the "responsible" predictor.](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/yolo-responsible-predictor.png)

损失函数仅在网格单元中存在对象时才惩罚分类错误，$\mathbb{1}_i^\text{obj} = 1$。它也仅在该预测器“负责”真实边界框时才惩罚边界框坐标错误，$\mathbb{1}_{ij}^\text{obj} = 1$。

> The loss function only penalizes classification error if an object is present in that grid cell, $\mathbb{1}_i^\text{obj} = 1$. It also only penalizes bounding box coordinate error if that predictor is “responsible” for the ground truth box, $\mathbb{1}_{ij}^\text{obj} = 1$.

作为一种单阶段目标检测器，YOLO 速度超快，但由于边界框候选数量有限，它不擅长识别不规则形状的对象或一组小对象。

> As a one-stage object detector, YOLO is super fast, but it is not good at recognizing irregularly shaped objects or a group of small objects due to a limited number of bounding box candidates.

### SSD：单次多盒检测器

> SSD: Single Shot MultiBox Detector

**单次检测器**（**SSD**；[Liu et al, 2016](https://arxiv.org/abs/1512.02325)）是首次尝试使用卷积神经网络的金字塔特征层次结构来有效检测各种尺寸对象的方法之一。

> The **Single Shot Detector** (**SSD**; [Liu et al, 2016](https://arxiv.org/abs/1512.02325)) is one of the first attempts at using convolutional neural network’s pyramidal feature hierarchy for efficient detection of objects of various sizes.

#### 图像金字塔

> Image Pyramid

SSD 使用在 ImageNet 上预训练的 [VGG-16](https://arxiv.org/abs/1409.1556) 模型作为其基础模型，用于提取有用的图像特征。\n在 VGG16 之上，SSD 添加了几个尺寸递减的卷积特征层。它们可以被视为不同尺度图像的*金字塔表示*。直观地说，早期层的大型细粒度特征图擅长捕获小对象，而小型粗粒度特征图可以很好地检测大对象。在 SSD 中，检测发生在每个金字塔层，针对各种尺寸的对象。

> SSD uses the [VGG-16](https://arxiv.org/abs/1409.1556) model pre-trained on ImageNet as its base model for extracting useful image features.
> On top of VGG16, SSD adds several conv feature layers of decreasing sizes. They can be seen as a *pyramid representation* of images at different scales. Intuitively large fine-grained feature maps at earlier levels are good at capturing small objects and small coarse-grained feature maps can detect large objects well. In SSD, the detection happens in every pyramidal layer, targeting at objects of various sizes.

![The model architecture of SSD.](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/SSD-architecture.png)

#### 工作流程

> Workflow

与YOLO不同，SSD不将图像分割成任意大小的网格，而是预测预定义的*锚框*（在论文中这被称为“默认框”）的偏移量，针对特征图的每个位置。每个框都有相对于其对应单元格的固定尺寸和位置。所有锚框以卷积方式平铺整个特征图。

> Unlike YOLO, SSD does not split the image into grids of arbitrary size but predicts offset of predefined *anchor boxes* (this is called “default boxes” in the paper) for every location of the feature map. Each box has a fixed size and position relative to its corresponding cell. All the anchor boxes tile the whole feature map in a convolutional manner.

不同层级的特征图具有不同的感受野大小。不同层级的锚框被重新缩放，使得一个特征图只负责特定尺度的物体。例如，在图 5 中，狗只能在 4x4 特征图（更高层级）中被检测到，而猫则仅由 8x8 特征图（更低层级）捕获。

> Feature maps at different levels have different receptive field sizes. The anchor boxes on different levels are rescaled so that one feature map is only responsible for objects at one particular scale. For example, in Fig. 5 the dog can only be detected in the 4x4 feature map (higher level) while the cat is just captured by the 8x8 feature map (lower level).

![The SSD framework. (a) The training data contains images and ground truth boxes for every object. (b) In a fine-grained feature maps (8 x 8), the anchor boxes of different aspect ratios correspond to smaller area of the raw input. (c) In a coarse-grained feature map (4 x 4), the anchor boxes cover larger area of the raw input. (Image source: original paper )](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/SSD-framework.png)

锚框的宽度、高度和中心位置都被归一化到 (0, 1) 之间。在某个位置$(i, j)$的$\ell$特征层，其大小为$m \times n$，$i=1,\dots,n, j=1,\dots,m$，我们有一个与层级成比例的独特线性尺度，以及 5 种不同的框长宽比（宽度与高度之比），此外，当长宽比为 1 时，还有一个特殊的尺度（为什么需要这个？论文没有解释。也许只是一个启发式技巧）。这使得每个特征单元总共有 6 个锚框。

> The width, height and the center location of an anchor box are all normalized to be (0, 1). At a location $(i, j)$ of the $\ell$ -th feature layer of size $m \times n$, $i=1,\dots,n, j=1,\dots,m$, we have a unique linear scale proportional to the layer level and 5 different box aspect ratios (width-to-height ratios), in addition to a special scale (why we need this? the paper didn’t explain. maybe just a heuristic trick) when the aspect ratio is 1. This gives us 6 anchor boxes in total per feature cell.

$$
\begin{aligned}
\text{level index: } &\ell = 1, \dots, L \\
\text{scale of boxes: } &s_\ell = s_\text{min} + \frac{s_\text{max} - s_\text{min}}{L - 1} (\ell - 1) \\
\text{aspect ratio: } &r \in \{1, 2, 3, 1/2, 1/3\}\\
\text{additional scale: } & s'_\ell = \sqrt{s_\ell s_{\ell + 1}} \text{ when } r = 1 \text{thus, 6 boxes in total.}\\
\text{width: } &w_\ell^r = s_\ell \sqrt{r} \\
\text{height: } &h_\ell^r = s_\ell / \sqrt{r} \\
\text{center location: } & (x^i_\ell, y^j_\ell) = (\frac{i+0.5}{m}, \frac{j+0.5}{n})
\end{aligned}
$$

![An example of how the anchor box size is scaled up with the layer index $\ell$ for $L=6, s\_\text{min} = 0.2, s\_\text{max} = 0.9$. Only the boxes of aspect ratio $r=1$ are illustrated.](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/SSD-box-scales.png)

在每个位置，模型输出4个偏移量和$c$个类别概率，通过应用一个$3 \times 3 \times p$卷积滤波器（其中$p$是特征图中的通道数），对于$k$个锚框中的每一个。因此，给定一个大小为$m \times n$的特征图，我们需要$kmn(c+4)$个预测滤波器。

> At every location, the model outputs 4 offsets and $c$ class probabilities by applying a $3 \times 3 \times p$ conv filter (where $p$ is the number of channels in the feature map) for every one of $k$ anchor boxes. Therefore, given a feature map of size $m \times n$, we need $kmn(c+4)$ prediction filters.

#### 损失函数

> Loss Function

与 YOLO 相同，损失函数是定位损失和分类损失的总和。

> Same as YOLO, the loss function is the sum of a localization loss and a classification loss.

$\mathcal{L} = \frac{1}{N}(\mathcal{L}_\text{cls} + \alpha \mathcal{L}_\text{loc})$

> $\mathcal{L} = \frac{1}{N}(\mathcal{L}_\text{cls} + \alpha \mathcal{L}_\text{loc})$

其中 $N$ 是匹配边界框的数量，$\alpha$ 平衡了两种损失之间的权重，通过交叉验证选择。

> where $N$ is the number of matched bounding boxes and $\alpha$ balances the weights between two losses, picked by cross validation.

*定位损失*是预测边界框校正与真实值之间的[平滑L1损失](https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf)。坐标校正变换与[R-CNN](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#r-cnn)在[边界框回归](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression)中所做的相同。

> The *localization loss* is a [smooth L1 loss](https://github.com/rbgirshick/py-faster-rcnn/files/764206/SmoothL1Loss.1.pdf) between the predicted bounding box correction and the true values. The coordinate correction transformation is same as what [R-CNN](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#r-cnn) does in [bounding box regression](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression).

$$
\begin{aligned}
\mathcal{L}_\text{loc} &= \sum_{i,j} \sum_{m\in\{x, y, w, h\}} \mathbb{1}_{ij}^\text{match}
 L_1^\text{smooth}(d_m^i - t_m^j)^2\\
L_1^\text{smooth}(x) &= \begin{cases}
    0.5 x^2             & \text{if } \vert x \vert < 1\\
    \vert x \vert - 0.5 & \text{otherwise}
\end{cases} \\
t^j_x &= (g^j_x - p^i_x) / p^i_w \\
t^j_y &= (g^j_y - p^i_y) / p^i_h \\
t^j_w &= \log(g^j_w / p^i_w) \\
t^j_h &= \log(g^j_h / p^i_h)
\end{aligned}
$$

其中 $\mathbb{1}_{ij}^\text{match}$ 表示第 $i$ 个边界框（坐标为 $(p^i_x, p^i_y, p^i_w, p^i_h)$）是否与第 $j$ 个真实框（坐标为 $(g^j_x, g^j_y, g^j_w, g^j_h)$）匹配，针对任何对象。$d^i_m, m\in\{x, y, w, h\}$ 是预测的校正项。有关转换如何工作，请参阅 [此处](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression)。

> where $\mathbb{1}_{ij}^\text{match}$ indicates whether the $i$ -th bounding box with coordinates $(p^i_x, p^i_y, p^i_w, p^i_h)$ is matched to the $j$ -th ground truth box with coordinates $(g^j_x, g^j_y, g^j_w, g^j_h)$ for any object. $d^i_m, m\in\{x, y, w, h\}$ are the predicted correction terms. See [this](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#bounding-box-regression) for how the transformation works.

*分类损失* 是多类别上的 softmax 损失（在 tensorflow 中为 [softmax_cross_entropy_with_logits](https://www.tensorflow.org/api_docs/python/tf/nn/softmax_cross_entropy_with_logits)）：

> The *classification loss* is a softmax loss over multiple classes ([softmax_cross_entropy_with_logits](https://www.tensorflow.org/api_docs/python/tf/nn/softmax_cross_entropy_with_logits) in tensorflow):

$$
\mathcal{L}_\text{cls} = -\sum_{i \in \text{pos}} \mathbb{1}_{ij}^k \log(\hat{c}_i^k) - \sum_{i \in \text{neg}} \log(\hat{c}_i^0)\text{, where }\hat{c}_i^k = \text{softmax}(c_i^k)
$$

其中 $\mathbb{1}_{ij}^k$ 表示第 $i$ 个边界框和第 $j$ 个真实框是否与类别 $k$ 中的一个对象匹配。$\text{pos}$ 是匹配的边界框集合（总共有 $N$ 项），$\text{neg}$ 是负样本集合。SSD 使用 [难例挖掘](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#common-tricks) 来选择容易被错误分类的负样本，以构建这个 $\text{neg}$ 集合：一旦所有锚框按目标置信度分数排序，模型会选择排名靠前的候选框进行训练，以使负样本与正样本的比例至多为 3:1。

> where $\mathbb{1}_{ij}^k$ indicates whether the $i$ -th bounding box and the $j$ -th ground truth box are matched for an object in class $k$. $\text{pos}$ is the set of matched bounding boxes ($N$ items in total) and  $\text{neg}$ is the set of negative examples. SSD uses [hard negative mining](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/#common-tricks) to select easily misclassified negative examples to construct this $\text{neg}$ set: Once all the anchor boxes are sorted by objectiveness confidence score, the model picks the top candidates for training so that neg:pos is at most 3:1.

### YOLOv2 / YOLO9000

> YOLOv2 / YOLO9000

**YOLOv2** ([Redmon & Farhadi, 2017](https://arxiv.org/abs/1612.08242)) 是 YOLO 的增强版本。**YOLO9000** 建立在 YOLOv2 的基础上，但使用结合了 COCO 检测数据集和 ImageNet 中前 9000 个类别的联合数据集进行训练。

> **YOLOv2** ([Redmon & Farhadi, 2017](https://arxiv.org/abs/1612.08242)) is an enhanced version of YOLO. **YOLO9000** is built on top of YOLOv2 but trained with joint dataset combining the COCO detection dataset and the top 9000 classes from ImageNet.

#### YOLOv2 改进

> YOLOv2 Improvement

应用了多种修改，使 YOLO 预测更准确、更快，包括：

> A variety of modifications are applied to make YOLO prediction more accurate and faster, including:

**1. 批归一化有帮助**：将*批归一化*添加到所有卷积层，显著改善了收敛性。

> **1. BatchNorm helps**: Add *batch norm* on all the convolutional layers, leading to significant improvement over convergence.

**2. 图像分辨率很重要**：使用*高分辨率*图像对基础模型进行微调，可以提高检测性能。

> **2. Image resolution matters**: Fine-tuning the base model with *high resolution* images improves the detection performance.

**3. 卷积锚框检测**：YOLOv2 没有使用全连接层在整个特征图上预测边界框位置，而是使用*卷积层*来预测*锚框*的位置，类似于 Faster R-CNN。空间位置和类别概率的预测是解耦的。总的来说，这一改变导致 mAP 略有下降，但召回率有所提高。

> **3. Convolutional anchor box detection**: Rather than predicts the bounding box position with fully-connected layers over the whole feature map, YOLOv2 uses *convolutional layers* to predict locations of *anchor boxes*, like in faster R-CNN. The prediction of spatial locations and class probabilities are decoupled. Overall, the change leads to a slight decrease in mAP, but an increase in recall.

**4. 边界框尺寸的 K 均值聚类**: 不同于 Faster R-CNN 使用手动选择的锚框尺寸，YOLOv2 在训练数据上运行 K 均值聚类，以找到锚框尺寸的良好先验。距离度量旨在*依赖于 IoU 分数*:

> **4. K-mean clustering of box dimensions**: Different from faster R-CNN that uses hand-picked sizes of anchor boxes, YOLOv2 runs k-mean clustering on the training data to find good priors on anchor box dimensions. The distance metric is designed to *rely on IoU scores*:

$$
\text{dist}(x, c_i) = 1 - \text{IoU}(x, c_i), i=1,\dots,k
$$

其中 $x$ 是一个真实框候选，$c_i$ 是其中一个质心。最佳质心数量（锚框）$k$ 可以通过 [肘部法则](https://en.wikipedia.org/wiki/Elbow_method_(clustering)) 选择。

> where $x$ is a ground truth box candidate and $c_i$ is one of the centroids. The best number of centroids (anchor boxes) $k$ can be chosen by the [elbow method](https://en.wikipedia.org/wiki/Elbow_method_(clustering)).

通过聚类生成的锚框在固定数量的框的条件下提供了更好的平均 IoU。

> The anchor boxes generated by clustering provide better average IoU conditioned on a fixed number of boxes.

**5. 直接位置预测**: YOLOv2 以一种方式制定了边界框预测，使其*不会偏离*中心位置太远。如果边界框位置预测可以将框放置在图像的任何部分，就像在区域提议网络中那样，模型训练可能会变得不稳定。

> **5. Direct location prediction**: YOLOv2 formulates the bounding box prediction in a way that it would *not diverge* from the center location too much. If the box location prediction can place the box in any part of the image, like in regional proposal network, the model training could become unstable.

给定大小为$(p_w, p_h)$的锚框，位于网格单元格，其左上角在$(c_x, c_y)$，模型预测偏移量和尺度，$(t_x, t_y, t_w, t_h)$，以及相应的预测边界框$b$的中心点为$(b_x, b_y)$，大小为$(b_w, b_h)$。置信度分数是sigmoid函数（$\sigma$）的另一个输出$t_o$。

> Given the anchor box of size $(p_w, p_h)$ at the grid cell with its top left corner at $(c_x, c_y)$, the model predicts the offset and the scale, $(t_x, t_y, t_w, t_h)$ and the corresponding predicted bounding box $b$ has center $(b_x, b_y)$ and size $(b_w, b_h)$. The confidence score is the sigmoid ($\sigma$) of another output $t_o$.

$$
\begin{aligned}
b_x &= \sigma(t_x) + c_x\\
b_y &= \sigma(t_y) + c_y\\
b_w &= p_w e^{t_w}\\
b_h &= p_h e^{t_h}\\
\text{Pr}(\text{object}) &\cdot \text{IoU}(b, \text{object}) = \sigma(t_o)
\end{aligned}
$$

![YOLOv2 bounding box location prediction. (Image source: original paper )](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/yolov2-loc-prediction.png)

**6. 添加细粒度特征**: YOLOv2 添加了一个直通层，用于将*细粒度特征*从较早的层带到最终输出层。这个直通层的机制类似于*ResNet 中的恒等映射*，以从前一层提取更高维度的特征。这使得性能提高了 1%。

> **6. Add fine-grained features**: YOLOv2 adds a passthrough layer to bring *fine-grained features* from an earlier layer to the last output layer. The mechanism of this passthrough layer is similar to *identity mappings in ResNet* to extract higher-dimensional features from previous layers. This leads to 1% performance increase.

**7. 多尺度训练**: 为了训练模型使其对不同尺寸的输入图像具有鲁棒性，每10个批次，输入维度的一个*新尺寸*会被*随机采样*。由于YOLOv2的卷积层将输入维度下采样32倍，因此新采样的尺寸是32的倍数。

> **7. Multi-scale training**: In order to train the model to be robust to input images of different sizes, a *new size* of input dimension is *randomly sampled* every 10 batches. Since conv layers of YOLOv2 downsample the input dimension by a factor of 32, the newly sampled size is a multiple of 32.

**8. 轻量级基础模型**: 为了使预测更快，YOLOv2采用了轻量级基础模型DarkNet-19，它有19个卷积层和5个最大池化层。关键是在3x3卷积层之间插入平均池化层和1x1卷积核。

> **8. Light-weighted base model**: To make prediction even faster, YOLOv2 adopts a light-weighted base model, DarkNet-19, which has 19 conv layers and 5 max-pooling layers. The key point is to insert avg poolings and 1x1 conv filters between 3x3 conv layers.

#### YOLO9000: 丰富数据集训练

> YOLO9000: Rich Dataset Training

因为在图像上绘制用于目标检测的边界框比为图像进行分类标记要昂贵得多，所以该论文提出了一种将小型目标检测数据集与大型ImageNet结合的方法，以便模型能够接触到更多数量的目标类别。YOLO9000这个名字来源于ImageNet中排名前9000的类别。在联合训练期间，如果输入图像来自分类数据集，它只会反向传播分类损失。

> Because drawing bounding boxes on images for object detection is much more expensive than tagging images for classification, the paper proposed a way to combine small object detection dataset with large ImageNet so that the model can be exposed to a much larger number of object categories. The name of YOLO9000 comes from the top 9000 classes in ImageNet. During joint training, if an input image comes from the classification dataset, it only backpropagates the classification loss.

检测数据集的标签数量少得多，且更通用，此外，跨多个数据集的标签通常不是互斥的。例如，ImageNet 有一个标签“波斯猫”，而在 COCO 中，同一张图片会被标记为“猫”。如果没有互斥性，对所有类别应用 softmax 就没有意义。

> The detection dataset has much fewer and more general labels and, moreover, labels cross multiple datasets are often not mutually exclusive. For example, ImageNet has a label “Persian cat” while in COCO the same image would be labeled as “cat”. Without mutual exclusiveness, it does not make sense to apply softmax over all the classes.

为了有效地将 ImageNet 标签（1000 个类别，细粒度）与 COCO/PASCAL（< 100 个类别，粗粒度）合并，YOLO9000 参考 [WordNet](https://wordnet.princeton.edu/) 构建了一个分层树结构，使得通用标签更接近根节点，而细粒度类别标签是叶子节点。通过这种方式，“猫”是“波斯猫”的父节点。

> In order to efficiently merge ImageNet labels (1000 classes, fine-grained) with COCO/PASCAL (< 100 classes, coarse-grained), YOLO9000 built a hierarchical tree structure with reference to [WordNet](https://wordnet.princeton.edu/) so that general labels are closer to the root and the fine-grained class labels are leaves. In this way, “cat” is the parent node of “Persian cat”.

![The WordTree hierarchy merges labels from COCO and ImageNet. Blue nodes are COCO labels and red nodes are ImageNet labels. (Image source: original paper )](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/word-tree.png)

为了预测一个类别节点的概率，我们可以沿着从该节点到根节点的路径进行：

> To predict the probability of a class node, we can follow the path from the node to the root:

```
Pr("persian cat" | contain a "physical object") 
= Pr("persian cat" | "cat") 
  Pr("cat" | "animal") 
  Pr("animal" | "physical object") 
  Pr(contain a "physical object")    # confidence score.
```

请注意，`Pr(contain a "physical object")` 是置信度分数，在边界框检测管道中单独预测。条件概率预测的路径可以在任何步骤停止，具体取决于哪些标签可用。

> Note that `Pr(contain a "physical object")` is the confidence score, predicted separately in the bounding box detection pipeline. The path of conditional probability prediction can stop at any step, depending on which labels are available.

### RetinaNet

> RetinaNet

**RetinaNet**（[Lin 等人，2018](https://arxiv.org/abs/1708.02002)）是一种单阶段密集目标检测器。两个关键的构建块是*特征化图像金字塔*和*焦点损失*的使用。

> The **RetinaNet** ([Lin et al., 2018](https://arxiv.org/abs/1708.02002)) is a one-stage dense object detector. Two crucial building blocks are *featurized image pyramid* and the use of *focal loss*.

#### 焦点损失

> Focal Loss

目标检测模型训练的一个问题是，不包含目标的背景与包含感兴趣目标的前景之间存在极端不平衡。**焦点损失**旨在为难以分类、容易误分类的样本（即具有噪声纹理的背景或部分目标）分配更高的权重，并降低简单样本（即明显为空的背景）的权重。

> One issue for object detection model training is an extreme imbalance between background that contains no object and foreground that holds objects of interests. **Focal loss** is designed to assign more weights on hard, easily misclassified examples (i.e. background with noisy texture or partial object) and to down-weight easy examples (i.e. obviously empty background).

从二元分类的普通交叉熵损失开始，

> Starting with a normal cross entropy loss for binary classification,

$$
\text{CE}(p, y) = -y\log p - (1-y)\log(1-p)
$$

其中 $y \in \{0, 1\}$ 是一个真实二元标签，表示边界框是否包含一个对象，而 $p \in [0, 1]$ 是对象性的预测概率（又称置信度分数）。

> where $y \in \{0, 1\}$ is a ground truth binary label, indicating whether a bounding box contains a object, and $p \in [0, 1]$ is the predicted probability of objectiveness (aka confidence score).

为方便起见，

> For notational convenience,

$$
\text{let } p_t = \begin{cases}
p    & \text{if } y = 1\\
1-p  & \text{otherwise}
\end{cases},
\text{then } \text{CE}(p, y)=\text{CE}(p_t) = -\log p_t
$$

容易分类的例子，当 $p_t \gg 0.5$ 很大时，即当 $p$ 非常接近 0（当 y=0 时）或 1（当 y=1 时），可能会产生非平凡大小的损失。Focal loss 明确地为交叉熵中的每一项添加了一个加权因子 $(1-p_t)^\gamma, \gamma \geq 0$，使得当 $p_t$ 很大时权重很小，从而降低了容易分类的例子的权重。

> Easily classified examples with large $p_t \gg 0.5$, that is, when $p$ is very close to 0 (when y=0) or 1 (when y=1), can incur a loss with non-trivial magnitude. Focal loss explicitly adds a weighting factor $(1-p_t)^\gamma, \gamma \geq 0$ to each term in cross entropy so that the weight is small when $p_t$ is large and therefore easy examples are down-weighted.

$$
\text{FL}(p_t) = -(1-p_t)^\gamma \log p_t
$$

![The focal loss focuses less on easy examples with a factor of $(1-p\_t)^\gamma$. (Image source: original paper )](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/focal-loss.png)

为了更好地控制加权函数的形状（参见图 10.），RetinaNet 使用了 focal loss 的 $\alpha$ 平衡变体，其中 $\alpha=0.25, \gamma=2$ 效果最好。

> For a better control of the shape of the weighting function (see Fig. 10.), RetinaNet uses an $\alpha$ -balanced variant of the focal loss, where $\alpha=0.25, \gamma=2$ works the best.

$$
\text{FL}(p_t) = -\alpha (1-p_t)^\gamma \log p_t
$$

![The plot of focal loss weights $\alpha (1-p\_t)^\gamma$ as a function of $p\_t$, given different values of $\alpha$ and $\gamma$.](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/focal-loss-weights.png)

#### 特征化图像金字塔

> Featurized Image Pyramid

 **特征化图像金字塔** （[Lin 等人，2017](https://arxiv.org/abs/1612.03144)）是 RetinaNet 的骨干网络。遵循 SSD 中 [图像金字塔](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/#image-pyramid) 的相同方法，特征化图像金字塔为不同尺度的目标检测提供了基本的视觉组件。

> The **featurized image pyramid** ([Lin et al., 2017](https://arxiv.org/abs/1612.03144)) is the backbone network for RetinaNet. Following the same approach by [image pyramid](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/#image-pyramid) in SSD, featurized image pyramids provide a basic vision component for object detection at different scales.

特征金字塔网络的核心思想体现在其基本结构中，该结构包含一系列 *金字塔层级*，每个层级对应一个网络 *阶段*。一个阶段包含多个相同大小的卷积层，并且阶段大小按 2 的因子缩小。我们将第 $i$ 个阶段的最后一层表示为 $C_i$。

> The key idea of feature pyramid network is demonstrated in The base structure contains a sequence of *pyramid levels*, each corresponding to one network *stage*. One stage contains multiple convolutional layers of the same size and the stage sizes are scaled down by a factor of 2. Let’s denote the last layer of the $i$ -th stage as $C_i$.

![The illustration of the featurized image pyramid module. (Replot based on figure 3 in FPN paper )](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/featurized-image-pyramid.png)

两条路径连接卷积层：

> Two pathways connect conv layers:

• **自下而上路径** 是正常的正向计算。

• **自上而下路径** 沿相反方向进行，通过横向连接将粗糙但语义更强的特征图添加回前一个更大尺寸的金字塔层级。



• 首先，高层特征被空间上粗略地向上采样，使其尺寸增大 2 倍。对于图像上采样，该论文使用了最近邻上采样。虽然有许多 [图像上采样算法](https://en.wikipedia.org/wiki/Image_scaling#Algorithms)，例如使用 [反卷积](https://www.tensorflow.org/api_docs/python/tf/layers/conv2d_transpose)，但采用另一种图像缩放方法可能不会改善 RetinaNet 的性能。



• 更大的特征图经过一个 1x1 卷积层以减少通道维度。



• 最后，这两个特征图通过逐元素相加进行合并。

  



  



横向连接只发生在阶段的最后一层，表示为 $\{C_i\}$，并且该过程持续进行，直到生成最精细（最大）的合并特征图。预测是在每个合并图经过一个 3x3 卷积层 $\{P_i\}$ 之后进行的。

英文原文：

• **Bottom-up pathway** is the normal feedforward computation.

• **Top-down pathway** goes in the inverse direction, adding coarse but semantically stronger feature maps back into the previous pyramid levels of a larger size via lateral connections.



• First, the higher-level features are upsampled spatially coarser to be 2x larger. For image upscaling, the paper used nearest neighbor upsampling. While there are many [image upscaling algorithms](https://en.wikipedia.org/wiki/Image_scaling#Algorithms) such as using [deconv](https://www.tensorflow.org/api_docs/python/tf/layers/conv2d_transpose), adopting another image scaling method might or might not improve the performance of RetinaNet.



• The larger feature map undergoes a 1x1 conv layer to reduce the channel dimension.



• Finally, these two feature maps are merged by element-wise addition.

  



  



The lateral connections only happen at the last layer in stages, denoted as $\{C_i\}$, and the process continues until the finest (largest) merged feature map is generated. The prediction is made out of every merged map after a 3x3 conv layer, $\{P_i\}$.

根据消融研究，特征化图像金字塔设计的组件重要性排序如下：**1x1 横向连接** > 跨多层检测对象 > 自上而下丰富 > 金字塔表示（与仅检查最精细层相比）。

> According to ablation studies, the importance rank of components of the featurized image pyramid design is as follows: **1x1 lateral connection** > detect object across multiple layers  > top-down enrichment > pyramid representation (compared to only check the finest layer).

#### 模型架构

> Model Architecture

特征化金字塔构建在 ResNet 架构之上。回想一下，[ResNet](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/TBA) 有 5 个卷积块（= 网络阶段 / 金字塔层级）。第 $i$ 个金字塔层级的最后一层 $C_i$ 的分辨率比原始输入维度低 $2^i$。

> The featurized pyramid is constructed on top of the ResNet architecture. Recall that [ResNet](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/TBA) has 5 conv blocks (= network stages / pyramid levels). The last layer of the $i$ -th pyramid level, $C_i$, has resolution $2^i$ lower than the raw input dimension.

RetinaNet 利用特征金字塔层级 $P_3$ 到 $P_7$：

> RetinaNet utilizes feature pyramid levels $P_3$ to $P_7$:

• $P_3$ 到 $P_5$ 是从 $C_3$ 到 $C_5$ 对应的 ResNet 残差阶段计算得出的。它们通过自上而下和自下而上两条路径连接。

• $P_6$ 是通过在 $C_5$ 之上进行 3×3 步长为 2 的卷积获得的

• $P_7$ 在 $P_6$ 上应用 ReLU 和一个 3×3 步长为 2 的卷积。

英文原文：

• $P_3$ to $P_5$ are computed from the corresponding ResNet residual stage from $C_3$ to $C_5$. They are connected by both top-down and bottom-up pathways.

• $P_6$ is obtained via a 3×3 stride-2 conv on top of $C_5$

• $P_7$ applies ReLU and a 3×3 stride-2 conv on $P_6$.

在 ResNet 上添加更高的金字塔层级可以提高检测大型对象的性能。

> Adding higher pyramid levels on ResNet improves the performance for detecting large objects.

与 SSD 中一样，检测发生在所有金字塔层级，通过对每个合并的特征图进行预测。由于预测共享相同的分类器和边界框回归器，它们都被形成为具有相同的通道维度 d=256。

> Same as in SSD, detection happens in all pyramid levels by making a prediction out of every merged feature map. Because predictions share the same classifier and the box regressor, they are all formed to have the same channel dimension d=256.

每个层级有 A=9 个锚框：

> There are A=9 anchor boxes per level:

• 基本尺寸对应于$32^2$到$512^2$像素的区域，分别在$P_3$到$P_7$上。有三种尺寸比例，$\{2^0, 2^{1/3}, 2^{2/3}\}$。

• 对于每种尺寸，有三种长宽比 {1/2, 1, 2}。

英文原文：

• The base size corresponds to areas of $32^2$ to $512^2$ pixels on $P_3$ to $P_7$ respectively. There are three size ratios, $\{2^0, 2^{1/3}, 2^{2/3}\}$.

• For each size, there are three aspect ratios {1/2, 1, 2}.

像往常一样，对于每个锚框，模型在分类子网中为 $K$ 个类别中的每个类别输出一个类别概率，并在框回归子网中回归从该锚框到最近的真实目标之间的偏移量。分类子网采用上面介绍的焦点损失。

> As usual, for each anchor box, the model outputs a class probability for each of $K$ classes in the classification subnet and regresses the offset from this anchor box to the nearest ground truth object in the box regression subnet. The classification subnet adopts the focal loss introduced above.

![The RetinaNet model architecture uses a FPN backbone on top of ResNet. (Image source: the FPN paper)](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/retina-net.png)

### YOLOv3

> YOLOv3

[YOLOv3](https://pjreddie.com/media/files/papers/YOLOv3.pdf) 是通过在 YOLOv2 上应用一系列设计技巧创建的。这些改变受到了目标检测领域最新进展的启发。

> [YOLOv3](https://pjreddie.com/media/files/papers/YOLOv3.pdf) is created by applying a bunch of design tricks on YOLOv2. The changes are inspired by recent advances in the object detection world.

以下是更改列表：

> Here are a list of changes:

**1. 置信度分数的逻辑回归**: YOLOv3 为每个边界框预测一个置信度分数，使用*逻辑回归*，而 YOLO 和 YOLOv2 使用平方误差和作为分类项（参见[损失函数](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/#loss-function)以上）。偏移预测的线性回归导致 mAP 下降。

> **1. Logistic regression for confidence scores**: YOLOv3 predicts an confidence score for each bounding box using *logistic regression*, while YOLO and YOLOv2 uses sum of squared errors for classification terms (see the [loss function](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/#loss-function) above). Linear regression of offset prediction leads to a decrease in mAP.

**2. 不再使用 Softmax 进行类别预测**: 在预测类别置信度时，YOLOv3 为每个类别使用*多个独立的逻辑分类器*，而不是一个 softmax 层。这非常有用，特别是考虑到一张图像可能具有多个标签，并且并非所有标签都保证是互斥的。

> **2. No more softmax for class prediction**: When predicting class confidence, YOLOv3 uses *multiple independent logistic classifier* for each class rather than one softmax layer. This is very helpful especially considering that one image might have multiple labels and not all the labels are guaranteed to be mutually exclusive.

**3. Darknet + ResNet 作为基础模型**: 新的 Darknet-53 仍然依赖于连续的 3x3 和 1x1 卷积层，就像原始的 Darknet 架构一样，但增加了残差块。

> **3. Darknet + ResNet as the base model**: The new Darknet-53 still relies on successive 3x3 and 1x1 conv layers, just like the original dark net architecture, but has residual blocks added.

**4. 多尺度预测**: 受图像金字塔的启发，YOLOv3 在基础特征提取模型之后添加了几个卷积层，并在这些卷积层中以三种不同的尺度进行预测。通过这种方式，它必须处理更多各种尺寸的边界框候选。

> **4. Multi-scale prediction**: Inspired by image pyramid, YOLOv3 adds several conv layers after the base feature extractor model and makes prediction at three different scales among these conv layers. In this way, it has to deal with many more bounding box candidates of various sizes overall.

**5. 跳层连接**: YOLOv3 还在两个预测层（输出层除外）和更早的细粒度特征图之间添加了跨层连接。模型首先对粗糙特征图进行上采样，然后通过拼接将其与之前的特征合并。与细粒度信息的结合使其在检测小物体方面表现更好。

> **5. Skip-layer concatenation**: YOLOv3 also adds cross-layer connections between two prediction layers (except for the output layer) and earlier finer-grained feature maps. The model first up-samples the coarse feature maps and then merges it with the previous features by concatenation. The combination with finer-grained information makes it better at detecting small objects.

有趣的是，focal loss 对 YOLOv3 没有帮助，这可能是由于使用了 $\lambda_\text{noobj}$ 和 $\lambda_\text{coord}$ —— 它们增加了边界框位置预测的损失，并减少了背景框置信度预测的损失。

> Interestingly, focal loss does not help YOLOv3, potentially it might be due to the usage of $\lambda_\text{noobj}$ and $\lambda_\text{coord}$ — they increase the loss from bounding box location predictions and decrease the loss from confidence predictions for background boxes.

总的来说，YOLOv3 的性能优于 SSD 且速度更快，但不如 RetinaNet，不过速度快了 3.8 倍。

> Overall YOLOv3 performs better and faster than SSD, and worse than RetinaNet but 3.8x faster.

![The comparison of various fast object detection models on speed and mAP performance. (Image source: focal loss paper with additional labels from the YOLOv3 paper.)](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/yolov3-perf.png)

引用来源：

> Cited as:

```
@article{weng2018detection4,
  title   = "Object Detection Part 4: Fast Detection Models",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2018",
  url     = "https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/"
}
```

### 参考文献

> Reference

[1] Joseph Redmon, et al. [“You only look once: Unified, real-time object detection.”](https://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/Redmon_You_Only_Look_CVPR_2016_paper.pdf) CVPR 2016.

> [1] Joseph Redmon, et al. [“You only look once: Unified, real-time object detection.”](https://www.cv-foundation.org/openaccess/content_cvpr_2016/papers/Redmon_You_Only_Look_CVPR_2016_paper.pdf) CVPR 2016.

[2] Joseph Redmon and Ali Farhadi. [“YOLO9000: Better, Faster, Stronger.”](http://openaccess.thecvf.com/content_cvpr_2017/papers/Redmon_YOLO9000_Better_Faster_CVPR_2017_paper.pdf) CVPR 2017.

> [2] Joseph Redmon and Ali Farhadi. [“YOLO9000: Better, Faster, Stronger.”](http://openaccess.thecvf.com/content_cvpr_2017/papers/Redmon_YOLO9000_Better_Faster_CVPR_2017_paper.pdf) CVPR 2017.

[3] Joseph Redmon, Ali Farhadi. [“YOLOv3: An incremental improvement.”](https://pjreddie.com/media/files/papers/YOLOv3.pdf).

> [3] Joseph Redmon, Ali Farhadi. [“YOLOv3: An incremental improvement.”](https://pjreddie.com/media/files/papers/YOLOv3.pdf).

[4] Wei Liu et al. [“SSD: Single Shot MultiBox Detector.”](https://arxiv.org/abs/1512.02325) ECCV 2016.

> [4] Wei Liu et al. [“SSD: Single Shot MultiBox Detector.”](https://arxiv.org/abs/1512.02325) ECCV 2016.

[5] Tsung-Yi Lin, et al. [“Feature Pyramid Networks for Object Detection.”](https://arxiv.org/abs/1612.03144) CVPR 2017.

> [5] Tsung-Yi Lin, et al. [“Feature Pyramid Networks for Object Detection.”](https://arxiv.org/abs/1612.03144) CVPR 2017.

[6] Tsung-Yi Lin, et al. [“Focal Loss for Dense Object Detection.”](https://arxiv.org/abs/1708.02002) IEEE transactions on pattern analysis and machine intelligence, 2018.

> [6] Tsung-Yi Lin, et al. [“Focal Loss for Dense Object Detection.”](https://arxiv.org/abs/1708.02002) IEEE transactions on pattern analysis and machine intelligence, 2018.

[7] [“What’s new in YOLO v3?”](https://towardsdatascience.com/yolo-v3-object-detection-53fb7d3bfe6b) by Ayoosh Kathuria on “Towards Data Science”, Apr 23, 2018.

> [7] [“What’s new in YOLO v3?”](https://towardsdatascience.com/yolo-v3-object-detection-53fb7d3bfe6b) by  Ayoosh Kathuria on “Towards Data Science”, Apr 23, 2018.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Object Detection | 目标检测 | 识别图像中物体的位置和类别 |
| R-CNN | 区域卷积神经网络 | 一种两阶段目标检测算法家族 |
| SSD (Single Shot MultiBox Detector) | 单次多盒检测器 | 一种单阶段目标检测算法，利用多尺度特征图进行检测 |
| RetinaNet | RetinaNet | 一种单阶段密集目标检测器，引入焦点损失和特征金字塔网络 |
| YOLO (You Only Look Once) | 你只看一次 | 一种单阶段实时目标检测算法 |
| Two-stage detector | 两阶段检测器 | 先生成区域提议，再对提议进行分类和边界框回归的检测器 |
| One-stage detector | 单阶段检测器 | 直接在图像上预测边界框和类别，跳过区域提议阶段的检测器 |
| Bounding box | 边界框 | 用于定位图像中物体位置的矩形框 |
| IoU (Intersection over Union) | 交并比 | 衡量预测边界框与真实边界框重叠程度的指标 |
| Anchor box | 锚框 | 预定义的一组具有特定尺寸和长宽比的候选边界框 |
| Feature Pyramid Network (FPN) | 特征金字塔网络 | 一种多尺度特征表示方法，结合自下而上和自上而下路径 |
| Focal Loss | 焦点损失 | 一种改进的交叉熵损失函数，用于解决目标检测中前景-背景类别不平衡问题 |
| Hard negative mining | 难例挖掘 | 一种训练策略，选择容易被错误分类的负样本进行训练 |
| Batch Normalization | 批归一化 | 一种神经网络训练技术，用于加速收敛和提高模型稳定性 |
| Multi-scale prediction | 多尺度预测 | 在不同尺度的特征图上进行预测，以检测不同大小的对象 |
