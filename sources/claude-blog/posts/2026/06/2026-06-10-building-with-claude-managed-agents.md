---
source: claude-blog
source_url: https://claude.com/blog/building-with-claude-managed-agents
published_at: 2026-06-10
category: Agents
title_en: The evolution of agentic surfaces: building with Claude Managed Agents
title_zh: 智能体形态的演进：基于 Claude Managed Agents 构建
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 2
source_image_count: 9
---

# 智能体形态的演进：基于 Claude Managed Agents 构建

_英文标题：The evolution of agentic surfaces: building with Claude Managed Agents_

> 来源：Claude Blog，2026-06-10
> 原文链接：https://claude.com/blog/building-with-claude-managed-agents
> 分类：Agents

## 核心要点

- Anthropic 的智能体构建模块从最初的 Messages API（一次请求、一次响应），演进到 Claude Agent SDK（复用 Claude Code 框架），再到 Claude Managed Agents（托管基础设施）。
- Managed Agents 的核心架构是「将大脑与双手解耦」：调用 Claude 的框架与执行代码的沙箱分离运行，二者通过仅追加的会话日志（session）连接。
- 它围绕三大核心资源构建：智能体（agent）、环境（environment）、会话（session）。
- 解耦架构带来多重收益：凭据隔离于沙箱之外、消除沙箱开销降低延迟（首字时延 p50 约降 60%、p95 降超 90%）、可靠持久的会话支撑可观测性与记忆。
- 支持 Anthropic 托管或自托管云容器，并提供 MCP 隧道，让团队精确控制哪些内容留在自身边界内。
- 框架随模型一同演进，团队无需再为框架调优耗费精力，可专注于上下文管理与领域专长。
- Notion、Rakuten、Sentry、Asana、Atlassian 等客户已在生产中基于 Managed Agents 交付智能体。

## 正文

随着模型智能与智能体框架（agentic harness）的演进，Claude Managed Agents 让团队能够在生产环境中可靠地大规模构建和部署智能体。以下是团队选择使用它的原因和方法。

> ⌁
> As model intelligence and agentic harnesses evolve, Claude Managed Agents allows teams to build and deploy agents in production environments reliably at scale. Here’s why and how teams are using it.

让一个智能体（agent）真正投入生产，需要的不只是一个好的提示词（prompt）。智能体需要有地方运行它编写的代码、需要访问你数据的凭证、可观测的会话，以及能随用量扩展的基础设施。在应用 AI（Applied AI）团队，我们工作在产品、研究和基于 Claude 构建的客户三者的交汇处——我们反复看到同样的模式：基础设施才是区分原型与生产级智能体的关键。太多时候，团队把开发周期消耗在安全、状态管理、权限控制和工具框架（harness）调优上。

> ⌁
> Getting an agent into production takes more than a good prompt. The agent needs somewhere to run the code it writes, credentials to reach your data, observable sessions, and infrastructure that scales with usage. On the Applied AI team, we work at the intersection of product, research, and the customers building on Claude—and we see the same pattern repeatedly: infrastructure is what separates a prototype from a production agent. All too often, teams burn development cycles on security, state management, permissioning, and harness tuning.

Claude 托管智能体（Claude Managed Agents）是我们用于构建和部署生产级智能体的一套可组合 API，它将一个为性能调优的智能体工具框架（harness）与生产基础设施结合在一起，让团队能在数天而非数月内从原型走向上线。在本文中，我们将介绍 Anthropic 智能体构建模块的演进、我们为何打造 Claude 托管智能体，以及当下团队如何在生产中使用它。

> ⌁
> Claude Managed Agents , our suite of composable APIs for building and deploying production-grade agents, pairs an agent harness tuned for performance with production infrastructure, allowing teams to go from prototype to launch in days rather than months. In this post, we'll cover the evolution of Anthropic’s agentic building blocks, why we built Claude Managed Agents, and how teams are using it in production today.

### 演进智能体架构

_Evolving the agent architecture_

2023 年我们向开发者开放 Claude 时，API 刻意保持简单：输入 token，输出 token。你发送一个提示词，Claude 返回一段补全，而由你来构建框架（harness）和底层基础设施。

