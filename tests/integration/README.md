# 应用集成测试

运行：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/integration/app_flow_runner.tscn
```

测试使用隔离的 `user://mask_whispers_app_integration_v05` 存档目录，覆盖：

- 启动页和空检查点状态。
- 正式内容创建真实 `RouteSession`。
- 新游戏进入身份选择，选择身份后进入五节点路线地图。
- 首战、镜中猎犬精英战、休息与镜厅男爵首领战均通过真实 UI 命令运行。
- 节点间奖励、单抽扣费、碎片升级和返回路线。
- 休息节点检查点可以返回标题后准确恢复。
- 三步“被篡改的讣告”支持取消、错误污染和正确完成。
- 晋升后保存序列 8「小丑」，继续游戏仍恢复到路线结算。
- 损坏检查点保持原文件、禁用继续并显示错误。

当前基线：`APP_V05_INTEGRATION_OK checks=73`，退出码为 `0`。
