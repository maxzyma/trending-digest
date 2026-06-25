---
source: claude-blog
source_url: https://claude.com/blog/harnessing-claudes-intelligence
published_at: 2026-04-02
category: Claude Blog
title_en: Harnessing Claude’s intelligence
title_zh: 驾驭 Claude 的智能
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 0
source_image_count: 7
---

# 驾驭 Claude 的智能

> • Harnessing Claude’s intelligence

> • 来源：Claude Blog，2026-04-02
> • 原文链接：https://claude.com/blog/harnessing-claudes-intelligence
> • 分类：Claude Blog

## 核心要点

- Anthropic 联合创始人 Chris Olah 认为，像 Claude 这样的生成式 AI 系统更多是"生长"出来的，而非"建造"出来的，因此构建时所做的假设会随着 Claude 能力增强而过时。
- 应使用 Claude 已经熟练掌握的工具（如 bash 和文本编辑器工具）来构建应用，Claude 能将这些通用工具组合成解决不同问题的模式。
- 应不断追问"我可以停止做什么"，让 Claude 自行编排动作、管理上下文、持久化上下文，例如通过代码执行、技能（Skills）、压缩（compaction）和记忆文件夹。
- 在为应用设置边界时要谨慎，针对用户体验、可观测性或安全边界使用声明式专用工具，并通过缓存命中优化成本。
- Claude 的智能前沿不断变化，需在每次能力跃迁后重新检验既有假设，并修剪掉已成为负担的结构。

## 正文

构建在智能、延迟和成本之间取得平衡的应用程序。

> Building applications that balance intelligence, latency, and cost.

Anthropic 联合创始人之一 Chris Olah 表示，像 Claude 这样的生成式 AI 系统更像是被培育出来的，而非被搭建出来的。研究者设定条件来引导其生长，但最终涌现出的确切结构或能力并不总是可预测的。

> One of Anthropic’s co-founders, Chris Olah, says that generative AI systems like Claude are grown more than they are built. Researchers set the conditions to direct growth, but the exact structure or capabilities that emerge aren’t always predictable.

这给基于 Claude 的开发带来了挑战：智能体框架（agent harness）编码了对 Claude 自身做不到什么的种种假设，但随着 Claude 能力增强，这些假设会逐渐过时。即便是本文这类文章中分享的经验，也值得经常重新审视。

> This creates a challenge for building with Claude: agent harnesses encode assumptions about what Claude can’t do on its own, but those assumptions grow stale as Claude gets more capable. Even lessons shared in articles like this deserve frequent revisiting.

本文分享三种模式，供团队在构建应用时使用，使应用既能跟上 Claude 不断演进的智能，又能兼顾延迟与成本：利用它已经知道的、追问哪些事可以不再做、以及谨慎地用智能体框架划定边界。

> In this article, we share three patterns that teams should use when building applications that keep pace with Claude’s evolving intelligence while balancing latency and cost: use what it already knows, ask what you can stop doing, and carefully set boundaries with the agent harness.

#### 1. 利用 Claude 已知的能力

> 1. Use what Claude knows

我们建议使用 Claude 熟悉的工具来构建应用。

> We suggest building applications using tools that Claude understands well.

2024 年末，Claude 3.5 Sonnet 在 SWE-bench Verified 上达到 49%——当时的最高水平——而它仅依靠一个 bash 工具和一个用于查看、创建、编辑文件的文本编辑器工具。Claude Code 也建立在这同样的工具之上。Bash 并不是为构建智能体而设计的，但它是 Claude 懂得如何使用、并随时间越用越好的工具。

> In late 2024, Claude 3.5 Sonnet reached 49% on SWE-bench Verified—then state of the art —with only a bash tool and a text editor tool for viewing, creating, and editing files. Claude Code is grounded in these same tools. Bash wasn’t designed for building agents, but it's a tool that Claude knows how to use and gets better at using over time.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd8747994e07042a959518_image2.png)

我们看到 Claude 将这些通用工具组合成各种模式，用以解决不同的问题。例如，智能体技能（Agent Skills）、程序化工具调用（programmatic tool calling）和记忆工具（memory tool），都是由 bash 和文本编辑器工具构建出来的。

> We've seen Claude compose these general tools into patterns that solve different problems. For instance, Agent Skills , programmatic tool calling , and the memory tool are all built from the bash and text editor tools.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd8835161641fba4aa1def_image4.png)

#### 2. 追问"我可以不再做什么？"

