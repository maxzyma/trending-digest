---
source: claude-blog
source_url: https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns
published_at: 2026-07-06
category: Claude Code
title_en: "A field guide to Claude Fable 5: Finding your unknowns"
title_zh: "Claude Fable 5 实地指南：发现你的未知"
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 6
source_image_count: 3
---

# Claude Fable 5 实地指南：发现你的未知

> A field guide to Claude Fable 5: Finding your unknowns

> 来源：Claude Blog，2026-07-06
> 原文链接：https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns
> 分类：Claude Code

## 核心要点

- 作者把交给 Claude 的提示词、技能与上下文比作「地图」，把真实的代码库与约束条件比作「疆域」，两者之间的差距即为「未知」。
- Fable 5 是首个让作者感到工作质量的瓶颈在于「自己能否澄清未知」的模型。
- 未知可分为四类：已知的已知、已知的未知、未知的已知、未知的未知；优秀的智能体编程者未知较少且会为未知预留空间。
- 指令过于具体会让 Claude 死板执行、错过更好的转向；过于含糊则会让它套用不一定契合的行业惯例。
- 应向 Claude 交代起点、你的经验与思路，让它作为「思考伙伴」并利用其快速检索与迭代能力帮你更快发现未知。
- 作者给出贯穿实现前、中、后的实践模式：盲点扫描、头脑风暴与原型、访谈、参考资料、实现计划、实现笔记、路演与讲解、测验。
- 「盲点扫描」用于在陌生领域挖掘未知的未知；「头脑风暴与原型」用于在实现前尽早识别只可意会的未知的已知，避免后期返工。

## 正文

在使用 Claude Code 时，我常常想起地图与疆域之间的区别。

> When working with Claude Code, I’m often reminded of the difference between the map and the territory.

地图，即对待办工作的表征，就是我的提示词、技能和上下文，是我交给 Claude 的东西。疆域则是工作真正发生的地方——代码库、现实世界，以及它实际存在的种种约束。

> The map, a representation of the work to be done, is my prompts and skills and context, it’s what I give Claude. The territory is where the work needs to happen, the codebase, the real world, its actual constraints.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4be4919e159adcdfa3ec1c_94358c3c.png)

地图与疆域之间的差异，就是我所说的未知（unknowns）。当 Claude 遇到一个未知时，它需要基于对我意图的最佳猜测来做决定。要做的工作越多，Claude 可能遇到的未知就越多。

> The difference between the map and the territory is what I call unknowns . When Claude runs into an unknown, it needs to make a decision based on its best guess of what I want. The more work being done, the more unknowns Claude might run into.

Claude Fable 是第一个让我觉得工作质量的瓶颈在于我澄清其未知能力的模型。

> Claude Fable is the first model where I find the quality of the work is bottlenecked by my ability to clarify its unknowns.

重要的是，仅仅提前规划并不总是足够。你可能在实现的深处才发现未知，或者你的未知会指向一个事实：你其实应该用一种完全不同的方式来解决这个问题。

> Importantly, just planning ahead isn’t always enough. You can find unknowns deep in implementation, or your unknowns may point you to the fact that you should actually be solving the problem in a different way altogether.

我发现，与 Fable 协作是一个迭代的过程——在实现之前、之中和之后不断发现我的未知。

> I’ve found that working with Fable is an iterative process of discovering my unknowns before, during, and after implementation.

### 了解你的未知

> Knowing your unknowns

你的未知是什么？当我带着一个问题去找 Claude 时，我倾向于从四个方面来拆解它：

> What are your unknowns? When I come to Claude with a problem I tend to break it down in 4 ways:

- 已知的已知（Known Knowns）：这本质上就是我提示词里的内容。我要告诉智能体（agent）我想要什么？
- 已知的未知（Known Unknowns）：有哪些是我还没弄清楚，但我意识到自己还没弄清楚的？
- 未知的已知（Unknown Knowns）：有哪些东西太显而易见，以至于我永远不会写下来，但如果看到它我会认出来？
- 未知的未知（Unknown Unknowns）：有哪些是我完全没有考虑过的？有哪些知识是我根本没意识到的？我是否知道某样东西能做到多好？

> • Known Knowns: This is essentially what is in my prompt. What do I tell the agent that I want?
> • Known Unknowns: What haven't I figured out yet, but I’m aware that I haven’t?
> • Unknown Knowns: What's so obvious I’d never write it down, but would recognize it if I saw it?
> • Unknown Unknowns: What haven't I considered at all? What knowledge am I not aware of? Do I know how good something can be?

最优秀的智能体编程者（agentic coder）的未知相对较少。看着像 Boris 或 Jarred 这样的人写提示词时，我很明显地感觉到他们对自己想要什么了如指掌。他们与代码库和模型行为都深度同步。

> The best agentic coders have relatively few unknowns. Watching someone like Boris or Jarred prompt, it is obvious to me that they know what they want in-detail. They are deeply in-sync with both the codebase and the model behaviors.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4be4919e159adcdfa3ec52_cc0ee2de.png)

但他们也会假定存在未知。在许多方面，减少并为你的未知做规划正是智能体编程的核心技能。但幸运的是，这是一项你可以通过与 Claude 协作而不断提升的技能。

> But they also assume unknowns. In many ways, reducing and planning for your unknowns is the skill of agentic coding. But luckily, this is a skill you can improve at, by working with Claude.

### 帮助 Claude 帮助你

> Help Claude help you

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4be4919e159adcdfa3ec55_c4646783.png)

给 Claude 下达指令是一种微妙的平衡。如果你太具体，Claude 会遵循你的指令，即便调整方向可能更合适。如果你太含糊，Claude 往往会基于行业最佳实践做出选择和假设，而这些未必适合你的任务。

> Instructing Claude is a delicate balance. If you are too specific, Claude will follow your instructions even when a pivot may be more appropriate. If you are too vague, Claude will often make choices and assumptions based on industry best practices that may not be a fit for your task.

当你没有考虑到自己的未知之处时，两种情况都会失败。你不知道什么时候路上会布满障碍，也不知道什么时候路会畅通，但你仍然希望 Claude 转向。

> When you don’t account for your unknowns, you fail both ways. You don't know when the path will be filled with obstacles, and you don’t know when the path will be clear, but you still want Claude to veer.

Claude 能帮你更快地发现自己的未知之处。它可以极快地搜索你的代码库和互联网，而且对一般话题的了解远超过你。它还能从失败中更快地迭代。

> Claude can help you discover your unknowns faster. It can search through your codebase and the internet extremely quickly, and it knows much more about the average topic than you. It can also iterate from failure faster.

这个过程中最重要的部分，是给 Claude 提供关于你起点的背景信息。例如，告诉它你的思考进展到哪一步；坦白你对这个问题和代码库的经验；让它像思考伙伴一样与你协作。

> The most important part of this process is to give Claude context about your starting point. For example, tell it where you are in your thought process; disclose your experience with the problem and codebase; and let it work with you like a thought partner.

在本文中，我详细介绍了一些我用来揭示这些未知之处的模式，包括：

> In this article I detail some of the patterns I use to uncover these unknowns including:

实现前：

> Pre-implementation:

- 盲点排查
- 头脑风暴与原型
- 访谈
- 参考资料
- 实现计划

> • Blind spot pass
> • Brainstorms and prototype
> • Interviews
> • References
> • Implementation plan

实现过程中：

> During implementation:

- 实现笔记

> • Implementation notes

实现后

> Post implementation

- 推介与讲解
- 测验

> • Pitches and explainers
> • Quizzes

### 实现前

> Pre-implementation

#### 盲点扫描

> Blind Spot Pass

