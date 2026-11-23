# 主界面（标题屏）美术生成提示词 — v0.85

> **设计前提**：主界面与日记屏**共用同一张桌子**（同一实木桌、同一盏烛、同一套布光）。
> 区别只在于：日记屏的书是**摊开**的，主界面的书是**合着**的。
> 玩家点开合着的日记 → 过场 → 摊开 → 进入章节。这样开场即有仪式感，且复用 DeskWorld。
>
> 交付到：`art/assets/raster/v0.85.0/title/`
> 抠图接入：在 `props.manifest.json` 加一行，跑 `art/tools/key_props.gd`（见 `docs/design/PROP_PIPELINE.md`）

---

## 0. 全局约束（每条提示词都要带，务必不要省）

这些是从**现网实测**反推的硬约束，不是风格偏好：

| 约束 | 原因 |
|---|---|
| **深炭灰纯色背景**（`#1a1a1a`–`#222`），主体居中、四周留白 | 管线靠边界洪水填充抠图；渐变/杂乱底会抠不干净 |
| **全图最亮处不超过 75% 亮度**，禁止纯白高光 | 实测参考图全图无任何像素 >0.75；现网超了就会显假 |
| **暖烛光，单一光源，从左上来** | 与现网 KeyLight（-48°, 35°）和烛位一致，否则贴进去光向会打架 |
| **不要画阴影投在背景上** | 阴影由引擎实时投，画上去会和实时阴影打架 |
| **不含任何文字、Logo、水印** | 文字一律由 Godot UI 绘制（`ART_DIRECTION.md` 规定）|
| **正交/平视角度，不要俯视** | 道具以 `Sprite3D` 竖直立在桌上；画成俯视会和相机角度冲突 |
| 色板：旧纸 `#D8C29A` / 深纸 `#AF9165` / 墨黑 `#211D18` / 暗金 `#B99750` / 蜡红 `#7A2828` / 冷雾 `#788079` | `ART_DIRECTION.md` 统一色板 |

**通用负面提示（negative prompt）**：
```
text, letters, watermark, logo, signature, white background, pure white highlights,
blown out, overexposed, neon, saturated colors, modern objects, plastic,
cast shadow on background, top-down view, multiple light sources, cartoon, flat vector
```

---

## 1. `title-journal-closed.png` — 合着的日记本【核心主体】

**用途**：主界面正中，点击 = 开始/继续游戏。1024×1024。

```
A closed antique leather-bound journal lying flat on a dark wooden desk,
viewed from a low three-quarter angle at eye level, warm candlelight from
the upper left, deep oxblood-red leather cover with worn edges and visible
grain, tarnished brass corner caps on all four corners, a dark red silk
ribbon bookmark trailing out from the page block, thick hand-cut page edges
slightly uneven and yellowed with age, a single dark red wax seal pressed
on the front cover keeping it shut, no text or lettering anywhere on the
cover, 19th century occult archive aesthetic, muted earth tones, deep
shadows, solid dark charcoal background #1a1a1a, centered composition with
generous empty margin around the object, photographic realism, subtle film
grain, nothing brighter than 75% luminance
```

**要点**：
- 封面上的蜡封是**完好未启**的（区别于日记屏里已启封的"进入"印）
- 书脊朝左、书签从右侧垂下，与日记屏摊开态的书签位置呼应
- **不要**在封面上画任何图案或文字——标题由 UI 绘制

---

## 2. `title-journal-new.png` — 未启封的新日记【开始新游戏】

**用途**：主界面副主体，点击 = 开始新游戏。1024×1024。

```
A brand new unopened leather journal on a dark wooden desk, same low
three-quarter eye-level angle, warm candlelight from upper left, deep
oxblood leather cover but noticeably cleaner and less worn than an old
book, crisp page edges, bound shut with a dark red wax seal that is fully
intact and unbroken, a thin leather cord wrapped once around the book,
no brass corner caps, no bookmark ribbon, no text or lettering, 19th
century occult aesthetic, muted earth tones, solid dark charcoal
background #1a1a1a, centered with empty margin, photographic realism,
nothing brighter than 75% luminance
```

**要点**：与 #1 的区别必须一眼可辨 —— **新书干净、有皮绳捆扎、无书签、无铜角**。

---

## 3. `title-dossier-stack.png` — 卷宗堆【挑战档案】

**用途**：桌角，点击 = 进入挑战档案。1024×1024。

```
A small stack of aged paper dossiers and folded documents tied with faded
red string, lying on a dark wooden desk, low three-quarter eye-level view,
warm candlelight from upper left, yellowed and foxed paper with soft
deckled edges, slightly askew stack of four or five folders, one corner
curled upward, a dark wax blob sealing the string, no text or writing on
any page, 19th century archive aesthetic, muted earth tones, solid dark
charcoal background #1a1a1a, centered with empty margin, photographic
realism, nothing brighter than 75% luminance
```

