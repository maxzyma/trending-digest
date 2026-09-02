# 最大化你的 Claude Code 会话价值

> Maximizing the value of your Claude Code sessions

> 来源：Claude Blog / Anthropic，2026-08-14
> 原文链接：https://claude.com/blog/maximizing-the-value-of-your-claude-code-sessions
> 分类：AI 工程 / 智能体编码工具使用

## 核心要点

- 同一项已完成的编码任务，会因使用方式不同而产生不同的 token 花费，高效使用 token 的目标不是总量更少，而是让消耗集中在真正需要的内容上。
- 一个 token 的价格由三个因素决定：使用哪个模型、它是输入 token 还是输出 token、以及它是否命中缓存。
- 请求在 GPU 上分为预填充和解码两个阶段，解码逐个生成 token 因而占用更多计算时间，输出定价约为输入的 5 倍。
- 提示词缓存要求请求开头的 token 逐字匹配，缓存读取的费用是输入价格的 0.1 倍，写入缓存最多为普通输入的 2 倍但只发生一次。
- 切换 `/model`、`/effort`、快速模式或执行 `/compact` 都会改变缓存键或对话前缀，导致整段会话按全价重新预填充，因此应在会话开始或 `/clear` 之后再做这些调整。
- 缓存在订阅模式下一小时后过期、使用 API key 时五分钟后过期，恢复旧会话通常也已失去缓存，因此在长时间离开前执行 `/compact` 比离开后更便宜。
- 凡是进入对话的内容——Claude 读取的文件、命令输出——在此后的每一轮都会被重新发送，并持续占用上下文空间。
- 用 @ 提及文件可让文件在发送前直接附加到消息中，省去一次 Read 调用和可能的搜索，且每次对话只需提及一次以免附加重复副本。
- 超过 30000 字符的命令输出会被写入文件并只留预览，真正的问题在于低于该上限的冗长输出，可通过静默标志、tail 或 hook 来削减。
- 长会话的开销高于把同样工作拆分为多次短会话，任务之间应 `/clear`、同一任务阶段性完成后 `/compact`，`/rewind` 则可在不产生成本的情况下裁掉末尾轮次。
- 子智能体拥有独立的上下文窗口，只把答案返回主会话，适合处理会产生大量无需保留输出的工作，但对小任务而言属于额外开销。
- 在全新会话中运行 `/context` 可查看启动时已加载的内容，据此精简 `CLAUDE.md`、把工作流移入 skills、并用 `/mcp` 关闭不需要的服务器。

## 正文

#### 太长不看

> TL;DR

- **在任务之间运行 `/clear `。**这样可以防止先前无关的上下文被重新发送给模型，从而减少 token 用量。
- **在开始之前设置好你的模型和努力程度（effort level）。**在对话中途更改其中任何一项都可能使你的提示词缓存失效，从而增加 token 成本。
- **用 @ 提及文件，而不是直接写文件名。**文件会直接附加到你的消息中，这样可以省去一次 Read 调用，如果 Claude 还得去查找该文件，则还能省去一次搜索。
- **给输出冗长的命令加上静默标志，或者在子代理中运行它们。**命令输出会像文件一样被加入对话，并在本次会话的余下过程中一直留在那里。
- **在全新会话中运行一次 ****`/context`****。**它会显示已加载的内容（`CLAUDE.md`、MCP 工具定义），这样你就可以删掉任何不必要的部分。
- **`/compact`****，在你离开键盘休息之前。**提示缓存会在一小时后过期，而在它仍处于缓存状态时总结对话要便宜得多。

> • **Run `/clear `between tasks.** This prevents prior irrelevant context from being sent back to the model, which can reduce token usage.
> • **Set your model and effort level before you start. **Changing either one mid-conversation can bust your prompt cache, which can increase token cost.
> • **@-mention files instead of naming them. **The file gets attached to your message directly, which saves a Read call, or a search if Claude has to go find it. 
> • **Add quiet flags to noisy commands, or run them in a subagent. **Command output is added to the conversation just like a file, and stays there for the rest of the session.
> • **Run ****`/context`**** once in a fresh session. **It shows what's loaded (`CLAUDE.md`, MCP tool definitions), so you can cut out anything unnecessary.
> • **`/compact`**** before you take a break from your keyboard. **The prompt cache expires after an hour, and summarizing a conversation is much cheaper while it's still cached.

