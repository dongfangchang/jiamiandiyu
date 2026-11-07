# v0.4.0 成长配置

`progression.json` 只保存内容语义，不复制 `data/cards/v0.3.0/cards.json` 中的卡牌效果金额。

## 字段

- `identities`：白昼身份稳定 ID、显示文本和唯一战斗/资源修正。
- `starter_card_ids`：新游戏确定性拥有的卡牌；关键战斗牌不得依赖抽卡。
- `gacha_pool`：卡池中的稳定卡牌 ID 和 `common` / `rare` 稀有度。
- `reward_options`：战后二选一奖励的内容定义；实际数量从 `data/balance/**` 读取。
- `upgrade_definitions`：卡牌升级上限和按 `effect_index`、`field` 描述的每级增量。

## 固定规则

- 卡牌基础效果仍以 `data/cards/v0.3.0/cards.json` 为唯一来源。
- 抽卡概率、保底、费用、重复碎片和升级成本由平衡数据提供。
- 升级后的卡牌通过 `UpgradedBattleContentPort` 在下一场战斗读取，不写回基础内容。
- 抽卡随机流名称由应用装配为 `gacha.draw`；测试必须固定种子复现。
- 所有祈愿池卡牌必须具有有效升级定义，避免重复卡产生无法消耗的碎片。
- 只有揭示效果、没有可提升数值字段的纯工具牌可以确定性拥有，但不进入祈愿池；`card.skill.second_look` 属于这一类。

## 待数据层接入

当前文件等待 `data/schema/v0.4.0/progression.schema.json` 校验，并需要应用层把该内容映射为 `ProgressionContentPort`。
