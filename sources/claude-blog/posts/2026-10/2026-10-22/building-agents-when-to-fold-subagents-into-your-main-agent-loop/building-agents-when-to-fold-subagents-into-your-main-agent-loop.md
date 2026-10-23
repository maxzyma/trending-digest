# 构建智能体：何时将子智能体并入主智能体循环

> Building agents: When to fold subagents into your main agent loop

> 来源：Claude Blog / Anthropic，2026-10-22
> 原文链接：https://claude.com/resources/articles/building-agents-when-to-fold-subagents-into-your-main-agent-loop
> 分类：AI 工程 / 智能体架构

## 核心要点

- 子智能体在验证、并行工作和模块化权限管理方面仍有价值，适用于上下文膨胀导致可测量性能下降、需要并行使用全新上下文窗口，或单个智能体难以选择工具和存在冲突指令的情况。
- 企业部署比较显示，配备技能的单一智能体在质量上常优于单一大提示词设计和子智能体设计，且每项任务的成本和延迟往往更低。
- 按团队或问题类型划分子智能体容易让智能体架构复刻组织架构图，带来上下文丢失、子智能体泛滥、缝合怪提示词、过度局部化评估和延迟增加等问题。
- 通过技能渐进式披露上下文、通过工具搜索渐进式披露工具，可以在共享主上下文的同时避免上下文膨胀，而更强的模型也使部分 harness 组件变得多余。
- 推荐的单循环设计由单个模型在单个上下文窗口中运行开放式工具循环，由同一模型编写并随时修订计划，执行顺序和领域流程移入技能，硬性限制移入工具。
- 迁移的第一步是建立任务完成类评估，由中心团队维护共享端到端评测集，各技能负责团队随技能提供小型评测集，即使 10 个黄金样例也足以起步。
- 迁移可分阶段进行：先合并紧密耦合的领域子智能体，再把保留的子智能体作为工具调用以建立基线，最后将子智能体提示词转为技能、API 调用转为 MCP 工具并逐一比较评估结果。
- 比较时应关注哪些任务结果发生翻转，并对每个任务多次运行，因为合并可能在降低延迟的同时导致原本通过的流程间歇性失败。
- 工具应按用户意图分组以避免定义过多导致选择准确率下降，前置条件和按用户划分的权限检查可移入工具内部，使一个循环服务不同权限的用户。
- Anthropic 发布的 Claude API 技能和迁移工具包提供构建评估、审计提示词、迭代优化和成本优化等功能，核心原则是衡量、一次只改一件事并保留经得起检验的部分。

## 正文

