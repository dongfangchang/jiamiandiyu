# 当前开发版本

## 指针

- 当前版本：`v0.89.0`
- 阶段：执行中
- 当前版本文档：`docs/versions/v0.89.0.md`
- ROADMAP 阶段：**X1 书桌世界 I ＋ 用户反馈 P0**（文字控件 / 删除旧界面 / 日记可读性与画面；ADR-0034）
- 更新日期：2026-11-24
- 前一版本：`v0.88.0`（验证中；H-03 被否决，由 X1-03 取代）
- 决策：`docs/decisions/ADR-0031-architecture-consolidation.md`
- **活跃计划（可勾销）**：`docs/ACTIVE_PLAN.md`
- **版本索引**：`docs/VERSION_INDEX.md`（里程碑 + 最近三版）
- **版本流水账**：`docs/VERSION_LOG.md`

## 强制阅读

0. `docs/ORIENTATION.md`（上手导读；新人先读）
1. `AGENTS.md`
2. `docs/versions/v0.89.0.md`
3. `docs/architecture/ROADMAP.md` §0 与 R2 一节
5. **任何 UI / 美术工作**：`docs/architecture/EXPERIENCE_ARCHITECTURE.md`（体验框架，违反即退回）
4. `docs/architecture/TARGET_ARCHITECTURE.md` §3–§4（改代码前）
6. `docs/ACTIVE_PLAN.md`
7. 查历史时优先 `VERSION_INDEX` / `VERSION_LOG`，勿通读全部 `versions/`

## 当前冻结规则

- 整治期行为不变：不新增卡牌、不扩展第二途径、不改公式和 `node_id`；只增加只读快照字段不算改规则（ADR-0031）。
- 主路径禁止新增原生 `OptionButton`；仪式失败不灭章。
- 提交与推送按 `PROJECT_CHARTER.md` §9：完成一个独立单元就提交并推送；强制推送等例外仍须用户同意。
- 跑测试：`tools/run_tests.sh`。
