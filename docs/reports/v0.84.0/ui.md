# v0.84.0 UI 报告

版本：v0.84.0  
角色：UI  
任务：BRIEF P0 桌上立体书 + ACTIVE_PLAN A→B→C→E  
状态：验证中（可执行项已清；关版待用户确认）  
计划：`docs/ACTIVE_PLAN.md`

## 已完成

### P0
- catalog：1 main clue → 1 spread（廷根 8）
- DeskWorld / 铰链翻页 / 蜡封 / 横滑 / 预检回弹 / 退役全屏 BookArt
- Chrome：右侧「合上」书签（远离 WaxSealHit）；页眉页脚更淡 + 状态脉冲
- 桌烛墨羽；页叠影；左页嵌板提亮
- 截图：`.tools/ui-captures/v084_desk_idle.png` / `v084_desk_flip.png`
- 探针：`V083_DIARY_DESK_P0_OK checks=21`；`V055_DIARY_CHAPTER_OK checks=59`

### P1 / P2（ACTIVE_PLAN B）
- 符文条按 AVAILABLE/COMPLETED/LOCKED 亮灭
- 点符文 → `RuneDetailLayer` 短说明（点空白收起）
- 结算 `play_settlement_fx` 桌面墨渍 bloom（表现层）
- 旁支 `side_notes` 贴条路径（现网日记无 `kind!=main`，有则显示）
- 页微翘：Quad + 轻微 scale/抬高（ArrayMesh 弯曲曾致页黑，已回退）
- 翻页/蜡封接 `TableSfx` KIND_FLIP / KIND_SEAL

### C / E
- DeskChrome 再淡；书签与蜡封热区不重叠
- 无美术 BRIEF → 正式纸纹进候选池
- V083 回归绿；主路径无新增原生 OptionButton

## 候选池
- 正式纸纹 / 桌面立绘 PNG
- 旁支内容补齐后贴条自动亮

## 验证
- 见上；`project.godot` = `0.84.0`
- 关版：**须用户点头**（ACTIVE_PLAN A 仅余此条）

## 困难与候选方案
- SubViewport 内 Button 不可点 → 屏上 `WaxSealHit`
- 长轮询曾被 Auto-review 拦；现用短间隔 ACTIVE_PLAN tick

## 最终解决
- P0+P1/P2 表现层补齐；不改规则/ID

## 风险
- 关版前需真窗口目视；截图 headless 无效须 GPU 跑 capture runner

## 跨角色请求
- 产品经理/用户：确认可关 v0.84 后更新 `CURRENT_VERSION` + `v0.84.0.md`
- 美术：若做纸纹/桌面立绘，另开 BRIEF

## 下一步入口
- 用户确认关版 → 删 ACTIVE_PLAN A → 停轮询 → 开下一版或执行 D

```text
版本：v0.84.0
角色：UI
任务：P0 + ACTIVE_PLAN A–E
状态：验证中（可执行项完成；待用户关版）
修改文件：src/ui/diary_desk_stage.gd, diary_chapter_screen.gd, diary_ui_catalog.gd, docs/ACTIVE_PLAN.md, docs/reports/v0.84.0/ui.md
验证：V083=21；无新增 OptionButton；截图路径就绪
下一步入口：用户确认关版
```

---

# 追加：A1 程序化翻页动画 + A2 真实投影（2026-11-23）

## 本版目标与当前任务
用户要求：以罗塞尔日记为载体、0-08 书写、笔记记录关卡、可交互、3D 形式；
进入后即桌面 + 烛台 + 摊开笔记，左页关卡背景图、右页关卡信息，点击进关卡。
本次按代码审查结论先落 **A1（程序化翻页无动画）** 与 **A2（全场无投影）**。

## 修改文件
- `src/ui/diary_desk_stage.gd`
- `src/ui/diary_chapter_screen.gd`
- `.tools/ui-captures/v084_desk_idle.png` / `v084_desk_flip.png`（重拍）

## 已完成内容

### A1 程序化翻页改为铰链动画
此前只有**拖拽**走 tween；导航书签 / 结算自动翻 / 索引跨叶全部直接调
`_on_desk_flip_committed` 硬切 —— 正是 BRIEF 要消灭的 2D 闪切，且 A-01 第 3 项
只验「横滑」，人眼验收覆盖不到。

- stage 新增 `play_flip(delta, duration)`：掀起 → 峰值 emit `flip_committed`
  （内容在半空换）→ 压平，与拖拽提交同构。
- stage 新增 `flip_visual_finished` 信号 + `is_flip_animating()`。
- 拖拽提交改为至少掀到 `COMMIT_FLIP_PEAK=0.95`（原先阈值 0.5 时只掀 0.55）。
- screen 新增 `_request_desk_flip()`，导航 / 结算 / 索引 / `_flip_to` 共 5 处改走它；
  `page_flip_finished` 改在**落平**时发，`is_flipping` 全程成立。
- 索引跨叶恢复逐叶慢翻（v0.63 行为，被 v0.84 硬切废掉）；长链按
  `INDEX_CHAIN_BUDGET=1.15s` 总预算加速成 riffle，单叶回看仍 0.82s。

竞态守卫（新增动画窗口带来的）：动画中忽略新手势、蜡封不响应、
`_refresh_wax_hit` 不在半空重新激活（内容在峰值已换，否则误进下一关）。
**bounce 与 commit 分离**（`_bounce_animating`）：bounce 不承诺
`flip_visual_finished`，否则回弹会把屏幕永久锁在 `is_flipping`。

