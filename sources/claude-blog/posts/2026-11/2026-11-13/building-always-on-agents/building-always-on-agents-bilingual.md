# 构建全天候运行的智能体

> Building always-on agents

> 来源：Claude Blog / Anthropic，2026-11-13
> 原文链接：https://claude.com/resources/articles/building-always-on-agents
> 分类：AI 工程 / 智能体架构

## 核心要点

- 常驻智能体是有状态且主动的，会跨会话管理上下文并在无直接监督时采取行动，近期模型判断力的提升和长周期任务成本的下降使其更切实可行。
- 所谓“永远在线”实为用户体验描述，智能体大部分时间处于休眠，被事件唤醒后执行一次运行，在会话中完成任务并保存信息后再次休眠。
- 事件收件箱以持久化事件列表、写入处理程序和后台工作进程组成，用于避免并发事件引发竞争运行或崩溃导致事件丢失。
- 收件箱实现的最佳实践包括处理程序快速确认事件、以收件箱作为唯一可信来源、同一收件箱只保留一个活跃 worker，以及对待处理事件进行批量合并。
- 定时器分为智能体为自己设定的跟进和按固定节奏重复的日程，由调度器定期轮询独立存储，将到期任务作为事件写入收件箱并唤醒工作进程。
- 记忆应存放在独立的持久化存储中，只保存智能体无法再次查到的内容，主要包括用户指令、用户笔记、历史消息和任务进度，并可通过“做梦”机制整理过时条目。
- 每次运行都要加载系统提示词、工具定义和记忆文件等初始上下文，应保持精简并配合提示词缓存，会话过长时可压缩旧消息或开启新会话。
- 权限是风险最集中的环节，可通过在智能体环境外注入凭据的代理、用分类器审查高风险操作的自动模式，以及等待用户输入的延迟工具调用来管理。
- 常驻智能体的大部分工作在后台完成，一次运行可能以发送消息、无需发送或延迟工具调用结束，正式的发件箱与分发器可用于控制发送节奏和错误恢复。
- 智能体发送消息的数量需要通过评测调校，宜从保持安静开始，随时间逐步赢得用户更多关注。

## 正文

过去几个月里，我们看到常驻运行（always-on）的智能体再度兴起。

> Over the past few months, we’ve seen a resurgence of always-on agents.

