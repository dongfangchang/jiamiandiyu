# Tasks · ui-designer

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

### UI-07-DQ · 日记站画面升级 DQ-01…06 审稿
- status: done
- 来源: ART-DQ 交付；ART_BRIEF_DESK_WORLD §5；ADR-0034 D3/D4；用户 2026-11-24
- 改哪些: `docs/reports/v0.89.0/ui.md` 审稿表；若退回则 `art/tasks.md` 请求区；全过则请求 coordinator CO-DQ
- 完成标准: DQ-01…06 逐项过/退回（尺寸、透明、无字、BRIEF 语义）；全过则请求 CO-DQ 迁入
- 怎么验: sips/PIL 尺寸+alpha；读 PNG 目视；对照 BRIEF §5 + 总览
- 阻塞: 无
- 备注: **勿**动 owner:主会话 UI-P0-1/P0-2/P1-1；**勿**自行迁 assets/game
- 证据:
  - `docs/reports/v0.89.0/ui.md` UI-07-DQ 表：**DQ-01…06 全部过**；无 ART-DQ-fix
  - 度量：尺寸全对齐；DQ-02 albedo/rough 接缝 mae=0；DQ-06×14 与物件同尺寸；RGBA 关键件四角 α=0
  - 跨角色：请 **CO-DQ** 迁入（含 index_card）

### UI-07-07b · 索引卡 DW-07b 审稿
- status: done
- 来源: ART-DW-07b 交付；ADR-0034 D1；DESK_WORLD_STATIONS
- 改哪些: 同 UI-07-DQ 报告表；退回则 art/tasks；全过并入 CO-DQ
- 完成标准: 600×900、6 行空白书写线、无字、四角透明；与 DW-07 同族
- 怎么验: PIL + 目视
- 阻塞: 无
- 备注: 与 UI-07-DQ 同批；勿迁 assets/game
- 证据: `ui.md` UI-07-07b：**过**；600×900；6 行；无字；四角 α=0；并入 CO-DQ

### UI-P1-1 · BUG-0041 战斗手牌插画被挤压
- status: done
- 证据: 合并 f046e7c；`battle_hand_card_face_runner` 314 项检查；截图 `.tools/ui-captures/v089_battle_hand_{1600x900,1100x700}_{before,after}.png`（主会话已看图：插画完整、比例正确、不可出牌的卡变暗）；待用户真窗口确认
- owner: 主会话（2026-11-24 起执行，**角色智能体勿重复开工、勿改相关文件**；完成后主会话标 done）
- 来源: 用户 2026-11-24；`docs/bugs/BUG-0041-battle-hand-card-art-squashed.md`
- 改哪些: `src/ui/battle_screen.gd`（手牌和飞卡）、`src/ui/common/card_face.gd`、`tests/ui/**`
- 完成标准: 见 BUG 文档的回归测试


> **2026-11-24 第二次下发（用户反馈 → ADR-0034）**：①控件绑定文字，物件只是画面；②替换即删除，禁止遮挡或隐藏旧界面；③日记可读性底线和画面升级。当前版本 **v0.89.0**（`docs/versions/v0.89.0.md`），P0 条目优先于其他所有条目。主会话会定时轮询本文件：done 条目必须写证据（提交 SHA、截图路径、测试输出），主会话据此合并、推送并下发后续任务。

### UI-P0-1 · 标题站：删除旧面板，改为文字菜单（取代被否决的 H-03 方案）
- status: doing
- 证据/说明: - owner: 主会话（2026-11-24 起执行，**角色智能体勿重复开工、勿改相关文件**；完成后主会话标 done）
- 优先级: P0（最先做）
- 来源: 用户反馈；ADR-0034 D1/D2；v0.89 P0-1
- 改哪些: `src/ui/start_screen.gd`、`src/ui/title_desk_stage.gd`、`scenes/ui/start_screen.tscn`、`tests/ui/**`
- 做法:
  1. **删除** `start_screen` 的整套旧布局（标题、说明、存档摘要面板、恢复备份 / 测试档案 / 设置等按钮、雨夜底图、`SceneDim`）以及只为它存在的代码；删除 `TitleOpenCover` 和隐形热区绑定（`bind()` 的再托管机制）。
  2. 标题站 = 合上的书（DW-05）+ 书签纸条（DW-04）。纸条上用思源宋体写存档摘要（身份 · 序列 · 上次保存），以及文字菜单「继续 / 新的日记 / 挑战 / 设置 / 离开」。恢复备份放进"设置"的二级纸签；测试档案只在调试构建中出现。
  3. 物件不可点；文字条目悬停或聚焦时，对应物件提亮。
  4. 开书动画只播放书的推近，然后交给路由器淡出；不再需要遮罩。
