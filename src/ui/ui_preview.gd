extends Control

## Static v0.2.0 visual preview.
## This scene renders sample view states only. It does not resolve combat,
## read saves, roll randomness, or send gameplay commands.

const C_BG := Color("#11120d")
const C_SURFACE := Color("#1c1b15")
const C_SURFACE_RAISED := Color("#242119")
const C_PAPER := Color("#d8c29a")
const C_TEXT := Color("#e8dfc9")
const C_MUTED := Color("#9f967f")
const C_GOLD := Color("#b99750")
const C_LINE := Color("#3a3731")
const C_DANGER := Color("#7a2828")
const C_DANGER_TEXT := Color("#d8b4a8")

const FLOW_STEPS := [
	{
		"number": "01",
		"title": "启动 / 继续",
		"body": "读取存档摘要；无存档时禁用继续。",
		"command": "ContinueGame / StartNewGame",
	},
	{
		"number": "02",
		"title": "白昼人格",
		"body": "选择身份行动，查看资源与三项风险。",
		"command": "PerformDayAction",
	},
	{
		"number": "03",
		"title": "城市地图",
		"body": "选择可达节点，预览威胁与奖励。",
		"command": "EnterMapNode",
	},
	{
		"number": "04",
		"title": "夜间战斗",
		"body": "逐张出牌，三列即时目标，结束回合。",
		"command": "PlayCardCommand / EndTurnCommand",
	},
	{
		"number": "05",
		"title": "战利品",
		"body": "三选一，显示资源与阈值余波。",
		"command": "ConfirmReward / SkipReward",
	},
	{
		"number": "06",
		"title": "灵界祈愿",
		"body": "展示概率、保底、消耗与重复卡转化。",
		"command": "DrawGacha(count)",
	},
	{
		"number": "07",
		"title": "晋升试炼",
		"body": "条件检查、短仪式、可选提示与失败代价。",
		"command": "SubmitAscension",
	},
	{
		"number": "08",
		"title": "本次结算",
		"body": "展示胜负、收获、身份余波和保存确认。",
		"command": "ContinueRun / ReturnToTitle",
	},
	{
		"number": "09",
		"title": "错误与恢复",
		"body": "任何加载或迁移失败的统一安全出口。",
		"command": "LoadBackup / ExportDiagnostics",
	},
]

const SAMPLE_HAND := [
	{
		"id": "card.sample.divination",
		"name": "占卜",
		"state": "可打出",
		"reason": "费用 1，当前目标有效。",
		"tone": "ready",
		"texture": "res://assets/game/cards/card-identity-reporter.png",
	},
	{
		"id": "card.artifact.watchers_eye",
		"name": "窥视者之眼",
		"state": "目标非法",
		"reason": "静态快照 reason_code=invalid_target。",
		"tone": "danger",
		"texture": "res://assets/game/cards/card-artifact-watchers-eye.png",
	},
	{
		"id": "card.sample.insight",
		"name": "灵性洞察",
		"state": "灵性不足",
		"reason": "静态快照 reason_code=insufficient_spirit。",
		"tone": "blocked",
		"texture": "res://assets/game/cards/card-identity-doctor.png",
	},
]

var _content: VBoxContainer
var _flow_button: Button
var _battle_button: Button
var _hint_label: Label


func _ready() -> void:
	theme = _build_theme()
	_build_shell()
	_show_flow()


func _build_theme() -> Theme:
	var result := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei UI",
		"Microsoft YaHei",
		"Noto Sans CJK SC",
	])
	result.default_font = font
	result.default_font_size = 16
	return result


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = C_BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 28)
	safe.add_theme_constant_override("margin_top", 22)
	safe.add_theme_constant_override("margin_right", 28)
	safe.add_theme_constant_override("margin_bottom", 18)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	safe.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	var title_block := VBoxContainer.new()
	title_block.add_theme_constant_override("separation", 2)
	header.add_child(title_block)

	var title := _label("假面低语 · 静态 UI 预览", 28, C_TEXT)
	title_block.add_child(title)
	title_block.add_child(_label(
		"v0.2.0 / WHISPERS BENEATH THE MASK / INTERFACE PROTOTYPE",
		12,
		C_GOLD
	))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_flow_button = _button("页面流", _show_flow, true)
	_battle_button = _button("战斗界面", _show_battle)
	header.add_child(_flow_button)
	header.add_child(_battle_button)
	header.add_child(_badge("STATIC VIEW MODEL", C_MUTED, C_LINE))

	var divider := ColorRect.new()
	divider.color = C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	_content = VBoxContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	column.add_child(_content)

	var footer := HBoxContainer.new()
	column.add_child(footer)
	footer.add_child(_label(
		"仅表达信息层级与交互状态；所有结算、概率、路由和存档结果均由玩法与应用层提供。",
		13,
		C_MUTED
	))
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	footer.add_child(_label("1600 × 900  /  ESC 不执行返回", 12, C_GOLD))


