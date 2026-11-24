# 架构与产品路线图（分阶段）

> **给后续智能体**：先读本文件 §0 和你所在阶段那一节，就知道下一步做什么、做到什么程度算完。  
> 依据：[`REVIEW_2026-11-24.md`](REVIEW_2026-11-24.md)（问题清单，用 `AR-xx` 引用）；终点形态见 [`TARGET_ARCHITECTURE.md`](TARGET_ARCHITECTURE.md)；决策记录 [`ADR-0031`](../decisions/ADR-0031-architecture-consolidation.md)。  
> 本文件由架构师和产品经理维护。阶段完成后在 §0 勾选，**不要删历史阶段**。

---

## 0. 总览与当前位置

| 阶段 | 建议版本 | 主题 | 玩家可见变化 | 状态 |
|---|---|---|---|---|
| — | v0.85.0 | 日记美术与字体 | 有 | ✅ 有条件关闭 2026-11-24 |
| **R0** | v0.86.0 | 安全网与止血 **+ 界面切换整治**（`UI_NAVIGATION_REVIEW.md`） | 战斗卡图修复；统一淡入淡出、输入锁、战斗收尾演完、回日记不卡、返回去向一致 | 🔶 自动化全部完成，待真窗口验收 |
| R1 | v0.87.0 | 删除死代码与旧载体 + BUG-0038 | 挑战恢复可玩 | ✅ 自动化完成（−4,253 行），待真窗口抽查 |
| R2 | v0.88.0 | 单一事实源：规则回玩法层、文案回数据、资源注册表、存档 v6 | 无（黄金回放不变） | 🔶 执行中（含热修 H-01…03） |
| R3 | v0.89.0–v0.90.0 | 结构拆分：效果注册表、引擎拆分、统一会话、屏幕组件化 | 无 | ⬜ |
| R4 | v0.91.0 | 收口：守卫全开、契约和协作文档更新 | 无 | ⬜ |
| P1 | v0.92.0+ | 第一卷完整度：旁支、结局、新手 5 分钟 | 有 | ⬜ |
| P2 | v0.95.0+ | 内容扩展：第二卷或新序列（需章程修订） | 有 | ⬜ |
| P3 | v1.0.0-rc | 发布质量：性能、导出、存档鲁棒、试玩 | 有 | ⬜ |

**大方向一句话**：先花 4–6 个版本把地基修平，让"加一张卡、一章日记、一个序列"变成**只改数据加少量独立文件**的事；然后转入内容生产，在 1.0 交付一个完整、可通关、存档可靠的廷根第一卷。

### 整治期总规则（R0–R4）

1. **行为不变**：R1–R4 是纯重构，黄金回放（R0 建立）必须保持不变。确实要改变行为的，单开条目并说明理由。
2. **冻结仍有效**：不加新卡、不扩途径、不改公式、不改 `node_id`。§TARGET 3.2 的"新增只读快照字段"不算改规则。
3. **每条任务独立可提交**：一条一个 commit（或一个小 PR），提交前跑 `tools/run_tests.sh` 全绿。
4. **先迁测试，再删代码**：删除代码之前，先把依赖它的测试改为公开 API 测试或一并删除，并在报告中列出删除的测试及理由。
5. **跨层改动单一负责人**：R2/R3 的条目会跨越多个目录，以条目上标注的"负责"为准，其他角色只读。

---

## R0 安全网与止血（v0.86.0）

**目标**：让"测试全绿"重新可信，并修掉玩家能看到的问题。**不做重构。**

