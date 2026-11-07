# v0.4.0 / 数值设计工作记录

## 状态

- 版本：`v0.4.0`
- 角色：数值设计
- 任务：身份、战后奖励、祈愿、重复卡转化和首次升级的经济草案与真实战斗验证
- 状态：完成数值草案与独立验证；祈愿池契约已按玩法裁决完成前向修正
- 最后更新：2026-11-08
- 下一步入口：`docs/reports/v0.4.0/local_backend.md` 完成参数映射后，运行真实 `ProgressionEngine`

## 本版本目标

- 让玩家在首场胜利后的一个短循环内至少完成一次有意义的祈愿或卡牌升级。
- 抽卡保持三个身份和两条奖励路线之间有不同决策。
- 关键初始战斗卡由内容确定性提供，不依赖祈愿运气。
- 卡牌金额仍只存在于 `data/cards/**`，本角色只维护全局票券、概率、奖励金额和升级成本。
- 用真实 `BattleEngine` 验证升级后的卡牌在下一场战斗中有可见效果。

## 依赖

- `AGENTS.md`、`docs/CURRENT_VERSION.md`、`docs/PROJECT_CHARTER.md`
- `docs/ARCHITECTURE_CONTRACT.md`、`docs/versions/v0.4.0.md`
- ADR-0005、ADR-0006、ADR-0007
- 玩法正式内容：`data/cards/v0.3.0/cards.json`、`data/cards/v0.4.0/progression.json`
- 正式战斗内容：`data/enemies/v0.3.0/enemies.json`、`data/encounters/v0.3.0/encounters.json`
- 现有 `BattleEngine`、BalancePort、ContentPort、RandomPort 和正式端口适配器

## 数据边界

本版本 balance 草案只新增以下全局参数：

| 参数 | 当前值 |
|---|---:|
| 初始占卜券 | 3 |
| 单抽成本 | 2 券 |
| 三连成本 | 5 券 / 3 次抽取 |
| 普通概率 | 85% |
| 稀有概率 | 15% |
| 稀有保底 | 第 4 抽 |
| 重复卡碎片 | 6 |
| 升级到 1 级 | 6 碎片 |
| 升级到 2 级 | 12 碎片 |
| 升级到 3 级 | 24 碎片 |
| 占卜券奖励 | 3 券 |
| 墨刺残页奖励 | 6 碎片 |

身份显示名、身份修正、牌池稀有度和每张卡的升级字段来自 `data/cards/v0.4.0/progression.json`，不在 balance 中复制：

- 记者：初始注视 -1，胜利额外获得 1 券。
- 医生：战斗最大生命 +4。
- 守墓人：重复卡额外获得 2 碎片。

## 短循环参数

### 记者票券路线

```text
初始 3 券
-> 胜利身份奖励 +1 券
-> 领取 3 券
-> 三连消耗 5 券
-> 再单抽消耗 2 券
-> 共 4 抽
```

四次抽取至少会覆盖部分重复牌，重复碎片用于首次 6 碎片升级。固定种子模拟中 99.6% 的循环完成一次升级。

### 医生碎片路线

```text
初始 3 券暂存
-> 胜利领取 6 枚墨刺碎片
-> 直接完成墨刺 1 级升级
```

医生的战斗修正是最大生命 +4。该路线不消耗初始券，下一循环仍可使用。

### 守墓人祈愿路线

```text
初始 3 券
-> 胜利领取 3 券
-> 三连消耗 5 券
-> 共 3 抽
-> 每次重复卡获得 8 碎片
```

三抽至少形成一次重复结果；固定种子模拟中 98.5% 的循环完成首次升级，剩余情况仍需更多抽卡次数，但已经完成了有意义的祈愿决策。

## 固定种子模拟

命令：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/economy_sampling_runner.tscn
```

根种子 `20261108`，每策略 1000 个首战胜利循环：

| 路线 | 抽取 | 券剩余 | 重复卡 | 升级完成率 | 有效循环 |
|---|---:|---:|---:|---:|---:|
| 记者票券 | 4.0 | 0.0 | 2.94 | 99.6% | 100% |
| 医生碎片 | 0.0 | 3.0 | 0.0 | 100% | 100% |
| 守墓人票券 | 3.0 | 1.0 | 2.58 | 98.5% | 100% |

三类路线的`active_loop_rate`均为 100%：每条路线至少完成一次祈愿或升级。

输出：

- `tools/simulation/out/v0.4.0_economy_sampling.json`
- 固定种子输出 SHA-256：`33A3C8FE163559DB03F0CB658FFE3EACE5C89C7CAC58539036AF7E7CE9793841`

## 真实 BattleEngine 连战采样

命令：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/upgrade_battle_sampling_runner.tscn
```

