# Journal · architect

> 追加写，旧条目不删。格式见 `.cursor/agents/_meta/SKILL_LOOP.md` §3。

## Log

- 2026-11-24 · AR-05：三渲染器真窗口对比（M4 · 2920×1753）→ ADR-0035 采纳桌面默认 Forward+。证据 `docs/decisions/ADR-0035-desk-world-renderer.md`、`docs/reports/v0.89.0/architect.md`、`docs/reports/v0.89.0/ar05_renderer/`。未改 `src/ui/**` / `project.godot`。

### Retro · 2026-11-24 · AR-05 渲染器评估
1. 目标是否达成？是。证据：ADR-0035 + 三法 baseline/fx 缩略图与 FPS 表；tasks AR-05 done。
2. 哪一步最耗时或最易错？3D 截图禁止 headless；Environment.ssao_enabled 在 Compatibility 上可写但不跑——必须以后端能力表 + 肉眼为准，不能信属性回读。
3. 可沉淀为 Skill 的步骤？渲染器对比清单：① CLI `--rendering-method` 不改 project ② 同镜头同分辨率 ③ baseline+FX 双拍 ④ 记 driver/FPS ⑤ 缩略图入库、全图可复跑 ⑥ 决策写迁移代价与谁落地配置。
4. 该进 Tool Registry 的命令？`tools/architecture/ar05_run_compare.sh`（评估复跑）。
5. 下次同一类任务第一条读？本 Retro + ADR-0035 + `tools/architecture/ar05_renderer_compare_runner.gd`。

- 2026-11-24 · AR-01/AR-02：R1 §4.1 遗留写入 ROADMAP 可勾选归口（含新 R2-13）；R2 边界+单一负责人+黄金回放约束写入 ROADMAP。证据 `docs/architecture/ROADMAP.md`、`docs/reports/v0.88.0/architect.md`。AR-03 仍 blocked（等 X1）。

### Retro · 2026-11-24 · AR-01/AR-02 文档债
1. 目标是否达成？是。证据：ROADMAP 遗留表 + R2 边界节 + architect.md §10；tasks AR-01/02 done；AR-03 未假做。
2. 哪一步最耗时或最易错？遗留「塞进既有条目」vs「新开 ID」——选 R2-13 显式立项，避免 route_ui_catalog 消失在口头债里。
3. 可沉淀为 Skill 的步骤？关版遗留归口清单：① 逐条对 ROADMAP 既有 ID ② 对不上则新开最小条目 ③ 不立项的写「—」并说明 ④ 边界评审 = 文件×负责人勾选表 + 黄金回放更新权属一句。
4. 该进 Tool Registry 的命令？无。
5. 下次同一类任务第一条读？本 journal Retro + ROADMAP「R1 → R2/R3 遗留归属」+「R2 边界」两节。

- 2026-11-24 · AR-04：UI-X0 **有条件通过**。证据 `docs/reports/v0.88.0/architect.md`。条件：新游戏 TITLE→DOSSIER 补表；羽笔避卡匣 AABB。烛台新坐标接受。UI-X1 可在其它阻塞清除后开工。

### Retro · 2026-11-24 · AR-04 UI-X0 评审
1. 目标是否达成？是。证据：architect.md 结论 + tasks AR-04 done。
2. 哪一步最耗时或最易错？用锚点×足迹做 AABB，比只读镜头表更容易发现碰撞。
3. 可沉淀为 Skill 的步骤？站位稿评审清单：① 六物件七站位齐全 ② 镜头相对 diary 基准 ③ 过渡表含继续+新游戏+T1–T4 ④ 俯视 AABB 无重叠 ⑤ 每屏能答「哪物件哪站位」⑥ X2/X3 占位不冒充精审。
4. 该进 Tool Registry 的命令？无。
5. 下次同一类任务第一条读？`docs/reports/v0.88.0/architect.md` + EXPERIENCE §2–§4。

- 2026-11-24 · boot：角色记忆目录初始化。
