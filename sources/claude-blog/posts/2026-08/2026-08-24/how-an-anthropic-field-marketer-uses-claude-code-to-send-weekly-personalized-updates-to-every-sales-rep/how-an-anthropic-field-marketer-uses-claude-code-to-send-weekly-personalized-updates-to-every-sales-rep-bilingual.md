# Anthropic 的一位现场市场营销人员如何使用 Claude Code 每周向每一位销售代表发送个性化更新

> How an Anthropic field marketer uses Claude Code to send weekly personalized updates to every sales rep

> 来源：Claude Blog / Anthropic，2026-08-24
> 原文链接：https://claude.com/blog/how-an-anthropic-field-marketer-uses-claude-code-to-send-weekly-personalized-updates-to-every-sales-rep
> 分类：AI 应用 / 市场营销自动化

## 核心要点

- 营销人员长期面临的难题是让销售团队及时了解活动、白皮书、网络研讨会等市场一线动态，避免销售代表错过可分享给客户的信息。
- 最初的解决方案是周日晚上手工汇总公司动态、制作幻灯片，并在周一 15 分钟站会上讲解并分享到 Slack，但随着团队扩张和支持的销售团队增多而难以为继。
- 在一场市场营销黑客松中，作者与团队用一小时以 Claude Code 重建了这一流程，这类同事主导的轻松学习机会提供了日常工作中挤不出的试验时间。
- 启动方式是先用提示词告诉 Claude 自己并非技术人员，请它把提问者当作理解业务问题的产品经理并逐步协作，作者常把口头讲解录音后将转录文本交给 Claude 以提供完整业务背景。
- 作者先向 Claude 概述目标并手写一份虚构周报作为模板，以面向行动的“本周三件要事”开头，并为经理另设一份提供团队全局视角的汇总模板。
- 通过 MCP 将 Claude 连接到作为唯一可信数据源的 BigQuery，整合 HubSpot、Clay 和 Salesforce 的数据，并结合 CRM 中的销售辖区与 Slack 中的客户动态生成个性化更新。
- 试点从一个愿意提供反馈的十人销售团队开始，首次发送后即着手修正问题，包括把“绝不编造 URL”写成硬性规则，只渲染逐字符来自源数据表的链接，并剔除无链接的活动。
- 第一周结束时提示词已包含九条内容规则，每条都可追溯到具体反馈，例如核对联系人职位与活动目标受众、用行业门槛过滤不匹配的邀请、为尚无客户的新销售发送简短欢迎信。
- 针对源数据表列顺序六周内变动三次的问题，提示词被改为每次运行先读取表头行确认列的对应关系，指令由硬编码列号改为按列含义描述。
- 该摘要已推广到整个销售部门，每周一向客户经理私信推送三项优先行动、现场活动、网络研讨会报名联系人和可分享内容，曾在一周内让一场高管晚宴报名人数翻倍。
- 同一提示词只改动一个 CRM 字段就复制给了 BDR 团队并在两天内上线，此后又扩展到客户成功团队和联盟团队，并为销售之外的跨职能伙伴提供活动总览。
- 每周推送会被完整归档以便回溯任意销售人员在任意日期收到的内容，系统已无需人工批准，作者度假期间推送仍正常自行发出。
- 作者给出的最佳实践包括从自己手工投入最多的重复任务入手、用平实语言写指令并为文档标注版本、从小规模有意愿的群体试点、把每一次反馈修正固化为明确规则。

## 正文

作为一名营销人员，我面临的最大挑战之一，是让销售团队及时了解市场一线发生的一切。大多数营销人员都熟悉这种走廊对话：一名销售代表说：“哦，我从没听说过那个活动”（或那份新白皮书、那场网络研讨会），而你意识到自己错过了一个向销售代表分享最新工作的机会，进而也错过了向客户分享的机会。 

> One of the biggest challenges I’ve faced as a marketer is keeping the sales team up to date with everything that’s going on in the field. Most marketers know the hallway conversation where a sales rep says, “Oh, I never heard about that event” (or that new whitepaper, that webinar) and you realize you’ve missed a chance to share the latest work with sales reps, and in turn, your customers. 

