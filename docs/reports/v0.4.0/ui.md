# v0.4.0 / UI 设计与美术审稿记录

## 状态

- 版本：`v0.4.0`
- 角色：UI 设计
- 任务：实现白昼身份、战后奖励、灵界祈愿和卡牌升级界面，并完成 UI 对美术候选的实际审稿
- 状态：UI 页面完成；等待 app 接线
- 最后更新：2026-11-08
- 下一步入口：app 注入成长快照、连接命令回调，完成短循环路由

## 本版本目标

把 `v0.3.0` 的单场战斗 UI 扩展为 20—30 分钟短循环：

```text
身份选择 -> 夜间战斗 -> 二选一战利品 -> 灵界祈愿 -> 卡牌升级 -> 返回身份/再战
```

UI 只显示规则层提供的快照和结果，不计算抽卡、保底、费用、碎片、升级效果或 BattleEngine 规则。

## 依赖

- `src/core/progression_command.gd`
- `src/core/progression_event.gd`
- `src/core/progression_snapshot.gd`
- `src/core/progression_command_result.gd`
- `docs/reports/v0.4.0/gameplay.md`
- `assets/game/v0.4.0/**`
- `src/ui/mask_ui_theme.gd`

## 已实现

### 白昼身份页

- 文件：
  - `src/ui/identity_screen.gd`
  - `scenes/ui/identity_screen.tscn`
- 显示三种身份、职业肖像、身份描述和快照中的 `battle_modifiers`。
- `identity_selection` 阶段发送 `SelectIdentity`。
- `hub` 阶段显示当前身份、占卜券、已收容卡牌和稀有保底，并提供：
  - 进入夜间战斗
  - 进行灵界祈愿
  - 整理卡牌与残页
- 使用 `title-screen.png` 背景，身份卡按 512×640 源图等比显示。

### 战后奖励页

- 文件：
  - `src/ui/reward_screen.gd`
  - `scenes/ui/reward_screen.tscn`
- 读取 `reward_options`，显示奖励名称、类型、金额和图标。
- 发送 `ClaimReward(reward_id)`，不自行判断余额或奖励合法性。
- 使用 `reward-archive.png`，奖励卡片围绕两页档案构图。

### 灵界祈愿页

- 文件：
  - `src/ui/gacha_screen.gd`
  - `scenes/ui/gacha_screen.tscn`
- 显示占卜券、单抽/三连费用、稀有保底、卡背和结果卡。
- 单抽、三连均只发送 `DrawGacha(1/3)`。
- 结果卡读取 `last_gacha_results`，显示卡面、稀有度、首次收容/重复残页数量。
- 结果、费用、保底和资源不足均由快照/命令结果驱动。
- 使用 `gacha-altar.png`；未揭示状态使用 `card-back-sealed-omen.png`。

### 卡牌升级页

- 文件：
  - `src/ui/upgrade_screen.gd`
  - `scenes/ui/upgrade_screen.tscn`
- 读取 `collection` 的等级、残页、上限和下一等级成本。
- 通过 `configure(card_names, effect_previews)` 注入显示名称和升级预览文本。
- 显示当前等级、满级状态、残页充足/不足、升级前后摘要和三级印章。
- 发送 `UpgradeCard(definition_id)`；不在 UI 计算升级后效果。

### 共享展示映射

- 文件：`src/ui/progression_ui_catalog.gd`
- 集中维护身份、卡面、卡背、资源图标和等级图标路径。
- 原因文本集中映射，避免各页面复制 `reason_code` 文案。

## UI 对美术的实际审稿

审稿基于实际 Godot 渲染截图，而不是只看源文件：

- 身份页：**通过**。记者、医生、守墓人在缩小卡片中可通过笔记本/眼睛、药瓶/听诊器、铲子/墓碑等轮廓区分。
- 祈愿页：**通过**。中央三卡结果没有遮挡祭坛主体，卡背和背景层级清楚；三张结果卡在 1600×900 下可读。
- 奖励页：**通过**。两页档案背景为奖励卡片提供对称承载，图标和金额不冲突；大面积暗化不影响按钮识别。
- 升级页：**通过**。128×128 等级印章缩小到约 32px 后差异偏细，但等级数字标签清楚；视觉可辅助而不承担唯一信息通道。
- 卡背：**通过**。与现有正面的旧纸、铜版线、暗金边框保持统一。

当前不需要美术退回资产。后续如果增加多行卡牌描述，需要重新检查升级列表和祈愿结果卡的实际排版。

## 验证

命令：

```powershell
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/ui/ui_progression_smoke_runner.tscn
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/ui/ui_smoke_runner.tscn
```

结果：

```text
PROGRESSION_UI_SMOKE_OK checks=41
UI_SMOKE_OK checks=21
```

覆盖：

- 正式 v0.4 美术路径存在。
- 身份选择、pending、快照更新和 hub 动作出现。
- 奖励二选一、领取后清空、命令结果更新。
- 单抽/三连请求、资源不足拒绝、三张结果渲染、重复残页提示。
- 升级列表、升级前后预览、成功和残片不足拒绝。
- UI 不读取领域内部字段；只通过 `ProgressionSnapshot`、`ProgressionCommandResult` 和注入回调工作。

