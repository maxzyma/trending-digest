---
source: claude-blog
source_url: https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense
published_at: 2026-04-10
category: Claude Blog
title_en: Preparing your security program for AI-accelerated offense
title_zh: 为 AI 加速的攻击做好安全防护准备
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 5
source_image_count: 0
---

# 为 AI 加速的攻击做好安全防护准备

> ⌁ Preparing your security program for AI-accelerated offense

> 来源：Claude Blog，2026-04-10
> 原文链接：https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense
> 分类：Claude Blog

## 核心要点

- AI 模型大幅降低了发现并利用软件漏洞所需的资源、时间和技能门槛；未来 24 个月内，大量长期潜伏的漏洞将被 AI 发现并串联成可用的利用链。
- 攻击者能借助 AI 加速，防御者同样可以——本文给出基于一线实践的安全建议与可操作技巧。
- 优先级建议包括：立即缩小补丁差距、为大幅增加的漏洞报告量做准备、在上线前发现漏洞、扫描现有代码库中的未知漏洞。
- 在架构上应"为被攻破而设计"（design for breach）：采用零信任、绑定硬件身份、短期令牌，并削减、盘点暴露面。
- 缩短事件响应时间，把模型放在告警队列前端进行首轮分流，并将记录、取证等工作交给 AI。
- 向外提交漏洞报告时，必须经人工核验、说明影响、给出可复现案例和补丁，并主动披露 AI 参与情况。

## 正文

人工智能正在改变漏洞被发现和利用的速度。我们基于自身的发现与安全实践，发布了一套初步建议，帮助你巩固自身防御。

> ⌁ AI is changing the speed at which vulnerabilities are found and exploited. We're publishing an initial set of recommendations to shore up your defenses based on our own findings and security practices.

本周早些时候，我们发布了"玻璃翼计划"（Project Glasswing）——这是我们将最新前沿模型 Claude Mythos Preview 强大的网络安全能力用于防御目的的紧迫尝试。在该公告以及配套的技术博客文章中，我们描述了 AI 模型如何正在迅速降低发现和利用软件漏洞所需的资源、时间和技能门槛。

> ⌁ Earlier this week, we announced Project Glasswing—our urgent attempt to put the strong cybersecurity capabilities of our newest frontier model, Claude Mythos Preview, to use for defensive purposes. In the announcement —and the accompanying technical blog post —we described how AI models are rapidly reducing the required resources, time, and skill required to find and exploit vulnerabilities in software.

着眼于 AI 闪电般的进展，我们还指出，具有同等能力水平的模型被广泛获取已为时不远。在未来 24 个月内，大量潜伏在代码中、可能已存在多年而无人察觉的漏洞，将被 AI 模型发现，并串联成可用的攻击利用链。事实上，目前已经出现这样的情况：公开可获取的、能力低于 Mythos 级别的模型，就能找出传统审查长期遗漏的严重漏洞。

> ⌁ With an eye on the lightning-fast progress of AI, we also noted that it will not be long before models of similar capability levels are widely available. Within the next 24 months, vast numbers of bugs that sat unnoticed in code, possibly for years, will be found by AI models and chained into working exploits. Indeed, it is already the case that publicly available, sub-Mythos-level models can find serious vulnerabilities that traditional reviews have missed for long periods of time.

所幸的是，这是双向的：尽管攻击者可以借助 AI 行动得更快，采用 AI 工具来保护自身的防御者同样可以。在本文中，我们基于安全团队和研究人员在使用前沿 AI 模型保护真实代码库和系统时所观察和学到的经验，提供安全建议和实用技巧。我们希望，在进入 AI 驱动的网络安全时代之际，安全团队及其他读者会发现这些建议有所帮助。

> ⌁ Thankfully, this works both ways: although attackers can use AI to move faster, so can defenders who adopt AI tools to secure themselves. In this post, we offer security recommendations and practical tips based on what our security teams and researchers have observed and learned from using frontier AI models to secure real codebases and systems. We hope security teams and others will find this advice useful as we enter the age of AI-driven cybersecurity.

下面的许多建议已是现有安全共识的一部分；我们根据哪些控制措施经受住了考验、哪些出现了退化来对它们进行优先级排序。如果贵组织依据 SOC 2 和 ISO 27001 进行合规报告，这些建议将直接对应到你已在跟踪的控制项上。

> ⌁ Many of the pieces of advice below are already part of the existing security consensus; we have prioritized them according to which controls we have seen hold and which we have seen degrade. If your organization reports against SOC 2 and ISO 27001, these will map directly onto controls you are already tracking.

随着我们及"玻璃翼计划"的合作伙伴持续推进网络安全工作，我们将不断更新本指南。

> ⌁ We’ll update this guidance as we and our Project Glasswing partners continue our cybersecurity work.

### 现在该做什么

> What to do now

#### 1. 弥补补丁缺口

> 1. Close your patch gap

AI 模型非常擅长在未打补丁的系统中识别已知且已修复漏洞的特征。将补丁逆向还原为可用的利用代码（exploit），正是这类模型擅长的机械化分析。这意味着从补丁发布到利用代码出现之间的窗口正在缩小。

> ⌁ AI models are very effective at recognizing the signatures of known, already-patched vulnerabilities in unpatched systems. Reversing a patch into a working exploit is exactly the kind of mechanical analysis at which these models excel. This means that the window between a patch being published and an exploit becoming available is shrinking.

