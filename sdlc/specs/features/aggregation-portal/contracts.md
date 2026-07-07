# 契约: 聚合门户（路由 + 重定向）

> 本 Feature 无传统 REST API；对外契约 = **URL 路径路由契约**（Worker 边缘反代规则）+ **301 重定向 fixture 契约**。字段/数据契约见 entities.md。

## 路由契约（CF Worker，绑 trending.theuntold.ai）

| 路径模式 | 目标 origin | 机制 | covers |
|---------|------------|------|--------|
| `/` | 本仓（trending-diggest）Pages | 直出（Worker 透传/不改写） | SC-04, SC-13 |
| `/claude-blog/*` | 本仓 Pages | 直出（同仓 Jekyll，baseurl=/claude-blog） | SC-11, SC-12, SC-13 |
| `/<未来小源>/*` | 本仓 Pages | 直出（同仓再开目录，机制同上） | SC-13 |
| `/github-trending/*` | github-trending-digest 独立仓 Pages | 反代 + path rewrite（baseurl=/github-trending） | SC-14, SC-15, SC-16 |
| 旧 github-trending 根路径模式 | — | 301 → `/github-trending/` 下对应新路径 | SC-17, SC-18 |

**路由铁律**：
- Worker 仅对 `/github-trending/*` 与旧路径模式生效；`/` 与同仓小源路径不被 Worker 改写（INV-04 / SC-13）。
- 反代要求 github-trending 仓 `baseurl=/github-trending`，否则 CSS/内链错位（INV-01 / SC-15）。

## 301 重定向 fixture 契约（US-05）

> 具体 permalink 模式在 Design/Implement 从 github-trending `_config.yml` permalink 配置枚举落地；本表定义 fixture 断言结构。

| 输入（旧 URL 模式） | 期望响应 | 期望 Location |
|--------------------|---------|--------------|
| 旧 daily 明细页根路径（模式待从 `_config.yml` 枚举） | 301 | `/github-trending/<对应新路径>` |
| 旧首页根（github-trending 迁移前根） | 301 | `/github-trending/` |
| 门户根 `/` | 200（门户首页） | —（不被重定向命中，SC-19） |

**fixture 契约**：重定向规则须为显式前缀/模式列表（非 catch-all）；一组 `旧 URL → 期望 301 目标` fixture 可断言；`/` 反例断言必含（SC-19）。

## 构建/部署契约

| 项 | 值 | covers |
|----|-----|--------|
| 本仓 Pages workflow | `submodules: false` | SC-01 |
| 本仓 CNAME | `trending.theuntold.ai` | SC-02 |
| 本仓门户首页构建期依赖 | 仅同仓内容（不拉 github-trending） | SC-06, INV-02 |

## Design 阶段增量（不在本阶段写）

- Worker path-rewrite 具体实现（Cloudflare Worker 脚本细节、缓存头、错误兜底）
- CF 部署配置、DNS A 记录 IP、灰度策略
- Jekyll 主题/布局技术选型
