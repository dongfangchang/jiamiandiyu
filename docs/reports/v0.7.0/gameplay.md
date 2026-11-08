# v0.7.0 / 玩法设计工作记录

## 状态

- 版本：`v0.7.0`
- 角色：玩法设计
- 任务：16 张占卜家卡池、8 卡牌组构筑、三套预设和第二挑战
- 状态：领域与构筑可行性修正完成；等待数值复采样和最终集成
- 最后更新：2026-11-08

## 已完成

### 卡池与升级

- 新增 8 张占卜家卡牌，当前正式卡池共 16 张唯一卡。
- 新卡全部复用已注册 effect 闭集。
- 祈愿池包含 15 张可升级卡；`second_look` 保持确定性初始收藏，不进入祈愿池。
- 新增防御、灵性/抽牌、标记爆发三条构筑方向。

### Deck 领域

- 新增 `DeckCommand`、`DeckEvent`、`DeckSnapshot`、`DeckCommandResult`、`DeckContentPort`。
- 新增 `DeckEngine`：
  - 8 张唯一卡牌。
  - 仅允许已拥有且已实现卡牌。
  - 加入、移除、清空、恢复默认、选择预设、保存预设、确认出战。
  - 编辑后自动取消旧确认。
  - 稳定原因码：`empty_deck`、`wrong_deck_size`、`duplicate_card`、`card_not_owned`、`unknown_card`、`unknown_preset`。
  - 持久状态导出/恢复。
- 新增三套预设和默认合法牌组数据。

### 构筑可行性修正

- 初始收藏扩展到 10 张，加入 `card.skill.omen` 与 `card.skill.coffin_nail`，保证新游戏默认牌组拥有标记起手和可靠终结牌。
- 守夜档案调整为 2 张伤害牌、3 张防御牌，并保留治疗与灵性支撑。
- 灵性预感用 `coffin_nail`、`whispered_hunch`、`mirrored_memory`、`paper_guard`、`calm_breath` 替换低伤害过滤组合，保留抽牌与灵性主题。
- 三套预设均保持 8 张唯一牌；满收藏时全部可确认。
- 新增测试要求每套预设至少包含 2 张伤害牌和 2 张防御牌。

### 第二挑战

- 新增 `challenge.v070.broken_procession`。
- 解锁条件：序列 8，并完成 `challenge.v060.mirror_echoes`。
- 完成记录保存在 `SequenceState.completed_challenge_ids`。
- 第二路线使用双敌人精英遭遇和双敌人首领遭遇。
- 残页晋升仪式的错误污染为 4，高于首次路线的 2。
- 新增三个修饰：讣告回声、双影同行、通宵守仪。
- `ChallengeSnapshot` 新增 required/completed challenge IDs 和 route ID。

## 验证

```text
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=103
ROUTE_TESTS_OK checks=98
CHALLENGE_TESTS_OK checks=89
V07_DECK_TESTS_OK checks=178
V07_CHALLENGE_TESTS_OK checks=38
```

## 跨角色请求

```text
[REQUEST]
从：玩法设计
给：本地数据层
版本：v0.7.0
内容：建立 cards/progression/decks/challenges/routes/rituals/encounters v0.7 schema；
切换默认内容路径；实现 DeckContentPort 与 ChallengeContentPort.get_challenge_ids；
存档升级到 v5，保存 current deck、三套预设、confirmed deck、
completed_challenge_ids 和第二挑战状态。
原因：当前领域接口完成，但默认 app 仍读取 v0.4/v0.5/v0.6 路径。
期望接口：只装配正式内容，不重算牌组合法性或挑战解锁。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：UI 设计
版本：v0.7.0
内容：新增牌组编辑/收藏页面，只读取 DeckSnapshot；
命令使用 DeckCommand；卡牌升级等级由 app 从 ProgressionSnapshot 合并展示；
第二挑战入口由 ChallengeSnapshot.completed_challenge_ids/unlocked 驱动。
[END REQUEST]
```

```text
[REQUEST]
从：玩法设计
给：数值设计
版本：v0.7.0
内容：对 warding、oracle、burst 三套 8 卡牌组、
两个身份和两条挑战进行固定种子真实引擎采样；
特别验证快速牌组是否有可行胜利路径，以及新卡升级收益。
[END REQUEST]
```

## 风险

- 三套预设有两套依赖祈愿解锁，首次进入时只能直接确认默认守夜牌组。
- 第二挑战已完成领域测试，但尚未经过 app 和 UI 实机接线。
- v0.7 全量卡包是当前运行时单一事实源；旧版本卡包保留为历史归档。
- 尚未进行真实人工牌组构筑体验与鼠标操作反馈。
- 初始收藏和两套预设已完成前向调整；数值角色需重新采样三套牌组，确认完成率与时长。
- 已清理项目根目录由命令重定向误生成的 0 字节 `$null` 文件，未回滚任何游戏代码。
- 仓库级 `git diff --check` 仍被美术角色文件 `art/ASSET_MANIFEST.md` 的文件尾空行阻塞；玩法作用域 diff 检查已通过，需美术或主协调者清理。

## 下一步入口

1. 数据层完成 v0.7 schema、内容适配与 v5 存档迁移。
2. UI/app 接入牌组编辑、确认出战和第二挑战。
3. 数值完成三构筑固定种子采样。
4. 全量回归、独立构建重导出与 UI 美术审稿。
