# v0.86.0 主协调者 / 架构师报告

```text
版本：v0.86.0
角色：主协调者（兼架构师）
任务：关闭 v0.84/v0.85；开 v0.86（ROADMAP R0）；统一测试入口；测试基线；卡图修复；仓库卫生
状态：部分完成
```

## 已完成（2026-11-24）

- **关版**：v0.84.0、v0.85.0 已有条件关闭（用户口头授权）；v0.85 余项真窗口审稿转为 R0-11。
- **文档**：
  - 新增 `docs/architecture/`（REVIEW / TARGET_ARCHITECTURE / ROADMAP / UI_NAVIGATION_REVIEW）和 ADR-0031。
  - 章程删除"不做 3D 场景"；章程新增 §9 提交与推送。
  - 更新 AGENTS 的所有权与规则。
- **R0-01**：新增 `tools/run_tests.sh` 和 `tools/run_tests.ps1`。
  - 自动发现 runner；`extends SceneTree` 的 runner 走 `--script`；每个 runner 有超时；排除 capture 和 monkey。
  - 内置守卫。
  - `.ps1` 未在 Windows 实测。
- **R0-05**：删除 `battle_screen.CARD_ART_BY_DEFINITION`，战斗优先使用 v0.85 插画窗口；v041/v042 测试改为断言新行为，两项均通过。
- **R0-08**：新增 `art/assets/raster/.gdignore`，取消跟踪 45 个 raster `.import` 和 `tools/simulation/out/`，并加入 `.gitignore`。
  - `art/assets/svg` **没有**忽略，因为 `art/tools/render_*.gd` 通过 `load()` 导入 SVG。
- **R0-09**：守卫已在 run_tests 中。
- 运行时版本号改为 `0.86.0`。

## R0-02 测试基线（macOS，Godot 4.7.2，headless）

`pass=75 fail=13 skipped=8`（skip 的是 capture 和 monkey）。另外守卫 `tests must not pin project version` 阻断（v077/v081/v082）。

| 失败 runner | 原因 | 处置（负责） |
|---|---|---|
| integration/app_flow、v07_app_flow、v091_app_destructive（超时）、v092_destructive | 调用旧路线屏 API（`get_snapshot_data`、`get_option_count`、`select_rest`、`is_exit_confirmation_visible`），但路由已指向日记屏；挑战 hub 的 `get_modifier_count` 不存在。**界面切换路径实际上没有可用的回归测试** | 轨道 B（UI）：随 NAV 整治重写为按日记主路径的导航测试 |
| ui/v056_immersion、v072_diary_008_layers、v077_live_copy、v077_runtime_cta、v081_diary_readability | 断言已退役的 2D 书、flip3d、页底板和版本号 | 轨道 A：删除或裁剪（R0-03，提前执行 R1-04 中测试的部分） |
| ui/v082_no_plate_flip3d | 只有版本号断言失败 | 轨道 A：删除版本断言 |
| ui/v084_diary_desk_flipstrip | 需要 GPU 截帧（capture null） | 轨道 A：改名或标记为 capture，移出 headless 集合 |
| simulation/v07_deck_contract | `deck.preset.clown` 在初始条件下无法确认（v0.40 解冻后要求序列 8） | 轨道 A：合约测试按序列 8 前置条件构造 |
| gameplay/v012_identity_passive | 身份屏不再显示「最大灵性 +1 / 残页」被动文案 | 轨道 A：先确认是文案改版还是回归；属于回归就开 BUG |

## 风险

- 4 个导航集成测试失效，说明 v0.55 日记替代路线屏以来的切换路径都是无测试裸奔；轨道 B 必须先补测试再改路由。
- `.ps1` 没有经过 Windows 实测。

## 下一步入口

- 轨道 A：上表"轨道 A"各行 + R0-04 黄金回放。
- 轨道 B：`docs/architecture/UI_NAVIGATION_REVIEW.md` §3。

## 轨道 A 结果（2026-11-24）

