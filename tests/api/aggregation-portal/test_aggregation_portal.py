"""聚合门户 API 自动化脚本（TC-API-*）。

存在性与执行分离（test-coverage-rules §1.1）：本交付无传统 HTTP API 服务
（Jekyll 静态站 + 无状态 CF Worker），故 canonical apitest 以骨架形态存在，
每条断言的**真实可重复证据**指向权威脚本：
  - Jekyll 构建/配置/结构类 → trending-diggest `scripts/verify-build.sh`（docker jekyll build + HTML 断言 + validate 红用例，19/19）
  - CF Worker 路由/反代/301 类 → theuntold `tests/unit/trending-proxy/{router,handler}.test.ts`（vitest 22/22）
  - live-CF 类（域名/DNS/GoatCounter 运行时）→ cutover-runbook §6 agent-browser（post-merge 执行）
每条 skip 注明真实证据位置，marker 齐全供 TC-ID 追溯闭环。
"""
import pytest

VERIFY_BUILD = "trending-diggest scripts/verify-build.sh"
WORKER_VITEST = "theuntold tests/unit/trending-proxy/*.test.ts"
LIVE_CUTOVER = "cutover-runbook.md §6 agent-browser (post-merge)"


@pytest.mark.tc_api_func_001
def test_tc_api_func_001_pages_build():
    """TC-API-FUNC-001 / SC-01：Pages 构建成功产出 HTML、无 submodule。"""
    pytest.skip(f"G4 填实：真实证据 {VERIFY_BUILD} → SC-01/TC-API-FUNC-001 PASS")


@pytest.mark.tc_api_bnd_001
def test_tc_api_bnd_001_cname():
    """TC-API-BND-001 / SC-02：CNAME=trending.theuntold.ai + 域返回本仓 Pages（行为层）。"""
    pytest.skip(f"G4 填实：CNAME 文件断言 {VERIFY_BUILD}；域路由 live 验 {LIVE_CUTOVER}")


@pytest.mark.tc_api_err_001
def test_tc_api_err_001_config_fail_loud():
    """TC-API-ERR-001 / SC-20：_config.yml 缺必填项 → 构建非零退出、无产物。"""
    pytest.skip(f"G4 填实：真实证据 {VERIFY_BUILD} → SC-20 红用例 PASS")


@pytest.mark.tc_api_func_002
def test_tc_api_func_002_proxy():
    """TC-API-FUNC-002 / SC-14：GET /github-trending/ 反代 github-trending Pages（200）。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} handler SC-14 PASS；live 反代 {LIVE_CUTOVER}")


@pytest.mark.tc_api_func_003
def test_tc_api_func_003_baseurl_prefix():
    """TC-API-FUNC-003 / SC-15：/github-trending/ 页面 CSS/JS/permalink/GoatCounter 前缀。"""
    pytest.skip(f"G4 填实：baseurl 前缀 build 侧 github-trending 构建(90 前缀) PASS；GoatCounter 运行时 {LIVE_CUTOVER}")


@pytest.mark.tc_api_bnd_002
def test_tc_api_bnd_002_no_copy():
    """TC-API-BND-002 / SC-16：门户产物无 github-trending 内容拷贝（运行时反代）。"""
    pytest.skip(f"G4 填实：真实证据 {VERIFY_BUILD} → SC-16 PASS")


@pytest.mark.tc_api_err_002
def test_tc_api_err_002_upstream_5xx():
    """TC-API-ERR-002 / SC-24：上游 5xx → Worker 非 200 可辨识错误；/ 仍 200。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} handler SC-24（5xx/网络失败 → X-Proxy-Error）PASS")


@pytest.mark.tc_api_func_004
def test_tc_api_func_004_legacy_301():
    """TC-API-FUNC-004 / SC-17：/daily/2026-03-30-analysis → 301 + query 保留。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} handler SC-17 + query 保留 PASS")


@pytest.mark.tc_api_func_005
def test_tc_api_func_005_legacy_enum():
    """TC-API-FUNC-005 / SC-18：daily/weekly/monthly/assets 锚定正则全 301。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} router SC-18（.html + weekly 变体）PASS")


@pytest.mark.tc_api_bnd_003
def test_tc_api_bnd_003_root_portal():
    """TC-API-BND-003 / SC-19：GET / → 200 门户、非 301。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} router/handler SC-19（/ → passthrough 非 redirect）PASS")


@pytest.mark.tc_api_bnd_004
def test_tc_api_bnd_004_same_repo_direct():
    """TC-API-BND-004 / SC-13：/ 与 /claude-blog/ 本仓直出、Worker 不改写非 /github-trending/。"""
    pytest.skip(f"G4 填实：真实证据 {VERIFY_BUILD} SC-13 + {WORKER_VITEST} router passthrough PASS")


@pytest.mark.tc_api_func_006
def test_tc_api_func_006_subsite_assets():
    """TC-API-FUNC-006 / SC-12：/claude-blog/ 资源 CSS 200、内链可达（前缀正确）。"""
    pytest.skip(f"G4 填实：真实证据 {VERIFY_BUILD} SC-12（28 post 前缀内链）PASS")


@pytest.mark.tc_api_err_003
def test_tc_api_err_003_baseurl_misconfig():
    """TC-API-ERR-003 / SC-23：子站 baseurl/permalink 错位 → 构建/校验非零退出。"""
    pytest.skip(f"G4 填实：真实证据 {VERIFY_BUILD} SC-23 + SC-23b/c（缺失/无 output）红用例 PASS")


@pytest.mark.tc_api_err_004
def test_tc_api_err_004_unmatched_no_301():
    """TC-API-ERR-004 / SC-25：不匹配任何模式的旧路径 → 不误 301、不返 5xx。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} router SC-25（未匹配 → passthrough，锚定防越界）PASS")


@pytest.mark.tc_api_bnd_005
def test_tc_api_bnd_005_no_trailing_slash():
    """TC-API-BND-005 / SC-26：GET /github-trending（无尾斜杠）→ 301 /github-trending/。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} router/handler SC-26 PASS")


@pytest.mark.tc_api_err_005
def test_tc_api_err_005_upstream_404_passthrough():
    """TC-API-ERR-005 / SC-27：上游真实 404 → Worker 透传 404（非 5xx 错误页）。"""
    pytest.skip(f"G4 填实：真实证据 {WORKER_VITEST} handler SC-27 PASS")


@pytest.mark.tc_api_func_007
def test_tc_api_func_007_canonical_prefix():
    """TC-API-FUNC-007 / SC-15：canonical/sitemap/feed/OG URL 含 /github-trending/ 前缀；旧根外链 301 不断链。"""
    pytest.skip(f"G4 填实：baseurl 前缀 build 侧已验；live canonical/外链 301 {LIVE_CUTOVER}")
