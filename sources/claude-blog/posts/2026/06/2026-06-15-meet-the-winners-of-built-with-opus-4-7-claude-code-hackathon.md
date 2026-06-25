---
source: claude-blog
source_url: https://claude.com/blog/meet-the-winners-of-built-with-opus-4-7-claude-code-hackathon
published_at: 2026-06-15
category: Claude Code
title_en: Meet the winners of the Built with Opus 4.7 Claude Code hackathon
title_zh: 认识用 Opus 4.7 打造的 Claude Code 黑客马拉松获奖者
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/dpYLaezmVNLOnyB3hPo9YePq8rMqPxX6"
---

# 认识用 Opus 4.7 打造的 Claude Code 黑客马拉松获奖者

> 来源：Claude Blog，2026-06-15
> 原文链接：https://claude.com/blog/meet-the-winners-of-built-with-opus-4-7-claude-code-hackathon
> 分类：Claude Code

## 核心要点

- 第一名 Medkit 是面向医学住院医师的诊疗模拟训练工具，作者跨四个 Claude Code 会话、几乎全程以语音方式构建。
- 第二名 Wrench Board 押注 Opus 4.7 对可视化电路原理图的理解能力，帮助电子维修技师定位故障点。
- 第三名 Maieutic 是一款让学生在写代码前先用自然语言描述需求的 IDE，强调先思考再构建。
- "最具创意使用奖" Virtual Puppet Theater 利用 Opus 4.7 的空间推理能力打造浏览器端实时木偶剧。
- "持续思考奖" MaestrIA 将智利木匠师傅的经验提炼成 JSON 知识文件，为家庭维修提供大师级诊断。
- "Claude 托管智能体（Managed Agents）最佳应用奖" ARIA 用五个智能体持续监测工厂机器并生成维修工单。

## 中文译文

上周，我们举办了 Claude Build Day——这是我们最新的一场黑客马拉松，构建者们齐聚旧金山，用 Claude Opus 4.8 将自己的创意付诸实践。

在我们等待他们的成果之际，我们与"用 Opus 4.7 打造（Built with Opus 4.7）"黑客马拉松的获奖者聊了聊他们的项目。他们攻克的领域涵盖医疗培训、电子维修、计算机科学教育、互动游戏、家庭维修和工厂维护。

恭喜各位获奖者以及所有参与者！我们希望他们的创意能给你带来启发。

### 第一名：Medkit，Bedirhan Keskin

Bedirhan Keskin 是一位常驻伊斯坦布尔、从医师转型为软件工程师的开发者，他使用 Claude 托管智能体（Claude Managed Agents）构建了 Medkit：一款面向住院医师或初级医生的学习工具，在一个游戏化的医疗诊所中模拟真实的患者就诊场景。

"当你独自身处急诊科、还有 50 名患者在等候，而你意识到有些病例你在医学院里从未练习过时，你最终只能在真实患者身上实时练习。" Bedirhan 说。

借助 Medkit，医学生可以对模拟患者进行诊断和治疗，使用该工具采集病史、开具化验单、读取影像、做出诊断并开具治疗方案。最后，一个智能体评分器会依据与执业医师资格考官所用相同的、已公开的临床指南，对整个诊疗过程进行评估。

Bedirhan 在四个独立的 Claude Code 会话中构建了 Medkit（语音引擎、内容生成、3D 游戏层和核心应用），保持每个上下文清晰，并同时推进所有部分。他遵循"说，别打字"的方式，几乎全程通过语音工作。

Medkit 已经开始受到关注，三所医学院和一家制药公司（均位于伊斯坦布尔）将在未来几周内启动试点。

给其他构建者的建议：把 Claude 当作思考伙伴，而不只是编码智能体。

Bedirhan 最初的本能是自托管语音引擎，但 Claude 建议使用云服务商以加快进度。"我最看重 Claude 的一点是，它不只是代码生成器，而是一个思考伙伴，帮我看到那些原本会错过的选项。"他说。

