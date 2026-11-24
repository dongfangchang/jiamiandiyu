# 道具/素材接入管线（PROP_PIPELINE）

> 目的：让「新画一张图」到「出现在游戏里」变成**改一行清单 + 放一个文件 + 跑一条命令**，
> 不需要改代码、不需要找散落的硬编码路径。
> 建立于 v0.85 接入 `art/assets/raster/v0.85.0/props/` 时。

---

## 1. 为什么需要这层

生成的美术是 **RGB + 深炭底**（便于抠图），而 UI 需要 **RGBA 透明**素材。
中间这步若手工做，每来一批图就要重做一次，且容易漏。
本管线把「抠图 / 裁边 / 派生状态色 / 运行时查找 / 缺图降级」固定下来。

```
art/assets/raster/<ver>/props/*.png      ← 美术交付（RGB，深炭或浅底）
        │
        │  props.manifest.json           ← 唯一需要人编辑的文件
        ▼
art/tools/key_props.gd                   ← 抠图 / 羽化 / 裁边 / 派生变体
        │
        ▼
assets/ui/diary/props/*.png              ← RGBA 成品（+ also_out 指定的额外路径）
        │
        │  src/ui/prop_ui_catalog.gd      ← 运行时查找（缺图返回 null）
        ▼
src/ui/diary_desk_stage.gd 等            ← 有图用图，无图保留程序画法
```

---

## 2. 加一个新道具（3 步）

1. 把 PNG 放进 `art/assets/raster/<ver>/props/`。
2. 在 `props.manifest.json` 的 `props[]` 加一行：
   ```json
   {"id": "my_prop", "src": "prop-my-thing.png", "key": "flood_dark",
    "tolerance": 0.18, "feather": 2, "trim": true, "pad": 6, "out": "my-thing.png"}
   ```
3. 跑：
   ```bash
   "$GODOT" --headless --path . --script art/tools/key_props.gd
   ```
   输出每张的尺寸与落点，末行 `KEY_PROPS_OK count=N`。

若该道具要被代码按 id 取用，再在 `prop_ui_catalog.gd` 的 `PROPS` 加一行映射
（只有**全新种类**才需要；替换同名素材不用动代码）。

### 字段说明

| 字段 | 含义 |
|---|---|
| `key` | `flood_dark` 扣深色底 / `flood_light` 扣浅色底 / `none` 整幅材质不抠 |
| `tolerance` | 与背景采样色的最大通道差阈值（0–1），越大扣得越狠 |
| `feather` | 边缘羽化像素，消锯齿 |
| `trim` + `pad` | 裁掉透明边并留 pad 像素余量 |
| `out` | 输出到 `output_dir` 下的文件名 |
| `also_out` | 额外输出的**完整 res:// 路径**，用于喂已写死路径的旧代码 |
| `variants` | 从同一张源图派生多个着色版本（见 §3） |

### 抠图为什么用洪水填充而不是阈值

这些道具内部**本来就有深色**（蜡封的暗红阴影、印章的黑色嵌纹）。
全局亮度阈值会把主体打出洞。本工具改为**从图像边界洪水填充**：
只有与边界连通、且与背景采样色接近的像素才被清除，内部深色保持不透明。

距离用**最大通道差**而非平均值：暗红蜡封 vs 炭黑底在红通道差异明显、
绿蓝通道几乎无差，取平均会被稀释到阈值以下，导致整块主体被吃掉
（实测曾只剩 4.6% 不透明，修正后为 61.9%）。

---

## 3. 一图多态（variants）

蜡封需要「可启 / 已阅 / 墨封」三态，但没必要让美术画三遍。
在该道具下加 `variants`，由工具派生：

```json
"variants": [
  {"out": "res://assets/ui/diary/wax_seal_available.png", "tint": [1.0, 1.0, 1.0]},
  {"out": "res://assets/ui/diary/wax_seal_completed.png", "tint": [0.62, 0.52, 0.45]},
  {"out": "res://assets/ui/diary/wax_seal_locked.png",   "tint": [0.42, 0.40, 0.42], "desaturate": 0.8}
]
```

