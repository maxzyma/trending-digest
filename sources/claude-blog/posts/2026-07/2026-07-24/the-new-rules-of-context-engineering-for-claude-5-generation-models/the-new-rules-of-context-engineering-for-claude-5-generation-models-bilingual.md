# Claude 5 世代模型的上下文工程新规则

> The new rules of context engineering for Claude 5 generation models

> 来源：Claude Blog / Anthropic，2026-07-24
> 原文链接：https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
> 分类：AI 工程 / 上下文工程

## 核心要点

- 提示词只占 Claude 实际获得上下文的一小部分，系统提示词、Skills、CLAUDE.md、记忆等共同组装成上下文，这一组装过程被称为上下文工程。
- 与针对单次请求的提示词不同，上下文会在大量请求中通用，因而难以写得具体，如何在不知道用户提示词的前提下编写通用指引是核心挑战。
- 面向 Claude Opus 5 与 Claude Fable 5 这类新一代模型，团队删除了 Claude Code 系统提示词中超过 80% 的内容，而编码评估未出现可测量的性能损失。
- 过去为规避最坏情况而施加的强硬规则（如「默认不写注释」）会与技能和用户请求相互冲突，迫使模型花更多精力消解矛盾；新模型判断力更好，可改为「与周围代码风格保持一致」这类交由模型自行判断的表述。
- 为工具提供使用示例的旧做法会把新模型限制在特定探索空间，更好的做法是打磨工具、脚本与文件的接口设计，例如用 pending/in_progress/completed 枚举本身来暗示预期用法。
- 应以渐进式披露替代把所有信息前置：Claude Code 把验证与代码审查拆入独立技能，并让部分工具「延迟加载」，需经 ToolSearch 检索完整定义后才占用上下文。
- CLAUDE.md 与 Skill.md 同样不应做成收录一切已知实践的集中仓库，而应构建文件树，让内容在恰当时机被加载。
- 早期模型需要重复指令、且更倾向听从上下文末尾的内容，如今可删除重复，把工具用法说明统一放进工具描述而非系统提示词。
- 记忆不再依赖用户用 # 快捷键手动写入 CLAUDE.md，Claude 现在会自动保存与工作及用户相关的记忆。
- 参考资料可以超越简单的 markdown 规范，包括 HTML artifacts、测试套件、可移植的函数以及评分标准（Rubrics），后者可配合动态工作流启动验证器 agent 来校验特定领域的品味。
- 落地建议是：系统提示词绑定产品上下文（自建 agent harness 时值得重点投入），CLAUDE.md 保持轻量并把 token 花在代码库坑点上，技能作为轻量指引承载团队独有的观点与实践，引用优先选择代码形式的高保真材料。
- 团队已将这些最佳实践写入新命令 `claude doctor`，可通过 /doctor 自动帮助精简技能与 CLAUDE.md 文件。

## 正文

我之前写过关于如何最好地[为最新一代 Claude 5 模型编写提示词](https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns)，以及如何与它们迭代协作以探索你想要构建的东西。

> I’ve written previously about how to best [prompt the newest generation of Claude 5 models](https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns) and work with them iteratively to discover what you want to build.

但当你向 Claude 发送一条消息时，提示词只是它所获得上下文中的一小部分。你的大部分上下文是由系统提示词、Skills、CLAUDE.md 文件、记忆以及其他来源组装而成的。我们称之为[上下文工程](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)，它对你在使用 Claude Code 或构建自己的智能体时所生成的结果有着重大影响。

> But when you send a message to Claude, the prompt is only a small part of the context it gets. Much of your context is assembled from your system prompt, Skills, CLAUDE.md files, memory, and other sources. We call this [context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), and it makes a big impact on the results you generate when using Claude Code or in building your own agents.

与提示词不同，上下文通常会在许多次请求中通用，因此它无法做到那么具体。你该如何为 Claude 构建这些通用的提示词和指引，尤其是在你并不知道用户的提示词可能是什么的情况下？

> Unlike a prompt, context is used generally across many requests, so it cannot be as specific.  How do you build these general prompts and guidance for Claude, especially when you don’t know what a user’s prompt might be?

