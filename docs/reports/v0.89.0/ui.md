# UI 报告 · v0.89.0

## UI-KEY-DIARY-JOINT · 日记目标帧联合纪要（2026-11-25）

```text
版本：v0.89.0
角色：UI 设计（与 art 共同决策）
任务：UI-KEY-DIARY-JOINT → 解锁 ART-KEY-02b（candidate_v3）
状态：完成（设计纪要；非画面实现）
对照：title/approved.png；驳回样 art/key_frames/diary/candidate_v2.png
约束：ADR-0037 附录 A；EXPERIENCE §5.1；ADR-0034 D1/D3
修改文件：docs/reports/v0.89.0/ui.md（本节）；.cursor/agents/ui-designer/tasks.md
验证：纪要自检（落点% / 字号 / 禁浮层 / 印纸准则）— 本轮无改 src/ui
跨角色请求：art 按本节开 ART-KEY-02b，出 diary/candidate_v3.png
下一步：用户拍板 → diary approved.png；其后才续 UI-P0-3 画面实现
```

### 驳回根因（必须消除）

`candidate_v2` 右页正文落在**半透明米黄矩形浮层**上，与书页透视/纸纹脱节，读起来像 HUD 叠字，不是「印在本子上」。

### 坐标系

以下百分比相对**右页纸面外轮廓**（含花边框内缘之前的整页矩形；原点 = 右页左上角，x 向右、y 向下）。画稿与实现均按此矩形对齐。

### 落点矩形（相对右页 %）

| 元素 | 矩形 (x%, y%, w%, h%) | 边距 / 行宽约束 |
|---|---|---|
| **题名** | `(12, 9, 70, 7)` | 上缘距页顶 ≥9%；左勿压左上花饰；右缘距页右 ≥14%；题名 ≤10 字单行 |
| **正文** | `(12, 18, 68, 46)` | 行宽 ≈ 右页宽 68%；与花边框内侧净空 ≥ 页宽 8%；笔迹 ≤60 字量级，可 2–3 段 |
| **蜡封「启」** | 圆心约 `(72, 82)`，直径 ≈ 页宽 **16–18%** | 单枚红蜡；「启」**压印在蜡面正中**（ADR-0037 附录：合并双印）；勿另画第二枚圆章 |

页脚/叶号若需要：贴右页底缘内侧 `(12, 90, 50, 5)`，字号走注脚档，不得抢正文。

### 字号 · 行距 · 墨色（1600×900 屏上等效）

| 层级 | 屏上字号 | 行距 | 墨色（目标） | 对比度 |
|---|---|---|---|---|
| 题名 | **≥ 28 px**（目标 30–32） | 单行 | 深褐墨 `#26140A`～`#2A160B` | ≥ 4.5:1 vs 纸面亮区 |
| 正文 | **≥ 20 px**（目标 22–24） | **1.40× 字号**（约 +6–8 px 行间） | 正文墨 `#21120A`；可微暖 | ≥ 4.5:1 |
| 蜡封「启」 | **≥ 22 px**（目标 24–28） | — | 蜡上压印：近白/浅骨色 `#F2E8D8`，靠蜡红衬托 | 相对蜡面可辨；不作 HUD 白字 |
| 注脚 / 叶号 | ≥ 15 px | 紧 | 淡墨褐 `#42301A` | ≥ 3:1 |

纸面基准（B 铜版）：米黄旧纸约 `#E4D2B0`～`#D8C49A`，带横线/纤维；**禁止**在字后另铺不透明或半透明色块底板。

### 「印在纸上」准则（目标帧硬闸）

1. **禁止**半透明 / 实色 HUD 浮层、圆角卡片、屏幕空间面板垫在字下面。
2. 文字必须落在**纸面 UV / 透视内**：随右页微曲与镜头俯角变形；可接受轻微纸面透视拉伸。
3. 墨迹与纸同光照：左近烛侧可略暖亮，右暗部墨可略沉，但**全页对比度仍达标**；禁止「字永远同一屏幕白」无视烛光。
4. 花边框、横线、涂鸦是纸面装饰层；字在装饰**之上**但不穿出框内安全区。
5. 合成验收自问：抹掉字后纸面应仍完整；字是印上去的，不是贴了一张 UI 贴纸。

### 给 art（ART-KEY-02b）的出图指令

