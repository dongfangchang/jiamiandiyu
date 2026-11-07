# v0.3.0 / UI 实现工作记录

## 状态

- 版本：v0.3.0
- 角色：UI 实现
- 任务：实现启动页、战斗页、结果页及只读快照/命令接口
- 状态：完成 UI 可独立验证范围
- 最后更新：2026-11-08
- 下一步入口：由应用层注入检查点摘要、内容显示名、QueryCardPlay 回调并连接命令结果

## 本版本目标

把 v0.2.0 的静态线框变成可运行的 Godot 页面，同时保持 UI 与玩法、存档和随机数隔离。本阶段验证 UI 能接收冻结的 `BattleSnapshot`、提交 `BattleCommand`、展示 `BattlePlayability` 原因和重建结果页。

## 依赖

- 已读取 `AGENTS.md`、`docs/CURRENT_VERSION.md`、`docs/PROJECT_CHARTER.md`、`docs/ARCHITECTURE_CONTRACT.md`、`docs/versions/v0.3.0.md`。
- 冻结玩法接口：`BattleSnapshot`、`BattleCommand`、`BattleCommandResult`、`BattlePlayability`、`BattleEvent`。
- 主协调者已完成 `assets/game/**` 正式 PNG 迁移，UI 只读引用新路径。
- 应用层尚未连接正式 UI，启动摘要、卡片/敌人显示名和 QueryCardPlay 均通过注入接口提供。

## 已完成

### 正式页面

- `scenes/ui/start_screen.tscn` + `src/ui/start_screen.gd`
  - 新游戏、继续、退出意图。
  - 加载中、无检查点、已加载、损坏四类状态。
  - 显示内容版本、序列、牌组规模、上一场结果和保存时间。
  - 无检查点时禁用继续；明确战斗中退出回到最近战后检查点。
  - 不访问 `FileAccess`。

- `scenes/ui/battle_screen.tscn` + `src/ui/battle_screen.gd`
  - 1600×900 三列敌人布局、手牌区、战斗记录和玩家资源区。
  - 显示回合、阶段、revision、生命、护盾、灵性、corruption、attention、牌堆、弃牌、敌方压力和可见意图。
  - 选择/取消手牌，选择敌人目标，pending 防重复。
  - 通过注入的 QueryCardPlay 回调显示可打出、资源不足、非法目标、错误阶段等原因。
  - 只发送 `BattleCommand.play_card` 和 `BattleCommand.end_turn`。
  - 接收 `BattleCommandResult`，丢弃旧 revision，重绘快照并追加事件。
  - 战斗结束发出 `battle_finished(BattleSnapshot)`，不在 UI 切换业务路由。

- `scenes/ui/result_screen.tscn` + `src/ui/result_screen.gd`
  - 显示胜利、失败、结束原因、战斗编号和回合数。
  - 保存状态区分等待确认、已保存、无需重复保存、保存失败。
  - 保存未确认前不会宣称进度已保存。

- `src/ui/mask_ui_theme.gd`
  - 统一旧纸、墨黑、暗金、干血红和冷雾灰视觉。
  - 系统字体回退、面板、按钮、标签、计量条和背景加载。

### 资源与旧预览

- 正式页面全部引用 `res://assets/game/**`。
- 旧的 `scenes/ui/ui_preview.tscn` 保留为静态视觉预览，并同步更新到迁移后的 PNG 路径。
- UI 自有生产文件不包含 `pollution`，统一使用 `corruption`。
- 未使用远程图片、CDN、绝对路径或新增第三方依赖。

## 验证

### UI 冒烟测试

场景：`res://tests/ui/ui_smoke_runner.tscn`

```text
UI_SMOKE_OK checks=17
```

覆盖：无存档禁用继续、加载检查点启用继续、快照渲染、手牌选择、目标选择、pending、命令发出、结果清理 pending、非法目标阻止命令、规则层拒绝原因显示、取消选择、事件记录、胜利结果和保存确认。

### 页面独立启动

以下场景使用 Godot 4.7.2 headless 启动并退出，退出码均为 `0`：