*如果你已在 Claude Platform 中构建了一个包含多个子智能体的智能体，可以使用我们的[迁移工具包](https://github.com/anthropics/single-agent-loop-kit)，看看其中哪些子智能体适合并入主智能体循环。它会运行一套引导式工作流，帮助你识别现有模式、评估替代方案，并验证最佳方案。工具包还附带一个演示，你可以先在模拟系统上试用，再在自己的智能体上运行。*

> *If you’ve built an agent in Claude Platform that includes multiple subagents, see which may make sense to fold into the main agent loop using our [migration kit](https://github.com/anthropics/single-agent-loop-kit). It runs a guided workflow to identify your patterns, evaluate alternatives, and verify the best approach. It includes a demo that you can try on a mock system before running on your agent.*

子智能体（subagent）——拥有独立上下文窗口、工具和指令，并由协调者统一编排的智能体——是智能体设计的核心组成部分。它们在验证、并行工作和模块化权限管理方面表现出色。我们在使用 Claude Platform 构建的许多自有智能体中都用到了子智能体，例如我们的[多智能体研究系统](https://www.anthropic.com/engineering/multi-agent-research-system)。

> Subagents – agents with their own context window, tools, and instructions, orchestrated by a coordinator – are a core component of agent design. They are effective at verification, parallel work, and modular permissioning. We use them in many of our own agents that we build using Claude Platform, for example our [multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system).

然而，Applied AI 团队最近发现了一种企业智能体部署模式：将路由器、规划器和领域子智能体整合进主智能体循环后，部署效果得到了提升。在[我们对多个企业部署的比较](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#:~:text=In%20our%20comparisons%20across%20several%20enterprise%20deployments,latency%20per%20task)中，配备技能的单一智能体在质量上常常优于“一个提示词包揽一切”的设计和子智能体设计，而且每项任务的成本和延迟往往也更低。

> However, recently the Applied AI team has found a pattern of enterprise agent deployments that have benefited from folding routers, planners, and domain subagents into the main agent loop. In [our comparisons across several enterprise deployments](https://claude.com/blog/the-anatomy-of-effective-commerce-agents#:~:text=In%20our%20comparisons%20across%20several%20enterprise%20deployments,latency%20per%20task), a single agent with skills frequently outperformed both the one-prompt-for-everything design and the subagent design on quality, and often at a lower cost and latency per task.

例如，一家公司发现，其面向客户的智能体中包含的十几个专业子智能体使得保持一致、符合品牌调性的体验变得困难，并且增加了延迟，损害了用户体验。

> For example, one company found the dozen of specialist subagents within its customer-facing agent made a consistent on-brand experience difficult to maintain and added latency that hurt the user experience.

我们还经常看到一些智能体设计方案，它们遵循一种似曾相识的演进路径：先是意图分类器，然后是固定的多步推理流水线、用户分群桶、相互独立的推荐分支，最上层再加一个多智能体编排器。

> We also often see proposed agent designs that follow a familiar progression: an intent classifier, a fixed multi-step reasoning pipeline, user-segment buckets, separate recommendation branches, and a multi-agent orchestrator on top.

在这些情况下，得到的反馈往往是：这套结构中的大部分其实是在替模型做它已不再需要别人代劳的工作；而一份清晰的系统提示词、4-5 个轻量的数据工具，再加上严格的输出护栏，就足以覆盖大部分用例。

> In these cases feedback is often that most of this structure was doing work the model no longer needed done for it, and that one clear system prompt, 4-5 thin data tools, and firm output guardrails would cover most of the use case.

![subagent design](https://assets.claude.com/a7cb2cf08bfcef461166310c0c55f28b72c33b0d.gif)

需要明确的是，子智能体仍有其用武之地，包括在研究前沿。在以下情况下使用它们：

> To be clear, subagents still have their place, including at the research frontier. Use them when:

- 单个智能体循环因上下文膨胀而出现可测量的性能下降，或
- 需要并行处理多个任务，每个任务使用全新的上下文窗口，任务完成后即可丢弃该窗口，或者
- 单个智能体难以选择合适的工具，或者系统提示词中存在相互冲突的指令。

> • A single agent loop hits measurable performance degradation from context bloat, or
> • Multiple tasks need to be tackled in parallel with fresh context windows that can be discarded once the task is done, or
> • A single agent struggles to select appropriate tools or there are conflicting instructions in the system prompt.

但我们常常看到，企业为每个团队或每类问题都配备各自的子智能体，结果智能体架构变成了其组织架构图的翻版（这正是康威定律在起作用）。

> But too often we see enterprises give each team or problem type its own subagent, with the agent architecture becoming a copy of their org chart (Conway’s law at work).

本文将结合我们在大型组织中构建智能体时总结的最佳实践，说明何时应考虑将子智能体并入主智能体循环。

> This post explains when to consider folding subagents into your main agent loop with best practices we’ve learned from building agents in large organizations.

#### 大型组织构建智能体时的失败模式

> Agent building failure modes for large organizations

企业常常希望构建一个智能体，将多种产品和能力整合到统一的客户界面中。

> Companies often want to build an agent that unites multiple products and capabilities into a single customer interface.

通常，每项能力都由一个独立的团队负责，因此企业起初会让各个团队分别构建自己的智能体，随后再由一个中央平台团队在其之上构建一个编排器。这可以采用多种结构，包括编排器-子智能体模式，或者由单个智能体将特定智能体作为 MCP 工具对外提供。

> Typically, each capability is owned by a separate team, so companies start by letting each individual team build their own agent, then a central platform team builds an orchestrator on top. This can take on several structures including orchestrator-subagent or a single agent with specific agents exposed as MCP tools.

这看起来是最简单的解决方案，但会立即在以下方面引入复杂性：

> This looks like the simplest solution but introduces immediate complexity around:

- **上下文管理：**你需要决定智能体之间交换哪些上下文，而且在来回传递的过程中经常会丢失细节。
- **子智能体泛滥**：每个团队都发布自己的子智能体，结果公司里堆积了数百个功能重叠的子智能体，既没有强制执行的标准，也没有明确的负责人。
- **缝合怪提示词（The Frankenprompt）**：每个团队都往系统提示词里加一句话，结果规则相互冲突，也没有统一的语气。
- **未经审核、过度局部化的评估**：每个人都添加自己的评估，而这些评估都针对各自的子任务做了过度优化。没有人负责或维护整套评估，领导层则基于被稀释、过度局部化的分数做出决策。
- **延迟**：多智能体架构的复杂性会增加延迟。有一位客户将其多智能体框架与单智能体循环进行了对比评估，发现后者的运行速度大约快 2 倍。

> • **Context management: **You need to decide what context is exchanged between agents and often lose details in the back and forth.
> • **Subagent sprawl**: Every team ships its own subagent, so companies end up with hundreds of overlapping subagents with no enforced standards and no specific owner.
> • **The Frankenprompt**: Every team adds a sentence to the system prompt, resulting in conflicting rules and no consistent voice.
> • **Unvetted, overly localized evals**: Everyone adds their own evals that are overly optimized for their subtask. No one owns or maintains the whole set, and leadership makes decisions based on watered-down, overly localized scores.
> • **Latency**: Multi-agent architectural complexity adds latency. One customer that evaluated their multi-agent harness against a single agent loop saw a roughly 2x faster runtime with the latter.

#### 使用带渐进式披露的智能体循环

> Using an agent loop with progressive disclosure

上文所述的编排器-子智能体（orchestrator-subagent）设计，是协调由不同团队构建的专业智能体的一种合理方式，但通常更有效的做法是**通过技能（skills）渐进式披露上下文**，以及**通过工具搜索（tool search）渐进式披露工具**。换句话说，智能体只会看到技能和工具的简短描述，仅在需要时才会完整加载它们。

> The orchestrator-subagent design described above is a reasonable approach to coordinating specialists built across teams, but often a more effective approach can be **progressively disclosing context via skills** and **progressively disclosing tools via tool search**. In other words, the agent sees short descriptions of the skills and tools, which are fully loaded only when needed.

这种方法之所以可能合理，有三个原因：

> There are three reasons why this approach can make sense:

- **共享上下文能带来更好的答案：**对于长时间运行的智能体，我们希望来自多个不同任务的上下文都位于主上下文窗口中。一个看过此前每一步结果的智能体能够把它们关联起来，从而产出比子智能体交回的一组摘要更丰富的输出和更深入的洞见。这也意味着[更少的上下文窗口和更少的有损交接](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them)。
- **渐进式披露可防止上下文膨胀：**这项技术** **让团队能够构建单个智能体来完成各种各样的任务，而无需把所有上下文一次性加载进一个冗长的系统提示词中。这消除了团队以往将工作拆分到多个子智能体的主要原因。事实上，我们[针对更先进的模型将 Claude Code 的系统提示词缩减了 80% 以上](https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/)，其中就包括与渐进式披露技能和工具相关的删减。
- **模型能力更强了：**从 Opus 4.5 开始，模型在单个循环中能够处理的内容已远超大多数团队的预期。在 Opus 5.5 和 Fable 5.1 上无法关闭思考功能，而且近期的模型越来越多地在执行过程中自行说明进展并检查自己的工作，这使得部分 harness 组件变得多余。每一代新模型都让你能够把更多决策从 harness 中移交给模型本身。更简单的循环也更容易迁移到下一代模型；在我们协助客户完成的迁移中，僵化的多智能体结构往往正是阻碍新模型承担更多工作的原因。

> • **Shared context produces better answers:** for longer-running agents, we want the context from several different tasks to sit in the main context window. An agent that has seen the result of each earlier step can connect them, which leads to richer outputs and better insights than a set of summaries handed back by subagents. It also means [fewer context windows and fewer lossy handoffs](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them).
> • **Progressive disclosure prevents context bloat: **this technique** **allows teams to build single agents that can accomplish a wide variety of tasks without requiring all of the context to be immediately loaded into one long system prompt. This removes the main reason teams previously split work across subagents. In fact, we [reduced Claude Code’s system prompt for more advanced models by over 80%](https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/) which included cuts related to progressively disclosing skills and tools.
> • **Models are more capable:** starting with Opus 4.5, models became capable of managing far more in a single loop than most teams expected. You cannot turn off thinking on Opus 5.5, and Fable 5.1, and recent models increasingly narrate their progress and check their work as they go, which makes some harness elements redundant. Each new model lets you move more of the decision-making out of the harness and into the model itself. A simpler loop is also easier to move to the next model; in migrations we have helped customers with, rigid multi-agent structures were often what stopped the new model from doing more of the work.

单智能体循环设计需要严格的工程纪律：精心管理的系统提示词、能在恰当时机触发的技能与工具描述，以及对上下文窗口、记忆和笔记记录的审慎处理。本文将在后续章节中进一步深入探讨迁移与设计方面的考量。

> The single agent loop design requires discipline: a carefully managed system prompt, skill and tool descriptions that trigger at the right times, and deliberate handling of context windows, memory, and note-taking. This article goes deeper into migration and design considerations in subsequent sections.

应由一个中心团队负责端到端质量和系统提示词，在每个新工具和评估上线之前对其进行审核。让这个中心团队保持精简，有助于快速迭代，并降低大型组织中的协调成本。

> One central team should own end-to-end quality and the system prompt, vetting every new tool and eval before it ships. Keeping that central team small helps iteration move quickly and lowers coordination cost across a large org.

如果你选择多智能体路线，请从可能奏效的最简单模式（生成器-验证器、编排器-子智能体或其他模式）入手。有效划分边界的方法是**按上下文划分：给每个子智能体分配一项几乎不依赖系统其余部分的工作，并让它交回一个精炼的结果**（合适的候选包括彼此独立的研究路径、接口清晰的独立组件，或黑盒验证）。当按问题类型划分智能体时，它们会陷入一场“传话游戏”，** **来回传递信息，每一次交接都会降低保真度。

> If you go the multi-agent route, start with the simplest pattern (generator-verifier, orchestrator-subagent, or other) that could work. Decompose boundaries effectively by** dividing by context: give each subagent a piece of work that needs little from the rest of the system and have it hand back a compact result **(good candidates are independent research paths, separate components with clean interfaces, or black-box verification). When agents are split by problem type, they engage in a "telephone game,"** **passing information back and forth with each handoff degrading fidelity.

![subagents split by problem](https://assets.claude.com/cd4b9c4417d5ba31776e8aa79e204966c08c6a43.png)

#### 如何将子智能体整合进主智能体循环

> How to fold subagents into the main agent loop

许多团队已经在生产环境中部署了一个编排器和一组专职智能体。以下是我们建议逐步迈向的单循环设计：

> Many teams already have an orchestrator and a set of specialist agents in production. The following is the single loop design we'd suggest working toward:

- 由单个模型和单个上下文窗口运行一个开放式的工具循环，其限制（轮次与成本预算、写入闸门）在 harness 中设定。
- 在每一轮中，模型会发出一批工具调用。harness 并行执行这些调用，并将原始结果返回给同一个模型，由该模型决定下一步：再发出一批调用、向用户提问，或给出回答。
- 当模型给出回答或触及[预算](https://platform.claude.com/docs/en/build-with-claude/task-budgets)上限时，循环即停止。在给出回答后，还可以选择性地运行目标检查或验证器检查。
- 模型在第一轮中就把计划写入上下文，并随着结果陆续返回而不断修订。这是相对于“编排器 + 专家智能体”架构的主要变化：编写计划的模型同时也是执行计划的模型，因此它可以在一轮进行中途修改计划。
- 上下文仍然会被加载，并由智能体自行管理：
   - 由于每一步都由模型决定，因此不再需要一个依据规则目录来重写计划的代码步骤。
   - 执行顺序和领域流程被移入**技能（skills）中。**
   - 硬性限制（校验、审批关卡）以及对话中途出现的其他任何需求（例如记忆查询）都移入**工具中。**
   - 代码仍可用于加载任何开销低且几乎总是相关的内容（例如实体解析步骤），并在循环所调用的工具内部处理各种机械性环节（载荷构建、流解析、恢复澄清流程）。

> • One model and one context window running an open-ended tool loop, with limits (turn and cost budgets, write gates) set in the harness.

> • Each turn, the model emits a batch of tool calls. The harness runs them in parallel and returns raw results to the same model, which decides the next step: another batch, a question to the user, or an answer.

> • The loop stops when the model answers or hits a [budget](https://platform.claude.com/docs/en/build-with-claude/task-budgets). A goal or verifier check can optionally run after the answer.

> • The model writes its plan in context on the first turn and revises it as results arrive. This is the main change from the orchestrator and specialist agents setup: the model that writes the plan is also the one carrying it out, so it can change the plan mid-turn.

> • Context still gets loaded, and is managed by the agent itself:

> ◦ A code step that rewrites the plan from a catalog of rules is no longer needed, since the model decides each step.

> ◦ Ordering and domain procedure move into **skills.**

> ◦ Hard limits (validation, approval gates) and anything else that comes up mid-conversation (e.g. memory lookup) move into the **tools.**

> ◦ Code can still be used to load anything cheap and almost always relevant (e.g. an entity resolution step), and to handle any mechanical parts (payload construction, stream parsing, resuming a clarification) inside tools the loop calls.

这种单循环设计也有助于实现许多团队正在努力追求的最终形态（一个能够理解用户高层目标并代表用户采取行动的智能体），因为它把智能体学到的一切都保存在同一个上下文中。

> This single loop design also helps with the end state many teams are working toward (an agent that understands a user's high-level goals and acts on their behalf), since it keeps everything the agent has learned in one context.

下面的建议说明了一个团队如何分阶段地从多智能体系统过渡到单一智能体循环，以及多个团队如何在此过程中持续为该智能体贡献力量。

> The suggestions below are how a team could get from a multi-agent system to a single agent loop in stages, and how several teams can keep contributing to that agent along the way.

##### 任务完成类评估

> Task-completion evals

第一步是创建一个评测集，帮助你判断是否应该将某个子智能体并入主智能体循环。我们看到行之有效的评测结构是：由一个中心团队负责维护一套共享的端到端评测集，同时由各个技能的负责团队随技能一并提供规模较小的评测集。即使只有 10 个黄金样例，也足以起步。

> The first step is to create an eval set that can help you determine whether you should fold a subagent into the main agent loop. The eval structure we’ve seen work is one shared end-to-end set owned by a central team with smaller eval sets shipped with each skill by the team that owns it. Even a set of 10 golden examples is enough to start.

根据评分标准对智能体的最终消息进行评分，是跟踪回答质量的良好起点。在仍有编排器的阶段，你还应跟踪路由准确率（它是否选对了子智能体？）。一旦某个子智能体被合并进来，则应改为检查智能体是否加载了正确的技能或调用了正确的工具。随着时间推移逐步转向任务完成度评估是有益的，因为在比较不同架构时，这一点最为重要。

> Grading the agent's final message against a rubric is a good starting point for tracking answer quality. While you still have an orchestrator, you should also track routing accuracy (did it pick the right subagent?). Once a subagent is folded in, check instead whether the agent loaded the right skill or called the right tool. Working toward task-completion evals over time is helpful as this matters most when comparing architectures.

在内部系统难以重放、用户交互难以模拟的环境中，这可能会很复杂。我们内部行之有效的一种方法是记录重要事件的时间戳，以便日后重放这些事件，作为有针对性的评估来运行。

> This can be complex in environments where internal systems are difficult to replay and user engagement is difficult to simulate. One approach that has worked for us internally is to record timestamps on important events, so they can be replayed later to run as targeted evals.

##### 逐步减少子代理

> Reducing subagents over time

向单一智能体循环演进，需要将子智能体并入工具和技能之中。具体做法可以是合并领域子智能体、将其作为工具调用，或用技能和工具来替代它们。

> Evolving toward a single agent loop involves folding the subagents into tools and skills. This can be done by merging domain subagents, calling them as tools, or replacing them with skills and tools.

![folding in subagents](https://assets.claude.com/ed6bd97496ffdab88763806d9e14f1ec61ed9255.gif)

##### 组合领域智能体

> Combining domain agents

在第一次合并之前，先构建一个小型的端到端评测。然后**按共享上下文逐步合并，从使用最多的子代理开始。**

> Build a small end-to-end eval before the first merge. Then **fold in by shared context starting with subagents that have the most use.**

[合并那些专职智能体](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them)：它们相互串联、以彼此的输出为输入，操作相同的数据，或经常被一起调用。例如，如果生产流量中有相当大的比例是先调用一个专职智能体、再调用另一个，那么这就是一对紧密耦合的智能体，可以考虑将其合并为一个领域智能体。

> [Merge specialists](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them) that chain on each other's output, touch the same data, or are often called together. For example, if a significant share of production traffic is one specialist followed by a second, that is a tightly coupled pair, which makes it a candidate to merge into one domain agent.

##### 作为工具调用的子智能体

> Subagents called as tools

当上述三种情况之一成立、你决定保留子智能体时，一种有效的做法是让主智能体将子智能体作为工具来调用，这样主智能体就能继续与用户保持对话。

> When one of the three conditions above applies and you keep a subagent, it can be effective to have the main agent call subagents as tools so it can continue holding the conversation with the user.

只有当子智能体需要直接与用户对话时，我们才建议采用完全移交的方式，即由子智能体接管对话。其他情况都可以在主循环中通过技能加工具来实现。

> We’d only recommend a full handoff, where the subagent takes over the conversation, when it needs to talk to the user directly. Everything else can be a skill plus tools in the main loop.

这样你就可以为子代理定义统一的响应 schema，由主代理基于真实数据验证结论，并精简传入最终综合步骤的输入。这是很好的第一步，因为你无需**重写**子代理。它还能让你在决定是否将某些子代理并入主代理之前，先获得任务完成度评估的**基线**。

> This will allow you to define a shared response schema for subagents, verify the conclusion against real data with the main agent, and trim the input to any final synthesis step. This is a good first step, as you don’t need to** rewrite **the subagents. It also gives you a** baseline** on the task-completion eval before deciding to fold any subagents into the main agent.

不过，仍会存在一些失效模式：

> However, some failure modes will remain:

- 每个专用智能体都有各自的提示词、上下文、负责团队和评测
- 每次调用返回的仍然只是一份有损的摘要
- 每次调用都是一个嵌套的模型循环，会增加延迟

> • Each specialist has its own prompt, context, owner team, and evals
> • Each call still hands back a lossy summary
> • Every call is a nested model loop that adds latency

##### 通过技能和工具将子代理并入主代理

> Folding subagents into the main agent via skills and tools

将子代理逐个合并到主代理中：把每个子代理的提示词转换为技能，把其 API 调用转换为 MCP 工具。比较有无该子代理时的评估表现，然后决定保留哪些。

> Fold subagents into the main agent one at a time by turning each one’s prompts into skills and API calls into MCP tools. Compare eval performance with and without the subagent. Then decide which to keep.

进行比较时，不要只看最终得分，还要看看哪些任务的结果发生了翻转。我们在一个示例客服智能体上测试时发现，将一个子智能体合并到另一个子智能体中虽然降低了延迟，却也导致一个原本通过的流程失败了。主智能体持有订单查询工具后便自行作答，而没有向物流专员询问送达日期。

> When you compare, don’t just examine the final score, take a look at which tasks flipped. When we tested this on a sample support agent, folding one subagent into another lowered latency, but also broke a process that had been passing. The main agent was holding the order lookup tool and answering on its own, without asking the shipping specialist for the delivery date.

每次修改之前，都要确保你的评估为生产环境中协同运行的每一条智能体链、以及智能体绝不能违反的每一条规则都设有对应的任务，并且每个任务都要运行不止一次，因为像这样的故障在两次运行中只出现了一次。

> Before each change, make sure your eval has a task for every chain of agents that runs together in production and for every rule the agent must not break, and run each task more than once, since a break like this one only showed up in one run out of two.

#### 多个团队如何共同参与构建同一个智能体

> How several teams can contribute to a single agent

领域推理能力可以从知识库、技能和 MCP 工具中检索获得。各个团队可以把自己的职责从智能体转向技能和工具，由一个小型中心团队负责系统提示词和端到端质量。这包括在新技能、工具和评测上线前对其进行审核。

> Domain reasoning can be retrieved from knowledge bases, skills, and MCP tools. Individual teams can shift their ownership from agents to skills and tools, with one small central team keeping ownership of the system prompt and end-to-end quality. This involves vetting new skills, tools, and evals before they ship.

##### MCP 工具

> MCP tools

当智能体需要执行某个操作、从系统中读取实时数据，或以固定格式返回结果时，工具是合适的选择。在迁移过程中，你也可以借助工具继续调用子智能体。我们建议按用户意图对工具进行分组（而不是每个 API 对应一个工具），因为一旦系统提示词中的工具定义超过 30–50 个，工具选择的准确性往往会下降。

> Tools are the right fit when the agent needs to take an action, read live data from a system, or return a result in a fixed shape. You can also use tools as a way to keep calling subagents while you migrate. We recommend tools grouped by user intent (not one tool per API) because once you exceed 30-50 tool definitions in the system prompt, tool choice tends to degrade.

使用带延迟加载的[工具搜索](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)，限制硬性前置条件，并将确实需要的前置条件移入工具内部。例如，如果 Y 需要 X 的输出，就由 Y 的工具检查该输出是否存在，并返回一条模型可以据此执行的指令。按用户划分的权限也以同样的方式处理。每个工具都会检查调用用户可以查看或执行哪些操作，并返回一条模型能够读懂的简明拒绝信息。这样，一个循环就能服务于拥有不同访问权限的用户，而无需为每个权限级别单独设置一个智能体。

> Use [tool search](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool) with deferred loading, limit hard preconditions, and move any needed ones into the tools. For example, if Y needs X's output, Y's tool checks for it and returns an instruction the model can act on. Per-user permissions work the same way. Each tool checks what the calling user may see or do and returns a plain refusal the model can read, so one loop can serve users with different access without a separate agent per permission level.

##### 技能

> Skills

当智能体需要了解一个团队如何开展工作时，比如过去由专业子智能体的提示词所承载的那些步骤、规则和判断取舍，Skills 就是合适的选择。

> Skills are the right fit when the agent needs to know how a team does work, like the steps, rules, and judgment calls a specialist subagent's prompt used to hold.

我们扩展技能库的做法，是把维护工作交还给编写技能的人。Claude 可以借助能够构建、测试和精简其他技能的技能，承担其中的繁重工作。

> Our approach to growing skill libraries is to give the maintenance work back to the people writing the skills. Claude can do the heavy lifting with skills that can build, test, and prune other skills.

为防止技能泛滥，可以让各团队的 DRI（直接负责人）负责管理各自的技能，确保这些技能设计精良、彼此区分明确，并在发布时附带相应的评估（evals）。

> To prevent skill sprawl, you can have DRIs per team own their skills and make sure they are well crafted, distinct, and shipped with appropriate evals.

- **/skill-creator** 可帮助你编写从一开始就结构规范的新技能，也可审查现有技能，对其进行精简、去重和重组。
- **/skill-doctor** 可以让你查看技能库中每个技能的开销及其实际使用频率，并删除无用的冗余技能。

> • **/skill-creator** allows you to author new skills that start well-formed, and audit existing ones to trim, deduplicate, and restructure them.
> • **/skill-doctor** allows you to see what each skill in your library costs and how often it’s actually used, and delete dead weight.

##### 知识库

> Knowledge bases

知识库适合存放智能体只是偶尔需要用到的参考资料。事实和参考资料（政策、指标定义、产品规格）可以放在模型调用的搜索或查询工具之后，也可以作为参考文件随技能一起提供。避免[由代码检索这些上下文并将其粘贴到提示词中](https://claude.com/blog/seeing-like-an-agent)。

> Knowledge bases are the right fit for reference material the agent only needs some of the time. Facts and reference material (policies, metric definitions, product specs) can sit behind a search or lookup tool the model calls, or ship as reference files inside a skill. Avoid having [code retrieve and paste this context into prompts](https://claude.com/blog/seeing-like-an-agent).

#### 加速这项工作的工具

> Tools to accelerate this work

我们最近[发布](https://code.claude.com/docs/en/commands)了一组 Claude API 技能，可以帮助完成上述大部分工作。我们的[迁移套件](https://github.com/anthropics/single-agent-loop-kit)将这些技能串联成一个引导式工作流，用于评估多智能体系统并将其迁移到单一智能体循环。其中包含一个演示，你可以在真正用于实际系统之前先试一试：

> We recently [released](https://code.claude.com/docs/en/commands) a set of Claude API skills that can help with most of the work mentioned above. Our [migration kit](https://github.com/anthropics/single-agent-loop-kit) chains these skills together in one guided workflow for assessing and moving multi-agent systems to a single agent loop. It includes a demo you can try before running it on the real thing:

- **/claude-api build-eval：**可以帮助创建由中央团队负责的首套端到端评估集，或由各团队随其技能一同发布的小型评估
- **/claude-api prompt-audit:** 可以标记出你的提示词、技能和工具描述中为旧模型编写的指令，并以 diff 形式提出修复建议。你可以在系统提示词上运行它，找出那些为早期模型添加、如今却让智能体变得更慢或更僵化的规则。各团队的 DRI 也可以在自己的技能和工具描述上运行它。
- **/claude-api hillclimb：**可以针对已有的评测（eval）迭代改进应用。它可用于“合并 vs 保留”的对比（把某个子智能体合并为一个技能加若干工具后，让它迭代优化技能和工具的描述，看合并后的版本能否追平或超越原子智能体），也可用于优化你的系统提示词。
- **/claude-api cost-optimize：**分析你的调用开销分布，并基于提示词缓存、裁减不必要的输入和输出 token、effort 以及模型选择等选项提出节省方案，每次只做一项改动。这有助于在既定设计下降低成本和延迟。

> • **/claude-api build-eval:** can help create a first end-to-end set owned by the central team or small evals each team ships with its skill
> • **/claude-api prompt-audit:** can flag instructions written for older models in your prompts, skills, and tool descriptions and propose fixes as a diff. This can be run on your system prompts to find any rules that were added for an earlier model and are now making the agent slower or more rigid. Each team's DRI can also run it on their own skills and tool descriptions.
> • **/claude-api hillclimb: **can iteratively improve an app against an existing eval. This can be used for the "folded in vs kept" comparison (after folding one subagent into a skill plus tools, let it iterate on the skill and tool descriptions and see if the folded version matches or beats the subagent), as well as your system prompt.
> • **/claude-api cost-optimize: **profiles where your calls go and proposes savings from options such as prompt caching, trimming unneeded input and output tokens, effort, and model choice, one change at a time. This can help bring cost and latency down on a given design.

随着模型不断演进，我们对如何最好地使用它们的理解以及围绕最佳实践的指导也在随之演进。这使得任何一种具体架构都不如其背后的原则重要：衡量，一次只改变一件事，并保留经得起检验的部分。

> As models evolve, our understanding of how to best use them and guidance around best practice evolve as well. That makes any one architecture less important than the principle behind it: measure, change one thing at a time, and keep what holds up.

这正是其中一种情况。随着模型能力不断增强、智能体运行时间越来越长，你的更多子智能体可以改为技能和工具。不过，你不必一步到位。先构建一个小型的端到端评估，把一个子智能体合并进来，只有当合并后的版本得分更低时才保留它作为子智能体，然后如此反复。

> This is one of those cases. As models get more capable and agents get longer running, more of your subagents can be skills and tools. You don’t have to make that move in one step, though. Build a small end-to-end eval, fold in one subagent, and keep it as a subagent only if the folded version scores worse, then rinse and repeat.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Subagent | 子智能体 | 拥有独立上下文窗口、工具和指令，并由协调者统一编排的智能体。 |
| Orchestrator | 编排器 | 负责路由任务并协调多个子智能体工作的上层智能体或组件。 |
| Agent Loop | 智能体循环 | 模型反复发出工具调用、接收结果并决定下一步直至给出回答的运行机制。 |
| Progressive Disclosure | 渐进式披露 | 先向智能体只展示简短描述，仅在需要时才完整加载相应内容的技术。 |
| Skills | 技能 | 封装团队工作步骤、规则和判断取舍的可按需加载的指令包。 |
| Tool Search | 工具搜索 | 让模型在需要时检索并延迟加载工具定义的机制。 |
| Context Bloat | 上下文膨胀 | 上下文窗口中堆积过多内容导致模型性能下降的现象。 |
| Harness | 运行框架 | 包裹模型、负责执行工具调用和设定预算与限制等的外围代码。 |
| Conway's Law | 康威定律 | 系统设计往往会复刻构建它的组织的沟通结构。 |
| Frankenprompt | 缝合怪提示词 | 由多个团队各自添加规则拼凑而成、规则冲突且语气不统一的系统提示词。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 用于向模型提供工具和数据源的标准化协议。 |
| Eval | 评估 | 用于衡量智能体在特定任务上表现的测试集合与评分方法。 |
| Golden Example | 黄金样例 | 带有已知正确结果、用于评测的高质量参考样本。 |
| Handoff | 移交 | 由子智能体接管与用户的对话或任务控制权的方式。 |
| DRI (Directly Responsible Individual) | 直接负责人 | 对某项资产或工作负有明确最终责任的个人。 |
