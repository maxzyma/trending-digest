---
source: claude-blog
source_url: https://claude.com/blog/getting-started-with-loops
published_at: 2026-06-30
category: Claude Code
title_en: Getting started with loops
title_zh: 上手智能体循环
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 3
source_image_count: 3
---

# 上手智能体循环

> Getting started with loops

> 来源：Claude Blog，2026-06-30
> 原文链接：https://claude.com/blog/getting-started-with-loops
> 分类：Claude Code

## 核心要点

- 循环的本质是智能体反复执行工作周期，直到满足停止条件；团队按触发方式、停止方式、所用原语和适用任务类型进行分类。
- 回合制循环由用户提示词触发，每一步由人来主导，适合无需纳入固定流程的短任务；可用技能文件把人工验证步骤编码进去，让 Claude 端到端自查。
- 目标制循环通过 /goal 定义完成标准，由评估模型在每次尝试停止时校验条件，直到达成目标或用尽设定的回合上限，适合有可验证退出条件的任务。
- 确定性标准（如通过的测试数量、达到某个评分阈值）最为有效，因为无需 Claude 自行判断何为足够好。
- 定时制循环用 /loop 按时间间隔重跑提示词，适合重复性工作或与外部系统交互；用 /schedule 可把循环迁到云端形成例程。
- 主动式循环由事件或计划触发、无需人实时参与，适合持续涌入的明确工作流，如缺陷报告、问题分诊、迁移和依赖升级。
- 可将各原语与自动模式、动态工作流等特性组合，构建长时运行的循环；把例程分流给更小更快的模型，判断性环节保留给最强模型。

## 正文

了解 Claude Code 团队如何定义智能体循环，并获得从回合制循环逐步进阶到目标制、定时制与主动式循环的实用指引，以及各自的适用场景。

> Learn how the Claude Code team defines agentic loops, with practical guidance on progressing from turn-based to goal-based, time-based, and proactive loops—and when to use each.

现在有很多关于"设计循环"（designing loops）而非给编码智能体写提示词的讨论。如果你花些时间在 X 上试图弄清循环究竟是什么，你会看到多种不同的答案。

> There’s a lot of talk right now about "designing loops" instead of prompting your coding agent. If you spend some time on X trying to pin down what a loop actually is, you'll come across multiple different answers.

在 Claude Code 团队，我们把循环定义为：智能体不断重复工作周期，直到满足停止条件。我们基于以下几点对循环类型做了区分：

> On the Claude Code team, we define loops as agents repeating cycles of work until a stop condition is met . We categorize a few different types of loops based on:

- 如何触发
- 如何停止
- 使用了哪个 Claude Code 原语（primitive）
- 每种循环最适合哪类任务。

> • How they are triggered
> • How they are stopped
> • What Claude Code primitive is used
> • What type of task is most appropriate for each.
我们将介绍主要的循环类型、各自的适用场景，以及如何在管理 token 用量的同时保持代码质量。并非所有任务都需要复杂的循环；从最简单的方案入手，有选择地使用这些模式。

> We’ll cover the main loop types, when to use each, and how to maintain code quality while managing token usage. Not all tasks require complex loops; start with the simplest solution and use these patterns selectively.

### 轮次循环（Turn-based loops）

> Turn-based loops

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a43eb603762e725a739d98c_8ace2295.png)

- 触发方式：用户的一次提示。
- 停止条件：Claude 判断自己已完成任务，或需要更多上下文。
- 最适合：不属于常规流程或排期的较短任务。
- 用量管理方式：编写具体的提示，并借助技能（skills）改进验证，以减少轮次数量。

> • Triggered by : A user prompt.
> • Stop criteria : Claude judges it has completed the task or needs additional context.
> • Best used for: Shorter tasks that are not part of a regular process or schedule.
> • Managed usage by: Write specific prompts and improve verification using skills to reduce the number of turns. ‍
你发送的每一条提示都会启动一个手动循环，由你来主导每一轮。Claude 收集上下文、采取行动、检查自己的工作，必要时重复，然后给出回应。我们称之为智能体循环（agentic loop）。

> Every prompt you send starts a manual loop with you directing each turn. Claude gathers context, takes action, checks its work, repeats if needed, and responds. We call this the agentic loop.

