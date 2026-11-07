# v0.5.0 schema

本目录冻结短路线与首次晋升所需的离线数据边界：

- `routes.schema.json`：固定五节点路线、初始状态、休息选项和序列目标；休息效果可带可选整数 `max_spirit_delta`（范围 -5 到 5，缺省按 0 处理）。
- `rituals.schema.json`：三步晋升仪式、公开选项与答案引用。
- `enemies.schema.json`：精英/首领可选 `phases`。
- `encounters.schema.json`：跨版本基础卡包引用与敌人槽位。
- `balance.schema.json`：v0.5 全局参数入口，允许后续增加路线预算字段。
- `save.schema.json`：存档 v3，包含 progression 与 route 节点边界状态。

存档 `save_version` 当前为 `3`。v1 存档经 v2 路径迁移，v2 存档补充空路线状态后再进入 v3。迁移不会覆盖损坏主档；失败时保留原件并报告备份可用性。

卡牌自身金额和效果仍只定义在 `data/cards/v0.3.0/cards.json`。敌人、遭遇、路线和仪式通过 `base_cards_version` 引用该基础包，不复制卡牌定义。