#### 价值最大化

> Maximizing value

直到不久之前，你用来写代码的工具都还是一口价（或者免费）。无论那天下午你修的是一个测试还是五十个，编辑器的价格都一样，所以单个任务本身其实并没有自己的价格。

> Until pretty recently, the tools you wrote code with were a flat fee (or free). Your editor cost the same whether you fixed one test or fifty that afternoon, so an individual task didn't really have a price of its own. 

而对于 Claude Code 这类智能体编码工具来说，答案是肯定的。同一项已完成的任务，也会因为你的使用方式不同而产生不同的花费。

> With agentic coding tools like Claude Code, it does. The same completed task can also cost different amounts depending on how you use it. 

在某一次会话中，Claude 读取测试文件以及它所覆盖的那个文件，做出修改，几轮交互之内就完成了。而在另一次会话中，它先在仓库里四处 grep，在抵达同样那两个文件的路上读了十几个文件，而且这些交互中的每一轮还会一并拖上今天早上以来在对话中读过的所有其他内容。

> In one session, Claude reads the test and the file it covers, makes the edit, and is done in a handful of turns. In another, it greps around the repo first, reads a dozen files on its way to the same two, and every one of those turns also drags along everything else that's been read into the conversation since this morning.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7f1946bc7cd69c4c8919db_be236b0d.png)

修复方案是一样的，但你为此花费的 token 数量不同，而且整个过程中模型还不得不去考虑十个它根本不需要的文件。

> It's the same fix, but you spent a different number of tokens on it, and the whole time the model was also having to think about ten files it didn't need.

高效使用 token 并不意味着整体上用得更少，而是要确保你所用掉的那些 token 都投向了你真正想要的东西。

> Being efficient with tokens doesn't mean using fewer of them overall. It means making sure the ones you do use go towards the thing you actually asked for.

那么我们先来看看是什么决定了一个 token 的价格，再看看是什么决定了一个会话发送多少个 token，并在此过程中看看这对你如何运行一个会话意味着什么。

> So let's look at what decides the price of a token, then what decides how many of them a session sends, and along the way, what that means for how you run a session.

#### **是什么决定了 token 的价格**

> **What decides the price of a token**

你按 token 计费，但实际上你付费购买的是推理:GPU(或 TPU,或该模型碰巧运行在其上的任何硬件)在你的 token 上运行模型所花费的时间。

> You're billed per token, but what you're actually paying for is inference: the time it takes a GPU (or a TPU, or whatever the model happens to be running on) to run the model over your tokens. 

有三个因素决定一个 token 占用多少时间：你运行的是哪个模型、它是输入 token（进入）还是输出 token（输出），以及它是否被缓存。

> Three things decide how much of that time a token takes: which model you're running, whether it's an input token (going in) or an output token (coming out), and whether it was cached.

##### 模型

> Model

更大的模型在输入和输出 token 上都会做更多的工作。哪种模型值得用于哪种工作本身就是一个话题，我们在 [Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code) 中讨论过。 

> A bigger model does more work on both input and output tokens. Which model is worth it for which kind of work is a topic on its own, and we covered it in [Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code). 

就本文而言，你只需要知道：接下来我们要讲的一切都会乘以模型的价格——当问题确实困难或模棱两可时使用更大的模型，当工作是例行公事时使用更小的模型。

> For this post, all you need to know is that everything else we're about to cover gets multiplied by the model's price: use a larger model when the problem is genuinely hard or ambiguous, and a smaller one when the work is routine.

![Curves are for illustration purposes only. They do not represent real benchmark data.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7f1946bc7cd69c4c8919de_da980737.png)

##### 输入与输出 token

