# v0.6.0 挑战内容

`challenges.json` 定义序列 8 后解锁的可重复挑战。挑战只引用既有路线、遭遇、卡牌和奖励 ID，不复制这些事实源。

## 当前挑战

- `challenge.v060.mirror_echoes`：复用 `route.v050.first_case`。
- 解锁条件：占卜家序列已晋升到 8。
- 完成奖励使用现有奖励 ID：
  - `reward.divination_tickets`
  - `reward.ink_dart_fragments`

## 修饰

| ID | 决策压力 |
|---|---|
| `modifier.rushed_reflection` | 所有敌人阶段提前 2 回合，催促更快结束战斗 |
| `modifier.tainted_margins` | 路线初始污染 +4、被注视 +1；每场战斗胜利后再增加 2 点污染，必须用封锁回声控制失控 |
| `modifier.fractured_deck` | 移除所有纸符护持，但额外获得 1 张占卜券 |

## 领域接入

- 挑战开始前由 `ChallengeEngine.build_battle_deck()` 应用牌组限制。
- 战斗初始化前由 `ChallengeEngine.prepare_enemy_configs()` 应用阶段修饰。
- 只有挑战完成时，`ChallengeCompleted` 事件才暴露奖励。
- 挑战失败不修改外部收藏、卡牌等级或已确认奖励。
- 挑战只做节点级恢复，不支持恢复战斗中间状态。
- 污染达到上限时，当前战斗节点判定为路线失败；已确认的局外成长保持不变。

## Schema 变更请求

`modifier.tainted_margins` 使用 `battle_corruption_delta: 2`，需要本地数据层在
`data/schema/v0.6.0/challenges.schema.json` 的修饰 `effects` 中增加：

```json
"battle_corruption_delta": {
  "type": "integer",
  "minimum": 0,
  "maximum": 10
}
```

该字段只增加挑战战斗胜利后的污染，不改变卡牌效果或全局平衡参数。