随着 Claude 自身能力的演进，这件事的难度可能出乎意料。最近，我们注意到在为最新一代 Claude 模型编写提示词的方式上出现了很大的跃变。我们为 Claude Opus 5 和 Claude Fable 5 这类模型删除了 Claude Code 系统提示词中超过 80% 的内容，而在我们的编码评估中没有出现可测量的性能损失。

> This can be surprisingly difficult as Claude’s own capabilities evolve. Most recently, we noticed a large jump in the way we prompt the newest generation of Claude models. We removed over 80% of Claude Code’s system prompt for models like Claude Opus 5 and Claude Fable 5 with no measurable loss on our coding evaluations.

以下是我们在为这类新模型编写提示词方面的经验，以及你可以如何运用这些经验来更新自己的上下文工程实践。我们已把这些最佳实践写入 `claude doctor;` 在 Claude Code 中使用 /doctor 命令，即可让你的技能和 CLAUDE.md 文件保持在合适的规模。

> Here’s what we’ve learned about prompting this new class of models, and how you can utilize it to update your context engineering. We’ve put these best practices in `claude doctor;` use the command /doctor in Claude Code to rightsize your skills, and CLAUDE.md files.

#### 解放 Claude

> Unhobbling Claude

总的来说，我们发现自己对 Claude Code 施加了过多约束，这既体现在我们的系统提示词中，也体现在我们的 CLAUDE.md 文件和 skills 中。

> Overall, we found that we were overconstraining Claude Code, both through our system prompt and in our CLAUDE.md files and skills. 

举个例子，当我们阅读自己内部使用 Claude Code 的对话记录时，会在同一个请求里看到若干互相冲突的指令，比如“酌情保留文档”，或者“不要添加注释”——我们的系统提示词、技能和用户请求彼此之间产生了冲突。

> For example, when we read transcripts of our own internal usage of Claude Code, we see several conflicting messages in a single request like “leave documentation as appropriate,” or “DO NOT add comments” as our system prompt, skills, and user requests clash with each other. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a63620bedb2b7813b1071e2_afa90c36.png)

一般来说，Claude 能够理解用户的意图并给出正确的答案，但在决定如何行动之前，Claude 必须更仔细地思考这些相互重叠和冲突的消息。

> Generally, Claude can interpret the user’s intent to get to the right answer, but Claude must think more carefully about these overlapping and conflicting messages before deciding what to do.

虽然这些约束曾经是避免最坏情况所必需的，但我们后来发现，可以删除其中许多约束，转而让模型利用上下文和判断力来处理。

> And while these constraints were once needed to avoid worst case scenarios, we have since found we can delete many of them and let the model use surrounding context and judgement instead.

此外，Claude Code 现在拥有了更多工具。过去 Claude 依赖 CLAUDE.md 作为记忆、信息和指导的来源。现在我们有了 memory、artifacts 和 skills，Claude 可以借助它们创造出跨会话加载和共享上下文的新方式。

> Additionally, Claude Code now has many more tools. Claude used to rely on CLAUDE.md as a source of memory, information, and guidance. Now we have memory, artifacts, and skills, which Claude can use to create new ways of loading and sharing context across sessions.

#### 今与昔

> Then and now

此前有不少上下文工程的最佳实践已经变成了迷思，包括：。

> There were a number of previous context engineering best practices that had become myths. Including:.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a63620bedb2b7813b107213_3979f6a1.png)

##### 然后：给 Claude 制定规则

> Then: Give Claude rules

##### 现在：让 Claude 自行判断

> Now: Let Claude use judgement

我们最初推出 Claude Code 时，需要确保 Claude 能避免最糟糕的情况，比如删除文件。这意味着我们会给出一些格外强硬的指引，而它们未必总是成立。例如，我们过去在系统提示中会这样写： 

> When we first rolled out Claude Code, we needed to be sure that Claude avoided worst case scenarios, such as deleting files. This meant we would give particularly strong guidance that might not always be true, For example, in the system prompt we used to say: 

*在代码中：默认不写注释。绝不写多段式的文档字符串或多行注释块——最多一行简短说明。除非用户要求，不要创建规划、决策或分析文档——依据对话上下文工作，而不是中间文件。*

> *In code: default to writing no comments. Never write multi-paragraph docstrings or multi-line comment blocks — one short line max. Don't create planning, decision, or analysis documents unless the user asks for them — work from conversation context, not intermediate files.*

