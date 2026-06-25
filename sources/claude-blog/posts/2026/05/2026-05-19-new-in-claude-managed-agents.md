---
source: claude-blog
source_url: https://claude.com/blog/new-in-claude-managed-agents
published_at: 2026-05-19
category: Agents
title_en: New in Claude Managed Agents: dreaming, outcomes, and multiagent orchestration
title_zh: Claude Managed Agents 新功能：做梦、结果导向与多智能体编排
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 1
source_image_count: 2
---

# Claude Managed Agents 新功能：做梦、结果导向与多智能体编排

> • New in Claude Managed Agents: dreaming, outcomes, and multiagent orchestration

> • 来源：Claude Blog，2026-05-19
> • 原文链接：https://claude.com/blog/new-in-claude-managed-agents
> • 分类：Agents

## 核心要点

- 做梦（dreaming）是一项定时流程，回顾智能体会话与记忆库，提炼模式并整理记忆，帮助智能体随时间持续自我改进。
- 记忆与做梦共同构成自我改进智能体的稳健记忆系统：记忆捕捉每个智能体在工作中所学，做梦在会话之间精炼这些记忆。
- 结果（outcomes）让你撰写评分标准（rubric），由独立的评分器（grader）在自己的上下文窗口中评估输出，智能体可据此自我纠正，无需人工逐次审查。
- 在测试中，结果功能将任务成功率较标准提示循环最高提升 10 个百分点，并提升了文件生成质量。
- 多智能体编排让主智能体（lead agent）将任务拆分并委派给各具模型、提示与工具的专家智能体，可并行协作。
- Harvey、Netflix、Spiral by Every、Wisedocs 等团队正利用这些功能构建可自我验证、跨会话学习并并行处理复杂任务的智能体。

## 正文

今天，我们以研究预览（research preview）的形式推出 Claude Managed Agents 中的"做梦"（dreaming）功能。做梦通过回顾过去的会话来发现模式，并帮助智能体实现自我改进，从而扩展了记忆能力。我们还向使用 Managed Agents 进行开发的开发者开放了结果（outcomes）、多智能体编排（multiagent orchestration）以及 Webhook。这些更新共同让智能体能够在最少引导下处理复杂任务。

> Today we're launching dreaming in Claude Managed Agents as a research preview. Dreaming extends memory by reviewing past sessions to find patterns and help agents self-improve. We're also making outcomes, multiagent orchestration, and webhooks available to developers building with Managed Agents. Together, these updates make agents more capable at handling complex tasks with minimal steering.

今天我们以研究预览（research preview）形式推出 Claude 托管智能体（Claude Managed Agents）中的"做梦"（dreaming）功能。做梦通过回顾过往会话来发现模式，从而扩展记忆并帮助智能体自我改进。我们还向使用托管智能体构建应用的开发者开放了成果（outcomes）、多智能体编排（multiagent orchestration）和网络钩子（webhooks）。这些更新合在一起，让智能体能够在极少人工引导的情况下更好地处理复杂任务。

> Today we're launching dreaming in Claude Managed Agents as a research preview. Dreaming extends memory by reviewing past sessions to find patterns and help agents self-improve. We're also making outcomes, multiagent orchestration, and webhooks available to developers building with Managed Agents. Together, these updates make agents more capable at handling complex tasks with minimal steering.

### 用「梦境」构建自我改进的智能体

> Build self-improving agents with dreaming

梦境（dreaming）是一个定期运行的流程，它会回顾你的智能体会话与记忆存储，提取模式，并整理记忆，让你的智能体随时间不断改进。你可以决定希望拥有多大的控制权：梦境既可以自动更新记忆，也可以让你在改动落地前先行审核。

> Dreaming is a scheduled process that reviews your agent sessions and memory stores, extracts patterns, and curates memories so your agents improve over time. You decide how much control you want: dreaming can update memory automatically, or you can review changes before they land.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69f8e9ad765c7eed52dcf468_Claude-Managed-Agents-Blog-Followup-Dreaming.png)

