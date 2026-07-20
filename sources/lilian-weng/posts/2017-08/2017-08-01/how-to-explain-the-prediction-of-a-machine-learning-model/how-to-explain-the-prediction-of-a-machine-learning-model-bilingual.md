# 如何解释机器学习模型的预测？

> How to Explain the Prediction of a Machine Learning Model?

> 来源：Lil'Log / Lilian Weng，2017-08-01
> 原文链接：https://lilianweng.github.io/posts/2017-08-01-interpretation/
> 分类：机器学习 / 模型可解释性

## 核心要点

- 机器学习模型在医疗、司法和金融等关键领域广泛应用，因此理解其决策过程并确保符合伦理法规至关重要。
- 深度学习模型因其“黑盒”特性，使得解释其复杂决策的需求日益增长，以建立信任并有效处理异常行为。
- 可解释模型应具备可模拟性、算法透明性和可分解性，经典模型如线性回归、朴素贝叶斯和决策树/列表本身就具有较好的可解释性。
- 随机森林虽然是集成模型，但其由可解释的决策树组成，可通过平均不纯度减少来量化全局特征重要性。
- 解释黑盒模型的方法旨在不了解模型内部工作原理的情况下，通过提取信息来证明其预测的合理性，并平衡忠实性和可解释性。
- 局部解释方法如预测分解、局部梯度解释向量和LIME，通过分析特征贡献或局部近似来揭示模型决策。
- LIME通过在感兴趣的预测附近局部近似黑盒模型，并使用可解释的表示和扰动样本来学习简单模型，有助于诊断虚假相关性。
- 全局解释方法如特征选择和BETA，旨在解释模型的整体行为，但可能无法捕捉细粒度的局部重要性。
- 可解释人工智能（XAI）项目致力于开发更具可解释性的AI模型，以增强人类对新兴AI技术的理解、信任和管理能力。
- 对抗性样本研究揭示了深度神经网络可能存在的意外行为和鲁棒性问题，进一步强调了模型可解释性的重要性。

## 正文

机器学习模型已开始渗透到医疗保健、司法系统和金融行业等关键领域。因此，弄清模型如何做出决策并确保决策过程符合伦理要求或法律法规变得至关重要。

> The machine learning models have started penetrating into critical areas like health care, justice systems, and financial industry. Thus to figure out how the models make the decisions and make sure the decisioning process is aligned with the ethnic requirements or legal regulations becomes a necessity.

与此同时，深度学习模型的快速发展进一步推动了对解释复杂模型的需求。人们渴望将人工智能的力量充分应用于日常生活的关键方面。然而，如果对模型没有足够的信任，或者没有有效的程序来解释意外行为，就很难做到这一点，特别是考虑到深度神经网络天生就是*黑盒*。

> Meanwhile, the rapid growth of deep learning models pushes the requirement of interpreting complicated models further. People are eager to apply the power of AI fully on key aspects of everyday life. However, it is hard to do so without enough trust in the models or an efficient procedure to explain unintended behavior, especially considering that the deep neural networks are born as *black-boxes*.

考虑以下情况：

> Think of the following cases:

1. 金融行业受到高度监管，法律要求贷款发放机构做出公平决策，并在决定拒绝贷款申请时解释其信用模型并提供理由。
2. 医疗诊断模型关乎人类生命。我们如何才能足够自信地按照黑盒模型的指示治疗患者？
3. 在法庭上使用刑事判决模型预测再犯风险时，我们必须确保模型以公平、诚实和非歧视的方式运行。
4. 如果一辆自动驾驶汽车突然出现异常行为，而我们无法解释原因，我们是否会足够放心在大规模真实交通中使用这项技术？

> • The financial industry is highly regulated and loan issuers are required by law to make fair decisions and explain their credit models to provide reasons whenever they decide to decline loan application.
> • Medical diagnosis model is responsible for human life. How can we be confident enough to treat a patient as instructed by a black-box model?
> • When using a criminal decision model to predict the risk of recidivism at the court, we have to make sure the model behaves in an equitable, honest and nondiscriminatory manner.
> • If a self-driving car suddenly acts abnormally and we cannot explain why, are we gonna be comfortable enough to use the technique in real traffic in large scale?

