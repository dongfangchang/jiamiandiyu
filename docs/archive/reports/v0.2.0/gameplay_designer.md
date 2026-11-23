# v0.2.0 / 玩法设计工作记录

## 状态

- 状态：完成（设计冻结 + 最小玩法实现检查点）
- 当前任务：已提交玩法方向与接口，并按 ADR-0002/ADR-0003 实现最小确定性子集。
- 最后更新：2026-11-08
- 下一步入口：本地数据层提供随机/内容/数值适配器，UI 接入冻结快照与命令。

## 本版本目标

在不实现生产代码的前提下，确定首版战斗采用什么操作方式，并把“白天身份 -> 夜间战斗 -> 奖励 -> 抽卡/升级 -> 序列晋升”的规则语义收敛到可实现、可测试、不会迫使 UI、数值和本地数据层各自猜接口的程度。

本报告中的“决定”是玩法设计提交的唯一推荐，尚需产品经理写入 ADR 后才成为冻结接口。本报告没有实现任何游戏功能。

## 依赖

- 必需文档：`AGENTS.md`、`docs/CURRENT_VERSION.md`、`docs/PROJECT_CHARTER.md`、`docs/ARCHITECTURE_CONTRACT.md`、`docs/versions/v0.2.0.md`。
- 依赖角色：
  - UI 设计：确认快照字段能支持三列布局、手牌、目标选择、非法原因、危险阈值和事件表现。
  - 数值设计：为规则提供参数 ID、阈值、费用、敌人区间、奖励与抽卡概率，不改变规则语义。
  - 本地数据层：实现内容读取、Balance 读取、可复现随机流、检查点存档和确定性回放所需基础能力。
- 期望接口：`BattleCommand`、`BattleCommandResult`、`BattleEvent`、`BattleSnapshot`、`RandomPort`、`ContentPort`、`BalancePort`。公共类型在冻结前不创建。

## 决策摘要

| 开放问题 | 玩法设计建议 | 关键理由 | 尚需谁确认 |
|---|---|---|---|
| 自动行动还是逐张出牌 | **玩家逐张出牌，三列位置作为轻量牌阵** | 交互反馈直接，卡牌差异和污染代价可见，20 张卡的内容可被玩家理解并形成构筑 | 产品经理 ADR、UI 确认操作复杂度 |
| 首版途径 | **只做“占卜家”一条途径，演示阶段完成序列 9 -> 8** | 与预视、改判、标记和抽牌天然匹配；一条途径能显著控制内容和数值量 | 产品经理 ADR |
| 抽卡是否含人格牌 | **包含人格牌、灵界回响和封印物三类；首个人格与关键基础牌确定性获得** | 保留“抽取身份”的产品钩子，同时避免运气卡死；人格只在开局前选择，战斗中不能切换 | 产品经理 ADR、数值确认经济 |
| 首次晋升试炼 | **“被篡改的讣告”三段式轻解谜** | 30—90 秒可完成，符合占卜家主题，错误有代价但不硬卡关 | 产品经理 ADR |
| MVP 存档检查点 | **每日开始、战斗结算后、抽卡/升级完成后保存；v0.3 不支持战斗中退出续战** | 避免首版引入复杂战斗序列化，同时满足继续游戏和防丢档 | 产品经理 ADR、本地数据层确认 |

## 1. 操作方式比较与唯一推荐

### 1.1 候选 A：自动行动 + 玩家部署

玩家每回合把卡牌放入六格牌阵，之后自动结算。

优点：

- 玩家单回合输入少，适合快速原型。
- 卡牌持续存在，容易表现“阵列协同”。
- UI 动画和操作规模较小。

缺点：

- 关键结算由系统自动完成，玩家较难从卡面直接理解目标、顺序和失败原因。
- 卡牌差异容易退化为数值和站位加成。
- 首次内容量只有 20 张时，自动战斗的观感收益不足以抵消构筑深度的损失。
- 污染、被注视和禁忌代价的即时反馈会被自动流程冲淡。

### 1.2 候选 B：玩家逐张出牌

玩家从手牌选择卡牌、支付灵性、选择目标并立即结算，然后可以继续出牌或结束回合。

优点：

- 每张卡的价值、目标合法性和代价能在操作当下被理解。
- 三列敌人位置仍有阵型意义，但不需要额外制作单位移动、自动寻敌或持续召唤系统。
- 抽到关键牌后的组合反馈更直接，适合抽卡和升级驱动的产品。
- 更容易用少量卡牌形成“进攻、守势、占卜”三个清晰方向。

缺点：

- 需要处理目标选择、取消、非法目标和重复点击。
- UI 信息密度高于纯自动战斗。
- 每张卡的即时效果必须定义清楚，不能用模糊的“自动施放”掩盖规则。

### 1.3 决定

**首版采用候选 B：玩家逐张出牌。**

“牌阵”在本首版中的明确含义是：

