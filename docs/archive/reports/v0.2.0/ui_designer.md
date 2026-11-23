# UI 设计报告：v0.2.0

```text
版本：v0.2.0
角色：UI 设计
任务：冻结页面流、低保真线框、只读视图模型与 UI 命令边界
状态：完成（静态线框与独立 Godot 视觉预览；未接入正式玩法）
```

## 1. 目标与范围

本版本只解决以下问题：

- 1600×900 下从启动到结算、错误恢复的完整页面流。
- 每个页面需要显示哪些只读数据、发送哪些玩家意图。
- 资源不足、目标非法、重复点击、危险阈值、加载失败和存档恢复如何呈现。
- UI 如何消费现有美术而不复制资产或把规则写进按钮。

本版本没有创建战斗结算、抽卡概率、存档读写或正式路由页面。补充交付的 `scenes/ui/ui_preview.tscn` 是独立静态视觉预览，只展示样张视图状态和本地选择提示。

## 2. 交付文件

- `assets/ui/wireframes/00_flow.svg`：总页面流与跨页面规则。
- `assets/ui/wireframes/01_start_resume.svg`：启动、继续、新游戏、损坏存档入口。
- `assets/ui/wireframes/02_day_identity.svg`：白昼人格、行动、资源与风险状态。
- `assets/ui/wireframes/03_map.svg`：城市路线、节点详情、风险预览与牌组入口。
- `assets/ui/wireframes/04_battle.svg`：三列威胁布局、手牌、敌人意图、事件日志与命令状态。
- `assets/ui/wireframes/05_reward.svg`：战斗奖励三选一与状态余波。
- `assets/ui/wireframes/06_gacha.svg`：灵界祈愿、保底、资源与确定性掉落说明。
- `assets/ui/wireframes/07_ascension.svg`：晋升条件、短仪式与提示入口。
- `assets/ui/wireframes/08_result.svg`：胜利/失败通用结算、保存状态与下一入口。
- `assets/ui/wireframes/09_error.svg`：错误原因、安全出口与不覆盖旧档的恢复路径。
- `assets/ui/wireframes/index.html`：本地浏览器总览，引用全部 SVG，不依赖网络。
- `src/ui/ui_preview.gd`：Godot 静态 UI 预览构建脚本。
- `scenes/ui/ui_preview.tscn`：页面流与战斗页双视图预览入口。

## 3. 页面流

```text
启动/继续
  -> 新游戏
  -> 白昼身份
  -> 城市地图
  -> 夜间战斗
  -> 战利品
  -> 灵界祈愿（可选）
  -> 晋升试炼（满足条件时）
  -> 本次结算
  -> 自动保存确认
  -> 返回白昼
```

任意页面发生内容加载、存档迁移或不可恢复规则异常时，进入统一错误页。错误页只显示恢复快照提供的安全操作。战斗、抽卡和晋升的结果确认不得靠 UI 自行切换场景，应用路由必须由状态或已确认的应用结果决定。

## 4. 页面信息层级

| 页面 | 首要信息 | 主要操作 | 次要信息 |
|---|---|---|---|
| 启动/继续 | 标题、是否存在存档 | 继续、新游戏、退出 | 存档版本、内容版本、时间 |
| 白昼身份 | 当前人格、剩余行动点 | 执行扮演、进入地图 | 稳定度、污染、注视、资源 |
| 城市地图 | 当前路线与风险 | 选择节点、进入节点 | 牌组、奖励预览、可达原因 |
| 夜间战斗 | 当前阶段、生命与灵性 | 选牌、选三列目标、取消、打出、结束回合 | 污染、注视、敌人意图、事件日志 |
| 战利品 | 三选一奖励 | 选择、确认、跳过 | 资源变化、危险阈值变化 |
| 灵界祈愿 | 卡池、消耗、保底 | 单抽、十连、确认结果、返回 | 已收集、概率、重复转化 |
| 晋升试炼 | 条件是否满足 | 选牌、排列、撤销、提示、确认 | 失败代价、晋升预览 |
| 本次结算 | 胜负与收获 | 返回安全屋、开始新夜晚、保存并回标题 | 身份余波、保存状态 |
| 错误 | 错误码、影响、数据是否保留 | 读取备份、打开目录、导出诊断、返回标题 | 折叠的技术摘要 |

