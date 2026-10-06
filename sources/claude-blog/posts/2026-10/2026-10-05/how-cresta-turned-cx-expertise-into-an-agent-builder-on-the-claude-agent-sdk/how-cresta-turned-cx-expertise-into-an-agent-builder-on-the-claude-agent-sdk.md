# Cresta 如何基于 Claude Agent SDK 将客户体验（CX）专业知识打造为智能体构建器

> How Cresta turned CX expertise into an agent builder on the Claude Agent SDK

> 来源：Claude Blog / Anthropic，2026-10-05
> 原文链接：https://claude.com/blog/how-cresta-turned-cx-expertise-into-an-agent-builder-on-the-claude-agent-sdk
> 分类：人工智能 / 智能体开发

## 核心要点

- 企业级客户体验智能体需要理解客户交互中的复杂上下文，并可能需要查询购买记录、退款政策、账户历史或付款状态等信息才能正确回应。
- Conductor 是一款自然语言智能体构建工具，用户描述需求后，它从有据可依的蓝图出发，引导实现、评估与优化的完整工作流程。
- Conductor 最初由 Cresta 基于 Claude Sonnet 和 Claude Opus 构建，用于支持内部团队的客户部署，之后被转化为客户可直接在平台内使用的产品。
- 据 Cresta 介绍，在其自身及合作伙伴的早期用例中，Conductor 将初始部署时间缩短了约一半。
- Conductor 作为可自我改进的元智能体，帮助构建者把模式、业务规则和评估方法沉淀为可复用的记忆工件，并作为技能在团队内共享，形成知识飞轮。
- Conductor 借助历史对话帮助团队划定对话中应保持灵活的部分与需要确定性业务规则和受控工具行为的部分，以兼顾体验与合规可靠性。
- Cresta 通过构建新智能体、编写测试用例、修改已有智能体和根因分析等任务评估 Conductor，并在新模型发布或框架更新时重新运行同一套评估作为安全网。
- Conductor 将构建阶段记录的需求和边缘情况转化为评估模块中的测试，使团队能在策略、系统和对话模式变化时持续监控关键工作流。
- Claude Agent SDK 作为通用执行框架位于 Conductor 之下，负责收集上下文、调用工具和编写运行代码，Conductor 则在其上叠加 Cresta 的 CX 工作流、工具和领域上下文。
- Cresta 对该 SDK 的评审涵盖多步骤、长上下文和反复工具调用的任务适配性，以及数据隐私、租户架构、组织级密钥分发、管控措施和可观测性。

## 正文

