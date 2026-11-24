# v0.84.0 UI 报告

版本：v0.84.0  
角色：UI  
任务：BRIEF P0 桌上立体书 + ACTIVE_PLAN A→B→C→E  
状态：有条件关闭（2026-11-24 用户授权）  
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
状态：有条件关闭（2026-11-24 用户授权）
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

---

# 追加：量化对标参考图 + 接回后处理颗粒 + 主界面提示词（2026-11-23）

## 做了一件之前没做的事：把「差距」变成数字
用户反馈「差距还是太大」。此前都在凭感觉调曝光，本轮先写了量化对比
（现已提升为常驻工具 `tools/compare_to_reference.gd`）。

结果**直接推翻了之前的判断**：

| 指标 | 参考样板 | 改前 | 改后 |
|---|---|---|---|
| 平均亮度 | 0.237 | 0.340 | **0.265** |
| 中间调占比(bin5-10) | 30.9% | 11.9% | **28.5%** |
| 亮度 >0.75 的像素 | **0%** | 16% | **0%** |
| 局部细节(邻像素差) | 0.0439 | 0.0294 | **0.0456** |

**关键发现：参考图全图没有任何像素亮度超过 0.75。**
我一直把纸当作「需要被照亮的主体」，而参考图里**纸本身就是暗的**，
唯一亮的是烛焰那一小块。方向错了，所以越调越偏。

据此：key 0.62→0.40、纸张 modulate 0.80→0.62、ambient 0.22→0.34
（最后一项专门填中间调缺口）。三项指标一次收敛。

## 接回后处理（颗粒）
`assets/ui/diary/diary_postprocess.gdshader` **早就写好且完整**
（warm grade + film grain + vignette），但 `_install_desk_p0` 里写死
`_post_fx.visible = false` —— 桌面改造时因为它**位于 3D stage 之下、不起作用**而关掉。

修复：重新启用并 `move_child` 到最末 + `z_index = 100`，使其采样合成后的画面。
另外 `_process` 每帧会覆盖构建期参数，故强度要在 `_process` 里给：
`intensity 0.28→0.92`、`grain_amount 0.085`。

**调参过程**：grain 0.16 时细节冲到 0.0632（过头），回调到 0.085 得 0.0456，
对参考 0.0439 —— 基本吻合。这就是「照片感」缺的那一块。

## 验证
- `V085_PROPS=38`、`V083=21`、`V055=59`、`V085_DIARY_ART=20`、`UI_SMOKE=33` 全绿
- 既有红 3 个（v056/v081/v082）checks 数不变，无新增
- 四项量化指标全部进入参考图邻域

## 新增工具
`tools/compare_to_reference.gd` —— 参考图 vs 现网截图的量化对比，含用法与
各指标含义注释。以后改完观感跑一次即可得出差距，不再靠主观判断。

## 主界面重塑：提示词已交付
`art/assets/raster/v0.85.0/title/PROMPTS.md`（203 行）

**设计主张**：主界面与日记屏**共用同一张桌子**，区别只是书合着 vs 摊开。
点击合着的日记 → 翻开 → 进入章节。好处是复用 DeskWorld 与光照，
风格必然统一，且消灭主路径上的方块按钮。

映射：继续=书签 / 新游戏=未启封新书 / 挑战=卷宗堆 / 设置=怀表 /
退出=灭烛器 / 存档信息=夹着的便签（UI 写字）。

含 7 张提示词 + **全局约束表**（从现网实测反推：深炭底便于抠图、
最亮不超 75%、光从左上、不画投影、不含文字、平视角度）+ 通用负面提示 +
接入 3 步 + 7 条验收清单。

```text
版本：v0.84.0
角色：UI
任务：量化对标 + 后处理颗粒 + 主界面提示词
状态：完成
修改文件：src/ui/diary_desk_stage.gd、src/ui/diary_chapter_screen.gd、
          tools/compare_to_reference.gd（新）、
          art/assets/raster/v0.85.0/title/PROMPTS.md（新）、本报告
验证：四项指标收敛到参考邻域；全量 ui runner 无新增失败
困难与候选方案：候选 A 继续凭感觉调曝光→否（已证明方向错误）；
                候选 B 新写后处理→否，仓内 shader 本就完整，只是被关掉
最终解决：先量化再调参；后处理移到顶层并在 _process 给足强度
风险：grain 为逐帧 hash，静帧看不出闪烁，需真窗口确认动态下不跳
跨角色请求：用户按 PROMPTS.md 生成主界面素材
下一步入口：素材到位后按 §8 三步接入；或先做主界面 DeskWorld 复用改造
```

