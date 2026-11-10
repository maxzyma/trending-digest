# 应该选用哪款 Claude 模型来构建应用？Fable、Opus、Sonnet 还是 Haiku

> Which Claude model should you build with? Fable, Opus, Sonnet, or Haiku

> 来源：Claude Blog / Anthropic，2026-11-09
> 原文链接：https://claude.dev/blog/which-claude-model-should-you-build-with/
> 分类：AI 工程 / 模型选型

## 核心要点

- 大多数工作建议先以 medium effort 使用 Opus 5.5，范围明确的日常任务可降级到 Sonnet 5.5，大批量简单任务可用 Haiku 5.5，最具挑战性或需长时间无人值守的项目则升级到 Fable 5.2。
- 更换模型前应先调整 effort 级别，但提高 effort 只能让模型思考更久、调用更多工具，并不能赋予其原本不具备的知识或技能。
- 每 token 价格更高并不必然意味着每项任务成本更高，在最困难的任务上 high 下的 Fable 5.2 可与 max 下的 Opus 5.5 得分持平而成本约为一半。
- 模型能力不足时应依次确保模型可自我验证、提高一级 effort、再换用更高级模型，并可先以低 effort 全量运行、仅对失败任务以高 effort 重跑来降低成本。
- 所有当前模型均有 100 万 token 上下文窗口，长时间运行中大部分输入按缓存读取计费，主模型越大越应保持主上下文精简，把冗长阅读交给更便宜的子代理。
- Haiku 5.5 是唯一按提示长度分档计价的模型，超过 100K token 的提示按五倍费率计费，因此长提示场景应按每项任务成本而非标价比较。
- 切换模型会产生新的缓存写入成本，且模型无法读取更高档模型的思考块，降级或从 Fable 5.2 切换时先前推理会被丢弃，宜在自然间歇点并借助摘要进行切换。
- 混合使用模型的方式包括让小模型承担易于发现错误的子代理工作、通过顾问工具向更强模型请教，以及由顶级模型主导并行调度多个低成本工作模型处理超大规模任务，但各方式收益需实测确认。
- 迁移前需检查保留思考、强制思考、强制工具调用、计算机使用、Haiku 参数变更及安全回退等兼容性差异，多模型系统应按最严格模型的要求构建请求。
- 最终选型应基于真实任务样本，在多个模型和 effort 级别下记录成本与得分并绘图比较，再以影子模式在部分真实流量上验证后切换。

## 正文

当前 Claude 产品阵容包含四款正式可用的模型：Claude Haiku 5.5、Claude Sonnet 5.5、Claude Opus 5.5 和 Claude Fable 5.2。Claude Mythos 5.2 是我们在网络安全和生命科学研究领域能力最强的模型，可通过我们的验证计划获取。

> The current Claude lineup has four generally available models: Claude Haiku 5.5, Claude Sonnet 5.5, Claude Opus 5.5 and Claude Fable 5.2. Claude Mythos 5.2 is our most capable model for cybersecurity and life sciences research, available through our verification programs.

如果你基于 Claude Platform 进行开发，或在 Claude Code 中工作，你可能会好奇在常见任务中应该使用哪个模型。本文将帮助解答这个问题，并说明如何权衡其中的取舍。

> If you build on the Claude Platform or work in Claude Code, you may be wondering which model to use for your common tasks. This article will help answer that question and how to think about the trade-offs.

#### 太长不看

> TL;DR

简而言之，大多数工作都应先在 Opus 5.5 上以其默认的 effort 级别开始，`medium`。

> The quick answer is that you should start most work on Opus 5.5 at its default effort level, `medium`.

它成为 Claude Code 的默认模型是有原因的。它的每个输入和输出 token 的价格仅为 Fable 5.2 的一半，也是我们推荐大多数编程和知识工作首选的模型。

> There's a reason it's the default model in Claude Code. It costs half as much per input and output token as Fable 5.2, and it's the model we recommend starting with for most coding and knowledge work.

在此基础上：

> From there:

- 对于范围明确的日常工作，例如修复 bug 或按照规格说明开发功能，可以降级使用 Sonnet 5.5。不过，有了清晰的规格说明并不意味着就应该使用 Sonnet。迁移或性能优化即便规格清晰，难度也可能足以需要 Opus 5.5；如果是大型任务，则可能需要 Fable 5.2。
- 对于最简单的大批量工作，例如分类、路由和信息提取，可以进一步降级使用 Haiku 5.5。Haiku 5.5 也很适合用于处理更大模型旁支任务的子代理。
- 在编程、金融和科学领域最具挑战性的技术项目中，请升级到 Claude Fable 5.2。此外，当 Opus 5.5 在 `high` 下仍无法满足需求时，或需要长时间无人值守运行时，也应升级。

> • Move down to Sonnet 5.5 for well-scoped everyday work, like a bug fix or a feature built against a spec. Just because you have a clear spec doesn't mean you should use Sonnet, though. A migration or a performance optimization can have clear specs and still be difficult enough to warrant Opus 5.5, or Fable 5.2 for a major one.
> • Move further down to Haiku 5.5 for the simplest high-volume work, such as classification, routing, and extraction. Haiku 5.5 is also good to use with subagents that work on a larger model's side tasks.
> • Move up to Claude Fable 5.2 for the hardest technical projects in coding, finance and the sciences. Also move up when Opus 5.5 at `high` still falls short, or for long unattended runs.

在更换模型之前，先试着调整你的 effort 级别。对于成本和能力而言，这都是一个更精细的调节旋钮。超过 `high` 之后，再提高一个 effort 级别的成本可能与换用更大的模型相当，因此请在你自己的任务上对两者进行比较。如果你已经超过 `high`，不妨改为以较低的 effort 测试更高一级的模型。反过来，降低一个级别也可能以更低的费用得到你所需的结果。

