---
source: claude-blog
source_url: https://claude.com/blog/claude-model-and-effort-level-in-claude-code
published_at: 2026-07-07
category: Claude Code
title_en: Choosing a Claude model and effort level in Claude Code
title_zh: 在 Claude Code 中选择模型与努力级别
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 1
source_image_count: 10
---

# 在 Claude Code 中选择模型与努力级别

> Choosing a Claude model and effort level in Claude Code

> 来源：Claude Blog，2026-07-07
> 原文链接：https://claude.com/blog/claude-model-and-effort-level-in-claude-code
> 分类：Claude Code

## 核心要点

- 模型选择决定了一组固定权重，也就是模型的整体能力范围与知识基础；上下文和引导只能影响单次回答，无法改变权重本身。
- 努力级别不只是「思考时间」，它控制 Claude 为你的请求投入多少总体工作量，包括读取多少文件、使用多少工具、以及在向你确认前推进多少步骤。
- 常规任务用较小模型，复杂或模糊的任务用较大模型；先使用每个模型的默认努力级别，再依据自己常做的工作类型作为整体偏好来调整，而非逐个任务微调。
- 若 Claude 已获得全部相关上下文、明显尽力尝试却仍出错，这是应换用更强模型的信号。
- 若 Claude 因跳过某个文件、没有运行测试、或中途放弃重构而出错，则应提高努力级别。
- 模型设置决定由哪组冻结权重处理请求，也决定每个输出 token 的成本；但它不决定生成多少 token。
- 从默认设置起步，再按需调节模型与努力这两个「旋钮」。

## 正文

核心要点：

> Key takeaways :

- Claude 模型选择决定了所用的固定权重集合，也就是模型的整体能力范围。虽然可以为模型提供上下文或加以引导，但模型的整体知识库和能力是固定的。
- 努力程度（effort）的含义不止是"思考时间"。它控制 Claude 对你的请求整体投入多少工作量，包括读取的文件数量、使用的工具，以及在向你反馈之前所采取的步骤数。
- 对较为常规的任务选择较小的模型，对更复杂或更模糊的任务选择较大的模型。先从每个模型的默认努力程度开始，并根据你所从事的工作类型将其作为一种总体偏好来调整，而不是逐个任务地调整。
- 如果 Claude 已经掌握了所有相关上下文、明显做了尝试，但仍然出错，这是应该选择更强模型的信号。如果 Claude 出错是因为跳过了某个文件、没有运行测试，或在重构进行到一半时放弃，那就选择更高的努力程度。

> • Claude model selection chooses the set of fixed weights, or the overall capability range of the model. While models can be provided context or steered, the model’s overall knowledge base and capabilities are set.
> • Effort means more than "thinking time.” It controls how much work Claude does on your request overall including the number of files read, tools used, and how many steps it takes before it checks back in with you.
> • Choose smaller models for more routine tasks and larger models for more complex or ambiguous tasks. Start with default effort levels for each model and tune as a general preference based on the type of work you do rather than task-by-task.
> • If Claude has all the pertinent context, clearly tried, and still got it wrong, that's a signal to pick a more capable model. If Claude got it wrong by skipping a file, not running the tests, or bailing on a refactor partway through, pick a higher effort level.

### Claude Code 的努力级别与模型选择

> Claude Code effort levels and model selection

Claude Code 提供了两个看起来能"让答案更好"的设置：模型设置和努力级别（effort level）。你可能会以为，像 Claude Fable 5 这样更大的模型会给出比 Claude Sonnet 更聪明的输出，而更高的努力级别意味着 Claude 在回答前会思考得更久。

> Claude Code gives you two settings that appear to "make the answer better": the model setting and the effort level. You may expect that larger models like Claude Fable 5 provide a smarter output than Claude Sonnet, and a higher effort level means Claude thinks longer before it answers.

第一个假设是准确的。根据行业标准基准测试，我们最大的模型能力更强。

> The first assumption is accurate. Our largest models are more capable, according to industry-standard benchmarks.

但努力级别的含义不只是"思考时间"。它控制的是 Claude 为你的请求所做工作的总量。这确实包括模型思考的时长，但还包括：

> But effort means more than just "thinking time." Effort level controls how much work Claude does on your request overall. This does include how long the model thinks, but also:

