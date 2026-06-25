---
source: claude-blog
source_url: https://claude.com/blog/meet-the-winners-of-our-claude-opus-4-8-build-day-hackathon
published_at: 2026-06-17
category: Claude Code
title_en: Meet the winners of our Claude Opus 4.8 Build Day hackathon
title_zh: 来认识我们 Claude Opus 4.8 Build Day 黑客松的获奖者
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 3
source_image_count: 3
---

# 来认识我们 Claude Opus 4.8 Build Day 黑客松的获奖者

> • Meet the winners of our Claude Opus 4.8 Build Day hackathon

> • 来源：Claude Blog，2026-06-17
> • 原文链接：https://claude.com/blog/meet-the-winners-of-our-claude-opus-4-8-build-day-hackathon
> • 分类：Claude Code

## 核心要点

- 6 月 13 日，超过 300 名创业者与开发者齐聚旧金山，参加为期 12 小时、以 Claude Opus 4.8 为主题的黑客松；1500 多人报名，310 人参与，每人获得 500 美元额度。
- 一等奖 Tekton：将历史木结构建筑重建为 3D 模型，并把每个部件追溯到有据可查的来源，全程在 Opus 4.8 上完成验证。
- 二等奖 Sim Francisco：基于美国人口普查数据构建的 1 万名合成居民的旧金山人口模型，可对整个合成选民群体进行实时民意调查。
- 三等奖 Custom Universe：用手机拍一张照片即可生成可放入场景、可重新风格化的 3D 物体，面向机器人实验室的合成数据需求。
- 三支队伍均计划开源或免费提供其项目，分别面向文化保护、模型训练与机器人研究。
- 各队的共同经验：先规划整个项目再动手、不要止步于第一个可行方案、用 Claude 来选择工具而不仅仅是写代码。

## 正文

从重建唐代建筑，到对一座合成的旧金山进行民意调查，来看看在我们最新一届黑客松上，获奖者们如何用 Claude Opus 4.8 在一天之内造出他们的作品。

> From reconstructing Tang Dynasty architecture to polling a synthetic San Francisco, see what the winners of our latest hackathon built with Claude Opus 4.8 in a day.

6 月 13 日，我们邀请了 300 多位创业者和开发者来到旧金山，参加一场使用 Claude Opus 4.8、为时 12 小时的黑客马拉松。报名人数超过 1500 人，最终 310 人参加，其中许多人远道而来，每人获得 500 美元额度，用一天时间把一个想法变成可运行的演示。

> On June 13, we brought more than 300 founders and builders to San Francisco for a 12-hour hackathon with Claude Opus 4.8. More than 1,500 people had applied; 310 took part, many traveling from around the world, each with $500 in credits and one day to turn an idea into a working demo.

我们与三支获胜队伍聊了聊他们做了什么，以及如何用 Claude 实现。

> We caught up with the three winning teams about what they built and how they used Claude to do it.

祝贺获胜者和所有参与者。希望他们的项目能给你带来一些灵感。

> Congratulations to the winners and everyone who took part. We hope their projects give you a few ideas of your own.

### 第一名：Tekton，Holly Tang 与 Austin Burgess

> First place: Tekton , Holly Tang and Austin Burgess

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a32e20130b0c237d85e1c09_Claude_Build_Day_258_compressed.jpg)

当一座历史悠久的木构建筑被焚毁时，几个世纪的工艺也可能随之消失。Tekton 以三维方式重建这些建筑，并将每一个构件追溯到有据可查的来源。

> When a historic wooden building burns, centuries of craftsmanship can disappear with it. Tekton reconstructs those buildings in 3D and traces every piece back to a documented source.

给 Tekton 一座历史建筑，Claude 就会对其进行研究，汇集示意图、施工文件、照片和图纸，然后跨越 339 个递增的施工状态组装出一个三维模型。当你点击模型中的任意构件时，Tekton 会显示该细节来自何处以及为何被放置在那里。团队称之为证据链（evidence chain），从原始资料一直延伸到经过验证的模型。他们为学术验证、修复工作和文化保护而构建了它，并从唐代建筑和巴黎圣母院的尖塔开始。

