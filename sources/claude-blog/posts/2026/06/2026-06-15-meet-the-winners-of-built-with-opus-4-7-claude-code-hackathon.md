---
source: claude-blog
source_url: https://claude.com/blog/meet-the-winners-of-built-with-opus-4-7-claude-code-hackathon
published_at: 2026-06-15
category: Claude Code
title_en: Meet the winners of the Built with Opus 4.7 Claude Code hackathon
title_zh: 来认识 Built with Opus 4.7 Claude Code 黑客松的获奖者
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 3
source_image_count: 0
---

# 来认识 Built with Opus 4.7 Claude Code 黑客松的获奖者

> • Meet the winners of the Built with Opus 4.7 Claude Code hackathon

> • 来源：Claude Blog，2026-06-15
> • 原文链接：https://claude.com/blog/meet-the-winners-of-built-with-opus-4-7-claude-code-hackathon
> • 分类：Claude Code

## 核心要点

- 一等奖 Medkit 是一款面向住院医师和初级医生的学习工具，在游戏化的医疗诊所中模拟真实的患者接诊场景。
- 二等奖 Wrench Board 借助 Opus 4.7 理解可视化电路图的新能力，帮助独立技术人员排查复杂的电子维修问题。
- 三等奖 Maieutic 是一款引导学生在关键时刻放慢节奏、先讲清思路再写代码的 IDE，帮助学生闭合元认知循环。
- 「最具创意 Opus 4.7 应用奖」由 Virtual Puppet Theater 获得，将摄像头视频和语音转换为动态交互式木偶剧。
- 「保持思考奖」颁给 MaestrIA，它为普通人提供大师级的家庭维修诊断，同时让熟练匠人有渠道展示专业能力。
- 「最佳 Claude Managed Agents 应用奖」由 ARIA 获得，它持续监测工厂机器并在故障出现时即时生成诊断和维修方案。
- 多位获奖者强调「先做评估、先做规划」以及把 Claude 当作思考伙伴的重要性。

## 正文

从医学培训、电子设备维修，到编程教育和工厂维护，看看我们最近这场线上黑客松获奖者们打造的项目。

> From medical training and electronics repair to coding education and factory maintenance, see the projects built by the winners of our latest virtual hackathon.

上周，我们举办了 Claude Build Day——我们最新一期的黑客松，开发者们齐聚旧金山，使用 Claude Opus 4.8 将他们的想法付诸实践。

> Last week, we hosted Claude Build Day , our latest hackathon where builders got together in San Francisco to put their ideas to work using Claude Opus 4.8.

在等待他们的成果揭晓的同时，我们与 Built with Opus 4.7 黑客松的获奖者们聊了聊他们的项目。他们的项目涵盖了医学培训、电子设备维修、计算机科学教育、互动游戏、家居修缮以及工厂维护。

> While we wait to see what they built, we chatted with the winners of our Built with Opus 4.7 hackathon about their projects. They tackled medical training, electronics repair, computer science education, interactive play, home repair, and factory maintenance.

祝贺各位获奖者以及所有参与者！我们希望他们的想法能够给你带来启发。

> Congratulations to the winners and to everyone who participated! We hope their ideas will inspire you.

### 第一名：Medkit，Bedirhan Keskin

> First place: Medkit , Bedirhan Keskin

Bedirhan Keskin 是一位常驻伊斯坦布尔、从医生转型为软件工程师的人，他使用 Claude 托管智能体（Claude Managed Agents）构建了 Medkit：一款面向住院医师或初级医生的学习工具，通过游戏化的医疗诊所模拟真实的患者接诊场景。

> Bedirhan Keskin, an Istanbul-based physician-turned-software engineer, used Claude Managed Agents to build Medkit: a learning tool for medical residents or junior doctors, simulating real-life patient encounters in a gamified medical clinic.

"当你独自待在急诊科，有 50 名患者在等候，而你意识到有些病例在医学院里从未练习过时，你最终只能在真实患者身上实时练习。"Bedirhan 说。

> "When you're alone in an emergency department with 50 patients waiting and you realize there are cases you never practiced in medical school, you end up practicing them on real patients in real time," says Bedirhan.

借助 Medkit，医学生可以练习诊断和治疗模拟患者，用这款工具采集病史、开具化验、读取影像、做出诊断并开处方。在结束时，一个智能体评分系统会依据与专科考官所用相同的已发布临床指南，对整个接诊过程进行评估。