- 完成标准: 标题场景树中除文字菜单条目外没有任何 `BaseButton`；`grep -n 'TitleOpenCover\|SceneBackgroundHolder' src/ui` 为空；集成测试按文字找到菜单并能走通继续 / 新游戏 / 挑战。
- 怎么验: run_tests 全绿；两种分辨率截图写进 `docs/reports/v0.89.0/ui.md`。
- 阻塞: 无

### UI-P0-2 · 日记可读性底线
- status: doing
- 证据/说明: - owner: 主会话（2026-11-24 起执行，**角色智能体勿重复开工、勿改相关文件**；完成后主会话标 done）
- 优先级: P0
- 来源: 用户反馈"字都看不清"；ADR-0034 D3；EXPERIENCE §5.1
- 改哪些: `src/ui/diary_desk_stage.gd`、`src/ui/diary_page_pair.gd`、`src/ui/diary_chapter_screen.gd`（外框文字）、`tests/ui/**`
- 已查明的原因:
  - `diary_page_pair.gd:20` 中 `PAGE_VP_SIZE = 512×720`。
  - `diary_desk_stage.gd:272` 中世界视口按逻辑 1600×900 渲染，在 2920×1753 窗口上被放大。
  - 注脚 16px、符文说明 16px、叶号 18px，贴到斜页上后只剩约 8–10px。
  - 镜头俯角 −59°，页面被压扁。
- 做法: 世界视口按物理像素渲染；页面视口 ≥1024×1440，所有页内字号随之放大；页面材质开 mipmap 和各向异性过滤；调整镜头或加悬停推近，使书页与视线夹角 ≤25°；外框文字（左上卷名、底部提示）改用思源宋体并放大，或删掉冗余项。
- 完成标准: §5.1 每一项达标；自动化测试断言视口尺寸 = 物理像素、页面视口 ≥1024×1440。
- 怎么验: 1600×900 和 2920×1753 两张截图（不加 `--headless`）；原尺寸下正文可读。
- 阻塞: 无

### UI-P0-3 · 日记站画面升级（光照、后期、右页版式、丝带书签）
- status: todo
- 优先级: P0
- 来源: 用户反馈"画风太简陋"；ADR-0034 D4
- 改哪些: `src/ui/diary_desk_stage.gd`、`src/ui/diary_page_pair.gd`、`tests/ui/**`
- 做法: 接入 DQ-01 背景板、DQ-02 桌面 PBR、DQ-03 书皮和书口、DQ-04 右页装饰、DQ-05 丝带书签（上面写"合上"，取代红色平面块）、DQ-06 接触阴影；按渲染器结论调整光照和后期（色调映射、辉光、暗角）；右页版式：页眉饰、极淡横线、题名、正文、页角饰，蜡封带文字。
- 完成标准: 用户认可前后对比截图。
- 阻塞: 无（AR-05 / UI-07-DQ / CO-DQ / Forward+ 均已齐）
- 注意: `diary_desk_stage.gd` 可能与主会话 UI-P0-2 同文件——先读再改，避免覆盖可读性改动

### UI-X0-rev · 按 ADR-0034 修订站位设计稿
- status: doing
- 证据/说明: - owner: 主会话（2026-11-24 起执行，**角色智能体勿重复开工、勿改相关文件**；完成后主会话标 done）；与 UI-P0-1 同一轨道
- 优先级: P0（X1 实现前完成）
- 改哪些: `docs/design/DESK_WORLD_STATIONS.md` §3.1、§3.3 及交互状态表
- 做法: 标题站改为纸条上的文字菜单；总览站把"悬停物件出题签"改为桌角索引卡的文字条目，条目悬停时联动提亮物件；明确所有站位"物件不可点"。
- 完成标准: 架构师 AR-06 评审通过


> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### UI-H · v0.88 热修 H-01 卡图 / H-02 翻页预加载 / H-03 标题露旧面板
- status: done
- 证据/说明: H-01、H-02 已合并（v0.88，f594848 之前）；H-03 被用户否决 → UI-P0-1
- owner: 主会话（v0.88 轨道 H）——**勿重复**；完成后由主会话标 done
- 来源: 用户 2026-11-24 反馈
- 改哪些: gacha_screen / upgrade_screen 取图、diary_desk_stage、title_desk_stage、start_screen
- 完成标准: 见 docs/versions/v0.88.0.md §1
- 怎么验: 轨道 H 报告 docs/reports/v0.88.0/ui_hotfix.md 的手动清单

