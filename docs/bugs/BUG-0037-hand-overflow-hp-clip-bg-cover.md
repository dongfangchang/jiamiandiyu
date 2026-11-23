# BUG-0037：第七张手牌越框 / 血条裁切 / 底部场景被盖死

- 日期：2026-11-18
- 严重度：S2（可读性 / 操作可信度）
- 版本：v0.52.0
- 状态：已修复

## 症状

1. 满手（≥7）时第 7 张卡画出金色手牌框。
2. 顶栏生命/灵性等 ProgressBar 被裁切或看不见。
3. 各界面底部场景图层（桌面/街道）完全被不透明底栏盖住。

## 根因

1. `HandScroll.clip_contents = false`，多出来的牌横向画出 `HandPanel`。
2. `BattleHeader` 高 52px 且 `clip_contents`，而 `diegetic_meter` 最小高 56px。
3. 底栏/手牌面板 alpha≈0.96–0.99，加均匀 `SceneDim`，底部图案被压死。

## 修复

- 手牌框与滚动区重新裁切；卡宽 208、间距 8，约 7 张落入框内，其余横滚。
- 血条改为双行紧凑表头；顶栏抬到 60px；敌人道具艺术高度封顶，避免顶掉生命行。
- `SceneDim` 改为纵向渐变（底端几乎透明）；底栏/手牌用 frosted alpha；安全区 `SAFE_BOTTOM_REVEAL`。

## 回归

- `V052_FRAME_HP_BG_OK`
- `V051_HAND_CLIP_PROBE_OK` / `V050_UI_OK` / `V014_CARD_LAYOUT_OK`
