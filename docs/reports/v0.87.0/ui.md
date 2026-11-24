# v0.87.0 UI 报告（轨道 B：界面死代码 R1-03 / R1-04）

```text
版本：v0.87.0
角色：UI（轨道 B）
任务：R1-03 删除 route_screen / ui_preview 及只测它们的探针；R1-04 删除 diary_chapter_screen 中的 2D 书、flip3d、索引面板、页角拖拽、墨晕/霉斑/光晕/笔触覆盖等旧载体
状态：完成
修改文件：见下
依赖：DIARY_DESK_3D_BRIEF（DeskStage 为唯一载体）；v0.86 ScreenRouter 钩子（on_enter/on_exit/set_pending）与日记缓存（NAV-03）
验证：tools/run_tests.sh 全绿（见「验证」）；黄金回放未改动；v084 GPU 截图前后目视一致
困难与候选方案：见下
最终解决：见下
风险：见下
跨角色请求：见下
下一步入口：见下
```

> 本报告只覆盖轨道 B。轨道 C（BUG-0038，`diary_ui_catalog.gd`）由另一位 UI 负责，本轨道未触碰该文件及其测试。

## 修改文件与行数

| 文件 | 之前 | 之后 | 说明 |
|---|---|---|---|
| `src/ui/route_screen.gd`（+ `.uid`） | 488 | 删除 | 生产零引用（路线图自 v0.55 起由日记承担） |
| `scenes/ui/route_screen.tscn` | 12 | 删除 | 同上 |
| `src/ui/ui_preview.gd`（+ `.uid`） | 577 | 删除 | 零引用 |
| `scenes/ui/ui_preview.tscn` | 12 | 删除 | 同上 |
| `src/ui/diary_chapter_screen.gd` | 2,945 | 830 | R1-04，目标 < 1,500 ✓ |

`src` 合计：+219 / −3,401，净减 **3,182 行**（`git diff --shortstat dbdcdea -- src`）。

删除前已确认：`grep route_screen / ui_preview` 在 `src/`、`scenes/`、`project.godot`、`tools/` 中无生产引用；`app_controller.gd` 的 `RouteScreenScene` 常量本来就指向 `diary_chapter_screen.tscn`，`_show_route_screen()` 只是方法名，**`src/app/**` 未修改**。

## R1-04：diary_chapter_screen 删除内容

从 DeskStage 主路径 + router 钩子出发追调用图，以下全部不可达或「建好即隐藏」：

- `_book_root` 整棵 2D 书树：`DiaryBookArt`、`PageEdgeShadow`、`FlipCurlShade`、`InkSealCoagulate`、`DiaryBook`/`PageCurrent`/`PageNext`、`GazeWarp`、`BookmarkRibbon`、`CorruptionMold`(+霉斑)、`SpiritMarginNote`、`GazeDisturb`、`CandleVeil`/`CandleCorner`/`CandleVignette`、四角磨损、页角拖拽提示、`InkTrail`。
- 页面渲染：`_make_spread_layer`、`_page_column`、`_render_spread`、`_clear_spread`、`_page_masthead`、`_ornament_line`、`_build_passage`（`ClueHit` 隐藏按钮）、`_obscure`、光晕 `_start_glow/_set_glow/_stop_glow`（目标只来自 `_build_passage`）。
- flip3d：`_build_flip_3d`、`_make_page_material`、`_play_flip_3d`；`_flip_to`（无调用者）及其独占的 `_finish_flip`、`_set_edge_shadow_progress`、`_set_page_next_for_flip/_idle`、`_set_tree_mouse_filter`。
- 页角拖拽：`_on_book_gui_input`、`_is_page_corner`、`_notification` 指针追踪、凝视漂移。
- 索引：`_build_index_panel`、`_on_index`、`_set_index_open`、`_on_edge_index_hover`、`_rebuild_index_list`、`_index_jump`、`_build_index_chain`、`_advance_index_chain`、`_clear_index_chain`、`_play_ink_trail`、`_furthest_open_idx`。
- 笔触覆盖层：`_build_pen_overlay`、`_run_pen_overlay`（挂在隐藏的 `_book_root` 下）。主路径的结算反馈仍是：状态句 + `PenFlashBanner` + `DeskStage.play_settlement_fx`。
- 隐藏的按钮与仪表：「前一页/后一页/页边」按钮（`visible=false`）及只服务它们的 `_on_prev_page/_on_next_page/_resist_flip/_play_ink_seal_coagulate`；隐藏的 `StatusPanel` 四个数值仪表。
- 隐藏背景：`UiTheme.add_background` + 隐藏 `SceneBackgroundHolder`、`LampGlow`（DeskStage 的 3D 视口不透明且全屏，二者本就不可见）。
- 资源加载：`_load_image`（含 `FileAccess`，顺带消除一处 UI 读文件守卫命中）及 `BOOK/INK/RIBBON/GRAIN/PEN` 贴图、蜡烛/凝视 shader 常量；`legacy_book_art_visible()` 探针；`_install_desk_p0` 的「先建后藏」逻辑并入正常构建。
- `_request_desk_flip` 去掉只给索引链用的 `duration` 参数。

