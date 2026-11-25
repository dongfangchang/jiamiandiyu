# Tasks · art

> 协议见 `../_meta/TASKS_FORMAT.md`。先立任务后执行。

## 进行中 / 待办

### ART-KEY-ORDER · 出图顺序与节奏
- status: doing
- 进度: title **已签字**；diary v2 驳回 → ART-KEY-02b；desk 三方案全驳回 → ART-KEY-03-rev；04–11 阻塞至 diary/desk 风格闸通过
- 做法: 标题定稿后，日记与桌面与 **ui-designer 共同决策**再出图；其后 P0→P1→P2：04 档案 → 05 卡匣… 每站提交推送并登记 STATUS。
- 一致性: 对照 `art/key_frames/title/approved.png`；文字载体必须吃烛光（暖橙反光+阴影），禁止纯白悬浮便签。
- 联合规则（用户 2026-11-25）: 目标帧阶段起，带文字的站位必须 **art + ui-designer 共同决策**（版式/字号/载体材质），再出图。

### ART-KEY-02b · 日记页重做（文字落在纸面）· 联合 UI
- status: done
- 优先级: P0
- 来源: 用户 2026-11-25 驳回 diary `candidate_v2`：「为什么文字不是显示在笔记上的，而是悬浮起来的」
- 协作: **art 出图 + ui-designer 共同决策**（右页版式、字号、页边距、墨色对比度；见 UI-KEY-DIARY-JOINT）
- 站位: `diary`
- 对照: `art/key_frames/title/approved.png`（同房同桌同烛同书）
- 驳回根因: 半透明纸色叠层浮在书页之上，未贴合右页透视与纸面材质
- 做法:
  1. 与 UI 先定：题名/正文/「启」的矩形落点（相对右页）、字号、行距、墨色（对比度 ≥4.5）— **UI-KEY-DIARY-JOINT done**
  2. 产出 `art/key_frames/diary/candidate_v3.png`：正文**印在**右页纸上（随纸面透视/微曲），非 HUD 浮层；蜡封「启」压在蜡上
  3. 更新 STATUS / 报告；commit+push；交用户审
- 完成标准: 用户可见「字在本子上」；通过后改名 `approved.png`
- 阻塞: 无（UI 联合纪要已完成）
- 怎么验: 用户拍板；**须 UI 联合签字纪要**（tasks/报告各留一段）
- 证据:
  - `art/key_frames/diary/candidate_v3.png` @1600×900
  - 底图 `art/key_frames/_work/kf_diary_v3_base.jpg`（无字；无浮层）
  - 思源宋体按 UI 纪要落点% multiply 印纸；蜡心「启」
  - STATUS diary → **批注中**
  - 报告：`docs/reports/v0.89.0/art.md`
  - 提交 SHA：见本提交
- 备注: 未自称 approved；交用户审印纸感

### ART-KEY-03 · 目标帧参考图：桌面总览（hub）——首轮
- status: rejected
- owner: art 智能体（2026-11-25）
- 优先级: P0
- 站位: `desk`
- 用户裁决（2026-11-25）: overview **三方案全不通过**
- 驳回根因: 场景为厚涂油画暗调神秘学+烛光局部照明；菜单是低饱和纯色白底便签，材质/光影/笔触与背景独立，无烛火暖橙反光与阴影，悬浮感严重
- 本轮证据（留档，不作选型）:
  - `art/key_frames/desk/options/{1,2,3,overview}.png`
  - `art/key_frames/desk/README.md`
  - 提交：`b3ea11c`
- 后续: 见 **ART-KEY-03-rev**