> Before you move models, try adjusting your effort level. It's a finer dial for both cost and capability. Past `high`, one more effort level can cost as much as a bigger model, so compare both on your own work. If you're past `high`, test the next model up at a lower effort instead. Conversely, one level down can get you the result you need at a lower rate.

当模型需要思考更长时间、调用更多工具或更多地检查自身工作时，提高 effort 会有所帮助。只是要记住，这也会增加延迟。此外，提升到更高的 effort 级别并不会赋予模型其原本不具备的知识或技能。要做到这一点，你仍然需要换用更高级的模型。

> Higher effort helps when the model needs to think longer, call more tools, or check its own work more. Just keep in mind that it also adds latency. Additionally, moving to a higher effort level won't give a model knowledge or skill it doesn't have. For that, you still need to move up a model.

#### 按任务选择模型

> PICK A MODEL BY TASK

| 任务 | 起始模型 | 起始 effort | 为什么 |
| --- | --- | --- | --- |
| 日常工程开发与调试。跨多个 PR 的功能开发 | Opus 5.5 | 先用 medium（默认），再用 high | 在成本与能力之间取得平衡，适用于日常任务。 |
| 分类、路由、打标签和大批量信息抽取 | Haiku 5.5 | 中（默认） | 该模型系列中成本和延迟最低。 |
| 负责搜索文件、读取日志或进行总结的子智能体 | Haiku 5.5 或 Sonnet 5.5 | 模型的默认设置 | 错误答案很容易发现，而且需要判断力的决策本来就由主模型负责。 |
| 聊天与交互式会话 | Sonnet 5.5（若为大规模的简单聊天场景，则用 Haiku 5.5） | 低或中 | Sonnet 5.5 速度很快，在低或中等 effort 下尤其如此。 |
| 范围明确的编码工作，例如缺陷修复、功能迭代和规格驱动的开发 | Sonnet 5.5 | medium，较难的任务再用 high | 它能很好地处理范围明确的任务，而 token 价格仅为 Opus 5.5 的一半。 |
| 日常文档、幻灯片和电子表格 | Sonnet 5.5 | high（默认；在 Claude Code 中为 medium） | 它迭代速度快，并且具有出色的设计眼光。对于复杂的财务模型，或基于大量源材料构建的文档，建议从 Opus 5.5 开始。 |
| 你需要反复运行的智能体任务，例如调查、审查或起草 | Sonnet 5.5 | 中 | 定义明确、重复执行的任务很少需要更大的模型。 |
| 计算机操作与重度依赖视觉的工作流 | Opus 5.5 | 中 | 这些运行是覆盖大量截图和图像的长时间智能体循环，正是 Opus 5.5 专为之打造的那类长时间运行的智能体工作。 |
| 大型重构与迁移、架构规划，以及统筹调度大量子代理 | Fable 5.2 | 先 medium，再 high（API 默认值为 high） | 它是 Anthropic 面向技术领域、目前正式可用的最强大模型。 |
| 深度研究，以及科学或定量分析 | Fable 5.2 | 先用 medium，再用 high（API 默认值为 high） | 它专为编程、金融和科学领域中最艰巨的技术项目而打造。 |
| 你还不确定 | Opus 5.5 | 中（默认） | Claude Code 在 Pro、Max、Ultra、Team、Enterprise 以及 Anthropic API 上默认使用它，平台文档也推荐将其作为起点。 |

> 英文原表 / English original

| Task | Starting model | Starting effort | Why |
| --- | --- | --- | --- |
| Everyday engineering and debugging. Multi-PR feature work | Opus 5.5 | medium (default), then high | Balance of cost and capability for everyday tasks. |
| Classification, routing, tagging, and high volume extraction | Haiku 5.5 | medium (default) | Lowest cost and latency in the model family. |
| Subagents that search files, read logs, or summarize | Haiku 5.5 or Sonnet 5.5 | The model's default | Wrong answers are cheap to spot, and the main model has the judgment calls anyway. |
| Chat and interactive sessions | Sonnet 5.5 (or Haiku 5.5 for simple chat at volume) | low or medium | Sonnet 5.5 is fast, especially on low or medium effort. |
| Well-scoped coding, like bug fixes, feature iteration, and spec driven work | Sonnet 5.5 | medium , then high for harder tasks | It handles scoped tasks well at half the Opus 5.5 token price. |
| Everyday documents, slides, and spreadsheets | Sonnet 5.5 | high (default; medium in Claude Code) | It iterates fast and has a strong eye for design. For a complex financial model, or a document built from a large pile of source material, start on Opus 5.5. |
| Agent tasks you run repeatedly such as investigation, review, or drafting | Sonnet 5.5 | medium | Well-defined, repeated tasks rarely need a bigger model. |
| Computer use and vision-heavy workflows | Opus 5.5 | medium | These runs are long agentic loops over many screenshots and images, the kind of long-running agentic work Opus 5.5 is built for. |
| Major refactors and migrations, architecture planning, and leading many subagents | Fable 5.2 | medium , then high (the API default is high ) | It's Anthropic's most capable generally available model for technical fields. |
| Deep research, and scientific or quantitative analysis | Fable 5.2 | medium , then high (the API default is high ) | It's built for the hardest technical projects in coding, finance and the sciences. |
| You aren't sure yet | Opus 5.5 | medium (default) | Claude Code uses it by default on Pro, Max, Ultra, Team, Enterprise and the Anthropic API, and the platform docs recommend it as the starting point. |

#### 四种模型并列对比

> THE FOUR MODELS SIDE BY SIDE

