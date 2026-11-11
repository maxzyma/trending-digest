# 我们如何用 Manus 构建数据智能体，帮助每个团队做出更好的决策

> How we built a data agent with Manus to help every team make better decisions

> 来源：Manus Blog / Manus，2026-11-06
> 原文链接：https://manus.im/blog/how-we-built-a-data-agent
> 分类：数据智能 / 企业数据智能体

## 核心要点

- Manus 的数据团队只有四人，数据请求量大且常卡在“没有现成仪表盘的新数据”和“解释数字为何变化”两个环节，因此决定构建数据智能体。
- 数据智能体需要两样东西：可直接查询明细数据的连接，以及说明指标定义、数据表用途及其相互关联的业务知识库。
- 团队分阶段接入汇总业务指标、营销数据和详细产品数据，一类数据运行稳定后再接入下一类。
- 团队先用智能体自动化数据团队自己的分析工作，再面向业务用户设计回答，每个回答都包含含义、可据以采取的行动和需要复核的内容。
- 团队在数据表中建立治理层并按主题划分访问权限，当用户问题涉及无权访问的表时，系统自动向数据负责人发起审批，获批后智能体自动恢复工作。
- 智能体被部署在 Slack 中，让成员可以在问题出现的地方直接提问、在消息串中协作并分享答案。
- 团队持续更新知识库并审查智能体的实际使用情况，大多数修复归为知识库条目缺失或定义模糊两类。
- 该智能体每周有 40 多人使用，被用于层层拆解用量变化的原因、从非结构化对话数据中提炼洞察，以及接入发布流程自动跟踪新功能表现。
- 团队选择 Manus 是因为它负责模型选择、工具调用和上下文管理，并提供项目、Automations 和图表报告生成等能力，使团队能把时间集中在数据和业务上下文上。
- 团队建议其他团队不必等数据干净再开始、为智能体接入尽可能多的上下文，并让团队中最擅长用 AI 自动化工作的人来负责。

## 正文

*Manus 的四人数据团队打造了一个每周有 40 多人使用的数据 agent。我们与 Ben Zhong 坐下来聊了聊——他在 Slack 上的头衔是“Data Guy”——听他讲述这个 agent 是如何做出来的，以及其他团队可以从中借鉴什么。*

> *Manus's four-person data team built a data agent that more than 40 people use every week. We sat down with Ben Zhong, whose Slack title is "Data Guy," to hear how it came together, and what other teams can take from it.*

很长一段时间里，Manus 的同事如果想弄明白某些数据，就会给数据团队发消息。周二的使用量为什么突然上涨？大家到底在用 Manus 构建什么？这个团队只有四个人，而问题却源源不断地涌来。

> For a long time, if someone at Manus wanted to understand some data, they messaged the data team. Why did usage jump on Tuesday? What are people really building with Manus? There were only four people on the team, and the questions kept coming.

如今，每周有 40 多人通过与一个基于 Manus 构建的数据智能体对话，来获得这些问题的答案。今天，我们来分享一下我们的数据团队是如何借助 Manus 做到这一点的。

> Today, more than 40 people get answers to those questions every week by talking to a data agent built on Manus. Today, we share a bit about how our data team gets it done with Manus.

**概览**

> **At a glance**

- 数据团队共 **4** 人
- 每周有 **40 多**人使用这个数据智能体
- 平均每人提 **2–3** 个问题，重度用户每天会问十几个甚至更多
- **约 1 周**做出第一个可用版本

> • **4** people on the data team
> • **40+** people use the data agent every week
> • **2–3** questions per person on average, and heavy users ask a dozen or more a day
> • **~1 week** to a first working version

#### 为什么重要：每个团队都需要数据，但分析师人手有限

> Why it matters: every team needs data, but analysts are limited

构建数据智能体的原因很简单：人手不够。Manus 几乎每个团队都用数据做决策，但大家往往既没有权限，也没有时间去深入探究自己心中的所有问题。

> The reason for building a data agent was simple: there weren't enough people. Almost every team at Manus makes decisions with data, but people rarely have the access or the time to dig into all the questions they have.

当某个团队有疑问时，他们有两个选择：查看现有的仪表盘，或者给数据团队四名成员中的某一位发一条 Slack 消息。

> When a team had a question, they had two options: check an existing dashboard, or send a Slack message to one of the four people on the data team.

除了问题数量庞大之外，数据请求还常常卡在两个环节：

> Besides the sheer volume of questions, data requests often got stuck in two places:

