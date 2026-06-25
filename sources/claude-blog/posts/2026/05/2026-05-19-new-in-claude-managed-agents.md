---
source: claude-blog
source_url: https://claude.com/blog/new-in-claude-managed-agents
published_at: 2026-05-19
category: Agents
title_en: New in Claude Managed Agents: dreaming, outcomes, and multiagent orchestration
title_zh: Claude Managed Agents 新功能：做梦、结果导向与多智能体编排
source_intro_paragraphs: 1
source_image_count: 2
---

# Claude Managed Agents 新功能：做梦、结果导向与多智能体编排

> 来源：Claude Blog，2026-05-19
> 原文链接：https://claude.com/blog/new-in-claude-managed-agents
> 分类：Agents

## 导语

今天，我们以研究预览（research preview）的形式推出 Claude Managed Agents 中的"做梦"（dreaming）功能。做梦通过回顾过去的会话来发现模式，并帮助智能体实现自我改进，从而扩展了记忆能力。我们还向使用 Managed Agents 进行开发的开发者开放了结果（outcomes）、多智能体编排（multiagent orchestration）以及 Webhook。这些更新共同让智能体能够在最少引导下处理复杂任务。

## 核心要点

- 做梦（dreaming）是一项定时流程，回顾智能体会话与记忆库，提炼模式并整理记忆，帮助智能体随时间持续自我改进。
- 记忆与做梦共同构成自我改进智能体的稳健记忆系统：记忆捕捉每个智能体在工作中所学，做梦在会话之间精炼这些记忆。
- 结果（outcomes）让你撰写评分标准（rubric），由独立的评分器（grader）在自己的上下文窗口中评估输出，智能体可据此自我纠正，无需人工逐次审查。
- 在测试中，结果功能将任务成功率较标准提示循环最高提升 10 个百分点，并提升了文件生成质量。
- 多智能体编排让主智能体（lead agent）将任务拆分并委派给各具模型、提示与工具的专家智能体，可并行协作。
- Harvey、Netflix、Spiral by Every、Wisedocs 等团队正利用这些功能构建可自我验证、跨会话学习并并行处理复杂任务的智能体。

## 中文译文

今天，我们以研究预览（research preview）的形式推出 Claude Managed Agents 中的"做梦"（dreaming）功能。做梦通过回顾过去的会话来发现模式，并帮助智能体实现自我改进，从而扩展了记忆能力。我们还向使用 Managed Agents 进行开发的开发者开放了结果（outcomes）、多智能体编排（multiagent orchestration）以及 Webhook。这些更新共同让智能体能够在最少引导下处理复杂任务。

### 用做梦构建自我改进的智能体

做梦是一项定时流程，它回顾你的智能体会话与记忆库，提炼模式，并整理记忆，使你的智能体随时间不断改进。你可以决定希望保留多少控制权：做梦既可以自动更新记忆，你也可以在变更落地前先行审查。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69f8e9ad765c7eed52dcf468_Claude-Managed-Agents-Blog-Followup-Dreaming.png)

做梦能够揭示单个智能体自身无法看到的模式，包括反复出现的错误、智能体趋于一致采用的工作流，以及团队内部共享的偏好。它还会重构记忆，使其在演进过程中始终保持高信息量。这对于长期运行的工作以及多智能体编排尤为有用。

记忆与做梦共同构成了一套面向自我改进智能体的稳健记忆系统。记忆让每个智能体在工作时捕捉自己所学到的内容。做梦则在会话之间精炼这些记忆，汇集跨智能体的共享经验，并使其保持最新。

做梦已在 Claude Platform 上的 Managed Agents 中提供；开发者可在此申请访问权限。

### 交付更优结果

借助结果（outcomes），你编写一份评分标准（rubric）来描述成功是什么样子，智能体则朝此目标努力。一个独立的评分器（grader）会在其自己的上下文窗口中，依据你的标准评估输出，因此不会受到智能体推理过程的影响。当某处不符合要求时，评分器会精确指出需要修改之处，智能体随即再做一遍。

