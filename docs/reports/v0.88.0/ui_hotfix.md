# v0.88.0 UI 报告（轨道 H：体验热修 H-01…H-03）

```text
版本：v0.88.0
角色：UI（轨道 H 单一负责人）
任务：H-01 祈愿/整理卡图未更新；H-02 日记跨页翻页卡顿闪烁；H-03 标题点书露出旧面板
状态：部分完成（三项自动化完成并有 GPU 截图佐证；H-02 的完整效果需 diary_chapter_screen 加一行调用，见“跨角色请求”；真窗口验收待用户）
```

## 修改文件

- H-01
  - 新增 `src/ui/common/card_face.gd`：共用卡面。取图顺序为 v0.85 插画窗 → 旧整卡底图 → 卡背，并按稀有度×机制盖印章。
  - `src/ui/gacha_screen.gd`：结果卡正面改用 `CardFace.make_face`（只改取图处）。
  - `src/ui/upgrade_screen.gd`：只改 `_build_card_row` 的取图一处，`ready_to_upgrade` 未动。
  - `src/ui/deck_screen.gd`：缩略图和印章换成共用卡面，行为不变。
  - 新增 `tests/ui/v088_card_face_runner.(gd|tscn)`。
- H-02
  - 新增 `src/ui/diary_page_pair.gd`：一对已备好的左右页（两个页面 SubViewport 及其中控件）。这部分代码从 stage 原样迁出。
  - 新增 `src/ui/diary_art_loader.gd`：用 `load_threaded_request` 后台预取插画，并统计阻塞加载次数。
  - `src/ui/diary_desk_stage.gd`：改为前/当前/后三对页的环形结构，翻页叶做成双面，新增叶下页。文件从 1610 行降到约 1470 行。
  - 新增 `tests/ui/diary_prepared_turn_runner.(gd|tscn)`。
  - 新增 `tests/ui/diary_turn_capture_runner.(gd|tscn)`：GPU 截图用，文件名含 capture，不进默认测试集。
- H-03
  - `src/ui/title_desk_stage.gd`：开书动画最后改为盖黑，不再让桌面自身淡出。
  - 新增 `tests/ui/title_open_beat_cover_runner.(gd|tscn)`：headless 下做断言；加 `-- --capture` 在窗口下截帧。
- `start_screen.gd`、`card_art_catalog.gd` 未改。`diary_chapter_screen.gd` 按派工未碰。

## 根因与修复

### H-01「整理卡牌与残页」「灵界祈愿」卡图没更新

- **根因**：两个界面取图走的不是牌组页那条路。
  - `gacha_screen.gd:422` 和 `upgrade_screen.gd:227` 用的是 `ProgressionCatalog.card_art`，这是 40 行的旧整卡底图表。
  - 牌组页早已改为 `CardArt.art_window` 加印章。
  - 同一事实有两套取图实现，改一处另一处不会跟着变。
- **修复**：抽出共用卡面 `card_face.gd`，三个界面都用它。
  - 以后新卡只要按约定放图，三个界面会一起更新。
  - `ProgressionCatalog.card_art` 仍保留，其他探针在用；收口到资源注册表属于 R2-10，见候选池。
- **验证**：`v088_card_face_runner` 共 363 项检查，结果 OK。
  - 对 `card_art_catalog.all_card_ids()` 中的每张卡，祈愿结果卡和升级行都显示 v0.85 插画窗，且盖了印章。
  - 牌组缩略图仍是插画窗。
  - 未知 id 退回卡背，不会编造印章。

### H-02 日记跨页切换卡顿后闪烁

**根因**：读代码后用 GPU 截帧确认。旧实现的 stage 只有一对页面视口。

1. 翻页叶其实不翻过去：右页抬到约 90°，在顶点处发出 `flip_committed`，然后落回原来的右侧。
2. 在顶点那一帧，chapter 调 `apply_spread(new)`，`_fill_pages()` 同时改写左右两页的内容。
   - 左页插画在叶子还竖着时就直接换成新图，这就是用户看到的“闪烁成新关卡”。
   - 截图见 `before/turn_05_0330ms.png`：左页已是下一关，右侧只剩空白纸。
3. 同一帧里，`_fill_pages()` 用同步 `load()` 加载新关卡 1260×1770 的插画，这就是“卡顿一下”。
   - 实测翻页过程中最大帧间隔 **45.6 ms**。

**修复**（结构替换，不是加条件分支）：

- **三对页环形结构**：stage 持有前/当前/后三对 `DiaryPagePair`。
  - 相邻两开的插画通过 `load_threaded_request` 后台预取，页面视口提前渲染（`UPDATE_ONCE`）。
  - 当前那对页保持 `UPDATE_ALWAYS`（蜡封呼吸需要），相邻页渲染一次后停更。
- **双面翻页叶**：
  - 翻到下一页：叶正面是当前右页，叶背面是下一开左页（UV 水平镜像），叶下面露出下一开右页。
  - 翻回上一页：左右镜像。
  - 叶子真正翻到对侧（0→180°），越过 90° 后逐渐压平，落在对侧页之上。
