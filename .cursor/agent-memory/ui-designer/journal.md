# Journal · ui-designer

> 追加写，旧条目不删。格式见 `.cursor/agents/_meta/SKILL_LOOP.md` §3。

## Log

- 2026-11-25 · UI-KEY-DIARY-SEAL + UI-KEY-DESK-UNITY done：纪要置顶 `ui.md`；「启」=蜡面压痕禁近白浮字；desk 母版=title/approved，三方案只许镜头/疏密/悬停；解锁 art 02c / 03-rev2；未改 src/ui。
- 2026-11-25 · UI-KEY-DIARY-JOINT + UI-KEY-DESK-JOINT done：联合纪要写入 `docs/reports/v0.89.0/ui.md`；日记落点%/印纸五准则；桌面索引卡材质·烛光·六行·悬停；未改 src/ui；解锁 art 02b / 03-rev。
- 2026-11-25 · UI-CH-GREY + UI-RENDER-MOBILE done：挑战锁定灰显+ChallengeHint；`project.godot` mobile；exposure 3.0 / SPECULAR_DISABLED；测门 95/0/14/0；截图 `ui_render_mobile_diary_1600x900.png`。
- 2026-11-25 · UI-P0-3-reject done：方案 (a) RoomBack `(0,1.05,-1.72)` 直立；D2 `attach_bookmark_ribbon`；AR-07 遮挡绿；测门 95/0/14/0；renderer-hold 回 gl_compatibility；截图 `ui_p0_3_fix_diary_*.png`。
- 2026-11-24 · UI-P0-3-sync done：WIP `f38393e` → rebase onto `b340186` → `4d510ce`；冲突三文件手改；DQ-01 后仰 −62°；测门 pass=95/0/guard0（含 readability）；已 push。
- 2026-11-24 · boot：角色记忆目录初始化。
- 2026-11-24 · UI-X0 done：`docs/design/DESK_WORLD_STATIONS.md` + `assets/ui/wireframes/desk_world/`；未实现 X1；请求 AR-04。
- 2026-11-24 · UI-07 done：DW-01 open / DW-06 轮廓退回；其余 DW 过；请求区写入 art/tasks。
- 2026-11-24 · UI-X0-fix：AR-04 两条件清零——新游戏 TITLE→DOSSIER；墨/羽 (0.52,0.48)/(0.66,0.55)；未复审 UI-07（art fix 仍 doing）。
- 2026-11-24 · UI-07-X2 done：DW-11…18 全过；请 CO-X2 迁入；无 ART-DW-X2-fix；未动 UI-H / UI-X1 码。
- 2026-11-24 · UI-07-DQ / UI-07-07b done：DQ-01…06 + DW-07b 全过；请 CO-DQ 迁 diary_quality+index_card；未动 P0/P1 实现、未自迁 assets/game。
- 2026-11-24 · UI-P0-3 done：DQ 接入 + Forward+ FX + 丝带「合上」；抽出 diary_desk_quality；未动主会话 P0-1/P0-2/P1-1 文件。
- 2026-11-24 · UI-P0-3-fix done：守卫注释清零；v085→DQ-02；FX 预算 HiDPI≈37fps；测门 94/0/guard0；**等 P0-2 再 push**。

### Retro · 2026-11-25 · UI-KEY-SEAL + UNITY（二次驳回闸）
1. 目标是否达成？证据（命令/路径/截图）？  
   是。`ui.md` 置顶 SEAL/UNITY；tasks done；art 可开 02c / 03-rev2；无 src/ui 改动。
2. 哪一步最耗时或最易错？  
   JOINT 曾写「启」近白压印——被用户证伪；须用压痕/吃蜡光覆盖旧色值，避免 art 按旧表复刻浮字。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   二次驳回：保留已过闸 → 只开失败子闸 → 母版锁不可变项 + 白名单可变项 → 置顶纪要覆盖旧句。
4. 该进 Tool Registry 的命令是什么？  
   无新命令。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   本 Retro + `ui.md` SEAL/UNITY 置顶节 + title/approved。

### Retro · 2026-11-25 · UI-KEY 联合纪要（diary + desk）
1. 目标是否达成？证据（命令/路径/截图）？  
   是。两节纪要在 `docs/reports/v0.89.0/ui.md`；tasks 标 done；art 可按纪要开 02b/03-rev；无 src/ui 改动。
