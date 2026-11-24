# 《假面低语》上手导读

> **给谁看**：新接手的人、换会话的智能体、隔了几天回来的自己。  
> **目标**：不读完整代码库，也能在 **15～20 分钟** 内弄清：这是什么、怎么协作、怎么走到今天、现在卡在哪、下一步读什么。  
> **不是**：完整 GDD、也不是 `ACTIVE_PLAN` 的任务清单（那两份仍然有效，本文件只做导航）。

更新日期：2026-11-23

**插画生成落点**：会话里出的章节栅格图直接进 `art/assets/raster/v0.85.0/`（见该目录 `README.md`），不要留在 Cursor 缓存。

---

## 1. 一句话产品

单人、**离线**、Godot 4.7.2 / GDScript 的《诡秘之主》同人卡牌游戏：身份伪装 + 牌阵战斗 + 抽卡成长 + 短仪式晋升。  
玩家本地游玩；**不做**多人、服务器、真实付费抽卡。

主场景：`res://src/app/app_root.tscn`  
引擎：项目内 `.tools/godot-4.7.2/`（**gitignore，不随仓库分发；换机需自备同版本 4.7.2**）  
便捷入口：macOS `./open-editor-mac.sh` / `./play-mac.sh`；Windows `open-editor.cmd` / `play.cmd`  
引擎二进制路径按平台解析，见 §4.3。

---

## 2. 现在最重要的三件事

1. **当前版本指针**（唯一权威）：[`docs/CURRENT_VERSION.md`](CURRENT_VERSION.md)  
   - 此刻：`v0.85.0`，阶段 **执行中**
   - 主题：为桌上立体日记交付八开插画、纸纹、木纹、蜡封和字体。v0.84 的真窗口关版验收仍保留。
2. **活的待办**（可勾销细条）：[`docs/ACTIVE_PLAN.md`](ACTIVE_PLAN.md)  
   - 关版门禁：`A-01` 目视表；用户说「关版」才做 `A-02`  
   - 玩法扩内容在 `D-*`（冻结）；后续点子在 `K-*`
3. **协作宪法**：根目录 [`AGENTS.md`](../AGENTS.md)  
   - 谁能改哪棵目录、禁止事项、质量门、汇报格式

当前美术规格：[`docs/design/ART_BRIEF_V085.md`](design/ART_BRIEF_V085.md)。翻页与蜡封交互沿用 [日记桌 3D 书契约](design/DIARY_DESK_3D_BRIEF.md)。

4. **长期方向与下一阶段**：[`docs/architecture/ROADMAP.md`](architecture/ROADMAP.md)
   - v0.85 关版后进入**架构整治期 R0–R4**（v0.86–v0.91）：先建安全网（统一测试 + 黄金回放），再删死代码、统一事实源、拆分大文件，然后回到内容生产（P1–P3 → 1.0）。
   - 问题清单：[`architecture/REVIEW_2026-11-24.md`](architecture/REVIEW_2026-11-24.md)（用 `AR-xx` 引用）；终点形态：[`architecture/TARGET_ARCHITECTURE.md`](architecture/TARGET_ARCHITECTURE.md)。
   - 已知坑（R0 之前不要被误导）：钉死版本号的测试已在 v0.86 删除（R0-03），战斗卡图覆盖问题已修复（AR-01）；跑测试用 `tools/run_tests.sh`；黄金回放 `tests/golden/` 是纯重构的判定标准；`diary_chapter_screen.gd` 约一半是隐藏的旧载体死代码（AR-42）。

---

## 3. 前因后果（压缩时间线）

不必从 v0.1 逐版啃。按「体验载体」理解即可：

