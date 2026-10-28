# 在 Google Cloud 上管理 Claude Code 的成本并证明其投资回报率（ROI）

> Manage costs and demonstrate ROI for Claude Code on Google Cloud

> 来源：Claude Blog / Anthropic，2026-10-27
> 原文链接：https://claude.com/resources/articles/how-to-manage-costs-and-demonstrate-roi-for-claude-code-on-google-cloud
> 分类：AI 开发工具 / 成本治理与 ROI 度量

## 核心要点

- Google Cloud 上的 Claude 按用量计费，Claude Code 的账单取决于任务消耗的 token 数量和所选模型的单价，智能体式多步骤任务比聊天消耗更多 token。
- Google Cloud 原生提供按项目计费、预算提醒、支出上限（预览版）、BigQuery 导出、配额和预置吞吐量等成本跟踪与控制功能。
- Claude 应用网关是部署在用户 Google Cloud 项目中的自托管服务，通过身份提供商登录为每个请求附加经过验证的身份，从而支持按 IdP 组设置模型允许列表和按用户、组或组织设置周期性支出上限。
- 控制杠杆强调以护栏引导而非武断限制，因为高成本会话常来自高价值重度用户，浪费更多出现在用错模型或遗忘的定时任务等中间地带。
- 网关在开发者用量超过 75% 和 95% 时发出 CLI 内警告，达到上限后返回 429，管理员可通过管理 API 以编程方式调整上限，并可借助模型默认值引导多数用户的模型选择。
- 追踪杠杆依靠 Claude Code 的 OpenTelemetry 指标与事件，按用户、团队、模型以及技能、插件、智能体和 MCP 服务器细分使用量与预估成本，并可通过 OTEL_RESOURCE_ATTRIBUTES 附加成本中心等自定义标签。
- Google 提供现成的 Cloud Monitoring 仪表板模板和 OTel 快速入门，可将遥测数据导入 Cloud Logging、Cloud Monitoring 及按事件类型分区的 BigQuery 表进行分析。
- 证明杠杆从采用与使用、开发者满意度和影响三个维度衡量价值，影响指标可按时间、投入量和产出量划分，并以源代码管理和工单中的历史交付记录作为基线。
- 衡量时应明确工作单元，统计某一明确类别中已完成的成果，而非简单计数 PR，同时将 Claude Code 遥测与 GitHub、GitLab 和工单系统关联，因为 Claude Code 统计的是其创建而非最终合并的 PR。
- Delivery Hero、Shopify 和 Fifth Dimension 等客户案例展示了 Claude Code 在加速工程工作、扩大构建者群体和大规模代码产出方面的成效，治理应从合理默认设置开始并随使用数据持续细化。

## 正文

