# 正式立绘契约（v0.48 · 敌人 + 身份）

> 以 `TINGEN_CANON.md` §6 与 `progression.json` 身份表为唯一故事源。  
> **禁止**新增敌人/身份 ID；立绘期间不改规则文案。

## 1. 原则

1. 每个 `enemy.*` / `identity.*` 一对一正式 PNG；禁止多敌共用同一占位图。
2. 敌人 **900×900**；身份卡 **512×640**；无烘焙中文。
3. 视觉：廷根暗金 / 旧纸 / 墨黑铜版，与卡面、场景一致。
4. 候选 `art/assets/svg/v0.48.0/**`；正式 `assets/game/v0.48.0/**`。

## 2. 敌人（9）

| 稳定 ID | 显示名 | 立绘要点 |
|---|---|---|
| `enemy.candle_moth` | 密修会成员 | 斗篷剪影、匕首、阴影潜入 |
| `enemy.tingen.kidnapper` | 绑匪 | 粗布帽、棍棒、码头匪徒 |
| `enemy.mirror_hound` | 失控的瑞尔·比伯 | 笔记诱惑失控、扭曲人形、污秽红眼 |
| `enemy.mirror_hound_echo` | 燕尾服小丑 | 燕尾服、高礼帽、魔术师气场 |
| `enemy.weeping_tenant` | 附身恶灵 | 半透明灵体、魔镜残影 |
| `enemy.tingen.knight_wraith` | 骑士怨魂 | 黑色铠甲剪影、锈剑、墓地冷光 |
| `enemy.tingen.rampager` | 失控的代罚者 | 货船失控者、撕裂体态 |
| `enemy.mirror_baron` | 失控的老尼尔 | 红眼、血肉炼成痕迹、办公室怪物 |
| `enemy.tingen.megose` | 梅高欧丝 | 白骨刀暗示、异变孕体、污秽高潮 |

## 3. 身份（3）

| 稳定 ID | 显示名 | 立绘要点 |
|---|---|---|
| `identity.reporter` | 占卜俱乐部会员 | 灵摆/塔罗桌、暖灯俱乐部 |
| `identity.doctor` | 值夜者文职人员 | 黑荆棘徽章、训练手套 |
| `identity.gravedigger` | 霍伊大学历史系毕业生 | 典籍、古文字残页 |

## 4. 验收

- [x] 九敌三身份各有独立 PNG
- [x] `battle_screen` / `progression_ui_catalog` 路径一对一
- [x] `V048_ART_OK`；不改规则/ID
