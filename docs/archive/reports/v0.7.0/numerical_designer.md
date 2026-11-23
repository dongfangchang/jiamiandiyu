# v0.7.0 / 数值设计工作记录

## 状态

- 版本：`v0.7.0`
- 角色：数值设计
- 任务：审核 16 张卡、三套牌组、双挑战与经济曲线
- 状态：最终复采样完成；三套牌组均存在可行路径

## 需求与依赖

- 正式卡牌、升级、牌组和挑战内容由玩法设计维护。
- 全局战斗、经济参数位于 `data/balance/v0.7.0/balance.json`。
- 本角色不修改 `data/cards/**`、`data/decks/**` 或玩法规则。

## 交付

- `data/balance/v0.7.0/balance.json`
- `data/balance/v0.7.0/README.md`
- `tools/simulation/v07_deck_content_adapter.gd`
- `tools/simulation/v07_challenge_content_adapter.gd`
- `tools/simulation/deck_sampling_runner.gd`
- `tools/simulation/deck_sampling_runner.tscn`
- `tools/simulation/out/v0.7.0_deck_sampling.json`
- `tests/simulation/v07_deck_contract_runner.gd`
- `tests/simulation/v07_deck_contract_runner.tscn`

## 采样方法

- 根种子：`20261108`
- 每案例 30 次运行。
- 3 套牌组 × 2 个身份 × 7 个场景 = 42 个案例。
- 7 个场景：首次路线、第一挑战 3 个修饰、第二挑战 3 个修饰。
- 后期收藏假设：已拥有全部 16 张卡，所有卡初始等级 0。
- 每场战斗使用已确认的 8 卡牌组，而不是遭遇中的固定参考牌组。
- 战斗内容通过 `ProgressionEngine.create_upgraded_content()` 获取升级后的卡牌金额。

## 最终复采样

玩法调整初始收藏与三套牌组后，按相同根种子和 42 个案例重新执行 1260 条真实引擎路线。

| 牌组 | 完成率 | 平均回合 | 平均估算时长 |
|---|---:|---:|---:|
| 守夜档案 | 45.48% | 19.00 | 24.17 分钟 |
| 灵性预感 | 71.90% | 14.53 | 22.28 分钟 |
| 棺钉凶兆 | 64.29% | 13.00 | 19.50 分钟 |

- 三套牌组不再存在 0% 或个位数完成率的不可用构筑。
- 首次路线总完成率 98.89%，平均估算 21.01 分钟。
- 第二挑战在讣告回声、双影同行、通宵守仪下完成率分别为 21.67%、30.56%、71.11%，形成不同压力。
- 固定种子输出 SHA-256：`80DB82D784C513D494E0B71DE6CA387D359A821BC7D4A8B7593F173121FC0900`。
- 全部样本仍位于 15—30 分钟目标区间。
- 未通过提高全局敌人生命或回合上限修正构筑问题。

## 验证

```text
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=103
ROUTE_TESTS_OK checks=98
CHALLENGE_TESTS_OK checks=89
V05_ROUTE_TESTS_OK checks=47
V06_CHALLENGE_TESTS_OK checks=48
V04_ECONOMY_TESTS_OK checks=54
V07_DECK_TESTS_OK checks=167
```

采样结果文件：

```text
SHA256=8D7D73EC18D0F6D24FAE7EACB6680341BF4C8673FEC6E46841C09F3ADE71FD44
```

三套牌组的 420 条有效运行结果：

| 牌组 | 完成率 | 平均回合 | 估算时长范围 | 主要失败节点 |
|---|---:|---:|---:|---|
| 守夜档案 | 2.14% | 21.57 | 23.43—29.10 分钟 | 精英、首领 |
| 灵性预感 | 0% | 13.52 | 18.06—22.07 分钟 | 精英、首领 |
| 棺钉凶兆 | 64.29% | 13.00 | 15.96—22.05 分钟 | 破碎游行首领 |

所有有效运行的估算时长都落在 ADR-0008 的 15—30 分钟范围内。灵性预感和守夜档案不是“速度稍慢”，而是没有稳定伤害路径；守夜档案平均每局使用墨刺 14.39 次、专注 13.56 次、再看一眼 12.48 次，说明大量回合用于低伤害过滤。灵性预感平均使用凶兆 11.04 次、墨刺 10.93 次，但最高单次伤害不足以稳定击穿精英与首领。

挑战场景仍体现差异：第二挑战“通宵守仪”在棺钉凶兆下约 93—100% 完成，而“讣告回声”和“双影同行”明显压低完成率；这说明挑战修饰并非全部无效。第一挑战的 `tainted_margins` 也通过污染压力成功制造失败。

## 初轮结论与风险（已由最终复采样替代）

当前 `v0.7.0` 不能通过构筑可行性验收。棺钉凶兆是唯一具有完整路线的牌组；守夜档案与灵性预感均缺少足够的高价值攻击牌，导致精英和首领战无法稳定结束。该问题来自 `data/decks/v0.7.0/decks.json` 的牌组组成，而不是全局生命值不足。

建议由玩法设计在牌组事实源中前向调整：

- 守夜档案将 `card.skill.insight`、`card.skill.second_look` 中至少一张替换为 `card.skill.piercing_omen`、`card.skill.coffin_nail` 或 `card.skill.fated_echo`，同时保留至少两张防御牌。
- 灵性预感将 `card.skill.whisper`、`card.skill.second_sight` 中至少一张替换为高价值终结牌，保留灵性/抽牌核心。
- 不对 `combat.max_rounds` 或将所有敌人生命值做全局调整；这会放大棺钉凶兆的一枝独秀，并掩盖构筑结构问题。

调整后应只重跑三套牌组、记者/医生和首次路线/两个挑战，确认每套牌组至少存在可行路线，并保持 15—30 分钟估算。当前数值合同测试通过，但“合同通过”不等于“构筑平衡通过”。
