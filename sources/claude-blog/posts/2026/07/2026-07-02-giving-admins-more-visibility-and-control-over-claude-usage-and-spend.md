---
source: claude-blog
source_url: https://claude.com/blog/giving-admins-more-visibility-and-control-over-claude-usage-and-spend
published_at: 2026-07-02
category: Product announcements
title_en: Giving admins more visibility and control over Claude spend
title_zh: 为管理员提供对 Claude 支出的更多可见性与控制
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 2
source_image_count: 1
---

# 为管理员提供对 Claude 支出的更多可见性与控制

> Giving admins more visibility and control over Claude spend

> 来源：Claude Blog，2026-07-02
> 原文链接：https://claude.com/blog/giving-admins-more-visibility-and-control-over-claude-usage-and-spend
> 分类：Product announcements

## 核心要点

- Claude Enterprise 新增更丰富的管理员分析、模型级权限授予与支出告警,帮助管理员理解 Claude 的使用方式并管理成本。
- 分析面板可按群组和用户展示使用量与成本,并将创建的产物、编辑的文件、调用的技能与连接器等指标直接与成本并列显示,还可按 SCIM 群组过滤。
- Claude Code 新增聚焦价值与使用情况的两个标签页:一个展示活跃开发者、会话数与高频命令,另一个估算生产力提升、每次提交成本与年度价值,且所有公式可见、输入可调。
- 分析对话支持用自然语言提问(如哪些团队本月使用量翻倍),并返回可导出、可分享的图表与产物。
- 使用量与成本数据可通过分析 API 以编程方式获取,便于财务与 IT 接入 Datadog、CloudZero 等既有工具,并可按日期、团队、产品或模型过滤。
- 模型默认值与权限设置让管理员控制新会话在聊天、Cowork 和 Claude Code 中默认使用哪个模型,避免日常工作默认调用最昂贵的选项。
- 支出阈值告警会在达到组织级限额的 75% 与 90% 时通知管理员,用户则在 75% 与 95% 收到应用内提醒,并可直接向管理员申请提额。

## 正文

Claude Enterprise 推出全新的分析功能与成本控制能力。

> New analytics and cost controls are available for Claude Enterprise.

我们正在为 Claude 企业版（Claude Enterprise）引入更丰富的管理员分析、模型级权限（model-level entitlements）以及支出提醒。随着 Claude 在整个组织中承担越来越困难和复杂的智能体（agentic）工作，其使用和成本模式与标准聊天工具已有所不同。这些控制手段让管理员既能了解 Claude 的使用情况，也拥有管理成本的工具。

> We’re introducing richer admin analytics, model-level entitlements, and spend alerts for Claude Enterprise. As Claude takes on increasingly difficult and complex agentic work across the organization, usage and cost patterns look different from a standard chat tool. These controls give admins the visibility to understand how Claude is being used and the tools to manage costs.

今天新增的功能建立在 Anthropic 已有的控制手段之上：各层级的支出上限、访问与模型路由、支持导出的使用分析仪表盘以及分析 API（Analytics API），还有工作量（effort）控制。更丰富的分析和更细粒度的成本控制，是我们数月来持续构建的这套控制体系的最新补充。

> Today's additions build on controls Anthropic already provides: spend caps at every level, access and model routing, a usage analytics dashboard with exports and an Analytics API, and effort controls. Richer analytics and more granular cost controls are the newest additions to a control surface we've been building on for months.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a45ed484e5998965a180707_Cost-controls-admin-viz-thumbnail.png)

### 跟踪采用情况与成本

> Track adoption and cost

面向管理员的分析仪表盘现在可以按群组和按用户展示使用情况与成本，产出内容（例如创建的制品、编辑的文件、使用的技能和连接器）会直接显示在其成本旁边。管理员可以按其 IT 团队已管理的 SCIM 群组进行筛选，因此该明细会与既有的组织架构保持一致。

> The analytics dashboard for admins now shows usage and cost by group and by user, with output like artifacts created, files edited, skills and connectors used displayed directly next to their cost. Admins can filter by the SCIM groups their IT team already manages, so the breakdown follows their existing org chart.

Claude Code 在管理控制台内新增了两个专注于价值和使用情况的标签页，带来更丰富的洞察。使用情况（Usage）标签展示全组织范围内的活跃开发者、会话数以及最常用的命令，并每日更新。价值（Value）标签汇总使用与成本数据，帮助管理员一眼了解 Claude Code 的价值，估算生产力提升、每次提交成本以及年度价值。每个公式都在标签页中可见，且输入项可调整。

> Claude Code gets richer insights with two new tabs focused on value and usage inside the admin console. Usage shows active developers, session counts, and top commands across the org, and is updated daily. The value tab summarizes usage and cost data to help admins understand value of Claude Code at a glance, estimating productivity lift, cost per commit, and annual value. Every formula is visible in the tab, and the inputs are adjustable.

