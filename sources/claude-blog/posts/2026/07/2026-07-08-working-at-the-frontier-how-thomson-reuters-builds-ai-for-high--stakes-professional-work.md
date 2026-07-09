---
source: claude-blog
source_url: https://claude.com/blog/working-at-the-frontier-how-thomson-reuters-builds-ai-for-high--stakes-professional-work
published_at: 2026-07-08
category: Enterprise AI
title_en: Working at the frontier: How Thomson Reuters builds AI for high-stakes professional work
title_zh: 在前沿工作：汤森路透如何为高风险专业场景打造 AI
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 0
source_image_count: 2
---

# 在前沿工作：汤森路透如何为高风险专业场景打造 AI

> Working at the frontier: How Thomson Reuters builds AI for high-stakes professional work

> 来源：Claude Blog，2026-07-08
> 原文链接：https://claude.com/blog/working-at-the-frontier-how-thomson-reuters-builds-ai-for-high--stakes-professional-work
> 分类：Enterprise AI

## 核心要点

- 汤森路透专注于对准确性和精确度要求极高的专业领域，其选用大模型的标准是：模型产出能否经受律师在采用前所施加的专业审查。
- 公司提出"受托责任级 AI"理念，强调 AI 需植根于权威内容、由深厚领域专长塑造，并直接嵌入专业工作流，使产出透明、可验证、可辩护。
- 专业级系统并非仅靠模型本身，而是将 Anthropic 前沿模型与权威内容、2700 多名领域专家、工作流集成及评估基础设施相结合的产物，最终责任仍由专业人士承担。
- 法律研究被围绕智能体重建，重点不只是检索，而是引文校验与来源核实，让原本需数十小时的研究可在几分钟内产出高质量起点。
- CoCounsel Legal 基于 Claude Agent SDK 重建，可实时规划、委派并在数百个工具与内容源之间协同，单个智能体可同时调用全部工具；客户数据受保护，不用于训练第三方模型。
- 团队总结出模型须满足的四项要求：自我校验引文、在长链工具调用中保持稳定、将人纳入产出协作过程，以及释放此前无暇处理工作的产能。
- 汤森路透作为 Anthropic 最早的企业客户之一，选择的决定性因素并非基准测试，而是其在透明度、安全性与负责任 AI 开发上的方式。

## 正文

汤森路透首席技术官 Joel Hron 多年来一直致力于将 AI 嵌入律师和会计师所信赖的产品之中。以下是他为何认为 Claude Fable 5 是知识工作 AI 可能性的一次关键演进。

> Joel Hron, CTO at Thomson Reuters, has spent years putting AI inside products trusted by lawyers and accountants. Here is why he considers Claude Fable 5 a critical evolution in what’s possible with AI for knowledge work.

汤森路透（Thomson Reuters）是一家全球性的内容与技术公司，175 多年来一直为需要做出重大决策的专业人士和机构打造可信赖的内容与技术。如今，同样的使命也在塑造这家公司为法律、税务、会计、合规及其他高风险专业工作流程构建人工智能的方式。

> Thomson Reuters, a global content and technology company, has spent more than 175 years building trusted content and technology for professionals and institutions making consequential decisions. Today, that same mission is shaping how the company builds AI for legal, tax, accounting, compliance, and other high-stakes professional workflows.

"我们是一家技术公司，专注于那些要求准确和精确的专业领域，"汤森路透首席技术官 Joel Hron 说。

> "We're a technology company focused on professions that demand accuracy and precision," says Joel Hron, CTO of Thomson Reuters.

该公司的产品是这些专业领域赖以运转的参考工具：用于法律检索和实务指导的 Westlaw 与 Practical Law；作为汤森路透专业级法律 AI 平台的 CoCounsel Legal，旨在让法律专业人士把工作做得更好，给出他们能够站得住脚的答案以及能提供真正价值的结果。四年前 Hron 所在的初创公司被汤森路透收购，他随之加入，工作处在产品、技术与战略的交叉点上。他说，在这段时间里，AI 重新定义了构建软件的含义。选择合适的技术合作伙伴从未像现在这样重要。

> Its products are the reference tools those professions run on: Westlaw and Practical Law for legal research and practical guidance, CoCounsel Legal, Thomson Reuters professional-grade legal AI platform, is designed to make legal professionals better at their jobs, with answers they can defend and outcomes that provide real value. Hron joined Thomson Reuters four years ago when his startup was acquired by the company, working at the intersection of product, technology, and strategy. In that time period, he says, AI has reshaped what it means to build software. Choosing the right technology partners has never been more important.

