# Tasks · local-backend

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

### LB-01 · R1 轨道 A 收尾确认
- status: todo
- 来源: v0.87 轨道 A
- 改哪些: 报告；若有残留 legacy 引用再开修条
- 完成标准: bootstrap/campaign/game_session/migrations 无回归；测试绿
- 怎么验: run_tests 基础设施相关；报告勾选
- 阻塞: 无

### LB-02 · app_controller 路由命名债登记（不擅自大改）
- status: todo
- 来源: v0.87 §4.1 遗留
- 改哪些: 本角色报告「跨角色请求」→ 架构/产品排 R2
- 完成标准: 问题与建议入口写清；代码改动等版本授权
- 怎么验: 报告可见
- 阻塞: R2 授权前不重构

### LB-03 · 存档/迁移在 R2 的预读清单
- status: blocked
- 来源: ROADMAP R2
- 改哪些: 仅报告清单
- 完成标准: save_version / schema 触点列表
- 怎么验: 架构师可评审
- 阻塞: 产品开 R2

## 已完成（近期）

### LB-done-R1-A · 应用层 legacy 清理
- status: done
- 证据: v0.87 §4.1 行数下降；轨道 A
