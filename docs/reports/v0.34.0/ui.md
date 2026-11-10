# v0.34.0 UI 报告

版本：v0.34.0  
角色：UI  
任务：档案控件、减负、策略表达  
状态：完成（关版待试玩）

## 已完成

- `UiTheme.seal_button` / `archive_tab_row`：蜡封条页签
- 牌组筛选 / 祈愿历史 / 设置缩放 / 反馈范围与节奏：全部去掉 `OptionButton`
- 预设卡默认只留名称/标签/一句钩子/费用；适合·慎用进 tooltip
- 战斗：情报与联动默认文案缩短；联动显示“差哪张”
- 路线：页头只留决策行；节点故事压缩，出处进悬停
- 仪式：出处与 lore 进悬停；步骤面只留线索与关键资源

## 验证

```text
V05_ROUTE_UI_SMOKE_OK checks=64
V031_CANON_BATTLE_OK checks=114
V07_DECK_UI_SMOKE_OK checks=66
V033_DECK_GUIDANCE_UI_OK checks=18
```

`src/ui/**` 已无 `OptionButton` 实例。数值加压由数值角色完成，不在 UI 范围。

## 未做 / 关版依赖

- 真人试玩确认悬停可发现性

```text
版本：v0.34.0
角色：UI
任务：档案控件与全页减负
状态：完成
修改文件：mask_ui_theme.gd, deck_screen.gd, gacha_screen.gd, battle_screen.gd, route_screen.gd, ritual_screen.gd, start_screen.gd, tests/ui/v05_route_ui_smoke_runner.gd
依赖：v0.34 开版
验证：见上
困难与候选方案：路线收益文案改短后旧断言失效；更新测试为检查收益内容
最终解决：主路径无系统下拉；路线/仪式长文进悬停
风险：悬停信息可发现性需试玩
跨角色请求：产品经理安排试玩后关版
下一步入口：悬停可发现性试玩
```