**保留**（主路径或公开 API）：`apply_snapshot`、`apply_command_result`、`present_post_encounter`、`set_challenge_context`、`get_status_text`、`get_background_path`、`get_page_count`、`get_current_spread_idx`、`is_page_flipping`、`request_node`、`get_clue`、`request_close`、`get_desk_stage`、`desk_world_ready`、`on_enter`、`on_exit`、`set_pending`、`get_exit_beat`、全部信号；DeskStage 接线、翻页闸门/回弹、自动翻页、蜡封命令、批注浮层、`DiaryPostFx`（仍置顶 z=100，`_process` 只驱动它）、标题/状态 chrome、「合上」书签（节点名新增 `CloseBookmark`，样式与位置不变）。

## 测试调整

| runner | 处理 | 原因 |
|---|---|---|
| `ui/v05_route_ui_smoke` | 删 `_test_route_screen` | 只测 route_screen；rest/ritual/route_result/敌人图检查保留 |
| `ui/v038_narrative_route` | 删 `_test_route_progress` | 同上；challenge hub/route select/rest 检查保留 |
| `ui/v050_ui` | 删 route_screen 段 | 背景、challenge、battle 检查保留 |
| `ui/v053_canvas_floor` | 删 route 画布段 | battle 地板检查保留 |
| `ui/v054_canvas_not_wireframe` | 删 route header 段 | battle 模块检查保留 |
| `ui/v06_challenge_ui_smoke` | 删 `_test_challenge_route_context` | route_screen 的挑战上下文 UI 已退役（日记的 `set_challenge_context` 为空实现） |
| `ui/v094_response_truth_smoke` | 删 `_test_route_header_contrast_panel` 与 `_find_meta` | 只测 route_screen 表头 |
| `ui/ui_capture`（GPU，默认不跑） | 删 `_capture_route_map`、`_capture_challenge_route` | 同上；`--check-only` 解析通过 |
| `integration/v093_pending_navigation` | `_test_route_hub_while_pending` 改测日记 | 原测 route_screen；改为日记 `set_pending(true)` 后「合上」仍可用、`request_close()` 只发一次 hub 意图 |
| `ui/v055_diary_chapter` | 删旧载体探针 | `SceneBackgroundHolder`、`DiaryBook`、`BookShell`、`DiaryBookArt`、`PageCurrent/Next`、`LeftPage/RightPage`、`LampGlow`、`IndexPanel` 及进度、旧资源存在性、`PenGlyph`、`PenOverlay` 可见；新增「`CloseBookmark` 可用」。checks 59 → 41 |
| `ui/v083_diary_desk_p0` | `V083_NO_BOOK_ART_PATH` 改写 | 原调 `legacy_book_art_visible()`；改为断言屏幕树中没有任何 `open_book_spread.png` 贴图，等价且不依赖私有/隐藏节点。checks 仍为 21 |
| `ui/v056_diary_capture`（GPU） | `_resist_flip` → `get_desk_stage().flip_committed.emit(1)` | 回弹走 DeskStage 公开信号 |

monkey runner（默认不跑）只按名字查找 `ClueHit` / `_on_book_gui_input`，找不到时本就会跳过，未改，`--check-only` 解析通过。

## 验证

