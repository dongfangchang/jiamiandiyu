# v0.89.0 UI 报告（轨道 D：P1-1 / BUG-0041 战斗手牌插画被挤压）

```text
版本：v0.89.0
角色：UI（轨道 D 单一负责人）
任务：P1-1 / BUG-0041：战斗手牌和打出飞卡改用共享卡面，插画按 512:390 显示，不压扁、不裁成横条、不压色
状态：完成（自动化回归 + 两种真窗口截图；用户真机观感验收待做）
修改文件：
  - src/ui/common/card_face.gd：新增 ART_WINDOW_ASPECT、window_size()、make_window_face()（紧凑卡面：固定为插画窗比例的尺寸，不被容器拉伸，角上盖稀有度×机制蜡封）。make_art / make_seal / make_face / face_art_path 未改，牌组、抽卡、升级三屏行为不变。
  - src/ui/battle_screen.gd：
      · 手牌卡重排为卡框结构：卡名（思源宋体）+ 费用 → 插画窗（CardFace.make_window_face，142×108，比例 1.315）→ 两行规则短句 → 目标/仪式/联动短签 → 选择按钮。
      · 删除插画横条（custom_minimum_size (0,34)）和统一 modulate(0.94,0.9,0.78,0.92) 压色；删除按 has_art_window 分支切换 stretch_mode 的代码。
      · 只在快照 hand[i].playable == false 时整卡压暗（UNPLAYABLE_DIM），悬停提示写出 blocked_reason 对应文案；UI 不计算规则。
      · 卡面尺寸 208×196 → 156×228；手牌区标题行与弃置祭坛合并为一行，腾出高度给插画窗。HandPanel 高度 292 不变，所以页面其他区域位置不变。
      · 类别（人格/封印物/非凡能力/值夜者支援）从卡面移到悬停提示首行，与卡名、费用写在一起。
      · 打出飞卡动画改用同一卡面（CastCard，130×99），不再用单独拉伸的 TextureRect。
      · get_card_art_path() 改为委托 CardFace.art_path()，与其他三屏取图顺序一致。
      · 结束回合按钮命名为 EndTurnButton，供测试按节点名查找（不访问私有成员）。
  - 新增 tests/ui/battle_hand_card_face_runner.(gd|tscn)：默认测试集内的回归测试。
  - 新增 tests/ui/battle_hand_capture_runner.(gd|tscn)：真窗口截图用，文件名含 capture，不进默认测试集。
依赖：R2 快照字段 hand[i].playable / blocked_reason / preview（玩法层已提供）；CardArt 目录与 v0.85 插画窗、蜡封资产（未改）。
验证：见下文“验证”。
困难与候选方案：见下文。
最终解决：固定卡宽，从插画宽度推出插画高度，再把剩下的高度分给文字；合并手牌标题行和祭坛行来腾高度。
风险：见下文。
跨角色请求：无。
下一步入口：用户真窗口观感确认；如果还觉得插画偏小，可以按“候选池”第 1 条做悬停放大预览。
```

## 根因复述

手牌是 v0.35 时期的“文字卡 + 装饰横条”版式，插画只占 190×34 的横条（约 5.6:1），v0.85 的 512×390 插画（约 1.31:1）被 `KEEP_ASPECT_COVERED` 裁掉八成以上，又被统一压暗压黄。牌组、抽卡、升级三屏在 H-01 已经改用 `card_face`，只有战斗还在用旧版式。

## 困难与候选方案

1. **高度预算**：ADR-0030 和 BUG-0036 把 HandPanel 固定在 292 px（1600×900 下底边 800，给场景地板留 100 px）。旧布局里卡牌只能分到约 199 px 高，放进 1.31:1 的插画窗后，留给卡名、规则和按钮的高度不够。
   - 方案 A：整卡统一缩放（`scale`）。插画不变形，但 12 px 的规则字会缩到 10 px 左右，读不清。未采用。
   - 方案 B：扇形重叠。卡宽不再受限，但拖拽、悬停和点选的命中区域都要重做，改动面大。未采用。
   - 方案 C（采用）：手牌标题与弃置祭坛并成一行（祭坛节点、固定高度和文案逻辑都不变），卡牌区高度从约 199 增至 230；卡宽 156，插画窗 142×108；规则短句两行（行距 −3），选择按钮高 24。
