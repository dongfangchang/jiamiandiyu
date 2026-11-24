# Tasks · gameplay-designer

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### GD-R2 · v0.88 R2 第一波 T1/T2/T3（战斗 / 路线日记 / 成长牌组）
- status: doing
- owner: 主会话——**勿重复**

### GD-X3-02 · 日记卷 / 章 / 扉页 / 终章数据结构
- status: blocked
- 来源: ROADMAP X3-02；EXPERIENCE §6
- 改哪些: `data/diaries/**`、日记 schema、内容校验
- 完成标准: 每章都有扉页开和终章开；每开都有插画键；校验能报告缺失
- 阻塞: X2 完成后开版


### GP-01 · 内容冻结守门（整治期）
- status: doing
- 来源: ADR-0031；ACTIVE_PLAN D 区
- 改哪些: 无（禁止改 cards/enemies/encounters/公式/node_id）；报告中拒绝越权请求
- 完成标准: 未开版前无内容漂移；候选点子只进报告候选池
- 怎么验: git diff 无违规路径
- 阻塞: 无（持续）

### GP-02 · R2 规则迁移预读（只文档/清单）
- status: todo
- 来源: ROADMAP R2；v0.87 遗留旧数据 runner
- 改哪些: 玩法报告中的迁移清单草稿（不改生产规则）
- 完成标准: 列出将动的 data/src/gameplay 文件与风险
- 怎么验: 架构师/产品可据此开版
- 阻塞: 产品未开 R2 前不改代码

### GP-03 · 解冻模板：D-01 新卡全链路（开版后复制）
- status: blocked
- 来源: ACTIVE_PLAN D-01
- 改哪些: data/cards 等（开版后）
- 完成标准: 定义+池+牌组+升级齐
- 怎么验: 内容加载 + 局内
- 阻塞: 须新版本文档授权

## 已完成（近期）

### GP-done-R0-04 · 黄金回放配合
- status: done
- 证据: tests/golden/；ACTIVE_PLAN R0-04 ✅
