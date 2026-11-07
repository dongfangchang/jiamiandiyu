# v0.5.0 / UI 设计

## 状态

- 版本：`v0.5.0`
- 角色：UI 设计
- 任务：短路线地图、休息、三步晋升仪式、路线结算及美术实机审稿
- 状态：完成 UI 页面、v0.5 美术实机复审与最终字段对齐
- 最后更新：2026-11-08
- 下一步入口：app 将 `RouteSnapshot`、`RitualSnapshot` 和 `RouteCommandResult` 注入四个页面

## 依赖

- `RouteSnapshot`、`RitualSnapshot`、`SequenceState`、`RouteCommand` 与 `RouteCommandResult`。
- 玩法公开快照不包含仪式答案。
- 正式资源已迁移到 `assets/game/v0.5.0/**`。
- 已关闭的 v0.3/v0.4 战斗、身份、奖励、祈愿和升级页面。

## 已完成

### 路线地图

- `src/ui/route_screen.gd`
- `scenes/ui/route_screen.tscn`
- 五节点、稳定顺序、当前位置、已完成和未到达状态。
- 生命、灵性、污染和被注视全部从 `RouteSnapshot.run_state` 读取。
- 普通、精英、休息、首领和仪式按钮只发送 `RouteCommand`。
- 仪式节点发送 `BeginAscension`，其他可用节点发送 `SelectNode`。
- 路线结束状态提供结算入口。

### 休息页面

- `src/ui/rest_screen.gd`
- `scenes/ui/rest_screen.tscn`
- 两种休息选择、效果说明、pending 和拒绝提示。
- 效果文案完全来自快照中的 `effects` 字段；支持展示 `hp_delta`、`corruption_delta`、`attention_delta` 和下一战 `max_spirit_delta`。
- `rest.seal_echo` 明确显示“污染 -2 · 被注视 +1 · 下一战灵性上限 +1”，与恢复生命的即时生存路线形成区分。
- 休息阶段不提供伪造的取消操作，避免界面暗示一个领域不支持的返回命令。

### 晋升仪式

- `src/ui/ritual_screen.gd`
- `scenes/ui/ritual_screen.tscn`
- 支持 `select_ids`、`ordered_ids`、`select_id` 三种公开步骤类型。
- 显示线索、步骤、已选顺序、污染、灵性、错误、提示和成功/失败结果。
- 提交发送 `SubmitRitualStep`；提示发送 `RequestRitualHint`；退出发送 `CancelRitual`。
- 提示按钮读取只读 `hint_spirit_cost`，显示精确灵性成本；灵性不足仍由领域的 `insufficient_spirit` 原因码反馈。
- UI 不包含正确答案、正确顺序或污染上限判断。

### 路线结算

- `src/ui/route_result_screen.gd`
- `scenes/ui/route_result_screen.tscn`
- 显示晋升完成/路线中断、完成节点、序列、剩余资源和保存状态。
- 成功使用仪式背景，失败使用路线地图背景。
- 保存状态支持 `saved`、`backup`、`failed` 和 pending 文案。

### 战斗美术映射

- `battle_screen.gd` 增加精英 `enemy.mirror_hound_echo` 和首领 `enemy.mirror_baron`。
- 首领使用独立 `assets/game/v0.5.0/enemies/enemy-mirror-baron.png`。
- 精英回声猎犬使用匹配的猎犬图像，不使用首领图或未知占位。

## API 交接

```text
RouteScreen
  apply_snapshot(RouteSnapshot)
  apply_command_result(RouteCommandResult)
  set_pending(bool)
  route_command_requested(RouteCommand)
  result_requested
  hub_requested

RestScreen
  apply_snapshot(RouteSnapshot)
  apply_command_result(RouteCommandResult)
  set_pending(bool)
  route_command_requested(RouteCommand)

RitualScreen
  apply_snapshot(RitualSnapshot)
  apply_command_result(RouteCommandResult)
  set_pending(bool)
  route_command_requested(RouteCommand)

RouteResultScreen
  show_result(RouteSnapshot, save_state)
  set_save_state(save_state)
  hub_requested
```

app 必须只在玩法接受命令后切换页面。UI 的 pending 只防止重复点击，不能替代领域幂等与阶段检查。

## UI 对美术的审稿

审稿依据：

- `.tools/ui-captures/route_map_screen.png`
- `.tools/ui-captures/rest_screen.png`
- `.tools/ui-captures/ritual_screen.png`
- `.tools/ui-captures/route_result_screen.png`
- `.tools/ui-captures/boss_battle_screen.png`

结论：`v0.5.0` 原型范围通过。

