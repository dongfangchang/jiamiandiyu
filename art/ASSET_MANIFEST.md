# 美术资产清单

所有当前资产均为项目内生成的可编辑 SVG 占位美术，无第三方图片来源。它们可以用于私人原型的视觉验收与 Godot 集成。

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