- 战斗区有三列，每列最多一个敌人。
- 玩家卡牌可以指定一列/一个敌人，部分卡牌不限位置。
- v0.3 不做持续召唤物、单位移动、六格随从养成或自动寻敌。
- 三列为目标与威胁布局，不是另一套卡牌位置收益系统。

这项选择只影响规则与接口，不代表 UI 已完成。

## 2. 首版规则闭环

### 2.1 一局的结构

```text
新游戏
  -> 选择人格（报道者默认解锁）
  -> 日间事件
  -> 夜间地图
  -> 战斗 / 非凡事件
  -> 战后奖励
  -> 安全屋：升级、抽卡、整理牌组
  -> 下一天
  -> 达到晋升条件
  -> “被篡改的讣告”晋升试炼
  -> 序列变化
  -> 继续短循环或结束本局
```

失败时结束当前探索，保留已获得的人格、收藏、抽卡资源和安全屋升级；不惩罚到必须从头刷基础卡。

### 2.2 日间身份

- 每次新探索开始前选择一个已解锁人格。
- 探索期间锁定，不允许战斗中切换，避免身份状态、牌组来源和被动效果产生不可追踪的级联变化。
- 三个人格使用稳定 ID：
  - `identity.reporter`
  - `identity.doctor`
  - `identity.gravedigger`
- 日间从三个固定动作中选一个：
  - `work`：获得探索货币，并调整被注视度。
  - `investigate`：获得线索，并增加被注视度。
  - `prepare`：调整灵性/污染，并推进下一场战斗的准备。

具体增减值由数值设计提供。玩法层只定义动作合法条件、结果顺序和边界。

### 2.3 夜间地图与战斗

- 夜间短地图由少量节点构成：普通战斗、非凡事件、精英战斗、晋升入口。
- v0.3 垂直切片只实现一个新游戏 -> 一场战斗 -> 结算的最小链路。
- 地图路线和奖励表使用稳定 ID，不从 UI 临时生成。
- 战斗开始前，应用层读取遭遇定义、敌人定义和人格配置，再创建 BattleEngine。

### 2.4 回合规则

1. 回合开始：玩家护盾清空，灵性恢复到上限；抽牌至手牌基准数。
2. 敌人意图生成本回合行动。默认只公开行动类别，具体数值和顺序需要通过占卜效果揭示。
3. 玩家进入行动阶段，可逐张打牌或结束回合。
4. 结束回合后，按以下顺序结算：
   - 玩家回合结束事件与持续状态计时。
   - 敌人按列顺序行动。
   - 检查玩家失败。
   - 检查所有敌人死亡。
   - 进入下一回合或结束战斗。
5. 达到最大回合数仍未胜利时，按失败处理，原因记录为 `round_limit`。

灵性每回合重置，不用“未使用灵性跨回合缓存”。卡牌效果明确给出的额外灵性只在当前回合生效，除非以后新增状态，否则不得跨回合保留。

### 2.5 目标与出牌

- 一张牌有三类目标之一：`none`、`self`、`enemy`。
- `enemy` 必须指向当前存活敌人；列位置由目标敌人决定。
- 无目标的牌不能要求玩家选择敌人。
- 目标选择是 UI 本地状态；“取消选择”不需要领域命令。
- 合法性由玩法层查询和最终校验共同决定。UI 可以提前展示可打出/不可打出，但不能自行判断规则。
- 扣费、效果、弃牌和事件产生属于一个顶层命令结果。命令被拒绝时不得扣费，也不得改变任何领域状态。

### 2.6 重复操作与幂等语义

首版不引入全局命令总线，也不需要为每个按钮生成 UUID。命令依靠实例 ID 和阶段实现“效果幂等”：

- 卡牌打出后从手牌移除并进入结算/弃牌区；同一 `card_instance_id` 再次打出会返回 `card_not_in_hand`，不会再次扣费。
- `EndTurn` 第一次成功后阶段立即改变；重复提交返回 `wrong_phase`。
- 非法目标、资源不足和卡牌不存在都返回拒绝结果，不产生部分状态。
- UI 在等待事件表现时暂停继续输入；即使没有暂停，领域拒绝也能保证不重复结算。

不建立无调用方需要的命令历史、分布式幂等键或通用事件总线。

### 2.7 随机与可复现性

- 新探索生成或接收一个 `run_seed`。
- 每个随机用途使用有命名的独立随机流，至少包括：
  - `battle.shuffle`
  - `battle.enemy_intent`
  - `reward.offer`
  - `gacha.draw`
  - `ritual.variant`
- 随机流由本地数据层实现，玩法层只调用抽象端口。
- 战斗开始时完成牌堆洗牌；抽牌时消耗 `battle.shuffle` 流。
- 敌人意图在回合开始时生成，随后固定，不再因 UI 刷新变化。
- 抽卡在确认抽取时一次性结算，抽卡动画不重新抽取。
- 日志至少记录根种子、随机流名称、战斗 ID 和命令顺序，以支持固定种子回放。

### 2.8 胜负与异常

