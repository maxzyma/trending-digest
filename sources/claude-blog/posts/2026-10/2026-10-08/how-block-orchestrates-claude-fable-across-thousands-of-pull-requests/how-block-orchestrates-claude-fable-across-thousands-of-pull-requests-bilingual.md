# Block 如何在数千个拉取请求中编排 Claude Fable

> How Block orchestrates Claude Fable across thousands of pull requests

> 来源：Claude Blog / Anthropic，2026-10-08
> 原文链接：https://claude.com/resources/articles/how-block-orchestrates-claude-fable-across-thousands-of-pull-requests
> 分类：AI 工程 / 智能体编排

## 核心要点

- 前沿模型使 Block 的设计与工程工作转向设计迁移方案、审查智能体行为和构建更多面向客户的功能。
- Block 认为 AI 将帮助小企业处理后台运营、帮助 Cash App 用户管理个人财务，未来产品可能按需即时构建。
- 在大规模代码迁移中，Fable 负责数据模型、API 规范和算法等高层设计，并调度数十个 Opus 或 Sonnet 等较小模型执行修改文件和运行测试等具体任务。
- 编排器先用前沿模型完成复杂规划，再把更多 token 分配给较小模型，早期结果显示成本更低且质量未下降。
- 整套多智能体系统运行在开源协作工作空间 Buzz 上，人类与智能体在共享频道和讨论串中协同工作。
- Block 用智能体定期巡检约百万行规模的代码库，以应对 PR 数量激增带来的技术债加速累积。
- Block 向所有技术员工开放前沿模型，同时构建自动选择器，帮助员工为不同任务挑选合适的模型。
- Bradley Axen 认为 effort 等级与模型构成一张需要整体优化的网格，评测时需覆盖每个模型的每个 effort 等级。
- 合并到 main 分支、部署生产环境和功能开关变更始终由人决定，部署需两人批准，智能体无法独自推送此类变更。
- Block 通过远程工作站、网络允许列表、无需模型参与的廉价检查以及模型内置安全机制构建默认安全的系统。
- Block 致力于把一线实践者积累的上下文与组织知识沉淀到系统层面，让每次运行智能体都能获得最佳上下文。

## 正文

