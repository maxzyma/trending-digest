---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents
published_at: 2026-04-08
category: Agents
title_en: Claude Managed Agents: get to production 10x faster
title_zh: Claude 托管智能体（Claude Managed Agents）：上线速度提升 10 倍
source_intro_paragraphs: 4
source_image_count: 1
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/7NkDwLng8ZM3voXGiNdqxD0aJKMEvZBY"
---

# Claude 托管智能体（Claude Managed Agents）：上线速度提升 10 倍

> 来源：Claude Blog，2026-04-08
> 原文链接：https://claude.com/blog/claude-managed-agents
> 分类：Agents

## 导语

今天，我们推出 Claude 托管智能体（Claude Managed Agents），这是一套可组合的 API，用于大规模构建和部署云托管智能体（cloud-hosted agents）。

## 核心要点

- Claude 托管智能体是一套可组合的 API，将经过性能调优的智能体框架（agent harness）与生产级基础设施结合，让原型上线时间从数月缩短到数天。
- 平台代为处理沙箱化代码执行、检查点（checkpointing）、凭据管理、范围化权限和端到端追踪等复杂工作。
- 内置编排框架负责决定何时调用工具、如何管理上下文以及如何从错误中恢复。
- 支持长时运行会话、多智能体协同，以及具备范围化权限、身份管理和执行追踪的可信治理。
- 专为 Claude 打造：你定义结果和成功标准，Claude 自我评估并迭代；在结构化文件生成测试中，任务成功率较标准提示循环最高提升 10 个百分点。
- Notion、乐天（Rakuten）、Asana、Vibecode、Sentry 等团队已借助该平台实现 10 倍的上线提速。
- 该功能现已在 Claude 平台以公开测试版（public beta）提供。

## 中文译文

今天，我们推出 Claude 托管智能体（Claude Managed Agents），这是一套可组合的 API，用于大规模构建和部署云托管智能体（cloud-hosted agents）。

在此之前，构建智能体意味着要把开发周期花在安全基础设施、状态管理、权限控制上，并且每次模型升级都要重做智能体循环（agent loop）。托管智能体将一套经过性能调优的智能体框架（agent harness）与生产级基础设施配对，让你从原型到上线只需数天而非数月。

无论你是在构建单任务执行器，还是复杂的多智能体流水线（multi-agent pipeline），你都可以专注于用户体验，而非运维开销。

托管智能体现已在 Claude 平台以公开测试版（public beta）形式提供。

### 构建并部署智能体的速度提升 10 倍

交付一个生产级智能体需要沙箱化代码执行、检查点（checkpointing）、凭据管理、范围化权限以及端到端追踪。这意味着在用户看到任何东西之前，要先完成数月的基础设施工作。

托管智能体替你处理这些复杂性。你定义智能体的任务、工具和护栏（guardrails），我们在自己的基础设施上运行它。内置的编排框架（orchestration harness）会决定何时调用工具、如何管理上下文，以及如何从错误中恢复。

托管智能体包含：

- **生产级智能体**，安全沙箱、身份验证和工具执行均由我们代为处理。

- **长时运行会话**，可自主运行数小时，进度和输出即使在连接中断时也能持续保留。

- **多智能体协同（multi-agent coordination）**，让智能体能够启动并指挥其他智能体，从而并行处理复杂工作（处于研究预览阶段，可在此申请访问）。

- **可信治理（trusted governance）**，让智能体在内置的范围化权限、身份管理和执行追踪下访问真实系统。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69d53a1b570fa207204f0111_Claude-Blog-Managed-Agents-Diagram-NoBorder.png)

### 为充分发挥 Claude 而设计

Claude 模型为智能体工作（agentic work）而生。托管智能体专为 Claude 打造，让你以更少的投入获得更好的智能体成果。

借助托管智能体，你定义结果和成功标准，Claude 会自我评估并迭代，直到达成目标（处于研究预览阶段，可在此申请访问）。当你想要更严格的控制时，它也支持传统的提示—响应（prompt-and-response）工作流。

在围绕结构化文件生成的内部测试中，托管智能体相较标准提示循环将任务成功率最高提升了 10 个百分点，且在最难的问题上提升最大。

会话追踪、集成分析和故障排查指引直接内置于 Claude 控制台（Claude Console），因此你可以检查每一次工具调用、决策和失败模式。

### 团队正在构建什么

团队们已经在一系列生产用例中借助托管智能体实现了 10 倍的上线提速。能够读取代码库、规划修复并发起 PR 的编程智能体；能够加入项目、领取任务并与团队其他成员并肩交付工作的生产力智能体；处理文档并提取关键信息的财务与法务智能体。在每个案例中，几天内即可上线意味着更快地为用户提供价值。

- **Notion** 让团队可以直接在工作区内将工作委派给 Claude（现已在 Notion Custom Agents 中以私有内测版提供）。工程师用它交付代码，知识工作者用它制作网站和演示文稿。数十个任务可以并行运行，整个团队同时协作处理产出。

- **乐天（Rakuten）** 在产品、销售、营销和财务领域交付了企业级智能体，这些智能体接入 Slack 和 Teams，让员工可以分派任务并取回电子表格、幻灯片和应用等成果。每个专业智能体都在一周内完成部署。

- **Asana** 构建了 AI 队友（AI Teammates），这是一种在 Asana 项目内与人类并肩工作的协作式 AI 智能体，承担任务并起草交付物。该团队使用托管智能体添加高级功能的速度远超此前所能达到的水平。

- **Vibecode** 帮助其客户将提示转化为已部署的应用，并将托管智能体作为默认集成，为新一代 AI 原生应用提供支撑。用户现在搭建相同基础设施的速度比以往至少快 10 倍。

- **Sentry** 将其调试智能体 Seer 与一个由 Claude 驱动、负责编写补丁并发起 PR 的智能体配对，使开发者能够在一个流程中从被标记的 bug 走到可供评审的修复。该集成在托管智能体上以数周而非数月完成交付。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| composable APIs | 可组合的 API |
| cloud-hosted agents | 云托管智能体 |
| agent harness | 智能体框架 |
| agent loop | 智能体循环 |
| multi-agent pipeline | 多智能体流水线 |
| public beta | 公开测试版 |
| checkpointing | 检查点 |
| scoped permissions | 范围化权限 |
| guardrails | 护栏 |
| orchestration harness | 编排框架 |
| multi-agent coordination | 多智能体协同 |
| trusted governance | 可信治理 |
| research preview | 研究预览 |
| agentic work | 智能体工作 |
| prompt-and-response | 提示—响应 |
| Claude Console | Claude 控制台 |
| AI Teammates | AI 队友 |
| PR (pull request) | PR（拉取请求） |
