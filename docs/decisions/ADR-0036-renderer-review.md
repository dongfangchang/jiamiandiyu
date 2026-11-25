# ADR-0036：渲染器复核（与 ADR-0035 结论冲突，待用户裁决）

状态：**已采纳**（用户 2026-11-25 选定 Mobile；取代 ADR-0035）
关系：复核 ADR-0035。采纳本 ADR 时，ADR-0035 改为"被取代"。

> 冲突要点：
> - ADR-0035 依据"只有 Forward+ 有 SSAO"推荐 Forward+，帧数是单次 48 个样本。
> - 本复核取 3 次中位数、每次 300 帧，并实测文字对比度。结论：
>   - SSAO 在 −75° 俯视镜头下几乎看不出来；
>   - 雾和 PCSS 软阴影会把书页冲淡，正文对比度降到 3.43，低于 4.5 的底线；
>   - Forward+ 全开时帧时间约 60 ms。
> - 推荐 **Mobile + 调优参数**。"简陋感"八成来自色调映射、环境光和烛光主光的设置，与渲染器无关。
>
> 对比图：`docs/architecture/renderer_eval/grid_idle.jpg`、`grid_flip.jpg`、`text_crop_2920.png`。

---

（以下为评估原文）


状态：提议（v0.89.0 轨道 C / AR-05，架构师起草；待产品经理裁决）
日期：2026-11-24
相关：ADR-0034 D3（可读性底线）、D4（画面质量）；v0.89.0 P0-3；`EXPERIENCE_ARCHITECTURE.md` §5.1；`ART_BRIEF_DESK_WORLD.md` §5

## 背景

ADR-0034 D4 要求比较 `gl_compatibility`、Forward+、Mobile 三种渲染器，用同一镜头截图比较画面和帧率，优先看 macOS M4。用户反馈"画风太简陋"，其中一部分原因被归到渲染器上：兼容渲染器没有 SSAO，也没有柔和阴影。

现状：`project.godot` 中 `renderer/rendering_method` 和 `.mobile` 都设为 `gl_compatibility`；没有设置 `rendering_device/driver.*`。DeskWorld 的灯光和环境全部在 `src/ui/diary_desk_stage.gd::_build_stage()` 里用代码搭建：一盏 DirectionalLight 作主光并投影，两盏补光 Omni，一盏蜡烛 Omni 投影，Environment 使用纯色背景加环境色，没有 tonemap、glow 和后期。

## 方法

- 测试机：macOS 26，Apple M4，Godot 4.7.2。驱动：兼容渲染器用 `opengl3`（实际运行在 OpenGL 4.1 over Metal 上），Forward+ 和 Mobile 用原生 `metal`（Metal 4.0）。Vulkan（MoltenVK）也能跑通，但不作为推荐路径。
- 截图和测时都用可复用的 runner `tests/ui/renderer_eval_capture_runner.tscn`（名字带 `_capture_runner`，不进默认测试集）。runner 把 `DiaryChapterScreen` 放进一个**按物理像素尺寸**创建的离屏 SubViewport（1600×900 和 2920×1753），拍待机图和翻页半空图（6 秒慢翻，第 2 秒截图），然后在关闭垂直同步的条件下测量墙钟帧时间：
  - **待机**：连续 300 帧取平均。
  - **翻页**：连续 300 帧取平均，期间来回 `play_flip`，保证每一帧都有书页在空中。
- 两套参数：
  - **现状参数**：直接使用 `diary_desk_stage.gd` 当前的灯光和环境。
  - **调优**：`tests/ui/renderer_eval_look.gd` 在运行时覆盖灯光和环境参数，代表每个渲染器"尽力调过"后的上限，而不是默认效果。同一份调优代码跑三个渲染器，渲染器不支持的特性会被引擎静默忽略。
- 帧时间每组跑 3 次，取中位数。另做了逐项开关的 A/B 测试，用来找出开销来源。
- 正文对比度：在 2920×1753 待机图上裁出右页正文区域 (1590,560)-(2210,720)，取 2% 分位亮度作墨色、60% 分位作纸色，按 WCAG 公式计算。截图包含 `DiaryPostFx` 的暗角和颗粒，三个渲染器条件相同。
- 运行注意：在 macOS 上**只加 `--rendering-driver metal`、不加 `--rendering-method`** 时，会强制走 Forward+，而不是使用项目设置。比较时两个参数必须一起给。

运行示例：

