# Curative 如何借助基于 Claude 的智能体构建全国性医疗服务提供者网络

> How Curative is building a national provider network with agents on Claude

> 来源：Claude Blog / Anthropic，2026-11-10
> 原文链接：https://claude.com/resources/articles/how-curative-is-building-a-national-provider-network-with-agents-on-claude
> 分类：AI 智能体 / 医疗保险签约自动化

## 核心要点

- Curative 面向雇主销售零共付额、零免赔额的健康保险，按每年约 2,000 份合同的速度建成全国性网络需要 30 年，仅靠招聘无法填补缺口。
- 主智能体 Gwen 主要基于 Claude Opus，每次运行只处理一家医疗服务提供方，负责从最初接洽到签约的全过程，并依据理赔数据集和价格透明度文件给出建议费率。
- 运行在 Sonnet 上的费率审核器负责判断 Gwen 超出标准模板的费率请求是否合理，约三分之二获得放行，其余非标准请求交由首席执行官审批。
- 运行在 Haiku 上的评审模型在每条通信发出前进行检查，被拦截的消息会附带原因返回给 Gwen 重写，这一环节源于 Gwen 曾把内部出价备注抄送给提供方。
- 每份合同约消耗 2000 万个 token，成本约为原先的十分之一，从填写表单到签约最快一小时，使签约常被大型网络忽视的小型提供方成为可行策略。
- Gwen 上线后签约团队从 45 人增至约 55 人，人均生产力约为原来的 2.5 倍，人员工作重心转向电话沟通与关系维护，并就 Gwen 促成的交易获得报酬。
- Curative 的其他智能体还承担雇主端销售、资质审核、数据录入和理赔争议答复等工作，其中理赔争议的答复时间从约 90 天缩短到 30 分钟以内。
- 所有智能体运行在 13 名工程师用 Claude Code 重建的理赔、事前授权和财务系统之上，这些系统提供 MCP 和 API 供智能体直接调用。
- 团队总结的经验包括：只给模型一个运行 Python 的通用工具、使用传真等对方习惯的渠道、保持每次运行隔离、定期让 Claude Code 抽样历史运行并提交修复。
- 智能体最初被禁止接触受保护的健康信息，在低风险场景积累经验后才迁移到相关领域，并配以后端控制和审计日志，同时需留意智能体自发产生的行为是否在风险承受范围内。

## 正文

*在我们的系列文章**《初创公司如何借助 Claude 进行构建》**中，我们重点介绍初创公司如何利用 AI 变革各自所在的行业。在本文中，我们将分享 Curative 如何基于 Claude 构建了一套层级式智能体体系，使签署医疗服务提供方合同的速度比其团队在 2025 年时快了约 50 倍。*

> *In our series, **How startups build with Claude**, we highlight how startups are transforming their industries with AI. In this article, we share how Curative built a hierarchy of agents on Claude to sign provider contracts about 50 times faster than its team did in 2025.*

| 简要介绍 |  |
| --- | --- |
| 名称 | 治愈性 |
| 成立时间 | 2020 年；2022 年推出其健康计划 |
| 创始人 | Fred Turner（首席执行官）、Isaac Turner（首席技术官）、Tami Wilson-Ciranna（总裁） |
| 栈 | Claude Platform、Claude Code、定制理赔系统 |
| 增长 | 以 12.75 亿美元估值完成 1.5 亿美元 B 轮融资。会员超过 165,000 人，雇主超过 1,200 家（2025 年 12 月）。通过 Gwen 签署了 23,000 份医疗服务提供方合同。每周新增 2,000 至 2,400 份合同，而 2025 年全年仅为 2,100 份。 |

> 英文原表 / English original

| The quick pitch |  |
| --- | --- |
| Name | Curative |
| Founded | 2020; launched its health plan in 2022 |
| Founders | Fred Turner (CEO), Isaac Turner (CTO), Tami Wilson-Ciranna (President) |
| Stack | Claude Platform, Claude Code, bespoke claims system |
| Growth | $150M Series B at a $1.275B valuation. 165,000+ members and 1,200+ employers (Dec 2025). 23,000 provider contracts signed with Gwen. 2,000 to 2,400 new contracts a week, up from 2,100 in all of 2025. |

