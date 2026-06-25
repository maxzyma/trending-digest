---
source: claude-blog
source_url: https://claude.com/blog/harnessing-claudes-intelligence
published_at: 2026-04-02
category: Claude Blog
title_en: Harnessing Claude’s intelligence
title_zh: 驾驭 Claude 的智能
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/mExel2BLV54XRmj6HP1MDrgyWgk9rpMq"
---

# 驾驭 Claude 的智能

> 来源：Claude Blog，2026-04-02
> 原文链接：https://claude.com/blog/harnessing-claudes-intelligence
> 分类：Claude Blog

## 核心要点

- Anthropic 联合创始人 Chris Olah 认为，像 Claude 这样的生成式 AI 系统更多是"生长"出来的，而非被"建造"出来的，其能力的演进难以完全预测。
- 智能体框架（agent harness）编码了关于"Claude 自身做不到什么"的假设，但随着 Claude 能力增强，这些假设会过时，需要频繁重新审视。
- 第一个模式：使用 Claude 已经熟悉的工具（如 bash 和文本编辑器工具）来构建应用。
- 第二个模式：不断追问"我可以停止做什么"，把编排（orchestration）、上下文管理与上下文持久化的决策权交还给 Claude。
- 让 Claude 通过代码执行工具自行编排工具调用，在 BrowseComp 基准上使 Opus 4.6 的准确率从 45.3% 提升到 61.6%。
- 第三个模式：谨慎设定边界，利用提示缓存（prompt caching）优化成本，并用声明式工具来强制约束用户体验、可观测性或安全边界。
- 应当持续修剪框架中因 Claude 能力提升而变成"死重"的结构，以免成为性能瓶颈。

## 中文译文

Anthropic 的联合创始人之一 Chris Olah 说，像 Claude 这样的生成式 AI（generative AI）系统，更多是被"生长"出来的，而不是被"建造"出来的。研究者设定条件来引导这种生长，但最终涌现出的确切结构或能力并不总是可预测的。

这给基于 Claude 的构建带来了一个挑战：智能体框架（agent harness）编码了关于"Claude 自己做不到什么"的假设，但随着 Claude 变得更强，这些假设会逐渐过时。即便是像本文这样的文章中分享的经验，也值得频繁重新审视。

在本文中，我们分享三种模式，团队在构建应用时应当采用它们，以便在跟上 Claude 不断演进的智能的同时，平衡延迟与成本：使用它已经掌握的知识、追问你可以停止做什么、以及谨慎地为智能体框架设定边界。

### 1. 利用 Claude 已掌握的知识

我们建议使用 Claude 已经充分理解的工具来构建应用。

在 2024 年底，Claude 3.5 Sonnet 在 SWE-bench Verified 上达到了 49%——当时的最高水平（state of the art）——而它仅使用了一个 bash 工具和一个用于查看、创建和编辑文件的文本编辑器工具。Claude Code 正是建立在这些相同的工具之上。Bash 并非为构建智能体而设计，但它是 Claude 知道如何使用、并且会随时间越用越好的工具。

我们看到 Claude 把这些通用工具组合成各种模式来解决不同的问题。例如，智能体技能（Agent Skills）、编程式工具调用（programmatic tool calling）和记忆工具（memory tool）都是基于 bash 和文本编辑器工具构建的。

### 2. 追问"我可以停止做什么？"

智能体框架编码了关于"Claude 自己做不到什么"的假设。随着 Claude 变得更强，这些假设应当被检验。

**让 Claude 编排自己的行动**

一个常见的假设是：每个工具结果都应当回流到 Claude 的上下文窗口（context window）中，以指导下一步行动。如果工具结果只是需要被传递给下一个工具，或者 Claude 只关心输出中很小的一部分，那么以 token 形式处理工具结果可能既慢、又昂贵、又不必要。

设想一下读取一张大表格只是为了对其中某一列进行推理：整张表格都进入了上下文，而 Claude 要为它并不需要的每一行支付 token 成本。可以在工具设计层面通过硬编码过滤器（hard-coded filters）来应对这一点。但这并未解决一个根本问题：是智能体框架在做编排决策，而 Claude 其实更适合做这个决策。

给 Claude 一个代码执行工具（例如 bash 工具或特定语言的 REPL）就能解决这个问题：它让 Claude 能够编写代码来表达工具调用以及调用之间的逻辑。与其由框架决定每个工具调用结果都被处理为 token，不如让 Claude 自己决定哪些结果要传递、过滤，或在不触及上下文窗口的情况下管道传递（pipe）到下一次调用。只有代码执行的输出才会进入 Claude 的上下文窗口。

