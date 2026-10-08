# 云端的 Claude Code：云会话实用指南

> Claude Code in the cloud: a field guide to cloud sessions

> 来源：Claude Blog / Anthropic，2026-10-06
> 原文链接：https://claude.dev/blog/claude-code-in-the-cloud/
> 分类：AI 编程工具 / Claude Code 云端会话

## 核心要点

- 本地运行的 Claude Code 会话与用户共享工作树和凭据，并在电脑睡眠或断网时停止，而云端会话为每个任务分配一台已克隆仓库到新分支的全新虚拟机。
- 在 tidepool 示例仓库上，三个云端会话在 16 秒内相继启动、87 秒内全部完成，分别修复了缓存竞态导致的不稳定测试、纠正了五处文档错误并实现了 JSON 日志记录器。
- 由于会话彼此隔离，日志记录器会话无法获得缓存修复，因此并行任务应按文件边界拆分、按合理顺序合并，并预期会话会报告其他会话正在修复的问题。
- 云端会话的 GitHub 令牌由代理持有而不进入虚拟机，仓库内的 CLAUDE.md、规则、技能等配置会随仓库迁移，个人 ~/.claude 不会同步，空闲虚拟机会被回收。
- 需要本地数据库、VPN、GPU、硬件、紧凑视觉迭代或启用零数据保留的任务应留在本地，远程控制和自托管环境则介于本地与云端之间。
- 适合云端的七种工作流包括并行清理积压任务、反复验证修复、本地规划云端构建再用 Teleport 拉回收尾、手机跟进、自动处理 CI 失败与评审意见、由例程触发工作以及运行不受信任的代码。
- 连接 GitHub 需要两项独立权限：用 GitHub 登录以识别身份，以及在拥有私有仓库的账户或组织上安装 Claude GitHub App；也可通过 /web-setup 使用 gh 令牌，或在无 GitHub 时上传仓库 bundle。
- 环境配置应从默认环境开始，用以 root 运行的 setup 脚本安装机器级工具并缓存快照，用 SessionStart hook 处理项目依赖，选用最窄网络级别，并避免把密钥放在共享变量中。
- 推荐的习惯包括一个任务一个会话、指明证明完成的命令、在 claude --cloud 前推送、长任务边做边提交、在差异视图中审查，以及注意并行会话会成倍消耗用量。
- 云端会话包含在 Pro、Max、Team 和 Enterprise 套餐中且共享用量限额，虚拟机约有 4 个 vCPU、16 GB 内存和 30 GB 磁盘，GitLab 和 Bitbucket 仓库可上传 bundle 但无法推送回去。

## 正文

你很可能是在自己笔记本电脑的终端里运行 Claude Code。这个会话在三个方面依赖于这台笔记本电脑：

> You probably run Claude Code in a terminal on your own laptop. That session depends on the laptop in three ways:

- 它与你共享同一个工作树，因此同一仓库上的两个会话可能会编辑相同的文件，并争抢同一个端口。
- 它会使用你的凭据运行。
- 当你的电脑进入睡眠或 Wi-Fi 断开时，它就会停止运行。

> • It shares your working tree, so two sessions on one repository can edit the same files and fight over the same port.
> • It runs with your credentials.
> • It stops when your computer sleeps or the Wi-Fi drops.

