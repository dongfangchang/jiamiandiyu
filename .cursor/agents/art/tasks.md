# Tasks · art

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-25 用户裁决**：渲染器 = Mobile（ADR-0036）；挑战未解锁时显示为灰色并写明原因；手牌通过；**标题页和日记页画面仍然太简陋 → ADR-0037"目标帧先行"：画面类实现暂停，先出概念图，由用户选定。**

### ART-KEY-01 · 三个风格方向的目标帧概念图（标题页 + 日记页）
- status: todo
- 优先级: **P0（最高）**
- 来源: ADR-0037 D1；用户"改了几版都不满意"
- 改哪些: `art/key_frames/directions/<A|B|C>/{title,diary}.png` + `README.md`；拼一张总览 `art/key_frames/directions/overview.png`（3 行 × 2 列，每格标方向名）
- 要求:
  - 每张都是 **1600×900 的完整画面**，不是单个物件：要有统一光源、统一透视、统一色温，以及最终的文字位置（用真实文案：标题页是存档摘要加文字菜单「继续 / 新的日记 / 挑战（灰，附原因）/ 设置 / 离开」；日记页是左插画、右页题名、正文、蜡封「启」）。
  - 三个方向必须**明显不同**，建议：
    - **A 油画暗室**：伦勃朗式明暗，烛光是唯一主光；桌面杂物密集（信件、怀表、塔罗、烟斗、蜡滴）；背景是书架和雨夜窗。
    - **B 铜版插画书**：整个画面像 19 世纪铜版或木刻插图，墨褐单色加局部金色；线条和网点质感，书页与环境同一种画法。
    - **C 立体透视舞台**：低机位斜看桌面，景深明显；窗外廷根街灯和雨，室内体积光和灰尘；书离镜头近。
  - 世界观：诡秘之主·廷根 1840s 风格（维多利亚 / 蒸汽 / 神秘学）；**插画内不得画出界面文字以外的字**。
  - 文字统一用思源宋体，正文在原尺寸下清晰可读（ADR-0034 §5.1）。
- 完成标准: 6 张图加总览齐全；README 写清每个方向的光源、色板（5 个色值）、材质关键词、实现难度（3D 程序 / 分层绘制）
- 怎么验: 交给用户挑选（主会话转达）；**不需要 UI 审稿**
- 阻塞: 用户提供的参考图（如有）放在 `art/key_frames/references/`。没有参考图也先出图，不要等。

### ART-KEY-02 · 按用户批注修改，直到签字
- status: blocked
- 阻塞: ART-KEY-01 交付后用户选出方向并批注
- 完成标准: `art/key_frames/{title,diary}/approved.png` 由用户签字（主会话在 v0.89 版本文档登记）


> **2026-11-24 第二次下发（用户反馈 → ADR-0034）**：①控件绑定文字，物件只是画面；②替换即删除，禁止遮挡或隐藏旧界面；③日记可读性底线和画面升级。当前版本 **v0.89.0**（`docs/versions/v0.89.0.md`），P0 条目优先于其他所有条目。主会话会定时轮询本文件：done 条目必须写证据（提交 SHA、截图路径、测试输出），主会话据此合并、推送并下发后续任务。

### ART-DQ · 日记站画面升级批（DQ-01…06）
- status: done
- 优先级: P0（高于 ART-DW-X3、ART-02…05）
- 来源: 用户反馈"画风太简陋"；`docs/design/ART_BRIEF_DESK_WORLD.md` §5
- 改哪些: `art/assets/raster/desk_world/diary_quality/<DQ-id>/`（每项一个目录加 README）
- 完成标准: 书房背景板（正视，3840×2160）；桌面 PBR 三张图（2048 无缝）；书皮和书口；右页装饰套；丝带书签；接触阴影。规格与 §5 一致。
- 怎么验: 拼一张"现状截图 vs 资产示意"对比图，放进 `docs/reports/v0.89.0/art.md`；交给 UI 审稿
- 阻塞: 无
- 证据:
  - DQ-01 `diary_quality/dq01/room_backplate.png` @3840×2160
  - DQ-02 `dq02/desk_{albedo,normal,roughness}.png` @2048
  - DQ-03 `dq03/cover_{albedo,normal}.png` + `fore_edge.png` @1024×128
  - DQ-04 `dq04/` 页眉/四角×4/横线/涂鸦×6/墨渍×4
  - DQ-05 `dq05/ribbon_bookmark.png` @160×900 (+shadow)
  - DQ-06 `dq06/contact_shadow_*.png` ×14
  - 总览 `_overview/diary_quality_dq_overview_2048.png`
  - 示意对比 `docs/reports/v0.89.0/art_dq_before_after_schematic.png`
  - 报告 `docs/reports/v0.89.0/art.md`
