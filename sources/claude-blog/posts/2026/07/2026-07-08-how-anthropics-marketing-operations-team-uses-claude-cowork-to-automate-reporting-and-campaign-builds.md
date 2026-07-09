---
source: claude-blog
source_url: https://claude.com/blog/how-anthropics-marketing-operations-team-uses-claude-cowork-to-automate-reporting-and-campaign-builds
published_at: 2026-07-08
category: Enterprise AI
title_en: How Anthropic's marketing operations team uses Claude Cowork to automate reporting and campaign builds
title_zh: Anthropic 市场运营团队如何用 Claude Cowork 自动化报告与活动搭建
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 3
source_image_count: 4
---

# Anthropic 市场运营团队如何用 Claude Cowork 自动化报告与活动搭建

> How Anthropic's marketing operations team uses Claude Cowork to automate reporting and campaign builds

> 来源：Claude Blog，2026-07-08
> 原文链接：https://claude.com/blog/how-anthropics-marketing-operations-team-uses-claude-cowork-to-automate-reporting-and-campaign-builds
> 分类：Enterprise AI

## 核心要点

- 市场运营团队大量时间用于让营销系统与业务保持同步，而各类营销技术工具之间集成不畅，报告靠人工汇总、落地页逐个搭建。
- Ian 过去每周要花一到两天准备市场指标周报，如今借助 Claude Cowork 将其压缩到最多两小时。
- 一个定时任务每周日晚运行，让 Claude 阅读上周回顾与最新会议记录、检查 Slack、查询数据仓库，并整理出数据与建议关注方向。
- 整个报告流程依赖连接器与 Ian 持续维护的三个技能：准备技能负责组装报告，校对技能逐一核对数字来源，行动项技能把跟进事项转为 Asana 任务。
- 当数字对不上时，Claude 会标记差异而非猜测，例如销售团队重组后主动指出口径不一致并询问处理方式。
- Annabel 通过一个每小时运行的调度技能读取 Slack 频道、挑出最紧急请求并分派给五个专项技能，实现活动搭建与数据导入的自动化。
- 人工校验成为两条工作流的核心环节，团队将省下的时间转向赋能、数据层梳理与流程完善。

## 正文

Anthropic 市场运营团队的 Ian Chan 与 Annabel Custer 分享，他们如何将团队过去需要跨多个平台手工完成的工作自动化。

> Ian Chan and Annabel Custer, in marketing operations at Anthropic, share how they automate work their team used to do by hand across multiple platforms.

营销运营（marketing operations）团队会花费相当一部分时间，让支撑各类营销项目的系统与业务保持同步。虽然自动化明确属于他们的职责范围，但很多工作却毫无自动化可言：营销技术（martech）工具之间无法顺畅集成，报告要手动汇总，落地页只能一个一个地搭建。

> Marketing operations teams spend a meaningful portion of their time keeping the systems behind marketing programs in step with the business. While automation sits firmly in their purview, a lot of the work is anything but: martech tools don’t integrate cleanly with each other, reports are consolidated manually, landing pages get spun up one at a time.

Anthropic 营销运营团队的 Ian Chan，过去每周要花一到两天来整理每周的营销指标评审。专注于活动运营的 Annabel Custer，过去要依次点击 Salesforce、HubSpot、Swoogo 和邮件工具，才能配置好每一个新活动。如今两人都通过在 Claude Cowork 中搭建工作流，把原本数天的手动工作压缩到了数小时。

> Ian Chan, on the marketing operations team at Anthropic, used to spend one to two days a week pulling together the weekly marketing metrics review. Annabel Custer, who focuses on campaign operations, used to set up each new event by clicking through Salesforce, HubSpot, Swoogo, and email tools in sequence. Both have now compressed days of manual work into hours by setting up workflows in Claude Cowork.

省下的时间改变了他们工作的形态。随着公司里越来越多的人自己拉取数据、自主推动项目，Ian 和 Annabel 现在花在系统间点击上的时间更少，而更多地投入到赋能（enablement）、验证，以及营销团队所依赖的底层数据和流程上。

> The recovered hours have shifted the shape of their work. Ian and Annabel now spend less time clicking through systems and more time on enablement, validation, and the underlying data and processes the marketing team relies on as more people across the company pull their own numbers and drive their own programs.

### 生成每周营销指标报告

> Generating the weekly marketing metrics report

在理想情况下，Ian 为营销团队和管理层准备的每周报告中的每个指标都应存在于仪表盘（dashboard）中，他的工作只需组织叙述即可。但实际上，有些指标已在仪表盘里，有些还没从数据仓库（data warehouse）进入仪表盘，还有些甚至尚未导入数据仓库。新指标可能只存在于一条 Slack 消息或一次通话记录中。

