# v0.2.0 数据 Schema

本目录由本地数据层维护，是当前版本数据结构的唯一 schema 来源。

## 文件

- `content_envelope.schema.json`：通用内容文档的最小版本信封。
- `save.schema.json`：本地存档的必需字段、基础类型和日期格式。
- `balance.schema.json`：当前数值草案的顶层结构与稳定 ID 要求。
- `battle_cards.schema.json`：战斗卡牌定义的稳定 ID、费用、目标类型、效果数组和效果 ID 枚举。

## 战斗端口适配

- `BattleContentAdapter` 只索引经过 `battle_cards.schema.json` 校验的 `cards` 数组。
- `BattleBalanceAdapter` 只把冻结参数 ID 映射到 `balance_draft.json` 的单一数值源，不提供默认参数。
- `BattleRandomAdapter` 将命名 `SeededRandomStream` 适配到 `BattleRandomPort`。
- 文件读取、schema 校验和适配器实例化由 `src/app/bootstrap.gd` 统一装配。
- 当前 `tests/infrastructure/fixtures/battle_cards.json` 只用于端口验证；正式卡牌效果仍由玩法设计在 `data/cards/**` 提供。

## 校验器

`src/infrastructure/schema_validator.gd` 只实现当前实际使用的 JSON Schema 子集：

- `type`
- `const`
- `enum`
- `required`
- `properties`
- `additionalProperties`
- `items`
- `minItems` / `maxItems`
- `minProperties`
- `minLength` / `maxLength`
- `pattern`
- `minimum` / `maximum`
- 自定义 `x-uniqueBy`

这不是完整 JSON Schema 实现。新增关键字段时若需要 `$ref`、`oneOf`、条件 schema 或复杂组合，必须先评审校验器复杂度，不能静默忽略。

## 稳定 ID

- 卡牌 ID 以 `card.` 开头。
- 敌人 ID 以 `enemy.` 开头。
- 数组使用 `x-uniqueBy` 校验稳定 ID 唯一。
- 中文显示名称不参与主键。

## 版本规则

- `schema_version` 表示数据文档结构版本。
- `save_version` 表示存档迁移版本，二者含义不同。
- 当前 `save_version` 从 1 开始；加载顺序为解析、版本迁移、迁移后完整 schema 校验。
- schema 变更必须同时更新本目录、校验器和回归测试。

## 测试

在项目根目录运行：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/infrastructure/test_runner.gd
```

当前覆盖 59 项检查，包括内容与数值端口映射、缺失 ID、对无效效果的 schema 拒绝、固定种子适配和完整应用装配。
