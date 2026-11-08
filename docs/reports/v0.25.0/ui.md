# v0.25.0 / UI 工作记录

## 状态

- 状态：首个切片完成，继续推进全页面审查

## 已完成

- 战斗页根据页面实际纵向/横向溢出显示滚动提示。
- 标准窗口不显示无效提示；窄窗口提示如何查看手牌和操作。
- 保持现有 ScrollContainer 和稳定资源路径，不改变玩法命令。

## 验证

- `V025_VIEWPORT_GUIDANCE_OK checks=4`
- `V014_CARD_LAYOUT_OK checks=20`
