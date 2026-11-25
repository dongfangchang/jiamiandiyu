# Tasks · ui-designer

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-25**：用户要求**所有界面的目标帧都由用户拍板后再做实现**（ADR-0037）。在 `art/key_frames/<station>/approved.png` 出现之前，任何站位都不做画面风格实现。当前只做功能性条目：UI-CH-GREY、UI-RENDER-MOBILE。

> **2026-11-25 用户裁决**：渲染器 = Mobile（ADR-0036）；挑战未解锁时显示为灰色并写明原因；手牌通过；**标题页和日记页画面仍然太简陋 → ADR-0037"目标帧先行"：画面类实现暂停，先出概念图，由用户选定。**

### UI-CH-GREY · 挑战未解锁时显示为灰色并写明原因
- status: done
- owner: ui-designer 智能体（2026-11-25 轮询派工）
- 来源: 用户 2026-11-25 裁决
- 改哪些: `src/ui/start_screen.gd`、`tests/ui/title_station_runner.gd`
- 做法: 未解锁时，「挑战」条目照常列出，但为灰色、不可选中、不可聚焦；条目下方用小一号宋体显示 `get_challenge_hint_text()` 的原因。原因文字必须来自现有快照或文案表，不在 UI 里推导规则。
- 完成标准: 测试断言未解锁时条目可见、disabled、原因文字非空；解锁后正常可点
- 注意: 这是功能改动，不受 ADR-0037 画面暂停的限制
- 证据:
  - `start_screen.gd`：`_set_challenge_item` + `ChallengeHint` 20px 宋体
  - `title_station_runner`：锁定可见/FOCUS_NONE/hint 非空；解锁可点
  - `tools/run_tests.sh` → **pass=95 fail=0 skipped=14 guard_block=0**
  - 报告 `docs/reports/v0.89.0/ui.md` UI-CH-GREY 节
  - commit/push：`f898e33` → origin/main

### UI-RENDER-MOBILE · 切换到 Mobile 渲染器，并做与画面风格无关的必要校正
- status: done
- owner: ui-designer 智能体（2026-11-25 轮询派工；与 UI-CH-GREY 同批）
- 来源: ADR-0036 已采纳
- 改哪些: `project.godot`、`src/ui/diary_desk_quality.gd`、`src/ui/diary_desk_stage.gd`、wiring/capture runners
- 做法: 只做**保证不变差**的最小校正：
  - 曝光按 ADR-0036 的 Mobile 数值设置。
  - 页面材质 `specular_mode = SPECULAR_DISABLED`。
  - 保证正文对比度 ≥ 4.5（`diary_readability_runner` 全绿）。
  
  **不做风格调优**（色调、氛围都等目标帧）。
- 完成标准: run_tests 全绿；在 Mobile 下截一张 1600×900 日记图，亮度和可读性不低于当前 compatibility 截图
- 证据:
  - `project.godot` → `rendering_method=mobile` / `.mobile=mobile`
  - exposure RD=3.0；`SPECULAR_DISABLED`；SSAO 仅 forward_plus
  - `tools/run_tests.sh` → **pass=95 fail=0 skipped=14 guard_block=0**
  - 截图 `docs/reports/v0.89.0/ui_render_mobile_diary_1600x900.png`（method=mobile metal）
  - 报告 `docs/reports/v0.89.0/ui.md` UI-RENDER-MOBILE 节
  - commit/push：`f898e33` → origin/main


### UI-P0-3-renderer-hold · 渲染器待用户裁决，P0-3 先按"与渲染器无关"的调优做
- status: cancelled
- 说明（2026-11-25）: 用户已裁决用 Mobile → 改为 UI-RENDER-MOBILE
- 来源: 2026-11-24 轮询。ADR-0035（Forward+）和 ADR-0036 复核（Mobile + 调优）冲突，由用户裁决。
- 阻塞: 用户裁决 ADR-0035 vs ADR-0036（遮挡已清零）
- 做法:
  1. **在用户裁决前，不要提交 `project.godot` 的 rendering_method 改动。**（reject 修复已把 method 回 `gl_compatibility`）
  2. 先做与渲染器无关的调优（色调映射、环境光、烛光主光、页面材质 `specular_mode = SPECULAR_DISABLED`）。参数见 `tests/ui/renderer_eval_look.gd` 和 ADR-0036。
  3. 曝光与辉光混合方式按当前渲染器分支设置（ADR-0036 中有数值）。
  4. 任何渲染器下，正文对比度都必须 ≥ 4.5（ADR-0036 实测 Mobile 为 4.04，需要加深墨色或提亮纸色）。

