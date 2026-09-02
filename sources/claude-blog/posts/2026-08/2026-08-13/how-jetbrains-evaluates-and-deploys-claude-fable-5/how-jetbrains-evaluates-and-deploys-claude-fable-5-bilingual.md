# 守护前沿：JetBrains 如何评估和部署 Claude Fable 5

> Securing the frontier: How JetBrains evaluates and deploys Claude Fable 5

> 来源：Claude Blog / Anthropic，2026-08-13
> 原文链接：https://claude.com/blog/how-jetbrains-evaluates-and-deploys-claude-fable-5
> 分类：AI 工程 / 模型评估与部署

## 核心要点

- JetBrains 服务超过 1250 万活跃开发者和《财富》全球 100 强中的 88 家企业，很早就成为大语言模型提供商的客户。
- 过去一年中，JetBrains 公司内外的 AI 怀疑论者几乎都改变了看法，认可 AI 将长期存在。
- JetBrains 在包括自有 monorepo 在内的私有代码库上运行大规模评估集，以检验模型的公开基准分数是否对应真实工作表现。
- 团队维护多份排行榜，分别衡量最佳质量、每任务最低成本和最快速度，Claude Fable 5 虽按 token 计价更贵，但在复杂长时任务中每任务成本反而更低。
- 在 JetBrains 的测试套件中，Claude Fable 5 的 Python 通过率为 44.3%，比 Opus 4.8 的 28.2% 高出 16 个百分点，并在一对一对比中解决了 18 个 Opus 4.8 未解决的任务、仅有 2 个失手。
- Claude Fable 5 达成解决方案所需步骤比 Opus 4.8 少约 22%，且其能运行的代码通过测试的频率更高，减少了最难发现、代价最高的隐性错误。
- 在 Java 任务上，Opus 4.8 反复尝试引入在该环境中几乎无效的外部资源，而 Claude Fable 5 跳过该步骤直接基于现有代码工作。
- Claude Fable 5 被用于需要出色推理的场景，例如一位技术负责人借助它几乎一次实现了多年来多次尝试的富文本编辑器组件。
- 团队让运行 Claude Fable 5 的智能体依据文本与图像规格实现类 IDE 应用，并可由智能体从现有应用反向生成规格，从而在近乎黑盒的条件下跨运行时、框架或语言重写应用。
- JetBrains 不自研安全模型，而是依赖 Anthropic 的红队测试，并围绕模型与外壳构建基础设施和安全网来保障系统化部署。
- 公司用 Claude Fable 5 对自身产品做白盒漏洞测试，并为外部人员使用同类模型探测其产品漏洞做准备，因其客户涉及受监管行业。
- JetBrains 更希望实现零数据留存，但接受将审查限定于被标记的最严重情况，视其为换取前沿智能使用权的公平取舍。
- JetBrains 的下一步是构建面向软件开发的驾驶舱，围绕智能体驱动的软件开发生命周期打造下一代产品，并为组织提供治理能力和投资回报的清晰认知。

## 正文

JetBrains 打造着全球开发者使用的工具，从 IntelliJ IDEA、PyCharm 到 Kotlin 编程语言，服务着超过 1250 万活跃用户以及《财富》全球 100 强中的 88 家企业。JetBrains 首席技术官 Vladislav Tankov 与 Anthropic 探讨了他的团队如何评估新模型、如何决定何时使用 Claude Fable 5，以及在使用前沿模型时如何看待数据留存与安全防护措施。

> JetBrains builds the tools developers use worldwide, from IntelliJ IDEA and PyCharm to the Kotlin programming language, serving more than 12.5 million active users and 88 of the Fortune Global 100. Vladislav Tankov, CTO at JetBrains, spoke with Anthropic about how his team evaluates new models, decides when to use Claude Fable 5, and thinks about data retention and safeguards when working with frontier models.

**2026 年前沿 AI 给 JetBrains 带来了哪些变化？**

> **How has frontier AI changed for JetBrains in 2026?**

我在 JetBrains 工作了 10 年，我们是最早一批 LLM 提供商的客户。在过去的一年里，我们从客户中和公司内部都存在 AI 怀疑论者，转变为看到 AI 将长期存在。这是技术行业中一次重大且根本性的变革。公司里几乎每一个怀疑论者都改变了看法。

> I've been with JetBrains for 10 years, and we were among the very first customers of LLM providers. Over the last year, we moved from having AI skeptics among our customers and inside the company to seeing that AI is here to stay. It's a big and foundational change in the technology industry. Literally every skeptic in the company has changed.

**你如何评估新模型并决定何时使用它们？**

> **How do you evaluate new models and decide when to use them?**

我们是一家做编程的公司，所以我们有一条庞大的评估流水线：在私有代码库（包括我们的 monorepo）上运行大规模评估集。我们会仔细考察一个模型在真实工作中是否真的配得上它的基准测试分数——有些模型经过调优后在公开基准上得分很高，但在实际任务中却表现糟糕。有了私有代码库，这一点就容易检验得多。我们还维护着几份排行榜：最佳质量、每任务最低成本，以及最快的模型。虽然 Claude Fable 5 按 token 计价更贵，但在某些情况下它的每任务成本反而更低，尤其是在更复杂、长时间运行的工作中。