- **新数据。**有人需要一个此前从未有人提取过的数字，所以没有现成的仪表盘可用。
- **“为什么”。**仪表盘能显示某个数字发生了变化，但要找出原因，就得深挖到远超仪表盘所呈现的层面。

> • **New data.** Someone needed a number nobody had pulled before, so there was no dashboard for it.
> • **The "why."** A dashboard showed that a number moved, but finding the cause meant digging well past it.

数据团队能处理的请求有限，所以很多好问题根本没有被提出来。

> The data team could only answer so many requests, so a lot of good questions never got asked.

#### 如何构建数据智能体

> How to build a data agent

数据智能体需要两样东西：与你的数据的连接，以及理解这些数据所需的业务上下文。

> A data agent needs two things: a connection to your data, and the business context to make sense of it.

##### 数据连接

> Data connection

数据团队为智能体提供了直接查询我们数据的工具，而不仅仅是查询仪表盘。有了对明细数据的访问权限，智能体就能回答任何仪表盘都未涵盖的问题。团队分阶段接入数据，例如汇总的业务指标、营销数据和详细的产品数据。一旦某一类数据接入良好且运行稳定，他们就会接入下一组数据。

> The data team gave the agent tools to query our data directly, not just the dashboards. With access to the detailed data, the agent can answer questions that no dashboard covers. The team added data in stages, such as summarized business metrics, marketing data, and detailed product data. Once one category of data is well connected and stable, they will connect the next group.

##### 业务背景

> Business context

光有数据还不够。AI 智能体还需要一张业务地图，这样当问题出现时，它才知道该去哪里找答案。数据团队创建了一个详尽的知识库，向智能体说明每个指标是如何定义的、每张表能帮你解决什么问题，以及这些表和指标之间是如何关联的。

> Data alone isn't enough. The AI agent also needs a map of the business, so that when a question comes in, it knows where to go. The data team created a detailed knowledge base that shows the agent how each metric is defined, what each table helps you solve, and how the tables and metrics relate to each other.

有了这张地图，智能体就能像分析师那样逐步解答问题。它会选对数据表，采用正确的定义，并顺着关联从一个指标追溯到下一个指标。即便是没有仪表盘的指标，这种方式同样行得通。

> With that map, the agent can work through a question the way an analyst would. It picks the right table, uses the right definition, and follows the links from one metric to the next. That works even for metrics that have no dashboard.

#### 构建数据智能体的五个步骤

> The five steps to building a data agent

##### 1. 先把自己的工作自动化

> 1. Automate your own work first

数据团队起初并不是为公司打造一款工具，而是先让智能体把他们自己的工作自动化。*“你其实是在打造一个自己的副本，”*Ben 说。

> The data team didn't start by building a tool for the company. They started by getting the agent to automate their own work. *"You're really building a copy of yourself,"* says Ben.

目标是让数据团队不再手写查询，而是通过与智能体对话来完成大部分分析工作。

> The goal is for the data team to stop writing queries by hand and do most of its analysis by talking to the agent.

##### 2. 为业务用户而设计

> 2. Design it for business users

事实证明，让这个智能体对其他所有人都有用，与其说是技术问题，不如说是设计问题。这两类人想从答案中得到的东西并不相同。Ben 的数据团队想知道一个数字是怎么算出来的。业务团队想知道这个数字意味着什么。

> Making the agent useful for everyone else turned out to be a design question more than a technical one. The two groups want different things from an answer. Ben's data team wants to know how a number was calculated. Business teams want to know what the number means.

因此，团队从业务视角出发设计了这个智能体。对业务用户而言，每个回答都涵盖三件事：

> So the team designed the agent from the business perspective. For business users, every answer covers three things:

- **这意味着什么：**数据表明这一变化背后的原因。
- **应据此采取的行动：**哪些发现足够可靠、可以据以采取行动，并附上建议的下一步。
- **需要复核的内容：**哪些发现仍然不够可靠、不足以采信，以便对方知道要去向数据团队核实。

> • **What it means:** What the data suggests is behind the change.
> • **What to act on:** Which findings are solid enough to drive action, with a suggested next step.
> • **What to double-check:** Which findings are still too weak to trust, so the person knows to check with the data team.

##### 3. 建立治理与信任机制

> 3. Set up governance and trust

最难的问题并不在于把智能体搭建起来这一技术环节，而在于制定合适的公司政策和防护措施。

> The hardest problems weren't the technical piece of getting the agent set up. They were about setting the right company policy and guardrails.

###### 按主题划分访问权限

> Split access by topic

