# 如何为 AI 驱动的代码现代化项目做好准备

> How to prepare for AI-driven code modernization projects

> 来源：Claude Blog / Anthropic，2026-09-23
> 原文链接：https://claude.com/blog/how-to-prepare-for-ai-driven-code-modernization-projects
> 分类：软件工程 / 代码现代化

## 核心要点

- 智能体加快了变更的编写速度，使大型代码现代化项目的瓶颈从产出变更转移到围绕变更调动组织的审查、审批与变更管理流程。
- 定义目标时需先确定现代化类型，即保持行为不变仅替换技术栈的转换式、借机偿还技术债务并引入新需求的重塑式，或就地升级的升级式，并尽早就路径达成共识。
- 借助 Claude 及代码现代化插件梳理代码库、提取业务规则，并辅以业务用户访谈和内部文档，可以完整把握遗留系统的实际行为。
- 降低风险通常比降低成本更能成为现代化改造的核心依据，不进行现代化的风险可作为权衡各方风险分歧的砝码。
- 证书是每项变更必须满足且无需人工即可检查的一组条件，应与未来的评审人员共同制定，其核查基准随现代化类型分别锚定原有代码库或行为规格。
- 晋升策略是事先书面约定的分级审查路径，应按影响范围和智能体置信度对变更分级，从源头修复反复出现的标记，并把领域专家的时间集中在高风险变更上。
- 环境、CI/CD、评审能力以及安全与合规审批等前提条件多依赖其他团队，需尽早启动沟通，并落实最小权限访问、敏感信息遮蔽和变更可追溯等要求。
- 智能体工作流应基于目标、证书和晋升策略构建，先在代码库一小部分上端到端验证并在出现问题时修改工作流本身，再逐步扩大规模。
- token 成本主要取决于代码阅读与修改量、证明复杂度、测试编写量和合并协调工作，可通过试点测量推算下限，并按任务难度搭配不同能力与成本的模型。
- 现代化的产出不仅是新代码库，还包括工作流、证书、晋升策略和证据链，可沉淀为可复用的行动手册。

## 正文

*在我们的****“一线笔记”（Notes from the Field）****系列中，Anthropic 的前线部署工程师会分享源自真实客户部署的最佳实践。在本文中，我们将分享管理大型代码现代化项目的经验。*

> *In our ****Notes from the Field ****series, Anthropic forward deployed engineers share best practices inspired by real customer deployments. In this article, we share our experience managing large code modernization projects.*

