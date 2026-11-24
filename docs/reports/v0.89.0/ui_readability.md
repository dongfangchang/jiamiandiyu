# v0.89.0 UI · P0-2 日记可读性（轨道 B）

```text
版本：v0.89.0
角色：UI（轨道 B，UI-P0-2）
任务：日记打开后字看不清 → 满足 EXPERIENCE §5.1 / ADR-0034 D3 全部可读性底线
状态：完成（§5.1 各行实测达标；用户真窗口确认待做）
修改文件：
  src/ui/diary_desk_stage.gd       世界视口按物理像素、阅读镜头、页面材质过滤、可读性探针接口
  src/ui/diary_page_pair.gd        PAGE_SCALE=2（页面 1024×1440）、字号 / 墨色 / 纸色常量、探针 getter
  src/ui/diary_reading_metrics.gd  新增：投影测量（屏上字号、阅读夹角、书宽占比、对比度）
  src/ui/diary_chapter_screen.gd   仅外框文字：卷名 / 载体行 / 底部提示 / 合上 / 批注改思源宋体并放大，删除空的叶号行
  tests/ui/diary_readability_runner.{gd,tscn}          新增，进默认测试集（41 项断言）
  tests/ui/diary_readability_capture_runner.{gd,tscn}  新增截图 runner（名字含 capture，不进默认集）
依赖：无跨角色交付物。未改 project.godot / 渲染器 / 规则 / 存档；黄金回放不变。
验证：tools/run_tests.sh pass=93 fail=0 skipped=11 guard_block=0（基线 92/0/10，多出的是新 runner）；
      H-02 diary_prepared_turn_runner 通过；diary_turn_capture_runner 目视翻页预加载正常。
```

## 1. 根因（复核）

| 原因 | 位置（改前） | 处理 |
|---|---|---|
| 世界视口按逻辑 1600×900 渲染，在 2920×1753 窗口上放大 1.825 倍 | `SubViewportContainer.stretch=true` 把视口锁在容器的逻辑尺寸 | 视口改为 `容器尺寸 × 最终画布缩放` 个物理像素，由一个普通 `TextureRect` 1:1 显示 |
| 页面视口 512×720 | `PAGE_VP_SIZE` | `PAGE_SCALE = 2.0`，页面 1024×1440；页内所有位置、尺寸、圆角、描边、字号统一走 `px()` |
| 字号太小（注脚 16、叶号 18） | 页内字面量 | 基准字号常量化：题名 36、正文 28、注脚 20（页面像素 ×2） |
| 镜头俯角 −59°，页面被压扁 | `DeskCamera` | 长焦俯视：俯角 −75°、距离 3.0 m、fov 23°，构图与原来一致 |

## 2. §5.1 清单（实测）

测量方法：`DiaryDeskStage.get_readability_metrics()` 用真实镜头把右页 9 个正文采样点投影到屏上，取最坏值。屏上字号 = 页面字号 × 屏上每页面像素长度（取水平和竖直方向中较短的一个），单位是 1600×900 等效像素。对比度按 WCAG 相对亮度计算：纸色 = 羊皮纸贴图在右页正文区的实测均值 (0.859, 0.763, 0.599) × 纸面 modulate (0.76, 0.70, 0.60)；墨色带 alpha 时先合成到纸色上再算。

