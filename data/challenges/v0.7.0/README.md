# v0.7.0 挑战内容

本目录包含第一挑战和第二挑战：

- `challenge.v060.mirror_echoes`：既有镜厅余响。
- `challenge.v070.broken_procession`：完成第一挑战后解锁的破碎游行。

第二挑战引用独立路线 `route.v070.broken_procession`，精英和首领节点使用不同遭遇，不使用虚增生命作为唯一差异。

新增修饰：

- `modifier.obituary_echo`：额外污染，提高完成奖励。
- `modifier.twin_shadow`：提高初始被注视，提高残页奖励。
- `modifier.ritual_vigil`：敌人阶段提前一回合，下一战灵性上限增加。

挑战解锁要求位于 `required_challenge_ids`。完成记录由 `SequenceState.completed_challenge_ids` 持久保存，UI 不自行推导。
