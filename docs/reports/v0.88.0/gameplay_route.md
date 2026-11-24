# v0.88.0 轨道 T2 路线/日记 报告（玩法 + UI）

```text
版本：v0.88.0（ROADMAP R2 第一波）
角色：玩法设计 + UI（仅 T2 路线/日记轨道）
任务：R2-03 日记快照补字段；R2-04 删除 UI 规则逻辑；R2-05 旁白迁出为 annotation_id；R2-06 路线平衡值迁入 data/balance
状态：完成（黄金哈希按 §3 政策未更新，见“黄金回放语义差异”）
修改文件：
  data/diaries/v0.55.0/tingen_volume_1.json（新增 annotations 段，schema_version 1→2）
  data/schema/v0.7.0/diary.schema.json（新建）
  data/balance/v0.7.0/balance.json（新增 route 段）
  data/schema/v0.7.0/balance.schema.json（route 段必填字段）
  src/gameplay/route_engine.gd
  src/core/route_content_port.gd（新增 get_route_rules / get_annotation_catalog，默认空）
  src/gameplay/challenge_route_content_port.gd（委托上面两个方法）
  src/infrastructure/route_content_adapter.gd（构造函数增加可选 balance/diary 文档）
  src/app/bootstrap.gd（V07_DOCUMENTS 增加 diary，带 schema 校验；注入给 RouteContentAdapter）
  src/ui/diary_ui_catalog.gd、src/ui/diary_chapter_screen.gd
  tools/simulation/v05_route_content_adapter.gd（模拟用端口补两个方法）
  tests/fixtures/route_content_data.gd（新建：测试读取同一份 balance/diary + 廷根路线夹具）
  tests/gameplay/v055_diary_unlock、v073–v076、route_test、challenge_test、v07_challenge_test 各 runner
  tests/ui/challenge_diary_fallback_runner.gd
依赖：RouteContentPort（core，共享契约，本轨仅增加两个带默认实现的方法）；T5 存档 v6（见下）
验证：tools/run_tests.sh → pass=89 fail=1 skipped=10 guard_block=0（合并 origin/main 后）；唯一失败为 golden（按政策不 --update）
```

## 1. 完成内容

### R2-05 旁白迁出

- `route_engine.gd` 中的 `PEN_REWRITE_TEXTS`、`*_BY_NODE`、`VICTORY_/DEFEAT_/REINK_/REST_/WIPE_ANNOTATIONS`、各 `_for()` 兜底句、`margin_note_zh "笔改过"`、`"墨迹改写了尚未读到的字句"`、仪式软失败批注全部迁到日记 `annotations`：
  - `pools.<pen_rewrite|victory|defeat|reink|rest|wipe>`：`by_node`（node_id → id）、`cycle`（按 `_revision % size` 轮转）、`default`（原代码兜底句）。
  - `fixed`：`pen_rewrite_marker`、`pen_rewrite_margin`、`ritual_failed`。
  - `entries`：`id → {text_zh, ink_stain}`，共 75 条。ID 形如 `annotation.pen_rewrite.first_hunt`、`annotation.victory.generic.03`。
- 选择逻辑不变：先按节点，再按 revision 轮转，最后 default。
- 引擎状态和事件只存 ID：`clue_annotations[node] = annotation_id`；`clue_overlays[node] = {annotation_id, source, margin_note_id}`；`ClueRewritten`/`InkWiped` 事件携带 `annotation_id`，不再携带 `text_zh`/`annotation_zh`。
- 序列名兜底（"小丑"/"占卜家"）改读路线 `sequence` 数据。守卫：`route_engine.gd` 中 CJK 字符 0 行。
- 原来按「墨渍」字串判断可擦拭，改为数据字段 `ink_stain`，由生成脚本按原文本是否含「墨渍」一次性写入，所以判定结果与原来逐条一致。

### R2-03 快照字段

`snapshot.nodes[i]` 新增：`can_open`、`can_advance`、`open_command`（`select_node`/`begin_ascension`）、`wipeable`、`wipe_cost`、`ink_stained`、`annotation_id`、`annotation_ids[]`（主批注 + 笔改覆写）。
- `can_open` = 之前所有节点都已完成（与 UI 原来的 `_can_open_spread` / `investigable` 链同义）。
- `can_advance` = 本节点已完成。
- `wipeable` 与 `WIPE_INK` 的接受判定共用 `_wipe_block_reason()`（同样的检查、同样的顺序），外加 phase==map。

另外新增顶层 `legacy_clue_annotations_zh`（只读显示，见第 3 节）。

### R2-04 UI 删除规则逻辑

- `diary_chapter_screen.gd` 删除了 `_clue_wipeable`（搜「墨渍」+ 灵性比较）、`_can_open_spread`、`_can_advance_from`、`DEFAULT_SPIRIT_WIPE_COST`/`_spirit_wipe_cost`，以及 `node_type == "ritual"` 分支（改读 `open_command`）。翻页阻挡、自动翻页、蜡封擦拭都改读快照字段。
- 结算闪字的兜底文案改为各池第一句，从日记数据读取，不再在 UI 中硬编码。
- `diary_ui_catalog.gd` 新增 `annotation_text(id)`、`pool_head_text(pool)`，用于把 ID 解析为日记文本；它把 `SNAPSHOT_FLAG_KEYS` 带进 spread/clue。如果手写快照或 R2 之前的快照缺少 `can_open`，仍按原有的 spread 链推导，保证 BUG-0038 回退行为不变。删除了无调用者的 `_node_type_map`。
- 守卫：`src/ui` 中不再出现把「墨渍」当作逻辑判断的代码（剩余出现处都是显示文案）。
- 按协调者要求，`_sync_desk_spread()` 改为调用 `apply_spread_list(_spread_list, _current_spread_idx)`；`diary_desk_stage.gd` 未改动。

