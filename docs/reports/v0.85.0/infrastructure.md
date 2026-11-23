# v0.85.0 本地数据层依赖评审

- 角色：本地数据层开发
- 任务：评审日记标题与正文使用完整简体思源宋体
- 状态：本地数据层静态评审通过，运行时和导出验收由 UI 与主协调者执行

| 项目 | 评审结果 |
|---|---|
| 上游版本 | Adobe Source Han Serif SC Regular，`2.003R`，提交 `7889f11bf31170b5d092a083b357c8c8130f89e0`。 [官方发布](https://github.com/adobe-fonts/source-han-serif/releases/tag/2.003R) |
| 原始资源 | `OTF/SimplifiedChinese/SourceHanSerifSC-Regular.otf`，24,543,332 字节（23.41 MiB），Git blob `cb41635674be23029e98469f729eded6ebc54611`。 [上游原文件](https://github.com/adobe-fonts/source-han-serif/blob/2.003R/OTF/SimplifiedChinese/SourceHanSerifSC-Regular.otf) |
| 授权 | SIL OFL 1.1。保留 Adobe 2017–2022 版权行、保留字体名称 `Source` 以及完整许可文本。仓库与交付给他人的构建都随附上游授权。 [上游许可](https://github.com/adobe-fonts/source-han-serif/blob/2.003R/LICENSE.txt) |
| 引入理由 | 日记标题需要宋体笔锋，正文需要印刷书页质感。Godot 自带 `FontFile` 导入能力，项目现有 Noto Sans 用于旁注与宋体缺字回退。字体从 `res://` 加载，离线随包运行。 |
| 体积与维护 | 保留一份完整字库，标题字重由 UI 表现控制。原始 OTF 增加约 23.41 MiB，最终包体以导出结果为准。更新时同步固定版本、SHA-256、授权文本与字形覆盖验证。 |
| 存档与移除 | 字体接在 UI 主题层，存档结构、内容数据与规则无需迁移。移除时让日记主题沿用现有 Noto Sans，再删除思源宋体及其导入元数据和独立授权文件。 |

已通过 GitHub API 核验标签提交、官方字体文件大小和 Git blob，并核对上游 `LICENSE.txt`。此前配置的导出预设使用 `all_resources`，许可证 `.txt` 需核实是否随包，或在分发目录附带。未执行 Godot 导入、导出或字形渲染验证。运行时复核时，以 `FontFile` 自身的字符覆盖与实际日记截图分别验证字库和排版，并检查缺失字形能否回退到随项目分发的 Noto Sans。

本地数据层同意产品经理采纳完整上游 OTF。裁剪字库虽可节省体积，但需要随内容更新重生成并维护授权名称与覆盖验证，本次保留原件。主协调者登记文件来源、版本、SHA-256 与授权，并在独立构建分发前验收许可证随包。
