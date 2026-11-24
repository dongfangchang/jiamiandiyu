# v0.88.0 轨道 T3 成长/牌组（玩法）报告

```text
版本：v0.88.0（ROADMAP R2 第一波）
角色：玩法设计（T3 成长/牌组；本轨道兼任 src/core 序列等级/随机端口负责人）
任务：R2-07 序列等级 int 化；R2-06/AR-12 删除成长兜底内容；AR-15 成长快照可升级字段；AR-19 抽卡随机端口改名
状态：完成（黄金哈希按 §3 政策未 --update，待主协调者统一更新）
修改文件：
  data/cards/v0.7.0/cards.json                 每张卡新增 required_sequence:int（40 张）
  data/schema/v0.7.0/cards.schema.json         新增 required_sequence 属性并设为必填
  src/core/sequence_tier.gd（新）              SequenceTier.BASE / required_for / is_unlocked
  src/core/random_port.gd（新）                通用 RandomPort
  src/core/battle_random_port.gd               改为 extends RandomPort（行为不变）
  src/infrastructure/seeded_random_adapter.gd（新）  RandomPort 的命名流适配器
  src/app/app_services.gd                      新增 create_random(stream_name)
  src/app/bootstrap.gd                         抽卡改用 services.create_random(&"gacha.draw")（1 行）
  src/gameplay/progression_engine.gd           去中文解析、去兜底、_upgrade_check、快照字段、RandomPort
  src/gameplay/deck_engine.gd                  _required_sequence 改读 SequenceTier
  src/ui/upgrade_screen.gd                     ready_to_upgrade / 按钮禁用改读快照 can_upgrade（未碰取图行）
  tests/gameplay/progression_test_runner.gd    测试替身补魔药/消化数据；新增 2 组用例
  tests/gameplay/v027_attack_catalog_runner.gd 必填字段加 required_sequence
  tests/gameplay/v028_potion_digestion_runner.gd 序列锁断言改用 SequenceTier
  tests/gameplay/v07_deck_test_runner.gd       抽卡流改用 SeededRandomAdapter
  tests/simulation/v031_card_value_audit_runner.gd 序列8 预算判断改用 SequenceTier
  tests/simulation/v07_deck_contract_runner.gd 抽卡流改用 SeededRandomAdapter
  tests/ui/ui_progression_smoke_runner.gd      假快照补 can_upgrade/upgrade_cost
  tests/ui/v07_deck_ui_smoke_runner.gd         假快照补 can_upgrade/upgrade_cost
依赖：v0.7 cards/progression 数据；SeededRandomService 的命名流派生（未改）
验证：tools/run_tests.sh → pass=85 fail=1 skipped=9 guard_block=0；唯一失败是 golden（预期：快照新增字段）。
      PROGRESSION_TESTS_OK checks=116；V028_POTION_DIGESTION_OK checks=40；PROGRESSION_UI_SMOKE_OK checks=55。
      黄金回放语义差异见下文 §4：仅新增字段，0 处数值/状态/抽卡变化。
```

## 1. R2-07 序列等级改为 int

- **现状问题**：`deck_engine.gd:322`、`progression_engine.gd:640/650/731-734` 四处用 `sequence_band.contains("序列8"/"→8"/"序列9")` 判断序列。
- **数据缺结构化字段**：卡牌只有展示文案 `sequence_band`（现行数据只有两种值：`序列9` ×32、`序列8·小丑` ×8；无 `→8`）。挑战数据已有 `required_sequence:int` 的先例，故沿用同名字段。
- **做法**：给 `data/cards/v0.7.0/cards.json` 每张卡加 `required_sequence`（`序列9`→9，`序列8·小丑`→8，脚本一次性 1:1 生成并断言只有这两种值）；schema 设为必填（缺字段在加载校验时报错）。卡牌 ID 未改。`sequence_band` 保留为纯展示文案。
- `src/core/sequence_tier.gd`：`BASE = 9`；`required_for(definition)`（无该字段的 v0.3 旧卡视为基础序列卡，与原默认 `"序列9"` 等价）；`is_unlocked(definition, current)` = `current <= required`。
- 语义等价性：
  - 抽卡解锁：原「当前序列≤8 不锁；否则锁含序列8 的卡」⇔ `current <= required`（数据只有 9/8 两档）。
  - 序列残页目标：原「序列9 选 序列9/→8 卡；序列8 选 序列8 卡」⇔ `required == current`；候选遍历顺序（`_all_card_ids()` 排序）与随机调用次数不变。
  - 牌组 `required_sequence` 快照与 `sequence_locked` 判断不变。
