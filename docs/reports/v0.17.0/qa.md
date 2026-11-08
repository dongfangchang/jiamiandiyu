# v0.17.0 / QA 工作记录

## 状态

- 状态：通过
- 任务：验证试玩引导和战斗行动提示改动

## 结果

| 检查 | 结果 |
|---|---|
| UI smoke | `UI_SMOKE_OK checks=33` |
| 多视口布局 | `V014_CARD_LAYOUT_OK checks=20` |
| macOS headless 启动 | 退出码 0 |
| Shell 语法 | `zsh -n` 通过 |
| 格式检查 | `git diff --check` 通过 |

## 结论

提示来自已有快照和 UI 选择状态，没有改变规则或结算；本版可交由产品经理关闭。
