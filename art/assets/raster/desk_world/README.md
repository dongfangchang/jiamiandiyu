# Desk World 栅格候选

> 规格：`docs/design/ART_BRIEF_DESK_WORLD.md`  
> 体验框架：`docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032）  
> 正式迁入：请主协调者 → `assets/game/desk_world/**`（美术不自行迁移）

## 批次

| 批 | 状态 | 说明 |
|---|---|---|
| X1（DW-01…07） | 候选齐；**UI-07 复审全过**；已迁 `assets/game`（CO-X1） | 本目录 |
| X2（DW-11…18） | 候选齐；**UI-07-X2 全过**；已迁（CO-X2） | 本目录 |
| **DQ（DQ-01…06）** | **候选齐 2026-11-24**；待 UI 审稿 | `diary_quality/` |
| **DW-07b 索引卡** | **候选齐**；待 UI 审稿 | `index_card/` |
| X3（DW-21…23） | **未开**（等章节清单） | 见 art/tasks.md |

## X1 清单

| ID | 目录 | 文件 | 尺寸 |
|---|---|---|---|
| DW-01 | `dossier/` | `closed.png` `open.png` + shadows | 800×1100 / 1600×1200 |
| DW-02 | `page/` | `page.png` + shadow | 1024×1024 |
| DW-03 | `photo_frame/` | `photo_frame.png` + shadow | 600×800（中心透明） |
| DW-04 | `slip/` | `slip.png` + shadow | 700×260 |
| DW-05 | `book_closed/` | `book_closed.png` + shadow | 1400×1000 |
| DW-06 | `candle/` | `candle_lit` `candle_out` `smoke` + shadows | 512×768 |
| DW-07 | `tag/` | `tag.png` + shadow | 360×120 |

总览：`_overview/desk_world_x1_overview_2048.png`

## X2 清单

| ID | 目录 | 文件 | 尺寸 |
|---|---|---|---|
| DW-11 | `cardbox/` | `closed.png` `open.png` + shadows | 1200×900 |
| DW-12 | `pouch/` | `pouch.png` + shadow | 600×600 |
| DW-13 | `altar/` | `altar_idle` `altar_active` + shadows | 1400×1400 |
| DW-14 | `circle_glow/` | `circle_glow.png`（加色） | 1400×1400 |
| DW-15 | `ink_mask/` | `ink_mask_01..04.png` 灰度 L | 2048×2048 |
| DW-16 | `envelope/` | `envelope.png` `insert_card.png` + shadows | 800×560 / 512×720 |
| DW-17 | `battle_cloth/` | `battle_cloth.png` 可平铺 | 2048×2048 |
| DW-18 | `page_frames/` | `frontispiece_frame` `epilogue_frame` + shadows | 1260×1770（中心透明） |

总览：`_overview/desk_world_x2_overview_2048.png`

## DQ / 07b 清单（v0.89 P0）

| ID | 目录 | 关键文件 |
|---|---|---|
| DQ-01…06 | `diary_quality/dq0N/` | 见 `diary_quality/README.md` |
| DW-07b | `index_card/` | `index_card.png` + shadow @600×900 |

总览：`_overview/diary_quality_dq_overview_2048.png`

## 通用规则（已落实）

- 正俯视、RGBA 透明底（平铺/遮罩例外）、插画无字
- 阴影另图 `*_shadow.png`（灰度柔边，同画布；遮罩/平铺可占位）
- 光向：左上暖烛光
- 站位比例见 `DESK_WORLD_STATIONS.md` §5

## 审稿

- X1/X2：已过审并迁入。
- **请 ui-designer 审 DQ-01…06 + DW-07b**（接进日记站后截 1600×900 / 2920×1753 对比）。  
**勿**自行迁 `assets/game`（等审过请 coordinator）。
