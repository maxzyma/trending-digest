# Slack 中的自助式数据分析：Anthropic 如何部署 Claude Tag 来应对临时提问

> Self-service data analytics in Slack: how Anthropic deploys Claude Tag for ad-hoc questions

> 来源：Claude Blog / Anthropic，2026-08-13
> 原文链接：https://claude.com/blog/self-service-data-analytics-in-slack-how-anthropic-deploys-claude-tag-for-ad-hoc-questions
> 分类：数据与 AI 工程 / 智能体部署实践

## 核心要点

- 让智能体回答准确与让它可被非分析师随时使用是两类不同的问题，后者需要额外解决分发、权限、新鲜度与可观测性。
- 技能文件被当作需要持续刷新的内容而非一次性发布物，Claude Tag 运行时挂载数据仓库的 skills/ 目录并在每次对话时重新读取。
- 数据模型可能一天变更多次，若技能文件滞后，智能体会自信地给出过时的错误答案，而 Slack 中的数据使用者缺乏仪表板那样的上下文来做直觉检验。
- 仅有告知表结构与语义层组织方式的知识技能只能产出正确数字，无法产出有用洞察，因此还需挂载预测、同期群与留存、漏斗、图表制作、分析性写作等运行手册技能。
- 许多分析约定原本只存在于个别分析师的头脑中，写成技能后可以让 Claude 一致地运用它们。
- 指标波动的原因往往不在数据模型中，因此 Claude Tag 接入了编目公司文档、讨论与事件的内部知识索引，用以检索同期背景信息。
- Claude Tag 以服务账号而非提问者身份查询数据仓库，因此凡能 @ 该机器人的人都拥有其数据访问权限，不存在按用户划分的行级安全控制。
- 权限收敛的五项做法包括：将服务账号限定在受治理数据、按列分类 PII 并拒绝授权、在技能中记录连接路径、把频道成员身份视为访问授权、为每次查询打标签以支持成本归因与审计。
- 每个问题都会记录结构化事件，涵盖加载的技能文件与版本、用户的反馈或纠正、以及相关表的未解决数据质量告警，并支撑采用率与正确性两个视图。
- 采用率指标最具可操作性，其下滑通常意味着技能文件已经漂移或出现了语义层未覆盖的新问题类别。
- 多人参与的公开讨论串让 Claude 承担跑腿工作，旁观者无需专门总结即可了解来龙去脉，掌握信息的人也可随时加入贡献。
- Claude 可通过循环处理主动汇报、测试监控、管道与仪表盘可观测性、数据问题分诊等重复性任务，并可在指定频道中主动介入回答问题。
- 推荐的落地顺序是权限优先、分发其次、从第一天起做好遥测、尽可能建立知识索引、分析技能放在最后。

## 正文

