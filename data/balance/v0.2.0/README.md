# v0.2.0 数值草案

`balance_draft.json` 是数值设计角色提出的首版参数草案，不是玩法层可直接视为已批准的事实源。

## 使用边界

- 生命、灵性、敌人、奖励、抽卡和升级参数可被模拟器与后续玩法实现读取。
- 卡牌 `effect_budget` 描述费用对应的效果预算，不定义具体卡牌规则。
- `card.artifact.watchers_eye` 由首领固定掉落，不进入随机卡池。
- `card.skill.cold_reading` 由精英敌人固定掉落，不进入随机卡池。
- 所有数值均需产品经理审核并与玩法设计语义对齐后才能冻结。
- 共享 schema 由 `data/schema/v0.2.0/**` 单独维护；本文件只保存数值内容。

## 敌方压力

`combat.enemy_pressure` 是 ADR-0003 的正式规则参数：

- `start_round = 7`
- `attack_bonus_per_completed_enemy_round = 1`
- `reset_each_battle = true`

第 7 回合的敌方攻击使用原始伤害；该回合完整结束后压力加 1，后续敌方行动才应用加成。压力在每场战斗开始时清零。

## 可复现验证

在项目根目录运行：

```powershell
node tools/simulation/balance_probe.mjs
```

数值契约和模拟可复现测试：

```powershell
node --test tests/simulation/*.test.mjs
```

固定种子、样本数与模拟配置记录在 `balance_draft.json` 的 `simulation` 字段。
