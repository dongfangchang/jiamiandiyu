# UI 报告 · v0.89.0

## UI-P0-3-fix · 合入门清零（2026-11-24）

```text
版本：v0.89.0
角色：UI 设计
任务：UI-P0-3-fix（守卫注释 / v085 DQ-02 断言 / Forward+ 帧率预算 / 双分辨率证据）
状态：完成（测门绿；等主会话 UI-P0-2 合入后再 commit/push，避免覆盖同文件）
修改文件：
  src/ui/desk_world_catalog.gd（注释去掉 res://assets/game 前缀字面量）
  src/ui/diary_desk_quality.gd（SSAO/辉光按 ≥30fps HiDPI 下调）
  src/ui/diary_desk_stage.gd（关烛光 Omni 影；WorldVP 关 MSAA/TAA；未动 PAGE_VP/镜头）
  tests/ui/v085_diary_art_runner.gd（旧木纹断言 → DQ-02 registry 材质）
  tests/ui/v089_diary_quality_capture_runner.gd|.tscn（双分辨率截图 + HiDPI fps）
  project.godot（forward_plus + mobile 预留；SSAO very-low + half_size）
  docs/reports/v0.89.0/ui.md / ui_p0_3_fix_diary_*.png
依赖：UI-P0-3 实现；ADR-0035；主会话 UI-P0-2 尚未合入（PAGE_VP 仍 512×720）
验证：
  tools/run_tests.sh → pass=94 fail=0 skipped=12 guard_block=0
  v085_diary_art_runner OK checks=24
  diary_quality_wiring_runner 30/30；v083 OK checks=21
  Forward+ Metal 截图：
    docs/reports/v0.89.0/ui_p0_3_fix_diary_1600x900.png
    docs/reports/v0.89.0/ui_p0_3_fix_diary_2920x1753.png
  HiDPI fps@2920×1753（暖机后 60 帧）：avg=37.4 min=29.0 max=41.0（目标 ≥30 达标）
困难与候选方案：
  A) 关 SSAO 换帧率 → 否（接线要求保持 enabled）
  B) 降 SSAO/辉光 + half_size + 关烛光 Omni 影 → 采纳
最终解决：守卫清零；v085 断言 DQ-02；帧率预算参数写入 diary_desk_quality + project.godot
风险 / 协调：
  - **仍等主会话 UI-P0-2**：同改 diary_desk_stage / diary_page_pair；本条未 push
  - PAGE_VP 可读性仍待 P0-2；本条未回滚/抬升 PAGE_VP
跨角色请求：主会话合入 P0-2 后请通知；本条再 rebase/commit/push（含 project.godot Forward+）
下一步入口：等待 P0-2 → 合入本修复 → 用户真窗签字画面
```

### 帧率调参摘要（相对 UI-P0-3 初值）

| 项 | 调整 |
|---|---|
| SSAO | radius 0.35 / intensity 0.48 / detail 0.05；project quality=0 + half_size |
| Glow | intensity 0.10；关掉 1/2/6/7 级 mip |
| 阴影 | 烛光 Omni `shadow_enabled=false`（保留方向光 + DQ-06 接触影） |
| WorldVP | MSAA/TAA/SSAA 关闭 |

---

## UI-P0-3 · 日记站画面升级（2026-11-24）