在[Affirm](https://www.affirm.com/)，我们每天发放数万笔分期贷款，当模型拒绝某人的贷款申请时，我们的承保模型必须提供拒绝理由。这是我深入研究并撰写此文的众多动机之一。模型可解释性是机器学习中的一个重要领域。本文并非旨在穷尽所有研究，而是作为一个起点。

> At [Affirm](https://www.affirm.com/), we are issuing tens of thousands of installment loans every day and our underwriting model has to provide declination reasons when the model rejects one’s loan application. That’s one of the many motivations for me to dig deeper and write this post. Model interpretability is a big field in machine learning. This review is never met to exhaust every study, but to serve as a starting point.

### 可解释模型

> Interpretable Models

Lipton (2017) 在一篇理论综述论文[《模型可解释性的神话》](https://arxiv.org/pdf/1606.03490.pdf)中总结了可解释模型的特性：人类可以重复（*“可模拟性”*）计算过程，并完全理解算法（*“算法透明性”*），且模型的每个独立部分都拥有直观的解释（*“可分解性”*）。

> Lipton (2017) summarized the properties of an interpretable model in a theoretical review paper, [“The mythos of model interpretability”](https://arxiv.org/pdf/1606.03490.pdf): A human can repeat (*“simulatability”*) the computation process with a full understanding of the algorithm (*“algorithmic transparency”*) and every individual part of the model owns an intuitive explanation (*“decomposability”*).

许多经典模型具有相对简单的形式，并且自然地带有模型特定的解释方法。同时，正在开发新工具以帮助创建更好的可解释模型（[Been, Khanna, & Koyejo, 2016](http://papers.nips.cc/paper/6300-examples-are-not-enough-learn-to-criticize-criticism-for-interpretability.pdf); [Lakkaraju, Bach & Leskovec, 2016](http://www.kdd.org/kdd2016/papers/files/rpp1067-lakkarajuA.pdf)）。

> Many classic models have relatively simpler formation and naturally, come with a model-specific interpretation method. Meanwhile, new tools are being developed to help create better interpretable models ([Been, Khanna, & Koyejo, 2016](http://papers.nips.cc/paper/6300-examples-are-not-enough-learn-to-criticize-criticism-for-interpretability.pdf); [Lakkaraju, Bach & Leskovec, 2016](http://www.kdd.org/kdd2016/papers/files/rpp1067-lakkarajuA.pdf)).

#### 回归

> Regression

线性回归模型的一般形式是：

> A general form of a linear regression model is:

$$
y = w_0 + w_1 x_1 + w_2 x_2 + … + w_n x_n
$$

系数描述了自变量增加一个单位所引起的响应变化。除非特征已经标准化（检查 sklearn.preprocessing.[StandardScalar](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html#sklearn.preprocessing.StandardScaler) 和 [RobustScaler](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.RobustScaler.html#sklearn.preprocessing.RobustScaler)），否则系数不能直接比较，因为不同特征的一个单位可能指代非常不同的事物。在未标准化的条件下，乘积 $w_i \dot x_i$ 可用于量化单个特征对响应的贡献。

> The coefficients describe the change of the response triggered by one unit increase of the independent variables. The coefficients are not comparable directly unless the features have been standardized (check sklearn.preprocessing.[StandardScalar](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html#sklearn.preprocessing.StandardScaler) and [RobustScaler](http://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.RobustScaler.html#sklearn.preprocessing.RobustScaler)), since one unit of different features can refer to very different things. Without standardization, the product $w_i \dot x_i$ can be used to quantify one feature’s contribution to the response.

#### 朴素贝叶斯

> Naive Bayes

朴素贝叶斯之所以被称为“朴素”，是因为它基于一个非常简化的假设：特征彼此独立，并且每个特征都独立地对输出做出贡献。

> Naive Bayes is named as “Naive” because it works on a very simplified assumption that features are independent of each other and each contributes to the output independently.

给定特征向量 $\mathbf{x} = [x_1, x_2, \dots, x_n]$ 和类别标签 $c \in \{1, 2, \dots, C\}$，此数据点属于该类别的概率为：

> Given a feature vector $\mathbf{x} = [x_1, x_2, \dots, x_n]$ and a class label $c \in \{1, 2, \dots, C\}$, the probability of this data point belonging to this class is:

$$
\begin{aligned}
p(c | x_1, x_2, \dots, x_n) 
&\propto p(c, x_1, x_2, \dots, x_n)\\
&\propto p(c) p(x_1 | c) p(x_2 | c) \dots p(x_n | c)\\
&\propto p(c) \prod_{i=1}^n p(x_i | c).
\end{aligned}
$$

朴素贝叶斯分类器定义为：

> The Naive Bayes classifier is then defined as:

$$
\hat{y} = \arg\max_{c \in 1, \dots, C} p(c) \prod_{i=1}^n p(x_i | c)
$$

由于模型在训练过程中学习了先验 $p(x_i \vert c)$，因此单个特征值的贡献可以通过后验 $p(c \vert x_i) = p(c)p(x_i \vert c) / p(x_i)$ 轻松衡量。

> Because the model has learned the prior $p(x_i \vert c)$ during the training, the contribution of an individual feature value can be easily measured by the posterior, $p(c \vert x_i) = p(c)p(x_i \vert c) / p(x_i)$.

#### 决策树/决策列表

> Decision Tree/Decision Lists

决策列表是一组布尔函数，通常通过类似 `if... then... else...` 的语法构建。if 条件包含一个涉及一个或多个特征的函数和一个布尔输出。决策列表天生具有良好的可解释性，并且可以以树状结构可视化。许多关于决策列表的研究都受到医疗应用的推动，在这些应用中，可解释性几乎与模型本身一样重要。

> Decision lists are a set of boolean functions, usually constructed by the syntax like `if... then... else...`. The if-condition contains a function involving one or multiple features and a boolean output. Decision lists are born with good interpretability and can be visualized in a tree structure. Many research on decision lists is driven by medical applications, where the interpretability is almost as crucial as the model itself.

下面简要介绍几种决策列表：

> A few types of decision lists are briefly described below:

• [递减规则列表（FRL）](http://proceedings.mlr.press/v38/wang15a.pdf)（Wang 和 Rudin，2015）对特征值完全强制了单调性。一个关键点，例如在二元分类的背景下，是与每个规则相关的预测概率 $Y=1$ 随着决策列表的向下移动而减小。

• [贝叶斯规则列表（BRL）](https://arxiv.org/abs/1511.01644)（Letham 等人，2015）是一个生成模型，它产生可能决策列表的后验分布。

• [可解释决策集（IDS）](https://cs.stanford.edu/people/jure/pubs/interpretable-kdd16.pdf)（Lakkaraju, Bach & Leskovec, 2016）是一个用于创建一组分类规则的预测框架。学习同时针对准确性和可解释性进行优化。IDS 与我[稍后](https://lilianweng.github.io/posts/2017-08-01-interpretation/#beta-black-box-explanation-through-transparent-approximations)将描述的用于解释黑盒模型的 BETA 方法密切相关。

英文原文：

• [Falling Rule Lists (FRL)](http://proceedings.mlr.press/v38/wang15a.pdf) (Wang and Rudin, 2015) has fully enforced monotonicity on feature values. One key point, for example in the binary classification context, is that the probability of prediction $Y=1$ associated with each rule decreases as one moves down the decision lists.

• [Bayesian Rule List (BRL)](https://arxiv.org/abs/1511.01644) (Letham et al., 2015) is a generative model that yields a posterior distribution over possible decision lists.

• [Interpretable Decision Sets (IDS)](https://cs.stanford.edu/people/jure/pubs/interpretable-kdd16.pdf) (Lakkaraju, Bach & Leskovec, 2016) is a prediction framework to create a set of classification rules. The learning is optimized for both accuracy and interpretability simultaneously. IDS is closely related to the BETA method I’m gonna describe [later](https://lilianweng.github.io/posts/2017-08-01-interpretation/#beta-black-box-explanation-through-transparent-approximations) for interpreting black-box models.

#### 随机森林

> Random Forests

奇怪的是，许多人认为[随机森林](http://www.math.univ-toulouse.fr/~agarivie/Telecom/apprentissage/articles/randomforest2001.pdf)模型是一个黑盒，但事实并非如此。考虑到随机森林的输出是大量独立决策树的多数投票，并且每棵树本身都是可解释的。

> Weirdly enough, many people believe that the [Random Forests](http://www.math.univ-toulouse.fr/~agarivie/Telecom/apprentissage/articles/randomforest2001.pdf) model is a black box, which is not true. Considering that the output of random forests is the majority vote by a large number of independent decision trees and each tree is naturally interpretable.

如果我们一次只查看一棵树，那么衡量单个特征的影响并不难。随机森林的全局特征重要性可以通过集成中所有树的节点不纯度总减少量（“平均不纯度减少”）来量化。

> It is not very hard to gauge the influence of individual features if we look into a single tree at a time. The global feature importance of random forests can be quantified by the total decrease in node impurity averaged over all trees of the ensemble (“mean decrease impurity”).

例如，由于所有树中的决策路径都得到了很好的跟踪，我们可以使用父节点中数据点的平均值与子节点中数据点的平均值之间的差异来近似此分割的贡献。在此系列博客文章中阅读更多内容：[解释随机森林](http://blog.datadive.net/interpreting-random-forests/)。

> For one instance, because the decision paths in all the trees are well tracked, we can use the difference between the mean value of data points in a parent node between that of a child node to approximate the contribution of this split. Read more in this series of blog posts: [Interpreting Random Forests](http://blog.datadive.net/interpreting-random-forests/).

### 解释黑盒模型

> Interpreting Black-Box Models

许多模型并非设计为可解释的。解释黑盒模型的方法旨在从训练好的模型中提取信息，以证明其预测结果的合理性，而无需了解模型的详细工作原理。使解释过程独立于模型实现对于实际应用很有好处：即使基础模型不断升级和完善，在其之上构建的解释引擎也无需担心这些变化。

> A lot of models are not designed to be interpretable. Approaches to explaining a black-box model aim to extract information from the trained model to justify its prediction outcome, without knowing how the model works in details. To keep the interpretation process independent from the model implementation is good for real-world applications: Even when the base model is being constantly upgraded and refined, the interpretation engine built on top would not worry about the changes.

无需担心保持模型透明和可解释，我们可以通过添加更多参数和非线性计算来赋予模型更强的表达能力。这就是深度神经网络在涉及丰富输入的任务中取得成功的原因。

> Without the concern of keeping the model transparent and interpretable, we can endow the model with greater power of expressivity by adding more parameters and nonlinearity computation. That’s how deep neural networks become successful in tasks involving rich inputs.

对于解释的呈现方式没有严格要求，但主要目标是回答：**我能信任这个模型吗？**当我们依赖模型做出关键或生死攸关的决策时，我们必须提前确保模型是值得信赖的。

> There is no hard requirement on how the explanation should be presented, but the primary goal is mainly to answer: **Can I trust this model?** When we rely on the model to make a critical or life-and-death decision, we have to make sure the model is trustworthy ahead of time.

解释框架应在两个目标之间取得平衡：

> The interpretation framework should balance between two goals:

- **忠实性**：解释产生的预测应尽可能与原始模型一致。
- **可解释性**：解释应足够简单，以便人类理解。

> • **Fidelity**: the prediction produced by an explanation should agree with the original model as much as possible.
> • **Interpretability**: the explanation should be simple enough to be human-understandable.

> 旁注：接下来的三种方法是为局部解释设计的。

> Side Notes: The next three methods are designed for local interpretation.

#### 预测分解

> Prediction Decomposition

[Robnik-Sikonja 和 Kononenko (2008)](http://lkm.fri.uni-lj.si/rmarko/papers/RobnikSikonjaKononenko08-TKDE.pdf) 提出通过测量原始预测与省略一组特征后做出的预测之间的差异来解释模型对一个实例的预测。

> [Robnik-Sikonja and Kononenko (2008)](http://lkm.fri.uni-lj.si/rmarko/papers/RobnikSikonjaKononenko08-TKDE.pdf) proposed to explain the model prediction for one instance by measuring the difference between the original prediction and the one made with omitting a set of features.

假设我们需要为分类模型生成解释$f: \mathbf{X} \rightarrow \mathbf{Y}$。给定数据点$x \in X$，它由$a$个属性$A_i$、$i = 1, \dots, a$的独立值组成，并被标记为类别$y \in Y$。通过计算模型在已知或未知$A_i$时的预测概率差异来量化*预测差异*：

> Let’s say we need to generate an explanation for a classification model $f: \mathbf{X} \rightarrow \mathbf{Y}$. Given a data point $x \in X$ which consists of $a$ individual values of attribute $A_i$, $i = 1, \dots, a$, and is labeled with class $y \in Y$. The *prediction difference* is quantified by computing the difference between the model predicted probabilities with or without knowing $A_i$:

$$
\text{probDiff}_i (y | x)  = p(y| x) - p(y | x \backslash A_i)
$$

(该论文还讨论了使用优势比或基于熵的信息度量来量化预测差异。)

> (The paper also discussed on using the odds ratio or the entropy-based information metric to quantify the prediction difference.)

**问题**: 如果目标模型输出概率，那么很好，获取 $p(y \vert x)$ 就很简单。否则，模型预测必须经过适当的后建模校准，才能将预测分数转换为概率。这个校准层是另一个复杂之处。

英文原文：Problem: If the target model outputs a probability, then great, getting 

$p(y \vert x)$ is straightforward. Otherwise, the model prediction has to run through an appropriate post-modeling calibration to translate the prediction score into probabilities. This calibration layer is another piece of complication.

**另一个问题**：如果我们生成$x \backslash A_i$通过替换`A_i`为缺失值（例如`None`、`NaN`等），我们就必须依赖模型内部的缺失值插补机制。一个用中位数替换这些缺失情况的模型，其输出应该与一个用特殊占位符进行插补的模型大相径庭。论文中提出的一种解决方案是替换`A_i`为该特征的所有可能值，然后将预测结果按每个值在数据中出现的可能性进行加权求和：

英文原文：Another problem: If we generate 

$x \backslash A_i$ by replacing `A_i` with a missing value (like `None`, `NaN`, etc.), we have to rely on the model’s internal mechanism for missing value imputation. A model which replaces these missing cases with the median should have output very different from a model which imputes a special placeholder. One solution as presented in the paper is to replace `A_i` with all possible values of this feature and then sum up the prediction weighted by how likely each value shows in the data:

$$
\begin{aligned}
p(y \vert x \backslash A_i)
&= \sum_{s=1}^{m_i} p(A_i=a_s \vert x \backslash A_i) p(y \vert x \leftarrow A_i=a_s) \\
&\approx \sum_{s=1}^{m_i} p(A_i=a_s) p(y \vert x \leftarrow A_i=a_s)
\end{aligned}
$$

其中$p(y \vert x \leftarrow A_i=a_s)$是获得标签$y$如果我们用$A_i$的值$a_s$在$x$。有$m_i$个$A_i$在训练集中。

> Where $p(y \vert x \leftarrow A_i=a_s)$ is the probability of getting label $y$ if we replace the feature $A_i$ with value $a_s$ in the feature vector of $x$. There are $m_i$ unique values of $A_i$ in the training set.

借助省略已知特征时的预测差异度量，我们可以*分解*每个独立特征对预测的影响。

> With the help of the measures of prediction difference when omitting known features, we can *decompose* the impact of each individual feature on the prediction.

![Explanations for a SVM model predicting the survival of one male adult first-class passenger in the Titanic dataset . The information difference is very similar to the probability difference, but it measures the amount of information necessary to find out $y$ is true for the given instance without the knowledge of $A\_i$: $\text{infDiff}\_i (y|x) = \log\_2 p(y|x) - \log\_2 p(y|x \backslash A\_i)$. Explanations for particular instance are depicted with dark bars. The light shaded half-height bars are average positive and negative explanations for given attributes' values. In this case, being a male adult makes it very less likely to survive; the class level does not impact as much.](https://lilianweng.github.io/posts/2017-08-01-interpretation/interpretability_prediction_decomposition.png)

#### 局部梯度解释向量

> Local Gradient Explanation Vector

这种方法（[Baehrens 等人，2010](http://www.jmlr.org/papers/volume11/baehrens10a/baehrens10a.pdf)）能够解释任意非线性分类算法所做的局部决策，它利用局部梯度来描述数据点需要如何移动才能改变其预测标签。

> This method ([Baehrens, et al. 2010](http://www.jmlr.org/papers/volume11/baehrens10a/baehrens10a.pdf)) is able to explain the local decision taken by arbitrary nonlinear classification algorithms, using the local gradients that characterize how a data point has to be moved to change its predicted label.

假设我们有一个[贝叶斯分类器](https://en.wikipedia.org/wiki/Bayes_classifier)，它在数据集$X$上进行训练，并输出类别标签$Y$, $p(Y=y \vert X=x)$的概率。并且一个类别标签$y$是从类别标签池$\{1, 2, \dots, C\}$中抽取的。这个贝叶斯分类器构建如下：

> Let’s say, we have a [Bayes Classifier](https://en.wikipedia.org/wiki/Bayes_classifier) which is trained on the data set $X$ and outputs probabilities over the class labels $Y$, $p(Y=y \vert X=x)$. And one class label $y$ is drawn from the class label pool, $\{1, 2, \dots, C\}$. This Bayes classifier is constructed as:

$$
f^{*}(x)  = \arg \min_{c \in \{1, \dots, C\}} p(Y \neq c \vert X = x)
$$

*局部解释向量*被定义为测试点处概率预测函数的导数$x = x_0$。该向量中的一个大条目突出显示了对模型决策有重大影响的特征；正号表示增加该特征会降低$x_0$分配给$f^{*}(x_0)$的概率。

> The *local explanation vector* is defined as the derivative of the probability prediction function at the test point $x = x_0$. A large entry in this vector highlights a feature with a big influence on the model decision; A positive sign indicates that increasing the feature would lower the probability of $x_0$ assigned to $f^{*}(x_0)$.

然而，这种方法要求模型输出是概率（类似于上面[“预测分解”](https://lilianweng.github.io/posts/2017-08-01-interpretation/#prediction-decomposition)方法）。如果原始模型（标记为$f$）未校准以产生概率怎么办？正如论文所建议的，我们可以通过另一个分类器来近似$f$，其形式类似于贝叶斯分类器$f^{*}$：

> However, this approach requires the model output to be a probability (similar to the [“Prediction Decomposition”](https://lilianweng.github.io/posts/2017-08-01-interpretation/#prediction-decomposition) method above). What if the original model (labelled as $f$) is not calibrated to yield probabilities? As suggested by the paper, we can approximate $f$ by another classifier in a form that resembles the Bayes classifier $f^{*}$:

(1) 将[Parzen窗](https://en.wikipedia.org/?title=Parzen_window&redirect=no)应用于训练数据以估计加权类别密度：

> (1) Apply [Parzen window](https://en.wikipedia.org/?title=Parzen_window&redirect=no) to the training data to estimate the weighted class densities:

$$
\hat{p}_{\sigma}(x, y=c) = \frac{1}{n} \sum_{i \in I_c} k_{\sigma} (x - x_i)
$$

其中$I_c$是包含分配给类$c$的数据点索引的索引集，由模型$f$，$I_c = \{i \vert f(x_i) = c\}$。$k_{\sigma}$是一个核函数。高斯核是其中一个流行的[众多候选者](https://en.wikipedia.org/wiki/Kernel_(statistics)#Kernel_functions_in_common_use)。

> Where $I_c$ is the index set containing the indices of data points assigned to class $c$ by the model $f$, $I_c = \{i \vert f(x_i) = c\}$. $k_{\sigma}$ is a kernel function. Gaussian kernel is a popular one among [many candidates](https://en.wikipedia.org/wiki/Kernel_(statistics)#Kernel_functions_in_common_use).

(2) 然后，应用贝叶斯规则来近似概率 $p(Y=c \vert X=x)$ 对于所有类别：

> (2) Then, apply the Bayes’ rule to approximate the probability $p(Y=c \vert X=x)$ for all classes:

$$
\begin{aligned}
\hat{p}_{\sigma}(y=c | x)
&= \frac{\hat{p}_{\sigma}(x, y=c)}{\hat{p}_{\sigma}(x, y=c) + \hat{p}_{\sigma}(x, y \neq c)} \\
&\approx \frac{\sum_{i \in I_c} k_{\sigma} (x - x_i)}{\sum_i k_{\sigma} (x - x_i)}
\end{aligned}
$$

(3) 最终估计的贝叶斯分类器形式如下：

> (3) The final estimated Bayes classifier takes the form:

$$
\hat{f}_{\sigma} = \arg\min_{c \in \{1, \dots, C\}} \hat{p}_{\sigma}(y \neq c \vert x)
$$

值得注意的是，我们可以使用原始模型 $f$ 生成任意数量的标注数据，不受训练数据大小的限制。选择超参数 $\sigma$ 是为了优化 $\hat{f}_{\sigma}(x) = f(x)$ 实现高保真度的机会。

> Noted that we can generate the labeled data with the original model $f$, as much as we want, not restricted by the size of the training data. The hyperparameter $\sigma$ is selected to optimize the chances of $\hat{f}_{\sigma}(x) = f(x)$ to achieve high fidelity.

![An example of how local gradient explanation vector is applied on simple object classification with Gaussian Processes Classifier (GPC). The GPC model outputs the probability by nature. (a) shows the training points and their labels in red (positive 1) and blue (negative -1). (b) illustrates a probability function for the positive class. (c-d) shows the local gradients and the directions of the local explanation vectors.](https://lilianweng.github.io/posts/2017-08-01-interpretation/interpretability_local_gradient.png)

> 旁注：如您所见，上述两种方法都要求模型预测结果是概率。模型输出的校准又增加了一层复杂性。

> Side notes: As you can see both the methods above require the model prediction to be a probability. Calibration of the model output adds another layer of complication.

#### LIME（局部可解释模型无关解释）

> LIME (Local Interpretable Model-Agnostic Explanations)

[LIME](https://github.com/marcotcr/lime)，是*局部可解释模型无关解释*的缩写，可以在我们感兴趣的预测附近局部近似一个黑盒模型([Ribeiro, Singh, & Guestrin, 2016](https://arxiv.org/pdf/1602.04938.pdf))。

> [LIME](https://github.com/marcotcr/lime), short for *local interpretable model-agnostic explanation*, can approximate a black-box model locally in the neighborhood of the prediction we are interested ([Ribeiro, Singh, & Guestrin, 2016](https://arxiv.org/pdf/1602.04938.pdf)).

同上，我们将黑盒模型标记为 $f$。LIME 提出了以下步骤：

> Same as above, let us label the black-box model as $f$. LIME presents the following steps:

(1) 将数据集转换为可解释的数据表示形式：$x \Rightarrow x_b$。

> (1) Convert the dataset into interpretable data representation: $x \Rightarrow x_b$.

- 文本分类器：一个二元向量，表示某个词是否存在
- 图像分类器：一个二元向量，表示是否存在连续的相似像素块（超像素）。

> • Text classifier: a binary vector indicating the presence or absence of a word
> • Image classifier: a binary vector indicating the presence or absence of a contiguous patch of similar pixels (super-pixel).

![An example of converting an image into interpretable data representation. (Image source: www.oreilly.com/learning/introduction-to-local-interpretable-model-agnostic-explanations-lime )](https://lilianweng.github.io/posts/2017-08-01-interpretation/LIME_interpretable_representation.png)

(2) 给定一个预测$f(x)$及其对应的可解释数据表示$x_b$，让我们围绕$x_b$通过抽取$x_b$的非零元素，并均匀随机抽取，其中抽取的数量也是均匀采样的。这个过程生成了一个扰动样本$z_b$，它包含$x_b$的非零元素的一部分。

> (2) Given a prediction $f(x)$ with the corresponding interpretable data representation $x_b$, let us sample instances around $x_b$ by drawing nonzero elements of $x_b$ uniformly at random where the number of such draws is also uniformly sampled. This process generates a perturbed sample $z_b$ which contains a fraction of nonzero elements of $x_b$.

然后我们将 $z_b$ 恢复到原始输入 $z$ 中，并通过目标模型获得预测分数 $f(z)$。

> Then we recover $z_b$ back into the original input $z$ and get a prediction score $f(z)$ by the target model.

使用许多这样的采样数据点 $z_b \in \mathcal{Z}_b$ 及其模型预测，我们可以学习一个具有局部忠实度的解释模型（例如，形式简单如回归模型）。采样数据点根据它们与 $x_b$ 的接近程度进行不同的加权。该论文使用了一种套索回归（lasso regression），并进行了预处理以预先选择前 $k$ 个最重要的特征，命名为“K-LASSO”。

> Use many such sampled data points $z_b \in \mathcal{Z}_b$ and their model predictions, we can learn an explanation model (such as in a form as simple as a regression) with local fidelity. The sampled data points are weighted differently based on how close they are to $x_b$. The paper used a lasso regression with preprocessing to select top $k$ most significant features beforehand, named “K-LASSO”.

![The pink and blue areas are two classes predicted by the black-box model $f$. the big red cross is the point to be explained and other smaller crosses (predicted as pink by $f$) and dots (predicted as blue by $f$) are sampled data points. Even though the model can be very complicated, we are still able to learn a local explanation model as simple as the grey dash line. (Image source: homes.cs.washington.edu/~marcotcr/blog/lime )](https://lilianweng.github.io/posts/2017-08-01-interpretation/LIME_illustration.png)

检查解释是否合理可以直接决定模型是否值得信任，因为有时模型可能会捕捉到虚假相关性或过度泛化。论文中一个有趣的例子是将 LIME 应用于一个 SVM 文本分类器，用于区分“基督教”和“无神论”。该模型取得了相当不错的准确率（在保留测试集上达到 94%！），但 LIME 的解释表明，决策是基于非常随意的理由做出的，例如统计“re”、“posting”和“host”这些与“基督教”或“无神论”都没有直接关联的词语。经过这样的诊断，我们了解到即使模型给出了不错的准确率，它也可能不值得信任。这也为改进模型提供了思路，例如对文本进行更好的预处理。

> Examining whether the explanation makes sense can directly decide whether the model is trustworthy because sometimes the model can pick up spurious correlation or generalization. One interesting example in the paper is to apply LIME on an SVM text classifier for differentiating “Christianity” from “Atheism”. The model achieved a pretty good accuracy (94% on held-out testing set!), but the LIME explanation demonstrated that decisions were made by very arbitrary reasons, such as counting the words “re”, “posting” and “host” which have no connection with neither “Christianity” nor “Atheism” directly. After such a diagnosis, we learned that even the model gives us a nice accuracy, it cannot be trusted. It also shed lights on ways to improve the model, such as better preprocessing on the text.

![Illustration of how to use LIME on an image classifier. (Image source: www.oreilly.com/learning/introduction-to-local-interpretable-model-agnostic-explanations-lime )](https://lilianweng.github.io/posts/2017-08-01-interpretation/LIME.png)

有关更详细的非论文解释，请阅读作者的[这篇博客文章](https://www.oreilly.com/learning/introduction-to-local-interpretable-model-agnostic-explanations-lime)。非常值得一读。

> For more detailed non-paper explanation, please read [this blog post](https://www.oreilly.com/learning/introduction-to-local-interpretable-model-agnostic-explanations-lime) by the author. A very nice read.

> 旁注：局部解释模型应该比全局解释模型更容易，但维护起来更困难（考虑到[维度灾难](https://en.wikipedia.org/wiki/Curse_of_dimensionality)）。下面描述的方法旨在解释模型的整体行为。然而，全局方法无法捕捉细粒度的解释，例如某个特征可能在此区域很重要，但在另一个区域则完全不重要。

> Side Notes: Interpreting a model locally is supposed to be easier than interpreting the model globally, but harder to maintain (thinking about the [curse of dimensionality](https://en.wikipedia.org/wiki/Curse_of_dimensionality)). Methods described below aim to explain the behavior of a model as a whole. However, the global approach is unable to capture the fine-grained interpretation, such as a feature might be important in this region but not at all in another.

#### 特征选择

> Feature Selection

本质上，所有经典的特征选择方法（[Yang and Pedersen, 1997](http://www.surdeanu.info/mihai/teaching/ista555-spring15/readings/yang97comparative.pdf)；[Guyon and Elisseeff, 2003](http://www.jmlr.org/papers/volume3/guyon03a/guyon03a.pdf)）都可以被视为全局解释模型的方式。特征选择方法分解了多个特征的贡献，因此我们可以通过单个特征的影响来解释模型的整体输出。

> Essentially all the classic feature selection methods ([Yang and Pedersen, 1997](http://www.surdeanu.info/mihai/teaching/ista555-spring15/readings/yang97comparative.pdf); [Guyon and Elisseeff, 2003](http://www.jmlr.org/papers/volume3/guyon03a/guyon03a.pdf)) can be considered as ways to explain a model globally. Feature selection methods decompose the contribution of multiple features so that we can explain the overall model output by individual feature impact.

关于特征选择的资源非常多，因此我将在本文中跳过这个话题。

> There are a ton of resources on feature selection so I would skip the topic in this post.

#### BETA（通过透明近似的黑盒解释）

> BETA (Black Box Explanation through Transparent Approximations)

[BETA](https://arxiv.org/abs/1707.01154)，是*通过透明近似的黑盒解释*的缩写，与[可解释决策集](https://cs.stanford.edu/people/jure/pubs/interpretable-kdd16.pdf)（Lakkaraju, Bach & Leskovec, 2016）密切相关。BETA 学习一个紧凑的两级决策集，其中每个规则都明确地解释了模型行为的一部分。

> [BETA](https://arxiv.org/abs/1707.01154), short for *black box explanation through transparent approximations*, is closely connected to [Interpretable Decision Sets](https://cs.stanford.edu/people/jure/pubs/interpretable-kdd16.pdf) (Lakkaraju, Bach & Leskovec, 2016). BETA learns a compact two-level decision set in which each rule explains part of the model behavior unambiguously.

作者提出了一种新颖的目标函数，使得学习过程针对**高保真度**（解释与模型之间的高度一致性）、**低模糊性**（解释中决策规则之间的重叠很少）和**高可解释性**（解释决策集轻量且小巧）进行优化。这些方面被组合成一个目标函数进行优化。

> The authors proposed an novel objective function so that the learning process is optimized for **high fidelity** (high agreement between explanation and the model), **low unambiguity** (little overlaps between decision rules in the explanation), and **high interpretability** (the explanation decision set is lightweight and small). These aspects are combined into one objection function to optimize for.

![Measures for desiderata of a good model explanation: fidelity, unambiguity, and interpretability. Given the target model is $\mathcal{B}$, its explanation is a two level decision set $\Re$ containing a set of rules ${(q\_1, s\_1, c\_1), \dots, (q\_M, s\_M, c\_M)}$, where $q\_i$ and $s\_i$ are conjunctions of predicates of the form (feature, operator, value) and $c\_i$ is a class label. Check the paper for more details. (Image source: arxiv.org/abs/1707.01154 )](https://lilianweng.github.io/posts/2017-08-01-interpretation/BETA.png)

### 可解释人工智能

> Explainable Artificial Intelligence

本节的名称借鉴了 DARPA 项目[“可解释人工智能”](https://www.darpa.mil/program/explainable-artificial-intelligence)。这个可解释人工智能（XAI）项目旨在开发更具可解释性的模型，并使人类能够理解、适当信任并有效管理新兴的人工智能技术。

> I borrow the name of this section from the DARPA project [“Explainable Artificial Intelligence”](https://www.darpa.mil/program/explainable-artificial-intelligence). This Explainable AI (XAI) program aims to develop more interpretable models and to enable human to understand, appropriately trust, and effectively manage the emerging generation of artificially intelligent techniques.

随着深度学习应用的进展，人们开始担心[即使模型出现问题，我们也可能永远不知道](https://www.technologyreview.com/s/601860/if-a-driverless-car-goes-bad-we-may-never-know-why/)。复杂的结构、大量的可学习参数、非线性数学运算以及[一些有趣的特性](https://arxiv.org/abs/1312.6199)（Szegedy et al., 2014）导致了深度神经网络的不可解释性，形成了一个真正的黑盒。尽管深度学习的力量源于这种复杂性——它更灵活地捕捉真实世界数据中丰富而复杂的模式。

> With the progress of the deep learning applications, people start worrying about that [we may never know even if the model goes bad](https://www.technologyreview.com/s/601860/if-a-driverless-car-goes-bad-we-may-never-know-why/). The complicated structure, the large number of learnable parameters, the nonlinear mathematical operations and [some intriguing properties](https://arxiv.org/abs/1312.6199) (Szegedy et al., 2014) lead to the un-interpretability of deep neural networks, creating a true black-box. Although the power of deep learning is originated from this complexity — more flexible to capture rich and intricate patterns in the real-world data.

关于**对抗性样本**的研究（[OpenAI Blog: Robust Adversarial Examples](https://blog.openai.com/robust-adversarial-inputs/), [Attacking Machine Learning with Adversarial Examples](https://blog.openai.com/adversarial-example-research/), [Goodfellow, Shlens & Szegedy, 2015](https://arxiv.org/pdf/1412.6572.pdf); [Nguyen, Yosinski, & Clune, 2015](http://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Nguyen_Deep_Neural_Networks_2015_CVPR_paper.pdf)）对人工智能应用的鲁棒性和安全性敲响了警钟。有时模型可能会表现出意想不到、出乎预料且不可预测的行为，而我们没有快速/好的策略来解释原因。

> Studies on **adversarial examples** ([OpenAI Blog: Robust Adversarial Examples](https://blog.openai.com/robust-adversarial-inputs/), [Attacking Machine Learning with Adversarial Examples](https://blog.openai.com/adversarial-example-research/), [Goodfellow, Shlens & Szegedy, 2015](https://arxiv.org/pdf/1412.6572.pdf); [Nguyen, Yosinski, & Clune, 2015](http://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Nguyen_Deep_Neural_Networks_2015_CVPR_paper.pdf)) raise the alarm on the robustness and safety of AI applications. Sometimes the models could show unintended, unexpected and unpredictable behavior and we have no fast/good strategy to tell why.

![Illustrations of adversarial examples. (a-d) are adversarial images that are generated by adding human-imperceptible noises onto original images ( Szegedy et al., 2013 ). A well-trained neural network model can successfully classify original ones but fail adversarial ones. (e-h) are patterns that are generated ( Nguyen, Yosinski & Clune, 2015 ). A well-trained neural network model labels them into (e) school bus, (f) guitar, (g) peacock and (h) Pekinese respectively. (Image source: Wang, Raj & Xing, 2017 )](https://lilianweng.github.io/posts/2017-08-01-interpretation/adversarial_examples.png)

英伟达最近开发了[一种方法来可视化其自动驾驶汽车决策过程中最重要的像素点](https://blogs.nvidia.com/blog/2017/04/27/how-nvidias-neural-net-makes-decisions/)。这种可视化提供了关于人工智能如何思考以及系统在操作汽车时依赖什么的信息。如果人工智能认为重要的内容与人类做出类似决策的方式一致，我们自然可以对黑盒模型获得更多信心。

> Nvidia recently developed [a method to visualize the most important pixel points](https://blogs.nvidia.com/blog/2017/04/27/how-nvidias-neural-net-makes-decisions/) in their self-driving cars’ decisioning process. The visualization provides insights on how AI thinks and what the system relies on while operating the car. If what the AI believes to be important agrees with how human make similar decisions, we can naturally gain more confidence in the black-box model.

在这个不断发展的领域，每天都有许多令人兴奋的新闻和发现。希望我的文章能给你一些指引，并鼓励你更深入地研究这个话题 :)

> Many exciting news and findings are happening in this evolving field every day. Hope my post can give you some pointers and encourage you to investigate more into this topic :)

引用为：

> Cited as:

```
@article{weng2017gan,
  title   = "How to Explain the Prediction of a Machine Learning Model?",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2017",
  url     = "https://lilianweng.github.io/posts/2017-08-01-interpretation/"
}
```

### 参考文献

> References

[1] Zachary C. Lipton. [“The mythos of model interpretability.”](https://arxiv.org/pdf/1606.03490.pdf) arXiv preprint arXiv:1606.03490 (2016)。

> [1] Zachary C. Lipton. [“The mythos of model interpretability.”](https://arxiv.org/pdf/1606.03490.pdf) arXiv preprint arXiv:1606.03490 (2016).

[2] Been Kim, Rajiv Khanna, and Oluwasanmi O. Koyejo. “Examples are not enough, learn to criticize! criticism for interpretability.” Advances in Neural Information Processing Systems. 2016。

> [2] Been Kim, Rajiv Khanna, and Oluwasanmi O. Koyejo. “Examples are not enough, learn to criticize! criticism for interpretability.” Advances in Neural Information Processing Systems. 2016.

[3] Himabindu Lakkaraju, Stephen H. Bach, and Jure Leskovec. [“Interpretable decision sets: A joint framework for description and prediction.”](http://www.kdd.org/kdd2016/papers/files/rpp1067-lakkarajuA.pdf) Proc. 22nd ACM SIGKDD Intl. Conf. on Knowledge Discovery and Data Mining. ACM, 2016。

> [3] Himabindu Lakkaraju, Stephen H. Bach, and Jure Leskovec. [“Interpretable decision sets: A joint framework for description and prediction.”](http://www.kdd.org/kdd2016/papers/files/rpp1067-lakkarajuA.pdf) Proc. 22nd ACM SIGKDD Intl. Conf. on Knowledge Discovery and Data Mining. ACM, 2016.

[4] Robnik-Šikonja, Marko, and Igor Kononenko. [“Explaining classifications for individual instances.”](http://lkm.fri.uni-lj.si/rmarko/papers/RobnikSikonjaKononenko08-TKDE.pdf) IEEE Transactions on Knowledge and Data Engineering 20.5 (2008): 589-600。

> [4] Robnik-Šikonja, Marko, and Igor Kononenko. [“Explaining classifications for individual instances.”](http://lkm.fri.uni-lj.si/rmarko/papers/RobnikSikonjaKononenko08-TKDE.pdf) IEEE Transactions on Knowledge and Data Engineering 20.5 (2008): 589-600.

[5] Baehrens, David, et al. [“How to explain individual classification decisions.”](http://www.jmlr.org/papers/volume11/baehrens10a/baehrens10a.pdf) Journal of Machine Learning Research 11.Jun (2010): 1803-1831。

> [5] Baehrens, David, et al. [“How to explain individual classification decisions.”](http://www.jmlr.org/papers/volume11/baehrens10a/baehrens10a.pdf) Journal of Machine Learning Research 11.Jun (2010): 1803-1831.

[6] Marco Tulio Ribeiro, Sameer Singh, and Carlos Guestrin. [“Why should I trust you?: Explaining the predictions of any classifier.”](https://arxiv.org/pdf/1602.04938.pdf) Proc. 22nd ACM SIGKDD Intl. Conf. on Knowledge Discovery and Data Mining. ACM, 2016。

> [6] Marco Tulio Ribeiro, Sameer Singh, and Carlos Guestrin. [“Why should I trust you?: Explaining the predictions of any classifier.”](https://arxiv.org/pdf/1602.04938.pdf) Proc. 22nd ACM SIGKDD Intl. Conf. on Knowledge Discovery and Data Mining. ACM, 2016.

[7] Yiming Yang 和 Jan O. Pedersen。[“文本分类中特征选择的比较研究。”](http://www.surdeanu.info/mihai/teaching/ista555-spring15/readings/yang97comparative.pdf) 国际机器学习会议。第 97 卷。1997。

> [7] Yiming Yang, and Jan O. Pedersen. [“A comparative study on feature selection in text categorization.”](http://www.surdeanu.info/mihai/teaching/ista555-spring15/readings/yang97comparative.pdf) Intl. Conf. on Machine Learning. Vol. 97. 1997.

[8] Isabelle Guyon 和 André Elisseeff。[“变量和特征选择导论。”](http://www.jmlr.org/papers/volume3/guyon03a/guyon03a.pdf) 机器学习研究杂志 3.Mar (2003): 1157-1182。

> [8] Isabelle Guyon, and André Elisseeff. [“An introduction to variable and feature selection.”](http://www.jmlr.org/papers/volume3/guyon03a/guyon03a.pdf) Journal of Machine Learning Research 3.Mar (2003): 1157-1182.

[9] Ian J. Goodfellow, Jonathon Shlens 和 Christian Szegedy。[“解释和利用对抗性样本。”](https://arxiv.org/pdf/1412.6572.pdf) ICLR 2015。

> [9] Ian J. Goodfellow, Jonathon Shlens, and Christian Szegedy. [“Explaining and harnessing adversarial examples.”](https://arxiv.org/pdf/1412.6572.pdf)  ICLR 2015.

[10] Christian Szegedy, Wojciech Zaremba, Ilya Sutskever, Joan Bruna, Dumitru Erhan, Ian Goodfellow, Rob Fergus。[“神经网络的有趣特性。”](https://arxiv.org/abs/1312.6199) 国际学习表示会议 (2014)

> [10] Christian Szegedy, Wojciech Zaremba, Ilya Sutskever, Joan Bruna, Dumitru Erhan, Ian Goodfellow, Rob Fergus. [“Intriguing properties of neural networks.”](https://arxiv.org/abs/1312.6199) Intl. Conf. on Learning Representations (2014)

[11] Nguyen, Anh, Jason Yosinski 和 Jeff Clune。[“深度神经网络易受欺骗：对无法识别图像的高置信度预测。”](http://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Nguyen_Deep_Neural_Networks_2015_CVPR_paper.pdf) IEEE 计算机视觉与模式识别会议论文集。2015。

> [11] Nguyen, Anh, Jason Yosinski, and Jeff Clune. [“Deep neural networks are easily fooled: High confidence predictions for unrecognizable images.”](http://www.cv-foundation.org/openaccess/content_cvpr_2015/papers/Nguyen_Deep_Neural_Networks_2015_CVPR_paper.pdf) Proc. IEEE Conference on Computer Vision and Pattern Recognition. 2015.

[12] Benjamin Letham, Cynthia Rudin, Tyler H. McCormick 和 David Madigan。[“使用规则和贝叶斯分析的可解释分类器：构建更好的中风预测模型。”](https://arxiv.org/abs/1511.01644) 应用统计年鉴 9, No. 3 (2015): 1350-1371。

> [12] Benjamin Letham, Cynthia Rudin, Tyler H. McCormick, and David Madigan. [“Interpretable classifiers using rules and Bayesian analysis: Building a better stroke prediction model.”](https://arxiv.org/abs/1511.01644) The Annals of Applied Statistics 9, No. 3 (2015): 1350-1371.

[13] Haohan Wang, Bhiksha Raj 和 Eric P. Xing。[“论深度学习的起源。”](https://arxiv.org/pdf/1702.07800.pdf) arXiv 预印本 arXiv:1702.07800 (2017)。

> [13] Haohan Wang, Bhiksha Raj, and Eric P. Xing. [“On the Origin of Deep Learning.”](https://arxiv.org/pdf/1702.07800.pdf) arXiv preprint arXiv:1702.07800 (2017).

[14] [OpenAI 博客：鲁棒对抗性样本](https://blog.openai.com/robust-adversarial-inputs/)

> [14] [OpenAI Blog: Robust Adversarial Examples](https://blog.openai.com/robust-adversarial-inputs/)

[15] [使用对抗性样本攻击机器学习](https://blog.openai.com/adversarial-example-research/)

> [15] [Attacking Machine Learning with Adversarial Examples](https://blog.openai.com/adversarial-example-research/)

[16] [解读人工智能汽车的“思想”：NVIDIA 神经网络如何做出决策](https://blogs.nvidia.com/blog/2017/04/27/how-nvidias-neural-net-makes-decisions/)

> [16] [Reading an AI Car’s Mind: How NVIDIA’s Neural Net Makes Decisions](https://blogs.nvidia.com/blog/2017/04/27/how-nvidias-neural-net-makes-decisions/)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Machine Learning Model | 机器学习模型 | 一种通过从数据中学习模式来执行特定任务的计算机程序。 |
| Interpretability | 可解释性 | 理解机器学习模型如何做出决策的能力。 |
| Black Box Model | 黑盒模型 | 内部工作原理不透明，难以理解其决策过程的机器学习模型。 |
| Deep Learning | 深度学习 | 机器学习的一个子领域，使用多层神经网络从数据中学习表示。 |
| Linear Regression | 线性回归 | 一种统计模型，通过拟合线性方程来建模因变量与一个或多个自变量之间的关系。 |
| Naive Bayes | 朴素贝叶斯 | 一种基于贝叶斯定理和特征独立性假设的简单概率分类器。 |
| Decision Tree | 决策树 | 一种树状模型，通过一系列决策规则来预测目标变量。 |
| Random Forest | 随机森林 | 一种集成学习方法，通过构建多个决策树并取其多数投票来提高预测准确性。 |
| Fidelity | 忠实性 | 解释模型产生的预测与原始模型预测结果的一致程度。 |
| LIME (Local Interpretable Model-agnostic Explanations) | 局部可解释模型无关解释 | 一种解释黑盒模型预测的方法，通过在局部近似原始模型来提供可理解的解释。 |
| Feature Selection | 特征选择 | 从原始特征集中选择最相关特征子集的过程，以提高模型性能和可解释性。 |
| Adversarial Examples | 对抗性样本 | 经过微小扰动，导致机器学习模型做出错误预测的输入数据。 |
| Explainable AI (XAI) | 可解释人工智能 | 旨在开发更具可解释性的AI模型，使人类能够理解、信任和有效管理AI技术的研究领域。 |
| Mean Decrease Impurity | 平均不纯度减少 | 衡量决策树或随机森林中特征重要性的一种指标，基于节点分裂时不纯度的平均减少量。 |
