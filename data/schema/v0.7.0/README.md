# v0.7.0 数据 schema

本目录固定 `v0.7.0` 的正式内容与存档边界：

- `cards.schema.json`：当前 20 张占卜家战斗卡。
- `balance.schema.json`：全局战斗、经济与概率参数边界。
- `progression.schema.json`：身份、初始卡、祈愿池、奖励和升级定义。
- `decks.schema.json`：牌组大小、卡池、默认预设和三套预设。
- `enemies.schema.json`、`encounters.schema.json`：敌人阶段与跨版本卡包引用。
- `routes.schema.json`、`rituals.schema.json`：固定路线与三步晋升仪式。
- `challenges.schema.json`：第一、第二挑战、稳定修饰与前置完成条件。
- `save.schema.json`：存档版本 5，包含路线、挑战和当前牌组状态。

跨文档稳定 ID 与引用关系由对应内容适配器进一步校验。schema 通过不代表引用完整，运行时装配必须同时检查。
