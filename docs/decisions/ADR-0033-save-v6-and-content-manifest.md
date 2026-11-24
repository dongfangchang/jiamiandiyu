# ADR-0033：存档 v6 与内容清单

状态：已采纳（v0.88.0 第二波 T5，本地数据层起草；待产品经理复核）
日期：2026-11-24
相关：ROADMAP R2-08、R2-11；REVIEW AR-21、AR-22、AR-23、AR-33；TARGET_ARCHITECTURE §3.4、§3.6

## 背景

- 自 v0.7 起 `save_version` 一直是 5，`content_version` 写死 `"v0.7.0"`。v0.7 存档 schema 顶层 `additionalProperties: true`，各子对象只写 `"type": "object"`，后来加入的字段都没有版本化（AR-22）。
- 加载顺序是"先迁移再校验"，原文档从未按源版本 schema 校验（AR-23）。
- `export_persistent_state()` 直接返回引擎内部 `_state`，内部结构就是存档格式（AR-33）。
- `bootstrap.gd` 用路径常量决定"当前生效的是哪一份内容"，只能读代码才知道（AR-21）。
- v0.88 第一波 T2 把路线批注从文本改为 `annotation.*` ID，旧档兼容暂时写在 `RouteEngine._normalize_legacy_annotations`，玩法层因此要认识旧存档格式。

## v5 之后实际新增、但未版本化的字段（按当前信封盘点）

| 位置 | 字段 | 引入 |
|---|---|---|
| `progression` | `sequence`、`digestion{potion_id, from_sequence, to_sequence, to_sequence_name_zh, progress, required, consumed}`、`potion_inventory[]`、`sequence_reward_target_id`、`gacha_history[]{draw_index, pull_count, results[]}` | v0.8 后的成长 / 晋升 |
| `route.state` | `unlocked_node_ids[]`、`clue_annotations{node → annotation_id}`、`clue_overlays{node → {annotation_id, source, margin_note_id}}`、`legacy_clue_annotations_zh`、`ritual_state{ritual_id, step_index, hints_used, hinted_steps, errors, hint_text, status, result}`、`route_outcome`、`end_reason` | 日记 / 墨迹 / 笔改（v0.55 起），v0.88 改为 ID |
| `challenge` | `reward_applied`、`sequence_state`；`state.route_state`（挑战内嵌一份路线状态，同样有批注字段） | v0.6–v0.7 |
| `deck` | `state{phase, confirmed, confirmed_card_ids, current_card_ids, presets, selected_preset_id, revision}` | v0.7 |

说明："日记结算"（`RouteSession._pending_diary_settlement`）只在内存里，**从未进入存档**；v6 维持不存，因为它由路线事件在当回合生成、读档后无需重放。

## 决策

### 1. 内容清单（R2-08 第一步）

- 新增 `data/manifest.json`（schema：`data/schema/manifest.schema.json`）：
  - `content_revision`：单调递增整数，从 1 开始。任何当前内容文件的语义变化都要 +1。
  - `documents`：`kind → {path, schema}`，覆盖 v0.7 启动链加载的全部内容：`cards`、`progression`、`enemies`、`encounters`、`balance`、`routes`、`rituals`、`challenges`、`decks`、`diary`。
- `bootstrap` 的路径常量全部删除，改由 `ContentManifest` 读清单；测试用的路径覆盖键（`cards`、`cards_schema` 等）保持不变。
- 新增 `ContentValidator`：清单每一项存在且通过 schema；ID 唯一；跨文件引用由各适配器的既有校验解析。
- **本波不移动文件**（T4 仍在替换 UI 对内容路径的直接读取）；扁平化在后续条目完成，只需改清单里的路径。

### 2. 存档 v6 形状（`data/schema/save/v6.schema.json`）

```text
{
  save_version: 6,
  content_revision: int ≥ 1,          // 取代 content_version
  created_at, rng_seed,
  profile:     {pathway, sequence, identity_id}                         严格
  run:         {checkpoint_kind, encounter_id, current_node_id,
                deck_summary{card_id → int}, last_battle{…}}             严格（last_battle 字段枚举）
  collection:  {card_id → {copies, level, fragments}}                   严格
  progression: ProgressionDTO                                           严格（含 digestion、gacha_history 条目）
  route:       {initialized, route_id, phase, run_state, completed_node_ids,
                sequence_state, state: RouteStateDTO}                   严格
  challenge:   {challenge_id, phase, selected_modifier_id, challenge_outcome,
                reward_applied, sequence_state, state}                  外层严格；state.route_state 用 RouteStateDTO
  deck:        {initialized, state: DeckStateDTO}                       严格
}
```