> Input and output tokens

一个请求在 GPU 上会经历两个阶段，二者的开销并不相同。

> A request goes through the GPU in two phases, and they cost different amounts. 

首先，在预填充阶段，模型会读取你的请求和上下文：系统提示词、你的 `CLAUDE.md`、你的消息，以及此后添加到对话中的所有内容（Claude 读取过的文件以及它运行命令的输出）。这些就是你的输入 token。

> First, during prefill, the model reads your request and context: the system prompt, your `CLAUDE.md`, your message, and everything that's been added to the conversation since (the files Claude has read and the output of the commands it ran). Those are your input tokens.

然后，在解码阶段，它会写出输出 token：它的思考过程、它发起的工具调用，以及你看到的文本。这个过程一次生成一个 token；一段 200 个 token 的回复就是模型接连运行 200 次。按每个 token 计算，解码让 GPU 忙碌的时间要长得多，这也是输出定价大约是输入 5 倍的原因。

> Then, during decode, it writes output tokens: its thinking, the tool calls it makes, and the text you see. This happens one token at a time; a 200-token response is 200 runs of the model, one after the other. Per token, decode keeps the GPU busy for a lot longer, which is why output is priced at roughly 5x input.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7f1947bc7cd69c4c891a0f_c69dbb11.png)

一次会话中的很多输出 token 都是思考 token，而模型每轮思考多少，正是由 effort 级别控制的。和模型一样，你用 `/effort` 选定的级别也会保留下来，成为下一次会话的默认值。

> A lot of the output tokens in a session are thinking tokens, and how much thinking the model does per turn is what the effort level controls. Like the model, the level you pick with `/effort` sticks around as your default for the next session too.

> **提示：**在一个全新的会话中运行一次 `/model `和 `/effort`，看看你实际处于什么状态。两者都会记住你上次的选择，而你应当让这个决定是有意为之的。

> **Tip: **run `/model `and `/effort` once in a fresh session to see what you're actually on. Both remember whatever you picked last time, and you want that decision to be deliberate.

> **提示：**如果你已经知道某次会话就是干粗活，`MAX_THINKING_TOKENS=0` claude 会为那一次会话关闭思考（Fable 5 除外），这比 `/effort` low 还要低一档。

> **Tip: **if you already know a session is going to be grunt work, `MAX_THINKING_TOKENS=0` claude turns thinking off for that one session (except on Fable 5), which is the step below `/effort` low.

##### 提示词缓存

> Prompt caching

如果一个请求的开头 token 与服务器刚刚处理过的某个请求完全相同，那么这段共享前缀所对应的状态计算结果也完全相同，因此服务器可以把上次的结果保留下来，只对其后的部分做预填充。这就是所谓的提示词缓存（prompt caching）。

> If a request starts with exactly the same tokens as a request the server just saw, the state for that shared beginning comes out the same, so the server can keep it around from last time and only prefill whatever comes after it. This is called prompt caching.

从缓存中读取的费用是输入价格的 0.1 倍，因为服务器加载状态而不是重新计算它。把 token 写入缓存的费用比普通输入略高，最多可达 2 倍，因为服务器之后还要保存这些状态。但写入对每个 token 只发生一次，而 0.1 倍的读取会在此后的每一轮中发生。

> Reading from the cache costs 0.1x the input price, because the server loads the state instead of computing it. Writing tokens into the cache costs a bit more than normal input, up to 2x, since the server also has to hold on to the state afterwards. But the write happens once per token, and the 0.1x reads happen on every turn after it.

Claude Code 在每次请求时都会管理提示词缓存，无需手动开启任何设置。不过你有可能破坏它，因此了解如何避免这类成本激增很重要。

> Claude Code manages the prompt cache on every request, there's nothing to turn on. However you can break it, so it's important to know how to avoid these cost spikes.

假设我们输入「fix the failing test in `utils.test.ts`」。以下是 Claude Code 为此发送的内容：

> Say we type "fix the failing test in `utils.test.ts`". Here's what Claude Code sends for it:

