# 使用 Claude Platform 降低成本并提升性能

> Reducing cost and improving performance with Claude Platform

> 来源：Claude Blog / Anthropic，2026-09-08
> 原文链接：https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform
> 分类：AI 工程 / 大模型成本优化

## 核心要点

- 许多使用 Claude Platform 的应用可以通过最大化提示缓存命中率、移除提示反模式和校准思考投入这三项改进，在不牺牲性能的前提下削减成本。
- 提示缓存保存的是预填充阶段生成的键值缓存状态，缓存读取的计费价格仅为完整输入价格的一小部分，但要求前缀逐字节一致、绑定同一模型，并受存活时间限制。
- 破坏缓存的常见做法包括在对话中途改动 effort 或 thinking 设置、把时间戳与 ID 等易变值放进前缀、改动会被渲染在最前面的工具定义，以及在分叉对话时前缀不完全一致。
- 保护缓存的手段包括监控缓存命中率并使用缓存诊断 API、对不常用工具启用 defer_loading、以对话中途系统消息的形式下发指令更新、把静态上下文放在增长的对话之前，以及按需为前缀设置 1 小时 TTL。
- 缓存本就会因压缩等操作失效的时刻，是切换模型或推理强度的合适时机；发送 max_tokens 为 0 且带显式缓存断点的请求可以预热缓存以降低首次延迟。
- 为弥补旧模型弱点而写的提示指令会成为反模式，包括验证仪式、彻底性与强调类增强表述、强制流程与草稿纸脚手架、过时的少样本示例、相互矛盾的规则以及已被平台拒绝的过时配置。
- 在客户支持基准的迁移实验中，对六个分别植入一种反模式的提示运行 prompt-audit，平均使成本下降 14.6%、准确率提升 5.3%，成因包括消除多余工具调用、废弃 thinking 设置导致的请求被拒以及草稿纸与内置思考的冲突。
- effort 等级会同时改变成本与性能，Fable 5 在 FrontierCode Diamond 上从低到最高档得分提高约 2.7 倍而成本约 3.5 倍，Fable 5.1 在 Humanity's Last Exam 上最后一档的提升则落在噪声范围内。
- effort 可能在两个方向失准：过高导致过度思考、推高成本与延迟甚至降低质量，过低则让模型在证据不足时停下、发起更少工具调用并跳过检查。
- 校准方法包括在低 effort 档位测试更强的模型，以及在一系列 effort 级别上测量应用性能以判断任务是否受思考算力限制；在 CursorBench 3.2 上低档 Fable 5.1 达到高档 Fable 5 的性能而成本仅三分之一。
- hillclimb 命令将评估集拆分为训练集与测试集并迭代搜索配置，在客户支持基准上最终以低推理强度的 Sonnet 5 配合补充的路由规则，在 14 个留出工单上把得分从 78.6% 提升至 90.5%，成本约为原来的五分之一。
- cost-optimize 命令先定位 token 开销来源，再按提示缓存、精简请求、限制输出规模和批处理排序施加措施，在 LegalBench、tau2-bench retail、OfficeQA Pro 和 SWE-bench Verified 上分别降低约 58%、73%、52% 和 55% 的成本。

## 正文

