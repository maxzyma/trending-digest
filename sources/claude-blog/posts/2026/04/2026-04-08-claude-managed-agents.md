---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents
published_at: 2026-04-08
category: Agents
title_en: Claude Managed Agents: get to production 10x faster
title_zh: Claude 托管智能体（Claude Managed Agents）：上线生产速度提升 10 倍
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/N7dx2rn0JbZ9XD74FZoMqOXwJMGjLRb3"
---

# Claude 托管智能体（Claude Managed Agents）：上线生产速度提升 10 倍

> 来源：Claude Blog，2026-04-08
> 原文链接：https://claude.com/blog/claude-managed-agents
> 分类：Agents

## 核心要点

- Claude 托管智能体是一套可组合的 API（composable APIs），用于大规模构建并部署云端托管的智能体。
- 它将经过性能调优的智能体框架（agent harness）与生产级基础设施结合，让项目从原型到上线由数月缩短到数天。
- 平台代为处理沙箱化代码执行、检查点（checkpointing）、凭证管理、范围化权限与端到端追踪等复杂工作。
- 支持可自主运行数小时的长时会话、多智能体协调，以及具备范围化权限、身份管理和执行追踪的可信治理。
- 它专为 Claude 构建，支持基于结果（outcome）的自评迭代工作流；在内部测试中将任务成功率最高提升 10 个百分点。
- Notion、Rakuten、Asana、Vibecode、Sentry 等团队已基于该方案在数天到数周内交付多种生产用例。

## 中文译文

今天，我们推出 Claude 托管智能体（Claude Managed Agents），这是一套用于大规模构建和部署云端托管智能体的可组合 API（composable APIs）。

在此之前，构建智能体意味着要把开发周期耗费在安全基础设施、状态管理、权限控制上，并且每次模型升级都要重做智能体循环（agent loops）。托管智能体将一套经过性能调优的智能体框架（agent harness）与生产级基础设施配对，让你能在数天而非数月内从原型走向上线。

无论你是在构建单任务运行器，还是复杂的多智能体流水线（multi-agent pipelines），都可以专注于用户体验，而不是运维开销。

托管智能体今日已在 Claude 平台（Claude Platform）上以公开测试版（public beta）形式提供。

## 以 10 倍速度构建和部署智能体

交付一个生产级智能体需要沙箱化代码执行（sandboxed code execution）、检查点（checkpointing）、凭证管理、范围化权限（scoped permissions）以及端到端追踪。这意味着在用户看到任何成果之前，要先投入数月的基础设施工作。

托管智能体承担了这些复杂性。你定义智能体的任务、工具和护栏（guardrails），我们在自己的基础设施上运行它。内置的编排框架（orchestration harness）负责决定何时调用工具、如何管理上下文、以及如何从错误中恢复。

托管智能体包含：

- 生产级智能体，安全沙箱、认证和工具执行均已为你处理妥当。

- 长时会话（long-running sessions），可自主运行数小时，即使断开连接，进度和产出也能持久保留。

- 多智能体协调（multi-agent coordination），让智能体可以启动并指挥其他智能体，从而对复杂工作进行并行处理（研究预览版（research preview）阶段提供，可在此申请访问）。

- 可信治理（trusted governance），通过内置的范围化权限、身份管理和执行追踪，让智能体安全访问真实系统。

## 为充分发挥 Claude 而设计

Claude 模型为智能体工作（agentic work）而生。托管智能体专为 Claude 打造，让你以更少的精力获得更好的智能体成果。

借助托管智能体，你定义结果（outcomes）和成功标准，Claude 会自我评估并不断迭代，直到达成目标（研究预览版阶段提供，可在此申请访问）。当你希望更严格地掌控时，它也支持传统的提示-响应（prompt-and-response）工作流。

在围绕结构化文件生成的内部测试中，托管智能体相比标准提示循环将任务成功率最高提升了 10 个百分点，而在最困难的问题上提升幅度最大。

会话追踪、集成分析和故障排查指引都直接内置于 Claude 控制台（Claude Console），让你能够检查每一次工具调用、决策和失败模式。

## 各团队正在构建什么

各团队已经借助托管智能体在一系列生产用例中实现 10 倍速度交付。能读取代码库、规划修复并提交合并请求（PR）的编码智能体；能加入项目、领取任务并与团队其他成员并肩交付工作的生产力智能体；处理文档并提取关键信息的财务与法律智能体。在每个案例中，以天为单位交付意味着更快地为用户创造价值。

- Notion 让团队可以直接在工作区内将工作委派给 Claude（现已在 Notion 自定义智能体（Notion Custom Agents）中以私有内测（private alpha）形式提供）。工程师用它来交付代码，而知识工作者用它来生成网站和演示文稿。数十项任务可以并行运行，整个团队则协作完成产出。

- Rakuten 在产品、销售、市场和财务领域交付了企业级智能体，这些智能体接入 Slack 和 Teams，让员工可以分配任务并取回电子表格、幻灯片和应用等交付物。每个专业智能体都在一周内完成部署。

- Asana 构建了 AI Teammates，这是一种协作型 AI 智能体，在 Asana 项目内与人类并肩工作，承担任务并起草交付物。该团队使用托管智能体添加高级功能的速度，远快于他们原本所能达到的水平。

- Vibecode 把托管智能体作为默认集成，帮助客户从提示直达已部署的应用，为新一代 AI 原生应用提供动力。用户现在搭建同样的基础设施，速度至少比以前快 10 倍。

- Sentry 将其调试智能体 Seer 与一个由 Claude 驱动、负责编写补丁并提交 PR 的智能体配对，使开发者能够在一个流程中从被标记的缺陷走向可供评审的修复。该集成在托管智能体上以数周而非数月的时间完成交付。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| composable APIs | 可组合 API |
| agent harness | 智能体框架 |
| agent loops | 智能体循环 |
| multi-agent pipelines | 多智能体流水线 |
| public beta | 公开测试版 |
| sandboxed code execution | 沙箱化代码执行 |
| checkpointing | 检查点 |
| scoped permissions | 范围化权限 |
| orchestration harness | 编排框架 |
| guardrails | 护栏 |
| long-running sessions | 长时会话 |
| multi-agent coordination | 多智能体协调 |
| research preview | 研究预览版 |
| trusted governance | 可信治理 |
| agentic work | 智能体工作 |
| prompt-and-response | 提示-响应 |
| Claude Console | Claude 控制台 |
| PR (pull request) | 合并请求 |
| private alpha | 私有内测 |
| AI-native apps | AI 原生应用 |
