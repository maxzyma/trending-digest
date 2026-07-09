---
delivery: D-001-aggregation-portal
antipatterns_checked: "10/10"
dimensions_checked: "8/8"
traps_scanned: "5/5"
issues_critical: 0
issues_high: 0
issues_medium: 0
report_timestamp: "2026-07-08T12:10:33+0800"
confidence_filter:
  threshold: 80
  candidates: 4
  kept: 0
  filtered: 4
status: PASS
---

# D-001 聚合门户 · 跨 task Code Review

> 范围：3 仓本交付改动——trending-diggest（Jekyll 门户 001~004 + validate/prepare 脚本）、github-trending-digest（baseurl 006）、theuntold（CF Worker 005/007）。
> 阶段一 per-task review 已覆盖各 task 可见维度；本报告为跨 task 视角 8 维 + 10 antipatterns + 5 traps 全量。

## 1. Antipatterns 快检（10 类）

| # | 反模式 | 结论 | 说明 |
|---|--------|------|------|
| 1 | 多租户隔离 | N/A | 无多租户/DB |
| 2 | 服务层架构 | N/A | 静态站 + 无状态 Worker，无服务层 |
| 3 | DTO 命名 | N/A | 无 DTO |
| 4 | 错误码 | PASS | Worker 上游 5xx→502 可辨识错误（X-Proxy-Error 头）；4xx 透传（SC-24/27） |
| 5 | i18n | PASS | 中文内容站，layout lang="zh-CN"；无硬编码用户文案错配 |
| 6 | 跨页状态 | N/A | 无客户端状态 |
| 7 | HTTP 方法 | PASS | Worker 301 用 GET 语义；反代透传 method；重定向 Location 正确 |
| 8 | 时间类型 | PASS | published_at 用 ISO YYYY-MM-DD，字符串排序即时间序（ALG-03） |
| 9 | 并发安全 | N/A | 无状态边缘函数，无共享可变态 |
| 10 | 前端性能 | PASS | 门户内联 CSS、无 JS 依赖；外链字体 display=swap；图片外链 CDN |

## 2. 8 维度审查

| # | 维度 | 结论 | 说明 |
|---|------|------|------|
| 1 | 安全 | PASS | Worker 不注入/不改写响应体；origin 用 Pages 域直连（防递归）；剥离 Host/X-Forwarded-Host；validate 脚本无外部输入注入面；无硬编码密钥 |
| 2 | 边界条件 | PASS | 空最新流优雅留空（SC-10）；缺 published_at 跳过+告警（SC-22）；锚定正则防前缀越界（SC-25）；无尾斜杠归一（SC-26） |
| 3 | Spec 一致性 | PASS | ALG-01/02/03、contracts 路由/301 fixture、entities SourceCard/DigestEntry、INV-01/02/04 均对齐；ALG-02 .html 偏差已回写 spec |
| 4 | 错误处理 | PASS | 构建期 fail-loud 非零退出（SC-20/21/23）；Worker 上游故障可辨识错误 + 网络失败 catch（SC-24） |
| 5 | 依赖 | PASS | 移除死依赖 minima；Worker 零运行时依赖；wrangler 仅 devDep |
| 6 | 架构一致性 | PASS | 门户/小源同仓直出 vs 大站边缘反代分层清晰（ADR-001/002）；Worker 纯函数 router 与 I/O handler 分离 |
| 7 | 代码质量 | PASS | 小文件、命名清晰、无重复；validate 脚本单一职责聚合 |
| 8 | 测试质量 | PASS | Worker 22 vitest 覆盖 ALG-01/02 全 SC 且 covers 声明；Jekyll 经 docker 真实构建 + 结构断言；build-time validate 红绿实证 |

## 3. Engineering-Traps（5 类）

| # | 陷阱 | 结论 | 说明 |
|---|------|------|------|
| 1 | 框架边界 | PASS | Jekyll collection 目录须 `_` 前缀 + GH Pages safe-mode 忽略 symlink → 用构建期 copy 规避（已实证）；Worker fetch Host 由 URL 驱动 |
| 2 | 精度/序列化 | PASS | 日期 ISO 字符串序即时间序；无浮点/大数 |
| 3 | 占位硬编码 | PASS | 无残留 TODO/占位；latest_stream_count 配置化非硬编码；origin/prefix 走 env vars |
| 4 | 异步并发 | PASS | Worker fetch await + try/catch；无竞态 |
| 5 | 部署配置 | PASS | pages.yml submodules:false + 构建前 materialize/validate step；wrangler routes/vars 显式；cutover 原子顺序 runbook 已定 |

## 4. Confidence Filter Summary

阈值 80。候选 4 条均为低置信度观察，过滤后不计入严重度：

| 候选 | score | 判定 | 理由 |
|------|-------|------|------|
| 门户依赖外链 Google Fonts（离线不可用） | 45 | filtered | 设计选型（对齐 github-trending 观感），display=swap 有回退，非缺陷 |
| Worker 未做响应缓存头优化 | 40 | filtered | contracts 明列缓存策略为 Design 增量/live-CF 层，非本阶段；非缺陷 |
| PORTAL_ORIGIN passthrough 分支 route-scoped 下不触发 | 30 | filtered | 防御性兜底代码，符合"Worker 也能 /* 绑定"的健壮性；非缺陷 |
| claude-blog 流水线未来仍可能产坏 YAML front matter | 55 | filtered | 根因在跨仓流水线，已记 follow-up；本交付已修复存量 8 文件，不属本交付代码缺陷 |

## 结论

CRITICAL=0 / HIGH=0 / MEDIUM=0。跨 task review 通过。live CF 层（Worker route 绑定/origin Host/递归/agent-browser）标注为 cutover 时 CF 环境验证（contracts「需 Cloudflare live 环境验证的测试层」），不在本地静态覆盖范围。
