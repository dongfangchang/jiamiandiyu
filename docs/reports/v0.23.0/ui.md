# v0.23.0 / UI 设计工作记录

## 状态

- 状态：完成 UI 增量，已提交并推送，等待版本集成验收
- 任务：让抽卡页面直接解释当前稀有概率和保底上限，降低抽取决策成本。

## 实现

- `src/ui/gacha_screen.gd` 在抽卡底部操作区增加只读“抽取说明”文案。
- 文案只读取成长快照中的 `rarity_weights.rare` 与 `rare_pity`，不在 UI 计算概率、保底或抽卡结果。
- 快照缺少字段或保底值无效时显示安全回退，不阻塞返回和其他操作。
- `tests/ui/ui_progression_smoke_runner.gd` 增加概率与保底说明断言。
- 升级卡片补充“可升级 / 还需 N 页 / 已满级 / 未收容”的下一步状态文案，并增加状态回归断言。

## 验证

- `git diff --check`：通过。
- `PROGRESSION_UI_SMOKE_OK checks=45`：通过。
- 提交：`554d57b feat(v0.23.0): explain gacha pity guidance`，已推送 `origin/main`。
- 本机未安装 Godot 4.7.2 命令行，`PROGRESSION_UI_SMOKE` 需在项目提供的 Godot 环境中运行。

## 风险与下一步

- 说明依赖玩法层已有的 `rarity_weights` 与 `rare_pity` 快照字段；字段缺失时使用安全回退。
- 版本集成时由 QA 在 Godot headless、实际窗口和截图回归中确认窄视口下文案不会遮挡抽取按钮。
