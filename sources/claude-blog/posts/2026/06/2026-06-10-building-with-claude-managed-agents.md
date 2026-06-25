---
source: claude-blog
source_url: https://claude.com/blog/building-with-claude-managed-agents
published_at: 2026-06-10
category: Agents
title_en: The evolution of agentic surfaces: building with Claude Managed Agents
title_zh: 智能体形态的演进：基于 Claude Managed Agents 构建
source_intro_paragraphs: 2
source_image_count: 9
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/m9bN7RYPWdlg2n09IK25RLpeWZd1wyK0"
---

# 智能体形态的演进：基于 Claude Managed Agents 构建

> 来源：Claude Blog，2026-06-10
> 原文链接：https://claude.com/blog/building-with-claude-managed-agents
> 分类：Agents

## 导语

随着模型智能与智能体框架（agentic harness）的演进，Claude Managed Agents 让团队能够在生产环境中可靠地大规模构建和部署智能体。以下是团队选择使用它的原因和方法。

## 核心要点

- Anthropic 的智能体构建模块从最初的 Messages API（一次请求、一次响应），演进到 Claude Agent SDK（复用 Claude Code 框架），再到 Claude Managed Agents（托管基础设施）。
- Managed Agents 的核心架构是「将大脑与双手解耦」：调用 Claude 的框架与执行代码的沙箱分离运行，二者通过仅追加的会话日志（session）连接。
- 它围绕三大核心资源构建：智能体（agent）、环境（environment）、会话（session）。
- 解耦架构带来多重收益：凭据隔离于沙箱之外、消除沙箱开销降低延迟（首字时延 p50 约降 60%、p95 降超 90%）、可靠持久的会话支撑可观测性与记忆。
- 支持 Anthropic 托管或自托管云容器，并提供 MCP 隧道，让团队精确控制哪些内容留在自身边界内。
- 框架随模型一同演进，团队无需再为框架调优耗费精力，可专注于上下文管理与领域专长。
- Notion、Rakuten、Sentry、Asana、Atlassian 等客户已在生产中基于 Managed Agents 交付智能体。

## 中文译文

将一个智能体（agent）投入生产，远不止需要一段好的提示词。智能体需要一个运行它所编写代码的地方、访问你数据的凭据、可观测的会话，以及随用量扩展的基础设施。在应用人工智能（Applied AI）团队，我们工作在产品、研究与基于 Claude 构建产品的客户的交叉点上——我们反复看到同一种模式：基础设施才是区分原型与生产级智能体的关键。团队太常把开发周期消耗在安全、状态管理、权限控制和框架调优上。

Claude Managed Agents 是我们用于构建和部署生产级智能体的一套可组合 API（composable APIs），它将一个为性能调优的智能体框架（agent harness）与生产基础设施配对，让团队能够在数天而非数月内从原型走向上线。在本文中，我们将介绍 Anthropic 智能体构建模块的演进、我们为何打造 Claude Managed Agents，以及当下团队如何在生产中使用它。

### 智能体架构的演进

2023 年我们向开发者开放 Claude 时，API 的设计刻意简单：输入 token，输出 token。你发送一段提示词，Claude 返回一个补全结果，框架和底层基础设施由你自己构建。

多年来 API 稳步变得更丰富，但底层契约从未改变：一次请求、一个模型回合，由你的应用决定接下来发生什么。在很长一段时间里，这就足够了。总结一篇文档、对一张支持工单分类、改写一段文字——这类工作都能舒适地装进单个回合。

然而随着时间推移，人们想要交付的任务不再适配这种模式。他们希望 Claude 把一项任务一路执行到底：查找某些信息、据此采取行动、查看变化了什么、再决定下一步做什么。他们还希望它能在自己工作已经运行其上的系统中操作，比如代码库、内部维基或工单系统。

使用 API，把 Claude 变成智能体意味着要自己构建循环：询问模型该做什么、运行工具、把结果反馈回去、如此重复。你要负责构建和部署智能体脚手架，而它可能需要随模型演进而调优。对于需要完全定制的智能体，这种方式是合理的。但对于更可预测、更不复杂的智能体工作负载，随着模型和产品演进而不断优化框架变得繁琐。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298c28f950480f89a8dfcf_01%20_%20Messages%20API.png)

Claude Code 是我们 2025 年推出的智能体编码工具，它让 Claude 直接与你的代码库交互，其中包含了我们自己版本的那种框架：循环、工具执行、子智能体（subagents）、上下文管理，以及让它成为高效智能体的丰富能力。开发者自然希望在各种领域为自己的智能体也用上类似的框架机制。

