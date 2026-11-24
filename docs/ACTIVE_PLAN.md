# 活跃迭代计划（可勾销 · 细粒度）

> **条目格式（强制）**  
> 每条必须写清：`ID` / `负责` / `改哪些文件` / `怎么做` / `完成标准` / `怎么验`。  
> **做完就删该条**（可搬到文末「已勾销归档」一行备注，不要留空壳大方向）。  
> 自动轮询只做标了 `自动=是` 的条；`自动=否` 须用户/产品经理口头或开版授权。  
> 冻结：禁新卡 / 第二途径 / 路线树 / 主路径原生 OptionButton；仪式软失败；提交与推送按章程 §9（完成即提交推送）。  
> 指针：`docs/CURRENT_VERSION.md`。本文件不是 `docs/versions/` 版本文档。  
> 新人/换会话先读：`docs/ORIENTATION.md`（上下文与现状），再回到本文件干活。

更新日期：2026-11-24  
当前版本：`v0.88.0`（执行中 · ROADMAP **R2** + 体验热修 H-01…03 + 体验框架 ADR-0032 / `EXPERIENCE_ARCHITECTURE.md`）。  
指针对齐：`docs/CURRENT_VERSION.md`（前一版 `v0.87.0` 自动化完成；真窗口抽查为 **v0.88 保留项**，不假装已关 v0.87）。  
v0.84 / v0.85 已有条件关闭（2026-11-24）。R0/R1 历史勾选见文末「已勾销归档 · R0/R1」。

---

## 0. 状态总览

| 块 | 状态 | 说明 |
|---|---|---|
| 当前执行 | **v0.88 / R2** | 单一事实源 + H-01…03；第二波 T4/T5；详见 `docs/versions/v0.88.0.md` |
| 体验框架 | **已冻结** | ADR-0032 已采纳；三项体验决定 **已确认采纳**（见 §EXP / `docs/reports/v0.88.0/product_manager.md`） |
| X1–X3 书桌世界 | 排队 | X1=v0.89；X2=v0.90；X3=v0.91（ROADMAP）；**等 v0.88 关版** 后开 X1（PM-06） |
| A v0.84 关版手续 | 已关 | 2026-11-24 用户授权有条件关闭 |
| F v0.85 日记美术 | 已关 | 余项真窗口审稿曾转 R0-11；现并入 v0.88 真窗保留包 |
| G 卡面/蜡封全量 | 收口 | G-01 蜡封 24 齐；G-02 四十卡齐；G-03 UI **须开版**（见 §ART） |
| B 日记桌 P1/P2 | 已勾销 | 见归档 |
| C 沉浸壳 | 已勾销 | 纸纹与桌面纹理纳入 F-01 |
| D 玩法内容 | **冻结** | 须新 `docs/versions/v0.xx.0.md`；整治期/书桌壳阶段不解冻 |
| E 工程门 | 已勾销 | 回归命令保留在 §E 参考 |
| K 候选池 | 排队 | 不阻塞关版 |
| 文档减负 | 已做一刀 | `VERSION_INDEX` 精简 + `VERSION_LOG` 流水账 |
| R0 / R1 | **历史完成（自动化）** | 勾选表已归档；真窗残留 → v0.88 保留项（勿静默改历史结论） |

### EXP · ADR-0032 三项体验决定（产品确认 · 2026-11-24）

ADR 状态「已采纳（用户授权架构师订框架）」下，以下三项记为 **已确认采纳**；日后若改须 **新 ADR**，不得口头覆盖：

1. **继续**先到桌面总览（DESK ~0.4 s）再推近推荐站。  
2. **奖励 / 休息 / 结算**并入日记页（非独立平面屏）。  
3. **牌组 + 升级**合并为 **卡匣**站。

### DW · 抽屉进战路径（产品冻结默认 · 2026-11-24）

采纳 UI 设计默认（`DESK_WORLD_STATIONS.md` §3.7）：选挑战确认后 **T1→DESK→T3** 进战斗（避免抽屉内直接墨迹）。**已冻结**，供 X3 实现；不再标「仍开放」。

### ART · 整治期 / 书桌世界下可做 vs 须开版（PM-03 · 2026-11-24）