> ⌁
> When we opened up Claude to developers in 2023, the API was deliberately simple: tokens in, tokens out. You sent a prompt, Claude returned a completion, and you built the harness and underlying infrastructure.

这些年 API 稳步变得更丰富，但底层的约定从未改变：一次请求，一轮模型回合，由你的应用决定接下来发生什么。在很长一段时间里，这就够了。总结文档、对工单分类、改写一段文本——这些工作都能舒适地容纳在单次回合中。

> ⌁
> The API grew steadily richer over the years, but the contract underneath never changed: one request, one model turn, and your application decides what happens next. For a long time, that was enough. Summarizing a document, classifying a support ticket, rewriting a block of text—the kind of work that fits comfortably in a single turn.

然而随着时间推移，人们想要交托的任务不再适配这一模式。他们希望 Claude 把任务一路推进到底：查找信息、据此采取行动、观察发生的变化，再决定下一步怎么做。而且他们希望它能在工作本就运行的系统里运转，比如代码库、内部维基或工单系统。

> ⌁
> Over time, however, the tasks people wanted to hand off stopped fitting. They wanted Claude to carry a task all the way through, look something up, act on it, see what changed, and decide what to do next. And they wanted it to operate in the systems their work already ran on, like a codebase, internal wiki, or ticketing system.

使用 API 时，把 Claude 变成智能体意味着要自己构建循环：询问模型该做什么，运行工具，把结果反馈回去，如此往复。你要负责构建和部署智能体的脚手架，而随着模型演进，它可能需要调优。对于需要完全定制的智能体，这种方式说得通。但对于更可预测、复杂度更低的智能体工作负载，随着模型和产品演进而不断优化框架就变得繁琐。

> ⌁
> With the API, turning Claude into an agent meant building your own loop: ask the model what to do, run the tool, feed the result back, and repeat. You were responsible for building and deploying the agent scaffolding, which may need tuning as models evolve. For agents that require full customization, this approach makes sense. For agentic workloads that are more predictable and less complex, optimizing harnesses as models and products evolved became tedious.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298c28f950480f89a8dfcf_01%20_%20Messages%20API.png)

Claude Code 是我们在 2025 年推出的智能体编码工具，它让 Claude 直接与你的代码库交互，其中包含了我们自己版本的那套框架：循环、工具执行、子智能体（subagent）、上下文管理，以及使它成为高效智能体的丰富能力。开发者自然希望在各类领域里为自己的智能体也配上类似的框架机制。

> ⌁
> Claude Code , the agentic coding tool we launched in 2025 that lets Claude interact directly with your codebase, contained our own version of that harness: the loop, tool execution, subagents, context management, and rich capabilities that made it an effective agent. Developers naturally wanted similar harness machinery for their own agents across various domains.

为了让团队能在 Claude Code 框架之上构建智能体，我们发布了 Claude Agent SDK。Claude Agent SDK 为开发者提供工具，使其能在运行 Claude Code 的同一套机制上构建自己的智能体，而无需维护自制的循环。对许多团队而言，正是从这时起智能体变得切实可用：框架到手时就已针对 Claude 调优，带有基础设施原语，并且会随着 Claude Code 一同持续改进。

> ⌁
> To enable teams to build agents on top of the Claude Code harness, we released Claude Agent SDK . Claude Agent SDK gives developers tools to build their own agents on the same machinery that runs Claude Code instead of maintaining a homegrown loop. For a lot of teams, this is when agents became practical: the harness arrived already tuned for Claude with infrastructure primitives and it kept improving as Claude Code did.

不过，即便有了框架，在生产环境中部署智能体仍可能因为以下几个原因而充满挑战：

> ⌁
> Even with a harness, though, deploying agents in production environments can be challenging for several reasons:

- 托管与扩展。智能体在哪里运行，对于一项耗时数小时的任务进程能存活多久，以及当使用量增长时由什么来扩展它？
- 会话管理。智能体的历史和进度存放在哪里？一次运行能否在中断后存活并无障碍地恢复？你能否回头检查之前会话中发生过什么？
- 文件系统管理。做真正的工作意味着产出制品：编辑代码、写文件、构建输出。智能体从哪里获得可操作的工作区，而这个工作区在两次运行之间又会怎样？
- 执行隔离。Claude 写的代码必须在某处执行。如果它出错，影响范围（blast radius）有多大，又有什么边界是你在生产中真正信得过的？
- 凭据。智能体需要访问你的系统。它如何在不把专有信息暴露给所生成代码的前提下获得这种访问权限？
- 可观测性。当一个智能体自主工作一小时并做出某件意外的事情时，你能否重建它走过的每一步？

