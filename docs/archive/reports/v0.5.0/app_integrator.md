# v0.5.0 / 应用集成

## 状态

- 版本：`v0.5.0`
- 角色：应用集成开发
- 任务：把真实固定路线、休息、首领、晋升仪式、成长页面与检查点接成完整短路线
- 状态：完成
- 最后更新：2026-11-08
- 下一步入口：全量回归、产品验收和版本检查点

## 本版本目标

将 v0.4 的单遭遇 `CampaignSession` 路由升级为 v0.5 `RouteSession` 主链：

```text
身份选择
-> 五节点路线地图
-> 三场战斗
-> 奖励 / 祈愿 / 升级
-> 休息二选一
-> 首领
-> 三步仪式
-> 序列 8「小丑」
-> 路线检查点与继续
```

## 依赖

- 玩法：`RouteEngine`、`RouteSnapshot`、`RitualSnapshot`、`SequenceState`。
- 数据层：`RouteSession`、`Bootstrap.start_route()`、`inspect_route_checkpoint()`、v3 存档。
- UI：路线、休息、仪式、路线结算、战斗和 v0.4 成长页面。
- 美术：v0.5 路线、休息、仪式和镜厅男爵资源已完成 UI 实机审稿。

## 完成内容

- `AppController` 改用 `AppBootstrap.start_route()` 和 `RouteSession`。
- 新游戏进入身份页，选择身份后进入路线地图。
- 战斗节点通过 `RouteSession.begin_route_battle()` 创建真实战斗；不重复发送底层 `select_node`。
- 休息节点先选择节点，再进入独立休息页面；两种休息命令直接提交给路线领域。
- 首领胜利后回到奖励，领奖后显示可进入的晋升节点。
- 完成三步仪式后进入路线结算，显示序列 8「小丑」。
- 仪式可取消、重新进入、错误增加污染，最终完成写入检查点。
- 继续游戏按 `RouteSnapshot.phase` 恢复至地图、休息、仪式、奖励或路线结算。
- v3 检查点摘要保留身份、当前节点、完成节点数、收藏、票、保底、序列和上一战。
- 损坏检查点禁止继续并保留原文件。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 理由 |
|---|---|---|---|
| 路线页点击战斗节点会发出 `select_node`，但 `begin_route_battle()` 内部也会选择节点 | 修改 UI；直接透传 `select_node`；按节点类型分流 | 应用层识别 battle/rest/ritual 并分流 | 避免重复选择、重复保存，也不越权修改 UI |
| 继续游戏若只看成长 phase，会错误回到 hub | 只恢复成长页；按路线 phase 分发；重建战斗 | 按路线 phase 分发 | 休息、仪式和完成状态的事实源属于 RouteSnapshot |
| 领奖后路线和成长同时变化 | 固定回 hub；固定回路线；读取当前快照决定 | 领奖后回到路线地图 | 保留路线上下文，同时可从路线进入 hub 使用祈愿/升级 |
| 失败结果与 v0.4 单战结果页语义不同 | 复用旧结果页；创建新结果页；复用 v0.5 路线结算 | v0.5 统一使用路线结算页 | 失败与晋升结果共享检查点和路线信息 |

## 验证

```text
APP_V05_INTEGRATION_OK checks=73

PASS infrastructure tests: 150
ROUTE_BACKEND_TESTS_OK checks=59
GAMEPLAY_TESTS_OK checks=131
PROGRESSION_TESTS_OK checks=90
ROUTE_TESTS_OK checks=96
UI_SMOKE_OK checks=33
PROGRESSION_UI_SMOKE_OK checks=41
V05_ROUTE_UI_SMOKE_OK checks=58
SIMULATION_TESTS_OK checks=33
V04_ECONOMY_TESTS_OK checks=54
V05_ROUTE_TESTS_OK checks=43
main scene --quit-after 5: exit 0
```

集成测试使用真实 UI 信号和真实领域会话，覆盖：

- 身份选择、五节点路线、首战、精英战、首领战。
- 节点间单抽、碎片升级和路线继续。
- 休息节点返回标题后准确继续。
- 仪式取消、重新进入、错误污染和正确晋升。
- 序列 8 持久化、继续恢复和损坏存档保护。

## 风险

- 当前仅支持一条固定路线和战斗节点边界检查点；战斗中退出会回到上一个节点。
- 路线 UI 暂不显示仪式提示的灵性成本，原因是只读 `RitualSnapshot` 尚无该字段；领域会拒绝资源不足。
- 数值路线完成率与节奏仍由产品经理复核，应用接线不调整平衡。

## 跨角色请求

```text
[REQUEST]
从：应用集成开发
给：玩法设计
版本：v0.5.0
内容：RitualSnapshot 可增加只读 hint_spirit_cost 字段
原因：UI 目前只能提示“消耗灵性”，无法显示精确 1 点成本
优先级：非阻塞，可由后续补丁版本处理
[END REQUEST]
```

## 下一步入口

执行全量回归、产品验收、资源路径检查和 Git 检查点；v0.5 通过后再规划更长路线。