- 基线（改动前）：`run_tests: pass=85 fail=0 skipped=9 guard_block=0`。
- 改动后全量：见文末「最终结果」。
- 黄金回放 `tests/golden/expected.json` 未改动，未使用 `--update`。
- 目视：改动前后各跑一次非 headless `tests/ui/v084_diary_desk_capture_runner.tscn`（macOS GPU），对比 `v084_desk_idle.png` / `v084_desk_flip.png`：桌面、蜡烛、羽毛笔、书本、插画、右页文字、蜡封、符文栏、「合上」书签、标题和状态句完全一致；翻页中帧的书页弯曲与背面文字一致。差异仅为后期颗粒噪声。
- `app_flow_runner` 日志中的 `Lambda capture ... was freed` 报错在基线就存在（基线 47 条，改动后 42 条），与本轨道无关。

## 困难与候选方案

1. **测试探针依赖隐藏节点**（v055、v083、v056、v093）。
   - 候选 A：保留隐藏节点让探针继续通过——违反 AGENTS §6「禁止为探针保留隐藏节点」。
   - 候选 B：删除探针或改为 DeskStage 公开 API / 行为断言。
   - 选择 B，逐条在上表说明。
2. **`on_enter` 焦点**：旧逻辑是「后一页可用则聚焦后一页，否则聚焦合上」，但后一页按钮一直是隐藏的，所以可前翻时实际上**没有任何控件获得焦点**。
   - 候选 A：照抄条件，保留这个空焦点。
   - 候选 B：始终聚焦「合上」。
   - 选择 B（NAV-09 的本意是日记有默认焦点）。这是唯一可感知的差异：键盘焦点框出现的时机更稳定。**请产品经理确认**；如需完全不变，只需恢复一行条件。
3. **背景层**：删除 `add_background` 后 `SceneFallback`/`SceneDim` 也不再创建。由于 DeskStage 的世界视口不透明且铺满全屏，这些层在真窗口中本就被完全遮住，GPU 截图对比确认无变化。

## 风险

- 真窗口交互（拖拽翻页、蜡封、合上、战斗往返缓存）只经过自动化和截图验证，需要用户抽查（版本验收已包含此项）。
- `on_enter` 焦点差异见上。

## 跨角色请求

- **主协调者 / 轨道 D**：以下资源在 `src/`、`scenes/`、`data/` 中已无引用，可纳入归档：`assets/ui/diary/ink_blot.svg`、`bookmark_ribbon.png`、`parchment_grain.svg`、`pen_008.svg`、`candle_vignette.gdshader`、`gaze_distort.gdshader`。`open_book_spread.png` 仍被 `route_result_screen.gd` 使用；`parchment_grain.png` 仍被 `diary_desk_stage.gd` 使用。本轨道按约定未改动 `assets/**`。
- **本地数据层 / 后续 R3**：`app_controller.gd` 中的 `RouteScreenScene` / `_show_route_screen` 命名已名不副实（实为日记），可在 app 层整治时改名。本轨道未改 `src/app/**`。
- `route_ui_catalog.gd` 中 `ROUTE_STATE_ICON`、`route_state_icon()` 等原供 route_screen 使用的部分可能已成死代码，建议 R2/R3 时清点（不在本条目范围）。

## 下一步入口

- `diary_chapter_screen.gd` 830 行，仍略高于 UI 800 行预算；若再新增功能，可把 chrome 构建（top/bottom/close bookmark/annotation）拆成独立 `diary_desk_chrome.gd`。
- `diary_desk_stage.gd`（1,610 行）是下一个超预算文件。

## 提交

- R1-03：`refactor(ui): delete retired route_screen and ui_preview (R1-03)`
- R1-04：`refactor(ui): drop the hidden 2D diary carrier from diary_chapter_screen (R1-04)`
- 未推送（按派工要求）。

## 最终结果

`tools/run_tests.sh`（macOS，Godot 4.7.2 headless，R1-04 改动后）：

```text
run_tests: pass=85 fail=0 skipped=9 guard_block=0
```

`golden_replay_runner` PASS，`tests/golden/` 无 diff。`ui reads files directly` 守卫中 `diary_chapter_screen.gd` 已不再出现。
