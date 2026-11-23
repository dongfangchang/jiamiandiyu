# v0.3.0 / UI 美术接入与复审

## 状态

- 版本：v0.3.0
- 角色：UI 实现与美术复审
- 任务：把正式美术候选接入启动、战斗、结果界面，并复查实际呈现
- 状态：完成
- 最后更新：2026-11-08
- 下一步入口：由产品经理完成 v0.3.0 验收并规划 v0.4.0

## 本版本目标

在不修改战斗规则、应用装配、存档和美术源文件的前提下，将 v0.3.0 正式美术资源接入 UI，并确认它们在 1600×900 的实际页面中可读、可辨识且不破坏现有交互。

## 依赖

- UI 只读依赖冻结的 `BattleSnapshot`、`BattleCommandResult`、`BattlePlayability`。
- 正式资源由主协调者迁移到 `assets/game/v0.3.0/**`。
- 敌人和卡牌定义来自 `data/enemies/v0.3.0/enemies.json` 与 `data/cards/v0.3.0/cards.json`。
- 美术候选来自 `docs/reports/v0.3.0/art_production.md`。

## 已完成

### 正式战斗视觉

- 战斗背景切换到 `res://assets/game/v0.3.0/scenes/battle-tingen-old-house.png`。
- 移除战斗页中残留的“晋升试炼”背景语义。
- 背景采用 0.58 暗化，保留旧宅门窗和雾气质感，同时不干扰 HUD。

### 敌人资源映射

- `enemy.weeping_tenant`：哭泣的房客。
- `enemy.candle_moth`：烛焰飞蛾。
- `enemy.mirror_hound`：镜中猎犬。
- 未知敌人显示中性“未知存在”占位，不再复用错误图片，也不显示内部英文 ID。
- 死亡敌人保留暗化图片，但显示名、生命和不可选状态仍可读。

### 手牌与状态

- 8 个正式卡牌 ID 均映射到 `assets/game/v0.3.0/cards/**` 的无文字插画。
- 手牌显示卡图、名称、灵性费用和“类别 · 目标”，规则文本仍由 UI 渲染。
- 内部实例 ID 移到卡牌工具提示，不再占据主要视觉空间。
- 生命、灵性、corruption、attention 和敌方压力接入正式状态图标。
- 类别 `skill` 改为玩家可读的“非凡能力”。

### 美术复审

结论：**v0.3.0 原型范围通过**。

- 战斗背景通过：没有文字或“晋升试炼”残留，顶部 HUD、三列敌人和底部手牌区域安全。
- 三张敌人通过：缩到约 205px 高度后，人形、飞蛾和犬形轮廓仍可区分。
- 8 张卡面通过：在约 58px 高度的横向缩略区域中保留至少一个核心视觉符号。
- 状态图标通过：18—20px 显示时仍能辅助区分生命、灵性、污染、注视和攻击压力。
- 启动页与结果页继续通过。

正式 AI 插画仍可作为后续质量提升项，但不是 v0.3.0 的运行阻塞。

## 修改文件

- `src/ui/battle_screen.gd`
- `src/ui/result_screen.gd`
- `src/ui/ui_preview.gd`
- `tests/ui/ui_smoke_runner.gd`
- `tests/ui/ui_capture_runner.gd`
- `docs/reports/v0.3.0/ui_asset_integration.md`

未修改 `art/**`、`assets/game/**`、`src/app/**`、`src/gameplay/**`、`data/schema/**` 或 `project.godot`。

## 验证

```text
Godot 资源导入：退出码 0
UI_SMOKE_OK checks=21
APP_INTEGRATION_OK checks=30
APP_ROOT_EXIT=0
实际 OpenGL 截图生成：3/3 成功
git diff --check：通过
```

实际截图：

- `.tools/ui-captures/start_screen.png`
- `.tools/ui-captures/battle_screen.png`
- `.tools/ui-captures/result_screen.png`

本轮新增 UI 冒烟检查覆盖：

- 战斗页使用专用战斗背景。
- 三个正式敌人插图均存在且可解析。
- 正式卡牌插图存在且可解析。
- 未知敌人不返回复用图片路径。

## 困难与候选方案

| 困难 | 候选方案 | 最终选择 | 结果 |
|---|---|---|---|
| 三种敌人共用一张图 | 颜色叠加；继续复用；稳定 ID 映射独立图 | 稳定 ID 映射独立图 | 三种轮廓可辨 |
| 战斗背景含“晋升试炼” | 加深遮罩；用标题背景；专用战斗背景 | 专用战斗背景 | 语义冲突消除 |
| 手牌加入缩略图后底部按钮被裁切 | 增加窗口高度；缩小插画；压缩元信息 | 插画降到 58px，合并类别与目标行 | 1600×900 下按钮完整 |
| 顶部显示内部 revision/battle ID | 保留；删除信息；移到 tooltip | 移到 tooltip | 主界面更接近成品 |
| 未知敌人缺乏正式图 | 复用提灯图；显示英文 ID；中性占位 | 中性“未知存在” | 不误导目标识别 |

## 风险与未决问题

- 当前敌人和卡牌美术是程序化矢量原型，不是精细商业插画。
- 三列敌人和手牌裁切使用固定比例；未来加入长名称或多行卡牌描述时需要重新布局。
- 当前截图使用包含三敌人的审稿快照；正式遭遇首战目前配置两个敌人，第三人用于覆盖三列视觉。
- 状态图标在 18px 下主要用于辅助，完整名称仍保留，不依赖图标单独传达信息。
- 键盘 Tab/Enter/Esc 的完整焦点回归仍属于后续 UI 质量项。

## 跨角色请求

```text
[REQUEST]
从：UI 美术复审
给：产品经理
版本：v0.3.0
内容：正式背景、三敌人、8 卡面和 12 状态图标已接入并完成实机截图复审，请纳入 v0.3.0 关闭验收。
证据：assets/game/v0.3.0/contact-sheet.png 与 .tools/ui-captures/battle_screen.png
期望：关闭 v0.3.0 后，把精细插画替换和多敌人视觉扩展排入后续美术批次，不阻塞抽卡/升级版本。
[END REQUEST]
```

## 下一步入口

1. 产品经理汇总 v0.3.0 角色报告并执行版本关闭。
2. v0.4.0 保留当前 UI 资源映射，新增白天身份、奖励和抽卡页面。
3. 后续美术批次按实际游戏内裁切尺寸精修，不重新设计卡框和路径契约。
