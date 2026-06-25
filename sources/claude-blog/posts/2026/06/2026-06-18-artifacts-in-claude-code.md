---
source: claude-blog
source_url: https://claude.com/blog/artifacts-in-claude-code
published_at: 2026-06-18
category: Claude Code
title_en: Claude Code now supports artifacts
title_zh: Claude Code 现已支持工件（Artifacts）
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 2
source_image_count: 0
---

# Claude Code 现已支持工件（Artifacts）

> ⌁ Claude Code now supports artifacts

> 来源：Claude Blog，2026-06-18
> 原文链接：https://claude.com/blog/artifacts-in-claude-code
> 分类：Claude Code

## 核心要点

- Claude Code 现可将工作进展捕获为工件（artifact），转化为实时、可共享的可视化页面，包括 PR 讲解、系统说明、仪表盘和发布清单。
- 工件基于完整会话上下文构建，整合代码库、连接器（connectors）和对话本身，无需自行接入数据源或搭建基础设施。
- 工件是会随会话更新而自动刷新的实时页面，每次发布都是同一链接下的新版本，并保留版本历史可随时恢复。
- 每个工件默认仅作者私有，仅限组织内经过身份验证的成员查看，无法公开。
- 管理员可通过组织级开关和基于角色的范围控制访问、设置保留策略，并通过合规 API（compliance API）获得组织范围的可见性。
- 工件以测试版形式向 Claude Team 和企业版（Enterprise）组织开放。

## 正文

将进行中的工作预览为实时、可交互的网页——基于完整的会话上下文构建，并可与团队共享。

> ⌁ Preview your in-progress work as a live, interactive web page—built from your full session context and shareable with your team.

从今天开始，Claude Code 可以将工作进展捕获为制品（artifact），把 Claude Code 的工作变成实时、可分享的可视化页面——包括 PR 走查、系统讲解、仪表盘和发布清单——并随着会话推进自动更新。

> ⌁ Starting today, Claude Code can capture work progress as an artifact, which turn Claude Code's work into live, shareable visual pages— including PR walkthroughs, system explainers, dashboards, and release checklists—that update themselves as your session works.

一次 Claude Code 会话的内容可以多种多样，从排查事故、重构服务，到分析数月的数据。制品会把这些工作转化为任何人都能打开并浏览的网页，比如一次拉取请求（pull request）走查、一个可筛选和排序的仪表盘，甚至是一份随工作完成而自动填写的发布清单。制品让协作共享工作更轻松，团队因此能把更多时间用在构建上，少花时间在沟通状态更新上。

> ⌁ A Claude Code session can range from investigating an incident to refactoring a service to analyzing months of data. Artifacts translate the work into a web page anyone can open and explore, like a pull request walkthrough, a dashboard you can filter and sort, or even a release checklist that fills itself out as work gets done. Artifacts make it easier to collaborate on shared work, so teams can spend more time building and less time communicating status updates.

### 基于会话上下文构建

> Built on the context from your session

Claude Code 会利用会话的完整上下文来构建产物（artifact），包括你的代码库、连接器（connector）以及对话本身。一个事件页面（incident page）就能汇集：来自你代码的失败测试及其背后的函数、来自已连接监控工具的错误激增，以及你刚刚运行的会话中得出的根因推理。借助产物，你无需接入数据源或搭建基础设施。你只需请求一个页面，Claude Code 就会根据已有内容把它构建出来。

> ⌁ Claude Code builds an artifact using the full context of your session, including your codebase, your connectors, and the conversation itself. A single incident page can bring together the failing test and the function behind it from your code, the error spike from a connected monitoring tool, and the root-cause reasoning from the session you just ran. With artifacts, you don't need to wire up data sources or stand up infrastructure. You ask for a page, and Claude Code builds it from what already exists.

### 就地更新的实时页面

> Live pages that update in place

当 Claude Code 更新工件（artifact）时，已打开的页面会就地刷新，团队成员在更新发布的那一刻就能看到。每次发布都是同一链接下的新版本，并带有版本历史，因此你可以随时恢复；图库（gallery）则让你浏览和管理你创建的所有工件。

> ⌁ When Claude Code updates an artifact, the open page refreshes in place and teammates see the updates the moment they’re published. Every publish is a new version at the same link, with version history so you can restore at any time, and a gallery lets you browse and manage all artifacts you've made.

在我们的内部测试中，最常见的用例之一是调试。典型情况大致是这样：一位工程师在站会前启动了一项事故调查。Claude Code 梳理了日志并发布了一份工件：一条时间线、可疑的提交，以及一张错误率图表。她从页面顶栏把链接分享给团队。等到站会开始时，随着调查推进，Claude 已经把它重新发布了两次，纳入了最新信息。有了工件，团队成员和相关方不必再让我们“带着大家过一遍智能体发现了什么”，因为他们看的都是同一个视图、同样的上下文。

> ⌁ From our internal testing, one of our most common use cases has been debugging. These typically look something like: An engineer kicks off an incident investigation before standup. Claude Code works through the logs and publishes an artifact: a timeline, the suspect commits, and an error-rate chart. She shares the link with her team from the page header. By the time standup begins, Claude has republished it twice as the investigation progressed, incorporating the latest information. With artifacts, team members and stakeholders don’t have to "walk us through what the agent found" because they're all looking at the same view, with the same context.

### 组织内部私密

> Private to your organization

每个工件（artifact）默认仅作者本人可见。准备就绪后，你可以直接在页面上将其分享给队友和组织。工件只有经过身份验证的组织成员才能查看，无法公开。管理员通过组织级开关和基于角色的范围控制来管理访问权限，设置留存策略，并通过合规 API 获得组织范围的可见性。