选择用哪些大语言模型（LLM）来支撑这些产品的标准异常具体。Hron 和他的团队评估一个新模型时会问：它的成果能否经受住律师在依赖它开展工作之前所施加的专业审查程度。

> The bar for selecting which LLMs to use to power these products is unusually concrete. Hron and his team evaluate a new model by asking whether its work can withstand the level of professional review lawyers apply before relying on it in their work.

#### 为法律工作评估模型

> Evaluating models for legal work

很多公司都能造出一款法律 AI 工具，但能造出一款律师愿意署上自己名字的工具的却少得多。汤森路透为专业 AI 带来了通用系统难以轻易复制的三项优势：权威内容、深厚的领域专长，以及工作流程集成。

> Plenty of companies can build a legal AI tool, but far fewer can build one a lawyer would put their name on. Thomson Reuters brings three advantages to professional AI that general-purpose systems cannot easily replicate: authoritative content, deep domain expertise, and workflow integration.

Hron 说，律师之所以能够依赖 Westlaw 给出的答案，靠的并不是模型本身。它靠的是数十年精心整理的判例法，是全球 2700 多位领域专家每天对这些内容进行标注和增强的工作，以及汤森路透在 Claude 等模型之上构建的评估体系。"对最终工作成果负责的，仍然是那位人类专业人士。"

> The reason a lawyer can rely on a Westlaw answer is not the model on its own, says Hron. It is decades of curated case law, the work of 2,700+ domain experts across the globe who annotate and enhance that content every day, and the evaluations Thomson Reuters builds on top of models like Claude. "That human professional is still the one who is accountable for the end work product."

Claude 是一个有价值的模型合作伙伴，但专业级系统来自于将 Anthropic 的前沿模型与汤森路透的权威内容、深厚领域专长、工作流程集成以及评估基础设施相结合。

> Claude is a valuable model partner, but the professional-grade system comes from the combination of Anthropic's frontier models with Thomson Reuters' authoritative content, deep domain expertise, workflow integration, and evaluation infrastructure.

汤森路透将这一方法称为"受托责任级 AI"（Fiduciary-Grade AI™）：这种 AI 以权威内容为根基，由深厚的领域专长塑造，并直接嵌入专业工作流程之中，从而在事关重大时输出是透明的、可验证的、且经得起辩护的。

> Thomson Reuters describes this approach as Fiduciary-Grade AI™: AI grounded in authoritative content, shaped by deep domain expertise, and embedded directly into professional workflows, so outputs are transparent, verifiable, and defensible when the stakes are high.

正是这种责任担当，使得在这里验证比表达流畅更重要。汤森路透围绕经过调优的智能体（agent）重建了法律检索，这些智能体"不仅仅是搜索，也不仅仅是检索，而是引证校验和验证"。要求是一套系统能帮助校验引证并清晰呈现来源，让专业人士能够审阅、验证并自信地运用自己的判断。

> That accountability is why verification matters more here than fluency. Thomson Reuters rebuilt legal research around agents tuned for "not just search and not just retrieval, but citation validation and verification." The requirement is a system that helps validate citations and surface sources clearly, so professionals can review, verify, and apply their judgment with confidence.

这一变化体现在客户的反馈中。Hron 说，过去"要花数十小时"的研究，现在"几分钟内"就能完成，为专业人士提供了一个高质量的起点，供其评估、完善并据以行动。"深度研究（deep research）深刻改变了思考法律检索的方式。"

> The change shows up in what customers report. Research that "would take dozens of hours," Hron says, now arrives "in a matter of minutes," giving professionals a high-quality starting point they can evaluate, refine, and act on. "Deep research has been a profound shift in how to think about legal research."

#### 构建智能体优先的产品

> Building an agent-first product

对汤森路透而言，构建智能体并不是打造一个更聪明的聊天机器人。它体现的是交付现有产品的一种新方式。Hron 和他的团队着手教会一个智能体使用公司过去以独立软件形式提供的所有工具。如今单个智能体可以同时访问公司数百种工具。

