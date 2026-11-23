# 廷根场景设计契约（v0.43 冻结）

> 本文件冻结**场景稳定 ID、用途、原著地点、安全区与绘制优先级**。  
> v0.43 **只设计不画图**；正式 PNG 留待后续版本（建议 v0.44）按本表执行。  
> 禁止在立绘期间改场景 ID、改玩法规则或另起一套地点名。

## 1. 原则（防割裂）

1. 每个可切换背景有唯一 `scene.*` 稳定 ID；UI 只通过 catalog 路径引用，不硬编码新故事名。
2. 系统屏（标题/档案/祈愿等）与叙事地点（战斗/休整/仪式）分两层：前者是桌面壳，后者是原著地点。
3. 背景 **1600×900**；中央信息安全区约 **320–1280 × 120–780**，不烘焙中文 UI 文案。
4. 视觉语言：廷根·黑夜女神暗金 / 旧纸 / 墨黑铜版线，与卡面一致；战斗场略暗、档案场略亮。
5. 当前战斗一律 `battle-tingen-old-house` 是**已知占位**；下版按节点 `scene_id` 切换，玩法不计算美术。

## 2. 系统场景（已有资源 · 保留 ID）

| 稳定 ID | 用途（UI 屏） | 现行路径（v0.24 活动集） | 气质 |
|---|---|---|---|
| `scene.title.mask_desk` | 开始页 / 身份选择壳 | `…/scenes/title-screen.png` | 假面桌面、蜡封、烛光 |
| `scene.hub.route_map` | 路线选择 / 路线图 / 部分结算 | `…/v0.5.0/scenes/route-map.png` | 廷根街道鸟瞰式档案图 |
| `scene.hub.deck_archive` | 牌组档案 | `…/v0.7.0/scenes/deck_archive.png` | 蜡封档案柜 |
| `scene.hub.gacha_altar` | 灵界祈愿 | `…/v0.4.0/scenes/gacha-altar.png` | 灰雾/祭坛抽卡 |
| `scene.hub.reward_archive` | 战后奖励 / 升级 | `…/v0.4.0/scenes/reward-archive.png` | 奖励匣 |
| `scene.hub.challenge_board` | 挑战 hub / 修饰 | `…/v0.6.0/scenes/challenge-selection.png` | 值夜者档案板 |
| `scene.hub.challenge_result` | 挑战结算 | `…/v0.6.0/scenes/challenge-result.png` | 结案戳记 |
| `scene.hub.rest_blackthorn` | 默认休整（黑荆棘旧宅感） | `…/v0.5.0/scenes/rest-old-house.png` | 值夜者休息室 |
| `scene.ritual.obituary` | 转运/篡改讣告仪式壳 | `…/v0.5.0/scenes/ritual-tampered-obituary.png` | 仪式桌 |
| `scene.ritual.ascension` | 晋升大仪式（备用） | `…/scenes/ritual-ascension.png` | 起誓/魔药 |
| `scene.battle.tingen_old_house` | **现行唯一战斗底**（占位） | `…/v0.3.0/scenes/battle-tingen-old-house.png` | 旧宅室内 |

> 系统场景本版不强制重绘；若重绘必须保留稳定 ID，并一次切换 catalog。

## 3. 主线叙事地点（第一卷·廷根 · 待画）

对应 `route.v028.first_stage` 与 `TINGEN_CANON` §7。  
**新增稳定 ID 自本文件冻结；下版美术只准用这些 ID。**

