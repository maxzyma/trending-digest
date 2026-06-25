---
source: claude-blog
source_url: https://claude.com/blog/building-effective-human-agent-teams
published_at: 2026-06-24
category: Enterprise AI
title_en: Building effective human-agent teams
title_zh: 构建高效的人机团队
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 3
source_image_count: 5
---

# 构建高效的人机团队

_英文标题：Building effective human-agent teams_

> 来源：Claude Blog，2026-06-24
> 原文链接：https://claude.com/blog/building-effective-human-agent-teams
> 分类：Enterprise AI

## 核心要点

- 人机协作正从"单人游戏"转向"多人游戏"：人类制定战略，Claude 执行工作，双方在同一工作空间（如 Slack）中协作。
- 多人智能体（Multiplayer Agents）拥有自己的记忆、技能、独立凭证，并存在于真实工作发生的地方。
- 经验一：公开工作并给智能体充分上下文——对智能体而言"没写下来、不可检索的东西就等于不存在"。
- 经验二：每个人和智能体都获得明确角色与称手工具，共用一份花名册、一套产出物、一个工作空间。
- 经验三：设定北极星（North Star）目标，让智能体能主动建议新工作流。
- 经验四：随时间逐步建立信任，按已验证的可靠程度成比例扩大智能体的自主权。
- 这些原则对人类团队并不新鲜，智能体只是让"不能跳过这些基本功"变得更加重要。

## 正文

我们与 AI 协作的方式正从"单人"体验演进为"多人"体验——人类与智能体（Agent）作为一个团队协同工作，共同实现一致的目标。我们将分享这种全新工作方式的实际案例。

> ⌁
> The way we work with AI is evolving from a single-player to a multiplayer experience, where humans and agents work together as a team to achieve shared goals. We share examples of this new way of working in action.

过去使用人工智能（AI）意味着一个人面对单一的聊天窗口。随着时间推移，AI 在处理复杂、长时间运行的工作上越来越得心应手，比如编程、研究和财务分析。随之而来，我们见到了许多使用 AI 的新方式——从终端、集成开发环境（IDE）到电子表格和演示文稿——但这些工作在很大程度上仍是一种"单人"体验：一个人与一个智能体（agent）协作来完成各自的任务。

> ⌁
> Working with AI used to mean one person interfacing with a single chat window. Over time, AI has become increasingly capable at handling complex, long-running work, like coding, research, and financial analysis. With this, we’ve seen many new ways to use AI—from the terminal and IDE to spreadsheets and decks—but the work has still very much been a “single-player” experience: one human worked with one agent to accomplish individual tasks.

随着 Claude Tag 等工具的发布，这种情况正在改变。现在，人类和智能体可以在同一个工作空间中协同，为团队共享的目标而协作。工作如今更像一场"多人"游戏，由人类团队制定策略，而 Claude 来执行具体工作。

> ⌁
> This is changing with the release of tools like Claude Tag . Now, humans and agents can work together in the same workspace, collaborating in service of goals shared by a team. Work now looks a lot more like a multiplayer game , with teams of humans setting the strategy, and Claude executing the work.

这涉及一些新的工作方式。在 Anthropic，过去几个月我们一直在测试让人机团队取得成功所需的技术。在本文中，我们将解释什么是多人智能体（multiplayer agents），以及我们在构建它们的过程中学到的经验。

> ⌁
> This involves some new ways of working. At Anthropic, we’ve been testing the technology required to make human-agent teams successful for the last several months. In this article, we explain what multiplayer agents are, and the lessons we’ve learned for building with them.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a3c1e1e24f66edde9ee63db_Claude-Tag-v2%402x.png)

### 什么是多人智能体（Multiplayer Agents）？

_What are multiplayer agents?_

“多人协作智能体”是我们这里对那种同时与许多不同人协作的 AI 模型的称呼。与普通智能体类似，它们拥有自己的记忆和技能。但在其他方面它们颇为不同。它们拥有自己的凭据（credentials），并存在于工作真正发生的地方。在 Anthropic，那就是 Slack 这类团队协作工具内部。

