---
name: godot-probe-gate
description: 运行 Godot 无窗口探针与默认测试门。改 UI/日记桌/集成后验证用；优先复用 TOOL_REGISTRY 中的命令。
---

# Godot Probe Gate

## 步骤

1. 查 `.cursor/agents/_meta/TOOL_REGISTRY.md` 是否已有对应 `run`。
2. 默认全量：`tools/run_tests.sh`。
3. 日记桌相关：跑 `v083_diary_desk_p0_runner`（见 Registry `v083-diary-desk`）。
4. 记录退出码与关键 OK 行到角色报告「验证」。
5. 失败则按 AGENTS Bug 门：复现 → 根因 → 前向修；禁止叠补丁。

## 注意

- Godot 二进制用 `.tools/` 或环境变量；Skill/Registry **禁止**写死他人机器路径。
- 需要 GPU 的截图 runner 不进默认门（见 AGENTS）。
