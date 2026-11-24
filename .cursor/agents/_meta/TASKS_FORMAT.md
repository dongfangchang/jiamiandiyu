# 角色任务文档协议

每个固定角色在 `.cursor/agents/<role>/tasks.md` 维护待办。

## 强制纪律

1. **先立任务，后执行**：动手改生产文件前，必须在本角色 `tasks.md` 有对应条目（`status: todo` 或 `doing`）。
2. **开工**：读 `tasks.md` → 选一条标 `doing` → 再读 journal / REGISTRY。
3. **收工**：完成则标 `done` 并写一行证据；取消则标 `cancelled` 并写原因；未完保持 `todo`/`doing`。
4. **范围**：只写本角色可编辑目录内的事；跨角色依赖写成「阻塞于 / 请求某某」而不是去改别人的文件。
5. **与 ACTIVE_PLAN**：产品级条目仍以 `docs/ACTIVE_PLAN.md` / 版本文档为准；`tasks.md` 是角色可执行拆解，ID 尽量对齐（如 `R0-11`、`ART-desk-wood`）。

## 条目模板

```markdown
### <ID> · <一句话标题>
- status: todo | doing | done | cancelled | blocked
- 来源: ACTIVE_PLAN / 用户口述 / 报告 / 自发现
- 改哪些: 路径或目录
- 完成标准: …
- 怎么验: …
- 阻塞: （无则删此行）
- 证据: （done 时必填）
```

## 禁止

- 空壳大方向（「优化美术」）——必须可勾销。
- 执行完了却不更新 status。
- 把别的角色的活写进自己的 tasks 并擅自开干。
