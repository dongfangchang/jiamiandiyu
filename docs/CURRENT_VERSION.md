# 当前开发版本

## 指针

- 当前版本：`v0.3.0`
- 阶段：单场战斗垂直切片
- 当前版本文档：`docs/versions/v0.3.0.md`
- 当前文档状态：执行中
- 更新日期：2026-11-08
- 前一版本：`v0.2.0`，有条件关闭

## 强制阅读

1. `AGENTS.md`
2. `docs/PROJECT_CHARTER.md`
3. `docs/TEAM_PROTOCOL.md`
4. `docs/ARCHITECTURE_CONTRACT.md`
5. `docs/versions/v0.3.0.md`

## 当前冻结规则

- 产品根目录固定为 `G:\guimizhizhu`。
- 单人、离线、Godot 4.7.2、GDScript。
- 本地“后端”只做存档、内容加载、RNG、日志、schema 和应用装配，不建设服务器。
- 抽卡只使用游戏内资源，本版本不实现抽卡流程。
- 首版采用逐张出牌 + 三列即时目标，单占卜家，序列 9 -> 8。
- 运行字段统一为 `corruption` 和 `attention`。
- 敌方压力按 ADR-0004 在第 5、7、9 回合开始时生效。
- v0.3.0 只保存战后检查点，不支持战斗中恢复。
- UI 只消费只读快照、事件和稳定原因码，不计算伤害、概率、合法性或胜负。
- 每个版本新建独立文档，历史文档不改写；紧急缺陷进入新补丁版本。
- Bug 按复现、根因、影响面、回滚/替换/根因修复、回归验证处理。

## 当前文件所有权

- `src/core/**`：玩法设计独占。
- `src/gameplay/**`、`tests/gameplay/**`、`data/cards/**`：玩法设计。
- `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`：UI 设计。
- `data/balance/**`、`tools/simulation/**`、`tests/simulation/**`：数值设计。
- `src/app/**`、`src/infrastructure/**`、`data/schema/**`、`tests/infrastructure/**`：本地数据层开发。
- `tests/integration/**` 与 `assets/game/**` 的一次性迁移：主协调者。
- `docs/**`、`AGENTS.md`：产品经理。

## 当前开放问题

- 玩法实现尚未按 ADR-0004 改为第 5/7/9 回合压力。
- 正式 `data/cards/**`、`data/enemies/**` 和遭遇数据尚未建立。
- UI 生产场景尚未消费真实 BattleSnapshot/Command，角色报告仍含 `pollution` 旧词。
- 真实战斗数值尚未采样，谨慎慢速构筑高胜率尚未解决。
- `art/assets/png/**` 到 `assets/game/**` 的受控迁移尚未执行。
- 启动、战斗、结算、保存和继续读取尚未形成一条真实链路。

## 下一检查点

1. 玩法和本地数据层确认正式内容 schema、端口映射与第 5/7/9 回合压力测试。
2. UI 使用真实快照完成静态可交互页面，不写规则。
3. 主协调者完成资源迁移并建立最小集成入口。
4. 数值设计运行真实战斗采样。
5. 产品经理关闭 v0.3.0 前逐项验证验收标准；未通过则记录阻塞，不直接创建后续功能版本。