- `VICTORY` 与 `DEFEAT` 是合法战斗状态，不是异常。
- 玩家 HP 降到 0 或以下时，优先判负。
- 所有敌人死亡且玩家仍存活时判胜。
- 达到最大回合数判负，原因是 `round_limit`。
- 数据缺失、效果未注册、非法快照属于可诊断错误，不能静默替换为默认卡牌或默认数值。

## 3. 状态机

### 3.1 探索状态

| 状态 | 允许操作 | 下一状态 |
|---|---|---|
| `RUN_INIT` | 创建种子、加载人格与收藏 | `DAY_START` |
| `DAY_START` | 选择日间动作 | `DAY_RESOLVED` |
| `DAY_RESOLVED` | 查看日间结果，进入地图 | `MAP_SELECT` |
| `MAP_SELECT` | 选择当前可达节点 | `BATTLE_INIT` / `EVENT` |
| `BATTLE_INIT` | 读取遭遇并初始化战斗 | `BATTLE` |
| `BATTLE` | 提交战斗命令 | `BATTLE_RESULT` |
| `BATTLE_RESULT` | 查看胜负并进入奖励或探索失败 | `REWARD` / `RUN_FAILED` |
| `REWARD` | 从确定性奖励中选择一项 | `SAFEHOUSE` |
| `SAFEHOUSE` | 抽卡、升级、整理牌组 | `DAY_END` / `ASCENSION` |
| `DAY_END` | 推进天数与检查点保存 | `DAY_START` |
| `ASCENSION` | 进行短试炼 | `SEQUENCE_GAINED` / `DAY_START` |
| `RUN_FAILED` | 结算保留内容 | `RUN_ENDED` |

### 3.2 战斗状态

```text
INIT
  -> ROUND_START
  -> PLAYER_ACTION
       -> PLAYER_ACTION       合法打牌
       -> ENEMY_ACTION        EndTurn
       -> VICTORY             所有敌人死亡
       -> DEFEAT              玩家死亡或回合上限
  -> ENEMY_ACTION
       -> ROUND_START         双方存活
       -> DEFEAT              玩家死亡
       -> VICTORY             敌人全部死亡
```

状态说明：

- `REROLL_OR_REFRESH` 不在首版战斗状态机中。
- `PLAYER_ACTION` 内允许任意多张可支付卡牌，直到玩家结束回合或资源不足。
- `ENEMY_ACTION` 是同步结算阶段，不接收玩家出牌命令。
- UI 的事件动画可以跨越多个领域阶段，但领域状态不以动画时长作为判定条件。

## 4. 命令与查询

### 4.1 玩法命令

| 命令 | 前置条件 | 成功结果 | 拒绝原因 |
|---|---|---|---|
| `PlayCardCommand(card_instance_id, target_id?)` | `PLAYER_ACTION`，卡牌在手，资源足够，目标合法 | 扣费、按数组顺序结算效果、移动卡牌、产生事件批次、返回新快照 | `wrong_phase`、`card_not_in_hand`、`insufficient_spirit`、`invalid_target` |
| `EndTurnCommand` | `PLAYER_ACTION` | 玩家行动结束，进入敌人结算，产生事件批次 | `wrong_phase` |

以下行为不创建领域命令：

- UI 点选卡牌、点选敌人、取消点选、悬停查看说明。
- 抽卡动画、伤害数字、抖屏、音效和页面转场。
- 打开牌组详情或查看收藏。

以下属于应用用例，不属于 BattleEngine 命令：

- `StartRun`
- `ChooseIdentity`
- `PerformDayAction`
- `EnterEncounter`
- `ClaimBattleReward`
- `DrawGacha`
- `UpgradeCard`
- `AttemptAscension`

### 4.2 出牌查询

玩法层提供只读查询：

```text
QueryCardPlay(card_instance_id, target_id?) -> Playability
```

`Playability` 至少返回：

```text
playable: bool
reason_code: playable | wrong_phase | card_not_in_hand |
             insufficient_spirit | invalid_target
```

查询不得消耗随机数、修改手牌、触发状态或写日志副作用。

### 4.3 命令结果

一个命令结果至少包含：

```text
accepted
reason_code
events
snapshot
```

- `accepted=false` 时 `events` 为空，`snapshot` 是未变化的当前快照。
- `accepted=true` 时事件按领域发生顺序排列，`snapshot` 是该命令全部结算后的只读状态。
- UI 先使用快照作为最终显示数据，再按事件顺序播放动画。事件不能反向修改结算结果。

## 5. 事件顺序

### 5.1 基础事件集合

