#!/usr/bin/env bash
# 可重复构建校验：本仓 Jekyll 门户 + claude-blog 子站的 SC 断言（TC-API/TC-UI 中可在构建产物上断言的部分）。
# Worker 相关 SC（14/17-19/24-27）由 theuntold tests/unit/trending-proxy vitest 覆盖，不在本脚本。
# 用法：bash scripts/verify-build.sh   （需 docker + jekyll/builder:4 镜像）
# 退出码：全 PASS=0，任一 FAIL=1。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SITE="_site"
JEKYLL="docker run --rm --platform linux/amd64 -v $ROOT:/srv/jekyll -w /srv/jekyll jekyll/builder:4"
fail=0
pass=0
declare -a RESULTS

assert() { # <SC/TC> <desc> <condition-exit>
  if [ "$3" -eq 0 ]; then RESULTS+=("PASS  $1  $2"); pass=$((pass+1));
  else RESULTS+=("FAIL  $1  $2"); fail=$((fail+1)); fi
}

# ── 正常构建 ──
bash scripts/prepare-collections.sh >/dev/null 2>&1
$JEKYLL sh -c "jekyll build -d $SITE >/dev/null 2>&1"; BUILD_EXIT=$?
assert "SC-01/TC-API-FUNC-001" "Pages 构建成功产出 HTML" "$( [ $BUILD_EXIT -eq 0 ] && [ -f $SITE/index.html ] && echo 0 || echo 1 )"

# SC-04 Hero + 网格
grep -q 'data-testid="portal-hero"' $SITE/index.html && grep -q 'data-testid="portal-source-grid"' $SITE/index.html; assert "SC-04/TC-UI-FUNC-001" "首页含 Hero + 信源导航网格" $?
# SC-05 两卡 + href
c=$(grep -c 'class="source-card"' $SITE/index.html); grep -q 'href="/github-trending/"' $SITE/index.html && grep -q 'href="/claude-blog/"' $SITE/index.html && [ "$c" -ge 2 ]; assert "SC-05/TC-UI-FUNC-002" "≥2 卡且入口链接正确" $?
# SC-06 无 github-trending 明细（无 daily/weekly 明细条目链接）
! grep -qE 'href="/github-trending/(daily|weekly|monthly)/' $SITE/index.html; assert "SC-06/TC-UI-BND-001" "首页无 github-trending 明细条目" $?
# SC-07 最新流占位块
grep -q 'data-testid="portal-latest-stream"' $SITE/index.html; assert "SC-07/TC-UI-FUNC-003" "最新流区块存在" $?
# SC-08 倒序 + 条数 ≤ N(=8)
n=$(grep -c '<li>' $SITE/index.html); dates=$(grep -oE '<time datetime="[0-9-]+"' $SITE/index.html | grep -oE '[0-9-]+' ); sorted=$(echo "$dates" | sort -r); [ "$n" -le 8 ] && [ "$dates" = "$sorted" ]; assert "SC-08/TC-UI-FUNC-004" "最新流倒序且条数≤N" $?
# SC-09 流不含 github-trending 明细（stream src 仅 claude-blog）
srcs=$(grep -oE '<span class="src">[^<]+' $SITE/index.html | sed 's/.*>//' | sort -u); [ "$srcs" = "claude-blog" ] || [ -z "$srcs" ]; assert "SC-09/TC-UI-BND-002" "最新流仅同仓源" $?
# SC-11 /claude-blog/ 索引渲染
[ -f $SITE/claude-blog/index.html ] && grep -q 'claude-blog-post-list\|post-list' $SITE/claude-blog/index.html; assert "SC-11/TC-UI-FUNC-005" "/claude-blog/ 子站索引渲染" $?
# SC-12 子站 post 前缀正确 + 内链
postcnt=$(find $SITE/claude-blog -name index.html | grep -vc '^_site/claude-blog/index.html$'); [ "$postcnt" -ge 20 ] && grep -qE 'href="/claude-blog/[0-9]{4}/' $SITE/claude-blog/index.html; assert "SC-12/TC-API-FUNC-006" "子站 post 渲染且 /claude-blog/ 前缀内链" $?
# SC-13 / 与 /claude-blog/ 均本仓直出
[ -f $SITE/index.html ] && [ -f $SITE/claude-blog/index.html ]; assert "SC-13/TC-API-BND-004" "/ 与 /claude-blog/ 同仓直出" $?
# SC-16 无 github-trending 内容拷贝
! find $SITE -path '*github-trending*' -name '*.html' | grep -q .; assert "SC-16/TC-API-BND-002" "门户产物无 github-trending 内容拷贝" $?