- RouteStateDTO 中 `clue_annotations` 的值必须匹配 `^annotation\.`；`clue_overlays` 条目只允许 `annotation_id`、`source`、`margin_note_id`、`legacy_text_zh`、`legacy_margin_note_zh`。
- 允许保留的迁移标记：`progression.migrated_from_v1`、`route.migrated_from_v2`、`challenge.migrated_from_v3`、`deck.migrated_from_v4`（布尔，可选）。
- **仍为开放映射**（已记录，后续收紧）：`challenge.sequence_state` 与 `challenge.state.sequence_state`（`SequenceState.to_dictionary()`，形状由序列模块定义）；`deck.state.presets` 是 `preset_id → card_id[]` 映射（键开放，值严格）。
- 仍含中文的字段（只读展示，非规则）：`progression.digestion.to_sequence_name_zh`、`route.state.ritual_state.hint_text`、`legacy_*_zh`。前两项由内容派生，后续 R 条目改为读档后从内容重建。

### 3. 运行状态 ⇄ 存档 DTO：`checkpoint_codec`

- 新增 `src/app/checkpoint_codec.gd`，取代 `checkpoint_envelope_builder.gd`。路线状态和成长状态按**显式字段表**逐项映射（含类型规整），读档时同样按字段表还原给引擎。引擎内部新增字段而未登记时，编码会丢弃并报告 `unknown_fields`，测试会阻断。
- 挑战状态和牌组状态的外层字段显式映射；其内嵌路线状态复用 RouteStateDTO。

### 4. 加载顺序（修复 AR-23）

`AtomicSaveService` 的加载严格按：

1. 解析 JSON（失败 → `invalid_json`，不改动文件）；
2. 读 `save_version`：比当前新 → `unsupported_save_version`；
3. **按源版本 schema 校验**（`source_validation_failed`）；源版本没有登记 schema → `source_schema_missing`；
4. 逐步迁移，每一步按该步目标版本的 schema 校验；
5. 按当前版本 schema 校验；
6. 不变量检查（`invariant_failed`）：`route.initialized` 时 `route.state.route_id == route.route_id`、`completed_node_ids` 无重复、`content_revision` 不大于本构建的清单版本、收藏数量非负。

版本 → schema 表（只增不改）：

| save_version | schema |
|---|---|
| 1 | `data/schema/v0.2.0/save.schema.json` |
| 2 | `data/schema/v0.4.0/save.schema.json` |
| 3 | `data/schema/v0.5.0/save.schema.json` |
| 4 | `data/schema/v0.6.0/save.schema.json` |
| 5 | `data/schema/v0.7.0/save.schema.json` |
| 6 | `data/schema/save/v6.schema.json` |

历史 schema 暂不复制到 `data/schema/save/v1..v5`：复制会制造第二份定义，且 `AtomicSaveService` 的通用默认值仍指向 v0.2.0。它们在扁平化条目里**移动**（不是复制），届时只改上表。

### 5. 迁移 v5 → v6

- 删除 `content_version`，写入 `content_revision = 1`（v0.7.0 内容包即清单第 1 版）。
- 批注文本 → ID：查表来自日记文档 `annotations.entries`（`id → text_zh`），对 `route.state` 和 `challenge.state.route_state` 都执行：
  - `clue_annotations[node]`：已是 `annotation.*` 保留；文本与某条 `text_zh` 完全相等 → 换成 ID；否则移到 `legacy_clue_annotations_zh[node]`（只读显示，不可擦拭）。
  - `clue_overlays[node].text_zh` → `annotation_id` 或 `legacy_text_zh`；`margin_note_zh` → `margin_note_id` 或 `legacy_margin_note_zh`。
- 其余字段按 v6 schema 修剪：严格对象中 v6 未登记的旧键被丢弃（这些键当前引擎不再读取）。
- 迁移完成后 `RouteEngine._normalize_legacy_annotations` 删除，玩法层不再认识旧存档文本。

### 6. 回滚与兼容

- v6 构建能读 v1–v6；v5 及更早的构建读 v6 档会因 `save_version` 过新而拒绝（已有行为），**不会**部分覆盖。
- 首次以 v6 写档时，原档先被复制为 `.json.bak`（v5 内容）。需要回退构建时，用户可用 `.bak` 恢复；这是唯一的回滚路径，不提供 v6 → v5 降级迁移。
- 迁移失败不改动原文件，错误码明确（见第 4 节）。

## 影响

- 黄金回放 `11_checkpoint` 的哈希变化（`save_version` 5 → 6、`content_version` → `content_revision`），其余阶段不变。由主协调者在波次合并时统一更新。
- 旧档 fixture：`tests/infrastructure/fixtures/saves/v1..v6` 加损坏档、过新档，由 `save_fixture_runner` 覆盖。