### A2 真实投影
此前**没有任何灯开阴影**，接触阴影是一块 `UNSHADED` 假暗板，两页还自发光 →
平光贴纸感。

- KeyLight：`shadow_enabled`，`max_distance=7.0`，`normal_bias=1.4`（页面是零厚度
  Quad，低了必起 acne）。
- 烛光 OmniLight：开阴影，羽笔 / 墨水瓶 / 书影随 `_process` 的 flicker 呼吸。
- 删除假接触暗板；页自发光 0.18/0.22 → 0.08/0.10。
- **曝光重平衡**（原灯光是按「无阴影平光」调的，开影后亮面过曝）：
  key 1.15→0.9、fill 0.55→0.4、fill_r 0.4→0.28、烛 1.35→1.05（flicker 基线同步）；
  页底色 `0.9,0.84,0.7`→`0.79,0.72,0.57`（旧值接近纯白，在 key 下会 clip）。

## 验证（真机 GPU + headless，均已实跑）
环境更正：本机实为 **Darwin arm64**（环境头误报 Linux），`.tools/` 内置引擎可用。

- `V083_DIARY_DESK_P0_OK checks=21`
- `V055_DIARY_CHAPTER_OK checks=59`
- `V084_DESK_CAPTURE_OK`（有显示；截图已更新，可见烛光投影、书影、掀页投影）
- 全量 `tests/ui/*`：44 个 runner，除下列**改动前即为红**的 6 个外全绿。
- 回归归因：用反向还原法在 `/tmp` 重建改动前基线并对跑，
  `v056 / v072 / v077×2 / v081 / v082` **基线与本次 checks 数完全一致**（均为既有失败）；
  `tests/integration/app_flow_runner` 基线与本次失败项逐条相同，亦非本次引入。
  其中 v056 的 2 项（`index jump starts animated flip`、`index jump does not
  teleport idx mid-flip`）**由本次修复转绿**。
- `tests/gameplay/*` 20 个 runner：19 绿，`v012_identity_passive` 红
  （该 runner 不引用日记任何文件，与本次无关）。
- **`tests/integration/v091_app_destructive_runner` 挂起（非失败）**：headless 下
  跑满 150s 不退出。用同样的上限对跑**改动前基线同样 TIMEOUT**，故非本次引入；
  且该 runner 全程不翻页（只点按钮进战斗），与 A1 的动画窗口无关。
  **已定位根因**：runner 第 50–104 行用 `调查线索` / `前往节点` / `ClueHit` 找进关入口，
  而 v0.84 桌面改造已把主路径入口换成蜡封（`WaxSealButton` / 屏上 `WaxSealHit`），
  三者都找不到 → 没进战斗 → 仍停在日记屏 → 第 114 行对日记屏调用战斗专有方法
  `is_exit_confirmation_visible()` → `SCRIPT ERROR` 打断 `_ready` 协程 →
  永不执行 `get_tree().quit()` → **挂起而非失败**。
  基线与本次的报错字节级一致（`Nonexistent function 'is_exit_confirmation_visible'`）。
  该 runner 是 `tools/run_v091_qa.ps1` 版本门的一项；**v0.84 关版前应修**：
  runner 需认蜡封入口（`tests/integration/**` 属主协调者），
  且建议 runner 增加超时自退，避免脚本错误表现为无限挂起。
- 专项探针（临时，已删）：程序化翻页中途 `animating=true, yaw≈82–86°,
  idx 未变, finished=0`；落平后 `idx` 前进、`finished=1`、`yaw=0`；
  受阻翻页正确 bounce（「墨封未启——还不能掀到后面。」）、不前进、不残留锁、
  其后合法翻页仍可用。

## 困难与候选方案
- 候选 A：程序化翻页复用 `_flip_to` 的 2D tween —— 否，那是 BRIEF 要去掉的闪切层。
- 候选 B：stage 内部直接改 idx —— 否，会把规则/顺序判断下沉到表现层。
- **最终选择**：stage 只负责「掀—峰值通知—落平」，顺序与可否翻页仍由 screen 判定。
- bounce 曾与 commit 共用 `_flip_animating`，导致回弹后 `page_flip_finished`
  永不到达（v055 先红后修）；已拆成两个状态位。
- 曾顺手加 `set_process(false)`（C2 优化）—— 打红 v056 的 gaze 探针，
  **已撤销**：不属本次用户要求范围，另行开条。

## 风险 / 未解决
- **阴影参数需你在真窗口确认**：若 M 系以外 GPU 掉帧，第一个关的旋钮是
  `_candle_flame_light.shadow_enabled`（点光源阴影最贵）。
- **左页关卡背景图本身几乎是空的占位**（例：`battle-moretti-home.png` 只有两个
  暗色方框）。这是 `art/**` 资产缺口，不是光照问题；用户要的「左页关卡背景图」
  要真正成立，需美术按 BRIEF 产出实绘 —— 属美术角色，本次未动。
- A-01 验收表建议加一条：**程序化翻页（书签/结算/索引）也必须是铰链动画**，
  否则该缺陷会二次复发而目视表覆盖不到。

## 跨角色请求
- 产品经理：A-01 增补上述第 9 项；确认 v056/v072/v077/v081/v082 既有失败是否立缺陷单。
- 美术：左页关卡场景图需实绘（当前为占位），另开 BRIEF。

## 下一步入口
- 你真窗口确认手感与曝光 → 定稿参数；
- 其余审查项（A3 双音、A5 胜负三态、B1/B2、B3 截断、C1/C2）待你点单。

