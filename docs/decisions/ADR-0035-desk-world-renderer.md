# ADR-0035：DeskWorld 渲染器选择（gl_compatibility / Mobile / Forward+）

状态：**被 ADR-0036 取代**（用户 2026-11-25 选定 Mobile）
日期：2026-11-24

## 背景

ADR-0034 D4 要求评估渲染器，解锁日记站光照与后期（UI-P0-3）。当前 `project.godot` 为：

```text
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

Compatibility 无真实 SSAO、阴影偏硬，烛光氛围与接触阴影难达标。导出侧目前仅有 Windows Desktop 预设（默认 Vulkan 路径可用）；尚无独立 macOS 导出预设。

## 评估方法

- 机器：macOS / Apple M4 / arm64；窗口捕获 **2920×1753**
- 引擎：Godot **4.7.2.stable**（`.tools/godot-4.7.2`）
- 切换：CLI `--rendering-method`，**不改**已入库的 `project.godot`
- 场景：日记站同一快照与镜头（`tools/architecture/ar05_renderer_compare_runner.tscn`）
- 每法两张图：`baseline`（现有 Environment）与 `fx`（同开 ACES + glow + SSAO 请求）
- 复跑：`tools/architecture/ar05_run_compare.sh`

## 实测摘要（M4 · 2920×1753）

| 方法 | 驱动 / 后端 | FPS avg (min–max) | 真实 SSAO | 柔和阴影 / 辉光 / ACES |
|---|---|---|---|---|
| `gl_compatibility` | OpenGL 4.1 Metal · Compatibility | 20.2 (3–21) | 否（属性可写，管线不跑） | 阴影硬；辉光/色调受限 |
| `mobile` | Metal · Forward Mobile | **32.2 (32–40)** | 否（Forward+ 专属） | Metal RD；辉光 + ACES 可用 |
| `forward_plus` | Metal · Forward+ | 17.4 (12–33) | **是** | 全套可用；HiDPI 全开 FX 偏沉 |

全分辨率原图（本机、`.tools` 忽略）：`.tools/ui-captures/ar05_renderer/*_{baseline,fx}.png`  
入库缩略图与报告：`docs/reports/v0.89.0/ar05_renderer/`

对比结论（肉眼 + 指标）：

1. **Compatibility**：书缘投影生硬，烛光体积感弱；开 FX 后画面变化主要来自有限辉光/曝光，**无 SSAO 层次**。
2. **Mobile**：帧率最稳、Metal 路径正确；阴影与材质响应优于 Compatibility，适合性能档；**仍无 SSAO**，接触阴影需继续依赖美术 DQ-06 / 假阴影。
3. **Forward+**：唯一能把 SSAO + 辉光 + ACES 一次开齐的路径；同镜头下桌面凹凸与书页接缝可读性最好；在 2920×1753 全开 FX 时约 **17 fps**，可交互但余量小。

## 决策

1. **桌面主路径默认改为 `forward_plus`**（macOS / Windows 桌面）。  
   - 理由：P0-3 / D4 的画面升级以 **真实 SSAO + 柔和阴影 + 辉光 + 色调映射** 为验收依赖；只有 Forward+ 满足 SSAO。
2. **`renderer/rendering_method.mobile` 设为 `mobile`**（若日后出移动端；当前无移动目标，仅作预留）。  
3. **Compatibility 降为应急回退**，不作为 DeskWorld 质量路径；不得再以「兼容渲染器够用」挡住后期。  
4. **性能档（可选后续）**：弱 GPU / 低帧时允许降到 `mobile` 或关 SSAO/降辉光，由 UI 质量开关实现；默认发货仍是 Forward+。

## 迁移代价

| 项 | 谁做 | 代价 |
|---|---|---|
| `project.godot` 改 `rendering_method=forward_plus` | 主协调者 / 产品授权一次合入 | 一行配置；需在真窗口冒烟标题→日记 |
| DeskWorld `Environment` 开 SSAO/glow/ACES | UI（UI-P0-3） | 调参；HiDPI 下注意帧率预算（SSAO radius/intensity、glow） |
| Windows 导出 | 已有 Desktop 预设 | Forward+ → Vulkan（或 D3D12）；弱卡需质量开关 |
| macOS 导出 | 尚未有 preset | 本 ADR 不新建导出；Metal 已在本机跑通 Forward+ |
| 自动化测试 | 无额外阻塞 | headless/dummy 不依赖 SSAO；黄金回放规则不变 |
| Compatibility 专有假设 | UI 排查 | 去掉「只在 Compatibility 上测过」的硬阴影/无后期假设 |

**不合入范围**：本评估不改 `src/ui/**` 生产实现、不改玩法/存档。

## 对 UI-P0-3 的接口约定

- 可依赖：Forward+ 下 `Environment.ssao_*`、`glow_*`、`tonemap_mode=ACES`、Directional/Omni 柔和阴影。
- 勿依赖：Compatibility 上的「假 SSAO」；Mobile 上的 SSAO。
- 建议：1600×900 与 2920×1753 各留一张后期对比；帧率以日记站闲置 ≥20 为软门槛，不足则先降 SSAO 再降辉光。

## 后果

- 解锁 UI-P0-3 光照/后期与美术 DQ 材质的正确呈现路径。
- HiDPI 全特效有帧率压力；需质量档或参数上限，避免默认机「能开不能玩」。
- 文档：`docs/ORIENTATION.md` 中「当前为 gl_compatibility」一句在合入配置后由产品/协调者改掉。

## 回滚

若 Forward+ 在目标 Windows 真机无法稳定呈现或帧率不可接受：  
1) 临时把 `rendering_method` 改回 `mobile`（保留辉光/ACES，放弃 SSAO）；或  
2) 回 `gl_compatibility` 并冻结 P0-3 后期范围。  
回滚只动项目渲染设置与 Environment 开关，不改存档与黄金回放。