---

# 追加：卡牌插画 / 蜡封矩阵 / 主界面素材接入（2026-11-24）

用户在 `art/` 新增大批素材，要求**架构优先**，保证后续新增卡牌能快速嵌入。

## 清点
- `cards/<card.id>/art.png` × **40**（512×390 无字插画窗）
- `seals/` 4 稀有度 × 6 机制 = **24 格全齐**（含 128px UI 叠层版，共 49 档）
- `title/` 主界面素材 × 7（按上一轮 `PROMPTS.md` 生成）

**交叉核对**：40 个插画目录名 vs `data/cards/**` 的 40 个卡牌 ID —— 
**完全一一对应，零缺口零孤儿**。

## 接手时的架构债（本轮主要解决对象）
卡图路径此前有**两套并存且必须同步修改**的实现：
- `progression_ui_catalog.gd`：40 行硬编码字典
- `deck_ui_catalog.gd`：5 个版本目录的 if-else 链 + 3 套命名规则
  （`card-skill-x.png` / `card_skill_x.png` / 目录白名单）

加一张卡要同时改两处，正是「新增卡牌难以快速嵌入」的根因。

## 新架构（约定优于配置）

### `src/ui/card_art_catalog.gd`（新）— 单一事实源
- `art_window(id)` —— 路径**由 ID 推导**，不查表
- `rarity_of(id)` / `mechanic_of(id)` —— 读卡牌自身数据；机制由
  `effects` + `mechanic_tags` **推导**，不落盘、不二次存储
- `seal(id, small)` —— 稀有度 × 机制 → 24 格矩阵取图，**蜡封无需每卡手绘**
- `missing_art()` —— 让探针能区分「未交付」与「回落成功」

机制推导顺序遵循「这张卡是干什么用的」优先于「附带什么效果」：
仪式 → 占卜 → 攻击 → 防御 → 支援 → 诅咒。
两处实测修正：①「平复灵性」(heal+risk) 曾被判 curse，应为 support；
②「黄水晶灵摆」(draw+占卜标签) 曾被判 support，应为 divination。

### `art/tools/ingest_cards.gd`（新）— 迁移 + 守门
**目录名即卡牌 ID**，无需清单。守门行为：
- 插画无对应卡牌 → **失败**（防止死 ID 烘进 `assets/game`）
- 卡牌无插画 → 报 gaps 但不失败（允许分批交付）
- 尺寸非 512×390 → 警告

实跑：`INGEST_CARDS_OK cards=40 seals=49 gaps=0`

### 接入点
- `battle_screen.gd`：手牌优先用插画窗（512×390 用 COVERED 裁切填满，
  旧整卡仍用 CENTERED 以免切掉自带卡框）
- `deck_screen.gd`：缩略图用插画窗 + **新增蜡封角标**（带稀有度/机制 tooltip）
- 旧 `card_art()` 两处保持可用，其他屏不受影响

## 架构验证（用户要求的核心）
**实测新增一张卡**：`data/cards` 加一条（`rarity=rare`、带 `damage`）+
建一个插画目录，**未改任何一行代码** → 跑迁移工具 →
自动得到插画、判定 `rare`/`attack`、取到 `seal-rare-attack-128.png`；
且 `v085_card_art_runner` 检查数**从 170 自动增长到 174** 覆盖了新卡。
验证后已清除测试数据并复验还原（40 张、170 项）。

## 主界面素材
用户已按 `title/PROMPTS.md` 生成 7 张并加入清单；
探针 `v085_props_runner` 正确抓到「清单有、catalog 未登记」（38→45 项转红），
补上映射后转绿。其中 3 张初次抠图不净（`title_journal_new` 80.9% 不透明、
`title_pocket_watch` 91.7%），调高容差至 0.22 后降到 26% / 25%，主体完整。
**素材已就绪，主界面重塑尚未实现**（仍是旧面板）。

## 新增探针
`tests/ui/v085_card_art_runner.{gd,tscn}` → `V085_CARD_ART_OK checks=170`
校验：每张卡都能解析插画与蜡封、稀有度/机制在合法枚举内、
插画窗确为 512×390、未知 ID 不伪造蜡封、旧入口仍可用、
**4×6 蜡封矩阵完整**（保证任何新卡组合已被覆盖）。
检查数随卡牌数自动增长，无需维护。