[Curative](https://curative.com/) 面向雇主销售健康保险，会员完成一次基线就诊（Baseline Visit）后，网络内医疗服务的共付额为 0 美元，免赔额也为 0 美元。Curative 并非一开始就做保险。它起步时是一家检验实验室创业公司，据其内部估算，最终处理了全美 10% 的 COVID-19 检测。因此，他们开始与美国几乎每一家保险公司合作。

> [Curative](https://curative.com/) sells health insurance to employers, with $0 copays and $0 deductibles for in-network care once members complete a Baseline Visit. Curative didn’t start out in insurance. It started as a lab startup and ended up processing 10% of all US COVID-19 tests according to their internal estimates. As a result, they started working with nearly every insurer in the country.

它的几位英国创始人习惯了患者无需为医疗付费的体系，他们看到了其中的低效之处，于是着手打造一家以预防为核心的支付方。后来他们意识到，自己严重低估了建立一个全国性网络的难度。

> Its British founders, used to a system where patients don’t pay for care, saw inefficiencies and set out to build a payer focused on prevention. They realized they had significantly underestimated how hard building a national network would be.

“在创业公司里，天真有时是件好事，因为你不知道这件事是不可能的。然后在这个过程中，你会想出办法让它变得并非不可能，”Curative 首席执行官 Fred Turner 说。“去年我们签了 2,100 份合同，是前一年的两倍，但按每年 2,000 份的速度，我们意识到这仍然需要 30 年才能建成。全国性网络只有寥寥几家，而且都是在大约 30 年前建成的，这是有原因的。”

> “Sometimes naivety is good in startups, because you don’t know that it’s impossible. And then along the way you figure out a way to make it not impossible,” said Curative CEO Fred Turner. “Last year we signed 2,100 contracts, twice as many as we did the year before, but at 2,000 a year, we realized it would still be a 30-year build. There is a reason there are only a handful of national networks and they were all built about 30 years ago.”

Curative 需要加快合同签署速度，但仅靠招聘无法填补如此大的缺口。

> Curative needed to accelerate contract signings, but hiring alone couldn’t close a gap that size.

他们的解决方案是 Gwen：一个负责把单个服务提供方交易从最初接洽一路推进到签约的智能体，周围还有一些较小的智能体，负责审核它给出的费率、检查它发出的消息、回答它提出的问题，并在遇到非标准定价时上报给人工处理。

> Their solution: Gwen, an agent that works one provider deal from initial outreach to signature, surrounded by smaller agents that review its rates, check its messages, answer its questions, and escalate to humans for non-standard pricing.

![Diagram of Gwen, Curative’s provider deal agent on Claude Opus, showing what it reads, the actions it takes, and the Haiku judge, Sonnet rate reviewer, and person who check its work.](https://assets.claude.com/b72a4b872ebbed253dc2492d8d0db2c4664b6b2f.png)

下面是他们的构建过程，以及一路上出过的问题。

> Here is how they built it and what broke along the way.

#### **Gwen：供应商合同智能体**

> **Gwen: the provider contracts agent**

Gwen 同时处理入站和出站线索。Gwen 的每次运行只处理一家提供商，主要基于 Claude Opus，因此不会受到其他交易中任何信息的影响。

> Gwen works both inbound and outbound leads. Each run of Gwen handles a single provider, mostly on Claude Opus, so nothing from other deals influences it.

例如，如果一家诊所在 Curative 的网站上填写了表单，Gwen 会对这家诊所进行调研，并根据一份购买的理赔数据集以及支付方如今被要求公布的价格透明度文件，回复建议费率。Gwen 会向医疗服务提供方展示这些市场费率数据，以协助谈判。

> For example, if a practice fills in the form on Curative’s website, Gwen will research the practice and reply with proposed rates based on a purchased claims data set and price-transparency files payers are now required to publish. Gwen will show providers these market rate data to help with negotiations.

费率审核器运行在 Sonnet 上。当 Gwen 想要超出其标准费率模板时，它会写明理由，再由审核器判断该费率是否合理。

> The rate reviewer runs on Sonnet. When Gwen wants to exceed its standard rate template, it writes out why, and the reviewer decides whether the rate makes sense.

“很长一段时间里，我们有一个很长的审批队列：如果 Gwen 想把费率定得比模板高出一定幅度，就必须先获得批准，不过后来我们逐渐放宽了限制。事实证明，让第二个智能体来审核费率，比单纯给 Gwen 更多权限效果更好。”Fred 说。

> “For a long time there was a big approval queue where Gwen had to get rates approved if she wanted to go a certain amount above the template, but we relaxed over time. Having a second agent review rates worked better than just giving Gwen more authority,” said Fred.

Sonnet 费率审核器会放行 Gwen 约三分之二的请求，其余任何非标准的请求则交由 Fred 审批。

> The Sonnet rate reviewer clears about two-thirds of Gwen’s requests and then anything non-standard goes to Fred for approval.

“我看到的请求，要么来自大型医疗集团，要么来自提出奇怪请求的人，即使这不是一个由智能体主导的销售模式，这些请求也会找到我这里来，”Fred 说。

> “The requests I see are from a big medical group or someone with a weird request that would come to me even if this wasn’t an agent-led motion,” said Fred.

主动外联的单子需要更多的坚持，因为诊所都很忙。有些医疗服务提供方要等到第十四封邮件和第九份传真之后才会回复。

> Outbound deals take more persistence, because practices are busy. Some providers’ replies come after the fourteenth email and the ninth fax.

![Line chart of the running total of provider contracts closed by Gwen, from March to October 2026, rising past 23,000, with fax added on July 24, 2026.](https://assets.claude.com/81117dec18c16ca382f07795da2c7c1202546b9b.png)

一个运行在 Haiku 上的评审模型会在每条通信发出之前先读一遍。Curative 之所以加上它，是因为 Gwen 曾把关于自己最高能出到多少的内部备注抄送给了医疗服务提供方。被拦截的消息会附带原因返回，这样 Gwen 就可以重写后再试一次。

> A judge, which runs on Haiku, reads every communication before it’s sent. Curative added it after Gwen copied providers on internal notes about how high it could go. A blocked message comes back with the reason, so Gwen can rewrite it and try again.

每份合同大约需要 2000 万个 token 才能完成，约为原始成本的十分之一。这些效率提升支撑了 Curative 的一项核心战略：签约那些常被大型网络忽视的小型医疗服务提供方。

> Each contract takes about 20 million tokens to complete, roughly a tenth of the original cost. These efficiencies enable one of Curative’s core strategies: signing smaller providers that have often been overlooked by larger networks.

“无论你是大型医院系统还是个人执业的医疗服务提供者，这个智能体都会乐于给予你同等程度的关注，”Fred 解释道。“从这个智能体的角度来看，这位医疗服务提供者就是它唯一的关注对象。”

> “The agent will happily give you the same level of attention whether you are a large hospital system or if you’re a solo provider,” Fred explained. “From that agent’s perspective, this provider is its only focus.”

在谈判过程中，Gwen 会对照 Curative 的政策文件检查诊所方的修订标记，然后编写 Python 代码，将双方的修改合并成最终文件。

> During negotiations, Gwen checks practice redlines against Curative’s policy document, then writes Python to merge both sides’ changes into a final document.

从填写表单到完成签约，整个流程最快只需一小时。合同签署后，一个独立的资质审核智能体会核查该医疗服务提供方的执业许可，其他智能体则录入该提供方的数据和合同，以便理赔能够依据合同进行定价。

> From form to signature, the process can be as quick as an hour. Once the contract is signed, a separate credentialing agent checks the provider’s licenses, and agents load the provider’s data and contract so claims can price against it.

自 Gwen 上线以来，Curative 的签约团队已从 45 人增长到约 55 人，每人的生产力约为原来的 2.5 倍。他们把陌生拓展和文书工作交给 Gwen，再通过电话接手有意向的线索。Curative 也会就 Gwen 促成的交易向签约团队支付报酬，因此人和智能体共享同一个目标。

> Curative’s contracting team has grown from 45 to about 55 people since Gwen launched, each about 2.5 times as productive. They hand Gwen cold outreach and paperwork and take over warm leads by phone. Curative pays its contracting team on Gwen’s deals too, so people and agents share one target.

“人们的工作变得更侧重于关系，而不是文书工作，”Fred 说。

> “People’s work becomes more about the relationship and less about paperwork,” said Fred.

Fred 还认为，更快的签约流程有助于小型诊所保持独立。“如果你开办一家诊所，却要花三个月才能加入保险网络并完成资质认证，那这三个月你就根本拿不到钱。”他说。

> Fred also believes faster contracting helps small practices stay independent. “If you start a medical practice and it takes three months to get in network and credentialed, you’re just not getting paid for three months,” he said.

Gwen 并不是 Curative 唯一的智能体。Brad 是另一个基于 Opus 的智能体，主要通过经纪人帮助向雇主销售 Curative 的保险计划。Brad 会就每一份报价与经纪人跟进，并从核保人员过去需要手工清理的电子表格中提取员工数据，帮助核保人员加快工作进度。

> Gwen is not Curative’s only agent. Brad, another Opus-based agent, helps sell Curative’s plan to employers, mainly through brokers. Brad follows up with brokers on each quote and helps underwriters move faster by pulling employee data out of the spreadsheets underwriters used to scrub by hand.

借助人机协作团队，Curative 现在可以在 30 分钟内答复通过电子邮件或传真提交的理赔争议，并附上一封针对该笔理赔的专属信函。“过去答复理赔争议大约需要 90 天，现在通过电子邮件或传真只需不到 30 分钟，”Fred 说。“大多数支付方使用一套模板，通过邮件合并拼接而成。这让医疗服务提供方非常不满意，因为模板通常并不能真正解释到底发生了什么。现在，提供方收到的是一封定制信函，其中会说明该笔理赔的具体情况、目前的进展以及原因。”

> Using human-agent teams, Curative can now answer emailed or faxed claims disputes in under 30 minutes, with a letter specific to that claim. “Claims dispute responses used to take about 90 days and now take under 30 minutes by email or fax,” said Fred. “Most payers use a set of templates that are mail-merged together. That leaves a provider deeply unsatisfied, because usually the template doesn’t actually explain what’s going on. Now providers get a customized letter that explains the specifics of the individual claim, what’s happening, and why.”

他们的所有智能体都运行在定制的理赔、事前授权和财务系统之上，这些系统是 13 名工程师今年用 Claude Code 重建的。该团队曾估算，仅构建一套理赔系统就需要 100 个工程师年。

> All of their agents sit on bespoke claims, prior authorization, and finance systems that 13 engineers rebuilt this year with Claude Code. The team had once sized building a claims system alone at 100 engineer-years.

“我们并不是要把[这些智能体]接入某个理赔系统，”Fred 说，“理赔系统就是运行在 AWS 上的 Python，它有 MCP，也有 API，而且是 Claude 写的，所以 Claude 理解它。”

> “We’re not trying to plug [these agents] into a claim system,” Fred said. “The claim system is Python running in AWS, and it has an MCP and it has an API, and Claude wrote it, so it understands it.”

#### **Curative 在构建与人谈判的智能体过程中学到了什么**

> **What Curative learned from building agents that negotiate with people**

以下是 Curative 团队在构建能与人谈判的智能体方面学到的经验。

> Here’s what the Curative team learned about how to build agents that negotiate with people.

- **从一个通用工具开始。**“我们一开始的想法是，‘哦，我们会有各种工具’，但这样效果并不太好，因为修订标注相当复杂，”Fred 说。“我们发现效果最好的做法是，模型只有一个工具，就是运行 Python，然后用一个 docx 库完成所有的修订标注。效果非常漂亮。”
- **在对方习惯的渠道上与他们沟通。**一款传真工具让 Gwen 的胜率提高了一倍多。如今许多医疗服务提供方会在打印出来的传真上手写内容，再传真回来。“这就是在对方所在的地方与他们相遇，”Curative 首席技术官 Isaac Turner 说，“没错，他们有电子邮件，但他们真正用得顺手的还是传真。”
- **让每次运行保持隔离。**Gwen 的每次运行只面对一个服务提供方，并且不会在不同交易之间保留任何记忆。Curative 的销售智能体 Brad 则会保留记忆，这种做法可行，但需要小心对待。“你可能会记下错误的笔记，然后陷入这种死循环：它有一条永远无法清除的错误记忆，”Fred 指出。
- **从运行之外改进系统。**每隔几天，Fred 都会给 Claude Code 同一条提示词：抽样最近 10,000 次运行，标记出任何异常之处，并提交一个 PR 来修复。“改进循环来自于让 Claude Code 跑一遍大量的历史对话，并追问这本可以如何做得更好，”他说。
- **先在远离 PHI 的环境中试验。**在很长一段时间里，Gwen 被禁止接触受保护的健康信息（PHI），因此早期的错误都发生在风险较低的场景中。如今在智能体会接触 PHI 的地方，后端控制措施会限制哪些内容可以进入对话，智能体的活动也会被记录下来以供审计。“我们先在那边学会了怎么做，然后再把它迁移到 PHI 领域，”Fred 说。签署业务伙伴协议（BAA）——即 HIPAA 要求供应商在处理 PHI 之前必须签订的合同——也变得更容易了。“尤其是 Anthropic，在快速推出最新服务的 HIPAA 合规版本方面一直做得非常好，”Isaac 说。“尽管身处受监管的领域，我们仍然能够非常迅速地引入这些新技术。”
- **留意智能体开始自行做哪些事，并确保这些行为符合你的风险承受范围。**当医疗服务提供方想要一份可在内部传阅的宣传单时，Gwen 用它的 Python 工具做了一份，而此前并没有任何政策要求它这样做。当一家网络内诊所的前台把一位会员拒之门外时，Gwen 要求该诊所对员工进行培训，随后又确认了这位会员已顺利就诊。

> • **Start with one general tool.** “We started off with, ‘Oh, we’ll have tools,’ and that doesn’t work that well, because redlining is quite complex,” Fred said. “What we found works best is that the model just has one tool, which is run Python, and it does all the redlining with a docx library. It works beautifully.”
> • **Meet people on their channel.** A fax tool more than doubled Gwen’s win rate. Many providers now handwrite on a printed fax and fax it back. “It’s meeting people where they are,” said Curative CTO Isaac Turner. “Yes, they have email, but really they’re comfortable in fax.”
> • **Keep each run isolated.** One Gwen run sees one provider and keeps no memory across deals. Brad, Curative’s sales agent, does keep memories, which works but needs care. “You can end up making notes that are wrong and then get into these doom loops, where it has a bad memory that can never be cleared,” Fred noted.
> • **Improve the system from outside the run.** Every few days, Fred gives Claude Code the same prompt: sample the last 10,000 runs, flag anything weird, and open a PR to fix it. “The improvement loops come from running Claude Code over lots of historic conversations and asking how could this have gotten better,” he said.
> • **Experiment away from PHI first.** For a long time Gwen was barred from protected health information (PHI), so early mistakes were in lower-risk settings. Where agents touch PHI now, back-end controls limit what enters a conversation, and agent activity is logged for audit. “We learned how to do it there and then transferred it over into PHI land,” said Fred. Signing Business Associate Agreements (BAAs), the contracts HIPAA requires before a vendor can handle PHI, has gotten easier too. “Anthropic especially has been very good about getting HIPAA-compliant versions of the latest services out very quickly,” said Isaac. “We’ve been able to onboard these new technologies very quickly despite it being regulated.”
> • **Watch what the agent starts doing on its own and make sure it matches your risk profile.** When providers asked for a flyer to share internally, Gwen made one with its Python tool, with no policy telling it to. When a front desk turned away a member at an in-network practice, Gwen asked the office to train its staff, then checked that the member got in.

#### **Curative 的下一步方向**

> **Where Curative is going next**

接下来，Curative 计划将智能体引入就医导航环节，让负责引导和辅导其会员的 130 名人员能够服务到更多人。

> Next, Curative plans to bring agents to care navigation, extending the reach of the 130 people who guide and coach its members.

Fred 预计医疗服务提供方一侧也会出现智能体。相当大一部分理赔争议似乎已经是由智能体撰写的，他希望提供方会使用智能体来谈判合同。“存在一个出清价格，越快找到这个出清价格，大家就都能继续去提供医疗服务，”他说。

> Fred expects agents on the provider side too. A large share of claims disputes already appear to be written by agents, and he hopes providers will use agents to negotiate contracts. “There’s a clearing price, and the faster you find the clearing price, everybody can get on with providing care,” he said.

| 来自 Curative 团队的最佳实践 |  |
| --- | --- |
| 智能体一开始应该拥有多大的权限？ | 比你以为它能承担的要少。Gwen 起初对任何高于模板的费率都设置了人工审批队列。Curative 分步放宽了限制，并优先放宽那些确定性更强的决策，随后加入了费率审核器，凡是它未放行的，仍由 Fred 审批。 |
| 当智能体出错时会发生什么？ | 要为此做好预案，并把它与替代方案作比较。“标准并不是完美，”Isaac 说，“标准是：如果让一千个人来签合同，他们会犯下多少让你后悔的错误？” |
| 如何审计数十万条消息？ | 记录所有日志，为每条对外发送的消息配置一个评审智能体，并让 Claude Code 对运行记录进行抽样检查。 |

> 英文原表 / English original

| Best practices from the Curative team |  |
| --- | --- |
| How much authority should an agent start with? | Less than you think it can handle. Gwen began with a human approval queue for any rate above the template. Curative loosened the limits in steps and for more deterministic decisions, then added the rate reviewer, with Fred still approving what it doesn’t clear. |
| What happens when the agent gets it wrong? | Plan for it, and compare it with the alternative. “The bar isn’t perfect,” Isaac said. “The bar is, if you had a thousand people signing contracts, how many mistakes would they make that you regret?” |
| How do you audit hundreds of thousands of messages? | Log everything, put a judge agent on every outbound message, and have Claude Code sample the runs. |

*立即开始使用 [Claude Platform](https://platform.claude.com) 进行构建。*

> *Start building with the [Claude Platform](https://platform.claude.com) today.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Agent | 智能体 | 能够自主调用工具、分步完成任务的 AI 系统。 |
| Provider Network | 医疗服务提供者网络 | 与保险公司签订合同、按约定费率为会员提供服务的医疗机构和医生的集合。 |
| Payer | 支付方 | 为医疗服务付费的机构，通常指健康保险公司。 |
| Copay | 共付额 | 会员每次就诊或取药时需自行支付的固定金额。 |
| Deductible | 免赔额 | 保险开始赔付之前会员需自行承担的医疗费用额度。 |
| Claims | 理赔 | 医疗服务提供方向保险公司提交的费用支付请求及其处理过程。 |
| Price Transparency Files | 价格透明度文件 | 支付方按监管要求公开的、与医疗服务提供方协商费率的数据文件。 |
| Redline | 修订标记 | 合同谈判中对文本增删改动的标注。 |
| Credentialing | 资质审核 | 核查医疗服务提供方执业许可与资格的流程。 |
| Underwriter | 核保人员 | 评估投保群体风险并确定保险报价的专业人员。 |
| Prior Authorization | 事前授权 | 某些医疗服务在提供前须获得保险公司批准的流程。 |
| PHI (Protected Health Information) | 受保护的健康信息 | HIPAA 所保护的、可识别到个人的健康相关信息。 |
| BAA (Business Associate Agreement) | 业务伙伴协议 | HIPAA 要求供应商在处理 PHI 之前必须签订的合同。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 让模型以标准方式连接外部工具和数据源的开放协议。 |
| Clearing Price | 出清价格 | 买卖双方都能接受并达成交易的价格。 |
