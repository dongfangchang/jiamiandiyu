# v0.32.0 主协调者报告

版本：v0.32.0  
角色：主协调者 / QA  
任务：基线专项、抽样复跑、试玩检查表、集成门  
状态：执行中

## 当前任务

1. 复跑 v0.31 价值审计与原著战斗 UI 专项。  
2. 复跑难度抽样，作为调参前基线。  
3. 提供真人试玩检查表供填写。

## 试玩检查表（待填写）

| 项 | 结果 | 笔记 |
|---|---|---|
| 新游戏仅廷根第一阶段可开 | 待测 | |
| 牌组：序列不足卡显示锁定中文原因（BUG-0022） | 待测 | |
| 抽卡→返回→重进无旧结果（BUG-0023） | 待测 | |
| 牌组/战斗中文无方框（BUG-0024） | 待测 | |
| 战斗节点 A（密修会或绑匪） | 待测 | |
| 战斗节点 B（提利尔/燕尾服小丑） | 待测 | |
| 战斗节点 C（恶灵或拉姆德/老尼尔） | 待测 | |
| 仪式页可读（出处 + 三步进度） | 待测 | |
| 至少一次原著联动触发可见 | 待测 | |
| 首领阶段条/下一阶段提示可读 | 待测 | |
| 1600×900 操作可达 | 待测 | |
| 1100×700 操作可达（可滚动） | 待测 | |
| 主观难度：过松 / 合适 / 过难 | 待测 | |

## 验证（2026-11-10 基线）

命令（项目根，Godot 4.7.2 headless）：

```text
./.tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/simulation/v031_card_value_audit_runner.tscn
→ V031_CARD_VALUE_AUDIT_OK checks=145  exit=0

./.tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/ui/v031_canon_battle_runner.tscn
→ V031_CANON_BATTLE_OK checks=114  exit=0

./.tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . res://tools/simulation/v031_canon_sampling_runner.tscn
→ V031_CANON_SAMPLING_DONE  exit=0
```

抽样摘要（4 预设 × 8 遭遇 × 60，贪心）：

- 绝大多数格子胜率 100%；仅 `mirror_baron`（ward 91% / oracle 95%）、`mirror_pursuit`（echo 95%）、`broken_baron`（echo 96%）略低。
- 胜场剩余 HP 普遍 45–54（开局 54），说明贪心路径压力不足。
- 联动：`oracle`/`burst` 有触发；`ward`/`echo` 基本 0。

日志写 `user://logs` 在沙箱下有告警，不影响专项退出码。

## 风险

- 全量 QA 脚本目前以 PowerShell 为主；macOS 按场景逐个 headless 跑专项。
- 贪心胜率不能直接等同真人难度，但“胜后满血”是明确过松信号。

## 调参后验证（同日）

- 用户授权方案 2；数值已改精英/首领并二次回调。
- 复跑：`V031_CARD_VALUE_AUDIT_OK`、`V031_CANON_BATTLE_OK`、抽样完成。
- 关键首领：老尼尔 76–98%；梅高欧丝 53–100%（echo 最低）；胜后生命较调前下降。
- 详情见 `numerical_designer.md`。

## 下一步入口

难度收口完成；随 v0.31 基线一并提交并推送远程。真人试玩表仍可补，不阻断本轮推送。