```text
版本：v0.84.0
角色：UI
任务：A1 程序化翻页动画 + A2 真实投影
状态：完成（代码与自动化验证已过；曝光/手感待真窗口确认）
修改文件：src/ui/diary_desk_stage.gd, src/ui/diary_chapter_screen.gd, .tools/ui-captures/v084_desk_*.png
依赖：无新增；不改规则 / 数值 / 卡牌 ID / schema
验证：V083=21、V055=59、V084 截图 OK；ui/gameplay/integration 全量对跑基线，无新增失败
      （既有红：ui 6 个、gameplay v012、integration app_flow + v091 挂起）
困难与候选方案：见上（bounce/commit 状态位拆分；拒绝 2D 闪切与规则下沉）
最终解决：stage 负责掀落表现，screen 保留顺序判定
风险：点光源阴影性能；左页关卡图为美术占位
跨角色请求：A-01 增补程序化翻页项；美术补左页实绘
下一步入口：真窗口确认 → 继续 A3/A5/B 组
```

---

# 追加：翻页连拍（flip strip）与中途换页修正（2026-11-23）

## 新增探针
`tests/ui/v084_diary_desk_flipstrip_runner.{gd,tscn}` —— **采样真实 `play_flip()`**，
不摆拍（不调 `_apply_flip_visual` 硬设姿势），在 10 个时间点取帧。
为避免 PNG 编码拖慢采样，帧先存内存，翻完再统一落盘。
需带显示运行；产物 `.tools/ui-captures/v084_flipstrip/`（含 `arc.txt` 数值）。

```bash
"$GODOT" --path . res://tests/ui/v084_diary_desk_flipstrip_runner.tscn
# 期望：V084_FLIPSTRIP_OK frames=10
```

## 实测弧线（右页前翻，idx 1→2）
```
0011ms yawR=   0.00  idx=1   起
0084ms yawR= -44.83  idx=1   EASE_OUT 上升
0157ms yawR= -81.67  idx=1
0224ms yawR= -97.85  idx=1
0270ms yawR= -99.68  idx=2 ← 峰值提交，内容在此换
0342ms yawR= -90.46  idx=2   EASE_IN 回落
0484ms yawR= -38.30  idx=2
0577ms yawR=   0.00  idx=2   落平，flipping=false
```
上升 ~252ms / 回落 ~308ms，与 `PROG_FLIP_DURATION=0.56` 一致；左铰链全程 0（未误动）。

## 连拍暴露的缺陷（单张静帧看不出来）
**中途换页是可见的 pop。** 对比首轮连拍：
`0210ms` 帧仍是「艾略特绑架案 / 阅」，`0260ms` 帧已是「提利尔仓库 / 启」，
而两帧**页面都正对镜头、文字清晰可读**。

根因：铰链是 **yaw 横滑**（BRIEF 冻结设计，非 bug），页面在整个行程中始终面向相机，
**永远不会侧到边**；而"峰值换内容"这套做法原本假设峰值时页面背对观众（真实翻页绕书脊
滚转才有此性质）。两者前提不匹配。

**修正**（表现层，不动 BRIEF 的 yaw 设计）：`_shade_turning_leaf()` ——
翻动中的那一叶按 `smoothstep(0.45,0.95,|p|)` 压暗至约 18% 亮度，峰值处文字不可读，
换页藏在暗部；回落自动恢复，`_reset_flip_visual()` 一并复位。
物理上也说得通：书页扫过烛光时本就该暗下去。
复拍确认：`0260ms` 帧文字已不可辨，`0560ms` 帧恢复满亮度且为新叶内容。

## 验证
- `V083=21`、`V055=59` 仍绿；`v056/v081/v082` checks 数与改动前**完全一致**（既有红）。
- `V084_DESK_CAPTURE_OK` 静态截图仍可用。

## 仍需你在真窗口确认
- 压暗幅度（0.82）与区间（0.45–0.95）是否过重/过轻 —— 静帧只能证明"遮住了"，
  **遮得自不自然要动起来看**。
- 烛光点阴影的帧率代价。

## 跨角色请求（不变）
- 主协调者：`v091_app_destructive_runner` 仍按旧入口找 `调查线索/ClueHit`，
  桌面路径已换蜡封 → 脚本错误 → **挂起而非失败**，关版前应修。
- 美术：左页关卡图仍为占位。

```text
版本：v0.84.0
角色：UI
任务：翻页连拍探针 + 中途换页 pop 修正
状态：完成（待真窗口确认压暗手感）
修改文件：src/ui/diary_desk_stage.gd, tests/ui/v084_diary_desk_flipstrip_runner.{gd,tscn}
验证：V084_FLIPSTRIP_OK frames=10；V083=21、V055=59；v056/v081/v082 与基线同
最终解决：yaw 横滑下页面不侧边，故用压暗遮换页，而非改 BRIEF 的铰链轴
风险：压暗参数需动态确认
下一步入口：真窗口确认 → B5 蜡封命中区投影化 + 放大取景
```

---

# 追加：按样板图重做桌面观感（2026-11-23）

用户提供参考图 `样板.jpg`，并指出：烛光不需要动态、场景太简陋。

## 逐项对照与处置