例如，让 Claude 创建一个点赞按钮。它会阅读你的代码、完成修改、运行测试，然后交回一个它认为可用的结果。之后由你手动检查这份工作，并写下一条提示。

> For example, ask Claude to create a like button. It reads your code, makes the edit, runs the tests, and hands back something it believes works. You then manually check the work, and write the next prompt.

你可以把自己的手动步骤编码进一个 SKILL.md 文件，从而改进验证环节，让 Claude 能端到端地检查更多自己的工作。这应当包含工具或连接器（connectors），以便 Claude 能够看到、测量或与结果交互。检查越量化，Claude 就越容易自我验证。

> You can improve the verification step by encoding your manual steps as a SKILL.md so Claude can check more of its own work, end-to-end. This should include tools or connectors to allow Claude to see , measure or interact with the result. The more quantitative the checks are, the easier it is for Claude to self-verify.

例如，在你的 SKILL.md 文件中，你可以这样指定：

> For example, in your SKILL.md file you may specify:

```plaintext
---
name: verify-frontend-change
description: Verify any UI change end-to-end before declaring it done.
---

# 验证前端改动
绝不要仅凭一次成功的编辑就把某个 UI 改动报告为已完成。要像人工评审者那样去验证它：

1. 启动开发服务器，并在浏览器中打开被编辑的页面。

2. 直接与改动交互。对于新增的控件（按钮、输入框、开关）：点击它，确认预期的状态变化，并截取前后对比图。

3. 检查浏览器控制台：不能有任何新的错误或警告。

4. 使用 Chrome Devtools MCP，运行一次性能追踪并审计核心网页指标（Core Web Vitals）。

如果任一步骤失败，修复问题并从第 1 步重新运行——不要交回只验证了一部分的工作。
```

> ---
> name: verify-frontend-change
> description: Verify any UI change end-to-end before declaring it done.
> ---
>
> # Verifying frontend changes
> Never report a UI change as complete based on a successful edit alone. Verify it the way a human reviewer would:
>
> 1. Start the dev server and open the edited page in the browser.
>
> 2. Interact with the change directly. For a new control (button, input, toggle): click it, confirm the expected state change, and screenshot before/after.
>
> 3. Check the browser console: zero new errors or warnings.
>
> 4. Use the Chrome Devtools MCP, run a performance trace and audit Core Web Vitals.
>
> If any step fails, fix the issue and rerun from step 1 — do not hand back partially verified work.

### 基于目标的循环（/goal）

> Goal-based loop (/goal)

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a43eb603762e725a739d98f_c6fa9ae5.png)

- 触发方式：实时手动输入提示词。
- 停止条件：达成目标，或到达最大轮次数。
- 最适合：具有可验证退出条件的任务。
- 用量管理方式：设定明确的完成标准和明确的轮次上限，比如“尝试 5 次后停止”。

> • Triggered by : A manual prompt in real-time.
> • Stop criteria : Goal achieved OR maximum number of turns reached.
> • Best used for: Tasks that have verifiable exit criteria.
> • Managed usage by: Setting a specific completion criteria and explicit turn caps, “stop after 5 tries.”
有时候一轮还不够，尤其是较复杂的任务。智能体（agent）在能够迭代时表现更好。你可以通过用 /goal 定义“完成”的样子，来延长 Claude 持续迭代的时长。

> Sometimes, a single turn is not enough, especially for more complex tasks. Agents do better when they can iterate. You can extend how long Claude keeps iterating by defining what done looks like with /goal.

当你定义了成功标准后，Claude 就不必自行判断怎样算“足够好”而提前结束循环。每次 Claude 试图停止时，一个评估模型（evaluator model）会检查你设定的条件，并让它继续工作，直到达成目标或到达你设定的轮次数。

> When you define the success criteria, Claude doesn’t have to make a determination on what is “good enough” and end the loop early. Each time Claude tries to stop, an evaluator model checks your condition and sends it back to work until the goal is met or a number of turns you define is reached.

正因如此，确定性的标准（比如通过的测试数量，或达到某个分数阈值）才如此有效。

> This is why deterministic criteria, such as number of tests passed or clearing a certain score threshold, are so effective.

例如：

> For example:

```plaintext
/goal 让首页的 Lighthouse 分数达到 90 或以上，尝试 5 次后停止。
```

