# Behaviors 索引: 聚合门户

| Rule 文件 | Rule（用户任务） | Story | Scenario 数 | SC 范围 |
|-----------|-----------------|-------|------------|---------|
| site-skeleton.gherkin | 本仓具备 Jekyll 站点骨架 + Pages 部署 + CNAME | US-00 | 4 | SC-01~03, 20 |
| portal-homepage.gherkin | 门户首页（Hero + 信源导航网格 + 流占位） | US-01 | 5 | SC-04~07, 21 |
| latest-stream.gherkin | 首页最新内容流（同仓小源倒序） | US-02 | 4 | SC-08~10, 22 |
| small-source-subsite.gherkin | 小源同仓分目录子站 | US-03 | 4 | SC-11~13, 23 |
| github-trending-proxy.gherkin | github-trending 经 Worker 反代 | US-04 | 6 | SC-14~16, 24, 26, 27 |
| legacy-redirect.gherkin | 旧 URL 301 重定向兜底 | US-05 | 4 | SC-17~19, 25 |
| editorial-design-system.gherkin | 三站统一 editorial token + light/dark 切换 | US-01~05（editorial） | 10 | SC-28~37 |

合计 7 Rule / 37 Scenario（每 Rule 含正常/边界/错误三类）。SC-20~25 为 @error；SC-26（无尾斜杠归一）/SC-27（上游 4xx 透传）为 codex 跨家族审查补的边界场景。SC-28~37 为三站统一 editorial 设计系统（SC-36 @error）；其中 SC-33 github-trending 为一致性核验（非改造，已在目标 token 上），SC-37 为非首次访问按已存偏好渲染（无 FOUC）。