| 参考图特征 | 改动前 | 本次处置 |
|---|---|---|
| 书几乎占满画面 | ~45%，大片空桌 | 相机 fov 40→34，距离 2.30→1.95，俯角 -47.5°；书约占 75% |
| 烛光静态 | 每帧 flicker | **去掉 flicker**（`_process` 只留蜡封呼吸）|
| 画面四周压黑 | 无 | 新增 `DeskVignette` 四向渐变 |
| 左页插画洇入纸面 | 深色底板 + 金边框（像贴牌子）| 去掉底板与边框，改四向羊皮色羽化出血 |
| 右页符文竖排带标签 | 底部中央一排小方块 | 改右缘竖排圆形徽记 + 「本叶/启印/阅印/封印」标签 |
| 厚页叠、毛边 | 3 片薄板 | 18 片分叶（左右各 9），逐层缩进+交替色；书脊/封面加厚 |
| 书签带 | 无 | 新增 `BookmarkRibbon` 自订口垂下 |

## 顺带修掉的真缺陷

- **左右页亮度不一致**：灰度纸纹只加在右页，左页是纯色底 → 左页发白。
  现在两页共用同一套纸张处理（底色 `0.74,0.67,0.52` + grain 0.35）。
- **左页提亮过头**：`_left_art.modulate` 的 1.35 提亮是「无阴影平光」时代留下的，
  现在被光照重复加成 → 降到 ~1.0。
- **烛光烤白左页**：烛焰距左页仅约 0.3，平方反比下成了聚光灯。
  能量 1.35→0.26、抬高到 y=0.62、range→3.2，改作氛围光而非主光。
- 曝光整体再降一档：key 0.9→0.62、fill 0.22→0.12、ambient 0.35→0.22、
  页自发光归 0（之前靠自发光硬撑可读性，现在靠光照）。

## B5：蜡封命中区改为投影自维护（本次必须做）
相机一动，原先手调的锚点常数（L0.54/R0.76/T0.52/B0.82）必然错位。
新增 `_sync_wax_hit_rect()`：取 `WaxSealButton` 在页 SubViewport 内的矩形 →
换算 UV → 经 `_page_uv_to_world()` 映射到页面 Quad 的世界坐标 →
`Camera3D.unproject_position()` 投影回屏幕。翻页/回弹期间跳过（避免半空误触）。

**实测验证**（临时探针，已删）：
```
HIT rect pos=(1025,553) size=(173,121)
HIT anchors L=0.641 R=0.749 T=0.615 B=0.750
HIT centre pixel = (0.93, 0.17, 0.07)  red_dominant=true   ← 正中红蜡
HIT click -> command=SENT
```
旧常数框 352×270px，实际蜡封仅 173×121px —— 原先既过大又会随取景静默漂移。

## 验证
- `V083=21`、`V055=59`、`UI_SMOKE=33`、`V05_ROUTE_UI_SMOKE=65` 全绿。
- `v056/v072/v077×2/v081/v082` checks 数与改动前**完全一致**（既有红，非本次）。
- `V084_FLIPSTRIP_OK frames=10`：新书体下弧线仍为 0→-99.7°→0，峰值提交、落平解锁。
- `V084_DESK_CAPTURE_OK`。

## 仍与参考图有差距的部分——**都是美术资产，不是代码**
1. **左页插画**：参考图是水彩叙事插画；现仓内 `battle-*.png` 是空方框占位
   （画面里那圈"光晕"其实是占位图自带的金色边框被羽化放大）。**这是当前最大差距。**
2. 纸张质感：参考图有做旧斑渍/纤维；现为程序纹理平铺。
3. 蜡封：参考图是立体压印不规则蜡块；现为扁平圆角矩形 + 文字。
4. 桌面木纹：参考图是粗糙实木；现为灰度纹理染色。
5. 标题装饰框：参考图标题有回纹边框；本次未做（可代码实现，优先级低于 1）。

第 1 项需按参考图另开美术 BRIEF（`art/**` 非 UI 角色范围）。
在拿到实绘前，左页永远是"简陋"的，这一点改代码无法解决。

```text
版本：v0.84.0
角色：UI
任务：按样板图重做桌面观感 + 静态烛光 + B5 蜡封命中区投影化
状态：完成（代码侧；左页实绘待美术）
修改文件：src/ui/diary_desk_stage.gd
验证：V083=21、V055=59、UI_SMOKE=33、FLIPSTRIP frames=10；命中区像素级验证红蜡命中
困难与候选方案：候选 A 调亮左页→否（治标，根因是纸纹缺失与提亮叠加）；
                候选 B 继续手调蜡封锚点→否（取景再变又会漂）；选投影自维护
最终解决：取景/曝光/体积感在代码侧补齐；插画缺口明确移交美术
风险：阴影+18 片分叶的 GPU 代价需真机确认；左页实绘未到位前观感仍受限
跨角色请求：美术按 `样板.jpg` 产出左页叙事插画 BRIEF；主协调者修 v091 入口
下一步入口：真窗口确认取景与性能 → 标题装饰框 / 蜡封压印（代码侧剩余）
```

---

# 追加：达成样板图所需的跨角色需求清单（2026-11-23）

> 本节是 **UI 角色提出的需求草案**。按 AGENTS.md，`docs/design/**` 归产品经理，
> 正式 BRIEF 须由产品经理落稿；此处只做规格建议与证据。

## 0. 核心判断：这是**介质差距**，不是工作量差距

查证现有美术管线：

- 源文件是**程序生成的 SVG**（`art/tools/generate_v0xx_*.mjs` → `art/assets/svg/`），
  再由 `render_v0xx_*.gd` 导出 PNG。
- 实例：`battle-moretti-home.svg` 全文 **2939 字节**，内容是
  `linearGradient` + `pattern(hatch)` + `feTurbulence` 滤镜 —— 没有任何具象形体。