*在我们的系列文章****《初创公司如何借助 Claude 构建产品》****中，我们将深入探讨 AI 产品背后的决策。本文将介绍 *[Cresta](https://cresta.com/)* 如何将其在构建 AI 原生客户体验方面的专长融入 *[Conductor](https://cresta.com/blog/cresta-conductor-the-agent-for-ai-agent-development)*——一款帮助开发者构建和改进其他智能体的智能体。*

> *In our series, ****How startups build with Claude****, we look at the decisions behind AI products. Here, we explore how *[Cresta](https://cresta.com/)* brought its expertise building AI-native customer experience into *[Conductor](https://cresta.com/blog/cresta-conductor-the-agent-for-ai-agent-development)*, an agent that helps developers build and improve other agents.*

为客户体验场景构建企业级 AI 智能体，需要理解蕴含在各类客户交互中的上下文。例如，客户可能会：

> Building enterprise AI agents for customer experience use cases requires understanding the context embedded across a wide range of customer interactions. For example, customers may:

- 要求退款，却没有说明指的是哪一笔购买，
- 在同一条消息中同时报告账单问题和登录问题，或者
- 在退货期限截止后申请退款。

> • Ask for a refund without saying which purchase they mean, 
> • Report a billing problem and a login issue in the same message, or 
> • Request a refund after the return window has closed. 

为了做出正确的回应，智能体可能需要查看客户购买了什么、退款政策、其账户历史记录或付款状态。

> To respond correctly, the agent may need to check what the customer bought, the refund policy, their account history, or the payment status.

Cresta 大规模地处理着这类交互。其平台为客户体验提供支撑：AI 智能体能够自主处理对话，为与其协同工作的人工坐席提供实时指导，并挖掘对话洞察，向企业揭示有待改进之处。

> Cresta sees these interactions at volume. Its platform powers customer experience, AI agents that handle conversations on their own, provide real-time guidance for the human agents working alongside them, and surface conversation intelligence that shows the business where to improve. 

构建和维护客户体验智能体，需要组织在运行要求上做出关键决策：智能体需要掌握哪些知识、必须访问哪些系统，以及其行为在哪些方面应当灵活、在哪些方面应当确定。Cresta 希望让更多团队都能借助这种判断力，而不必每个团队都从零开始。

> Building and maintaining customer experience agents requires organizations to make key decisions on operating requirements: what the agent needs to know, which systems it must access, and where its behavior should be flexible or deterministic. Cresta wanted to make that judgment available to more teams without each one starting from scratch. 

Conductor 正是这一成果：它是一款自然语言智能体构建工具，帮助团队将复杂的业务上下文转化为可投入生产的智能体。用户描述想要构建的内容，Conductor 便会引导整个工作流程，从有据可依的蓝图出发，贯穿实现、评估与优化各个环节。

> Conductor is the result: a natural language agent builder that helps teams turn complex business context into production-ready agents. Users describe what they want to build, and Conductor guides the work from a grounded blueprint through implementation, evaluation, and optimization.

Cresta 最初使用 Claude Sonnet 和 Claude Opus 构建了 Conductor 的早期版本，用于帮助内部团队支持客户部署。悬而未决的问题是：Cresta 能否将这套系统转化为一款产品，让客户直接*在*平台内构建智能体。  
  
为了开展开放式的开发工作，Conductor 将 Claude Agent SDK 用作通用框架，以收集上下文、使用工具、编写并运行代码，并根据结果进行调整。

> Cresta originally built an early version of Conductor using Claude Sonnet and Claude Opus to help internal teams support customer deployments. The open question was whether Cresta could turn that system into a product customers could use to build agents directly *within* the platform.  
>
> To carry out open-ended development work, Conductor uses the Claude Agent SDK as a general-purpose harness to gather context, use tools, write and run code, and adapt based on the results.

“我们在内部把 Claude Code 当作开发工具使用，因为它在构建智能体的软件开发环节非常高效，”Cresta Conductor 工程负责人 Renjie Li 表示，“Claude Agent SDK 让我们能够以编程方式使用同一套智能体开发框架。借助 Conductor，我们将它与 Cresta 深厚的对话智能、客户体验（CX）专业能力、评估体系和运行时相结合，为用户提供我们从第一天起就希望拥有的智能体构建体验。”

> “We used Claude Code internally as a dev tool because it was very effective at the software development aspects of building an agent,” said Renjie Li, Engineering Lead for Cresta Conductor. “The Claude Agent SDK gave us a way to use that same agentic development harness programmatically. With Conductor, we’ve connected it with Cresta’s deep conversation intelligence, CX expertise, evaluations, and runtime to give users the agent-building experience we wish we’d had from day one.”

Cresta 表示，在 Cresta 及其合作伙伴的早期用例中，Conductor 将初始部署时间缩短了约一半。

> Cresta reports that in early use cases across Cresta and its partners, Conductor cut initial deployment time roughly in half. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ac3a966e07da0d8501b6945_cresta-conductor-architecture-original-style.png)

#### **一个帮助构建下一代智能体的元智能体**

> **A meta-agent that helps build the next agent**

Conductor 是一个能够自我改进的元智能体，基于 CX 智能体开发中久经验证的最佳实践构建而成。随着团队使用它构建和优化越来越多的智能体，他们会沉淀下自己行之有效的模式、工作流和专家判断。由此形成一个知识飞轮，让未来的开发更快速、更一致。

> Conductor is a self-improving meta-agent built on established best practices for CX agent development. As teams build and refine more agents with it, they capture their own proven patterns, workflows, and expert judgment. This creates a knowledge flywheel that makes future development faster and more consistent.

上线后，生产环境中的交互、工作流结果和反馈会成为下一轮改进的新信号。

> After launch, production interactions, workflow outcomes, and feedback become new signals for the next improvement. 

Conductor 帮助构建者将他们在构建智能体过程中学到的经验转化为可复用的记忆工件，沉淀其中的模式、业务规则和评估方法。随后，他们可以将其作为技能分享给团队其他成员，让其他人也能基于同样经过验证的实践进行构建。

> Conductor helps builders turn what they learned from an agent build into a reusable memory artifact, capturing patterns, business rules, and evaluation approaches. They can then share it as skill with the rest of the team, so others can build from the same proven practices.

##### **让重要决策变得更容易**

> **Making the important decisions easier**

编写第一版提示词只是构建一个实用智能体的一部分。更难拿捏的一点在于：对话在哪些环节应保持灵活，又在哪些环节需要明确的业务规则和受控的工具行为。

> Writing the first prompt is only one part of building a useful agent. One of the harder calls is where a conversation should stay flexible and where it needs explicit business rules and controlled tool behavior.

“你不希望过于确定性，否则你会创建一棵巨大的决策树，试图描绘出每一个可能的分支……但有些企业关键型工作流必须确保始终正常运行，尤其是在风险容忍度低、监管严格的行业中，”Renjie 说道。“Conductor 帮助发现并固化这些确定性需求及其实现，同时保留灵活性来改善整体体验。”

> "You don't want to go too deterministic, otherwise you create a giant decision tree trying to map out every possible branch… but there are enterprise-critical workflows that you need to make sure work all the time, especially for highly regulated industries with low risk tolerance," said Renjie. "Conductor helps discover and harden those deterministic requirements and the implementation with the flexibility to improve the overall experience."

Conductor 借助历史对话，帮助团队确定哪些环节应当保留人工参与，哪些环节可以给模型留出自行调整的空间。划定这些边界之后，开发者仍需针对确定性部分所要落实的需求对其进行测试，并随着底层业务规则的变化修订这些测试。 

> Conductor draws on historical conversations to help teams identify where a human should stay in the loop and where the model can be given room to adapt. Once those boundaries are set, developers still need to test the deterministic pieces against the requirements they're meant to enforce, and revise those tests as the underlying business rules change. 

#### **Cresta 如何评估 Conductor**

> **How Cresta evaluates Conductor**

Conductor 的衡量标准是它构建智能体的能力。为此，Cresta 让 Conductor 执行一组构建任务：

> Conductor is measured on how well it builds agents. To that end, Cresta runs Conductor through a set of build tasks:

- 构建新智能体
- 为其中一个编写测试用例
- 修改已存在的智能体
- 进行根因分析

> • Build a new agent
> • Write a test case for one
> • Change an agent that already exists
> • Perform root cause analysis

完成任务并不是唯一的标准。团队还会审视结果、Conductor 是如何达成这些结果的，以及它在此过程中使用了哪些东西。

> Finishing the task is not the only bar. The team also looks at the outcomes, how Conductor got there, and what it used along the way.

这些相同的任务也起到了安全网的作用。每当新的 Claude 模型发布或 Conductor 框架更新时，Cresta 都会重新运行评估。它使用相同的任务和相同的评分方式，在任何人决定采纳这一变更之前，找出哪些方面有所改进、哪些方面仍需完善。

> Those same tasks function as a safety net. When a new Claude model is launched or the Conductor framework is updated, Cresta reruns its evaluations. It uses the same tasks and same scoring to identify what improved and what still needs work before anyone commits to the change.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ac3a91f9f5ee36b2b3dcc52_cresta-eval-1-what-we-evaluate.png)

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ac3a92f9c523d9a223f3798_cresta-eval-2-how-each-scenario-is-executed.png)

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ac3a9409092cb2380e00bda_cresta-eval-3-how-we-expose-the-run-data.png)

