# 契约: 聚合门户（路由 + 重定向）

> 本 Feature 无传统 REST API；对外契约 = **URL 路径路由契约**（Worker 边缘反代规则）+ **301 重定向 fixture 契约**。字段/数据契约见 entities.md。

## 路由契约（CF Worker，绑 trending.theuntold.ai）

| 路径模式 | 目标 origin | 机制 | covers |
|---------|------------|------|--------|
| `/` | 本仓（trending-diggest）Pages | 直出（Worker 透传/不改写） | SC-04, SC-13 |
| `/claude-blog/*` | 本仓 Pages | 直出（同仓 Jekyll，baseurl=/claude-blog） | SC-11, SC-12, SC-13 |
| `/<未来小源>/*` | 本仓 Pages | 直出（同仓再开目录，机制同上） | SC-13 |
| `/github-trending/*` | github-trending-digest 独立仓 Pages | 反代**保留路径**（不改写 path——github-trending baseurl=/github-trending，其自身链接已含前缀；Worker 仅转发到 origin，不 strip/rewrite） | SC-14, SC-15, SC-16 |
| `/github-trending/*`（上游不可用） | — | Worker 返回非 200 可辨识错误（5xx/自定义错误页），不污染 `/` 与同仓路径 | SC-24 |
| 旧 github-trending 根路径模式 | — | 301 → `/github-trending/` 下对应新路径 | SC-17, SC-18 |

**路由铁律**：
- Worker 仅对 `/github-trending/*` 与旧路径模式生效；`/` 与同仓小源路径不被 Worker 改写（INV-04 / SC-13）。
- 反代要求 github-trending 仓 `baseurl=/github-trending`，否则 CSS/内链错位（INV-01 / SC-15）。

## 301 重定向 fixture 契约（US-05）

> permalink 模式已在 Define 阶段从 github-trending `_config.yml` 枚举（US-05 AC-2）：该仓无自定义 `permalink`，用 Jekyll 默认；内容页实际路径为 `/daily/{date}-analysis`、`/daily/{date}`、`/weekly/{YYYY-Www}`、`/monthly/{YYYY-MM}`；旧首页在裸 `/`。迁移后 baseurl=`/github-trending`，对应新路径前缀 `/github-trending/...`。

| 输入（旧 URL 模式，baseurl="" 时） | 期望响应 | 期望 Location | covers |
|--------------------|---------|--------------|--------|
| `/daily/{date}-analysis`、`/daily/{date}` | 301 | `/github-trending/daily/{date}-analysis` 等 | SC-17, SC-18 |
| `/weekly/{YYYY-Www}` | 301 | `/github-trending/weekly/{YYYY-Www}` | SC-18 |
| `/monthly/{YYYY-MM}` | 301 | `/github-trending/monthly/{YYYY-MM}` | SC-18 |
| `/assets/*`（旧站资源） | 301 | `/github-trending/assets/*` | SC-18 |
| 裸 `/`（原 github-trending 首页） | **200 门户首页**（不 301，见下方裁决） | — | SC-19 |
| 不匹配任何模式的旧路径 | 不误 301（命中反代 200 或 404，不返 5xx） | — | SC-25 |

**裸 `/` 裁决（自审发现的语义冲突解）**：`/` 迁移后是**门户首页**，不能 301 到 github-trending 旧首页——SC-19（`/`=门户）权威优先于 SC-18「旧首页根 301」。github-trending 旧首页内容现位于 `/github-trending/`，门户首页显著提供其导航卡（SC-05）。故 301 仅覆盖**内容子路径**（daily/weekly/monthly/assets），不覆盖裸 `/`。

**fixture 契约**：重定向规则须为显式前缀/模式列表（非 catch-all，SC-25）；一组 `旧 URL → 期望 301 目标` fixture 可断言；`/` → 门户（200，非 301）反例断言必含（SC-19）。

## 构建/部署契约

| 项 | 值 | covers |
|----|-----|--------|
| 本仓 Pages workflow | `submodules: false` | SC-01 |
| 本仓 CNAME | `trending.theuntold.ai` | SC-02 |
| 本仓门户首页构建期依赖 | 仅同仓内容（不拉 github-trending） | SC-06, INV-02 |
| 构建失败即阻断部署（fail-loud，保留上一可用版本） | 配置/字段错误时非零退出、不产残缺站 | SC-20, SC-21 |
| 子站 baseurl 校验 | baseurl 错位在部署前由构建/校验以非零退出码捕获 | SC-23 |

## Worker origin 契约（CF 特有约束，codex 跨家族审查补）

| 项 | 契约 | 依据 |
|----|------|------|
| portal origin | 本仓 GitHub Pages 的 **Pages 域**（`maxzyma.github.io` 类，非 `trending.theuntold.ai`），Worker fetch 指向该 origin，**禁指回自定义域**（否则 CF 路由回 Worker → 无限递归/502） | 防递归 |
| github-trending origin | github-trending-digest 的 GitHub Pages 域，Worker fetch 指向它 | 反代目标 |
| Host header | fetch 时设为对应 origin 的 Pages 域 host（GitHub Pages 按 Host 路由到正确 repo site） | Pages Host 路由 |
| 递归防护 | Worker fetch origin 用 Pages 域直连（非自定义域）；如无法避免同域，加 `CF-Worker` bypass 标记 | 防无限子请求 |
| 上游故障 | 5xx / 网络失败 → Worker 可辨识错误；**4xx（404/410）透传上游**（不掩盖真实 not-found，保 SEO 诊断） | ALG-01 |

## Design 阶段增量（不在本阶段写）

- Worker 脚本具体实现（缓存头 `cf-cache-status`、Route 绑定、purge 策略）
- CF 部署配置、DNS A 记录 IP、灰度策略
- Jekyll 主题/布局技术选型

## 需 Cloudflare live 环境验证的测试层（不可本地静态覆盖）

Worker Route 绑定、cache bypass/purge、origin Host/SNI、subrequest 行为、递归防护 —— 标注为 "requires live CF validation"，本地静态测试不覆盖，G4 在 CF 环境执行（对应 test-cases.md live-CF 层）。
