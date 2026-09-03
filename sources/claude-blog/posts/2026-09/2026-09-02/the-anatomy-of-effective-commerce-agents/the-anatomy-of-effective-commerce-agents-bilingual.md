# 高效电商智能体的结构剖析指南

> A guide to the anatomy of effective commerce agents

> 来源：Claude Blog / Anthropic，2026-09-02
> 原文链接：https://claude.com/blog/the-anatomy-of-effective-commerce-agents
> 分类：AI 工程 / 智能体架构

## 核心要点

- 商务智能体被定义为简化在线目录中买卖流程的智能体，既可面向消费者完成搜索、比价与下单，也可面向商家处理销售分析、促销活动与库存定价。
- 推荐的核心架构是处于标准智能体循环中的单一模型，配备技能、工具与评估套件，前端不设意图路由器，后端不挂领域子智能体。
- 商务对话跨多意图、多轮次且状态紧密耦合，向子智能体移交会丢失购物车、偏好与历史等共享状态，并额外消耗数倍 token 与数秒延迟。
- 技能提供按领域划分的模块化能力却无需交接成本，在多个企业部署的对比中，配备技能的单一智能体在质量、成本与延迟上均优于单一大提示词和子智能体设计。
- 指令放入系统提示词还是技能取决于使用频率，涉及约三分之一以上流量的内容以及安全、法律、品牌与过敏等关键信息应常驻系统提示词。
- 智能体工具应调用企业已有的搜索、购物车、库存与促销系统而非重新实现，并只返回模型推理所需字段，在错误场景中给出可操作指令而非笼统错误码。
- UI 组件应实现为带类型参数的展示工具，使组件以原生工具调用形式留存于 messages 数组，避免自定义标签解析带来的可靠性下降、上下文膨胀与历史加载问题。
- 降低任务完成延迟的三个杠杆是更少轮次、更快工具与更快 token，具体手段包括预加载页面上下文、提升模型智能、并行调用独立工具以及在参数流式完成时即刻分发工具调用。
- 提示缓存是最大的成本削减项，应按全局层、会话层、易变内容的顺序组织请求前缀，最佳部署的缓存命中率可达 90–99%。
- 长期记忆应存放在自有数据库而非模型中，采用异步提取写入以避免增加对话延迟，并按人而非按账户组织商家记忆，同时处理保存范围、用户查改删、保留期限与按地区开关等合规义务。
- 安全约束必须在运行框架的代码中强制执行，模型只能提出建议，资金与业务变更需经人工或策略审批，写入与渲染仅接受服务端签发的 ID，第三方内容一律净化并围栏包裹。
- 评估应针对可直接构造的状态快照而非完整对话，覆盖核心请求、上下文依赖请求、安全与品牌案例、界面渲染与跨能力请求，并为每个正面用例配备对应的反面用例。
- 在大型组织中交付需要让技能与工具的所有权对齐系统归属团队，变更随测试用例发布并由 CI 运行选定用例集，同时对智能体实施金丝雀发布、技能开关与业务高峰期冻结。

## 正文

在过去的一年里，我们与商业领域的各类团队展开合作——包括零售商、市场平台、旅游、娱乐以及电信服务提供商——共同使用 Claude 构建商业智能体。  

> Over the past year, we've worked with teams across the commerce industry — retailers, marketplaces, travel, entertainment, and telecom providers — to build commerce agents using Claude.  

这些智能体已投入生产环境，企业客户在使用它们后，看到了更大的购物车金额和更高效的卖家运营。它们还共享一种简单的架构：处于智能体循环中的 Claude，配备一组技能、工具和一套强大的评估套件。

> These agents are in production, and enterprise customers have seen larger carts and more efficient seller operations when using them. They also share a simple architecture: Claude in an agent loop equipped with a set of skills, tools, and a strong eval suite.

本文面向正在构建这类（或其他面向消费者的）智能体的工程师和工程负责人。第一部分讲架构，这是你只需决定一次的事。第二部分讲延迟与成本。第三部分讲生产环境：记忆、安全、评估，以及如何在一个组织内扩展这项工作。

> This post is for the engineers and engineering leaders building these (or other consumer facing) agents. Part 1 covers the architecture, which you decide once. Part 2 covers latency and cost. Part 3 covers production: memory, safety, evals, and scaling the work across an organization.

本指南内容

> In this guide

1. [第 1 部分：架构](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p1)
2. [第二部分：让它快速且经济](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p2)
3. [第 3 部分：在生产环境中运行](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p3)
4. [展望未来](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p4)

> 1\. [Part 1: The architecture](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p1)
> 2\. [Part 2: Making it fast and affordable](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p2)
> 3\. [Part 3: Running it in production](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p3)
> 4\. [Looking ahead](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#ca-p4)

#### 该架构

> The architecture

##### **什么是商务智能体？**

> **What is a commerce agent?**

我们将商务智能体定义为一种简化在线商品目录中买卖流程的智能体。

> We define a commerce agent as an agent that simplifies buying and selling across an online catalog.

有些智能体面向消费者：它们搜索、比较、替换并组装订单。这可能是一个零售购物车、一份旅行行程、一次移动套餐变更，或是为某场演出预留的座位。有些智能体面向企业：它们回答有关销售的问题，开展促销和营销活动，并管理库存与定价。

> Some agents face consumers: they search, compare, substitute, and assemble the order. That could be a retail cart, a travel itinerary, a mobile plan change, or seats held for a show. Some agents face the business: they answer questions about sales, run promotions and campaigns, and manage inventory and pricing. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a97121e31e08caa3a0e6679_02653800.png)