[云端会话](https://code.claude.com/docs/en/claude-code-on-the-web)会在一台专属机器上运行 Claude Code。每个任务都会获得一台全新的虚拟机，你的仓库已被克隆到一个新分支上，环境的初始化配置也已完成。

> [A cloud session](https://code.claude.com/docs/en/claude-code-on-the-web) runs Claude Code on a machine of its own. Each task gets a fresh virtual machine with your repository cloned onto a new branch and your environment's setup already done.

你可以从 [claude.ai/code](https://code.claude.com/docs/en/web-quickstart)、[Claude 移动应用](https://code.claude.com/docs/en/mobile)、[桌面应用](https://code.claude.com/docs/en/desktop#run-long-running-tasks-in-the-cloud)、你的[终端](https://code.claude.com/docs/en/claude-code-on-the-web#from-terminal-to-cloud)以及 [Slack](https://code.claude.com/docs/en/slack) 启动一个会话。之后，你可以在浏览器、移动应用和桌面端跟进它。工作完成后，结果会保存在一个分支上，你可以将其转为拉取请求（pull request）。

> You can start one from [claude.ai/code](https://code.claude.com/docs/en/web-quickstart), the [Claude mobile app](https://code.claude.com/docs/en/mobile), the [Desktop app](https://code.claude.com/docs/en/desktop#run-long-running-tasks-in-the-cloud), your [terminal](https://code.claude.com/docs/en/claude-code-on-the-web#from-terminal-to-cloud), and [Slack](https://code.claude.com/docs/en/slack). You can then follow it from the browser, the mobile app, and Desktop. When the work is done, it sits on a branch you can turn into a pull request.

云端会话包含在你的 Pro、Max、Team 或 Enterprise 套餐中，无需额外付费：云端机器不单独收费，会话与 Claude Code 的其他功能共用同一套用量限额。根据你的套餐类型，可能需要由组织所有者先[开启云端会话](https://claude.ai/admin-settings/claude-code)。

> Cloud sessions come with your Pro, Max, Team, or Enterprise plan at no additional cost: there's no separate charge for the cloud machine, and sessions draw on the same usage limits as the rest of Claude Code. Depending on your plan, an organization owner may need to [turn on cloud sessions](https://claude.ai/admin-settings/claude-code) first.

**云端会话奖励额度。**现有的 Pro 和 Max 个人订阅用户可领取一次性的云端会话奖励额度，该额度独立于套餐限额之外：Pro 用户为 100 美元，Max 用户为 250 美元。请在 10 月 7 日前通过 claude.ai/code/claim-credit 或在 Claude Code 中使用 `/claim-credit` 领取。该额度将于 11 月 4 日到期。额度用完或到期后，将按你所订套餐的常规用量计算。该额度不适用于 Projects 或 Routines。详见[促销额度优惠条款](https://www.anthropic.com/legal/promotion-credit-terms)。

> **Bonus credit for cloud sessions.** Existing individual Pro and Max subscribers can claim a one-time bonus credit for cloud sessions, on top of their plan limits: $100 on Pro and $250 on Max. Claim it by October 7 at claude.ai/code/claim-credit or with `/claim-credit` in Claude Code. The credit expires on November 4. After it's used or expires, your plan's regular usage applies. It isn't eligible for Projects or Routines. See the [Promotional Credit Offer Terms](https://www.anthropic.com/legal/promotion-credit-terms).

为撰写本指南，我在一个小型示例代码库上运行了四次真实的云端会话。这些会话的记录、diff 和耗时贯穿全文。截图中的代码库和用户均为虚构，但其中的工作内容、输出结果和各项数据都来自这些会话。

> For this guide I ran four real cloud sessions against a small sample repository. Their transcripts, diffs, and timings appear throughout. The repository and the user in the screenshots are made up. The work, the output, and the numbers come from those sessions.

云端会话的主要优势之一，是你可以同时运行多个任务，而它们不会互相干扰。下面是我在 16 秒内相继启动的三个任务，每个都运行在各自独立的机器上。如果在我的笔记本电脑上，我要么只能一个接一个地运行它们，要么得花时间避免它们互相干扰。

> One of the main advantages of cloud sessions is that you can run several tasks at once without them getting in each other's way. Here are three I started within 16 seconds of each other, each on its own machine. On my laptop, I'd have run these one after another, or spent my time keeping them out of each other's way.

![Timeline of three cloud sessions in three VMs, started within 16 seconds of each other. After a hatched setup bar, the flaky-test fix finishes at 65 seconds with the suite run 40 times and 0 failures, the docs rewrite at 62 seconds with 5 doc errors fixed, and the structured-logging change at 87 seconds with JSON logs and 5 new tests.](https://claude.dev/media/58bd02532f8c5914f4dc430c84caddcb4158c4dc7b2905bcf602c9cb439ab5e2.png)

#### 三项任务，一个仓库，三台机器

> THREE TASKS, ONE REPOSITORY, THREE MACHINES

示例仓库是 **tidepool**，这是一个小型 Node API，用于预测三个虚构港口的潮汐。它有三个常见的问题：一个测试大约每运行四次就会失败一次；API 文档描述了代码早已不再读取的参数；日志记录器通过字符串拼接来构造日志行。

> The sample repository is **tidepool**, a small Node API that predicts tides for three fictional harbors. It had three ordinary problems: one test failed about one run in four, the API docs described parameters the code no longer read, and the logger built its lines by concatenating strings.

我在 16 秒内先后启动了三个云端会话，每个问题一个。我是通过程序启动它们的；由于 tidepool 不在 GitHub 上，每个会话都先根据提示词中的文件重建仓库。如果是真实的仓库，你可以跳过这一步，而在终端中，每个会话只需一条 `claude --cloud` 命令。三个提示词精简后如下：

> I started three cloud sessions within 16 seconds of each other, one per problem. I started them programmatically, and because tidepool isn't on GitHub, each session first recreated the repository from files in its prompt. With a real repository you'd skip that step, and from a terminal each session is one `claude --cloud` command. Shortened, the three prompts were:

```
claude --cloud "npm test fails maybe one run in four. Find the flaky test, fix the root cause in the code (not the test), and prove it by running the suite at least 30 times in a row."
claude --cloud "docs/API.md is out of date with src/server.js. Rewrite it so every endpoint, parameter, default and response shape matches the code. Start the server and run each curl example to check it."
claude --cloud "Make src/logger.js emit one JSON object per line, keep LOG_LEVEL, and log method, path, status and duration_ms as fields. Add a test for the logger."
```

这三个会话分别运行了 61 秒、65 秒和 72 秒，从第一个会话启动算起，87 秒后三个会话全部完成。重建仓库大约占每次运行时长的三分之一到略超一半。结果如下。

> The sessions ran for 61, 65 and 72 seconds, and all three were done 87 seconds after the first one started. Recreating the repository took roughly a third to just over half of each run. Here are the results.

- **不稳定的测试。**Claude 在 `TtlCache.get` 中发现了一个竞态条件。该缓存只有在加载器执行完毕后才会存入值，因此在加载期间对同一个键发起的第二次 `get` 会再次调用加载器。Claude 将缓存改为存储进行中的 promise，在加载失败时移除该条目，并连续运行 `npm test` 40 次，零失败。
- **文档。**Claude 启动了服务器，用 curl 逐一请求了每个端点，发现旧文档有五处错误：列出了 API 从不返回的字段，记录了一个代码会忽略的 `days` 参数，把以米为单位的高度写成了英尺，遗漏了 `/next-high` 端点，还漏掉了错误响应。它还发现，格式错误的 `from=` 值会返回一个空列表并附带 200 状态码；它将这一点作为注意事项写进了文档，而没有去修改它未被要求改动的服务器代码。
- **日志记录器。**Claude 编写了 JSON 日志记录器，把请求日志改为结构化字段，并新增了五个测试。它提交时有一个测试未通过，于是 Claude 将缓存测试重跑了八次，其中五次失败，并将失败原因追溯到第一个会话正在修复的同一个竞态条件。它提出了相同的修复方案，但没有改动缓存，因为那超出了它的任务范围，并在总结中说明测试套件并未全部通过。

> • **The flaky test.** Claude found a race in `TtlCache.get`. The cache stored a value only after the loader finished, so a second `get` for the same key during a load called the loader again. Claude changed the cache to store the in-flight promise, dropped the entry when a load fails, and ran `npm test` 40 times in a row with zero failures.
> • **The docs.** Claude started the server, ran a curl against every endpoint, and found five ways the old doc was wrong. It listed fields the API never returns, documented a `days` parameter the code ignores, gave heights in feet when they are metres, skipped the `/next-high` endpoint, and left out the error responses. It also found that a malformed `from=` value returns an empty list with a 200, and documented that as a caveat instead of changing server code it wasn't asked to touch.
> • **The logger.** Claude wrote the JSON logger, moved the request log to structured fields, and added five tests. Its commit went in with one failing test, so Claude reran the cache test eight times, saw it fail in five of them, and traced the failure to the same race the first session was fixing. It proposed the same fix, left the cache alone because that was outside its task, and said in its summary that the suite wasn't clean.

![claude.ai/code showing the Structured logging session: an expanded diff of src/server.js replacing a string-built request log with logger.info('request', { method, path, status, duration_ms }), and a branch bar for claude/structured-logging with a Create PR button.](https://claude.dev/media/6dfaea2721b24b4bcaeb1ecd1888d0b592776c363e69f8563a1db7ea97413659.png)

![The Fix the flaky test session: the command that patched cache.js and ran the test suite 40 times, its output runs=40 fails=0, and Claude's explanation of the race in TtlCache.get.](https://claude.dev/media/caa714fdd2f78736773e380b98b2491123ef497120b00760b9bef931c21a29c0.png)

![The Update the tidepool API docs session: Claude's summary of the five ways the old docs/API.md was wrong.](https://claude.dev/media/a195ee38cd704981526163e2824c10fc9ba813b2dce9045ce2d6ab8651159a70.png)

日志记录器的结果说明了为什么云端会话适合并行工作。每个会话都有自己的仓库副本、自己的进程和自己的分支。文档会话和日志记录器会话各自启动了 API 服务器来进行测试，彼此互不影响。而在单台笔记本电脑上，两个智能体在同一个检出目录中工作时会编辑相同的文件，并且除非各自选用不同的端口，否则还会发生端口冲突。

> The logger result shows why cloud sessions suit parallel work. Each session had its own copy of the repository, its own processes and its own branch. The docs session and the logger session each started the API server to test against it, and neither affected the other. On a single laptop, two agents working in one checkout would edit the same files, and would collide on a port unless each picked its own.

由于这种隔离，日志记录器会话无法获取第一个会话正在进行的缓存修复。应按文件边界拆分并行任务，以合理的顺序合并分支，并预料到某个会话可能会报告另一个会话已在修复的问题。

> Because of that isolation, the logger session had no access to the cache fix the first session was making. Split parallel tasks along file boundaries, merge the branches in a sensible order, and expect a session to report problems that another session is already fixing.

#### 深入剖析 Claude Code 云端会话的底层机制

> UNDER THE HOOD OF A CLAUDE CODE CLOUD SESSION

云端会话是运行在 Anthropic 托管基础设施上的 Claude Code 会话，也可以借助[自托管环境](https://code.claude.com/docs/en/self-hosted-environments)运行在你所在组织自己的机器上。下图展示了其组成部分。图后的四个要点会改变你的工作方式。

> A cloud session is a Claude Code session running on Anthropic-managed infrastructure, or on your organization's own machines with a [self-hosted environment](https://code.claude.com/docs/en/self-hosted-environments). The figure shows the parts. The four takeaways after it are the ones that change how you work.

![You start a session from a browser, phone, Desktop, terminal, Slack or a routine. It runs in a fresh VM with a clone of your repository on a claude branch, Claude Code in auto mode, and your environment's setup. GitHub traffic passes through a proxy that holds your token outside the VM; other traffic passes through a security proxy that applies the network allowlist. The result is a branch and a pull request.](https://claude.dev/media/7c0f2a65796202281cbc6ededff3f0dbfe216aca98e3831640eec064e2b85165.png)

- **每个任务都有专属的机器。**一台全新的虚拟机，你的仓库会被克隆到一个新分支上，因此各个会话之间无法触碰彼此的文件或端口。参见[已安装的内容](https://code.claude.com/docs/en/cloud-environments#installed-tools)。
- **你的 GitHub 令牌永远不会进入虚拟机。**令牌由代理持有，会话只会获得一个短期凭据，且该凭据只能推送到会话自己的工作分支。参见 [GitHub 代理](https://code.claude.com/docs/en/cloud-environments#github-proxy)。
- **仓库的 Claude 配置会随之带上，而你的个人配置不会。**`CLAUDE.md`、规则（rules）、技能（skills）、代理（agents）和命令（commands）会随仓库一起迁移，而你的 `~/.claude` 则留在你的笔记本电脑上。请参阅[云端会话中的设置](https://code.claude.com/docs/en/settings#settings-in-cloud-sessions)。
- **空闲的虚拟机会被回收。**重新打开会话后，你会得到一台新的虚拟机，对话内容会被恢复，因此请提交你在意的工作。参见[环境过期](https://code.claude.com/docs/en/claude-code-on-the-web#environment-expired)。

> • **Every task gets its own machine.** A fresh VM with your repository cloned onto a new branch, so sessions can't touch each other's files or ports. See [what's installed](https://code.claude.com/docs/en/cloud-environments#installed-tools).
> • **Your GitHub token never enters the VM.** A proxy holds it, and the session gets a short-lived credential that can push only to its own working branch. See the [GitHub proxy](https://code.claude.com/docs/en/cloud-environments#github-proxy).
> • **The repository's Claude config comes along. Your personal one doesn't.** `CLAUDE.md`, rules, skills, agents, and commands travel with the repo, and your `~/.claude` stays on your laptop. See [settings in cloud sessions](https://code.claude.com/docs/en/settings#settings-in-cloud-sessions).
> • **Idle VMs get reclaimed.** Reopen the session and you get a fresh VM with the conversation restored, so commit work you care about. See [environment expiry](https://code.claude.com/docs/en/claude-code-on-the-web#environment-expired).

有关规格、[权限模式](https://code.claude.com/docs/en/permission-modes)和网络级别，请参阅[云环境文档](https://code.claude.com/docs/en/cloud-environments)。

> For specs, [permission modes](https://code.claude.com/docs/en/permission-modes), and network levels, see the [cloud environments docs](https://code.claude.com/docs/en/cloud-environments).

#### 本地还是云端？

> LOCAL OR CLOUD?

云端会话并不会取代本地会话，大多数人两者都会用。下表列出了它们的不同之处，表后的段落则说明了各自适用的场景。

> Cloud sessions don't replace local ones, and most people use both. The table shows where they differ, and the paragraphs after it say when each one fits.

|  | 本地会话 | 云端会话 |
| --- | --- | --- |
| 运行环境 | 你的机器 | 每个任务使用一台全新的虚拟机 |
| 笔记本电脑处于睡眠或离线状态 | 会话停止 | 会话持续进行 |
| 同一仓库上的多个任务 | 独立的 worktree、端口，并需谨慎处理 | 每个任务一台虚拟机、一个分支 |
| 智能体可触达的范围 | 你的用户账户能访问的一切，包括 SSH 密钥、云 CLI 和 ~/.claude | 代码仓库、你设置的网络级别、你启用的连接器，以及一个会话范围内的 GitHub 凭据 |
| 从此开始或沿用自 | 那台机器，或通过远程控制使用你的手机 | 浏览器、手机、桌面端、终端、Slack、API 调用或定时任务 |
| 审批 | 任意模式，包括按命令设置 | 自动、接受编辑或计划 |
| 结尾为 | 工作区中的更改 | 一个分支，需要时再加一个拉取请求 |
| 计算 | 你的机器 | 不单独收取计算费用；使用您套餐的额度 |

> 英文原表 / English original

|  | Local session | Cloud session |
| --- | --- | --- |
| Runs on | Your machine | A fresh VM for each task |
| Laptop asleep or offline | The session stops | The session keeps going |
| Several tasks on one repo | Separate worktrees, ports and care | One VM and one branch per task |
| What the agent can reach | Anything your user account can, including SSH keys, cloud CLIs and ~/.claude | The repository, the network level you set, the connectors you enable, and a session-scoped GitHub credential |
| Start or follow from | That machine, or your phone through remote control | Browser, phone, Desktop, terminal, Slack, an API call or a schedule |
| Approvals | Any mode, including per-command | Auto, Accept edits or Plan |
| Ends with | Changes in your working tree | A branch, and a pull request when you want one |
| Compute | Your machine | No separate compute charge; uses your plan's limits |

当任务需要只有你的机器才具备的东西时，就留在本地。这包括存有真实本地数据的数据库、需要通过 VPN 访问的服务、GPU、手机模拟器，或者你桌上的硬件。如果你需要紧凑的视觉迭代循环，希望在几秒内就在自己的浏览器里看到每一处改动，也应留在本地；此外，如果你的组织启用了[零数据保留（Zero Data Retention）](https://code.claude.com/docs/en/zero-data-retention)，云端会话会被关闭，这时同样应留在本地。

> Stay local when the task needs something only your machine has. That covers a database with real local data, a service you reach over VPN, a GPU, a phone simulator, or hardware on your desk. Stay local too for tight visual loops where you want to see each change in your own browser within seconds, and when your organization runs with [Zero Data Retention](https://code.claude.com/docs/en/zero-data-retention), which turns cloud sessions off.

有两项功能介于这些选项之间。**远程控制**让会话保留在你的机器上，同时允许你通过手机或浏览器操控它。**[自托管环境](https://code.claude.com/docs/en/self-hosted-environments)**目前面向 Team 和 Enterprise 提供 beta 版，可在你所在组织自己的基础设施上运行云端会话，因此这些会话能够访问私有网络。

> Two features sit between the options. **Remote control** keeps the session on your machine and lets you steer it from your phone or browser. **[Self-hosted environments](https://code.claude.com/docs/en/self-hosted-environments)**, in beta for Team and Enterprise, run cloud sessions on your organization's own infrastructure, so they can reach private networks.

如果以上情况都不适用，那么这项任务就很适合放到云端执行。下一节将介绍云端执行收益最大的几类工作流。

> If none of that applies, the task is a good candidate for the cloud. The next section covers the workflows where that pays off most.

#### 适合云端会话的七种工作流

> SEVEN WORKFLOWS THAT SUIT CLOUD SESSIONS

这些工作流将表中列出的差异付诸实践：每个任务各用一台独立的机器，会话在你离开期间持续运行，最后生成一个分支供你审阅。

> These workflows put the differences in the table to work: a separate machine for each task, sessions that keep running while you're away, and a branch at the end for you to review.

##### 1. 并行清理积压任务

> 1. Clear a backlog in parallel

假设你有五个互不相关的小修复。在本地，你会一个接一个地完成它们，或者建立五个 worktree，并让它们的端口和依赖安装彼此隔离。在云端，你会启动五个会话，并审查五个分支。

> Let's say you have five small, unrelated fixes. Locally, you'd do them one after another, or set up five worktrees and keep their ports and installs apart. In the cloud, you'd start five sessions and review five branches.

```
claude --cloud "Fix the flaky test in auth.spec.ts"
claude --cloud "Update the API documentation"
claude --cloud "Refactor the logger to use structured output"
```

`claude --cloud` 会按你当前所在的分支克隆你的 GitHub 远程仓库，因此请先推送本地提交。在 VM 启动期间，CLI 会实时显示一份设置步骤清单，并将你输入的任何内容排入队列。

> `claude --cloud` clones your GitHub remote at your current branch, so push your local commits first. While the VM starts, the CLI shows a live checklist of setup steps and queues anything you type.

把每个任务都写成一张自成一体的工单，写明问题出在哪里、完成是什么样子，以及如何证明已经完成。那个关于不稳定测试的提示词就点明了它的证明方式：连续运行测试套件至少 30 次。而该会话实际运行了 40 次。

> Write each task as a self-contained ticket that states what's wrong, what done looks like, and how to prove it. The flaky-test prompt named its proof: running the suite at least 30 times in a row. The session ran it 40 times.

当这些任务同属一项更大的工作时，**[项目](https://claude.com/blog/projects-redesigned)**（面向 Pro 和 Max 用户公开测试）会运行一个协调对话，替你启动并跟踪各个云端会话。随后，它会按状态对这些会话进行分组：进行中、等待你处理，以及可供审阅。

> When the tasks belong to one larger effort, a **[project](https://claude.com/blog/projects-redesigned)** (public beta for Pro and Max) runs a coordinator conversation that starts and tracks the cloud sessions for you. It then groups them by state: working, waiting on you, and ready for review.

##### 2. 让它证明修复有效

> 2. Let it prove the fix

不稳定测试（flaky test）最能说明哪类工作需要反复验证：你得一遍又一遍地运行整套测试，而你并不希望这个循环占用你正在工作的机器。在云端，Claude 修补了缓存，并用一条命令将整套测试运行了 40 次。

> A flaky test is the clearest case of work that needs repeated proof: you have to run the suite again and again, and you don't want that loop tying up the machine you're working on. In the cloud, Claude patched the cache and ran the whole suite 40 times in one command.

![The flaky-test session's Bash step: a patch to src/cache.js that caches the in-flight promise, then a loop running the test suite 40 times, with output runs=40 fails=0.](https://claude.dev/media/6ce551ccd1a1cd64a0f9c0fb8b8116e1ca1e260a9f5de861de798e0fe578afe6.png)

虚拟机不收取计算费用，而且它的 CPU 也不是你的，所以尽管要求它给出充分的证明。把测试套件跑 200 遍，在 50 个提交中二分定位一个回归问题，运行耗时较长的集成测试层，或者像那次文档会话那样启动应用并用 curl 去访问它。

> The VM has no compute charge and its CPU isn't yours, so ask for thorough proof. Run the suite 200 times, bisect a regression across 50 commits, run the slow integration tier, or start the app and hit it with curl the way the docs session did.

Claude 的每一轮仍会计入你的套餐用量，但在一条命令内运行一长串测试几乎不怎么消耗用量。[前台命令](https://code.claude.com/docs/en/cloud-environments)默认在 2 分钟后超时（最长 10 分钟），之后会转入后台继续运行，最多再运行 30 分钟。你可以在环境变量中通过 `BASH_DEFAULT_TIMEOUT_MS` 和 `BASH_MAX_TIMEOUT_MS` 调高这些默认值。

> Each of Claude's turns still counts toward your plan, but a long test run inside one command costs little. [Foreground commands](https://code.claude.com/docs/en/cloud-environments) time out after 2 minutes by default (10 at most) and then keep running in the background for up to 30 more. You can raise the defaults with `BASH_DEFAULT_TIMEOUT_MS` and `BASH_MAX_TIMEOUT_MS` in the environment's variables.

##### 3. 在桌前规划，在云端构建，在终端收尾

> 3. Plan at your desk, build in the cloud, finish in your terminal

对于较大的改动，先在来回沟通成本较低的阶段就方案达成一致。以计划模式启动 Claude，一起敲定计划，提交该计划，然后推送。

> For a larger change, agree on the approach first where back-and-forth is cheap. Start Claude in plan mode, work out the plan together, commit the plan, and push it.

```
claude --permission-mode plan
# ...agree on the plan, save it to docs/migration-plan.md, commit and push...
claude --cloud "Execute the migration plan in docs/migration-plan.md"
```

云端会话构建期间，你的终端可以腾出来处理其他工作。完成后，把会话拉取到本地，手动完成收尾。

> While the cloud session builds, your terminal is free for other work. When it's done, pull the session down to finish it by hand.

```
claude --teleport            # pick a cloud session
claude --teleport <session-id>
```

Teleport 会检查你是否位于同一个仓库中，拉取该会话的分支并检出，然后把整段对话加载到你的终端中。你的工作区必须是干净的（它会提议帮你 stash），而且该分支必须已经推送。在 Claude Code 内部，`/teleport`（或 `/tp`）会打开同一个选择器，先输入 `/tasks` 再输入 `t` 也同样可行。Desktop 应用则是反方向的，它的 **Open in** 菜单会把本地会话发送到云端。

> Teleport checks that you're in the same repository, fetches the session's branch, checks it out, and loads the whole conversation into your terminal. You need a clean working tree (it offers to stash), and the branch has to be pushed. From inside Claude Code, `/teleport` (or `/tp`) opens the same picker, and `/tasks` then `t` works too. The Desktop app goes the other way, and its **Open in** menu sends a local session to the cloud.

##### 4. 用手机随时查看进度

> 4. Check in from your phone

Claude 应用中的 Code 标签页连接的是同一批会话。你可以在手机上启动任务、跟进任务进展、引导任务方向、回答 Claude 提出的问题，或者让 Claude 盯着某个拉取请求。

> The Code tab in the Claude app connects to the same sessions. From your phone you can start a task, follow it, steer it, answer a question Claude asked, or tell Claude to watch a pull request.

手机适合用来问那些等你走到键盘前就会忘掉的问题。我给第四个会话提了一个通常会在键盘上敲出来的问题：tidepool 是如何预测潮汐的，在时间窗口的边界处又可能出什么问题？它运行代码来验证自己的答案，并发现了一个真实存在的 bug。循环从不检查第一个和最后一个样本，因此恰好落在窗口起点的高潮会被 API 漏掉。

> A phone suits questions you'd otherwise forget by the time you reach a keyboard. I gave a fourth session the kind of question you'd type on one: how does tidepool predict tides, and how could it go wrong at the edges of a time window? It ran code to check its answer and found a real bug. The loop never examines the first or last sample, so the API misses a high tide that falls exactly at the start of the window.

![Phone-width claude.ai/code showing the start of Claude's answer: predictTides has two edge problems, confirmed by running it, with a How it works section.](https://claude.dev/media/b07f3e2a23b519b872849b868c7ff83d07521d5e36a4fd7e9d4c0b0fb4f0701f.png)

![The end of the answer: a table of how often reported highs and lows had an equal-height neighbour per station, and the proposed fix.](https://claude.dev/media/350260c5c66006b458f3f1512cf039933643e404080ac8aaa8c0451b23374d51.png)

##### 5. 把 CI 失败和评审意见交给 Claude 处理

> 5. Hand CI failures and review comments to Claude

在仓库上安装 Claude GitHub App 后，云端会话可以监视某个拉取请求，并对其发生的变化做出响应。在 claude.ai/code 的会话中，从 CI 栏开启 **Auto-fix**。你也可以在终端中于该 PR 分支上运行 `/autofix-pr`，让移动应用监视该 PR，或者将 PR 的 URL 粘贴到会话中。

> With the Claude GitHub App installed on a repository, a cloud session can watch a pull request and act on what happens to it. From the CI bar in a session at claude.ai/code, turn on **Auto-fix**. You can also run `/autofix-pr` on the PR branch in your terminal, ask the mobile app to watch the PR, or paste the PR URL into a session.

对于失败的检查和评审意见，如果修复方案明确，Claude 会直接推送修复，并说明它做了哪些改动。遇到任何含糊不清或涉及架构的问题，它会向你询问。它在评审讨论串中的回复会以你的 GitHub 用户名发布，并标注为 Claude Code。Claude 不会收到与基础分支之间合并冲突的通知，因此需要你让它执行 rebase。它的评论也可能触发由评论驱动的自动化流程，例如 Atlantis。

> Claude pushes clear fixes for failing checks and review comments, and explains what it changed. It asks you about anything ambiguous or architectural. Replies on review threads post under your GitHub username, labeled as Claude Code. Claude doesn't get notified about merge conflicts with the base branch, so ask it to rebase. Its comments can also trigger comment-driven automation such as Atlantis.

##### 6. 无需亲自动手即可启动工作

> 6. Start work without starting it yourself

**例程**（研究预览版）是为完成某项任务而设计的一组已保存资源，例如提示词、代码仓库、连接器和环境。每次运行都是一个由触发器启动的云端会话。触发器可以是定时计划（最频繁为每小时一次）、对该例程专属端点的 HTTP 调用，或者 GitHub 事件，例如拉取请求被创建或发布新版本。你可以在 claude.ai/code/routines、桌面应用中创建例程，也可以在 CLI 中使用 `/schedule` 创建。例程运行时不会弹出审批提示，并且默认推送到以 `claude/` 为前缀的分支。

> A **routine** (research preview) is several saved resources designed to accomplish a task, such as a prompt, repositories, connectors, and an environment. Each run is a cloud session, started by a trigger. Triggers can be a schedule (hourly at most often), an HTTP call to the routine's own endpoint, or a GitHub event such as a pull request opening or a release. Create one at claude.ai/code/routines, in the Desktop app, or with `/schedule` in the CLI. Routines run without approval prompts, and by default they push to `claude/`-prefixed branches.

有两个较小的工具可以在这方面提供帮助。你可以在任何已登录的机器上（包括 CI 任务中）向正在运行的会话追加一条后续指令。

> Two smaller tools help here. You can queue a follow-up into a running session from any machine where you're logged in, including a CI job.

```
claude -p "The integration tier is green now; rebase on main and push" --cloud <session-id>
```

你还可以将预填好的会话加入书签。诸如 `claude.ai/code?prompt=Triage+the+newest+issues&repositories=acme-labs/tidepool` 这样的 URL 会打开 claude.ai/code，并且提示词和仓库都已预先填好。

> You can also bookmark a prefilled session. A URL such as `claude.ai/code?prompt=Triage+the+newest+issues&repositories=acme-labs/tidepool` opens claude.ai/code with the prompt and repository already filled in.

##### 7. 运行你不完全信任的代码

> 7. Run code you don't fully trust

贡献者提交的拉取请求、新依赖的安装脚本，或者你五分钟前刚克隆的仓库，都可能运行你没有读过的代码。在你的笔记本电脑上，这些代码就运行在你的 SSH 密钥、云 CLI 会话和浏览器配置文件旁边。而在云端会话中，它运行在一台用完即弃的虚拟机里，那里没有上述任何东西，只有一个仅限本次会话的 GitHub 凭据，以及一个你可以收紧访问范围的网络。

> A contributor's pull request, a new dependency's install script, or a repository you cloned five minutes ago can all run code you haven't read. On your laptop, that code runs next to your SSH keys, your cloud CLI sessions and your browser profile. In a cloud session it runs in a disposable VM with none of those, a session-scoped GitHub credential, and a network you can narrow.

若要以最严格的方式运行，请将环境的网络访问设置为 **None**；也可以保留 **Trusted**，该选项允许访问软件包仓库、GitHub 以及主要云 SDK 的主机。即使设置为 None，Claude Code 仍会向 Anthropic API 发送请求，因此数据仍可能经由这一途径离开虚拟机，并且会话仍可以推送到其自身的分支。所有出站流量都会经过一个记录主机名的代理。

> Set the environment's network access to **None** for the strictest run, or keep **Trusted**, which allows package registries, GitHub and the major cloud SDK hosts. Even at None, Claude Code still sends requests to the Anthropic API, so data can leave the VM that way, and the session can still push to its own branch. All outbound traffic passes through a proxy that logs hostnames.

#### 顺利连接 GITHUB，不再卡壳

> CONNECTING GITHUB WITHOUT GETTING STUCK

如果你的第一次云端会话出了问题，最可能的原因是 GitHub。大多数问题都源于云端会话需要两项彼此独立的 GitHub 权限。

> If your first cloud session goes wrong, GitHub is the most likely reason. Most problems come from cloud sessions needing two separate GitHub permissions.

- **使用 GitHub 登录**可以让 Claude 知道你是谁。
- 在某个账户或组织上**安装 Claude GitHub App**，即可设定 Claude 能在其中访问哪些私有仓库。

> • **Signing in with GitHub** tells Claude who you are.
> • **Installing the Claude GitHub App** on an account or organization sets which private repositories Claude can see there.

公共仓库只需第一项即可使用。私有仓库则需要第二项，且须安装在拥有该仓库的账户或组织上。如果你已连接 GitHub 却找不到某个私有仓库，通常是因为该 App 没有安装在拥有该仓库的账户或组织上。

> Public repositories work with the first alone. Private repositories need the second, on whichever account or organization owns them. If you connected GitHub and a private repository is missing, the App usually isn't installed on the account or organization that owns it.

| 你已连接的内容 | 公开仓库 | 你的私有仓库 | 组织的私有仓库 | 自动修复、GitHub 触发器与项目 |
| --- | --- | --- | --- | --- |
| 仅通过 GitHub 登录 | 是 | 否 | 否 | 否 |
| + 个人账户中的应用 | 是 | 是 | 否 | 你的仓库 |
| + 安装在组织上的 App（由所有者批准） | 是 | 仅当也存在于你的账户中时 | 是 | 组织仓库 |
| /web-setup（你的 gh 令牌） | 是 | 是 | 你的令牌能访问到的任何内容 | 不支持，需要使用 App |

> 英文原表 / English original

| What you've connected | Public repos | Your private repos | An org's private repos | Auto-fix, GitHub triggers, projects |
| --- | --- | --- | --- | --- |
| Signed in with GitHub only | Yes | No | No | No |
| + App on your personal account | Yes | Yes | No | Your repos |
| + App on the organization (owner approves) | Yes | Only if also on your account | Yes | Org repos |
| /web-setup (your gh token) | Yes | Yes | Whatever your token can reach | No, needs the App |

##### 路径 A：在浏览器中连接（推荐）

> Path A: connect in the browser (recommended)

在 [claude.ai/connect-github](https://claude.ai/connect-github) 关联你的 GitHub 账户，然后在拥有该仓库的账户或组织上安装 Claude GitHub App。如果是组织，通常需要由所有者批准安装。[快速入门](https://code.claude.com/docs/en/web-quickstart)会逐步介绍每个步骤。

> Connect your GitHub account at [claude.ai/connect-github](https://claude.ai/connect-github), then install the Claude GitHub App on the account or organization that owns your repository. For an organization, an owner usually has to approve the install. The [quickstart](https://code.claude.com/docs/en/web-quickstart) walks through each step.

![The Code with Claude anywhere screen with a Connect to GitHub button.](https://claude.dev/media/ff85ccc8f6a5ae3f2212014490ad5850c9bdb622908e85b8e33a8177cfc18942.png)

![The Connect your repositories screen asking you to install the Claude GitHub App on your repositories, with Skip and Connect repositories buttons.](https://claude.dev/media/84004dce66bdcb7f9b4529e584e715f5d6e3d3930409689ca48df28aac45e685.png)

如果 GitHub 没有将你跳转回 claude.ai/code，可以在 [claude.ai/connect-github](https://claude.ai/connect-github) 连接页面查看一份简短的检查清单，其中列出了常见原因。其中之一是单点登录（SSO）步骤：如果跳过这一步，组织的仓库将不会显示。

> If GitHub doesn't send you back to claude.ai/code, the connect page at [claude.ai/connect-github](https://claude.ai/connect-github) can show a short checklist for the usual causes. One of them is the single sign-on step, which hides an organization's repositories if you skip it.

![The Didn't finish connecting screen with five tips: sign in to the right GitHub account, authorize each organization on the single sign-on step, start again if you saw GitHub connection not completed, connect your own account first and let an owner approve organization access later, or run /web-setup from the terminal.](https://claude.dev/media/0855b55ac62191f9b92cd9f5f1d5ab2d8181b03eb155678dd859cc7c8f8722ed.png)

自动修复、由 GitHub 触发的例程以及项目功能同样依赖该 App，因此即使你通过其他方式连接，也请安装它。

> Auto-fix, GitHub-triggered routines and projects also depend on the App, so install it even if you connect another way.

##### 路径 B：在终端中通过 /web-setup 连接

> Path B: connect from your terminal with /web-setup

如果你已经在使用 `gh` CLI，可以在 Claude Code 中运行 `/web-setup`，将你的 `gh` 令牌发送到你的 Claude 账户。之后，无论是否安装该 App，会话都可以访问该令牌有权访问的任何仓库。具体步骤请参阅[从终端连接](https://code.claude.com/docs/en/web-quickstart#connect-from-your-terminal)。在 Team 和 Enterprise 套餐中，需要先由所有者开启[快速设置](https://code.claude.com/docs/en/claude-code-on-the-web#quick-setup-for-team-and-enterprise)。

> If you already use the `gh` CLI, run `/web-setup` inside Claude Code to send your `gh` token to your Claude account. Sessions can then reach any repository that token can, with or without the App. See [Connect from your terminal](https://code.claude.com/docs/en/web-quickstart#connect-from-your-terminal) for the walkthrough. On Team and Enterprise plans, an owner has to turn on [Quick setup](https://code.claude.com/docs/en/claude-code-on-the-web#quick-setup-for-team-and-enterprise) first.

##### 路径 C：一次性任务可跳过 GitHub

> Path C: skip GitHub for a one-off

在没有 GitHub 远程仓库、或未安装该 App 的仓库中运行 `claude --cloud`，Claude Code 会上传仓库的打包文件，而不是克隆仓库。只有当你的 GitHub 连接对该仓库拥有推送权限时，会话才能将更改推送回去。文档中列出了[打包文件包含和不包含的内容](https://code.claude.com/docs/en/claude-code-on-the-web#send-local-repositories-without-github)。

> Run `claude --cloud` in a repository that has no GitHub remote, or one where the App isn't installed, and Claude Code uploads a bundle of your repository instead of cloning it. The session can push back only if your GitHub connection has push access to that repository. The docs list [what the bundle includes and leaves out](https://code.claude.com/docs/en/claude-code-on-the-web#send-local-repositories-without-github).

##### 如果你使用的是 Team 或 Enterprise 版

> If you run Team or Enterprise

所有者只需完成一份简短的清单：在 [claude.ai/admin-settings/connectors](https://claude.ai/admin-settings/connectors) 开启 GitHub 连接器，在 [Claude Code 管理设置](https://claude.ai/admin-settings/claude-code)中允许云端会话，在组织的代码仓库上安装 Claude GitHub App（或批准成员的安装请求），并决定是否开启[快速设置](https://code.claude.com/docs/en/claude-code-on-the-web#quick-setup-for-team-and-enterprise)。使用 IP 白名单或 GitHub Enterprise Server 的组织还需额外一步。请参阅关于 [IP 白名单](https://code.claude.com/docs/en/claude-code-on-the-web#limitations)和 [GitHub Enterprise Server](https://code.claude.com/docs/en/github-enterprise-server) 的文档。

> An owner has a short checklist: turn on the GitHub connector at [claude.ai/admin-settings/connectors](https://claude.ai/admin-settings/connectors), allow cloud sessions in the [Claude Code admin settings](https://claude.ai/admin-settings/claude-code), install the Claude GitHub App on the organization's repositories (or approve members' requests), and decide whether to turn on [Quick setup](https://code.claude.com/docs/en/claude-code-on-the-web#quick-setup-for-team-and-enterprise). Organizations with IP allowlists or GitHub Enterprise Server have an extra step. See the docs on [IP allowlists](https://code.claude.com/docs/en/claude-code-on-the-web#limitations) and [GitHub Enterprise Server](https://code.claude.com/docs/en/github-enterprise-server).

##### 如果仍然不起作用

> When it still doesn't work

| 你看到的内容 | 为什么 | 修复 |
| --- | --- | --- |
| 选择器中缺少某个私有仓库 | 该 App 未安装在拥有该仓库的账户或组织上，或者其仓库访问权限未包含该仓库 | 在那里安装该 App，或在 GitHub 设置中将该仓库添加到该 App 的 Repository access（仓库访问权限）中 |
| 一条错误提示，表示你必须是该组织的所有者才能关联它 | 组织阻止了成员资格检查，通常是因为存在待处理的 App 权限请求、IP 允许列表或 SAML 单点登录 | 组织所有者在组织的 GitHub App 设置中接受待处理的权限请求，为已安装的 GitHub App 启用 IP 允许列表继承，或者（在 SAML 下）授予 Claude 访问该组织的权限 |
| 刚连接后，某个组织的仓库缺失 | 该组织使用 SAML 单点登录，而其授权步骤被跳过了 | 在 GitHub 的“Single sign-on to your organizations”步骤中，请先点击每个组织旁边的 Authorize，然后再继续。如果你已经跳过了这一步，请在 GitHub 设置中为该组织授权 Claude，然后重新连接 |
| 每个云端会话都因身份验证错误而失败 | 你的 Claude 组织使用了 IP 允许列表 | 请求支持团队将 Anthropic 托管的服务列为豁免项 |

> 英文原表 / English original

| What you see | Why | Fix |
| --- | --- | --- |
| A private repository is missing from the picker | The App isn't installed on the account or organization that owns it, or its repository access excludes it | Install the App there, or add the repository to the App's Repository access in your GitHub settings |
| An error saying you must be an owner of the organization to link it | The organization blocked a membership check, usually because of a pending App permission request, an IP allow list, or SAML single sign-on | An owner accepts the pending permission request in the organization's GitHub App settings, turns on IP allow list inheritance for installed GitHub Apps, or (under SAML) grants Claude access to the organization |
| An organization's repositories are missing right after you connect | The organization uses SAML single sign-on, and its authorization step was skipped | On GitHub's "Single sign-on to your organizations" step, click Authorize next to each organization before you continue. If you already skipped it, authorize Claude for that organization in your GitHub settings, then reconnect |
| Every cloud session fails with an authentication error | Your Claude organization uses IP allowlisting | Ask support to exempt Anthropic-hosted services |

如遇其他问题，请参阅文档中的[故障排除](https://code.claude.com/docs/en/claude-code-on-the-web#troubleshooting)部分，其中包括[连接 GitHub 后未显示任何仓库](https://code.claude.com/docs/en/web-quickstart#no-repositories-appear-after-connecting-github)的情况。如需完全断开与 GitHub 的连接，请前往 claude.ai/customize/connectors。

> For anything else, see [troubleshooting](https://code.claude.com/docs/en/claude-code-on-the-web#troubleshooting) in the docs, including [no repositories appearing after you connect GitHub](https://code.claude.com/docs/en/web-quickstart#no-repositories-appear-after-connecting-github). To disconnect GitHub entirely, use claude.ai/customize/connectors.

#### 为会话提供自检工作所需的一切

> GIVE SESSIONS WHAT THEY NEED TO CHECK THEIR OWN WORK

能够运行测试的会话，会在交还工作之前先检查自己的成果。否则，你审查的就是没人运行过的改动。本指南演示中的大部分价值都来自 Claude 实际运行的东西：把测试套件跑了 40 遍，启动服务器并执行 curl 请求，在窗口边缘计算潮汐。花十分钟配置环境，就能让 Claude 有办法运行这些检查。

> A session that can run your tests checks its own work before it hands the work back. Without that, you review changes nobody has run. Most of the value in this guide's demos came from Claude running things: the suite 40 times, the server and its curls, the tide calculation at the window's edge. Ten minutes of environment setup gives Claude a way to run those checks.

![The Add cloud environment dialog with the name tidepool, Trusted network access, LOG_LEVEL=debug, and a setup script that installs shellcheck with apt-get.](https://claude.dev/media/aba93ba97b08d40ee9705338d22e861ed592cc8a7e32b8ddd715b6545b3c4fcd.png)

- **从默认环境开始。**它使用“受信任”网络访问，不设变量，也没有设置脚本，足以满足大多数 JavaScript、Python、Go 和 Rust 仓库的需求。
- **为机器使用 setup 脚本。**它会在 Claude Code 启动之前以 root 身份运行，因此 `apt install` 可以正常执行。脚本必须以 0 退出，否则会话将无法启动；而且它应在大约五分钟内完成，以便环境能够被缓存。此后，新会话会从快照启动，你的工具已经在磁盘上就绪。当你修改脚本或允许的主机时，缓存会重新构建；此外大约每七天也会重建一次。
- **为项目使用 SessionStart hook。**将 `npm install` 及类似步骤放入仓库 `.claude/settings.json` 中的 hook，使其在本地和云端以相同方式运行。如果某个步骤只应在云端运行，请检查 `CLAUDE_CODE_REMOTE`。仓库 hook 会在单仓库会话中加载。
- **在每个会话中启动服务。**缓存保存的是文件，之前运行中的进程不会随缓存保留下来。可以让 Claude 运行 `service postgresql start`，或者在 SessionStart 钩子中执行。
- **选择能满足需求的最窄网络级别。**Trusted 涵盖常用的软件包仓库。使用 Custom 添加私有仓库，仅当任务需要访问开放互联网时才使用 Full。更改会在大约一分钟内同步到正在运行的会话。
- **不要把密钥放在共享变量中。**环境变量对使用该环境的所有人都可见。在 Pro 和 Max 套餐中，环境的 API 凭据会在虚拟机之外为发往你指定主机的请求附加密钥，因此密钥永远不会存放在变量中。
- **把命令写进 CLAUDE.md。**你个人的 `~/.claude` 不会同步到云端虚拟机。如果 Claude 需要知道如何运行集成测试，就必须由代码仓库本身写明。

> • **Start with the Default environment.** It uses Trusted network access, no variables and no setup script, which is enough for most JavaScript, Python, Go and Rust repositories.
> • **Use a setup script for the machine.** It runs as root before Claude Code starts, so `apt install` works. It must exit 0 or the session won't start, and it should finish within about five minutes so the environment gets cached. After that, new sessions start from a snapshot with your tools on disk. The cache rebuilds when you change the script or the allowed hosts, and about every seven days.
> • **Use a SessionStart hook for the project.** Put `npm install` and similar steps in a hook in the repository's `.claude/settings.json`, so they run the same way locally and in the cloud. Check `CLAUDE_CODE_REMOTE` if a step should run only in the cloud. Repository hooks load in single-repository sessions.
> • **Start services per session.** The cache stores files. Processes that were running don't survive it. Ask Claude to run `service postgresql start`, or do it in a SessionStart hook.
> • **Pick the narrowest network level that works.** Trusted covers the common registries. Use Custom to add a private registry, and Full only when the task needs the open internet. Changes reach running sessions within about a minute.
> • **Keep secrets out of shared variables.** Environment variables are visible to anyone who uses the environment. On Pro and Max, an environment's API credentials attach a key to requests for the hosts you name, outside the VM, so the key never sits in a variable.
> • **Put the commands in CLAUDE.md.** Your personal `~/.claude` doesn't reach the cloud VM. If Claude needs to know how to run the integration tests, the repository has to say so.

#### 值得养成的习惯

> HABITS THAT PAY OFF

- **一个任务，一个会话。**小而独立的会话更易于审查，丢弃的成本也更低。
- **要求提供证据。**指明能证明任务已完成的命令，并在查看 diff 之前先阅读 Claude 的总结。
- **在 `claude --cloud` 之前先推送。**虚拟机是从 GitHub 克隆代码的，因此未推送的提交不会同步到虚拟机上。
- **执行长任务时，请边做边提交。**空闲的虚拟机可能会被回收。
- **在差异视图中审查。**行内评论会被汇总到你的下一条消息中，而**Create PR**可以创建完整的 PR、草稿 PR，或打开 GitHub 的撰写页面。
- **在 Claude 工作时进行引导。**在 Claude 工作期间发送的消息会进入队列，你也可以撤回已排队的消息。
- **共享会话。**在 Team 和 Enterprise 版本中，将会话的可见性设置为 Team，这样审阅者就能查看变更是如何完成的。来自云端会话的提交会带有 `Claude-Session` trailer，可链接回对应的会话记录。
- **注意用量限制。**并行会话会同时消耗你的套餐额度，因此五个会话的消耗速度大约是一个会话的五倍。例行任务（Routines）有各自的每小时上限，而[项目](https://code.claude.com/docs/en/claude-projects)每天最多可以启动 200 个新线程。

> • **One task, one session.** Small, separate sessions are easier to review and cheaper to throw away.
> • **Ask for evidence.** Name the command that proves the task is done, and read Claude's summary before the diff.
> • **Push before `claude --cloud`.** The VM clones from GitHub, so unpushed commits don't reach it.
> • **Commit as you go on long tasks.** Idle VMs can be reclaimed.
> • **Review in the diff view.** Inline comments are batched into your next message, and **Create PR** can open a full PR, a draft, or GitHub's compose page.
> • **Steer while Claude works.** Messages you send while Claude works queue up, and you can take a queued one back.
> • **Share the session.** On Team and Enterprise, set a session's visibility to Team so a reviewer can read how the change was made. Commits from cloud sessions carry a `Claude-Session` trailer that links back to the transcript.
> • **Watch your limits.** Parallel sessions draw on your plan limits in parallel, so five sessions use them about five times as fast as one. Routines have their own hourly caps, and [projects](https://code.claude.com/docs/en/claude-projects) can start up to 200 new threads a day.

#### 常见问题

> COMMON QUESTIONS

**谁可以使用云端会话？**使用 claude.ai 账号登录的 Pro、Max 和 Team 套餐用户，以及拥有高级席位或 Chat + Claude Code 席位的 Enterprise 用户。使用 Console API 密钥或第三方提供商时无法使用云端会话。请参阅[云端会话文档](https://code.claude.com/docs/en/claude-code-on-the-web)。

> **Who can use cloud sessions?** Pro, Max, and Team plans, and Enterprise users with a premium seat or a Chat + Claude Code seat, signed in with a claude.ai account. They aren't available with a Console API key or a third-party provider. See the [cloud sessions docs](https://code.claude.com/docs/en/claude-code-on-the-web).

**我的数据会存储到哪里？**Anthropic 会存储会话记录，保留时长取决于你的套餐和模型改进设置。虚拟机在闲置一段时间后会被回收，删除会话即会移除其数据。请参阅[数据使用](https://code.claude.com/docs/en/data-usage)和[安全](https://code.claude.com/docs/en/security)。

> **Where does my data go?** Anthropic stores the session transcript, and how long it's kept depends on your plan and model-improvement setting. VMs are reclaimed after inactivity, and deleting a session removes its data. See [data usage](https://code.claude.com/docs/en/data-usage) and [security](https://code.claude.com/docs/en/security).

**Claude 会使用我的云端会话数据进行训练吗？**云端会话遵循与 Claude Code 其他部分相同的政策。在 Team、Enterprise 和 API 方案下，除非你的组织选择加入，否则 Anthropic 不会使用你的代码或提示词训练模型。在 Free、Pro 和 Max 方案下，这取决于你的[模型改进设置](https://claude.ai/settings/data-privacy-controls)。请参阅[数据使用](https://code.claude.com/docs/en/data-usage)。

> **Will Claude train on my cloud sessions data?** Cloud sessions follow the same policy as the rest of Claude Code. On Team, Enterprise, and the API, Anthropic doesn't train models on your code or prompts unless your organization opts in. On Free, Pro, and Max, it depends on your [model-improvement setting](https://claude.ai/settings/data-privacy-controls). See [data usage](https://code.claude.com/docs/en/data-usage).

**它能处理我的大型仓库吗？**该虚拟机大约有 4 个 vCPU、16 GB 内存和 30 GB 磁盘。请把耗时较长的安装步骤放在[设置脚本](https://code.claude.com/docs/en/cloud-environments#setup-scripts)中，这样它们只需运行一次，并会保存到缓存快照中。

> **Will it handle my large repository?** The VM has about 4 vCPUs, 16 GB of RAM, and 30 GB of disk. Put heavy installs in a [setup script](https://code.claude.com/docs/en/cloud-environments#setup-scripts) so they run once and land in the cached snapshot.

**GitLab 或 Bitbucket 呢？** `claude --cloud` 可以从任意 git 仓库上传 bundle，但会话无法推送回这些托管平台。Team 和 Enterprise 方案支持 [GitHub Enterprise Server](https://code.claude.com/docs/en/github-enterprise-server)。请参阅[平台限制](https://code.claude.com/docs/en/claude-code-on-the-web#limitations)。

> **What about GitLab or Bitbucket?** `claude --cloud` can upload a bundle from any git repository, but the session can't push back to those hosts. [GitHub Enterprise Server](https://code.claude.com/docs/en/github-enterprise-server) is supported on Team and Enterprise. See the [platform restrictions](https://code.claude.com/docs/en/claude-code-on-the-web#limitations).

**并行分支发生冲突时会怎样？**这些会话彼此并不知情。先合并一个分支，然后[向下一个会话发送一条后续消息](https://code.claude.com/docs/en/claude-code-on-the-web#send-follow-ups-from-the-cli)，例如 `claude -p "rebase on main and fix any conflicts" --cloud <session-id>`。

> **What happens when parallel branches conflict?** The sessions don't know about each other. Merge one branch, then [send the next session a follow-up](https://code.claude.com/docs/en/claude-code-on-the-web#send-follow-ups-from-the-cli) such as `claude -p "rebase on main and fix any conflicts" --cloud <session-id>`.

**我会失去本地工具吗？**用户级配置不会随会话迁移，因此请把团队需要的内容移到仓库中：将技能和命令提交到 `.claude/` 下，将项目级 MCP 服务器添加到 `.mcp.json`，并在 `CLAUDE.md` 中记录测试命令。[云端会话中的设置](https://code.claude.com/docs/en/settings#settings-in-cloud-sessions)列出了每个会话会读取哪些内容。

> **Will I lose my local tools?** User-level config doesn't travel, so move what the team needs into the repository: commit skills and commands under `.claude/`, add project-scoped MCP servers to `.mcp.json`, and document test commands in `CLAUDE.md`. [Settings in cloud sessions](https://code.claude.com/docs/en/settings#settings-in-cloud-sessions) lists what each session reads.

#### 五分钟内开始

> START IN FIVE MINUTES

设置只需大约五分钟。之后，你就可以把任务交出去，合上笔记本电脑，回来时便会看到一个可供审查的分支。

> Setup takes about five minutes. After that, you can hand off a task, close your laptop, and come back to a branch that's ready for review.

1. 打开 claude.ai/code，或使用你的 claude.ai 账号在 Claude Code 中运行 `/login`。
2. 连接 GitHub，并在你的代码仓库所在的位置安装 Claude GitHub App。
3. 选择仓库和 Default 环境。
4. 从你的待办事项中挑一个任务交给 Claude，并附上一条能证明任务已完成的命令。
5. 关闭标签页。稍后用手机查看进度，然后在 claude.ai/code 上审阅 diff 并创建 pull request。

> 1\. Open claude.ai/code, or run `/login` in Claude Code with your claude.ai account.
> 2\. Connect GitHub and install the Claude GitHub App where your repository lives.
> 3\. Pick the repository and the Default environment.
> 4\. Give Claude one task from your backlog, with a command that proves it's done.
> 5\. Close the tab. Check in from your phone later, then review the diff and create the pull request at claude.ai/code.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Cloud session | 云端会话 | 在 Anthropic 托管或自托管基础设施的专属虚拟机上运行的 Claude Code 会话。 |
| Worktree | 工作树 | Git 仓库中检出文件所在的工作目录，可通过 git worktree 为同一仓库创建多个。 |
| Flaky test | 不稳定测试 | 在代码不变的情况下时而通过、时而失败的测试。 |
| Race condition | 竞态条件 | 程序结果依赖于并发操作执行时序而产生的错误。 |
| Teleport | Teleport（会话传送） | 将云端会话的分支和对话记录拉取到本地终端继续工作的功能。 |
| Plan mode | 计划模式 | Claude Code 中先制定并确认方案、暂不修改代码的工作模式。 |
| Auto-fix | 自动修复 | 让云端会话监视拉取请求并自动响应 CI 失败和评审意见的功能。 |
| Routine | 例程 | 由定时、HTTP 调用或 GitHub 事件触发运行的已保存云端任务配置。 |
| GitHub App | GitHub 应用 | 安装在账户或组织上、授予对指定仓库访问权限的 GitHub 集成。 |
| Setup script | 设置脚本 | 在 Claude Code 启动前以 root 身份运行、结果可缓存为快照的环境初始化脚本。 |
| SessionStart hook | 会话启动钩子 | 在每个会话开始时执行的仓库级命令，可在本地和云端以相同方式运行。 |
| Git bundle | Git 打包文件 | 将仓库对象和引用打包成单个文件以便在无远程仓库时传输。 |
| Zero Data Retention | 零数据保留 | 不保留用户数据的组织级策略，启用后云端会话会被关闭。 |
| Self-hosted environment | 自托管环境 | 在组织自有基础设施上运行云端会话、可访问私有网络的部署方式。 |
| Trailer | 提交尾注 | 附加在 Git 提交信息末尾的键值元数据行。 |
