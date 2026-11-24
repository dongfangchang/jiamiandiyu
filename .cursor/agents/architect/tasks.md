# Tasks · architect

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

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
