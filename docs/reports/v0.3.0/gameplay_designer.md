# v0.3.0 / 玩法设计工作记录

## 状态

- 状态：完成
- 当前任务：按 ADR-0004 实现敌方压力时点，建立 8 张正式占卜家卡、3 个敌人与首场遭遇，并补齐规则回归。
- 最后更新：2026-11-08
- 下一步入口：主协调者与 UI、本地数据层完成真实启动链路；数值设计确认正式卡金额并把 Balance 中的压力起点改为 5。

## 本版本目标

在保持冻结命令接口的前提下，把 BattleEngine 的压力规则修正到第 5/7/9 回合开始生效，提供可被内容层加载的 8 张占卜家卡，并让规则测试覆盖正式卡实际使用的每个 effect。

## 依赖

- 必需文档：`AGENTS.md`、`docs/CURRENT_VERSION.md`、`docs/PROJECT_CHARTER.md`、`docs/ARCHITECTURE_CONTRACT.md`、`docs/versions/v0.3.0.md`、`docs/decisions/ADR-0004-enemy-pressure-timing.md`。
- 依赖角色：
  - 本地数据层：三类正式 schema 与内容装配器已提供；仍需完成默认内容到 UI 的端到端集成验证。
  - 数值设计：用真实 BattleEngine 采样 8 张正式卡和正式首战；确认压力参数起点和第 5/7/9 回合意图。
  - UI 设计：从快照读取 `enemy_pressure_bonus`，显示正式卡展示字段，不在 UI 计算压力。
- 期望接口：沿用冻结的 `PlayCardCommand`、`EndTurnCommand`、`QueryCardPlay`、`BattleCommandResult`、`BattleSnapshot`、`BattleContentPort`、`BattleBalancePort`、`BattleRandomPort`，没有新增公共接口。

## 已完成

### 敌方压力

- 压力改为回合开始阶段、生成敌人意图之前应用。
- 由数值参数 `battle.enemy_pressure_start_round` 得到首个触发回合，再按固定规则在第 5、7、9 回合触发三次。
- 第 5、7、9 回合当前意图直接包含压力加成。
- 第 4 回合无压力，第 10 回合保留第 9 回合累计的 3 点压力，不再继续增加。
- 战斗对象初始化时压力为 0，同场叠加，跨战斗不继承。
- `EnemyPressureChanged` 事件包含 `round_number`、当前加成和存活敌人数。
- `BattleSnapshot.enemy_pressure_bonus` 暴露存活敌人的最高当前压力值。

### 正式首版卡牌

新增 `data/cards/v0.3.0/cards.json`，共 8 张，全部使用既有 20 卡稳定 ID：

| 稳定 ID | 核心效果 | 费用 |
|---|---|---:|
| `card.skill.ink_dart` | 单体伤害 | 1 |
| `card.skill.paper_guard` | 护盾 | 1 |
| `card.skill.calm_breath` | 治疗并降低污染 | 1 |
| `card.skill.focus` | 增加当前回合灵性 | 0 |
| `card.skill.insight` | 抽牌 | 0 |
| `card.skill.omen` | 施加上层标记 | 1 |
| `card.skill.whisper` | 削弱下一次敌方攻击 | 1 |
| `card.skill.second_look` | 揭示敌人意图 | 0 |

这些卡覆盖正式内容实际使用的 8 类 effect：`damage`、`block`、`heal`、`spirit`、`draw`、`apply_status`、`reveal_intent`、`risk`。

本地数据层随后提供了 `data/schema/v0.3.0/cards.schema.json`、`enemies.schema.json`、`encounters.schema.json`。玩法已将正式卡文件路径统一为应用装配器使用的 `res://data/cards/v0.3.0/cards.json`，没有保留旧文件名副本。

### 正式首场遭遇

新增：

- `data/enemies/v0.3.0/enemies.json`：3 个稳定敌人定义。
- `data/encounters/v0.3.0/encounters.json`：`encounter.first_hunt`“雨夜双影”。

首场遭遇：

- 客厅列是 `enemy.weeping_tenant`，12 生命、4 攻击。
- 右列是 `enemy.candle_moth`，8 生命、2 攻击。
- 另有 `enemy.mirror_hound` 作为后续内容预留定义，不进入当前遭遇。
- 牌组包含 12 个卡牌实例，引用 8 个正式稳定卡牌 ID，允许重复实例，不以显示名作为主键。

内容和所有引用由玩法测试检查：卡牌 ID 必须存在、敌人 ID 必须存在、敌人列不能重复、遭遇必须实际包含两个敌人。

### JSON 数值校验修复

正式内容通过 JSON 读取后，整数可能以浮点数形式进入 Dictionary。旧校验只接受 GDScript `int`，会把合法正式卡判为 `card_definition_invalid`。

根因是内容表示与运行时校验不匹配，不是某张卡的特例。修复位于通用 effect 校验：

- 接受真正整数。
- 接受有限且等于整数的浮点数。
- 仍然拒绝小数、NaN、无穷和非法负数/零。
- 结算处继续统一转为整数，不建立针对正式卡 ID 的条件分支。

## 困难与方案

