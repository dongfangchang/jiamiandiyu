# 数值模拟测试

先运行真实战斗采样：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/battle_sampling_runner.tscn
```

再运行合同检查：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/simulation/balance_contract_runner.tscn
```

采样器直接读取正式 `data/cards`、`data/enemies`、`data/encounters` 和 `data/balance/v0.3.0/balance.json`，不会复制卡牌或敌人定义。

## v0.4.0 短循环经济

先生成经济与升级战斗采样：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/economy_sampling_runner.tscn
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/upgrade_battle_sampling_runner.tscn
```

再运行 v0.4 合同检查：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/simulation/v04_economy_contract_runner.tscn
```

v0.4 经济模型验证身份修正、二选一奖励、三抽保底、重复卡碎片和首次升级。升级战斗采样使用真实 `BattleEngine`；升级规则是等待玩法层确认的投影模型，不复制到生产内容。

当前结果：

```text
V04_ECONOMY_TESTS_OK checks=54
ECONOMY_SHA256=33A3C8FE163559DB03F0CB658FFE3EACE5C89C7CAC58539036AF7E7CE9793841
BATTLE_SHA256=841EC2C98A81DCD8D841D577CD4CAD26BD608DEE4470588660C1CAE83B6F94B8
```

## v0.5.0 完整短路线

生成固定种子路线采样：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/route_sampling_runner.tscn
```

再运行路线合同检查：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/simulation/v05_route_contract_runner.tscn
```

路线采样直接驱动 `RouteEngine`、`BattleEngine` 和 `ProgressionEngine`，覆盖首战、精英战、休息、首领战和三步晋升仪式。三种策略分别搭配记者与医生，每个组合运行 200 条路线。

当前基线：

```text
V05_ROUTE_TESTS_OK checks=47
ROUTE_SAMPLING_SHA256=8261a1c32baabe4ef316d5362e9e99edb3f5d8b8994215e6759f8bc2c8febdf4
```

规划时间模型中值为 16.45—21.81 分钟，保守—宽松区间为 13.94—24.90 分钟，符合 ADR-0008 的 15—30 分钟目标。两种休息在当前收益评分下均被策略选择采用；不通过虚增敌人生命或降低伤害延长路线。

## v0.6.0 可重复挑战

生成固定种子挑战采样：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/challenge_sampling_runner.tscn
```

再运行挑战合同检查：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/simulation/v06_challenge_contract_runner.tscn
```

挑战采样直接驱动 `ChallengeEngine`、`RouteEngine`、`BattleEngine` 和 `ProgressionEngine`，覆盖三种修饰、记者/医生和三套策略（激进、均衡、忽视污染）。每个组合 100 条挑战，共 1800 条有效路线。

当前基线：

```text
V06_CHALLENGE_TESTS_OK checks=48
CHALLENGE_SAMPLING_SHA256=69C3627CD6CF01208DD8DDF66638B219CAD872BB38D3995DEDA5C876E58226E0
```

采样用于验证修饰决策压力：`tainted_margins` 在忽视污染、始终包扎的策略下 200/200 失败，正确选择封锁回声仍可完成；失败样本保留局外卡牌收藏和等级。全局数值位于 `data/balance/v0.6.0/balance.json`；挑战修饰和奖励仍只在 `data/challenges/v0.6.0/challenges.json` 定义。

## v0.7.0 牌组构筑与第二挑战

生成真实牌组/身份/路线/挑战采样：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tools/simulation/deck_sampling_runner.tscn
```

再运行合同检查：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/simulation/v07_deck_contract_runner.tscn
```

采样器直接驱动 `DeckEngine + ChallengeEngine + RouteEngine + BattleEngine + ProgressionEngine`。三套正式牌组、记者/医生、首次路线以及两个挑战的全部挑战修饰组成 42 个案例，每个案例 30 条固定种子运行。采样假设“后期收藏已拥有当前全部卡牌”，用于比较构筑，不用于计算首次获取速度。