- 跨角色请求: 请 **ui-designer** 审 DQ；真窗口对比后请 **coordinator** 迁入；勿美术自迁
- 备注: 2026-11-24 首轮交付；未迁 assets/game；未碰 owner:主会话 UI

### ART-DW-07b · 索引卡（桌面总览的文字入口底纸）
- status: done
- 来源: ADR-0034 D1
- 改哪些: `art/assets/raster/desk_world/index_card/`
- 完成标准: 600×900 正俯视索引卡，留 6 行空白书写行，无字，透明底；与 DW-07 同族
- 阻塞: 无
- 证据:
  - `index_card/index_card.png` + `index_card_shadow.png` @600×900
  - README：`index_card/README.md`
  - 报告：`docs/reports/v0.89.0/art.md`
- 跨角色请求: 请 UI 与 DQ 一并审稿；迁入同 coordinator
- 备注: 2026-11-24 与 ART-DQ 并行完成


> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### ART-DW-X1 · 书桌世界 X1 批（DW-01…07）
- status: done
- 来源: ADR-0032；`docs/design/ART_BRIEF_DESK_WORLD.md` §1
- 改哪些: `art/assets/raster/desk_world/<object>/`（每个物件一个目录加 README）
- 完成标准: 身份档案夹（开 / 合）、档案内页纸、相片框、书签纸条、合上的日记封面、烛台三帧、悬停题签全部交齐；正俯视、透明底、无字；阴影单独出图
- 怎么验: 尺寸和透明度核对；放进一张 2048 总览拼贴，对照 §4 自查；交给 ui-designer UI-07 审稿
- 阻塞: 无（规格已经定死为正俯视，不依赖镜头参数）
- 证据:
  - `art/assets/raster/desk_world/dossier/{closed,open}.png` + shadows
  - `art/assets/raster/desk_world/page/page.png` + shadow
  - `art/assets/raster/desk_world/photo_frame/photo_frame.png` + shadow（中心透明）
  - `art/assets/raster/desk_world/slip/slip.png` + shadow
  - `art/assets/raster/desk_world/book_closed/book_closed.png` + shadow
  - `art/assets/raster/desk_world/candle/{candle_lit,candle_out,smoke}.png` + shadows
  - `art/assets/raster/desk_world/tag/tag.png` + shadow
  - 总览: `art/assets/raster/desk_world/_overview/desk_world_x1_overview_2048.png`
  - 报告: `docs/reports/v0.88.0/art.md`
- 跨角色请求: 请 **ui-designer** 做 **UI-07** 审稿（按 DW-ID）；`DESK_WORLD_STATIONS.md` 若已出请标需改比例的 ID
- 备注: 2026-11-24 完成；站位稿未出，按 BRIEF 表尺寸；未迁 `assets/game`

### UI→art 请求区 · UI-07-DQ / UI-07-07b（2026-11-24）— **全过，无强制退回**
> 来自 ui-designer；详 `docs/reports/v0.89.0/ui.md`。请 coordinator **CO-DQ** 迁入。

| ID | 结论 | 原因 / 要做什么 |
|---|---|---|
| DQ-01…06 | **过** | 尺寸/透明/无字/BRIEF §5 语义齐 |
| DW-07b | **过** | 600×900；6 行空白线；无字；四角 α=0 |
| （可选微修） | 非阻塞 | `page_corner_tr` ↔ `page_corner_bl` 文件名建议互换；`fore_edge` 纸层横纹可再加强 |

