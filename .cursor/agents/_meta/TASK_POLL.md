# 角色任务轮询（架构师下发）

> 主会话用 **4 分钟** 固定 loop 唤醒后执行本协议。  
> 停止：用户说「停止轮询」→ 杀掉 loop PID（见 `.cursor/agents/_meta/task_poll.pid`）。

## 每轮做什么

1. 读 `docs/CURRENT_VERSION.md`（确认当前版，勿做错版）。
2. 扫描全部 `.cursor/agents/*/tasks.md`。
3. 挑出**可执行**条目，条件同时满足：
   - 落在「架构师下发」区块内，或 `来源` 含 ADR-0032 / EXPERIENCE / ROADMAP X* / 架构师；
   - `status` 为 `todo` 或 `doing`；
   - **无** `阻塞:`，或阻塞条件已客观解除（证据在 tasks/报告里）；
   - **无** `owner: 主会话`（勿重复开工）。
4. 按角色委派对应 subagent（art / ui-designer / coordinator / …），**并行**启动可互不抢文件的条目。
5. 同角色多条：优先 `doing`，否则按文件中从上到下第一条 `todo`。
6. 本轮若无可执行项：在聊天里用一行写「轮询空转」+ 仍 blocked 的前 3 条 ID；**不要**空转刷大段报告。
7. 有委派则等其自然完成通知；不要在本轮里串行做完全部角色的全部活。

## 禁止

- 不开新版、不改产品范围。
- 不碰 `owner: 主会话` 文件集。
- 不做「看起来像下发」但 blocked 的假开工。
- 不重复启动已在跑的同 ID 任务。

## Loop 臂装

```bash
# 仓库根；PID 写入 _meta/task_poll.pid
while true; do
  sleep 240
  echo 'AGENT_LOOP_TICK_role_tasks {"prompt":"按 .cursor/agents/_meta/TASK_POLL.md 执行一轮角色任务轮询"}'
done
```

哨兵正则：`^AGENT_LOOP_TICK_role_tasks`
