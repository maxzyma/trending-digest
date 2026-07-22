---
source: claude-blog
source_url: https://claude.com/blog/how-anthropic-secures-its-ai-native-software-development-lifecycle
published_at: 2026-07-21
category: Claude Code
title_en: How Anthropic secures its AI-native software development lifecycle
title_zh: Anthropic 如何保障其 AI 原生软件开发生命周期的安全
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 9
source_image_count: 4
---

# Anthropic 如何保障其 AI 原生软件开发生命周期的安全

> How Anthropic secures its AI-native software development lifecycle

> 来源：Claude Blog，2026-07-21
> 原文链接：https://claude.com/blog/how-anthropic-secures-its-ai-native-software-development-lifecycle
> 分类：Claude Code

## 核心要点

- Anthropic 的代码量与部署速度呈指数级增长，工程师人均季度交付代码量是 2021 至 2025 年的 8 倍，安全流程必须同步扩展以避免成为瓶颈。
- Claude 已从编码助手演变为主要的代码创建者与审查者，约 80% 合并入代码库的代码由 Claude 撰写，超过一半的代码由内部版本的 Claude Tag 合并，人类工程师专注于指挥、设定意图与最终批准。
- 团队重点防御三类威胁：被攻陷或遭提示注入的智能体引入恶意变更、被智能体当作可信输入摄入的供应链与依赖投毒，以及以更高频率出现的常见应用漏洞。
- 核心策略包括安全左移并深度融入编码阶段、以硬性访问与身份边界控制爆炸半径、在上线前后结合自动化确定性审查与智能体审查，以及在最高杠杆点插入人类环节。
- 规划阶段采用 Claude Opus 驱动的项目安全评审应用，对照 MITRE ATT&CK 框架分析设计文档，并连接内部知识索引以获取组织级策略与历史决策的深层上下文。
- 安全指导原则从难以执行的文档转变为编码进 CLAUDE.md 文件，使安全团队能够直接塑造代码的生成方式，从源头预防漏洞。
- 一条持久原则是：将安全智能体接入组织已有的上下文所在之处（聊天记录、既往评审、代码库），而非在不再需要的阶段强制编写详尽文档。

## 正文

Anthropic 副首席信息安全官 Jason Clinton 详细介绍了安全工程团队如何在 AI 撰写 80% 已合并代码的开发生命周期中保障安全。

> Anthropic Deputy CISO, Jason Clinton, details how the Security Engineering team secures a SDLC that has AI authoring 80% of merged code.

在 Anthropic，代码量和部署速度呈指数级增长。我们的软件工程师平均每季度交付的代码量，是 2021 到 2025 年的 8 倍。

> At Anthropic, the amount of code and velocity of deployment have scaled exponentially. Our software engineers on average ship 8x as much code per quarter as they did from 2021 to 2025.

