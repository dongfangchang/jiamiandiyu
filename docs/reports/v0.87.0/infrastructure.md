# v0.87.0 本地数据层报告（轨道 A：R1-01、R1-02）

```text
版本：v0.87.0
角色：本地数据层开发
任务：R1-01 删除 bootstrap.gd 的 legacy 入口和 campaign_session.gd；R1-02 save_migrations.gd 只保留一个迁移链工厂
状态：完成
修改文件：
  src/app/bootstrap.gd
  src/app/campaign_session.gd（删除，含 .uid）
  src/app/game_session.gd
  src/app/route_session.gd
  src/app/challenge_session.gd
  src/infrastructure/save_migrations.gd
  tests/infrastructure/test_runner.gd
  tests/infrastructure/route_backend_runner.gd
  tests/infrastructure/challenge_backend_runner.gd
  tests/infrastructure/v07_backend_runner.gd
  tests/infrastructure/fixtures/v0.3.0/balance.json（删除）
  tests/infrastructure/README.md
依赖：无其他轨道交付物；未触碰 src/ui/**、scenes/**、tests/ui/**、tests/integration/**、assets/**、data/**
验证：tools/run_tests.sh -> run_tests: pass=85 fail=0 skipped=9 guard_block=0；黄金回放 PASS，tests/golden/expected.json 未改动
困难与候选方案：见下文
最终解决：见下文
风险：见下文
跨角色请求：见下文
下一步入口：R2（v0.88.0）
```

## 1. 可达性核对

删除前用 grep 检查了 `src/` 中的每个函数（`app_controller.gd`、`screen_router.gd`、`app_root.tscn` 以及其余 src 文件）：

| 函数 | 生产调用 | 测试调用（删除前） |
|---|---|---|
| `start_new_game` | 无（`app_controller.start_new_game` 是同名的控制器方法，内部调用 `start_route_v07`） | test_runner |
| `start_campaign` | 无 | test_runner |
| `inspect_checkpoint` | 无 | test_runner |
| `start_route` | 无 | route_backend、challenge_backend |
| `start_challenge` | 无（`ChallengeCommand.start_challenge` 不是同一个函数） | challenge_backend |
| `inspect_route_checkpoint` | 无 | route_backend、challenge_backend |
| `load_battle_ports` | 无 | test_runner |
| `load_campaign_ports` | 无 | 无 |
| `checkpoint_summary`（公开包装） | 无 | 无 |
| `CampaignSession` | 只由 `start_campaign` 构造 | 无 |
| `SaveMigrations.create_v04/05/06_service` | 只由上面的 legacy 入口使用 | test_runner、route_backend、challenge_backend、v07_backend |

`tests/integration/**` 没有调用任何被删函数，所以没有改动。

## 2. 已完成

### R1-01

- `bootstrap.gd` 删除上表中的 8 个 legacy 入口、`checkpoint_summary` 包装、26 个 v0.3–v0.6 路径常量，以及 `GameSessionScript`、`CampaignSessionScript` 两个 preload。
- `start_route_v07` 原来逐个手写 8 次"加载文档 → 失败时附加 stage"，现在改为表驱动的 `_load_v07_documents`。加载顺序、路径覆盖键（`<key>`、`<key>_schema`）和失败时的 stage 名不变。`start_challenge_v07` 只合并了多余的换行，行为不变。
- 删除 `src/app/campaign_session.gd`。
- `game_session.gd` 仍是路线和挑战的单场战斗包装，所以保留。只删除只为 legacy 入口服务的部分：存档相关的 `save_checkpoint`、`_build_checkpoint_envelope`、`last_checkpoint_result`、`_auto_save_on_end`，以及 `services`、`checkpoint_slot`、`encounter_name`、`card_display_name`、`enemy_display_name`、`_content_version` 等无人读取的字段。路线和挑战一直传 `auto_save_on_end=false`，因此删除自动存档分支不改变行为。构造参数随之减少，`route_session.gd` 和 `challenge_session.gd` 的两处调用已同步更新。

### R1-02

- `save_migrations.gd` 删除 `create_v04_service`、`create_v05_service`、`create_v06_service`。现在只有 `create_v07_service` 注册 v1→v5 迁移链。四个 `migrate_vN_to_vM` 函数、版本常量和 schema 路径保持原样，存档格式不变。

### 行数

| 文件 | 之前 | 之后 | 变化 |
|---|---|---|---|
| `src/app/bootstrap.gd` | 1444 | 690 | −754 |
| `src/app/campaign_session.gd` | 244 | 0 | −244 |
| `src/app/game_session.gd` | 229 | 119 | −110 |
| `src/app/route_session.gd` | 569 | 565 | −4 |
| `src/app/challenge_session.gd` | 623 | 619 | −4 |
| `src/infrastructure/save_migrations.gd` | 237 | 162 | −75 |
| **src 合计** | | | **−1191** |
| `tests/infrastructure/*`（4 个 runner） | 2712 | 2335 | −377 |

`bootstrap.gd` 为 690 行，达到"< 700 行"的标准。

## 3. 测试迁移与删除

### 迁移到 v07 入口（仍检查实际运行中的行为）

