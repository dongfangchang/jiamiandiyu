# 当前开发版本

## 指针

- 当前版本：`v0.7.0`
- 阶段：卡组构筑与第二挑战
- 当前版本文档：`docs/versions/v0.7.0.md`
- 当前文档状态：执行中
- 更新日期：2026-11-08
- 前一版本：`v0.6.0`，已关闭

## 强制阅读

1. `AGENTS.md`
2. `docs/PROJECT_CHARTER.md`
3. `docs/TEAM_PROTOCOL.md`
4. `docs/ARCHITECTURE_CONTRACT.md`
5. `docs/versions/v0.7.0.md`

## 当前冻结规则

- 产品根目录固定为 `G:\guimizhizhu`。
- 单人、离线、Godot 4.7.2、GDScript。
- 本地“后端”只做存档、内容加载、RNG、日志、schema 和应用装配，不建设服务器。
- 抽卡只使用游戏内资源，不允许真实付费。
- 首版继续只使用占卜家；v0.7 将正式战斗卡池从 8 张扩展到至少 16 张。
- 首次晋升固定为占卜家序列 9 -> 序列 8「小丑」。
- 首版路线固定为三场战斗、一次休息和一次三步晋升仪式。
- v0.7 首版牌组固定为 8 张唯一卡牌，只能使用已拥有卡牌。
- 当前牌组和三套预设必须可保存、重启恢复，并实际用于首次路线和挑战。
- 运行字段统一为 `corruption` 和 `attention`。
- UI 只消费只读快照、事件和稳定原因码，不计算伤害、概率、保底、合法性和胜负。
- 美术与 UI 是独立角色；美术提交候选，UI 在实际界面审稿，美术不得自行验收。
- 普通缺陷默认前向根因修复；仅运行阻断、数据破坏、结构无法安全前进或用户明确要求时评估回滚。
- 每个版本新建独立文档，历史版本不覆盖。

## 当前文件所有权

- `src/core/**`：玩法设计独占。
- `src/gameplay/**`、`tests/gameplay/**`、`data/cards/**`、`data/enemies/**`、`data/encounters/**`、`data/routes/**`、`data/rituals/**`、`data/challenges/**`、`data/decks/**`：玩法设计。
- `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`：数值设计。
- `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`：UI 设计。
- `art/**`：美术。
- `src/app/**`、`src/infrastructure/**`、`data/schema/**`、`tests/infrastructure/**`：本地数据层开发。
- `tests/integration/**`、`assets/game/**`、`build/**`、`export_presets.cfg`、`project.godot`：主协调者。
- `docs/**`、`AGENTS.md`：产品经理。
- 角色报告路径：`docs/reports/v0.7.0/<role>.md`。

## 当前验证结果

v0.6.0 已关闭并通过最终回归：

- 基础设施：150 项。
- 路线后端：67 项。
- 挑战后端：65 项。
- 基础玩法：131 项。
- 晋级成长：103 项。
- 路线玩法：98 项。
- 挑战玩法：89 项。
- 基础 UI：33 项。
- 成长 UI：41 项。
- 路线 UI：62 项。
- 挑战 UI：40 项。
- 完整应用集成：146 项。
- 数值合同：33 项。
- 经济合同：54 项。
- 路线合同：47 项。
- 挑战合同：48 项。
- 主场景 headless 启动退出码 0。
- Windows 独立构建在项目目录外启动退出码 0。
- UI 已完成 v0.6 挑战美术实际界面复审，原型范围通过。

## 当前开放问题

- v0.7 牌组编辑、三套预设、当前牌组和 8 张新增卡尚未实现。
- 第二挑战解锁、路线变体和两个新修饰尚未冻结正式 ID。
- 卡池/牌组 schema 与 v5 存档尚未实现。
- 真实人工秒表试玩与鼠标操作反馈尚未收集；用户试玩没有发现问题就保留当前验收基线。
- `rushed_reflection` 与 `fractured_deck` 仍偏构筑展示，后续挑战必须增加内容压力而非虚增生命。

## 下一检查点

1. 玩法冻结 DeckCommand/DeckSnapshot、8 张出战牌组规则、三套预设和第二挑战解锁语义。
2. 数值审核新增 8 张卡牌、三条构筑方向和第二挑战修饰。
3. 数据层冻结卡池/牌组 schema 与 v5 存档迁移。
4. UI 与美术并行制作卡组编辑、收藏和第二挑战页面；UI 必须实际审稿美术。
5. app 接入牌组选择、首次路线与第二挑战，完成全量回归和独立构建重导出。