> With Medkit, medical students practice diagnosing and treating simulated patients, using the tool to take medical history, order labs, read imaging, diagnose, and prescribe treatment. At the end, an agentic grader assesses the full encounter against the same published clinical guidelines that a board examiner would use.

Bedirhan 在四个独立的 Claude Code 会话中构建了 Medkit（语音引擎、内容生成、3D 游戏层和核心应用），让每个会话的上下文保持清晰，并同时推进所有部分。他遵循"说，而不是打字"的方式，几乎完全靠语音工作。

> Bedirhan built Medkit across four separate Claude Code sessions (voice engine, content generation, 3D game layer, and a core app), keeping each context clean and progressing on all at once. He followed a “talk, don’t type” approach, working almost entirely by voice.

Medkit 已开始获得关注，三所医学院和一家制药公司（均位于伊斯坦布尔）将在未来几周内启动试点。

> Medkit is already gaining traction, with three medical faculties and a pharma company, all based in Istanbul, set to start running pilots in the coming weeks.

给其他构建者的建议：把 Claude 当作思想伙伴，而不仅仅是编码智能体。

> Advice to other builders: Work with Claude as a thought partner, not just a coding agent.

Bedirhan 最初的本能是自托管语音引擎，但 Claude 建议使用云服务商以加快进度。"我最看重 Claude 的一点是，它不仅是代码生成器，更是帮我发现那些原本会错过的选项的思想伙伴，"他说。

> Bedirhan’s first instinct was to self-host the voice engine, but Claude suggested using a cloud provider to move faster. “What I value most about Claude is it’s not just a code generator, but a thought partner helping me see options I'd otherwise miss,” he says.

Medkit 在 Github 上

> Medkit on Github

### 第二名：Wrench Board，Alexis Chapellier

> Second place: Wrench Board , Alexis Chapellier

来自法国雷尼耶-埃塞里（Reignier-Ésery）的 Alexis Chapellier 在创建 RepairMind 之前，曾多年从事电子设备维修。RepairMind 是一个面向维修店的 AI 驱动管理平台。他在 Opus 4.7 黑客马拉松中的项目 Wrench Board，帮助独立技术人员搞定复杂的维修。用户放入一张电路原理图和一张板视图（boardview），并描述故障现象，智能体便会生成一张统一的电气图，对其进行推理，指出需要探测的确切焊盘，读取测量值，并不断更新假设，直到诊断出问题。

> Alexis Chapellier from Reignier-Ésery, France, spent years fixing electronics before creating RepairMind , an AI-powered management platform for repair shops. His Opus 4.7 hackathon project, Wrench Board , helps independent technicians figure out complex repairs. Users drop in a schematic and a boardview and describe the symptoms, and the agent creates a unified electrical graph, reasons over it, points to the exact pad to probe, reads measurements, and updates its hypotheses until it diagnoses the issue.

Alexis 在 Claude Design 中为 Wrench Board 制作原型，将应用的各项职责（设计、原理图导入、板视图、诊断智能体）拆分开来，先为每一项生成规格说明，再生成计划。他在 Claude Code 的多智能体模式下执行，每一步都做基准测试，调试时并行运行五到六个智能体，每个领域配一个专属智能体。

> Alexis prototyped Wrench Board in Claude Design, separating the app’s responsibilities (design, schematic ingestion, boardview, diagnostic agent) and producing first a spec and then a plan for each one. He executed in Claude Code’s multi-agent mode, benchmarking at every step by running five or six agents in parallel during debugging, with one dedicated agent per domain.

Alexis 押下的大注，是 Opus 4.7 新具备的理解可视化原理图的能力；他说当他让模型在主板上追踪一条电源路径时，他就知道这事成了。

> Alexis’s big bet was on Opus 4.7’s new ability to understand visual schematics; he says he knew it was working when he asked the model to trace a power path on a motherboard.

“我看着 Wrench Board 的板视图一步步亮起来，箭头出现，组件被指出，名称浮现。那一刻，我明白这个想法立得住，”他说。

> “I watched Wrench Board’s boardview light up step by step, arrows appearing, components getting pointed at, names surfacing. At that moment, I understood the idea was holding up," he says.