> ⌁
> “Multiplayer agents” is how we refer here to AI models that work with many different humans at the same time. Much like regular agents, they have their own memory and skills . But in other respects they're quite different. They have their own credentials and they live in places where work happens. At Anthropic, that's inside team collaboration tools like Slack.

下面是一个人类与智能体组成的团队在 Slack 中共同分析数据集的例子：

> ⌁
> Here’s an example of a human-agent team analyzing a dataset together in Slack:

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a3be9ec0c7dd123eea0fcea_85b9b96b.png)

要让智能体在团队频道中富有成效地参与，它们需要具备特定的能力：

> ⌁
> For agents to productively participate in a team channel, they need specific capabilities:

- 持久记忆，使它们能记住目标并据此调整自己的执行
- 不与人类绑定的凭据，使它们能在安全、可预测的护栏内运作
- 对信息的持续广泛访问，使它们能了解组织如何运转，并采取行动来执行服务于团队目标的任务

> ⌁
> - Persistent memory, so they can remember goals and tune their execution towards them
> - Credentials not tied to humans , so they can operate within safe, predictable guardrails
> - Ongoing broad access to information , so they can learn how the organization works and take action to execute tasks in service of the team’s goals

这些能力构成了智能体在由众多人类组成的团队中富有成效地参与所需的技术基础。然而，要让人类与智能体团队取得成功，仅有这些还不够：团队同样需要特定的协作方式和共同的规范。

> ⌁
> These capabilities amount to the technical foundation required for an agent to participate productively across a team of many humans. However, making human-agent teams successful requires more than this: teams need specific ways of working and shared norms, too.

### 经验 1：公开工作，给智能体提供广泛的上下文

_Lesson 1: Work in public and give agents broad context_

Anthropic 的团队会主动、公开地分享信息。当团队里有智能体（agent）时尤其如此，因为智能体完全依靠团队设为可检索的文本来建立理解：Slack、代码、文档和会议记录。私信、走廊里的对话以及受限文档都无法给智能体提供上下文。对智能体来说，凡是没有写下来、无法访问的，就等于不存在。

> ⌁
> Teams at Anthropic share information proactively and openly. This is especially true when agents are on the team, because agents build their understanding entirely from the text a team makes searchable: Slack, code, docs, and meeting notes. Private messages, hallway conversations, and restricted documents can’t provide agents with context. For an agent, if it’s not written down and accessible, it doesn’t exist.

我们没有逐个文档或逐个 Slack 频道地决定哪些信息可以提供给智能体，而是使用界定清晰的安全边界（security boundary），这些边界适用于整个 Slack 工作区，也适用于会议记录和文档库。在安全边界之内，上下文会流向每一位团队成员——无论是人还是 AI。这不仅扩大了智能体和人能够访问的范围，也减少了关于"什么能分享、能分享给谁"的困惑。无论是人还是智能体，都难以应对逐项分享带来的模糊边界：这个频道该公开还是私有？我能把这份文档分享给那个人吗？这个智能体允许看那条讨论吗？少量清晰的、工作区级别的边界，能消除日常工作中的决策疲劳。

> ⌁
> Instead of deciding what information should be available to agents one doc or Slack channel at a time, we use clearly defined security boundaries that apply to entire Slack workspaces, as well as to meeting transcripts and doc libraries. Within the security boundary, context flows to every teammate—whether human or AI. Not only does this increase what agents and humans get access to, it also reduces confusion about what can be shared and with whom. Humans and agents alike find it difficult to navigate the soft boundaries of per-item sharing: should this channel be public or private? Can I share this doc with that person? Is this agent allowed to see that thread? A small number of clear, workspace-level boundaries removes decision fatigue from day-to-day work.

高度透明是有回报的。例如，能够读取团队会议决策的智能体，不会再建议那些已被降级处理的任务或项目。能访问本团队之外产品规格的智能体，可以推荐那些在其他团队已被验证成功的模式。而且由于智能体读取大量文本的速度远超人类，它们经常能发现人类原本会错过的相关工作。在一个繁忙、快速变化的行业里，我们高度依赖智能体来保持信息同步与协调。

