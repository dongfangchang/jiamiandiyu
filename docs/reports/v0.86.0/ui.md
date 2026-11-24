# v0.86.0 UI 报告（轨道 B：界面切换整治）

```text
版本：v0.86.0
角色：UI（轨道 B 单一负责人）
任务：NAV-01…NAV-09（UI_NAVIGATION_REVIEW §3）+ R0-06/AR-04（并入 NAV-08）；先补导航回归测试，再改路由
状态：部分完成（自动化范围内全部完成；真窗口观感待用户验收，见文末清单）
```

## 修改文件

- 新增 `src/app/screen_router.gd`：统一切屏（淡出/淡入遮罩、单次切换输入锁、`on_exit`/`on_enter` 钩子、仅日记缓存、提示条、常驻音效宿主）。
- `src/app/app_controller.gd`（仅路由相关部分）：
  - `_replace_screen` 全部改为 `_swap` → router。
  - 新增返回表 `BACK_TARGETS` / `get_back_target()` / `_navigate_back()`。
  - 错误分流 `_show_load_error` / `_report_error`。
  - 挑战 hub 预览缓存。
  - 删除 `test_checkpoint` 特例。
  - 公开查询 `is_transitioning()`、`get_router()`、`set_transitions_instant()`、`get_toast_text()`、`is_challenge_hub_preview_cached()`。
- `src/ui/table_sfx.gd`：常驻宿主 `set_persistent_host()`。
- 屏幕钩子：
  - `battle_screen.gd`：`on_enter`/`on_exit`，公开 `request_exit()`/`confirm_exit()`。
  - `diary_chapter_screen.gd`：`on_enter`/`on_exit`/`set_pending`、`get_clue()`/`request_close()`。
  - `start_screen.gd`：开书动作移入 `on_exit`。
  - `rest_screen.gd`：新增「回日记」与 `back_requested`。
  - `route_select_screen.gd`、`reward_screen.gd`、`deck_screen.gd`：`on_enter` 焦点。
- 测试：
  - 重写 `tests/integration/app_flow_runner`、`v07_app_flow_runner`、`v091_app_destructive_runner`。
  - `v092_destructive_runner` 重写战斗退出/测试档案段，其余保留。
  - 新增 `tests/integration/app_driver.gd`（共用驱动）。
  - 新增 `tests/ui/screen_router_runner.(gd|tscn)`。
- 修正 `tests/integration/app_flow_runner.tscn`：它原本挂的是 `v07_app_flow_runner.gd`，`app_flow_runner.gd` 实际从未运行。

## 依赖

- `UI_NAVIGATION_REVIEW.md` §3。
- 现有会话/引导 API（`bootstrap.gd` 未改）。
- 日记内容 `data/diaries/v0.55.0/tingen_volume_1.json`（只读）。

## NAV 条目状态与证据