Medkit on GitHub

### 第二名：Wrench Board，Alexis Chapellier

来自法国 Reignier-Ésery 的 Alexis Chapellier 在维修电子产品多年后，创建了 RepairMind——一个由 AI 驱动的维修店管理平台。他在 Opus 4.7 黑客马拉松上的项目 Wrench Board，帮助独立技师攻克复杂的维修问题。用户上传一份电路原理图（schematic）和板视图（boardview）并描述故障症状，智能体便创建一个统一的电气图（electrical graph），在其上进行推理，指出需要探测的确切焊盘，读取测量值，并不断更新假设，直到诊断出问题所在。

Alexis 在 Claude Design 中为 Wrench Board 制作了原型，将应用的职责（设计、原理图导入、板视图、诊断智能体）分离开来，先为每一部分生成规格说明（spec），再生成计划（plan）。他在 Claude Code 的多智能体模式下执行，在每一步都进行基准测试，调试期间并行运行五到六个智能体，每个领域配一个专用智能体。

Alexis 押下的大赌注，是 Opus 4.7 理解可视化原理图的新能力；他说，当他让模型追踪主板上的一条电源路径时，他知道这个想法成立了。

"我看着 Wrench Board 的板视图一步步亮起来，箭头出现，组件被指向，名称浮现。那一刻，我明白这个想法站得住脚了。"他说。

Wrench Board 的下一阶段是建立一个由有意试用该应用的电子维修人员、以及能用自身现场经验丰富该工具的专家组成的社区。他的 Claude 额度将投入到 RepairMind、这些首批用户，以及当前正在推进的所有基础设施中。

"这场黑客马拉松证明，一个从维修店里走出来的自学者，能够在五天内交付一个雄心勃勃的系统。"参赛时正在申请"糊口工作"的 Alexis 说，"Claude Code 会放大任何拥有创意、并有耐力去执行它的人，无论其起点如何。"

给其他构建者的建议：在头脑风暴中深入挖掘，并对模型提出反驳。

Alexis 使用 Superpowers——一个集成进 Claude 的技能框架，它把"先头脑风暴、再做计划"的步骤结构化，有时并行运行多个头脑风暴，以在不同战线上同时推进。他从 Claude Design 开始，然后用内置的按钮直接分享项目目录，交接给 Claude Code，并在模型说"不行"时推动它。

"在黑客马拉松期间，Claude 好几次告诉我这个或那个在可用时间里做不完。但实际上，我有大把时间。"他说，"你得知道怎么跟它说，我反正要试一试。"

Wrench Board on GitHub

### 第三名：Maieutic，Paula Vásquez-Henríquez

Paula Vásquez-Henríquez 在智利康塞普西翁的 Universidad del Desarrollo 教授计算机科学，她说在过去两年里，她看到越来越多学生在不理解自己代码的情况下通过了考试。

"学生现在用 AI 来批量生产代码，但他们完全不知道这些代码是干什么的。"她说，"他们从未学会精确地陈述一个问题、在编码前起草一份计划，或者批判性地阅读自己的代码、注意到它在哪里偏离了原本的意图。在他们还没完全把问题想清楚之前，自动补全就已经交出了能运行的代码，于是那个元认知循环——真正造就一个程序员的'思考你的思考'——永远闭合不了。他们毕业时能生成代码，却无法对其进行推理。"

Paula 目前正在攻读人工智能博士，研究学生与 AI 的交互模式，她参加这场黑客马拉松，是想从学生和教师两个视角解决这个问题。

Maieutic 是一款 IDE，旨在让学生在关键时刻慢下来。学生必须先用通俗语言描述他们的程序应该做什么，才能写任何代码；Claude 会提出有针对性的澄清问题，并保持编辑器锁定，直到规格说明足够详尽，以至于一个称职的程序员无需猜测就能实现。

随后学生可以开始写 Python，但自动补全被关闭；一个聊天面板会直接回答查阅类问题，但对推理类问题则以反问而非直接修复来回应，拒绝替学生思考。

