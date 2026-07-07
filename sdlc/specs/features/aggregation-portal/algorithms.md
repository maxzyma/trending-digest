# 算法: 聚合门户路由与重定向

> CF Worker 边缘路由/重写/301 匹配逻辑。实现载体归 theuntold 仓，本文件定义算法契约。

## ALG-01 路径路由分派（Worker fetch handler）

**covers**: [SC-14, SC-16, SC-24, SC-13]

**输入**：request URL path `P`
**输出**：origin 响应（反代 / 直出 / 错误）

**逻辑**（按序匹配，首命中即返）：
1. `P` 命中旧内容子路径模式（见 ALG-02）→ 交 ALG-02 返回 301
2. `P` 以 `/github-trending/` 前缀 → 反代 github-trending 独立仓 Pages origin（保留子路径）
   - 上游返回非 2xx/3xx → 返回 Worker 可辨识错误响应（HTTP 非 200，不透传门户内容）（SC-24）
3. 其余（`/`、`/claude-blog/*`、未来同仓小源）→ 直出/透传本仓 Pages origin（Worker 不改写）（SC-13）

**边界**：
- 门户根 `/` 命中步骤 3，不被步骤 1/2 截获（INV-04 / SC-19）
- 反代保持 path（github-trending 仓 baseurl=`/github-trending`，故其自身链接已含前缀，Worker 不再二次改写）（SC-15）

## ALG-02 旧 URL → 301 目标映射

**covers**: [SC-17, SC-18, SC-19, SC-25]

**输入**：request URL path `P`
**输出**：`{ status: 301, location }` 或 `null`（不重定向）

**重定向模式集**（显式列表，非 catch-all；从 github-trending `_config.yml` 枚举——无自定义 permalink，Jekyll 默认）：
```
/daily/{date}-analysis      → /github-trending/daily/{date}-analysis
/daily/{date}               → /github-trending/daily/{date}
/weekly/{YYYY-Www}          → /github-trending/weekly/{YYYY-Www}
/monthly/{YYYY-MM}          → /github-trending/monthly/{YYYY-MM}
/assets/*                   → /github-trending/assets/*
```

**逻辑**：
1. `P == "/"` → 返回 `null`（门户首页，不重定向）（SC-19）
2. `P` 前缀匹配模式集任一 → 返回 `{301, "/github-trending" + P}`（SC-17/18）
3. 否则 → 返回 `null`（交 ALG-01 后续步骤；不 catch-all 兜底 301）（SC-25）

**边界**：
- 模式集为显式前缀白名单，新增源不改本算法（github-trending 迁移一次性）
- 不匹配的旧路径不误 301（返回 404 或正常路由，不返 5xx）（SC-25）

## ALG-03 首页最新流聚合（Jekyll 构建期）

**covers**: [SC-08, SC-09, SC-10, SC-22]

**输入**：本仓 `site.pages` 中同仓小源 DigestEntry 集合
**输出**：倒序 top-N digest 列表（渲染到首页第三区块）

**逻辑**：
1. 过滤：仅 same-repo 源的 DigestEntry（排除 github-trending，构建期拿不到，SC-09）
2. 缺 `published_at` 排序键的条目 → 跳过 + 构建日志告警（不中止，SC-22）
3. 按 `published_at` 倒序排序
4. 取前 N 条（N = 站点配置项，默认值实现时定，SC-08）
5. 空集 → 区块优雅留空/隐藏（SC-10）

**边界**：构建期纯本仓数据，无跨仓/无运行时依赖（INV-02）
