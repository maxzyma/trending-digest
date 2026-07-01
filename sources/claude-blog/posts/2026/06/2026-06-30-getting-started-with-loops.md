---
source: claude-blog
source_url: https://claude.com/blog/getting-started-with-loops
published_at: 2026-06-30
category: Claude Code
title_en: Getting started with loops
title_zh: 循环入门：Claude Code 的智能体循环设计
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 3
source_image_count: 3
---

# 循环入门：Claude Code 的智能体循环设计

> Getting started with loops

> 来源：Claude Blog，2026-06-30
> 原文链接：https://claude.com/blog/getting-started-with-loops
> 分类：Claude Code

## 核心要点

- Claude Code 团队将循环定义为：智能体重复执行工作周期，直到满足停止条件；并按触发方式、停止方式、所用基础能力和适用任务类型进行分类。
- 轮次循环由用户提示触发，Claude 判断任务完成或需要更多上下文即停止，适合不属于常规流程的短任务；可用技能文件加强自我验证以减少轮次。
- 目标循环通过 /goal 实时触发，设定可验证的完成标准和轮次上限;评估模型每次在 Claude 想停止时校验条件,达标或到达轮次上限才结束。
- 确定性标准（如通过测试数、达到某分数阈值）最利于目标循环，因为 Claude 无需自行判断“够好了没”。
- 时间循环用 /loop 按间隔重复运行提示，用 /schedule 将其迁移到云端形成例程，适合重复性工作或与外部系统交互（如检查 PR、处理 CI）。
- 主动循环由事件或计划触发、无人实时参与，可组合 /schedule、/goal、技能、动态工作流和自动模式，处理源源不断的既定工作，如缺陷报告、问题分诊、迁移和依赖升级。
- 控制用量的做法包括：编写具体提示、设定明确完成标准与轮次上限、拉长运行间隔或改为事件驱动、将例程路由到更小更快的模型而把最强模型留给判断性决策。

## 正文

了解 Claude Code 团队如何定义智能体循环，并获得从轮次循环逐步进阶到目标循环、时间循环和主动循环的实用指引——以及各自的适用场景。

> Learn how the Claude Code team defines agentic loops, with practical guidance on progressing from turn-based to goal-based, time-based, and proactive loops—and when to use each.

现在有很多关于"设计循环（loop）"而非给编码智能体（coding agent）写提示词的讨论。如果你花些时间在 X 上想弄清楚循环到底是什么，你会看到很多不同的答案。

> There’s a lot of talk right now about "designing loops" instead of prompting your coding agent. If you spend some time on X trying to pin down what a loop actually is, you'll come across multiple different answers.

在 Claude Code 团队，我们把循环定义为智能体反复执行工作周期，直到满足停止条件为止。我们根据以下几点对几种不同类型的循环进行分类：

> On the Claude Code team, we define loops as agents repeating cycles of work until a stop condition is met . We categorize a few different types of loops based on:

- 它们如何被触发
- 它们如何被停止
- 使用了哪种 Claude Code 原语（primitive）
- 哪种类型的任务最适合各自使用。

> • How they are triggered
> • How they are stopped
> • What Claude Code primitive is used
> • What type of task is most appropriate for each.
我们将介绍主要的循环类型、各自的适用场景，以及如何在管理 token 用量的同时保持代码质量。并非所有任务都需要复杂的循环；从最简单的方案入手，有选择地使用这些模式。

> We’ll cover the main loop types, when to use each, and how to maintain code quality while managing token usage. Not all tasks require complex loops; start with the simplest solution and use these patterns selectively.

### 轮次循环

> Turn-based loops

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a43eb603762e725a739d98c_8ace2295.png)

- 触发方式：用户提示。
- 停止条件：Claude 判断已完成任务，或需要更多上下文。
- 最适用于：不属于常规流程或计划的较短任务。
- 用量管理方式：编写具体的提示，并借助技能（skill）改进验证，以减少轮次数量。

> • Triggered by : A user prompt.
> • Stop criteria : Claude judges it has completed the task or needs additional context.
> • Best used for: Shorter tasks that are not part of a regular process or schedule.
> • Managed usage by: Write specific prompts and improve verification using skills to reduce the number of turns. ‍
你发送的每一个提示都会开启一个由你手动引导的循环，每一轮都由你来指挥。Claude 收集上下文、采取行动、检查结果，必要时重复，然后给出回应。我们称之为智能体循环（agentic loop）。

> Every prompt you send starts a manual loop with you directing each turn. Claude gathers context, takes action, checks its work, repeats if needed, and responds. We call this the agentic loop.

