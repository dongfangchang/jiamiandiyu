# v0.28.0 QA 报告

## 验证范围

- Godot 4.7.2 编辑器 headless 扫描。
- v0.28 专项：扮演消化、魔药库存、序列晋升、连续波次。
- 既有核心玩法、进度、路线、v0.7 后端和 UI smoke 回归。

## 结果

- `V028_POTION_DIGESTION_OK checks=21`
- `GAMEPLAY_TESTS_OK checks=131`
- `PROGRESSION_TESTS_OK checks=103`
- `ROUTE_TESTS_OK checks=99`
- `V07_BACKEND_TESTS_OK checks=43`
- `UI_SMOKE_OK checks=33`
- 编辑器脚本扫描通过。
- `git diff --check` 通过。

## 修复记录

- 遭遇 schema 支持 `waves`，保留旧 `enemy_slots` 兼容路径。
- 进度内容端口补齐卡牌定义读取，避免扮演记录运行时崩溃。
- 敌方回合结束时先激活下一波，再判定胜利；下一波敌人重新执行状态与阶段校验。

## 未决项

- 真实窗口截图和独立构建应在版本发布前补齐。
- 序列 8 小丑戏法卡牌与封印物进入下一版本。
