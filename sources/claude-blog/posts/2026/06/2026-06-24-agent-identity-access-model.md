---
source: claude-blog
source_url: https://claude.com/blog/agent-identity-access-model
published_at: 2026-06-24
category: Claude Code
title_en: Agent identity in Claude Tag: a new access model for autonomous, team-wide AI
title_zh: Claude Tag 中的智能体身份：面向自主、团队级 AI 的全新访问模型
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 4
source_image_count: 1
---

# Claude Tag 中的智能体身份：面向自主、团队级 AI 的全新访问模型

_英文标题：Agent identity in Claude Tag: a new access model for autonomous, team-wide AI_

> 来源：Claude Blog，2026-06-24
> 原文链接：https://claude.com/blog/agent-identity-access-model
> 分类：Claude Code

## 核心要点

- 在多人协作（multiplayer）的 AI 体验中，"以用户身份行事"的传统模型行不通，因为智能体自主性不断提升，且共享频道中有多人同时操作，无法确定该套用谁的权限。
- 智能体身份模型让 Claude 拥有自己的账户：它以 Claude 应用身份在 Slack 发帖、以 Claude GitHub 应用身份开 PR、以管理员配置的服务账户查询数据仓库。
- 访问问题从"这个用户能做什么"转变为"这个智能体在这个隔间里能做什么"，权限从"按用户"转为"按频道"。
- 管理员在工作区层级定义身份基线，频道默认继承，并可在频道层级覆盖；可配置仓库访问、连接器（connectors）、技能与插件、常驻指令等。
- 私有频道各自拥有独立身份，公共频道共享工作区级身份；记忆与访问均遵守这些边界。
- 建议从宽松访问起步，再依据组织管理偏好收紧；每一次授权都谨慎、逐步进行，并配合审计追踪。
- 私信（DM）运行在用户个人 claude.ai 账户上，与共享频道机制不同；未来将引入即时凭证授权和身份感知叠加层。

## 正文

Claude Tag 的智能体身份（agent identity）访问模型如何运作，以及在团队工作区中配置它的最佳实践。

> ⌁
> How Claude Tag’s agent identity access model works, and best practices for configuring it in your team’s workspace.

要让 AI 智能体（agent）在人机协作团队中发挥最佳表现，它需要访问与人类相同的工具、文档和上下文。

> ⌁
> For an AI agent to do its best work on a human-agent team, it needs access to the same tools, documents, and context humans have.

在"单人"AI 体验中（即一个人与一个助手对话），这很简单：你接入自己的账户，智能体代表你行动。但在像 Claude Tag 这样的"多人"AI 体验中，Claude 与许多人同处一个共享频道，它依赖的是属于该工作空间（workspace）的工具和上下文，而非任何单个个人的。

> ⌁
> In a “single player” AI experience (where one person chats with one assistant), that’s straightforward: you connect your own accounts and the agent acts on your behalf. But in a “multiplayer” AI experience like Claude Tag , Claude sits in a shared channel alongside many people at once, and it draws on the tools and context that belong to the workspace , rather than any one individual.

要让多人体验正常运转，Claude 需要为这些工具拥有自己的账户，由管理员设置并与工作空间绑定。我们将这种访问模型称为智能体身份（agent identity）。

> ⌁
> To make multiplayer experiences work, Claude needs its own accounts for those tools, set up by an admin and tied to the workspace. We call this access model agent identity .

在本文中，我们将解释智能体身份如何运作、它如何把权限从按用户（per-user）转变为按频道（per-channel），以及如何在你自己的工作空间中恰当地设定其范围。

> ⌁
> In this post, we explain how agent identity works, how it moves permissions from per-user to per-channel, and how to scope it well in your own workspace.

### “以用户身份行事”为何行不通

_Why “act as the user” breaks down_

当你把 AI 当作个人助手使用时，可以连接 Google Drive、GitHub、日历等平台，让模型借用你的访问权限在其中读写。

> ⌁
> When you use AI as a personal assistant, you can connect platforms like Google Drive, GitHub, and your calendar, and let the model use your access permissions to read and write in them.

这种模式对 Claude Tag 不适用，原因有二：

> ⌁
> This model doesn’t work for Claude Tag for two reasons:

- 代理自主性不断提升。AI 代理能够可靠地独立完成的任务时长，大约每四个月就翻一番。如今代理会自行安排稍后执行的任务，并在提出请求的人早已下线很久之后响应事件。虽然用户会设置一些在特定情形下触发代理行动的例程，但代理在很大程度上是自主工作的。
- 多人协作团队。Claude Tag 把 Claude 放进团队已经在协作的共享空间——例如，三名工程师和一名产品经理一起调试问题的频道。但当不止一个人在指挥时，该套用谁的权限？没有任何单一的人选在任何时候都是正确的。这让管理员能够独立于参与的人来定义代理在 Slack 中可以做什么，并对在 Slack 中所做之事进行独立的追踪。

> ⌁
> - Increasing agent autonomy. The length of a task that an AI agent can reliably complete on its own has been doubling roughly every four months . Agents now schedule their own tasks for later and respond to events long after the person who asked has logged off. While users set up routines that trigger them to act given certain situations, the agent works largely autonomously.
> - Multiplayer teams. Claude Tag places Claude in shared spaces where teams are already working—e.g., a channel where three engineers and a PM are debugging together. But when more than one person is steering, whose permissions apply? There’s no single choice of person that’d be right all of the time. This gives admins the ability to define what an agent can do in Slack independent from the humans involved, and a distinct tracking of what is done in Slack.

#### Claude 以自身身份行事

_Claude acts as itself_

在启用了 Claude Tag 的频道里，Claude 并不是代表某个单一用户行事。它在所接触的每个系统中都有自己的账户：在 Slack 中以 Claude 应用的身份发帖，以 Claude GitHub 应用的身份提交拉取请求（pull request），并以管理员配置的服务账户查询你的数据仓库。

> ⌁
> In a channel where Claude Tag is active, Claude isn’t acting on behalf of a single user. It has its own account in each system it touches: it posts in Slack as the Claude app, opens pull requests as the Claude GitHub App, and queries your warehouse under a service account provisioned by an admin.

而且由于不涉及任何个人用户凭据，共享频道永远不会变成通往某人私人文档的旁门。

> ⌁
> And because there are no personal user credentials in play, a shared channel can never become a side door into someone’s private documents.

#### 继承权限

_Inheriting permissions_

在代理身份模型中，管理员在工作区（workspace）层级定义一个身份——即 Claude 在各处持有的基线连接与技能集合——每个频道默认继承它。然后，在合理的场景下，他们可以在频道层级覆盖该设置，比如授予工程频道访问 GitHub 和数据仓库的权限，或将某个 CRM 连接限定在单个私有频道内。

> ⌁
> In the agent identity model, admins define an identity—the baseline set of connections and skills Claude holds everywhere—at the workspace level, and every channel inherits it by default. Then, where it makes sense, they can override it at the channel level, such as by granting the engineering channel access to GitHub and the data warehouse, or confining a CRM connection to a single private channel.

除凭据之外，管理员还会定义：

> ⌁
> In addition to credentials, admins also define:

- 仓库访问：Claude 可以读写哪些代码仓库。
- 连接器（connectors）：Claude 完成工作所用的工具和 API 密钥。在整个组织中，不同的 API 密钥可以以不同权限级别连接到同一服务（例如，Claude 在一个通用频道里可能被授予只读的仓库访问权限，而在数据团队的私有频道里则拥有写入权限）。
- 技能与插件：包含指令、脚本和资源的文件夹，Claude 会动态加载这些内容以提升在专门任务上的表现。
- 常驻指令：为每个频道定制的指令和上下文。

> ⌁
> - Repository access: which repos Claude can read and write to.
> - Connectors: the tools and API keys that Claude uses to do its job. Across an organization, different API keys can connect to the same service at different permission levels (e.g., Claude might be given read-only warehouse access in a general channel, and write access in the data team’s private one).
> - Skills and plugins: folders of instructions, scripts, and resources Claude loads dynamically to improve performance on specialized tasks.
> - Standing instructions: custom instructions and context for each channel.

由于该模型围绕各自独立的 Claude 身份运作，撤销某个身份即可终止 Claude 在使用该身份的所有地方的访问权限。相比在数十个用户账户中审计单个代理行为，这种方式的管理成本要低得多。