2. 哪一步最耗时或最易错？  
   把「可读性底线」译成 art 可执行的落点%与材质闸，避免再画出浮层/白便签。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   目标帧联合：驳回根因 → 对照 approved → 落点表% → 字号/对比度 → 禁清单 → 给 art 出图指令三问自检。
4. 该进 Tool Registry 的命令是什么？  
   无新命令（纯设计交付）。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   本 Retro + ADR-0037 附录 A + EXPERIENCE §5.1 + 本报告两节。

### Retro · 2026-11-25 · UI-CH-GREY + UI-RENDER-MOBILE
1. 目标是否达成？证据（命令/路径/截图）？  
   是。GREY 锁定灰显+原因；Mobile exposure/specular；`run_tests` pass=95 fail=0 skipped=14 guard_block=0；截图 `ui_render_mobile_diary_1600x900.png`。
2. 哪一步最耗时或最易错？  
   Mobile 开 SSAO 会每次构建刷警告；须按 method 关 SSAO，并改 wiring 断言。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   渲染器切换清单：改 project.godot → 按 method 分支 exposure/glow/SSAO → 页面 SPECULAR_DISABLED → readability 绿 → 非 headless 截图写 method/driver。
4. 该进 Tool Registry 的命令是什么？  
   已有 `v089_diary_quality_capture_runner.tscn`；路径改为 `ui_render_mobile_diary_*`。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   ADR-0036 参数表 + 本 Retro；画面风格仍读 ADR-0037。

### Retro · 2026-11-25 · UI-P0-3-reject RoomBack 遮挡
1. 目标是否达成？证据（命令/路径/截图）？  
   是。方案 (a)；`run_tests` pass=95 fail=0 skipped=14 guard_block=0；readability checks=43（遮挡 clear）；截图 `ui_p0_3_fix_diary_{1600x900,2920x1753}.png` 书页完整。
2. 哪一步最耗时或最易错？  
   与 AR-07 并行改 `diary_desk_stage.gd` 会互相覆盖（曾短暂丢回 `replace_bookmark_ribbon` / −62°）；测门中途竞态假红。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   陡镜头背景板：先算 camera→page 线段，禁止任何板 AABB 与之相交；摆放后再跑遮挡守卫；D2 书签只建一个节点。
4. 该进 Tool Registry 的命令是什么？  
   已有 capture；遮挡断言随 `diary_readability_runner`。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   本 Retro + EXPERIENCE §5.1 + AR-07 `diary_page_occlusion.gd`。

### Retro · 2026-11-24 · UI-P0-3-sync rebase P0-2
1. 目标是否达成？证据（命令/路径/截图）？  
   是。`4d510ce`；`run_tests` pass=95 fail=0 guard_block=0；readability+quality wiring 绿；截图刷新 `ui_p0_3_fix_diary_*.png`。
2. 哪一步最耗时或最易错？  
   沙箱无法 unlink journal → rebase 必须 `all` 权限；冲突时易丢 `INK_FADE_LOCKED` / `px()`；陡镜头下 DQ-01 直立墙必然出画。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   并行轨道：WIP commit → rebase → 冲突表（保留底线列 / 叠质量列）→ 重评估出画资产 → 全量测门（非沙箱）→ push。
4. 该进 Tool Registry 的命令是什么？  
   已有 capture；补一句：测门必须非沙箱（需写 `user://`）。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   本 Retro + `ui_readability.md` §6 合并须知 + `godot-probe-gate`。

### Retro · 2026-11-24 · UI-P0-3-fix 合入门
1. 目标是否达成？证据（命令/路径/截图）？  
   是。`run_tests` pass=94 fail=0 guard_block=0；截图 `ui_p0_3_fix_diary_{1600x900,2920x1753}.png`；HiDPI fps avg=37.4。未 push（等 P0-2）。
2. 哪一步最耗时或最易错？  
   帧率：仅降 Environment 不够，还需 half_size SSAO + 关烛光 Omni 影；采样须暖机否则 min=1 拖垮均值。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   合入门三件套：grep 守卫字面量（含注释）→ 替换即删除旧断言 → 非 headless 双分辨率 + 暖机 fps。