开始一项工作时，最有用的事情之一是了解自己的盲点。例如，如果你正在代码库的新部分编写功能，或者借助 Claude 帮你完成不熟悉的工作（比如迭代某个设计），你很可能会有大量的未知的未知（unknown unknowns）。

> When starting work, one of the most useful things you can do is understand your blind spots. For example, if you’re writing a feature in a new part of the codebase, or using Claude to help you with unfamiliar work like iterating on a design, you’re likely to have a lot of unknown unknowns .

你可能不知道该问什么问题、好的标准是什么样、历史上做过哪些工作，或者要避开哪些坑。

> You may not know what questions to ask, what good looks like, what historical work has been done, or what potholes to avoid.

在这些情况下，你可以让 Claude 帮你找出这些未知的未知并向你解释。我喜欢直接用「盲点扫描（blind spot pass）」和「未知的未知」这样的字眼。向它提供关于你是谁、你知道什么的背景信息，通常对 Claude 理解如何与你开始协作很重要。

> In these situations, you can ask Claude to help you find your unknown unknowns and explain them to you. I like to use the literal words “blind spot pass” and “unknown unknowns.” Giving it context on who you are and what you know is usually important for Claude to understand the best way to start collaborating with you.

示例提示词：

> Example prompts :

- “我正在为代码库添加一个新的认证提供方，但我对这个代码库里的认证模块一无所知。你能做一次盲点扫描，帮我理清相关的未知的未知，并帮助我更好地向你提问吗？”
- “我不知道什么是调色（color grading），但我需要给这段视频调色。你能教我理解自己关于调色的未知的未知，好让我能更好地向你提问吗？”

> • “I'm working on adding a new auth provider but I know nothing about the auth modules in this codebase. Can you do a blind spot pass to help me figure out my relevant unknown unknowns and help me prompt you better.”
> • “I don’t know what color grading is but I need to grade this video. Can you teach me to understand my unknown unknowns about color grading, so that I can prompt better?”

#### 头脑风暴与原型

> Brainstorms and prototypes

当我在一个存在大量未知的已知（unknown knowns）的领域工作时——那些我只有看到才知道该如何定义的标准——我喜欢让 Claude 和我一起头脑风暴并做原型。

> When I’m working in an area with a lot of unknown knowns , involving criteria I only know to define when I see it, I like to ask Claude to brainstorm and prototype with me.

在原型阶段尽早识别并说出这些未知的已知非常有价值，因为在实现阶段才发现它们代价（相对）高昂。功能或规格上的小改动可能导致代码实现截然不同，而且让你的智能体回退之前的改动可能更加困难。

> It’s extremely valuable to identify and verbalize unknown knowns early during prototyping, because finding them out during implementation can be (relatively) expensive. Small changes in a feature or spec can cause drastically different implementations in code, and it can be more difficult for your agent to revert previous changes.

例如，你可能只想看看在一个界面框里加个按钮是什么样子，而不必接通后端路由或在前端维护额外的状态。

> For example, you may just want to see how a button added to a frame looks without having to wire up a backend route or maintaining additional state in the frontend.

另一个例子是视觉设计，对我来说这是难以言表的东西，但我看到想要的就知道。在这些情况下，我会为一个产物索要几种不同的设计方案。

> Another example is visual design, which for me, is something that is difficult to articulate, but I know what I want when I see it. In these cases, I’ll ask for several design approaches to an artifact.

我几乎每次编码会话都以探索或头脑风暴阶段开始。这帮助我带着意图起步，去界定项目的范围。Claude 常常能找到我会错过的高价值方案，有时也会只见树木不见森林。头脑风暴让我不至于把范围设得太窄或太宽。

> I also start almost every coding session with an exploration or brainstorming phase. This helps me start with intent to define the project’s scope. Claude often finds high-value approaches I would have missed, and sometimes misses the forest through the trees. Brainstorming prevents me from setting too narrow or too wide a scope.