> ⌁
> - Hosting and scaling. Where does the agent run, how long can a process stay alive for a multi-hour task, and what scales it when usage grows?
> - Session management. Where does an agent's history and progress live? Can a run survive an interruption and resume unencumbered? Can you go back and inspect what happened in previous sessions?
> - Filesystem management. Doing real work means producing artifacts: editing code, writing files, building outputs. Where does the agent get a workspace to act on, and what happens to that workspace between runs?
> - Execution isolation. The code Claude writes has to execute somewhere. What's the blast radius if it's wrong, and what boundary would you actually trust in production?
> - Credentials. The agent needs access to your systems. How does it get that access without exposing proprietary information to the code it generates?
> - Observability. When an agent works autonomously for an hour and does something surprising, can you reconstruct every step it took?

有了 Agent SDK，上述生产基础设施的许多要素都由 Claude Code 的机制提供。智能体获得一个真实的文件系统来工作，会话状态被持久化到本地或外部存储，而可观测性可以通过 OpenTelemetry 导出到你已经在用的任何监控栈中。

> ⌁
> With the Agent SDK, many elements of the aforementioned production infrastructure are provided through Claude Code’s machinery. The agent gets a real filesystem to work in, session state is persisted locally or on external storage, and observability is exportable through OpenTelemetry into whatever monitoring stack you already run.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298c53aaeeee508f2b3166_02%20_%20Claude%20Agent%20SDK.png)

然而，随着团队越来越多地把智能体从本地开发迁出、投入生产，他们需要一种方式来大规模部署并配套托管基础设施。而且随着模型及其周边框架变得更先进——运行更久、执行更多代码、触及更多系统、采取更多行动——扩展、安全和沙箱化变得更加棘手。

> ⌁
> However, as teams increasingly built agents that moved out of local development into production, they needed a way to deploy them at scale and with managed infrastructure. And as models and their surrounding harnesses become more advanced–running longer, executing more code, touching more systems, and taking more actions– scaling, security, and sandboxing became more challenging.

这些障碍中有几个源自一个共同的架构选择：智能体框架往往与它所操作的文件系统运行在同一个容器里。容器必须先启动（付出启动开销），Claude 才能开始思考；智能体连同代码执行就紧挨着你的凭据；而当容器消亡时，运行也随之消亡。

> ⌁
> Several of these hurdles stem from a common architectural choice: agent harnesses often run inside the same container as the filesystem it works on. A container has to spin up (paying a startup cost) before Claude can think, the agent along with code execution lives right next to your credentials, and when the container dies, the run dies with it.

Managed Agents（托管智能体）通过把大脑与双手解耦来解决这些问题。调用 Claude 的框架与执行代码的沙箱分开运行，而会话——一份对每次模型调用、工具调用及结果的只追加（append-only）日志——把两者连接起来。Claude 可以在任何容器存在之前就开始推理，沙箱远离你的凭据，而整次运行都可以在任意时点从它的会话中重建。

> ⌁
> Managed Agents solves these problems by decoupling the brain from the hands . The harness that calls Claude runs separately from the sandbox where code executes, and the session–an append-only log of every model call, tool call, and result–connects the two. Claude can start reasoning before any container exists, the sandbox stays far away from your credentials, and a whole run can be reconstructed from its session at any point.

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298c97d4a887f2666a50b6_03%20_%20Claude%20Managed%20Agents.png)

### 何时以及为何使用 Claude 托管智能体（Managed Agents）

_When and why to use Claude Managed Agents_

使用托管智能体进行开发时，用户定义任务、工具和护栏（guardrails），由 Anthropic 在我们的基础设施上运行该智能体，并在底层处理智能体循环（agentic loop）：如何为智能体提供调用工具的执行环境、出错时如何恢复、多智能体编排等等。

