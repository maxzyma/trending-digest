---
source: claude-blog
source_url: https://claude.com/blog/artifacts-in-claude-code
published_at: 2026-06-18
category: Claude Code
title_en: Claude Code now supports artifacts
title_zh: Claude Code 现已支持工件（Artifacts）
source_intro_paragraphs: 2
source_image_count: 0
---

# Claude Code 现已支持工件（Artifacts）

> 来源：Claude Blog，2026-06-18
> 原文链接：https://claude.com/blog/artifacts-in-claude-code
> 分类：Claude Code

## 导语

将进行中的工作预览为实时、可交互的网页——基于完整的会话上下文构建，并可与团队共享。

## 核心要点

- Claude Code 现可将工作进展捕获为工件（artifact），转化为实时、可共享的可视化页面，包括 PR 讲解、系统说明、仪表盘和发布清单。
- 工件基于完整会话上下文构建，整合代码库、连接器（connectors）和对话本身，无需自行接入数据源或搭建基础设施。
- 工件是会随会话更新而自动刷新的实时页面，每次发布都是同一链接下的新版本，并保留版本历史可随时恢复。
- 每个工件默认仅作者私有，仅限组织内经过身份验证的成员查看，无法公开。
- 管理员可通过组织级开关和基于角色的范围控制访问、设置保留策略，并通过合规 API（compliance API）获得组织范围的可见性。
- 工件以测试版形式向 Claude Team 和企业版（Enterprise）组织开放。

## 中文译文

从今天开始，Claude Code 可以将工作进展捕获为工件（artifact），把 Claude Code 的工作转化为实时、可共享的可视化页面——包括 PR 讲解、系统说明、仪表盘和发布清单——并随会话推进而自我更新。

一个 Claude Code 会话的范围可以从调查事故、重构服务，到分析数月的数据。工件将工作转化为任何人都能打开并探索的网页，比如一个拉取请求（pull request）讲解、一个可筛选和排序的仪表盘，甚至是一个随工作完成而自动填写的发布清单。工件让协作共享工作变得更容易，使团队能花更多时间构建，更少时间沟通状态更新。

### 基于你的会话上下文构建

Claude Code 使用会话的完整上下文来构建工件，包括你的代码库、连接器（connectors）以及对话本身。单个事故页面可以汇集来自你代码的失败测试及其背后的函数、来自已连接监控工具的错误激增，以及来自你刚刚运行会话的根因（root-cause）推理。有了工件，你不需要接入数据源或搭建基础设施。你只需请求一个页面，Claude Code 就会从已有内容中构建它。

### 实时更新的页面

当 Claude Code 更新工件时，已打开的页面会原地刷新，队友会在更新发布的那一刻看到它们。每次发布都是同一链接下的新版本，并带有版本历史，因此你可以随时恢复，而画廊（gallery）则让你浏览和管理你创建的所有工件。

在我们的内部测试中，最常见的用例之一是调试。这些通常类似于：一名工程师在站会前启动了一次事故调查。Claude Code 梳理日志并发布一个工件：一条时间线、可疑提交，以及一张错误率图表。她从页面顶部把链接分享给团队。等到站会开始时，随着调查推进，Claude 已经重新发布了两次，纳入了最新信息。有了工件，团队成员和利益相关者不必"带我们了解一遍代理发现了什么"，因为他们都在看同一个视图、同一份上下文。

### 仅对你的组织私有

每个工件默认仅作者私有。当你准备好时，可以直接从页面与队友和组织共享。工件仅对组织内经过身份验证的成员可见，无法被设为公开。管理员通过组织级开关和基于角色的范围控制来管理访问、设置保留策略，并通过合规 API（compliance API）获得组织范围的可见性。

### 开始使用

向你的会话请求一个工件——或只是请求一些可视化的内容，以下是按角色划分的一些思路：

- 法务 / 开源（Legal / open source）：直接从仓库对每个依赖项进行许可证审计，标记出 copyleft。"构建一个工件，列出每个第三方依赖项及其许可证，标记出任何 copyleft。"

- 隐私（Privacy）：一张数据流图（data-flow map），展示代码中个人数据被收集、存储和记录的位置。"在代码库中追踪我们接触个人数据的位置，整理成一个用于隐私审查的工件。"

- 安全（Security）：链接到确切行的发现，使修复明确无误。"将本次审查中的认证发现构建成一个工件，每条都链接到代码。"

- FinOps / 平台财务（FinOps / platform finance）：从你的基础设施即代码（infrastructure-as-code）映射出云资源和成本驱动因素。"将我们 Terraform 中的云资源映射成一个工件，按服务分组，并标出主要成本驱动因素。"

- 软件工程师（Software engineers）：一个评审者真正能跟上的 PR 或缺陷讲解，从 diff 及其周边代码中提取。"制作一个工件，讲解这个 PR——diff、推理过程，以及我测试了什么。"

- 设计师与前端工程师（Designers & frontend engineers）：一个屏幕的多个 UX 方向，每个都基于你真实的组件构建，因此你选中的那个是可交付的。"给我一个工件，包含这个注册表单的 5 种 UX 变体，基于我们的组件库构建。"

- 资深工程师与架构师（Staff engineers & architects）：一张服务实际如何组合在一起的图，从真实的导入图（import graph）而非白板绘制。"将支付服务如何组合在一起映射成一个工件，从代码中提取。"

- SRE 与值班（SRE & on-call）：一个随调查推进而扩展、并最终成为事后复盘（postmortem）的事故页面。"将这次事故转化为一个工件——时间线、可疑提交、来自我们监控的错误激增——并在我推进时重新发布。"

- 工程经理（Engineering managers）：一个展示实际交付内容的页面，从已合并的 PR 构建。"从 PR 构建一个工件，展示我团队本周合并了什么，按项目分组。"

Claude Code 会构建页面并给你一个链接。在浏览器或桌面应用中打开它，从顶部共享它——更新会自动发布到同一 URL。

### 可用性

工件以测试版（beta）形式向 Claude Team 和企业版（Enterprise）组织开放，可从 Claude Code CLI 和桌面应用使用，页面可在任何浏览器中查看。

立即开始使用 Claude Code。

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
