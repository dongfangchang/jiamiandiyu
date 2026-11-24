# Tasks · architect

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

### AR-07 · 可读性测试补"遮挡"维度（P0-3 退回暴露的测试缺口）
- status: doing
- owner: architect 智能体（2026-11-24 轮询派工）
- 优先级: P0
- 来源: 2026-11-24 轮询。`diary_readability_runner` 全绿，但真窗口里正文被背景板遮住，测试只检查相机常量。
- 做法: 在 `diary_readability_runner`（headless 可跑）中，对左右页面网格的采样点（四角、题名、正文、蜡封）从相机做 `PhysicsRayQueryParameters3D` 射线检测，或按几何做"镜头 → 采样点"线段与站内其他可见网格包围盒的相交检测。命中页面以外的物体即判失败。必须在**装上质量层（DeskQuality）之后**的完整舞台上检测。
- 完成标准: 用 4d510ce 的背景板摆放能让测试失败，修好后通过

> **2026-11-24 第二次下发（用户反馈 → ADR-0034）**：①控件绑定文字，物件只是画面；②替换即删除，禁止遮挡或隐藏旧界面；③日记可读性底线和画面升级。当前版本 **v0.89.0**（`docs/versions/v0.89.0.md`），P0 条目优先于其他所有条目。主会话会定时轮询本文件：done 条目必须写证据（提交 SHA、截图路径、测试输出），主会话据此合并、推送并下发后续任务。

### AR-05 · 渲染器评估（gl_compatibility 对比 Forward+ / Mobile）→ ADR-0035
- status: done
- 优先级: P0（阻塞 UI-P0-3 的光照和后期）
- 来源: ADR-0034 D4
- 做法: CLI `--rendering-method` 切换三法；日记站同镜头 2920×1753 截图 + FPS；结论 ADR-0035。不合入 project.godot（交协调者落地）。
- 改哪些: `docs/decisions/ADR-0035-desk-world-renderer.md`、`docs/reports/v0.89.0/architect.md`、`docs/reports/v0.89.0/ar05_renderer/**`、`tools/architecture/ar05_*`
- 完成标准: ADR-0035 给出选择、理由和迁移代价；附截图对比
- 证据: 选择 **Forward+**（桌面默认）；Mobile=性能档；Compatibility=应急。ADR=`docs/decisions/ADR-0035-desk-world-renderer.md`；报告=`docs/reports/v0.89.0/architect.md`；缩略图=`docs/reports/v0.89.0/ar05_renderer/*_thumb.png`；全分辨率可复跑 `tools/architecture/ar05_run_compare.sh` → `.tools/ui-captures/ar05_renderer/`。FPS@M4/2920×1753：compat 20.2 / mobile 32.2 / forward+ 17.4。未改 `src/ui/**`。

### AR-06 · 评审 UI-X0-rev（ADR-0034 修订）
- status: todo
- 证据: UI-X0-rev 已交付（c954512），请评审
- 阻塞: UI-X0-rev

### AR-03b · 新守卫：遮罩和非文字按钮
- status: todo
- 证据: UI-P0-1 已合入；track A 已加阻断守卫（TitleOpenCover，标题文件中的 add_background / SceneBackgroundHolder）；剩余：标题站和总览站"非文字 BaseButton"的断言，可复用 title_station_runner
- 做法: run_tests 守卫：主路径禁止 `TitleOpenCover` / `*Cover` 遮罩；标题站和总览站除文字条目外不得有 `BaseButton`（用 UI 测试断言更可靠，与 UI 协作）
- 阻塞: UI-P0-1 合并


> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### AR-03 · 书桌世界守卫加入 run_tests
- status: todo
- 证据/说明: X1 已开版；`add_background(` 守卫先只对已改造的站位生效
- 来源: EXPERIENCE §8
- 改哪些: `tools/run_tests.sh` / `.ps1`
- 完成标准: `add_background(`（X2 后阻断）、`Color("#` 字面量（已改造的站位阻断）、过渡期间同步 load（由路由测试覆盖）
- 阻塞: X1 合并

### AR-04 · 评审 UI-X0 站位设计稿
- status: done
- 来源: EXPERIENCE §8；UI-X0 交付后评审
- 改哪些: `docs/reports/v0.88.0/architect.md`
- 完成标准: 结论 通过/有条件通过/退回；写清必须改的点；UI-X1 可否开工说明
- 怎么验: 对照 EXPERIENCE §2–§5/§8、DESK_WORLD_STATIONS、wireframes、ui.md、ADR-0032
- 证据: 初评**有条件通过**；2026-11-24 **条件确认通过**（`architect.md`「AR-04 条件确认」）。① 过渡表已补 TITLE→DOSSIER；② 墨/羽 (0.52,0.48)/(0.66,0.55)。烛台 (−0.95,−0.38) 接受。UI-X1：条件已清 + 道具已迁入（CO-X1）；**余阻 v0.88 合并**。


## 已完成（近期）

### AR-01 · R1 遗留项写入 ROADMAP/R2 拆分
- status: done
- 来源: v0.87.0 §4.1 遗留
- 改哪些: `docs/architecture/ROADMAP.md`、`docs/reports/v0.88.0/architect.md`
- 完成标准: app_controller 命名、route_ui_catalog 死代码、diary 超行、旧数据读取等有条目归属
- 怎么验: ROADMAP 可勾选；不改生产代码除非版本授权
- 证据: ROADMAP「R1 → R2/R3 遗留归属」+ R2-13 新增；R2-08/R3-06/R3-09 补注；摘要见 `docs/reports/v0.88.0/architect.md` AR-01

### AR-02 · R2 开版前边界评审清单
- status: done
- 来源: ADR-0031；R2 规则迁移/事实源合并
- 改哪些: `docs/architecture/ROADMAP.md`、`docs/reports/v0.88.0/architect.md`
- 完成标准: 跨层文件单一负责人表；黄金回放不变约束写清
- 怎么验: 产品 / 协调者派工时可直接勾选
- 证据: ROADMAP「R2 边界与黄金回放约束」可勾选表 + 四条硬约束；`architect.md` AR-02 摘要

### AR-done-ADR-0031 · 整治期决策落地文档
- status: done
- 证据: docs/decisions/ADR-0031；ROADMAP R0–R4