1. Claude Code 会用系统提示词（其中包含工具定义）、你的 `CLAUDE.md` 以及你的消息组装出第一个请求，然后把它发送出去（输入 token）。此时缓存里还什么都没有，所以这些内容全部会被预填充并写入缓存。
2. 模型无法修复一个它没看到过的测试，于是它思考片刻，回应了一个针对 `utils.test.ts` 的 Read 调用（输出 token）。Claude Code 读取该文件，将其追加到对话中，然后把整个内容再次发送出去（输入 token）。这一次，请求 1 中的所有内容都以十分之一的价格从缓存中读回，唯一需要按全价预填充的是新增的部分：那个 Read 调用和那个文件。
3. 现在模型需要待测试的文件（输出）。又一次 Read，又一次追加，所有内容再次发送出去：请求 1 和 2 来自缓存，第二个文件按全价计费（输入）。
4. 模型返回一个 Edit（输出）。Claude Code 应用它，把结果追加进去，然后再把全部内容发送一次。情况还是一样：Edit 和它的结果是新的，排在它们前面的所有内容都是缓存读取（输入）。
5. 模型运行 `npm test `（输出）。Claude Code 追加测试输出，然后再次发送全部内容，其中测试输出是唯一的新增部分（输入）。
6. 测试通过，模型返回了一段简短的总结（输出）。没有工具调用意味着没有内容需要追加，也没有请求 6，因此我们完成了。

> 1\. Claude Code assembles the first request out of the system prompt (tool definitions included), your `CLAUDE.md`, and your message, and sends it off (input tokens). Nothing is in the cache yet, so all of it gets prefilled and written into the cache.
> 2\. The model can't fix a test it hasn't seen, so it thinks for a moment and responds with a Read call for `utils.test.ts` (output tokens). Claude Code reads the file, appends it to the conversation, and sends the whole thing again (input tokens). This time everything from request 1 is read back out of the cache at a tenth of the price, and the only thing prefilled at full price is what's new: the Read call and the file.
> 3\. Now the model wants the file under test (output). Another Read, another append, and everything goes out again: requests 1 and 2 from the cache, the second file at full price (input).
> 4\. The model responds with an Edit (output). Claude Code applies it, appends the result, and sends everything again. Same story: the Edit and its result are new, everything in front of them is a cache read (input).
> 5\. The model runs `npm test `(output). Claude Code appends the test output and sends everything again, with the test output as the only new part (input).
> 6\. The tests pass, and the model responds with a short summary (output). No tool call means nothing to append and no request 6, so we're done.

为了一个小小的修复，这就发出了五次请求，而其中每一次都包含了到那个时间点为止的整段对话。典型的一轮交互是极不对称的：输入是数万个 token，输出只有几百个。但在那一轮中，只有新增的部分才会按全价进行预填充。

> That's five requests for one small fix, and every one of them contained the entire conversation up to that point. A typical turn is lopsided: tens of thousands of tokens going in, a few hundred coming out. But only what's new in that turn gets prefilled at full price. 

这就是每一轮的全部账单：历史部分按缓存读取计费，新增内容按完整输入价格计费，响应则按输出价格计费。

> That's the whole per-turn bill: cache reads on the history, full input price on whatever's new, and the output price on the response.

> 这一点在订阅制下同样适用。你不会直接看到这些价格，但正是同样的这些请求在消耗你的额度。

> This applies on a subscription too. You don't see these prices directly, but the same requests are what draw down your limits.

缓存必须从请求的最开头开始逐字匹配，而请求总是按同样的顺序发出：先是工具定义，然后是系统提示词，最后是对话（`CLAUDE.md` 位于对话的最前面）。

> The cache has to match from the very start of the request forward, and requests always go out in the same order: tool definitions, then the system prompt, then the conversation (with `CLAUDE.md` at the front of it). 

如果该前缀中的任何内容发生变化，其后的所有内容都会被重新预填充。追加到对话末尾的工具结果是最理想的情况，因为它后面没有任何内容。真正让缓存作废的，是那些改动请求中更靠前部分的内容，或者改变缓存键所依据的内容：

