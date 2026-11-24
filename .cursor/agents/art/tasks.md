# Tasks · art

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### ART-DW-X1 · 书桌世界 X1 批（DW-01…07）
- status: todo
- 来源: ADR-0032；`docs/design/ART_BRIEF_DESK_WORLD.md` §1
- 改哪些: `art/assets/raster/desk_world/<object>/`（每个物件一个目录加 README）
- 完成标准: 身份档案夹（开 / 合）、档案内页纸、相片框、书签纸条、合上的日记封面、烛台三帧、悬停题签全部交齐；正俯视、透明底、无字；阴影单独出图
- 怎么验: 尺寸和透明度核对；放进一张 2048 总览拼贴，对照 §4 自查；交给 ui-designer UI-07 审稿
- 阻塞: 无（规格已经定死为正俯视，不依赖镜头参数）

### ART-DW-X2 · 书桌世界 X2 批（DW-11…18）
- status: todo
- 来源: ART_BRIEF_DESK_WORLD §2
- 改哪些: 同上
- 完成标准: 卡匣、残页袋、祈愿台（两态加光效）、墨迹遮罩 ×4、信封 / 夹页卡、战斗桌布、扉页 / 终章页框
- 怎么验: 同上；墨迹遮罩必须是灰度、能平滑地按阈值扩散
- 阻塞: 建议在 X1 批之后做

### ART-DW-X3 · 书桌世界 X3 批（DW-21…23）
- status: todo
- 来源: ART_BRIEF_DESK_WORLD §3
- 阻塞: X3 开版时由产品经理给出章节清单（DW-23）

> 现有 ART-01（桌木纹 / 蜡封三态）、ART-02（身份牌）照常进行：ART-02 的身份插画会放进 DW-03 相片框，构图请留出回形针区域。


### ART-01 · 日记桌材质补洞（desk_wood + 页蜡封三态）
- status: todo
- 来源: ART_BRIEF_V085 §4；art 缺口建议 2026-11-24
- 改哪些: `art/assets/raster/v0.85.0/**`（或当前版本 raster 目录）；清单 README
- 完成标准: `desk_wood` ≥2048 无缝平铺候选；`wax_seal_{available,completed,locked}` 各 512×512 透明、无字
- 怎么验: 尺寸核对 + 报告登记；正式迁入请 coordinator
- 阻塞: 无

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
