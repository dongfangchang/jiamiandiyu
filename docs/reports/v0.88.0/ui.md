# UI 报告 · v0.88.0

版本：v0.88.0  
角色：ui-designer  
任务：UI-X0 站位稿 + UI-07 / UI-07-X2 审稿（并行；不碰主会话 UI-H）  
状态：部分完成（X0 + UI-X0-fix + UI-07 X1/X2 审稿完成；H 由主会话；X1 实现仍 blocked）

## 本版本目标与当前任务

- 主会话：轨道 H 热修（本角色**不抢改** gacha/upgrade/diary_desk/title_desk/start）。
- 本职并行：**UI-X0** 站位设计稿，供 art 定 DW 比例、供架构师 AR-04 评审。

## §10 · UI-X0 书桌世界站位设计稿

### 完成标准勾选

1. ✅ 桌面俯视布局（世界单位；日记 55–65% 视口宽）
2. ✅ 七站位镜头位姿（相对 diary 基准 `pos 0,1.61,0.93` / `rot −59` / `fov 38`）
3. ✅ 各站 2D 版式（title 纸条；dossier 两页；desk 题签等）
4. ✅ T1–T4 与输入状态
5. ✅ 现有素材总览拼贴

### 交付路径

| 产物 | 路径 |
|---|---|
| 设计稿 | `docs/design/DESK_WORLD_STATIONS.md` |
| 线框目录 | `assets/ui/wireframes/desk_world/` |
| 俯视 | `…/00_topdown_layout.svg` |
| 镜头 | `…/01_camera_poses.svg` |
| 版式 | `…/02_station_content_layouts.svg` |
| 过渡 | `…/03_transitions.md` |
| 拼贴 | `…/04_overview_collage.svg` |

### 七站位摘要

| 站位 | 镜头要点 | 2D |
|---|---|---|
| title | 更远更高 fov42 | DW-04 书签纸条 |
| desk | 总览 fov48 | DW-07 悬停题签 |
| dossier | 左推近 yaw+22 | 左相片+姓名序列 / 右资源局况章 |
| diary | **基准** fov38 | 现左右页 BRIEF |
| cardbox | 右推近 | 摊牌+残页袋（X2 美术） |
| altar | 右上俯 fov32 | 纸签环绕镜 |
| drawer | 降低前移 | 卷宗夹 |

### 给 art 的比例要点（DW→站位）

以打开日记足迹宽 **1.34 = 100%**：

- DW-01 档案夹：合 ~36% / 开 ~67% → `dossier`
- DW-04 纸条：~28% → `title`
- DW-05 合书：~54% → `title`/`desk`
- DW-06 烛台：底座 ~12%、高 0.42 → 左上光 / T4
- DW-07 题签：屏上 360×120 → `desk` 悬停

详表：`DESK_WORLD_STATIONS.md` §5。

### UI-07 审稿（已做 · 部分退回）

对照 `ART_BRIEF_DESK_WORLD` §0/§1/§4 + `DESK_WORLD_STATIONS.md` §5。资产根：`art/assets/raster/desk_world/`。总览：`_overview/desk_world_x1_overview_2048.png`。

| DW-ID | 文件 | 尺寸 | 结论 | 说明 |
|---|---|---|---|---|
| DW-01 closed | `dossier/closed.png` | 800×1100 ✅ | **过** | 皮夹、铜扣、空白标签；透明底 |
| DW-01 open | `dossier/open.png` | 1600×1200 ✅ | **过（复审）** | FIX：皮夹展开 + 双空白公文纸 + 铜扣/标签族；非开书 |
| DW-02 | `page/page.png` | 1024×1024 ✅ | **过** | 偏冷+淡横线（平铺满幅 opaque OK） |
| DW-03 | `photo_frame/photo_frame.png` | 600×800 ✅ | **过** | 回形针、中心透明 |
| DW-04 | `slip/slip.png` | 700×260 ✅ | **过** | 空白撕边纸条 |
| DW-05 | `book_closed/book_closed.png` | 1400×1000 ✅ | **过** | 烫金框无字；左上光 |
| DW-06 lit/out | `candle_*.png` | 512×768 ✅ | **过（复审）** | FIX：alpha 掩膜相对 out **xor=0**（焰在 RGB 内）；T4 可切 |
| DW-06 smoke | `smoke.png` | 512×768 ✅ | **过** | |
| DW-07 | `tag/tag.png` | 360×120 ✅ | **过** | 空白题签 |
| 批次 README | 各物件目录 | — | **过（复审）** | 7/7 README 已齐 |