> If anything in that prefix changes, everything behind it gets prefilled again. A tool result appended to the end of the conversation is the ideal case, since nothing is behind it. What throws the cache away is anything that changes the request further towards the front, or changes what the cache is keyed on:

- **`/model`**：每个模型都有自己的缓存，所以下一轮对话时，整个会话会按全价重新预填充一遍。（这也包括 opusplan，因为每次你进入或退出 plan 模式时它都会切换模型。）
- **`/effort:`** 努力程度也是缓存键的一部分，所以情况是一样的。这就是为什么 `/model `和 `/effort `都会在你于对话中途切换时要求你确认。
- **快速模式**：同样属于缓存键的一部分，而且重新预填充会按快速模式的价格计费，所以如果你打算开启它，就在一开始就开启。（再关掉它是免费的，就缓存而言。）
- **`/compact`**：对话会被替换成一段更短的内容，因此其中的任何部分都不再匹配（位于其前面的系统提示词得以保留）。只要旧对话仍在缓存中，撰写摘要本身的成本很低，所以在长时间中断之前做这件事，要比中断之后做便宜得多。
- **时间：**每一轮对话都会重置计时，但缓存在订阅模式下一小时后过期，使用 API key 时则是五分钟后过期（`ENABLE_PROMPT_CACHING_1H=1 `会将其延长为一小时）。如果间隔超过这个时间再回来，下一轮就会重新预填充整段对话。恢复一个旧会话几乎也总是如此：到那时缓存通常已经失效，而且系统提示词无论如何都会在启动时重新构建。

> • **`/model`**: every model has its own cache, so on the next turn the entire conversation gets prefilled again at full price. (This includes opusplan, which switches models every time you go in or out of plan mode.)
> • **`/effort:`** the effort level is part of what the cache is keyed on too, so it's the same story. It's why both `/model `and `/effort `ask you to confirm when you switch in the middle of a conversation.
> • **Fast mode**: also part of the key, and the re-prefill happens at fast mode prices, so if you're going to turn it on, turn it on at the start. (Turning it off again is free, cache-wise.)
> • **`/compact`**: the conversation gets replaced with a shorter one, so nothing in it matches anymore (the system prompt in front of it survives). Writing the summary itself is cheap as long as the old conversation is still in the cache, so it's a lot cheaper before a long break than after one.
> • **Time:** every turn resets the clock, but the cache expires after an hour on a subscription or five minutes on an API key (`ENABLE_PROMPT_CACHING_1H=1 `makes it an hour). Come back later than that, and the next turn prefills the whole conversation again. Resuming an old session almost always does too: the cache is usually gone by then, and the system prompt gets rebuilt at launch anyway.

这一切并不意味着你永远不该切换模型或思考强度。它的意思是，做这件事有代价低廉的时机——会话开始时，或紧接在一次 `/clear` 之后——也有代价高昂的时机，比如一段长对话的中途。

> None of this means you should never switch models or effort. It means there are cheap moments to do it, the start of a session or right after a `/clear`, and expensive ones, the middle of a long conversation.

> **提示： **如果最近这几轮对话走向了你不想保留的方向，可以` /rewind`回到它们之前，而不是运行 `/compact`。回退只会把这些轮次从末尾裁掉，因此它们之前的所有内容仍在缓存中，不会产生任何成本。而压缩会重写整个对话，所以总会产生一定成本。

> **Tip: **if the last few turns went somewhere you don't want to keep,` /rewind` to just before them instead of running `/compact`. Rewinding only cuts those turns off the end, so everything before them is still cached and it costs nothing. Compacting rewrites the whole conversation, so it always costs something.

#### **是什么决定了一个会话发送多少 token**

> **What decides how many tokens a session sends**

这里要知道的最重要的一点是，没有任何东西只被发送一次。凡是进入对话的内容，无论是 Claude 读取的文件，还是它运行的命令的输出，在此之后的每一轮都会被再次发送，直到会话结束。