分析对话（Analytics chat）现在可以回答范围更广的问题，并生成可深入探究的更丰富制品。管理员可以用自然语言提问——比如"哪些团队本月的 Claude 使用量翻倍了？"或"我们在哪里获得了每席位最高的价值？"——Claude 会返回可导出并与相关方分享的图表。

> Analytics chat can now answer a much broader set of questions and produce richer artifacts that you can dive deeper into. Admins can ask questions in plain language — "Which teams doubled their Claude usage this month?" or "Where are we getting the most value per seat?" — and Claude returns charts that can be exported and shared with stakeholders.

使用与成本数据可通过分析 API（Analytics API）以编程方式获取，因此财务和 IT 部门可以将 Claude 的使用和成本数据引入他们已在运行的工具中——比如 Datadog Cloud Cost Management 和 CloudZero——并与其余云和 AI 支出并列查看。结果可按日期范围、团队、产品或模型筛选。技能会报告自身的使用情况和成本，新的端点则跟踪插件采用和制品创建情况。

> Usage and cost data is available programmatically through the Analytics API , so finance and IT can bring Claude usage and cost data into the tools they already run — like Datadog Cloud Cost Management and CloudZero — and see it alongside the rest of their cloud and AI spend. Results can be filtered by date range, team, product, or model. Skills report their own usage and cost, and new endpoints track plugin adoption and artifact creation.

管理员可以将使用情况的可见性延伸到单个用户——成本、产品和模型明细，以及相对于支出上限的进度——这样就不会有人遭遇意外中断。用户也可以查看自己随时间变化的使用趋势，包括自己最依赖哪些产品、模型和技能，以及这些活动如何累加为支出。

> Admins can extend usage visibility to individual users — cost, product and model breakdowns, and progress against spend limits — so no one hits a surprise cutoff. Users can also see their own usage trends over time, including which products, models, and skills they rely on most, and how that activity adds up in spend.

### 管理支出的控制手段

> Controls for managing spend

模型默认值与授权（entitlements）让管理员可以设置聊天、Cowork 和 Claude Code 中新对话默认启动的 Claude 模型，从而使日常工作不必默认使用最昂贵的选项。管理员可以控制哪些模型对特定角色开放，或在整个组织范围内开放。

> Model defaults and entitlements let admins set which Claude model new conversations start with across chat, Cowork, and Claude Code so routine work doesn't necessarily default to the most expensive option. Admins control which models are available to specific roles or across the entire organization.

支出阈值提醒会在达到组织级支出上限的 75% 和 90% 时通知管理员，让他们有时间在任何人任务中途被阻断之前提高上限。用户则会在 75% 和 95% 阈值时收到应用内通知，并可以直接向管理员请求提高上限，无需离开 Claude。

> Spend-threshold alerts notify admins at 75% and 90% of an org-level spend limit, giving them time to raise the cap before anyone gets blocked mid-task. Users receive in-app notifications at 75% and 95% thresholds and can request a limit increase directly from their admin without leaving Claude.

对于需要在多个群组间管理上限的组织，管理员 API（Admin API）将成本控制流程转移到脚本中，使控制手段随组织规模扩展。可以大规模地自动化上限提升请求的审核、识别接近支出上限的成员，并标记使用量快速变化的情况。

> For organizations managing limits across many groups, the Admin API moves cost-control workflows into scripts so controls scale with the org. Automate increase-request reviews, identify members close to their spend limit, and flag rapidly changing usage all at scale.

### 入门

> Getting started

对于在整个组织中管理 Claude 的管理员：可在管理控制台中查看用量与成本明细，按群组设置默认模型和支出上限，并配置支出阈值告警以提前防范超支。用量数据可在管理员仪表盘中查看，分析 API（Analytics API）则可让财务和 IT 部门将相同的指标拉取到现有的报表系统中，点此了解更多。

> For admins managing Claude across their organization: explore usage and cost breakdowns in the admin console, set model defaults and spend limits by group, and configure spend-threshold alerts to stay ahead of overages. Usage data is available in the admin dashboard, and the Analytics API lets finance and IT pull the same metrics into existing reporting systems, learn more here .

## 术语对照

| English | 中文 |
|---|---|
| admin analytics | 管理员分析 |
| spend controls | 支出控制 |
| model-level entitlements | 模型级权限 |
| spend cap | 支出上限 |
| spend-threshold alerts | 支出阈值告警 |
| Analytics API | 分析 API |
| Admin API | 管理员 API |
| SCIM groups | SCIM 群组 |
| model routing | 模型路由 |
| effort controls | 投入度控制 |
| Claude Code | Claude Code |
| connectors | 连接器 |
| cost per commit | 每次提交成本 |
| artifacts | 产物 |