### ART-KEY-03-rev · 桌面总览重做（UI 载体融入场景光）· 联合 UI
- status: doing
- 优先级: P0
- 来源: 用户 2026-11-25 驳回 desk overview；要求后续与 ui-designer 共同决策
- 协作: **art 出图 + ui-designer 共同决策**（索引卡材质、入口文案层级、悬停态；见 UI-KEY-DESK-JOINT）
- 站位: `desk`
- 对照: `art/key_frames/title/approved.png`
- 方案数: 3（可保留原构图差异，但**菜单载体必须重做**）
- 硬性风格闸:
  - 索引卡/纸签 = 场景内物件：旧纸/铜版纸面，吃烛光暖橙、接触阴影、与桌面笔触一致
  - **禁止**低饱和纯白平底便签、平面 HUD 叠层
  - 文字仍用思源宋体叠真实文案；菜单 ≥22px；对比度 ≥4.5
- 交付: `art/key_frames/desk/options_v2/{1,2,3,overview}.png` + README；STATUS=待选
- 阻塞: 无（UI 联合纪要已完成；02b 已交批注）
- 怎么验: 用户拍板；**须 UI 联合签字纪要**

### ART-KEY-04 · 目标帧参考图：身份档案（建档 / 局况）
- status: todo
- 优先级: P0
- 阻塞: ART-KEY-02b 与 ART-KEY-03-rev 用户通过（风格闸）；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `dossier`
- 画什么: 推近到展开的档案夹：左页是身份相片（回形针夹住）、姓名、序列、途径；右页是资源（灵性、污染、被注视）、当前章节、局况。纸面为 B 铜版公文纸风格，档案夹皮面和桌面为 A。另画一张"建档模式"小图：三张身份候选相片可选。
- 方案数: 2 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/dossier/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/dossier/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**

### ART-KEY-05 · 目标帧参考图：卡匣（出战牌组 + 整理卡牌与残页）
- status: todo
- 优先级: P1
- 阻塞: ART-KEY-02b / ART-KEY-03-rev 通过；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `cardbox`
- 画什么: 打开的木卡匣，牌按槽位竖插，选中的 8 张摊在桌面上（用现有 v0.85 卡面插画缩略）；旁边是残页袋（升级入口）。文字入口有：确认牌组、整理残页、返回。展示一张"升级中"的卡（残页数 / 消耗）。
- 方案数: 3 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/cardbox/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/cardbox/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**

### ART-KEY-06 · 目标帧参考图：祈愿台（灵界祈愿 + 晋升仪式）
- status: todo
- 优先级: P1
- 阻塞: ART-KEY-02b / ART-KEY-03-rev 通过；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `altar`
- 画什么: 圆镜、三支烛、桌面上的粉笔圈。两种状态各一张：祈愿（镜面浮出牌背，翻开时揭示卡面）与仪式（粉笔圈亮起冷色灵光，右侧纸签列出仪式步骤）。冷色灵光只出现在这里。
- 方案数: 2 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/altar/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/altar/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**

### ART-KEY-07 · 目标帧参考图：战斗（夜间牌阵，离桌场景）
- status: todo
- 优先级: P1
- 阻塞: ART-KEY-02b / ART-KEY-03-rev 通过；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `battle`
- 画什么: 这是离开书桌的唯一场景，但画风仍属同一世界：深色绒布桌布加粉笔阵纹作为战场。敌人是铜版风格的立牌或卡；手牌在底部（沿用已通过的手牌卡面布局，比例 512:390）；状态（生命 / 灵性 / 污染 / 被注视）是黄铜计量器或纸签，不用平面 UI 条。需要保证 ADR-0030 布局红线。**这是改动最大的一屏，请出 3 个方案。**
- 方案数: 3 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/battle/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/battle/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**

### ART-KEY-08 · 目标帧参考图：日记页变体（奖励夹页 / 休息开 / 扉页 / 终章 / 回退开）
- status: todo
- 优先级: P1
- 阻塞: diary `approved.png`；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `diary_variants`
- 画什么: 在已选的日记页（B 纸面加 A 环境）基础上画 5 个小变体：①战斗后夹进书页的信封和奖励卡；②休息开，右页写有可选的纸签选项；③章节扉页；④章节终章（结语加完成蜡封）；⑤没有日记文案时的回退开（只有标题和场景图）。每个变体 1 张。
- 方案数: 1 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/diary_variants/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/diary_variants/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**

