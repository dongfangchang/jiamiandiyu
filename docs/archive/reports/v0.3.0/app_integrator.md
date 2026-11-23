# v0.3.0 / 应用集成工作记录

## 状态

- 版本：v0.3.0
- 角色：应用集成开发
- 任务：连接启动页、真实战斗会话、战斗页、结果页和检查点
- 状态：完成（应用集成与隔离存档端到端测试通过）
- 最后更新：2026-11-08

## 本版本目标

把已验证的 UI、玩法和本地数据层装配成一条真实可运行链路，不复制领域规则。

## 依赖

- UI 页面与信号：`scenes/ui/**`、`src/ui/**`
- 应用与检查点：`src/app/**`、`src/infrastructure/**`
- 冻结玩法接口：`Snapshot`、`Command`、`Playability`
- 正式内容：`data/cards`、`data/enemies`、`data/encounters`、`data/balance`

## 实施内容

- 新增 `src/app/app_controller.gd` 与 `src/app/app_root.tscn`。
- 启动页读取检查点摘要，并连接新游戏、继续和退出意图。
- 新游戏通过 `AppBootstrap.start_new_game` 创建正式 `GameSession`。
- 战斗页注入正式遭遇、卡牌名、敌人名和 `query_card_play`。
- 战斗命令转发到 `GameSession.submit`，结果回送战斗页。
- 战斗结束路由到结果页，并读取 `last_checkpoint_result`。
- 返回标题刷新检查点摘要；继续会用检查点种子和遭遇重新开始。
- 新增 `tests/integration/app_flow_runner` 覆盖端到端路由和保存。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 检查点不保存战斗中间状态 | 伪装成中途恢复；继续同一遭遇；只显示摘要 | 继续同一遭遇 | 与 v0.3.0 明确检查点语义一致 |
| UI 显示名不在快照中 | UI 读内容文件；应用注入名称；硬编码 | 应用从内容目录注入 | 保持 UI 与文件、规则隔离 |
| 战斗结束信号发生在命令回调中 | 立即释放战斗页；延迟切换 | `call_deferred` 路由结果页 | 避免在 UI 自身信号回调中释放当前页面 |

## 验证

- `APP_INTEGRATION_OK checks=30`，退出码 `0`。
- 覆盖启动路由、空检查点禁用继续、正式内容创建真实 `GameSession`、新游戏路由到战斗、正式遭遇快照注入、战斗结束路由到结果页、战后检查点保存、返回标题读取摘要、继续同一遭遇、损坏检查点提示且不自动覆盖。
- `src/app/app_root.tscn` 可独立在 Godot 4.7.2 headless 中加载。
- 测试存档使用隔离目录 `user://mask_whispers_app_integration`，运行前后清理。

## 风险

- 主场景仍需要主协调者写入 `project.godot`。
- 继续入口从战后检查点重新开始同一遭遇，不恢复战斗中间状态。
- 正式场景的视觉验收仍由 UI 与美术审稿负责，本报告不替代视觉验收。

主场景设置要求：主协调者在 `project.godot` 的 `[application]` 段添加：

```ini
run/main_scene="res://src/app/app_root.tscn"
```

## 跨角色请求

无新增接口请求。

## 下一步入口

运行集成测试，修复实际路由或存档问题，然后把 `src/app/app_root.tscn` 设为主场景。