## 5. 通用视图模型

以下字段只用于表达 UI 状态。字段最终名称由产品经理冻结；UI 不推导其业务含义。

```text
UiActionView
  action_id: StringName
  label_key: String
  enabled: bool
  pending: bool
  reason_code: StringName

MeterView
  id: StringName
  current: int
  max: int
  severity: neutral | warning | critical | blocked
  label_key: String

CostView
  resource_id: StringName
  amount: int
  affordable: bool

ResourceView
  resource_id: StringName
  amount: int
  display_key: String

CardFaceView
  card_id: StringName
  display_name_key: String
  category_id: StringName
  cost: Array[CostView]
  rules_text_key: String
  flavor_text_key: String
  art_reference_id: StringName
  rarity_id: StringName

PendingOperationView
  command_id: StringName
  in_progress: bool
```

约束：

- `severity`、`enabled`、`affordable`、`reason_code` 都由玩法或应用快照提供；UI 只把稳定原因码映射为本地化提示，不根据当前数值自行判断阈值。
- `card_id`、`resource_id`、`action_id` 使用稳定 ID；中文显示名不作为主键。
- `art_reference_id` 通过集中资源注册表解析，UI 不拼接文件路径。
- 文本通过 `*_key` 进入本地化层；原型阶段可以暂用中文，但生产页面不得把说明文案散落在回调里。

## 6. 页面契约

### 6.1 启动与继续

```text
BootViewModel
  build_version
  load_state: loading | ready | empty | failed
  has_save
  save_summary
    content_version
    saved_at
    chapter_label_key
    location_label_key
  load_error
    code
    message_key
    backup_available
  actions: continue_game | start_new_game | open_recovery | quit_game
```

无存档时“继续”禁用，并显示原因。已有存档时“新游戏”必须二次确认，确认内容说明旧自动存档不会被静默覆盖。

### 6.2 白昼身份

```text
DayViewModel
  day_index
  identity
    card_id
    display_name_key
    familiarity_current
    familiarity_max
  action_points_current
  action_points_max
  acting_progress
  meters: stability | pollution | attention
  resources
  actions: Array[IdentityActionView]
  map_enabled
  pending_operation
```

`IdentityActionView` 至少包含 `action_id`、标题、可用态、原因、消耗、可见后果和是否需要确认。封印物相关行动必须明确显示污染与被注视变化。

界面语义：日间动作对应应用用例 `PerformDayAction`，并携带稳定 `action_id`；进入地图或安全屋属于应用路由意图。具体命令负载等待产品经理冻结。

### 6.3 城市地图

```text
MapViewModel
  nodes
    node_id
    position
    state: locked | available | visited | selected
    risk_severity
    label_key
  selected_node
    title_key
    anomaly_type_key
    estimated_rounds
    reward_preview
    cost_preview
  deck_summary
  actions: select_map_node | enter_map_node | open_deck | return_day
```

不可达节点由快照标记为 `locked`，点击只显示 `reason_code`，不发送进入命令。

### 6.4 夜间战斗

玩法设计当前唯一推荐为“玩家逐张出牌 + 三列即时目标”。三列用于显示敌人位置和威胁，不做六格持续牌阵、召唤物或自动寻敌。UI 线框已按该草案更新；产品经理冻结前仍不视为最终接口。

```text
BattleViewModel
  encounter_title_key
  turn_index
  phase
  revision
  max_rounds
  player
    health
    max_health
    block
    spirit
    max_spirit
    meters: pollution | attention
  lanes[3]
    lane_index
    enemy: EnemyView | nil
  hand: Array[CardBattleView]
  enemies: Array[EnemyView]
  selection
    card_instance_id
    target_id
  event_feed
  draw_pile_count
  discard_pile_count
  actions
    select_card
    choose_target
    cancel_selection
    play_selected_card
    end_turn
```