例如，让 Claude 创建一个点赞按钮。它会读取你的代码、进行修改、运行测试，并交回一个它认为可用的结果。然后你手动检查这项工作，并写下下一个提示。

> For example, ask Claude to create a like button. It reads your code, makes the edit, runs the tests, and hands back something it believes works. You then manually check the work, and write the next prompt.

你可以通过把手动步骤编码为 SKILL.md 来改进验证环节，让 Claude 能够端到端地检查更多自己的工作。这应包含工具或连接器（connector），使 Claude 能够查看、衡量或与结果交互。检查越是量化，Claude 就越容易进行自我验证。

> You can improve the verification step by encoding your manual steps as a SKILL.md so Claude can check more of its own work, end-to-end. This should include tools or connectors to allow Claude to see , measure or interact with the result. The more quantitative the checks are, the easier it is for Claude to self-verify.

例如，在你的 SKILL.md 文件中，你可以这样指定：

> For example, in your SKILL.md file you may specify:

```text
--- name: verify-frontend-change description: 在宣布完成前端改动完成之前，端到端地验证任何 UI 改动。 --- # 验证前端改动 切勿仅凭一次成功的编辑就报告 UI 改动已完成。要像人工审阅者那样验证它： 1. 启动开发服务器，并在浏览器中打开被编辑的页面。 2. 直接与改动进行交互。对于新控件（按钮、输入框、开关）：点击它，确认预期的状态变化，并截取前后对比图。 3. 检查浏览器控制台：不应出现任何新的错误或警告。 4. 使用 Chrome Devtools MCP，运行一次性能追踪，并审计核心网页指标（Core Web Vitals）。 如果任何一步失败，修复问题并从第 1 步重新运行——不要交回只经过部分验证的工作。
```

> ```text
> --- name: verify-frontend-change description: Verify any UI change end-to-end before declaring it done. --- # Verifying frontend changes Never report a UI change as complete based on a successful edit alone. Verify it the way a human reviewer would: 1. Start the dev server and open the edited page in the browser. 2. Interact with the change directly. For a new control (button, input, toggle): click it, confirm the expected state change, and screenshot before/after. 3. Check the browser console: zero new errors or warnings. 4. Use the Chrome Devtools MCP, run a performance trace and audit Core Web Vitals. If any step fails, fix the issue and rerun from step 1 — do not hand back partially verified work.
> ```

### 基于目标的循环（/goal）

> Goal-based loop (/goal)

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a43eb603762e725a739d98f_c6fa9ae5.png)

- 触发方式：实时手动输入提示词。
- 停止条件：达成目标，或达到最大轮次数。
- 最适用于：具有可验证退出条件的任务。
- 使用管理方式：设定具体的完成条件和明确的轮次上限，例如"尝试 5 次后停止"。

> • Triggered by : A manual prompt in real-time.
> • Stop criteria : Goal achieved OR maximum number of turns reached.
> • Best used for: Tasks that have verifiable exit criteria.
> • Managed usage by: Setting a specific completion criteria and explicit turn caps, “stop after 5 tries.”
有时单轮并不够用，尤其是面对更复杂的任务。智能体（agent）在能够迭代时表现更好。你可以通过用 /goal 定义"完成"的样子，来延长 Claude 持续迭代的时间。

> Sometimes, a single turn is not enough, especially for more complex tasks. Agents do better when they can iterate. You can extend how long Claude keeps iterating by defining what done looks like with /goal.

当你定义了成功标准后，Claude 就不必自行判断怎样算"足够好"而提前结束循环。每次 Claude 试图停止时，一个评估器模型会检查你设定的条件，并让它继续工作，直到达成目标或达到你设定的轮次数为止。

> When you define the success criteria, Claude doesn’t have to make a determination on what is “good enough” and end the loop early. Each time Claude tries to stop, an evaluator model checks your condition and sends it back to work until the goal is met or a number of turns you define is reached.

这正是确定性标准（如通过的测试数量，或清除某个分数阈值）之所以如此有效的原因。

> This is why deterministic criteria, such as number of tests passed or clearing a certain score threshold, are so effective.

例如：

> For example:

```text
/goal 让首页的 Lighthouse 分数达到 90 分或以上，尝试 5 次后停止。
```

> ```text
> /goal get the homepage Lighthouse score to 90 or above, stop after 5 tries.
> ```

### 基于时间的循环（/loop 与 /schedule）

> Time-based loop (/loop and /schedule)

