# 0-08 三分支篡改支线（v0.72 冻结）

> 正式契约。由 `DIARY_008_BRANCH_DRAFT.md` 升格；玩法侧 overlay 语义自 v0.55 起已落地，本版补齐文档冻结与真三层字迹验收。  
> 约束：不新卡 / 不扩第二途径 / 不回归路线树；主路径禁止新增原生 `OptionButton`。

## 目标

阿勒苏霍德之笔在结算时不只写批注，还能**改写未读字迹**，形成三条可感知分支。

## 三分支（同页、不新卡）

| 分支 | 触发 | 效果 |
|---|---|---|
| A 真相落下 | 胜（默认） | 完成批注 + 解锁下一条 |
| B 墨渍改写 | 胜且 revision 命中（约 1/3） | 写入同页一条 locked 线索的 `clue_overlays`（不改内容 JSON 主键 / node_id） |
| C 夜色吞没 | 败 | 软失败 + 墨渍回涌；可灵性擦拭 |

## Snapshot 契约

- `clue_overlays: { node_id: { text_zh, source: "0-08", margin_note_zh? } }`
- UI catalog 必须同时保留：
  - `base_text_zh`：日记 JSON 原迹
  - `text_zh` / `overwrite_text_zh`：笔改后的可读覆写（有 overlay 时）
  - `rewritten_by_pen: true`
- UI 渲染：褐底原迹（可划掉/淡化）+ 暗金覆写叠层 + 「笔改过」戳；node_id 不变。

## 非目标

- 完整长篇叙事重写
- 新卡 / 第二途径 / 路线树

## 验收

1. 胜结算可出现 overlay，且目标仍是原 `node_id`。
2. 日记屏对笔改线索同时可见原迹与金覆写。
3. 探针 `V072_*` + 既有 `V055_DIARY_UNLOCK` 回归绿。