### UI-X0 · 书桌世界站位设计稿（现在就可以做，不改 src）
- status: done
- 来源: ADR-0032；ROADMAP X1
- 改哪些: 新建 `docs/design/DESK_WORLD_STATIONS.md`（本条授权 UI 写这一个设计文件）；线框图放 `assets/ui/wireframes/desk_world/`
- 完成标准:
  1. 桌面俯视布局图：日记、档案夹、卡匣、祈愿台、烛台、抽屉的位置和尺寸（世界单位），日记占视口宽 55–65%
  2. 七个站位的镜头位姿（位置 / 旋转 / fov），以现有日记镜头 `diary_desk_stage.gd:216-224`（pos 0,1.61,0.93；rot −59°；fov 38）为基准
  3. 每个站位的 2D 内容版式：title 书签纸条、dossier 两页（左：身份相片 + 姓名 + 序列；右：资源 / 局况 / 当前章）、desk 悬停题签
  4. 每个站位的进出过渡（T1–T4 中的哪一个）与输入状态（悬停 / 按下 / 禁用 / 锁定）
  5. 用现有素材拼一张总览示意截图
- 怎么验: 架构师评审通过（对照 EXPERIENCE §2–§5）；美术能按此定物件比例
- 证据: `docs/design/DESK_WORLD_STATIONS.md`；`assets/ui/wireframes/desk_world/{00..04}*`；报告 `docs/reports/v0.88.0/ui.md` §10；请求 architect AR-04

### UI-X0-fix · AR-04 条件清零
- status: done
- 来源: docs/reports/v0.88.0/architect.md（有条件通过）
- 改哪些: `docs/design/DESK_WORLD_STATIONS.md` §1/§4；`assets/ui/wireframes/desk_world/00_topdown_layout.svg`；`03_transitions.md`；`docs/reports/v0.88.0/ui.md`
- 完成标准:
  1. 过渡表补新游戏 TITLE→DOSSIER（T1）及建档后续 CARDBOX→DIARY（直达，不经 DESK 0.4s）
  2. 墨水/羽笔改到卡匣·祈愿台·抽屉 AABB 外，俯视线框标注
- 怎么验: architect 短评确认条件清零
- 证据: DESK_WORLD_STATIONS §1/§4；00_topdown + 03_transitions；ui.md「AR-04 条件已清」；请 architect 确认

### UI-X1 · v0.89 书桌世界 I 实现（X1-01…04、X1-06）
- status: todo
- 证据/说明: 阻塞已解除（v0.88 已合并，X0 已评审，X1 美术已迁入）；排在 UI-P0-1、UI-P0-2、UI-X0-rev 之后
- 来源: ROADMAP X1
- 改哪些: `src/ui/**`、`src/app/screen_router.gd`、`scenes/ui/**`、`tests/ui/**`
- 完成标准: ROADMAP X1 各行的"完成标准"；EXPERIENCE §8 验收
- 怎么验: run_tests 全绿 + 连续截图审查
- 阻塞: ① v0.88 合并（避免与主会话 R2 同改 src/ui）；② UI-X0 **AR-04 已通过**；③ X1 道具 **已迁入** `assets/game/desk_world/`（CO-X1 done）

### UI-X2 · v0.90 书桌世界 II（X2-01…05）
- status: blocked
- 阻塞: UI-X1 完成（X2 美术已交付且 **CO-X2 已迁入**）

### UI-07 · 书桌世界美术审稿
- status: done
- 来源: ART_BRIEF_DESK_WORLD §4
- 改哪些: 审稿结论写入当版 UI 报告；退回清单按 DW-ID 写进 art/tasks.md 的请求区
- 完成标准: 每个 DW 物件结论为"过"或"退回加原因"
- 证据: 初审退回 DW-01 open / DW-06；**复审 2026-11-24 全过**（`ui.md` UI-07 复审）；可请 coordinator 迁入

### UI-07-recheck · FIX 复审
- status: done
- 证据: open 为皮夹双页；烛台 alpha xor=0；README 7/7

### UI-07-X2 · 书桌世界 X2 审稿（DW-11…18）
- status: done
- 来源: ART-DW-X2 交付；ART_BRIEF_DESK_WORLD §2/§4
- 改哪些: `docs/reports/v0.88.0/ui.md` 审稿表；若退回则 `art/tasks.md` 请求区 + ART-DW-X2-fix
- 完成标准: DW-11…18 逐项过/退回（尺寸、透明、无字、开合轮廓、墨迹灰度中心白、页框中心透明）；全过则请求 coordinator 迁 X2
- 怎么验: sips/PIL 尺寸+alpha；读 PNG 目视；对照 BRIEF §0/§2/§4 + 总览
- 阻塞: 无
- 备注: **勿**动 UI-H；**勿**开 UI-X1 生产码；**勿**自行迁 assets/game
- 证据:
  - `docs/reports/v0.88.0/ui.md` UI-07-X2 表：**DW-11…18 全部过**；无 ART-DW-X2-fix
  - 度量：尺寸全对齐；altar 外围 xor=0；ink_mask L+中心白；page_frames 中心透明 100%；battle_cloth 接缝 mae=0
  - 跨角色：~~CO-X2~~ **done**（26 PNG → `assets/game/desk_world/`）

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
