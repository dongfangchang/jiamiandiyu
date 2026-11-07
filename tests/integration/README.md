# 应用集成测试

运行：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/integration/app_flow_runner.tscn
```

测试使用隔离的 `user://mask_whispers_app_integration_v04` 存档目录，覆盖：

- 启动页和空检查点状态。
- 正式内容创建真实 `CampaignSession`。
- 新游戏进入身份选择，选择身份后进入 hub。
- hub 进入真实逐张出牌战斗。
- 战斗胜利进入二选一奖励，奖励写入成长状态。
- 单抽扣费并从页面显示真实结果。
- 残页升级墨刺，升级等级进入下一场战斗。
- 返回标题后读取身份、收藏与升级检查点并继续 hub。
- 损坏检查点保持原文件、禁用继续并显示错误。

当前基线：`APP_V04_INTEGRATION_OK checks=39`，退出码为 `0`。
