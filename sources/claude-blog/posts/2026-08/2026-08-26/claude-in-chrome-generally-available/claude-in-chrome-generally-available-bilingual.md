# Claude in Chrome 现已全面开放使用

> Claude in Chrome is generally available

> 来源：Claude Blog / Anthropic，2026-08-26
> 原文链接：https://claude.com/blog/claude-in-chrome-generally-available
> 分类：AI 智能体 / 浏览器安全

## 核心要点

- Claude in Chrome 已在所有付费 Claude 套餐中全面开放，不再限于试点范围。
- Claude 现在可以在浏览器中自主执行操作，不需要用户为每一项操作单独授予批准。
- Claude in Chrome 可以查看用户当前所在页面，并复用已有登录状态完成读写文本、点击链接、页面导航和填写表单等操作。
- 该扩展的定位是让 Claude 触达无法通过连接器接入的工具，例如内部仪表板、遗留系统和供应商门户。
- 提示注入指隐藏在网站、邮件或文档中的恶意指令，可诱骗智能体执行用户未曾要求的行为，例如把用户邮件转发给攻击者。
- Anthropic 使用一个持续扩充的提示注入攻击库训练模型，攻击来源包括内部自动化攻击程序、外部红队人员和真实世界监控，新成功的攻击会被纳入库中用于后续训练。
- 探针会在模型对工具结果中的网页内容采取行动前进行扫描，检测到可疑内容时会提示 Claude 保持怀疑并在必要时先与用户确认。
- 分类器会将 Claude 即将执行的操作与用户最初的请求进行比对，不相符的操作会被阻止，该自动批准机制与 Claude Code 的自动模式相同，用户可在设置中关闭。
- 在使用专业红队攻击的当前评估中，无防护条件下攻击对 Opus 4.5 的成功率为 17.6%，对 Opus 5 为 3.8%；在探针与安全分类器同时运行时，Sonnet 5、Opus 5 与 Mythos 5 均无攻击成功，Fable 5 的成功率为 0.3%。
- 原有的 Cowork 提示注入评估因成功率降至 0% 而被判定饱和并退役。
- 企业版管理员可在组织设置中管理该扩展并将其限制在已批准域名范围内。
- 处理本地文件或与其他应用协同仍需使用 Claude 桌面版应用，该扩展暂不支持其他 Chromium 浏览器和移动端。

## 正文

Claude in Chrome 现已在所有付费 Claude 套餐中全面开放。Claude 现在还可以在浏览器中自主执行操作，而无需为每一项操作单独获得批准。在每个操作执行前，会有一个安全分类器对其进行校验，以确保该操作是安全的并且符合你的请求。

> Claude in Chrome is now generally available on every paid Claude plan. Claude can now also take actions autonomously in the browser, instead of needing approval for every one. A safety classifier validates each action before it’s performed to ensure it’s safe and matches your request.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8e8c30f077b615a7429ea1_a9d1d161.png)