> In a perfect world, every metric in the weekly report Ian prepares for marketing and leadership would live in a dashboard and his job would be to simply put together the narrative. In practice, some metrics are in the dashboard already, while others haven’t yet made it there from the data warehouse, and others haven’t been piped into the warehouse yet. New ones might exist only in a Slack message or a call transcript.

在 Anthropic，业务发展的速度比传统报告流水线所能跟上的还要快，Ian 过去每周要花一到两天时间追查数据并进行验证。现在 Claude Cowork 承担了这项数据搜寻工作的大部分。

> At Anthropic, the business moves faster than a traditional reporting pipeline can keep up with and Ian used to spend a day to two days every week tracking down data and validating it. Claude Cowork now handles most of that data hunt.

一个定时任务在每周日晚上运行，提示 Claude 阅读上一周的回顾和最新的会议记录，查看 Slack 了解销售团队的关注重点，查询数据仓库，并留下一个文件夹，里面包含各项数字和几个建议的关注领域。

> A scheduled task runs every Sunday evening, prompting Claude to read the previous week's review and the latest meeting transcript, check Slack for what the sales team is focused on, query the warehouse, and leave a folder with the numbers and a few suggested focus areas.

周一早上，Ian 打开 Claude Cowork，拉取初始报告，其中包含指标表格以及建议的标题或关注领域。

> On Monday morning, Ian opens Claude Cowork and pulls the initial report, which contains the metrics tables and suggested headlines, or areas of focus.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4c4a528dff4302c054e6cd_47666869.png)

Ian 审阅这些内容，一旦他确认或决定叙述的重点方向，就让 Claude 用支撑性的细节和示例加以扩展。有些周团队是在响应某项销售优先事项，另一些周则是在响应产品发布。到季度交替时，Ian 会让 Claude 以季度计划开篇，并输入季度回顾文档。

> Ian reviews them and once he’s confirmed or decided where to focus the narrative, he tells Claude to expand on them with supporting details and examples. Some weeks the team is responding to a sales priority, and others—to a product launch. At the quarter turn, Ian tells Claude to lead with quarterly plans and feeds in the quarterly review doc.

Claude 根据同样的数据和叙述生成给管理层的幻灯片：发生了什么变化、原因是什么，以及各团队正在采取什么应对措施。任何后续事项都会转化为 Asana 任务。

> Claude generates the leadership slide from the same data and narrative: what changed, why, and what the teams are doing about it. Any follow-ups become Asana tasks.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4c4a528dff4302c054e6d0_9a64f8ed.png)

当数字对不上时，Claude 会标记出这种不一致，而不是靠猜测。例如，在销售团队进行一次重组（reorg）后，营销部门的报告数据不再与销售团队的一致。Claude 标记了这一差异，并询问 Ian 该如何处理。

> When the numbers don’t line up, Claude flags the mismatch instead of guessing. After a reorg on the sales team, for example, marketing's reporting no longer matched theirs. Claude flagged the gap and asked Ian how to handle it.

整个流程依托于连接团队所用营销平台和工具的连接器（connector），以及 Ian 已构建并持续更新的三项技能（skill）：

> The process runs on connectors to the marketing platforms and tools the team uses, and three skills that Ian has built and updates continually:

- 一项准备技能负责推进报告的组装，包括关注重点、标题，以及用支撑细节进行扩展。
- 一项校对技能会将草稿中的每个数字与经过验证的来源进行核对。
- 一项行动项技能会将后续事项转化为 Asana 任务。

> • A prep skill drives the report assembly, including focus, headlines, and expansion with supporting detail.
> • A proofreading skill checks every number in the draft against a verified source.
> • An action-items skill turns follow-ups into Asana tasks.

在每次每周会话结束时，Ian 会让 Claude 总结本次出现的、应当反馈回技能中的内容。例如新的销售重组结构、他所做的修正，或者他希望标题采用的新表述方式。在 Ian 的案例中，整个过去需要多达两天工作量的流程，如今最多只需两小时。

> At the end of each weekly session, Ian asks Claude to summarize what came up that should go back into the skills. The new sales reorg structure, for example, the corrections he made, or a new way he wanted the headlines framed. In Ian’s case, the entire process, which used to take up to two days of work, takes up to two hours.

