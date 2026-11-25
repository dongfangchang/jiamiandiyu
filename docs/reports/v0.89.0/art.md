# 美术报告 · v0.89.0

```text
版本：v0.89.0
角色：美术
任务：ART-KEY-03（桌面总览 hub 三方案目标帧）
状态：部分完成（三方案已交待选；未自称 approved；未开 04–11）
修改文件：
  art/key_frames/desk/options/{1,2,3,overview}.png
  art/key_frames/desk/README.md
  art/key_frames/desk/_work/kf_desk_opt{1,2,3}_base.jpg
  art/key_frames/STATUS.md
  docs/reports/v0.89.0/art.md
  .cursor/agents/art/tasks.md
  .cursor/agent-memory/art/journal.md
依赖：
  ADR-0037 附录 A；一致性对照 title/diary candidate_v2（尚未签字）
  思源宋体 assets/ui/fonts/SourceHanSerifSC-Regular.otf
验证：
  三方案 + overview 均为 1600×900 PNG
  索引卡菜单字号 26–28px（≥22）；对比度抽检 ≈7.56（≥4.5）
  插画底图无字；中文思源叠字；悬停项各异（日记 / 祈愿 / 档案）
困难与候选方案：
  1) 底图索引卡过小难读 → 概念帧叠可读尺寸索引卡（B 纸面）承载六行入口
  2) 生成器中文不可靠 → 禁字底图 + Pillow 叠字
最终解决：产出 desk 三方案 + overview + README；STATUS=待选；等用户选型
风险：
  title/diary 仍批注中；desk 一致性暂以 candidate_v2 为锚，签字后可能需微调同书同烛
跨角色请求：
  请主会话转达用户对 desk 三方案选型（1 俯角铺开 / 2 雨窗斜透视 / 3 近景密布）；
  勿迁 assets/game；勿开 KEY-04…11；勿宣布 approved
下一步入口：用户选定 desk 方案 → 批注轮 → approved.png；并行可继续等 title/diary 签字
```

## ART-KEY-03 三方案差异（一句话）

| 方案 | 路径 | 差异 |
|---|---|---|
| 1 · 俯角静物铺开 | `art/key_frames/desk/options/1.png` | 略俯视横铺；悬停「日记」；索引卡右下 |
| 2 · 雨窗斜透视 | `art/key_frames/desk/options/2.png` | 保留书架雨窗进深；悬停「祈愿」；同房感最强 |
| 3 · 近景密布 | `art/key_frames/desk/options/3.png` | 镜头更近更密；悬停「档案」；索引卡左前大卡 |

总览：`art/key_frames/desk/options/overview.png`  
说明：`art/key_frames/desk/README.md`（构图 + 实现方式：分层绘制优先）

## ART-KEY-02（仍有效 · 待签字）

```text
任务：ART-KEY-02（title/diary candidate_v2）
状态：部分完成（candidate_v2 已交；待用户签字 → approved.png；未自称 approved）
路径：
  art/key_frames/title/candidate_v2.png
  art/key_frames/diary/candidate_v2.png
```

## 先前交付（仍有效）

| ID | 路径 |
|---|---|
| ART-KEY-01 | `art/key_frames/directions/{A,B,C}/{title,diary}.png` + overview |
| DQ-01…06 | `art/assets/raster/desk_world/diary_quality/` |
| DW-07b | `art/assets/raster/desk_world/index_card/` |

## 未做 / 边界

- 未改 `src/ui/**`、未迁 `assets/game/**`
- 未开 ART-KEY-04…11；未宣布 approved / 用户签字
- 画面类实现仍按 ADR-0037 暂停