我们的评审、监控和其他安全流程也需要随着这种加快的节奏一同扩展。否则就会形成瓶颈（[阿姆达尔定律](https://en.wikipedia.org/wiki/Amdahl%27s_law)）。

> Our reviews, monitoring, and other security processes needed to scale alongside this increased pace. Otherwise it becomes a formula for bottlenecks ([Amdahl’s Law](https://en.wikipedia.org/wiki/Amdahl%27s_law)).

我们的软件开发流程也发生了巨大变化。Claude 已从编码助手演变为主要的创建者和评审者。如今合并进我们代码库的代码中，约 80% 由 [Claude 编写](https://www.anthropic.com/institute/recursive-self-improvement)。

> Our software development processes have changed drastically as well. Claude has evolved from coding assistant to primary creator and reviewer. [Claude authors](https://www.anthropic.com/institute/recursive-self-improvement) about 80% of the code merged into our codebase today.

超过一半的代码由我们内部版本的 [Claude Tag](https://www.anthropic.com/news/introducing-claude-tag) 合并，而人类工程师则专注于指挥、设定意图和掌握最终审批权。

> More than half of all code is being merged by our internal version of [Claude Tag](https://www.anthropic.com/news/introducing-claude-tag) while human engineers focus on directing, setting intent, and owning final approval.

这意味着我们的安全团队必须防御一个快速扩张的攻击面，并加固一个以非确定性、持续演进的智能体（agent）为核心的开发生命周期。本文将介绍保护软件开发生命周期（SDLC）的策略。

> This means our security team must defend a rapidly expanding surface area and harden a lifecycle with non-deterministic, constantly evolving agents at its heart. In this article, I cover strategies to secure the software development lifecycle (SDLC).

（本文旨在与我们近期发布的 [面向智能体的零信任](https://claude.com/blog/zero-trust-for-ai-agents) 框架结合阅读；本文中的所有内容在实现上都采用了该框架中的安全设计理念。）

> (This is intended to be combined with the[Zero Trust for Agents](https://claude.com/blog/zero-trust-for-ai-agents)framework we recently published; everything in this article uses security design ideas from that framework in the implementation).

我们所要防御的威胁很具体：被攻陷或遭受提示注入（prompt-injected）的智能体引入恶意变更；被智能体当作可信输入摄入的供应链与依赖投毒；以及那些更为常见、如今却以更高数量涌现的应用漏洞类别。后文中的每一项控制措施都至少对应上述威胁之一。

> The threats we're designing against are specific: a compromised or prompt-injected agent introducing a malicious change; supply-chain and dependency poisoning that an agent ingests as trusted input; and the more familiar classes of application vulnerability now arriving at higher volume. Every control that follows maps to at least one of those.

我们部署了几项总体策略，以在不显著拖慢开发速度的前提下实现这一目标，包括：

> There are several overarching strategies we’ve deployed to accomplish this without significantly throttling dev velocity including:

- 将安全左移，并与代码开发阶段完全整合；
- 使用硬性的访问和身份边界来控制影响范围（blast radius）；
- 在投产前后结合自动化的确定性评审与智能体评审；以及
- 在杠杆效应最高的环节插入人工介入（human in the loop）。

> • Shifting security left and fully integrating with the code development stage;
> • Using hard access and identity boundaries to contain the blast radius;
> • Combining automated deterministic and agentic reviews before and after production; and
> • Inserting humans in the loop at the highest leveraged points.

本文将介绍我们在软件开发生命周期特定阶段所实施的安全流程，以及其背后的核心原则。这些原则更为持久，因为随着模型能力的演进，安全团队必须重新审视、并常常重新发明其流程。

> In this article, we’ll cover the security processes we have implemented at specific stages of the software development lifecycle as well as the core principles behind them. These principles are more enduring as security teams must reexamine, and often reinvent, their processes as model capabilities evolve.

### 软件开发生命周期的演进

> The evolving software development lifecycle

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a5fa5786cc9f557247c1256_9c126d9d.png)

我们的开发团队已经[详细](https://claude.com/blog/running-an-ai-native-engineering-org)介绍过他们软件开发生命周期的变化，所以在深入每个阶段之前，这里只做一个简短的入门介绍。

> Our development team has covered the changes to their software development lifecycle [at length](https://claude.com/blog/running-an-ai-native-engineering-org), so this will be a brief primer before we dive into each stage.

从宏观上看，我们的软件开发生命周期是被压缩的。它更多由原型和内部采用（内部试用，dogfooding）驱动，而不是冗长的规划周期。创意来自组织的各个角落，传统角色（前端、后端、设计）之间的界限也变得模糊。评审和审批仍然保留人工参与（human in the loop），但同时也由智能体循环（agentic loop）驱动。

> At a high level, our software development lifecycle is compressed. It is driven by prototypes and internal adoption (dogfooding) more than lengthy planning cycles. Ideation comes from all corners of the organization and traditional roles (frontend, backend, design) are blurred. Reviews and approvals still have humans in the loop, but are also driven by agentic loops.

虽然每个阶段都因 Claude Code 和 Claude Tag 而发生了根本性的转变和加速，但每个阶段的名称和目的对于来自更传统组织的开发者来说并不会感到陌生。这些是自然的关卡，我们也把它们作为面向 AI 原生软件开发生命周期的安全流程的一部分。

> While each stage has been fundamentally transformed and accelerated by Claude Code and Claude Tag, the names and purposes of each stage wouldn’t look alien to a developer coming from a more traditional organization. These are natural gates that we also use as part of our security processes for an AI-native SDLC.

### 计划

> Plan

我们最早的安全自动化之一，是一个由 Claude Opus 驱动的简单 PSR（项目安全审查，project security review）Web 应用。它会读取项目设计文档，并对照 [MITRE ATT&CK 框架](https://attack.mitre.org/)进行分析，以识别潜在漏洞并给出缓解建议。

> One of our first security automations ever was a simple Claude Opus powered PSR (project security review) web application. It ingested a project design document and analyzed it against the [MITRE ATT&CK framework](https://attack.mitre.org/) to identify potential vulnerabilities and suggested mitigations.

我们对该系统做了大幅增强，将其接入一个内部知识索引，从而在覆盖全组织的政策、过往决策和相关系统方面提供了更深入的上下文。

> We’ve significantly enhanced the system by connecting it to an internal knowledge index that provides much deeper context across our organization-wide policies, past decisions, and related systems.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a5fa80d84f25c4ed3f5421f_three-steps-diagram.png)

这让我们能更好地理解潜在风险，也能捕捉到 PSR 中缺失的信息。仅这一项实现就为应用安全（AppSec）团队节省了大部分时间。一旦我们确信 Claude 能准确评估风险，便允许各团队在 Claude 判定发布风险足够低时自行批准自己的项目。

> This gives us a better understanding of potential risk, and it also captures information missing from the PSR. This one implementation saved the majority of the AppSec team’s time. Once we gained confidence that Claude was accurate in assessing risk, we allowed teams to approve their own project, if Claude deemed the launch low enough risk.

在这里我们可以看到面向 AI 原生 SDLC 的首批关键调整之一。PSR 最初的设计目的，是在漫长且昂贵的编码过程之前发现安全问题。在这个阶段发现问题可以节省数月的重新开发时间。

> Here we can see one of the first key adaptations to an AI-native SDLC. A PSR was originally designed to catch security issues before the lengthy and expensive coding process. Catching an issue at this stage saved months of re-development.

如今，一个主要功能的多个原型可以在数小时内完成，这使得详细的架构评审不再是那么关键的关卡。将我们的 PSR 应用接入知识索引，可以捕捉那些原本可能被遗漏的上下文，同时又不会制造不必要的减速带。而创建一个 Claude Code 技能（skill），让 Claude 能够进一步扇出（fan out），在上下文所在的任何地方将其捕捉下来。

> Today, multiple prototypes of major features can be created in hours, making detailed architectural review a less critical gate. Connecting our PSR application to our knowledge index captures context that could otherwise be missed without creating an unnecessary speed bump. Creating a Claude Code skill allowed Claude to further fan out and capture additional context wherever it lived.

长效原则：将安全智能体接入组织上下文。随着规划周期被压缩，把这些智能体带到上下文已经存在的地方——聊天线程、既往评审、代码库——要比在可能已不再需要的阶段强行要求详尽的文档有效得多。无论哪种方式，智能体都需要代码本身之外的上下文。

> Enduring Principle: Connect security agents to organizational context. As the planning cycle compresses, it is much more effective to bring these agents to where the context already lives – chat threads, prior reviews, the codebase – rather than forcing detailed documentation at stages that may no longer require them. Either way, agents need context outside of the code itself.

### 代码

> Code

AI 原生工程组织中的安全专业人员有了一个新的杠杆：他们可以直接塑造代码的生成方式，从源头上帮助防止漏洞产生。

> Security professionals within an AI-native engineering organization have a new lever: they can directly shape how code is created, helping to prevent vulnerabilities at the source.

过去，团队会观察到反复出现的漏洞，并制定安全编码规范来应对，但这些规范难以强制执行，也很少标准化。

> Previously, teams observed recurring vulnerabilities and created secure coding guidelines to address them, but those guidelines were difficult to enforce and rarely standardized.

在 Anthropic，这些规范被编码进 CLAUDE.md 文件，并引用组织级技能（skill），因此代码在生成的那一刻就遵循这些最佳实践。这是作为一个闭环来完成的。一旦某个智能体发现了一类缺陷，相关文件就会更新，以防止它在未来的代码中再次出现。

> At Anthropic, those guidelines are encoded in CLAUDE.md files and references to org-wide skills so the code follows these best practices the minute it's generated. This is done as part of a closed loop. Once an agent discovers a bug class, the relevant file is updated to prevent it recurring in future code.

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a5fa78b8f99d4eea5c0c389_closed-loop-diagram.png)

当然，这并不意味着所有代码都完美无缺。我们团队一开始使用的 CLAUDE.md 文件会指示智能体在提交 PR 前把运行 [/security-review](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code) 作为最后一步。这个普遍可用的命令是我们团队内部审查流程的产品化版本，它会查找潜在的攻击者可控输入进入的位置，扫描可疑链接，然后验证其发现。

> Of course, that doesn’t mean all code comes out perfect. Our team started with a CLAUDE.md file that instructs the agent to run [/security-review](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code) as a final step before opening a PR. This generally available command, the productized version of our team's internal review workflow, looks for places where potential attacker-controllable input enters, scans for suspicious links, and then verifies its findings.

如今，这些审查在 Claude 生成代码的同时进行。一旦安装了[安全指导插件](https://code.claude.com/docs/en/security-guidance)，Claude 会随着进程审查对话和代码。它会在生成代码的同一会话中提出安全改进建议，并处理常见漏洞。

> Today, these reviews take place while Claude generates the code. Once a [security guidance plugin](https://code.claude.com/docs/en/security-guidance) is installed, Claude reviews the conversation and code as it goes. It suggests security improvements and addresses common vulnerabilities in the same session as it generates the code.

在 PR 环节的其他引导会推动内部的非技术团队把他们的应用托管在我们的低代码应用托管平台上，避免那些传统上一直困扰安全团队的影子 IT（shadow IT）。

> Other nudges at PR-time push internal, non-technical teams towards hosting their app on our low-code app-hosting platform, avoiding shadow IT that had traditionally plagued security teams.

我们的一些客户选择将 [/security-review](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code) 与 PreToolUse 钩子（hook）集成，使这一步成为一个更硬性的关卡。那样也很有效，但我们团队选择在周期的测试/CI 阶段设置我们的硬性代码审查关卡。

> Some of our customers choose to integrate [/security-review](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code) with a PreToolUse hook, which makes this step a harder gate. That is also effective, but our team has chosen to incorporate our hard code review gate at the test/CI stage of the cycle.

除了塑造和审查代码之外，控制爆炸半径（blast radius）是我们在这一阶段的主要关注点之一。我们通过围绕身份设定硬性边界（详见监控部分），并让开发者在虚拟机上编码来做到这一点。

> In addition to shaping and reviewing code, containing the blast radius is one of our primary concerns at this stage. We do this by setting hard boundaries around identity (more on that in the monitor section) and setting our devs up to code on virtual machines.

把我们的编码迁移到远程虚拟机是一次相对轻松的转变，与仅使用笔记本电脑相比，它给了我们更强的控制力和可见性。这些虚拟机上的智能体流量采用出站白名单（egress-allowlisted）。

> Moving our coding to remote VMs was a relatively painless shift and gave us increased control and visibility compared to laptops alone. Agent traffic on these VMs is egress-allowlisted.

当智能体读取可能携带提示注入（prompt-injection）载荷的不受信任输入时，这些严格的出站控制尤为重要。被注入的指令无法到达互联网上的任意目的地：数据外泄路径被限制在一小组受监控的服务范围内。

> These tight egress controls matter especially when the agent is reading untrusted input which can carry a prompt-injection payload. An injected instruction can’t reach arbitrary destinations on the internet: exfiltration paths are limited to a small set of monitored services.

在这里你同样可以看到针对 AI 原生 SDLC 的明确适配。远程编码过去主要用于保护知识产权（IP），而如今我们看到更成熟的 AI 编码团队把这些环境作为一种约束智能体的手段来采用。

> Here again you can see a clear adaptation for an AI-native SDLC. Remote coding was previously used mainly to contain IP, and today we’re seeing more mature AI coding teams adopt these environments as a means to contain agents.

持久原则：在 AI 原生工程组织中，左移（shift left）意味着闭合漏洞发现与更新指令之间的环路，从而定制 Claude 生成代码的方式。用适当的硬性边界来限制爆炸半径（最小代理权原则，Principle of Least Agency）以及智能体能访问的范围。

> Enduring Principle: Shifting left in an AI-native engineering organization means closing the loop between vulnerability discovery and updating instructions to customize how Claude generates code. Limit the blast radius (Principle of Least Agency) and what an agent can access with hard boundaries as appropriate.

### 测试（CI）

> Test (CI)

根据我的经验，测试或持续集成（CI）阶段很快会成为处于 AI 原生转型过程中的工程团队最痛苦的瓶颈。在 Anthropic，一旦大多数开发者都在使用智能体编码工具并同时运行多个智能体，很快就明显看出团队的推进速度只能与人类审查代码的速度持平。

> In my experience, the test or CI stage quickly becomes the most painful bottleneck for engineering teams in the midst of an AI-native transformation. At Anthropic, once most developers were using agentic coding tools and running multiple agents at one time, it quickly became obvious the team could only move as quickly as humans could review code.

需要明确的是：人类问责仍是我们流程的核心。我们所做的是通过将自动化的智能体审查与确定性审查相结合来加速审查流程，同时把人工审查保留给受监管或真正关键的代码。

> Let’s be clear: human accountability is still central to our process. What we did was accelerate the review process by combining automated agentic and deterministic reviews, while reserving human review for regulated or truly critical code.

历来人工代码审查被视为标准，但[实证证据](https://link.springer.com/chapter/10.1007/978-3-642-36563-8_14)表明它并不完美。安全漏洞经常随软件在世界各地发布。我们的审查流程能够审查更多代码并捕捉尤为复杂的问题，从而帮助降低这些风险。

> Historically, human code review has been held as the standard, yet the [empirical evidence](https://link.springer.com/chapter/10.1007/978-3-642-36563-8_14) has shown it is not perfect. Security bugs regularly ship in software across the world. Our review process is able to review more code and catch particularly complex issues, helping to reduce these risks.

获得实质性审查意见的拉取请求（PR）占比[已从 16% 增长到 54%](https://claude.com/blog/code-review)，因为我们通过要求智能体写出其发现有效的证明，从而对这些发现建立了信心。我们还确定，过去 claude.ai 事故背后大约[三分之一的漏洞本可以被我们现已实施的自动化流程捕捉到](https://www.anthropic.com/institute/recursive-self-improvement)。

> The share of PRs that get substantive review comments [has grown from 16 to 54%](https://claude.com/blog/code-review) as we’ve gained confidence in the findings by requiring the agents to write a proof that their finding is valid. We’ve also determined that approximately [a third of the bugs behind past claude.ai incidents would have been caught](https://www.anthropic.com/institute/recursive-self-improvement)by the automated processes we have now implemented.

我们并非唯一发现这一点的组织。[Intercom 分享过](https://www.intercom.com/blog/ai-is-approving-our-pull-requests-heres-how-we-made-it-safe/)它自动批准了 19% 的 PR。部署量翻倍，而由破坏性代码变更导致的宕机时间下降了 35%。CircleCI 得出了类似的结论，它构建了 Chunk——一个基于 Claude 的自主智能体，用于解决 CI/CD 维护问题，并[在人类看到之前验证自己的修复。该](https://claude.com/customers/circleci)方法使智能体任务转化为已完成拉取请求的比率翻了一倍。

> We’re not the only organization that has found this to be true. [Intercom has shared](https://www.intercom.com/blog/ai-is-approving-our-pull-requests-heres-how-we-made-it-safe/) it auto-approves 19% of its PRs. Deployment doubled while downtime from breaking code changes dropped 35%. CircleCI reached a similar conclusion building Chunk, an autonomous agent on Claude that resolves CI/CD maintenance issues and[validates its own fixes before a human ever sees them. The](https://claude.com/customers/circleci) approach doubled the rate at which agent tasks convert into completed pull requests.

在 Anthropic，当一个 PR 被打开时，多个智能体会自动审查它。每个审查智能体都被设计并限定在一个具体、狭窄的关注点上，并利用检索增强生成（RAG）来获取围绕过往事故的额外上下文和记忆。

> When a PR is opened at Anthropic, multiple agents automatically review it. Each review agent is designed and scoped to a specific, narrow focus and leverages RAG for additional context and memory surrounding past incidents.

这比一个超大提示词或超级安全智能体更有效，原因有几点：

> This is much more effective than one mega-prompt or super security agent for a few reasons:

- 它们不共享偏见和盲点
- 如果其中一个被攻陷或犯了错误，可以被其他审查者捕捉到
- 精力不会在多个关注领域上摊得太薄

> • They do not share biases and blindspots
> • If one is compromised or makes a mistake, it can be caught by other reviewers
> • Effort isn’t spread too thinly across multiple focus areas

需要明确的是，智能体不会未经检查就把代码合并到生产环境。我们按风险对代码库分级，并就哪些部分要自动化做出审慎决定。整个代码库都有严格的人工批准流程。

> To be clear, agents aren't merging code to production unchecked. We tier our codebase by risk, and make deliberate decisions on what parts to automate. Entire codebases have strict human approval processes.

对于由 Claude 审查并合并的代码，人类问责仍是核心。每一次批准都会连同背后的信号和推理一起被记录，并由人类审查一个按风险加权抽取的样本。另一轮测试聚焦于诸如“用户 A 永远无法读取用户 B 的数据”这类不变量，并触发额外的人工审查。我们还将智能体扫描与静态应用安全测试（SAST）工具相结合，后者会直接在 PR 上发布结果。

> Human accountability is still central for code that is reviewed and merged by Claude. Every approval is logged with the signals and reasoning behind it, and a risk-weighted sample is reviewed by humans. Another round of testing focuses on invariants like “user A can never read user B’s data,” and triggers additional manual reviews.We combine our agentic scans with SAST tools as well, which post directly on PRs.

大多数扫描方法，无论是智能体式还是确定性的，都是基于消耗量的。随着代码吞吐量增加，成本会上升，团队需要决定何种覆盖水平对他们而言是合适的。

> Most scanning approaches, whether agentic or deterministic, are consumption based. Costs will increase as code throughput increases, and teams will need to decide what level of coverage is appropriate for them.

在 Anthropic，我们接受这里的成本会随着代码速度的提升而增长，但预期单位成本会下降。如今的模型在编码上远胜于几年前的所有模型，我们预期这一模式将持续下去。

> At Anthropic, we accept costs here will grow as our code velocity increases, but anticipate unit cost will fall. Models today are much better at coding than all models from a few years ago, and we anticipate that this pattern will continue.

恒久原则：自动化审查是一种不同类型的风险，需要以不同方式来控制（通过多个关卡以及拥有独立上下文窗口的多个智能体）。人类仍处于闭环之中，但根据代码库的性质，可能处于生命周期的不同位置。

> Enduring Principle: Automated reviews are a different type of risk that is controlled differently (through multiple gates and agents with separate context windows). Humans stay in the loop, but may be in different places in the lifecycle depending on the nature of the codebase.

### 部署（CD）

> Deploy (CD)

Anthropic 维护着一个稳健的预发布环境（staging environment），我们在其中执行常见的安全最佳实践，例如为重大发布进行外部渗透测试，以及定期的动态应用安全测试（DAST）扫描，以捕捉静态扫描遗漏或无法发现的逻辑缺陷。

> Anthropic maintains a robust staging environment where we execute common security best practices such as external pentesting for major launches and periodic DAST scans to catch logic bugs that static scans have missed or can’t see.

和 SDLC 的其他阶段一样，AI 对安全团队既带来新挑战，也带来新解法。一方面，能进入这个阶段的漏洞更少了；另一方面，那些幸存下来的漏洞往往是最隐蔽、最难捕捉的。

> Like the other SDLC stages, AI presents both new challenges and solutions for security teams. On one hand, fewer vulnerabilities reach this stage. On the other, the vulnerabilities that do survive are among the most subtle and difficult to catch.

再加上更大量的代码以更高的频率被发布，定期的动态测试就显得不那么“动态”了。

> Combine that with larger volumes of code being shipped more frequently, and periodic dynamic testing doesn’t seem so dynamic anymore.

好消息是，AI 模型在跨组件、多步骤推理方面表现更好，能捕捉到更高比例的这类复杂漏洞。例如，今年二月，我们披露 Claude 发现并帮助修复了超过 [500 个高危开源软件漏洞](https://www.anthropic.com/research/zero-days)。

> The good news is that AI models are better on the multi-step, cross-component reasoning that can catch a greater percentage of these complex vulnerabilities. For example, in February, we disclosed that Claude discovered and helped to fix more than [500 high-severity OSS vulnerabilities](https://www.anthropic.com/research/zero-days).

在 Anthropic，我们正在预发布环境中实施持续的、由 AI 驱动的 DAST 扫描。它们在系统层面寻找漏洞，即两个或多个服务之间的假设不一致之处。目前已有不少厂商提供此类能力。

> At Anthropic, we are implementing continuous AI-powered DAST scans in our staging environment. These look for vulnerabilities at the system level where the assumptions between two or more services are incorrect. There are a number of vendors that offer these capabilities today.

持久原则：动态测试应与部署节奏相匹配。

> Enduring Principle: Dynamic testing should match deployment cadence.

### 监控

> Monitor

任何优秀的安全团队都清楚，代码推送到生产环境后工作并未结束。我们可以假设，任何漏洞都会被日益老练的攻击者迅速发现。

> As any good security team knows, the job isn’t done once code is pushed to prod. We can assume any vulnerability will be quickly identified by increasingly sophisticated attackers.

我们的安全团队在此实施了一些标准实践，例如[公开漏洞赏金计划](https://hackerone.com/anthropic)、红队模拟攻击，以及对我们的依赖项、密钥、供应链、云安全态势和容器进行定期漏洞扫描。

> Our security team has implemented programs here that are standard practice such as a [public bug bounty program](https://hackerone.com/anthropic), red team simulated attacks, and regular scans for vulnerabilities across our dependencies, secrets, supply chain, cloud posture, and containers.

Claude 在这些工作中扮演了重要角色，但我们将聚焦于 AI 原生 SDLC 给监控工作带来的更大变化：告警分诊（alert triage）和代码迁移。

> Claude plays a large role in these, but we’ll focus on larger changes to our monitoring efforts as a result of our AI-native SDLC: alert triage and code migrations.

当 Anthropic 触发一个告警时，Claude 会开始：

> When an alert fires at Anthropic, Claude starts:

- 审查生产日志
- 对漏洞进行根因分析；
- 撰写事后复盘（post-mortem）；在某些情况下还会
- 编写修复漏洞的代码变更。

> • Reviewing the production logs
> • Root-causing the bug;
> • Writing the post-mortem; and in some cases
> • Writing the code change to fix the bug.

这个智能体无法做的是自动部署修复。它是一个单一用途的系统账户智能体，拥有三项权限：可以撰写新文档、在公司频道发帖，以及访问生产日志。

> What this agent can’t do is deploy the fix automatically. It’s a single-purpose system account agent with three permissions: it can write new docs, post in company channels, and access production logs.

修复要么来自另一个智能体—人类审查系统。原因还是回到对身份、权限和硬边界的管理：在把代码推向生产环境时，控制影响范围（blast radius）非常重要。分离智能体至关重要，因为一个（或多个）智能体充当对另一个的校验。

> The fix either needs to come from a separate agent-human reviewer system. The reason for this comes back to managing identity, permissions, and hard boundaries: it’s important to contain the blast radius when pushing code into production. Separating agents is critical as one (or multiple) agents act as checks on the other.

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a5faaaf38e56da47cb6564d_permission-boundary-diagram.png)

这对 CISO 来说也是一个重要教训，而我是通过惨痛的方式学到的。在考虑一个智能体的硬边界时，你需要把它对其他智能体的访问权限也纳入其中。

> This is also an important lesson for CISOs, and one that I had to learn the hard way. When considering an agent’s hard boundaries you need to include its access to other agents.

在一次模型升级后，事件响应智能体主动通过 Slack 联系了另一个 Claude 实例。它请求那个能够编写代码的智能体去推送修复。这在设计好的人类审查关卡处被拦截了，但这次经历教会我们，要围绕访问权限和行为来划定边界，而不是围绕模型的指令或我们认为模型能做什么来划边界。如今在 Anthropic，智能体之间在 Slack 上的通信已成为常态，我们对[智能体身份模型](https://claude.com/blog/agent-identity-access-model)投入了大量思考。

> Following a model upgrade, the incident response agent reached out over Slack to another Claude instance on its own initiative. It asked the agent, which could write code, to push the fix. This was caught at a human review gate as designed, but this experience taught us to draw the boundary around access and actions, not around a model’s instructions or what we believe a model can do. Today at Anthropic, agent-to-agent communication on Slack is the norm and we give considerable thought to [agent identity models](https://claude.com/blog/agent-identity-access-model).

第二个重大变化是我们团队处理迁移的方式。每个安全工程团队都经历过这样的时刻：意识到必须进行一次代码迁移，才能修复公司运作方式中某个系统性缺陷。过去，CISO 需要发起动员，请求各部门拿出一小部分工程资源，历时数个季度才能把它修好。

> The second major change is how our team approaches migrations. Every security engineering team has experienced the moment where they realize a code migration will be necessary to fix some systemic flaw in the way the company operates. In the past, the CISO would need to start campaigning and request a small percentage of each department’s engineering resources for multiple quarters to get it fixed.

迁移的经济成本已经下降，跨公司协调的成本也随之下降。Claude 能[在数天内自动完成迁移过程，涉及数万行代码](https://claude.com/blog/ai-code-migration)。

> The economic cost of migration has fallen and so too has the cost of cross company coordination. Claude [automates the migration process, tens of thousands of lines of code, in days](https://claude.com/blog/ai-code-migration).

恒久原则：给每个智能体一个单一用途的身份，并只授予其工作所需的最小权限。如果你确实允许智能体相互协调，就让它们通过与人类相同的渠道来进行。

> Enduring Principle: Give every agent a single-purpose identity with the minimum permissions for its job. If you do let agents coordinate, have them do so over the same channels as humans.

### 治理

> Governance

我们已将许多安全流程自动化，但在保障安全的软件开发生命周期中，人仍然是不可或缺的一部分。只不过，我们的注意力不再集中于审查代码和缺陷报告，而是转向了 Claude Tag、循环（loops）和仪表盘。

> We have automated many of our security processes, but humans are still very much an integral part of ensuring a secure software development lifecycle. But instead of focusing on reviewing code and bug reports, our attention is now focused on Claude Tag, loops, and dashboards.

这凸显了强有力治理的重要性。如果某项技能（skill）过时了、某类被发现的缺陷从未回写进 CLAUDE.md、或者某个智能体的决策未经抽样检查，整个结构就会退化。我们通过以下方式来避免这种情况：

> This underscores the importance of strong governance. If a skill goes stale, a discovered bug class never makes it back into CLAUDE.md, or an agent's decisions go unsampled, the whole structure degrades. We avoid this by:

- 按风险对代码库分级，然后基于该级别自动化审查。
- 对所有新的 AI 审查者采用影子模式（shadow mode）。新智能体先发布评论供人工批准，直到赢得信任为止。我们的团队还会对它们进行“红队演练”，尝试植入恶意变更。
- 对所有自动批准中的一定比例进行抽样。
- 关注我们的生命体征。我们维护并密切监控一个仪表盘，它汇总了每个安全流程和工作流中的关键指标。
- 将每个智能体动作路由到 SIEM。每一次自动批准、工具调用以及智能体之间的消息，都会连同其所使用的信号一起被记录下来，并进入我们的 SIEM，这样任何决策事后都可归因、可审计。我们利用这些数据，将这些智能体视为一种新型内部威胁（insider threat），并在它们行为偏离预期时触发告警。

> • Tiering our codebase by risk and then automating reviews based on that level.
> • Shadow mode for all new AI reviewers. New agents post comments for human approval until trust is earned. Our team also “red teams” them and tries to insert malicious changes.
> • Sampling a percentage of all automated approvals.
> • Watching our vitals. We maintain and closely monitor a dashboard that rolls up key metrics across every security process and workstream.
> • Routing every agent action to the SIEM. Every automated approval, tool call, and agent-to-agent message is logged with the signals it used and lands in our SIEM, so any decision is attributable and auditable after the fact. We use this data and treat these agents as a new type of insider threat, and raise alerts when they act out of alignment.

恒久原则：安全工程师的工作从监控缺陷演变为监控循环。

> Enduring Principle: The security engineer’s job evolves from monitoring bugs to monitoring loops.

### 唯一不变的就是变化

> The only constant is change

软件开发生命周期以及强化它的手段正在以何等速度演进，怎么强调都不为过。模型能力每月都在进步，既带来新挑战，也带来新解决方案。

> It’s hard to overstate just how fast the software development lifecycle, and the means of hardening it are evolving. Model capabilities advance every month, bringing both new challenges and solutions.

今天还行不通或经济上还不太可行的事情，很可能很快就会变得可行。对你的团队而言，正确的问题不是"我们负担得起扫描一切吗？"，而是"如果扫描几乎免费，我们会运行什么？"请为此做好规划。

> What doesn’t quite work today or isn’t quite economically feasible likely will be soon. The right question for your team isn't "can we afford to scan everything?" but "what would we run if scanning were nearly free?" Plan for that.

本文由 Anthropic 副首席信息安全官（Deputy CISO）Jason Clinton 撰写。他要感谢 Michael Segner 对本文的贡献。

> This article was written by Jason Clinton, Deputy CISO, Anthropic. He’d like to thank Michael Segner for his contributions to this article.

## 术语对照

| English | 中文 |
|---|---|
| software development lifecycle (SDLC) | 软件开发生命周期 |
| AI-native | AI 原生 |
| prompt injection | 提示注入 |
| supply-chain poisoning | 供应链投毒 |
| dependency poisoning | 依赖投毒 |
| blast radius | 爆炸半径 |
| shift left | 安全左移 |
| human in the loop | 人类在环 |
| agentic loop | 智能体循环 |
| project security review (PSR) | 项目安全评审 |
| knowledge index | 知识索引 |
| Zero Trust for Agents | 智能体零信任 |
| dogfooding | 内部试用 |
| Amdahl's Law | 阿姆达尔定律 |