`tint` 为逐通道乘算，`desaturate` 为向灰度插值的比例。**alpha 始终保留**。

---

## 3.5 卡牌插画：第二条管线（约定优于配置）

卡牌走**独立管线**，连清单都不用改 —— **目录名就是卡牌 ID**。

```
art/assets/raster/<ver>/cards/<card.id>/art.png   ← 512×390 无字插画
        │   art/tools/ingest_cards.gd
        ▼
assets/game/<ver>/cards/<card.id>/art.png
        │   src/ui/card_art_catalog.gd
        ▼
battle_screen / deck_screen …
```

### 加一张新卡（2 步，零代码改动）

1. `data/cards/**` 加卡牌定义（含 `rarity`）—— 玩法/数据所有者负责
2. 建目录 `art/assets/raster/<ver>/cards/<card.id>/`，放入 `art.png`
3. 跑 `"$GODOT" --headless --path . --script art/tools/ingest_cards.gd`

**蜡封不用画**：`card_art_catalog.gd` 从卡牌自身的 `rarity` ×
（由 `effects`/`mechanic_tags` 推导的）机制标签，到 4×6 蜡封矩阵里取图。
矩阵已全齐，任何新组合都已覆盖。

**已实测**：临时加一张 `rarity=rare`、带 `damage` 效果的新卡 +
一个插画目录，未改任何代码 → 自动得到插画、判定为 `rare`/`attack`、
取到 `seal-rare-attack-128.png`，且 `v085_card_art_runner` 的检查数
从 170 自动增长到 174 覆盖了它。

### 机制推导顺序（为什么是这个顺序）

「这张卡是干什么用的」优先于「它附带什么效果」：

```
仪式标签/prepare_ritual → ritual
占卜类标签/reveal_*     → divination   （占卜道具即使 draw 也算占卜）
damage/damage_all       → attack
block                   → defense
heal/spirit/draw        → support      （带 risk 副作用的治疗仍是 support）
risk/lose_hp/discard    → curse
其余                     → support
```

**唯一定义源仍是 `data/cards/**`**，推导结果不落盘、不二次存储，
规则一改蜡封自动跟随。

### 迁移工具的守门行为

`ingest_cards.gd` 不是无脑复制：
- **插画无对应卡牌** → 直接失败（避免把死 ID 烘进 `assets/game`）
- **卡牌无插画** → 报 `gaps` 但不失败（允许分批交付）
- **尺寸非 512×390** → 报警告（卡框会缩放，但对不齐像素）

---

## 4. 加一个新章节 / 新插画

章节插画走的是**另一条**（已有）路径，不经过本管线：

1. 图放 `art/assets/raster/<ver>/diary/`（竖幅 1260×1770，见 `ART_BRIEF_V085_DRAFT.md` §1）。
2. 主协调者迁到 `assets/game/v0.85.0/diary/`，**文件名须匹配**
   `scene_ui_catalog.gd` 的 `DIARY_PATHS`。
3. 新增 scene_id 时，在 `DIARY_PATHS` 加一行映射。
4. 新章节的**文本**在 `data/diaries/<ver>/<volume>.json`（玩法/数据所有者维护），
   UI 侧的 `diary_ui_catalog.gd` 会自动按 `1 main clue = 1 开` 展开，无需改 UI。

**验收必须逐张确认**：`diary_path_for()` 缺图时**静默回落**到旧场景图、不报错。
用 `SceneCatalog.has_diary_art(scene_id)` 核对，
不能以「界面没报错」判定交付完成。

---

## 5. 缺图降级（框架保证）

`prop_ui_catalog.gd` 的 `texture()` 在素材缺失时返回 `null`，
所有调用点都必须保留程序画法作为 fallback。

