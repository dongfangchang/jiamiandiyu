# 美术报告 · v0.89.0

```text
版本：v0.89.0
角色：美术
任务：ART-KEY-02（按附录 A/B 改标题+日记目标帧 → candidate_v2）
状态：部分完成（candidate_v2 已交；待用户签字 → approved.png；未自称 approved）
修改文件：
  art/key_frames/title/candidate_v2.png
  art/key_frames/diary/candidate_v2.png
  art/key_frames/_work/kf_{title,diary}_v2_base.jpg
  art/key_frames/STATUS.md
  docs/reports/v0.89.0/art.md
  .cursor/agents/art/tasks.md
  .cursor/agent-memory/art/journal.md
依赖：
  ADR-0037 附录 A（标题=A / 日记纸面=B / 环境=A）+ 附录 B 批注
  ART-KEY-01 方向图；思源宋体 assets/ui/fonts/SourceHanSerifSC-Regular.otf
验证：
  两帧均为 1600×900 PNG
  标题菜单字号 32px（≥22）、摘要 20px（≥16）；日记正文 22px（≥20）
  对比度抽检：标题菜单≈15.0；日记正文≈5.3（均 ≥4.5）
  插画底图无字；中文思源宋体叠字；蜡封仅一枚，「启」压印在蜡心
困难与候选方案：
  1) 同房同桌同烛同书 → 标题底参考 A；日记环境参考 A、纸面参考 B 联合出图
  2) 右页偏暗 → 羊皮纸 wash 提亮正文区以满足对比度
  3) 「启」须压在蜡上而非旁侧红钮 → 在无字底图上做圆域红点检测再叠字
最终解决：产出 title/diary candidate_v2；STATUS 标批注中；等用户圈改或签字
风险：
  书皮金饰在开合两态仍可能被用户挑一致性；未做 approved
跨角色请求：
  请主会话转达用户审 candidate_v2（签字或继续批注）；勿迁 assets/game；勿开 KEY-03…11
下一步入口：用户签字 → 改名 approved.png；或批注 → candidate_v3
```

## ART-KEY-02 构图说明

### 标题页 `art/key_frames/title/candidate_v2.png`

- **风格**：A 油画暗室（伦勃朗烛光、厚涂、雨窗/书架）。
- **构图**：左烛 + 桌面杂物（怀表、烟斗、蓝金卡背、墨水瓶、红蜡信件）；右中合上的酒红皮面日记（金角饰 + 空白金饰板，无字）；右侧暗区直接排菜单（采纳附录 B.1，不放书签纸条）。
- **文案**：假面低语 / 存档摘要 / 继续·新的日记·挑战（灰+「完成序列 8 晋升后开放」）·设置·离开。

### 日记页 `art/key_frames/diary/candidate_v2.png`

- **风格**：环境层 A（同烛同桌同雨窗）+ 纸面层 B（铜版页框 + 左页铜版街景插画）。
- **构图**：开本推近；左页雨夜巷道插画；右页题名与正文留足页边距，避开花饰；**单枚**红蜡封，「启」压印蜡心（附录 B.2）。
- **文案**：第一卷 · 雨夜来信 + 正文（廷根雨夜 / 无寄信人红蜡抉择）。

### 一致性锚点

同一房间雨窗、同一张深色木桌、同一支黄铜烛台熔蜡烛、同一本酒红皮日记（合=标题 / 开=日记）。

## 先前交付（仍有效）

| ID | 路径 |
|---|---|
| ART-KEY-01 | `art/key_frames/directions/{A,B,C}/{title,diary}.png` + overview |
| DQ-01…06 | `art/assets/raster/desk_world/diary_quality/` |
| DW-07b | `art/assets/raster/desk_world/index_card/` |

## 未做 / 边界

- 未改 `src/ui/**`、未迁 `assets/game/**`
- 未开 ART-KEY-03…11；未宣布 approved / 用户签字
- 画面类实现仍按 ADR-0037 暂停