Wrench Board 的下一阶段，是建立一个由有兴趣试用该应用的电子维修人员、以及能够用现场经验丰富该工具的专家组成的社区。他的 Claude 额度（credits）将投入到 RepairMind、这些首批用户，以及当前正在推进的全部基础设施上。

> Wrench Board’s next phase is to build a community of electronics repairers interested in trying the app and experts able to enrich the tool with their field experience. His Claude credits will go toward RepairMind, those first users, and all the infrastructure currently in flight.

“这次黑客马拉松证明，一个从维修店走出来的自学者，可以在五天内交付一套雄心勃勃的系统，”报名时还在申请“糊口工作”的 Alexis 说。“Claude Code 会放大任何有想法、并有耐力去执行的人，无论其起点如何。”

> “This hackathon is proof that a self-taught person coming out of a repair shop can ship an ambitious system in five days,” says Alexis, who was applying for “survival jobs” when he entered. “Claude Code amplifies whoever has an idea and the endurance to execute on it, regardless of their starting point.”

给其他开发者的建议：在头脑风暴中深挖，并对模型提出反驳。

> Advice to other builders: Go deep in the brainstorm and push back on the model.

Alexis 使用 Superpowers——一个集成在 Claude 中的技能框架，用于把“先头脑风暴、后做计划”的步骤结构化，有时并行运行多个头脑风暴，以在不同方向上同时推进。他从 Claude Design 起步，然后用内置按钮直接共享项目，移交给 Claude Code，并在模型说“不行”时推它一把。

> Alexis uses Superpowers , a skills framework integrated into Claude that structures the brainstorm-then-plan steps, sometimes running brainstorms in parallel to make progress on different fronts. He starts in Claude Design, then hands off to Claude Code using the built-in button that shares the project directly, and pushes the model when it tells him no.

“在黑客马拉松期间，Claude 好几次告诉我这个或那个在剩余时间里做不完。实际上，我时间多得很，”他说。“你得知道怎么对它说，我无论如何都要试一试。”

> “During the hackathon, Claude told me several times that this or that wouldn't fit in the time available. In reality, I had plenty of time,” he says. “You have to know how to tell it, I'm going to try anyway. "

GitHub 上的 Wrench Board

> Wrench Board on GitHub

### 第三名：Maieutic，Paula Vásquez-Henríquez

> Third place: Maieutic , Paula Vásquez-Henríquez

Paula Vásquez-Henríquez 在智利康塞普西翁的发展大学（Universidad del Desarrollo）教授计算机科学，她说在过去两年里，她看到越来越多的学生在不理解自己代码的情况下通过测试。

> Paula Vásquez-Henríquez, who teaches computer science at Universidad del Desarrollo in Concepción, Chile, says over the past two years she is seeing more students pass tests without understanding their own code.

"现在学生用 AI 制造代码，但完全不知道代码做了什么，"她说。"他们从来没学会精确地陈述一个问题、在编码前起草一份计划，或批判性地阅读自己的代码、注意它在哪里偏离了原本的意图。自动补全在他们还没把问题想清楚之前就交出了能运行的代码，于是元认知循环——那种思考你自己思考的过程，才是真正造就程序员的东西——永远无法闭合。他们毕业时能生成代码，却无法对代码进行推理。"

> "Students now use AI to manufacture code, but they have no idea what the code does," she says. “They never learn to state a problem precisely, to draft a plan before coding, or to read their own code critically and notice where it drifted from what they intended. The autocomplete delivers working code before they've even finished forming the question, so the metacognitive loop, the thinking-about-your-thinking that actually creates a programmer, never closes. They graduate able to generate code but not reason about it.”

Paula 目前正在攻读人工智能博士学位，研究学生与 AI 的交互模式，她参加这次黑客松是为了从学生和教师两个视角解决这个问题。

> Paula, who is currently working on a PhD in Artificial Intelligence researching student–AI interaction patterns, entered the hackathon to solve this problem from both student and instructor perspectives.

Maieutic 是一款旨在让学生在关键时刻放慢脚步的集成开发环境（IDE）。学生必须先用平实的语言描述自己的程序应该做什么，然后才能写任何代码；Claude 会提出有针对性的澄清问题，并保持编辑器锁定，直到规格说明（spec）足够详细，以至于一位合格的程序员无需猜测即可实现它。

