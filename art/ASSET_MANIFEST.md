# 美术资产清单

历史原型美术以项目内生成的 SVG 及其 PNG 导出为主。新增字体与栅格素材分别登记来源、版本、授权及验收状态；生产计划不代表资产已交付。

正式 PNG 已一次性迁移到项目级 `assets/game/`：卡牌 600 x 840，敌人 900 x 900，场景 1600 x 900，图标表 1200 x 800。`art/assets/svg/` 只保留可编辑源文件，不再保留同名 PNG 副本。

## 当前资产

| 文件名 | 类型 | 状态 | 用途 |
|---|---|---|---|
| `assets/svg/templates/card-frame.svg` | 模板 | 可用 | 卡框与版式基准 |
| `assets/svg/cards/card-identity-reporter.svg` | 人格牌 | 原型 | 记者身份样张 |
| `assets/svg/cards/card-identity-doctor.svg` | 人格牌 | 原型 | 医生身份样张 |
| `assets/svg/cards/card-identity-gravedigger.svg` | 人格牌 | 原型 | 守墓人身份样张 |
| `assets/svg/cards/card-artifact-watchers-eye.svg` | 封印物牌 | 原型 | 窥视者之眼 |
| `assets/svg/cards/card-artifact-faceless-mask.svg` | 封印物牌 | 原型 | 无面遗嘱 |
| `assets/svg/enemies/enemy-lantern-pursuer.svg` | 敌人 | 原型 | 提灯追猎者 |
| `assets/svg/scenes/ritual-ascension.svg` | 场景 | 原型 | 晋升试炼背景 |
| `assets/svg/scenes/title-screen.svg` | 场景 | 原型 | 标题画面 |
| `assets/svg/icons/status-sheet.svg` | 图标 | 原型 | 状态与资源图标参考 |
| `preview/contact-sheet.html` | 预览 | 可用 | 浏览器查看整套样张 |

## v0.3.0 战斗返工资产

以下资产根据 `docs/reports/v0.3.0/ui_art_review.md` 制作。美术完成制作与尺寸检查后，已由 UI 在实际界面完成审稿；v0.3.0 原型范围审稿通过，证据见 `docs/reports/v0.3.0/ui_asset_integration.md`。

| 稳定 ID | SVG 源 | PNG 候选 | 尺寸 | 用途 |
|---|---|---|---:|---|
| `scene.battle.tingen_old_house` | `art/assets/svg/v0.3.0/scenes/battle-tingen-old-house.svg` | `assets/game/v0.3.0/scenes/battle-tingen-old-house.png` | 1600×900 | 无文字战斗背景 |
| `enemy.weeping_tenant` | `art/assets/svg/v0.3.0/enemies/enemy-weeping-tenant.svg` | `assets/game/v0.3.0/enemies/enemy-weeping-tenant.png` | 900×900 | 哭泣的房客 |
| `enemy.candle_moth` | `art/assets/svg/v0.3.0/enemies/enemy-candle-moth.svg` | `assets/game/v0.3.0/enemies/enemy-candle-moth.png` | 900×900 | 烛焰飞蛾 |
| `enemy.mirror_hound` | `art/assets/svg/v0.3.0/enemies/enemy-mirror-hound.svg` | `assets/game/v0.3.0/enemies/enemy-mirror-hound.png` | 900×900 | 镜中猎犬 |
| `card.skill.ink_dart` | `art/assets/svg/v0.3.0/cards/card_skill_ink-dart.svg` | `assets/game/v0.3.0/cards/card_skill_ink-dart.png` | 512×400 | 无文字卡面 |
| `card.skill.paper_guard` | `art/assets/svg/v0.3.0/cards/card_skill_paper-guard.svg` | `assets/game/v0.3.0/cards/card_skill_paper-guard.png` | 512×400 | 无文字卡面 |
| `card.skill.calm_breath` | `art/assets/svg/v0.3.0/cards/card_skill_calm-breath.svg` | `assets/game/v0.3.0/cards/card_skill_calm-breath.png` | 512×400 | 无文字卡面 |
| `card.skill.focus` | `art/assets/svg/v0.3.0/cards/card_skill_focus.svg` | `assets/game/v0.3.0/cards/card_skill_focus.png` | 512×400 | 无文字卡面 |
| `card.skill.insight` | `art/assets/svg/v0.3.0/cards/card_skill_insight.svg` | `assets/game/v0.3.0/cards/card_skill_insight.png` | 512×400 | 无文字卡面 |
| `card.skill.omen` | `art/assets/svg/v0.3.0/cards/card_skill_omen.svg` | `assets/game/v0.3.0/cards/card_skill_omen.png` | 512×400 | 无文字卡面 |
| `card.skill.whisper` | `art/assets/svg/v0.3.0/cards/card_skill_whisper.svg` | `assets/game/v0.3.0/cards/card_skill_whisper.png` | 512×400 | 无文字卡面 |
| `card.skill.second_look` | `art/assets/svg/v0.3.0/cards/card_skill_second-look.svg` | `assets/game/v0.3.0/cards/card_skill_second-look.png` | 512×400 | 无文字卡面 |
| `status.*` | `art/assets/svg/v0.3.0/status/status-*.svg` | `assets/game/v0.3.0/status/status-*.png` | 64×64 | 12 个状态图标 |