> ⌁
> When building with Managed Agents, users define the task, the tools, and the guardrails, and Anthropic runs the agent on our infrastructure and handles the agentic loop underneath: how to give an agent an execution environment to call tools, how to recover when something fails, multi-agent orchestration, and more.

当运行框架（harness）没有随着模型智能的提升而演进时，智能体就会失效。在 Claude Sonnet 4.5 上，智能体在接近上下文末尾时会急于收尾，草草结束工作，而不是用尽剩余的余量——这种现象被称为"上下文焦虑"（context anxiety）。我们的应对方式是在运行框架中加入上下文重置，内置了一个假设：Claude 在接近上限时需要帮助才能保持连贯。但这个假设没能在下一个模型中延续。在 Claude Opus 4.5 上，这种行为消失了，而我们加入的那些重置反而成了额外开销。

> ⌁
> When the harness doesn’t evolve alongside model intelligence, the agent breaks down . On Claude Sonnet 4.5, an agent would rush to finish as it neared the end of its context, cutting work short rather than using the room it had left—a pattern called "context anxiety." Our fix was to add context resets to the harness, baking in an assumption that Claude needed help staying coherent near the limit. That assumption didn't survive the next model. On Claude Opus 4.5, the behavior was gone, and the resets we'd added were just overhead.

对大多数组织而言，维护运行框架属于无法让产品形成差异化的额外开销。运行框架必须针对特定的模型行为进行调优；像压缩（compaction）、工具执行和缓存这样的基础能力，在 Claude 上的工作方式与其他模型不同。借助 Claude 托管智能体，运行框架会随着模型一起演进，让团队能够专注于真正能让其智能体形成差异化的方面：上下文管理和领域专长。

> ⌁
> For most organizations, maintaining a harness is overhead that doesn't differentiate their product. Harnesses have to be tuned for certain model behaviors; primitives like compaction, tool execution, and caching works differently on Claude than other models. With Claude Managed Agents, the harness evolves alongside the model, allowing teams to focus on what will differentiate their agents: context management and domain expertise.

为了让开发者能够配置构建有效智能体所需的上下文和工具，托管智能体围绕三个主要资源构建：智能体（agents）、环境（environments）和会话（sessions）。智能体是一份配置：一个模型、一个提示词、一组工具，以及围绕它们的护栏。环境是智能体运行所处的执行上下文：沙箱容器、其网络规则，以及其中预装的软件包，可托管在我们的云上或你掌控的基础设施上。每一次运行都是一个会话，它将一个智能体与一个环境配对，并获得自己独立的沙箱实例。会话会在服务端持久化其完整的事件历史、沙箱状态和输出，因此长时间运行的工作可以暂停、干净地恢复，并在事后逐步追溯。借助托管智能体，你可以一次性定义好一个智能体和一个环境，然后随着工作负载的增长，针对同一份配置运行多个会话。

> ⌁
> To enable developers to configure the context and tools necessary to build effective agents, Managed Agents is built around three primary resources: agents, environments, and sessions. An agent is a configuration: a model, a prompt, a set of tools, and the guardrails around them. An environment is the execution context the agent runs in: the sandbox container, its networking rules, and the packages pre-installed in it, hosted on our cloud or on infrastructure you control. Each run is a session , which pairs an agent with an environment and gets its own isolated sandbox instance. Sessions persist their full event history, sandbox state, and outputs server-side, so long-running work can pause, resume cleanly, and be traced step by step after the fact. With Managed Agents, you can define an agent and an environment once, then run many sessions against the same configuration as your workload grows.

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a29a18bb07e245f8389acb9_04%20_%20Agents_%20environments_%20sessions%20(2).png)

### 在托管智能体（Managed Agents）上构建生产级与规模化应用

_Building for production and scale on Managed Agents_

在应用 AI（Applied AI）团队中，我们见证了智能体在 Anthropic 内部及客户系统中从原型走向生产，覆盖编程、金融、客服、法律等十多个领域。这让我们清楚地看到，是什么把一个演示和一个生产就绪的智能体区分开来，以及团队常常卡在哪里。

> ⌁
> Within Applied AI, we see agents go from prototype to production both inside Anthropic and across our customers’ systems, across coding, finance, support, legal, and a dozen other domains. This gives us a clear view of what separates a demo from a production-ready agent and where teams often get stuck.

