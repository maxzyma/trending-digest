# 用“混沌循环”为 Claude Docs 上线加固：数十亿次请求中仅出现 60 次服务器错误

> Using a "chaos loop" to harden the Claude Docs launch: 60 server errors across billions of requests

> 来源：Claude Blog / Anthropic，2026-11-17
> 原文链接：https://claude.dev/blog/chaos-loop-claude-docs-launch/
> 分类：AI 工程 / 服务可靠性与负载测试

## 核心要点

- Claude Docs 在公开发布三周前还是运行在单节点上的概念验证，上线后一周内用户创建了超过 460 万份文档，20 亿次请求中仅出现 60 次服务器错误且从未回滚。
- 团队在镜像生产环境的预发布集群中让 Claude 连续运行约两周，以每天超过一百万份合成文档的规模施压并故意破坏核心组件，然后修复所有出故障的地方。
- 循环由一个持续运行的 Claude Code 会话充当协调者，把工作分派给子代理，依次执行选场景、跑测试框架、读遥测、提方案、部署到预发布环境并重复。
- 容易撤销的改动由 Claude 直接编写并部署，而更改数据库 schema、键布局或文档存储与物化方式等难以撤销的决策必须停下来征求人的批准。
- Claude 在整个测试过程中必须遵守两条不变式：文档必须几乎瞬间打开，以及服务器确认过的编辑必须被证明仍然存在。
- Claude 每轮迭代都会读取遥测并补充缺失的部分，借助更细粒度的内存分析把一份大型文档的内存占用从约 3 GB 降到约 180 MB，所需 Pod 估算从 500 多个降到约 50 个。
- 团队选择用 Rust 编写服务并把依赖降到最低，必要的库通过 vendoring 纳入代码库，使 Claude 测得的任何数字都能追溯到自己编写的代码。
- 在预发布环境演练过的十个场景中有七个在生产环境中真实发生，由于修复方案已放在运行时开关后面上线，通常只需切换开关即可应对。
- 这种做法之所以现在可行，是因为较新的前沿模型能在数周的长循环和多次上下文压缩后仍守住目标与不变式，而较早的模型会出现目标漂移。
- 从 8 月底到发布当天的推理费用按标价约为 12.5 万美元，作者估计小规模技术栈下类似的两周冲刺约需 3,000 到 10,000 美元。

## 正文

在 Claude Docs 向公众开放的三周前，它还只是一个运行在单个节点上的概念验证，使用者是 Anthropic 内部的几千人。我们正朝着一个雄心勃勃的发布日期全力冲刺，而按照我们自己的估算，上线头几天内就会出现数百万份文档。

> Three weeks before Claude Docs opened to the public, it was running as a proof of concept on a single node, used by a few thousand people inside Anthropic. We were racing toward an ambitious launch date, and our own estimate said we'd see millions of docs within the first few days.

我们于 9 月 16 日上线。截至 9 月 22 日，用户已创建超过 460 万份文档。在 20 亿次请求中，我们只遇到了 60 次服务器错误，而且从未需要回滚。整个 Docs 服务运行在大约 50 个内存优化型 Pod 上。

> We launched on September 16. By September 22, people had created over 4.6 million docs. Across 2 billion requests we saw only 60 server errors, and we never had to roll back. The whole Docs service ran on about 50 memory-optimized pods.

两个决定让我们做到了这一点：

> Two decisions got us there:

- **发布级规模的混沌循环。**我们在预发布环境中搭建了一套测试框架，让 Claude 连续运行两周，想方设法搞垮这项服务。它对我们基础设施的每个部分都进行了负载测试，并修复了所有出故障的地方。
- **提升对 Claude 的可读性。**只有当我们的系统在每次迭代中都产出准确的遥测数据时，Claude 才能有效地完成修复的闭环。我们很早就做出决定，避免使用任何会以我们的代码难以控制的方式占用内存或 CPU 的运行时（例如带有垃圾回收的运行时）。当某个遥测信号看起来令人担忧时，Claude 可以轻松地将其追溯到某个 bug 或某项具体的设计决策。