> Give Tekton a historical building and Claude researches it, pulling together schematics, construction documents, photographs, and diagrams, then assembles a 3D model across 339 incremental construction states. When you click any component in the model, Tekton shows where the detail came from and why it was placed there. The team calls this an evidence chain, running from source material to verified model. They built it for academic validation, restoration work, and cultural preservation, starting with Tang Dynasty architecture and the spire of Notre-Dame.

整个验证过程完全在 Opus 4.8 上运行。独立的验证子代理（verifier sub-agents）在隔离的上下文窗口中对每次重建进行评分，自我修正循环不断重新检查构件放置，直到全部 20 项测试通过。每一次构建都对照历史记录及其引用进行衡量，因此最终模型遵循该结构最初建造方式的有据可查的规则。

> The verification ran entirely on Opus 4.8. Independent verifier sub-agents graded each reconstruction in isolated context windows, and self-correction loops rechecked component placement until all 20 tests passed. Every build was measured against the historical record and its citations, so the finished model follows the documented rules of how the structure was originally built.

Holly Tang 和 Austin Burgess 在一个月前相识，当时他们在一场 Code with Claude 活动上排队买咖啡。设计师 Holly 一直在帮助 Austin 的初创公司 Pearl。"我喜欢看纪录片，每当看到美丽的建筑毁于火灾，总让我感到难过，"Holly 说。她曾独自做出过单次重建的原型；而 Austin 的贡献是将其扩展到能够端到端地适用于任何建筑。

> Holly Tang and Austin Burgess met a month earlier, in line for coffee at a Code with Claude event. Holly, a designer, has been helping with Austin's startup, Pearl . "I love watching documentaries, and it always upset me to see beautiful buildings lost to fire," Holly says. She had prototyped a single reconstruction on her own; Austin's contribution was scaling it to work on any building, end to end.

为了构建 Tekton，两人分阶段推进：先让巴黎圣母院的尖塔实现大规模渲染，再添加更精细的细节，然后向结构的其余部分扩展。在完成整座大教堂之前，时间就用尽了。即便如此，仍有几位黑客松参与者前来询问，或主动提出帮助提高其准确性。Holly 和 Austin 希望将 Tekton 开源，以便博物馆、历史学家、非营利组织和政府能够在其基础上继续开发。

> To build Tekton, the two worked in stages: they got the spire of Notre-Dame rendering at scale first, then added finer detail, then expanded toward the rest of the structure. Time ran out before the full cathedral was done. Even so, several hackathon attendees asked about it or offered to help make it more accurate. Holly and Austin want to make Tekton open source, so museums, historians, nonprofits, and governments can build on it.

给其他构建者的建议：在动手构建任何部分之前，先把整个项目规划清楚。

> Advice to other builders: Map the whole project before you build any of it.

"我们做了一份完整的 PRD（产品需求文档），还在 Notion 看板上列了大约 50 个任务卡，每张对应一项具体任务，"Austin 说。"那几乎就像是，这是从头到尾的完整项目，而这正是我们对每一步的确切期望。"计划确定后，他将构建拆分成各自独立的工作流并行运行。

> "We built an entire PRD and a Notion board with around 50 tickets, one for each specific task," Austin says. "It was almost like, here's the complete project end to end, and this is exactly what we want for each step." With the plan set, he broke the build into separate workflows and ran them in parallel.

GitHub 上的 Tekton

> Tekton on GitHub

### 第二名：Sim Francisco，Tanmayi Priya Dasari 和 Tejas Prabhune

> Second place: Sim Francisco , Tanmayi Priya Dasari and Tejas Prabhune

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a32e670a9a0ae0844278fec_Claude_Build_Day_280_cropped_native.jpg)

Sim Francisco 是旧金山人口的一个运行模型。它包含 1 万名根据美国人口普查数据生成的合成居民，每人都有各自的人口统计特征、个人经历和世界观，被放置在城市地图上并实时对新闻作出反应。

> Sim Francisco is a working model of San Francisco's population. It has 10,000 synthetic residents drawn from US Census data, each with their own demographics, personal history, and worldview, placed on a map of the city and reacting to the news in real time.

