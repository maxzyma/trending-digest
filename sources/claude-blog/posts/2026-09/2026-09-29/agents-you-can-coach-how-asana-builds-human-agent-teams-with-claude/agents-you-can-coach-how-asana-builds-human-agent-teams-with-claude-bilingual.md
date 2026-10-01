# 可以指导的智能体：Asana 如何借助 Claude 打造人机协作团队

> Agents you can coach: how Asana builds human-agent teams with Claude

> 来源：Claude Blog / Anthropic，2026-09-29
> 原文链接：https://claude.com/blog/agents-you-can-coach-how-asana-builds-human-agent-teams-with-claude
> 分类：AI 应用 / 人机协作

## 核心要点

- Asana 没有为 AI 另建上下文结构，而是让智能体在既有的 Work Graph 模型中运作，像人类协作者一样拥有角色、接收任务、读写消息并出现在活动动态中。
- Asana 员工先借助 Claude 整理来自 Slack、会议录音、文档等的零散信息，再将可执行事项导入 Asana 的项目和任务结构，供智能体和同事接手。
- 智能体按角色或工作类型构建，配备基于客户研究的预置技能和所需集成，并通过资料页明确其用途、使用者、管理员、指令、技能、集成与权限。
- 智能体受显式访问控制约束，且其实际权限以触发它的那个人的权限为上限，以降低私密信息被外泄的风险。
- 智能体具备可被多个用户复用的共享记忆，但只有管理员和编辑者能将反馈写入永久记忆或删除记忆，其他人的反馈仅作用于当前任务。
- 负责某项标准的团队应担任相应智能体的编辑和管理员，例如传播团队管理写作智能体，团队中只需一两位专家负责配置。
- 智能体会在共享任务中公开发布计划和执行步骤，使请求、异议和产出集中在一处，审阅者可以查看、评论并修改指令。
- 在 Slack 产品问答场景中，智能体把问题转为 Asana 任务，依据已审批指引作答，并在发现产品缺口或重复问题时为产品团队或赋能团队创建任务。
- At-Risk Renewal 智能体每天汇总全球存在风险的续约更新，按积极动态、消极动态和建议跟进分类并按区域拆分，推送给客户相关高管，且可在共享空间中被持续指导改进。
- 在代码生成不再是瓶颈的背景下，Asana 工程团队用 Command 管理从客户反馈到编码智能体的循环，由人决定工单进入迭代周期，系统给出三种完成时间预测，并通过 MCP 服务器向 Claude 开放数据。

## 正文