### UI-07 复审（2026-11-24 · FIX 后 · 主会话代 ui 收口）

对照重交资产：`dossier/open.png`、`candle_lit|out.png`、各 README、`_overview/…2048.png`。  
**DW-01…07 全部过。** **CO-X1 已迁入** `assets/game/desk_world/`（coordinator 2026-11-24）。

### UI-07-X2 审稿（2026-11-24 · ART-DW-X2）

对照 `ART_BRIEF_DESK_WORLD` §0/§2/§4 + `DESK_WORLD_STATIONS.md` §5 X2 行。  
资产根：`art/assets/raster/desk_world/`。总览：`_overview/desk_world_x2_overview_2048.png`。  
**未改** `src/**`、**未动** UI-H、**未开** UI-X1 生产码、**未自行迁** `assets/game`。

| DW-ID | 文件 | 尺寸 | 结论 | 说明 |
|---|---|---|---|---|
| DW-11 closed | `cardbox/closed.png` + shadow | 1200×900 ✅ | **过** | 木框+铜扣+空白铭牌；四角 alpha=0；无字 |
| DW-11 open | `cardbox/open.png` + shadow | 1200×900 ✅ | **过** | 绒布槽+盖内纹样；无字；与合态画布同尺寸 |
| DW-12 | `pouch/pouch.png` + shadow | 600×600 ✅ | **过** | 系绳皮袋+撕页；左上光；透明底 |
| DW-13 idle | `altar/altar_idle.png` + shadow | 1400×1400 ✅ | **过** | 圆镜+三烛+粉笔圈；与 active 外围 alpha 错配 **0** |
| DW-13 active | `altar/altar_active.png` + shadow | 1400×1400 ✅ | **过** | idle⊕镜面冷光；bbox 对齐 |
| DW-14 | `circle_glow/circle_glow.png` | 1400×1400 ✅ | **过** | 独立加色冷光环；透明底 |
| DW-15 | `ink_mask/ink_mask_01..04.png` | 2048×2048 L ✅ | **过** | mode=L；中心≈238–248、四角近黑（白=先到） |
| DW-16 envelope | `envelope/envelope.png` + shadow | 800×560 ✅ | **过** | 空白蜡封、无字 |
| DW-16 insert | `envelope/insert_card.png` + shadow | 512×720 ✅ | **过** | 中心为空白纸面（引擎写字）；勿当插画卡 |
| DW-17 | `battle_cloth/battle_cloth.png` | 2048×2048 ✅ | **过** | 深绒+粉笔阵；L-R/T-B 接缝 mae=0（可平铺） |
| DW-18 frontis | `page_frames/frontispiece_frame.png` + shadow | 1260×1770 ✅ | **过** | 中心透明采样 **100%**；无字 |
| DW-18 epilogue | `page_frames/epilogue_frame.png` + shadow | 1260×1770 ✅ | **过** | 同上；装饰框 |
| 批次 README | 八物件目录 | — | **过** | 8/8 README |

**批次结论：DW-11…18 全部过。** 无需 ART-DW-X2-fix。

非阻塞备注（不退回）：DW-11 closed 偏「匣面面板」而非厚盖立体（art 自报风险）；合/开外轮廓因开盖必然不同，非 lit/out 式插值对齐——实现时勿按像素 morph。

验证命令（本机）：
```bash
.tools/art-venv/bin/python  # 尺寸/mode/角 alpha；altar 外围 xor；ink 中心/角；page_frames 中心透明；battle_cloth 接缝
```

### 验证

- 对照 EXPERIENCE §2–§5 / §8：设计稿 §7 自检表。
- 像素：`sips` / PNG RGBA 角透明抽样；烛台 alpha 错配统计；X2 见上表。
- 未改 `src/**` 生产逻辑；未触碰 UI-H 文件。