为了让团队能在 Claude Code 框架之上构建智能体，我们发布了 Claude Agent SDK。Claude Agent SDK 为开发者提供工具，让他们在运行 Claude Code 的同一套机制上构建自己的智能体，而不必维护一个自研循环。对许多团队而言，正是从这时起智能体变得切实可行：框架到手时已为 Claude 调优好，并带有基础设施原语（primitives），而且会随 Claude Code 一同持续改进。

不过即便有了框架，在生产环境中部署智能体仍可能因若干原因而充满挑战：

- 托管与扩展。智能体在哪里运行？一个进程能为一项多小时任务存活多久？当用量增长时由什么来扩展它？

- 会话管理。智能体的历史和进度存在哪里？一次运行能在中断后存活并无负担地恢复吗？你能回溯查看之前会话中发生了什么吗？

- 文件系统管理。做真正的工作意味着产出制品：编辑代码、写文件、构建输出。智能体从哪里获得一个可操作的工作区？该工作区在多次运行之间会发生什么？

- 执行隔离。Claude 写的代码必须在某处执行。如果代码有误，影响范围（blast radius）有多大？在生产中你真正信得过的边界是什么？

- 凭据。智能体需要访问你的系统。它如何在不向其生成的代码暴露专有信息的情况下获得这种访问权？

- 可观测性。当一个智能体自主工作一小时并做出某些出人意料的事时，你能重建它走过的每一步吗？

借助 Agent SDK，上述生产基础设施的许多要素是通过 Claude Code 的机制提供的。智能体获得一个真实的文件系统来工作，会话状态被持久化到本地或外部存储，可观测性可通过 OpenTelemetry 导出到你已在运行的任何监控栈中。

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298c53aaeeee508f2b3166_02%20_%20Claude%20Agent%20SDK.png)

然而，随着团队越来越多地构建从本地开发走向生产的智能体，他们需要一种方式来大规模、以托管基础设施部署它们。而随着模型及其周边框架变得更先进——运行更久、执行更多代码、触及更多系统、采取更多行动——扩展、安全和沙箱化变得更具挑战性。

其中若干障碍源于一个共同的架构选择：智能体框架往往与它所操作的文件系统运行在同一个容器内。容器必须先启动（付出启动成本）Claude 才能开始思考，智能体连同代码执行就紧挨着你的凭据，而当容器死亡时，运行也随之死亡。

Managed Agents 通过将大脑与双手解耦来解决这些问题。调用 Claude 的框架与执行代码的沙箱分开运行，而会话——一份记录每次模型调用、工具调用和结果的仅追加（append-only）日志——连接二者。Claude 可以在任何容器存在之前就开始推理，沙箱远离你的凭据，并且整次运行可以在任意时刻从其会话中重建。

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298c97d4a887f2666a50b6_03%20_%20Claude%20Managed%20Agents.png)

### 何时以及为何使用 Claude Managed Agents

在使用 Managed Agents 构建时，用户定义任务、工具和护栏（guardrails），Anthropic 在我们的基础设施上运行智能体并处理底层的智能体循环：如何给智能体一个执行环境来调用工具、出错时如何恢复、多智能体编排（multi-agent orchestration）等等。

当框架不能与模型智能同步演进时，智能体就会崩坏。在 Claude Sonnet 4.5 上，智能体在接近上下文末尾时会急于完成，缩短工作而非利用它剩余的余地——这种模式被称为「上下文焦虑」（context anxiety）。我们的修复方法是给框架加入上下文重置，固化了一种假设：Claude 在接近上限时需要帮助才能保持连贯。这个假设在下一个模型上就站不住脚了。在 Claude Opus 4.5 上，这种行为消失了，我们加入的重置只剩下额外开销。

对大多数组织而言，维护一个框架是不会让其产品产生差异化的额外开销。框架必须针对特定的模型行为来调优；像压缩（compaction）、工具执行和缓存这样的原语在 Claude 上的工作方式与其他模型不同。借助 Claude Managed Agents，框架随模型一同演进，让团队能专注于真正能让其智能体产生差异化的东西：上下文管理和领域专长。