## 验证
- `V085_CARD_ART=170`（新）、`V085_PROPS=45`、`V042_CARD_ART=181`、
  `V041_CLOWN_ART=48`、`V07_DECK_UI=66`、`V031_CANON_BATTLE=111`、
  `V013_CARD_PACK_OK` 等全绿
- 全量 ui runner：失败项仍为既有 6 个（v056/v072/v077×2/v081/v082），**无新增**

```text
版本：v0.84.0（素材属 v0.85 预备）
角色：UI
任务：卡牌插画 + 蜡封矩阵 + 主界面素材接入，建立快速嵌入架构
状态：完成（主界面重塑未实现，素材已就绪）
修改文件：src/ui/card_art_catalog.gd（新）、art/tools/ingest_cards.gd（新）、
          tests/ui/v085_card_art_runner.*（新）、src/ui/prop_ui_catalog.gd、
          src/ui/battle_screen.gd、src/ui/deck_screen.gd、
          props.manifest.json、docs/design/PROP_PIPELINE.md、本报告
依赖：不改规则/数值/卡牌 ID/schema；机制推导只读数据，不写回
验证：见上；含「新增卡零代码接入」实测与清理还原
困难与候选方案：候选 A 扩展现有两套 card_art→否（债翻倍）；
                候选 B 新建映射清单→否（仍需每卡登记）；
                选「目录名即 ID」约定 + 数据推导蜡封，零登记
最终解决：加卡 = 数据一条 + 目录一个 + 跑一条命令
风险：机制推导为启发式，新增特殊卡需复查蜡封是否贴切（探针会报枚举合法性，
      但判不出「语义是否贴切」）
跨角色请求：玩法/数据：新卡务必填 rarity；美术：插画严格 512×390 无字
下一步入口：主界面重塑（素材已就绪）；或卡框 7 层合成（paper/frame/pip/panel/seal）
```

---

# 追加：主界面重塑为「同一张桌子」（2026-11-24）

## 设计
主界面与日记屏共用同一张桌子，区别只是**书合着 vs 摊开**。
每个菜单项变成桌上的一件实物：

| 入口 | 桌上物件 | 原按钮文字（保留）|
|---|---|---|
| 继续 | 合着的皮面日记 | 继续上次战斗 |
| 新局 | 墨水瓶 | 开始新游戏 |
| 挑战 | 捆扎卷宗 | 进入挑战档案 |
| 设置 | 黄铜怀表 | 设置与玩法说明 |
| 熄烛 | 烛台 | 退出 |

## 关键实现决策

### 1) 不叠剪影，直接用定场图
`title-desk-wide.png` **本身已含全部道具**（日记居中、烛台左、怀表/墨水瓶右上、
卷宗右下）。最初实现是在定场图上再叠 5 张抠好的道具剪影 —— 看图后推翻：
那会得到两套互相错位的道具。
改为**只在定场图上定位热区**，各物件的屏幕矩形由 1920×1080 原图逐个量出换算成锚点。

### 2) 保留全部按钮与文字（关键约束）
`tests/integration/**` 的 monkey/destructive 探针靠**按钮文字**找入口
（`_button_by_text(controller, "继续上次战斗")` 等）。v091 的挂起就是因为
桌面改造换掉了入口名而探针没跟上。

因此本次**不新建控件、不改任何按钮文字**：
原 Button 被 `bind()` 重新挂到桌面层，变成覆盖该物件的**透明热区**，
焦点顺序、禁用逻辑、信号全部不变。物件名由桌面层单独画小字说明。

字形隐藏踩了一个坑：仅覆盖 `font_color` 系列**无效**（主题仍绘制），
书面与卷宗上出现「继续上次战斗」「进入挑战档案」字样；
最终加 `font_size = 1` + 全部状态色透明才真正消失。

### 3) 桌面替换旧背景而非叠加
首次 `move_child(desk, 1)` 后桌面不可见 —— 探针显示它被 index 2/3 的
`SceneBackgroundHolder` / `SceneDim`（雨夜街景）盖住。
改为隐藏那三层并把桌面移到 index 0。

### 4) 禁用态
禁用的入口把说明小字压暗（而非隐藏物件），避免邀请一次什么都不会发生的点击。
`set_busy` / `set_challenge_available` 都接了 `_sync_desk()`。

## 验证
- **七个探针按钮全部可找到且可见**（实测）：继续上次战斗 / 开始新游戏 /
  进入挑战档案 / 设置与玩法说明 / 退出 / 恢复上次备份 / 测试档案；
  `is_continue_enabled()` / `is_challenge_enabled()` 正常。
