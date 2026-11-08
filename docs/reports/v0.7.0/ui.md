# v0.7.0 / UI 设计工作记录

## 状态

- 版本：`v0.7.0`
- 角色：UI 设计
- 任务：卡组编辑、出战牌组入口、双挑战入口与第二挑战页面
- 状态：完成；等待 app 真实接线和全量回归
- 最后更新：2026-11-08

## 依赖

- `DeckSnapshot`、`DeckCommand`、`DeckCommandResult`
- `ProgressionSnapshot.collection[].level`
- `ChallengeSnapshot.challenge_id`、`required_challenge_ids`、`completed_challenge_ids`
- `assets/game/v0.7.0/**`
- 现有 v0.3-v0.6 UI 主题、挑战和路线页面

## 已完成

### 卡组编辑

- 新增 `scenes/ui/deck_screen.tscn` 与 `src/ui/deck_screen.gd`。
- 16 卡收藏网格：卡面、名称、升级等级、灵性费用、目标类型、拥有状态和当前牌组状态。
- 8 槽当前出战牌组，支持单卡移出、加入、清空和恢复默认。
- 三套预设均可载入与覆盖保存；显示当前预设、合法状态、确认状态和稳定原因码。
- 支持“全部 / 已拥有 / 未拥有 / 当前牌组”筛选。
- 所有合法性、费用、拥有状态和升级等级来自快照；UI 只发送 `DeckCommand`。
- 身份 hub 新增当前牌组摘要与“调整出战牌组”入口。

### 挑战页面

- 新增 `scenes/ui/challenge_hub_screen.tscn`，同时展示“镜厅余响”和“破碎游行”。
- 第二挑战显示前置挑战、路线变体、三项修饰、奖励和锁定原因；未满足前置条件时不能发命令。
- `ChallengeScreen` 改为动态读取挑战 ID、名称、描述、路线和徽记。
- 新修饰图标映射：
  - `modifier.obituary_echo`
  - `modifier.twin_shadow`
  - `modifier.ritual_vigil`
- `ChallengeResultScreen` 动态显示第二挑战徽记与路线名称。
- 启动页挑战按钮改为“进入挑战档案”，保留原 `challenge_requested` 信号。

## 美术审稿

结论：**v0.7.0 原型范围通过**。

- 卡组背景 `deck_archive.png` 通过：标题、预设栏、16 卡网格和 8 槽牌组区域无冲突。
- 8 张新卡通过：在约 108×72 缩略尺寸下，防御、灵性/抽牌和标记爆发方向可由构图与符号区分。
- 第二挑战徽记通过：与第一挑战徽记轮廓明显不同。
- 新修饰图标通过：挑战入口 32×32 小徽记和选择页 108×108 大图标均可辨识。
- 第二挑战页面通过：动态徽记、路线差异、三个修饰和奖励信息清晰。
- 截图中发现的空路线问题来自测试样张缺少顶层 `route_id`，已修正样张；正式 `ChallengeSnapshot` 已包含该字段。

截图位置：

- `.tools/ui-captures/deck_screen.png`
- `.tools/ui-captures/identity_hub_screen.png`
- `.tools/ui-captures/challenge_hub_screen.png`
- `.tools/ui-captures/challenge_second_screen.png`
- `.tools/ui-captures/challenge_result_screen.png`

## 验证

```text
UI_SMOKE_OK checks=33
PROGRESSION_UI_SMOKE_OK checks=41
V05_ROUTE_UI_SMOKE_OK checks=62
V06_CHALLENGE_UI_SMOKE_OK checks=40
V07_DECK_UI_SMOKE_OK checks=46
```

新增 v0.7 UI 测试覆盖：

- 16 卡池、3 预设、8 槽牌组与合法性展示。
- 已拥有/未拥有/当前牌组筛选。
- 加入、预设切换、确认命令与错误原因展示。
- 身份 hub 牌组入口。
- 第二挑战锁定、完成前置后解锁、稳定挑战 ID。
- 第二挑战动态标题、路线和徽记。

实际渲染截图生成退出码为 `0`。

## 困难与解决

| 困难 | 解决方案 |
|---|---|
| 新资产首次测试时尚未进入 Godot 导入缓存 | 先运行 headless editor import，再跑 UI 测试 |
| 重绘时确认按钮被误从动作列表移除 | 每轮渲染重新注册基础按钮，动态卡片按钮单独追加 |
| 旧挑战页硬编码第一挑战标题与徽记 | 改为从 `ChallengeSnapshot` 读取，并通过稳定 ID 映射资源 |
| 挑战入口无法区分两个挑战 | 新增 ChallengeHub，单纯读取两个 ChallengeSnapshot |
| 小尺寸修饰图标未被实际使用 | 挑战档案卡加入 32px 修饰徽记行 |

## 跨角色请求

```text
[REQUEST]
从：UI 设计
给：app
版本：v0.7.0
内容：
1. identity_screen.deck_requested -> deck_screen
2. deck_screen 注入 DeckSnapshot 和 ProgressionSnapshot 的等级信息
3. deck_command_requested -> DeckEngine；确认成功后用于首次路线和挑战
4. StartScreen.challenge_requested -> ChallengeHub
5. ChallengeHub.challenge_selected(challenge_id) -> 对应 ChallengeSession
6. 启动摘要可增加 completed_challenge_ids 和已解锁挑战数量
[END REQUEST]
```

## 风险

- UI 尚未接入 app，当前页面级冒烟测试使用手工快照。
- 卡牌描述通过提示信息展示；正式扩展多行描述时需要再次检查卡组网格高度。
- 启动页仍只有一个挑战档案入口，具体挑战由 ChallengeHub 选择，符合当前两挑战规模。

## 下一步入口

1. app 接入 DeckScreen 和 ChallengeHub。
2. 数据层提供 v5 存档后，验证继续游戏恢复当前牌组和第二挑战状态。
3. 全量回归通过后重新导出 Windows 构建。