`CardBattleView` 至少显示 `instance_id`、`definition_id`、`category`、`cost_spirit`、`target_type` 和只读 `Playability`。`Playability` 使用玩法定义的 `playable` 与 `reason_code`；UI 不检查卡牌类型、费用、目标合法性或死亡状态。若需要集中展示可选敌人，必须等待玩法接口冻结是否为批量查询字段，不能由 UI 另建规则。

命令边界：

- `select_card(card_instance_id)`：只改变选择意图。
- `choose_target(target_id)`：只改变目标意图。
- `cancel_selection()`：清除 UI 选择。
- `PlayCardCommand(card_instance_id, target_id?)`：由玩法验证并结算。
- `EndTurnCommand`：由玩法验证当前阶段和未处理事件。

玩法设计明确不引入全局命令 UUID 或通用事件总线；重复结算依靠 `card_instance_id`、阶段和玩法最终校验避免。UI 的 `pending` 只是本地防重复点击状态，不属于命令负载。

事件按顺序返回，UI 可以排队播放动画，但不可依据动画进度推导新状态；收到新快照后以 `revision` 为准，较早快照和事件批次要丢弃。动画中断后重新显示最新快照即可恢复。

### 6.5 战利品

```text
RewardViewModel
  origin_encounter_id
  reward_choices[3]
    reward_id
    category_id
    title_key
    rules_text_key
    selected
    selectable
  resource_delta
  meter_delta
  threshold_notice
  confirm_enabled
  skip_enabled
  pending_operation
```

命令：`select_reward`、`confirm_reward`、`skip_reward`。确认后等待玩法结果，不直接进入白昼。选择后是否可撤销由玩法规则提供，UI 不假设。

### 6.6 灵界祈愿

```text
GachaViewModel
  pool_id
  pool_title_key
  resources
  draw_costs
  pity
    current
    guarantee
    description_key
  probability_summary
  collection_summary
  draw_once_enabled
  draw_once_reason_code
  draw_ten_enabled
  draw_ten_reason_code
  result_reveal_state
  pending_operation
```

概率、折扣、保底和重复卡转化都来自快照或结果，UI 不本地计算。展示完整概率的按钮只打开只读说明面板。

界面语义：单抽、十连分别对应应用用例 `DrawGacha` 的 `draw_count=1/10`；结果确认与关闭只是 UI 流程。具体命令封装等待 PM 冻结。抽卡请求 pending 时禁止重复抽取；结果确认前禁止关闭池或再次抽取。

### 6.7 晋升试炼

```text
AscensionViewModel
  current_sequence
  target_sequence
  requirements
    requirement_id
    met
    current
    target
    label_key
  ritual_cards[]
  selection_order[]
  clue_panel
  hint
    available
    cost
    reason_code
  attempt_state: ready | arranging | submitting | failed | succeeded
  failure_effect_preview
  pending_operation
```

试炼无强制现实倒计时。失败后显示原因、保留材料说明和重新尝试入口。提示操作可能消耗资源，必须二次确认并显示消耗。

### 6.8 本次结算与错误

```text
RunResultViewModel
  outcome: victory | defeat | abandoned | blocked
  rewards
  identity_aftermath
  save_status
  next_actions

ErrorViewModel
  code
  category
  summary_key
  preserves_save
  technical_details_collapsed
  safe_actions
```

自动保存未得到数据层成功确认前，“保存并回标题”保持禁用或转为“重试保存”。错误页不提供删除原档的按钮。

## 7. 交互与边界状态