- UI：`identity_screen.gd` 没有序列字符串解析；`deck_screen.gd` 已读快照 `required_sequence:int`，无需改。
- gameplay 中已无「序列8」「→8」字符串判断（`grep` 确认 progression/deck 两个引擎 0 处）。

## 2. R2-06 / AR-12 删除成长兜底内容

- 删除 `_load_content` 中的兜底魔药（`potion.seer_to_clown`/小丑魔药）与兜底消化规则；删除 `_pick_sequence_reward_target` 的兜底卡 `card.skill.ink_dart`。
- 缺数据改为初始化失败并给出明确原因码（`initialize()` 返回 `accepted=false`）：
  - `potion_definitions_missing`：没有魔药定义；
  - `digestion_rules_missing` / `digestion_potion_unknown` / `digestion_rules_invalid`：消化规则缺失、引用未定义魔药、或 `from/to_sequence/required/to_sequence_name_zh/eligible_mechanic_tags` 不合法；
  - `sequence_reward_target_missing`：起始序列（`from_sequence`）没有任何同序列卡可作残页奖励目标。
  - 其余内容错误仍为 `content_invalid`（原行为）。
- 现行 v0.7 数据完整覆盖以上检查，运行时无变化（黄金回放验证）。
- 同时把 `_new_digestion_state`、`_consume_potion` 里的 `8/9/"小丑"` 字面默认值改为读已校验的 `_digestion_rules`。
- 测试替身 `ProgressionTestContent`（v0.4 文档，原本依赖兜底）改为显式读取 v0.7 `progression.json` 的魔药/消化数据。新增 `_test_missing_potion_content_rejected` 覆盖 3 个原因码。

## 3. AR-15（成长部分）快照 `can_upgrade` + `upgrade_cost`

- 新增 `_upgrade_check(definition_id) -> {reason, cost}`，`UPGRADE_CARD` 命令与快照共用同一判断（单一事实源）；原因码与检查顺序和原 `_upgrade_card` 完全一致。
- `progression.collection[i]` 新增：
  - `can_upgrade: bool` = 当前提交 `UPGRADE_CARD` 会被接受（含阶段必须为 hub）；
  - `upgrade_cost: int` = 下一级花费；无升级路径或已满级时为 0。
  - 保留 `next_upgrade_cost`（兼容其他读者，T4/T5 可再收敛）。
- `upgrade_screen.gd`：`ready_to_upgrade := bool(card.get("can_upgrade", false))`，按钮禁用改为 `_busy or not ready_to_upgrade`（同一判断的两处镜像，一并收口）；未改取图行（H 轨道负责）。
- 新增 `_test_snapshot_upgrade_fields`：非 hub 为 false；碎片不足 false 且显示花费；无升级路径 cost=0；足够时 true 且命令被接受；升级后 cost 跟随下一级。

## 4. AR-19 抽卡随机端口

- `ProgressionEngine` 构造参数类型由 `BattleRandomPort` 改为 `RandomPort`（core 通用端口）。`BattleRandomPort` 现为 `RandomPort` 子类，战斗相关代码与测试替身不受影响。
- `bootstrap` 改用 `services.create_random(&"gacha.draw")` → `SeededRandomAdapter`，流名不变，因此种子派生（FNV 流名哈希）完全一致；黄金 `10_gacha` 抽卡结果 0 差异。
- `route_session` / `challenge_session` 只接收已构造的 `ProgressionEngine`，无需改。

## 5. 黄金回放语义差异（未 --update）

