# v0.88.0 本地数据层报告（第二波 T5：内容清单 + 存档 v6）

```text
版本：v0.88.0
角色：本地数据层
任务：R2-08 内容清单（本波不移动文件）；R2-11 存档 v6（ADR-0033）
状态：完成（R2-08 的目录扁平化按约定留到后续，清单见第 5 节）
修改文件：
  docs/decisions/ADR-0033-save-v6-and-content-manifest.md（新）
  data/manifest.json（新）、data/schema/manifest.schema.json（新）、data/schema/save/v6.schema.json（新）
  src/infrastructure/content_manifest.gd（新）、content_validator.gd（新）
  src/infrastructure/atomic_save_service.gd、save_migrations.gd、schema_validator.gd
  src/app/checkpoint_codec.gd（新，取代并删除 checkpoint_envelope_builder.gd）
  src/app/bootstrap.gd、route_session.gd、challenge_session.gd（只改存档 / 内容版本接线）
  src/gameplay/route_engine.gd（只删除 _normalize_legacy_annotations 及两个辅助函数）
  tools/validate_content.gd（新）
  tests/infrastructure/save_fixture_runner.gd（新）、content_manifest_runner.gd（新）、fixtures/saves/*.json（新，9 个）
  tests/infrastructure/{test_runner, route_backend_runner, challenge_backend_runner, v07_backend_runner, preferences_service_runner}.gd、README.md
  tests/integration/v092_destructive_runner.gd（手写 v5 信封改为读 v6 fixture）
  tests/gameplay/v055_diary_unlock_runner.gd（删除旧文本状态用例，已迁到 save_fixture_runner）
依赖：T2 的日记 annotations.entries（批注文本 → ID 查表）；T2 报告第 3 节的旧档语义
验证：tools/run_tests.sh → pass=91 fail=1 skipped=10 guard_block=0；唯一失败是 golden 11_checkpoint（预期内，未执行 --update，见第 4 节）
      tools/validate_content.gd → OK content_revision=1（10 类文档）
      save_fixture_runner checks=179 全过；content_manifest_runner checks=41 全过
```

## 1. R2-08 内容清单

- `data/manifest.json`：`content_revision: 1`，以及 `documents` 中 10 类文档 `kind → {path, schema}`：`cards`、`progression`、`enemies`、`encounters`、`balance`、`routes`、`rituals`、`challenges`、`decks`、`diary`。kind 名称与 bootstrap 原有的覆盖键一致（日记用 `diary` 而不是 `diaries`），这样测试的路径覆盖不用改。
- `ContentManifest`（infrastructure）负责读取和校验清单，并提供 `resolve(kind, overrides)`、`load_kind(kind, overrides)`。覆盖规则保持原样：`paths[kind]`、`paths[kind + "_schema"]`。另外新增覆盖键 `manifest`。
- `bootstrap.gd`：路径常量全部删除，只保留加载顺序 `V07_DOCUMENT_KINDS`；路线预览、v07 启动链和挑战都改为读清单。失败时的 `details.stage` 与原来一致；清单本身出错时 stage 为 `manifest`。
- `ContentValidator` 的检查项：
  - 每一项存在，并通过各自的 schema；
  - 每个文档顶层 `[{id}]` 数组内 ID 唯一；所有路线的节点 ID 全局唯一；
  - 跨文档引用：复用 `CampaignContentCatalog`、`ProgressionContentAdapter`、`RouteContentAdapter`、`DeckContentAdapter`、`ChallengeContentAdapter` 的校验；另外补充了适配器没查的三项：节点 `encounter_id` / `ritual_id` 必须存在，日记 `route_id` 必须存在，`annotations.pools/fixed` 引用的 ID 必须在 `entries` 中。
  - 命令行：`"$GODOT" --headless --path . --script res://tools/validate_content.gd`。

## 2. R2-11 存档 v6

