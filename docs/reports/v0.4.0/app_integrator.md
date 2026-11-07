# v0.4.0 / App 短循环集成

## 状态

- 版本：`v0.4.0`
- 角色：主协调者 / App 集成
- 任务：把身份、战斗、奖励、祈愿、升级和检查点接成可实际操作的主链
- 状态：完成；等待数值角色修复一处过期测试夹具后做最终总验
- 最后更新：2026-11-08
- 下一步入口：全量回归通过后由产品经理关闭 `v0.4.0`

## 本版本目标

把已完成的领域、存档和 UI 页面接入同一个 app 控制器，使玩家可以实际完成：

```text
启动 -> 身份选择 -> hub -> 战斗 -> 胜利奖励 -> 祈愿 -> 升级 -> 再战 -> 保存/继续
```

## 依赖

- `CampaignSession` 提供的成长与战斗用例。
- `AppBootstrap.start_campaign()`、`inspect_checkpoint()`。
- `ProgressionSnapshot`、`ProgressionCommand`、`ProgressionCommandResult`。
- UI 四页的信号、只读快照和配置接口。
- `assets/game/v0.4.0/**` 正式资源。

## 已实现

### 路由

`src/app/app_controller.gd` 现在支持：

- `start`
- `identity`
- `hub`
- `battle`
- `reward`
- `gacha`
- `upgrade`
- `result`

新游戏从启动页进入身份选择；继续游戏根据检查点中的成长阶段恢复到身份页、hub 或奖励页。

### 命令接线

- 身份页 `identity_selected` -> `CampaignSession.submit_progression(SelectIdentity)`。
- hub `battle_requested` -> `CampaignSession.begin_battle()` -> 战斗页。
- 战斗 `command_requested` -> `CampaignSession.submit_battle()` -> UI 结果。
- 胜利 `battle_finished` -> 奖励页；失败 -> 结果页。
- 奖励 `reward_claimed` -> `ClaimReward` -> 刷新 hub。
- 祈愿 `draw_requested` -> `DrawGacha` -> 页面接收真实结果。
- 升级 `upgrade_requested` -> `UpgradeCard` -> 页面接收新等级和残页状态。
- 升级后的 `CampaignSession.begin_battle()` 自动使用 owned deck、身份修正和 upgraded content port。

### 显示数据

- 卡牌名和敌人名来自 `CampaignContentCatalog`。
- 升级预览由 app 通过 `UpgradedBattleContentPort` 生成只读文本，UI 不重新计算公式。
- 祈愿页在 app 中注入正式卡牌显示名。
- UI 仍只接收快照、稳定原因码和页面命令。

### 检查点

- 每次成功成长命令、战后结算和升级后都由 `CampaignSession` 原子保存。
- 启动摘要通过 v0.4 `inspect_checkpoint()` 读取。
- 继续游戏使用 `resume_from_checkpoint=true`，不会把战斗中间状态恢复成可玩状态。
- 损坏检查点保持原文件并禁用继续。

## 修改文件

- `src/app/app_controller.gd`
- `tests/integration/app_flow_runner.gd`
- `tests/integration/README.md`

未修改 gameplay、core、UI、schema、balance、art、assets 或 `project.godot`。

## 验证

真实集成测试：

```text
APP_V04_INTEGRATION_OK checks=39
```

覆盖：

- 启动页信号创建新 campaign。
- 身份选择和 hub。
- hub 进入正式双敌人战斗。
- 通过 UI 选择手牌、目标、出牌和结束回合。
- 胜利进入二选一奖励。
- 领取墨刺残页。
- 单抽扣除两张占卜券并显示真实结果。
- 使用残页将墨刺升到 1 级。
- 升级等级保留到下一场战斗。
- 返回标题显示 loaded checkpoint。
- 继续游戏恢复身份、收藏和升级状态。
- 损坏检查点禁用继续且显示错误。

主场景解析：

```text
Godot 4.7.2 --headless --quit-after 5: exit 0
```

本轮全量回归结果：

- infrastructure：`150 passed`
- gameplay：`131 checks`
- progression：`90 checks`
- UI：`21 checks`
- progression UI：`41 checks`
- simulation contract：`33 checks`
- app integration：`39 checks`
- economy contract：当前失败，见下方跨角色请求

## 困难与解决

| 困难 | 候选方案 | 最终选择 |
|---|---|---|
| 旧控制器只认识单场 `GameSession` | 保留旧路由并新增旁路；替换控制器主流程；维护两套模式 | 替换为 `CampaignSession` 单主流程，v0.3 类保留作兼容入口 |
| UI 需要升级前后效果文本 | UI 自己回读卡牌金额；app 生成预览；新增只读接口 | app 使用正式升级内容装饰器生成每级展示文本 |
| 从检查点继续时阶段不同 | 一律进入 hub；按成长 phase 路由；一律重新开始第一战 | 根据 `identity_selection/hub/reward` 路由，不恢复战斗中间状态 |
| 胜利结果与奖励页重复 | 胜利仍展示结果页再进入奖励；直接显示奖励；双按钮确认 | 胜利直接进入奖励；失败保留结果页 |
| 下一战可能带入未拥有卡 | 修改遭遇数据；运行时忽略缺卡；owned deck 过滤 | `CampaignSession` 使用 `build_owned_battle_deck()` |

## 风险与未决问题

- 启动页摘要仍只显示内容版本、序列、牌组和上一战；身份、占卜券、稀有保底和收藏数量需要在 UI 侧补显示。
- 启动页页脚仍写着 `v0.3.0`，属于 UI 文案，需在 UI 所有权内更新。
- 失败结果页“再进行一场”实际返回 hub，文案可能需要 UI 调整为“返回白昼档案”。
- 战斗仍不支持中途恢复，这是当前冻结规则。
- 当前祈愿、奖励和升级的经济已由数值与玩法测试覆盖，但尚未进行人工长时间试玩。

## 跨角色请求

```text
[REQUEST]
从：App 集成
给：数值设计
版本：v0.4.0
内容：`tests/simulation/v04_economy_contract_runner.tscn` 仍断言祈愿池有 8 张卡，但玩法前向修复后正式池为 7 张可升级卡。
原因：`card.skill.second_look` 已从祈愿池移除，避免产生无法消费的重复残页；数值测试夹具过期。
期望接口：更新断言/报告并重跑 `V04_ECONOMY_TESTS_OK`，不修改正式卡池规则。
截止检查点：v0.4.0 关闭前
[END REQUEST]
```

```text
[REQUEST]
从：App 集成
给：UI 设计
版本：v0.4.0
内容：启动页更新为 v0.4.0，并显示 checkpoint 摘要中的 identity_id、divination_tickets、pity_counter、collection 数量。
原因：后端已经提供字段，但当前启动页未呈现成长进度。
期望接口：继续只消费 checkpoint summary，不读取存档文件。
截止检查点：v0.4.0 最终验收前
[END REQUEST]
```

## 下一步入口

1. 数值角色修正过期 economy 测试夹具。
2. UI 更新启动页版本和成长摘要。
3. 主线程重跑九组测试、主场景 smoke 与 `git diff --check`。
4. 截图验证短循环页面并建立 v0.4 检查点。