评审拼图：`assets/game/v0.3.0/contact-sheet.png`。

迁移约定：主协调者应将正式候选 PNG 一次性迁入 `assets/game/**`，然后删除候选副本或把它们明确视为导出缓存；不得让 `assets/game/` 与正式引用同时保留两套长期可编辑副本。

## v0.4.0 短循环候选

以下资产根据 `docs/versions/v0.4.0.md` 制作，已迁移到正式目录并通过 UI 实际界面审稿。美术只提交候选，不自行标记界面通过。

| 稳定 ID | SVG 源 | PNG 候选 | 尺寸 | 用途 |
|---|---|---|---:|---|
| `identity.reporter` | `art/assets/svg/v0.4.0/identities/card-identity-reporter.svg` | `assets/game/v0.4.0/identities/card-identity-reporter.png` | 512×640 | 白昼身份：记者 |
| `identity.doctor` | `art/assets/svg/v0.4.0/identities/card-identity-doctor.svg` | `assets/game/v0.4.0/identities/card-identity-doctor.png` | 512×640 | 白昼身份：医生 |
| `identity.gravedigger` | `art/assets/svg/v0.4.0/identities/card-identity-gravedigger.svg` | `assets/game/v0.4.0/identities/card-identity-gravedigger.png` | 512×640 | 白昼身份：守墓人 |
| `scene.gacha.altar` | `art/assets/svg/v0.4.0/scenes/gacha-altar.svg` | `assets/game/v0.4.0/scenes/gacha-altar.png` | 1600×900 | 灵界祈愿背景 |
| `scene.reward.archive` | `art/assets/svg/v0.4.0/scenes/reward-archive.svg` | `assets/game/v0.4.0/scenes/reward-archive.png` | 1600×900 | 战后奖励三选一背景 |
| `status.upgrade_1` | `art/assets/svg/v0.4.0/icons/upgrade-1.svg` | `assets/game/v0.4.0/icons/upgrade-1.png` | 128×128 | 一级升级印章 |
| `status.upgrade_2` | `art/assets/svg/v0.4.0/icons/upgrade-2.svg` | `assets/game/v0.4.0/icons/upgrade-2.png` | 128×128 | 二级升级印章 |
| `status.upgrade_3` | `art/assets/svg/v0.4.0/icons/upgrade-3.svg` | `assets/game/v0.4.0/icons/upgrade-3.png` | 128×128 | 三级升级印章 |
| `resource.card_shard` | `art/assets/svg/v0.4.0/icons/card-shard.svg` | `assets/game/v0.4.0/icons/card-shard.png` | 128×128 | 重复卡碎片 |
| `resource.divination_ticket` | `art/assets/svg/v0.4.0/icons/divination-ticket.svg` | `assets/game/v0.4.0/icons/divination-ticket.png` | 128×128 | 占卜券 |
| `card.back.sealed_omen` | `art/assets/svg/v0.4.0/cards/card-back-sealed-omen.svg` | `assets/game/v0.4.0/cards/card-back-sealed-omen.png` | 512×720 | 抽卡卡背 |

审稿拼图：`assets/game/v0.4.0/contact-sheet.png`。正文和资源数字必须由 Godot 渲染，不能烘焙进这些图像。

## v0.5.0 短路线与晋升候选

以下资产根据 `docs/versions/v0.5.0.md` 制作，已在路线、休息、首领和晋升界面通过 UI 实际审稿。