- 立即修补 CISA 已知被利用漏洞（KEV）目录中的所有内容。该目录收录了已确认正在被主动利用的漏洞。该列表中任何可从网络访问的项目都应被视为紧急情况处理。
- 用 EPSS 来排定其余项的优先级。利用预测评分系统（EPSS）每日更新某个通用漏洞披露（CVE）在未来 30 天内被利用的概率。先修补 KEV 列表，再修补所有高于所选 EPSS 阈值的项，可以帮你把成千上万个未处理的 CVE 变成可管理的队列。
- 缩短面向互联网系统的修补时间。我们建议在利用代码出现后 24 小时内修补面向互联网的应用，对其他漏洞则在数天内修补。
- 在自动更新引发宕机的风险可接受的情况下，自动化补丁部署与重启。人工审批步骤会增加延迟，而延迟如今是首要风险。

> ⌁ - Patch everything on the CISA Known Exploited Vulnerabilities (KEV) catalog immediately. This catalog contains vulnerabilities that are confirmed to be under active exploitation. Anything on this list which is reachable from a network should be treated as an emergency.
> - Use EPSS to prioritize the rest. Exploit Prediction Scoring System (EPSS) provides a daily-updated probability that a given Common Vulnerability and Exposure (CVE) will be exploited in the next 30 days. Patching the KEV list first and then everything above a chosen EPSS threshold will help you turn thousands of open CVEs into a manageable queue.
> - Reduce time-to-patch on internet-exposed systems. We recommend patching internet-facing applications within 24 hours of an exploit becoming available, and within days for other vulnerabilities.
> - Automate patch deployment and reboots where the risk of an automated update causing an outage is acceptable. Manual approval steps add delay, and delay is now the primary risk.

实用提示：大多数云和操作系统厂商已经提供补丁自动化；启用它通常只是一个简单的配置更改。对于容器镜像和依赖清单，有若干开源扫描器可作为单个持续集成（CI）步骤运行，并用 KEV 目录和 EPSS 的数据为 CVE 做注解，因此优先级排序是内置的。

> ⌁ Practical tip: Most cloud and OS vendors already ship patch automation; enabling it is often a simple configuration change. For container images and dependency manifests, several open-source scanners run as a single continuous integration step and annotate CVEs with data from the KEV catalogue and EPSS, so prioritization is built in.

#### 2. 为应对数量大得多的漏洞报告做好准备

> 2. Prepare to handle a much higher volume of vulnerability reports

在大约未来两年里，你用来接收、排序和修复漏洞（既包括自有代码中的，也包括从厂商购买的软件中的）的流程，将承受比今天大得多的压力。你的漏洞管理流程应当为来自厂商和上游的更多补丁做规划。

> ⌁ Over approximately the next two years, the processes you use to receive, prioritize, and fix vulnerabilities (both in your own code and in the software you buy from vendors) will be under far more pressure than they are today. Your Vulnerability Management process should plan for many more patches, from vendors and upstream.

- 为发现数量增加一个数量级做规划。接收、分诊（triage）和修复跟踪等环节需要跟上不断增加的暴露漏洞数量。如果你的安全会议仍然围绕一张电子表格和每周一次的会议来运作，你很可能跟不上节奏。值得考虑引入一定程度的自动化——当然要让人保持在环（humans in the loop），以应对这里的庞大数量。
- 检查开源依赖的安全性。大多数软件供应链以开源为主。大多数开源项目没有服务级别协议，也没有维持高安全水平的承诺。OpenSSF Scorecard 会基于分支保护、模糊测试覆盖率、已签名发布和维护者活跃度等信号，自动为每个依赖项打分。它在 CI 中运行，有助于识别无人维护的软件包。
- 对你的厂商提出同样的期望。你的第三方风险管理流程应当询问供应商：他们自己如何为加速的利用时间线做准备，以及他们是否在扫描自己的代码。

> ⌁ - Plan for an order-of-magnitude increase in finding volume. Aspects like intake, triage, and remediation tracking need to keep pace with the increasing numbers of vulnerabilities being exposed. If your security meetings are still built around a spreadsheet and a weekly meeting, it’s unlikely that you’ll keep up. It’s worth considering some amount of automation—with, of course, humans in the loop, to assist with the sheer volume here.
> - Check the security of your open-source dependencies. Most software supply chains are mostly open source. Most open-source projects have no service-level agreement or commitment to maintain a high level of security. OpenSSF Scorecard automatically scores every dependency on signals like branch protection, fuzzing coverage, signed releases, and maintainer activity. It runs in CI and helps to identify unmaintained packages.
> - Apply the same expectations to your vendors. Your third-party risk management process should ask suppliers how they are themselves preparing for accelerated exploit timelines and whether they are scanning their own code.

实用提示：研究那些评估脆弱代码可达性的开源软件和第三方服务。建立自动化流程，通过对更新进行回归测试来获得快速部署的信心，从而持续地向你的 IT 和生产基础设施交付新的软件更新。

> ⌁ ‍ Practical tip: Look into open source software and third-party services that evaluate the reachability of vulnerable code. Build automated processes that continuously deliver new software updates to your IT and production infrastructure, by doing regression testing on updates to gain confidence that you can deploy them quickly.

上面我们提到了这些流程的自动化。AI 可以在以下几个重要方面提供帮助：

> ⌁ Above we mentioned automation of these processes. There are a number of important ways that AI can assist:

- 加快分诊。分诊是一个瓶颈，因为它需要专家审查和分类。前沿模型（frontier model）可以将新发现与既有待办项去重，利用它对你资产的了解来估计暴露程度，并起草修复工单，其中受影响的代码路径已被预先识别。
- 检查依赖中的冗余。大多数大型代码库会积累多个执行相同工作的库（几个 HTTP 客户端；几个 JSON 解析器）。这给了攻击者更多机会，而你却毫无功能上的收益。把大语言模型（LLM）对准一个锁文件（lockfile），询问哪些依赖相互重叠（以及迁移和整合会是什么样子），是一个往往很划算、只需一小时的工作。
- AI 升级自动化。前沿模型越来越有能力生成可随漏洞报告一同附上的补丁。当报告清晰而详尽，甚至附带概念验证（proof-of-concept）时，模型可以直接测试补丁，以确认利用路径已被封堵。它还可以直接自动化接受上游补丁的过程，验证升级不会破坏测试或内部系统。
- AI 自托管（vendoring）。一些小型依赖在 OpenSSF Scorecard 上得分很低——也许是因为它们没有得到积极维护。你不应继续依赖这些；相反，你应当考虑让 LLM 自己编写代码，重新实现你实际用到的功能。

> ⌁ - Speeding up triage. Triage is a bottleneck, because it requires expert review and classification. A frontier model can deduplicate findings against an existing backlog, use its knowledge of your assets to estimate exposure, and draft remediation tickets where the affected code paths are pre-identified.
> - Check your dependencies for redundancy. Most large codebases accumulate multiple libraries doing the same job (several HTTP clients; several JSON parsers). This gives attackers more opportunity, all for no functional gain on your part. Pointing an LLM at a lockfile and asking which dependencies overlap (and what migration and consolidation would look like) is a one-hour exercise that often pays off.
> - AI upgrade automation. Frontier models are increasingly capable of generating patches to include alongside vulnerability reports. When the report is clear and thorough, maybe even with a proof-of-concept, the model can directly test the patch to confirm that the exploit path is closed. It can also directly automate the process of accepting the upstream patch, validating that the upgrade doesn’t break tests or internal systems.
> - AI vendoring . Some small dependencies will score poorly on the OpenSSF Scorecard—perhaps because they’re not actively maintained. You shouldn’t continue to rely on these; instead, you should consider having an LLM write its own code to reimplement the functionality you actually use.

#### 3. 在发布之前找出漏洞

> 3. Find bugs before you ship them

预防永远胜于补救。你应当假设进入生产环境的漏洞最终会被发现，因此安全测试必须远在那之前完成。

> ⌁ Prevention is always better than cure. You should assume that bugs that reach production will eventually be found, so your security testing needs to happen well before.

- 将静态分析和 AI 辅助的代码审查纳入持续集成（CI）流水线，并对高置信度的发现阻断合并。如果误报使这一做法不切实际，你应保留检查，但改进工具。OWASP 应用安全验证标准（Application Security Verification Standard）定义了三种不同严格程度下“通过”测试的标准。
- 将自动化渗透测试纳入持续交付流水线。你可以对预发布环境运行与攻击者将对你生产系统运行的相同扫描。
- 保护构建流水线。能够在提交与部署之间注入代码的攻击者无需寻找漏洞。SLSA 安全框架提供了分级路径：较低级别确立哪次提交产生了哪个构件，较高级别则使构建本身可验证。
- 采用“设计即安全”（Secure by Design）实践。CISA 的承诺条款（默认启用多因素认证；不使用默认密码；透明的漏洞报告）是一个合理的最低标准。
- 新代码优先采用内存安全语言。大量严重漏洞是内存安全缺陷，而这些缺陷不会出现在 Rust、Go 或托管运行时中。CISA、NSA 和 NCSC 已发布了有用的路线图。现有的 C/C++ 代码不必重写，但新的 C/C++ 代码应当要求给出理由。AI 辅助的重写也越来越可行。

> ⌁ - Add static analysis and AI-assisted code review to your continuous integration pipeline, and block merges on high-confidence findings. If false positives make this impractical, you should keep the check, but address the tooling. The OWASP Application Security Verification Standard defines what “passing” a test looks like at three different levels of rigor.
> - Add automated penetration testing to your continuous delivery pipeline. You can run the same scanning for staging that attackers will run against your production systems.
> - Secure the build pipeline. An attacker who can inject code between commit and deployment does not need to find a vulnerability. The SLSA security framework provides a graded path: lower levels establish which commit produced which artifact, and higher levels make the build itself verifiable.
> - Adopt Secure by Design practices. CISA’s pledge commitments (multi-factor authentication by default; no default passwords; transparent vulnerability reporting) are a reasonable minimum bar.
> - Prefer memory-safe languages for new code. A large share of severe vulnerabilities are memory-safety bugs that do not occur in Rust, Go, or managed runtimes. CISA, the NSA, and the NCSC have published useful roadmaps . Existing C/C++ code does not need to be rewritten, but new C/C++ code should require a justification. AI assisted rewrites are increasingly viable, as well.

实用提示：作为 CI 动作运行、带有 OWASP Top 10 及特定语言规则集的静态应用安全测试（SAST）工具已广泛可得，既有开源的，也有内置于代码托管平台中的（GitHub 上的 CodeQL 是最常见的起点）。要评估构建来源（provenance），OpenSSF 发布了一个可复用的工作流，能从 GitHub Actions 生成 SLSA 三级证明；采用它所需的工作远比 SLSA 规范看上去的要少。