| 阶段 | 大致版本 | 发生了什么 | 对今天的影响 |
|---|---|---|---|
| 可玩核 | v0.3～v0.14 | 战斗、存档、抽卡、身份、连携、多路线、卡池扩到约 20 张 | **规则与数据主链仍在**；UI 不得私自改公式 |
| 场景与立绘 | v0.43～v0.54 | 场景 BRIEF、敌人/身份立绘、战斗页露底与模块化面板 | `scene_id` → 背景 catalog；正式 PNG 在 `assets/game/` |
| 日记替代路线树 | v0.55～v0.56 | 章节用「日记」推进节点，不再主推路线树 UI；仪式软失败不灭章 | **主路径是日记章**；旧路线屏代码可能还在仓里但不是主交互 |
| 日记沉浸程序特效 | v0.57～v0.72 | 墨晕、纸纹、伪/真 3D 翻页、WorldEnvironment、字迹三层、线框 IA | 大量逻辑堆在 `diary_chapter_screen.gd`；后来证明「全屏书图 + 闪切」不够像桌上的书 |
| 0-08 笔改叙事 | v0.72～v0.76 | 覆写池、败局/墨渍/胜注按 node 旁白 | 玩法在 `route_engine.gd`；UI 只展示快照 |
| QA monkey | v0.78～v0.80 | 按钮/拖放/拖页角自动化砸主路径 | `tests/integration/**` |
| 可读性反复 | v0.81～v0.82 | 字迹对比、去垫板、翻页加强 | 静止阅读仍偏 2D 叠字 |
| 桌面立体书设计 | v0.83 | 只冻结 `DIARY_DESK_3D_BRIEF`，不写实现 | 验收与场景树契约的源头 |
| **桌面立体书实现** | **v0.84** | DeskWorld + 左右页 SubViewport + 横滑铰链 + 蜡封进关；P1/P2 表现层补强 | **现网日记主载体**；关版等用户目视 |
| **日记美术与字体** | **v0.85（当前）** | 独立竖幅插画、纸纹、木纹、蜡封和字体 | 分批接入，八开真窗口验收后进入关版 |

更全的版本表：[`docs/VERSION_INDEX.md`](VERSION_INDEX.md)（历史很长，按需查，不要从头通读）。

---

## 4. 桌面立体书基线（v0.84）

### 4.1 玩家在日记里看到什么

- 暗室里一张桌子：烛、墨水瓶、羽笔占位。
- 桌上有一本 **3D 打开的日记**：左页场景插图，右页短笔迹 + 蜡封。
- **一整开（左右页）= 一个关卡节点**（廷根卷 8 个 main clue → 8 开）。
- **横滑**翻页（铰链 yaw）；**点蜡封**进战斗/休息/仪式（命令仍是既有 `RouteCommand`）。
- 右上「合上」书签回 hub；系统壳故意做淡，避免盖过书。

截图证据（GPU 跑出来的，headless 会黑/空）：

- `.tools/ui-captures/v084_desk_idle.png`
- `.tools/ui-captures/v084_desk_flip.png`

### 4.2 关键代码地图（先认门牌，再下钻）

```text
玩家操作
  → src/ui/diary_chapter_screen.gd   # 屏、Chrome、结算表现、接线
      → src/ui/diary_desk_stage.gd    # DeskWorld / 铰链 / 蜡封命中 / 符文薄层
      → src/ui/diary_ui_catalog.gd  # 日记 JSON → spread_list（1 main = 1 开）
  →（命令）app → gameplay（route_engine 等）→ core
  ← 只读快照回来刷新 UI

内容：data/diaries/v0.55.0/tingen_volume_1.json
场景图：src/ui/scene_ui_catalog.gd + assets/game/...
音效：src/ui/table_sfx.gd
```

依赖方向（违反即架构债）：

```text
ui → app → gameplay → core
infrastructure → app/gameplay ports + core
```

UI **不算规则**；玩法 **不碰** `Control` / 存档 / 真 RNG。

### 4.3 探针与回归（改日记 UI 最少跑这些）

先解析引擎路径（`.tools/` 是本机工具链，不同平台布局不同）：

| 平台 | `.tools/godot-4.7.2/` 下的二进制 |
|---|---|
| macOS | `Godot.app/Contents/MacOS/Godot` |
| Windows | `Godot_v4.7.2-stable_win64.exe` |
| Linux | `Godot_v4.7.2-stable_linux.x86_64`（arm64 机器用 `.arm64`） |