> Maieutic is an IDE designed to make students slow down at key moments. Students must describe in plain language what their program should do before writing any code; Claude asks targeted clarifying questions and keeps the editor locked until the spec is detailed enough that a competent programmer could implement it without guessing.

学生随后可以开始编写 Python，但自动补全是关闭的；聊天面板会直接回答查阅类问题，但对推理类问题则以反问而非给出修复来回应，拒绝替学生思考。

> Students can then start writing Python but autocomplete is off; a chat panel answers reference questions directly but responds to reasoning questions with counter-questions rather than fixes, refusing to do the student's thinking for them.

意图差异审查（Intent-Diff Review）是这个工具的核心，它让 Claude 把规格说明与最终代码进行比对，将每处分歧归类为偏移（drift）、修订（revision）或缺陷（bug），然后抛出一个中立、不带指责意味的问题，促使学生自己解释这个问题。

> The Intent-Diff Review, the core of the tool, has Claude compare the spec against the final code, classify each divergence as drift, revision, or bug, and then surface a neutral, non-accusatory question prompting the student to explain the issue themselves.

对于教师，一个实时仪表板为每名学生显示一行，附带一句话的认知摘要（例如"已写过三次规格说明，仍未考虑空输入"）。教师可以点击单个学生，查看其与 Claude 的具体交互，系统还会分析整个班级的情况，识别并呈现全班共有的误解，让教师能够弥补这一缺口。

> For instructors, a live dashboard shows one row per student with a one-sentence cognitive summary (e.g., "written the spec three times, still hasn't considered empty input"). Teachers can click on individual students to monitor their specific interactions with Claude, which also analyzes the full cohort to identify and surface any shared misunderstandings across the whole class so instructors can close that gap.

黑客松结束后，休斯顿大学的研究人员已联系她洽谈合著论文，Paula 正用她的奖励额度来进一步开发这个工具。她说黑客松那一周让她看到，从理解一个问题到为它交付一个工具之间的差距已经坍塌。

> Since the hackathon ended, researchers at the University of Houston have reached out about co-authoring a paper, and Paula is putting her prize credits toward developing the tool further. She says hackathon week showed her that the gap between understanding a problem and shipping a tool for it has collapsed.

"我是智利康塞普西翁的一名教育工作者，不在硅谷，"她说。"我能在一周内交付一个可运行的全栈产品，是因为这些工具让我能够留在我真正擅长的角色里，而它们处理其余的事情。最贴近真实问题的人现在可以直接为这些问题构建解决方案。"

> “I’m an educator in Concepcion, Chile, not Silicon Valley,” she says. “I shipped a working full-stack product in a week because the tools let me stay in the role I'm genuinely expert in while they handle the rest. The people closest to real problems can now build for them directly.”

给其他构建者的建议：先思考，再构建。

> Advice to other builders: Think before you build.

这个项目是 Paula 在亲身实践自己的理念：先明确规格，再构建。"Maieutic 之所以存在，是因为学生直接跳到写代码，而我把它做好的唯一办法，就是拒绝自己也那样做，"她说。她用两天时间纯粹做思考工作，在写下一行代码之前先完成设计规格和技术规格。

> This project was Paula dogfooding her own philosophy: specify before you build. “Maieutic exists because students jump straight to code, and the only way I built it well was by refusing to do exactly that myself,” she says. She dedicated two days to pure thought work, creating the design spec and the technical spec before writing a single line of code.

"那两天的规格工作在当时感觉很慢，黑客松里有一种立刻就要开始交付的真实压力，但正是它们让那一周余下的时间能够快速推进，"她说。

> “Those two days of spec felt slow at the time, there's real pressure in a hackathon to start shipping immediately, but they were what let the rest of the week move fast,” she says.

### Opus 4.7 最具创意应用：虚拟木偶剧场，Rene Hangstrup Møller

> Most Creative Use of Opus 4.7: Virtual Puppet Theater, Rene Hangstrup Møller

全栈开发者 Rene Hangstrup Møller 对 Opus 4.7 的空间推理能力深感兴趣，于是打造了虚拟木偶剧场（Virtual Puppet Theater），这是一款基于浏览器的应用，能把网络摄像头视频和语音变成动态的交互式木偶戏。一个实时动画木偶会模仿用户的动作，同时第二个由 AI 驱动的伙伴木偶会与用户对话；口头提示还能即时变换场景并生成 3D 道具。

