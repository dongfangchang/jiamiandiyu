# 界面切换审查与整治方案（2026-11-24）

> 用户反馈："各界面之间的切换都有点问题"。本文件给出根因、缺陷清单（NAV-xx）和最小改造方案。  
> 执行版本：v0.86.0 轨道 B。行号以审查当日为准。

## 1. 根因

切换**有**一个中心函数 `_replace_screen`（`src/app/app_controller.gd:1624-1633`），但它只做一件事：同一帧内 `remove_child` 加 `queue_free` 旧屏，再实例化并挂上新屏。

它缺少四样东西：
- 过渡动画
- 切换期间的输入锁
- 屏幕的进入/离开生命周期钩子
- 缓存

于是每个屏幕各自发明退场效果：
- 标题"继续"会推镜淡黑，而"新游戏"直接硬切。
- 日记"合上"淡出 0.45 秒，其他屏一律硬切。
- **所有屏都没有淡入**；全项目 `src/ui` 中没有一处 `grab_focus`。

历史上的 BUG-0005/0012/0014/0015/0023 都是在各屏内部补标志位，补的正是"路由器本该负责的事"（幂等离开、切换期输入锁、进出清理）。这正是 AGENTS §8 禁止的叠补丁模式。

## 2. 缺陷清单

| ID | 严重度 | 现象 | 根因与位置 |
|---|---|---|---|
| NAV-01 | S2 | **战斗最后一击和胜利演出看不到** | `battle_screen.gd:271-273` 发出 `battle_finished` 后，`app_controller.gd:966-967` 只 defer 到同帧末尾就释放战斗屏，命中和横幅 tween（2877-3005）随之销毁 |
| NAV-02 | S2 | 每次切屏时点击音效被截断 | `table_sfx.gd:50-55` 把 `AudioStreamPlayer` 挂在即将被释放的屏上（例如日记合上 `diary_chapter_screen.gd:2851`） |
| NAV-03 | S2 | 回到日记时卡顿 | 每次回日记都重建 3D 世界、页 SubViewport、蜡封、着色器并重新读取纹理（`diary_chapter_screen.gd:141-150`，`diary_desk_stage.gd:89-101, 166-198, 660-665`） |
| NAV-04 | S3 | 点日记线索后状态句和笔触一闪而过 | 状态在 `diary_chapter_screen.gd:2210-2212` 设置，但同一调用栈内就切进战斗（`app_controller.gd:835-843`） |
| NAV-05 | S2 | "返回"的去向不一致 | 战斗退出回标题（957-963），战斗结束却回日记（991）；hub→重开→选路线→返回到了标题而不是 hub（685, 1428）；奖励→hub 跳过领取（997/1011）；挑战结算→hub 进的是战役身份 hub（626）；挑战中确认牌组会回到挑战选择页（434, 754-755，疑似循环，待实机确认）；休息和仪式没有返回入口（806-823） |
| NAV-06 | S2 | 小错误被当成"存档损坏"踢回标题 | `_show_start_error` 调用 `show_start_screen`，会清空会话并显示 corrupt（1588-1595）；魔药使用失败也走这条路（1088） |
| NAV-07 | S3 | 打开挑战 hub 很慢 | 每次都完整执行一遍 `start_challenge_v07` 并逐挑战建引擎（484-503, 514-576），从牌组页"返回"也会触发 |
| NAV-08 | S3 | 导航后残留隐藏状态 | 测试局结束后 `checkpoint_slot` 仍是 `test_checkpoint`，回标题也不复位（143, 102-114）；忙碌标志分散在各屏，控制器从不调用 `set_pending`（与 AR-04 合并处理） |
| NAV-09 | S3 | 键盘焦点在每次切换后丢失 | 没有任何 `grab_focus` |

## 3. 改造方案（最小、不过度设计）

### 3.1 `src/app/screen_router.gd`

```gdscript
class_name ScreenRouter extends Control
# 子节点：_overlay（全屏 ColorRect，默认 alpha 0、MOUSE_FILTER_IGNORE）始终在最上层
var _busy := false
var _cache := {}            # 只缓存日记屏
var instant := false        # 测试模式：跳过所有 await，保持同步语义

func swap(scene: PackedScene, setup: Callable, opts := {}) -> Control:
    if _busy: return null                          # 同一时间只允许一次切换 → 取代各屏的防连点标志
    _busy = true; _overlay.mouse_filter = MOUSE_FILTER_STOP
    if _screen and _screen.has_method("on_exit"): await _screen.on_exit()   # 屏幕可以演完收尾（上限约 0.6s）
    await _fade(1.0, opts.get("out", 0.18))
    _detach_or_free(_screen)                       # 被缓存的：remove_child + 停更新；其余 queue_free
    var next = (_cache.get(scene) if opts.get("cache") else null)
    if next == null: next = scene.instantiate()
    add_child(next); move_child(_overlay, -1); setup.call(next)
    if next.has_method("on_enter"): next.on_enter()    # 重启动画、grab_focus、present_post_encounter
    await _fade(0.0, opts.get("in", 0.18))
    _overlay.mouse_filter = MOUSE_FILTER_IGNORE; _busy = false
    return next
```

### 3.2 屏幕约定（可选实现，不实现就按默认行为）

- `on_exit() -> void`（可 await）：
  - 战斗：等最后的命中 tween 和结果横幅（NAV-01），取代 `call_deferred`。
  - 日记：把"合上"的淡出动画移到这里。
  - 标题：把推镜动画移到这里，使"新游戏"和"继续"的退场一致。
  - 线索：在这里播放状态句和笔触（NAV-04）。
- `on_enter() -> void`：`grab_focus` 默认按钮（NAV-09）；日记在这里调用 `apply_snapshot` 和 `present_post_encounter`。

### 3.3 其余改动

| 条目 | 做法 |
|---|---|
| NAV-02 | `TableSfx` 的播放器挂到 router（常驻节点）上，不再挂在屏上 |
| NAV-03 | 只缓存 `diary_chapter_screen`；脱离场景树时把 SubViewport 设为 `UPDATE_DISABLED` |
| NAV-05 | 在 app_controller 里建一张 `{route: back_target}` 返回表，战役和挑战会话共用；休息和仪式补返回入口（只是 UI 入口，不改规则） |
| NAV-06 | 游戏内的错误用非破坏性提示条（toast）；只有加载存档失败才回标题 |
| NAV-07 | 挑战 hub 的预览结果缓存到会话变化为止 |
| NAV-08 | 回标题时复位 `checkpoint_slot`；删除 `test_checkpoint` 的生产特例（AR-04），测试改用 fixture |

### 3.4 测试

- 已有测试同步调用 `_show_*`，所以 router 在测试中设 `instant = true`，保持同步行为。
- 新增 `tests/ui/screen_router_runner`：验证连续两次 swap 只生效一次、overlay 会阻断输入、缓存的日记实例被复用、on_exit 被 await、返回表与预期一致。

## 4. 与 ROADMAP 的关系

- v0.86 轨道 B 完成 3.1–3.4。
- ROADMAP R3-06 拆分 app_controller 时，`screen_router` 直接成为独立模块，路由表从 controller 中迁出，不需要返工。