示例提示词：

> Example prompts:

- “我想为这些数据做一个仪表盘，但我没有视觉审美，也不知道有哪些可能性。给我做一个 HTML 页面，包含 4 个风格迥异的设计方向，好让我做出反应。”
- “在接通任何东西之前，用假数据做一个单独的 HTML 文件，模拟新的编辑器工具栏。我想在你动真正的应用之前先对布局做出反应。”
- “这是我大致的问题：用户在引导（onboarding）之后流失。搜索代码库，头脑风暴出 10 个我们可以介入的地方，从最省成本到最有雄心排列。我会告诉你哪些让我有共鸣。”

> • "I want a dashboard for this data but I have no visual taste and don't know what's possible. Make me an HTML page with 4 wildly different design directions so I can react to them.”
> • “Before wiring anything up, make a single HTML file mocking the new editor toolbar with fake data. I want to react to the layout before you touch the real app."
> • "Here's my rough problem: users churn after onboarding. Search the codebase and brainstorm 10 places we could intervene, from cheapest to most ambitious. I'll tell you which ones resonate."

#### 访谈

> Interviews

一旦我做了足够的头脑风暴，我很可能仍然存在一些未知。

> Once I’ve done sufficient brainstorming, I likely still have unknowns.

这种情况下，我会让 Claude 就任何未知或含糊之处对我进行访谈。让 Claude 访谈你时，尽量给它提供关于你问题的背景，以引导它的提问。

> In this case, I ask Claude to interview me about any unknowns or ambiguities. When asking Claude to interview you, try and give it context about your problem to guide its questions.

‍ 示例提示词：

> ‍ Example prompt:

- “就任何含糊之处一次一个问题地访谈我，优先提出那些我的回答会改变架构的问题。”

> • "Interview me one question at a time about anything ambiguous, prioritize questions where my answer would change the architecture."

#### 参考

> References

有时你无法详细描述你想要什么。例如，你可能缺乏相应的语言，或者它复杂到你需要花相当长时间才能说清。

> Sometimes you can’t describe what you want in detail. For example, you might not have the language or it might be so complicated that it would take you quite a while.

这种情况下，最好的办法是给一个参考。虽然你可以附上图表、文档或图片，但绝对最好的参考是源代码（source code）。

> In this case, the best approach is a reference. While you can include diagrams, documentation or pictures, the absolute best reference is source code .

如果你有一个以某种方式实现了某功能的库，或者一个你非常喜欢的设计组件，只要把 Fable 指向那个文件夹并告诉它要找什么，即使是用另一种语言写的也行。相比于截图之类的东西，这能为 Claude 提供关于标记（markup）和结构远为丰富的细节。

> If you have a library that implements something in a certain way or a design component you really like, just point Fable at the folder and tell it what to look for, even if it’s in a different language. This provides Claude much richer detail around the markup and structure, compared to for example a screenshot.

示例提示词：

> Example prompts:

- “vendor/rate-limiter 里的这个 Rust crate 实现了我想要的退避（backoff）行为。读一读它，并在我们的 TypeScript API 客户端里重新实现相同的语义。”

> • "This Rust crate in vendor/rate-limiter implements the exact backoff behavior I want. Read it and reimplement the same semantics in our TypeScript API client."

#### 实现计划

> Implementation Plans

当我觉得自己准备好实现时，我往往会让 Claude 整理一份实现计划供我审阅。计划聚焦于那些最可能变动的部分，比如数据模型、类型接口或用户体验流程。这让 Claude 能呈现出我可能真的需要改动的东西。

> When I think I’m ready to implement, I tend to ask Claude to put together an implementation plan for me to review. The plan focuses on the parts that might be most likely to change such as data models, type interfaces, or UX flows. This allows Claude to surface things I might actually need to alter.

示例提示词：

> Example prompt:

- “用 HTML 写一份实现计划，但要以我最可能调整的决策开头：数据模型的改动、新的类型接口，以及任何面向用户的部分。把机械性的重构放在最底部，那部分我信任你。”

> • "Write an implementation plan in HTML, but lead with the decisions I'm most likely to tweak with: data model changes, new type interfaces, and anything user-facing. Bury the mechanical refactoring at the bottom, I trust you on that part."

### 实施期间

> During implementation

#### 实施笔记

> Implementation notes

一旦我对计划满意，我就会新建一个会话，并把各种产物传入提示词。这样 Claude 就获得了一个全新的上下文窗口，同时又带着它在规划阶段汇编的全部信息。例如，我可能会传入一个规格文件和一个原型，然后让智能体去实现它。

> Once I am satisfied with my plan, I make a new session and pass any artifacts to the prompt. This gives Claude a fresh context window but with all of the information it compiled from your planning. For example, I might pass in a spec file and a prototype and ask an agent to implement it.

但事实是，无论你做多少规划，总有一些未知的未知（unknown unknowns）潜伏其中。智能体可能会在工作过程中发现，由于它在代码里遇到了某个边界情况，需要改换思路。

> But the truth is that no matter how much planning you do, there are always unknown unknowns lurking. The agent may find during its work that it needs to take a different tack due to an edge case it found in the code.

我会让 Claude Code 维护一个临时的 “implementation-notes.md”（或 .html）文件，让它在其中记录所做的决策，以便我们能为下一次尝试汲取经验。

> I ask Claude Code to keep a temporary ‘implementation-notes.md’ (or .html) file where it keeps track of decisions it makes so we can learn for our next attempt.

示例提示词：

> Example prompt:

- “维护一个 implementation-notes.md 文件。如果你遇到某个边界情况，迫使你偏离计划，就选择保守的方案，把它记录在‘Deviations（偏离）’下，然后继续推进。”

> • "Keep an implementation-notes.md file. If you hit an edge case that forces you to deviate from the plan, pick the conservative option, log it under 'Deviations', and keep going."

### 实施之后

> Post implementation

#### 提案与说明

> Pitches and explainers

交付某个东西最重要的环节之一，就是获得支持与批准。在最终文档中构建提案（pitch）和说明（explainer）材料有助于：

> One of the most important parts of shipping something is getting buy-in and approvals. Building pitch and explainer artifacts in the final document helps:

- 当评审者带着和你当初相同的未知点开始时，加速他们的理解
- 当专家想看到你已经考虑了他们会预料到的未知点和常见故障点时，加速批准

> • Accelerate understanding when reviewers start with the same unknowns you did
> • Accelerate approvals when experts want to see you accounted for the unknowns and common failure points they would have anticipated

示例提示词：

> Example prompt:

- “把原型、规格说明和实现笔记打包成一份文档，让我能直接丢到 Slack 上争取支持。开头先放演示 GIF。”

> • "Package the prototype, the spec, and the implementation notes into a single doc I can drop in Slack to get buy-in. Lead with the demo GIF."

#### 测验

> Quizzes

经过一段长时间的工作后，Claude 完成的东西可能比我意识到的多得多。阅读代码差异（diff）只能让我对发生的事情有一个粗浅的理解，因为很多行为都取决于已有的代码路径。

> After a long working session, Claude might have accomplished a lot more than I realized. Reading the code diffs can only give me a light understanding of what happened, since much of the behavior will depend on existing code paths.

在给我大量上下文之后，让 Claude 就这次变更对我进行测验，有助于我理解发生了什么。只有完美通过测验后，我才会合并。

> Asking Claude to quiz me about the change after giving me a bunch of context helps me understand what happens. I only merge after I pass the quiz perfectly.

示例提示词：

> Example prompt:

- “我想确保自己理解这次变更中发生的一切。给我一份关于这些变更的 HTML 报告，让我可以带着上下文、直觉去阅读理解，包括做了什么等等，并在末尾附上一个我必须通过的、关于这些变更的测验。”