编排决策从框架转移到了模型。由于代码是 Claude 编排行动的一种通用方式，一个强大的编程模型也是一个强大的通用智能体。Claude 在使用这种模式的非编程评测中也表现出色：在测试智能体浏览网页能力的基准 BrowseComp 上，让 Opus 4.6 能够过滤自己的工具输出，使准确率从 45.3% 提升到了 61.6%。

**让 Claude 管理自己的上下文**

任务特定的上下文会引导 Claude 使用 bash 和文本编辑器工具等通用工具。一个常见的假设是：系统提示（system prompt）应当用任务特定的指令手工精心打造。问题在于，用指令预加载提示无法跨越众多任务进行扩展：每添加一个 token 都会消耗 Claude 的注意力预算（attention budget），而用很少使用的指令预加载上下文是一种浪费。

给 Claude 访问技能（skills）的能力解决了这个问题：每个技能的 YAML 前置元数据（frontmatter）是预加载到上下文窗口中的简短描述，提供了对该技能内容的概览。如果某个任务需要，Claude 可以调用读文件工具来渐进式地展开（progressively disclosed）完整的技能。

技能赋予了 Claude 自由组装其上下文窗口的能力，而上下文编辑（context editing）则是其逆操作，提供了一种方式来有选择地移除已经过时或无关的上下文，例如旧的工具结果或思考块（thinking block）。

借助子智能体（subagents），Claude 越来越擅长判断何时应当分叉出一个全新的上下文窗口，以隔离某项特定任务的工作。使用 Opus 4.6，生成子智能体的能力在 BrowseComp 上比最佳单智能体运行结果提升了 2.8%。

**让 Claude 持久化自己的上下文**

长时运行的智能体可能会超出单个上下文窗口的限制。一个常见的假设是：记忆系统应当依赖于模型周围的检索基础设施。我们的许多工作都聚焦于给 Claude 提供简单的方式，让它自己选择要持久化哪些内容。

例如，压缩（compaction）让 Claude 能够总结其过去的上下文，以便在长周期任务中保持连续性。在多个版本的迭代中，Claude 越来越擅长选择记住什么。例如，在智能体搜索任务 BrowseComp 上，无论我们给 Sonnet 4.5 多少压缩预算，它都停滞在 43%。而 Opus 4.5 在相同设置下扩展到了 68%，Opus 4.6 则达到了 84%。

记忆文件夹（memory folder）是另一种方法，它允许 Claude 把上下文写入文件，之后按需读取。我们看到 Claude 把它用于智能体搜索。在 BrowseComp-Plus 上，给 Sonnet 4.5 一个记忆文件夹，把准确率从 60.4% 提升到了 67.2%。

长周期游戏（long-horizon games），比如《宝可梦》（Pokémon），就是 Claude 使用记忆文件夹能力提升的一个例子。Sonnet 3.5 把记忆当作逐字记录，写下非玩家角色（NPC）说了什么，而不是什么才重要。在走了 14,000 步之后，它有了 31 个文件——其中包括两个关于毛毛虫宝可梦的近乎重复的文件——而它仍然停留在第二座城镇：

```text
caterpie_weedle_info: - Caterpie 和 Weedle 都是毛毛虫宝可梦。 - Caterpie 是一种没有毒的毛毛虫宝可梦。 - Weedle 是一种有毒的毛毛虫宝可梦。 - 这个信息对未来的遭遇和战斗至关重要。 - 如果我们的宝可梦中毒了，应当尽快到宝可梦中心寻求治疗。
```

后来的模型则写下了战术笔记。Opus 4.6 在相同的步数下，有 10 个被组织进目录的文件、三枚道馆徽章，以及一个从自身失败中提炼出来的"经验"文件：

```text
/gameplay/learnings.md: - Bellsprout 的睡眠+缠绕连招：在催眠粉生效前用啃咬快速 KO。别让它布置好场面！ - 一代背包上限：最多 20 件物品。进地牢前丢弃不需要的招式机器。 - 旋转地砖迷宫：不同的进入 y 坐标会通向不同的目的地。尝试所有入口，并串联穿过多个区块。 - B1F y= 16 的墙在 x= 9 -28 全部确认为实心（步数 14557）
```

### 3. 谨慎设定边界

智能体框架在 Claude 周围提供结构，以强制约束用户体验（UX）、成本或安全性。

**设计上下文以最大化缓存命中**

