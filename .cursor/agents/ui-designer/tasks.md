# Tasks · ui-designer

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### UI-H · v0.88 热修 H-01 卡图 / H-02 翻页预加载 / H-03 标题露旧面板
- status: doing
- owner: 主会话（v0.88 轨道 H）——**勿重复**；完成后由主会话标 done
- 来源: 用户 2026-11-24 反馈
- 改哪些: gacha_screen / upgrade_screen 取图、diary_desk_stage、title_desk_stage、start_screen
- 完成标准: 见 docs/versions/v0.88.0.md §1
- 怎么验: 轨道 H 报告 docs/reports/v0.88.0/ui_hotfix.md 的手动清单

### UI-X0 · 书桌世界站位设计稿（现在就可以做，不改 src）
- status: todo
- 来源: ADR-0032；ROADMAP X1
- 改哪些: 新建 `docs/design/DESK_WORLD_STATIONS.md`（本条授权 UI 写这一个设计文件）；线框图放 `assets/ui/wireframes/desk_world/`
- 完成标准:
  1. 桌面俯视布局图：日记、档案夹、卡匣、祈愿台、烛台、抽屉的位置和尺寸（世界单位），日记占视口宽 55–65%
  2. 七个站位的镜头位姿（位置 / 旋转 / fov），以现有日记镜头 `diary_desk_stage.gd:216-224`（pos 0,1.61,0.93；rot −59°；fov 38）为基准
  3. 每个站位的 2D 内容版式：title 书签纸条、dossier 两页（左：身份相片 + 姓名 + 序列；右：资源 / 局况 / 当前章）、desk 悬停题签
  4. 每个站位的进出过渡（T1–T4 中的哪一个）与输入状态（悬停 / 按下 / 禁用 / 锁定）
  5. 用现有素材拼一张总览示意截图
- 怎么验: 架构师评审通过（对照 EXPERIENCE §2–§5）；美术能按此定物件比例
- 阻塞: 无

### UI-X1 · v0.89 书桌世界 I 实现（X1-01…04、X1-06）
- status: blocked
- 来源: ROADMAP X1
- 改哪些: `src/ui/**`、`src/app/screen_router.gd`、`scenes/ui/**`、`tests/ui/**`
- 完成标准: ROADMAP X1 各行的"完成标准"；EXPERIENCE §8 验收
- 怎么验: run_tests 全绿 + 连续截图审查
- 阻塞: ① v0.88 合并（避免与主会话 R2 同改 src/ui）；② UI-X0 评审通过；③ ART-DW-X1 批交付并由 coordinator 迁入

### UI-X2 · v0.90 书桌世界 II（X2-01…05）
- status: blocked
- 阻塞: UI-X1 完成；ART-DW-X2 批交付

### UI-07 · 书桌世界美术审稿
- status: blocked
- 来源: ART_BRIEF_DESK_WORLD §4
- 改哪些: 审稿结论写入当版 UI 报告；退回清单按 DW-ID 写进 art/tasks.md 的请求区
- 完成标准: 每个 DW 物件结论为"过"或"退回加原因"
- 阻塞: 等 art 交付


### UI-01 · R0-11 日记八开真窗口审稿
- status: todo
- 来源: ACTIVE_PLAN R0-11；F-01 遗留
- 改哪些: 审稿记录进 `docs/reports/<ver>/ui.md`；退回清单按 scene_id 给 art
- 完成标准: 八开逐张观感结论（过/退回）；退回写清原因
- 怎么验: 真窗口截图或等价记录；V083 仍绿
- 阻塞: 无（资产已齐）

### UI-02 · 手牌卡面抽样 ≥4 + 蜡封锚点抽查
- status: todo
- 来源: ACTIVE_PLAN G-02/G-01 仍待
- 改哪些: UI 报告；必要时只读映射微调（不改规则）
- 完成标准: ≥4 张手牌真窗结论；蜡封叠层位置可接受或列退回 card_id
- 怎么验: 战斗内截图/记录
- 阻塞: 无

### UI-03 · NAV 真窗口验收清单收口
- status: todo
- 来源: v0.86 保留；`docs/reports/v0.86.0/ui.md`
- 改哪些: 报告勾选；发现回归再开修条目
- 完成标准: NAV-01…09 用户/本职真窗勾完
- 怎么验: 对照报告清单
- 阻塞: 部分需用户确认

### UI-04 · v0.87 真窗抽查路径
- status: todo
- 来源: docs/versions/v0.87.0.md §4
- 改哪些: 报告记录
- 完成标准: 新游戏→日记→战斗→hub；挑战→蜡封→战斗 无回归
- 怎么验: 真窗口走查
- 阻塞: 可与产品确认焦点/挑战正文两项并行

### UI-05 · G-03 检视弹层（开版后）
- status: blocked
- 来源: ACTIVE_PLAN G-03
- 改哪些: `src/ui/**` 检视弹层
- 完成标准: 手牌短句 + 居中弹层全文；检视无蜡封
- 怎么验: 点银质匕首见完整规则
- 阻塞: 须开版或产品授权（自动=否）

## 已完成（近期）

### UI-done-R0-05 · 战斗卡图 AR-01
- status: done
- 证据: ACTIVE_PLAN R0-05 ✅ 2026-11-24

### UI-done-BUG-0038 · 挑战日记回退开页
- status: done
- 证据: v0.87 R1-07；自动化覆盖