我最初采用的是许多营销人员都很熟悉的解决方案：每周一早上与销售团队进行15分钟的站会。我会在周日晚上汇总整个公司的最新动态，将其制作成适合演示的幻灯片，然后在会议上现场介绍这些信息，并在 Slack 中分享整套幻灯片。这样就搞定了，对吧？其实不然：有了 Claude 之后，整个流程显得过于依赖手工操作；而且随着团队不断壮大，我开始同时支持多个销售团队，原来的幻灯片工作方式也越来越难以为继。这些更新也变得没那么有用了，因为我已无暇为每个团队筛选出最适合他们的机会。 

> My initial solution was one many marketers will recognize: the 15-minute Monday morning stand-up with the sales team. I spent Sunday evenings collating updates from across the business and turning them into presentable slides, and then delivered the info live in the meeting and shared the deck in Slack. Job done, right? Not quite: with access to Claude, this all felt overly manual and as our team grew and I started supporting multiple sales teams, my slide routine couldn’t keep up. The updates were also becoming less useful, because I no longer had time to pick out the opportunities that were right for each team. 

我希望 Claude 来完成这项工作，为每位销售代表打造一个更好的“产品”：一份针对他们各自客户量身定制、并与我们市场部正在推进的所有事项相匹配的每周摘要。

> I wanted Claude to do the work and create a better “product” for each sales rep: a weekly digest tailored to their accounts and matched to everything we had going on in marketing. 

幸运的是，我们组织了一场市场营销黑客松：专门腾出时间，用 Claude Code 重建可重复的流程和工作流。我和团队聚在一起，花了一个小时攻克这个问题，而这带来了全然不同的结果。像黑客松这样轻松的、往往由同事主导的学习机会，能让人进行平时日常工作中根本挤不出时间去做的试验和探索，我们团队也不例外。

> Thankfully, we had organized a marketing hackathon: dedicated time to rebuild repeatable processes and workflows with Claude Code. I huddled with my team and we dedicated an hour to this problem, which made all the difference. Casual, often peer-led learning opportunities like hackathons allow for experimentation and exploration you wouldn’t otherwise carve out time for in your day to day, and our team was no exception. 

#### **你不需要写代码，你需要讲清楚**

> **You don't need to code, you need to explain**

同行营销人员问我最多的问题之一是：“我该如何开始使用 AI？”我的方法，尤其是在使用 Claude Code 时，是先给出一段提示词，向 Claude 说明：虽然我不是技术人员，但我面临这样一个具体的挑战，Claude 应该把我当作一位深刻理解业务问题的产品经理，并且与我一步步地合作推进。我习惯于把想法说出来，所以我常常会把自己讲解这个问题的过程录下来，然后把转录文本交给 Claude；这样一来，Claude 就掌握了全部的业务背景。

> One of the biggest questions I get from fellow marketers is, “How do I get started with AI?” My approach, especially with Claude Code, is to open with a prompt explaining to Claude that although I’m not technical, I have this specific challenge, and Claude should treat me as a product manager who deeply understands the business problem, and work with me step by step. I think out loud, so I'll often record myself explaining the problem and give Claude the transcript; that way, Claude has all the business context. 

以我们团队的每周 AE 摘要为例，我首先向 Claude 概述了目标：每周向每位销售代表发送一条 Slack 消息，介绍市场部正在推进的工作，以及这些工作会如何帮到他们的客户。随后我写了一份虚构的周报，好让 Claude 有一个可以参照的模板。我知道销售代表以行动为导向，所以我以一份“本周三件要事”清单开头，列出三项可以分享给客户的行动事项，比如即将举办的活动或近期发布的内容。我还为经理汇总版另写了一份模板，因为经理通常想要的是对整个团队的全局视角，而不只是单个客户的情况。

> In the case of our team’s weekly AE digest, I started by outlining the goal to Claude: a weekly Slack message to each rep on what’s happening in marketing and how it would help their customers. I then wrote a fake weekly update to give Claude a template to work towards. I know sales reps are action-oriented, so I started with a “top three things for the week” list, featuring three action items, such as upcoming events or recent content, they can share with their customers. I also wrote a separate template for manager roll-ups, since managers typically want a holistic view of their team rather than just individual accounts. 

接下来，我通过 MCP 将 Claude 连接到 BigQuery；BigQuery 是我们市场团队的唯一可信数据源，能够提供来自 HubSpot、Clay 和 Salesforce 的数据的细粒度洞察。我想从简单的地方入手，所以先从我们关于活动和网络研讨会的唯一可信数据源开始。为了让每份更新都实现个性化，我让 Claude 从我们的 CRM 中提取销售代表负责的区域，以及 Slack 中传达的任何相关客户动态。这样，Claude 就可以将两者结合起来解析，生成个性化的每周更新。

