---
source: claude-blog
source_url: https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
published_at: 2026-06-18
category: Claude Code
title_en: Steering Claude Code: CLAUDE.md files, skills, hooks, rules, subagents and more
title_zh: 驾驭 Claude Code：CLAUDE.md 文件、技能、钩子、规则、子智能体及其他
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 4
source_image_count: 1
---

# 驾驭 Claude Code：CLAUDE.md 文件、技能、钩子、规则、子智能体及其他

> 🌏︎ • Steering Claude Code: CLAUDE.md files, skills, hooks, rules, subagents and more

> • 来源：Claude Blog，2026-06-18
> • 原文链接：https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
> • 分类：Claude Code

## 核心要点

- Claude Code 提供七种指令 Claude 行为的方式：CLAUDE.md 文件、规则、技能、子智能体、钩子、输出样式以及追加系统提示词。
- 每种方式在三个维度上有所不同：指令何时加载进上下文、是否能在长会话压缩后保留、以及携带多大的指令权威。
- CLAUDE.md 是项目根目录下的 markdown 文件，在会话开始时加载并全程驻留，适合放构建命令、目录结构、编码规范和团队约定。
- CLAUDE.md 有两种类型：根目录文件始终加载且压缩后会重读；子目录文件按需加载，行为与路径限定规则一致。
- 在共享仓库里 CLAUDE.md 容易无序膨胀，应控制在 200 行以内、指定负责人、像审查代码一样审查它，并把团队专属约定下沉到路径限定规则、把流程下沉到技能。
- 在 monorepo 中可给每个团队目录配各自的子目录 CLAUDE.md，并用 `claudeMdExcludes` 跳过无关文件；组织级标准可通过 MDM 集中部署一份无法被排除的 CLAUDE.md。

## 正文

Claude 被打造成按你的工作方式来工作，而在 Claude Code 中，你可以对它进行定制。

> 🌏︎ Claude is built to work the way you work, and in Claude Code you can customize it.

Claude 的设计宗旨是契合你的工作方式，而在 Claude Code 中你还可以对它进行定制。

> 🌏︎ Claude is built to work the way you work, and in Claude Code you can customize it.

有七种方法可以指导 Claude 的行为：CLAUDE.md 文件、规则（rules）、技能（skills）、子代理（subagents）、钩子（hooks）、输出样式（output styles），以及追加系统提示词（system prompt）。

> 🌏︎ There are seven methods for instructing Claude's behavior: CLAUDE.md files, rules, skills , subagents , hooks , output styles, and appending the system prompt.

每种方法控制：

> 🌏︎ Each method controls:

- 指令何时加载进上下文；
- 它是否能在长会话中持续存在（压缩行为）；以及
- 它携带多大的权威性。

> 🌏︎ • When an instruction loads into context;

> • Whether it persists through long sessions (compaction behavior); and

> • How much authority it carries.

下表简要汇总了各方法之间的关键差异，文中还会提供更多细节，以及用于判断每条 Claude 指令应归属何处的决策框架。

> 🌏︎ The table below provides a quick summary of key differences across each method while the post provides additional detail and decision framework for determining where each of your Claude instructions belongs.

### 交付指令的七种方法

> The seven methods for delivering instructions

#### CLAUDE.md 文件

> CLAUDE.md files

CLAUDE.md 是位于项目根目录的 markdown 文件。它在会话开始时加载进上下文，并在整个会话期间保留。

> 🌏︎ CLAUDE.md is a markdown file at the root of your project. It loads into context at session start and stays there for the entire session.

构建命令、目录布局、单体仓库（monorepo）结构、编码规范以及团队约定都很自然地适合放在这里。

> 🌏︎ Build commands, directory layout, monorepo structure, coding conventions, and team norms all fit naturally here.

它有两种类型，加载方式不同：

> 🌏︎ There are two types, and they load differently:

