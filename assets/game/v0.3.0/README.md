# v0.3.0 美术导出

本目录保存等待 UI 复验和主线程迁移的 PNG 候选。

- `render-manifest.json` 是稳定 ID、SVG 源、PNG 候选和尺寸的机器可读清单。
- 清单中的路径以 `art/` 为基准，不是项目根目录。
- 所有 PNG 使用 1× 设备缩放渲染。
- 正式迁移目标是 `assets/game/enemies/`、`assets/game/cards/`、`assets/game/scenes/` 和 `assets/game/icons/`。
- 迁移完成后，不能同时长期保留两套可编辑正式资产。
