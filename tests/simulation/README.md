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
