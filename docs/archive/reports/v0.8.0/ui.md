# v0.8.0 / UI 工作记录

## 状态

- 版本：`v0.8.0`
- 角色：UI 设计
- 状态：完成

## 完成内容

- 首次启动五步引导，支持跳过与从设置重新打开。
- 设置与玩法说明覆盖层：全屏、界面缩放、减少闪烁偏好。
- 新游戏覆盖现有检查点前显示确认对话框。
- 主菜单显示备份可用状态并提供恢复入口。
- 主菜单继续显示身份、序列、牌组、资源、收藏和挑战摘要。
- 设置保存与备份恢复均有可见成功或失败反馈。

## 验证

```text
SYSTEM_UI_SMOKE_OK checks=7
UI_SMOKE_OK checks=33
V07_DECK_UI_SMOKE_OK checks=46
main scene --quit-after 5: exit 0
```

实际截图：

- `.tools/ui-captures/tutorial_screen.png`
- `.tools/ui-captures/settings_screen.png`
- `.tools/ui-captures/start_screen.png`

## 风险

- “减少闪烁”已持久化，但当前界面本身没有强闪烁动画，因此该选项目前只作为后续表现层约束。
- 设置页使用 Godot 默认控件字体与基础样式，功能优先于进一步装饰。