常驻智能体（always-on agents）是有状态且主动的，这意味着它们会跨会话管理上下文，并在没有直接监督的情况下采取行动。从底层来看，它们与其他智能体运行在相同的[核心循环](https://www.anthropic.com/research/building-effective-agents)之上。区别在于外围架构：这套架构由一系列原语构建而成，这些原语控制着智能体何时被唤醒、哪些内容会在多次运行之间延续，以及它们的工作成果如何触达用户。

> Always-on agents are stateful and proactive, meaning they manage context across sessions and take actions without direct supervision. Underneath, they run on the same [core loop](https://www.anthropic.com/research/building-effective-agents) as other agents. The difference is the surrounding architecture, which is built from primitives that control when the agents wake up, what carries over between runs, and how their work reaches the user.

这一复兴在很大程度上得益于近期模型的进步，使常驻运行的智能体变得更加切实可行。首先，最新模型具备更好的判断力：它们在理解用户意图、把握何时向用户确认方面更加可靠。其次，智能的成本正在下降，其中长周期任务受益最大。例如，在[一项长周期编程基准测试](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence)中，Opus 5.5 每解决一个任务的成本比 Opus 5 低 78%，而在典型工作负载上则低 40%。

> The resurgence is largely due to recent model advancements, which have made always-on agents more practical to run. First, the latest models have better judgment: they’re more reliable at understanding user intent and knowing when to check in. Second, intelligence is becoming cheaper, with long-horizon tasks benefiting the most. For example, on [one long-horizon coding benchmark](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence), Opus 5.5 cost 78% less per solved task than Opus 5, compared with 40% less on typical workloads.

客户开始询问我们，如何将这类体验集成到他们自己的产品中。一些公司希望让现有的智能体变得更加主动，而另一些公司则打算从零开始构建这样的智能体。

> Customers have started to ask us how to integrate this type of experience into their own products. Some companies want to make their existing agents more proactive, while others are looking to build them from the ground up.

本文将拆解常驻智能体背后的基础原语，并逐步讲解它们如何协同组合在一起。

> This post breaks down the primitives behind always-on agents and walks through how they fit together.

#### 常驻智能体背后的循环

> The cycle behind the always-on agent

所谓“永远在线”的智能体，其实并非真的“永远在线”。这只是对用户体验的一种描述。

> An always-on agent is not actually “always on.” This is just a description of the user experience.

实际上，智能体大部分时间都处于休眠状态，只是定期醒来执行工作。每一段工作称为一次**运行（run）**：智能体接收一个事件，完成其任务，然后保存有关所发生情况的信息。运行在一个**会话（session）**中进行，会话即由消息和工具调用构成的记录。运行结束后，智能体重新进入休眠，如此循环往复，无限持续。

> In reality, the agent spends most of its time asleep, waking up periodically to do work. Each stretch of work is called a **run**: the agent receives an event, completes its task, and then saves information about what happened. A run works inside a **session**, which is the transcript of messages and tool calls. Once the run is finished, the agent goes back to sleep, and the cycle repeats indefinitely.

![Animated diagram of an always-on agent’s timeline: long stretches asleep with no tokens spent, broken by brief runs. Each run has four steps: an event arrives, a session starts, the agent loop runs, and the run writes back to stored state that carries over between runs.](https://assets.claude.com/5dc803bf06d6e92e4aecae762da096626e2fa9ec.gif)

#### 核心原语

> The core primitives

常驻智能体的外围架构包含五个核心原语：事件收件箱、定时器、记忆、权限和发件箱。下面逐一来看。

> The surrounding architecture of an always-on agent has five core primitives: an event inbox, timers, memory, permissions, and an outbox. Let’s take a look at each.

##### 事件收件箱

> Event inbox

大多数 AI 智能体只在用户发送消息时才会运行。相比之下，始终在线的智能体可以由多种类型的事件触发，包括 webhook、定时任务和后台作业。

> Most AI agents only run when the user sends a message. In contrast, always-on agents can be triggered by many types of events, including webhooks, scheduled tasks, and background jobs.

一种很有吸引力的做法是让每个事件源直接调用智能体，但这会带来几种失败模式。例如，两个同时到达的事件可能会启动相互竞争的运行，而一次崩溃则可能导致某个事件完全丢失。

> One tempting approach is to have each event source call the agent directly, but that has a few failure modes. For example, two events arriving at the same time can start competing runs, and a crash can lose an event entirely.

这正是事件收件箱发挥作用的地方。各个来源不再直接调用智能体，而是将事件发送到收件箱，再由工作进程从中取出处理。

> This is where the event inbox comes in. Instead of calling the agent, every source sends an event to an inbox, where a worker picks it up.

最简单的版本包含三个组成部分：

> The simplest version has three components:

- 一份持久化的事件列表，通常是一张数据库表；
- 一个处理程序（通常是 HTTP 端点），负责将事件写入列表；以及
- 一个从该列表中读取数据的工作进程，通常是一个后台服务。

> • A durable list of events, usually a database table;
> • A handler, usually an HTTP endpoint, that writes events to the list; and
> • A worker, usually a background service, that reads from the list.

收件箱应跟踪每个事件的状态，并可根据来源提供的唯一标识符对事件进行去重。关系型数据库很适合用作收件箱，每个事件都作为新行追加写入。我们建议从每个用户一个收件箱起步，但如果需要更高的并行度，也可以进一步拆分。

> The inbox should track the status of each event, and events can be deduplicated based on unique identifiers from the source. A relational database works well for the inbox, with every event appended as a new row. We recommend starting with one inbox per user, but you can split this further if you need more parallelism.

![Diagram of the event inbox. A handler (an HTTP endpoint) writes each event to the inbox, a database table that tracks status and drops duplicates, and wakes the worker. The worker reads what’s pending, starts the run, waits for it to finish, and marks the events done.](https://assets.claude.com/bb08543a505cea3a24c88c718ceec4405e9c0a79.png)

当有新事件到达时，处理程序会将该事件写入收件箱并唤醒工作进程。工作进程读取所有待处理的内容并启动一次运行。延续先前工作的事件（例如用户的回复）会恢复已有的会话，而其他所有事件都会启动一个新会话。

> When a new event comes in, the handler writes the event to the inbox and wakes the worker. The worker reads whatever is pending and starts a run. Events that continue earlier work, such as a reply from the user, resume an existing session, while everything else starts a new session.

接下来，worker 将这些事件传递给智能体循环，等待运行结束，并将相应的事件标记为已完成。具体实现可能会比较棘手，因此这里给出几条最佳实践：

> From there, the worker passes the events to the agent loop, waits for the run to finish, and marks the corresponding events as done. The implementation details can get tricky, so here are a few best practices:

- **处理程序应快速确认事件**。某些事件源（例如 webhook 提供方）会将响应缓慢视为失败。处理程序仍可执行轻量级检查，但任何更深入的验证（例如检查提示注入）都应在运行期间完成。
- **收件箱应当作为唯一可信来源**。工作进程被唤醒时，应首先从收件箱拉取最新事件。这样一来，即使工作进程在运行中途崩溃，新的工作进程也能接手同一事件并重试。
- **一个收件箱同一时间只应有一个活跃的 worker**。这可以防止两次运行重复工作或相互覆盖。当运行过程中出现新事件时，你可以将其推迟到下一次运行，将其并入当前运行，或者中断并重新启动。
- **worker 应当将待处理的事件合并批处理。**例如，如果用户连续发送了多条消息，worker 可以将它们合并为一次运行，这样 agent 只需回复一次。

> • **The handler should acknowledge events quickly**. Some sources, such as webhook providers, treat slow responses as failures. The handler can still run lightweight checks, but any deeper verification, such as checking for prompt injection, should be done during the run.
> • **The inbox should be the source of truth**. When the worker is woken up, it should pull the latest events from the inbox first. That way, if the worker dies mid-run, a new one can pick up the same event and retry.
> • **An inbox should only have one active worker at a time**. This prevents two runs from duplicating work or overwriting each other. When a new event shows up mid-run, you can either push it to the next run, fold it into the current run, or interrupt and restart.
> • **The worker should batch pending events together.** For example, if the user sends several messages in a row, the worker can merge them into a single run, so the agent only needs to reply once.

##### 定时器

> Timers

计时器与事件收件箱相结合，使常驻智能体能够主动采取行动。计时器通常分为两类：跟进（follow-up）和日程（schedule）。跟进是智能体为自己设定的截止时间，例如检查某条回复的进展。而日程则是按已知节奏重复执行的任务，例如每日简报。

> Together with the event inbox, timers let always-on agents be proactive. Timers generally fall into one of two categories: follow-ups or schedules. A follow-up is a deadline that the agent sets for itself, such as checking in on a reply. A schedule, on the other hand, is a recurring task that happens on a known cadence, such as a daily newsletter.

定时器存放在独立的持久化存储中（通常是另一张数据库表），与收件箱分开。收件箱只应存放已准备好被处理的事件。后续任务（follow-up）和调度计划（schedule）可以共用相似的模式（schema），但调度计划还需要额外记录其重复规则。

> Timers live in their own durable store, usually another database table, separate from the inbox. The inbox should only hold events that are ready to be worked on. A follow-up and a schedule can share a similar schema, but a schedule needs to track its recurrence as well.

![Diagram of timers. A run sets a timer in a database table, either a follow-up set by the agent or a schedule set by the user. A scheduler finds what’s due and adds an event to the event inbox, which starts the next run.](https://assets.claude.com/c16694e6d979a2ace84d03da0544297b7245c0a8.png)

定时器本身不会启动运行。相反，由调度器（通常是一个后台服务）以固定的时间间隔轮询存储，并触发所有已到期的任务。每次轮询时，调度器会：

> A timer doesn’t initiate a run on its own. Instead, a scheduler, usually a background service, polls the store at a fixed interval and fires anything that’s due. On each pass, the scheduler:

1. 扫描存储，找出已到期的定时器。
2. 根据每个计时器的类别对其进行更新。
   1. 后续事项应标记为已完成。
   2. 调度任务的到期时间应更新为下一次触发的时间。
3. 将一个事件添加到收件箱并唤醒工作线程。

> 1\. Scans the store and finds timers that are due.

> 2\. Updates each timer based on its category.

> 1\. A follow-up should be marked as done.

> 2\. A schedule should get its due time updated to the next occurrence.

> 3\. Adds an event to the inbox and wakes the worker.

对于调度器，你既可以自行构建服务，也可以使用持久化执行引擎。

> For the scheduler, you can either build your own service or use a durable execution engine.

##### 记忆

> Memory

常驻智能体在许多彼此割裂的运行中工作，并依靠记忆来保持连续性。

> Always-on agents work across many disjointed runs and rely on memory to maintain continuity.

与事件收件箱和定时器类似，记忆也应当拥有自己的存储。在我们的产品中，例如 Claude Code 的[自动记忆](https://code.claude.com/docs/en/memory)和 Messages API 的[记忆工具](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)，这一存储被实现为一个文件目录。对于常驻运行的智能体，这些目录应映射到持久化存储，通常是数据库或对象存储。这样，记忆的生命周期就能长于工作进程。

> Similar to the event inbox and timers, memory should have its own store. In our products, such as Claude Code’s [auto memory](https://code.claude.com/docs/en/memory) and the Messages API’s [memory tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool), this is implemented as a directory of files. For an always-on agent, the directories should map to durable storage, usually a database or an object store. This way memories outlive the worker.

经验法则是，记忆中只应保存智能体无法再次查找到的内容。如果某些信息已经存放在其他系统中（例如问题跟踪系统），你应当改为保存一个指向它的指针。以下是常驻智能体应当存储的各类记忆的分类说明：

> As a rule of thumb, memory should only hold what the agent can’t look up again. If something already lives in another system, such as an issue tracker, you should save a pointer instead. Here is a breakdown of the types of memory an always-on agent should store:

- **用户指令：**用户关于智能体行为的任何指令都应保存在单独的文件中，并在每次运行开始时加载。用户不会一直在场引导智能体，因此这些指令必须在多次运行之间延续下去。
- **用户笔记：**智能体应保存它对用户的了解，例如用户的角色、偏好，或用户给出的任何纠正。你可以从单个文件开始，随着笔记增多再改为多个小文件。在后一种情况下，每次运行开始时只加载一个索引，但智能体在需要更多细节时，可以将单个文件拉入上下文。
- **历史消息：** 代理应当记录它已经告诉过用户的内容，以免重复。它可以把这些内容存储在一个单独的文件中，在每次运行开始时加载；也可以让 worker 加载代理与用户之间最近的几条消息。
- **任务进度：**对于每个进行中的任务，智能体都应维护一个进度文件，记录已完成的工作和剩余的工作。这样，任何新的运行都可以读取该文件，并从上一次运行中断的地方继续。与用户笔记类似，每次运行开始时只加载索引，但智能体在需要更多细节时，可以将具体文件拉入上下文。

> • **User instructions:** Any instructions from the user about agent behavior should be saved in their own file and loaded at the start of every run. The user won’t always be around to steer the agent, so the instructions have to carry over between runs.
> • **User notes:** The agent should save what it’s learned about the user, such as their role, their preferences, or any corrections they’ve given. You can start with one file and move to several small files as the notes grow. In the latter case, only an index is loaded at the start of each run, but the agent can pull the individual files into context when it needs more details.
> • **Past messages:** The agent should keep track of what it’s already told the user so nothing is repeated. It can either store this in a separate file that’s loaded at the start of each run, or have the worker load the agent’s last few messages with the user.
> • **Task progress:** For each ongoing task, the agent should keep a progress file that covers what’s been done and what’s left. Any new run can then read that file and pick up where the previous run left off. Similar to user notes, only an index is loaded at the start of each run, but the agent can pull the individual files into context when it needs more details.

下图展示了一种示例配置。

> The diagram below shows one example setup.

![Diagram of an example memory setup as a directory of files. instructions.md, index.md, and reported.md are loaded at the start of every run, while the notes/ and progress/ folders are read when needed. The agent writes to memory during the run.](https://assets.claude.com/e5d209d7ef9b3455dec8a27b777dc12bdf806699.png)

以上内容描述的都是在运行过程中保存的记忆。你还可以加入“做梦”（dreaming）机制，它会回顾过去的会话来整理记忆。做梦机制可以替换过时的条目，并发现只有跨越多次运行才会显现的模式。如果你有兴趣深入了解，我们的[关于智能体记忆的文章](https://www.anthropic.com/research/components-of-agent-memory)对此有更详细的介绍。

> All of the above describes memory that’s saved during a run. You can also add dreaming, which reviews past sessions to curate memories. Dreaming can replace outdated entries and find patterns that only show up across many runs. If you’re interested in learning more, our [post on agent memory](https://www.anthropic.com/research/components-of-agent-memory) covers this in more detail.

###### 上下文窗口内部

> Inside the context window

在开始任何工作之前，智能体会加载系统提示词、工具定义和记忆文件。每次运行都会包含这部分初始上下文“开销”，因此我们建议保持其精简，并使用[提示词缓存](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)来降低成本。

> Before doing any work, the agent loads the system prompt, tool definitions, and memory files. This initial context “overhead” is included in every run, so we recommend keeping it lean and using [prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) to lower costs.

新会话启动时只包含这部分上下文开销以及触发本次运行的事件。而已有会话则会带回其先前运行中的消息和工具调用。

> A new session starts only with this context overhead and the events that triggered the run. An existing session, on the other hand, brings back the messages and tool calls from its earlier runs.

如果会话变得过长，你可以[压缩较早的消息](https://platform.claude.com/docs/en/build-with-claude/compaction)，或者开启一个新会话。这两种方式都会丢失细节，因此任何需要持久保留的内容都应在过程中随时保存到记忆中。

> If a session becomes too long, you can either [compact the older messages](https://platform.claude.com/docs/en/build-with-claude/compaction) or start a new session. Both approaches lose detail, so anything that needs to persist should be saved to memory along the way.

![Animated chart of context used over time. A fixed band for the system prompt, tools, and memory is present on every run. An existing session brings back its whole transcript and grows until compaction turns the older transcript into a summary.](https://assets.claude.com/48757f0a147acfe841c943674c6214d34ed4405a.gif)

##### 权限

> Permissions

权限是常驻型智能体风险最集中的环节。一次运行持有用户的访问权限，并且按设计在无人值守的状态下运行。对于每一次工具调用，智能体都需要决定是自行继续执行、予以阻止，还是等待批准。

> Permissions are where always-on agents carry the most risk. A run holds the user’s access and, by design, operates unattended. For each tool call, the agent needs to decide whether to proceed on its own, block it, or wait for approval.

权限相关的组件与其他智能体所用的组件相同：

> The components for permissions are the same ones other agents use:

- **凭据存储：**常驻智能体通常需要密码或访问令牌等敏感的用户凭据才能发挥作用。[推荐的模式](https://code.claude.com/docs/en/agent-sdk/secure-deployment#credential-management)是在智能体环境之外设置一个代理，由它为外发请求添加凭据。智能体发送的请求不携带凭据，代理在转发之前注入真实凭据。
- **自动模式：**一个始终在线的智能体应当能够在无需用户持续输入的情况下工作。我们已经在 Claude Code 中通过[自动模式](https://www.anthropic.com/research/claude-code-auto-mode)解决过这一问题的某种形式。自动模式使用分类器审查较高风险的操作，并阻止被其识别为危险的操作，从而让 Claude 能够找到更安全的方案。不过，对于最重要的决策，仍然需要用户进行审查。
- **延迟的工具调用：**在 Claude Code 中，[hook 可以延迟一次工具调用](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)，并等待用户提供额外输入。同样的模式也适用于常驻智能体，它们在执行某些操作之前可能需要澄清或审批。当一次调用被延迟时，本次运行结束，会话在调用中途被保存。该请求会展示给用户（例如，通过使用 [MCP Apps](https://modelcontextprotocol.io/extensions/apps/overview) 构建的交互式卡片），用户的回答则作为一个事件回到收件箱中。该事件会启动一次新的运行，携带用户的输入恢复已保存的会话。在被延迟的调用等待响应期间，worker 可以处理其他事件，因此智能体不会被阻塞。

> • **Credential store:** Always-on agents often need sensitive user credentials like passwords or access tokens to be useful. The [recommended pattern](https://code.claude.com/docs/en/agent-sdk/secure-deployment#credential-management) is a proxy outside the agent’s environment that adds credentials to outgoing requests. The agent sends requests without credentials, and the proxy injects the real credentials before forwarding.
> • **Auto mode:** An always-on agent should be able to work without constant user input. We’ve already tackled a version of this problem with [auto mode](https://www.anthropic.com/research/claude-code-auto-mode) in Claude Code. Auto mode uses classifiers to review higher-risk actions and block the ones they identify as dangerous so Claude can find a safer approach. User review, however, is still necessary for the most important decisions.
> • **Deferred tool calls:** In Claude Code, [a hook can defer a tool call](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later) and wait for additional input from the user. The same pattern applies to always-on agents, which may need clarification or approval before taking certain actions. When a call is deferred, the run ends and the session is saved mid-call. The request is shown to the user (e.g., through an interactive card built with [MCP Apps](https://modelcontextprotocol.io/extensions/apps/overview)), and their answer comes back as an event in the inbox. That event starts a new run, which resumes the saved session with the user’s input. While the deferred call waits for a response, the worker can pick up other events, so the agent isn’t blocked.

##### 发件箱

> Outbox

对于大多数 AI 智能体，响应会在生成的同时以流式方式传输给用户，这样用户就能实时跟随 Claude 推理问题、调用工具并撰写答案的过程。

> With most AI agents, the response is streamed to the user as it’s generated, so they can follow along as Claude reasons through the problem, calls tools, and writes its answer.

相比之下，常驻型智能体的大部分工作都在后台完成。用户得到的是结果和少量细节，而不是完整的逐步分解过程。

> Always-on agents, on the other hand, do most of their work in the background. The user gets the outcome and a few details, rather than the entire step-by-step breakdown.

![Diagram of the outbox. A run ends with nothing to say, a send tool call, or a deferred tool call that asks the user. Messages go to the outbox, a database table, and a dispatcher delivers them to the user. A deferred request can go through the outbox or be shown in your own interface.](https://assets.claude.com/700b5f3a446f22493c0307ec65751b6b2f82ccb7.png)

一次运行可能以以下三种方式之一结束：

> A run can end in one of three ways:

- 代理将一条消息发送到发件箱，
- 智能体判断无需发送任何内容，或者
- 智能体通过延迟工具调用来请求权限或获取额外输入。

> • The agent sends a message to the outbox,
> • The agent decides that nothing needs to be sent, or
> • The agent uses a deferred tool call to request permission or additional input.

大多数常驻智能体只需一个“send”工具，把消息直接发送给用户即可。只有当你希望控制智能体发送消息的节奏，或让智能体能够从错误中恢复时，才需要一个正式的发件箱。

> Most always-on agents can get by with a “send” tool that delivers the message directly to the user. You only need a formal outbox when you want to pace your agent’s messages or allow your agent to recover from errors.

发件箱（outbox）是一张独立的待发送消息表，与事件收件箱相对应。此外还有一个分发器（dispatcher），通常是一个后台服务，其作用与工作器（worker）相对应。分发器读取待处理的消息，决定要投递哪些消息，并将其发送给用户。来自延迟工具调用的请求既可以经由发件箱发送，也可以直接在界面中展示。

> The outbox is a separate table of outgoing messages, analogous to the event inbox. There’s also a dispatcher, usually a background service, that’s analogous to the worker. The dispatcher reads the pending messages, decides what to deliver, and sends those to the user. A request from a deferred tool call can either go through the outbox or be shown directly in the interface.

除了消息投递之外，调校智能体发送消息的数量也很重要。发送过多消息的智能体会显得嘈杂，而发送太少的智能体则会遗漏用户需要知道的信息。我们建议构建评测来找到合适的平衡点。在实践中，智能体最好一开始保持安静，然后随着时间推移逐步赢得用户更多的关注。

> Beyond delivery, it’s important to tune how many messages the agent sends. An agent that sends too many becomes noisy, while an agent that doesn’t send enough misses things that the user needs to know. We recommend building evals to find the right balance. In practice, it’s better for the agent to start quiet and then earn more of the user’s attention over time.

#### 各部分如何协同运作

> How everything fits together

以下是这五个原语如何协同工作的：

> Here is how the five primitives fit together:

![Animated diagram of how the five primitives fit together. Timers and the event inbox start a run, the run works with memory and permissions inside a session, and the outbox delivers messages to the user, whose answer comes back as an event.](https://assets.claude.com/9f8df7b2dcc9d4637d27f37dae6e40a2a5851c8a.gif)

每次运行都始于收件箱中的一个事件，无论是用户消息、webhook 还是定时器。当 worker 获取到一个事件时，它会启动一次运行，并在新会话或现有会话中唤醒智能体。智能体会读取其记忆以建立基线，在其权限范围内执行操作，然后将学到的任何内容更新到记忆中。运行结束后，智能体会向发件箱推送一行记录，再由分发器将消息投递给用户。

> Every run starts with an event from the inbox, whether it’s a user message, a webhook, or a timer. When the worker picks up an event, it kicks off a run and wakes the agent in a new or existing session. The agent reads its memory to get a baseline, works within its permissions to take actions, and then updates its memory with anything it has learned. Once the run is finished, the agent pushes a row to the outbox, and the dispatcher delivers the message to the user.

这些部分共同构成一个循环。一次运行可以设置一个定时器，让智能体在稍后再次被唤醒；当用户回复某条消息时，他们的答复会作为一个事件重新进入收件箱。每次运行都很短暂，但这个循环会无限持续下去，正是这一点让智能体给人一种始终在线的感觉。

> Together, these form a cycle. A run can set a timer that wakes the agent again later, and when the user replies to a message, their answer comes back as an event in the inbox. Each run is brief, but the cycle keeps going indefinitely, and that’s what makes the agent feel like it’s always on.

#### 致谢

> Acknowledgements

*作者：William Hu。特别感谢 Rodrigo Olivares 和 Michael Segner 的贡献。*

> *Written by William Hu. Special thanks to Rodrigo Olivares and Michael Segner for their contributions.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Always-on agent | 常驻智能体 | 有状态且主动、能跨会话管理上下文并在无直接监督下行动的智能体。 |
| Run | 运行 | 智能体接收事件、完成任务并保存相关信息的一段工作。 |
| Session | 会话 | 由消息和工具调用构成、承载运行的记录。 |
| Event inbox | 事件收件箱 | 持久化存放待处理事件、由工作进程统一取出处理的队列。 |
| Webhook | Webhook | 外部系统在事件发生时主动向指定端点发送 HTTP 请求的回调机制。 |
| Worker | 工作进程 | 从收件箱读取待处理事件并启动智能体运行的后台服务。 |
| Deduplication | 去重 | 依据来源提供的唯一标识符避免同一事件被重复处理。 |
| Follow-up | 跟进 | 智能体为自己设定的一次性截止时间类定时器。 |
| Scheduler | 调度器 | 定期轮询定时器存储并将到期任务写入收件箱的后台服务。 |
| Durable execution engine | 持久化执行引擎 | 能在故障后可靠恢复并继续执行工作流的运行时系统。 |
| Dreaming | 做梦 | 回顾过去会话以整理、更新记忆并发现跨运行模式的机制。 |
| Prompt caching | 提示词缓存 | 缓存重复使用的提示前缀以降低成本和延迟的技术。 |
| Compaction | 压缩 | 将较早消息概括缩减以控制会话上下文长度的做法。 |
| Auto mode | 自动模式 | 用分类器审查高风险操作、使智能体无需持续用户输入即可工作的模式。 |
| Deferred tool call | 延迟的工具调用 | 暂停某次工具调用并结束运行，待用户提供输入后再恢复会话执行的机制。 |
| Outbox | 发件箱 | 存放待发送给用户的消息、由分发器读取投递的独立表。 |
| Dispatcher | 分发器 | 读取发件箱中的待处理消息并决定投递给用户的后台服务。 |
