# BUG-0038：挑战路线在日记 UI 中没有线索，无法推进

- 日期：2026-11-24
- 严重度：S2（主流程可达性）
- 版本：v0.86.0 发现（v0.55 日记替代路线屏以来一直存在）
- 状态：已修复（回退开页，v0.87.0 轨道 C）

## 症状

从标题进入挑战并确认牌组后，日记桌面上**没有可以点击的挑战节点线索**，玩家无法在日记 UI 中推进挑战路线。

## 复现

1. 标题 → 挑战 → 选择挑战 → 确认牌组。
2. 进入日记章节，看不到挑战路线节点对应的开页或蜡封。

自动化中，`tests/integration/v07_app_flow_runner` 只能直接发出日记屏的 `route_command_requested` 信号绕过 UI。

## 根因

`data/diaries/v0.55.0/tingen_volume_1.json` 只映射了 `route.v028.first_stage.*` 节点。`diary_ui_catalog.gd` 按日记数据生成开页，挑战路线的节点在日记数据里没有对应条目。

v0.55 以日记替代路线屏时，只给主线写了日记，挑战路线失去了 UI 入口。

## 影响范围

- 挑战模式（`challenge.v060.*` / `challenge.v070.*`）在正式 UI 中实际不可玩。
- 战役主线不受影响。

## 修复策略（候选，待产品经理裁决）

- **A. 数据补齐**：为每个挑战路线写一卷日记数据（或在现有卷里加挑战段），UI 不改。需要叙事文案。
- **B. 通用回退**：`diary_ui_catalog` 对没有日记映射的路线节点，自动生成"空白页加节点名"的开页。这不是规则，只是展示回退。
- **建议**：先做 B 恢复可玩性（v0.87 R1 期间就可以做，属于 UI 的一处小改动），再在 P1 用 A 补文案。

## 修复（v0.87.0，策略 B）

- `src/ui/diary_ui_catalog.gd`：
  - 快照中的路线节点若不在日记卷 `tingen_volume_1.json` 的线索映射里，按路线顺序各生成一个回退开页（`is_fallback: true`）。
  - 标题取快照节点已有的 `display_name_zh`（截到 10 字）；没有时用「无名之页」。正文取快照节点的 `narrative_beat_zh`，挑战节点为空。
  - 锁定 / 可调查 / 已完成状态与蜡封载荷沿用主线开页的同一套计算（`completed_node_ids`、`unlocked_node_ids`、前页未完成则锁），不新增规则判断。
  - 快照节点里一个日记卷节点都没有时（纯挑战路线），不再显示主线卷的 8 页，卷名退回路线名，`base_notes_zh` 为空。
  - 主线（`route.v028.first_stage`）和没有 `nodes` 的旧快照仍走原逻辑，输出逐字节不变。
- `diary_chapter_screen.gd` 未改：回退开页与主线开页字段一致，现有 DeskStage 蜡封 → `RouteCommand` 路径直接可用（普通节点 `select_node`，仪式节点 `begin_ascension`）。

## 回归测试

- `tests/integration/v07_app_flow_runner`：挑战进入日记后检查开页数等于路线节点数、首节点蜡封可用，并通过 `AppDriver.press_seal`（发出桌面 `seal_activated`，与主线相同）进入第一场战斗。`app_driver.gd` 删除了直接发 `route_command_requested` 的 `enter_node` 旁路。
- `tests/ui/challenge_diary_fallback_runner`：
  - 挑战快照生成 5 个回退开页，顺序、标题、锁定状态正确；无主线页混入；无名节点得到「无名之页」。
  - 锁定蜡封不发命令；首节点蜡封发 `select_node(route.v070.node.first_hunt)`；仪式蜡封发 `begin_ascension`。
  - 主线 4 种快照（开局 / 中途含批注与改写 / 只剩晋升 / 无 nodes）的 `build_view` 输出 SHA-256 与修复前记录的值一致。
