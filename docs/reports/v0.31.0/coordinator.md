# v0.31.0 主协调者报告

任务：卡牌平衡重构、原著对齐、界面挤压修复。
状态：完成（本地，未推送）。

验证：
- 全量 QA（45+ 组）通过，含新增 `V031_CARD_VALUE_AUDIT_OK checks=145`、`V031_CANON_BATTLE_OK checks=114`。
- 截图：`.tools/ui-captures/v0.31.0/battle_megose_1600x900.png`、`battle_megose_1100x700.png`、`battle_tyrell_1600x900.png`。
- 难度抽样：`tools/simulation/v031_canon_sampling_runner.tscn`。

风险：新敌人暂用回退立绘；首领数值按贪心策略调校，真人体验需复测。

协作备忘：外部 skill 选用清单见同目录 `skill_playbook.md`（默认启用 balance/Godot/QA；美术与拆书按需；不跑 NovelToGame / Game-Studios 初始化接管仓库）。