- **提交只换引用**：`apply_spread(next)` 发现内容就是已备好的相邻页时，只轮换角色指针。
  - 叶子落地后重新绑定当前那对页，画面内容与落地叶完全一致，看不到切换。
  - 不重建节点，不加载纹理。
  - 轮换出去的那对页清空，等下一次 `set_neighbours` 时再准备。
- **兼容**：
  - `apply_spread`、`play_flip`、`set_flip_blocked`、`bounce_flip`、`is_flip_animating` 及各信号语义不变。
  - 新增可选的 `set_neighbours(prev, next)`，以及便捷方法 `apply_spread_list(list, index)`。
  - 未提供相邻页时（即 chapter 现状），翻页仍会落到新关卡上：叶下面是空白纸，内容在顶点处同步加载。也就是说，**卡顿要等 chapter 加上那一行才会消失**。
- **其他细节**：
  - 拖动被拦截时不显示叶下页（不剧透被封的下一页）。
  - 如果提交被拒（叶子翻到顶点但内容没变），叶子落回原侧。
  - 日记屏从路由缓存回来时，重新渲染相邻页，避免冻结后出现空的渲染目标。
  - 当前那对页始终排在树的最前面，所以 `find_child("SceneArt")` 这类探针仍会找到正在看的那一页。

**验证**：

- `diary_prepared_turn_runner`：28 项检查，OK。
  - 环里依次是前/当前/后三开；相邻页插画走 threaded request。
  - 翻到下一页时：叶正面是当前右页，背面是下一开左页，叶下是下一开右页。
  - 提交后：当前那对页就是原来的“后一页”实例；三对页的 instance id 集合不变；`blocking_loads` 不增加。
  - 落地后两页都绑定到新的那对页，叶下页隐藏。
  - 翻回上一页做了同样的检查。
  - 不传相邻页的旧调用方式仍能落到新页。
- GPU 截帧（`diary_turn_capture_runner`，窗口模式，1600×900），输出在 `.tools/ui-captures/diary_turn/{before,after}/`：

| | 最大帧间隔 | 翻到中途的画面 |
|---|---|---|
| 修复前 | 45.6 ms | 顶点处左页直接换成新插画；叶子落回右侧，叶下是空白纸 |
| 修复后（传了相邻页） | 12.0 ms | 280ms：叶子竖起，叶下已是第 3 叶右页；390/520ms：叶背面是第 3 叶的插画（方向正确，没有镜像）；700ms：落定后与叶背面内容完全一致 |

- 回归：`v085_diary_art`、`v083_diary_desk_p0`、`v055_diary_chapter`、`v085_props`、`screen_router` 全部 PASS。

**导入设置建议**（`assets/game/v0.85.0/diary/*.png`，16 张，本次**未改**）：

- 现状：
  - `compress/mode=0`（无损）：加载时要在 CPU 解码约 8.9 MB/张。
  - `mipmaps/generate=false`：1260×1770 的图在 512×720 的页面视口里只显示约 430×610，缩小时无 mip，容易出现锯齿和闪烁。
- 建议（交主协调者评估）：
  - `compress/mode=2`（VRAM 压缩）加 `compress/high_quality=true`（BPTC）：去掉 CPU 解码，显存约降到 1/4。
  - `mipmaps/generate=true`，同时把 `SceneArt.texture_filter` 设为 `LINEAR_WITH_MIPMAPS`（这条在 UI 侧，可随后跟进）。
  - `process/size_limit=1280`：页面最多用到约 2 倍显示尺寸。
  - 需要真窗口对比画质后再决定。

### H-03 点书时露出旧标题面板

- **根因**：
  - `start_screen` 把旧面板（假面低语标题、「检测到可继续的检查点」摘要、恢复上次备份/测试档案按钮）留在桌面层下面。
  - 平时这块面板被不透明的桌面底图完全挡住（见 `title_open_0_rest.png`）。
  - `title_desk_stage.play_open` 最后一步是 `tween_property(self, "modulate:a", 0.0, 0.22)`，把**桌面自己**淡出，于是把下面的旧面板露了出来；之后路由才开始淡出。
- **修复**：
  - 桌面最上层新增全屏黑色遮罩 `TitleOpenCover`，`bind()` 重新挂载按钮后它始终保持在最上面。
  - 开书最后一步改为遮罩从 0 淡到 1，桌面 modulate 始终保持 1。路由遮罩接手时画面已经全黑，下面任何东西都露不出来。
  - `reset_open()` 会复位遮罩。
- **验证**：
  - `title_open_beat_cover_runner`：12 项检查，OK。桌面是标题屏最上层；遮罩在桌面所有子节点之上；整个过程中桌面和屏幕 alpha 最小值都 ≥0.999；结束时遮罩 alpha 为 1、可见、覆盖全视口；复位后清除。
  - 窗口截帧 `title_open_{0_rest,1_mid,2_end}.png`：中间帧是变暗的桌面，没有旧面板文字；最后一帧全黑。

## 测试

全量 `tools/run_tests.sh`：`pass=89 fail=0 skipped=10 guard_block=0`（详见文末）。黄金回放（`tests/golden`）未执行 `--update`，本轨道只改表现层。

