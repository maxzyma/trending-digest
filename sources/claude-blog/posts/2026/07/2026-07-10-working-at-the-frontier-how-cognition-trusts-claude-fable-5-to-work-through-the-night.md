---
source: claude-blog
source_url: https://claude.com/blog/working-at-the-frontier-how-cognition-trusts-claude-fable-5-to-work-through-the-night
published_at: 2026-07-10
category: Enterprise AI
title_en: Working at the frontier: How Cognition trusts Claude Fable 5 to work through the night
title_zh: 在前沿工作：Cognition 为何放心让 Claude Fable 5 通宵运行
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 5
source_image_count: 2
---

# 在前沿工作：Cognition 为何放心让 Claude Fable 5 通宵运行

> Working at the frontier: How Cognition trusts Claude Fable 5 to work through the night

> 来源：Claude Blog，2026-07-10
> 原文链接：https://claude.com/blog/working-at-the-frontier-how-cognition-trusts-claude-fable-5-to-work-through-the-night
> 分类：Enterprise AI

## 核心要点

- Cognition 于 2024 年初打造了自主 AI 软件工程师 Devin，承接工程师无暇处理的代码库迁移、积压缺陷与迟迟未完成的功能。
- 团队对基准分数持怀疑态度，秉持“不信任任何评测”的原则，改由最挑剔的工程师用真实一天的工作检验模型，标准是代码是否值得保留。
- 早期模型只能持续专注几分钟到一小时，之后就会跑偏；面对多个并行思路会混乱，在数据库迁移中虽完成任务却引入隐蔽缺陷。
- 在 Cognition 自建的 Frontier Code 基准最难子集上，前代 Opus 模型约得 10%，Claude Fable 5 约得 30%，且内部试用结果与分数一致。
- Claude Fable 5 最突出的是“持续自主时长”：曾连续工作八小时并取得实质进展，在嘈杂上下文中保持清醒，能查明根因并如实说明未知之处。
- 该模型首次正确使用 Cognition 内部调试工具，在浏览器中翻查日志并得出结论；在迁移任务中先声明要坚守的不变量再据此执行。
- Cognition 认为 Claude Fable 5 让“智能体在云端连续运行数小时”的创始设想真正可行，部分能力已落地于产品，如主动监控 Slack 与生产环境并自行分诊。

## 正文

Cognition 研究高级副总裁 Silas Alberti 几乎在其 AI 软件工程师 Devin 中测试过每一代 Claude 模型。Claude Fable 5 是他第一个敢让其整夜持续运行的模型。

> Silas Alberti, SVP of Research at Cognition, has tested nearly every Claude model inside Devin, the company's AI software engineer. Claude Fable 5 is the first he'd trust to leave running overnight.

Cognition 是一家年轻的公司，即便以硅谷的标准来看也是如此。它在 2024 年初打造了自主 AI 软件工程师 Devin，当时智能体（agent）最基本的运行机制都还勉强能凑合。

> Cognition is young, even by Silicon Valley standards. It built Devin, its autonomous AI software engineer, in early 2024, at a time when the basic mechanics of an agent barely held together.

Devin 承接的是工程师们始终腾不出手去做的工作：代码库迁移、积压的缺陷（bug），以及那些一再被搁置的功能。它的客户既有高速成长的初创公司，也有《财富》500 强企业，因此标准很高。Devin 写出的代码必须可靠、达到生产可用（production-ready）的水平；一个悄然引入的小 bug 都可能在下游造成真正的问题。

> Devin takes on the work engineers never quite get to: codebase migrations, the backlog of bugs, the features that keep slipping. With customers ranging from high-growth startups to Fortune 500 companies, the bar is high. Code written by Devin has to be reliable and production-ready; a small bug introduced quietly can cause real problems downstream.

Alberti 的团队负责训练和测试 Devin 背后的模型，几乎运行过一开始以来的每一代 Claude。他把第一次真正的飞跃追溯到 2024 年底的 Claude 3.6 Sonnet。那是第一个能够可靠地串联工具、并撑住多步骤任务的模型。当团队把它接入 Devin 后，内部使用量翻了三倍。