但对于某一类特定的提示词来说，这条指导原则会是错误的。在编写文档的场景中，用户可能有自己的偏好，或者非常复杂的代码中某些特定部分可能需要多行注释块。

> But for a certain subset of prompts, this guidance would be wrong. In the case of documentation, the user may have their own preferences, or specific parts of very complex code might need multi-line comment blocks.

不过，如果不为较旧的模型设置这些约束，Claude 写出的注释在很多情况下会是错误的，我们不得不接受这种取舍。但更新的模型判断力更好，即使没有明确的规则，也能很好地处理这些决定。

> Still, without these guardrails for older models, the comments Claude wrote would be incorrect in many cases and we had to accept this tradeoff. But newer models have better judgement and can handle these decisions well without explicit rules. 

在新的系统提示词中我们写道：*编写与周围代码风格一致的代码：匹配其注释密度、命名方式和惯用写法。*

> In the new system prompt we say: *Write code that reads like the surrounding code: match its comment density, naming, and idiom.*

##### 然后：给 Claude 提供示例

> Then: Give Claude examples

##### 现在：设计接口

> Now: Design interfaces

使用工具的第一条规则曾经是给 Claude 提供如何使用它们的示例。而在我们最新的模型上，我们发现给出示例实际上会把它们限制在某个特定的探索空间里。

> The number one rule for tool usage was to give Claude examples on how to use them. With our newest models, we’ve found that giving examples actually constrains them to a certain exploration space. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a63620bedb2b7813b107216_c4fdec0d.png)

与其使用示例，不如多思考一下你的工具、脚本和文件的设计——Claude 有哪些参数可用，这些参数怎样才能更具表达力？

> Instead of using examples, think more about the design of your tools, scripts and files- what parameters does Claude have and how can they be more expressive? 

例如，在 Todo 工具的例子中，仅仅把 status 列为 pending、in_progress 和 completed 之间的枚举，就向 Claude 暗示了该如何使用它。关于始终保持一个条目处于 in_progress 状态的说明，有助于明确我们所期望的行为。

> For example, in the Todo tool example, just listing status as an enumeration between pending, in_progress, and completed, hints to Claude about how to use it. The instruction on keeping one item in_progress helps define our requested behavior.

##### 那么：把它们全部放在最前面

> Then: Put it all upfront

##### 现在：使用渐进式披露

> Now: Use progressive disclosure

由于 Claude Code 专注于编程，我们的系统提示词中包含了关于如何进行代码审查和验证的详细信息。这些信息并非总是需要，但在需要的时候，它们就是至关重要的信息。

> Because Claude Code was focused on coding, our system prompt included detailed information on how to do code review and verification. These were not always needed, but when they were, it was crucial information.

从那时起，Claude Code 在使用渐进式披露方面变得非常在行——在恰当的时机加载恰当的上下文。例如，我们把验证和代码审查移入了各自独立的技能中，供 Claude Code 有选择地调用。

> Since then, Claude Code has gotten very competent at using progressive disclosure- loading the right context at the right times. For example, we moved verification and code review into their own skills that Claude Code could selectively call.

但渐进式披露不仅用于技能，我们也把它用在工具上。我们的一些工具是「延迟加载」的，也就是说智能体在使用它们之前，必须先通过 ToolSearch 搜索它们的完整定义。这让我们能够拥有更多工具（例如我们的 Task 工具），而它们在被需要之前不会占用上下文。

> But progressive disclosure is not just for skills, we also use it for tools. Some of our tools are ‘deferred loading,’ which means the agent must search for their full definitions using ToolSearch before using them. This allows us to have more tools (such as our Task tools) that don’t take up context until they’re needed.

同样的道理也适用于你自己的 CLAUDE.md 和 Skill.md 文件。一个常见的误解是，你想把这些文件做成一个集中的仓库，收录你*可能*遇到的每一项已知实践，因为否则 Claude 就找不到它们。相反，[可以考虑构建一个文件树，让它们在恰当的时机被加载](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code)。

> The same can be applied to your own CLAUDE.md and Skill.md files. A common myth is that you want to make these a central repository for every known practice that you *might* run into, because Claude would not find it otherwise. Instead, [consider having a tree of files that can be loaded at the right time](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code).

##### 那么：重复你自己

> Then: Repeat yourself

##### 现在:简单的工具描述

> Now: Simple tool descriptions

