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

当前基线：`59 passed, 0 failed`，退出码为 `0`。
