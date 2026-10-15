# ABC Legal 如何借助 Claude Managed Agents 让每位员工都成为构建者

> How ABC Legal turned every employee into a builder with Claude Managed Agents

> 来源：Claude Blog / Anthropic，2026-08-17
> 原文链接：https://claude.com/blog/how-abc-legal-turned-every-employee-into-a-builder-with-claude-managed-agents
> 分类：AI 工程 / 企业智能体落地

## 核心要点

- ABC Legal 向 1,100 名员工推出 Claude Enterprise 后，各部门自发构建自动化流程，CTO Brandon Fuller 随后部署 Claude Managed Agents，将散落在个人台式机上的智能体迁移到云端统一管理。
- 截至 2026 年 7 月，公司已有 50 多个基于 Managed Agents 的生产智能体，部分任务成本最多降低约 50%，约 310 名员工在日常工作中使用 Claude。
- 每个智能体都以代码形式定义，提示词、工具列表、调度计划、凭据和记忆写入配置文件并存放在 git 仓库中，任何变更都须通过经人批准的拉取请求进行。
- Fuller 搭建了事件驱动型和定时型两个入门模板，由非开发人员组成的 15 人指导委员会借助 Claude Code 在一周内都构建出可运行的智能体，并在一个月内带动约 50 多个智能体上线。
- 智能体已覆盖代码审查、证据记录递送、电子立案驳回诊断、任务核验、律师出庭协调、应收账款核销、广告分析和服务工单审核等环节。
- 对需要评分反馈的智能体，公司采用初始智能体、Harvester 和 Tuner 三角色架构，将 Slack 中的回复和表情回应转化为对提示词或配置的版本化修改，由人工审核合并。
- 姊妹公司 Docketly 将约 145 个交付路由规则集存为 git 中的 YAML 文件，由四个智能体组成的闭环可在一周内把一次路由错误标记转化为已合并的规则变更。
- Fuller 选择 Managed Agents 的标准包括版本管理、可观测会话、工作区计费、模型选择、记忆原语、MCP 接入以及免于维护基础设施，并按任务需求在 Sonnet、Haiku 和 Opus 之间切换模型。
- 公司以智能体交付价值与运行成本之比作为效率指标，智能体通常从人在回路模式起步并遵循 J 曲线，在证明判断与人类一致后才转为自主运行。
- Fuller 总结的实践原则包括把一切视为代码、以 PR 作为控制面、投资反馈循环、直接采用 Managed Agents、预期 Git 而非 AI 才是主要门槛，以及并非每项任务都值得动用智能体。

## 正文