出于用户隐私以及公司治理方面的原因，Ben 的团队无法向所有人开放每一张数据表的访问权限。他们希望给每个人足够的权限，以便解答各自的问题。他们的做法是在数据表中建立一个治理层，并让智能体了解这些访问规则。按主题划分访问权限，既能保护我们的用户，也能让我们保持合规。

> Because of user privacy as well as company governance reasons, Ben's team can't grant access to everyone for every data table. They wanted to give everyone enough access to answer the questions they have. What they did was to create a governance layer in the data tables and let the agent know about the access rules. Splitting access by topic protects our users and keeps us compliant.

###### 在需要时请求访问权限

> Ask for access when it's needed

通常情况下，如果你看不到某个仪表盘，就得提交工单然后等待。有了数据智能体，Ben 的团队把这一流程自动化了。当用户提出的问题涉及一张他们无权访问的数据表时，系统会在我们的内部审批软件中触发一条审批请求，并由对应的数据负责人批准。之后，数据智能体会自动恢复工作，给出用户想要的答案。

> Normally, if you can't see a dashboard, you file a ticket and wait. With the data agent, Ben's team automated the process. When a user asks questions using a data table they don't have access to, it triggers an approval request in our internal approval software and gets approved by the right data owner. After that, the data agent resumes working automatically, giving the user the answer they want.

##### 4. 让人们用起来

> 4. Get people to use it

Ben 的团队让这个工具达到合规要求并准备就绪之后，他们希望确保我们的团队尽可能多地使用它。于是，团队把这个智能体放到了问题本来就会出现的地方。Ben 的团队在 Slack 中上线了 Data Agent，团队成员可以在那里直接提问、在消息串中协作，并轻松地在频道中分享答案。

> Once Ben's team got the tool to be compliant and ready, they wanted to make sure our team uses it as much as possible. So the team put the agent into the places where questions already come up. Ben's team launched Data Agent in Slack where team members can ask questions directly, collaborate on a thread, and share answers easily in channels.

##### 5. 持续打磨和改进

> 5. Keep refining and improving

随着业务不断变化，数据团队会持续更新知识库，纳入新的数据表和定义，以反映我们作为一家企业所关注的内容。最棒的是——Data Agent 的用户完全不需要了解这些，因为知识库会在 Manus 项目中自动更新。

> As the business keeps changing, the data team constantly updates the knowledge base about new data tables and definitions that reflect what we care about as a business. The best part is - users of Data Agent don't need to know about any of them because the knowledge base is automatically updated in the Manus project.

Ben 的团队还会审查我们内部对数据智能体的使用情况，看它是否采用了正确的方法来回答问题，并给出了正确的洞察。大多数修复可归为两类：知识库条目缺失，或定义模糊。Ben 说，虽然这个流程并不是什么高深的学问，但让它持续运转起来，对保证智能体的质量很重要。

> Ben's team also reviews our internal usage of the data agent to see if the data agent is answering the questions using the right approach and providing the right insight. Most fixes fall into two types, a missing knowledge base entry, or a fuzzy definition. Ben said while this process is not rocket science, it’s important to keep it running to ensure the quality of the agent.

#### 让数据智能体上线

> Getting the data agent live

我们的数据智能体已经上线数月，我们看到团队以许多很酷的方式使用这款出色的产品。以下是一些例子。

> Our data agent has been live for months now, and we have seen many cool ways that the team is using this awesome product. Here are some examples.

##### 层层深挖，直到找出原因

> Drill down until it finds the cause

这些细分数据中，有很多根本没有对应的仪表盘，但有了 Manus Data Agent，做深入分析就容易多了。

> Many of those detailed numbers have no dashboard at all, but with the Manus Data Agent, it's much easier to do deep dive analyses.

***示例：我们的用量为什么激增？***

> ***Example: Why did our usage jump?***

*针对这个问题，智能体会按地区和渠道拆分使用量。它会检查人们是通过什么方式访问 Manus 的：是通过网页、移动端或桌面应用，还是通过 API。如果增长来自广告流量，它会检查是否由某条具体的广告引起，或者我们的广告追踪是否发生了某些变化。*

> *For this question, the agent splits usage by region and by channel. It checks how people reach Manus, whether through the web, the mobile or desktop app or the API. If the jump came from ad traffic, it checks whether a specific ad caused it, or whether there's some change with our ad tracking.*

![How the data agent breaks down a usage spike by region, channel, and ad traffic](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/ebb8cec6831b899f24c5265a3ca5f33c08e0de10127b062cdaaf6bf6b7734cdd.webp)