> We're a coding company, so we have a big evaluation pipeline: large eval sets on private repositories, including our monorepo. We take a close look at whether a model lives up to its benchmark scores on real work—some models are tuned to score well on public benchmarks but fall down on actual tasks. With a private repository, that's a lot easier to check. We also keep leaderboards for best quality, best cost per task, and fastest model. While Claude Fable 5 is more expensive per token, its cost per task is lower in some cases, particularly for more complicated, long-running work.

**在你们的评估中，Claude Fable 5 相较于此前的模型表现如何？**

> **How did Claude Fable 5 score on your evals relative to previous models?**

Claude Fable 5 比先前的模型既更准确也更高效。它在我们的测试套件中取得了最佳的 Python 通过率 44.3%，而 Opus 4.8 为 28.2%，提升了 16 个百分点。在一对一的对比中，Claude Fable 5 解决了 18 个 Opus 4.8 未能解决的 Python 任务，而仅有 2 个任务失手。它给出的答案也更可信：当它的代码能够运行时，通过我们测试的频率远高于两个 Opus 模型中的任何一个。这一点很重要，因为能运行却给出错误答案的代码，是最难发现、代价最高的一类失败。

> Claude Fable 5 is both more accurate and more efficient than prior models. It posted the best Python pass rate in our suite at 44.3%, against 28.2% for Opus 4.8, a 16-point jump. In a head-to-head comparison, Claude Fable 5 solved 18 Python tasks that Opus 4.8 missed and lost only 2. Its answers are also more trustworthy: when its code ran, it passed our tests far more often than either Opus model. That matters because code that runs but produces wrong answers is the most expensive kind of failure to catch.

效率方面的表现同样值得关注。Claude Fable 5 达成解决方案所需的步骤比 Opus 4.8 少约 22%，因此它能以更少的试错次数写出可运行的代码。它还把精力用在了正确的地方。在 Java 任务上，Opus 4.8 反复尝试引入在我们的环境中几乎从不起作用的外部资源，而 Claude Fable 5 完全跳过了这一步，直接基于眼前的代码开展工作。更广泛地说，它展现出了更好的工程习惯。

> The efficiency story is just as interesting. Claude Fable 5 needed about 22% fewer steps than Opus 4.8 to reach a solution, so it gets to working code with less trial and error. It also spends its effort in the right places. On Java tasks, Opus 4.8 repeatedly tried to pull in outside resources that almost never help in our environment, while Claude Fable 5 skipped that entirely and worked with the code in front of it. It shows better engineering habits more generally.

**什么时候使用 Claude Fable 5 而不是其他模型？**

> **When do you use Claude Fable 5 over other models?**

Opus 被视为一匹主力：你可以非常确信它能把活干完。当你真正需要出色的推理能力时，当你几乎需要一个伙伴、而你自己也不确定该怎么做这件事时，你会去找 Claude Fable 5。举个例子，我们的一位技术负责人决定实现一个富文本编辑器组件——这是我们多年来尝试过好几次的东西——而 Claude Fable 5 几乎一次就搞定了。

> Opus is seen as a workhorse: you can be very sure it will do the work. You go to Claude Fable 5 when you really need good reasoning, when you almost need a partner, and you're not sure yourself how to do the thing. For example, one of our tech leads decided to implement a rich text editor component we had attempted a few times over the years, and Claude Fable 5 almost one-shotted it.

Claude Fable 5 的另一个热门用例是长时间运行的智能体编程实验。我们为运行 Claude Fable 5 的智能体提供规格说明（以文本和图像的形式），并让它实现复杂的类 IDE 应用。这里有趣的地方在于，规格说明也可以由智能体基于现有应用生成。将这两个环节结合起来，我们就能在近乎黑盒的设定下，把应用从一种运行时、框架或语言重写为另一种。

> Another popular Claude Fable 5 use case is long-running agentic-coding experimentation. We provide an agent running Claude Fable 5 with specifications (in the form of text and images) and make it implement sophisticated IDE-like apps. The interesting thing here is that specifications can also be generated by the agent, based on the existing app. Joining these two components allows us to rewrite the app from one runtime, framework, or language to another in a nearly black-box setup.

**对于当今的前沿模型，你是如何看待安全性与数据保留问题的？**

> **How are you thinking about safety and data retention with today's frontier models?**

我们不是一家试图自己打造最安全模型的公司。我们期望 Anthropic 那边所做的红队测试以及其他一切工作，足以让人相信这个模型是安全的。然后我们采取一种系统化的部署方式，在其中我们能够保证安全性：围绕模型和外壳（harness）构建基础设施和安全网，而不是去调整模型本身。

> We're not a company trying to create the safest model ourselves. We expect that the red teaming and everything else done on Anthropic's side is enough to believe the model is safe. Then we take a systematic approach to deployment, where we can guarantee safety: creating the infrastructure and the safety net around the model and the harness, rather than tweaking the model itself.