做法：改动前把 `expected.json` 哈希临时置空运行 runner 取得 11 个阶段的规范化 JSON（并用 Python 复算 sha256 确认与 `expected.json` 全部一致，随后恢复原文件），改动后再取一次，逐键递归比较。

| 阶段 | 新增字段 | 删除 | 值变化 |
|---|---|---|---|
| 01_start … 10_gacha（10 个阶段） | `progression.collection[].can_upgrade` ×40、`progression.collection[].upgrade_cost` ×40 | 0 | 0 |
| 11_checkpoint（存档信封） | 无（哈希与 expected.json 一致） | 0 | 0 |

- 黄金路线全程 `can_upgrade` 均为 false（回放策略从未攒够碎片/在 hub 外），`upgrade_cost` 与原 `next_upgrade_cost` 在未满级卡上相等。
- 存档格式不变（`11_checkpoint` 哈希未变；`can_upgrade/upgrade_cost` 只在快照中，不进入持久化状态）。
- 结论：仅新增只读快照字段，无数值、状态或抽卡序列变化。请主协调者在第一波合并后统一 `--update` 并登记。

## 6. 困难、候选方案与最终选择

1. **序列等级来源**：A) 在 core 里集中一处字符串解析；B) 数据加结构化 int 字段。选 B——A 仍是「按文案判断规则」，违背 TARGET_ARCHITECTURE §3.3。
2. **序列 8 无残页候选时**：A) 初始化时同时校验 `from_sequence` 和 `to_sequence` 都有候选；B) 只校验起始序列，到达新序列后若无候选则不提供该奖励。A 会让只含早期卡池的测试替身（v0.4 文档，不含序列 8 卡）无法初始化，需要伪造序列 8 卡并改变其抽卡结果。最终选 B：起始序列缺候选=初始化错误；后续序列无候选时 `_pick_sequence_reward_target` 返回空，`_all_reward_ids` 不提供该奖励（不再凭空指定 `ink_dart`）。现行数据序列 8 有 8 张候选，不受影响。
3. **随机端口命名**：A) 新建 `GachaRandomPort`；B) core 通用 `RandomPort`，`BattleRandomPort` 继承它。选 B，避免每个领域各建一个同形端口；适配器层新增 `SeededRandomAdapter`（与 `BattleRandomAdapter` 有约 15 行重复，因 GDScript 单继承无法共享，后续可把战斗也迁到 `RandomPort` 后删掉旧类）。

## 7. 风险

- `progression_engine.gd` 1122 行（原 1090），超过 500 行预算（原本已超）；本轨道只做条目内修改，未拆分。建议 R3 拆出 gacha / digestion 子模块。
- `can_upgrade` 含「阶段为 hub」条件；若 UI 在非 hub 阶段展示升级页，按钮会显示不可升级（原来会可点但被引擎拒绝），属更真实的反馈。
- 非 v0.7 卡（v0.3 旧卡）无 `required_sequence`，按基础序列 9 处理，与原 `"序列9"` 默认一致。

## 8. 跨角色请求

- 主协调者：第一波合并后统一更新 `tests/golden/expected.json`（本轨道 diff 仅新增 `can_upgrade`/`upgrade_cost`）。
- 本地数据层（T5，存档 v6 / manifest）：`cards.schema.json` 新增必填 `required_sequence`；扁平化迁移时请保留。`BattleRandomAdapter` 与 `SeededRandomAdapter` 可在战斗侧改用 `RandomPort` 后合并。
- UI（H 轨道）：`upgrade_screen.gd` 本轨道只改了第 204 行与按钮禁用块（约 298 行），未碰取图行。

## 9. 候选池

- 战斗引擎也改用 `RandomPort`，删除 `BattleRandomPort`/`BattleRandomAdapter`。
- 卡牌 `sequence_band` 展示文案可由 UI 文本表按 `required_sequence` 生成，去掉数据中的重复。

## 10. 下一步入口

- 第二波 T4/T5 合并时复跑 `tools/run_tests.sh`；若 manifest 扁平化移动 `data/cards/v0.7.0/cards.json`，确认 `required_sequence` 随之迁移。