该工具的核心是"意图—差异审查（Intent-Diff Review）"，它让 Claude 将规格说明与最终代码进行比对，把每一处偏差归类为偏移（drift）、修订（revision）或缺陷（bug），然后抛出一个中立、不带指责的问题，促使学生自己解释这个问题。

对教师而言，一个实时仪表盘为每位学生显示一行，附带一句认知摘要（例如："已三次撰写规格说明，仍未考虑空输入"）。教师可以点击单个学生，监看他们与 Claude 的具体交互；系统还会分析整个班级，识别并呈现全班共有的任何误解，以便教师弥合这一差距。

黑客马拉松结束后，休斯顿大学的研究人员已联系她，商讨合著一篇论文，Paula 正把她的奖励额度投入到进一步开发该工具中。她说，黑客马拉松这一周让她看到，从理解一个问题、到交付一个解决它的工具，这之间的鸿沟已经坍塌。

"我是康塞普西翁（智利）的一名教育者，不是硅谷的。"她说，"我在一周内交付了一个可运行的全栈产品，因为这些工具让我能停留在我真正擅长的角色里，而把其余的事交给它们处理。最贴近真实问题的人，现在可以直接为这些问题构建解决方案了。"

给其他构建者的建议：先思考，再构建。

这个项目是 Paula 对自己理念的"吃自己的狗粮"：先定规格，再构建。"Maieutic 之所以存在，正是因为学生直接跳去写代码，而我把它做好的唯一办法，就是拒绝让自己也这么做。"她说。她花了整整两天进行纯粹的思考工作，在写下任何一行代码之前先制作设计规格和技术规格。

"那两天的规格工作在当时感觉很慢——黑客马拉松里有种立刻开始交付的真实压力——但正是它们让接下来的一周得以快速推进。"她说。

### Opus 4.7 最具创意使用奖：Virtual Puppet Theater，Rene Hangstrup Møller

全栈开发者 Rene Hangstrup Møller 对 Opus 4.7 的空间推理（spatial reasoning）能力很感兴趣，于是构建了 Virtual Puppet Theater——一个基于浏览器的应用，把网络摄像头视频和语音变成一场动态的互动木偶剧。一个实时动画木偶会镜像用户的动作，同时第二个由 AI 驱动的同伴木偶与用户对话调侃；口头提示可以即时改变场景并生成 3D 道具。

Rene 在整个流程中都使用了 Claude：概念讨论、规划和代码编写，而他负责导演、架构、审查和决策。这款应用基于 Bun、Vite 和 TypeScript，使用 MediaPipe 手部追踪（在 WASM 中运行）和 Three.js 以 60 fps 渲染 3D 木偶舞台。一个小型 WebSocket 服务器通过 Anthropic SDK 连接到 Claude Opus 4.7，以驱动 AI 木偶的对话并即时生成 3D 道具；语音方面，输入由 Web Speech API 处理，输出由 ElevenLabs 处理（以浏览器语音合成作为后备）。Opus 的空间推理能力——通过基于截图的反馈循环加以打磨——负责处理视觉输出。

Virtual Puppet Theater 除了开放式的游玩之外没有任何目标，Rene 说他对这个获奖项目没有产品计划。对他而言，这关乎学习和乐趣。"我和我最小的儿子一起测试了它，他玩得很开心。"Rene 说，"看着他与木偶互动、描述场景、对回应咯咯笑，这真的就是我所需要的全部用户验证了。"

他补充说，Virtual Puppet Theater 的源代码已在 GitHub 上以 MIT 许可证发布，"如果有人想把它做得更进一步。"

给其他构建者的建议：如果你参加黑客马拉松，要预留时间制作演示视频。

"制作一段 3 分钟的视频所需的时间远比你想象的要长。"Rene 说，他用 Claude 和 Hyperframes 创建和剪辑了 Virtual Puppet Theater 的视频，差点赶不上黑客马拉松的截止时间。"黑客马拉松 Discord 里很多人都警告过这一点，他们说得对。下次，我会把最后一整天专门留出来制作演示。"

