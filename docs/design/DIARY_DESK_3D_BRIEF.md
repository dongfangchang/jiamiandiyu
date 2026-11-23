# 日记桌 3D 书契约（P0）

> 状态：**已冻结**（v0.83.0 设计关闭 · 2026-11-22）  
> 取代方向：`DIARY_IMMERSION_BRIEF` 中「书图当全屏底 / 2D 叠字当正文载体」的实现路径。  
> 世界观墨迹语义（褐墨 / 金覆写 / 侵蚀）仍继承；载体与交互重定。  
> 参考构图：桌上立体书 + 烛台桌面背景（跨页一关）。  
> 实现须另开执行版或将 v0.83 转入执行；**本文件冻结后改交互/版式须新产品裁决。**

## 1. 一句话

玩家坐在桌前面对一本**可交互的立体日记**；桌面与烛台是场景背景，书是 3D 物件。  
**一整开（左右页）= 一个关卡节点**；横滑翻页，点蜡封进关。

## 2. 场景构成

| 层 | 是什么 | 不是什么 |
|---|---|---|
| 背景 | 桌面、烛台、暗室占位 | 全屏书图墙纸 |
| 主体 | 程序网格立体书（书脊 + 左右页 + 厚度） | 仅翻页时闪现的 Viewport |
| 页内容 | 贴在页 Mesh 上的 SubViewport 纹理 | 漂在全屏 Control 上的大段说明 |
| HUD | 桌沿书签级（返回等） | 盖住书页的常驻说明书 |

P0 资产：Godot 程序网格 + 现有纸纹/简单材质；**不依赖 Blender**。

## 3. 跨页一关（版式）

### 3.1 绑定

- 一开 ↔ 一个可调查 `node_id`（优先 `kind=main`；旁支另议，P0 可先只铺 main）。
- 翻一次 = 换下一关整开，左右一起换。
- 与现网 `spread_list` 差异：现网一 spread 可含多 clue 左右分栏；P0 **改为 1 spread = 1 node**（catalog 重组或适配层，规则 ID 不变）。

### 3.2 左页 — 场面

- 满页插图（场景 / 遭遇 catalog；无则程序占位图）。
- 可有污渍、边注痕迹；**不是系统面板**。
- 默认点插图**不**进关（防误触）；可选：画中唯一高亮物件可点（P0 可不做，进关只走蜡封）。

### 3.3 右页 — 笔迹与封印

- 短题名（≤10 字量级）
- 日记体短笔迹 **≤60 字**（氛围一眼，非攻略）
- **蜡封 / 关印**：本开唯一「进入」控件
- 页边符文位：P0 可先留空位或静态占位；亮灭语义属 P1

### 3.4 空白焦虑

页靠「左满图 + 右笔迹与蜡封」填满，**不加**长说明、按钮栏、进度条。  
空 = 没画满，不是少 UI。

## 4. 交互（P0）

| 意图 | 手势 | 备注 |
|---|---|---|
| 翻页 | 书页区域 **横滑 / 拖**，跟手掀页；过半翻页，否则回弹 | 不是唯页角热区 |
| 进关 | **单击**蜡封（位移小于点击阈值） | 走现有 `request_node` / app 命令 |
| 返回 | 桌沿书签 / 既有退出 | 不挡书心 |

**禁止**：页角作为唯一翻页入口；进关与翻页争同一点击热区而不做手势分层。

锁定页（未解锁 / 墨封）：强拖回弹 + 可渗墨反馈（可沿用现语义；P0 至少回弹）。

## 5. 技术骨架（设计约束，本 loop 不写代码）

### 5.1 场景树（探针可按名查找）

```text
DiaryChapterScreen (Control 壳)                    # 保留现有对外 API：apply_snapshot / request_node / …
  ├ DeskStage (SubViewportContainer)               # 主舞台；书约占视口 55–65% 宽
  │    └ DeskWorldViewport (SubViewport)
  │         └ DeskWorld (Node3D)
  │              ├ DeskMesh (MeshInstance3D)
  │              ├ CandleMesh (MeshInstance3D)
  │              ├ BookRoot (Node3D)
  │              │    ├ SpineMesh
  │              │    ├ LeftPageMesh                 # albedo ← LeftPageViewport
  │              │    └ RightPageMesh                # 翻页时绕局部 Y（书脊）旋转
  │              ├ DeskCamera (Camera3D)             # 略俯视桌面，书不铺满
  │              ├ KeyLight / FillLight
  │              ├ LeftPageViewport (SubViewport)    # 2D 画左页
  │              │    └ LeftPageRoot (Control)
  │              │         ├ SceneArt (TextureRect)
  │              │         └ (optional stains)
  │              └ RightPageViewport (SubViewport)
  │                   └ RightPageRoot (Control)
  │                        ├ TitleLabel
  │                        ├ InkLabel (≤60 字)
  │                        ├ WaxSealButton           # 唯一进关
  │                        └ RuneStrip (P0 可空占位)
  └ DeskChrome (Control)                             # 返回书签等；mouse 不挡书心
```