| 稳定 ID | SVG 源 | PNG 候选 | 尺寸 | 用途 |
|---|---|---|---:|---|
| `scene.route.v050.short_road` | `art/assets/svg/v0.5.0/scenes/route-map.svg` | `assets/game/v0.5.0/scenes/route-map.png` | 1600×900 | 五节点羊皮纸路线图 |
| `scene.rest.old_house` | `art/assets/svg/v0.5.0/scenes/rest-old-house.svg` | `assets/game/v0.5.0/scenes/rest-old-house.png` | 1600×900 | 旧宅休息场景 |
| `enemy.mirror_baron` | `art/assets/svg/v0.5.0/enemies/enemy-mirror-baron.svg` | `assets/game/v0.5.0/enemies/enemy-mirror-baron.png` | 900×900 | 原创首领镜厅男爵 |
| `scene.ritual.tampered_obituary` | `art/assets/svg/v0.5.0/scenes/ritual-tampered-obituary.svg` | `assets/game/v0.5.0/scenes/ritual-tampered-obituary.png` | 1600×900 | 三步晋升仪式背景 |
| `ritual.card.name_record` | `art/assets/svg/v0.5.0/rituals/ritual-card-name-record.svg` | `assets/game/v0.5.0/rituals/ritual-card-name-record.png` | 420×600 | 姓名记录仪式牌 |
| `ritual.card.chronology` | `art/assets/svg/v0.5.0/rituals/ritual-card-chronology.svg` | `assets/game/v0.5.0/rituals/ritual-card-chronology.png` | 420×600 | 事件顺序仪式牌 |
| `ritual.card.seal` | `art/assets/svg/v0.5.0/rituals/ritual-card-seal.svg` | `assets/game/v0.5.0/rituals/ritual-card-seal.png` | 420×600 | 封印符号仪式牌 |
| `status.route.pending` | `art/assets/svg/v0.5.0/icons/route-pending.svg` | `assets/game/v0.5.0/icons/route-pending.png` | 96×96 | 未到达节点 |
| `status.route.current` | `art/assets/svg/v0.5.0/icons/route-current.svg` | `assets/game/v0.5.0/icons/route-current.png` | 96×96 | 当前节点 |
| `status.route.completed` | `art/assets/svg/v0.5.0/icons/route-completed.svg` | `assets/game/v0.5.0/icons/route-completed.png` | 96×96 | 已完成节点 |
| `status.ritual.success` | `art/assets/svg/v0.5.0/icons/ritual-success.svg` | `assets/game/v0.5.0/icons/ritual-success.png` | 128×128 | 仪式成功 |
| `status.ritual.failure` | `art/assets/svg/v0.5.0/icons/ritual-failure.svg` | `assets/game/v0.5.0/icons/ritual-failure.png` | 128×128 | 仪式失败/污染 |

审稿拼图：`assets/game/v0.5.0/contact-sheet.png`。HTML 预览：`art/preview/v0.5.0/index.html`。

## v0.6.0 挑战候选

以下资产根据 `docs/versions/v0.6.0.md` 制作，已迁移到 `assets/game/v0.6.0/**` 并在实际挑战选择、路线与结算界面通过 UI 审稿。

| 稳定 ID | SVG 源 | PNG 候选 | 尺寸 | 用途 |
|---|---|---|---:|---|
| `scene.challenge.selection` | `art/assets/svg/v0.6.0/scenes/challenge-selection.svg` | `assets/game/v0.6.0/scenes/challenge-selection.png` | 1600×900 | 挑战选择背景，预留三个修饰卡区域 |
| `scene.challenge.result` | `art/assets/svg/v0.6.0/scenes/challenge-result.svg` | `assets/game/v0.6.0/scenes/challenge-result.png` | 1600×900 | 挑战结算背景，预留中央印章和结算信息 |
| `challenge.modifier.pressure_advance` | `art/assets/svg/v0.6.0/icons/modifier-pressure-advance.svg` | `assets/game/v0.6.0/icons/modifier-pressure-advance.png` | 128×128 | 敌人压力提前 |
| `challenge.modifier.mirror_echo` | `art/assets/svg/v0.6.0/icons/modifier-mirror-echo.svg` | `assets/game/v0.6.0/icons/modifier-mirror-echo.png` | 128×128 | 镜厅回响/污染压力 |
| `challenge.modifier.restricted_reward` | `art/assets/svg/v0.6.0/icons/modifier-restricted-reward.svg` | `assets/game/v0.6.0/icons/modifier-restricted-reward.png` | 128×128 | 奖励限制 |
| `challenge.modifier.compact_deck` | `art/assets/svg/v0.6.0/icons/modifier-compact-deck.svg` | `assets/game/v0.6.0/icons/modifier-compact-deck.png` | 128×128 | 紧凑牌组 |
| `challenge.modifier.reinforced_guard` | `art/assets/svg/v0.6.0/icons/modifier-reinforced-guard.svg` | `assets/game/v0.6.0/icons/modifier-reinforced-guard.png` | 128×128 | 敌人强化护盾 |
| `challenge.modifier.early_phase` | `art/assets/svg/v0.6.0/icons/modifier-early-phase.svg` | `assets/game/v0.6.0/icons/modifier-early-phase.png` | 128×128 | 首领阶段提前 |
| `status.challenge.success` | `art/assets/svg/v0.6.0/icons/challenge-success.svg` | `assets/game/v0.6.0/icons/challenge-success.png` | 128×128 | 挑战成功印章 |
| `status.challenge.failure` | `art/assets/svg/v0.6.0/icons/challenge-failure.svg` | `assets/game/v0.6.0/icons/challenge-failure.png` | 128×128 | 挑战失败印章 |
| `challenge.mode.emblem` | `art/assets/svg/v0.6.0/icons/challenge-emblem.svg` | `assets/game/v0.6.0/icons/challenge-emblem.png` | 256×256 | 挑战模式徽记 |
| `challenge.deck.restricted` | `art/assets/svg/v0.6.0/icons/deck-restricted.svg` | `assets/game/v0.6.0/icons/deck-restricted.png` | 128×128 | 牌组受限标识 |