> ⌁
> A high degree of transparency has a reward. For instance, agents that can read decisions from team meetings won't suggest tasks or projects that were deprioritized. Agents with access to product specs beyond their own team can recommend patterns that have succeeded for others. And because agents can read enormous volumes of text far faster than humans do, they routinely surface relevant work that humans would otherwise have missed. We lean on our agents heavily to stay informed and coordinated in a busy, fast-moving industry.

在 Anthropic，公开工作具体表现为：

> ⌁
> At Anthropic, working in public looks like:

- 在公司层面选定少数几条安全边界，并创建与每条安全边界相匹配的工作区和文档分享设置
- 将新的沟通频道在组织内默认设为公开，并确保每次决策都落实到频道、文档和会议记录中
- 撰写制品和会议记录时要让智能体能够找到它们，因为智能体如今已是团队文档的主要消费者之一
- 确保 AI 能够访问完成工作所需的正确工具和信息

> ⌁
> - Choosing a handful of security boundaries at the company and creating workspaces and document sharing settings that match each security boundary
> - Defaulting new communication channels to public within the organization, and ensuring decisions land in channels, docs, and meeting notes every time
> - Writing artifacts and meeting notes so that agents can find them, since agents are now a primary consumer of team documentation
> - Making sure AI has access to the right tools and information needed to get their job done

将信息默认设为内部公开，可能需要文化上的转变。然而，拥有上下文的人机团队与缺乏上下文的团队之间，差距大到无法忽视。

> ⌁
> Defaulting information to be internally public can require cultural shifts. However, the difference between human-agent teams with context and those without is too stark to ignore.

当然，有些交互是敏感的，需要在某个人与 AI 之间保持私密。对于这类情况，你可以通过 Claude Tag 给 @Claude 发送私信，也可以使用现有的 Claude.ai 和 Claude Cowork 应用。这些工具让 Claude 通过你个人的 MCP 连接器访问私密信息，同时确保你的对话以及你与智能体分享的内容都将保持私密。

> ⌁
> Of course, some interactions are sensitive and will need to be private between a single human and AI. For those, with Claude Tag you can send @Claude a direct message, or you can use the existing Claude.ai and Claude Cowork applications. These tools give Claude access to private information via your personal MCP connectors, with the knowledge that your conversation and what you share with the agent will remain private.

### 经验 2：每个人和智能体都获得一个明确的角色，并配备适合该工作的工具

_Lesson 2: Every human and agent get a defined role with the right tools for the job_

人类与智能体团队共享同一份名册、同一套工件以及同一个工作空间。智能体拥有各自的凭证（credentials）、技能（skills）和工具访问权限。不同的智能体也承担不同的角色：例如，一个可能负责某项目的数据分析，另一个则掌握并执行设计标准，第三个则负责研究综合。

> ⌁
> Human-agent teams share one roster, one set of artifacts, and one working space. Agents have their own credentials , skills , and tool access. Different agents also hold different roles: for instance, while one might own the data analysis for a project, another will hold and enforce the design standard, and a third will run research synthesis.

项目启动时，人类与智能体交流，确定该分配哪些角色，以及人类和智能体将如何协作。

> ⌁
> When a project kicks off, humans chat with the agents to figure out which roles to assign, and how the humans and agents will work together.

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a3bf2ac55e5efdefd1d06fb_LAUNCH%20ROOM.png)

一旦人类和智能体的工作职责明确，某个智能体可能会启动其他智能体，以确保特定任务由拥有正确记忆和适当访问权限的智能体来处理。重要的是，它们需要访问完成工作所需的所有工具：负责数据分析的智能体可能需要访问 BigQuery，而执行 QA 的智能体可能需要访问 Playwright MCP。

> ⌁
> Once the jobs for humans and agents are clear, an agent might spin up other agents to make sure that specific tasks are handled by the agents with the right memory and appropriate access. Importantly, they need access to all the tools required to accomplish the job: one that handles data analysis might need access to BigQuery, and one that performs QA might need access to the Playwright MCP.

