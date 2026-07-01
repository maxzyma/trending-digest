---
source: claude-blog
source_url: https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
published_at: 2026-06-18
category: Claude Code
title_en: Steering Claude Code: CLAUDE.md files, skills, hooks, rules, subagents and more
title_zh: 驾驭 Claude Code：CLAUDE.md 文件、技能、钩子、规则、子智能体等
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 4
source_image_count: 4
---

# 驾驭 Claude Code：CLAUDE.md 文件、技能、钩子、规则、子智能体等

> Steering Claude Code: CLAUDE.md files, skills, hooks, rules, subagents and more

> 来源：Claude Blog，2026-06-18
> 原文链接：https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
> 分类：Claude Code

## 核心要点

- Claude Code 提供七种向 Claude 下达指令的方式：CLAUDE.md 文件、规则、技能、子智能体、钩子、输出风格，以及追加系统提示词。
- 每种方式在三个维度上各有差异：指令何时载入上下文、能否在长会话压缩后保留、以及携带多大的约束权威。
- CLAUDE.md 位于项目根目录，会话开始即载入并全程保留，适合放构建命令、目录结构、编码约定与团队规范；建议控制在 200 行以内并设专人维护。
- 规则存放于 .claude/rules/，可通过 paths 字段做路径限定，只在 Claude 读取相关目录文件时才载入，避免无关上下文浪费 token。
- 技能以文件夹形式存放于 .claude/skills/，会话开始只载入名称和描述，调用时才载入完整正文，适合部署流程、发布清单等流程化指令。
- 子智能体存放于 .claude/agents/，为特定旁支任务定义隔离的助手，通过 Agent 工具按需调用，正文不会自动触发。
- 在共享仓库与单一大仓中，应将团队专属约定下沉为路径限定规则、把流程归入技能，并可借助 claudeMdExcludes 设置跳过无关团队的文件。

## 正文

Claude 旨在贴合你的工作方式而打造，在 Claude Code 中你可以对它进行定制。

> Claude is built to work the way you work, and in Claude Code you can customize it.

有七种方法可以指示 Claude 的行为：CLAUDE.md 文件、规则（rules）、技能（skills）、子代理（subagents）、钩子（hooks）、输出样式（output styles），以及追加系统提示词（system prompt）。

> There are seven methods for instructing Claude's behavior: CLAUDE.md files, rules, skills , subagents , hooks , output styles, and appending the system prompt.

每种方法控制：

> Each method controls:

- 指令何时载入上下文；
- 它是否在长会话中持续存在（压缩行为）；以及
- 它具有多大的权威性。

> • When an instruction loads into context;
> • Whether it persists through long sessions (compaction behavior); and
> • How much authority it carries.
下表简要总结了各方法之间的关键差异，而本文则提供了更多细节，以及用于判断每条 Claude 指令该归属何处的决策框架。

> The table below provides a quick summary of key differences across each method while the post provides additional detail and decision framework for determining where each of your Claude instructions belongs.

### 七种下达指令的方法

> The seven methods for delivering instructions

#### CLAUDE.md 文件

> CLAUDE.md files

CLAUDE.md 是位于项目根目录的 markdown 文件。它在会话开始时载入上下文，并在整个会话期间保持存在。

> CLAUDE.md is a markdown file at the root of your project. It loads into context at session start and stays there for the entire session.

构建命令、目录布局、单一仓库（monorepo）结构、编码规范以及团队约定都很适合放在这里。

> Build commands, directory layout, monorepo structure, coding conventions, and team norms all fit naturally here.

它有两种类型，载入方式不同：

> There are two types, and they load differently:

- 始终载入：第一种是根目录的 CLAUDE.md 文件，既可以放在共享仓库中，也可以在本地保存，用于你针对某个项目的个人偏好。所有这些文件都在会话开始时载入，且不会在长会话中丢失或退化。当 Claude Code 压缩对话时，会重新读取这些文件。
- 按需载入：位于你初始化会话的文件夹之下的子目录中的 CLAUDE.md 文件。例如，app/api/CLAUDE.md 会在 Claude 读取 app/api 下的文件时载入，而非在会话开始时载入。它的压缩行为与路径限定规则（path-scoped rules）相同：在再次触及该子目录之前会一直消失。

