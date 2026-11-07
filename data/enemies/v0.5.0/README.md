# v0.5.0 敌人内容

- `enemies.json` 包含三名单战敌人、一个精英敌人和一个首领。
- 首领 `enemy.mirror_baron` 使用可选的 `phases` 数组表达回合阶段。
- `phases[].at_round` 指定触发回合；`base_attack_bonus`、`block_bonus`、`heal` 是数据驱动修正。
- 卡牌继续引用 `data/cards/v0.3.0/cards.json`，本文件不复制卡牌定义。

数据层仍需为 `phases` 增加正式 schema，并在内容目录装配时保留该字段。