明确定义的角色和职责为人类与智能体团队的成功奠定了基础。人类通常在与智能体相同的线程中工作，但他们承担只有人类才能承担的角色。这确保了一切协调运作，并将人类判断力应用于最重要的决策。如果没有清晰的角色，人们最终会在一旁运行各自的个人 AI 队伍，重复工作并割裂团队的上下文。指标追踪就是一个常见的例子：一个多人协作的智能体可以一次性完成这项工作，让所有人看到相同的数字。

> ⌁
> Clearly defined roles and responsibilities set human-agent teams up for success. Humans often work in the same threads the agents do, but they hold the roles only humans can hold. This ensures everything works together and human judgment is applied to the most important decisions. Without clear roles, people end up running fleets of personal AIs on the side, duplicating work and fracturing the team's context. Metrics tracking is a common case: a multiplayer agent can do the job once and let everyone see the same numbers.

在 Anthropic，人类与智能体团队拥有清晰定义的角色具体表现为：

> ⌁
> At Anthropic, having clearly defined roles on human-agent teams looks like:

- 一套商定的任务集：团队中的人类及其智能体就谁做什么达成一致
- 人类和智能体在同一个共享线程中工作，因此任何人都可以接续他人未完成的工作
- 人类和智能体都能访问完成各自工作所需的正确工具
- 对智能体角色和职责范围的描述

> ⌁
> - An agreed-upon task set: the team's humans and its agents agree on who does what
> - Humans and agents working in the same shared threads, so anyone can pick up where anyone left off
> - Humans and agents that have access to the right tools to accomplish their respective jobs
> - Descriptions of agents’ roles and scopes

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a3be9ee0c7dd123eea0fd08_e35d445f.png)

Anthropic 的一个工程团队开始创建名册来帮助编纂人类和智能体的角色，因为这让推进他们的工作变得更加容易和具体。他们早期领悟到的一些要点：

> ⌁
> An engineering team at Anthropic started creating rosters to help codify human and agent roles because it made driving their work much easier and more concrete. Some things that clicked for them early on:

- 具体的角色也帮助人类轻松追踪某项任务的责任归属，无论是单个任务还是整个团队的职责集合
- 编写技能文件来定义特定智能体的角色有助于让专业化变得简单，并允许公司内各处的人快速搭建出同类型的其他智能体
- 当项目变得更加复杂时，团队会增加新的智能体来专注于新的领域。例如，他们增加了一个发布经理智能体来处理新的软件发布。

> ⌁
> - Specific roles also help humans easily track where responsibility for a task lies, whether that’s in individual tasks or an entire team’s set of responsibilities
> - Writing skill files to define specific agents’ roles helps to make specialization easy, and allows people across the company to quickly stand up other agents of the same type
> - The team adds new agents to focus on new areas when projects get more complex. For example, they added a release manager agent to deal with new software releases.

这些方法让人类对人类与智能体团队的心智模型能够随着智能体数量的增长而扩展。

> ⌁
> These methods let humans' mental model of a human-agent team scale as the number of agents grows.

### 经验 3：设定北极星，让智能体更主动

_Lesson 3: Set a north star to make agents more proactive_

尽管 Anthropic 的一些智能体只是完成分配的任务，但最重要的智能体会主动提出新项目和新工作方向。这通常发生在一个已经为其智能体提供了丰富背景和明确角色的团队，再加上另一项指引时：北极星。

> ⌁
> Although some agents at Anthropic simply complete assigned tasks, the most important ones proactively suggest new projects and workstreams. This often happens when a team that has already given its agents rich context and clear roles adds another guide: a north star.

北极星是宏大而广泛的目标，帮助团队判断哪些任务和工作方向才是正确的。在 Anthropic，北极星始终由人类设定，并以业务的使命和目标为根基。

> ⌁
> North stars are ambitious, wide-reaching goals that help teams decide which tasks and workstreams are the right ones. At Anthropic, humans always set the north star, grounding it in the mission and goals of the business.