func _show_flow() -> void:
	_clear_content()
	_set_active_tab(true)

	var intro := HBoxContainer.new()
	intro.add_theme_constant_override("separation", 18)
	_content.add_child(intro)
	var intro_copy := VBoxContainer.new()
	intro_copy.add_theme_constant_override("separation", 4)
	intro.add_child(intro_copy)
	intro_copy.add_child(_label("主页面流", 23, C_TEXT))
	intro_copy.add_child(_label(
		"应用负责路由；UI 只发送稳定意图。错误页可从任意阶段进入，并保留原始存档。",
		14,
		C_MUTED
	))
	var intro_spacer := Control.new()
	intro_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_child(intro_spacer)
	intro.add_child(_badge("9 个页面状态", C_GOLD, C_GOLD))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_content.add_child(grid)

	for index in FLOW_STEPS.size():
		grid.add_child(_flow_tile(FLOW_STEPS[index], index))

	var guardrail := _panel(_style(Color("#2d1919"), C_DANGER, 1, 8))
	guardrail.custom_minimum_size = Vector2(0, 72)
	_content.add_child(guardrail)
	var guardrail_row := HBoxContainer.new()
	guardrail_row.add_theme_constant_override("separation", 16)
	_pad_panel(guardrail, guardrail_row, 14)
	guardrail_row.add_child(_badge("范围守则", C_DANGER_TEXT, C_DANGER))
	guardrail_row.add_child(_label(
		"重复点击进入 pending；资源不足、目标非法与危险阈值只显示快照 reason_code，不在 UI 复算规则。",
		15,
		C_DANGER_TEXT
	))


