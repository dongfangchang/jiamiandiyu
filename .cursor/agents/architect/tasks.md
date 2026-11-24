# Tasks · architect

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### AR-03 · 书桌世界守卫加入 run_tests
- status: blocked
- 来源: EXPERIENCE §8
- 改哪些: `tools/run_tests.sh` / `.ps1`
- 完成标准: `add_background(`（X2 后阻断）、`Color("#` 字面量（已改造的站位阻断）、过渡期间同步 load（由路由测试覆盖）
- 阻塞: X1 合并

### AR-04 · 评审 UI-X0 站位设计稿
- status: blocked
- 阻塞: UI-X0 交付


### AR-01 · R1 遗留项写入 ROADMAP/R2 拆分
- status: todo
- 来源: v0.87.0 §4.1 遗留
- 改哪些: `docs/architecture/ROADMAP.md`、必要时 TARGET / ADR 起草
- 完成标准: app_controller 命名、route_ui_catalog 死代码、diary 超行、旧数据读取等有条目归属
- 怎么验: ROADMAP 可勾选；不改生产代码除非版本授权
- 阻塞: 无

### AR-02 · R2 开版前边界评审清单
- status: todo
- 来源: ADR-0031；R2 规则迁移/事实源合并
- 改哪些: architecture 文档评审笔记
- 完成标准: 跨层文件单一负责人表；黄金回放不变约束写清
- 怎么验: 产品开 R2 时可直接派工
- 阻塞: v0.87 关版或产品明确开 R2

## 已完成（近期）

### AR-done-ADR-0031 · 整治期决策落地文档
- status: done
- 证据: docs/decisions/ADR-0031；ROADMAP R0–R4