向这座城市提一个问题，它会逐个街区地对整个合成选民群体进行民调。在使用知识截止日期为 2023 年 10 月的模型运行时，它预测 2024 年总统选举民主党得票率为 81.3%，而实际为 83.8%；预测旧金山 2024 年 3 月的 Prop A 提案为 70%，而实际为 70.38%。它对 Kalshi 和 Polymarket 等预测市场的追踪误差在几个百分点之内。*

> Ask the city a question and it polls the entire synthetic electorate, neighborhood by neighborhood. Running on models with an October 2023 knowledge cutoff, it forecast the 2024 presidential vote at 81.3% Democratic against an actual 83.8%, and San Francisco's March 2024 Prop A at 70% against an actual 70.38%. It tracks prediction markets like Kalshi and Polymarket within a couple of points.*

Opus 4.8 编写了全部前端和后端，并端到端地验证了后端的行为。为了验证模型的工作成果，团队让 Claude 与一个验证器和一个对抗性智能体协同工作，构建出一个能够重现城市真实人口分布的后端。

> Opus 4.8 wrote the entire front and back end and verified the backend's behavior end to end. To verify the model’s work, the team had Claude work alongside a verifier and an adversarial agent to build a backend that reproduced the city's real demographic distributions.

Tanmayi Priya Dasari 和 Tejas Prabhune 是加州大学伯克利分校（UC Berkeley）电气工程与计算机科学专业的学生，两人通过校内的机器学习俱乐部相识。对 Tejas 来说，Sim Francisco 同时也是对他正在创办的后训练（post-training）公司的一次测试，他在其中探索合成人物角色能否保持足够的一致性，从而用于训练模型完成长周期任务。

> Tanmayi Priya Dasari and Tejas Prabhune are electrical engineering and computer science majors at UC Berkeley who met through the Machine Learning club on campus. For Tejas, Sim Francisco doubles as a test for the post-training company he's building, where he's working out whether simulated personas can stay consistent enough to train models on long-horizon tasks.

给其他开发者的建议：不要满足于第一个可行的方案，尤其是当它成本高昂时。

> Advice to other builders: Don't settle for the first approach that works, especially when it's expensive.

团队的第一个版本为这 1 万名居民中的每一位单独发起一次推理调用，这变得成本高昂。"随着时间推移，Claude 运行了一套它自己创建的演化聚类算法，"Tejas 说，将居民归并为约 300 个代表性人物角色。归并后的版本在 Kalshi、Polymarket 和历史结果上保持了相同的准确度，同时将推理成本削减了 10 到 100 倍。

> The team's first version made a separate inference call for each of the 10,000 residents, which got costly. "Over time, Claude ran an evolutionary clustering algorithm it created itself," Tejas says, batching residents into about 300 representative personas. The grouped version held the same accuracy against Kalshi, Polymarket, and historical results while cutting inference cost by 10 to 100 times.

Sim Francisco 的 GitHub 页面

> Sim Francisco on GitHub

### 第三名：Custom Universe，Jake Stevens 与 Mauricio Pereira

> Third place: Custom Universe , Jake Stevens and Mauricio Pereira

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a32eb3be6cc4dc20abf6ba5_Claude_Build_Day_241_compressed.jpg)

用手机拍一张椅子的照片，Custom Universe 就能把它变成一个 3D 物体，让你放进场景中、用文本提示词重新设计样式，并在渲染图像实时更新的同时随意移动它。

> Snap a phone photo of a chair, and Custom Universe turns it into a 3D object you can drop into a scene, restyle with a text prompt, and move around while the rendered image updates in real time.

该项目面向机器人实验室，这类实验室需要大量合成数据来训练机器人完成特定任务和适应特定环境。实验室可以扫描工厂车间里的一台机器，将它放进场景中，生成数据，针对那个精确的环境对机器人模型进行微调。搭建这类系统通常意味着要雇佣物理学家和工程师来处理物理和碰撞几何。而 Custom Universe 让你只需拖动物体就能布置场景，团队还计划加入精确放置功能，比如把一个物体在厨房台面上挪动 30 厘米。

> The project is aimed at robotics labs, which need large volumes of synthetic data to train robots for specific tasks and settings. A lab can scan a machine from a factory floor, drop it into a scene, and generate data to fine-tune a robotics model for that exact environment. Building that kind of setup usually means hiring physicists and engineers to handle the physics and collision geometry. Custom Universe lets you arrange a scene by dragging objects around instead, and the team plans to add precise placement, like nudging an object 30 centimeters across a kitchen counter.