> Alberti’s team trains and tests the models behind Devin and has run nearly every Claude generation since the start. He traces the first real jump to Claude 3.6 Sonnet in late 2024. It was the first model that could reliably chain tools and hold a multi-step task. When the team plugged it into Devin, internal usage tripled.

正是这段经历让他很难被打动。Cognition 见过一些模型在基准测试（benchmark）上拿到高分，却在工程师真正上手使用时立刻崩溃。"我们被这样坑过很多次，"Alberti 说。所以团队更信任自己的工程师，而不是任何分数。他们品味最高的开发者会用一整天真实的工作来检验每个新模型，衡量标准是：这些代码是不是他们真的愿意留下来用的。

> That history is what makes him hard to impress. Cognition has watched models ace a benchmark and then fall apart the moment its engineers tried to use them. "We've been burned like this a bunch of times," Alberti says. So the team trusts its own engineers over any score. Its highest-taste developers put each new model through a real day of work, and the bar is whether the code is something they’d actually keep.

用 Alberti 的话说，"我们不信任何评测（eval）。"

> As Alberti puts it, "we trust no eval."

### 早期模型的极限所在

> Where earlier models hit their limit

尽管取得了这些进展，仍有一道天花板存在：一个智能体（agent）能运行多久才会丢失思路？

> For all that progress, one ceiling remained: how long an agent could run before it lost the thread?

"在 Fable 之前，你能委派的智能体只能专注于任务几分钟，也许一个小时，"Alberti 说。之后，会话就会跑偏。给早期模型五个需要同时权衡的想法，它就会失去头绪、陷入混乱。在一次数据库迁移中，之前的 Opus 模型从技术上说完成了任务，但过程中引入了一系列细微的 bug。

> "Before Fable, you could delegate agents that could stay on-task for a couple of minutes, maybe an hour," Alberti says. After that, sessions drifted. Give an earlier model five ideas to weigh at once, and it would lose track and get confused. On one database migration, a prior Opus model technically finished the job but introduced a series of subtle bugs along the way.

事故分流（incident triage）也呈现出同样的模式。早期模型往往停留在日志表面，而不去挖掘出相关的那一行，而且它们被训练成无论如何都要给出答案——所以它们会"自信地宣称自己发现的第一个看似合理的东西，然后就停下来"。工程师们学会了不再理会它们。

> Incident triage showed the same shape. Earlier models tended to stay at the surface of the logs instead of digging for the relevant line, and they were trained to give an answer no matter what—so they'd "confidently claim the first plausible thing they discover and then stop." Engineers learned to tune them out.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4dd0c75a04f6ca41530255_C41-77690-D2-02-0006_VS_R1.jpeg)

### Claude Fable 5 达到了 Cognition 自己设定的标准

> Claude Fable 5 clears Cognition's own bar

Cognition 用 Frontier Code 这一基准来给模型评级，之所以自建这个基准，是因为现有基准总在奖励那些能通过测试、却无法在真实代码库中存活的代码。Alberti 称它为一种"反劣质代码"（anti-slop）标准。在其最难的子集上，此前的 Opus 模型得分约为 10%，而 Claude Fable 5 得分约为 30%。

> Cognition grades models on Frontier Code, a benchmark it built because existing ones kept rewarding code that passed tests but wouldn't survive a real codebase. Alberti calls it an "anti-slop" standard. On its hardest subset, the prior Opus model scored around 10%. Claude Fable 5 scored about 30%.

团队的第一反应是怀疑。"是不是有 bug？这不可能是真的。"通常基准分数的跃升会伴随工程师们争论数周，讨论模型在实际使用中是否真的更好。而这一次，实际试用（dogfooding）的结果与数字相吻合。"说实话，这有点让人震惊，"Alberti 说。

> The team's first reaction was suspicion. "Is there a bug? This can't be true." Usually a benchmark jump comes with engineers arguing for weeks over whether the model is actually better in practice. This time the dogfooding agreed with the numbers. "It was kind of a shocker, honestly," Alberti says.