> Next, I connected Claude to BigQuery via MCP; BigQuery is our marketing team’s source of truth, offering granular insights into data from HubSpot, Clay, and Salesforce. I wanted to start simple, so I began with our single source of truth for events and webinars. To personalize each update, I had Claude pull the rep’s territory from our CRM and any relevant account updates communicated in Slack. That way, Claude can parse the two together to create a personalized weekly update. 

随着时间推移，我与市场营销部门的其他团队展开合作以丰富数据，因此现在这份简报中还包含了新的内容类型，比如博客文章、电子书、客户案例、网络研讨会，甚至还有来自我们合作伙伴生态系统的活动。

> Over time, I’ve worked with other teams across marketing to enrich the data, so the briefing now includes new content like blog articles, and ebooks, customer stories, webinars, and even events from our partner ecosystem. 

#### **用户反馈才是真正的提示工程**

> **User feedback is the real prompt engineering**

为了把它推广到一线，我先从一个同意充当测试组的销售团队开始。先发给 10 个人的小组，万一出现错误也不会那么让人心慌，而且这个小组承诺会提供反馈。首次发送之后，我做了几处调整。

> To roll this out to the field, I started with one sales team that agreed to be the test group. Sending to a group of 10 people felt less daunting in case errors came up, and the group was committed to providing feedback. After the initial send, I made a few tweaks.

有些问题纯粹是错误。举例来说，当某个活动在源数据表中没有 URL 时，Claude 会编造一个看似合理、实则无法访问的地址。我们立即把这一点作为硬性规则写进提示词：绝不编造 URL。现在，只有当地址逐字符来自源数据表时，链接才会被渲染出来。后来的一个版本干脆把没有链接的活动从简报中剔除了，因为我们意识到，那些无法让我们的销售人员为任何人完成注册的活动，不过是噪音而已。

> Some issues were just errors. For example, where an event had no URL in the source sheet, Claude composed a plausible-looking one that led nowhere. We immediately wrote it into the prompt as a hard rule: never invent a URL. A link now renders only if the address comes character for character from the source sheet. A later version dropped linkless events from the briefing entirely, because we realized that events for which our sellers can't register anyone are just noise.

到第一周结束时，这条提示词中已经包含九条内容规则，每一条都可以追溯到某位销售或某位经理提出的一条反馈。一位销售指出，有位工程副总裁被推荐参加一场面向知识工作者的研讨会，因此现在会将联系人职位与活动的目标受众进行核对，不匹配的会被直接剔除，不作说明。一道行业门槛会把零售类客户挡在金融晚宴邀请之外，而尚未拥有客户的新入职销售，收到的是一封简短的欢迎信，而不是一条空白消息。

> By the end of the first week, the prompt held nine content rules, each traced to a piece of feedback from a seller or a manager. A seller flagged an engineering VP recommended for a workshop aimed at knowledge workers, so contact titles are now checked against an event's intended audience, and mismatches are dropped without comment. An industry gate keeps retail accounts off finance dinner invitations, and brand-new sellers who don’t have accounts yet get a short welcome note instead of a blank message.

另一些问题出在数据上。做市场的人都知道，维护单一可信数据源有多难。比如那份线下活动表格，六周内列的顺序就被调整了三次。为应对这种情况，我们修改了提示词，要求每次运行开始时先读取表格的表头行，确认列的对应关系，然后再着手撰写任何内容。指令不再硬编码为“查看 C 列”，而是变成类似“查看包含活动 URL 的那一列”这样的表述。

> Other issues were data problems. Anyone in marketing knows how hard it is to maintain a single source of truth. The field events sheet, for example, has had its columns rearranged three times in six weeks. To plan for that, we changed the prompt to open every run by reading the sheet's header row and verifying the column map before composing anything. Instead of hard-coding “look at Column C,” the instruction is now something like, “Look at the column with the event URL.” 

#### **将摘要推广到整个业务 **

> **Rolling the digest out across the business **

