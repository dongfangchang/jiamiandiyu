# Tasks · product-manager

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### PM-05 · 确认 ADR-0032 的三项体验决定
- status: todo
- 来源: ADR-0032
- 内容: ① 继续先到桌面总览再推近；② 奖励 / 休息 / 结算并入日记页；③ 牌组和升级合并为卡匣站
- 完成标准: 用户确认，或提出修改（修改须开新 ADR）
- 阻塞: 用户

### PM-06 · v0.88 关版后开 v0.89（X1）
- status: blocked
- 阻塞: v0.88 自动化全绿，H-01…03 真窗口通过


### PM-01 · v0.87 关版裁决
- status: todo
- 来源: docs/versions/v0.87.0.md
- 改哪些: CURRENT_VERSION / VERSION_* / 版本文档状态；必要时 ADR
- 完成标准: 两项行为确认有结论；真窗抽查通过或显式结转；版本关闭或明确「仍验证中」
- 怎么验: 指针与报告一致
- 阻塞: 用户真窗抽查；焦点落在「合上」、挑战页无正文两项待确认

### PM-02 · ACTIVE_PLAN 与 CURRENT 指针对齐
- status: todo
- 来源: ACTIVE_PLAN 仍写 v0.86/R0，CURRENT 已 v0.87/R1
- 改哪些: `docs/ACTIVE_PLAN.md` 抬头与 §0
- 完成标准: 计划文件版本指针与 CURRENT_VERSION 一致；过期块归档
- 怎么验: 新人读 ORIENTATION→CURRENT→ACTIVE_PLAN 无矛盾
- 阻塞: 无

### PM-03 · 排期美术补洞 vs R2 开版
- status: todo
- 来源: art 建议；玩法 D 区冻结
- 改哪些: ACTIVE_PLAN / 下一版本文档范围（不实现代码）
- 完成标准: 写清哪些 ART/UI 可在整治期做、哪些必须开版
- 怎么验: 各角色 tasks 可对齐
- 阻塞: 无

### PM-04 · G-03 / 内容解冻是否开版
- status: todo
- 来源: ACTIVE_PLAN G-03、D-*
- 改哪些: 新 versions 或明确继续冻结
- 完成标准: 自动=否条目有明确「开/不开」
- 怎么验: 版本文档或 ACTIVE_PLAN 一句裁决
- 阻塞: 可在 v0.87 关后做

## 已完成（近期）

### PM-done-v084-v085 · 有条件关版
- status: done
- 证据: ACTIVE_PLAN §0；余项转 R0-11