- `art/ASSET_MANIFEST.md` 首行明示：
  「所有当前资产均为项目内生成的**可编辑 SVG 占位美术，无第三方图片来源**」。

样板图左页是**有人物、有透视、有空气感的水彩叙事插画**。
3KB 的矢量渐变 + 噪声滤镜**在原理上**画不出它——无论投入多少时间。
所以第一件事不是派活，是**定介质**。

## 1. 唯一需要用户拍板的决策：左页插画怎么来

| 方案 | 产出质感 | 成本 | 与现有约束的冲突 |
|---|---|---|---|
| A. 人类画师手绘栅格图 | 可达样板图 | 8 张 × 外包周期/费用 | 引入第三方素材，需改 ASSET_MANIFEST 的「无第三方来源」声明 |
| B. AI 生成栅格图 | 可接近样板图（样板本身即此类） | 低 | 同上；另需确认授权与风格一致性 |
| C. 继续程序 SVG，但大幅加复杂度 | **达不到**；上限是风格化矢量插画 | 中 | 无冲突 |
| D. 混合：AI/手绘出底 → 程序叠纸纹做旧 | 接近样板且风格统一 | 中 | 同 A/B |

**UI 角色建议 D**：底图解决「具象与空气感」，程序层解决「洇入纸面、做旧、烛光响应」，
后者我已在代码侧实现（羽化出血 + grain + 光照），底图一换即生效。

AGENTS.md §6：新增第三方依赖须产品经理与数据层共同评审并记录来源、授权。
**此决策不在 UI 角色权限内。**

## 2. 给美术的精确规格（底图一旦定介质即可开工）

### 2.1 左页叙事插画 —— 最高优先级，当前最大差距

- 数量：**8 张**（廷根卷一，1 main clue = 1 开，已核对 `tingen_volume_1.json`）
- 画幅：**1600×900**（与现有 `assets/game/**/scenes/` 一致，catalog 无需改）
- 交付路径：`art/assets/svg/v0.85.0/scenes/`（或栅格则另议目录）
  → 正式 PNG 由**主协调者**迁移至 `assets/game/v0.85.0/scenes/`
- 命名必须**沿用现有 scene_id 映射**，否则 `scene_ui_catalog.gd` 要同步改：

| # | scene_id | 文件名 | 节点 | 类型 |
|---|---|---|---|---|
| 1 | `scene.battle.moretti_home` | `battle-moretti-home.png` | 密修会的闯入者 | normal |
| 2 | `scene.battle.elliot_ruin` | `battle-elliot-ruin.png` | 艾略特绑架案 | normal |
| 3 | `scene.battle.tyrell_warehouse` | `battle-tyrell-warehouse.png` | 提利尔仓库 | elite |
| 4 | `scene.battle.wood_house` | `battle-wood-house.png` | 伍德家的恶灵 | normal |
| 5 | `scene.rest.divination_club` | `rest-divination-club.png` | 占卜俱乐部 | rest |
| 6 | `scene.battle.lamud_chapel` | `battle-lamud-chapel.png` | 拉姆德小镇驱邪 | elite |
| 7 | `scene.battle.blackthorn_neil` | `battle-blackthorn-neil.png` | 失控的老尼尔 | boss |
| 8 | `scene.ritual.clown_ascension` | `ritual-clown-ascension.png` | 晋升：小丑 | ritual |

**构图约束（由当前实现反推，务必遵守）**：
- 采用 `STRETCH_KEEP_ASPECT_COVERED`，页面可视区约 **3:4 竖向**。
  1600×900 横图会被**裁掉左右两侧**，主体必须压在**中央竖向安全区**内。
  → 若美术更顺手，可改交 **1200×1600 竖幅**，我同步改 catalog（更贴样板图）。
- 四边各约 10% 会被羽化吃掉（出血），**不要在边缘放关键信息**。
- **不要自带边框**：现占位图自带金色描边，被羽化放大后成了「光晕」，是当前画面最大瑕疵。
- 色调：低饱和冷灰蓝 + 暖灯点缀；避免纯黑死区（页面会被烛光压暗一次）。
- 不含文字（标题由 UI 渲染）。

### 2.2 纸张做旧立绘（替换程序纹理）
- 路径：`assets/ui/diary/parchment_grain.png`（已存在，现为 v0.69 程序生成）
- 画幅 ≥ 2048×2048，**可四向无缝平铺**
- 增补样板图特征：水渍斑、纤维、折痕、边缘焦痕；灰度或极低饱和（会被代码染色）

### 2.3 蜡封立绘
- 路径建议 `assets/ui/diary/wax_seal.png`，512×512，**透明背景**
- 不规则边缘、挤压溢出、立体高光；中心留印章纹样
- 现为扁平圆角矩形 + 文字「启」，是样板图差距第 3 位
- 需 **3 态**：可启（红亮）/ 已阅（褐暗）/ 墨封（灰）

### 2.4 桌面木纹
- 路径建议 `assets/ui/diary/desk_wood.png`，2048×2048 可平铺
- 粗糙实木、年轮、刀痕；现为灰度纹理染色

## 3. 给产品经理的需求
1. **裁决 §1 的介质决策**，并相应更新 `art/ASSET_MANIFEST.md` 的「无第三方来源」声明。
2. 落稿正式 `docs/design/ART_BRIEF_V085.md`（本节可直接作为素材）。
3. 开 v0.85 版本并解冻 `art/**` 与 `assets/game/v0.85.0/**` 所有权。
4. A-01 验收表增补：**程序化翻页（书签/结算/索引）必须是铰链动画**
   —— 现表只验「横滑」，该缺陷曾存在且目视表覆盖不到。