> Intrigued with Opus 4.7’s spatial reasoning capabilities, full stack developer Rene Hangstrup Møller built Virtual Puppet Theater, a browser-based app that turns webcam video and voice into a dynamic interactive puppet show. A real-time animated puppet mirrors a user’s movements while a second AI-driven companion puppet banters with the user; spoken prompts can transform the scenery and spawn 3D props on the fly.

Rene 在整个流程中都使用了 Claude：概念讨论、规划和代码编写，而他自己负责导演、架构、审查和决策。该应用基于 Bun、Vite 和 TypeScript，使用 MediaPipe 手部追踪（在 WASM 中运行）和 Three.js 以 60 fps 的帧率在 3D 中渲染木偶舞台。一个小型 WebSocket 服务器通过 Anthropic SDK 连接到 Claude Opus 4.7，以驱动 AI 木偶的对话并即时生成 3D 道具，而语音输入由 Web Speech API 处理、输出则由 ElevenLabs 处理（以浏览器语音合成作为后备方案）。Opus 的空间推理能力通过基于截图的反馈回路加以打磨，负责处理视觉输出。

> Rene used Claude across the full pipeline: concept discussion, planning, and code writing, while he handled direction, architecture, review, and decision-making. The app is based on Bun, Vite, and TypeScript, using MediaPipe hand tracking (running in WASM) and Three.js to render the puppet stage in 3D at 60 fps. A small WebSocket server connects to Claude Opus 4.7 via the Anthropic SDK to drive the AI puppet's dialogue and generate 3D props on the fly, while voice is handled by the Web Speech API for input and ElevenLabs for output (with browser speech synthesis as a fallback). Opus's spatial reasoning capabilities, refined through a screenshot-based feedback loop, handle the visual output.

虚拟木偶剧场除了开放式的游玩之外没有其他目标，Rene 表示她对这个获奖项目没有产品规划。对他而言，这关乎学习和乐趣。"我和我最小的儿子一起测试，他玩得很开心，"Rene 说。"看着他与木偶互动、描述场景、对回应咯咯笑，这真的是我所需要的唯一用户验证。"

> There's no objective in Virtual Puppet Theater beyond open-ended play and Rene says she has no product plans for his winning project. For him, it was about learning and fun. "I tested it with my youngest son and he had a blast,” Rene says. “Seeing him interact with the puppet, describe scenes, and giggle at the responses was really the only user validation I needed.”

他补充说，虚拟木偶剧场的源代码已在 GitHub 上以 MIT 许可证开放，"如果有人想把它做得更进一步的话。"

> Virtual Puppet Theater’s source code is available on GitHub under MIT licensing, he adds, “if anyone wants to take it further.”

给其他开发者的建议：如果你参加黑客松，要留出时间制作演示视频。

> Advice to other builders: If you’re participating in a hackathon, plan time to create the demo video.

‍ "制作一段 3 分钟的视频所花的时间远比你想象的要长，"Rene 说，并指出他在黑客松截止期限前用 Claude 和 Hyperframes 制作并剪辑了虚拟木偶剧场的视频。"黑客松 Discord 里很多人都提醒过这一点，他们说得没错。下次我会把最后一整天都留出来专门用于制作演示视频。"

> ‍ "It takes way longer than you think to produce a 3-minute video,” Rene says, noting that he went up against the hackathon deadline using Claude and Hyperframes to create and edit his Virtual Puppet Theater video. “Many people in the hackathon Discord warned about this, and they were right. Next time, I'd reserve that entire last day just for producing the demo."

GitHub 上的虚拟木偶剧场

> Virtual Puppet Theater on Github

### "持续思考"奖：MaestrIA，Benjamin Torralbo

> "Keep Thinking" Prize: MaestrIA , Benjamin Torralbo

Benjamin Torralbo 从小跟随父亲 Juan Rodrigo Torralbo 当学徒，他父亲是智利奇洛埃岛（Chiloé）一位持证的木匠大师傅（Maestro Mayor）。"我父亲有 30 年的手艺，修复过列入联合国教科文组织名录的教堂，但在智利的体制中依然是隐形的，和成千上万其他手艺人一样，"Benjamin 说。"与此同时，需要修缮房屋的人不知道问题出在哪、要花多少钱、该找谁，也不知道收费是否公道。"