同样的评估规范也内置于 Conductor 中，使其用户能够检查并确认他们的智能体是否按预期运行。Conductor 会将构建阶段中记录的需求和边缘情况转化为其评估模块中的测试。

> That same evaluation discipline is built into Conductor, which allows its users to check and see if their agents are performing as intended. Conductor turns requirements and edge cases captured during the build phases into tests within its evaluation module. 

随后，随着策略、所连接的系统和对话模式不断变化，团队可以持续监控那些每次都必须正常运行的工作流。这为他们提供了一种切实可行的方式，使其能够随着业务的变化更新智能体，同时不丧失已经加固过的工作流的可靠性。

> Teams can then monitor the workflows that need to work every time as policies, connected systems, and conversation patterns change. That gives them a practical way to update an agent as the business changes without losing the reliability of the workflows they have already hardened.

#### **基于 Claude Agent SDK 构建 Conductor**

> **Building Conductor on the Claude Agent SDK**

Cresta 将 Conductor 设计为面向客户体验（CX）场景的智能体开发控制平面。它整合了对话数据、领域专业知识和开发实践，并通过策略、可观测性、验证以及反馈驱动的改进来管控每一次智能体运行。

> Cresta designed Conductor as the CX-specific control plane for agent development. It brings together conversation data, domain expertise, and development practices, then governs each agent run through policy, observability, verification, and feedback-driven improvement.