> /goal get the homepage Lighthouse score to 90 or above, stop after 5 tries.

### 基于时间的循环（/loop 和 /schedule）

> Time-based loop (/loop and /schedule)

- 触发方式：指定的时间间隔。
- 停止条件：你取消它，或工作完成（PR 合并、队列清空）。
- 最适用于：周期性工作，或与外部环境／系统对接。
- 用量管理方式：设置更长的间隔，或基于事件而非时间来响应。

> • Triggered by : A specified time interval.
> • Stop criteria : You cancel it, or the work completes (the PR merges, the queue is empty).
> • Best used for: For recurring work, or interfacing with external environments / systems.
> • Managed usage by: Set longer intervals or react based on events rather than time.
有些智能体（agentic）工作是周期性的：任务保持不变，只有输入在变化。例如每天早上汇总 Slack 消息。另一些工作依赖于外部系统，而与其对接的一种简单方式，就是按间隔检查它并对变化做出响应。例如一个 PR，它可能收到代码评审或 CI 失败。

> Some agentic work is recurring: the task stays the same and only the inputs change. For example, summarizing Slack messages every morning. Other work depends on external systems, and a simple way to interface with one is to check it on an interval and react to what changed. For example, a PR which may receive code reviews or fail CI.

对于这些场景，你可以用 `/loop` 触发 Claude 的运行，它会按间隔重新执行一个提示词。例如：

> For these, you can trigger when Claude runs with `/loop` which re-runs a prompt on an interval. For example:

```plaintext
/loop 5m check my PR, address review comments, and fix failing CI
```

> /loop 5m check my PR, address review comments, and fix failing CI

`/loop` 运行在你的电脑上，所以如果你关机，它就会停止。你可以通过用 `/schedule` 创建一个例程（routine），把循环迁移到云端。

> `/loop` runs on your computer, so if you turn it off, it stops. You can move the loop to the cloud by creating a routine with `/schedule`.

### 主动式循环

> Proactive loops

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a43eb603762e725a739d989_eb9e496a.png)

- 触发方式：由事件或计划任务触发，无需人工实时参与。
- 停止条件：每个任务在达成目标后退出。例程本身则持续运行，直到你手动关闭。
- 最适合场景：定义明确、反复出现的工作流：缺陷报告、问题分类（triage）、迁移、依赖升级等。
- 用量管理方式：将例程路由到更小、更快的模型，只在需要判断决策时使用能力最强的模型。

> • Triggered by : An event or schedule, with no human in real time.
> • Stop criteria : Each task exits when its goal is met. The routine itself runs until you turn it off.
> • Best used for: Recurring streams of well-defined work: bug reports, issue triage, migrations, dependency upgrades, etc.
> • Managed usage by: Routing routines to smaller, faster models and using the most capable model for judgment calls.
上述基础能力，连同其他 Claude Code 特性——如自动模式（auto mode）和动态工作流（dynamic workflows，研究预览版）——可以组合成一个用于长时间运行工作的循环。

> The primitives above, along with other Claude Code features like auto mode and dynamic workflows (research preview) can be composed into a loop for long-running work.

例如，要处理收到的反馈，你可以使用：

> For example, to handle incoming feedback, you can use:

- `/schedule`（研究预览版）来运行一个检查新报告的例程
- `/goal` 来定义"完成"的样子，并用技能（skills）来记录如何验证完成
- 动态工作流来编排各个智能体，对每份报告进行分类、修复，并复审修复
- 自动模式，让例程无需停下来请求许可即可运行

> • `/schedule` (research preview) to run a routine that checks for new reports
> • `/goal` to define what done looks and skills to document how to verify it
> • Dynamic workflows to orchestrate agents that triage each report, fix it, and review the fix
> • Auto mode so the routine runs without stopping to ask for permission
把它们组合起来，一个提示词可能是这样的：

> Putting it together, a prompt could look like this:

```plaintext
/schedule 每小时：检查 #project-feedback 中的缺陷报告。/goal：在本次运行中找到的每份报告都被分类、处理并回复之前，不要停止。修复缺陷时，用一个工作流在三个并行的工作树（worktrees）中探索三种解决方案，并让一个评审者对它们进行对抗式复审。
```

