---
source: claude-blog
source_url: https://claude.com/blog/ciso-guide-to-agentic-ai
published_at: 2026-07-17
category: Enterprise AI
title_en: Zero risk isn't the job: a CISO's guide to agentic AI
title_zh: 零风险不是目标：CISO 的智能体 AI 治理指南
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 4
source_image_count: 0
---

# 零风险不是目标：CISO 的智能体 AI 治理指南

> Zero risk isn't the job: a CISO's guide to agentic AI

> 来源：Claude Blog，2026-07-17
> 原文链接：https://claude.com/blog/ciso-guide-to-agentic-ai
> 分类：Enterprise AI

## 核心要点

- CISO 在智能体 AI 时代的职责不是实现零风险，而是让智能体风险变得可辨识、有边界，从而在可管理的前提下主动接受风险。
- 对请求一味说'不'会催生毫无遥测、无法关停的影子采用；不加控制地说'是'则会引发事故。
- 内部风险的主要威胁向量是通过监管不足的个人智能体连接分散系统而导致的数据泄露，以及提示注入攻击。
- 评估智能体风险的四个问题：摄入哪些不可信内容、能执行哪些动作及以谁的身份、失准时的影响半径、具备哪些可观测性。
- 遵循最小代理权原则：只授予刚好能完成任务的最窄能力，并采用管理员节奏的渐进式推广。
- 失准的智能体等同于内部威胁，而智能体的执行速度使得以天计的响应时间远远不够。
- 所有部署都处于身份访问模型光谱的两端之间，一端是单一用途、最小权限的系统服务账户。

## 正文

Anthropic 副首席信息安全官 Jason Clinton 分享其团队采用智能体 AI 的经验教训，以及他们为安全地构建和部署智能体而开发的风险评估框架。

> Anthropic's Deputy CISO, Jason Clinton, shares his team's lessons learned adopting agentic AI, and the risk assessment framework they've developed for building and deploying agents securely.

安全负责人正被要求批准几个月前根本还不存在的智能体 AI（agentic AI）用例。董事会想知道这些是否受到治理，而在你的组织某处，已经有员工在没有告诉你的情况下把某个智能体连接到了某样东西上。

> Security leaders are being asked to approve agentic AI use cases that did not even exist a few months ago. Boards want to know whether any of it is governed, and somewhere in your organization, an employee has already connected an agent to something without telling you.

对这些请求说“不”，会催生影子采用（shadow adoption），它没有任何遥测数据，通常也没有关闭开关。不加控制就说“可以”，则会引发事故，而你公司里第一起严重的智能体事故会让你的 AI 计划倒退。

> Saying “no” to these requests produces shadow adoption, which has zero telemetry and generally no off switch. Saying “yes” without controls produces incidents, and the first serious agent incident at your company will set your AI program back.

在智能体 AI 时代，CISO 的职责不是实现零风险。相反，我们的工作是让智能体风险变得可读、可界定。这样，我们就能有意识地接受那些我们能够管理的风险，让业务按我们的条件推进，而不是绕过我们推进。

> A CISO’s responsibility in the age of agentic AI is not to achieve zero risk. Instead, our jobs are to make agentic risk legible and bounded. This way, we can deliberately accept what we can manage, so the business moves on our terms instead of around us.

在本文中，我分享我们评估智能体安全风险的框架，解释“有界（bounded）”在实践中意味着什么，并预告我们的工作将走向何方。

> In this article, I share our framework for evaluating agents for security risk, explain what “bounded” means in practice, and preview where our work is headed.

### Mythos 时代之后：AI 带来的外部风险与内部风险

> External risk from AI versus internal risk in the post-Mythos era