> ⌁
> Because this model works around distinct Claude identities, revoking the identity ends Claude’s access everywhere that the identity was used. This takes much less effort to manage than auditing individual agent actions across dozens of user accounts.

### 智能体身份模型的工作原理

_How the agent identity model works_

智能体身份把“这个用户能做什么？”这一问题替换为“这个智能体在这个隔离区里能做什么？”。这与按用户设置的访问控制列表（Access Control Lists）不同：它意味着如果频道的配置授予了 Claude 相应权限，一个对仓库没有直接访问权的频道成员也可以让 Claude 读取该仓库。

> ⌁
> Agent identity replaces the question “what can this user do?” with “what can this agent do in this compartment?” That’s a departure from per-user Access Control Lists: it means that a channel member without direct access to the repo can ask Claude to read that repo, if the channel’s profile grants Claude that permission.

这并不常见，但我们认为这是迈向一种适用于自主、多人协作智能体的访问模型的必要一步。下面，我们勾勒出如何思考设定这些边界。

> ⌁
> This is unusual, but we think it is a necessary step toward an access model that works for autonomous, multiplayer agents. Below, we sketch out how to think about setting those boundaries.

#### 身份边界如何运作

_How identity boundaries work_

Claude Tag 为每个私有频道创建一个独立身份；工作区中的公开频道共享一个工作区级别的身份。Claude 在法务频道中的身份无法触及未在该处授权的代码，它在工程频道中的身份也无法读取未在该处授权的法务文档。记忆与访问都遵循这些边界：Claude 在私有频道中学到的内容绝不会出现在更广的工作区中。

> ⌁
> Claude Tag creates a distinct identity for each private channel; public channels in a workspace share a workspace-level identity. Claude's identity in a legal channel can't reach code that wasn't granted there, and its identity in an engineering channel can't read legal documents that weren't granted there. Memory and access respect those boundaries: what Claude learns in a private channel never appears in the wider workspace.

身份属于频道，因此默认情况下频道内任何人都可以标记（tag）Claude，管理员则可以把每个频道的配置限定到权限最低的成员。在企业版方案中，基于角色的访问控制让管理员可以更进一步，决定哪些成员能够调用 Claude，从而让频道既管控智能体能触及什么，也管控谁能发起请求。

> ⌁
> The identity belongs to the channel, so anyone in it can tag Claude by default, and admins can scope each channel's profile to the least-privileged member. On Enterprise plans, role-based access control lets admins go further and decide which members can invoke Claude at all, so a channel governs both what the agent can reach and who can ask.

#### 对工具与上下文的广泛默认访问

_Broad default access to tools and context_

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a3a0eae87418506ee6e5b08_agent-access-scoping%20(2).jpg)

在 Anthropic 内部运行 Claude Tag 时，我们发现它的价值会随着工具与上下文访问而叠加放大。每一个接入的系统都让其他系统更有用，因为 Claude 可以跨系统组合上下文——把 Slack 里的一条讨论、Drive 里的一份文档、追踪器里的一张工单，以及数据仓库的一次查询，汇聚成任何单一工具都无法提供的一个答案。

> ⌁
> Running Claude Tag inside Anthropic, we found that its value compounds with tool and context access. Each connected system makes every other one more useful, because Claude can combine context across them—pulling a thread from Slack, a doc from Drive, a ticket from a tracker, and a query from a warehouse into one answer that no single tool could provide.

从 Claude 身上获益最多的团队，是那些一开始就慷慨授予访问权、再依据组织管理员偏好逐步收回访问权的团队。智能体身份给管理员足够宽的范围，让 Claude 能做有用的跨系统工作，同时边界又足够牢固，使访问权绝不会流向未被授权之处。我们的建议是：先在几个频道里使用一个基线配置，查看审计记录，然后在工作确有需要之处扩展访问权，一次只审慎地授予一项。

> ⌁
> The teams that get the most out of Claude are the ones that grant it generous access from the start, and pare access back depending on their organization’s admin preferences. Agent identity gives admins broad enough scope for Claude to do useful cross-system work, with boundaries firm enough that the access never travels somewhere it wasn’t granted. Our advice is to start with a baseline profile in a few channels, read the audit trail, and then extend access where the work justifies it, one deliberate grant at a time.