下面，我们分享在 Claude 托管智能体这类托管服务上构建的几个最常见理由：

> ⌁
> Below, we share the most common reasons to build on a managed service like Claude Managed Agents:

1. 凭证被隔离在沙盒之外。当所有东西都在一个容器中运行时，Claude 生成的代码就紧挨着你的凭证，因此提示注入（prompt injection）可能诱导模型读取自身环境，从而泄露令牌。我们可以通过在同一容器内设置强健的护栏来防范这一点，但将架构解耦能带来更安全的方式，即把凭证完全排除在沙盒之外。用于 MCP、命令行工具（CLI）、GitHub 仓库等工具的令牌存放在一个独立的保险库（Vault）中，由代理（proxy）按需获取并解密。托管智能体开箱即用地提供保险库来处理凭证，这样你无需运行自己的密钥存储、无需在每次调用时传输令牌，也不会弄不清智能体是代表哪位最终用户在行动。保险库中的凭证在存储前会经过信封加密（envelope encryption）保护，检索时需要一个经过签名的请求令牌进行验证。

> ⌁
> 1. Credentials are kept out of the sandbox. When everything runs in one container, the code Claude generates sits right next to your credentials, so prompt injections could lead the model to leak a token by convincing the model to read its own environment. We can protect against this by setting up robust guardrails within the same container, but decoupling the architecture enables a much more secure approach by keeping credentials out of the sandbox entirely. Tokens for tools like MCPs, CLIs, and GitHub repos live in a separate vault, and a proxy fetches them and decrypts them only on demand. Managed Agents provides Vaults that handle credentials out-of-the-box, so you don’t need to run your own secret store, transmit tokens on every call, or lose track of which end user an agent acted on behalf of. Vault credentials are protected with envelope encryption before storage, and retrieval requires a signed request token for verification.

![Image 5](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a29a19cebb4eb7adac0a8ec_05%20_%20Managed%20Agents%20runtime%20(1).png)

2. 消除沙盒开销带来的更低延迟。延迟是许多企业团队最关心的指标之一，因为用户在等待 Claude 响应时感受非常明显。没有托管智能体架构时，每个会话都必须启动一个容器，即便是那些智能体只需思考、从不运行工具的会话。这段启动时间被白白浪费，用户会把它感受为首次响应前的延迟。有了托管智能体，Claude 会立即开始推理，而环境则并行启动，那些从不运行工具的会话则完全跳过容器。这意味着用户无需等待容器启动就能看到首个令牌，而当智能体需要运行某些东西时，环境已经就绪。在我们的测试中，这把首个令牌出现时间（time-to-first-token）在中位数情况（p50）下削减了约 60%，在最慢情况（p95）下削减了超过 90%。

> ⌁
> 2. Lower latency from eliminated sandbox overhead. Latency is a metric that is top-of-mind for many enterprise teams, since users acutely feel when they’re waiting for Claude to respond. Without the Managed Agents architecture, a container has to be spun up for every session, even the ones where the agent only needs to think and never runs a tool. That setup time is wasted, and the user feels it as a delay before the first response. With Managed Agents, Claude begins reasoning immediately while the environment spins up in parallel, and sessions that never run a tool skip the container entirely. This means the user sees the first token without waiting on container startup, and the environment is ready by the time the agent needs to run something. In our testing, that cut the time-to-first-token by roughly 60% in the median case (p50) and by over 90% in the slowest cases (p95).

3. 可靠、持久的会话，支撑会话管理、可观测性和记忆。托管智能体不以请求/响应的方式思考，而是以事件（event）的方式思考。一个会话是一段持续的事件流：每一次模型调用、工具调用和结果，都会被追加到一份存活于智能体运行进程之外的日志中。借助这一架构，智能体工作时你可以随着事件流入获得实时更新，并且之后能恢复任意会话，无需管理数据库或保存点。除非你删除会话，否则历史会在各次交互之间得到保留；当会话进入闲置状态时，其容器会被检查点保存（checkpoint），使你能从暂停处干净地继续。而由于整个运行本身就是一份事件记录，可观测性和记忆也随之而来：Claude 开发者控制台（Claude Developer Console）提供原生的可视化时间线视图来展示你的智能体会话，以及一种可深入查看任意会话记录的调试体验。托管智能体还附带记忆（Memory）和梦境（Dreaming）等功能，它们同样利用了这种会话持久性。梦境是一个定时进程，会审阅你的智能体会话和记忆存储，提取模式，并整理记忆，使你的智能体随时间不断改进。梦境在会话之间精炼记忆，从而能通过读取持久的会话日志，从反复出现的错误和用户偏好中改进。

