---
source: claude-blog
source_url: https://claude.com/blog/harnessing-claudes-intelligence
published_at: 2026-04-02
category: Claude Blog
title_en: Harnessing Claude’s intelligence
title_zh: 驾驭 Claude 的智能
source_intro_paragraphs: 0
source_image_count: 7
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/m9bN7RYPWdlg2n09IK2B3d6xWZd1wyK0"
---

# 驾驭 Claude 的智能

> 来源：Claude Blog，2026-04-02
> 原文链接：https://claude.com/blog/harnessing-claudes-intelligence
> 分类：Claude Blog

## 导语

构建在智能、延迟和成本之间取得平衡的应用程序。

## 核心要点

- Anthropic 联合创始人 Chris Olah 认为，像 Claude 这样的生成式 AI 系统更多是"生长"出来的，而非"建造"出来的，因此构建时所做的假设会随着 Claude 能力增强而过时。
- 应使用 Claude 已经熟练掌握的工具（如 bash 和文本编辑器工具）来构建应用，Claude 能将这些通用工具组合成解决不同问题的模式。
- 应不断追问"我可以停止做什么"，让 Claude 自行编排动作、管理上下文、持久化上下文，例如通过代码执行、技能（Skills）、压缩（compaction）和记忆文件夹。
- 在为应用设置边界时要谨慎，针对用户体验、可观测性或安全边界使用声明式专用工具，并通过缓存命中优化成本。
- Claude 的智能前沿不断变化，需在每次能力跃迁后重新检验既有假设，并修剪掉已成为负担的结构。

## 中文译文

Anthropic 的联合创始人之一 Chris Olah 说，像 Claude 这样的生成式 AI 系统，与其说是被建造出来的，不如说是被生长出来的。研究人员设定条件来引导其生长，但最终涌现出的确切结构或能力并不总是可预测的。

这给基于 Claude 进行构建带来了一项挑战：智能体框架（agent harness）编码了关于 Claude 自身无法做到哪些事情的假设，而随着 Claude 能力增强，这些假设会变得过时。即便是像本文这样分享的经验，也值得经常重新审视。

在本文中，我们分享三种模式，团队在构建应用时应当使用它们，从而在平衡延迟和成本的同时，跟上 Claude 不断演进的智能：使用它已经掌握的知识、追问你可以停止做什么、以及谨慎地用智能体框架设置边界。

### 1. 使用 Claude 已经掌握的知识

我们建议使用 Claude 充分理解的工具来构建应用。

2024 年末，Claude 3.5 Sonnet 在 SWE-bench Verified 上达到了 49%——这在当时是业界最高水平——而它仅使用了一个 bash 工具和一个用于查看、创建和编辑文件的文本编辑器工具。Claude Code 正是建立在这些相同的工具之上。bash 并非为构建智能体而设计，但它是 Claude 知道如何使用、并且会随时间越用越好的一个工具。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd8747994e07042a959518_image2.png)

我们看到 Claude 将这些通用工具组合成解决不同问题的模式。例如，智能体技能（Agent Skills）、程序化工具调用（programmatic tool calling）以及记忆工具（memory tool）都是基于 bash 和文本编辑器工具构建的。

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd8835161641fba4aa1def_image4.png)

### 2. 追问"我可以停止做什么？"

智能体框架编码了关于 Claude 自身无法做到哪些事情的假设。随着 Claude 能力增强，这些假设应当被检验。

让 Claude 编排它自己的动作

一个常见的假设是：每一个工具结果都应当流回 Claude 的上下文窗口，以便为下一个动作提供信息。如果工具结果只需要传递给下一个工具，或者 Claude 只关心输出中很小的一部分，那么以 token 形式处理工具结果可能既缓慢又昂贵，而且没有必要。

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd889c76e6e17dbe4ff4b9_image7.png)

设想读取一个大表格只为了对其中某一列进行推理：整个表格都会进入上下文，而 Claude 要为它并不需要的每一行支付 token 成本。可以通过工具设计来应对这一点，使用硬编码的过滤器（filters）。但这并未解决这样一个事实：智能体框架正在做出一个编排决策，而 Claude 才更适合做这个决策。

