# 傻瓜式目标检测 第1部分：梯度向量、HOG和SS

> Object Detection for Dummies Part 1: Gradient Vector, HOG, and SS

> 来源：Lil'Log / Lilian Weng，2017-10-29
> 原文链接：https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/
> 分类：计算机视觉 / 目标检测基础

## 核心要点

- 本文作为“傻瓜式目标检测”系列的第一部分，旨在从图像处理的基本概念入手，探讨目标识别和检测算法的数学原理。
- 图像梯度向量定义为每个像素在x轴和y轴上的颜色变化度量，具有幅值和方向两个重要属性。
- 图像梯度可通过对整个图像矩阵应用专门设计的卷积核（如Prewitt和Sobel算子）来高效计算。
- 方向梯度直方图（HOG）是一种有效的特征提取方法，通过计算图像单元格内的梯度幅值和方向直方图，并进行块归一化来构建特征向量。
- HOG特征向量可作为分类器的输入，用于目标识别任务，其鲁棒性通过按比例分配梯度幅值到相邻方向桶来增强。
- Felzenszwalb算法是一种基于图的图像分割方法，通过衡量像素间不相似性将图像分割成相似区域，是区域提议算法（如Selective Search）的初始化步骤。
- Felzenszwalb算法通过自下而上的过程，根据边权重和组件内部差异、组件间差异的比较，迭代地合并相似区域。
- 选择性搜索算法在图像分割的基础上，利用颜色、纹理、大小和形状等多种相似度度量，通过贪婪算法层次化地分组区域，生成可能包含对象的区域建议。
- 通过调整Felzenszwalb算法的阈值、改变颜色空间和组合不同的相似性度量，可以选择性搜索生成多样化的区域建议策略。
- 本文介绍的方法是目标检测和识别的传统基础，不涉及深度神经网络，为后续深度学习模型奠定理解基础。

## 正文

我从未在计算机视觉领域工作过，也不知道当一辆自动驾驶汽车被配置成区分停车标志和戴红帽的行人时，这种“魔法”是如何实现的。为了激励自己深入研究目标识别和检测算法背后的数学原理，我正在撰写几篇关于“傻瓜式目标检测”主题的文章。本文作为第1部分，从图像处理中极其基本的概念和几种图像分割方法开始。目前还没有涉及深度神经网络。用于目标检测和识别的深度学习模型将在[第2部分](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)和[第3部分](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)中讨论。

> I’ve never worked in the field of computer vision and has no idea how the magic could work when an autonomous car is configured to tell apart a stop sign from a pedestrian in a red hat. To motivate myself to look into the maths behind object recognition and detection algorithms, I’m writing a few posts on this topic “Object Detection for Dummies”. This post, part 1, starts with super rudimentary concepts in image processing and a few methods for image segmentation. Nothing related to deep neural networks yet. Deep learning models for object detection and recognition will be discussed in [Part 2](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/) and [Part 3](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/).

> 免责声明：当我开始时，我曾互换使用“目标识别”和“目标检测”。我认为它们并不相同：前者更多是关于判断图像中是否存在某个目标，而后者则需要找出目标的位置。然而，它们高度相关，许多目标识别算法为检测奠定了基础。

> Disclaimer: When I started, I was using “object recognition” and “object detection” interchangeably. I don’t think they are the same: the former is more about telling whether an object exists in an image while the latter needs to spot where the object is. However, they are highly related and many object recognition algorithms lay the foundation for detection.

本系列所有文章的链接：
[[第1部分](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)]
[[第2部分](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)]
[[第3部分](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)]
[[第4部分](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)]。

