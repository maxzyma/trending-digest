# 编程会话越来越长，占用的上下文也越来越多。Claude Opus 5.5 正是针对这一点而打造的。

> Coding sessions are longer and use more context. Claude Opus 5.5 is built with that in mind.

> 来源：Claude Blog / Anthropic，2026-09-24
> 原文链接：https://claude.com/blog/claude-opus-5-5-built-for-coding-sessions-that-use-more-context
> 分类：AI 编程 / 模型成本与上下文缓存

## 核心要点

- 对于按 token 计费的典型工作负载，Claude Opus 5.5 的运行成本估计比 Opus 5 低约 40%，且在运行时间更长、上下文更多的会话中成本差异最大。
- 2026 年 3 月至 9 月的 Claude Code 数据显示，Claude 每个提示的工作时长提升至 3.3 倍，模型调用次数增加 40% 以上，中断次数减少 68%。
- 每个请求的上下文增长了 2.6 倍，输入与输出 token 的比例从 189:1 上升到 324:1，开发者更多地连接工具服务器或使用技能，而较少直接粘贴文本。
- 按 token 计费的输入和输出价格降低了 20%，缓存 token 的读取价格降低了 60%，而缓存读取占据了智能体和编程工作成本的大部分。
- 过去六个月 Claude Code 新增的多项功能使未命中缓存的输入减少了 50% 以上，包括降低因刷新登录、中途添加指令或按需加载工具而破坏缓存的可能性。
- 对于 Opus 5.5 和 Fable 5.1 等较新模型，会话中途更改 effort 级别不会重置缓存，API 密钥和云服务商用户可设置一小时缓存有效期，子代理可直接复用父会话的缓存。
- 在开放式任务中，Opus 5.5 完成同一任务所需的轮次和工具调用可能更少，而在范围界定清晰的任务上轮次大致相同，主要收益来自降价。
- Opus 5.5 的输出生成速度比 Opus 5 快 30% 以上，这虽不减少 token 用量，但能缩短长时间运行时的等待。
- 开发者可通过 /usage 查看缓存读取占比，并通过在会话开始时选定模型、在离开前进行压缩以及为长会话设置一小时缓存有效期来保护缓存读取。

## 正文

