# v0.88.0 UI 报告（第二波 T4：资源注册表与文本）

```text
版本：v0.88.0
角色：UI + 主协调者（T4 单一负责人）
任务：R2-09（UI 不读内容文件）、R2-10（资源注册表，收口 4 个卡图来源，挑战 ID 特例改数据）、R2-12（效果文本移出 app 层）、守卫改为阻断
状态：完成（预见减伤数字未接入快照，见“风险”）
```

## 修改文件

- 新增 `data/registry/assets.json`：稳定 ID → `res://` 路径。分区包括 `cards`（window / plate）、`seals`（稀有度.机制 → full / small）、`enemies`、`identities`、`scenes`（含新 ID `scene.ui.canvas`）、`diary_pages`、`status_icons`、`icons`（奖励、升级、路线状态、仪式结果、挑战结果、修饰、挑战徽记、`icon.deck.restricted`）、`ritual_steps`、`props`，以及 `fallbacks`（卡背、各类场景兜底、修饰兜底等）。头字段 `generated_by` 记录生成命令。
- 新增 `data/schema/registry/assets.schema.json`。
- 新增 `tools/gen_asset_registry.gd`：一次性迁移脚本，内含旧目录表，并扫描 v0.85 卡图、印章和日记目录。生成命令：`godot --headless --path . --script res://tools/gen_asset_registry.gd`。迁移完成后，注册表本身就是事实源，主协调者迁入资源时直接改 JSON；重跑脚本会覆盖手工修改。
- 新增 `src/ui/asset_registry.gd`：注册表的唯一读取者，静态加载并缓存。`FileAccess` 是被认可的唯一例外，已在代码中注明。
- 改为查注册表：`card_art_catalog`、`progression_ui_catalog`、`deck_ui_catalog`、`scene_ui_catalog`、`route_ui_catalog`、`challenge_ui_catalog`、`prop_ui_catalog`、`common/card_face`、`battle_screen`、`battle_table_feel`、`result_screen`、`start_screen`、`route_select_screen`、`route_result_screen`、`ritual_screen`、`challenge_screen`、`challenge_result_screen`、`diary_page_pair`，以及其他引用旧常量的屏幕。原来的 `*_BACKGROUND`、`CARD_BACK`、`BOSS_ART` 等常量改为同名小写函数。
- 卡图：原有 4 个来源（progression 的 40 行表、deck 的版本 if 链、card_art_catalog、battle_screen）统一收口到 `card_art_catalog`，再由它查注册表：
  - `card_art()` 返回整卡底图，缺图时回退卡背。
  - `display_art()` 按“插画窗 → 底图 → 卡背”顺序取图，`card_face` 和 `battle_screen` 都用它。
  - `deck_ui_catalog.card_art` 和 `progression_ui_catalog.card_art` 只做转发，保留是为了兼容 `tests/gameplay` 中的调用方。
- AR-16：`challenge_ui_catalog.PRESENTATION` 按挑战 ID 存放 `arc_zh` 和 `select_tag_zh`。两个屏幕改调 `selection_eyebrow()` / `result_eyebrow()`；徽记直接按挑战 ID 查注册表。`src/ui` 中已没有 `challenge.v070.*` 的判断。
- R2-09：
  - `card_art_catalog.configure(card_definitions)` 与 `diary_ui_catalog.configure(volume)` 都是静态方法。
  - `AppController.configure_ui_content()` 是静态方法，在 `_ready` 中调用。它通过 `JsonDocumentLoader` 读取 bootstrap 已登记的卡牌和日记路径，并做 schema 校验后注入。
  - `prop_ui_catalog` 检查源文件时改走 `AssetRegistry.source_exists`。
- R2-12：
  - 新增 `src/ui/text/effect_text.gd`，迁入原来 app_controller 中的 `_format_card_effects`、`_format_single_effect`、`_format_effect_condition`、`_trait_label`、`_status_label`，逻辑逐字不变。
  - 新增 `src/ui/text/app_text.gd`：app 层的提示（toast、检查点状态、兜底名称）改为传消息 ID。
  - `src/app/app_controller.gd` 中已没有中文。
- 测试：
  - 新增 `tests/ui/ui_content_fixture.gd`。42 个不经过 AppController、直接构建屏幕或目录的 runner，在入口处调用 `UiContentFixture.ensure()`。
  - `v011_status_keyword_smoke_runner` 不再访问私有方法 `_format_card_effects`，改调 `EffectText`。
  - 其余 runner 只把旧常量名换成新函数名。
- 守卫：`tools/run_tests.sh` / `.ps1` 中，“UI 不读文件”（白名单为 `asset_registry.gd`）和“UI 无 `res://assets/game/`”两条改为阻断。同时修复了 sh 版 `grep -lc` 会把 0 计数文件也列出的问题。