今年早些时候，美国法律文书递送公司 ABC Legal 的 CTO Brandon Fuller 向公司 1,100 名员工推出了 [Claude Enterprise](https://claude.com/solutions/enterprise)，效果立竿见影。公司各个团队（包括送达、电子立案和出庭律师业务团队，以及市场、合规、财务等部门）在无人要求的情况下，纷纷自发地开始构建自动化流程。

> When Brandon Fuller, CTO of ABC Legal, a U.S.-based legal document delivery company, rolled out [Claude Enterprise](https://claude.com/solutions/enterprise) to the company's 1,100 employees earlier this year, something clicked immediately. Teams across the company (service of process, eFiling, and appearance counsel operations, plus marketing, compliance, finance, and more) started building automations on their own, without being asked.

“我们的用户真的是蜂拥而至，”Fuller 回忆道，“他们看到了连接器和工具的易用性，突然之间，整个组织里到处都有人在把那些一直以来占据他们大量时间的任务自动化。”

> "Our users really flocked to it," Fuller recalls. "They saw the ease of use of connectors and tools, and suddenly we had people all over the organization automating the tasks that had always eaten up their day."

这正是任何一位 CTO 都梦寐以求的采用情况。但 Fuller 看到了更进一步的机会：如果 ABC Legal 还能运行一支 AI 智能体队伍，并且这些智能体可版本化、可观测、始终在线，那会怎样？

> It was exactly the kind of adoption any CTO hopes for. But Fuller saw an opportunity to go further: what if ABC Legal could also run a fleet of AI agents that were versioned, observable, and always on?

这一雄心最终归结为基础设施问题。早期的智能体由构建者随手安置，以计划任务的形式运行在各自的台式机上。将它们从个人电脑上迁移出去，既能让它们无人值守地运行，也能让 Fuller 在单一视图中掌握已构建了哪些智能体、花费多少，以及它们昨晚是否运行过。

> That ambition came down to infrastructure. Early agents lived wherever their builder happened to put them, as scheduled tasks on individual desktops. Moving them off personal machines would let them run unattended and give Fuller a single view of what had been built, what it cost, and whether it ran last night.

于是他部署了 [Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview)：统一的通用部署结构、共享工作区、单一的审计与计费入口，以及运行在云端而非个人笔记本电脑上的常驻智能体。

> So he deployed [Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview): one common deployment structure, shared workspaces, a single audit and billing surface, and always-on agents in the cloud instead of on a person’s laptop.

截至 2026 年 7 月，Fuller 及其在 ABC Legal 的团队已追踪到：

> As of July 2026, Fuller and his team at ABC Legal have tracked:

- 生产环境中基于 Managed Agents 构建的 50 多个智能体
- 在尚未进行深度优化之前，部分智能体所覆盖的人工任务成本最多可降低约 50%
- 约 310 名员工，遍布各个部门，在日常工作中使用 Claude

> • 50+ agents built with Managed Agents in production
> • Up to ~50% reduction in the cost of the human tasks some agents cover, before heavy optimization
> • ~310 employees across every department using Claude for daily work

以下是他们实现这一目标的过程，以及在此过程中收获的经验。

> Here’s how they got there and what they learned in the process.

#### 从热情到工程化：像对待软件一样对待每一个智能体

> From enthusiasm to engineering: treating every agent like software

在首次部署 Claude Managed Agents 时，Fuller 让团队将每个智能体都以代码形式定义。他认为这是智能体天然应有的形态。正如他所解释的：“智能体本质上只是结构化文本，即一段提示词加上配置，而任何文本都可以存放在代码仓库中，让整个公司都能查看、审阅和改进。”智能体的提示词、工具列表、调度计划、凭据和记忆，全都写入配置文件，与公司的软件一起保存在 git 仓库中。智能体的任何变更都必须通过经人批准的拉取请求进行，这让每个智能体都拥有版本历史、代码审查、回滚能力和审计记录。

> When they first deployed Claude Managed Agents, Fuller had the team define every agent as code. He believes this is the natural form for an agent to take. As he explains, “an agent is really just structured text, a prompt plus configuration, and anything that is text can live in a repository where the whole company can see it, review it, and improve it.” An agent's prompt, tool list, schedule, credentials, and memory all go into configuration files kept in a git repository alongside the company's software. Nothing about an agent changes except through a pull request someone approves, which gives every agent version history, code review, rollback, and an audit trail.

他花了一周时间搭建了一套入门工具包，包含两个模板，分别存放在专用的 git 仓库中。一个用于事件驱动型智能体，它们会在某件事发生的那一刻启动，比如有新任务到来，或者有文件从法院返回。另一个用于定时型智能体，它们按计划定时运行：每小时、每天或每周。每个智能体都存放在各自的文件夹中，采用标准结构：一个 JSON 配置文件、一份 Markdown 格式的系统提示词、部署脚本以及运维文档。将变更合并到主分支后，智能体就会自动部署。构建者完全不需要编写软件。他们只需克隆仓库、复制一个入门模板、告诉 Claude Code 这个智能体应该做什么，就能拿到智能体所需的一切：配置、提示词、凭据存储和记忆。

> He spent a week building a starter kit with two templates, stored in dedicated git repositories. One is for event-driven agents, which start the moment something happens, like a new job arriving or a document coming back from a court. The other is for scheduled agents, which run on a timer: hourly, daily, or weekly. Each agent lives in its own folder with a standard structure: a JSON config file, a system prompt in Markdown, deployment scripts, and operational documentation. Merging a change into the main branch deploys the agent automatically. A builder never has to write software. They clone the repo, copy a starter template, tell Claude Code what the agent should do, and get back everything the agent needs: config, prompt, credential store, and memory.

#### 弥合技术鸿沟

> Bridging the technical divide

Fuller 召集了公司 15 人的指导委员会，成员来自财务、市场营销、运营和开发部门（其中没有一位是软件开发人员），让他们克隆代码仓库，并使用 Claude Code 构建 Managed Agents。

> Fuller gathered the company’s 15-person steering committee, drawn from finance, marketing, operations, and development (none of them software developers), and had them clone the repository and build Managed Agents using Claude Code.

这样做的目标是证明非开发人员也能自己构建生产级智能体。如果每个智能体都必须经由开发团队来构建，这一瓶颈就会限制整个公司的推进速度。之所以能保证安全，是因为他们并不是在编写软件，而是在填写配置和提示词，运行时则由 Managed Agents 提供。

> The goal was to prove that non-developers could build production agents themselves. If every agent had to route through the dev team, that bottleneck would cap how fast the whole company could move. What made it safe is that they were not writing software. Instead, they were filling in configuration and a prompt, and Managed Agents supplied the runtime.

“我得向他们解释 PR 是什么。很多[非软件工程师]以为它指的是跑步，就像 PR 那样，指你能跑出的最快成绩，”他说。“现在他们都在提 pull request，还互相发给对方。”

> "I had to explain what a PR was to them. A lot of [the non-software engineers] thought it meant running, like a PR, the fastest you can,” he said. “Now they're doing pull requests and sending them to each other."

不到一周，全部 15 名员工都有了可以正常运行的智能体。这些构建者回到各自团队后，又培训了其他同事。不到一个月，ABC Legal 内部已有大约 50 多个智能体在运行。每个智能体都有一个名字、一位负责人，并且只承担一项工作。

> Within a week, all 15 employees had working agents. Those builders went back to their teams and trained others. Within a month, roughly 50+ agents were running across ABC Legal. Each agent has a name, an owner, and a single job.

#### 覆盖法律文书处理大部分环节的智能体

> An agent for most stages of the legal document process

如今，ABC Legal 在法律文件提交流程及其相关运营的大部分环节中都已部署了智能体。

> ABC Legal now has an agent at most stages of the legal filing process and the operations around it.

AI Code Reviewer 会审查四个代码库中的每一个拉取请求，通过多模型分析来捕捉安全漏洞、性能回退以及被提交进代码的凭据。如今，工程师们会等它完成审查后再合并代码。

> The AI Code Reviewer reviews every pull request across four codebases, running multi-model analysis to catch security bugs, performance regressions, and committed credentials. Engineers now wait for its review before merging.

EvidenceChain™ Delivery Agent 接手了一项原本由客户经理每周手动完成的例行工作。ABC Legal 运营着一个自有网站 EvidenceChain.com，法院、原告和被告可以在上面查询现场送达完成的记录，包括送达人是谁、何时尝试送达，以及文件递送的照片。有一位客户希望持续从中提取特定记录。现在，该智能体会针对匹配的任务拉取数据库报告，借助 Managed Agent 内置的浏览器获取每份 PDF，并每天将其递送到客户的 FTP 服务器。搭建它的客户经理此前从未做过任何自动化，仅通过向 Claude Code 描述需求，就在大约一小时内把它搭建了出来。

> The EvidenceChain™ Delivery Agent took over a weekly chore an account manager used to do by hand. ABC Legal runs a proprietary site, EvidenceChain.com, where courts, plaintiffs, and defendants look up the record of a service completed in the field, including who the process server was, when they attempted it, and photos of the document delivery. One customer wanted specific records pulled from it on an ongoing basis. The agent now pulls a database report for matching jobs, retrieves each PDF with a browser built into the Managed Agent, and delivers it to the customer's FTP server daily. The account manager who set it up had never automated anything, and built it in about an hour by describing it to Claude Code.

eFiling 驳回诊断器（eFiling Rejection Diagnoser）会在法院驳回某份提交文件时自动触发，读取任务详情，核查该法院的规则，并在大约一分钟内将诊断结果发布到 Slack，而这项工作过去要占用一名员工一天中的好几个小时。一个任务核验智能体会将每个新进任务与法院信息逐一核对。它在浏览器中访问法院网站，确认听证或案件已妥善立案、且确实会在所述日期进行，然后根据核查结果调整任务，标注管辖区、法院以及诉讼时效期限。

> The eFiling Rejection Diagnoser fires automatically when a court rejects a filing, reads the job details, checks the court's rules, and posts a diagnosis to Slack in about a minute, work that used to consume hours of an employee’s day. A job-verification agent checks every incoming job against the courts. It navigates a court website in a browser, confirms the hearing or case is filed appropriately and actually occurring on the stated date, then adjusts the job based on what it found, flagging jurisdictions, courts, and statute-of-limitations timeframes.

律师覆盖代理（Attorney Coverage Agent）在律师网络中寻找人选来出席庭审：查询律师的空闲情况、向他们发送邮件，并读取关于空闲时间和报价的回复，以便协调员确认出庭安排。

> The Attorney Coverage Agent works the network of attorneys to get hearings covered, checking availability, emailing them, and reading replies about availability and pricing so a coordinator can confirm coverage.

在财务方面，一个应收账款回款智能体会解析回款邮件，生成 NetSuite 付款核销文件，并将其发布到 Slack 供一键审批，随后完成导入；此外还有一个每日运行的智能体，会对每张工程工单给出资本化还是费用化的判定。市场部运行着一个 Google Ads 分析智能体，每周为渠道负责人发布一份建议。在运营方面，一个名为 Charvis 的审核智能体会检查已完成的服务工单，如今它与合规团队的判断一致率约为 98%。

> In finance, an AR-remittance agent parses a remittance email, builds the NetSuite payment-application file, and posts it to Slack for one-click approval, and then imports it, with a daily agent that renders a capitalize-or-expense verdict on each engineering ticket. Marketing runs a Google Ads analyst that posts a weekly recommendation for the channel lead. In operations, a review agent called Charvis checks completed service jobs and now agrees with the compliance team about 98% of the time.

Service-Overdue-Nudger 负责处理 ABC Legal 运营积压事项中的第一层（tier-1）工作，即原本需要人工完成的重复性初步处理，并起草分级的每日外联消息，交由人工审批。

> The Service-Overdue-Nudger works the tier-1 layer of ABC Legal's operational backlogs, the repetitive first pass a person would otherwise do, and drafts tiered daily outreach messages for human approval.

#### 让智能体更聪明：采集、调优、循环往复

> Making the agents smarter: harvest, tune, repeat

ABC Legal 的智能体在人工监督下工作，它们会把已完成的操作或给出的建议发布到 Slack 上，人们则在线程中回复，并用表情符号回应。

> ABC Legal's agents work under human supervision, posting what they did or what they recommend to Slack, where people reply in threads and react with emoji.

![Hank, an internal code review agent, posts every review to a shared Slack channel. Each entry names the pull request and the counts that came out of it so the trail of what the agent decided is public and searchable.](https://assets.claude.com/8f900037eb2f484fefedada30cfe8e50e744453b.png)

Fuller 认为，所有这些反馈数据本是一种训练信号，却被白白浪费了。不过，并非每个智能体都需要这种信号。整个智能体群中的大多数都是单任务执行者，它们的输出无人评分，而且各自独立工作。对于那些确实会收集评分反馈的智能体，ABC Legal 采用了一种三角色架构：几个相互独立的智能体共享同一个工作区、环境和凭据库，但按不同的计划运行。这种模式将 Slack 中的消息转化为对智能体的、有版本记录且经人工批准的变更：

> Fuller saw all that reaction data as a training signal going to waste. Not every agent needs the signal, though. Most of the fleet are single-task runners whose output no one grades, and they work alone. For the agents that do collect graded feedback, ABC Legal uses a three-role architecture: separate agents that share one workspace, environment, and credential vault but run on different schedules. The pattern turns messages in Slack into versioned, human-approved changes to the agent:

1. **初始智能体**负责执行工作，通常是在任务到来或文档返回时实时处理，并为每一项操作记录审计轨迹。
2. **Harvester（采集器）**每小时或每天运行一次，从 Slack 收集人工反馈——这些反馈以线程回复和表情回应的形式出现。每一条反馈都会成为一个带标签的数据点。
3. **Tuner** 每周运行一次，统览全部内容，并提出对提示词或配置的修改，而不是修改模型权重。它只负责起草，由人工审核并合并拉取请求。

> 1\. **The Initial Agent **does the work, usually in real time as a job comes in or a document comes back, and records an audit trail of each action.
> 2\. **The Harvester** runs hourly or daily and gathers human feedback from Slack, where it arrives as thread replies and emoji reactions. Each one becomes a labeled data point.
> 3\. **The Tuner** runs weekly, looks across everything at once, and proposes a change to the prompt or config rather than the model's weights. It drafts only. A human reviews and merges the pull request.

![In ABC Legal’s self-improving agent loop, an initial agent does the work in real time, a harvester sweeps up human feedback from Slack on an hourly cadence, and a weekly tuner proposes prompt and config changes as a pull request. Agents improve through the same workflows developers already use.](https://assets.claude.com/be80e667d16bcafbeda2800fafdcc97e780547f2.png)

“交付即代码”（deliveries-as-code）就是一个例子。这是 Fuller 打造的一套智能体系统，用于调整工作的路由方式，最早在 ABC Legal 旗下拥有 50 名员工的姊妹公司 Docketly 落地。Docketly 以“交付”为单位组织工作，每项交付都有自己的一套路由和处理规则集。全部约 145 个规则集都是存放在 git 中的单个 YAML 文件，而不是管理后台里的记录，因此调整一项交付，就意味着修改一个文件并发起一个拉取请求。

> One example is "deliveries-as-code," Fuller's agentic system for tuning how work gets routed, which started at Docketly, ABC Legal's 50-person sister company. Docketly organizes its work around deliveries, each with its own ruleset for routing and handling. All 145 or so rulesets are single YAML files in git rather than records in an admin screen, so tuning a delivery means editing a file and opening a pull request.

这个闭环由四个智能体组成：一个每周向 Slack 发布评估结论，Harvester 根据人工反馈将表情回应转化为标签，Tuner 针对 YAML 文件发起拉取请求，第四个智能体则将合并后的配置推送到生产数据库。第四个智能体只执行已经过人工审查和批准的内容。实际运行中，一个标记某次配送路由错误的表情回应，可以在一周内变成对该配送路由规则的一次已合并变更。审查是整个闭环中唯一的人工步骤。

> Four agents make up the loop: one posts a weekly verdict to Slack, the Harvester turns reactions into labels based on human feedback, the Tuner opens a pull request on the YAML, and a fourth agent pushes the merged config to the production database. That fourth agent only executes what a human has already reviewed and approved. In practice, an emoji reaction flagging a mis-routed delivery can become a merged change to that delivery's routing rules within the week. The review is the only manual step in the loop.

#### 为什么选择 Claude Managed Agents

> Why Claude Managed Agents

Fuller 在评估了多个框架之后，最终选定 Claude Managed Agents 作为其组织的智能体运行框架（agentic harness）。他的标准非常具体：平台必须具备版本管理、可观测的会话、工作区计费、模型选择、记忆原语、MCP 接入，以及最关键的一点——无需费心照看任何基础设施。

> Fuller evaluated multiple frameworks before settling on Claude Managed Agents as his organization’s agentic harness. His criteria were specific: the platform had to have versioning, observable sessions, workspace billing, model selection, memory primitives, MCP wiring, and, most critically, no infrastructure to babysit.

该平台的职责划分与 Fuller 希望的运作方式完全契合。Anthropic 的托管基础设施负责让智能体运行起来的一切：执行循环、会话、记忆、控制台以及模型本身。ABC Legal 则负责提示词、工具列表、触发逻辑、审计追踪，以及针对结果的反馈闭环。

> The platform's division of responsibility maps cleanly to how Fuller wants to run things. Anthropic’s managed infrastructure owns everything that makes an agent run: the execution loop, sessions, memory, the console, and the models themselves. ABC Legal owns the prompt, the tool list, the trigger logic, the audit trail, and the feedback loop on outcomes.

在大规模场景下，有几项能力被证明尤为重要：

> A few capabilities proved especially important at scale:

- **版本管理：**每次推送都会创建一个新的 agent 版本，并采用乐观锁机制。回滚轻而易举。
- **模型灵活性：**大多数智能体默认使用 Claude Sonnet；高吞吐量和要求快速响应的任务使用 Claude Haiku；当更深入的推理值得付出相应成本时，则使用 Claude Opus。切换模型只需改动一行代码。
- **MCP 接入与凭证保管库：**智能体连接到 ABC Legal 自有平台（提供 100 多种工具）、用于报表的 Metabase、用于人机协同交互的 Slack，以及用于项目管理的 Atlassian。
- **定时部署：**周期性运行的智能体通过 Bitbucket Pipelines 按 cron 计划运行，而 Bitbucket Pipelines 本身已负责处理仓库访问、密钥和计费。

> • **Versioning:** every push creates a new agent version with optimistic locking. Rollback is trivial.
> • **Model flexibility:** the default is Claude Sonnet for most agents, Claude Haiku for high volume and fast tasks, and Claude Opus when deeper reasoning justifies the cost. Swapping models is a one-line change.
> • **MCP wiring and credential vaults:** agents connect to ABC Legal's own platform (with over 100 tools available), Metabase for reporting, Slack for human-in-the-loop interaction, and Atlassian for project management.
> • **Scheduled deployments:** recurring agents run on cron schedules through Bitbucket Pipelines, which already handles repo access, secrets, and billing.

ABC Legal 追踪每一美元的 AI 支出，并按供应商、工具、团队和用例进行细分。随着智能体集群在春季陆续上线，支出不断攀升；而从 7 月开始，在使用量持续增长的同时，支出却开始下降。这得益于下文所述的效率优化工作：许多智能体所覆盖任务的成本降低了约 50%，且各个部门共约 310 名员工都在使用 Claude。

> ABC Legal tracks every dollar of AI spend, broken out by vendor, tool, team, and use case. Spend climbed as the fleet went live through the spring, then started falling in July while usage kept growing, the result of the efficiency work described below, with a ~50% reduction in cost for the tasks many agents cover and ~310 employees across every department using Claude.

公司在成本上的思路是有意为之的：把支出向可衡量回报的垂直化、运营类工具和智能体倾斜，同时让横向的聊天与创意构思类使用保持广泛覆盖，并将成本控制在合理范围内。大多数智能体起初都采用人在回路的方式：智能体查看任务或工单后给出建议，由人审核后才会采取任何行动。这些建议要么存储在任务中并以横幅形式呈现，让人在工作流程中直接接受或拒绝；要么发布到 Slack 频道，供人们在讨论串中回复。这些反馈积累成一个标注了正确与错误判断的数据集，为收集器与调优器循环提供输入，也让团队能够编写评估，并在各个前沿模型之间对智能体进行基准测试。一旦某个智能体证明自己在该特定任务上与人类表现相当甚至更好，它就会切换到自动化模式并自主行动，此后仍保留在同一衡量框架内，以监测其性能的任何变化。

> The company's approach to cost is deliberate: push spend toward vertical, operational tools and agents where return is measurable, whilef keeping horizontal chat and ideation usage broad and costs in check. Most agents start with a human in the loop, where the agent looks at the job or ticket and makes a recommendation for a person to review before anything is acted on. The recommendation is either stored in the job and surfaced in a banner so the person can accept or reject it in the flow of their work, or posted to a Slack channel where people can reply in the thread. Those responses build a labeled dataset of good and bad calls, which feeds the harvester and tuner loop and lets the team write evals and benchmark agents across frontier models. Once an agent proves it is as good as or better than the humans on that specific task, it shifts into automation mode and acts on its own, and it stays inside the same measurement framework afterward to watch for any changes in performance.

ABC Legal 追踪的指标是一个效率比：智能体所交付的价值与其运行成本之比。每个 Managed Agent 在每次运行时都会以小时和美元为单位，将自身创造的价值回报给数据仓库。智能体遵循一条 J 曲线：在刚上线、运行较大模型时往往处于亏损状态，随后随着团队编写评估、改用更便宜更快的模型并削减 token 用量，逐步转为正收益。

> The metric ABC Legal tracks is an efficiency ratio; the value an agent delivers measured against what it costs to run. Every Managed Agent reports its own value back to a data warehouse on each run, in hours and dollars. Agents follow a J-curve, often starting underwater while they are new and running larger models, then flipping positive as the team writes evals, moves to cheaper and faster models, and trims tokens.

#### 部署智能体集群的最佳实践

> Best practices for deploying a fleet of agents

Fuller 在部署 AI（特别是 Claude Managed Agents）方面的经验，让他总结出了几条使用这项技术的实用原则：

> Fuller’s experience with deploying AI–specifically Claude Managed Agents led him to a few working principles about using the technology:

‍

> ‍

- **把一切都视为代码。**“代码不过是结构化的文本，而 LLM 是文本引擎，”他说，“你能把业务中越多的部分转化为代码仓库里的文本，智能体给你带来的杠杆效应就越大。”这一点既适用于传统软件，也同样适用于提示词、schema、调度规则、通知模板和业务配置。
- **从人在回路开始。**每个智能体起初都只发布建议，交由人工审核。只有在证明其判断与人类决策始终保持一致之后，它才能获得独立行动的权利。“每个智能体都要先赢得信任，才能独自行动。它并非一开始就拥有这种信任。”
- **把 PR 当作你的控制面。**“如果你想让智能体参与某项决策，就把这项决策做成拉取请求的样子。”逐行评论、审批流程和不可篡改的审计记录都是版本控制自带的，并且能与 AI 审查和人工审查自然结合。
- **投资于反馈循环。**采集器-调优器（harvester-tuner）模式意味着智能体无需重新训练即可持续改进。Slack 回复和表情回应会转化为结构化信号，反馈到提示词和配置的变更中，而这一切都通过人类早已在用的同一套拉取请求（pull request）工作流完成。
- **跳过定时任务这段弯路。**ABC Legal 在转向 Managed Agents 之前，花了不少时间构建定时任务和本地例程，这主要是因为该产品当时才刚刚以 beta 版推出。Fuller 如今的建议是：直接上手 Managed Agents。
- **要预料到的是 Git 门槛，而不是 AI 门槛。**难点主要在于让业务用户习惯克隆仓库、使用 Git 和拉取请求进行工作，而不在于 AI 本身。这种方式确实奏效，而且见效很快，但这确实是一道真正的门槛，Fuller 希望工具本身能够让这一过程变得更容易。
- **并非每项任务都值得动用智能体。**成本是实实在在的，因此每个团队都必须从价值与成本的权衡来考虑。真正的功夫在于挑选那些可解决、且确实能节省时间或实现自动化的问题，并且敢于说某项任务不值得交给智能体。

> • **Think of everything as code.** "Code is just structured text. LLMs are text engines,” he said. “The more of your business you can turn into text in a repo, the more leverage agents give you." This applies to traditional software and equally to prompts, schemas, dispatch rules, notification templates, and business configurations.
> • **Start with humans in the loop.** Every agent begins by posting recommendations for human review. Only after demonstrating consistent agreement with human decisions does it earn the right to act independently. "Every agent earns trust before it acts alone. It doesn't start there."
> • **Use the PR as your control surface.** "If you want an agent involved in a decision, make the decision look like a pull request." Line-by-line comments, approval workflows, and immutable audit trails come free with version control, and compose naturally with both AI and human review.
> • **Invest in the feedback loop. **The harvester-tuner pattern means agents improve without retraining. Slack replies and emoji reactions become structured signals that feed back into prompt and config changes, all through the same pull request workflow humans already use.
> • **Skip the scheduled-tasks detour. **ABC Legal spent real time building scheduled tasks and local routines before moving to Managed Agents, largely because the product had only just launched in beta. Fuller's advice today is to go straight to Managed Agents.
> • **Expect the git hurdle, not the AI hurdle.** The hard part was getting business users comfortable with cloning a repo and working in Git and pull requests, more than anything about the AI itself. It worked, and fast, but it was a real hurdle, and Fuller would like to see it made easier in the tooling itself.
> • **Not every task deserves an agent.** The cost is real, so every team has to think in terms of value over cost. The work is picking tractable problems that genuinely save time or create automation, and being willing to say a given task is not worth an agent.

#### 下一步

> What's next

ABC Legal 的智能体集群仍在持续扩大。正在进行中的项目包括服务照片审核智能体、PagerDuty 分诊智能体、每日 KPI 摘要，以及在现有智能体上扩展的 Tuner 循环。

> ABC Legal's agent fleet continues to grow. In-flight projects include a service photo reviewer, a PagerDuty triage agent, a daily KPI digest, and expanded Tuner loops on existing agents.

团队还在识别更多“X 即代码”（X-as-code）的候选对象：通知模板、事件路由规则和调度逻辑，这些都可以迁移到代码仓库中，供智能体读取、推理并提出改进建议。

> The team is also identifying more "X-as-code" candidates: notification templates, event routing rules, and dispatch logic that can be moved into repositories where agents can read, reason about, and propose improvements.

正如 Fuller 所说：“我们希望 AI 能够支撑一家可以自主运转的企业，让员工腾出手来为它掌舵。”

> As Fuller puts it: "We want AI to support a business that can run itself, with employees free to steer it."

[了解更多](https://platform.claude.com/docs/en/managed-agents/overview)关于 Claude Managed Agents 的信息。

> [Learn more](https://platform.claude.com/docs/en/managed-agents/overview) about Claude Managed Agents.

‍

> ‍

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Claude Managed Agents | Claude 托管智能体 | Anthropic 提供的托管平台，负责智能体的执行循环、会话、记忆和控制台等运行基础设施。 |
| Claude Enterprise | Claude 企业版 | 面向企业组织部署的 Claude 产品方案。 |
| Claude Code | Claude Code | Anthropic 推出的智能体式编码工具，可根据自然语言描述生成和修改代码。 |
| pull request (PR) | 拉取请求 | 在代码仓库中提交变更供他人审查并合并的协作机制。 |
| agent fleet | 智能体集群 | 组织内同时运行、统一管理的一组智能体。 |
| human-in-the-loop | 人在回路 | 由人工审核智能体建议后才执行操作的工作模式。 |
| Harvester | 采集器 | 定期从 Slack 收集人工反馈并将其转化为带标签数据点的智能体角色。 |
| Tuner | 调优器 | 每周汇总反馈并起草提示词或配置修改供人工审核的智能体角色。 |
| as-code | 即代码 | 将配置、规则等业务内容以文本文件形式存放在代码仓库中进行版本管理的做法。 |
| agentic harness | 智能体运行框架 | 为智能体提供执行循环、工具调用和状态管理的运行环境。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 让模型或智能体以统一方式连接外部工具与数据源的开放协议。 |
| optimistic locking | 乐观锁 | 在提交时检测冲突而非预先加锁的并发控制机制。 |
| credential vault | 凭证保管库 | 集中安全存储智能体访问外部系统所需凭据的组件。 |
| cron | cron 定时调度 | 按预设时间表周期性触发任务的调度机制。 |
| J-curve | J 曲线 | 描述智能体先因成本较高处于亏损、再随优化转为正收益的效益走势。 |
