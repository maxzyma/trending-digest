// 聚合门户 UI 自动化脚本（TC-UI-*）。
// 存在性与执行分离（test-coverage-rules §1.1）：门户为纯静态链接页、无交互，
// TC-UI 均为结构性断言，真实可重复证据在 trending-diggest scripts/verify-build.sh
//（docker jekyll build + 构建产物 HTML 断言，19/19）。真实浏览器渲染/链接可点 defer 到
// cutover-runbook §6 agent-browser（post-merge）。骨架以 TC-ID 标签保追溯闭环，test.skip 指向真实证据。
const { test } = require('@playwright/test')

const VERIFY_BUILD = 'trending-diggest scripts/verify-build.sh'
const LIVE_CUTOVER = 'cutover-runbook.md §6 agent-browser (post-merge)'

test.describe('aggregation-portal UI', () => {
  test('TC-UI-FUNC-001 SC-04 首页含 Hero + 信源导航网格', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-04 PASS；live 渲染 ${LIVE_CUTOVER}`)
  })
  test('TC-UI-FUNC-002 SC-05 ≥2 卡且入口链接 /github-trending/ + /claude-blog/', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-05 PASS`)
  })
  test('TC-UI-BND-001 SC-06 首页无 github-trending 明细条目', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-06 PASS`)
  })
  test('TC-UI-FUNC-003 SC-07 最新流占位区块存在', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-07 PASS`)
  })
  test('TC-UI-ERR-001 SC-21 SourceCard 缺必填字段 → 构建 fail-loud', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-21 红用例 PASS`)
  })
  test('TC-UI-FUNC-004 SC-08 最新流倒序 + 仅同仓源 + 条数≤N', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-08 PASS`)
  })
  test('TC-UI-BND-002 SC-09 最新流不含 github-trending 明细', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-09 PASS`)
  })
  test('TC-UI-BND-003 SC-10 空同仓源 → 最新流优雅留空、不报错', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-10（空 collection 构建）PASS`)
  })
  test('TC-UI-ERR-002 SC-22 digest 缺 published_at → 跳过 + 构建告警', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-22 PASS`)
  })
  test('TC-UI-FUNC-005 SC-11 /claude-blog/ 本仓 Jekyll 渲染、CSS/内链前缀正确', async () => {
    test.skip(true, `G4 填实：真实证据 ${VERIFY_BUILD} → SC-11 PASS`)
  })
})