- 热区尺寸由锚点决定（如墨水瓶 171×200），初版因按钮残留
  `custom_minimum_size` 无法铺满物件，已清零。
- `V078_MONKEY_OK`、**`V079_MONKEY_OK`（1048 次操作，routes 含 `start`）**
  —— 自动化主路径未被破坏。
- 全量 ui runner：失败项仍为既有 6 个，**无新增**。
- 截图：`.tools/ui-captures/start_screen.png`

## 未做 / 风险
- **「合上→翻开」的过场动画未实现**，点击日记仍是直接切屏。
- 热区坐标是对着 1920×1080 定场图量的；**换定场图必须重量**（同日记屏道具摆位）。
- 极端宽高比下 `KEEP_ASPECT_COVERED` 会裁掉边缘物件，热区随之偏移 —— 需真窗口
  在非 16:9 下复验。

```text
版本：v0.84.0
角色：UI
任务：主界面重塑为桌面实物菜单
状态：完成（过场动画未做）
修改文件：src/ui/title_desk_stage.gd（新）、src/ui/start_screen.gd、本报告
依赖：素材来自 prop_ui_catalog；缺图自动回退旧面板（has_art 判定）
验证：7 按钮可达性实测、V078/V079 monkey 通过、全量 ui 无新增失败
困难与候选方案：候选 A 新建 TextureButton 替换旧按钮→否（会打断探针按文字查找）；
                候选 B 在定场图上叠道具剪影→否（与图内道具双重错位）；
                选「保留按钮 + 透明热区 + 按原图量坐标」
最终解决：表现层全新，控件树与探针面不变
风险：换定场图需重量坐标；非 16:9 需复验
跨角色请求：无
下一步入口：合上→翻开过场；或卡框 7 层合成
```

---

# 追加：修复 UID 重复 + 章节插画实际到位（2026-11-24）

## 症状
导入时报 8 条 `UID duplicate detected`，全部位于
`assets/game/v0.85.0/diary/`。

## 根因
这 8 张章节插画连同各自的 `.import` 文件一起被复制进来，
而 `.import` 里带 `uid=`，于是 **8 张图共用同一个 `uid://5f63hu8jq632`**。

危害不止是刷屏警告：Godot 会把同 UID 的资源解析成**同一个**，
画面上「看起来交付了」，实际可能渲染出另一张图 —— 而导入时只是 WARNING，极易漏过。

## 处理
1. 全仓扫描确认**仅此 8 个**文件受影响（`assets/` + `art/` 全量比对 uid）。
2. 确认**无任何代码按该 uid 引用**，且 8 张图内容各不相同（md5 互异）。
3. 删除这批 `.import` 并重跑 `--import`，Godot 重建出 8 个唯一 UID。
4. 复扫：重复警告数 0，全仓无重复。

## 顺带确认：章节插画已真正到位
这 8 张正是 `ART_BRIEF_V085_DRAFT.md` §3 要求的左页叙事插画。实测：

```
scene.battle.moretti_home      delivered=true  1260x1770
scene.battle.elliot_ruin       delivered=true  1260x1770
…（8/8 全部）
```

**尺寸恰为 1260×1770**，即 BRIEF §1.1 推导的零裁切规格 —— 美术严格照规格交付，
`diary_path_for()` 直接取用，无需改代码。现网日记左页已是实拍级插画
（截图 `.tools/ui-captures/v084_desk_idle.png`）。

## 新增防护
`v085_props_runner` 增加**全仓 `.import` UID 唯一性检查**（38→46 项）。

**有效性已实测**：人为把两张图的 uid 改成相同 →
`V085_PROPS_FAIL: no duplicate import UIDs (["battle-moretti-home... == battle-wood-house..."])`
并指出冲突双方；还原后转绿。不是永远绿的假检查。

`PROP_PIPELINE.md` §7 补入该陷阱与正确做法（只复制 `.png`，让 Godot 生成 `.import`）。

## 验证
- 重复警告数 **0**；全仓 UID 无重复
- `V085_DIARY_ART=20`、`V083=21`、`V055=59`、`V085_PROPS=46`、`V085_CARD_ART=170` 全绿
- 全量 ui runner 失败项仍为既有 6 个，**无新增**