你每天使用的许多工具都[可以连接到 Claude](http://claude.com/connectors)。但还有很多工具做不到，比如内部仪表板、遗留系统和供应商门户。Claude in Chrome 让 Claude 能够访问这些工具。它可以查看你当前所在的页面，并使用你已有的登录状态执行各种操作，例如读取和输入文本、点击链接、在页面之间导航以及填写表单。

> Many of the tools you use every day [connect to Claude](http://claude.com/connectors). But many others don’t, such as internal dashboards, legacy systems, and vendor portals. Claude in Chrome lets Claude access those. It can view the page you’re on and take actions like reading and typing text, clicking links, navigating between pages, and filling out forms, using your existing logins. 

我们去年首次以试点形式发布了 Claude in Chrome，以便在测试它的同时加强我们针对[提示注入](https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks)的防御：提示注入是指隐藏在网站、邮件或文档中的恶意指令，它们试图诱骗 AI 智能体做出违背用户意愿的行为。下文所述的这些防御措施，让我们有信心将 Claude in Chrome 全面开放使用。

> We first announced Claude in Chrome as a pilot last year, so we could test it while also shoring up our defenses against [prompt injection](https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks): malicious instructions hidden in websites, emails, or documents that try to trick an AI agent into acting against the user’s wishes. These defenses, described below, give us the confidence to make Claude in Chrome generally available.

#### 防范提示词注入

> Safeguarding against prompt injection

正如我们在宣布这项试点时[所概述的](https://claude.com/blog/claude-for-chrome)，在你的浏览器中工作的 AI 智能体同样容易受到提示注入攻击。因此，在更大范围地发布 Claude in Chrome 之前，我们一直在努力改进我们的防护措施。

> As [we outlined](https://claude.com/blog/claude-for-chrome) when we announced the pilot, an AI agent that works in your browser is also vulnerable to prompt injection. So we’ve worked to improve our safeguards before releasing Claude in Chrome more widely. 

在提示注入攻击中，恶意行为者会将指令隐藏在网页、电子邮件或表单字段等网络内容中。你可能永远不会看到这些指令，但它们可以让智能体去执行你从未要求过的操作。例如，如果你让 Claude 起草电子邮件回复，某封邮件中隐藏的指令可能会告诉 Claude 把你的其他邮件转发给攻击者。

> In a prompt injection attack, malicious actors hide instructions in web content such as a web page, an email, or a form field. You may never see them, but these instructions can redirect the agent to do something you never asked for. For example, if you’ve asked Claude to draft replies to your emails, a hidden instruction in one message could tell Claude to forward your other emails to the attacker instead.

在发布时，我们介绍了如何测试 Claude 抵御这些攻击的能力以及当时已部署的防护措施；后来我们发布了一份更详细的[浏览器使用防护措施](https://www.anthropic.com/research/prompt-injection-defenses)说明。此后，我们改进了模型和[探针](https://www.anthropic.com/research/next-generation-constitutional-classifiers)的训练方式，并新增了一组分类器，使 Claude 能够在 Chrome 中安全地执行更多自主操作。在下一节中，我们将讨论评估结果，这些结果展示了这些防护措施的有效性。

> At launch, we described how we tested Claude’s defenses against these attacks and the safeguards we had in place at the time; we later released a more detailed description of our [browser-use safeguards](https://www.anthropic.com/research/prompt-injection-defenses). Since then, we’ve improved how we train both the model and our [probes](https://www.anthropic.com/research/next-generation-constitutional-classifiers), and added an additional set of classifiers that make it possible for Claude to safely take more autonomous actions in Chrome. In the next section, we discuss the results of our evaluations, which show the efficacy of these safeguards.

**Claude 能识别更多攻击。**我们使用一个不断扩充的提示注入攻击库来训练 Claude，这些攻击来自我们内部的自动化攻击程序、外部红队人员以及真实世界的监控。当一种新攻击成功攻破当前模型时，它就会被加入该库，用于指导未来模型的训练以及我们已部署的防护措施，使其学会识别这种攻击。自从我们在 2025 年 11 月首次撰文介绍[面向浏览器使用场景的提示注入防御](https://www.anthropic.com/research/prompt-injection-defenses)以来，我们已让 Claude 对这类攻击的抵抗力大幅提升。

> **Claude recognizes more attacks. **We train Claude against a growing library of prompt injection attacks, sourced from our internal automated attackers, external red-teamers, and real-world monitoring. When a new attack succeeds against a current model, it’s added to the library, where it informs the training of future models and our deployed safeguards so they learn to recognize it. Since we first wrote about our [prompt injection defenses for browser use](https://www.anthropic.com/research/prompt-injection-defenses) in November 2025, we’ve made Claude substantially more resistant to these attacks. 

**探针会在 Claude 对网页内容采取行动之前先对其进行筛查。**网页内容通过工具结果抵达 Claude。为了执行诸如阅读页面或打开邮件之类的操作，模型会发起一次工具调用；工具结果让模型得以读取输出（在此例中即页面或邮件的内容）。我们训练探针扫描这些结果，以发现潜在的提示注入。当探针检测到可能的攻击时，Claude 会收到警告，要以怀疑的态度对待该内容，并在必要时先与你确认再采取行动。我们最初在 Claude Opus 4.5 上部署了这些探针，此后又扩展了它们所覆盖的攻击类型。

> **Probes screen web content before Claude acts on it.** Web content reaches Claude through tool results. To take an action like reading a page or opening an email, the model makes a tool call; the tool result lets the model read the output (in this case, the content of the page or the email). We train probes to scan those results for potential prompt injections. When a probe detects a likely attack, Claude is warned to treat the content with suspicion and, if needed, to check with you before taking an action. We first deployed these probes with Claude Opus 4.5, and have since expanded the types of attacks they cover.

**操作在运行前会先经过验证**。在 Claude in Chrome 中，Claude 现在会自动批准它判定为安全的操作，所用机制与 Claude Code 中的[自动模式](https://claude.com/blog/auto-mode-default-in-claude-code)相同。（如果你更希望继续手动批准 Claude 的操作，可以在设置中关闭此功能。）分类器会审查 Claude 即将执行的操作，例如导航到新网站或在页面中输入文本，并将其与你最初的请求进行比对。如果该操作与你的请求不符，就会被阻止。

> **Actions are verified before they run**. In Claude in Chrome, Claude will now automatically approve actions it determines to be safe, using the same mechanism as [auto mode](https://claude.com/blog/auto-mode-default-in-claude-code) in Claude Code. (You can switch this off in your settings if you’d prefer to continue to approve Claude’s actions manually.) A classifier reviews actions Claude is about to take, such as navigating to a new website or entering text into a page, and checks them against what you originally asked for. If the action doesn’t match your request, it’s blocked.

#### 衡量 Claude 抵御提示词注入的稳健性

> Measuring Claude’s robustness against prompt injection

我们已对这些防护措施进行了测试，以确保 Claude in Chrome 可以安全地用于基于浏览器的工作。在此，我们报告最近一次评估的结果。

> We’ve tested these safeguards to ensure that Claude in Chrome is safe to use for browser-based work. Here, we report the results from our most recent evaluations. 

在我们[最初的评估](https://claude.com/blog/claude-for-chrome)中，我们测试了 Claude Cowork 抵御提示注入攻击的能力（该评估最初是在我们发布 Claude in Chrome 试点时开发的），在 [Cowork harness](https://claude.com/blog/cowork-chrome-side-panel) 中，没有任何攻击能够成功攻破 Claude Fable 5、Claude Opus 5 或 Claude Sonnet 5，即使在没有上述探测器和分类器的情况下也是如此。   

> On our [initial evaluation](https://claude.com/blog/claude-for-chrome) testing Claude Cowork’s resilience against prompt injection attacks (first developed when we released the Claude in Chrome pilot), no attack succeeded against Claude Fable 5, Claude Opus 5, or Claude Sonnet 5 in the [Cowork harness](https://claude.com/blog/cowork-chrome-side-panel), even without the probes and classifiers discussed above.   

![Success rate of prompt injection attacks against Claude Opus 4.5, Sonnet 5, Opus 5, and Fable 5. Opus 4.5 was run with extended thinking, since it does not support our newer default of adaptive thinking. All other models were run with adaptive thinking at medium effort as the default. The results discussed in our November 2025 blog post were run without extended thinking enabled, but because thinking cannot be disabled for Fable 5, we report thinking-enabled results here. The grader model used in November is also no longer available, so we moved to a more capable grading pipeline combined with manual review of successful attacks, which produces fewer false positives.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8e8c30f077b615a7429ea7_8477d7f5.png)

由于我们已经使该评估饱和（0% 的成功率即为证据），我们决定将其退役。在我们的[当前评估](https://www-cdn.anthropic.com/b514064af1408018e64b1ad24e7d5e75850b4ffd/Claude%20Opus%205%20System%20Card.pdf#page=76.73)中（该评估使用了由专业红队人员提供的更强攻击），在没有任何额外防护措施的情况下，触达模型的攻击对 Opus 4.5 的成功率为 17.6%，对 Opus 5 的成功率为 3.8%。在使用 2025 年 11 月可用的最强防护措施时，针对搭配探针运行的 Opus 4.5 的攻击成功率为 16.7%。对于 Opus 4.8 及之后的每一个模型，在同时运行探针和安全分类器的情况下，没有任何攻击对 Claude Sonnet 5、Claude Opus 5 或 Claude Mythos 5 取得成功。我们观察到针对 Fable 5 的攻击成功率为 0.3%。我们已人工核实，所有成功的突破都发生在低严重性场景中，并且我们正在着手缓解这些问题。

> Because we saturated that evaluation (as evidenced by the 0% success rate), we decided to retire it. On our [current evaluation](https://www-cdn.anthropic.com/b514064af1408018e64b1ad24e7d5e75850b4ffd/Claude%20Opus%205%20System%20Card.pdf#page=76.73), which uses stronger attacks sourced by professional red-teamers, attacks that reached the model succeeded against Opus 4.5 17.6% of the time and against Opus 5 3.8% of the time, before any additional safeguards.  With the strongest safeguards available in November 2025, attacks against Opus 4.5 running with probes succeeded 16.7% of the time. Against every model from Opus 4.8 onwards, when running with probes and the safety classifier, no attacks succeeded against Claude Sonnet 5, Claude Opus 5, or Claude Mythos 5. We saw a 0.3% attack success rate against Fable 5. We have manually verified that all successful breaks are in low-severity scenarios and are working to mitigate them.

![No attacks succeeded against Claude Sonnet 5 or Opus 5 with probes plus the automatic approval safety classifiers, and 0.3% of attacks succeeded against Fable 5. Opus 4.5’s model behavior resulted in a lower number of attacks reaching the model, but it still had the highest percentage of successful attacks.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8e8c30f077b615a7429ea4_b8a100e7.png)

提示注入是一个不断变化的目标。虽然这种方法能够防御当前的攻击，但我们还需要确保我们的防护措施始终领先于攻击者不断演变的手段。随着每一次模型发布，我们持续投入开发更为复杂精密的自动化系统，用于攻击发现、红队测试以及构建更强大的分类器。

> Prompt injection remains a moving target. While this approach defends against current attacks, we also need to ensure our safeguards stay ahead of the evolving methods of attackers. With each model release, we continue to invest in developing more sophisticated automated systems for attack discovery, red-teaming, and building stronger classifiers.

#### 快速开始

> Getting started

要开始在 Chrome 中使用 Claude，请从 [Chrome 应用商店](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn)安装它。在企业版方案中，管理员可以在“组织设置”中对其进行管理，并将其限制在已批准的域名范围内。请参阅[管理员设置指南](https://support.claude.com/en/articles/13065128-claude-in-chrome-admin-controls#h_bdb63199e1)。

> To start using Claude in Chrome, install it from the [Chrome Web Store](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn). On Enterprise plans, admins can manage it in Organization Settings and limit it to approved domains. See the [admin setup guide](https://support.claude.com/en/articles/13065128-claude-in-chrome-admin-controls#h_bdb63199e1).

如果要处理你电脑上的文件或与其他应用程序协同工作，你仍然需要使用 Claude 桌面版应用。Claude in Chrome 目前还不能在其他 Chromium 浏览器或移动端上运行。

> You’ll still need to use the Claude desktop app to work with files on your computer or with other applications. Claude in Chrome doesn’t run on other Chromium browsers or on mobile yet.

‍

> ‍

*¹ 并非所有攻击都会到达——即被——模型看到。在某些情况下，Claude 所采取的行动导致它从未遇到那些恶意指令。*

> *¹ Not all attacks reach—i.e., are seen by—the model. In some cases, the actions Claude takes result in it never encountering the malicious instructions.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Prompt Injection | 提示注入 | 将恶意指令隐藏在网页、邮件或表单等内容中，诱导 AI 模型执行用户未授权操作的攻击手法。 |
| AI Agent | AI 智能体 | 能够自主调用工具、连续执行多步操作以完成用户目标的 AI 系统。 |
| Classifier | 分类器 | 用于判定输入或待执行操作属于哪一类别（如安全或不安全）的机器学习模型。 |
| Probe | 探针 | 嵌入模型处理流程中、用于扫描内容并检测潜在攻击信号的轻量检测组件。 |
| Tool Result | 工具结果 | 模型发起工具调用后返回的输出内容，浏览器场景下即页面或邮件正文等外部数据。 |
| Tool Call | 工具调用 | 模型为获取信息或执行动作而向外部工具发出的请求。 |
| Connectors | 连接器 | 把外部应用与数据源接入 Claude 的官方集成方式。 |
| Red Teaming | 红队测试 | 由专门人员模拟攻击者对系统发起对抗性测试以暴露安全漏洞的做法。 |
| Attack Success Rate | 攻击成功率 | 在评估中成功突破模型防护的攻击占全部攻击尝试的比例。 |
| Guardrails | 防护措施 | 为约束 AI 行为、阻止不安全输出或操作而设置的各类安全机制。 |
| Harness | 运行框架 | 承载模型运行、提供工具与执行环境的外层软件框架。 |
| Auto Mode | 自动模式 | 由系统自动批准被判定为安全的操作、无需用户逐项确认的运行方式。 |
| Constitutional Classifiers | 宪法式分类器 | 依据一组明确书面原则训练、用于筛查有害输入输出的安全分类模型。 |
| System Card | 系统卡 | 随模型发布的技术文档，说明其能力、评估结果与安全风险。 |
| Jailbreak | 越狱 | 通过特制输入绕过模型安全限制、使其产生本应被拒绝的行为或输出。 |
