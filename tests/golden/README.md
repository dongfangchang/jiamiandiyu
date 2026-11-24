# 黄金回放（ROADMAP R0-04）

`golden_replay_runner` 用**固定种子**（`20261124`）和**固定命令策略**，走与游戏"新游戏"相同的组合入口 `AppBootstrap.start_route_v07`，跑完第一卷 `route.v028.first_stage`，并在每个阶段对快照取摘要。

## 覆盖的阶段

| 阶段 | 内容 |
|---|---|
| `01_start` | 新档开局 + 选择身份 `identity.reporter` |
| `02`–`05`、`07`、`08` | 每个战斗节点：自动打牌（每步打出第一张可打的牌，目标为第一个存活敌人；没有可打的牌就结束回合），胜利后领取第一个奖励 |
| `06_rest` | 休整节点：选第一个休整选项 |
| `09_ascension` | 晋升仪式：按仪式内容的正确答案逐步提交，晋升到序列 8 |
| `10_gacha` | 单抽一次 |
| `11_checkpoint` | 读回存档槽，对存档信封取摘要（保证存档格式不悄悄变化） |

每个阶段的快照包括：路线、成长、牌组、序列状态，以及本阶段的命令日志（命令、是否接受、原因码、事件类型）和战斗终局快照。

规范化规则：字典键递归排序；去掉随时间或机器变化的字段（`created_at`、`*_at`、`*_ms`、`*_unix`、`*_path`、`path`、`checksum`）；整数值的浮点数统一成整数。然后 `JSON.stringify` 再取 `sha256`。

存档写在独立目录 `user://golden_replay`、槽位 `golden_replay`，不会覆盖玩家存档（参见 BUG-0012）；每次运行前后都会清空这个目录。

runner 在同一进程内会连跑两次，先校验两次哈希一致（确定性），再和 `expected.json` 比较。

## 规则

1. **纯重构（R1–R4）必须保持全部哈希不变。** 哈希变了就说明行为变了，先查原因，不要直接更新。
2. **有意的规则或数值变化**才允许更新哈希，而且必须在当次版本文档里写明：哪个阶段变了、为什么变。
3. 失败时 runner 会列出变化的阶段、期望摘要和实际摘要，并把实际的规范化 JSON 写到 `user://golden_replay_actual/<阶段>.json`（日志里会打印绝对路径），方便对比。

## 运行与更新

```bash
# 校验（也包含在 tools/run_tests.sh 里）
GODOT=... tools/run_tests.sh golden

# 有意的规则变化后，重写 expected.json
"$GODOT" --headless --path . res://tests/golden/golden_replay_runner.tscn -- --update
```

更新后要连跑两次确认通过，再把 `expected.json` 和规则改动放在同一次提交里。
