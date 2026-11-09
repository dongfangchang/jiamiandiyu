# 中文 UI 字体

- 文件：`NotoSansCJKsc-Regular.otf`，上游原始文件名与内容保持不变。
- 项目：Noto CJK，https://github.com/notofonts/noto-cjk
- 固定版本：`Sans2.004`。
- 上游提交：`523d033d6cb47f4a80c58a35753646f5c3608a78`。
- 来源：https://raw.githubusercontent.com/notofonts/noto-cjk/523d033d6cb47f4a80c58a35753646f5c3608a78/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf
- SHA-256：`2c76254f6fc379fddfce0a7e84fb5385bb135d3e399294f6eeb6680d0365b74b`。
- 许可证：SIL Open Font License 1.1，完整授权见同目录 `OFL.txt`（上游同提交根目录 `LICENSE`）。
- 用途：共享 UI 主题直接加载完整简体字库，保证离线运行及跨平台字形一致，不依赖操作系统字体回退。
- 成本：原文件 16,437,364 字节，无运行时代码或网络依赖；后续更新必须同步版本、授权、散列和字形覆盖测试。
- 验证：`tests/ui/v030_font_runner.gd` 扫描 UI 和内容数据中的中文字符；不带 `--headless` 时额外生成真实渲染截图。