func _flow_tile(step: Dictionary, index: int) -> Control:
	var accent := C_GOLD if index < 4 else C_MUTED
	var panel := _panel(_style(C_SURFACE, C_LINE, 1, 8))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 128)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	_pad_panel(panel, body, 14)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	body.add_child(heading)
	heading.add_child(_label(String(step["number"]), 13, accent))
	heading.add_child(_label(String(step["title"]), 18, C_TEXT))

	var description := _label(String(step["body"]), 14, C_MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(description)

	var command := _label(String(step["command"]), 12, accent)
	command.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(command)
	return panel


func _show_battle() -> void:
	_clear_content()
	_set_active_tab(false)

	var battle_header := _panel(_style(C_SURFACE, C_LINE, 1, 8))
	_content.add_child(battle_header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 18)
	_pad_panel(battle_header, header_row, 14)

	var encounter := VBoxContainer.new()
	encounter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter.add_theme_constant_override("separation", 2)
	header_row.add_child(encounter)
	encounter.add_child(_label("廷根旧宅 · 第 2 回合", 23, C_TEXT))
	encounter.add_child(_label(
		"PLAYER_ACTION  ·  sample revision 42  ·  领域状态为只读快照",
		12,
		C_MUTED
	))

	header_row.add_child(_meter("生命", "18 / 24", C_TEXT))
	header_row.add_child(_meter("灵性", "3 / 5", C_GOLD))
	header_row.add_child(_meter("污染", "2 / 10", C_DANGER_TEXT))
	header_row.add_child(_meter("被注视", "3 / 10", C_DANGER_TEXT))
	var end_turn := _button("结束回合", _on_end_turn, true)
	header_row.add_child(end_turn)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	_content.add_child(middle)

	var battlefield := _panel(_style(Color("#171711"), C_LINE, 1, 8))
	battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield.size_flags_stretch_ratio = 2.8
	middle.add_child(battlefield)
	_build_battlefield(battlefield)

	var side_panel := _panel(_style(C_SURFACE, C_LINE, 1, 8))
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_stretch_ratio = 1.0
	middle.add_child(side_panel)
	_build_side_panel(side_panel)

	var hand_panel := _panel(_style(Color("#1c1b15"), C_LINE, 1, 8))
	hand_panel.custom_minimum_size = Vector2(0, 270)
	_content.add_child(hand_panel)
	_build_hand(hand_panel)


func _build_battlefield(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_pad_panel(panel, column, 14)

	var heading := HBoxContainer.new()
	column.add_child(heading)
	heading.add_child(_label("威胁列", 18, C_TEXT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	heading.add_child(_label("三列即时目标 · 点击列查看静态目标状态", 13, C_MUTED))

	var lanes := HBoxContainer.new()
	lanes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lanes.add_theme_constant_override("separation", 10)
	column.add_child(lanes)
	lanes.add_child(_battle_lane(0, "第 1 列", false))
	lanes.add_child(_battle_lane(1, "第 2 列 · 当前威胁", true))
	lanes.add_child(_battle_lane(2, "第 3 列", false))


func _battle_lane(index: int, title: String, has_enemy: bool) -> Control:
	var lane_panel := _panel(_style(Color("#201e18"), C_DANGER if has_enemy else Color("#544d40"), 2, 7))
	lane_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lane_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	_pad_panel(lane_panel, body, 10)

	var lane_title := _label(title, 14, C_MUTED)
	lane_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(lane_title)

	if has_enemy:
		var enemy := TextureRect.new()
		enemy.texture = load("res://assets/game/v0.3.0/enemies/enemy-weeping-tenant.png")
		enemy.custom_minimum_size = Vector2(0, 190)
		enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		body.add_child(enemy)
		var enemy_name := _label("哭泣的房客", 17, C_TEXT)
		enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(enemy_name)
		body.add_child(_center_label("生命 16 / 16 · 意图：攻击 ?", 13, C_DANGER_TEXT))
	else:
		var empty := Control.new()
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.add_child(empty)
		body.add_child(_center_label("无目标", 14, C_MUTED))

	var target_button := _button(
		"选择该列",
		_on_lane_pressed.bind(index),
		has_enemy
	)
	target_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(target_button)
	return lane_panel


func _build_side_panel(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_pad_panel(panel, column, 14)
	column.add_child(_label("敌人与威胁", 18, C_TEXT))

	var threat := _panel(_style(Color("#1b1a15"), C_DANGER, 1, 7))
	threat.custom_minimum_size = Vector2(0, 120)
	column.add_child(threat)
	var threat_text := VBoxContainer.new()
	threat_text.add_theme_constant_override("separation", 5)
	_pad_panel(threat, threat_text, 12)
	threat_text.add_child(_label("提灯追猎者", 17, C_TEXT))
	threat_text.add_child(_label("攻击意图未知；下一事件可能增加被注视。", 13, C_MUTED))
	threat_text.add_child(_label("危险：被注视将在本回合后达到 5 / 10", 13, C_DANGER_TEXT))

	var log := _panel(_style(C_SURFACE_RAISED, C_LINE, 1, 7))
	log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(log)
	var log_text := VBoxContainer.new()
	log_text.add_theme_constant_override("separation", 6)
	_pad_panel(log, log_text, 12)
	log_text.add_child(_label("事件序列（只读）", 15, C_GOLD))
	log_text.add_child(_label("TurnStarted → CardDrawn → PlayerAction → EnemyResolve", 13, C_MUTED))
	_hint_label = _label("选择一张手牌查看静态可打性原因。", 13, C_TEXT)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.add_child(_hint_label)


func _build_hand(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_pad_panel(panel, column, 12)

	var heading := HBoxContainer.new()
	column.add_child(heading)
	heading.add_child(_label("手牌", 18, C_TEXT))
	var heading_spacer := Control.new()
	heading_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_spacer)
	heading.add_child(_label("选择为 UI 本地态；提交命令由玩法层验证", 13, C_MUTED))

	var hand_row := HBoxContainer.new()
	hand_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_row.add_theme_constant_override("separation", 12)
	column.add_child(hand_row)
	for card in SAMPLE_HAND:
		hand_row.add_child(_hand_card(card))


func _hand_card(card: Dictionary) -> Control:
	var panel := _panel(_style(Color("#1b1a15"), C_LINE, 1, 7))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_pad_panel(panel, row, 8)

	var art := TextureRect.new()
	art.texture = load(String(card["texture"]))
	art.custom_minimum_size = Vector2(120, 168)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(art)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 7)
	row.add_child(copy)
	copy.add_child(_label(String(card["name"]), 17, C_TEXT))
	var tone := String(card["tone"])
	var badge_color := C_GOLD
	if tone == "danger":
		badge_color = C_DANGER_TEXT
	elif tone == "blocked":
		badge_color = C_MUTED
	var state_badge := _badge(String(card["state"]), badge_color, badge_color)
	state_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	copy.add_child(state_badge)
	var reason := _label(String(card["reason"]), 13, C_MUTED)
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(reason)
	var inspect := _button("查看状态", _on_card_pressed.bind(card), true)
	copy.add_child(inspect)
	return panel


func _on_card_pressed(card: Dictionary) -> void:
	if not is_instance_valid(_hint_label):
		return
	_hint_label.text = "%s\n%s" % [String(card["name"]), String(card["reason"])]


func _on_lane_pressed(index: int) -> void:
	if not is_instance_valid(_hint_label):
		return
	var availability := "可选择" if index == 1 else "无目标，静态快照应为禁用"
	_hint_label.text = "目标列 %d：%s。\nUI 只记录选择意图，不判断最终合法性。" % [index + 1, availability]


func _on_end_turn() -> void:
	if not is_instance_valid(_hint_label):
		return
	_hint_label.text = "静态预览：EndTurnCommand 尚未接入。\n正式实现必须等待领域快照与命令接口冻结。"


func _clear_content() -> void:
	for child in _content.get_children():
		child.free()


func _set_active_tab(flow_active: bool) -> void:
	_flow_button.disabled = flow_active
	_battle_button.disabled = not flow_active


func _panel(style: StyleBoxFlat) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _pad_panel(panel: PanelContainer, child: Control, margin: int) -> void:
	var padded := MarginContainer.new()
	padded.add_theme_constant_override("margin_left", margin)
	padded.add_theme_constant_override("margin_top", margin)
	padded.add_theme_constant_override("margin_right", margin)
	padded.add_theme_constant_override("margin_bottom", margin)
	padded.add_child(child)
	panel.add_child(padded)


func _style(
	background: Color,
	border: Color,
	border_width: int = 1,
	radius: int = 8
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


func _center_label(text_value: String, font_size: int, color: Color) -> Label:
	var result := _label(text_value, font_size, color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result


func _badge(text_value: String, foreground: Color, border: Color) -> Label:
	var badge := _label(text_value, 12, foreground)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_stylebox_override("normal", _style(Color("#1b1a15"), border, 1, 5))
	badge.add_theme_constant_override("outline_size", 0)
	return badge


func _button(
	text_value: String,
	on_pressed: Callable,
	enabled: bool = true
) -> Button:
	var button := Button.new()
	button.text = text_value
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(118, 38)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", C_TEXT)
	button.add_theme_color_override("font_hover_color", Color("#fff4dc"))
	button.add_theme_color_override("font_disabled_color", C_MUTED)
	button.add_theme_stylebox_override("normal", _style(C_SURFACE_RAISED, C_LINE, 1, 6))
	button.add_theme_stylebox_override("hover", _style(Color("#302c23"), C_GOLD, 1, 6))
	button.add_theme_stylebox_override("pressed", _style(Color("#171711"), C_GOLD, 2, 6))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), C_GOLD, 2, 6))
	button.add_theme_stylebox_override("disabled", _style(Color("#181711"), C_LINE, 1, 6))
	button.pressed.connect(on_pressed)
	return button


func _meter(label_text: String, value_text: String, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.custom_minimum_size = Vector2(82, 0)
	box.add_child(_label(label_text, 12, C_MUTED))
	box.add_child(_label(value_text, 20, color))
	return box