审稿拼图：`assets/game/v0.6.0/contact-sheet.png`。HTML 预览：`art/preview/v0.6.0/index.html`。

## v0.7.0 卡组构筑与第二挑战候选

以下资产根据 `docs/versions/v0.7.0.md` 与正式 v0.7 卡牌/挑战数据制作。美术完成 XML、尺寸和实际拼图检查，等待 UI 在卡组编辑、收藏、第二挑战和结算界面实机审稿；美术不得自行标记界面通过。

| 稳定 ID | SVG 源 | PNG 候选 | 尺寸 | 用途 |
|---|---|---|---:|---|
| `card.skill.warding_circle` | `art/assets/svg/v0.7.0/cards/card_skill_warding_circle.svg` | `assets/game/v0.7.0/cards/card_skill_warding_circle.png` | 512×400 | 守夜圆环 |
| `card.skill.lantern_step` | `art/assets/svg/v0.7.0/cards/card_skill_lantern_step.svg` | `assets/game/v0.7.0/cards/card_skill_lantern_step.png` | 512×400 | 提灯步 |
| `card.skill.whispered_hunch` | `art/assets/svg/v0.7.0/cards/card_skill_whispered_hunch.svg` | `assets/game/v0.7.0/cards/card_skill_whispered_hunch.png` | 512×400 | 灵性预感 |
| `card.skill.mirrored_memory` | `art/assets/svg/v0.7.0/cards/card_skill_mirrored_memory.svg` | `assets/game/v0.7.0/cards/card_skill_mirrored_memory.png` | 512×400 | 镜中记忆 |
| `card.skill.fated_echo` | `art/assets/svg/v0.7.0/cards/card_skill_fated_echo.svg` | `assets/game/v0.7.0/cards/card_skill_fated_echo.png` | 512×400 | 命运回声 |
| `card.skill.piercing_omen` | `art/assets/svg/v0.7.0/cards/card_skill_piercing_omen.svg` | `assets/game/v0.7.0/cards/card_skill_piercing_omen.png` | 512×400 | 穿刺凶兆 |
| `card.skill.coffin_nail` | `art/assets/svg/v0.7.0/cards/card_skill_coffin_nail.svg` | `assets/game/v0.7.0/cards/card_skill_coffin_nail.png` | 512×400 | 棺钉 |
| `card.skill.second_sight` | `art/assets/svg/v0.7.0/cards/card_skill_second_sight.svg` | `assets/game/v0.7.0/cards/card_skill_second_sight.png` | 512×400 | 第二视觉 |
| `scene.deck.archive` | `art/assets/svg/v0.7.0/scenes/deck_archive.svg` | `assets/game/v0.7.0/scenes/deck_archive.png` | 1600×900 | 卡组编辑与收藏背景 |
| `challenge.mode.broken_procession` | `art/assets/svg/v0.7.0/icons/challenge_broken_procession.svg` | `assets/game/v0.7.0/icons/challenge_broken_procession.png` | 256×256 | 第二挑战徽记 |
| `challenge.modifier.obituary_echo` | `art/assets/svg/v0.7.0/icons/modifier_obituary_echo.svg` | `assets/game/v0.7.0/icons/modifier_obituary_echo.png` | 128×128 | 讣告回声 |
| `challenge.modifier.twin_shadow` | `art/assets/svg/v0.7.0/icons/modifier_twin_shadow.svg` | `assets/game/v0.7.0/icons/modifier_twin_shadow.png` | 128×128 | 双影同行 |
| `challenge.modifier.ritual_vigil` | `art/assets/svg/v0.7.0/icons/modifier_ritual_vigil.svg` | `assets/game/v0.7.0/icons/modifier_ritual_vigil.png` | 128×128 | 通宵守仪 |
| `route.variant.overridden_node` | `art/assets/svg/v0.7.0/icons/route_overridden_node.svg` | `assets/game/v0.7.0/icons/route_overridden_node.png` | 128×128 | 数据覆盖路线节点 |

