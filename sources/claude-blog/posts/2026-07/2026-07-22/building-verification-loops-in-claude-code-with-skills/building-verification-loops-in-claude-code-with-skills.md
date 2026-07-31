# 用技能在 Claude Code 中构建验证循环

> Building verification loops in Claude Code with skills

> 来源：Claude Blog / Anthropic，2026-07-22
> 原文链接：https://claude.com/blog/building-verification-loops-in-claude-code-with-skills
> 分类：AI 工程 / 智能体验证

## 核心要点

- 代理式编程会话遵循一个循环：用户提出变更请求，Claude 收集上下文、采取行动、验证结果，必要时回到起点收集更多上下文。
- Claude 已能借助类型检查器、代码检查工具、测试和运行时错误等确定性信号完成部分验证，其余无法推断的部分则落回到人工检查步骤上。
- 验证循环指智能体在继续下一步之前运行测试、linter 或自定义检查并修复失败项的重复周期，打包为技能后每个会话都会自动应用相同检查。
- Claude Code 已内置多种验证支持，包括 /verify 技能、工具链错误码捕捉、Code Review 研究预览版、GitHub Actions job、规范校验技能，以及托管式智能体中基于评分标准的 beta 验证。
- 编写自定义验证循环的第一步是把每次都会重复执行的修补步骤用平实语言写下来，如同交给入职第一天的新队友的说明；难以表述时可先向 Claude 索取最佳实践再作修改。
- 验证检查不必是定性的，例如“拒绝任何在没有回填步骤的情况下删除列的迁移”就是通用 linter 捕捉不到、但项目专属 linter 可以捕捉的确定性规则。
- 把重复步骤编码为技能的最快方式是安装 skill-creator 插件让 Claude 进行访谈，也可以手写一个包含 frontmatter 与正文的 markdown 文件放入项目的 .claude/skills/ 目录。
- 独立方式适用于安全扫描、可访问性审计、许可证头校验等并非每次改动都适用的横切检查，其代价是每次调用都需要人记得触发。
- 嵌入式方式让检查随特定工作流自动运行，仅适用于可编辑的技能；内置技能和由插件管理、更新时会被覆盖的技能应改用链式调用。
- 链式调用让一个技能在结束时调用下一个，Anthropic 的 Claude Code 团队即以 /code-review、/simplify、/verify 与自定义 /design 技能串接使用，代价是牺牲灵活性并增加 token 开销。
- 当技能链对个人改动足够可靠后，同一套技能、评分标准与规范可在每个 PR 上运行，使验证从个人基础设施变为团队基础设施；但链路仍在变动时不宜设置覆盖全部 PR 的门禁。

## 正文