梦境能揭示单个智能体自身无法察觉的模式，包括反复出现的错误、智能体趋同形成的工作流，以及团队成员共享的偏好。它还会重新组织记忆结构，使其在演进过程中始终保持高信噪比。这对长时间运行的工作以及多智能体编排尤其有用。

> Dreaming surfaces patterns that a single agent can’t see on its own, including recurring mistakes, workflows that agents converge on, and preferences shared across a team. It also restructures memory so it stays high-signal as it evolves. This is especially useful for long-running work and multiagent orchestration.

记忆与梦境共同构成了面向自我改进智能体的稳健记忆系统。记忆让每个智能体在工作过程中捕捉它所学到的东西。梦境则在会话之间精炼这些记忆，汇集各智能体之间的共享经验，并保持其时效性。

> Together, memory and dreaming form a robust memory system for self-improving agents. Memory lets each agent capture what it learns as it works . Dreaming refines that memory between sessions , pulling shared learnings across agents and keeping it up-to-date.

梦境已在 Claude 平台（Claude Platform）的托管智能体（Managed Agents）中提供；开发者可在此申请使用权限。

> Dreaming is available in Managed Agents on the Claude Platform; developers can request access here .

### 交付更优结果

> Deliver better outcomes

使用结果（outcomes），你需要编写一份评分标准（rubric）来描述成功的样子，智能体（agent）则朝着这一目标推进。一个独立的评分器（grader）在自己的上下文窗口中根据你的标准评估输出，因此不会受到智能体推理过程的影响。当某处不对时，评分器会精确指出需要修改的地方，智能体便再尝试一次。

> With outcomes , you write a rubric describing what success looks like and the agent works toward it. A separate grader evaluates the output against your criteria in its own context window, so it isn't influenced by the agent's reasoning. When something isn't right, the grader pinpoints what needs to change and the agent takes another pass.

当智能体知道"好"是什么样子时，它们能发挥出最佳水平。例如一套结构框架、一项演示规范，或一组需要满足的要求。借助结果，智能体可以对照这一标准检查自己的工作并自我修正，直到输出足够好，无需人工审查每一次尝试。

> Agents do their best work when they know what "good" looks like. For example, a structural framework, a presentation standard, or a set of requirements that need to be met. With outcomes, agents can check their work against that bar and self-correct until the output is good enough, without a human needing to review each attempt.

结果对于需要注重细节和详尽覆盖的任务尤其有用。它也适用于主观质量，比如文案是否符合品牌调性，或设计是否遵循视觉规范。在测试中，相比标准的提示循环，结果将任务成功率提升了最多 10 个百分点，在最难的问题上提升幅度最大。结果还提升了文件生成质量，在我们的内部基准测试中，docx 任务成功率提升 8.4%，pptx 提升 10.1%。

> Outcomes is particularly useful for tasks that require attention to detail and exhaustive coverage. It also works for subjective quality, like whether copy matches a brand voice or a design follows visual guidelines. In testing, outcomes improved task success by up to 10 points over a standard prompting loop, with the largest gains on the hardest problems. Outcomes also improved file generation quality, with +8.4% task success on docx and +10.1% on pptx in our internal benchmarks.

现在你还可以定义一个结果，让智能体运行，并在完成时通过网络钩子（webhook）收到通知。

> You can also now define an outcome, let the agent run, and get notified by a webhook when it's done.

### 用多个智能体处理复杂任务

> Handle complex tasks with multiple agents

当工作量太大、单个智能体难以做好时，多智能体编排（multiagent orchestration）让主智能体把任务拆成若干部分，并将每一部分交给拥有各自模型、提示词和工具的专职智能体。例如，主智能体可以开展一次排查，同时多个子智能体分头梳理部署历史、错误日志、指标和支持工单。