- 它读取多少文件；
- 它做多少验证；以及
- 在与你确认之前，它会把一个多步骤任务推进到多远。

> • How many files it reads;
> • How much it verifies; and
> • How far it pushes through a multi-step task before checking in with you.

在较高的努力级别下，Claude 会在回到你面前之前采取更多这类行动（例如读取文件、运行测试、反复核查）。在较低的努力级别下，它更倾向于向你索要更多背景信息，而不是消耗 token 自己去搞清楚某件事。

> At a higher effort, Claude will take more of those actions (for example, read files, run tests, and double-check) before it comes back to you. At lower effort, it would rather ask you for more context than spend tokens figuring something out on its own.

### 模型选择的工作原理

> How model selection works

当你按下回车时，Claude Code 会把你的消息与系统提示词、工具定义、你的 CLAUDE.md、对话历史以及上下文中的所有文件组装在一起。所有这些作为一个请求发送到 API。

> When you press enter, Claude Code assembles your message together with the system prompt, tool definitions, your CLAUDE.md, the conversation history, and any files in context. All of this is sent as one request to the API.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe674684f_1a1b01b4.png)

不过，模型看到的从来不是纯文本。服务器上发生的第一件事是分词（tokenization）；文本被切分成若干片段，每个片段被映射为模型训练时所用固定词表中的一个整数。const 可能映射为 1978，await 可能映射为 4293。从此刻起，你的提示词就是一个整数数组。

> The model never sees that as plain text, though. The first thing that happens on the server is tokenization ; the text is split into pieces, and each piece is mapped to an integer from a fixed vocabulary the model was trained with. const might map to 1978, await might map to 4293. From here on, your prompt is an array of integers.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe674684c_32d50939.png)

模型的任务就是接过这个数组，预测下一个 token 是什么。它的做法是为词表中每个 token 计算一个概率，然后从概率最高的里面挑选。在 const x = await 之后，一个训练良好的模型会给 fetch 很高的概率（非常可能），而给 banana 接近零的概率（完全不可能）。

> The model's job is to take that array and predict which token comes next. It does this by computing a probability for every token in its vocabulary and picking from the top. After const x = await, a well-trained model puts high probability on fetch (very likely) and near-zero on banana (not likely at all).

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe6746855_41fef15e.png)

把你的输入 token 转化为这些概率的，是权重（weights，也称参数 parameters）。这是数十亿个数字，组织成一批大型矩阵。为了预测一个 token，模型让你的输入穿过这些矩阵，进行一长串矩阵乘法，并在末端读出概率。模型所"知道"的一切都存在于权重之中。

> What turns your input tokens into those probabilities is the weights (also called parameters ). These are billions of numbers organized into large matrices. To predict one token, the model runs your input through those matrices, a long chain of matrix multiplications, and reads the probabilities at the end. The weights are where everything the model "knows" lives.

每个模型的权重都是在训练期间确定的，等到你发送请求时，它们已经是只读的了。你的提示词、你的 CLAUDE.md 或你的上下文中，没有任何东西能改变它们。（如果你遇到过推理（inference）这个词，它指的就是这件事：在训练完成、权重固定之后使用模型。）

> The weights of each model are set during training, and by the time you're sending requests they're read-only. Nothing in your prompt, your CLAUDE.md, or your context changes them. (If you've run into the word inference, that's all it means: using the model after training is done, with the weights fixed.)

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe6746852_ac6d87ee.png)

Claude 关于 TypeScript、流行框架、地道的 Go 写法，或任何其他通用编程知识所知道的一切，都是在训练时编码进这些权重里的。

> Everything Claude knows about TypeScript, popular frameworks, idiomatic Go, or any other general programming knowledge, was encoded into those weights at training time.

你的提示词和上下文仍然可以引导预测（把你真实的代码摆在 Claude 面前就是一种引导，而且效果非常好），但它们不会给权重本身添加任何东西。

> Your prompt and context can still steer the prediction (putting your real code in front of Claude is steering , and it works really well), but they don't add anything to the weights themselves.

如果某个库在模型训练时还不存在，它就不在权重里。你可以把文档放进上下文，Claude 会使用它，但那是引导，而不是教学。Claude 的回答只会在那次请求中受到影响；底层模型并没有记住这些信息。