| 事件 | 必要字段 | 用途 |
|---|---|---|
| `BattleStarted` | battle_id, round_number | 初始化表现 |
| `RoundStarted` | round_number | 刷新回合 UI |
| `IntentGenerated` | enemy_id, intent_id, visible_values | 更新敌人意图 |
| `CardPlayed` | card_instance_id, definition_id, target_id | 表现出牌 |
| `SpiritChanged` | before, after, reason_code | 灵性变化 |
| `DamageApplied` | source_id, target_id, amount, hp_before, hp_after | 伤害表现 |
| `BlockChanged` | target_id, before, after | 护盾表现 |
| `Healed` | target_id, amount, hp_before, hp_after | 治疗表现 |
| `StatusChanged` | target_id, status_id, stacks, duration | 状态表现 |
| `CardDrawn` | card_instance_id, definition_id | 抽牌表现 |
| `CardDiscarded` | card_instance_id, reason_code | 弃牌表现 |
| `DeckReshuffled` | discard_count | 洗牌表现 |
| `IntentRevealed` | enemy_id, revealed_fields | 占卜表现 |
| `EnemyActed` | enemy_id, intent_id | 敌人行动 |
| `EnemyDefeated` | enemy_id | 移除敌人 |
| `RiskChanged` | risk_id, before, after, reason_code | 污染/被注视度表现 |
| `BattleEnded` | outcome, reason_code | 战斗结束 |

### 5.2 出牌事件顺序

合法出牌按以下顺序：

1. 校验阶段、卡牌、目标和资源。
2. 锁定目标集合。
3. 扣除灵性，产生 `SpiritChanged`。
4. 产生 `CardPlayed`。
5. 按卡牌效果数组顺序逐项结算。
6. 每次数值或状态变化立即产生对应事件。
7. 卡牌从手牌移动到弃牌区，产生 `CardDiscarded`。
8. 检查胜负；若结束则最后产生 `BattleEnded`。
9. 返回新快照和事件批次。

如果某效果要求的目标在之前的同卡效果中已经死亡，该效果跳过并记录 `effect_target_missing`，不得自动改打其他目标。

### 5.3 结束回合事件顺序

1. `PlayerTurnEnded` 语义由 `RoundStarted`/阶段快照体现，不额外创建空事件。
2. 玩家回合末状态计时。
3. 敌人按列索引从小到大的顺序行动。
4. 每个敌人行动内部按意图步骤数组顺序结算。
5. 检查玩家是否死亡。
6. 清理到期状态和护盾。
7. 检查敌人是否全部死亡。
8. 若继续，生成下一回合意图，抽牌至基准手牌数，产生 `RoundStarted`。
9. 若结束，产生 `BattleEnded`。

### 5.4 UI 动画解耦

- 领域命令同步完成，动画只消费事件。
- UI 在播放事件批次时可以显示忙碌状态，但不允许自行改变资源、目标攻击次数或伤害结果。
- 若动画中断，重新渲染最新快照即可恢复正确状态。
- 同一命令的事件不能拆成多个独立结算命令。

## 6. 最小只读快照

`BattleSnapshot` 是 UI 唯一允许读取的战斗显示数据，建议字段如下：

```text
revision
battle_id
phase
round_number
max_rounds

player:
  actor_id
  hp
  max_hp
  block
  spirit
  max_spirit
  corruption
  attention
  statuses[]

hand[]:
  instance_id
  definition_id
  category
  cost_spirit
  target_type

draw_pile_count
discard_pile_count

enemies[]:
  actor_id
  definition_id
  lane_index
  hp
  max_hp
  block
  statuses[]
  intent:
    intent_id
    revealed
    visible_fields

outcome
outcome_reason
```

约束：

- 快照不包含可变领域对象引用。
- 快照不包含文件路径、资源绝对路径或 UI 控件。
- 显示名称、说明文本和卡图 ID 由内容目录提供，UI 通过应用层拿到只读展示映射；玩法层不拼中文文案。
- `revision` 用于 UI 丢弃过期响应，不用于玩法幂等。
- 敌人意图默认只公开类别；`revealed` 与 `visible_fields` 决定 UI 能显示多少。

## 7. 领域端口

### 7.1 ContentPort

玩法层只接受已验证的内容对象，不读取 JSON 或文件：

```text
get_card_definition(definition_id)
get_identity_definition(identity_id)
get_enemy_definition(enemy_id)
get_encounter_definition(encounter_id)
get_reward_table(table_id)
get_gacha_pool(pool_id)
get_ritual_definition(trial_id)
```

所有查询必须返回明确成功或结构化错误。资源路径与本地化字段由表现/内容映射处理，不进入战斗结算。

### 7.2 BalancePort

```text
get_battle_balance(version_id)
get_progression_balance(version_id)
get_reward_balance(version_id)
get_gacha_balance(pool_id)
```

数值只通过参数 ID 被规则读取：

- `player.base_max_hp`
- `player.base_max_spirit`
- `player.starting_hand`
- `player.turn_draw_to_hand_size`
- `player.max_hand_size`
- `battle.max_rounds`
- `risk.corruption_thresholds`
- `risk.attention_thresholds`
- `progression.sequence_9_to_8_requirements`
- 各卡牌、敌人和奖励参数

禁在 BattleEngine 中写具体伤害、费用、概率或阈值常量。

### 7.3 RandomPort

```text
get_stream(stream_name) -> RandomStream
RandomStream.next_int(max_exclusive)
RandomStream.shuffle_in_place(array)
```

更简单的等价接口也可，但必须满足：