|  | Haiku 5.5 | Sonnet 5.5 | Opus 5.5 | Fable 5.2 |
| --- | --- | --- | --- | --- |
| 适用于 | 高吞吐量、成本敏感型任务 | 快速、高效地处理范围明确的任务 | 我们处理复杂编码和知识工作的日常主力 | 最具雄心、最开放性的技术工作 |
| 相对延迟 | 最快 | 快速 | 中等 | 中等 |
| 输入 / 输出，每百万 token | 提示词不超过 100K tokens 时为 $0.10 / $0.50，超过 100K 时为 $0.50 / $2.50 | $2 / $10 | $4 / $20 | $8 / $40 |
| 缓存读取，每百万 token | 10 万以内 $0.01，超过 10 万 $0.05 | $0.10 | $0.20 | $0.20 |
| 上下文窗口 | 100 万 token | 100 万 tokens | 100 万 tokens | 100 万 tokens |
| 最大输出 | 128K 个 token | 128K 个 token | 128K 词元 | 128K 个 token |
| API 中的思考功能 | 自适应，默认开启，也可以关闭 | 自适应，默认开启；between_tools 会跳过前置思考 | 自适应，始终开启 | 自适应，始终开启 |
| API 上的默认 effort（Claude Code 中可能不同；可通过 /effort status 查看你的设置） | 中 | 高（在 Claude Code 中为中） | 中 | high（在 Claude Code 中为 medium） |
| 快速模式 | 否 | 否 | 是 | 是 |

> 英文原表 / English original

|  | Haiku 5.5 | Sonnet 5.5 | Opus 5.5 | Fable 5.2 |
| --- | --- | --- | --- | --- |
| Built for | High-volume, cost-sensitive tasks | Fast, capable help with well-scoped tasks | Our daily driver for complex coding and knowledge work | The most ambitious, open-ended technical work |
| Relative latency | Fastest | Fast | Moderate | Moderate |
| Input / output, per million tokens | $0.10 / $0.50 for prompts up to 100K tokens, $0.50 / $2.50 over 100K | $2 / $10 | $4 / $20 | $8 / $40 |
| Cache reads, per million tokens | $0.01 up to 100K, $0.05 over 100K | $0.10 | $0.20 | $0.20 |
| Context window | 1M tokens | 1M tokens | 1M tokens | 1M tokens |
| Max output | 128K tokens | 128K tokens | 128K tokens | 128K tokens |
| Thinking on the API | Adaptive, on by default, and you can turn it off | Adaptive, on by default; between_tools skips upfront thinking | Adaptive, always on | Adaptive, always on |
| Default effort on the API (Claude Code can differ; /effort status shows yours) | medium | high ( medium in Claude Code) | medium | high ( medium in Claude Code) |
| Fast mode | No | No | Yes | Yes |

