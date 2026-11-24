# 架构报告 · v0.88.0

版本：v0.88.0  
角色：architect  
任务：AR-01 / AR-02 文档债；AR-04 UI-X0 评审（已完成）  
状态：AR-01/AR-02 完成；AR-03 仍 blocked（等 X1 合并）；AR-04 完成

未改生产玩法 / UI 业务代码。

---

## AR-01 · R1 遗留 → ROADMAP 归口（完成）

来源：`docs/versions/v0.87.0.md` §4.1。写入：`docs/architecture/ROADMAP.md`「R1 → R2/R3 遗留归属」+ 条目补注。

| 遗留 | 归口 | 负责 |
|---|---|---|
| `app_controller` route_screen 命名 | R3-06 | 数据层 |
| `route_ui_catalog` 死代码 | **R2-13**（新增） | UI |
| `diary_chapter_screen` 超 800 行 | R3-09 | UI |
| runner 直读 v0.3–v0.6 | R2-08（补注） | 数据层 |
| 采样 v0.2 生成物 | 不立项 | — |
| `assets/game/{scenes,v0.*}` 工具输出 | ART-archive-tools-out | 美术 |

---

## AR-02 · R2 边界 / 单一负责人 / 黄金回放（完成）

写入：`ROADMAP.md`「R2 边界与黄金回放约束」可勾选表（与 v0.88 §2 轨道一致）。摘要：

- **黄金回放不变约束**：轨道禁自行 `--update`；仅协调者合并后统一更新 + 版本文档登记语义 diff（数值/状态变化须为 0）。
- **跨层文件**：见 ROADMAP 勾选表；冲突 → coordinator；范围 → product-manager。
- **ADR-0032**：R2 不做 DeskWorld 外壳；热修不新增面板 / `add_background(`。

派工入口：直接勾 ROADMAP 该节 + `docs/versions/v0.88.0.md` §2。

---

## AR-04 评审范围（历史）

| 材料 | 路径 |
|---|---|
| 体验框架 | `docs/architecture/EXPERIENCE_ARCHITECTURE.md` §2–§5、§8 |
| ADR | `docs/decisions/ADR-0032-desk-world-experience.md` |
| 设计稿 | `docs/design/DESK_WORLD_STATIONS.md` |
| 线框 | `assets/ui/wireframes/desk_world/`（00–04） |
| UI 交付说明 | `docs/reports/v0.88.0/ui.md` |

---

## AR-04 条件确认：**通过**（2026-11-24 · 主会话代 architect 复核）

核对 UI-X0-fix：

1. `DESK_WORLD_STATIONS.md` §4 + `03_transitions.md` 已含新游戏 **TITLE → DOSSIER（T1 直达）→ CARDBOX → DIARY**，与「继续」DESK 0.4s 分流。  
2. 墨/羽锚点改为 **(0.52, 0.48) / (0.66, 0.55)**，明确废弃 (0.85, −0.08)；`00_topdown_layout.svg` 已标注；落在卡匣 AABB 外。

条件清零。UI-X1 余阻：v0.88 合并 + X1 道具经 UI 复审后迁入。

---

## 结论（初评）：**有条件通过**（条件已于上节确认清零）

六物件 + 七站位齐全；镜头以现网 diary 为基准且相对偏移合理；过渡仅 T1–T4；上一级皆为 DESK；继续流含 0.4 s DESK 停留；2D 贴合物件（纸条 / 档案页 / 题签），无平面面板 / OptionButton / `add_background` 设计；叙事字体指向 `font.ink`。对照 EXPERIENCE §2–§5 / §8 与 ADR-0032，**可作为 UI-X1 布局与位姿表的权威输入**。

以下两点必须在设计稿补齐后，才视为 X0 闭环；不构成退回重做。

### 必须改（ui-designer · 设计稿 / 线框，不改生产代码）

1. **新游戏路径写进过渡表**  
   EXPERIENCE §3：`TITLE ──新游戏──▶ DOSSIER → CARDBOX → DIARY`（不经「继续」那条 DESK 停留）。  
   当前 `DESK_WORLD_STATIONS.md` §4 与 `03_transitions.md` 只有 TITLE↔DESK / 继续流，§3.1 仅说第二签=新游戏。  
   **要求**：增一行 `TITLE → DOSSIER`（T1；建档流），并写明是否短暂经 DESK（框架默认**直达** DOSSIER）。同步改 `03_transitions.md` 状态机简图。

2. **墨水 + 羽笔锚点与卡匣足迹冲突**  
   稿 §1 建议迁到 `(0.85, −0.08)`，但合态卡匣 AABB（锚 `(0.96, 0.08)`、足迹 `0.55×0.42`）覆盖约 `x∈[0.685,1.235]`、`z∈[−0.13,0.29]`，该点落在匣内。  
   **要求**：改到日记右前、**卡匣与祈愿台足迹外**的坐标，并画进 `00_topdown_layout.svg`（现线框未标羽笔/墨水）。

### 已裁决（设计可保留）

