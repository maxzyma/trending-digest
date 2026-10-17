# Anthropic 日本 BDR 如何借助一组 Claude 智能体安排每天的工作

> How an Anthropic Japan BDR runs his day with a fleet of Claude agents

> 来源：Claude Blog / Anthropic，2026-10-16
> 原文链接：https://claude.com/resources/articles/how-an-anthropic-japan-business-development-representative-runs-his-day
> 分类：AI 智能体 / 销售工作流自动化

## 核心要点

- 这名业务拓展代表过去每天要花数小时手动分配和评估线索、用日语或英语写邮件并更新 CRM，如今大部分工作由智能体在一天开始前准备好，本人只需审阅。
- 智能体集群 Nakama 按单一职责设计，Furiwake 分配线索，Sabaki 评估并处理分给自己的线索，Henji 每小时起草邮件回复，Shoudan 更新 Salesforce 商机，Nokori 在日终整理会议摘要和跟进事项。
- 第六个智能体作为协调者，约每 15 分钟查看 Slack 频道，按本人用平实语言提出的请求更新其他智能体的指令和共享知识库，且只有本人可以发起此类修改。
- 整个集群最初在 Claude 中用技能、定时任务和本地共享文件夹搭建原型，迁移后分别对应系统提示词、部署上的计划任务和记忆存储，指令每次修改都会保存为带编号的版本。
- Managed Agents 让智能体无论笔记本是否开机都能按计划在后台运行，可在 Console 中查看每次运行的每一步，且试验中的修改不会影响已部署版本的计划运行。
- 所有智能体读写同一个记忆存储，把草稿与实际发出邮件的差异记录为笔记，因此在一个智能体中修正一次措辞，其他智能体也不会再犯同样的错误。
- 凭据存放在托管保管库中，每个智能体部署只使用所需的保管库，智能体看不到凭据本身，访问权限可一步撤销。
- 需要后续跟进的事项会交给作为 Slack 工作区成员的 Claude Tag，它会核对规则、列出方案、起草内容，在需要时标记本人，并为等待回复的事项设置提醒。
- 根据按手动耗时折算的工作日志，这组智能体每周节省约 60 小时，腾出的时间用于客户交流、外联策略、跨职能项目和帮助队友搭建智能体。
- 为控制成本和提高可靠性，规则明确的智能体运行在 Sonnet 上，需要更多判断力的运行在 Opus 上，高频运行的 Henji 采用顾问策略向 Opus 求助，投入程度也与模型分开设置。
- 文章总结的经验是不必每次写详细提示词、知识库比提示词更重要，以及应尽早把可放心交出的工作交给智能体。

## 正文

作为 Anthropic 日本团队的业务拓展代表，我的工作是向日本企业展示 Claude 如何简化并自动化他们的工作流程，但直到今年早些时候，我自己的大部分工作流程仍是手动的。我每天早上要花几个小时对潜在客户线索进行分配和资质评估，然后用日语或英语撰写邮件。剩下的时间里，我还要更新我们的 CRM，而且常常滞后一天甚至更久。如今，我的智能体会在我一天的工作开始前把其中大部分准备好，我只需审阅即可。

> As a business development representative on Anthropic's Japan team, my job is to show Japanese companies how Claude can simplify and automate their workflows, but until earlier this year, most of mine were still manual. I was spending a couple of hours each morning routing and qualifying leads, then writing emails in Japanese or English. In the time I had left, I was updating our CRM, often a day or more behind. Now my agents prepare most of that before my day starts, and I review it.

我搭建的第一个由 Claude 运行的工作流相当简陋，但确实能用。我每次交给 Claude 一部分工作，纠正它做错的地方，并把这些纠正保存下来。随着时间推移，它逐渐发展成几个智能体，各自负责一项不同的日常事务。

> The first Claude-run workflow I built was pretty scrappy, but it did the job. I'd hand Claude one piece of my work at a time, correct what it got wrong, and save those corrections. Over time, that grew into a handful of agents, each covering a different routine.

消息很快传开了，队友们开始向我索要提示词和技能，好搭建他们自己的版本。可我能发给他们的，只有一个包含我的技能和知识库中几个 Markdown 文件的 zip 压缩包。他们得先把这些上传到 Claude，再回答一轮设置问题，才能让一切跑起来。我自己的配置也越来越难以管理。每个智能体都由一个技能、一个定时任务和一个共享文件夹组成，而我修改它们的方式，是在当时开着的任意一个聊天里让 Claude 去改，结果同一个技能被许多不同的对话分别编辑。

