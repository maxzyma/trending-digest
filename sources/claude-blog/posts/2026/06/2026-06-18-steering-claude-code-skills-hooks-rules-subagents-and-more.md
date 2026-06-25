---
source: claude-blog
source_url: https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
published_at: 2026-06-18
category: Claude Code
title_en: Steering Claude Code: CLAUDE.md files, skills, hooks, rules, subagents and more
title_zh: 驾驭 Claude Code：CLAUDE.md 文件、技能、钩子、规则、子智能体及其他
source_intro_paragraphs: 4
source_image_count: 1
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/Obva6QBXJw9lDLgYuMnee592Wn4qY5Pr"
---

# 驾驭 Claude Code：CLAUDE.md 文件、技能、钩子、规则、子智能体及其他

> 来源：Claude Blog，2026-06-18
> 原文链接：https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
> 分类：Claude Code

## 导语

Claude 被打造成按你的工作方式来工作，而在 Claude Code 中，你可以对它进行定制。

## 核心要点

- Claude Code 提供七种指令 Claude 行为的方式：CLAUDE.md 文件、规则、技能、子智能体、钩子、输出样式以及追加系统提示词。
- 每种方式在三个维度上有所不同：指令何时加载进上下文、是否能在长会话压缩后保留、以及携带多大的指令权威。
- CLAUDE.md 是项目根目录下的 markdown 文件，在会话开始时加载并全程驻留，适合放构建命令、目录结构、编码规范和团队约定。
- CLAUDE.md 有两种类型：根目录文件始终加载且压缩后会重读；子目录文件按需加载，行为与路径限定规则一致。
- 在共享仓库里 CLAUDE.md 容易无序膨胀，应控制在 200 行以内、指定负责人、像审查代码一样审查它，并把团队专属约定下沉到路径限定规则、把流程下沉到技能。
- 在 monorepo 中可给每个团队目录配各自的子目录 CLAUDE.md，并用 `claudeMdExcludes` 跳过无关文件；组织级标准可通过 MDM 集中部署一份无法被排除的 CLAUDE.md。

## 中文译文

Claude 被打造成按你的工作方式来工作，而在 Claude Code 中，你可以对它进行定制。

有七种指令 Claude 行为的方式：CLAUDE.md 文件、规则（rules）、技能（skills）、子智能体（subagents）、钩子（hooks）、输出样式（output styles），以及追加系统提示词（appending the system prompt）。

每种方式控制：

- 指令何时加载进上下文；

- 它是否能在长会话中保留（压缩行为，compaction behavior）；以及

- 它携带多大的指令权威。

下面的表格对每种方式的关键差异作了快速概述，而本文则提供了更多细节，并给出一套决策框架，帮你判断你的每条 Claude 指令应当放在哪里。

### 传递指令的七种方式

#### CLAUDE.md 文件

CLAUDE.md 是项目根目录下的一个 markdown 文件。它在会话开始时加载进上下文，并在整个会话期间驻留。

构建命令、目录结构、monorepo 布局、编码规范和团队约定，都天然适合放在这里。

它有两种类型，加载方式不同：

- **始终加载**：第一种是根目录 CLAUDE.md 文件，可以放在共享仓库里，和／或本地保存针对某项目的个人偏好。所有这些文件都在会话开始时加载，且不会在长会话中丢失或退化。当 Claude Code 压缩对话时，会重新读取这些文件。

- **按需加载**：位于你初始化会话的目录下方的子目录中的 CLAUDE.md 文件。例如，`app/api/CLAUDE.md` 会在 Claude 读取 `app/api` 下的文件时加载，而非在会话开始时加载。它的压缩行为与路径限定规则相同：在再次触及该子目录之前都不存在。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a340f852d1f938ab8675599_65a737a9.png)

在共享仓库里，CLAUDE.md 会像任何无人负责的配置文件一样膨胀：每个团队都追加自己的指令，没有任何东西被删除。规模化后，成本会复合叠加。

每一行都会加载进每位在该仓库工作的工程师的每个会话，无论它是否与其任务相关。这会消耗 token，并稀释对那些真正重要指令的遵循度。随着文件增大，应把团队专属约定下沉到路径限定规则、把流程下沉到技能中，让它们只在相关时加载。

**提示**：把 CLAUDE.md 控制在 200 行以内，给它指定一个负责人，并像审查代码一样审查它的改动。把这个文件想象成给 Claude 提供你代码库的概览，或一个指向其他文件的索引——Claude 需要时可以从那些文件找到更多信息。

在 monorepo 中，给每个团队的目录配各自的子目录 CLAUDE.md，这样团队只加载自己的约定；开发者还可以用 `claudeMdExcludes` 设置跳过那些自己从不接触的团队的文件。

对于必须应用到组织内每个仓库的标准——安全策略、合规要求——可以通过 MDM 或配置管理把一份集中管理的 CLAUDE.md 部署到开发者机器上，且它无法被个人设置排除。

关于设置 CLAUDE.md 的更多内容，详见我们的博客文章《CLAUDE.md files: Customizing Claude Code for your codebase》。

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