| ID | 负责 | 任务 | 完成标准 |
|---|---|---|---|
| R0-01 | 主协调者 | 新建 `tools/run_tests.sh` 和 `tools/run_tests.ps1`：自动发现 `tests/**/*_runner.tscn`（排除 `capture`、`monkey`），逐个 `--headless` 运行，汇总通过/失败并以退出码返回；Godot 路径用 `$GODOT` 或按平台自动查找 | 一条命令跑完全部 runner，输出失败清单 |
| R0-02 | 主协调者 | 首次全量运行并记录基线：哪些已经失败，写入 `docs/reports/v0.86.0/coordinator.md` | 有基线失败清单 |
| R0-03 | UI | 修复或删除钉版本号的测试 `v077_live_copy`、`v081`、`v082`（AR-05）：删除版本号断言；只测死 flip3d 常量的断言一并删除 | 不再断言 `config/version` |
| R0-04 | 玩法 + 主协调者 | **黄金回放**：新建 `tests/golden/`，用固定种子和固定命令序列跑首章的路线、战斗、仪式和抽卡，把各阶段快照规范化（排序键、去掉时间戳）后取哈希，写入 `tests/golden/expected.json` | 连跑两次哈希一致，并纳入 run_tests |
| R0-05 | UI | ✅ 2026-11-24 **AR-01**：删除 `CARD_ART_BY_DEFINITION`，`get_card_art_path` 优先 v0.85 插画窗口，缺失时回落旧整卡图；v041/v042 测试改为断言新行为 | 战斗手牌显示 v0.85 卡图；在 1600×900 下截图核对 |
| R0-06 | 数据层 | **AR-04**：从 `app_controller.gd` 移除 `test_checkpoint` 特例，测试需要的状态改由测试自己构造存档 fixture | 生产代码中 `grep test_checkpoint` 为 0 |
| R0-07 | 数据层 | `challenge_session.gd:12-13` 的默认版本对齐到当前（AR-22 的一部分） | 默认值与 route_session 一致 |
| R0-08 | 美术 + 主协调者 | 新建 `art/.gdignore`，删除 `art/**` 下的 `.import`；`tools/simulation/out/` 加入 `.gitignore` 并取消跟踪（AR-54/55） | Godot 不再导入 `art/`；`git status` 干净 |
| R0-09 | 主协调者 | 在 run_tests 中加入 TARGET §4 的守卫 1 和守卫 3；守卫 2 先只报告不阻断 | 守卫在脚本中可见 |
| R0-10 | 产品经理 | 修正文档冲突（AR-24、AR-57）：根目录表述 ✅、章程删除"不做 3D 场景" ✅、章程加入提交与推送政策 ✅、README 当前基线 ✅ | 文档一致 |
| R0-11 | UI | v0.85 余项：日记八开真窗口逐页审稿与校色 | UI 报告中有结论 |
| NAV-01…09 | UI（单一负责人，授权修改 app_controller 中与路由相关的部分） | 界面切换整治，见 `UI_NAVIGATION_REVIEW.md` §3；R0-06 并入 NAV-08 | 见 v0.86.0 §4 验收 |

**退出条件**：`tools/run_tests.sh` 全绿（基线失败要么修好，要么已删除并写明理由）；黄金回放已入库；R0-05 已通过目视确认。

---

## R1 删除死代码与旧载体（v0.87.0）

**目标**：减少约 3,000 行代码和约 19 MB 资源，**不改任何玩家可见行为**。

