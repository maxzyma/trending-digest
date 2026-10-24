# Claude Duet 的安全性、隐私与安全防护

> Claude Duet Safety, Privacy, and Security

> 来源：Claude Blog / Anthropic，2026-10-23
> 原文链接：https://claude.com/resources/articles/claude-duet-safety-privacy-and-security
> 分类：AI 智能体 / 安全与隐私

## 核心要点

- Claude Duet 基于三项原则构建：审慎处理用户及他人在已连接应用中分享的信息、由用户掌控其代为执行的操作，以及智能体永远不接触密码、Cookie、登录令牌等凭据。
- 在发送可能敏感的消息、付款或删除内容等操作前，Claude Duet 会展示操作、目标和内容并等待用户批准，同时由独立于执行模型、基于 Claude Code 自动模式分类器扩展的检查同步评估操作是否符合用户意图。
- 证券交易、账户间转账和访问他人账户等操作即使获批也被禁止，付款、删除订单和创建账户等步骤不适用“不再询问我”规则，且团队持续校准请求批准的频率以避免审批疲劳。
- 购物时 Claude Duet 使用 Stripe 旗下 Link 等钱包生成的限定商家和金额的一次性卡付款，用户的真实卡号不会透露给智能体或商家。
- 一个独立于主模型的新安全分类器会检查每条待发送消息，将登录凭据、完整银行卡号与账号、政府证件号码列为绝不共享信息，将健康、财务等私人信息列为需经用户同意才能分享的信息。
- 用户可在任务列表中查看并引导任务，对话历史和记忆会保留到用户删除或重置为止，断开应用只会停止新的访问而不会清除已获取的记忆。
- 密码通过一次性密钥加密的应用内表单直接传给云端浏览器，登录令牌由智能体机器外的代理在请求时填入，浏览器运行在独立虚拟机中且智能体只能通过固定命令操控它。
- 登录表单只会在用户主动发起的应用内登录过程中出现，任何在其他地方冒充 Claude Duet 索要密码的行为都不是正规的。
- Claude Duet 通过独特的 User-Agent 请求头和公开的公网 IP 地址表明智能体身份，并在发布前允许部分大型网站选择阻止其访问。
- 测试工作包括 Safeguards 团队的三变体评估与影子流量、红队测试、全系统威胁建模、外部渗透测试以及纳入 HackerOne 公开漏洞赏金计划。

## 正文

