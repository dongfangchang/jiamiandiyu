# 基础设施测试

运行：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/infrastructure/test_runner.gd
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/infrastructure/route_backend_runner.tscn
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/infrastructure/challenge_backend_runner.tscn
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/infrastructure/v07_backend_runner.tscn
```

测试覆盖：

- JSON 内容解析与 schema 校验
- 当前数值草案 schema
- 战斗卡牌效果 schema 与缺失 effect 校验
- 稳定 ID 唯一性
- 固定种子随机流的可复现性与隔离
- `BattleRandomPort` / `BattleContentPort` / `BattleBalancePort` 适配
- 缺失内容或数值参数不会被默认值掩盖
- 原子存档往返和备份
- 无效新档不覆盖现有存档
- 损坏主档报告备份
- 迁移缺失与成功迁移
- 结构化日志
- 应用服务与完整战斗端口装配
- v0.5 路线/仪式 schema、跨版本基础卡包与敌人阶段
- 身份到五节点路线、节点边界恢复、首领与晋升持久化
- v1 -> v2 -> v3 连续存档迁移
- v0.6 挑战定义/schema、修饰引用、挑战会话语义和 v3 -> v4 迁移

测试使用 `user://mask_whispers_infrastructure_tests`，运行前后自动清理。

当前基线：

- 基础设施主测试：`150 passed, 0 failed`
- v0.5 路线后端测试：`67 passed, 0 failed`
- v0.6 挑战后端测试：`65 passed, 0 failed`
- v0.7 牌组/v5 存档后端测试：`43 passed, 0 failed`

v0.3.0 新增覆盖：

- 卡牌、敌人、遭遇三类正式内容 schema。
- v0.3.0 精简全局数值 schema，卡牌和敌人定义不再复制进 balance。
- 跨文档内容版本一致性、稳定 ID、卡牌引用、敌人引用和三列位置校验。
- 正式内容目录到 BattleEngine 的内容/数值/随机端口装配。
- 固定种子新游戏、启动手牌与敌人实例化。
- 战斗结束后单次检查点保存、重复保存防护、启动摘要读取、无存档与损坏主档状态。

v0.4.0 新增覆盖：

- progression、balance 和带成长状态的存档 schema。
- 身份、祈愿池、奖励、升级定义与基础卡牌的跨文档引用。
- v0.4 全局参数映射和固定 `gacha.draw` 随机流。
- 真实短循环：身份 -> 战斗 -> 奖励 -> 升级 -> 祈愿 -> 保存 -> 继续。
- 下一场战斗使用已拥有牌组和升级后的内容端口。
- v1 存档到 v2 的显式迁移和迁移后的新版本启动。

v0.7.0 新增覆盖：

- 当前占卜家卡池和牌组内容 schema。
- 三套八卡预设、稳定卡牌引用和非法预设拒绝。
- 当前牌组、确认状态和预设保存到 v5 存档。
- 实际路线战斗读取当前确认牌组。
- 第一挑战完成条件与第二挑战依赖图。
- v1/v2/v3/v4 -> v5 连续迁移入口。