- 同一根种子、同一流名称和同一命令顺序产生同一结果。
- UI 刷新、重绘和动画不消耗随机数。
- 抽卡与战斗使用不同命名流。
- 日志可记录当前流游标，支持问题复现。

### 7.4 SavePort 与 ClockPort

BattleEngine 不直接调用 SavePort。保存由应用层在检查点执行：

- 每日开始。
- 战斗结算并领取结果后。
- 抽卡、升级或晋升提交后。

v0.3 不支持战斗中途恢复；如果应用异常退出，回到最近检查点。该限制必须由 UI 明确说明，不能让玩家误以为战斗进度已保存。

## 8. 卡牌效果最小封闭集合

首版效果不通过任意脚本路径组合，而由注册的 `effect_id` 表达。

| effect_id | 语义 | 主要目标 | 必需参数 |
|---|---|---|---|
| `damage` | 造成一次伤害 | enemy | amount |
| `block` | 增加护盾 | self | amount |
| `heal` | 恢复生命，不超过上限 | self | amount |
| `draw` | 抽牌，超过手牌上限则弃置并记录 | none | count |
| `spirit` | 当前回合增加灵性 | self | amount |
| `apply_status` | 添加/叠加状态 | self/enemy | status_id, stacks, duration |
| `remove_status` | 移除状态层数或全部层数 | self/enemy | status_id, stacks |
| `discard` | 弃置手牌 | none | count, selection_rule |
| `reveal_intent` | 揭示敌人意图字段 | enemy | fields[] |
| `risk` | 修改污染或被注视度 | self/run | risk_id, amount |

首版状态只保留两个：

- `mark`：下一次对目标造成伤害时消耗全部层数，每层增加固定伤害；有最大层数和到期时间。
- `weaken`：敌人下一次攻击伤害降低固定值；不叠加层数，只刷新持续回合；不能使伤害低于 0。

状态由数值提供上限与具体增量。任何新状态必须同时定义：目标、叠加规则、触发时机、持续时间、到期顺序、日志字段和 UI 显示。

### 8.1 20 张卡的功能分布

这里的 20 张是可收集卡定义，不代表 v0.3 首场战斗全部进入牌组。

| 稳定 ID | 类别 | 功能重点 | 获取方式 |
|---|---|---|---|
| `card.identity.reporter` | 人格 | 降低被注视度；强化“获取信息”方向 | 默认解锁 |
| `card.identity.doctor` | 人格 | 处理污染与生命状态 | 抽卡/明确保底 |
| `card.identity.gravedigger` | 人格 | 从失败和死亡中回收资源 | 抽卡/明确保底 |
| `card.skill.ink_dart` | 灵界回响 | 基础单体伤害 | 初始牌 |
| `card.skill.paper_guard` | 灵界回响 | 基础护盾 | 初始牌 |
| `card.skill.calm_breath` | 灵界回响 | 少量治疗、降低污染 | 初始牌 |
| `card.skill.focus` | 灵界回响 | 获得当前回合灵性 | 初始牌 |
| `card.skill.insight` | 灵界回响 | 抽牌 | 初始牌 |
| `card.skill.omen` | 灵界回响 | 施加 `mark` | 战斗奖励 |
| `card.skill.whisper` | 灵界回响 | 施加 `weaken` | 战斗奖励 |
| `card.skill.second_look` | 灵界回响 | 揭示敌人意图 | 战斗奖励 |
| `card.skill.cold_reading` | 灵界回响 | 标记并抽牌 | 精英奖励 |
| `card.skill.rain_step` | 灵界回响 | 护盾并调整位置威胁 | 战斗奖励 |
| `card.skill.forbidden_name` | 灵界回响 | 高伤害并增加污染 | 抽卡/风险牌 |
| `card.skill.night_watch` | 灵界回响 | 护盾与少量治疗 | 战斗奖励 |
| `card.artifact.watchers_eye` | 封印物 | 揭示意图，使用后增加被注视度 | 首领确定性掉落 |
| `card.artifact.faceless_testament` | 封印物 | 重置一个负面状态，但增加身份风险 | 抽卡 |
| `card.artifact.rain_ledger` | 封印物 | 将弃牌转化为资源 | 精英奖励/抽卡 |
| `card.artifact.black_candle` | 封印物 | 强化伤害，持续增加污染 | 抽卡 |
| `card.artifact.broken_compass` | 封印物 | 调整下一次敌人意图顺序或目标 | 抽卡 |

设计边界：

- 初始人格和基础战斗牌确定性获得，抽卡不影响能否完成第一场战斗。
- 关键晋升所需能力和至少一件封印物走首领确定性掉落或固定奖励。
- 封印物必须通过“增益 + 代价”的 effect 参数组合表达，不能为每件物品写特例 UI。
- 卡牌费用和实际强度由 `data/balance/**` 提供。

## 9. 抽卡、升级与序列晋升

### 9.1 抽卡

