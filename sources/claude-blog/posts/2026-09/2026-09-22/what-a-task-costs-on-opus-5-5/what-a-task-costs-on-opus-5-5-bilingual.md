# 在 Opus 5.5 上完成一项任务要花多少钱

> What a task costs on Opus 5.5

> 来源：Claude Blog / Anthropic，2026-09-22
> 原文链接：https://claude.com/blog/what-a-task-costs-on-opus-5-5
> 分类：AI 工程 / 大模型成本优化

## 核心要点

- 在 Claude Code 中，一项任务是一个循环，每一轮都会把此前的全部对话重新发送一次，因此轮次更多的模型即便单价相同也会更贵。
- 任务成本由四个因素决定：对话轮次、缓存读取比例、输出 token 类型（含思考 token），以及所选模型的单价。
- Opus 5.5 的 API 标价为每百万输入 token 4 美元、输出 20 美元、缓存读取 0.20 美元，输入与输出比 Opus 5 便宜 20%，缓存读取便宜 60%。
- 缓存命中率对输入成本影响最大，同样 280 万输入 token 在无缓存时为 11.20 美元，90% 命中率下约 1.62 美元，96% 命中率下约 0.99 美元。
- 在 Opus 5.5 上一个输出 token 的成本是缓存读取的 100 倍，思考过程按输出计费，即便界面只展示摘要也同样收费。
- effort 分为 low、medium、high、xhigh 四级（另有单次会话可用的 max），日常明确范围的工作建议用 medium，机械性编辑用 low，medium 卡住时升到 high。
- 更换模型、改动 effort 或思考设置、连接或断开 MCP 服务器、停顿超时以及对话压缩都会清除缓存并触发一次缓存写入。
- 建议把 Opus 5.5 作为可监督工作的日常主力，需要长时间无人值守或多子智能体协调时升级到 Fable 5.1，搜索、读日志等查找类子智能体则降级到 Sonnet 或 Haiku。
- /clear 清空对话不产生开销，/compact 保留连续性但消耗一次请求，在 150K token 处压实约需 0.25 美元、约十轮可回本，临近结束时压实则得不偿失。
- 一次内部客户支持基准测试显示，迁移到低 effort 的 Opus 5.5 使成本下降约 18%，运行 prompt-audit 移除仪式性指令后再降 9%。
- 文中所有数字均为示意，建议用 /usage 查看会话的缓存占比、输出与输入之比及总输入与对话规模之比，并在同一真实任务上对比不同模型的结果。

## 正文

#### 一项任务的成本，以及一次重试的成本

> The cost of a task, and the cost of a retry

你并不是一开始就打算买下数百万 token。你想做的是构建一个功能、完成一次迁移，或者跑完一项任务。token 数量只是模型为达成目标所需要的量。

> You don't set out to buy millions of tokens. You set out to build a feature, finish a migration, or run a task. The token count is whatever the model needed to get there.

两个每 token 单价相同的模型，在同一项任务上的花费可能相差很大。一个模型把代码读一遍。另一个读一遍、尝试修一次、再读一遍。每一步都是一轮，而每一轮都会把到目前为止的对话重新发送一次。所以需要更多轮次的模型花费更高，即便单价相同。

> Two models with the same cost per token can cost very different amounts on the same task. One reads the code once. The other reads it, tries a fix, and reads it again. Each of those steps is a turn, and each turn resends the conversation so far. So the model that needs more turns costs more, even at the same price.

读完这篇文章，你应该能回答关于自己工作的三个问题：

> By the end of this post you should be able to answer three questions about your own work:

- 在 Opus 5.5 上，我的典型任务要花多少钱？
- 哪些设置会改变这一点，影响有多大？
- 我该如何查看自己的会话用量？

> • What do my typical tasks cost me on Opus 5.5?
> • Which settings change that, and by how much?
> • How do I check my own session usage?

我想先说明的权衡是：每一种少花 token 的方法，也都可能让你付出一项任务无法完成的代价。降低思考强度、换用更小的模型或减少上下文，确实都能省下 token。而一次重试的代价会超过这些节省。本文试图为每一种权衡定出一个价格。

> The tradeoff I want to share upfront is that every way to spend fewer tokens can also cost you a finished task. Lower effort, a smaller model, or less context can all certainly save tokens. A retry costs more than those savings. This post attempts to put a price on each tradeoff.

这里有些数字是标价，有些是在标价基础上做的示意。图表是交互式的，阅读时可以自行更改输入。这些都是尽力而为的示意，请务必查阅我们的文档并自己核算。

> Some numbers here are list prices, and some are illustrations built from them. The figures are interactive, so change the inputs as you read. These are best effort illustrations, so be sure to check our docs and your own math.

#### 一项任务要花多少钱？

> What does a task cost?

Claude Code 中的一项任务是一个循环。模型读取对话、调用工具、读取结果，然后再来一轮，直到完成为止。循环的每一圈就是一次请求。有四个因素决定这个循环的成本。

> A task in Claude Code is a loop. The model reads the conversation, calls a tool, reads the result, and goes round again until it's done. Each trip round the loop is one request. Four things set what the loop costs.

**轮次。** 每一轮都会重新发送迄今为止的全部对话。轮次越少，需要处理的输入就越少。

> **Turns.** Every turn resends the conversation so far. Fewer turns means less input processed.

**缓存读取。** 一轮对话重新发送的内容，大部分是模型在上一轮就已经看过的文本。这部分按缓存读取计费，价格只是输入价格的一小部分。

> **Cache reads.** Most of what a turn resends is text the model saw on the previous turn. It's billed as a cache read, at a small fraction of the input price.