> ⌁ Practical tip: Static application security testing (SAST) tooling that runs as a CI action with OWASP Top 10 and language-specific rule sets is widely available, both open-source and built into code hosting platforms (CodeQL on GitHub being the most common starting point). To assess build provenance, OpenSSF publishes a reusable workflow that produces SLSA Level 3 attestations from GitHub Actions; adopting it is significantly less work than the SLSA spec suggests.

与前面一样，这里也有一些借助 AI 加速此项工作的明确机会：

> ⌁ As before, there are some clear opportunities for accelerating this work with AI:

- AI 漏洞扫描。其逻辑很直接：你应当用攻击者会使用的同类模型来扫描自己的代码和系统，赶在他们之前。这种做法只需要一个隔离的智能体、一个用于过滤噪声的验证步骤，以及一条接入你现有分级流程的通道。今天用大语言模型（LLM）就能做到。如果本节你只实施一件事，就实施这件。
- 补丁生成。当 SAST 或扫描器产生一项发现时，前沿模型通常能为其提出补丁。这并不消除审查的必要，但它把开发者的工作从“理解缺陷并编写修复”转变为“验证所提补丁是否正确”。后者更快。同样的做法也适用于向内存安全迁移：LLM 可以把一个自包含的 C 模块连同测试一起移植到 Rust；审查者可以验证两者等价，而不必从头编写全部内容。

> ⌁ - AI vulnerability scanning. The logic here is straightforward: you should scan your own code and systems with the same kind of model an attacker would use, before they do. This approach just requires an isolated agent, a verification step to filter noise, and a path into your existing triage process. You can do this with an LLM today. If you implement one thing from this section, implement this.
> - Patch generation. When SAST or a scanner produces a finding, a frontier model can usually propose a patch for it. This does not remove the need for review, but it changes the developer’s job from “understand the bug and write a fix” to “verify a proposed fix is correct.” The latter is faster. The same approach applies to memory-safe migration: LLMs can port a self-contained C module to Rust with tests; a reviewer can validate the equivalence rather than writing the whole thing from scratch.

#### 4. 找出代码中已存在的漏洞

> 4. Find the vulnerabilities already in your code

打补丁应对的是你所依赖软件中的已知漏洞。但你自己的代码库中含有未知漏洞。大多数长期运行的生产代码已被人工审查过许多次，却从未被前沿模型检视过，而这类分析往往能浮现出此前被忽视的新问题。主动扫描可以在攻击者自己发现之前，识别出现代 LLM 力所能及范围内的漏洞。

> ⌁ Patching addresses known vulnerabilities in software you depend on. But your own codebase contains unknown ones. Most long-running production code has been reviewed by humans many times, but has never been examined by a frontier model, and that kind of analysis tends to surface new, previously-overlooked issues . Proactively scanning can identify vulnerabilities that are within the reach of modern LLMs before attackers discover them themselves.

- 按暴露程度排序。从解析不可信输入、执行认证或授权决策，或可从互联网访问到的代码入手。这些路径上的发现最有可能要紧。
- 纳入遗留代码。早于当前审查实践、或原作者已离开的代码，往往是最久未受审视的。那里正是一次全新审查收益最大的地方。
- 为修复留出预算。一次结构良好的模型扫描对较旧代码产生的发现通常比铺开 SAST 要少，但其中真实问题的比例更高。要规划工程时间来修复这些缺陷。

> ⌁ - Prioritize by exposure. Start with code that parses untrusted input, enforces an authentication or authorization decision, or is reachable from the internet. These are the paths where a finding is most likely to matter.
> - Include legacy code. Code that predates current review practices, or whose original authors have moved on, often has the least recent scrutiny. That’s where you have the most to gain from a fresh pass.
> - Budget for remediation. A well-structured model scan of older code typically produces fewer findings than a SAST rollout, but a higher share of them are real. Plan engineering time to fix the bugs.

实用提示：挑选一个面向互联网、当前负责人很少的服务，扫描其输入处理与认证逻辑。在隔离环境中运行智能体，并加入一个验证步骤，以便针对已确认的发现采取行动。把一个服务做到位，是估算更大规模计划成本的合理依据。

> ⌁ Practical tip: Pick one internet-facing service with few current owners and scan its input handling and auth logic. Run the agent in isolation and add a verification step so you’re acting on confirmed findings. One service done properly is a reasonable basis for estimating what a broader program will cost.

#### 5. 为被攻破而设计

> 5. Design for breach

攻击者会设法在某处取得立足点。你需要限制他们从那里能够触及的范围。

> ⌁ Attackers will try to get a foothold somewhere. You need to limit what they can reach from there.

那些价值来自增加摩擦——使攻击变得繁琐——而非构成硬性屏障的缓解措施（额外的跳转环节、速率限制、非标准端口、基于短信的多因素认证），对一个能够熬过这些繁琐步骤的对手要无效得多。下面我们的建议偏向那些即便攻击者有无限耐心也依然成立的控制手段：与硬件绑定的凭证、会过期的令牌，以及根本不存在的网络路径，而非仅仅是不方便的路径。

> ⌁ Mitigations whose value comes from friction—making an attack tedious —rather than a hard barrier (extra pivot hops, rate limits, non-standard ports, SMS-based MFA) are much less effective against an adversary that can grind through those tedious steps. Our recommendations below favor controls that hold even when the attacker has unlimited patience: hardware-bound credentials, expiring tokens, and network paths that do not exist rather than paths that are merely inconvenient.

