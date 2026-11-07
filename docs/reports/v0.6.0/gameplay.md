# v0.6.0 / 玩法设计工作记录

## 状态

- 版本：`v0.6.0`
- 角色：玩法设计
- 任务：序列 8 后可重复挑战与三种数据驱动修饰
- 状态：完成；数据层 schema、app 接线、UI 审核和最终构建均已完成
- 最后更新：2026-11-08
- 下一步入口：v0.7 卡组构筑与第二挑战

## 本版本目标

让玩家在完成首次序列晋升后，使用已有身份、收藏、卡牌等级和祈愿资源继续挑战同一短路线。挑战通过数据驱动修饰改变决策，不用提高敌人生命值假装难度。

## 依赖

- `AGENTS.md`、`CURRENT_VERSION.md`、`PROJECT_CHARTER.md`、`ARCHITECTURE_CONTRACT.md`
- `docs/versions/v0.6.0.md`、ADR-0005/0006/0007/0008/0009
- 既有 `RouteEngine`、`BattleEngine`、`ProgressionEngine`
- v0.5 正式路线、遭遇、敌人和仪式数据

## 已完成

### 领域接口

- `ChallengeCommand`：选择修饰、开始挑战、转发 `RouteCommand`。
- `ChallengeCommandResult`：接受状态、原因码、挑战事件、只读快照和嵌套路线结果。
- `ChallengeSnapshot`：解锁、阶段、修饰、奖励预览、路线/仪式/序列快照和可用命令。
- `ChallengeContentPort`：读取挑战和修饰定义。
- `ChallengeEngine`：解锁门槛、修饰选择、挑战生命周期和路线复用。
- `ChallengeRouteContentPort`：只调整路线的初始运行状态，不复制路线规则。
- `ProgressionEngine.apply_reward_bundle(reward_amounts)`：全量校验后原子应用挑战奖励，复用既有 `reward.*` 定义与资源事实源。

### 三种修饰

- `modifier.rushed_reflection`：敌人阶段提前 2 回合，首领阶段从第 3/6 回合变为第 1/4 回合。
- `modifier.tainted_margins`：初始污染 +4、被注视 +1，每场战斗胜利后污染 +2。持续使用包扎会在首领战后达到污染上限；使用封锁回声才能安全完成晋升。
- `modifier.fractured_deck`：移除所有 `card.skill.paper_guard`，完成奖励额外增加 1 张占卜券。

### 领域能力

- 未完成序列 8 晋升时保持锁定；锁定状态拒绝修饰选择。
- 必须选择修饰后才能开始挑战。
- `build_battle_deck()` 统一应用牌组限制。
- `prepare_enemy_configs()` 统一应用阶段时点修饰，不修改源内容。
- 完整挑战复用五节点路线和既有战斗、休息、仪式命令。
- 挑战完成后发出一次 `ChallengeCompleted`，暴露基于既有奖励 ID 的完成奖励。
- 挑战失败只进入失败状态，不修改外部收藏、卡牌等级或已确认资源。
- 战斗胜利后的污染达到上限时，节点判定失败并停止后续路线推进。
- 导出/恢复挑战修饰、阶段和内部路线状态；恢复点仍是路线节点边界。

### 正式内容

- `data/challenges/v0.6.0/challenges.json`
- `data/challenges/v0.6.0/README.md`

内容只引用 `route.v050.first_case`、既有卡牌和既有奖励 ID。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 挑战可能复制五节点路线 | 新建 ChallengeRouteEngine；包装并复用 RouteEngine | 复用 `RouteEngine`，只包装路线内容 | 避免两套节点和仪式规则 |
| 修饰可能只是改数值 | 增加敌人生命；增加阶段/牌组/初始风险修饰 | 使用阶段提前、初始风险、牌组限制 | 直接改变决策与构筑 |
| 卡牌 JSON 整数在 Godot 中解析为浮点数 | 修改 schema 接收任意数；在 adapter 转换；领域接受有限整数值 | 领域使用有限整数校验 | 保持数据边界稳健，不放松任意浮点 |
| 完成奖励可能创建第二套奖励定义 | 在挑战内写完整奖励；引用既有奖励 ID 和金额 | 使用 `reward.divination_tickets`、`reward.ink_dart_fragments` | 奖励事实源仍属于成长内容 |
| 挑战失败可能误删局外收藏 | 挑战直接操作 ProgressionEngine；Challenge 只导出结果 | 挑战域不持有局外收藏，仅产生事件/快照 | 失败天然保留局外成长 |