- 抽卡消耗游戏内获得的占卜资源，不涉及真实货币。
- 池内包含人格牌、灵界回响和封印物，三类均带稳定 ID。
- 首次进入安全屋时确定性获得首个可用人格；后续人格只决定新探索的开局选择。
- 人格牌不进入战斗手牌，也不能在探索中途切换。
- 关键战斗牌和晋升素材有确定性获取路径；抽卡主要提供构筑变化、替代方案和收藏目标。
- 概率、保底、重复转碎片和单抽/连抽规则由数值设计给出；玩法层只定义“按池规则执行一次抽取”和结果事件。
- 抽卡状态保存于 profile/collection，不保存于 BattleState。

### 9.2 卡牌升级

- 升级只改变已获得卡的等级或启用数值层，不复制卡牌定义。
- 卡牌实例引用 `definition_id + level`，不把不同等级写成多个不同主键。
- 升级消耗和允许的等级范围由数值提供。
- v0.2 不决定是否允许战斗中临时升级；v0.3 默认只在安全屋升级。

### 9.3 序列晋升

首版只做占卜家从序列 9 到序列 8：

- 消耗由数值定义的非凡特性碎片。
- 完成由玩法定义的扮演条件。
- 污染不得高于晋升上限。
- 通过一次短仪式试炼。
- 成功后解锁一个固定能力或卡牌，并更新序列 ID；失败增加污染或消耗部分准备资源，可以再次尝试。

### 9.4 “被篡改的讣告”试炼

目标：30—90 秒内做出三次选择，验证玩家理解，而不是考外部知识。

流程：

1. 展示三份讣告残页，只能选择一份与当前人格和线索一致。
2. 从三枚占卜符号中选择与所选残页相符的一枚。
3. 选择一种代价：增加污染、增加被注视度或放弃一项额外奖励。

规则：

- 所有判断信息来自本次游玩中已经展示的线索，不要求玩家背原著。
- 错误选择不会永久卡关，增加污染或被注视度后允许下一次再试。
- 可消耗灵性或占卜资源获得一次提示。
- 试炼失败与战斗失败读取同一风险阈值，但错误路径由独立事件记录。

## 10. 风险状态

### 10.1 污染

- 污染是 0 到上限的整数。
- 跨阈值时触发事件和表现，不自动结束游戏。
- 达到最大值时进入一次可控的“失控事件”：
  - v0.3 只实现战斗内失败或跳出战斗风险，不实现复杂幻觉地图。
  - 具体阈值与失控行为由数值设计提供。

### 10.2 被注视度

- 被注视度记录世界对玩家的关注程度。
- 日间行动、使用部分封印物和晋升失败会改变它。
- 达到阈值后，提高下一场遭遇难度或触发追猎事件。
- v0.3 不实现完整追猎地图，只允许影响下一场战斗的敌人配置或初始状态。

污染和被注视度是有规则意义的长期状态，不是纯 UI 数值。

## 11. 规则测试清单

以下测试必须在接口冻结后由玩法与本地数据层共同实现，本阶段只定义。

### 11.1 命令与阶段

- 在 `PLAYER_ACTION` 合法出牌成功，资源只扣一次。
- 重复打出同一 `card_instance_id` 被拒绝且状态不变。
- `EndTurn` 成功后重复提交被拒绝。
- 非行动阶段不能出牌或结束回合。
- `accepted=false` 的命令不产生事件、不消耗随机数、不写检查点。

### 11.2 卡牌与效果

- 一张卡多个效果严格按数组顺序完成。
- 目标在效果中途死亡时，后续目标效果被跳过并记录原因。
- 费用不足时不结算任何效果。
- 护盾吸收伤害的顺序和溢出伤害正确。
- 治疗不超过最大生命。
- `mark` 被下一次伤害消耗，增伤只应用一次。
- `weaken` 刷新持续回合但不叠层，伤害不低于 0。
- 手牌超出上限时，抽到的手牌按明确规则弃置并产生事件。
- 牌堆为空时，弃牌区按固定种子重新洗入牌堆。

### 11.3 回合与胜负

- 玩家和敌人状态在正确回合节点清理。
- 敌人按列索引顺序行动。
- 玩家死亡优先于敌方全灭时判负。
- 所有敌人死亡时判胜。
- 到达最大回合仍存活时判负并记录 `round_limit`。
- 战斗结束后不再接受任何战斗命令。

### 11.4 随机与回放

- 同一种子、同一命令序列产生完全相同快照和事件序列。
- UI 重新渲染或查询合法目标不改变随机流。
- 抽卡和战斗使用不同流，战斗洗牌不会改变抽卡结果。
- 敌人意图在回合内固定，不因刷新变化。

### 11.5 数据与边界

- 未注册效果 ID 产生结构化错误而非静默忽略。
- 目标类型和效果目标不匹配时产生数据校验错误。
- 稳定 ID 重复时内容加载失败。
- 数值参数缺失时不使用硬编码默认值。
- 存档检查点中的序列、收藏、抽卡资源和探索状态能恢复并继续。

## 12. 修改文件

- `docs/reports/v0.2.0/gameplay_designer.md`

没有修改 `src/`、`data/`、`scenes/`、`project.godot`、`art/`、共享契约或其他角色文件。

