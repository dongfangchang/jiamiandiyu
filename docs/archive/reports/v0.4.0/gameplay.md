# v0.4.0 / 玩法设计工作记录

## 状态

- 版本：`v0.4.0`
- 角色：玩法设计
- 任务：实现身份、战后奖励、灵界祈愿、重复卡转碎片与卡牌升级的最小领域闭环
- 状态：完成
- 最后更新：2026-11-08
- 下一步入口：数据层完成 schema、余额参数路径与存档迁移；UI 只消费快照和命令；app 接线完整短循环

## 本版本目标

在现有单场战斗之上增加可保存、可复现的局外成长，让一次短循环形成“身份 -> 战斗 -> 奖励 -> 祈愿/升级 -> 再战”的明确变化。

## 依赖

- 已关闭的 `v0.3.0` 战斗、内容和存档基线。
- `data/balance/v0.4.0/balance.json` 草案。
- 数据层需提供 progression 内容 schema、余额参数映射和持久状态迁移。
- UI 需消费只读快照与稳定原因码，不计算费用、概率、保底和升级效果。

## 已实现

### 共享契约

新增：

- `src/core/progression_command.gd`
- `src/core/progression_event.gd`
- `src/core/progression_snapshot.gd`
- `src/core/progression_command_result.gd`
- `src/core/progression_content_port.gd`

命令：

- `SelectIdentity(identity_id)`
- `ResolveBattle(outcome)`
- `ClaimReward(reward_id)`
- `DrawGacha(pull_count)`，只允许 1 或 3
- `UpgradeCard(definition_id)`

稳定拒绝原因包括：

- `wrong_phase`
- `unknown_identity`
- `invalid_battle_outcome`
- `reward_not_available`
- `invalid_pull_count`
- `insufficient_divination_tickets`
- `upgrade_not_supported`
- `card_not_owned`
- `card_level_max`
- `insufficient_fragments`
- `content_invalid`
- `balance_missing`

### 成长引擎

`src/gameplay/progression_engine.gd` 实现：

- 初始身份选择阶段。
- 胜利后进入二选一奖励阶段；失败返回 hub，不发放胜利奖励。
- 单抽与三连祈愿、占卜券扣除、稀有度权重和稀有保底。
- 重复卡按配置转化为碎片；守墓人获得额外重复碎片。
- 卡牌等级和碎片扣除。
- 固定种子下的可复现抽卡。
- `export_persistent_state()` 与初始化恢复。
- 战斗中读取的身份修正通过 `apply_battle_modifiers()` 统一应用。
- `build_owned_battle_deck()` 过滤未拥有卡牌。

### 升级进入下一场战斗

`src/gameplay/upgraded_battle_content_port.gd` 是 `BattleContentPort` 装饰器：

- 基础卡牌定义仍来自 `data/cards/v0.3.0/cards.json`。
- 根据卡牌等级和 `progression.json` 的 `effect_index` / `field` / `amount_per_level` 生成只读升级副本。
- 不写回基础内容，不在 `BattleEngine` 内增加等级条件分支。

测试已验证一级 `card.skill.ink_dart` 的伤害从 4 提升到 5，并由真实 `BattleEngine` 在下一场战斗结算为 5 点。

### 正式成长内容

新增 `data/cards/v0.4.0/progression.json`：

- 3 个身份：记者、医生、守墓人。
- 6 张确定性初始卡。
- 7 张可升级抽卡池卡牌，`card.skill.omen` 与 `card.skill.whisper` 为稀有。
- 2 个战后奖励：占卜券、墨刺碎片。
- 7 张可升级卡牌的升级上限与每级增量。

基础卡牌名称、费用和效果金额没有复制到成长文件。

## 固定语义

- 关键战斗牌 `ink_dart`、`paper_guard` 等由初始收藏确定性获得。
- 抽卡随机流名称由 app 装配为 `gacha.draw`；战斗洗牌仍使用 `battle.shuffle`。
- 保底计数只由稀有抽中重置；非稀有增加。
- 三连按三次独立抽取顺序更新保底，不一次批量判定。
- 身份修正由玩法层应用；UI 只显示快照中的 `battle_modifiers`。
- 升级只修改配置指定的 effect 字段，其他字段保持不变。
- 奖励、抽卡和升级均需要 hub 阶段；非法命令不改变状态。

## 验证