> 2. Ask ‘what can I stop doing?’

智能体框架编码了对 Claude 自身做不到什么的假设。随着 Claude 能力增强，这些假设应当受到检验。

> Agent harnesses encode assumptions about what Claude can’t do on its own. As Claude gets more capable, those assumptions should be tested.

让 Claude 自行编排其行动

> Let Claude orchestrate its own actions

一个常见的假设是：每个工具调用结果都应回流到 Claude 的上下文窗口中，以指导下一步行动。如果某个结果只需传递给下一个工具，或 Claude 只关心输出中的一小部分，那么以 token 形式处理工具结果可能既慢、又贵，且没有必要。

> A common assumption is that every tool result should flow back through Claude’s context window to inform the next action. Processing tool results in tokens can be slow, costly, and unnecessary if it only needs to be passed to the next tool or if Claude only cares about a small slice of the output.

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd889c76e6e17dbe4ff4b9_image7.png)

设想要读取一个很大的表格，却只为推断其中某一列：整个表格都进入上下文，Claude 为每一行（哪怕用不到）都付出 token 成本。可以在工具设计层面用硬编码过滤器来应对这个问题。但这并未解决一个根本事实：是智能体框架在做编排决策，而 Claude 其实更适合做这个决策。

> Consider reading a large table to reason about a single column: the whole table lands in context and Claude pays the token cost for every row it doesn't need. It’s possible to tackle this in tool design, using hard-coded filters . But this does not address the fact that the agent harness is making an orchestration decision that Claude is better positioned to make.

给 Claude 一个代码执行工具（例如 bash 工具或特定语言的 REPL）就能解决这一点：它让 Claude 能编写代码来表达工具调用以及调用之间的逻辑。与其由框架决定每个工具调用结果都以 token 形式处理，不如让 Claude 自行决定哪些结果应该透传、过滤，或在不触及上下文窗口的情况下管道传递给下一次调用。只有代码执行的输出才进入 Claude 的上下文窗口。

> Giving Claude a code execution tool (e.g., bash tool or language-specific REPL ) addresses this: it allows Claude to write code to express tool calls and the logic between them. Rather than the harness deciding that every tool call result is processed as tokens, Claude decides what results to pass through, filter, or pipe into the next call without touching the context window. Only the output of code execution reaches Claude’s context window.

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd891f5b4d2dea57b008d1_image6.png)

编排决策从框架转移到了模型。由于代码是 Claude 编排行动的一种通用方式，一个强大的编码模型同时也是一个强大的通用智能体。Claude 用这种模式在非编码评测上表现出色：在测试智能体网页浏览能力的基准 BrowseComp 上，赋予 Opus 4.6 自行过滤工具输出的能力，将准确率从 45.3% 提升到了 61.6%。

> The orchestration decision moves from the harness to the model. Since code is a general way for Claude to orchestrate actions, a strong coding model is also a strong general agent. Claude shows strong performance on non-coding evals using this pattern: on BrowseComp, a benchmark that tests the ability of agents to browse the web, giving Opus 4.6 the ability to filter its own tool outputs brought accuracy from 45.3% to 61.6%.

让 Claude 自行管理其上下文

> Let Claude manage its own context

针对任务的上下文会引导 Claude 使用 bash、文本编辑器等通用工具。一个常见假设是：系统提示词应该用针对任务的指令手工精心编写。问题在于，预先在提示词中塞入指令无法跨众多任务扩展：每加入一个 token 都会消耗 Claude 的注意力预算，而预先载入很少用到的指令是一种浪费。

> Task-specific context steers Claude’s use of general tools like bash and the text editor tool. A common assumption is that system prompts should be hand-crafted with task-specific instructions. The problem is that pre-loading prompts with instructions does not scale across many tasks: every token added depletes Claude’s attention budget and it is wasteful to pre-load context with rarely used instructions.

让 Claude 能够访问技能就解决了这一点：每个技能的 YAML 前置元数据（frontmatter）是一段预先载入上下文窗口的简短描述，提供该技能内容的概览。当某个任务需要时，Claude 可调用读取文件工具，逐步展开完整的技能内容。

> Giving Claude the ability to access skills addresses this: the YAML frontmatter of each skill is a short description pre-loaded into the context window, providing an overview of the skill contents. The full skill can be progressively disclosed by Claude calling a read file tool if a task calls for it.

![Image 5](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd895f7f04456cccf7b7e0_image3.png)