- 触发方式：指定的时间间隔。
- 停止条件：你取消它，或工作完成（PR 合并、队列清空）。
- 最适用于：周期性工作，或与外部环境/系统对接。
- 管理用量方式：设置更长的间隔，或基于事件而非时间来响应。

> • Triggered by : A specified time interval.
> • Stop criteria : You cancel it, or the work completes (the PR merges, the queue is empty).
> • Best used for: For recurring work, or interfacing with external environments / systems.
> • Managed usage by: Set longer intervals or react based on events rather than time.
有些智能体工作是周期性的：任务保持不变，只有输入发生变化。例如，每天早上汇总 Slack 消息。另一些工作则依赖外部系统，而与外部系统对接的一种简单方式，就是按间隔检查它并对变化作出响应。例如，一个 PR 可能会收到代码评审，或者 CI 失败。

> Some agentic work is recurring: the task stays the same and only the inputs change. For example, summarizing Slack messages every morning. Other work depends on external systems, and a simple way to interface with one is to check it on an interval and react to what changed. For example, a PR which may receive code reviews or fail CI.

对于这些场景，你可以用 `/loop` 来触发 Claude 运行，它会按间隔重新运行一个提示词。例如：

> For these, you can trigger when Claude runs with `/loop` which re-runs a prompt on an interval. For example:

```text
/loop 5m check my PR, address review comments, and fix failing CI
```

> ```text
> /loop 5m check my PR, address review comments, and fix failing CI
> ```

`/loop` 在你的电脑上运行，所以如果你关机，它就会停止。你可以通过用 `/schedule` 创建一个例程，把循环迁移到云端。

> `/loop` runs on your computer, so if you turn it off, it stops. You can move the loop to the cloud by creating a routine with `/schedule`.

### 主动循环

> Proactive loops

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a43eb603762e725a739d989_eb9e496a.png)

- 触发方式：由事件或计划触发，无需人类实时参与。
- 停止条件：每个任务在其目标达成时退出。例程本身会一直运行，直到你将其关闭。
- 最适用于：反复出现的、定义明确的工作流：缺陷报告、问题分类、迁移、依赖升级等。
- 用量管理方式：将例程路由到更小、更快的模型，仅在需要判断的场合使用能力最强的模型。

> • Triggered by : An event or schedule, with no human in real time.
> • Stop criteria : Each task exits when its goal is met. The routine itself runs until you turn it off.
> • Best used for: Recurring streams of well-defined work: bug reports, issue triage, migrations, dependency upgrades, etc.
> • Managed usage by: Routing routines to smaller, faster models and using the most capable model for judgment calls.
上述基本单元（primitive），连同 Claude Code 的其他特性，如自动模式（auto mode）和动态工作流（dynamic workflows，研究预览版），可以组合成一个循环，用于长时间运行的工作。

> The primitives above, along with other Claude Code features like auto mode and dynamic workflows (research preview) can be composed into a loop for long-running work.

例如，要处理传入的反馈，你可以使用：

> For example, to handle incoming feedback, you can use:

- `/schedule`（研究预览版）运行一个例程，检查是否有新报告
- `/goal` 定义完成的样子，并用技能（skill）记录如何验证它
- 动态工作流来编排智能体（agent），对每个报告进行分类、修复，并复审修复
- 自动模式，使例程无需停下来请求许可即可运行

> • `/schedule` (research preview) to run a routine that checks for new reports
> • `/goal` to define what done looks and skills to document how to verify it
> • Dynamic workflows to orchestrate agents that triage each report, fix it, and review the fix
> • Auto mode so the routine runs without stopping to ask for permission
组合起来，提示词可能是这样的：

> Putting it together, a prompt could look like this:

```text
/schedule every hour: check #project-feedback for bug reports. /goal: don't stop until every report found this run is triaged, actioned, and responded to. When fixing a bug, use a workflow to explore three solutions in parallel worktrees and have a judge adversarially review them.
```

> ```text
> /schedule every hour: check #project-feedback for bug reports. /goal: don't stop until every report found this run is triaged, actioned, and responded to. When fixing a bug, use a workflow to explore three solutions in parallel worktrees and have a judge adversarially review them.
> ```

### 保持代码质量

> Maintaining code quality

循环输出的质量取决于其周围的系统。在设计系统时：

> The quality of a loop’s output depends on the system around it. When designing the system:

- 保持代码库本身整洁：Claude 会遵循代码库中已有的模式和约定。
- 给 Claude 一种验证自己工作的方式：用技能（skills）把你和团队眼中"好的样子"编码下来。
- 让文档易于获取：框架和库的文档包含最新的最佳实践。
- 使用第二个智能体做代码审查：拥有全新上下文的审查者偏见更少，也不会受到主智能体推理过程的影响。你可以使用内置的 `/code-review` 技能或 Code Review for Github。

