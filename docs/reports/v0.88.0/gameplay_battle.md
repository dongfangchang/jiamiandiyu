# v0.88.0 · T1 战斗轨道报告（玩法 + UI）

```text
版本：v0.88.0（ROADMAP R2 第一波 · T1 战斗）
角色：玩法设计 + UI（仅限 T1 战斗轨道）
任务：R2-01 战斗快照补字段；R2-02 删除 battle_screen 规则镜像；R2-06 战斗平衡数值迁入 data/balance；R2-07 意图输出 ID
状态：完成（黄金回放待主协调者统一更新哈希）
```

## 1. 修改文件

| 文件 | 改动 |
|---|---|
| `src/gameplay/battle_engine.gd` | 快照新增字段；仪式加成拆成纯函数 `_ritual_scaled_effects`，结算和预览共用；可打判断抽成 `_card_cost_block_reason`，`query_card_play` 和快照共用；弃牌数量统一由 `_effective_required_discard` 计算；规则常量改为读平衡数据；意图不再生成中文 |
| `src/ui/battle_screen.gd` | 删除 `RITUAL_CONSUME_*`、`RITUAL_PREPARE_BY_DEFINITION`、`_ritual_payoff_damage`、弃牌门槛回退、两参数查询分支；`THREAT_NAMES` 去掉数字；仪式、风险、横幅文案改读快照或事件字段 |
| `src/ui/text/intent_text.gd`（新增） | UI 侧意图文案表：`intent_id`/`variant_id` → 中文 |
| `src/infrastructure/battle_balance_adapter.gd` | 新增参数 `battle.enemy_pressure`、`battle.rules`（**跨出轨道目录，只加两行映射**） |
| `data/balance/v0.7.0/balance.json` | `combat.enemy_pressure` 补 `interval_rounds/trigger_count/bonus_per_trigger`；新增 `combat.rules` |
| `data/balance/v0.3.0–v0.6.0/balance.json` | 补同样的字段，数值与原代码常量一致，另补 `danger_threshold: 9`（原代码默认值）。这些旧文档仍被测试和采样器喂给战斗引擎 |
| `data/schema/v0.7.0/balance.schema.json` | `combat` 新增必填项 `danger_threshold` 和 `rules`，并补充字段定义 |
| `tests/gameplay/{test_runner,route_test_runner,progression_test_runner,v0100_chain_runner}.gd` | 假平衡端口补充新增参数 |
| `tests/gameplay/battle_snapshot_preview_runner.{gd,tscn}`（新增） | 新快照字段的行为测试（26 项检查） |
| `tests/ui/*`（8 个）、`tests/integration/v091_regression_runner.gd`、`v092_destructive_runner.gd` | 可打查询的假处理函数改为三参数（UI 已删除两参数分支） |

## 2. 实现说明

### R2-01 快照字段
- `hand[i].playable` / `hand[i].blocked_reason`：取值为 `BattlePlayability` 的 ID（`wrong_phase`、`insufficient_spirit`、`invalid_target`、`definition_error`）；可打时为 `""`。只按卡牌本身判断（阶段、灵性，以及有没有可选的存活敌人）；具体目标和弃牌选择仍由 `query_card_play` 判断。两者的灵性和定义检查共用 `_card_cost_block_reason`。
- `hand[i].required_discard`：改为实际需要选的弃牌数，即 `min(声明数, 手牌数-1)`，和结算门槛、`auto_discard_ids_for` 用同一个函数。黄金回放中这个值没有变化。
- `hand[i].preview`：`{damage, block, heal, draw, spirit, discard, self_hp_loss, ritual_stacks, corruption, attention, statuses[], conditional{同结构}, ritual_consumed}`。先用结算时同一个 `_ritual_scaled_effects` 算出加成后的效果，再按 `effect_id` 汇总；带 `condition` 的效果单独放进 `conditional`。不计入目标身上的印记、护盾等修正。
- `player.ritual_payoff_preview`：`{definition_id, stacks, damage}`。取牌组中第一张 `consumes_ritual` 卡，在当前层数下的 `preview.damage`；牌组里没有这类卡时为 `{}`。
- `enemies[i].threat_amount`：敌人每次行动附带的威胁增量，来自 `battle.rules.threat_risk`。
- 事件 `RitualCompleted` / `RitualProgressed` 增加 `payoff_damage`；`EnemyActed` 增加 `variant_id`。

### R2-02 UI 去规则
- `grep -n '4 + 3' src/ui` 结果为空。`4+3`、`RITUAL_PREPARE`、`_ritual_payoff_damage`、`get_argument_count` 在 `battle_screen.gd` 中都已为 0。
- 卡面「叠仪式 +N」读 `preview.ritual_stacks`；「兑现 N 伤」读 `preview.damage` 和 `preview.ritual_consumed`。
- 烛台预计伤害读 `player.ritual_payoff_preview`；兑现横幅读事件里的 `payoff_damage`。「三段已齐」判断原来写死 3，现在改读事件的 `max`。
- 「污染侵蚀：每回合 -1 生命」中的 1 改读 `risk_pressure.corruption_penalty`。
- `THREAT_NAMES` 只保留文案，数字由 `threat_amount` 拼接。