实际截图：

```text
.tools/ui-captures/identity_screen.png
.tools/ui-captures/reward_screen.png
.tools/ui-captures/gacha_screen.png
.tools/ui-captures/upgrade_screen.png
```

## app 接线接口

1. 创建 `IdentityScreen`，调用 `apply_snapshot(GameSession.get_progression_snapshot())`，连接 `identity_selected`、`battle_requested`、`gacha_requested`、`upgrade_requested`。
2. 战斗胜利后创建 `RewardScreen`，应用 `ProgressionSnapshot`，连接 `reward_claimed` 到 `GameSession.claim_reward`。
3. 创建 `GachaScreen`，调用 `configure(card_names)` 和 `apply_snapshot(...)`，连接 `draw_requested` 到 `GameSession.draw_gacha`。
4. 创建 `UpgradeScreen`，调用 `configure(card_names, effect_previews)` 和 `apply_snapshot(...)`，连接 `upgrade_requested` 到 `GameSession.upgrade_card`。
5. 所有页面的 `back_requested` 或 `hub_requested` 返回身份/hub 页；app 不把规则复制到路由中。
6. `effect_previews` 必须由 app/content adapter 生成，UI 不根据卡牌名称或 amount 计算升级结果。

## 困难与方案

| 困难 | 候选方案 | 最终选择 |
|---|---|---|
| UI 需要显示升级前后效果，但快照只提供等级与成本 | UI 读取卡牌原始数据并计算 | 注入 `effect_previews`，UI 只渲染规则层/adapter 提供的显示文本 |
| 三连结果需要同时可读 | 单张大图轮播；三列结果；滚动列表 | 三列结果卡，1600×900 下直接比较 |
| 新背景可能和按钮冲突 | 全屏高亮；裁切背景；暗化遮罩 | 保留祭坛/档案构图，统一暗化并让结果和按钮占据固定安全区 |
| UI 与美术混在同一角色 | 美术自行接入并验收 | UI 独立实际截图审稿，美术只交候选和请求 |

## 风险与未决问题

- 当前 UI 场景尚未被 app 接线；本报告不代表短循环已能从启动页实际走到结算、抽卡和升级。
- `UpgradeScreen` 的升级前后文本依赖 app 提供 `effect_previews`；若注入缺失，会显示“效果由规则层结算”，不会伪造数值。
- 祈愿页会显示上一轮结果；若产品希望每次进入都清空，需要 app 路由显式传入空结果快照。
- 级印章在小尺寸下主要作为辅助，等级数字仍是主要可读信息。

## 跨角色请求

```text
[REQUEST]
从：UI
给：本地数据层/app
版本：v0.4.0
内容：GameSession 暴露 progression snapshot 和 identity/reward/gacha/upgrade 命令结果，并在 app 中按“身份/hub -> 战斗 -> 奖励 -> 祈愿/升级 -> hub”路由。
期望接口：现有 ProgressionCommand/Result/Snapshot；UI 不直接访问 FileAccess。
[END REQUEST]
```

```text
[REQUEST]
从：UI
给：app
版本：v0.4.0
内容：在抽卡/升级页初始化时注入 card_names 和 effect_previews。effect_previews 必须来自内容/规则适配，不由 UI 计算。
[END REQUEST]
```

## 下一步入口

等待 app 接线后，运行真实短循环集成：

```text
启动 -> 身份 -> 战斗 -> 奖励 -> 祈愿/升级 -> 再战
```

如果实际界面发现身份卡裁切、奖励按钮冲突或升级多行溢出，先在 UI 层做遮罩/排版前向修复，再判断是否需要新的美术候选。

## 启动与结果状态收尾

- 启动页不再硬编码旧版本号：有检查点时读取 `content_version`，无检查点时显示当前原型 `v0.4.0`。
- 检查点摘要新增身份、占卜券、稀有保底和收藏数量的只读显示。
- 摘要缺少收藏或保底字段时明确显示“摘要未提供”，不以牌组规模冒充收藏数量。
- 损坏检查点继续显示“原始存档已保留”，并禁用继续入口。
- 失败结果页导航按钮调整为“返回白昼档案”，与 app 实际 hub 路由一致。
- UI smoke 新增无检查点、正常 v0.4 摘要、损坏摘要、胜利和失败状态覆盖。

后续 app checkpoint summary 可直接补充：

```text
collection_count
pity_counter
rare_pity
```

UI 已兼容这些字段；未提供时保持安全占位。

最终验证：

```text
UI_SMOKE_OK checks=33
PROGRESSION_UI_SMOKE_OK checks=41
APP_V04_INTEGRATION_OK checks=39
Godot resource import: exit 0
UI-scoped git diff --check: clean
```

截图已重新生成到 `.tools/ui-captures/`。全局 `git diff --check` 仍被
`art/README.md` 与 `art/ASSET_MANIFEST.md` 的 EOF 空行阻塞，属于美术文件，
UI 角色未越权修改。