> ⌁ Every artifact is private to its author by default. When you're ready, share it with your teammates and your organization directly from the page. Artifacts are viewable only by authenticated members of your org and cannot be made public. Admins manage access with an org-level toggle and role-based scoping, set retention policies, and get org-wide visibility through the compliance API.

### 开始使用

> Getting started

向你的会话索要一个工件（artifact）——或者直接要求生成可视化内容，以下是按角色划分的一些思路：

> ⌁ Ask your session for an artifact — or just ask for something visual, h ere are some ideas by role:

- 法务／开源：直接从代码仓库出发，对每个依赖项进行许可证审计，标记出 copyleft（左版）许可。"构建一个工件，列出每个第三方依赖项及其许可证，并标记任何 copyleft 许可。"
- 隐私：绘制一张数据流图，呈现代码中个人数据在何处被收集、存储和记录。"在整个代码库中追踪我们接触个人数据的位置，整理成一个工件供隐私审查使用。"
- 安全：将发现的问题链接到确切代码行，使修复方案明确无误。"把本次审查中的认证（auth）相关发现构建成一个工件，每一项都链接到对应代码。"
- 财务运营（FinOps）／平台财务：从你的基础设施即代码（infrastructure-as-code）中梳理出云资源和成本驱动因素。"从 Terraform 中梳理我们的云资源，整理成一个工件，按服务分组，并标出主要成本驱动因素。"
- 软件工程师：从代码差异（diff）及其周边代码中提取，生成一份审查者真正能看懂的 PR 或缺陷讲解。"做一个工件，逐步讲解这个 PR——差异、推理过程以及我测试了什么。"
- 设计师与前端工程师：为某个界面提供多个用户体验（UX）方向，每个都基于你真实的组件构建，因此你选中的方案可以直接上线。"给我一个工件，包含这个注册表单的 5 种 UX 变体，均基于我们的组件库构建。"
- 资深工程师与架构师：根据真实的导入关系图（import graph）而非白板，绘制一个服务实际是如何组合在一起的图谱。"从代码出发，把支付服务是如何组合的绘制成一个工件。"
- 站点可靠性工程师（SRE）与值班人员：一个随调查推进而不断扩充、并最终成为复盘报告的事故页面。"把这次事故整理成一个工件——时间线、可疑提交、来自我们监控的错误激增——并在我处理过程中重新发布。"
- 工程经理：根据已合并的 PR，生成一份真正交付了哪些内容的页面。"从 PR 出发，构建一个工件，呈现我团队本周合并了哪些内容，按项目分组。"

> ⌁ - Legal / open source : A license audit of every dependency, flagging copyleft, straight from the repo. "Build an artifact listing every third-party dependency and its license, flagging anything copyleft."
> - Privacy : A data-flow map of where personal data is collected, stored, and logged across the code. "Trace where we touch personal data across the codebase into an artifact for the privacy review."
> - Security : Findings that link to the exact line, so the fix is unambiguous. "Build an artifact of the auth findings from this review, each linked to the code."
> - FinOps / platform finance : Cloud resources and cost drivers mapped from your infrastructure-as-code. "Map our cloud resources from the Terraform into an artifact, grouped by service, with the big cost drivers."
> - Software engineers : A PR or bug walkthrough reviewers can actually follow, pulled from the diff and the code around it. "Make an artifact walking through this PR — the diff, the reasoning, and what I tested."
> - Designers & frontend engineers : Several UX directions for a screen, each built from your real components so the one you pick is shippable. "Give me an artifact with 5 UX variations of this signup form, built from our component library."
> - Staff engineers & architects : A map of how a service actually fits together, drawn from the real import graph instead of a whiteboard. "Map how the payments service fits together into an artifact, from the code."
> - SRE & on-call : An incident page that grows as you investigate and becomes the postmortem. "Turn this incident into an artifact — timeline, suspect commits, error spike from our monitoring — and republish as I work through it."
> - Engineering managers : A page of what actually shipped, built from the merged PRs. "Build an artifact of what merged on my team this week from the PRs, grouped by project."

Claude Code 会构建该页面并给你一个链接。在浏览器或桌面应用中打开它，从页眉处分享——更新会自动发布到同一个 URL。

> ⌁ Claude Code builds the page and gives you a link. Open it in your browser or the desktop app, share it from the header—updates publish to the same URL automatically.

### 可用性

> Availability

Artifacts 目前以测试版（beta）形式向 Claude Team 和 Enterprise 组织开放，可在 Claude Code 命令行工具（CLI）和桌面应用中使用，生成的页面可在任意浏览器中查看。

> ⌁ Artifacts is available in beta to Claude Team and Enterprise orgs, from the Claude Code CLI and desktop app, with pages viewable in any browser.

立即通过 Claude Code 开始使用。

> ⌁ Get started today with Claude Code.

## 术语对照

| English | 中文 |
|---|---|
| artifact | 工件 |
| pull request (PR) | 拉取请求 |
| connector | 连接器 |
| dashboard | 仪表盘 |
| release checklist | 发布清单 |
| root-cause | 根因 |
| version history | 版本历史 |
| gallery | 画廊 |
| standup | 站会 |
| postmortem | 事后复盘 |
| compliance API | 合规 API |
| copyleft | copyleft |
| data-flow map | 数据流图 |
| infrastructure-as-code | 基础设施即代码 |
| import graph | 导入图 |
| Enterprise | 企业版 |
| beta | 测试版 |