| ID | 状态 | 做法 | 证据 |
|---|---|---|---|
| NAV-01 | 完成 | 战斗 `on_exit` 补一个胜利/败退横幅，并等待 0.8s（router 上限 0.9s）后才淡出释放。`call_deferred` 只用于离开战斗命令调用栈，不再提前释放屏幕 | v091「battle on_exit beat was awaited」 |
| NAV-02 | 完成 | `TableSfx.play` 优先挂到 router 的常驻 `TableSfxHost` 节点 | router_runner「table SFX player is hosted by the router」「not parented to the screen」 |
| NAV-03 | 完成 | 只缓存日记屏：离场时 `remove_child`，并把其下所有 SubViewport 设为 `UPDATE_DISABLED`；回场先 `add_child` 再恢复模式（SubViewportContainer 入树会重置子视口，所以顺序不能反）。setup 重新 `apply_snapshot` 和 `present_post_encounter`，`on_enter` 复位翻页状态。会话变化时清缓存 | app_flow「diary instance is reused after battle and reward」「desk stage is not rebuilt」「hub round trip reuses the cached diary」；router_runner「SubViewports stop updating / restored」 |
| NAV-04 | 完成 | 点线索后状态句保留，日记 `on_exit` 播放桌面笔触 bloom，并等 0.55s 再淡出。笔触动画本身未改 | v091「clue status line is still on screen while the diary exits」「diary on_exit beat was awaited」 |
| NAV-05 | 完成 | 见下方返回表 | app_flow / v07 / v091 / router_runner 共 20 余条返回断言 |
| NAV-06 | 完成 | 游戏内失败（开局、挑战开局、挑战 hub、路线列表、魔药、重新探索、战斗快照缺失）一律走 `_report_error`：留在原屏、释放该屏 busy、底部 toast。只有读档/恢复态失败（`continue_saved_checkpoint`、`_show_current_state` 不可恢复）走 `_show_load_error` 回标题并显示 corrupt | v091「in-play error keeps the player on the diary / keeps the session / shown as a toast」「corrupt checkpoint load returns to the title」 |
| NAV-07 | 完成 | 挑战 hub 预览按「存档目录 + 槽位 + 检查点摘要 JSON」缓存，摘要不变就复用 | v07「challenge previews are cached」「cached hub reopens quickly」 |
| NAV-08 / AR-04 | 完成 | `show_start_screen` 复位 `checkpoint_slot`。删除 `_refresh_checkpoint_summary` 和挑战 probe 中的 `test_checkpoint` 特例。测试档案槽位改名为常量 `TEST_PROFILE_SLOT = "test_profile"`；生产代码 `grep test_checkpoint` 结果为 0。各屏的忙碌标志由 router 的 `_busy` 统一兜底：所有命令处理器都先查 `_router_busy()` | v092「returning to the title should reset the test profile slot」「title challenge entry should follow the normal checkpoint」 |
| NAV-09 | 完成（自动化） | 各屏 `on_enter` 给默认按钮 `grab_focus`：<br>· 标题：继续或新局<br>· 路线选择：首个可选路线<br>· 牌组：确认或返回<br>· 奖励：首个奖励<br>· 战斗：结束回合<br>· 日记：后一页或合上<br>· 休整：首个选项<br>其余屏（含另一代理正在改的 identity_screen）由 router 回退聚焦首个可用按钮 | headless 无断言焦点外观，需真窗口确认 |

### 返回表（`app_controller.BACK_TARGETS`，战役/挑战共用）

| 来源 | 战役 | 挑战 | 说明 |
|---|---|---|---|
| route_select | hub | hub | 无会话时回标题。修正「hub→重开→返回」误回标题；有会话时按钮文案改为「回身份档案」 |
| map（日记合上） | hub | hub | |
| battle | map | map | **改动**：确认退出后重载最近检查点回到日记，不再先回标题。退出对话框文案同步 |
| reward | hub | hub | hub「打开日记」改走状态机，未领奖励会先回奖励页（修正「跳过领取」） |
| rest | map | map | **新增**「回日记」。日记里再点该休整线索会直接重开休整页（仅 UI 入口，不提交规则命令） |
| ritual | map | map | 沿用「退出仪式」(CANCEL_RITUAL)，不经返回表 |
| deck | hub | challenge_hub | 从 hub 打开的统一回 hub |
| gacha / upgrade / route_result | hub | hub | |
| challenge_select | challenge_hub | challenge_hub | 原为回标题 |
| challenge_result | challenge_hub | challenge_hub | 修正原来进战役身份 hub 的问题 |
| hub / identity / challenge_hub | start | start | |

挑战中确认牌组的循环（434/754）：
- 挑战中途确认牌组后改走 `_show_current_state()` 继续挑战，不再跳回挑战 hub。
- 正常 UI 下，标题在牌组未确认时禁用挑战入口，因此本次 v07 流程中没有出现牌组页。
- 这条路径靠代码检查修正，没有专门的自动化复现。

## 标题退场统一

