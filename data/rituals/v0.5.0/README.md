# v0.5.0 晋升仪式

唯一仪式：`ritual.v050.tampered_obituary`。

- 三步：选择两个姓名、排列三个事件、选择一个封印。
- 错误步骤增加 2 点污染。
- 提示消耗 1 点灵性，每个步骤最多使用一次。
- 成功后占卜家序列 9 晋升到序列 8“小丑”。

答案字段只由领域层读取；公开 `RitualSnapshot` 不包含 `correct_ids`、`correct_order` 或 `correct_id`。
