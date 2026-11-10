# v0.33.0 玩法设计报告

版本：v0.33.0  
角色：玩法设计  
任务：预设对抗提示写入 decks 并由快照透出  
状态：完成

## 修改文件

- `data/decks/v0.7.0/decks.json`：四套预设增加 `strategy_tag_zh` / `best_against_zh` / `caution_zh` / `combo_focus_zh`
- `src/gameplay/deck_engine.gd`：快照透出上述字段
- `tests/gameplay/v033_deck_guidance_runner.gd(.tscn)`

## 验证

`V033_DECK_GUIDANCE_OK checks=37`

```text
版本：v0.33.0
角色：玩法设计
任务：预设引导数据与快照
状态：完成
修改文件：data/decks/v0.7.0/decks.json, src/gameplay/deck_engine.gd, tests/gameplay/v033_deck_guidance_runner.*
依赖：无
验证：V033_DECK_GUIDANCE_OK checks=37
困难与候选方案：引导放 UI 硬编码 vs 数据；选数据为唯一定义
最终解决：decks.json + snapshot
风险：无
跨角色请求：UI 只读快照
下一步入口：无
```
