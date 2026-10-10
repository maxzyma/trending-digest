# 构建高效的智能体自动化

> Building effective agent automations

> 来源：Claude Blog / Anthropic，2026-10-08
> 原文链接：https://claude.dev/blog/building-effective-agent-automations/
> 分类：AI 工程 / 智能体自动化

## 核心要点

- 该参考实现由来源、目的地、智能体、调度、记忆和护栏六个组件构成，通过 ant apply 在 Claude API 工作区中创建资源，并在 Anthropic 基础设施上按计划运行，无需本地常驻程序。
- 凭据存放在 vault 中，真实值始终位于沙箱之外：MCP 工具经由沙箱外代理匹配凭据，Slack 请求则在离开沙箱时由平台将占位符替换为真实令牌。
- 智能体不按“过去 24 小时”这类固定时间窗口读取，而是为每个来源维护书签，记录上次读到的最新条目时间戳，使每次运行恰好覆盖自上次以来的全部内容。
- 当某个来源读取失败时，智能体保持该来源书签不动，用其他来源撰写简报，并在末尾注明未能读取的内容，避免把读取失败误报为“没有新内容”。
- 只有当 Slack 返回 "ok": true 及消息 ts 后才算发布成功并更新书签与台账；发帖前会检查当天简报是否已发布，结果不明确时标记为“可能已发布”且不做其他改动。
- 发布前智能体会重新检查每个条目的实时状态，且 agent.md 会引导输出保持简短。
- 部署负责指定智能体、环境、首条消息、调度、凭据库、记忆存储和预算，每次调度触发都会启动全新会话，并需显式指定时区以避免日期计算错误。
- 记忆分为两个存储：对智能体只读的 preferences 存放用户偏好，可读写的 state 存放书签、已报告内容台账、偏好修改建议和来源行为笔记；智能体每次运行都应重新读取偏好，读取失败则停止。
- 由于智能体会读取可能含有注入指令的外部文本，应将 GitHub 令牌和偏好存储设为只读、限制网络允许列表，并只把 Slack 机器人邀请到必要频道。
- 每次运行的支出上限建议先设为正常运行成本的三到五倍再逐步收紧，达到上限的运行会以 budget_reached 原因暂停而非失败。

## 正文

随着 AI 加快了我们的工作节奏，跟上进度变得越来越难。在 Anthropic，我们经常借助简单的智能体自动化来应对。它们通常按计划定时运行，在后台收集上下文，并主动告诉我们需要了解的信息。但要构建有效的智能体自动化并不容易：它们可能在无人察觉的情况下失去对某个信息源的访问权限，或者未能遵循我们的偏好。

> As AI accelerates our work, it's getting harder to keep up. At Anthropic, simple agent automations are frequently used to help. They often run on a schedule, gather context in the background, and proactively tell us what we need to know. But it’s difficult to build effective agent automations: they can lose access to a source without anyone noticing or fail to follow our preferences.

我们使用 [Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview)（beta）构建了一个参考实现：它按计划读取自定义信息源（例如 Slack 和 GitHub 仓库），追踪自上次运行以来发生的变化，并将你需要了解的内容发布出去（例如发布到 Slack）。在本文中，我们将逐步讲解每个环节，分享一个参考实现，并提供一条可在 Claude Code 中运行的命令，帮你自动完成该智能体的配置。

> Using [Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview) (beta), we built a reference implementation that reads custom sources (e.g., Slack and GitHub repos) on a schedule, tracks what changed since the last run, and posts what you need to know (e.g., to Slack). In this article, we walk through each step, share a reference implementation, and provide a command to run in Claude Code that configures the agent for you.

#### 获取代码

> GET THE CODE