| 测试 | 原入口 | 迁移后 |
|---|---|---|
| test_runner `_test_game_session_and_checkpoint` → `_test_route_checkpoint_inspection` | `start_new_game` + `inspect_checkpoint` | `start_route_v07` + `inspect_route_checkpoint_v07`：检查缺档返回 none，选择身份后存档返回 loaded（content_version v0.7.0、种子、身份），主档损坏时返回 corrupt 并给出 backup_available |
| test_runner `_test_v1_to_v2_campaign_migration` → `_test_v1_save_migrates_to_current` | `create_v04_service` + `start_campaign` | `create_v07_service`：v1 存档走完整条链到 v5，逐段检查 migrated_from_v1/v2/v3/v4 标记 |
| test_runner `_test_battle_ports_and_adapters` → `_test_battle_adapters` | 含 `load_battle_ports` 和 v0.2 草案 | 保留内容、数值和随机三个适配器断言；数值改用现行 `data/balance/v0.7.0/balance.json`，压力起始回合的期望值由 7 改为 5 |
| route_backend `_test_route_session_and_node_resume` | `start_route` + `inspect_route_checkpoint`（v0.5 包） | `start_route_v07`（`route.v070.first_case`）+ `inspect_route_checkpoint_v07`；完整打通战斗、休息、首领、仪式、序列 8 和恢复，断言数量不变（67） |
| route_backend `_test_v1_and_v2_migrations` | `create_v05_service`，期望 v3 | `create_v07_service`，期望 v5 |
| challenge_backend 全部会话、恢复、奖励测试 | `start_route` / `start_challenge` / `inspect_route_checkpoint`，v0.6 挑战 | `start_route_v07` / `start_challenge_v07` / `inspect_route_checkpoint_v07`，v0.7 挑战；`ChallengeSession` 按生产方式传入 deck_engine、"v0.7.0"、5 |
| challenge_backend `_test_v3_to_v4_migration` | `create_v06_service`，期望 v4 | `create_v07_service`，期望 v5（迁移标记和备份可读的断言保留） |
| v07_backend `_test_v4_to_v5_migration` | 用 `create_v06_service` 写 v4 夹具 | 用 `AtomicSaveService.new(dir, V06_SAVE_VERSION, V06_SAVE_SCHEMA_PATH)` 直接写 v4 夹具，再用 v07 链迁移 |

### 删除（只覆盖死代码或冻结数据）

| 测试或断言 | 原因 |
|---|---|
| test_runner `_test_balance_schema` | 只校验 `data/balance/v0.2.0/balance_draft.json`，无运行时引用（AR-44，轨道 D 负责删除数据） |
| test_runner `_test_battle_ports_and_adapters` 中的 v0.2 battle_cards schema 拒绝断言（2 条）和 `load_battle_ports` 装配断言（4 条） | 前者依赖 `data/schema/v0.2.0/battle_cards.schema.json`（AR-44），后者测试的是被删除的入口 |
| test_runner `_test_formal_v03_content_startup` | 只测 v0.3 `start_new_game` 包 |
| test_runner `_test_v04_schemas_adapters_and_campaign` 后半部分（CampaignSession 的身份、战斗、奖励、升级、抽卡、恢复） | 只测 `start_campaign`/`CampaignSession`；同类行为已由 route_backend、v07_backend 和玩法 runner 经 v07 路线覆盖。前半部分 v0.4 schema 和适配器断言保留 |
| test_runner `_test_game_session_and_checkpoint` 中的 `GameSession.save_checkpoint` 去重和"进行中不得存档"断言 | 被测方法只为 legacy 入口存在，已随之删除 |
| challenge_backend "challenge schema should reject battle corruption deltas above ten" | 这是 v0.6 挑战 schema 的上限约束，v0.7 schema 没有这个上限；迁到 v0.7 后断言不成立。是否要在 v0.7 schema 恢复上限属于 schema 决策，列入候选池 |
| `tests/infrastructure/fixtures/v0.3.0/balance.json` | 只被已删除的 `start_new_game` 测试使用 |

迁移后的断言数：test_runner 96（README 记录的旧基线为 150），route_backend 67，challenge_backend 64（原 65），v07_backend 43。

## 4. 困难与候选方案

1. **game_session.gd 是删除还是保留**。候选 A：整个删除，把战斗包装并入 route_session 和 challenge_session。候选 B：保留文件，只删除 legacy 存档部分。**选择 B**：两种会话都依赖它，合并会把 R3 的拆分提前到本版，超出 R1 的范围。
2. **legacy 测试是迁移还是删除**。候选 A：把 legacy 函数改名为测试辅助函数继续保留。候选 B：凡是仍有实际行为价值的测试都迁到 v07 入口，只测死代码的测试删除。**选择 B**，因为 AGENTS §6 禁止"为探针保留"死代码。
3. **start_route_v07 的加载块**。删除 legacy 入口后文件约 723 行，仍高于 700 的目标。改用表驱动加载达到 690 行；失败时的 stage 名和加载顺序都与原实现一致，黄金回放不变。

## 5. 风险

- `GameSession` 的构造参数减少了。仓库内只有 route_session 和 challenge_session 两处构造，已同步更新；src/tests/tools 中没有其他直接构造。
- tests/simulation、tests/gameplay 和 tools/simulation 中仍有多个 runner 直接读取 v0.3–v0.6 的 data 文件，但它们不经过 bootstrap，不在本轨道范围内；这些数据目录是否归档由 R1-06 或 R2-08 决定。
- `tests/infrastructure/README.md` 中的基线数字是旧值，本次只更新了覆盖说明。

## 6. 跨角色请求

- 轨道 D（主协调者）：`data/schema/v0.2.0/battle_cards.schema.json`、`content_envelope.schema.json` 以及 `data/balance/v0.2.0/balance_draft.json` 在 tests/infrastructure 中已经零引用，可以按 R1-06 归档。`data/schema/v0.2.0/save.schema.json` 仍被 `atomic_save_service.gd` 用作默认 schema，**不能删除**。

## 7. 候选池

- v0.7 挑战 schema 是否恢复 `battle_corruption_delta` 的 0–10 上限（v0.6 schema 有这个上限）。
- `create_v07_service` 可以在 R2 改名为 `create_save_service`，与"不再以版本号命名"保持一致。