- 交付 `art/key_frames/diary/candidate_v3.png` @1600×900。
- 环境 = A 油画暗室，与 `title/approved.png` **同房同桌同烛**；纸面 = B 铜版。
- 底图书页**不画最终汉字**（或仅极淡示意线）；正式文案用思源宋体按上表落点叠真实样本文案（题名例：「第一卷 · 雨夜来信」；蜡封「启」）。
- 自检：无浮层底板；题名/正文/启落在表内矩形；一眼能感到字在本子上。

---

## UI-KEY-DESK-JOINT · 桌面 hub 目标帧联合纪要（2026-11-25）

```text
版本：v0.89.0
角色：UI 设计（与 art 共同决策）
任务：UI-KEY-DESK-JOINT → 解锁 ART-KEY-03-rev（options_v2）
状态：完成（设计纪要；非画面实现）
对照：title/approved.png；驳回样 art/key_frames/desk/options/overview.png
约束：ADR-0037；EXPERIENCE §5.1；DESK_WORLD_STATIONS §3.3；ADR-0034 D1
修改文件：docs/reports/v0.89.0/ui.md（本节）；.cursor/agents/ui-designer/tasks.md
验证：纪要自检（物件材质 / 入口层级 / 悬停 / 禁白底便签）— 本轮无改 src/ui
跨角色请求：art 按本节开 ART-KEY-03-rev，出 desk/options_v2/{1,2,3,overview}.png
下一步：用户选型 → desk approved；风格闸过后再解 ART-KEY-04…
```

### 驳回根因（必须消除）

overview 三方案菜单载体是**低饱和纯白/近白平底便签**：无烛火暖橙反光、无接触阴影、笔触与油画桌面脱节，呈悬浮 HUD 感。构图差异可保留，**载体必须重做**。

### 索引卡 = 桌面物件（材质 / 光影规格）

| 项 | 规格 |
|---|---|
| 身份 | 桌面右前角的**旧索引卡 / 铜版便笺**（DW-07b 族），平放或微仰 ≤8°；不是屏幕 UI 面板 |
| 纸色 | 旧米黄 / 亚麻纸 `#C9B089`～`#D4BC96`；允许局部污渍、纤维、淡书写线；**禁止**纯白 `#FFF`、低饱和冷灰白底、现代便利贴 |
| 笔触 | 纸面层走 **B 铜版**；边缘毛茬、轻微折痕；与 `title/approved.png` 中羊皮纸/残页同一世界 |
| 烛光 | **必须吃左/场景主烛暖橙**：近烛缘高光偏橙 `#E8A060` 量级；远缘落入桌面阴影；卡面 albedo 随光衰减，禁止整卡均匀曝光 |
| 阴影 | 卡底有**接触阴影**贴桌（参考 DQ-06 语汇）；禁止「漂在空中」的无接缝投影 |
| 尺寸感 | 屏上卡面大约 280–340 px 高（1600 宽画幅）；六行书写线可见；不遮主物件识别 |

### 入口文案层级（信息架构）

固定六行，思源宋体，顺序不可改（与 §3.3 一致）：

```text
日记
档案
卡匣
祈愿
卷宗
熄烛
```

| 层级 | 规则 |
|---|---|
| 字号 | **≥ 22 px**（目标 **24 px** @1600×900） |
| 字色常态 | 深褐墨 `#2A1810`，对比度 ≥ 4.5:1 vs 卡面受光区 |
| 行结构 | 一行一条；行距 ≥ 1.35×；对齐书写线；左缩进统一 |
| 装饰 | 可用极淡中点 `·` 或行首缺口，**禁止**按钮底、描边胶囊、平面图标条 |
| 控件原则 | 只有这些文字是可操作入口；物件不可点（ADR-0034 D1） |

### 悬停 / 聚焦态（卡面 + 物件联动）

| 通道 | 行为 |
|---|---|
| 卡面文字 | 当前行墨色加深或微金褐提亮（仍吃烛光，禁止霓虹/纯白描边）；可加极细下划线贴书写线 |
| 对应物件 | 同步提亮：日记→书；档案→档案夹；卡匣→卡匣；祈愿→祈愿台/镜；卷宗→抽屉/卷宗；熄烛→烛焰微晃或焰侧提亮 |
| 卡身 | 可选极弱边缘暖光（仍像纸被烛照，不是 UI glow） |
| 禁用 | 若条目不可用：灰褐墨 + 仍印在卡上；原因短注用更小字（≥15 px）写在该行下，不另开浮层 |