## 验证

Godot 4.7.2 headless：

```text
CHALLENGE_TESTS_OK checks=89
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=103
ROUTE_TESTS_OK checks=98
```

挑战测试覆盖：

- 正式内容稳定 ID、路线引用和三种修饰。
- 完成奖励和移除卡牌引用现有的奖励/遭遇内容。
- 序列 9 未解锁、序列 8 已解锁。
- 未知修饰、未选修饰和错误阶段拒绝。
- 阶段提前修饰不修改源敌人配置。
- 初始污染/被注视修饰真实进入路线状态。
- 每场战斗胜利后的挑战污染压力真实累积。
- 染墨页边在错误休息选择后于首领战触发污染上限失败。
- 同一修饰在正确选择封锁回声后仍能完成晋升仪式。
- 残缺牌组移除所有受限制牌。
- 完整五节点挑战与确定性奖励。
- 战斗失败保持外部收藏不变。
- 挑战状态导出/恢复。
- 相同命令序列得到相同最终快照。
- 挑战奖励包可同时入账占卜券与卡牌碎片。
- 未知奖励、负数额、非整数和空奖励包不会部分修改成长状态。

## 跨角色请求

```text
[REQUEST]
从：玩法设计
给：本地数据层开发 / app
版本：v0.6.0
内容：挑战战斗必须依次使用 progression owned deck、ChallengeEngine.build_battle_deck、ChallengeEngine.prepare_enemy_configs，再初始化 BattleEngine。
原因：修饰在领域层已有实际语义，app 若跳过会显示修饰但不生效。
截止检查点：挑战 app 集成。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：UI 设计
版本：v0.6.0
内容：UI 只使用 ChallengeSnapshot/ChallengeCommand；显示解锁条件、所选修饰、路线快照、奖励预览和失败保留局外成长。不得重新计算阶段提前、牌组限制或奖励。
截止检查点：挑战 UI 美术审稿前。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：本地数据层开发
版本：v0.6.0
内容：在 challenges schema 的 modifier.effects 中允许可选整数
`battle_corruption_delta`，范围 0..10，并由 ChallengeContentAdapter 透传。
原因：`modifier.tainted_margins` 需要每场战斗胜利后累积污染，形成可实际失败的挑战压力；
该值属于挑战内容，不是卡牌金额或全局平衡参数。
期望接口：现有 ChallengeSnapshot/modifier effects 原样暴露，不增加第二套规则。
截止检查点：challenge backend schema 验收与 v0.6 全量回归。
[END REQUEST]
```

## 风险与未决问题

- `data/challenges/**` 已划归玩法设计，正式 schema 与适配器由本地数据层维护。
- `ChallengeCompleted` 暴露的奖励必须通过 `ProgressionEngine.apply_reward_bundle()` 入账；批内原子性由成长的“先全量校验、后统一应用”保证。
- 每次挑战只应入账一次；幂等标记仍由 `ChallengeSession.reward_applied` 和持久检查点负责，成长层保留重复挑战可再次获得奖励的能力。
- 若奖励已在内存入账但检查点写盘失败，重启后的补发窗口依赖存档原子性策略，属于 app/数据层风险。
- `battle_corruption_delta` 尚未加入 v0.6 challenge schema；在数据层完成字段批准前，
  正式 schema 校验会拒绝该修饰，玩法测试可独立通过。
- `prepare_enemy_configs()` 和 `build_battle_deck()` 已在 v0.6 关闭前接入 app 挑战战斗。
- 挑战可重复运行，但没有额外失败惩罚或每日限制，当前符合本地单机范围。
- 真实难度和奖励平衡需要数值角色用 `ChallengeEngine` 采样。

## 下一步入口

1. v0.6 挑战领域、schema、app、UI、数值与独立构建已全部完成。
2. 下一版进入 v0.7 卡组构筑与第二挑战。
3. 继续复用现有战斗、成长与挑战规则，不复制流程。
