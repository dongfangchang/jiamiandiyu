# v0.86.0 主协调者 / 架构师报告

```text
版本：v0.86.0
角色：主协调者（兼架构师）
任务：关闭 v0.84/v0.85；开 v0.86（ROADMAP R0）；统一测试入口；测试基线；卡图修复；仓库卫生
状态：部分完成
```

## 已完成（2026-11-24）

- **关版**：v0.84.0、v0.85.0 已有条件关闭（用户口头授权）；v0.85 余项真窗口审稿转为 R0-11。
- **文档**：
  - 新增 `docs/architecture/`（REVIEW / TARGET_ARCHITECTURE / ROADMAP / UI_NAVIGATION_REVIEW）和 ADR-0031。
  - 章程删除"不做 3D 场景"；章程新增 §9 提交与推送。
  - 更新 AGENTS 的所有权与规则。
- **R0-01**：新增 `tools/run_tests.sh` 和 `tools/run_tests.ps1`。
  - 自动发现 runner；`extends SceneTree` 的 runner 走 `--script`；每个 runner 有超时；排除 capture 和 monkey。
  - 内置守卫。
  - `.ps1` 未在 Windows 实测。
- **R0-05**：删除 `battle_screen.CARD_ART_BY_DEFINITION`，战斗优先使用 v0.85 插画窗口；v041/v042 测试改为断言新行为，两项均通过。
- **R0-08**：新增 `art/assets/raster/.gdignore`，取消跟踪 45 个 raster `.import` 和 `tools/simulation/out/`，并加入 `.gitignore`。
  - `art/assets/svg` **没有**忽略，因为 `art/tools/render_*.gd` 通过 `load()` 导入 SVG。
- **R0-09**：守卫已在 run_tests 中。
- 运行时版本号改为 `0.86.0`。

## R0-02 测试基线（macOS，Godot 4.7.2，headless）

`pass=75 fail=13 skipped=8`（skip 的是 capture 和 monkey）。另外守卫 `tests must not pin project version` 阻断（v077/v081/v082）。

| 失败 runner | 原因 | 处置（负责） |
|---|---|---|
| integration/app_flow、v07_app_flow、v091_app_destructive（超时）、v092_destructive | 调用旧路线屏 API（`get_snapshot_data`、`get_option_count`、`select_rest`、`is_exit_confirmation_visible`），但路由已指向日记屏；挑战 hub 的 `get_modifier_count` 不存在。**界面切换路径实际上没有可用的回归测试** | 轨道 B（UI）：随 NAV 整治重写为按日记主路径的导航测试 |
| ui/v056_immersion、v072_diary_008_layers、v077_live_copy、v077_runtime_cta、v081_diary_readability | 断言已退役的 2D 书、flip3d、页底板和版本号 | 轨道 A：删除或裁剪（R0-03，提前执行 R1-04 中测试的部分） |
| ui/v082_no_plate_flip3d | 只有版本号断言失败 | 轨道 A：删除版本断言 |
| ui/v084_diary_desk_flipstrip | 需要 GPU 截帧（capture null） | 轨道 A：改名或标记为 capture，移出 headless 集合 |
| simulation/v07_deck_contract | `deck.preset.clown` 在初始条件下无法确认（v0.40 解冻后要求序列 8） | 轨道 A：合约测试按序列 8 前置条件构造 |
| gameplay/v012_identity_passive | 身份屏不再显示「最大灵性 +1 / 残页」被动文案 | 轨道 A：先确认是文案改版还是回归；属于回归就开 BUG |

## 风险

- 4 个导航集成测试失效，说明 v0.55 日记替代路线屏以来的切换路径都是无测试裸奔；轨道 B 必须先补测试再改路由。
- `.ps1` 没有经过 Windows 实测。

## 下一步入口

- 轨道 A：上表"轨道 A"各行 + R0-04 黄金回放。
- 轨道 B：`docs/architecture/UI_NAVIGATION_REVIEW.md` §3。