| 困难 | 候选方案 | 最终选择 | 理由 | 风险 |
|---|---|---|---|---|
| 原压力在第 7 回合后每轮叠加，不符合 ADR-0004 | 保留旧逻辑增加特例；重构到回合开始；只在测试中模拟新规则 | 前向重构到回合开始、意图生成之前 | 根因是触发阶段错误，测试不能代替生产规则 | 数值和 UI 必须读取新快照/事件 |
| 正式 JSON 整数被解析为浮点数，卡片初始化失败 | 修改正式数据写特殊形式；放宽通用整数校验；在内容适配器逐卡转换 | 放宽通用整数校验 | JSON 表示属于系统边界问题，按通用规则修复 | 若接受不严格可能有浮点误差，已限制为有限整数值 |
| 压力测试夹具仍使用旧第 7 回合参数 | 改默认值；改测试夹具；在生产代码兼容旧值 | 测试显式使用第 5 回合参数 | 规则数据与测试输入应明确，不把旧默认留在生产引擎 | 正式 Balance 数据必须同步为 5 |
| 敌人与遭遇 schema 先于正式内容出现，所有权曾不明确 | 玩法自建；本地数据层创建；等待 PM 裁决 | PM 更新 AGENTS.md 后由玩法创建正式内容 | 单一所有权和 schema 已明确，无需临时重复文件 | 数值与主链集成仍待其他角色完成 |

## 验证

玩法测试命令：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/gameplay/test_runner.tscn
```

结果：

```text
GAMEPLAY_TESTS_OK checks=131
```

覆盖：

- 正式卡文件存在 8 个唯一稳定 ID。
- 正式 effect 集合完整。
- 正式 ink dart、paper guard、calm breath、focus、insight、omen、whisper、second look 的实际数据。
- 正式敌人文件存在 3 个唯一稳定 ID。
- 首场遭遇包含两个不同列的敌人，且所有卡牌和敌人引用有效。
- 正式首战内容可由 BattleEngine 初始化到 `player_action`，快照包含两个敌人。
- 第 4 回合无压力，第 5/7/9 回合分别增加 1，意图当回合包含加成，共触发三次。
- 原有非法操作、重复操作、胜负、回合上限、状态和固定种子回放测试继续通过。

基础设施回归：

```text
PASS infrastructure tests: 93
```

当前未运行 UI 启动、战后保存和数值采样；这些依赖主协调者集成、正式 Balance 参数及数值角色工作。

## 修改文件

- `src/gameplay/battle_engine.gd`
- `tests/gameplay/test_runner.gd`
- `data/cards/v0.3.0/cards.json`
- `data/enemies/v0.3.0/enemies.json`
- `data/encounters/v0.3.0/encounters.json`
- `docs/reports/v0.3.0/gameplay_designer.md`

没有修改 `src/core/**`，因为冻结接口和快照字段已满足本阶段需求。

## 跨角色请求

```text
[REQUEST]
从：玩法设计
给：本地数据层 / 主协调者
版本：v0.3.0
内容：正式 `data/cards`、`data/enemies`、`data/encounters` 已按默认路径交付。请在 Balance 起点修正后运行 AppBootstrap.start_new_game，验证 CampaignContentCatalog、BattleEngine、事件快照、战后保存与继续读取。
原因：玩法单元测试已覆盖内容引用和引擎初始化，但端到端链路属于主协调者和本地数据层所有权。
期望接口：使用现有默认路径与冻结接口，不复制内容或规则到 app/UI。
截止检查点：v0.3.0 集成验收前。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：数值设计
版本：v0.3.0
内容：请确认 data/balance 的 enemy_pressure.start_round 为 5，并用真实 BattleEngine 对 8 张正式卡的至少三种固定牌序采样；当前卡牌效果金额来自玩法首战草案，需要数值角色确认或提出同目录调整建议。
原因：ADR-0004 已改为第 5/7/9 回合，旧 balance_draft 仍写第 7 回合；正式卡金额与平衡预算必须只有一个批准来源。
期望接口：BalancePort 现有参数即可，不新增规则分支。
截止检查点：v0.3.0 产品验收前。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：UI 设计
版本：v0.3.0
内容：压力显示只读取 snapshot.enemy_pressure_bonus；意图显示读取每列 intent.revealed 与 visible_fields.damage。正式卡名称从 definition_id 映射，不在 UI 判断效果金额。
原因：第 5/7/9 回合压力在回合开始时已计入意图，UI 再次计算会造成双加。
期望接口：现有 BattleSnapshot，无需修改 core。
截止检查点：UI 战斗页接入真实快照前。
[END REQUEST]
```

## 风险与未决问题

- 正式首战内容已就绪；UI 启动、存档与继续读取仍需主协调者完成端到端验证。
- 正式卡效果金额目前是玩法首战草案，必须由数值角色确认；没有在脚本中硬编码这些值。
- 压力触发次数和间隔从已冻结规则常量推导，起点读取 BalancePort；数值数据仍须把起点更新为 5。
- UI 当前可能仍包含旧 `pollution` 术语，属于 UI 所有权，不由玩法越权修改。
- 主协调者进行集成时，应直接通过 `BattleEngine.initialize` 和正式内容端口装配，不复制敌人/卡牌配置到场景脚本。