ADR：`docs/decisions/ADR-0033-save-v6-and-content-manifest.md`。其中盘点了 v5 之后实际新增、但一直没有版本化的字段。

- **形状**：`data/schema/save/v6.schema.json`，每一层能枚举的地方都设为 `additionalProperties: false`。仍开放的有：以 ID 为键的映射（collection、deck_summary、批注映射、牌组 presets，值都严格）和 `SequenceState` 字典（`challenge.sequence_state`、`challenge.state.sequence_state`）。为了让路线状态 DTO 在 `route.state` 和 `challenge.state.route_state` 两处共用一份定义，`schema_validator` 增加了本地 `#/$defs/<name>` 的 `$ref` 支持。
- **`content_revision` 取代 `content_version`**：值来自清单。会话构造参数从 `content_version: String` 改为 `content_revision: int`；`route_session` / `challenge_session` 的默认值从 v4 / "v0.6.0" 改为 `CheckpointCodec.SAVE_VERSION`（6）/ 1，修复 AR-22。`_checkpoint_summary` 和 bootstrap 结果的 `details` 中的 `content_version` 改为 `content_revision`（UI 和 app_controller 都不读这个键，已 grep 确认）。
- **加载顺序**（AR-23）：解析 → 版本过新则拒绝 → **按源版本 schema 校验**（`source_validation_failed`；源版本没登记 schema 时报 `source_schema_missing`）→ 逐步迁移，每步按该步目标 schema 校验 → 按当前 schema 校验 → 不变量检查（`invariant_failed`）。不变量也用于写入：`save_slot` 会拒绝违反不变量的信封。历史 schema 表放在 `SaveMigrations.VERSION_SCHEMAS`，只增不改。
- **v5 → v6 迁移**：删除 `content_version`，写入 `content_revision = 1`；`route.state` 和 `challenge.state.route_state` 中的批注文本按 `annotations.entries` 改为 ID，匹配不上的移到 `legacy_clue_annotations_zh` / `legacy_text_zh` / `legacy_margin_note_zh`（语义与 T2 在引擎中的实现完全一致）；然后按 v6 schema 修剪当前不读的旧键。查表由 bootstrap 用已加载的日记文档传入；`inspect` / `restore` 路径自己读清单里的日记。
- **`CheckpointCodec`**（AR-33）：取代 `CheckpointEnvelopeBuilder`。路线、成长、牌组、挑战状态都按字段表逐项映射，并做类型规整；bootstrap 读档时同样经 `decode_*` 还原给引擎。引擎新增字段而没登记时，编码会 `push_error`，`audit()` 用例会失败。
- **删除** `RouteEngine._normalize_legacy_annotations`、`_normalize_legacy_field`、`_annotation_id_for_text`。已确认没有其他路径把未迁移的 v5 状态直接交给引擎：bootstrap 只从迁移后的存档恢复；`app_controller` 的重开只传成长和牌组；挑战引擎的路线状态同样来自迁移后的 `challenge.state`。

## 3. Fixture 与测试

`tests/infrastructure/fixtures/saves/`：`v1`–`v6`、`corrupt`、`newer_version`（save_version 7）、`v5_schema_invalid`。它们是冻结的历史形状，由黄金回放 11_checkpoint（种子 20261124）改写为各版本，**不得用当前代码重新生成**。v5 中包含已知批注文本、未知批注文本、overlay 文本和一个当前不再使用的字段。

`save_fixture_runner` 覆盖：

- v1–v6 都加载为 v6，`content_revision` = 1，加载不改写原文件；重新写入后再读，内容不变；
- v2–v6 经 `start_route_v07` 恢复后，由运行中的引擎写回检查点：
  - 存档里原有的路线字段全部保留；
  - v5 和 v6 的路线、成长、牌组状态完全相同；
  - 首次以 v6 写入时，旧文件留作 `.bak`；