```bash
Godot --path . --resolution 2920x1753 --rendering-method mobile --rendering-driver metal \
  res://tests/ui/renderer_eval_capture_runner.tscn -- \
  --size=2920x1753 --look=tuned --out=res://.tools/ui-captures/renderer_eval/mobile/tuned
# 可选 A/B 开关：--fog=0 --ssao=0 --pcss=0 --glow=0 --msaa=0|2|4 --soft_high=1 --exposure=2.4 --tonemap=agx
```

## 截图

已入库的对比图在 `docs/architecture/renderer_eval/`，均不超过 1600 宽，共约 6 MB：

| 文件 | 内容 |
|---|---|
| `grid_idle.jpg` | 3 行（compat / Mobile / Forward+）× 2 列（现状 / 调优），待机，1600×900 |
| `grid_flip.jpg` | 同上，翻页半空 |
| `text_crop_2920.png` | 2920×1753 原像素裁切右页正文：compat 现状 / compat 调优 / Mobile 调优 / Forward+ 调优 |
| `candle_crop_2920.jpg` | 2920×1753 原像素裁切烛台和桌面：同上四格 |
| `baseline_compat_idle.jpg` | 现状基线，全帧 |
| `recommended_mobile_idle.jpg`、`recommended_mobile_flip.jpg` | 推荐方案，全帧 |
| `compat_tuned_idle.jpg`、`forward_plus_tuned_idle.jpg` | 另外两个渲染器调优后的全帧 |

原始 PNG（每个渲染器 × 现状/调优 × 两个尺寸 × 待机/翻页）在本机 `.tools/ui-captures/renderer_eval/<renderer>/<default|tuned|tuned_lite>/`，未入库，可以用上面的命令重新生成。

## 帧时间（Apple M4，毫秒，3 次取中位数，越小越好）

| 渲染器 / 参数 | 1600×900 待机 | 1600×900 翻页 | 2920×1753 待机 | 2920×1753 翻页 |
|---|---|---|---|---|
| gl_compatibility · 现状 | 6.9 | 6.9 | 18.7 | 21.0 |
| gl_compatibility · 调优 | 6.9 | 6.9 | 31.3 | 28.8 |
| Mobile · 现状 | 6.9 | 6.9 | 15.0 | 13.0 |
| **Mobile · 调优（推荐）** | **6.9** | **6.9** | **18.4** | **17.1** |
| Forward+ · 现状 | 6.8 | 6.9 | 21.3 | 19.2 |
| Forward+ · 调优（SSAO + 体积雾 + PCSS） | 12.6 | 15.3 | 60.3 | 60.5 |
| Forward+ · 调优去雾去 PCSS | 10.6 | 6.9 | 33.7 | 32.3 |

读表说明：

- 1600×900 下各组大多卡在约 6.9 ms。这是本机的帧节拍下限，说明场景本身负载很小，这个尺寸下三者分不出高低。**有区分度的是 2920×1753**，而这正是 ADR-0034 D3 要求的"按物理像素渲染"后，Retina 窗口上的真实尺寸。
- 单次测量波动约 ±30%。表中只有"Forward+ 调优明显更贵"和"2920 下 Mobile 比兼容渲染器快"这两条结论在 3 次重复里都稳定成立。
- 开销来源（2920，A/B 测试）：
  - Forward+ 调优里最贵的是 PCSS 软阴影（`light_size` / `light_angular_distance`），约 +10–15 ms；其次是 SSAO 和体积雾，各约 +5 ms。
  - Mobile 上 PCSS 约 +2 ms。
  - 兼容渲染器调优比现状多约 +10 ms，主要来自 4×MSAA 和 glow 在高分辨率下的开销。

## 正文对比度（2920×1753，墨/纸，ADR-0034 D3 要求 ≥ 4.5:1）

| 组合 | 对比度 |
|---|---|
| gl_compatibility · 现状 | 4.54 |
| gl_compatibility · 调优 | 5.92 |
| Mobile · 现状 | 2.53 |
| **Mobile · 调优** | **4.04** |
| Forward+ · 现状 | 2.54 |
| Forward+ · 调优 | 3.43（体积雾把纸面冲灰）／去雾 3.97 |

两项关键实测：

