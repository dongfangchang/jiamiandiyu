# v0.21.0 / UI 设计工作记录

## 状态

- 状态：完成
- 任务：在预设卡片中显示 8 张、平均灵性费用和最高费用摘要

## 验证

- `V07_DECK_UI_SMOKE_OK checks=50`
- `V020_PRESET_METRICS_OK checks=72 presets=4`
- 缺失卡牌数据时显示回退提示，不阻断牌组操作。
