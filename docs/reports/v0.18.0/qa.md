# v0.18.0 / QA 工作记录

## 状态

- 状态：通过

## 结果

| 检查 | 结果 |
|---|---|
| 牌组平衡审计 | `V018_DECK_BALANCE_AUDIT_OK checks=81 presets=4` |
| UI smoke | `UI_SMOKE_OK checks=33` |
| 多视口布局 | `V014_CARD_LAYOUT_OK checks=20` |
| 格式检查 | `git diff --check` 通过 |

## 结论

审计只读取既有卡池和预设数据，未改变玩法、数值或存档；本版可关闭。