| 稳定 ID | 路线节点（语义） | 类型 | 原著地点 / 节拍 | 画面要点 |
|---|---|---|---|---|
| `scene.battle.moretti_home` | 密修会的闯入者 | battle | 莫雷蒂家深夜闯入 | 平民公寓、破窗/烛光、密修会阴影 |
| `scene.battle.elliot_ruin` | 艾略特绑架案 | battle | 废弃建筑救艾略特 | 废屋梁柱、绳索、昏黄街灯渗入 |
| `scene.battle.tyrell_warehouse` | 提利尔仓库 | battle | 瑞尔·比伯 → 燕尾服小丑 | 仓库木箱、2-049 木偶感、减速空气 |
| `scene.battle.wood_house` | 伍德家的恶灵 | battle | 生日宴魔镜占卜 | 客厅镜面、女孩宴后的不安灵气 |
| `scene.rest.divination_club` | 占卜俱乐部 | rest | 豪尔斯街扮演消化 | 俱乐部桌面、塔罗/灵摆、暖灯 |
| `scene.battle.lamud_chapel` | 拉姆德小镇驱邪 | battle | 黑色骑士铠甲怨魂 | 小镇教堂/墓地、铠甲剪影、圣徽微光 |
| `scene.battle.blackthorn_neil` | 失控的老尼尔 | boss | 黑荆棘安保公司 | 办公室异变、血肉炼成痕迹、压抑红黑 |
| `scene.ritual.clown_ascension` | 晋升：小丑 | ritual | 考核起誓 + 服用魔药 | 女神象征、魔药杯、小丑妆暗示（克制） |

挑战复用：

| 稳定 ID | 用途 | 说明 |
|---|---|---|
| `scene.battle.megose_descent` | 邪神子嗣降临（梅高欧丝） | 黑荆棘异变高潮；可与 `blackthorn_neil` 同楼异态变体 |
| `scene.rest.chanis_gate` | 查尼斯门值夜 | 挑战休整；封印物库门廊 |
| `scene.ritual.above_fog` | 灰雾之上的复苏 | 愚者灰雾；挑战仪式尾 |

## 4. 绘制优先级（下版执行顺序）

**P0（主线战斗可读）**

1. `scene.battle.tyrell_warehouse`
2. `scene.battle.blackthorn_neil`
3. `scene.battle.lamud_chapel`
4. `scene.rest.divination_club`
5. `scene.ritual.clown_ascension`

**P1（主线补齐）** — v0.45 已交付

6. `scene.battle.moretti_home` ✓
7. `scene.battle.elliot_ruin` ✓
8. `scene.battle.wood_house` ✓

**P2（挑战 / 变体）** — v0.46 已交付

9. `scene.battle.megose_descent` ✓
10. `scene.rest.chanis_gate` ✓
11. `scene.ritual.above_fog` ✓

**P3（系统壳抛光）** — v0.47 已交付

12. `scene.title.mask_desk` ✓
13. `scene.hub.route_map` ✓
14. `scene.hub.deck_archive` ✓
15. `scene.hub.gacha_altar` ✓

**P4（剩余系统壳）** — v0.49 已交付

16. `scene.hub.reward_archive` ✓
17. `scene.hub.challenge_board` ✓
18. `scene.hub.challenge_result` ✓
19. `scene.hub.rest_blackthorn` ✓
20. `scene.ritual.obituary` ✓
21. `scene.ritual.ascension` ✓

## 5. 接入约定（给下版工程）

1. 内容侧：路线/遭遇节点增加只读字段 `scene_id`（或 encounter 绑定）；缺省回退 `scene.battle.tingen_old_house`。
2. UI：`battle_screen` / `rest_screen` / `ritual_screen` 从快照读 `scene_id` → catalog 路径；**不**在 UI 写地点规则。
3. 美术：候选 `art/assets/svg/v0.44.0/scenes/**`；正式 `assets/game/v0.44.0/scenes/**`；尺寸 1600×900。
4. 同屏安全区：敌人立绘与手牌 HUD 不得被背景高对比色块切断（沿用 v0.24 暗角习惯）。

## 6. 明确不做

- 本版不提交新 PNG、不改 `project.godot` 玩法、不新增卡牌/敌人 ID。
- 不画魔术师序列场景、不画贝克兰德外省。
- 不把地点名写进存档主键；存档只存节点 ID。

## 7. 验收（设计门）

- [x] 系统场景与现行 UI 路径一一对应表完整
- [x] 主线 8 个叙事地点均有稳定 ID + 原著要点
- [x] P0–P2 优先级冻结，可供 v0.44 直接开工
- [x] v0.44 已按 P0 出图并接入 `scene_id`（见 `docs/versions/v0.44.0.md`）
