# Wide Research：超越上下文窗口

> Wide Research: Beyond the Context Window

> 来源：Manus Blog / Manus，2025-10-29
> 原文链接：https://manus.im/blog/manus-wide-research-solve-context-problem
> 分类：AI 智能体 / 并行研究架构

## 核心要点

- 在涉及多个条目的研究任务中，AI 处理到第八、第九项左右时会开始捏造内容，这被归因于架构限制而非提示词或模型能力问题。
- 上下文窗口不仅要容纳各实体的原始信息，还要承载任务说明、格式模板、中间推理、交叉比较以及先前条目的累积上下文，因而会迅速被填满。
- 模型的输出质量随条目推进呈现阶段性下滑：前几项为真实研究，中段趋于笼统，之后进入依据统计模式生成貌似合理内容的编造模式。
- 编造内容格式规范、语气权威且与真实条目风格一致，若不经人工核查难以发现，从而削弱了自动化研究的意义。
- 单纯扩大上下文窗口无法解决问题，原因包括“迷失在中间”的回忆衰减、处理成本不成比例增长、单模型的认知负荷，以及后训练数据偏短带来的上下文长度压力。
- Wide Research 由主控制器将请求分解为相互独立的子任务，并为每个子任务启动具备完整虚拟机、工具库、联网能力和全新上下文窗口的 Manus 子智能体。
- 子智能体并行执行且彼此不通信，所有协调经由主控制器完成，以防止上下文污染并保持独立性，最后由主控制器综合成统一报告。
- 该架构被认为能在规模化下保持一致质量、随任务规模线性扩展、显著缩短耗时、降低幻觉率，并避免单个子智能体的错误扩散。
- Wide Research 适用于需要对多个相似条目进行一致性分析的任务，而不适用于强串行依赖的任务或少于 10 项的小型任务。
- Wide Research 已向所有订阅用户开放，被定位为从“AI 助手”迈向“AI 劳动力”的范式转变。

## 正文

AI 驱动研究的愿景向来引人入胜：把繁琐的信息收集与综合工作交给智能系统，从而让人类的认知腾出来，专注于更高层次的分析与决策。然而，任何在复杂用例上真正深度使用过这些系统的人，都遭遇过一个令人沮丧的现实：在一项涉及多个主题的研究任务中，进行到第八、第九项时，AI 就开始捏造内容了。

> The promise of AI-driven research has always been compelling: delegate the tedious work of information gathering and synthesis to an intelligent system, freeing up human cognition for higher-order analysis and decision-making. Yet, anyone who has pushed these systems on non-trivial use cases has run into a frustrating reality: by the eighth or ninth item in a multi-subject research task, the AI starts fabricating.

不只是简化，也不只是更简洁地总结，而是**捏造。**

> Not just simplifying. Not just summarizing more concisely. **Fabricating.**

这不是提示词工程的问题，也不是模型能力的问题，而是一种架构上的限制。自 AI 研究工具诞生以来，它就一直在悄无声息地制约着这类工具的实用性。而 Wide Research 正是为突破这一限制而设计的。

> This isn't a prompt engineering problem. It's not a model capability problem. It is an architectural constraint that has quietly limited the utility of AI research tools since their inception. And it's the constraint that Wide Research is designed to overcome.

---

#### 上下文窗口：一个根本性瓶颈

> The Context Window: A Fundamental Bottleneck

每个大语言模型都在一个上下文窗口内运行。上下文窗口是一个有限的记忆缓冲区，它限制了模型在任一时刻能够主动处理的信息量。现代模型已经将这一边界推进到了令人瞩目的程度：从 4K token 到 32K、128K，近期版本甚至达到了 1M token。

> Every large language model operates within a context window, a finite memory buffer that limits the amount of information the model can actively process at any given moment. Modern models have pushed this boundary impressively: from 4K tokens to 32K, 128K, and even 1M tokens in recent versions.

然而，问题依然存在。

> Yet the problem persists.