目标帧至少标一格「悬停示意」（例如「日记」行高亮 + 书提亮），与驳回 overview 角标同级说明即可。

### 禁止清单（风格闸）

- 白底 / 近白纯色便签、现代 sticky note、半透明 HUD 条
- 不接烛光的均匀填色卡、无接触阴影的悬浮板
- 把菜单做成与油画笔触无关的矢量扁平块
- 用物件热区代替文字入口

### 给 art（ART-KEY-03-rev）的出图指令

- 交付 `art/key_frames/desk/options_v2/{1,2,3,overview}.png` + README；方案构图可沿用原 1/2/3 差异，**索引卡必须按上表重画进场景光**。
- 对照 `art/key_frames/title/approved.png` 的房间/桌/烛气质。
- 卡面可留空白书写线；正式六行文案用思源宋体按层级叠上。
- 自检三问：① 是否像桌上旧纸？② 近烛是否暖橙、是否有落影？③ 能否一眼不是白便签 HUD？

---

## UI-CH-GREY + UI-RENDER-MOBILE（2026-11-25）

```text
版本：v0.89.0
角色：UI 设计
任务：UI-CH-GREY（挑战未解锁灰色+原因）＋ UI-RENDER-MOBILE（ADR-0036 Mobile 最小校正）
状态：完成
修改文件：
  src/ui/start_screen.gd（挑战始终列出；锁定时 disabled + FOCUS_NONE；ChallengeHint 20px 宋体）
  tests/ui/title_station_runner.gd（锁定可见/不可聚焦/原因非空；解锁可点）
  project.godot（rendering_method / .mobile → mobile）
  src/ui/diary_desk_quality.gd（Mobile exposure=3.0、glow SCREEN；SSAO 仅 forward_plus）
  src/ui/diary_desk_stage.gd（页面 specular_mode=SPECULAR_DISABLED）
  tests/ui/diary_quality_wiring_runner.gd（曝光/SSAO/specular 断言）
  tests/ui/v089_diary_quality_capture_runner.gd（截图路径改 mobile）
  docs/reports/v0.89.0/ui_render_mobile_diary_{1600x900,2920x1753}.png
验证：
  tools/run_tests.sh → pass=95 fail=0 skipped=14 guard_block=0
  title_station_runner / diary_readability_runner / diary_quality_wiring_runner 全绿
  capture method=mobile driver=metal；1600×900 正文可读
困难与候选方案：锁定挑战是隐藏还是灰显 → 用户裁决灰显+原因
最终解决：功能 GREY + Mobile 曝光/specular 最小校正；不做风格调优（ADR-0037）
风险：HiDPI Mobile avg≈28 fps（抽样）；画面风格仍待目标帧
跨角色请求：无
下一步入口：ART-KEY 目标帧；UI-X1 功能轨
commit：f898e33（已 push origin/main）
```

### UI-CH-GREY

| 状态 | 「挑战」 | 原因行 |
|---|---|---|
| 未解锁 / 无存档 / 损坏 | 列出、灰色、`disabled`、`FOCUS_NONE` | `ChallengeHint` 显示 `get_challenge_hint_text()` |
| 已解锁 | 可点、可聚焦 | 隐藏 hint |

### UI-RENDER-MOBILE

| 项 | 值 |
|---|---|
| `rendering_method` | `mobile` / `.mobile=mobile` |
| `tonemap_exposure` | compat 1.15 / RD(Mobile) 3.0 |
| 页面材质 | `SPECULAR_DISABLED` |
| 正文对比度 | readability ≥4.5（body≈5.47） |
| 截图 | `docs/reports/v0.89.0/ui_render_mobile_diary_1600x900.png` |

---

## UI-P0-3-reject · 背景板遮挡退回修复（2026-11-25）

