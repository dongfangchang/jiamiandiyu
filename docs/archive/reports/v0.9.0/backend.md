# v0.9.0 / 本地诊断工作记录

## 状态

- 版本：`v0.9.0`
- 角色：本地数据层开发
- 状态：完成

## 完成内容

- 新增 `PlaytestDiagnosticsService`。
- 每次启动独立记录 `user://diagnostics/session_*.json`。
- 事件包含经过时间、事件类型与稳定内容 ID。
- 会话摘要包含内容/构建版本、开始结束时间、总时长与结束位置。
- 反馈保存为独立 `feedback_*.json`，限制为 4000 字，不记录键鼠和系统路径。
- 文件采用临时文件后校验替换，失败不中断游戏。

## 验证

```text
DIAGNOSTICS_TESTS_OK checks=11
PREFERENCES_TESTS_OK checks=16
APP_V07_INTEGRATION_OK checks=131
main scene --quit-after 5: exit 0
```
