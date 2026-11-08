# 当前开发版本

## 指针

- 当前版本：`v0.9.0`
- 阶段：本地试玩反馈与诊断
- 当前版本文档：`docs/versions/v0.9.0.md`
- 当前文档状态：已关闭，等待本地试玩反馈
- 更新日期：2026-11-08
- 前一版本：`v0.8.0`，已关闭

## 强制阅读

1. `AGENTS.md`
2. `docs/PROJECT_CHARTER.md`
3. `docs/TEAM_PROTOCOL.md`
4. `docs/ARCHITECTURE_CONTRACT.md`
5. `docs/versions/v0.9.0.md`

## 当前冻结规则

- 产品根目录固定为 `G:\guimizhizhu`。
- 单人、离线、Godot 4.7.2、GDScript。
- 本地“后端”只做存档、内容加载、RNG、日志、schema 和应用装配，不建设服务器。
- 抽卡只使用游戏内资源，不允许真实付费。
- 首版继续只使用占卜家；正式战斗卡池为 16 张。
- 首次晋升固定为占卜家序列 9 -> 序列 8「小丑」。
- 首版路线固定为三场战斗、一次休息和一次三步晋升仪式。
- 牌组固定为 8 张唯一卡牌，只能使用已拥有卡牌。
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
- 角色报告路径：`docs/reports/v0.9.0/<role>.md`。

## 当前验证结果

v0.7.0 已关闭并通过最终回归：

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
- 牌组合同：169 项。
- v0.7 后端：43 项。
- v0.7 牌组：178 项。
- v0.7 第二挑战：38 项。
- 牌组 UI：46 项。
- 主场景 headless 启动退出码 0。
- Windows 独立构建已重新导出，并在项目目录外启动退出码 0。
- UI 已完成 v0.7 卡组与第二挑战美术实际界面复审。

## 当前开放问题

- v0.8 的引导、设置、帮助与备份恢复已完成。
- v0.9 的本地诊断与游戏内反馈已完成。
- 下一版本方向必须以真实本地试玩反馈为依据。

## 下一检查点

1. 用户运行 `build/windows/MaskWhispers_v0.9.exe`。
2. 在游戏中保存至少一条反馈。
3. 读取 `user://diagnostics/session_*.json` 的真实时长、节点与结果。
4. 产品经理依据诊断数据决定 v1.0 的方向。