| 项 | 裁决 |
|---|---|
| 烛台 `(−0.86,−0.14)` → `(−0.95,−0.38)` | **接受**。符合「左上主光」；desk fov48 总览更干净。X1 实现允许 ±5% 微调，勿挡 diary 55–65% 构图。 |
| 档案开态左缘略出台面 (~0.13) | **可接受**（开夹朝镜头的透视余量）；若真机穿帮再收足迹，不阻塞过稿。 |
| 卡匣 / 祈愿 / 抽屉 2D 仅占位 | **符合** ROADMAP X2/X3；X0 不审其精版式。 |
| 抽屉选挑战后进战默认 DESK→T3 | **已由 product-manager 冻结**（ACTIVE_PLAN §0 · DW；`product_manager.md`）。 |

### 非设计退回项（勿与 AR-04 混淆）

UI-07 对 DW-01 open / DW-06 轮廓的退回属 **art** 资产，不否定站位设计稿本身。

---

## UI-X1 开工条件

**有条件通过 → UI-X1 可在其它阻塞清除后开工**，建议门闩：

1. 上列 **必须改 ×2** 已写入设计稿与线框（小补丁即可）。  
2. v0.88 主会话轨道合并完成（产品 / 协调者确认）。  
3. X1 所需道具（DW-01…07）**已迁入** `assets/game/desk_world/`（CO-X1，2026-11-24）。  
4. AR-03 测试守卫仍 **blocked on X1 合并**（本评审不解除）。

ROADMAP X1 范围仍是 title / desk / dossier / diary 四站 + T1/T4 + `theme_tokens`；cardbox / altar / drawer 站位表可先入库，实现排 X2/X3。

---

## 给 ui-designer 的修改清单（最短）

- [ ] `DESK_WORLD_STATIONS.md` §4 + `03_transitions.md`：补 **新游戏 TITLE→DOSSIER（T1）** 及建档后续 CARDBOX→DIARY  
- [ ] §1：重定墨水/羽笔 `(x,z)`，避开卡匣/祈愿台；`00_topdown_layout.svg` 标注  
- [ ] 改完后在 `docs/reports/v0.88.0/ui.md` 回注「AR-04 条件已清」一行

---

## §10 汇报 · AR-01 / AR-02

```text
版本：v0.88.0
角色：architect
任务：AR-01 R1 遗留归口；AR-02 R2 边界评审清单
状态：完成（AR-03 仍 blocked）
修改文件：docs/architecture/ROADMAP.md；docs/reports/v0.88.0/architect.md；.cursor/agents/architect/tasks.md；.cursor/agent-memory/architect/journal.md
依赖：v0.87 §4.1；ADR-0031/0032；CURRENT v0.88；v0.88 版本文档 §2–§3
验证：ROADMAP 可勾选表与 R2-13/R2-08/R3-06/R3-09 交叉引用可读；无生产代码改动
困难与候选方案：遗留塞进既有 R2 vs 新开 R2-13 → 选新增 R2-13 + 既有条目补注，避免幽灵债
最终解决：归属表 + 边界/单一负责人/黄金回放约束写入 ROADMAP；报告摘要本文件
风险：R2-13 若与主会话 T4 并行改 route_ui_catalog 可能撞车 → UI 开工前与协调者对齐
跨角色请求：UI 认领 R2-13；数据层 R2-08 含旧 runner；美术认领 ART-archive-tools-out；R3-06/09 延期到结构拆分
下一步入口：主会话继续 R2 第二波；AR-03 等 X1 合并
```

## §10 汇报 · AR-04（历史）

```text
版本：v0.88.0
角色：architect
任务：AR-04 评审 UI-X0 站位设计稿
状态：完成
修改文件：docs/reports/v0.88.0/architect.md；.cursor/agents/architect/tasks.md；.cursor/agent-memory/architect/journal.md
依赖：UI-X0 交付（DESK_WORLD_STATIONS + wireframes + ui.md）；EXPERIENCE / ADR-0032
验证：人工对照 EXPERIENCE §2–§5/§8、镜头表与俯视 AABB、过渡表完备性；未跑 Godot（无生产改动）
困难与候选方案：新游戏路径漏表 vs 退回整稿 → 选有条件通过 + 清单；羽笔碰撞算 AABB 确认
最终解决：有条件通过；烛台坐标接受；两处必须改交 ui-designer
风险：条件未补就开 X1 会导致 travel() 状态机与布局二次返工
跨角色请求：ui-designer 清条件；product-manager 冻结抽屉进战；art 继续 ART-DW-X1-fix（独立于本评审）
下一步入口：条件清零后协调者可解 UI-X1 设计阻塞；AR-03 仍等 X1 合并
```

### Retro · 2026-11-24 · AR-04 UI-X0 评审

1. 目标是否达成？是。证据：本报告结论「有条件通过」+ tasks AR-04 done。  
2. 哪一步最易错？俯视锚点×足迹的 AABB 重叠（羽笔）比读镜头表更隐蔽。  
3. 可沉淀？「站位稿评审清单：物件表 / 镜头表 / 过渡完备（含新游戏）/ AABB 不重叠 / §8 站位归属」。见 journal。  
4. Tool Registry？无新命令。  
5. 下次第一条读？本报告 + EXPERIENCE §2–§4 + 设计稿 §1/§4。
