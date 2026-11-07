# v0.3.0 正式内容 schema

三类内容分别使用独立文档：

- `data/cards/v0.3.0/*.json` 使用 `cards.schema.json`
- `data/enemies/v0.3.0/*.json` 使用 `enemies.schema.json`
- `data/encounters/v0.3.0/*.json` 使用 `encounters.schema.json`
- `data/balance/v0.3.0/balance.json` 使用 `balance.schema.json`

当前加载器每个类别读取一个聚合文档。跨文档引用、内容版本一致性和三列位置唯一性由 `CampaignContentCatalog` 在 schema 校验之后检查。

`balance.json` 只保存跨内容全局参数。卡牌费用与效果、敌人生命与攻击、遭遇牌组和敌人列分别只在对应内容文档中定义。

`schema_version` 描述文档格式版本，`content_version` 描述内容批次版本。显示名称不是主键，所有引用都使用点分稳定 ID。