> The main thing to know here is that nothing gets sent just once. Everything that ends up in the conversation, a file Claude read or the output of a command it ran, gets sent again on every turn after it, for the rest of the session. 

它是被缓存的，所以每次重新发送的成本都很低，但低成本不等于零成本，而且它每一轮都在占用上下文空间，模型思考时都得绕开它。

> It's cached, so each of those re-sends is cheap, but cheap isn't nothing, and it's taking up room in the context the model has to think around on every turn too.

这其实就是一次会话的完整成本模型：最终有多少 token 进入上下文，它们在其中停留了多少轮，以及你同时运行着多少个上下文。

> That's really the whole cost model of a session: how many tokens end up in the context, how many turns they stay there, and how many contexts you're running at the same time.

##### **最终进入上下文的内容**

> **What ends up in the context**

上下文中的一部分内容在你输入任何东西之前就已经存在了：工具定义、系统提示词、`CLAUDE.md`，以及启动时加载的其他各种内容。

> Part of what's in the context is there before you type anything: the tool definitions, the system prompt, `CLAUDE.md`, and whatever else gets loaded at startup.

> **提示**：在一个全新的会话里运行 `/context`，看看在你还没输入任何内容之前那里面有些什么。把 `CLAUDE.md` 限定为具体的指令，并将工作流相关的内容移到 skills 里，这样它们只在被使用时才会加载。如果本次会话中有你不需要的 MCP 服务器，用 `/mcp` 把它关掉。

> **Tip**: run `/context` in a fresh session to see what's in there before you've typed anything. Keep `CLAUDE.md` to specific instructions and move workflow-specific ones into skills, which only get loaded when they're used. If there's an MCP server you don't need in this session, turn it off with `/mcp`.

会话期间添加的几乎所有其他内容都是工具结果：Claude 读取的文件，以及它运行的命令的输出。

> Nearly everything else that gets added during the session is tool results: the files Claude reads, and the output of the commands it runs.

Claude 读多少内容，主要取决于它需要自己弄清楚多少东西。如果你说"测试挂了"，它首先得找出是哪些测试：grep 一两次，打开几个文件看看哪个相关，而所有这些结果在早已失去价值之后，仍然留在上下文里。

> How much Claude reads mostly comes down to how much it has to figure out on its own. If you say "the tests are failing", it first has to find out which tests: a grep or two, a few files opened to see which one is relevant, and all of those results stay in the context long after they've stopped being useful. 

“修复 `utils.test.ts` 中失败的测试”省去了搜索过程，只需为该文件花费一次 Read 调用，而“修复 `@utils.test.ts` 中失败的测试”连这次 Read 调用也不需要。

> "Fix the failing test in `utils.test.ts`" skips the searching and costs one Read call for the file, and "Fix the failing test in `@utils.test.ts`" doesn't cost the Read call either.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7f1b213f60488b546224d4_cab63270.png)

> **提示：**当你要引用某个文件时，用 @ 提及它，而不是输入路径。Claude Code 会在任何内容被发送之前把文件附加到你的消息里，因此它出现在最开始的那次请求中，而且不会为它产生 Read 调用。无论哪种方式，文件本身在上下文里占用的空间都是一样的，所以每次对话只需要提及一次：它会一直留在那里，而在之后的轮次里再次用 @ 提及它，通常会附加第二份副本。

> **Tip:** when you're referring to a file, @-mention it instead of typing the path. Claude Code attaches the file to your message before anything gets sent, so it's in the very first request and there's no Read call for it. The file itself takes up the same room in the context either way, so you only need to mention it once per conversation: it stays there, and @-mentioning it again on a later turn generally attaches a second copy.

另一个会占满上下文的东西是 Claude 运行的命令的输出。每当它运行你的测试、构建或 git log 时，无论打印出什么内容，都会像它读取的文件一样被追加到对话中，并且会在同样多的轮次里一直保留在那里。