> • Keep the codebase itself clean : Claude follows patterns and conventions that already exist in your codebase.
> • Give Claude a way to verify its own work : Encode what good looks like for you and your team with skills .
> • Make docs easy to reach: Frameworks and libraries docs have up-to-date best practices.
> • Use a second agent for code reviews : A reviewer with fresh context is less biased and not influenced by the main agent’s reasoning. You can use the built-in `/code-review` skill or Code Review for Github.
当某个单独的结果没有达到标准时，不要止步于修复这个单独的问题，试着把它编码进系统，从而改进未来所有的迭代。

> When an individual result doesn’t meet the standard, don’t stop at fixing the individual issue, try to encode it to improve the system for all future iterations.

### 管理 Token 用量

> Managing token usage

为管理 Token 用量，循环应当有清晰的边界：

> To manage token usage, loops should have clear boundaries:

- 为任务选择合适的原语和模型：较小的任务不需要多个智能体或循环。有些任务可以使用更便宜、更快的模型。
- 定义清晰的成功与停止标准：明确「完成」是什么样子，让 Claude 能更快（但不要过早）得出解决方案。
- 大规模运行前先试点：动态工作流可能派生出数百个智能体。先在一小部分工作上评估用量。
- 用脚本处理确定性工作：运行脚本比逐步推理更便宜。例如，PDF 技能可以附带一个填表脚本供 Claude 每次运行，而不必重新推导代码。
- 不要以超出需要的频率运行例程：将运行间隔与被监控对象的变化频率相匹配。
- 查看用量：`/usage` 命令按技能、子智能体和 MCP 分解近期用量，不带参数的 `/goal` 显示到目前为止的轮次数和 Token 用量，`/workflows` 显示每个智能体的 Token 用量，你可以随时停止某个智能体。

> • Choose the right primitive and model for the job: Smaller tasks don’t need multiple agents or loops. Some tasks can use cheaper and faster models.
> • Define clear success and stop criteria: Be specific about what done looks like so Claude can arrive at the solution sooner (but not too soon).
> • Pilot before a large run: Dynamic workflows can spawn hundreds of agents. Gauge usage on a smaller slice of the work first.
> • Use scripts for deterministic work : Running a script is cheaper than reasoning through the steps. For example, a PDF skill can ship a form-filling script that Claude runs each time, instead of re-deriving the code.
> • Don’t run routines more often that you need to: Match the interval to how often the thing you’re watching changes
> • Review usage: The `/usage` command breaks down recent usage by skills, subagents, and MCPs, `/goal` with no arguments shows number of turns and token usage so far, `/workflows` shows each agent’s token usage and you can stop an agent at any time.
### 开始上手

> Getting started

总结一下：

> To summarize:

要开始使用循环（loops），先审视你已经在做的工作。挑一个你成为瓶颈的任务，问问自己有哪一部分可以交出去：你能写出验证检查吗？目标是否足够清晰？工作是否按固定的时间表到来？

> To get started with loops, look at the work you already do. Pick one task where you’re the bottleneck and ask which piece you could hand off: can you write the verification check? Is the goal clear enough? Does the work arrive on a schedule?

一旦有了想法，就运行这个循环，观察结果，比如它在哪里卡住或做过了头，并且不要害怕对它进行迭代。

> Once you have an idea, run the loop, observe the results like where it stalls or over-reaches, and don’t be afraid to iterate on it.

想了解更多信息，请阅读 Claude Code 文档中关于并行运行智能体（agents）的内容，以及循环（loop）、时间表（schedule）、目标（goal）和动态工作流（dynamic workflows）页面。

> For more information, read the Claude Code docs on running agents in parallel, as well as the loop , schedule , goal , and dynamic workflows pages.

本文由 Delba de Oliveira 和 Michael Segner 撰写

> This article was written by Delba de Oliveira and Michael Segner

## 术语对照

| English | 中文 |
|---|---|
| loop | 循环 |
| agentic loop | 智能体循环 |
| stop condition | 停止条件 |
| turn-based loop | 轮次循环 |
| goal-based loop | 目标循环 |
| time-based loop | 时间循环 |
| proactive loop | 主动循环 |
| turn cap | 轮次上限 |
| evaluator model | 评估模型 |
| skill | 技能 |
| routine | 例程 |
| dynamic workflows | 动态工作流 |
| auto mode | 自动模式 |
| Core Web Vitals | 核心网页指标 |
