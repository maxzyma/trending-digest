# Warp 如何基于 Claude 构建自我改进的智能体

> How Warp builds self-improving agents on Claude

> 来源：Claude Blog / Anthropic，2026-08-26
> 原文链接：https://claude.com/blog/how-warp-builds-self-improving-agents-on-claude
> 分类：AI 工程 / 智能体架构

## 核心要点

- 智能体若只能完成八成任务，会给用户带来嘈杂且令人厌烦的使用体验，因此可靠性直接决定产品策略。
- Warp 内部的代码审查智能体一度输出无用评论和低质量结果，工程师对此提出了抱怨。
- 手动改写提示词和优化 AGENTS.md 之类的上下文文件能缓解问题，但都无法规模化，算不上完整解决方案。
- 问题的根源在于针对智能体的反馈通常在会话结束时就消失了，使智能体循环失去关键上下文。
- 自我改进架构由内层基础技能承载领域知识、外层改进器技能作为观察者智能体定时运行，中间引入人类反馈。
- 改进器技能会比对智能体建议与人类实际响应，针对基础技能提出小而聚焦的修改，并以 PR 形式走常规代码评审流程。
- 编写技能的经验包括写原则而非规则、解释规则背后的原因、让提供反馈毫不费力、保持技能文件短小并采用渐进式披露。
- 来自领域专家的少量详细反馈就能提供良好信号，二元的点赞点踩无法说明原因，但高质量信号的语料库越大越好。
- 改进器技能除领域知识部分外具有很强的跨用例复用性，因此在其上投入的精力回报超出单个智能体循环。
- 问题分诊智能体的实例中，维护者在 issue 上留下说明期望与原因的反馈，改进器智能体运行捆绑的 Python 脚本汇总反馈并提交技能修改 PR，人工合并后下一次运行即继承新知识。

## 正文

*在我们的系列文章 中，我们重点介绍初创公司如何用 AI 变革各自的行业。本文分享 Warp 如何将无状态的用户反馈转化为其智能体的自我改进循环。*

> *In our series, , we highlight how startups are transforming their industries with AI. In this article, we share how Warp turned stateless user feedback into a self-improvement loop for its agents.*

智能体需要可靠且高效地处理重复性任务。一个只完成 80% 任务的初版提示词，会给用户带来嘈杂而烦人的体验。Warp 通过艰难的实践认识到了这一点，并以此指导其产品策略，为全球近 100 万名开发者创造了更好的体验。

> Agents need to handle recurring tasks reliably and effectively. A first-pass prompt that gets 80% of the task correct can create a noisy and annoying experience for the user. Warp learned this the hard way, and used this to inform its product strategy, creating an improved experience for nearly 1M developers worldwide.

Warp 是一款由 AI 驱动的终端和智能体开发环境，构建在 Claude Platform 之上。该团队在其内部代码审查智能体上遇到了这种“嘈杂体验”的问题。工程师们抱怨他们的智能体给出了无用的评论，并产生了低质量的输出。

> Warp, the AI-powered terminal and agentic development environment, builds on the Claude Platform. The team ran into this “noisy experience” problem with their internal code review agent. Engineers complained that their agent made unhelpful comments and produced low-quality output.

团队最初尝试了权宜之计，比如根据观察到的代码评审失败案例手动改写提示词。这让输出更可用了，但无法规模化。改进 AGENTS.md 之类的上下文文件也有帮助，但远远算不上完整的解决方案。

> The team initially tried stopgap solutions, like manually rewriting the prompt based on observed code review failures. This made output more usable but didn’t scale. Improving context files like AGENTS.md also helped, but was far from a complete fix. 

他们最终意识到，真正的问题在于：对智能体的反馈，无论出于什么目的，通常都会在会话结束时消失，从而使智能体循环失去关键上下文。他们的解决方案是：一个基于[Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)的框架，用于创建可自我改进的智能体，让反馈随时间不断累积，从而持续优化和提升智能体的输出。 