## 13. 困难与方案

| 困难 | 候选方案 | 最终选择 | 理由 | 风险 |
|---|---|---|---|---|
| 自动战斗原型更省 UI，但产品吸引力不足 | 六格自动牌阵；逐张出牌；逐张出牌 + 轻量三列 | 逐张出牌 + 三列位置 | 保留策略与卡牌反馈，不引入召唤物和自动寻敌 | 目标选择与合法性 UI 需要更严谨 |
| 人格既是日间身份又是战斗卡，容易产生切换边界 | 战斗中切换；只在开局选择；完全不做人格牌 | 只在开局选择，人格决定日间动作和起始构筑 | 避免中局状态级联，又保留抽人格钩子 | 抽到新人格的上场频率较低 |
| 六格持续牌阵表现力强，但实现成本高 | 六格持续召唤；三列即时目标；单敌人无阵型 | 三列即时目标 | v0.3 先验证卡牌决策，再决定是否加入持续单位 | 未来若加持续单位需要扩充接口 |
| UI 容易根据动画进度判断回合结束 | 领域同步完成；动画事件驱动；UI 等动画回调结束 | 领域同步完成，UI 消费事件批次 | 动画中断不影响正确性 | UI 需明确忙碌状态 |
| 中途续战需要保存复杂战斗状态 | 全程自动保存；检查点保存；不支持继续战斗 | 检查点保存，战斗退出回最近检查点 | 首版降低存档和迁移风险 | 玩家可能误以为战斗中已保存，需要 UI 明示 |

## 14. 跨角色请求

```text
[REQUEST]
从：玩法设计
给：UI 设计
版本：v0.2.0
内容：战斗页面需要显示三列敌人、手牌、生命/护盾/灵性、污染/被注视、牌堆与弃牌数量、敌人意图可见字段，以及可打出/资源不足/目标非法/错误阶段四类原因。
原因：首版采用逐张出牌，UI 必须在不自行计算规则的前提下发送 PlayCardCommand 或 EndTurnCommand。
期望接口：BattleSnapshot、QueryCardPlay、BattleCommandResult.events。
截止检查点：UI 线框提交前读取本报告，不自行定义胜负或扣费。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：数值设计
版本：v0.2.0
内容：请围绕 3 场普通战斗 + 1 场精英/首领、10—20 分钟一局，为首版占卜家提供：玩家基础生命/灵性/手牌参数、污染与被注视阈值、20 张卡的费用带、2 条可理解构筑方向、敌人伤害区间、奖励经济、抽卡概率与保底、序列 9 -> 8 条件。
原因：玩法只冻结参数 ID 和语义，不写具体平衡值。
期望接口：BalancePort 按参数 ID 返回，不把值散落到脚本或 UI。
截止检查点：PM 接口裁决前提交数值草案；不得用数值掩盖状态机缺失。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层开发
版本：v0.2.0
内容：优先实现内容/数值只读端口、命名随机流、固定种子回放和每日/战后检查点保存；v0.3 不要求战斗中途恢复。内容或效果缺失必须返回结构化错误，不能静默默认。
原因：BattleEngine 不得直接读文件、使用真实随机数或写存档。
期望接口：ContentPort、BalancePort、RandomPort；SavePort 只由应用检查点调用。
截止检查点：PM 冻结接口后再搭最小骨架，必须有固定种子重复性测试。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：产品经理
版本：v0.2.0
内容：请裁决并形成 ADR：逐张出牌 + 三列轻量牌阵、单占卜家途径、抽卡含人格/回响/封印物但关键内容确定性获取、首次晋升主题“被篡改的讣告”、v0.3 只做检查点保存。
原因：这五项决定会影响 UI 页面、数值参数、RNG 流和存档边界，必须在任何生产代码前冻结。
期望接口：更新 `docs/CURRENT_VERSION.md` 和对应 ADR/版本文档。
截止检查点：各角色提交草案后、创建 `src/core` 前。
[END REQUEST]
```

## 15. 验证

- 已逐项阅读 v0.2.0 要求的玩法交付内容。
- 已覆盖操作方式唯一推荐、状态机、命令/查询、事件顺序、快照、端口、效果封闭集合、20 张卡分布、领域闭环、晋升试炼和测试清单。
- 未运行代码测试，因为本阶段按版本要求只提交设计报告，没有创建生产代码或数据。

## 16. 风险与未决问题

- 逐张出牌比自动战斗多出目标选择与事件动画工作量，UI 必须在 v0.3 前确认可交付。
- 抽卡包含人格牌会增加收藏与开局选择 UI，但人格在探索中锁定，避免中局切换带来的状态污染。
- `v0.3` 是否需要三列而不是单敌人尚未被 UI 原型验证；如果无法在首场切片中有效利用列位置，产品经理应削减为单列，不能为“像牌阵”增加空机制。
- 战斗中异常退出回到最近检查点是明确的体验限制，需要 UI 在进入战斗时提示。
- 本报告中的接口是草案，未经 PM 冻结前不得作为共享 `src/core` 实现依据。
- 卡牌升级的重复卡转化与等级上限属于数值和收藏边界，需在数值报告中给出一致方案。