## 4. 给主协调者的需求
1. `v091_app_destructive_runner` 仍按 `调查线索/前往节点/ClueHit` 找入口，
   桌面路径已换蜡封 → 脚本错误 → **挂起而非失败**；建议同时加超时自退。
2. 美术定稿后执行 PNG 受控迁移到 `assets/game/v0.85.0/**`。

## 5. 不依赖任何美术、UI 可自行完成的剩余项
- 标题回纹装饰框（样板图特征，纯代码可画）
- 蜡封在拿到立绘前的过渡改良：不规则轮廓 + 高光（Polygon2D / 多层 StyleBox）
- 字体：现仅 `NotoSansCJKsc-Regular`，样板图标题为书法/宋体风。
  **换字体是性价比最高的单项**，但属第三方依赖，须走 §3.1 同一评审。
- 页面微倾斜 / 轻微不平整（样板图书页不是完美平面）

```text
版本：v0.84.0
角色：UI
任务：输出达成样板图的跨角色需求清单
状态：完成（需求已出；介质决策待用户/产品经理）
修改文件：docs/reports/v0.84.0/ui.md
验证：资产清单经 tingen_volume_1.json + routes.json 交叉核对，8 开 8 张无重复
最终解决：明确「介质差距」为根因，拆成用户决策 / 美术规格 / PM / 主协调者 / UI 自做 五档
风险：若维持程序 SVG（方案 C），左页永远达不到样板图，属预期内上限
跨角色请求：见 §3、§4
下一步入口：用户拍板 §1 介质 → PM 落 BRIEF → 美术开工；UI 并行做 §5
```

---

# 追加：方案 D 落地 — BRIEF 草案 + 日记插画与场景图解耦（2026-11-23）

用户拍板**方案 D（栅格底图 + 程序做旧）**，并要求把需求写成尽可能详细的文档。

## 交付物
`docs/design/ART_BRIEF_V085_DRAFT.md`（375 行）。
按 AGENTS.md，`docs/design/**` 归产品经理，故标注为**草案**，待 PM 落稿。

内容：介质决策与合规前置 / 嵌入几何硬约束 / 安全区与 6 条禁止项 / 色板 /
**8 张逐张内容规格** / 纸张·蜡封·木纹 / 字体扩展 / 接入后 12 步流程 / 开放项。

8 张的画面内容全部**从游戏内实际数据推导**，非凭空想象：
日记原文与旁注取自 `tingen_volume_1.json`，敌人阵容取自 `encounters.json` +
`enemies.json`，世界观约束取自 `TINGEN_CANON.md` 与 `ART_DIRECTION.md`。

## 查证中发现的硬冲突及其解决（本次代码改动）

这 8 个 scene_id **同时**被 `battle_screen.gd` / `rest_screen.gd` /
`ritual_screen.gd` 用作 16:9 全屏背景。两种用途裁切方向相反（实测）：

| 画幅 | 日记左页(0.712 竖) | 战斗屏(1.78 横) |
|---|---|---|
| 1600×900 | **仅见 40% 宽** | 100% |
| 1260×1770 | 100% | **仅见 40% 高** |

单一画幅无解。**已解耦**：
- `scene_ui_catalog.gd` 新增 `DIARY_ART_DIR` / `DIARY_PATHS` /
  `diary_path_for()` / `has_diary_art()`；
- `diary_ui_catalog.gd` 左页改用 `diary_path_for()`；
- 日记优先取 `assets/game/v0.85.0/diary/*`，**缺失则静默回落**到现有 16:9 图；
- 战斗/休整/仪式屏**完全不受影响**。

效果：美术可**逐张交付、逐张生效**，不必等 8 张齐活，也不阻塞任何现有画面。

## 验证
- `V083=21`、`V055=59`；`v044/v045/v046/v047/v049` 场景 runner 全绿。
- 回落半边：8/8 `falls_back=true`，`battle_plate_unchanged=true`。
- **交付半边**（临时投放一张真 PNG 后 import 实测）：
  `delivered=true falls_back=false` —— 确认新图会被认出，不是只会回落。
  测试文件与 `assets/game/v0.85.0/` 已删净，复验 V083/V055 仍绿。

## 风险（已写入 BRIEF §6.2）
`diary_path_for()` 缺图时**静默回落、不报错**。
验收必须用 `has_diary_art(scene_id)` 逐张确认，
**不能以「界面没报错」判定交付完成** —— 否则漏交的图会伪装成已完成。

```text
版本：v0.84.0
角色：UI
任务：方案 D 需求文档化 + 日记/场景图路径解耦
状态：完成（文档待 PM 落稿；美术可开工）
修改文件：docs/design/ART_BRIEF_V085_DRAFT.md（新）, src/ui/scene_ui_catalog.gd,
          src/ui/diary_ui_catalog.gd, docs/reports/v0.84.0/ui.md
依赖：不改规则/数值/卡牌 ID/schema；战斗屏零影响
验证：V083=21、V055=59、场景 runner 全绿；回落与交付双向实测
困难与候选方案：候选 A 双画幅各出一版（16 张，成本翻倍）；
                候选 B 方形母版取双安全区（构图受限）；
                选 C 解耦双路径 —— 美术只出 8 张，战斗屏不动
最终解决：日记独立竖幅 + 自动回落，逐张可生效
风险：静默回落可能伪装成交付完成，验收须用 has_diary_art 逐张核
跨角色请求：PM 落稿 BRIEF 并裁决第三方素材/字体合规；主协调者建 raster 源目录与迁移
下一步入口：PM 批 BRIEF → 美术开工；UI 并行做标题回纹框 / 蜡封过渡改良
```