| 项 | 底线 | 改前 | 改后实测 | 结论 |
|---|---|---|---|---|
| 3D 世界渲染分辨率 | 物理像素 | 两种窗口都是 1600×900（2920 窗口放大 1.825 倍） | 1600×900 窗口 → 1600×900；2920×1753 → 2920×1643（aspect keep 留黑边后的内容区）；真窗口 `--resolution 2920x1753`（macOS 限高后 2920×1602）→ 2848×1602 | 达标 |
| 页面 SubViewport | ≥1024×1440 | 512×720 | 1024×1440 | 达标 |
| mipmap / 各向异性 | 开启 | 无 | 材质设 `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC`。实测：Godot 4.7 的 `ViewportTexture` 没有 mip 链，SubViewport 也没有开 mip 的选项，开关前后正文区像素差 = 动态颗粒噪声底（6.3–7.0 / 255）。替代：窗口缩放 < 1.5 时 3D 通道 `scaling_3d_scale = 2` 超采样，正文边缘锯齿明显变少 | 部分达标（见 §4） |
| 正文屏上字号 | ≥20 px | 约 8–10 px（推算） | 22.6 px | 达标 |
| 题名屏上字号 | ≥28 px | 约 13 px | 29.1 px | 达标 |
| 注脚（叶号、符文说明） | ≥15 px | 约 7–8 px | 16.2 px | 达标 |
| 正文对比度 | ≥4.5:1 | — | 5.47:1（未开 5.47 / 已阅 ≥5.2 / 封存 ≥4.5，三种状态都由测试断言） | 达标 |
| 题名对比度 | （按正文） | — | 5.31:1 | 达标 |
| 注脚对比度 | ≥3:1 | — | 4.06:1 | 达标 |
| 阅读姿态 | ≤25° | 约 45°（−59° 俯角，推算） | 右页 9 个点最坏 24.2° | 达标（默认镜头，没加悬停推近） |
| 书宽占比 | 55–65% | 约 67% | 62.8% | 达标 |
| 外框文字 | 底线字号、宋体 | 12 / 20 / 12 / 14 / 15 px，黑体 | 卷名 28，载体行、提示、批注题 18，合上、批注正文 20，全部思源宋体 | 达标 |

## 3. 截图（全部为非 headless 截图，已逐张看过）

`.tools/ui-captures/v089_readability/`（在 `.gitignore` 内）：

- `before/diary_1600x900_{idle,flip}.png`、`before/diary_2920x1753_{idle,flip}.png`、`before/diary_window_{idle,flip}.png`
- `after/` 下同名六张

生成命令：`Godot --path . res://tests/ui/diary_readability_capture_runner.tscn -- --phys=2920x1753 --out=res://.tools/ui-captures/v089_readability/after`；真窗口版加 `--resolution 2920x1753` 和 `-- --window`。

目视结论：
- **改前 2920**：正文能认出，但笔画糊成一团（先按 1600 渲染再放大）；叶号“其 1 叶”和符文说明几乎看不出来；书页呈明显梯形。
- **改后 2920**：正文、题名、叶号、四个符文说明在原尺寸下都清楚，笔画锐利；页面接近正视，只轻微收窄；外框卷名和合上按钮也是清楚的宋体。
- **改后 1600**：正文可读，比改前大约 2 倍；超采样之后边缘不再有阶梯锯齿。
- **翻页中**：竖起的叶子上字随透视倾斜，仍然能认；叶下已经是下一叶（H-02 环形预加载正常）。
- **构图变化**：俯视更陡，桌面后墙不再入画；蜡烛、墨水瓶、羽毛笔原本竖直放置，在陡镜头下会被压成细条，现在向后倾 45° 以保持可见。

## 4. 困难与候选方案

1. **ViewportTexture 没有 mipmap。** 候选方案：A 每帧把页面复制成带 mip 的 `ImageTexture`（开销大，每帧都要回读）；B 3D 通道超采样；C 页面用 `TextureRect` 按屏上尺寸渲染（会丢掉 3D 翻页）。选 B：只在窗口缩放 < 1.5 时开，HiDPI 下页面像素已接近 1:1，不需要。D3 要求的“mipmap + 各向异性”这一项按“兼容渲染器实测为准”记为**部分达标**；ADR-0035 切到 Forward+ 后需要复测。
2. **阅读夹角。** 只调俯角，要到约 −82° 才能满足 ≤25°（页角离轴太大）；改用长焦（拉远、缩小 fov）后，−75° 就够了，构图不变。没有做悬停推近：默认镜头已经达标，少一套交互状态。
3. **对比度。** 原来正文墨色在锁定状态下乘了 alpha 0.7，对比度不到 3:1。改为 `INK_FADE_LOCKED`，仍然看得出淡化，但 ≥4.5:1。0-08 改写墨色从亮金 (0.62, 0.42, 0.12) 改为深琥珀 (0.24, 0.11, 0)，因为亮金对纸只有约 2.3:1。

