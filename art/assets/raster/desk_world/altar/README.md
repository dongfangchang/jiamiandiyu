# DW-13 · 祈愿台（altar）

| 文件 | 尺寸 | 状态 | 说明 |
|---|---|---|---|
| `altar_idle.png` | 1400×1400 | idle | 圆镜 + 三烛 + 几何粉笔圈（无字母） |
| `altar_idle_shadow.png` | 1400×1400 | — | 灰度柔边阴影 |
| `altar_active.png` | 1400×1400 | active | 同轮廓；镜面叠冷光 |
| `altar_active_shadow.png` | 1400×1400 | — | 灰度柔边阴影 |

- 视角：正俯视；背景：透明 RGBA；文字：无（粉笔仅为弧/点/三角）
- 站位比例：直径 ~41%（0.55）；`station.altar`
- 来源：2026-11-24 ART-DW-X2；idle 源 `_work/dw13_altar_idle.jpg`（v3 无字母）；active = idle ⊕ 冷光叠层
- 验证：idle/active 外围 alpha 错配 0%（中心光晕可不同）
- 授权：项目原创候选，仅私人离线使用
