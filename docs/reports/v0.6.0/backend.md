# v0.6.0 / 本地数据层开发工作记录

## 状态

- 版本：`v0.6.0`
- 角色：本地数据层开发
- 任务：挑战 schema、内容适配、v4 存档与挑战会话接线
- 状态：完成（挑战数据层、v4 存档、奖励入账与恢复回归）
- 最后更新：2026-11-08
- 下一步入口：v0.6 已关闭；进入 v0.7 牌组与第二挑战数据层

## 本版本目标

让挑战内容经过统一 schema 与端口进入离线游戏，并在不复制路线、战斗和成长规则的前提下保存挑战修饰、节点边界和局外进度。

## 依赖

- `AGENTS.md`、`CURRENT_VERSION.md`、`PROJECT_CHARTER.md`、`ARCHITECTURE_CONTRACT.md`
- `docs/versions/v0.6.0.md`
- `docs/reports/v0.6.0/gameplay.md`
- `data/challenges/v0.6.0/challenges.json`
- `ChallengeEngine`、`RouteEngine`、`BattleEngine`、`ProgressionEngine`

## 已完成

- 新增 `data/schema/v0.6.0/challenges.schema.json`。
- 新增 `data/schema/v0.6.0/save.schema.json`，存档版本升级到 4，并保留挑战检查点段。
- 新增 `ChallengeContentAdapter`：
  - 校验挑战稳定 ID、默认挑战和至少三个修饰。
  - 校验 `route_id`、完成奖励 ID、移除卡牌与正式路线的引用。
  - 校验修饰 effect 键、整数参数、重复 ID 和非负奖励。
  - 透传 `battle_corruption_delta`；字段可选，缺省由领域按 0 处理。
- 扩展 `SchemaValidator`，支持对象型 `additionalProperties`，覆盖奖励包这类动态键值映射。
- 新增 `ChallengeSession`：
  - 使用 `ChallengeEngine` 的挑战状态机。
  - 挑战战斗依次执行 `owned deck -> challenge deck transform -> enemy phase transform`。
  - 在挑战开始时、节点命令后、战斗结算后和成长提交后保存 v4 检查点。
  - 不在战斗刚开始时写入不可恢复的战斗中间状态。
- 新增 `AppBootstrap.start_challenge()`；从最近路线检查点恢复成长与序列状态，并按挑战状态恢复修饰和节点边界。
- 普通路线也统一写入 v4 存档，避免挑战与主线在同一存档槽内版本来回降级。
- `inspect_route_checkpoint()` 摘要新增挑战 ID、阶段、修饰、结果和奖励是否已入账。
- `SaveMigrations.create_v06_service()` 支持 v1 -> v2 -> v3 -> v4 显式迁移；v3 备份在覆盖保存时通过迁移链读取验证，不会因旧版本备份被误判为损坏。
- 新增 `tests/infrastructure/challenge_backend_runner.gd/.tscn`。
- `ChallengeSession` 已直接调用正式 `ProgressionEngine.apply_reward_bundle()`，删除 `has_method()` 临时兼容分支。
- 挑战完成奖励按完整奖励包校验后一次入账；重复完成、重复恢复调用不会重复增加货币或碎片。
- 完成态检查点若尚未记录奖励已入账，重启时补发一次并立即保存；下一次重启不会再次补发。
- 保存失败会保留明确的 `last_checkpoint_result` 失败状态，不会向调用方伪报检查点成功。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 挑战状态与普通路线共用存档槽 | 新开第二套存档；在挑战槽复制路线；升级统一槽 schema | 普通路线和挑战统一写入 v4，`challenge.phase=inactive` 表示普通路线 | 单存档槽、继续语义清晰，不产生两份成长事实源 |
| 挑战完成后用户立即退出 | 依赖事件即时入账；事件后立即落盘；完成态恢复时补发 | 记录 `reward_applied`，完成态恢复时允许补发 | 避免崩溃或反馈失败导致奖励永久丢失 |
| 旧 v3 档作为备份 | 跳过旧档校验；拒绝覆盖；按原版本迁移验证 | `AtomicSaveService` 通过迁移链验证备份 | 保留旧档安全并允许正常升级 |
| schema 动态奖励键 | 只校验顶层；为每个 reward 写死属性；支持对象型 additionalProperties | 扩展通用 schema 校验器 | schema 语义正确，也适用于未来动态奖励包 |
| 挑战完成奖励 | app 改私有状态；复制奖励表；玩法公开批量入账 | 使用玩法已提供的 `ProgressionEngine.apply_reward_bundle(reward)` | 保持奖励规则单一来源，并删除临时兼容路径 |
| 奖励入账成功但落盘失败 | 伪报保存成功；回滚已入账奖励；保留失败状态并等待恢复 | 保留明确的落盘失败结果，完成态恢复按 `reward_applied` 补发一次 | 不丢失奖励，也不重复持久化入账 |
| 挑战污染压力字段与 schema 不一致 | 放宽 schema 任意字段；在适配器写死规则；显式增加整数效果 | schema 限定 0—10，适配器只校验并透传 | 保持规则在玩法层，避免静默接受坏数据 |