| 资产 | 结论 | 说明 |
|---|---|---|
| 短路线地图 | 通过 | 五节点暗色卡片在羊皮纸背景上可辨，未出现背景文字穿透 |
| 休息旧宅 | 通过 | 足够暗化，两种操作区与资源文字无冲突 |
| 镜厅男爵 | 通过 | 在战斗三列中与普通敌人轮廓明显不同，中央单首领构图成立 |
| 晋升仪式背景 | 通过 | 中央与右侧证物区可容纳选项、按钮和卡面 |
| 三张仪式牌 | 通过 | 只提供证物视觉，不泄露答案或规则文字 |
| 路线三态图标 | 通过 | 当前、完成、未到达在路线卡片上可区分 |
| 晋升成功/失败图标 | 通过 | 与结果标题和颜色共同表达，不单靠图标 |

UI 没有要求美术在本版本返工。角色美术仍需由 UI 后续统一审稿，但以下问题不阻塞 v0.5：

- 路线地图的节点卡主体留白较大，未来可在节点上增加小型缩略图或事件摘要。
- 仪式步骤选项位于上缘，中央留白偏多；已作为仪式台留白接受。
- 程序化矢量美术的细节精度有限，不影响当前信息识别。

## 验证

```text
UI_SMOKE_OK checks=33
PROGRESSION_UI_SMOKE_OK checks=41
V05_ROUTE_UI_SMOKE_OK checks=62
Godot resource import: exit 0
Main scene headless --quit-after 5: exit 0
```

v0.5 新测试覆盖：

- 12 个正式 v0.5 资源存在。
- 五节点布局与三种状态。
- 节点禁止/可用按钮。
- `SelectNode` 与 `BeginAscension` 命令。
- 路线拒绝原因显示。
- 两种休息选择及快照效果文案。
- 下一战灵性上限变化的只读展示。
- 仪式三种步骤输入、顺序保持、提交、提示、取消、拒绝与成功状态。
- 仪式提示精确成本，以及灵性不足的领域拒绝提示。
- 晋升完成、路线中断、保存成功、保存失败和备份状态。
- 精英与首领敌人美术映射。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 界面不能泄露仪式答案 | UI 判断后显示对错；只显示领域快照；额外复制答案 | 只显示公开 RitualSnapshot | 保持玩法单一事实源 |
| 多选与排序交互不同 | 共用按钮；分开选择状态机；每次弹窗 | 单页本地选择顺序，提交时发送完整数组 | 保持 30—90 秒仪式节奏 |
| 休息效果不能由 UI 计算 | 显示变化后的数值；直接列出快照 effects；只显示说明 | 直接列出快照 effects，包括下一战灵性上限变化 | 避免复制规则 |
| 路线阶段存在不可取消节点 | 伪造返回；隐藏不可用操作；显示按钮但让 app 忽略 | 隐藏领域不支持的休息取消 | 避免点击无响应的坑 |
| 首领与普通敌人共用图像 | 继续共用猎犬图；只用名称区分；独立首领图 | 独立首领图，精英使用匹配猎犬图 | 三列战斗中保持辨识度 |

## 风险

- `RitualSnapshot.hint_spirit_cost` 已提供只读提示费用，仪式按钮显示精确灵性成本；资源不足仍由领域拒绝原因兜底，UI 不判断答案。
- 路线地图底部仍有返回白昼档案入口，app 必须明确该入口只暂停到最近节点检查点，不能丢失路线状态。
- 路线阶段恢复由 app 决定，UI 不持有持久状态。
- 未来节点数量增加时，五列路线布局需要改为滚动或地图路线布局。

## 跨角色请求

```text
[REQUEST]
从：UI
给：app
版本：v0.5.0
内容：路线页面接入 RouteSnapshot/RouteCommandResult；战斗结束后使用 RouteCommand.resolve_node；休息与仪式仅按玩法结果切页。
截止检查点：v0.5 app 集成前
[END REQUEST]
```

```text
[REQUEST]
从：UI
给：主协调者 / app
版本：v0.5.0
内容：并行修改期间曾出现一次 4 项检查点/序列恢复失败，待相关角色写入完成后重跑已恢复为 `APP_V05_INTEGRATION_OK checks=73`；请在全量回归时再次确认 checkpoint 保存 `kind=route`、`sequence.current_sequence=8` 和 completed route resume。
截止检查点：v0.5.0 关闭前
[END REQUEST]
```

## 修改文件

- `src/ui/route_ui_catalog.gd`
- `src/ui/route_screen.gd`
- `src/ui/rest_screen.gd`
- `src/ui/ritual_screen.gd`
- `src/ui/route_result_screen.gd`
- `src/ui/battle_screen.gd`
- `scenes/ui/route_screen.tscn`
- `scenes/ui/rest_screen.tscn`
- `scenes/ui/ritual_screen.tscn`
- `scenes/ui/route_result_screen.tscn`
- `tests/ui/v05_route_ui_smoke_runner.gd`
- `tests/ui/v05_route_ui_smoke_runner.tscn`
- `tests/ui/ui_capture_runner.gd`
- 本报告

## 下一步入口

app 接入四个页面后，应在真实主链中重新截图并确认：

1. 战斗胜利返回路线地图时，当前位置正确。
2. 休息确认后不可重复执行。
3. 仪式错误不切页，成功/失败才进入路线结算。
4. 返回白昼档案时，路线状态已建立最近节点检查点。