> Links to all the posts in the series:
> [[Part 1](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/)]
> [[Part 2](https://lilianweng.github.io/posts/2017-12-15-object-recognition-part-2/)]
> [[Part 3](https://lilianweng.github.io/posts/2017-12-31-object-recognition-part-3/)]
> [[Part 4](https://lilianweng.github.io/posts/2018-12-27-object-recognition-part-4/)].

### 图像梯度向量

> Image Gradient Vector

首先，我想确保我们能够区分以下术语。它们非常相似，密切相关，但并不完全相同。

> First of all, I would like to make sure we can distinguish the following terms. They are very similar, closely related, but not exactly the same.

|  | 导数 | 方向导数 | 梯度 |
| --- | --- | --- | --- |
| 值类型 | 标量 | 标量 | 向量 |
| 定义 | 函数 $f(x,y,z,…)$ 在点 $(x_0,y_0,z_0,…)$ 处的变化率，即该点处切线的斜率。 | 函数 $f(x,y,z, …)$ 沿单位向量 $\vec{u}$ 方向的瞬时变化率。 | 它指向函数增长最快的方向，包含多变量函数的所有偏导数信息。 |

> 英文原表 / English original

|  | Derivative | Directional Derivative | Gradient |
| --- | --- | --- | --- |
| Value type | Scalar | Scalar | Vector |
| Definition | The rate of change of a function $f(x,y,z,…)$ at a point $(x_0,y_0,z_0,…)$, which is the slope of the tangent line at the point. | The instantaneous rate of change of $f(x,y,z, …)$ in the direction of an unit vector $\vec{u}$. | It points in the direction of the greatest rate of increase of the function, containing all the partial derivative information of a multivariable function. |

在图像处理中，我们想知道颜色从一个极端变化到另一个极端（即灰度图像中的从黑到白）的方向。因此，我们希望测量像素颜色的“梯度”。图像上的梯度是离散的，因为每个像素都是独立的，不能再进一步分割。

> In the image processing, we want to know the direction of colors changing from one extreme to the other (i.e. black to white on a grayscale image). Therefore, we want to measure “gradient” on pixels of colors. The gradient on an image is discrete because each pixel is independent and cannot be further split.

[图像梯度向量](https://en.wikipedia.org/wiki/Image_gradient)被定义为每个独立像素的度量，包含像素在x轴和y轴上的颜色变化。该定义与连续多变量函数的梯度一致，后者是所有变量偏导数的向量。假设f(x, y)记录了位置(x, y)处像素的颜色，则像素(x, y)的梯度向量定义如下：

> The [image gradient vector](https://en.wikipedia.org/wiki/Image_gradient) is defined as a metric for every individual pixel, containing the pixel color changes in both x-axis and y-axis. The definition is aligned with the gradient of a continuous multi-variable function, which is a vector of partial derivatives of all the variables. Suppose f(x, y) records the color of the pixel at location (x, y), the gradient vector of the pixel (x, y) is defined as follows:

$$
\begin{align*}
\nabla f(x, y)
= \begin{bmatrix}
  g_x \\
  g_y
\end{bmatrix}
= \begin{bmatrix}
  \frac{\partial f}{\partial x} \\[6pt]
  \frac{\partial f}{\partial y}
\end{bmatrix}
= \begin{bmatrix}
  f(x+1, y) - f(x-1, y)\\
  f(x, y+1) - f(x, y-1)
\end{bmatrix}
\end{align*}
$$

$\frac{\partial f}{\partial x}$ 项是x方向上的偏导数，计算为目标左右相邻像素的颜色差，即 f(x+1, y) - f(x-1, y)。类似地，$\frac{\partial f}{\partial y}$ 项是y方向上的偏导数，测量为目标上方和下方相邻像素的颜色差，即 f(x, y+1) - f(x, y-1)。

> The $\frac{\partial f}{\partial x}$ term is the partial derivative on the x-direction, which is computed as the color difference between the adjacent pixels on the left and right of the target, f(x+1, y) - f(x-1, y). Similarly, the $\frac{\partial f}{\partial y}$ term is the partial derivative on the y-direction, measured as f(x, y+1) - f(x, y-1), the color difference between the adjacent pixels above and below the target.

图像梯度有两个重要属性：

> There are two important attributes of an image gradient:

• **幅值**是向量的L2范数，$g = \sqrt{ g_x^2 + g_y^2 }$。

• **方向**是两个方向上偏导数之比的反正切，$\theta = \arctan{(g_y / g_x)}$。

英文原文：

• **Magnitude** is the L2-norm of the vector, $g = \sqrt{ g_x^2 + g_y^2 }$.

• **Direction** is the arctangent of the ratio between the partial derivatives on two directions, $\theta = \arctan{(g_y / g_x)}$.

![To compute the gradient vector of a target pixel at location (x, y), we need to know the colors of its four neighbors (or eight surrounding pixels depending on the kernel).](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/image-gradient-vector-pixel-location.png)

示例中的梯度向量是：

> The gradient vector of the example in is:

$$
\begin{align*} \nabla f = \begin{bmatrix} f(x+1, y) - f(x-1, y)\\ f(x, y+1) - f(x, y-1) \end{bmatrix} = \begin{bmatrix} 55-105\\ 90-40 \end{bmatrix} = \begin{bmatrix} -50\\ 50 \end{bmatrix} \end{align*}
$$

因此，

> Thus,

• 幅值是 $\sqrt{50^2 + (-50)^2} = 70.7107$，并且

• 方向是 $\arctan{(-50/50)} = -45^{\circ}$。

英文原文：

• the magnitude is $\sqrt{50^2 + (-50)^2} = 70.7107$, and

• the direction is $\arctan{(-50/50)} = -45^{\circ}$.

迭代地对每个像素重复梯度计算过程太慢。相反，这可以很好地转化为对整个图像矩阵应用卷积运算符，使用专门设计的卷积核之一，标记为 $\mathbf{A}$。

> Repeating the gradient computation process for every pixel iteratively is too slow. Instead, it can be well translated into applying a convolution operator on the entire image matrix, labeled as $\mathbf{A}$ using one of the specially designed convolutional kernels.

让我们从图1示例的x方向开始，使用核 $[-1,0,1]$ 沿x轴滑动；$\ast$ 是卷积运算符：

> Let’s start with the x-direction of the example in Fig 1. using the kernel $[-1,0,1]$ sliding over the x-axis; $\ast$ is the convolution operator:

$$
\begin{align*}
\mathbf{G}_x &= 
[-1, 0, 1] \ast [105, 255, 55] = -105 + 0 + 55 = -50
\end{align*}
$$

类似地，在y方向上，我们采用核 $[+1, 0, -1]^\top$：

> Similarly, on the y-direction, we adopt the kernel $[+1, 0, -1]^\top$:

$$
\begin{align*}
\mathbf{G}_y &= 
[+1, 0, -1]^\top \ast
\begin{bmatrix}
  90\\
  255\\
  40
\end{bmatrix} 
= 90 + 0 - 40 = 50
\end{align*}
$$

在python中尝试这个：

> Try this in python:

```python
import numpy as np
import scipy.signal as sig
data = np.array([[0, 105, 0], [40, 255, 90], [0, 55, 0]])
G_x = sig.convolve2d(data, np.array([[-1, 0, 1]]), mode='valid') 
G_y = sig.convolve2d(data, np.array([[-1], [0], [1]]), mode='valid')
```

这两个函数分别返回 `array([[0], [-50], [0]])` 和 `array([[0, 50, 0]])`。（请注意，在numpy数组表示中，40显示在90前面，因此在核中-1相应地列在1前面。）

> These two functions return `array([[0], [-50], [0]])` and `array([[0, 50, 0]])` respectively. (Note that in the numpy array representation, 40 is shown in front of 90, so -1 is listed before 1 in the kernel correspondingly.)

#### 常用图像处理核

> Common Image Processing Kernels

[Prewitt算子](https://en.wikipedia.org/wiki/Prewitt_operator)：Prewitt算子不只依赖于四个直接相邻的像素，而是利用八个周围像素来获得更平滑的结果。

> [Prewitt operator](https://en.wikipedia.org/wiki/Prewitt_operator): Rather than only relying on four directly adjacent neighbors, the Prewitt operator utilizes eight surrounding pixels for smoother results.

$$
\mathbf{G}_x = \begin{bmatrix} -1 & 0 & +1 \\ -1 & 0 & +1 \\ -1 & 0 & +1 \end{bmatrix} \ast \mathbf{A} \text{ and } \mathbf{G}_y = \begin{bmatrix} +1 & +1 & +1 \\ 0 & 0 & 0 \\ -1 & -1 & -1 \end{bmatrix} \ast \mathbf{A}
$$

[Sobel算子](https://en.wikipedia.org/wiki/Sobel_operator)：为了更强调直接相邻像素的影响，它们被赋予更高的权重。

> [Sobel operator](https://en.wikipedia.org/wiki/Sobel_operator): To emphasize the impact of directly adjacent pixels more, they get assigned with higher weights.

$$
\mathbf{G}_x = \begin{bmatrix} -1 & 0 & +1 \\ -2 & 0 & +2 \\ -1 & 0 & +1 \end{bmatrix} \ast \mathbf{A} \text{ and } \mathbf{G}_y = \begin{bmatrix} +1 & +2 & +1 \\ 0 & 0 & 0 \\ -1 & -2 & -1 \end{bmatrix} \ast \mathbf{A}
$$

为实现不同目标创建了不同的核，例如边缘检测、模糊、锐化等等。请查看[此维基页面](https://en.wikipedia.org/wiki/Kernel_(image_processing))以获取更多示例和参考资料。

> Different kernels are created for different goals, such as edge detection, blurring, sharpening and many more. Check [this wiki page](https://en.wikipedia.org/wiki/Kernel_(image_processing)) for more examples and references.

#### 示例：2004年的马努

> Example: Manu in 2004

让我们对马努·吉诺比利2004年（当时他还有很多头发）的照片进行一个简单的实验 [[下载图片]({{ ‘/assets/data/manu-2004.jpg’ | relative_url }}){:target="_blank"}]。为简单起见，照片首先被转换为灰度图。对于彩色图像，我们只需在每个颜色通道中分别重复相同的过程。

> Let’s run a simple experiment on the photo of Manu Ginobili in 2004 [[Download Image]({{ ‘/assets/data/manu-2004.jpg’ | relative_url }}){:target="_blank"}] when he still had a lot of hair. For simplicity, the photo is converted to grayscale first. For colored images, we just need to repeat the same process in each color channel respectively.

![Manu Ginobili in 2004 with hair. (Image source: Manu Ginobili's bald spot through the years )](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/manu-2004.png)

```python
import numpy as np
import scipy
import scipy.signal as sig
# With mode="L", we force the image to be parsed in the grayscale, so it is
# actually unnecessary to convert the photo color beforehand.
img = scipy.misc.imread("manu-2004.jpg", mode="L")

# Define the Sobel operator kernels.
kernel_x = np.array([[-1, 0, 1],[-2, 0, 2],[-1, 0, 1]])
kernel_y = np.array([[1, 2, 1], [0, 0, 0], [-1, -2, -1]])

G_x = sig.convolve2d(img, kernel_x, mode='same') 
G_y = sig.convolve2d(img, kernel_y, mode='same') 

# Plot them!
fig = plt.figure()
ax1 = fig.add_subplot(121)
ax2 = fig.add_subplot(122)

# Actually plt.imshow() can handle the value scale well even if I don't do 
# the transformation (G_x + 255) / 2.
ax1.imshow((G_x + 255) / 2, cmap='gray'); ax1.set_xlabel("Gx")
ax2.imshow((G_y + 255) / 2, cmap='gray'); ax2.set_xlabel("Gy")
plt.show()
```

![Apply Sobel operator kernel on the example image.](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/manu-2004-sobel-operator.png)

你可能会注意到大部分区域是灰色的。因为两个像素之间的差异在-255到255之间，我们需要将它们转换回[0, 255]以供显示。
一个简单的线性变换 ($\mathbf{G}$ + 255)/2 会将所有零（即，颜色恒定的背景显示没有梯度变化）解释为125（显示为灰色）。

> You might notice that most area is in gray. Because the difference between two pixel is between -255 and 255 and we need to convert them back to [0, 255] for the display purpose.
> A simple linear transformation ($\mathbf{G}$ + 255)/2 would interpret all the zeros (i.e., constant colored background shows no change in gradient) as 125 (shown as gray).

### 方向梯度直方图 (HOG)

> Histogram of Oriented Gradients (HOG)

方向梯度直方图 (HOG) 是一种从像素颜色中提取特征以构建目标识别分类器的有效方法。有了图像梯度向量的知识，理解HOG的工作原理并不难。让我们开始吧！

> The Histogram of Oriented Gradients (HOG) is an efficient way to extract features out of the pixel colors for building an object recognition classifier. With the knowledge of image gradient vectors, it is not hard to understand how HOG works. Let’s start!

#### HOG的工作原理

> How HOG works

1. 
预处理图像，包括调整大小和颜色归一化。

2. 
计算每个像素的梯度向量，以及其幅值和方向。

3. 
将图像划分为许多8x8像素的单元格。在每个单元格中，这64个单元格的幅值被分箱并累加到9个无符号方向（无符号，即0-180度而不是0-360度；这是基于经验实验的实际选择）的桶中。
  
  

为了更好的鲁棒性，如果像素梯度向量的方向介于两个桶之间，其幅值不会全部进入更近的那个桶，而是按比例分配给两个桶。例如，如果一个像素的梯度向量幅值为8，角度为15度，它介于0度和20度的两个桶之间，我们将分配2给桶0，分配6给桶20。
  
  

这种有趣的配置使得当图像受到微小失真时，直方图更加稳定。


> • 
> Preprocess the image, including resizing and color normalization.
> • 
> Compute the gradient vector of every pixel, as well as its magnitude and direction.
> • 
> Divide the image into many 8x8 pixel cells. In each cell, the magnitude values of these 64 cells are binned and cumulatively added into 9 buckets of unsigned direction (no sign, so 0-180 degree rather than 0-360 degree; this is a practical choice based on empirical experiments).
>
>
>
> For better robustness, if the direction of the gradient vector of a pixel lays between two buckets, its magnitude does not all go into the closer one but proportionally split between two. For example, if a pixel’s gradient vector has magnitude 8 and degree 15, it is between two buckets for degree 0 and 20 and we would assign 2 to bucket 0 and 6 to bucket 20.
>
>
>
> This interesting configuration makes the histogram much more stable when small distortion is applied to the image.

![How to split one gradient vector's magnitude if its degress is between two degree bins. (Image source: https://www.learnopencv.com/histogram-of-oriented-gradients/)](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/HOG-histogram-creation.png)

1. 然后，我们以2x2个单元格（即16x16像素）的块在图像上滑动。在每个块区域中，4个单元格的4个直方图被连接成一个36值的一维向量，然后归一化以具有单位权重。
最终的HOG特征向量是所有块向量的连接。它可以输入到像SVM这样的分类器中，用于学习目标识别任务。

> • Then we slide a 2x2 cells (thus 16x16 pixels) block across the image. In each block region, 4 histograms of 4 cells are concatenated into one-dimensional vector of 36 values and then normalized to have an unit weight.
> The final HOG feature vector is the concatenation of all the block vectors. It can be fed into a classifier like SVM for learning object recognition tasks.

#### 示例：2004年的马努

> Example: Manu in 2004

让我们重用上一节中的相同示例图像。请记住，我们已经为整个图像计算了 $\mathbf{G}_x$ 和 $\mathbf{G}_y$。

> Let’s reuse the same example image in the previous section. Remember that we have computed $\mathbf{G}_x$ and $\mathbf{G}_y$ for the whole image.

```python
N_BUCKETS = 9
CELL_SIZE = 8  # Each cell is 8x8 pixels
BLOCK_SIZE = 2  # Each block is 2x2 cells

def assign_bucket_vals(m, d, bucket_vals):
    left_bin = int(d / 20.)
    # Handle the case when the direction is between [160, 180)
    right_bin = (int(d / 20.) + 1) % N_BUCKETS
    assert 0 <= left_bin < right_bin < N_BUCKETS

    left_val= m * (right_bin * 20 - d) / 20
    right_val = m * (d - left_bin * 20) / 20
    bucket_vals[left_bin] += left_val
    bucket_vals[right_bin] += right_val

def get_magnitude_hist_cell(loc_x, loc_y):
    # (loc_x, loc_y) defines the top left corner of the target cell.
    cell_x = G_x[loc_x:loc_x + CELL_SIZE, loc_y:loc_y + CELL_SIZE]
    cell_y = G_y[loc_x:loc_x + CELL_SIZE, loc_y:loc_y + CELL_SIZE]
    magnitudes = np.sqrt(cell_x * cell_x + cell_y * cell_y)
    directions = np.abs(np.arctan(cell_y / cell_x) * 180 / np.pi)

    buckets = np.linspace(0, 180, N_BUCKETS + 1)
    bucket_vals = np.zeros(N_BUCKETS)
    map(
        lambda (m, d): assign_bucket_vals(m, d, bucket_vals), 
        zip(magnitudes.flatten(), directions.flatten())
    )
    return bucket_vals

def get_magnitude_hist_block(loc_x, loc_y):
    # (loc_x, loc_y) defines the top left corner of the target block.
    return reduce(
        lambda arr1, arr2: np.concatenate((arr1, arr2)),
        [get_magnitude_hist_cell(x, y) for x, y in zip(
            [loc_x, loc_x + CELL_SIZE, loc_x, loc_x + CELL_SIZE],
            [loc_y, loc_y, loc_y + CELL_SIZE, loc_y + CELL_SIZE],
        )]
    )
```

以下代码简单地调用函数来构建直方图并绘制它。

> The following code simply calls the functions to construct a histogram and plot it.

```python
# Random location [200, 200] as an example.
loc_x = loc_y = 200

ydata = get_magnitude_hist_block(loc_x, loc_y)
ydata = ydata / np.linalg.norm(ydata)

xdata = range(len(ydata))
bucket_names = np.tile(np.arange(N_BUCKETS), BLOCK_SIZE * BLOCK_SIZE)

assert len(ydata) == N_BUCKETS * (BLOCK_SIZE * BLOCK_SIZE)
assert len(bucket_names) == len(ydata)

plt.figure(figsize=(10, 3))
plt.bar(xdata, ydata, align='center', alpha=0.8, width=0.9)
plt.xticks(xdata, bucket_names * 20, rotation=90)
plt.xlabel('Direction buckets')
plt.ylabel('Magnitude')
plt.grid(ls='--', color='k', alpha=0.1)
plt.title("HOG of block at [%d, %d]" % (loc_x, loc_y))
plt.tight_layout()
```

在上面的代码中，我使用左上角位于[200, 200]的块作为示例，这是该块最终的归一化直方图。你可以通过修改代码来改变滑动窗口识别的块位置。

> In the code above, I use the block with top left corner located at [200, 200] as an example and here is the final normalized histogram of this block. You can play with the code to change the block location to be identified by a sliding window.

![Demonstration of a HOG histogram for one block.](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/block_histogram.png)

这段代码主要是为了演示计算过程。有许多现成的库实现了HOG算法，例如 [OpenCV](https://github.com/opencv/opencv)、[SimpleCV](http://simplecv.org/) 和 [scikit-image](http://scikit-image.org/)。

> The code is mostly for demonstrating the computation process. There are many off-the-shelf libraries with HOG algorithm implemented, such as [OpenCV](https://github.com/opencv/opencv), [SimpleCV](http://simplecv.org/) and [scikit-image](http://scikit-image.org/).

### 图像分割（Felzenszwalb 算法）

> Image Segmentation (Felzenszwalb’s Algorithm)

当一张图像中存在多个对象时（几乎所有真实世界的照片都是如此），我们需要识别一个可能包含目标对象的区域，以便更有效地执行分类。

> When there exist multiple objects in one image (true for almost every real-world photos), we need to identify a region that potentially contains a target object so that the classification can be executed more efficiently.

Felzenszwalb 和 Huttenlocher ([2004](http://cvcl.mit.edu/SUNSeminar/Felzenszwalb_IJCV04.pdf)) 提出了一种使用基于图的方法将图像分割成相似区域的算法。它也是我们稍后将讨论的 Selective Search（一种流行的区域提议算法）的初始化方法。

> Felzenszwalb and Huttenlocher ([2004](http://cvcl.mit.edu/SUNSeminar/Felzenszwalb_IJCV04.pdf)) proposed an algorithm for segmenting an image into similar regions using a graph-based approach. It is also the initialization method for Selective Search (a popular region proposal algorithm) that we are gonna discuss later.

假设我们使用无向图$G=(V, E)$来表示输入图像。一个顶点$v_i \in V$代表一个像素。一条边$e = (v_i, v_j) \in E$连接两个顶点$v_i$和$v_j$。其关联权重$w(v_i, v_j)$衡量$v_i$和$v_j$之间的不相似性。这种不相似性可以通过颜色、位置、强度等维度进行量化。权重越高，两个像素之间的相似度越低。一个分割方案$S$是将$V$分割成多个连通分量，$\{C\}$。直观上，相似的像素应属于同一分量，而不相似的像素则被分配到不同的分量。

> Say, we use a undirected graph $G=(V, E)$ to represent an input image. One vertex $v_i \in V$ represents one pixel. One edge $e = (v_i, v_j) \in E$ connects two vertices $v_i$ and $v_j$. Its associated weight $w(v_i, v_j)$ measures the dissimilarity between $v_i$ and $v_j$. The dissimilarity can be quantified in dimensions like color, location, intensity, etc. The higher the weight, the less similar two pixels are. A segmentation solution $S$ is a partition of $V$ into multiple connected components, $\{C\}$. Intuitively similar pixels should belong to the same components while dissimilar ones are assigned to different components.

#### 图的构建

> Graph Construction

有两种方法可以从图像中构建图。

> There are two approaches to constructing a graph out of an image.

- **网格图**：每个像素仅与其周围的邻居（总共8个其他单元格）连接。边的权重是像素强度值之间的绝对差。
- **最近邻图**：每个像素都是特征空间(x, y, r, g, b)中的一个点，其中(x, y)是像素位置，(r, g, b)是RGB颜色值。权重是两个像素特征向量之间的欧几里得距离。

> • **Grid Graph**: Each pixel is only connected with surrounding neighbours (8 other cells in total). The edge weight is the absolute difference between the intensity values of the pixels.
> • **Nearest Neighbor Graph**: Each pixel is a point in the feature space (x, y, r, g, b), in which (x, y) is the pixel location and (r, g, b) is the color values in RGB. The weight is the Euclidean distance between two pixels’ feature vectors.

#### 关键概念

> Key Concepts

在我们确定良好图划分（即图像分割）的标准之前，让我们先定义几个关键概念：

> Before we lay down the criteria for a good graph partition (aka image segmentation), let us define a couple of key concepts:

• **内部差异**：$Int(C) = \max_{e\in MST(C, E)} w(e)$，其中$MST$是这些组件的最小生成树。一个组件$C$即使我们移除了所有权重小于$Int(C)$的边，也仍然可以保持连接。

• **两个组件之间的差异**：$Dif(C_1, C_2) = \min_{v_i \in C_1, v_j \in C_2, (v_i, v_j) \in E} w(v_i, v_j)$。$Dif(C_1, C_2) = \infty$如果它们之间没有边。

• **最小内部差异**: $MInt(C_1, C_2) = min(Int(C_1) + \tau(C_1), Int(C_2) + \tau(C_2))$，其中 $\tau(C) = k / \vert C \vert$ 有助于确保我们对组件之间的差异有一个有意义的阈值。当 $k$ 较高时，更有可能产生更大的组件。

英文原文：

• **Internal difference**: $Int(C) = \max_{e\in MST(C, E)} w(e)$, where $MST$ is the minimum spanning tree of the components. A component $C$ can still remain connected even when we have removed all the edges with weights < $Int(C)$.

• **Difference between two components**: $Dif(C_1, C_2) = \min_{v_i \in C_1, v_j \in C_2, (v_i, v_j) \in E} w(v_i, v_j)$. $Dif(C_1, C_2) = \infty$ if there is no edge in-between.

• **Minimum internal difference**: $MInt(C_1, C_2) = min(Int(C_1) + \tau(C_1), Int(C_2) + \tau(C_2))$, where $\tau(C) = k / \vert C \vert$ helps make sure we have a meaningful threshold for the difference between components. With a higher $k$, it is more likely to result in larger components.

分割的质量通过为给定两个区域 $C_1$ 和 $C_2$ 定义的成对区域比较谓词进行评估：

> The quality of a segmentation is assessed by a pairwise region comparison predicate defined for given two regions $C_1$ and $C_2$:

$$
D(C_1, C_2) = 
\begin{cases}
  \text{True} & \text{ if } Dif(C_1, C_2) > MInt(C_1, C_2) \\
  \text{False} & \text{ otherwise}
\end{cases}
$$

只有当谓词为真时，我们才认为它们是两个独立的组件；否则，分割过于精细，它们可能应该合并。

> Only when the predicate holds True, we consider them as two independent components; otherwise the segmentation is too fine and they probably should be merged.

#### 图像分割的工作原理

> How Image Segmentation Works

该算法遵循自下而上的过程。给定 $G=(V, E)$ 和 $|V|=n, |E|=m$：

> The algorithm follows a bottom-up procedure. Given $G=(V, E)$ and $|V|=n, |E|=m$:

1\. 边按权重升序排序，标记为 $e_1, e_2, \dots, e_m$。

2\. 最初，每个像素都停留在自己的组件中，因此我们从 $n$ 个组件开始。

3\. 重复 $k=1, \dots, m$:\n\n

• 步骤 $k$ 处的分割快照表示为 $S^k$。



• 我们按顺序取第 k 条边，$e_k = (v_i, v_j)$。



• 如果 $v_i$ 和 $v_j$ 属于同一个组件，则不执行任何操作，因此 $S^k = S^{k-1}$。



• 如果 $v_i$ 和 $v_j$ 属于两个不同的组件 $C_i^{k-1}$ 和 $C_j^{k-1}$，如分割 $S^{k-1}$ 所示，我们希望在 $w(v_i, v_j) \leq MInt(C_i^{k-1}, C_j^{k-1})$ 的情况下将它们合并为一个；否则不执行任何操作。

英文原文：

1\. Edges are sorted by weight in ascending order, labeled as $e_1, e_2, \dots, e_m$.

2\. Initially, each pixel stays in its own component, so we start with $n$ components.

3\. Repeat for $k=1, \dots, m$:



• The segmentation snapshot at the step $k$ is denoted as $S^k$.



• We take  the k-th edge in the order, $e_k = (v_i, v_j)$.



• If $v_i$ and $v_j$ belong to the same component, do nothing and thus $S^k = S^{k-1}$.



• If $v_i$ and $v_j$ belong to two different components $C_i^{k-1}$ and $C_j^{k-1}$ as in the segmentation $S^{k-1}$, we want to merge them into one if $w(v_i, v_j) \leq MInt(C_i^{k-1}, C_j^{k-1})$; otherwise do nothing.

如果您对分割属性的证明以及它为何始终存在感兴趣，请参阅这篇 [论文](http://fcv2011.ulsan.ac.kr/files/announcement/413/IJCV(2004)%20Efficient%20Graph-Based%20Image%20Segmentation.pdf)。

> If you are interested in the proof of the segmentation properties and why it always exists, please refer to the [paper](http://fcv2011.ulsan.ac.kr/files/announcement/413/IJCV(2004)%20Efficient%20Graph-Based%20Image%20Segmentation.pdf).

![An indoor scene with segmentation detected by the grid graph construction in Felzenszwalb's graph-based segmentation algorithm (k=300).](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/image-segmentation-indoor.png)

#### 示例：2013年的马努

> Example: Manu in 2013

这次我将使用2013年老马努·吉诺比利的照片[[Image]({{ ‘/assets/data/manu-2013.jpg’ | relative_url }})]作为示例图片，当时他的秃顶已经很明显了。为了简单起见，我们仍然使用灰度图片。

> This time I would use the photo of old Manu Ginobili in 2013 [[Image]({{ ‘/assets/data/manu-2013.jpg’ | relative_url }})] as the example image when his bald spot has grown up strong. Still for simplicity, we use the picture in grayscale.

![Manu Ginobili in 2013 with bald spot. (Image source: Manu Ginobili's bald spot through the years )](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/manu-2013.png)

我们不从头开始编写代码，而是将[skimage.segmentation.felzenszwalb](http://scikit-image.org/docs/dev/api/skimage.segmentation.html#skimage.segmentation.felzenszwalb)应用于图像。

> Rather than coding from scratch, let us apply [skimage.segmentation.felzenszwalb](http://scikit-image.org/docs/dev/api/skimage.segmentation.html#skimage.segmentation.felzenszwalb) to the image.

```python
import skimage.segmentation
from matplotlib import pyplot as plt

img2 = scipy.misc.imread("manu-2013.jpg", mode="L")
segment_mask1 = skimage.segmentation.felzenszwalb(img2, scale=100)
segment_mask2 = skimage.segmentation.felzenszwalb(img2, scale=1000)

fig = plt.figure(figsize=(12, 5))
ax1 = fig.add_subplot(121)
ax2 = fig.add_subplot(122)
ax1.imshow(segment_mask1); ax1.set_xlabel("k=100")
ax2.imshow(segment_mask2); ax2.set_xlabel("k=1000")
fig.suptitle("Felsenszwalb's efficient graph based image segmentation")
plt.tight_layout()
plt.show()
```

代码运行了Felzenszwalb算法的两个版本，如所示。左侧k=100生成了更细粒度的分割，其中小区域识别出马努的秃顶。右侧k=1000输出更粗粒度的分割，其中区域往往更大。

> The code ran two versions of Felzenszwalb’s algorithms as shown in The left k=100 generates a finer-grained segmentation with small regions where Manu’s bald spot is identified. The right one k=1000 outputs a coarser-grained segmentation where regions tend to be larger.

![Felsenszwalb's efficient graph-based image segmentation is applied on the photo of Manu in 2013.](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/manu-2013-segmentation.png)

### 选择性搜索

> Selective Search

选择性搜索是一种常用算法，用于提供可能包含对象的区域建议。它建立在图像分割输出之上，并使用基于区域的特征（注意：不仅仅是单个像素的属性）进行自下而上的层次分组。

> Selective search is a common algorithm to provide region proposals that potentially contain objects. It is built on top of the image segmentation output and use region-based characteristics (NOTE: not just attributes of a single pixel) to do a bottom-up hierarchical grouping.

#### 选择性搜索的工作原理

> How Selective Search Works

1. 在初始化阶段，应用Felzenszwalb和Huttenlocher的基于图的图像分割算法来创建初始区域。
2. 使用贪婪算法迭代地将区域分组：


   - 首先计算所有相邻区域之间的相似度。
   - 将两个最相似的区域组合在一起，并计算所得区域与其邻居之间的新相似度。
3. 重复分组最相似区域的过程（步骤2），直到整个图像成为一个单一区域。

> • At the initialization stage, apply Felzenszwalb and Huttenlocher’s graph-based image segmentation algorithm to create regions to start with.

> • Use a greedy algorithm to iteratively group regions together:
>

> ◦ First the similarities between all neighbouring regions are calculated.

> ◦ The two most similar regions are grouped together, and new similarities are calculated between the resulting region and its neighbours.

> • The process of grouping the most similar regions (Step 2) is repeated until the whole image becomes a single region.

![The detailed algorithm of Selective Search.](https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/selective-search-algorithm.png)

#### 配置变体

> Configuration Variations

给定两个区域$(r_i, r_j)$，选择性搜索提出了四种互补的相似性度量：

> Given two regions $(r_i, r_j)$, selective search proposed four complementary similarity measures:

- **颜色**相似度
- **纹理**：使用适用于材料识别的算法，例如[SIFT](http://www.cs.ubc.ca/~lowe/papers/iccv99.pdf)。
- **大小**：鼓励小区域尽早合并。
- **形状**：理想情况下，一个区域可以填补另一个区域的空白。

> • **Color** similarity
> • **Texture**: Use algorithm that works well for material recognition such as [SIFT](http://www.cs.ubc.ca/~lowe/papers/iccv99.pdf).
> • **Size**: Small regions are encouraged to merge early.
> • **Shape**: Ideally one region can fill the gap of the other.

通过(i)调整Felzenszwalb和Huttenlocher算法中的阈值$k$，(ii)改变颜色空间，以及(iii)选择不同的相似性度量组合，我们可以生成多样化的选择性搜索策略。生成最佳质量区域建议的版本配置为(i)各种初始分割建议的混合，(ii)多种颜色空间的融合，以及(iii)所有相似性度量的组合。不出所料，我们需要在质量（模型复杂性）和速度之间取得平衡。

> By (i) tuning the threshold $k$ in Felzenszwalb and Huttenlocher’s algorithm, (ii) changing the color space and (iii) picking different combinations of similarity metrics, we can produce a diverse set of Selective Search strategies. The version that produces the region proposals with best quality is configured with (i) a mixture of various initial segmentation proposals, (ii) a blend of multiple color spaces and (iii) a combination of all similarity measures. Unsurprisingly we need to balance between the quality (the model complexity) and the speed.

引用方式：

> Cited as:

```
@article{weng2017detection1,
  title   = "Object Detection for Dummies Part 1: Gradient Vector, HOG, and SS",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2017",
  url     = "https://lilianweng.github.io/posts/2017-10-29-object-recognition-part-1/"
}
```

### 参考文献

> References

[1] Dalal, Navneet, and Bill Triggs. [“用于人体检测的定向梯度直方图。”](https://hal.inria.fr/file/index/docid/548512/filename/hog_cvpr2005.pdf) Computer Vision and Pattern Recognition (CVPR), 2005。

> [1] Dalal, Navneet, and Bill Triggs. [“Histograms of oriented gradients for human detection.”](https://hal.inria.fr/file/index/docid/548512/filename/hog_cvpr2005.pdf) Computer Vision and Pattern Recognition (CVPR), 2005.

[2] Pedro F. Felzenszwalb, and Daniel P. Huttenlocher. [“高效的基于图的图像分割。”](http://cvcl.mit.edu/SUNSeminar/Felzenszwalb_IJCV04.pdf) Intl. journal of computer vision 59.2 (2004): 167-181。

> [2] Pedro F. Felzenszwalb, and Daniel P. Huttenlocher. [“Efficient graph-based image segmentation.”](http://cvcl.mit.edu/SUNSeminar/Felzenszwalb_IJCV04.pdf) Intl. journal of computer vision 59.2 (2004): 167-181.

[3] [Satya Mallick的定向梯度直方图](https://www.learnopencv.com/histogram-of-oriented-gradients/)

> [3] [Histogram of Oriented Gradients by Satya Mallick](https://www.learnopencv.com/histogram-of-oriented-gradients/)

[4] [Chris McCormick的梯度向量](http://mccormickml.com/2013/05/07/gradient-vectors/)

> [4] [Gradient Vectors by Chris McCormick](http://mccormickml.com/2013/05/07/gradient-vectors/)

[5] [Chris McCormick的HOG人物检测器教程](http://mccormickml.com/2013/05/09/hog-person-detector-tutorial/)

> [5] [HOG Person Detector Tutorial by Chris McCormick](http://mccormickml.com/2013/05/09/hog-person-detector-tutorial/)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Computer Vision | 计算机视觉 | 使计算机能够“看”并理解图像和视频的技术领域。 |
| Object Recognition | 目标识别 | 判断图像中是否存在特定目标的技术。 |
| Object Detection | 目标检测 | 在图像中找出特定目标的位置并识别其类别的技术。 |
| Image Gradient Vector | 图像梯度向量 | 衡量图像中每个像素颜色在x轴和y轴上变化方向和幅值的向量。 |
| Convolution Operator | 卷积算子 | 在图像处理中，通过与核函数进行卷积运算来提取图像特征或进行变换的数学操作。 |
| Histogram of Oriented Gradients (HOG) | 方向梯度直方图 | 一种特征描述符，通过计算图像局部区域内梯度方向的分布来表示图像特征。 |
| Feature Vector | 特征向量 | 从原始数据中提取的、用于表示其关键属性的数值列表，常作为机器学习模型的输入。 |
| Image Segmentation | 图像分割 | 将数字图像划分为多个图像区域或像素集的过程，每个区域内部具有相似的特征。 |
| Graph-based method | 基于图的方法 | 将图像像素或区域表示为图的节点，通过分析节点和边来解决图像处理问题的方法。 |
| Minimum Spanning Tree (MST) | 最小生成树 | 在一个加权无向图中，连接所有顶点的边的子集，且所有边的权重之和最小。 |
| Selective Search | 选择性搜索 | 一种区域提议算法，通过层次化分组图像分割区域来生成可能包含对象的候选框。 |
| Region Proposal | 区域提议 | 在目标检测中，生成可能包含对象的候选区域的过程。 |
| Greedy Algorithm | 贪婪算法 | 在每一步选择中都采取在当前状态下最好或最优的选择，从而希望导致结果是全局最好或最优的算法。 |
| Similarity Measure | 相似度度量 | 量化两个对象或区域之间相似程度的指标。 |
| Color Space | 颜色空间 | 描述和表示颜色的一种数学模型或系统，如RGB、HSV等。 |