## 17. v0.2.0 实现检查点

ADR-0002 已确认 `src/core/**` 为玩法设计在 v0.2.0 期间的唯一负责人，ADR-0003 已冻结逐张出牌、占卜家、抽卡池、晋升失败语义、节点结构、检查点保存与 `corruption/attention` 字段。本角色据此完成最小玩法实现。

### 17.1 已实现文件

- `src/core/battle_command.gd`
- `src/core/battle_event.gd`
- `src/core/battle_snapshot.gd`
- `src/core/battle_playability.gd`
- `src/core/battle_command_result.gd`
- `src/core/battle_content_port.gd`
- `src/core/battle_balance_port.gd`
- `src/core/battle_random_port.gd`
- `src/gameplay/battle_engine.gd`
- `tests/gameplay/test_runner.gd`
- `tests/gameplay/test_runner.tscn`

没有修改 UI、基础设施、存档 schema、`project.godot`、`art/`、数值表或其他角色报告；没有创建 `data/cards` 数据，因为共享 schema 由本地数据层负责，测试使用明确隔离的内容夹具。

### 17.2 实现范围

- 逐张出牌、灵性支付、三列目标与列顺序敌人行动。
- 独立命令、事件、只读快照和一键命令结果。
- 非法阶段、卡牌不在手牌、资源不足、非法目标的结构化拒绝。
- 伤害、护盾、治疗、抽牌、灵性、状态、弃牌、意图揭示和风险效果。
- `mark` 被下一次伤害消耗；`weaken` 降低下一次敌人攻击并在到期后移除。
- 洗牌采用注入的随机端口；同一随机流和命令序列可复现。
- 从第 7 回合起，每次完整敌方回合后提升存活敌人的压力攻击。
- 玩家死亡、敌方全灭、回合上限三种结束路径。
- 初始化时校验缺失端口、缺失数值参数、非法卡牌定义、重复敌人列和非法初始状态。

### 17.3 验证

测试场景：

```text
res://tests/gameplay/test_runner.tscn
```

Godot 4.7.2 headless 结果：

```text
GAMEPLAY_TESTS_OK checks=52
EXIT_CODE=0
```

覆盖：合法出牌与重复拒绝、资源不足、非法目标、护盾吸收、标记消耗、削弱、胜利、失败、回合上限、敌方压力、同种子回放和非法效果定义。

### 17.4 实现阶段困难与解决

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 共享契约尚未冻结 | 先写内部类型，稍后迁移；等待 ADR | 等待 ADR-0002/0003 后创建 core | 避免两套公共类型和迁移级联 |
| 脚本型测试入口未执行断言 | 继续修 MainLoop 生命周期；改用 Godot 测试场景 | 使用 `Node` + `.tscn` 入口 | 生命周期明确，可捕获输出和退出码 |
| 敌人削减状态可能被重复计时 | 每次敌人行动后计时；回合末统一计时 | 回合末统一计时一次 | 避免 weaken 提前消失和重复扣时 |
| 无共享内容 schema 时容易写生产数据 | 自建 schema；先在测试夹具中表达 | 只用测试夹具，不创建 `data/cards` | 保持 schema 单一负责人 |

### 17.5 当前集成请求

```text
[REQUEST]
从：玩法设计
给：本地数据层开发
版本：v0.2.0
内容：请让内容加载器、数值表和 SeededRandomStream 通过适配器实现 BattleContentPort、BattleBalancePort、BattleRandomPort，或在不复制定义的前提下继承这些 core 端口。当前 SeededRandomStream.next_int 签名兼容，但类型上尚不能直接传给 BattleEngine。
原因：玩法层不能直接依赖 infrastructure 具体类，也不能复制第二套端口。
期望接口：app/bootstrap 将命名随机流适配为 BattleRandomPort；内容/数值适配失败返回结构化错误。
截止检查点：v0.2.0 集成验证前
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：UI 设计
版本：v0.2.0
内容：UI 后续只能读取 BattleSnapshot，通过 BattleCommand 提交操作；本地选择不计入命令幂等。`corruption` 是唯一污染字段，不再保留 `pollution`。
原因：避免 UI 重算规则和存档出现同义字段。
期望接口：见 src/core 中只读快照与 Playability。
截止检查点：v0.3.0 UI 接线前
[END REQUEST]
```

### 17.6 剩余风险

- 当前 BattleEngine 使用内部 Dictionary 状态，公开访问入口是快照；后续若出现测试之外的可变状态访问，必须停止扩展并改为命令/查询。
- 测试使用隔离夹具，尚未经过真实 JSON schema、BalancePort 和 UI 集成。
- 效果集合只覆盖 v0.2 最小封闭集；新增效果必须同时扩展校验、事件、快照和回归测试。
- 实时战斗手感尚未验证；数值仍需在 v0.3.0 真实逐张出牌后重新采样。
