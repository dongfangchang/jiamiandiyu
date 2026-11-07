# v0.6.0 / 数值设计工作记录

## 状态

- 版本：`v0.6.0`
- 角色：数值设计
- 任务：挑战修饰经济、真实引擎采样与风险验证
- 状态：完成（已按 v0.6 污染压力重新采样）
- 最终更新：2026-11-08
- 下一入口：v0.7 卡组构筑数值、第二挑战采样与正式独立构建

## 本版本目标

验证三种挑战修饰是否改变玩家决策，而不只是提高敌人生命；为序列 8 后的重复挑战提供可复现的数值证据。

## 依赖

- `AGENTS.md`、当前版本、架构契约和 ADR-0009。
- `docs/reports/v0.6.0/gameplay.md` 与 `data/challenges/v0.6.0/challenges.json`。
- `ChallengeEngine`、`RouteEngine`、`BattleEngine`、`ProgressionEngine`。
- v0.5 正式路线、卡牌、敌人、遭遇和仪式数据。

## 交付

- `data/balance/v0.6.0/balance.json`：复用 v0.5 全局基线，不复制卡牌、敌人、修饰或挑战奖励。
- `data/balance/v0.6.0/README.md`：说明全局参数与内容定义的边界。
- `tools/simulation/challenge_sampling_runner.gd`：真实挑战固定种子采样器。
- `tools/simulation/v06_challenge_content_adapter.gd`：仿真侧挑战内容适配器。
- `tools/simulation/v06_identity_route_content_port.gd`：在挑战路线初始化前应用身份修正。
- `tests/simulation/v06_challenge_contract_runner.gd`：48 项挑战编号。
- `tools/simulation/out/v0.6.0_challenge_sampling.json`：1800 条有效挑战结果。

## 挑战奖励

基础奖励来自 `data/challenges/v0.6.0/challenges.json`：

- 占卜券 +2。
- 墨刺碎片 +4。

`modifier.fractured_deck` 额外增加占卜券 +1。挑战未完成时不发放基础奖励；局外收藏、卡牌等级和已确认奖励不得被删除。

## 采样设置

- 根种子：`20261108`。
- 18 个挑战用例：3 修饰 × 记者/医生 × 3 策略；每个组合 100 条。
- 三种策略为激进、均衡和“忽视污染、始终包扎”的脆弱策略。
- 总有效路线：1800；无效路线：0。
- 升级/抽卡继续使用 v0.4 正式成长引擎。
- 仪式使用正式三步顺序，在采样中执行正确答案，以隔离挑战修饰对战斗与资源的影响。

## 核心结果

| 修饰 | 完成率 | 平均回合 | 平均估算时长 | 休息：包扎/封锁 | 首阶段回合 | 阶段事件 |
|---|---:|---:|---:|---:|---:|---:|
| `rushed_reflection` | 100% | 12.97 | 19.87 分钟 | 348 / 252 | 1.0 | 2.99 |
| `tainted_margins` | 66.67% | 12.61 | 19.59 分钟 | 200 / 400 | 3.0 | 2.29 |
| `fractured_deck` | 100% | 9.78 | 17.40 分钟 | 600 / 0 | 3.0 | 2.03 |

决策差异：

- `rushed_reflection` 将首领/阶段触发从第 3 回合提前到第 1 回合，阶段事件增加，并把策略样本推向更多封锁回声。
- `tainted_margins` 初始提供 4 污染和 1 被注视，每场战斗胜利后再增加 2 污染。正常策略选择封锁回声后可以完成；脆弱策略始终包扎，200/200 条样本均在 `route.v050.node.mirror_baron` 后因污染达到 10 而失败。
- `tainted_margins` 的 200 条失败样本全部通过 `collection_preserved_failures=200` 验证：已拥有卡牌数量与等级没有减少，失败不会删除局外成长。
- `fractured_deck` 将首战牌组从 10 张降到 8 张，移除所有纸符护持，所有策略样本改用包扎，形成明确的防护能力取舍。

估算时长区间：

- `rushed_reflection`：17.19—21.94 分钟。
- `tainted_margins`：16.91—21.42 分钟。
- `fractured_deck`：15.11—19.07 分钟。

所有组合规划中值均落在 ADR-0008 的 15—30 分钟目标内。

## 验证

```text
CHALLENGE_SAMPLING_SHA256=51E83297D893C3C154910729B7707EC86F01D7C92E69343F8266DBA921DDF8B4
V06_CHALLENGE_TESTS_OK checks=48
CHALLENGE_TESTS_OK checks=89
ROUTE_TESTS_OK checks=98
PROGRESSION_TESTS_OK checks=103
GAMEPLAY_TESTS_OK checks=131
V05_ROUTE_TESTS_OK checks=47
V04_ECONOMY_TESTS_OK checks=54
SIMULATION_TESTS_OK checks=33
```

采样输出连续两次 SHA-256 一致；挑战修饰 ID、路线引用、奖励引用和固定种子回放均可解析。

## 困难与解决

| 困难 | 候选方案 | 最终解决 |
|---|---|---|
| ChallengeEngine 不直接消费 ProgressionEngine | 复制身份逻辑进采样器；修改玩法层；仿真侧只写端口包装 | 使用 `v06_identity_route_content_port.gd` 在路线初始化前调用现有 `apply_battle_modifiers`，不复制规则 |
| 初始战斗事件未被统计 | 只统计后续提交；读取 BattleEngine 初始结果事件；减少样本 | 读取 initial events，并单独记录每场战斗最早阶段回合，避免遗漏第 1 回合阶段 |
| 连续采样耗时较长 | 减少到 50；每个组合 100 条并保持固定种子 | 选择 100 条/组合，保留修饰、身份和策略分层 |
| 旧采样没有自然失败样本 | 继续提高全局伤害；增加脆弱策略验证规则是否真正生效 | 新增“忽视污染”策略；污染挑战在该策略下 200/200 失败，正常策略仍可完成；未通过虚增敌人生命制造难度 |

## 风险与未决问题

- `rushed_reflection` 和 `fractured_deck` 的正常策略仍为 100% 完成，当前主要依赖 `tainted_margins` 提供实际失败压力。
- 失败压力集中在首领战后污染阈值，属于路线末段风险；若后续需要更早、多波次的失败压力，应由玩法内容增加机制，而不是抬高全局敌人生命。
- `fractured_deck` 移除护符后仍比 `rushed_reflection` 更快完成，说明护符并非唯一胜负关键；这属于构筑深度不足，不应通过提高敌人血量掩盖。
- 当前时间模型是规划估算，不是人工秒表。
- 挑战完成奖励的持久化和完整 app 集成已完成；本采样保留为挑战数值证据。

## 跨角色请求

- 玩法设计：保持污染挑战在“包扎失败、封锁回声可完成”的明确取舍；后续扩展挑战时优先增加阶段或资源压力。
- 数据层：继续保持挑战奖励通过既有 ProgressionEngine 结算，并验证失败不清空局外收藏、等级或已确认奖励。
- UI：展示挑战修饰、初始污染/被注视、牌组限制和完成奖励；不得自行计算奖励。
- 产品经理：将 `tainted_margins` 的失败压力作为 v0.6 挑战体验证据；另外两种修饰当前仍以构筑展示和快节奏为主，不应宣传为高难挑战。

## 下一步

挑战前后端与数据、UI/app 路由、全量回归和最终 Windows 构建均已接入。若真实试玩仍感知不到失败压力，进入后续内容版本，而不是继续堆叠全局数值。