审稿拼图：`assets/game/v0.7.0/contact-sheet.png`。HTML 预览：`art/preview/v0.7.0/index.html`。

## v0.13.0 卡池扩展

以下资产由 `art/tools/generate_v013_cards.mjs` 生成 SVG，并由 `art/tools/render_v013_cards.gd` 渲染为 512×400 PNG。用于收藏、牌组编辑、抽卡与战斗手牌。

| 稳定 ID | SVG 源 | PNG | 尺寸 | 用途 |
|---|---|---|---:|---|
| `card.skill.dream_question` | `art/assets/svg/v0.13.0/cards/card_skill_dream_question.svg` | `assets/game/v0.13.0/cards/card_skill_dream_question.png` | 512×400 | 梦问 |
| `card.skill.mirror_ward` | `art/assets/svg/v0.13.0/cards/card_skill_mirror_ward.svg` | `assets/game/v0.13.0/cards/card_skill_mirror_ward.png` | 512×400 | 镜面替身 |
| `card.skill.severed_string` | `art/assets/svg/v0.13.0/cards/card_skill_severed_string.svg` | `assets/game/v0.13.0/cards/card_skill_severed_string.png` | 512×400 | 断线 |
| `card.skill.last_rites` | `art/assets/svg/v0.13.0/cards/card_skill_last_rites.svg` | `assets/game/v0.13.0/cards/card_skill_last_rites.png` | 512×400 | 临终圣礼 |

## 计划资产

| 批次 | 内容 | 优先级 |
|---|---|---|
| A | 卡牌背面、常规/稀有/禁忌三种卡框 | 高 |
| B | 剩余 3-5 张人格牌 | 高 |
| C | 8 张普通灵界回响牌 | 候选完成并经 UI 实际界面复审通过 |
| D | 3 个封印物牌与独立裁切插画 | 中 |
| E | 5 个普通敌人与 1 个首领 | v0.3.0 的 3 个普通敌人和 v0.5.0 首领已完成候选 |
| F | 白昼安全屋、夜间街区两张背景 | 夜间战斗背景已完成候选 |

## 来源规则

- 当前 SVG：原创程序化图形，项目内生成。
- 后续 AI 资产：在表格中记录生成日期、模型/模式、最终提示词和文件路径。
- 公版图像：记录来源 URL、作者、馆藏编号和授权说明。
- 开放素材：记录作者、素材包名称、授权和下载日期。
- 不使用搜索引擎缓存、无水印网站或官方小说图片作为最终资产。

## v0.24.0 美术抛光覆盖

v0.24.0 在不改变稳定 ID、构图和运行时语义的前提下，为现有 87 个 SVG 资产增加统一的纸张纹理、铜版线、暗角、套印边缘和图标定位线。候选源位于 `art/assets/svg/v0.24.0/**`，正式 PNG 位于 `assets/game/v0.24.0/**`，运行时只引用后者。

| 项目 | 记录 |
|---|---|
| 生成脚本 | `art/tools/generate_v024_art_polish.mjs` |
| 生成方式 | 项目内 SVG 程序化抛光层；保留既有构图与稳定 ID |
| 正式清单 | `assets/game/v0.24.0/render-manifest.json` |
| 审稿拼图 | `assets/game/v0.24.0/contact-sheet.png` |
| 来源与授权 | 仅使用项目内原创 SVG，不含第三方图片、文字、水印或外部下载 |
| 运行时迁移 | 主协调者受控迁移；UI 目录已切换到 `res://assets/game/v0.24.0/**` |

## v0.41.0 序列 8「小丑」卡面

按 `docs/design/ART_BRIEF_V041.md` 冻结的 8 个稳定 ID 补齐正式卡面。SVG 候选与 PNG 正式件同后缀；UI 档案 / 抽卡 / 手牌同源。