| 类别 | 裁决 | 说明 |
|---|---|---|
| **X1 道具（DW-01…07）已 UI 审过** | **可做：迁入** | coordinator 迁 `assets/game/desk_world/**` 并登记 registry（CO-X1）；美术不自迁 |
| **X2 候选预产（DW-11…18）** | **可做：只产候选** | 可在 `art/**` 按 BRIEF 预画；**不**当正式运行时、不改 `src/**`、不宣布验收通过 |
| **X3 抽屉批（DW-21…23）** | **可预产候选** | 同上；进战路径已冻结为 T1→DESK→T3 |
| **身份 / 敌人换皮** | **可做** | 同 ID 换图、保持尺寸与 BRIEF；**禁止**新 ID / 改规则文案 / 改 `data/cards|enemies` 结构 |
| **G-01/G-02 迁入与真窗抽样** | **可做（协调/UI）** | 不新增卡；迁入与审稿跟现网资产 |
| **UI-X1 生产实现**（DeskWorld / travel / 四站） | **须开版** | = v0.89（X1）；阻塞于 v0.88 关版 + 资产迁入 |
| **UI-X2/X3 站位实现**、退役旧屏 | **须开版** | v0.90 / v0.91 |
| **G-03 检视弹层** | **须开版** | 挂独立 UI 切片或后续版本 |
| **新卡 / D 区解冻 / node_id / 公式** | **须开版** | 见 §D；PM-04 仍待裁决「开/不开」具体主题 |
| **K-02 旁支内容** 等玩法 JSON 扩写 | **须开版** | UI 路径已通也不算授权改日记内容 |

---

## F. 日记美术与字体

### F-01 正式资产与运行时验收

- **自动**：是
- **负责**：美术制作，UI 接入并真窗口审稿，主协调者迁入清单
- **改哪些文件**：`art/assets/raster/v0.85.0/**`、`assets/game/v0.85.0/diary/**`、`assets/ui/diary/**`、`assets/ui/fonts/**`、日记 UI 与本版报告
- **美术进度（2026-11-24）**：**八开竖图 8/8 已交**（`art/.../scenes/` + `assets/game/v0.85.0/diary/`）。仍待真窗口审稿与校色。
- **怎么做**：按 [正式美术规格](design/ART_BRIEF_V085.md) 分批接入并记录来源。
- **完成标准**：八开均加载竖图，纸、木、蜡封、字体和操作检查通过。
- **怎么验**：V083、V055、`has_diary_art()` 八页逐张核对、带显示截图及 UI 审稿。

---

## G. 卡面体系全量（后续执行 · 责任人 **art**）

> 规范：`art/README.md` §0。执行者：本仓库 art 角色（会话内由当前代理按批绘制）。  
> **不**问「优先哪几格」——矩阵与卡表 **全量** 列入，分批做完即删条。

### G-01 蜡封矩阵全量（4×6 = 24）— **已交付**

- **状态**：2026-11-23 art 齐：`art/assets/raster/v0.85.0/seals/`
- **交付**：24×母版 PNG + 24×`*-128.png` 透明叠层 + 更新 `seal-matrix-sheet.png`
- **清单**：`seals/README.md`
- **仍待**：主协调者迁 `assets/game`（若运行时改路径）；UI 手牌锚点抽查；旧四枚带英文母版可择期无字重刻
- **已勾销归档**：矩阵绘制完成。

### G-02 全卡插画重绘（40 张 · 五批×8）— **已交付候选**

- **状态**：2026-11-23 art 候选齐（`art/assets/raster/v0.85.0/cards/**/art.png`）
- **清单**：`art/assets/raster/v0.85.0/cards/README.md`；总览 `card-framework/cards-art-contact-sheet.png`
- **批次**：①仪式核心 ②射击/训练 ③占卜/情报 ④小丑+盟友 ⑤封印物
- **仍待**：主协调者迁 `assets/game/`；UI 真窗口抽样 ≥4；不满意单卡重画不阻塞整批
- **已勾销归档**：候选绘制本身完成；迁入与审稿另跟。

### G-03 检视弹层（UI · 配合卡面短句）

- **自动**：否（须开版或挂在 v0.85/后续 UI 切片）
- **负责**：UI
- **怎么做**：按 `art/README.md` §0.4 居中弹层；检视**无蜡封**；数据读 `rules_text_zh` 等。
- **完成标准**：手牌短句 + 弹层全文；不砍插画窗。
- **怎么验**：战斗内点银质匕首 → 见完整规则与风味。

---

## R. 架构整治进度（指针）

- **当前**：R2（v0.88）— 见 `docs/versions/v0.88.0.md`；体验框架已冻结，实现排 X1+。  
- **R0/R1 勾选表**：已移入文末「已勾销归档 · R0/R1」——**保留原结论与 ⬜ 真窗项**，不在此重写历史；真窗残留统一记为 **v0.88 保留项**（产品经理关版时一并核）。

