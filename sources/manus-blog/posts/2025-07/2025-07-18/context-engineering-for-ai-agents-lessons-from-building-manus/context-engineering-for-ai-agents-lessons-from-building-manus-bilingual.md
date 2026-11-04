# AI 智能体的上下文工程：构建 Manus 的经验教训

> Context Engineering for AI Agents: Lessons from Building Manus

> 来源：Manus Blog / Manus，2025-07-18
> 原文链接：https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
> 分类：AI 智能体 / 上下文工程

## 核心要点

- Manus 选择基于前沿模型的上下文学习能力构建智能体，以便在数小时内交付改进，并让产品与底层模型的进步保持正交。
- KV 缓存命中率被视为生产阶段智能体最重要的单一指标，因为智能体输入输出 token 比例约为 100:1，缓存命中可将输入成本降低约 10 倍。
- 提升缓存命中率的关键做法包括保持提示词前缀稳定、让上下文只追加不修改、确保序列化确定，以及在必要时显式标记缓存断点。
- 工具数量膨胀会让模型更易选错动作，但在迭代中动态增删工具会使缓存失效并导致模型因引用未定义工具而困惑。
- Manus 用上下文感知的状态机在解码时对 token logits 进行掩码，并结合响应预填充和统一的工具名前缀来约束动作选择，而不移除工具定义。
- Manus 将文件系统视为容量不受限、持久且可直接操作的终极上下文，并让压缩策略保持可恢复，例如保留 URL 或文件路径以便按需重新读取内容。
- 智能体通过不断重写 todo.md 把全局目标复述到上下文末尾，从而将计划拉入模型近期注意力范围，减轻迷失在中间和目标偏离的问题。
- 把失败的操作及其错误信息保留在上下文中，能让模型隐式调整信念、避免重复同样的错误，错误恢复也被视为真正智能体行为的清晰标志。
- 上下文中大量相似的动作-观察对会让模型机械模仿既有模式，Manus 通过在序列化模板、措辞和格式中引入受控的多样性来打破这种惯性。
- 上下文的塑造方式最终决定智能体的运行速度、恢复能力和扩展规模，这些模式来自多次重建框架和面向数百万用户的真实测试。

## 正文