*这是我们“构建人机协作团队”系列的第三篇文章。*[第一篇](https://claude.com/blog/building-effective-human-agent-teams)*分享了我们在 Anthropic 使用多人协作 AI 的经验。*[第二篇](https://claude.com/blog/turning-conversation-into-knowledge-how-slack-builds-human-agent-teams)*介绍了 Slack 如何将职场对话转化为智能体所需的上下文。本篇则探讨当智能体与团队在同一平台上运作时，会发生哪些变化。*

> *This is the third post in our series on building human-agent teams. The *[first](https://claude.com/blog/building-effective-human-agent-teams)* shared what we’ve learned working with multiplayer AI at Anthropic. The *[second](https://claude.com/blog/turning-conversation-into-knowledge-how-slack-builds-human-agent-teams)* shared how Slack turns workplace conversation into the context agents need. This one looks at what changes when agents operate on the same platform where teams work.*

早在推出 AI 智能体的数年之前，Asana 的团队就一直在不断探索如何将结构和问责机制融入团队的协作方式之中。他们最终构建了 W*ork Graph*® 模型，该模型将每一项任务、项目、目标和对话都映射到一张关系网络上，并明确界定了负责人、贡献者和依赖关系。

> Years before they introduced AI agents, teams at Asana were iterating on ways to encode structure and accountability into how teams work together. They ultimately built the W*ork Graph*® model, which maps out every task, project, goal, and conversation on a web of relationships, with defined owners, contributors, and dependencies. 

在开始构建 AI 智能体时，他们决定不为 AI 另行添加新的上下文结构，而是让智能体在同一模型中运作。智能体将拥有明确的角色、被分配任务、读写消息，并与人类协作者一同出现在活动动态中——同时，对于智能体能够访问和共享的内容，还设有额外的保护措施。

> When they started building AI agents, they decided that rather than adding new context structures for AI, agents would operate within this same model. They would have defined roles, be assigned tasks, read and write messages, and show up in activity feeds alongside human collaborators—with additional safeguards around what agents can access, and share. 

我们与 Asana 首席产品官 Arnab Bose 进行了交流，探讨 Asana 自己的团队如何使用 Claude，以及如何与这些由 Claude 模型驱动、承担复杂任务的智能体协同工作：每个智能体如何获得其角色和访问权限、由谁来训练它、如何让工作对所有人保持可见，以及在 Asana 的人机协作团队中，智能体承担哪些类型的工作。

> We talked with Arnab Bose, Asana’s Chief Product Officer, about how Asana’s own teams use Claude and work alongside these agents, where Claude models power complex tasks: how each agent gets its role and access, who trains it, how work stays visible to everyone, and the types of jobs agents have on human-agent teams at Asana. 

#### 在智能体开始执行之前，先想清楚并梳理好你的工作

> Think through and structure your work before agents act on it

对 Asana 员工而言，Claude 是默认的 AI 工具，并已接入员工日常工作所用的各个平台，包括 Google Drive、Slack，当然还有 Asana。

> For Asana employees, Claude is the default AI tool, connected to the platforms employees use to work, including Google Drive, Slack, and of course, Asana. 

“一个人理清自己的一天，靠的是把各种非结构化数据汇总起来：一个闪现的想法、Slack 里的一段对话、Zoom 里的一份会议录音、一份 Databricks 报告、Google Docs 里的信息，”Arnab 说，“他们先和 Claude 把这些梳理清楚，然后就能把所有内容导入 Asana 以项目和任务构成的结构中。”一旦结构搭建完成，智能体就可以基于它采取行动，并具备我们在本系列第一篇文章[《构建高效的人机协作团队》](https://claude.com/blog/building-effective-human-agent-teams)中描述的三项能力：持久记忆、各自独立的凭证，以及共享上下文。

> "A person makes sense of their day by taking unstructured data, an idea they have, a conversation in Slack, a meeting recording in Zoom, a Databricks report, information from Google Docs,” Arnab says. “They talk it through with Claude, and then they can pump all of that into the structure that Asana provides with projects and tasks." Once the structure is in place, agents can act on it, with the three capabilities we described in the first post of this series, [Building effective human agent teams](https://claude.com/blog/building-effective-human-agent-teams): persistent memory, their own credentials, and shared context.

**如何将其付诸实践：**

> **How to put this into practice:**

- **从你自己的想法开始。**把你一天中那些零散的片段——一个想法、一段 Slack 对话，或分散在各个文档里的笔记——带给 Claude。
- **与 Claude 辩论和讨论。**把它当作思考伙伴：反复探讨这个想法，直到下一步清晰为止。
- **将可执行事项记录到 Work Graph 中。**把可执行的内容移入项目和任务，让智能体和同事都能接手处理。

> • **Start with your own ideas.** Bring the unstructured pieces of your day, an idea, a Slack conversation, or notes spread across docs, to Claude.
> • **Debate and discuss with Claude.** Use it as a thinking partner: talk the idea through until the next steps are clear.
> • **Log the actionable items to the Work Graph.** Move what's actionable into projects and tasks, where agents and colleagues can pick it up.

#### 为每个智能体分配一个角色，并提供其所需的工具和访问权限

> Give every agent a role and the tools and access it needs

Asana 员工可以在任何项目中与 AI 智能体协作，就像与人类同事共事一样。由人来设计自己所在的团队；每位员工都会获得一份推荐智能体列表，可用来助力实现团队目标。

> Asana employees can work with AI agents in any project like they would with a human colleague. Humans design the teams they work on; each employee gets a list of recommended agents they can use to augment their teams’ goals. 

智能体围绕角色或工作类型构建，例如内容撰稿人、洞察分析师、项目经理、工作受理专员、营销活动分析师或营销活动协调员。每个智能体都配备了预置技能，这些技能基于 Asana 对其客户如何开展此类工作的研究，同时还配备了他们所需的集成，例如 Hubspot 或文档云盘。

> Agents are built around roles or types of work, for example, content writer, insights analyst, project manager, work intake specialist, campaign analyst, or campaign coordinator. Each agent comes with pre-built skills based on Asana’s research into how its customers do that work, and with the integrations they would need, such as Hubspot or a document drive. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6abb134d1d061429065e9809_947344a3.png)

每个智能体还有一个资料页，列出其名称和用途、可以使用它的人员、管理员、指令、技能、集成以及权限。Asana 为你提供了相应工具，让访问授权成为有意为之的决定。“Asana 是一个边界清晰的工作空间，”Arnab 说，“你可以选择只授权访问特定的一组项目而不是全部内容，或者特定的一组文档，又或者文档与应用的组合。”

> Each agent also has a profile page that lists its name and purpose, the people who can use it, the administrators, instructions, skills, integrations, and permissions. Asana gives you the tools to make access intentional. “Asana is a contained work surface,” Arnab says. “You could choose to grant access to a specific set of projects versus everything, or a specific set of documents, or a combination of documents and apps.”

与人类用户一样，智能体也受显式访问控制的约束，但多了一层额外保障：Asana 表示，智能体的实际访问权限以触发它的那个人的权限为上限。这样一来，智能体既能广泛访问公开内容，又能将任何人获取到智能体在私密情境中所了解信息的风险降到最低。

> Like human users, agents are subject to explicit access controls, but have an additional safeguard: Asana says an agent’s effective access is bounded by the permissions of the person who triggers it. This allows agents to have broad access to public content, while minimizing the risk of anyone accessing information the agent has learned in a private context.  

**如何将其付诸实践：**

> **How to put this into practice:**

- **先定义角色，再创建 agent。**想一想 agent 能在你的团队中承担哪些类型的工作，然后写下这个 agent 的目标、指令以及它具体负责哪些工作，就像你为新员工规划入职第一个季度那样。
- **界定访问范围。**确定智能体可以读取哪些项目和文档、可以访问哪些应用，以及可以执行哪些操作。
- **分别指定用户和管理员。**许多人都可以使用智能体，但只有一个规模小、成员明确的群体才应管控它能访问什么以及如何行事。

> • **Define the role before you create the agent. **Think about the types of jobs that agents can do on your team, then write down the agent’s purpose, instructions, and which specific jobs it owns, the way you would for a new hire’s first quarter. 
> • **Scope access. **Decide which projects and documents the agent can read, which applications it can access, and which actions it can take.  
> • **Name users and admins separately. **Many people can work with an agent, but only a small, named group should govern what it can access and how it behaves. 

#### 将与智能体协作和训练智能体区分开来

> Separate working with an agent from training it

Asana 将其智能体称为“AI 队友”，这些智能体的一项关键特性是共享记忆：智能体能够保留此前指令中的信息，多个用户可以复用这份记忆，从而更快地完成任务或工作。“你可以像指导和培训团队中的成员一样，去指导和训练 AI 队友，”Arnab 说。

> A key feature of Asana’s agents, which it calls AI teammates, is shared memory, which enables an agent to retain information from previous instructions, allowing multiple users to reuse that memory to complete tasks or jobs faster. “AI teammates can be coached and trained as if they were a person on your team,” Arnab says.

共享记忆的工作方式中有一项基于角色的限制。虽然任何人都可以就某项任务向智能体提供反馈，但只有管理员和编辑者才能将反馈提交到永久记忆中，也只有他们能撤销或删除该记忆中的内容。对于其他人而言，他们提供的反馈仅适用于当前任务。

> There is one role-based restriction in how shared memory works. While anyone can give an agent feedback on a task, only admins and editors can commit feedback to permanent memory, as well as undo, or delete from that memory. For everyone else, the feedback they provide applies only to the current task. 

Arnab 说，这种分工是有意为之。Asana 的传播团队负责把控公司的语气和风格，因此他们会成为一个写作智能体的编辑和管理员。Arnab 可以用它起草内容，但无法修改它的行为。而大多数人根本不需要接触这套机制：“不是团队里的每个人都需要理解这些概念，比如技能、行为和记忆。团队中会有一两个人成为专家，他们把它正确地配置好，此后团队里的其他所有人都能获得同样的好处。”

> The split is intentional, Arnab says. Asana's communications team hold the pen on the company's voice and tone, so they would be the editors and admins of an agent that writes. Arnab can draft with it, but he can't modify its behavior. And most people never need to touch the machinery at all: "Not everybody on the team needs to understand these concepts, like skills and behavior and memory. There are one or two people on the team who become experts, they set it up correctly, and all the other human beings on the team get the same benefits going forward."

**如何将其付诸实践：**

> **How to put this into practice:**

- **确定由谁训练每个智能体，由谁与之协作。**在企业内部找出能够帮助构建团队所用智能体的领域专家。其他人可以对任务提供反馈，但不能改写智能体。
- **让编辑者与专业领域相匹配。**负责智能体所应用标准（如品牌语调或规划惯例）的团队，也负责（或管理）该智能体。 
- **边工作边构建记忆。**反馈可以让智能体随着时间推移不断改进。你可以让智能体记住值得保留的决策，或者删除那些已不再相关或不再正确的决策。

> • **Decide who trains each agent, and who works with it. **Identify subject matter experts inside your business who can help build the agents that the team uses. Everyone else can provide feedback on tasks, but cannot rewrite the agent. 
> • **Match editors to expertise.** The team that owns the standard the agent applies, like brand voice or planning conventions, owns (or administers) the agent. 
> • **Build the memory as you work. **Feedback can improve the agent with time. Ask the agent to remember decisions worth keeping, or delete ones that are no longer relevant or true. 

#### 让智能体的工作对所有人可见

> Keep the agent’s work where everyone can see it

就像[Slack 中的智能体会在频道里公开透明地发帖](https://claude.com/blog/turning-conversation-into-knowledge-how-slack-builds-human-agent-teams)一样，当一项任务被分配给 AI 队友时，所有人都能看到是一个智能体在处理它，以及它具体做了什么。智能体会发布活动记录，包括它的调研计划和所采取的步骤，因此每个有权访问该任务的人都可以查看它做了什么、发表评论，并引导它朝着自己想要的结果推进。

> Similar to how [agents in Slack post transparently in channels](https://claude.com/blog/turning-conversation-into-knowledge-how-slack-builds-human-agent-teams), when a task is assigned to an AI teammate everyone can see that an agent is doing it, and what it does. The agent posts activity, including its research plan and the steps it took, so everyone with access to that task can read what it did, comment, and steer it toward the result they want. 

当 Asana 的传播团队请 Arnab 审阅一份演讲活动的简报文档时，他在该任务上 @ 了智能体，并让它同时参考他此前一次演讲的讲稿思路。他的消息很简短，因为他已经多次使用过这个智能体，而且他提到的材料早已存在于 Work Graph 中。传播团队的一位同事能够看到他的请求和智能体的回复，并且可以同时与智能体来回沟通。

> When Asana’s communications team asked Arnab to review a briefing document for a speaking engagement, he @-mentioned the agent on the task and asked it to also factor in his talk track from an earlier talk. The message was brief because he had used that agent many times and the material he referenced was already in the Work Graph. A colleague on the communications team could see his request and the agent’s response, and go back and forth with the agent at the same time.

“如果你非常善于使用 AI，大概可以通过一对一的 AI 智能体得到质量很高的回复，把那份文档拿出来，再贴回 Slack 或 Asana 里，”Arnab 说，“但到了那一步，其他审阅这份内容的人并不知道提示词是什么，也不知道中间经过了怎样的来回沟通。如果他们不认同你给出的某些指导，就根本无法就此达成一致。”而在共享任务中，请求、反对意见和产出都集中在同一个地方，审阅产出的人也可以修改生成这份产出的指令。

> "You could probably get great quality responses from a one-on-one AI agent if you are highly AI fluent, get that document out, and post it back into Slack or into Asana," Arnab says. "But at that point, the other human beings who are reviewing that content don't know what the prompt was and what the back-and-forth was. If they disagree with some of the guidance you provided, that's impossible for them to get aligned on." On a shared task, the request, the pushback, and the output are in one place, and the people reviewing the output can also revise the instructions that produced it.

**如何付诸实践**

> **How to put this into practice**

- **在团队审阅工作的地方引入智能体。**这样，请求、智能体的执行步骤和结果都集中在一处，审阅者可以修改指令或输出。
- **让智能体的工作清楚地显示为智能体的工作。**这样，人们就会知道这项工作是由 AI 智能体而不是人类同事完成的。
- **让审阅者能够指导智能体的工作。**Asana 的智能体会在共享任务中发布其计划和步骤，以便其他审阅者提供进一步的指示或反馈。

> • **Bring in agents where your team reviews work. **This way, the request, the agent’s steps, and the results are in one place, and reviewers can change the instructions or the output.
> • **Make agent work visibly agent work. **This way, people will know the work is being done by an AI agent rather than a human colleague.
> • **Enable reviewers to coach the agent’s work. **Asana’s agents post their plan and steps in the shared task, so other reviewers can provide further instructions or feedback.

#### Asana 交给智能体的三项工作

> Three jobs Asana has handed to agents

在 Asana，凡是生成文档或执行复杂任务的智能体工作，都由 Claude 驱动。以下是来自公司不同团队的三个例子：

> Claude powers any agentic work that generates documents or runs complex tasks at Asana. Here are three examples from different teams across the company: 

##### **在 Slack 频道中解答产品问题**

> **Answering product questions from a Slack channel**

每当 Asana 推出新功能时，销售人员和客户成功团队的员工都可以在一个共享的 Slack 频道中提问。在有 AI 队友之前，同样的问题会被反复提出，每次都要 @ 相关领域专家。Arnab 表示，可搜索的知识库并不是一个切实可行的解决方案，因为这些答案细节微妙，而且会不断变化。“你多少需要有人对产品的当前状态做出判断和把关，”他说。

> As Asana launches features, sellers and customer success staff can ask questions in a shared Slack channel. Before AI teammates, the same questions were posted repeatedly and subject-matter experts were @-mentioned each time. A searchable knowledge base wasn’t a practical solution, Arnab says, because the answers are nuanced and they change. "You kind of need to have some amount of taste-making around what is the current state of the product," he says.

这些问题仍然会发到 Slack，因为对一线人员来说，那是提问最简单的地方。现在，频道中的 Asana 应用会把每个问题转成一个 Asana 任务，再由一个智能体接手处理。如果已有经过审批的指引，智能体会附上来源链接进行回复。如果没有经过审批的答案，而且这个问题指向产品中的某个缺口，智能体就会在产品团队的需求收集项目中创建一个任务，并将其加入待办列表。如果同一个问题反复出现，智能体也一再发布同一条记录，它就会为赋能团队创建一个任务，让他们更新培训材料和文档。

> Those questions still go to Slack, because that's the simplest place for the field to ask. Now, an Asana app in the channel turns each question into an Asana task, and an agent picks it up. If approved guidance exists, the agent replies with source links. If there is no approved answer and the question points to a gap in the product, the agent creates a task in the product team's intake project and adds it to the backlog. And if the same question keeps coming up and the agent keeps posting the same record, it creates a task for the enablement team to update the training material and documentation. 

这一流程为赋能团队腾出了宝贵的时间，使其能够专注于更具战略性、优先级更高的工作，同时也能为业务的其他领域提供参考。例如，如果围绕某款新产品的某个特定主题出现了大量问题，这就是一个信号，提示赋能团队应通过额外的培训或信息来重点关注该主题。

> This process frees up valuable time for the enablement team to focus on strategic, higher priority work, while also informing other areas of the business. For example, if there are a lot of questions on a particular topic around a new product, that’s a signal for the enablement team to focus on it with extra training or information. 

##### **向高管汇报存在流失风险的续约情况**

> **Briefing executives on at-risk renewals**

Asana 首席客户官 Josh Abdulla 过去每周都要为高管团队制作一份高风险续约简报，依据的是客户成功经理（CSM）提交的更新：他们会标记存在风险的续约，并在情况变化时更新客户账户信息。Asana 在全球拥有数千家客户，更新数量庞大，如果没有专人负责汇总整理，根本无法及时掌握最新情况。这项工作不仅繁琐，还让整个流程变得被动。“Josh 是在各位负责人告诉他时才知道问题，而不是在数据最初显示出问题的时候，”Arnab 说。

> Asana's Chief Customer Officer, Josh Abdulla, used to produce a weekly at-risk renewals briefing for the executive team based on updates from customer success managers (CSMs) who flagged at-risk renewals and updated accounts as conditions changed. Across thousands of customers globally, the volume of updates made it impossible to stay current without a dedicated person synthesizing them, which was tedious work, and it made the process reactive. "Josh knew about problems when leaders told him, not when the data first showed it," Arnab says.

客户体验团队在 Asana 中构建了一个名为 At-Risk Renewal 的智能体 AI 队友。它会读取全球业务组合中每一项存在风险的续约任务，包括每位 CSM 的更新、状态备注和评论，并生成一份结构化的每日摘要，分为三类：积极动态、消极动态和建议跟进事项。它先生成全球视图，再按区域进行拆分，并在每天早上自动将摘要推送给首席客户官、首席营收官以及每一位区域客户成功负责人。由于摘要发布在共享空间中，这些负责人可以提出后续问题，例如某个客户的流失预测背后有哪些领先指标，还可以指导智能体记住某些内容以供下次运行使用，从而让报告每天早上都变得更好。

> The customer experience organization built an agent AI teammate in Asana called At-Risk Renewal. It reads every at-risk renewal task across the global portfolio, including each CSM's updates, status notes, and comments, and generates a structured daily digest organized into three buckets: positive momentum, negative momentum, and recommended follow-ups. It runs a global view first, then cuts by region, and pushes the digest automatically each morning to the Chief Customer Officer, the Chief Revenue Officer, and every regional customer success leader. Because the digest lands in a shared space, those leaders can ask follow-up questions, such as what the leading indicators were behind a particular account's churn forecast, and coach the agent to remember things for the next run, so the report improves each morning.

“他们大概可以让 Claude 为自己生成一份报告，”Arnab 说，“但我们怎样才能做到让报告标准化、拥有一个共享的工作空间，并且每运行一次都会变得更好？”

> "They could probably have Claude generate a report for themselves," Arnab says. "But how do we get to the place where there's standardization of the report, there's a shared workspace, and it keeps getting better with every single run?"

##### **使用 Command 规划工程周期**

> **Planning engineering cycles with Command**

Asana 在自家产品上运行自动化编码循环时，周期时间和发布进度都出现了延误，原因是自动生成的变更让每个周期变得臃肿。这种循环如今在软件公司中已很常见：从各种渠道收集客户反馈，进行综合提炼，再触发编码智能体将其转化为拉取请求（PR）。“代码生成如今已不再是瓶颈，”Arnab 说，“瓶颈在于规划、决策和打磨。”Asana 的工程团队现在运行在 Command by Asana 之上——这是一款用于管理大型工程团队的产品——并借助它来管理这一循环。

> When Asana ran automated coding loops on its own product, its cycle times and releases slipped, because the cycles were getting bloated by automatically generated changes. The loop itself has become common at software companies: gather customer feedback from various channels, synthesize it, and trigger coding agents to turn it into pull requests (PRs). "Code generation is now no longer the bottleneck," Arnab says. "The bottleneck is around planning, decision-making, and refinement." Asana's engineering organization now runs on Command by Asana, a product for managing large engineering teams, and uses it to manage that loop.

在 Command 中，一个团队空间容纳 10 到 12 名负责同一款产品的工程师。智能体会从客户反馈以及团队 Slack 反馈频道中的评论里提取工单，填充到团队的计划外看板上。由人来决定哪些工单从该看板移入迭代周期，而 Command 会以乐观、均衡和保守三种估算来预测该周期的完成时间。

> In Command, a team space holds a group of 10 to 12 engineers who work on one product. Agents populate the team's unplanned board with tickets pulled from customer feedback and from comments in the team's feedback channel in Slack. People decide what moves from that board into the cycle, and Command predicts time to completion for the cycle with optimistic, balanced, and conservative estimates. 

工单既可以分配给人，也可以分配给编码智能体；而且由于所有周期数据都集中在一处，经理可以在聊天中询问某个版本发布为何偏离轨道，以及做出哪些取舍能让它回到正轨。Command 会基于数据作答，说明是什么在驱动这一信号，以及可以取舍哪些变更。所有这些都通过 Asana 的 MCP 服务器对外开放——正是这一连接让 Claude 这样的助手能够读取这些数据——因此，像 Arnab 或与其对口的 CTO 这样的人，无需打开 Command，就能直接询问 Claude 哪些工作进展正常。

> A ticket can be assigned to a person or to a coding agent, and because the cycle data is all in one place, a manager can ask in chat why a release is off track and what tradeoffs would bring it back. Command answers from the data with what's driving the signal and which changes to trade. All of it is exposed through Asana's MCP server, the connection that lets an assistant like Claude read it, so someone like Arnab or his CTO counterpart can ask Claude what's on track without opening Command.

“当团队能够毫不费力地协同工作时，人类才能蓬勃发展；而如今，每个团队都由人类和智能体共同组成，”Arnab 说，“这正是我们所设计的工作方式：一个人类和智能体都能基于其开展工作的共享上下文；为每个智能体赋予独立身份，使其贡献和访问权限都可被审计；以及对智能体所能学到的内容进行持久记录，让团队的知识不断累积，而不是烟消云散。”

> “Humanity thrives when teams can work together effortlessly, and today every team is part human, part agent,” Arnab says. “That’s the kind of work we design for: one shared context that both humans and agents can work from, with a distinct identity for every agent so its contributions and access can be audited, and a durable record of what agents can learn so the team’s knowledge compounds instead of evaporating.”

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Human-agent team | 人机协作团队 | 由人类成员与 AI 智能体共同组成、协同完成工作的团队。 |
| Work Graph | Work Graph（工作图谱） | Asana 将任务、项目、目标和对话映射为关系网络并界定负责人与依赖关系的数据模型。 |
| AI teammate | AI 队友 | Asana 对其可被分配任务、与人类协作的 AI 智能体的称呼。 |
| Persistent memory | 持久记忆 | 智能体跨任务、跨会话保留信息的能力。 |
| Shared memory | 共享记忆 | 智能体保留的、可被多个用户复用的指令与反馈信息。 |
| Shared context | 共享上下文 | 人类与智能体共同可见并据以开展工作的信息背景。 |
| Credentials | 凭证 | 用于标识智能体身份并授权其访问资源的认证信息。 |
| Access control | 访问控制 | 规定主体可以读取哪些内容、执行哪些操作的权限机制。 |
| Skill | 技能 | 预先配置给智能体、用于完成特定类型工作的能力或方法包。 |
| Integration | 集成 | 智能体与外部应用（如 HubSpot、文档云盘）之间的连接。 |
| Intake | 需求收集 | 统一接收和登记新请求或反馈以便后续处理的流程。 |
| Enablement team | 赋能团队 | 负责为销售和客户团队提供培训与资料支持的团队。 |
| Customer Success Manager (CSM) | 客户成功经理 | 负责维护客户关系、推动客户续约与价值实现的岗位。 |
| Pull request (PR) | 拉取请求 | 向代码仓库提交变更并请求审查与合并的机制。 |
| MCP server | MCP 服务器 | 基于模型上下文协议对外提供数据和工具、供 AI 助手调用的服务端。 |