价格为 Claude API 标价。有关基准测试结果，请参阅 [Fable 5.2 页面](https://www.anthropic.com/claude/fable)。

> Prices are Claude API list prices. For benchmark results, see the [Fable 5.2 page](https://www.anthropic.com/claude/fable).

#### 权衡取舍

> THE TRADE-OFFS

在不同模型之间做选择时，你是在进行权衡。例如，当你选择一个更大的模型时，你是在用延迟换取能力。以下是需要仔细考虑的主要权衡。

> When you choose between models, you're making a trade-off. When you pick a larger model, for example, you are choosing capability over latency. These are the main trade-offs to think through.

##### 每个完成任务的能力与成本

> Capability and cost per finished task

一般来说，模型越大，每个 token 的成本越高，能力也越强，但在具体任务层面，成本与能力之间的这种权衡并不总是成立。

> Generally, bigger models cost more per token and are more capable, but the cost vs capability trade-off isn't universally true at the task level.

每 token 价格更高，并不总是意味着每项任务的成本更高，也不一定带来更好的结果。正如我们在[《Spending your effort》](https://claude.dev/blog/spending-your-effort/)中所展示的，在 Anthropic 运行的 Terminal-Bench 3.0 中，上一代 Fable 5.1 在 `max` 下得分为 58.0%，而 Opus 5.5 在 `high` 下得分为 58.9%，且仅用了一半的 token。

> A higher price per token doesn't always mean a higher cost per task, or a better result. As we showed in [Spending your effort](https://claude.dev/blog/spending-your-effort/), on Anthropic's runs of Terminal-Bench 3.0, the previous Fable, 5.1, at `max` scored 58.0%, while Opus 5.5 at `high` scored 58.9% with half the tokens.

在最困难的工作上，价格差距可能会缩小。在 FrontierCode 2.0 上，`high` 下的 Fable 5.2 与 `max` 下的 Opus 5.5 得分大致持平（45.3% 对 45.5%），而每项任务的成本约为后者的一半。因此，在困难任务上将 Opus 5.5 提升到 `high` 以上之前，不妨先试试 Fable 5.2。对于日常工作，`medium` 下的 Opus 5.5 仍是首选的起点。有关基准测试结果，请参阅[发布文章](https://www.anthropic.com/claude-fable-and-mythos-5-2)。

> On the hardest work, the price gap can close. On FrontierCode 2.0, Fable 5.2 at `high` scored about level with Opus 5.5 at `max` (45.3% vs. 45.5%) for roughly half the cost per task. So before you raise Opus 5.5 past `high` on a hard task, test Fable 5.2. For everyday work, Opus 5.5 at `medium` is still the place to start. For benchmark results, see the [launch post](https://www.anthropic.com/claude-fable-and-mythos-5-2).

不过，Claude Platform 的[成本与智能水平测评](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence)也显示出小模型的局限。这类模型通常擅长处理输出可校验的大批量工作，而不太适合长时间的智能体循环。

> However, the Claude Platform's [cost and intelligence measurements](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence) also show the limits of a small model. These generally do well on high-volume work with checkable outputs and are less suited to long agentic loops.

在比较两个模型时，除了典型任务之外，还应为任务集中最难的任务估算成本，因为最难的任务占据了大部分开销。在一个包含 20 道题的搜索基准测试中，有两道题就占了 43% 的开销。

> When you compare two models, price the hardest tasks in your set as well as the typical ones, because the hardest tasks carry most of the spend. On one 20-problem search benchmark, two problems carried 43% of the spend.

##### 延迟与准确率的权衡

> Latency against accuracy

更快的配置完成得更早，但也可能遗漏更多。在选择模型和投入级别之前，先想清楚一个人能等待多长时间。对于需要有人等待的回复，可以先让 Sonnet 5.5 使用 `low` 或 `medium`。

> A faster setup finishes sooner and can miss more. Think through how long a person can wait before you pick your model and effort level. For replies a person waits on, start Sonnet 5.5 at `low` or `medium`.

下一代模型通常比上一代更快。Fable 5.2 的输出生成速度比 Fable 5.1 最多快 30%。Sonnet 5.5 的运行速度比 Sonnet 5 快 30%。

> Often next generation models are faster than their predecessors. Fable 5.2 generates output up to 30% faster than Fable 5.1. Sonnet 5.5 runs 30% faster than Sonnet 5.

努力程度（effort level）与延迟大致呈正相关。请判断所获得的准确率提升是否值得付出额外的延迟。例如，在 SWE-bench Pro 上，Opus 5.5 在 `medium` 下的得分比 `high` 努力设置低约 2.5 分，成本约为其 70%。在 `low` 下，得分低约 8 分，成本约为其三分之一。在 `xhigh` 下，得分高约 1.4 分，成本是 `high` 的 2.5 倍。

> Effort level and latency are roughly correlated. Determine if the accuracy you gain is worth the extra latency. For example, on SWE-bench Pro, Opus 5.5 at `medium` scored about 2.5 points lower for about 70% of the cost as the `high` effort setting. At `low` it scored about 8 points lower for about a third of the cost. At `xhigh` it scored about 1.4 points higher for 2.5 times the cost of `high`.

相比调整投入程度（effort level），提供一种自我验证的手段往往更具成本效益，带来的延迟也更少。当模型不足以胜任某项任务时，请按以下顺序采取这些步骤：

> Often providing a means of self-verification is more cost effective and adds less latency than changing effort levels. When a model isn't good enough for a task, take these steps in order:

1. 确认模型能够验证自己的工作成果，可以通过测试、构建，或调用该端点的脚本来实现。
2. 将 effort 提高一级。
3. 换用更高一级的模型，并从比在较小模型上所用更低的 effort 级别开始。

> 1\. Check that the model can verify its own work, with a test, a build or a script that calls the endpoint.
> 2\. Raise effort one level.
> 3\. Move to the next model up, starting at a lower effort level than you used on the smaller one.

如果你能自动检查结果，就先以低级别运行所有任务，再仅以高级别重新运行失败的任务。在同一个 SWE-bench Pro 子集上，Opus 5.5 以 `low` 运行、失败任务以 `high` 重跑，约 97% 的任务通过，每个任务成本约 0.17 美元；相比之下，所有任务均以 `high` 运行时通过率为 95.3%，每个任务成本为 0.29 美元。

> If you can check outcomes automatically, run everything at a low level and re-run only the failures at a high one. On the same SWE-bench Pro subset, Opus 5.5 at `low` with failures re-run at `high` passed about 97% of tasks for about $0.17 each, against 95.3% for $0.29 with every task at `high`.

如果你需要同一模型更快地给出回复，可以选择为速度付费，而不必牺牲能力。在 Claude API 上，Opus 5.5 和 Fable 5.2 都提供[快速模式](https://platform.claude.com/docs/en/build-with-claude/fast-mode)，以溢价定价换取更高的输出速度。

> If you need a faster reply from the same model, you can pay for speed instead of giving up capability. On the Claude API, Opus 5.5 and Fable 5.2 both offer [fast mode](https://platform.claude.com/docs/en/build-with-claude/fast-mode), with higher output speed at premium pricing.

##### 上下文与成本的权衡

> Context against cost

当前这一代的每个模型都拥有 100 万 token 的上下文窗口。大上下文可以帮助模型完成任务，但每一轮都会产生成本，因为每一轮都要重新发送它。话虽如此，[在长时间运行中，你的大部分输入都按缓存读取计费](https://claude.com/blog/claude-opus-5-5-built-for-coding-sessions-that-use-more-context)。

> Every model in the current generation has a 1M-token context window. Large context can help the model complete the task but it costs you on every turn, because each turn resends it. That being said, [on long runs most of your input bills as cache reads](https://claude.com/blog/claude-opus-5-5-built-for-coding-sessions-that-use-more-context).

Opus 5.5 的缓存读取价格为每百万 token 0.20 美元，Sonnet 5.5 为 0.10 美元。Fable 5.2 同样收费 0.20 美元，因此在长时间、大量使用缓存的运行中，Fable 与 Opus 之间的差距取决于未缓存的输入和输出，而在这部分上，Fable 的每 token 成本是 Opus 的两倍。

> Opus 5.5 charges $0.20 per million tokens for a cache read, and Sonnet 5.5 charges $0.10. Fable 5.2 charges the same $0.20, so on a long, cache-heavy run the gap between Fable and Opus comes down to uncached input and output, where Fable costs twice as much per token.

在[《在 Opus 5.5 上完成一项任务的成本》](https://claude.dev/blog/what-a-task-costs-on-opus-5-5/)中，当上下文为 150K token 时，单轮的缓存读取成本约为 0.03 美元；当上下文为 20K 时，成本约为 0.004 美元。

> In [What a task costs on Opus 5.5](https://claude.dev/blog/what-a-task-costs-on-opus-5-5/), a turn's cache read costs about $0.03 at 150K tokens of context. At 20K it costs about $0.004.

由此得出的一个结论是：主模型越大，保持主上下文精简就越重要。把昂贵模型的上下文留给决策，让更便宜的子代理去完成冗长的阅读工作。

> One takeaway from this is that a lean main context matters more the bigger the main model is. Keep the expensive model's context for the decisions, and let cheaper subagents do the verbose reading.

Haiku 5.5 是唯一一款 token 单价随提示长度变化的模型。不超过 100K token 的提示按较低档位计费，超过 100K 的提示则按该费率的五倍计费。即便是长提示档位，其每 token 价格也仅为 Sonnet 5.5 的四分之一。因此，Haiku 5.5 在短提示上最为划算，此时其输入价格仅为 Sonnet 5.5 的二十分之一。

> Haiku 5.5 is the only model where the token price varies by prompt length. A prompt of up to 100K tokens bills at the lower tier, and a prompt over 100K bills at five times that rate. The long-prompt tier still costs a quarter of Sonnet 5.5's per-token price. So Haiku 5.5 pays off most on short prompts, where it costs a twentieth of Sonnet 5.5's input price.

当每次调用都需要很长的提示词时，应按完成每项任务的成本来比较 Haiku 5.5 和 Sonnet 5.5，而不是看标价。

> When every call needs a long prompt, compare Haiku 5.5 with Sonnet 5.5 on cost per finished task, not list price.

#### 混合使用模型

> MIXING MODELS

##### 在自然的间歇点进行切换

> Switch at a natural break

提示词缓存归属于写入它的模型。切换到新模型后的第一轮，需要为整个对话支付缓存写入费用。为了缩小这一轮的规模，可以先在 Claude Code 中运行 `/compact`，或者带着一份简短的书面计划开启一个新会话。在 API 上，开启新模型的对话时，请提供迄今为止工作的摘要，而不是完整的历史记录。

> The prompt cache belongs to the model that wrote it. Your first turn on a new model pays the cache-write price on the whole conversation. To make that turn smaller, run `/compact` first in Claude Code, or start a fresh session with a short written plan. On the API, open the new model's conversation with a summary of the work so far instead of the full history.

每个思考块都会记录生成它的模型，而每个模型只能读取部分其他模型的思考块。在 Claude API 和 Google Cloud 上的 Claude 模型（由 Google 托管）上，Opus 5.5 可以读取 Sonnet 5.5 和 Haiku 5.5 的思考块。Sonnet 5.5 可以读取 Haiku 5.5 的思考块。Fable 5.2 可以读取 Opus 5.5、Sonnet 5.5 和 Haiku 5.5 的思考块。在 Claude API 上，Fable 5.1 可以读取 Opus 5.5 的思考块。

> Each thinking block records the model that produced it, and each model reads only some other models' blocks. On the Claude API and Claude Models on Google Cloud (Google managed), Opus 5.5 reads Sonnet 5.5's and Haiku 5.5's thinking blocks. Sonnet 5.5 reads Haiku 5.5's. Fable 5.2 reads Opus 5.5's, Sonnet 5.5's and Haiku 5.5's. On the Claude API, Fable 5.1 reads Opus 5.5's.

降级到更低一档的模型会丢失先前的推理，因为模型永远不会读取比它更高档模型的思考块。其他切换方式也可能导致推理丢失。当新模型无法读取先前模型的思考块时，API 会丢弃这些块，请求仍会成功。随后，新模型将在没有这部分推理的情况下继续工作。

> A move down a tier loses the earlier reasoning, because a model never reads the blocks of a model above it. Other moves can lose it too. When the new model can't read the earlier model's thinking blocks, the API drops them and the request still succeeds. The new model then works without that reasoning.

[保留思考](https://platform.claude.com/docs/en/build-with-claude/preserved-thinking)列出了所有情况。从 Fable 5.2 切换到任何其他正式可用的模型时，其推理内容都会被丢弃。

> [Preserved thinking](https://platform.claude.com/docs/en/build-with-claude/preserved-thinking) lists every case. A move from Fable 5.2 to any other generally available model drops its reasoning.

##### 将子智能体放在较小的模型上运行

> Put subagents on smaller models

子代理在自己的上下文窗口中运行，并返回一份摘要。其 token 费用按所运行模型的费率计算。在 Claude Code 中，可在子代理的定义里设置 `model: haiku` 或 `model: sonnet`。对于未指定模型的子代理，`CLAUDE_CODE_SUBAGENT_MODEL` 环境变量用于设置其默认模型。

> A subagent runs in its own context window and hands back a summary. You pay for its tokens at the rates of the model it runs on. In Claude Code, set `model: haiku` or `model: sonnet` in a subagent's definition. The `CLAUDE_CODE_SUBAGENT_MODEL` environment variable sets the default for subagents that don't specify a model.

将其保存为 `.claude/agents/log-reader.md`：

> Save this as `.claude/agents/log-reader.md`:

```
---
name: log-reader
description: Reads test output and logs, and reports each failing case. Use after a test run.
tools: Read, Grep, Glob, Bash
model: haiku
---

Read the logs you're given. For each failure, report the file, the test name and the first error line. Don't edit any files.
```

让小模型负责那些出错后容易发现的工作，比如查找文件、运行测试和阅读日志。代码编辑和需要判断的决策则交给主模型。一旦小模型误读了搜索结果，主模型就会打开错误的文件，并在上面白白耗费 token。

> Keep small models on work where a mistake is cheap to spot, like finding files, running tests and reading logs. Keep code edits and judgment calls on the main model. When a small model misreads a search result, the main model opens the wrong file and spends tokens on it.

在当前版本的 Claude Code 中，内置的 Explore 子智能体会使用你会话所用的模型，而不再总是使用 Haiku。在 Claude API 上，该模型最高为 Opus。为了降低探索成本，可以自定义一个名为 `Explore` with `model: haiku`. You can pin the model the `haiku` alias uses with `ANTHROPIC_DEFAULT_HAIKU_MODEL`.

> In current versions of Claude Code, the built-in Explore subagent runs on your session's model instead of always running on Haiku. On the Claude API, that model is capped at Opus. To keep exploration cheap, define your own subagent named `Explore` with `model: haiku`. You can pin the model the `haiku` alias uses with `ANTHROPIC_DEFAULT_HAIKU_MODEL`.

在 Anthropic API 上，`haiku` 别名现在指向 Haiku 5.5，需要 Claude Code v2.1.293 或更高版本。在 Amazon Bedrock、Google Cloud、Microsoft Foundry 和 Claude Platform on AWS 上，它仍指向 Haiku 4.5。详情请参阅 Claude Code 的[模型配置](https://code.claude.com/docs/en/model-config)文档。

> On the Anthropic API, the `haiku` alias now resolves to Haiku 5.5, which needs Claude Code v2.1.293 or later. On Amazon Bedrock, Google Cloud, Microsoft Foundry and Claude Platform on AWS, it still resolves to Haiku 4.5. Claude Code's [model configuration](https://code.claude.com/docs/en/model-config) docs have the details.

Claude Code 还提供了 `opusplan` 别名：它在计划模式下用 Opus 制定计划，再用 Sonnet 执行该计划。这意味着代码编辑交给了 Sonnet。上面的建议恰恰相反：代码编辑留在主模型上，只把出错后容易发现的工作交给较小的模型。在把 `opusplan` 设为默认之前，请先在你自己的任务上实际测一测。

> Claude Code also has the `opusplan` alias, which plans with Opus in plan mode and then carries out the plan with Sonnet. That puts your code edits on Sonnet. The advice above does the reverse. It keeps code edits on the main model and gives smaller models only work where a mistake is cheap to spot. Measure `opusplan` on your own tasks before you make it your default.

##### 将艰难的决策上报给顾问

> Escalate hard decisions to an advisor

[顾问工具](https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool)（beta）将一个更快、更便宜的执行模型与一个更强的顾问模型搭配使用。执行模型负责运行任务，并可以在执行过程中向顾问模型寻求指导。大部分 token 按执行模型的费率计费。只有当顾问模型能提供执行模型所欠缺的能力，并且执行模型主动请求建议时，顾问模型才会发挥作用；而在低 effort 设置下，执行模型请求建议的频率会更低。

> The [advisor tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool) (beta) pairs a faster, cheaper executor model with a stronger advisor model. The executor runs the task and can ask the advisor for guidance partway through. Most of the tokens bill at the executor's rate. The advisor helps only when it adds capability the executor lacks and the executor asks for advice, which it does less often at low effort.

可能带来回报的场景：大多数轮次都是常规操作的智能体工作。该平台的成本指南态度谨慎：在其顾问模型表格列出的四种组合中，没有一种明显优于单独使用执行模型；而且只有当执行模型向顾问模型咨询时，顾问模型才能发挥作用。请先测量你的执行模型的咨询率。查看你的执行模型接受哪些顾问模型。例如，Sonnet 5.5 执行模型接受 Fable 5.2、Opus 5.5、Opus 5 和 Sonnet 5.5，而 Fable 5.2 执行模型只接受 Fable 5.2 或 Mythos 5.2。

> Where it might pay off: agentic work where most turns are routine. The platform's cost guide is cautious: of the four pairings in its advisor table, none clearly beat its executor alone, and an advisor can help only when the executor consults it. Measure your executor's consult rate first. Check which advisors your executor accepts. A Sonnet 5.5 executor accepts Fable 5.2, Opus 5.5, Opus 5 and Sonnet 5.5, for example, and a Fable 5.2 executor accepts only Fable 5.2 or Mythos 5.2.

收益甚微的情形：其中一种组合是在 `high` 下运行的 Opus 5.5 执行者搭配 Fable 5.1 顾问，在一项内部编程基准测试上进行评估。它的得分为 90.1%，每次尝试成本为 2.92 美元。这比在 `high` 下单独使用 Opus 5.5 高出 1.7 个百分点，但花费约为其 2.1 倍。这种幅度的提升处于不同运行之间随机波动的边缘，大致相当于提高 effort 所能带来的收益。

> Where it adds little: one of those pairings was an Opus 5.5 executor at `high` with a Fable 5.1 advisor on an internal coding benchmark. It scored 90.1% at $2.92 per attempt. That's 1.7 points over Opus 5.5 alone at `high` for about 2.1 times the money. A gain that size is at the edge of run-to-run noise, and about what raising effort would have bought.

##### 将批量工作委派给成本更低的工作者

> Delegate bulk work to cheaper workers

上文介绍的子代理（subagent）负责处理旁支任务，由一个主模型把握主线。而本模式适用于超出单个上下文窗口容量的工作：由一个顶级模型担任主导，拆分任务，将各部分并行分派给众多成本更低的工作模型，再将返回的结果合并。在一项针对约 2200 万 token 源代码的内部缺陷搜索基准测试中，由 Opus 5.5 主导、同时调度最多 25 个 Sonnet 5.5 工作模型的方案，成本比默认推理强度下单独使用 Opus 5.5 低约三分之一，而得分大致相当。

> Subagents, above, handle side tasks while one main model keeps the thread. This pattern is for work bigger than one context window. A top-tier model leads, splits the task, hands the pieces to many cheaper workers in parallel, and merges what comes back. On an internal defect-search benchmark over about 22 million tokens of source code, an Opus 5.5 lead over Sonnet 5.5 workers, up to 25 at a time, cost about a third less than Opus 5.5 alone at its default effort. It scored about the same.

在 Claude Platform 上，Claude Managed Agents 中的[多智能体编排](https://platform.claude.com/docs/en/managed-agents/multiagent-orchestration)为你提供一个协调者智能体和一组工作者智能体。如果任务是一条由相互依赖步骤组成的链，或者工作量能放进单个上下文窗口，就不要使用它。在这些情况下，规划与合并的成本会高于它所节省的成本。[何时将子智能体并入主智能体循环](https://claude.com/resources/articles/building-agents-when-to-fold-subagents-into-your-main-agent-loop)一文介绍了在哪些情况下，单个智能体循环比一组子智能体更胜一筹。

> On the Claude Platform, [multiagent orchestration](https://platform.claude.com/docs/en/managed-agents/multiagent-orchestration) in Claude Managed Agents gives you a coordinator agent and a roster of workers. Skip it for one chain of dependent steps or for work that fits in one context window. There, the planning and merging cost more than they save. [When to fold subagents into your main agent loop](https://claude.com/resources/articles/building-agents-when-to-fold-subagents-into-your-main-agent-loop) covers when one agent loop beats a team of subagents.

#### 迁移前请检查兼容性

> CHECK COMPATIBILITY BEFORE MIGRATING

选择模型主要取决于能力和成本，但并不总是只改个模型名称、其他一概不动就行。当前所有模型都支持工具调用和图像输入，但在把请求从一个模型迁移到另一个模型之前，仍有一些差异需要测试。

> Model choice is mostly a question of capability and cost, but you can't always change the model name and nothing else. Every current model supports tool use and image input, but there are differences to test before you move a request from one model to another.

- **Fable 5.2 将保留思考扩展至所有 API 账户。**当 Fable 5.2 思考块之前的任何内容发生变化时，包括系统提示词、工具或较早的消息，API 都会以 400 错误拒绝该请求，除非你选择启用丢弃受影响的思考内容。如果你通过 Claude Code、Claude Agent SDK 或 Claude Managed Agents 构建请求，则无需做任何更改。如果你自己的代码会编辑历史记录，请保持其仅追加，并在切换前进行测试。
- **思考。**Opus 5.5 和 Fable 5.2 始终会进行思考，关闭思考的请求会返回错误。Sonnet 5.5 默认进行思考，而 `between_tools` 会将思考限制在工具调用之间的间隙中。Haiku 5.5 默认进行思考，在 `high` 或更低的 effort 级别下可以关闭思考。对于所有这些模型，都应按 `type` 读取内容块，因为响应可能以思考块开头。
- **强制工具调用。**在 Sonnet 5.5、Opus 5.5 和 Fable 5.2 上，将 `tool_choice` 设为 `any` 或 `tool` 会返回 400 错误。请改为发送 `auto`，将该工具标记为 `strict: true`，并在提示词中说明何时使用它。
- **计算机使用。**Opus 5.5、Sonnet 5.5、Haiku 5.5 和 Fable 5.2 仅在 Claude API 以及 Google Cloud 上的 Claude 模型（由 Google 托管）中，通过 `computer_toolset_20260801` 工具集支持计算机使用。
- **从 Haiku 4.5 迁移到 Haiku 5.5。**将 `budget_tokens` 替换为 effort 级别，并移除非默认的 `temperature`、`top_p` 和 `top_k` 值，否则会返回 400 错误。`messages` 必须以用户轮次结尾，因为以助手轮次结尾、让模型续写同样会返回 400 错误。
- **安全回退。**Opus 5.5、Sonnet 5.5 和 Fable 5.2 会运行安全分类器，这些分类器最常标记网络安全和生物学相关内容。在 Claude Code 中，被标记的请求可能会改用较旧的模型重新运行，对话记录中会显示一条通知，告诉你具体使用了哪个模型。Fable 5.2 沿用了 Fable 5.1 所使用的回退模型。被标记的网络安全请求会回退到 Opus 4.8，被标记的生物学请求则会回退到 Opus 5。

> • **Fable 5.2 extends preserved thinking to every API account.** The API rejects a request with a 400 error when anything before a Fable 5.2 thinking block has changed, including the system prompt, the tools or an earlier message, unless you opt in to dropping the affected thinking. If you build requests through Claude Code, the Claude Agent SDK or Claude Managed Agents, you don't need to change anything. If your own code edits history, keep it append-only, and test before you switch.
> • **Thinking.** Opus 5.5 and Fable 5.2 always think, and a request that turns thinking off returns an error. Sonnet 5.5 thinks by default, and `between_tools` limits thinking to the gaps between tool calls. Haiku 5.5 thinks by default, and you can turn thinking off at `high` effort or below. On all of them, read content blocks by `type`, because a response can begin with a thinking block.
> • **Forced tool use.** A `tool_choice` of `any` or `tool` returns a 400 error on Sonnet 5.5, Opus 5.5 and Fable 5.2. Send `auto`, mark the tool `strict: true`, and say in the prompt when to use it.
> • **Computer use.** Opus 5.5, Sonnet 5.5, Haiku 5.5 and Fable 5.2 support computer use only through the `computer_toolset_20260801` toolset on the Claude API and Claude Models on Google Cloud (Google managed).
> • **Haiku 4.5 to Haiku 5.5.** Replace `budget_tokens` with an effort level, and drop non-default `temperature`, `top_p` and `top_k` values, which return a 400 error. End `messages` with a user turn, because a final assistant turn for the model to continue also returns a 400 error.
> • **Safety fallbacks.** Opus 5.5, Sonnet 5.5 and Fable 5.2 run safety classifiers that most often flag cybersecurity and biology content. In Claude Code, a flagged request can re-run on an older model, and a notice in the transcript tells you which. Fable 5.2 keeps the fallback models that Fable 5.1 uses. Flagged cybersecurity requests fall back to Opus 4.8, and flagged biology requests to Opus 5.

如果一个系统运行多个模型，就按其中最严格的那个来构建每一个请求：保持历史记录只追加不修改，在使用严格工具时发送 `tool_choice: auto`，按 `type` 读取内容块，并把提示词和工具描述写得足够精确，让最照字面理解的模型也能正确执行。这样一来，某个步骤在不同层级之间上调或下调时，就无需修改代码。当路由规则很简单时，例如每种步骤类型对应一个模型，就让代码来选择模型，而不是让模型来选。

> If one system runs several models, build every request for the strictest of them: keep history append-only, send `tool_choice: auto` with strict tools, read content blocks by `type`, and write prompts and tool descriptions precisely enough for the most literal model. Then a step can move up or down a tier without a code change. When the routing rule is simple, such as one model for each step type, let code pick the model rather than asking a model to.

#### 在你自己的工作上进行衡量

> MEASURE ON YOUR OWN WORK

已发布的结果（例如上文的 SWE-bench Pro 和 Terminal-Bench 分数）可以帮你选出一个起步模型。在正式选定之前，请先用你自己的任务对候选模型进行测试。

> Published results, like the SWE-bench Pro and Terminal-Bench numbers above, get you a starting model. Then test the candidates on your own tasks before you commit.

1. 抽取一批真实任务作为样本。为每个任务编写一项结果检查，例如测试通过、工单关闭或行数正确。
2. 让每个候选模型分别在两到三个 effort 级别下运行，每次运行都使用独立的会话，以免各次运行共享缓存。根据每个响应的 `usage` 字段，记录每个已完成任务的成本。
3. 以花费为横轴、得分为纵轴绘制图表。只有当多模型方案在图上优于每一个单模型数据点时，才保留该方案。
4. 在正式切换之前，先让胜出方案以影子模式在一部分真实流量上运行。

> 1\. Pull a sample of real tasks. Write an outcome check for each one, such as a passing test, a closed ticket or a correct row count.
> 2\. Run each candidate model at two or three effort levels, each in its own session so that the runs don't share a cache. Record the cost of each completed task from the `usage` field of each response.
> 3\. Plot score against spend. Keep a multi-model setup only if it beats every single-model point on that chart.
> 4\. Run the winner in shadow on a slice of real traffic before you cut over.

若要在 Claude Code 中快速验证，可以从你的待办列表中挑一个任务，用 `/model` 在两个模型上分别运行，然后比较 `/usage` 报告的结果。

> For a quick check in Claude Code, run one task from your backlog on two models with `/model` and compare what `/usage` reports.

#### 了解更多

> LEARN MORE

- [使用 Claude Sonnet 5.5 进行构建](https://claude.dev/blog/building-with-claude-sonnet-5-5/)介绍了何时选择 Sonnet 而非 Opus，以及定价、迁移和调优等内容。
- [在 Claude 和 Claude Code 中充分发挥 Opus 5.5 的能力](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/)介绍了如何为 Opus 5.5 编写提示词以及如何引导长时间运行的任务。
- [在 Opus 5.5 上完成一项任务要花多少钱](https://claude.dev/blog/what-a-task-costs-on-opus-5-5/)一文对 effort 设置、模型选择和子代理的成本进行了测算。
- Claude 博客上的[为你的用例选择最合适的 Claude 模型](https://claude.com/blog/claude-models-explained-choosing-the-best-model-for-your-use-case)和[在 Claude Code 中选择模型与投入程度](https://claude.com/blog/claude-model-and-effort-level-in-claude-code)两篇文章对此有更深入的介绍。
- 相关文档请参阅[选择模型](https://platform.claude.com/docs/en/about-claude/models/choosing-a-model)、[在成本与智能之间进行优化](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence)、[Effort](https://platform.claude.com/docs/en/build-with-claude/effort)、Claude Code [模型配置](https://code.claude.com/docs/en/model-config)以及[子代理](https://code.claude.com/docs/en/sub-agents)。

> • [Building with Claude Sonnet 5.5](https://claude.dev/blog/building-with-claude-sonnet-5-5/) covers when to choose Sonnet over Opus, pricing, migration and tuning.
> • [Getting the most out of Opus 5.5 in Claude and Claude Code](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/) covers prompting Opus 5.5 and steering long runs.
> • [What a task costs on Opus 5.5](https://claude.dev/blog/what-a-task-costs-on-opus-5-5/) prices effort, model choice and subagents.
> • On the Claude blog, [choosing the best Claude model for your use case](https://claude.com/blog/claude-models-explained-choosing-the-best-model-for-your-use-case) and [picking a model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) go deeper.
> • In the docs, see [Choosing a model](https://platform.claude.com/docs/en/about-claude/models/choosing-a-model), [Optimizing for cost and intelligence](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence), [Effort](https://platform.claude.com/docs/en/build-with-claude/effort), Claude Code [model configuration](https://code.claude.com/docs/en/model-config) and [subagents](https://code.claude.com/docs/en/sub-agents).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| effort level | 投入级别 | 控制模型思考时长、工具调用与自检程度的参数，影响成本、能力与延迟。 |
| subagent | 子代理 | 在独立上下文窗口中运行并向主模型返回摘要的辅助智能体。 |
| prompt caching | 提示词缓存 | 缓存已发送的提示内容以便后续轮次按较低的缓存读取价格计费的机制。 |
| cache read | 缓存读取 | 复用已缓存的输入内容时产生的计费项，单价低于普通输入。 |
| context window | 上下文窗口 | 模型单次请求可处理的最大 token 数量。 |
| thinking block | 思考块 | 响应中记录模型推理过程并标注生成模型的内容块。 |
| preserved thinking | 保留思考 | 在多轮对话中保留并回传先前思考块的机制，要求历史记录保持只追加。 |
| advisor tool | 顾问工具 | 让较便宜的执行模型在任务中向更强的顾问模型请求指导的测试版工具。 |
| executor model | 执行模型 | 在顾问模式中实际运行任务并承担大部分 token 费用的模型。 |
| multiagent orchestration | 多智能体编排 | 由协调者智能体拆分任务并调度多个工作者智能体并行处理再合并结果的模式。 |
| fast mode | 快速模式 | 以溢价换取同一模型更高输出速度的服务选项。 |
| tool_choice | 工具选择参数 | API 中指定模型是否及如何调用工具的请求参数。 |
| computer use | 计算机使用 | 让模型通过专用工具集操作计算机界面的能力。 |
| safety fallback | 安全回退 | 请求被安全分类器标记后改由较旧模型重新运行的机制。 |
| shadow mode | 影子模式 | 让新方案在部分真实流量上并行运行但不影响实际输出的验证方式。 |
