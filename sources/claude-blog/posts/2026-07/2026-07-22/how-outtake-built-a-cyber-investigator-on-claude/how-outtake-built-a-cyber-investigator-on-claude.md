# Outtake 如何在 Claude 上构建网络安全调查员

> How Outtake built a cyber investigator on Claude

> 来源：Claude Blog / Anthropic，2026-07-22
> 原文链接：https://claude.com/blog/how-outtake-built-a-cyber-investigator-on-claude
> 分类：AI 应用 / 网络安全智能体

## 核心要点

- AI 能力被不法分子伪装成无害用途后，可用于生成仿真登录门户、分发钓鱼内容和伪造身份，使传统网络安全防御难以应对。
- 攻击者通常遵循“将公开数据武器化、构建假冒身份作为诱饵、利用内部系统”这一可预见的三段式流程，而 AI 加速了该流程。
- 传统安全工具分别覆盖威胁情报、品牌保护和端点防护，每次只能守住攻击链中的一个环节。
- Outtake 的 Recon Agent 不止于下线单个克隆登录页，而是收集分类证据、顺线索追踪关联基础设施，并以图谱形式勾勒整个攻击者网络并输出调查报告。
- Recon Agent 能够读写和运行代码，甚至直接与恶意登录页面交互以查明被窃凭据的流向，单次会话运行时长中位数为 16 分钟，最长一次达到两小时。
- 构建过程分四步推进：先由工程师亲自开展真实调查以定义“好”的标准，再在 Claude Code 中做原型，随后借助 Agent SDK 升级到生产级运行框架，最后建立由评估驱动的迭代循环。
- 核心设计原则是在编排层面对智能体施加严格约束，同时在需要判断力的环节留出自由发挥空间。
- 为智能体提供文件系统和 bash 这类开放式工具，可在上下文压缩后保留记忆，并让它在工具失败时自行找到变通办法。
- 提示词被视为建议而非保证，应当把“每次都必须执行”的内容从系统提示中提取出来，固化进护栏与框架。
- 评估的更大价值在于提速而非仅保障可靠性，把人工反思结构化为可打分的自动检查，可让另一个智能体评审长篇运行记录并驱动工具自动改进。
- 面对提示注入这一真实威胁，团队采用假定智能体可能被劫持的“防爆箱”思路做隔离，并在智能体接触互联网的节点上对内容打信任分。

## 正文

*在我们的系列文章 ***《初创公司如何用 Claude 构建产品》**中，我们重点介绍初创公司如何借助 AI 变革各自所在的行业。本文分享 Outtake 如何打造出一位自主的网络安全调查员，它能够检测、调查并瓦解各类数字威胁，从克隆的登录页面到整个攻击者网络。

> *In our series, ***How startups build with Claude,** we highlight how startups are transforming their industries with AI. In this article, we share how Outtake built an autonomous cyber investigator that detects, investigates, and dismantles digital threats, from cloned login pages to entire adversarial networks.

即使拥有强有力的防护措施和管控手段，不法分子仍可能将其对 AI 的使用伪装成看似无害的用途，从而掩盖其恶意意图。代码生成平台可以创建以假乱真的登录门户，代理式的市场推广工具可以助力钓鱼攻击的分发，图像生成能力则可以伪造身份。传统的网络安全防御手段难以招架。

> Even with strong safeguards and controls, bad actors can mask their use of AI in seemingly benign purposes that hide their malicious intent. Code generation platforms can create convincing login portals, agentic go-to-market tooling can power the distribution of phishing attacks, and image generation capabilities can spoof identity. Traditional cybersecurity defenses struggle to keep up.