4. 该进 Tool Registry 的命令是什么？  
   `v089_diary_quality_capture_runner.tscn`（capture 排除默认门）。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   `godot-probe-gate` + 本 Retro + ADR-0035 帧率软门槛。

### Retro · 2026-11-24 · UI-P0-3 日记站 DQ / Forward+
1. 目标是否达成？证据（命令/路径/截图）？  
   实现与探针是。`diary_quality_wiring_runner` 30/30；v083/prepared_turn/challenge_fallback OK；截图 `docs/reports/v0.89.0/ui_p0_3_diary_1600x900.png`。用户真窗签字仍待。
2. 哪一步最耗时或最易错？  
   与主会话同文件冲突规避；headless capture 在 dummy 下拿不到纹理，须非 headless Forward+ 窗。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   registry desk_world 目录 → 抽出 *\_quality 助手 → 舞台只留调用点 → chrome 丝带文字控件 → wiring runner 断言 Environment/节点名。
4. 该进 Tool Registry 的命令是什么？  
   `diary_quality_wiring_runner.tscn` + 非 headless `v084_diary_desk_capture_runner`（已有 capture 排除默认门）。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   ADR-0035 接口约定 + 本报告 UI-P0-3 接入表 + `godot-probe-gate`。

### Retro · 2026-11-24 · UI-07-DQ / UI-07-07b 日记画面升级审稿
1. 目标是否达成？证据（命令/路径/截图）？  
   是。`docs/reports/v0.89.0/ui.md`；art-venv Pillow 尺寸/α/接缝/阴影对齐；总览与关键 PNG 目视。
2. 哪一步最耗时或最易错？  
   DQ-04 四角文件名与画布质心不一致；索引卡「线数」自动化易被纸纹抬高，须目视确认 6 行。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   复用 X1/X2：BRIEF 批表 → 尺寸 → RGBA 角透明 → 特规（无缝/同尺寸阴影/中段留白/无字）→ 总览色温 → 报告 + CO 请求；非阻塞备注与强制退回分开写。
4. 该进 Tool Registry 的命令是什么？  
   仍用 `.tools/art-venv/bin/python` 一次性脚本；暂不晋升。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   `ART_BRIEF_DESK_WORLD` §5 + 上版 `ui.md` UI-07 表格式。

### Retro · 2026-11-24 · UI-07-X2 书桌世界 X2 审稿
1. 目标是否达成？证据（命令/路径/截图）？  
   是。`docs/reports/v0.88.0/ui.md` UI-07-X2 表；Pillow 度量（尺寸/xor/ink/页框/接缝）；总览目视。
2. 哪一步最耗时或最易错？  
   区分「页框中心透明」(DW-18) 与「插页卡空白纸面」(DW-16 insert)——后者中心不透明是正确的。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   复用 X1 审稿清单：BRIEF 尺寸表 → RGBA 角透明 → 开合外围 xor（若要求插值）→ 特规（墨迹 L/中心白、平铺接缝、页框中心 α）→ 总览色温 → 报告+迁入请求。
4. 该进 Tool Registry 的命令是什么？  
   `.tools/art-venv/bin/python` + 一次性审稿脚本即可；暂不晋升独立 tool。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   `ART_BRIEF_DESK_WORLD` §0/§批表/§4 + 上版 `ui.md` UI-07 表格式。

### Retro · 2026-11-24 · UI-X0 书桌世界站位设计稿
1. 目标是否达成？证据（命令/路径/截图）？  
   是。`docs/design/DESK_WORLD_STATIONS.md`；线框 `assets/ui/wireframes/desk_world/00–04`；报告 `docs/reports/v0.88.0/ui.md` §10。
2. 哪一步最耗时或最易错？  
   把现网 DeskMesh/BookRoot/镜头对齐到七站位相对位姿，并与 ART_BRIEF 像素规格写成同一套「相对日记开书宽 %」。
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）  
   见 `drafts/desk-world-station-brief.md`（先锚日记足迹 → DW 相对% → SVG 线框 → 报告+AR-04）。
4. 该进 Tool Registry 的命令是什么？  
   无新命令（SVG 拼贴即可）。
5. 下次同一类任务，第一条该读哪份 Skill/Draft？  
   `drafts/desk-world-station-brief.md` + EXPERIENCE §2 + ART_BRIEF_DESK_WORLD。