---

# 追加：v0.85 道具素材接入 + 可复用管线（2026-11-23）

用户在 `art/assets/raster/v0.85.0/props/` 放入 14 张新生成素材，
要求融入并**形成框架，便于后续快速接入新图纸与章节**。

## 素材现状（查证）
14 张 PNG 全部为 **RGB、无 alpha 通道**，主体置于深炭底（README 自述「便于抠图」）。
UI 需要 RGBA 透明素材，**不能直接用**。
本机无 PIL / ImageMagick，故用 Godot `Image` API 实现（与仓内 `art/tools/render_*.gd` 惯例一致）。

## 新增框架（三层）

### 1) 清单：`art/assets/raster/v0.85.0/props/props.manifest.json`
唯一需要人编辑的文件。声明每张图的抠图模式、容差、羽化、裁边、输出名、
额外输出路径（`also_out`）、派生变体（`variants`）。

### 2) 工具：`art/tools/key_props.gd`
```bash
"$GODOT" --headless --path . --script art/tools/key_props.gd   # → KEY_PROPS_OK count=13
```
抠图 / 羽化 / 自动裁边 / 派生着色变体 / 额外路径输出。幂等，可重跑。

**两个关键实现决策（都是被实测逼出来的）**：
- **洪水填充而非亮度阈值**：道具内部本就有深色（蜡封暗红阴影、印章黑嵌纹），
  全局阈值会把主体打出洞。改为从图像边界洪水填充，只清除与边界连通的背景。
- **最大通道差而非平均差**：暗红蜡封 vs 炭黑底仅在红通道差异明显，
  取平均会稀释到阈值以下。首次实现用平均值，**蜡封只剩 4.6% 不透明**（主体被吃光），
  改为取最大通道后恢复到 61.9%（正是花边圆形的真实占比）。

### 3) 运行时：`src/ui/prop_ui_catalog.gd`
`path()` / `has()` / `texture()` / `token_for_state()` / `missing()`。
**缺图返回 null**，所有调用点保留程序画法。

## 已接入的素材
| 素材 | 接入点 |
|---|---|
| `desk_wood` | DeskMesh 材质（真实木纹替换灰度染色）|
| `parchment_sheet` | 左右页背景（左页镜像，避免同一张图盖两次）|
| `wax_seal` | 右页进关按钮；**派生三态**（可启/已阅/墨封）|
| `token_*` ×4 | 右页符文栏换成真徽记；金罗盘高亮、余者暗银 |

符文栏接入时同步修了一处：有贴图时 StyleBox 底板与描边设为全透明，
否则painted 徽记会坐在一个彩色圆盘上；未点亮态改为暗金属（0.62 灰 / 0.5 alpha）
而非近乎消失。

## 文档：`docs/design/PROP_PIPELINE.md`（142 行）
含：为什么需要这层 / **加一个新道具的 3 步** / 字段说明 /
抠图算法原理与踩坑 / 一图多态 / **加一个新章节的 4 步** / 缺图降级 / 现有清单 / 注意事项。

## 探针：`tests/ui/v085_props_runner.{gd,tscn}` → `V085_PROPS_OK checks=38`
校验清单与 catalog 一致、素材已接入、**alpha 真的存在**
（角落透明 + 主体不透明占比 > 25%，双向卡住「没抠」与「抠过头」）、
四枚状态印一一对应、派生变体齐备、符文栏与蜡封命中区在位。

## 验证
- `V085_PROPS_OK=38`（新）、`V083=21`、`V055=59`、`V085_DIARY_ART_OK=20`、
  `UI_SMOKE=33`、`V05_ROUTE_UI_SMOKE=65`、`V050/V051/V052/V053/V054` 全绿。
- 既有红 6 个（v056/v072/v077×2/v081/v082）checks 数与改动前一致，无新增。
- **缺图降级实测**：把 `assets/ui/diary/props/` 整个移走后
  `V083=21`、`V055=59` 仍绿 —— 缺素材不崩溃、不失败，只回到程序观感。
- **探针有效性实测**：移走单张 `wax-seal.png` → `V085_PROPS_FAIL`，恢复后转绿。
  首版探针曾因 `.import` 缓存而漏报（`ResourceLoader.exists()` 对已删 PNG 仍为真），
  已在 `has()` 中加 `FileAccess.file_exists()` 实文件校验修正。

## 现网效果
左页廷根雨夜插画、右页羊皮纸 + 真蜡封 + 四枚金属状态印、桌面实木、书签缎带，
与 `样板.jpg` 已高度接近。截图：`.tools/ui-captures/v084_desk_idle.png`。

## 备注
`diary_desk_stage.gd` 在本轮期间被外部修改过（已有 `WOOD_PATH` / `SEAL_PATHS` /
`_wax_art` / `_load_texture`，但三张蜡封 PNG 并不存在，贴图为 null）。
按「不覆盖他人未提交修改」原则，**未另起一套**，而是用 `variants` + `also_out`
按其既有期望路径补齐产物，使该段代码直接生效。