早期的 Claude 模型有时需要重复给出指令，或者更倾向于听从上下文窗口末尾的指令而非开头的指令。这意味着我们的系统提示词有时会在主系统提示词中提到工具，同时也在工具描述中给出指令。

> Earlier Claude models could sometimes need repeated instructions or be more likely to listen to instructions at the end of their context window than at the start. This meant our system prompt would sometimes have references to tools in the main system prompt as well as instructions in the tool description. 

我们发现可以删掉这些重复的示例，把如何使用工具的说明放到工具描述里，而不是放在系统提示中。

> We found we could delete these repeat examples and put instructions on how to use tools in the tool descriptions rather than the system prompt.

##### 当时：CLAUDE.md 文件中的记忆

> Then: Memory in CLAUDE.md files

##### 现在：自动记忆

> Now: Auto-memory

我们过去会鼓励用户把内容保存到 Claude 的记忆中，方法是使用 # 快捷键自动写入他们的 [CLAUDE.md](http://claude.md)。现在，Claude 会自动保存与工作以及与你相关的记忆。

> We used to encourage users to save things to Claude’s memory, by using the # hotkey to write to their [CLAUDE.md](http://claude.md) automatically. Instead, Claude now automatically saves memories that are relevant to the work and to you. 

##### 当时：简单的规范

> Then: Simple specs

##### 现在：丰富的引用

> Now: Rich references

在计划模式下，Claude Code 大量依赖包含计划的 markdown 文件。把这些文件存储为计划，有助于 Claude 在需要时参考它们。另一个类似的最佳实践是把规格说明存储在代码库中，供 Claude 在跨越较长周期的项目中工作时参考。

> In plan mode, Claude Code has heavily relied on markdown files with plans. Storing these files as plans helped Claude refer to them when needed. Another similar best practice was to store specs in the codebase for Claude to refer to while working across longer projects.

但我们发现，Claude 能够处理越来越复杂的引用。除了简单的 markdown 文件之外，Claude 还可以引用由我们新的 artifacts 功能创建的 HTML artifacts。

> But we’ve found that Claude can handle increasingly more complicated references. Instead of simple markdown files, Claude can reference HTML artifacts created by our new artifacts feature. 

你也可以以代码的形式为 Claude 提供参考。规范也可以是一套详细的测试套件，或者是另一个代码库中 Claude 可以移植的某个函数。

> You may also give Claude references in the form of code. A spec may also be a detailed test suite, or a function in a different codebase that Claude might port. 

评分标准（Rubrics）是参考资料的另一种形式。评分标准让 Claude 能够通过[动态工作流](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code)并依据这些评分标准启动验证器 agent，来尝试验证你在某个特定领域中的品味（例如，好的 API 设计应该是什么样的）。

> Rubrics are another form of references. Rubrics allow Claude to try and verify your taste in a particular field (e.g. what does a good API design look like) by using [dynamic workflows](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code) and spinning up verifier agents with those rubrics.

#### 将这一点应用到你的具体情境中

> Applying this to your context

把这些整合起来，当你组装上下文时，看起来会是什么样子？

> Pulling this all together, what does this look like when you assemble your context?

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a63620bedb2b7813b10721a_836a850d.png)

##### 系统提示词

> System Prompt

系统提示词与产品上下文紧密绑定。它告诉 Claude 自己运行在什么产品中、正在做什么。对于 Claude Code，你大概永远不需要修改它；但如果你要构建自己的 agent harness，这里就是你应该投入大量时间的地方。

> A system prompt is heavily tied to the product context. It tells Claude what product it’s operating in and what it’s doing. For Claude Code, you will likely never modify this, but if you are building your own agent harness, this is where you should spend a lot of time.

##### CLAUDE.md

> CLAUDE.md

保持你的 CLAUDE.md 轻量，简要说明你的仓库是做什么的，但把大部分 token 花在代码库内部的坑点上。例如，你可能会把类型都组织在一个单体文件中，别处不再存放。避免陈述那些 Claude 通过查看你的文件系统或仓库就能知道的『显而易见』的内容。

> Keep your CLAUDE.md lightweight and briefly describe what your repo is for, but spend most of the tokens on gotchas inside of the codebase. For example, you may organize your code to keep types in one monolithic file and nowhere else. Avoid stating ‘the obvious’ things Claude should know by looking at your file system or your repo.