一旦北极星被清晰地以书面形式表述出来，人类就会把它分享给团队中的智能体。然后，重要的是，人类会选择哪些智能体应当主动提出新的工作方向，以帮助实现这一长期目标。（团队中并非每个智能体都具备成功主动提出工作所需的技能和信任。）

> ⌁
> Once a north star is clearly articulated in writing, humans share it with the agents on their team. Then, importantly, humans choose which agents should proactively suggest new workstreams to help achieve this long-term goal. (It’s unlikely that every agent on the team will have the prerequisite skills and trust to proactively suggest work successfully.)

例如，一个以"让产品上手过程更有帮助"为北极星的内部工具团队，看到一个智能体主动推荐修改上手流程中错误信息的文案。这些改动在接下来的一周内可衡量地提升了上手成功率。

> ⌁
> For example, an internal tools team with a north star to “make product onboarding more helpful” saw an agent proactively recommended copy revisions to the onboarding flow error messages. These changes measurably increased onboarding success the following week.

在 Anthropic，设定北极星的过程大致是这样的：

> ⌁
> At Anthropic, setting a north star looks like:

- 让人类讨论、辩论并记录下一个为其人机团队设定的宏大北极星目标——一个植根于公司使命和业务目标的目标
- 将北极星分享给团队中的智能体，并明确指明哪些智能体可以主动推荐新的工作方向
- 在日程表上保留高质量的人类时间，让会议如今聚焦于最重要的工作

> ⌁
> - Having humans discuss, debate, and document an ambitious north star goal for their human-agent team—one that’s rooted in the company’s mission and business goals
> - Sharing the north star with agents on the team and explicitly naming which agents can proactively recommend new workstreams
> - Keeping high-fidelity human time protected on the calendar, with meetings now focused on the most important work

清晰的北极星为智能体提供了一个持续努力的方向，以及主动支持团队工作的有意义机会。

> ⌁
> A clear north star gives agents a consistent direction to work toward and meaningful opportunities to proactively support a team’s work.

### 经验 4：随时间建立信任

_Lesson 4: Build trust over time_

Anthropic 的团队会根据已证明的可靠性，按比例授予智能体（agent）自主权，然后有意识地逐步扩大。工程师已经能成功地派遣团队中的智能体独立处理 500 个缺陷修复，但起步时显然并非如此。

> ⌁
> Teams at Anthropic grant agents autonomy in proportion to demonstrated reliability, then expand it deliberately. Engineers have successfully dispatched agents on their team to handle 500 bug fixes independently, but things certainly didn’t start off that way.

当一位新的人类同事加入团队时，需要时间来评估其能力并建立稳固的协作惯例。通常要经过多个反馈循环，才能把关于如何最好地完成任务的所有隐性信息外化出来。智能体也是如此。用户必须通过给智能体布置许多不同的任务来试验，从而了解智能体能做什么、如何清晰地描述目标、它需要哪些技能文件，以及哪些提示词最能引出期望的行为。随着模型变化和改进，重新测试任务也很重要。提示词可能需要重新措辞，而过去有用的护栏（guardrail）可能会限制更聪明的模型去追求更有创造性的解决方案。

> ⌁
> When a new human colleague joins the team, it takes time to assess their capabilities and develop strong working routines. It usually takes multiple feedback cycles to externalize all the tacit information about how tasks are best completed. The same is true for agents. Users have to experiment with giving agents many different tasks so they can learn what the agent is capable of, how to clearly describe the goal, what skill files it needs, and what prompts work best to elicit a desired behavior. It’s also important to retest tasks as models change and improve. Prompts may need re-wording and guardrails that used to be helpful may constrain a smarter model from pursuing more creative solutions.

值得注意的是，我们发现最优秀的长时运行智能体在人类查看之前，有许多不同的方式来核验自己的工作。代码当然有测试，但大多数其他工作也可以被核验。例如，技术文档可以套用评分标准（rubric）和风格指南。当人类设定标准并确保分配给智能体的所有工作都能被审查时，质量就能保持在高水平，不会偏离最初的意图。另外，与人类一样，让一个智能体负责执行任务、另一个智能体负责检查第一个智能体的工作，往往会有帮助。这通常被称为“执行者-核验者”（Doer-Verifier）智能体框架。

