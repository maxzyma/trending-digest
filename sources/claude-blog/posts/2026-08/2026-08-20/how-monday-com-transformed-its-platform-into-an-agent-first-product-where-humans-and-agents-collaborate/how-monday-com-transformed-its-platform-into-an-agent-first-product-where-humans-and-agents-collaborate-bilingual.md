# monday.com 如何将其平台转变为一个以智能体为先的产品，让人类与智能体协同工作

> How monday.com transformed its platform into an agent-first product where humans and agents collaborate

> 来源：Claude Blog / Anthropic，2026-08-20
> 原文链接：https://claude.com/blog/how-monday-com-transformed-its-platform-into-an-agent-first-product-where-humans-and-agents-collaborate
> 分类：企业软件 / AI 智能体产品化

## 核心要点

- monday.com 拥有超过 250,000 家企业客户，其核心产品最初是帮助团队自动化工作流并管理项目的可视化界面。
- 公司围绕人机协作模型从头重新架构产品，以 Claude 为核心处理技术复杂性，使客户能在熟悉的工作流内使用前沿 AI。
- 重构的第一阶段是把 AI 能力嵌入原有平台，并在 2025 年 5 月以全公司范围的“AI 月”活动集中交付 AI 功能。
- 团队将早期做法称为“AI 尘埃”——把自动化功能撒在现有工作流之上，虽有采用率却未改变产品的根本价值主张，也未形成持续使用模式。
- 转型指令来自最高层，但把北极星目标转化为具体产品选择和构建各自的智能体，由每个团队和员工自行实现。
- 重建后的产品复用平台已内置的上下文、工作流、看板、权限和治理能力，自 2026 年 5 月推出以来客户与智能体的交互已超过 500 万次。
- 每个智能体都被赋予名称与头像，同事可通过触发器和提及为其分配工作，从而把智能体式 AI 从抽象概念变为可执行的工作方式。
- 客户可通过 monday Agents、自带智能体（BYOA）、智能体商店的预置智能体以及 Claude Coding 集成四种方式在平台内使用 Claude。
- 营销案例展示了策略师智能体、落地页构建器与品牌审查员在单个看板条目内接力，从简报直至落地页审批，人类只需决定发布或继续优化。
- 家族海鲜企业 Cooke 在 Claude 与 monday 上运行约 200 个项目的 RAID 日志和 130 份合同的生命周期工作流，报告编制与数据准备已自动完成。
- monday 总结的五条经验包括：改变思维模式比改变技术更难、小团队在全面变动中跑得更快、采用取决于信任、能力需要匹配的基础设施（如 monday DB）、在已行之有效的基础上构建。

## 正文