我们估计，对于按 token 计费的典型工作负载，Claude Opus 5.5 的运行成本[比 Opus 5 低约 40%](https://www.anthropic.com/claude-opus-5-5)。对开发者而言，这些节省究竟*如何*累积起来至关重要。

> We estimate Claude Opus 5.5 [costs about 40% less](https://www.anthropic.com/claude-opus-5-5) to run than Opus 5 for typical workloads billed by token. For developers, exactly *how *those savings stack up matters. 

如果你按 token 付费，那么在运行时间更长、上下文更多的会话中，你会看到最大的成本差异——而这恰恰是过去六个月里越来越普遍的那类 Claude Code 会话。

> If you pay by the token, you will see the greatest cost difference for longer-running, higher context sessions–the exact type of Claude Code sessions that have become more prevalent in the last six months. 

本文将深入剖析 Opus 5.5 的运作机制，探讨它为何能在开发者当下（以及很可能未来）的编码方式中实现高性价比。

> This post will dive into the mechanics of what makes Opus 5.5 cost effective for how developers are coding today (and likely tomorrow).

#### **Claude Code 趋势**

> **Claude Code trends**

我们汇总了 2026 年 3 月至 9 月开发者使用 Claude Code 的整体数据。随着模型能力的提升，开发者部署智能体的方式也日益复杂。每个会话的提示数量一直保持稳定，但我们发现了一些有趣的行为：

> We've pulled aggregate data on how developers have been using Claude Code from March to September 2026. As model capabilities improve, developers have been deploying agents in increasingly sophisticated ways. The number of prompts per session has been steady, but we found some interesting behaviors:

- Claude 在每个提示上的工作时长提升至 3.3 倍，每个提示的模型调用次数增加了 40% 以上，中断次数减少了 68%。
- 开发者连接工具服务器或使用技能的可能性约为其他人的两倍，而将文本粘贴到提示词中的可能性则低三分之一。
- 每个请求的上下文增长了 2.6 倍。输入与输出 token 的比例从 189:1 上升到 324:1。

> • Claude works 3.3x longer on each prompt with more than 40% more model calls per prompt. There are 68% fewer interruptions.
> • Developers are about twice as likely to have a tool server connected or use a skill and a third less likely to paste text into a prompt.
> • Context per request has grown 2.6x. The input to output token ratio moved from 189:1 to 324:1.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab54d371474ec5e28cb0912_0dfedac7.png)

所有这些都表明，开发者正在让更勤奋、更了解情况的 Claude 去承担规模更大、更开放的任务。对于这类会话，上下文工程带来的经济影响会成倍放大。

> All of this points to developers aiming a harder working, better informed Claude toward bigger, more open-ended tasks. For these types of sessions, the economic impact of context engineering is compounded. 

简而言之，Claude 读取的 token 更多。你需要确保[你提供的所有上下文都是必要的](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)，并且[尽可能多的上下文是从缓存中读取的](https://claude.com/blog/maximizing-the-value-of-your-claude-code-sessions)。

> Simply put, Claude reads more tokens. You need to make sure [all the context you are providing is necessary](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models), and that [as much of that context as possible is reading from cache](https://claude.com/blog/maximizing-the-value-of-your-claude-code-sessions). 

#### **是什么让 Opus 5.5 在长时间、重上下文的会话中具备成本效益**

> **What makes Opus 5.5 cost effective for long, context heavy sessions**

有三项变化让长时间运行、上下文密集的会话更具成本效益：定价的变化、模型行为的变化，以及 Claude Code 框架（harness）的变化。下面逐一来看。

> There are three changes that make long-running, context-heavy sessions more cost effective: changes to pricing, model behavior, and the Claude Code harness. Let’s look at each.

##### **缓存很便宜**

> **Cache is cheap**

对于按 token 计费的用量，我们将输入和输出 token 的费用降低了 20%，并且*将读取缓存 token 的价格降低了 60%*。后一项降价意义重大，因为缓存读取占据了智能体和编程工作成本的大部分。

> For usage billed by the token, we reduced the cost of input and output tokens 20%, and *we dropped the price of reading a cached token 60%*. The latter reduction is significant because cache reads make up the majority of agentic and coding work costs. 

正如我们刚才讨论的，每个请求的上下文在六个月内增长了约 2.6 倍，这意味着节省的幅度正朝着有利的方向发展。对于按 token 计费的用户而言，同样的价格调整在如今的 Claude Code 流量上能节省的费用，要比六个月前更多，因为现在账单中有更大一部分来自被重复读取的上下文。

> And as we just discussed, context per request has increased roughly 2.6x in six months, which means savings are trending in the right direction. The same price change for those billed by token saves more on today's Claude Code traffic than it would have six months ago, because more of the bill is now re-read context. 

截至发布之日，Opus 5.5 上一个缓存 token 的成本仅为竞争模型的五分之一，而性能却优于它们。

> As of the publication date, a cached token on Opus 5.5 costs a fifth of what it does compared to competing models while outperforming them.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab54d381474ec5e28cb0920_7df87a60.png)

##### **Claude Code 更善于利用缓存**

> **Claude Code is better at using the cache**

这与其说是 Opus 5.5 特有的现象，不如说是我们过去六个月在 Claude Code 中新增的诸多功能共同作用的结果。根据我们刚才讨论的编码会话趋势，人们本会预期缓存未命中率上升，但事实恰恰相反。**未命中缓存的输入减少了 50% 以上。**

> This is less specific to Opus 5.5, and more the result of many of the Claude Code features we’ve added in the last six months. Given the coding session trends we just discussed, you would expect a higher rate of cache misses, but the opposite is true. **Input that misses the cache decreased by more than 50%. **

例如，我们让缓存更不容易因一些细小的操作（比如刷新登录）而被意外破坏。我们也让缓存更不容易因较大的操作而被破坏，比如在对话中途添加指令或按需加载工具。对于 Opus 5.5 和 Fable 5.1 等较新的模型，你现在可以在会话过程中更改 effort 级别，而无需重置缓存。

> For example, we made it harder to unintentionally break your cache with smaller papercuts like refreshing a login. We also made it harder to break with larger actions, like adding instructions mid-conversation or loading tools on demand. For newer models like Opus 5.5 and Fable 5.1, you can now change effort levels during your sessions without resetting your cache.

我们还让缓存在运行时间更长的会话和委派会话中更加实用。使用 API 密钥和云服务商的开发者现在可以将缓存有效期设置为一小时（订阅用户此前已可使用该功能），而派生出的子代理会直接复用父会话的缓存，无需为相同的上下文再次付费。

> We also made the cache more useful for longer-running and delegated sessions. Developers on API keys and cloud providers can now set a one-hour cache lifetime (which subscribers already had) and forked subagents start from the parent's cache instead of paying for the same context again. 

##### **同样的任务，更少的轮次**

> **The same task, but with fewer turns**

与其他模型相比，Opus 5.5 完成同一任务所需的轮次可能更少。Zeta Labs 发现，与 Opus 5 相比，它每项任务的轮次和工具调用次数更少，而成本却接近减半，完成的最难任务数量也翻了一倍。

> Opus 5.5 can need fewer turns than other models to accomplish the same task. Zeta Labs saw fewer turns and tool calls per task than Opus 5, but at nearly half the cost and twice as many of their hardest tasks completed.

这一点并非对所有任务都成立。在[《Opus 5.5 上一项任务的成本》](https://claude.com/blog/what-a-task-costs-on-opus-5-5)中，Addy 写道：“对于范围界定清晰的任务，两个模型完成所需的轮数大致相同，你得到的只有降价带来的好处。差距在开放式任务上应该最大，因为在这类任务中，模型可能会在错误的思路上耗费许多轮。没有哪个单一数字适用于所有代码库，所以要自己去测量。”

> This won't hold for every task. In [The cost of a task on Opus 5.5](https://claude.com/blog/what-a-task-costs-on-opus-5-5), Addy wrote, "On a well-scoped task, both models finish in about the same number of turns, and the price cut is all you get. The gap should be biggest on open-ended tasks, where a model can spend many turns on the wrong idea. No single number holds for every codebase, so measure it."

换句话说，简单、简短、机械性的任务所需的轮次不会变，而更长、更难的任务则让 Opus 5.5 有更大的空间避免把 token 浪费在错误的方法上。减少一个轮次甚至比一个缓存 token 更具成本效益。

> In other words, simple, short, and mechanical tasks will take the same amount of turns while longer, harder tasks have more potential for Opus 5.5 to avoid burning tokens on the wrong approach. A reduced turn is even more cost efficient than a cached token.

另外值得注意的是，尤其是在 Claude 长时间无人值守或不间断工作的情况下，Opus 5.5 的输出生成速度比 Opus 5 快 30% 以上。虽然这并不会提高缓存命中率，也不会减少 token 用量，但意味着在长时间运行时等待更少。

> Also worth noting, especially as Claude works longer unattended or uninterrupted, is that Opus 5.5 generates output more than 30% faster than Opus 5. While this doesn’t increase cache hit rate or use less tokens, it means waiting less on long runs.

#### **保护你的缓存读取**

> **Protect your cached reads**

随着智能体编程日趋成熟，各组织对开发者的要求已从不计代价地扩大规模，转变为高效地扩大规模。在 Claude Code 中运行 /usage，查看你的用量中有多少来自缓存读取。然后守住这个数字：

> As agentic coding has matured, organizations have shifted from asking developers to scale at all costs to asking developers to scale efficiently. Run /usage in Claude Code to see how much of your usage is cached reads. Then protect that number: 

- 请在会话开始时就选定模型，而不是中途切换，
- 在离开之前而不是之后进行压缩，并且
- 如果你使用的是 API 密钥或云服务提供商，请为长会话设置[一小时缓存有效期](https://code.claude.com/docs/en/prompt-caching#choose-the-ttl-yourself)。

> • Pick your model at the start of a session rather than switching midway, 
> • Compact before you step away rather than after, and 
> • If you're on an API key or cloud provider, set the [one-hour cache lifetime](https://code.claude.com/docs/en/prompt-caching#choose-the-ttl-yourself) for long sessions. 

请将 Opus 5.5 用于开放式、需要大量上下文的工作，这类工作最能让这些习惯的效果不断叠加放大；具体测算数据请参阅[在 Opus 5.5 上完成一项任务的成本](https://claude.com/blog/what-a-task-costs-on-opus-5-5)。

> Point Opus 5.5 at the open-ended, context-heavy work where those habits compound, and see [What a task costs on Opus 5.5](https://claude.com/blog/what-a-task-costs-on-opus-5-5) for the worked numbers.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| token | 词元 | 模型处理文本时的基本计量与计费单位。 |
| context | 上下文 | 模型在一次请求中可读取的全部输入信息。 |
| context engineering | 上下文工程 | 对提供给模型的上下文进行选择、组织和优化的实践。 |
| prompt caching | 提示缓存 | 复用先前请求中已处理的上下文以降低成本和延迟的机制。 |
| cache read | 缓存读取 | 从缓存中读取已存储上下文 token 的操作，通常按较低价格计费。 |
| cache miss | 缓存未命中 | 所需上下文不在缓存中而必须重新处理输入的情况。 |
| TTL (time to live) | 缓存有效期 | 缓存条目在失效前可保留的时间长度。 |
| harness | 框架 | 包裹模型并管理其工具调用、上下文与会话流程的运行环境。 |
| agent | 智能体 | 能够自主规划并调用工具以完成多步任务的模型系统。 |
| subagent | 子代理 | 由主会话派生、承担委派子任务的智能体实例。 |
| tool call | 工具调用 | 模型在执行任务过程中调用外部工具或函数的操作。 |
| turn | 轮次 | 模型与环境之间一次完整的请求与响应交互。 |
| effort level | effort 级别 | 控制模型在响应中投入推理量的可调参数。 |
| compaction | 压缩 | 将较长的会话历史浓缩为摘要以减少上下文占用的操作。 |
| skills | 技能 | 可按需加载、为智能体扩展特定能力的指令与资源包。 |