当你让 AI 研究多个实体——比如五十家公司、三十篇研究论文或二十款竞品——上下文窗口会迅速被填满。这不仅仅是每个实体的原始信息，还包括：

> When you ask an AI to research multiple entities-say, fifty companies, thirty research papers, or twenty competing products-the context window fills up rapidly. It's not just the raw information about each entity, but also:

- 
原始任务说明与要求

- 
用于保持输出格式一致的结构模板

- 
每一项的中间推理与分析

- 
交叉引用与比较说明

- 
所有先前条目的累积上下文


> • 
> The original task specification and requirements
> • 
> The structural template for consistent output formatting
> • 
> Intermediate reasoning and analysis for each item
> • 
> Cross-referencing and comparative notes
> • 
> The cumulative context of all preceding items

当模型处理到第八或第九项时，上下文窗口已承受巨大压力。模型面临一个两难的选择：要么明确地失败，要么开始偷工减料。

> By the time the model reaches the eighth or ninth item, the context window is under immense strain. The model faces an impossible choice: fail explicitly, or start cutting corners.

**它总是选择后者。**

> **It always chooses the latter.**

---

#### 编造阈值

> The Fabrication Threshold

实际情况是这样的：

> Here's what happens in practice:

**第 1-5 项：**模型进行了真正的研究。它检索信息、交叉核对来源，并给出详尽、准确的分析。

> **Items 1-5:** The model performs genuine research. It retrieves information, cross-references sources, and produces detailed, accurate analysis.

**第 6-8 项：**质量开始出现细微下滑。描述变得略显笼统。模型开始更多地依赖先前的模式，而不是新鲜的研究。

> **Items 6-8:** The quality begins to subtly degrade. Descriptions become slightly more generic. The model starts relying more on prior patterns than fresh research.

**第 9 项及以后：**模型进入编造模式。由于无法在管理不断溢出的上下文的同时，承担深入研究所需的认知负荷，它开始依据统计模式生成听起来合理的内容，而非基于实际调查。

> **Items 9+:** The model enters fabrication mode. Unable to maintain the cognitive load of thorough research while managing an overflowing context, it begins generating plausible-sounding content based on statistical patterns, not actual investigation.

这些捏造的内容相当精巧。它们听起来很权威，完美遵循既定的格式，往往语法无误，风格上也与先前那些真实的条目保持一致。

> These fabrications are sophisticated. They sound authoritative. They follow the established format perfectly. They are often grammatically flawless and stylistically consistent with the earlier, legitimate entries.

**它们也经常出错。**

> **They are also frequently wrong.**

竞品分析可能会把某些功能归到实际上并未提供这些功能的公司名下。文献综述可能会引用含有捏造结论的论文。产品对比可能会凭空编造价格档位或规格参数。

> A competitor analysis might attribute features to companies that don't offer them. A literature review might cite papers with fabricated findings. A product comparison might invent pricing tiers or specifications.

隐患在于，这些捏造内容若不经人工核查便很难被发现——而这恰恰让自动化研究失去了全部意义。

> The insidious part is that these fabrications are difficult to detect without manual verification—which defeats the entire purpose of automated research.

---

#### 为什么更大的上下文窗口也无法解决这个问题

> Why Bigger Context Windows Can't Fix This

直觉上的应对办法就是直接扩大上下文窗口。32K token 不够，就用 128K；还不够，就推到 200K 甚至更多。

> The intuitive response is to simply expand the context window. If 32K tokens aren't enough, use 128K. If that's not enough, push to 200K or beyond.

这种做法误解了问题所在。

> This approach misunderstands the problem.

**首先，上下文衰减并非非此即彼。**模型无法在整个上下文窗口中保持完美的回忆能力。研究表明，检索准确率会随着与当前位置距离的增加而下降——即“迷失在中间”（lost in the middle）现象。位于上下文开头和结尾的信息比位于中间的信息能被更可靠地回忆起来。

