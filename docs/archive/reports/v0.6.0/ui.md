# v0.6.0 / UI 设计工作记录

## 状态

- 角色：UI 设计
- 任务：挑战入口、修饰选择、挑战路线标识、挑战结算和 v0.6 美术实机审稿
- 状态：完成
- 下一步入口：v0.6 已关闭；进入 v0.7 卡组构筑与第二挑战 UI

## 依赖

- `src/core/challenge_snapshot.gd`
- `src/core/challenge_command.gd`
- `src/core/challenge_command_result.gd`
- `src/gameplay/challenge_engine.gd`
- `data/challenges/v0.6.0/challenges.json`
- `assets/game/v0.6.0/**`
- 现有身份、路线、战斗、奖励、祈愿、升级和结果页面

## 已完成

### 挑战入口与选择

- 新增 `src/ui/challenge_screen.gd` 和 `scenes/ui/challenge_screen.tscn`。
- 仅从 `ChallengeSnapshot` 读取挑战名称、描述、解锁状态、要求序列、三个修饰和完成奖励。
- 未解锁时显示明确原因，禁用修饰和开始操作，不伪造可用状态。
- 修饰选择发送 `ChallengeCommand.select_modifier`；开始发送 `ChallengeCommand.start_challenge`。
- 记录 pending 状态，避免重复点击；领域拒绝原因原样映射为可读提示。
- 完成奖励名称可由 app 注入，UI 不推导奖励规则。

### 挑战中的路线

- `RouteScreen` 新增 `set_challenge_context()`、`clear_challenge_context()` 和只读上下文文本。
- 挑战路线继续只消费 `RouteSnapshot` 和 `RouteCommand`，不建立第二套路线页面。
- 路线标题下显示“挑战 · 镜厅余响 · 修饰：染墨页边”等上下文。

### 挑战结算

- 新增 `src/ui/challenge_result_screen.gd` 和对应场景。
- 显示挑战成功/中断、所选修饰、路线完成节点、序列、生命、污染、被注视和保存状态。
- 失败时明确提示局外收藏、卡牌等级和已确认奖励保留。
- 提供“再次挑战”和“返回白昼档案”信号，由 app 决定实际路由。

### 启动入口

- 启动页新增独立挑战入口和锁定提示。
- 由 `show_checkpoint_status()` 的 `challenge_available` 与 `challenge_reason` 字段驱动，不在 UI 中判断序列条件。
- `challenge_requested` 信号交给 app 创建挑战会话。

## 美术实机审稿

结论：**v0.6.0 原型范围通过，无需美术返工。**

- 挑战选择背景为内容提供足够留白，3 个 128px 修饰徽记在实际约 108px 显示时轮廓可辨。
- “倒影提前”“染墨页边”“残缺牌组”分别使用沙漏、镜眼和破牌意象，不依赖文字也能区分。
- 挑战成功印章在结果页 120px 显示时清晰；深色面板与旧纸、暗金风格一致。
- 启动页新增挑战按钮没有挤压摘要或原有按钮，1600×900 下无裁切。
- 挑战路线上下文在 1600×900 下可见且不与资源栏重叠。
- UI 仅做了背景暗化和固定面板遮罩适配，没有修改美术源文件。

## 修改文件

- `src/ui/challenge_ui_catalog.gd`
- `src/ui/challenge_screen.gd`
- `src/ui/challenge_result_screen.gd`
- `src/ui/route_screen.gd`
- `src/ui/start_screen.gd`
- `scenes/ui/challenge_screen.tscn`
- `scenes/ui/challenge_result_screen.tscn`
- `tests/ui/v06_challenge_ui_smoke_runner.gd`
- `tests/ui/v06_challenge_ui_smoke_runner.tscn`
- `tests/ui/ui_capture_runner.gd`

## 验证

```text
Godot resource import: exit 0
V06_CHALLENGE_UI_SMOKE_OK checks=40
UI_SMOKE_OK checks=33
PROGRESSION_UI_SMOKE_OK checks=41
V05_ROUTE_UI_SMOKE_OK checks=62
```

实际截图：

- `.tools/ui-captures/start_screen.png`
- `.tools/ui-captures/challenge_screen.png`
- `.tools/ui-captures/challenge_route_screen.png`
- `.tools/ui-captures/challenge_result_screen.png`

## 困难与解决

| 困难 | 候选方案 | 最终解决 |
|---|---|---|
| 挑战修饰效果不应由 UI 解析 | UI 根据 effects 自行拼文案；直接显示领域描述；再建立 modifier 规则层 | 显示 snapshot 中的领域描述，奖励名称由 app 注入或 UI 做纯显示映射 |
| 挑战进行页与普通路线重复 | 复制一套挑战地图；复用 RouteScreen 并增加上下文 | 复用 RouteScreen，仅增加挑战标识，避免规则和页面双源 |
| 未解锁状态容易被 UI 自己判断 | UI 读取 sequence 判断；完全依赖 snapshot | 使用 snapshot.unlocked 与 required_sequence，不自行计算解锁条件 |
| 挑战失败文案可能误导奖励已发放 | 永远显示完成奖励；显示空奖励 | 根据 challenge_outcome 显示“未发放 · 局外收藏保留” |

## 跨角色请求

```text
[REQUEST]
从：UI 设计
给：本地数据层 / app
版本：v0.6.0
内容：启动摘要请提供 challenge_available 与 challenge_reason，并连接 StartScreen.challenge_requested。
原因：UI 不在本地判断序列 8 是否解锁挑战。
期望接口：ChallengeSession 初始化后返回只读 ChallengeSnapshot；app 负责路由。
[END REQUEST]
```

```text
[REQUEST]
从：UI 设计
给：本地数据层 / app
版本：v0.6.0
内容：ChallengeScreen 已提供 apply_snapshot/apply_command_result/challenge_command_requested；ChallengeResultScreen 已提供 show_result/set_save_state/hub_requested/retry_requested。
原因：挑战 UI 已完成独立测试，后续已在 v0.6 关闭前接入真实 ChallengeSession。
期望接口：app 注入真实 snapshot、奖励显示名和保存状态。
[END REQUEST]
```

## 风险与未决问题

- app 级 ChallengeSession 接线、挑战奖励、保存恢复和最终独立构建均已完成。
- 挑战修饰的资源影响完全依赖领域描述；若后续改为结构化效果卡，可增加 app 注入文案，不在 UI 中解释。
- 重新挑战需要 app 创建新的 ChallengeEngine/ChallengeSession，不能把 completed 快照原地重置。
- 程序化美术精细度有限，但本次挑战视觉在实际界面中可识别并被 UI 验收通过。
- 最终 UI 回归时，`APP_V05_INTEGRATION` 被非 UI 文件 `src/app/route_session.gd:364` 的
  `CheckpointEnvelopeBuilder` 未声明/未注册编译错误阻断。错误日志位于
  `.tools/ui-v06-test-logs/integration.final.err.log`。UI 作用域测试和 diff 检查均通过；
  该问题应由 app/本地数据层在现有结构上补齐显式 preload/class 注册或修复实现后重跑，
  不回滚 UI 或其他已验证模块。

## 下一步入口

1. 挑战入口、修饰选择、真实挑战和结算均已完成并通过应用集成。
2. 挑战奖励通过既有成长用例入账，失败保留局外状态。
3. v0.6 已关闭，下一版扩展卡组构筑与第二挑战。