**输出 token 类型。**最昂贵的 token，价格是输入的五倍。[思考](https://platform.claude.com/docs/en/build-with-claude/extended-thinking)按输出计费，因此在得出答案的过程中推理较少的模型成本更低。

> **Output token type.** The most expensive tokens, at five times the input price. [Thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking) is billed as output, so a model that reasons less on the way to the answer costs less.

**模型。**每个模型都有自己的价格，列在定价页面上，因此你选择的模型决定了每个 token 的价格。

> **Model. **Each model has its own prices, listed on the pricing page, so the model you pick sets the price of every token.

我们的示例采用 Opus 5.5 API 的标价：每百万输入 token 4 美元，每百万输出 token 20 美元，每百万缓存读取 0.20 美元。与下文的计算器一样，这些示例按读取价格计算缓存输入的费用，其余部分按输入价格计算，并且不计入缓存写入。其中的 token 数量仅为示意。

> Our examples use Opus 5.5 API list prices: $4 per million input tokens, $20 per million output tokens and $0.20 per million cache reads. Like the calculator further down, the examples bill cached input at the read price and everything else at the input price, and leave out cache writes. The token counts are illustrations.

##### 轮次

> Turns

假设一个任务以 20K token 的上下文开始，随着模型读取文件和工具结果，增长到 120K。在 40 个回合中，平均每个回合发送约 70K token。这相当于该任务约 2.8M 输入 token，尽管对话本身从未超过 120K。如果 90% 从缓存读取，输入成本约为 1.62 美元。同样的任务如果用 25 个回合完成，则处理约 1.75M token，输入成本约为 1.02 美元。

> Let’s say a task starts with 20K tokens of context and grows to 120K as the model reads files and tool results. At 40 turns, the average turn sends about 70K tokens. That's about 2.8M input tokens for the task, though the conversation never grew past 120K. With 90% read from cache, the input costs about $1.62. The same task in 25 turns processes about 1.75M tokens and costs about $1.02 in input.

一次对话轮次的成本高于它新增的 token 数量，因为它会把此前的全部内容重新发送一遍。所以最省钱的轮次，就是你不需要的那一次。

> A turn costs more than the tokens it adds, because it resends everything before it. So the cheapest turn is the one you don't need. 

有一个能减少交互轮次的习惯，就是给模型提供一种检验自己工作成果的手段。比如可以运行的测试、构建流程，或者调用接口的脚本。能够检验自己工作的模型，会更早发现自己的错误。

> One habit that can cut turns is giving the model a way to check its work. For example, a test to run, a build, or a script that calls the endpoint. A model that can check its own work finds its mistakes earlier.

一个能在一次遍历中获取所需全部信息、并把工具调用批量化的模型，重发的次数也更少。

> A model that gathers what it needs in one pass, and batches its tool calls, pays the resend fewer times too.

##### 缓存读取

> Cache reads

同样的 280 万输入 token，如果全部不走缓存，费用是 11.20 美元。在 90% 的命中率下，费用为 1.62 美元；在 96% 的命中率下，约为 0.99 美元。没有其他设置能如此大幅地改变输入成本。一个稳定的会话本身就能保持较高的命中率。本文后面我会介绍一些应当避免的操作，以免破坏你的缓存。

> The same 2.8M input tokens cost $11.20 if none come from cache. At a 90% hit rate they cost $1.62, and at 96% about $0.99. No other setting moves input cost this much. A steady session keeps a high hit rate on its own. I cover some actions to avoid breaking your cache later in this post. 

##### 输出 token

> Output tokens

在 Opus 5.5 上，一个输出 token 的成本是缓存读取的 100 倍。一个典型任务的 6 万输出 token 花费 1.20 美元，相当于从缓存中读取 600 万 token。输出包括思考过程。这些你都要付费，即便 Claude Code 只向你展示一份摘要。这就是为什么 effort（它主要改变模型思考的多少）会对账单产生如此大的影响。

> On Opus 5.5, an output token costs 100 times a cache read. The 60K output tokens of a typical task cost $1.20, the same as reading 6M tokens from cache. Output includes thinking. You pay for all of it, even when Claude Code only shows you a summary. That's why effort, which mostly changes how much the model thinks, moves the bill so much.

##### 模型

> Model

缓存读取更便宜的模型主要有利于长会话。输出更便宜的模型则主要有利于需要大量推理的任务。

> A model with cheaper cache reads mostly helps long sessions. One with cheaper output mostly helps tasks that need a lot of reasoning.

#### Opus 5.5 有哪些变化

> What changed in Opus 5.5

有两件事发生了变化：价格，以及模型所做的工作量。

> Two things changed: the price, and how much work the model does. 

**每一项价格都更低了。**输入和输出 token 比 Opus 5 便宜 20%。缓存读取便宜 60%。输入价格下降，读取费率也随之下降，从输入价格的十分之一降到二十分之一。图 A 按每百万 token 对比了这两个模型。以上是 API 标价。在 Pro、Max 或 Team 套餐中，Opus 5.5 更低的价格会体现在你的用量限额上，包括缓存的上下文，因此额度比在 Opus 5 上大约多用 25%。缓存读取的额外降价是一项 API 价格调整。

> **Every price line is lower.** Input and output tokens are 20% cheaper than on Opus 5. Cache reads are 60% cheaper. The input price falls, and the read rate falls with it, from a tenth of the input price to a twentieth. Fig A compares the two models per million tokens. These are API list prices. On a Pro, Max or Team plan, the lower Opus 5.5 price is passed on to your limits, including cached context, so they go about 25% further than on Opus 5. The extra cut on cache reads is an API price change.

![Fig A. Price per million tokens.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab2b188d841f059a960ac69_fig-a-price-per-million.png)

对于 API 密钥来说，缓存读取的降价对 Claude Code 影响最大。一次长时间的智能体会话，其输入的大部分开销都花在缓存读取上。在下方图 B 所计价的会话中，缓存这一项从 1.00 美元降至 0.40 美元，是账单上降幅最大的一项。

> On an API key, the cache-read price cut matters most for Claude Code.  A long agentic session spends most of its input on cache reads. In the session priced in Fig B below, the cache line falls from $1.00 to $0.40, the largest drop on the receipt.

能省多少取决于你的工作形态。以缓存读取为主的会话，输入部分最多可省 60%。而一个没有缓存的简短提问配上很长的回答，最多只能省 20%，因为输出占了大头。大多数 Claude Code 任务介于两者之间。下方的计算器可以显示你的情况落在哪里。

> How much you save depends on the shape of your work. A session that is mostly cache reads can save up to 60% on input. A short question with no cache and a long answer can save up to 20%, because output dominates it. Most Claude Code tasks sit between the two. The calculator below shows where yours sits.

Opus 5.5 在回答时可以使用更多 token，因为它在回复前总是会先思考。我们预计人们在 Opus 5.5 上能完成更多工作，但这因任务而异，所以请在你自己的工作上进行衡量。** ** 图 C 比较了两个模型上每项任务的成本。这部分对你的工作的依赖程度远高于价格。

> Opus 5.5 can use more tokens on an answer, because it always thinks before it replies. We expect people to get more done on Opus 5.5, but it varies by task, so measure it on your own work.** ** Fig C compares cost per task on the two models. This part depends on your work far more than the price does.

在范围明确的任务上，两个模型完成所需的轮次大致相同，你得到的好处就只有降价这一项。差距应当在开放式任务上最大，因为模型可能会在错误的思路上耗费许多轮次。没有哪个单一数字适用于所有代码库，所以请自行测量（见最后一节）。

> On a well-scoped task, both models finish in about the same number of turns, and the price cut is all you get. The gap should be biggest on open-ended tasks, where a model can spend many turns on the wrong idea. No single number holds for every codebase, so measure it (see the last section).

**长时间的运行会以一份报告收尾。** Opus 5.5 在结束一次长时间运行时，会说明它改动了什么、发现了什么，以及需要你提供什么。这同样能省钱，因为当你能看到发生了什么时，你重跑一次会话的次数就会减少。

> **Long runs end with a report.** Opus 5.5 closes a long run with what it changed, what it found, and what it needs from you. That can save money too, because you rerun a session less often when you can see what happened.

#### 相同任务的并排对比

> The same tasks side-by-side

图 B 用相同的 token 数量在两种模型上对同一次会话进行计价。因此其中的差异只来自价格变动，别无其他。切换模型即可对比。图中的 token 数量仅作示意。

> Fig B prices one session on both models with the same token counts. So the difference is the price change and nothing else. Switch models to compare. The token counts are illustrative.

*图 B. 在两个模型上使用相同 token 的示例会话，因此这里体现的仅仅是价格变化。*

> *Fig B. Illustrative session with the same tokens on both models, so this is the price change alone.*

这份账单包含 /usage 为一次会话显示的三行数据。按 token 计算，缓存读取是最大的一项，为 2M。输出按 token 算是最小的一项，按费用算却是最大的一项。新鲜输入介于两者之间，它涵盖每个文件的首次读取和每次新的工具调用结果。

> The receipt has the three lines /usage shows for a session. Cache reads are the biggest line by tokens, at 2M. Output is the smallest by tokens and the biggest by cost. Fresh input sits between them. It covers the first read of each file and each new tool result.

图 B 为两个模型设定了相同的 token 数量，因此它单独反映了价格变化。你自己的会话在 Opus 5.5 上可能会使用更多或更少的 token。按这种方式计价，该会话的成本大约低 31%。

> Fig B gives both models the same token counts, so it shows the price change alone. Your own sessions can use more or fewer tokens on Opus 5.5.  Priced that way, the session costs about 31% less. 

录制一次运行会带来第二重效应，即模型工作量的变化。在存在错误起步的任务上，差距应当会拉大。试试你自己的数据

> A recorded run adds the second effect, the change in how much work the model does. On a task with a false start, the gap should widen. Try your own numbers

设置你的某一项任务所使用的数值，或者从预设开始。这些预设很有说明性，但我仍然建议你自己算一算。缓存输入按缓存读取价格计费，新输入按输入价格计费，因此缓存滑块显示的是差额中有多少来自缓存读取。

> Set what one of your tasks uses, or start from a preset. The presets are pretty illustrative but I’d still recommend doing your own math. Cached input bills at the cache-read price and fresh input at the input price, so the cache slider shows how much of the gap comes from cache reads.

要用真实会话数据填充这些滑块，请在任务结束时运行 /usage。Session 区块会给出输入、输出和缓存数据。最后一个滑块是你对 Opus 5.5 在你的任务上少做了多少工作的假设。如果只看价格变化，把它保持在 0%。要根据你自己的工作来设定它，方法如下：在 Opus 5 和 Opus 5.5 上运行同一个任务，然后比较轮次和输出 token 数。“自己动手测量”一节会逐步讲解这个过程，“读懂一次会话”一节则展示了在 /usage 中该查看哪些内容。 

> To fill the sliders from a real session, run /usage at the end of a task. The Session block gives input, output and cache figures. The last slider is your assumption about how much less work Opus 5.5 does on your tasks. Leave it at 0% for the price change alone. To set it from your own work, here's how: run the same task on Opus 5 and on Opus 5.5, and compare turns and output tokens. Measure it yourself walks through it, and Reading a session shows what to check in /usage. 

#### 让你的会话价值最大化的小贴士

> Tips for maximizing the value of your session

Opus 5.5 更低的价格让每个 token 的成本更低。你如何运行一个会话决定了你使用多少 token，而这些步骤会有所帮助。

> Opus 5.5’s lower price makes each token cost less. How you run a session decides how many tokens you use, and these steps help.

##### **先提高推理强度，再考虑更换模型**

> **Raise effort before you change models**

努力程度为模型在每一轮中花费多少 token 设定了一个总体倾向：包括它的思考、它写出的文本以及它的工具调用。在较低的努力程度下，它会进行更少的工具调用，并让这些调用更简短。Opus 5.5 有四个级别（low、medium、high 和 xhigh），另外还有可用于单次会话的 max。请在下方选择一个级别，查看何时使用它以及设置它的命令。

> Effort sets a general disposition for how many tokens the model spends on each turn: its thinking, the text it writes, and its tool calls. At lower effort it makes fewer tool calls and keeps them shorter. Opus 5.5 has four levels (low, medium, high and xhigh), plus max for a single session. Pick a level below to see when to use it and the command that sets it.

Claude Code 会为每个模型设置一个默认级别，运行 /effort status 可以查看你当前的级别。对于范围明确的日常工作，可以试试 **medium**。当 medium 陷入停滞时，可以试试 **high**。它每轮的开销比 medium 更高，但仍低于换用更大的模型。对于机械性的工作，比如重命名或在多个文件中套用已知的模式，请使用 **low**。

> Claude Code sets a default level for each model, and /effort status shows yours. Try **medium** for well-scoped, day-to-day work. When medium stalls, try **high**. It spends more per turn than medium, but less than moving to a bigger model. Use **low** for mechanical work, like renames or applying a known pattern across files.

粗略估算 effort 定价的一种方式：假设 high 在一个任务中额外增加 2 万个思考 token。在 Opus 5.5 上这相当于 0.40 美元。一个十轮的重试循环，每轮 10 万缓存上下文、总共 1 万输出 token，成本大致相同。所以在能省下一次重试的任务上，high 就能收回成本。而在 medium 本来第一次就能完成的任务上，这笔开销就浪费了。

> A rough way to think about effort pricing: say high adds 20K thinking tokens across a task. On Opus 5.5 that's $0.40. A retry loop of ten turns at 100K of cached context, with 10K output tokens in total, costs about the same. So high pays for itself on a task where it saves one retry. On a task medium would have finished the first time, it's wasted.

###### **当介质固定某一层时**

> **When medium fixes one layer**

最明显的信号是：某个修复只停留在单一层面，这说明你需要投入更多精力。

> The clearest sign you need more effort is a fix that stops at one layer.

假设某个 API 处理函数中有一个字段被重命名了。在中等推理强度下，模型会更新这个处理函数，该处理函数的测试通过了，而客户端仍在发送旧字段名。它完成了被要求做的事，只是读得不够远，没有找到第二个调用方。在高推理强度下，它会在动手写代码之前花更多轮次去阅读调用点，并在一次修改中同时改动两层。

> Say a field is renamed in an API handler. At medium, the model updates the handler, the handler's tests pass, and the client still sends the old field. It did what it was asked. It just didn't read far enough to find the second caller. At high, it spends more turns reading call sites before it writes, and it changes both layers in one pass.

检查同样能抓住这个 bug。如果模型能运行一个会走通客户端的测试，那么旧字段在写下它的那一轮就会让测试失败，在中等档位就能做到。所以在提高投入档位之前，先看看模型有没有办法检查自己的工作。跑一次测试的成本是一轮对话和它的输出。而提高投入档位会给每一轮都加上思考开销。

> A check can catch the same bug. If the model can run a test that goes through the client, the old field fails that test on the turn it was written, at medium. So before you raise effort, check whether the model has a way to check its work. A test run costs one turn and its output. More effort adds thinking to every turn.

如果提高努力等级和增加检查都不奏效，那就换用更大的模型。

> If upgrading effort levels and adding checks doesn’t work, then switch to a bigger model. 

###### **会话中途更改思考强度**

> **Changing effort mid-session**

在 Claude Code 中，运行 /effort 并附带一个级别，例如 /effort high。/effort status 会打印当前级别。你可以在任务进行中更改它，新级别将应用于下一个请求。

> In Claude Code, run /effort with a level, for example /effort high. /effort status prints the current level. You can change it mid-task, and the new level applies to the next request.

更改 effort 或 thinking 设置会清除缓存的对话，因为这些设置是缓存所匹配的提示词的一部分。下一次请求要为整个对话支付缓存写入的代价。

> Changing effort or thinking settings clears the cached conversation, because those settings are part of the prompt the cache matches. The next request pays the cache-write price on the whole conversation.

##### **为你的工作选择合适的模型**

> **Choose the right model for your work**

模型的选择决定了一次会话中每个 token 的价格，因此它对账单的影响比投入的精力更大。它的影响范围也更广。每个继承主模型的子智能体，同样继承了它的价格。大多数日子需要三种模型：一个小模型用于查询，Opus 5.5 用于你密切监督的工作，以及一个更大的模型用于最困难的任务。

> Model choice sets the price of every token in a session, so it moves the bill more than effort does. It also reaches further. Every subagent that inherits the main model inherits its price too. Most days need three models: a small one for lookups, Opus 5.5 for  work you supervise closely, and a bigger one for the hardest tasks.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab2b335fc4bd44bfd949d5e_fig-model-ladder.png)