### UI-P0-3-reject · 画面升级退回：背景板遮住书页，正文和题名不可见
- status: done
- owner: ui-designer 智能体（2026-11-24 轮询派工）
- 优先级: P0（最高）
- 方案: **(a) 远置直立** — `RoomBack` → `pos (0, 1.05, -1.72)` / `rot (0,0,0)`；D2：`attach_bookmark_ribbon` 单节点，删除 BookmarkProp/程序带构建与 `visible=false`
- 完成标准:
  1. 两种分辨率的截图中，右页题名、正文、蜡封和左页整幅插画都完整可见，与 P0-2 截图 `.tools/ui-captures/v089_readability/after/diary_1600x900_idle.png` 的书页取景一致（书宽 55–65%）；
  2. 删除旧书签节点（不是隐藏）；
  3. 完成 AR-07 的遮挡守卫测试并通过。
- 证据:
  - `tools/run_tests.sh` → **pass=95 fail=0 skipped=14 guard_block=0**
  - `diary_readability_runner` checks=43（含 AR-07 遮挡 clear）
  - `diary_quality_wiring_runner` checks=33（z=-1.72 / upright / 无 BookmarkProp）
  - 截图 `docs/reports/v0.89.0/ui_p0_3_fix_diary_{1600x900,2920x1753}.png`
  - 报告 `docs/reports/v0.89.0/ui.md` UI-P0-3-reject 节
  - `project.godot` rendering_method 保持 `gl_compatibility`（renderer-hold）

### UI-P0-3-sync · ⚠ 合入前必须先同步 origin/main（2026-11-24 轮询）
- status: done
- owner: ui-designer 智能体（2026-11-24 轮询派工）
- 优先级: P0，阻塞 UI-P0-3 提交
- 说明: origin/main 已合入 P0-2 可读性（b340186），它改了你正在工作区改的三个文件：
  - `diary_desk_stage.gd`：`_stage` 改为 TextureRect，世界视口按物理像素渲染，新镜头常量（俯角 −75°、3.0 m、fov 23°），物件后仰 45°
  - `diary_page_pair.gd`：`PAGE_SCALE = 2.0`，所有坐标经 `px()`，纸色调亮，墨色常量改动
  - `diary_chapter_screen.gd`：外框改用宋体，删除空的叶号行
  
  P0-1 标题站也已合入（`start_screen.gd` 重写）。逐项改动清单见 `docs/reports/v0.89.0/ui_readability.md`。
- 做法: 先提交你的工作区改动（可以是 WIP 提交），再 `git pull --rebase origin main` 解决冲突。**保留 P0-2 的可读性底线**（`diary_readability_runner` 必须全绿）。光照、材质、丝带书签叠加在新镜头之上；新镜头下后墙已不在画面内，DQ-01 背景板的摆放要按新镜头重新评估。
- 完成标准: run_tests 全绿（包括 diary_readability_runner）；然后再标 UI-P0-3 done
- 证据:
  - WIP→rebase：`4d510ce` on top of `b340186`；冲突手改三文件（保留 PAGE_SCALE/px/新镜头/INK_FADE_LOCKED；叠 DQ/丝带/FX）
  - DQ-01：`RoomBack` 后仰 −62° 贴书桌远沿（直立墙在 −75° 下出画）——**随后被主会话退回见 UI-P0-3-reject**
  - `tools/run_tests.sh` → **pass=95 fail=0 skipped=13 guard_block=0**；含 `diary_readability_runner` + `diary_quality_wiring_runner`
  - 截图刷新 `docs/reports/v0.89.0/ui_p0_3_fix_diary_{1600x900,2920x1753}.png`；报告 UI-P0-3-sync 节

### UI-P0-3-fix · 轮询发现（2026-11-24，架构师）：工作区当前状态未达合入门
- status: done
- owner: ui-designer 智能体（2026-11-24 轮询派工）
- 优先级: P0（在 UI-P0-3 标 done 前必须清零）
- 来源: 主会话轮询，对工作区跑 `tools/run_tests.sh` → pass=92 fail=1 guard_block=1
- 问题:
  1. **守卫阻断**：`src/ui/desk_world_catalog.gd:4` 的注释里写了 `res://assets/game/...`，命中"UI 资源路径字面量"守卫。注释里也不要写这个前缀（可改成"assets 路径"）。
  2. **测试失败**：`tests/ui/v085_diary_art_runner` 中"desk uses wood or paper fallback"和"dedicated wood replaces desk grain"两项。换成 DQ-02 PBR 桌面后，旧断言已不成立。按"替换即删除"规则改写为断言新的桌面材质（注册表 ID `desk.dq.desk_albedo` / normal / roughness），而不是保留旧路径。
  3. **渲染器**：`project.godot` 已在工作区改为 `forward_plus`（ADR-0035）。它是跨角色文件：请在 UI-P0-3 的同一提交里带上，并在报告中附 Forward+ 下的两种分辨率截图，以及 HiDPI 下的帧率（ADR-0035 实测全开 FX 约 17 fps，偏低：SSAO / 辉光参数要按帧率预算调，目标 ≥30 fps）。
  4. **协调**：主会话的 P0-2 可读性轨道同时在改 `diary_desk_stage.gd` / `diary_page_pair.gd`（页面视口 1024×1440、物理像素渲染）。P0-3 合入前须先 `git pull`，并在主会话合入 P0-2 之后再提交，避免互相覆盖。