| 稳定 ID | SVG 源 | PNG |
|---|---|---|
| `card.skill.veil_step` | `art/assets/svg/v0.41.0/cards/card_skill_veil_step.svg` | `assets/game/v0.41.0/cards/card_skill_veil_step.png` |
| `card.skill.severed_fate` | `art/assets/svg/v0.41.0/cards/card_skill_severed_fate.svg` | `assets/game/v0.41.0/cards/card_skill_severed_fate.png` |
| `card.skill.paper_swarm` | `art/assets/svg/v0.41.0/cards/card_skill_paper_swarm.svg` | `assets/game/v0.41.0/cards/card_skill_paper_swarm.png` |
| `card.skill.mirror_shard` | `art/assets/svg/v0.41.0/cards/card_skill_mirror_shard.svg` | `assets/game/v0.41.0/cards/card_skill_mirror_shard.png` |
| `card.skill.last_witness` | `art/assets/svg/v0.41.0/cards/card_skill_last_witness.svg` | `assets/game/v0.41.0/cards/card_skill_last_witness.png` |
| `card.skill.false_death` | `art/assets/svg/v0.41.0/cards/card_skill_false_death.svg` | `assets/game/v0.41.0/cards/card_skill_false_death.png` |
| `card.skill.sealed_answer` | `art/assets/svg/v0.41.0/cards/card_skill_sealed_answer.svg` | `assets/game/v0.41.0/cards/card_skill_sealed_answer.png` |
| `card.skill.hollow_bell` | `art/assets/svg/v0.41.0/cards/card_skill_hollow_bell.svg` | `assets/game/v0.41.0/cards/card_skill_hollow_bell.png` |

| 项目 | 记录 |
|---|---|
| 生成脚本 | `art/tools/generate_v041_clown_cards.mjs` |
| 导出脚本 | `art/tools/render_v041_clown_cards.gd`（需先 `--import`） |
| 尺寸 | 512×400，无烘焙文字 |
| 来源 | 项目内程序化 SVG，铜版/纸张语言对齐 v0.7/v0.13 |

## v0.42.0 缺口技能卡（12）

| 项目 | 记录 |
|---|---|
| 契约 | `docs/design/ART_BRIEF_V042.md` |
| 生成 | `art/tools/generate_v042_gap_cards.mjs` |
| 导出 | `art/tools/render_v042_gap_cards.gd` |
| 正式 PNG | `assets/game/v0.42.0/cards/`（12 × 512×400） |
| 覆盖 | 此前回退卡背的 12 张序列 9 技能卡；至此 40 张技能卡均有正式面 |

## v0.44.0 廷根场景 P0（5）

| 稳定 ID | PNG |
|---|---|
| `scene.battle.tyrell_warehouse` | `assets/game/v0.44.0/scenes/battle-tyrell-warehouse.png` |
| `scene.battle.blackthorn_neil` | `assets/game/v0.44.0/scenes/battle-blackthorn-neil.png` |
| `scene.battle.lamud_chapel` | `assets/game/v0.44.0/scenes/battle-lamud-chapel.png` |
| `scene.rest.divination_club` | `assets/game/v0.44.0/scenes/rest-divination-club.png` |
| `scene.ritual.clown_ascension` | `assets/game/v0.44.0/scenes/ritual-clown-ascension.png` |

生成：`art/tools/generate_v044_p0_scenes.mjs`；导出：`render_v044_p0_scenes.gd`；尺寸 1600×900。

## v0.45.0 廷根场景 P1（3）

| 稳定 ID | PNG |
|---|---|
| `scene.battle.moretti_home` | `assets/game/v0.45.0/scenes/battle-moretti-home.png` |
| `scene.battle.elliot_ruin` | `assets/game/v0.45.0/scenes/battle-elliot-ruin.png` |
| `scene.battle.wood_house` | `assets/game/v0.45.0/scenes/battle-wood-house.png` |

生成：`art/tools/generate_v045_p1_scenes.mjs`；导出：`render_v045_p1_scenes.gd`。

## v0.46.0 廷根场景 P2（3）

| 稳定 ID | PNG |
|---|---|
| `scene.battle.megose_descent` | `assets/game/v0.46.0/scenes/battle-megose-descent.png` |
| `scene.rest.chanis_gate` | `assets/game/v0.46.0/scenes/rest-chanis-gate.png` |
| `scene.ritual.above_fog` | `assets/game/v0.46.0/scenes/ritual-above-fog.png` |

生成：`art/tools/generate_v046_p2_scenes.mjs`；导出：`render_v046_p2_scenes.gd`；尺寸 1600×900。

## v0.47.0 廷根场景 P3 系统壳（4）

| 稳定 ID | PNG |
|---|---|
| `scene.title.mask_desk` | `assets/game/v0.47.0/scenes/title-mask-desk.png` |
| `scene.hub.route_map` | `assets/game/v0.47.0/scenes/hub-route-map.png` |
| `scene.hub.deck_archive` | `assets/game/v0.47.0/scenes/hub-deck-archive.png` |
| `scene.hub.gacha_altar` | `assets/game/v0.47.0/scenes/hub-gacha-altar.png` |

生成：`art/tools/generate_v047_p3_scenes.mjs`；导出：`render_v047_p3_scenes.gd`；尺寸 1600×900。

## v0.48.0 敌人与身份立绘（12）