> • Always loaded : The first type is a root CLAUDE.md file, either in a shared repository and/or saved locally for your personal preferences specific to a project. All these files load at session start, and won’t get lost or degraded across long sessions. When Claude Code compacts the conversation, it re-reads these files.
> • On-demand: CLAUDE.md files in subdirectories below the folder where you initialized the session. For example, app/api/CLAUDE.md loads when Claude reads a file under app/api , not at session start. It shares the compaction behavior of path-scoped rules: gone until that subdirectory is touched again.
![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a340f852d1f938ab8675599_65a737a9.png)

在共享仓库中，CLAUDE.md 会像任何无人专属的配置文件那样不断膨胀：每个团队都追加自己的指令，却没有任何内容被删除。这种成本在规模化时会层层累加。

> In a shared repository, CLAUDE.md grows the way any unowned config file does: every team appends its own instructions and nothing gets deleted. The cost compounds at scale.

无论是否与某位工程师的任务相关，每一行都会载入仓库中每位工程师的每个会话。这会消耗 token，并稀释对真正重要指令的遵循。随着文件增长，应把团队专属约定移入路径限定规则，把流程移入技能（skills），让它们只在相关时载入。

> Every line loads into every session for every engineer working in the repo, whether it's relevant to their task or not. This consumes tokens and dilutes adherence to the instructions that actually matter. As the file grows, push team-specific conventions into path-scoped rules and procedures into skills, where they load only when relevant.

提示：将 CLAUDE.md 控制在 200 行以内，为它指定一名负责人，并像审查代码那样审查对它的改动。可以把这个文件理解为给 Claude 提供代码库的概览，或作为指向其他文件的索引，让 Claude 在需要时去那里查找更多信息。

> Tip: Keep CLAUDE.md under 200 lines, give it an owner, and review changes to it like code. Think of this file as giving Claude an overview of your codebase, or as an index pointing to other files where Claude can find more information as needed.

在单一仓库中，给每个团队的目录配上各自的子目录 CLAUDE.md，这样团队只会载入自己的约定；开发者还可以用 claudeMdExcludes 设置跳过那些自己从不接触的团队代码所对应的文件。

> In monorepos, give each team's directory its own subdirectory CLAUDE.md so teams only load their own conventions, and developers can use the claudeMdExcludes setting to skip files from teams whose code they never touch.

对于必须适用于组织内每个仓库的标准——安全策略、合规要求——可以通过 MDM 或配置管理把集中管理的 CLAUDE.md 部署到开发者机器上，且它无法被个人设置排除。

> For standards that must apply to every repository in the organization — security policies, compliance requirements — a centrally managed CLAUDE.md can be deployed to developer machines via MDM or config management, and it can't be excluded by individual settings.

关于设置 CLAUDE.md 的更多内容，参见我们的博客文章《CLAUDE.md 文件：为你的代码库定制 Claude Code》。

> More on setting up CLAUDE.md in our blog post, CLAUDE.md files: Customizing Claude Code for your codebase .

#### 规则

> Rules

规则是位于 .claude/rules/ 中的 markdown 文件，用于给 Claude 提供具体的约束或约定。

> Rules are markdown files in .claude/rules/ that give Claude specific constraints or conventions.

未限定范围的规则行为类似 CLAUDE.md，即始终在会话开始时载入，并在压缩时重新注入。这可能会浪费 token，因为即便与当前任务无关也会载入上下文。

> Unscoped rules behave like CLAUDE.md in that they are always loaded at session start and get re-injected on compaction. This can waste tokens by loading context even when it's not relevant for the task at hand.

路径限定规则允许你通过添加一个 paths 字段来控制规则指令的载入时机，从而只在相关时载入。

> Path-scoped rules allow you to load rule instructions only when they are relevant by adding a paths field that controls when they load.