[Claude Duet（在新标签页中打开）](https://claude.com/resources/articles/claude-duet)是一款目前处于研究预览阶段的智能体，它使用基于云端的计算机替你完成工作。它可以使用你选择连接到 Claude 的所有应用和服务，即使你关闭应用后也会持续运行。在你离开时，它可以阅读你的收件箱、起草回复、进行预订，并执行例行任务。我们的团队在自己的账户上运行 Claude Duet，每天都用它来工作。

> [Claude Duet (opens in new tab)](https://claude.com/resources/articles/claude-duet) is an agent, currently in research preview, that uses a cloud-based computer to do work for you. It can use all the apps and services you've chosen to connect to Claude, and it runs continuously even after you close the app. It can read your inbox, draft replies, book things, and run routines while you are away. Our team runs Claude Duet on our own accounts and we use it for work every day.

我们基于三项原则构建了 Claude Duet，用以指导智能体的行为：

> We built Claude Duet on three principles to guide the agent's behavior:

1. 你的信息，以及其他人在你已连接的应用中分享的内容，都会被审慎处理：Claude Duet 起草的消息在发出之前，会先经过一个新的分类器检查。
2. 它代表你执行的操作，始终由你掌控。
3. Claude Duet 永远不会看到你的密码、浏览器 Cookie、登录令牌或其他凭据。

> 1\. Your information, and what other people share in your connected apps, is handled with discretion, using a new classifier that checks messages Claude Duet drafts before they go out.
> 2\. You stay in control of what it does on your behalf.
> 3\. Claude Duet never sees your passwords, browser cookies, sign-in tokens, or other credentials.

Claude Duet 是一款新产品，但其背后的理念并不新。2025 年，我们[发布了安全可信智能体框架（在新标签页中打开）](https://www.anthropic.com/news/our-framework-for-developing-safe-and-trustworthy-agents)，该框架让人保持掌控，并将隐私和安全交互视为基本要求。此后，我们撰文阐述了为什么[没有任何单一防御措施是足够的（在新标签页中打开）](https://www.anthropic.com/research/trustworthy-agents)，以及为什么[模型内部的防护不能单独发挥作用（在新标签页中打开）](https://www.anthropic.com/engineering/how-we-contain-claude)。我们还通过 [Claude Managed Agents（在新标签页中打开）](https://www.anthropic.com/engineering/managed-agents)构建并运营企业在生产环境中运行智能体所用的基础设施，而 Claude Duet 也以同样的方式将凭据与智能体隔离开来。它以这些工作为基础，增加了代表你行事的智能体所需的各项防护。本文将介绍我们新增了哪些内容，以及我们仍在推进的工作。

> Claude Duet is new but the thinking behind it is not. In 2025 we [published our framework for safe and trustworthy agents (opens in new tab)](https://www.anthropic.com/news/our-framework-for-developing-safe-and-trustworthy-agents), which puts people in control and treats privacy and secure interactions as basic requirements. Since then, we have written about why [no single defense is enough (opens in new tab)](https://www.anthropic.com/research/trustworthy-agents) and why [protection inside the model can’t stand alone (opens in new tab)](https://www.anthropic.com/engineering/how-we-contain-claude). We also build and operate the infrastructure businesses use to run agents in production through [Claude Managed Agents (opens in new tab)](https://www.anthropic.com/engineering/managed-agents), and Claude Duet keeps credentials separate from the agent in the same way. It builds on this work, adding the protections that an agent acting for you needs. This post walks through what we added and what we’re still working on.

#### 重要操作由你来批准

> You approve important actions

一个在你离开时自主行动的智能体，必须知道何时停下来、在继续之前征求许可，并且要以恰当的频率这样做。在 Claude Duet 执行诸如发送可能敏感的消息、付款或删除任何内容等操作之前，它会向你展示该操作、目标以及内容，包括每一位收件人。然后，它会等待你批准该操作。

> An agent that acts while you’re away has to know when to stop and ask for permission before proceeding, and to do it at the right cadence. Before Claude Duet does something like sending a potentially sensitive message, paying for something, or deleting anything, it shows you the action, the destination, and the content, including every recipient. It then waits for you to approve the action.

每个操作执行时，都会同步运行一项独立的自动化检查。该检查基于[Claude Code 的自动模式分类器（在新标签页中打开）](https://www.anthropic.com/engineering/claude-code-auto-mode)构建，并针对 Claude Duet 做了扩展，用于评估该操作是否符合你的意图。这项检查在执行任务的模型之外运行，因此页面中隐藏的指令无法影响其结果。

> A separate, automated check runs alongside each action, built on [the auto mode classifier from Claude Code (opens in new tab)](https://www.anthropic.com/engineering/claude-code-auto-mode) and extended for Claude Duet. It assesses whether the action matches your intent. The check runs outside the model doing the work so instructions hidden in a page cannot affect the outcome.

有些操作即使获得你的批准也仍然禁止执行，例如证券交易、在账户之间转账等银行操作，以及访问他人的账户。还有一些步骤不适用“不再询问我”规则，无论你此前批准过多少次，例如付款或汇款、删除订单或创建账户。在你离开期间运行的例行任务也具有相同的保护措施。

> Some actions stay off-limits even with your approval, like trading securities, banking actions such as moving money between accounts, and accessing someone else's account. Some other steps aren’t covered by a "don't ask me again" rule, however often you have approved them, like paying or sending money, deleting an order, or creating an account. The routines that run while you are away have the same safeguards.

我们花了大量时间来校准 Claude Duet 请求批准的频率。审批疲劳是一个严重的问题，因为过多的请求会让人们养成随手点过的习惯，有时甚至没有经过充分的考虑。我们将随着时间推移继续调整这一校准。

> We spent a lot of time calibrating how often Claude Duet asks for approval. Approval fatigue is a serious issue, because too many requests teach people to tap through them, sometimes without adequate consideration. We will continue to adjust this calibration over time.

在购物时，Claude Duet 会使用来自 Stripe 旗下 Link 等钱包的一次性卡进行支付，该卡仅限于对应商家和金额。你可以看到商品和总价，并在你的 Link 应用中批准这笔购买。你的真实卡号不会透露给 Claude Duet 或商家。

> For purchases, Claude Duet pays with a one-time card from a wallet like Link from Stripe, limited to that merchant and amount. You see the item and the total, and you approve the purchase in your Link app. Your real card number isn’t shared with Claude Duet or the merchant.

![a graphic showing the approval flow for Claude Duet](https://assets.claude.com/45eff23b993c919b077fb5c7f366c78bcfb7c06d.png)

#### 您的信息将被审慎处理

> Your information is handled with discretion

一个替你阅读邮件、代你发送消息的智能体，时时刻刻都在判断不同类型的信息应该流向何处。如果你让 Claude Duet 给团队发送一份每周回顾，它应当只包含团队每个人本来就能访问的内容，而绝不能包含私密细节，比如你的绩效评估谈话。

> An agent that reads your email and sends messages for you is constantly deciding where different types of information should go. If you ask Claude Duet to send your team a weekly recap, it should include only things everyone on the team already has access to and never private details, like your performance review conversations.

为此，我们构建了一个新的安全分类器，它独立于主模型运行，负责检查 Claude Duet 即将发送的每条消息是否包含潜在的敏感信息。我们将这类信息分为两个层级：

> To address this, we built a new safety classifier that runs separately from the main model and checks whether each message Claude Duet is about to send contains potentially sensitive information. We categorize this information into two tiers:

- **绝不共享：**对于登录凭据、完整的银行卡号和银行账号以及政府身份证件号码等信息，我们给予最高级别的保护。Claude Duet 被设定为绝不与任何人共享这些信息，即使是你本人提出要求也不例外。
- **需要同意才能分享：**只有在你明确批准的情况下，Claude Duet 才会分享其他私人信息，例如健康或财务信息。你自己提出的请求即视为同意，因此像“给我的牙医发一条消息，说说我牙疼的情况”这样的请求，通常不需要额外批准。

> • **Never share: **We give the most sensitive protection to information like sign-in credentials, full card and bank account numbers, and government ID numbers. Claude Duet is instructed never to share these with anyone, even if you ask.
> • **Needs consent to share: **Claude Duet will share other private information, such as health or finances, only if you’ve explicitly approved it. Your own request counts as consent, so “send a note to my dentist about my tooth pain” generally won’t need additional approval.

![A graphic that shows where your information can go with Claude Duet](https://assets.claude.com/6cf6546eabf0f7bdccd66fa93e407941f9e50947.png)

如果 Claude Duet 因上述任一原因被阻止，它可以决定在去除敏感信息后重写该消息，并交给你审批。

> If Claude Duet is blocked for either reason, it can decide to rewrite the message without the sensitive information and share with you for approval.

Claude Duet 仍处于研究预览阶段，这些安全防护措施偶尔会遗漏某些内容，或将无害的消息误判为问题。正因如此，它们需要与上文所述的审批机制协同运作，这些机制旨在让你始终掌控 Claude Duet 代表你发送的内容。随着我们进一步了解人们如何使用 Claude Duet，我们预计将持续迭代我们的分类器。

> Claude Duet is still in research preview and these safeguards will occasionally miss something or flag a harmless message. That’s why they work alongside the approval mechanisms above, which are designed to keep you in control of what Claude Duet sends on your behalf. We expect to continue iterating on our classifier as we learn more about how people use Claude Duet.

#### 你可以查看任务和已连接的应用

> You have visibility into tasks and connected apps

你可以在任务列表中查看 Claude Duet 已完成和正在进行的工作，每个任务都有独立的页面，你还可以在任务进行中对其加以引导。Claude Duet 会保留你的对话历史和它的记忆，以便在不同任务之间延续上下文，直到你删除历史记录或将其重置为止。删除你的账户将清除 Claude Duet 存储的所有内容。

> You can see what Claude Duet has done and is doing in its task list, where each task has its own page, and steer it mid-task. Claude Duet keeps your conversation history and its memory so it can carry context between tasks, until you delete your history or reset it. Deleting your account wipes everything Claude Duet has stored.

![A screengrab of what a Claude Duet task list looks like](https://assets.claude.com/2ea9a7ae6dfe5a96c7e3e0fb759df5a0703704b1.png)

你已连接到 Claude 的应用会同步到 Claude Duet，在一处关闭某个应用，两处都会随之关闭。断开某个应用后，从那一刻起将停止新的访问，但 Claude Duet 已从中了解到的内容会一直保留，直到你重置其记忆；你可以随时在应用设置中进行重置。Claude Duet 还会使用你 Claude 账户中的记忆，因此 Claude 从你之前的聊天中记住的细节也会显示出来。

> The apps you have connected to Claude carry over to Claude Duet, and switching an app off in one place switches it off in both. Disconnecting an app stops new access from that moment, but what Claude Duet already learned from it stays until you reset its memory, which you can do anytime from the app’s settings. Claude Duet also uses the memory from your Claude account, so details Claude remembered from your earlier chats are visible.

#### 凭据和浏览器与模型相互隔离

> Credentials and the browser are isolated from the model

Claude Duet 永远看不到你的密码、浏览器 Cookie 或已连接应用的登录令牌，也无法将它们保存到自己的记忆中。这些信息只会经过模型无法访问的独立机器，而约束其行为的审批和安全检查也同样在那里运行。

> Claude Duet never sees your passwords, browser cookies, or the sign-in tokens for your connected apps, and it can’t save them to its memory. They only ever pass through separate machines the model can’t access, and the approvals and safety checks that govern what it does run there too.

**密码**

> **Passwords**

当网站要求输入密码时，你会在 Claude 应用内的一个表单中输入密码。该表单使用一个一次性密钥对密码进行加密，这个密钥只存在于我们安全的云端浏览器机器上，且仅供这一次使用。表单将加密后的密码原封不动地传给浏览器，再由浏览器将其输入到网站中。模型看不到密码，也无法保存或复述密码。很快，你还将能够使用 1Password 登录：Claude Duet 会请求凭据，你在 1Password 中批准该请求后，凭据将直接发送到浏览器，而不会经过模型。

> When a site asks for a password, you type it into a form inside the Claude app. The form encrypts it with a single-use key that exists only on our secure cloud browser machine, for that one single use. It passes the encrypted password unopened to the browser, which types it into the site. The model doesn’t see the password and can’t save or repeat it. Soon you will also be able to sign in with 1Password; Claude Duet will ask for a credential, you will approve that request in 1Password, and the credential will go to the browser without passing through the model.

代你登录的智能体会从两个方面改变网络钓鱼的形态。一方面，Claude Duet 不替你保管凭据，因此无法被钓取密码，任何隐藏指令也无法让它泄露它根本不掌握的机密。另一方面，登录表单本身就是攻击目标，因为任何索要密码的东西都可能被仿冒。因此，Claude Duet 的登录表单只会在应用内、在你主动发起的登录过程中出现。它绝不会以链接、短信、电子邮件或 claude.ai 以外网站的形式出现。如果任何看起来像 Claude Duet 的东西在其他地方向你索要密码，那都不是正规的。

> An agent that signs in for you changes phishing in two ways. On one hand, Claude Duet doesn’t hold credentials for you so it can’t be phished for a password, and no hidden instruction can make it reveal a secret it doesn’t have. On the other hand, the sign-in form is itself a target, because anything that asks for a password can be imitated. So Claude Duet’s sign-in form only appears inside the app, during a sign-in you asked for. It never arrives as a link, a text message, an email, or a website other than claude.ai. If something that looks like Claude Duet asks for your password anywhere else, it’s not legitimate.

**登录令牌**

> **Sign-in tokens**

当 Claude Duet 在已连接的应用中工作时，它遵循[我们的 Claude Managed Agents 设计（在新标签页中打开）](https://www.anthropic.com/engineering/managed-agents)，使凭据始终处于智能体工作范围之外。智能体代表你使用的凭据（例如已连接服务的登录令牌）永远不会进入智能体工作所在的机器。该机器上只放置凭据的占位符，而位于该机器之外的代理仅在发出请求时才填入真实值。

> When Claude Duet works in a connected app, it follows [our Claude Managed Agents design (opens in new tab)](https://www.anthropic.com/engineering/managed-agents) so credentials stay out of reach of the agent’s work. Credentials that the agent uses on your behalf, such as a sign-in token for a connected service, never enter the machine where the agent works. A placeholder for the credential sits there instead and a proxy outside that machine puts in the real value only as a request is made.

**浏览器**

> **The browser**

Claude Duet 中的浏览器运行在云端一台专属的虚拟机中，与模型以及智能体所操作的云端计算机相互隔离。智能体只能通过一组固定的命令来操控浏览器：*打开这个页面、点击这里、输入这些内容*。网站运行的任何内容都[只停留在浏览器所在的机器上（在新标签页中打开）](https://www.anthropic.com/engineering/managed-agents)。网站的代码和 Cookie 不会进入 Claude Duet 的记忆或你已连接的应用，智能体的任何命令也都无法从浏览器中读取 Cookie。真正会传回来的是页面文本和下载内容，因为智能体必须读取它们才能完成工作。这正是设置其他检查的原因，也是 Claude Duet 同时采用我们在[浏览器使用研究（在新标签页中打开）](https://www.anthropic.com/research/prompt-injection-defenses)中所述的提示注入防护措施的原因。它通过浏览器上传的文件，会和它发送的消息一样，接受相同的敏感信息检查。

> Your browser in Claude Duet runs in its own dedicated virtual machine in the cloud, separate from the model and from the cloud computers the agent works on. The agent drives the browser only through a fixed set of commands: *open this page, click here, type this*. Whatever a site runs [stays on the browser machine (opens in new tab)](https://www.anthropic.com/engineering/managed-agents). The site’s code and cookies don’t reach Claude Duet’s memory or your connected apps, and none of the agent’s commands can read cookies out of the browser. What does come back is the page's text and downloads, because the agent has to read them to do its job. That’s why the other checks exist, and why Claude Duet also uses the prompt-injection safeguards described in our [browser-use research (opens in new tab)](https://www.anthropic.com/research/prompt-injection-defenses). Files it uploads through the browser get the same sensitive-information check as its messages.

![a graphic that show what goes on Claude's computer and what stays on yours](https://assets.claude.com/7df447f5c9bcaa1b3424f88f94d623be1383b637.png)

Claude Duet 在设计上也会表明自己的智能体身份。目前，其网页浏览器发出的请求带有一个独特的 User-Agent 请求头，我们还公布了它浏览网页时使用的公网 IP 地址，以便网站能够识别它，并决定如何对待它。在发布之前，我们还联系了几家大型网站，让它们可以选择阻止 Claude Duet 访问其网站，其中一些网站选择了这样做。随着我们从研究预览中不断积累经验，我们将继续改进 Claude Duet 表明自身身份的方式。

> Claude Duet is also designed to identify itself as an agent. Today, requests that its web browser sends include a distinct User-Agent header, and we publish the public IP addresses it browses from, so sites can recognize it and decide how to treat it. Before launch, we also contacted several large websites and gave them the option to prevent Claude Duet from visiting their sites, and some chose to. We’ll keep refining how Claude Duet identifies itself as we learn from the research preview.

![Graphic showing the credential path for passwords](https://assets.claude.com/3073b7d3f85e65f58bd4a7627eb5f5ff9c2af4af.png)

#### 我们如何测试 Claude Duet

> How we tested Claude Duet

测试早在研究预览之前就已开始，并持续至今。我们的 Safeguards 团队以类似日常例行任务的形式构建了评估，每项任务都有三个变体：一个无害版本，一个注入了指令的版本，以及一个诱使智能体做超出要求之事的版本。这些评估与来自真实使用的影子流量同步运行。

> Testing started well before the research preview and continues now. Our Safeguards team built evaluations from routine-shaped tasks, each in three variants: an innocent version, one with injected instructions, and one that tempts the agent to do more than it was asked. Those run alongside shadow traffic from real use.

红队还进一步测试了 Claude Duet 是否会泄露信息、未经批准擅自行动或执行恶意提示。我们针对整个系统构建了威胁模型，覆盖其涉及的各个代码仓库和信任边界。一家外部渗透测试公司在可访问我们源代码的条件下对 Claude Duet 进行了测试，另一项涵盖云端浏览器和登录表单的后续测试目前正在进行中。每项新的凭据功能在向任何人发布之前，都会先在隔离的测试环境中接受红队测试。

> Red teams further tested whether Claude Duet would leak information, act without approval, or follow malicious prompts. We built a threat model of the whole system, across the repositories and trust boundaries it touches. An external penetration-testing firm tested Claude Duet with access to our source code, and a follow-on engagement covering the cloud browser and the sign-in form is running now. Each new credential feature is red-teamed on an isolated rig before it ships to anyone.

Claude Duet 同样属于 Anthropic 公开漏洞赏金计划的范围。根据我们的负责任披露政策，该计划会对有效报告给予奖励，并为善意研究提供安全港保护。如果你发现了安全漏洞，我们希望了解相关情况：请通过 Anthropic 在 [HackerOne（在新标签页中打开）](https://hackerone.com/anthropic)上的漏洞赏金计划进行报告。

> Claude Duet is also in scope of Anthropic’s public bug bounty program, which rewards valid reports and offers safe harbor for good-faith research, under our responsible disclosure policy. If you find a security vulnerability, we want to hear about it: report it through Anthropic’s bug bounty program on [HackerOne (opens in new tab)](https://hackerone.com/anthropic).

#### 与你携手共建

> Building this with you

我们将 Claude Duet 作为研究预览版发布，是因为我们希望了解你在个人智能体中看重什么，包括你希望接下来看到哪些保护措施和控制功能。这里描述的部分内容仍在变化中：它请求批准的频率、你的登录方式，以及敏感信息检查在区分私密内容与无害内容方面的准确程度。用平实的语言告诉 Claude Duet 你希望看到什么或哪里出了问题，它会为我们的团队提交一份报告。

> We’re releasing Claude Duet as a research preview because we want to learn what you value in a personal agent, including the protections and controls you’d like to see next. Some of what’s described here is still changing: how often it asks for approval, how you sign in, and how well the sensitive-information checks tell what’s private from what’s harmless. Tell Claude Duet in plain words what you’d like to see or what went wrong, and it will file a report for our team.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Research Preview | 研究预览 | 产品在正式发布前向用户开放以收集反馈和使用经验的阶段。 |
| Agent | 智能体 | 能够自主规划并代表用户执行多步任务的 AI 系统。 |
| Classifier | 分类器 | 对输入内容进行判别归类的模型，此处用于检查操作意图或敏感信息。 |
| Auto Mode | 自动模式 | Claude Code 中让智能体在分类器把关下自主执行操作的运行模式。 |
| Approval Fatigue | 审批疲劳 | 因审批请求过多导致用户不加思考地随手批准的现象。 |
| Prompt Injection | 提示注入 | 通过在页面或数据中隐藏指令来操纵模型行为的攻击方式。 |
| Credential | 凭据 | 用于身份验证的密码、令牌、Cookie 等机密信息。 |
| Login Token | 登录令牌 | 服务在用户认证后签发、用于后续请求授权的凭证字符串。 |
| Cookie | Cookie | 网站存储在浏览器中、常用于维持登录状态的小段数据。 |
| Proxy | 代理 | 位于智能体机器之外、在发出请求时填入真实凭据的中间服务。 |
| Virtual Machine | 虚拟机 | 在物理主机上隔离运行的独立计算环境。 |
| User-Agent | User-Agent 请求头 | HTTP 请求中标识发起客户端身份的头部字段。 |
| Red Teaming | 红队测试 | 模拟攻击者对系统进行对抗性测试以发现安全弱点的做法。 |
| Shadow Traffic | 影子流量 | 将真实使用流量复制到测试系统中以评估行为而不影响用户的手段。 |
| Bug Bounty | 漏洞赏金计划 | 对外部研究者提交的有效安全漏洞报告给予奖励的计划。 |
