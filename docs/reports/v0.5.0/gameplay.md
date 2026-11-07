# v0.5.0 / 玩法设计

## 状态

- 版本：`v0.5.0`
- 角色：玩法设计
- 任务：固定短路线、休息、首领和首次序列晋升
- 状态：完成；v0.5.0 已关闭
- 最后更新：2026-11-08
- 下一步入口：数据层建立 v0.5 schema/适配器，app 将 RouteEngine 接入 CampaignSession

## 本版本目标

在不复制战斗和成长规则的前提下，实现：

```text
首战 -> 精英战 -> 休息 -> 首领战 -> 被篡改的讣告 -> 序列 9 晋升 8
```

## 依赖

- 已关闭的 `v0.4.0` 成长短循环。
- `BattleEngine` 的逐张出牌、敌方压力和事件顺序。
- `ProgressionEngine` 的身份、牌组过滤、升级内容端口。
- 数据层新增 route、ritual、敌人阶段和存档 v3 schema。

## 已实现

### 共享契约

- `src/core/route_command.gd`
- `src/core/route_event.gd`
- `src/core/route_snapshot.gd`
- `src/core/route_command_result.gd`
- `src/core/route_content_port.gd`
- `src/core/ritual_snapshot.gd`
- `src/core/sequence_state.gd`

命令：

- `SelectNode(node_id)`
- `ResolveNode(node_id, outcome, player_state)`
- `UseRest(rest_id)`
- `BeginAscension`
- `SubmitRitualStep(selections)`
- `RequestRitualHint`
- `CancelRitual`

稳定拒绝原因包括：

- `wrong_phase`
- `unknown_node`
- `node_not_available`
- `wrong_node`
- `invalid_battle_outcome`
- `rest_not_available`
- `ascension_requires_begin`
- `ascension_not_available`
- `ritual_selection_count`
- `invalid_ritual_selection`
- `ritual_step_invalid`
- `insufficient_spirit`
- `hint_already_used`

### 路线状态机

`src/gameplay/route_engine.gd` 固定五节点顺序：

1. `route.v050.node.first_hunt`
2. `route.v050.node.mirror_pursuit`
3. `route.v050.node.old_house_rest`
4. `route.v050.node.mirror_baron`
5. `route.v050.node.ascension`

状态包括 `map`、`battle_pending`、`rest_pending`、`ritual`、`completed` 和 `failed`。

- 战斗节点胜利后解锁下一节点，失败结束路线。
- 战斗结束的 `hp`、`corruption`、`attention`、`spirit` 可带回路线状态。
- 路线只保存已确认节点，不复制战斗中间状态。
- 重复节点、重复休息、失败后继续操作均被结构化拒绝。

### 休息选项

- `rest.bandage`：恢复 12 点生命。
- `rest.seal_echo`：降低 2 点污染，增加 1 点被注视，并让下一场战斗的灵性上限 +1。

效果来自 `data/routes/v0.5.0/routes.json`，UI 只消费快照。

### 被篡改的讣告

`data/rituals/v0.5.0/rituals.json` 实现固定三步：

1. 选择两个同姓姓名。
2. 排列出生、死亡、埋葬。
3. 选择倒悬之眼封印。

- 公开 `RitualSnapshot` 不包含答案字段。
- 每个步骤都可以请求一次提示，提示消耗 1 点灵性。
- 合法但错误的步骤增加 2 点污染并停留在当前步骤。
- 污染达到上限时仪式失败并结束路线，不永久卡死。
- 仪式可以取消并重试，取消不抹除已获得的局外收藏。
- 成功时序列从 9 变为 8“小丑”。

### 首领独有机制

`BattleEngine` 增加可选敌人 `phases`：

- `at_round`：触发回合。
- `base_attack_bonus`：后续基础攻击增量。
- `block_bonus`：阶段触发时获得护盾。
- `heal`：阶段触发时治疗。

镜厅男爵：

- 第 3 回合“磨亮的镜面”：攻击 +1、获得 5 护盾。
- 第 6 回合“破碎倒影”：攻击再 +2、获得 3 护盾、治疗 4。

阶段在当回合生成意图前触发，事件为 `EnemyPhaseTriggered`，快照包含已触发阶段数量。

## 正式内容

- `data/enemies/v0.5.0/enemies.json`：3 个基础敌人、1 个精英、1 个首领。
- `data/encounters/v0.5.0/encounters.json`：首战、精英战、首领战。
- `data/routes/v0.5.0/routes.json`：唯一固定路线、初始资源和休息选项。
- `data/rituals/v0.5.0/rituals.json`：三步晋升仪式。

## 验证

