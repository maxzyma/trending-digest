# Claude 值班：Claude Tag 如何成为 Anthropic 应对 CI/CD 故障的第一响应者

> Claude on call: How Claude Tag serves as Anthropic’s first responder for CI/CD failures

> 来源：Claude Blog / Anthropic，2026-08-18
> 原文链接：https://claude.com/blog/ai-ci-cd-on-call
> 分类：工程实践 / AI 运维与事件响应

## 核心要点

- Anthropic 的值班 Claude 通过 Slack 频道运行，在近期每一起有情况报告的 CI 事故中都由它撰写首份报告，通常在 15 分钟内发布首次分析。
- 一套值班智能体需要四个要素：记忆用于留存已做过的事、连接与访问权限用于调查和行动、日程安排用于定时启动任务、指令用于界定行为。
- Claude Tag 拥有独立的服务账号，由管理员一次性为频道配置 Datadog、Grafana 等工具访问权限，例行任务通过自然语言提示排期。
- 常设指令以 markdown skills 形式提交到 GitHub 仓库，便于多人迭代并像代码一样管理变更，其中包含路由指令、策略与经验教训日志。
- 在检测环节，Claude 在新服务上线初期分析数据与告警以建议新规则并微调过宽或过窄的阈值，同时按 oncall.md 中的判定标准逐条甄别告警，缓解告警疲劳。
- 告警流程是确定性的，而值班升级同时存在确定性路径和智能体路径，团队成员报告问题或内部事故页面提交都可触发流程。
- 分诊阶段由编排智能体派生执行器子智能体，通过 MCP 连接器并行调查 Grafana、日志存储、PagerDuty、GitHub、Kubernetes 与 Slack 事故频道，再综合为态势报告，发布首份有证据支撑分析的中位耗时为 14 分钟，最快 4 分钟即可指出根本原因。
- 调查由按缺陷类型编写的技能引导，例如一个 617 行的影子分歧排查技能，由作者在事故排障过程中与 Claude 协作生成。
- lessons.md 记录每起已解决事故的经过、根因、修复方式与坑点，Claude 自动追加内容并在每次新调查开始时读取，反复出现的模式会被提升为调查技能。
- 在解决环节，团队大多数部署位于功能开关之后，由一个被授予作者权限的独立智能体管理金丝雀流量并自动升降开关，Claude 还会给出集群排空、扩容建议或直接提交可供审查合并的修复 PR。
- 验证完成后 Claude 写入事后复盘与交接 SITREP，另有名为 ci-weather 的 agent 汇总事故频道、构建指标、合并队列与部署延迟，以新闻编辑室风格发布到全公司可见的公开频道。
- 报告格式经过多轮迭代，文中指出让报告易读的是团队特有的品味，属于人与人之间的沟通而非管道工程。
- Anthropic 工程师现在平均每季度交付的代码量是 2021 至 2025 年期间的 8 倍，同时保持每个 PR 有具名人类负责人、每处改动需批准合并并通过同一套 CI 关卡的标准。

## 正文