参考实现见[此处](https://github.com/anthropics/claude-quickstarts/tree/main/managed-agents/daily-brief)。如需交互式演练，请在 Claude Code 中运行下方命令。`claude-api` skill 可以按照本文的指导帮助你搭建该 agent：

> The reference implementation is [here](https://github.com/anthropics/claude-quickstarts/tree/main/managed-agents/daily-brief). For an interactive walkthrough, run the command below in Claude Code. The `claude-api` skill can help set up the agent following the guidance in this article:

```
/claude-api managed-agents-onboard https://claude.dev/blog/building-effective-agent-automations/
```

对于这个参考实现，你需要一个 Slack 应用（[通过清单创建](https://api.slack.com/apps?new_app=1&manifest_yaml=display_information%3A%0A%20%20name%3A%20Daily%20brief%0A%20%20description%3A%20Posts%20one%20short%20brief%20each%20weekday%20morning.%0Afeatures%3A%0A%20%20bot_user%3A%0A%20%20%20%20display_name%3A%20Daily%20brief%0A%20%20%20%20always_online%3A%20false%0A%20%20app_home%3A%0A%20%20%20%20home_tab_enabled%3A%20false%0A%20%20%20%20messages_tab_enabled%3A%20true%0A%20%20%20%20messages_tab_read_only_enabled%3A%20true%0Aoauth_config%3A%0A%20%20scopes%3A%0A%20%20%20%20bot%3A%0A%20%20%20%20%20%20-%20channels%3Ahistory%0A%20%20%20%20%20%20-%20chat%3Awrite%0Asettings%3A%0A%20%20org_deploy_enabled%3A%20false%0A%20%20socket_mode_enabled%3A%20false%0A%20%20token_rotation_enabled%3A%20false%0A)）和一个 [GitHub 令牌](https://github.com/settings/personal-access-tokens/new)。所提供的文件（如下所示）是 Claude API 资源的配置，包括智能体、其运行环境、记忆存储、密钥库和部署。

> For this reference implementation, you need a Slack app ([create it from the manifest](https://api.slack.com/apps?new_app=1&manifest_yaml=display_information%3A%0A%20%20name%3A%20Daily%20brief%0A%20%20description%3A%20Posts%20one%20short%20brief%20each%20weekday%20morning.%0Afeatures%3A%0A%20%20bot_user%3A%0A%20%20%20%20display_name%3A%20Daily%20brief%0A%20%20%20%20always_online%3A%20false%0A%20%20app_home%3A%0A%20%20%20%20home_tab_enabled%3A%20false%0A%20%20%20%20messages_tab_enabled%3A%20true%0A%20%20%20%20messages_tab_read_only_enabled%3A%20true%0Aoauth_config%3A%0A%20%20scopes%3A%0A%20%20%20%20bot%3A%0A%20%20%20%20%20%20-%20channels%3Ahistory%0A%20%20%20%20%20%20-%20chat%3Awrite%0Asettings%3A%0A%20%20org_deploy_enabled%3A%20false%0A%20%20socket_mode_enabled%3A%20false%0A%20%20token_rotation_enabled%3A%20false%0A)) and a [GitHub token](https://github.com/settings/personal-access-tokens/new). The provided files (shown below) are configuration for Claude API resources, including the agent, its environment, memory stores, vault, and deployment.

```
daily-brief/
├── agent.md                        model, tools, instructions
├── deployment.md                   schedule, time zone, budget, input message
├── environment.yaml                network allowlist
├── memory_store_preferences.yaml   user preferences
├── memory_store_state.yaml         the agent's bookmarks, ledger, notes, and run records
├── vault.yaml                      the vault that holds the credentials
├── claude-lock.json                resource IDs, written by ant apply
└── slack/manifest.yaml             one bot app
```

[ant apply](https://platform.claude.com/docs/en/cli-sdks-libraries/cli/apply) 是 ant CLI 中的一个命令，它会读取这些文件，在你的 Claude API 工作区（平台存储和运行这些资源的地方）中创建相应资源，并将其 ID 记录到 `claude-lock.json` 中。

> [ant apply](https://platform.claude.com/docs/en/cli-sdks-libraries/cli/apply), a command in the ant CLI, reads these files, creates the resources in your Claude API workspace (where the platform stores and runs them), and records the IDs in `claude-lock.json`.

我们将在下文各节中使用此命令。配置完成后，该自动化任务会按计划在 Anthropic 的基础设施上运行，因此你的机器上无需保持任何程序运行。

> We'll use this command in the sections below. Once configured, the automation runs on a schedule on Anthropic's infrastructure, so nothing has to stay running on your machine.

#### 概述

> OVERVIEW

我们将要构建的智能体由六个组件构成，按以下顺序依次介绍：

> The agent we’ll build has six components, covered in this order:

- Sources - 一组具名的读取位置列表
- Destination - 智能体可以写入的唯一位置
- Agent - agent.md 中的模型、工具和运行步骤
- Schedule - 一个 cron 调度计划
- Memory——你的偏好与智能体自身的记忆
- 护栏机制 - 凡是智能体只需读取的地方都只授予只读权限，并为每次运行设置花费上限

> • Sources - A named list of places to read
> • Destination - One place the agent may write
> • Agent - The model, tools, and run steps in agent.md
> • Schedule - A cron schedule
> • Memory - Your preferences and the agent's own memory
> • Guardrails - Read-only access wherever the agent only reads, and a spending cap per run

![Architecture of the agent: a schedule wakes the agent, which reads from its sources and posts a brief to one destination for the reader. Memory holds the agent's state and the reader's preferences, and guardrails surround the agent.](https://claude.dev/media/fdbe45db5e3ce9afbb00bf62f87e64078a683800bc492d4ac6cf716a2d313a00.png)

#### 参考来源

> SOURCES

该智能体默认读取两个来源：Slack 频道和 GitHub 拉取请求。这些频道和仓库列在你的 `preferences` 文件中。你也可以扩展该模板以使用其他来源。

> The agent reads two default sources: Slack channels and GitHub pull requests. The channels and repos are listed in your `preferences` file. The template can be extended to use other sources.

![The architecture diagram with Sources highlighted. The sources are read-only, reached through MCP or HTTPS with credentials from a vault, and feed the agent.](https://claude.dev/media/d8508de61bb90f3bfccf6184dd3d7cbe9c65e2e76bd00477efd1620e3910dae7.png)

##### 为智能体配备专属的、限定权限范围的凭证

> Give the agent its own, scoped credentials

在 [Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview) 中，凭据存放在 [vault](https://platform.claude.com/docs/en/managed-agents/vaults) 中。智能体可以引用这些凭据，但真实值始终保留在 vault 里，位于运行 Claude 代码的沙箱之外（参见[此处](https://www.anthropic.com/engineering/managed-agents)和[此处](https://x.com/katelyn_lesse/status/2099315903884415400)）：

> With [Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview), credentials live in [vaults](https://platform.claude.com/docs/en/managed-agents/vaults). The agent can reference these credentials but the real values stay in the vault, outside the sandbox where Claude's code runs (see [here](https://www.anthropic.com/engineering/managed-agents) and [here](https://x.com/katelyn_lesse/status/2099315903884415400)):

- 
**MCP 服务器（GitHub）。**智能体通过一个运行在沙箱外部的代理调用 MCP 工具。该代理会查找 URL 与该服务器 URL 相匹配的保险库凭据。

- 
**Shell（Slack）。**智能体在沙箱内使用 bash 工具，通过 curl 调用 Slack API。沙箱中只保存一个不透明的占位符 `$SLACK_BOT_TOKEN`。当请求离开沙箱时，平台会针对你允许的主机将其替换为真实令牌。


> • 
> **MCP servers (GitHub).** The agent calls MCP tools through a proxy that runs outside the sandbox. The proxy finds the vault credential whose URL matches the server’s.
> • 
> **The shell (Slack).** The agent calls the Slack API with curl using the bash tool inside the sandbox. The sandbox only holds an opaque placeholder, `$SLACK_BOT_TOKEN`. As the request leaves the sandbox, the platform swaps in the real token for hosts you allow.

使用 `ant` CLI 和仓库中的模板文件创建 vault：

> Create the vault using the `ant` CLI and the template file in the repo:

```
ant apply vault.yaml
```

这会在你的 Claude API 工作区中创建该保管库（由平台负责存储），并将其 ID 记录在 `claude-lock.json` 中。然后使用 [TypeScript SDK](https://platform.claude.com/docs/en/cli-sdks-libraries/sdks/typescript) 将每个凭据添加到该保管库中。下面是一个添加 Slack 凭据的示例：

> This creates the vault in your Claude API workspace, where the platform stores it, and records its ID in `claude-lock.json`. Then add each credential to the vault with the [TypeScript SDK](https://platform.claude.com/docs/en/cli-sdks-libraries/sdks/typescript). Here is an example showing addition of the Slack credential:

```
const vaultId = process.env.VAULT_ID!; // the vault's ID, from claude-lock.json

await client.beta.vaults.credentials.create(vaultId, {
  display_name: "SLACK_BOT_TOKEN",
  auth: {
    type: "environment_variable",
    secret_name: "SLACK_BOT_TOKEN",
    secret_value: process.env.SLACK_BOT_TOKEN!,
    networking: { type: "limited", allowed_hosts: ["slack.com"] },
    injection_location: { header: true },
  },
});
```

After creating the vault and adding each credential, attach the vault to the deployment. Copy the vault ID from `claude-lock.json` into `vault_ids` in the deployment file, `deployment.md`.

> After creating the vault and adding each credential, attach the vault to the deployment. Copy the vault ID from `claude-lock.json` into `vault_ids` in the deployment file, `deployment.md`.

##### 从上次中断的地方继续阅读

> Read from where you left off

一个常见的错误是让智能体读取一个固定的时间窗口，比如“*过去 24 小时*”。运行晚了会留下空档，运行早了又会重复读取条目。正确的做法是为每个来源分配一个书签。每次运行结束时，智能体把它从每个来源读到的最新条目的时间戳写入同一个文件 `bookmarks.json`，每个来源对应一条记录：`"slack": "2026-09-14T13:02:11Z"`。

> A common mistake is asking the agent to read a fixed window like "*the last 24 hours*." A late run leaves a gap and an early run repeats items. Instead, give the agent a bookmark per source. At the end of each run, the agent writes the timestamp of the newest item it read from each source to one file, `bookmarks.json`, with an entry per source: `"slack": "2026-09-14T13:02:11Z"`.

下一次运行会从这些书签处开始，因此它的时间窗口会相应拉长或缩短，以覆盖自上次运行以来的全部内容。这些书签存放在名为 `state` 的[记忆存储](https://platform.claude.com/docs/en/managed-agents/memory)中：这是一个由文本文件组成的文件夹，平台会将其挂载到每次运行的沙箱中的 `/mnt/memory/` 下，并在多次运行之间保留。智能体使用其常规的文件工具读写它，而 `agent.md` 中的指令会告诉它具体该怎么做。

> The next run starts from those bookmarks, so its window stretches or shrinks to cover everything since the last run. The bookmarks live in the [memory store](https://platform.claude.com/docs/en/managed-agents/memory) called `state`: a folder of text files that the platform mounts into every run's sandbox under `/mnt/memory/` and keeps between runs. The agent reads and writes it with its ordinary file tools, and the instructions in `agent.md` tell it how.

##### 别把读取失败误当成风平浪静的一天

> Don't mistake a failed read for a quiet day

如果某个 MCP 服务器宕机或其令牌已过期，运行仍会启动，只是不带该服务器的工具。会话会记录一条错误，但智能体从该来源看不到任何内容，于是报告“没有新内容”。

> If an MCP server is down or its token has expired, the run still starts, just without that server's tools. The session logs an error, but the agent sees nothing from that source and reports "nothing new."

`agent.md` 中的三条规则有助于解决这个问题。当某个数据源失败时，agent 会：将该数据源的书签保持在原处，用其他数据源撰写简报，并在简报末尾用一行文字注明它未能读取的内容（“本次运行无法获取 pull request”），以便让读者知晓。

> Three rules in `agent.md` help fix this. When a source fails, the agent will: keep the source’s bookmark where it is, write the brief from the other sources, and end the brief with one line naming what it couldn't read ("pull requests unavailable this run"), so the reader is made aware.

#### 目的地

> DESTINATION

我们的模板会发布到一个 Slack 频道，每次运行时都会发布一条带日期的帖子。

> Our template posts to one Slack channel, with a dated post each time it runs.

![The architecture diagram with Destination highlighted. After a check that today's brief isn't already posted, the agent posts to one destination, which delivers the brief to the reader.](https://claude.dev/media/15481dc4dff01b4a613e8ff36039bc14036ab97781eddeaf749746533b97bd16.png)

该 agent 在其沙箱中通过 bash 工具向 Slack 发帖，所用的 bot token 与它读取消息时使用的相同。

> The agent posts to Slack using the bash tool in its sandbox, using the same bot token it reads with.

发布这条帖子不需要经过任何审批。智能体通过一条 bash 命令发送它，而内置的 bash 工具默认无需审批即可运行。`slack.com` 也在该智能体[环境](https://platform.claude.com/docs/en/managed-agents/environments)（即其运行所在的沙箱）的允许列表中。发布帖子只需一个请求：

> Nothing has to approve the post. The agent sends it with a bash command, and the built-in bash tool runs without asking for approval by default. `slack.com` is also on the allowlist of the agent's [environment](https://platform.claude.com/docs/en/managed-agents/environments), the sandbox it runs in. The post is one request:

```
curl -s https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"channel": "C0123456789", "text": "Daily brief, Tue Sep 15 ..."}'
```

##### 先确认帖子已成功发布，再进行记录

> Confirm the post landed before recording it

一旦确认帖子已发布，智能体就会更新其已报告条目的台账和书签。如果这些记录与实际发布的内容不一致，就可能出现两种问题。如果智能体记录了一条实际上并未发出的帖子，书签就会继续前移，而那些条目将永远不会被报告。如果智能体因为不确定第一条帖子是否已发出而再次发布，读者就会收到两份相同的简报。

> Once a post is confirmed, the agent updates its ledger of reported items and its bookmarks. If those records don't match what was actually posted, two things can go wrong. If the agent records a post that never landed, the bookmarks move on and those items are never reported. If it posts again because it isn't sure the first post landed, readers get the same brief twice.

`agent.md` 中的三条规则可以防止这种情况。第一，智能体会在频道的近期消息中查找今天的标题，如果该期内容已经发布，就不再发帖。第二，只有当 Slack 返回 `"ok": true` 和消息 ts 时，才算发送成功。第三，智能体只在得到这一确认后才更新台账和书签。如果结果不明确，它会将本次运行标记为“可能已发布”，且不做其他任何改动，因此不会丢失任何内容。

> Three rules in `agent.md` prevent this. First, the agent looks for today's title in the channel's recent messages and doesn't post if the edition is already there. Second, the post counts as sent only if Slack returns `"ok": true` and a message ts. Third, the agent updates the ledger and bookmarks only after that confirmation. If the result is unclear, it marks the run "maybe posted" and changes nothing else, so nothing is lost.

该智能体会在其记忆存储（`runs/<date>.md`）中保存一份运行记录。它在发帖前将本次运行标记为“发布中”，之后再标记为附带消息 ID 的“已发布”，或者标记为“可能已发布”。

> The agent keeps a run record in its memory store (`runs/<date>.md`). It marks the run "posting" before the post, then "posted" with the message ID, or "maybe posted."

#### 智能体

> AGENT

在 Claude Managed Agents 中，[agent](https://platform.claude.com/docs/en/managed-agents/agent-setup) 是一种带版本的配置，由模型、系统提示词和工具组成。每次运行都会按其运行步骤执行，然后停止。

> In Claude Managed Agents, an [agent](https://platform.claude.com/docs/en/managed-agents/agent-setup) is a versioned configuration: a model, a system prompt, and tools. Each run follows its run steps and stops.

![The architecture diagram with the Agent highlighted: a model plus a prompt that holds the run loop and the judgement rules.](https://claude.dev/media/8b00d803c6eee8a1c6419c15961f688cba2f6fbff5031e1bd0539725cba1780b.png)

在我们的参考实现中，智能体配置为 `agent.md`：

> In our reference implementation, the agent configuration is `agent.md`:

```
---
name: Daily brief
model: claude-sonnet-5-5
mcp_servers:
  - type: url
    name: github
    url: https://api.githubcopilot.com/mcp/
tools:
  - type: agent_toolset_20260401
    configs:
      - name: web_search
        enabled: false
      - name: web_fetch
        enabled: false
  - type: mcp_toolset
    mcp_server_name: github
    default_config:
      permission_policy:
        type: always_allow
---

[Eight numbered run steps; the full text is in agent.md in the repo.]
```

frontmatter 提供智能体名称、模型、工具和 MCP 服务器，正文则提供智能体指令。MCP 工具默认需要审批，但运行时无人在场批准，因此将 GitHub 工具集设置为 `always_allow`，并将 GitHub 令牌设置为 `read-only`。

> The frontmatter supplies the agent name, model, tools, and MCP servers. The body provides the agent instructions. MCP tools ask for approval by default and nobody is there to give it, so the GitHub toolset is set to `always_allow` and the GitHub token is `read-only`.

##### 保持简报简短

> Keep the brief short

`agent.md` 会引导 Claude 趋向简洁：

> `agent.md` steers Claude toward brevity:

```
4. Decide. An item earns a line when the reader would act on it today, or it changes a decision they are about to make. When unsure, leave it out. Most days that is a few items, sometimes none. A count ("12 open reviews") is not an item; link the ones that are blocked. An item already in the ledger and still open is carried as one marked line ("still waiting, day 3"), not re-reported; a closed item is dropped without comment. Do not bring back a topic the preferences file has retired.
```

##### 发布前，再检查一遍仍未解决的事项

> Re-check anything still open right before posting

从智能体读取来源到发布内容之间，条目的状态可能会发生变化。在发布前的最后一刻，`agent.md` 会指示智能体重新检查每个条目的实时状态：

> Items can change between when the agent reads sources and when it posts. Just before posting, `agent.md` instructs the agent to re-check the live status of each item:

```
5. Verify. The world moved while you read. For every item you will report, re-check its live source just before posting: resolved since you read it, drop it; still open but changed, fix the line; cannot confirm, drop it and list it in the run record's cuts. One stale "still waiting on you" costs more trust than ten missing items, so never hedge an item's status: assert it or drop it. Every link is copied from the source's own link field (a pull request's html_url, a Slack permalink), never assembled by hand.
```

#### 调度

> SCHEDULE

在 Claude Managed Agents 中，智能体只是一个配置文件；由[部署](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments)来运行它。部署指定了智能体、环境以及每次运行的第一条消息，还包含调度计划、凭据库、记忆存储和预算。每当调度触发时，平台都会启动一个全新的智能体[会话](https://platform.claude.com/docs/en/managed-agents/sessions)。

> With Claude Managed Agents, the agent is only a configuration file; a [deployment](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments) runs it. The deployment names the agent, environment, and the first message of each run. It also holds the schedule, vault, memory stores, and budget. Each time the schedule fires, the platform starts a fresh agent [session](https://platform.claude.com/docs/en/managed-agents/sessions).

![The architecture diagram with Schedule highlighted: a scheduled deployment that wakes the agent for each run.](https://claude.dev/media/a206f78f34b18dcf7a51bc9bca1acaaf3b68df80ee4034ff521cfbf353af7bc5.png)

在我们的模板中，部署记录在 `deployment.md` 中，以第一条消息作为其正文：

> In our template, the deployment is captured in `deployment.md`, with the first message as its body:

```
---
name: Daily brief
agent: ./agent.md
environment_id: ./environment.yaml
schedule:
  type: cron
  expression: "32 7 * * 1-5"
  timezone: America/New_York
vault_ids: [vlt_...]   # the vault you create under Sources
resources:
  - path: ./memory_store_preferences.yaml
    access: read_only
    instructions: The reader's preferences. Re-read them every run. Never write here.
  - path: ./memory_store_state.yaml
    access: read_write
    instructions: Your state. Bookmarks, ledger, notes, proposals, and run records.

---

Write today's brief.
The reader's time zone is America/New_York. Work out every date in that zone.

Follow your run steps in order. Today's edition is titled "Daily brief, <weekday> <month> <day>".
```

这会创建该部署，并包含它按路径引用的 agent、环境和记忆存储。

> This creates the deployment with the agent, environment and memory stores it names by path.

```
ant apply deployment.md
```

如果想在不等待计划触发的情况下进行测试，可以使用 `ant beta:deployments run --deployment-id <id>` 手动启动一次运行，所需 ID 取自 `claude-lock.json`。

> To test it without waiting for the schedule, start a run by hand with `ant beta:deployments run --deployment-id <id>`, using the ID from `claude-lock.json`.

##### 按你所在的时区计算日期

> Compute dates in your time zone

一个常见的 bug 是智能体把今天早上称为“昨天”，因为它是按服务器所在时区计算日期的。在 `deployment.md` 中，`timezone` 字段设定运行的触发时间，而正文的第二行则告诉智能体在处理日期时应使用哪个时区。

> A common bug is the agent calling this morning "yesterday" because it computes dates in the server's time zone. In `deployment.md`, the `timezone` field sets when the run fires and the second line of the body tells the agent which zone to use for dates.

#### 记忆

> MEMORY

每次运行都从一个全新的沙箱开始，不保留上一次运行的任何记忆。没有记忆，反馈就无法留存。然而，过时的记忆也会让智能体困惑：它会把一个已经解决的事项报告为仍在等待中，或者因为某个事项“已经报告过”而将其遗漏，尽管它仍未关闭。

> Each run starts in a fresh sandbox with no memory of the last one. Without memory, feedback doesn't stick. However, stale memory can confuse the agent: it reports an item as still waiting after it was resolved, or drops one that's still open because it was "already reported."

![The architecture diagram with Memory highlighted. State is what the agent reads and writes, and Preferences is what the reader writes and the agent only reads.](https://claude.dev/media/30e51eab0381bb583fe355fe412162b4e8868643b8d58b2c76c4aa2d0eafea57.png)

我们的模板维护两个[记忆存储](https://platform.claude.com/docs/en/managed-agents/memory)，即挂载在 /mnt/memory/ 下的文件夹（参见“来源”）：

> Our template keeps two [memory stores](https://platform.claude.com/docs/en/managed-agents/memory), the folders mounted under /mnt/memory/ (see Sources):

- 
**偏好设置**（属于你，对智能体只读）：要读取哪些频道和仓库、哪些内容要排除、长度上限、输出目的地，以及何时停止。

- 
**state**（属于智能体，可读写）：书签、记录其已报告内容的台账（每次运行一条记录）、它对你的偏好提出的修改建议，以及关于每个来源行为特点的笔记（例如“只返回最新的 50 条”）。


> • 
> **preferences** (yours, read-only to the agent): which channels and repos to read, what to leave out, the length cap, the destination, and when to stop.
> • 
> **state** (the agent's, read-write): the bookmarks, a ledger of what it reported, one record per run, changes it proposes to your preferences, and notes on how each source behaves ("returns only the newest 50 items").

`ant apply deployment.md` 会创建偏好设置存储目录，但不会在其中创建文件。首次运行之前，请使用该仓库的 `scripts/seed-preferences.sh` 在其中写入你的 preferences.md。

> `ant apply deployment.md` creates the preferences store, but not the file in it. Before the first run, write your preferences.md there with the repo's `scripts/seed-preferences.sh`.

##### 每次运行开始时重新读取你的偏好设置

> Re-read your preferences at the start of every run

一个常见的问题是：偏好设置的副本被固化在提示词中，导致它不断沿用你早已修改过的规则。应让智能体在每次运行时都重新读取该文件。如果无法读取文件，它应当停止运行并明确说明，而不是按默认设置继续执行。

> A common problem occurs when a copy of the preferences is baked into the prompt, which keeps applying rules you've already changed. Have the agent read the file fresh every run. If it can't read the file, it should stop and say so instead of running on defaults.

##### 记录你已经报告过的内容，并报告其中的变化

> Keep a ledger of what you've already reported, and report the change

智能体会维护一份台账 `ledger.md`，记录它报告过的每一项内容，从而避免简报重复。每一行记录该条目的报告时间、来源、一个固定不变的 ID（Slack 消息时间戳或拉取请求编号），以及它最后已知的状态：

> The agent keeps a ledger, `ledger.md`, of every item it has reported, so the brief doesn't repeat itself. Each line records when the item was reported, where it came from, an ID that doesn't change (a Slack message timestamp or a pull request number), and its last known status:

```
2026-09-09 slack:C0123456789 1788963600.000100 refund thread: customer waiting on a decision
2026-09-11 github 481 review blocked, day 2 (still waiting)
2026-09-11 slack:C0234567891 1789117333.000300 enterprise escalation: owner named, in progress
```

#### 护栏

> GUARDRAILS

由于我们的自动化任务按计划在“后台”运行，我们对智能体能做什么以及能花费多少都设定了限制。

> Because our automation runs in the “background” on a schedule, we set limits on what the agent can do and what it can spend.

![The architecture diagram with Guardrails highlighted: a boundary around the agent with caps on turns, time and spend, and a heartbeat that someone watches.](https://claude.dev/media/746533f20f4e2bf093d08a04f368a8c5eca739de6579c384e9742b86d5385f50.png)

##### 它能力上的局限

> Limits on what it can do

智能体会读取他人撰写的消息和 issue，而这些文本可能会被解读为指令。因此要限制智能体在遵从这些指令时所能做的事情。在我们的示例中，GitHub 令牌和 `preferences` 存储都是只读的，并且运行环境只能访问其允许列表中的主机。被植入的指令仍然可以改变简报的内容，包括通过智能体在多次运行之间保留的笔记来实现。但它无法写入 GitHub，也无法修改你的规则。

> The agent reads messages and issues that other people wrote, and that text can be interpreted as instructions. Limit what the agent could do if it followed them. In our example, the GitHub token and the `preferences` store are read-only, and the environment only reaches the hosts on its allowlist. A planted instruction can still change what the brief says, including through the notes the agent keeps between runs. It can't write to GitHub or edit your rules.

Slack 是个例外：同一个令牌也用于发帖，因此只把机器人邀请到它需要读取或发帖的频道中。

> Slack is the exception: the same token posts, so invite the bot only where it needs to read or post.

##### 根据真实运行数据设定支出上限

> Set the spending cap from real runs

A spending cap protects you from runaway costs. Start at three to five times the cost of a normal run, then tighten it as you see real numbers. A run that hits its cap pauses instead of failing, so a cap set too low looks like a brief that went quiet. The cap is the [budget](https://platform.claude.com/docs/en/managed-agents/budgets) in `deployment.md`. Every run gets the full amount, and a run that reaches it pauses with a `budget_reached` stop reason:

> A spending cap protects you from runaway costs. Start at three to five times the cost of a normal run, then tighten it as you see real numbers. A run that hits its cap pauses instead of failing, so a cap set too low looks like a brief that went quiet. The cap is the [budget](https://platform.claude.com/docs/en/managed-agents/budgets) in `deployment.md`. Every run gets the full amount, and a run that reaches it pauses with a `budget_reached` stop reason:

```
budget:
  type: limit
  max_list_cost:
    amount: "500" # a string, in cents: "500" is $5.00
    currency: USD
```

#### 入门指南

> GETTING STARTED

我们的参考实现可以归结为六条规则：

> Our reference implementation comes down to six rules:

- 从书签位置读取每个来源，而不是按固定的时间窗口读取。
- 读取失败时要报告为无法读取，绝不能当作平静无事的一天。
- 发布前再逐项检查一遍。
- 只有在 Slack 确认后才将帖子计为已发送，然后更新书签和台账。
- 每次运行都要重新读取你的偏好设置，并且要从智能体无法编辑的存储中读取。
- 凡是只需读取的地方，都只给智能体只读权限，并为每次运行设定支出上限。

> • Read each source from a bookmark, not a fixed time window.
> • Report a failed read as unreadable, never as a quiet day.
> • Re-check every item right before posting.
> • Count a post as sent only when Slack confirms it, then update bookmarks and ledger.
> • Re-read your preferences every run, from a store the agent can't edit.
> • Give the agent read-only access wherever it only reads, and cap what each run can spend.

Claude Code 可以带你逐步了解本文提供的指导。首先，进行更新：

> Claude Code can walk you through the guidance provided in this article. First, update:

```
claude update
```

然后，使用 claude-api skill：

> Then, use the claude-api skill:

```
/claude-api managed-agents-onboard https://claude.dev/blog/building-effective-agent-automations/
```

claude-api 技能会读取这篇文章，提出一套配置方案，将文件写入你项目中的 agents/ 文件夹，并通过 ant apply 创建相应资源。请将其视为一个起点，并根据你的数据源、目标位置或记忆偏好来定制该智能体。

> The claude-api skill reads this post, proposes a setup, writes the files to an agents/ folder in your project, and creates the resources with ant apply. Treat this as a starting point, and customize the agent for your sources, destination, or memory preferences.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Agentic Automation | 智能体自动化 | 由 AI 智能体按计划在后台自主收集信息并执行任务的自动化流程。 |
| Claude Managed Agents | Claude 托管智能体 | Anthropic 提供的在其基础设施上配置、运行和调度智能体的平台服务。 |
| Vault | 凭据库 | 存放智能体凭据的安全存储，真实值保留在运行沙箱之外。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 让模型通过标准化服务器接口调用外部工具和数据源的协议。 |
| Sandbox | 沙箱 | 智能体执行代码和工具调用的隔离运行环境。 |
| Bookmark | 书签 | 记录每个来源上次读取到的最新条目时间戳，用作下次读取的起点。 |
| Ledger | 台账 | 记录智能体已报告条目及其最后已知状态的文件，用于避免重复报告。 |
| Memory Store | 记忆存储 | 挂载到每次运行沙箱中、跨运行持久保留的文本文件夹。 |
| Deployment | 部署 | 指定智能体、环境、首条消息、调度、凭据和预算并负责实际运行智能体的配置。 |
| Cron Schedule | cron 调度计划 | 用 cron 表达式定义任务定时触发规则的调度方式。 |
| Guardrails | 护栏机制 | 限制智能体权限范围和花费的约束措施。 |
| Prompt Injection | 提示词注入 | 外部文本中夹带的内容被模型误当作指令执行的风险。 |
| Allowlist | 允许列表 | 限定运行环境可访问的主机范围的白名单。 |
| Budget | 预算 | 为每次运行设置的支出上限，触达后运行以 budget_reached 原因暂停。 |
| Frontmatter | 前置元数据 | 位于 Markdown 文件开头、用于声明名称、模型、工具等配置的元数据块。 |
