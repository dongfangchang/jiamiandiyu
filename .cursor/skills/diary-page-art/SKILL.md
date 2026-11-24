---
name: diary-page-art
description: 绘制并入库日记左页开页插画。按 ART_BRIEF 竖构图 1260×1770、无框无字无纸纹叠绘，写入 art/.../scenes 并协调迁入 assets/game/.../diary。美术角色出图时使用。
---

# Diary Page Art

## 输入

- `docs/design/ART_BRIEF_V085.md` §3 对应节点规格
- 参考：`art/assets/raster/v0.85.0/reference/样板.jpg`、已有 `battle-moretti-home.png`
- 目标文件名见 `src/ui/scene_ui_catalog.gd` → `DIARY_PATHS`

## 步骤

1. 按 BRIEF 写提示词：竖构图、水彩+铜版、无字无框、强调色、克制面部。
2. 生成后裁切为 **1260×1770**；高光勿死白（可钳亮度）。
3. 写入 `art/assets/raster/v0.85.0/scenes/<name>.png`（+ 可选 jpg 源）。
4. 更新 `scenes/README.md` 清单。
5. **不要擅自改 UI**；迁正式路径请 coordinator：目标 `assets/game/v0.85.0/diary/<name>.png`。
6. 报告写清：文件列表、与 BRIEF 差异、请 UI 真窗口审稿。

## 失败模式

- 带金色外框 → 程序羽化后发光晕；必须重出无框版。
- 画成 16:9 → 日记左页被左右裁切；必须竖图。
- 纸纹画进图 → 与程序 parchment 叠脏；删纹理重出。
