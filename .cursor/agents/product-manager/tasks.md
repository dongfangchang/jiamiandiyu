# Tasks · product-manager

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 第二次下发（用户反馈 → ADR-0034）**：①控件绑定文字，物件只是画面；②替换即删除，禁止遮挡或隐藏旧界面；③日记可读性底线和画面升级。当前版本 **v0.89.0**（`docs/versions/v0.89.0.md`），P0 条目优先于其他所有条目。主会话会定时轮询本文件：done 条目必须写证据（提交 SHA、截图路径、测试输出），主会话据此合并、推送并下发后续任务。

### PM-09 · 目标帧用户裁决落盘（title 签字 / diary·desk 驳回）
- status: done
- 来源: 用户裁决 2026-11-25；主会话已更新 art/ui tasks 与 `art/key_frames/STATUS.md`
- 改哪些: `docs/versions/v0.89.0.md` §1.1.1；`docs/decisions/ADR-0037-target-frame-first.md` 附录 C；CURRENT_VERSION；ACTIVE_PLAN；`docs/reports/v0.89.0/product_manager.md`
- 完成标准: 版本文档登记 title `approved.png` 与 diary/desk 驳回理由；ADR 附录补「文字载体须承接场景光；禁止纯白悬浮便签；目标帧 art+UI 联合」；commit+push（勿 force）
- 怎么验: 文档与 STATUS 一致；远程含 docs + approved
- 证据/说明: 见同 commit（SHA 提交后回填）；签字路径 `art/key_frames/title/approved.png`；报告 `docs/reports/v0.89.0/product_manager.md`

### PM-07 · v0.88 收口
- status: done
- 证据/说明: 用户 2026-11-24 确认 H-01 卡图、H-02 翻页通过；v0.88 有条件关闭；新报 BUG-0041 → v0.89 P1-1
- 内容: H-01（卡图）、H-02（翻页）请用户真窗口确认；H-03 已被否决并转入 v0.89 P0-1；`reink.generic.05` 是否改为可拭
- 完成标准: v0.88 改为"有条件关闭"，或列出遗留项

### PM-08 · 旧内容目录：归档还是删除
- status: todo
- 来源: v0.88 T5 报告 §5（v0.3–v0.6 的 cards / enemies / encounters / balance 等只有旧测试引用）
- 完成标准: 给出裁决；如果归档，沿用 `archive/pre-v0.87-assets` 的标签方式


> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### PM-06 · v0.88 关版后开 v0.89（X1）
- status: done
- 证据/说明: v0.89 已由架构师按用户授权开版（docs/versions/v0.89.0.md）
- 阻塞: v0.88 自动化全绿，H-01…03 真窗口通过（本轮不做）

### PM-01 · v0.87 关版裁决
- status: blocked
- 来源: docs/versions/v0.87.0.md
- 改哪些: CURRENT_VERSION / VERSION_* / 版本文档状态；必要时 ADR
- 完成标准: 两项行为确认有结论；真窗抽查通过或显式结转；版本关闭或明确「仍验证中」
- 怎么验: 指针与报告一致
- 阻塞: 用户真窗抽查（焦点「合上」、挑战页无正文）
- 备注: 2026-11-24 **结转到 v0.88 保留项**——不假装关 v0.87；关版手续并入 v0.88 真窗包或后续 PM 关版条

### PM-04 · G-03 / 内容解冻是否开版
- status: todo
- 来源: ACTIVE_PLAN G-03、D-*
- 改哪些: 新 versions 或明确继续冻结
- 完成标准: 自动=否条目有明确「开/不开」
- 怎么验: 版本文档或 ACTIVE_PLAN 一句裁决
- 阻塞: 可在 v0.88 关后做（本轮不做）

## 已完成（近期）

### PM-05 · 确认 ADR-0032 的三项体验决定
- status: done
- 证据/说明: 用户 2026-11-24 的反馈修订了交互模型（控件绑定文字），见 ADR-0034；其余三项决定沿用
- 证据: ACTIVE_PLAN §0 · EXP；`docs/reports/v0.88.0/product_manager.md`；ADR-0032 已采纳前提下记为已确认采纳；改须新 ADR

### PM-DW-drawer · 冻结抽屉进战路径
- status: done
- 证据: ACTIVE_PLAN §0 · DW；`DESK_WORLD_STATIONS.md` §3.7；采纳 T1→DESK→T3

### PM-02 · ACTIVE_PLAN 与 CURRENT 指针对齐
- status: done
- 证据: ACTIVE_PLAN 抬头/§0 → v0.88/R2+热修+EXPERIENCE；R0/R1 表下移归档备注，⬜ 结转 v0.88 保留项

### PM-03 · 整治期/书桌世界下美术可做 vs 须开版
- status: done
- 证据: ACTIVE_PLAN §0 · ART 表；product_manager 报告裁决摘要

### PM-done-v084-v085 · 有条件关版
- status: done
- 证据: ACTIVE_PLAN §0；余项转 R0-11（现已并入 v0.88 保留项叙述）