### R2-06 路线平衡值

`balance.json` 新增 `route` 段：`spirit_wipe_cost: 2`、`pen_rewrite: {every_n: 3, phase: 2}`（原来的魔数 `!= 2`）、`defeat_penalty: {corruption: 1, attention: 1}`、`ritual_soft_fail_corruption_margin: 2`、`default_run_state`（hp/max_hp 54，spirit/max_spirit 3，corruption/attention 0，max_corruption/max_attention 10）。
引擎在 `_load_route` 中校验这一段，缺失时初始化返回 `content_invalid`，不在代码中兜底。数值与原来完全相同。

## 2. 黄金回放语义差异（未执行 --update）

方法：在改动前把 expected 的哈希置空跑一次 golden，取 `user://golden_replay_actual/*.json`（11 个阶段）作为 before；改动后（合并 main 之前，以隔离本轨影响）再取 after；用脚本递归对比，并通过日记 `entries` 把 ID 反查回文本。

```text
equal leaves: 15679
text->id replacements:
  margin_note_zh->margin_note_id x17
  text_zh->annotation_id x17          （clue_overlays）
  value text->id x53                  （clue_annotations 的值）
added keys:
  annotation_id x80, annotation_ids x80, can_advance x80, can_open x80,
  ink_stained x80, open_command x80, wipe_cost x80, wipeable x80   （nodes[i]，各阶段累计）
  legacy_clue_annotations_zh x10      （顶层，均为空 {}）
OTHER (must be empty): 0
```

结论：没有任何数值、状态、列表长度或其他字段变化。所有被替换的文本都能由 ID 精确反查回原文。`11_checkpoint` 的存档摘要（save_version、content_version）未变。

## 3. 存档兼容（交给 T5 / R2-11）

- 本轨**没有**改 `save_version`，也没有改存档 schema（`save.schema.json` 不约束路线内部字段）。
- 新档：`route.state.clue_annotations` 的值是 annotation_id；`clue_overlays[node]` 为 `{annotation_id, source, margin_note_id}`；可能出现 `legacy_clue_annotations_zh`。
- 旧档（v1–v5 中 `clue_annotations` 存文本、overlay 存 `text_zh`/`margin_note_zh`）在 `RouteEngine._restore_state` 中被容忍：
  - 文本与某条 `entries.text_zh` 完全相等 → 换成对应 ID。
  - 不相等 → 批注移到 `legacy_clue_annotations_zh[node]`，overlay 改为 `legacy_text_zh`/`legacy_margin_note_zh`，只读显示，不参与规则（不可擦拭）。
  - 已知风险：旧档中若有被同一 revision 改过文字的条目，无法映射，会退为 legacy；这种条目只影响擦拭能力，不影响进度。
- 建议 T5 在 v6 迁移中显式执行同样的映射（把逻辑移到迁移层，校验后写回 ID），然后可以删除引擎里的 `_normalize_legacy_annotations`。映射表就是 `data/diaries/.../annotations.entries`。
- `legacy_text_zh` 命名与 TARGET_ARCHITECTURE §3.3 一致。

## 4. 困难与候选方案

1. **测试夹具怎样拿到 balance/diary**：方案 A 是每个 runner 自读 JSON（重复）；方案 B 是共享夹具。选 B：新建 `tests/fixtures/route_content_data.gd`，读取与游戏相同的两份文件。
2. **BUG-0038 哈希钉**（`challenge_diary_fallback_runner` 钉了 main view 的 sha256）：方案 A 是更新哈希；方案 B 是哈希前剥掉新增的只读标志。选 B：剥掉后原哈希仍然通过，证明除新增字段外视图与旧实现逐字节一致（另用旧 catalog 并跑比对过 4 个状态，全部 equal）。
3. **reink.generic.05 不可擦拭**：原文本「败后余墨爬行——可拭的污渍……」不含「墨渍」，所以原来就不可擦拭。冻结期保持 `ink_stain:false`，v073 改为断言池中至少 5 条可擦拭。请产品经理决定是否作为内容修正。

## 5. 风险

- `route_engine.gd` 1469 行（原 1434 行），超出 500 行预算；R3 拆分时，日记批注/擦拭可整体抽成 `diary_rules.gd`。
- `diary_ui_catalog.gd` 仍直接用 `FileAccess` 读日记（R2-09 改为注入）。
- bootstrap 现在加载日记文档并做 schema 校验；日记格式损坏会让 v0.7 启动失败（`stage=diary`），这是预期的“加载时报错”。

## 6. 跨角色请求

- 主协调者：第一波合并后统一更新 `tests/golden/expected.json`。本轨的变化仅限第 2 节所列。
- T5：见第 3 节。
- 产品经理：第 4.3 条内容裁决。

## 7. 下一步入口

- R2-09：`diary_ui_catalog.ensure_loaded()` 改为由 app 注入已校验的日记文档（bootstrap 已加载 `documents.diary`）。
- R3：从 route_engine 中拆出日记规则模块。