> ⌁
> Notably, we’ve found that the best long-running agents have many different ways to verify their work before a human looks at it. Code has tests, of course, but most other work can be verified as well. For example, technical docs can have rubrics and style guides applied to them. When humans set the bar and ensure all work assigned to an agent can be vetted, quality stays high and doesn’t drift from the original intention. Separately, as with humans, it often helps to give one agent the job of doing the task and another agent the job of checking the first agent’s work. This is often called the “Doer-Verifier” agent harness .

在 Anthropic，随时间与智能体建立信任的过程看起来是这样的：

> ⌁
> At Anthropic, building trust with agents over time looks like:

- 在初期手动审查智能体的工作，以审核质量、提供反馈，并设计任务核验清单
- 告诉智能体把使用一个“核验者”智能体来检查其工作作为任务的一部分
- 将反思纳入循环，要求智能体复盘自己的失误，使工作随时间不断改进
- 跟踪每个智能体在哪些类型的任务上赢得了自主权，并在反复成功后按任务类型扩大其范围

> ⌁
> - Reviewing agent work manually in the beginning to vet quality, provide feedback, and design task verification checklists
> - Telling the agent to use a “verifier” agent to check its work as part of the task
> - Building reflection into the cycle and asking agents to review their own misses so work improves over time
> - Tracking which kinds of tasks each agent has earned autonomy on and expanding scope per task type after repeated successes

Anthropic 的一位工程负责人接手了一个积压大量待办事项的新团队。为了理清头绪，他邀请了几位人类和几个智能体帮他梳理积压事项并对最重要的内容进行优先级排序。团队中的一组智能体通读了积压清单中的所有事项，弄清是否有人正在处理这些事项，并为任何无人认领的事项打上复杂度评分。另一组则从清单中读取、筛选出中低复杂度的事项，并创建代码改动。一开始，人类审查智能体做出的每一个决策，并标记任何需要人类介入的决策。随后，人类教会智能体直接把这些决策呈现给人类，确保涉及艰难取舍的决策始终有人类参与其中。

> ⌁
> One engineering leader at Anthropic took on a new team with a big backlog. To get a handle on it, he invited a few humans and a few agents to help him sort through the backlog and prioritize what was most important. One set of agents on the team read through all of the items in the backlog, figured out if anyone was working on the items, and assigned a complexity score to anything that was unowned. The other set read from the list, filtered to the medium and low complexity items, and created code changes. At the beginning, humans reviewed every decision made by an agent and marked any that required human input. Then the humans taught the agents to surface those decisions to humans directly, ensuring that decisions with hard tradeoffs always had a human in the loop.

![Image 5](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a3be9ee0c7dd123eea0fd03_9eb4409f.png)

每周，这位负责人和他的团队都会要求智能体汇编一份包含“经验教训与失误”的周报，以便智能体记录错误并避免将来重蹈覆辙。随着时间推移，这位负责人得以把越来越复杂的代码改动交给他的智能体，并在引导智能体的日常任务上花费更少的时间。

> ⌁
> Every week, the leader and his team asked the agents to compile a weekly report that included “lessons & missteps” so the agents would keep track of mistakes and avoid making them again in the future. Over time, the leader was able to give more and more complex code changes to his agents and spend less time guiding the agents’ day to day tasks.

而一旦智能体更加独立，这位负责人就训练它们把人类的注意力当作稀缺资源来对待：把问题批量汇总以便一次性回答、重复关键背景以便快速让人类进入状态，并限制每位人类一次看到的事项数量。

> ⌁
> And once the agents were more independent, the leader coached them to treat human attention as the scarce resource it is: to batch questions to be answered in a single pass, repeat key context to get a human up to speed quickly, and limit how many things each human sees at once.