在这些初步的试运行之后，我把这份摘要推广到了我支持的每一个团队，现在现场营销部门为整个销售部门运行它。每个周一早上，Anthropic 多个销售细分领域的客户经理打开 Slack，就能看到一条私信，里面列出了本周的三项优先行动、面向他们所负责客户的现场活动、已经报名参加即将举行的网络研讨会的联系人、可供分享的相关营销内容，以及其他跟进建议。

> After these initial runs, I expanded the digest to every team I support, and field marketing now runs it for all of sales. Every Monday morning, account executives across several Anthropic sales segments open Slack to a direct message that lists three priority actions for the week, field events for their accounts, contacts who have already registered for upcoming webinars, relevant marketing content to share, and other follow-up suggestions. 

每条消息都是根据收件人自己的客户名单生成的，因此没有两条消息是相同的。这份摘要正在发挥作用；我们最近在一周内让一场高管晚宴的报名人数翻了一番，纯粹是因为合适的销售代表在周一早上就看到了合适的活动。

> Each message is composed from the recipient's own account list, so no two messages are alike. The digest is working; we recently doubled registrations for an executive dinner in a week, purely because the right reps had the right event in front of them on Monday morning. 

当 Anthropic 的业务拓展代表（BDR）想要属于他们自己的那版摘要时，我们为他们复制了这个提示词，只改动了一个字段，因为在我们的 CRM 中，BDR 与客户的对应关系不同于客户代表与客户的对应关系。提示词的结构和内容规则原封不动地沿用了下来，BDR 们在两天内就上线使用了。此后我也为客户成功团队和联盟团队做了同样的事情，并且我还为销售之外的其他跨职能伙伴提供所有市场营销活动的总览。 

> When Anthropic's business development representatives (BDRs) wanted their own version of the digest, we duplicated the prompt for them with a change in one field, since BDRs map to accounts through a different relationship in our CRM than account reps do. The prompt structure and content rules carried over unchanged, and the BDRs were live within two days. I’ve since done this for the customer success and alliance teams too, and I also provide an overview of all marketing activities for other cross-functional partners outside sales. 

无论业务节奏多快，我和我的团队在 Claude 的帮助下，都能确保销售代表在周一开始工作时就清楚地知道本周正在发生什么，以及应该优先关注哪些客户和活动。每个周一的推送都会被完整归档，因此我可以随时调出任何销售人员在任何日期收到的确切内容，而管理者可以在一份汇总报告中看到整个团队的推荐建议。我仍然会阅读发出去的内容，不过这套系统已经不再需要等我批准了。几周前我去度假时，周一的推送自行发出，没有出任何问题。

> No matter how fast the business moves, my team and I, with Claude’s help, make sure that sales reps start their Monday knowing exactly what’s happening that week and what accounts and events to prioritize. Each Monday's send is archived in full, so I can pull up exactly what any seller received on any date, and managers see their whole team's recommendations in a single roll-up. I still read what goes out, though the system no longer waits for my approval. When I went on holiday a few weeks ago, the Monday send went off on its own, without a hitch. 

![An example of what a Monday brief looks like, shown with a UI mockup depicted with synthetic data that does not represent real companies or individuals.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a88b9f50a3e987d4b342927_LATEST%20slack-weekly-update.png)

#### **开始使用 Claude 的最佳实践**

> **Best practices for getting started with Claude**

下面，我分享一些受我自己使用 Claude Code 的经验启发的技巧和窍门：

> Below, I share tips and tricks inspired by my own experience working with Claude Code:

1. **从小处着手，从你已经在手动做的事情开始。**当外界对人们如何使用 AI 的讨论如此嘈杂时，起步可能会很难。我的建议是：挑出你手动投入时间最多的那项重复性任务，让 Claude 重新把它做一遍。这样一来，你就能判断输出的好坏，因为你已经知道什么样才算好。如果问题仍然感觉太大，就把 Claude 当作思考伙伴，让它把问题拆解成若干步骤。如果这件事会与其他人共享，那就先把最初几次运行的结果发给你自己，这样你就能在别人之前先发现错误。
2. **用平实的语言写指令，并为每份文档标注版本。**像给新同事做交接一样向 Claude 说明情况，剩下的交给 Claude 就行。让 Claude 把每次更新保存为带编号的版本，并附上一行说明改动内容，这样你就有了一份记录，能追溯每次运行所对应的提示词。我们用的是一个 markdown 文件，同事们各自针对自己的板块运行它；我们最初用的是一份共享的 Google Doc，后来需要编辑的人多了，就迁移到了 GitHub。
3. **从一个小规模、有投入意愿的群体开始试点。**我们最初的测试是与少数几位客户经理一起进行的，我们知道他们愿意花时间为我们提供反馈并逐步改进这份报告，帮助我们发现错误，或就如何扩展、个性化覆盖范围提出建议。
4. **利用反馈改进你的提示词，把每一次修正都固化为一条明确的规则。**当收件人开始向我们反馈意见，而每一条修正都变成了给 Claude 的一条明确规则时，这份营销简报才真正变得有用。