> Benjamin Torralbo grew up apprenticing alongside his father, Juan Rodrigo Torralbo, a certified Maestro Mayor carpenter in Chiloé, Chile. “My father has 30 years of craft, has restored UNESCO-listed churches, but is still invisible to the Chilean system, like hundreds of thousands of other tradespeople,” Benjamin says. “Meanwhile, people needing home repairs don't know what is wrong, what it costs, who to call, and whether they're being charged fairly.”

他在黑客松上的 MaestrIA 项目同时解决了两端的问题：这是一款 Web 应用，既为普通人提供大师级的房屋维修诊断，也为技艺娴熟的手艺人提供展示专业能力的途径。

> His MaestrIA hackathon project solves both sides as a web app that gives ordinary people master-level home repair diagnostics while giving skilled tradespeople a way to demonstrate expertise.

使用 MaestrIA 时，用户拍下问题的照片，用语音或文字描述，并分享所在位置。Claude 实时流式输出它的推理，在照片上叠加动态的边界框（bounding box），然后给出结构化诊断：哪里坏了、材料是什么、严重程度 1–5 级、项目预算和时间估算。随后智能体（agent）会渲染出一张附近 maestros 的地图，并按工种筛选，同时另一个智能体起草一条可发送的 WhatsApp 消息。

> With MaestrIA, users photograph their problem, describe it in voice or text, and share their location. Claude streams its reasoning in real time with animated bounding boxes over the photos, then delivers structured diagnoses: what's broken, material, severity 1–5, project budget and time estimate. The agent then renders a map of nearby maestros filtered by trade while a second agent drafts a WhatsApp message to send.

MaestrIA 的技术核心是一个 JSON 文件，会注入到每一次诊断中，其中包含 17 条诊断规则、7 种奇洛埃原生木材、16 个当地行业方言术语、19 个基准价格，以及该手艺的 9 个常见错误，全部从 Benjamin 与父亲数小时访谈中提炼而来。在不改动系统提示词（system prompt）的前提下，这一个文件就让他的评估（eval）成绩提升了七个点（相对人类大师傅的判断从 74% 升到 81%），也正因如此，MaestrIA 能够诊断出"alerce 木墙板上的上升潮气（rising damp）"，而不是泛泛的"木材受损"。

