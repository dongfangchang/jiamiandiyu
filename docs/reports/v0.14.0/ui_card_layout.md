# v0.14.0 / UI 卡牌裁切专项修复

## 状态

- 版本：`v0.14.0`
- 角色：UI
- 任务：修复卡牌在小窗口和 UI 缩放下被截断
- 状态：完成
- 最后更新：2026-11-08
- 下一步入口：主协调者纳入统一 QA 与独立构建

## 用户问题

用户报告即使升级到新版，卡牌仍会被截断。此前只缩小了单张卡高度，但仍假设整个战斗页面固定为 1600×900，窗口客户区不足或 UI 放大时会裁掉页面底部。

## 根因

- 战斗页面根容器直接占满逻辑视口，没有窗口高度不足时的降级路径。
- 手牌区使用固定最小高度，无法随可用高度收缩。
- 启动时窗口固定为 1600×900，没有限制在操作系统可用桌面区域内。
- UI 缩放大于 1.0 时，逻辑布局空间进一步减少，固定高度内容会被裁切。

## 方案比较

| 方案 | 结果 | 结论 |
|---|---|---|
| 继续减小卡片固定高度 | 只适配某个分辨率，其他缩放仍会裁切 | 拒绝 |
| 只允许 UI scale ≤ 1.0 | 限制用户设置且窗口客户区问题仍存在 | 拒绝 |
| 固定高度加条件分支 | 难以覆盖未知缩放和窗口尺寸 | 拒绝 |
| 完整页面滚动降级 + 窗口可用区 clamp | 标准分辨率保持原样，小窗口仍可访问所有卡牌 | 采用 |

## 最终修复

- 战斗页面增加纵向/横向滚动兜底，内容基准仍为 1600×900。
- 1600×900 不出现页面滚动条，保持现有布局。
- 1366×768、1333×750、1280×720 等较小逻辑视口可滚动访问完整手牌和选择按钮。
- 整张卡牌继续可点击，选择按钮保留。
- 应用窗口非全屏时自动限制在桌面可用区域内，避免窗口本身超出屏幕。
- 全屏模式不受窗口尺寸 clamp 影响。

## 修改文件

- `src/ui/battle_screen.gd`
- `src/app/app_controller.gd`
- `tests/ui/v014_card_layout_runner.gd`
- `tests/ui/v014_card_layout_runner.tscn`

## 验证

```text
V014_CARD_LAYOUT_OK checks=20      # headless layout
V014_CARD_LAYOUT_OK checks=24      # rendered layout + screenshots
UI_SMOKE_OK checks=33
V0100_CHAIN_UI_OK checks=4
V011_STATUS_KEYWORD_OK checks=8
APP_V07_INTEGRATION_OK checks=132
main headless exit=0
```

覆盖逻辑视口：

- 1600×900
- 1366×768
- 1333×750（约 1.2 UI scale 的有效空间）
- 1280×720

渲染截图：

- `.tools/ui-captures/card_layout_1600x900.png`
- `.tools/ui-captures/card_layout_1366x768.png`
- `.tools/ui-captures/card_layout_1333x750.png`
- `.tools/ui-captures/card_layout_1280x720.png`
- `.tools/ui-captures/battle_screen.png`

## 风险

- 极小窗口需要页面滚动才能同时查看战场和手牌，但不会再丢失操作入口。
- 本次没有改变战斗规则、卡牌数据或存档格式。

## 跨角色请求

请主协调者在 v0.14.0 统一 QA 中加入 `tests/ui/v014_card_layout_runner.tscn`，并在正式构建后重新截图。