| ID | 负责 | 任务 | 完成标准 |
|---|---|---|---|
| R1-01 | 数据层 | 删除 `bootstrap.gd` 的 legacy 入口（`start_new_game`、`start_campaign`、`start_route`、`start_challenge`、`inspect_checkpoint`、`inspect_route_checkpoint`、`load_battle_ports`、`load_campaign_ports`）和 `campaign_session.gd`；把 `tests/infrastructure/test_runner.gd` 等测试迁到 v07 入口（AR-40） | `bootstrap.gd` < 700 行；run_tests 全绿 |
| R1-02 | 数据层 | `save_migrations.gd` 只保留一个工厂（AR-43） | 只有一处注册迁移链 |
| R1-03 | UI | 删除 `route_screen.gd/.tscn` 和 `ui_preview.gd/.tscn`，以及只测它们的 runner：v05、v038、v050、v053、v054、v06、v077_runtime_cta，还有 ui_capture 中的路线部分（AR-41） | `grep route_screen` 只剩 `route_select_screen` |
| R1-04 | UI | 删除 `diary_chapter_screen.gd` 中的 2D 书、flip3d、索引面板、页角拖拽和墨晕链（AR-42）；v055、v056、v072、v083 探针改为只测 DeskStage 主路径的公开 API | 文件 < 1,500 行；V083 等价断言保留；GPU 截图目视无回归 |
| R1-05 | 主协调者 | 无引用资源目录（AR-45）和逐字节重复副本（AR-56）移到仓库外归档或 `archive/` 分支，并在 `art/ASSET_MANIFEST.md` 记录去向。**不直接删除**，符合 AGENTS 归档政策 | `assets/game` 中只剩被引用的目录 |
| R1-07 | UI | BUG-0038：`diary_ui_catalog` 对没有日记映射的路线节点生成通用回退开页，恢复挑战模式可玩性 | 挑战能通过蜡封进入第一场战斗 |
| R1-06 | 玩法 / 数值 | 删除 `data/balance/v0.2.0/balance_draft.json` 和 v0.2 的无用 schema（AR-44），同步删除引用它们的测试 | 数据目录中没有零引用文件 |

**退出条件**：run_tests 全绿；黄金回放不变；src 总行数下降不少于 2,500 行；真窗口走一遍新游戏、日记第一开、战斗和返回 hub。

---

## R2 单一事实源（v0.88.0）

**目标**：每个事实只有一个定义源。规则回到玩法层，文案回到数据，路径进入注册表。**这是整治中价值最高的阶段。**

| ID | 负责 | 任务 | 完成标准 |
|---|---|---|---|
| R2-01 | 玩法 | 战斗快照补字段：`hand[i].preview`、`required_discard`、`blocked_reason`、`player.ritual_payoff_preview`（TARGET §3.2） | 快照测试覆盖这些字段 |
| R2-02 | UI | 删除 `battle_screen` 的公式镜像、`RITUAL_PREPARE_BY_DEFINITION`、弃牌门槛回退和 `THREAT_NAMES` 中的数字，改读 R2-01 的字段（AR-02、AR-15） | `grep '4 + 3'` 在 src/ui 为 0 |
| R2-03 | 玩法 | 日记快照补字段 `can_open`、`can_advance`、`wipeable`、`wipe_cost`、`annotation_ids` | 同上 |
| R2-04 | UI | 删除 `_clue_wipeable`、`_can_open_spread`、`_can_advance_from` 和 `node_type == "ritual"` 分支（AR-03、AR-15） | UI 不再搜「墨渍」字符串 |
| R2-05 | 玩法 | **旁白迁出**：`route_engine` 的 `PEN_REWRITE_TEXTS` 和 `*_BY_NODE` 等移到 `data/diaries/tingen_volume_1.json`（新增 `annotations` 段，带 schema）；引擎只产出 `annotation_id`（AR-10）。同时删除或改写把常量钉死的 v073–v076 源码断言测试（AR-52） | `route_engine.gd` 中无中文；黄金回放的规则部分不变 |
| R2-06 | 数值 | 硬编码平衡数值迁到 `data/balance/`：墨渍消耗、笔改周期、初始属性、危险阈值、惩罚值（AR-11）；删除 progression 的兜底内容，改为加载时报错（AR-12） | 守卫：gameplay 中不出现这些数值字面量 |
| R2-07 | 玩法 | 序列等级改为 `int`/枚举字段，删除 4 处中文解析（AR-13）；`intent` 文案改为输出 `intent_id`（battle_engine:691-706） | gameplay 中不按中文字符串做判断 |
| R2-08 | 数据层 | **内容清单**：新建 `data/manifest.json`，扁平化内容目录（只保留当前生效的一份），`bootstrap` 的 42 个路径常量改为读清单（AR-21）。旧目录按归档政策处理 | 只有一份当前内容；`content_validator` 通过 |
| R2-09 | 数据层 | UI 读取内容改走基础设施：`card_art_catalog`、`diary_ui_catalog` 和 `prop_ui_catalog` 不再直接用 `FileAccess`，由 app 注入只读内容视图；补上日记 schema（AR-14） | 守卫 2 的第一条（UI 中无 FileAccess）启用并阻断 |
| R2-10 | UI + 主协调者 | **资源注册表** `data/registry/assets.json` 加 `ui/asset_registry.gd`，替换 4 个卡图来源和约 140 个路径字面量；挑战 ID 特例改为数据字段（AR-16、AR-20） | 守卫 2 的第二条（UI 中无 `res://assets/game/`）启用并阻断 |
| R2-11 | 数据层 | **存档 v6**：`checkpoint_codec` 显式映射；文案字段迁移为 ID；先按源版本 schema 校验再迁移；`content_revision` 取代 `content_version`（AR-22、AR-23、AR-33 的存档部分）。需要 ADR | v1–v5 旧档 fixture 都能加载；损坏档明确报错 |
| R2-12 | 数据层 | 效果文本格式化从 `app_controller` 移到 `ui/text/effect_text.gd`（AR-18） | app 层中没有中文拼接 |