###### **把 Opus 5.5 作为日常主力模型**

> **Opus 5.5 as the daily driver**

把 Opus 5.5 用于你能监督的工作：跨几个文件的功能开发、调试，以及带后续修改的代码审查。你会阅读它所做的事情，并在它跑偏时介入，因此反馈循环保持简短。升级到 Fable 5.1

> Use Opus 5.5 for work you supervise: feature work across a few files, debugging, and code review with follow-up edits. You read what it does and step in when it drifts, so the loop stays short. Moving up to Fable 5.1

**当结果比 token 价格更重要时，升级到 Fable 5.1。例如**你不会全程监督的长时间运行、代码库中没有现成范式可循的问题，以及需要协调多个子智能体的大规模改动。不要等到第三次失败。如果 Opus 5.5 在 high 档位上两次碰到同一个问题，就切换过去，问题解决后再切回来。对于交互式工作，Opus 5.5 更合适，因为它延迟更低、成本更低。

> **Move up to Fable 5.1 when the result matters more than the token price. For example **long runs you won't supervise, problems with no existing pattern in the codebase, and large changes that coordinate many subagents. Don't wait for a third failure. If Opus 5.5 on high hits the same problem twice, switch, and switch back once it's solved. For interactive work, Opus 5.5 is a better fit as it has lower latency and costs less.

