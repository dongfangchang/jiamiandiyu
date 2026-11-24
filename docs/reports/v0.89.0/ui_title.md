# v0.89.0 UI 报告（轨道 A：P0-1 标题站 + UI-X0-rev）

```text
版本：v0.89.0
角色：UI（轨道 A）
任务：P0-1 删除标题旧界面并重建为"合书 + 书签纸条文字菜单"；UI-X0-rev 按 ADR-0034 修订站位设计稿
状态：完成（自动化与截图已验证；真窗口验收待用户；UI-X0-rev 待架构师 AR-06 评审）
```

## 修改文件

- 设计：`docs/design/DESK_WORLD_STATIONS.md`（新增 §0.1 交互总则；改写 §3.1 标题站、§3.3 索引卡、§4 输入状态表；§1/§5 中 DW-04、DW-07 行）
- 代码：
  - `src/ui/start_screen.gd`（重写：973 → 430 行）
  - `src/ui/title_desk_stage.gd`（重写：纯画面桌面）
  - 新增 `src/ui/title/title_paper.gd`（纸条与文字条目）、`src/ui/title/title_sheets.gd`（设置 / 确认 / 引导 / 反馈纸签）
  - `data/registry/assets.json`：props 新增 `desk_book_closed`、`desk_candle_lit`、`desk_folder_closed`、`desk_slip` 及各自 `_shadow`（指向已迁入的 `assets/game/desk_world/**`）
- 测试：
  - 新增 `tests/ui/title_station_runner.(gd|tscn)`
  - 删除 `tests/ui/title_open_beat_cover_runner.*`（只为遮罩存在）
  - 更新 `ui_smoke_runner`、`v08_system_ui_smoke_runner`（改为按文字按条目，不再访问私有成员）、`v039_table_sfx_runner`、`v047_scene_runner`（删除雨夜底图断言）、`ui_capture_runner`
  - `tests/integration/app_driver.gd` 新增 `text_item()` / `press_title_item()`；`app_flow_runner`、`v07_app_flow_runner` 改为按文字按「继续」「挑战」；`v092_destructive_runner` 改为先按「设置」再按「恢复上次备份」；三个 monkey runner 把「离开」列为破坏性条目，「进入挑战档案」改为「挑战」
- 守卫：`tools/run_tests.sh` 与 `tools/run_tests.ps1` 新增两条阻断守卫
  - `src/ui` 中不得出现 `TitleOpenCover`
  - 已改造站位（`start_screen.gd`、`title_desk_stage.gd`、`src/ui/title/`）中不得出现 `SceneBackgroundHolder` 或 `add_background(`
  - 说明：派工原文要求 `grep 'SceneBackgroundHolder' src/ui` 为空，但 `mask_ui_theme.gd` 的 `add_background` 仍被其他未改造屏使用（会命中），所以按版本文档 §4"只对已改造的站位生效"收窄范围。

## 删除内容（ADR-0034 D2）

- 旧面板：「雾都入口 / 假面低语」标题、玩法说明、检查点摘要、「继续上次战斗 / 开始新游戏 / 退出」行、「进入挑战档案」行、「设置与玩法说明 / 恢复上次备份 / 测试档案」行、底部提示与页脚。
- 雨夜底图：`add_background` 调用、`title_background()`、`SceneCatalog` 依赖；`SceneBackgroundHolder / SceneDim / SceneFallback` 的隐藏逻辑。
- 隐形热区：`_install_desk`、`bind()` 再托管、`_pass_through_layout`、`_fade_panel_chrome`、`_sync_desk`、字号缩到 1 的透明按钮文字。
- `TitleOpenCover` 与开书盖黑。
- 原生 `ConfirmationDialog` 改为纸签确认；设置里的 `CheckButton` 和档案页签行改为文字开关和文字选项。
- 净删除：src+tests 共 −1226 / +1364 行（含新增测试 213 行）；`start_screen.gd` 删 813 行。

## 新标题站

- 画面：俯视木桌，桌上依次是合书（DW-05）、烛台（DW-06，同时是暖光源）、卷宗夹（DW-01 合态，作挑战联动物），都带阴影，外加暗角。所有节点 `mouse_filter = IGNORE`，桌面上没有任何按钮。
- 书签纸条（DW-04 九宫格竖条）贴在书右缘，文字全部用思源宋体：
  - 题名「假面低语」38px
  - 摘要：`记者 · 序列 9` 22px，`保存于 2026-11-08 02:30` 17px；无存档时写「尚无日记」；损坏时写「日记无法读取」+「原始存档已保留」+ 错误原因
  - 菜单 28px：继续（仅有检查点时）/ 新的日记 / 挑战（仅解锁时）/ 设置 / 离开；「测试档案」18px，只在 `OS.is_debug_build()` 时出现
  - 版本号 15px
- 交互：悬停或键盘聚焦时，墨色加深为蜡红，并显示下划线；对应物件提亮（继续 / 新的日记 / 测试档案 → 书，挑战 → 卷宗夹，离开 → 烛台）。打开时默认聚焦「继续」，没有存档则聚焦「新的日记」。
- 开书：只把所选物件推近（0.42 秒，放大 1.14 倍并移向中心），之后交给路由器淡出。桌面始终不透明，没有遮罩。回到标题时由 `set_busy(false)` 复位。
- 设置（二级纸签）：全屏、减闪、静音三个文字开关，界面缩放 90/100/110%，操作提示 `OpsHint`，以及「重新查看新手引导 / 记录试玩反馈 / 恢复上次备份 / 合上」。恢复结果写在主纸条和设置纸签上。
- 新的日记（已有存档时）：弹出确认纸签「覆盖当前进度？」，条目为「取消 / 开始新的日记」。
- 信号名全部保留，`src/app/**` 未改。