**退出条件**：守卫全部启用；黄金回放的**规则哈希**不变（文案 ID 化导致的快照字段变化，在本版一次性更新哈希并写明）；旧存档往返测试通过。

---

## R3 结构拆分（v0.89.0–v0.90.0）

**目标**：拆掉上帝文件，让"加效果、加屏"变得局部化。可以拆成两个版本：v0.89 做玩法和 core，v0.90 做 app 和 UI。

| ID | 负责 | 任务 | 完成标准 |
|---|---|---|---|
| R3-01 | 玩法（core 授权） | core 泛化：`Result`、`DomainEvent`、`Snapshot`（make_read_only），取代 16 个近似类；抽出引擎公共基类或 mixin 提供 `_emit`、`_success`、`_rejected`；整数校验工具只保留一份（AR-32） | core 文件数减半 |
| R3-02 | 玩法 | **效果注册表**：每个效果一个 handler 文件，包含 validate、apply、preview；状态同理（AR-30，TARGET §3.1） | 新增效果只需新文件 + 注册 1 行 |
| R3-03 | 玩法 | 拆分 `battle_engine`：validator、enemy_ai、deck_zones、chain_synergy、risk_penalties、snapshot_builder | 主文件 ≤ 400 行 |
| R3-04 | 玩法 | 拆分 `route_engine` 和 `progression_engine`（TARGET §2）；`challenge_engine` 通过端口使用路线，不再 preload；抽卡使用独立的 `GachaRandomPort`（AR-19、AR-31） | 每个文件 ≤ 500 行 |
| R3-05 | 玩法 + 数据层 | **RunEngine 和 RunSession**：阶段前置条件、战斗到节点结算、奖励应用移入 `gameplay/run/run_engine.gd`；`route_session` 和 `challenge_session` 合并为 `app/run_session.gd`，用策略参数区分（AR-17、AR-34） | 只剩一个会话类 |
| R3-06 | 数据层 | 拆分 `bootstrap` 和 `app_controller`：composition_root、content_manifest、checkpoint_codec、screen_router，`app_root` 变成薄壳（AR-35） | 每个文件 ≤ 500 行 |
| R3-07 | UI | `ui/common/`：`ScreenBase`、`theme_tokens`、widgets、fx；把散落的辅助函数和颜色字面量收拢进来（AR-36） | `Color("#` 字面量只出现在 theme_tokens 中 |
| R3-08 | UI | 拆分 `battle_screen`：hud、enemy_lane、hand_card、hand_controller、battle_fx、event_formatter | 主文件 ≤ 600 行 |
| R3-09 | UI | 拆分 `diary_chapter_screen` 和 `diary_desk_stage`：用 view_model 承接快照 | 每个文件 ≤ 800 行 |

