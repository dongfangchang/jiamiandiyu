# 美术资源使用说明

## 目录

- `ART_DIRECTION.md`：视觉方向、色板、资产规格与正式插画提示词。
- `ASSET_MANIFEST.md`：当前资产、计划资产与来源记录。
- `assets/svg/`：可编辑矢量源文件。
- `assets/png/`：已经渲染的 1:1 PNG，可直接导入 Godot。
- `preview/contact-sheet.html`：在浏览器中查看整套样张。
- `tools/generate_art.mjs`：重新生成占位资产的脚本。

## 重新生成

在项目根目录运行：

```powershell
node art/tools/generate_art.mjs
```

脚本只使用 Node.js 内置模块，不需要安装依赖。

## PNG 导出

当前环境使用 Microsoft Edge 的无头模式把 SVG 渲染为 PNG。卡牌为 600 x 840，敌人为 900 x 900，标题与仪式为 1600 x 900。

如果后续修改 SVG，建议优先直接在 Godot 中使用 SVG 作为临时资产；只有在导入滤镜出现差异时再重新导出 PNG。

## 当前生成工具状态

此会话没有暴露内置 `image_gen` 工具，因此当前美术是原创程序化 SVG 占位资产。正式插画可以按 `ART_DIRECTION.md` 中的提示词模板生成；需要 CLI 图像生成时，用户必须明确选择该方式并自行在本地设置 `OPENAI_API_KEY`。

## 接入 Godot

- 卡牌样张用于视觉验收。正式实现应使用独立插画、卡框和文字。
- 状态图标可从 `icons/status-sheet.svg` 拆分，也可以在 Godot 中重新绘制。
- 标题画面和晋升仪式可以直接作为背景纹理使用。
- 卡牌图鉴建议加载 600 x 840 PNG；牌阵中的缩小卡可以生成 256 x 358 的缩略图。