---

## D. 玩法与内容（冻结 · 开版前拆成可执行故事）

> 未写入 `docs/versions/v0.xx.0.md` 前 **禁止改** `data/cards|enemies|encounters`、战斗公式、`node_id`。

### D-01 新卡全链路门禁（模板故事，开版后复制改 ID）

- **自动**：否
- **负责**：玩法 + 数值审核金额 + 美术卡图 + 主协调者迁 PNG + UI 只读映射
- **改哪些文件（一次卡一张清单）**：
  - `data/cards/v0.7.0/*.json`（定义）
  - 抽卡池 / 牌组目录 / 升级定义（现网对应 json）
  - `assets/game/<ver>/cards/<card_id>.png`（经主协调者迁移）
  - 禁止只加显示名不加稳定 `card.*` ID
- **完成标准**：定义+池+牌组+升级+正式卡图五件套齐；可加载；有自动化或可重复验证
- **怎么验**：内容加载测试 + 局内抽到/编入牌组各一次

### D-02 小丑相关解冻

- **自动**：否
- **前置**：版本文档写明「解冻范围」（序列几、哪 8 张、是否改发放）
- **负责**：玩法（`data/decks` / progression grant）+ 应用层 owned 同步（若版本授权）
- **完成标准**：只动授权字段；不顺手扩第二途径
- **怎么验**：晋升结算文案与 owned 预设与版本说明一致

### D-03 数值 / schema / node_id 变更

- **自动**：否
- **前置**：`docs/decisions/ADR-xxxx.md` + 新版本号
- **负责**：数值或数据层（按字段所有权）
- **完成标准**：ADR 有迁移/回滚说明；存档 `save_version` 策略明确
- **怎么验**：旧档加载或明确报错，不静默坏档

---

## K. 候选池（详细 backlog · 不阻塞 A 清空）

### K-02 旁支 `kind!=main` 内容 + 贴条可见

- **自动**：否（内容属玩法/叙事开版；UI 路径已通）
- **现状**：`diary_ui_catalog.gd` 已收集 `side_notes`；`SideBranchSticker` 有 notes 才显示；现网 `data/diaries/v0.55.0/tingen_volume_1.json` **全是 main**
- **负责**：玩法/叙事在日记 JSON 增加 `kind!=main` 线索 → UI 免改或只调文案
- **改哪些文件**：
  - `data/diaries/v0.55.0/tingen_volume_1.json`（或新 diary 版本路径）
  - 必要时 `tests/ui/*` 加一条「有 side_notes 时贴纸可见」
- **完成标准**：至少 1 条旁支在某一 main 开上显示「旁」贴条；点击出非 Dialog 薄层
- **怎么验**：构造含 side 的 fixture 快照 → 找 `SideBranchSticker.visible==true`

### K-03 页真弯曲网格（可读、不黑页）

- **自动**：否（曾用 ArrayMesh 导致 capture 黑页，已回退 Quad 微翘）
- **负责**：UI
- **改哪些文件**：`src/ui/diary_desk_stage.gd` `_make_page_mesh`
- **怎么做**：SurfaceTool 生成弯页 + 正确法线/绕序；先单页试点再双页；GPU capture 必过
- **完成标准**：idle 左页插图+金框仍清晰；flip 仍见铰链；V083=21
- **怎么验**：GPU `v084_desk_idle.png` 目视非黑页

### K-04 符文详情文案数据化

- **自动**：否
- **现状**：`_rune_hint` 写死「本叶/启印/阅印/封印」
- **负责**：UI（读快照字段）或玩法提供只读文案字段
- **完成标准**：文案来自 spread/clue 字段或 catalog，不散落魔法字符串过多；仍非系统 Dialog
- **怎么验**：改 fixture 文案 → 薄层同步

### K-05 结算墨渍分胜/败/墨渍三态目视差

- **自动**：否
- **现状**：`play_settlement_fx(kind)` 已有 pen/wipe/win/defeat 染色；调用点主要 pen/wipe
- **负责**：UI（`diary_chapter_screen.gd` 在 `present_post_encounter` 路径传对 kind）
- **完成标准**：胜→暖金 bloom；败/墨渍→深褐；拭→冷蓝；不改 `route_engine` 触发公式
- **怎么验**：三种结算各截一帧或探针断言 modulate/color

### K-06 烛/墨/羽点击反馈（可选）

