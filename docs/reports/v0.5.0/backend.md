# v0.5.0 / 本地数据层开发

## 状态

- 版本：`v0.5.0`
- 角色：本地数据层开发
- 任务：路线/仪式 schema、跨版本内容装配、RouteSession、存档 v3
- 状态：完成；v0.5.0 已关闭
- 最后更新：2026-11-08
- 下一步入口：UI 路线地图/休息/仪式页面接入 `RouteSession`，主协调者完成端到端验收

## 本版本目标

在复用 BattleEngine、ProgressionEngine 和 RouteEngine 的前提下，完成：

```text
身份选择 -> 首战 -> 精英 -> 休息 -> 首领 -> 晋升仪式
  -> 节点边界保存 -> 继续游戏 -> 序列 8 持久化
```

不实现战斗中保存，不在应用层复制战斗、休息、抽卡、升级或仪式答案规则。

## 依赖

- `v0.4.0` 已关闭的身份、奖励、祈愿、升级与存档基础。
- 玩法 v0.5 的 RouteEngine、RouteSnapshot、RitualSnapshot、SequenceState。
- 正式卡牌 v0.3、敌人/遭遇/路线/仪式 v0.5、平衡 v0.5、成长配置 v0.4。
- 产品契约要求存档 v3，并保留 v1/v2 显式迁移。

## 已完成

### 数据 schema

- `data/schema/v0.5.0/routes.schema.json`
- `data/schema/v0.5.0/rituals.schema.json`
- `data/schema/v0.5.0/enemies.schema.json`
- `data/schema/v0.5.0/encounters.schema.json`
- `data/schema/v0.5.0/balance.schema.json`
- `data/schema/v0.5.0/save.schema.json`
- `data/schema/v0.5.0/README.md`

覆盖固定五节点、两步以上休息选项、三步仪式、敌人 `phases`、跨版本基础卡包和路线节点检查点。

### 休息灵性上限字段

- `routes.schema.json` 的休息效果新增可选整数 `max_spirit_delta`。
- 允许范围为 `-5..5`，缺省值为 `0`；旧路线数据缺少该字段时仍可通过 schema。
- `RouteContentAdapter` 保持原始效果字段透传，不在适配器计算休息结果。
- 正式路线数据中的 `rest.seal_echo.max_spirit_delta = 1` 已验证进入快照。
- 真实 RouteSession 选择 `rest.seal_echo` 后，路线状态 `max_spirit` 从 3 提升到 4。
- 新增回归覆盖：字段透传、缺省 0、非整数拒绝、超出范围拒绝。

### 内容装配

- `CampaignContentCatalog` 支持 v0.5 敌人/遭遇引用 v0.3 基础卡包。
- 敌人 `phases` 会进入 BattleEngine 的敌人配置，不在适配器中计算触发。
- `RouteContentAdapter` 校验：
  - 路线、仪式 content version 一致。
  - `base_cards_version` 与已加载基础卡包一致。
  - `base_encounters_version` 与 package version 一致。
  - 五节点类型顺序。
  - 遭遇和仪式引用存在。
  - 仪式答案 ID 都来自公开选项。
- `AppBootstrap.start_route()` 一次装配卡牌、敌人、遭遇、路线、仪式、平衡、成长和随机端口。

### 路线会话

`src/app/route_session.gd` 提供：

- 身份选择后初始化 RouteEngine。
- 将身份生命修正写入路线初始状态，避免每场战斗重复叠加。
- 战斗开始使用 `RouteEngine.get_battle_player_state()`，不再从满血重新构建。
- 战斗结束把 `BattleSnapshot.player` 回写 RouteEngine。
- 胜利后调用 ProgressionEngine 进入奖励阶段，失败结束路线。
- 休息、仪式提示、每一步提交和取消通过 RouteCommand。
- 仪式完成保存序列 9 -> 8“小丑”。
- 下一场战斗使用 owned deck、身份修正和升级内容端口。
- 节点边界保存，战斗中不保存。

验证完整短循环已实际通过：

```text
身份 -> 首战胜利 -> 奖励 -> 精英胜利 -> 奖励
  -> 休息 -> 首领胜利 -> 奖励
  -> 被篡改的讣告三步成功 -> 序列 8
  -> 检查点读取完成路线
```

### 存档 v3

- `SaveMigrations.create_v05_service()` 写入 `save_version: 3`。
- `RouteSession` 保存 progression、路线状态、节点、序列、种子、牌组摘要和上一战结果。
- 从休息前节点恢复已实测。
- v2 -> v3 增加未初始化路线并保留 progression。
- v1 -> v2 -> v3 连续迁移已实测。
- 每次迁移按其目标版本 schema 校验，避免用最终 v3 schema 错误拒绝合法中间 v2。
- 损坏主档仍由 AtomicSaveService 保留，并报告备份可用性。

