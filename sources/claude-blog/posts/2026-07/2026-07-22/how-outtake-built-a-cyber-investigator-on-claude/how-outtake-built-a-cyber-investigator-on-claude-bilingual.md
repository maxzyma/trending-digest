# Outtake 如何在 Claude 上构建网络安全调查智能体

> How Outtake built a cyber investigator on Claude

在我们的系列《创业公司如何用 Claude 构建》中，我们展示了创业公司如何用 AI 变革各自的行业。本文将分享 Outtake 如何构建一个自主的网络调查员，它能检测、调查并瓦解各类数字威胁，从克隆的登录页面到整张敌对网络。

> *In our series, ***How startups build with Claude,** we highlight how startups are transforming their industries with AI. In this article, we share how Outtake built an autonomous cyber investigator that detects, investigates, and dismantles digital threats, from cloned login pages to entire adversarial networks.

即便有强大的防护和控制措施，不法分子仍能把 AI 的使用伪装成看似无害的用途，掩盖其恶意意图。代码生成平台可以制作以假乱真的登录门户，具备自主能力的市场推广工具可以为钓鱼攻击的分发提供动力，图像生成能力则可以伪造身份。传统的网络安全防御难以跟上。

> Even with strong safeguards and controls, bad actors can mask their use of AI in seemingly benign purposes that hide their malicious intent. Code generation platforms can create convincing login portals, agentic go-to-market tooling can power the distribution of phishing attacks, and image generation capabilities can spoof identity. Traditional cybersecurity defenses struggle to keep up.

