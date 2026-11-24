---
name: agent-skill-loop
description: 子智能体可迭代技能框架。任务开始时发现并复用 Skill/Tool；收工时强制自省五问、写 journal/draft、登记工具并申请晋升。任何固定角色 agent 在实质性工作收尾时使用。
---

# Agent Skill Loop

## 何时用

- 角色 agent 开始任务前（Discover）
- 实质性改动收工时（Reflect / Promote）
- 用户要求「沉淀技能」「复盘」「注册工具」时

## 指令

1. 打开并遵循：`.cursor/agents/_meta/SKILL_LOOP.md` 与 `_meta/TASKS_FORMAT.md`。
2. 读并维护：`.cursor/agents/<role>/tasks.md`（**先立任务后执行**）。
3. 读本角色：`.cursor/agent-memory/<role>/journal.md`。
4. 查：`.cursor/skills/REGISTRY.md` 与 `.cursor/agents/_meta/TOOL_REGISTRY.md`。
5. 执行任务时优先复用已有 Skill / tool recipe。
6. 收工更新 tasks status；写 Retro 五问；有可复用步骤则写 `drafts/`；满足晋升条件则更新 REGISTRY 并新建/改 `SKILL.md`。
7. 新命令追加进 `TOOL_REGISTRY.md`，勿塞本机绝对盘符。
8. **推送纪律**：`.cursor/agents|skills|agent-memory|rules`（含 tasks）有变更时与代码一并 commit/push。
9. **跨项目**：多仓通用内容写用户级 `~/.cursor/agents/` 与用户 Agent Store `skills/`；本仓专用留在 `.cursor/**`。项目缺协议时回退用户级 `_meta/SKILL_LOOP.md`。

## 最小可交付

- `tasks.md` 当前工作有条目且状态正确。
- journal 至少一行 Retro，或报告中含同等五问。
- 若宣称「学会了新技能」，必须有 Draft 或 REGISTRY 变更路径。