> If a library didn't exist when the model was trained, it isn't in the weights. You can put the docs in context and Claude will use them, but that's steering , not teaching . Claude’s response will only be influenced for that request; the underlying model hasn’t retained the information.

所以，当 Claude 自信地调用一个并不存在的 API 时（一种幻觉），那是权重在依据训练模式生成一个看起来貌似合理的 token 序列，而不是一次失败的查找。

> So when Claude confidently calls an API that doesn't exist (a hallucination), that's the weights producing a token sequence that looks plausible from training patterns, not a failed lookup.

那么，切换模型实际上做了什么？它替换了处理你请求的那套冻结权重。

> So what does changing the model actually do? It swaps which set of frozen weights handles your request.

模型并不是一次性生成整个答案。它预测一个 token，把它追加到序列中，然后再次运行整个计算以得到下一个。一个 200 token 的回答就是 200 次分别穿过权重的过程。这个循环正是你大部分等待时间和输出成本的来源。

> The model doesn't generate a whole answer at once. It predicts one token, appends it to the sequence, and runs the whole computation again to get the next one. A 200-token response is 200 separate passes through the weights. This loop is where most of your wait time and your output cost come from.

![Image 5](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe674685d_45cfd994.png)

所以，模型设置决定了由哪套权重来处理你的请求，同时也决定了每个输出 token 的成本。

> So the model setting decides which weights handle your request, and it also decides what each output token costs.

它不决定的是生成多少个 token。对于同一个提示词，这个数字可能变化很大，取决于 Claude 决定做多少工作。

> What it doesn't decide is how many tokens get generated. That number can vary a lot for the same prompt, depending on how much work Claude decides to do.

这正是努力级别（effort level）所控制的：Claude 在每一轮里决定做多少工作。

> This is what effort level controls: how much work Claude decides to do for each turn.

### 效力（effort）如何运作

> How effort works

当 Claude Code 处理任务时，它生成的 token 大致分为几类：

> When Claude Code is working on a task, the tokens it generates fall into a few categories:

- 思考（Thinking）：你在动作之前和之间看到流式输出的推理过程。
- 工具调用（Tool calls）：结构化的代码块，指明某个工具（如 Read 或 Edit）及其参数，随后由 Claude Code 解析并执行。
- 对你的文本：计划、进度更新，以及结束时的总结。

> • Thinking : the reasoning you see streaming before and between actions.
> • Tool calls : structured blocks naming a tool like Read or Edit and its arguments, which Claude Code then parses and executes.
> • Text to you : the plan, progress updates, the summary at the end.

这些都是来自同一循环的普通输出 token，按相同费率计费。例如，思考 token 与其他输出 token 的生成方式完全一样，并在该轮剩余过程中保留在上下文中。

> These are all ordinary output tokens from the same loop, billed at the same rate. For example, thinking tokens are generated exactly like the other output tokens and stay in context for the rest of that turn.

当 Claude 转向编写代码时，它先前的推理就成为输入的一部分，就像它读取过的一个文件一样。

> When Claude moves on to writing code, its earlier reasoning is part of the input just like a file it’s read.

![Image 6](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe6746860_ab0cbec6.png)

效力如何改变这一切？效力级别作为请求的一部分发送给模型，就紧挨着你的提示词。模型经过训练，理解在每个效力级别下应如何表现，而这种习得的行为已固化在冻结的权重中。

> How does effort change any of this? The effort level is sent to the model as part of the request, right alongside your prompt. The model was trained to understand how to behave at each effort level and that learned behavior is baked into the frozen weights.

当你的请求到达时，效力级别只是模型响应的又一个输入，就像它响应你的提示文本一样。这设定了 Claude 的行为：在认为任务完成之前，它需要多彻底、多确定。

> When your request arrives, effort level is one more input the model responds to, the same way it responds to your prompt text. This sets Claude’s behavior for how thorough and certain it needs to be before it considers the task done.

这一点在每一轮都会被考量，并会产生更多 token 以给出置信度更高的答案。

> This is considered on every turn and results in more tokens to produce higher confidence answers.

![Image 7](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe6746865_c62704ad.png)

在较高的效力级别下，Claude 往往先创建一个计划，而效力级别会影响该计划的深度和广度。不过，计划并非一成不变。随着 Claude 收到其动作的结果，它会更新已取得的进展，以及对累积结果的确定程度。