> MaestrIA’s technical heart is a JSON file, injected into every diagnosis, that contains 17 diagnostic rules, 7 native Chilote woods, 16 terms of local trade dialect, 19 benchmark prices, and 9 common mistakes of the craft all distilled from hours of interviews Benjamin did with his father. Without touching the system prompt, that single file lifted his eval seven points (74% to 81% against a human master's judgment) and is how MaestrIA can diagnose "rising damp on alerce wood siding" instead of generic "wood damage."

在此之前没有任何编程经验的 Benjamin 说，他的角色是监督 Claude 技术执行的工地工头。"在写任何功能之前，我都让 Claude Code 设计规格、分阶段的行动计划和安全模型：针对提示注入（prompt injection）的输入清洗、速率限制、来源校验，以及作为唯一事实来源的 Zod 模式（schema），"他说。"然后我逐个 diff 地审查每一项功能。"

> With no prior programming experience, Benjamin says his role was site foreman overseeing Claude’s technical execution. “Before writing any feature, I asked Claude Code to design the specs, the staged action plan, and the security model: input sanitization against prompt injection, rate limiting, origin validation, and Zod schemas as the single source of truth,” he says. “Then I reviewed each feature diff by diff.”

Benjamin 希望 MaestrIA 能拓展到新建工程、五金店集成、正式预算、合同、评价以及一套认证体系。最终，每个工种内部都会编码一位自己的大师傅（Maestro Mayor），包括木匠、建筑师、水管工、电工和泥瓦匠。

> Benjamin wants MaestrIA to grow into new builds, hardware-store integration, formal budgets, contracts, reviews, and a certification system. Eventually, each trade will have its own Maestro Mayor encoded inside, including carpenters, architects, plumbers, electricians, and masons.

他把奖金用于开发这款应用、把父亲的公司数字化作为一个真实试点，以及提升自己的技术能力。"Claude Code 让一个来自奇洛埃、没有编程经验的 20 岁年轻人，能够构建出自己父亲就能使用的软件，并且能帮助智利另外 28 万名像他一样的 maestros，"他说。"它也为数百万一直有宝贵想法却苦于无从实现的人打开了大门。"

> His prize credits go toward developing the app, digitizing his father's company as a live pilot, and his own technical growth. “Claude Code lets a 20-year-old from Chiloé with no programming experience build software that his own dad can use and that can help 280,000 more maestros like him in Chile,” he says. “And it opens the door for millions of people who've always had valuable ideas but no way to bring them to life."

给其他构建者的建议：先做评估，后做功能。

> Advice to other builders: Eval first, features later.

"我做过的最重要的一件事，就是针对 12 个真实案例构建了一套可审计的 9 维度评估，标准答案由我父亲记录，"Benjamin 说。"是这套评估、而不是我的直觉，告诉我什么有效、什么无效。如果我再参加一次黑客松，评估会是我的第一次提交。"

> “The single most important thing I did was build an auditable 9-dimension eval against 12 real cases with ground truth recorded by my dad,” Benjamin says. “That eval, not my intuition, told me what was working and what wasn't. If I did another hackathon, the eval would be the first commit.”

### Claude 托管智能体（Claude Managed Agents）最佳应用：ARIA，Idriss Benguezzou 与 Adam Hnaien

> Best Use of Claude Managed Agents: ARIA , Idriss Benguezzou & Adam Hnaien

大多数工厂都有这样一位资深技师：仅凭机器发出的声音，就能判断它是不是快要坏了。荣获“Claude 托管智能体最佳应用”奖的项目 ARIA（自适应运行时智能，Adaptive Runtime Intelligence）把一位经验丰富的维护工程师的直觉，转化为一套价格亲民、部署迅速的 AI 系统，持续监测工厂机器，并在故障出现的瞬间生成定制化的诊断和维修方案。

> Most factories have that one veteran technician who can tell when a machine is about to break, just by the sound it makes. The Best Use of Claude Managed Agents prize-winning project, ARIA (Adaptive Runtime Intelligence) turns an experienced maintenance engineer’s instincts into an affordable, fast-to-set-up AI system that continuously watches factory machines and generates custom diagnostics and repair plans the moment trouble appears.

使用 ARIA 时，维护工程师上传一份厂商的 PDF，回答四个通俗易懂的校准问题，15 分钟内便完成对整个工厂的画像。从这一刻起，五个智能体开始监测实时信号。如果某个智能体检测到故障，或预测故障即将发生，它就会生成一份工单，分析涉及的部件、故障模式、紧急程度、所需零件以及介入时间窗口。

> With ARIA, a maintenance engineer uploads a manufacturer's PDF, answers four plain-language calibration questions, and within 15 minutes the plant is profiled. From there, five agents watch live signals. If an agent detects a failure or predicts one is imminent, it produces a work order analyzing component, failure mode, urgency, parts, and intervention window

该项目的两位开发者都有车间一线的工业经验，他们在黑客松的找队友 Discord 频道里相识。Idriss Benguezzou 是一位拥有数据/AI 硕士学位的法国工业软件工程师，他此前已经构思这个想法并设计了其大部分架构。Adam Hnaien 是一名自学成才的工程专业学生，熟悉 Claude Code 和多智能体工作流，他一眼就看出 ARIA 是工业维护领域极有价值的解决方案。

> The project’s builders, both of whom have on-the-floor industrial experience, met in the hackathon’s teammate-finding Discord channel. Idriss Benguezzou, a French industrial-software engineer with a Master's in data/AI, had been mapping out the idea and most of its architecture for a while. Adam Hnaien, a self-taught engineering student experienced with Claude Code and multi-agent workflows, immediately recognized ARIA as a valuable solution for industrial maintenance.

Idriss 和 Adam 在黑客松第二天全程处于规划模式，使用 GitHub 项目看板，在写下第一行代码之前就梳理好每一个里程碑、议题和验收标准。Adam 说：“我们希望从 M2 阶段起就以 200% 的状态投入。用一天来规划，让我们能把这一周剩下的时间都花在执行上，而不是临场发挥。”

> Idriss and Adam spent all of the hackathon’s second day in planning mode with a GitHub Project board, scoping every milestone, issue, and acceptance criterion before writing the first line of code. “We wanted to go in at 200% from M2 onward,” Adam says. “One day of planning let us spend the rest of the week executing, not improvising.”

两人都估计，约 80% 的原始代码是 Claude Code 写的，而他们亲手做出领域逻辑和设计决策。Idriss 负责阈值评估、知识库（KB）模式和异常检测，因为他说：“你没法靠提示词就摸清维护技师实际会关注什么。”Adam 负责用户体验、视觉语言以及 ARIA 的“星座”概念，因为他说：“你没法靠提示词就提示出品味。”

> Both estimate that Claude Code wrote ~80% of the raw lines while they made domain logic and design decisions by hand. Idriss handled threshold evaluation, KB schema, and anomaly detection because, he says, “you can't prompt your way to knowing what a maintenance technician actually looks at." Adam took on UX, visual language, and ARIA’s constellation concept because, he says, “you can't prompt your way to taste.”

托管智能体负责处理智能体基础设施。Adam 说：“要是没有 Claude 托管智能体，我们这一周就得去搭建 Anthropic 已经托管好的基础设施：沙箱化的 Python 环境、安全执行、会话持久化、MCP 调度。而我们反过来把这一周用在围绕这套基础设施打造产品上。这就是用五天交付 ARIA 和用五周交付 ARIA 的区别。”

> Managed Agents handled agent infrastructure. “Without Claude Managed Agents, we'd have spent the week building infrastructure that Anthropic already hosts: a sandboxed Python environment, secure execution, session persistence, MCP dispatching,” Adam says. “Instead, we spent that week building the product around that infrastructure. That's the difference between shipping ARIA in five days and shipping ARIA in five weeks.”

黑客松结果公布后，正在攻克这一难题的公司主动就该项目与他们取得了联系。Idriss 会把 ARIA 的智能体架构、知识库模式和信号流水线整合进他自己的工业物联网平台；他获得的额度将用于更多的开发和实验。至于 Adam，他打算继续探索工业智能体 AI 领域的机会，并用 API 额度继续开发和实验。

> After the hackathon’s results were announced, companies working on exactly this problem reached out about the project. Idriss will fold ARIA's agent architecture, KB schema, and signal pipeline into his own industrial IoT platform; his credits will go toward more building and experimentation. As for Adam, his plan is to continue exploring opportunities in industrial agentic AI and use the API credits to continue building and experimenting.

给其他开发者的建议：让 Claude 来审计。Idriss 说，在构建下一个东西之前，先让 Claude 检查你已经构建的内容有没有问题。“这个循环被严重低估了。”

> Advice to other builders: Let Claude audit . Ask Claude to find if there’s anything wrong with what you've already built before building the next thing, says Idriss. “That loop is underrated.”

ARIA 在 GitHub 上

> ARIA on GitHub

了解我们的 Claude 社区项目，包括线下聚会、黑客松等更多活动。

> Learn about our Claude Community programs, including meetups, hackathons, and more.

‍

> ‍

## 术语对照

| English | 中文 |
|---|---|
| hackathon | 黑客松 |
| Claude Managed Agents | Claude Managed Agents（托管智能体） |
| medical resident | 住院医师 |
| agentic grader | 智能体评分器 |
| clinical guidelines | 临床指南 |
| voice engine | 语音引擎 |
| thought partner | 思考伙伴 |
| schematic | 电路图 |
| boardview | 板视图 |
| electrical graph | 电气图 |
| pad | 焊盘 |
| multi-agent mode | 多智能体模式 |
| spec | 规格 |
| spatial reasoning | 空间推理 |
| metacognitive loop | 元认知循环 |
| autocomplete | 自动补全 |
| Intent-Diff Review | 意图—差异审查 |
| drift / revision / bug | 偏移 / 修订 / 缺陷 |
| dashboard | 仪表盘 |
| hand tracking | 手部追踪 |
| WebSocket server | WebSocket 服务器 |
| system prompt | 系统提示词 |
| prompt injection | 提示注入 |
| rate limiting | 速率限制 |
| schema | 模式 |
| eval | 评估 |
| ground truth | 标准答案 |
| commit | 提交 |
| failure mode | 故障模式 |
| work order | 工单 |
| knowledge base (KB) | 知识库 |
| anomaly detection | 异常检测 |
| sandboxed environment | 沙箱化环境 |
| session persistence | 会话持久化 |
| MCP dispatching | MCP 分发 |
| industrial IoT platform | 工业物联网平台 |