安全也是我们对 Claude Fable 5 最主要的用途之一。我们对自己的产品进行白盒测试以发现漏洞，而我们的安全团队正在为这样一个事实做准备：不只是我们在运行这个模型——公司外部的人也会运行 Claude Fable 5 或同类模型，来探测我们所有产品中的漏洞。由于我们服务于受监管行业的大型企业，做好准备对我们来说非常重要。Claude Fable 5 支持我们的工作，而不是阻碍它。

> Security is also one of our biggest Claude Fable 5 uses. We run white-box testing against our own products to find vulnerabilities, and our security team is preparing for the fact that not only are we running the model—people outside the company will be running Claude Fable 5, or similar-class models, to probe for vulnerabilities across all of our products. Since we serve large enterprises in regulated industries, it's important for us to be prepared. Claude Fable 5 supports our work rather than blocking.

所以这是一种微妙的平衡：分类器对你这一侧越不激进，别人就会在我们的产品中发现越多的漏洞——包括那些此前无人知晓的漏洞。

> So it's a tight balance: the less aggressive the classifier is on your side, the more vulnerabilities someone will find in our products—including ones nobody knew about.

这一点并不隐晦：我们更希望做到零数据留存。但我实在想不出还有什么别的办法能让你们了解用户问了什么、以及分类器可能在哪里判断出错。只要审查仅用于调查被标记出的最严重的那些情况，我就可以接受。我认为，为了换取能让我的团队发挥出最佳水平的前沿智能的使用权，这是一个公平的取舍。

> And it's no secret: we'd prefer zero data retention. But I don't see any other way for you to understand what was asked and where a classifier may have worked incorrectly. As long as reviews are only to investigate the most serious cases flagged , I'm okay with it. I think it's a fair tradeoff for access to frontier intelligence that allows my team to do their best work.

**JetBrains 的 AI 路线图下一步是什么？**

> **What's next on JetBrains's AI roadmap?**

我们预计 LLM 提供商构建的底层模型会持续变得更强大。现在真正重要的是一种面向软件开发的驾驶舱：一个让智能体与人协作、并让人能够管理开发流程的空间。

> We expect the underlying models built by the LLM providers to keep getting more capable. What matters now is a kind of cockpit for software development: a space in which agents and people collaborate, and where people can manage the development process. 

对 JetBrains 而言，这是一次重大的转型。我们看到了一个机会：围绕智能体驱动的软件开发生命周期，构建支撑那个驾驶舱的下一代产品。开发者将借助智能体交付更多、更优质的代码，非技术岗位将在软件创造中扮演更重要的角色，组织则将获得他们所需要的治理能力以及对投资回报的清晰认知。

> For JetBrains, it’s a big transformation. We see an opportunity to build the next generation of products across the agentic software development lifecycle that powers that cockpit. Developers will get more and better code shipped with agents, non-technical roles will have a larger role in software creation, and organisations will get the governance and clarity on the return on investment they need.

***开始使用 ***[Claude Fable](https://www.anthropic.com/claude/fable)***。***

> ***Get started with ***[Claude Fable](https://www.anthropic.com/claude/fable)***.***

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| frontier model | 前沿模型 | 当前能力最强、处于技术前沿的大型 AI 模型。 |
| LLM (Large Language Model) | 大语言模型 | 在海量文本上训练、可生成和理解自然语言与代码的神经网络模型。 |
| monorepo | 单一代码仓库 | 把多个项目或模块集中存放在同一个版本控制仓库中的代码组织方式。 |
| evaluation pipeline | 评估流水线 | 用于自动化运行测试集并衡量模型表现的一整套流程。 |
| benchmark | 基准测试 | 用于横向比较模型能力的标准化任务集合与评分。 |
| pass rate | 通过率 | 模型生成的解答通过既定测试的比例。 |
| percentage point | 百分点 | 两个百分比数值之间的算术差值单位。 |
| head-to-head comparison | 一对一对比 | 在相同任务上直接比较两个模型表现的评测方式。 |
| agent | 智能体 | 能够自主规划、调用工具并多步执行任务的 AI 系统。 |
| harness | 外壳 / 运行框架 | 包裹模型、负责提示组装、工具调用与结果处理的外围程序层。 |
| red teaming | 红队测试 | 以对抗视角主动攻击系统以暴露安全缺陷的评估方法。 |
| white-box testing | 白盒测试 | 在了解内部实现的前提下开展的漏洞与质量测试。 |
| black box | 黑盒 | 只依据输入输出而不了解内部结构的系统视角。 |
| classifier | 分类器 | 用于判定内容或请求是否违反安全策略的辅助模型或规则系统。 |
| zero data retention | 零数据留存 | 服务方不保存用户请求与响应数据的隐私处理策略。 |
| SDLC (software development lifecycle) | 软件开发生命周期 | 从需求、设计、开发到测试与运维的完整软件工程流程。 |
| ROI (return on investment) | 投资回报 | 衡量投入产出效益的财务指标。 |