其核心架构是一个处于[标准智能体循环](https://www.anthropic.com/engineering/building-effective-agents)中的模型：围绕目标进行推理、探索上下文、通过工具采取行动、通过技能学习流程、提出澄清性问题，并观察结果，直到目标达成。 

> The core architecture is a model in a [standard agent loop](https://www.anthropic.com/engineering/building-effective-agents): reasoning about a goal, exploring context, taking actions through tools, learning procedures through skills, asking clarifying questions, and observing the results until the goal is accomplished. 

它前面没有用于切分对话的意图路由器，后面也没有一组特定领域的智能体。

> There is no intent router in front of it that segments the conversation and no set of domain specific agents behind it.

##### **工程背景**

> **Engineering context**

###### **技能，而非子智能体**

> **Skills, not subagents**

一个商务代理需要覆盖众多品类和意图上的广泛能力，这使得人们很容易想为每个领域创建一个子代理。

> A commerce agent has to cover a wide range of capabilities across many categories and intents, which makes it tempting to create one subagent per domain. 

实际上这种做法并不理想，因为一次商务对话是一个跨多个意图和多轮交互的紧密耦合会话，需要大量的共享上下文。

> In practice this proves suboptimal, because a commerce conversation is one tightly coupled session across multiple intents and turns, and requires considerable shared context.

在子智能体架构中，编排器持有购物车或暂存的变更、用户的偏好以及对话历史。

> In a subagent architecture, the orchestrator holds the cart or staged changes, the user's preferences, and the conversation history. 

每一次向子代理的移交都是一次会丢失状态的操作，这往往会影响子代理响应的质量，并进而影响整体响应的质量。除此之外，每次移交都可能消耗数倍的 token，并增加数秒的延迟。

> Every handoff to a subagent is a state-lossy operation, which often impacts the quality of the subagent’s response and, consequently, the overall response. On top of that, each handoff can cost several times the tokens and adds seconds of latency.

这些领域也很少能干净地分离开来。一个退货流程可能需要订单历史、当前购物车和产品目录，这意味着「每个领域一个子智能体」的做法要么在所有地方重复这些访问权限，要么在任务中途进行交接。

> The domains also rarely separate cleanly. A returns flow might need the order history, the current cart, and the product catalog, meaning a subagent-per-domain approach either duplicates that access everywhere or hands off mid-task. 

随着模型变得更聪明，它们也能处理更长的上下文、更多的技能和更多的工具，因此当今放置规则背后的种种限制会随着每一代模型的推出而逐渐放宽。

> As models get smarter, they also handle longer context, more skills, and more tools, so the limits behind today's placement rules loosen with each model generation.

相反，[智能体技能](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)能为你提供类似的按领域划分的模块化能力和上下文控制，却不必付出交接成本，因为技能指令是加载到已经掌握全部历史记录的主智能体中的。

> Instead, [agent skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) give you similar per-domain modularity and context control without the handoff tax, because the skill instructions load into the main agent that already holds the entire history. 

在我们对多个企业部署的对比中，配备技能的单一智能体在质量上始终优于「一个提示词包打天下」的设计和子智能体设计，而且每项任务的成本和延迟往往更低。

> In our comparisons across several enterprise deployments, a single agent with skills consistently has outperformed both the one-prompt-for-everything design and the subagent design on quality, and often at a lower cost and latency per task.

子智能体真正能发挥价值的场景，是编排器可以把它们当作工具来调用，用于处理那些范围狭窄或自成一体、且能从独立的专属上下文窗口中受益的任务。

> Where subagents do earn their place is when the orchestrator can call them as a tool for a narrow or self-contained task that would benefit from its own dedicated context window. 

一个常见的生产环境示例是深度研究子智能体（deep-research subagent），子智能体会搜索并阅读文档、编写并运行代码、遍历数据模型，也会走进死胡同。所有这些工作都发生在一个或多个子智能体内部，只有一份精简的答案会返回给编排器。

> A common production example is a deep-research subagent, where the subagent searches and reads documents, writes and runs code, traverses data models, and hits dead ends. All the work happens inside one or more subagents, and only a compact answer comes back to the orchestrator.

另一个例外是某个领域已经拥有专门为其构建的智能体。如果你的药房或金融服务业务运行着一个带有自身合规界面的专用智能体，那么正确的做法可能是移交，即由该智能体接管任务，并通过它自己的循环直接与用户协作，直到任务完成。

> The other exception is a domain that already has its own purpose-built agent. If your pharmacy or financial-services experience runs a dedicated agent with its own compliance surface, the right move can be a hand-off, where that agent takes over the task and works with the user directly through its own loop until the task is done. 

区别在于对话的归属权。移交（hand-off）会让领域智能体成为用户的对话对象，而委派（delegation）则保留编排器的对话归属权，在单个回合内让领域智能体反复进出，并在每一次交互中不断退化。

> The distinction is ownership of the conversation. A hand-off makes the domain agent the user's counterpart, while delegation keeps the orchestrator, bouncing the domain agent in and out within a single turn and degrading on every exchange.

###### **系统提示词还是技能：按使用频率决定**

> **System prompt or skill: decide by frequency**

决定将一组指令放在系统提示词中还是放在技能中，主要考虑的因素是智能体需要用到它的频率。加载一个技能会消耗一个模型回合，因此智能体在大多数回合中都需要的内容，通常应放在系统提示词里。

> The main factor when deciding whether to put a set of instructions within a system prompt or skill is how often the agent will need it. Loading a skill costs a model turn, so anything the agent needs on most turns generally goes in the system prompt. 

不过，这确实取决于你的流量是如何分布的，以及你的评估显示出怎样的智能体行为。一个不错的出发点是：凡是与三分之一或更多流量相关的内容，无论是在上线前预期到的还是在生产环境中观察到的，都放进系统提示词，其余的则放进技能中。

> This does, however, depend on how your traffic is distributed, and what agent behavior your evals show. A good starting point is that anything relevant to a third or more of your traffic, whether anticipated before launch or observed in production, goes in the system prompt, and the rest goes in skills.

如果某项技能可以根据你已有的信号预测出来，比如用户来自哪个页面，我们建议在首次模型调用之前就从 harness 注入该技能，从而省去加载技能所需的额外一轮交互。

> If a skill is predictable from a signal you already have, such as the page the user arrived from, we recommend injecting it from the harness before the first model call and skipping the extra turn to load the skill. 

关键指令，例如安全与法律规则、品牌约束，以及诸如过敏等重要的用户信息，都应始终放在系统提示词中。

> Critical instructions, such as safety and legal rules, brand constraints, and key user facts such as allergies, always go in the system prompt.

对于电商代理来说，这意味着产品搜索应当放在提示词中，因为几乎每一次会话都会用到它，而技能则承载功能的长尾部分。

> For commerce agents, this means product search lives in the prompt, since nearly every session touches it, and skills carry the long tail of features. 

在我们的[参考实现](https://github.com/anthropics/commerce-agents)中，购物代理的提示词包含了基础设定、购物车与结账语义以及呈现规则，其余部分则由以下技能覆盖：search-discovery、purchase-research、planning-goals、customer-care 和 memory-personalization。

> In our [reference implementation](https://github.com/anthropics/commerce-agents), the shopping agent's prompt holds grounding, cart and checkout semantics, and presentation rules, and the following skills cover the rest: search-discovery, purchase-research, planning-goals, customer-care, and memory-personalization. 

商家代理也以同样的方式拆分，以 performance-insights、catalog-listings、inventory-operations、pricing-promotions 和 marketing-campaigns 作为其技能，每个运营领域对应一个。

> The merchant agent splits the same way, with performance-insights, catalog-listings, inventory-operations, pricing-promotions, and marketing-campaigns as its skills, one per operational domain.

##### **工程化智能体工具**

> **Engineering agent tooling**

我们那篇关于[为智能体编写高效工具](https://www.anthropic.com/engineering/writing-tools-for-agents)的文章总体介绍了工具设计。其中有两点在电商场景中最为重要：

> Our post on[ writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) covers tool design in general. Two points have mattered most in commerce:

**在你的核心系统和逻辑之上构建智能体工具。** 

> **Build agent tools on top of your core systems and logic.** 

一家电商公司已经拥有搜索与排序、购物车、偏好与档案存储、库存系统、促销与营销活动引擎、销售分析等各类系统，每一个都沉淀着经过多年调优的逻辑，并接触着模型永远无法获取的信号。

> A commerce company already has search and ranking, a cart, a preferences and profile store, an inventory system, promotion and campaign engines, sales analytics, and more, each encoding logic tuned over years and seeing signals the model never will. 

智能体的工具应当调用这些系统，而不是重新实现它们；工具边界正是这些系统的逻辑终止、模型的判断开始接管的地方。

> The agent's tools should call those systems, not reimplement them, and the tool boundary is where their logic ends and the model's judgment takes over. 

例如，当代理调用 `search_products` 时，返回的结果应当已经排好序；它的任务是判断哪些结果服务于用户的目标、展示多少条，以及如何呈现它们。

> For example, when the agent calls `search_products`, the results should arrive already ranked; its job is to decide which results serve the user's goal, how many to show, and how to present them.

**工具返回的结果就是上下文。** 

> **Tool results are context.** 

只返回模型推理时用得到的字段，其余一律丢弃。每一行搜索结果里的图片 URL 就是最常见的元凶。

> Return the fields the model reasons with and drop the rest. Image URLs on every search row are the usual offender. 

根据需要，在工具内部重塑原始响应，包括在数据本身无法明显体现下一步操作时，附加上下一步的说明。

> As needed, reshape the raw response inside the tool, including appending a next step when it isn't obvious from the data. 

这一点对于错误场景尤其重要，因为模型从指令中获得的帮助要大于从错误码中获得的帮助。例如，添加一条错误指令“查询可用性时请包含产品 ID”，而不是返回一个笼统的 403。

> This is especially relevant for error scenarios, where the model benefits from instructions instead of error codes. For example, add an error instruction "Include a product ID when querying availability," instead of a generic 403.

###### **UI 组件即工具**

> **The UI components are tools**

大多数商务智能体的响应是 UI 组件而非散文，无论是产品轮播、行程单、座位图还是图表。这意味着智能体必须输出一个 schema，而不是文本。

> Most commerce agent responses are UI components rather than prose, whether a product carousel, an itinerary, a seat map, or a chart. That means the agent has to emit a schema rather than text.

团队有时一开始会提示模型输出自定义标签，然后在客户端解析它们。随着接触面的扩大，这种做法会失效，原因是：

> Teams sometimes start by prompting the model to emit custom tags and parsing them on the client-side. This stops working as the surface grows, because:

- 模型在你的标记语言上的训练程度不如在工具调用上那么充分，因此随着嵌套组件的增加，可靠性会下降。仅靠提示词无法保证数据格式的规范性。
- 标签定义存在于系统提示词中，因此每新增一个组件都会让上下文变得臃肿，而每一次修改都有可能导致提示词中其他位置出现回归问题。
- 过去的对话最终以只有你的解析器才能读取的格式存储，因此加载历史记录意味着要么在客户端解析原始消息，要么以一种并非模型 API 原生的格式保留第二份副本。

> • The model isn’t as well trained on your markup as it is on tool calls so reliability drops as nested components get added. Well-formed data is not guaranteed just through prompting.
> • The tag definitions live in the system prompt, so every new component bloats context and every edit risks regressions elsewhere in the prompt.
> • Past conversations end up stored in a format only your parser can read, so loading history means either parsing raw messages on the client or keeping a second copy in a format that isn't native to the model API.

经受住考验的模式是把每个 UI 组件都做成一个工具。模型使用带类型的参数调用 `present_products`、`present_itinerary` 或 `present_plan_comparison`；你的服务器验证并丰富该调用，然后发出一个事件；你的客户端负责渲染它。

> The pattern that has held up is to make each UI component a tool. The model calls `present_products`, `present_itinerary`, or `present_plan_comparison` with typed arguments; your server validates and enriches the call and emits an event; and your client renders it. 

由于这些组件就是工具调用，它们已经以原生格式存在于 messages 数组中，因此当你重新加载旧对话时无需重新解析。下面以及[参考仓库](https://github.com/anthropics/commerce-agents)中展示了一个展示型工具（presentation-tool）契约的示例。

> As the components are tool calls, they're already in the messages array in native format, so you don’t need to re-parse when you reload an old conversation. An example presentation-tool contract is illustrated below and in the [reference repo.](https://github.com/anthropics/commerce-agents)

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a971accf6d9dcde640f87df_presentationtool.gif)

代价是流式传输的粒度。工具调用的每个顶层参数都会在服务端缓冲以便校验，因此即使开启了流式传输，演示工具的各个子组件也是分步到达的。这会影响感知延迟。

> The tradeoff is streaming granularity. Each top-level argument of a tool call buffers on the server for validation, so the sub-components of a presentation tool arrive in steps even with streaming on. This impacts perceived latency. 

要获得 token 级别的流式输出，请在工具定义上将 `eager_input_streaming:` 设为 true，这会跳过缓冲，同时也会失去服务端的 schema 保证。

> To get a token-level stream, set `eager_input_streaming:` true on the tool definition, which skips the buffering and with it the server-side schema guarantee. 

在我们的评估中，Claude Sonnet 级别及以上的模型极少出现 schema 违规，但仍应为调用包上重试逻辑，以应对偶尔漏过的情况。

> In our evals, schema violations are very rare on Claude Sonnet-class models and up, but wrap the call in a retry for the cases where one slips through.

展示工具还能让智能体记录屏幕上显示的内容。当客户说"第一家酒店"或"左边从上往下数第三个"时，布局信息就在 messages 数组中，位于最后一次展示调用的参数里。

> Presentation tools also give the agent a record of what's on screen. When a customer says "the first hotel" or "the third one down on the left," the layout is in the messages array, in the arguments of the last presentation call. 

要让这一点奏效，参数必须反映渲染后的布局，因此应按照 UI 的结构来组织它们，即有序的行和轮播，而不是由客户端重新排列的扁平列表。

> For that to work, the arguments have to reflect the rendered layout, so structure them the way the UI is structured, as ordered rows and carousels rather than a flat list the client rearranges.

#### 让它既快速又经济实惠

> Making it fast and affordable

延迟在电商领域至关重要，而面向消费者的界面对此最不宽容。然而，在智能体界面上，我们持续观察到，真正能推动留存率、参与度和购物车规模等指标的是结果的质量。

> Latency matters in commerce, and consumer surfaces are the least forgiving. However, on agentic surfaces, what we have consistently seen move metrics like retention, engagement, and cart size is the quality of the outcome. 

相比于边际上的延迟收益，答案是否相关以及任务是否真正完成，对这些指标而言更为关键。

> Whether the answer was relevant and the task actually completed was more critical to those metrics as compared to marginal latency gains. 

所以要从两条战线上攻克延迟。通过良好的工程实践把端到端延迟降到最低，并同时降低感知延迟（因为看着智能体工作所花的时间会被理解为进展）。

> So attack latency on two fronts. Minimize end-to-end latency through good engineering, and pair that with dropping perceived latency (since time spent watching an agent work reads as progress). 

每个用户都有延迟预算，而下面这些技术能让智能体保持在预算之内，且无需为此牺牲智能水平。

> Every user has a latency budget, and the techniques below keep the agent inside it without spending intelligence to get there.

##### **最小化任务完成延迟**

> **Minimizing task completion latency**

任务完成延迟是模型每一轮的最后一个 token 生成时间与工具处理时间之和。这为你提供了三个可以着力的杠杆：更少的轮次、更快的工具和更快的 token。这些杠杆有时会相互冲突，因此要最小化的是它们的总和，而不是其中任何单独一项。

> Task completion latency is the sum, over model turns, of time to last token plus tool processing. That gives you three levers to work towards: fewer turns, faster tools, and faster tokens. These levers sometimes compete, so the thing to minimize is the sum rather than any one of them.

###### **更少的轮次**

> **Fewer turns**

查询复杂度会增加轮次，而这通常不受你的控制。模型智能和相关上下文有助于智能体用更少的轮次完成任务。我们在这方面的一些关键经验包括：

> Query complexity adds turns, and is generally out of your control. Model intelligence and relevant context help the agent get to task completion in fewer turns. Some of our key learnings in this area include:

- **提前加载可能用到的上下文。**如果用户是从某个商品页面打开助手的，或者商家是从某个营销活动看板打开它的，就把该页面的数据放入会话上下文。对话很可能与之相关，而直接从上下文中作答不会产生额外的交互轮次。
- **提升模型智能。**更聪明的模型能够减少完成一项任务所需的总轮次，因为智能体可以更高效地规划并发出工具调用。这往往足以抵消其更慢的 token 输出速度。如果你的查询偏向复杂，或者生产环境显示每个任务超过约五个轮次，那么更快的模型往往就是更聪明的那个。具体是哪一个取决于你的流量情况，所以请通过扫描测试来选择，如下文"选择模型"部分所述。
- **让模型并行调用相互独立的工具**。电商场景常常需要并行执行许多操作：比如搜索多个商品、查询多份政策文档，或从多个销售数据来源获取记录。并行工具调用可以确保多个独立的查询不会额外消耗轮次。提示模型在一轮内调用多个工具，并将结果以工具结果数组的形式在一条用户消息中返回（参见[并行工具调用文档](https://platform.claude.com/docs/en/agents-and-tools/tool-use/parallel-tool-use)）。

> • **Load likely context up front.** If the user opened the assistant from a product page, or a merchant opened it from a campaign dashboard, put that page's data in the session context. The conversation is likely about it, and answering from context costs no extra turns.
> • **Increase model intelligence.** Smarter models can decrease overall turns in the completion of a task as the agent can more efficiently plan and issue its tool calls. That often outweighs their slower tokens. If your queries skew complex, or production shows more than about five turns per task, the faster model is frequently the smarter one. Which one that is depends on your traffic, so choose by sweep, as described under "Choosing the model" below.
> • **Have the model call independent tools in parallel**. Commerce use cases often require many operations in parallel: be it searching for multiple products, querying many policy docs, or fetching records from many sources of sales data. Parallel tool ensures multiple independent queries don’t burn additional turns. Prompt the model to call many tools within a turn and return the results in one user message as an array of tool results (see the [parallel tool use docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/parallel-tool-use)).

###### **更快的工具**

> **Faster tools**

- **优化工具自身的后端。**有时候，一个工具确实需要扇出调用——比如一个商家智能体接到「获取今日概览」的查询，会通过三次独立调用分别读取销售、库存和活动状态。但我们经常看到的情况是，工具边界成了缝合缺失后端逻辑的地方：一次可用性检查要调用商品目录获取 SKU、按门店调用库存服务、调用履约服务获取截单时间，然后在工具自己的代码里应用替代品规则和自提资格判断，最后才给出答复。这样的工具如今承载了过多领域知识，随着规则变化很难保持正确，而且携带着本应位于上游系统中的逻辑。当你发现自己正在工具里编写这类逻辑时，正确的做法是提供一个能直接回答该问题的后端接口，然后用一个智能体工具去调用它。
- **积极地分发工具调用。**工具参数像其他 token 一样从模型中流式输出，因此在每个工具的参数流式传输完成时，框架就可以执行该工具的调用并对其进行处理，而此时模型仍在流式输出其他并行的工具或内容块。我们已经看到这种做法将数秒的间隔缩短到几百毫秒，而 [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) 默认就是这样做的。你应该提示模型先发出最慢的调用，以获得最大的延迟收益。

> • **Optimize the tool's own backend.** Sometimes a tool genuinely fans out – a merchant agent with a  "get today's snapshot" query reads sales, inventory, and campaign status in three independent calls. But we often see the tool boundary become the place where missing backend logic gets stitched together: an availability check that calls the catalog for the SKU, the inventory service per store, and the fulfillment service for cutoffs, then applies substitution rules and pickup eligibility in the tool's own code before answering. That tool is now overloaded with domain knowledge, hard to keep correct as the rules change, and is carrying logic that should sit in an upstream system. When you find yourself writing that logic in a tool, the fix is one backend endpoint that answers the question, and calling that with an agent tool.
> • **Dispatch tools eagerly.** Tool arguments stream out of the model like any other tokens, so the harness can execute each tool’s call as its arguments complete and process it while the model is still streaming other, parallel tools or content blocks. We've seen this take multi-second gaps down to a few hundred milliseconds, and the [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) does it by default. You should prompt the model to emit its slowest call first for maximum latency gains.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a971b4ebf113390b39a25b2_eagerdispatch.gif)

##### **感知延迟**

> **Perceived latency**

感知延迟是指用户从操作到感觉屏幕有所反应之间的时间。在面向消费者的场景中，这一点尤为关键，因为任何交易环节的摩擦都会影响结账率和营收。有两种技术可以在不改动模型的情况下缩短它：

> Perceived latency is the time a user feels until the screen does something. It’s especially critical in consumer-facing use cases where any transaction friction impacts checkout rates and revenue. Two techniques shorten it without touching the model:

- **在组件成形的过程中就流式传输。** 一个渲染完成的电商响应通常有 500–700 个输出 token，如果不采用流式传输，就意味着五秒甚至更久的加载转圈。应当在展示类工具的每个参数流式产生时就把它发送给客户端，并渐进式地渲染页面。
- **展示工作过程。**在智能体收集上下文的过程中，用通俗的语言为每个步骤呈现一行简短的进度提示（例如「正在寻找靠海的酒店」）。你可以基于工具已有的参数来构建这行提示（比如商品搜索的查询词），也可以为工具增加一个 user_facing_message 参数，提示模型来撰写这行文字。

> • **Stream components as they form.** A rendered commerce response is typically 500–700 output tokens, which without streaming is five or more seconds of a spinner. Send each parameter of a presentation tool to the client as it streams and render the page progressively.
> • **Show the work.** While the agent is gathering context, render a short progress line for each step in plain language (for example, "finding hotels near the water"). You can build it from the tool's existing arguments (such as the query for a product search), or add an additional user_facing_message parameter tool that prompts the model to write the line. 

![The two panels above run the same agent with the same tools and prompt; only the harness differs. Total time is about the same, but the time the user sees something is quite different.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a971b28c43d0f061e80bc6c_perceivedlatency.gif)

##### **提示缓存**

> **Prompt caching**

提示缓存是你最大的成本削减候选项，而电商流量非常适合它。缓存输入 token 的读取成本只有全新 token 的十分之一，虽然缓存写入有大约 1.25 倍的溢价，但一个缓存前缀在第二次使用时就能收回成本。在面向客户、流量很大的应用中，你有一个独特的机会，可以使用最便宜的、默认 5 分钟的缓存过期时间来达到非常高的缓存命中水平。  

> Prompt caching is your largest cost reduction candidate and commerce traffic is well-suited for it. Cached input token reads cost a tenth of fresh ones, and while cache-writes carry a premium of roughly 1.25x, a cached prefix pays for itself on its second use. In customer facing applications where volume is large, you have a unique opportunity to hit very high cache levels using the cheapest, default 5 minute cache expiration.  

我们见过的最佳电商部署方案运行时的缓存命中率在 90–99% 之间，这也是从一开始就应该设计对标的区间。我们的经验表明，在约 10 万 tokens 的规模下，缓存 token 的读取速度也要快大约 1.5 到 2 倍，且 token 数量越多，这一提升的扩展性相对越接近线性。

> The best commerce deployments we've seen run at 90–99% cache hit rates, and that is the range to design for from the start. Our experience has shown cached token reads are also around 1.5 to 2x faster at ~100k tokens, with relatively linear scaling the more tokens there are. 

缓存是基于前缀的。一个请求会从缓存中读取内容，直到遇到与之前请求不同的第一个字节，因此重要的不仅是上下文中有什么，还有它们的排列顺序。可以把一个请求看作三个片段，按它们变化的频率排序：

> Caching is prefix-based. A request reads from cache up to the first byte that differs from a previous request, so what matters is not just what is in the context but the order it is in. Think of a request as three segments, ordered by how often they change:

- **全局层**：绝大部分系统提示词和工具定义，在每个会话中都完全相同。这是你最热的缓存，在大规模场景下很可能永不过期。请让它在各轮次和各会话之间保持逐字节一致，并在其末尾放置一个缓存断点。
- **会话**：即每个用户的上下文和对话历史，它们在不同会话之间各不相同，但在同一个会话内保持稳定。这一段位于全局段之后。
- **易变内容**：会话过程中会发生变化的任何内容，例如当前时间或当前页面。把它放在请求的最末尾，可以作为最新一轮用户消息中的带标签块，或者在支持[会话中系统消息](https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages)的模型上，作为追加到 messages 数组末尾的 system 角色消息。我们看到的最常见错误，是把时间戳或当前页面放在系统提示词的开头，这会在每次请求时悄无声息地破坏缓存。

> • **Global**: most of the system prompt and tool definitions, identical across every session. This is your warmest cache and, at scale, will likely not expire. Keep it byte-identical across turns and sessions and put a cache breakpoint at its end.
> • **Session**: per-user context and conversation history, which differ across sessions but stay stable within one. This segment comes after the global one.
> • **Volatile**: anything that changes within a session, such as the current time or the current page. Put it at the very end of the request, either as a tagged block in the newest user turn or, on models that support [mid-conversation system messages](https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages), as a system-role message appended to the messages array. The most common mistake we see is a timestamp or the current page at the top of the system prompt, which silently breaks the cache on every request.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a970f654fd654f0e7990b95_c63ca0e7.png)

这里有两个实现细节需要记住。首先，技能应当作为工具结果加载，而不是追加到系统提示词中。这样技能正文就会落在对话前缀里，并随之一起被缓存。

> There are two implementation details to remember here. First, skills should be loaded as tool results rather than appended to the system prompt. The skill body then lands in the conversation prefix and is cached along with it. 

其次，在每一轮中向前滚动你的断点：一次请求只允许有限数量的断点，因此要把最新的断点移动到每个用户回合的末尾。这样每一轮都可以从缓存中读取累积的历史记录，包括搜索响应之类的长工具结果。

> Second, roll your breakpoints forward in each turn: a request allows a limited number of breakpoints, so move the newest one to the end of each user turn. Each round then reads the accumulated history, including long tool results such as search responses, from cache.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a97109fd7957fb6e5b0facf_f48075ed.png)

##### **选择模型及其配置**

> **Choosing the model and its configuration**

[模型规模与努力程度设置](https://claude.com/blog/claude-model-and-effort-level-in-claude-code)体现的是同一种权衡——智能水平与延迟和成本之间的取舍——这两者你都应该通过实测来选择：

> [Model size and the effort setting](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) are the same tradeoff – intelligence against latency and cost – and you should choose both by measurement:

1. **选定你的指标和底线。**选定业务所依赖的质量指标（任务完成度、答案相关性、有据可依的准确性）、你不愿跌破的评估分数，以及 p50 和 p99 的延迟和成本预算。
2. **扫描测试。**在你会考虑的*每一个*模型和思考强度档位上运行完整的评估套件。我们建议商家智能体从 Opus 起步，因为其任务偏重分析；消费者智能体则从 Sonnet 起步，因为延迟的权重更大。如果你有生产流量，就按真实的查询构成对结果加权。然后让数据来做决定。有时 Opus 5 在推动购物车转化类任务上带来的提升足以证明相对 Sonnet 的成本差值得付出，有时则不然。**‍**
3. **仔细解读结果。**有两件事经常让团队感到意外。第一件是提示词是针对某个模型调优的，因此用某一个提示词跑出的扫描结果，可能会让那些并非为该提示词而写的其他模型表现不佳。较小的模型通常需要当前模型能自行推断出的那些指令，而较大的模型则会严格遵照较小模型此前一直忽略的指令。在排除任何一个候选模型之前，针对每个候选模型的失败案例做几轮迭代是一个成本很低的步骤。第二件是，更智能的配置有时反而在延迟上取胜（最常见于 p90 和 p99），尽管其 token 生成更慢，因为它能更好地规划工具调用，在最复杂的请求上只需更少的轮次。

> 1\. **Pick your metric and your floor.** Pick the quality metrics your business runs on (task completion, answer relevance, grounded accuracy), the eval score you won't go below, and your p50 and p99 latency and cost budgets.
> 2\. **Sweep.** Run your entire eval suite across *every* model and effort level you'd consider. We recommend starting at Opus for merchant agents, whose tasks are analysis-heavy, and Sonnet for consumer agents, where latency weighs more. If you have production traffic, weigh the results by your real query mix. Then let the numbers decide. Sometimes Opus 5's lift on cart-driving tasks justifies the cost difference over Sonnet, and sometimes it doesn't.**‍**
> 3\. **Read the results carefully.** Two things regularly surprise teams. The first is that a prompt is tuned to a model, so a sweep run with one prompt may underperform other models that it wasn't written for. A smaller model usually needs instructions the current model infers on its own, and a larger one will follow instructions to the letter that the smaller one was ignoring. A few rounds of iteration on each candidate's failing cases is a cheap step before ruling any of them out. The second is that a more intelligent configuration sometimes wins on latency (most commonly on p90 and p99) despite slower tokens, because it plans its tool calls better and needs fewer rounds on the most complex requests.

衡量的应当是每完成一项任务的成本，而不是每次模型调用的成本，因为一个更便宜的模型如果需要更多轮次，或者更频繁地失败，那它就并不更便宜。当结果相近，且成本符合你的单任务经济性和延迟要求时，选择更强的智能。质量才是推动采用和留存的因素，并且能为未来 6 个月模型变得更强时的构建留出空间。

> Measure cost per completed task rather than per model call, since a cheaper model that needs more turns, or fails more often, is not cheaper. When the result is close, and the cost fits your per-task economics and latency, choose intelligence. Quality is what drives adoption and retention, and allows for room to build for the next 6 months as models become better.

#### 在生产环境中运行它

> Running it in production

最后，我们讨论让智能体顺利上线生产环境所需的要素：记忆、安全性、评估，以及如何在整个组织范围内扩展这项工作。

> Lastly, we talk about what gets an agent through production: memory, safety, evals, and scaling the work across an organization.

##### **跨会话留存的记忆**

> **Memory that survives the session**

你与客户之间的关系和互动至关重要。记忆能让智能体从上一次对话中断的地方继续，而不是从零开始。三月份提到过坚果过敏的购物者，不应该在六月份还得重复一遍；每周一都要查看同样三个营销活动的商家，也不该每次都得把它们的名字说一遍。长期记忆，即那些应当跨会话留存的事实，是一个你需要构建的系统，它由三部分组成：事实如何存储、如何写入，以及如何读取。

> The relationship and interactions you have with your customers matter. Memory is what lets an agent pick up where the last conversation left off instead of starting from nothing. A shopper who mentioned a nut allergy in March shouldn't have to repeat it in June, and a merchant who checks the same three campaigns every Monday shouldn't have to name them each time. Long-term memory, the facts that should survive across sessions, is a system you build and it has three parts: how facts are stored, how they are written, and how they are read.

###### **存储记忆 **

> **Storing memories **

记忆应当存在于你的系统之中，而不是模型之中。

> Memory belongs in your systems, not in the model. 

当画像规模较小、且智能体是唯一的读取方时，扁平的 markdown 画像是够用的。但大多数生产环境中的商务智能体都会超出这种方式的承载能力，而务实的替代方案就是你已经在运维的数据库。一条事实就是一小段带类型的记录：一个键（例如 shoe_size、default_store、preferred_report_cadence）、一个简短的值、一个类别，以及它所来自的会话。有些键由你预先确定，每个用户都会有；其余的则由抽取器自行发现。随着存储规模增长，数据库依然可以查询，让你能够基于特定属性构建确定性的行为，并与你已有的用户数据进行关联。

> A flat markdown profile works when profiles are small and the agent is the only reader. Most production commerce agents outgrow it, and the practical replacement is the database you already operate. A fact is a small typed record: a key (such as shoe_size, default_store, preferred_report_cadence), a short value, a category, and the session it came from. Some keys you decide up front and every user gets; the rest the extractor discovers. A database stays queryable as the store grows, lets you build deterministic behavior on specific attributes, and joins to the user data you already have.

对于面向商家的智能体，应按人而非按账户来组织记忆。商家登录凭据常常在多个操作员之间共享，因此每个操作员都需要拥有自己的档案，而读取操作必须遵循该操作员的权限：门店经理的智能体不应回忆起区域经理所陈述的事实。

> For merchant-facing agents, key memory by person rather than by account. Merchant logins are often shared between operators, so each operator needs their own profile, and reads have to respect that operator's permissions: a store manager's agent should not recall a fact a district manager stated.

在商业领域，智能体记忆中存储着个人数据。那些值得记住的事实，往往正是受监管最严格的信息，而各司法辖区之间的规则又各不相同。应当把记忆视为一个数据处理的设计问题，而不仅仅是存储问题。落到实处，这意味着四件事：

> In the commerce domain, agent memory holds personal data. The facts worth remembering are often the most regulated ones, and the rules between jurisdictions differ. Treat memory as a data-handling design problem and not just a storage one. In practice that means four things:

- **决定你愿意保存哪些类型的记忆**。在写入路径上强制执行这一点：让每次保存都经过一个校验器，而不是仅仅依赖提示词。
- **给用户提供查看、更正和删除已存储内容的方式。**将删除功能接入你的账户注销和数据请求流程。 
- **设置保留期限。**几年前的偏好很可能已经过时，因此设置保留期限有助于保持记忆事实的新鲜度。
- **记忆功能应当是一个按部署环境设置的开关**。这样，无法承担这些义务的地区就可以在关闭该功能的情况下运行。

> • **Decide which types of memories you are willing to hold**. Enforce that at the write path, with a validator that every save goes through, rather than in the prompt alone.
> • **Give users a way to see, correct, and delete what is stored.** Wire deletion into your account-deletion and data-request flows. 
> • **Set a retention period. **A preference from a few years ago is likely to be outdated, so a retention period helps keep memory facts fresh.
> • **Memory should be a per-deployment switch**. This allows regions that can't take on these obligations to run without it.

###### **写入记忆**

> **Writing memory**

异步写入记忆。在每一轮结束时，或在长会话中每隔几轮，由一个位于独立线程或进程中的智能体读取对话，并在存储中创建、更新或删除事实，随着会话的进行维护它自己的工作上下文。

> Write memory asynchronously. At the end of each turn, or every few turns in a long session, an agent in a separate thread or process reads the conversation and creates, updates, or deletes facts in the store, keeping its own working context as the session goes on. 

它不会给对话增加任何延迟，并且在我们内部的商务记忆评测套件上实现了高出 13% 的事实召回率。

> It adds nothing to the conversation's latency, and achieved 13% higher fact recall on our internal commerce memory eval suite.

显而易见的替代方案——让智能体调用一个工具来保存事实——对于延迟敏感的商务智能体来说并不合适。每一次保存都是面向用户的对话轮次中的一次工具调用，而且除非整个存储都在上下文中，否则保存前需要先读取以便更新或去重，这本身又是一轮往返。

> The obvious alternative, a tool the agent calls to save a fact, is the wrong one for a latency-sensitive commerce agent. Every save is a tool call inside a user-facing turn, and unless the whole store is in context, a save needs a read first to update or dedupe, which is a round of its own. 

它还在每一轮对话中给智能体增加了一个需要做的决策，而在我们的评估中，这种对注意力的争夺表现为记忆遗漏。

> It also puts one more decision in front of the agent on every turn, and in our evals that competition for attention showed up as missed memories.

把提取器分离出来，还让你能够精确地对它下达提示。它只读取用户和助手的文本，绝不读取工具返回的结果，因此商品描述或评论不会变成关于用户的事实。它的提示词规定了什么算作事实——已声明的尺码、饮食限制、履约偏好、某个商家惯用的物化视图——以及什么不算，比如来自商品列表的任何内容或一次性的细节。

> Separating the extractor also lets you prompt it precisely. It reads only the user's and the assistant's text, never tool results, so a product description or a review can't become a fact about the user. Its prompt says what counts as a fact — a stated size, a dietary constraint, a fulfillment preference, a merchant’s usual materialized views — and what doesn't, such as anything from a listing or a one-off detail.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9713df298bf7d2c29e81e1_7480b230.png)

###### **读取内存**

> **Reading memory**

分三层阅读内存。

> Read memory in three layers.

由于记忆是每个用户各自的上下文，它全部放在会话段中，位于全局缓存断点之下。

> Since memory is per-user context, all of it goes in the session segment, below the global cache breakpoint.

##### **安全性：强制约束存在于运行框架中**

> **Safety: enforcement lives in the harness**

提示词是安全行为的起点，但在商业场景中，它不能成为强制执行安全的地方。这里的失败是财务上的，而且往往不可逆，一条提示词规则只要遇到一次注入或一次糟糕的采样就会被跳过。下文的每一条规则都在代码中强制执行，在消费者智能体和商家智能体两侧都是如此，并且只定义一次，从而让每个运行时都共享它。

> The prompt is where safe behavior starts, but in commerce it can't be where safety is enforced. The failures are financial and often irreversible, and a prompt rule is one injection or one bad sample away from being skipped. Every rule below is enforced in code, on both the consumer and the merchant agent, and defined once so every runtime shares it.

###### **模型负责铺陈；由人或策略来落地应用**

> **The model stages; a person or a policy applies**

没有任何模型工具调用会转移资金或改变业务。下单、支付、退款、改价和活动上线，最终都落在由框架而非模型控制的操作上。

> No model tool call moves money or changes the business. Order placement, payments, refunds, price changes, and campaign launches all end in an action the harness controls instead of the model.

在消费者侧，这是结构性的：结账工具渲染出购物车并附带一个下单按钮，而智能体调用的后端接口根本没有扣款方法。 

> On the consumer side this is structural: the checkout tool renders the cart with a button to place the order, and the backend interface the agent calls has no charge method at all. 

在商户侧，每个写入工具都会生成一份带有服务端生成 ID 的暂存变更，而 `apply_change` 只有对那些已通过真实界面获得批准的 ID 才会成功：运营门户中的一个按钮、CLI 中的一次确认，或者当智能体运行在 Managed Agents 上时平台自身的工具批准提示。 

> On the merchant side, every write tool produces a staged change with a server-generated ID, and `apply_change` succeeds only for IDs that have been approved through a real surface: a button in the operator's portal, a confirmation in the CLI, or the platform's own tool-approval prompt when the agent runs on Managed Agents. 

护栏规则会在应用时依据当前的限制重新校验，而不是依据变更暂存时生效的限制。无论采用哪种形式，其结构都是一样的：模型所能采取的最危险的动作就是提出建议，而审批则会经由你的业务在处理此类变更时已经在使用的双人复核（maker-checker）流程。

> The guardrails are re-checked at apply time against current limits, not the limits in force when the change was staged. Whatever the surface, the shape is the same: the model's most dangerous action is to propose, and the approval routes through the maker-checker flow your business already uses for that kind of change.

###### **写入和渲染仅接受服务端签发的 ID**

> **Writes and renders accept only server-issued IDs**

该框架为每个会话保存一份记录，记录服务器交给模型的每一个 ID，而这份记录是任何写入或渲染操作唯一接受的键。

> The harness keeps a per-session record of every ID the server has handed the model, and that record is the only key any write or render will accept. 

购物车只接受服务器在本会话中返回过的商品 ID，商家工具也只接受代理实际读取过的商品列表 ID 和活动 ID。以其他任何方式出现的 ID——凭空捏造的、用户粘贴的、埋在评论里的——都会在后端看到它之前被拒绝。

> The cart accepts only product IDs the server returned to this session, and the merchant tools accept only listing and campaign IDs the agent has actually read. An ID that arrived any other way — hallucinated, pasted by a user, planted in a review — is refused before the backend sees it.

同样的规则也适用于 UI。展示层工具只接收 ID，由服务端自己填入产品、订单或变更记录，因此卡片只会渲染服务端自己填入的记录。

> The same rule covers the UI. Presentation tools take IDs, and the server fills in the product, order, or change records itself, so a card only renders records the server itself filled in.

它同样涵盖委托方：商户分析子智能体只读取数据，绝不会向该智能体可写入的 ID 集合中添加任何内容。

> It covers delegates too: the merchant analysis subagent reads data but never adds to the set of IDs the agent may write to.

对于费用、披露信息及其他受监管内容，由模型选择披露哪款产品，而服务端则从已批准的文案中提供每一个字。同样的费用字段也在商户代理的保护清单上，因此柜台两侧的任何一方都无法更改或改写它们，评估会逐字节检查渲染后的字符串。

> For fees, disclosures, and other regulated content, the model chooses which product to disclose and the server supplies every word from approved copy. The same fee fields are on the merchant agent's protected list, so neither side of the counter can change or paraphrase them, and evals check the rendered strings byte for byte.

###### **有上限的交易必须在重复请求下依然成立 **

> **Capped transactions must hold to repeated requests **

大多数电商界面都会限制单个用户能购买某件商品的数量——出于票务配额、促销定价或反欺诈的考虑——而智能体会以人类点击按钮时从未有过的方式去重试、换个说法再试以及并行发起请求。

> Most commerce surfaces cap how many of an item one user can buy — for ticket allocations, promotional pricing, or fraud control — and an agent will retry, rephrase, and parallelize in ways a human clicking a button never did.

因此，上限是按写入后的行状态来强制执行的，所以第二次「再加两件」无法叠加突破该上限；并且同一会话的购物车写入是串行化的，因此单轮中的并行工具调用也无法合并起来超出上限。

> The cap is therefore enforced on the line as it would be after the write, so a second "add two more" can't stack past it, and cart writes for one session are serialized so parallel tool calls in a single turn can't combine to exceed it. 

商家的变更同样会根据价格波动、折扣深度、补货数量和活动预算的上限进行校验，此外还有一份任何变更都不得触碰的受保护字段清单。这条规则可以推广开来：针对最终状态而非请求本身来强制执行每一项限制，并按会话串行化写入。

> Merchant changes are checked the same way against caps on price movement, discount depth, restock size, and campaign budget, plus a list of protected fields no change may touch. The rule generalizes: enforce every limit on the resulting state rather than the request, and serialize writes per session.

###### **第三方内容会被净化处理**

> **Third-party content is sanitized**

在电子商务领域，大部分上下文都是由并非你自己的人写的——卖家、评价者、竞争对手——所以每一次后端读取都是不可信输入，都要经过同一个净化器处理。

> In commerce most of the context is written by people who aren't you — sellers, reviewers, competitors — so every backend read is untrusted input and goes through one sanitizer. 

每一条由第三方生成的工具结果，例如商品列表、评论、政策、卖家消息和存储的记忆，都会在模型看到之前经过净化处理，并用带有固定标签的围栏包裹起来。

> Every tool result authored by a third party, such as listings, reviews, policies, seller messages, and stored memory,  is sanitized and wrapped in a fence with a fixed label before the model sees it. 

该清洗器会剥离控制字符和双向文本字符，移除任何模仿围栏标记的内容，化解模仿对话轮次或工具调用的文本，并限制大小，其设计目的是阻止恶意列表冒充系统或塞满上下文。

> The sanitizer strips control and bidirectional characters, removes anything that imitates the fence markers, defuses text that imitates a conversation turn or a tool call, and caps the size, which is designed to stop a hostile listing from impersonating the system or filling the context. 

提示词承担了契约的另一半：被围栏包裹的文本是用来汇报的材料，绝不是用来执行的。

> The prompt carries the other half of the contract: fenced text is material to report on, never to act on.

##### **评估：交付一个非确定性系统**

> **Evals: shipping a non-deterministic system**

从小小的提示词改动到新增一个工具，任何变化都可能以难以预测的方式改变智能体的行为，而你正在上线的那个改动往往并不是造成回归的那一个。评估（evals）就是让你在部署之前发现这一点的手段。我们此前那篇关于[智能体评估](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)的博客文章介绍了通用做法。本节讲的是电商类智能体的具体细节。

> Anything from a small prompt change to a new tool can change agent behavior in ways that are hard to predict, and the change you're shipping is often not the one that regresses. Evals are how you find that out before you deploy. Our earlier blog post on [evals for agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) covers the general practice. This section covers specifics for commerce agents.

**评估快照，而非对话**

> **Evaluate snapshots, not conversations**

模型的 API 是无状态的，因此智能体的输出是系统提示词、工具和消息数组的函数。这意味着商务对话所能到达的任何状态都可以被直接构造出来。所以创建一个评估用例，就是构造测试状态、追加测试用户消息，然后让智能体从那里开始运行。

> The model’s API is stateless, so what the agent outputs is a function of the system prompt, the tools, and the messages array. This means any state a commerce conversation can reach can be constructed directly. So creating an eval case means constructing the test state, appending the test user message, and letting the agent run from there. 

然后对结果进行评分：最终状态和渲染后的响应，包括最后一次写入操作的参数。在大多数情况下，我们不建议对智能体到达该结果所走的路径进行评分，因为这类测试用例既脆弱又具有限制性。

> Then grade the outcome: the final state and the rendered response, including the arguments of the last write. In most cases, we recommend against grading the path the agent took to get there as such test cases are brittle and restricting.

模拟用户评测（simulated-user evals）中，由第二个模型扮演用户，再由一个评判模型为整段对话打分，这种做法用于测量的效果很差。两个非确定性系统相互交互，需要更大的样本量、每次试验的成本更高、更难评判，而且产生的失败很难归因。它们的用处在于发现覆盖范围的缺口，以及对智能体做一次总体的感觉性检查，所以应当用它们来发现用例，然后把每个用例写成快照。

> Simulated-user evals, in which a second model plays the user and a judge grades the whole conversation, are a poor tool for measurement. Two non-deterministic systems interacting need larger samples, cost more per trial, are harder to judge, and produce failures that are hard to attribute. They are useful for finding coverage gaps and for a general vibe check on the agent, so use them to discover cases, then write each case as a snapshot.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a97148e18f6986708d53e97_f98ad17a.png)

###### **在严苛条件下评估行为表现**

> **Evaluate for behaviors in tough conditions**

大多数团队都没能正确地测试注入的状态。一个测试用例应当编码失败的前置条件，而不仅仅是任务本身。如果某个行为只有在经历了包含数次工具调用的繁忙首轮之后，或者在会话早期出现矛盾之后才会显现，那么一个从干净状态开始的用例在每种配置下都会通过，无法提供任何有意义的数据。

> Most teams fail to properly test the injected state. A case should encode the preconditions of a failure, not just the task. If a behavior only emerges after a busy first turn with several tool calls, or after a contradiction earlier in the session, a case that starts from a clean state passes on every config and provides no meaningful data. 

我们观察到大多数测试套件都大量集中在这类干净初始状态的用例上，因此请确保你的用例中有一部分是从冗长、混乱或自相矛盾的历史记录开始的。

> We've observed most suites to be heavy on such clean-state cases, so make sure a share of yours starts from long, messy, or contradictory histories.

有效的评估需要同时测试期望的行为和非期望的行为。 

> Effective evaluation requires testing both desired and undesired behaviors. 

为每一个正面用例编写与之对应的反面用例：每有一个"应当拒绝"，就配一个"应当服务"；每有一个"应当询问"，就配一个"应当直接执行"。缺失反面用例是我们在测试套件中发现的最常见的缺口。

> For every positive case, write its negative counterpart: a "should serve" for every "should refuse," a "should just do it" for every "should ask." Missing negatives are the most common gap we find in a suite. 

请评估以下内容：

> Evaluate for the following:

- **核心请求**构成了流量的绝大部分，因为这里出现故障会影响大多数会话。这类请求包括简单查询、多约束条件请求、产品与套餐问题，以及多意图消息。对于这些问题，要检查每一项价格、可用性和属性是否都能追溯到返回的数据，以及在数据缺失时智能体是否会明确说明，而不是凭空编造。
- **依赖上下文的请求**，例如引用屏幕上显示的内容、从此前对话轮次延续下来的约束条件，以及针对已有购物车的写入操作。评估记忆能力也属于这一类。要检查记忆是否被提取、被检索，以及是否改变了答案。
- **安全与品牌类案例**，此类失败会造成金钱或信任上的损失。它们包括注入尝试、试图读取其他用户数据的行为，以及受监管的表述——这类表述需要逐字节核查。将注入分为两种情况：用户撰写的注入，即指令来自用户自己的消息；以及数据面注入，即指令被植入到通过工具结果传入的产品名称、评论或网页片段中。
- **界面评估**，用于确保渲染出正确的组件、遵守条目数量上限，并且面向用户的文本中不含内部标识符。也要测试超时和空结果的情况。
- **同时归属于多种能力的请求。**一位运营人员问道："如果我把这件商品降价 15%，我的库存够不够覆盖需求？"这既是一个定价问题，也是一个库存问题。正确的回答会在安排降价的同时附上库存预测；错误的回答则只做其中一件、漏掉另一件。按单个能力分别编写的评估无法发现这一点，因为每份评估只给自己那一半打分。请为那些需要两个相邻能力协同处理的请求编写测试用例，并对回答的两个部分都进行评分。

> • **Core requests** that make up the bulk of your traffic, since a failure here affects most sessions. These include simple lookups, multi-constraint requests, product and plan questions, and multi-intent messages. For the questions, check that every price, availability, and attribute traces back to returned data, and that the agent says when data is missing rather than inventing it.
> • **Context-dependent requests**, such as references to what is on screen, constraints carried over from earlier turns, and writes against an existing cart. Evaluating memory falls into this bucket as well. Check that memories were extracted, retrieved, and changed the answer.
> • **Safety and brand cases**, where a failure costs money or trust. These include attempted injection, attempts to read another user's data, and regulated language, which is checked byte for byte. Split injection into two cases: user-authored injection, where the directive comes from the user's own message, and data-plane injection, where it is planted in product names, reviews, or web snippets that arrive via tool results.
> • **Interface evaluations**, to ensure the right component is rendered, item caps are respected, and there are no internal identifiers in user-facing text. Test for timeouts and empty results too.
> • **Requests that belong to multiple capabilities at once.** An operator asks "if I mark this down 15%, do I have enough stock to cover the demand?" That is a pricing question and an inventory question together. The right answer stages the markdown with a stock projection attached; the wrong answers do one and skip the other. Evals written per capability won't catch this, because each grades only its own half. Write cases for the requests that need two neighboring capabilities together, and grade both halves of the answer.

与那些亲眼见到失败案例的领域专家合作来设计测试用例，比如产品、法务、商家运营、客户服务和品类管理团队的成员。真实的失败案例能造就最好的评估集，每个用户流程 50-100 个评估用例是一个不错的起点。

> Partner with the subject-matter experts who see the failures firsthand, such as team members in Product, Legal, Merchant Ops, Customer Care, and Category Management, to design test cases. Real failures make the best evals, and 50-100 eval cases per user flow is a good starting point. 

确保覆盖多种类型的用例，如上文所述。生产环境的对话记录是获取新用例的绝佳来源，尤其是那些棘手的用例。编程智能体擅长生成额外的用例和对抗性变体。[参考仓库](https://github.com/anthropics/commerce-agents)中包含一个 Claude Code 插件，其内置的评估编写技能采用了我们推荐的方法构建。

> Make sure to have a variety of cases, as outlined above. Production transcripts are a great stream for sourcing new cases, especially the tricky ones. Coding agents are good at generating additional cases and adversarial variants. The[ reference repository](https://github.com/anthropics/commerce-agents) includes a Claude Code plugin with an eval-authoring skill built with our recommended approach.

###### **在大型组织中交付**

> **Shipping with a large organization**

在一家电商企业中，智能体是由许多工程团队共同构建的。搜索、结算、定价、营销技术、客户服务和商品目录平台各自拥有智能体所依赖的系统，各自按照自己的节奏发布，并且每个团队都会希望添加或修改某个工具、某项技能或某条提示规则。

> In a commerce enterprise the agent is built by many engineering teams. Search, checkout, pricing, marketing tech, customer care, and the catalog platform each own systems the agent depends on, each ships on its own cadence, and each will want to add or change a tool, a skill, or a prompt rule. 

与服务不同，智能体没有保护其他部分的严格模块边界：定价团队所做的改动与结账共享同一个上下文窗口。

> Unlike a service, an agent has no strict module boundary protecting the others: a change made by the pricing team shares a context window with checkout.

一个诱人的解决办法是把系统拆分成许多子智能体，每个业务单元一个。正如第 1 部分所讨论的，出于质量方面的考虑，我们不建议这样做。相反，我们概述了降低多团队协作风险的流程：

> The tempting fix is to break the system into many subagents, one per business unit. As discussed in Part 1, we recommend against it for quality reasons. Instead, we outline the process for de-risking multi-team collaboration:

- **所有权与系统保持一致。**每一项技能和工具都有唯一的归属团队。例如,定价团队拥有促销工具和定价技能,客服团队拥有订单与退货工具以及客户关怀技能。共享提示词的通用部分有唯一的平台级归属方,领域专属部分则由领域归属方负责。
- **变更随其测试用例一同发布，CI 会为它运行一组选定的用例。**贡献某个 skill 的团队同时也要贡献它的测试用例，包括负面用例，以及针对相邻 skill 的边界用例。在每个 pull request 上运行完整的测试套件太慢、成本太高，难以持续下去，所以应该从中构建一个 CI 用例集。该用例集将由一组核心用例组成，其中包含流量最高的请求以及所有安全用例。在此之上，再运行变更所触及部分对应的用例。对于一个 skill，这意味着它自己的用例和它相邻 skill 的边界用例。对于一个工具，则是所有调用它的用例。对于共享提示词，则是完整的 eval 套件，因为所有东西都会读取系统提示词。我们建议以若干次试验的通过率作为门槛，并对缓存命中率和每轮成本设置门槛。每晚以及每次发布前运行完整套件也是一个好做法。跨团队的回归问题正是在这些运行中被发现的。
- **智能体也应纳入发布日程。**它是一个部署单元，因此一次糟糕的变更会同时影响到每一位用户。先把提示词和技能的变更推送给一小批金丝雀用户，保留一个可以在不重新部署的情况下关闭某个技能的开关，并像冻结其他系统那样，在业务高峰期之前冻结智能体。

> • **Ownership follows the systems.** Every skill and tool has a single owner team. For example, pricing owns the promotion tools and the pricing skill, care owns the order and returns tools and the customer-care skill. The shared prompt has a single platform-level owner for the common parts and domain owner for the domain-specific section.
> • **A change ships with its cases and CI runs a set chosen for it.** A team contributing a skill also contributes its cases, including the negative cases and the boundary cases against neighboring skills. Running the full suite on every pull request is too slow and too expensive to survive, so build a CI set from it instead. That set will consist of a core set of cases with the highest-traffic requests and every safety case. On top of that, run the cases for whatever the change touched. For a skill, that means its own cases and its neighbors' boundary cases. For a tool, it is every case that calls it. For the shared prompt, it is the full eval suite since everything reads the system prompt. We recommend gating the pass rate over a few trials, and on cache hit rate and cost per turn. It is also a good practice to run the full suite nightly and before every release. Cross-team regressions are caught in these runs.
> • **The agent should also be inside the release calendar.** It's one deployment unit, so a bad change reaches every user at once. Roll prompt and skill changes to a canary cohort first, keep a switch that turns off one skill without a deploy, and freeze the agent ahead of peak periods the same way you freeze other systems.

关于这种安排中人的一面，参见[构建高效的人机代理团队](https://claude.com/blog/building-effective-human-agent-teams)。

> For the human side of this arrangement, see [Building effective human-agent teams](https://claude.com/blog/building-effective-human-agent-teams).

#### **展望未来**

> **Looking ahead**

本文所描述的大部分内容与模型无关。工具调用的是你已经在运行的系统，技能编码的是你已经在遵循的流程，评估就是把你的产品需求文档写成了测试，而这套框架强制执行的策略，也正是你会对任何客户执行的策略。模型会不断进步，当更好的模型发布时，我们描述的这套架构只需改动一处配置并做一轮评估扫描，就能采用它。其他一切照常运作。

> Most of what this post describes is not about the model. The tools call systems you already run, the skills encode procedures you already follow, the evals are your product requirements doc written as tests, and the harness enforces policy you would enforce for any client. Models will keep improving, and when a better one ships, the architecture we describe adopts it as a config change with an eval sweep. Everything else keeps working.

同样重要的是思考产品界面的路线图。架构的生命周期会比聊天面板更长久。同一个智能体可以通过语音工作，也可以在用户开口之前就主动对票价下跌采取行动。对于已经具备评估体系和工具的团队来说，这些都属于表现层的项目。再往远看，你的店面流量中会有一部分来自代表用户购物的智能体。让你自己的智能体保持在边界之内的那套来源追溯、暂存和审批规则，正是能让你安全地向那些智能体开放工具的东西。

> It is also important to think about your roadmap for product surfaces. The architecture will outlast the chat panel. The same agent can work over voice, and it can proactively act on a fare drop before the user asks. For a team that already has the evals and the tools, those are presentation-layer projects. Further out, some of the traffic to your storefront will come from agents that shop on behalf of users. The same provenance, staging, and approval rules that keep your own agent in bounds are what will let you open your tools to those agents safely.

商业活动向来会奖励那些把购买流程做得尽可能顺畅的做法。智能体让这件事变得容易多了。请查看[完整的参考实现](https://github.com/anthropics/commerce-agents)，其中同时包含消费者智能体和商家智能体，以及零售、旅游、电信和娱乐领域的可运行示例。

> Commerce has always rewarded making the buying process as smooth as possible. Agents make that a lot easier. Check out the [complete reference implementation](https://github.com/anthropics/commerce-agents), with both the consumer and the merchant agent and runnable examples for retail, travel, telecom, and entertainment.

##### **致谢**

> **Acknowledgements**

*作者：Matthew Koen 和 Ali Shazal。特别感谢 Michael Segner、Rodrigo Olivares、Amandeep Khurana、Aiza Usman、John Lopus 以及其他为本文做出贡献的人。*

> *Written by Matthew Koen and Ali Shazal. Special thanks to Michael Segner, Rodrigo Olivares, Amandeep Khurana, Aiza Usman, John Lopus and others for their contributions.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| commerce agent | 商务智能体 | 用于简化在线商品目录中买卖流程的 AI 智能体。 |
| agent loop | 智能体循环 | 模型围绕目标反复推理、调用工具、观察结果直至完成任务的运行模式。 |
| subagent | 子智能体 | 由编排器调用的从属智能体，拥有独立的上下文窗口。 |
| Agent Skills | 智能体技能 | 按需加载到主智能体中的模块化领域指令包。 |
| hand-off | 移交 | 把对话归属权交给另一个智能体，由其直接与用户完成任务。 |
| delegation | 委派 | 编排器保留对话归属权，仅在单轮内把子任务交给领域智能体处理。 |
| system prompt | 系统提示词 | 每次调用都会传入的基础指令，承载高频与关键规则。 |
| harness | 运行框架 | 包裹模型调用的宿主程序，负责工具执行、校验与策略强制。 |
| parallel tool use | 并行工具调用 | 模型在单轮内同时发起多个互不依赖的工具调用以节省轮次。 |
| prompt caching | 提示缓存 | 对请求的公共前缀做缓存复用，以降低输入 token 成本并加快读取。 |
| cache breakpoint | 缓存断点 | 标记缓存前缀边界的位置，需随对话向前滚动以复用累积历史。 |
| eager input streaming | 即时输入流式传输 | 跳过服务端缓冲以获得 token 级流式输出的工具选项，代价是失去 schema 校验保证。 |
| presentation tool | 展示工具 | 以带类型参数的工具调用形式输出 UI 组件的接口约定。 |
| maker-checker | 双人复核 | 由提出方与审批方分离来控制高风险变更的流程机制。 |
| prompt injection | 提示注入 | 在用户消息或工具返回数据中植入指令以劫持模型行为的攻击。 |
| evals | 评估 | 在部署前衡量非确定性智能体质量与回归情况的测试套件。 |
| simulated-user eval | 模拟用户评测 | 由模型扮演用户并由评判模型打分的对话级评估方式。 |
| canary release | 金丝雀发布 | 先向小批量用户推送变更以限制故障影响范围的上线策略。 |