| 情况 | UI 行为 | 禁止行为 |
|---|---|---|
| 重复点击提交按钮 | 首次点击后设置 `pending`，禁用同一命令并显示进行中 | 由 UI 自行去重后改变结算 |
| 资源不足 | 显示短缺资源、所差数量与 `reason_code` | 自动改选更便宜操作 |
| 目标非法 | 目标高亮可解释，确认按钮禁用并显示原因 | 默认选择第一个目标 |
| 污染/注视接近阈值 | 显示 `severity` 对应文案和图标，不只靠颜色 | 用当前数字判断“即将锁定” |
| 命令被玩法拒绝 | 保持当前页面，聚焦原因提示，允许取消 | 点击后强制跳页 |
| 动画与状态不同步 | 丢弃旧 `revision`，按结果重绘 | 动画回调里自行改数值 |
| 内容加载失败 | 进入错误页，显示内容版本与安全出口 | 使用默认数据静默继续 |
| 存档损坏/迁移失败 | 显示备份是否可用，保留原文件 | 自动覆盖原存档 |
| 退出到标题 | 若有未结算命令，等待结果后再确认 | 中途销毁运行态 |

## 8. 键盘与可读性

- `Tab` / `Shift+Tab` 按视觉顺序移动焦点。
- `Enter` / `Space` 激活当前控件；`Esc` 取消选择或返回可撤销页面。
- 战斗快捷键暂不定死，等玩法命令冻结后再与 UI 映射一起确定。
- 危险状态同时使用标签、图标和数值，不只改变颜色。
- 最小正文按 1600×900 设计，不低于 14 px；关键操作与说明不低于 16 px。
- 动画可跳过，污染闪烁和套印错位提供降噪模式。
- 所有弹窗和错误恢复界面必须能只用键盘完成。

## 9. 美术映射与缺口

已可映射：

- `art/assets/png/scenes/title-screen.png`：启动背景。
- `art/assets/png/cards/card-identity-*.png`：白昼人格、抽卡结果与奖励展示。
- `art/assets/png/cards/card-artifact-*.png`：牌组预览、抽卡与封印物行动。
- `art/assets/png/enemies/enemy-lantern-pursuer.png`：战斗敌人区域。
- `art/assets/png/scenes/ritual-ascension.png`：晋升试炼背景。
- `art/assets/png/icons/status-sheet.png`：状态图标参考。

下一批缺口，按 UI 优先级：

1. 卡牌背面和普通/稀有/禁忌卡框。
2. 三列威胁边框、选中目标和可打出高亮。
3. 城市地图底图、路线线和五类节点图标。
4. 白昼安全屋、夜间街头与战斗背景。
5. 资源、奖励类别与错误恢复图标。
6. 灵界祈愿祭坛和抽卡结果展示底板。

正式资源接入前只做一次受控迁移到 `assets/` 并由资源注册表引用，禁止 UI 长期同时引用 `art/` 和 `assets/` 两份同名资源。

## 10. 困难、候选方案与决定

### 困难

- 玩法报告已经出现，唯一推荐为逐张出牌与三列目标；但命令与事件字段仍需产品经理冻结，不能现在写业务实现。
- 现有美术主要覆盖标题、卡牌与仪式，地图、牌阵和抽卡交互还需要版式支撑。
- 战斗页同时需要规则状态、动画事件与玩家选择，最容易把结算逻辑写进 UI。

### 候选方案

1. 所有流程做成单一大型 HUD。
2. 每个领域状态对应一个独立页面，抽卡结果和确认使用覆盖层。

### 决定

采用方案 2。每个主流程一个页面，确认、概率详情和抽卡揭示使用临时覆盖层；应用路由只根据稳定状态或应用结果变化。这样错误恢复、返回路径和测试边界更清楚。

## 11. 验证