[代码现代化改造](https://claude.com/blog/how-ai-helps-break-cost-barrier-cobol-modernization)过去被规划为需要全员投入、历时数年的工作，如今几个月（甚至[几周](https://claude.com/blog/ai-code-migration)）就能完成，但前后两端的组织工作往往依然不变。

> [Code modernizations ](https://claude.com/blog/how-ai-helps-break-cost-barrier-cobol-modernization)once scoped as multi-year, all-hands efforts can now finish in months (or [weeks](https://claude.com/blog/ai-code-migration)), but the organizational work on either side often remains the same. 

例如，关键银行系统的每一项变更都必须经过变更管理、审查和审批。这是一套严格的流程，因为监管机构、审计人员和业务部门都有此要求。

> For example, every change to a critical banking system must go through change management, review, and approval. It is a robust process because regulators, auditors, and the business require it. 

正是这些流程让关键系统值得信赖，而它们建立在这样一个假设之上：每项变更都由人来编写，每个 diff 都由人来审查。一旦智能体加快了变更的编写速度，瓶颈就从产出变更转移到了围绕这些变更调动整个组织。

> Those processes are what make critical systems trustworthy, and they were built on the assumption that a human wrote each change and a human would review each diff. Once agents accelerate writing the changes, the bottleneck shifts from producing changes to mobilizing the organization around them.

本文介绍企业在现代化改造开始之前必须完成的工作：定义何为“完成”、一项变更必须附带哪些证据、经过认证的变更将如何进入生产环境，以及需要预先准备哪些内容才能启动运行。

> This article covers the work enterprises must do before the modernization takes place: defining what done means, what evidence a change must carry, how certified changes will reach production, and what has to be staged so the run can start. 

我们将这一过程分为六个步骤：

> We break this process into six steps:

1. **定义目标：**现代化后的代码必须采用的技术栈及应具备的行为。
2. **创建证书：**即变更在目标状态下必须满足、才能被视为正确的条件。
3. **制定晋升策略：**即经过认证的变更以其产出速度进入生产环境的路径。
4. **落实前提条件：**环境、CI/CD、评审能力以及审批。
5. **构建并完善智能体工作流：**即定制的 Claude Code [动态工作流](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)，它将现代化改造分配到许多较小的并行子智能体工作流中，由这些工作流生成具体变更。该工作流围绕目标、证书和晋升策略构建。
6. **执行现代化改造：**先在代码库的一小部分上端到端验证工作流，再逐步扩大规模。

> 1\. **Define the target:** the tech stack and behavior the modernized code must have. 
> 2\. **Create the certificate:** the conditions that the changes must meet to be considered correct in the target state. 
> 3\. **Set the promotion policy:** the path by which certified changes get into production at the rate they’re produced. 
> 4\. **Put the prerequisites in place:** environment, CI/CD, review capacity, and approvals.
> 5\. **Build and refine the agentic workflow: **the custom Claude Code [dynamic workflow](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) that distributes the modernization across many smaller parallel subagent workstreams that produce the changes. This is built around the target, certificate, and promotion policy.
> 6\. **Run the modernization:** prove the workflow end to end on a small partition of the codebase, then scale. 

#### **第 1 步：定义目标**

> **Step 1: Define the target**

**目标**是现代化的最终状态。期望的最终状态决定了你所进行的是三种现代化中的哪一种，详见下表。

> The** target **is the end state of the modernization. The desired end state determines which of the three kinds of modernization you are doing, detailed in the table below. 

##### **确定现代化改造类型**

> **Determine the modernization type**

究竟采用哪种现代化改造方式，在组织内部往往争论不休。根据我们的经验，最贴近生产环境的人希望在保持行为不变的前提下替换技术栈，以控制风险（转换式现代化）。另一方则往往是长期与这套代码库打交道、希望借现代化改造偿还技术债务的工程师，以及希望借此机会提出新需求的其他业务相关方（重塑式现代化）。

> Determining which type of modernization to do is often debated inside an organization. In our experience, the people closest to production want the stack swapped with behavior held constant to contain risk (transform modernization). On the other side are often the engineers who have lived with the codebase and want the modernization to pay down tech debt, plus other business stakeholders who want to take the opportunity to name new requirements (reimagine modernization). 

两种立场都有道理，但如果这个问题悬而未决，它日后就会以争论某项改动是否“正确”的形式再次浮现。就采取哪条路径达成共识，虽然会在初期带来一些阻力，却能让整个项目推进得更加顺畅。

> Both positions are reasonable, but if the question is left unresolved it resurfaces later as an argument over whether a given change is “correct.” Building consensus on which path to take adds initial friction, but streamlines the project as a whole.

##### **梳理代码库并编写行为规范**

> **Map the codebase and create the behavioral spec**

理解现有系统往往是定义目标的良好第一步。梳理旧代码的实际行为，并为当前行为建立清单，便于判断哪些部分应当修改或舍弃，从而确定这次现代化属于转换（transform）还是重塑（reimagine）。这一过程还常常能揭示出此前未知的业务逻辑和边界情况。

> Understanding the current system is often a good first step for defining the target. Extracting what the old code actually does and creating an inventory of current behavior makes it easy to decide if parts should be changed or dropped, and so whether the modernization is a transform or a reimagine. This also often reveals unknown business logic and edge cases. 

Claude 可以通过[梳理依赖关系并记录那些早已无人记得是如何构建的工作流](https://claude.com/blog/how-ai-helps-break-cost-barrier-cobol-modernization)来完成大部分此类摸底工作。[代码现代化插件](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization)的 *assess、map、*以及 *extract-rules* 命令能够挖掘业务规则并附上源代码出处，供工程师随后审阅。

> Claude can do much of that discovery by [mapping dependencies and documenting workflows that nobody remembers building](https://claude.com/blog/how-ai-helps-break-cost-barrier-cobol-modernization). The [code modernization plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization)’s *assess, map, *and *extract-rules* commands mine business rules with source citations that engineers can then review. 

然而，仅靠 Claude 的探查，未必能完整把握遗留系统的全部行为。与业务用户和开发人员的访谈，以及内部文档，可以填补这些空白。前期收集上下文可能需要花费一些时间，但上下文的质量会影响工作流后续做出的每一个决策。

> However, Claude’s discovery alone may not capture how a legacy system fully behaves. Interviews with business users and developers, and internal documentation, can fill those gaps. Context gathering may take some time upfront, but the quality of that context shapes every decision the workflow makes later.

对于重新构想（reimagine）而言，定义目标需要额外的工作：应当写下一份详细的行为规格说明，并与各用户群体达成一致。

> For a reimagine, defining the target requires additional work: a detailed behavioral spec should be written down and agreed with user groups.

![An interactive dependency map example from the code modernization plugin.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab3ce6a62d56528c6b6e022_efbbc4f0.png)

##### **确立项目的依据与目标**

> **Establish the project’s justification and goals**

在明确目标的同时，组织还应思考这次现代化改造究竟为何值得进行。对遗留系统进行现代化改造可以降低持续的维护和运营成本，然而，根据我们的经验，降低成本并不是大多数现代化项目的主要驱动目标。

> Alongside defining the target, the organization should consider why the modernization is worth undertaking at all. Modernizing legacy systems can reduce ongoing maintenance and operational costs, however, in our experience, cost reduction has not been the driving goal of most modernization projects.

> 降低风险往往是现代化改造最重要的收益。在讨论是否要开展该项目时，应当考虑不进行现代化改造所带来的风险。 

> Risk reduction is often the most important modernization benefit. Consider the risk of not doing the modernization when debating whether or not to undergo the project. 

例如，一个存在未修补漏洞的系统，可能招致网络入侵，或引发严重到足以危及企业自身存续的宕机。运行时不再受支持，或是了解该系统的工程师日益减少，都会加剧这种风险。

> For example, a system carrying unpatched vulnerabilities can mean a cyber breach or an outage severe enough to put the business itself at risk. An unsupported runtime or a shrinking pool of engineers who understand the system exacerbates the risk. 

像 Claude Code 这样的智能体编程工具缩短了现代化改造的周期，但预算仍然难以估算，这导致了迟迟不愿行动的惰性。我们已经公开了部分[大规模现代化改造](https://claude.com/blog/ai-code-migration)项目的成本，[其他团队](https://claude.com/customers/lg-cns)也同样公开过。这些数据可以作为粗略的基准，此外，本指南末尾还提供了关于预算预测的更多指导。

> Agentic coding tools like Claude Code have shortened modernization timelines, but budgets are still hard to estimate, which leads to inertia. We have released the costs of some of our [large-scale modernizations](https://claude.com/blog/ai-code-migration) as have [others](https://claude.com/customers/lg-cns). These can serve as a rough baseline, and we have additional guidance on budget projections at the bottom of this guide. 

启动这类项目的主要挑战，通常在于在拥有该系统的团队以及依赖该系统的团队之间建立内部共识并获得其投入。构建业务论证并设定项目目标（通常在领导层层面进行），能让这部分工作更容易推进。这也有助于为后续证书和发布晋级策略中的权衡取舍提供依据。当利益相关方对某项变更能承担多大风险意见不一时，不进行现代化改造的风险便是与之相抗衡的砝码。

> The main challenge in initiating these projects is usually building the internal consensus and commitment from the teams that own the system, and the teams that depend on it. Building the business case and setting the goals of the project, often at the leadership level, make this part of the process easier. This also helps anchor the tradeoffs in the certificate and promotion policy that follow. When stakeholders disagree over how much risk a change can carry, the risk of not modernizing is the counterweight. 

#### **第 2 步：定义证书**

> **Step 2: Define the certificate**

**验收凭证**是每一项现代化改造变更都必须满足的一组条件或测试。应选取那些能够提供最强累积证据、证明该变更相对于目标是正确的条件。

> The **certificate** is the set of conditions or tests that every modernization change must meet. Pick the conditions that give the strongest cumulative evidence that the change is correct against the target. 

每个条件都应当无需人工参与即可检查，这样智能体工作流就能对某项变更反复迭代，直到其满足证书要求；如果无法满足，则将其标记出来交由人工审查。 

> Each condition should be checkable without a human in the loop, so the agentic workflow can iterate on a change until it meets the certificate or flag it for human review if it can’t. 

证书中包含哪些内容取决于目标，但通常会从以下列表中选取：

> What goes into the certificate depends on the target, but will usually draw from this list:

- 原有测试套件全部通过
- 在现代化改造过程中由 Claude 编写的测试全部通过
- 测试覆盖率达到约定的阈值
- 性能基准测试结果保持在约定的范围内
- 由 Claude 进行的多轮独立对抗性审查（每轮均在全新的上下文窗口中进行）均未发现阻塞性问题
- 在用户界面方面，由 Claude 驱动的计算机操作未发现任何回归问题
- 当前版本与目标版本在相同输入下产生相同输出，输入可以是实时的、录制的或由 Claude 生成的
- 持久化状态和传输格式可在当前版本与目标版本之间双向往返转换
- 变更在预发布环境中运行约定的时长，期间错误率、延迟和告警均无回归
- 静态分析和安全扫描均未发现新问题
- 对于编译型目标，构建干净无误，且类型检查通过

> • The original test suite passes
> • Claude-authored tests written during the modernization all pass
> • Test coverage meets an agreed threshold
> • Performance benchmarks stay within an agreed bound
> • Independent adversarial reviews by Claude, each in a fresh context window, find no blocking issues
> • For user interfaces, Claude-driven computer use finds no regressions
> • Current and target versions produce the same output from the same input, which can be live, recorded, or Claude-generated
> • Persisted state and wire formats round-trip between current and target versions
> • Changes run in staging for an agreed period with no regressions in error rates, latency, or alerts
> • Static analysis and security scans show no new findings
> • For compiled targets, the build is clean and type checks pass

> **与将来负责审查变更并将其推进到生产环境的人员一起编写认证标准。**趁认证标准和智能体工作流仍在设计阶段，就让当前依赖该代码库的开发人员、用户群体和业务负责人参与进来。

> **Write the certificate with the people who will review and promote changes into production. **Bring in the developers, user groups, and business leads who depend on the codebase now, while the certificate and agentic workflow are still being designed. 

他们的专业知识决定了证书衡量的内容，而正是他们的早期参与，才让他们在变更进入评审时愿意认同。检验最终证书的一个好方法是：他们是否愿意仅凭证书提供的证据就合并代码。如果他们能从中看到自己的标准，那么第 3 步中的晋升策略就可以宽松一些。 

> Their expertise shapes what the certificate measures, and their early involvement is what earns their buy-in when changes reach review. A good check on the finished certificate is whether they would be comfortable merging on the certificate's evidence alone. If they see their own bar in it, the promotion policy in Step 3 can be lighter. 

证书依据什么进行核查、如何核查，取决于现代化改造的类型。

> What the certificate checks against, and how, depends on the modernization type. 

- **对于升级式现代化改造**，** **等价性是相对于原始代码库而言的，原有的测试套件可以作为证明的核心。
- **对于转换式现代化改造，**一致性同样是以原有代码库为基准，但原有测试套件很少能在新技术栈上运行。取而代之，大部分工作由生产流量回放、新旧系统之间的差异测试以及与生产环境并行的部署来完成。
- **对于重新构想式现代化**，证明以行为规格为锚点。这是最难的情况。与可供比对的现有系统相比，规格不那么客观，因此需要更多地依赖模型的判断，结果也可能更加多变。在这种情况下，证明主要依靠三类手段：根据规格编写的测试；由 Claude 进行的独立对抗性审查，逐项对照规格检查每一处变更；以及在新系统保留旧系统行为之处进行的差异比对检查。随着规格逐步明确，证明也需要相应修订：规格中的缺漏最先会在这里暴露出来。

> • **For an uplift modernization**,** **parity is against the original codebase, and the original test suite can be the core of the certificate. 
> • **For a transform modernization,** parity is also against the original codebase, but the original test suite rarely runs on the new stack. Replay of production traffic, differential testing between old and new, and a prod-parallel deployment do most of the work instead. 
> • **For a reimagine modernization**, the certificate is anchored in the behavioral spec. This is the hardest case. A spec is less objective than an existing system to diff against, so a larger degree of model judgement is involved, which can lead to more variable outcomes. Here, the certificate leans on tests written from the spec, independent adversarial reviews by Claude that check each change against the sec, and differential checks where the new system keeps the old one’s behavior. Expect to revise the certificate as the spec is clarified: gaps in the spec show up here first.

较旧的系统往往测试覆盖率低、测试不稳定，且几乎没有遥测数据。定义证书的一部分工作就是找出这些缺口。如果难以支撑一份强有力的证书，那么这一步最有用的做法之一，就是借助 Claude 构建缺失的证据，无论是搭建与生产环境并行的环境、构建回放测试框架，还是编写更多测试。

> Older systems often have thin test coverage, flaky tests, and little telemetry. Part of defining the certificate is identifying these gaps. If it will be difficult to support a strong certificate, one of the most useful things to do at this step is to use Claude to build the missing evidence, whether that’s standing up a prod-parallel setup, building a replay harness, or writing more tests. 

#### **第 3 步：设置晋升策略**

> **Step 3: Set the promotion policy**

智能体产生变更的速度，将远远超过任何人类团队逐个 diff 审查的速度。晋升策略是一条分级审查路径——事先以书面形式确定并达成一致——用于设定人类对某项变更的审查深度，从而使现代化改造能够在可接受的时间线内完成。 

> Agents will produce changes far faster than any human team can review them diff-by-diff. The promotion policy is a tiered review path–written down and agreed in advance–that sets the depth of human review for a change, so the modernization can finish on an acceptable timeline. 

与证书一样，这一步也应与评审人员共同推进，并尽可能纳入你所在组织现有的变更管理流程。具体细节会因组织及其面临的风险权衡而有所不同，但有几条规则在任何地方都适用：

> Like the certificate, work this step with the reviewers, and fit it into your organization's existing change-management process wherever you can. The details will differ by organization and the risk tradeoffs it faces, but a few rules hold everywhere:

- **根据影响范围和智能体置信度对变更进行分级。**如果你的组织已有自己的变更或风险分类标准，请沿用该标准。对关键路径保留完整的人工审查。
- **从源头解决反复出现的标记。**随时间推移对被标记的变更进行分组和分析。当同一类标记反复出现时，应在智能体工作流或证书中修复其根本原因，而不是逐一审查每个标记。
- **与审核人员共同设计输出格式。**就哪些信息和格式能让审核最快完成、哪些信号比其他信号更能增强信心达成一致。请他们在第 5 步中审核早期的示例输出。
- **高效分配 SME 的时间**。SME 不会逐一审阅每一份最终 diff，但他们的判断仍然是最稀缺的投入。要让他们能够直接定位到最高风险层级中的变更，以及每个层级内被标记出来的智能体决策，而无需费力翻阅大量 diff。这样，少量的专家工时就能覆盖风险最高的那些变更。

> • **Tier changes by blast radius and agent confidence.** Use your organization's own change or risk classification if it has one. Keep full human review for critical paths.
> • **Fix recurring flags at the source. **Group and analyze the flagged changes over time. When the same kind of flag keeps recurring, fix the cause in the agentic workflow or the certificate rather than reviewing each one.
> • **Design the output format with the reviewers. **Agree on what information and format make review the fastest, and what signals give more confidence than others. Have them review early sample outputs in Step 5.
> • **Allocate SME time effectively**. SMEs won't read every final diff, but their judgment is still the scarce input. Make it easy for them to go straight to the changes in the highest-risk tiers, and to the flagged agent decisions within each one, without wading through large diffs. A small number of expert hours then covers the changes that carry the most risk.

其中许多规则通过在项目早期就让领域专家（SME）参与进来，将他们投入的工时前置。在全面现代化改造开始之前，他们的反馈会对证书和智能体工作流进行调优。

> Many of these rules front-load SME hours by engaging them early in the project. Their feedback tunes the certificate and the agentic workflow before the full modernization begins.

他们对样本的认可，也进一步证明了在高置信度的情况下可以采用更轻量的审查流程。这与传统的非智能体模式恰恰相反，后者的审查是在最后才进行的。

> Their sign-off on the samples also becomes further justification for a lighter review path where there is high confidence. This is the reverse of the traditional, non-agentic pattern, where review happens at the end.

![The path of a change from generation to production.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab3ce6a62d56528c6b6e01f_878b06f2.png)

晋级策略还应体现现代化改造在速度与评审深度之间所处的位置。如果现代化改造正赶在硬性截止期限前冲刺，例如某个运行时即将停止支持，就需要更快速的策略：减轻人工评审，并明确约定每次变更可接受更高的风险。

> The promotion policy should also reflect where the modernization sits on the spectrum between speed and review depth. A modernization racing to a hard deadline, such as a runtime losing support, needs a faster policy with lighter human review and an explicit agreement to accept more risk per change. 

时间线较长的现代化改造可以承受更深入的人工审查和更缓慢的切换。利益相关方会根据各自的风险偏好和约束条件，在这一范围内选择不同的位置，因此值得在工作开始之前就把这一点确定下来。

> A modernization on a longer timeline can afford deeper human review and a slower cutover. Stakeholders will land on different points of this spectrum depending on their risk appetite and constraints so it is worth locking in before the work starts.

在受监管的环境中，对任何变更采用更轻量的人工审核流程都可能引发切实的不安。个人审批者对签字批准心存犹豫，因为他们要承担不良变更带来的风险，而领导层则要承担系统老化这一更大的风险。

> In a regulated environment, taking a lighter human review path for any change can cause real discomfort. Individual approvers hesitate to sign off because they carry the risk of a bad change, while leadership carries the larger risk of an aging system. 

根据我们的经验，晋升策略的指令最好来自组织高层。此外，最好事先就此达成一致，这样一旦有缺陷进入生产环境，责任由大家共同承担，而不是归咎于批准该变更的人。

> In our experience, it is best to have the directive for the promotion policy come from the top of the organization. It is also better to agree on it beforehand so responsibility for a bug that reaches production is shared, not pinned on whoever approved the change.

> **这一切仍然取决于两点：一是证书要足够详尽，能够作为真正的证据；二是审阅者要充分理解 Claude 是如何得出某项改动的，从而能够信任它。**

> **All of this still depends on a certificate detailed enough to serve as real evidence, and on reviewers who understand how Claude arrived at a change well enough to trust it. **

#### **第 4 步：准备好前提条件**

> **Step 4: Put the prerequisites in place**

这一步的大部分工作都要经由现代化团队之外的其他团队完成：由平台或基础设施团队提供主机，由 QA 或发布工程团队提供测试能力，由安全与合规团队负责审批。这些团队往往各有自己的待办事项或审批流程，因此要尽早开启沟通——一旦确定了需求就立即着手，这通常是在第 1 步到第 3 步仍在进行之时。

> Much of this step runs through teams outside the modernization: platform or infrastructure for the host, QA or release engineering for test capacity, security and compliance for approvals. Each of those teams often has its own backlog or approval process, so open the conversations early, as soon as you have identified the requirements, often while Steps 1 through 3 are still underway.

##### **环境**

> **Environment**

- 一台专用远程主机，用于运行该工作流，且 Claude 可以访问其中的代码库及其他相关资源
- 按证书要求测试容量
- 任何能够增强凭证可信度的东西：生产环境遥测数据、与生产并行的环境，或可供回放的生产数据

> • A dedicated remote host for running the workflow with the codebase and other relevant sources reachable by Claude
> • Test capacity as required by the certificate
> • Anything that strengthens the certificate: production telemetry, a prod-parallel setup, or production data for replay

##### **代码库与 CI/CD**

> **Codebase and CI/CD**

- 一份代码库依赖关系图，其依据来自构建和编译日志、导入分析或运行时跟踪。注意：该插件的 *map* 命令是一个不错的起点，但根据代码库的规模和年代，可能需要预先开展更多的工作
- 作为目标定义的一部分，对所有依赖项或软件包的计划处理方式
- 一项兼容性检查，可按需加入 CI/CD 流程
- 一项各方认可的代码冻结策略（如果你是在原有系统上就地进行现代化改造）
- 面向活跃开发者的沟通计划，涵盖所有代码冻结安排以及新的兼容性要求

> • A dependency map of the codebase, grounded in build and compile logs; import analysis; or runtime traces. Note: The plugin’s *map* command is a good starting point, but depending on the size and age of the codebase, more extensive upfront work may need to be done
> • Planned treatment of any dependencies or packages, as part of the target definition
> • A compatibility check ready to add to CI/CD, if needed
> • An agreed code-freeze policy, if you are modernizing in place
> • A communication plan for active developers covering any code freezes and new compatibility requirements

##### **团队与评审**

> **Teams and review**

- 与依赖该代码库的其他团队就其参与方式达成一致，例如签署证书或依据晋升策略进行评审，并为评审人员预留时间

> • Agreement from other teams that depend on the codebase on how they take part, like signing off on the certificate or reviewing under the promotion policy, with reviewer time set aside

##### **安全与合规**

> **Security and compliance**

- 一条已获准用于源代码的 Claude Code 模型访问路径
- 为智能体工作流实施最小权限访问：仅允许写入现代化改造分支，且不授予任何生产环境凭据
- 已从现代化改造分支中清除或遮蔽密钥和个人身份信息（PII）
- 每项变更均可追溯，且每个 PR 都关联到智能体对话记录和证书证据
- 新依赖项的许可证与漏洞检查

> • A model access path for Claude Code approved for source code
> • Least-privilege access for the agentic workflow: write only to modernization branches and no production credentials
> • Secrets and PII scrubbed or masked from the modernization branch
> • Every change traceable and PR linked to an agent transcript and certificate evidence
> • License and vulnerability checks on new dependencies

#### **第 5 步：构建并完善智能体工作流**

> **Step 5: Build and refine the agentic workflow**

使用 Claude Code 开发定制化的[动态工作流](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)，以实现代码库的现代化。

> Use Claude Code to develop a customized [dynamic workflow](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) for modernizing the codebase. 

我们建议从[代码现代化插件](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization)入手，并将工作流可能需要的一切内容放在文件系统上或通过 MCP 提供，让 Claude 能够访问。这包括目标、证书、晋升策略、代码库、文档，以及证书所需的任何数据源或工具。你也可以把本文作为上下文提供给 Claude。这些内容共同构成项目的核心知识库。

> We recommend starting with the[ code modernization plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization), and putting everything the workflow may need on the file system or over MCP, where Claude can reach it. This includes the target, certificate, promotion policy, codebase, documentation, and whatever data sources or tooling the certificate requires. You can give this article to Claude as context too. This forms the central knowledge base for the project.

有了这些基础，[构建现代化改造工作流](https://claude.com/blog/ai-code-migration)就是最简单的部分了。在下游环节依赖 Claude 的工作成果之前，请根据需要让领域专家（SME）对其进行审查，包括任何特定于代码库的技能或提取出的规则。

> With that in place, [building the modernization workflow ](https://claude.com/blog/ai-code-migration)is the easy part. Have SMEs review Claude’s work as needed, including any codebase-specific skills or extracted rules before anything downstream relies on it. 

将你构建的成果应用到代码库的一小部分上加以完善，并由领域专家（SME）审查它所产生的改动、智能体的执行过程，以及证明已满足证书要求的证据。 

> Refine what you've built by applying it to small parts of the codebase, with SMEs reviewing the changes it produces, the agents’ process, and the evidence the certificate was met. 

> 当问题出现时，应当修改工作流，而不是逐一修改每个变更。目标是确信：一旦规模化，变更几乎在所有地方都能满足认证要求，并且审阅者能够放心地依据晋级策略进行合并。

> You should modify the workflow, not each change, when issues surface. The goal is confidence that, once scaled, changes will meet the certificate almost everywhere and reviewers will be comfortable merging under the promotion policy. 

#### **第 6 步：执行现代化改造**

> **Step 6: Run the modernization**

首先，在代码库的一小部分上端到端地完成现代化改造，包括按照晋升策略审查并落地这些变更。趁修复成本还低时解决所有不奏效的问题，重复这一过程直到你有十足把握，然后再扩展到整个代码库。 

> First, complete the modernization end to end on a small part of the codebase, including reviewing and landing the changes through the promotion policy. Fix anything that doesn’t work while it’s still cheap, repeat the process until you are confident, then scale to the full codebase. 

转换式（transform）和重构式（reimagine）现代化改造都是在现有系统之外并行构建目标系统，待完成后再进行切换；而升级式（uplift）改造还有第二种选择：在开发持续进行的同时，直接在线上运行的代码库上就地进行现代化改造。

> While transform and reimagine modernizations involve building the target alongside the existing system and cutting over once complete, an uplift has a second option: modernizing in place on the live codebase while development continues. 

当系统不能停机，或者代码库变化太快、难以让一份单独的现代化副本保持同步时，通常会选择这种方式。在这种情况下，我们看到行之有效的做法是：从叶子节点向内，将代码库划分为若干逻辑分区；每次冻结并现代化一个分区；并对 CI/CD 设置门禁，使新的提交无法撤销已完成现代化的分区。

> This is the usual choice when the system cannot be down, or when the codebase changes so quickly that it’s difficult to keep a separate modernized copy up to date. What we have seen work in this case is splitting the codebase into logical partitions from the leaves inward; freezing and modernizing one partition at a time; and gating CI/CD so new commits cannot undo a partition once it has been modernized. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab3ce6a62d56528c6b6e025_244d0cca.png)

#### **关于成本的说明**

> **A note on cost**

经常有人问我们，像这样的现代化改造会消耗多少 token。每项现代化改造工作都各不相同，但主要的成本驱动因素包括：

> We often get asked what a modernization like this will cost in tokens. Each modernization effort is different, but the main cost drivers include:

- 代码库中有多少需要阅读、又有多少需要修改；
- 证明材料的复杂程度（在受监管的环境中，工作量的大头通常是验证，而不是编写变更本身）；
- 该证书需要编写多少新测试、修复多少测试；以及 
- 运行进行期间，其他团队在你周边合并代码会带来多少调和工作。

> • How much of the codebase has to be read versus changed;
> • How involved the certificate is (verification, not writing the change, is usually the larger share in a regulated environment);
> • How much new test writing and test repair the certificate demands; and 
> • How much reconciliation work comes from other teams merging around you while the run is in progress.

> 在对代码库的一小部分完成现代化改造时，测量 token 用量，并据此推算其余运行的用量。将试点无法覆盖的任何内容（例如在活跃代码库上进行的协调合并）视为未知项。这样，你就能估算出完成整个现代化改造的成本下限。

> When completing the modernization on a small part of the codebase, measure token-usage and use that to extrapolate for the rest of the run. Treat anything the pilot couldn’t see, such as reconciliation on a live codebase, as an unknown. This way you can get an estimate for the cost floor for the full modernization. 

试点中的测量数据还能揭示智能体工作流中哪些环节值得进行成本优化。找出工作流中消耗 token 最多的部分，并思考如何提高其效率。将计算量大的验证信号置于成本更低的检查关卡之后，使其仅在较简单的检查通过后才运行。

> Measurements from the pilot also show where to optimize your agentic workflow for cost. Find the parts of the workflow that consumed the most tokens and consider how to make them more efficient. Move compute-heavy verification signals behind cheaper gates so they only run once easier checks have passed. 

对于那些由证书完全检查的机械性、大批量工作，可以考虑使用 Sonnet 这类在成本与能力之间取得平衡的模型。更智能的模型则留给困难的转换任务，以及用于验证正确性的对抗性审查。 

> Consider using models like Sonnet that balance cost and capability for the mechanical, high-volume work the certificate fully checks. Keep more intelligent models for hard transformations and the adversarial reviews that verify correctness. 

当较便宜的模型未能满足验证标准时，你也可以升级到更昂贵的模型，但在试点阶段要仔细分析重试率，因为多次廉价尝试的总成本可能高于一次昂贵的尝试。如果你让 Claude 同时访问工作流和试点数据，它可以与你一起完成大部分此类分析。

> You can also escalate to a more expensive model when a less expensive one fails to meet the certificate, but analyze retry rates carefully while piloting, since several cheap attempts can cost more than one expensive one. If you give Claude access to both the workflow and the pilot data, it can do much of this analysis with you. 

#### **超越现代化**

> **Beyond the modernization**

现代化后的代码库只是产出之一。其他产出还包括：生成它的工作流、一份界定何为正确的书面凭证、一套已被你们的变更管理流程认可的晋升策略，以及每一项已落地变更的证据链。将这套行动手册固化为可复用的资产，这样在下一次升级或重写时，这一模式就已经准备就绪。

> The modernized codebase is one output. The others are the workflow that produced it, a written certificate for what counts as correct, a promotion policy your change-management process has already accepted, and an evidence trail for every change that landed. Codify the playbook as a reusable asset, so the pattern is already in place for the next upgrade or rewrite.

我们的前沿部署工程师会与客户一起，在其最关键的系统上逐步完成这些步骤。如果您正在筹备现代化改造，[欢迎联系我们的团队](https://claude.com/contact-sales)。

> Our forward deployed engineers work through these steps with customers on their most critical systems. If you're preparing a modernization,[ talk to our team](https://claude.com/contact-sales).

#### **其他资源**

> **Additional resources**

- [面向 Claude Code 的公开 codemod 插件](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization)
- [AI 原生 SDLC 实践手册](https://claude.com/blog/the-ai-native-sdlc-playbook)
- [代码现代化实战手册](https://resources.anthropic.com/code-modernization-playbook)
- [借助 AI 实现 COBOL 现代化：打破成本壁垒](https://claude.com/blog/how-ai-helps-break-cost-barrier-cobol-modernization)

> • [The public codemod plugin for Claude Code](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization)
> • [The AI-Native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
> • [Code modernization playbook](https://resources.anthropic.com/code-modernization-playbook)
> • [COBOL Modernization with AI: Breaking the Cost Barrier](https://claude.com/blog/how-ai-helps-break-cost-barrier-cobol-modernization)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Code Modernization | 代码现代化 | 将遗留系统迁移或改造为现代技术栈与架构的工程工作。 |
| Forward Deployed Engineer | 前线部署工程师 | 直接驻场参与客户真实部署并解决落地问题的工程师。 |
| Transform | 转换式现代化 | 在保持系统行为不变的前提下替换技术栈的现代化方式。 |
| Reimagine | 重塑式现代化 | 依据新的行为规格重新构建系统并引入新需求的现代化方式。 |
| Uplift | 升级式现代化 | 在原有代码库上进行版本或技术升级、可就地实施的现代化方式。 |
| Certificate | 证书 | 每项变更必须满足、可自动检查以证明其正确性的一组条件或测试。 |
| Promotion Strategy | 晋升策略 | 事先约定的分级审查路径，决定经认证的变更如何进入生产环境。 |
| Agentic Workflow | 智能体工作流 | 由 AI 智能体自主执行并迭代任务步骤的自动化流程。 |
| Dynamic Workflows | 动态工作流 | Claude Code 中将任务分配给多个并行子智能体执行的定制工作流机制。 |
| Subagent | 子智能体 | 由主工作流调度、负责处理部分子任务的独立智能体。 |
| Differential Testing | 差异测试 | 以相同输入比对新旧系统输出是否一致的测试方法。 |
| Production Traffic Replay | 生产流量回放 | 将录制的真实生产请求重放到新系统以验证行为一致性的方法。 |
| Adversarial Review | 对抗性审查 | 以主动寻找缺陷为目标、在独立上下文中进行的审查。 |
| SME (Subject Matter Expert) | 领域专家 | 对特定业务或系统具有深入专业知识的人员。 |
| Code Freeze | 代码冻结 | 在特定时期内限制或禁止对代码库特定部分提交变更的策略。 |
| Least Privilege | 最小权限 | 仅授予完成任务所必需的最低访问权限的安全原则。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 用于让模型连接外部数据源和工具的开放协议。 |