### ART-KEY-09 · 目标帧参考图：抽屉 / 值夜者卷宗（挑战）
- status: todo
- 优先级: P2
- 阻塞: ART-KEY-02b / ART-KEY-03-rev 通过；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `drawer`
- 画什么: 拉开的桌沿抽屉，里面放着几个值夜者卷宗文件夹（标签空白，文字由 UI 排版）；一个卷宗展开，显示挑战说明和修饰项（纸签勾选）。
- 方案数: 2 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/drawer/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/drawer/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**

### ART-KEY-10 · 目标帧参考图：过渡关键帧（墨迹门槛 / 烛灭 / 镜头推近）
- status: todo
- 优先级: P2
- 阻塞: ART-KEY-02b / ART-KEY-03-rev 通过；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `transitions`
- 画什么: 三组过渡各画 3 帧，用来定节奏和质感：①日记 → 战斗：蜡封裂开、墨晕扩散、盖满屏幕；②回标题：烛焰熄灭、余烟、暗下；③标题 → 桌面 → 日记：镜头推近的起点、中点、终点。
- 方案数: 1 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/transitions/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/transitions/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**

### ART-KEY-11 · 目标帧参考图：设置与系统纸签（设置 / 确认覆盖存档 / 错误提示）
- status: todo
- 优先级: P2
- 阻塞: ART-KEY-02b / ART-KEY-03-rev 通过；**须联合 ui-designer**
- 来源: 用户 2026-11-25："其他所有界面也先出参考图，我来拍板，全部定下来再做其他的"
- 站位: `settings`
- 画什么: 标题页或任意站位上弹出的纸签：设置（音量、全屏、恢复备份）、确认覆盖存档、加载失败提示。用 B 纸面，叠放在 A 环境上，背景压暗。
- 方案数: 2 个
- 风格: **必须遵守 ADR-0037 附录 A**——环境 = A 油画暗室（与标题页同一个房间、同一张桌、同一支蜡烛），纸面 = B 铜版插画；思源宋体；插画内不画文字，文字按最终位置用真实文案排版；正文原尺寸可读（菜单 ≥ 22px、正文 ≥ 20px、对比度 ≥ 4.5）。
- 交付: 每个方案都是 1600×900 完整画面，放在 `art/key_frames/settings/options/<1|2|3>.png`；本站位一张总览 `art/key_frames/settings/options/overview.png`（方案并排，每格标出方案名和一句话差异）；README 写清每个方案的构图思路和实现方式（3D 程序 / 分层绘制）。
- 怎么验: 主会话转给用户拍板；用户选定后进入"批注 → 修改 → 签字"，签字稿为 `approved.png`。**不需要 UI 审稿。**


> **2026-11-25 用户裁决**：渲染器 = Mobile（ADR-0036）；挑战未解锁时显示为灰色并写明原因；手牌通过；**标题页和日记页画面仍然太简陋 → ADR-0037"目标帧先行"：画面类实现暂停，先出概念图，由用户选定。**

### ART-KEY-01 · 三个风格方向的目标帧概念图（标题页 + 日记页）
- status: done
- owner: art 智能体（2026-11-25）
- 优先级: **P0（最高）**
- 来源: ADR-0037 D1；用户"改了几版都不满意"
- 改哪些: `art/key_frames/directions/<A|B|C>/{title,diary}.png` + `README.md`；总览 `overview.png`
- 完成标准: 6 张图加总览齐全；README 写清每个方向的光源、色板（5 个色值）、材质关键词、实现难度
- 怎么验: 交给用户挑选（主会话转达）；**不需要 UI 审稿**
- 阻塞: 无
- 证据:
  - `art/key_frames/directions/A/{title,diary}.png` @1600×900
  - `art/key_frames/directions/B/{title,diary}.png` @1600×900
  - `art/key_frames/directions/C/{title,diary}.png` @1600×900
  - `art/key_frames/directions/overview.png`（3×2，格内方向名）
  - `art/key_frames/directions/README.md`（光源 / 5 色板 / 材质 / 实现难度）
  - 报告：`docs/reports/v0.89.0/art.md`
  - 提交 SHA：见本提交