## 5. 风险

- 2920 窗口下世界视口像素约为原来的 3.3 倍；1600 窗口开超采样后 3D 像素是原来的 4 倍。M4 上截图运行流畅，但没有正式测帧率。`diary_turn_capture` 的 max_frame_gap 波动很大（0–79 ms，无论是否超采样），不能作为结论。
- `diary_desk_stage.gd` 1536 行，超过 800 行预算（改前 1470 行就已超出）。测量代码已拆到 `diary_reading_metrics.gd`，主体拆分留给 X1。
- 道具倾斜是为陡镜头做的补救；P0-3 换 DQ 资产或改光照时需要一起看。

## 6. 与 P0-3 合并须知（两个文件中改了哪些函数 / 常量）

`src/ui/diary_desk_stage.gd`：
- 常量：删除 `CAMERA_PITCH_DEG = -47.5`（原值），新增 `CAMERA_PITCH_DEG=-75`、`CAMERA_FOV`、`CAMERA_DISTANCE`、`CAMERA_TARGET`、`READING_ANGLE_MAX_DEG`、`PROP_LEAN_DEG`、`LOW_DPI_SCALE`；preload `ReadingMetrics`
- `var _stage` 类型改为 `TextureRect`
- `_notification`：ENTER_TREE 时连接 / EXIT_TREE 时断开 viewport `size_changed`，并延迟调用 `_sync_world_vp_size`
- `_process`：每帧调用 `_sync_world_vp_size()`
- 新增：`get_readability_metrics`、`physical_scale`、`expected_world_viewport_size`、`get_world_viewport_size`；重写 `_sync_world_vp_size`
- `_build_stage`：世界视口直接挂在 stage 下，`DeskStage` 改为 TextureRect；镜头的 fov、位置、旋转改用上面的常量
- `_prop_sprite`：`rotation_degrees` 的 x 改为 `-PROP_LEAN_DEG`
- `_page_material`：加一行 `texture_filter`
- `_build_rune_detail`：字体改宋体，字号 13 → 18
- `_sync_wax_hit_rect`：只改了注释

`src/ui/diary_page_pair.gd`：
- 常量：`PAGE_SCALE`、`PAGE_BASE_SIZE`、`PAGE_VP_SIZE`（由前两者推导）、`SEAL_SIZE`、`*_FONT_BASE`、`SHEET_MEAN`、`PAPER_MODULATE`、`PAPER_TONE`、`INK_*`、`INK_FADE_*`
- 新增：`caption_labels`、`px()`、`contrast_ratio()`、`_rel_luminance()`、`font_sizes()`、`text_colors()`
- `fill`：墨色和状态淡化改用常量
- `_page_parchment`：modulate 改为 `PAPER_MODULATE`
- `_build_left`、`_build_right`、`_build_wax`、`_build_runes`、`_build_side_sticker`：所有字面量改走 `px()`；符文说明改宋体并登记到 `caption_labels`；正文 `max_lines_visible` 10 → 8

`diary_chapter_screen.gd`：新增 `CHROME_*` 常量、`_serif`、`_chrome_plate`、`get_chrome_font_sizes`；改动了 `_build_top_chrome`、`_build_bottom_chrome`、`_build_close_bookmark`（只改字体和尺寸，样式未动）、`_build_annotation_float`、`_pulse_desk_chrome`、`_refresh_chrome`；删除 `_leaf_label`。

## 7. 跨角色请求

- 架构师 / P0-3：切到 Forward+ 后，复测 ViewportTexture 的 mipmap 和各向异性是否生效；生效后可去掉 `LOW_DPI_SCALE` 超采样。
- 产品经理：请用户在真窗口确认原尺寸下正文可读（§5.1 验收行）。

## 8. 下一步入口

`tests/ui/diary_readability_runner.gd` 是底线守卫；改镜头、字号或纸色前先跑它。截图 runner 用来做前后对比。