## 验证

```text
CHALLENGE_BACKEND_TESTS_OK checks=65
PASS infrastructure tests: 150
CHALLENGE_TESTS_OK checks=89
PROGRESSION_TESTS_OK checks=103
ROUTE_TESTS_OK checks=98
APP_V05_INTEGRATION_OK checks=73
main scene --quit-after 5: exit 0
```

挑战后端覆盖：

- 正式 challenge schema 和三个修饰。
- `battle_corruption_delta` 正式值透传、非法类型、越界和缺省兼容。
- 缺失路线、重复修饰、未知奖励、移除路线外卡牌的拒绝。
- 序列 9 锁定与序列 8 解锁。
- `fractured_deck` 在真实挑战战斗牌组中移除纸符护持。
- 挑战节点边界检查点和重启恢复。
- v3 存档迁移到 v4、v4 覆盖 v3 时的备份恢复。
- 挑战完成奖励实际增加占卜券和卡牌碎片。
- 重复完成和重复恢复不重复入账。
- 完成态检查点缺少 `reward_applied` 时只补发一次。
- 非法存档槽导致落盘失败时，不伪报检查点成功。
- 挑战奖励恢复用例使用可完成的修饰，污染失败压力由独立玩法测试覆盖。

## 风险与未决问题

- `AppController` 已接入挑战页面、挑战 Session、结果页和保存恢复。
- 挑战修复仍复用完整五节点路线，因此一次挑战包含再次晋升仪式；若产品希望挑战只战斗，需要后续版本明确拆出挑战路线。
- 奖励在内存入账后若落盘失败，当前运行时保持已领取状态，重启只能从最后成功检查点恢复；因此不会重复持久化，但用户必须重新完成该检查点之后的挑战进度。

## 跨角色请求

```text
[REQUEST]
从：本地数据层开发
给：产品经理
版本：v0.6.0
内容：登记 S2 缺陷：AtomicSaveService 在升级到 v4 后，
      第一次覆盖 v3 主档时，旧逻辑用 v4 schema 校验 v3 备份会误报失败。
原因：缺陷已通过迁移链验证备份前向修复，但当前角色无权编辑 docs/bugs/**。
期望接口：创建 BUG 文档并引用 challenge_backend_runner 的备份回归。
截止检查点：v0.6.0 关闭前
[END REQUEST]
```

## 修改文件

- `data/schema/v0.6.0/**`
- `src/infrastructure/challenge_content_adapter.gd`
- `src/infrastructure/schema_validator.gd`
- `src/infrastructure/save_migrations.gd`
- `src/infrastructure/atomic_save_service.gd`
- `src/app/challenge_session.gd`
- `src/app/checkpoint_envelope_builder.gd`
- `src/app/game_session.gd`
- `src/app/route_session.gd`
- `src/app/bootstrap.gd`
- `tests/infrastructure/challenge_backend_runner.gd`
- `tests/infrastructure/challenge_backend_runner.tscn`
- `tests/infrastructure/README.md`

## 下一步入口

数据层挑战奖励链路、挑战 UI/app 路由、全量回归和独立 Windows 构建均已完成。最终应用集成为 146 项，Windows 独立构建在项目目录外启动退出码为 `0`。