### UI→art 请求区 · UI-07 退回（2026-11-24）— **已清零（复审全过）**
> 来自 ui-designer UI-07；比例锚见 `docs/design/DESK_WORLD_STATIONS.md` §5。

| DW-ID | 结论 | 原因 / 要做什么 |
|---|---|---|
| **DW-01 open** | **过（复审）** | 皮夹展开 + 左右空白公文纸 + 铜扣/标签族 |
| **DW-06 lit/out** | **过（复审）** | lit←out 母版叠焰；alpha xor=0 |
| DW-01 closed | 过 | 皮夹+铜扣+空白标签位；尺寸 800×1100 |
| DW-02 | 过 | 偏冷公文纸+淡横线；1024 平铺 |
| DW-03 | 过 | 回形针框、中心透明；600×800 |
| DW-04 | 过 | 空白纸条 700×260 |
| DW-05 | 过 | 合书烫金框无字；1400×1000 |
| DW-06 smoke | 过 | 有独立烟帧 |
| DW-07 | 过 | 空白题签 360×120 |
| （批次） | **已补** | 各物件 README 已齐（BRIEF §0） |

### ART-DW-X1-fix · UI-07 退回项
- status: done
- 来源: UI-07 2026-11-24
- 改哪些: `dossier/open.png`(+shadow)；`candle/candle_lit|out.png` 轮廓对齐；各目录 README
- 完成标准: 上表退回项清零；UI 复审过
- 怎么验: 再交 UI-07
- 证据:
  - `dossier/open.png` 重生为皮夹+双空白纸+铜扣/标签（非烫金开书）
  - `candle_lit.png` = `candle_out` 母版 ⊕ 俯视焰；alpha xor=0
  - 各物件 README 已按 BRIEF §0 补齐尺寸/状态/来源/授权
  - 总览已更新：`_overview/desk_world_x1_overview_2048.png`
  - 报告：`docs/reports/v0.88.0/art.md`
  - **UI 复审全过**（`docs/reports/v0.88.0/ui.md` UI-07 复审）
- 跨角色请求: ~~coordinator 迁入~~ → **CO-X1 done**（`assets/game/desk_world/`）

### ART-DW-X2 · 书桌世界 X2 批（DW-11…18）
- status: done
- 来源: ART_BRIEF_DESK_WORLD §2；X1 已过审
- 改哪些: `art/assets/raster/desk_world/<object>/`（cardbox/pouch/altar/circle_glow/ink_mask/envelope/battle_cloth/page_frames）+ shadow + README；总览；报告
- 完成标准: DW-11…18 齐；正俯视透明底无字；阴影另图；墨迹灰度阈值可扩散；不迁 assets/game；不开 X3
- 怎么验: 尺寸/alpha/灰度；2048 总览；请 ui-designer UI-07 审 X2
- 阻塞: 无
- 证据:
  - `cardbox/{closed,open}.png` + shadows @1200×900
  - `pouch/pouch.png` + shadow @600×600
  - `altar/{altar_idle,altar_active}.png` + shadows @1400×1400（外围 alpha 错配 0%）
  - `circle_glow/circle_glow.png` @1400×1400
  - `ink_mask/ink_mask_01..04.png` @2048×2048 L（中心亮/角黑）
  - `envelope/{envelope,insert_card}.png` + shadows
  - `battle_cloth/battle_cloth.png` @2048 平铺
  - `page_frames/{frontispiece,epilogue}_frame.png` + shadows @1260×1770（中心透明 100%）
  - 总览 `_overview/desk_world_x2_overview_2048.png`
  - 报告 `docs/reports/v0.88.0/art.md` X2 节
- 跨角色请求: ~~UI-07-X2~~ 全过；~~CO-X2~~ **done**（`assets/game/desk_world/`）；**不开 X3**
- 备注: 2026-11-24 完成；未迁 assets/game

### UI→art 请求区 · UI-07-X2（2026-11-24）— **已清零（全过）**
> 来自 ui-designer UI-07-X2；无退回项；非阻塞备注见 ui.md（DW-11 closed 偏面板感）。