在[此前的一篇博客文章](https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense)中，我和同事们分享了 AI 如何压缩从漏洞存在到可用利用程序出现之间的时间，并强调了组织可以如何缓解这些风险。在未来几个月里，我们预计大量长期潜伏在代码中、有时已存在数年而未被发现的缺陷，将被 AI 模型找到，并串联成可用的利用程序。像 [Claude Mythos Preview](https://red.anthropic.com/2026/mythos-preview/) 和 [Claude Mythos 5](https://www.anthropic.com/news/claude-fable-5-mythos-5) 这样的前沿模型，已经发现了多年人工审查都未能察觉的[严重漏洞](https://www.anthropic.com/glasswing)，涉及 OpenBSD、Linux 内核以及 [Mozilla Firefox](https://blog.mozilla.org/en/privacy-security/ai-security-zero-day-vulnerabilities/)。

> In [an earlier blog post](https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense), my colleagues and I shared how AI is collapsing the time between a vulnerability existing and a working exploit, highlighting how organizations can mitigate these risks. In the coming months, we expect that vast numbers of bugs that have sat unnoticed in code, sometimes for years, will be found by AI models and chained into working exploits. Frontier models like [Claude Mythos Preview](https://red.anthropic.com/2026/mythos-preview/) and [Claude Mythos 5](https://www.anthropic.com/news/claude-fable-5-mythos-5) are already finding [serious vulnerabilities](https://www.anthropic.com/glasswing) that years of human review missed, including in OpenBSD, the Linux Kernel and [Mozilla Firefox](https://blog.mozilla.org/en/privacy-security/ai-security-zero-day-vulnerabilities/).

对任何 GRC 项目而言，这些都是严重的风险。缓解和弥合漏洞缺口，以及为即将到来的利用浪潮做好准备，应当成为首要任务。针对这一主题，我们已另行准备了一份文档：[为 AI 加速的攻击做好安全项目准备](https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense)。本指南将聚焦于内部风险。

> These are serious risks to any GRC program. Mitigating and closing vulnerability gaps, as well as for preparing for the coming wave of exploits, should be a top priority. For this topic, we have prepared a separate doc: [Preparing your security program for AI-accelerated offense](https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense). We’ll focus on internal risks for this guide.

### 治理内部风险

> Governing internal risks

对许多组织而言，智能体系统最可能的威胁途径是数据泄露——通过个人智能体将各不相同的系统连接起来，却缺乏足够的监督。另一个担忧是[提示词注入](https://www.anthropic.com/research/prompt-injection-defenses)：攻击者将指令隐藏在智能体读取的内容中，智能体便听从攻击者而非用户。任何接触不可信内容的智能体都可能因此暴露，具体取决于模型防御的稳健程度。随着模型能力不断增强，它们抵御注入的能力也在显著提升。虽然[攻击成功率持续下降](http://anthropic.com/research/prompt-injection-defenses)，但并未归零。除这两个例子外还有许多担忧，层出不穷的新型担忧类别可能让人感到不堪重负。

> For many organizations, the most likely threat vector for agentic systems is a data leak enabled by connecting disparate systems through personal agents with insufficient oversight. Another concern is [prompt injection](https://www.anthropic.com/research/prompt-injection-defenses): an attacker hides instructions inside content the agent reads, and the agent follows the attacker instead of the user. Any agent that touches untrusted content could then be exposed, depending on how robust the defenses of the model are. As models grow increasingly capable, they’re getting meaningfully better at resisting injection. While[attack success rates keep falling](http://anthropic.com/research/prompt-injection-defenses), they’re not zero. There are many concerns outside of these two examples, and the deluge of new classes of concern can seem overwhelming.

#### 应问的四个问题

> Four questions to ask

当一个智能体用例进入我们的评审流程时，我们通过提出四个问题来评估其风险：

> When an agentic use case reaches our review process, we assess its risk by asking four questions:

- 它摄取哪些不可信内容？不可信指攻击者有可能撰写或篡改的任何内容，包括外部邮件、开放网络、第三方文档或公共代码库。如果答案是"没有"，那么智能体特有的风险几乎为零，你应当快速推进。
- 它能执行哪些操作，又代表谁执行？只读与读写是两种不同的担忧。工具调用、代码执行和网络出站流量都会扩大风险面。每个操作都在某个身份下发生，而你需要知道是谁的身份。
- 如果它出现失准，波及范围有多大？范围×严重程度是快速的估算方式：恶意行为者或失准事件访问的是一个文件还是整个组织？后果会是一次异常、一次困扰、一次数据暴露，还是一次真正的事故？
- 我拥有哪些可观测性？你能区分智能体操作与用户操作吗？这些操作会进入你的 SIEM 吗？

> • What untrusted content does it ingest? Untrusted means anything an attacker could plausibly write or alter, including outside email, the open web, third-party documents, or public repositories. If the answer is "nothing," the agent-specific risk is near zero and you should move quickly.
> • What actions can it take, and on whose behalf? Read-only is a different concern from read/write. Tool calls, code execution, and network egress each widen the aperture. Every action happens under some identity, and you need to know whose.
> • What is the blast radius if it is misaligned? Scope X severity is the quick calculation: did the bad actor or alignment incident have access to one file or the whole org? Would it be an anomaly, an annoyance, a data exposure, or a true incident?
> • What observability do I have? Can you tell agent actions from user actions? Does it land in your SIEM?

这四个问题的答案让你看清自己的风险，而最小代理权（least agency）原则则告诉你该如何应对：授予能够完成任务的最窄能力（详见我们的[《面向 AI 智能体的零信任》](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a1611a04085d7cd3dadc924_Claude-eBook-Zero-Trust-for-AI-Agents-05182026.pdf)白皮书）。Anthropic 的默认姿态是管理员节奏式推广：先向一小群人开放，观察遥测数据，然后再扩大访问范围。将这些问题应用于思考高风险智能体系统的新范式。

> The four answers to these questions give you a picture of your risk, but the principle of least agency tells you what to do with it: grant the narrowest capability that still completes the task (see our [Zero Trust for AI Agents](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a1611a04085d7cd3dadc924_Claude-eBook-Zero-Trust-for-AI-Agents-05182026.pdf) white paper to learn more). Our default posture at Anthropic is admin-paced rollout: enable a small group, watch the telemetry, and then expand access. Apply these questions to a new paradigm for thinking about risky agentic systems.

一个偏离你意图、与之失准的智能体，与一次内部人员攻击难以区分。安全行业在 2019 至 2022 年间将[内部风险确立为一门独立于边界防御的学科](https://www.cisa.gov/resources-tools/resources/insider-threat-mitigation-guide)——认识到系统中最危险的攻击途径往往是那些侵入了本就拥有合法访问权限之人的攻击。

> An agent that drifts out of alignment with your intent is indistinguishable from an insider attack. The security industry spent 2019-2022 formalizing [insider risk as a discipline](https://www.cisa.gov/resources-tools/resources/insider-threat-mitigation-guide) distinct from perimeter defense—recognizing that the most dangerous external attack vectoractor in a system is often one that compromises someone who already has legitimate access.

运营上的差别在于响应时间：[Ponemon 研究所的《2026 年内部风险成本》报告](https://www.ponemon.org/news-updates/blog/security/lessons-learned-from-the-2026-global-cost-of-insider-risks.html)发现，组织平均需要 67 天才能遏制一次内部人员事件——即便在专门的内部风险项目上投入多年之后依然如此。而以智能体的执行速度来看，以天为单位的响应实在太慢了。

> The operational difference is response time:[Ponemon Institute's 2026 Cost of Insider Risks report](https://www.ponemon.org/news-updates/blog/security/lessons-learned-from-the-2026-global-cost-of-insider-risks.html) found organizations took an average of 67 days to contain an insider incident—even after years of investment in dedicated insider risk programs. At agent execution speeds, responses measured in days are too long.

### 智能体身份光谱

> The agentic identity spectrum

我们部署的一切都位于[身份访问模型](https://claude.com/blog/agent-identity-access-model)光谱的两端之一。

> Everything we deploy sits at one of two ends of an [identity access model](https://claude.com/blog/agent-identity-access-model) spectrum.

一端是系统服务账户：一个自包含、单一用途、最小权限的身份，只为业务做一件事，不附带任何人类身份。事件响应智能体（见下文）、工单分流智能体或自主代码审查器都是这类例子。另一个例子是 [Claude Tag](https://www.anthropic.com/news/introducing-claude-tag)，我们新推出的共享工作区智能体，让人类团队可以在 Slack 等共享工作区中通过 @ 提及 Claude 来与智能体协作。

> At one end is the system service account: a self-contained, single-purpose, least-privilege identity that does exactly one thing for the business, with no human identity attached. The incident-response agent (see below), a ticket triage agent, or an autonomous code reviewer are examples of these. Another example is [Claude Tag](https://www.anthropic.com/news/introducing-claude-tag), our new shared workspace agent that lets human teams collaborate with agents in shared workspaces like Slack by tagging in Claude.

另一端是人类凭证。当员工在自己的笔记本电脑上使用聊天界面或像 Claude Cowork 这样的个人智能体框架时，键盘前的那个人要对结果负责，就像他们要对用自己凭证做的任何其他事情负责一样。

> At the other end is the human credential. When an employee uses a chat interface or a personal agent harness like Claude Cowork on their laptop, the person at the keyboard is accountable for the outcome, the same way they are accountable for anything else done with their credentials.

光谱的中间地带——智能体携带某人被委派的身份进入那个人并未监视的系统——正是问责变得含糊的地方。含糊的问责正是事件变得无法解释的原因。

> The middle of the spectrum, where an agent carries a person's delegated identity into systems that person is not watching, is where accountability gets ambiguous. Ambiguous accountability is how incidents become unexplainable.

一个偏离你意图、失去对齐的智能体与内部攻击（insider attack）无法区分。安全行业在 2019 至 2022 年间将[内部风险正式确立为一门独立于边界防御的学科](https://www.cisa.gov/resources-tools/resources/insider-threat-mitigation-guide)——认识到系统中最危险的外部攻击向量往往是那种攻陷了已经拥有合法访问权限之人的向量。

> An agent that drifts out of alignment with your intent is indistinguishable from an insider attack. The security industry spent 2019-2022 formalizing [insider risk as a discipline](https://www.cisa.gov/resources-tools/resources/insider-threat-mitigation-guide) distinct from perimeter defense—recognizing that the most dangerous external attack vector in a system is often one that compromises someone who already has legitimate access.

[Ponemon 研究所 2026 年内部风险成本报告](https://www.ponemon.org/news-updates/blog/security/lessons-learned-from-the-2026-global-cost-of-insider-risks.html)发现，各组织平均需要 67 天才能遏制一起内部事件——即便在多年投入专门的内部风险项目之后也是如此。而在智能体的执行速度下，67 天完全是错误的度量单位。

> [Ponemon Institute's 2026 Cost of Insider Risks report](https://www.ponemon.org/news-updates/blog/security/lessons-learned-from-the-2026-global-cost-of-insider-risks.html) found organizations took an average of 67 days to contain an insider incident—even after years of investment in dedicated insider risk programs. At agent execution speeds, 67 days is the wrong unit of measurement entirely.

### 案例研究：事件响应智能体

> Case study: an incident response agent

一年多以前，我们让 Claude 参与我们的事件响应流程。任何为生产应用值过班的人都熟悉这个问题：凌晨两点你因一起安全事件被呼叫，你拉起一个事件响应频道，召集合适的人，然后开始处理。这个流程繁琐、文档量大、节奏很快。但只要拥有关于生产环境代码库的正确上下文，其中大部分工作都可以自动化。

> More than a year ago, we pointed Claude at our incident response process. Anyone who has been on-call for a production application knows the problem: you’re paged at 2 a.m. about a security incident, you spin up an incident response channel, you pull in the right people, and get to work. This process is tedious, documentation-heavy, and fast-moving. But, with the right context about your production environment codebase, the majority of it can be automated.

于是我们构建了一个智能体来做这件事。我们给这个智能体授予了三个工具的访问权限：对生产日志的只读访问（日志中不含个人身份信息 PII）；对 Slack 的访问，用于开启事件频道并推进流程；以及在事件解决后起草一份用于事后复盘（postmortem）的 Google 文档的能力。

> So we built an agent to do it. We gave the agent access to three tools: read-only access to our production logs, which contain no PII; access to Slack, to open the incident channel and run the process; and the ability to draft a Google Doc for the postmortem after the incident is resolved.

我们用那四个问题对它进行了审视：

> We ran it through the four questions:

- 不可信内容：无。输入是我们自己的日志和我们自己的内部 Slack，两者都在信任边界之内，因此一次注入攻击需要内部人员或被攻陷的账户，而非匿名攻击者。
- 动作：读操作遍布各处，写操作则仅限于新建文档和 Slack 消息。没有编辑或删除，没有权限变更，没有外部端点。
- 影响范围（blast radius）：我们能设想的最坏结果，是一些轻度敏感的日志行被发布到一个本已被锁定的事件频道中。
- 可观测性：每一个动作都会进入我们的 SIEM，因此任何意外都会在几分钟内浮现，而不是几周后。

> • Untrusted content: none. The inputs were our own logs and our own internal Slack, both inside the trust boundary, so an injection would require an insider or a compromised account rather than an anonymous attacker.
> • Actions: reads everywhere, writes limited to new documents and Slack messages. No edits or deletes, no permission changes, no external endpoints.
> • Blast radius: the worst outcome we could construct was some mildly sensitive log lines posted into an incident channel that was already locked down.
> • Observability: every action landed in our SIEM, so anything unexpected would surface in minutes, not weeks.

虽然这个智能体并非毫无风险，但它运行在一个有界的写入面上，并有完整的审计覆盖，这是一种我们能够接受的风险画像。

> While the agent wasn’t risk-free, it operated on a bounded write surface with full audit coverage, which was a risk profile we were comfortable with.

不过，这个故事有一个有趣的补记：随着每次模型发布，这个智能体变得更聪明了。2025 年 11 月，我们把这个智能体从 Claude Opus 4 迁移到 Claude Opus 4.5，其他什么都没改——没有新工具、没有新权限、没有新提示词。此后立刻，第一次，仅凭智能提升就足以让这个智能体在事件处理途中注意到：它已经在一条堆栈跟踪（stack trace）中找到了根因，而在尚未到场的人类缺席的情况下，它可以尝试自行修复生产环境——办法是联系另一个拥有相应代码访问权限、能够生成代码变更的智能体。

> However, there’s an interesting addendum to this story: with each model release, the agent got smarter. In November 2025, we moved this agent from Claude Opus 4 to Claude Opus 4.5 and changed nothing else—no new tools, permissions, or prompts. Immediately after this, for the first time, the intelligence uplift alone was enough for the agent to notice, mid-incident, that it had already found the root cause in a stack trace and that, in the absence of the human who hadn't arrived yet, it could try to fix production on its own by reaching out to another agent that had the appropriate code access to produce the code change.

事后，我们回顾了日志：我们在思考轨迹（thinking traces）中看到它这样推演：我已经完成了被要求做的事。人类不在。如果我把问题修好呢？在 Anthropic 内部，我们有一个类似 Claude Tag 技术的内部变体，它可以编写代码变更并上传供人类审查。它自行通过 Slack 联系了这个类 Claude Tag 的实例，请它编写修复方案。修复方案进入了一个拉取请求（pull request），由人类审查后再推送到生产环境。

> Post hoc, we reviewed logs: we watched it work through this in the thinking traces: I have done what I was asked to do. The human is not here. What if I fixed the problem? Inside of Anthropic we have an internal variant of Claude Tag-like technology which can write code changes and upload them for human review. On its own, it reached out over Slack to this Claude Tag-like instance and asked it to write the fix. The fix went to a pull request that a human reviewed before pushing it to production.

这种涌现出的智能体间通信所带来的扩大化影响范围，本身仍受我们的原则约束：可能发生的最坏情况，是上传一份包含某条生产日志行的代码变更。如今这种智能体间通信已成为我们事件响应中根因定位与修复实践的常规组成部分；全程都有人类在环（human-on-the-loop）监控。

> The expanded blast radius that came from this emergent agent-to-agent communication was itself governed by our principles: the worst that could happen would be that a code change would be uploaded which contained a production log line. This agent-to-agent communication is now a regular part of our incidence response root cause and remediation practices; all with human-on-the-loop monitoring.

这一涌现行为教会了我们两件事。第一：新能力可能在一次智能体部署的边界之内出现。重要的是围绕访问权限和动作来设限，而不是围绕你今天认为的模型能力上限来设限。第二：即便面对像这样具有随机性（stochastic）的智能体，控制措施依然有效。这个新行为之所以是人类在环的，是因为它发生在一个 Slack 频道里，而唯一类似写入的动作仍然需要人类审查。

> This emergent behavior taught us two things. First: new capabilities can show up within the boundaries of an agent deployment. It’s important to limit access and actions, not around what you believed today's model limits are. Second: controls are effective even with stochastic agents like this. The new behavior was human-on-the-loop because it happened in a Slack channel, and the only write-like action still required a human review.

如今，在事件响应之外，在人们工作的聊天频道内、由人类在环的智能体间通信，已成为常态。

> Today, outside of incidence response, agent-to-agent communication within chat channels, with human on-the-loop where people work, is the norm.

### 案例研究：Claude Cowork

> Case study: Claude Cowork

事件响应智能体是一个只做一件事的服务账户，运行在受限的服务账户中。[Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork) 处于光谱的人类操作者一端：一名坐在键盘前的员工对结果负责，智能体随后代表其行事，在其授权的系统中——并且越来越多地——运行在云端。

> The incident response agent is a service account doing one job, in a bounded service account. [Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork) is at the human operator end of the spectrum: an employee at a keyboard is accountable for the outcome, and the agent then acts on their behalf, in systems they authorized—increasingly—running in the cloud.

Claude Cowork 的威胁模型很直接，因为该智能体本质上就是运行在本地或托管界面中的 Claude Code。桌面应用仍是本地文件访问、浏览器使用和计算机使用所必需的；这些能力直接触及本地机器，因而需要该应用来实现。因此，完整的系统面分为两部分：一个（可能是远程的）执行环境，负责编排、MCP 调用和出站网络请求；以及一个用于文件和屏幕访问的本地桥接。

> Claude Cowork's threat model is straightforward, because the agent is essentially Claude Code running either locally or inside a hosted interface. The desktop app remains required for local file access, browser use, and computer use; those capabilities reach the local machine directly and need the app to do so. The full system surface is therefore two-part: a (possibly remote) execution environment handling orchestration, MCP calls, and outbound network requests, and a local bridge for file and screen access.

上述四个问题对每个 Claude Cowork 使用场景都会给出不同的答案。但只要部署了合适的控制措施，你就能对它们加以约束，从而更好地控制任何可能的风险。

> The four questions outlined above produce different answers for every Claude Cowork use case. But with the right controls in place, you can bound them to better control any possible risk.

下面每项控制都表述两次，先作为任何智能体环境都应能满足的要求，再作为它在 Claude Cowork 中是如何实施的：

> Each control below is stated twice, first as the requirement any agent environment should be able to meet and then as how it is enforced in Claude Cowork:

身份来自你的身份提供方（IdP）：智能体的身份必须在你已经用来签发和撤销其他一切的地方签发和撤销，并以你现有的用户组作为策略单元。Claude Cowork 使用 SAML 或 OIDC 进行登录，使用 SCIM 进行账户配置。在企业版（Enterprise）计划中，自定义角色可让你按组来限定能力范围。

> Identity comes from your IdP:an agent's identity has to be issued and revoked where you already issue and revoke everything else, with your existing groups as the unit of policy. Claude Cowork uses SAML or OIDC for sign-in and SCIM for provisioning. On Enterprise plans, custom roles let you scope capability by group.

连接器允许清单（allowlist）划定你的数据边界：连接器（MCP）的允许清单让你能够决定智能体可以触及哪些系统。Claude Cowork 采用双重闸门模型：管理员在组织范围内启用每个连接器，然后每个用户再单独为自己的账户授权。存在按角色的连接器控制，因此启用某个连接器就会让它对该角色中的所有人可用（来自你 IdP 的组可以被分配到角色）。管理员关于启用哪些连接器的决定，同时也是关于智能体可以触及哪些数据的决定。请让连接器留在你企业/生产数据边界的企业一侧；或者，如果它们要访问来自不可信来源的信息，请确保任何破坏性或单向决策都需经过人工审核。例如，如果一个个人智能体被用于处理邮件，但把网络搜索结果作为其输入的一部分，那么一个绝佳的默认设置是：只允许创建邮件草稿，绝不自动地在未经人工审核的情况下对外发送。如果数据必须跨越边界，就应经过 DLP 或 DSPM 控制。

> Connector allowlists draw your data boundary: allowslists for connectors (MCPs) let you decide which systems the agent can reach. Claude Cowork uses a two-gate model: an admin enables each connector org-wide, and each user then individually authorizes their own account. There is a per-role connector control, so enabling a connector makes it available to everyone in that role (groups from your IdP can be assigned to roles). The admin decision about which connectors to turn on is also the decision about which data the agent can reach. Keep connectors on the corporate side of your corporate/production data boundary or, if they access information from untrusted sources, ensure that human review is required for any destructive or one-way decision. For example, if a personal agent is being used for email but using web search results as a part of its input, an excellent default is to only allow draft emails to be created and never sent externally, automatically, without human review. If data must cross the boundary, it should go through the DLP or DSPM controls.

按工具、按操作的审批是风险削减变得精细之处：智能体的工具列表是一个更细粒度的权限边界，因此你需要能够移除某个特定连接器的动作/操作，而不仅仅是移除整个连接器系统。在 Claude Enterprise Chat 和 Cowork 中，管理员现在可以在组织范围内和按角色地限制每个连接器内可用的操作：允许起草文档但绝不自动发送、允许读取和搜索但绝不删除。如果那个让你彻夜难眠的故障模式是"生产数据库被删除"，那就把删除这一动作从智能体的世界里彻底移除。它绝不会尝试一个不在其工具列表中的操作。（对此需说明：Claude for Chrome 和 Claude Code 赋予了更多的自由度，因而在治理不当的情况下风险更大。智能体可能会利用工程师的浏览器删除某个生产资源，或利用其命令行 CSP 工具做同样的事。更多内容请参见我们关于[保护 Claude Code 安全](https://code.claude.com/docs/en/security)的指南。）

> Per-tool, per-action approval is where risk reduction gets granular:the agent's tool list is a more fine-grained permission boundary, so you need to be able to remove any particular connector’s verbs/actions and not only that entire connector system. In Claude Enterprise Chat and Cowork, admins can now restrict which actions are available within each connector org-wide and per-role: allow drafting docs but never automatically send them, allow reads and searches but never deletes. If the failure mode that keeps you up at night is "the production database gets deleted," remove the delete verb from the agent's world entirely. It will never attempt an action that isn't in its tool list. (A note on this: Claude for Chrome and Claude Code enable more degrees of freedom and so are more risky, if not governed well. An agent could use an engineer’s browser to delete a production resource or their command line CSP tool to do the same. See our guide to [securing Claude Code](https://code.claude.com/docs/en/security) for more.)

沙箱化执行让智能体的工作环境远离生产凭证：我们在 Anthropic 始终坚持的一条原则是，智能体循环所运行的环境绝不应持有任何值得被窃取的凭证。在 Claude Cowork 的远程会话中，智能体循环运行在 Anthropic 托管基础设施上一个隔离的临时沙箱中。连接器授权令牌绝不进入沙箱，因为连接器调用是经由一个注入真实凭证的反向代理来完成的，所以沙箱从不持有可被外泄的凭证。截至 2026 年 7 月，Anthropic 提交用于拉取请求（pull request）的所有代码中，有超过 50% 是由我们内部版本的类 Claude Tag 系统编写的。我们能够安全地运行它的主要原因在于，这一切都发生在与我们的生产密钥和账户隔离的临时虚拟机（VM）中，并且在任何内容落地之前都有人工审核。

> Sandboxed execution keeps the agent's working environment away from production credentials:one principle that we hold constant at Anthropic is that the environment the agent loop runs in should never hold a credential worth stealing. In Claude Cowork's remote sessions, the agent loop runs in an isolated, temporary sandbox on Anthropic-managed infrastructure. Connector authorization tokens never enter the sandbox, because connector calls are made via a reverse proxy that injects real credentials, so the sandbox never holds a credential that can be exfiltrated. As of July 2026, more than 50% of all code submitted for pull requests at Anthropic is authored by our internal version of a Claude Tag-like system. The primary reasons we can run that safely are that all of it happens in ephemeral VMs separated from our production keys and accounts, with a human review before anything lands.

出站允许清单（egress allowlisting）是你对抗提示注入（prompt injection）的最强控制：所有离开智能体执行环境的流量都应经过一个该环境无法重新配置或绕过的代理，并且只有你选定的目的地才可达。其原理在于，即便智能体被它所读取的某些内容所攻陷，攻击者仍然必须把数据传出去；而当出站请求只能到达你选定的域名时，就没有任何受攻击者控制的地方可以发送任何东西。在 Claude Cowork 的远程会话中，所有离开沙箱的流量都会经过一个沙箱无法重新配置或绕过的强制代理，并且只有列入允许清单的目的地才可达。该功能也是 Claude Managed Agents 的一部分。

> Egress allowlisting is your strongest control against prompt injection:all traffic leaving the agent's execution environment should pass through a proxy that environment cannot reconfigure or bypass, and only destinations you chose should be reachable. The reasoning is that, if an agent is compromised by something it read, then the attacker still has to get data out, and when outbound requests can only reach domains you chose, there is nowhere attacker-controlled to send anything. In Claude Cowork's remote sessions, all traffic leaving the sandbox passes through a mandatory proxy the sandbox cannot reconfigure or bypass, and only allowlisted destinations are reachable. The feature is also a part of Claude Managed Agents.

遥测数据通过 OpenTelemetry 发送到你的 SIEM：在你原本就用来调查问题的系统中，智能体（agent）操作必须能与用户操作区分开来，而供应商应当以数据流的形式交付这些数据，让你可以将其指向任意位置，而不是一个你必须去访问的仪表盘。在 Claude Cowork 中，管理员可以在组织设置（Organization settings）里配置一个 OTLP 端点，智能体会将每一次工具调用——工具名称、MCP 服务器、参数、成功或失败、以及耗时——连同用户身份和会话上下文一起流式传出。注意：Claude Cowork 的活动目前尚未纳入 Anthropic 的合规 API（Compliance API）或正式审计日志，但我们清楚这是一项重要的客户需求。OpenTelemetry 数据流是原生的监控路径，并且与 Claude Code 需要主动选择开启（opt-in）不同，Claude Cowork 的 OTel 输出默认包含提示词（prompt）内容。如果你的数据留存或隐私审查对 SIEM 中的提示词内容有意见，请在开启该数据流之前就把这个问题解决好。

> Telemetry goes to your SIEM over OpenTelemetry:agent actions have to be distinguishable from user actions in the system where you already investigate things, and the vendor should deliver that as a stream you can point somewhere, not a dashboard you have to visit. In Claude Cowork, admins can configure an OTLP endpoint in Organization settings and the agent streams every tool invocation—tool name, MCP server, parameters, success or failure, and duration—alongside user identity and session context. Note: Claude Cowork activity is not currently captured in Anthropic's Compliance API or formal audit logs, but we know that this is an important customer need. The OpenTelemetry stream is the native monitoring path, and prompt content is included in Claude Cowork's OTel output by default, unlike Claude Code where it is opt-in. If your retention or privacy review has an opinion about prompt content in your SIEM, have it before you turn the stream on.

有一个组织范围的总开关：在 Claude Cowork 的组织设置中，单个开关可以同时为每个用户禁用连接器（connector），包括正在进行的会话。在企业版（Enterprise）套餐中，同一控制界面让你在彻底归零之前可以先做更精细的收缩：基于角色的访问控制（RBAC）让你能从特定群组撤销访问权限，同时让其他群组继续运行；而针对单个连接器的控制让你能够禁用某个特定集成上的写操作，而不影响部署的其余部分。一份好的事件响应计划会在你需要之前就把这三个层级全部规划清楚。

> There is an org-wide off switch:In Claude Cowork's Organization settings, a single toggle disables connectors for every user simultaneously, active sessions included. On Enterprise plans, the same control surface lets you go narrower before you go to zero: RBAC lets you pull access from specific groups while leaving others running, and per-connector controls let you disable write operations on a specific integration without touching the rest of the deployment. The right incident response plan has all three layers mapped out before you need them.

### 治理不必成为瓶颈

> Governance doesn’t have to be a bottleneck

我从其他 CISO 那里听到最多的一点是，他们的董事会要求他们快速行动，而治理（即回答这些问题、强制推行这些控制措施）让安全看起来像是瓶颈。其实不必如此。

> The observation I hear most from other CISOs is that they are being asked to move fast by their boards and governance (i.e., answering these questions and mandating these controls) makes security seem like the bottleneck. It doesn't have to.

事实上，我们的治理、风险与合规（GRC）团队自己也运行智能体（agent）。例子包括回复安全问卷、阅读供应商问卷回复和子处理方变更通知，并标记出我们应当反对的那些。

> In fact, our Governance, Risk, and Compliance teams run agents of their own. Examples include security-questionnaire responses and reading vendor questionnaire responses and subprocessor-change notifications, and flagging the ones we should object to.

以下是我们从运行这些智能体中学到的三点：

> Here are three things we've learned from running them:

- 首先从风险登记册入手。一个每季度评审一次的登记册，无法治理那些变化速度快于风险治理流程记录新风险速度的系统。想办法将其自动化，可能把智能体与安全评审流程集成起来。
- 了解是谁构建了它们以及为什么。在我们这里，GRC 智能体是由非工程人员用 Claude Code 在一个托管业务应用的内部平台上构建的。人们绕过安全，是因为受认可的路径太慢，而这正是大多数影子采用（shadow adoption）的根源。一名能在你看得见的地方构建自己所需工具的合规分析师，并不是影子采用。
- 人的问责是工作流的一部分。有意接受风险，是由有权接受该风险的人来完成的行为。如果你有 ISO 42001 或类似体系，配有实时的风险登记册和背后的高管风险委员会，那么输出就有了落脚点：重新评分会送到能够接受它们的人手中，被标记的供应商条款会送到负责谈判的人手中。如果你已经有了 ISO 27001，通常在现有审计方那里增加 42001 只是一项增量补充。

> • Take the risk register first.A register reviewed quarterly can't govern systems that change faster than the risk governance process can document new risks. Find a way to automate this, possibly integrating an agent with the security review process.
> • Understand who built them and why. In our case, non-engineers built the GRC agents, with Claude Code, on an internal platform for hosting business apps. People route around security because the sanctioned path is slow, and that's the origin of most shadow adoption. A compliance analyst who can build the tool they need, where you can see it, isn't shadow adoption.
> • Human accountability is part of the workflow. Deliberately accepting risk is an act performed by humans with the authority to accept it. If you have ISO 42001 or something like it, with a live risk register and an executive risk council behind it, the output lands somewhere: re-scores reach the people who can accept them, flagged vendor terms reach the people who negotiate them. If you already have ISO 27001, often adding 42001 is an incremental addition with your current auditor.

### 为不断进化的模型智能设计你的安全协议

> Design your security protocol for evolving model intelligence

如果你按照模型今天的能力来设计新方案，等到方案上线时你就已经落后了。要按照模型六个月后的水平来设计。模型智能的提升带来更多的自由度，会让那些配有精细提示词的复杂脚手架（scaffold）变得过时；如果你依赖这些东西来做控制，它们会在未来几代内部应用的智能体中被移除，让你失去控制点。

> If you design your new program for what the model can do today, you will be behind by the time your program launches. Design for where the model will be in six months. Increased model intelligence enables more degrees of freedom and obsoletes elaborate scaffolds with meticulous prompts; if you lean on these for controls, they will be cut out of agents in future generations of internal applications leaving you without a control point.

那些持有自己账户、运行跨越数天工作流的智能体，已经借助 Claude Tag 等工具在 Anthropic 和其他组织内部运行，它们需要像管理人一样被治理：身份、最小权限、监控，以及一套能在几分钟内响应的内部风险（insider-risk）方案。现在就在上述这类低风险智能体上锻炼出这套能力的组织，等到高自主性的用例到来时，才有能力说“可以”。

> Agents that hold their own accounts and run multi-day workstreams already operate inside Anthropic and other organizations with tools like Claude Tag, and they need to be governed the way you govern people: identity, least privilege, monitoring, and an insider-risk program that can respond in minutes. The organizations that build that muscle now, on low-risk agents like the examples above, will be ready to say yes when the high-autonomy use cases arrive.

### 开始行动

> Getting started

上面的框架只有在改变你所在组织的某个决策时才有价值。以下是三个可以着手的地方：

> The framework above is only useful if it changes a decision in your organization. Here are three places to start:

- 挑选内部推动压力最大的智能体（agentic）用例，用这四个问题过一遍。目标是找出你会在何种条件下批准它，而不是给出一个裁决。
- 把上面的七项要求带给那些正在构建智能体、且你已经在付费的团队和供应商。问问你的身份提供商（IdP）、你的安全信息与事件管理系统（SIEM），以及任何智能体供应商：其中哪些他们今天就能在你的技术栈里演示给你看它确实可用。
- 确定你的信任边界。写下在你的环境中什么算作不可信内容。一旦这条线存在，未来每一个智能体决策都会变得更容易。

> • Pick the agentic use case with the most internal pressure and run it through the four questions. The goal is to find the conditions under which you would approve it, not to produce a verdict.
> • Take the seven requirements above to the teams and vendors building agents whom you already pay. Ask your IdP, your SIEM, and any agent vendor which of these they can show you working in your stack today.
> • Decide your trust boundary. Write down what counts as untrusted content in your environment. Every future agent decision gets easier once that line exists.

等待零风险意味着永远等待。网络是充满对抗性的，模型在快速演进，而那些现在就学会衡量并接受这种风险的组织，正是能获得优势的组织。

> Waiting for zero risk means waiting forever. The web is adversarial, the models are evolving fast, and the organizations that learn to size and accept this risk now are the ones that get the advantage.

关于本文背后的控制措施、鉴证报告和白皮书，请从[trust.anthropic.com](https://trust.anthropic.com)开始。也可以看看[我们的配套文章](https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense)，内容是关于如何防御 AI 加速的攻击。

> For the controls, attestations, and white papers behind this post, start at[trust.anthropic.com](https://trust.anthropic.com). Check out[our companion piece](https://claude.com/blog/preparing-your-security-program-for-ai-accelerated-offense)on defending against AI-accelerated offense.

‍本文由 Anthropic 副首席信息安全官（Deputy CISO）Jason Clinton 撰写。

> ‍This article was written by Jason Clinton, Deputy CISO, Anthropic.

## 术语对照

| English | 中文 |
|---|---|
| agentic AI | 智能体 AI |
| CISO | 首席信息安全官 |
| risk assessment framework | 风险评估框架 |
| shadow adoption | 影子采用 |
| telemetry | 遥测 |
| prompt injection | 提示注入 |
| untrusted content | 不可信内容 |
| blast radius | 影响半径 |
| principle of least agency | 最小代理权原则 |
| observability | 可观测性 |
| SIEM | 安全信息与事件管理系统 |
| insider risk | 内部威胁 |
| identity access model | 身份访问模型 |
| service account | 服务账户 |