Virtual Puppet Theater on GitHub

### "持续思考（Keep Thinking）"奖：MaestrIA，Benjamin Torralbo

Benjamin Torralbo 是在父亲 Juan Rodrigo Torralbo 身边当学徒长大的，父亲是智利奇洛埃（Chiloé）一位获认证的"大师傅（Maestro Mayor）"木匠。"我父亲有 30 年的手艺，曾修复过列入联合国教科文组织名录的教堂，但他对智利的体系来说仍然是隐形的，就像数十万其他手艺人一样。"Benjamin 说，"与此同时，需要做家庭维修的人不知道哪里出了问题、要花多少钱、该找谁，也不知道收费是否公道。"

他的 MaestrIA 黑客马拉松项目作为一款 Web 应用同时解决了两端的问题：它为普通人提供大师级的家庭维修诊断，同时给技艺娴熟的手艺人一条展示专长的途径。

借助 MaestrIA，用户给问题拍照、用语音或文字描述，并分享自己的位置。Claude 实时流式输出它的推理过程，在照片上叠加动画边界框，然后给出结构化诊断：什么坏了、材料、严重程度 1–5 级、项目预算和时间估算。随后智能体渲染一张按工种筛选的附近大师傅地图，同时第二个智能体起草一条待发送的 WhatsApp 消息。

MaestrIA 的技术核心是一个 JSON 文件，它被注入到每一次诊断中，包含 17 条诊断规则、7 种奇洛埃本地木材、16 个本地行业方言术语、19 个基准价格和 9 个手艺中常见的错误——全部从 Benjamin 与父亲数小时访谈中提炼而来。在完全不触碰系统提示词的情况下，这一个文件就把他的评测分数提升了 7 个点（相对人类大师傅的判断从 74% 提升到 81%），也正是 MaestrIA 能诊断出"alerce 木墙板上的上升潮气"而非泛泛的"木材损坏"的原因。

由于此前没有编程经验，Benjamin 说他的角色是工地领班，监督 Claude 的技术执行。"在编写任何功能之前，我让 Claude Code 设计规格说明、分阶段行动计划，以及安全模型：针对提示词注入（prompt injection）的输入消毒、速率限制、来源验证，以及作为单一事实来源的 Zod schema。"他说，"然后我逐个差异（diff）地审查每个功能。"

Benjamin 希望 MaestrIA 能扩展到新建工程、五金店集成、正式预算、合同、评价以及一套认证体系。最终，每个工种内部都会编码进它自己的"大师傅"，包括木匠、建筑师、水管工、电工和泥瓦匠。

他的奖励额度将用于开发该应用、把父亲的公司数字化作为一个实地试点，以及他自身的技术成长。"Claude Code 让一个来自奇洛埃、没有编程经验的 20 岁年轻人，构建出他自己父亲就能用的软件，并且能帮助智利另外 28 万名像他一样的大师傅。"他说，"它也为数百万一直拥有宝贵创意、却苦无途径将其实现的人打开了大门。"

给其他构建者的建议：先做评测，再做功能。

"我做过的最重要的一件事，就是针对父亲记录下真值（ground truth）的 12 个真实案例，构建了一个可审计的 9 维评测。"Benjamin 说，"是那个评测，而非我的直觉，告诉我什么有效、什么无效。如果我再参加一次黑客马拉松，评测会是第一个提交（commit）。"

### Claude 托管智能体（Claude Managed Agents）最佳应用奖：ARIA，Idriss Benguezzou 与 Adam Hnaien

大多数工厂里都有那么一位资深技师，仅凭机器发出的声音就能判断它是否快要坏了。获得"Claude 托管智能体最佳应用奖"的项目 ARIA（Adaptive Runtime Intelligence，自适应运行时智能），把一位经验丰富的维护工程师的直觉，转化成一套价格可负担、上手快的 AI 系统，持续监视工厂机器，并在故障一出现就生成定制的诊断和维修方案。

