# AI 原生软件开发生命周期实战手册

> The AI-Native SDLC playbook

> 来源：Claude Blog / Anthropic，2026-08-21
> 原文链接：https://claude.com/blog/the-ai-native-sdlc-playbook
> 分类：软件工程 / AI 原生开发流程

## 核心要点

- 传统软件开发生命周期的审批关卡、评审与交接是为编码最耗时、最昂贵的时代设计的，当代码不再是瓶颈时，这些环节反而拖慢整体交付速度。
- 当构建阶段加速后，瓶颈转移到仍以人类速度运行的规划、评审/测试与部署环节，逐行人工审查等管控措施难以为继，治理成本随例外处理会议而上升。
- 安全团队按人类产出量配置规模，智能体使代码量成倍增长后会出现评审队列积压或代码在评审不足时上线，受监管组织无法接受这两种结果。
- AI 原生的生命周期把线性流程改造成循环，每个阶段以将产物提交到版本控制作为结束，下一阶段以读取该产物作为开始，这条提交链同时构成审计轨迹。
- 规划阶段由发起人与 Claude 头脑风暴产出 intent.md，经产品负责人审阅提交后触发设计阶段；设计阶段在组织技能约束下生成 spec.md 并标记存疑之处。
- 构建阶段以计划模式为默认起点，工程师迭代出 plan.md 后再让 Claude 实施，随着防护措施成熟，自动接受模式可成为常规工作的默认方式。
- CLAUDE.md 承载团队约定与常见错误纠正，技能承载必须一致应用的组织知识，钩子作为确定性层强制执行技能背后的策略，形成从建议性控制到强制控制的分层。
- 测试阶段强调为智能体提供可自我验证的反馈循环，并通过在修复期间禁止编辑测试文件的钩子来保护该循环；CI 中的持续评估在配置变更时充当质量关卡。
- 部署阶段由 Claude 依据 REVIEW.md 评审 PR 并响应 @claude 提及推送修复，但编写代码的智能体无法批准代码，批准仍由人类通过分支保护给出。
- CI/CD 中智能体在沙箱内以短期受限令牌运行，部署能力通过 MCP 以允许清单方式暴露，自主权按环境分级，智能体可以行动直至生产环境闸门但不能越过。
- 维护阶段由确定性脚本监控控制带，按 1σ 记录、2σ 只读诊断、3σ 提交 PR 或触发预批准运行手册的层级响应，突破后写出 intent.md 使循环自我驱动。
- Claude Tag 让智能体以自身身份进驻 Slack 等沟通频道充当第一响应者，小范围修复走 PR 评审关卡，更大的工作则写成 intent.md 回到规划阶段。

## 正文

#### 代码不再是瓶颈

> Code is no longer the bottleneck

各家机构已经开始用 AI 以一年前难以想象的速度编写代码，然而围绕代码的各项流程却没有以同样的速度改变。

> Organizations have started using AI to write code at a speed unthinkable one year ago, yet the processes around the code haven't changed at the same pace.