1. **同一组灯光参数下，RD 渲染器（Mobile / Forward+）的纸面亮度只有兼容渲染器的约 40%**：纸面相对亮度 0.147 对 0.364。所以直接切换渲染器而不改参数，画面会整体变暗、发灰（见 `grid_idle.jpg` 左列）。补救方法是把 `tonemap_exposure` 调到约 3.0，兼容渲染器保持 1.15。
2. **在 RD 渲染器下，纸面的 GGX 高光会把墨色往纸色方向抬**，墨字发灰。把页面材质设为 `specular_mode = SPECULAR_DISABLED` 后，对比度从 1.89 回到 4.04。试过两条其他路线，都没有用，已否决：
   - 给页面 `FORCE_SRGB`：会二次解码，对比度降到 1.2。
   - 让页面自发光：会把墨也一起提亮，对比度降到 1.1–2.2。

   这说明 `ViewportTexture` 贴到 3D 上时，RD 渲染器的色彩空间处理本身是正确的，不需要额外修正。

## 各渲染器能为"画风简陋"带来什么（目视结论）

| 能力 | gl_compatibility | Mobile | Forward+ | 对本场景的实际效果 |
|---|---|---|---|---|
| 实时投影（主光 + 蜡烛） | 有（现状已开） | 有 | 有 | 书压在桌上、杂物落影，三者都能做到 |
| 柔和阴影（PCF blur / PCSS） | 有 `shadow_blur`，无 PCSS | 有 PCF；PCSS 可用（+2 ms） | 全有（PCSS 很贵） | 蜡烛投影边缘变软，Mobile 和 Forward+ 略好，差别小 |
| Tonemap（Filmic/ACES/AgX） | 有 | 有 | 有 | **收益最大的一项**：烛光高光不再死白，暗部有层次。三者都支持 |
| Glow / Bloom | 有（4.x 兼容渲染器已支持） | 有 | 有 | 烛焰光晕、纸面烛光渐晕。三者都支持 |
| MSAA / FXAA | 有 | 有 | 有（另有 TAA） | 书页边缘、羽毛笔的锯齿。三者都够用 |
| SSAO / SSIL | 无 | 无 | 有 | 俯拍、平板桌、薄书的场景里几乎看不出来，书脊和桌面接缝稍暗 |
| 体积雾 / 光柱 | 无 | 无 | 有 | 能做出烛光雾气，但会把整页冲灰，正文对比度跌到 3.4。**与可读性底线冲突** |
| 屏幕空间反射 | 无 | 无 | 有 | 场景里没有反光面，不需要 |

**目视结论**：

- "简陋感"的主要来源有三点：没有 tonemap 和 glow；环境光太亮把立体感压平；蜡烛不是主光。这三点**不依赖渲染器**。
- 兼容渲染器调优后（`compat_tuned_idle.jpg`）已经拿到大约 80% 的观感提升。
- Mobile 调优和 Forward+ 去雾版的观感几乎一样：烛光暖区、桌面渐暗、书本投影、烛焰光晕。Forward+ 独有的 SSAO 在这个镜头下基本看不出来，体积雾还破坏可读性。
- 剩下的简陋感来自几何和材质：方盒桌、平面墙、薄板书。这要靠美术 `ART_BRIEF_DESK_WORLD.md` §5 的 DQ-01…06 解决，换渲染器解决不了。

## 兼容性约束（代码与资源盘点）

- **只为兼容渲染器写的代码**：没有。
  - `src/**` 中没有 `RenderingServer` 调用，也没有按渲染器分支的逻辑。
  - `diary_desk_stage.gd::_build_vignette()` 的注释说"用渐变不用 shader 是因为兼容渲染器"，但实现是普通的 `GradientTexture2D`，所有渲染器都能用。
- **着色器**：只有两个，都是 `canvas_item`，在三个渲染器下都能正常编译和显示（已用截图验证）。
  - `assets/ui/diary/diary_postprocess.gdshader`：使用 `hint_screen_texture`。
  - `diary_page_pair.gd` 中内联的羽化 shader。
- **页面 `ViewportTexture` → `StandardMaterial3D.albedo_texture`**：RD 渲染器下显示正确，色彩空间无误（见上文"两项关键实测"）。唯一需要处理的是纸面高光，即 `SPECULAR_DISABLED`。
- **2D UI**（`canvas_items` 拉伸、字体、主题）：`tests/ui/ui_capture_runner.tscn` 的 21 张界面截图在 Mobile 和 Forward+ 下分别与兼容渲染器逐像素比较：
  - 平均差异 ≤ 0.46/255；
  - 差异大于 24 的像素占比为 0.00–0.02%；
  - 目视无差别（字体灰度抗锯齿的舍入差异）。