如果说技能让 Claude 有自由组装自己上下文窗口的能力，那么上下文编辑（context editing）则是其反向操作：提供一种方式，有选择地移除已过时或不再相关的上下文，例如旧的工具结果或思考块。

> While skills give Claude the freedom to assemble its own context window, context editing is the inverse, providing a way to selectively remove context that’s become stale or irrelevant, such as old tool results or thinking blocks.

借助子智能体（subagents），Claude 越来越懂得何时该分叉出一个全新的上下文窗口，以隔离某项具体任务的工作。在 Opus 4.6 上，派生子智能体的能力使 BrowseComp 的成绩比最佳的单智能体运行高出 2.8%。

> With subagents , Claude is getting better at knowing when to fork into a fresh context window to isolate work on a specific task. With Opus 4.6 , the ability to spawn subagents improved results on BrowseComp by 2.8% over the best single-agent runs.

让 Claude 自行持久化其上下文

> Let Claude persist its own context

长时间运行的智能体可能超出单个上下文窗口的限制。一个常见假设是：记忆系统应依赖围绕模型搭建的检索基础设施。我们的许多工作都聚焦于给 Claude 提供简单的方式，让它自行选择要持久化哪些内容。

> Long-running agents can exceed the limit of a single context window . A common assumption is that memory systems should rely on retrieval infrastructure around the model. Much of our work has focused on giving Claude simple ways to choose for itself what content to persist.

例如，压缩（compaction）让 Claude 能够总结其过往的上下文，以便在长跨度任务中保持连贯性。经过多个版本的迭代，Claude 在选择记住什么方面越来越好。例如在智能体搜索任务 BrowseComp 上，无论我们给多少压缩预算，Sonnet 4.5 都停滞在 43%。而在相同设置下，Opus 4.5 扩展到了 68%，Opus 4.6 更达到了 84%。

> For example, compaction lets Claude summarize its past context in order to maintain continuity on long-horizon tasks. Over several releases, Claude has gotten better at choosing what to remember. On BrowseComp , for example, an agentic search task, Sonnet 4.5 stayed flat at 43% regardless of the compaction budget we gave it. Yet Opus 4.5 scaled to 68% and Opus 4.6 reached 84% with the same setup.

记忆文件夹是另一种方法，允许 Claude 把上下文写入文件，之后按需读取。我们已经看到 Claude 把它用于智能体式搜索（agentic search）。在 BrowseComp-Plus 上，给 Sonnet 4.5 配备记忆文件夹，使准确率从 60.4% 提升到 67.2%。

> A memory folder is another approach, allowing Claude to write context to files and later read them as needed. We’ve seen Claude use this for agentic search. On BrowseComp-Plus, giving Sonnet 4.5 a memory folder lifted accuracy from 60.4% to 67.2% .

![Image 6](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd89bfccdc7c50beb40e0d_image5.png)

长程游戏（long-horizon games），例如宝可梦，体现了 Claude 在使用记忆文件夹方面的能力提升。Sonnet 3.5 把记忆当作逐字记录，写下非玩家角色（NPC）说了什么，而不是真正重要的内容。在 14000 步之后，它有 31 个文件——其中包括两个关于毛毛虫宝可梦的近乎重复的文件——而它仍停留在第二个城镇：

> Long-horizon games , such as Pokémon, are an example of Claude’s improved ability to use a memory folder. Sonnet 3.5 treated memory as a transcript, writing down what non-player characters (NPCs) said rather than what mattered. After 14,000 steps it had 31 files—including two near-duplicates about caterpillar Pokémon—and was still in the second town:

```text
caterpie_weedle_info: - 绿毛虫和独角虫都是毛毛虫宝可梦。 - 绿毛虫是一种没有毒的毛毛虫宝可梦。 - 独角虫是一种有毒的毛毛虫宝可梦。 - 这条信息对未来的遭遇和战斗至关重要。 - 如果我们的宝可梦中毒了，我们应该尽快到宝可梦中心寻求治疗。
```

> ```text
> caterpie_weedle_info: - Caterpie and Weedle are both caterpillar Pokémon. - Caterpie is a caterpillar Pokémon that does not have poison. - Weedle is a caterpillar Pokémon that does have poison. - This information is crucial for future encounters and battles. - If our Pokémon get poisoned, we should seek healing at a Pokémon Center as soon as possible.
> ```

