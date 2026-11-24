# DW-06 · 烛台（candle）

| 文件 | 尺寸 | 状态 | 说明 |
|---|---|---|---|
| `candle_out.png` | 512×768 | 熄灭 | **母版轮廓**（底座/烛身） |
| `candle_out_shadow.png` | 512×768 | — | 阴影 |
| `candle_lit.png` | 512×768 | 燃着 | 同母版 + 俯视焰/暖光；**底座 alpha 与 out 对齐** |
| `candle_lit_shadow.png` | 512×768 | — | 阴影 |
| `smoke.png` | 512×768 | 烟 | 骨白 + alpha，叠在熄灭帧上 |
| `smoke_shadow.png` | 512×768 | — | 占位软影（特效层可忽略） |

- 视角：正俯视；背景：透明 RGBA；文字：无
- 站位：底座直径 ~12%；T4 切换依赖 lit/out 轮廓对齐（`DESK_WORLD_STATIONS.md` §5）
- 来源：2026-11-24 初交；**FIX** lit 由 out 母版合成焰（body 错配 0%，焰可不同）
- 授权：项目原创候选