> /schedule every hour: check #project-feedback for bug reports. /goal: don't stop until every report found this run is triaged, actioned, and responded to. When fixing a bug, use a workflow to explore three solutions in parallel worktrees and have a judge adversarially review them.

### 保持代码质量

> Maintaining code quality

循环输出的质量取决于其周围的系统。在设计系统时：

> The quality of a loop’s output depends on the system around it. When designing the system:

- 保持代码库本身整洁：Claude 会遵循代码库中已有的模式和约定。
- 给 Claude 一种验证自身工作的方法：用技能（skills）把你和团队心中"好的标准"编码下来。
- 让文档易于获取：框架和库的文档包含最新的最佳实践。
- 使用第二个智能体做代码审查：拥有全新上下文的审查者偏见更少，不会受主智能体推理过程的影响。你可以使用内置的 `/code-review` 技能，或使用 Code Review for Github。

> • Keep the codebase itself clean : Claude follows patterns and conventions that already exist in your codebase.
> • Give Claude a way to verify its own work : Encode what good looks like for you and your team with skills .
> • Make docs easy to reach: Frameworks and libraries docs have up-to-date best practices.
> • Use a second agent for code reviews : A reviewer with fresh context is less biased and not influenced by the main agent’s reasoning. You can use the built-in `/code-review` skill or Code Review for Github.
当某个单独结果未达到标准时，不要止步于修复这个单独问题，而要尝试把它编码进系统，从而改进未来所有的迭代。

> When an individual result doesn’t meet the standard, don’t stop at fixing the individual issue, try to encode it to improve the system for all future iterations.

### 管理令牌用量

> Managing token usage

为管理令牌用量，循环应有清晰的边界：

> To manage token usage, loops should have clear boundaries:

- 为任务选择合适的原语和模型：较小的任务不需要多个智能体或循环。有些任务可以使用更便宜、更快的模型。
- 定义清晰的成功与停止标准：明确说明"完成"是什么样子，好让 Claude 更早（但不要太早）得出解决方案。
- 大规模运行前先试点：动态工作流可能生成数百个智能体。先在一小部分工作上评估用量。
- 用脚本处理确定性工作：运行脚本比逐步推理更便宜。例如，PDF 技能可以附带一个填表脚本，让 Claude 每次运行它，而不是每次重新推导代码。
- 不要以超出需要的频率运行例程：让间隔与你所监测事物的变化频率相匹配。
- 查看用量：`/usage` 命令按技能、子智能体和 MCP 分解近期用量，不带参数的 `/goal` 显示目前的轮次数和令牌用量，`/workflows` 显示每个智能体的令牌用量，你可以随时停止某个智能体。

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

要开始使用循环（loops），先审视你已经在做的工作。挑选一个你成为瓶颈的任务，并思考其中哪一部分可以交出去：你能否写出验证检查？目标是否足够清晰？工作是否按固定时间到达？

> To get started with loops, look at the work you already do. Pick one task where you’re the bottleneck and ask which piece you could hand off: can you write the verification check? Is the goal clear enough? Does the work arrive on a schedule?

一旦有了想法，就运行循环，观察结果，比如它在哪里停滞或越界，并且不要害怕对它进行迭代。

> Once you have an idea, run the loop, observe the results like where it stalls or over-reaches, and don’t be afraid to iterate on it.

更多信息请阅读 Claude Code 文档中关于并行运行智能体（running agents in parallel）的内容，以及循环（loop）、调度（schedule）、目标（goal）和动态工作流（dynamic workflows）等页面。

> For more information, read the Claude Code docs on running agents in parallel, as well as the loop , schedule , goal , and dynamic workflows pages.

本文由 Delba de Oliveira 和 Michael Segner 撰写

> This article was written by Delba de Oliveira and Michael Segner

## 术语对照

| English | 中文 |
|---|---|
| agentic loop | 智能体循环 |
| stop condition | 停止条件 |
| turn-based loop | 回合制循环 |
| goal-based loop | 目标制循环 |
| time-based loop | 定时制循环 |
| proactive loop | 主动式循环 |
| prompt | 提示词 |
| verification | 验证 |
| skill | 技能 |
| evaluator model | 评估模型 |
| turn cap | 回合上限 |
| routine | 例程 |
| auto mode | 自动模式 |
| dynamic workflow | 动态工作流 |
