# v0.26.0 / 美术资源插件安装记录

## 插件

- 名称：Aseprite Wizard
- 来源：[viniciusgerevini/godot-aseprite-wizard](https://github.com/viniciusgerevini/godot-aseprite-wizard)
- 分支：`godot_4`
- 固定提交：`18ebea9868ea567782ae9e53b27ad260dbc8e062`
- 版本：`9.8.0`
- 许可证：MIT（许可证副本保存在 `addons/AsepriteWizard/LICENSE`）

## 用途

插件只用于 Godot 编辑器中的美术资源工作流：导入 Aseprite 文件、切分图层/精灵帧、生成 SpriteFrames 和辅助检查。正式游戏运行不依赖编辑器插件，也不依赖网络或 Aseprite。

## 风格适配结论

本项目的正式方向是十九世纪铜版画、旧报纸纸张、墨黑与暗金的神秘学档案风格。已评估的其他候选中，PixelMaker 主要生成像素美术，与项目风格不匹配；`godot-sdcpp` 维护和许可证信息不足，因此没有安装。正式风格图仍按 `art/ART_DIRECTION.md` 的提示词模板生成，再由 UI 在实际界面审稿。

## 安装范围

- 插件源码安装到 `addons/AsepriteWizard/`。
- 已在 `project.godot` 的 `[editor_plugins]` 中启用。
- 未引入运行时脚本、存档字段、玩法规则或正式资源路径变更。

## 验证

- Godot 4.7.2 headless 编辑器启动检查通过。
- 插件配置、脚本和许可证文件已纳入仓库。
- 下一步美术工作可在编辑器的 `Project > Tools > Aseprite Wizard` 中导入候选资源，再由 UI 在实际界面审稿后迁移为正式资源。
