# v0.87.0 UI（第二人）报告：轨道 C 挑战日记回退（R1-07 / BUG-0038）

```text
版本：v0.87.0（ROADMAP R1）
角色：UI（第二人）
任务：R1-07 / BUG-0038——挑战路线在日记中没有线索。按策略 B 为没有日记映射的路线节点生成回退开页，并让挑战自动化改走桌面蜡封。
状态：完成（自动化）；真窗口挑战抽查待用户执行（见下方“手动检查”）
修改文件：
  - src/ui/diary_ui_catalog.gd
  - tests/integration/app_driver.gd（删除 enter_node 旁路，统一用 press_seal）
  - tests/integration/v07_app_flow_runner.gd（挑战入口改走蜡封，并新增回退开页检查）
  - tests/ui/challenge_diary_fallback_runner.gd / .tscn（新增）
  - docs/bugs/BUG-0038-challenge-route-no-diary-clues.md（状态、修复、回归）
  - docs/reports/v0.87.0/ui_challenge.md（本文件）
依赖：
  - RouteSnapshot 已有字段：nodes[].id / type / display_name_zh / scene_id / narrative_beat_zh、completed_node_ids、unlocked_node_ids、available_node_id、clue_annotations、clue_overlays（只读，未新增字段）
  - data/diaries/v0.55.0/tingen_volume_1.json（只读）
  - diary_chapter_screen.gd 的 get_clue / get_page_count / get_desk_stage().seal_activated（只读使用，未修改）
验证：
  - tools/run_tests.sh：run_tests: pass=86 fail=0 skipped=9 guard_block=0（基线 85 + 新增 1）
  - CHALLENGE_DIARY_FALLBACK_OK checks=77
  - APP_V07_CHALLENGE_FLOW_OK checks=88
  - 黄金回放 tests/golden/expected.json 未改动（git 无差异，golden runner 通过）
  - 主线 build_view 在 4 种快照下的 SHA-256 与修复前一致（写死在新 runner 中）
困难与候选方案：
  1. 挑战快照下主线卷的 8 页会和回退页混在一起。
     候选 a：始终显示主线卷，再在后面追加回退页（挑战玩家会先看到 8 张锁死的主线页，且回退页因前页未完成永远锁定——不可玩）。
     候选 b：快照节点里没有任何日记卷节点时，跳过日记卷，只出回退页；有任一映射节点或没有 nodes 时沿用原逻辑。
     选 b。旧测试中只给部分主线节点的快照仍走原逻辑，主线输出不变。
  2. 标题来源：不新建文案表，直接用快照节点已有的 display_name_zh；为空时用「无名之页」。
  3. 状态计算：沿用主线开页的同一套计算（完成 / 已解锁且前页完成 / 锁定），不新增规则；蜡封载荷字段与主线相同，因此 diary_chapter_screen.gd 不需要改动。
最终解决：catalog 内新增 _fallback_spread 与 _volume_node_ids；回退开页带 is_fallback: true，其余字段与主线开页同构。
风险：
  - 主线开页和回退开页都在 UI 里根据 completed/unlocked 推“前页未完成则锁”。这是 v0.84 以来已有的 UI 推导，本次只是复用。按 AGENTS §6，R2 应改为直接读快照节点自带的 state 字段（候选池）。
  - 主线哈希包含 left_art_path；若轨道 D 删除了主线场景实际引用的资源，回退路径会变，哈希检查会失败。这属于预期的报警。
  - 挑战回退页没有叙事正文（挑战节点无 narrative_beat_zh），只有标题和场景图。文案补齐属于策略 A（P1）。
  - 挑战全程（含仪式和结算）仍未在自动化中打通：脚本玩家打不完整条挑战。已覆盖第一节点的蜡封进入、战斗、奖励以及返回日记；仪式蜡封发 begin_ascension 由 UI runner 覆盖。
跨角色请求：
  - 产品经理 / 叙事：P1 按策略 A 为挑战路线补日记文案后，回退开页会自动让位，无需改 UI。
  - 架构师（R2）：建议日记开页状态改读快照 nodes[].state，去掉 UI 侧的前页推导。
下一步入口：tests/ui/challenge_diary_fallback_runner.gd；src/ui/diary_ui_catalog.gd 的 _fallback_spread。
```

## 玩家现在看到什么

标题 → 挑战 → 选择挑战 → 确认牌组 → 日记桌面上出现挑战路线的 5 个开页（如「密修会的闯入者」「提利尔仓库」「黑荆棘安保公司」「失控的老尼尔」「转运仪式」）。第一页蜡封可点，点后进入第一场战斗。后面各页在前页完成前保持锁定，与主线一致。卷名显示为挑战路线名。

## 手动检查（用户真窗口抽查）

1. 有序列八存档（或先通关主线）后，标题 → 挑战 → 「值夜者档案：笔记案」→ 任选修饰 → 开始 → 确认牌组。
2. 日记桌面应显示标题为「密修会的闯入者」的开页，蜡封可点亮；向后翻页应被弹回（后续页锁定）。
3. 点蜡封 → 进入战斗 → 胜利 → 领奖 → 回到日记，第一页已完成，自动或手动翻到「提利尔仓库」，蜡封可点。
4. 回归：新游戏 → 日记第一开（「密修会的闯入者」，带原叙事文本）→ 战斗 → 返回 hub，与修复前一致。

## 候选池

- 日记开页状态直接读快照 `nodes[].state`（R2）。
- 挑战路线日记文案（策略 A，P1）。