```bash
# 取第一个可执行的；也可直接用环境变量 GODOT 覆盖。
# 注意 zsh 下无匹配的 glob 会报错，所以用 find 而不是 ls。
GODOT="${GODOT:-$(find .tools/godot-4.7.2 -maxdepth 5 -type f -perm -u+x \
  \( -name 'Godot' -o -name 'Godot_v4.7.2-stable_*' \) 2>/dev/null | head -1)}"
"$GODOT" --version   # 期望 4.7.2.stable

# 逻辑探针：headless 即可
"$GODOT" --headless --path . res://tests/ui/v083_diary_desk_p0_runner.tscn
# 期望：V083_DIARY_DESK_P0_OK checks=21
"$GODOT" --headless --path . res://tests/ui/v055_diary_chapter_runner.tscn
# 期望：V055_DIARY_CHAPTER_OK checks=59

# 截图必须带显示（不要 --headless）：DeskWorld 是 3D SubViewport，
# 无 GPU present 时输出黑图。
"$GODOT" --path . res://tests/ui/v084_diary_desk_capture_runner.tscn
# 产物：.tools/ui-captures/v084_desk_idle.png / v084_desk_flip.png
```

**平台事实（2026-11-23 实测）**：当前开发机为 macOS 26.5.1 / Apple M4 / arm64，
渲染走 `OpenGL API 4.1 Metal`（`project.godot` 为 `gl_compatibility`）。
`AGENTS.md` §1 仍写死 `G:\guimizhizhu`（Windows 时期遗留），与此不符；
**以本节与实际检出路径为准**，该条须产品经理裁决后修订（`AGENTS.md` 仅产品经理可改）。

角色报告：`docs/reports/v0.84.0/ui.md`

### 4.4 明确冻结（动之前先问产品经理）

- 不新增卡牌 ID；不扩第二途径；不恢复路线树为主路径。
- 主路径禁止新增原生 `OptionButton`（用项目内替代控件）。
- 仪式失败 **不灭章**（软失败）。
- 不改战斗公式 / 平衡散落值；数值在 `data/balance/**` 或卡牌自身定义。
- 不擅自关版；提交与推送按章程 §9（完成一个单元就提交推送，强推等例外须用户同意）。

---

## 5. 协作怎么转（避免踩坑）

| 角色 | 可写（当前习惯） | 只读/禁止 |
|---|---|---|
| 产品经理 | `docs/**`、`AGENTS.md`、版本/ADR/验收 | 未经派工直接改游戏功能 |
| UI | `src/ui/**`、`scenes/ui/**`、`assets/ui/**`、`tests/ui/**`、本版 UI 报告 | 战斗规则、数值公式、存档格式 |
| 玩法 | `src/gameplay/**`、`src/core/**`（若版本授权）、相关 `data/**`、玩法报告 | 直接操 UI / 文件系统 |
| 数值 | `data/balance/**`、`tools/simulation/**` | UI、规则流程、第二份卡牌定义 |
| 数据层 | `src/app/**`、`src/infrastructure/**`、`data/schema/**` | 代替玩法定规则 |
| 美术 | `art/**` | 自行验收进正式 `assets/game`（须主协调者迁移 + UI 审稿） |
| 主协调者 | 集成测试、构建、`project.godot`、资源迁移 | 静默改产品范围 |

**单一事实源**：版本目标看 `CURRENT_VERSION` + `docs/versions/<ver>.md`；进度写在 `docs/reports/<ver>/<role>.md`，聊天不能替代。

Bug：S1/S2 要有 `docs/bugs/BUG-xxxx.md`；先复现→根因→前向修，默认不回滚。

---

## 6. 建议阅读顺序（按时间盒）

### 5 分钟（能开口同步）

1. 本文 §1～§4.1  
2. [`CURRENT_VERSION.md`](CURRENT_VERSION.md)  
3. [`ACTIVE_PLAN.md`](ACTIVE_PLAN.md) 的「状态总览」表  

### 15 分钟（能改日记 UI 而不踩雷）

4. [`AGENTS.md`](../AGENTS.md) §4 所有权 + §6 依赖  
5. [`DIARY_DESK_3D_BRIEF.md`](design/DIARY_DESK_3D_BRIEF.md) §3、§5、§6  
6. 扫一眼 `diary_desk_stage.gd` 文件头与信号：`seal_activated` / `flip_committed`  
7. 跑一遍 V083  

### 45 分钟（能独立收一个小缺陷）

8. [`ARCHITECTURE_CONTRACT.md`](ARCHITECTURE_CONTRACT.md)  
9. [`TEAM_PROTOCOL.md`](TEAM_PROTOCOL.md)  
10. `docs/versions/v0.84.0.md` + `docs/reports/v0.84.0/ui.md`  
11. 若动叙事旁白：v0.72～v0.76 版本文档 + `route_engine.gd` 相关常量  