### 5.2 输入状态机（P0）

```text
IDLE
  press on book stage → ARM
ARM
  move > CLICK_SLOP_PX → FLIP_DRAG（跟手转 RightPage / 假页）
  release ≤ CLICK_SLOP 且命中 WaxSeal → SEAL_CLICK → emit 既有 route 命令
  release 其他 → IDLE
FLIP_DRAG
  release |progress| ≥ 0.5 → commit 换 spread_idx，播完回 IDLE
  release |progress| < 0.5 → 回弹 IDLE
  若目标 spread 锁定 → 强制回弹（P0 最低要求）
```

- `CLICK_SLOP_PX`：建议 8–12px（设计值，实现可调）。
- 蜡封：P0 用 `RightPageViewport` 内 `Button`/`TextureButton`；`gui_input` 与翻页手势互斥靠状态机，不靠页角热区。
- 对外命令**不变**：`RouteCommand.select_node` / `wipe_ink` / `begin_ascension`（逻辑抄现 `_on_clue_pressed`）。

### 5.3 退役

- `DiaryBookArt` 全屏底图：隐藏或删除主路径引用。
- 现 `DiaryFlip3D` 短暂闪现：禁止再当主翻页表现。
- 多 clue 段落列表 UI：被「一开一关」取代（数据仍来自同一 diary JSON）。

## 5A. 数据映射（现网 → P0）

### 5A.1 源

- 卷：`data/diaries/v0.55.0/tingen_volume_1.json`（不改 schema / 不改 `node_id`）。
- 现网：`diary_ui_catalog.build_view` 把每 JSON `pages[]` 内多 `clues` 合成 **一个** spread（左右分栏）。
- 现网样例：2 个 JSON page × 各 4 main clue → **2** spreads；P0 需要 **8** spreads。

### 5A.2 适配规则（UI catalog，不改玩法）

对每个 clue（P0 仅 `kind=main`）生成一条 spread：

| spread 字段 | 来源 |
|---|---|
| `spread_index` | 按卷内 main clue 顺序 0..N-1 |
| `node_id` / `clue_id` | clue 原字段 |
| `state` | 沿用 completed / unlocked 算法 |
| `title_zh` | **优先** route 节点 `display_name_zh`（已短）；过长则截 ≤10；再空才用 `margin_note_zh` 首句 |
| `ink_zh` | diary `text_zh`（有覆写则覆写优先，仍保留 `base_text_zh`）截断 ≤60 字 |
| `left_art_path` | route 节点 `scene_id` → `SceneCatalog.path_for`；无则占位图 |
| `node_type` | 现 `_node_type_map` |
| `annotation_zh` | 现 annotations |
| `is_locked` / `is_available` / `is_completed` | 由 state 派生 |

旁支 `kind!=main`：P0 **不生成开页**（记入候选：后页贴条 / 符文）。

### 5A.3 进关语义（保持）

| state | 点蜡封 |
|---|---|
| AVAILABLE | `select_node`；`ritual` → `begin_ascension` |
| LOCKED + 可擦 | `wipe_ink` |
| LOCKED 不可擦 | 拒绝 + 短状态（可桌沿一句，不弹系统 Dialog） |
| COMPLETED | 显示 annotation（P0 可用右页短暂浮墨；非模态系统窗优先） |

### 5A.4 章内数量与 scene 对照（廷根卷一）

按 main clue 顺序 = **8 开**（横滑 7 次可遍历，含锁定回弹）：

| # | node_id 后缀 | display_name_zh | scene_id | 蜡封命令 |
|---|---|---|---|---|
| 0 | `first_hunt` | 密修会的闯入者 | `scene.battle.moretti_home` | `select_node` |
| 1 | `tenant_trace` | 艾略特绑架案 | `scene.battle.elliot_ruin` | `select_node` |
| 2 | `mirror_pursuit` | 提利尔仓库 | `scene.battle.tyrell_warehouse` | `select_node` |
| 3 | `boundary` | 伍德家的恶灵 | `scene.battle.wood_house` | `select_node` |
| 4 | `rest` | 占卜俱乐部 | `scene.rest.divination_club` | `select_node` |
| 5 | `lamud` | 拉姆德小镇驱邪 | `scene.battle.lamud_chapel` | `select_node` |
| 6 | `baron` | 失控的老尼尔 | `scene.battle.blackthorn_neil` | `select_node` |
| 7 | `ascension` | 晋升：小丑 | `scene.ritual.clown_ascension` | `begin_ascension` |

完整 id 前缀：`route.v028.first_stage.node.`  
左页图：`SceneCatalog.path_for(scene_id, kind)`；缺资产用纸纹占位，不得留纯黑。