后来的模型则写下战术笔记。Opus 4.6 在相同步数下，有 10 个按目录组织的文件、三枚道馆徽章，以及一个从自身失败中提炼出来的经验文件：

> Later models wrote tactical notes. Opus 4.6, at the same step count, had 10 files organized into directories, three gym badges, and a learnings file distilled from its own failures:

```text
/gameplay/learnings.md: - 喇叭芽的催眠+紧束组合：在催眠粉命中之前用咬住快速击倒它。别让它布场！ - 第一世代背包上限：最多 20 个道具。进地下城前丢掉不需要的招式机。 - 旋转地砖迷宫：不同的进入 y 位置会通向不同的目的地。尝试所有入口，并串联穿过多个区块。 - B1F y=16 的墙在所有 x=9-28 处已确认为实心（第 14557 步）
```

> ```text
> /gameplay/learnings.md: - Bellsprout Sleep+Wrap combo: KO FAST with BITE before Sleep Powder lands. Don't let it set up! - Gen 1 Bag Limit: 20 items max. Toss unneeded TMs before dungeons. - Spin tile mazes: Different entry y-positions lead to DIFFERENT destinations. Try ALL entries and chain through multiple pockets. - B1F y= 16 wall CONFIRMED SOLID at ALL x= 9 -28 (step 14557 )
> ```

#### 3. 谨慎设定边界

> 3. Set boundaries carefully

智能体框架（agent harness）在 Claude 周围提供结构，以确保用户体验、成本或安全。

> Agent harnesses provide structure around Claude to enforce UX, cost, or security.

设计上下文以最大化缓存命中

> Design context to maximize cache hits

消息 API（Messages API）是无状态的。Claude 无法看到此前回合的对话历史。这意味着智能体框架需要在每个回合把新的上下文连同所有过往动作、工具描述和指令一起打包给 Claude。

> The Messages API is stateless. Claude cannot see the conversation history of prior turns. This means that the agent harness needs to package new context alongside all past actions, tool descriptions, and instructions for Claude at each turn.

提示可以基于设定的断点（breakpoint）进行缓存。换句话说，Claude API 会把断点之前的上下文写入缓存，并检查该上下文是否与任何此前的缓存条目匹配。

> Prompts can be cached based on set breakpoints . In other words, the Claude API writes context up until a breakpoint to the cache and checks whether the context matches any prior cache entries.

由于缓存令牌的成本仅为基础输入令牌的 10%，以下是智能体框架中有助于最大化缓存命中的几条原则：

> Since cached tokens are 10% the cost of base input tokens, here are a few principles in the agent harness help maximize cache hits:

使用声明式工具来处理用户体验、可观测性或安全边界

> Use declarative tools for UX, observability, or security boundaries

Claude 不一定知道某个应用的安全边界或用户体验界面。Claude 发出工具调用，由框架处理。bash 工具给了 Claude 广泛的程序化能力来执行动作，但它只给框架一个命令字符串——每个动作的形态都相同。把动作提升为专用工具，则给框架提供了一个针对具体动作、带类型化参数的钩子，框架可以拦截、把关、渲染或审计它。

> Claude doesn't necessarily know an application's security boundary or UX surface. Claude emits tool calls, which are handled by the harness. A bash tool gives Claude broad programmatic leverage to perform actions, but it gives the harness only a command string—the same shape for every action. Promoting actions to dedicated tools gives the harness an action-specific hook with typed arguments it can intercept, gate, render, or audit.

需要安全边界的动作天然适合做成专用工具。可逆性通常是一个好的判断标准，而像外部 API 调用这类难以逆转的动作可以通过用户确认来把关。诸如 edit 之类的写入工具可以包含陈旧性检查（staleness check），这样 Claude 就不会覆盖一个自上次读取以来已发生变更的文件。

> Actions that require a security boundary are natural candidates for dedicated tools. Reversibility is often a good criterion, and hard-to-reverse actions such as external API calls can be gated by user confirmation. Write tools like edit can include a staleness check so Claude doesn't overwrite a file that changed since it was last read.

![Image 7](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd8ebecb4a73207c8b2ffc_image1.png)

当某个动作需要呈现给用户时，工具也很有用。例如，它们可以渲染为模态框，向用户清晰地展示一个问题、给用户多个选项，或者在用户提供反馈之前阻塞智能体循环。

> Tools are also useful when an action needs to be presented to a user. For example, they can be rendered as a modal to display a question clearly to the user, give the user multiple options, or block the agent loop until a user provides feedback.