大多数[代理式编程](https://claude.com/blog/introduction-to-agentic-coding)会话都遵循一个循环：你请求一项变更，Claude 收集上下文、采取行动、验证结果，如有需要，再回到循环开头收集更多上下文。

> Most [agentic coding](https://claude.com/blog/introduction-to-agentic-coding) sessions follow a loop: you ask for a change, Claude gathers context, takes action, verifies the results, and if needed, loops back to gather additional context.

验证是智能体在响应之前检查自身工作的方式。Claude 已经通过观察你代码库中的确定性信号完成了部分验证工作，这些信号包括类型检查器、代码检查工具、测试和运行时错误。凡是 Claude 无法推断出来的部分，就变成了你手动检查某项功能时所要执行的步骤。

> Verification is how agents check their work before responding. Claude already does some of this from observing the deterministic signals in your codebase, including type checkers, linters, tests, and runtime errors. Whatever Claude can't infer becomes the steps you take to manually check a feature. 

然而，这些手动步骤可以转化为验证循环。在 [Claude Code](https://claude.com/product/claude-code) 中，验证循环是一个迭代过程，Claude 会在其中检查并尝试修复工作成果。

> These manual steps, however, can be transformed into verification loops. In [Claude Code](https://claude.com/product/claude-code), a verification loop is an iterative process where Claude checks and attempts to fix the work.

![diagram of the agentic loop: 1. gathering context, 2. taking action, 3. verifying results.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a60f2068656db3211c097af_5b4284f8.png)

在本文中，我们将介绍最常见的验证循环类型，并向你展示我们在 Anthropic 内部使用的做法。然后我们会展示如何把你已经在手动执行的检查编码为技能（skills），这样 Claude 就能自行闭合反馈循环，而你可以在它迭代的同时去做别的事情。

> In this article, we cover the most common types of verification loops and show you what we use inside Anthropic. Then we’ll show how to encode the manual checks you already do as skills, so Claude can close its own feedback loop and you can work on something else while it iterates.

#### 什么是验证循环？

> What is a verification loop?

验证循环是一个不断重复的周期：AI 智能体检查自己的工作成果——运行测试、代码检查工具或自定义检查——并在继续下一步之前修复失败的部分。在 Claude Code 中，验证循环可以被打包成技能（skills），这样每个会话都会自动应用相同的检查，而不必依赖人来记住它们。

> A verification loop is a repeating cycle where an AI agent checks its own work — running tests, linters, or custom checks — and fixes what fails before moving on. In Claude Code, verification loops can be packaged as skills, so every session applies the same checks automatically instead of relying on a human to remember them.

#### 内置的验证循环

> Built-in verification loops

在深入设计自定义验证循环之前，先了解 Claude 对多种不同验证循环的内置支持会很有帮助。常见的功能和方法包括：

> Before diving into designing custom verification loops, it can be helpful to understand the built-in support Claude has for a number of different verification loops. Common features and approaches include:

- **/verify 技能**：构建、运行并观察你的应用程序中的更改。
- **工具链**：Claude 会力求捕捉你所提供的任意工具（例如 linter）发出的错误码和警告，并据此采取行动。一个良好的做法是在 CLAUDE.md 中列出你确切的构建和测试命令，这样 Claude 就不必去推断它们。
- **Code Review（研究预览版）**：一项托管的多智能体服务，会在你启用的仓库中对 PR 运行自动化审查。你可以手动修复发现的问题并推送，也可以通过在该问题下评论 @claude 来闭环处理（前提是你已按下文完成 GitHub Actions 的设置和配置）。
- **GitHub Actions**：定义一个调用 Claude 并使用验证技能的 job，这样你在本地运行的那套检查就会在每次 push 或 PR 时触发。
- **规范校验**：一项技能，帮助对照仓库中的 markdown 规范验证每一处改动，并尝试修复违规之处。
- **Claude 托管式智能体中的评分标准（beta）**：一种托管式智能体服务，可让你借助独立的评分智能体，依据评分标准对结果进行验证。未通过的结果会自动回流，进入重做流程。

> • **/verify skill**: builds, runs, and observes the changes in your application.
> • **Toolchain**: Claude aims to catch and act on error codes and warnings from any tool you provide such as a linter. A good practice is to list your exact build and test commands in CLAUDE.md so Claude doesn't have to infer them.
> • **Code Review (research preview)**: A managed multi-agent service that runs an automated review pass on PRs in the repos you enable. You can manually fix the finding and push, or close the loop by commenting @claude on the finding (if you’ve already set up and configured GitHub Actions, below).
> • **GitHub Actions**: Define a job that invokes Claude with a verification skill, and the same checks you run locally fire on every push or PR.
> • **Spec validation**: A skill that helps verify each change against a markdown spec in the repo and looks to fix violations.
> • **Rubrics in Claude Managed Agents (beta)**: A managed agentic service that allows you to verify outcomes against a rubric using a separate grader agent. Failures loop back for rework automatically.

#### 编写验证循环 

> Writing verification loops 

当你手头有一个现成的项目，并且发现每次 Claude 为你实现新功能时，你都在做同样的那些小修小补，那就该把这些步骤变成你自己的自定义验证循环了。第一步是把你每次都会做的所有事情写下来

> When you have an existing project and you find yourself making the same small corrections every time Claude implements a new feature for you, it’s time to turn those steps into your own custom verification loop. The first step is to write down everything that you find yourself doing every time 

如果你正在启动一个新项目，需要弄清楚这个项目应该有怎样的行为，做法也是一样的。用平实的英语写出最佳实践的版本，就像你在新队友入职第一天时交给他们的那样。

> The same goes if you're starting a new project and need to figure out how the project should behave. Write the best-practices version in plain English, the way you'd hand it to a new teammate on day one.

如果你难以清晰表述验证检查本身，可以先向 Claude 询问最佳实践，然后在此基础上进行修改。你的版本可能在几个具体点上有所不同，而这些差异正是你想要捕捉的内容。

> If you're struggling to articulate the verification check itself, ask Claude for best practices first and edit from there. Your version probably differs on a few specific points, and those differences are exactly what you want to capture.

**专业提示**：这里的检查项并不一定得是定性的。「拒绝任何在没有回填步骤的情况下删除列的迁移」就是一条确定性规则，任何通用 linter 都捕捉不到它，但项目专属的 linter 可以。任何你不得不反复手动执行的检查，都有资格被捕获为一个循环。

> **Pro tip**: The check doesn't have to be qualitative to belong here. "Reject any migration that drops a column without a backfill step" is a deterministic rule no generic linter will catch but a project-specific one will. Anything you keep having to enforce by hand as a manual check qualifies for capture as a loop.

#### 把它做成一项技能

> Make it a skill

把重复性步骤编码进验证循环，最常见的做法是将其写成一个[技能](https://claude.com/blog/complete-guide-to-building-skills-for-claude)，而创建技能最快的方式是安装 skill-creator 插件，让 Claude 来对你进行访谈：

> The most common way to encode repetitive steps into  a verification loop is to write it as a [skill](https://claude.com/blog/complete-guide-to-building-skills-for-claude), and  the fastest way to create a skill is to install the skill-creator plugin and let Claude interview you:

示例：

> Example:

```plaintext
/skill-creator Create a skill for verifying frontend changes end-to-end. Interview me about my workflow.
```

你也可以手写一个 skill，只需在项目内的 .claude/skills/ 目录下放入一个 markdown 文件。最简单的验证 skill 就是几行 frontmatter 加上正文：

> You can also hand-write a skill by dropping a markdown file in .claude/skills/ inside your project. The simplest possible verification skill is a few lines of frontmatter plus a body:

```plaintext
# .claude/skills/verify-log-hygiene/SKILL.md
---
name: verify-log-hygiene
description: Check that error logs include the request ID and never
  include the request body. Use when the diff touches error handling
  or logging.
allowed-tools: [Read, Edit, Grep]
---
Read the error-handling paths in the current diff.

For each log call on an error path, confirm it includes the request ID
and does not pass the request body, headers, or any user-supplied payload.

Report each violation with file:line, then fix it: add the request ID
where it's missing and strip the payload from the log call.
```

完整的 schema 及其背后的理念，请参阅我们的[技能构建完全指南](https://claude.com/blog/complete-guide-to-building-skills-for-claude)。

> The full schema and the philosophy behind it are in our [complete guide to building skills](https://claude.com/blog/complete-guide-to-building-skills-for-claude).

#### 让校验与其运行的位置相匹配

> Match the check to where it runs

接下来要确定的是验证循环如何启动：独立运行、嵌入式、链式，还是与 PR 绑定。

> The next thing to determine will be how the verification loop kicks off: standalone, embedded, chained, or tied to PR. 

##### 独立

> Standalone

你要在产物已经存在之后，主动去调用它。独立技能的价值体现在那些并非每次都适用的横切检查上：提交前的安全扫描、提 PR 前的可访问性审计、跨仓库的许可证头校验。凡是你希望在多种工作流中都能随时取用、却不想在每次代码变更时都触发的检查，都属于这一类。

> You invoke it deliberately, after the artifact exists. A standalone skill earns its place for cross-cutting checks that don't apply every time: a pre-commit security scan, a pre-PR accessibility audit, license-header verification across a repo. Anything you want available across many workflows but don't want firing on every code change.

代价是每次调用仍然是一个你必须记着去执行的动作。当你在每次改动之后都要运行它时，这个信号就说明你已经不再适合独立方式了。到那时，这套流程已经赢得了一个永久的归属：把它嵌入进去，或者把它串接起来。

> The cost is that each invocation is still a turn you have to remember to take. The signal that you've outgrown standalone is when you're running it after every change. At that point, the procedure has earned a permanent home: embed it or chain it.

##### 嵌入式

> Embedded

作为产出技能的一部分自动触发。该检查隶属于某一个特定的工作流，而现在这个工作流无需你要求就会自动运行它。

> Fires automatically as part of the producing skill. The check belongs to one specific workflow, and the workflow now runs it without you asking.

最简单的版本是在生成该技能的主体中追加一行：

> The simplest version is a one-line append to the producing skill's body:

```plaintext
# .claude/skills/scaffold-component/SKILL.md
---
name: scaffold-component
description: Scaffold a new React component under src/components/, including the component file, its co-located test, and an index export. Use when the user asks to create a new component.
allowed-tools: [Read, Write, Edit, Bash, Glob]
---

# Scaffold a new React component

Given a component name (PascalCase), create the following under `src/components/<Name>/`:

1. `<Name>.tsx`: function component with a typed props interface and a default export.
2. `<Name>.test.tsx`: React Testing Library test that renders the component and asserts it mounts without throwing.
3. `index.ts`: re-export the default and any named exports.

Follow the patterns in `src/components/Button/` as the reference. Match the import alias style (`@/components/...`) used throughout the codebase.

# code continues...

After creating the component file, run eslint on it and
address any errors before reporting completion.
```

在一个全新的任务上调用该技能，确认新增的步骤作为输出的一部分运行，以此验证嵌入是否生效。如果没有生效，说明该技能的描述或前面的指令没有把追加的检查项纳入进来。

> Verify the embed works by invoking the skill on a fresh task and confirming the new step runs as part of the output. If it doesn't, the skill's description or earlier instructions aren't pulling the appended check in.

嵌入式方案只适用于你能编辑的技能：你自己编写的技能，或是安装在项目级别、SKILL.md 文件由你掌控的技能。内置技能和由插件管理的技能（那种会在更新时被覆盖的技能）不适用于这种模式；对于它们，请改用链式调用。

> Embedded only works on skills you can edit: ones you wrote yourself, or ones installed at a project level where the SKILL.md file is under your control. Built-in skills and plugin-managed skills (the kind that get overwritten on update) are off-limits for this pattern; for those, chain instead.

对于跨工作流的检查，不要使用嵌入式方式；这类检查需要独立运行，这样你就可以从任何上下文中调用它们。

> Skip embedded for checks that span workflows; those want standalone, so you can invoke them from any context.

##### 链式

> Chained

一个技能在结束时调用另一个技能，多次经过验证的交接可以端到端地运行。

> One skill calls another at its end, and several verified handoffs run end-to-end. 

Anthropic 的 Claude Code 团队成员在日常工作中就使用这种模式：/code-review 负责查找 bug，/simplify 负责清理 diff，/verify 技能负责确认端到端行为，如果改动涉及 UI，还会用一个自定义的 /design 技能对照 DESIGN.md 文件中的规范进行检查。

> Members of Anthropic's Claude Code team use this pattern in their day-to-day: /code-review hunts for bugs, /simplify cleans up the diff, a /verify skill confirms end-to-end behavior, and a custom /design skill checks against guidelines in a DESIGN.md file if the change touched UI.

链式调用也是为无法修改的技能添加验证的方式：构建一个自定义的包装技能，先调用原始技能，再调用你的验证技能，如下图所示：

> Chaining is also how you add verification to a skill you can't modify: build a custom wrapper skill that invokes the original, then invokes your verification skill, as depicted below: 

```plaintext
# .claude/skills/safe-refactor/SKILL.md
Run /simplify on the current diff first.
When /simplify finishes, invoke /verify-no-public-api-changes.
```

起初只是一种习惯（“我总是在 /simplify 之后运行 /verify”），后来变成了一种约定（“/simplify 结束时总会运行 /verify”）。这条链条会自行完成整个开发周期。只有当某个问题上报回你这里时，你才需要介入。

> What started as a habit ("I always run /verify after /simplify") becomes a contract ("/simplify always runs /verify when it finishes"). The chain runs the whole dev cycle on its own. You only step in when something escalates back to you. 

当各个步骤足够独立、你有时希望单独运行其中某一步而不运行其他步骤时，可以跳过链式调用；链式调用是以灵活性换取自动化。链式的验证循环会增加 token 开销，因此最好在大规模部署这些循环之前先做测试。

> You can skip chaining when the steps are independent enough that you sometimes want to run one without the others; chaining trades flexibility for automation. Chained verification loops can increase token spend, so it's best to test these loops before deploying them broadly.

##### 在每个 PR 上

> On every PR

一旦这套流程链对你自己的改动足够可靠，同样的过程就可以在每个 PR 上运行。队友的改动会通过与你的改动相同的关卡，无论他们是否记得去调用这条链。这套基础设施与你已经写好的那条链属于同一类东西，只是再往前走了一步：相同的技能、相同的评分标准、相同的规范，在不依赖作者自觉性的情况下得到应用。

> Once the chain is solid for your own changes, the same procedure can run on every PR. A teammate's change passes the same gates yours did, whether they remembered to invoke the chain or not. The infrastructure is the same kind of thing as the chain you already wrote, one step further along: the same skills, the same rubrics, the same standards, applied without depending on the author's diligence.

正是在这里，验证不再是个人的基础设施，而变成了[团队的基础设施](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start)。你为每周省下两分钟而写下的那项检查，如今在每一次变更中都为每个人节省两分钟。当整条链路仍在变动时，先不要设置覆盖全部 PR 的门禁；每一次调整都会成为一个团队可见的事件。

> This is where verification stops being personal infrastructure and becomes[ team infrastructure](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start). The check you wrote down to save yourself two minutes a week is now saving everyone two minutes a week, on every change. Hold off on PR-wide gates while the chain is still in flux; every adjustment becomes a team-visible event.

一旦掌握了这个流程，你就可以开始扩展你的循环工程了。无论你要自动化什么，也无论在什么环境中，验证循环的创建流程都是一致的：

> Once you have the process down, you’re ready to expand your loop engineering.   The verification loop creation process is consistent, no matter what you’re automating or in what environment:

1. 选出你这周做得最频繁的那项手动跟进工作。
2. 先试用内置的 /verify 技能，看看它是否对你的流程有帮助。
3. 用平实的语言把流程写下来，就像你在新同事入职第一天交给他们的那样。 
4. 把它交给 skill-creator，或者自己把 markdown 文件放进 .claude/skills/ 目录。
5. 在一个新任务上调用它，确认该检查会作为输出的一部分运行，必要时进行迭代。
6. 尝试使用技能链来创建端到端的验证流程。

> • Pick the manual follow-up you did most often this week.
> • Try out the built-in /verify skill first and see if it helps your process.
> • Write the procedure in plain English, the way you'd hand it to a new teammate on day one. 
> • Hand it to skill-creator, or drop the markdown file in .claude/skills/ yourself. 
> • Invoke it on a new task and confirm the check runs as part of the output, iterate if needed.
> • Experiment with skill chaining to create an end-to-end verification flow.

你能为 Claude 编码进去的内容越多，Claude 的回复就越经常在第一次尝试时就接近你想要的样子。那些你不再需要费心去调整的修正，如今把你的注意力解放出来，用于那些没有任何技能能替你写下来的、独属于你个人的工作。

> The more you can encode for Claude to follow, the more often Claude's response will land closer to what you want on the very first try. The corrections you no longer have to fiddle with now free up your attention for the individual and exclusive work that no skill can write down for you.

***开始在 ***[Claude Code](https://www.anthropic.com/product/claude-code) 中使用验证循环。

> ***Get started with verification loops in ***[Claude Code](https://www.anthropic.com/product/claude-code).

*本文由 Claude Code 团队成员 Delba de Oliveira 撰写。*

> *This article was written by Delba de Oliveira, a member of the Claude Code team. *

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| agentic coding | 代理式编程 | 由 AI 智能体自主收集上下文、执行操作并验证结果的编程工作方式。 |
| verification loop | 验证循环 | 智能体运行检查、修复失败项并再次检查的重复性自查周期。 |
| skill | 技能 | 以 markdown 文件描述的可复用指令单元，供 Claude 在会话中调用。 |
| linter | 代码检查工具 | 静态扫描源码以发现风格问题与潜在缺陷的工具。 |
| type checker | 类型检查器 | 在不运行程序的前提下校验类型一致性的工具。 |
| frontmatter | 前置元数据 | 位于 markdown 文件开头、用于声明名称与描述等字段的结构化区块。 |
| SKILL.md | 技能定义文件 | 承载单个技能的前置元数据与正文指令的 markdown 文件。 |
| CLAUDE.md | 项目说明文件 | 放在仓库中向 Claude 提供构建、测试命令等项目约定的文件。 |
| Code Review | 代码审查（服务） | 对已启用仓库的 PR 运行自动化审查的托管多智能体服务。 |
| GitHub Actions | GitHub Actions | GitHub 的持续集成服务，可在 push 或 PR 时触发预定义 job。 |
| PR (pull request) | 拉取请求 | 请求把一个分支的改动合并进目标分支的协作提案。 |
| rubric | 评分标准 | 供独立评分智能体据以判定结果是否通过的评判准则。 |
| chaining | 链式调用 | 让一个技能在结束时调用下一个技能，从而端到端串联多道交接。 |
| plugin | 插件 | 可安装并随更新覆盖自身内容的扩展包，例如 skill-creator。 |
| token | 词元 | 语言模型处理文本的最小计量单位，直接对应上下文与调用开销。 |
