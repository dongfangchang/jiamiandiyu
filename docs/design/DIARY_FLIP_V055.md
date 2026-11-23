# 罗塞尔日记翻页子系统（v0.55）

运行载体：Godot 4。实现：`src/ui/diary_chapter_screen.gd` + `diary_ui_catalog.gd`。

## 约束

1. 一个跨页单元 = 左页 + 右页；翻页切换整组 Spread；页内线索 / 结算 / 批注 / 墨渍不触发翻页。
2. 全局锁 `is_flipping`：为 true 时拒绝一切线索点击。
3. 翻页动画 0.7s：透明度 + 水平位移 + 边缘阴影；无夸张卷曲。
4. 禁止路线树 / 节点卡片 / 连线；阿勒苏霍德之笔仅结算短闪，不常驻。

## 数据

- Clue.state：`0` 未解锁 / `1` 可调查 / `2` 已完成
- Spread：`title_zh`、`left_clues`、`right_clues`、`is_main_complete`
- `spread_list` + `current_spread_idx`

## 层

- `PageCurrent`：当前跨页
- `PageNext`：预加载离屏层

## 信号

- `page_flip_started`
- `page_flip_finished`

## 战后结算衔接

战斗/休整会 `replace` 日记屏，只走 `apply_snapshot`。应用层在重建后调用 `present_post_encounter(node_id, outcome)`：

1. 聚焦刚结算线索所在 Spread（不立刻跳到下一叶）
2. 0-08 笔短闪 + `PenOverlay` 扫过（文案优先用 `clue_annotations`）
3. 若本 Spread 主线刚齐且还有下一叶：约 1.85s 后自动后翻（对齐加长笔演出）

## 相关表现

- 翻页 / 结算 / 擦拭 / 合书：`table_sfx` 程序化音效
- 灵性擦拭：`wipe_ink` 成功后走结算闪示（`InkWiped.annotation_zh`）
- 左右页纸纹各自着色，避免整摊同纹平铺
