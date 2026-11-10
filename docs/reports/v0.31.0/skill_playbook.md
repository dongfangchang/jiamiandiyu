# 《假面低语》Skill 选用清单（v0.31.0）

- 日期：2026-11-10
- 角色：主协调者备忘
- 原则：本仓库事实源仍是 `AGENTS.md`、`docs/CURRENT_VERSION.md`、版本文档与角色报告。外部 skill 只提供方法与检查清单，不另立目录体系，不覆盖现有协作规则。

## 1. 默认启用（当前版本日常）

| Skill | 何时用 | 产出落点 |
|---|---|---|
| `balance-check` | 改卡牌效果、费用、封印物代价、联动奖励后 | `docs/reports/<version>/numerical_designer.md`；数值门继续以 `tests/simulation/v031_card_value_audit_runner.gd` 为准 |
| `godot-code-review` | 审 `BattleEngine`、联动/仪式、布局固定区等热区改动 | 对应角色报告的验证段；不直接改公共契约 |
| `godot-gdscript-headless-testing` / `godot-testing` | 补回归、破坏路径、最小测试集 | `tests/**` 中本角色可编辑目录 |
| `godot-ui` | 界面互挤、多视口滚动降级、固定高度区域 | `src/ui/**`、`scenes/ui/**`、`tests/ui/**` |
| `smoke-check` | 版本门前自动冒烟 | QA / 协调者报告；失败不得宣称可玩 |
| `game-qa` | 真实窗口、截图、核心环、重启与已知限制验收 | `.tools/ui-captures/<version>/` + QA 报告 |
| `scope-check` | 任何“顺手加内容”冲动时 | 候选池写入版本报告，不直接开工 |
| `playtest-report` | 真人试玩仪式/联动/首领可读性后 | 结构化进协调者或 QA 报告 |

## 2. 有明确任务再开

| Skill | 适用任务 | 约束 |
|---|---|---|
| `scenario-game-assets` | 正式卡图、敌人立绘、统一视觉生产 | 候选进 `art/**`；正式 PNG 仅主协调者迁入 `assets/game/**`；UI 实际界面审稿 |
| `art-bible` / `asset-spec` / `asset-audit` | 美术规范、单资产规格、资产合规 | 服从现有 `art/ART_DIRECTION.md`；不改玩法或数值 |
| `novel-game-analyze` | 核对廷根线节点、能力边界、原著场面是否漂移 | **只借拆书法**；产出对照 `docs/design/TINGEN_CANON.md`，不重开改编工程 |
| `card-game` | 再调构筑节奏、combo、牌组预设主题时 | 稳定卡牌 ID 不变；平衡仍走价值审计 |
| `team-combat` / `team-ui` / `team-qa` | 需要多智能体并行某一切片时 | 文件边界仍按本项目角色表，不按 Game-Studios 默认路径 |
| `hotfix` / `day-one-patch` | 发布前阻断缺陷的小补丁版本 | 先写 BUG 记录；默认前向修复 |
| `milestone-review` / `gate-check` | 决定关闭 v0.31 或开启下一版本 | 缺窗口证据不得关闭 |

## 3. 明确不用作主流程

| Skill | 原因 |
|---|---|
| `novel-to-game` 总入口 | 会另起改编流水线与工作区约定；本项目已是可玩 Godot 工程 |
| `game-studios-init` / `start` / `adopt` / `create-architecture` | 面向新项目或模板迁移；会与现有 `docs/**`、`AGENTS.md` 抢事实源 |
| 原版 `content-audit` / `consistency-check` | 默认盯 GDD/entity registry；本仓库事实源是 `data/**` + 版本文档，需改映射后才能用 |
| `unity-*` / `unreal-*` / `roblox-*` 等非 Godot skill | 引擎不对口 |

## 4. 推荐组合拳

1. **改数值/卡牌**：`balance-check` → 现有 `V031_CARD_VALUE_AUDIT` →（可选）难度抽样 → 数值报告。
2. **改战斗/UI 代码**：`godot-code-review` → 最小相关 headless → `godot-ui`（若动布局）→ 角色报告。
3. **版本门**：`scope-check` → `smoke-check` → `game-qa`（含截图）→ `playtest-report` → 产品经理裁决是否关闭。
4. **补正式美术**：`art-bible`/`asset-spec` → `scenario-game-assets` → `asset-audit` → UI 审稿 → 主协调者迁移。

## 5. 与本项目多智能体的衔接

- 产品经理 / 主协调者：选用 skill、卡范围、验收。
- 各角色：只读相关 skill 的方法段，只写自己目录与 `docs/reports/<version>/<role>.md`。
- 冲突时：以 `AGENTS.md` 与当前版本文档为准，不以 skill 模板目录为准。

## 6. 下次复审

- 触发：开启新主版本、引入新外部 skill、或 Game-Studios / NovelToGame 目录约定与本仓库再次冲突时。
- 入口：先读本文件，再读 `docs/CURRENT_VERSION.md`。