当智能体清楚"好"是什么样子时，它们能发挥出最佳水平。例如，一个结构框架、一项演示标准，或一组需要满足的要求。借助结果，智能体可以对照这一标准检查自己的工作并自我纠正，直到输出足够好，而无需人工审查每一次尝试。

结果功能对于那些需要关注细节并做到详尽覆盖的任务尤为有用。它同样适用于主观质量，例如文案是否契合品牌语气，或设计是否遵循视觉规范。在测试中，结果功能将任务成功率较标准提示循环最高提升了 10 个百分点，且在最困难的问题上提升最为显著。结果还提升了文件生成质量，在我们的内部基准测试中，docx 任务成功率提升 +8.4%，pptx 提升 +10.1%。

你现在还可以定义一个结果，让智能体运行，并在其完成时通过 Webhook 收到通知。

### 用多个智能体处理复杂任务

当工作量太大、单个智能体难以胜任时，多智能体编排让主智能体（lead agent）将任务拆分成若干部分，并将每一部分委派给一位拥有自身模型、提示与工具的专家。例如，主智能体可以执行一项调查，同时子智能体（subagent）分头深入部署历史、错误日志、指标以及支持工单。

这些专家在共享文件系统上并行工作，并为主智能体的整体上下文做出贡献。由于事件是持久化的，且每个智能体都记得自己做过什么，主智能体可以在工作流进行中重新与其他智能体沟通确认。你还可以在 Claude Console 中追踪每一个步骤：哪个智能体做了什么、按何种顺序、出于何种原因，从而让你对任务如何被委派和执行拥有完整的可见性。

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69f8ea208aefcf18345ee3ef_Claude-Managed-Agents-Blog-Followup-Sessions-UI.png)

### 团队正在构建什么

各团队正利用做梦、结果与多智能体编排，交付能够验证自身工作、跨会话学习并并行处理复杂任务的智能体：

- Harvey 使用 Managed Agents 来协调诸如长篇起草与文档创作等复杂的法律工作。借助做梦，他们的智能体能够记住在会话之间所学到的内容，包括文件类型的变通方法以及特定工具的模式。在他们的测试中，完成率提升了约 6 倍。

- Netflix 的平台团队构建了一个分析智能体，用于处理来自不同来源、数百次构建的日志。在影响数千个应用的变更中，重要的是找出那些在众多应用中反复出现的问题。多智能体编排让该智能体能够并行分析批次，并只呈现值得采取行动的模式。

- Every 旗下的 Spiral 正使用多智能体编排与结果，为其新的 API 和 CLI 背后的写作智能体提供动力。主智能体运行在 Haiku 上：它接收传入请求，必要时提出快速的跟进问题，然后将起草工作委派给运行在 Opus 上的子智能体。当用户要求多份草稿时，子智能体会并行运行。写作质量是 Spiral 的核心价值，因此他们使用结果来确保这一点。每份草稿都会依据一套评分标准进行打分，该标准融合了 Every 的编辑原则与用户的语气，两者皆从记忆中调取。只有达到标准的草稿才会被返回。

- Wisedocs 在 Managed Agents 上构建了一个文档质量检查智能体，使用结果依据其内部准则为每次审查打分。审查现在的运行速度快了 50%，同时仍与团队的标准保持一致。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| dreaming | 做梦 |
| outcomes | 结果 |
| multiagent orchestration | 多智能体编排 |
| webhook | Webhook |
| research preview | 研究预览 |
| memory store | 记忆库 |
| rubric | 评分标准 |
| grader | 评分器 |
| context window | 上下文窗口 |
| lead agent | 主智能体 |
| subagent | 子智能体 |
| filesystem | 文件系统 |
| Claude Console | Claude 控制台 |
| Claude Platform | Claude 平台 |
| completion rate | 完成率 |
| task success | 任务成功率 |
