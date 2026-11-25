# 美术报告 · v0.89.0

```text
版本：v0.89.0
角色：美术
任务：ART-KEY-01（三风格方向目标帧：标题页 + 日记页）
状态：完成（概念图齐；待用户选型；不需 UI 审稿；画面实现暂停）
修改文件：
  art/key_frames/directions/A/{title,diary}.png
  art/key_frames/directions/B/{title,diary}.png
  art/key_frames/directions/C/{title,diary}.png
  art/key_frames/directions/overview.png
  art/key_frames/directions/README.md
  art/key_frames/directions/_work/kf_*_base.jpg
  docs/reports/v0.89.0/art.md
  .cursor/agents/art/tasks.md
  .cursor/agent-memory/art/journal.md
依赖：
  ADR-0037；ART_DIRECTION；思源宋体 assets/ui/fonts/SourceHanSerifSC-Regular.otf
  diary-page-art（左页无字约束参考）；无用户参考图
验证：
  6 帧均为 1600×900 PNG；overview 3×2 带方向名
  标题页含存档摘要 + 菜单（挑战灰+解锁原因）；日记页含题名/正文/蜡封「启」
  插画生成底图无字，中文由思源宋体合成
困难与候选方案：
  1) 生成器不可靠出中文 → 无字底图 + Pillow 叠字
  2) 无参考图 → 按 ADR-0037 建议三方向差异化先出
最终解决：A 油画暗室 / B 铜版插画书 / C 立体透视舞台 各 title+diary；README 记光源/色板/材质/实现难度
风险：
  概念帧非实机；用户选型前不得做画面实现（ADR-0037 D1）
跨角色请求：
  请主会话转达用户挑选方向并批注（ART-KEY-02）；勿 UI 审稿；勿迁 assets/game
下一步入口：用户签字方向 → ART-KEY-02
```

## ART-KEY-01 交付路径

| 方向 | 标题页 | 日记页 |
|---|---|---|
| A 油画暗室 | `art/key_frames/directions/A/title.png` | `…/A/diary.png` |
| B 铜版插画书 | `…/B/title.png` | `…/B/diary.png` |
| C 立体透视舞台 | `…/C/title.png` | `…/C/diary.png` |
| 总览 | `art/key_frames/directions/overview.png` | |
| 说明 | `art/key_frames/directions/README.md` | |

## 先前交付（仍有效）

| ID | 路径 |
|---|---|
| DQ-01…06 | `art/assets/raster/desk_world/diary_quality/` |
| DW-07b | `art/assets/raster/desk_world/index_card/` |

## 未做 / 边界

- 未改 `src/ui/**`、未迁 `assets/game/**`
- 未开 ART-KEY-02 / ART-DW-X3 / ART-02…05
- 画面类实现按 ADR-0037 暂停