最后，工具对可观测性也很有用。当动作是一个类型化的工具时，框架就能获得结构化的参数，可以记录、追踪和回放。

> Finally, tools are useful for observability. When the action is a typed tool, the harness gets structured arguments it can log, trace, and replay.

把动作提升为工具的决定应当持续重新评估。例如，Claude Code 的自动模式（在本文发表时处于研究模式）为 bash 工具提供了一道安全边界：它让第二个 Claude 读取命令字符串并判断其是否安全。这种模式可以减少对专用工具的需求，且只应用于用户信任其总体方向的任务。对于某些高风险动作，专用工具仍有其存在价值。

> The decision to promote actions to tools should be continually re-evaluated. For example, Claude Code's auto-mode (in research mode at the time of publication) provides a security boundary around the bash tool: it has a second Claude read the command string and judge whether it's safe. This pattern can limit the need for dedicated tools, and should only be used for tasks where users trust the general direction. Dedicated tools can still earn their place for certain high-stakes actions.

#### 展望

> Looking forward

Claude 智能的前沿始终在变化。关于 Claude 做不到什么的假设，需要随着它能力的每一次阶跃而重新检验。

> The frontier of Claude’s intelligence is always changing. Assumptions about what Claude can’t do need to be re-tested with each step change in its capability.

我们看到这种模式反复出现。在我们为长程任务构建的一个智能体中，Sonnet 4.5 一旦感觉到上下文上限临近，就会过早收尾。我们加入了重置机制来清空上下文窗口，以应对这种"上下文焦虑"。到了 Opus 4.5，这种行为消失了。我们为弥补它而构建的上下文重置，反而成了智能体框架中的累赘。

> We see this pattern repeat itself. In an agent we built for long-horizon tasks , Sonnet 4.5 would wrap up prematurely as it sensed the context limit approaching. We added resets to clear the context window in order to address this "context anxiety." With Opus 4.5, the behavior was gone. The context resets we built to compensate had become dead weight in the agent harness.

移除这种累赘很重要，因为它可能成为 Claude 性能的瓶颈。随着时间推移，我们应用中的结构或边界应当基于这样一个问题来修剪：我可以停止做什么？

> Removing this dead weight is important because it can bottleneck Claude’s performance. Over time, the structure or boundaries in our applications should be pruned based the question: what can I stop doing?

要使用这里讨论的所有工具和模式，请查看我们的 claude-api 技能。

> To use all tools and patterns discussed here, check out our claude-api skill .

#### 致谢

> Acknowledgements

由 Lance Martin 撰写，他是 Claude 平台团队的技术人员。特别感谢 Thariq Shihipar、Barry Zhang、Mike Lambert、David Hershey 和 Daliang Li 就本文所涉主题展开的有益讨论。感谢 Lydia Hallie、Lexi Ross、Katelyn Lesse、Andy Schumeister、Rebecca Hiscott、Jake Eaton、Pedram Navid 和 Molly Vorwerck 的编辑审阅与反馈。

> Written by Lance Martin, member of technical staff on the Claude Platform team. Special thanks to Thariq Shihipar, Barry Zhang, Mike Lambert, David Hershey, and Daliang Li for helpful discussion on the topics covered. Thanks to Lydia Hallie, Lexi Ross, Katelyn Lesse, Andy Schumeister, Rebecca Hiscott, Jake Eaton, Pedram Navid, and Molly Vorwerck for their editorial review and feedback.

## 术语对照

| English | 中文 |
|---|---|
| agent harness | 智能体框架 |
| generative AI | 生成式 AI |
| tool | 工具 |
| text editor tool | 文本编辑器工具 |
| Agent Skills | 智能体技能 |
| programmatic tool calling | 程序化工具调用 |
| memory tool | 记忆工具 |
| context window | 上下文窗口 |
| code execution tool | 代码执行工具 |
| orchestration | 编排 |
| system prompt | 系统提示词 |
| frontmatter | 前置元数据 |
| progressively disclosed | 逐步披露 |
| context editing | 上下文编辑 |
| subagents | 子智能体 |
| compaction | 压缩 |
| memory folder | 记忆文件夹 |
| long-horizon games | 长跨度游戏 |
| breakpoints | 断点 |
| staleness check | 陈旧性检查 |
| modal | 模态框 |
| observability | 可观测性 |
| reversibility | 可逆性 |
| auto-mode | 自动模式 |