- v1 / v4 / v5 的迁移细节：迁移标记、文本 → ID、未知文本保留为 legacy、旧键被修剪；恢复后的快照能显示 legacy 文本；
- 损坏档 / 过新档 / 源 schema 不合法：分别报 `invalid_json` / `unsupported_save_version` / `source_validation_failed`；`inspect` 显示为 corrupt 并带错误码；无法继续游戏；新的写入会被 `backup_validation_failed` 拒绝，**原文件字节不变**；
- 不变量：`route_id` 不一致、节点重复、`content_revision` 比当前构建新、v6 中出现批注文本，读和写都会被拒绝；
- codec `audit`：成长、牌组、新开路线和已完成路线的导出状态中，没有未映射的字段。

## 4. 黄金回放（未执行 --update）

- 01–10 阶段哈希不变；只有 `11_checkpoint` 变化。
- 前后语义对比（规范化 JSON，基线为 `72f181a` 上的 runner 输出）：
  - 259 个值相同；
  - `changed $.envelope.save_version 5 → 6`；
  - `removed $.envelope.content_version "v0.7.0"`；
  - `added $.envelope.content_revision 1`。
  - **没有其他差异**：路线、成长、牌组、挑战、run 的字段和数值完全相同。这说明 codec 的显式映射没有丢掉也没有改动任何字段。
- runner 的摘要现在显示 `{"content_version":"","save_version":6}`。`_summary` 仍读 `content_version`，这个文件归 `tests/golden` 管，本轨没有改；建议主协调者在更新 `expected.json` 时，顺带把摘要改为读 `content_revision`。

## 5. 扁平化后续清单（R2-08 第二步，T4 合并之后做）

当前生效的目录（清单所指）：`data/cards/v0.7.0/`（cards、progression）、`data/enemies/v0.7.0/`、`data/encounters/v0.7.0/`、`data/balance/v0.7.0/`、`data/routes/v0.7.0/`、`data/rituals/v0.7.0/`、`data/challenges/v0.7.0/`、`data/decks/v0.7.0/`、`data/diaries/v0.55.0/`、`data/schema/v0.7.0/`。

建议移到 `data/<kind>/<file>.json` 和 `data/schema/<kind>.schema.json`，然后**只改 `data/manifest.json`**。阻塞项：

1. `src/ui/card_art_catalog.gd`（`cards/v0.7.0`）、`src/ui/diary_ui_catalog.gd`（`diaries/v0.55.0`）：由 T4 的 R2-09 改为注入。
2. 约 40 个测试直接写死上述路径。主要有 UI 战斗 / 牌组类、`tests/fixtures/route_content_data.gd`、`v07_backend_runner`、`deck_sampling_runner`、`v092_destructive_runner`、`challenge_diary_fallback_runner`。应改为通过 `ContentManifest.load_manifest().data.path_for(kind)` 取路径。
3. 历史内容目录只被历史契约 / 采样测试引用，需要裁决这些测试是保留（随目录一起移入 `data/archive/`）还是删除：
   - `cards/v0.3.0`、`cards/v0.4.0`；
   - `enemies`、`encounters` 的 `v0.3.0` / `v0.5.0`；
   - `balance` 的 `v0.3.0`–`v0.6.0`；
   - `routes/v0.5.0`、`rituals/v0.5.0`、`challenges/v0.6.0`；
   - `schema` 的 `v0.3.0`–`v0.6.0` 中的内容 schema。
4. `data/balance/v0.2.0/` 没有任何引用，可以直接归档。
5. 历史存档 schema（`schema/v0.2.0`、`v0.4.0`、`v0.5.0`、`v0.6.0`、`v0.7.0` 下的 `save.schema.json`）应**移动**为 `data/schema/save/v1..v5.schema.json`，同时改 `SaveMigrations.VERSION_SCHEMAS` 和 `AtomicSaveService.DEFAULT_SAVE_SCHEMA_PATH`（通用默认值，现在指向 v0.2.0）。这一步只改常量，fixture runner 能直接验证。