给 Claude 一个代码执行工具（例如 bash 工具或特定语言的 REPL）可以解决这个问题：它让 Claude 能够编写代码来表达工具调用以及调用之间的逻辑。与其由框架决定每一个工具调用结果都被处理为 token，不如让 Claude 决定哪些结果要传递、过滤，或者管道（pipe）输入到下一个调用中，而不触及上下文窗口。只有代码执行的输出才会进入 Claude 的上下文窗口。

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd891f5b4d2dea57b008d1_image6.png)

编排决策从框架转移到了模型。由于代码是 Claude 编排动作的一种通用方式，一个强大的编码模型同时也是一个强大的通用智能体。Claude 使用这种模式在非编码评测上表现出色：在 BrowseComp（一个测试智能体浏览网页能力的基准）上，赋予 Opus 4.6 过滤其自身工具输出的能力，将准确率从 45.3% 提升到了 61.6%。

让 Claude 管理它自己的上下文

任务特定的上下文引导着 Claude 对 bash 和文本编辑器工具等通用工具的使用。一个常见的假设是：系统提示词应当用任务特定的指令手工精心打造。问题在于，将指令预加载进提示词无法在大量任务之间扩展：每增加一个 token 都会消耗 Claude 的注意力预算，而用很少使用的指令来预加载上下文是一种浪费。

赋予 Claude 访问技能的能力可以解决这个问题：每个技能的 YAML 前置元数据（frontmatter）是预加载到上下文窗口中的一段简短描述，提供该技能内容的概览。如果某个任务需要，Claude 可以通过调用读取文件工具来逐步披露（progressively disclosed）完整的技能内容。

![Image 5](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd895f7f04456cccf7b7e0_image3.png)

如果说技能赋予 Claude 自由组装自己上下文窗口的能力，那么上下文编辑（context editing）则是其反面，它提供了一种方式来选择性地移除那些已经过时或无关的上下文，例如旧的工具结果或思考块（thinking blocks）。

借助子智能体（subagents），Claude 越来越善于知道何时分叉（fork）出一个全新的上下文窗口，以隔离对某个特定任务的工作。在 Opus 4.6 上，生成子智能体的能力使 BrowseComp 上的结果比最佳的单智能体运行提升了 2.8%。

让 Claude 持久化它自己的上下文

长时间运行的智能体可能会超出单个上下文窗口的限制。一个常见的假设是：记忆系统应当依赖围绕模型的检索基础设施。我们的大部分工作都集中在赋予 Claude 简单的方式，让它自行选择要持久化哪些内容。

例如，压缩（compaction）让 Claude 能够总结它过去的上下文，以便在长跨度任务上保持连续性。在数次发布中，Claude 在选择记住什么方面越来越好。例如，在 BrowseComp 这一智能体搜索任务上，无论我们给 Sonnet 4.5 多少压缩预算，它都停留在 43% 不变。然而在相同的设置下，Opus 4.5 扩展到了 68%，Opus 4.6 达到了 84%。

记忆文件夹（memory folder）是另一种方法，它允许 Claude 将上下文写入文件，并在之后按需读取。我们看到 Claude 将其用于智能体搜索。在 BrowseComp-Plus 上，给 Sonnet 4.5 一个记忆文件夹将准确率从 60.4% 提升到了 67.2%。

![Image 6](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd89bfccdc7c50beb40e0d_image5.png)

长跨度游戏（long-horizon games），例如宝可梦（Pokémon），是 Claude 使用记忆文件夹能力提升的一个例子。Sonnet 3.5 把记忆当作一份逐字记录，写下了非玩家角色（NPC）说了什么，而不是写下什么才是重要的。在 14,000 步之后，它有 31 个文件——其中包括两个关于毛虫类宝可梦的近乎重复的文件——而且仍然停留在第二个城镇：

```text
caterpie_weedle_info: - Caterpie and Weedle are both caterpillar Pokémon. - Caterpie is a caterpillar Pokémon that does not have poison. - Weedle is a caterpillar Pokémon that does have poison. - This information is crucial for future encounters and battles. - If our Pokémon get poisoned, we should seek healing at a Pokémon Center as soon as possible.
```

后来的模型则写下了战术笔记。在相同的步数下，Opus 4.6 有 10 个被组织进目录的文件、三枚道馆徽章，以及一个从它自身失败中提炼出来的"经验"文件：