### 5A.5 填表示例（spread 0）

源：`clue.tingen.first_hunt` / `route.v028.first_stage.node.first_hunt`

| 页面元素 | P0 取值 |
|---|---|
| 左页图 | `scene.battle.moretti_home` |
| 右题名 | **「密修会的闯入者」**（`display_name_zh`，已 ≤10 字级；过长才截） |
| 右笔迹 | diary `text_zh` 截断 ≤60 |
| 蜡封 | AVAILABLE → `select_node(first_hunt)` |
| 符文条 | P0 灰印占位 |

### 5A.6 DeskChrome（P0）

- 仅：**合上/返回**书签（沿用现退出）、必要时一句桌沿状态（锁定拒绝等）。
- 禁止：常驻污染条、多按钮工具栏、盖住书心的 Panel。
- 旧 `V055` 等多 clue 探针：实现版改为 `V083_*` 或适配 1-node spread；不得为过旧探针保留多 clue 主 UI。

## 6. P0 验收

### 6.1 产品验收

1. 进日记：能看见**桌面背景**上的立体书（书宽约占视口 55–65%，四周露桌/烛）。
2. 横滑可翻到另一关开页；翻页时页是 3D 掀起，不是切 2D 图层闪一下。
3. 点蜡封进入对应节点（战斗/仪式等现有流）。
4. 一开只表达一关；右页无大段常驻系统说明（题名+≤60 字+蜡封）。
5. 不改卡牌 ID / 第二途径 / 路线树 / 战斗公式；主路径无新 `OptionButton`。

### 6.2 探针清单（实现版必须有）

| 检查 ID | 断言 |
|---|---|
| `V083_DESK_WORLD` | 存在 `DeskWorld` / `BookRoot` / `DeskCamera` |
| `V083_BOOK_NOT_FULLBLEED` | 书在相机投影下不盖满整屏（可用 AABB 或约定书 scale；至少 DeskMesh 可见） |
| `V083_SPREAD_PER_NODE` | `spread_list.size()` == 卷内 main clue 数（廷根=8） |
| `V083_FLIP_COMMIT` | 模拟横滑过半 → `current_spread_idx` +1 或 -1 |
| `V083_FLIP_BOUNCE` | 横滑不足半 / 锁页 → idx 不变 |
| `V083_SEAL_SELECT` | 对 AVAILABLE 蜡封 → 发出 `select_node`（或 ritual 的 `begin_ascension`） |
| `V083_NO_BOOK_ART_PATH` | 主路径不再依赖全屏 `DiaryBookArt` 可见 |
| `V083_API_COMPAT` | `apply_snapshot` / `request_node` / `present_post_encounter` 仍可被 app 调用 |

## 7. 非目标（本 P0 / 本设计版）

- Blender 精模、正式桌面立绘包
- 符文详情薄层、结算墨渍爽感（P1/P2）
- 真网格刻字、整游戏 3D
- 再调 2D alpha / 羊皮垫 / 全屏后正当「3D」
- 平衡数值大改
- 改 diary JSON schema / 改 `node_id`
- 旁支 clue 独立开页

## 8. 与旧 BRIEF 关系

| 旧条款 | 本契约 |
|---|---|
| 画面重心是摊开日记 | **保留**，但日记必须是桌上 3D 物件 |
| 背景简洁 | **修订**：背景=桌面烛台场景，不是空或书墙纸 |
| 拖页角为主翻页 | **修订**：横滑整页为主；页角非唯一 |
| 实现可用 Control 叠层、不要求真 3D | **作废**（P0 起要求真 3D 书载体） |

墨迹三层语义、仪式软失败、禁新卡等冻结规则不变。

## 9. 实现派工清单（冻结后交给 UI，本设计版不执行）

1. `diary_ui_catalog`：1 clue → 1 spread 适配。
2. 新建 DeskWorld 场景树（可仍由 `diary_chapter_screen.gd` 组装或拆 `diary_desk_world.gd`）。
3. 左右页 Viewport 内容按 §3 / §5A 填充。
4. 输入状态机 §5.2；接线 `_on_clue_pressed` 等价命令。
5. 退役全屏书图与闪现 Flip3D。
6. `tests/ui` 探针 §6.2；版本号另开执行版或本版转执行后 bump。

## 10. 设计 loop 记录

| Tick | 时间 | 产出 |
|---|---|---|
| 0 | 开环即刻 | 本文初稿 + v0.83 开版指针 |
| 0b | 开环后连续 | §5 节点树 / 输入机 / §5A 数据映射 / §6.2 探针 ID / §9 派工 |
| 冻 | 契约已可派工 | §5A.4 scene 对照表 / §5A.6 Chrome / 状态→**已冻结**；停 8 分钟空转 loop |