## 6. 困难与候选方案

- **怎样让 v6 schema 严格，同时不在两处重复定义路线 DTO**：
  - 候选 A：把定义复制两份；
  - 候选 B：给 `schema_validator` 加本地 `$ref`。
  - 选 B：约 15 行代码，只支持 `#/$defs/`。
- **旧档里有当前引擎不再写的键，严格 schema 会拒绝**：
  - 候选 A：迁移时逐键白名单；
  - 候选 B：直接拒绝；
  - 候选 C：按 v6 schema 修剪。
  - 选 C：字段表只有 schema 一处定义，被修剪的键当前没有代码读取。
- **codec 的字段表与 schema 是两份清单**：用 `audit()` 测试和"保存时 schema 严格校验"两道保险，保证二者一致。一方漏改时：要么保存失败（schema 拒绝），要么测试失败（`audit` 发现未映射字段）。
- **拆分提交**：bootstrap 的清单改动和存档改动在同一文件中交织，而环境不支持交互式暂存，所以清单接线并入了"save v6"提交。内容清单的提交只包含数据、清单类、校验器和工具。

## 7. 风险与未解决问题

- **v1 存档无法继续游戏（迁移前就存在的问题，本轨没有改动）**：v1→v2 迁移把成长重置为 `identity_selection`，收藏为空，于是默认牌组无法确认（`default_deck_invalid / card_not_owned`）。v1 档能加载、能往返，只是不能恢复游戏。建议后续把 v1→v2 的重置改为"空成长"，让引擎按新档初始化起始卡。需要产品经理确认是否值得为 v0.2/v0.3 时代的存档修复。fixture runner 中 v1 已跳过游戏恢复这一步，并注明了原因。
- 存档里仍有中文的只读展示字段：`progression.digestion.to_sequence_name_zh`、`route.state.ritual_state.hint_text`，以及 `legacy_*_zh`。前两项由内容派生，建议在后续 R 条目中改为读档后从内容重建。
- `route.sequence_state` 在信封里是字符串，而 bootstrap 原来按字典读它，`resumed_sequence` 因此一直为空。这是既有问题，v6 保持原样没有修，已在 ADR 中写明形状。
- 新档写入都按 v6 进行；旧构建读到 v6 档会因版本过新而拒绝。首次写入时旧文件会保留为 `.bak`，这是唯一的回退路径。

## 8. 跨角色请求

- **主协调者**：在第二波合并时统一更新 golden `expected.json`（只有 11_checkpoint 变化，差异见第 4 节），并建议把 golden `_summary` 改为读 `content_revision`。
- **T4 / UI**：R2-09 改为注入后，`card_art_catalog` / `diary_ui_catalog` 不再写死内容路径，扁平化即可开始。如需内容路径，请用 `ContentManifest`，不要新增字面量。
- **玩法（T2）**：`tests/gameplay/v055_diary_unlock_runner.gd` 中的旧文本状态用例已删除，等价覆盖在 `save_fixture_runner` 的 v5 用例中。引擎不再接受批注文本，存档层负责转换。
- **产品经理**：裁决第 5 节第 3 项（历史内容目录和测试的去留），以及第 7 节的 v1 恢复问题。

## 9. 候选池

- 把 `run_state` / `completed_node_ids` 在信封 `route` 顶层的重复副本去掉，只保留 `route.state`（需要 save v7）。
- 用 `ContentValidator` 替换 bootstrap 中逐项的版本号比对（`v07_content_version_mismatch` 等），版本一致性改由清单保证。

## 下一步入口

T4 合并后执行扁平化：按第 5 节移动文件，只改 `data/manifest.json` 和 `SaveMigrations.VERSION_SCHEMAS`，然后跑 `tools/validate_content.gd` 和 `tools/run_tests.sh`。