> • **A chaos loop at launch scale.** We set up a test harness on our staging environment where Claude ran constantly for two weeks to try and break the service. It load tested every part of our infrastructure and fixed whatever fell over.
> • **Improving legibility to Claude.** Claude could only close the loop effectively on fixes if our system produced accurate telemetry every iteration. We made a call early to avoid any runtime that uses memory or CPU in ways our code can't easily control (e.g. runtimes with garbage collection). When a telemetry signal looked concerning, Claude could easily trace it to a bug or a specific design decision.

但说实话，这之所以能成功，完全是因为我们的前沿模型最近进步很大（我用的是一个内部研究模型，能力大致与 Claude Fable 5.2 相当）。根据我们的经验，它们现在可以在这样的一次运行中连续数周坚持同一个目标，这正是帮助我们在紧张的时间内达到上线规模的原因。

> But honestly, this only worked because our frontier models have gotten much better recently (I used an internal research model roughly comparable to Claude Fable 5.2). In our experience, they can now stick with one goal through a run like this for weeks, which is what helped us hit launch scale in a tight timeline.

#### 混沌循环

> THE CHAOS LOOP

一台机器上的几千名内部用户，根本无法告诉我们这项服务能否扛住正式发布，而我们显然也没有发布时的真实流量可供测试。

> A few thousand internal users on one machine told us nothing about whether the service would survive launch, and we obviously didn't have launch traffic to test with.

我们希望用真实的证据来决定可以多快地推进上线。于是在 9 月 4 日，也就是发布前大约两周，我让 Claude 驱动一个镜像生产环境的预发布集群，以每天超过一百万份合成文档的规模运行，并故意破坏核心组件。然后……我就让它一直跑着（完整的成本我放在了本文末尾）。

