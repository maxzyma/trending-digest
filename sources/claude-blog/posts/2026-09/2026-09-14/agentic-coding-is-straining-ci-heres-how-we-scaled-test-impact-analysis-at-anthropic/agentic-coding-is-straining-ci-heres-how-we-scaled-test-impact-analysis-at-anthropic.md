# 智能体编程正在给 CI 带来压力。以下是我们在 Anthropic 扩展测试影响分析的方法

> Agentic coding is straining CI. Here’s how we scaled test impact analysis at Anthropic

> 来源：Claude Blog / Anthropic，2026-09-14
> 原文链接：https://claude.com/blog/agentic-coding-is-straining-ci-heres-how-we-scaled-test-impact-analysis-at-anthropic
> 分类：软件工程 / 持续集成与测试基础设施

## 核心要点

- Anthropic 工程师的人均季度代码交付量相比 2021—2025 年间提升了约 8 倍，其中 80% 的代码由 Claude 编写，Claude 同时深度参与 PR 的审查与批准。
- 代码库中的测试数量增长了 10 倍，而工程师只增加了少量，最终使 CI 作业数量在六个月内增长了 25 倍。
- 测试影响分析服务由记录每次 CI 运行结果的“监听器”和据此决定在各 PR 上运行哪些测试的“选择器”两个确定性组件构成，二者必须保持同步。
- 由于每个测试的运行历史需要单一写入者写入，全部逻辑运行在单个进程中，这一 v0 设计使服务无法进行水平分片。
- 监听器滞后会带来具体后果：问题变更合入后测试对所有人报错、依赖项不稳定导致红色构建阻塞合并、新增或修复的测试在追赶完成前不会运行从而可能放过回归。
- 三次快速修复分别是把机器核心数翻倍、按 package 分片并行化监听器、以及每日重启进程，有效期依次为 70 天、29 天和不到一天。
- 重新设计的方案为测试选择服务配备了内存数据存储，监听器 worker 无状态地把结果追加到日志中，由独立消费者进程每隔几秒汇总为按测试维度的历史记录供选择器查询。
- 新的分布式架构运行成本更高，但更易扩展和做内存剖析，整个项目由一名工程师耗时三周完成，而一年前大约需要接近一个季度。
- Claude 更倾向于提交更小、更细粒度的 PR，并会在夜间与周末持续提交，这抬高了 CI 活动量的下限，但因大量 PR 仍由人类推动而保持突发性。
- 文中给出的建议包括：假设架构在两个季度内面对 25 倍负载、在 v0 阶段就按感知规模的 10—20 倍预留余量、不把状态放进进程、避免无度量的单实例关键服务，并为服务植入可观测能力以便 Claude 渐进式修复问题。

## 正文

#### AI 正在革新持续集成（CI）

> AI is evolving CI 