| DW-ID | 结论 | 原因 / 要做什么 |
|---|---|---|
| DW-11…18 | **过** | 尺寸/透明/无字/墨迹灰度中心白/页框中心透明/altar 外围 xor=0/布接缝 均达标 |
| （批次） | **过** | 8/8 README；总览色温一致 |
| ART-DW-X2-fix | **不开** | 无退回 |

### ART-DW-X3 · 书桌世界 X3 批（DW-21…23）
- status: todo
- 来源: ART_BRIEF_DESK_WORLD §3
- 阻塞: X3 开版时由产品经理给出章节清单（DW-23）

> 现有 ART-01（桌木纹 / 蜡封三态）、ART-02（身份牌）照常进行：ART-02 的身份插画会放进 DW-03 相片框，构图请留出回形针区域。


### ART-01 · 日记桌材质补洞（desk_wood + 页蜡封三态）
- status: done
- 来源: ART_BRIEF_V085 §4；X2 余力
- 改哪些: `art/assets/raster/v0.85.0/desk_materials/**`
- 完成标准: `desk_wood` ≥2048 无缝平铺候选；`wax_seal_{available,completed,locked}` 各 512×512 透明、无字
- 怎么验: 尺寸核对 + 报告登记；正式迁入请 coordinator
- 阻塞: 无
- 证据:
  - `desk_wood.png` 2048×2048
  - `wax_seal_{available,completed,locked}.png` 512×512 RGBA
  - README：`art/assets/raster/v0.85.0/desk_materials/README.md`
- 跨角色请求: 请 coordinator 迁 `assets/ui/diary/`；请 ui-designer 真窗口抽查三态
- 备注: available 压印字母已后处理抹除

### ART-02 · 身份牌 3 张换 v0.85 风格
- status: todo
- 来源: art 缺口建议；现网仍 v0.48
- 改哪些: `art/assets/.../identities/` 候选 `art.png` 512×390（reporter/doctor/gravedigger）
- 完成标准: 三张候选齐、色温对齐技能卡；无插画内嵌字
- 怎么验: contact sheet + UI 审稿请求
- 阻塞: 无

### ART-03 · 敌人半身像铜版风格候选（按现有 encounter 名单）
- status: todo
- 来源: ART_DIRECTION；现网 SVG→PNG
- 改哪些: `art/assets/.../enemies/` 候选，目标约 900×900
- 完成标准: 现有敌人各一候选；不扩新敌人 ID
- 怎么验: README 清单；不迁 assets/game 除非 coordinator
- 阻塞: R1 内容冻结下只做风格补洞，不改 data

### ART-04 · 共用卡框分层源
- status: todo
- 来源: art/README §0
- 改哪些: `art/.../card-framework/` — paper_base / frame_chrome / effect_panel / 类型点
- 完成标准: 换卡只换插画的分层 PNG 可复用
- 怎么验: 用一张技能卡合成样张
- 阻塞: 可与 UI 手牌审稿并行

### ART-05 · 卡背 + 旧蜡封去英文（择期）
- status: todo
- 来源: ACTIVE_PLAN G-01 遗留
- 改哪些: 卡背候选；旧 4 枚母版无字重刻或确认 `-128` 足够
- 完成标准: 无拉丁字母；风格统一
- 怎么验: 目视 + 清单
- 阻塞: 低于 ART-01…04

### ART-06 · 配合 R0-11：按 UI 退回清单单张重修日记开页
- status: blocked
- 来源: ACTIVE_PLAN R0-11
- 改哪些: `art/.../scenes/` 被点名的竖图
- 完成标准: 退回项全部重交
- 怎么验: UI 复审
- 阻塞: 等待 ui-designer 出退回清单（按 scene_id）

## 已完成（近期）

### ART-done-diary-8 · 日记八开竖图 8/8
- status: done
- 证据: `assets/game/v0.85.0/diary/` 8/8 @1260×1770；真窗口审稿另属 UI

### ART-done-cards-40 · 技能卡插画 40/40
- status: done
- 证据: `art/assets/raster/v0.85.0/cards/**/art.png`

### ART-done-seals-24 · 蜡封矩阵 24/24
- status: done
- 证据: `art/assets/raster/v0.85.0/seals/`