“如果你站在坏人的角度想,现在其实是发动攻击的绝佳时机,”AI 网络安全平台 [Outtake](https://www.outtake.ai/) 的创始人兼首席执行官 Alex Dhillon 说。“借助 AI,一次攻击不仅执行速度更快,而且还能获取更深层的访问权限。”

> “If you put on the bad actor's hat, it's actually a great time to be running attacks,” says Alex Dhillon, founder and CEO of AI cybersecurity platform [Outtake](https://www.outtake.ai/). “The average attack is not only executed faster because of AI, but it also captures deeper access due to AI”

Outtake 将完整的[数字信任攻击链](https://www.outtake.ai/blog/2026-digital-trust-industry-pain-report)统一到单一防御体系中，利用 AI 智能体集群自主检测、调查并瓦解针对其客户的威胁，这些客户包括领先的 AI 实验室、大型对冲基金和美国联邦机构。

> Outtake unifies the full [digital trust attack chain](https://www.outtake.ai/blog/2026-digital-trust-industry-pain-report) into a single defense, using fleets of AI agents to autonomously detect, investigate, and dismantle threats aimed at their customers, which include leading AI labs, major hedge funds, and US federal agencies. 

以下是 Outtake 团队最近如何使用 [Claude Code](https://code.claude.com/docs/en/quickstart) 和 [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview)，在 Claude 上构建 Recon Agent（一个长时间运行的自主网络安全调查员）的过程。

> Here’s how the Outtake team recently built the Recon Agent, a long-running autonomous cyber investigator, on Claude using [Claude Code](https://code.claude.com/docs/en/quickstart) and the [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview).

#### **智能体化的进攻需要智能体化的防御**

> **Agentic offense needs agentic defense**

在针对某家公司发起攻击时，攻击者通常会经历相同的流程：将公开数据武器化 → 构建假冒身份作为诱饵 → 利用内部系统。这一流程已被 AI 加速。

> When targeting a company, attackers typically move through the same process: weaponize public data → build impersonations as lures → exploit internal systems. This process has been accelerated by AI.

在入侵任何目标之前，他们会收集有关某个组织及其高管和员工的公开信息。

> Before breaking into anything, they harvest publicly available information about an organization, and its executives and employees.

随后，他们会把这些情报变成诱饵，例如带有欺诈性登录页面的假冒网站，诱骗受害者交出凭据。通过这些诱饵获得的访问权限，可以帮助攻击者突破边界，进而触及组织最有价值、最敏感的资产。

> They then turn that intelligence into bait, like a fake website with a fraudulent login page, to trick victims into handing over credentials. The access gained from these lures help the attacker get inside the perimeter to reach an organization’s most valuable and sensitive assets.

   
这三段式序列是可以预见的，但传统安全工具每次只能守住其中一环：

>
> This three-part sequence is predictable, but legacy security tooling guards only one slice at a time:

- 威胁情报工具监控公开数据阶段，
- 品牌保护工具会监控仿冒行为，并且
- 端点工具守护着内部系统。

> • Threat intelligence tools monitor the public-data stage,
> • Brand protection tools watch for impersonations, and
> • Endpoint tools guard the internal systems. 

Outtake 的 Recon Agent 会调查冒充行为背后的完整网络。举例来说，该 agent 不只是下线一个克隆的登录页面，而是从冒充事件中收集并分类证据。

> Outtake’s Recon Agent investigates the full network behind an impersonation. Instead of just taking down a cloned login page, for example, the agent gathers and classifies evidence from the impersonation event. 

它会顺着这些线索追踪到关联的基础设施，比如一个自称“客户支持”的虚假 Telegram 账号，并以图谱形式勾勒出这个攻击者网络。该智能体的最后一步会生成一份报告，说明调查过程、威胁行为者的画像，以及攻击者所作所为的时间线重建。 

> It follows those leads to connected infrastructure, like a fake Telegram account that presents itself as “Customer Support,” and maps this adversarial network in a graph. The agent’s final step produces a report explaining the investigation process, a profile of the threat actor, and a reconstructed timeline of what the attacker did. 

为了执行这一复杂的工作流程，Recon Agent 能够读取、编写和运行代码。它甚至可以直接与恶意登录页面交互，以查看被窃取的凭据实际流向了何处。

> To carry out this sophisticated workflow, the Recon Agent can read, write, and run code. It can even interact with malicious login pages directly to see where stolen credentials actually go. 

这些调查工作可能需要智能体长时间自主运行。智能体会话的运行时长中位数为 16 分钟，但经常延长到一小时甚至更久；迄今为止最长的一次运行在返回结果前进行了两小时的智能体工作。

> These investigations can require agents to run autonomously for long periods of time. Agent sessions run a median of 16 minutes, but routinely stretch to an hour and beyond; the longest run thus far lasted two hours of agentic work before returning results.

#### **Outtake 如何借助 Claude 构建复杂的长时运行智能体**

> **How Outtake built a complex long-running agent with Claude**

Outtake 大致分四个阶段构建了 Recon Agent。每个阶段的重点都是先理解一次出色的调查应该是什么样子，然后逐步把这种判断力交给 agent。

> Outtake built the Recon Agent in roughly four stages. Each stage was about understanding what a good investigation looked like, then progressively handing that judgment to the agent.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a60e7ad9916514322ed5ac4_3f776183.png)

##### **第一步：先成为专家。**

> **Step 1: Become the expert first.**

在构建 agent 的任何部分之前，Outtake 的工程师们亲自开展了真实的网络调查，并从客户和设计合作伙伴那里汲取领域专业知识。

> Before building any part of the agent, Outtake's engineers ran real cyber investigations themselves and pulled domain expertise from customers and design partners. 

目标是定义"好"应该是什么样子。对于这类调查而言，这意味着要识别哪些证据是重要的、如何组织这些证据，以及是什么把一个可付诸行动的结论与一次猜测区分开来。这个标准成为他们在之后每个阶段都会回归的固定参照点。

> The goal was to define what "good" looks like. For these types of investigations, that meant identifying what evidence matters, how to organize it, and what separated an actionable conclusion from a guess. That standard became the fixed reference point they returned to at every later stage. 

“构建长时间运行的智能体，最重要的一点是你必须真正理解*什么才算好？* *这个智能体应该做什么？*”Outtake 智能体平台的工程负责人 Jack Hayford 说。“因为归根结底，你要确保智能体每一次都能做到这一点。”

> “The most important thing about building long running agents is that you really have to understand *what does good look like?* *What is the agent supposed to be doing?*” said Jack Hayford, engineering lead for Outtake's agent platform. “Because ultimately you're ensuring that the agent can do that every single time.”

##### **第 2 步：在 Claude Code 中做原型**

> **Step 2: Prototype in Claude Code**

起初，Outtake 团队使用传统的 agent 框架，逐步将他们正在标准化的调查流程自动化。

> Initially, the Outtake team used traditional agent frameworks to progressively automate the investigations they were standardizing. 

然而他们很快意识到，Recon Agent 不能只是一个简单的调查者。它需要编写和运行代码、随时构建工具，并真正与恶意域名进行交互。

> They quickly realized, however, that the Recon Agent couldn't just be a simple investigator. It needed to write, run code, build tools on the fly, and actually interact with malicious domains. 

“每一次调查都各不相同，而且技术性极强，”Hayford 说。“这个 agent 需要具备编码实力和能力，而 Claude Code 为我们提供了一个强大的初始载体，让我们能够真正验证这些假设，并开始不断深入地实验。”   
  
正是通过在 Claude Code 中进行原型开发，他们确立了自己的核心设计原则：在编排层面对 agent 施加严格约束（*“调查某个域名时，始终执行 X、Y、Z”*），但在需要判断力时，让它可以自由发挥。

> “Every investigation is different, and deeply technical,” Hayford said. “The agent needed coding muscle and capability, and Claude Code was a strong initial harness for us to actually validate those assumptions and start experimenting more and more.”   
>
> It was by prototyping in Claude Code that they forged their core design principle: constrain the agent tightly at the orchestration level (*‘always do X, Y, Z when investigating a domain’*), but leave  it free to improvise whenever judgement was required.

##### **第 3 步：升级到生产级的运行框架**

> **Step 3: Graduate to a production-grade harness**

“我们非常喜欢 Claude Code 引入的这些模式，但我们还需要额外访问那些更底层的原语，而这些并不是我们打算自己去构建的，”Hayford 说。

> “We really liked the patterns that Claude Code had introduced, but we needed additional access to the lower level primitives, which we weren't trying to build ourselves,” Hayford said.

使用 Claude [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) 是将 Recon Agent 推向生产环境的自然的下一步。沿用 Claude Code 中的技能和模式，确保团队在无需就 agent 循环和会话处理重新造轮子的情况下，既没有损失任何速度，又获得了对 Recon Agent 的记忆、上下文和文件系统更严密的控制。

> Using the Claude [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) was a natural next step for taking the Recon Agent into production. Carrying over skills and patterns from Claude Code ensured that the team didn't drop any velocity while they gained tighter control over the Recon Agent’s memory, context, and file system without reinventing the wheel in terms of the agent loop and handling sessions.

##### **第 4 步：构建由评估驱动的紧密迭代循环。 **

> **Step 4: Build a tight iteration loop driven by evals. **

能够低成本、快速响应地进行迭代，在网络安全领域尤为关键——攻击者一旦得知某种防御工具的存在，就会立刻做出调整。团队从一开始就集成了智能体评估，并构建出一套强大的评估套件，可以同时运行大量场景。这让他们能够安全且自信地做出大刀阔斧的改动，比如模型升级和记忆系统的彻底重构。

> The ability to iterate inexpensively and responsively is particularly crucial in cybersecurity, where attackers adapt the moment they learn a defensive tool exists. The team integrated agent evals from the very beginning, and arrived at a strong eval suite that runs many scenarios at once. This let them make sweeping changes, like model upgrades and full memory-system refactors, safely and with confidence. 

这也让团队得以从智能体循环中抽身出来。举例来说，当侦察智能体（Recon Agent）完成一次调查后反馈说，如果有某个它当时不具备的工具，本可以做得更好，这时另一个独立的编码智能体便会读取这些建议，编写出新工具，并搭建一个测试场景来试用它。

> It also let the team pull themselves out of the agentic loop. When, for example, the Recon Agent finishes an investigation and reports back that it could have done better with some tool it didn't have, a separate coding agent then reads those suggestions, writes the new tool, and builds a test scenario to try it out. 

只有在最后阶段才会有人介入查看结果：这个智能体用了那个工具之后，调查做得更好了吗？“我们才是瓶颈所在，而当你构建这些漫长而复杂的智能体时，反馈循环实现自动化就非常重要。这样快得多，而且作为开发者也让人更有成就感，”Hayford 说道。

> Only at the very end does a human step in to look at the result: did the agent do the investigation better with that tool, or not? “We are the bottleneck, and when you build these long, complex agents, it's very important that the feedback loop be automated. It's a lot faster and it's also a lot more satisfying as a developer,” said Hayford.

#### **构建长时运行智能体的经验总结**

> **Learnings from building a long-running agent**

在智能体发展的早期，开发者会预先编写脚本来规定智能体的行为，用硬编码的、确定性的分步路径来防止它偏离轨道。如今，繁复的工作流正在被一种支撑框架（harness）所取代：一个由记忆、工具、技能和护栏构成的支持性环境。

> In the early days of agents, builders scripted agent behavior in advance with hardcoded, deterministic, step-by-step paths to keep it from going off the rails. Now, elaborate workflows are being replaced by a harness: a supportive environment of memory, tools, skills, and guardrails.

以下是 Outtake 团队在实现 Recon Agents 构建过程中总结出的一些经验要点。

> Here are some takeaways from the Outtake team’s experience in implementing the Recon Agents build.

##### **工具：一个文件系统和 bash 就够了**

> **Tools: a filesystem and bash is all you need**

文件系统实现了在上下文压缩后依然留存的记忆。智能体通常会被赋予非常具体且细致的工具，但为智能体提供一个文件系统，以及编写、读取和运行代码的能力，能帮助它应对各种障碍。

> Filesystem enables memory that survives compaction. Agents are typically given very specific and nuanced tools, but giving an agent a filesystem along with the ability to write, read, and run code helps the agent respond to obstacles. 

“把那些极其强大的开放式工具和能力交给一个智能体，是一次巨大的阶段性转变。我们观察到大量这样的案例：智能体手里的某个工具因为网络抖动之类的原因失败了，而它就会自己找到正确的变通办法继续做下去，”Hayford 说。“因为我们构建的其余框架足够稳固，也因为这些强大的开放式工具给智能体留出了即兴发挥的空间，它最终仍然能够达成成功的结果。”

> “Handing those extremely powerful open-ended tools and capabilities to an agent is a huge step change. We’ve observed plenty of cases where an agent had a tool that was failing due to a network hiccup or whatever, and it would just find the right workaround and continue,” said Hayford. “Because the rest of the harness that we had built was strong enough, and because it left the agent with opportunity for improvisation with these powerful, open-ended tools, it was still able to get to a successful outcome.”

##### **提示词只是建议**

> **Prompts are suggestions**

提示词在需要时提供灵活性，但尽可能硬编码才能确保稳定性。“当你在构建这些随时间推移变得越来越复杂的长期运行智能体时，提示词只是建议，”Hayford 说。“当智能体没有按你的意图行事时，自然的反应就是去修改智能体中可塑性最强的那部分。把‘当 X 发生时，务必执行 Y’塞进系统提示词中，起初可能有效，但随着这个智能体运行得越久，该提示词中的每一个词最终都可能被忽略。”  
  
正确的做法是围绕这种可能性来构建：识别出智能体每一次都应当执行的内容，并将其变成智能体护栏的一部分。“把这些东西从提示词中提取出来，放进框架里，”他说。“现在智能体不必再去考虑它了，它有更多的上下文空间和注意力可以投入到真正能发挥所长的领域。”

> Prompts provide flexibility when needed, but hardcoding where possible ensures stability. “When you're building these long-running agents that get complicated over time, prompts are suggestions,” Hayford said. “When an agent didn't do what you wanted, the natural response is to add to the most plastic part of the agent. Slipping ‘when X happens, make sure you do Y’ into the system prompt may work initially, but as this agent runs longer, every single word in that prompt will probably be ignored eventually.”   
>
> The correct approach is to build around that likelihood by identifying what the agent should always do every time and making it part of the agent guardrails. “Pull these things out of the prompt and put them into the harness,” he said. “Now the agent doesn't have to think about it anymore and it has more context space and attention to put towards areas where it can really thrive.” 

*延伸阅读：*[指导 Claude 的最佳实践](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)*，以及每种方法的上下文成本与权威性。*

> *Read more on *[best practices for directing Claude](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)*, and the context cost and authority of each method. *

##### **评估不只是为了可靠性，更是为了速度**

> **Evals are for speed, not just reliability**

把手动的“反思”当作通往自动化评估的路线图，从而缩短开发周期。** **传统观点认为，评估是保障可靠性的质量关口。但对于长时间运行的智能体来说，更大的收益在于速度。

> Use manual “reflections” as a roadmap to automated evals that tighten dev cycles.** **The conventional view is that evals are a quality gate for reliability. For long-running agents, though, the bigger payoff is speed. 

早期，每次侦察智能体（Recon Agent）运行时，团队都会人工评审它的表现。但阅读一份记录了智能体所有操作的 30 分钟长的对话记录极其煎熬，而且无法规模化。

> Early on, every time the Recon Agent ran, the team did a manual review of its performance. But reading an agent’s 30-minute transcript of everything it did is brutal and doesn't scale. 

“在现代智能体开发中，评估输出是整个循环中成本最高的一步，”Jack 说。

> “In modern agent development, evaluating the output is the most expensive step in the loop,” Jack said. 

评估（eval）就是把这种反思变成结构化、可打分、可自动化的版本。一旦你把「什么才算好」编码成一项可重复的检查，你就可以让一个 agent 坐上评审席，去阅读那份 30 分钟的运行记录并为这次运行打分。

> An eval is just a structured, graded, automatable version of that reflection. Once you've codified what good looks like into a repeatable check, you can put an agent in the judge's seat to read the 30-minute transcript and score the run.

“我觉得有些工程师对构建评估（evals）感到有些顾虑，因为这就好像要打造一个完美的方案，”Jack 说，“但从一开始就构建某种形式的评估，无论它们有多正式、多‘完美'，都会让你更快地做出那个 agent。”

> “I think that some engineers feel apprehensive about building evals because it's like this idea of building a perfect case,” Jack said. “Building some version of evals from the very beginning will make you build that agent faster regardless of how official or ‘perfect' they are.”

##### **保护你的智能体**

> **Protecting your agents**

[提示注入](https://www.anthropic.com/research/prompt-injection-defenses)是真实存在的威胁，因此把智能体放进沙箱或为它加上防护装甲至关重要。Outtake 团队选择 Claude，部分原因就在于它对提示注入的抵御能力很强。

> [Prompt injection](https://www.anthropic.com/research/prompt-injection-defenses) is a real threat, so putting your agent in a sandbox or giving it armor is essential. The Outtake team chose Claude in part because of its strength against prompt injection. 

“安全性对我们构建 Recon Agent 来说是一个重要考量，”Hayford 说。“我们给了它一个文件系统和 bash，并且我们要把它送到充满对抗性的环境中，所以我们必须解决的最重要的问题，就是构建一种防爆箱，让你能够把你的 agent 与敏感的内部信息隔离开，同时又不会真正妨碍它的运作。” 

> “Security is a big note for us for building the Recon Agent,” Hayford said. “We gave it a file system and bash and we're sending it to adversarial environments, so the most important problem we had to solve was building a sort of blastbox where you could try to hide your agent from sensitive internals without actually hindering it.” 

他们的方法假定 agent 可能会被劫持，因此对周边系统进行了工程设计以控制损害范围。不过，安全性会因 agent 的用途不同而有所差异，并非所有 agent 都适合采用 blastbox 方案。

> Their approach assumes the agent might get hijacked, so the surrounding system is engineered to contain the damage. Security looks different from agent to agent, however, depending on their purpose, and not all agents are blastbox candidates. 

Outtake 现在会在 agent 接触互联网的确切节点上为信任级别打分，实现了一个检查点，对 agent 即将触及的任何内容进行评估：“这个页面是冒充的吗？它是恶意软件吗？它此刻是否正试图对 agent 进行提示注入？”随着 agent 穿行于日益充满敌意的互联网，这可能正是它们所需要的护甲。

> Outtake is now scoring the level of trust at the exact point where the agent reaches out to the internet, implementing a checkpoint that evaluates whatever the agent is about to touch: ‘Is this page an impersonation? Is it malware? Is it trying to prompt-inject the agent right now?’ This may be exactly the armor that agents need as they traverse an increasingly adversarial internet.

#### **下一步计划**

> **What's next**

Recon Agent 现已上线，今天就在运行调查任务。如果你想深入了解 Outtake 如何使用 Claude 大规模绘制敌对基础设施图谱：

> Recon Agent is live and running investigations today. If you want to go deeper on how Outtake uses Claude to map adversarial infrastructure at scale:

- [观看完整的网络研讨会](https://www.anthropic.com/webinars/outtake-built-cyber-investigator-claude)*，获取现场演示，并深入了解 Outtake 如何使用 Claude 大规模自主调查和绘制威胁基础设施。*
- [查看 Recon Agent 的实际运行效果](https://www.outtake.ai/solutions/recon-agent)*。了解该智能体如何从单次仿冒事件出发，构建出完整的威胁行为者画像。*
- [免费获取一次 Recon Agent 评估](https://www.outtake.ai/recon-agent-assessment)*，看看调查能在你自身的暴露面上发现什么。*

> • [View the full webinar](https://www.anthropic.com/webinars/outtake-built-cyber-investigator-claude)* for a live demo and deeper discussion of how Outtake uses Claude to autonomously investigate and map threat infrastructure at scale.*
> • [See Recon Agent in action](https://www.outtake.ai/solutions/recon-agent)*. Explore how the agent moves from a single impersonation to a full threat actor profile.*
> • [Get a free Recon Agent assessment](https://www.outtake.ai/recon-agent-assessment)* to see what an investigation surfaces on your own exposure.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Recon Agent | 侦察智能体 | Outtake 构建的长时运行自主网络安全调查智能体。 |
| Agent SDK | 智能体开发工具包 | Claude 提供的底层原语集合，用于将智能体推向生产环境。 |
| Claude Code | Claude Code | Anthropic 的编码智能体产品，此处被用作原型验证载体。 |
| harness | 支撑框架 | 由记忆、工具、技能与护栏构成的智能体运行支持环境。 |
| prompt injection | 提示注入 | 通过外部内容篡改智能体指令的攻击手段。 |
| blastbox | 防爆箱 | 将智能体与敏感内部信息隔离、控制被劫持后损害范围的沙箱方案。 |
| eval | 评估 | 把“什么算好”编码为可重复打分检查的结构化验证方式。 |
| guardrail | 护栏 | 写入框架而非提示词、约束智能体必须执行行为的机制。 |
| context compaction | 上下文压缩 | 会话过长时对历史上下文进行精简的处理过程。 |
| agent loop | 智能体循环 | 智能体反复调用工具、观察结果并继续推进的执行流程。 |
| threat intelligence | 威胁情报 | 监控公开数据阶段风险信号的安全能力。 |
| brand protection | 品牌保护 | 监测仿冒站点与假冒身份的安全能力。 |
| endpoint security | 端点安全 | 守护组织内部终端与系统的防护手段。 |
| threat actor | 威胁行为者 | 发起攻击的个人或组织，可被刻画为画像。 |
| digital trust attack chain | 数字信任攻击链 | 从公开信息收集到内部系统利用的完整冒充攻击路径。 |
| sandbox | 沙箱 | 限制智能体权限与影响范围的隔离运行环境。 |