命令：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/gameplay/route_test_runner.tscn
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/gameplay/test_runner.tscn
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/gameplay/progression_test_runner.tscn
```

结果：

```text
ROUTE_TESTS_OK checks=96
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=90
```

新增路线测试覆盖：

- 正式路线、遭遇、敌人和仪式引用。
- 五节点初始快照与状态解锁。
- 快照中的可执行命令集合随地图、休息和仪式阶段变化。
- 完整首战、精英、休息、首领、仪式胜利链。
- 战斗失败结束路线。
- 两种休息选择及重复使用拒绝。
- 被篡改的讣告答案不泄漏。
- 步骤错误污染、污染上限失败、取消和重试。
- 提示灵性消耗与同步步骤重复提示拒绝。
- 提示按步骤记录，错误后不能在同一阶段重复购买提示。
- 公开仪式快照提供 `hint_spirit_cost`，UI 不自行推测提示成本。
- 封锁回声提供下一战灵性上限成长，包扎提供更高即时生命恢复，两种休息不再只是同一资源的不同数值。
- 序列 8 与 `SequenceAdvanced` 事件。
- 路线状态导出/恢复。
- 首领第 3/6 回合两个阶段、当回合意图加成、压力叠加、各触发一次和独立护盾。

## 困难与解决

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 路线不应复制战斗规则 | Route 自己模拟战斗；调用 BattleEngine；只记录 Battle 结果快照 | Route 只接收战斗结果和玩家终态 | 保留战斗单一规则源 |
| 首领不能只是数值放大 | 在代码判断 boss ID；数据驱动阶段；单独 BossEngine | 数据驱动 `phases` | 通用、可测试，不引入第二战斗引擎 |
| 仪式答案不能暴露给 UI | 完整数据传给 UI；领域 snapshot 过滤答案；独立仪式 UI 驱动 | 公开快照只含线索与选项 | UI 不判断答案 |
| 仪式错误可能永久卡死 | 禁止失败；错误只加污染；污染上限结束路线并保留局外状态 | 采用后者 | 有代价但可继续游玩 |
| v0.5 内容包需要复用 v0.3 卡牌 | 复制卡牌为 v0.5；允许跨包引用 | 数据文件明确 `base_cards_version` | 避免卡牌双份事实源 |

## 跨角色请求

```text
[REQUEST]
从：玩法设计
给：本地数据层
版本：v0.5.0
内容：为 data/routes/v0.5.0/routes.json 与 data/rituals/v0.5.0/rituals.json 建立 schema 和 RouteContentPort 适配器。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层
版本：v0.5.0
内容：扩展敌人 schema 接受可选 phases；扩展 encounter/campaign catalog 接受 base_cards_version，避免把 v0.3 卡牌复制为 v0.5。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层 / app
版本：v0.5.0
内容：CampaignSession 接入 RouteEngine；战斗开始时使用 route.get_battle_player_state()，战斗结束后把 BattleSnapshot.player 传给 RouteCommand.resolve_node；节点边界保存 route.export_persistent_state()。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：UI
版本：v0.5.0
内容：路线地图只读 RouteSnapshot；休息只发送 UseRest；晋升只发送 BeginAscension/SubmitRitualStep/RequestRitualHint/CancelRitual。提示按钮读取 RitualSnapshot.hint_spirit_cost；休息效果显示可选的 max_spirit_delta。不得计算仪式答案、休息效果或晋升条件。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层
版本：v0.5.0
内容：route rest effect schema 接受可选整数 max_spirit_delta；当前运行时已按该字段更新下一战灵性上限并有玩法回归覆盖。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：数值设计
版本：v0.5.0
内容：封锁回声现为“污染 -2、被注视 +1、下一战灵性上限 +1”，包扎仍为生命 +12；请重新采样两种休息的实际选择分布。
[END REQUEST]
```

## 风险与未决问题

- `max_spirit_delta` 已由玩法运行时消费，但需要数据层确认 schema 显式字段与 UI 文案展示。
- 数值模型基于旧休息语义，封锁回声的新取舍需要重新采样。
- 当前路线真实采样约 14—25 分钟，低于原 30—45 分钟目标，需要产品经理裁决是否接受本垂直切片范围。
- UI 与 app 已接入路线；本轮只新增两个展示字段，需在最终截图与全量回归中确认。

## 修改文件

- `src/core/route_command.gd`
- `src/core/route_event.gd`
- `src/core/route_snapshot.gd`
- `src/core/route_command_result.gd`
- `src/core/route_content_port.gd`
- `src/core/ritual_snapshot.gd`
- `src/core/sequence_state.gd`
- `src/gameplay/route_engine.gd`
- `src/gameplay/battle_engine.gd`
- `tests/gameplay/route_test_runner.gd`
- `tests/gameplay/route_test_runner.tscn`
- `data/enemies/v0.5.0/**`
- `data/encounters/v0.5.0/**`
- `data/routes/v0.5.0/**`
- `data/rituals/v0.5.0/**`
- 本报告
