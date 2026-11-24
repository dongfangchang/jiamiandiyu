# 美术报告 · v0.89.0

```text
版本：v0.89.0
角色：美术
任务：ART-DQ（DQ-01…06）+ ART-DW-07b（索引卡）
状态：完成（候选齐；待 UI 审稿 / 真窗口对比）
修改文件：
  art/assets/raster/desk_world/diary_quality/**（DQ-01…06）
  art/assets/raster/desk_world/index_card/**
  art/assets/raster/desk_world/_overview/diary_quality_dq_overview_2048.png
  art/assets/raster/desk_world/_work/dq*.jpg
  art/assets/raster/desk_world/README.md
  docs/reports/v0.89.0/art.md
  docs/reports/v0.89.0/art_dq_before_after_schematic.png
  .cursor/agents/art/tasks.md
  .cursor/agent-memory/art/journal.md
依赖：
  ART_BRIEF_DESK_WORLD §5；EXPERIENCE_ARCHITECTURE §5.1；ADR-0034；DESK_WORLD_STATIONS
验证：
  DQ-01 room_backplate 3840×2160；下沿压暗
  DQ-02 albedo/normal/roughness 均为 2048；albedo 边缘交叉淡化
  DQ-03 cover 2048 + fore_edge 1024×128（程序化无字）
  DQ-04 页眉/四角/横线/涂鸦×6/墨渍×4 齐；透明底墨褐
  DQ-05 ribbon 160×900 RGBA；中段留白给「合上」；清洁版无墨渍
  DQ-06 contact_shadow ×14 与物件同尺寸
  DW-07b index_card 600×900；6 行空白书写线；四角 alpha=0
  总览 + 示意对比图已出
困难与候选方案：
  1) 书口生成易夹带印刷字 → 改程序化纸层
  2) 丝带初版墨渍过重 → 重出清洁版
  3) 索引卡源图线数偏多 → 清线后重画 6 行
最终解决：按 BRIEF 尺寸落盘；程序化补洞；清洁丝带；未迁 assets/game
风险：
  真窗口「现状 vs 接资产后」截图须 UI 接入后才能用户签字；本报告示意对比非实机
  normal/roughness 为亮度派生，非扫面 PBR；若渲染器 ADR 要求真 PBR 可能重修
跨角色请求：
  请 **ui-designer** 审 DQ-01…06 + DW-07b；接进日记站后截 1600×900 / 2920×1753
  审过请 **coordinator** 迁 `assets/game/desk_world/`（勿美术自迁）
下一步入口：UI 审稿结论；退回按 DQ-ID / DW-07b 列清单
```

## 交付路径

| ID | 路径 |
|---|---|
| DQ-01 | `art/assets/raster/desk_world/diary_quality/dq01/room_backplate.png` |
| DQ-02 | `…/dq02/desk_{albedo,normal,roughness}.png` |
| DQ-03 | `…/dq03/cover_{albedo,normal}.png` · `fore_edge.png` |
| DQ-04 | `…/dq04/`（16 张：ornament / corners×4 / ruled / doodles×6 / blots×4） |
| DQ-05 | `…/dq05/ribbon_bookmark.png` (+shadow) |
| DQ-06 | `…/dq06/contact_shadow_*.png` ×14 |
| DW-07b | `art/assets/raster/desk_world/index_card/index_card.png` (+shadow) |
| 总览 | `art/assets/raster/desk_world/_overview/diary_quality_dq_overview_2048.png` |
| 示意对比 | `docs/reports/v0.89.0/art_dq_before_after_schematic.png`（左：扁平面材代理；右：DQ 资产拼贴） |

## 未做 / 边界

- 未改 `src/ui/**`、未迁 `assets/game/**`
- 未开 ART-DW-X3 / ART-02…05
