#!/usr/bin/env bash
# 拉取跨仓源已发布的 latest.json，供首页最新流构建期合并（ADR-005）。
#
# 走对方的 Pages 域而不是 trending.theuntold.ai：自定义域经 CF Worker 反代，
# 构建期直连 origin 少一跳、也避开 Worker 故障把本站构建拖下水。
#
# 字段在此规范成与同仓 collection 条目一致（url / title / published_at / source），
# 于是首页模板只需把两个数组 concat 起来，渲染逻辑一行不改。
#
# 取不到就写一个空清单——外部源不可达不该阻断本站发布（SC-09b）。这与配置错误
# 必须 fail-loud 不同：那是自己的错，这是别人的可用性。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${CROSS_REPO_LATEST_URL:-https://maxzyma.github.io/github-trending-digest/latest.json}"
OUT="$ROOT/_data/github_trending_latest.json"
TMP="$(mktemp)"

mkdir -p "$ROOT/_data"

if curl -fsSL --max-time 20 "$SRC" -o "$TMP" 2>/dev/null &&
   python3 - "$TMP" "$OUT" <<'PY' 2>/dev/null
import json, sys
raw = json.load(open(sys.argv[1]))
src = raw.get("source") or "github-trending"
items = []
for it in raw["items"]:
    title, path, date = it["title"], it["path"], it["published_at"]
    if not (title and path and date):
        raise ValueError("条目缺字段")
    items.append({"title": title, "url": path, "published_at": date, "source": src})
json.dump({"source": src, "items": items}, open(sys.argv[2], "w"), ensure_ascii=False, indent=1)
print(len(items))
PY
then
  rm -f "$TMP"
  echo "[cross-repo-latest] ok: $(python3 -c "import json;print(len(json.load(open('$OUT'))['items']))") entries from $SRC"
else
  rm -f "$TMP"
  echo '{"source":"github-trending","items":[]}' > "$OUT"
  echo "[cross-repo-latest] WARN unreachable or malformed, degrading to empty: $SRC" >&2
fi
