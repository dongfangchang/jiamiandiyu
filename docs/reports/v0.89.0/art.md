# 美术报告 · v0.89.0

```text
版本：v0.89.0
角色：美术
任务：ART-KEY-03-rev（desk options_v2 · 旧纸索引卡吃烛光）
状态：完成（三方案待选；未自称 approved；未开 04–11）
修改文件：
  art/key_frames/desk/options_v2/{1,2,3,overview}.png
  art/key_frames/desk/options_v2/README.md
  art/key_frames/desk/_work/kf_desk_v2_opt{1,2,3}_base.jpg
  art/key_frames/STATUS.md
  docs/reports/v0.89.0/art.md
  .cursor/agents/art/tasks.md
  .cursor/agent-memory/art/journal.md
依赖：
  UI-KEY-DESK-JOINT；ADR-0037 附录 A/C；对照 title/approved.png
  思源宋体 assets/ui/fonts/SourceHanSerifSC-Regular.otf
验证：
  三方案 + overview 均为 1600×900
  索引卡旧米黄+暖橙高光+接触阴影；无白底便签
  六行：日记/档案/卡匣/祈愿/卷宗/熄烛；字号 24；对比度 ≈5.3–5.5
  悬停：1=日记、2=祈愿、3=档案（行高亮 + 物件提亮）
跨角色请求：
  请主会话转达用户选型 options_v2；审「卡是否吃光、是否像桌上旧纸」
  勿迁 assets/game；勿开 KEY-04…11
下一步入口：用户选定 desk → 批注 → approved；并行等 diary v3 签字
```

## ART-KEY-03-rev 三方案差异

| 方案 | 路径 | 差异 |
|---|---|---|
| 1 · 俯角铺开 | `options_v2/1.png` | 悬停「日记」；索引卡右前 |
| 2 · 雨窗进深 | `options_v2/2.png` | 悬停「祈愿」；同房感最强 |
| 3 · 近景大卡 | `options_v2/3.png` | 悬停「档案」；左前大卡 |

总览：`art/key_frames/desk/options_v2/overview.png`  
说明：`art/key_frames/desk/options_v2/README.md`

---

```text
版本：v0.89.0
角色：美术
任务：ART-KEY-02b（日记 candidate_v3 · 印纸）
状态：完成（已交批注；未自称 approved）
修改文件：
  art/key_frames/diary/candidate_v3.png
  art/key_frames/_work/kf_diary_v3_base.jpg
  art/key_frames/STATUS.md
  （见提交 862db00）
依赖：UI-KEY-DIARY-JOINT；title/approved.png
验证：
  1600×900；无半透明浮层；右页印纸；蜡心「启」；正文对比度 ≈4.8
跨角色请求：请用户审 diary「字是否印在本子上」
```

## 先前交付（仍有效）

| ID | 路径 | 状态 |
|---|---|---|
| ART-KEY-01 | `art/key_frames/directions/…` | done |
| ART-KEY-02 title | `title/approved.png` | 已签字 |
| ART-KEY-02 diary v2 | `diary/candidate_v2.png` | 驳回留档 |
| ART-KEY-03 | `desk/options/…` | 全驳回留档 |
| DQ / DW-07b | `art/assets/raster/desk_world/…` | 仍有效 |

## 未做 / 边界

- 未改 `src/ui/**`、未迁 `assets/game/**`
- 未开 ART-KEY-04…11；未宣布 diary/desk approved