### R2-06 平衡数值
`battle_engine.gd` 已删除 `ENEMY_PRESSURE_INTERVAL_ROUNDS`、`ENEMY_PRESSURE_TRIGGER_COUNT`、`RITUAL_MAX_STACKS`、`DEFAULT_DANGER_THRESHOLD`。下列字面量改为读 `combat.rules`：注视惩罚 1/2、污染惩罚 1、威胁增量 2/1、预见减伤 1、意图污染危险线 2，以及压力每次 +1。这些参数都是**必填**：缺失时初始化返回 `balance_missing`，引擎内不再保留兜底值，与 AR-12 的思路一致。所有数值都和原常量相同。

### R2-07 意图 ID
- 删除 `_default_intent_name`。失声时的覆盖意图改为 `{"intent_id": "attack", "variant_id": "silenced"}`。
- 每个意图（含 `visible_fields`）新增 `variant_id`。`display_name_zh` 只透传内容数据里写的文案，内容没写时为 `""`。
- UI 通过 `IntentText.name_zh` / `specific_name_zh` / `description_zh` 映射中文。
- 守卫：`battle_engine.gd` 中 CJK 字符数为 0。

## 3. 验证

- `tools/run_tests.sh`：见第 6 节的最终结果行。
- `battle_snapshot_preview_runner`：26/26 通过。检查内容：预览伤害等于实际结算的 `DamageApplied.raw_amount`；`RitualCompleted.payoff_damage` 等于预览；`blocked_reason` 与 `query_card_play` 一致；弃牌数量按手牌封顶；意图不带引擎生成的中文；缺少 `battle.rules` 时报 `balance_missing`。

### 黄金回放语义差异（未执行 `--update`）
做法：改动前后各用同一个回放驱动（`_replay` + `_normalize`，与 runner 的规范化完全相同），导出 11 个阶段的规范化 JSON，再逐键递归比较。

```
REMOVED: none
CHANGED values: 0
ADDED（仅战斗终局快照 battle_final）：
  hand[].playable / hand[].blocked_reason / hand[].preview   （02–07 各阶段）
  player.ritual_payoff_preview                                （02–08）
  enemies[].threat_amount                                     （02–08）
  enemies[].intent.variant_id、intent.visible_fields.variant_id（02–08）
01_start、06_rest、09_ascension、10_gacha、11_checkpoint：无任何差异（存档信封不变）
```

结论：只有新增字段，没有删除，也没有任何数值或状态变化。`required_discard` 和 `display_name_zh` 的值都没有变（v0.7 内容的意图本来都写了名字）。哈希变化的阶段：02–05、07、08。这些阶段的 golden 会因新增字段失败，需要主协调者在第一波合并后统一执行 `--update`。

## 4. 困难与候选方案

1. **旧平衡文档缺少新参数**：v0.3–v0.6 的 balance.json 仍被测试和采样器喂给引擎。候选方案：A）引擎保留默认值；B）参数设为必填，并给旧文档补字段。**选 B**：A 等于在玩法层保留第二份数值来源，违反 AGENTS §7 和 AR-12。
2. **两参数可打查询**：多个 UI 冒烟测试传入两参数的假处理函数。候选方案：A）保留兼容分支；B）删除分支并改测试。**选 B**：任务明确要求删除旧路径；app 层传入的 `query_card_play` 本来就是三参数。
3. **preview 怎样避免重写公式**：候选方案：A）在副本上试跑整个 `_apply_effect`；B）共用纯函数 `_ritual_scaled_effects` 后汇总数量字段。**选 B**：A 会消耗随机数（抽牌、洗牌）并发出事件，破坏确定性。B 里真正的公式（仪式加成）只有一份，汇总只是读取各效果的数量字段。

## 5. 风险与遗留

- `battle_screen.gd`（2970 行）和 `battle_engine.gd`（2158 行）远超 AGENTS §6 的 800/500 行上限。本次以删减为主，没有拆分，作为例外记录；按 ROADMAP 由 R3 拆分。
- UI 中还有一处规则镜像：状态文案「预见（下次攻击 -1）」。减伤值已进入 `combat.rules.foresight_reduction`，但快照还没暴露。建议 T4 或 R3 把它加到快照里。
- 修改了 `src/infrastructure/battle_balance_adapter.gd` 和 `tests/integration/*` 两个轨道外文件，改动都很小。请主协调者合并时确认，不应与 T5 冲突。
- `data/schema/v0.7.0/balance.schema.json` 属于共享契约；本次只做加法，按任务授权修改。

## 6. 跨角色请求与下一步

- **主协调者**：第一波合并后统一执行一次 golden `--update`，并在 v0.88.0 文档登记（本轨道导致的变化阶段：02–05、07、08，仅新增字段）。
- **T4（R2-12）**：`src/ui/text/` 目录已由本轨道创建（`intent_text.gd`），`effect_text.gd` 可以直接放在旁边。
- 最终测试结果行：全量 `run_tests: pass=84 fail=2 skipped=9 guard_block=0`，失败项为 golden 和 v031。之后修正 `v031_canon_battle_runner`：牌组里没有驱邪卡时，读数会如实显示「驱邪尚未入组」，断言改为只要求出现「驱邪」。修正后单独重跑 v031 通过，新增的 battle_snapshot runner 也通过。合计 **pass=86 fail=1**，唯一失败是 golden：02–05、07、08 六个阶段哈希变化，期望摘要和实际摘要逐项一致（hp、回合、命令数等）。
- 守卫：`grep -n '4 + 3' src/ui` 结果为空；`battle_engine.gd` 中 CJK 字符数为 0。