> We wanted real evidence to decide how fast we could roll out. So on September 4, about two weeks before launch, I had Claude drive a staging cluster that mirrored production at over a million synthetic docs a day and break core components on purpose. And then... I just left it running (I've included the full cost at the end of this article).

我的配置相当简单。整个循环就是一个我让它一直运行着的 Claude Code 会话：挑选一个场景，运行测试框架，读取遥测数据，提出修复方案，将其发布到预发布环境，然后重复。这个会话充当协调者，把大部分工作交给子代理。在最忙的那一周，这通常意味着同时运行约 11 个子代理，峰值时达到 30 个。协调者还通过 Slack MCP 与我们内部版本的 Claude Tag（beta）对话，向 Anthropic 其他曾扩展过类似服务的基础设施团队学习。他们的代理检查了我们的扩展方案，排查其中是否存在他们已经踩过的坑。

> My setup was pretty simple. The loop was a session in Claude Code that I left running: pick a scenario, run the harness, read the telemetry, propose a fix, ship it to staging, repeat. That session acted as a coordinator and handed most of the work to sub-agents. In the busiest week, that usually meant about 11 sub-agents running at a time, and 30 at the peak. The coordinator also talked to our internal variant of Claude Tag (beta) via the Slack MCP to learn from other infrastructure teams at Anthropic who had scaled similar services. Their agents checked our scaling approach for pitfalls they’d already hit.

有趣的部分在于，我挑选的都是些自认为有点杞人忧天的场景：

> The fun part was picking scenarios I thought were paranoid:

- 单日新建文档达 1000 万份
- 22,000 个活跃连接同时重连
- 一篇有数百名查看者的热门文档、一台在加载文档过程中被杀掉的服务器，以及数据库卡顿

> • 10M new docs created in a single day
> • 22,000 live connections reconnecting at once
> • One hot doc with hundreds of viewers, a server killed while it was still loading a doc, and the database stalling

每一轮迭代的流程都一样。我们的测试框架选定一项功能（例如文档创建），并把创建操作一路压到饱和状态。随后 Claude 通过 Datadog MCP 读取遥测数据，返回一份简短的备选方案清单和一条建议。

> Each iteration looked the same. Our testing harness selected a feature like document creation and pushed creation to saturation. Claude then read telemetry using the Datadog MCP and came back with a short menu of options and a recommendation.

如果建议的改动容易撤销，Claude 就会编写该改动并将其部署到预发布环境，然后重新运行测试。我们对服务执行的每一项操作都有遥测数据。例如，每条数据库查询都会上报自己的名称，以及扫描了多少行、返回了多少行，因此 Claude 能够发现有问题的查询并将其重写。

> If the recommendation was easy to undo, Claude wrote and deployed the change to staging and reran the test. We had telemetry on every operation the service ran. Every database query, for example, reported its name and how many rows it scanned versus how many it returned, so Claude could spot a bad query and rewrite it.

![A loop of eight steps, with a legend marking the steps Claude does and the ones you do. Top row, left to right: the harness adds load, Claude reads the telemetry, Claude proposes options, and you pick one. Bottom row, right to left: Claude writes the change, Claude reviews it in a separate session, you approve, and Claude deploys to staging, which leads back to the harness. Inside the loop: opens instantly, and check that no confirmed edit was lost.](https://claude.dev/media/060110fce9da51e6293c9864b9db6c21d7a0585613d133ec7ce05a74f22fffea.png)

在循环开始之前，我告诉 Claude 哪些决策需要我批准；基本上就是任何难以撤销的事情，比如更改数据库 schema 或键布局，或者更改文档的存储和物化方式。

> Before the loop started, I told Claude which decisions needed my approval; basically anything hard to undo, like changing the database schema or key layout, or changing how a doc is stored and materialized.

每当 Claude 遇到这类情况，它就会停下来问我，通常还会附上一个建议，而我最后一般都会批准。Schema 变更就是我希望被征求意见的典型情形：这类问题通常有好几个合理的答案，而中途改变方向往往代价不小。

> When Claude ran into one of those, it stopped and asked me, usually with a recommendation that I ended up approving. Schema changes were the classic case where I wanted to be consulted: there are usually a few reasonable answers, and changing directions is often painful.

而且在整个测试过程中，Claude 必须遵守两条不变式：

> And during the whole testing process, Claude had to conform to two invariants:

1. 文档必须几乎瞬间打开（即使是历史记录很长的文档）
2. 一旦服务器确认了某次编辑，测试就必须证明这次编辑仍然存在

> 1\. Docs had to open almost instantly (even ones with a long history)
> 2\. Once the server acknowledged an edit, tests had to show the edit was still there

#### 让服务对 Claude 清晰可读

> MAKING THE SERVICE LEGIBLE TO CLAUDE

我的同事 Felix Rieseberg 最近写了[一篇关于如何更大胆地使用模型的教程](https://felixrieseberg.com/how-to-be-more-ambitious-a-tutorial-for-humans-with-models/)。他的核心观点是提升你向 Claude 下达提示时的“高度”：直接要求你想要的*结果*，而不是某一项具体任务。

> My colleague Felix Rieseberg recently wrote [a tutorial on being more ambitious with models](https://felixrieseberg.com/how-to-be-more-ambitious-a-tutorial-for-humans-with-models/). His main idea is to raise the "altitude" you prompt Claude at: ask for the *outcome* you want, not the individual task.

所以，你不是让 Claude 去修复一个个单独的崩溃，而是让它把你的应用做到零崩溃。（我们自己的应用还没有完全做到这一点，但我们正是靠这种方式取得实质性进展的。）不过，要在这个高度上工作，你必须把代码准备好，让 Claude 能够自行拉取崩溃报告，并运行一套测试工具来复现每个崩溃、验证修复是否有效。

> So instead of asking Claude to fix individual crashes, you ask it to make your app crash-free. (Our own apps aren't all the way there yet, but this is how we're making real progress.) To work at that altitude, though, you have to set up your code so Claude can pull crash reports on its own and run a harness that reproduces each crash and checks the fix.

对我们来说，最终的成果是一个能够扛住发布的服务。为了做到这一点，我们做了两件事，让这个服务对 Claude 来说尽可能清晰易懂：

> For us, the outcome was a service that could handle launch. To get there, we did two things to make the service as legible to Claude as we could:

- **诊断循环。**Claude 在每次迭代时都会读取遥测数据，并补充它认为缺失的内容。
- **清晰可辨的技术选型。**我们在选择运行时和依赖项时，力求让 Claude 测得的任何数字都能追溯到我们自己编写的代码。

> • **A diagnostic loop.** Claude read the telemetry on every iteration and added whatever it thought was missing.
> • **Legible technology choices.** We picked a runtime and dependencies so any number Claude measured traced back to code we wrote.

##### 诊断循环

> A diagnostic loop

每一轮迭代，Claude 都会读取遥测数据，并补上它认为缺失的部分。手写遥测很繁琐，所以实际上大多数遥测都是在出了问题之后才加上去的。现在 Claude 会边做边写。

> Every iteration, Claude read the telemetry and added whatever it thought was missing. Writing telemetry by hand is tedious, so in practice most telemetry would go in after something broke. Now Claude just writes it as it goes.

记忆是最好的例子。

> Memory is the best example.

在测试工具运行的早期，有一个大型文档在它所在的 pod 上占用了约 3 GB 内存（这可不是个让人看了开心的数字）。Claude 最初尝试的修复办法是缩小我们的某个缓存，好让服务器更早地淘汰文档。下一轮测试工具运行显示，这些内存其实位于我们某个依赖项内部的一个*独立*缓存中，于是 Claude 放弃了这项改动。

> Early in the harness run, one large doc was using about 3 GB on its pod (not a fun number to see). Claude’s first stab at fixing it was to shrink one of our caches so our server would evict docs sooner. The next harness run showed the memory was actually in a *separate* cache inside one of our dependencies, so Claude dropped the change.

从那里开始，Claude 借助更细粒度的内存分析不断缩小排查范围。最终它发现，每次按键都会把文档复制到好几个不同的数据结构中，每次都会增加几 MB。Claude 把这些结构改成了写时复制，这样它们现在共享同一个引用，而不是各自持有一份副本。

> From there Claude kept narrowing it down with finer-grained memory profiling. Eventually it found that every keystroke was copying the doc into several different data structures, adding a few MB each time. Claude switched those structures to copy-on-write, so they now share one reference instead of each holding its own copy.

经过大约三天的迭代，那份文档的内存占用最高约为 180 MB，而我们对上线所需资源的估算也从 500 多个内存优化型 pod 降到了约 50 个。

> After about three days of iterating, that doc topped out around 180 MB, and our estimate of what we’d need for launch dropped from more than 500 memory-optimized pods to about 50.

![Claude adds telemetry as it goes. A loop of six steps: the harness stresses the service, the service reports telemetry, and Claude reads it and traces it to a cause. Then Claude adds what's missing, which is highlighted, Claude fixes it or drops a wrong guess, and Claude deploys and reruns, with hard-to-undo changes going to you first, which leads back to the harness.](https://claude.dev/media/a02f11262eb83a0c3bd3938e08015db1f9d520db1220dd90b4205f05559d6cc7.png)

##### 清晰易懂的技术选型

> Legible technology choices

我们对这个服务的运行时和依赖项十分挑剔。我们希望 Claude 测得的任何数字都能追溯到我们自己编写的代码。

> We were picky about the service’s runtime and dependencies. We wanted any number Claude measured to trace back to code we wrote.

这是因为我们的模型在信号干净时爬坡效果最好。我们预计垃圾回收器会引入噪声，因为内存和延迟会随回收器的调度节奏而波动。

> This is because our models hill climb best with a clean signal. We expected a garbage collector to add noise, because memory and latency shift on the collector’s schedule.

有两个选择起到了最大的作用。

> Two choices helped the most.

1. **我们用 Rust 编写了这个服务**。由于没有垃圾回收器，一个文档占用的全部内存都位于我们自己定义的结构中，因此当内存增长时，Claude 可以指出是哪个结构造成的，对其进行修改，并在下一轮迭代中查看内存是否降了下来。Anthropic 内部也有很出色的 Go 工具链，而且我们并没有对这两种语言做过对比评测，所以这里讲的只是我们使用 Rust 的经验。不过，由于我过去做过 Go 方面的工作，真正让我欣赏的一点是：我几乎不必操心代码用完内存之后，这些内存还滞留不去的问题。
2. **我们还把依赖降到了最低**。每个库都会带来并非我们编写、也难以轻易摸清底细的数据结构。对于确实需要的少数几个库，我们把代码直接纳入了自己的代码库（vendoring），这样就可以亲自阅读并度量它们。

> 1\. **We wrote the service in Rust**. With no garbage collector, all of a doc’s memory sits in structures we defined, so when it grew, Claude could point to the one responsible, change it, and see whether memory came down on the next iteration. We have great Go tooling at Anthropic too, and we didn’t bake off the two languages, so this is our experience with Rust. What I did appreciate, coming from past work in Go, was how little I had to think about memory sticking around after my code was done with it.
> 2\. **We also kept dependencies to a minimum**. Every library brings data structures we didn’t write and can’t easily account for. For the few we really needed, we vendored the code so we could read and measure it ourselves.

Rust 对人来说很难写，放在几年前，这一点会在选型时占很大的分量。而 Claude 写 Rust 和其他大多数语言都没什么问题，所以这一点现在已经没那么重要了。

> Rust is hard for people to write, and a few years ago that would have weighed heavily on the choice. Claude writes it and most other languages fine, so that matters a lot less now.

![We wanted every number to trace back to code we wrote, so we used Rust and kept dependencies to a minimum. Two lanes. What we chose: Rust and few dependencies, so memory sits in our own structures, then Claude finds the cause, then fixes are easy to check. What we avoided, a bet and not a test: garbage collection and libraries we didn't write, then memory we can't account for, then a noisier signal that is harder to trace to our code.](https://claude.dev/media/9168b5a755c326966403a7bee480d1d1a60f1f1a6979ab959ece5a8993fb9930.png)

#### 发布周

> LAUNCH WEEK

服务在上线规模下稳住了。第一批一百万份文档在大约 30 小时内就出现了，到 9 月 22 日我们已经突破 460 万份。9 月份我们对生产环境进行了 629 次发布，一次都没有回滚过。

> The service held at launch scale. The first million docs showed up in about 30 hours, and we were past 4.6 million by September 22. We rolled prod 629 times in September and never once rolled back.

发布周给人一种奇怪的熟悉感。Claude 很擅长设想一个服务可能出故障的各种方式，早在发布之前就已经为其中大部分情况做好了预案。我们在 staging 环境演练过的十个场景中，有七个真的在生产环境中发生了。到那时，harness 已经让 staging 环境经历过其中的大部分情况，Claude 也已经把修复方案放在运行时开关后面上线了。当基础设施的某一部分遇到压力时，我们通常只需切换一个开关。

> Launch week felt weirdly familiar. Claude is great at imagining ways a service can fail and had planned for most of them well before launch. Seven of the ten scenarios we’d rehearsed on staging actually happened in prod. By then the harness had already put staging through most of it, and Claude had shipped the fixes behind runtime flags. When part of the infra ran into pressure, we usually just flipped a flag.

#### 为什么现在行得通

> WHY THIS WORKS NOW

几个月前，这多半是行不通的。较早的模型通过 MCP 服务器读取遥测数据没什么问题，但在一个长循环里迭代十次、二十次之后，它们就会开始忘记我们到底在优化什么，我最后只好把目标重新说一遍。Anthropic 的其他员工把这种现象称为[目标漂移](https://claude.dev/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code/#why-dynamic-workflows)。

> A few months ago this probably wouldn’t have worked. Older models were fine at reading telemetry through an MCP server, but ten or twenty iterations into a long loop, they’d start forgetting what we were optimizing for, and I’d end up restating the goal. Other Anthropic employees have called this [goal drift](https://claude.dev/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code/#why-dynamic-workflows).

我们较新的前沿模型是为长时间运行的工作而打造的。Claude 在多次上下文压缩之后依然守住了我们所有的不变量，我从未需要重复说明。

> Our newer frontier models are built for long-running work. Claude held all of our invariants across many compactions, and I never had to repeat them.

这么做的也不只是我们。Vercel 借助一个与我们非常相似的受监督智能体循环，[让 Turborepo 的速度提升了最高 96%](https://vercel.com/blog/making-turborepo-ninety-six-percent-faster-with-agents-sandboxes-and-humans)。

> We're not the only ones doing this, either. Vercel [made Turborepo up to 96% faster](https://vercel.com/blog/making-turborepo-ninety-six-percent-faster-with-agents-sandboxes-and-humans) with a supervised agent loop a lot like ours.

#### 代价几何

> WHAT IT COST

按 Claude Fable 5.2 的 API 标价（截至 2026 年 11 月）计算，从 8 月底到发布当天，我用掉了大约 12.5 万美元的推理费用。放在几年前，我估计这种规模的工作需要一个工程师团队花大约六个月才能完成。

> At Claude Fable 5.2's API list price (as of November 2026), I used roughly $125,000 of inference from the end of August to launch day. A couple of years ago, work on this scale I'd guess would have taken a team of engineers about six months.

其中大部分用于读取遥测数据、撰写提案、生成修复以及审查代码。

> Most of that went to reading telemetry, writing proposals, generating fixes, and reviewing code.

关于成本，有几点需要说明：

> A couple of things about the cost:

- **我们的发布规模尤其庞大。**相当大一部分资金投入到了只有在这种规模下才有意义的基础设施上，而对这些基础设施进行推理又需要更多的推理算力。Claude 必须更加深入地思考越来越多的服务如何相互配合，以及它们可能出现故障的各种方式。
- **在摸索流程的过程中，我也烧掉了大量 token。**我在试验这套配置的时候，循环一直在不停地跑。以我现在掌握的经验来看，我认为我们本可以只花大约一半的成本。

> • **Our launch was particularly massive.** A good chunk of the money went into infrastructure that only makes sense at that scale, and that infrastructure took more inference to reason about. Claude had to think a lot harder about how a growing set of services fit together and all the ways they could fail.
> • **I also burned a lot of tokens figuring out the process.** The loop ran nonstop while I was experimenting with the setup. Knowing what I know now, I think we could have spent about half as much.

#### 动手试一试

> TRYING THIS OUT

这对规模小得多的服务同样适用，而且成本应该会低很多。

> This works for much smaller services too, and it should cost a lot less.

为了得到一个粗略的数字，我按一套经典的小团队技术栈估了价：几台配置适中的 Kubernetes 节点，外加一个 Postgres 实例。然后我梳理了从 8 月底到上线当天我合入的所有改动，把那套配置下不需要做的工作剔除掉：

> To get a rough number, I priced out a classic small team stack: a couple of reasonably sized Kubernetes nodes and a Postgres instance. Then I went through the changes I landed between the end of August and launch day and removed the work that setup wouldn’t need:

- 与我们的其他内部服务相适配
- 与规模化工作交织在一起的客户与产品工作
- 跨多个 Pod 运行
- 细粒度速率限制

> • Fitting in with our other internal services
> • Client and product work that was intermixed with the scale work
> • Running across many pods
> • Fine-grained rate limiting

大约三分之一的改动被保留了下来。

> About a third of the changes were left.

把我们的花费按比例缩减到那三分之一，再剔除我在摸索配置阶段犯下的错误，我估计像这样一次为期两周的冲刺，按同样的标价算大约需要 3,000 到 10,000 美元（我并没有实际这样跑过，所以这只是一个粗略的估计）。

> Scaling our spend down to that third and taking out the mistakes I made while I was still figuring out the setup, I’d put a two week push like this one at $3,000 to $10,000 at the same list price (I haven’t actually run this, so it’s only a rough sense).

以下步骤假设由一名工程师配合 Claude Code、一个预发布环境和一个可观测性服务提供商来完成。协调器和子智能体有助于加快这一过程，但如果你发现它们每小时消耗的 token 过多，退回到单个智能体的方式应该也能取得相当不错的效果。如果你想尝试：

> The steps below assume one engineer with Claude Code, a staging environment, and an observability provider. The coordinator and sub-agents helped speed up the process, but if you find they’re burning too many tokens per hour, going back to a single agent should also work quite well. If you want to try it:

1. 让 Claude 能够访问你的遥测数据。大多数可观测性服务商都提供了可供 Claude 使用的 MCP 服务器。
2. 让 Claude 编写一个压测脚本，向服务的预发布副本施加十倍于真实流量的压力，并故意搞破坏。杀掉一个实例、让数据库卡住、在流量高峰期间进行部署，都是不错的切入点。然后让 Claude 持续修复所有垮掉的地方。
3. 在选择技术栈时，尽量倾向于 Claude 最容易度量的方案。对我们来说，那就是 Rust，以及尽可能少的依赖。
4. 开始之前，先写下你最重要的技术不变量，并把它们交给 Claude。
5. 对于任何难以撤销的操作，让 Claude 停下来，给你几个选项，并附上明确的推荐。

> 1\. Give Claude access to your telemetry. Most observability providers have an MCP server that Claude can use.
> 2\. Have Claude write a load script that throws ten times your real traffic at the staging copy of the service and breaks things on purpose. Killing an instance, stalling the database, and deploying in the middle of a spike are good places to start. Then let Claude keep fixing whatever falls over.
> 3\. When you’re picking your stack, lean toward whatever Claude can measure most easily. For us that was Rust and as few dependencies as possible.
> 4\. Before you start, write down your most important technical invariants and give them to Claude.
> 5\. For anything that’s hard to undo, have Claude stop and give you a few options with a clear recommendation.

*非常感谢 Docs 团队，他们在同样的三周内落地了数千项编辑器修复；也感谢平台团队和存储团队，是他们构建了这一切所依托的基础。*

> *Huge thanks to the Docs team, who landed thousands of editor fixes in the same three weeks, and to the platform and storage teams who built everything this sits on.*

**延伸阅读。** [我们如何在两周内让 claude.ai 提速 3 倍](https://claude.dev/blog/how-we-made-claude-ai-faster/) (claude.dev) · [为每项任务配备一套 harness：Claude Code 中的动态工作流](https://claude.dev/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code/) (claude.dev)，关于目标漂移。

> **Further reading.** [How we made claude.ai 3x faster in two weeks](https://claude.dev/blog/how-we-made-claude-ai-faster/) (claude.dev) · [A harness for every task: dynamic workflows in Claude Code](https://claude.dev/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code/) (claude.dev), on goal drift.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Chaos Loop | 混沌循环 | 让智能体在预发布环境中反复施压、故意破坏组件并修复故障的持续迭代流程。 |
| Harness | 测试框架 | 用于驱动负载、注入故障并复现问题以验证修复效果的测试工具集。 |
| Staging | 预发布环境 | 镜像生产环境配置、用于上线前验证改动的独立环境。 |
| Telemetry | 遥测数据 | 服务运行时上报的指标、日志和追踪等可观测性数据。 |
| Legibility | 可读性 | 系统行为与度量结果能被模型清晰理解并追溯到具体代码或设计决策的程度。 |
| Invariant | 不变式 | 无论系统如何改动都必须始终成立的技术约束条件。 |
| Subagent | 子代理 | 由协调者会话分派具体任务并并行执行的下级智能体。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 让模型通过统一接口访问外部工具与数据源的协议。 |
| Garbage Collection | 垃圾回收 | 由运行时自动回收不再使用的内存的机制，其调度会使内存和延迟产生波动。 |
| Copy-on-Write | 写时复制 | 多个使用方共享同一份数据引用、仅在写入时才复制的优化策略。 |
| Vendoring | 依赖内置 | 把第三方库的源码直接纳入自己的代码库以便阅读、度量和修改的做法。 |
| Runtime Flag | 运行时开关 | 无需重新部署即可在运行中启用或关闭某项功能或修复的配置开关。 |
| Goal Drift | 目标漂移 | 模型在长循环多次迭代后逐渐偏离或忘记最初优化目标的现象。 |
| Context Compaction | 上下文压缩 | 在长会话中把已有对话内容摘要化以腾出上下文窗口空间的过程。 |
| Rollback | 回滚 | 在发布出现问题时把服务恢复到上一个稳定版本的操作。 |
