# 《假面低语》固定角色智能体

本目录是 **项目级长期 Subagent**（随仓提交）。Cursor 会在本仓库会话中识别它们，可被主对话委派，也可你直接点名调用。

## 角色一览

| 文件 | 何时用 |
|---|---|
| `product-manager.md` | 开版/关版、范围裁决、验收、ADR、ACTIVE_PLAN |
| `architect.md` | 分层边界、重构路线、跨层拆分评审 |
| `coordinator.md` | 派工并发、集成验收、迁 `assets/game`、测门 |
| `ui-designer.md` | `src/ui` / 场景 / UI 资产 / UI 测试与审稿 |
| `art.md` | `art/**` 出图、生成脚本、美术报告（不迁正式 assets/game） |
| `gameplay-designer.md` | 规则/状态机、`data/cards|enemies|…`、玩法测试 |
| `numerical-designer.md` | `data/balance`、模拟与数值报告 |
| `local-backend.md` | `src/app` / `infrastructure`、schema、存档与 RNG |

## 怎么用

```text
用 art 智能体：按 ART_BRIEF_V085 重画 battle-elliot-ruin
用 ui-designer：把八开日记竖图接到 diary 左页并跑 V083
用 product-manager：根据 ACTIVE_PLAN 排下一开版范围
```

## 硬约束（所有角色共用）

1. 开工先读：`AGENTS.md` → `docs/CURRENT_VERSION.md` → 当前 `docs/versions/<ver>.md` → 本角色报告。
2. **只改自己可编辑目录**；跨角色改文件先写报告请求，由产品经理裁决。
3. 官方进度只写 `docs/reports/<version>/<role>.md`，聊天不能替代。
4. UI ≠ 美术验收：美术交候选，UI 真窗口审稿；正式 PNG 仅主协调者迁入 `assets/game/**`。
5. 单向依赖：`ui → app → gameplay → core`；玩法不碰 `Control`/`FileAccess`。

协作协议全文：`docs/TEAM_PROTOCOL.md`。

## 任务队列（先立后做）

每个角色目录：`.cursor/agents/<role>/tasks.md`  
协议：`_meta/TASKS_FORMAT.md`。

| 角色 | 任务文件 |
|---|---|
| product-manager | `product-manager/tasks.md` |
| architect | `architect/tasks.md` |
| coordinator | `coordinator/tasks.md` |
| ui-designer | `ui-designer/tasks.md` |
| art | `art/tasks.md` |
| gameplay-designer | `gameplay-designer/tasks.md` |
| numerical-designer | `numerical-designer/tasks.md` |
| local-backend | `local-backend/tasks.md` |

**纪律**：无匹配任务条目不得改生产文件；开工标 `doing`，收工标 `done`/`cancelled` 并写证据。

## 技能框架（自学循环）

| 组件 | 路径 |
|---|---|
| 循环协议 | `_meta/SKILL_LOOP.md` |
| 任务格式 | `_meta/TASKS_FORMAT.md` |
| 工具注册 | `_meta/TOOL_REGISTRY.md` |
| 技能成品 | `../skills/` + `REGISTRY.md` |
| 角色记忆 | `../agent-memory/<role>/` |

主 Skill：`agent-skill-loop`。

### 推送纪律（学习内容必进远端）

提交/推送时**必须包含**若有变更的：

- `.cursor/agents/**`（含各 `tasks.md`）
- `.cursor/skills/**`
- `.cursor/agent-memory/**`
- `.cursor/rules/**`

禁止把 journal/drafts/tasks 留在本机不推。跨项目通用框架另见用户级 `~/.cursor/agents/` 与用户 Agent Store 的 `skills/`。