- 「新局」「继续」「挑战」「测试档案」都先 `set_busy` 并立即发出意图。
- 桌面开书动画（约 0.9s）改为 `start_screen.on_exit`，之后接 router 的统一淡出。
- 「新游戏」不再硬切。

## 测试

| runner | 结果 | 覆盖 |
|---|---|---|
| integration/app_flow_runner | OK checks=93 | 标题 → 新局 → 选路线 → 身份 → 牌组 → hub → 日记 → 蜡封(`seal_activated`) → 战斗 → 奖励 → 日记（同一实例）→ 合上 → hub → 子页往返 → 奖励不可跳过 → 休整返回 → 打完 8 节点与仪式 → 结算 → hub → 标题（槽位复位）→ 继续 → 重开选路线返回 hub → 损坏存档 |
| integration/v07_app_flow_runner | OK checks=86 | 打通主线作序列 8 fixture → 挑战 hub（缓存）→ 修饰选择返回 hub → 开挑战（无循环）→ 挑战日记首战 → 合上/重开 → 标题 → 继续挑战 |
| integration/v091_app_destructive_runner | OK checks=47 | **真实淡入淡出模式**：<br>· 双击新局只切一次，切换中的其他点击丢弃，遮罩阻断<br>· 双击蜡封只开一场战斗<br>· 退出确认连按、切换中再结束回合，只切一次，回到日记<br>· 战斗 `on_exit` 被 await<br>· 双击领奖只结算一次<br>· 双击合上只切一次<br>· 游戏内错误弹 toast<br>· 损坏存档继续回标题且原文件不被覆盖 |
| integration/v092_destructive_runner | OK checks=182 | 保留原有备份恢复、可读性、挂起与幂等审计。重写测试档案段：战斗退出回日记、回标题后槽位复位、正常存档不被污染、挑战入口按正常存档规则 |
| ui/screen_router_runner（新） | OK checks=49 | 两次 swap 只生效一次；遮罩期间点击不到新旧屏，结束后可点；`on_exit` 先于下一屏 setup 完成；挂死的 `on_exit` 被上限截断；日记实例/桌面复用、SubViewport 冻结与恢复；音效宿主；返回表形状 |
| ui/v083_diary_desk_p0_runner | OK checks=21 | 回归 |
| ui/v055_diary_chapter_runner | OK checks=59 | 回归 |

全量 `tools/run_tests.sh`（macOS，Godot 4.7.2 headless）：`pass=76 fail=13 skipped=8 guard_block=1`。基线是 `pass=71 fail=17`。剩余 13 个失败均在基线中已失败，且都不在本轨道范围：

- 另一代理正在处理的文件：`ui/v056_immersion`、`v072_diary_008_layers`、`v077_live_copy`、`v077_runtime_cta`、`v081_diary_readability`、`v082_no_plate_flip3d`、`v084_diary_desk_flipstrip`、`gameplay/v012_identity_passive`。
- `simulation/` 下的 `balance_contract`、`v04_economy_contract`、`v05_route_contract`、`v06_challenge_contract`、`v07_deck_contract`。
- `guard_block` 来自 v077/v081/v082 钉版本号。

## 困难、候选方案与最终选择

1. **测试如何跑完整主线**：
   - 现象：自动出牌脚本在多数种子下会输掉精英战。
   - 候选：改进出牌 AI，或固定一个能全胜的种子。
   - 最终选择：固定种子 1（主线 8 场全胜），与旧测试同一做法。
   - 挑战路线用该脚本打不过第二战，所以 v07 只覆盖挑战首节点与导航；`challenge_result` 返回去向由返回表断言。
2. **`on_exit` 上限**：
   - 原审查定为约 0.6s，但标题开书动画约 0.9s。
   - 最终把 router 上限设为 0.9s：战斗 0.8s、日记 0.55s、标题约 0.9s。
   - 屏幕在上限后会被释放，所以钩子本身的时长必须短于上限。
3. **缓存日记的信号重复连接**：
   - router 离场时断开屏幕脚本信号上所有外部连接，由下一次 setup 重新接线。这也顺带让已离场的屏幕无法再驱动导航（迟到点击）。