Fable 5.1 的标价是每百万输入 token 10 美元、每百万输出 token 50 美元，是 Opus 5.5 价格的两倍半。它的缓存读取费用是每百万 0.25 美元，只有 Opus 5.5 费率的 1.25 倍，因为缓存读取按其输入价格的 0.025 倍计费。所以在缓存占比高的长时间运行中，两者差距最小；而在写入量大的任务上，差距最大。

> Fable 5.1 lists at $10 per million input tokens and $50 per million output, two and a half times the Opus 5.5 price. Its cache reads cost $0.25 per million, only 1.25 times the Opus 5.5 rate, because they bill at 0.025 times its input price. So the gap is smallest on a long, cache-heavy run, and largest on a task that writes a lot.

在自然的间断点切换。缓存属于此前的模型，所以要预料到在新模型上的第一轮会为整段对话支付写入价格。先运行 /compact，或者带着一份简短的书面计划开启一个全新会话，好让那一轮变小。运行 [/model](https://code.claude.com/docs/en/model-config) 并附上别名或模型名称即可切换。/model 还会把你的选择保存为新会话的默认值，所以在难点搞定后记得切回来。

> Switch at a natural break. The cache belongs to the previous model, so expect the first turn on the new model to pay the write price on the whole conversation. Run /compact first, or start a fresh session with a short written plan, to make that turn smaller. Run [/model](https://code.claude.com/docs/en/model-config) with an alias or a model name to switch. /model also saves your choice as the default for new sessions, so switch back when the hard part is done.

###### **为查找类任务降级**

> **Moving down for lookups**

**为查找类任务降级到 Sonnet 或 Haiku，而不是为写代码降级：**用于搜索和总结的子智能体、阅读日志和测试输出，以及“这个是在哪里定义的”这类问题。对于跨多个文件的机械性编辑，保留 Opus 5.5 并把 effort 设为 low。这样编辑仍然由那个编写你其余代码的模型来完成，而每轮成本更低。

> **Move down to Sonnet or Haiku for lookups, not for writing code:** subagents that search and summarize, reading logs and test output, and "where is this defined" questions. For a mechanical edit across many files, keep Opus 5.5 and set effort to low. The edit stays on the model that writes the rest of your code, at a lower cost per turn.

要让[子智能体](https://code.claude.com/docs/en/sub-agents)使用更小的模型，在其定义中设置 model: haiku 或 model: sonnet。要让所有子智能体都使用同一个模型，设置 CLAUDE_CODE_SUBAGENT_MODEL 环境变量。子智能体定义中指定的模型会覆盖该变量。没有 model 设置的子智能体会运行在你的主模型上，除非设置了该变量。

> To put a [subagent](https://code.claude.com/docs/en/sub-agents) on a smaller model, set model: haiku or model: sonnet in its definition. To put every subagent on one model, set the CLAUDE_CODE_SUBAGENT_MODEL environment variable. A model named in a subagent's definition overrides the variable. A subagent with no model setting runs on your main model, unless the variable is set.

每个子智能体都在自己的上下文窗口中运行，并回传一份摘要，因此它读取的文件不会进入你的主对话。它仍然要为自己的 token 付费，所以模型设置决定了这部分开销的成本。

> Each subagent runs in its own context window and hands back a summary, so its file reads stay out of your main conversation. It still pays for its own tokens, so the model setting decides what that spend costs.

权衡在于：一个误读了搜索结果的小模型，会把主模型引向错误的文件，而这段弯路的费用由主模型来承担。把小模型用在出错时容易被发现的工作上，比如查找文件、运行测试和阅读日志。

> The tradeoff: a small model that misreads a search result sends the main model after the wrong file, and the main model pays for the detour. Keep the small model on work where a mistake is cheap to spot, like finding files, running tests and reading logs. 

把需要判断力的决策留给主模型。opusplan 别名采用了另一种分工方式：Opus 在计划模式下制定计划，Sonnet 执行计划。这把代码编辑交给了 Sonnet，与上面的建议相反。在把它设为默认之前，先在你自己的任务上做一下衡量。

> Keep judgment calls on the main model. The opusplan alias splits the work a different way: Opus plans in plan mode, and Sonnet carries out the plan. That puts the code edits on Sonnet, the opposite of the advice above. Measure it on your own tasks before you make it a default.

##### **迁移时检查你的提示词**

> **Check your prompts when you migrate**

为较老模型编写的指令可能会让 Opus 5.5 写得更多、并重复调用工具。在 Claude Code 中运行 /claude-api prompt-audit，检查你的 Claude Code 配置（比如你的技能和 CLAUDE.md 文件）是否存在这些[提示词反模式](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform)。它也会检查你基于 Claude Platform 构建的应用的代码。

> Instructions written for an older model can make Opus 5.5 write more and repeat tool calls. Run /claude-api prompt-audit in Claude Code to check your Claude Code setup, such as your skills and CLAUDE.md file, for these [prompting anti-patterns](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform). It also checks the code of an app you build on the Claude Platform.

我们在一次从 Opus 4.8 到 Opus 5.5 的迁移中测试了这一点，使用的是一个包含 44 张工单的内部客户支持基准测试，其提示词中存在多个此类模式。迁移到 Opus 5.5（低 effort 档位）把该基准测试的成本削减了约 18%。运行 prompt-audit 又进一步削减了 9%，使其比 Opus 4.8 的起点低了约 25%。此次审计移除了那些让模型写得更多、重复调用工具的仪式性指令：一套强制的六步流程、一条草稿纸规则、一条二次校验规则，以及相互矛盾的指令。

> We tested this on a migration from Opus 4.8 to Opus 5.5, using an internal customer support benchmark of 44 tickets whose prompt had several of these patterns. The move to Opus 5.5, at low effort, cut the benchmark's cost by about 18%. Running prompt-audit cut it by a further 9%, to about 25% below the Opus 4.8 starting point. The audit removed ritual instructions that made the model write more and repeat tool calls: a mandatory six-step procedure, a scratchpad rule, a verify-twice rule, and instructions that contradicted each other.

![Fig D. Migration from Opus 4.8 at default effort to Opus 5.5 at low effort, with prompt-audit, on the customer support benchmark.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab2b2c575f4bb6ac9f4d52a_fig-d-prompt-audit_2.png)

该结果来自单个基准测试，因此应把它当作一个示例，而不是可以预期得到的数值。先运行审计，然后在真实任务上对比前后的 /usage（参见「自行测量」）。

> That result comes from one benchmark, so treat it as an example rather than a number to expect. Run the audit, then compare /usage on a real task before and after (see Measure it yourself).

##### **缓存与压实**

> **Caching and compaction**

Claude Code 会为你处理缓存和压缩。而你运行会话的方式，决定了它们能为你节省多少。

> Claude Code handles caching and compaction for you. How you run a session decides how much they save.

###### **缓存的工作原理**

> **How the cache works**

Claude Code 会缓存请求中重复的部分，例如系统提示词、工具定义以及到目前为止的对话内容。

> Claude Code caches the parts of a request that repeat, such as the system prompt, tool definitions, and the conversation so far.

在 Opus 5.5 上，一次缓存读取的成本为全新输入 token 的 5%。写入缓存的成本高于一次全新读取：按今天的定价，五分钟缓存为输入价格的 1.25 倍，一小时缓存为输入价格的两倍。每次命中都会免费重置其生存期。

> On Opus 5.5 a cached read costs 5% of a fresh input token. Writing to the cache costs more than a fresh read, at 1.25 times the input price for a five-minute cache and twice the input price for a one-hour cache, on today's pricing. Each hit resets the lifetime at no charge.

在 Claude Code 中，有效期取决于你的付费方式。使用 Claude 订阅时为一小时。使用 API 密钥或云服务商时，默认为五分钟；而订阅一旦开始消耗用量额度，也会降为五分钟。

> In Claude Code the lifetime depends on how you pay. On a Claude subscription it's an hour. On an API key or a cloud provider it's five minutes by default, and a subscription drops to five minutes once it's drawing on usage credits.

在 120K 令牌的上下文规模下，Opus 5.5 上一次五分钟的写入大约花费 0.60 美元，一次读取约 0.02 美元。一次写入的成本相当于 25 次读取。在 API 密钥上，六分钟的咖啡休息会把下一次 0.02 美元的读取变成 0.60 美元的写入。同等规模下一小时的写入大约花费 0.96 美元，而在 API 上，你可以支付这笔溢价来覆盖你一天中的各个空档。

> At 120K tokens of context, a five-minute write on Opus 5.5 costs about $0.60 and a read about $0.02. One write costs as much as 25 reads. On an API key, a six-minute coffee break turns the next $0.02 read into a $0.60 write. A one-hour write at the same size costs about $0.96, and on the API you can pay that premium to cover the gaps in your day.

###### **会话形态与命中率**

> **Session shape and hit rate**

缓存存储的是前缀，因此它只能复用请求中从开头开始与上一个请求相匹配的那部分。

> The cache stores a prefix, so it can reuse only the part of a request that matches the previous one from the start.

稳定的会话会在每一轮对话中把内容追加到对话末尾，从而保持较高的缓存命中率。任何改动请求靠前部分的操作都会降低命中率。修改工具定义会清空整个缓存，而修改系统提示词会清空从该处往后的缓存，也就几乎是全部内容。

> A steady session appends to the end of the conversation on every turn and keeps its hit rate high. Anything that changes an earlier part of the request lowers it. Changing the tool definitions clears the whole cache, and a change to the system prompt clears it from that point on, which is almost everything.

实际使用中，以下情况会触发缓存写入：

> In practice, expect a cache write when:

- 你的停顿时间超过了缓存的存活时长；
- 你更改了努力程度或思考设置（参见努力程度一节），这会清除已缓存的对话；
- 你连接或断开某个 MCP 服务器，这会改变每次请求开始时加载的内容；
- 你切换了模型，因为新模型从空缓存开始；以及
- 对话被压缩了，这会重写缓存所匹配的历史记录。

> • You pause longer than the cache lifetime;
> • You change effort or thinking settings (see the effort section), which can clear the cached conversation;
> • You connect or disconnect an MCP server, which can change what loads at the start of each request;
> • You switch models, since the new model starts from an empty cache; and
> • The conversation is compacted, which rewrites the history the cache matched.

所以在会话开始时把这些设置好，然后在它工作期间不要去动它们。

> So set these up when the session starts, and leave them alone while it works.

###### **为什么长会话的每轮成本更高**

> **Why long sessions cost more per turn**

每一轮都会重新发送整个上下文，因此随着上下文增长，单轮的成本也会上升，即使缓存是热的也一样。在 20K token 的上下文下，Opus 5.5 上一轮的缓存读取成本约为 0.004 美元。在 150K 时约为 0.03 美元，按这个规模算，30 轮仅读取就要花掉 0.90 美元。同样是 30 轮，在 20K 下约为 0.12 美元。在 Claude 4.6 及更新的模型上，更大的上下文窗口并不会改变每 token 的价格，因此成本完全来自重新发送对话内容。

> Every turn resends the whole context, so a turn costs more as the context grows, even with a warm cache. At 20K tokens of context a turn's cache read costs about $0.004 on Opus 5.5. At 150K it costs about $0.03, and 30 turns at that size spend $0.90 on reads alone. The same 30 turns at 20K cost about $0.12. On Claude 4.6 and later models a bigger context window doesn't change the price per token, so the cost comes entirely from resending the conversation.

其中很大一部分上下文都是早前工作留下的残余：一小时前的堆栈跟踪、一个你已经处理完的文件、一次测试运行的输出（而你此后已经修好了它）。这些内容在每一轮对话中仍然会被全部发送。

> Much of that context is left over from earlier work: a stack trace from an hour ago, a file you've finished with, the output of a test run you've since fixed. It's all still sent on every turn.

###### **压缩、/compact 与 /clear**

> **Compaction, /compact and /clear**

当会话接近上下文限制时，Claude Code 会对较早的历史记录进行摘要，从而让后续对话轮次发送更少的内容。运行 /autocompact 并附上 token 数量，即可更改在此之前上下文可以填充到多满。

> When a session gets close to its context limit, Claude Code summarizes older history so later turns send less. Run /autocompact with a token count to change how full the context gets before that happens.

有两个命令可以让你自己做到这一点。/clear 会清空对话且不产生任何开销，所以当你转向无关的工作时就用它。/compact 保留连续性，代价是一次请求。它会读取自己要总结的那段对话，而且你可以指定要保留什么，例如 /compact keep the failing test names and the schema change。

> Two commands let you do this yourself. /clear empties the conversation and costs nothing, so use it when you move to unrelated work. /compact keeps continuity and costs one request. It reads the conversation it summarizes, and you can say what to keep, for example /compact keep the failing test names and the schema change.

在 150K token 处执行压缩的大致费用约为 0.25 美元。这包括一次读取、几千个输出 token 的摘要，以及对更短上下文的一次新的缓存写入。之后每一轮大约能在读取上省下 0.025 美元，因此压缩大约在十轮之内就能收回成本。而在快要结束时才做的压缩，花掉的比省下的更多。

> A rough price for compacting at 150K tokens is about $0.25. That's the read, a summary of a few thousand output tokens, and a new cache write on the shorter context. Each later turn saves about $0.025 in reads, so the compaction pays for itself within about ten turns. A compaction just before you finish costs more than it saves.

摘要还会丢失细节。在调试过程中途做压缩，可能会把那条唯一关键的日志行给丢掉。请在自然的间歇处压缩；如果下一步依赖某个具体内容，就在 /compact 指令中说明。

> The summary also loses detail. A compaction in the middle of a debugging session can drop the one log line that mattered. Compact at a natural break, and when the next step depends on something specific, say so in the /compact instruction.

###### **你打字之前会加载什么**

> **What loads before you type**

你的 [CLAUDE.md 文件](https://code.claude.com/docs/en/memory)会在每次会话开始时加载进上下文，因此其中的每一行都会成为每一轮重新发送的内容的一部分。[成本文档](https://code.claude.com/docs/en/costs)建议把它控制在 200 行以内。MCP 工具定义是延迟加载的：开始时只加载工具名称和服务器说明，完整定义在该工具被使用时才加载。运行 /mcp 查看已连接哪些服务器，并关掉你不用的那些。

> Your [CLAUDE.md file](https://code.claude.com/docs/en/memory) loads into the context at the start of every session, so each line in it is part of what every turn resends. The [costs docs](https://code.claude.com/docs/en/costs) suggest keeping it under 200 lines. MCP tool definitions are deferred. Only tool names and server instructions load at the start, and a full definition loads when its tool is used. Run /mcp to see which servers are connected, and turn off the ones you aren't using.

###### **账单的其余部分**

> **The rest of the bill**

下表列出了影响 Claude Code 会话的其他计费规则，若有对应文档则附上链接。

> The table lists the other billing rules that affect a Claude Code session, with a link to the docs where one exists.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6ab2ae80d2ca2fafb3d3bdf6_a5a12df0.png)

#### 自己动手测量

> Measure it yourself

本文中的数字只是示例。你的代码库、提示词和使用习惯各不相同，所以要在你自己的任务上测量成本。下面是检查方法。

> The figures in this post are illustrations. Your codebase, prompts and habits are different, so measure cost on your own tasks. Here's how to check.

1. **在会话中运行 **[/usage](https://code.claude.com/docs/en/costs)**。**/cost 的作用相同。Session 区块会显示 token 用量和按标价估算的美元成本。一行 prompt-cache 信息会显示你的输入中有多大比例来自缓存。在 Pro、Max、Team 或 Enterprise 套餐下，同一屏还会显示你的套餐用量条。美元数字是在你本机按标价计算的，所以在订阅制下，它是衡量你做了多少工作的参考，而不是一张账单。
2. **把同一个任务跑两遍。**从你的待办事项中挑一件真事，别用玩具示例。用 /model 在 Opus 5 和 Opus 5.5 之间切换。记录每次运行的轮数、输出 token 和成本。做过三四个任务之后再下结论。
3. **对于团队，使用用量与成本报表。**[Claude Code Analytics API](https://platform.claude.com/docs/en/manage-claude/claude-code-analytics-api) 提供按用户估算的成本。[Usage and Cost API](https://platform.claude.com/docs/en/manage-claude/usage-cost-api) 则按模型、以及按缓存与非缓存 token 拆分支出。
4. **试试努力度阶梯。**把一个困难任务先用 medium 跑一遍，再用 high 跑一遍。把一个机械性任务用 low 跑一遍。

> 1\. **In a session, run **[/usage](https://code.claude.com/docs/en/costs)**.** /cost does the same thing. The Session block shows token use and an estimated dollar cost at list price. A prompt-cache line shows how much of your input came from cache. On a Pro, Max, Team or Enterprise plan, the same screen shows your plan usage bars. The dollar figure is computed on your machine at list price, so on a subscription it is a guide to how much work you did, not a bill.
> 2\. **Run the same task twice.** Pick something from your backlog, not a toy example. Use /model to switch between Opus 5 and Opus 5.5. Note turns, output tokens and cost for each run. Do three or four tasks before you draw a conclusion.
> 3\. **For a team, use the usage and cost reports.** The [Claude Code Analytics API](https://platform.claude.com/docs/en/manage-claude/claude-code-analytics-api) gives estimated cost per user. The [Usage and Cost API](https://platform.claude.com/docs/en/manage-claude/usage-cost-api) breaks spend down by model and by cached versus uncached tokens.
> 4\. **Try the effort ladder.** Run one hard task at medium and then at high. Run one mechanical task at low.

##### 读懂一次会话

> Reading a session

任务结束时，在 /usage 中检查三件事。

> Check three things in /usage at the end of a task.

- **缓存占比。**对于长会话，它应该很高。如果偏低，就去找找是不是有过长时间的停顿、更换了努力度或模型，或者中途接入了某个 MCP 服务器。
- **输出相对于输入。**一个小改动却产生大量输出，通常意味着努力度对该任务来说定得太高，或者模型在反复重试。
- **总输入相对于对话的规模。**如果总输入是对话规模的很多倍，说明这次会话经历了很多轮，值得把对话读一遍，找出循环重复的地方。

> • **Cache share.** For a long session it should be high. If it's low, look for a long pause, a change of effort or model, or an MCP server connected partway through.
> • **Output against input.** A lot of output on a small change usually means the effort level is too high for the task, or the model is retrying.
> • **Total input against the size of the conversation.** If the total is many times the size of the conversation, the session took many turns, and the conversation is worth reading to find where the loop repeated.

作为参照基准，Claude Code 成本文档给出的企业部署平均值约为每位开发者每个活跃日 13 美元，90% 的用户每个活跃日低于 30 美元。一次成本远高于你自己正常水平的会话，值得复盘。

> For a baseline, the Claude Code costs docs give an average across enterprise deployments of about $13 per developer per active day, and under $30 per active day for 90% of users. A session that costs well above your own normal level is worth reviewing.

#### 要点提醒

> Keep in mind

- 对范围明确的日常工作使用 medium 努力度。
- 给模型一个检查自己工作的途径，并在 plan 模式下启动跨文件的改动。
- 当 medium 卡住时，把努力度提到 high。在间歇处更改，因为切换可能产生一次缓存写入的开销。
- 如果 high 在同一个问题上卡了两次，换成 Fable 5.1。问题解决后再切回来。
- 把搜索和读日志的子智能体放在 Sonnet 或 Haiku 上。代码编辑保留在 Opus 5.5 上。
- 让长会话持续推进，这样它的缓存才能保持热度。
- 在互不相关的任务之间用 /clear，并在间歇处用 /compact，附上一条说明要保留什么。
- **最重要的一条：**在每个模型上跑一个真实任务，比较 /usage 的报告结果。值得信赖的是你自己的数字。

> • Use medium effort for well-scoped daily work.
> • Give the model a way to check its work, and start changes that span files in plan mode.
> • When medium stalls, raise effort to high. Change it at a break, since the change can cost a cache write.
> • If high hits the same problem twice, switch to Fable 5.1. Switch back once it's solved.
> • Put search and log-reading subagents on Sonnet or Haiku. Keep code edits on Opus 5.5.
> • Keep a long session moving, so its cache stays warm.
> • Use /clear between unrelated tasks, and /compact at a break with a note on what to keep.
> • **The one that matters most:** run one real task on each model and compare what /usage reports. Your own numbers are the ones to trust.

希望这篇文章对你有帮助。如果你的额度在 Opus 5.5 上并不比在 Opus 5 上撑得更久，请用 /feedback 告诉我们。 

> I hope this post was helpful. If your limits don’t go further on Opus 5.5 than on Opus 5, tell us with /feedback. 

延伸阅读：[有效管理成本](https://code.claude.com/docs/en/costs) · [模型配置](https://code.claude.com/docs/en/model-config) · [在 Claude Code 中选择 Claude 模型和努力度](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) · [努力度](https://platform.claude.com/docs/en/build-with-claude/effort) · [提示词缓存](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) · [最大化你的 Claude Code 会话价值](https://claude.com/blog/maximizing-the-value-of-your-claude-code-sessions)

> Further reading: [Manage costs effectively](https://code.claude.com/docs/en/costs) · [Model configuration](https://code.claude.com/docs/en/model-config) · [Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) · [Effort](https://platform.claude.com/docs/en/build-with-claude/effort) · [Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) · [Maximizing the value of your Claude Code sessions](https://claude.com/blog/maximizing-the-value-of-your-claude-code-sessions)

*感谢 Michael Segner、Kacie Jenkins 和 Molly Vorwerck 的审阅。*

> *With thanks to Michael Segner, Kacie Jenkins and Molly Vorwerck for their reviews.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| token | 词元 | 模型处理文本的最小计费单位，输入、输出与缓存分别按不同价格结算。 |
| prompt caching | 提示词缓存 | 将请求中重复的前缀内容缓存复用，以远低于输入价的费率重复读取。 |
| cache read | 缓存读取 | 命中缓存时按较低费率计费的输入部分，Opus 5.5 上为新鲜输入价格的 5%。 |
| cache write | 缓存写入 | 首次把内容写入缓存的操作，费率高于一次全新读取，五分钟缓存为输入价的 1.25 倍。 |
| cache hit rate | 缓存命中率 | 一次会话输入中来自缓存读取的比例，是决定输入成本的最主要变量。 |
| extended thinking | 扩展思考 | 模型在给出答案前的推理过程，其 token 按输出价格计费。 |
| effort | 努力程度／推理强度 | 控制模型每轮花费多少思考、文本与工具调用 token 的总体档位设置。 |
| turn | 对话轮次 | 智能体循环的一圈，即一次请求，会重新发送迄今为止的全部上下文。 |
| context window | 上下文窗口 | 单次请求中模型可容纳的全部 token 范围，其大小直接影响每轮重发成本。 |
| sub-agent | 子智能体 | 在独立上下文窗口中运行并回传摘要的辅助智能体，可单独指定所用模型。 |
| compaction | 压实／压缩 | 对较早对话历史进行摘要以缩短上下文的机制，可由系统自动触发或用 /compact 手动执行。 |
| MCP server | MCP 服务器 | 为会话提供外部工具的服务端，其连接状态变化会改变请求开头内容并使缓存失效。 |
| prompt anti-pattern | 提示词反模式 | 为旧模型编写、会诱使新模型写得更多或重复调用工具的冗余指令写法。 |
| plan mode | 计划模式 | 让模型先产出改动方案再执行的运行模式，适合跨文件改动的起步阶段。 |
| Usage and Cost API | 用量与成本 API | 按模型以及缓存与非缓存 token 拆分团队支出的报表接口。 |