> Ultimately, they realized, the real issue was that feedback to an agent, no matter what its purpose, typically disappears when the session ends, removing critical context from the agentic loop. Their solution: an [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)-based framework to create self-improving agents where feedback compounds over time to continually refine and enhance agent output. 

继续阅读，了解他们如何基于 Claude Platform 使用 skills 构建了它。

> Read on to learn how they built it with skills on top of the Claude Platform. 

#### **基于技能构建的智能体自我改进循环**

> **Agent self-improvement loops built on skills**

核心技术是一个利用[技能](https://support.claude.com/en/articles/12512176-what-are-skills)的自我改进循环，技能是以文件为载体的知识编码方式，可以把指令从原始提示词中剥离出来。Warp 演化出了一种自我改进的智能体架构，它由两个技能组成，中间引入人类反馈。

> The central technique is a self-improvement loop using [skills](https://support.claude.com/en/articles/12512176-what-are-skills), which are file based encodings of knowledge that keep instructions out of the raw prompt. Warp evolved a self-improving agent architecture consisting of two skills, with human feedback in between. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8f1a9a1b33f40618a9d59a_selfimprove-loop.jpg)

**内层/基础技能**承载着功能领域的知识和指令。例如，当一个 PR 被创建时，Warp 的代码智能体便会基于该基础技能和上下文来执行，从而生成它的评审意见。

> The **inner/base skill** holds the functional domain knowledge and instructions. For example, when a PR is opened, Warp’s code agent executes using that base skill and context to produce its review.

**人类反馈**对智能体输出而言，是自我改进循环中的关键一环。对于代码审查来说，这种反馈可以简单到只是一个点赞，但越明确越好。

> **Human feedback **on agent output is a critical component for the self-improvement loop. For code review this could be something as simple as a thumbs up, but the more explicit the better. 

“人可以确认‘这条评论很好、很有用’，”Warp 创始人 Zach Lloyd 解释道，“但人也可以详细说明某次代码审查为什么不好。诸如‘你建议重命名这个变量，但我们代码库的约定是这类全局变量要使用这种特定的命名方式’这样的具体反馈，能告诉智能体下次该怎么做才对。”

>  “A human could affirm, ‘this was a good, useful comment’,” Warp founder Zach Lloyd explains, “But the human could also give detailed reasons why a code review wasn't good. Specifics like ‘you suggested renaming this variable, but our code base convention is this type of global variable uses this particular naming context’ tell the agent how to do it right next time.”

**外层/改进器技能**作为一个观察者智能体运行，它按计划定时执行，而非按任务执行。它会提取积累的人类反馈，将智能体的建议与人类的实际响应进行比对，并针对基础技能提出一处小而聚焦的修改。

> The **outer/improver skill** functions as an observer agent that runs on a schedule rather than per-task. It pulls the accumulated human feedback, compares what the agent suggested against how humans responded, and proposes a small, focused edit to the base skill.

由于技能就是普通文件，智能体极其擅长更新它们。这些更新是可审阅、可批准、可合并的，能够通过常规的 PR/代码评审流程流转；一旦合并，内层技能的下一次运行就会继承这项改进。

> Because skills are plain files, agents are extremely good at updating them. These updates, which are reviewable, approvable, and mergeable, can flow through a normal PR/code-review workflow; once merged, the next run of the inner skill inherits the improvement. 

Warp 现在已在其整个开源仓库中运行这一模式，配备了各自独立的规范撰写、评审和分诊代理，每个代理都带有自己的自我改进循环。

> Warp now runs this pattern across its entire open-source repo, with separate spec-writing, review, and triage agents, each carrying their own self-improvement loop.

“基于文件的技能是一种为智能体编码知识的方式，无需把这些知识直接放进提示词中，而是让智能体在工作过程中可以随时查阅，”Zach 说。“这个框架其实非常简单：先有一个基础的领域特定技能，然后有一个改进者技能来打磨这个领域特定技能。这种简单性正是该方法的精妙之处。”

> “File-based skills are a way of encoding knowledge for agents without putting that knowledge directly in the prompt, as something the agent can simply look up in the course of doing its job,” says Zach. “The framework is really simple actually: there's the base domain-specific skill and then there's the improver skill that refines  that domain-specific skill. This simplicity is the beauty of this approach.”

#### **如何为智能体编写自我改进的技能**

> **How to write self-improving skills for agents**

以下是 Warp 团队在为智能体循环编写自我改进技能时屡试不爽的一些技巧：

> Here are some of the Warp team’s tried and true tips for writing self-improving skills for agentic loops: 

- **写原则，而不是规则。**“构建技能时，要像是在指导一个聪明人，而不是像在给计算机编程，”Zach 说。“在技能中加入‘留意重复的代码’这样的指引，比详尽的变量命名规则能提供更好的方向。”
- **解释原因。**给出规则背后的理由，能让 agent 针对问题进行推理，而不是死板地遵循指令，这同样带来更好的泛化能力。
- **让提供反馈变得毫不费力。**在人们已经工作的地方收集反馈，比如直接在 PR 或 issue 上评论。同时，让这一切自动发生，无需额外的提交步骤。“低摩擦才能让信号持续流动，”Zach 指出。“如果你把它弄得太难，你就得不到反馈，也就无法提升这项技能。"
- **保持技能文件短小，并采用渐进式披露。** [一个好的技能](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)文件篇幅不大；它会引用资源文件和脚本，而不是把所有内容一次性塞进上下文。 
- **反馈质量 > 数量，但数量也有帮助。** 来自资深工程师的少量详细、针对特定领域的反馈，可能比大量草率的反馈更有价值，因为二元的点赞/点踩并不能说明*为什么*。“如果反馈非常详细，并且来自一个掌握智能体本来无从获取的领域专有知识的人，那么即使样本量相对较小，你也能获得非常好的信号，”Zach 继续说道。“话虽如此，高质量信号的语料库越大越好。在 Warp，我们正用一个循环来管理我们整个开源仓库。我们有数百人参与贡献，我们在做数千次代码评审。”
- **在改进器技能上多下功夫**。在编写改进器技能(即观察者智能体)上多花些功夫,其回报会超出当前这一个智能体循环本身,因为改进器技能在不同用例之间具有很强的复用性。“除了领域特定知识那一部分之外,这是一套相当可复用的机制——代码评审智能体的改进器技能,与任何其他智能体的改进器技能并没有太大区别。”

> • **Write principles, not rules.** "Construct the skill as though you're instructing a smart person, not like you're programming a computer,” Zach says. “Including direction in the skill like ’Look for repeated code’ provides better direction than exhaustive variable naming rules.” 
> • **Explain the why. **Providing the rationale behind the rule lets the agent reason about the problem instead of following rigid instructions, again allowing for better generalization. 
> • **Make feedback effortless to give.** Capture it where people already work, like by commenting directly on a PR or issue. Also, make this happen automatically, with no extra submission step. “Low friction is what keeps signal flowing,” Zach notes. “If you make it too hard you're not going to get the feedback and you're not going to be able to improve the skill."
> • **Keep skills small and use progressive disclosure.** [A good skill](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) file isn't large; it references resource files and scripts rather than dumping everything into context at once. 
> • **Feedback quality > volume, but volume helps.** A small amount of detailed, domain-specific feedback from a senior engineer can be worth more than lots of cursory feedback because binary thumbs up/down doesn't say *why*. “You can get really good signal even from a relatively small sample size if it's very detailed feedback from a person around domain specific knowledge that the agent otherwise would have no way of getting,” Zach continues. “That said, the bigger the corpus of quality signal, the better. At Warp we're using a loop to manage our whole open source repo. We have hundreds of people contributing and we're doing thousands of code reviews.”
> • **Put extra effort into the improver skill**. Putting extra effort into writing the improver skill (the observer agent) pays off beyond the immediate agent loop, because improver skills are very reusable across different use cases.  “Outside of the domain specific knowledge component, this is a fairly reusable mechanism—the improver skill for a code review agent is not that different from the improver skill for any other agent.”

#### **循环的实际应用：Warp 的问题分诊智能体 **

> **The loop in action: Warp’s issue triage agent **

[Warp 的问题分类代理](https://github.com/warpdotdev/warp-agents-demo-github-issue-triage)展示了自我改进的代理技能框架。每当有人提交新的 GitHub issue 时，该模式就会被触发：一个 GitHub Action 会启动一个代理，该代理会分析该 issue 的复杂度和可行性，分配标签，并为修复给出方向建议。这个分类代理运行时依赖一个内部技能文件，其中保存着关于每个标签含义以及在采取行动前如何研究代码库的领域知识。

> [Warp’s issue triage agent](https://github.com/warpdotdev/warp-agents-demo-github-issue-triage) demonstrates the self-improving agent skills framework. The pattern is triggered whenever someone files a new GitHub issue: a GitHub Action fires an agent that analyzes the issue for complexity and feasibility, assigns labels, and suggests a direction for the fix. That triage agent runs off an inner skill file holding the domain knowledge about what each label means and how to research the codebase before acting.

在一个示例 issue 上，第一阶段的内部技能表现不错，但遗漏了一个标签 ready to spec，该标签表示贡献者可以开始针对该 issue 编写产品和技术规格说明。Warp 团队的一位维护者发现了这个疏漏，并直接在该 issue 上留下了反馈，恰好就在工作发生的地方。关键在于，他既说明了自己期望什么，也说明了为什么这样期望：这是可执行的反馈，便于智能体日后吸收。

> On a sample issue, the first-stage inner skill did a solid job but missed one label, ready to spec, which signals that a contributor can start building product and technical specs against the issue. A maintainer on the Warp team caught the gap and left feedback directly on the issue, exactly where the work was happening. Critically, he explained both what he expected and why he expected it: actionable feedback easy for the agent to absorb later. 

外层的改进器技能运行在 [Oz，即 Warp 的智能体编排平台](https://docs.warp.dev/)中，作为一个定时执行的“更新分类”智能体。该智能体向 GitHub 完成身份认证，运行与该技能捆绑的一个 Python 脚本来拉取近期带有反馈的 issue，将它们汇总成一个 JSON 文件，再把该文件读回上下文中。这个捆绑脚本本身就是一项最佳实践；技能可以引用资源文件，而不必在每次运行时都重新编写代码。

> The outer improver skill runs in [Oz, Warp's agent orchestration platform](https://docs.warp.dev/), as a scheduled “update triage” agent. The agent authenticated to GitHub, ran a Python script bundled with the skill to pull recent issues carrying feedback, summarized them into a JSON file, and read that back into context. The bundled script is itself a best practice; skills can reference resource files instead of writing fresh code on every run.

在此基础上，该智能体从维护者的评论中识别出具体的反馈信号，并提出了能够涵盖这些信号的最小改动。它提交了一个 PR，修改内层技能，使其在某个 issue 描述了一个真实问题时应用 "ready to spec" 标签，即便确切的 UI 或 UX 形态尚未确定。

> From there, the agent identified the concrete feedback signals in the maintainer comments and proposed the smallest edit that captured them. It opened a PR editing the inner skill to apply the "ready to spec" label when an issue describes a real problem, even though the exact UI or UX shape is not yet defined. 

由于整个更新就是一个技能文件，它会走正常的代码评审流程。这个 PR 附带了一段描述，说明哪些信号促成了此次更改，以及它改动了什么。人类进行评审、批准并合并，然后分诊技能的下一次运行就会继承这些新知识。最后这一步人工环节闭合了整个循环，并让人始终掌控实际发生的变更。

> Because the whole update is a skill file, it moves through the normal code-review workflow. The PR arrived with a description explaining which signals prompted the change and what it altered. A human reviews, approves, and merges, and the next run of the triage skill inherits the new knowledge. That final human step closes the loop and keeps a person in control of what actually changes.

这正是 Warp 目前在其开源代码库中大规模运行的同一套机制，在那里，编写规范的智能体、评审智能体和分类智能体各自都带有自己的自我改进循环。

> This is the same mechanism Warp now runs at scale across its open-source repo, where spec-writing agents, review agents, and triage agents each carry their own self-improvement loop. 

任何智能体，无论其任务是什么，只要你从一开始就在其中构建这样一个循环——捕获人类反馈信号，将其转化为技能更新——它就会随着时间推移变得更好，并将智能体从一次性的助手扩展为能够在整个组织中产生复利效应的强大系统。

> Any agent, no matter what its task, gets better over time if you build one of these loops into it from the start to capture human feedback signals, turn them into skill updates, and expand agents from one-off helpers into capable systems that compound across your org.

[观看完整的网络研讨会](https://www.anthropic.com/webinars/how-warp-builds-self-improving-agents-on-claude)*，获取现场演示，并深入了解 Warp 如何使用 Claude 构建能够从团队反馈中学习并随时间不断自我改进的智能体。*

> [View the full webinar](https://www.anthropic.com/webinars/how-warp-builds-self-improving-agents-on-claude)* for a live demo and deeper discussion of how Warp uses Claude to build agents that learn from team feedback and improve themselves over time.*

*立即开始使用 *[Claude 平台](https://platform.claude.com/)* 进行构建。*

> *Start building with the *[Claude Platform](https://platform.claude.com/)* today.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Agent Skills | 智能体技能 | 以文件为载体为智能体编码知识和指令的机制，可从原始提示词中剥离并按需查阅。 |
| self-improving loop | 自我改进循环 | 通过持续捕获人类反馈并将其转化为技能更新，使智能体输出随时间不断提升的闭环流程。 |
| inner skill | 内层技能 | 承载某一功能领域具体知识与指令、供智能体执行任务时直接调用的基础技能文件。 |
| improver skill | 改进器技能 | 作为观察者智能体定时运行、比对反馈并提出基础技能修改建议的外层技能。 |
| observer agent | 观察者智能体 | 不按任务而按计划定时执行、负责审视既往输出与反馈的智能体角色。 |
| progressive disclosure | 渐进式披露 | 技能文件保持精简并按需引用资源文件与脚本，而非一次性将全部内容塞入上下文的做法。 |
| AGENTS.md | 智能体上下文文件 | 仓库中用于向编码智能体提供项目约定与背景信息的约定式说明文件。 |
| code review agent | 代码评审智能体 | 在 PR 创建时自动运行、基于技能与上下文生成评审意见的智能体。 |
| issue triage agent | 问题分诊智能体 | 分析新提交 issue 的复杂度与可行性、分配标签并给出修复方向建议的智能体。 |
| GitHub Action | GitHub 工作流动作 | 由仓库事件触发的自动化执行机制，此处用于在新 issue 提交时启动分诊智能体。 |
| PR (pull request) | 拉取请求 | 提交代码或文件变更并交由他人评审、批准与合并的协作流程单元。 |
| Oz | Oz 编排平台 | Warp 的智能体编排平台，用于按计划调度并运行改进器等智能体。 |
| Claude Platform | Claude 平台 | Warp 智能体产品所依托的模型与智能体开发平台。 |
| actionable feedback | 可执行反馈 | 同时说明期望结果及其原因、便于智能体后续吸收并泛化的具体反馈。 |
| agentic development environment | 智能体开发环境 | 将 AI 智能体深度集成到终端与日常开发工作流中的开发环境形态。 |
