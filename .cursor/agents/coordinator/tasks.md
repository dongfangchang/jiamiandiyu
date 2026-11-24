# Tasks · coordinator

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

> **2026-11-24 第二次下发（用户反馈 → ADR-0034）**：①控件绑定文字，物件只是画面；②替换即删除，禁止遮挡或隐藏旧界面；③日记可读性底线和画面升级。当前版本 **v0.89.0**（`docs/versions/v0.89.0.md`），P0 条目优先于其他所有条目。主会话会定时轮询本文件：done 条目必须写证据（提交 SHA、截图路径、测试输出），主会话据此合并、推送并下发后续任务。

### CO-DQ · 迁入日记画面升级资产，并更新资源注册表
- status: blocked
- 改哪些: `assets/game/desk_world/diary_quality/**`、`data/registry/assets.json`、`art/ASSET_MANIFEST.md`
- 完成标准: 经 UI 审稿通过后迁入；注册表登记 ID；守卫不报错
- 阻塞: ART-DQ 交付并审稿通过

### CO-05 · 资源注册表负责人（v0.88 起）
- status: doing
- 说明: 每次迁入资源都同步更新 `data/registry/assets.json`；`src/ui` 中不得出现资源路径字面量（守卫阻断）


> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### CO-R2 · v0.88 R2 各轨道合并与黄金回放统一更新
- status: done
- 证据/说明: v0.88 两波已合并，黄金回放更新两次（72f181a、f594848）
- owner: 主会话——**勿重复**

### CO-01 · 卡面/蜡封正式迁入抽查
- status: todo
- 来源: ACTIVE_PLAN G-01/G-02 仍待
- 改哪些: 若运行时路径需统一则迁 `assets/game/**`；更新清单
- 完成标准: 游戏加载路径与 art 交付一致；无重复幽灵副本
- 怎么验: 启动战斗见新 art；`run_tests` 相关绿
- 阻塞: 可与 UI 抽查并行

### CO-02 · 日记/桌面新候选迁入门（等 art 交）
- status: blocked
- 来源: ART-01
- 改哪些: `assets/ui/diary/**` 或 `assets/game/**` 按既有惯例
- 完成标准: 正式路径可加载；art 候选归档说明写清
- 怎么验: 日记桌真窗 + 探针
- 阻塞: art ART-01 交付候选

### CO-03 · v0.87 用户抽查协调与关版材料
- status: todo
- 来源: v0.87.0 验证中
- 改哪些: 协调报告；必要时补集成证据
- 完成标准: 抽查结论可交给产品经理关版
- 怎么验: 对照版本 §4
- 阻塞: UI/用户真窗

### CO-04 · 推送前检查 .cursor 学习内容
- status: todo
- 来源: 用户要求；SKILL_LOOP §7
- 改哪些: 每次集成推送时 `git add` agents/skills/memory/rules/tasks
- 完成标准: 远端含最新 tasks/journal/skills
- 怎么验: `git status` 无遗漏 .cursor
- 阻塞: 无（持续纪律）

## 已完成（近期）

### CO-X2 · 迁入书桌世界 X2 批资产（DW-11…18）
- status: done
- 来源: UI-07-X2 全过；ART-DW-X2
- 证据: `assets/game/desk_world/{cardbox,pouch,altar,circle_glow,ink_mask,envelope,battle_cloth,page_frames}/**` 26 PNG；`art/ASSET_MANIFEST.md` X2 段；`docs/reports/v0.88.0/coordinator.md` §B
- 验证: Godot import 26/26 DONE；`run_tests: pass=90 fail=0 skipped=10 guard_block=0`
- 备注: 未删 art；未开 X3；未碰 R2/UI-H；注册表仍待 R2-10

### CO-X1 · 迁入书桌世界 X1 批资产
- status: done
- 来源: ART_BRIEF_DESK_WORLD
- 证据: `assets/game/desk_world/**` 20 PNG；`art/ASSET_MANIFEST.md` v0.88 desk_world 段；`docs/reports/v0.88.0/coordinator.md`
- 验证: Godot import 20/20 DONE；`run_tests: pass=90 fail=0 skipped=10 guard_block=0`
- 备注: 未建 `data/registry/assets.json`（R2-10 未落地）；未删 art 候选；未碰主会话 CO-R2/UI-H

### CO-done-R0-01…09 · R0 测门与守卫
- status: done
- 证据: ACTIVE_PLAN §R 勾选

### CO-done-R1-D · 资源归档轨道
- status: done
- 证据: v0.87 §4.1；标签 `archive/pre-v0.87-assets`