- 跨角色请求: 请主会话转达用户选型；解锁 ART-KEY-02
- 备注: 无参考图先行；底图无字 + 思源宋体叠字

### ART-KEY-02 · 按用户批注修改，直到签字
- status: done
- owner: art 智能体（2026-11-25 TASK_POLL tick 277）
- 解锁（2026-11-25）: 用户选定**标题页 = A，日记页 = B**
- 用户裁决（2026-11-25）:
  - **title `candidate_v2` 通过** → `art/key_frames/title/approved.png`
  - **diary `candidate_v2` 不通过**（文字悬浮未落在笔记上）→ **ART-KEY-02b**
- 本轮证据:
  - `art/key_frames/title/approved.png`（自 candidate_v2）
  - 驳回留档：`art/key_frames/diary/candidate_v2.png`
  - 提交 SHA：见本提交 / 登记提交
- 备注: diary 后续必须与 ui-designer 联合


> **2026-11-24 第二次下发（用户反馈 → ADR-0034）**：①控件绑定文字，物件只是画面；②替换即删除，禁止遮挡或隐藏旧界面；③日记可读性底线和画面升级。当前版本 **v0.89.0**（`docs/versions/v0.89.0.md`），P0 条目优先于其他所有条目。主会话会定时轮询本文件：done 条目必须写证据（提交 SHA、截图路径、测试输出），主会话据此合并、推送并下发后续任务。

### ART-DQ · 日记站画面升级批（DQ-01…06）
- status: done
- 优先级: P0（高于 ART-DW-X3、ART-02…05）
- 来源: 用户反馈"画风太简陋"；`docs/design/ART_BRIEF_DESK_WORLD.md` §5
- 改哪些: `art/assets/raster/desk_world/diary_quality/<DQ-id>/`（每项一个目录加 README）
- 完成标准: 书房背景板（正视，3840×2160）；桌面 PBR 三张图（2048 无缝）；书皮和书口；右页装饰套；丝带书签；接触阴影。规格与 §5 一致。
- 怎么验: 拼一张"现状截图 vs 资产示意"对比图，放进 `docs/reports/v0.89.0/art.md`；交给 UI 审稿
- 阻塞: 无
- 证据:
  - DQ-01 `diary_quality/dq01/room_backplate.png` @3840×2160
  - DQ-02 `dq02/desk_{albedo,normal,roughness}.png` @2048
  - DQ-03 `dq03/cover_{albedo,normal}.png` + `fore_edge.png` @1024×128
  - DQ-04 `dq04/` 页眉/四角×4/横线/涂鸦×6/墨渍×4
  - DQ-05 `dq05/ribbon_bookmark.png` @160×900 (+shadow)
  - DQ-06 `dq06/contact_shadow_*.png` ×14
  - 总览 `_overview/diary_quality_dq_overview_2048.png`
  - 示意对比 `docs/reports/v0.89.0/art_dq_before_after_schematic.png`
  - 报告 `docs/reports/v0.89.0/art.md`
- 跨角色请求: 请 **ui-designer** 审 DQ；真窗口对比后请 **coordinator** 迁入；勿美术自迁
- 备注: 2026-11-24 首轮交付；未迁 assets/game；未碰 owner:主会话 UI