## 修改文件

- `src/app/bootstrap.gd`
- `src/app/game_session.gd`
- `src/app/route_session.gd`
- `src/infrastructure/atomic_save_service.gd`
- `src/infrastructure/campaign_content_catalog.gd`
- `src/infrastructure/route_content_adapter.gd`
- `src/infrastructure/save_migrations.gd`
- `data/schema/v0.5.0/**`
- `data/schema/v0.5.0/routes.schema.json`
- `data/schema/v0.5.0/README.md`
- `tests/infrastructure/README.md`
- `tests/infrastructure/route_backend_runner.gd`
- `tests/infrastructure/route_backend_runner.tscn`
- 本报告

未修改 UI、scene、gameplay、core、正式内容、美术、balance 数据或 `project.godot`。

## 困难与解决

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 敌人/遭遇 v0.5 需复用 v0.3 卡牌 | 复制卡牌；放宽所有版本；显式 base_cards_version | 显式跨版本基础包 | 保持卡牌单一事实源 |
| 身份生命修正可能在每场战斗重复叠加 | GameSession 每次应用；RouteEngine 初始化应用一次；RouteSession 修正后关闭重复应用 | 初始化路线时应用一次，战斗覆盖状态 | 保持跨节点生命连续，避免重复修饰 |
| 路线引擎只接收战斗终态 | App 自己模拟战斗；使用 RouteEngine；从 BattleSnapshot 回写 | 使用真实 BattleEngine 终态回写 | 不复制战斗规则 |
| 连续迁移 v1->v2->v3 被 v3 schema 拒绝 | 放宽 v3 schema；拆分迁移；按目标版本 schema 校验 | 每跳使用目标 schema | 根因修复，同时保持最终文档严格 |
| 战斗中选择节点后保存会恢复未结束战斗 | 保存战斗中间态；只保存地图；节点边界 + 不保存 battle_pending | 节点边界保存 | 符合“不支持战斗中途恢复” |
| 迁移后的 v0.4 档需要路线 | 丢弃成长；重新开档；创建未初始化路线 | 保留 progression，创建未初始化路线 | 不丢失已验证成长 |

## 验证

```text
PASS infrastructure tests: 150
ROUTE_BACKEND_TESTS_OK checks=67
ROUTE_TESTS_OK checks=98
PROGRESSION_TESTS_OK checks=90
GAMEPLAY_TESTS_OK checks=131
APP_V05_INTEGRATION_OK checks=73
Godot editor resource import: exit 0
backend-scoped git diff --check: passed
```

v0.5 路线后端测试覆盖：

- v0.5 schema 正式通过。
- v0.5 package 使用 v0.3 卡牌。
- 敌人 phases 进入遭遇配置。
- 路线/仪式跨引用与缺失引用拒绝。
- 身份生命修正进入路线。
- 击败首战与精英、奖励领取、休息恢复。
- 休息节点检查点恢复。
- 休息灵性上限字段透传、缺省和非法值校验。
- 封锁回声在真实路线中增加下一战灵性上限。
- 首领战与三步晋升。
- 序列 8、路线 completed 和最后检查点。
- v1/v2 到 v3 连续迁移。

## 风险

- AppController 与 v0.5 页面已由集成角色接线；单独重跑完整路线集成测试为 73 项通过。
- 数值角色已完成 v0.5 路线采样；新的休息灵性上限语义仍需数值角色复采样。
- 全局 `git diff --check` 当前仍受美术文件 `art/README.md`、`art/ASSET_MANIFEST.md` 的 EOF 空行影响；后端作用域检查已通过。

## 跨角色请求

```text
[REQUEST]
从：本地数据层开发
给：UI 设计
版本：v0.5.0
内容：新增路线地图、休息、晋升仪式和路线结算页面。
期望接口：只读 RouteSnapshot/RitualSnapshot；发送 SelectNode、UseRest、BeginAscension、SubmitRitualStep、RequestRitualHint、CancelRitual。
截止检查点：AppController v0.5 接线前
[END REQUEST]
```

```text
[REQUEST]
从：本地数据层开发
给：主协调者
版本：v0.5.0
内容：将 AppController 从 CampaignSession 单战流程切到 AppBootstrap.start_route + RouteSession；处理继续、节点奖励、休息、仪式和序列 8 展示。
期望接口：AppBootstrap.start_route、inspect_route_checkpoint、RouteSession.begin_route_battle/submit_battle/submit_route。
截止检查点：v0.5 端到端验收
[END REQUEST]
```

## 下一步入口

1. UI 在 `assets/game/v0.5.0/**` 上实际审稿并接 RouteSnapshot。
2. 主协调者接 AppController v0.5 路由与节点检查点。
3. 数值完成固定种子完整路线采样。
4. 全量回归后由产品经理关闭 v0.5.0。