大量使用渐进式披露，例如，如果你有若干关于如何验证工作成果的独特说明，就创建一个验证技能（skill），并在 CLAUDE.md 中引用它。

> Use progressive disclosure heavily, for example if you have several unique instructions on how to verify your work, create a verification skill and reference it from your CLAUDE.md.

##### 技能

> Skills

把 skills 看作轻量级的指引，让 Claude 在需要时能够找到信息。除了在极为重要的领域之外，不要把它们写得过度约束。

> Think of skills as lightweight guides to let Claude find information when needed. Avoid making them overconstrained, except in highly important areas. 

对于篇幅较长的技能，请尽可能采用渐进式披露——将其拆分成多个文件并分开存放。

> For long skills, try and use progressive disclosure as much as possible- divide it into many files and split them out.

当技能编码的是你、你的团队或产品所特有的观点、知识或最佳实践时，效果最好。

> It’s best when skills encode particular opinions, knowledge, or best practices that are particular to you, your team, or product. 

##### 参考文献 

> References 

你可以使用 @ 提及文件，将它们作为引用包含进来。引用让 Claude 能够查阅关于当前计划的详细信息。

> You can @ mention files to include them as references. References allow Claude to refer to in-depth information about the current plan. 

这些内容可能存在于规格文件、原型稿，甚至整个代码库中。一般来说，你应该优先选择以代码形式存在的文件，因为它能以 Claude 非常熟悉的语言向它提供清晰、高保真的指令。例如，一份设计的 HTML 原型通常比对该设计的文字描述或截图能产出更好的结果。

> This might be in specs files, mockups, or even entire codebases. Generally you should prefer files that are in code as it provides clear, high-fidelity instructions to Claude in a language it knows very well. For example, a HTML mockup of a design will generally produce better results than a description of the design or a screenshot.

#### 试着简化

> Try simplifying

在你的系统提示词、技能和 CLAUDE.md 文件中，你可能需要像我们一样做一次精简。我们推出了一个名为 `claude doctor` 的新命令，它也能帮你自动完成这件事。关于如何专门为更高级的模型编写提示词的更多细节，请查看我们的[Fable 实用指南](https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns)。

> Across your system prompt, skills, and CLAUDE.md files, you may need to simplify just like we did. We rolled out a new command called `claude doctor,` which will help you do this automatically as well. For more details on prompting more advanced models specifically, check out our [Fable field guide](https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns).

*本文由 Anthropic 技术团队成员 Thariq Shihipar 撰写。*

> *This article was written by Thariq Shihipar, member of technical staff, Anthropic.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| context engineering | 上下文工程 | 有意识地组装并管理模型在每次请求中所接收全部上下文的实践。 |
| system prompt | 系统提示词 | 绑定产品形态的底层指令，告知模型自身运行环境与职责。 |
| CLAUDE.md | CLAUDE.md 文件 | 放在代码库中、供 Claude 读取的项目说明与指引文件。 |
| Skills | 技能 | 可按需加载的轻量指引模块，承载特定领域的知识与最佳实践。 |
| progressive disclosure | 渐进式披露 | 只在恰当时机加载恰当上下文，而非一次性全部前置的策略。 |
| agent harness | 智能体运行框架 | 包裹模型、提供工具与上下文装配逻辑的外层系统。 |
| lazy loading | 延迟加载 | 工具定义在被真正需要前不占用上下文的加载方式。 |
| ToolSearch | 工具检索 | 智能体用来搜索并获取延迟加载工具完整定义的机制。 |
| artifacts | 工件 | Claude 生成的可复用产物，如可被反过来引用的 HTML 原型。 |
| rubric | 评分标准 | 描述某领域优劣判据的参考材料，可供验证器 agent 依据评估。 |
| verifier agent | 验证器智能体 | 依据评分标准对产出进行独立校验的子智能体。 |
| dynamic workflows | 动态工作流 | 按任务需要动态编排步骤与子智能体的执行方式。 |
| plan mode | 计划模式 | Claude Code 中先产出并依赖 markdown 计划文件再执行的工作模式。 |
| spec | 规格说明 | 存放在代码库中、供长周期项目持续参考的需求或设计描述。 |
| claude doctor | claude doctor 命令 | 用于自动检查并精简技能与 CLAUDE.md 规模的新命令。 |
