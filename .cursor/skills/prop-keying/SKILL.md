---
name: prop-keying
description: 按 props.manifest.json 对 art 栅格道具做洪水抠图并输出到 assets/ui。标题屏/桌面道具源图更新后由美术准备、协调者或授权流程执行。
---

# Prop Keying

## 步骤

1. 源图放 `art/assets/raster/v0.85.0/title/` 或 `props/`。
2. 在 `props/props.manifest.json` 的 `props[]` 登记 `id/src/key/tolerance/...`。
3. 深色皮革/铜：`flood_dark`，tolerance 约 0.05–0.12；检查不透明占比防抠穿。
4. 跑 Registry 中 `key-props` 配方（需本机 `$GODOT`）。
5. 整图背景类（如 desk-wide）用 `key: none`。

详见 `docs/design/PROP_PIPELINE.md`。