### ART-DW-07b · 索引卡（桌面总览的文字入口底纸）
- status: done
- 来源: ADR-0034 D1
- 改哪些: `art/assets/raster/desk_world/index_card/`
- 完成标准: 600×900 正俯视索引卡，留 6 行空白书写行，无字，透明底；与 DW-07 同族
- 阻塞: 无
- 证据:
  - `index_card/index_card.png` + `index_card_shadow.png` @600×900
  - README：`index_card/README.md`
  - 报告：`docs/reports/v0.89.0/art.md`
- 跨角色请求: 请 UI 与 DQ 一并审稿；迁入同 coordinator
- 备注: 2026-11-24 与 ART-DQ 并行完成


> **2026-11-24 架构师下发**：框架已冻结为 `docs/architecture/EXPERIENCE_ARCHITECTURE.md`（ADR-0032，书桌世界）。任何 UI / 美术工作开工前必读；做不进"某物件的某站位"的需求一律退回设计。  
> 当前版本 v0.88（R2 + 热修）由**主会话**并行执行，标注 `owner: 主会话` 的条目**不要重复开工**，也不要改它们的文件。

### ART-DW-X1 · 书桌世界 X1 批（DW-01…07）
- status: done
- 来源: ADR-0032；`docs/design/ART_BRIEF_DESK_WORLD.md` §1
- 改哪些: `art/assets/raster/desk_world/<object>/`（每个物件一个目录加 README）
- 完成标准: 身份档案夹（开 / 合）、档案内页纸、相片框、书签纸条、合上的日记封面、烛台三帧、悬停题签全部交齐；正俯视、透明底、无字；阴影单独出图
- 怎么验: 尺寸和透明度核对；放进一张 2048 总览拼贴，对照 §4 自查；交给 ui-designer UI-07 审稿
- 阻塞: 无（规格已经定死为正俯视，不依赖镜头参数）
- 证据:
  - `art/assets/raster/desk_world/dossier/{closed,open}.png` + shadows
  - `art/assets/raster/desk_world/page/page.png` + shadow
  - `art/assets/raster/desk_world/photo_frame/photo_frame.png` + shadow（中心透明）
  - `art/assets/raster/desk_world/slip/slip.png` + shadow
  - `art/assets/raster/desk_world/book_closed/book_closed.png` + shadow
  - `art/assets/raster/desk_world/candle/{candle_lit,candle_out,smoke}.png` + shadows
  - `art/assets/raster/desk_world/tag/tag.png` + shadow
  - 总览: `art/assets/raster/desk_world/_overview/desk_world_x1_overview_2048.png`
  - 报告: `docs/reports/v0.88.0/art.md`
- 跨角色请求: 请 **ui-designer** 做 **UI-07** 审稿（按 DW-ID）；`DESK_WORLD_STATIONS.md` 若已出请标需改比例的 ID
- 备注: 2026-11-24 完成；站位稿未出，按 BRIEF 表尺寸；未迁 `assets/game`

### UI→art 请求区 · UI-07-DQ / UI-07-07b（2026-11-24）— **全过，无强制退回**
> 来自 ui-designer；详 `docs/reports/v0.89.0/ui.md`。请 coordinator **CO-DQ** 迁入。

| ID | 结论 | 原因 / 要做什么 |
|---|---|---|
| DQ-01…06 | **过** | 尺寸/透明/无字/BRIEF §5 语义齐 |
| DW-07b | **过** | 600×900；6 行空白线；无字；四角 α=0 |
| （可选微修） | 非阻塞 | `page_corner_tr` ↔ `page_corner_bl` 文件名建议互换；`fore_edge` 纸层横纹可再加强 |

### UI→art 请求区 · UI-07 退回（2026-11-24）— **已清零（复审全过）**
> 来自 ui-designer UI-07；比例锚见 `docs/design/DESK_WORLD_STATIONS.md` §5。