> ⌁
> 3. Reliable, persistent sessions that enable session management, observability, and memory. Instead of request/response, Managed Agents thinks in terms of events. A session is an ongoing stream of events: every model call, tool call, and result, are appended to a log that lives outside the process running the agent. With this architecture, you get real-time updates as events stream in while the agent works, and you can resume any session later with no database or save-points to manage. History is preserved between interactions unless you delete the session, and when a session goes idle its container is checkpointed so you can pick up cleanly from where it paused. And because the whole run is already a record of events, observability and memory come with it: the Claude Developer Console offers a native visual timeline view of your agent sessions, and a debugging experience that allows you to examine any transcript in-depth. Managed Agents also comes with features like Memory and Dreaming that also use this session durability. Dreaming is a scheduled process that reviews your agent sessions and memory stores, extracts patterns, and curates memories so your agents improve over time. Dreaming refines memory between sessions so that it can improve from recurring mistakes and user preferences by reading from the persistent session logs.

4. 在 Anthropic 托管或自托管云容器之间的灵活性。默认情况下，使用托管智能体，你可以把编排和工具执行都委托给 Anthropic 托管的云容器。这让托管和扩展变得简单轻松，提供一条更快的生产化路径。由于在托管智能体中"大脑"与"双手"是解耦的，"双手"可以存在于任何地方，包括你的虚拟私有云（VPC）内部。因此，我们也为希望掌控工具执行的团队提供自托管沙盒，使智能体的代码、文件系统和网络出口流量永远不离开他们的环境。我们还提供 MCP 隧道（MCP tunnel），让你能把 Claude 连接到运行在你私有网络内的模型上下文协议（Model Context Protocol，MCP）服务器。因此，自托管沙盒控制智能体代码在何处执行，而 MCP 隧道控制 Anthropic 如何访问你网络中的 MCP 服务器，让你能够精确控制哪些东西留在你的边界之内。

> ⌁
> 4. Flexibility in Anthropic-managed or self-hosted cloud containers. By default, with Managed Agents, you can delegate both orchestration and tool execution to Anthropic-managed cloud containers. This makes hosting and scaling simple and easy, delivering a faster path to production. Because the brain is decoupled from the hands in Managed Agents, the hands can live anywhere, including inside your Virtual Private Cloud (VPC). Thus, we also offer self-hosted sandboxes for teams that want control over tool execution, so the agent’s code, filesystem, and network egress never leave their environment. We also provide MCP tunnels , which let you connect Claude to Model Context Protocol (MCP) servers that run inside your private network. So self-hosted sandboxes control where the agent’s code executes , and MCP tunnels control how Anthropic reaches MCP servers in your network , giving you the ability to control exactly what stays inside your boundary.

![Image 6](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298e427c7a804ea4295163_image7.png)

除这些功能外，其他能力还包括：让智能体依据评分标准（rubric）给自己的工作打分的"成果"（outcomes）功能、多智能体编排、权限策略以及网络钩子（webhook）。点此了解更多。

> ⌁
> Beyond these features, additional capabilities include outcomes that let an agent grade its own work against a rubric, multiagent orchestration, permission policies, and webhooks. Learn more here .

#### 客户当下如何在托管智能体上构建

_How customers are building on Managed Agents today_

在各行各业，客户已经在用 Claude 托管智能体把智能体投入生产。以下是几个例子：

> ⌁
> Across industries, customers are already shipping agents in production with Claude Managed Agents. Here are a few examples:

- Notion 在托管智能体（Managed Agents）上运行其自定义智能体（Custom Agents）：团队直接从任务看板把工作分配给 Claude，Claude 围绕每项任务获取相关文档、会议记录和连接的数据，完成的代码、演示文稿和网站会回到工作区供审阅。数十项任务并行运行，他们团队描述早期原型把大约十二小时的工作变成了二十分钟。
- 乐天（Rakuten）使用托管智能体在产品、销售、营销和财务部门推出了专业智能体，每个都在约一周内上线。
- Sentry 将其 Seer 调试智能体与一个编写补丁并提交拉取请求（PR）的 Claude 智能体配对，由单个工程师在数周内（而非数月）完成构建。
- Asana 构建了能在项目内接手任务的 AI 队友（AI Teammates），Atlassian 则把开发者智能体加入了 Jira 工作流。

> ⌁
> - Notion runs its Custom Agents on Managed Agents: teams assign work to Claude straight from a task board, Claude picks up the docs, meeting notes, and connected data around each task, and the finished code, decks, and sites land back in the workspace for review. Dozens of tasks run in parallel, and their team has described an early prototype turning roughly twelve hours of work into twenty minutes.
> - Rakuten used Managed Agents to ship specialist agents across product, sales, marketing, and finance, each live within about a week.
> - Sentry paired its Seer debugging agent with a Claude agent that writes the patch and opens the PR, built in weeks instead of months by a single engineer.
> - Asana built AI Teammates that pick up tasks inside projects, and Atlassian put developer agents into Jira workflows.

### Claude 托管智能体（Managed Agents）入门

_Getting started with Claude Managed Agents_

我们打造托管智能体，是为了让你能尽可能轻松地通过 Claude Code 和 platform.claude.com 上的 Claude 开发者控制台（Developer Console）启动智能体。例如，控制台的快速上手功能让你可以从智能体模板开始，或用自然语言描述一个智能体，然后在几分钟内将其变成可以保护并部署的生产就绪智能体。

> ⌁
> We built Managed Agents to make it as easy as possible to spin up agents through Claude Code and the Claude Developer Console at platform.claude.com . The Console’s quickstart, for example, lets you start from an agent template or describe an agent in plain language, then turn it into a production-ready agent you can secure and deploy in minutes.

![Image 7](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298e9b866a4402a3c9bb5d_image5.png)

![Image 8](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298ebdff6d26839e052c63_image9.png)

在 Claude Code 中，默认提供 /claude-api 技能（skill），它为 Claude 提供了关于在 Claude 托管智能体上构建应用的详细、最新的参考资料。我们强烈建议你利用它来获取设置托管智能体应用的最佳实践。运行 /claude-api managed-agents-onboard 即可开始，这是一个以访谈方式引导你从零搭建新托管智能体的演练。

> ⌁
> In Claude Code, the /claude-api skill is provided by default and provides Claude with detailed, up-to-date reference material for building applications on Claude Managed Agents. We highly recommend that you utilize it for the best practices on setting up your Managed Agents application. Get started by running /claude-api managed-agents-onboard for an interview-driven walkthrough for setting up a new Managed Agent from scratch.

![Image 9](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a298ef3765ce453971174cd_image6.png)

### 构建托管智能体的未来

_The future of building managed agents_

随着各团队分享他们用托管智能体（Managed Agents）构建的成果，我们发现，过去花在生产基础设施上的时间，如今转向了真正让智能体与众不同的环节：管理上下文，以及为用户量身定制体验。现在，当新模型发布时，你只需更新智能体以使用它，重新运行评估，然后交付改进，而无需触碰底层架构。

> ⌁
> As teams share what they’re building with Managed Agents, we see that the time they used to spend on production infrastructure now goes to what differentiates their agents: managing context and tailoring the experience to users. Now, when a new model comes out, you update your agent to use it, rerun your evals, and ship the improvement without touching the architecture underneath.

我们期待看到你的成果。

> ⌁
> We’re excited to see what you build.

立即开始使用 Claude 托管智能体。

> ⌁
> Get started with Claude Managed Agents.

本文由 Anthropic 应用 AI 团队的技术成员 Gagan Bhat 和 Isabella He 撰写。他们要感谢 Hema Thanki、Jess Yan 和 Molly Vorwerck 的贡献。

> ⌁
> This article was written by Gagan Bhat and Isabella He, Members of Technical Staff on Anthropic’s Applied AI team. They'd like to thank Hema Thanki, Jess Yan, and Molly Vorwerck for their contributions.

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