> For Thomson Reuters, building agents isn't about creating a smarter chatbot. It reflects a new way to deliver existing products. Hron and his team set out to teach an agent to use all the tools the company used to offer as standalone software. A single agent now has access to hundreds of company tools — simultaneously.

这一转变改变了汤森路透评估模型的方式。"我们对 Claude 的重大考验，是切实评估它在制定计划以及有效、正确地使用这些工具方面到底有多出色，"他说。

> That shift changed how Thomson Reuters evaluated models. "Our big test for Claude is to really assess how good it is at making plans and using these tools effectively and correctly," he says.

CoCounsel Legal 展示了这种情形的样子。它过去是一个接一个地运行各项独立技能。在 Claude Agent SDK 上重建后，它现在能够实时地跨工具和内容源进行规划、委派和编排，于是专业人士可以定义想要的结果，而不必逐步指挥每一个步骤。客户数据仍受到保护，不会用于训练第三方模型。

> CoCounsel Legal shows what that looks like. It used to run separate skills one after another. Rebuilt on the Claude Agent SDK, it now plans, delegates, and orchestrates across tools and content sources in real time, so a professional can define the outcome instead of dictating every step. Customer data remains protected and is not used to train third-party models.

Hron 将这一选择追溯到两家公司最初的合作方式。汤森路透是 Anthropic 最早的企业客户之一，而决定性因素并非某项基准测试。"最打动我们的头号因素是 Anthropic 构建企业 AI 的方法，"他说，并列举了透明、安全和负责任的 AI 开发。第一个验证点是法律领域的深度研究，由双方共同构建，因为两个团队都注意到 Anthropic 的工程师使用这些工具的方式，正是汤森路透当时已在交付产品的方式。

> Hron traces the choice back to how the two companies started working together. Thomson Reuters was one of Anthropic's earliest enterprise customers, and the deciding factor wasn't a benchmark. "The number one thing that spoke to us was Anthropic's approach to building enterprise AI," he says, citing transparency, safety, and responsible AI development. The first proof point was deep research in legal, built together as both teams noticed how Anthropic's engineers used the tools the way Thomson Reuters was already shipping them.

#### 知识工作对模型的要求

> What knowledge work demands of a model

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4c7cbf5c3bf25d312f2d36_hrh.jpg)

在这些项目中，Hron 的团队归纳出模型在获得汤森路透信任之前必须做到的四件事。

> Across those projects, Hron's team has settled on four things a model has to do before Thomson Reuters trusts it.

第一，作为 CoCounsel Legal 系统的一部分，模型必须核查自己的引证。系统不能检索到一个来源就此作罢，而必须在把研究结果呈交人类做最终审阅和验证之前，先校验它所引用的内容。

> First, the model, as part of the CoCounsel Legal system, has to check its own citations. Rather than retrieve a source and move on, the system has to validate what it cites before presenting its findings to a human for final review and verification.

在这一系统中，模型还必须在长链条的工具调用中保持稳定。更长的任务要求在持续运行中做好更好的上下文管理，并可靠地使用工具。模型必须在多个步骤、多个系统间保持连贯的思路，这样智能体（agent）才能完成真正的工作，而不是半途卡住。

> In this system, the model also has to hold steady across long chains of tool calls. Longer tasks demand better context management and dependable tool use over an extended run. A model has to keep the thread across many steps and many systems, so an agent finishes real work instead of stalling halfway through.

它还必须把人带入工作过程中，而不只是给出答案。对于最艰难的任务，Hron 希望有一个能"把人带入产出成果的开发过程，而不是仅仅依赖智能体一次性给出答案"的模型。

> It also has to bring a person into the work, not just the answer. For the hardest jobs, Hron wants a model that will "bring the human into the loop of developing a work product rather than just relying on the agent to one shot an answer."

最后，它还必须为汤森路透（Thomson Reuters）团队此前没有精力处理的工作腾出时间。汤森路透正在为复杂的法律工作开发高级起草能力，包括动议起草和专业人士原本要"花费数天甚至数周去打磨"的文书，他说。这类任务"一直对早期模型要求过多的上下文和精度"。而有了 Claude Fable 5，如今已触手可及。

> And finally, it has to free up time for work the Thomson Reuters team didn't have bandwidth to tackle before. Thomson Reuters is developing advanced drafting capabilities for complex legal work, including motion drafting, filings that professionals would otherwise "spend days or weeks perfecting," he says. The task "always required far too much context and precision" for earlier models. With Claude Fable 5, it's now within reach.

