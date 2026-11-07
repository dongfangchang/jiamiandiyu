# 基础设施测试

运行：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/infrastructure/test_runner.gd
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

测试使用 `user://mask_whispers_infrastructure_tests`，运行前后自动清理。

当前基线：`104 passed, 0 failed`，退出码为 `0`。

v0.3.0 新增覆盖：

- 卡牌、敌人、遭遇三类正式内容 schema。
- v0.3.0 精简全局数值 schema，卡牌和敌人定义不再复制进 balance。
- 跨文档内容版本一致性、稳定 ID、卡牌引用、敌人引用和三列位置校验。
- 正式内容目录到 BattleEngine 的内容/数值/随机端口装配。
- 固定种子新游戏、启动手牌与敌人实例化。
- 战斗结束后单次检查点保存、重复保存防护、启动摘要读取、无存档与损坏主档状态。
