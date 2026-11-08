# v0.16.0 / QA 工作记录

## 状态

- 状态：通过
- 当前任务：验证 UI 主操作层级和现有窗口布局回归
- 最后更新：2026-11-08

## 验收结果

| 检查 | 命令 | 结果 |
|---|---|---|
| UI smoke | `Godot --headless --path . res://tests/ui/ui_smoke_runner.tscn` | `UI_SMOKE_OK checks=33` |
| 多视口布局 | `Godot --headless --path . res://tests/ui/v014_card_layout_runner.tscn` | `V014_CARD_LAYOUT_OK checks=20` |
| 项目启动 | `./play-mac.sh --headless --quit-after 1` | 退出码 0 |
| 脚本语法 | `zsh -n open-editor-mac.sh play-mac.sh` | PASS |
| 格式检查 | `git diff --check` | PASS |

## 结论

共用按钮主题和主操作标记未修改玩法、数值、存档、core 契约或正式资源；现有 1600×900、1366×768、1333×750、1280×720 布局回归通过，可交由产品经理关闭版本。
