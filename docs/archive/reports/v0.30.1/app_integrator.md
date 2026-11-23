# v0.30.1 / 主协调集成记录

## 状态

- 版本：`v0.30.1`
- 角色：主协调者
- 任务：拉取远端最新代码并按默认流程更新 Windows 构建
- 状态：部分完成
- 最后更新：2026-11-09

## 拉取结果

- 拉取前：`f85a186`
- 拉取后：`ad1d334`
- 方式：`git pull --ff-only origin main`
- 远端新增 v0.27.0 至 v0.30.3 的实现、攻击系统、字体、路线数据和测试。
- `project.godot` 与当前产品版本文档保持 `0.30.1`；构建包含后续 v0.30.2、v0.30.3 提交。

## 构建阻断与根因

- 首次构建失败：`addons/AsepriteWizard/plugin.gd` 预加载的
  `addons/AsepriteWizard/export/export_plugin.gd` 不存在。
- 根因：`.gitignore` 使用无锚点的 `export/`，误匹配插件内部
  `addons/AsepriteWizard/export/`，导致上游插件文件在提交时被静默忽略。
- 修复：
  - 将忽略规则收紧为 `/export/`，只忽略项目根目录导出目录。
  - 从插件记录中固定的上游提交
    `18ebea9868ea567782ae9e53b27ad260dbc8e062`
    恢复 `export_plugin.gd` 及其 UID。
  - 在 Windows 导出预设中排除编辑器专用的 `addons/*`，避免插件进入运行时包。
  - 构建脚本保留 Godot stderr 诊断，但以进程退出码判断构建成败，避免把
    AsepriteWizard 的编辑器退出告警误判为构建失败。

## 修改文件

- `.gitignore`
- `build-windows.ps1`
- `export_presets.cfg`
- `addons/AsepriteWizard/export/export_plugin.gd`
- `addons/AsepriteWizard/export/export_plugin.gd.uid`
- `docs/reports/v0.30.1/app_integrator.md`

## 构建与验证

- Windows 构建：`build/windows/MaskWhispers_v0.30.1.exe`
- 大小：`142741016` 字节
- SHA-256：
  `746D5AC99311DC879CC03AC27D69AB710A852847964B036F38BC22FF5A220EF6`
- 项目目录外 headless 启动：PASS
- `WINDOWS_COMPAT_OK`：PASS
- `git diff --check`：PASS

## 全量 QA 未通过项

- `infrastructure`：147 项通过，3 项失败。
  - `runtime enemy ID should be deterministic`
  - `catalog should reject missing enemy references`
  - `catalog should reject duplicate enemy lanes`
- `v013_card_pack`：2 项失败。
  - `镜中余响` 预设未使用 `card.skill.mirror_ward`
  - `镜中余响` 预设未使用 `card.skill.severed_string`

这些失败来自本轮拉取后的远端代码，不影响 Windows 导入、独立导出和项目外启动，
但表示当前代码未通过完整版本门。

## 困难与候选方案

- 候选方案一：禁用 AsepriteWizard。该方案会丢失已批准的美术导入工作流。
- 候选方案二：写占位导出插件。该方案会保留错误契约并掩盖缺件。
- 最终选择：修正忽略规则，从同一固定上游提交恢复原文件，并阻止编辑器插件进入运行时包。

## 风险与未解决问题

- 游戏包可启动不代表全量 QA 通过；上述 5 个断言仍需对应玩法、数据层和 UI 负责人定位。
- 当前版本号 `0.30.1` 落后于提交标题中的 `v0.30.3`，需要产品经理决定是否升版或新建补丁文档。
- AsepriteWizard 是编辑器插件，当前不计入游戏运行时依赖。

## 跨角色请求

- 玩法/数据层：核对敌人 ID 确定性、缺失敌人引用和重复敌人列校验。
- 玩法/UI：确认 `镜中余响` 预设是否应更新，或旧 v0.13 断言是否已经过时。
- 产品经理：统一当前运行版本号与最新提交命名。

## 下一步入口

1. 修复或更新上述 5 个失败断言。
2. 运行全量 QA 和实际窗口回归。
3. 通过后重新导出并替换 `MaskWhispers_v0.30.1.exe`。
