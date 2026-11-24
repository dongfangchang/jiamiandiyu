# Tasks · local-backend

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 第二次下发（用户反馈 → ADR-0034）**：①控件绑定文字，物件只是画面；②替换即删除，禁止遮挡或隐藏旧界面；③日记可读性底线和画面升级。当前版本 **v0.89.0**（`docs/versions/v0.89.0.md`），P0 条目优先于其他所有条目。主会话会定时轮询本文件：done 条目必须写证据（提交 SHA、截图路径、测试输出），主会话据此合并、推送并下发后续任务。

### LB-BUG-v1-resume · v1 存档能加载但无法继续游戏
- status: todo
- 来源: v0.88 T5 报告
- 做法: 先写 `docs/bugs/BUG-0039-*.md`（复现、根因：v1→v2 迁移重置进度、没有初始牌）；前向修复迁移，使 v1 存档迁移后能确认默认牌组
- 完成标准: `save_fixture_runner` 的 v1 用例能走完恢复步骤

### LB-BUG-seqstate · `route.sequence_state` 存成字符串、按字典读取
- status: todo
- 来源: v0.88 T5 报告
- 做法: 写 `docs/bugs/BUG-0040-*.md`；codec 写入字典并在读取时兼容字符串；补回归测试
- 完成标准: 读档后序列状态与存档前一致（黄金回放 11_checkpoint 只允许这一字段变化，在报告中说明）


> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### LB-R2-W2 · v0.88 第二波 T5：内容清单 + 存档 v6（R2-08、R2-11）
- status: done
- 证据/说明: T5 已合并（ba2e6d3），ADR-0033
- owner: 主会话（第一波合并后启动）——**勿重复**

### LB-X1-05 · `app/flow.gd` 推荐站位与"继续"流程
- status: todo
- 证据/说明: v0.89 已开版；"继续 → 总览 → 推荐站"；任何入口都是文字（ADR-0034）
- 来源: ROADMAP X1-05；EXPERIENCE §3
- 改哪些: `src/app/flow.gd`（新建）、`src/app/app_controller.gd` 中的继续 / 返回逻辑、`tests/integration/**`
- 完成标准: 继续 = TITLE → DESK（停 0.4 s）→ 推荐站；所有"返回"都到 DESK；判断写在 flow.gd 一处，UI 不判断
- 怎么验: 集成测试；黄金回放的规则部分不变
- 阻塞: v0.88 合并；与 UI-X1 同版协作（路由器接口由 UI 定义）


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