#### AI 的投资回报

> The ROI of AI

Hron 对 AI 的投资回报（ROI）持有一种反主流的观点，其他正在推广模型的领导者或许会觉得有用。"如果你太过想去优化回报率的计算，就会只见树木不见森林，"他说。他希望团队先感受到文化和思维方式的转变，然后再去调优每项任务的成本。一旦这种思维转变发生，回报自然随之而来。

> Hron takes a contrarian view on AI's return on investment, one other leaders rolling out models might find useful. "If you try to optimize too much for the rate of return calculation, you miss the forest for the trees," he says. He wants teams to feel the cultural and mindset shift before they tune for cost per task. Once that mindset shift happens, the returns follow on their own.

他仍然跟踪传统的工程指标，例如 DevOps 研究与评估（DORA）以及从想法到投产的时间，并且他提到一款基于 Claude 构建的内部错误修复工具，它把一个生产问题从三小时的根因分析变成了四分钟的修复。"能在几分钟而非几小时内恢复健康，这是实质性的差别。"

> He still tracks traditional engineering measures like DevOps Research and Assessment (DORA) and time from idea to production, and he points to an internal error-remediation tool built on Claude that turned a production issue from three hours of root cause analysis into a four-minute fix. "The ability to get back to health within minutes versus hours is a material difference."

据 Hron 所说，更深层的变化在于工作本身。

> The deeper change, according to Hron, is to the work itself.

"编写一行行代码这件事已不再是工作本身，"Hron 谈到他的工程师时说；如今最重要的技能是系统性思维、判断力和品味。他看到同样的模式正扩展到工程之外，AI 让人变得"更呈 T 型"，能够横跨产品、设计和财务，而不是固守某一条赛道。

> "The act of writing lines of code is no longer the job," Hron says of his engineers; the skills that matter most now are systems thinking, judgment, and taste. He sees the same pattern spreading past engineering, with AI making people "more T-shaped," able to reach across product, design, and finance rather than staying in one lane.

#### 接下来是什么

> What's next

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4c7c0af419ea78652cbbb0_000261730019_VS_R1_web.jpg)

Hron 和他的团队渴望用 Claude Fable 5 及未来的 Claude 模型去突破边界：更长时间跨度的工作、更好的上下文管理，以及在智能体运行的整条任务链条中都能信赖的工具调用。

> Hron and his team are eager to push the boundaries with Claude Fable 5 and future Claude models: longer-horizon work, better context management, and tool calling they can count on across the chain of tasks an agent runs.

他同样渴望在自己的工作中使用这些模型。Claude Code 让他"重新变得技术性强了很多"，能在几分钟而非一天内熟悉一个他已数月未碰的代码库；他还借助 Claude Cowork 站在首席财务官（CFO）或战略官的视角来压力测试各种想法。

> He is just as eager to use these models in his own work. Claude Code has let him "be far more technical again," coming up to speed on a codebase he hasn't touched in months within minutes rather than a day, and he turns to Claude Cowork to take on the perspective of a CFO or strategy officer and pressure-test ideas.

这些正是 Claude Fable 5 这类模型的构建方向，而对于最终必须在法庭上经得起考验的工作，Hron 认为这就是下一个值得发力的前沿。毕竟，专业级 AI 必须在"接近正确还不够好"的环境中运转。

> Those are the directions models like Claude Fable 5 are being built around, and for work that ultimately has to hold up in court, Hron sees that as the frontier worth pushing on next. After all, professional AI has to work in environments where being almost right is not good enough.

开始使用 [Claude Fable 5](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5-and-claude-mythos-5)。

> Get started with[Claude Fable 5](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5-and-claude-mythos-5).

## 术语对照

| English | 中文 |
|---|---|
| frontier model | 前沿模型 |
| high-stakes professional work | 高风险专业工作 |
| Fiduciary-Grade AI | 受托责任级 AI |
| authoritative content | 权威内容 |
| domain expertise | 领域专长 |
| workflow integration | 工作流集成 |
| citation validation | 引文校验 |
| verification | 核实 |
| agent | 智能体 |
| agent-first product | 智能体优先产品 |
| Claude Agent SDK | Claude 智能体开发套件 |
| tool use | 工具调用 |
| context management | 上下文管理 |
| human in the loop | 人在回路 |