```text
/gameplay/learnings.md: - Bellsprout Sleep+Wrap combo: KO FAST with BITE before Sleep Powder lands. Don't let it set up! - Gen 1 Bag Limit: 20 items max. Toss unneeded TMs before dungeons. - Spin tile mazes: Different entry y-positions lead to DIFFERENT destinations. Try ALL entries and chain through multiple pockets. - B1F y= 16 wall CONFIRMED SOLID at ALL x= 9 -28 (step 14557 )
```

### 3. 谨慎设置边界

智能体框架在 Claude 周围提供结构，以强制实施用户体验（UX）、成本或安全方面的约束。

设计上下文以最大化缓存命中

Messages API 是无状态的。Claude 无法看到先前轮次的对话历史。这意味着智能体框架需要在每一轮中，将新的上下文与所有过去的动作、工具描述和指令一起打包给 Claude。

提示词可以基于设定的断点（breakpoints）进行缓存。换句话说，Claude API 将断点之前的上下文写入缓存，并检查该上下文是否与任何先前的缓存条目相匹配。

由于缓存 token 的成本是基础输入 token 的 10%，以下是智能体框架中有助于最大化缓存命中的几条原则：

为用户体验、可观测性或安全边界使用声明式工具

Claude 不一定知道一个应用的安全边界或用户体验界面。Claude 发出工具调用，由框架来处理。bash 工具给予 Claude 广泛的程序化能力去执行动作，但它只给框架一个命令字符串——对每个动作都是相同的形态。将动作提升为专用工具，则给予框架一个针对特定动作的钩子，带有类型化参数，框架可以拦截、把关（gate）、渲染或审计它。

需要安全边界的动作天然适合作为专用工具的候选。可逆性通常是一个好的判断标准，像外部 API 调用这类难以逆转的动作可以通过用户确认来把关。像 edit 这样的写入工具可以包含一项陈旧性检查（staleness check），这样 Claude 就不会覆盖一个自上次读取后已被更改的文件。

![Image 7](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69cd8ebecb4a73207c8b2ffc_image1.png)

当一个动作需要呈现给用户时，工具也很有用。例如，它们可以被渲染为一个模态框（modal），向用户清晰地展示一个问题、给用户提供多个选项，或者阻塞智能体循环直到用户提供反馈。

最后，工具对可观测性也很有用。当动作是一个类型化工具时，框架会获得结构化的参数，可以对其进行日志记录、追踪和回放。

将动作提升为工具的决策应当被持续地重新评估。例如，Claude Code 的自动模式（auto-mode，发布时处于研究模式）为 bash 工具提供了一个安全边界：它让第二个 Claude 读取命令字符串并判断其是否安全。这种模式可以减少对专用工具的需求，并且只应用于用户信任其总体方向的任务。对于某些高风险动作，专用工具仍然有其存在的价值。

### 展望

Claude 智能的前沿一直在变化。关于 Claude 无法做到哪些事情的假设，需要在它能力的每一次阶跃变化时被重新检验。

我们看到这个模式反复出现。在我们为长跨度任务构建的一个智能体中，Sonnet 4.5 会在感觉到上下文限制临近时过早收尾。我们添加了重置机制来清空上下文窗口，以应对这种"上下文焦虑"。到了 Opus 4.5，这种行为消失了。我们为弥补而构建的上下文重置，变成了智能体框架中的累赘。

移除这种累赘很重要，因为它可能成为 Claude 性能的瓶颈。随着时间推移，我们应用中的结构或边界应当基于这个问题来进行修剪：我可以停止做什么？

要使用本文讨论的所有工具和模式，请查看我们的 claude-api 技能。

### 致谢

本文由 Lance Martin 撰写，他是 Claude Platform 团队的技术成员。特别感谢 Thariq Shihipar、Barry Zhang、Mike Lambert、David Hershey 和 Daliang Li 就所涉主题进行的有益讨论。感谢 Lydia Hallie、Lexi Ross、Katelyn Lesse、Andy Schumeister、Rebecca Hiscott、Jake Eaton、Pedram Navid 和 Molly Vorwerck 的编辑审阅与反馈。

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