- **全量测试**（`tools/run_tests.sh`，丢弃分支 `adr0035-renderer-throwaway` 上临时修改 `project.godot`，并把调优参数原型移植进 `diary_desk_stage.gd`）：

  | 项目设置 | 结果 |
  |---|---|
  | gl_compatibility（基线，main 76d02d5） | pass=92 fail=0 skipped=11 |
  | mobile + 调优原型 | pass=92 fail=0 skipped=11 |
  | forward_plus + 调优原型 | pass=92 fail=0 skipped=11 |

  注意：`run_tests.sh` 用 `--headless` 运行，渲染走 dummy 驱动。全绿只能说明脚本和场景逻辑与渲染器设置无关，**不能证明 GPU 输出正确**。GPU 输出由上面的真窗口截图和 2D 逐像素比较覆盖。
- **主程序真窗口冒烟**（Mobile/Metal，`--quit-after 120`）：无错误和警告；`v084_diary_desk_capture_runner` 在 Mobile 下截图正常。

## 导出影响

- **macOS（当前主力机，M4）**：Mobile 和 Forward+ 默认走原生 Metal，实测无需额外配置。项目目前**没有 macOS 导出预设**，只有 Windows。用户在 macOS 上是从编辑器或 `play-mac.sh` 运行，不受影响。
- **Windows**（`export_presets.cfg`：x86_64，`application/export_d3d12=0`）：
  - Mobile 和 Forward+ 需要 Vulkan 1.0+ 或 Direct3D 12 显卡。大约 2015 年以后的 Intel 核显（Skylake 起）、AMD GCN 及以后、NVIDIA Kepler 及以后都满足；更老的核显（如 HD 4000 一代）不满足。
  - Godot 4.x 默认 `rendering/rendering_device/fallback_to_opengl3=true`：在不支持的机器上会自动退回兼容渲染器，游戏仍能启动。但那时画面会按兼容渲染器的亮度显示，所以**调优参数必须按 `RenderingServer.get_current_rendering_method()` 分支**（见下文 `exposure` 等）。
  - 项目没有显式设置 `rendering_device/driver.windows`。Godot 4.6 起新建项目在 Windows 上默认用 D3D12（官方说明"已有项目不变"）。为避免歧义，迁移时应显式写入 `driver.windows="vulkan"`，因为 `export_d3d12=0` 不打包 D3D12 Agility SDK。或者改为 `d3d12` 并把 `export_d3d12` 设为 1。具体选哪个，在用户的 Windows 机上用 `build-windows.ps1` 实测后再定。
  - 外部冒烟（`build-windows.ps1` 中的 `--headless --quit-after 5`）只测启动，不覆盖 GPU。
- **首帧卡顿风险**：RD 渲染器需要编译管线。Godot 4.4 起有 ubershader 和管线缓存缓解这个问题，但首次打开日记站仍可能有一次几十毫秒的卡顿。UI-P0-3 应在真窗口里首次进入日记站时观察，必要时在标题站预热：先实例化一次桌面世界并渲染一帧。

## 风险与迁移成本

| 项目 | 成本 / 风险 | 缓解 |
|---|---|---|
| 改 `project.godot` 两行 | 低（跨角色文件，需产品经理指定负责人） | 主协调者执行 |
| 灯光参数不能照搬 | 中：同参数下 RD 渲染器画面暗约 60%，直接切换会更难看 | 一次性按下方参数改，按渲染器分支设 exposure 和 glow 混合模式 |
| 纸面对比度 | 中：Mobile 调优后为 4.04，仍低于 4.5 | 页面 `SPECULAR_DISABLED`（必须）；UI-P0-3 加深页面 SubViewport 的墨色，或提高纸色，并配合 D3 的 1024×1440 页面重新实测 |
| 退回兼容渲染器的机器 | 低：能启动，画面按兼容渲染器参数显示 | 参数按渲染器分支 |
| 测试覆盖 | 低：headless 测试与渲染器无关 | 渲染相关验收依赖真窗口截图 runner |
| 将来想要 SSAO 或体积雾 | 需要改用 Forward+，并承受 3 倍开销 | 本场景不需要；以后如有室内远景站点再评估 |

## 决策（建议）

**把 `renderer/rendering_method` 和 `renderer/rendering_method.mobile` 都改为 `"mobile"`。macOS 用 Metal，Windows 用 Vulkan 并保留 `fallback_to_opengl3=true`。不选 Forward+。**