> The other thing that fills up the context is the output of the commands Claude runs. Every time it runs your tests, a build, or a git log, whatever that prints gets appended to the conversation just like a file it read, and stays there for the same number of turns.

特别大的输出其实没问题：超过 30000 个字符后，Claude Code 会把输出写入文件，只在对话中放一段简短预览和文件路径（如果你想修改这一行为，`BASH_MAX_OUTPUT_LENGTH`）。

> Really big outputs are actually fine: after 30,000 characters Claude Code writes the output to a file and only puts a short preview and the path in the conversation (`BASH_MAX_OUTPUT_LENGTH` if you want to change it). 

问题出在低于这个上限的所有情况。一个逐行打印 400 个通过测试的测试运行器，其输出并未超出上限，而这 400 行现在成了此后每一轮对话的一部分。

> The problem is everything under that. A test runner that prints 400 passing tests one line at a time comes in under the limit, and those 400 lines are now part of every remaining turn. 

Claude 通常会用各种标志参数和 tail 帮你处理好这件事；如果你不愿意把这件事交给 Claude 决定，文档里有一个小的 hook，它会在命令运行前重写那些输出嘈杂的命令，这样返回的就只有重要的那几行。

> Claude will often take care of this for you with flags and tail, and if you'd rather not leave it up to Claude, there's a small hook in the docs that rewrites noisy commands before they run so only the lines that matter come back.

> **提示**：把你整天都在用的那两三条命令写进 `CLAUDE.md`，连静默标志一起写上，就照你自己敲的样子写（"用 `npx vitest run <file> --reporter=dot"` 运行单个测试文件）。这只是个很小的补充，但它能在此后的每次会话中省下一轮交互和几百行输出。

> **Tip**: put the two or three commands you run all day in `CLAUDE.md`, quiet flags included, the way you'd type them yourself ("run a single test file with `npx vitest run <file> --reporter=dot"`). It's a small addition, but it saves a turn and a few hundred lines of output in every session after it.

##### 它在那里停留多少回合

> How many turns it stays there

一次长会话的开销高于把同样的工作分散到几次短会话中，而且高出的幅度超出你的预期，因为第 40 轮同时也在重新阅读它之前的 39 轮。你希望会话中的上下文简短且相关，所以不要把一个任务的上下文带入下一个任务：开始新任务时`/clear `，同一任务的前半部分完成后`/compact`。

> One long session costs more than the same work spread over a few short ones, and by more than you'd think, because turn 40 is also re-reading the 39 turns before it. You want the context in your session to be short and relevant, so don't carry one task's context into the next: `/clear `when you start something new, and `/compact` when the earlier part of the same task is done.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7f1cdb7fb1ad2229b0afa5_92ab0ee2.png)

> **提示**：`/rename`，在你`/clear `之前——前提是你之后还想找回这个会话。当你`/compact`时，告诉它要保留什么，或者把一个 “Compact instructions” 小节放进`CLAUDE.md`，如果每次要保留的内容都一样的话。而如果你用的是 1M 模型，又更希望把自动压缩这道安全网放回原来的位置，`/autocompact 200k`可以把它恢复（需要 Claude Code v2.1.221+）。

> **Tip**: `/rename` before you `/clear `if you'll want the session back later. When you `/compact`, tell it what to keep, or put a "Compact instructions" section in `CLAUDE.md` if it's always the same thing. And if you're on a 1M model and would rather have the auto-compact safety net where it used to be, `/autocompact 200k` puts it back (needs Claude Code v2.1.221+).

也要留意那些不是你在打字时发生的轮次。`/loop` 会在你设置它的那个会话中作为一个完整轮次触发，每次都会带上整段对话，而如果距离上一轮已经超过一小时，还会再加上一次缓存未命中。请在另一个终端里开一个新会话，从那里运行这个循环。

> Keep an eye on turns that happen when you're not typing, too. A `/loop` fires as a full turn in the session you set it up in, carrying that whole conversation with it every time, and if it's been more than an hour since the last turn, it's a cache miss on top. Start a fresh session in another terminal and run the loop from there.