## 验证

- `tools/run_tests.sh`：`run_tests: pass=92 fail=0 skipped=10 guard_block=0`。
- 黄金回放：`tests/golden/` 无改动，并且全绿。
- `title_station_runner`：163 项检查，OK。覆盖以下内容：
  - 场景树中所有 `BaseButton` 都是带标记的文字条目，有可读文字、无图标；纸签关闭时只允许菜单文字
  - 没有名字含 `Cover / SceneBackgroundHolder / SceneDim / SceneFallback` 的节点
  - 桌面和所有物件都 IGNORE 鼠标，桌面没有按钮
  - 摘要使用思源宋体
  - 无存档、有存档、损坏三种菜单与摘要
  - 聚焦联动：书、烛台、卷宗夹
  - 设置纸签的开合，关闭后不留按钮
  - 确认纸签
  - 开书时书被推近，桌面和屏幕 alpha 最小值 ≥ 0.999，复位后恢复
- 集成测试按文字按条目，继续、新游戏、挑战三条流程都已走通（`app_flow_runner`、`v07_app_flow_runner`、`v092_destructive_runner` 全部 PASS）。
- 截图（非 headless，Apple M4 / Compatibility），已逐张查看：
  - 1600×900：`.tools/ui-captures/v089_title_rest_1600x900.png`、`v089_title_focus_continue_1600x900.png`、`v089_title_settings_1600x900.png`、`v089_title_open_mid_1600x900.png`
  - 大窗口（请求 2920×1753，macOS 实际给出 2848×1602 物理像素）：同名 `_2920x1753.png` 四张
  - 结论：文字锐利，大窗口下按物理分辨率渲染（canvas_items 拉伸），墨色压在纸上可读。画面上没有平面面板，纸条是桌上的物件。
  - 复现命令：`"$GODOT" --path . res://tests/ui/title_station_runner.tscn -- --capture [--capture-size=2920x1753]`

## 手动检查（6 步）

1. 启动游戏，标题只有木桌、合书、烛台、卷宗夹和右侧纸条，不出现任何旧面板或雨夜图。
2. 鼠标移过「继续 / 新的日记」，字变成蜡红并出现下划线，合书提亮；移到「离开」时烛台提亮，移到「挑战」时卷宗夹提亮。直接点书、烛台、卷宗夹都没有反应。
3. 用 Tab / 方向键在条目间移动，下划线和物件联动跟着焦点走；按回车可以触发。
4. 点「继续」，书推近后画面淡出进入游戏，中间不露出黑幕后的任何旧界面。返回标题后，书回到原位。
5. 有存档时点「新的日记」，弹出确认纸签；点「取消」关闭，点「开始新的日记」进入建档。
6. 点「设置」，打开二级纸签，逐项切换开关、缩放，「恢复上次备份」在有备份时可点，「合上」关闭。

## 困难与候选方案

- 九宫格 `NinePatchRect` 不是容器，二级纸签无法随内容撑开，首张截图中设置纸签塌成一条。
  - 候选 A：固定尺寸。
  - 候选 B：改用 `PanelContainer` + `StyleBoxTexture`（同一张 DW-04 纸）。
  - 选 B：纸张随内容自适应，主纸条仍用锚点定位。
- 挑战未解锁时，派工要求不列出该条目，但原测试断言"锁定原因可见"。
  - 最终选择：不列出条目，`get_challenge_hint_text()` 仍返回原因供查询；测试消息相应调整。如需在纸条上显示锁定原因，请产品裁决。
- 桌面构图选择：
  - 候选 A：继续用 `title-desk-wide` 斜视画板。画上已经画了一本书，再叠 DW-05 会出现两本书。
  - 候选 B：俯视木纹 + DW 物件。
  - 选 B：与 X1 DeskWorld 的俯视布局一致。

## 风险 / 未决

- monkey runner（默认不跑）：`v079_monkey_coverage_runner` 报覆盖缺口「challenge_hub 未到达」。我在基线 76d02d5 的独立 worktree 上复测，结果相同，属于既有问题，与本次修改无关。`v080_monkey_rich_runner` 在 240 秒内超时，未在基线上复测。`v078` 通过。
- 标题站仍是 2D 合成。X1-01 常驻 3D DeskWorld 落地后，应把物件迁入 3D，纸条菜单逻辑（`title_paper` / `title_sheets`）可以复用。
- `_identity_name` 是沿用的 ID → 中文映射。建议后续由快照提供 `identity_display_name`。
- 新增 `.gd` 文件尚未生成 `.uid`（headless 不生成），编辑器打开时会自动补齐。

## 跨角色请求

- 架构师：评审 UI-X0-rev（AR-06）；确认守卫的收窄范围（只针对已改造站位）。
- 产品经理：挑战未解锁时是否在纸条上显示灰字和原因。
- 主协调者：`art/ASSET_MANIFEST.md` 如需登记 registry 新增的 8 个 prop id，请补充。

## 下一步入口

- X1-01 / X1-03：把标题站迁入常驻 DeskWorld（3D 合书 + 纸条 SubViewport），复用 `src/ui/title/`。
- 索引卡（§3.3）可以复用 `title_paper.text_item()`。
