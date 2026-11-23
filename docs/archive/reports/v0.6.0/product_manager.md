# v0.6.0 / 产品经理

## 状态

- 版本：`v0.6.0`
- 角色：产品经理
- 任务：离线构建与可重复挑战的范围、依赖和验收
- 状态：已关闭
- 最后更新：2026-11-08
- 下一入口：`docs/versions/v0.7.0.md`

## 验收结论

`v0.6.0` 的离线构建、挑战解锁、三种修饰、挑战奖励、v4 存档、UI 和 app 主链均已接通。最终全量回归与独立构建验收通过。

默认挑战为 `challenge.v060.mirror_echoes`，要求占卜家序列 8。三种修饰均已进入真实挑战：

- `modifier.rushed_reflection`：敌人阶段提前。
- `modifier.tainted_margins`：初始污染 +4、被注视 +1，每场战斗胜利后污染 +2；持续包扎会在首领战后失败，选择封锁回声可以完成。
- `modifier.fractured_deck`：移除所有纸符护持，完成奖励增加占卜券。

挑战完成奖励通过 `ProgressionEngine.apply_reward_bundle()` 入账；重复完成可再次领取，同一完成检查点不会重复发奖。挑战失败保留局外收藏、卡牌等级、预设和已确认奖励。

## 最终验证

```text
Infrastructure       150
Route backend         67
Challenge backend     65
Gameplay             131
Progression          103
Route                 98
Challenge             89
UI                    33
Progression UI        41
Route UI              62
Challenge UI          40
Integration          146
Simulation contract   33
Economy               54
Route contract        47
Challenge contract    48
Main scene           exit 0
```

固定种子挑战采样共 1800 条：

- `rushed_reflection`：100% 完成，平均 12.97 回合。
- `tainted_margins`：66.67% 完成；200 条忽视污染并始终包扎的样本全部失败，失败后局外收藏保持完整。
- `fractured_deck`：100% 完成，平均 9.78 回合。

## 独立构建

- Godot 4.7.2 官方导出模板已安装并通过 SHA-512 校验。
- 最终构建：`build\windows\MaskWhispers.exe`
- 大小：`121,196,864` 字节
- SHA-256：`95EEABACF4EAF1AD70A048BA2416A07328100BD33172C541C81E1FF9FEE4DB3E`
- 已复制到项目目录外，以 headless 模式启动并正常退出，退出码 `0`。
- 导出预设排除 `tests/`、`tools/`、`docs/`、`art/`、`.tools/` 和开发启动脚本。

## UI 与美术

美术与 UI 保持独立角色。美术交付挑战背景、修饰徽记、印章和模式标识；UI 在实际挑战选择、路线和结算界面完成审稿，结论为原型范围通过，无退回重做项。

## 已知风险

- `rushed_reflection` 与 `fractured_deck` 仍由正常策略 100% 完成，定位为快节奏和构筑展示修饰。
- 挑战复用首次晋升路线，因此仍包含仪式；纯战斗挑战如需拆分，进入后续版本。
- 人工秒表试玩尚未执行；当前 15—30 分钟来自固定种子规划估算。用户试玩未发现问题则保留该基线。
- 挑战奖励已在内存入账但落盘失败时，重启从最后成功检查点恢复，不重复持久化奖励。

## 下一步

进入 `v0.7.0`：卡组构筑与第二挑战。先冻结牌组命令/快照、卡组合法性、8 张新增卡、第二挑战解锁和 v5 存档，再并行实现 UI、美术、后端和数值。
