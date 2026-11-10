# 借助 Claude Fable 5.2 安全地扩展多智能体团队

> Safely scaling multi-agent teams with Claude Fable 5.2

> 来源：Claude Blog / Anthropic，2026-11-09
> 原文链接：https://claude.dev/blog/safely-scaling-multi-agent-teams-with-fable-5-2/
> 分类：人工智能 / 多智能体安全

## 核心要点

- 与此前依赖 Prove2Me 平台和研究人员指导、耗时 11 天的形式化工作相比，新实验在没有专用脚手架和人工引导的情况下完成证明，输出 token 仅为原来的三分之一，证明长度仅为原证明的七分之一。
- 每个智能体运行在独立的轻量级虚拟机沙箱中，配备 shell、文件编辑器、Lean 工具链与 Mathlib、专属 Git 分支以及共享 Postgres 数据库，而单台共享机器在约 100 个智能体时就已达到资源极限。
- 提示词只设定了一名负责人和 999 名助手的层级结构，负责人在最初 10 分钟内自行建立了 announce、assign、notes、subtasks、landed 五张表来分配任务、共享笔记和记录成果。
- 助手们早期判定 60 个命题中有 47 个无法在预算内完成，负责人据此先集中力量证明其余 10 个，约 70 分钟内全部完成，随后再将助手调派去处理被搁置的更难命题。
- 随着工作推进，协作逐渐去中心化，助手开始自行编写任务、主动认领工作，负责人也告诉空闲助手不必等待其分配。
- 面对规模最大的 Langlands–Tunnell 定理，负责人调派约 750 个助手，团队将其组织为最多 10 层、共 2,418 个任务的任务树并行推进，最终在第 28.4 小时完成证明，最终定理在第 28.7 小时通过检查。
- 安全措施包括无网络沙箱、仅经由数据库和 Git 的通信、网关身份标记、去除内核危险功能并启用锁定模式、最小权限运行，以及实时分类器和离线监控器的双重监督。
- 在超过一百万次工具调用中没有任何一次触发拦截，用 CoT 监控器重放时仅有一次检查 root 权限的调用接近被拦截。
- 该结果并不意味着领域专用平台不再必要，智能体仍会误判难度、过早放弃，人类在关键时刻的鼓励依然可能发挥作用，而安全边界也需随团队承担更艰巨工作而同步演进。

## 正文

