# BUG-0041：战斗手牌插画被挤压

- 日期：2026-11-24
- 严重度：S2（观感，主路径每场战斗都能看到）
- 版本：v0.89.0 发现（v0.85 换插画以后变得明显）
- 状态：已关闭（用户 2026-11-25 真窗口确认）

## 症状

战斗中手牌上的卡牌插画被压成一条细带，构图看不清，看起来像被挤压。

## 根因

- 手牌是 `HAND_CARD_SIZE = 208×196` 的文字卡（`src/ui/battle_screen.gd:142`），插画只占一条 `custom_minimum_size = (0, 34)` 的横带（`battle_screen.gd:1673`）。
- v0.85 的插画窗口是 512×390（约 1.3:1），塞进约 190×34（约 5.6:1）的横带后，`KEEP_ASPECT_COVERED` 会裁掉 80% 以上的画面，只剩中间一条。
- 横带还被统一 `modulate` 压暗压黄（`battle_screen.gd:1685`）。
- 手牌版式是 v0.35 前后"文字卡 + 装饰条"时期的设计，v0.85 换成插画卡框体系时没有同步改。牌组、抽卡、升级三屏已经改用共享卡面组件 `src/ui/common/card_face.gd`（H-01），只有战斗没改。

## 修复策略

- 战斗手牌改用共享卡面组件 `card_face`，与卡框规范（`art/README.md` §0）一致：插画窗口按 512:390 的比例，下方是卡名、费用和规则短句。
- 手牌区高度必须守住 ADR-0030 的布局红线：手牌和操作按钮在 1600×900 和 1100×700 下都可见；如果一张卡的高度放不下，就缩小整卡，不能压扁插画。
- 打出时的飞卡动画（`battle_screen.gd:2801`）也改用同一卡面。

## 回归测试

- UI 测试：每张手牌的插画控件宽高比在 1.31 ± 0.05 之间；`stretch_mode` 不得是 `SCALE`。
- 在 1600×900 和 1100×700 两种窗口下截图，并对照 ADR-0030 检查。

## 修复（v0.89.0 轨道 D）

- `src/ui/common/card_face.gd` 新增 `make_window_face(definition_id, width)`：生成紧凑卡面，尺寸固定为插画窗比例（512:390），不会被父容器拉伸，角上盖稀有度×机制蜡封。原有 `make_art / make_seal / make_face` 未改。
- `src/ui/battle_screen.gd`：
  - 手牌卡改为卡框结构：卡名（思源宋体）+ 费用 → 插画窗 142×108 → 两行规则短句 → 目标/仪式短签 → 选择按钮。卡尺寸 156×228。
  - 删除 34 px 横条和统一 `modulate` 压色。只在快照 `hand[i].playable == false` 时整卡压暗，悬停提示写出 `blocked_reason` 对应文案。
  - 手牌标题行与弃置祭坛合并为一行，卡牌区多出约 30 px 高度。HandPanel 仍为 292 px，其他区域位置不变（ADR-0030 / BUG-0036 预算不变）。
  - 打出飞卡改用同一卡面（`CastCard`）。
  - `get_card_art_path()` 委托 `CardFace.art_path()`，四屏取图顺序一致。
- 详细记录：`docs/reports/v0.89.0/ui_battle_hand.md`。

## 回归

- `tests/ui/battle_hand_card_face_runner.tscn`（默认测试集）：1600×900 与 1100×700 各测窗口拉伸布局和原始布局。断言每张手牌和飞卡的插画显示比例为 1.31±0.05、`stretch_mode != STRETCH_SCALE`、插画高度 ≥ 90、没有压色、取图路径与共享卡面一致；只有不可打出的牌被压暗；手牌全部在 HandPanel 内；结束回合按钮和手牌在视口内，或可通过页面滚动到达。
- 真窗口截图：`tests/ui/battle_hand_capture_runner.tscn -- --capture-size=WxH --capture-tag=before|after`。修复前后的对照图见报告。