| 稳定 ID | PNG |
|---|---|
| `enemy.candle_moth` | `assets/game/v0.48.0/enemies/enemy-candle-moth.png` |
| `enemy.tingen.kidnapper` | `assets/game/v0.48.0/enemies/enemy-tingen-kidnapper.png` |
| `enemy.mirror_hound` | `assets/game/v0.48.0/enemies/enemy-mirror-hound.png` |
| `enemy.mirror_hound_echo` | `assets/game/v0.48.0/enemies/enemy-mirror-hound-echo.png` |
| `enemy.weeping_tenant` | `assets/game/v0.48.0/enemies/enemy-weeping-tenant.png` |
| `enemy.tingen.knight_wraith` | `assets/game/v0.48.0/enemies/enemy-tingen-knight-wraith.png` |
| `enemy.tingen.rampager` | `assets/game/v0.48.0/enemies/enemy-tingen-rampager.png` |
| `enemy.mirror_baron` | `assets/game/v0.48.0/enemies/enemy-mirror-baron.png` |
| `enemy.tingen.megose` | `assets/game/v0.48.0/enemies/enemy-tingen-megose.png` |
| `identity.reporter` | `assets/game/v0.48.0/identities/card-identity-reporter.png` |
| `identity.doctor` | `assets/game/v0.48.0/identities/card-identity-doctor.png` |
| `identity.gravedigger` | `assets/game/v0.48.0/identities/card-identity-gravedigger.png` |

生成：`art/tools/generate_v048_enemy_identity_art.mjs`；导出：`render_v048_enemy_identity_art.gd`。

## v0.49.0 系统壳补绘 P4（6）

| 稳定 ID | PNG |
|---|---|
| `scene.hub.reward_archive` | `assets/game/v0.49.0/scenes/hub-reward-archive.png` |
| `scene.hub.challenge_board` | `assets/game/v0.49.0/scenes/hub-challenge-board.png` |
| `scene.hub.challenge_result` | `assets/game/v0.49.0/scenes/hub-challenge-result.png` |
| `scene.hub.rest_blackthorn` | `assets/game/v0.49.0/scenes/hub-rest-blackthorn.png` |
| `scene.ritual.obituary` | `assets/game/v0.49.0/scenes/ritual-obituary.png` |
| `scene.ritual.ascension` | `assets/game/v0.49.0/scenes/ritual-ascension.png` |

生成：`art/tools/generate_v049_shell_scenes.mjs`；导出：`render_v049_shell_scenes.gd`；尺寸 1600×900。


## v0.85.0 日记美术与字体（实施中）

- 正式规格：`docs/design/ART_BRIEF_V085.md`。
- 插画正式路径：`assets/game/v0.85.0/diary/`，与战斗横幅分离；13 项栅格资产清单见 `art/production/v0.85.0/asset_manifest.json`。当前尚未生成，回退旧图不算交付。
- AI 出图已获用户授权。使用 imagegen 标准 CLI / gpt-image-2；13 项请求已 dry-run 校验，尚未发起付费请求。需本机 API 凭据。原始输出、处理记录、哈希和 UI 审稿完成后才可登记为正式素材。AI 图片不得冒记为 OFL/CC0。
- 思源宋体：`assets/ui/fonts/SourceHanSerifSC-Regular.otf`，Adobe Source Han Serif SC Regular **2.003R**，完整上游简体字库，24,543,332 字节（23.41 MiB）。
- 来源：https://github.com/adobe-fonts/source-han-serif/blob/2.003R/OTF/SimplifiedChinese/SourceHanSerifSC-Regular.otf
- 字体 SHA-256：`78aa7a328fd974df2d688c8a9fd74a33d8334dfa84ab24d9d11efb2ffc464117`。
- 授权：**SIL OFL 1.1**，原文 `assets/ui/fonts/LICENSE-SourceHanSerif.txt`（Adobe 2017–2022 版权，保留字体名称 Source）。导出 include_filter 显式包含字体许可文本。
- 评审：产品经理与本地数据层分别在 `docs/reports/v0.85.0/` 记录；字体映射 44,779 字符，日记 JSON 的 378 种现有字符无缺字。
- 用途：日记题名与正文；现有 Noto Sans 保留给旁注、页脚及缺字回退。无存档变化、运行时网络或新运行库。更新时复核授权/哈希/字形；移除时回到 Noto Sans 并删除字体与导入元数据。

### 2026-11-23 用户确认的莫雷蒂家首叶

- 用户提供并确认采用雨夜插画，原件保留于 `art/assets/raster/v0.85.0/diary/battle-moretti-home-original.png`（1536×2048）。
- 运行时：`assets/game/v0.85.0/diary/battle-moretti-home.png`（1260×1770），居中适配画幅，左右各裁约 2.54%，未改色；战斗横幅路径保留。
- 来源与处理哈希：`art/production/v0.85.0/moretti_source.json`。这是用户供图，不是本机 API 生成，不冒记为 CC0 / OFL。
- 其余七幅插画与五项纸纹、木纹、蜡封资源仍待交付；先前程序样稿仅保留为未采用预览。