**退出条件**：黄金回放不变；单文件不超过 800 行（UI）或 500 行（其他层），有例外的在报告中说明；真窗口完整打一遍首章。

---

## R4 收口（v0.91.0）

| ID | 负责 | 任务 |
|---|---|---|
| R4-01 | 主协调者 | 测试框架化：新建 `tests/framework/test_case.gd` 和共享 fakes，把 runner 改为按行为命名，合并重叠的 capture 和 battle-feel runner（AR-51、AR-53） |
| R4-02 | 主协调者 | 所有守卫改为阻断；`run_tests` 加入文件长度报告 |
| R4-03 | 产品经理 + 架构师 | 更新 `ARCHITECTURE_CONTRACT.md` 以吸收 TARGET 的约定，`ORIENTATION.md` 更新代码地图，本 ROADMAP 勾选 R0–R4 |
| R4-04 | 主协调者 | 评估是否把 `art/assets/raster` 迁到 Git LFS（AR-55），形成 ADR，不强制 |

**退出条件**：一位新智能体只读 ORIENTATION + TARGET 就能在 30 分钟内**只改数据**加一个复用现有效果的测试卡（在测试 fixture 中加，不进正式卡池）。

---

## P1 第一卷完整度（v0.92.0+）

整治完成后恢复产品推进。**每个版本只做一个可验收的玩家价值切片。**

| 候选切片 | 内容 | 依赖 |
|---|---|---|
| 日记旁支 | ACTIVE_PLAN K-02：`kind != main` 线索和贴条，2–3 条旁支文案 | R2-05（旁白已数据化） |
| 结算三态 | K-05 胜/败/墨渍的视觉差异 | R3-09 |
| 新手 5 分钟 | 对照章程 §7 成功标准做一次无引导试玩，并记录 | — |
| 结局闭环 | 第一卷通关和失败结局的叙事收口 | R2-05 |
| 真弯页 | K-03 | R3-09 |

**P1 退出条件**：章程 §7 首版试玩标准逐条可验证通过。

## P2 内容扩展（v0.95.0+，需章程修订）

- 由产品经理决定扩展方向：第二卷日记（新城区）、序列 7 晋升，或新卡包。**一次只选一个。**
- 前置条件：解冻 ACTIVE_PLAN D-01/D-02；内容管线 `validate_content` 全绿。
- 架构预期：只新增 `data/**` 内容、`effects/` 中少量新 handler 和资源注册表条目，**不新增引擎或屏幕**。如果需要新增，说明架构有缺口，应先提 ADR。

## P3 发布质量（v1.0.0-rc）

- 导出：Windows 和 macOS 构建脚本对齐，加入 run_tests 作为构建前置门。
- 存档：连续三次启动、存档、读取不丢进度（章程 §7）；新增"坏档、旧档、新档"三种 fixture 的端到端测试。
- 性能：DeskWorld 3D 在集显上的帧率预算；资源导入体积预算。
- 试玩：外部（非开发者）试玩一次，问题记入 `docs/bugs`。

---

## 附：阶段之间的依赖

```text
R0 安全网 + 界面切换 ─┬─▶ R1 删死代码 ─▶ R2 单一事实源 ─▶ R3 拆分 ─▶ R4 收口 ─▶ P1 ─▶ P2 ─▶ P3
           └─ R0-05 卡图修复可以立即做，不阻塞
R0 内部两条轨道并行：A 安全网（tests/tools），B 界面切换（app_controller 路由 + ui 钩子）。两条轨道文件不重叠。
```

R2 是**不可跳过**的阶段：如果跳过 R2 直接做 R3，就是在错误的事实源上拆文件，拆完还要再拆一次。