- 完成标准: run_tests 全绿、守卫不阻断；Forward+ 截图和帧率写进报告
- 证据:
  - `tools/run_tests.sh` → **pass=94 fail=0 skipped=12 guard_block=0**
  - 截图 `docs/reports/v0.89.0/ui_p0_3_fix_diary_{1600x900,2920x1753}.png`
  - HiDPI fps avg=**37.4** (min 29 / max 41) @ 2920×1753 Forward+ Metal
  - 报告 `docs/reports/v0.89.0/ui.md` UI-P0-3-fix 节
  - **未 commit/push**：`git fetch` 后 origin/main 仍无 P0-2；`PAGE_VP_SIZE` 仍 512×720 → **等待主会话 UI-P0-2 合入**后再提交，避免覆盖


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
- status: done
- 证据: origin/main b340186（df07b21）；`start_screen.gd` 从 973 行减到 430 行，旧面板、隐形热区和 TitleOpenCover 全部删除；title_station_runner 163 项检查；主会话看过截图 `.tools/ui-captures/v089_title_focus_continue_1600x900.png`：只有纸条上的文字菜单，物件不可点；待用户真窗口确认
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
- status: done
- 证据: origin/main（045bd70）；diary_readability_runner 41 项检查；正文 22.6px、题名 29.1px、注脚 16.2px，对比度 5.47 / 5.31 / 4.06，阅读夹角 24.2°；截图在 `.tools/ui-captures/v089_readability/`；mipmap 在兼容渲染器下无效，改用超采样（切换到 Forward+ 后复测）
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
- status: blocked
- 说明（2026-11-25）: ADR-0037：画面类实现暂停，等 ART-KEY 目标帧由用户签字。已合入的遮挡修复（9429ae0）和可读性保留
- owner: ui-designer 智能体（2026-11-24；未覆盖主会话 P0-1/P0-2/P1-1/X0-rev）
- 优先级: P0
- 来源: 用户反馈"画风太简陋"；ADR-0034 D4
- 改哪些: `src/ui/diary_desk_stage.gd`、`src/ui/diary_desk_quality.gd`、`src/ui/desk_world_catalog.gd`、`src/ui/diary_page_pair.gd`、`src/ui/diary_chapter_screen.gd`（仅合上书签）、`tests/ui/diary_quality_wiring_runner.*`
- 做法: 接入 DQ-01…06；ACES/glow/SSAO；丝带「合上」取代红块；右页 DQ-04 + 蜡封 caption
- 完成标准: 实现与探针绿；用户真窗认可截图（待签字）
- 阻塞: ADR-0037 目标帧签字（ART-KEY）后再续画面实现；reject/Mobile 已合入
- 注意: 可读性参数留给 UI-P0-2；DQ-04 相对锚点可叠加 PAGE_VP 抬升
- 证据:
  - `docs/reports/v0.89.0/ui.md` UI-P0-3 / UI-P0-3-fix / UI-P0-3-sync / UI-P0-3-reject 节
  - reject 后 `run_tests` **pass=95 fail=0 skipped=14 guard_block=0**（含 readability 遮挡）
  - 截图刷新 `ui_p0_3_fix_diary_*.png`（书页完整可见）
  - 待用户真窗签字

### UI-X0-rev · 按 ADR-0034 修订站位设计稿
- status: done
- 证据: c954512 DESK_WORLD_STATIONS 修订（文字控件、索引卡、交互状态表）；待 AR-06 评审
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
- status: blocked
- 说明（2026-11-25）: 功能部分（常驻 DeskWorld、站位切换、文字入口）可以做；画面风格部分等目标帧。UI-RENDER-MOBILE 已 done，渲染器冲突解除；画面仍受 ADR-0037 约束
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