```text
版本：v0.86.0
角色：主协调者
任务：轨道 A：R0-03 清理过期测试、基线修复、R0-04 黄金回放
状态：完成（只剩 4 个 tests/integration 导航 runner 未通过，它们归轨道 B）
修改文件：tests/ui/**（删 4 个 runner、裁剪 2 个、改名 1 个）；tests/simulation/{v07_deck,balance,v04_economy,v05_route,v06_challenge}_contract_runner.gd；tests/gameplay/v012_identity_passive_runner.gd；新增 tests/golden/**；本报告
依赖：src/app/bootstrap.gd start_route_v07、RouteSession 的公开 API（只读，没有改动）；data/** 只读
验证：tools/run_tests.sh → pass=80 fail=4 skipped=9 guard_block=0（4 个失败全部是 tests/integration 导航 runner）
```

### 删除的 runner（每个都删了 .gd、.gd.uid 和 .tscn）

| runner | 删除原因（TARGET §3.8） |
|---|---|
| `ui/v056_immersion` | 测的全是已退役的 2D 书节点（StatusPanel、EdgeInkIndex、DiaryFlip3D、FlipPageMesh 等），调用私有成员（`_resist_flip`、`_index_jump`、`_book_root`、`_is_page_corner`），还检查 docs 文件是否存在；没有一条对应 DeskStage 主路径的行为 |
| `ui/v077_live_copy` | 全部是读 `.gd` 源码做字符串断言，外加钉 `config/version="0.77.0"`；按钮文案的实际行为已由 `v077_runtime_cta` 实例化断言 |
| `ui/v081_diary_readability` | 全部是读源码断言颜色和常量（包括已删除的 C_PARCHMENT_PLATE），外加钉 `config/version` |
| `ui/v082_no_plate_flip3d` | 全部是读源码断言 flip3d 和页底板常量，外加钉 `config/version` |

### 裁剪或修正

- **`ui/v072_diary_008_layers`**
  - 保留：`DiaryUiCatalog.build_view` 的 0-08 契约（node_id 不变、`rewritten_by_pen`、base 和 overwrite 文本不同）、日记屏无 OptionButton。
  - 删除：读 `docs/design/DIARY_008_BRANCH.md` 的检查；2D 书层节点（PenRewriteStamp、GoldOverwrite、RoselleBaseInk）。
- **`ui/v077_runtime_cta`**
  - 删除：两条读源码的颜色断言；退役 `route_screen` 的检查。
  - 保留：身份、奖励、抽卡、日记的按钮文案实例化断言。
- **`ui/v084_diary_desk_flipstrip` → `v084_diary_desk_flipstrip_capture_runner`**
  - 这个 runner 需要 GPU 截帧，改名后 run_tests 会自动跳过。
  - `.tscn` 里的脚本路径已同步更新。
- **`simulation/v07_deck_contract`**
  - 契约改为：含序列 8 牌的预设（clown）在序列 9 下必须以 `sequence_locked` 拒绝确认，在序列 8 下可以确认并且是 8 张不重复的牌。
  - 每张牌需要的序列从引擎快照的 `required_sequence` 读取，不硬编码 ID。
  - 没有改 data 或 gameplay。
- **`gameplay/v012_identity_passive`：确认是文案改版，不是回归，不开 BUG。**
  - 快照里的 `passive_text_zh` 仍然含有「最大灵性 +1」和「残页」。
  - 身份屏仍然显示被动文案，只是 hub 标签前缀从「身份特性：」改成了「特性：」，并改为 clip_label 加 tooltip。
  - 这项改动在 squash 提交 e998c4e 中，和 v0.31 的定高排版整治一致。
  - 测试改为断言屏幕上出现了来自内容数据的 `passive_text_zh`，不再硬编码前缀。`identity_screen.gd` 没有改动。
- **新发现，属于 R0-08 的后续问题**
  - 现象：`simulation/balance_contract`、`v04_economy_contract`、`v05_route_contract`、`v06_challenge_contract`、`v07_deck_contract` 在干净检出时失败。
  - 原因：R0-08 已经取消跟踪 `tools/simulation/out/`，这些 runner 需要的生成文件在干净检出里不存在。R0-02 基线是在还留有生成文件的主检出里跑的，所以没有暴露。
  - 修复：数据契约照常检查；采样输出只在已经生成时校验，缺失时打印 `SIMULATION_NOTE`。
  - 有文件和无文件两种情况都已实测通过。

