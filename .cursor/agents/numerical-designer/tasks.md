# Tasks · numerical-designer

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

### NU-01 · 整治期数值冻结守门
- status: doing
- 来源: ADR-0031
- 改哪些: 无（不改公式/balance 全局参数除非版本授权）
- 完成标准: 无静默平衡改动
- 怎么验: data/balance diff 为空或仅有授权条目
- 阻塞: 无（持续）

### NU-02 · 身份/敌人美术补洞的数值无涉确认
- status: todo
- 来源: art ART-02/03（仅换图）
- 改哪些: 报告一句确认「不改金额/血量」
- 完成标准: 书面确认美术换皮不触发数值任务
- 怎么验: 产品/玩法无异议
- 阻塞: 无

### NU-03 · 开版后平衡复核模板
- status: blocked
- 来源: ACTIVE_PLAN D-03
- 改哪些: data/balance、tools/simulation（开版后）
- 完成标准: 模拟入口与报告
- 怎么验: simulation 测试或抽样记录
- 阻塞: 须开版

## 已完成（近期）

### NU-done-R0-08-followup · simulation 输出校验条件化
- status: done
- 证据: 相关 test commit（采样输出缺失时不误伤）
