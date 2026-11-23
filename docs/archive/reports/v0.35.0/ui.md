# v0.35.0 UI 报告

版本：v0.35.0  
角色：UI  
任务：战斗桌面手感全套  
状态：完成

## 已完成

- 新增 `battle_table_feel.gd`：物件化 meter、意图图标映射、联动缺口 ID
- 拖放打出 + 指向线（`AimOverlay`）；点选 / 「打出」按钮保留
- 手牌悬停放大抬升；联动缺口金边高亮
- 生命/灵性/污染/被注视改为分段条 + 图标
- 敌人意图行：图标 + 短文案 + 危险徽章；危险艺术调红
- 去掉敌人区嵌套纵向滚动（1600×900 主舞台）；页滚动降级保留

## 验证

```text
V035_BATTLE_FEEL_OK checks=25
V031_CANON_BATTLE_OK checks=110
V05_ROUTE_UI_SMOKE_OK checks=64
V07_DECK_UI_SMOKE_OK checks=66
V033_DECK_GUIDANCE_UI_OK checks=18
V091_REGRESSION_OK checks=77
V031_CARD_VALUE_AUDIT_OK checks=145
```

```text
版本：v0.35.0
角色：UI
任务：拖放/悬停/物件化 HUD/意图姿态
状态：完成
修改文件：src/ui/battle_screen.gd, src/ui/battle_table_feel.gd, tests/ui/v035_battle_feel_runner.*
依赖：v0.35 开版；快照字段足够
验证：见上
困难与候选方案：头测无法完整模拟 OS 拖放；以控件面 + 点选降级合同覆盖
最终解决：拖放提交既有 BattleCommand；点选路径未删
风险：真机拖放命中热区需试玩微调
跨角色请求：协调者关版前试玩拖放命中
下一步入口：真人桌面手感试玩
```
