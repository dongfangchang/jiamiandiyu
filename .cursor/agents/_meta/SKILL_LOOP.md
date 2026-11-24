# 子智能体技能循环（发现 → 沉淀 → 复用 → 优化）

> 目标：让固定角色 **看起来像在自学进步**。机制是**可审计的文件沉淀**，不是神秘权重更新。  
> 每次实质性任务结束，角色必须跑完本循环一圈（短任务可合并进报告一节）。

## 0. 名词

| 名词 | 位置 | 含义 |
|---|---|---|
| **Skill** | `.cursor/skills/<id>/SKILL.md` | 可被点名或自动触发的标准作业 |
| **Draft** | `.cursor/agent-memory/<role>/drafts/*.md` | 未晋升的经验草稿 |
| **Journal** | `.cursor/agent-memory/<role>/journal.md` | 角色时间线（失败/成功/下次怎么改） |
| **Tool recipe** | `.cursor/agents/_meta/TOOL_REGISTRY.md` | 可复用命令/脚本/探针入口 |
| **REGISTRY** | `.cursor/skills/REGISTRY.md` | 全仓技能目录与状态 |

状态机：`draft` → `candidate` → `stable` → `deprecated`

## 1. 开工（Discover）

0. **先任务后动手**：读 `.cursor/agents/<role>/tasks.md`；无匹配条目则先写入再执行（见 `_meta/TASKS_FORMAT.md`）；将当前条标 `doing`。
1. 读本角色 `journal.md` 最近 5 条。
2. 读 `.cursor/skills/REGISTRY.md`，按任务关键词匹配 Skill。
3. 若命中 `stable`/`candidate`：先按 Skill 执行，再动手发明流程。
4. 查 `TOOL_REGISTRY.md` 是否已有命令；有则复用，勿另起炉灶。

## 2. 执行中（Instrument）

- 只改本角色可编辑目录（见 agent 定义）。
- 新踩坑立刻记一行到 **Draft**（症状 / 根因 / 试过的无效招 / 有效招）。
- 新命令若跑通：登记到 Tool Registry（或 Draft 里先写，事后晋升）。

## 3. 收工自省（Reflect）— 强制五问

在角色报告或 `journal.md` 追加：

```markdown
### Retro · YYYY-MM-DD · <任务一句话>
1. 目标是否达成？证据（命令/路径/截图）？
2. 哪一步最耗时或最易错？
3. 可沉淀为 Skill 的步骤有哪些？（可复制清单）
4. 该进 Tool Registry 的命令是什么？
5. 下次同一类任务，第一条该读哪份 Skill/Draft？
```

同时更新 `tasks.md`：完成 → `done`+证据；未完保持；取消写原因。

再选一：

- **无新知** → 只记 journal 一行。
- **有可复用步骤** → 写/更新 Draft。
- **Draft 已在 ≥2 次任务验证** → 申请晋升（见 §4）。

## 4. 晋升（Promote）

写 Draft 或改 REGISTRY 时注明：

| 条件 | 动作 |
|---|---|
| 首次发现 | `drafts/<topic>.md`，状态 `draft` |
| 第二次同类任务仍适用 | 状态改 `candidate`，补 examples |
| 协调者/产品经理确认或三次成功 | 建成 `.cursor/skills/<id>/SKILL.md`，REGISTRY 标 `stable` |
| 流程过时 | `deprecated`，保留文件并指向替代 Skill |

晋升请求可写在角色报告「跨角色请求」：请 **coordinator** 或 **product-manager** 过一眼（不阻塞紧急修复）。

## 5. 优化（Optimize）

对已有 Skill：

- 失败一次：在 Skill 末尾加「失败模式」一节（不超过 15 行）。
- 连续成功且步骤变短：删冗余，更新 `description` 触发词。
- 与另一 Skill 重叠 >70%：合并，旧的 `deprecated`。

## 6. 诚实边界

- 本循环 **不** 自动改模型权重；进步 = 仓库里更好的作业说明书 + 工具表。
- 禁止为「显得会学」批量造空 Skill；无证据不晋升。
- 机密/本机绝对路径不得写入 Skill 或 Registry。

## 7. 推送与跨项目

- **本仓学习内容必须进 git**：`.cursor/agents/**`（含各角色 `tasks.md`）、`.cursor/skills/**`、`.cursor/agent-memory/**`、`.cursor/rules/**` 有变更时，与业务改动一并 commit/push，禁止只推代码。
- **跨项目通用框架**落在用户级：`~/.cursor/agents/`、`~/.cursor/agent-memory/`、用户 Agent Store 的 `skills/`（不随本仓推送，本机全项目可用）。
- 同名角色/技能：**项目级优先于用户级**。