## 困难、候选方案与最终选择

1. **H-02 结构选择**
   - 方案 A：只把插画改成 threaded 预取，保留单对页、叶子竖起后落回原侧。可以去掉卡顿，但顶点处左页突变仍在，“闪烁”不会消失。
   - 方案 B：三对页环形结构加双面翻页叶（已采用）。从根上去掉“顶点处同时改写两页”这个动作。
   - 叶子落地时的弧度问题：叶子翻到 180° 后，弧形会朝下扎进左页。不能用负缩放把弧形翻回来（会翻转面剔除），所以改为让叶子越过 90° 后逐渐压平，并抬高 `LAND_LIFT=0.03` 落在左页之上。落地后换回静态左页，会有极小的高度差，截图上看不出来。
2. **文件预算**：`diary_desk_stage.gd` 原本就超过 UI 的 800 行预算（1610 行）。这次先把页面构建拆到 `diary_page_pair.gd`，再加环形逻辑，现在约 1470 行，仍超预算。请在 R3 拆分时继续把桌面道具（烛台、墨水瓶等 3D 布景）迁出。
3. **探针兼容**：原有测试用 `find_child("SceneArt"/"WaxSealArt"…)` 找节点。通过让当前那对页排在树的最前面保持兼容，没有改动任何旧测试。

## 风险

- 真窗口下拖动翻页的手感变了：拖满全宽只到叶子竖起（90°），松手后自动翻过去。需要用户确认。
- 路由缓存往返后相邻页能否正确重绘，已有代码保证，但只在 headless 下验证过节点结构，GPU 下未专门截图。
- 旧面板里的「恢复上次备份/测试档案」按钮平时被桌面底图遮住，但仍然可以点到（桌面是 PASS，底图是 IGNORE）。这是看不见却能点的入口，属于既有问题，本次不改，列入候选池。

## 跨角色请求

- **T2（`diary_chapter_screen.gd` 负责人）——H-02 需要的一行改动**：在 `_sync_desk_spread()` 中把

  ```gdscript
  _desk_stage.apply_spread(_current_spread())
  ```

  改为

  ```gdscript
  _desk_stage.apply_spread_list(_spread_list, _current_spread_idx)
  ```

  这一行等价于先 `apply_spread` 当前页，再 `set_neighbours(前一开, 后一开)`。不改这一行，翻页叶子已经会翻过去、不再在顶点闪换，但叶下仍是空白纸，顶点处仍会同步加载插画（卡顿仍在）。
- **主协调者**：评估上面的导入设置建议。
- **产品经理**：标题旧面板的去留，以及其中隐藏按钮的入口，放到 v0.89 Desk World 外壳中裁决。

## 候选池

- 标题旧面板整体移除，或把备份/测试入口迁到桌面道具上（v0.89）。
- `ProgressionCatalog.card_art` 和 `DeckCatalog.card_art` 收口到资源注册表（R2-10）。
- 日记插画导入设置改为 VRAM 压缩加 mipmap。

## 下一步入口

- T2 合入那一行后，重跑 `tests/ui/v084_diary_desk_flipstrip_capture_runner.tscn`（chapter 实际路径），确认叶下和叶背面都有内容。
- 截图对比：`tests/ui/diary_turn_capture_runner.tscn`（加 `-- --old=<旧 stage 副本>` 可生成修复前的对照）。

## 手动验证清单（真窗口）

1. 身份档案 →「整理卡牌与残页」：每张卡显示 v0.85 插画，右下角有稀有度×机制印章；没有插画的卡显示卡背。
2. 「灵界祈愿」单抽或三连：翻开后的卡面是 v0.85 插画加印章；点开详情正常。
3. 牌组页缩略图与之前一致。
4. 标题点书（继续）、新局、挑战：画面变暗推近后直接黑屏进入下一屏，**任何时刻**都看不到「假面低语」标题、检查点摘要、恢复备份/测试档案按钮。
5. 从下一屏回到标题：桌面恢复正常亮度，不残留黑屏。
6. 日记里向左拖、松手翻页（T2 合入一行后）：
   - 叶子从右侧翻起，越过竖直后背面是下一关的插画，落到左侧。
   - 右侧露出下一关的文字和蜡封。
   - 全程无卡顿，落地瞬间无闪烁。
7. 向右拖、翻回上一页：镜像效果同上。
8. 向被封的下一页拖：叶子弹回，叶下不露出下一页内容，状态栏提示「墨封未启」。
9. 战斗结算后的自动翻页：与第 6 条相同。
10. 日记合上 → hub → 再打开，然后翻页：叶背面和叶下内容正确，不出现空白或旧页。

## 全量结果

macOS，Godot 4.7.2 headless，三项热修全部提交后执行：

```text
run_tests: pass=89 fail=0 skipped=10 guard_block=0
```

- 包含 `tests/golden/golden_replay_runner`，结果 PASS，未执行 `--update`。
- 新增 3 个 runner 全部 PASS：`v088_card_face`（363 项）、`diary_prepared_turn`（28 项）、`title_open_beat_cover`（12 项）。
- `skipped` 为 capture/monkey 类。