- 采用零信任架构。对服务之间的每一个请求都进行身份认证和授权，如同它来自互联网一样。CISA 的零信任成熟度模型（Zero Trust Maturity Model）和 NCSC 的零信任原则都提供了分阶段的采用路径。
- 将访问权限绑定到经过验证的硬件，而非凭据。生产系统和敏感的内部工具应只能从具有经认证硬件身份的受管员工设备访问，并搭配抗钓鱼的双因素认证（FIDO2 或通行密钥）。仅凭被盗凭据绝不应足以获得访问权限。即使是生产服务之间的调用，也应植根于硬件身份。
- 按身份隔离服务。被攻陷的构建服务器不应能够查询生产数据库。被攻陷的笔记本电脑不应能够触及构建基础设施。要在接收端强制执行这一点：每个工作负载都应携带自己的加密身份，每个服务应只接受其策略名称中所指定的特定调用方的连接。网络分段仍可缩小波及范围、减少噪声，但它只是一道后备防线。
- 用短期令牌取代长期密钥。静态 API 密钥、嵌入式凭据和共享的服务账户密码，是借助模型辅助代码分析的攻击者最先会找到的东西之一。应使用由身份提供方签发的、范围狭窄的短期令牌。

> ⌁ - Adopt zero trust architecture. Authenticate and authorize every request between services as if it came from the internet. CISA's Zero Trust Maturity Model and the NCSC's zero trust principles both provide staged adoption paths.
> - Tie access to verified hardware rather than credentials. Production systems and sensitive internal tools should only be reachable from managed employee devices with attested hardware identity, paired with phishing-resistant 2FA (FIDO2 or passkeys). Stolen credentials alone should never be sufficient to gain access. Even calls between production services should be rooted in hardware identity.
> - Isolate services by identity. A compromised build server should not be able to query production databases. A compromised laptop should not be able to reach build infrastructure. Enforce this at the receiving end: every workload should carry its own cryptographic identity, and each service should accept connections only from the specific callers of its policy names. Network segmentation can still reduce blast radius and noise, but it is a backstop.
> - Replace long-lived secrets with short-lived tokens. Static API keys, embedded credentials, and shared service-account passwords are among the first things an attacker with model-assisted code analysis will find. Use short-lived, narrowly-scoped tokens issued by an identity provider.

实用提示：完整的零信任是一项跨越数年的工程，但身份感知的访问代理（identity-aware access proxy）能在内部服务前面加上一道经设备验证、MFA 把关的访问层，而无需从根本上改变这些服务的架构。各大主流云厂商都提供原生选项，针对本地部署或多云环境也存在若干开源和商业替代方案。对于密钥，每家主流云都有托管的密钥存储；把那个被共享得最广的单一凭据迁入其中并轮换，是推动其余工作的一个有用契机。

> ⌁ Practical tip: Full zero-trust is a multi-year program, but an identity-aware access proxy puts device-verified, MFA-gated access in front of internal services without having to fundamentally change their architecture. Each major cloud provider offers a native option, and several open-source and commercial alternatives exist for on-premises or multi-cloud environments. For secrets, every major cloud has a managed secrets store; moving the single most widely-shared credential into one and rotating it is a useful forcing function for the rest.

#### 6. 减少并盘点你所暴露的内容

> 6. Reduce and inventory what you expose

本节基于两条重要原则。其一，你无法防御自己不知道的系统。其二，暴露面越小，可供攻击的东西就越少。

> ⌁ This section is based on two important principles. First, you cannot defend systems you don’t know about. Second, the smaller the exposed surface, the less there is to attack.

- 对系统中每一台面向互联网的主机、服务和 API 端点维护一份最新的清单。攻击者可以运行自动化侦察；你的清单至少应当同样准确。要把这些系统纳入渗透测试和红队演练。
- 下线未使用的系统。没有明确归属的遗留服务通常也没有打补丁。
- 尽量减少每个服务所暴露的内容。网络入站默认拒绝，并将 API 暴露面限制在实际所需的范围内。

> ⌁ - Maintain a current inventory of every internet-facing host, service, and API endpoint in your systems. Attackers can run automated reconnaissance; your inventory should be at least as accurate. Include these systems in your pentests and red-teaming.
> - Decommission unused systems. Legacy services with no clear owner are typically also unpatched.
> - Minimize what each service exposes. Default-deny network ingress and limit API surface area to what is actually required.

实用提示：全网扫描索引是可公开检索的；用它查询你自己的 IP 段和域名，就能看到攻击者侦察时所看到的内容。对于云资产，原生盘点工具（AWS Config、Azure Resource Graph、GCP Asset Inventory）已经存在；工作在于去查询它们。

> ⌁ Practical tip: Internet-wide scan indexes are publicly searchable; querying one for your own IP ranges and domains shows you what an attacker’s reconnaissance sees. For cloud assets, native inventory tools (AWS Config, Azure Resource Graph, GCP Asset Inventory) already exist; the work is in querying them.

AI 在这里也能直接提供帮助：

> ⌁ AI can help directly here, too:

- 清理陈旧的代码和系统。识别未使用的代码很繁琐——但如上所述，AI 模型擅长繁琐的任务。一个对代码库和流量日志具有读取权限的模型，可以列出没有调用方、也没有收到流量的端点；在此基础上，它还能说明移除每一个端点会影响什么。
- 自主的外部红队演练。让一个 AI 攻击型代理从外部、在没有凭据和源代码访问权限的情况下对准你自己的边界。然后，让它做攻击者会做的事：摸清哪些是可触及的、对其进行指纹识别，并尝试把所发现的内容串联成一个立足点。这类自动化红队演练能发现源代码扫描看不到的东西：被遗忘的主机、暴露的管理接口、默认凭据和配置错误的存储。让它以与你刷新清单相同的节奏运行。

> ⌁ - Pruning stale code and systems. Identifying unused code is tedious—but as noted above, AI models are good at tedious tasks. A model with read access to a codebase and traffic logs can list endpoints that have no callers and have not received traffic; from there, it can explain what removing each one would affect.
> - Autonomous external red-teaming. Point an AI offensive agent at your own perimeter from the outside, with no credentials and no source access. Then, let it do what an attacker would: work out what is reachable, fingerprint it, and attempt to chain what it finds into a foothold. This kind of automated red-teaming can catch things source scanning doesn’t see: forgotten hosts, exposed management interfaces, default credentials, and misconfigured storage. Run it on the same cadence as your inventory refresh.

#### 7. 缩短你的事件响应时间

> 7. Shorten your incident response time

漏洞利用可能在补丁发布后数小时内出现。耗时数天的响应流程太慢了。以下是一些缩短事件响应时间的思路：

> ⌁ Exploits can appear within hours of a patch. Response processes that take days are too slow. Here are some ideas for how to reduce your incident response time:

- 在告警队列的最前端放一个模型。每一条传入的告警在被人看到之前，都应先经过自动化的初步调查。这类"分诊代理"对你的安全信息与事件管理（SIEM）平台具有只读访问权限，并配有一套范围明确的查询工具，能把你的注意力引向最需要人类判断的告警。
- 优先考虑驻留时间（dwell time）和覆盖面的检测能力，胜过其他一切。这是 AI 自动化最有能力改善的两项指标；当漏洞利用窗口缩短时，二者都最为关键。
- 将事件相关的记录工作自动化。在事件处理过程中，模型应负责记笔记、留存证据、并行推进多条调查线索，并起草事后复盘与根因分析。另一方面，人类应负责做出遏制决策、披露决策和客户沟通决策。事件中人类的决策速度，绝不应被那些更适合交给 AI 的环节（如证据收集或撰写报告）所拖累。
- 让模型驱动检测的飞轮。摄取威胁情报、生成候选检测规则、搜寻匹配项、调优触发条件，如今都已在前沿模型的能力范围之内，它们可以端到端地运行整个流程。
- 针对五起同时发生的事件进行桌面推演。标准演练假设某个周一爆出一个带有可用利用代码（exploit）的严重 CVE 漏洞。鉴于我们看到的 AI 能力提升，这种假设可能并不明智。要真正对你的响应进行压力测试，你应当演练同一周内爆发五起事件的版本。
- 将检测覆盖范围对照 MITRE ATT&CK 进行映射。ATT&CK 提供了一套标准的攻击者技术词汇，大多数检测工具已经在使用。明确知道哪些技术你能检测（以及哪些不能），比泛泛的“提升检测能力”目标更有用。你应当优先覆盖横向移动（lateral movement）和凭据访问（credential access）。
- 提前建立应急变更流程。生产环境补丁需要两周的变更审批周期，这本身就是一种安全风险。同样的道理也适用于应急遏制措施（如下线某项服务、轮换凭据或封锁某条网络路径）。你应当提前决定谁有权批准这些操作，以及能多快执行。

> ⌁ - Put a model at the front of your alert queue. Every inbound alert should get an automated first-pass investigation before a human sees it. This kind of “triage agent” with read-only access to your Security Information and Event Management (SIEM) platform and a well-scoped set of query tools can direct your attention to the alerts that need human judgement most.
> - Put instrument dwell time and coverage before anything else. These are the two metrics that AI automation has the greatest ability to move; both matter most when exploit windows shorten.
> - Automate the bookkeeping around incidents. During an active incident, models should be taking notes, capturing artifacts, pursuing parallel investigation tracks, and drafting the postmortem and root-cause analysis. On the other hand, humans should be making the containment calls, disclosure calls, and customer-comms calls. Human decision speed during an incident should never be rate-limited on aspects that would be better handed to an AI, like evidence collection or write-ups.
> - Let models drive the detection flywheel. Ingesting threat intelligence , generating candidate detections, hunting for matches, and tuning what fires are all now within reach of frontier models, who can run the process end-to-end.
> - Run a tabletop for five simultaneous incidents. The standard exercise assumes one critical CVE with a working exploit hits on a Monday. Given the improved AI capabilities we’re seeing, this might be unwise. To truly stress-test your responses, you should run the version where five incidents hit in the same week.
> - Map detection coverage against MITRE ATT&CK . ATT&CK provides a standard vocabulary of attacker techniques that most detection tools already use. Knowing which techniques you can detect (and which you can’t), is more useful than a general goal to “improve detection.” You should prioritize coverage for lateral movement and credential access.
> - Establish emergency change procedures in advance. A two-week change-approval cycle for production patches is itself a security risk. The same applies to emergency containment actions (like taking a service offline, rotating a credential, or blocking a network path). You should decide in advance who can authorize these and how fast.