[使用我们的配置套件搭建你自己的 Claude 值班系统](https://github.com/anthropics/oncall-kit)*。*

> [Set up your own Claude on-call with our setup kit](https://github.com/anthropics/oncall-kit)*.*

#### CI/CD 的 AI 事件响应：Anthropic 内部值守的 Claude

> AI incident response for CI/CD: Claude on call at Anthropic

几周前，我正值on-call班，晚上10点同事在Slack上给我发了条消息：某个新服务上大约有44个测试没有触发。

> A few weeks ago, I was on-call and my colleague Slacked me a message at 10pm: roughly 44 tests on a new service weren’t firing.

换作以前，我会停下手头的事情，坐下来打开笔记本电脑，疲惫地叹一口气，然后开始长达一小时的排查与修复过程。但现在，我的工作流程完全不同了：我把 @Claude 拉进来，问它看到了什么。

> In the past, I would have stopped what I was doing, sat down with my laptop, sighed wearily, and began an hour-long investigate-and-fix process. But now, my workflow is entirely different: I pull in @Claude, and ask what it sees. 

在这个案例中，Claude 发现测试的消失是因为当天早上启用了一个功能开关，而且回滚该开关是安全的。我请同事回滚了这个开关。3 分钟后，Claude 在 Slack 上给我发消息，确认跳过规则确实已被移除，错误率也回到了基线水平。

> In this case, Claude found the tests disappeared when a feature flag got turned on that morning, and also that it would be safe to revert. I asked my colleague to revert the flag. Claude pinged me on Slack 3 minutes later to verify the skip rules had indeed been removed and the error rate was back to baseline.

![Redesigned from a real exchange for clarity.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a85deb08541b5a210e00ef5_cb834739.png)

过去几个月里，Claude Tag 一直是 Anthropic CI/CD 故障的值班第一响应者。这不仅改善了我们的社交生活，还为每一次 CI 事故都提供了一名即时的第一响应者：在近期每一起有情况报告的事故中，首份情况报告都是由 Claude 撰写的，**通常在 15 分钟内就会发布它的首次分析。**

> For the last several months Claude Tag has been the on-call first responder for CI/CD failures at Anthropic. Not only has this helped with our social lives, it has given every CI incident an instant first responder: Claude authored the first situation report in every recent incident that had one, **typically publishing its first analysis within 15 minutes.**

在本文中，我们将介绍我们构建了什么以及它是如何工作的，这样你就可以自己动手搭建一套，不必再对轮到自己值班感到发怵。

> In this article we’ll walk through what we built and how it works so you can build it yourself and stop dreading your turn in the rotation.

#### **我们的 Claude 值班配置**

> **Our Claude on call setup**

在深入介绍事件响应流程的每个阶段之前，我先总体概述一下我们这里的配置，这样在补充细节时你心里就有了全局图景。

> Before we go into each stage of the incident response process, I’ll provide a general overview of our setup here so you have the big picture in mind as we fill in the details.

值班代理需要**记忆**，这样它才能记住已经做过的事情；需要**连接与访问权限**，这样它才能调查、理解并采取行动；需要**日程安排**，这样它才知道何时重新开始工作；还需要**指令**，这样它才知道该做什么。

> An on-call agent needs **memory** so it remembers what’s been done; **connections and access** so it can investigate, understand, and act; **schedules** so it knows when to get back to work; and **instructions** so it knows what to do.

[Claude Tag](https://claude.com/product/tag) 是我们值班 agent 的支柱。Claude Tag 在我们的值班 Slack 频道中保存记忆，并提供在事故期间下达逐轮指令的接口。Claude 还会对值班频道及其他频道中的事件做出实时响应。例行任务的调度，也就是 Claude 定期执行的操作，同样在这个频道上通过自然语言提示来完成，例如“每周一美东时间上午 9:00 运行 CI 交接”。

> [Claude Tag](https://claude.com/product/tag) is the backbone of our on-call agent. Claude Tag holds memory across our on-call Slack channel and the interface to provide per-turn instructions during an incident. Claude also acts in real time to events in the on-call channel and others. The scheduling of routines, or the regular actions Claude takes, happens on this channel as well with natural language prompts like “run CI handoff every Monday at 9:00am EST.”

[Claude Tag 拥有自己的服务账号](https://claude.com/blog/agent-identity-access-model)，并可以访问 Anthropic CI 工程师所需的工具，例如 Datadog 或 Grafana。这是由管理员为该频道一次性完成的设置（[具体方法见此](https://claude.com/docs/claude-tag/admins/setup-overview#choose-which-tools-to-connect)）。

> [Claude Tag has its own service account](https://claude.com/blog/agent-identity-access-model) and access to the tools an Anthropic CI engineer needs such as Datadog or Grafana. This was set up one time by an administrator for the channel ([here’s how](https://claude.com/docs/claude-tag/admins/setup-overview#choose-which-tools-to-connect)). 

除了值班频道之外，我们还让 Claude 监控其他相关频道，这些频道同样把 Claude Tag 加为成员，这样它就能获取更多上下文信息，比如服务告警、配置变更或 PR 的最新动态。

> In addition to the on-call channel, we set up Claude to watch other relevant channels that also have Claude Tag as a member so it can get additional context like service alerts, configuration changes, or updates on PRs. 

常设指令以 markdown 文件的形式作为 skills 存在，并提交到 GitHub 仓库中。这样多位团队成员就可以对其进行迭代，我们也能像管理代码一样管理这些变更。它还包含一些关键信息，例如路由指令、策略，以及作为自我改进循环一部分的经验教训日志。

> Standing instructions are in markdown files as skills, committed in a GitHub repository. This way multiple teammates can iterate on them and we can manage changes just like we do code. It also includes key information like routing instructions, policies, and a log of lessons learned as part of a self-improvement loop. 

这套配置只花了我们几个小时，而不是几天。我们在 GitHub 上创建了一个通用的[值班配置工具包](https://github.com/anthropics/oncall-kit)，可以帮助你上手搭建类似的智能体。** **它会把你团队自己的事故历史转化为分级排查手册，并在你的事故频道中留下一个只读的 Claude，负责诊断、升级和学习。[你可以观看它针对一个虚构团队的历史记录运行](https://github.com/anthropics/oncall-kit/blob/main/test-fixtures/RUNBOOK.md)，大约十分钟即可完成。

> This setup took us hours, not days. We created a generalized [on-call setup kit](https://github.com/anthropics/oncall-kit) in GitHub that can help get you started with a similar agent.** **It transforms your team's own incident history into triage playbooks and leaves you with a read-only Claude in your incident channel that diagnoses, escalates, and learns. [You can watch it run against a fictional team's history](https://github.com/anthropics/oncall-kit/blob/main/test-fixtures/RUNBOOK.md) in about ten minutes.

用 TL;DR 的方式总结这些步骤

> To summarize the steps TL;DR fashion

- 你需要一个 [Claude Team 或 Claude Enterprise](https://support.claude.com/en/collections/9387370-team-and-enterprise-plans) 套餐
- 组织所有者需要通过 Claude Tag 将 Claude 添加到值班 Slack 频道
- 组织所有者还需要帮助将值班 Slack 频道中的 Claude 连接到相应的连接器和 GitHub 仓库，并设置 [Claude Code Remote](https://code.claude.com/docs/en/remote-control)。
- 将 Claude 添加到你的事故响应频道，并指示它监控事故并立即进行分级处理

> • You’ll need a [Claude Team or Claude Enterprise](https://support.claude.com/en/collections/9387370-team-and-enterprise-plans) plan
> • The organization owner needs to add Claude to the on call Slack channel via Claude Tag
> • The org owner also needs to help connect Claude in the on-call Slack channel to the appropriate connectors, GitHub repo, and set up [Claude Code Remote](https://code.claude.com/docs/en/remote-control).
> • Add Claude to your incident channel and instruct it to monitor for incidents and immediately triage

现在，让我们深入了解在事件处理的每一个步骤中，这种转变具体是什么样子的。

> Now, let’s dive into the details of what this transformation looks like at each step of an incident.

#### **检测**

> **Detection**

Claude 不仅改变了你响应事件的方式，还改变了你最初检测到它们的方式。此前，检测事件存在两种主要的失效模式。

> Claude doesn’t just transform how you respond to incidents, it transforms how you detect them in the first place. Previously, there were two major failure modes for detecting incidents. 

人类很难始终具备先见之明，用完美的阈值制定出完美的规则。当你没有足够的数据来分析流量模式时，这就尤其困难。

> It's hard for humans to have the foresight to set perfect rules with perfect thresholds all the time. It's especially difficult when you don't have enough data to analyze traffic patterns.

为解决这一问题，我们让 Claude 在新服务上线的最初几天分析数据和接收到的告警，以便提出额外的规则建议，并对那些过于宽泛或过于狭窄的规则进行微调。

> To address this, we have Claude analyze the data and incoming alerts for the first few days of a new service to suggest additional rules and to fine-tune any that are overly broad or narrow. 

检测事故的第二个主要失败模式是告警疲劳：检查并甄别每一条触发的告警是件枯燥乏味的事。然而，Claude 不会像人类那样产生疲劳。

> The second major failure mode for detecting incidents was alert fatigue: checking and vetting every alert that fires is tedious. However, Claude doesn’t get fatigued the same way a human does. 

Claude 会监控每个告警通道中的所有相关告警，并依照 [根目录 oncall.md 文件](https://github.com/anthropics/oncall-kit/blob/main/templates/ONCALL.md)中的判定标准来确定该告警是否可以等到早上处理，还是需要呼叫值班人员。例如，在通过分析数据完成调优之后，该文件中的一条规则可能是：“如果错误率高于 2% 且持续超过 5 分钟，并且当前不处于已知的部署窗口期，则呼叫值班人员，否则将其写入 lessons.md。”

> Claude monitors every relevant alert in each alert channel and goes through the criteria in the [root oncall.md file](https://github.com/anthropics/oncall-kit/blob/main/templates/ONCALL.md) to determine if it can wait until the morning or if the on-call needs a page. For example, once tuned from analyzing the data, a rule in the file could be, “If the error rate is greater than 2% for longer than 5 minutes AND it's not a known deploy window, page the on-call otherwise write it to lessons.md.”

Claude 的值班告警流程还有另外两种触发方式：

> There are two other ways the Claude on-call alert process can trigger:

- CI 团队的成员可以在值班频道中报告问题，就像开头那个 44 个测试缺失的例子那样；或者  
- 公司里的任何人都可以通过内部页面提交一起事故。如果它被标记为 CI 基础设施事故，就会为该事故开设一个 Slack 频道，由我们值班的 Claude 接手处理。

> • A member of the CI team can report an issue in the on-call channel, as was the case in the opening example of 44 missing tests; or  
> • Anyone in the company can open an incident through an internal page. If it’s marked as a CI infrastructure incident then a Slack channel is provisioned for that incident and our on-call Claude picks it up.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a84a163e2030bce8127dd8e_a5e36b9a.png)

这里的关键要点是，告警流程是确定性的，而值班升级则同时具备确定性路径和智能体路径。

> The key takeaway here is that the alerting process is deterministic, while on-call escalation has both deterministic and agentic paths. 

#### **分诊 **

> **Triage **

让 Claude 过滤告警噪音是一回事，但真正的效率提升来自调查环节。在事件开启后，Claude 发布首份有证据支撑的分析的中位耗时为 14 分钟，而在最快的情况下，它能在 4 分钟内于首份报告中指出根本原因。

> It's one thing to have Claude filter through the alert noise, but the real savings comes from the investigation. Claude posts its first evidence-grounded analysis a median of 14 minutes after an incident opens, and in the fastest cases names the root cause within 4 minutes in its first report.

当一个告警升级为事故时，Claude 通常已经在我们的 Slack 频道中准备好了一个有证据支撑、可供我们审阅的假设。Claude Tag 会启动一个[动态工作流](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code)，其中的编排智能体会派生出执行器子智能体，去调查每一个依赖项和事实来源。

> When an alert has been escalated to an incident, Claude is often ready in our Slack channel with a hypothesis grounded in evidence that we can review. Claude Tag kicks off a [dynamic workflow](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code) with an orchestration agent that spins up executor subagents to investigate each dependency and source of truth. 

对我们来说，这些就是 Grafana、我们的日志存储、PagerDuty、GitHub、Kubernetes 和 Slack 事故频道——全部通过 [MCP 连接器](https://code.claude.com/docs/en/mcp)接入。Claude 可以并行追查多条线索，有助于降低 MTTR（平均解决时间）。

> For us that’s Grafana, our log store, PagerDuty, GitHub, Kubernetes and Slack incident channels–all wired up via [MCP Connectors](https://code.claude.com/docs/en/mcp). Claude can chase multiple leads in parallel, helping to reduce MTTR (mean time to resolution).

执行器将发现的结果反馈给编排代理，由后者进行综合并以连贯的态势报告（SITREP）形式呈现这些信息。

> Executors report the findings back to the orchestration agent which synthesizes and surfaces the information in a coherent SITREP. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a84a163e2030bce8127ddb7_faae8c5a.png)

编排器智能体和执行器智能体并不是在盲目搜索。它们由一项调查技能引导，该技能[为每一类缺陷都配备了更为详尽的参考 markdown 文件](https://github.com/anthropics/oncall-kit/tree/main/skills/triage)。

> The orchestrator and executor agents aren’t searching blind. They are guided by an investigation skill with [more detailed reference markdown files for each bug class](https://github.com/anthropics/oncall-kit/tree/main/skills/triage). 

例如，一个 617 行的、用于排查影子分歧（shadow divergence）缺陷的调查技能，编码了我在一次典型调查中所采取的每一个步骤。我是在某次事故期间与 Claude 逐轮排障时构建它的，然后让它根据那次经验生成了这个文件。

> For example, a 617 line investigation skill for shadow divergence bugs encodes every step I take during a typical investigation. I built it by troubleshooting with Claude turn-by-turn during one of the incidents and then had it create the file from that experience.

Lessons.md 也指导着 Claude 的故障排查。这个 markdown 文件是我们解决过的每一起事故的实时日志：发生了什么、根本原因、修复方式，以及值得记住的坑。Claude 会自行自动向其中追加内容。每次新的调查都从阅读它开始，因此 Claude 的第一个假设是从近期发生过的事情出发的。

> Lessons.md also guides Claude’s troubleshooting. This markdown file is a running log of every incident we've resolved: what happened, the root cause, the fix, and the gotcha worth remembering. Claude appends to it on its own automatically. Every new investigation starts by reading it, so Claude's first hypothesis starts with what has happened recently. 

如果同一种模式出现的次数足够多，我们就会把它提升到调查技能本身当中。我最喜欢的一条记录是 Claude 写下的关于我的内容。当时我在查看指标之前就根据一个配置文件做出了假设，于是 lessons.md 文件现在写着：“先查询数据，再提出理论。配置告诉你什么可能出错；指标告诉你什么已经出错。”

> If the same pattern shows up enough times, we promote it into the investigation skill itself. My favorite entry is one Claude wrote about me. I'd made an assumption from a config file before checking the metrics, and the lessons.md file now states, "query the data first, then theorize. Config tells you what could go wrong; metrics tell you what did."

即使有了这些工具和上下文，Claude 也并不总能一次就做对。人的直觉和经验依然重要。Claude Tag 让团队能够以多人协作模式排查事故。我们中的任何一个人都可以实时引导调查方向，或者共同补充一个假设。

> Even with these tools and context, Claude doesn’t always get it right the first time. Human intuition and experience matter. Claude Tag allows the team to troubleshoot incidents in multi-player mode. Either of us can steer the investigation or add a hypothesis in real-time, together.

![Recreated from a real conversation for clarity.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a85df2d22740fdbccb17112_24270a8f.png)

#### **分辨率**

> **Resolution**

如果 Claude 能够升级和排查告警，它也能修复它们吗？这个问题的答案因团队而异，但以下是我们的做法。

> If Claude can escalate and troubleshoot alerts, can it fix them too? The answer to this question will vary from team to team, but here’s how we do it.

我们团队的大多数部署都在功能开关（feature flag）背后进行。我在 Claude Code 中创建了一个独立的智能体，赋予它我的权限，使其能够在这些功能开关背后逐个进行渐进式部署。

> Most deployments within our team happen behind a feature flag. I have created a separate agent in Claude Code, with my permissions, capable of progressive deployment behind each of these feature flags. 

我们发布流程的第一阶段通常是由 Claude 管理金丝雀流量、监控问题，并自动上调或下调给定的功能开关。这本身完全可以单独写一篇文章，所以这里我就不再展开了。

> The first stage of our rollout process usually involves Claude managing canary traffic, monitoring for issues, and automatically ramping a given feature flag up or down. This could be an entirely separate article, so I won't go into more detail here.

Claude Tag 帮助我的团队处理的其他解决路径包括：

> Other resolution paths that Claude Tag helps my team with are:

- 让我们知道是否需要排空或隔离 Kubernetes 集群中的某些部分；。
- 指导我们如何扩展部分基础设施以应对需求激增（这种情况很少见，但当 Claude 给出我们可以采取的确切缓解措施时，帮助非常大）；以及，最常见的是，
- 以 PR 形式提供的修复，值班人员可以对其进行审查、合并，然后部署，从而迅速解决问题。

> • Letting us know if we need to drain or cordon off certain sections of our Kubernetes cluster;.
> • Giving us instructions on how to scale up some of our infrastructure in responses to demand-surges (this is rare but it’s very helpful when Claude comes back with exactly what we can do for mitigation); and, most frequently,
> • Fixes in the form of a PR that the on-call can review, merge, and then deploy for a swift resolution.

#### **验证、沟通与交接**

> **Verification, communication, and handoff**

Claude 使用了许多与它在调查过程中所用相同的 MCP 连接器和工具，来验证修复是否按预期生效。作为 oncall.md 中常设指令的一部分，它会将一份事后复盘写入 lessons.md，并写入用于交接的 SITREP。

> Claude uses many of the same MCP Connectors and tools that it did for its investigation to verify the fix worked as intended. As part of the standing instructions in oncall.md, it writes a post-mortem to lessons.md and for the handoff SITREP.

为了完整呈现多起事故的全貌，我们创建了一个名为 ci-weather 的 agent。它会汇总每个事故 Slack 频道的信息、构建指标、合并队列统计数据以及部署延迟情况。然后，它会以新闻编辑室的风格把报告发布到一个公司里任何人都能查看的公开频道。现在，我们的工程师在判断是否应该暂缓合并，或者想要弄清楚“CI 到底出了什么问题？”时，可以直接查看那个频道，而不必来找我们询问。

> To communicate the full picture across multiple incidents, we created an agent called ci-weather. It compiles information from each incident Slack channel, build metrics, merge queue stats, and deploy lag. Then it posts a newsroom-style report to one public channel anyone in the company can read. Now, our engineers can reference that channel rather than pinging us when they are trying to determine if they should hold their merges or if they’re trying to answer “what’s wrong with CI?”.

坦白说一点：我们前后迭代了好几版报告格式。Claude 可以一次性生成一个用于产出状态报告的技能，但真正让报告变得易读的，是团队特有的品味。这属于人与人之间的沟通，而不是管道工程。

> One honest note: we needed to iterate the report format several times. Claude can one-shot a skill that generates a status report, but what makes it readable is team-specific taste. It's human communication, not plumbing.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a84a163e2030bce8127ddb1_c00ab792.png)

最后，虽然 Claude 会在 lessons.md 中为自己记录日志，我们也希望每周一为人类生成交接报告。Claude 会产出每日和每周摘要，这样团队中的一位成员就能接手另一位成员未完成的工作。

> Finally, while Claude keeps a journal for itself in lessons.md, we also want to produce handoff reports for humans as well every Monday. Claude produces daily and weekly summaries so one member of the team can pick up where the other left off.

#### **从监控事件到监控事件响应系统**

> **From monitoring incidents to monitoring an incident response system**

我们的软件工程师现在平均每季度[交付的代码量是 2021 至 2025 年期间的 8 倍](https://www.anthropic.com/institute/recursive-self-improvement)。而且，尽管我们始终保持着很高的质量标准（每个 PR 都有一位具名的人类负责人，每一处改动都需要经过批准才能合并，每一处改动都要通过同一套 CI 关卡），但要跟上智能体编码的节奏，唯一的办法就是让 CI 也智能体化。

> Our software engineers on average [ship 8x as much code per quarter](https://www.anthropic.com/institute/recursive-self-improvement) as they did from 2021 to 2025. And while we have kept the quality bar high (every PR has a named human owner, every change requires approval to merge, every change goes through the same set of CI gates), the only way to keep up with agentic coding is agentic CI.

Claude 承担了我工作中那些繁琐的部分——非工作时间的打扰以及事故沟通，让我能够专注于中长期的架构变更，而这些才是真正能提升系统可靠性的关键。

> Claude has absorbed the tedious parts of my job, the after-hours disruptions and the incident comms, while allowing me to focus on the medium and long term architectural changes that truly move the needle for system reliability. 

我们所构建的一切中最棒的部分在于，它并不让人感觉支离破碎。我们的值班流程仍然在 Slack 中运行，只不过现在 Claude 也加入了这个频道。

> The best part of what we have built is that it doesn’t feel scattered. Our on-call processes live in Slack, but now Claude has joined the channel.

如何开始：

> How to get started:

- 你需要一个 [Claude Team 或 Claude Enterprise](https://support.claude.com/en/collections/9387370-team-and-enterprise-plans) 套餐
- 组织所有者需要通过 Claude Tag 将 Claude 添加到 on call Slack 频道
- 组织所有者还需要帮助将值班 Slack 频道中的 Claude 连接到相应的连接器和 GitHub 仓库，并设置 [Claude Code Remote](https://code.claude.com/docs/en/remote-control)。
- 将 Claude 添加到你的事故响应频道，并指示它监控事故并立即进行分类定级

> • You’ll need a [Claude Team or Claude Enterprise](https://support.claude.com/en/collections/9387370-team-and-enterprise-plans) plan
> • The organization owner needs to add Claude to the on call Slack channel via Claude Tag
> • The org owner also needs to help connect Claude in the on-call Slack channel to the appropriate connectors, GitHub repo, and set up [Claude Code Remote](https://code.claude.com/docs/en/remote-control).
> • Add Claude to your incident channel and instruct it to monitor for incidents and immediately triage

[使用我们的配置工具包搭建你自己的 Claude 值班助手](https://github.com/anthropics/oncall-kit)*。*

> [Set up your own Claude on-call with our setup kit](https://github.com/anthropics/oncall-kit)*.*

*本文由 Anthropic 技术团队成员 Sachin Malhotra 撰写，Anthropic 团队成员 Michael Segner 参与贡献。*

> *This article was written by Sachin Malhotra, technical member of Anthropic staff with contributions from Michael Segner, Anthropic staff.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| on-call | 值班 / 值守 | 工程师在轮值期间随时待命处理线上告警与事故的制度。 |
| CI/CD | 持续集成 / 持续交付 | 自动化构建、测试与部署代码变更的工程流水线。 |
| feature flag | 功能开关 | 在不重新部署的前提下动态启用或关闭某项功能的配置项。 |
| triage | 分诊 / 分级定级 | 对涌入的告警或事故按严重性和紧急度排序并决定处理路径。 |
| SITREP (situation report) | 态势报告 | 简明汇总当前事故状态、已知证据与下一步行动的结构化报告。 |
| MTTR (mean time to resolution) | 平均解决时间 | 从事故发生到彻底恢复所耗时间的平均值，衡量响应效率。 |
| MCP connector | MCP 连接器 | 基于 Model Context Protocol 把外部工具和数据源接入智能体的组件。 |
| orchestrator agent | 编排智能体 | 负责拆解任务、派发子智能体并综合其结果的上层智能体。 |
| executor sub-agent | 执行器子智能体 | 受编排智能体调度、针对单一依赖或事实来源执行具体调查的子进程。 |
| dynamic workflow | 动态工作流 | 智能体在运行时按任务需要自行组织步骤与子任务的执行模式。 |
| runbook | 排查手册 / 操作手册 | 针对特定故障场景列出诊断与处置步骤的标准化文档。 |
| alert fatigue | 告警疲劳 | 告警过多过杂导致响应者逐渐迟钝甚至忽略真实故障的现象。 |
| canary traffic | 金丝雀流量 | 先将小比例真实流量导向新版本以观察风险的渐进发布手段。 |
| shadow divergence | 影子分歧 | 影子运行的新旧系统对同一输入产生不一致结果的缺陷类型。 |
| merge queue | 合并队列 | 对待合并 PR 排队并依次验证后再入主干的机制。 |
| postmortem | 事后复盘 | 事故结束后记录经过、根因与改进项的回顾文档。 |