在我们的[上一篇文章](https://claude.com/blog/how-anthropic-enables-self-service-data-analytics-with-claude)中，我们介绍了如何通过三个主要工件让 Claude 以约 95% 的准确率回答数据分析问题：

> In our [previous post](https://claude.com/blog/how-anthropic-enables-self-service-data-analytics-with-claude), we described how we enabled Claude to answer data analytics questions with ~95% accuracy through three primary artifacts: 

- 一个受治理的语义层；
- 一组编码了我们分析惯例的技能文件；以及 
- 用于衡量性能的评估套件。

> • A governed semantic layer; 
> • A set of skill files that encode our analytical conventions; and 
> • An evaluation suite to measure performance. 

那篇文章聚焦于 [Claude Code](https://claude.com/product/claude-code)（我们的数据科学家和数据工程师的主要开发平台），以及提升智能体准确性的最佳实践。

> That post focused on [Claude Code](https://claude.com/product/claude-code) (the primary development surface for our data scientists and data engineers), and best practices for improving agentic accuracy.

本文将介绍 Anthropic 的数据团队如何借助 [Claude Tag](https://claude.com/product/tag)** **(公开测试版) 把这一基础能力应用到公司其他部门的日常工作中，它也是我们在 Slack 中的数据分析智能体的基础。任何人都可以向它提出与数据相关的问题，并获得由**分析师所使用的同一套受治理的定义**支撑的答案。

> This post discusses how the data team at Anthropic applies that foundation to where the rest of the company works using [Claude Tag](https://claude.com/product/tag)** **(public beta), which is the foundation for our data analytics agent in Slack. Anyone can ask it data-related questions and receive answers backed by **the same governed definitions analysts use**. 

![Fictional recreation of a Claude Tag conversation for illustrative purposes. Details, names, and tools are not real.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7e018507d3cd146d296978_11388c5c.png)

#### 在 Slack 中部署数据分析智能体的最佳实践

> Best practices for deploying a data analytics agent in Slack

让智能体做到*准确*，与让它*部署到非分析师也能使用的地方*，结果证明是两件相当不同的事情。我们不会重复上一篇文章中关于准确性的建议，因为那些建议在这里依然适用。

> Getting an agent to be *accurate* and getting it *deployed where non-analysts can use it* turned out to be quite different motions. We won’t rehash our recommendations on accuracy from our prior post as they’re still applicable here. 

相反，我们将介绍过去一年中我们最重要的五点经验：如何在 Slack 中部署数据分析智能体，以及你应该如何思考分发、权限、新鲜度和可观测性。

> Rather, we’ll cover our five most important learnings over the past year for how to deploy a data analytics agent in Slack and how you should think about distribution, permissions, freshness, and observability.

##### 更新技能的频率应与更新数据模型的频率一样高

> Refresh skills as often as you refresh your data models

你可以使用 [skill](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more) 来教 Claude 按照你的风格和要求完成任务，它是一个包含自然语言指令的 markdown 文件，以及 Claude 在需要时可以参考的文件。

> You can teach Claude how to do a task aligned with your style and requirements using a [skill](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more), which is a markdown file with natural language instructions and files Claude can reference when needed.

我们做出的最重要的架构决策，是把技能文件当作**被持续提供的内容**来对待，不断刷新，而不是一次性发布后就被遗忘的东西。 

> The single most important architectural decision we made was to treat skill files as **served content**, refreshed continuously, rather than something shipped once and forgotten. 

数据模型可能一天变更好几次。例如，某个列被重命名、某项指标定义被修正，或某张表被弃用。这些变更中的每一项都需要在相对较短的时间内落实到 skill 文件中。如果 Claude 读取的是上周二那份 skill 副本，它就会满怀信心地给出上周二那个错误的答案。

> Data models can change several times a day. For example, a column gets renamed, a metric definition is corrected, or a table is deprecated. Every one of those changes needs to land in a skill file in relatively short order. If Claude is reading last Tuesday's copy of the skill, it gives last Tuesday's wrong answer with full confidence.

这种倾向可能尤其有害，因为此时数据使用者已经与判断回答准确性所需的上下文完全隔绝。他们看到的不是带有趋势线或相关指标、可以帮助他们进行“直觉检验”的仪表板。他们可能只会在 Slack 中收到一两个数据点；如果这些不是他们经常查看的数据，他们很可能会接受那个自信却错误的答案。

> This tendency can be especially damaging since the data consumer is now completely separated from the context they need to judge the accuracy of the response. They aren’t looking at a dashboard with trend lines or associated metrics that can guide their “sniff test.” They may receive just a single data point or two in Slack, and if it's not data they look at regularly, they are likely to accept that confidently wrong answer.

为了掌控这个不断变化的环境，Claude Tag 的运行时会挂载我们数据仓库的 skills/ 目录，并**在每次对话时重新读取它**。这些技能文件只是磁盘上的 markdown 文件；智能体读取它们的方式，与读取任何项目文件的方式完全相同。 

> To control this ever-changing environment, Claude Tag's runtime mounts our data repo's skills/ directory and **re-reads it on every conversation**. The skill files are just markdown on disk; the agent reads them the same way it would read any project file. 

##### 赋予智能体超越"知道查询什么"的能力

> Give the agent skills beyond knowing what to query 

我们最初的直觉是，用 Claude Tag 部署数据分析智能体时，只需创建一个“知识技能”，教会 Claude 该使用哪些表、我们的语义层是如何组织的，然后就大功告成。我们很快就发现，这种做法能给出*正确*的*数字*，却达不到*有用*的*洞察*。

> Our initial instinct for deploying our data analytics agent using Claude Tag was to create a “knowledge skill,” which teaches Claude which tables to use and how our semantic layer is organized, and call it a day. We quickly determined that approach would provide *correct* *numbers*, but stop short of *useful* *insights*.

大多数数据使用者往往会提出开放式且含糊的问题，比如「是什么导致了这次下滑？」「你能预测月底会落在什么水平吗？」或者「把这些数据以漏斗图的形式展示给我」。要回答这些问题，智能体不仅需要知道*数据在哪里*，还需要知道*分析师会如何使用这些数据*。

> Most data consumers tend to ask open-ended and ambiguous questions like "what's driving this dip?" or "can you forecast where this lands at month-end?" or "show me this data as a funnel." Answering those requires the agent to know not just *where the data is* but *how an analyst would work with it*.

因此，除了这项知识技能之外，我们还为 Claude Tag 挂载了额外的分析或运行手册技能，包括：

> So alongside this knowledge skill, we mounted Claude Tag with additional analytics or runbook skills, including:

- **预测**：何时以及如何拟合简单趋势、季节性假设，以及何时因序列过短或噪声过大而拒绝预测。
- **同期群与留存分析**：标准的同期群定义、向管理层汇报的留存曲线模板，以及那些会让粗糙实现踩坑的注意事项（左删失、幸存者偏差）。
- **漏斗分析**：为关键产品漏斗提供规范的阶段定义，这样「用户在新手引导的哪个环节流失？」这类问题在不同回答中能保持一致。
- **图表制作**：可视化惯例，比如针对什么问题该用哪种图表类型、配色方案，以及什么时候表格比图更清晰。
- **分析性写作**：如何组织一条发现（先给 TL;DR，再给数字、机制、注意事项），以及在给定置信度下应采用何种程度的措辞保留。

> • **Forecasting**: when and how to fit a simple trend, seasonality assumptions, and when to refuse because a series is too short or too noisy.
> • **Cohort and retention analysis**: standard cohort definitions, the retention curve template reported to leadership, and any gotchas (left-censoring, survivorship) that trip up naive implementations.
> • **Funnel analysis**: the canonical stage definitions for key product funnels, so "where are users dropping off in onboarding?" is consistent across responses.
> • **Charting**: visualization conventions like which chart type to use for which question, color palettes, and when a table is clearer than a plot.
> • **Analytical writing**: how to structure a finding (TL;DR first, number, mechanism, caveat), and the level of hedging that’s appropriate given the degree of confidence.

每个数据团队大概都已经有这些约定了；只是它们通常只存在于某个人的脑子里，偶尔才会被记录下来。把它们作为技能写下来，可以确保 Claude 像你的数据科学家一样始终如一地运用它们。

> Every data team likely already has these conventions; they just usually live in someone's head and are only occasionally documented. Writing them down as skills ensures Claude applies them as consistently as your data scientist would.

##### 连接业务上下文，而不仅仅是数据仓库

> Connect to business context, not just the warehouse

即使把知识类技能和操作手册类技能结合起来，也未必总能回答一个问题。当有人问「为什么周二的注册量下降了？」时，答案往往并不在数据模型里，而是常常散落在 Slack 讨论串、事故追踪系统、发布说明和文档之中。

> Even this combination of knowledge skills and runbook skills is not always enough to answer a question. When someone asks "why did sign-ups drop on Tuesday?", the answer often isn’t in the data model, but rather is frequently spread across Slack threads, incident trackers, release notes, and docs.

为了弥补这些缺口，我们将 Claude Tag 接入了内部知识索引，该索引对公司范围内的文档、讨论和事件进行了编目。当智能体发现某项指标出现波动时，它可以在该索引中搜索*同期背景信息*：当天早上开启的一起事故、某个被切换的功能开关、有人在频道里分享的竞争对手公告。

> To account for these gaps, we wire Claude Tag into our internal knowledge index, which catalogs documents, discussions, and events across the company. When the agent sees a metric move, it can search that index for *contemporaneous context*: an incident opened that morning, a feature flag flipped, a competitor announcement someone shared in a channel. 

现在的答案看起来会是这样：“周二注册量下降了 12%：那天上午 9 点至 11 点期间有一起支付服务事故未解决，且下降集中在受影响的地区。”

> The answer now would look like "sign-ups dropped 12% Tuesday: there was a payment-service incident open 9-11am that morning, and the dip is concentrated in the affected region."

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7e018507d3cd146d2969dd_0990031b.png)

如果你的组织拥有知识图谱、内部搜索，甚至只是组织良好的事故与变更日志信息流，那么在数据仓库本身之外，将 Claude Tag 连接到这些资源，是你能补充的杠杆效应最高的信息。你还可以[连接 Claude Tag，让它能够读取并从 Slack 各个关键频道中获取上下文](https://claude.com/docs/claude-tag/admins/attach-to-scope#attach-to-a-channel)。 

> If your organization has a knowledge graph, internal search, or even just well-organized incident and changelog feeds, connecting Claude Tag to them is the highest-leverage information you can add after the warehouse itself. You can also [connect Claude Tag so it can read and get context from key channels across Slack](https://claude.com/docs/claude-tag/admins/attach-to-scope#attach-to-a-channel). 

##### 为服务账号审慎地分配权限

> Permission the service account deliberately

Claude Tag 以服务账号的身份查询你的数据仓库，而不是以提问的那个人的身份。虽然这是正确的设计（因为你不会希望每个 Slack 用户都需要直接的数据仓库凭据），但[每个能够 @ 这个机器人的人，都拥有该机器人的数据访问权限](https://claude.com/blog/agent-identity-access-model)**。**这里不存在按用户划分的行级安全控制：服务账号能读取的内容，频道里的任何人都可以拿来提问。

> Claude Tag queries your warehouse as a service account, not as the human who asked the question. While that's the right design (since you don't want every Slack user requiring direct warehouse credentials), [everyone who can mention the bot has the bot's data access](https://claude.com/blog/agent-identity-access-model)**. **There is no per-user row-level security: what the service account can read, anyone in the channel can ask about.

我们从五个方面着手（我们建议认真对待这一点，因为它很容易出错，而且难以撤销）：

> We approach this in five ways (and we recommend taking this seriously as it’s easy to get wrong and hard to undo):

**1. 将服务账号的权限范围限定在受治理的数据上。**在 Anthropic，Claude Tag 的服务账号可以读取语义层的输出表以及为其供数的精选数据集市。它无法读取原始事件流、暂存模式（staging schemas），或任何个人沙箱中的内容。如果某个问题需要用到该边界之外的数据，智能体会直接说明，而不是靠猜测作答。这同时也是正确的用户体验，因为受治理层之外的数据尚未经过验证。

> **1. Scope the service account to governed data only.** At Anthropic, Claude Tag's service account can read the semantic layer's output tables and the curated marts that feed them. It cannot read raw event streams, staging schemas, or anything in a personal sandbox. If a question requires data outside that boundary, the agent says so rather than guessing. That is also the right user experience because data outside the governed layer hasn't been validated.

**2. 在列级别对 PII 进行分类，并拒绝授予服务账号访问权限。**受治理的数据并不自动等同于 PII 安全的数据（例如，一张经过整理的表仍可能包含电子邮件地址）。我们维护了一个具备列级血缘的数据目录，因此每一列的来源和下游流向都是已知的。当新的列进入系统时，Claude 会扫描它们，并标记出可能的 PII 候选项供人工审核。随后由人工在该列的元数据中应用分类，血缘关系会将该标签传播到派生表。由于 Claude Tag 的服务账号不具备 PII 访问权限，数据仓库的列级访问控制会使任何 PII 列对该智能体不可见。它可以查询该表，但敏感列根本无法读取。

> **2. Classify PII at the column level and deny the service account clearance. **Governed data isn’t automatically PII safe data (e.g., a curated table can still carry an email address). We maintain a data catalog with column-level lineage, so every column’s origin and downstream flow is known. When new columns land, Claude scans them and flags likely PII candidates for human review. A human then applies the classification in the column’s metadata, and lineage propagates that label to derived tables. Given Claude Tag’s service account holds no PII clearance, the warehouse’s column-level access controls make any PII columns invisible to the agent. It can query the table, but the sensitive columns simply aren’t readable.

**3. 在技能自身中记录连接路径。**我们的数仓技能有一个专门的章节，说明智能体*如何*连接（是通过 CLI、直接调用 API，还是通过 MCP 服务器），以及每条路径下认证具体是怎样工作的。这个看似平淡的特性让我们能够区分智能体是干净利落地失败（“我无法从这个界面访问数仓；原因如下”），还是令人困惑地失败（一个查询悄无声息地跑在了错误的项目上，或者认证提示被转发到了不该去的地方）。当连接机制写在技能里时，智能体就能解释自身的约束。

> **3. Document the connection path in the skill itself.** Our warehouse skill has a dedicated section on *how* the agent connects (whether via CLI, direct API, or an MCP server) and exactly how authentication works for each path. This prosaic feature allows us to differentiate between the agent failing cleanly ("I can't reach the warehouse from this surface; here's why") versus failing confusingly (a query that silently runs against the wrong project, or an auth prompt relayed somewhere it shouldn't be). When the connection mechanics are in the skill, the agent can explain its own constraints.

**4. 把 Claude 的频道成员身份视为一种访问授权。**把 Claude Tag 加入某个 Slack 频道，实际上就等于授予该频道成员对该智能体所能查询的一切内容的读取权限。我们把这一点明确化：Claude 由数据团队成员添加到频道中，并且频道清单由数据团队负责维护。

> **4. Treat Claude’s channel membership as an access grant.** Adding Claude Tag to a Slack channel is, in effect, granting that channel's members read access to whatever the agent can query. We made this explicit: Claude is added to a channel by a data-team member, and the data team owns the list of channels.

**5. 为每一次查询打标签。** 对于每一个数仓查询，Claude Tag 都会携带标识来源界面、会话以及请求用户（在 Slack 提供该信息时）的标签。这在查询时并不强制执行任何限制，但它提供了成本归因和审计追踪（事后你可以确定是谁提出了那个扫描了 4 TB 数据的问题）。

> **5. Label every query.** For every warehouse query, Claude Tag carries labels identifying the surface, the conversation, and the requesting user (where Slack provides it). This doesn't enforce anything at query time, but it provides cost attribution and audit trails (you can determine who asked the question that scanned 4 TB after the fact).

我们的总体立场是，Slack 中的数据分析智能体就是**你受治理的数据仓库的一个共享只读副本，**我们也在按这个定位来限定它的权限范围。

> Our general posture is that a data analytics agent in Slack is a **shared read replica of your governed warehouse,** and we try to scope it as such.

##### 为每个答案添加监测埋点

> Instrument every answer

判断智能体是否给出了充分的回答，并不是靠肉眼一看就能做到的事。

> Determining whether the agent gave a sufficient answer is not something you can eyeball.

对于 Claude Tag 处理的每一个问题，我们都会记录一条结构化事件。其中包括：

> We log a structured event for every question Claude Tag handles. This includes:

- 加载了哪些技能文件以及对应的版本；
- 用户是用 👍/👎 作出反应，还是回复了一条纠正；以及 
- 它所涉及的表上任何未解决的数据质量告警。我们还会在答案的页脚呈现所有数据质量告警，这样陈旧数据的提醒就会出现在数字旁边，而不是无从察觉。

> • Which skill files were loaded and at what version; 
> • Whether the user reacted with 👍/ 👎 or replied with a correction; and 
> • Any open data quality warnings on the tables it touched. We also surface any data quality warnings in the answer's footer, so a stale-data alert appears next to the number rather than being invisible.

这些遥测数据支撑两个视图。一个跟踪**采用率**，即按接入面和领域划分，有多大比例的智能体查询是经由受治理的层而非临时 SQL 完成的。另一个跟踪**正确性**，按领域以 👎 反馈和纠正的发生率来衡量。这是两次评估运行之间用于反映准确率的在线代理指标。

> This telemetry feeds two views. One tracks **adoption **or what fraction of agent queries route through the governed layer rather than ad hoc SQL by surface and domain. The other tracks **correctness** measured by the rate of 👎 reactions and corrections by domain. This is the online proxy for accuracy between eval runs.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7e018507d3cd146d2969e3_07987b0d.png)

事实证明，采用率指标是我们所追踪的所有数字中最具可操作性的一个。当某个领域的该指标下滑时，几乎总是意味着两种情况之一：要么某个技能文件已经发生漂移，要么出现了语义层未能覆盖的一类新问题。

> The adoption metric turned out to be the single most actionable number we tracked. When it dips for a domain, it almost always means either a skill file has drifted or a new class of questions has appeared that the semantic layer doesn't cover. 

#### 这如何加速自助式分析的采用

> How this accelerates self-service analytics adoption

##### Claude Tag 讨论串成为新的会议形式 

> Claude Tag threads become the new meeting 

我们最喜欢、最有效的 Claude Tag 讨论串通常都有多人参与。在这些情况下，我们看到人们贡献想法和背景信息，而由 Claude 来处理跑腿的工作。

> Our favorite, most effective Claude Tag threads usually have multiple people in them. In these cases we see people contributing ideas and context while Claude handles the legwork. 

例如，一位数据团队成员询问 Claude，为什么某个营收仪表盘的加载时间比平时多了几分钟。Claude 发现查询结果没有被缓存，并且有一个 bug 拖慢了结果送达页面的速度。

> For example, a data team member asked Claude why a revenue dashboard was taking a few minutes longer than usual to load. Claude discovered query results weren't being cached and a bug was slowing down how results reached the page. 

Claude 通知了仪表板的所有者，对方决定立即修复缓存，同时另行处理这个 bug。

> Claude notified the dashboard owner who decided to fix the cache immediately while handling the bug in a separate motion. 

随后，负责人询问还有哪些仪表板变慢了，结果发现有数十个仪表板都受到了同一个缓存错误的影响。Claude 编写了缓存修复方案，数据团队成员对其进行了审核，所有受影响的仪表板在不到一小时内就恢复了满负荷运行。

> The owner then asked what other dashboards had slowed, and it turned out dozens were impacted by the same caching error. Claude wrote the caching fix, the data team member reviewed it, and all impacted dashboards were functioning at full capacity in less than an hour.

![Fictional recreation of a Claude Tag conversation for illustrative purposes. Incident details, names, and tools are not real.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7e018507d3cd146d2969e0_0dceb0a6.png)

这些讨论串是公开的，这一点在多个方面都很有帮助。旁观阅读的人无需别人专门写一份总结，就能自行了解来龙去脉（出了什么问题、原因是什么、又是怎么修复的）。更重要的是，他们不必只做被动的读者。任何掌握有用信息的人都可以随时加入并做出贡献，就像上面例子中团队成员所做的那样。

> These threads are open which is helpful for multiple reasons. People reading along pick up context (what broke, why, how it got fixed) without anyone writing a summary for them. More importantly, they don't have to remain passive readers. Anyone who knows something useful can jump in and contribute, the way the team members did in the example above.

因此，把智能体留在共享频道里，并把工作放在讨论串中而不是私信里，因为讨论串可以充当一份可供审阅的历史记录。

> So keep the agent in shared channels and keep the work in threads instead of DMs, as the thread can function as a reviewable historical record.

##### Claude Tag 处理重复性任务

> Claude Tag handles repetitive tasks

大量数据工作是重复性的：流水线健康检查、KPI 监控等。你可以让 [Claude 创建循环](https://www.youtube.com/watch?v=SlGRN8jh2RI)，按计划或在出现异常变化时处理这些周期性任务。我们已经实现的一些数据领域的具体示例包括：  


> A lot of data work is recurring: pipeline health checks, KPI monitoring, etc. You can ask [Claude to create loops](https://www.youtube.com/watch?v=SlGRN8jh2RI) that can handle cyclical tasks on schedule or in response to unusual changes. Some data specific examples we’ve implemented include:  

- **主动汇报**：Claude 会在每周站会前提供一份摘要：上周有哪些进展、与前一周相比如何，以及有哪些值得关注的地方。 
- **测试监控**：当我们监控一次发布或一项实验时，Claude 每天会多次提供数据简报。在最近的一次实验中，它注意到设置在中途发生了变化，帮助我们及早发现并修复了这个问题。
- **可观测性**：其他循环负责监控我们的数据管道和仪表盘。如果某条管道出现故障，Claude 会开始排查、起草修复方案，并通知值班人员。如果某项 KPI 出现异常波动，Claude 会给出可能的解释：是节假日效应？还是上游数据发生了变化？并在任何人打开仪表盘之前就完成核查。
- **分诊**：另一个循环会跟踪我们的数据问题频道。对于每一个新问题，它都会做出判断：直接回答、启动更深入的调查，或者引入人工介入。等到数据团队的人来查看时，大部分工作都已经完成了。  


> • **Proactive Readouts**: Claude provides a summary before a weekly standup: what moved last week, how it compares to the week prior, and what’s worth noting. 
> • **Test Monitoring**: When we’re monitoring a launch or an experiment, Claude provides readouts multiple times a day. During one recent experiment, it noticed the settings had changed partway through and helped us catch and fix it early.
> • **Observability**: Other loops monitor our pipelines and dashboards. If a pipeline fails, Claude starts investigating, drafts a fix, and pings the person on call. If a KPI moves unexpectedly, Claude provides likely explanations: a holiday effect? an upstream data change? and checks them before anyone opens a dashboard.
> • **Triage**: Another loop tracks our data questions channel. For each new question, it makes a call: answer it directly, start a deeper investigation, or bring in a human. By the time someone from the data team checks, most of the work is already done.  

Claude 也可以帮忙设计这个循环。问问 @Claude 它在你的频道里见过哪些重复性工作，以及它能提供什么帮助。

> Claude can also help design the loop. Ask @Claude what repetitive jobs it’s seen in your channels and how it can help.

##### 在需要时介入

> Stepping in when needed

你可以让 Claude 在你选择的任何频道中更加主动，一边跟读内容，一边在需要时介入提供帮助。在过去一个月里，我们的一个数据频道中，Claude Tag 回答了人们发布的 75% 以上的问题，通常在一两分钟内就能回复，甚至无需被主动呼叫。

> You can allow Claude to be more proactive in any channel you choose, reading along and stepping in to help when needed. In one of our data channels over the last month, Claude Tag answered more than 75% of questions people posted, typically within a minute or two, even without being called. 

例如，一位 Anthropic 团队成员在一个公开频道中询问某个仪表盘是否包含了一个新的使用类别。在 90 秒内，Claude 回答了这些数据是如何定义的，确认了新细分类别确实缺失，提出了修复方案，并起草了一个 PR。一位数据科学家进行了审查并批准。随后 Claude 合并了该 PR 并刷新了仪表盘。

> For example, an Anthropic team member asked in a public channel whether a dashboard included a new usage category. Within 90 seconds Claude answered how the data was defined, confirmed the new segment was missing, proposed a fix, and drafted a PR. A data scientist reviewed and approved. Claude then merged the PR and refreshed the dashboard. 

![Fictional recreation of a Claude Tag conversation for illustrative purposes. Incident details, names, and tools are not real.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7e018507d3cd146d2969f4_e14fa07b.png)

#### 快速开始

> Getting started

如果你已经完成了[我们第一篇文章](https://claude.com/blog/how-anthropic-enables-self-service-data-analytics-with-claude)中的工作，那么 Slack 部署基本上只是接线的活儿，不过顺序很重要：

> If you've already done the work from [our first post](https://claude.com/blog/how-anthropic-enables-self-service-data-analytics-with-claude), the Slack deployment is mostly plumbing, though the order is important:

1. **权限优先。**在写下第一行 agent 代码之前，先确定服务账号可以读取哪些内容。放宽访问权限要比事后收回容易得多。
2. **分发其次。**选择挂载仓库或 skills-over-MCP 方案，并端到端验证新鲜度：修改一个 skill 文件，确认 Claude Tag 能在你的 SLA 时限内识别到该变更。
3. **从第一天起就做好遥测。** 你无法回过头去给一个月前的对话补埋点。请在最初的那个问题上就记录结构化事件。
4. **尽可能建立知识索引。**数据仓库回答的是*是什么*；而你的内部文档和事故信息流回答的是*为什么*。一旦数据链路稳定，就尽快把它们接入进来。
5. **分析技能放在最后。**先创建数据访问技能，然后让真实的问题告诉你，你的同事究竟需要哪些分析师技能（预测、同期群、漏斗）。

> • **Permissions first.** Decide what the service account can read before you write a line of agent code. It's much easier to widen access later than to claw it back.
> • **Distribution second.** Pick mounted-repo or skills-over-MCP and verify freshness end-to-end: change a skill file, and confirm Claude Tag picks it up within your SLA.
> • **Telemetry from day one.** You will not retroactively instrument month-old conversations. Log the structured event on the very first question.
> • **Knowledge index when you can.** The warehouse answers *what*; your internal docs and incident feeds answer *why*. Wire them in as soon as the data path is stable.
> • **Analytics skills last.** Create the data-access skill first and then let real questions inform which analyst skills (forecasting, cohorts, funnels) your co-workers actually need.

*本文由 Anthropic 数据科学与数据工程团队成员 Clement Peng 和 Lily Zhao 撰写，Josh Cherry 和 Michael Segner 亦有贡献。*

> *This article was written by Clement Peng and Lily Zhao, members of Anthropic's Data Science and Data Engineering team, with contributions from Josh Cherry and Michael Segner.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| semantic layer | 语义层 | 在原始数据之上定义统一指标与实体口径的受治理抽象层。 |
| skill | 技能 | 包含自然语言指令与参考文件的 markdown 文件，用于教模型按特定方式完成任务。 |
| eval suite | 评估套件 | 用于系统性衡量智能体回答质量与准确率的一组测试用例。 |
| service account | 服务账号 | 供程序或智能体使用的非人类身份，其权限决定了可访问的数据范围。 |
| row-level security | 行级安全 | 按用户身份限制其可读取数据行的数据库访问控制机制。 |
| PII | 个人身份信息 | 可用于识别特定自然人的数据，如邮箱、电话等。 |
| column-level lineage | 列级血缘 | 记录每一列数据来源与下游流向的追踪关系，可用于传播敏感标签。 |
| data mart | 数据集市 | 面向特定业务主题整理的精选数据集合。 |
| staging schema | 暂存模式 | 数据加载过程中存放中间态、未经验证数据的数据库模式。 |
| cohort analysis | 同期群分析 | 按共同起始特征分组，追踪各组随时间变化行为的分析方法。 |
| left censoring | 左删失 | 观测起点之前已发生的事件无法被记录，导致统计偏差的现象。 |
| survivorship bias | 幸存者偏差 | 只统计留存下来的样本而忽略已流失样本所造成的结论偏差。 |
| funnel analysis | 漏斗分析 | 按规范化阶段定义衡量用户在流程各环节转化与流失的分析方法。 |
| MCP server | MCP 服务器 | 按模型上下文协议为智能体提供工具与数据访问能力的服务端。 |
| telemetry | 遥测 | 为每次交互记录的结构化运行数据，用于监测采用率与正确性。 |
| feature flag | 功能开关 | 无需发版即可控制功能是否对用户生效的配置项。 |
| SLA | 服务等级协议 | 对响应时延、数据新鲜度等指标做出的约定性承诺。 |
