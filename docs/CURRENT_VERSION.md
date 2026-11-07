# 当前开发版本

## 指针

- 当前版本：`v0.5.0`
- 阶段：短路线与首次序列晋升
- 当前版本文档：`docs/versions/v0.5.0.md`
- 当前文档状态：执行中
- 更新日期：2026-11-08
- 前一版本：`v0.4.0`，已关闭

## 强制阅读

1. `AGENTS.md`
2. `docs/PROJECT_CHARTER.md`
3. `docs/TEAM_PROTOCOL.md`
4. `docs/ARCHITECTURE_CONTRACT.md`
5. `docs/versions/v0.5.0.md`

## 当前冻结规则

- 产品根目录固定为 `G:\guimizhizhu`。
- 单人、离线、Godot 4.7.2、GDScript。
- 本地“后端”只做存档、内容加载、RNG、日志、schema 和应用装配，不建设服务器。
- 抽卡只使用游戏内资源，不允许真实付费。
- 首版继续只使用占卜家和既有正式卡池。
- 首次晋升固定为占卜家序列 9 -> 序列 8「小丑」。
- 首版路线固定为三场战斗、一次休息和一次三步晋升仪式。
- 运行字段统一为 `corruption` 和 `attention`。
- UI 只消费只读快照、事件和稳定原因码，不计算伤害、概率、保底、合法性和胜负。
- 美术与 UI 是独立角色；美术提交候选，UI 在实际界面审稿，美术不得自行验收。
- 普通缺陷默认前向根因修复；仅运行阻断、数据破坏、结构无法安全前进或用户明确要求时评估回滚。
- 每个版本新建独立文档，历史版本不覆盖。

## 当前文件所有权

- `src/core/**`：玩法设计独占。
- `src/gameplay/**`、`tests/gameplay/**`、`data/cards/**`、`data/enemies/**`、`data/encounters/**`、`data/routes/**`、`data/rituals/**`：玩法设计。
- `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`：数值设计。
- `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`：UI 设计。
- `art/**`：美术。
- `src/app/**`、`src/infrastructure/**`、`data/schema/**`、`tests/infrastructure/**`：本地数据层开发。
- `tests/integration/**`、`assets/game/**`、`project.godot`：主协调者。
- `docs/**`、`AGENTS.md`：产品经理。
- 角色报告路径：`docs/reports/v0.5.0/<role>.md`。

## 当前验证结果

v0.4.0 已关闭并通过最终回归：

- 基础设施：150 项。
- 基础玩法：131 项。
- 成长玩法：90 项。
- UI：33 项。
- 成长 UI：41 项。
- 短循环集成：39 项。
- 数值合同：33 项。
- 经济合同：54 项。
- 主场景 headless 启动退出码 0。
- UI 已完成 v0.4 美术实际界面复审，原型范围通过。

## 当前开放问题

- 路线、休息、仪式和序列状态接口尚未冻结。
- 首领遭遇、精英遭遇和路线奖励尚待实现。
- 存档 v3 的节点级检查点与 v1/v2 迁移尚未实现。
- v0.5 UI、美术、路线采样和端到端测试尚未开始。

## 下一检查点

1. 玩法提交并实现固定路线、休息和三步晋升仪式语义。
2. 数值提交 30—45 分钟路线预算与首领/休息参数。
3. 数据层冻结路线、仪式、序列和存档 v3 schema。
4. UI 与美术独立生产，UI 必须在实际界面审稿美术。
5. app 接入节点级检查点和完整短路线。
6. 全量回归通过后关闭 v0.5.0，再评估后续章节。