- 10 个 SVG 均通过 XML 解析。
- `index.html` 使用相对引用，未引用网络资源。
- 战斗页已通过本地 Edge headless 渲染截图检查；发现并修复了事件序列条遮挡后排牌位的问题。
- Godot 4.7.2 以无界面编辑器模式完成资源导入，退出码为 0。
- `res://scenes/ui/ui_preview.tscn` 在 Godot headless 中成功启动 3 帧并正常退出，退出码为 0。
- 预览可通过场景运行命令打开；顶部按钮切换“页面流”和“战斗界面”，卡牌与列目标按钮只更新本地提示。
- 预览中的生命、灵性、可打出原因、敌人状态和保底信息全部是静态样张；没有接入真实快照、命令、RNG 或存档。

## 12. 跨角色请求

```text
[REQUEST]
从：UI 设计
给：玩法设计
版本：v0.2.0
内容：请确认三列威胁页面的只读映射。UI 提案读取 BattleSnapshot.revision、phase、max_rounds、lanes[3]、hand、玩家护盾和牌堆/弃牌数量，并通过 PlayCardCommand、EndTurnCommand 与 QueryCardPlay 展示操作状态。
原因：UI 需要显示禁用原因、丢弃旧快照并安全处理重复点击，同时不得复算规则。
期望接口：确认现有 BattleSnapshot/Playability 已覆盖这些页面字段；若缺少“可选择的全部敌人”字段，请决定由批量查询还是逐目标查询提供。
截止检查点：产品经理冻结玩法接口时
[END REQUEST]
```

```text
[REQUEST]
从：UI 设计
给：数值设计
版本：v0.2.0
内容：所有计量条需要同时提供 current、max、severity 和 label_key；抽卡页需要当前概率摘要、保底进度及消耗的只读显示数据。
原因：UI 不允许根据阈值自行判断颜色、危险文案或计算概率。
期望接口：MeterView 与 GachaProbabilityView 的显示数据约定。
截止检查点：数值表冻结前
[END REQUEST]
```

```text
[REQUEST]
从：UI 设计
给：本地数据层开发
版本：v0.2.0
内容：启动/继续与错误页需要加载状态、存档摘要、备份是否可用、错误分类和允许的安全操作；保存完成状态需可确认。
原因：UI 不读取文件，也不能把“点击离开”视为保存成功。
期望接口：BootViewModel、SaveSummaryView、ErrorViewModel 及保存结果。
截止检查点：应用装配与最小链路实现前
[END REQUEST]
```

```text
[REQUEST]
从：UI 设计
给：产品经理
版本：v0.2.0
内容：冻结页面路由、视图模型字段所有权、命令 ID 与资源迁移规则；确认抽卡结果覆盖层是否允许中断或跳过演出。
原因：这些决定会影响 UI 状态机和后续存档恢复路径。
期望接口：ADR 与 v0.3.0 进入条件。
截止检查点：v0.2.0 关闭前
[END REQUEST]
```

## 13. Godot 静态预览补充

为补齐 v0.2.0 的可运行视觉验收，新增一个独立场景。它不修改 `project.godot` 主场景，也不建立正式应用路由。

预览包含：

- 9 个主流程状态的总览和对应命令意图。
- 1600×900 战斗页静态样例。
- 三列威胁、当前玩家状态、敌人威胁、只读事件序列和三张手牌。
- 现有记者、医生、封印物、提灯追猎者美术的直接 `res://` 引用。
- “可打出 / 目标非法 / 灵性不足”三种由快照提供的静态状态展示。
- 重复提交只改变 UI 本地提示，不产生游戏结算。

运行方式：

```text
.tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe --path . res://scenes/ui/ui_preview.tscn
```

## 14. 下一步入口

产品经理冻结接口后，UI 才进入正式 Godot 路由与数据接线：

1. 建立 `scenes/ui` 的页面路由和应用壳。
2. 用静态视图模型字段做无规则假数据页面。
3. 接入玩法只读快照与命令，不在页面脚本中复制规则。
4. 先完成战斗页和错误页的真实渲染，再补其余页面。

玩法设计报告已在本报告关闭前读取；三列布局、逐张出牌和命令语义已对齐，但所有接口仍需产品经理 ADR 冻结后才可作为实现依据。
