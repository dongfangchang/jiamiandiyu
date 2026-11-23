# v0.7.0 / 本地数据层开发工作记录

## 状态

- 版本：`v0.7.0`
- 角色：本地数据层开发
- 任务：v0.7 schema、DeckContentPort、挑战依赖校验、v5 存档与 v0.7 会话装配
- 状态：完成本角色范围；等待 UI/app 路由接入和全量关闭验收
- 最后更新：2026-11-08

## 依赖

- `AGENTS.md`、`docs/CURRENT_VERSION.md`、`docs/PROJECT_CHARTER.md`
- `docs/ARCHITECTURE_CONTRACT.md`、`docs/versions/v0.7.0.md`
- 玩法交付的 16 卡、DeckEngine、三套预设和第二挑战内容
- 数值交付的 `data/balance/v0.7.0/balance.json`

## 已完成

### Schema 与内容端口

- 新增 `data/schema/v0.7.0/`：cards、progression、decks、enemies、encounters、routes、rituals、challenges、balance、save。
- 新增 `DeckContentAdapter`，校验默认预设、牌组大小、卡池 ID 和预设引用。
- `ChallengeContentAdapter` 增加：
  - `required_challenge_ids` 类型与存在性检查；
  - 自依赖、重复依赖和依赖环检查。

### Deck 会话接入

- `GameSession` 增加可选 confirmed deck override；v0.7 战斗使用真实八卡选择。
- `RouteSession`、`ChallengeSession` 接入可选 `DeckEngine`：
  - `get_deck_snapshot()`
  - `submit_deck(DeckCommand)`
  - `get_confirmed_deck_ids()`
- 无牌组引擎时保留旧 v0.5/v0.6 固定牌组路径，兼容历史回归。
- 有牌组引擎但未确认时，战斗返回 `deck_not_confirmed`。

### App 入口

- 新增 `AppBootstrap.start_route_v07()`。
- 新增 `AppBootstrap.start_challenge_v07()`。
- 新增 `AppBootstrap.inspect_route_checkpoint_v07()`。
- v0.7 启动加载当前正式卡包、路线、仪式、牌组、挑战和数值内容。
- 新游戏默认确认合法八卡“守夜档案”，之后编辑会取消确认，必须重新确认。

### 存档 v5

- 新增 v1 → v2 → v3 → v4 → v5 显式迁移。
- v5 保存 `deck.initialized` 与完整 `deck.state`，包含当前牌组、预设、选择状态和确认状态。
- Checkpoint summary 增加：
  - `deck_confirmed`
  - `current_deck_card_ids`
  - `completed_challenge_ids`
- 路线和挑战节点边界保存；V5 仍不保存战斗中间状态。
- 旧档迁移时牌组先标记未初始化，启动后用默认八卡补齐并确认，不覆盖原文件之外的来源。

## 验证

```text
PASS infrastructure tests: 150
ROUTE_BACKEND_TESTS_OK checks=67
CHALLENGE_BACKEND_TESTS_OK checks=65
V07_BACKEND_TESTS_OK checks=43
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=103
ROUTE_TESTS_OK checks=98
CHALLENGE_TESTS_OK checks=89
V07_DECK_TESTS_OK checks=148
V07_CHALLENGE_TESTS_OK checks=38
APP_V06_INTEGRATION_OK checks=146
```

## 困难与解决

| 困难 | 处理 |
|---|---|
| 旧 v0.5/v0.6 固定牌组与 v0.7 选择牌组冲突 | GameSession 新增可选牌组覆盖；只有显式 DeckEngine 时启用新路径 |
| 第二挑战需避免前向引用和依赖环 | ChallengeContentAdapter 在完整读取后统一校验依赖图 |
| v4 存档没有 deck 字段 | v4 → v5 迁移显式建立 deck 状态，之后由 DeckEngine 恢复或默认确认 |
| 旧集成测试仍走 v0.6 入口 | 保留旧入口，新增 v07 入口，避免以全局切换破坏历史回归 |

## 跨角色请求

```text
[REQUEST]
从：本地数据层
给：UI / App 路由
版本：v0.7.0
内容：正式主流程改用 start_route_v07、start_challenge_v07、inspect_route_checkpoint_v07；
新增牌组编辑页面，读取 get_deck_snapshot() 并提交 DeckCommand；
身份选择后先完成牌组确认，再进入路线/挑战。
原因：旧 start_route/start_challenge 仍冻结在 v0.6 内容路径，供历史回归使用。
截止检查点：v0.7 app 接线。
[END REQUEST]
```

## 风险

- 当前 `DeckEngine` 的恢复逻辑属于玩法层，数据层只保存完整状态，不替玩法重新计算合法性。
- 主线控制器还未切换到 v07 入口，因此直接运行旧 app 仍显示 v0.6 流程。
- v5 存档会保留旧档迁移链；正式发布前仍需全量回归和独立构建。