##### 将大量非结构化数据转化为洞察

> Turns large amounts of unstructured data into insight

有些问题是任何仪表盘都回答不了的，因为答案埋藏在海量的用户数据之中。智能体能实时地将这些数据转化为洞察。

> Some questions can't be answered by any dashboard, because the answer is buried in a large amount of user data. The agent turns that into insight in real time.

***示例：我们在中东的用户是谁？***

> ***Example: Who are our users in the Middle East?***

*我们在沙特阿拉伯和阿联酋有很多用户，我们想知道他们是当地居民，还是因工作迁居当地的外籍人士。本地人往往将 Manus 用于日常生活和社交用途，而因工作身在当地的人则往往用它来经营业务。智能体查看了人们在对话中使用的语言：标准阿拉伯语、当地阿拉伯语方言还是英语，并为我们带来了一些非常有意思的洞察。*

> *We have many users in Saudi Arabia and the UAE, and we wanted to know whether they were local residents or expats who had moved there for work. Locals tend to use Manus for everyday life and social uses, while people there for work tend to use it to run a business. The agent looked at which languages people used in their conversations: standard Arabic, local Arabic or English and got us some really interesting insight.*

![The data agent summarizing use cases from user sessions](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/72b27c8b0d86d64a0fd06f49da3f6e8e78355eb1ed92ead4251e5e3ed102e1f9.webp)

##### 随着产品演进构建新的埋点追踪

> Builds new tracking as the product evolves

我们的产品每周都在变化，每个新功能都会带来现有表格或仪表盘尚未覆盖的数据。我们没有等人来搭建数据追踪，而是把数据智能体接入了我们的发布流程。

> Our product changes every week, and each new feature brings numbers that no existing table or dashboard covers yet. Instead of waiting for someone to set up tracking, the data agent is connected to our release process.

***示例：新功能表现如何？***

> ***Example: How is the new feature doing?***

*当工程团队发布一项功能时，智能体会自动开始跟踪它。几天后，产品经理就能看到这项功能的表现如何。这个闭环过去需要有人来协调，现在它会自然而然地发生。*

> *When engineering ships a feature, the agent automatically starts tracking it. A few days later, the product manager sees how the feature is doing. That loop used to need someone to coordinate it. Now it just happens.*

![The data agent reporting on feature usage in Slack](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/7e618126039184cb8addf290494fbe5566287f6e22d38a7baf188987e9ecfc82.webp)

#### 为什么用 Manus 构建数据智能体

> Why use Manus for a data agent

Ben 的团队选择使用 Manus，是因为它开箱即用地管理智能体，这样一个四人团队就可以把时间花在数据和业务上下文上。

> Ben's team chose to use Manus because it manages the agent out of the box, so a four-person team could spend its time on the data and the business context.

##### 你无需维护自己的智能体基础设施

> You don't need to maintain your own agent infrastructure

在 Manus 上，无需照看服务器，也无需维护智能体代码。Manus 会自动为你的任务挑选最合适的模型、调用工具并管理上下文。借助 Manus API，Ben 的团队没写一行代码就把数据智能体部署到了 Slack 上。“我想把时间花在确保知识库准确无误上，并根据真实的问答每周对它进行改进。所以我没有在构建智能体本身上花任何时间。”Ben 说。

> On Manus, there's no server to look after and no agent code to keep up with. Manus automatically picks the best models for your task, uses tools and manages context. With the Manus API, Ben’s team was able to deploy the data agent on Slack without a line of code. "I want to spend my time keeping the knowledge base right, and improving it every week based on real questions and answers. So I spent no time building the agent itself," says Ben.

##### 项目将知识库集中存放在一处

> A project keeps the knowledge base in one place

Manus 项目将智能体的指令、技能和知识集中存放在一个共享的地方。Ben 只需更新一次，所有人就能立即获得最新版本。当团队接入新数据时，这些数据会以同样的方式呈现给每个人。

> A Manus project holds the agent's instructions, skills and knowledge in one shared place. Ben updates them once, and everyone gets the latest version right away. When the team connects new data, it shows up for everyone the same way.

![The data agent project in Manus, with shared instructions, skills, and knowledge](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/1c97677bd7e242cde881b5a509ecd6bb855a9d81b7e7698d2094ab323d0d5f25.webp)

##### 自动化流程负责处理审批

> Automations handle the approvals