为了让开发者能配置构建高效智能体所需的上下文和工具，Managed Agents 围绕三个主要资源构建：智能体（agents）、环境（environments）和会话（sessions）。智能体是一份配置：一个模型、一段提示词、一组工具，以及围绕它们的护栏。环境是智能体运行其中的执行上下文：沙箱容器、它的网络规则，以及预装在其中的软件包，托管在我们的云上或你控制的基础设施上。每次运行都是一个会话，它将一个智能体与一个环境配对，并获得自己独立的沙箱实例。会话在服务器端持久化其完整的事件历史、沙箱状态和输出，因此长时间运行的工作可以暂停、干净地恢复，并在事后逐步追溯。借助 Managed Agents，你可以一次性定义一个智能体和一个环境，然后随着工作负载增长针对同一份配置运行多个会话。

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a29a18bb07e245f8389acb9_04%20_%20Agents_%20environments_%20sessions%20(2).png)

### 在 Managed Agents 上面向生产与规模构建

在应用人工智能团队内部，我们看到智能体在 Anthropic 内部以及客户的系统中从原型走向生产，覆盖编码、金融、支持、法律及十几个其他领域。这让我们清楚地看到什么区分了演示与生产就绪的智能体，以及团队常常在哪里卡住。

下面，我们分享在 Claude Managed Agents 这样的托管服务上构建的最常见理由：

1. 凭据被排除在沙箱之外。当一切都在一个容器中运行时，Claude 生成的代码就紧挨着你的凭据，因此提示注入（prompt injection）可能通过说服模型读取其自身环境而导致模型泄露 token。我们可以通过在同一容器内设置健壮的护栏来防范这种情况，但解耦架构通过将凭据完全排除在沙箱之外，实现了一种安全得多的方法。用于 MCP、CLI 和 GitHub 仓库等工具的 token 存放在一个独立的保险库（vault）中，由一个代理仅在按需时获取并解密它们。Managed Agents 提供开箱即用处理凭据的保险库（Vaults），因此你无需运行自己的密钥存储、在每次调用时传输 token，也不会弄不清楚智能体是代表哪个终端用户行动的。保险库凭据在存储前用信封加密（envelope encryption）保护，检索需要一个经签名的请求 token 来验证。

![Image 5](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a29a19cebb4eb7adac0a8ec_05%20_%20Managed%20Agents%20runtime%20(1).png)

2. 消除沙箱开销带来更低延迟。延迟是许多企业团队高度关注的指标，因为当用户在等待 Claude 响应时会强烈感知到这一点。没有 Managed Agents 架构时，每个会话都得启动一个容器，即使是那些智能体只需思考、从不运行工具的会话。那段启动时间被浪费了，用户会把它感受为首次响应前的延迟。借助 Managed Agents，Claude 立即开始推理，环境则并行启动，而从不运行工具的会话则完全跳过容器。这意味着用户无需等待容器启动就能看到第一个 token，而到智能体需要运行某些东西时环境已经就绪。在我们的测试中，这在中位数情况（p50）下将首字时延（time-to-first-token）削减了约 60%，在最慢情况（p95）下削减了超过 90%。

3. 可靠、持久的会话，支撑会话管理、可观测性和记忆。Managed Agents 不以请求/响应来思考，而是以事件（events）来思考。一个会话是持续的事件流：每次模型调用、工具调用和结果，都被追加到一份位于运行智能体的进程之外的日志中。借助这种架构，你能在智能体工作时随事件流入获得实时更新，并可在之后恢复任何会话，无需管理数据库或保存点。除非你删除会话，否则历史会在交互之间保留；当一个会话进入空闲时，它的容器会被检查点保存（checkpointed），因此你可以从它暂停处干净地接续。而且因为整次运行本身就是一份事件记录，可观测性和记忆也随之而来：Claude 开发者控制台（Claude Developer Console）提供你的智能体会话的原生可视化时间线视图，以及一种允许你深入查看任何转录的调试体验。Managed Agents 还带有记忆（Memory）和梦境（Dreaming）等功能，它们同样利用这种会话持久性。梦境是一个定期运行的过程，它审阅你的智能体会话和记忆存储、提取模式、并整理记忆，使你的智能体随时间改进。梦境在会话之间精炼记忆，以便通过读取持久化的会话日志，从反复出现的错误和用户偏好中改进。

4. 在 Anthropic 托管或自托管云容器之间的灵活性。默认情况下，借助 Managed Agents，你可以把编排和工具执行都委托给 Anthropic 托管的云容器。这让托管和扩展简单易行，提供更快的生产路径。因为在 Managed Agents 中大脑与双手解耦，双手可以存在于任何地方，包括你的虚拟私有云（VPC）内部。因此，我们也为希望控制工具执行的团队提供自托管沙箱（self-hosted sandboxes），使智能体的代码、文件系统和网络出口（network egress）永不离开他们的环境。我们还提供 MCP 隧道（MCP tunnels），让你能把 Claude 连接到运行在你私有网络内部的模型上下文协议（Model Context Protocol，MCP）服务器。因此自托管沙箱控制智能体的代码在何处执行，而 MCP 隧道控制 Anthropic 如何触达你网络中的 MCP 服务器，使你能够精确控制哪些内容留在你的边界内。