4. **instant 模式**：
   - `configure_for_testing` 默认开启 instant，旧的同步 runner 语义不变：不 await，也不跑 `on_exit`。
   - 需要真实过渡的测试调用 `set_transitions_instant(false)`。

## 发现的问题（非本轨道修复）

- **S2 挑战路线在日记里没有线索**：
  - `tingen_volume_1.json` 只映射了 `route.v028.first_stage.*` 节点。
  - 挑战路线（`route.v070.*`）打开的日记里没有任何可按的蜡封，玩家在 UI 上无法推进挑战。
  - v07 测试只能通过日记自身的 `route_command_requested` 信号推进挑战节点。
  - 需要产品经理裁决：补日记内容映射，或给挑战另配载体。按 AGENTS §8 应开 BUG 档，请 PM 编号。
- 战斗屏 `_play_card_cast` 的 tween 回调捕获了目标节点，敌人栏重建后会报 `Lambda capture at index 1 was freed`。基线 v031 已有，本次未改。
- `app_controller.gd` 从 1642 行增至 1791 行（原本已超出 500 行预算）。按 ROADMAP R3-06 拆分时，`screen_router` 与返回表可直接迁出。

## 风险（需真窗口确认）

- 淡入淡出时长 0.18s+0.18s 与各屏 `on_exit` 节奏的实际观感，尤其是标题开书 0.9s 之后再淡出是否显得拖。
- 战斗胜利/败退横幅（新加，仅表现层）的位置与可读性。
- 日记缓存回场后 3D 桌面、蜡封呼吸、笔触 bloom 是否正常恢复渲染（headless 下 3D 视口本就禁用）。
- 键盘焦点框在各屏默认按钮上的外观；日记里回车会触发「后一页」或「合上」。
- 测试档案不再「解锁全部挑战」，也不再出现在标题的继续入口（回标题即复位到正式槽位）。这是 AR-04 的预期结果；如仍需开发用的挑战入口，请数据层用 fixture/引导参数提供。

## 跨角色请求

- 产品经理：
  - 为「挑战路线日记无线索」开 BUG 并裁决方案。
  - 确认战斗退出改为「回日记（读检查点）」符合预期。
- 数据层（如需）：测试档案若要直达挑战，在 `bootstrap` 的 test_profile 初始状态中提供，而不是在 app 层按槽位名写特例。

## 下一步入口

- 真窗口按下方清单走一遍。如节奏需要调整，只改 `screen_router.gd` 顶部常量和各屏 `EXIT_BEAT_SEC`。
- R3-06 拆分 app_controller 时，把 `BACK_TARGETS`/`_navigate_back`/`_swap` 一并迁出。

## 手动验证清单（真窗口）

1. 标题点「新局」：开书动画后淡出，进入选路线时淡入，无硬切。快速连点不会触发两次。
2. 选路线 → 身份 → 牌组确认 → hub「打开日记」：每步都有淡入淡出。
3. 日记点亮的蜡封：状态句「字句展开……调查开始」和桌面红色 bloom 可见约半秒，然后淡入战斗。
4. 打赢一场：最后一击的伤害数字、闪光和「胜利」横幅都看得到，然后才切到奖励。点击音效在切屏时不被截断。
5. 领奖回日记：没有明显卡顿，书页停在刚结算的那一叶，并有结算笔触和自动翻页。
6. 日记「合上」→ hub →「打开日记」：回来时桌面不重建（无闪黑、无重新加载卡顿）。
7. 在奖励页点「回日记」到 hub，再点「打开日记」：应回到奖励页，而不是跳过。
8. 休整页点「回日记」，再点该休整蜡封：重新打开休整页。
9. 战斗中「退出战斗」→ 确认：回到日记（最近检查点），线索仍可再点。
10. hub「重新开始」→ 选路线「回身份档案」：回 hub。
11. 每次切屏后按 Tab/回车：焦点落在合理的默认按钮上。