> At higher effort levels, Claude often starts with creating a plan and the level of effort influences the depth and breadth of that plan. However, the plan is not frozen in place. As Claude receives results from its actions, it updates the progress that has been made and how certain it is of the accumulated result.

因此，当一个包含三个假设的调试计划在第 1 步就找到了 bug，"调查假设 2 和 3"可能就不再是必要的动作。Claude 通常会明确说明这一点，"第一次检查就找到了，所以剩下的检查不需要了"，然后跳过。你在 Claude Code 中会看到这种情况：任务列表在运行途中被修订。

> So when step 1 of a three-hypothesis debugging plan finds the bug, "investigate hypotheses 2 and 3" may no longer be necessary actions. Claude will typically say this explicitly, "the first check found it, so the remaining checks aren't needed" and skip ahead. You see this happen in Claude Code when task lists get revised mid-run.

在较高的效力级别下，Claude 会更倾向于复核额外的假设或验证正确性，但对于简单任务，它一般不会在较高效力级别下人为地虚增用量。事实上，我们的团队在模型训练中高度关注"过度思考"，因为它会削弱有效性。

> Claude will be more predisposed to double-checking additional hypotheses or verifying correctness at higher effort levels, but it generally won’t artificially inflate usage for simple tasks at higher effort levels. In fact, our team pays close attention to “overthinking” during model training as it degrades effectiveness.

### 选择努力级别

> Picking an effort level

我们的建议是，对大多数任务应使用模型的默认努力级别（default effort level）。默认级别是指 Claude 会根据大多数人愿意在某项任务上花费的量来相应调整其 token 用量的级别。

> Our guidance is that for most tasks you should use the model’s default effort level . The default is the level where Claude will scale its token usage according to what most people would want to spend on a task.

把努力级别看作一个手动调节项，用来控制 Claude 工作的强度和时长。当你基于自己的领域或工作类型，对彻底性或速度有明确偏好时，再有意识地选择它。请把它更多地当作一种总体偏好，而不是逐个任务的决策。

> Think of effort as a manual override to scale how hard and long Claude works. Choose it deliberately when you have a strong preference for thoroughness or speed based on your domain or the type of work you do. Consider this more as a general preference than a task-by-task decision.

在 Claude Opus 4.8 发布之后，有一些实用的观察也许能给你一些指引：在我们的测试中，我们发现当你为 Opus 4.8 使用默认努力设置时，对于同一任务，相比为 Opus 4.7 使用默认努力设置，它能在大致相同的 token 数量下产生更好的结果。

> Some practical insight that may help guide you following the launch of Claude Opus 4.8 : in our testing we found when you use the default effort setting for Opus 4.8, it will produce better results for about the same number of tokens when compared to using the default effort setting of Opus 4.7 for the same task.

### 当 Claude 出错时该改什么

> What to change when Claude gets it wrong

当 Claude 出错时，你的第一反应不应该是去调整某个旋钮，而是检查你提供的上下文。你的提示词是否太模糊？Claude 是否连接了正确的工具？是否配备了正确的技能（skill）？

> When Claude gets something wrong, your first instinct shouldn’t be to adjust a knob, but to examine the context you have provided. Is your prompt too vague? Is Claude connected to the right tools? Equipped with the right skills?

如果你在一个本不需要更高投入的任务上提高了投入度（effort），修正的关键往往在上游——在你的上下文、你的 CLAUDE.md，或任务的界定方式里。

> If you're increasing effort on a task that shouldn't need it, the fix is often upstream, in your context, your CLAUDE.md, or how the task is scoped.

但假设你已经提供了清晰的上下文，而 Claude 仍然出错，那你该问自己的问题是：它是不够努力，还是知道得不够多？

> But assuming you have provided clear context and Claude still gets something wrong, the question to ask yourself is: did it not try hard enough, or did it not know enough?

![Image 8](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe6746868_e1c52525.png)

#### 模型：问题太难了

> Model: The problem was too hard

当问题确实很难时，选更大的模型。例如，隐蔽的 bug、陌生的领域，或架构决策这类问题。当较小的模型无论你给多少上下文都自信地犯错时，更大的模型会有帮助。

> Pick a larger model when the problem is genuinely hard. For example, problems like subtle bugs, unfamiliar domains, or architecture decisions. A larger model is helpful for situations where the smaller model is confidently wrong no matter how much context you give it.