### R0-04 黄金回放

- **文件**：`tests/golden/golden_replay_runner.{gd,tscn}`、`tests/golden/expected.json`、`tests/golden/README.md`。
- **组合入口**：`AppBootstrap.start_route_v07`，和游戏"新游戏"使用同一入口。
  - 种子 `20261124`，路线 `route.v028.first_stage`，身份 `identity.reporter`。
  - 存档写在独立目录 `user://golden_replay`、槽位 `golden_replay`，不碰玩家存档。
- **阶段（11 个）**：

| 阶段 | 内容 |
|---|---|
| `01_start` | 开局 |
| `02_first_hunt`、`03_tenant_trace`、`04_mirror_pursuit`、`05_boundary`、`07_lamud`、`08_baron` | 6 场战斗，全部胜利；每场胜利后领取第一个奖励 |
| `06_rest` | 休整，选第一个选项 |
| `09_ascension` | 仪式，答案取自仪式内容；结束后到序列 8 |
| `10_gacha` | 单抽一次 |
| `11_checkpoint` | 存档信封 |

- **快照内容**：每阶段包含路线、成长、牌组、序列状态、命令日志（是否接受、原因码、事件类型）和战斗终局。
- **规范化**：字典键递归排序，去掉 `created_at`、`*_at`、`*_ms`、`*_path` 等易变字段，然后取 sha256。
- **确定性**：
  - runner 在同一进程内连跑两次，比较哈希。
  - 另外跨进程连跑两次，都是 `GOLDEN_REPLAY_OK`。
  - 人为篡改一个哈希后，runner 会报出变化的阶段、期望和实际摘要，并输出实际 JSON 的路径。
- **更新方式**：`"$GODOT" --headless --path . res://tests/golden/golden_replay_runner.tscn -- --update`。
  - 纯重构必须保持哈希不变。
  - 有意的规则变化才允许更新，并且要在版本文档里写明哪个阶段变了、为什么。
- 已经纳入 `tools/run_tests.sh`：自动发现，单次约 1 秒。

### 困难与候选方案

1. **v012 是回归还是改版？**
   - 难点：git 历史在 e998c4e 被 squash，看不到逐版的变化。
   - 候选 A：判定为回归，恢复「身份特性：」前缀并开 BUG-0038。
   - 候选 B：判定为改版，测试改为断言来自数据的文案。
   - 选择 B。理由：被动文案仍然完整显示，只是前缀缩短并加了 tooltip，属于定高排版的一部分；恢复前缀反而会改动现有界面。
2. **采样输出缺失。**
   - 候选 A：run_tests 先跑采样生成器。这样太慢（每个工况 1000 次采样）。
   - 候选 B：缺失时跳过采样检查并打印提示。
   - 选择 B。采样属于数值工具的产物，不是规则契约。

### 风险

- 黄金回放只覆盖"全胜"这一条首章路径，不覆盖失败、仪式答错和挑战模式；后续可以按需要加阶段。
- 采样输出缺失时会静默跳过。数值设计改动平衡后，需要手动跑 `tools/simulation/*` 重新生成。

### 跨角色请求（产品经理）

- `docs/ORIENTATION.md:41` 仍然写着"v077/v081/v082 测试必然失败"，这些 runner 已删除，请改掉这句。
- `docs/design/ART_BRIEF_V085.md:334` 和 `ART_BRIEF_V085_DRAFT.md:351` 引用的 `v084_diary_desk_flipstrip_runner.tscn` 已改名为 `v084_diary_desk_flipstrip_capture_runner.tscn`。
- 请在 v0.86.0 版本文档里登记：黄金回放基线哈希来自本次提交。

### 下一步入口

- 轨道 B 重写 4 个 integration 导航 runner 后，`tools/run_tests.sh` 应该全绿。
- R1–R4 每次提交都要跑 `tools/run_tests.sh golden`。
