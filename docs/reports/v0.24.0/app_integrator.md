# v0.24.0 / Windows 集成适配记录

## 状态

- 状态：完成
- 最后更新：2026-11-09
- 任务：拉取远端更新并适配 Windows

## 拉取

- 远端：`https://github.com/dongfangchang/jiamiandiyu.git`
- 拉取前：`c67a2d1`
- 拉取后：`aa6ef1d`
- 方式：`git pull --ff-only`
- 远端新增 `v0.15.0` 至 `v0.24.0` 文档、UI 体验改进和 macOS 启动器。

## Windows 检查

- `project.godot` 主场景和渲染配置可直接加载。
- `play.cmd`、`open-editor.cmd` 使用项目相对路径。
- Godot 4.7.2 Windows 编辑器与 console 可执行文件存在。
- `.gitattributes` 保持 `.cmd` 为 CRLF、Shell 脚本为 LF。
- 运行时代码未发现 macOS 绝对路径或 AppleScript 依赖。
- 两个 Windows 启动器增加参数透传，便于 headless 自动验证。
- QA 脚本从 `project.godot` 动态读取产品版本。
- QA 脚本纳入远端新增 v0.18 平衡审计和 v0.20 预设指标测试。

## 验证

```text
Godot import: PASS
V018_DECK_BALANCE_AUDIT_OK checks=81 presets=4
V020_PRESET_METRICS_OK checks=72 presets=4
V0.14.0 QA PASS: 40 checks
WINDOWS_COMPAT_OK
Windows external smoke: PASS
```

- 完整 Windows QA 40 组通过。
- `play.cmd` 和 `open-editor.cmd` headless smoke 通过。
- Windows 独立构建及项目目录外启动通过。
- 构建版本：`MaskWhispers_v0.14.0.exe`
- 构建大小：`123945536` 字节
- SHA-256：`6EBF7DFE118BD57FBEADC979156C18A074E04FB9662C7E316E99634029DA0045`

## 风险

- GitHub 拉取依赖本机 Clash 代理端口 `127.0.0.1:7890`；代理退出时 fetch 会失败。
- v0.24.0 仍处于规划中，当前代码版本字段仍为 `0.14.0`，因此界面显示 0.14 而不是文档规划号。
