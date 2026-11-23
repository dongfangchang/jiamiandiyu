# 活跃迭代计划（可勾销 · 细粒度）

> **条目格式（强制）**  
> 每条必须写清：`ID` / `负责` / `改哪些文件` / `怎么做` / `完成标准` / `怎么验`。  
> **做完就删该条**（可搬到文末「已勾销归档」一行备注，不要留空壳大方向）。  
> 自动轮询只做标了 `自动=是` 的条；`自动=否` 须用户/产品经理口头或开版授权。  
> 冻结：禁新卡 / 第二途径 / 路线树 / 主路径原生 OptionButton；仪式软失败；推送须用户要求。  
> 指针：`docs/CURRENT_VERSION.md`。本文件不是 `docs/versions/` 版本文档。  
> 新人/换会话先读：`docs/ORIENTATION.md`（上下文与现状），再回到本文件干活。

更新日期：2026-11-23  
当前版本：`v0.85.0`（执行中）。`v0.84.0` 验收事项继续保留。

---

## 0. 状态总览

| 块 | 状态 | 说明 |
|---|---|---|
| A v0.84 关版手续 | 待验 | 真窗口目视 OK 后再关闭 v0.84 |
| F v0.85 日记美术 | 执行中 | 按正式美术规格分批交付 |
| G 卡面/蜡封全量 | 收口 | G-01 蜡封 24 齐；G-02 四十卡齐；G-03 UI 待开版 |
| B 日记桌 P1/P2 | 已勾销 | 见归档 |
| C 沉浸壳 | 已勾销 | 纸纹与桌面纹理纳入 F-01 |
| D 玩法内容 | **冻结** | 须新 `docs/versions/v0.xx.0.md` |
| E 工程门 | 已勾销 | 回归命令保留在 §E 参考 |
| K 候选池 | 排队 | 不阻塞关版 |
| 文档减负 | 已做一刀 | `VERSION_INDEX` 精简 + `VERSION_LOG` 流水账 |

---

## A. 收口 `v0.84.0`（须用户确认）

### A-01 真窗口目视验收（关版前门禁）

- **自动**：否（须人眼）
- **负责**：用户 / 产品经理
- **改哪些文件**：无（只验收）
- **怎么做**：用 Godot 编辑器或导出包打开，进入廷根日记章，对照下表逐项打勾。
- **完成标准**（全部是）：

| # | 检查 | 期望 |
|---|---|---|
| 1 | 进日记首屏 | 可见桌面 + 烛 + 墨/羽；书是 3D 物件不是全屏书墙纸 |
| 2 | 书占比 | 约视口宽 55–65%；左右露桌面道具 |
| 3 | 横滑翻页 | 页绕书脊铰链掀起，不是 2D 闪切 |
| 4 | 点蜡封「启」 | 进入 `first_hunt`（或当前 AVAILABLE 节点）战斗/仪式流 |
| 5 | 右页信息密度 | 只有题名 + ≤60 字笔迹 + 蜡封；无大段攻略 HUD |
| 6 | 「合上」 | 回到 hub；点击不误触蜡封 |
| 7 | 锁定叶横滑过头 | 回弹 + 可选渗墨/状态句；不跳关 |
| 8 | 冻结 | 无新卡 ID、无第二途径、无路线树、无新原生 OptionButton |

- **怎么验**：对照截图 `.tools/ui-captures/v084_desk_idle.png` / `v084_desk_flip.png`；真窗口为准。
- **阻塞**：任一项否 → 开 `docs/bugs/BUG-xxxx.md`（S2 显示）或把缺陷写回本文件新条，**不关版**。

### A-02 有条件关闭文档手续（A-01 全通过后）

- **自动**：否（用户说「关版」后才执行）
- **负责**：产品经理（本角色可代改 docs）
- **改哪些文件**：
  1. `docs/versions/v0.84.0.md` → 状态改为「有条件关闭」；写关闭日期与验收摘要
  2. `docs/CURRENT_VERSION.md` → 更新前一版本的验收状态，保留本版指针
  3. `docs/VERSION_INDEX.md` → 记一笔 v0.84 关闭
  4. `docs/reports/v0.84.0/ui.md` → 状态改为有条件关闭
  5. 本文件：删除 A-01/A-02；若开下一版则写入新块
- **怎么做**：用户明确「关版」→ 按上列改 → 不 `git push` 除非另嘱。
- **完成标准**：上述文件记录的 v0.84 状态一致，运行时版本号随当前执行版本交付更新。
- **怎么验**：`rg -n '有条件关闭|验证中' docs/CURRENT_VERSION.md docs/versions/v0.84.0.md`

### A-03 关版前材料包（可自动准备，不代替 A-01）

- **自动**：是
- **负责**：UI
- **改哪些文件**：仅报告/截图，不改关版指针
- **怎么做**：
  1. 跑 V083（见 E-REF）
  2. GPU 跑 `tests/ui/v084_diary_desk_capture_runner.tscn` 刷新两张 PNG
  3. 在 `docs/reports/v0.84.0/ui.md` 写「材料包日期 + 探针数字」
- **完成标准**：截图 mtime 为最近一次 GPU 跑；报告含 V083=21
- **怎么验**：
  ```bash
  .tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot --headless --path . \
    res://tests/ui/v083_diary_desk_p0_runner.tscn
  # 期望：V083_DIARY_DESK_P0_OK checks=21
  ```

---

## F. 日记美术与字体

### F-01 正式资产与运行时验收

- **自动**：是
- **负责**：美术制作，UI 接入并真窗口审稿，主协调者迁入清单
- **改哪些文件**：`art/assets/raster/v0.85.0/**`、`assets/game/v0.85.0/diary/**`、`assets/ui/diary/**`、`assets/ui/fonts/**`、日记 UI 与本版报告
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