##### 子智能体

> Subagents

另一种把某些内容排除在你的上下文之外的办法，是让它发生在另一个上下文里，而这正是子智能体的用途。子智能体拥有自己的上下文窗口，有自己的系统提示词、工具，以及你的 `CLAUDE.md`，但没有你的对话内容。它自行运行自己的轮次，唯一会回到主会话的东西就是它的答案。其余的一切在它完成后都会被丢弃。

> The other way to keep something out of your context is to have it happen in a different one, which is what subagents are for. A subagent gets its own context window, with its own system prompt, the tools, and your `CLAUDE.md`, but not your conversation. It runs its own turns, and the only thing that comes back to the main session is its answer. Everything else is thrown away once it's done.

没有共享对话的坏处是，子代理有时不得不重新读取主会话已经拥有的内容，而且在这样做的过程中它还要为自己的轮次付费。对于小任务来说，这就纯粹是额外开销。

> The downside of not having your conversation is that a subagent sometimes has to re-read things the main session already had, and it's paying for its own turns while it does. For a small job it's just overhead. 

当一项工作会产生大量你不需要保留的输出时，比如通读一份日志，它就很划算。对于这类事情，Claude 常常会自己主动使用子代理；如果它没有这么做，你也可以直接要求（"用一个子代理来通读这份日志"）。只要记住：主会话只能拿回子代理选择汇报的内容。

> It pays off when a job produces a lot of output you don't need to keep, like going through a log. Claude will often reach for one on its own for that kind of thing, and you can ask for one directly when it doesn't ("go through this log in a subagent"). Just keep in mind that the main session only gets back what the subagent chose to report.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7f1cdb7fb1ad2229b0afaa_a653b369.png)

> **提示**：如果有一个吵闹的任务你反复地交出去，就给它一个属于自己的子智能体定义，配上 model: haiku（或 sonnet）。否则它会运行在你主会话所运行的任何模型上。

> **Tip**: if there's a noisy job you hand off over and over, give it a subagent definition of its own with model: haiku (or sonnet). Otherwise it runs on whatever your main session is running on.

#### 首先应该看哪里

> Where to look first

在以上所有内容中,有四件事值得关注,大致按其成本高低排序:

> Of everything above, four things are worth keeping an eye on, roughly in order of how much they cost:

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7f1dd4531c50c7022d5171_df696a6b.png)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| token | 词元 | 模型处理文本的最小计费与计算单位。 |
| prompt caching | 提示词缓存 | 服务器复用此前请求相同前缀的计算状态，从而降低预填充成本的机制。 |
| prefill | 预填充 | 模型读取请求与上下文、处理输入 token 的阶段。 |
| decode | 解码 | 模型逐个生成输出 token 的阶段。 |
| input token | 输入 token | 发送给模型的系统提示词、对话历史与工具结果等内容所对应的 token。 |
| output token | 输出 token | 模型生成的思考过程、工具调用与回复文本所对应的 token。 |
| effort level | 努力程度 | 控制模型每轮思考量的设置，会影响输出 token 数量并构成缓存键的一部分。 |
| thinking token | 思考 token | 模型在给出回答前进行推理时生成的输出 token。 |
| cache key | 缓存键 | 决定请求能否命中已有缓存的标识，包含模型、努力程度与快速模式等因素。 |
| context window | 上下文窗口 | 单次会话中模型可容纳的全部内容的容量上限。 |
| system prompt | 系统提示词 | 位于请求前部、包含工具定义等内容的固定指令部分。 |
| tool definition | 工具定义 | 描述模型可调用工具的结构说明，在请求中最先发送。 |
| subagent | 子智能体 | 拥有独立上下文窗口、只向主会话返回结论的辅助智能体。 |
| MCP | 模型上下文协议 | 用于接入外部服务器与工具的协议，其工具定义会占用启动时的上下文。 |
| hook | 钩子 | 在命令执行前后介入并改写行为的自定义脚本机制。 |