帮助智能体良好地沟通，能确保它们保持有用和高效。有些人在团队中设置了专门的智能体，其唯一职责就是决定如何批量汇总并只向人类团队成员上报最重要的沟通内容。另一些人则围绕智能体每天应完成的工作量设置护栏，使人类能够对工作进行有意义的参与。这类护栏确保人类保持对其重要的技能，也确保需要人类审查的事项数量维持在可持续的水平。

> ⌁
> Helping agents communicate well ensures that they remain helpful and effective. Some people have agents in their team with the sole role of deciding how to batch and elevate only the most important communication for human team members. Others set guardrails around how much work agents should do per day, so that humans are able to meaningfully engage with the work. Such guardrails ensure that humans maintain skills that are important to them, and that the number of items requiring human review stays sustainable.

### 应问的问题

_Questions to ask_

在为你的人类-智能体团队打基础时，可以思考以下问题：

> ⌁
> As you’re laying the foundation for your human-agent teams, consider the following questions:

- 智能体和人类所需的全部信息与访问权限，是否都公开且可被广泛检索？
- 你能否写下团队的成员名册（包括人类和智能体），并说明每个成员各自负责什么？
- 团队中的每一位人类和智能体，是否都能用上完成工作所需的恰当工具？
- 你是否为人类和智能体准备了评分标准（rubric）或测试，用来核验关键的工作成果？
- 你的团队是否有一个清晰的北极星目标（north star），让每个人都能参照？

> ⌁
> - Is all the information and access that agents and humans need both public and broadly searchable?
> - Can you write down your team's roster (humans and agents), and say what each member owns?
> - Does every human and agent on the team have access to the right tools to perform their job?
> - Do you have rubrics or tests for humans and agents to verify key work products?
> - Does your team have a clear north star that everyone can reference?

### 继续前行

_Moving forward_

这些模式没有一个是新鲜事——至少对人类来说不是。明确的北极星目标、清晰的角色分工、扎实的文档、共同的质量标准，以及从错误中学习的空间，都是我们几十年来所熟知的健康团队习惯。智能体（agent）只是让我们更加不能跳过这些做法。

> ⌁
> None of these patterns are new—at least not for humans. A strong north star, clear roles, strong documentation, a shared bar for quality, and room to learn from mistakes are the healthy team habits we’ve known for decades. Agents just make it even more important not to skip them.

那些从智能体身上收获最多的团队，正是最有意识地践行这些基本功的团队。

> ⌁
> The teams getting the most from their agents are the ones who are most intentional about applying these fundamentals.

致谢

> ⌁
> Acknowledgements

本文由 Anthropic 教育团队成员 Kristen Swanson 撰写。她要感谢 Matt Bell、Erik Olesund、Hasnain Lakhani、Shale Craig、Nolan Caudill、Mike Schiraldi、Aleks Todorova 和 Molly Vorwerck 对本文的贡献。

> ⌁
> This article was written by Kristen Swanson, a member of the Education team at Anthropic. She’d like to thank Matt Bell, Erik Olesund, Hasnain Lakhani, Shale Craig, Nolan Caudill, Mike Schiraldi, Aleks Todorova, and Molly Vorwerck for their contributions to this piece.

开始在 Claude Code 中使用智能体团队（agent teams）构建多人协作智能体，或者使用 Claude Tag 来构建。

> ⌁
> Start building multiplayer agents using agent teams in Claude Code or by using Claude Tag .

## 术语对照

| English | 中文 |
|---|---|
| Multiplayer agents | 多人智能体 |
| Agent | 智能体 |
| Single-player / Multiplayer | 单人 / 多人 |
| Memory | 记忆 |
| Skills / Skill Files | 技能 / 技能文件 |
| Credentials | 凭证 |
| Persistent memory | 持久记忆 |
| Security Boundary | 安全边界 |
| North Star | 北极星 |
| Onboarding | 上手 / 产品上手 |
| Backlog | 积压 |
| Rubric | 评分标准 |
| Doer-Verifier | 执行者—验证者 |
| Human in the Loop | 人类参与 |
| Release Manager | 发布经理 |
| Roster | 花名册 |
