# v0.6.0 数据 schema

- `challenges.schema.json`：序列 8 后挑战、修饰和完成奖励的正式结构；修饰可声明 0—10 点的战后污染增量 `battle_corruption_delta`。
- `save.schema.json`：存档版本 4，在 v0.5 路线检查点上增加挑战状态。
- 卡牌、敌人、遭遇、路线、仪式和 balance 继续使用 v0.5 schema；v0.6 不复制其定义。
- v1、v2、v3 存档通过显式迁移链读取，迁移失败时保留原文件。
