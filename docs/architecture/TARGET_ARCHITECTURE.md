# 目标架构（Target Architecture）

> 本文件描述整治完成后（ROADMAP R4 结束）的代码形态，是重构的"终点图"。  
> 它不替代 [`../ARCHITECTURE_CONTRACT.md`](../ARCHITECTURE_CONTRACT.md)：契约定义**原则**，本文件定义**具体模块与约定**。冲突时以契约为准，并提 ADR 修正其中一方。  
> 每个阶段做什么，见 [`ROADMAP.md`](ROADMAP.md)；为什么这样做，见 [`REVIEW_2026-11-24.md`](REVIEW_2026-11-24.md)。

---

## 1. 分层（不变，但补全"谁拥有什么"）

```text
ui  ──命令/查询──▶  app  ──▶  gameplay  ──▶  core
 ▲                   │             ▲
 └──只读视图模型──────┘             │ 端口实现
                     infrastructure ┘
app/composition_root  ──装配──▶  ui, gameplay, infrastructure
```

| 层 | 拥有 | 绝不拥有 |
|---|---|---|
| `core` | 稳定 ID、通用 `Result`/`DomainEvent`/`Snapshot`、端口接口、枚举 | 任何规则、文案、路径 |
| `gameplay` | **所有**规则：结算、可用性、解锁、成本、阶段前置条件、奖励、预览数值 | 中文文案、资源路径、文件、真 RNG |
| `app` | 装配、会话生命周期、存档时机、屏幕路由 | 规则分支、文案格式化、按 slot 名写特例 |
| `infrastructure` | 所有文件 I/O：内容、存档、偏好、日志、RNG 实现 | 规则、UI |
| `ui` | 布局、输入、动画、**把 ID 映射成文案和图** | 任何"能不能""多少"的判断 |

**判定口诀**：如果把 UI 换成命令行界面，这个判断还需要吗？需要，就属于 gameplay。

---

## 2. 目录终态