"我们注意到的最大变化是时间跨度（horizon），也就是它能自主运行多久，"他说。"有些任务，我正准备睡觉时会想，'好吧，请继续做这个，别停，直到我醒来。'然后我一觉醒来，它已经连续工作了八个小时，而且确实取得了实质性进展。这是我以前从未见过的。"

> "The biggest thing we noticed was the horizon, how long it can be self-sufficient," he says. "There have been tasks where I was about to go to bed and I was like, 'Okay, just please keep working on this and don't stop until I wake up.' And then I wake up, and it's been working for eight hours straight and actually making real progress. I hadn't seen that before."

这种时间跨度之所以能维持，是因为 Claude Fable 5 在杂乱的上下文中始终保持清醒。它是第一个能正确使用 Cognition 内部调试工具的模型，能在浏览器中翻阅日志，并在噪声之中得出结论。在一次曾让早期模型栽跟头的迁移任务中，它先陈述了自己要坚守的不变量（invariants），然后据此执行。在故障排查上，它锁定了根本原因，并说明了自己不清楚的地方——Alberti 说，这才是真正重建信任的关键。

> The horizon held because Claude Fable 5 stayed clear-headed in messy context. It was the first model to properly use Cognition's internal debugging tools, paging through logs in the browser and drawing conclusions despite the noise. On a migration that had tripped up earlier models, it stated the invariants it would hold itself to, then executed against them. On triage, it pinned down the root cause and said what it didn't know, which Alberti says is what actually rebuilds trust.

他把这次跃升归入为数不多的真正阶跃式变化之列，这种变化大约每年才出现一次。

> He puts the jump in a small class of true step changes, the kind that come roughly once a year.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a4dd13a49316d41447995c4_C41-77690-D2-11-0026_VS_R1.jpeg)

### 接下来会发生什么

> What’s next

Cognition 创立时押下的赌注是：智能体应当在云端连续运行数小时。而在公司成立的第一年，模型还达不到这个水平。

> Cognition's founding bet was that agents should run in the cloud for hours at a time. For the company's first year, the models weren't there yet.

Alberti 表示，Claude Fable 5 让这个赌注的完整版本变得可行，其中一部分已经落地到产品中。Devin 可以盯着一个 Slack 频道，无需被点名就主动介入某个问题，或者监控生产环境并自行分诊某次流量激增。他说，当它把这类任务做对时，感觉就"像团队里一位真正的工程师"。

> Alberti says Claude Fable 5 makes the full version of that bet viable, and some of it is already in the product. Devin can watch a Slack channel and jump into an issue without being tagged, or monitor production and triage a spike on its own. When it gets one of those right, he says, it feels "like a real engineer on the team."

他预期这将成为工程团队的默认模式。他说，再过一两年，90% 的智能体会话将是主动式的——它们会发现问题、扫描代码库，然后带着修复方案给你发消息。

> He expects this to become the default for engineering teams. In a year or two, he says, 90% of agent sessions will be proactive ones that find a problem, scan the codebase, and message you with the fix.

"很多我们在公司一直想做的事情，现在都变得可能了，"Alberti 说。

> "A lot of these things we've always wanted to build at the company are now possible," Alberti says.

立即开始使用 [Claude Fable 5](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5-and-claude-mythos-5)。

> Get started with [Claude Fable 5](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5-and-claude-mythos-5).

## 术语对照

| English | 中文 |
|---|---|
| frontier | 前沿 |
| AI software engineer | AI 软件工程师 |
| agent | 智能体 |
| codebase migration | 代码库迁移 |
| production-ready | 生产可用 |
| tool chaining | 工具链式调用 |
| multi-step task | 多步骤任务 |
| benchmark | 基准测试 |
| eval | 评测 |
| dogfooding | 内部试用 |
| horizon | 持续时长 |
| incident triage | 事故分诊 |
| root cause | 根因 |
| invariant | 不变量 |