### AR-04 条件已清（UI-X0-fix · 2026-11-24）

对照 `docs/reports/v0.88.0/architect.md` 必须改 ×2：

1. ✅ 过渡表补 **新游戏 `TITLE → DOSSIER`（T1）** + 建档后续 `DOSSIER → CARDBOX → DIARY`（直达，不经 DESK 0.4 s）——`DESK_WORLD_STATIONS.md` §4；`03_transitions.md` 状态机同步。
2. ✅ 墨水/羽笔改坐标 **`(0.52, 0.48)` / `(0.66, 0.55)`**（避开合/开卡匣、祈愿台、抽屉 AABB）；废弃 `(0.85, −0.08)`——§1 表 + ASCII；`00_topdown_layout.svg` 已标注。

**AR-04 条件已由主会话代 architect 确认通过**（见 `architect.md`「AR-04 条件确认」）。

### 跨角色请求

- **product**：抽屉进战已冻结为 **T1→DESK→T3**（见 `product_manager.md` / ACTIVE_PLAN §0 · DW）。
- **coordinator · CO-X2**：**done**（26 PNG 已迁入 `assets/game/desk_world/` X2 目录）。

### 风险 / 未决

- 抽屉进战路径已冻结（T1→DESK→T3）；X3 实现时按此。
- UI-X1 仍等：**v0.88 合并**（X1+X2 道具均已迁入）。

---

## 修改文件（本角色本轮）

- `docs/design/DESK_WORLD_STATIONS.md`（X0 + AR-04 补丁 §1/§4）
- `assets/ui/wireframes/desk_world/**`（含 00 墨/羽标注、03 新游戏流）
- `docs/reports/v0.88.0/ui.md`（本文件；含 UI-07-X2）
- `.cursor/agents/ui-designer/tasks.md`（UI-X0-fix；UI-07-X2）
- `.cursor/agents/art/tasks.md`（UI→art 请求区 X2 清零）
- `.cursor/agents/coordinator/tasks.md`（请求 CO-X2）
- `.cursor/agent-memory/ui-designer/journal.md`

## 困难与候选方案

- 拼贴无 Pillow/ImageMagick：用 SVG `image href` 引用现有 PNG，可在浏览器/IDE 预览。
- 卡匣等 X2 资产未到：俯视用色块占位，避免假装已有美术。
- 羽笔旧点与卡匣 AABB 重叠：改到日记右前 +Z 侧 `(0.52/0.66, 0.48/0.55)`。

## 最终解决

设计/线框 + AR-04 条件清零 + UI-07 X1/X2 全过 + CO-X1/X2 已迁入；生产路由仍不动。

## 下一步入口

1. v0.88 合并后开 UI-X1（道具已在 `assets/game/desk_world/`）

### Retro · 2026-11-24 · UI-07-X2

1. 达成？是。DW-11…18 全过；证据见上表 + Pillow 度量。  
2. 易错？DW-16 insert 中心纸面 ≠ DW-18 中心透明。  
3. 可沉淀？X1/X2 同款审稿清单（尺寸→α→特规→总览→CO 请求）。  
4. Tool？暂用 art-venv Pillow 一次性脚本。  
5. 下次先读？BRIEF 批表 + 本报告 UI-07 表格式。

### Retro · 2026-11-24 · UI-X0 站位设计稿

1. 目标是否达成？是。证据：`docs/design/DESK_WORLD_STATIONS.md` + `assets/ui/wireframes/desk_world/` 五件套。  
2. 哪一步最耗时或最易错？把现网日记世界单位（DeskMesh / BookRoot / 镜头）对齐到七站位相对偏移，避免与 ART_BRIEF 像素规格两套数。  
3. 可沉淀步骤？「先读 diary 镜头与 DeskMesh → 定 100% 日记足迹 → 再写 DW 相对% → 线框 SVG」。已 Draft。  
4. Tool Registry？本轮无新命令。  
5. 下次第一条读？Draft `desk-world-station-brief` + EXPERIENCE §2 + ART_BRIEF_DESK_WORLD。