## 依赖

- bootstrap 中的 `DEFAULT_V07_CARDS_PATH`、`DEFAULT_DIARY_PATH` 及其 schema 常量（只读引用，bootstrap 未改动）。
- `data/schema/v0.7.0/diary.schema.json` 已存在，日记 schema 部分不需要新增。

## 验证

- 等价性：迁移前用旧目录、迁移后用新 API，各导出一份全部查询结果，共 727 项，包括 40 张卡 × 各取图入口、印章、稀有度/机制、敌人、状态图标、全部场景 ID × 4 种类型、日记页、身份、图标、道具及未知 ID 的兜底。
  - 两份结果**完全一致**。唯一差异是导出脚本多枚举了新 ID `scene.ui.canvas`。
- `res://assets/game/` 字面量：`src/ui` 中由 **101 行（10 个文件）降到 0**。约 140 这个说法包含了测试中的同类字面量，测试中的不在本条范围内。
- `FileAccess`：`src/ui` 中只剩 `asset_registry.gd`。
- `tools/run_tests.sh`：`pass=90 fail=0 skipped=10 guard_block=0`，黄金回放通过。`tests/golden/` 无改动，未执行 `--update`。
- GPU 截图：`tests/ui/v084_diary_desk_capture_runner.tscn` 在非 headless 下运行。idle 与 flip 两张截图中，左页肖像插画、桌面木纹、蜡封、四枚状态徽记、蜡烛、墨水瓶和羽毛笔都正常显示。

## 困难与候选方案

1. 注入的时机：
   - 方案 A：`bootstrap.start_route_v07` 把文档交给会话，再由 app 注入。缺点是要改 T5 的文件，而且标题页等进入会话前的屏幕拿不到数据。
   - 方案 B：`AppController` 启动时自行经基础设施加载并注入。
   - **选 B**：只动 app_controller，标题页也有数据。代价是卡牌和日记 JSON 在会话启动时还会再读一次（两份都很小）。
2. 测试数据：
   - 方案 A：每个测试手写 fixture 卡牌。缺点是 40 张卡的稀有度和机制断言会失真。
   - 方案 B：共用 fixture，走生产注入路径。
   - **选 B**。

## 风险

- 预见减伤：`battle_screen` 中的“预见（下次攻击 -1）”仍写死为 1。`foresight_reduction` 只存在于 balance，没有进入战斗快照，所以按派工**保留未改**。需要玩法层在快照里加只读字段（例如 `player.foresight_reduction`）。
- `src/app/bootstrap.gd`（路线预览占位文案、挑战锁定原因）和 `src/app/route_session.gd`（`pathway_name_zh` 等）仍有中文。这两个文件不在 T4 范围内（bootstrap 属于 T5），见“跨角色请求”。
- 注册表加入新卡牌或新资源时必须登记，否则会回退到卡背或兜底图；`v085_card_art_runner` 会报出缺少插画窗的卡。
- `src/ui` 仍有 `res://assets/ui/diary/*` 字面量（seal、grain、book 等）。它们不在本条守卫范围内，可在 X1 并入注册表。

## 跨角色请求

- **T5（本地数据层）**：
  1. R2-08 扁平化后，若卡牌或日记路径常量改名或移动，`AppController.configure_ui_content()` 引用的 `AppBootstrapScript.DEFAULT_V07_CARDS_PATH / _SCHEMA_PATH` 和 `DEFAULT_DIARY_PATH / _SCHEMA_PATH` 必须同步。更好的做法是由 bootstrap 或 manifest 提供 `load_ui_content_documents()`，返回已校验的 `{cards, diary}`，app_controller 改调它。
  2. `bootstrap.gd` 中有中文拼接，包括 `"%d 个调查节点 · 序列 9 占卜家"`、规划占位路线文案和挑战锁定原因，建议在 manifest 或内容数据中改为 ID。
  3. 新增的 `data/schema/registry/assets.schema.json` 目前只供人工和 CI 参考。如果希望启动时校验注册表，可由基础设施提供校验入口；UI 不应自行校验。
- **玩法（战斗）**：在快照中暴露 `foresight_reduction`。
- **产品经理**：`data/registry/assets.json` 属于“全局资源注册表”，是跨角色文件。建议在 v0.88 版本文档中登记由主协调者维护。

## 下一步入口

- 新卡或新资源：在 `data/registry/assets.json` 的对应分区加一行即可，不需要改代码。
- X1：把 `res://assets/ui/**` 也纳入注册表，并配合 theme tokens 处理。