理由：

1. 画面收益主要来自 tonemap、glow、以烛光为主光的布光和柔和投影。Mobile 全都支持，观感与 Forward+ 去雾版几乎一样。
2. 在 ADR-0034 D3 要求的 2920×1753 物理像素下，Mobile 调优帧时间约 18 ms，兼容渲染器调优约 31 ms，Forward+ 调优约 60 ms。Mobile 是唯一一个调优后仍稳定高于 50 fps 的组合。
3. Forward+ 独有的 SSAO 在这个俯拍镜头下几乎看不出来，体积雾还和可读性底线冲突，不值得承担 3 倍开销。
4. 兼容渲染器调优可以作为**降级方案**：如果产品经理不想动 `project.godot`，下方参数中兼容渲染器那一列照样能拿到大部分观感提升，代价是 Retina 全分辨率下约 30 fps。

### 给 UI-P0-3 的具体参数

需要修改 `src/ui/diary_desk_stage.gd::_build_stage()`、`_build_candle()` 和 `_page_material()`。其中 compat 列也是退回兼容渲染器时生效的值：

```gdscript
var compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
# --- DeskWorldViewport ---
_world_vp.msaa_3d = Viewport.MSAA_4X
_world_vp.positional_shadow_atlas_size = 4096
# --- Environment ---
env.background_color = Color(0.02, 0.012, 0.01)
env.ambient_light_color = Color(0.55, 0.50, 0.48)   # 原 (0.76,0.80,0.86)
env.ambient_light_energy = 0.30                      # 原 0.64：环境光让位给烛光
env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
env.tonemap_exposure = 1.15 if compat else 3.0       # RD 同参数下暗约 60%
env.glow_enabled = true
env.glow_intensity = 0.7
env.glow_strength = 1.0
env.glow_bloom = 0.02
env.glow_hdr_threshold = 1.0
env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT if compat else Environment.GLOW_BLEND_MODE_SCREEN
env.adjustment_enabled = true
env.adjustment_contrast = 1.06
env.adjustment_saturation = 0.95
# 不开 ssao / ssil / volumetric_fog / ssr
# --- KeyLight（改作窗外冷色月光，从背后右上方打来）---
key.light_color = Color(0.72, 0.80, 1.0)
key.light_energy = 0.30
key.light_angular_distance = 2.0   # PCSS，Mobile 约 +2 ms；预算紧张时设为 0，改用 shadow_blur
key.shadow_blur = 1.6
key.shadow_opacity = 1.0
# --- FillLight / FillLightRight：energy 各乘 0.6（0.072 / 0.096）---
# --- CandleFlame（成为主光）---
candle.light_color = Color(1.0, 0.68, 0.38)
candle.light_energy = 1.0
candle.omni_range = 2.8
candle.omni_attenuation = 1.6
candle.light_size = 0.05
candle.shadow_enabled = true
candle.shadow_blur = 1.4
candle.shadow_opacity = 0.85
# 蜡烛贴图不被自己的火焰照爆：
candle_sprite.layers = 2
candle.light_cull_mask = 0xFFFFF & ~2
# 新增 HDR 焰心（glow 的光源）：r=0.007 的球体，albedo 黑，emission (1,0.7,0.35) ×6，
# 不投影，位置在 CandleFlame 上方 (0, 0.025, 0.02)
# --- 页面材质（_page_material）---
mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED   # 必须：RD 下高光会让墨色发灰
```

完成后的验收：用 `renderer_eval_capture_runner` 在 2920×1753 下截图，正文对比度要 ≥ 4.5（当前 4.04）。不足部分在 UI-P0-3 的页面版式里补：加深墨色，或配合 1024×1440 页面重新测量。`tests/ui/renderer_eval_look.gd` 是上述参数的可运行参考实现，UI-P0-3 移植进 `src/ui` 后可以删除，也可以保留作 A/B 工具。

## 后果

- 采纳后：主协调者修改 `project.godot` 两行，并显式写入 `rendering_device/driver.windows`；UI-P0-3 按上方参数修改 `diary_desk_stage.gd`；美术 DQ-01…06 按 RD 渲染器下的画面审稿。
- 丢弃分支 `adr0035-renderer-throwaway` 保留原型提交（Mobile 设置 + 调优参数移植 + runner），**不合并**，复核完即可删除。
- 不采纳：保持兼容渲染器，UI-P0-3 只用上方 compat 列参数。
