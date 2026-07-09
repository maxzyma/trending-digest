---
delivery: D-001-aggregation-portal
feature: aggregation-portal
phases_appended: [implement, verify, deliver]
created: 2026-07-09
verify_safety_net: 已填
spec_gap_test_value: 已填
flow_blockage: 已填
experience_capture: 已填
---

# 复盘：D-001 聚合门户

## 维度①：正向防护网表现（问题暴露 + 防护网起没起作用）

- **[verify] Host 递归风险（自审二轮暴露）**：Worker 反代转发原始 Host → origin 按自定义域路由回本域递归/502。防护网（本地对抗自审）**起作用**——TDD 单测 + 自审在部署前拦下。已加 originHeaders 剥离 + 单测。
- **[verify] validate-site collection 缺失静默放行（codex 跨家族暴露）**：SC-23 校验对整段缺失的挂载 collection `next unless key?` 放过，本该 fail-loud。防护网（同族两轮）**该拦未拦**——同族审查盯着"前缀错位"没想到"整段缺失"；换家族（codex L3）才捕获。教训：同族审查有共同盲区，结构性/边界"缺失态"需跨家族或显式反向构造。已修 + 补 SC-23b/c 红用例。
- **[verify] 无误拦**：codex 核实的 9 个方向均确认无问题，无假阳性浪费返工。

## 维度②：test-cases / TDD 驱动价值（implement）

- **[implement] 驱动补边界**：Worker TDD 从 SC 独立派生红步，驱动补齐 `.html` 后缀 + weekly `-old-...` 变体的锚定正则——这是对着 test-cases 设计边界时发现 spec ALG-02 与实际 permalink 不符，回写了 spec（实证修正）。
- **[implement] 真实构建驱动发现数据问题**：docker 真实 Jekyll 构建（非 mock）驱动暴露 8 个 claude-blog post 的 front matter YAML 坏值（未引号冒号）——mock/静态检查不会发现，真实构建 fail-loud 才暴露。已修存量 + 立 follow-up 追流水线根因。
- **[implement] test 是否拦住缺陷**：Worker 22 单测在重构（Host 剥离、ALG-02 修正）时全程守护，改动无回归。verify-build.sh 的 fail-loud 红用例（SC-20/21/23）确保配置错误不带病上线。

## 维度③：流程返工 / 阻塞（verify）

- **无阻塞性返工**。三轮审查均在 Implement/Verify 内闭环修复，未回退 G2/G3。
- **跨仓协调是主要非代码约束**：交付物分 3 仓，live 验证（SC-02/03 + GoatCounter 运行时）本质是 post-merge cutover 才能做——非流程阻塞，是 GitHub Pages 一域一仓 + CF 域切换的平台事实，已由 cutover-runbook 兜底。
- **实证修正驱动 spec 回写 2 处**（Option B 前缀映射 G3-delta、ALG-02 .html 精度）——均在交付内 spec-first 处理，未破坏已过 Gate。

## 维度④：经验沉淀（可复用教训）

- **静态站 + 无状态 Worker 与 canonical 测试 harness 不匹配**：SDLC 的 apitest(python)/playwright fan-out 假设有 HTTP API 服务 + 交互 UI。纯 Jekyll 站 + 边缘 Worker 场景下，真实可重复证据是 vitest（Worker 逻辑）+ 构建断言脚本（Jekyll 产物），canonical harness 只能以骨架存在（存在性与执行分离）。教训：栈适配的可重复自动化同样满足 provenance 铁律，不应为"目录形态"牺牲证据真实性；但需在 G4 显式向 Human 登记偏差裁量。
- **跨仓 + 平台约束（GitHub Pages 一域一仓 + CF 域切换）把关键验证推到 post-merge**：域名可达/反代连通/301 live 本质只能在生产域切换后验，pre-merge 审查再多轮也验不了。教训：这类交付要明确区分"审查/构建能验的"与"必须 live 验的"，后者用原子 cutover runbook + agent-browser 兜底，而非假装 pre-merge 能覆盖。
- **实证驱动 spec 回写 2 处**（Option B 前缀映射、ALG-02 .html 精度）：spec 的模式枚举（permalink）与 Jekyll 实际输出有偏差，靠真实构建才暴露。教训：涉及平台默认行为（permalink/baseurl/safe-mode）的 spec，implement 期必须用真实构建校准，不能纸面推导。

## 元层洞察（候选，机制类）

- **同族审查共同盲区 → "缺失态"逃逸**：3 个真问题中，最隐蔽的（collection 整段缺失校验）唯有换家族才捕获。同族无论审几轮都盯着"配错"而非"整个没有"。→ 结构性校验类产物的对抗审查应显式构造"整段缺失/空集/零元素"反例，或强制跨家族一轮。