采样对象：医生身份、正式 8 卡内容、正式双敌人首战，共 500 组前后战：

| 样本 | 胜率 | 平均回合 | 墨刺每次伤害 | 墨刺总伤害 |
|---|---:|---:|---:|---:|
| 升级前 | 100% | 3.234 | 4.0 | 10000 |
| 升到 1 级 | 100% | 3.234 | 5.0 | 12500 |

升级带来的每次伤害提升已经由真实 `BattleEngine` 事件验证。由于教学战原本就在 3—4 回合结束，平均回合和剩余生命未产生差异；这是教学战强度和高过量伤害的结果，不代表升级无效。

输出：

- `tools/simulation/out/v0.4.0_upgrade_battle_sampling.json`
- 固定种子输出 SHA-256：`841EC2C98A81DCD8D841D577CD4CAD26BD608DEE4470588660C1CAE83B6F94B8`

## 合同测试

命令：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/simulation/v04_economy_contract_runner.tscn
```

结果：

```text
V04_ECONOMY_TESTS_OK checks=54
```

覆盖：

- v0.4 balance 草案字段和单一数据源。
- 三个身份、六个初始卡、七个可升级祈愿池卡和两个奖励。
- 正式战斗池仍为 8 张；祈愿池与战斗池数量分离。
- 祈愿池中的全部稳定 ID 均存在于升级定义，且不能重复。
- 初始票券、抽卡成本、概率、保底、重复碎片和升级成本。
- 三类固定种子路线的有效循环、抽取次数和升级可达性。
- 真实 BattleEngine 前后战种子、胜负、墨刺基础伤害和升级伤害。

同时回归玩法：

```text
PROGRESSION_TESTS_OK checks=90
```

### 后续契约修正

玩法角色已将 `card.skill.second_look` 移出祈愿池，保留为确定性拥有的不可升级工具牌。当前正式祈愿池为 7 张可升级卡，独立验证断言已同步。`ProgressionEngine` 同时拒绝加载包含“有卡无升级定义”或重复卡 ID 的祈愿池。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 最初草案使用 `meta` 和自造身份修正 | 保留数值层副本；等待玩法接口；前向对齐玩法正式字段 | 身份定义使用 `data/cards/v0.4.0/progression.json`，balance 只保留全局参数 | 遵守单一事实源，避免 UI 和玩法读取两套身份 |
| 旧草案把升级从 1 级算起 | 把初始等级视为 1；修改玩法字段 | 玩法从 0 级开始，成本按下一次等级 1/2/3 定义 | 与 `ProgressionEngine` 的实际语义一致 |
| 抽卡池必须与正式稀有度一致 | 数值层复制稀有度表；按卡 ID 自行分类 | 读取 `progression.json.gacha_pool` | 避免重复定义卡池 |
| 抽卡路线是否一定获得升级 | 保底碎片；直接赠送卡牌；降低首升成本到 6 | 首次升级成本 6，重复卡给 6—8 碎片 | 保持抽卡有意义，同时避免玩家卡关 |
| 真实战斗升级后平均回合不变 | 人为削弱敌人；伪造升级差值；记录单次伤害 | 记录 `DamageApplied` 的单次伤害，接受教学战快速结束 | 升级规则真实生效，不能为了展示而篡改战斗 |

## 跨角色请求

```text
[REQUEST]
从：数值设计
给：本地数据层
版本：v0.4.0
内容：建立 balance schema v2，并在 BattleBalancePort 适配器中映射：
  progression.starting_divination_tickets -> progression.starting_divination_tickets
  gacha.single_cost -> gacha.single_cost
  gacha.triple_cost -> gacha.triple_cost
  gacha.rarity_weights -> gacha.rarity_weights
  gacha.rare_pity -> gacha.rare_pity
  gacha.duplicate_fragments -> gacha.duplicate_fragments
  upgrade.cost_by_next_level -> upgrade.cost_by_next_level
  reward.amounts -> reward.amounts