Messages API 是无状态的。Claude 看不到之前轮次的对话历史。这意味着智能体框架需要在每一轮都把新的上下文连同所有过去的行动、工具描述和指令一起打包给 Claude。

提示可以基于设定的断点（breakpoints）进行缓存。换句话说，Claude API 会把断点之前的上下文写入缓存，并检查该上下文是否与任何先前的缓存条目匹配。

由于缓存 token 的成本仅为基础输入 token 的 10%，以下是智能体框架中有助于最大化缓存命中的几条原则：

**为用户体验、可观测性或安全边界使用声明式工具**

Claude 不一定知道某个应用的安全边界或用户体验界面。Claude 发出工具调用，由框架来处理。bash 工具给了 Claude 广泛的编程杠杆来执行操作，但它只给框架一个命令字符串——每个操作的形态都一样。把操作提升为专用工具（dedicated tools），就给了框架一个针对特定操作、带有类型化参数的钩子，框架可以拦截、设门槛（gate）、渲染或审计它。

需要安全边界的操作天然适合做成专用工具。可逆性往往是一个很好的判断标准，像外部 API 调用这样难以逆转的操作可以通过用户确认来设门槛。写入工具（如 edit）可以包含过时性检查（staleness check），这样 Claude 就不会覆盖一个自上次读取后已发生改动的文件。

当某个操作需要呈现给用户时，工具也很有用。例如，它们可以被渲染成一个模态框（modal），向用户清晰地展示一个问题、给用户多个选项，或者阻塞智能体循环直到用户提供反馈。

最后，工具对可观测性也很有用。当操作是一个类型化工具时，框架就获得了可以记录、追踪和重放的结构化参数。

是否把操作提升为工具的决策应当被持续重新评估。例如，Claude Code 的自动模式（发布时处于研究模式）为 bash 工具提供了一个安全边界：它让第二个 Claude 读取命令字符串并判断其是否安全。这种模式可以减少对专用工具的需求，并且只应当用于用户信任其总体方向的任务。对于某些高风险操作，专用工具仍然有其价值。

### 展望

Claude 智能的前沿始终在变化。关于"Claude 做不到什么"的假设，需要在它能力的每一次阶跃式提升时被重新检验。

我们看到这种模式不断重演。在我们为长周期任务构建的一个智能体中，Sonnet 4.5 会在感觉到上下文上限临近时过早地收尾。我们加入了重置（resets）来清空上下文窗口，以应对这种"上下文焦虑"。而到了 Opus 4.5，这种行为消失了。我们为了补偿而构建的上下文重置，在智能体框架中变成了死重（dead weight）。

移除这种死重很重要，因为它可能成为 Claude 性能的瓶颈。随着时间推移，我们应用中的结构或边界应当基于这个问题来进行修剪：我可以停止做什么？

要使用本文讨论的所有工具和模式，请查看我们的 claude-api 技能。

### 致谢

由 Lance Martin 撰写，他是 Claude 平台团队的技术成员。特别感谢 Thariq Shihipar、Barry Zhang、Mike Lambert、David Hershey 和 Daliang Li 对所涉主题的有益讨论。感谢 Lydia Hallie、Lexi Ross、Katelyn Lesse、Andy Schumeister、Rebecca Hiscott、Jake Eaton、Pedram Navid 和 Molly Vorwerck 的编辑审阅与反馈。

## 术语对照

| English | 中文 |
|---|---|
| agent harness | 智能体框架 |
| generative AI | 生成式 AI |
| context window | 上下文窗口 |
| orchestration | 编排 |
| programmatic tool calling | 编程式工具调用 |
| memory tool | 记忆工具 |
| Agent Skills | 智能体技能 |
| hard-coded filters | 硬编码过滤器 |
| REPL | 交互式解释器（REPL） |
| system prompt | 系统提示 |
| attention budget | 注意力预算 |
| frontmatter | 前置元数据 |
| progressively disclosed | 渐进式展开 |
| context editing | 上下文编辑 |
| thinking block | 思考块 |
| subagents | 子智能体 |
| compaction | 压缩 |
| memory folder | 记忆文件夹 |
| long-horizon games | 长周期游戏 |
| NPC | 非玩家角色 |
| breakpoints | 断点 |
| prompt caching | 提示缓存 |
| dedicated tools | 专用工具 |
| gate | 设门槛 |
| staleness check | 过时性检查 |
| modal | 模态框 |
| dead weight | 死重 |
| state of the art | 最高水平 |