“如果你戴上不法分子的帽子，现在其实是发动攻击的绝佳时机，”AI 网络安全平台 [Outtake](https://www.outtake.ai/) 创始人兼 CEO Alex Dhillon 说。“借助 AI，普通一次攻击不仅执行得更快，还能获取更深层的访问权限。”

> “If you put on the bad actor's hat, it's actually a great time to be running attacks,” says Alex Dhillon, founder and CEO of AI cybersecurity platform [Outtake](https://www.outtake.ai/). “The average attack is not only executed faster because of AI, but it also captures deeper access due to AI”

Outtake 将完整的[数字信任攻击链](https://www.outtake.ai/blog/2026-digital-trust-industry-pain-report)统一为单一防御体系，用成群的 AI 智能体自主检测、调查并瓦解针对其客户的威胁，这些客户包括领先的 AI 实验室、大型对冲基金和美国联邦机构。

> Outtake unifies the full [digital trust attack chain](https://www.outtake.ai/blog/2026-digital-trust-industry-pain-report) into a single defense, using fleets of AI agents to autonomously detect, investigate, and dismantle threats aimed at their customers, which include leading AI labs, major hedge funds, and US federal agencies. 

下面介绍 Outtake 团队近期如何在 Claude 上，使用 [Claude Code](https://code.claude.com/docs/en/quickstart) 和 [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) 构建 Recon Agent——一个长时间运行的自主网络调查员。

> Here’s how the Outtake team recently built the Recon Agent, a long-running autonomous cyber investigator, on Claude using [Claude Code](https://code.claude.com/docs/en/quickstart) and the [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview).

### 智能体攻防需要智能体防御

> **Agentic offense needs agentic defense**

在瞄准一家公司时，攻击者通常会经历相同的流程：将公开数据武器化 → 构建冒充身份作为诱饵 → 利用内部系统。这一流程已被人工智能加速。

> When targeting a company, attackers typically move through the same process: weaponize public data → build impersonations as lures → exploit internal systems. This process has been accelerated by AI.

在入侵任何目标之前，他们会收集有关某个组织及其高管和员工的公开可得信息。

> Before breaking into anything, they harvest publicly available information about an organization, and its executives and employees.

随后他们将这些情报转化为诱饵，比如一个带有伪造登录页面的假冒网站，诱骗受害者交出凭据。通过这些诱饵获得的访问权限，帮助攻击者进入边界之内，触及组织最有价值、最敏感的资产。

> They then turn that intelligence into bait, like a fake website with a fraudulent login page, to trick victims into handing over credentials. The access gained from these lures help the attacker get inside the perimeter to reach an organization’s most valuable and sensitive assets.

这个三段式序列是可预测的，但传统安全工具每次只能守护其中一个环节：

>  $  
> /$This three-part sequence is predictable, but legacy security tooling guards only one slice at a time:

- 威胁情报（threat intelligence）工具监控公开数据阶段，
- 品牌保护（brand protection）工具监视冒充行为，
- 端点（endpoint）工具守护内部系统。

> • Threat intelligence tools monitor the public-data stage,
> • Brand protection tools watch for impersonations, and
> • Endpoint tools guard the internal systems. 

Outtake 的侦察智能体（Recon Agent）会调查冒充行为背后的整张网络。举例来说，它不仅仅是下架一个克隆的登录页面，而是从冒充事件中收集并分类证据。

> Outtake’s Recon Agent investigates the full network behind an impersonation. Instead of just taking down a cloned login page, for example, the agent gathers and classifies evidence from the impersonation event. 

它顺着这些线索追踪到关联的基础设施，比如一个自称“客户支持”的假冒 Telegram 账号，并将这一敌对网络绘制成图谱。智能体的最后一步会生成一份报告，说明调查过程、威胁行为者的画像，以及重建的攻击者行为时间线。

> It follows those leads to connected infrastructure, like a fake Telegram account that presents itself as “Customer Support,” and maps this adversarial network in a graph. The agent’s final step produces a report explaining the investigation process, a profile of the threat actor, and a reconstructed timeline of what the attacker did. 

为了执行这一复杂的工作流，侦察智能体能够读取、写入并运行代码。它甚至可以直接与恶意登录页面交互，以查看被窃取的凭据实际流向何处。

> To carry out this sophisticated workflow, the Recon Agent can read, write, and run code. It can even interact with malicious login pages directly to see where stolen credentials actually go. 

这些调查可能要求智能体长时间自主运行。智能体会话的运行时长中位数为 16 分钟，但经常延长到一小时甚至更久；迄今为止最长的一次运行在返回结果前进行了两小时的智能体工作。

> These investigations can require agents to run autonomously for long periods of time. Agent sessions run a median of 16 minutes, but routinely stretch to an hour and beyond; the longest run thus far lasted two hours of agentic work before returning results.

### Outtake 如何用 Claude 构建复杂的长时运行智能体

> **How Outtake built a complex long-running agent with Claude**

Outtake 大致分四个阶段构建了侦察智能体（Recon Agent）。每个阶段的核心都是先理解一次好的调查应该是什么样子，然后逐步把这种判断力交给智能体。

> Outtake built the Recon Agent in roughly four stages. Each stage was about understanding what a good investigation looked like, then progressively handing that judgment to the agent.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a60e7ad9916514322ed5ac4_3f776183.png)

#### 第一步：先成为专家。

> **Step 1: Become the expert first.**

在构建智能体的任何部分之前，Outtake 的工程师们亲自开展了真实的网络调查，并从客户和设计合作伙伴那里汲取领域专业知识。

> Before building any part of the agent, Outtake's engineers ran real cyber investigations themselves and pulled domain expertise from customers and design partners. 

目标是定义什么样才算“好”。对这类调查而言，这意味着识别哪些证据重要、如何组织这些证据，以及是什么把一个可执行的结论与一个猜测区分开来。这个标准成为他们在此后每个阶段都会回归的固定参照点。

> The goal was to define what "good" looks like. For these types of investigations, that meant identifying what evidence matters, how to organize it, and what separated an actionable conclusion from a guess. That standard became the fixed reference point they returned to at every later stage. 

“构建长时运行智能体最重要的一点，是你真的必须理解：好是什么样的？智能体应该做什么？”Outtake 智能体平台的工程负责人 Jack Hayford 说。“因为归根结底，你要确保智能体每一次都能做到这一点。”

> “The most important thing about building long running agents is that you really have to understand *what does good look like?* *What is the agent supposed to be doing?*” said Jack Hayford, engineering lead for Outtake's agent platform. “Because ultimately you're ensuring that the agent can do that every single time.”

#### 第二步：在 Claude Code 中做原型

> **Step 2: Prototype in Claude Code**

最初，Outtake 团队使用传统的智能体框架，逐步把他们正在标准化的调查流程自动化。

> Initially, the Outtake team used traditional agent frameworks to progressively automate the investigations they were standardizing. 

然而他们很快意识到，侦察智能体不能只是一个简单的调查者。它需要编写、运行代码，随手构建工具，并真正与恶意域名交互。

> They quickly realized, however, that the Recon Agent couldn't just be a simple investigator. It needed to write, run code, build tools on the fly, and actually interact with malicious domains. 

“每一次调查都不一样，而且技术性很强，”Hayford 说。“这个智能体需要编码的肌肉和能力，而 Claude Code 是我们用来真正验证这些假设、并开始越来越多地实验的一个有力的初始载体（harness）。”正是通过在 Claude Code 中做原型，他们锻造出了核心设计原则：在编排层面对智能体进行严格约束（“调查一个域名时，始终做 X、Y、Z”），但只要需要判断力，就让它自由发挥。

> “Every investigation is different, and deeply technical,” Hayford said. “The agent needed coding muscle and capability, and Claude Code was a strong initial harness for us to actually validate those assumptions and start experimenting more and more.” $  
> /$$  
> /$It was by prototyping in Claude Code that they forged their core design principle: constrain the agent tightly at the orchestration level (*‘always do X, Y, Z when investigating a domain’*), but leave  it free to improvise whenever judgement was required.

#### 第三步：升级到生产级的载体

> **Step 3: Graduate to a production-grade harness**

“我们非常喜欢 Claude Code 引入的这些模式，但我们需要额外访问那些更底层的原语，而这些原语我们并不想自己去构建，”Hayford 说。

> “We really liked the patterns that Claude Code had introduced, but we needed additional access to the lower level primitives, which we weren't trying to build ourselves,” Hayford said.

使用 Claude [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) 是把侦察智能体推向生产环境的自然下一步。把 Claude Code 中的技能和模式沿用过来，确保团队在获得对侦察智能体的记忆、上下文和文件系统更严密控制的同时，不会损失任何速度，也无需在智能体循环和会话处理方面重新造轮子。

> Using the Claude [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) was a natural next step for taking the Recon Agent into production. Carrying over skills and patterns from Claude Code ensured that the team didn't drop any velocity while they gained tighter control over the Recon Agent’s memory, context, and file system without reinventing the wheel in terms of the agent loop and handling sessions.

#### 第四步：构建由评估（eval）驱动的紧密迭代循环。

> **Step 4: Build a tight iteration loop driven by evals. **

在网络安全领域，能够低成本、快速响应地迭代尤为关键，因为攻击者一旦得知某个防御工具存在就会立刻做出调整。团队从一开始就集成了智能体评估，并形成了一套强大的评估套件，可以一次运行多个场景。这让他们能够安全、有信心地做出大刀阔斧的改动，比如模型升级和整套记忆系统的重构。

> The ability to iterate inexpensively and responsively is particularly crucial in cybersecurity, where attackers adapt the moment they learn a defensive tool exists. The team integrated agent evals from the very beginning, and arrived at a strong eval suite that runs many scenarios at once. This let them make sweeping changes, like model upgrades and full memory-system refactors, safely and with confidence. 

它还让团队得以把自己从智能体循环中抽离出来。举例来说，当侦察智能体完成一次调查后反馈说，如果当时有某个它没有的工具，本可以做得更好时，另一个独立的编码智能体就会读取这些建议，编写出新工具，并构建一个测试场景来试用它。

> It also let the team pull themselves out of the agentic loop. When, for example, the Recon Agent finishes an investigation and reports back that it could have done better with some tool it didn't have, a separate coding agent then reads those suggestions, writes the new tool, and builds a test scenario to try it out. 

只有在最后一步，才会有人介入查看结果：智能体用了那个工具后，调查是否做得更好了？“我们才是瓶颈，而当你构建这些长而复杂的智能体时，反馈循环实现自动化非常重要。它快得多，作为开发者也令人满意得多，”Hayford 说。

> Only at the very end does a human step in to look at the result: did the agent do the investigation better with that tool, or not? “We are the bottleneck, and when you build these long, complex agents, it's very important that the feedback loop be automated. It's a lot faster and it's also a lot more satisfying as a developer,” said Hayford.

### 构建长时运行智能体的经验教训

> **Learnings from building a long-running agent**

在智能体（agent）发展的早期，构建者会预先用硬编码、确定性的分步路径来编排智能体的行为，以防它偏离轨道。如今，这些繁复的工作流正被一种"支撑框架"（harness）所取代：一个由记忆、工具、技能和护栏构成的支持性环境。

> In the early days of agents, builders scripted agent behavior in advance with hardcoded, deterministic, step-by-step paths to keep it from going off the rails. Now, elaborate workflows are being replaced by a harness: a supportive environment of memory, tools, skills, and guardrails.

以下是 Outtake 团队在实现 Recon Agents 构建过程中的一些心得。

> Here are some takeaways from the Outtake team’s experience in implementing the Recon Agents build.

#### 工具：一个文件系统加上 bash 就够了

> **Tools: a filesystem and bash is all you need**

文件系统能提供在上下文压缩（compaction）后依然留存的记忆。人们通常会给智能体配备非常具体而精细的工具，但给智能体一个文件系统，加上编写、读取和运行代码的能力，能帮助它应对障碍。

> Filesystem enables memory that survives compaction. Agents are typically given very specific and nuanced tools, but giving an agent a filesystem along with the ability to write, read, and run code helps the agent respond to obstacles. 

"把这些极其强大的开放式工具和能力交给智能体，是一次巨大的阶跃式变化。我们观察到很多情况：某个工具因为网络抖动之类的原因失败了，而智能体会自己找到正确的变通办法并继续下去，"Hayford 说。"因为我们构建的整个支撑框架足够稳固，也因为它给智能体留出了用这些强大开放式工具即兴发挥的空间，它依然能够达成成功的结果。"

> “Handing those extremely powerful open-ended tools and capabilities to an agent is a huge step change. We’ve observed plenty of cases where an agent had a tool that was failing due to a network hiccup or whatever, and it would just find the right workaround and continue,” said Hayford. “Because the rest of the harness that we had built was strong enough, and because it left the agent with opportunity for improvisation with these powerful, open-ended tools, it was still able to get to a successful outcome.”

#### 提示词只是建议

> **Prompts are suggestions**

提示词在需要时提供灵活性，但尽可能硬编码则能确保稳定性。"当你构建这些随时间推移变得复杂的长时运行智能体时，提示词只是建议，"Hayford 说。"当智能体没做你想要的事时，很自然的反应是去修改智能体中最容易改动的那部分。把'当 X 发生时，一定要做 Y'塞进系统提示词，起初可能有效，但随着这个智能体运行时间变长，那段提示词里的每一个字最终大概都会被忽略。" 正确的做法是围绕这种可能性来构建：识别出智能体每一次都应该做的事，并把它变成智能体护栏的一部分。"把这些东西从提示词里抽出来，放进支撑框架，"他说。"这样智能体就不必再去想它了，也就有更多的上下文空间和注意力可以投向真正能发挥作用的领域。"

> Prompts provide flexibility when needed, but hardcoding where possible ensures stability. “When you're building these long-running agents that get complicated over time, prompts are suggestions,” Hayford said. “When an agent didn't do what you wanted, the natural response is to add to the most plastic part of the agent. Slipping ‘when X happens, make sure you do Y’ into the system prompt may work initially, but as this agent runs longer, every single word in that prompt will probably be ignored eventually.” $  
> /$$  
> /$The correct approach is to build around that likelihood by identifying what the agent should always do every time and making it part of the agent guardrails. “Pull these things out of the prompt and put them into the harness,” he said. “Now the agent doesn't have to think about it anymore and it has more context space and attention to put towards areas where it can really thrive.” 

延伸阅读[引导 Claude 的最佳实践](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)，以及每种方法的上下文成本和权威性。

> *Read more on *[best practices for directing Claude](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)*, and the context cost and authority of each method. *

#### 评测（eval）是为了速度，而不只是可靠性

> **Evals are for speed, not just reliability**

把手动的"复盘"当作通往自动化评测的路线图，从而缩短开发周期。传统观点认为评测是保证可靠性的质量关卡。但对长时运行智能体而言，更大的回报在于速度。

> Use manual “reflections” as a roadmap to automated evals that tighten dev cycles.** **The conventional view is that evals are a quality gate for reliability. For long-running agents, though, the bigger payoff is speed. 

早期，Recon Agent 每次运行后，团队都会手动审查它的表现。但通读智能体 30 分钟内所做一切的完整记录既痛苦又无法规模化。

> Early on, every time the Recon Agent ran, the team did a manual review of its performance. But reading an agent’s 30-minute transcript of everything it did is brutal and doesn't scale. 

"在现代智能体开发中，评估输出是整个循环里成本最高的一步，"Jack 说。

> “In modern agent development, evaluating the output is the most expensive step in the loop,” Jack said. 

评测其实就是那种复盘的结构化、可打分、可自动化的版本。一旦你把"好的表现应该是什么样"编码成一个可重复的检查，你就可以让一个智能体坐上裁判席，去读那 30 分钟的记录并为这次运行打分。

> An eval is just a structured, graded, automatable version of that reflection. Once you've codified what good looks like into a repeatable check, you can put an agent in the judge's seat to read the 30-minute transcript and score the run.

"我觉得有些工程师对构建评测心存顾虑，因为那就像是要打造一个完美的用例，"Jack 说。"无论评测多么正式或多么'完美'，从一开始就构建某种版本的评测，都会让你更快地把那个智能体建好。"

> “I think that some engineers feel apprehensive about building evals because it's like this idea of building a perfect case,” Jack said. “Building some version of evals from the very beginning will make you build that agent faster regardless of how official or ‘perfect' they are.”

#### 保护你的智能体

> **Protecting your agents**

[提示词注入](https://www.anthropic.com/research/prompt-injection-defenses)是一个真实的威胁，因此把你的智能体放进沙箱或给它套上护甲至关重要。Outtake 团队选择 Claude，部分原因就在于它抵御提示词注入的能力。

> [Prompt injection](https://www.anthropic.com/research/prompt-injection-defenses) is a real threat, so putting your agent in a sandbox or giving it armor is essential. The Outtake team chose Claude in part because of its strength against prompt injection. 

"安全是我们构建 Recon Agent 时非常重要的一点，"Hayford 说。"我们给了它文件系统和 bash，还把它送进充满对抗性的环境，所以我们要解决的最重要的问题，是构建一种'爆炸箱'（blastbox）——你可以尝试把智能体与敏感的内部信息隔离开，同时又不真正妨碍它的工作。"

> “Security is a big note for us for building the Recon Agent,” Hayford said. “We gave it a file system and bash and we're sending it to adversarial environments, so the most important problem we had to solve was building a sort of blastbox where you could try to hide your agent from sensitive internals without actually hindering it.” 

他们的做法假设智能体可能被劫持，因此外围系统被设计成能够控制损害范围。不过，安全在不同智能体之间样貌各异，取决于它们的用途，并非所有智能体都适合采用爆炸箱方案。

> Their approach assumes the agent might get hijacked, so the surrounding system is engineered to contain the damage. Security looks different from agent to agent, however, depending on their purpose, and not all agents are blastbox candidates. 

Outtake 现在会在智能体接触互联网的那一刻精确地评估信任级别，设置一个检查点来评估智能体即将接触的任何东西：'这个页面是不是仿冒的？是不是恶意软件？它是不是正试图对智能体进行提示词注入？'随着智能体穿行于日益充满对抗性的互联网，这也许正是它们所需要的护甲。

> Outtake is now scoring the level of trust at the exact point where the agent reaches out to the internet, implementing a checkpoint that evaluates whatever the agent is about to touch: ‘Is this page an impersonation? Is it malware? Is it trying to prompt-inject the agent right now?’ This may be exactly the armor that agents need as they traverse an increasingly adversarial internet.

### 接下来

> **What's next**

侦察智能体（Recon Agent）已经上线，如今正在执行调查任务。如果你想深入了解 Outtake 如何使用 Claude 大规模地绘制敌方基础设施：

> Recon Agent is live and running investigations today. If you want to go deeper on how Outtake uses Claude to map adversarial infrastructure at scale:

- [观看完整网络研讨会](https://www.anthropic.com/webinars/outtake-built-cyber-investigator-claude)，其中包含现场演示，并更深入地讨论了 Outtake 如何使用 Claude 自主调查并大规模绘制威胁基础设施。
- [观看侦察智能体的实战演示](https://www.outtake.ai/solutions/recon-agent)。了解该智能体如何从单个仿冒行为出发，构建出完整的威胁行为者画像。
- [获取免费的侦察智能体评估](https://www.outtake.ai/recon-agent-assessment)，看看一次调查能揭示你自身暴露面的哪些情况。

> • [View the full webinar](https://www.anthropic.com/webinars/outtake-built-cyber-investigator-claude)* for a live demo and deeper discussion of how Outtake uses Claude to autonomously investigate and map threat infrastructure at scale.*
> • [See Recon Agent in action](https://www.outtake.ai/solutions/recon-agent)*. Explore how the agent moves from a single impersonation to a full threat actor profile.*
> • [Get a free Recon Agent assessment](https://www.outtake.ai/recon-agent-assessment)* to see what an investigation surfaces on your own exposure.*