更大的模型也更擅长处理模糊性，而在较小的模型上，用具体指令来指挥执行才是成功的更好配方。

> Larger models are also better at handling ambiguity, whereas specific instructions directing execution are a better recipe for success on the smaller models.

当工作是常规性的时候，选更小的模型。例如，你能精确描述的编辑、机械性的改动，或关于已在上下文中的代码的问题。没有理由为任务并不需要的能力付费。如果 Claude 已经掌握了所有相关上下文，且明显尽力尝试了却仍然出错，这就是该选更大模型的信号。如果你正在用较大的模型，而工作已经常规了一段时间，那么降到较小模型会提升速度，且通常在不影响输出质量的情况下降低成本。

> Pick a smaller model when the work is routine. For example, edits you can describe precisely, mechanical changes, or questions about code that's already in context. There's no reason to pay for capability the task doesn't need. If Claude has all the pertinent context and clearly tried and still got it wrong, that's a signal to pick a larger model. If you're on the larger model and the work has been routine for a while, dropping down will increase speed and typically reduce cost without impacting the quality of the output.

#### 投入度：Claude 不够努力

> Effort: Claude didn’t try hard enough

如果 Claude 出错是因为跳过了某个文件、没运行测试，或没有反复核对自己的工作，那就选更高的投入度（effort level）。当你把投入度选到了低于该模型默认值时，这一点尤其相关。

> Pick a higher effort level if Claude got it wrong by skipping a file, not running the tests, or not double-checking its work. This is most relevant if you selected an effort level below the model’s default.

Fable 对比 Opus 对比 Sonnet：专家中的专家、专家、以及全才

> Fable vs. Opus vs. Sonnet: The specialist, the expert, and the generalist

我喜欢这样理解这两个设置之间的关系：Fable 是一位见过几乎没人见过的问题的专才，Opus 是专家，而 Sonnet 是一位非常出色的全才。投入度则决定了他们中任何一位在你的任务上花多少时间。

> One way I like to think about how the two settings relate: Fable is a specialist who's seen problems almost no one else has, Opus is the expert, and Sonnet is a really good generalist. The effort level decides how much time any of them spends on your task.

低投入度的 Opus 就像获得五分钟时间去请教一位在类似问题上有深厚经验的专家。他们带来的是你代码库里任何地方都没有的知识：他们以前见过的模式、他们知道要检查的坑，以及那种只有解决过大量类似问题才能获得的东西。但只给他们五分钟，意味着他们只能快速浏览你的代码，而不是仔细阅读。

> Opus at low effort is like getting five minutes with an expert who has deep experience with problems like yours. They bring knowledge that isn't anywhere in your codebase: patterns they've seen before, gotchas they know to check for, the kind of thing you only get from having solved a lot of similar problems. But just giving them five minutes means a quick read of your code, not a careful one.

高投入度的 Sonnet 就像给一位非常出色的全才整个下午。他们会读完所有东西、运行程序、反复核对自己的工作，最终透彻地理解你的具体代码。他们较为欠缺的，是那种“我以前正好见过这个”的识别力。

> Sonnet at high effort is like giving a really good generalist the whole afternoon. They'll read everything, run things, double-check their work, and end up understanding your specific code thoroughly. What they bring less of is that "I've seen exactly this before" recognition.

而 Fable，即使在低投入度下，也是那位专才——只需瞥一眼别人都卡住的问题，就能发现别人发现不了的关键。那种识别力是你付出最高代价所换取的，所以值得留给那些真正需要它的任务。

> Fable, even at low effort, is that specialist glancing at the problem everyone else is stuck on and still spotting the thing no one else would. That recognition is what you're paying the most for, so it's worth saving for the tasks that genuinely need it.

这些设置没有一个是普遍更优的。模型设置大致对应“能力有多强”；投入度设置大致对应“有多细致”。大多数真实任务两者都需要一些。

> None of these is universally better. The model setting is roughly how capable ; the effort setting is roughly how thorough . Most real tasks need some of both.

### 影响力、模型与 Token 消耗

> Effort, model, and token consumption

那么模型选择、投入力度（effort）和 Token 消耗三者是如何相互作用的？这取决于任务本身。