Anthropic 的工程师平均每季度交付的代码量是 2021-2025 年间的 [8 倍](https://www.anthropic.com/institute/recursive-self-improvement)。其中 [80% 的代码](https://www.anthropic.com/institute/recursive-self-improvement)由 Claude 编写，它在 [审查和批准 PR 方面同样](https://claude.com/blog/how-anthropic-secures-its-ai-native-software-development-lifecycle)发挥着很大的作用。 

> Anthropic engineers on average ship [8x as much code](https://www.anthropic.com/institute/recursive-self-improvement) per quarter as they did from 2021-2025. Claude authors [80% of that code](https://www.anthropic.com/institute/recursive-self-improvement) and it also plays a large role in [reviewing and approving PRs as well](https://claude.com/blog/how-anthropic-secures-its-ai-native-software-development-lifecycle). 

![Writing code is no longer the constraint, and once PR review gets accelerated, CI starts feeling the pressure.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6aa7f3c848204c50ad501861_da466791.png)

除此之外，我们代码库中的测试数量增长了 10 倍，而我们只增加了少量工程师。这一切导致 CI 作业数量在六个月内增长了 25 倍（如果你想核对这个数字，并非每个测试都会在每个 PR 上运行，我稍后会解释）。

> On top of that, the amount of tests across our codebase grew 10x and we added a nominal amount of engineers. This all led to a 25x increase in CI jobs over a six month period (in case you are trying to do the math, not every test runs on every PR as I will explain).

这曾多次险些让我们的测试影响分析服务不堪重负。为了避免自己成为下一个瓶颈，我们把整套东西推倒重来，重新构想了该服务的架构应该是什么样子。但通往那一步的道路颇为坎坷，起初是三个快速修复方案，它们的有效期分别只有 70 天、29 天，以及不到一天。

> This threatened to overload our test impact analysis service several times. To avoid becoming the next bottleneck, we blew up the whole thing and reimagined what the service's architecture looks like. But getting there was a bumpy path that started with three quick fixes, which lasted 70 days, then 29 days, and then less than a day respectively. 

随着智能体持续加速代码生成与审查，扩展 CI 将成为越来越多工程团队很快要面对的挑战。我预计，随着运行智能体的团队产出更多 PR 和更多测试，横向扩展的测试选择架构将成为行业标准。

> Scaling CI is a challenge more engineering teams are likely to soon face as agents continue to accelerate code generation and review. I anticipate horizontally scaled test selection architecture will become industry standard as teams running agents create both more PRs and more tests.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6aa7f3c848204c50ad501864_e0fd4bf1.png)

在本文中，我将讨论我们如何在 Anthropic 扩展我们的测试影响分析服务，以及我通过惨痛教训学到的一课：永远要为指数级增长做好准备。那些具体的扩展技术——购买更大的机器、并行化进程，或者重启服务（是的，这招至今依然出奇地管用）——都很常见，**并不是本文希望你从中获得的洞见。** 

> In this article, I’ll discuss how we scaled our test impact analysis service at Anthropic and the lesson I learned the hard way: always plan for the exponential. The specific scaling techniques–buying bigger machines, parallelizing processes, or restarting the service (yeah, this one still works surprisingly well) – are common and** not the insights to take from this article.** 

关键在于，这些技术手段如今换来的时间，只是一年前的一小部分。另一方面，彻底重构并完全重新设计一项服务所花的时间同样只是过去的一小部分，而且既然写代码不再是瓶颈，这种做法现在要可持续得多。

> The point is that each of these techniques bought a fraction of the time they did a year ago. On the other hand, overhauling and completely redesigning a service also takes a fraction of the time and is much more sustainable now that writing code is no longer the bottleneck. 

你越是能够预见这种压力，并规划好架构将如何随之演进，就越少把时间浪费在治标不治本的权宜之计上。

> The more you can anticipate this strain and plan how your architecture will evolve with it, the less time you will waste on half-measures. 

#### 测试影响分析架构

> The test impact analysis architecture

我的许多同行所在的组织，每次变更**仍然会**运行全部测试。这种做法在一定规模内行得通，但无法扩展：CI 门禁会变得越来越漫长、昂贵且不可信。

> Many of my peers work at organizations where every test is **still **run on every change. This works up to a point, but doesn’t scale: CI gates get increasingly long, expensive, and untrustworthy.

此外，人类很擅长判断哪些测试失败与自己无关，而智能体则需要更多上下文和指引。当它们拿到一组特定的有效测试时，就能更有效地自我验证和迭代。

> Additionally, humans are great at determining which test failures don’t apply to them while agents will require more context and direction. When they get a specific set of valid tests, they can self-verify and iterate more effectively.

在 Anthropic，我们构建了一个确定性的测试影响分析（或称测试选择）服务，它会根据以往的运行表现和软件包相关性，确定每次变更需要运行哪些测试。这并不是一种罕见的做法，市面上也有一类厂商提供该领域的产品。

> At Anthropic, we built a deterministic test impact analysis or test selection service that determines which tests run on each change based on past performance and package relevance. This isn’t an uncommon practice, and there is a category of vendors with offerings in this area.

我们的服务依赖于两个确定性组件保持同步：

> Our service depends on two deterministic components staying in sync: 

- **一个“监听器”**会记录每次 CI 运行的测试结果。
- **“选择器”**读取测试结果历史，并决定在哪些已打开的 PR 上运行哪些测试。

> • **A “listener” **records the test results from every CI run. 
> • **A “selector”** reads the test result history and determines which tests run on which opened PRs.

这种方式是有效的，但当每秒都有多个 CI 任务在运行时，监听器就会越来越跟不上 PR 队列。对于[以 AI 为核心的 SDLC](https://claude.com/blog/the-ai-native-sdlc-playbook) 来说，即使是很小的延迟也可能造成很大的影响。例如，监听器 20 分钟的滞后，可能意味着有数万条测试更新没有被应用到选择器上。

> This is effective, but when there are multiple CI jobs running every second, the listener starts to increasingly fall behind the PR queue. For an [AI-native SDLC](https://claude.com/blog/the-ai-native-sdlc-playbook), a small lag can have a big impact. For example, 20 minutes of listener lag can translate into tens of thousands of test updates not being applied to the selector. 

- **如果一个有问题的变更被合入**，那么测试就会开始对其他所有人报错，从而引发多次不必要的排查。
- **如果某个依赖项开始出现不稳定（flaky）情况**，那么不稳定的红色构建就会开始阻塞合并。
- **如果某个测试被修复或新增了一个测试**，在监听器追赶上来之前它都不会运行，这有可能导致回归问题。

> • **If a bad change gets merged**, then a test will start failing for everyone else causing multiple unnecessary investigations.
> • **If a dependency starts flaking**, then flaky reds start blocking merges.
> • **If a test gets fixed or a new one gets added**, it won't run until the listener catches up risking a regression.

所有这些都在单个进程中运行，因为要为每个测试保留一份运行历史，就需要由单个写入者来写入结果。这个 v0 设计使我们无法进行水平分片。

> All of this ran as a single process because keeping a running history per test meant a single writer needed to apply the results. This v0 design prevented us from being able to horizontally shard.

#### 坎坷的重新设计之路

> The bumpy road to redesign

到去年十月，该服务已经显现出吃紧的迹象，我们连续两天被呼叫告警。

> By October of last year the service was already showing signs of strain, and we got paged two days straight.

##### 补丁 1：更大的机器

> Patch 1: A bigger machine

第一个修复很简单：我们把运行该服务的核心数翻了一倍。我们也知道这只是权宜之计。

> The first fix was easy: we doubled the cores running the service. We also knew it would be fleeting.

![Conversation recreated. Based on real events.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6aa7f3c848204c50ad501867_33889734.png)

即便趋势线已经很清晰，归属权却依然模糊。没人愿意再接手一块基础设施。而且，CI 团队还有更重要的事情要处理。

> Even when the trend line was clear, ownership was murky. No one wanted to own another piece of infrastructure. Also, the CI team had bigger fish to fry.

##### 补丁 2：分片

> Patch 2: Sharding

到这个阶段，该服务监听器积压的延迟已经频繁地把我们呼叫起来。为了推动一些长期修复，我在内部版本的 Claude Tag 中开启了一个长期运行的会话，专门用于监控这个服务。每当监听器延迟积压超过 50,000 个任务时，Claude 就会提醒我，并接着我们之前的对话继续讨论下一步该怎么做。

> At this point we were getting paged pretty frequently by the lag building up in the listener of this service. To drive some long-term fixes, I started a long-running session in an internal version of Claude Tag dedicated to monitoring the service. Anytime the listener lag would get more than 50,000 jobs behind, Claude would ping me and resume our conversation on next steps. 

这种状态持续了好几个月，不用反复向它重述以往的尝试或上下文，这一点很有帮助。Claude 常常主张彻底重构，但我们通常还是选择再打一个补丁。

> This would go on for months, and it was helpful not having to constantly remind it of past efforts or context. Claude often argued for an overhaul, but we usually settled on another patch. 

![Verbatim conversation on an internal version of Claude Tag with some redactions.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6aa7f3c848204c50ad50186a_c1d3dc74.png)

到了二月，CI 任务的指数级增长再次让这个服务不堪重负。这一次，我们决定做并行化。

> In February, the exponential growth of CI jobs started to strain the service once again. This time, we decided to parallelize.

监听器并不需要用单一写入者来正确排序测试结果，它需要的是每个 package 一个单一写入者，从而为我们代码库的每个部分正确排序测试结果。Claude 为我们生成了代码，把每个 package 的状态拆分到一个分片中，各自拥有独立的 worker。

> The listener didn’t need a single writer to order test results correctly, it needed a single writer per package to order the test results for each section of our codebase correctly. Claude generated the code for us to split each package’s state into a shard with its own worker.

我们同样清楚这个修复只是权宜之计，但没想到它只为我们争取到了 29 天。

> We also knew this fix would be fleeting, but we didn’t realize it would only buy us 29 days. 

##### 补丁 3：每日重启

> Patch 3: Daily restarts

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6aa7f3c848204c50ad50186d_c816aae3.png)

到了三月，在大多数工作日的午后，这个进程就会触及内存上限。我们再次寻找快速修复方案，但是：

> In March, the process reached its memory limit by mid-afternoon on most weekdays. Again, we looked for quick fixes but:

- 我们只找到了四个 bug。
- 把内存分配器换掉这种快速取巧的做法毫无效果。我们当时试图优化垃圾回收，但那并不是真正的解法。
- 我们不想冒险对一个已经处于重负载下的单例做内存剖析。
- 重启为我们争取到的时间还不到一天。

> • We only found four bugs.
> • Swapping the memory allocator as a quick-hack did nothing. We were trying to optimize garbage collection but that wasn’t really the solution. 
> • We didn’t want to risk memory profiling a singleton already under a heavy load. 
> • Restarting bought us less than a day.

我们还发现，每日重启导致该服务逐渐落后得越来越多。当它落后超过一小时时（这种情况发生过好几次），大量任务结果没有被监听器记录下来。

> We also discovered daily restarts were resulting in the service gradually falling further behind. When it fell behind for more than an hour, which happened several times, a ton of job results weren’t recorded by the listener. 

需要说明的是，这并不意味着那些 PR 从未跑过 CI，也不意味着未经测试的代码被推到了生产环境。它意味着的是，监听器没有收到部分结果，于是我们的测试选择组件在决定哪些测试要在 PR 上运行、哪些不运行时用的是陈旧数据。这在大多数情况下表现为：我们跑了一些本来就极其不稳定、或者在各处普遍失败的测试。

> To be clear, this doesn’t mean CI never ran on those PRs, or that untested code was pushed to production. What it meant was that the listener didn’t pick up some results, which meant our test-selection component was using stale data to decide what to run and what not to on PRs. Mostly this translated into us running tests that were already super flaky or widespread-failing across the board. 

##### 重新设计

> The redesign

是时候（其实早就该）重新设计这个服务了，于是我们采纳了 Claude 的建议：我们给测试选择服务配了一个数据库，准确地说是一个内存数据存储。这样一来，我们实际上把原先由单例承担的一大块内存内处理工作卸载了出去。

> It was (past) time to redesign the service, and we took Claude’s advice: we gave the test selection service a database, or an in-memory data store to be exact. By doing so, we effectively offloaded a huge chunk of in-memory processing that the singleton used to do. 

现在，任何一个监听器 worker 都可以处理任何结果，把它追加到内存存储中的一个日志（journal）里，然后继续下一个，不必在内存中保留任何东西——无状态，因此可以水平扩展。一个小型的独立消费者进程每隔几秒把日志汇总成按测试维度的历史记录，选择器就能快速查到相关的结果历史。

> Now, any listener worker can process any result, append it to a journal in the in-memory store, and move on without holding anything in memory - stateless and hence, horizontally scalable. A small separate consumer process rolls the journal up into per-test history every few seconds, and the selector can look up relevant result history quickly. 

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6aa7f3c848204c50ad501870_958f4a9d.png)

这套分布式架构的运行成本更高，但相比一个摇摇欲坠的单例，它更容易扩展、也更容易做内存剖析。这个项目由一名工程师花了三周完成。放在一年前，大概要接近一个季度。

> This distributed architecture is more expensive to run, but it is much easier to scale and memory profile than a shaky singleton.This project took three weeks for a single engineer. A year ago it would have been closer to a quarter.

![Queued, unprocessed job-result events, hourly max. Before: a backlog built up most days and grew week over week. After cutover and tuning: flat.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6aa7f3c948204c50ad501881_4deaf7d0.png)

其中有一些精细调优（确定日志规模和 worker 数量），基本上由 Claude 自主完成，而我们的服务自那以后一直保持稳定。

> There was some fine tuning (sizing the journal and number of workers) which Claude did largely autonomously, but our service has remained stable since.

#### 如果重来一次我会怎么做

> What I would do differently 

如果我被送回 2025 年 10 月，以我现在所掌握的认识，我会用不同的方式来处理这个项目以及其他项目。

> If I was sent back in time to October 2025, I would have approached this and other projects differently with what I now know. 

第一个不同之处是，我会把 AI 的指数级增长考虑进去。随着每位工程师平均使用的 agent 数量上升，以及加速 PR 审批的手段变得更成熟，CI 任务会呈指数级增加。

> The first difference is that I would account for the AI exponential. CI jobs increase exponentially as the average number of agents per engineer rises and as accelerated PR approval becomes more sophisticated. 

这在 Anthropic 已经逐渐改变了 PR 的形态，因为 Claude 更倾向于提交更小、更细粒度的 PR（这也是不该对每个 PR 都跑全部测试的又一个很好的理由）。其结果就是单日内的 CI 任务变多了。同时，由于 agent 会在夜间和周末持续提交，活动量的下限被抬高了，但它依然呈突发性，因为相当大一部分 PR 仍由人类工程师推动和审批。

> This has changed the shape of PRs over time at Anthropic as Claude prefers smaller, more granular PRs (another good reason not to run every test against every PR). This has translated into more CI jobs in a given day. Also, the activity level floor is raised as agents push overnight and on weekends, but it remains bursty as human engineers still drive and approve a significant amount of PRs.

我给工程团队的建议是，无论你是自建还是采购，都要假设你的架构在两个季度内会面对 25 倍的负载。「过度工程」这个概念正开始略微淡出，或者至少这条门槛正在大幅上移。只要预算允许，你现在可以在 v0 的设计中就按感知规模的 10—20 倍来预留余量。

> My advice to engineering teams is, whether you build or buy, assume your architecture will be at a 25x load within two quarters. Over-engineering as a concept is starting to slightly fade away, or at least the bar is moving much higher. You can now start to account for 10-20x the perceived scale in your v0 designs as long your budget allows for it. 

为你的服务植入观测能力，让它们成为 Claude 的眼睛和耳朵。这使 Claude 能够逐步爬坡改进、渐进式地修复问题，比我们手动操作更出色也更快速。尤其要确保进入的 CI 作业数量与产出的数量相等。

> Instrument your services to act as Claude’s eyes and ears. It allows Claude to hill-climb and fix problems incrementally much better and faster than we could manually. In particular, ensure that the same number of CI jobs coming in equals the same going out. 

从一开始就不要把状态放进进程里。我还建议避免以单实例方式运行任何关键服务，除非你能对它以及任何金丝雀变更进行度量。CI 的演进速度太快了，别无他法。

> Keep state out of the process from the start. I’d also avoid running any critical service as a single instance unless you can measure it and any canary changes. CI is evolving too quickly to proceed any other way. 

#### 额外的 CI 资源

> Additional CI resources

我还写过我们如何使用 [Claude Tag 加速 CI 值班](https://claude.com/blog/ai-ci-cd-on-call)（测试版）。

> I’ve also written how we accelerated [CI on call using Claude Tag](https://claude.com/blog/ai-ci-cd-on-call) (beta).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| CI (Continuous Integration) | 持续集成 | 开发者频繁将代码合入主干并自动构建、测试的实践。 |
| Test Impact Analysis | 测试影响分析 | 依据变更内容推断需要运行哪些测试的技术。 |
| Test Selection | 测试选择 | 从全部测试中挑选与本次变更相关的子集来运行。 |
| PR (Pull Request) | 拉取请求 | 请求将一个分支的改动合并进目标分支的协作单元。 |
| SDLC (Software Development Lifecycle) | 软件开发生命周期 | 从需求到交付运维的完整软件开发流程。 |
| Sharding | 分片 | 把数据或负载按键拆分到多个独立单元上处理。 |
| Horizontal Scaling | 水平扩展 | 通过增加实例数量而非单机规格来提升处理能力。 |
| Stateless | 无状态 | 进程不在本地保留请求间状态，因而任意实例可处理任意请求。 |
| Single Writer | 单一写入者 | 只允许一个进程写入某份数据以保证顺序与一致性的约束。 |
| Flaky Test | 不稳定测试 | 在代码未变的情况下时而通过、时而失败的测试。 |
| Journal | 日志 | 按顺序追加写入的记录流，用于后续汇总或重放。 |
| In-Memory Data Store | 内存数据存储 | 将数据主要保存在内存中以获得低延迟访问的存储系统。 |
| Garbage Collection | 垃圾回收 | 运行时自动回收不再被引用的内存的机制。 |
| Memory Profiling | 内存剖析 | 分析程序内存占用与分配来源以定位泄漏或瓶颈。 |
| Canary | 金丝雀发布 | 先向小比例流量或实例发布新版本以观察风险。 |
| Observability | 可观测性 | 通过指标、日志和链路数据推断系统内部状态的能力。 |