命令：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/gameplay/progression_test_runner.tscn
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/gameplay/test_runner.tscn
```

结果：

```text
PROGRESSION_TESTS_OK checks=90
GAMEPLAY_TESTS_OK checks=131
```

新增测试覆盖：

- 正式身份、初始卡、抽卡池、奖励与平衡参数契约。
- 身份不可重复选择。
- 记者、医生和守墓人的单一日志修正。
- 胜利进入奖励，奖励不可重复领取。
- 单抽/三连费用、重复碎片、同种子回放。
- 稀有保底与保底重置。
- 占卜券不足时不扣费。
- 未拥有、碎片不足和满级升级拒绝。
- 升级效果进入真实战斗。
- 未拥有卡牌从下一场牌组过滤。
- 持久状态导出/恢复一致。
- 缺失卡牌引用拒绝初始化。

## 困难与方案

| 困难 | 候选方案 | 最终选择 | 原因 |
|---|---|---|---|
| 卡牌升级会影响战斗，但基础卡定义只能有一份 | 把升级值写进 data/balance；复制 8 张卡到 v0.4；内容端口装饰器 | `UpgradedBattleContentPort` 在读取时应用等级增量 | 保留基础卡唯一源，也不让战斗引擎出现等级特例 |
| 抽卡需要保底且三连可复现 | 一次随机生成三个稀有度；三次独立抽取；使用真实随机数 | 三次顺序抽取，每次更新保底 | 与单抽规则一致，日志和回放更明确 |
| 身份效果可能被 UI 重复实现 | UI 读取 modifiers；玩法提供 apply 方法；app 自行解释 | `apply_battle_modifiers()` | 单一规则入口 |
| 新内容没有 schema | 等 schema 后再写；先写脚本常量；先写内容配置并提 schema 请求 | 内容配置进入 `data/cards/v0.4.0`，提交字段请求 | 内容与规则可测试，schema 仍由数据层独占 |
| 初始是否拥有全部卡池 | 全部拥有导致抽卡只出重复；少量初始导致当前遭遇引用缺失 | 6 张初始、2 张稀有可解锁，并提供 owned deck 过滤 | 保留关键卡确定性，同时给抽卡新卡空间 |

## 跨角色请求

```text
[REQUEST]
从：玩法设计
给：本地数据层
版本：v0.4.0
内容：为 data/cards/v0.4.0/progression.json 建立 schema 和 ProgressionContentPort 适配器。
字段：schema_version、content_version、base_cards_version、identities、starter_card_ids、gacha_pool、reward_options、upgrade_definitions。
校验：身份/奖励/卡牌 ID 唯一；所有卡牌引用存在；rarity 仅 common/rare；effect_index/field/bonus 合法。
期望接口：get_identity_options/get_identity/starter_card_ids/gacha_pool/reward_options/upgrade_definition/has_card_definition。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层
版本：v0.4.0
内容：progression schema 必须增加跨字段不变量：每个 gacha_pool.definition_id 都必须存在于 upgrade_definitions。
原因：无升级路径的卡进入祈愿池会产生无法消耗的重复碎片。
期望错误：schema_validation_failed，并指出具体 definition_id。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层
版本：v0.4.0
内容：BattleBalanceAdapter 增加以下参数路径：
progression.starting_divination_tickets
gacha.single_cost
gacha.triple_cost
gacha.rarity_weights
gacha.rare_pity
gacha.duplicate_fragments
upgrade.cost_by_next_level
reward.amounts
以及 gacha 随机流名称 gacha.draw。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层 / app
版本：v0.4.0
内容：保存 ProgressionEngine.export_persistent_state() 的 phase、identity_id、divination_tickets、collection、pity_counter、reward_option_ids、last_battle_outcome 和 last_gacha_results，并做版本迁移。
恢复必须调用 initialize(saved_state) 或等价验证入口，不能直接覆盖损坏收藏。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：UI
版本：v0.4.0
内容：身份界面只发送 SelectIdentity；奖励只发送 ClaimReward；祈愿只发送 DrawGacha(1/3)；升级只发送 UpgradeCard。
费用、概率、保底、奖励数量、升级成本和结果均读取 snapshot/result events，不自行计算。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：app / 主协调者
版本：v0.4.0
内容：Bootstrap 下一场战斗使用：
1. progression.apply_battle_modifiers(player_state)
2. progression.build_owned_battle_deck(encounter.deck_definition_ids)
3. progression.create_upgraded_content(base_content)
再传给 BattleEngine.initialize。
[END REQUEST]
```

## 风险与未决问题

- 当前 `progression.json` 尚无正式 schema，必须在 app 接线前由数据层补齐。
- `BattleBalanceAdapter` 尚未映射新增平衡参数；当前测试使用隔离的测试端口。
- 应用层尚未接短循环路由和存档；因此本报告不代表端到端已可玩。
- 初始只拥有 6 张卡，当前 v0.3 encounter 含 8 张；app 必须使用 owned deck 过滤，避免未拥有卡牌进入战斗。
- 奖励目前是固定两项，符合 v0.4 最小范围；随机奖励轮换留给后续版本。
- 防御失败返回 hub，不提供战后奖励；之后可根据真实试玩决定是否增加失败保底资源。

## 抽卡池升级缺口修复

- 问题：`card.skill.second_look` 只有 `reveal_intent` 效果，没有可提升的数值字段，却进入祈愿池；重复抽到后会产出无法使用的升级碎片。
- 根因：内容加载只验证卡牌引用存在，没有验证祈愿池卡牌是否具有有效升级定义；同时 `second_look` 被错误加入祈愿池。
- 前向修复：保留 `second_look` 作为确定性拥有的纯工具牌，从祈愿池移除；`ProgressionEngine` 在加载时统一拒绝任何没有升级定义的祈愿池条目。
- 数据边界：没有为单张牌增加战斗特例，也没有在 balance 中复制卡牌定义。
- 新增回归：所有祈愿池卡牌必须有升级定义；`second_look` 仍由新游戏拥有且升级返回 `upgrade_not_supported`；把无升级卡加入祈愿池会返回 `content_invalid`。

## 修改文件

- `src/core/progression_command.gd`
- `src/core/progression_event.gd`
- `src/core/progression_snapshot.gd`
- `src/core/progression_command_result.gd`
- `src/core/progression_content_port.gd`
- `src/gameplay/progression_engine.gd`
- `src/gameplay/upgraded_battle_content_port.gd`
- `data/cards/v0.4.0/progression.json`
- `data/cards/v0.4.0/README.md`
- `tests/gameplay/progression_test_runner.gd`
- `tests/gameplay/progression_test_runner.tscn`
- `docs/reports/v0.4.0/gameplay.md`

未修改 UI、app、infrastructure、schema、balance、art 或 `project.godot`。