实用建议：挑选一条噪声大、已知误报率高的规则。将一个前沿模型（frontier model）以只读权限接入其告警流，使其访问底层数据，并让它为每一次触发生成结构化的处置结论。在两周内将其与人工审查者的判断进行一致性测量。如果一致率可以接受，就扩展到下一条规则。一次性尝试自动化整个告警队列并不值得。另外，Atomic Red Team 是一个开源库，包含一系列对照 ATT&CK 技术的小型、安全的测试；运行其中几个并检查你现有的日志实际检测到了哪些，是一个一下午就能完成的练习，能产出一份具体的覆盖图谱。

> ⌁ Practical tip: Pick one noisy rule with a known-high false positive rate. Wire a frontier model into its alert stream with read-only access to the underlying data, and have it produce a structured disposition for every firing. Measure agreement against a human reviewer for two weeks. If the agreement rate is tolerable, expand to the next rule. It’s not worth trying to automate the whole queue at once. Separately, Atomic Red Team is an open-source library of small, safe tests mapped to ATT&CK techniques; running a handful and checking which ones your existing logging actually detected is a one-afternoon exercise that produces a concrete coverage map.

以下是 AI 可以协助缩短响应时间的几种方式：

> ⌁ Here are some ways AI can assist with response times:

- 以 100% 覆盖率进行初步分诊（triage）。一个范围明确的分诊智能体可以调查每一条告警（而人工可能只查看高于某个严重性阈值的告警），并产出结构化的处置结论，供人工接受、拒绝或升级。让这一切奏效的机制在于：为模型提供一套最小化的工具集（查询、思考、报告），让它自行选择调查策略，并以运营指标来衡量其输出。
- 事件记录员与并行调查者。在事件进行过程中，模型可以同步记录笔记，在收集证据时为其打上时间戳，推进响应人员尚未着手的独立调查线索，并在事件结束后根据记录草拟事后复盘报告。这是前沿模型在安全工作中最不起眼的应用——但很可能也是影响最大的一个。
- 针对你自己环境的主动狩猎（hunting）。能在源代码中发现漏洞的那类智能体，同样可以在你的遥测数据中狩猎错误配置和入侵指标（indicators of compromise）。你可以让它以与外部攻击面扫描相同的节奏运行。

> ⌁ - First-pass triage at 100% coverage. A well-scoped triage agent can investigate every alert (where humans might look only at those above a given severity threshold), and produce a structured disposition a human can accept, reject, or escalate. The mechanism that makes this work is giving your model a minimal tool set (query, think, report), letting it choose its own investigation strategy, and measuring the output against operational metrics.
> - Incident scribe and parallel investigator. During an active incident, a model can take contemporaneous notes, timestamp artifacts as they are collected, pursue independent investigation tracks the responder has not gotten to yet, and draft the postmortem from the transcript once the incident closes. This is the least glamorous application of frontier models to security work—but it’s probably the highest-impact one.
> - Proactive hunting against your own environment. The same kind of agent that can find vulnerabilities in source code can hunt for misconfigurations and indicators of compromise across your telemetry. You can run it on the same cadence as your external attack-surface scan.

### 向他人提交漏洞报告的建议

> Advice for submitting vulnerability reports to others

如果你在扫描代码——你自己的依赖、开源项目或供应商产品——并把发现上报给上游，那么这些报告的质量决定了是否有人会采取行动。开源维护者已经在接收大量低质量的自动化报告，许多人已开始忽略任何看起来像 AI 生成的内容。在不增加有效信号的情况下增加这类数量，会让包括你在内的所有人处境更糟。

> ⌁ If you are scanning code—your own dependencies, open-source projects, or vendor products—and reporting findings upstream, the quality of those reports determines whether anyone acts on them. Open-source maintainers are already receiving large volumes of low-quality automated reports, and many have started ignoring anything that looks AI-generated. Adding to that volume without adding signal makes the problem worse for everyone, including you.

报告只应在有人工核实并愿意署名后才发送。具体而言：

> ⌁ A report should be sent only when a human has verified it and is willing to put their name on it. Concretely:

- 用平实的语言陈述漏洞及其影响。维护者应该能从第一段就理解问题出在哪里、为什么重要，而不必运行任何东西。
- 梳理代码路径。展示输入从哪里进入、在哪里被错误处理、后果在哪里发生。这部分正是区分真实发现与模式匹配的关键。
- 提供可运行的复现。维护者能运行的概念验证（proof-of-concept），或一个会失败的测试用例，比任何解释都更可信。
- 附上一份你若是维护者也会接受的补丁建议。补丁表明报告者足够了解代码库，能以符合项目惯例的方式修复问题。
- 在开头就声明 AI 的参与。如果是模型发现了漏洞或起草了报告，请在第一行就说明。维护者反正会发现；隐瞒比披露损失更多的信誉。
- 尊重维护者的判断。如果他们拒绝了报告，你应该坦然接受。易于合作所带来的善意，比在一个漏洞上赢得争论更有价值。