```text
版本：v0.89.0
角色：UI 设计
任务：UI-P0-3（DQ-01…06 接入 + Forward+ 光照/后期 + 丝带「合上」）
状态：完成（实现与自动化绿；用户真窗认可仍待签字）
修改文件：
  src/ui/desk_world_catalog.gd（新建）
  src/ui/diary_desk_quality.gd（新建；DQ/Environment 抽出，避免再胀 diary_desk_stage）
  src/ui/diary_desk_stage.gd（调用点叠加；未改镜头/PAGE_VP 可读性参数，留给 UI-P0-2）
  src/ui/diary_page_pair.gd（DQ-04 右页装饰 + 蜡封文字 caption）
  src/ui/diary_chapter_screen.gd（仅 _build_close_bookmark → DQ-05 丝带）
  tests/ui/diary_quality_wiring_runner.gd|.tscn
  docs/reports/v0.89.0/ui.md
  .cursor/agents/ui-designer/tasks.md
  .cursor/agent-memory/ui-designer/journal.md
依赖：CO-AR05 Forward+；CO-DQ 资产；ADR-0035；ADR-0034 D4
验证：
  diary_quality_wiring_runner checks=30 failures=0
  v083_diary_desk_p0_runner OK checks=21
  diary_prepared_turn_runner OK checks=28
  challenge_diary_fallback_runner OK checks=77
  真窗截图（Metal Forward+）：docs/reports/v0.89.0/ui_p0_3_diary_1600x900.png
    + ui_p0_3_diary_flip_1600x900.png
困难与候选方案：
  A) 全塞进 diary_desk_stage（已 >800 行）→ 否
  B) 抽出 diary_desk_quality + desk_world_catalog → 采纳
最终解决：registry 查 desk_world；Environment 开 ACES/glow/SSAO；丝带取代红块 StyleBox
风险：
  - PAGE_VP 仍 512×720（UI-P0-2 主会话负责抬到 ≥1024×1440）；DQ-04 用相对锚点，可叠加
  - HiDPI 全开 FX 帧率见 ADR-0035；本轮参数偏保守
  - 2920×1753 截图未跑（capture runner 固定 1600×900）；请用户真窗确认
跨角色请求：无阻塞；请用户在真窗对比认可画面升级
下一步入口：用户签字 → 主会话继续 UI-P0-2 可读性；勿回滚本条 DQ 调用
行数例外：diary_desk_stage.gd 仍 ~1473 行；本条只加调用点，逻辑在 diary_desk_quality.gd（207 行）
```

### 接入对照

| ID | 落点 | 说明 |
|---|---|---|
| DQ-01 | `RoomBackplate` albedo | 书房远景板 |
| DQ-02 | `DeskMesh` PBR | albedo/normal/roughness |
| DQ-03 | `CoverMesh` + `ForeEdgeL/R` | 书皮 + 书口条 |
| DQ-04 | 右页 `RuledLines` / 页眉 / 四角 / 涂鸦·墨渍 | tr↔bl 按审稿质心映射 |
| DQ-05 | 3D `RibbonBookmark` + chrome `CloseBookmarkRibbon` | 文字「合上」；删除红块 StyleBox |
| DQ-06 | `BookContactShadow` / `CandleContactShadow` / `CoverContactShadow` | 接触阴影 |
| FX | SubViewport Environment | ACES + glow + SSAO（ADR-0035） |

### 冲突纪律

未改 `start_screen` / `title_desk_stage` / `battle_screen` / `card_face` / `DESK_WORLD_STATIONS.md`（主会话 P0-1/P1-1/X0-rev）。  
`diary_desk_stage` 开工时无主会话未提交 diff；可读性参数（镜头俯角、PAGE_VP、字号）保持原样供 UI-P0-2 叠加。

---

## UI-07-DQ 审稿（2026-11-24 · ART-DQ）

对照 `ART_BRIEF_DESK_WORLD` §5 + ADR-0034 D4 + `DESK_WORLD_STATIONS`。  
资产根：`art/assets/raster/desk_world/diary_quality/`。  
总览：`_overview/diary_quality_dq_overview_2048.png`。示意对比：`docs/reports/v0.89.0/art_dq_before_after_schematic.png`（非实机）。

