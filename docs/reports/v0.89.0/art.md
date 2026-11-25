# 美术报告 · v0.89.0

```text
版本：v0.89.0
角色：美术
任务：ART-KEY-02b（日记 candidate_v3 · 印纸）
状态：完成（已交批注；未自称 approved）
修改文件：
  art/key_frames/diary/candidate_v3.png
  art/key_frames/_work/kf_diary_v3_base.jpg
  art/key_frames/STATUS.md
  docs/reports/v0.89.0/art.md
  .cursor/agents/art/tasks.md
  .cursor/agent-memory/art/journal.md
依赖：
  UI-KEY-DIARY-JOINT（落点%/字号/禁浮层）；ADR-0037 附录 A/C
  对照 art/key_frames/title/approved.png
  思源宋体 assets/ui/fonts/SourceHanSerifSC-Regular.otf
验证：
  1600×900 PNG；底图无字无半透明浮层
  题名/正文按右页矩形% multiply 印纸；蜡封「启」压蜡心
  正文区对比度抽检 ≈4.8（≥4.5）；同房同桌同烛对照 title
跨角色请求：
  请主会话转达用户审 diary v3「字是否印在本子上」；通过后改名 approved.png
  勿迁 assets/game；勿开 KEY-04…11
下一步入口：用户拍板 diary → 并行/紧接 ART-KEY-03-rev desk options_v2
```

## ART-KEY-02b 要点

- 驳回消除：不再铺半透明米黄 HUD 底板；墨迹直接乘算到右页纸纹。
- 样本文案：题名「第一卷 · 雨夜来信」；蜡封「启」。
- 落点参照 UI 纪要：题名 (12,9,70,7)、正文 (12,18,68,46)、蜡心 ≈(72,82)。

## 先前交付（仍有效）

| ID | 路径 | 状态 |
|---|---|---|
| ART-KEY-01 | `art/key_frames/directions/{A,B,C}/…` | done |
| ART-KEY-02 title | `art/key_frames/title/approved.png` | 已签字 |
| ART-KEY-02 diary v2 | `art/key_frames/diary/candidate_v2.png` | 驳回留档 |
| ART-KEY-03 | `art/key_frames/desk/options/{1,2,3,overview}.png` | 全驳回留档 |
| DQ / DW-07b | `art/assets/raster/desk_world/…` | 仍有效 |

## 未做 / 边界

- 未改 `src/ui/**`、未迁 `assets/game/**`
- 未开 ART-KEY-04…11；未宣布 diary/desk approved
