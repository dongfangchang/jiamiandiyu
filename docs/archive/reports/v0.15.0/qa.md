# v0.15.0 / QA 工作记录

## 状态

- 状态：通过
- 当前任务：验证 macOS 编辑器与试玩启动脚本
- 最后更新：2026-11-08

## 验收结果

| 检查 | 命令或路径 | 结果 |
|---|---|---|
| Shell 语法 | `zsh -n open-editor-mac.sh`、`zsh -n play-mac.sh` | PASS |
| 试玩启动 | `./play-mac.sh --headless --quit-after 1` | PASS，退出码 0 |
| 编辑器启动 | `./open-editor-mac.sh --headless --quit-after 1` | PASS，退出码 0 |
| 缺少运行时 | 临时副本在无 `.tools/` 环境执行 `play-mac.sh` | PASS，退出码 1，提示 Godot runtime 路径 |
| 缺少编辑器 | 临时副本在无 `.tools/` 环境执行 `open-editor-mac.sh` | PASS，退出码 1，提示 Godot editor 路径 |
| 参数透传 | 两个脚本均将 `"$@"` 传给 Godot；headless 参数已实际验证 | PASS |
| 格式检查 | `git diff --check` | PASS |
| Windows 入口 | `git diff --quiet -- play.cmd open-editor.cmd` | PASS，未修改 |

## 证据与风险

- 本机 Godot 版本为 `4.7.2.stable`，项目 headless 启动退出码为 `0`。
- 编辑器 headless 检查会输出一次 `Scan thread aborted` 警告，但进程退出码为 `0`，且项目扫描完成；未观察到脚本错误或运行阻断。
- 缺失依赖测试使用 `/tmp` 临时副本，没有改名、删除或修改项目内 `.tools/`。
- 未运行 Windows 构建；本补丁不修改 Windows 脚本或构建配置。

## 结论

v0.15.0 规定的 macOS 启动脚本验收项全部通过，可交由产品经理关闭版本并建立 Git 检查点。
