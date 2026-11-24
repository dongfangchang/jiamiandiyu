# 日记左页开页插画（v0.85）

规格：`docs/design/ART_BRIEF_V085.md` — **1260 × 1770**，无框、无字、无纸纹叠绘。

正式运行路径：`assets/game/v0.85.0/diary/<同名>.png`（本目录为美术源；已同步一份到正式路径）。

| 文件 | scene_id | 节点 |
|---|---|---|
| `battle-moretti-home` | `scene.battle.moretti_home` | 密修会的闯入者 |
| `battle-elliot-ruin` | `scene.battle.elliot_ruin` | 艾略特绑架案 |
| `battle-tyrell-warehouse` | `scene.battle.tyrell_warehouse` | 提利尔仓库 |
| `battle-wood-house` | `scene.battle.wood_house` | 伍德家的恶灵 |
| `rest-divination-club` | `scene.rest.divination_club` | 占卜俱乐部 |
| `battle-lamud-chapel` | `scene.battle.lamud_chapel` | 拉姆德小镇驱邪 |
| `battle-blackthorn-neil` | `scene.battle.blackthorn_neil` | 失控的老尼尔 |
| `ritual-clown-ascension` | `scene.ritual.clown_ascension` | 晋升：小丑 |

验收：`SceneCatalog.has_diary_art(scene_id)` 八开均为 true；真窗口左页不再回落 16:9。