Claude Agent SDK 位于 Conductor 之下，作为通用的执行框架。它负责收集上下文、调用工具以及编写和运行代码等工作；Conductor 则在其之上叠加 Cresta 的客户体验（CX）工作流、工具和领域上下文。

> The Claude Agent SDK sits beneath Conductor as a general-purpose execution harness. It manages the work of gathering context, calling tools, and writing and running code; Conductor layers Cresta's CX workflows, tools, and domain context on top.

团队根据 Conductor 需要执行的工作对该 SDK 进行了评估：这些任务包含多个步骤、涉及大量上下文，并需要反复调用工具。评审范围涵盖整个实现中的数据隐私、租户架构、组织级密钥分发、管控措施以及可观测性。

> The team evaluated the SDK against the work Conductor needed to perform: tasks with multiple steps, substantial context, and repeated tool use. Its review covered data privacy, tenant architecture, organization-level key distribution, controls, and observability across the implementation.

“Anthropic 为我们的智能体软件开发提供了坚实、通用的基础。这让我们能够把工程投入集中在 Cresta 最能创造持久客户价值的地方，”Cresta 工程副总裁 Xiangru Chen 表示。

> "Anthropic gives us a strong, general-purpose foundation for agentic software development. That lets us put our engineering investment where Cresta creates the most durable customer value," said Xiangru Chen, VP of Engineering at Cresta.

#### **将 Cresta 的工程专业能力直接交到客户手中**

> **Putting Cresta's engineering expertise directly in customers' hands**

Conductor 起步于 Cresta 内部，帮助其前沿部署团队摸清哪些开发任务可以变得可重复、上下文在哪些环节最为关键，以及构建者在此过程中需要检查哪些内容。它在这项内部工作中取得的成功，让团队有信心将同样的能力带给客户和合作伙伴。

> Conductor started inside Cresta, helping its own forward-deployed team learn which development tasks could become repeatable, where context mattered most, and what builders needed to inspect along the way. Its success in that internal work gave the team confidence to bring the same capabilities to customers and partners.

对于任何一个产品部署定制智能体的速度超过工程师手工构建速度的团队来说，Cresta 的做法都是一个有用的参考：无论是智能体还是元智能体，初始构建之后的工作往往才是最难的部分。

> For any team whose product deploys custom agents faster than its engineers can hand-build them, Cresta's approach is a useful reference point: with agents or meta-agents, the work after the initial build is often the hardest part.

了解 [Conductor](https://cresta.com/blog/cresta-conductor-the-agent-for-ai-agent-development) 如何将业务上下文转化为更好的智能体设计、实现和持续改进。

> See how [Conductor](https://cresta.com/blog/cresta-conductor-the-agent-for-ai-agent-development) turns business context into better agent design, implementation, and ongoing improvement.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Claude Agent SDK | Claude 智能体开发工具包 | Anthropic 提供的以编程方式构建智能体的通用框架，支持收集上下文、调用工具和运行代码。 |
| Customer Experience (CX) | 客户体验 | 企业在与客户交互的全过程中提供的服务与体验。 |
| Meta-agent | 元智能体 | 用于帮助构建、评估和改进其他智能体的智能体。 |
| Agent harness | 智能体框架 | 承载智能体执行循环、工具调用和上下文管理的底层运行框架。 |
| Control plane | 控制平面 | 负责统一管控、编排和治理系统运行的管理层。 |
| Runtime | 运行时 | 智能体在生产环境中实际执行的环境与系统。 |
| Conversation intelligence | 对话智能 | 对客户对话进行分析以提取洞察和改进机会的技术能力。 |
| Blueprint | 蓝图 | 智能体构建前基于需求和数据形成的设计方案。 |
| Memory artifact | 记忆工件 | 将构建经验、模式和业务规则沉淀下来以供复用的持久化产物。 |
| Skill | 技能 | 可在团队内共享、供智能体复用的封装化能力或实践。 |
| Knowledge flywheel | 知识飞轮 | 经验不断积累并反哺后续开发、使效率持续提升的正向循环。 |
| Deterministic workflow | 确定性工作流 | 必须按固定规则稳定执行、不允许模型自由发挥的业务流程。 |
| Human-in-the-loop | 人工参与 | 在自动化流程的关键环节保留人工审核或介入的设计方式。 |
| Root cause analysis | 根因分析 | 追溯问题根本原因以便有针对性地修复的分析方法。 |
| Observability | 可观测性 | 通过日志、指标和追踪等手段了解系统内部运行状态的能力。 |