在 [Manus](https://manus.im/app) 项目刚启动时，我和团队面临一个关键抉择：是基于开源基础模型训练一个端到端的智能体模型，还是在前沿模型的[上下文学习](https://arxiv.org/abs/2301.00234)能力之上构建智能体？

> At the very beginning of the [Manus](https://manus.im/app) project, my team and I faced a key decision: should we train an end-to-end agentic model using open-source foundations, or build an agent on top of the [in-context learning](https://arxiv.org/abs/2301.00234) abilities of frontier models?

在我从事 NLP 的头十年里，我们可没有这种选择的余地。在 [BERT](https://arxiv.org/abs/1810.04805) 那个遥远的年代（没错，已经过去七年了），模型必须先经过微调和评估，才能迁移到新任务上。尽管那些模型与今天的 LLM 相比小得可怜，这个过程每次迭代往往仍要耗费数周时间。对于快速变化的应用，尤其是在达到 PMF 之前，这种**缓慢的反馈循环**是致命的。这是我上一次创业时得到的惨痛教训：当时我为[开放信息抽取](https://en.wikipedia.org/wiki/Open_information_extraction)和语义搜索从零开始训练模型。随后 [GPT-3](https://arxiv.org/abs/2005.14165) 和 [Flan-T5](https://arxiv.org/abs/2210.11416) 横空出世，我自研的模型一夜之间就失去了意义。讽刺的是，正是这些模型开启了上下文学习的时代，也开辟了一条全新的前进道路。

> Back in my first decade in NLP, we didn't have the luxury of that choice. In the distant days of [BERT](https://arxiv.org/abs/1810.04805) (yes, it's been seven years), models had to be fine-tuned—and evaluated—before they could transfer to a new task. That process often took weeks per iteration, even though the models were tiny compared to today's LLMs. For fast-moving applications, especially pre–PMF, such **slow feedback loops** are a deal-breaker. That was a bitter lesson from my last startup, where I trained models from scratch for [open information extraction](https://en.wikipedia.org/wiki/Open_information_extraction) and semantic search. Then came [GPT-3](https://arxiv.org/abs/2005.14165) and [Flan-T5](https://arxiv.org/abs/2210.11416), and my in-house models became irrelevant overnight. Ironically, those same models marked the beginning of in-context learning—and a whole new path forward.

这一来之不易的教训让选择变得清晰：**Manus 将押注于上下文工程**。这使我们能够在几小时内而非几周内交付改进，并让我们的产品与底层模型保持正交：**如果说模型的进步是上涨的潮水，我们希望 Manus 成为那条船**，而不是固定在海床上的柱子。

> That hard-earned lesson made the choice clear: **Manus would bet on context engineering**. This allows us to ship improvements in hours instead of weeks, and kept our product orthogonal to the underlying models: **If model progress is the rising tide, we want Manus to be the boat**, not the pillar stuck to the seabed.

不过，上下文工程远没有那么简单。它是一门实验科学——我们已经把智能体框架重建了四次，每一次都是因为发现了塑造上下文的更好方法。我们把这种架构搜索、反复调整提示词和凭经验猜测的手工过程，亲切地称为“**随机*****研究生*****下降**”。它并不优雅，但确实管用。

> Still, context engineering turned out to be anything but straightforward. It's an experimental science—and we've rebuilt our agent framework four times, each time after discovering a better way to shape context. We affectionately refer to this manual process of architecture searching, prompt fiddling, and empirical guesswork as "**Stochastic *****Graduate***** Descent**". It's not elegant, but it works.

本文分享我们通过自己的“SGD”所找到的局部最优解。如果你正在构建自己的 AI 智能体，希望这些原则能帮助你更快收敛。

> This post shares the local optima we arrived at through our own "SGD". If you're building your own AI agent, I hope these principles help you converge faster.

##### 围绕 KV-Cache 进行设计

> Design Around the KV-Cache

如果只能选一个指标，我认为**KV 缓存命中率**是生产阶段 AI 智能体最重要的单一指标。它同时直接影响延迟和成本。要理解其中的原因，我们先来看看[一个典型的智能体](https://arxiv.org/abs/2210.03629)是如何运作的：

> If I had to choose just one metric, I'd argue that the **KV-cache hit rate** is the single most important metric for a production-stage AI agent. It directly affects both latency and cost. To understand why, let's look at how [a typical agent](https://arxiv.org/abs/2210.03629) operates:

收到用户输入后，智能体会通过一连串的工具调用来完成任务。在每次迭代中，模型会根据当前上下文，从预定义的动作空间中选择一个**动作**。随后，该动作会在**环境**（例如 Manus 的虚拟机沙箱）中执行，并产生一个**观察结果**。动作和观察结果会被追加到上下文中，构成下一次迭代的输入。这一循环会持续进行，直到任务完成。

> After receiving a user input, the agent proceeds through a chain of tool uses to complete the task. In each iteration, the model selects an **action** from a predefined action space based on the current context. That action is then executed in the **environment** (e.g., Manus's virtual machine sandbox) to produce an **observation**. The action and observation are appended to the context, forming the input for the next iteration. This loop continues until the task is complete.

可以想见，上下文会随着每一步不断增长，而输出——通常是一个结构化的函数调用——则相对较短。这使得智能体中**预填充（prefilling）**与**解码（decoding）**之间的比例相比聊天机器人严重失衡。以 Manus 为例，平均输入与输出 token 之比约为**100:1**。

> As you can imagine, the context grows with every step, while the output—usually a structured function call—remains relatively short. This makes the ratio between **prefilling** and **decoding** highly skewed in agents compared to chatbots. In Manus, for example, the average input-to-output token ratio is around **100:1**.

幸运的是，具有相同前缀的上下文可以利用 [KV-cache](https://medium.com/@joaolages/kv-caching-explained-276520203249)，从而大幅降低**首 token 延迟（TTFT）**和推理成本——无论你使用的是自托管模型还是调用推理 API。而且节省的幅度可不小：以 Claude Sonnet 为例，缓存命中的输入 token 价格为 **0.30 美元/百万 token**，而未缓存的则为 **3 美元/百万 token**——相差 10 倍。

> Fortunately, contexts with identical prefixes can take advantage of [KV-cache](https://medium.com/@joaolages/kv-caching-explained-276520203249), which drastically reduces **time-to-first-token (TTFT)** and inference cost—whether you're using a self-hosted model or calling an inference API. And we're not talking about small savings: with Claude Sonnet, for instance, cached input tokens cost **0.30 USD/MTok**, while uncached ones cost **3 USD/MTok**—a 10x difference.

![](https://d1oupeiobkpcny.cloudfront.net/user_upload_by_module/markdown/310708716691272617/OhdKxGRSXCcuqOvz.png)

从上下文工程的角度来看，提升 KV 缓存命中率涉及以下几项关键实践：

> From a context engineering perspective, improving KV-cache hit rate involves a few key practices:

1. 
**保持提示词前缀稳定。**由于 LLM 的[自回归](https://en.wikipedia.org/wiki/Autoregressive_model)特性，哪怕只有一个 token 的差异，也会使从该 token 开始往后的缓存全部失效。一个常见的错误是在系统提示词的开头加入时间戳——尤其是精确到秒的时间戳。没错，这样模型就能告诉你当前时间，但同时也会让你的缓存命中率一落千丈。

2. 
**让你的上下文只追加、不修改。**避免修改之前的动作或观察结果。确保你的序列化是确定性的。许多编程语言和库在序列化 JSON 对象时并不保证键的顺序稳定，这可能会在不知不觉中破坏缓存。

3. 
**必要时显式标记缓存断点。**部分模型提供商或推理框架不支持自动增量前缀缓存，而是需要在上下文中手动插入缓存断点。设置断点时，应考虑缓存可能过期的情况，并且至少要确保断点覆盖系统提示词的末尾。


> 1\. 
> **Keep your prompt prefix stable.** Due to the [autoregressive](https://en.wikipedia.org/wiki/Autoregressive_model) nature of LLMs, even a single-token difference can invalidate the cache from that token onward. A common mistake is including a timestamp—especially one precise to the second—at the beginning of the system prompt. Sure, it lets the model tell you the current time, but it also kills your cache hit rate.
> 2\. 
> **Make your context append-only.** Avoid modifying previous actions or observations. Ensure your serialization is deterministic. Many programming languages and libraries don't guarantee stable key ordering when serializing JSON objects, which can silently break the cache.
> 3\. 
> **Mark cache breakpoints explicitly when needed.** Some model providers or inference frameworks don't support automatic incremental prefix caching, and instead require manual insertion of cache breakpoints in the context. When assigning these, account for potential cache expiration and at minimum, ensure the breakpoint includes the end of the system prompt.

此外，如果你使用 [vLLM](https://github.com/vllm-project/vllm) 等框架自行托管模型，请确保已启用[前缀/提示词缓存](https://docs.vllm.ai/en/stable/design/v1/prefix_caching.html)，并使用**会话 ID** 等技术，将请求一致地路由到分布式工作节点上。

> Additionally, if you're self-hosting models using frameworks like [vLLM](https://github.com/vllm-project/vllm), make sure [prefix/prompt caching](https://docs.vllm.ai/en/stable/design/v1/prefix_caching.html) is enabled, and that you're using techniques like **session IDs** to route requests consistently across distributed workers.

##### 遮蔽，而非移除

> Mask, Don't Remove

随着你的智能体承担越来越多的能力，它的动作空间自然会变得愈发复杂——说白了，就是**工具数量**爆炸式增长。最近 [MCP](https://modelcontextprotocol.io/introduction) 的流行更是火上浇油。如果你允许用户自行配置工具，相信我：总会有人把数百个来历不明的工具塞进你精心设计的动作空间里。结果就是，模型更容易选错动作，或者走上低效的路径。简而言之，你那全副武装的智能体反而变笨了。

> As your agent takes on more capabilities, its action space naturally grows more complex—in plain terms, the **number of tools** explodes. The recent popularity of [MCP](https://modelcontextprotocol.io/introduction) only adds fuel to the fire. If you allow user-configurable tools, trust me: someone will inevitably plug hundreds of mysterious tools into your carefully curated action space. As a result, the model is more likely to select the wrong action or take an inefficient path. In short, your heavily armed agent gets dumber.

一个自然的反应是设计动态的动作空间——比如借助类似 [RAG](https://en.wikipedia.org/wiki/Retrieval-augmented_generation) 的方式按需加载工具。我们在 Manus 中也尝试过。但我们的实验得出了一条明确的规则：除非绝对必要，**避免在迭代过程中动态添加或移除工具**。这主要有两个原因：

> A natural reaction is to design a dynamic action space—perhaps loading tools on demand using something [RAG](https://en.wikipedia.org/wiki/Retrieval-augmented_generation)-like. We tried that in Manus too. But our experiments suggest a clear rule: unless absolutely necessary, **avoid dynamically adding or removing tools mid-iteration**. There are two main reasons for this:

1. 
在大多数 LLM 中，工具定义在序列化后位于上下文的靠前位置，通常在系统提示词之前或之后。因此，任何改动都会使后续所有动作和观察结果的 KV-cache 失效。

2. 
当先前的动作和观察仍在引用当前上下文中已不再定义的工具时，模型就会感到困惑。如果没有[约束解码](https://platform.openai.com/docs/guides/structured-outputs)，这往往会导致**违反模式（schema）或产生幻觉动作**。


> 1\. 
> In most LLMs, tool definitions live near the front of the context after serialization, typically before or after the system prompt. So any change will invalidate the KV-cache for all subsequent actions and observations.
> 2\. 
> When previous actions and observations still refer to tools that are no longer defined in the current context, the model gets confused. Without [constrained decoding](https://platform.openai.com/docs/guides/structured-outputs), this often leads to **schema violations or hallucinated actions**.

为了在解决这一问题的同时仍能改进动作选择，Manus 使用一个上下文感知的[状态机](https://en.wikipedia.org/wiki/Finite-state_machine)来管理工具的可用性。它并不移除工具，而是在解码过程中**对 token logits 进行掩码**，从而根据当前上下文阻止（或强制）选择某些动作。

> To solve this while still improving action selection, Manus uses a context-aware [state machine](https://en.wikipedia.org/wiki/Finite-state_machine) to manage tool availability. Rather than removing tools, it **masks the token logits** during decoding to prevent (or enforce) the selection of certain actions based on the current context.

![](https://d1oupeiobkpcny.cloudfront.net/user_upload_by_module/markdown/310708716691272617/cWxINCvUfrmlbvfV.png)

实践中，大多数模型提供商和推理框架都支持某种形式的**响应预填充（response prefill）**，它让你可以在*不*修改工具定义的情况下约束动作空间。函数调用通常有三种模式（我们以 NousResearch 的 [Hermes 格式](https://github.com/NousResearch/Hermes-Function-Calling)为例）：

> In practice, most model providers and inference frameworks support some form of **response prefill**, which allows you to constrain the action space *without* modifying the tool definitions. There are generally three modes of function calling (we'll use the [Hermes format](https://github.com/NousResearch/Hermes-Function-Calling) from NousResearch as an example):

- 
**Auto** – 模型可以自行选择是否调用函数。实现方式是仅预填充回复前缀：`<|im_start|>assistant`

- 
**Required（必须调用）** – 模型必须调用某个函数，但具体调用哪个不受约束。实现方式是将预填充一直进行到工具调用 token 为止：`<|im_start|>assistant<tool_call>`

- 
**指定（Specified）**——模型必须调用**某个特定子集中的**函数。实现方式是将预填充内容一直写到函数名的开头：`<|im_start|>assistant<tool_call>{"name": “browser_`


> • 
> **Auto** – The model may choose to call a function or not. Implemented by prefilling only the reply prefix: `<|im_start|>assistant`
> • 
> **Required** – The model must call a function, but the choice is unconstrained. Implemented by prefilling up to tool call token: `<|im_start|>assistant<tool_call>`
> • 
> **Specified** – The model must call a function **from a specific subset**. Implemented by prefilling up to the beginning of the function name: `<|im_start|>assistant<tool_call>{"name": “browser_`

借助这一点，我们通过直接屏蔽 token logits 来约束动作选择。例如，当用户提供新的输入时，Manus 必须立即回复，而不是执行某个动作。我们还特意为动作名称设计了一致的前缀——例如，所有与浏览器相关的工具都以 `browser_` 开头，命令行工具则以 `shell_` 开头。这样，我们就能轻松地强制智能体在给定状态下只从某一组工具中进行选择，**而无需使用有状态的 logits 处理器**。

> Using this, we constrain action selection by masking token logits directly. For example, when the user provides a new input, Manus must reply immediately instead of taking an action. We've also deliberately designed action names with consistent prefixes—e.g., all browser-related tools start with `browser_`, and command-line tools with `shell_`. This allows us to easily enforce that the agent only chooses from a certain group of tools at a given state **without using stateful logits processors**.

这些设计有助于确保 Manus 的智能体循环保持稳定——即便是在模型驱动的架构下。

> These designs help ensure that the Manus agent loop remains stable—even under a model-driven architecture.

##### 将文件系统用作上下文

> Use the File System as Context

如今的前沿大语言模型已提供 128K token 甚至更长的上下文窗口。但在真实的智能体场景中，这往往仍然不够，有时甚至会成为负担。常见的痛点有三个：

> Modern frontier LLMs now offer context windows of 128K tokens or more. But in real-world agentic scenarios, that's often not enough, and sometimes even a liability. There are three common pain points:

1. 
**观察结果可能非常庞大**，尤其是当智能体与网页或 PDF 等非结构化数据交互时。很容易就会超出上下文限制。

2. 
**模型性能往往会在超过一定上下文长度后下降**，即使上下文窗口在技术上支持该长度。

3. 
**长输入的成本很高**，即使启用了前缀缓存也是如此。你仍然要为每个 token 的传输和预填充付费。


> 1\. 
> **Observations can be huge**, especially when agents interact with unstructured data like web pages or PDFs. It's easy to blow past the context limit.
> 2\. 
> **Model performance tends to degrade** beyond a certain context length, even if the window technically supports it.
> 3\. 
> **Long inputs are expensive**, even with prefix caching. You're still paying to transmit and prefill every token.

为了解决这个问题，许多智能体系统会采用上下文截断或压缩策略。但过于激进的压缩不可避免地会导致信息丢失。这个问题是根本性的：智能体本质上必须基于所有先前状态来预测下一步行动，而你**无法**可靠地预测哪一条观察结果会在十步之后变得至关重要。从逻辑上讲，任何不可逆的压缩都存在风险。

> To deal with this, many agent systems implement context truncation or compression strategies. But overly aggressive compression inevitably leads to information loss. The problem is fundamental: an agent, by nature, must predict the next action based on all prior state—and you **can't** reliably predict which observation might become critical ten steps later. From a logical standpoint, any irreversible compression carries risk.

这就是为什么我们在 Manus 中将**文件系统视为终极上下文**：它容量不受限制，天然具备持久性，并且可以由智能体直接操作。模型学会按需写入和读取文件——不仅把文件系统当作存储，更把它用作结构化的外部化记忆。

> That's why we treat the **file system as the ultimate context** in Manus: unlimited in size, persistent by nature, and directly operable by the agent itself. The model learns to write to and read from files on demand—using the file system not just as storage, but as structured, externalized memory.

![](https://d1oupeiobkpcny.cloudfront.net/user_upload_by_module/markdown/310708716691272617/sBITCOxGnHNUPHTD.png)

我们的压缩策略始终设计为**可恢复的**。例如，只要保留了 URL，网页内容就可以从上下文中移除；只要文档路径在沙箱中仍然可用，其内容就可以省略。这使 Manus 能够缩短上下文长度，而不会永久丢失信息。

> Our compression strategies are always designed to be **restorable**. For instance, the content of a web page can be dropped from the context as long as the URL is preserved, and a document's contents can be omitted if its path remains available in the sandbox. This allows Manus to shrink context length without permanently losing information.

在开发这个功能的过程中，我不禁设想：要让**状态空间模型（State Space Model，SSM）**在智能体场景中高效工作，需要具备什么条件。与 Transformer 不同，SSM 缺乏完整的注意力机制，难以处理长程的反向依赖。但如果它们能够掌握基于文件的记忆——将长期状态外部化，而不是保存在上下文中——那么它们的速度和效率或许能催生出一类全新的智能体。具备智能体能力的 SSM 才可能是[神经图灵机（Neural Turing Machines）](https://arxiv.org/abs/1410.5401)真正的继任者。

> While developing this feature, I found myself imagining what it would take for a **State Space Model (SSM)** to work effectively in an agentic setting. Unlike Transformers, SSMs lack full attention and struggle with long-range backward dependencies. But if they could master file-based memory—externalizing long-term state instead of holding it in context—then their speed and efficiency might unlock a new class of agents. Agentic SSMs could be the real successors to [Neural Turing Machines](https://arxiv.org/abs/1410.5401).

##### 通过复述操控注意力

> Manipulate Attention Through Recitation

如果你用过 Manus，可能已经注意到一个有趣的现象：在处理复杂任务时，它往往会创建一个 **todo.md** 文件，并随着任务推进逐步更新，把已完成的事项一一勾掉。

> If you've worked with Manus, you've probably noticed something curious: when handling complex tasks, it tends to create a **todo.md** file—and update it step-by-step as the task progresses, checking off completed items.

这不只是可爱的行为——而是一种刻意用来**操纵注意力**的机制。

> That's not just cute behavior—it's a deliberate mechanism to **manipulate attention**.

![](https://d1oupeiobkpcny.cloudfront.net/user_upload_by_module/markdown/310708716691272617/OYpTzfPZaBeeWFOx.png)

在 Manus 中，一个典型任务平均需要大约 **50 次工具调用**。这是一个很长的循环——而由于 Manus 依赖 LLM 进行决策，它很容易偏离主题或遗忘先前的目标，尤其是在长上下文或复杂任务中。

> A typical task in Manus requires around **50 tool calls** on average. That's a long loop—and since Manus relies on LLMs for decision-making, it's vulnerable to drifting off-topic or forgetting earlier goals, especially in long contexts or complicated tasks.

通过不断重写待办事项列表，Manus 实际上是在**把自己的目标复述到上下文的末尾**。这会把全局计划推入模型近期的注意力范围内，从而避免“**迷失在中间**”（lost-in-the-middle）问题，并减少目标偏离。实际上，它是在用自然语言让自己的注意力偏向任务目标，而无需对架构做任何特殊改动。

> By constantly rewriting the todo list, Manus is **reciting its objectives into the end of the context**. This pushes the global plan into the model's recent attention span, avoiding "**lost-in-the-middle**" issues and reducing goal misalignment. In effect, it's using natural language to bias its own focus toward the task objective—without needing special architectural changes.

##### 把错误留在上下文中

> Keep the Wrong Stuff In

智能体会犯错。这不是 bug，而是现实。语言模型会产生幻觉，环境会返回错误，外部工具会出现异常行为，意想不到的边界情况也随时可能出现。在多步骤任务中，失败不是例外，而是循环的一部分。

> Agents make mistakes. That's not a bug—it's reality. Language models hallucinate, environments return errors, external tools misbehave, and unexpected edge cases show up all the time. In multi-step tasks, failure is not the exception; it's part of the loop.

然而，一种常见的冲动是把这些错误藏起来：清理轨迹、重试操作，或者重置模型状态，然后把一切交给神奇的“[temperature](https://arxiv.org/abs/2405.00492)”。这样做感觉更安全、更可控。但它是有代价的：**抹去失败就等于抹去证据**。而没有证据，模型就无法适应。

> And yet, a common impulse is to hide these errors: clean up the trace, retry the action, or reset the model's state and leave it to the magical "[temperature](https://arxiv.org/abs/2405.00492)". That feels safer, more controlled. But it comes at a cost: **Erasing failure removes evidence**. And without evidence, the model can't adapt.

![](https://d1oupeiobkpcny.cloudfront.net/user_upload_by_module/markdown/310708716691272617/dBjZlVbKJVhjgQuF.png)

根据我们的经验，改进智能体行为最有效的方法之一看似简单得出奇：**把走错的路留在上下文中**。当模型看到一次失败的操作，以及由此产生的观察结果或堆栈跟踪时，它会隐式地更新其内部信念。这会使它的先验偏离类似的操作，从而降低重复同样错误的概率。
事实上，我们认为**错误恢复**是真正智能体行为最清晰的标志之一。然而，在大多数学术研究和公开基准测试中，它仍然没有得到充分体现，这些研究和基准往往侧重于理想条件下的任务成功率。

> In our experience, one of the most effective ways to improve agent behavior is deceptively simple: **leave the wrong turns in the context**. When the model sees a failed action—and the resulting observation or stack trace—it implicitly updates its internal beliefs. This shifts its prior away from similar actions, reducing the chance of repeating the same mistake.
> In fact, we believe **error recovery** is one of the clearest indicators of true agentic behavior. Yet it's still underrepresented in most academic work and public benchmarks, which often focus on task success under ideal conditions.

##### 别被少样本示例带偏

> Don't Get Few-Shotted

[少样本提示（Few-shot prompting）](https://www.promptingguide.ai/techniques/fewshot)是提升 LLM 输出质量的常用技术。但在智能体系统中，它可能以一些不易察觉的方式适得其反。

> [Few-shot prompting](https://www.promptingguide.ai/techniques/fewshot) is a common technique for improving LLM outputs. But in agent systems, it can backfire in subtle ways.

语言模型是出色的模仿者；它们会**模仿上下文中的行为模式**。如果你的上下文中充满了相似的过往“动作-观察”对，模型就会倾向于沿用这种模式，即便它已不再是最优选择。

> Language models are excellent mimics; they **imitate the pattern of behavior** in the context. If your context is full of similar past action-observation pairs, the model will tend to follow that pattern, even when it's no longer optimal.

在涉及重复性决策或操作的任务中，这可能很危险。例如，在使用 Manus 帮助审阅一批 20 份简历时，智能体常常会陷入一种惯性节奏——仅仅因为上下文中看到的就是这些，便重复类似的操作。这会导致偏移、过度泛化，有时甚至产生幻觉。

> This can be dangerous in tasks that involve repetitive decisions or actions. For example, when using Manus to help review a batch of 20 resumes, the agent often falls into a rhythm—repeating similar actions simply because that's what it sees in the context. This leads to drift, overgeneralization, or sometimes hallucination.

![](https://d1oupeiobkpcny.cloudfront.net/user_upload_by_module/markdown/310708716691272617/IIyBBdwwuMDJUnUc.png)

解决办法是**增加多样性**。Manus 会在动作和观察中引入少量结构化的变化——不同的序列化模板、替换的措辞、顺序或格式上的细微噪声。这种受控的随机性有助于打破固定模式，并调整模型的注意力。
换句话说，**不要用 few-shot 把自己困在套路里**。你的上下文越单一，你的智能体就越脆弱。

> The fix is to **increase diversity**. Manus introduces small amounts of structured variation in actions and observations—different serialization templates, alternate phrasing, minor noise in order or formatting. This controlled randomness helps break the pattern and tweaks the model's attention.
> In other words, **don't few-shot yourself into a rut**. The more uniform your context, the more brittle your agent becomes.

##### 结论

> Conclusion

上下文工程仍是一门新兴的学问，但对智能体系统而言，它已经不可或缺。模型或许正变得更强、更快、更便宜，但无论原始能力有多强，都无法取代对记忆、环境和反馈的需求。你如何塑造上下文，最终决定了你的智能体如何表现：它运行得多快、恢复得多好，以及能扩展到多大规模。

> Context engineering is still an emerging science—but for agent systems, it's already essential. Models may be getting stronger, faster, and cheaper, but no amount of raw capability replaces the need for memory, environment, and feedback. How you shape the context ultimately defines how your agent behaves: how fast it runs, how well it recovers, and how far it scales.

在 Manus，我们是通过一次次重写、走进死胡同，以及**面向数百万用户的真实环境测试**才学到这些经验的。我们在这里分享的内容并非放之四海而皆准的真理——但这些是对我们行之有效的模式。如果它们能帮你少经历哪怕一次痛苦的迭代，那么这篇文章就达到了目的。

> At Manus, we've learned these lessons through repeated rewrites, dead ends, and **real-world testing across millions of users**. None of what we've shared here is universal truth—but these are the patterns that worked for us. If they help you avoid even one painful iteration, then this post did its job.

智能体的未来将由一个又一个上下文构建而成。请用心设计好每一个上下文。

> The agentic future will be built one context at a time. Engineer them well.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Context Engineering | 上下文工程 | 通过设计和管理输入给模型的上下文来塑造智能体行为的方法。 |
| In-context Learning | 上下文学习 | 模型无需更新参数、仅凭提示中的示例和信息完成新任务的能力。 |
| KV-cache | 键值缓存 | 缓存注意力计算中已处理前缀的键和值，以便复用相同前缀、降低延迟与成本。 |
| Prefilling | 预填充 | 推理时一次性处理输入 token 并建立缓存的阶段。 |
| Decoding | 解码 | 模型逐个生成输出 token 的阶段。 |
| Time to First Token (TTFT) | 首 token 延迟 | 从发出请求到模型返回第一个输出 token 所需的时间。 |
| Cache Breakpoint | 缓存断点 | 在上下文中手动标记的位置，用于指示推理服务从该处缓存前缀。 |
| Action Space | 动作空间 | 智能体在每一步可选择执行的全部动作或工具集合。 |
| Logit Masking | logits 掩码 | 在解码时屏蔽特定 token 的概率，以阻止或强制模型选择某些输出。 |
| Constrained Decoding | 约束解码 | 在生成过程中限制输出须符合指定格式或模式的解码方式。 |
| Response Prefill | 响应预填充 | 预先写入模型回复的开头部分，以约束其后续生成内容。 |
| State Space Model (SSM) | 状态空间模型 | 以递归状态而非完整注意力处理序列的一类高效序列模型架构。 |
| Lost in the Middle | 迷失在中间 | 模型在长上下文中容易忽视位于中段信息的现象。 |
| Few-shot Prompting | 少样本提示 | 在提示中提供少量示例以引导模型输出的技术。 |
| Model Context Protocol (MCP) | 模型上下文协议 | 用于将外部工具和数据源接入大语言模型应用的开放协议。 |