如今，Ian 有相当一部分时间转移到了帮助营销人员构思问题、优化提示词，以及在他们自己从 Claude 拉取数据时解读所得到的结果上。他也有余力深入数据层，确保 Claude 对数字、定义和区域结构的解读方式与数据仓库保持一致。

> Now, a meaningful share of Ian’s time has moved to helping marketers frame their questions, refine their prompts, and interpret what they get back when they pull their own numbers from Claude. He also has bandwidth to go deeper into the data layer, making sure Claude interprets the numbers, definitions, and regional structures the same way as the data warehouse.

人工验证已成为这两条工作流不可或缺的一部分——随着 Claude 自动化了那些传统上占据营销分析师大量时间的繁琐手工任务，这一转变正在加速。

> Human validation has become an integral part of both workstreams—a shift that’s accelerating as Claude automates the mundane manual tasks that have traditionally taken up much of marketing analysts’ time.

### 自动化活动搭建与数据导入

> Automating event builds and data imports

搭建营销活动背后的基础设施，历来是营销工作中最需要手动操作的流程之一。每一场活动、网络研讨会（webinar）或整合式营销活动，都需要在客户关系管理系统（CRM）中设置，在运行邮件序列及其背后自动化流程的营销自动化平台中设置，以及在托管报名页和活动落地页的活动管理平台中设置。这些平台通常来自不同供应商，它们之间的集成往往并不完善。

> Setting up the infrastructure behind marketing campaigns has traditionally been one of the most manual processes in marketing. Every event, webinar, or integrated campaign needs to be set up in the CRM, in the marketing automation platform that runs the email sequences and the automation behind them, and in the event management platform that hosts the registration page and the event landing page. Each of these is typically a different vendor, and the integrations between them are rarely complete.

在使用 Claude Cowork 之前，Annabel 从一个专用的 Slack 频道中接收每一个请求，然后手动完成整个流程。她的新方案则几乎完全由 Claude 处理。流程从一个接收表单开始，请求方在其中指定所需的帮助类型：活动搭建、数据导入、申请参会（apply-to-attend），或审批支持。

> Before Claude Cowork, Annabel picked up every request from a dedicated Slack channel and worked through the sequence manually. Her new setup is almost entirely handled by Claude. It starts with an intake form where requesters specify the type of help they need: event build, data import, apply-to-attend, or approval support.

每小时一次，一个调度（dispatcher）技能会读取该频道，挑出最紧急的请求，为工单打上标记以免重复处理，然后将其交给 Annabel 设置的五个专项技能之一去完成相应工作。它本身不做任何活动搭建；它的职责是决定接下来运行什么，而将其独立出来，让 Annabel 可以单独打磨每一个专项技能，而不必改动路由逻辑。

> Once an hour, a dispatcher skill reads the channel, picks the most urgent request, stamps the ticket so the work doesn't get duplicated, and hands it off to one of five specialist skills that Annabel has set up to do the required work. It doesn’t do any event setup itself; its job is to decide what runs next, and keeping it separate lets Annabel refine each specialist skill on its own without touching the routing.

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4c4a528dff4302c054e6d3_36d62936.png)

对于活动搭建这一最复杂的请求类型，一个活动搭建技能会从头到尾处理整个流程：创建 CRM 营销活动、搭建带有工作流和列表的营销自动化活动、设置活动平台、起草邮件、生成落地页，以及它们之间的全部集成。

> For an event build, which is the most complex request type, an event-build skill handles the full sequence end to end: CRM campaign creation, marketing automation campaign with workflows and lists, event platform setup, email drafting, landing page generation, and all of the integrations between them.

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4c4a528dff4302c054e6d8_be52735c.png)

搭建完成后，它会交给一个新的智能体进行审核。这个审核智能体从零上下文开始，在真实上线的落地页上提交一次测试报名，在 Gmail 中打开确认邮件，如果一切无误就将 Asana 任务标记为完成。每个结果在正式发布前都会由 Annabel 审阅。

> When the build is done, it hands off to a new agent for audit. The audit agent starts with no prior context, submits a test registration on the live landing page, opens the confirmation email in Gmail, and marks the Asana task complete if everything looks right. Annabel reviews each result before it ships.

这套工作流运行在与 Annabel 所用营销平台和工具对接的连接器（connector）之上，外加她构建的一系列技能——每当发现新的边缘情况，她都会对这些技能进行更新：

> This workflow runs on connectors to the marketing platforms and tools Annabel works with, plus a number of skills she's built and updates as she finds new edge cases:

- 一个调度技能读取接收频道，并将每个请求路由到下面对应的专项技能。
- 一个活动搭建技能驱动跨平台的端到端搭建。
- 一个网络研讨会落地页创建技能为网络研讨会快速生成落地页。
- 一个审核技能，由一个独立的全新 Claude 实例运行，在任务被标记为完成之前验证活动搭建技能的输出。
- 一个申请参会技能，处理报名流程中途出现的变更：
- 一个审批支持技能，处理活动审批，并按预定的节奏发送相应的邮件。
- 一个数据导入技能，清洗列表并处理参会者数据。

> • A dispatcher skillreads the intake channel and routes each request to the right specialist skill below.
> • An event-build skill drives the end-to-end setup across platforms.
> • A webinar-landing-page creation skill spins up landing pages for webinars.
> • An audit skill, run by a separate fresh Claude instance, verifies the event-build skill's output before the task is marked complete.
> • An apply-to-attend skill handles in-flight changes to the registration flow:
> • An approval-support skillhandles event approvals and sends the appropriate emails at a scheduled cadence.
> • A data-import skill scrubs lists and processes attendee data.

她还另外常开着一个“管理者”（manager）智能体。当某次运行出错时，她会打开这个管理者，让它查看发生了什么并提出应当调整的地方。任何值得保留的改动都会回写到相应的技能中。

> She also keeps a separate "manager" agent open. When a run misfires, she opens the manager and asks it to look at what happened and propose what to adjust. Anything worth keeping goes back into the relevant skill.

虽然这些自动化工作流将在 Annabel 的日常工作中显著节省时间，但她构建它们的首要动机是工作质量。随着营销团队规模扩大，营销人员从手边现成的任意模板克隆活动页面，可能会产生各种问题，比如确认邮件显示了错误的城市名，或落地页出现故障。借助 Claude Cowork，她能在大规模的搭建中保持一致性。

> While these automated workflows will become significant time savers in Annabel’s day, her primary motivation to build them was quality of work. As the marketing team scales, marketers cloning event pages from whatever template happens to be nearby can produce bugs, such as confirmation emails surfacing the wrong city name or broken landing pages. With Claude Cowork, she gets consistency across builds, at scale.

当 Claude 承担起营销活动运营中的重复性环节后，Annabel 就能专注于更具战略性的项目，比如赋能（enablement），以及为获得更好的洞察而对流程和营销活动架构进行自动化或优化。

> As Claude takes on the repetitive parts of campaign operations, Annabel can focus on more strategic projects, like enablement, and automating or optimizing processes and campaign architecture for better insights.

### Claude Cowork 入门给营销运营团队的建议

> Advice for Marketing Ops teams on getting started with Claude Cowork

- 把反复出现的纠正变成技能（skill）。当你发现自己一再纠正 Claude 同一个问题时，这条反馈就应该沉淀为一项技能。你也不必亲自构建技能：Claude 可以替你完成。
- 先构建一项校对（proofreading）技能。校对技能会检查 Claude 写入报告的每一个数字都能追溯到一个已验证的来源。
- 让 Claude 反思。Claude 阅读指令的方式与人类撰写指令的方式不同，因此在新工作流首次运行之后，可以问它指令中有哪些地方难以理解。Annabel 会把由此浮现出来的问题反馈进技能，这是她持续更新技能这一更广泛做法的一部分。
- 善用定时任务（scheduled tasks）。每周日晚上或每小时自动运行的工作，就是无需任何人记着去做的工作。

> • Turn repeated corrections into skills.When you find yourself correcting Claude on the same thing more than once, that feedback belongs in a skill. You don’t need to build skills, either: Claude can do that for you.
> • Build a proofreading skill first.The proofreading skill checks that every number Claude puts in a report traces back to a verified source.
> • Ask Claude to reflect.Claude reads instructions differently than a human writes them, so after the first runs of a new workflow, ask what was difficult about the instructions. Annabel feeds what surfaces back into the skill as part of her broader practice of constantly updating skills.
> • Lean on scheduled tasks.Work that runs on its own every Sunday night or every hour is work no one has to remember to do.

‍

> ‍

## 术语对照

| English | 中文 |
|---|---|
| marketing operations | 市场运营 |
| martech tools | 营销技术工具 |
| weekly marketing metrics report | 市场指标周报 |
| data warehouse | 数据仓库 |
| connector | 连接器 |
| skill | 技能 |
| scheduled task | 定时任务 |
| meeting transcript | 会议记录 |
| dispatcher skill | 调度技能 |
| event build | 活动搭建 |
| data import | 数据导入 |
| landing page | 落地页 |
| marketing automation platform | 营销自动化平台 |
| human validation | 人工校验 |
