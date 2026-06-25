---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents
published_at: 2026-04-08
category: Agents
title_en: Claude Managed Agents: get to production 10x faster
title_zh: Claude 托管智能体（Claude Managed Agents）：上线速度提升 10 倍
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 4
source_image_count: 1
---

# Claude 托管智能体（Claude Managed Agents）：上线速度提升 10 倍

> ⌁ Claude Managed Agents: get to production 10x faster

> 来源：Claude Blog，2026-04-08
> 原文链接：https://claude.com/blog/claude-managed-agents
> 分类：Agents

## 核心要点

- Claude 托管智能体是一套可组合的 API，将经过性能调优的智能体框架（agent harness）与生产级基础设施结合，让原型上线时间从数月缩短到数天。
- 平台代为处理沙箱化代码执行、检查点（checkpointing）、凭据管理、范围化权限和端到端追踪等复杂工作。
- 内置编排框架负责决定何时调用工具、如何管理上下文以及如何从错误中恢复。
- 支持长时运行会话、多智能体协同，以及具备范围化权限、身份管理和执行追踪的可信治理。
- 专为 Claude 打造：你定义结果和成功标准，Claude 自我评估并迭代；在结构化文件生成测试中，任务成功率较标准提示循环最高提升 10 个百分点。
- Notion、乐天（Rakuten）、Asana、Vibecode、Sentry 等团队已借助该平台实现 10 倍的上线提速。
- 该功能现已在 Claude 平台以公开测试版（public beta）提供。

## 正文

今天，我们推出 Claude 托管智能体（Claude Managed Agents），这是一套可组合的 API，用于大规模构建和部署云托管智能体（cloud-hosted agents）。

> ⌁ Today, we're launching Claude Managed Agents, a suite of composable APIs for building and deploying cloud-hosted agents at scale.

今天，我们推出 Claude 托管智能体（Claude Managed Agents），这是一套可组合的 API，用于大规模构建和部署云托管智能体。

> ⌁ Today, we're launching Claude Managed Agents, a suite of composable APIs for building and deploying cloud-hosted agents at scale.

到目前为止，构建智能体意味着要把开发周期花在安全基础设施、状态管理、权限控制上，并为每次模型升级重新调整你的智能体循环（agent loop）。托管智能体将一套针对性能调优的智能体框架（harness）与生产级基础设施结合起来，让你能在数天而非数月内从原型走向上线。

> ⌁ Until now, building agents meant spending development cycles on secure infrastructure, state management, permissioning, and reworking your agent loops for every model upgrade. Managed Agents pairs an agent harness tuned for performance with production infrastructure to go from prototype to launch in days rather than months.

无论你构建的是单任务运行器，还是复杂的多智能体流水线，你都可以专注于用户体验，而不是运维开销。

> ⌁ Whether you're building single-task runners or complex multi-agent pipelines, you can focus on the user experience, not the operational overhead.

托管智能体即日起在 Claude 平台上以公开测试版（public beta）形式提供。

> ⌁ Managed Agents is available today in public beta on the Claude Platform.

### 更快地构建和部署智能体，效率提升 10 倍

> Build and deploy agents 10x faster

交付一个生产级智能体需要沙箱化代码执行、检查点（checkpointing）、凭证管理、范围化权限以及端到端追踪。这意味着在用户能看到任何成果之前，要先做好几个月的基础设施工作。

> ⌁ Shipping a production agent requires sandboxed code execution, checkpointing, credential management, scoped permissions, and end-to-end tracing. That's months of infrastructure work before you ship anything users see.

托管智能体（Managed Agents）来处理这些复杂性。你定义智能体的任务、工具和护栏（guardrails），我们在我们的基础设施上运行它。内置的编排框架（orchestration harness）会决定何时调用工具、如何管理上下文，以及如何从错误中恢复。

> ⌁ Managed Agents handles the complexity. You define your agent's tasks, tools, and guardrails and we run it on our infrastructure. A built-in orchestration harness decides when to call tools, how to manage context, and how to recover from errors.

托管智能体包括：

> ⌁ Managed Agents includes:

- 生产级智能体，安全沙箱、身份验证和工具执行都已为你处理妥当。
- 长时间运行的会话，可自主运行数小时，进度和输出即使在断连情况下也能持久保留。
- 多智能体协调，让智能体能够启动并指挥其他智能体，从而并行处理复杂工作（研究预览版，可在此申请访问）。
- 可信治理，让智能体以范围化权限访问真实系统，内置身份管理和执行追踪。

> ⌁ - Production-grade agents with secure sandboxing, authentication, and tool execution handled for you.
> - Long-running sessions that operate autonomously for hours, with progress and outputs that persist even through disconnections.
> - Multi-agent coordination so agents can spin up and direct other agents to parallelize complex work (available in research preview , request access here ). ‍
> - Trusted governance, giving agents access to real systems with scoped permissions, identity management, and execution tracing built in.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69d53a1b570fa207204f0111_Claude-Blog-Managed-Agents-Diagram-NoBorder.png)

