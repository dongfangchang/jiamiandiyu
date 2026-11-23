# v0.3.0 / 本地数据层开发工作记录

## 状态

- 版本：`v0.3.0`
- 角色：本地数据层开发
- 任务：正式内容 schema、端口装配、应用启动、战后检查点和启动摘要
- 状态：完成（正式内容启动、端口装配与检查点链路已通过模块级验证）
- 最后更新：2026-11-08
- 下一步入口：UI 使用 `GameSession` 接入真实战斗和结果页，主协调者完成场景路由与端到端验收。

## 本版本目标

在不复制玩法规则的前提下，让应用可以加载卡牌、敌人和遭遇，装配 BattleEngine 所需端口，从新游戏进入真实战斗，并在战斗结束后保存可读取的检查点摘要。

## 依赖

- 玩法设计：8 张正式卡、敌人语义、遭遇结构和第 5/7/9 回合压力规则。
- 数值设计：BalancePort 参数与固定种子。
- UI 设计：通过 AppBootstrap/GameSession 获取只读快照和命令结果。
- 产品经理：ADR-0006 已明确 `data/enemies/**`、`data/encounters/**` 由玩法设计唯一维护。

## 已完成

### 正式 schema

新增 `data/schema/v0.3.0/`：

- `cards.schema.json`
- `enemies.schema.json`
- `encounters.schema.json`
- `balance.schema.json`
- `README.md`

三类内容均使用 `schema_version` 和 `content_version`。显示名称不作为主键。

v0.3 默认 Balance 已迁移到 `data/balance/v0.3.0/balance.json`，只保留全局战斗参数；卡牌、敌人和遭遇定义不会复制进数值文件。

### 内容目录与跨引用校验

新增 `CampaignContentCatalog`：

- 索引稳定卡牌 ID、敌人 ID 和遭遇 ID。
- 拒绝空内容、重复 ID、跨文档版本不一致。
- 拒绝遭遇中不存在的卡牌或敌人引用。
- 拒绝重复或越界的敌人列位置。
- 将遭遇解析为 BattleEngine 所需固定牌组和敌人运行时配置。
- 运行时敌人 ID 由遭遇 ID 与列位置生成，保持确定性。

### 应用装配与战斗会话

扩展 `AppBootstrap`：

- `load_campaign_ports`：加载并校验三类内容、数值文件，装配内容、数值和随机端口。
- `start_new_game`：选择遭遇、构造玩家初始状态、初始化真实 BattleEngine。
- `inspect_checkpoint`：返回 `none`、`loaded` 或 `corrupt`，并报告备份可用性。

新增 `GameSession`：

- 对 UI 暴露只读快照、卡牌合法性和命令提交。
- 只转发冻结的玩法接口，不计算伤害、胜负或敌方压力。
- 仅当战斗进入 victory/defeat 后自动保存一次战后检查点。
- 同一战斗结果重复保存时返回 `already_saved`，避免重复写盘。
- 检查点保存 content_version、save_version、创建时间、根种子、序列 9、固定牌组摘要和上一场结果。
- 提供卡牌、敌人的显示名称查询，UI 不读取内容目录内部结构。

### 测试

新增正式内容 fixture 与启动链路测试，覆盖：

- 三类 schema 加载和跨文件引用。
- 内容版本不一致、缺失敌人引用、重复敌人列位置。
- 固定种子新游戏、玩家生命、起始手牌和敌人实例化。
- 非法提前保存拒绝。
- 战斗结束自动保存、重复保存防护和固定牌组摘要。
- 启动读取 `none`/`loaded`/`corrupt` 摘要与备份可用性。
- 默认正式 `cards.json`、`enemies.json`、`encounters.json` 加载后进入 `encounter.first_hunt`，实化两个敌人并读取正式卡牌、敌人显示名。

## 困难与解决方案

| 困难 | 候选方案 | 最终选择 | 结果 |
|---|---|---|---|
| 新类在独立测试入口冷启动时无法作为静态类型解析 | 依赖全局类缓存；为测试预热；弱类型应用边界 | `CampaignContentCatalog` 在应用装配边界使用显式实例和 RefCounted 字段，脚本本身仍独立可测 | 根因处理了类缓存顺序，没有添加运行分支 |
| JSON 内容与玩法内部状态可能形成两套事实源 | 在基础设施解析战斗效果；让适配器计算伤害；只索引、只组装 | 基础设施只做 schema、引用和基本不变量校验，规则仍由 BattleEngine 校验与执行 | 保持依赖方向 |
| 战斗结束可能被 UI 重复通知并多次保存 | 增加全局事件总线；每次覆盖；应用会话幂等键 | 用 battle_id + revision + outcome 形成单次保存键 | 无新公共事件系统 |
| 损坏存档只有错误码，启动页无法判断能否恢复 | 自动覆盖；直接返回失败；摘要对象 | `inspect_checkpoint` 返回结构化状态和 backup_available，不自动恢复 | UI 可以选择安全操作 |
| 正式敌人/遭遇所有权未在共享文档中明确 | 数据层越权创建；让 UI 临时造数据；停止主链 | 使用 schema 与 fixture 完成模块验证，同时提交所有权请求 | 玩法已按 v0.3.0 派工交付正式内容；文档所有权表仍需 PM 补齐 |

## 修改文件

- `data/schema/v0.3.0/**`
- `src/infrastructure/campaign_content_catalog.gd`
- `src/infrastructure/battle_balance_adapter.gd`
- `src/app/app_services.gd`
- `src/app/bootstrap.gd`
- `src/app/game_session.gd`
- `tests/infrastructure/test_runner.gd`
- `tests/infrastructure/fixtures/v0.3.0/**`
- `tests/infrastructure/README.md`
- 本报告

## 验证

- Godot 4.7.2 headless 基础设施测试：`104 passed, 0 failed`。
- Godot 4.7.2 headless 玩法联合回归：`GAMEPLAY_TESTS_OK checks=131`。
- `git diff --check`：通过。
- 固定 fixture 能从新游戏进入 BattleEngine、完成胜利、保存检查点并在新服务实例中读取摘要。
- 运行时代码只使用 `res://`，未新增本机绝对路径。
- `src/infrastructure` 未引用 UI、玩法状态类或场景树。

## 跨角色请求

```text
[REQUEST]
从：本地数据层开发
给：玩法设计
版本：v0.3.0
内容：正式内容已被数据层按固定路径和 schema 成功加载；后续新增内容继续保持 content_version 一致、稳定 ID 和三列位置唯一。
原因：当前默认正式内容已验证进入 `encounter.first_hunt`。
期望接口：仅通过 data/cards、data/enemies、data/encounters 修改，不复制到 UI 或应用代码。
截止检查点：v0.3.0 关闭前
[END REQUEST]
```

## 风险与未决问题

- 正式敌人/遭遇文件已交付，默认 `start_new_game` 已能从正式内容初始化首场双敌人战斗。
- 正式数值已迁移到 v0.3.0，敌方压力起点为第 5 回合。
- 原子替换采用备份加恢复，进程在删除主档与重命名之间被强制终止时主档可能暂时缺失，但备份仍可识别。
- 当前每个内容类别读取一个聚合文档；内容量扩大后是否拆分文件需新版本决定，不在本版本提前抽象。
- UI 尚未接入 `GameSession`，主协调者仍需完成场景路由和端到端集成。

## 下一步入口

1. UI 使用 `GameSession.get_snapshot()`、`query_card_play()` 和 `submit()` 接入战斗页。
2. 主协调者完成资源迁移后的端到端验收。
3. 数值角色同步压力起点和真实战斗采样。