2. **规则短句**：旧版用 `fixed_text`（内含 ScrollContainer），窄卡里会出现滚动条。改为两行 `wrapped_label`，超出部分以省略号截断，完整文字放在悬停提示里。规则文字仍来自 `card_details.effect_text`，UI 不做计算。
3. **过程记录（批量替换误伤）**：第一次批量替换时，起始标记在车道构建函数里也出现过一次，导致误删一段代码。发现后从 HEAD 恢复本文件（该文件开工时没有其他人的改动），再用限定到 `_build_hand_card` 范围的唯一匹配重新应用修改。最终 diff 只涉及手牌、飞卡和标题行。

## 验证

- `tools/run_tests.sh`：见文末“测试结果”。
- 新回归 `tests/ui/battle_hand_card_face_runner.tscn`：`BATTLE_HAND_CARD_FACE_OK checks=314`。覆盖：
  - 1600×900 和 1100×700 各测两种布局：一种按项目拉伸设置模拟真实窗口（canvas_items + keep，逻辑尺寸 1600×900），一种是未缩放的原始尺寸。
  - 每张手牌：插画显示比例在 1.31±0.05 之间（实测 1.315）；`stretch_mode != STRETCH_SCALE`；插画高度 ≥ 90（不是横条）；插画 modulate 为白色（没有压色）；取图路径等于 `CardFace.art_path`。
  - 只有 `playable=false` 的那张牌被压暗；选择按钮完整落在卡内，高度 ≥ 20。
  - 所有手牌都在 HandPanel 内。窗口布局下，EndTurnButton 和 HandPanel 都在视口内；原始 1100×700 布局下，EndTurnButton 和每张手牌都能通过页面滚动到达视口内（ADR-0030）。
  - 打出飞卡：`CastCard` 存在，插画比例同样在 1.31±0.05 之间，没有压色。
- 旧测试：`v051_hand_clip_probe`（选择按钮在 900 以内、在卡内）、`v052_frame_hp_bg`（第 7 张牌、裁切、横向滚动）、`v053_canvas_floor`（手牌框底边 ≤ 800）、`v025_viewport_guidance`、`v014_card_layout`、`v035/v036`（拖拽、点选、弃置祭坛）、`v088_card_face`（三屏卡面）均未修改，全部通过。

### 截图（真窗口，非 headless，`tests/ui/battle_hand_capture_runner.tscn`）

| 窗口 | 修复前 | 修复后 |
|---|---|---|
| 1600×900 | `.tools/ui-captures/v089_battle_hand_1600x900_before.png` | `.tools/ui-captures/v089_battle_hand_1600x900_after.png` |
| 1100×700 | `.tools/ui-captures/v089_battle_hand_1100x700_before.png` | `.tools/ui-captures/v089_battle_hand_1100x700_after.png` |

（1100×700 窗口在 keep 拉伸下内容区是 16:9，所以保存出的 PNG 为 1100×618。）

截图对照 ADR-0030：修复前，插画是 190×34 的横条，裁剩中间一条，而且发黄。修复后，7 张手牌都显示完整构图（142×108），右下角有蜡封；第 6 张“第二视觉”（快照标记不可打出）整卡压暗。结束回合、退出战斗、打出所选牌、取消选择和所有选择按钮都在视口内；手牌框底边仍在 800，场景地板带保留。

## 风险

- 卡宽从 208 缩到 156，规则短句只显示两行，更长的规则文字会以省略号截断，完整内容要悬停才能看到。现有卡牌的规则文字大多一到两行。
- 卡名字号 14（宋体加粗变体），低于 EXPERIENCE_ARCHITECTURE §5.1 给阅读页定的“题名 ≥ 28 px”。§5.1 针对日记阅读页；战斗手牌沿用原有的 12–17 px 档，本轮没有提高。
- `battle_screen.gd` 2944 行（原 2952），超过 800 行预算（守卫只报告不阻断，开工前就已超出）。本次行数基本持平，没有拆分。

## 候选池

1. 悬停手牌时在手牌区上方弹出大尺寸卡面（完整 600×840 卡框），既解决插画偏小，又能显示完整规则。
2. 等 X1 的 `theme_tokens.gd` 建好后，把手牌底色和边框里的 `Color("#…")` 字面量迁到令牌（本轮没有新增字面量）。

## 测试结果

`tools/run_tests.sh`：`run_tests: pass=93 fail=0 skipped=11 guard_block=0`（黄金回放 `tests/golden/golden_replay_runner.tscn` 通过且未改动；只报告不阻断的 GUARD 是 battle_screen.gd 等文件超出行数预算，开工前就已超出）。
