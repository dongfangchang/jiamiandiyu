# v0.30.1 牌组序列提示与中文字体修复

- 版本：v0.30.0 发现，v0.30.1 修复验收。
- 角色：牌组玩法 / UI / 字体验证（主协调者指定文件归属）。
- 任务：修复提灯步显示可加入却返回 sequence_locked，修复中文方框。
- 状态：完成；未自行提交，由主协调者集成。

## 根因与修复

1. DeckEngine 添加命令已有序列限制，但快照仅输出 owned，UI 把拥有误当成可加入；pending 刷新还会无条件启用所有卡牌按钮。
2. 添加命令和快照共用 `_card_add_reason`，输出 `can_add`、`add_reason_code`、`required_sequence`。UI 显示「已拥有 · 需序列 8」、禁用加入、显示中文原因；来自旧预设的非法卡仍可移除。pending 解除保留可操作状态。
3. 当前 macOS 的旧 SystemFont 列表匹配到 Open Sans SemiBold；实测敌、稳等 has_char=false。加 PingFang SC 仍匹配 PingFang HK，敌、稳仍缺字，故未采用仅改回退名单的方案。
4. 共享主题直接预加载完整 Noto Sans CJK SC Regular 2.004，离线字形一致。16,437,364 字节；PM 与主协调者已确认成本和授权。固定来源、提交与 SHA256 在 `assets/ui/fonts/README.md`，许可证在 `OFL.txt`。不改高级卡能力或序列限制。

## 验证

- V07_DECK_TESTS_OK checks=287：序列 9 提灯步快照、命令拒绝及不变性、晋升后重新可加入。
- V07_DECK_UI_SMOKE_OK checks=64：锁定按钮 pending 后仍禁用、中文原因、非法已入组卡可移除、1100×700 操作可达。
- V030_FONT_OK glyphs=900：扫描 src/ui 与 data 的所有中文字符，900 个不同字形均存在。
- 非 headless OpenGL 实际渲染成功，截图 `.tools/ui-captures/v0.30.0/chinese-font.png` 已打开审阅：敌、稳、防御、提灯步及原因文本无方框。
- Godot 编辑器资源导入通过；git diff --check 通过。

## 风险与后续

- 字体改变各平台文字度量，主协调者需继续全流程窗口审阅；牌组1100×700布局回归通过。
- 维护字体时必须同步版本、来源、SHA及字形覆盖测试。
- 依赖：既有序列数据、DeckSnapshot字典协议；无新存档字段，无执行库或运行时网络依赖。