| DW-ID | 结论 | 原因 / 要做什么 |
|---|---|---|
| **DW-01 open** | **过（复审）** | 皮夹展开 + 左右空白公文纸 + 铜扣/标签族 |
| **DW-06 lit/out** | **过（复审）** | lit←out 母版叠焰；alpha xor=0 |
| DW-01 closed | 过 | 皮夹+铜扣+空白标签位；尺寸 800×1100 |
| DW-02 | 过 | 偏冷公文纸+淡横线；1024 平铺 |
| DW-03 | 过 | 回形针框、中心透明；600×800 |
| DW-04 | 过 | 空白纸条 700×260 |
| DW-05 | 过 | 合书烫金框无字；1400×1000 |
| DW-06 smoke | 过 | 有独立烟帧 |
| DW-07 | 过 | 空白题签 360×120 |
| （批次） | **已补** | 各物件 README 已齐（BRIEF §0） |

### ART-DW-X1-fix · UI-07 退回项
- status: done
- 来源: UI-07 2026-11-24
- 改哪些: `dossier/open.png`(+shadow)；`candle/candle_lit|out.png` 轮廓对齐；各目录 README
- 完成标准: 上表退回项清零；UI 复审过
- 怎么验: 再交 UI-07
- 证据:
  - `dossier/open.png` 重生为皮夹+双空白纸+铜扣/标签（非烫金开书）
  - `candle_lit.png` = `candle_out` 母版 ⊕ 俯视焰；alpha xor=0
  - 各物件 README 已按 BRIEF §0 补齐尺寸/状态/来源/授权
  - 总览已更新：`_overview/desk_world_x1_overview_2048.png`
  - 报告：`docs/reports/v0.88.0/art.md`
  - **UI 复审全过**（`docs/reports/v0.88.0/ui.md` UI-07 复审）
- 跨角色请求: ~~coordinator 迁入~~ → **CO-X1 done**（`assets/game/desk_world/`）

### ART-DW-X2 · 书桌世界 X2 批（DW-11…18）
- status: done
- 来源: ART_BRIEF_DESK_WORLD §2；X1 已过审
- 改哪些: `art/assets/raster/desk_world/<object>/`（cardbox/pouch/altar/circle_glow/ink_mask/envelope/battle_cloth/page_frames）+ shadow + README；总览；报告
- 完成标准: DW-11…18 齐；正俯视透明底无字；阴影另图；墨迹灰度阈值可扩散；不迁 assets/game；不开 X3
- 怎么验: 尺寸/alpha/灰度；2048 总览；请 ui-designer UI-07 审 X2
- 阻塞: 无
- 证据:
  - `cardbox/{closed,open}.png` + shadows @1200×900
  - `pouch/pouch.png` + shadow @600×600
  - `altar/{altar_idle,altar_active}.png` + shadows @1400×1400（外围 alpha 错配 0%）
  - `circle_glow/circle_glow.png` @1400×1400
  - `ink_mask/ink_mask_01..04.png` @2048×2048 L（中心亮/角黑）
  - `envelope/{envelope,insert_card}.png` + shadows
  - `battle_cloth/battle_cloth.png` @2048 平铺
  - `page_frames/{frontispiece,epilogue}_frame.png` + shadows @1260×1770（中心透明 100%）
  - 总览 `_overview/desk_world_x2_overview_2048.png`
  - 报告 `docs/reports/v0.88.0/art.md` X2 节
- 跨角色请求: ~~UI-07-X2~~ 全过；~~CO-X2~~ **done**（`assets/game/desk_world/`）；**不开 X3**
- 备注: 2026-11-24 完成；未迁 assets/game

### UI→art 请求区 · UI-07-X2（2026-11-24）— **已清零（全过）**
> 来自 ui-designer UI-07-X2；无退回项；非阻塞备注见 ui.md（DW-11 closed 偏面板感）。

| DW-ID | 结论 | 原因 / 要做什么 |
|---|---|---|
| DW-11…18 | **过** | 尺寸/透明/无字/墨迹灰度中心白/页框中心透明/altar 外围 xor=0/布接缝 均达标 |
| （批次） | **过** | 8/8 README；总览色温一致 |
| ART-DW-X2-fix | **不开** | 无退回 |