```text
src/
  core/
    result.gd               # 通用 Result{ok, code, data, events}，取代 5 个 *CommandResult
    domain_event.gd         # 通用事件{type, payload}，取代 5 个 *Event
    snapshot.gd             # 只读快照封装（make_read_only），取代 6 个 *Snapshot
    commands/               # 保留各域 Command（它们确实不同）
    ports/                  # content_port, random_port, clock_port …
    ids.gd                  # 序列等级等枚举（取代中文字符串解析）
  gameplay/
    battle/
      battle_engine.gd      # ≤400 行：submit/play/end_turn/outcome 编排
      battle_validator.gd
      effects/
        effect_registry.gd  # effect_id → handler，一处注册
        damage.gd, block.gd, draw.gd, status.gd, ritual.gd …   # 每个 handler 自带 validate + apply
      statuses/             # 同理：status_id → handler
      enemy_ai.gd
      deck_zones.gd
      chain_synergy.gd
      risk_penalties.gd
      battle_snapshot_builder.gd   # 含 payoff_preview / required_discard 等 UI 需要的派生字段
    run/
      run_engine.gd         # 路线 + 挑战共用的"一局"编排（取代 session 里的规则）
      route_graph.gd
      ritual_flow.gd
      diary_progress.gd     # 笔改/墨渍/覆写：只产出 annotation_id，不产出文案
    progression/
      gacha.gd, upgrade.gd, digestion.gd, rewards.gd, identity_modifiers.gd
    deck/
      deck_engine.gd
    challenge/
      challenge_engine.gd   # 通过 RunEngine 端口编排，不 preload RouteEngine
  app/
    composition_root.gd     # 唯一 new 具体实现的地方
    content_manifest.gd     # 读 data/manifest.json → ContentBundle
    run_session.gd          # 单一会话；route/challenge 通过策略参数区分
    checkpoint_codec.gd     # 运行状态 ⇄ 存档 DTO（显式映射，不直接导出内部 _state）
    screen_router.gd        # 屏幕切换表
    app_root.gd             # 薄壳：信号接线
  infrastructure/           # 基本保持；合并重复的迁移注册
  ui/
    common/
      screen_base.gd        # apply_view/set_pending/status/empty 等共用协议
      theme_tokens.gd       # 颜色、字号、间距 token（取代散落的 Color 字面量）
      widgets/              # 按钮、计量条、浮字、横幅、卡牌小部件
      fx/                   # 抖动、闪光、tween 帮助
    text/
      effect_text.gd        # effect_id → 中文描述（从 app_controller 迁来）
      narration_text.gd     # annotation_id → 中文（读日记数据）
    asset_registry.gd       # 读 data/registry/assets.json；全 UI 唯一取图入口
    battle/   battle_screen.gd(≤600) + hud.gd + enemy_lane.gd + hand_card.gd + hand_controller.gd + battle_fx.gd + event_formatter.gd
    diary/    diary_chapter_screen.gd(≤800) + diary_desk_stage.gd + diary_view_model.gd
    …其余屏按同一模式
data/
  manifest.json             # 当前生效的内容清单：kind → path + schema（唯一）
  cards/cards.json          # 扁平：不再按版本号分目录
  balance/battle.json, run.json, economy.json, gacha.json
  enemies/ encounters/ routes/ rituals/ challenges/ decks/
  diaries/tingen_volume_1.json      # 含旁白/批注文案（从 route_engine 迁来）
  registry/assets.json      # ID → res:// 路径（卡图、敌人、场景、蜡封、道具）
  schema/                   # 每种内容一份当前 schema + save/ 下的历史存档 schema
tests/
  framework/                # test_case.gd（断言库）、fakes/（共享假端口）、run_all.gd
  unit/<模块>/              # 按行为命名：test_ritual_payoff.gd …
  golden/                   # 黄金回放：种子 + 命令序列 → 快照哈希
  ui_smoke/                 # 少量真场景冒烟（只测公开 API）
  capture/                  # 需要 GPU 的截图，不进默认测试集
tools/
  run_tests.sh / run_tests.ps1     # 跨平台唯一入口
  validate_content.gd       # ID 唯一、引用存在、资源路径存在
art/.gdignore               # 源美术不进 Godot 导入
```

---

## 3. 关键约定

### 3.1 效果注册表（解决 AR-30）

```gdscript
# gameplay/battle/effects/effect_registry.gd
static func handlers() -> Dictionary:
    return {
        &"damage": DamageEffect,
        &"block": BlockEffect,
        ...
    }
# 每个 handler 提供：
#   static func validate(def: Dictionary) -> Result
#   static func apply(ctx: BattleContext, def: Dictionary) -> void
#   static func preview(ctx: BattleContext, def: Dictionary) -> Dictionary   # 给 UI 的预估数值
```

- 新增效果 = 新建 1 个文件 + 注册表 1 行 + schema enum 1 项。
- 校验和执行不得分散在两个 `match` 里。
- `preview` 输出 UI 需要的所有数字（伤害、层数、弃牌数），UI 不得自行计算。

### 3.2 快照必须"足够 UI 用"

UI 需要做"能不能/多少"的判断时，答案必须由快照字段提供。整治时至少补齐这些字段：

| 快照 | 新字段 | 取代的 UI 逻辑 |
|---|---|---|
| battle.hand[i] | `playable`, `blocked_reason`, `required_discard`, `preview{damage, stacks…}` | battle_screen 的公式镜像和弃牌门槛 |
| battle.player | `ritual_payoff_preview` | `4 + 3×层` |
| diary.spread[i] | `can_open`, `can_advance`, `wipeable`, `wipe_cost`, `annotation_ids[]` | `_can_open_spread`、`_clue_wipeable` |
| progression.card[i] | `can_upgrade`, `upgrade_cost` | upgrade_screen:204 |
| run | `sequence_tier:int` | 从「序列8」字符串解析 |

**冻结期例外**：只增加只读快照字段、不改变任何结算结果的改动，不视为"改规则"，可以在玩法冻结期进行。前提是黄金回放保持不变。

### 3.3 文案与规则分离