> 1\. **Start small, with something you already do manually. **It can be hard to get started when there’s so much noise about what people are doing with AI. My advice: pick the repetitive task you spend the most hands-on time on and ask Claude to rebuild it. That way, you’ll be able to judge the output because you already know what good looks like. If the problem still feels too big, use Claude as a thought partner to break it into steps. And if it’s something you share with other people, route the early runs to yourself first so you catch the errors before anyone else does.
> 2\. **Write instructions in plain language and version each document.** Brief Claude the way you’d brief a new colleague and Claude will do the rest. Instruct Claude to save each update as a numbered version with a one-line note of what’s changed, so you have a record of the prompts that produced each past run. Ours is a markdown file my colleagues run for their own segments; we started from a shared Google Doc and moved to GitHub once more people needed to edit it.
> 3\. **Pilot with a small, committed group. **We ran our first tests with a handful of account executives who we knew would be willing to spend the time on providing us feedback and improving the report over time, helping us detect errors or offer suggestions on how to expand or personalize coverage.
> 4\. **Use feedback to improve your prompt, fold in each correction as an explicit rule. **The marketing briefing became useful when the recipients started sharing feedback with us and each correction became an explicit rule for Claude. 

Claude 自动化了一个以前每个星期天都要花我几个小时的手动流程，但通过这个项目，我和我的团队获得了比时间更宝贵的东西：我们的产出现在更具个性化、更有用，也更可衡量。你可以用 Claude 改进哪些营销流程呢？ 

> Claude automated a manual process that used to take me hours each Sunday, but with this project, my team and I have gained something much better than time: our output is now more personal, more useful, and more measurable. What marketing process can you improve with Claude? 

立即开始使用 [Claude Code](https://claude.com/product/claude-code)。

> Get started with [Claude Code](https://claude.com/product/claude-code) today.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Claude Code | Claude Code | Anthropic 推出的可在终端等环境中运行的 Claude 智能体工具，能连接数据源并执行可重复的工作流。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 一种开放协议，用于把模型与外部数据源和工具标准化地连接起来。 |
| AE (Account Executive) | 客户经理／客户代表 | 负责跟进特定客户名单并完成销售成交的销售岗位。 |
| BDR (Business Development Representative) | 业务拓展代表 | 负责开拓和筛选潜在客户、为客户经理输送商机的销售岗位。 |
| BigQuery | BigQuery | Google Cloud 提供的托管式数据仓库服务，可对大规模数据执行分析查询。 |
| CRM (Customer Relationship Management) | 客户关系管理系统 | 集中记录客户信息、联系人和销售辖区归属的业务系统。 |
| HubSpot | HubSpot | 集市场营销、销售与客户服务于一体的 SaaS 平台。 |
| Salesforce | Salesforce | 广泛使用的云端客户关系管理平台。 |
| Clay | Clay | 用于聚合多方数据、丰富潜在客户信息的营销数据工具。 |
| Slack | Slack | 企业内部使用的即时通讯与协作平台，支持频道和私信推送。 |
| single source of truth | 唯一可信数据源 | 指某类数据在组织内被指定为权威版本的唯一存放位置。 |
| prompt engineering | 提示工程 | 通过设计和迭代指令文本来控制模型输出质量的实践。 |
| hackathon | 黑客松 | 在集中的一段时间内组队快速构建原型或解决具体问题的活动。 |
| hallucination | 幻觉 | 指模型生成看似合理但并不真实存在的内容，例如无法访问的网址。 |
| header row | 表头行 | 数据表首行，用于标明各列字段名称与含义。 |
| field marketing | 现场营销 | 面向特定区域或客户群、配合一线销售开展活动与内容支持的营销职能。 |