Opus 4.8 从头到尾构建了整个项目，并在整个黑客马拉松期间操控运行该模型的远程 NVIDIA H100。团队还使用 Claude 来确定哪些模型能产出正确的输出，并构建了将用苹果 RealityKit 扫描的手机物体导入网页应用的流程管线。

> Opus 4.8 built the project end to end and operated the remote NVIDIA H100 that ran the model throughout the hackathon. The team also used Claude to work out which models produced the right output and to build the pipeline that brings phone-scanned objects, captured with Apple's RealityKit, into the web app.

Jake Stevens 与 Mauricio Pereira 在活动上相识。Jake 是罗切斯特理工学院（RIT）的计算机视觉专业毕业生，经营着一家专注于加速 AI 模型的初创公司 Luminal；这个场景构建器最初是他一直想尝试的副业项目。Mauricio 是麻省理工学院（MIT）机器人专业毕业生，经营着 Coat Robotics，他带来了自己亲身了解的难题：机器人领域仍然缺乏训练数据，而构建合成环境很困难。Custom Universe 依靠开源模型和算法，可以免费使用；团队表示用户可以在自己的 GPU 上运行它。

> Jake Stevens and Mauricio Pereira met at the event. Jake is a Rochester Institute of Technology (RIT) computer-vision graduate who runs Luminal , a startup focused on speeding up AI models; the scene builder started as a side project he had wanted to try. Mauricio, an MIT robotics graduate who runs Coat Robotics , brought the problem he knew firsthand: robotics still lacks training data, and building synthetic environments is hard. Custom Universe relies on open-source models and algorithms and is free to use; the team says users can run it on their own GPUs.

给其他开发者的建议：用 Claude 来选择工具，而不只是写代码。

> Advice to other builders: Use Claude to choose your tools, not just to write the code.

"很多迭代工作其实是在看哪个模型能给出正确的输出，所以我们用 Claude 做了大量调研，"Mauricio 说。团队还把不熟悉的技术交给 Claude 去集成。"比如苹果 RealityKit，以及我们要如何确保人们能把扫描出的物体输入到我们的网站。我们问 Claude：把这个加到流程管线里。"

> "A lot of the iteration was looking at which model was giving us the right output, so we used Claude to do a lot of the research," Mauricio says. The team also handed Claude unfamiliar technologies to integrate. "For example, Apple RealityKit, and how we were going to make sure people can input their scanned objects to our website. We asked Claude: add this to the pipeline."

Custom Universe 的 GitHub 页面

> Custom Universe on GitHub

了解我们的 Claude 社区项目，包括线下聚会、黑客马拉松等更多内容。

> Learn about our Claude Community programs, including meetups, hackathons, and more.

*Sim Francisco 是一个独立的黑客马拉松项目，以预测选举结果为示例。这并不代表 Anthropic 认可将 AI 模拟的选举预测作为一种使用场景。

> *Sim Francisco is an independent hackathon project that uses forecasting election outcomes as an example. This does not represent an Anthropic endorsement of using AI-simulated election predictions as a use case.

‍

> ‍

## 术语对照

| English | 中文 |
|---|---|
| hackathon | 黑客松 |
| demo | 演示 |
| evidence chain | 证据链 |
| sub-agent / verifier sub-agents | 子智能体／验证子智能体 |
| context window | 上下文窗口 |
| self-correction loop | 自我纠正循环 |
| PRD | 产品需求文档（PRD） |
| workflow | 工作流 |
| synthetic residents | 合成居民 |
| US Census | 美国人口普查 |
| knowledge cutoff | 知识截止日期 |
| prediction markets | 预测市场 |
| adversarial agent | 对抗性智能体 |
| post-training | 后训练 |
| inference call | 推理调用 |
| evolutionary clustering algorithm | 演化聚类算法 |
| synthetic data | 合成数据 |
| fine-tune | 微调 |
| collision geometry | 碰撞几何 |
| pipeline | 流水线 |
| computer vision | 计算机视觉 |