- gameplay 只输出 **ID**：`annotation_id`、`intent_id`、`blocked_reason` 枚举等。
- 中文文案统一放在 `data/**` 或 `ui/text/**`，存档只存 ID。
- 旧存档里已有的 `text_zh` 字段，由迁移把它映射回 ID；映射不到的保留为 `legacy_text_zh` 并只读显示。

### 3.4 内容清单与扁平化（解决 AR-21）

- `data/manifest.json` 是**唯一**的"当前生效内容"定义。
- 内容不再按版本号建目录，历史通过 git 追溯；每个文件里的 `schema_version` 负责兼容性。
- 存档里的 `content_version` 改为 manifest 中的 `content_revision`（单调整数）。

### 3.5 资源注册表（解决 AR-20）

- `data/registry/assets.json`：`{ "card.skill.silver_dagger": {"art": "res://…", "face": "res://…"}, … }`
- 只有 `ui/asset_registry.gd` 可以读它；UI 代码中禁止出现 `res://assets/game/` 字面量。可用 grep 守卫，见 §4。
- 主协调者迁入资源时**同时**更新注册表；美术不直接改。

### 3.6 存档

- `save_version` 每次形状变化都要 +1。整治期间预计升到 **6**，加入日记结算等字段并把文案改为 ID。
- 加载顺序严格是：解析 → **按源版本 schema 校验** → 逐步迁移 → 按目标 schema 校验 → 不变量检查。
- 运行状态与存档 DTO 之间由 `checkpoint_codec` 显式映射，禁止 `export_persistent_state()` 直接返回内部字典。
- 历史存档 schema 移到 `data/schema/save/v1..vN.schema.json`，只增不改。

### 3.7 UI 屏幕

- 每个屏继承 `ScreenBase`，只实现 `_build()` 和 `_render(view_model)`。
- 颜色、字号、间距一律来自 `theme_tokens`。
- 单文件超过 800 行必须拆分组件（battle_screen 首拆）。
- 新载体验收通过的**同一版本**，删除旧载体和只为它存在的探针。

### 3.8 测试

- 有唯一入口：`tools/run_tests.sh`（macOS/Linux）和 `tools/run_tests.ps1`（Windows），以退出码表示结果。
- 用 `tests/framework/test_case.gd` 提供断言，禁止每个文件各写一份 `_expect`。
- 测试**按行为命名**，不按版本号。
- **禁止**：断言 `project.godot` 版本号；读取 `.gd` 源码文本做断言；访问 `_private` 成员（需要观察的东西应该改为公开查询或快照字段）。
- 黄金回放：用固定种子和命令序列跑完首章，比较快照摘要哈希。**任何纯重构都必须让黄金回放保持不变**；有意的规则变化要同步更新哈希，并在版本文档里写明原因。

---

## 4. 可机器检查的守卫（R0 起加入 `tools/run_tests.*`）

```bash
# 1. gameplay/core 纯净
rg -n 'FileAccess|randi\(|randf\(|RandomNumberGenerator|extends (Node|Control)' src/gameplay src/core && exit 1
# 2. UI 不读文件、不写资源路径字面量（R2 结束后启用第二条）
rg -n 'FileAccess' src/ui && exit 1
rg -n 'res://assets/game/' src/ui && exit 1
# 3. 测试不钉版本号、不读源码
rg -n 'config/version=' tests && exit 1
rg -n 'FileAccess.*\.gd"' tests && exit 1
# 4. 文件长度预警（不阻断，只报告）
find src -name '*.gd' | xargs wc -l | awk '$1>800 && $2!="total"'
```

---

## 5. 刻意不做（防过度设计）

- 不引入第三方测试框架（GUT 等）。自研 `test_case.gd` 约 100 行就够用，也避免新依赖评审。
- 不做插件、mod 或通用脚本化效果。注册表只是一张静态字典。
- 不为"第二座城市"做抽象。`run_engine` 只服务现有路线和挑战。
- 不把所有屏幕改写成 `.tscn` 编辑器布局。代码建树可以保留，但要组件化，并通过公开 API 测试。