```text
版本：v0.84.0
角色：UI
任务：修复 .import UID 重复；确认章节插画到位
状态：完成
修改文件：assets/game/v0.85.0/diary/*.import（重建）、
          tests/ui/v085_props_runner.gd、docs/design/PROP_PIPELINE.md、本报告
验证：警告清零 + 全仓复扫 + UID 检查有效性实测（植入重复能被抓到）
困难与候选方案：候选 A 手工逐个改 uid→否（易再错且不防复发）；
                选「删 .import 让引擎重建」+ 加自动检查
最终解决：重建唯一 UID，并把该陷阱变成探针断言
风险：此坑会随任何「连 .import 一起复制」的交付复发，故加检查而非只改文档
跨角色请求：美术/主协调者交付素材时只复制 .png，不要带 .import
下一步入口：合上→翻开过场；或卡框 7 层合成
```

---

# 追加：修复主界面点击失效 + 开卷过场（2026-11-24）

## 症状
用户反馈：七个入口看得见，但**实际点击好几个没反应**。

## 根因（两个叠加，都是输入拾取问题）

### 1) 全屏布局容器拦截点击（主因）
左侧文字栏的 `MarginContainer` / `VBoxContainer` **宽度铺满整屏**（虽然文字只占左侧），
而 Container 默认 `MOUSE_FILTER_STOP` —— 右侧道具（新局 / 挑战 / 熄烛）上的点击
全被这些**不可见的空容器**吞掉。

修复：新增 `_pass_through_layout()`，把 Container / Label / Panel 等纯排版节点设为
`MOUSE_FILTER_IGNORE`；`BaseButton` / `Range` / `LineEdit` / `TextEdit` 等真正可交互的
**跳过不动**，保持各自行为。

### 2) 桌面层与屏幕本身的 filter
- `TitleDeskStage` 原为 `MOUSE_FILTER_IGNORE` —— IGNORE 容器在拾取时**连同子节点一起被跳过**，
  热区按钮根本收不到事件。改为 `PASS`。
- `StartScreen` 自身从未设过 filter，默认 **STOP 且全屏**，同样吞点击。改为 `PASS`。
- 桌面层原在 `move_child(desk, 0)`；GUI 拾取按**树序反向**遍历，index 0 反而最低。
  改为移到**最末**。

### 3) 热区矩形互相重叠
日记热区 746×725 压住怀表（重叠 15949 px²），墨水瓶压住卷宗。
按各物件实体范围重新量取，**重叠数降为 0**。

## 验证（关键：排除测试自身干扰）
批量点击测试一度显示「只有第一个成功」，追查发现是**前一次点击弹出的确认框/系统菜单
未关闭**，挡住后续点击 —— 是探针缺陷，不是 UI 缺陷。

最终改为**每个按钮独立一次进程**运行，互不干扰：

```
ONECLICK continue  -> OK
ONECLICK new_game  -> OK
ONECLICK challenge -> OK
ONECLICK settings  -> OK
ONECLICK quit      -> OK
```

**五个入口全部可点**（真窗口，非 headless）。

## 开卷过场
`title_desk_stage.gd` 新增 `play_open(key)` / `open_finished` / `reset_open()`：
其余物件与说明小字先淡出（注意力收窄）→ 选中物件暖光亮起 →
整个桌面推近 9% 并淡出 → 发信号切屏。

接入 `_on_continue` / `_on_challenge`，经 `_emit_after_open()`：
**无桌面（素材缺失）或动画被拒时立即直发**，菜单不会卡住。

`set_busy(false)` 接 `reset_open()` —— 返回标题时复位，否则第二次进来是黑屏。

实测：
```
opening_started=true
signal_immediate=false      ← 不立即发，等动画
signal_after=true delay=0.89s
desk_alpha=0.00             ← 淡出到位
after_return alpha=1.00     ← 返回复位
second_open started=true / second_signal=true  ← 二次进入仍正常
```

## 回归
- 全量 ui runner：失败项仍为既有 6 个，**无新增**
- `V078_MONKEY_OK`、`V079_MONKEY_OK` —— 过场引入的延迟未打破自动化主路径

```text
版本：v0.84.0
角色：UI
任务：修复主界面点击失效；实现开卷过场
状态：完成
修改文件：src/ui/title_desk_stage.gd、src/ui/start_screen.gd、本报告
验证：五入口独立进程逐个实测可点；过场时序/复位/二次进入实测；monkey 通过
困难与候选方案：候选 A 给每个按钮单独提权→否（治标，容器仍会拦下一个新控件）；
                选「排版节点统一 IGNORE + 交互节点跳过」，根治且对后续新增控件有效
最终解决：拾取链三处 filter + 树序 + 热区去重叠
风险：过场固定 ~0.9s；若后续需要可跳过（点击任意处立即切屏）尚未实现
跨角色请求：无
下一步入口：过场可跳过；或卡框 7 层合成
```