### 充分发挥 Claude 能力的设计

> Designed to make the most of Claude

Claude 模型专为智能体（agentic）工作打造。托管智能体（Managed Agents）专为 Claude 设计，让你用更少的精力获得更好的智能体成果。

> ⌁ Claude models are built for agentic work. Managed Agents is purpose-built for Claude, enabling you to get better agent outcomes with less effort.

使用托管智能体时，你定义成果和成功标准，Claude 会自我评估并不断迭代，直至达成目标（现以研究预览形式提供，可在此申请访问）。当你希望更严格地控制时，它也支持传统的提示-响应（prompt-and-response）工作流。

> ⌁ With Managed Agents, you define outcomes and success criteria, and Claude self-evaluates and iterates until it gets there (available in research preview , request access here ). It also supports traditional prompt-and-response workflows when you want tighter control.

在围绕结构化文件生成的内部测试中，托管智能体相比标准提示循环将成果任务成功率提升了最多 10 个百分点，其中在最难的问题上提升最大。

> ⌁ In internal testing around structured file generation, Managed Agents improved outcome task success by up to 10 points over a standard prompting loop, with the largest gains on the hardest problems.

会话追踪、集成分析和故障排查指引都直接内置于 Claude 控制台（Claude Console），因此你可以检查每一次工具调用、决策和失败模式。

> ⌁ Session tracing, integration analytics, and troubleshooting guidance are built directly into the Claude Console, so you can inspect every tool call, decision, and failure mode.

### 团队正在构建什么

> What teams are building

团队已经在借助托管智能体（Managed Agents）在各类生产场景中以快 10 倍的速度交付。包括：读取代码库、规划修复方案并提交合并请求（PR）的编码智能体；加入项目、领取任务并与团队其余成员一同交付工作的生产力智能体；处理文档并提取关键信息的财务与法务智能体。在每个案例中，以天为单位交付意味着更快地为用户带来价值。

> ⌁ Teams are already shipping 10x faster with Managed Agents across a range of production use cases. Coding agents that read a codebase, plan a fix, and open a PR. Productivity agents that join a project, pick up tasks, and deliver work alongside the rest of the team. Finance and legal agents that process documents and extract what matters. In each case, shipping in days meant providing value to users faster.

- Notion 让团队可以直接在工作区内把工作委派给 Claude（现已在 Notion 自定义智能体内以私有 alpha 形式提供）。工程师用它来交付代码，知识工作者用它来生成网站和演示文稿。在整个团队协作处理产出时，可以并行运行数十个任务。
- Rakuten 在产品、销售、营销和财务等部门交付了企业级智能体，这些智能体接入 Slack 和 Teams，让员工可以分派任务并拿回电子表格、幻灯片和应用等交付物。每个专精智能体都在一周内完成部署。
- Asana 构建了 AI 队友（AI Teammates），这是在 Asana 项目内与人类协同工作的协作型 AI 智能体，会承担任务并起草交付物。该团队借助托管智能体添加高级功能的速度，远快于其他方式所能达到的程度。
- Vibecode 把托管智能体作为默认集成，帮助其客户从提示词一路走到已部署的应用，为新一代 AI 原生应用提供支撑。用户现在搭建同样的基础设施至少比以前快 10 倍。
- Sentry 将其调试智能体 Seer 与一个由 Claude 驱动、负责编写补丁并提交 PR 的智能体配对，使开发者能在一个流程中从被标记的缺陷走到可供评审的修复。该集成在托管智能体上以数周而非数月的时间完成交付。

> ⌁ - Notion lets teams delegate work to Claude directly inside their workspace (available now in private alpha inside Notion Custom Agents). Engineers use it to ship code, while knowledge workers use it to produce websites and presentations. Dozens of tasks can run in parallel while the whole team collaborates on the output.
> - Rakuten shipped enterprise agents across product, sales, marketing and finance that plug into Slack and Teams, letting employees assign tasks and get back deliverables like spreadsheets, slides, and apps. Each specialist agent was deployed within a week.
> - Asana built AI Teammates, collaborative AI agents that work alongside humans inside Asana projects, taking on tasks and drafting deliverables. The team used Managed Agents to add advanced features dramatically faster than they would have been able to otherwise.
> - Vibecode helps their customers go from prompt to deployed app using Managed Agents as the default integration, powering a new generation of AI-native apps. Users can now spin up that same infrastructure at least 10x quicker than before. ‍
> - Sentry paired Seer, their debugging agent, with a Claude-powered agent that writes the patch and opens the PR, so developers go from a flagged bug to a reviewable fix in one flow. The integration shipped in weeks instead of months on Managed Agents.

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