> ⌁ - State the bug and its impact in plain language. A maintainer should be able to understand what is wrong and why it matters from the first paragraph, without running anything.
> - Walk through the code path. Show where the input enters, where it is mishandled, and where the consequence occurs. This is the part that distinguishes a real finding from a pattern match.
> - Provide a working reproduction. A proof-of-concept the maintainer can run, or a test case that fails, is more credible than any amount of explanation.
> - Include a proposed patch you would accept if you were the maintainer. A patch demonstrates that the reporter understands the codebase well enough to fix the problem in a way that fits the project’s conventions.
> - Disclose AI involvement upfront. If a model found the bug or drafted the report, say so in the first line. Maintainers will find out anyway; concealing it costs more credibility than disclosing it.
> - Defer to the maintainer's judgment. If they decline the report, you should make peace with that. The goodwill from being easy to work with is worth more than winning an argument over one bug.

实用提示：在发送漏洞报告前，一个有用的自检方法是关掉编辑器，凭记忆解释这个漏洞。如果你不参照模型输出就无法描述问题出在哪里，那说明你对它的理解还不足以上报。

> ⌁ Practical tip: A useful self-check before sending a vulnerability report is to close the editor and explain the bug from memory. If you cannot describe what goes wrong without referring back to the model output, you do not understand it well enough to report it.

### 如果你没有安全团队

> If you don’t have a security team

上述大部分建议都假设你的组织有专门的安全职能。如果你是小型组织、独立开发者或开源维护者，同样的风险依然存在，但应对措施更简单：

> ⌁ Most of the above advice assumes that your organization has a dedicated security function. If you are a small organization, a solo developer, or an open-source maintainer, the same risks apply but the actions are simpler:

- 为你的操作系统、浏览器以及每一个提供该功能的应用开启自动更新。这是唯一最有效的措施，而且无需持续投入精力。
- 优先使用托管服务而非自行部署。让拥有安全团队的服务商来运行数据库、身份认证和电子邮件，会把打补丁的负担转移给他们。这类托管服务的成本几乎总是低于一次事故的代价。
- 在每一个支持的账户上使用通行密钥（passkeys）或硬件安全密钥。短信验证码可能被拦截，密码会被重复使用；而硬件密钥无法被钓鱼骗取。
- 启用代码托管平台上的免费安全工具。GitHub 的 Dependabot、密钥扫描（secret scanning）和 CodeQL 对公开仓库免费，并能捕获相当一部分企业级工具能捕获的问题。启用它们只需几分钟。

> ⌁ - Turn on automatic updates for your operating system, browser, and every application that offers it. This is the single most effective action available and requires no ongoing effort.
> - Prefer managed services over self-hosting. Letting a provider with a security team run the database, authentication, and email shifts the patching burden to them. The cost of a managed service like this is almost always lower than the cost of one incident.
> - Use passkeys or hardware security keys on every account that supports them. SMS codes can be intercepted and passwords get reused; a hardware key cannot be phished.
> - Enable the free security tooling on your code host. GitHub's Dependabot, secret scanning, and CodeQL are free for public repositories and catch a meaningful share of what enterprise tools catch. Enabling them takes minutes.

如果你维护一个开源项目，请发布一份 SECURITY.md，说明该联系谁以及联系后能得到怎样的回应。AI 辅助扫描意味着你会收到比以往更多的漏洞报告。其中一些有价值，一些则是自动化产生的噪音。清晰的接收流程能帮你区分两者，也向善意的报告者表明他们的努力不会白费。

> ⌁ If you maintain an open-source project, publish a SECURITY.md stating who to contact and what to expect when they’re contacted. AI-assisted scanning means you will receive more vulnerability reports than before. Some will be valuable; some will be automated noise. A clear intake process helps you tell them apart, and signals to good-faith reporters that their effort will not be wasted.

#### 致谢

> Acknowledgements

本文由 Anthropic 安全工程与研究团队成员撰写，包括 Donny Greenberg、Jason Clinton、Michael Moore、Abel Ribbink 和 Jackie Bow，并得到 Jannet Park、Gabby Curtis 和 Stuart Ritchie 的贡献。

> ⌁ This article was written by members of Anthropic’s Security Engineering and Research teams, including Donny Greenberg, Jason Clinton, Michael Moore, Abel Ribbink, and Jackie Bow, with contributions from Jannet Park, Gabby Curtis, and Stuart Ritchie.

## 术语对照

| English | 中文 |
|---|---|
| vulnerability | 漏洞 |
| exploit | 利用/利用代码 |
| patch | 补丁 |
| frontier model | 前沿模型 |
| Known Exploited Vulnerabilities (KEV) | 已知被利用漏洞 |
| Exploit Prediction Scoring System (EPSS) | 利用预测评分系统 |
| Common Vulnerability and Exposure (CVE) | 通用漏洞披露 |
| continuous integration | 持续集成 |
| continuous delivery | 持续交付 |
| static analysis | 静态分析 |
| Static application security testing (SAST) | 静态应用安全测试 |
| build pipeline | 构建流水线 |
| Secure by Design | 安全设计 |
| memory-safe language | 内存安全语言 |
| zero trust architecture | 零信任架构 |
| humans in the loop | 人在回路中 |
| phishing-resistant 2FA | 抗钓鱼双因素认证 |
| network segmentation | 网络分段 |
| short-lived token | 短期令牌 |
| attack surface | 攻击面 |
| red-teaming | 红队演练 |
| incident response | 事件响应 |
| dwell time | 驻留时间 |
| triage | 分流 |
| SIEM | 安全信息与事件管理 |
| threat intelligence | 威胁情报 |
| lateral movement | 横向移动 |
| credential access | 凭证访问 |
| proof-of-concept | 概念验证 |
| managed service | 托管服务 |
| passkey | 通行密钥 |