借助 ARIA，维护工程师上传制造商的 PDF，回答四个通俗语言的校准问题，15 分钟内整个工厂就被画像完毕。从那时起，五个智能体监视实时信号。如果某个智能体检测到故障、或预测故障即将发生，它就生成一份工单，分析组件、故障模式、紧急程度、所需部件和干预窗口。

这个项目的两位构建者都有现场工业经验，他们在黑客马拉松的"找队友" Discord 频道相遇。Idriss Benguezzou 是一位拥有数据/AI 硕士学位的法国工业软件工程师，他已经构思这个想法及其大部分架构有一段时间了。Adam Hnaien 是一名自学成才、对 Claude Code 和多智能体工作流颇有经验的工程学专业学生，他一眼就认出 ARIA 是工业维护领域一个有价值的解决方案。

Idriss 和 Adam 在黑客马拉松第二天全程处于规划模式，使用一个 GitHub Project 看板，在写下第一行代码之前就界定好每一个里程碑、议题和验收标准。"我们想从 M2 开始就以 200% 的状态投入。"Adam 说，"一天的规划，让我们在接下来的一周里得以执行，而不是即兴发挥。"

两人都估计 Claude Code 写了约 80% 的原始代码行，而他们亲手做出领域逻辑和设计决策。Idriss 负责阈值评估、知识库（KB）schema 和异常检测，因为他说："你没法靠提示词凭空知道一个维护技师实际会看什么。" Adam 承担了用户体验、视觉语言和 ARIA 的"星座（constellation）"概念，因为他说："你没法靠提示词凭空获得品味。"

托管智能体处理了智能体基础设施。"如果没有 Claude 托管智能体，我们这一周就得用来构建 Anthropic 已经托管好的基础设施：一个沙箱化的 Python 环境、安全执行、会话持久化、MCP 分派。"Adam 说，"而我们却用这一周来围绕这套基础设施构建产品。这就是五天交付 ARIA 和五周交付 ARIA 的区别。"

黑客马拉松结果公布后，正在攻克同一问题的公司纷纷就这个项目找上门来。Idriss 将把 ARIA 的智能体架构、知识库 schema 和信号管道融入他自己的工业物联网（IoT）平台；他的额度将用于更多的构建与试验。至于 Adam，他的计划是继续探索工业智能体 AI 领域的机会，并用 API 额度持续构建和试验。

给其他构建者的建议：让 Claude 来审计。Idriss 说，在构建下一样东西之前，先让 Claude 找出你已经构建的东西是否有任何问题。"这个循环被低估了。"

ARIA on GitHub

了解我们的 Claude 社区项目，包括聚会、黑客马拉松等。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| Claude Code | Claude Code |
| Claude Design | Claude Design |
| schematic | 电路原理图 |
| boardview | 板视图 |
| electrical graph | 电气图 |
| spec | 规格说明 |
| plan | 计划 |
| multi-agent mode | 多智能体模式 |
| spatial reasoning | 空间推理 |
| metacognitive loop | 元认知循环 |
| Intent-Diff Review | 意图—差异审查 |
| drift / revision / bug | 偏移 / 修订 / 缺陷 |
| dashboard | 仪表盘 |
| autocomplete | 自动补全 |
| WebSocket server | WebSocket 服务器 |
| hand tracking | 手部追踪 |
| prompt injection | 提示词注入 |
| input sanitization | 输入消毒 |
| rate limiting | 速率限制 |
| single source of truth | 单一事实来源 |
| diff | 差异 |
| eval | 评测 |
| ground truth | 真值 |
| commit | 提交 |
| knowledge base (KB) | 知识库 |
| anomaly detection | 异常检测 |
| work order | 工单 |
| failure mode | 故障模式 |
| session persistence | 会话持久化 |
| MCP dispatching | MCP 分派 |
| industrial IoT platform | 工业物联网平台 |
| full-stack product | 全栈产品 |