许多工程团队仍然保留着相同的审批关卡、评审、交接和政策，这拖慢了使用 [Claude Code](https://claude.com/product/claude-code) 等智能体编程方案所带来的生产力提升。

> Many engineering teams still have the same approval gates, reviews, handoffs, and policies, stalling productivity gains made by using agentic coding solutions like [Claude Code](https://claude.com/product/claude-code).

软件开发生命周期（SDLC）是将软件从想法推进到生产环境的过程。大多数组织都在运行同样六个阶段的某个版本，涵盖软件的规划、设计、构建、测试、部署和维护。传统上，每个阶段都是由不同角色负责的独立环节。产品经理撰写需求，技术架构师将需求转化为设计，工程师实现这些设计，受监管企业中的 QA 团队对其进行验证，发布团队负责上线，运维团队则监控正在运行的系统。工作通过文档、工单和签字审批在各个阶段之间流转。

> The software development lifecycle (SDLC) is the process that takes software from idea to production. Most organizations run some version of the same six stages, covering planning, design, building, testing, deploying, and maintaining software. Traditionally, each stage is a discrete phase owned by a different role. Product managers write requirements, technical architects turn them into designs, engineers build the designs, QA teams at regulated enterprises verify it, releases teams ship it, and operations monitors what is running. Work moves between the phases through documents, tickets, and sign-offs.

传统的软件开发生命周期（SDLC）流程繁重，目的是确保每一步都有问责和管控。然而，传统 SDLC 的设计初衷是在这样一个时代最大化效率：当时最耗时、最昂贵的阶段是编写和实现代码，而如今情况已不再如此。PRD、估算仪式和产品安全评审之所以存在，都是为了在可能长达数周、数月甚至数个季度的开发工作期间强制达成一致。

> The traditional software development lifecycle (SDLC) is process-heavy to ensure accountability and control at each step. However, the traditional SDLC was designed to maximize efficiency in an era where the most time-consuming and expensive stage was writing and implementing code, which is no longer the case. PRDs, estimation rituals, and product security reviews all existed to force alignment during what could be weeks, months, or quarters of development work.

传统的软件开发生命周期（SDLC）还包含一些默认每一步都由人工完成的管控措施。那些创造出最大价值的组织，已经围绕如今智能体 AI 所能做到的事情重建了自身流程，同时确保人始终参与其中。在本指南中，我们将介绍我们的 Applied AI 团队在 SDLC 各个阶段内部集成 Claude 以加速开发、让流程运转更快的若干最佳实践，这些实践源自我们与客户合作的经验。

> The traditional SDLC also features controls that assume every step is performed by humans. The organizations generating the most value have rebuilt their process around what agentic AI can now do, while ensuring that humans stay in the loop. In this guide, we walk through several of our Applied AI team's best practices for integrating Claude internally across each stage of the SDLC to accelerate development and make processes run faster, inspired by working with our customers.

当代码不再是瓶颈，构建阶段的推进速度超出传统 SDLC 所能容纳的范围时，有三件事会成为现实：

> When code is no longer the bottleneck and the build phase runs faster than the traditional SDLC allows for, three things become true:

- 瓶颈转移到了构建阶段左右两侧的步骤上。这主要是规划、评审/测试和部署，它们仍以人类的速度运行。
- 这些管控措施与现实脱节，变得难以为继。当代码由人编写时，逐行人工审查是合理的；但一旦大部分改动由智能体写就，这种做法便跟不上节奏了。
- 治理成本随之上升，因为例外情况仍需经由每周或每月才召开一次的会议和委员会来处理。

> • The bottleneck moves to the steps to the left and right of the build phase. This is mainly plan, review/test, and deploy, which still run at human speed.
> • The controls stop matching reality and become intractable. Reviewing each line by hand made sense when a person had written it, but it can't keep up once agents write most of the diff.
> • Governance costs increase because exceptions still route through meetings and committees that meet weekly or monthly.

![Build is no longer the constraint — the human-speed steps around it are. Human-speed stages keep their length while build collapses to hours.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8739a1b934ffe55bfc9715_44592f18.png)

让我们以安全瓶颈为例。安全团队的规模是按人类的产出量配置的，因此当智能体使代码产出成倍增长时，要么评审队列不断积压，要么代码在评审不充分的情况下就发布上线。受监管的组织无法接受这两种结果中的任何一种，因此其安全与合规检查必须跟上智能体的节奏。

> Let's use a security bottleneck as an example. Security teams are sized for human output, so when agents multiply code output, either the review queue builds or code ships under-reviewed. A regulated organization can't accept either outcome, so its security and policy checks have to keep pace with the agents.

为了更好地实现智能体 AI 带来的生产力提升并保障其安全，传统的 SDLC 生命周期需要经历与实施阶段已经历过的同等程度的变革。

> To better realize the productivity gains of and secure agentic AI, the traditional SDLC lifecycle requires the same level of transformation as the implementation phase has undergone.

1. [代码不再是瓶颈](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-c1)
2. [剧本](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-c2)
3. [阶段 1 — 规划](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s1)
4. [第 2 阶段 —— 设计](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s2)
5. [第 3 阶段 —— 构建](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s3)
6. [阶段 4 — 测试](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s4)
7. [阶段 5 — 部署](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s5)
8. [阶段 6 — 维护](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s6)
9. [结语](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-c9)

> 1\. [Code is no longer the bottleneck](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-c1)
> 2\. [Plays](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-c2)
> 3\. [Stage 1 — Plan](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s1)
> 4\. [Stage 2 — Design](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s2)
> 5\. [Stage 3 — Build](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s3)
> 6\. [Stage 4 — Test](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s4)
> 7\. [Stage 5 — Deploy](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s5)
> 8\. [Stage 6 — Maintain](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-s6)
> 9\. [Closing thoughts](https://claude.com/blog/the-ai-native-sdlc-playbook#sd-c9)

##### 什么是 AI 原生的软件开发生命周期（SDLC）？

> What is an AI-native SDLC?

AI 原生的 SDLC 是一种重新构想的流程，它将过去的控制目标与新的强制执行手段结合起来。流程不再是线性的，而是变成一个循环，并且 AI 被嵌入到每一个环节。AI 原生的 SDLC 推动自动化的交接以及后续动作的触发，有助于解决传统 SDLC 各阶段之间交接时人工操作多、过程笨拙的问题。

> The AI-native SDLC is a reimagined process that combines the old control objectives with new enforcement. Instead of a linear flow, the process becomes a loop, and AI is embedded at each point. The AI-native SDLC promotes automated handover and triggering of subsequent plays, helping to address the manual and clunky nature of handoff between the phases of the traditional SDLC.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8858c2eccce183e7553cf2_53b010df.png)

##### 这些变化

> The shifts

下表列出了传统 SDLC 与由 Claude 支持的 AI 原生 SDLC 两个极端之间的对比。大多数组织处于这两列之间的某个位置。

> The table below highlights the ends of the spectrum between traditional SDLC and AI-native SDLC, supported by Claude. Most organizations sit somewhere between the two columns.

| 阶段 | 传统软件开发生命周期 | AI 原生软件开发生命周期 |
| --- | --- | --- |
| 计划 | 由委员会收集需求，经过研讨会和签字确认层层提炼，再手工撰写成文 | Claude 直接从源材料中提炼出痛点，并将其记录在 intent.md 中，该文件既便于人类阅读，也可供机器执行 |
| 设计 | 由分析师编写规范，由设计师解析 | 需求与设计压缩进与智能体的一次工作会话中，由编码为技能的标准来引导，并在 git 中进行版本管理 |
| 构建 | 测试和代码为手工编写，文档在主要开发工作完成之后撰写 | 测试和代码由 AI 生成，机构知识以版本化的机器可读 CLAUDE.md 文件和技能的形式维护 |
| 测试 | 阶段边界处的质量保证关卡 | 贯穿实现过程的持续评估 |
| 部署 | 人类审查每一行代码，治理发生在评审周期中，且往往缺乏一致性 | 多层智能体评审，人工评审仅保留给受监管代码和关键代码。治理在 AI 执行操作的同时强制实施，以钩子作为审批关卡 |
| 维护 | 由人工监控生产环境中的缺陷 | 智能体监控实时部署。任何被突破的控制带都会被诊断，并作为新的 intent.md 写回循环中 |

> 英文原表 / English original

| Stage | Traditional SDLC | AI-native SDLC |
| --- | --- | --- |
| Plan | Requirements gathered by committee, distilled through workshops and sign-offs, written up by hand | Claude synthesizes pain points straight from the sources and captures them within intent.md which is human readable and machine actionable |
| Design | Spec written by analysts, parsed by designers | Requirements and design compressed into one working session with an agent, guided by standards encoded as skills, versioned in git |
| Build | Tests and code are handwritten and documentation is written after the main development happens | Tests and code are generated by AI and institutional knowledge is maintained as versioned machine-readable CLAUDE.md files and skills |
| Test | QA gates at stage boundaries | Continuous evals woven through implementation |
| Deploy | Humans review every line of code and governance occurs in review cycles, often inconsistently | Layers of agentic review with human review reserved for regulated and critical code. Governance is enforced as the AI acts, with hooks as approval gates |
| Maintain | Humans watch production for bugs | Agents monitor live deployments. Any breached control band is diagnosed and written back into the loop as a new intent.md |

贯穿右侧栏的主线是已提交的产物。每个阶段都以将一份产物写入版本控制作为结束（包括 `intent.md`、`spec.md`、`plan.md`、diff 及其测试、附带评审意见的 PR，以及事故记录），而下一个阶段则以读取它作为开始。对于早期阶段，.md 文件是主要的产物形式，因为产品负责人和智能体都能读取同一个文件并据此行动。从 Build 阶段开始，产物就是代码及其记录。这条提交链同时也是审计轨迹：谁提出了什么要求、智能体产出了什么，以及谁批准了它。

> The thread running through the right-hand column is the committed artifact. Each stage ends by writing one to version control (including `intent.md`, `spec.md`, `plan.md`, the diff and its tests, the PR with its review findings, and the incident record) and the next stage begins by reading it. For the early stages, .md files are the predominant artifact because a product owner and an agent can both read and act on the same file. From Build onward, the artifact is code and its records. The chain of commits is also the audit trail: who asked for what, what the agent produced, and who approved it.

人类仍然要对每一个需要判断力的决策负责。在智能体驱动的软件开发生命周期（SDLC）世界中，人类的注意力会随着必须审查的产物一同转移。

> Humans remain accountable for every decision that requires judgment. In the agentic SDLC world, the human attention shifts along with the artifacts that must be reviewed.

#### 剧本

> Plays

这些实践是本手册的核心，被划分为六个非线性阶段（规划、设计、构建、测试、部署、维护），它们共同涵盖了完整的生命周期。

> The plays are the core of the playbook and are grouped into six non-linear stages (Plan, Design, Build, Test, Deploy, Maintain), which together cover the complete lifecycle.

每个方案涵盖：

> Each play covers:

- 有哪些变化；
- 入门；
- 实施的具体步骤；
- 治理方面的考量；以及
- 你如何衡量它是否奏效。

> • What changes;
> • Getting started;
> • Concrete steps for implementation;
> • Governance considerations; and
> • How you measure whether it worked.

这些步骤是模块化的，各组织可以根据自身的独特需求，选择在不同时间优先转型不同的阶段。每个策略在“前提条件”下列出了其依赖项，依赖关系图对此作了进一步说明。

> These steps are modular and organizations may choose to prioritize transforming different stages at different times based on their unique needs. Each play names its dependencies under "Prerequisites," which the dependency graph further illustrates.

一个阶段以提交产物告终，而该提交会启动下一个阶段。被接受的 `intent.md` 触发需求与设计环节，获批的 `spec.md` 触发计划模式，合并的 PR 触发流水线，而生产环境中被突破的控制带会写出下一个 `intent.md`，循环由此继续。

> A stage ends by committing an artifact with the commit initiating the next stage. An accepted `intent.md` triggers the requirements and design pass, an approved `spec.md` triggers plan mode, a merged PR triggers the pipeline, and a breached control band in production writes the next `intent.md` and so the loop continues.

首先，你手动为每一步编写提示词，最终状态是一个循环：每个被接受的产出物都会触发下一道关卡。人的注意力集中在这些关卡上，审阅智能体标记出来的内容，而不是从零开始进入每个阶段。

> First, you prompt each step by hand with the end state being a loop in which each accepted artifact fires the next gate. Human attention concentrates at the gates, reviewing what the agent flagged rather than starting each stage from scratch.

![The plays are listed with stage; the arrows give the order to adopt them in. The two are not the same. Start with any clay play — nothing points into it, so it needs nothing first. For any other play, the arrows pointing into it are the plays to adopt before it.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8855c75344623fc81efcb8_5d5a3c05.png)

#### 计划

> Plan

##### 记录为 intent.md

> Capture as intent.md

`intent.md`启动了软件开发流程，它可以通过不同的途径进入。有人提出一个想法，有人提交了一个工单，或者通过告警暴露出一次事故（参见第 6 阶段：维护）。

> The `intent.md`, which kicks off the software development process can enter through different routes. A person has an idea, a ticket is filed, or an incident is surfaced via an alert (see Stage 6: Maintenance).

当一个人有了想法时，他们会与 Claude 一起头脑风暴，产出一份 markdown 格式的初步规格草案。而在传统的软件开发生命周期（SDLC）中，同一个人必须先说服产品团队的某位成员，与自己一起或代表自己把这个想法写成文档。

> When a person has an idea, they brainstorm with Claude and produce a markdown proto-spec. In the traditional SDLC, the same person must then convince a member of the product team to write the idea up with them or on their behalf.

由 Claude 生成的原型规范（proto-spec）可供人类阅读、纳入版本控制，并且可以立即被下一阶段直接使用。该原型规范会保存为一个 `intent.md`。

> The proto-spec generated by Claude is human readable, version-controlled, and immediately consumable by the next stage. The proto-spec is saved as an `intent.md`.

无论意图来自事件触发还是来自智能体，适用的步骤都是相同的：产品负责人在提交之前，会审阅并修正由智能体编写的 `intent.md`。

> Regardless of whether the intent originates from an event trigger or an agent, the same steps apply: the product owner reviews and corrects the agent-written `intent.md` before it is committed.

搭建这套机制对平台团队或工程团队而言是一次性的工作。需要有一位技术人员来建立意图存放地，并决定谁可以向其中写入内容，因为许多贡献者会来自组织的各个部门。

> Setting this up is a one-time task for the platform or engineering team. A technical team member needs to stand up the intent home and decide who can write to it, since many contributors will come from across the organization.

仓库建好之后，没有 git 经验的贡献者也无需直接使用 git。取而代之的是，一个连接到版本控制系统（例如 GitHub）的连接器可以让 Claude 代表他们从 claude.ai 或 Cowork 提交 markdown 文件。

> Once the repository exists, contributors without git experience don't need to use git directly. Instead a connector to the version-control system (e.g. GitHub) lets Claude commit markdown files on their behalf from claude.ai or Cowork.

###### 如何执行

> How to execute it

1. 发起人用自己的话向 Claude 描述问题。发起人可以描述他们今天做不到什么、这个想法会影响到谁、更好的状态是什么样子，或者什么不在范围内。不需要使用正式的语言。
2. 反复头脑风暴，直到想法足够具体。Claude 会提出分析师会问的那些问题：范围、用户、约束条件，以及成功是什么样子。
3. 请 Claude 使用组织的模板将结果写成 `intent.md`，该模板可以编码为由技术团队成员搭建、并由负责人签署确认的技能。它可以涵盖问题、预期成果、受影响的用户和系统、约束条件以及未解决的问题。
4. 发起者会纠正 Claude 误解的任何内容。
5. 将 `intent.md` 提交到共享主页。作者和时间戳会一并记入该记录，产品负责人随后从那里接手这个想法。

> 1\. The originator describes the problem to Claude in their own words. The originator may describe what they cannot do today, who is affected by the idea, what better looks like, or what is out of scope. No formal language is required.
> 2\. Brainstorm until the idea is concrete. Claude asks the questions an analyst would ask: scope, users, constraints, and what success looks like.
> 3\. Ask Claude to write the result as `intent.md` using the organization's template, which can be encoded as a skill set up by a technical team member and signed off by a lead. This can cover the problem, proposed outcome, affected users and systems, constraints, and open questions.
> 4\. The originator corrects anything Claude misunderstood.
> 5\. Commit `intent.md` to the shared home. Author and timestamp join the record, and the product owner picks the idea up from there.

```markdown
# Intent: claims status self-service
Author: J. Ortiz (claims operations). Status: draft.

## Problem
Customers phone the contact center to ask where their claim is.
Handlers spend roughly a third of call time on status-only queries.

## Proposed outcome
Customers see claim status, next step and expected date in the portal.

## Affected users and systems
Claims handlers, portal team, claims-core API.

## Constraints
No new PII in the portal session. Existing authentication only.

## Open questions
Do third-party loss adjusters need access too?
```

###### 治理方面的考量

> Governance considerations

证据是已提交的 `intent.md`，其中列出了作者、时间戳和完整的修订历史。它记录在 intent home 的 git 历史中。产品负责人进行审批，而将该 intent 送入第 2 阶段：设计的接受或拒绝决定，则记录为合并或结束评审。

> The evidence is the committed `intent.md`, which lists the author, the timestamp and the full revision history. It's logged in the git history of the intent home. The product owner approves, and the accept or reject decision that sends the intent into Stage 2: Design is recorded as the merge or the closing review.

#### 设计

> Design

##### 需求与设计

> Requirements and design

一旦获得产品负责人的批准，Claude 就会接收已确认的 `intent.md`，并生成需求与设计规范。这一过程由组织在品牌、安全、合规和用户体验方面的[技能](https://code.claude.com/docs/en/skills)提供指导。

> Once approved by the product owner, Claude takes the accepted `intent.md` and produces a requirements and design spec. This is guided by the organization's [skills](https://code.claude.com/docs/en/skills) for brand, security, compliance, and UX.

产品负责人会审阅这份规格说明，但并不负责撰写。这一流程的目标是产出一份工程团队可以据以制定计划的规格说明，并标注出需要关注的问题点。

> The product owner reviews that spec, but doesn't write it. The goal of this process is to create a spec the engineering team can plan against, with flagged areas of concern.

前端工作是最清晰的例子。一旦 `intent.md` 获得通过，产品负责人就会用 `intent.md` 中的 [Claude Design](https://claude.com/product/design)（测试版）把设计稿做出来，对该设计稿进行迭代，然后将其导出到 Claude Code 中进行构建。

> Front-end work is the clearest example. Once the `intent.md` is accepted, the product owner mocks the design up in [Claude Design](https://claude.com/product/design) (beta) from the `intent.md`, iterates on the mock, and then exports it to Claude Code to build.

###### 如何执行

> How to execute it

1. 产品负责人在组织可用技能的情况下打开一个会话，并附加了 `intent.md`。
2. 产品负责人提示词指向 `intent.md`，点明各项约束，并要求标记出存疑之处。一开始先手动运行它，之后再将其固化为组织级的斜杠命令。在此基础上，把意图归属地中 `intent.md` 的接受作为触发条件，用一个在合并时触发的非交互式任务，在加载了组织技能的情况下运行该流程，并将 `spec.md` 以拉取请求的形式提交（第 5 阶段：部署 中的 CI/CD 实操涵盖了相关的管道搭建）。从这时起，产品负责人首次介入的环节就是评审。
3. 同一位产品负责人会对照最初的想法审查这份规格说明。该规格说明是否解决了所陈述的问题？来自 `intent.md` 的开放性问题是否已得到回答或被延续下来？
4. 先处理被标记出的问题，因为这些正是分析师会上报升级的要点。产品负责人会在工程团队看到规格说明之前，与各自的政策负责人逐一解决这些问题。
5. 将 `spec.md` 与 `intent.md` 一并提交。这一对文件记录了所提出的要求以及所做出的决定。
6. 产品负责人决定规格与意图是否进入构建阶段，并就组织认定风险较高的任何事项咨询技术负责人。这一决定始终由人类团队成员做出，而接受规格正是启动第三阶段「构建」中计划模式环节的动作。

> 1\. The product owner opens a session with the organization's skills available and attaches the `intent.md`.
> 2\. The product owners prompt points at the `intent.md`, names the constraints, and demands flagged concerns. Run it by hand at first, then codify it as an organization-level slash command. From there make the acceptance of `intent.md` in the intent home the trigger, with a non-interactive job that fires on the merge, run the pass with the organization's skills loaded, and commit `spec.md` as a pull request (the CI/CD play in Stage 5: Deploy covers the plumbing). From that point the product owner's first involvement is the review.
> 3\. The same product owner reviews the spec against the idea. Does the spec solve the stated problem, and are the open questions from `intent.md` answered or carried forward?
> 4\. Work through the flagged concerns first as they are the points an analyst would have escalated. The product owner resolves each one with its policy owner before engineering sees the spec.
> 5\. Commit `spec.md` alongside `intent.md`. The file pair records what was asked for and what was decided.
> 6\. The product owner decides whether the spec and intent progress to build, consulting a technical lead for anything the organization classes as higher risk. A human team mate always makes this call, and accepting the spec is what starts the plan mode play in Stage 3: Build.

###### 它看起来是什么样的（提示词）

> What it looks like (the prompt)

```markdown
Read the attached intent.md and produce a requirements and design spec for integrating it into our existing codebase. Apply the skills available to you so the plan conforms to our brand guidelines, security policies and UX standards. Document the spec fully as spec.md, ready to hand to the engineering team. Describe clearly any areas of concern, especially where you cannot satisfy contradicting policies.
```

###### 治理层面的考量

> Governance considerations

实时策略不再是几周后才在评审中被发现，而是在编写规格说明的同时就被读取并应用。组织的技能被作为约束条件施加于规格说明之上。规格说明、生成它的提示词，以及生效的技能版本，全部记录在版本控制中。产品负责人签署确认规格说明，并将标记出的问题分派给指定的策略负责人。

> Instead of being discovered in a review weeks later, the live policy is read and applied while the spec is written. The organization's skills are applied as constraints on the spec. The spec, the prompt that produced it, and the skill versions in force are all logged in version control. The product owner signs off the spec, and routes flagged concerns to the named policy owners.

#### 构建

> Build

##### 将 Claude Code 的计划模式作为默认的起点

> Claude Code plan mode as the default starting point

工程师在[计划模式](https://code.claude.com/docs/en/permission-modes)下启动 Claude Code 会话，把第二阶段“设计”中已批准的 `spec.md` 交给 Claude，让它对自己进行访谈，并不断迭代该计划，直到工程师满意为止。

> Engineers start Claude Code sessions in [plan mode](https://code.claude.com/docs/en/permission-modes), give Claude the approved `spec.md` from Stage 2: Design, and let it interview them, iterating on the plan until the engineer is happy with it.

###### 如何执行它

> How to execute it

1. 工程师使用 Claude 在计划模式下开始了本次会话。
2. 工程师把 `intent.md` 和 `spec.md` 交给 Claude，并要求它给出一份实施计划，其中要指明会改动哪些文件、工作的先后顺序，以及用来证明其有效的测试。
3. 审视这份计划，问一问：这项改动可能会破坏什么，哪一步风险最大，以及 Claude 放弃了哪些其他选项。
4. 不断迭代，直到一位从未看过这段对话的工程师仅凭该计划就能实现这项变更。
5. 将批准的计划提交为 `plan.md`。该计划会加入审计追踪，PR 评审流程（阶段 5：部署）会据此核对最终的差异。
6. 接受该计划并让 Claude 实施。有了扎实的计划，实施通常一次即可完成。
7. 当实施偏离计划时，在同一次提交中更新 `plan.md`。可以考虑使用钩子来强制两者保持同步。

> 1\. The engineer starts the session in plan mode with Claude.
> 2\. The engineer gives Claude the `intent.md` and the `spec.md` and asks for an implementation plan that names the files that change, the order of the work, and the tests that prove it.
> 3\. Interrogate the plan by asking what the change could break, which step is most risky, and what other options Claude chose not to do.
> 4\. Iterate until an engineer who has never seen the conversation could implement the change from the plan alone.
> 5\. Commit the approved plan as `plan.md`. The plan joins the audit trail, and the PR review play (Stage 5: Deploy) checks the eventual diff against it.
> 6\. Accept the plan and let Claude implement. With a solid plan, the implementation is often a single pass.
> 7\. When implementation departs from the plan, update `plan.md` in the same commit. Consider using a hook to enforce synchronization between the two.

###### 示例（plan.md）

> What it looks like (plan.md)

```markdown
# Plan: claims status self-service (from intent.md 2026-06-02)

## Files that change
portal/src/claims/StatusPanel.tsx (new), claims-api/routes/status.py,
claims-api/tests/test_status.py

## Order of work
1. Add the status endpoint behind existing auth.
2. Panel against the endpoint.
3. Wire into the portal nav.

## Risks
The claims-core API rate-limits at 50 rps; the panel must cache.

## Proof
test_status.py covers the four claim states; screenshot matches the
approved mock.
```

###### 治理方面的考量

> Governance considerations

设计评审发生在生成任何代码之前，此时要改变方向仍只需编辑文档。计划模式本身会强制执行这一点，因为在工程师接受计划之前，Claude 无法编辑文件。计划及其修订记录都会被保留，同时还会记录由谁接受。常规变更由工程师批准，组织归类为较高风险的任何变更则交由技术负责人或架构师审批。

> Design review happens before any code is generated, when changing course is still a matter of editing a document. Plan mode enforces this itself, since Claude cannot edit files until the engineer accepts the plan. The plan and its revisions are logged along with who accepted it. Routine changes are approved by the engineer, and anything the organization classes as higher risk goes to a tech lead or architect.

##### 自动模式下的 Claude Code

> Claude Code on auto mode

Claude Code 也可以在自动模式下运行：工程师批准计划，并在对经过迭代的计划感到满意后，由 Claude 应用每项变更，无需逐次提示确认编辑。随着后续实践中的防护措施逐渐成熟（经过调优的 `CLAUDE.md`、将政策编码其中的技能、阻止不安全操作的钩子，以及 Claude 可以运行的测试套件），自动接受会成为常规工作的默认方式：明确的 `spec.md`、较小的影响范围，以及已有测试覆盖的代码。

> Claude Code can also run in auto mode, where the engineer approves the plan and, once happy and iterated upon, Claude applies each change without a per-edit prompt. As the guardrails from the later plays mature (a tuned `CLAUDE.md`, skills that encode policy, hooks that block unsafe actions, and a test suite Claude can run), auto-accept becomes the default for routine work: a tight `spec.md`, a small blast radius, and code the tests already cover.

现在的转变是：不再由用户看着智能体进行编辑并审查其操作，而是在更长时间的自主会话结束后审查产物。与工作树结合使用时，自动接受模式还能进一步促进个人之间和团队内部的并行工作，并且是自主运行软件开发生命周期、按照第 6 阶段“维护”中的描述实现闭环的基础。

> The shift is now away from the user watching the agent make the edits and reviewing actions, towards the review of artifacts after longer autonomous sessions. Auto-accept mode further enables parallelism across individuals and the team when used with worktrees and is fundamental to running the SDLC autonomously and closing the loop as described in Stage 6: Maintenance.

##### 遗留系统与事实来源

> Legacy systems and the source of truth

##### CLAUDE.md

> The CLAUDE.md

[CLAUDE.md](https://code.claude.com/docs/en/memory) 为 Claude 提供新成员所需的上下文，涵盖约定、命令、架构，以及团队最常遇到的错误。过去存在于人们头脑和 Wiki 中的知识，转化为智能体每次会话开始时都会读取的文件，由整个团队共同维护，并在每次出现错误时持续完善。

> [CLAUDE.md](https://code.claude.com/docs/en/memory) gives Claude the context a new joiner would need, covering conventions, commands, architecture, and the mistakes the team sees most often. Knowledge that used to sit in people's heads and on wikis becomes a file the agent reads at the start of every session, maintained by the whole team and iterated on whenever a mistake is made.

###### 如何执行

> How to execute it

1. 在代码库中运行 `/init`。Claude 会根据发现的内容生成一份初始 `CLAUDE.md`。
2. 精简生成的文件，只保留新成员入职第一天需要的内容。保留构建、测试和代码检查命令、重要约定，以及 Claude 经常出错的事项。
3. 将 `CLAUDE.md` 签入代码库根目录的 git 中，使整个团队共享同一个版本，并像评审代码一样评审变更。
4. 这里有一条实用规则：当 Claude 两次犯下同一个错误时，就把纠正方法写入 `CLAUDE.md`。
5. 将其控制在一页以内，因为 Claude 会在会话开始时读取全部内容，任何过时内容只会占用上下文而毫无益处。

> 1\. Run `/init` in the repo. Claude generates a starting `CLAUDE.md` from what it finds.
> 2\. Cut the generated file down to what a new joiner would need on day one. Keep the build, test and lint commands, the conventions that matter, and the things Claude keeps getting wrong.
> 3\. Check `CLAUDE.md` into git at the repo root so the whole team shares one version and changes are reviewed like code.
> 4\. A working rule helps here. When Claude makes a mistake twice, the correction goes into `CLAUDE.md`.
> 5\. Keep it under a page, because Claude reads all of it at the start of a session and anything stale is taking up context for no benefit.

###### 示例（CLAUDE.md）

> What it looks like (CLAUDE.md)

```javascript
# Payments service

## Commands
- Build: make build
- Test: make test (unit), make itest (integration, needs docker)
- Lint: make lint (runs in CI; fix before pushing)

## Conventions
- Java 21, Spring Boot 3. No new Lombok.
- Money is always BigDecimal, never double.
- Every endpoint needs an integration test in src/itest.

## Architecture
- api/ holds REST controllers, core/ holds domain logic,
  adapters/ talks to external systems.
- Kafka events are defined in schemas/; never edit generated classes.

## Things Claude gets wrong
- Do not bump dependency versions; the platform team owns them.
- The legacy v1/ package is frozen; changes go in v2/.
```

###### 治理方面的考量

> Governance considerations

`CLAUDE.md` 受版本控制，因此智能体遵循的指令可供评审和审计。团队约定通过该文件应用，对文件的变更记录在 git 历史中，并由代码所有者在 PR 评审中批准这些变更。

> `CLAUDE.md` is version controlled, so the instructions the agent works to are reviewable and auditable. Team conventions are applied through the file, changes to it are logged in git history, and code owners approve those changes in PR review.

##### 作为组织知识的技能

> Skills as institutional knowledge

技能是组织将其组织知识付诸实践的方式。这些指令明确、受版本控制、得到广泛应用，并在政策变化时集中更新。经验法则是：对于必须一致应用的组织知识，应编写技能；对于应放在 `CLAUDE.md` 或提示词中的内容，则不要编写技能。

> Skills are how an organization makes its institutional knowledge operational. The instructions are explicit, version-controlled, applied broadly, and updated centrally when policy changes. The rule of thumb: write a skill for institutional knowledge that must be applied consistently; don't write a skill for components that belong in `CLAUDE.md` or a prompt.

###### 如何执行

> How to execute it

1. 选择一项当前执行不一致的知识。它可以是一项安全标准、一项 API 设计约定或一条品牌规范。
2. 将其编写成一个技能，即一个包含 `SKILL.md` 的文件夹；该文件的前置元数据说明何时触发，正文则说明要做什么。工程师以政策所有者的事实来源为依据，在 Claude 的协助下编写它。
3. 将技能放入仓库的 `.claude/skills/<name>/` 中，使其随代码一同交付；或者通过[插件](https://code.claude.com/docs/en/plugin-marketplaces)在整个组织范围内分发。
4. 测试技能能否被触发。用不同的方式让 Claude 执行相关任务，并确认每次都会加载该技能。
5. 当策略发生变化时，更新技能，并让策略负责人批准这一变更。
6. 工程师会在下一次会话中自动获取新版本。

> 1\. Pick one piece of knowledge that is enforced inconsistently today. This could be a security standard, an API design convention, or a brand rule.
> 2\. Write it as a skill, a folder containing a `SKILL.md` whose frontmatter says when it triggers and whose body says what to do. An engineer writes it from the policy owner's source of truth, using Claude to help.
> 3\. Put the skill in the repo at `.claude/skills/<name>/` so it ships with the code, or distribute it organization-wide through a [plugin](https://code.claude.com/docs/en/plugin-marketplaces).
> 4\. Test that the skill triggers. Ask Claude to do the relevant task in different ways and confirm the skill loads each time.
> 5\. When the policy changes, change the skill and have the policy owner sign off the change.
> 6\. Engineers pick up the new version automatically in their next session.

###### 示例（.claude/skills/secure-api-review/SKILL.md）

> What it looks like (.claude/skills/secure-api-review/SKILL.md)

```markdown
---
name: secure-api-review
description: Apply the API security standard. Use whenever creating or
  modifying an external-facing endpoint, reviewing API code, or
  generating an OpenAPI spec.
---
# Secure API review

When you create or change an API endpoint:
1. Authentication: every endpoint requires the gateway JWT;
   no anonymous routes outside /health.
2. Input validation: validate request bodies against the OpenAPI
   schema and reject unknown fields.
3. Audit: every state-changing endpoint emits an audit event with
   actor, action, entity and timestamp.
4. Data classification: fields tagged pii in the schema must never
   appear in logs or error messages.

Run scripts/check-endpoints.sh and include its output in your summary.
```

###### 治理方面的考量

> Governance considerations

技能是一种控制措施，但属于建议性控制。它会让 Claude 更有可能在编写代码时应用该策略，但没有任何机制强制会话遵守策略。对于必须始终得到遵守的策略，需要在技能背后设置确定性机制，例如阻止相关操作的钩子，或在 PR 阶段重新检查策略的审查流程。技能让违规变得少见，而钩子则让违规近乎不可能发生。技能调用会记录在会话追踪中，策略负责人会像审查代码一样审查技能变更。

> A skill is a control, though an advisory one. It makes Claude likely to apply the policy while the code is written, and nothing forces a session to comply with it. A policy that must always hold needs something deterministic behind the skill, such as a hook that blocks the action or a review pass that re-checks the policy at the PR. The skill makes violations rare and the hook makes them close to impossible. Skill invocations are logged in session traces, and the policy owner reviews skill changes like code.

##### 作为构建时护栏的钩子

> Hooks as build-time guardrails

技能是建议性控制，而[钩子](https://code.claude.com/docs/en/hooks)是其背后的确定性层。Claude 的大多数操作都是实现过程中的文件编辑和 shell 命令，因此构建阶段往往是钩子触发最频繁的阶段。

> A skill is an advisory control while a [hook](https://code.claude.com/docs/en/hooks) is the deterministic layer behind it. Most of Claude's actions are file edits and shell commands during implementation, so the build phase is where hooks can end up firing most often.

构建阶段的钩子可以：

> Build-phase hooks can:

- 阻止编辑受保护的路径，例如生成的类或已冻结的软件包；
- 在编辑文件后运行格式化工具和代码检查工具，避免偏差不断累积；
- 防止凭据进入差异内容。

> • Block edits to protected paths such as generated classes or a frozen package;
> • Run the formatter and linter after file edits so drift never accumulates;
> • Keep credentials out of the diff.

对于策略必须无一例外得到遵守的技能，都应为其配备钩子。钩子会在每个匹配的操作上运行，因此构建阶段的钩子应当快速，并将范围限定在发生变更的文件。完整测试套件等较重的检查应放在提交或 PR 阶段执行。

> Back any skill whose policy has to hold without exception. A hook runs on each action that matches it, so build-phase hooks should be fast and scoped to the file that changed. Heavier checks such as the full test suite belong at the commit or the PR.

需要请求人工批准的钩子应与第 5 阶段“部署”中的门禁放在一起，因为在构建过程中弹出批准提示，会让人工重新回到所有并行会话的关键路径上。

> A hook that asks a human for approval belongs with the gates in Stage 5: Deploy, because an approval prompt during the build puts a person back on the critical path of all the sessions running in parallel.

##### 并行会话和子代理

> Parallel sessions and subagents

一名工程师可以同时推进多条工作流。

> One engineer can drive several streams of work at once.

并行会话是另一个完整的 Claude Code 实例，它在自己的 [git worktree](https://code.claude.com/docs/en/worktrees) 中处理一项独立任务。每个独立会话都对其他会话一无所知，它们唯一共享的是负责引导这些会话的工程师。

> A parallel session is another full Claude Code instance, working a separate task in its own [git worktree](https://code.claude.com/docs/en/worktrees). Each independent session knows nothing about the others, and the engineer steering them is the only thing they share.

[子代理](https://code.claude.com/docs/en/sub-agents)在单个会话内作为限定范围的助手运行，拥有自己的上下文窗口和工具限制，适合处理会在多个任务中重复出现的工作，例如验证应用是否按预期运行。

> A [subagent](https://code.claude.com/docs/en/sub-agents) runs inside a single session as a scoped helper with its own context window and tool limits and suits jobs that recur in multiple tasks such as verifying the app runs as expected.

并行会话增加了工程师可以同时推进的任务数量，而子代理则让每个会话都专注于自己的任务。工程师的职责是引导并审查所有这些工作。

> Parallel sessions raise the number of tasks an engineer can have in flight, while subagents keep each session focused on its own task. The engineer's job is steering and reviewing all of them.

###### 如何执行

> How to execute it

1. 工程师将工作拆分为会修改不同文件的任务，并使用计划模式实践（第 3 阶段：构建）生成的计划来判断哪些工作彼此独立。会修改相同文件的任务则在同一会话中依次运行。
2. 每个并行任务都使用自己的 worktree，例如在一个终端中使用 `claude --worktree feature-auth`，在另一个终端中使用 `claude --worktree fix-rate-limit`。worktree 是位于独立分支上的单独检出目录，可防止各会话在文件上发生冲突。
3. 从两到三个会话开始比较合理。实际的上限取决于一个人能够妥善审查多少条工作流，因此只有在审查进度能够跟上的情况下才应增加会话。
4. 将重复性工作转化为子代理，并在 `.claude/agents/` 中的 markdown 文件里定义它们；每个子代理都应包含名称、适用场景说明以及它可以使用的工具。例如：在主代理完成工作后去除不必要复杂性的代码简化器；运行应用并检查行为的验证器；探索代码库并汇报结果、同时避免主上下文被大量信息淹没的研究器。将这些定义提交到 git，使整个团队能够共享。

> 1\. The engineer splits the work into tasks that touch different files, using the plan from the plan mode play (Stage 3: Build) to see where the work is independent. Tasks that share files run in a single session, one after another.
> 2\. Each parallel task gets its own worktree, for example `claude --worktree feature-auth` in one terminal and `claude --worktree fix-rate-limit` in another. A worktree is a separate checkout on its own branch, which stops sessions colliding on files.
> 3\. Two or three sessions is a sensible starting point. The practical ceiling is how many streams one person can review properly, so add sessions only while review is keeping up.
> 4\. Turn repeated jobs into subagents, as defined in markdown files in `.claude/agents/`, each with a name, a description of when to use it, and the tools it may touch. Examples include a code simplifier that strips needless complexity after the main agent finishes, a verifier that runs the app and checks behavior, a researcher that explores the codebase and reports back without flooding the main context. Check the definitions into git so the whole team shares them.

###### 它看起来是什么样的（.claude/agents/verifier.md）

> What it looks like (.claude/agents/verifier.md)

```javascript
---
name: verifier
description: Runs the app and checks the change works before the session
  reports done
tools: Bash, Read
---
Start the app with make run. Exercise the changed behavior and the two
nearest neighboring flows. Report what you ran, what you saw, and any
behavior that does not match plan.md. Do not fix anything; report only.
```

###### 治理方面的考量

> Governance considerations

更多的会话意味着更多的产出，因此控制手段必须来自仓库中的配置。那里的钩子和权限设置对所有会话生效，而每个会话所做的事情都会被记录，并归属到运行它的工程师名下。

> More sessions means more output, so the controls have to come from configuration in the repo. Hooks and permission settings there apply to all sessions, and what a session does is logged and attributed to the engineer who ran it.

#### 测试

> Test

##### 为 Claude 提供反馈循环

> Give Claude a feedback loop

始终为 Claude 提供一种验证自身工作的方式，无论是测试、构建还是截图对比。这样一次会话就能在工程师看到之前检查自己的工作并修正自己的错误。

> Always give Claude a way to verify its own work, whether tests, a build, or a screenshot diff. A session checks its own work and fixes its own mistakes before an engineer sees them.

不要把反馈循环与验证子智能体（阶段 3：构建）混为一谈。反馈循环会伴随整个任务反复运行，次数与工作量相当。而验证子智能体则是打包最终检查的一种方式：当会话认为工作已经完成时，用一个全新的上下文窗口跑一次检查。这样一来，结论就不会被产出这些代码时所依赖的假设所influence。

> The feedback loop should not be confused with a verifier subagent (Stage 3: Build). The feedback loop runs through the whole task as many times as the work. The verifier subagent, on the other hand, is one way to package the final check by running a fresh context window once the session believes the work is done. This way the verdict is not colored by the assumptions that produced the code.

###### 如何执行

> How to execute it

1. 如果今天检查工作需要一连串命令和一些环境知识，就把它包装成单个目标，比如 "make test" 或 "npm test"，并在失败时以非零状态退出。
2. 在 `CLAUDE.md` 的“命令”一节中，逐条列出每个命令，并附上一个正常输出的示例。
3. 陈述一个目标并使其可量化，这样 Claude 就能自行检查工作成果，而无需询问你，例如：“test_status.py 中的所有测试都通过”“截图与附带的设计稿一致”或“该端点返回 200 并带有新字段”。
4. 修复 bug 时，先写会失败的测试。让 Claude 把这个 bug 复现为一个测试，运行它，并确认它失败的原因正是你所预期的。提交那个测试。只有在此之后，才让 Claude 在不修改测试的前提下让它通过，并用最后一步中的测试文件钩子来强制执行这一限制。一个在修复之前就已存在、且智能体无法重写的测试，就是 bug 已被消除的证明。
5. 对于 UI 相关的工作，要用视觉检查来闭环。给 Claude 一个浏览器或截图工具，把设计稿交给它，让它反复迭代。实现、截图、对比、调整。两到三轮是很正常的，而且每一轮的结果都应该有所改进。
6. 把验证纳入"完成"的定义。相关说明位于 `CLAUDE.md`。在报告任务完成之前先运行测试，并展示输出结果。
7. 最后，循环本身也需要保护，因为修复代码的智能体不能被允许削弱针对该代码的检查。一个在修复任务期间阻止编辑测试文件的钩子就能做到这一点。另一种做法是在评审中检查 diff，并拒绝任何触及测试的改动。

> 1\. If checking the work today takes a sequence of commands and some environment knowledge, wrap it in a single target such as "make test" or "npm test" that exits non-zero on failure.
> 2\. In the `CLAUDE.md`'s Commands section, list each command with an example of a healthy output.
> 3\. State a target and make it quantifiable so Claude can check the work without asking you, for example: "All tests in test_status.py pass," "the screenshot matches the attached mock," or "the endpoint returns 200 with the new field".
> 4\. For bug fixes, write the failing test first. Ask Claude to reproduce the bug as a test, run it, and confirm it fails for the reason you expect. Commit that test. Only then ask Claude to make it pass without editing the test, with the test-file hook from the final step enforcing the restriction. A test that existed before the fix, and that the agent couldn't rewrite, is proof the bug is gone.
> 5\. For UI work, close the loop with a visual check. Give Claude a browser or screenshot tool, give it the mock, and let it iterate. Implement, screenshot, compare, and adjust. Two or three rounds is normal, and the result should improve with each one.
> 6\. Make verification part of "done." Instruction lives in `CLAUDE.md`. Run the tests before reporting a task complete, and show the output.
> 7\. Finally, the loop itself needs protecting, because an agent fixing code must not be able to weaken the check on that code. A hook that blocks edits to test files during a fix task does this. The alternative is to check the diff in review and reject any change that touches a test.

###### 它长什么样（CLAUDE.md 验证块）

> What it looks like (CLAUDE.md verification block)

```javascript
## Verifying your work

- Build: make build (must finish with "Build succeeded")
- Test: make test (all green; never skip or delete a failing test)
- Lint: make lint (zero warnings)

Run all three before reporting any task complete, and paste the output.
If a test fails, fix the code, not the test.
```

##### CI 中的持续评估

> Continuous evals in CI

评估（Evals）是 AI 原生环境下与阶段门式质量保证（stage-gate QA）相对应的东西。在实践中，这意味着一套在智能体配置发生变化时就会运行的测试组合。当换入一个新模型或重写一段提示词时，评估套件会告诉你该智能体是否仍以同样的标准完成工作。

> Evals are the AI-native equivalent of stage-gate QA. In practice that means a suite that runs whenever the agent's configuration changes. When a new model is swapped in or a prompt is rewritten, the eval suite says whether the agent still does the work to the same standard.

评估应被视为一套动态演进的测试集。随着模型能力的提升，曾经具有区分度的用例会失去区分度，因此必须补充从持续监控中发现的新用例。

> The evals should be seen as a live suite. As models improve, cases that once discriminated stop doing so and new ones must be added that arise from ongoing monitoring.

根据具体使用场景，有些团队可能更愿意按固定周期离线运行这些评估，而不是在每次变更时都运行。下面的步骤适用于持续评估。

> Depending on the use case, some teams may prefer to run these evals offline on a set cadence rather than on every change. The steps below are for continuous evaluations.

###### 如何执行

> How to execute it

1. 平台工程师从近期工作中收集 20 到 50 个真实任务，并附上各自的预期/可接受结果。
2. 把每个任务都写成一次评估（eval），也就是提示词加上定义何为合格的检查项（测试通过、lint 无告警、行为不变、遵循规范）。
3. 该测试套件会在 CI 中按计划非交互式运行，并在 `CLAUDE.md`、技能或钩子发生任何变更时运行，因为这些配置会引导 agent 的行为，理应获得与代码同等的回归测试。
4. 根据结果对配置变更设置门禁。如果某项技能改动导致通过率下降，就要在合并前接受审查。
5. 每一次生产环境事故都会催生一个评测，由负责该事故的团队编写，并作为回归测试保留在测试套件中。

> 1\. The platform engineer collects 20 to 50 real tasks from recent work with its expected/accepted outcome.
> 2\. Write each task as an eval, meaning the prompt plus the checks that define acceptable (tests pass, lint clean, behavior unchanged, policy followed).
> 3\. The suite runs non-interactively in CI on a schedule and on any change to `CLAUDE.md`, skills or hooks, since that configuration steers the agent and deserves the regression testing that code gets.
> 4\. Gate configuration changes on the results. A skill change that drops the pass rate gets reviewed before it merges.
> 5\. Each production incident gets an eval, written by the team that owned the incident, and stays in the suite as a regression test.

###### 它看起来是这样的（.github/workflows/agent-evals.yml）

> What it looks like (.github/workflows/agent-evals.yml)

```yaml
name: Agent evals
on:
  pull_request:
    paths: ['CLAUDE.md', '.claude/**']
  schedule:
    - cron: '0 2 * * *'
jobs:
  evals:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g @anthropic-ai/claude-code
      - name: Run eval suite
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          for eval in evals/*.json; do
            claude -p "$(jq -r '.prompt' $eval)" \
              --allowedTools "Read,Edit,Bash(make test)" \
              --output-format json > result.json
            ./evals/check.sh "$eval" result.json
          done
```

###### 治理方面的考量

> Governance considerations

评估为 QA 提供了一道能够跟上智能体产出速度的关卡。通过率阈值以合并检查的形式强制执行，每次运行都会被记录下来以便对结果进行长期对比，并且由拥有该配置变更所有权的团队来批准它。

> Evals give QA a gate that keeps up with agent output. The pass-rate threshold is enforced as a merge check, runs are logged so results can be compared over time, and the team that owns the configuration change approves it.

#### 部署

> Deploy

##### PR 评审流程中的 AI

> AI in the PR review loop

Claude 既进行评审，也接受评审。它会依据组织的规范来评审传入的 PR，并处理自己 PR 上的评审意见。这让工程师能够在 PR 评审中专注于行为本身，而这归根结底就是对意图和风险的判断。

> Claude both gives and receives reviews. It reviews incoming PRs against the organization's policies and addresses review comments on its own PRs. This allows engineers to focus on behavior in their PR review, which boils down to judging intent and risk.

###### 如何执行它

> How to execute it

1. 托管的 Code Review 服务是最快的上手方式。管理员启用它并选择仓库即可。当你需要控制流水线，或希望 API 调用通过自己的云服务协议进行路由时，可以使用 claude-code-action 在你自己的 CI 中运行审查（CI/CD 方案涵盖了这部分的对接细节）。
2. 技术负责人将评审策略写成仓库根目录下的 `REVIEW.md`，并按组织关心的检查项进行划分：缺陷与逻辑错误；安全与漏洞；对规格说明（来自需求实践的 `spec.md`）、实施计划（来自计划模式实践的 `plan.md`）以及设计原则的符合性。`REVIEW.md` 还定义了什么算作 Important（重要问题）而非 Nit（吹毛求疵），以及哪些内容应当跳过。
3. 技术负责人设定人工介入的阈值。检查结果本身不会批准或阻止一个 PR，分支保护仍然要求获得代码所有者的批准。如果平台工程师想根据检查结果来管控合并，可以读取检查运行以机器可读的计数形式发布的严重性数量统计。
4. 当审阅者或作者在某条审阅意见上标注 `@claude` 时，Claude 会处理该意见并推送修复。PR 讨论串同时记录下这次请求和改动。这个修复循环通过 claude-code-action 运行。在托管服务中，评论 `@claude review` 则是请求一次全新的审阅。对于由 Claude 发起的 PR，还可以更进一步，让 Claude 一路照看这个 PR 直到合并。团队会把这个循环封装成一个自定义斜杠命令，扫描 PR 上未解决的审阅意见和未通过的检查项，处理它们并推送修复，直到 PR 全绿、只等代码所有者批准为止。
5. 评审结论会反馈回 `CLAUDE.md`。当某次评审第二次指出同一个错误时，修正内容会作为该次评审的一部分写入 `CLAUDE.md`；由于评审会读取 `CLAUDE.md`，该错误从下一个 PR 起就会被捕获。评审还会指出某项变更是否使 `CLAUDE.md` 变得过时。
6. 技术负责人每月会通过对发现的问题进行评分来调整该配置，从而让审查器不断改进，并在 `REVIEW.md` 中限制 Nit 类问题的数量。生成的路径以及 CI 已经强制检查的内容都会被排除在外。

> 1\. The managed Code Review service is the fastest start. An admin enables it and selects repositories. Run the review in your own CI with the claude-code-action when you need control of the pipeline or want API calls routed through your own cloud agreement (the CI/CD play covers that plumbing).
> 2\. The tech lead writes the review policy as `REVIEW.md` at the repo root, divided into the passes the organization cares about: bugs and logical errors; security and vulnerabilities; compliance against the spec (`spec.md` from the requirements play), the implementation plan (`plan.md` from the plan mode play) and design principles. `REVIEW.md` also defines what counts as Important as opposed to a Nit, and what to skip.
> 3\. The tech lead sets the human threshold. Findings do not approve or block a PR on their own, and branch protection still requires approval from a code owner. A platform engineer who wants to gate merges on findings can read the severity counts that the check run publishes as a machine-readable tally.
> 4\. When a reviewer or the author tags `@claude` on a review comment, Claude addresses the comment and pushes the fix. The PR thread records both the request and the change. This fix loop runs through the claude-code-action. In the managed service, commenting `@claude review` requests a fresh review instead. For PRs Claude opened, go further and let Claude babysit the PR to merge. Teams wrap the loop in a custom slash command that sweeps the unresolved review comments and failing checks on the PR, addresses them and pushes the fixes, until the PR is green and waiting only on code owner approval.
> 5\. Review findings feed back into `CLAUDE.md`. When a review flags a mistake for the second time, the correction goes into `CLAUDE.md` as part of that review, and because review reads `CLAUDE.md` the mistake is caught from the next PR onwards. Review also flags when a change has made `CLAUDE.md` outdated.
> 6\. Once a month the tech lead tunes the setup by rating findings so the reviewer improves and by capping Nit volume in `REVIEW.md`. Generated paths and anything CI already enforces are excluded.

###### 它看起来是什么样子（REVIEW.md）

> What it looks like (REVIEW.md)

```markdown
# Review instructions

## Passes
Run three passes and tag each finding with its pass:
- Bugs: logic errors, broken edge cases, subtle regressions
- Security: injection risks, authentication gaps, PII in logs
- Compliance: the change matches spec.md, plan.md and our design principles

## What Important means here
Reserve Important for findings that would break behavior, leak data
or breach a policy. Style and naming are nits.

## Cap the nits
Report at most five nits per review; summarize the rest as a count.

## Do not report
Generated files under src/gen/ and anything CI already enforces.
```

###### 治理方面的考量

> Governance considerations

职责分离得以保留，因为编写代码的智能体无法批准这些代码。`REVIEW.md` 中的评审策略适用于所有 PR，且发现的问题、修复、评级和批准都记录在 PR 历史中，因此 PR 本身就是审计记录。批准由人类通过分支保护规则给出，并以这些发现作为依据。

> Separation of duties is preserved, because the agent that wrote the code has no way to approve it. The review policy in `REVIEW.md` is applied to all PRs, and findings, fixes, ratings and approvals are logged in the PR history, so the PR is the audit record. Approval comes from a human through branch protection, informed by the findings.

##### 用作审批关卡的钩子

> Hooks as approval gates

构建阶段将钩子用作护栏，在无人参与的情况下允许或阻止操作（阶段 3：构建）。钩子也可以发出询问，暂停操作直到特定人员批准，而这正是发布门控所需要的。

> The build phase used hooks as guardrails, allowing or blocking actions with no human involved (Stage 3: Build). A hook can also ask, pausing the action until a specific person approves, which is what release gating needs.

这个实践之所以被放在第 5 阶段：部署，是因为发布门禁是最清晰的一个用例，但 hooks 并不局限于部署：只要 Claude 在执行操作，hooks 就会运行。例如，在第 3 阶段：构建中，hooks 可以阻止在没有变更单的情况下修改迁移脚本和基础设施；在第 4 阶段：测试中，可以在修复任务期间阻止 agent 编辑测试文件。

> The play sits in Stage 5: Deploy because the release gate is the clearest case, but hooks are not deploy-specific: they run wherever Claude acts. For example, hooks can block edits to migrations and infra without a change ticket during Stage 3: Build, and stop the agent editing test files during a fix task in Stage 4: Test.

###### 如何执行

> How to execute it

1. 工程管理层与变更管理、合规团队一起，列出必须保留的人工审批关卡，例如变更管理签署、发布授权，以及对受保护路径的修改。
2. 平台工程师将每个关卡表达为一个 hook，即一段在 Claude 采取行动之前运行的脚本，它可以允许、询问或阻止该行动。
3. 团队钩子放在 git 中的 `.claude/settings.json`，而不可协商的钩子则放在由平台或 IT 管理员拥有的托管设置中，让个别工程师无法将其关闭。
4. 拦截应当自我说明，因此当钩子阻止某个操作时，原因以及获得批准的途径都会出现在 Claude 的输出中。

> 1\. Engineering leadership, with change management and compliance, lists the human approval gates that must survive, such as change management sign-off, release authorization, and edits to protected paths.
> 2\. The platform engineer expresses each gate as a hook, a script that runs before Claude acts that can allow, ask, or block.
> 3\. Team hooks go in `.claude/settings.json` in git, and non-negotiable hooks go in managed settings owned by the platform or IT admin, where individual engineers cannot switch them off.
> 4\. A block should explain itself, so when a hook stops an action the reason and the route to approval appear in Claude's output.

###### 它长什么样（.claude/settings.json）

> What it looks like (.claude/settings.json)

```json
{
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            { "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/production-gate.sh" }
          ]
        }
      ]
    }
}
```

###### 以及门禁脚本本身（.claude/hooks/production-gate.sh）

> And the gate itself (.claude/hooks/production-gate.sh)

```bash
#!/bin/bash
# Production deploys require a named release authorization
cmd=$(jq -r '.tool_input.command' < /dev/stdin)
if [[ "$cmd" == *"deploy"* && "$cmd" == *"production"* ]]; then
   if [ -z "$RELEASE_APPROVAL" ]; then
     echo "Production deploys need a release authorization." >&2
     exit 2 # exit 2 blocks the action; the message goes to Claude
   fi
fi
exit 0
```

###### 治理方面的考量

> Governance considerations

钩子就是审批关卡。关卡条件每一次都会强制执行，对所有人一视同仁。放行和拦截的决策都会带时间戳记录下来。关卡还定义了什么才算通过审批，无论那是一张已批准的变更工单，还是发布经理的签字确认。

> Hooks are the approval gates. The gate condition is enforced every time, for everyone. Allow and block decisions are logged with a timestamp. The gate also defines what counts as approval, whether that's an approved change ticket or the release manager's sign-off.

##### 面向受监管企业的托管设置

> Managed settings for a regulated enterprise

##### CI/CD 集成与部署

> CI/CD integration and deployment

在 CI/CD 流水线内以非交互方式运行 Claude Code，对执行过程进行沙箱隔离以保证长时间运行的代理安全运行，通过 MCP 集成来开放部署能力，并在代理真正需要之前先演练好回滚路径。

> Run Claude Code non-interactively inside the CI/CD pipeline, sandbox the execution so long-running agents run safely, expose deployment through MCP integrations, and rehearse the rollback paths before the agent ever needs them.

###### 如何执行它

> How to execute it

1. 平台工程师从只读的判断步骤开始。在流水线作业中使用 `claude -p` 来对失败的构建进行分类定位、总结不稳定的测试，或起草变更日志。
2. 在现有的门控之后添加写入步骤，用于处理诸如修复 lint、更新生成的文档，或通过 `@claude` 提及来回应评审意见之类的任务。代理写入的任何内容都会经由分支保护以 PR 的形式提交，代理没有任何途径推送到 main。
3. 执行过程在沙箱中进行。Agent 作业在容器中运行，受网络策略约束，使用短期有效的受限作用域令牌，且默认不持有任何生产环境凭据。
4. 通过 MCP 暴露部署能力。部署、状态查询和回滚都变成工具，并按环境划分作用域，这样智能体的部署权限就是一份允许清单，而不是一个带着凭据的 shell 脚本。
5. 按环境对自主权分级。在开发环境中，代理可以自由部署。在生产环境中，由代理准备发布、发布经理进行授权，并由一个钩子来强制执行生产环境的关卡。预发布环境则介于两者之间。
6. 回滚应当是流水线中演练得最充分的路径——一条智能体可以运行的单一命令，并且在预发布环境中定期执行验证。闭环环节（阶段 6：维护）会在控制带被突破时调用这个回滚，因此它必须事先得到验证。

> 1\. The platform engineer starts with read-only judgment steps. Use `claude -p` in a pipeline job to triage a failed build, summarize a flaky test, or draft the changelog.
> 2\. Add write steps behind the existing gates for jobs like fixing lint, updating generated docs, or addressing review comments via the `@claude` mentions. Anything the agent writes arrives as a PR through branch protection, and the agent has no route to push to main.
> 3\. Execution is sandboxed. Agent jobs run in containers under a network policy with short-lived scoped tokens, and hold no production credentials by default.
> 4\. Expose deployment through MCP. Deploy, status, and rollback become tools, scoped per environment, so the agent's deployment powers are an allowlist rather than a shell script with credentials.
> 5\. Tier the autonomy by environment. In development, the agent deploys freely. In production, the agent prepares the release and the release manager authorizes it, and a hook enforces the production gate. Staging sits somewhere in the middle.
> 6\. Rollback should be the most rehearsed path in the pipeline, a single command that the agent can run and that is exercised regularly in staging. The closing the loop play (Stage 6: Maintenance) calls this rollback when a control band is breached, so it has to be proven in advance.

###### 它看起来是什么样的（流水线步骤）

> What it looks like (pipeline step)

```markdown
- name: Triage failed build
  if: failure()
  run: >
    claude -p "Read the build log at out/build.log. Identify the most
    likely cause, say whether the failure looks flaky or real, and write a
    three-line summary for the PR thread." >> triage.md
```

###### 治理方面的考量

> Governance considerations

其核心原则是：智能体可以行动直至生产环境闸门为止，但不能越过该闸门。下述控制措施用于落实这一原则。

> The governing principle is that the agent may act up to the production gate and cannot pass it. The controls below enforce this principle.

- 分支保护会把智能体写入的任何内容都变成一个 PR，没有直接通往 main 分支的路径。
- 生产环境部署钩子会阻止发布，直到某位指定的发布经理进行授权。每次非交互式运行都以该代理自身的身份执行，因此流水线日志会区分代理所做的操作与触发它的工程师所做的操作。
- 按环境划分的权限层级决定了代理在到达关卡之前可以执行多少操作。

> • Branch protection turns anything the agent writes into a PR, with no direct path to main.
> • The production deploy hook blocks the release until a named release manager authorizes it. Each non-interactive run acts under the agent's own identity, so the pipeline log separates what the agent did from what the engineer who triggered it did.
> • Per-environment permission tiers set how much the agent may do on the way to the gate.

#### 维护

> Maintain

##### 维护与闭环

> Maintenance and closing the loop

到目前为止，我们讨论了如何将 Claude 添加到 SDLC 流程的每个阶段，其中每个阶段都需要人来启动最初的步骤。然而，这一阶段将重点转向让 Claude 自主运行，从而闭环。

> So far, we've discussed how to add Claude to each stage of the SDLC process, with each stage requiring a human to launch the initial steps. This stage, however, shifts the focus to autonomous running of Claude to close the loop.

例如，一个持续运行的监控代理可以在有缺陷工单被提出后，创建一个 `intent.md`，并依次流经需求、计划、构建、测试和评审各个阶段。第 6 阶段：维护以无人值守（headless）方式运行，各阶段之间设有独立的置信度关卡——可以是确定性检查，也可以是一个对抗性的评审代理——由它决定上一阶段的输出是继续推进，还是升级交由人工处理。

> For example, a continuously running monitoring agent could, off the back of a bug ticket being raised, create an `intent.md`, and flow through the requirements, plan, build test and review phases. Stage 6: Maintenance runs headless, with an independent confidence gate between stages, a deterministic check or an adversarial reviewing agent, deciding whether the previous stage's output continues or is escalated to a human.

##### 闭合循环

> Closing the loop

一个确定性脚本会监控生产环境，并在控制区间被突破时调用 Claude。对于自主运行的循环而言，对突破情况的监控是该模式的一个有用示例，而本阶段末尾的 [Claude Tag](https://claude.com/product/tag)（公开测试版）一节则涵盖了通过不同渠道到来的工作。

> A deterministic script watches production and invokes Claude when a control band is breached. Monitoring of a breach is a helpful example of the pattern for the loop running autonomously, while the [Claude Tag](https://claude.com/product/tag) (public beta) section at the end of the stage covers work arriving through different channels.

###### 如何执行

> How to execute it

1. 服务负责人或平台工程师选择一个具有稳定滚动基线的指标，例如 CI 测试失败率、部署后 5xx 错误率或 PR 周期时间。
2. 他们编写检测脚本，通常采用滚动窗口上的均值和标准差，并配合规则（Western Electric 或类似规则），使控制带既能捕捉缓慢漂移，也能捕捉尖峰。该脚本纳入版本控制并有单元测试，检测过程完全保持确定性，不涉及任何模型。
3. 响应层级在受版本控制的配置中定义（见下方 `bands.yaml`）。在 1σ 时，脚本仅记录日志；在 2σ 时，它会以只读方式调用 Claude 进行诊断；在 3σ 时，Claude 可以采取行动，但仅限于向评审关卡提交 PR，或触发预先批准的运行手册。
4. 触发层可以是 GitHub 或 GitLab 中的定时工作流、来自现有监控栈的 webhook，或者网络内部的 Cron Job。Claude 以无状态方式运行，既可作为 CI runner 上的非交互式步骤，也可作为沙箱容器中的 Agent SDK 服务运行，而 CI/CD 方案涵盖了部署和模型访问的各种选项。由于运行是无状态且非交互式的，一个循环可以在无人启动它的情况下开始和结束。
5. 该智能体以「阶段 1：计划」的格式将其诊断结果写成 `intent.md`，内容涵盖异常及其证据、提议的处理结果、受影响的系统以及任何未决问题。此后，该发现会像其他任何内容一样走完整个流水线。
6. 服务负责人或值班工程师对队列进行分级处理，将面向产品的发现项转交给产品负责人。可以选择立即修复、排期处理或忽略。忽略操作会调整分级区间，有助于减少噪声。
7. 当修复上线后，为该事故添加一项评估（即持续评估的做法），以确保今后能够防范此类问题。

> 1\. The service owner or platform engineer picks one metric with a stable rolling baseline, such as CI test failure rate, post-deploy 5xx rate, or PR cycle time.
> 2\. They write the detection script, typically mean and standard deviation over a rolling window with rules (Western Electric or similar) so the bands catch slow drift as well as spikes. The script is version controlled and unit tested, and detection stays entirely deterministic, with no model involved.
> 3\. Response tiers are defined in version-controlled config (`bands.yaml` below). At 1σ the script only logs, at 2σ it invokes Claude read-only to diagnose, and at 3σ Claude may act, though only by opening a PR into the review gate or triggering a pre-approved runbook.
> 4\. The trigger layer can be a scheduled workflow in GitHub or GitLab, a webhook from the existing monitoring stack, or a Cron Job inside the network. Claude runs stateless, either as a non-interactive step on a CI runner or as an Agent SDK service in a sandboxed container, and the CI/CD play covers the deployment and model-access options. Because the run is stateless and non-interactive, a loop can begin and end without anyone starting it.
> 5\. The agent writes its diagnosis as `intent.md` in the Stage 1: Plan format, covering the anomaly and its evidence, a proposed outcome, the affected systems and any open questions. From there the finding goes through the pipeline like anything else.
> 6\. The service owner or on-call engineer triages the queue, routing product-facing findings to the product owner. Fix now, schedule, or dismiss. Dismissals tune the bands and help to reduce noise.
> 7\. When a fix ships, add an eval for the incident (the continuous evals play) to ensure that such issues are protected against going forwards.

###### 它看起来是什么样的（例如，一个用于监控 CI 测试失败率的 bands.yaml）

> What it looks like (for example, a bands.yaml monitoring CI test failure rate)

```yaml
metric: ci_test_failure_rate
baseline: rolling_30d
rules: western_electric
tiers:
  1sigma: { action: log }
  2sigma: { action: diagnose,
            tools: "Read,Grep,Bash(gh run view *)" }
  3sigma: { action: propose,
            routes: [pull_request, runbook:rollback-deploy] }
```

###### 治理方面的考量

> Governance considerations

层级边界由纳入版本控制的配置强制执行，权限和托管设置会拒绝对生产环境的访问。调用、发现的问题以及分级处置决定都会带时间戳记录下来。由服务负责人对发现的问题进行分级并批准，由此产生的变更走正常的 PR 评审关卡，而智能体可以触发的运行手册均已事先获得批准。

> The tier boundaries are enforced from version-controlled config, with permissions and managed settings denying production access. Invocations, findings and triage decisions are logged with a timestamp. A service owner triages and approves findings, resulting changes go through the normal PR review gate, and the runbooks the agent may trigger were approved in advance.

###### 示例

> Examples

- 当 CI 测试失败率突破 3σ 时，agent 会隔离该不稳定测试或提交一个回滚 PR，并由评审门禁做出决定。
- 当部署后的 5xx 错误率突破 3σ 且窗口期内存在一次部署时，该 agent 会触发现有的回滚流水线。
- 当 PR 周期时间触发漂移规则时，该智能体会为工程管理层撰写一份报告，这表明该框架不仅适用于生产指标，也适用于流程指标。

> • When the CI test failure rate breaches 3σ, the agent quarantines the flaky test or opens a revert PR, and the review gate decides.
> • When the post-deploy 5xx rate breaches 3σ with a deployment in the window, the agent triggers the existing rollback pipeline.
> • When PR cycle time trips a drift rule, the agent writes a report for engineering leadership, which shows the harness works for process metrics as well as production ones.

##### Claude 与 Claude 标签一同值守

> Claude on call with Claude Tag

事件也可能通过其他途径出现，比如 Slack 或 Teams 这类办公沟通应用。事件可能表现为晚上 10 点在事件频道里发来的一条要求紧急修复的 Slack 消息，而现在可以立即对其采取行动。Claude Tag（目前在 Slack 中提供公开测试版）让 Claude 以自己的身份成为这些频道的成员，因此每一个新出现的事件都会有一位第一响应者，而响应本身也会成为闭环的一部分，并沉淀为应对未来事件的记忆。

> Incidents can also arrive via other means such as workplace communication apps, like Slack or Teams. Incidents can look like a 10pm Slack message for an urgent fix on an incident channel and can now be actioned immediately. Claude Tag (public beta currently available in Slack) makes Claude a member of those channels under its own identity, so each new incident gets a first responder and the response itself becomes part of the loop and memory for future incidents.

对话和机构知识都留存在频道中，频道内的任何人都可以引导并执行响应。任何团队成员都能实时检验假设、探索新方案并展开调查，而频道历史记录进一步增强了可审计性。通过访问 MCP，Claude 验证该指标已回到基线水平，并在讨论线程中予以确认，同时将复盘报告写入一个受版本控制的经验教训文件，供未来的调查查阅。

> The conversation and institutional knowledge stay in the channel, with anyone in the channel able to guide and action the response. Any team member can test hypotheses, explore new options and investigate in real time with the channel history adding to the auditability. Through access to MCP Claude verifies the metric is back at baseline and confirms it in the thread, writes the post-mortem to a version-controlled lessons file that future investigations can read.

事故并不是 Claude Tag 承接的唯一工作。无论是通过 MCP 在工单上被标记，还是在频道里被直接询问，Claude 都会以同样的方式对工作进行分诊。范围小、边界清晰的修复会以 PR 的形式经由评审关卡提交，而任何更大的工作则会被写成 `intent.md` 交给阶段 1：规划，此时这个循环便开始自我驱动了。

> Incidents are not the only work Claude Tag picks up. Tagged on a ticket over MCP or asked in the channel, Claude triages the work the same way. A small, well-bounded fix arrives as a PR through the review gate, and anything larger is written up as `intent.md` for Stage 1: Plan, at which point the loop starts feeding itself.

![The channel is the audit trail: request, diagnosis, human authorization and fix all stay where the incident was handled.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8760aded54a2a8319cd5b9_fe6d780d.png)

#### 结语

> Closing thoughts

模型和框架已变得更加先进，使各组织不仅能够变革代码的生产方式，还能变革整个软件开发生命周期。

> Models and harnesses have become more advanced, allowing organizations to not just transform how they produce code, but the entire software development lifecycle.

这种转型使人的判断始终处于流程的核心，并兼顾了大型企业组织的治理与合规要求。

> This transformation keeps human judgement central to the process and considers the governance and regulation requirements of large enterprise organizations.

本指南汇总了我们的应用人工智能团队每天为客户实践的许多真正的最佳实践，我们希望你会发现它是一份实用且可付诸行动的资源。

> This guide consolidated many of the real best practices our Applied AI team executes on a daily basis for our customers, and we hope you found it a practical and actionable resource.

##### 资源与致谢

> Resources and acknowledgments

下面的文档是平台团队设置这些控制项所需的内容，大致按照你实际推行的顺序排列。

> The documentation below is what a platform team needs to set those controls up, in roughly the order you would roll them out.

感谢 Jim Blackhurst、Will Steuk 和 Jamal Arif 对本指南的贡献，本指南的灵感来自他们此前的大量工作，并在此基础上构建而成。

> Thanks to Jim Blackhurst, Will Steuk, and Jamal Arif for their contributions to this guide, which was inspired by and built on much of their previous work.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| SDLC (Software Development Life Cycle) | 软件开发生命周期 | 将软件从想法推进到生产环境的过程，通常划分为规划、设计、构建、测试、部署、维护六个阶段。 |
| Plan Mode | 计划模式 | Claude Code 的一种权限模式，在工程师接受计划之前禁止模型编辑文件。 |
| Skill | 技能 | 以 SKILL.md 定义的受版本控制指令包，用于把组织知识与策略一致地施加到会话上。 |
| Hook | 钩子 | 在模型采取行动前运行的脚本，可允许、询问或阻止该行动，构成确定性管控层。 |
| Sub-agent | 子代理 | 在单个会话内运行的限定范围助手，拥有独立上下文窗口和工具限制。 |
| git worktree | 工作树 | 位于独立分支上的单独检出目录，使多个并行会话不在同一文件上冲突。 |
| Eval | 评估 | 由提示词与合格判定检查组成的测试项，用于在智能体配置变化时检验其表现是否退化。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 将部署、状态查询、回滚等能力以工具形式按环境作用域暴露给智能体的接口协议。 |
| CI/CD | 持续集成 / 持续交付 | 自动构建、测试并向各环境发布代码的流水线体系。 |
| Branch Protection | 分支保护 | 版本控制平台的规则设置，要求变更以 PR 形式合入并获得代码所有者批准。 |
| PRD (Product Requirements Document) | 产品需求文档 | 传统流程中用于在长周期开发前强制达成一致的需求说明文件。 |
| Stage-gate QA | 阶段门式质量保证 | 在阶段之间设置人工验证关卡的传统质量保证方式，在 AI 原生流程中由持续评估替代。 |
| Headless | 无人值守 / 非交互式 | 不需要人工交互即可启动和结束的运行方式，用于自主循环与流水线作业。 |
| Control Band | 控制带 | 基于滚动窗口均值与标准差设定的指标区间，突破后按层级触发相应响应。 |
| Runbook | 运行手册 | 预先批准的标准处置流程，智能体在特定阈值下可直接触发执行。 |
| Managed Settings | 托管设置 | 由平台或 IT 管理员拥有的配置层，使个别工程师无法关闭不可协商的管控项。 |