# ── fail-loud 校验（红用例）──
ruby scripts/validate-site.rb >/dev/null 2>&1; assert "validate-GREEN" "当前配置校验通过" $?
# SC-20 缺 title → 非零退出
cp _config.yml /tmp/vb_c.bak; ruby -e "require 'yaml';require 'date';c=YAML.load_file('_config.yml');c.delete('title');File.write('_config.yml',c.to_yaml)"; ruby scripts/validate-site.rb >/dev/null 2>&1; rc=$?; cp /tmp/vb_c.bak _config.yml; assert "SC-20/TC-API-ERR-001" "配置缺必填项 fail-loud 非零退出" "$( [ $rc -ne 0 ] && echo 0 || echo 1 )"
# SC-21 SourceCard 缺字段 → 非零
cp _data/sources.yml /tmp/vb_s.bak; ruby -e "require 'yaml';require 'date';c=YAML.load_file('_data/sources.yml');c[0].delete('summary');File.write('_data/sources.yml',c.to_yaml)"; ruby scripts/validate-site.rb >/dev/null 2>&1; rc=$?; cp /tmp/vb_s.bak _data/sources.yml; assert "SC-21/TC-UI-ERR-001" "SourceCard 缺必填字段 fail-loud" "$( [ $rc -ne 0 ] && echo 0 || echo 1 )"
# SC-23 claude_blog permalink 前缀错位 → 非零
cp _config.yml /tmp/vb_c.bak; ruby -e "require 'yaml';require 'date';c=YAML.load_file('_config.yml');c['collections']['claude_blog']['permalink']='/wrong/:path/';File.write('_config.yml',c.to_yaml)"; ruby scripts/validate-site.rb >/dev/null 2>&1; rc=$?; cp /tmp/vb_c.bak _config.yml; assert "SC-23/TC-API-ERR-003" "子站 permalink 前缀错位 fail-loud" "$( [ $rc -ne 0 ] && echo 0 || echo 1 )"
# SC-22 缺 published_at → stderr 告警 + 构建不中止 + 跳过
mkdir -p sources/claude-blog/posts/2099/01; printf -- '---\nsource: claude-blog\ntitle_zh: 无日期\ncategory: X\n---\n# x\n' > sources/claude-blog/posts/2099/01/2099-01-01-nd.md
warn=$(ruby scripts/validate-site.rb 2>&1 | grep -c "WARN.*published_at"); bash scripts/prepare-collections.sh >/dev/null 2>&1; $JEKYLL sh -c "jekyll build -d $SITE >/dev/null 2>&1"; rc=$?; nd=$(grep -c "无日期" $SITE/index.html); rm -rf sources/claude-blog/posts/2099; [ "$warn" -ge 1 ] && [ $rc -eq 0 ] && [ "$nd" -eq 0 ]; assert "SC-22/TC-UI-ERR-002" "缺 published_at 跳过+告警+构建不中止" $?
# SC-10 空集优雅
mkdir -p _cb_bak && mv _claude_blog/* _cb_bak/ 2>/dev/null; $JEKYLL sh -c "jekyll build -d $SITE >/dev/null 2>&1"; rc=$?; empt=$(grep -c 'portal-stream-empty' $SITE/index.html); li=$(grep -c '<li>' $SITE/index.html); mv _cb_bak/* _claude_blog/ 2>/dev/null; rmdir _cb_bak 2>/dev/null; [ $rc -eq 0 ] && [ "$empt" -ge 1 ] && [ "$li" -eq 0 ]; assert "SC-10/TC-UI-BND-003" "空同仓源最新流优雅留空不报错" $?

# 恢复干净构建
bash scripts/prepare-collections.sh >/dev/null 2>&1; $JEKYLL sh -c "jekyll build -d $SITE >/dev/null 2>&1"

echo "════════ verify-build 结果 ════════"
printf '%s\n' "${RESULTS[@]}"
echo "─────────────────────────────────"
echo "PASS=$pass FAIL=$fail"
[ $fail -eq 0 ] && echo "ALL PASS" || echo "HAS FAILURES"
exit $([ $fail -eq 0 ] && echo 0 || echo 1)