随着组织将越来越多的工作交给 Claude Code，相关支出也随之增长，平台团队需要一种既能控制成本、又能了解其影响的方法。受近期与 Google Cloud 合办的[一场网络研讨会（在新标签页中打开）](https://www.anthropic.com/webinars/how-to-control-costs-and-show-roi-for-claude-code-on-google-cloud)启发，我们将分享使用 Claude Code 的组织如何在 Google Cloud 上更好地跟踪和优化这些方面，其中包括三个核心抓手：控制、跟踪和证明。

> As organizations delegate more work to Claude Code, spend grows with it, and platform teams need a way to both control costs and understand impact. Inspired by [a recent webinar (opens in new tab)](https://www.anthropic.com/webinars/how-to-control-costs-and-show-roi-for-claude-code-on-google-cloud) with Google Cloud, we share how organizations using Claude Code can better track and optimize these considerations on Google Cloud, including three core levers: control, track, and prove.

#### 用于管理 Claude Code 支出的控制措施

> Controls for managing Claude Code spend

Google Cloud 上的 Claude 采用按用量计费，因此你的账单直接反映了开发者在你的 Google Cloud 环境中使用 Claude 的程度。采用带动使用；你为使用付费，而价值也正是在使用中体现出来的。

> Claude on Google Cloud has consumption-based pricing, so your bill is a readout of how much your developers are using Claude in your Google Cloud environment. Adoption drives usage; usage is what you pay for, and it’s also where the value shows up.

你的 Claude Code 账单取决于任务消耗的 token 数量以及处理这些任务的模型。token 消耗量随任务复杂度和对话长度而增长。聊天是一种问答式对话。与聊天相比，像 Claude Code 这样的智能体工具在每个任务上会消耗更多 token，因为它执行的是多步骤工作：读取文件、运行工具，并在整个任务中进行推理。同时，每个模型都有各自的每 token 价格，因此[为任务匹配合适的模型](https://claude.com/blog/claude-model-and-effort-level-in-claude-code)是另一项主要的成本控制手段。

> Your Claude Code bill is a product of how many tokens tasks consume and the models that handle them. Token consumption scales with task complexity and conversation length. Chat is a Q&A conversation. An agentic tool like Claude Code spends more tokens per task relative to chat because it's doing multistep work: reading files, running tools, and reasoning across a whole task. Meanwhile each model has its own price per token, so [matching the model to the task](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) is the other major cost control.

您可以通过 [Claude 应用网关](https://claude.com/blog/introducing-the-claude-apps-gateway)和 Google Cloud 服务，了解每月影响组织账单的令牌用量和模型选择情况。您可以通过三个相互独立的手段来管控支出和管理成本：

> Visibility into the tokens and model choices impacting your organization’s bill each month is available through the [Claude apps gateway](https://claude.com/blog/introducing-the-claude-apps-gateway) and Google Cloud services. You can govern the spend and manage costs via three independent levers:

- **控制**。建立护栏来引导使用，同时避免过度限制访问、无意中将人拒之门外。
- **追踪**。在账单到来之前，精细掌握支出发生在哪里，以及后续还将流向何处。
- **证明**。识别贵组织从这些 token 支出中获得的价值，并准确归因其具体来源。

> • **Control**. Creating guardrails that guide usage without over-restricting access and unintentionally blocking people.
> • **Track**. Granular oversight of where the spend is happening, and where it will continue to go, before the bill arrives.
> • **Prove**. Identifying the value your org is getting from spending these tokens and attributing exactly where it’s coming from.

以下介绍如何将这套“控制 -> 追踪 -> 证明”框架应用到你自己在 Google Cloud 上部署的 Claude Code 中。

> Here’s how to apply this control -> track -> prove framework to your own Claude Code on Google Cloud deployment.

![graphic showing control - track - prove categories and the tools used in each](https://assets.claude.com/50faca60a22f422f7c0f5e9d2f4177a1ea483448.png)

##### **治理工具箱**

> **The governance toolbox**

Google Cloud 上的 Claude 提供了一系列工具和功能，帮助你控制、追踪支出，并证明支出带来的价值。

> Claude on Google Cloud comes with tools and capabilities for controlling, tracking, and proving the value of your spend.

![Graphic showing Google Cloud native and Claude Code + Claude apps gateway add](https://assets.claude.com/b3266f5cebd6e2613593339d21200b3a7c034b9a.png)

Google Cloud 已经为你提供了许多原生功能，可用于跟踪和控制你在 Claude 上的支出：

> Google Cloud already gives you many native capabilities you can apply to tracking and controlling your Claude spend:

- **按项目计费**。允许你为 Claude Code 托管一个专用项目，以清晰地追踪成本。
- **账单预算与提醒**。允许你设置预算提醒，并在实际支出超过你定义的阈值时收到通知。
- **支出上限（预览版）。**允许您强制执行服务级别的 Google Cloud 支出预算，并可手动解除该上限。
- **BigQuery 导出。**让你能够将 Claude 的支出与其余云成本放在一起进行分析。
- **配额。**Google Cloud 上的 Claude 模型针对每个模型系列和端点位置，分别设有每分钟请求数、输入 token 数和输出 token 数的限制。
- **预置吞吐量。**为预留容量支付固定费用，而不是按用量付费。

> • **Per-project billing**. Allows you to host a dedicated project for Claude Code as a clean way to track costs.
> • **Billing budgets and alerts**. Allows you to set budget alerts and get notified as actual spend crosses thresholds you define.
> • **Spend caps (Preview). **Allows you to enforce a service-level Google Cloud spend budget with ability to manually lift the cap.
> • **BigQuery exports. **Lets you analyze Claude spend alongside the rest of your cloud costs.
> • **Quotas. **Claude models on Google Cloud have per-minute limits on requests, input tokens, and output tokens for each model family and endpoint location.
> • **Provisioned throughput.** Pay a fixed fee for reserved capacity instead of pay-as-you-go.

Claude Code 与 Claude 应用网关增加了各自的跟踪和控制能力。该网关是一项自托管服务，与您的开发者已在使用的同一个 `claude` 二进制文件一同发布，运行在您的 Google Cloud 项目中，位于 Claude Code 与 Google Cloud 上的 Claude 之间。开发者通过您的身份提供商（例如 Google Workspace）登录，因此每个请求都带有经过验证的身份。这样，您就可以按 IdP 组设置模型允许列表，并按用户、IdP 组或组织，以天、周或月为周期设置支出上限。

> Claude Code and Claude apps gateway add their own tracking and control capabilities. The gateway is a self-hosted service, shipped in the same `claude` binary your developers already use, that runs in your Google Cloud project between Claude Code and Claude on Google Cloud. Developers sign in through your identity provider, such as Google Workspace, so every request carries a verified identity. That lets you set model allowlists per IdP group, and spend caps per user, IdP group, or organization, by day, week, or month.

以下介绍如何选择并组合各项能力，以管理衡量贵组织在 Google Cloud 上借助 Claude 进行 AI 投资的成本与投资回报率（ROI）的三大杠杆：

> Here's how to choose and combine capabilities to manage the three levers measuring the cost and ROI behind your organization’s AI investments with Claude on Google Cloud:

###### 杠杆一：控制

> Lever 1: Control

控制杠杆的核心在于提供护栏，引导开发者使用 Claude Code，而不是用武断的上限去限制他们。

> The control lever is all about providing guardrails that guide developers in their Claude Code use, instead of restricting them with arbitrary caps.

之所以要引导而非限制，是因为高成本会话未必是坏事——事实上，它们往往价值很高，在 Claude Code 中尤其如此。这类会话通常来自走在最前沿的重度用户，他们在使用新的工作流，从 Claude 获得大量价值，并完成大量工作。

> Guiding rather than restricting is important because high cost sessions are not necessarily bad — in fact, they're often high value, especially in Claude Code. Those sessions are generally your power users that are at the forefront, using new workflows and getting a lot of value from Claude and getting a lot of work done.

浪费往往藏在重度用户用量分布中那段漫长的中间地带。比如，他们用 Fable 来处理 Sonnet 就能轻松胜任的日常例行任务；又或者，他们忘了某个早已不再关心的定时任务，而它却依然在自动运行。

> Waste tends to sit in the long middle of heavy spenders. For example, they're using Fable for a daily routine that Sonnet can easily handle. Or maybe they have forgotten some scheduled task they no longer care about, but it keeps on running automatically anyway.

有四项功能为你提供护栏，让你能够引导用户，而不是限制他们：

> There are four features that give you the guardrails to guide your users instead of restricting them:

- **[支出限额（在新标签页中打开）](https://code.claude.com/docs/en/claude-apps-gateway-spend-limits)。**Claude 应用网关允许你按用户、按 IdP 组或在整个组织范围内设置支出上限，可按天、周或月设定。组和组织上限是每位成员各自继承的单个开发者默认额度，而非共享额度池。
- **阈值提醒。**与 Claude apps gateway 配合使用时，Google Cloud 上的 Claude Code 会在开发者接近其上限时发出警告：首次在超过 75% 时，再次在超过 95% 时。这些是面向开发者的 CLI 内警告，而 Google Cloud Billing 提醒则面向管理员。达到上限后，网关会返回 429，直到周期重置或管理员提高上限为止；你还可以通过网关的管理 API 以脚本方式提高上限。
- **模型默认值与允许列表。**通过 Claude 应用网关，按 IdP 组指定可用的模型；该网关会在服务端对每个请求强制执行允许列表。我们发现，设置模型默认值的效果非常好，因为大多数人会沿用默认模型；如果他们想切换模型，通常是出于某种原因。你可以在使用模型允许列表的同时使用模型默认值，也可以用模型默认值来替代模型允许列表。
- **Gateway 管理 API。**该网关提供一个[用于支出限额的管理 API（在新标签页中打开）](https://code.claude.com/docs/en/claude-apps-gateway-spend-limits)，因此你可以以编程方式设置和更改上限，例如通过工单工作流来实现。

> • **[Spend limits (opens in new tab)](https://code.claude.com/docs/en/claude-apps-gateway-spend-limits). **The Claude apps gateway allows you to set spend caps per user, per IdP group, or organization-wide, by day, week, or month. Group and organization caps are per-developer defaults that each member inherits, not a shared pool.
> • **Threshold alerts.** When used with Claude apps gateway, Claude Code on Google Cloud warns developers as they approach their cap, first past 75% and again past 95%. These are in-CLI warnings for developers, whereas Google Cloud Billing alerts are meant for admins. At the cap, the gateway returns 429 until the period resets or an admin raises the cap, and you can script cap increases through the gateway's admin API.
> • **Model defaults and allowlists.** Specify which models are available, per IdP group, via the Claude apps gateway which enforces the allowlist server-side on every request. We have found that setting a model default works really well, because most people will stick to the model default; if they want to switch models, they usually are switching for a reason. You can use model defaults in addition to or instead of model allowlists.
> • **Gateway Admin API. **The gateway serves an [admin API for spend limits (opens in new tab)](https://code.claude.com/docs/en/claude-apps-gateway-spend-limits), so you can set and change caps programmatically, for example using a ticketing workflow.

![Graphic showing the phases of a spend-cap lifecycle](https://assets.claude.com/d1ded8cd5410c90e62905f650bf2a4e09df4cdce.png)

结合这些功能来控制你的总体账单，但请记住，控制只是第一个杠杆。每 token 的价格并不能反映全貌。最重要的指标是每项任务的成本，可以通过跟踪这些用量来对其进行监控和分析。

> Combine these capabilities to control your overall bill, but remember that control is only the first lever. Price per token doesn't give you the full picture. The most important metric is the cost per task, which can be monitored and analyzed by tracking this usage.

###### 杠杆 2：追踪

> Lever 2: Track

这一杠杆的核心在于看清支出流向何处以及如何被使用。好消息是，你可以在整个组织范围内追踪 Claude Code 的使用量、成本和工具活动。主要的追踪策略包括：

> This lever is all about seeing where spend is going and how it’s being used. The good news is that you can track Claude Code usage, costs, and tool activity across your organization. Primary tracking strategies include:

- **使用量与成本可观测性。**[Claude Code 的 OpenTelemetry 指标和事件（在新标签页中打开）](https://code.claude.com/docs/en/monitoring-usage)会报告使用量和预估成本，并按技能、插件、智能体和 MCP 服务器细分。你可以通过 OpenTelemetry 协议（OTLP），借助 OpenTelemetry 收集器或经由 Claude 应用网关中继（用于集中式 OpenTelemetry 配置），将它们发送到你已在使用的工具，例如 Google Cloud Monitoring。
- **终端用户用量视图。**开发者可以直接在 Claude Code 中查看自己的支出，并在触及限额之前收到用量提醒。
- **将数据导出到您现有的系统。**借助 Google Cloud Billing 导出到 BigQuery 的功能，您可以按模型和 token 类型筛选 Claude SKU，将 Claude 支出与其他云和 AI 支出放在一起查看。OTel 数据会流入您的可观测性（O11y）技术栈，而网关 Admin API 可以将支出限额状态直接推送到您的工单系统。

> • **Usage and cost observability. **[Claude Code's OpenTelemetry metrics and events (opens in new tab)](https://code.claude.com/docs/en/monitoring-usage) report usage and estimated cost, broken down by skill, plugin, agent, and MCP server. Send them over OpenTelemetry Protocol (OTLP) to tools you already run, such as Google Cloud Monitoring, through an OpenTelemetry collector or relayed by the Claude apps gateway (for centralized OpenTelemetry config).
> • **End-user usage view.** Developers see their own spend and get usage warnings right in Claude Code before they hit a limit.
> • **Data export to your existing systems.** Google Cloud Billing exports to BigQuery let you filter to Claude SKUs by model and token type, putting Claude spend alongside the rest of your cloud and AI spend. OTel flows to your O11y stack, and the gateway Admin API can feed spend-limit status straight into your ticketing system.

![Graphic showing Claude Code telemetry on Google Cloud](https://assets.claude.com/f2ab59204d683994ef32ddc5b4e6f1167389a800.png)

无论是在开发者本机还是在云工作站上运行，Claude Code 在启用后都可以导出 OpenTelemetry 数据，包括会话、活跃时间、代码行数、提交、拉取请求、token 和成本，并可按用户、团队和模型细分。Claude Code 的最新版本还会按技能、插件、智能体和 MCP 服务器细分用量，因此你不仅能看到 Claude Code 的整体使用情况，还能看到组织内部的哪些技能和插件得到了采用。借助 Claude apps 网关，你无需逐台配置机器。只需在网关上设置遥测目标，它就会为已登录的开发者开启遥测。它还会使用开发者登录时经过验证的电子邮件和 IdP 组为每次导出打上标签，而不是使用客户端配置的值。

> Claude Code, whether running on developer machines or on cloud workstations, can export OpenTelemetry once you enable it, including sessions, active time, lines of code, commits, pull requests, tokens and cost, broken down by user, team, and model. The most recent releases of Claude Code also break usage down by skill, plugin, agent, and MCP server so you can see not just overall Claude Code usage but also which of your org’s internal skills and plugins get adopted. With the Claude apps gateway, you don't need to configure each machine. Set a telemetry destination on the gateway, and it turns telemetry on for signed-in developers. It also tags every export with the developer's verified email and IdP groups from their sign-in, rather than values configured on the client-side.

要将使用量归属到您自己的成本中心和部门，请设置 OTEL_RESOURCE_ATTRIBUTES 环境变量（例如 department=engineering,cost_center=eng-123）。Claude Code 会将这些标签添加到每个指标和事件中，以便您按它们进行筛选和聚合。这些指标会连同这些自定义属性一起进入 Google Cloud Monitoring（或 Grafana、Splunk 等其他监控解决方案）。

> To attribute usage to your own cost centers and departments, set the OTEL_RESOURCE_ATTRIBUTES environment variable (for example, department=engineering,cost_center=eng-123). Claude Code adds these tags to every metric and event, so you can filter and aggregate by them. The metrics land in Google Cloud Monitoring (or other monitoring solutions like Grafana or Splunk) with those custom attributes.

![A screenshot of a dashboard](https://assets.claude.com/201a89049ce753ac7e42f8518d1db7908b40a91a.png)

典型的采用情况视图会显示活跃开发者数、过去 24 小时内的会话数以及消耗的 token 总量。橙色框显示的是开发者触及网关强制执行的支出上限时被拦截的请求。该指标可以与你现有的工单系统很好地配合，形成一个允许开发者申请提高额度的工作流。

> A typical adoption view shows active developers, number of sessions over the last 24 hours, and total tokens consumed. The orange box shows blocked requests when developers hit their gateway-enforced spend caps. That metric pairs well with your existing ticketing system as a workflow that allows developers to request an increase.

如需现成的 Cloud Monitoring 仪表板，请参阅 [Claude Code Monitoring 模板（在新标签页中打开）](https://github.com/GoogleCloudPlatform/monitoring-dashboard-samples/tree/master/dashboards/claude-code)，该模板将 Claude Code 的 OpenTelemetry 指标整合为一个统一视图，涵盖采用情况、编码活动、token 用量及预估支出，让你在 Google Cloud 上推广 Claude Code 时，可以按用户和模型跟踪使用量与成本。你可以直接在 Cloud Monitoring 控制台中复制此模板。

> For ready-made Cloud Monitoring dashboard, refer to the [Claude Code Monitoring template (opens in new tab)](https://github.com/GoogleCloudPlatform/monitoring-dashboard-samples/tree/master/dashboards/claude-code), which turns Claude Code’s OpenTelemetry metrics into a single view of adoption, coding activity, and token usage and estimated spend, so you can track usage and costs by user and model as you roll out Claude Code on Google Cloud. You can copy this template directly from within the Cloud Monitoring console.

要在 Google Cloud 上设置自定义 Claude Code 遥测，请从 [Claude Code OTel 快速入门（在新标签页中打开）](https://github.com/Google-Cloud-AI/partner-ai-anthropic/tree/main/01-quickstart/otlp-to-telemetry-api)开始。借助它，你可以配置 Claude Code，将 OpenTelemetry 数据直接导出到 Google Cloud Observability 套件，包括 Cloud Logging 和 Cloud Monitoring。该快速入门还会将日志路由到分区的 BigQuery 表中，每种事件类型对应一张表（API 请求、工具决策、工具结果、助手响应以及已完成的 hook 执行），并提供 SQL 查询，用于按开发者/模型统计支出、分析工具成功率与延迟、hook 等待时间，以及按轮次和按会话进行分析。

> To set up custom Claude Code telemetry on Google Cloud, start with the [Claude Code OTel quickstart (opens in new tab)](https://github.com/Google-Cloud-AI/partner-ai-anthropic/tree/main/01-quickstart/otlp-to-telemetry-api). Use it to configure s Claude Code to export OpenTelemetry straight to Google Cloud Observability suite including Cloud Logging and Cloud Monitoring. The quickstart also routes logs into partitioned BigQuery tables, one per event type (API requests, tool decisions, tool results, assistant responses, and completed hook executions), and ships SQL queries for spend per developer/model, tool success and latency, hook wait time, per-turn and per-session analytics.

###### 杠杆 3：证明

> Lever 3: Prove

“控制”杠杆负责管理和分摊使用量与成本；“追踪”杠杆让你能够将这些支出可视化。“证明”杠杆则是你将 Google Cloud 上 Claude Code 的使用量与投资回报率（ROI）对应起来的方式。

> The control lever governs and apportions usage and costs; the track lever allows you to visualize that spend. The prove lever is how you map usage to ROI for Claude Code on Google Cloud.

平台工程师最关心的 Claude Code 衡量指标可归入三个维度：使用情况、开发者满意度和影响。

> The metrics that platform engineers care most about measuring in Claude Code are contained within three dimensions: usage, developer satisfaction, and impact.

**采用与使用**指标衡量组织内成员使用 Claude 的情况，包括已激活用户及其每周和每日的使用情况。这些指标能揭示使用深度、用户随时间的留存情况，以及谁是 Claude Code 的重度用户等信息。所有这些指标均来自 Claude Code 的 OTel 数据。

> **Adoption and usage** metrics measure how people are using Claude in your organization, including your activated users and their weekly and daily usage. These reveal information like depth of use, user retention over time, and who your Claude Code power users are. These metrics are all derived via Claude Code OTel data.

**满意度**指标用于监测工程师的用户体验，包括他们对 Claude Code 的满意程度、感知到的时间节省、对输出结果的信心，以及可能遇到的任何阻碍。满意度指标来自推广前后各进行一次的简短问卷调查，以及之后持续的用户回访。

> **Satisfaction** metrics monitor the user experience for your engineers, including their happiness with Claude Code, perceived time savings, confidence in output, and any friction they might experience. Satisfaction metrics come from a short survey run before and after rollout, followed by ongoing user check-ins.

**影响力**指标用于评估 Claude 在交付可衡量工程成果方面的表现：将吞吐量、周期时间和评审速度与基线进行对比，并对特定工作内容进行定性衡量。

> **Impact **metrics assess how Claude is delivering measurable engineering outcomes, comparing throughput, cycle time, and review speed against a baseline, plus qualitative measurements on specific bodies of work.

##### **一组初始的影响力指标**

> **A starting set of impact metrics**

以下是一组初始的影响力指标，分为三个方面：时间、投入和规模。

> Here's a starting set of impact metrics, grouped into three areas: time, effort, and volume.

**时间**衡量工作交付的速度：PR 从创建到合并（open -> merge）的周期时间，以及代码评审的周转时间。

> **Time** measures how quickly work ships: PR cycle time from open -> merge, and code review turnaround.

**投入量**衡量每项变更需要多少工作：每个 PR 的评审轮次、每个 PR 的评审意见数量与返工量。

> **Effort **measures how much work each change takes: review iterations per PR, review comments and rework per PR.

**产出量**衡量释放出的产能带来了什么：每位工程师的 PR 数、部署频率，以及具名的工作成果，即你的团队利用释放出的产能交付的具体待办事项。这些在数量统计之外补充了定性视角。

> **Volume** measures what the freed-up capacity delivers: PRs per engineer, deployment frequency, and named bodies of work: the specific backlog items your teams shipped with the freed capacity. These add a qualitative view alongside the counts..

这些是方向性的参考点，而非硬性规则，但它们是衡量 Claude Code 在你的组织中所产生影响的良好起点。你所需的基线早已存在：就是你在源代码管理和工单中的交付历史。

> These are directional reference points, not rules, but a good starting point for measuring Claude Code's impact in your organization. The baseline you need already exists: your delivery history in source control and tickets.

##### **定义你的工作单元**

> **Define your unit of work**

这些指标大多统计 PR 数量，但修一个错别字和发布一项功能都只算一个 PR。因此，应改为统计某一明确类别中已合并的 PR：由 Claude 提交 PR，由人来决定是否发布。借助 hotfix 或 feature release 之类的标签、工单 ID 以及 Claude 是否参与等信息，就能在你现有的系统中轻松找到这些 PR。并非每个工作单元都是 PR，例如一次服务切换，或一个已从根本原因上解决并关闭的事故。规则同样适用：在成果落地的地方，统计一件已完成的事。

> Most of these metrics count PRs, but a typo fix and a feature release are both one PR. Therefore, count merged PRs of a defined class instead: Claude opens the PR, and a person decides whether it ships. Labels such as hotfix or feature release, the ticket ID, and whether Claude was involved make those PRs easy to find in the systems you already run. Not every unit of work is a PR; a service cutover or an incident closed at its root cause are examples. The same rule applies: count one finished thing, where it lands.

#### Claude Code 原生遥测

> Claude Code native telemetry

在落实成本治理和使用情况跟踪之后，下一步是将其与投资回报率（ROI）关联起来。Claude Code 的原生遥测功能可帮助你采集贡献度和生产力指标，从而记录你的组织所获得的价值。

> After putting cost governance and usage tracking in place, the next step is to map those to ROI. Claude Code’s native telemetry helps you capture contribution and productivity metrics that document the value your organization is deriving.

![Graphic showing Claude Code native telemetry with three columns: Usage, Cost, Contribution / Productivity.](https://assets.claude.com/5d1a4e740237e04f4524c9ff169e0f70def7c5ab.png)

借助 Claude Code 的 OTel 指标，你可以追踪或推导出代码建议接受率、修改的代码行数、创建的提交数、创建的 PR 数、单位产出成本以及人均 PR 数。

> Claude Code’s OTel metrics let you track or derive code suggestion accept rate, lines of code modified, commits created, PRs created, cost per unit of output, and PRs per user.

所有这些原生指标都提供了有用且可据以行动的信息。如果再结合通过[Google Cloud 上的 Claude Code 遥测（在新标签页中打开）](https://docs.google.com/document/d/1LezclyuvbRQ9tInAet0loCEPiNIITB8eLHvzNik9IBs/edit?tab=t.nr7gi1cdf1oi#heading=h.vdcj39wwyv9f)捕获的日志事件（例如用户提示词和工具决策），这些信息的价值会更大。例如，记录用户提示词是了解用户群正在尝试构建的所有内容的好方法，因为并非每个工作单元都一定是一个 PR。请注意，由于可能包含敏感内容，用户提示词不会被自动记录；你必须专门选择启用。

> All of these native metrics offer useful and actionable information. This info becomes even more valuable when paired with logged events like user prompts and tool decisions, captured via [Claude Code telemetry on Google Cloud (opens in new tab)](https://docs.google.com/document/d/1LezclyuvbRQ9tInAet0loCEPiNIITB8eLHvzNik9IBs/edit?tab=t.nr7gi1cdf1oi#heading=h.vdcj39wwyv9f). Logging user prompts, for example, is a good way to understand everything your user base is trying to build, because not every unit of work is necessarily a PR. Note that user prompts are not logged automatically due to potentially sensitive content; you have to specifically opt in.

举例来说，如果你是 SRE，可以用 Claude Code 排查故障；如果你是售前工程师，可以用它为现场演示生成示例数据。这些会话不会产生 PR，但确实加快了这些团队的工作流程。请注意，Claude Code 的 PR 指标统计的是 Claude Code *创建*的 PR，而不是最终合并的 PR。源代码管理系统和工单系统仍然是已交付内容的记录依据，因此请将 Claude Code 遥测数据与 GitHub 或 GitLab 以及工单跟踪系统关联起来，以获得全貌

> One example would be using Claude Code to troubleshoot an incident if you’re an SRE or generate sample data for a live demo if you’re a sales engineer. Those sessions do not result in a PR, but they do accelerate those teams’ workflows. Keep in mind that Claude Code's PR metric counts the PRs Claude Code *creates*, not what eventually merges. Your source control and ticketing systems remain the record of what shipped, so correlate Claude Code telemetry with GitHub or GitLab and your ticket tracker for the full picture

以下是部分使用 Google Cloud 上的 Claude 的客户借助 Claude Code 所取得的可衡量成效。

> Here’s the measurable impact that some Claude on Google Cloud customers have achieved with Claude Code.

- [Delivery Hero（在新标签页中打开）](https://claude.com/customers/delivery-hero)的一个团队对涵盖 100 个 UI 组件的设计系统进行了全面改造。Claude Code 在几分钟内就完成了通常需要一名工程师花费一周时间的工作。
- [Shopify（在新标签页中打开）](https://claude.com/customers/shopify)的工程师借助 Claude Code 构建得更快，而非工程师也能在几分钟内（而不是几天）搭建内部工具。Claude Code 正在扩大 Shopify 中能够动手构建的人群，而不只是让原本就在构建的人提速。
- [Fifth Dimension（在新标签页中打开）](https://cloud.google.com/customers/fifth-dimension-anthropic) 的工程师普遍在 Google Cloud 上使用 Claude Code。他们每月合计编写超过 300,000 行代码，接受率达 98%。

> • [Delivery Hero (opens in new tab)](https://claude.com/customers/delivery-hero) had a team overhaul a design system across 100 UI components. Claude Code did in minutes what would normally take a week of an engineer's time.
> • [Shopify  (opens in new tab)](https://claude.com/customers/shopify)engineers build faster with Claude Code, but non-engineers are also building internal tools in minutes instead of days. Claude Code is expanding who can build at Shopify, not just speeding up the people already building.
> • [Fifth Dimension (opens in new tab)](https://cloud.google.com/customers/fifth-dimension-anthropic) engineers universally use Claude Code on Google Cloud. Combined, they're writing over 300,000 lines of code a month with a 98% acceptance rate.

#### 快速入门

> Getting started

本文旨在帮助你熟悉现有的工具和功能，以便管理 Google Cloud 上 Claude Code 的成本并证明其投资回报率（ROI）。对于平台工程师而言，这套系统的作用不仅在于察觉和观察用户群体中的行为，还能为你提供动态调整治理策略和设置所需的信息。

> The goal of this post is to help you feel comfortable with the tools and capabilities that exist to help you manage Claude Code on Google Cloud costs and demonstrate ROI. As platform engineers, the system serves not only to notice and observe behavior in your user base. It also gives you the knowledge necessary to dynamically adjust governance and settings.

这是一个持续循环的过程：先从合理的默认设置入手，例如全组织范围的支出上限、默认模型和模型允许列表，然后随着使用数据的积累，按角色和团队逐步细化。通过跟踪实际使用情况，并将各项指标与您从 Claude Code 获得的价值关联起来，您便可以将这些结果提供给需要分析 Claude Code 投资回报率（ROI）和业务影响的利益相关方。

> It’s a continuous loop: start with reasonable defaults, such as an org-wide spend cap, a default model, and a model allowlist, then refine by role and team as usage data comes in. By tracking actual use and correlating metrics to the value you’re getting from Claude Code, you can then deliver these to your stakeholders who need to analyze the ROI and business impact of using Claude Code.

![Graphic showing a continuous loop for Control - Track - Prove framework](https://assets.claude.com/9a83ef407d2df018b107f8108d1955ad70702d7f.png)

随着我们委派给 Claude 的工作量不断增加、工作类型日益深入和多样，各组织在 Google Cloud 上使用 Claude Code 的方式以及从中获得的价值也将随之演进。本文概述的**控制 → 追踪 → 证明**框架，为衡量 Claude Code 部署的各个方面及其成效提供了一个稳定的起点。

> How organizations use Claude Code on Google Cloud and the value derived from that usage will both evolve as the amount of work and the type of work we're delegating to Claude keep getting deeper and more diverse. The **control → track → prove** framework outlined here is a stable starting point for measuring every aspect and outcome of your Claude Code deployment.

以下资源可帮助你快速上手：

> Here are resources to get you started:

- [有效管理成本（在新标签页中打开）](https://code.claude.com/docs/en/costs)
- [监控用量和成本（在新标签页中打开）](https://code.claude.com/docs/en/monitoring-usage)
- [Claude 应用网关支出限额（在新标签页中打开）](https://code.claude.com/docs/en/claude-apps-gateway-spend-limits)
- [在 Google Cloud 上部署 Claude 应用网关（在新标签页中打开）](https://code.claude.com/docs/en/claude-apps-gateway-on-gcp)
- [创建、编辑或删除预算和预算提醒（在新标签页中打开）](https://code.claude.com/docs/en/claude-apps-gateway-on-gcp)
- [管理支出上限预算 | Cloud Billing（在新标签页中打开）](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps)

> • [Manage costs effectively (opens in new tab)](https://code.claude.com/docs/en/costs)
> • [Monitoring usage and costs (opens in new tab)](https://code.claude.com/docs/en/monitoring-usage)
> • [Claude apps gateway spend limits (opens in new tab)](https://code.claude.com/docs/en/claude-apps-gateway-spend-limits)
> • [Deploy Claude apps gateway on Google Cloud (opens in new tab)](https://code.claude.com/docs/en/claude-apps-gateway-on-gcp)
> • [Create, edit, or delete budgets and budget alerts (opens in new tab)](https://code.claude.com/docs/en/claude-apps-gateway-on-gcp)
> • [Manage spend cap budgets | Cloud Billing (opens in new tab)](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Token | token（词元） | 模型处理文本时的基本计量单位，也是按用量计费的依据。 |
| Claude apps gateway | Claude 应用网关 | 位于 Claude Code 与云端 Claude 之间的自托管服务，提供身份认证、模型允许列表和支出限额等治理能力。 |
| Spend limit | 支出限额 | 按用户、组或组织在指定周期内允许消耗的最高费用。 |
| Model allowlist | 模型允许列表 | 规定特定用户组可调用哪些模型的服务端访问策略。 |
| Identity Provider (IdP) | 身份提供商 | 负责认证用户身份并提供组成员信息的服务，例如 Google Workspace。 |
| Provisioned Throughput | 预置吞吐量 | 以固定费用预留模型调用容量、而非按实际用量付费的计费方式。 |
| Quota | 配额 | 对每分钟请求数及输入、输出 token 数设定的使用上限。 |
| BigQuery export | BigQuery 导出 | 将云账单或日志数据导出到 BigQuery 以便进行 SQL 分析的功能。 |
| OpenTelemetry (OTel) | OpenTelemetry | 用于采集和导出指标、日志与追踪数据的开放可观测性标准。 |
| OTLP | OpenTelemetry 协议 | OpenTelemetry 用于传输遥测数据的标准协议。 |
| Observability (O11y) | 可观测性 | 通过指标、日志和追踪等数据理解系统运行状态的能力。 |
| MCP server | MCP 服务器 | 基于模型上下文协议向 AI 智能体提供工具与数据访问的服务。 |
| Cycle time | 周期时间 | 一项工作从开始到完成所经历的时间，如 PR 从创建到合并的时长。 |
| Acceptance rate | 接受率 | AI 生成的代码建议被开发者采纳的比例。 |
| Unit of work | 工作单元 | 用于衡量产出的明确、可计数的已完成工作成果。 |
