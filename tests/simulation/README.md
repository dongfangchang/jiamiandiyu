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
