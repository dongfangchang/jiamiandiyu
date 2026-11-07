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
| `card.skill.ink_dart` | `art/assets/svg/v0.3.0/cards/card-skill-ink-dart.svg` | `assets/game/v0.3.0/cards/card-skill-ink-dart.png` | 512×400 | 无文字卡面 |
| `card.skill.paper_guard` | `art/assets/svg/v0.3.0/cards/card-skill-paper-guard.svg` | `assets/game/v0.3.0/cards/card-skill-paper-guard.png` | 512×400 | 无文字卡面 |
| `card.skill.calm_breath` | `art/assets/svg/v0.3.0/cards/card-skill-calm-breath.svg` | `assets/game/v0.3.0/cards/card-skill-calm-breath.png` | 512×400 | 无文字卡面 |
| `card.skill.focus` | `art/assets/svg/v0.3.0/cards/card-skill-focus.svg` | `assets/game/v0.3.0/cards/card-skill-focus.png` | 512×400 | 无文字卡面 |
| `card.skill.insight` | `art/assets/svg/v0.3.0/cards/card-skill-insight.svg` | `assets/game/v0.3.0/cards/card-skill-insight.png` | 512×400 | 无文字卡面 |
| `card.skill.omen` | `art/assets/svg/v0.3.0/cards/card-skill-omen.svg` | `assets/game/v0.3.0/cards/card-skill-omen.png` | 512×400 | 无文字卡面 |
| `card.skill.whisper` | `art/assets/svg/v0.3.0/cards/card-skill-whisper.svg` | `assets/game/v0.3.0/cards/card-skill-whisper.png` | 512×400 | 无文字卡面 |
| `card.skill.second_look` | `art/assets/svg/v0.3.0/cards/card-skill-second-look.svg` | `assets/game/v0.3.0/cards/card-skill-second-look.png` | 512×400 | 无文字卡面 |
| `status.*` | `art/assets/svg/v0.3.0/status/status-*.svg` | `assets/game/v0.3.0/status/status-*.png` | 64×64 | 12 个状态图标 |

评审拼图：`assets/game/v0.3.0/contact-sheet.png`。

迁移约定：主协调者应将正式候选 PNG 一次性迁入 `assets/game/**`，然后删除候选副本或把它们明确视为导出缓存；不得让 `assets/game/` 与正式引用同时保留两套长期可编辑副本。

## v0.4.0 短循环候选

以下资产根据 `docs/versions/v0.4.0.md` 制作，状态为“等待 UI 实际界面审稿”。美术只提交候选，不自行标记界面通过。

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

## 计划资产

| 批次 | 内容 | 优先级 |
|---|---|---|
| A | 卡牌背面、常规/稀有/禁忌三种卡框 | 高 |
| B | 剩余 3-5 张人格牌 | 高 |
| C | 8 张普通灵界回响牌 | 候选完成并经 UI 实际界面复审通过 |
| D | 3 个封印物牌与独立裁切插画 | 中 |
| E | 5 个普通敌人与 1 个首领 | v0.3.0 的 3 个普通敌人已完成候选 |
| F | 白昼安全屋、夜间街区两张背景 | 夜间战斗背景已完成候选 |

## 来源规则

- 当前 SVG：原创程序化图形，项目内生成。
- 后续 AI 资产：在表格中记录生成日期、模型/模式、最终提示词和文件路径。
- 公版图像：记录来源 URL、作者、馆藏编号和授权说明。
- 开放素材：记录作者、素材包名称、授权和下载日期。
- 不使用搜索引擎缓存、无水印网站或官方小说图片作为最终资产。