> **First, context decay is not binary.** A model does not maintain perfect recall across its entire context window. Studies have shown that retrieval accuracy degrades with distance from the current position—the "lost in the middle" phenomenon. Information at the beginning and end of the context is recalled more reliably than information in the middle.

**其次，处理成本会不成比例地增长。**处理 400K token 上下文的成本并不只是 200K 的两倍——它在时间和计算资源上都会呈指数级增长。这使得超大上下文处理在许多用例中都不具备经济可行性。

> **Second, the processing cost grows disproportionately.** The cost to process a 400K token context isn't just double the cost of 200K—it increases exponentially in both time and computing resources. This makes massive-context processing economically impractical for many use cases.

**第三，问题在于认知负荷。**即使上下文无限长，要求单个模型在数十项相互独立的研究任务中始终保持一致的质量，也会造成认知瓶颈。模型必须不断在各个条目之间切换上下文、维持一个用于比较的框架，并确保风格一致——而这一切都要在执行核心研究任务的同时完成。

> **Third, the problem is cognitive load.** Even with an infinite context, asking a single model to maintain consistent quality across dozens of independent research tasks creates a cognitive bottleneck. The model must constantly switch context between items, maintain a comparative framework, and ensure stylistic consistency—all while performing the core research task.

**第四，上下文长度压力。**模型的“耐心”在一定程度上取决于其训练数据中样本的长度分布。然而，当前语言模型的后训练数据混合仍以为聊天机器人式交互而设计的较短轨迹为主。因此，当助手消息内容的长度超过某个阈值时，模型自然会感受到一种上下文长度压力，促使它急于进行总结，或转而采用要点列表等不完整的表达形式。

> **Fourth, context length pressure.** The model’s “patience” is, to some extent, determined by the length distribution of samples in its training data. However, the post-training data mixture of current language models is still dominated by relatively short trajectories designed for chatbot-style interactions. As a result, when the length of an assistant message’s content exceeds a certain threshold, the model naturally experiences a kind of context length pressure, prompting it to hasten toward summarizing or to resort to incomplete expression forms such as bullet points.

上下文窗口确实是一种限制。但它只是一个更深层架构局限的表征：**单处理器、顺序执行的范式。**

> The context window is a constraint, yes. But it's a symptom of a deeper architectural limitation: **the single-processor, sequential paradigm.**

---

#### 架构转变：并行处理

> The Architectural Shift: Parallel Processing

Wide Research 代表着对 AI 系统应如何处理大规模研究任务的一次根本性重新思考。我们不再让单个处理器按顺序处理 n 个条目，而是部署 n 个并行子智能体，同时处理这 n 个条目。

> Wide Research represents a fundamental rethinking of how an AI system should approach large-scale research tasks. Instead of asking one processor to handle n items sequentially, we deploy n parallel sub-agents to process n items simultaneously.