对于需要更细粒度的组织，管理员可以在特定频道中停用 Claude Tag。管理员也可以应用基于角色的访问控制（RBAC），将 Claude Tag 的访问权限限定给特定用户。

> ⌁
> For organizations that require even more granularity, admins can disable Claude Tag in specific channels. Admins can also apply role-based access controls (RBAC) to limit access to Claude Tag to specific users.

#### 私信

_Direct messages_

使用 Claude Tag 时，私信（DM）的运作方式与共享频道不同。私信运行在用户各自的 claude.ai 账户上——使用他们自己的连接器、凭据，结果也署他们的名字。这使私信成为适合处理那些绝不应存在于频道中的任务和工具的场所，例如邮件草稿或只有你拥有许可证的软件。

> ⌁
> With Claude Tag, direct messages work differently than in shared channels. DMs run on users’ individual claude.ai accounts—their connectors, credentials, and name on the result. This makes DMs the right place to work with Claude on tasks and with tools that should never live in a channel, like email drafts or software only you have a license for.

#### 安全与审计

_Security and audit_

当管理员把一个连接添加到某个频道的配置中时，凭据会被独立存储并映射到该频道的身份，随后在请求时于网络边界处注入。流向任何管理员未允许主机的出站流量都会被直接阻断。在审计方面，每一次例程、记忆写入和使用智能体凭据发起的网络调用都会被记录，而且由于 Claude 以自己的服务账户行事，这些操作也会出现在每个接入系统各自的日志中。

> ⌁
> When an admin adds a connection to a channel's profile, the credential is stored independently and mapped to that channel's identity, then injected at the network boundary at request time. Outbound traffic to any host an admin hasn't allowed is blocked outright. On the audit side, every routine, memory write, and network call made with agent credentials is recorded, and because Claude acts under its own service accounts, those actions also land in each connected system's own logs.

### 接下来的计划

_What’s next_

智能体身份是 Claude Tag 访问模型的基础。未来，我们计划强化 Claude Tag 的安全能力，包括即时凭证授予（just-in-time credential grants）——让用户可以在当下批准单次敏感操作，而无需永久扩大智能体的权限范围——以及面向具有更复杂权限结构组织的身份感知（identity-aware）叠加层。这将在智能体的权限范围之上增加用户级别的检查，因此只有当频道的配置和发起请求用户自身的权限都允许时，Claude 才会执行操作。

> ⌁
> Agent identity is the foundation of Claude Tag's access model. In the future, we plan to strengthen our Claude Tag’s security offerings to include just-in-time credential grants—so that a user can approve a single sensitive action in the moment without permanently widening the agent's scope—and an identity-aware overlay for organizations with more complex clearance structures. This will add user-level checks on top of an agent’s scope, so Claude only acts when both the channel's profile and the requesting user's own permissions allow it.

从单人模式到多人协作 AI 的转变，让 Claude Tag 这类产品中长时间运行、基于团队的工作成为可能。智能体身份确保 Claude 对工具的访问既足够广泛以发挥作用，又足够受限以在企业规模下保持安全。

> ⌁
> The shift from single player to multiplayer AI in products like Claude Tag makes long-running, team-based work possible. Agent identity ensures that Claude’s access to tools is broad enough to be useful, but scoped enough to be secure at enterprise scale.

进一步了解 Claude Tag。

> ⌁
> Learn more about Claude Tag.

本文由 Claude Code 团队的技术人员 Noah Zweben 撰写。

> ⌁
> This article was written by Noah Zweben, a member of technical staff on the Claude Code team.

## 术语对照

| English | 中文 |
|---|---|
| agent identity | 智能体身份 |
| single player / multiplayer | 单人 / 多人 |
| workspace | 工作区 |
| Access Control List (ACL) | 访问控制列表 |
| role-based access control (RBAC) | 基于角色的访问控制 |
| connectors | 连接器 |
| skills and plugins | 技能与插件 |
| standing instructions | 常驻指令 |
| pull request | 拉取请求 |
| service account | 服务账户 |
| direct message (DM) | 私信 |
| just-in-time credential grants | 即时凭证授权 |
| identity-aware overlay | 身份感知叠加层 |
| audit trail | 审计追踪 |