> • “I want to make sure I understand everything that's happened in this change. Give me a HTML report on the changes for me to read and understand with context, intuition, what was done, etc. and a quiz at the bottom on the changes that I must pass.”

### 如何组合起来：发布 Fable

> How this comes together: launching Fable

Fable 的发布视频从头到尾都是用 Claude Code 剪辑的。这对我来说是一个全新的领域，我绝不是这方面的专家。

> The launch video for Fable was edited end-to-end using Claude Code. This was a new domain for me and I’m by no means an expert.

于是我从我已知的东西入手。我知道 Claude 可以用代码来剪辑和转录视频，但不确定它是否足够准确。接着我请 Claude 向我解释像 Whisper 这样的转录是如何工作的，以及我能否用 ffmpeg 准确地剪掉诸如"嗯"这样的语气词或较长的停顿。

> So I started with what I did know. I knew that Claude could use code to edit videos and transcribe them, but I wasn’t sure if it was accurate enough. I then asked Claude to explain to me how transcription like Whisper worked, and whether I would be able to accurately cut out things like ums or large pauses using ffmpeg.

我希望 Claude 创建一个与我所说的词语同步定时的界面（UI），但不确定这是否可行，于是我请 Claude 用 Remotion 和一份转录稿制作一个原型视频，看看能否行得通。

> I wanted Claude to create a UI that was timed with the words I was saying, but wasn’t sure it was possible so I asked Claude to create a prototype video using Remotion and a transcription to see if it would work.

最后，视频本身看起来有点暗淡，我知道这是调色（color grading）的结果，但我并不真正了解调色是什么。我的第一次尝试是让 Claude 做几个变体供我挑选，但我意识到，在调色这件事上，我并不知道"好"是什么样子。于是我改为请 Claude 教我了解调色，以发现我的未知之处。

> Finally, the video itself looked a bit muted, which I knew was the result of color grading but I didn’t really know what color grading was. My first pass attempt was to try and get Claude to do a few variations to pick, but I realized that I didn’t know what “good” looked like when it came to color grading. So instead, I asked Claude to teach me about color grading to discover my unknowns.

### 让地图与地形相符

> Matching the Map and Territory

模型越强，用对方法能取得的成果就越多。当一个长周期任务返回了错误结果，很可能你需要花更多时间界定自己的未知项，或者制定一份能让你和 Claude 在推进过程中不断调整的实施计划。

> The better models get, the more you can achieve with the right approach. When a long-horizon task comes back wrong, it's likely you need to spend more time defining your unknowns or creating an implementation plan that allows for you and Claude to adapt through them.

每一次讲解、头脑风暴、访谈、原型和参考，都是一种低成本的方式，让你在代价高昂、难以修复之前就发现自己此前不知道的东西。

> Every explainer, brainstorm, interview, prototype, and reference is a cheap way to find out what you didn't know before it gets expensive to fix.

所以，开始你的下一个项目时，不妨先请 Claude 帮你找出你的未知项。

> So start your next project by asking Claude to help you find your unknowns.

本文作者为 Thariq Shihipar，Anthropic 技术团队成员。

> This article was written by Thariq Shihipar, member of technical staff, Anthropic.

## 术语对照

| English | 中文 |
|---|---|
| map | 地图 |
| territory | 疆域 |
| unknowns | 未知 |
| Known Knowns | 已知的已知 |
| Known Unknowns | 已知的未知 |
| Unknown Knowns | 未知的已知 |
| Unknown Unknowns | 未知的未知 |
| agentic coding | 智能体编程 |
| Blind Spot Pass | 盲点扫描 |
| prototype | 原型 |
| Implementation Plan | 实现计划 |
| Implementation Notes | 实现笔记 |
| thought partner | 思考伙伴 |
| prompt | 提示词 |