- **自动**：否
- **负责**：UI
- **怎么做**：屏上热区或 3D pick → 只播 `TableSfx` / 短状态句，**不进关**
- **完成标准**：不与蜡封/翻页抢手势；无规则副作用
- **怎么验**：点击烛 → call_log 含对应 kind；无 `RouteCommand`

### K-07 下一产品切片（开版候选，择一）

写新版前必须单独立 `docs/versions/v0.xx.0.md`，下面只是候选主题：

| 候选主题 | 一句话范围 | 明确不做 |
|---|---|---|
| 日记旁支内容包 | K-02 + 2～3 条旁支文案 | 不新卡 |
| 真弯页 | K-03 | 不上整游戏 3D |
| 玩法 D-0x | 新卡或小丑授权 | 无授权不动 |

---

## E. 工程参考（已勾销项的保留命令 · 勿当待办空壳）

改 UI 后最小集：

```bash
GODOT=".tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot"
"$GODOT" --headless --path . res://tests/ui/v083_diary_desk_p0_runner.tscn
# 必要时：
"$GODOT" --headless --path . res://tests/ui/v055_diary_chapter_runner.tscn
# 截图须 GPU（不要 --headless）：
"$GODOT" --path . res://tests/ui/v084_diary_desk_capture_runner.tscn
# OptionButton 抽查：
rg -n 'OptionButton\.new|type="OptionButton"' src/ui scenes/ui
```

关键路径速查：

| 用途 | 路径 |
|---|---|
| 桌面 3D 舞台 | `src/ui/diary_desk_stage.gd` |
| 日记屏/Chrome/结算 | `src/ui/diary_chapter_screen.gd` |
| 开页 catalog | `src/ui/diary_ui_catalog.gd` |
| 日记内容 | `data/diaries/v0.55.0/tingen_volume_1.json` |
| P0 探针 | `tests/ui/v083_diary_desk_p0_runner.tscn` |
| 截图 runner | `tests/ui/v084_diary_desk_capture_runner.tscn` |
| 设计契约 | `docs/design/DIARY_DESK_3D_BRIEF.md` |
| 版本身份 | `docs/versions/v0.85.0.md` |

---

## 已勾销归档（勿再执行 · 供审计）

- B：符文亮灭、RuneDetailLayer、settlement bloom、side_notes 路径、页微翘、FLIP/SEAL SFX
- C：Chrome 降透明度、合上书签远离 WaxSealHit(0.54–0.76)、纸纹无 BRIEF→K-01
- K-01：正式纸纹与桌面纹理已纳入 v0.85 F-01
- E：V083=21、无新增 OptionButton、capture runner 可复跑
- A 视觉：idle/flip 截图曾复核（关版仍以 A-01 真窗口为准）

### 已勾销归档 · R0/R1（历史表 · 2026-11-24 自 §R 下移，结论不改写）

> 归档备注：ACTIVE_PLAN 指针已对齐 CURRENT=`v0.88.0`/R2。下表为 R0（v0.86）与 R1（v0.87）当时勾选快照；⬜ 真窗项 **结转 v0.88 保留项**，不因此表下移而视为已验收。

| 条目 | 负责 | 状态（归档快照） |
|---|---|---|
| R0-01 统一测试入口 `tools/run_tests.sh` / `.ps1` | 主协调者 | ✅（.ps1 待 Windows 实测） |
| R0-02 基线失败清单 | 主协调者 | ✅ |
| R0-03 删除钉版本号的测试断言 | 主协调者 | ✅ |
| R0-04 黄金回放 | 玩法 + 主协调者 | ✅ `tests/golden/` |
| R0-05 战斗卡图（AR-01） | UI | ✅ 2026-11-24 |
| R0-08 `art/.gdignore`，取消跟踪 simulation/out | 主协调者 | ✅ |
| R0-09 守卫 | 主协调者 | ✅ 已在 run_tests 中 |
| R0-11 日记八开真窗口审稿 | UI | ⬜ → **v0.88 保留项** |
| NAV-01…09 界面切换整治 | UI | ✅ 自动化；⬜ 用户真窗 → **v0.88 保留项**（清单 `docs/reports/v0.86.0/ui.md`） |
| BUG-0038 挑战路线无日记线索 | UI | ✅ v0.87 回退开页 |
| v0.87 R1 删除死代码 | 全员 | ✅ 自动化；⬜ 用户抽查 → **v0.88 保留项**（新游戏→日记→战斗→hub；挑战→蜡封→战斗） |