数据请求通常就卡在获取访问权限这一步。在 Manus Data Agent 上，Ben 的团队利用我们新推出的 Automations 功能，自动向相关数据所有者提交审批申请。一旦获得批准，智能体就会重新接手任务并将其完成。

> Getting access is usually where a data request stalls. On Manus Data Agent, Ben's team leveraged our new Automations feature to submit an approval to the relevant data owner automatically. Once it's approved, the agent picks the task back up and finishes it.

##### 答案可以变成图表和仪表盘

> Answers can become charts and dashboards

Manus 还可以在同一个会话中生成图表、报告和网页，让结果一目了然。在 Manus，人们经常把 Data Agent 的报告分享给团队，其他智能体也会读取这些报告，接手下一项工作。

> Manus can also build charts, reports and web pages in the same session, making it easy to understand. At Manus, people often share Data Agent's reports with their teams, and other agents read those reports to pick up the next piece of work.

#### 来自 Manus 数据团队的一些建议

> Some advice from the Manus Data Team

##### 不要等数据干净了才开始

> Don't wait for clean data to start

虽然我们的数据表里有一套相对清晰的定义，这确实有所帮助，但 Ben 表示，其他团队不应把这当作必要条件：“现在的智能体能力很强。你的配置是什么样子、有没有一份定义清单，都不重要。你可以边做边理清。”随着时间推移，智能体会在它的指令和项目中逐步建立起自己的一套工作体系。在此基础上，你再不断改进它、整理它。

> While it helped that we had a relatively clear set of definitions in our data table, Ben said that other teams shouldn't treat that as a requirement: "Agents are very capable now. It doesn't matter what your setup looks like, or whether you have a list of definitions. You can sort it out as you go." Over time, the agent builds up its own working system in its instructions and project. From there, you keep improving it and tidying it up.

##### 为智能体提供尽可能多的上下文

> Give the agent as much context as possible

智能体能触及的范围越广，它就越强大。如果你有许多不同的数据库，那也没关系。把它们连接起来，让智能体接手那些你平时需要手动完成的工作。用 Ben 的话说，最重要的一步是尽可能多地接入上下文，并开始把你的手动查询工作自动化。

> The more an agent can reach, the stronger it gets. If you have lots of different databases, that's fine. Connect them, and let the agent take over the work you'd normally do by hand. In Ben's words, the most important step is to connect with as much context as you can and start automating your manual querying work.

##### 让你们最 AI 原生的人来负责

> Put your most AI-native person in charge

让智能体把真实工作自动化是一项技能。如果你的团队里已经有人擅长用 AI 自动化工作，就把这个项目交给他们。

> Getting an agent to automate real work is a skill. If someone on your team already excels at automating work with AI, give them this project.

*如果你的团队也想搭建类似的系统，欢迎联系我们。我们会向你详细介绍我们的搭建过程。*

> *If your team wants to build something similar, reach out. We'll walk you through how we set it up.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Data Agent | 数据智能体 | 能够连接企业数据并以对话方式回答数据分析问题的 AI 智能体。 |
| AI Agent | AI 智能体 | 能自主调用工具、分步完成任务的人工智能系统。 |
| Dashboard | 仪表盘 | 以图表形式集中展示预定义业务指标的可视化页面。 |
| Knowledge Base | 知识库 | 向智能体说明指标定义、数据表用途及其关联关系的结构化文档集合。 |
| Business Context | 业务上下文 | 理解数据含义所需的业务背景信息，如指标口径和表间关系。 |
| Metric | 指标 | 用于衡量业务表现的量化数值及其计算口径。 |
| Governance Layer | 治理层 | 建立在数据表之上、用于定义和执行访问规则的管控机制。 |
| Guardrails | 防护措施 | 约束智能体行为和数据访问范围以保证安全合规的规则与机制。 |
| Access Control | 访问权限控制 | 按主题或角色限定用户可查询哪些数据的机制。 |
| Unstructured Data | 非结构化数据 | 没有固定表结构的数据，如用户对话文本。 |
| Tracking | 埋点追踪 | 为产品功能采集使用数据以便后续分析其表现的机制。 |
| Manus Projects | Manus 项目 | Manus 中集中存放智能体指令、技能和知识的共享空间。 |
| Automations | 自动化流程 | Manus 的一项功能，可自动触发审批等流程并在完成后让智能体继续任务。 |
| Manus API | Manus API | 用于将 Manus 智能体接入 Slack 等外部系统的编程接口。 |
| AI-native | AI 原生 | 指习惯并擅长以 AI 为核心方式完成和自动化工作的人或团队。 |