![Image 6](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298e427c7a804ea4295163_image7.png)

除这些功能外，更多能力还包括让智能体根据评分标准（rubric）给自己的工作评分的结果（outcomes）、多智能体编排、权限策略，以及 webhook。在此了解更多。

#### 客户当下如何基于 Managed Agents 构建

跨行业的客户已经在用 Claude Managed Agents 把智能体交付到生产中。以下是几个例子：

- Notion 在 Managed Agents 上运行其自定义智能体（Custom Agents）：团队直接从任务板把工作分配给 Claude，Claude 取用每项任务周边的文档、会议记录和连接的数据，完成的代码、演示文稿和网站则回到工作区供审阅。数十项任务并行运行，他们的团队描述称一个早期原型把约十二小时的工作变成了二十分钟。

- Rakuten 使用 Managed Agents 在产品、销售、营销和财务领域交付专业智能体，每个都在约一周内上线。

- Sentry 将其 Seer 调试智能体与一个编写补丁并开启 PR 的 Claude 智能体配对，由一名工程师在数周而非数月内构建完成。

- Asana 构建了能在项目内接手任务的 AI 队友（AI Teammates），Atlassian 则把开发者智能体放进了 Jira 工作流。

### 开始使用 Claude Managed Agents

我们打造 Managed Agents，是为了让通过 Claude Code 和位于 platform.claude.com 的 Claude 开发者控制台启动智能体尽可能简单。例如，控制台的快速入门让你可以从一个智能体模板出发，或用自然语言描述一个智能体，然后在几分钟内把它变成一个可以保护并部署的生产就绪智能体。

![Image 7](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298e9b866a4402a3c9bb5d_image5.png)

![Image 8](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298ebdff6d26839e052c63_image9.png)

在 Claude Code 中，默认提供 /claude-api 技能（skill），它为 Claude 提供详尽、最新的参考材料，用于在 Claude Managed Agents 上构建应用。我们强烈建议你利用它来获取设置 Managed Agents 应用的最佳实践。运行 /claude-api managed-agents-onboard 即可开始，获得一段以访谈驱动的演练，从零设置一个新的 Managed Agent。

![Image 9](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298ef3765ce453971174cd_image6.png)

### 构建托管智能体的未来

随着团队分享他们用 Managed Agents 构建的东西，我们看到他们过去花在生产基础设施上的时间，如今转向了真正让其智能体产生差异化的事：管理上下文以及为用户量身定制体验。如今，当一个新模型发布时，你更新智能体去使用它、重跑你的评估（evals）、并发布改进，而无需触碰底层架构。

我们很期待看到你构建的东西。

开始使用 Claude Managed Agents。

本文由 Anthropic 应用人工智能团队的技术成员 Gagan Bhat 和 Isabella He 撰写。他们想感谢 Hema Thanki、Jess Yan 和 Molly Vorwerck 的贡献。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| agent harness | 智能体框架 |
| composable APIs | 可组合 API |
| Messages API | Messages API |
| Claude Agent SDK | Claude Agent SDK |
| harness | 框架 |
| subagents | 子智能体 |
| primitives | 原语 |
| blast radius | 影响范围 |
| session | 会话 |
| append-only | 仅追加 |
| agent / environment / session | 智能体 / 环境 / 会话 |
| guardrails | 护栏 |
| multi-agent orchestration | 多智能体编排 |
| context anxiety | 上下文焦虑 |
| compaction | 压缩 |
| prompt injection | 提示注入 |
| vault / Vaults | 保险库 |
| envelope encryption | 信封加密 |
| time-to-first-token | 首字时延 |
| events | 事件 |
| checkpointed | 检查点保存 |
| Memory / Dreaming | 记忆 / 梦境 |
| VPC (Virtual Private Cloud) | 虚拟私有云 |
| self-hosted sandboxes | 自托管沙箱 |
| network egress | 网络出口 |
| MCP tunnels | MCP 隧道 |
| Model Context Protocol (MCP) | 模型上下文协议 |
| outcomes | 结果 |
| rubric | 评分标准 |
| Claude Developer Console | Claude 开发者控制台 |
| evals | 评估 |
| Applied AI | 应用人工智能 |