### ART-DW-X3 · 书桌世界 X3 批（DW-21…23）
- status: todo
- 来源: ART_BRIEF_DESK_WORLD §3
- 阻塞: X3 开版时由产品经理给出章节清单（DW-23）

> 现有 ART-01（桌木纹 / 蜡封三态）、ART-02（身份牌）照常进行：ART-02 的身份插画会放进 DW-03 相片框，构图请留出回形针区域。


### ART-01 · 日记桌材质补洞（desk_wood + 页蜡封三态）
- status: done
- 来源: ART_BRIEF_V085 §4；X2 余力
- 改哪些: `art/assets/raster/v0.85.0/desk_materials/**`
- 完成标准: `desk_wood` ≥2048 无缝平铺候选；`wax_seal_{available,completed,locked}` 各 512×512 透明、无字
- 怎么验: 尺寸核对 + 报告登记；正式迁入请 coordinator
- 阻塞: 无
- 证据:
  - `desk_wood.png` 2048×2048
  - `wax_seal_{available,completed,locked}.png` 512×512 RGBA
  - README：`art/assets/raster/v0.85.0/desk_materials/README.md`
- 跨角色请求: 请 coordinator 迁 `assets/ui/diary/`；请 ui-designer 真窗口抽查三态
- 备注: available 压印字母已后处理抹除

### ART-02 · 身份牌 3 张换 v0.85 风格
- status: todo
- 来源: art 缺口建议；现网仍 v0.48
- 改哪些: `art/assets/.../identities/` 候选 `art.png` 512×390（reporter/doctor/gravedigger）
- 完成标准: 三张候选齐、色温对齐技能卡；无插画内嵌字
- 怎么验: contact sheet + UI 审稿请求
- 阻塞: 无

### ART-03 · 敌人半身像铜版风格候选（按现有 encounter 名单）
- status: todo
- 来源: ART_DIRECTION；现网 SVG→PNG
- 改哪些: `art/assets/.../enemies/` 候选，目标约 900×900
- 完成标准: 现有敌人各一候选；不扩新敌人 ID
- 怎么验: README 清单；不迁 assets/game 除非 coordinator
- 阻塞: R1 内容冻结下只做风格补洞，不改 data

### ART-04 · 共用卡框分层源
- status: todo
- 来源: art/README §0
- 改哪些: `art/.../card-framework/` — paper_base / frame_chrome / effect_panel / 类型点
- 完成标准: 换卡只换插画的分层 PNG 可复用
- 怎么验: 用一张技能卡合成样张
- 阻塞: 可与 UI 手牌审稿并行

### ART-05 · 卡背 + 旧蜡封去英文（择期）
- status: todo
- 来源: ACTIVE_PLAN G-01 遗留
- 改哪些: 卡背候选；旧 4 枚母版无字重刻或确认 `-128` 足够
- 完成标准: 无拉丁字母；风格统一
- 怎么验: 目视 + 清单
- 阻塞: 低于 ART-01…04

### ART-06 · 配合 R0-11：按 UI 退回清单单张重修日记开页
- status: blocked
- 来源: ACTIVE_PLAN R0-11
- 改哪些: `art/.../scenes/` 被点名的竖图
- 完成标准: 退回项全部重交
- 怎么验: UI 复审
- 阻塞: 等待 ui-designer 出退回清单（按 scene_id）

## 已完成（近期）

### ART-done-diary-8 · 日记八开竖图 8/8
- status: done
- 证据: `assets/game/v0.85.0/diary/` 8/8 @1260×1770；真窗口审稿另属 UI

### ART-done-cards-40 · 技能卡插画 40/40
- status: done
- 证据: `art/assets/raster/v0.85.0/cards/**/art.png`

### ART-done-seals-24 · 蜡封矩阵 24/24
- status: done
- 证据: `art/assets/raster/v0.85.0/seals/`
