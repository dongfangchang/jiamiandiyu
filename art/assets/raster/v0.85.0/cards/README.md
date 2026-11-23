# 卡牌插画窗（v0.85 重绘）

规范：`art/README.md` §0 — 仅交 **512×390** 无字插画；卡框/蜡封/UI 字另层。

路径：`art/assets/raster/v0.85.0/cards/<card.id>/art.png`  
源图备份：同目录 `art_source.jpg`  
总览：`../card-framework/cards-art-contact-sheet.png`

## 五批（各 8 张 · 已齐）

| 批 | 主题 | 张数 |
|---|---|---|
| 1 | 仪式核心 | 8 |
| 2 | 射击/近战/训练 | 8 |
| 3 | 占卜/情报 | 8 |
| 4 | 小丑包 + 盟友 | 8 |
| 5 | 封印物 | 8 |

## 清单

### 批 1 仪式核心
- `card.skill.paper_guard` 灵性之墙
- `card.skill.borrowed_breath` 圣夜粉
- `card.skill.coffin_nail` 银质匕首
- `card.skill.candle_archive` 以灵性点燃烛芯
- `card.skill.warding_circle` 驱邪仪式
- `card.skill.whispered_hunch` 通灵
- `card.skill.midnight_ledger` 老尼尔的神秘学课
- `card.skill.calm_breath` 平复灵性

### 批 2 射击/近战/训练
- `card.skill.ink_dart` 左轮手枪
- `card.skill.piercing_omen` 猎魔子弹
- `card.skill.omen` 格斗训练
- `card.skill.focus` 冥想
- `card.skill.veil_step` 身体控制与平衡
- `card.skill.mirror_shard` 闪身反击
- `card.skill.severed_fate` 预判下一步
- `card.skill.hollow_bell` 飞牌

### 批 3 占卜/情报
- `card.skill.insight` 黄水晶灵摆
- `card.skill.second_look` 灵视
- `card.skill.fated_echo` 塔罗占卜
- `card.skill.dream_question` 梦境占卜
- `card.skill.mirror_ward` 魔镜占卜
- `card.skill.echo_reading` 占卜俱乐部的解读
- `card.skill.glass_thesis` 塔罗会：情报交换
- `card.skill.lantern_step` 查尼斯门值守

### 批 4 小丑 + 盟友
- `card.skill.paper_swarm` 纸牌连掷
- `card.skill.closed_eye` 危险预感
- `card.skill.false_death` 小丑的危险预感
- `card.skill.last_witness` 小丑的微笑
- `card.skill.second_sight` 灰雾之上
- `card.skill.whisper` 伦纳德：午夜诗人
- `card.skill.last_rites` 邓恩：圣赛琳娜骨灰
- `card.skill.omen_chorus` 邓恩：梦魇

### 批 5 封印物
- `card.skill.mirrored_memory` 安提哥努斯家族笔记
- `card.skill.severed_string` 2-049 安提哥努斯木偶
- `card.skill.ink_scarlet` 2-105 血管小偷
- `card.skill.hungry_symbol` 3-0625 厄运布偶
- `card.skill.black_thread` 3-0611 安静发丝
- `card.skill.eclipse` 阳炎符咒
- `card.skill.red_corridor` 3-0782 太阳圣徽
- `card.skill.sealed_answer` 阿兹克铜哨

## 下游

- 正式迁入 `assets/game/`：主协调者
- 蜡封矩阵：`../seals/`（G-01）
- 检视弹层短句：UI（G-03）
