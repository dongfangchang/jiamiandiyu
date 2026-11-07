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