> Word got around quickly, and teammates started asking for my prompts and skills so they could build their own. All I could send them was a zip file with my skills and a few Markdown files from the knowledge base, which they had to upload to Claude and then answer a round of setup questions before anything worked. My own setup was getting harder to keep track of, too. Each agent was a skill, a scheduled task and a shared folder, and I changed them by asking Claude in whatever chat I had open, so the same skill was being edited from lots of different conversations.

我希望每个智能体只需在一个地方定义一次，并且能够看到自己对它做过的每一处改动。于是我决定试试 [Claude Managed Agents（在新标签页中打开）](https://platform.claude.com/docs/en/managed-agents/overview)（beta），这是我们在 Claude Platform 上提供的托管式智能体基础设施。

> I wanted to define each agent once, in one place, and be able to see every change I'd made to it. So I decided to try [Claude Managed Agents (opens in new tab)](https://platform.claude.com/docs/en/managed-agents/overview) (beta), our managed agent infrastructure on the Claude Platform.

一开始我有些犹豫，不太敢尝试。文档里讲的是调度、工具和凭据保管库，而我只是一名销售代表，所以我以为 Managed Agents 是给那些能够搭建并维护相关基础设施的开发者用的。但我还是试了，因为我的智能体早就已经有了，只需要把它们迁移过去就行。

> I was hesitant to try it at first. The docs talk about schedules, tools, and credential vaults, and I'm a sales rep, so I assumed Managed Agents was for developers who can build and maintain the necessary infrastructure. I tried it anyway because my agents already existed, and I only had to move them over.

事实证明，我并不需要成为开发者。我用通俗的语言描述了每个智能体的工作，Claude 写了几个简短的设置脚本，我在笔记本电脑的终端里运行了它们。（如果你是从零开始，Console 中还提供了一个附带现成智能体模板的[快速入门](https://platform.claude.com/workspaces/default/agent-quickstart)。）从那以后，我再也不需要维护任何基础设施。

> It turned out I didn't need to be a developer. I described each agent's job in plain language, Claude wrote a few short setup scripts, and I ran them from the terminal on my laptop. (If you're starting from scratch, the Console also has a [quickstart](https://platform.claude.com/workspaces/default/agent-quickstart) with ready-made agent templates.) Since then, there has been no infrastructure for me to look after.

在这篇文章中，我将介绍我是如何设计这支智能体集群并制作原型的、为什么我把它迁移到了 Managed Agents、Claude Tag 如何接手常规流程之外的一切事务、这一切如何改变了我的一周，以及对于想要构建自己的智能体来自动化手动、重复性工作流程的销售人员，我会给出哪些建议。

> In this post, I'll walk through how I designed and prototyped the fleet, why I moved it to Managed Agents, how Claude Tag picks up anything that falls outside the routine, how it all changed my week, and what I'd tell sellers who want to build their own agents to automate manual, repetitive workflows.

#### 设计我的智能体集群

> Designing my fleet of agents

我把自己的工作流拆分给多个智能体，并为每个智能体分配一项明确的职责。单一职责让每个智能体都易于理解、易于追踪，尤其是在出现问题时。我还给每个智能体起了一个日文名字，因为它们大多用日语工作。它们合起来被称为 *Nakama*，意为“团队”，或者更直白地说，是与你并肩工作的伙伴：

> I divided up my workflow across several agents and gave every agent one clear job. A single responsibility keeps each one easy to reason about and easy to track, especially when something is off. I also gave every agent a Japanese name, because they mostly work in Japanese. Together they're called the *Nakama*, "the crew," or more literally, the companions you work with:

- ***Furiwake***（“分拣”）最先启动：它读取每日的入站队列，将每条线索分配给团队中合适的销售代表，同时兼顾线索数量与各条线索的优先级，并核对当天谁在岗，确保在我们任何人开始一天的工作之前，每条线索都已有负责人。每次运行结束时，它会向一个专用 Slack 频道发布报告（列出每条进入的线索和每条已分配的线索），方便我跟踪交接情况。
- ***Sabaki* **（意为“处理”）负责分拣分配给我的销售线索：它会对每条线索进行资格评估，按预设标准进行分类，针对该类别执行既定的下一步操作（起草回复引导对方使用自助服务，或撰写定制化的首封邮件），在 Salesforce 中更新线索记录，并起草首次触达邮件。草稿内容来自 *Nakama* 的共享知识库，这是一个所有智能体都会读写的[记忆存储（在新标签页中打开）](https://claude.com/blog/claude-managed-agents-memory)（下文将详细介绍）。
- ***Henji* **（意为“回复”）每小时扫描一次我的收件箱，找出需要回复的客户邮件，并根据邮件往来的语言用日语或英语准备一份回复草稿，所依据的知识库与 *Sabaki* 相同。我可以审阅、编辑并发送这份草稿。
- ***Shoudan***（意为“商机”）会读取近期的客户互动记录，并将更新推送到 Salesforce，从而无需手动录入数据即可让商机记录保持最新。
- ***Nokori* **（“剩下的事”）在一天结束时运行：它会扫描我的日历，阅读所附的会议记录，为每场会议撰写摘要，并起草后续跟进事项，同样基于同一个知识库。

> • ***Furiwake*** ("sorting") kicks off first: it reads the daily inbound queue and routes each lead to the right rep on the team, balancing the number of leads and the priority of each one and checking who's in that day, so every lead has an owner before any of us start our day. At the end of each run it posts a report to a dedicated Slack channel (every lead in, every lead assigned) so I can track the handoff.
> • ***Sabaki* **("handling") triages the leads that are assigned to me: it qualifies each lead, categorizes it against pre-set criteria, takes the defined next step for that category (draft a reply pointing them to to self-serve, craft a customized first email), updates the lead record in Salesforce, and drafts the first-touch email. It sources the draft's contents from the *Nakama*'s shared knowledge base, a [memory store (opens in new tab)](https://claude.com/blog/claude-managed-agents-memory) every agent reads and writes (more on this below).
> • ***Henji* **("reply") scans my inbox hourly for customer emails that need a response and prepares a draft reply in Japanese or English, depending on the thread, drawing on the same knowledge base as *Sabaki*. I can review, edit, and send the draft.
> • ***Shoudan*** ("opportunity") reads recent customer interactions and pushes updates into Salesforce, so opportunity records stay current without manual data entry.
> • ***Nokori* **("what remains") runs at the end of the day: it scans my calendar, reads the attached meeting transcripts, summarizes each meeting, and drafts the follow-ups, again from the same knowledge base.

每个智能体都按[计划](https://claude.com/blog/whats-new-in-claude-managed-agents)运行。第六个智能体是 Nakama 的协调者，担任整个智能体团队的运营经理。它会在各次运行之间更新智能体的指令和共享知识库。当我想改变某个智能体的工作方式时，我会在 Nakama 的 Slack 频道里用平实的语言写下我的要求。只有我可以发布修改智能体指令和系统提示词的请求。协调者大约每 15 分钟查看一次该频道，接收请求并完成更新。

> Each agent runs on a [schedule](https://claude.com/blog/whats-new-in-claude-managed-agents). A sixth agent, the Nakama's coordinator, is the fleet’s operations manager. It updates the agents’ instructions and the shared knowledge base between runs. When I want to change how an agent works, I write what I want in plain language in the Nakama’s Slack channel. Only I can post requests for changes to agents’ instructions and system prompts. The coordinator checks that channel every 15 minutes or so, picks up the request, and makes the update.

![A graphic showing the agents and their roles](https://assets.claude.com/1fabdce2187d0997e43f9b0518820c25606a0f1d.png)

#### 在 Claude 中构建集群原型

> Prototyping the fleet in Claude

你无需 Managed Agents 也能起步。我最初是先在 Claude 中把整个智能体集群做出原型的，用到了以下几个部分：

> You don't need Managed Agents to start. I prototyped the whole fleet in Claude first, using the following pieces:

- 每个智能体一个技能：即完成一项工作的指令。
- 为每个技能设置一个定时任务，这样我就不需要手动运行了。
- 我笔记本电脑上的一个共享文件夹，作为知识库，每个技能都会把它学到的东西写回其中：包括它起草的内容与我实际发出的内容之间的差异，以及它在过程中挖掘到的任何新信息。

> • A skill per agent: the instructions for one job.
> • A scheduled task for each skill, so I don’t need to run it manually.
> • A shared folder on my laptop as the knowledge base every skill writes its learnings back into: the difference between what it drafted and what I sent, plus anything new it dug up along the way.

在 Managed Agents 上，技能变成了代理的系统提示词，定时任务变成了[代理部署上的计划任务（在新标签页中打开）](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments)，共享文件夹则变成了记忆存储。我仍然用自然语言提出修改要求，但现在全部在一个 Slack 频道中完成，而且对代理指令的每次修改都会保存为一个新版本，因此每个代理都保留着一份带编号的指令历史。我的建议是先从 Claude 开始，等到代理多到难以轻松管理时，再把它们迁移到 Managed Agents。

> On Managed Agents, the skill became the agent's system prompt, the scheduled task became a [schedule on the agent's deployment (opens in new tab)](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments), and the shared folder became a memory store. I still ask for changes in plain language, but now I do it all in one Slack channel, and each change to an agent's instructions is saved as a new version, so each agent keeps a numbered history of its instructions. I'd suggest starting in Claude and moving your agents to Managed Agents once you have more than you can comfortably keep track of.

![graphic showing how the agents were deployed on Claude Managed Agents](https://assets.claude.com/a04a480dffb7c328be71e45d708df2ccb10c3e30.png)

#### 在 Claude Managed Agents 上运行智能体集群

> Running the fleet on Claude Managed Agents

在 Managed Agents 上，对我的工作流最重要的三点收获：

> Three things I got on Managed Agents that mattered most for my workflow:

**智能体可以在后台运行**

> **The agents can run in the background**

无论我的笔记本电脑是否开着，甚至在离线时，这些智能体都会按照各自的计划运行。运行计划是每个智能体部署的一部分。我在 Claude 中也可以为技能设定运行计划，但每一个计划都是在我自己的应用里配置的任务。而在 Managed Agents 上，我在 Console 中设置运行频率和时区，就在已部署智能体的指令和工具旁边，也不需要额外维护任何 cron 作业。如果某次运行出了问题，我可以在 Console 中打开它，查看智能体执行的每一个步骤。而且，当我在试验对某个智能体的修改时，计划运行会继续使用已部署的版本，因此改到一半的内容不会被带进第二天的运行中。

> The agents run on their schedule whether my laptop is open or not, even when it's offline. The schedule is part of each agent's deployment. I could schedule skills in Claude too, but each of those schedules was a task set up in my own app. On Managed Agents, I set the cadence and timezone in the Console, next to the deployed agent's instructions and tools, and I have no cron jobs to maintain on the side. If a run goes wrong, I can open it in the Console and see each step the agent took. And while I'm trying out a change to an agent, the scheduled runs keep using the version that’s deployed, so a half-finished edit doesn't end up in tomorrow's run.

**Nakama 共享同一份记忆，并从我的修改中学习**

> **The Nakama shares one memory and learns from my edits**

每个智能体都读写同一个[记忆存储（在新标签页中打开）](https://claude.com/blog/claude-managed-agents-memory)，因此任何智能体都能利用其他智能体积累的经验。智能体会把自己写的草稿与我实际发出的邮件进行对比，并将每一处差异保存为一条笔记，记录我会如何措辞。它们还会保留在研究答案过程中从我们的内部文档和官方网站中挖掘到的任何新信息。我只需在 Henji 的草稿中修正一次措辞，Sabaki 和 Nokori 就不会再犯同样的错误。

> Every agent reads and writes the same [memory store (opens in new tab)](https://claude.com/blog/claude-managed-agents-memory), so any agent can use the others’ learnings. The agents compare the drafts they wrote with the emails I sent, and they save each difference as a note on how I'd phrase it. They also keep whatever new information they dig up while researching an answer, from our internal docs and our official websites. I fix a phrasing once in Henji's drafts, and Sabaki and Nokori stop making the same mistake.

**凭据存放在具有限定权限范围的托管保管库中**

> **Credentials live in a managed vault with scoped permissions**

我的智能体可以访问我的电子邮件和我们的 Salesforce 记录，但由于这些涉及客户对话和公司记录，我希望这种访问处于受控状态。凭据存放在[托管保管库（在新标签页中打开）](https://platform.claude.com/docs/en/managed-agents/vaults)中，这些保管库用于保护智能体登录外部服务时所用的凭据，例如 OAuth 访问令牌和刷新令牌、API 密钥以及个人访问令牌。每个智能体的部署只使用其工作所需的保管库，智能体永远看不到凭据本身，而我可以一步撤销访问权限。

> My agents have access to my email and our Salesforce records, but since these are customer conversations and company records, I wanted that access under control. The credentials live in [managed vaults (opens in new tab)](https://platform.claude.com/docs/en/managed-agents/vaults), which protect credentials agents use to log in to outside services, such as OAuth access and refresh tokens, API keys, and personal access tokens. Each agent’s deployment uses only the vaults its job needs, it never sees the credentials, and I can revoke access in one step.

#### 将后续步骤交给 Claude Tag

> Handing the next steps to Claude Tag

对于 Nakama 产出的大部分内容，我只需要在收件箱里读一下草稿然后发出去，或者扫一眼更新后的 Salesforce 记录。但有些事项需要后续跟进，比如弄清楚升级路径或采购渠道，或者把问题升级给其他团队处理。

> For most of what the Nakama produces, I only need to read a draft in my inbox and send it, or glance at an updated Salesforce record. But some items need a follow-up step, such as figuring out an upgrade path or a purchasing route, or escalating an issue to another team.

对于这类事项，智能体不会停下来等我。它们会把事项交给 [Claude Tag（在新标签页中打开）](https://www.anthropic.com/news/introducing-claude-tag)（测试版）。Claude Tag 是被设置为我们 Slack 工作区成员的 Claude：在它已加入的频道中，任何人，无论是人还是我的某个智能体，都可以 @Claude 提出请求，它会接下请求并在该消息串中处理。一旦在你的工作区中配置好，就没有任何新东西需要学习。你像标记同事一样标记 Claude 即可。

> For those, the agents don't stop and wait for me. They hand the item to [Claude Tag (opens in new tab)](https://www.anthropic.com/news/introducing-claude-tag) (in beta). Claude Tag is Claude set up as a member of our Slack workspace: anyone in a channel it has joined, a person or one of my agents, can tag @Claude with a request and it picks the request up and works on it in the thread. Once it's configured in your workspace there is nothing new to learn. You tag Claude the way you would a colleague.

在我的设置中，它是这样运作的。一个智能体把待办事项发布到 Nakama 的 Slack 频道并标记 Claude。Claude 会阅读该讨论串，核对我们的规则和适用的条款，列出可选方案，并起草所需的内容。当某个步骤需要我审阅或签批时，它会标记我。当需要客户或其他团队先回复时，Claude 会给自己设置一个提醒，在指定的日期回来查看。在下面的讨论串中，它设置了一个周二的提醒，届时查看客户是否已回复，以及交易台（deal desk）是否已答复工单。提醒到期时，Claude 会检查这两项，并在同一讨论串中发布当前进展。如果有人需要催一下，它会起草消息并标记我来发送。

> In my setup it works like this. An agent posts the action item to the Nakama's Slack channel and tags Claude. Claude reads the thread, checks our rules and the terms that apply, lays out the options, and drafts what's needed. It tags me when a step needs my review or sign-off. When a customer or another team needs to reply first, Claude sets a reminder for itself to check back on a set day. In the thread below, it set a reminder for Tuesday to check whether the customer had replied and whether the deal desk had answered the ticket. When the reminder comes due, Claude checks both and posts where things stand in the same thread. If someone needs a nudge, it drafts the message and tags me to send it.

![A screenshot mock of a conversation between a human, Claude, and an agent](https://assets.claude.com/407d1a67eadd3ebd1d4ec34fd1fabebb42b64829.png)

Claude 还会在每天早上发布一份产品和定价更新简报。Nakama 协调员会接收这份简报，并将必要的变更写入共享知识库。

> Claude also posts a morning brief of product and pricing updates. The Nakama coordinator picks up that brief and writes the necessary changes into the shared knowledge base.

#### 我这一周发生了哪些变化

> What changed in my week

现在，Claude 会准备入站邮件的回复，并在（大体上）无需我手动输入的情况下保持 CRM 记录的更新，我的职责则是审核任何需要人工判断的事项。一份书面规则手册界定了每个智能体的职责范围，诸如定价问题、敏感客户或含义模糊的请求等事项都会转交给我处理。Henji、Sabaki 或 Nokori 起草的每封邮件，顶部都附有一段简短摘要，说明当前的情况，因此我无需追溯整个邮件往来就能了解背景：我阅读摘要、确认、修改，然后发送。

> Now that Claude prepares inbound replies and keeps CRM records current (mostly) without my manual input, my role is to review anything that requires human judgment. A written rulebook defines each agent's lane and items like pricing questions, sensitive accounts, or ambiguous asks route to me. Every email draft from Henji, Sabaki, or Nokori arrives with a short summary at the top of what's going on, so I don't have to trace the whole thread to understand the context: I read the summary, confirm, make revisions, and send.

![A screenshot of an email drafted by Claude, for review by the human.](https://assets.claude.com/209fde33711300fd8cfb2f1fc7005f21bca2a20d.png)

查看 Nakama 每周完成工作的日志，并把每项任务按我手动完成所需的时间来计算，这支智能体队伍每周为我节省了大约 60 小时的工作量。我把腾出来的时间用在智能体（目前）还无法有效完成的工作上：与客户交流、制定外联策略、推进跨职能项目，以及帮助队友搭建他们自己的智能体队伍。

> Looking at the weekly log of what the Nakama gets through and counting each task as the time it would have taken me to do manually, the fleet saves me around 60 hours of work. I spend the time that frees up on work that agents can't effectively do (yet): conversations with customers, outbound strategy, cross-functional projects, and helping teammates build their own fleets.

#### 设计更高效的智能体

> Designing agents to be more efficient

无论我是否在盯着，定时智能体每天都会运行，因此浪费会不断累积，体现在成本和可靠性两方面。最常见的错误包括：在现有指令上不断追加内容而不是更新它们，给智能体提供超出其任务所需的上下文，以及让每个任务都在最大的模型上以最高的投入等级运行。

> Scheduled agents run every day whether I'm watching or not, so waste can add up, in cost and reliability. Some of the most common mistakes include adding to existing instructions rather than updating them, giving agents more context than they need for their tasks, and running every job on the biggest model at the highest effort level.

让这些智能体保持高效的，主要在于我对整个智能体集群的设计方式：每个智能体只负责一项工作，因此它的指令始终聚焦于这项工作；每个执行工作的智能体都按计划运行，因此它会被唤醒、完成一轮处理，然后停止；而且这些智能体共享记忆，因此一次修正就能在所有地方复用。

> Most of what keeps the agents efficient is how I designed the fleet: each agent has one job, so its instructions stay focused on that job; each working agent runs on a schedule, so it wakes up, does its pass, and stops; and the agents share memory, so a correction made once is reused everywhere.

另一个重要因素是每个智能体运行在哪个模型上。一旦某个智能体的职责界定清楚，它可能就不需要我们能力最强的模型。Furiwake 和 Shoudan 遵循一份成文的规则手册，因此它们运行在我们较小的模型 Sonnet 上。Sabaki、Nokori 和协调者运行在我们较大的模型 Opus 上，因为它们的工作需要更多判断力。协调者对判断力的需求最高，因为它会修改其他智能体的指令，一次错误的修改就会波及所有智能体。Henji 需要的判断力与 Sabaki 相当，因为每位客户的邮件都各不相同，但它的运行频率也高于其他任何智能体，整个工作日都在运行。每次都用 Opus 运行它将是成本最高的选择，所以我在 Managed Agents 中使用了[顾问策略（在新标签页中打开）](https://claude.com/blog/the-advisor-strategy)：Henji 运行在 Sonnet 上，当遇到无法独自做出的决定时，它会向 Opus 征求建议。顾问会阅读 Henji 目前已完成的工作，并返回一个计划、一处修正或一个停止信号，随后 Henji 完成草稿供我审阅。我还将每个智能体的投入程度（模型在回答前思考多长时间）与其模型分开设置，并且只在推理难度较大的地方才调高它，比如 Henji 的回复。

> The other big factor is which model each agent runs on. Once an agent's job is well defined, it may not need our most capable model. Furiwake and Shoudan follow a written rulebook, so they run on Sonnet, our smaller model. Sabaki, Nokori and the coordinator run on Opus, our larger model, because their work needs more judgment. The coordinator needs it most, since it edits the other agents' instructions and one bad edit would reach every agent. Henji needs as much judgment as Sabaki, because every customer's email is different, but it also runs more often than any other agent, all through the working day. Running it on Opus every time would be the most expensive option, so I use the [advisor strategy (opens in new tab)](https://claude.com/blog/the-advisor-strategy) in Managed Agents: Henji runs on Sonnet, and when it reaches a decision it can't make on its own, it asks Opus for advice. The advisor reads what Henji has done so far and sends back a plan, a correction, or a stop signal, and Henji then finishes the draft for my review. I also set each agent's effort level (how long the model thinks before it answers) separately from its model, and I raise it only where the reasoning is hard, as with Henji's replies.

![A graphic showing which models the different agents use for their jobs](https://assets.claude.com/f9f71df9bc447aba6114949e002ce0fb8dd34ba2.png)

#### 我的收获

> What I learned

对于任何想搭建自己集群的人，我有三点经验想分享。

> Three things I'd pass on to anyone building their own fleet.

1. **你不必每次都写一份详细的提示词。**只需把任务描述一次，让 Claude 起草，修改草稿，再让它把这些修改记下来沿用。
2. **知识库比提示词更重要。**每一次修正和过往交互都会保存在所有智能体都能读写的地方，因此 Claude 从那里获取上下文，而不是依赖更长的提示词。经过几百轮低成本的起草、修改和保存，草稿才写得像我本人的风格。
3. **尽早给 Claude 更多空间。**起初，我一直亲手做那些我以为必须由我来做的任务：更新知识库，或者逐个手动编辑每个智能体的指令。后来我放手了，这两件事也都运转良好。现在，智能体会自己把学到的东西写进知识库；当我用平实的英语提出要求时，协调者会更新其他智能体的指令。对于那些本可以放心交给智能体的工作，我之前过于谨慎了。

> 1\. **You don't need a detailed prompt every time.** Describe the job once, let Claude draft, fix the draft, and let it keep the fix.
> 2\. **The knowledge base matters more than the prompt.** Every correction and past interaction is saved where all the agents can read it and write to it, so Claude takes its context from there instead of from a longer prompt. It took a few hundred cheap rounds of drafting, fixing, and saving to get the drafts to sound like me.
> 3\. **Give Claude more room, sooner.** At first I kept doing the tasks that I assumed needed me: updating the knowledge base, or editing each agent's instructions by hand. Both worked fine once I let go of them. The agents now write what they learn into the knowledge base themselves, and the coordinator updates the other agents' instructions when I ask in plain English. I had been too cautious with work I could trust the agents to do.

[开始使用 Claude Managed Agents（在新标签页中打开）](https://platform.claude.com/workspaces/default/agent-quickstart)

> [Get started with Claude Managed Agents (opens in new tab)](https://platform.claude.com/workspaces/default/agent-quickstart)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| BDR (Business Development Representative) | 业务拓展代表 | 负责开拓和评估潜在客户线索、发起初次触达的销售岗位。 |
| Claude Managed Agents | Claude 托管智能体 | Claude Platform 上提供的托管式智能体基础设施，支持部署、调度、记忆和凭据管理。 |
| Agent Fleet | 智能体集群 | 由多个各司其职、协同工作的智能体组成的整体。 |
| Skill | 技能 | 在 Claude 中定义如何完成某项工作的一组可复用指令。 |
| System Prompt | 系统提示词 | 设定智能体角色、职责和行为方式的基础指令。 |
| Scheduled Deployment | 计划部署 | 为已部署智能体设置运行频率和时区，使其按计划自动执行。 |
| Memory Store | 记忆存储 | 供多个智能体共同读写、持久保存知识与修正记录的存储。 |
| Vault | 保管库 | 安全保存智能体访问外部服务所需凭据的托管存储。 |
| OAuth Token | OAuth 令牌 | 基于 OAuth 协议授权访问外部服务的访问令牌或刷新令牌。 |
| Claude Tag | Claude Tag | 作为 Slack 工作区成员的 Claude，可被 @ 提及接收请求并在消息串中处理。 |
| Orchestrator | 协调者 | 负责管理和更新其他智能体指令与共享知识的智能体。 |
| Advisor Strategy | 顾问策略 | 让较小模型执行任务、在难以独自决策时向较大模型征求建议的模式。 |
| Effort Level | 投入程度 | 控制模型在回答前思考时长的参数，可与模型选择分开设置。 |
| CRM (Customer Relationship Management) | 客户关系管理系统 | 记录和管理客户、线索及商机信息的业务系统。 |
| Deal Desk | 交易台 | 负责审核和支持报价、合同条款等交易事务的内部团队。 |