**要点**：**纸上不能有字**（哪怕模糊的）—— 有字会在缩小后变成噪点，且违反"文字由 UI 绘制"。

---

## 4. `title-pocket-watch.png` — 黄铜怀表【设置】

**用途**：桌角，点击 = 设置与玩法说明。1024×1024。

```
An antique open brass pocket watch lying on a dark wooden desk, low
three-quarter eye-level view, warm candlelight from upper left, tarnished
and aged brass case with fine engraving, the cover hinged open, visible
watch face with plain unmarked dial and delicate hands, a short brass
chain curling beside it, patina and small scratches, 19th century
aesthetic, muted earth tones, solid dark charcoal background #1a1a1a,
centered with empty margin, photographic realism, nothing brighter than
75% luminance
```

**要点**：表盘**不要刻度数字**（会变噪点）；指针可见即可。

---

## 5. `title-candle-snuffer.png` — 烛罩/灭烛器【退出】

**用途**：桌角，点击 = 退出（吹熄蜡烛 → 画面渐暗）。1024×1024。

```
An antique brass candle snuffer with a long handle lying on a dark wooden
desk, low three-quarter eye-level view, warm candlelight from upper left,
tarnished brass bell-shaped cone with a slender curved handle, soot marks
inside the cone, aged patina, 19th century aesthetic, muted earth tones,
solid dark charcoal background #1a1a1a, centered with empty margin,
photographic realism, nothing brighter than 75% luminance
```

---

## 6. `title-note-slip.png` — 便签【存档信息承载】

**用途**：夹在合着的日记里露出一角，上面由 **UI 绘制**身份/序列/牌组/上一场。1024×1024。

```
A small blank slip of aged parchment paper lying on a dark wooden desk,
low three-quarter eye-level view, warm candlelight from upper left,
yellowed paper with soft torn deckled edges and a faint horizontal fold
crease, completely blank with no writing or lines of any kind, slightly
curled corners, 19th century aesthetic, muted earth tones, solid dark
charcoal background #1a1a1a, centered with empty margin, photographic
realism, nothing brighter than 75% luminance
```

**要点**：**必须完全空白**（无横线、无字），UI 会在上面写字。
已有的 `prop-parchment-sheet` 也可直接复用，本张为可选的更小尺寸版本。

---

## 7. `title-desk-wide.png` — 整桌定场图【可选 · 备选方案】

**用途**：若不想用「3D 桌 + 立体道具」，可用这张整图做静态背景，UI 按钮叠在上面。
1920×1080（16:9，与标题屏视口一致）。

```
A dark wooden desk in a dim Victorian study at night, viewed from a low
three-quarter angle, a single lit candle in a brass holder on the left
casting warm light, a closed oxblood leather journal with brass corners
resting in the center, a small stack of tied paper dossiers at the right,
an antique brass pocket watch and an inkwell with a quill nearby, deep
shadows falling away into darkness at the edges, heavy atmospheric gloom,
19th century occult archive mood, muted earth tones, warm candlelight as
the only light source, photographic realism, subtle film grain,
nothing brighter than 75% luminance, no text anywhere
```

**要点**：这是**与方案 A 二选一**。
- 选 3D 道具（#1–#6）：可交互、可动画、随光照变化，但要摆位调试
- 选整图（#7）：一次到位、观感最稳，但道具不能单独高亮/响应
**我建议 #1–#6**，因为与日记屏共用 DeskWorld，风格必然统一。

---

## 8. 生成后怎么接入（3 步，无需改代码）

1. 图放 `art/assets/raster/v0.85.0/title/`
2. 在 `art/assets/raster/v0.85.0/props/props.manifest.json` 的 `props[]` 加行：
   ```json
   {"id": "title_journal_closed", "src": "../title/title-journal-closed.png",
    "key": "flood_dark", "tolerance": 0.12, "feather": 2, "trim": true,
    "pad": 6, "out": "title-journal-closed.png"}
   ```
   *深色道具（皮革/黄铜）容差建议 0.05–0.12；抠完检查不透明占比，
   明显低于主体应占比例就是抠过头了。*
3. 跑 `"$GODOT" --headless --path . --script art/tools/key_props.gd`

接入 UI 时再在 `src/ui/prop_ui_catalog.gd` 的 `PROPS` 加映射。

---

## 9. 验收标准

生成后逐张检查：

- [ ] 背景是**纯深炭灰**，没有渐变、没有桌面纹理混入（否则抠不干净）
- [ ] 主体**没有碰到画布边缘**（留白至少 10%）
- [ ] **没有任何文字**
- [ ] 最亮处不是纯白（眯眼看，高光应该是暖黄不是刺白）
- [ ] 光从**左上**来，与现网一致
- [ ] 背景上**没有投影**
- [ ] #1 与 #2 一眼能区分（旧书有铜角+书签，新书有皮绳、更干净）