> So how do model selection, effort, and token consumption all interact? It depends on the task.

在同等投入力度下处理常规工作时，两种模型通常都能完成得很好。较大的模型会因额外的验证步骤消耗更多 Token，且单位 Token 价格更高。这正是在常规阶段切换到较小模型能实实在在省钱、又不损失质量的原因。

> On routine work at the same effort level, both models generally will get it right. The larger model consumes more tokens with extra verification steps at a higher per-token price. That's why dropping to the smaller model for routine stretches saves real money at no quality cost.

![Image 9](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe674686b_dc7b4801.png)

在更难、需要多步骤的工作上，情况就不一样了。较小的模型不得不逼近自身能力的极限、反复迭代地硬啃，而较大的模型只需更少的步骤就能达到同样的质量标准。

> On harder, multi-step work, the equation is different. The smaller model has to grind toward the limit of its ability, burning iterations, while the larger model reaches the same quality bar in fewer steps.

使用较大模型时，你为每个 Token 付出的价格更高，但在那些真正逼近较小模型能力上限的任务上，每项任务的总成本反而可能更低。更重要的是，较大的模型能够完成较小模型即便在最高投入力度设置下也无法完成的任务。

> You're paying more per token for the larger model, but on tasks that genuinely stretch the smaller one, the total cost per task can come out lower. Also, more importantly, the larger model can accomplish tasks the smaller one cannot even at the highest effort settings.

这一点在 Fable 上表现得最为明显。在漫长的多步骤工作中，它遥遥领先。在我们的测试中，它完成了 Opus 和 Sonnet 在任何投入力度下都无法达成的任务。它的单位 Token 成本也最高，这是另一个应当把它留给真正需要它的工作的原因。

> This is most pronounced with Fable. On long, multi-step work it pulls furthest ahead. In our testing, it finished jobs Opus and Sonnet can't reach at any effort level. It also costs the most per token, which is the other reason to save it for the work that needs it.

![Image 10](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4d058625e4fe8fe674686e_80670a42.png)

上面图表中的关键在于：投入力度决定了 Claude 愿意沿着曲线走多远，但同样要强调，这并不意味着 Claude 需要走那么远才能完成任务。

> The key point in the graphs above is that effort level picks how far Claude is willing to travel along the curve, but again, that doesn’t mean Claude will need to travel that far to complete the task.

这里还有一个细微之处：投入力度塑造 Token 消耗，但并不限制它。系统中唯一的硬性上限是 max_tokens，一旦达到就会在响应中途将其截断。它是一种粗暴的手段，主要与 API 开发者相关。较为柔性的控制手段，比如任务预算，或在提示词中要求 Claude 保持简洁，才是更有用的工具。它们作为模型受训后会遵循的引导——如果接近上限，模型会设法收尾完成任务——而不是一堵会撞上去的墙。

> Another nuance to this: effort shapes token consumption but doesn't limit it. The only hard cap in the system is max_tokens , which truncates a response mid-stream when hit. It’s a blunt instrument, mostly relevant to API developers. Softer controls, like task budgets or asking Claude to keep it brief in your prompt, are more helpful tools. They serve as guidance the model is trained to follow-it will look to conclude its tasks if it gets near the limit–rather than a wall it runs into.

### 从默认设置开始，需要时再调节旋钮

> Start with the defaults, then reach for the dials

大多数情况下，你不应该去操心这两个设置。当结果不理想时，先问一句：“是 Claude 知道得不够，还是它没有足够努力？”然后据此调整。

> Most of the time, you shouldn't be thinking about either setting. When a result misses the mark, ask, “did Claude not know enough or did it not try hard enough?” and adjust as needed.

本文由 Claude Code 团队技术成员 Lydia Hallie 撰写。

> This article was written by Lydia Hallie, member of technical staff on the Claude Code team.

## 术语对照

| English | 中文 |
|---|---|
| model selection | 模型选择 |
| effort level | 努力级别 |
| weights / parameters | 权重 / 参数 |
| tokenization | 分词 |
| token | 词元 |
| vocabulary | 词表 |
| inference | 推理 |
| steering | 引导 |
| context | 上下文 |
| system prompt | 系统提示词 |
| tool call | 工具调用 |
| hallucination | 幻觉 |
| multi-step task | 多步骤任务 |
| benchmark | 基准测试 |
