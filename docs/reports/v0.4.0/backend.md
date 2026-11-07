# v0.4.0 / 本地数据层与 app 用例

## 状态

- 版本：`v0.4.0`
- 角色：本地数据层开发
- 任务：schema、成长内容装配、v2 存档迁移、短循环用例和战斗接线
- 状态：完成（等待主协调者接 UI 路由）
- 最后更新：2026-11-08
- 下一步入口：应用控制器接入 `CampaignSession` 与四个新 UI 页面

## 本版本目标

在不破坏已关闭 `v0.3.0` 单场战斗的前提下，提供可保存的
“身份 -> 战斗 -> 奖励 -> 祈愿/升级 -> 再战”应用用例。

## 已实现

### Schema

- `data/schema/v0.4.0/progression.schema.json`
- `data/schema/v0.4.0/balance.schema.json`
- `data/schema/v0.4.0/save.schema.json`
- `data/schema/v0.4.0/README.md`

成长文档、全局数值和 v2 存档分别校验。跨文档卡牌引用与身份/祈愿/奖励 ID
由适配器和玩法引擎继续执行运行时校验。

### 内容与平衡适配

- `ProgressionContentAdapter` 读取正式 `progression.json`，卡牌存在性直接查询
  `BattleContentPort`，没有复制卡牌定义。
- `BattleBalanceAdapter` 新增成长、祈愿、升级和奖励参数路径。
- JSON 加载器支持 `schema_version: 2`，以读取 v0.4 平衡文档。
- 祈愿使用独立 `gacha.draw` 随机流；战斗洗牌继续使用 `battle.shuffle`。

### 应用用例

- `AppBootstrap.start_campaign(...)` 启动或恢复 v0.4 短循环。
- `CampaignSession` 提供：
  - 成长只读快照和 `ProgressionCommand` 提交。
  - 身份、奖励、单抽/三连与升级后的自动检查点。
  - 身份选择后开始真实战斗。
  - 下一场战斗使用已拥有牌组过滤。
  - 下一场战斗使用 `UpgradedBattleContentPort`。
  - 身份战斗修正进入真实玩家状态。
  - 胜利/失败后结算成长阶段，再写入一次战后检查点。
- 现有 `AppBootstrap.start_new_game(...)` 保持 v0.3 兼容，没有强制迁移到新流程。

### 存档与迁移

- `SaveMigrations.create_v04_service()` 创建 `save_version: 2` 服务并注册 v1 迁移。
- v1 存档迁移后标记 `migrated_from_v1`；恢复时以当前内容重新生成正式初始收藏。
- 保存内容包含：
  - 身份、占卜券、收藏、等级、碎片、保底和成长阶段。
  - 根种子、遭遇、已拥有牌组摘要和上一场结果。
- 继续保留临时文件、校验、备份、损坏保护和失败不覆盖原档的行为。
- `AppBootstrap.inspect_checkpoint()` 使用 v2 服务，因此旧 v1 检查点也能读取。

## 修改文件

- `src/app/bootstrap.gd`
- `src/app/game_session.gd`
- `src/app/campaign_session.gd`
- `src/infrastructure/atomic_save_service.gd`
- `src/infrastructure/battle_balance_adapter.gd`
- `src/infrastructure/json_document_loader.gd`
- `src/infrastructure/progression_content_adapter.gd`
- `src/infrastructure/save_migrations.gd`
- `data/schema/v0.4.0/**`
- `tests/infrastructure/test_runner.gd`
- `tests/infrastructure/README.md`
- 本报告

## 验证

Godot 4.7.2 headless：

```text
PASS infrastructure tests: 150
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=90
APP_INTEGRATION_OK checks=30
SIMULATION_TESTS_OK checks=33
UI_SMOKE_OK checks=21
main scene --quit-after 5: exit 0
```

基础设施新增覆盖：

- progression/balance/save schema。
- 正式成长内容与基础卡引用。
- v0.4 参数映射和 v1/v2 内容版本关系。
- 新游戏身份选择、真实战斗、胜利奖励、升级、祈愿和保存。
- 继续游戏恢复身份、等级、货币和收藏。
- 下一场战斗的 owned deck 与身份修正。
- v1 -> v2 迁移，以及迁移后的新成长初始状态。
- 缺失参数、非法稀有度和缺卡引用拒绝。

## 困难与解决

| 困难 | 候选方案 | 最终选择 |
|---|---|---|
| v0.3 存档没有成长字段 | 直接覆盖旧档；禁止读取；显式迁移 | 显式注册 v1 -> v2，旧档迁移后重新生成初始成长 |
| 新 schema 会破坏旧测试服务 | 全局改所有服务；让 schema 可选；让服务可注入 schema | 保留 v1 默认服务，v0.4 app 显式创建 v2 服务 |
| 升级不能形成第二份卡牌定义 | 复制升级卡；在 balance 写卡牌金额；内容端口装饰 | 保留基础卡唯一源，战斗读取时应用等级增量 |
| 新脚本冷启动无法引用自身 class_name | 依赖全局类缓存；让调用方手动注册 | 迁移服务在脚本内以前向 lambda 注册 |
| 未拥有卡进入正式遭遇 | 修改遭遇数据；让战斗忽略缺失卡 | app 通过 owned deck 过滤后再初始化战斗 |

没有回滚任何可运行代码。

## 跨角色请求

```text
[REQUEST]
从：本地数据层
给：主协调者 / UI
版本：v0.4.0
内容：应用控制器使用 CampaignSession 接身份、奖励、祈愿、升级和战斗页面。
关键接口：
  get_progression_snapshot()
  submit_progression(ProgressionCommand)
  begin_battle()
  submit_battle(BattleCommand)
  start_next_battle()
  get_battle_snapshot()
  query_card_play()
命令映射：
  identity_selected -> select_identity
  reward_claimed -> claim_reward
  draw_requested -> draw_gacha
  upgrade_requested -> upgrade_card
截止检查点：v0.4 UI 端到端接线
[END REQUEST]
```

## 风险与未决问题

- `src/app/app_controller.gd` 仍使用 v0.3 单战斗入口，尚未路由四个 v0.4 页面。
- UI v0.4 页面当前已存在但尚未由应用控制器接线；本报告不将其视为已集成。
- v1 迁移会重新生成 v0.4 初始成长收藏，因为 v1 没有收藏或货币字段。
- 主协调者最终提交前仍需清理其他角色在 `art/README.md` 和
  `art/ASSET_MANIFEST.md` 产生的 EOF 空行，使仓库级 `git diff --check` 通过。