Block 致力于打造帮助企业和个人参与经济活动的工具，包括面向商家的 Square 和面向消费者的 Cash App。Bradley Axen 负责领导 Block 的 AI 能力建设，他的团队构建端到端的 AI 产品，其中包括 Buzz——一个面向[人机协作团队（在新标签页中打开）](https://claude.com/blog/building-effective-human-agent-teams)的开源工作空间，并与 Square 和 Cash App 团队合作打造面向客户的 AI 功能。Brad 与 Anthropic 进行了交流，谈到了 Claude Opus 5 和 Claude Fable 5 等前沿模型如何改变了工程师的内涵，Block 如何借助 Fable 应用智能体编排模式，以及在每位员工都能使用前沿模型的情况下安全防护措施所发挥的作用。

> Block builds tools that help businesses and individuals participate in the economy, including Square for sellers and Cash App for consumers. Bradley Axen leads AI capabilities at Block, where his team builds end-to-end AI products, including Buzz, an open-source workspace for [human-agent teams (opens in new tab)](https://claude.com/blog/building-effective-human-agent-teams), and partners with the Square and Cash App teams to build customer-facing AI features. Brad spoke with Anthropic about how frontier models like Claude Opus 5 and Claude Fable 5 have transformed what it means to be an engineer, how Block applies agent orchestration patterns with Fable, and the role of safeguards when every employee has access to frontier models.

#### **前沿模型在 2026 年取得了实质性进展。这项技术对你的工作方式产生了怎样的影响？**

> **Frontier models have made meaningful progress in 2026. How has this technology impacted how you work?**

AI 对我们在 Block 的工作影响最大的，是我们构建产品的方式，而这种影响无论怎么强调都不为过。我们在 2025 年就借助 Claude Code 等工具看到了它的开端，不过当时这些工具还需要大量人工干预。随着模型变得越来越智能，设计和工程工作已转向设计迁移方案本身、审查智能体的行为，以及构建更多面向客户的功能，而这一直都是我们的目标。

> The biggest impact AI has had on our work at Block is how we build things, and you couldn't overstate how impactful that is. We saw the beginning of it in 2025 with tools like Claude Code, which at the time, required a lot more manual intervention. As models become more intelligent, design and engineering work has shifted toward designing the migrations themselves, reviewing agent behavior, and building more customer-facing features, which was always the goal.

下一阶段是通过 Block 的产品，把这些变革性技术带给我们的客户。AI 在帮助小企业处理它们不愿花时间应付的后台运营事务方面，或在帮助 Cash App 客户管理个人财务方面，同样能创造巨大的价值。借助 Claude，我们拥有了一个全新的技术杠杆，它可以改变人们对软件能为自己做什么的预期。想象一下，如果 AI 能够响应客户需求，并即时构建新的界面，会怎样？我越来越认为，我们的产品将借助 AI 按需构建，用来解决具体问题。

> The next phase is to bring these transformative technologies to our customers, through Block’s products. There's just as much value AI can bring to helping a small business handle the back-of-house operations it doesn't want to spend its time on, or to helping a Cash App customer manage their finances. With Claude, we have a whole new lever in technology that can change what people expect software to do for them. Imagine if AI could respond to customer needs and build new interfaces on the fly? Increasingly, I think our products will be built on demand with AI to solve specific problems.

#### **随着前沿智能不断演进，你的团队现在能做到哪些几个月前还做不到的事情？**

> **As frontier intelligence evolves, what can your team do now that it couldn't do a few months ago?**

Claude 较新的前沿模型带来的最大变化，是我们构建软件的规模。编写代码仍是核心环节，但如今我们会借助 AI 完成全公司范围的迁移。我们都怀揣这个梦想很久了，而在 2025 年它鲜少成真。在 Claude Fable 5 之前，问题必须结构格外清晰，前沿模型才能真正大放异彩。

> The biggest thing that has changed with Claude’s newer frontier models is the scale at which we can build software. Writing code is still the core component, but now we'll do company-wide migrations with AI. We've all had that dream for a long time, and in 2025 it rarely panned out. Before Claude Fable 5, you had to have a particularly well-shaped problem for frontier models to really shine.

到 2026 年，AI 已成为我们开展所有大规模代码迁移的重要组成部分。对我们而言，一次迁移可能意味着跨多个代码仓库、涉及数百万行代码的数百乃至数千个独立的 pull request。过去，这些工作需要由人来协调，而模型一次只能承担一个或少数几个 PR。有了 Fable，我们看到它能够跨多个会话统筹这些工作。由人类工程师把握方向，Fable 专注于更高层次的设计工作：数据模型、API 规范、算法。随后，它会调度多达数十个更小、更具成本效益的模型（如 Opus 或 Sonnet）来完成各项具体任务，例如实际修改文件和运行测试。

> In 2026, AI is a major part of how we run all large-scale code migrations. For us, a migration might mean hundreds or thousands of individual pull requests across multiple repos and millions of lines of code. In the past, humans had to coordinate that work, and models could take on one or a few PRs at a time. With Fable, we're seeing it orchestrate the work across many sessions. A human engineer steers, and Fable focuses on the higher-level design work: data models, API specs, algorithms. It then directs up to dozens of smaller, more cost-effective models like Opus or Sonnet to do the individual tasks, such as making the actual file edits and running tests.

从经济性上看，这套方案相当划算。早期结果显示，编排器会先用前沿模型的 token 完成复杂的前期规划，再把更高比例的 token 分配给较小的工作模型，而质量并没有下降。整套系统运行在 Buzz 上——这是我们开源的协作工作空间，人类与 AI 智能体在共享的频道和讨论串中并肩工作。它让我们能够清晰地掌握团队的进展情况。

> The economics work out well. Early results show the orchestrator using frontier tokens for complex, upfront planning before driving a higher percentage of tokens to smaller worker models, without a drop in quality. We run the whole setup on Buzz, our open source collaboration workspace where humans and AI agents work side by side in shared channels and threads. It gives us great visibility into how the team is progressing.

在任何一次迁移中，我们都可能合并上千个由 Fable 编排的拉取请求。这让工程师能够专注于困难的设计决策，而不是机械性的工作。

> In any given migration, we might merge a thousand pull requests orchestrated by Fable. That lets engineers focus on the hard design decisions instead of the mechanical work.

#### **什么情况下应选择 Claude Fable 模型，而不是其他选项？**

> **When do you use Claude Fable models over other options?**

从那以后，许多模型都开始缩小差距，Opus 也非常出色，但 Fable 一推出，你一次能够承担的问题规模就出现了巨大的跃升。Block 的团队被它吸引，并开始探索再上升一个抽象层级、再扩大一个规模层级意味着什么。

> A lot of models have started to close the gap since, and Opus is very good too, but the moment Fable came out, it was a big step change in how large a problem you could take on at once. Teams at Block gravitated to that and started figuring out what it means to move up another level of abstraction, another level of scale.

如今，我们讨论的很多内容都围绕模型效率展开。这正是模型编排发挥作用的地方：当你用 Fable 攻克一个大问题时，它的前沿智能最能体现价值，而代码改动中的大量细节，我们则交给更小的模型来补全。这确实是自我们开始用 LLM 写代码以来，我记忆中第一次答案不再只是“100% 的时间都用最前沿的模型”。

> Now, a lot of our conversation is about model efficiency. That's where model orchestration comes in: Fable’s frontier intelligence is most valuable when you're tackling a big problem with it, and then we look to smaller models to fill in a lot of the details on code changes. It's literally the first time I can remember since we started using LLMs for code where the answer wasn't just "use the most frontier model 100% of the time."

模型编排是我们如今构建产品的重要组成部分，这意味着我们需要新的工具。有些工具非常侧重于单次对话，当你时刻有 45 个智能体与你协同工作时，界面就跟不上了。这也是 Buzz 发挥作用的另一个地方。我们在 Buzz 中提供了多智能体工作流，并且我们坚信，未来将是多人与众多智能体对话，由组织为常规任务选择高效的模型，为更大的难题选用前沿模型。

> Model orchestration is a big part of how we build things today, and it means we need new tools. Some tools are very single-conversation focused, and the interface doesn't keep up with you having 45 agents working with you all the time. That's another place Buzz comes in. We have multi-agent workflows in Buzz, and we really think the future is multiple people talking to many agents, with the organization picking the efficient models for routine tasks and frontier models for bigger problems.

#### **你交给 Fable 的最难的问题是什么？**

> **What's the hardest problem you've thrown at Fable?**

第一类是大规模迁移：涉及数千个 PR 的迁移，由 Fable 编排完成这些工作的整个系统。

> The first is large-scale migrations: multiple-thousand-PR migrations where Fable orchestrated the whole system that did the work.

第二个是接手一个大型代码库，规模大约在一百万行代码左右，并确保它不会每天都在累积技术债。我们现在提交的 PR 比以往任何时候都多。大家交付的功能和改动多了很多，因此我们的系统累积技术债的速度也比以往任何时候都快，而我们一直缺少一种与之相应、能提升维护能力的东西。现在这终于实现了。我们有智能体每天或每周对整个代码库做一轮巡检，问一问：“这里情况怎么样？有哪些需要清理和整合的？”

> The second is taking a large codebase, something in the neighborhood of a million lines of code, and making sure it's not growing tech debt every day. We are shipping more PRs than ever before. People are shipping a lot more features and a lot more changes, so our systems accumulate tech debt faster than ever, and we've been missing the corresponding thing that speeds up our ability to maintain them. That's finally happening. We have agents that do daily or weekly passes across a whole codebase asking, "How's it going in here? What do we need to clean up and consolidate?"

#### **在广泛开放访问的情况下，如何推动高效使用前沿模型？**

> **With broad access, how do you drive efficient use of frontier models?**

我们为所有技术岗位的员工提供最前沿模型的完整访问权限，因为我们战略的一个重要部分，就是始终在可能性的边缘开展工作。

> We give anyone in a technical role full access to the most frontier models, because a big part of our strategy is to always be working at the edge of what's possible.

用 Fable 来修正 README 里的一个拼写错误，是对资源的极大浪费。因此，我们需要更好的系统，来为特定任务推荐合适的模型。为此，我们一直在构建一个自动选择器，帮助员工决定在什么时候使用哪个模型。由大小不一的前沿模型共同驱动的多智能体系统也在这方面发挥了作用。

> Using Fable to fix a typo in a README is a very bad use of resources. So we needed better systems for suggesting which model to use for given tasks. To accomplish this, we’ve been building an auto-selector that helps employees choose which model to use, when. Our multi-agent systems powered by a mix of larger and smaller frontier models help too.

作为一家公司，我们目标的很大一部分是默认以高效的方式运作，而这正是我们现在正在培养的能力。我们有很多出色的模型可供选择。如果每个人都能熟练地为合适的任务挑选合适的模型，我们的成本效益就能大大提升，同时不会拖慢我们的速度。

> A big part of our goal as a company is to operate efficiently by default, and that's the skill we're building now. We've got a lot of great models to choose from. If everyone gets good at picking the right model for the right task, our cost effectiveness goes a lot further without slowing us down.

#### **你们是否建议采用特定的优化策略，比如 effort 等级？**

> **Do you advise specific optimization strategies, like effort levels?**

即便是我这样整天和 LLM 打交道的人，有时也几乎觉得，同一个模型在 xhigh effort 下和在 medium 下简直像是两个不同的模型。我并不把 effort 等级看作一条可以沿着走的连续谱。低 effort 下的 Fable 可能就是比另一个模型在 xhigh 下表现更好。所以我把它看作一张更大的网格，需要我们在其上进行优化。我们评测的每一个用例，不仅要检查每一个模型，还要检查每个模型的每一个 effort 等级。

> Even as someone who works with LLMs all day, I almost feel like a model at xhigh effort is a different model than the same model at medium. I don't think of effort levels as a spectrum you walk along. Fable on low might just be better than another model on xhigh. So I think of it as a bigger grid we need to optimize against. Every single use case we benchmark, we check not just every model but every effort level of every model.

作为在核心层面负责我们如何使用 AI 的人，我希望得到非常明确的建议，比如：“对于这类任务，默认使用这个模型的 high 档位。”我们必须尽可能让工具自动做到这一点，然后在专家想要探索时再放手让他们去探索。

> As someone working centrally on how we do AI, I want recommendations that are really clear, such as: "Use this model on high as the default for this kind of task." We have to make the tools do that automatically as much as possible, and then let experts explore when they want to.

#### **在当今的前沿模型中，你们如何考虑引入安全防护措施？**

> **How are you thinking about incorporating safeguards with today's frontier models?**

有些事情至关重要，必须有保障，我们还没准备好让 LLM 在我们的代码库里放手去做。合并到 main 分支和部署到生产环境，以及功能开关等相关变更，我们始终交由人来决定。智能体可以修改代码，但这些修改必须通过我们的安全检查，然后还需要两个人批准部署。这道双人审批机制使得 LLM 不可能独自推送这类变更。

> Some things are so critical that you need guarantees, and we're not ready to let LLMs loose on our codebase. We always leave merges to main and deploys to production up to people, along with related changes like feature flags. Agents can make code changes, but those changes have to pass our security checks, and then two humans have to approve the deploy. That dual-approval layer makes it impossible for an LLM to push those kinds of changes on its own.

从更底层来看，令人惊讶的是，一个员工如果不留神，能在自己的笔记本电脑上做出多少事情，而这些事情你原本以为人类不会去做，因为他们知道不该做。这把我们推向了一些有趣的方向。我认为未来工作的很大一部分会是远程工作站，因为它们更容易保障安全（而且还能帮助解决 LLM 存在的其他问题，比如把磁盘空间占满）。我们安全策略的很大一部分是构建默认安全的系统：使用网络允许列表而非拒绝列表，诸如此类的做法，可以阻止最严重的那类问题。

> At a lower level, it's surprising how many things an employee can do on their laptop if they're not paying attention, things you assume humans won't do because they know not to. That pushes us in interesting directions. I think a lot of the future of work is remote workstations, because they're easier to secure (and they help with other problems LLMs have, like filling up disk space). A big part of our security story is building systems that are secure by default: a network allow list instead of a deny list, and things like that, which stop the worst kinds of problems.

我们还会尽可能把工作移出模型循环。我们的许多安全护栏其实是非常廉价、高效的检查，运行时完全不需要模型参与。我们把这些检查直接构建到人们日常工作所用的界面中。有时甚至只是一个正则表达式。如今，越来越多的小型分类器也加入了进来。

> We also try to get as much as possible out of the model loop. A lot of our security guardrails are really cheap, efficient checks that run without the model needing to be involved. We build those into the interfaces people use to do work. Sometimes it's even a regex. Increasingly, smaller classifiers are part of the picture too.

此外，在日常工作中，还有一大类事情是你希望放开、以提升大家工作效率的，对这些事情加以拦截并不值得。我们有意让模型提交 PR、审查代码，以及查询我们的日志系统和分析型数据库，这一切都是为了帮助大家更快地推进工作。

> Then in the day to day, there's a whole class of things you want to enable to make people productive, where blocking isn't worth it. We intentionally let the model open PRs, review code, and query our logging systems and analytical databases, all to help people move faster.

这正是模型内置安全防护机制至关重要的地方。我指的是 Fable 和其他前沿模型经过调优、不会参与危险活动的方式，以及 [Anthropic 自己的安全分类器（在新标签页中打开）](https://www.anthropic.com/news/claude-fable-5-mythos-5)。在我们的测试中，即使有人要求 Claude「绕开」我们的双重审批系统，它也会拒绝尝试绕过。这也是我们会进行基准测试的内容。

> That's where the model's built-in safeguards are really critical. By that, I mean the way Fable and other frontier models are tuned to not take part in dangerous activities, plus [Anthropic's own safety classifiers (opens in new tab)](https://www.anthropic.com/news/claude-fable-5-mythos-5). In our testing, even if someone asks Claude to "hack around" our dual-approval system, it refuses to try to bypass it. It's something we benchmark, too.

#### **对于其他使用前沿模型的工程团队，你们有什么建议吗？**

> **Any advice for other engineering teams working with frontier models?**

我们有成千上万的人在使用 AI，不断拓展它能力的边界。他们作为个人在摸索哪些方法行之有效，同时也在改进身边的系统。比如，我的笔记本电脑上就有一堆本地技能，让我能够在 Square 的 Web 前端上开展工作，尽管我本职并不是前端开发者。当所有这些上下文和组织知识都在系统层面而非个人层面被记住时，组织才算真正走向成熟。

> We have thousands of people working with AI who are pushing the frontier of what it can do. They're learning what works as individuals, and they're improving the systems around them. I've got a bunch of local skills on my laptop that make it possible for me to work in our Square web front end, for example, even though I’m not a front-end developer by trade. Organizational maturity comes when all of this context and organizational knowledge is remembered at a system level, not an individual level.

我们的目标是把从一线实践者身上学到的一切记录下来，并纳入一个让所有人都能受益的系统中。这样，每次运行智能体时，你都能确信它拥有最佳的上下文，从而更好地助力你的工作。

> Our goal is to document everything we're learning from people doing the work and put it into a system where everyone benefits, so every time you run an agent, you know it has the best context available to contribute to your work.

*立即开始使用 [Claude Fable 5.1（在新标签页中打开）](https://www.anthropic.com/claude/fable)。*

> *Get started with [Claude Fable 5.1 (opens in new tab)](https://www.anthropic.com/claude/fable) today.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Agent Orchestration | 智能体编排 | 由一个主模型规划任务并调度多个智能体协同执行的模式。 |
| Orchestrator | 编排器 | 负责任务分解、规划并分派给工作模型的上层模型或组件。 |
| Worker Model | 工作模型 | 由编排器调度、执行具体子任务的较小且更具成本效益的模型。 |
| Pull Request | 拉取请求 | 向代码仓库提交变更并请求审查与合并的协作机制，常缩写为 PR。 |
| Code Migration | 代码迁移 | 将代码库从旧的结构、接口或技术栈系统性地改造到新形态的工程工作。 |
| Technical Debt | 技术债 | 为求快速交付而积累的、日后需要额外投入清理的代码质量问题。 |
| Effort Level | effort 等级 | 控制模型在推理上投入多少计算与思考深度的参数档位。 |
| Frontier Model | 前沿模型 | 能力处于当前最高水平的大型 AI 模型。 |
| Token | token | 语言模型处理文本时的基本计量单位，也常用于衡量调用成本。 |
| Feature Flag | 功能开关 | 无需重新部署即可在运行时启用或关闭特定功能的配置机制。 |
| Allowlist | 允许列表 | 仅放行明确列出项目、默认拒绝其余一切的访问控制方式。 |
| Denylist | 拒绝列表 | 仅拦截明确列出项目、默认放行其余一切的访问控制方式。 |
| Classifier | 分类器 | 对输入内容进行类别判定的模型，常用于安全风险检测。 |
| Guardrail | 安全护栏 | 限制系统或模型行为以防止危险或不当操作的防护措施。 |
| Remote Workstation | 远程工作站 | 托管在服务器端供员工远程使用的开发环境，便于集中管控与保障安全。 |