例如：一条限定到 src/api/** 的规则，在仅涉及文档的会话中不会进入上下文。它只会在 Claude 读取 src/api/ 目录内的文件时载入。

> For example: a rule scoped to src/api/** stays out of context during a docs-only session. It would only be loaded whenever Claude reads files within that src/api/ directory.

它看起来是这样的：

> Here’s what that looks like:

```text
--- paths: - "src/api/**" - "**/*.handler.ts" --- 所有 API 处理程序在处理前都必须用 Zod 校验输入。
```

> ```text
> --- paths: - "src/api/**" - "**/*.handler.ts" --- All API handlers must validate input with Zod before processing.
> ```

提示：像“迁移文件只可追加”这样针对特定文件的约束，最适合作为一条规则放进 paths: frontmatter 中。当指令涉及横切关注点，或涉及在代码库多个（但非全部）角落出现的文件时，应选择路径限定规则，而非嵌套的 CLAUDE.md 文件。

> Tip : A file-specific constraint, like "migrations are append-only," fits best as a rule placed in your paths: frontmatter. Reach for a path scoped rule over a nested CLAUDE.md file when the instruction regards a cross-cutting concern or file that appears in multiple (but not all) corners of the codebase.

#### 技能

> Skills

技能位于 .claude/skills/，是由指令、脚本和资源组成的文件夹，供 Claude 动态载入。每个技能都有一个 SKILL.md 文件，包含名称、描述和正文。

> Skills live in .claude/skills/ as folders of instructions, scripts, and resources that Claude loads dynamically. Each skill has a SKILL.md file with a name, description, and body.

会话开始时只载入名称和描述；当 Claude 调用该技能时才载入完整正文，调用方式可以是斜杠命令（/code-review），也可以通过任务自动匹配。

> Only the name and description load at session start; the full body loads when Claude invokes the skill, either through a slash command (/code-review) or by auto-matching the task.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a340f852d1f938ab867559f_2199ed03.png)

例如，/code-review 是一个内置技能，它会审查你当前的 diff 并报告发现的问题，而不修改文件。该技能定义了操作手册，因此每次你调用它时，Claude 都会遵循同样的结构化方法。

> For example, /code-review is a built-in skill that reviews your current diff and reports its findings without editing files. The skill defines the playbook so Claude follows the same structured approach every time you invoke it.

在压缩时，Claude Code 会重新注入已调用过的技能，但所有已调用技能合计有一个总预算上限。如果你在一次会话中调用了许多技能，最旧的会最先被丢弃。

> On compaction, Claude Code re-injects invoked skills up to a total budget across all invoked skills. If you’ve invoked many skills during a session, the oldest ones drop first.

提示：流程性的指令，例如部署工作流、发布检查清单或审查流程，应放进技能而非 CLAUDE.md。

> Tip: Instructions that are procedural, like deploy workflows, release checklists, or review processes, belong in a skill rather than in CLAUDE.md.

Claude Code 自带了一些技能，但你也可以编写自己的自定义技能。我们的《构建 Claude 技能完整指南》会向你展示具体做法。

> Claude Code ships with skills, but you can also write your own custom skills. Our complete guide to building skills for Claude shows you how.

#### 子代理

> Subagents

子代理是位于 .claude/agents/ 中的 markdown 文件，用于为特定的旁支任务定义相互隔离的助手。每个文件使用 YAML frontmatter（name、description，以及可选的 model 和工具访问权限字段），后接一段作为该子代理系统提示词的正文。

> Subagents are markdown files in .claude/agents/ that define isolated assistants for specific side tasks. Each file uses YAML frontmatter (name, description, plus optional fields for model and tool access) followed by a body that becomes that subagent's system prompt.

子代理与技能类似，其名称、描述和工具列表在会话开始时载入，但代理正文中更大块的上下文不会自动调用。Claude 通过 Agent 工具调用它们，并传入一个提示词字符串。

> Subagents are similar to skills in that the name, description, and tool list load at session start, but the larger context within the body of the agent doesn’t auto-invoke. Claude calls them via the Agent tool, passing in a prompt string.

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a340f852d1f938ab86755a2_914c1942.png)

主体中更大的指令上下文不仅不会被自动调用，它根本就不会进入父级对话。

> Not only does the larger instructional context within the body of the subagent not auto-invoke, it never enters the parent conversation at all.

随后子代理（subagent）在自己全新的上下文窗口中运行，唯一返回到主会话的只有子代理的最终消息（通常是众多子任务的汇总结果）以及元数据。

> The subagent then runs in its own fresh context window, and the only thing that returns to your main session is the subagent’s final message (often the aggregated result of many subtasks) plus metadata.

这种模式可以扩展：子代理最多可嵌套五层，动态工作流可编排数十到数百个后台代理，而无需你为子代理架构指定每一个细节。编排计划和中间结果存放在脚本变量中，而非 Claude 的上下文窗口中，从而在不损失指令保真度的前提下实现规模化。

> This pattern scales: subagents can nest up to five levels deep, and dynamic workflows orchestrate tens to hundreds of background agents without requiring you to specify each detail of the subagent architecture. The orchestration plan and intermediate results live in script variables rather than in Claude’s context window, which enables scale without losing instructional fidelity.

提示：这种隔离正是选择子代理而非技能（skill）的主要原因之一。当深度搜索、日志分析或依赖审计等附带任务会用你不会再引用的中间结果塞满主对话时，使用子代理。当你希望流程在主线程内逐步展开、以便你能看到并引导每一步时，使用技能。

> Tip: That isolation is one of the main reasons to reach for a subagent instead of a skill. Use a subagent when a side task like deep search, a log analysis pass, or a dependency audit would clutter your main conversation with intermediate results you won't reference again. Use a skill when you want the procedure to play out inside the main thread so you can see and steer each step.

#### 钩子

> Hooks

钩子（hook）是用户定义的命令、HTTP 端点或大语言模型提示词，它们在 Claude 生命周期中的特定事件（如文件编辑、工具调用或会话启动）上触发，从而对 Claude 的行为提供更确定性的控制。

> Hooks are user-defined commands, HTTP endpoints, or LLM prompts that provide more deterministic control over Claude’s behavior by firing on specific events in Claude’s lifecycle like file edits, tool calls, or session start.

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a340f852d1f938ab867559c_e782277c.png)

你可以在 settings.json、受管策略设置或技能/代理的前置元数据（frontmatter）中注册钩子。

> You register hooks in settings.json , managed policy settings, or skill/agent frontmatter.

钩子有几种类型：command、HTTP、mcp_tool、prompt 和 agent。所有钩子都是确定性触发的。前三种确定性地执行，而后两种 prompt 和 agent 则使用 Claude 的判断而非一套规则来决定输出。

> There are several types of hooks: command, HTTP, mcp_tool, prompt, and agent. All hooks are deterministically triggered. The first three execute deterministically while the latter two, prompt and agent, use Claude’s judgment rather than a set of rules to determine the output.

钩子的上下文开销很低，因为其配置或指令存放在主上下文窗口之外。根据钩子类型，框架（harness）会运行处理程序（command、http、mcp_tool）或以独立窗口发起模型调用（prompt、agent）。

> Hooks have low context costs because the configuration or instruction lives outside the main context window. The harness runs the handler (command, http, mcp_tool) or makes model calls with separate windows (prompt, agent) depending on the hook type.

有些钩子的输出可能会被保存到主上下文窗口。例如，阻断型钩子的标准错误会被保存到上下文中，以便 Claude 知道该调用为何被拒绝。

> Some hooks may have the output saved to the main context window. For example, a blocking hook's standard error is saved within context so Claude knows why the call was denied.

但大多数钩子的输出不会被保存到主窗口，除非配置中明确返回它。如果你在压缩（compaction）前使用 PreCompact 事件把聊天记录备份到另一个文件以供日后参考，Claude 并不会知道哪个文件保存了聊天记录。

> But most hooks won’t have the output saved to the main window unless the configuration explicitly returns it. If you backed up your chat history into another file for later reference before compaction using the PreCompact event, Claude wouldn’t know which file had the chat history saved.

这使得这些钩子类型与 CLAUDE.md、规则（rules）和技能有根本性的不同。你可以在我们的文章《如何配置钩子》中了解更多。

> This makes these hook types fundamentally different from CLAUDE.md, rules, and skills. You can learn more in our post how to configure hooks .

提示：对任何应当确定性发生的事情使用钩子：在编辑后运行 linter、完成时发送到 Slack，或在特定命令执行前将其阻断。PreToolUse 钩子可以检查任何工具调用，并以退出码 2 拒绝它。

> Tip: Use hooks for anything that should happen deterministically: running linters after edits, posting to Slack on completion, or blocking specific commands before they execute. A PreToolUse hook can inspect any tool call and exit code 2 to deny it.

它们的上下文开销很低，因为它们是框架运行的代码，而非加载进上下文、交给 Claude 的指令。

> They have low context cost because they are code that the harness runs rather than instructions to Claude that get loaded into context.

#### 输出风格

> Output styles

输出风格（output style）是位于 .claude/output-styles/ 中的文件，它们会将指令注入系统提示词。它们永远不会被压缩，在每次会话开始时加载，并在一次会话内的首次请求后被缓存，这意味着它们有中等的上下文开销。

> Output styles are files in .claude/output-styles/ that inject instructions into the system prompt. They never get compacted, load at the start of every session, and are cached after the first request within a session, meaning they have a moderate context cost.

由于它们位于系统提示词中，输出风格在我们目前所介绍的所有方法中拥有最高的指令遵循权重，应谨慎使用。

> Because they sit in the system prompt, output styles carry the highest instruction-following weight of any method that we've covered so far and should be used judiciously.

对输出风格的更改将替换默认输出风格（除非你在该风格的前置元数据中设置 keep-coding-instructions: true）。

> Changes to the output style will replace the default output style (unless you set keep-coding-instructions: true in the style's frontmatter).

在 Claude Code 中，这会移除那些告诉 Claude 它正在帮助用户完成软件工程任务的指令，以及其他关键的默认指令，例如：

> In Claude Code, this would remove instructions that tell Claude it is helping users with software engineering tasks and contains other critical default instructions such as:

- 如何界定更改范围；
- 何时添加或省略代码注释；
- 如何处理安全问题；以及
- 诸如在宣布工作完成前运行测试之类的验证习惯。

> • How to scope changes;
> • When to add or omit code comments;
> • What to do about security concerns; and
> • Verification habits like running tests before declaring work complete.
默认情况下，自定义输出风格会丢弃所有这些内容，Claude Code 会更像一个通用助手，而非软件工程师助手。

> By default, a custom output style drops all of this and Claude Code becomes more of a general assistant than a software engineer assistant.

提示：在编写自定义输出风格之前，先查看内置风格。Proactive（主动）、Explanatory（讲解）和 Learning（学习）涵盖了最常见的需求（自主性、教学模式、协作编码），无需你维护一个风格文件。

> Tip : Before writing a custom output style, check the built-in styles. Proactive , Explanatory , and Learning cover the most common needs (autonomy, teaching mode, collaborative coding) without you having to maintain a style file.

#### 追加系统提示词

> Appending the system prompt

修改输出风格的一个替代方案是 append-system-prompt 标志。修改输出风格文件可能对 Claude 的行为造成巨大、意外的更改，而追加标志只是对原始系统提示词的增补。它不改变 Claude 的角色，只是为其默认角色添加指令。

> An alternative to modifying output styles is the append-system-prompt flag. Whereas modifying output style files can have large, unintended changes to Claude’s behavior, the append flag is only additive to the original system prompt. It doesn’t modify Claude’s role; it just adds instructions to its default role.

它还在调用时传入，且仅对该次调用生效，而不会作为文件跨会话持久保存。

> It is also passed at invocation time, and only applies to that invocation, rather than persisted as a file across sessions.

与其他传递指令的方法相比，追加系统提示词可能有更高的上下文开销。它会增加输入 token，不过提示词缓存会在一次会话的首次请求后降低这一开销。指示 Claude 使用更冗长或更长的风格也会增加输出 token。

> Appending the system prompt can have a higher context cost compared to other methods of passing instructions. It increases input tokens, though prompt caching reduces this cost after the first request in a session. Instructing Claude to use a more verbose or longer style also increases output tokens.

提示：追加系统提示词最适合用于添加特定的编码规范、输出格式或领域专属知识。请记住，追加系统提示词对遵循度的提升存在边际递减效应。一般来说，用这种方法提供的指令越多，Claude 遵循得就越不严格，尤其是当其中存在相互矛盾之处时。

> Tip: Appending the system prompt is best for adding specific coding standards, output formatting, or domain-specific knowledge. Keep in mind that appending the system prompt has diminishing returns for adherence. Generally, the more instructions you provide using this method, the less strictly Claude will follow them, particularly if any contradict.

### Claude Code 定制的快速技巧

> Quick tips for Claude Code customization

如果你发现自己在做下面某件事，或许应该考虑把指令放到其他位置：

> If you find yourself doing one of the following, you may want to consider an alternative location for your instructions:

在 CLAUDE.md 里写"每次 X，总是做 Y"。如果某个行为应当可靠发生，比如每次编辑后运行 prettier，或完成时发到 Slack，那就改用 settings.json 里的钩子（hook）。模型选择去运行格式化工具，和格式化工具自动运行是两回事。

> "Every time X, always do Y" in CLAUDE.md. If the behavior should happen reliably, like running prettier after every edit or posting to Slack on completion, use a hook in settings.json instead. The model choosing to run a formatter is different from the formatter running automatically.

在 CLAUDE.md 里写"永远不要做这个"。当某件事绝对不能发生时，指令是错误的工具。Claude 大多数时候会遵守指令，但在有压力时、在漫长的会话中、在含糊的情境下，或由于任务中访问的某个文件里存在提示注入（prompt injection），模型可能无法遵守一条以提示形式给出的规则。真正的护栏需要是确定性的，而强制手段是钩子（hooks）和权限（permissions）。PreToolUse 钩子可以检查一次调用，并以退出码 2 来阻止它。受管设置（managed settings）更进一步：它们由管理员部署，无法被用户的本地配置覆盖，是强制实施确定性、组织级护栏的唯一方式。

> “Never do this” in CLAUDE.md . When there's something that absolutely must not happen, an instruction is the wrong tool. Claude will follow the instruction most of the time, but when under pressure, in a long session or an ambiguous situation, or due to a prompt injection in a file accessed as part of the task, the model can fail to follow a prompted rule. A real guardrail needs to be deterministic, and the enforcement methods are hooks and permissions . A PreToolUse hook can inspect a call and exit with code 2 to block it. Managed settings go further: they are admin-deployed, cannot be overridden by a user's local config, and are the only way to enforce a deterministic, organization-wide guardrail.

在 CLAUDE.md 里写一段 30 行的流程。流程属于技能（skills）。CLAUDE.md 适合放 Claude 应当始终掌握的事实：构建命令、单仓库（monorepo）布局、团队约定。一份部署操作手册或一份安全审查清单应当放在 .claude/skills/，其正文只在被调用时才加载。

> A 30-line procedure in CLAUDE.md. Procedures belong in skills. CLAUDE.md is for facts Claude should hold all the time: build commands, monorepo layout, team conventions. A deployment runbook or a security review checklist should live in .claude/skills/ , where the body loads only when invoked.

写一条针对特定 API、却没有路径的规则。如果某条规则只适用于 src/api/**，用 paths: 限定它的作用范围，就能在无关工作期间把它排除在上下文之外。一条未限定范围的规则在机制上等同于把内容放进 CLAUDE.md：始终加载，始终消耗 token。

> An API-specific rule without paths. If a rule only applies to src/api/** , scoping it with paths: keeps it out of context during unrelated work. An unscoped rule is mechanically identical to putting the content in CLAUDE.md: always loaded, always costing tokens.

把个人偏好写进项目级的 CLAUDE.md 文件。所有基于文件的方法都有一个用户级的对应版本，它会为每一次 Claude Code 会话加载，无论你身处哪个仓库。把本地文件用于个人偏好（总是使用语义化的提交信息）。把项目级文件留给团队通用、但特定于某个代码库的偏好。

> Writing personal preferences to a project-level CLAUDE.md file. All file-based methods have a user-level counterpart loaded for every Claude Code session regardless of which repo you’re in. Use local files for personal preferences (always use semantic commit messages). Keep project-level files for preferences that are team-wide but specific to a given codebase.

### 开始使用

> Getting started

关于如何充分发挥 Claude Code 的能力，从配置环境到跨并行会话扩展，你可以在我们的 Claude Code 最佳实践文档中找到更多技巧和模式。

> You can find more tips and patterns for getting the most out of Claude Code, from configuring your environment to scaling across parallel sessions, in our best practices for Claude Code documentation.

当你让其中几项运转起来后，可以把许多功能（技能、子代理、钩子、输出风格）打包成一个插件（plugin），从而在团队成员或项目之间共享一套连贯的配置。

> Once you have a few of these working, you can bundle many of them (skills, subagents, hooks, output styles) as a plugin to share a coherent setup across teammates or projects.

## 术语对照

| English | 中文 |
|---|---|
| Claude Code | Claude Code |
| CLAUDE.md file | CLAUDE.md 文件 |
| rules | 规则 |
| skills | 技能 |
| subagents | 子智能体 |
| hooks | 钩子 |
| output styles | 输出风格 |
| system prompt | 系统提示词 |
| context | 上下文 |
| compaction | 上下文压缩 |
| path-scoped rules | 路径限定规则 |
| slash command | 斜杠命令 |
| monorepo | 单一大仓 |
| frontmatter | 前置元数据 |