![Wide Research Demo](https://files.manuscdn.com/assets/dashboard/materials/2025/10/29/cd3dd078490bf950774ab686d2653563b649c365f062e943fc0c6e2c2e995a16.webp)

##### Wide Research 架构

> The Wide Research Architecture

当你启动一个 Wide Research 任务时，系统的运行方式如下：

> When you launch a Wide Research task, the system operates as follows:

**1. 智能分解**

> **1. Intelligent Decomposition**

主控制器会分析你的请求，并将其拆解为相互独立、可并行执行的子任务。这一过程包括理解任务结构、识别依赖关系，以及编写条理清晰的子规格说明。

> The main controller analyzes your request and breaks it down into independent, parallelizable sub-tasks. This involves understanding the task structure, identifying dependencies, and creating coherent sub-specifications.

**2. 子智能体委派**

> **2. Sub-agent Delegation**

对于每个子任务，系统都会启动一个专用的子智能体。关键在于，这些并不是轻量级进程——它们是功能完整的 Manus 实例，每个实例都具备：

> For each sub-task, the system spins up a dedicated sub-agent. Crucially, these are not lightweight processes—they are full-featured Manus instances, each with:

- 
一个完整的虚拟机环境

- 
可访问完整的工具库（搜索、浏览、代码执行、文件处理）

- 
独立的互联网连接

- 
一个全新的、空的上下文窗口


> • 
> A complete virtual machine environment
> • 
> Access to the full tool library (search, browsing, code execution, file handling)
> • 
> An independent internet connection
> • 
> A fresh, empty context window

**3. 并行执行**

> **3. Parallel Execution**

所有子智能体同时执行。每个子智能体只专注于分配给它的条目，并以处理单条目任务时相同的深度开展研究和分析。

> All sub-agents execute simultaneously. Each one focuses exclusively on its assigned item, performing the same depth of research and analysis it would for a single-item task.

**4. 集中式协调**

> **4. Centralized Coordination**

主控制器负责全局监督，在各子代理完成任务时收集其结果。重要的是，子代理之间并不相互通信，所有协调都经由主控制器进行。这样可以防止上下文污染，并保持各子代理的独立性。

> The main controller maintains oversight, collecting results as the sub-agents complete their jobs. Importantly, the sub-agents do not communicate with each other, all coordination flows through the main controller. This prevents context pollution and maintains independence.

**5. 综合与整合**

> **5. Synthesis and Integration**

所有子智能体汇报完毕后，主控制器会将结果综合成一份统一、连贯且全面的报告。这一综合步骤能够充分利用主控制器的全部上下文容量，因为它并未承担原始的研究工作。

> Once all sub-agents have reported back, the main controller synthesizes the results into a single, coherent, and comprehensive report. This synthesis step leverages the full context capacity of the main controller, as it is not burdened with the original research effort.

---

#### 为何这将改变一切

> Why This Changes Everything

##### 规模化下的一致质量

> Consistent Quality at Scale

每一项都得到同等对待。第 50 项的调研与第一项同样深入。不存在质量衰减曲线，不存在开始编造的临界点，也不存在质量断崖。

> Every item gets the same treatment. The 50th item is researched just as thoroughly as the first. There is no degradation curve, no fabrication threshold, and no quality cliff.

##### 真正的水平可扩展性

> True Horizontal Scalability

需要分析 10 个条目？系统就部署 10 个子智能体。需要分析 500 个？它就部署 500 个。该架构随任务规模线性扩展，而不像基于上下文的方法那样呈指数级增长。

> Need to analyze 10 items? The system deploys 10 sub-agents. Need to analyze 500? It deploys 500. The architecture scales linearly with the size of the task, not exponentially like context-based approaches.

##### 显著加速

> Significant Speed-Up

由于各个子智能体并行运行，分析 50 个条目所需的实际耗时与分析 5 个条目大致相同。瓶颈从顺序处理时间转移到了综合汇总时间——而后者在整个任务中所占的比重要小得多。

> Because the sub-agents operate in parallel, the real-world time required to analyze 50 items is roughly the same as the time to analyze 5. The bottleneck shifts from sequential processing time to synthesis time—a much smaller component of the overall task.

##### 降低幻觉率

> Reduced Hallucination Rate

每个子智能体都在其认知舒适区内运作。由于拥有全新的上下文和单一、聚焦的任务，它不会面临编造内容的压力。子智能体可以开展真正的研究、核实事实并保持准确性。

> Each sub-agent operates within its cognitive comfort zone. With a fresh context and a single, focused task, there is no pressure to fabricate. The sub-agent can perform genuine research, verify facts, and maintain accuracy.

##### 独立性与可靠性

> Independence and Reliability

由于各子智能体之间不共享上下文，某个子智能体在任务中出现的错误或幻觉不会扩散到其他子智能体。每项分析都相互独立，从而降低了系统性风险。

> Because the sub-agents do not share context, an error or hallucination in one sub-agent's job does not propagate to the others. Each analysis stands on its own, reducing systemic risk.

---

#### 超越单处理器范式

> Beyond the Single-Processor Paradigm

Wide Research 不只是一项功能——它代表着一种根本性的转变：从单处理器范式转向经过编排的并行架构。AI 系统的未来不在于越来越大的上下文窗口，而在于智能的任务分解与并行执行。

> Wide Research is more than a feature—it represents a fundamental shift away from the single-processor paradigm and toward an orchestrated, parallel architecture. The future of AI systems lies not in ever-larger context windows, but in intelligent task decomposition and parallel execution.

我们正在从“AI 助手”时代迈入“AI 劳动力”时代。

> We are moving from the era of the "AI assistant" to the era of the "AI workforce."

**何时使用 Wide Research：**任何涉及多个相似条目、需要进行一致性分析的任务——竞品研究、文献综述、批量处理、多素材生成。

> **When to use Wide Research:** Any task involving multiple, similar items that require consistent analysiscompetitive research, literature reviews, bulk processing, multi-asset generation.

**不适用的情况：**高度串行的任务，即每一步都严重依赖上一步的结果；或者小型任务（少于 10 项），此时由单个处理器处理更具成本效益。

> **When not to use:** Deeply sequential tasks where each step heavily depends on the prior result, or small tasks (fewer than 10 items) where single-processor handling is more cost-effective.

---

#### Wide Research 现已向所有订阅用户开放

> Wide Research is for all subscribers

从单一 AI 助手到由子代理协同组成的工作团队，这一架构上的飞跃现已向所有订阅用户开放。这是 AI 驱动的研究与分析的一种全新范式。

> The architectural leap from a single AI assistant to a coordinated workforce of sub-agents is now available to all subscribers. This is a new paradigm for AI-powered research and analysis.

我们诚邀您亲身体验其中的不同。带上您的大规模研究难题——那些您曾认为 AI 无法完成的任务——见证并行处理方法如何在规模化场景下持续交付高质量的结果。

> We invite you to experience the difference firsthand. Bring your large-scale research challenges—the ones you thought were impossible for AI—and witness how a parallel-processing approach delivers consistent, high-quality results at scale.

AI 劳动力的时代已经到来。今天就开始你的 Wide Research 任务吧。

> The era of the AI workforce is here. Start your Wide Research task today.

[在 Manus Pro 中试用 Manus Wide Research →](https://manus.im/app)

> [Try Manus Wide Research in Manus Pro →](https://manus.im/app)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Context Window | 上下文窗口 | 大语言模型在任一时刻能够处理的有限 token 容量。 |
| Token | 词元 | 模型处理文本时使用的基本计量单位。 |
| Hallucination | 幻觉 | 模型生成看似合理但与事实不符的内容。 |
| Fabrication | 捏造 | 模型在缺乏实际依据时编造信息的行为。 |
| Lost in the Middle | 迷失在中间 | 模型对上下文中间位置信息的回忆准确率低于开头和结尾的现象。 |
| Context Decay | 上下文衰减 | 信息距当前位置越远，模型对其检索准确率越低的现象。 |
| Cognitive Load | 认知负荷 | 模型同时承担多项任务与维持一致性时所面临的处理负担。 |
| Context Length Pressure | 上下文长度压力 | 输出超过训练数据常见长度时，模型倾向于仓促总结或简化表达的现象。 |
| Post-training | 后训练 | 在预训练之后针对特定交互形式对模型进行的进一步训练。 |
| Sub-agent | 子智能体 | 由主控制器派生、专门负责单个子任务的独立智能体实例。 |
| Orchestrator | 主控制器 | 负责任务分解、子智能体协调与结果综合的中心组件。 |
| Task Decomposition | 任务分解 | 将复杂请求拆解为可独立并行执行的子任务的过程。 |
| Parallel Processing | 并行处理 | 多个执行单元同时处理不同子任务的计算方式。 |
| Horizontal Scalability | 水平可扩展性 | 通过增加并行执行单元数量来应对更大任务规模的能力。 |
| Context Pollution | 上下文污染 | 无关或错误信息混入上下文而干扰模型处理的问题。 |
