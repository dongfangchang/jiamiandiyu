# 应用集成测试

运行：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/integration/app_flow_runner.tscn
```

测试使用隔离的 `user://mask_whispers_app_integration` 存档目录，覆盖：

- 启动页和空检查点状态。
- 正式内容创建真实 `GameSession`。
- 启动页到战斗页路由。
- 战斗命令到结果页路由。
- 战后检查点保存。
- 返回标题、读取检查点摘要并继续同一场遭遇。