> When there is too much work for a single agent to do well, multiagent orchestration lets a lead agent break the job into pieces and delegate each one to a specialist with its own model, prompt, and tools. For example, a lead agent can run an investigation while subagents fan out through deploy history, error logs, metrics, and support tickets.

这些专职智能体在共享文件系统上并行工作，并向主智能体的整体上下文汇入成果。由于事件是持久化的、且每个智能体都记得自己做过什么，主智能体可以在工作流进行中随时与其他智能体核对。你还能在 Claude 控制台（Claude Console）中追踪每一步：哪个智能体做了什么、按什么顺序、出于什么原因，从而完整掌握任务是如何被委派和执行的。

> These specialists work in parallel on a shared filesystem and contribute to the lead agent's overall context. The lead agent can check back in with other agents mid-workflow because events are persistent and every agent remembers what it's done. You can also trace every step in the Claude Console : which agent did what, in what order, and why, giving you full visibility into how your task was delegated and executed.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69f8ea208aefcf18345ee3ef_Claude-Managed-Agents-Blog-Followup-Sessions-UI.png)

### 团队正在构建什么

> What teams are building

团队正在使用做梦（dreaming）、结果评估（outcomes）和多智能体编排（multiagent orchestration）来交付能够自我验证工作、跨会话学习并行处理复杂任务的智能体：

> Teams are using dreaming, outcomes, and multiagent orchestration to ship agents that verify their own work, learn across sessions, and parallelize complex jobs:

- Harvey 使用托管智能体（Managed Agents）来协调长篇起草和文档创建等复杂的法律工作。借助做梦能力，他们的智能体能记住会话之间学到的内容，包括文件类型的变通方案和特定工具的模式。在他们的测试中，完成率提升了约 6 倍。
- Netflix 的平台团队构建了一个分析智能体，处理来自不同来源的数百次构建的日志。当变更影响到数千个应用时，关键在于找出在其中许多应用上反复出现的问题。多智能体编排让该智能体能够并行分析多个批次，只呈现值得采取行动的模式。
- Every 旗下的 Spiral 使用多智能体编排和结果评估，为其新 API 和命令行工具（CLI）背后的写作智能体提供支持。主智能体运行在 Haiku 上：它接收传入的请求，必要时提出快速的追问，然后将起草工作委派给运行在 Opus 上的子智能体。当用户要求多份草稿时，子智能体会并行运行。写作质量是 Spiral 的核心价值，因此他们用结果评估来保障它。每份草稿都会对照一套评分标准打分，这套标准结合了 Every 的编辑原则和用户的语言风格，两者都从记忆中调取。只有达标的草稿才会被返回。
- Wisedocs 在托管智能体上构建了一个文档质量检查智能体，利用结果评估对照其内部准则为每次审查打分。如今审查速度提升了 50%，同时仍与团队标准保持一致。

> • Harvey uses Managed Agents to coordinate complex legal work like long-form drafting and document creation. With dreaming, their agents remember what they learned between sessions, including filetype workarounds and tool-specific patterns. Completion rates went up ~6x in their tests.

> • Netflix's platform team built an analysis agent that processes logs from hundreds of builds across different sources. With changes that affect thousands of applications, what matters is finding the issues that recur across many of them. Multiagent orchestration lets the agent analyze batches in parallel and surface only the patterns worth acting on.

> • Spiral by Every is using multiagent orchestration and outcomes to power the writing agent behind their new API and CLI. The lead agent runs on Haiku : it fields incoming requests, poses quick follow-up questions when needed, then delegates the drafting to subagents running on Opus . When a user asks for multiple drafts, the subagents run in parallel. Writing quality is Spiral's core value, so they use outcomes to enforce it. Each draft is scored against a rubric of Every's editorial principles and the user's voice, both pulled from memory. Only drafts that clear the bar are returned.

> • Wisedocs built a document quality check agent on Managed Agents, using outcomes to grade each review against their internal guidelines. Reviews now run 50% faster, while staying aligned with their team's standards.

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
