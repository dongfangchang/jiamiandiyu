# Draft · desk-world-prop-batch

> 状态：Draft（等 UI-07 审稿一轮后再考虑晋升 Skill）

## 何时用

按 `ART_BRIEF_DESK_WORLD` 批量交付正俯视桌面物件（透明底 + 独立阴影）。

## 步骤

1. 读 EXPERIENCE_ARCHITECTURE + ART_BRIEF_DESK_WORLD §0；若有 `DESK_WORLD_STATIONS.md` 先对比例。
2. 生成：正俯视、深炭底 `#1a1a1a`、无字、无投影、左上暖光；长边≤2048。
3. 目视剔除夹带烛/杂物；不合格重出。
4. 抠图：深色皮 `flood_dark` tol≈0.10–0.12；纸类可略高；透明窗用品红 chroma 再清溢色。
5. 定尺寸：BRIEF 画布，物件 fit≈0.92–0.96，勿硬拉伸变形。
6. 派生同尺寸灰度 `*_shadow.png`；物件本体不含投影。
7. 2048 总览拼贴对照 §4；每目录 README；请 UI-07 按 DW-ID 审稿。
8. 不迁 `assets/game`（coordinator）。

## 失败模式

- 深色皮被抠穿 → 降 tol、查中心 alpha
- 画布比例与源构图不符 → README 注明留白，或 UI 退回后重裁
- 开合态各自生成 → 观感断裂或轮廓错配；**先定母版再派生**（合→开参考；熄灭→点燃叠焰；idle→active 叠冷光），并用 body alpha xor 对账（焰/光晕区可豁免）
- 粉笔圈 / 页框标题易生成字母 → 提示词写死「ZERO letters」；仍失败则几何 scrub 或底栏重绘
- DW-15 墨迹：优先程序化距离场（白=先到）；勿用带字插画冒充阈值图
- DW-18：品红窗 chroma + 中心透明率抽检；长边 1260×1770 对齐日记竖图
- DQ 书口 / 页饰 / 接触阴影：优先程序化；丝带忌墨渍（中段留给 UI 字）；索引卡线数清到 BRIEF 指定行数
