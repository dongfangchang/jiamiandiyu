# 当前开发版本

## 指针

- 当前版本：`v0.4.0`
- 阶段：短循环开发
- 当前版本文档：`docs/versions/v0.4.0.md`
- 当前文档状态：执行中
- 更新日期：2026-11-08
- 前一版本：`v0.3.0`，已关闭

## 强制阅读

1. `AGENTS.md`
2. `docs/PROJECT_CHARTER.md`
3. `docs/TEAM_PROTOCOL.md`
4. `docs/ARCHITECTURE_CONTRACT.md`
5. `docs/versions/v0.4.0.md`

## 当前冻结规则

- 产品根目录固定为 `G:\guimizhizhu`。
- 单人、离线、Godot 4.7.2、GDScript。
- 本地“后端”只做存档、内容加载、RNG、日志、schema 和应用装配，不建设服务器。
- 抽卡只使用游戏内资源，不允许真实付费。
- 首版继续只使用占卜家和既有正式卡池。
- 运行字段统一为 `corruption` 和 `attention`。
- UI 只消费只读快照、事件和稳定原因码，不计算伤害、概率、保底、合法性和胜负。
- 美术与 UI 是独立角色；美术提交候选，UI 在实际界面审稿，美术不得自行验收。
- 普通缺陷默认前向根因修复；仅运行阻断、数据破坏、结构无法安全前进或用户明确要求时评估回滚。
- 每个版本新建独立文档，历史版本不覆盖。

## 当前文件所有权

- `src/core/**`：玩法设计独占。
- `src/gameplay/**`、`tests/gameplay/**`、`data/cards/**`、`data/enemies/**`、`data/encounters/**`：玩法设计。
- `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`：数值设计。
- `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`：UI 设计。
- `art/**`：美术。
- `src/app/**`、`src/infrastructure/**`、`data/schema/**`、`tests/infrastructure/**`：本地数据层开发。
- `tests/integration/**`、`assets/game/**`、`project.godot`：主协调者。
- `docs/**`、`AGENTS.md`：产品经理。
- 角色报告路径：`docs/reports/v0.4.0/<role>.md`。

## 当前验证结果

v0.3.0 已关闭并通过最终回归：

- 玩法：131 项。
- 基础设施：104 项。
- UI：21 项。
- 应用集成：30 项。
- 数值合同：33 项。
- 主场景 headless 启动退出码 0。
- UI 已完成 v0.3 美术实际界面复审，原型范围通过。

## 当前开放问题

- v0.4 身份、奖励、祈愿和升级的领域接口尚未冻结。
- 抽卡概率、单抽/三连成本、重复卡碎片和升级经济仍是待实现参数。
- 收藏、卡牌等级、占卜券和保底字段需要统一 schema 与迁移。
- v0.4 UI 与美术候选尚未开始。

## 下一检查点

1. 玩法提交身份、奖励、祈愿、升级状态机与命令草案。
2. 数值提交可复现经济草案，数据层冻结 schema。
3. UI 与美术按不同角色并行生产，UI 必须审稿美术。
4. app 接入完整短循环。
5. 全量回归通过后关闭 v0.4.0，再规划首次晋升版本。