### 不要一上来就读

- 全部 `docs/versions/v0.*.md`——日常看 `VERSION_INDEX` + `VERSION_LOG`；复盘看 `docs/archive/`
- 整份 `diary_chapter_screen.gd`（历史沉浸特效很多；先确认你的改动是否还走 DeskStage 主路径）  
- README 里偏旧的「当前基线 v0.25」段落（以 `CURRENT_VERSION` 为准）

---

## 7. 常见「为什么这样怪」

| 现象 | 原因 |
|---|---|
| 蜡封在页 Viewport 里点不到 | 页在 3D SubViewport 内；真点击走屏上 `WaxSealHit` |
| headless 截图是黑的/空的 | DeskWorld 要 GPU present；用无 `--headless` 的 capture runner |
| 还有旧翻页/书图代码 | 兼容与探针保留；主路径应 `legacy_book_art_visible()==false` |
| 旁支贴条从来不出现 | UI 路径已通，但日记 JSON 里目前全是 `kind=main`（见 ACTIVE_PLAN `K-02`） |
| ArrayMesh 弯页又回退了 | 曾把 capture 弄成黑页；现用 Quad 微翘（`K-03` 候选再做） |
| README / VERSION_INDEX 早期行仍写「执行中」 | 历史索引未全部回写；**以 CURRENT_VERSION 为指针** |

---

## 8. 你落地后第一天建议动作

1. 拉代码 → `./open-editor-mac.sh` 能开工程。  
2. 读完本文 §2 + §6 的 15 分钟路径。  
3. 真窗口进廷根日记，对照 `ACTIVE_PLAN` `A-01` 表打勾（或记缺陷）。  
4. 在当前版本的 `docs/reports/<version>/<role>.md` 写「已阅读导读 + 当前任务」。  
5. 改代码前确认目录所有权；改完跑 §4.3 命令。

---

## 9. 文档地图（深潜入口）

| 文档 | 用途 |
|---|---|
| [`CURRENT_VERSION.md`](CURRENT_VERSION.md) | 现在在做哪一版 |
| [`ACTIVE_PLAN.md`](ACTIVE_PLAN.md) | 细粒度可勾销待办 |
| [`AGENTS.md`](../AGENTS.md) | 角色、所有权、质量门 |
| [`PROJECT_CHARTER.md`](PROJECT_CHARTER.md) | 产品目标与范围 |
| [`ARCHITECTURE_CONTRACT.md`](ARCHITECTURE_CONTRACT.md) | 分层与端口 |
| [`architecture/ROADMAP.md`](architecture/ROADMAP.md) | 分阶段路线（R0–R4 整治 → P1–P3 → 1.0） |
| [`architecture/TARGET_ARCHITECTURE.md`](architecture/TARGET_ARCHITECTURE.md) | 目标目录、效果注册表、快照/文案/资源约定、测试规则 |
| [`architecture/REVIEW_2026-11-24.md`](architecture/REVIEW_2026-11-24.md) | 架构审查缺陷清单（AR-xx） |
| [`TEAM_PROTOCOL.md`](TEAM_PROTOCOL.md) | 同步与报告纪律 |
| [`VERSION_INDEX.md`](VERSION_INDEX.md) | 里程碑 + 最近三版 |
| [`VERSION_LOG.md`](VERSION_LOG.md) | 其余版本一行流水账 |
| [`archive/`](archive/README.md) | 历史详档与报告归档（复盘，不删） |
| [`design/DIARY_DESK_3D_BRIEF.md`](design/DIARY_DESK_3D_BRIEF.md) | 当前日记载体契约 |
| [`design/DIARY_IMMERSION_BRIEF.md`](design/DIARY_IMMERSION_BRIEF.md) | 更早的沉浸日记纲领 |
| `docs/bugs/` | 缺陷档案 |
| `docs/decisions/` | ADR |
| `docs/reports/<ver>/` | 各角色当版工作实录 |

---

## 10. 维护约定

- 指针或主载体大变时：更新本文件 §2、§3 末行、§4。  
- 不要把本文件写成第二份 `ACTIVE_PLAN`（任务细节仍只写 ACTIVE_PLAN）。  
- 不要把本文件写成第二份章程（目标与范围仍以 PROJECT_CHARTER / 版本文档为准）。
