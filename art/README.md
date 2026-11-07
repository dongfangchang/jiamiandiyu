# 美术资源使用说明

## 目录

- `ART_DIRECTION.md`：视觉方向、色板、资产规格与正式插画提示词。
- `ASSET_MANIFEST.md`：当前资产、计划资产与来源记录。
- `assets/svg/`：可编辑矢量源文件。
- `assets/svg/v0.3.0/`：战斗场景、三敌人、八卡面与状态图标的 v0.3.0 矢量源。
- `../assets/game/v0.3.0/`：已由主线程迁移的 v0.3.0 正式 PNG。
- `assets/svg/v0.4.0/`：身份、祈愿、奖励、升级图标与卡背的 v0.4.0 矢量源。
- `assets/game/v0.4.0/`：等待主线程迁移到 `../assets/game/v0.4.0/` 的 PNG 候选。
- `../assets/game/`：已经渲染的 1:1 PNG，是 Godot 运行时唯一的正式 PNG 来源。
- `preview/contact-sheet.html`：在浏览器中查看整套样张。
- `tools/generate_art.mjs`：重新生成占位资产的脚本。

## 重新生成

在项目根目录运行：

```powershell
node art/tools/generate_art.mjs
```

脚本只使用 Node.js 内置模块，不需要安装依赖。

v0.3.0 返工资产：

```powershell
node art/tools/generate_v030_art.mjs
```

生成清单见 `assets/game/v0.3.0/render-manifest.json`，其中路径以 `art/` 为基准。

v0.4.0 短循环候选：

```powershell
node art/tools/generate_v040_art.mjs
```

脚本只使用 Node.js 内置模块和本机 Edge 无头渲染，不安装额外依赖。生成清单为 `assets/game/v0.4.0/render-manifest.json`，审稿拼图为 `assets/game/v0.4.0/contact-sheet.png`。

## PNG 导出

当前环境使用 Microsoft Edge 的无头模式把 SVG 渲染为 PNG。正式 PNG 输出到项目级 `assets/game/`；卡牌为 600 x 840，敌人为 900 x 900，标题与仪式为 1600 x 900。

如果后续修改 SVG，建议优先直接在 Godot 中使用 SVG 作为临时资产；只有在导入滤镜出现差异时再重新导出 PNG。

## 当前生成工具状态

此会话没有暴露内置 `image_gen` 工具，因此当前美术是原创程序化 SVG 占位资产。正式插画可以按 `ART_DIRECTION.md` 中的提示词模板生成；需要 CLI 图像生成时，用户必须明确选择该方式并自行在本地设置 `OPENAI_API_KEY`。

## 接入 Godot

- 卡牌样张用于视觉验收。正式实现应使用独立插画、卡框和文字。
- 状态图标可从 `icons/status-sheet.svg` 拆分，也可以在 Godot 中重新绘制。
- 标题画面和晋升仪式可以直接作为背景纹理使用。
- 卡牌图鉴建议加载 600 x 840 PNG；牌阵中的缩小卡可以生成 256 x 358 的缩略图。