```text
版本：v0.84.0（素材属 v0.85 预备）
角色：UI
任务：道具素材接入 + 可复用管线框架
状态：完成
修改文件：art/assets/raster/v0.85.0/props/props.manifest.json（新）、
          art/tools/key_props.gd（新）、src/ui/prop_ui_catalog.gd（新）、
          docs/design/PROP_PIPELINE.md（新）、tests/ui/v085_props_runner.*（新）、
          src/ui/diary_desk_stage.gd、assets/ui/diary/props/*（13）、
          assets/ui/diary/{desk_wood,wax_seal_*}.png（4）
依赖：不改规则/数值/卡牌 ID/schema；战斗屏零影响
验证：V085_PROPS=38、V083=21、V055=59，全量 ui runner 无新增失败；
      缺图降级与探针有效性均实测
困难与候选方案：候选 A 手工逐张抠图→否（每批重做、易漏）；
                候选 B 亮度阈值抠图→否，实测打洞；选边界洪水填充 + 最大通道差
最终解决：清单驱动，加素材 = 一行 JSON + 放文件 + 跑一条命令
风险：新增 PNG 后须跑一次 --import，否则看起来像没交付（已写入文档 §7）
跨角色请求：美术后续素材直接按 props.manifest.json 格式交付即可
下一步入口：接入 corner_ornament（标题框）与 candle/inkwell/quill 实体替换程序几何
```

---

# 追加：道具全面替换为实拍素材 + 框架可替换性验证（2026-11-23）

用户指出烛台 / 羽笔 / 纸张仍是旧的，要求**全面换成 props 素材**，
并借此验证框架是否真的方便替换。

## 先确认一处漏接（用户是对的）
上一轮的纸张接入代码块因 Python `assert` 失败而**整块未写入**，
当时未复查就报告完成。实测确认：`_add_parchment` 出现次数为 0，
页面仍在用旧的 `parchment_grain`。本轮已真正接上并复验。

## 本轮接入
| 素材 | 替换掉 | 回落 |
|---|---|---|
| `parchment_sheet` | `parchment_grain` 平铺（左页镜像）| 缺图回落 grain |
| `candle` | 车削黄铜烛台网格 | `_build_candlestick_mesh()` |
| `inkwell` / `quill_pen` | Cylinder / Box 网格 | `_build_desk_tools_mesh()` |
| `bookmark` | BoxMesh 缎带 | BoxMesh（`visible` 互斥）|

加上上一轮的 `desk_wood` / `wax_seal` / `token_*`×4，
**13 张已接入 11 张**；`corner_ornament`（标题框）与 `open_journal`（参考用）待接。

## 三个被实测纠正的错误

**1. 深色道具被抠穿**。默认容差 0.18 下墨水瓶只剩 **17.8% 不透明**
（深铜瓶身被判为背景），蜡烛丢了托盘。按素材深浅分别降容差
（inkwell 0.05 / candle 0.07 / quill 0.09 / bookmark 0.10）后
墨水瓶恢复到 48.4%、蜡烛 48.0%，托盘与瓶身完整。

**2. Sprite 跟随相机俯仰导致全部悬空**。最初让 sprite 绕 X 轴转
`CAMERA_PITCH_DEG(-47.5°)`，算出脚底被推离接触点约**高度的 32%**。
改为**保持竖直**（画面透视交给相机，立体感画里已有）后贴合桌面。

**3. 摆位靠猜连错两轮**（先被书挡、再跑出画面）。
改用 `Camera3D.unproject_position()` 逐点投影实测，得出当前取景下
只有 `|x|≈0.85 / z≈-0.15` 既在画面内又不被书遮挡；
并把 fov 34→38、相机后撤，给道具让出两侧空间。

## 框架可替换性验证（用户要求的核心）
**只改清单一行**，把 `inkwell.src` 从 `prop-inkwell.png` 换成 `prop-quill-pen.png`，
跑一次工具：输出从 521×681 变为 578×925，**未改任何一行代码**；
改回去再跑，即刻还原。证明「换图 = 改一行 JSON + 跑一条命令」成立。

## 验证
- `V085_PROPS=38`、`V083=21`、`V055=59`、`V085_DIARY_ART=20`、
  `UI_SMOKE=33`、`V05_ROUTE=65`、`V050/V053/V054` 全绿。
- 既有红 3 个（v056/v081/v082）checks 数与改动前一致，无新增。
- **缺图降级**：`assets/ui/diary/props/` 整个移走后 V083/V055 仍绿，
  全部回落到程序网格。
- **蜡封命中区**：取景改动后未手调任何常数，投影自维护生效 —
  实测 rect=(1023,619) 105×89，中心像素 `(0.57,0.16,0.14)` 为红蜡，点击发出命令。

## 文档
`PROP_PIPELINE.md` 补入 `_prop_sprite()` 用法（pivot/不跟随俯仰/alpha_cut）、
摆位须实测、深色道具容差经验，共 166 行。

```text
版本：v0.84.0（素材属 v0.85 预备）
角色：UI
任务：道具全面替换为实拍素材 + 框架可替换性验证
状态：完成
修改文件：src/ui/diary_desk_stage.gd、props.manifest.json、
          docs/design/PROP_PIPELINE.md、assets/ui/diary/props/*、
          docs/reports/v0.84.0/ui.md
验证：见上；含缺图降级与「改一行清单换图」双向实测
困难与候选方案：候选 A 保留程序网格仅换材质→否（车削网格无法表达蜡滴与雕花）；
                候选 B sprite 跟随相机俯仰→否，实测悬空 32% 高度；
                选竖直 sprite + 底边 pivot + 实测摆位
最终解决：11/13 素材已接入，全部带程序回落
风险：取景若再改，道具摆位需用 unproject 重测（已写入文档）
跨角色请求：无新增
下一步入口：corner_ornament 接入标题框；open_journal 可用于封面/合卷动画
```
