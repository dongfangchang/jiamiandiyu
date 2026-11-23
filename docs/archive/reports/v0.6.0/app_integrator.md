# v0.6.0 / 应用集成工作记录

## 状态

- 版本：`v0.6.0`
- 角色：应用集成
- 任务：挑战入口、路由、完整挑战、保存恢复与独立构建接线
- 状态：完成
- 最后更新：2026-11-08

## 修改文件

- `src/app/app_controller.gd`
- `src/app/bootstrap.gd`
- `tests/integration/app_flow_runner.gd`
- `tests/integration/README.md`
- `export_presets.cfg`
- `build-windows.ps1`
- `project.godot`
- `README.md`
- `play.cmd`

## 已接入

- 启动页挑战入口由检查点摘要中的序列和 `challenge_available` 驱动。
- `ChallengeSession` 与普通 `RouteSession` 共用现有启动、身份 hub、战斗、奖励、祈愿、升级、休息和仪式页面。
- 挑战修饰选择与开始通过真实 `ChallengeCommand` 提交，UI 不计算解锁或修饰效果。
- 挑战战斗继续消费真实 `BattleSnapshot`、`BattleCommand` 和 `QueryCardPlay`。
- 挑战完成后使用既有 `ProgressionEngine.apply_reward_bundle()` 入账，重复挑战可再次领取，同一完成检查点不重复入账。
- 挑战成功、失败、保存状态和局外收藏保留进入 `ChallengeResultScreen`。
- 再次挑战创建新的挑战状态，不恢复已完成挑战。
- 继续游戏根据 `challenge_phase` 恢复挑战选择、路线节点、休息、仪式或挑战结算；不恢复战斗中间状态。
- 启动摘要补全 `challenge_available` 和安全原因文案。
- 挑战奖励后若挑战已因污染失败，会直接进入挑战结算，不错误停留在路线地图。

## 独立构建

- Godot `4.7.2.stable` 官方导出模板已安装并通过 SHA-512 校验。
- `build-windows.ps1` 通过独立进程运行 Godot 并检查真实退出码。
- `export_presets.cfg` 排除测试、工具、文档、美术源和 `.tools`，嵌入 PCK。
- 最终独立构建 `build/windows/MaskWhispers.exe` 已包含挑战主链、v4 存档和挑战 UI。
- 最终构建已复制到项目目录外启动验证，退出码为 `0`。

## 验证

```text
APP_V06_INTEGRATION_OK checks=146
APP_ROOT_EXIT=0
```

覆盖首次晋升路线、挑战解锁、修饰选择、完整挑战、奖励入账、挑战成功/失败结算、保存继续、再次挑战、损坏检查点与独立主场景启动。

## 困难与解决

| 困难 | 解决方案 |
|---|---|
| 挑战与普通路线使用不同 Session 类型 | AppController 按 Session 脚本类型分流，复用公共战斗和成长接口 |
| 挑战失败可能发生在战后奖励之后 | 领奖完成统一调用 `_show_current_state()`，由领域快照决定结果页 |
| 已完成挑战会被再次启动恢复 | 启动新挑战使用 `start_fresh_challenge`，继续游戏才恢复检查点 |
| Godot GUI 进程直接调用无法可靠取得退出码 | 构建和测试使用 `Start-Process -Wait -PassThru` 捕获真实退出码 |
| 导出目录可能带入开发文件 | 预设排除 `tests/tools/docs/art/.tools` 和 Markdown/启动脚本 |

## 风险

- 挑战正常策略完成率仍偏高，玩法修饰需要后续继续加强内容压力。
- 尚未完成真实人工计时与人工鼠标操作反馈；当前由完整自动集成和实机截图覆盖。
- 导出文件尚未包含版本资源签名或安装器，符合当前个人本地试玩范围。

## 下一步入口

1. v0.6 已关闭，最终构建与项目外启动均已通过。
2. 后续卡组构筑与第二挑战进入 `v0.7.0`。
3. 用户真实试玩发现问题时进入补丁版本。