- 始终加载：第一种是根目录的 CLAUDE.md 文件，既可以放在共享仓库中，也可以本地保存用于你针对某个项目的个人偏好。所有这些文件都在会话开始时加载，不会在长会话中丢失或退化。当 Claude Code 压缩对话时，会重新读取这些文件。
- 按需加载：位于你初始化会话所在文件夹之下的子目录中的 CLAUDE.md 文件。例如，app/api/CLAUDE.md 会在 Claude 读取 app/api 下的某个文件时加载，而不是在会话开始时加载。它和路径范围（path-scoped）规则的压缩行为一致：在该子目录再次被触及之前都不存在。

> 🌏︎ • Always loaded : The first type is a root CLAUDE.md file, either in a shared repository and/or saved locally for your personal preferences specific to a project. All these files load at session start, and won’t get lost or degraded across long sessions. When Claude Code compacts the conversation, it re-reads these files.

> • On-demand: CLAUDE.md files in subdirectories below the folder where you initialized the session. For example, app/api/CLAUDE.md loads when Claude reads a file under app/api , not at session start. It shares the compaction behavior of path-scoped rules: gone until that subdirectory is touched again.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a340f852d1f938ab8675599_65a737a9.png)

在共享仓库中，CLAUDE.md 会像任何无人负责的配置文件一样不断膨胀：每个团队都追加自己的指令，却没有任何内容被删除。这种成本在规模化时会复合叠加。

> 🌏︎ In a shared repository, CLAUDE.md grows the way any unowned config file does: every team appends its own instructions and nothing gets deleted. The cost compounds at scale.

每一行都会加载进每位在该仓库工作的工程师的每个会话，无论它是否与其任务相关。这会消耗 token，并稀释对真正重要指令的遵循度。随着文件不断变大，应把团队特定的约定移入路径范围规则，把流程移入技能（skill），让它们只在相关时加载。

> 🌏︎ Every line loads into every session for every engineer working in the repo, whether it's relevant to their task or not. This consumes tokens and dilutes adherence to the instructions that actually matter. As the file grows, push team-specific conventions into path-scoped rules and procedures into skills, where they load only when relevant.

提示：把 CLAUDE.md 保持在 200 行以内，为它指定一位负责人，并像审查代码一样审查对它的改动。可以把这个文件视为给 Claude 提供你代码库的概览，或视为一个索引，指向 Claude 在需要时可以查找更多信息的其他文件。

> 🌏︎ Tip: Keep CLAUDE.md under 200 lines, give it an owner, and review changes to it like code. Think of this file as giving Claude an overview of your codebase, or as an index pointing to other files where Claude can find more information as needed.

在单体仓库中，给每个团队的目录配一个自己的子目录 CLAUDE.md，让团队只加载自己的约定；开发者还可以使用 claudeMdExcludes 设置，跳过那些他们从不涉及的团队的代码文件。

> 🌏︎ In monorepos, give each team's directory its own subdirectory CLAUDE.md so teams only load their own conventions, and developers can use the claudeMdExcludes setting to skip files from teams whose code they never touch.

对于必须适用于组织内每个仓库的标准——安全策略、合规要求——可以通过移动设备管理（MDM）或配置管理把集中管理的 CLAUDE.md 部署到开发者机器上，且它无法被个人设置排除。

> 🌏︎ For standards that must apply to every repository in the organization — security policies, compliance requirements — a centrally managed CLAUDE.md can be deployed to developer machines via MDM or config management, and it can't be excluded by individual settings.

关于设置 CLAUDE.md 的更多内容，参见我们的博客文章《CLAUDE.md files: Customizing Claude Code for your codebase》。

> 🌏︎ More on setting up CLAUDE.md in our blog post, CLAUDE.md files: Customizing Claude Code for your codebase .

## 术语对照

| English | 中文 |
|---|---|
| CLAUDE.md files | CLAUDE.md 文件 |
| rules | 规则 |
| skills | 技能 |
| subagents | 子智能体 |
| hooks | 钩子 |
| output styles | 输出样式 |
| appending the system prompt | 追加系统提示词 |
| compaction behavior | 压缩行为 |
| context | 上下文 |
| session | 会话 |
| build commands | 构建命令 |
| directory layout | 目录结构 |
| monorepo | monorepo |
| coding conventions | 编码规范 |
| path-scoped rules | 路径限定规则 |
| token | token |
| MDM | MDM（移动设备管理） |
| config management | 配置管理 |