| ID | 资产 | 尺寸 / 规格 | 结论 | 备注 |
|---|---|---|---|---|
| DQ-01 | `dq01/room_backplate.png` | 3840×2160 ✅ | **过** | 正视书房：窗/书架/壁纸；下沿 1/3 偏暗（bot lum≈11.5 vs top≈29）；无桌面；无字 |
| DQ-02 | `desk_{albedo,normal,roughness}` | 2048×2048 ✅ | **过** | 深胡桃+磨损墨渍；albedo/roughness 接缝 mae=0；normal 接缝 mae≈0.5/0.8（可平铺）；normal 起伏偏细（art 自报亮度派生，非阻塞） |
| DQ-03 | `cover_{albedo,normal}` + `fore_edge` | 2048 / 1024×128 ✅ | **过** | 旧皮革压纹星纹无字；书口无印刷字。非阻塞：fore_edge 偏暗、横纹纸层略弱 |
| DQ-04 | 页眉/四角×4/横线/涂鸦×6/墨渍×4 | README 尺寸全 ✅ | **过** | 16/16；RGBA 四角 α=0；墨褐单色；不抢正文。非阻塞：`page_corner_tr` 与 `page_corner_bl` 画布内质心对调（接入前改名互换或 UI 映射即可） |
| DQ-05 | `ribbon_bookmark.png` (+shadow) | 160×900 ✅ | **过** | 暗红丝带+燕尾；四角 α=0；中段无重墨渍（可叠「合上」）；无烘焙字 |
| DQ-06 | `contact_shadow_*.png` ×14 | 与物件同尺寸 ✅ | **过** | 14/14 对齐 X1/X2 物件；灰度 sat=0；柔边 maxA=140 |
| 批次 README | dq01…06 | — | **过** | 目录 README 齐；总览齐 |

**批次结论：DQ-01…06 全部过。** 无需 ART-DQ-fix。

## UI-07-07b 审稿（2026-11-24 · ART-DW-07b）

对照 ADR-0034 D1（索引卡文字入口）+ art README。  
资产：`art/assets/raster/desk_world/index_card/`。

| ID | 资产 | 尺寸 / 规格 | 结论 | 备注 |
|---|---|---|---|---|
| DW-07b | `index_card.png` (+shadow) | 600×900 ✅ | **过** | 正俯视空白索引卡；**6 行**淡书写线；无字；四角 α=0；与 DW-07 同族 |

**结论：DW-07b 过。**

## 验证命令（本机）

```bash
.tools/art-venv/bin/python - <<'PY'
# 尺寸 / 四角 alpha / DQ-02 接缝 / DQ-06 对物件 / DW-07b
# 见本会话度量输出；关键目视：总览、room_backplate、desk_albedo、cover、ribbon、index_card、dq04 collage
PY
```

## 非阻塞备注（不退回）

1. DQ-04：`page_corner_tr.png` ↔ `page_corner_bl.png` 建议 art 改名互换（质心：现 tr≈BL、bl≈TR）；或 UI-P0-3 接入时按质心映射。
2. DQ-03 `fore_edge`：实机若仍像木条而非纸层，可再补横纹。
3. DQ-02 normal：真 PBR 若被渲染器 ADR 要求，可能重修（art 已自报）。
4. 真窗口 1600×900 / 2920×1753「现状 vs 接资产」对比：待 CO-DQ 迁入 + UI-P0-3 接入后由 UI 截图，用户签字。

## 跨角色请求

1. ✅ 请 **coordinator · CO-DQ**：迁入  
   - `art/assets/raster/desk_world/diary_quality/**` → `assets/game/desk_world/diary_quality/`  
   - `art/assets/raster/desk_world/index_card/**` → `assets/game/desk_world/index_card/`  
   并更新 `data/registry/assets.json` / `art/ASSET_MANIFEST.md`（按 CO-05）。  
2. ~~art FIX~~：无强制退回。可选微修：四角 tr/bl 改名。  
3. UI-P0-3 仅再堵本迁入（AR-05 已清）。

### Retro · 2026-11-24 · UI-07-DQ / UI-07-07b

1. 达成？是。DQ-01…06 + DW-07b 全过；证据见表 + Pillow 度量。  
2. 易错？DQ-04 四角文件名朝向 vs 画布质心；自动化「线数」易被纸纹误计，以目视为准。  
3. 可沉淀？同 X1/X2：BRIEF 表 → 尺寸/α → 特规（接缝/同尺寸阴影/中段留白）→ 总览 → CO 请求。  
4. Tool？续用 `.tools/art-venv` Pillow 一次性脚本。  
5. 下次先读？`ART_BRIEF_DESK_WORLD` §5 + 本报告表格式。