```text
版本：v0.89.0
角色：UI 设计
任务：UI-P0-3-reject（RoomBack 遮挡书页 + D2 删旧书签）
状态：完成
方案： (a) 直立远置 — RoomBack 移到书桌远沿之后 pos (0, 1.05, -1.72)、rot (0,0,0)；
      禁止 −62° 后仰把下沿甩进镜头→书页视锥。
修改文件：
  src/ui/diary_desk_stage.gd（RoomBack 远置直立；书签只调 attach_bookmark_ribbon）
  src/ui/diary_desk_quality.gd（replace_bookmark_ribbon → attach_bookmark_ribbon；删除 visible=false 藏旧节点）
  src/ui/diary_page_occlusion.gd（AR-07 协作落地；舞台公开 get_page_occlusion_report）
  tests/ui/diary_readability_runner.gd（AR-07 遮挡采样断言）
  tests/ui/diary_quality_wiring_runner.gd（z≤−1.4 / 直立 / 无 BookmarkProp）
  project.godot（rendering_method 回 gl_compatibility，遵守 UI-P0-3-renderer-hold；保留 SSAO 等无关调优）
  docs/reports/v0.89.0/ui_p0_3_fix_diary_{1600x900,2920x1753}.png
验证：
  tools/run_tests.sh → pass=95 fail=0 skipped=14 guard_block=0
  diary_readability_runner DIARY_READABILITY_OK checks=43（含 AR-07 遮挡）
  diary_quality_wiring_runner checks=33 failures=0（z=-1.72 / upright / 无 BookmarkProp）
  截图：docs/reports/v0.89.0/ui_p0_3_fix_diary_{1600x900,2920x1753}.png
  目视：右页题名「密修会的闯入者」/正文/蜡封「启」与左页整幅插画完整可见；书宽约 55–65%
困难与候选方案：
  (a) 远置直立  (b) 2D 远景层  (c) 本站不显示 → 采纳 (a)
最终解决：远置直立 + D2 单节点书签；AR-07 线段/AABB 遮挡守卫绿
风险：陡读镜头下远墙几乎出画（可接受）；渲染器仍待用户裁决 ADR-0035/36
跨角色请求：请用户真窗确认；AR-07 可标 done（与本条同证据）
下一步入口：用户签字 → UI-P0-3-renderer-hold 裁决后调色
```

### DQ-01 摆放（reject 后）

| 项 | 退回坏值 | 修复后 (a) |
|---|---|---|
| 板位 | `pos (0,0.52,-0.78)`，`rot.x=-62°` | `pos (0,1.05,-1.72)`，直立 |
| 尺寸 | 3.8×2.2×0.04 | 4.2×2.4×0.04 |
| 理由 | 下沿甩进书页视锥，遮题名/正文 | 整板在书页 z 后方；采样射线先到页 |

---

## UI-P0-3-sync · 合入 P0-2 可读性（2026-11-24）

```text
版本：v0.89.0
角色：UI 设计
任务：UI-P0-3-sync（先提交 P0-3 → rebase origin/main P0-2 → 保留可读性底线并叠回质量层）
状态：完成
修改文件：
  src/ui/diary_desk_stage.gd（ReadingMetrics + DeskQuality；DQ-01 后墙按 −75° 镜头后仰 −62°）
  src/ui/diary_page_pair.gd（PAGE_SCALE/px/INK_FADE_LOCKED + DQ-04/蜡封 caption；装饰走 px()）
  src/ui/diary_chapter_screen.gd（丝带「合上」+ CHROME_CLOSE_PX 宋体底线）
  （其余 P0-3 / fix 文件随 rebase 提交一并带上）
冲突文件（手改）：diary_desk_stage.gd / diary_page_pair.gd / diary_chapter_screen.gd
验证：
  tools/run_tests.sh → pass=95 fail=0 skipped=13 guard_block=0
  diary_readability_runner PASS；diary_quality_wiring_runner PASS
  合入后截图刷新：docs/reports/v0.89.0/ui_p0_3_fix_diary_{1600x900,2920x1753}.png
困难与候选方案：
  A) 直立后墙保留 → 陡镜头出画
  B) DQ-01 板向镜头后仰 −62°、贴书桌远沿 → 采纳
最终解决：可读性常量/物理像素视口/新镜头全留；质量层叠在其上；未动 start_screen
风险：物理像素视口 × Forward+ FX 在 HiDPI 上更重；capture 抽样 fps 偏低，请用户真窗确认
跨角色请求：请用户真窗看合入后画面与可读性
下一步入口：用户签字；UI-X1
commit：4d510ce（rebase 后）+ 本报告/tasks 跟进提交
```

### DQ-01 新镜头摆放

| 项 | 合入前（P0-3） | 合入后（P0-2 镜头） |
|---|---|---|
| 板位 | `pos (0,0.9,-0.85)` 直立 | `pos (0,0.52,-0.78)`，`rot.x = -62°` |
| 尺寸 | 4.5×2.6×0.08 | 3.8×2.2×0.04 |
| 理由 | 旧 −59° 俯角能看见后墙 | −75° 长焦后直立墙出画；后仰后填书桌远沿 |

---

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