从中小型企业到《财富》500强组织，超过 250,000 家公司使用 [monday.com](http://monday.com) 来管理他们的工作。这家公司在十多年前推出时，其核心产品是一个可视化界面，帮助团队自动化工作流并管理项目。如今，它已围绕一种人机协作模型从头重新架构了产品，将 AI 融入到各个层级的工作之中。以 Claude 为核心，monday 的新平台处理了技术上的复杂性，使客户能够在自己已经熟悉的工作流内部，站在 AI 前沿开展工作。

> More than 250,000 companies, from small and midsize businesses to Fortune 500 organizations, use [monday.com](http://monday.com) to manage their work. When the company launched more than a decade ago, its core product was a visual interface that helped teams automate workflows and manage projects. Today, it has rearchitected its product from the ground up around a human-agent collaboration model where AI is woven into work at every level. With Claude at the core, monday’s new platform handles the technical complexity so customers can work at the AI frontier inside workflows they already know.

“转向以智能体为先的产品，是我们作为一家公司做出的最重要的决定之一，”monday.com 首席产品与技术官 Daniel Lereya 说。“这意味着要从根本上重新构想这个平台应该做什么，而不只是在现有工作流上叠加 AI。我们的愿景是让 monday 成为人与 AI 智能体无缝协作的地方，而 Anthropic 和 Claude 一直是帮助我们把这一愿景变为现实的可信赖伙伴。”

> "The shift to an agent-first product was one of the most significant decisions we've made as a company," said Daniel Lereya, chief product and technology officer at monday.com. "It meant fundamentally reimagining what the platform should do, not just adding AI to existing workflows. Our vision is for monday to be the place where people and AI agents work together seamlessly and Anthropic and Claude have been trusted partners in helping us bring that vision to life."

#### 触及“AI 尘埃”天花板

> Hitting the “AI dust” ceiling

monday 的重构分三个阶段展开。在第一阶段，随着前沿大语言模型技术日趋成熟、客户热情不断升温，monday 的各个团队致力于将 AI 能力嵌入其原有平台。这项努力在 2025 年 5 月达到高潮，公司内部举办了一场“AI 月”活动，用四周时间集中在全公司范围内交付 AI 功能或产品。

> monday’s rebuild unfolded in three phases. In the first phase, as frontier LLM technology matured and customer excitement grew, monday teams worked on embedding AI capabilities into its original platform. The effort culminated in May 2025 with an internal “AI month,” with four weeks dedicated to shipping AI features or products across the company. 

采用率很高，也带来了兴奋感，但团队很快就遇到了天花板。“我们当时是在造‘AI 尘埃’，把自动化功能撒在现有工作流上，却没有把它们嵌入产品的根本价值主张，也没有改变这个价值主张，”monday.com AI Works 平台产品副总裁 Orly Stern Izhaki 说。“我们的功能帮助用户总结文本、对信息分类，但它们并没有形成持续的使用模式。” 

> Adoption was strong and generated excitement, but soon the team hit a ceiling. “We were building ‘AI dust’, sprinkling automations onto existing workflows without embedding them within or changing the product’s fundamental value proposition,” says Orly Stern Izhaki, VP of Product, AI Works Platform at monday.com. “Our features helped users summarize text and categorize information, but they weren’t creating sustained usage patterns.” 

这家公司需要把重心从为产品功能添加 AI，转向将 AI 原生地构建进平台之中。“采用 AI 功能并不等同于成为一家 AI 公司，”Izhaki 说。“一旦我们理解了这一点，一切都变了。”

> The company needed to shift focus from  adding AI to product features to building it natively into the platform. "Adopting AI features is not the same as becoming an AI company," Izhaki says. "Once we understood that, everything changed."

Izhaki 的团队正是这样着手彻底重塑 monday 的：从一款工作管理工具，变成一个让人与智能体协同完成工作的地方。虽然改造产品的指令来自最高层，但如何把这个北极星目标转化为具体的产品选择、并构建各自的智能体，则要靠每个团队和每位员工自己去实现。

> That’s how Izhaki’s team set out to reimagine monday completely: from a work management tool to a place where people and agents get work done together. While the mandate to transform the product came from the top, it was up to each team and each employee to translate that north star into concrete product choices and build their own agents. 

经过数月的紧张工作，该公司宣布了其历史上最重大的一次变革：围绕人类与智能体协同工作这一理念重建整个产品体验，并充分利用已内置的上下文、工作流、看板、权限和治理能力。自 2026 年 5 月推出以来，monday 的客户已在其平台上与智能体进行了超过 500 万次交互。 

> After months of intense work, the company announced the most significant change in its history, rebuilding its entire product experience around humans and agents working together, using already built-in context, workflows, boards, permissions, and governance. Since launching in May 2026, monday’s customers have had more than 5 million interactions with agents on its platform. 

#### **智能体作为团队成员**

> **Agents as teammates**

除了访问权限和限制之外，每个 monday 智能体都会被赋予一个名称和一个头像，同事们可以通过 monday 平台中的触发器和提及来为智能体分配工作。  

> Along with access permissions and restrictions, each monday agent is given a name and an avatar, and colleagues can assign agents work through triggers and mentions in the monday platform.  

这种设计是有意为之的，它针对的是 monday 在其客户群中发现的一个模式：许多企业希望让 AI 发挥作用，但往往停滞在一个与实际工作场所平行运行的 AI 聊天工具上。将智能体直接嵌入工作流，并让人们能够像与同事互动那样与它们互动，这就把智能体式 AI 从一个抽象概念变成了具体、可执行的东西。

> This design was intentional, addressing a pattern monday noticed across its customer base: many enterprises want to put AI to work, but often stall at an AI chat that runs parallel to where they actually do the work. Embedding agents directly into workflows and enabling people to interact with them like they would with their colleagues turned agentic AI from an abstract concept to a concrete, actionable one.

monday 为智能体规划的工作范围涵盖 IT 工单分类与知识库维护、候选人寻源与面试安排、面向销售和营销的竞争情报简报，以及类似参谋长的工作，例如会议准备和把决策转化为可跟踪的任务。

> The jobs monday has mapped for agents range from IT ticket triage and knowledge-base upkeep to candidate sourcing and interview scheduling, competitive-intelligence briefings for sales and marketing, and chief-of-staff work like meeting prep and converting decisions into tracked tasks.

*四种常见工作流中的智能体团队及其职责。*

> *Agent teams and their jobs for four common workflows.*

#### **在 monday 中运行 Claude 的四种方式**

> **Four ways to run Claude in monday**

客户通过四项能力在 monday 平台内使用 Claude：

> Customers use Claude inside the monday platform through four capabilities:

借助 **monday Agents**，团队可以使用提示词构建自定义智能体，并选择 Claude 作为其模型。该平台为智能体提供了名称、形象以及在看板上的位置，任何人都可以在这里给它分配工作。

> With **monday Agents**, teams can build custom agents using prompts, and choose Claude as its model. The platform gives the agent a name, a face, and a place on the board where anyone can assign it work.

**自带智能体（Bring Your Own Agent，BYOA）**让 Claude 托管智能体（Claude Managed Agents）能够加入该平台。一旦进入 monday 平台，某个人构建的智能体就能成为整个团队都可以提及并向其分配工作的队友。

> **Bring Your Own Agent (BYOA)** makes it possible for Claude Managed Agents to join the platform. Once on the monday platform, an agent one person has built can become a teammate the whole team can mention and assign work to.

**预置智能体**可在 monday 智能体商店中获取，它能把 Claude 插件变成专职的团队成员：法务团队可以在自己的工作流中以智能体的形式运行法务插件，财务团队也可以对其插件做同样的事。

> **Pre-built Agents**, available in the monday Agents Store, turn Claude plugins into specialized teammates: a legal team can run a legal plugin as an agent inside its own workflows, and finance teams can do the same with theirs.

**Claude Coding 集成**让团队能够在 monday 仪表板中接入 Claude，然后规划并向智能体分配任务。Claude Managed Agents 在客户自己的环境中执行，结果与更新会回写到工单上，随后该任务再移交给下一个智能体或交由人工审核。整个流程从业务需求出发，产出可运行的代码，再回到业务用户手中。

> **The Claude Coding integration** enables teams to connect Claude in the monday dashboard, then plan and assign agents tasks. Claude Managed Agents executes in the customer's own environment, and results and updates land back on the ticket before the task hands off to the next agent or to a human for review. The work runs from business need to working code and back to the business user.

#### **从需求简报到落地页，无需离开看板**

> **From brief to landing page without leaving the board**

一个端到端的例子：某营销团队在单个看板条目内运行一条营销活动生产线。营销人员和内容负责人在该条目上梳理简报，就目标、受众、核心信息和渠道达成一致。一个基于 monday Agents 构建的策略师智能体（Strategist Agent）会将这些原始输入转化为结构化简报，涵盖营销活动目标、信息传递支柱、渠道细分和成功指标。

> One end-to-end example: a marketing team runs a campaign production line inside a single board item. The marketer and content lead shape the brief on the item, aligning on goal, audience, key message, and channels. A Strategist Agent built with monday Agents turns that raw input into a structured brief covering the campaign objective, messaging pillars, channel breakdown, and success metrics.

接下来，落地页构建器（Landing Page Builder）接手工作。它在公司自有环境中的 Claude Managed Agents 上运行，会拉取已批准的简报，并基于现有落地页生成一个新版本，其文案、结构和信息传达都针对该营销活动做了调整。产出结果会自动回填到 monday 的对应条目上。在页面进入审批环节之前，品牌审查员（Brand Reviewer，一个 Claude Managed Agent）会依照品牌准则和法务标准对其进行检查，并标记出任何需要人工关注的地方。随后，营销经理只需做一个决定：发布，还是继续优化。

> From there, a Landing Page Builder takes over. Running on Claude Managed Agents in the company's own environment, it pulls the approved brief and generates a new variant of an existing landing page, with copy, structure, and messaging adapted to the campaign. The output lands back on the monday item automatically. Before the page reaches approval, a Brand Reviewer, a Claude Managed Agent, checks it against brand guidelines and legal standards and flags anything that needs human attention. The marketing manager then makes one decision: publish or refine.

#### **人工智能前沿的一家家族企业**

> **A family business at the AI frontier**

[Cooke](https://cookeseafood.com/) 是一家家族海鲜企业，1985 年创立于新不伦瑞克省布莱克斯港，从最初拥有 5,000 条三文鱼的单一养殖场，发展成为全球最大的家族所有制海鲜公司，业务遍及 16 个国家。如今，Cooke 在 Claude 与 monday 上共同运行项目交付、资源管理和合同管理。产品经理使用 Claude 将已批准的项目章程和需求转化为初始项目计划、生成状态报告，并识别风险与问题，这些内容会直接输入到他们在 monday 中的 RAID 日志，覆盖约 200 个在建和拟建项目。Claude 自动完成报告编制和数据准备工作，从而使 130 份合同的生命周期工作流保持准确——这类维护性工作过去既繁琐又需要人工处理。 

> [Cooke](https://cookeseafood.com/), a family seafood business founded in 1985 in Blacks Harbour, New Brunswick, has grown from a single farm site with 5,000 salmon into the world's largest family-owned seafood company, operating in 16 countries. Today, Cooke runs project delivery, resource management, and contract management on Claude and monday together. Product managers use Claude to turn approved charters and requirements into initial project plans, generate status reports, and surface risks and issues that feed straight into their monday RAID logs, across roughly 200 active and proposed projects. Claude automates the reporting and data prep that keep lifecycle workflows accurate across 130 contracts—upkeep work that used to be tedious and manual. 

“monday 和 Claude 一起帮助我们掌握团队的产能情况，并做出更明智的资源分配决策，”Cooke 的战略总监 Patti Stevens 说。“过去 monday 只是一个我们必须去更新的平台。现在，我们的运营就建立在它之上。”

> “Together, monday and Claude help us read team capacity and make smarter allocation calls,” says Patti Stevens, director of strategy at Cooke. “Monday used to be a platform we had to update. Now we operate from it.”

#### **monday.com 学到了什么**

> **What monday.com learned**

对于计划进行类似重构的公司，monday 团队分享了他们在将平台转型为 AI 优先产品过程中学到的五条经验： 

> For companies planning a similar rebuild, monday’s team shares five lessons they learned as they transformed their platform into an AI-first product: 

- **改变思维模式比改变技术更难。**人们天然地想要保护质量，并不断改进那些已经运转良好的东西。让团队从「我们如何负责任地改进当前的产品？」转向「我们如何负责任地为一个不同的未来重建它？」，所花的时间比技术工作本身更长。
- **当所有事情都在同时变化时，小团队反而跑得更快。**方向、用户体验、技术、定价、信任模型，以及公司自己对「好」的定义，全都在同时变动。层层叠加的利益相关方会丢失掉如此之多的细节，而权责清晰、决策迅速的小团队则能始终紧贴这些细节。
- **采用与否既取决于能力，也同样取决于信任。**产品与市场的契合度，取决于用户的信心，以及他们是否准备好让智能体参与到工作的实际完成方式中。治理、权限、透明度和可靠性,决定了智能体能否走出试点项目、进入生产环境。
- **能力需要与之匹配的基础设施。**当智能体建立在实时项目数据、团队历史记录和结构化工作流之上时，其表现会达到另一个层次，而在企业级规模下，后端必须扛得住。除了智能体层，monday 还投入建设了 monday DB，以便数据基础设施能够支撑智能体在整个组织中运行所带来的数据量、速度和复杂度。
- **在已经行之有效的基础上构建。** monday 一直以来都把自己描述为人们组队协作、推动业务成果的地方，而这次以智能体为先的重建，把这一承诺延伸到了一种新型的团队成员身上。人们依然来到 monday 实现自己的目标，区别在于，与他们并肩工作的一些团队成员现在是智能体。

> • **The mental model is harder to change than the technology.** People naturally want to protect quality and keep improving what already works. Moving teams from "how do we responsibly improve the current product?" to "how do we responsibly rebuild it for a different future?" took longer than the technical work.
> • **Small teams move faster when everything is changing at the same time.** Direction, UX, technology, pricing, the trust model, and the company's own definition of good were all in motion at the same time. Layers of stakeholders would lose that much detail, but small teams with clear ownership and fast decision rights stayed close to it.
> • **Adoption depends on trust as much as it does on capability.** Product-market fit depends on user confidence and preparedness to let agents into how work actually gets done. Governance, permissions, transparency, and reliability determine whether agents move beyond pilot programs and into production.
> • **Capability needs infrastructure to match.** Agents perform at a different level when they're grounded in live project data, team history, and structured workflows, and at enterprise scale the backend has to hold. Alongside the agent layer, monday invested in monday DB so the data infrastructure could support the volume, speed, and complexity of agents operating across an organization.
> • **Build on what already works.** monday has always described itself as the place where people team up to drive business outcomes, and the agent-first rebuild extends that promise to a new kind of team member. People still come to monday to achieve their goals, the difference is that some of the team members working alongside them are now agents.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| agent-first | 以智能体为先 | 在产品设计中把 AI 智能体作为首要参与者而非附加功能的架构取向。 |
| agentic AI | 智能体式 AI | 能够自主规划并执行多步骤任务的 AI 系统形态。 |
| human-AI collaboration | 人机协作 | 人类与 AI 在同一工作流中分工配合完成任务的模式。 |
| frontier LLM | 前沿大语言模型 | 处于当前能力最前沿的大规模语言模型。 |
| Bring Your Own Agent (BYOA) | 自带智能体 | 允许用户把自行构建的外部智能体接入平台并作为团队成员使用的机制。 |
| Claude Managed Agents | Claude 托管智能体 | 由 Claude 托管、可在客户自有环境中执行任务的智能体。 |
| prebuilt agents | 预置智能体 | 在智能体商店中直接获取、无需自行搭建的现成智能体。 |
| plugin | 插件 | 为特定职能扩展 AI 能力的可复用模块，可转化为专职智能体。 |
| board | 看板 | monday 平台中承载条目、任务与协作上下文的核心工作视图。 |
| trigger | 触发器 | 在满足设定条件时自动启动自动化或分配智能体任务的机制。 |
| governance | 治理 | 对权限、合规与责任边界进行管理的制度与技术安排。 |
| RAID log | RAID 日志 | 项目管理中记录风险、假设、问题与依赖的跟踪表。 |
| project charter | 项目章程 | 正式授权项目启动并界定目标与范围的文件。 |
| contract lifecycle workflow | 合同生命周期工作流 | 覆盖合同从起草到续期或终止各阶段的流程管理。 |
| product-market fit | 产品与市场契合度 | 产品满足目标市场真实需求并获得持续采用的状态。 |
| monday DB | monday DB | monday 自建的数据基础设施，用于支撑智能体规模化运行的数据量与复杂度。 |