### 2026-11-23 用户提供的桌面材质与烛台参考

- 原始纸纹、木纹均为 1536×2048，存放在 `art/assets/raster/v0.85.0/materials/`；烛台参考保存在 `art/assets/raster/v0.85.0/references/brass-candlestick-original.png`。
- 用户供图用于本项目，不声明为 CC0/OFL；烛台图仅用于造型参考，未冒充透明素材。
- `art/tools/prepare_v085_desk_materials.py` 可重复生成正式纸纹与木纹：中心裁为正方形，等比放大到 2048×2048，在外缘 160 像素内余弦交叉融合；不整体改色。原先纸纹占位已另存。
- 来源、裁切坐标、哈希及接缝测量见 `art/production/v0.85.0/desk_material_sources.json`。两幅对边像素差均为 0；2×2 预览未见硬接缝，木结重复仍属于平铺纹理固有限制。
- 运行时：`assets/ui/diary/parchment_grain.png`、`assets/ui/diary/desk_wood.png`。素材已接入样张，最终桌面呈现由 UI 审稿。
- 尚缺七幅叙事插画和三态蜡封。本次不调用付费出图接口。

## v0.87 归档

v0.87.0 R1-05 / R1-06（AR-44、AR-45、AR-56）。以下文件已从 `main` 删除，历史完整保留在 git 标签 **`archive/pre-v0.87-assets`**（指向删除前提交 `dbdcdeac74468cb21d8fbfea3f25f908732dbebc`）。

| 路径 | 大小 | 文件数（不含 `.import`） | 删除理由 |
|---|---:|---:|---|
| `assets/game/v0.3.0/` | 4.3 MB | 27 | 无运行时 / 测试 / 工具 / uid 引用；现行副本在 `assets/game/v0.24.0/v0.3.0/` |
| `assets/game/v0.4.0/` | 1.8 MB | 13 | 同上（现行 `v0.24.0/v0.4.0/`） |
| `assets/game/v0.5.0/` | 3.6 MB | 14 | 同上（现行 `v0.24.0/v0.5.0/`） |
| `assets/game/v0.6.0/` | 0.9 MB | 14 | 同上（现行 `v0.24.0/v0.6.0/`） |
| `assets/game/v0.7.0/` | 3.1 MB | 16 | 同上（现行 `v0.24.0/v0.7.0/`） |
| `assets/game/cards/` | 2.6 MB | 5 | 无引用（现行 `v0.24.0/cards/`、`v0.85.0/cards/`） |
| `assets/game/enemies/` | 0.2 MB | 1 | 无引用 |
| `assets/game/icons/` | 0.5 MB | 1 | 无引用 |
| `assets/game/templates/` | 0.5 MB | 1 | 无引用 |
| `data/schema/v0.2.0/content_envelope.schema.json` | <0.01 MB | 1 | 无任何引用（仅 README 提及） |

合计约 17.4 MB（`assets/` 由 158.2 MB 降到 140.8 MB，按 `du -sk` 计）。

恢复命令：

```bash
git fetch origin tag archive/pre-v0.87-assets   # 标签已推送时
git checkout archive/pre-v0.87-assets -- <path>
# 例：git checkout archive/pre-v0.87-assets -- assets/game/v0.3.0
```

本轮保留（审查列为候选但仍有引用）：

- `assets/game/{scenes,v0.13.0,v0.47.0,v0.49.0}/`：`art/tools/render_title_svg.gd`、`render_v013_cards.gd`、`render_v047_p3_scenes.gd`、`render_v049_shell_scenes.gd` 及对应 `.mjs` 以其为输出目录；按保守规则整目录保留，待美术确认后可归档。
- 逐字节重复：`assets/ui/diary/desk_wood.png` = `props/desk-wood.png`、`wax_seal_available.png` = `props/wax-seal.png`（`props/` 经 `prop_ui_catalog.gd` 的 `PROP_DIR` 动态引用）；`assets/game/v0.24.0/cards/card-identity-reporter.png` = `templates/card-frame.png`（后者登记在 `v0.24.0/render-manifest.json`）。两份均有引用，均保留。`assets/game/v0.85.0` 与 `art/**` 的重复不在本轮范围（不动 `art/**`）。
- `data/balance/v0.2.0/balance_draft.json`、`data/schema/v0.2.0/battle_cards.schema.json`：仍被 `tests/infrastructure/test_runner.gd` 读取，保留。