性能与成本常常被视为一种权衡：想少花钱，就得接受更差的结果。但在实践中，我们发现许多使用 Claude Platform 的应用可以通过三项改进在不牺牲性能的前提下削减成本：最大化提示缓存命中率、在升级到前沿 Claude 模型时移除提示中的反模式，以及根据任务校准投入的思考量。我们已将这些指导整理进 [claude-api skill](https://github.com/anthropics/skills/tree/main/skills/claude-api)。在本文中，我们将展示 Claude Code 搭配 `claude-api `往往能够找到在保持甚至提升性能的同时降低成本的方法。

> Performance and cost are often viewed as a trade-off: to spend less, you accept worse results. In practice, we've found that many applications using Claude Platform can cut costs without giving up performance with three fixes: maximize the prompt cache hit rate, remove anti-patterns from your prompts when upgrading to frontier Claude models, and calibrate effort to the task. We've put this guidance into the [claude-api skill](https://github.com/anthropics/skills/tree/main/skills/claude-api). In this article, we show how Claude Code with the `claude-api `can often find ways to reduce cost while maintaining or improving performance.

#### **提示词缓存**

> **Prompt cache**

在 Claude 生成回复之前，它会先将你的提示词处理成一个内部工作状态。这一步称为*预填充*，是处理输入过程中开销最大的部分。提示词缓存会保存该状态（即键值缓存，KV cache）：当某个请求以相同的前缀开头时，Claude 会将其读回，而不是重新计算。缓存读取的[计费价格仅为](https://platform.claude.com/docs/en/about-claude/pricing)完整输入价格的一小部分。

> Before Claude generates a response, it first processes your prompt into an internal working state. This step, called *prefill*, is the expensive part of handling input. Prompt caching saves that state (the key–value, or KV, cache): when a request starts with the same prefix, Claude reads it back instead of recomputing it. Cache reads are[ billed at a fraction](https://platform.claude.com/docs/en/about-claude/pricing) of the full input price.

要有效利用提示缓存，有几点实际的注意事项。首先，提示缓存与特定模型绑定。其次，提示缓存的读取必须在整个提示的完整范围内做到*逐字节精确一致*。最后，提示缓存的[存活时间有限](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#ttl-support)（TTL）。

> There are a few practical considerations to ensure effective use of the prompt cache. First, the prompt cache is pinned to a specific model. Second, prompt cache reads must be *byte-exact* across the full span of the prompt. Finally, the prompt cache has a [limited time-to-live](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#ttl-support) (TTL).

考虑到这几点，这里有一些实用的建议：

> With these points in mind, there are a few practical tips:

- **避免在对话中途更改 effort 或 thinking 设置**。这些设置会在你的内容之前被渲染进提示词中，因此它们属于被缓存的前缀部分。特别是在使用 Claude Opus 5 和 Fable 5.1 时，你可以[在对话中途更新 effort](https://platform.claude.com/docs/en/build-with-claude/effort#changing-effort-mid-conversation)而不会破坏缓存。

> • **Avoid changing effort or thinking settings mid-conversation**. These settings render into the prompt ahead of your content, so they are part of the cached prefix. With Claude Opus 5 and Fable 5.1 specifically, you can [update effort mid-conversation](https://platform.claude.com/docs/en/build-with-claude/effort#changing-effort-mid-conversation) without breaking the cache.

- **不要把易变的值放在前缀中**。系统提示词中的动态时间戳或 ID 会在不同的模型调用之间发生变化，从而破坏缓存。 

> • **Keep volatile values out of the prefix**. A dynamic timestamp or ID in the system prompt can change across model calls, and break the cache. 

- **避免会自行重新排序的工具定义**。使用 Claude Messages API 时，[提示词的组装](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#structuring-your-prompt)顺序是固定的，工具定义会被渲染在最前面。对工具定义的任何改动都会导致缓存失效。 

> • **Avoid tool definitions that reorder themselves**. When using the Claude Messages API, the [prompt is assembled](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#structuring-your-prompt) in a fixed order with tool definitions rendered at the top. Any change to the tool definition will break the cache. 

- **分叉对话时要小心**。只有当分叉的前缀在字节层面完全一致、使用同一模型、且采用相同的 effort 设置时，子代理和分支才会共享父级的缓存。 

> • **Be careful when forking conversations**. Subagents and branches only share the parent’s cache when the fork’s prefix is byte-identical, on the same model, and using the same effort. 

- **避免使用超出缓存 TTL 的同步工具调用和子智能体**。如果一个智能体阻塞在长时间运行的工具调用或子智能体上，缓存可能在结果返回之前就已过期。下一轮就必须重写缓存，费用是正常输入价格的 1.25 倍（1 小时缓存则为 2 倍），而不是便宜的读取价格。

> • **Avoid synchronous tool calls and subagents that outlive the cache TTL**. If an agent blocks on a long-running tool call or sub-agent, the cache can expire before the results come back. The next turn has to rewrite the cache, at 1.25× the normal input price (2× for a 1-hour cache) instead of the cheap read price.

##### 如何修复

> How to fix it

我们[积累](https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything)了一些关于提示词缓存管理的经验教训： 

> We’ve [accumulated](https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything) a few lessons for prompt cache management: 

- **仔细监控你的提示缓存命中率**。[Claude Console](https://platform.claude.com/docs/en/build-with-claude/cache-diagnostics) 提供提示缓存诊断功能，包括提示缓存未命中的原因（图 1）。如果命中率意外下降，[缓存诊断 API ](https://platform.claude.com/docs/en/build-with-claude/cache-diagnostics)会准确告诉你两个请求在哪里出现了分歧。

> • **Monitor your prompt cache hit rate carefully**. [Claude Console](https://platform.claude.com/docs/en/build-with-claude/cache-diagnostics) provides prompt cache diagnostics, including reasoning for prompt cache misses (Figure 1). If hits drop unexpectedly, the [cache diagnostics API ](https://platform.claude.com/docs/en/build-with-claude/cache-diagnostics)tells you exactly where two requests diverged.

![Figure 1. Claude Console can diagnose unexpected prompt cache misses by comparing consecutive requests and identifying exactly where the prompt prefix diverged.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9f8d87cec69dcbb7d97cb2_image3.png)

- **推迟加载不常用的工具**。预先声明你所有的工具，但把不常用的那些标记为 [defer_loading](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-use-with-prompt-caching#defer-loading-and-cache-preservation)：它们不会进入被缓存的前缀，只有当 Claude 通过工具搜索查找到它们时才会被追加到对话中，因此缓存得以保留。

> • **Defer rarely used tools**. Declare all your tools up front but mark the rarely used ones [defer_loading](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-use-with-prompt-caching#defer-loading-and-cache-preservation): they stay out of the cached prefix and are appended into the conversation only when Claude looks them up with tool search, so the cache is preserved.

- **以消息的形式应用系统提示词的更新**。[Claude Platform](https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages#when-to-use-a-mid-conversation-system-message) 允许你在对话中途将系统指令作为一条消息添加进去，而不是去修改系统提示词，这样可以保留缓存。

> • **Apply system prompt updates as messages**. [Claude Platform](https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages#when-to-use-a-mid-conversation-system-message) lets you add a system instruction as a message mid-conversation instead of editing the system prompt, which preserves the cache.

- **组织请求结构，让稳定的部分保持稳定**。先放入静态上下文（工具定义和系统提示词），再把不断增长的对话内容放在它们之后（图 2）。

> • **Lay out the request out so the stable part stays stable**. Add static context (tool definitions and the system prompt) first and the growing conversation behind them (Figure 2).

![Figure 2. Organize prompts to ensure dynamic content is appended to the end of a stable prefix.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9f8e173f4924ebf13397e3_image5.png)

- **在提示缓存本就会失效时再更换模型或推理强度**。某些操作（例如[压缩](https://platform.claude.com/docs/en/build-with-claude/compaction)）本身就会重写大部分缓存（即对话内容）。那正是切换模型或推理强度的[好时机](https://cognition.com/blog/devin-fusion)，因为反正你已经要为一次缓存未命中付费了。

> • **Make changes to model or effort when the prompt cache will already be broken**. Certain operations, like [compaction](https://platform.claude.com/docs/en/build-with-claude/compaction), already rewrite much of the cache (the conversation). That is a [good moment](https://cognition.com/blog/devin-fusion) to switch model or effort, since you are paying for a miss anyway.

- **随着对话增长移动缓存断点**。在 Claude Platform 中，你可以设置[自动缓存](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#automatic-caching)，将缓存断点自动应用到最后一个可缓存的块。

> • **Move the cache breakpoint as the conversation grows**. With Claude Platform, you can set [automatic caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#automatic-caching) to automatically apply the cache breakpoint to the last cacheable block. 

- **预热缓存**。为了降低延迟，可以发送一个带有 `max_tokens: 0` 和显式缓存断点的请求。这会处理提示词并将其写入缓存，而不生成任何内容。如果你在会话开始时运行它（例如，在用户正在输入时），那么第一个真实请求就会命中已预热的缓存。

> • **Pre-warm the cache**. To reduce latency, send a request with `max_tokens: 0` and an explicit cache breakpoint. This processes the prompt and writes it to the cache without generating anything. If you run it at session start (for example, while a user is typing), the first real request hits a warm cache.

- **不要超出提示缓存的 TTL**。5 分钟的缓存 TTL 从请求开始时计时。如果某个智能体因工具调用或子智能体请求而阻塞，且这些调用运行超过 5 分钟，父级的缓存会在结果返回之前过期。在这类情况下，可以考虑改为对前缀[设置 1 小时的 TTL](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence)。

> • **Don’t exceed the prompt cache TTL**. The 5-minute cache TTL counts from the start of the request. If an agent blocks on tool calls or sub-agent requests that run longer than 5 minutes, the parent's cache expires before the result comes back. In cases like this, consider [setting a 1-hour TTL](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence) on the prefix instead.

#### **说明**

> **Instructions**

提示词中可能会不断累积各种用于弥补模型弱点的指令。随着[最新 Claude 模型](https://x.com/trq212/status/2080710971228918066)能力的提升，这些指令可能会逐渐与模型能力脱节。以下是一些常见的提示词“反模式”，它们会束缚前沿 Claude 模型的表现，并且可能无意中增加成本：

> Prompts can accumulate instructions that patch model weaknesses. These instructions can drift relative to the capabilities of the [latest Claude models](https://x.com/trq212/status/2080710971228918066). Here are common prompting “anti-patterns” that hobble frontier Claude model and can inadvertently increase costs:

- **验证仪式**。诸如“*仔细检查你的工作*”或“*回复前验证两次*”这样的指令，常常会被前沿模型按字面意思执行，从而浪费 token。

> • **Verification rituals**. Instructions like "*double-check your work*” or "*verify twice before responding*” are often taken literally by frontier models and can waste tokens.

- **彻底性与强调类增强表述**。“*务求最大程度的彻底*”“*关键：你必须始终……*”这类表述在与前沿模型协作时，可能导致输出冗长以及额外的工具调用。

> • **Thoroughness and emphasis boosters**. "*Be maximally thorough*," "*CRITICAL: YOU MUST ALWAYS…*" can lead to verbosity and extra tool calls when working with frontier models.

- **强制性流程与草稿纸脚手架**。固定的步骤流程（例如「*在草稿纸上一步步思考*」）或推理模板都是前沿模型并不需要的仪式。这类脚手架会叠加在原生推理之上，消耗不必要的 token。

> • **Mandatory procedures and scratchpad scaffolds**. Fixed step processes (e.g., "*think step by step in a scratchpad*") or reasoning templates are rituals that frontier models don't need. This scaffolding can stack on top of native reasoning and use unnecessary tokens.

- **过时的示例**。针对旧模型失效模式而调优的少样本示例，可能会让前沿模型在并不需要长推理链的请求上，也去模仿这种长推理链。

> • **Stale examples**. Few-shot examples tuned to an older model's failure modes can teach a frontier model to imitate long reasoning chains on requests that don't need them.

- **相互矛盾的规则**。前沿模型在指令遵循方面表现更好。相互矛盾的指令（“始终在政策范围内退款”与“未经上报绝不发放退款”）可能会被前沿模型更字面地遵循，从而导致性能下降。  

> • **Contradictory rules**. Frontier models are better at instruction following. Contradictory instructions ("always refund within policy" vs. "never issue refunds without escalation") can be followed more literally by frontier models, resulting in degraded performance.  

- **过时的配置**。为较早一代 Claude 编写的设置（例如手动设定的思考预算）在升级到前沿模型时可能会被 Claude 平台拒绝。

> • **Dated configuration**. Settings written for an older Claude generation (e.g., manual thinking budgets) can be rejected by the Claude Platform when upgrading to frontier models.

##### **如何修复 **

> **How to fix it **

我们已更新 `claude-api `技能，新增了一个用于排查这些反模式的命令。在 Claude Code 中，针对你的提示词、技能或工具描述运行 `/claude-api prompt-audit`。该审查覆盖你工作目录中的所有内容，包括调用 Claude API 的应用代码以及 Claude Code 自身的配置（例如 [CLAUDE.md](http://claude.md) 或技能）。

> We've updated the `claude-api `skill with a new command that watches out for these anti-patterns. In Claude Code, run `/claude-api prompt-audit` against your prompts, skills, or tool descriptions. The audit covers anything in your working directory, including application code that calls the Claude API and Claude Code's own configuration (e.g., [CLAUDE.md](http://claude.md) or skills).

例如，我们在一个客户支持基准测试上测试了从 Opus 4.8 到 Opus 5 的模型迁移。我们从一个干净的提示词出发，每次植入一种反模式（一个已弃用的思考设置、一对相互矛盾的退款规则、一个手动草稿板、"验证两次"、"尽可能详尽"，以及一个强制的六步流程），从而得到六个遗留提示词。

> For example, we tested a model migration from Opus 4.8 to Opus 5 on a customer support benchmark. We started from a clean prompt and planted one anti-pattern at a time (a retired thinking setting, a pair of contradictory refund rules, a manual scratchpad, "verify twice", "be maximally thorough", and a mandatory six-step procedure), giving six legacy prompts. 

我们对每一项都进行了测试：在 Opus 4.8 上运行，在仅更改模型 ID 的 Opus 5 上运行，以及在每个提示各运行一次 `/claude-api prompt-audit` 之后的 Opus 5 上运行（图 3 显示了这六项的平均值）。

> We ran each on Opus 4.8, on Opus 5 with only the model ID changed, and on Opus 5 after running `/claude-api prompt-audit` once per prompt (Figure 3 shows the average across the six).

![Figure 3. The effect of prompting anti-patterns during model migration from Opus 4.8 to Opus 5.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9f8f03f76b0fe7cad36789_image7.png)

在 Opus 5 上，验证仪式（"*验证两次*"）会在每次退款时重复执行订单查询，从而消耗不必要的 token。强调式增强语（"*尽可能详尽彻底*"）则变成了数十次不必要的知识库搜索。 

> With Opus 5, verification rituals ("*verify twice*") use unnecessary tokens by duplicating order lookup on every refund. Emphasis boosters ("*be maximally thorough*") became dozens of unneeded knowledge-base searches. 

运行 `/claude-api prompt-audit` 移除了这些反模式，平均使成本下降 14.6%，准确率提升 5.3%。成本下降是因为消除了额外的工具调用和重复的推理。准确率上升有三个原因。已废弃的 thinking 设置导致 API 直接拒绝了每一个路由请求。相互矛盾的退款规则使 Opus 5 在要求客户确认的同时，扣下了四笔本应发放的退款。而手动草稿纸与 Opus 5 的内置思考发生了冲突：在三张工单上，它把工具调用写进了自己的推理过程中，却从未真正执行。

> Running `/claude-api prompt-audit` removed the anti-patterns, decreasing costs by 14.6% and increasing accuracy by 5.3% on average. Cost dropped because extra tool calls and duplicated reasoning were eliminated. Accuracy rose for three reasons. The retired thinking setting made the API reject every routing request outright. The contradictory refund rules led Opus 5 to withhold four refunds it owed while it asked the customer to confirm. And the manual scratchpad collided with Opus 5's built-in thinking: on three tickets it wrote the tool call inside its reasoning and never executed it.

#### **Effort**

> **Effort**

[Effort](https://platform.claude.com/docs/en/build-with-claude/effort)（努力程度）告诉 Claude“要多努力地工作”。在低努力程度下，Claude 通常会更快地得出结论。在高努力程度下，Claude 会在回答之前进行深思、验证并探索其他备选方案。 

> [Effort](https://platform.claude.com/docs/en/build-with-claude/effort) tells Claude “how hard to work.” At low effort Claude generally reaches conclusions faster. At high effort, Claude deliberates, verifies, and explores alternatives before answering. 

同一个模型在不同思考强度（effort）等级下的成本与性能之比可能存在差异。例如，在 FrontierCode Diamond（最难的 50 个任务）上，Claude Fable 5 在低强度下得分为 11.5%，每个任务花费 5.35 美元。在最高强度下，Fable 5 得到 30.9% 的分数，每个任务花费 19.00 美元；改变强度使分数提高了约 2.7 倍（+19 分），而成本约为 3.5 倍（图 4）。

> Cost-versus-performance across effort levels on a single model can vary. For example, Claude Fable 5 scores 11.5% at low effort for $5.35 per task on FrontierCode Diamond (the hardest 50 tasks). At max effort, Fable 5 gets 30.9% for $19.00 per task; changing effort raises the score about 2.7x (+19 points) for about 3.5x the cost (Figure 4). 

在 Claude Fable 5.1 上，Humanity's Last Exam（不使用工具）呈现出一条陡峭但最后一步收益递减的曲线。在低算力投入下，它的得分约为 53%，每道题约需 0.30 美元；在最大算力投入下得分约为 61%，每道题约需 2.23 美元；从次高档提升到最大档这最后一步只带来约半个百分点的提升，成本却增加了 46%。这一增益落在该基准测试运行间的噪声范围内，所以你多花了钱却得不到可测量的收益。

> On Claude Fable 5.1, Humanity's Last Exam (without tools) shows a steep curve with a diminishing last step. It scores about 53% at low effort for about $0.30 per question and about 61% at max effort for about $2.23; the last step up to max adds about half a point for 46% more cost. The gain inside the benchmark's run-to-run noise, so you pay more for no measurable gain.

![Figure 4. Fable 5 performance vs cost across effort levels on FrontierCode Diamond.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9f8f79e11f87d01ba88ea0_image4.png)

努力程度可能在两个方向上失准：

> Effort can be miscalibrated in either direction:

- **误以为越高总是越好**。过高的思考投入会导致 Claude *过度*思考。它花在斟酌上的时间超出了任务本身的需要，这既增加了成本和延迟，也可能降低答案质量。只有在仍有证据可供发掘时，斟酌才有帮助。

> • **Assuming higher is always better**. High effort can cause *over-*thinking. Claude spends more time deliberating than the task warrants, which adds cost / latency and can degrade answer quality. Deliberation only helps while there's still evidence to find. 

- **偏向低努力程度**。设置得过低时，Claude 会在证据尚不充分时就停下来。它发起的工具调用更少，因此可能根据第一个搜索结果作答，而不是第三个。它在困难步骤上思考得更少，并跳过原本会自行执行的检查。答案看起来是完整的，但它建立在不完整的信息之上。 

> • **Biasing to low effort**. Set too low, Claude stops before it has enough evidence. It makes fewer tool calls, so it may answer from the first search result instead of the third. It thinks less on hard steps and skips the check it would normally run on its own. The answer looks finished, but it's built on partial information. 

##### **如何修复 **

> **How to fix it **

有一些有用的方法可以校准投入的精力：

> There are some useful ways to calibrate effort: 

- **在更低的努力档位上测试更强的模型**。一个更强的模型在低努力档位下运行，可能比一个较弱的模型全力工作（高努力档位）更便宜。例如，在 CursorBench 3.2 上，低努力档位的 Claude Fable 5.1 [达到了](https://www-cdn.anthropic.com/0339e6a7c5c7b87f5c07798616dc32c215d14235/Claude%20Fable%205.1%20&%20Claude%20Mythos%205.1%20System%20Card.pdf)高努力档位 Fable 5 的性能，而成本只有三分之一（图 5）。有两点让这个更新的模型更便宜：在低努力档位下它每个任务做的工作更少，而且 Fable 5.1 的提示缓存读取定价为每百万 token 0.25 美元，而 Fable 5 为 1.00 美元。即便按 Fable 5 的价格计算，低努力档位的 Fable 5.1 也会便宜约 40%。

> • **Test stronger models at lower effort**. A stronger model at low effort can be cheaper than a weaker model working hard (high effort). For example, on CursorBench 3.2, Claude Fable 5.1 at low effort [matches the performance](https://www-cdn.anthropic.com/0339e6a7c5c7b87f5c07798616dc32c215d14235/Claude%20Fable%205.1%20&%20Claude%20Mythos%205.1%20System%20Card.pdf) of Fable 5 at high effort at a third of the cost (Figure 5). Two things make the newer model cheaper: at low effort it does less work per task, and Fable 5.1's prompt-cache reads are priced at $0.25 per million tokens versus $1.00 for Fable 5. Even at Fable 5's prices, Fable 5.1 at low effort would cost about 40% less.

![Figure 5. Fable 5 vs. Fable 5.1 across effort levels on CursorBench 3.2.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9f8fa48d8330985eb9d300_image1.png)

- **了解你的任务形态。**在[一系列思考强度级别](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence#tune-effort)上测量应用性能，是理解特定任务成本-性能权衡的有效方法。在未饱和的评估中，如果性能-成本曲线在各个强度级别上保持平坦，说明该任务并不受思考算力的限制；提高思考强度不会带来收益。

> • **Understand your task shape. **Measuring application performance across a [sweep of effort levels](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence#tune-effort) is a useful way to understand the cost-performance tradeoff for your particular task. On a non-saturated evaluation, a flat performance-cost curve across effort levels suggests that the task is not bound by thinking compute; increasing effort is not beneficial.

这种校准通常需要在不同模型和不同投入水平上运行一次评估。在 Claude Code 中，`/claude-api hillclimb` 会为你执行这项搜索：它将你的评估拆分为训练集和测试集，提出配置更改建议，并读取训练集中未通过的样例以修复所发现的问题。

> This calibration often involves running an evaluation across models and effort levels. In Claude Code, `/claude-api hillclimb` performs this search for you: it splits your evaluation into train and test sets, proposes configuration changes, and reads failing train examples to fix what it finds.

我们在一个客户支持基准测试上运行了它，起点是默认（高）努力程度下的 Opus 4.8。爬坡器首先尝试了低努力程度的 Opus 5，并应用 prompt-audit 来移除强制性的工具调用仪式、草稿纸步骤和相互矛盾的规则。这一步以 98.9% 的训练准确率超越了 Opus 4.8 基线，并将成本降至每张工单 2.6 美分。

> We ran it on a customer support benchmark, starting from Opus 4.8 at its default (high) effort. The hillclimber first tried Opus 5 at low effort, applying prompt-audit to remove mandatory tool-call rituals, scratchpad steps, and contradictory rules. That cleared the Opus 4.8 baseline at 98.9% train accuracy and cut cost to 2.6 cents per ticket.

![Figure 6. Hillclimbing improves cost and performance by updating model choice, effort, and prompt.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9f8fd5bc0d13015256b1f5_image6.png)

随后它降级到低推理强度的 Sonnet 5，成本更低，每张工单 1 美分，但准确率降至 88.9%。在阅读了失败的火车票工单后，Claude 在提示词中加入了路由规则和退款上限交叉引用，使 Sonnet 5 在相同成本下重新回到 98.9%。

> It then stepped down to Sonnet 5 at low effort, which was cheaper still at 1 cent per ticket, but accuracy fell to 88.9%. Reading the failing train tickets, Claude added routing rules and a refund-cap cross-reference to the prompt, bringing Sonnet 5 back to 98.9% at the same cost.

在搜索过程从未接触过的 14 个留出工单上，最终配置得分为 90.5%，而原始设置为 78.6%，成本约为原来的五分之一。

> On the 14 held-out tickets the search never saw, the final configuration scored 90.5% against the original setup's 78.6%, at about one fifth the cost.

#### **自动化降低成本**

> **Automating cost reduction**

提示缓存、指令和思考投入量是降低成本的常见手段。我们的[文档](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence#cut-spend-without-losing-quality)还涵盖了更多内容。为了对使用 Claude API 的应用代码进行全面的成本审计，我们新增了 `/claude-api cost-optimize`：它会剖析你的开销去向、施加成本削减措施，并且在你提供评估的情况下，展示节省的成本与性能之间的权衡关系。

> Prompt caching, instructions, and effort are common levers for reducing cost. Our[ documentation](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence#cut-spend-without-losing-quality) covers even more. To run a holistic cost audit of application code that uses the Claude API, we've added `/claude-api cost-optimize`: it profiles where your spend goes, applies cost reductions, and, if you provide an evaluation, shows how savings trade off with performance.

`cost-optimize` 首先要弄清楚你的 token 都花在了哪里：如果你有 Claude Admin API 密钥，可以查看你所在组织的[用量与成本报告](https://platform.claude.com/docs/en/manage-claude/usage-cost-api)；如果你的应用记录了日志，可以查看每个 API 响应中的 usage 对象；如果两者都没有，就只能阅读你构建请求的代码并进行估算。

> `cost-optimize` starts by finding where your tokens go: from your organization's[ usage and cost reports](https://platform.claude.com/docs/en/manage-claude/usage-cost-api) if you have a Claude Admin API key, from the usage object on each API response if your application logs it, or, failing both, by reading your request-building code and estimating.

随后，它会对可用的节省手段进行排序，从提示缓存开始，精简每个请求所携带的内容（包括一次提示审计），限制输出规模，并对无人值守的工作进行[批处理](https://platform.claude.com/docs/en/build-with-claude/batch-processing)。如果你提供了一套评估方案，它还会更进一步，计算不同投入水平和模型选择下的成本与性能。 

> It then ranks the available savings, starting with prompt caching, trimming what each request carries (including a prompt-audit), bounding output, and[ batching](https://platform.claude.com/docs/en/build-with-claude/batch-processing) unattended work. If you supply an evaluation, it goes further and computes cost and performance across effort levels and model choices. 

我们在四个公开基准上运行了该方法，并以 Sonnet 5 作为基线（图 7）：

> We ran this on four public benchmarks, starting with Sonnet 5 as a baseline (Figure 7):

- **LegalBench（成本降低约 58%）：** `cost-optimize` 提出在各任务间缓存共享前缀、将 effort 设为低档，并通过 Batch API 处理任务。思考 token 从 102,779 降至 8,284，但通过率仍在噪声范围内，成本下降约 58%。

> • **LegalBench (~58% lower cost): ** `cost-optimize` proposed caching a shared prefix across tasks, setting low effort, and processing tasks via the Batch API. Thinking tokens fell from 102,779 to 8,284, but pass rate stayed within noise and cost dropped by ~58%.

- **tau2-bench retail（成本降低约 73%）：**通过实现提示词缓存并显式放置断点，`cost-optimize` 在保持通过率不变的情况下将支出减少了 73%。

> • **tau2-bench retail (~73% lower cost): **By implementing prompt caching with explicit breakpoint placement, `cost-optimize` reduced spend by 73% while keeping pass rate flat.

- **OfficeQA Pro（成本降低约 52%）：**`cost-optimize` 增加了批处理和文档缓存，使成本从 $136.20 降至 $64.87。

> • **OfficeQA Pro (~52% lower cost): **`cost-optimize` added batch processing and document caching, which brought cost down from $136.20 to $64.87. 

- **SWE-bench Verified（成本降低约 55%）：** `cost-optimize` 发现默认配置已经能够正确进行缓存。节省来自将 effort 设置为 medium，并将智能体的输出限制为仅几句简洁的句子。每个任务的中位步数从 29 降至 17，提示词 token 从 75.2M 降至 33.7M。 

> • **SWE-bench Verified (~55% lower cost):** `cost-optimize` found that the default config already caches correctly. Savings came from setting effort to medium and constraining the agent’s output to just a few concise sentences. Median steps per task went from 29 to 17 and prompt tokens fell from 75.2M to 33.7M. 

‍

> ‍

![Figure 7. Cost and performance change across benchmarks with /claude-api cost-optimize.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a9f9120b5999192bd5d7463_d41ebc95.png)

#### **入门**

> **Getting started**

当你已迁移到前沿 Claude 模型，并想据此检查现有提示词时，可以从 `/claude-api prompt-audit` 开始。它会扫描你工作目录中的提示词、技能和工具描述。这些可以是调用 Claude API 的应用代码，也可以是 Claude Code 的配置（CLAUDE.md、技能）。它会移除那些拖累前沿模型的常见反模式。

> Start with `/claude-api prompt-audit` when you've migrated to a frontier Claude model and want to check your existing prompts against it. It scans the prompts, skills, and tool descriptions in your working directory. This can be application code that calls the Claude API or Claude Code's configuration (CLAUDE.md, skills). It removes common anti-patterns that hobble frontier models.

当你的应用使用 Claude API 并且你想做一次成本审计时，就用 `/claude-api cost-optimize`。它会分析 token 的花费情况，然后测试不同的调节手段：它会应用 prompt-audit，同时还会检查能否通过 prompt caching、把无人值守的工作批量处理，或限制输出长度来降低成本。如果你提供了一份评估，它会衡量投入程度与模型选择之间的权衡。

> Reach for `/claude-api cost-optimize` when your application uses the Claude API and you want a cost audit. It profiles token spend and then tests different levers: it applies prompt-audit, but also checks for ways to lower cost via prompt caching, batching unattended work, or bounding output. If you provide an evaluation, it measures the effort and model selection trade-offs.

最后，使用 `/claude-api hillclimb` 对成本和性能进行迭代搜索。给定一个评估集，Claude 会将其拆分为训练集和测试集，然后提出对你的应用的更新方案，目标是在保持基线性能的同时降低成本。Claude 会阅读训练集中失败的用例来指导搜索，最终配置会在留出的测试集上进行评分。

> Finally, use `/claude-api hillclimb` for an iterative search over cost and performance. Given an evaluation, Claude splits it into train and test sets, then proposes updates to your application that aim to reduce cost while maintaining baseline performance. Claude reads the failing train cases to guide the search, and the final configuration is scored on the held-out test set.

了解更多： 

> To learn more: 

- 请参阅我们的文档，[点击此处](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence#cut-spend-without-losing-quality)
- 请参阅我们的 cookbook，[点击这里](https://platform.claude.com/cookbook/cost-optimization-cost-optimization#prompt-caching)

> • See our documentation, [here](https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence#cut-spend-without-losing-quality)
> • See our cookbook, [here](https://platform.claude.com/cookbook/cost-optimization-cost-optimization#prompt-caching)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| prompt caching | 提示缓存 | 把提示前缀的预填充结果保存下来，后续相同前缀的请求直接读取而不重新计算。 |
| prefill | 预填充 | 模型生成回复前把输入提示处理为内部工作状态的阶段，是处理输入中开销最大的部分。 |
| KV cache | 键值缓存 | 预填充阶段产生并被保存复用的注意力键值张量状态。 |
| TTL | 存活时间 | 缓存条目在过期前可被读取的有效时长，Claude 提供 5 分钟与 1 小时两档。 |
| cache breakpoint | 缓存断点 | 在提示中标记的位置，其之前的内容会被写入缓存。 |
| defer_loading | 推迟加载 | 工具定义的一种标记，使其不进入缓存前缀，仅在被工具搜索找到时才追加到对话中。 |
| effort | 努力程度 / 思考强度 | 控制模型回答前投入多少斟酌、验证与备选探索的参数。 |
| thinking budget | 思考预算 | 早期模型中手动设定的推理 token 上限，属于升级到前沿模型后可能被拒绝的过时配置。 |
| compaction | 压缩 | 对已增长的对话内容进行精简重写的操作，会导致大部分缓存失效。 |
| Batch API | 批处理 API | 以批量方式提交无人值守请求的接口，用于以更低单价处理非实时任务。 |
| prompt-audit | 提示词审查 | claude-api 技能中的命令，扫描工作目录中的提示、技能与工具描述并移除反模式。 |
| hillclimb | 爬坡搜索 | claude-api 技能中的命令，基于训练集与测试集迭代搜索成本更低而性能不降的配置。 |
| cost-optimize | 成本优化 | claude-api 技能中的命令，剖析 token 开销来源并按序施加各类成本削减措施。 |
| few-shot examples | 少样本示例 | 提示中给出的示范样例，若针对旧模型失效模式调优则可能误导前沿模型。 |
| holdout set | 留出集 | 在配置搜索过程中从未被使用、仅用于最终评分的样本集合。 |
| cache hit rate | 缓存命中率 | 请求中成功读取到已缓存前缀的比例，是提示缓存效果的核心监控指标。 |