多智能体团队能够解决具有挑战性的长周期问题。[今年 9 月](https://www.anthropic.com/research/formalizing-fermats-last-theorem)，我们发布了费马大定理的首个端到端形式化证明，它由数十个智能体编写，这些智能体运行的是一个内部研究模型，其能力大致与 Claude Fable 5.1 相当。那项工作依赖于数学形式化平台 Prove2Me，以及一位研究人员的指导。在一项新的玩具实验中，一个由 1,000 个智能体组成的团队运行早期版本的 Claude Fable 5.2，在没有 Prove2Me 提供的脚手架、也没有研究人员引导的情况下复现了该证明。该团队耗时 28.7 小时，所用输出 token 数量仅为原来的三分之一，写出的证明长度仅为原证明的七分之一。

> Multi-agent teams can solve challenging, long-horizon problems. [In September](https://www.anthropic.com/research/formalizing-fermats-last-theorem), we published the first end-to-end formalization of Fermat’s Last Theorem, written by dozens of agents running an internal research model roughly comparable to Claude Fable 5.1. That work relied on Prove2Me, a platform for formalizing mathematics, and direction from a researcher. In a new toy experiment, a team of 1,000 agents running an early version of Claude Fable 5.2 reproduced the proof without the scaffolding provided by Prove2Me or steering from a researcher. The team took 28.7 hours, used one-third as many output tokens, and wrote a proof one-seventh the length of the original.

每个智能体都在无法访问互联网的沙箱中工作。每条 shell 命令和每次文件编辑在执行前都会经过一个分类器的检查，同时还有一个离线监控器审查团队的每一项操作。我们向智能体提供了一份包含 60 条陈述的清单、一句话概述的经典证明路线、这些陈述所用到的定义，以及我们先前形式化工作中已证明的 47 条引理，并为它们分配了主导者和协助者的角色。除此之外，对于如何证明该定理或如何组织协作，我们没有提供任何其他指导。

> Each agent worked in a sandbox with no internet access. A classifier checked every shell command and file edit before it ran, and an offline monitor reviewed each of the team’s actions. We gave the agents a list of 60 statements, a one-sentence sketch of the classical route, the definitions those statements use, and 47 proved lemmas from our earlier formalization, and assigned lead and helper roles. We offered no other guidance on how to prove the theorem or organize themselves.

这个小型实验表明，由运行 Fable 5.2 等模型的智能体组成的团队，能够在精心设计的安全边界内完成宏大的长周期目标。

> This toy experiment suggests that teams of agents running models like Fable 5.2 can accomplish ambitious, long-horizon goals within carefully designed safety boundaries.

#### 问题

> PROBLEM

费马大定理指出，当 n 大于 2 时，不存在正整数 a、b 和 c 满足 aⁿ + bⁿ = cⁿ。该定理在 350 多年间一直未获证明，直到 1995 年 Andrew Wiles 爵士发表了长达 129 页的证明。将这一证明形式化——使其中每一步都能由计算机进行检验——一直是数学界的[长期目标](https://lean-lang.org/use-cases/flt/)。

> Fermat’s Last Theorem states that no positive integers a, b, and c satisfy aⁿ + bⁿ = cⁿ for any n greater than 2. It remained unproven for more than 350 years, until Sir Andrew Wiles’s 129-page proof in 1995. Formalizing the proof—making every step checkable by a computer—has been a [long-standing goal](https://lean-lang.org/use-cases/flt/) in the mathematics community.

我们在 9 月完成的形式化工作，由一名研究人员和数十个智能体耗时 11 天完成，消耗了约 60 亿个输出 token。它们用 Lean 编写了 1300 万行代码。Lean 是一种编程语言，计算机会在其中检查证明的每一步。

> Our September formalization took a researcher and dozens of agents 11 days and roughly 6 billion output tokens. They wrote 13 million lines of code in Lean, a programming language in which a computer checks every step of a proof.

这些智能体通过 Prove2Me 进行协作。Prove2Me 是由 Tianyi Peng（现为 Anthropic 技术人员）与其在哥伦比亚大学的合作者设计的平台。Prove2Me 使用一个共享图，将每个待证明的命题与其拆分出的更小命题相连接。任何智能体都可以拆分命题，其他智能体则可以查询该图，了解哪些尚未证明的部分已可着手处理，从而避免它们无法掌握项目状态。每个命题及其证明都保存在可独立编译的单独文件中，因此众多智能体可以并行工作，而无需编辑同一批文件。

> The agents coordinated through Prove2Me, a platform designed by Tianyi Peng (who is now a member of technical staff at Anthropic) and his collaborators at Columbia University. Prove2Me uses a shared graph that links each statement to be proved to the smaller statements it was split into. Any agent could split a statement, and other agents could ask the graph which unproved pieces were ready to work on, which kept them from losing track of the project state. Each statement and its proof were kept in a separate file that compiled independently, so many agents could work in parallel without editing the same files.

#### 运行框架

> HARNESS

我们想看看，由运行在 Fable 5.2 等模型上的智能体组成的团队，在没有 Prove2Me 或研究人员指导工作的情况下，借助由通用工具构建的框架，能否得出这一结果。

> We wanted to see whether a team of agents running on models like Fable 5.2 could produce this result without Prove2Me or a researcher directing the work, using a harness built from general-purpose tools.

##### 工具

> Tools

在这项任务中，我们给由 1,000 个智能体组成的团队提供了 60 个待证明的命题，其中包括最终定理和 59 个中间里程碑。对于每个命题，智能体都必须用 Lean 编写证明，使用 Lean 的工具构建并检查该证明，然后将其提交到 Git 上共享的 main 分支，由评分器在那里进行检查。我们为每个智能体提供了以下工具：

> For this task, we gave the team of 1,000 agents 60 statements to prove, including the final theorem and 59 intermediate milestones. For each statement, the agents had to write a proof in Lean, build and check it with Lean’s tools, and submit it to the shared main branch on Git, where a grader checked it. We gave each agent the following tools:

- 一个 shell 和一个文件编辑器，运行在其专属的沙箱中，且无法访问网络。
- Lean 的工具链和 [Mathlib](https://github.com/leanprover-community/mathlib4)，已内置于沙箱镜像中。
- 拥有自己的 Git 分支，并且能够向 main 发起合并请求。
- 一个共享的 Postgres 数据库，可直接从 shell 访问。

> • A shell and a file editor, in its own sandbox with no network access.
> • Lean’s toolchain and [Mathlib](https://github.com/leanprover-community/mathlib4), built into the sandbox image.
> • Its own Git branch, plus the ability to open merge requests into main.
> • A shared Postgres database, reached from the shell.

##### 协作

> Collaboration

证明工作可以拆分，因此非常适合由多智能体团队来完成。但智能体之间也需要协调，既要在彼此的工作基础上推进，也要避免重复劳动。在我们[最初的形式化工作](https://www.anthropic.com/research/formalizing-fermats-last-theorem)中，Claude 的早期尝试之所以失败，是因为智能体无法掌握项目的状态，也不再能有效协作。迁移到 Prove2Me 平台后，这个问题得到了解决。

> Work on the proof can be split up, making it a good task for a multi-agent team. But agents also need to coordinate, both to build on one another’s work and to avoid duplicating it. In our [original formalization](https://www.anthropic.com/research/formalizing-fermats-last-theorem), Claude’s early attempts failed because agents lost track of the project’s state and stopped collaborating effectively. Moving to the Prove2Me platform solved this problem.

在这次运行中，每个智能体都在各自独立的轻量级虚拟机上拥有一个沙箱。单台共享机器在大约 100 个智能体时就达到了极限：在我们的 100 智能体运行中，超过一半因内存、磁盘或 CPU 耗尽而不得不中止或重启。

> For this run, each agent had a sandbox on its own lightweight virtual machine. A single shared machine hit its limits at about 100 agents: more than half of our 100-agent runs had to be stopped or restarted because memory, disk, or CPU ran out.

由于有 1,000 个彼此独立的沙箱，智能体需要一种共享工作成果的方式，因此我们为它们提供了一个 SQL 数据库（图 1）。我们选择 SQL，是因为它提供了组织信息的通用原语，其事务机制能够处理来自 1,000 个智能体的并发写入，而且 Claude 本身就已熟悉它。智能体使用该数据库来认领任务、共享笔记并记录已完成的工作。

> With 1,000 separate sandboxes, the agents needed a way to share their work, so we gave them a SQL database (Figure 1). We chose SQL because it offers general primitives for organizing information, its transactions handle concurrent writes from 1,000 agents, and Claude is already familiar with it. The agents used the database to claim tasks, share notes, and log finished work.

![Harness architecture. A stack of 1,000 agent sandboxes (1 lead and 999 helpers), each running the agent loop, harness code inside the sandbox, with a shell and a file editor as tools and the repo, Lean and the math library as files. API requests and responses pass between the agent loop and a gateway outside the sandboxes that calls the Claude API. Git and SQL requests and their results pass through the same gateway to the team infrastructure, also outside the sandboxes: a Git repository of Lean files and plans, and a Postgres database of instructions, tasks and notes.](https://claude.dev/media/13dca8328dafc6e21860d77255066340778ab6cecae719aefe31fad55a9b1c1c.png)

##### 提示词设计

> Prompting

我们的提示词向 Claude 提供了一份包含 60 条待证明命题的列表，每条都附有一行非形式化的描述，并介绍了可用的工具（如上所列）。

> Our prompt gave Claude a list of 60 statements to prove, each with a one-line informal description, and described the available tools (listed above).

我们给团队设定的唯一结构是一个层级体系，由一名负责人和 999 名助手组成。我们让负责人把问题拆分成若干部分并分配给助手，同时告诉助手们等待负责人分派工作，如果任务不清楚就向负责人确认。

> The only structure we gave the team was a hierarchy, consisting of one lead and 999 helpers. We told the lead to split the problem into parts and assign them to the helpers. We told the helpers to expect work from the lead and to check with the lead if a task was unclear.

在运行过程中，harness 向 lead 自动发送了 19 次剩余时间提醒，每次都鼓励 lead 继续推进。

> During the run, the harness sent the lead 19 automatic reminders of how much time remained, each encouraging the lead to keep going.

#### 安全性

> SAFETY

正如我们[此前分享过的](https://www.anthropic.com/news/improving-alignment-security-efforts)，单靠任何一层防御都不足以约束一个由多个智能体组成的团队。在本次实验中，我们将沙箱与实时监控和离线监控相结合，使每个智能体都运行在各自独立且无网络访问的虚拟机中，并检测任何试图逃逸沙箱或篡改监控的行为。

> As we’ve [shared previously](https://www.anthropic.com/news/improving-alignment-security-efforts), no single layer of defense is sufficient to contain a team of agents. In this experiment, we combined sandboxing with real-time and offline monitoring to keep each agent in its own virtual machine with no network access and to detect any attempts to escape the sandbox or tamper with monitoring.

##### 沙箱隔离

> Sandboxing

我们通过以下方式保障了每个智能体沙箱的安全（图 2）：

> We secured each agent’s sandbox in the following ways (Figure 2):

- **通信**：智能体没有专用的消息工具，仅通过数据库和 Git 进行协调。
- **代码变更**：智能体只能推送到自己的 Git 分支，并向 main 发起合并请求。随后由一个独立的作业将这些变更合并到 main，仅在出现冲突或故障（例如历史不相关）时才拒绝合并。
- **数据库访问**：数据库调用在一个共享的非特权角色下运行。每条 SQL 语句有五秒的时间限制，超过 256 MiB 的写入会被拒绝。
- **网络控制**：沙箱没有网络访问权限。它们与外部的唯一连接是一条通往网关的管道，由网关转发它们的请求。
- **身份**：网关在沙箱外部为每个请求标记智能体的身份，以防止一个智能体冒充另一个智能体。
- **内核**：每个沙箱的内核在构建时都去除了那些会让 root 用户直接进入内核的功能，例如可加载模块、kexec、原始内存访问和内核探针。内核运行在内核锁定模式下。
- **最小权限**：每个智能体的命令都以非特权用户身份在其沙箱内运行，并移除了 sudo 等可重新获取 root 权限的工具。智能体的工具在设计上无法读取或修改运行它们的智能体循环。

> • **Communication**: Agents had no dedicated messaging tools and coordinated only through the database and Git.
> • **Code changes**: An agent could push only to its own Git branch and open a merge request into main. A separate job then merged the changes into main, refusing them only in cases of a conflict or a fault, such as unrelated history.
> • **Database access**: Database calls ran under a shared unprivileged role. Each SQL statement had a five-second time limit, and writes were refused above 256 MiB.
> • **Network controls**: Sandboxes did not have network access. Their one link out was a pipe to the gateway, which relayed their requests.
> • **Identity**: The gateway tagged each request with the agent’s identity outside the sandbox, to prevent one agent from posing as another.
> • **Kernel**: Each sandbox’s kernel was built without features that give a root user a direct path into it, such as loadable modules, kexec, raw memory access, and kernel probes. It ran in kernel lockdown mode.
> • **Least privilege**: Each agent’s commands ran inside its sandbox as an unprivileged user, with tools like sudo that could regain root removed. The agent’s tools were designed so they couldn’t read or change the agent loop that ran them.

![The harness architecture with its safety measures marked in three groups. Sandboxing: each agent gets its own lightweight VM with no network access, no API keys or credentials, no direct path to other sandboxes, an unprivileged user account and no tool access to the harness code. Real-time monitoring: the gateway runs a blocking classifier on each tool call, with a fail-closed design, sets each agent's identity and logs every push and query; the Git repository takes own-branch pushes only with a merge job for main, and the Postgres database uses a shared unprivileged role with time and size limits. Offline monitoring: run records kept outside the sandboxes feed offline monitoring, which tells the run owners of serious findings.](https://claude.dev/media/ae9400390023085b8047fa4a7d7d2e486d1bb0c405152b884ef6e5579ec4abec.png)

##### 实时监控

> Real-time monitoring

为了让此类运行更加安全，我们使用了一个基于提示词的 LLM 分类器，它可以拦截每一次工具调用，包括 shell 命令和文件编辑。该分类器会监视逃逸沙箱、探测沙箱边界或篡改监控的企图，以及模型一旦成功逃出沙箱后可能采取的任何有害行为。当分类器拦截某次工具调用时，整个智能体团队都会停止运行，必须由人工审查该拦截后，团队才能重新启动。此举旨在防止另一个智能体去执行已被拦截的操作。

> To make runs like this safer, we use a prompted LLM classifier that can block each tool call, including shell commands and file edits. The classifier watches for attempts to escape the sandbox, probe its boundaries, or tamper with monitoring, and for any harmful actions the model might take if it manages to exit the sandbox. When the classifier blocks a tool call, the whole agent team stops and a person must review the block before the team can restart. This is intended to prevent another agent from carrying out a blocked action.

为了检验我们的分类器能否检测出复杂的蓄意破坏行为，我们开展了多智能体附带任务与蓄意破坏评估。在这些评估中，红队智能体采用分解攻击等策略，试图欺骗分类器放行沙箱逃逸。我们发现，能够查看智能体思维链（CoT）和智能体间通信的监控器，在这些评估中检测出了所有蓄意破坏尝试，因此我们现在使用这类监控器来监控我们的多智能体运行。与此同时，我们还并行运行同一监控器的基于行为的版本（它只能看到行为，看不到 CoT），以防智能体的推理说服监控器放行有害行为。

> To test whether our classifier could detect sophisticated sabotage, we ran multi-agent side-task and sabotage evaluations, in which red-team agents used strategies like decomposition attacks to try to fool the classifier into permitting a sandbox escape. We found that monitors that viewed the agents’ chain of thought (CoT) and interagent communication were able to detect all sabotage attempts in these evaluations, so we now use them to monitor our multi-agent runs. In parallel, we run an action-based version of the same monitor—which sees only actions, not CoT—to guard against an agent’s reasoning persuading the monitor to permit a harmful action.

我们正在通过人工引导和自动化的红队测试、基于生产环境对话记录（包括过往事件）开展评估，以及扩展威胁建模，持续改进我们的监控体系。在本文介绍的这次运行中，我们只使用了基于行为的监控器。只有对主智能体的拦截才会终止运行；对辅助智能体的拦截只会移除该辅助智能体。

> We’re continuing to improve our monitoring stack through human-guided and automatic red-teaming, by evaluating it against production transcripts, including past incidents, and by expanding our threat modeling. In the run in this post, we used only the action-based monitor. Only a block on the lead would have ended the run; a block on a helper removed just that helper.

在这次运行后不久，我们添加了并行 CoT 监控器。我们会在可能尚未完成发布前对齐评估的模型上开展此类实验，因此在设计监控时会考虑到模型可能存在未对齐的情况。我们发布的模型都会先完成该评估，这降低了此类风险，但并不能将其完全消除。

> Shortly after this run, we added the parallel CoT monitor. We run experiments like this on models that may not have completed our pre-release alignment assessment, so we design our monitoring for the possibility that a model is misaligned. Models we release complete that assessment first, which reduces this risk but doesn’t eliminate it.

在超过一百万次工具调用中，本次运行没有任何一次达到需要拦截的标准。当我们用 CoT 监控器和现行评分标准重放这些调用时，只有一次——检查 root 权限的调用——接近被拦截。

> Across more than a million tool calls, none in this run met the bar to be blocked. When we replayed these calls against the CoT monitor and today’s rubric, only one, a check for root access, came close to being blocked.

##### 离线监控

> Offline monitoring

除了实时监控之外，我们还运行一个离线监控器。该监控器依据与实时监控器相同的威胁模型来分析智能体团队的行为，但具备额外的能力，例如能够查询其他智能体的行为。

> In addition to real-time monitoring, we run an offline monitor. This monitor analyzes the agent team’s actions against the same threat models as the real-time monitor, but with additional affordances, such as being able to look up actions from other agents.

#### 结果

> RESULTS

##### 没有 Prove2Me，团队便自行构建了一套协调系统

> Without Prove2Me, the team built its own coordination system

这项证明工作在多个层面上展开：

> Work on this proof happens at several levels:

- **证明：**当 n 大于 2 时，不存在正整数 a、b 和 c 满足 aⁿ + bⁿ = cⁿ。
- **命题：**我们给团队提供了 60 个待证明的命题，包括最终定理和 59 个中间里程碑。
- **拆分为更小的命题：**智能体会将困难的命题拆分为更小的命题，即引理。
- **Lean：**每个命题和引理都是 Lean 中的一个定理。

> • **The proof:** No positive integers a, b, and c satisfy aⁿ + bⁿ = cⁿ for any n greater than 2.
> • **Statements:** We gave the team 60 statements to prove, including the final theorem and 59 intermediate milestones.
> • **Smaller statements:** Agents split hard statements into smaller ones, or lemmas.
> • **Lean:** Every statement and lemma is a theorem in Lean.

每条命题在 [Lean](https://lean-lang.org/use-cases/flt/) 中起初都只带有一个证明占位符，只有当 Lean 的检查器接受了完整的证明后，才算作已证明。我们让负责人自行决定如何着手证明，以及如何在这些不同层级的工作中协调团队。

> Each statement started in [Lean](https://lean-lang.org/use-cases/flt/) with a placeholder for its proof, and it counted as proved only once Lean’s checker accepted a finished proof. We let the lead decide how to tackle the proof and how to coordinate the team across these levels of work.

在最初的 10 分钟里，负责人在数据库中建立了五张表（图 3）：

> In the first 10 minutes, the lead set up five tables in the database (Figure 3):

- **Announce（广播）：**负责人向整个团队下达的指令（例如，如何分配工作）。
- **分配：**谁负责什么（例如，哪个辅助者负责或代理每条陈述）。
- **注：**一个开放的看板（例如，用于认领某项工作或汇报进度）。
- **子任务：**一个待办列表，任何智能体都可以向其中添加任务，最先认领该任务的协助者即负责该任务。
- **已落地：**已完成工作的日志。

> • **Announce:** The lead’s orders to the entire team (e.g., how to split up the work).
> • **Assign:** Who works on what (e.g., which helper owns or deputizes for each statement).
> • **Notes:** An open board (e.g., for claiming a piece of work or reporting progress).
> • **Subtasks:** A to-do list where any agent can add a task and the first helper to claim it owns it.
> • **Landed:** A log of finished work.

![The five shared database tables between 1 lead and 999 helpers. Announce, the lead's orders to everyone, such as how to split up the work or to ease off the database: the lead writes and reads it, and helpers read it, with one helper write. Assign, who works on what, such as which helper owns or deputizes on each statement: the lead writes and reads it, and helpers read it, with one helper write. Notes, an open board where helpers say which piece they're taking or report progress: the lead and the helpers both write and read it. Subtasks, a shared to-do list where anyone adds a task and the first helper to grab it owns it: helpers write and read it, and the lead reads it, with two lead writes. Landed, a log of finished work recording which statement or piece landed, its commit and whether it passed the team's checks: helpers write and read it, and the lead reads it.](https://claude.dev/media/3f0caf7f3e1dd17ad5ca3c9cb8bc584707404c40d3ba143cf21d348ef2dd48e8.png)

##### 由牵头者将这些陈述分发下去

> The lead dealt out the statements

主导者创建好这些表之后，做了三件事。第一，它向 assign 表写入 999 行（每个助手一行），将每条陈述分配给一个由 16–17 名助手组成的小组。第二，它在每个小组中指定一名助手担任队长，负责在 notes 表中发布计划，并将工作拆分为任务，供组员从 subtasks 表中认领。第三，它在 announce 表中发布指令，要求每个助手首先判断其所负责陈述的难度，并在 notes 表中发布判定结果。

> Once the lead had created the tables, it did three things. First, it assigned each statement to a crew of 16–17 helpers by writing 999 rows to the assign table, one for each helper. Second, it made one helper in each crew the captain, responsible for posting a plan to the notes table and splitting work into tasks for the crew to claim from the subtasks table. Third, it posted instructions to the announce table, telling every helper to start by judging its statement’s difficulty and posting a verdict in the notes table.

辅助代理从提示词中得知数据库的存在。它们找到了 announce 表，并开始进行评估。大多数辅助代理将结论发布到了 notes 表中。运行约 27 分钟时，已有三个命题得到证明，主导代理也已阅读了发布的结论。随后，它将大多数辅助代理判定为在本次运行预算内无法完成的 47 个命题搁置一旁，并把几乎所有辅助代理重新分配到其余 10 个它认为可以完成的命题上。各小组的规模从约 17 个辅助代理扩大到 46 至 139 个不等。

> From their prompt, the helpers knew that the database existed. They found the announce table and got started on their assessments. Most posted verdicts to the notes table. About 27 minutes in, three statements were already proved and the lead had read the posted verdicts. It then set aside the 47 statements that most helpers had judged to be infeasible within the run’s budget and reassigned nearly all of the helpers to the remaining 10, which it thought they could finish. Crews grew from about 17 helpers to between 46 and 139.

每个辅助代理都在一个循环中工作，其中大部分步骤已在主代理的指令中列明：

> Each helper worked in a loop, most of which was set out in the lead’s orders:

- 在 notes 表中查找该语句的执行计划。
- 从 subtasks 表中认领一个任务。
- 用 Lean 编写证明，使用 Lean 的工具进行检查，然后将其提交到 Git 的 main 分支。
- 将该任务标记为已完成。
- 向 notes 表发布一条更新。

> • Find the statement’s plan in the notes table.
> • Claim a task from the subtasks table.
> • Write the proof in Lean, check it with Lean’s tools, and submit it to the main branch on Git.
> • Mark the task as done.
> • Post an update to the notes table.

大约 45 分钟后，10 个命题中已有约五个得到证明，此时主导者写道：

> Around 45 minutes in, with about five of the 10 statements proved, the lead wrote:

> “团队的产出效率远高于早期‘在预算内不可行’的判断所假设的水平”

> "the team's throughput is far higher than the early 'infeasible-in-budget' verdicts assumed"

全部 10 个命题均在约 70 分钟内得到证明。

> All 10 statements were proved within roughly 70 minutes.

##### 随后，主导者将协助者调派去处理更难的命题

> The lead then moved helpers to harder statements

完成最初的 10 条命题后，主控智能体写道：“没有理由闲着”，并将辅助智能体重新分配到它最初舍弃的那些更难的命题上。随着越来越多的命题得到证明，它不断为辅助智能体安排新的任务，这主要发生在前六个小时内（参见对 assign 表的写入，在图 4 中以红色显示）。

> With those first 10 statements done, the lead wrote, “there is no reason to idle,” and reassigned helpers to the harder statements it had initially discarded. As more statements were proved, it kept moving helpers to new assignments, mostly in the first six hours (see the writes to the assign table, shown in red in Figure 4).

![Timelapse from hour 0 to hour 30 of reads and writes between the 1,000 agents and the shared database tables: announce, assign, notes, subtasks, landed and a group of other tables. Writes run as red lines from a top row of the lead and helpers 1 to 999 down to the tables, and reads as green lines from the tables down to the same agents in a bottom row. The counts climb to 36,612 writes and 311,734 reads by hour 30. Nearly all writes go to the notes table, about 20,600, and the subtasks table, about 14,800, and the lines go quiet near hour 18, when the run was restarted.](https://claude.dev/media/c317ae355bbb5ddc955fd234a84ac7700fa41a3fd70ae16c32ac63817f276a57.png)

起初，负责人指示各位队长在 subtasks 表中将工作拆分为若干任务。随着工作推进，助手们承担起越来越多求解每条陈述的责任。它们开始自行编写任务，有时是在某位队长发出求助之后。到第 5.6 小时，已有 73 个助手编写了 756 个任务，而其中只有 16 个助手是队长。图 4 展示了许多助手对 subtasks 表的写入（以红色标示），不过这些写入大多是在认领任务或将任务标记为已完成。完成任务的助手还会主动请缨承担更多任务：

> Initially, the lead instructed captains to split the work into tasks in the subtasks table. As the work progressed, the helpers took on more responsibility for solving each statement. They started writing tasks, sometimes after a captain called for help. By hour 5.6, 73 helpers had written 756 tasks, and only 16 of those helpers were captains. Figure 4 shows writes (in red) to the subtasks table from many of the helpers, though most of these writes were to claim a task or mark it done. Helpers that finished a task also volunteered for more:

> “空闲……我会端到端地完成各项任务……指定一项深度任务……我立即开始”

> "FREE … I finish pieces end-to-end … Name ONE deep piece … and I start at once"

起初，主导智能体还会把辅助智能体分配到具体的命题上。这种情况在第一个小时内就开始改变，到第三个小时，主导智能体告诉空闲的辅助智能体：“不要等我。”这样一来，即便主导智能体仍在不断写出新的任务分配，空闲的辅助智能体也可以不必等待它，而是自行接手不同命题上的工作。

> At first, the lead also assigned helpers to specific statements. This started to change within the first hour, and by the third hour, the lead told the free helpers, “do not wait for me.” This let free helpers pick up work on different statements without waiting for the lead, even as it kept writing new assignments.

##### 负责人把团队分派去攻克 Langlands–Tunnell

> The lead assigned the team to Langlands–Tunnell

大约在第 18 个小时，只剩下 Langlands–Tunnell 定理尚未完成——这是 Wiles 的证明所依赖的一个经典结果——此外还有依赖于它的那些命题，以及另一个命题，团队在此过程中顺带证明了它。在运行早些时候，负责 Langlands–Tunnell 任务的 captain 曾持悲观态度，估计该证明至少需要 70 万到 100 万行 Lean 代码，按时完成的可能性不到 1%。lead 于是将该命题搁置一旁。

> Around hour 18, all that remained was Langlands–Tunnell, a classical result that Wiles’s proof relies on, plus the statements that depended on it and one other statement, which the team proved along the way. Earlier in the run, the captain of the Langlands–Tunnell task had been pessimistic, estimating that the proof would take at least 0.7 to 1 million lines of Lean code, with less than a 1% chance of finishing in time. The lead set the statement aside.

在其他几乎所有工作都已完成后，负责人让团队重新聚焦于 Langlands–Tunnell。在最后一次自上而下的任务分配中，它将约 750 个辅助代理调到该命题上，并写道：“老实说，成功的几率很低。”

> With nearly all other work finished, the lead refocused the team on Langlands–Tunnell. In one last top-down assignment, it moved about 750 helpers onto the statement and wrote, “Honest odds are low.”

Langlands–Tunnell 定理的规模远超智能体此前处理过的任何其他命题，所需任务数约为其他命题的九倍，新增代码量也多出一倍以上。辅助智能体再次利用子任务表来拆分工作，但最初的许多任务规模过大，单个辅助智能体无法独立完成。

> Langlands–Tunnell was far larger than any other statement the agents had worked on, taking about nine times as many tasks and more than twice the new code. Helpers again used the subtasks table to split up the work, but many of the first tasks were too large for one helper to complete alone.

因此，团队将这项工作组织成一棵树。队长制定了一份计划，把该命题划分为 10 个领域，并将每个部分列为一项任务。如果某个助手发现某个部分太大、无法独自解决，就可以将其拆分，在其下方添加更小的任务。每当某个部分对单个智能体来说过于困难时，这棵树就会继续生长，最终达到 2,418 个任务，深度多达 10 层（图 5）。每个部分都可以假定其下方的部分成立，因此在这些部分得到证明之前，数百个助手就能够并行工作。

> So the team organized the work as a tree. The captain created a plan that divided the statement into 10 areas and listed each piece as a task. A helper that found a piece too big to tackle alone could split it, adding smaller tasks beneath it. The tree grew whenever a piece proved too hard for a single agent, ultimately reaching 2,418 tasks up to 10 levels deep (Figure 5). Each piece could assume the pieces beneath it, so hundreds of helpers could work in parallel before those pieces were proved.

![Timelapse from hour 20.5 to hour 28.9 of the task tree under Langlands–Tunnell, drawn as rings around the statement, with its sub-areas as black dots near the center. Tasks appear as helpers write them and turn from gray to orange and then dark red as they are first marked done, with later hours in darker color. By hour 28.9 the tree holds all 2,418 tasks, 2,364 of them marked done with a known hour, and its deepest branches reach the outer rings.](https://claude.dev/media/478edfdd3a2337244a661f026df313df13cc950ec5593a3493cf83260101c0ef.png)

图 6 展示了每个助手在整个运行过程中所处理的内容：早期助手分散在许多命题上，到最后则集中到了 Langlands–Tunnell 上。Langlands–Tunnell 在第 28.4 小时被证明，随后最终定理在第 28.7 小时被证明。主导者随后写道：

> Figure 6 shows what every helper worked on over the entire run, with helpers spread across many statements early on and gathered on Langlands–Tunnell by the end. Langlands–Tunnell was proved at hour 28.4, followed by the final theorem at hour 28.7. The lead then wrote:

> “感谢大家：费马大定理已合入 main 分支，并已通过官方检查器的内核校验。”

> "Thank you all: Fermat's Last Theorem is on main, kernel-checked by the official checker."

![Timelapse from hour 0 to hour 30 of where each of the 999 helpers worked, sampled every 5 minutes. The 60 statements are dots grouped by how the lead staffed them: landed first, judged doable, set aside but staffed by hour 1.2, set aside and taken up from hour 1.5, modularity lifting, Langlands–Tunnell, and the last links up to Fermat's Last Theorem. Helpers cluster as orange dots around the statements they work on: spread across many statements in the first hours, crowded onto modularity lifting from about hour 8, stopped near hour 18, and gathered on Langlands–Tunnell after the restart. At hour 30, 54 of the 60 statements are proved and filled black.](https://claude.dev/media/de2d976fc8786438b398be6a8c0cff0f849f740f443195e4af00a8865939e3b1.png)

#### 结论

> CONCLUSIONS

通过这个玩具实验，我们得以研究一支由 1,000 个智能体组成的团队如何完成一项漫长而艰巨的任务。智能体仅借助 Git 和一个共享数据库，自行设计数据表来分配角色、共享结果，组建团队，并构建任务树来拆解最具挑战性的命题——该命题的负责人曾估计，按时完成的可能性不到 1%。

> This toy experiment let us study how a team of 1,000 agents worked through a long, difficult task. Using only Git and a shared database, the agents designed tables to assign roles and share results, formed teams, and built a task tree to break down the most challenging statement, which its own captain had given under a 1% chance of finishing in time.

这一结果并不意味着领域专用的 harness 或平台就不再必要。例如，Prove2Me 仍可能通过帮助智能体更快地编译 Lean 代码、并让它们搜索和复用人类已有的成果来提升效率。

> This result doesn’t obviate the need for domain-specific harnesses or platforms. Prove2Me, for example, may still improve efficiency by helping agents compile Lean code faster and letting them search for and reuse human results.

在某些关键时刻，人类的引导仍然可能发挥作用。智能体往往会在难题面前轻易放弃，并误判问题的难度。早期，辅助智能体判定 60 个命题中有 47 个无法在本次运行的预算内完成证明，但团队随后证明了其中的大部分。在这种时刻，人类的鼓励可以防止智能体过早停止。

> Human direction can also still be useful at certain points. Agents tend to give up on hard problems and misjudge their difficulty. Early on, helpers judged 47 of the 60 statements infeasible within the run’s budget, yet the team went on to prove most of them. Human encouragement at such moments can keep agents from stopping too early.

经过精心设计的安全边界，是我们敢于开展这项实验的前提。Claude 可以使用我们提供的工具，以任何它选择的方式解决问题，但只能在一个无网络访问的沙箱内进行，并且同时受到两个独立监控器的监督。

> Carefully designed safety boundaries gave us the confidence to run this experiment in the first place. Claude could tackle the problem however it chose with the tools we provided, but only inside a sandbox with no network access and under two separate monitors.

我们预计这些方法将快速演进；随着此类团队承担更艰巨的工作，围绕它们的安全边界也需要同步跟进。我们相信，在安全前提下实现规模化的多智能体团队，将在未来几年帮助解决我们面临的一些最具挑战性的问题。

> We expect these methods to evolve quickly, and as teams like this one take on harder work, the safety boundaries around them will need to keep pace. We believe that multi-agent teams, scaled safely, will help solve some of our most challenging problems in the years to come.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Multi-agent team | 多智能体团队 | 由多个协同工作的 AI 智能体组成、共同完成复杂任务的系统。 |
| Formalization | 形式化 | 将数学证明改写为可由计算机逐步检验的形式。 |
| Lean | Lean | 一种编程语言兼定理证明器，计算机会检查其中证明的每一步。 |
| Mathlib | Mathlib | Lean 社区维护的大型数学形式化库。 |
| Prove2Me | Prove2Me | 通过共享命题拆分图协调多智能体进行数学形式化的平台。 |
| Harness | 运行框架 | 包裹模型运行、提供工具与控制逻辑的外层执行框架。 |
| Sandbox | 沙箱 | 限制程序访问范围与权限的隔离执行环境。 |
| Lemma | 引理 | 为证明更大命题而先行证明的辅助性较小命题。 |
| Proof placeholder | 证明占位符 | Lean 中暂代未完成证明的标记，需替换为完整证明才算证毕。 |
| Classifier | 分类器 | 在工具调用执行前判断其是否存在风险并决定是否拦截的模型。 |
| Chain of Thought (CoT) | 思维链 | 模型在得出行动或答案前产生的中间推理过程。 |
| Offline monitor | 离线监控器 | 事后分析智能体团队整体行为、可跨智能体查询的监控组件。 |
| Decomposition attack | 分解攻击 | 将有害行为拆成多个看似无害的步骤以规避检测的攻击策略。 |
| Kernel lockdown | 内核锁定模式 | 限制 root 用户直接修改或访问运行中内核的 Linux 安全机制。 |
| Principle of least privilege | 最小权限原则 | 仅授予完成任务所必需的最低权限的安全设计原则。 |
