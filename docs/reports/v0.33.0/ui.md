# v0.33.0 UI 报告

版本：v0.33.0  
角色：UI  
任务：预设卡显示适合/慎用；目录降为回退  
状态：完成

## 修改文件

- `src/ui/deck_screen.gd`：优先快照引导字段；暴露 `get_preset_guidance`
- `src/ui/deck_ui_catalog.gd`：硬编码仅作回退
- `tests/ui/v033_deck_guidance_ui_runner.gd(.tscn)`

## 验证

`V033_DECK_GUIDANCE_UI_OK checks=18`；序列锁定中文原因断言通过。

```text
版本：v0.33.0
角色：UI
任务：预设对抗提示展示
状态：完成
修改文件：src/ui/deck_screen.gd, src/ui/deck_ui_catalog.gd, tests/ui/v033_deck_guidance_ui_runner.*
依赖：玩法快照字段
验证：V033_DECK_GUIDANCE_UI_OK checks=18
困难与候选方案：增高预设卡 vs 滚动；选用固定增高 148px + clip_label
最终解决：preset card 显示适合/慎用
风险：窄视口下预设行更高，已有滚动降级依赖既有布局
跨角色请求：无
下一步入口：无
```