```text
res://scenes/ui/ui_preview.tscn
res://scenes/ui/start_screen.tscn
res://scenes/ui/battle_screen.tscn
res://scenes/ui/result_screen.tscn
```

### 实际渲染检查

使用 Godot OpenGL Compatibility 渲染并生成到忽略目录 `.tools/ui-captures/`：

```text
start_screen.png
battle_screen.png
result_screen.png
```

已检查：标题与状态层级、1600×900 排版、三列敌人、手牌文字、保存状态和结果页没有遮挡或越界。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 理由 | 风险 |
|---|---|---|---|---|
| 战斗页最容易自行判断目标或胜负 | UI 自己检查目标；完全交由 app；UI 只消费 QueryCardPlay 与快照 | UI 只显示回调结果并发送命令 | 保持规则单一来源 | app 未接 QueryCardPlay 时无法打出牌 |
| 卡牌和敌人显示名不在 Snapshot | 在 UI 内置内容表；从定义文件读取；由 app 注入标签 | app 注入 `card_labels` / `enemy_labels` | UI 不读文件、不建立第二内容源 | 未注入时显示技术 ID 的简化文本 |
| 多敌人没有独立美术 | 临时生成三套图；重复使用提灯追猎者；只显示剪影 | 当前重复使用一张敌人图并压暗死亡目标 | 避免新增错误占位资产 | 战斗辨识度暂受限制 |
| 命令结果可能重复或乱序 | 每事件立即重绘；按 revision 丢弃旧快照；UI 自行结算 | 直接应用最新结果并按 revision 拒绝旧快照 | 与冻结事件模型一致 | app 必须保证结果按调用顺序送回 |
| 保存确认异步 | 点击后立即离开；显示“保存中”并等待 app 通知 | 结果页保存状态由 app 注入 | 不误报成功 | 真实保存仍未接线 |

## 跨角色请求

```text
[REQUEST]
从：UI 实现
给：本地数据层 / 主协调者
版本：v0.3.0
内容：应用层需要连接启动页的信号，调用 inspect_checkpoint/checkpoint_summary 后向 show_checkpoint_status 传入纯数据；新游戏创建 GameSession 后切换到战斗页。
原因：UI 不读取 FileAccess。
期望接口：start_new_game、inspect_checkpoint 的现有公开结果。
截止检查点：真实主链集成前
[END REQUEST]
```

```text
[REQUEST]
从：UI 实现
给：主协调者
版本：v0.3.0
内容：绑定 BattleScreen.configure(encounter_title, card_labels, enemy_labels, query_handler)；连接 command_requested 到 GameSession.submit，并把 BattleCommandResult 送回 apply_command_result。
原因：UI 只表达选择意图，不持有玩法引擎。
期望接口：GameSession.query_card_play/submit/get_snapshot。
截止检查点：真实战斗验收前
[END REQUEST]
```

```text
[REQUEST]
从：UI 实现
给：主协调者
版本：v0.3.0
内容：战斗结束信号之后切换结果页，并用 GameSession.last_checkpoint_result 映射 saved/already_saved/failed；保存状态未确认时不可提示已保存。
原因：结果页不直接访问存档服务。
期望接口：InfrastructureResult.ok/code/message。
截止检查点：战后保存验收前
[END REQUEST]
```

## 风险与未决问题

- 正式页面尚未接入 app，不能被描述为完整可玩链。
- 三种敌人共用提灯追猎者图片；后续应通过资源注册表提供独立敌人视觉。
- UI 冒烟测试使用手动快照，不代表真实内容 schema 或真实战斗事件顺序已通过。
- 键盘焦点依赖 Godot 默认顺序，尚未做完整 Tab/Enter/Esc 回归。
- 结果页“再进行一场”只发出意图；重开策略由应用层决定。

## 下一步入口

1. 应用层连接启动页摘要、新游戏/继续信号。
2. 将 GameSession 封装成只读快照输入与 QueryCardPlay 回调。
3. 连接战斗命令结果和结束页保存状态。
4. 真实首战内容就绪后，补一次 UI→app→gameplay→save 的集成测试。