原因：ProgressionEngine 已依赖这些参数 ID，而现有 v0.3 BalanceAdapter 尚未映射 v0.4 字段。
期望接口：保持卡牌/敌人/遭遇内容目录不变，只扩展 schema 与适配器；balance 不复制 `data/cards` 的内容。
截止检查点：v0.4 app 接线前。
[END REQUEST]
```

```text
[REQUEST]
从：数值设计
给：玩法设计
版本：v0.4.0
内容：`card.skill.second_look` 出现在初始卡和抽卡池中，但 `upgrade_definitions` 没有该卡，因此重复抽到它时不能升级。请确认这是有意设计，还是补齐升级定义。
原因：记者和守墓人祈愿路线分别有 0.4% 和 1.5% 的样本只抽到不可升级的重复牌，导致首次循环只在祈愿上有资源动作。
期望接口：补充该卡的数据升级定义，或在报告中明确它是不可升级卡。
截止检查点：v0.4 玩法验收前。
[END REQUEST]
```

```text
[REQUEST]
从：数值设计
给：UI 设计
版本：v0.4.0
内容：所有抽卡显示数字必须来自 ProgressionSnapshot：票价、保底计数、稀有概率/权重、余额、重复碎片和升级成本。UI 不得在按钮中重复计算“是否够三连”或“下一次保底”。
原因：v0.4 经济已经能在固定种子下复现，UI 复制公式会产生第二事实源。
期望接口：直接展示 `gacha_costs`、`pity_counter`、`rare_pity`、`divination_tickets`、`collection[].fragments` 和 `next_upgrade_cost`。
截止检查点：v0.4 UI 接线前。
[END REQUEST]
```

```text
[REQUEST]
从：数值设计
给：产品经理
版本：v0.4.0
内容：当前参数已满足“单个循环至少一次可见资源动作”，并让记者/医生/守墓人形成票券、稳妥升级、重复碎片三种路线。建议保留教学战 100% 胜率，不在 v0.4 用战斗失败打断成长链；难度曲线留到有更多遭遇后再调。
原因：首场教学战承担链路验证，升级只有 4→5 的单次伤害变化，继续削弱敌人会掩盖成长反馈。
期望接口：在版本关闭时确认教学战定位和这些数值为 v0.4 验收参数。
截止检查点：v0.4 关闭前。
[END REQUEST]
```

## 验证

- 固定种子经济模拟：3 个策略 × 1000 局，全部有效。
- 固定种子战斗采样：500 组前后战，基线 500、升级 500，全部有效。
- 合同测试：`V04_ECONOMY_TESTS_OK checks=54`。
- 玩法回归：`PROGRESSION_TESTS_OK checks=90`。
- 墨刺升级后真实伤害：每次命中 4 → 5。
- balance 未复制 cards/enemies/encounters。
- 未修改 schema、核心规则、UI、基础设施或正式存档代码。

## 风险

- balance schema v2 尚未冻结；在数据层完成映射前，不能声称真实 app 已经读取 v0.4 参数。
- 已解决：`second_look` 不再进入祈愿池；正式祈愿池全部可升级。
- 记者票券路线在首循环内完成 4 抽和一次升级的 99.6%；目前偏慷慨，若后续出现资源滚雪球，应调整奖励或升级成本，而不是复制卡池数据。
- 医生路线保留 3 张初始券进入下一战；这是刻意留出的跨循环资源，后续需要观察实际累计速度。
- 战斗采样仍使用同一教学遭遇，不能代表多遭遇后的平衡。

## 修改文件

- `data/balance/v0.4.0/balance.json`
- `data/balance/v0.4.0/README.md`
- `tools/simulation/economy_sampling_runner.gd`
- `tools/simulation/economy_sampling_runner.tscn`
- `tools/simulation/upgrade_battle_sampling_runner.gd`
- `tools/simulation/upgrade_battle_sampling_runner.tscn`
- `tools/simulation/out/v0.4.0_economy_sampling.json`
- `tools/simulation/out/v0.4.0_upgrade_battle_sampling.json`
- `tests/simulation/v04_economy_contract_runner.gd`
- `tests/simulation/v04_economy_contract_runner.tscn`
- `tests/simulation/README.md`
- `docs/reports/v0.4.0/numerical_designer.md`

## 下一步入口

1. 本地数据层按请求冻结 balance schema v2 和参数映射。
2. app 接线后，用真实 `ProgressionEngine` 重放记者/医生/守墓人三条固定种子路线。
3. UI 完成抽卡和升级界面后，从快照读取成本、保底和碎片，不复制计算。
4. 首次完整短循环可运行后，重跑经济与战斗采样并更新最终哈希。