**已验证**：把 `assets/ui/diary/props/` 整个移走后，
`V083=21`、`V055=59` 仍全绿 —— 缺素材不会导致崩溃或探针失败，
只是回到程序观感。

用 `PropCatalog.missing()` 可列出未交付的 id，供报告与探针使用。

---

## 6. 现有道具清单（v0.85）

| id | 用途 | 接入点 |
|---|---|---|
| `desk_wood` | 桌面木纹 | DeskMesh 材质（并 `also_out` 到 `desk_wood.png`）|
| `parchment_sheet` | 书页纸张 | 左右页背景（左页镜像）|
| `wax_seal` | 蜡封 | 右页进关按钮，派生三态 |
| `token_available/failed/silence/archive` | 状态印四枚 | 右页符文栏 |
| `bookmark` | 书签缎带 | `_prop_sprite` 平铺于订口（缺图回落 BoxMesh）|
| `candle` | 烛台 | `_build_candle()`（缺图回落车削网格 `_build_candlestick_mesh()`）|
| `inkwell` / `quill_pen` | 墨水瓶 / 羽笔 | `_prop_sprite`（缺图回落 `_build_desk_tools_mesh()`）|
| `corner_ornament` | 页角花饰 | 待接（标题框）|
| `open_journal` | 整本日记 | 参考用，当前书由程序搭建 |

### 立起来的道具：`_prop_sprite()`

桌面道具用 `Sprite3D` 立在桌上，不是贴在桌面上。两个要点：

- **不要跟随相机俯仰**。曾让 sprite 绕 X 轴转 `CAMERA_PITCH_DEG`，
  结果画好的脚底被推离接触点约**高度的 32%**，道具全部悬空。
  正确做法是**保持竖直**：画面里的透视由相机负责，画本身已经画好了立体感。
- **pivot 放在底边**（`offset.y = 高度/2`），这样无论像素尺寸多少，
  道具都站在给定的接触点上。

`alpha_cut = ALPHA_CUT_DISCARD` 而非混合，确保道具能投出真实阴影、
且不会与书产生排序问题。

### 摆位要用实测，不要猜

当前取景下，只有 `|x|≈0.85` 且 `z≈-0.15` 的区域既在画面内、又不被书遮挡。
这是用 `Camera3D.unproject_position()` 逐点投影测出来的，不是估的。
改取景后必须重测——接入本批素材时就因此调过三轮。

---

## 7. 注意事项

- `.import` 文件由 Godot 生成，**首次新增 PNG 后需跑一次** `--headless --path . --import`，
  否则 `ResourceLoader.exists()` 为假、素材看起来像没交付。
- 本管线输出到 `assets/ui/diary/props/`（UI 素材）。
  **章节插画**属 `assets/game/**`，由主协调者迁移，不要混用。
- 工具是幂等的：重跑会覆盖输出，不会累积。
- 源图保留在 `art/`，**不要删**——调参数需要重新抠图。
- **不要连 `.import` 一起复制图片**。`.import` 里带 `uid=`，复制后多张图共用
  同一个 UID，Godot 会把它们解析成**同一个资源** —— 画面上看起来「交付了」，
  实际渲染出来的是另一张图。导入时只是 WARNING，极易漏过。
  **正确做法**：只复制 `.png`，让 Godot 自己生成 `.import`。
  已中招时：删掉这批 `.import` 再跑一次 `--import` 即可重建唯一 UID。
  `v085_props_runner` 已内置全仓 UID 唯一性检查（实测可抓到植入的重复）。
- **深色道具要调低容差**。默认 0.18 适合浅色主体；墨水瓶（深铜）在 0.18 下
  只剩 17.8% 不透明（瓶身被当背景吃掉），降到 0.05 后恢复到 48.4%。
  现清单中 inkwell=0.05 / candle=0.07 / quill=0.09 / bookmark=0.10。
  **判断方法**：抠完看不透明占比，明显低于主体应占的画面比例就是抠过头了。
