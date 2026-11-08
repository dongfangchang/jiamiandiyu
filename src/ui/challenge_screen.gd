extends Control

signal challenge_command_requested(command: ChallengeCommand)
signal exit_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const ChallengeCatalog := preload("res://src/ui/challenge_ui_catalog.gd")
const ChallengeSnapshotScript := preload("res://src/core/challenge_snapshot.gd")
const ChallengeCommandResultScript := preload("res://src/core/challenge_command_result.gd")

var _snapshot_data: Dictionary = {}
var _reward_labels: Dictionary = {}
var _modifier_row: HBoxContainer
var _status_label: Label
var _requirement_label: Label
var _reward_label: Label
var _route_label: Label
var _heading_label: Label
var _description_label: Label
var _eyebrow_label: Label
var _emblem: TextureRect
var _start_button: Button
var _exit_button: Button
var _buttons_by_modifier: Dictionary = {}
var _selected_modifier_id := ""
var _busy := false


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func apply_snapshot(snapshot: ChallengeSnapshot) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_selected_modifier_id = String(
		_snapshot_data.get("selected_modifier_id", "")
	)
	_busy = false
	_render()


func apply_command_result(result: ChallengeCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到挑战结果。", true)
		_refresh_buttons()
		return
	if not result.accepted:
		_set_status(ChallengeCatalog.reason_text(
			String(result.reason_code)
		), true)
		_refresh_buttons()
		return
	if result.snapshot != null:
		_snapshot_data = result.snapshot.to_dictionary()
		_selected_modifier_id = String(
			_snapshot_data.get("selected_modifier_id", "")
		)
	_render()
	_set_status("挑战档案已更新。")


func set_reward_labels(labels: Dictionary) -> void:
	_reward_labels = labels.duplicate(true)
	_update_reward_text()


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func is_pending() -> bool:
	return _busy


func request_modifier(modifier_id: String) -> void:
	if _busy:
		return
	if not bool(_snapshot_data.get("unlocked", false)):
		_set_status(ChallengeCatalog.reason_text("challenge_locked"), true)
		return
	if String(_snapshot_data.get("phase", "")) != "modifier_selection":
		_set_status(ChallengeCatalog.reason_text("wrong_phase"), true)
		return
	if not _modifier_ids().has(modifier_id):
		_set_status(ChallengeCatalog.reason_text("unknown_modifier"), true)
		return
	_selected_modifier_id = modifier_id
	_busy = true
	_render_modifier_states()
	_refresh_buttons()
	_set_status("正在记录挑战修饰……")
	challenge_command_requested.emit(
		ChallengeCommand.select_modifier(StringName(modifier_id))
	)


func request_start() -> void:
	if _busy or not can_start():
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在展开镜厅余响……")
	challenge_command_requested.emit(ChallengeCommand.start_challenge())


func request_exit() -> void:
	exit_requested.emit()


func can_start() -> bool:
	return (
		not _busy
		and bool(_snapshot_data.get("unlocked", false))
		and String(_snapshot_data.get("phase", "")) == "modifier_selection"
		and not _selected_modifier_id.is_empty()
	)


func get_modifier_count() -> int:
	return _modifier_ids().size()


func get_selected_modifier_id() -> String:
	return _selected_modifier_id


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_requirement_text() -> String:
	return _requirement_label.text if is_instance_valid(_requirement_label) else ""


func get_reward_text() -> String:
	return _reward_label.text if is_instance_valid(_reward_label) else ""


func get_background_path() -> String:
	return ChallengeCatalog.SELECTION_BACKGROUND


func get_challenge_title() -> String:
	return _heading_label.text if is_instance_valid(_heading_label) else ""


func get_route_text() -> String:
	return _route_label.text if is_instance_valid(_route_label) else ""


func get_emblem_path() -> String:
	return ChallengeCatalog.challenge_emblem(
		String(_snapshot_data.get("challenge_id", ""))
	)


func _build() -> void:
	UiTheme.add_background(
		self,
		ChallengeCatalog.SELECTION_BACKGROUND,
		UiTheme.C_BG,
		0.20
	)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 54)
	safe.add_theme_constant_override("margin_top", 36)
	safe.add_theme_constant_override("margin_right", 54)
	safe.add_theme_constant_override("margin_bottom", 34)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	safe.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	column.add_child(header)
	_emblem = TextureRect.new()
	_emblem.texture = load(ChallengeCatalog.challenge_emblem(""))
	_emblem.custom_minimum_size = Vector2(100, 100)
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_emblem)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 3)
	header.add_child(heading)
	_eyebrow_label = UiTheme.label(
		"镜厅余响 · 可重复挑战",
		12,
		UiTheme.C_GOLD
	)
	heading.add_child(_eyebrow_label)
	_heading_label = UiTheme.label("镜厅余响", 42, UiTheme.C_TEXT)
	heading.add_child(_heading_label)
	_description_label = UiTheme.wrapped_label(
		"晋升之后，旧宅仍在记录你的脚步。选择一条修饰，用既有收藏再次挑战镜厅男爵。",
		15,
		UiTheme.C_PAPER
	)
	heading.add_child(_description_label)
	_requirement_label = UiTheme.label("", 14, UiTheme.C_MUTED)
	_requirement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_requirement_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	var premise := UiTheme.padded_panel(
		_build_premise(),
		15,
		Color(0.055, 0.058, 0.047, 0.96),
		UiTheme.C_LINE
	)
	column.add_child(premise)
	_modifier_row = HBoxContainer.new()
	_modifier_row.add_theme_constant_override("separation", 14)
	_modifier_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_modifier_row)

	var footer := UiTheme.padded_panel(
		_build_footer(),
		14,
		Color(0.055, 0.058, 0.047, 0.97),
		UiTheme.C_GOLD
	)
	column.add_child(footer)


func _build_premise() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var icon := TextureRect.new()
	icon.texture = load(ChallengeCatalog.ICON_BASE + "deck-restricted.png")
	icon.custom_minimum_size = Vector2(58, 58)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 2)
	row.add_child(text_column)
	text_column.add_child(UiTheme.label("挑战规则", 16, UiTheme.C_TEXT))
	text_column.add_child(UiTheme.wrapped_label(
		"所有修饰只改变本次挑战。失败不会删除局外收藏、卡牌等级或已确认奖励；路线仍只在节点边界保存。",
		13,
		UiTheme.C_MUTED
	))
	_route_label = UiTheme.wrapped_label("路线：等待载入", 12, UiTheme.C_GOLD)
	text_column.add_child(_route_label)
	_reward_label = UiTheme.label("", 15, UiTheme.C_GOLD)
	_reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_reward_label)
	return row


func _build_footer() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_status_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_status_label)
	_exit_button = UiTheme.button("返回白昼档案", request_exit, true, 170)
	_start_button = UiTheme.button("开始挑战", request_start, false, 156)
	row.add_child(_exit_button)
	row.add_child(_start_button)
	return row


func _render() -> void:
	for child in _modifier_row.get_children():
		child.queue_free()
	_buttons_by_modifier.clear()
	var modifiers: Array = _snapshot_data.get("modifiers", [])
	for value in modifiers:
		if value is Dictionary:
			_modifier_row.add_child(_build_modifier(value))
	var unlocked := bool(_snapshot_data.get("unlocked", false))
	var required_sequence := int(
		_snapshot_data.get("required_sequence", 8)
	)
	var challenge_id := String(_snapshot_data.get("challenge_id", ""))
	var challenge_name := String(_snapshot_data.get(
		"display_name_zh",
		ChallengeCatalog.challenge_name(challenge_id)
	))
	if challenge_id == "challenge.v070.broken_procession":
		_eyebrow_label.text = "破碎游行 · 第二挑战"
	else:
		_eyebrow_label.text = "镜厅余响 · 可重复挑战"
	_heading_label.text = challenge_name
	_description_label.text = String(_snapshot_data.get(
		"description_zh",
		"选择一条修饰，用既有收藏再次进入镜厅。"
	))
	_emblem.texture = load(ChallengeCatalog.challenge_emblem(challenge_id))
	_route_label.text = "路线：" + ChallengeCatalog.route_name(
		String(_snapshot_data.get("route_id", ""))
	)
	var required_challenges := ChallengeCatalog.required_challenge_names(
		_snapshot_data.get("required_challenge_ids", [])
	)
	_requirement_label.text = (
		"已解锁 · 要求序列 %d" % required_sequence
		if unlocked
		else (
			"锁定 · 需先完成：%s" % required_challenges
			if not required_challenges.is_empty()
			else "锁定 · 完成序列 %d 晋升后开放" % required_sequence
		)
	)
	_requirement_label.add_theme_color_override(
		"font_color",
		UiTheme.C_GOLD if unlocked else UiTheme.C_DANGER_TEXT
	)
	_update_reward_text()
	_render_modifier_states()
	_refresh_buttons()
	if not unlocked:
		_set_status(
			"挑战尚未解锁；请先完成前置路线或晋升。",
			true
		)
	elif String(_selected_modifier_id).is_empty():
		_set_status("选择一项修饰后开始挑战。")
	else:
		_set_status("修饰已记录，可以开始挑战。")


func _build_modifier(modifier: Dictionary) -> Control:
	var modifier_id := String(modifier.get("id", ""))
	var selected := modifier_id == _selected_modifier_id
	var panel := UiTheme.panel(
		Color(0.065, 0.068, 0.055, 0.97),
		UiTheme.C_GOLD if selected else UiTheme.C_LINE
	)
	panel.custom_minimum_size = Vector2(420, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)
	var icon := TextureRect.new()
	icon.texture = load(ChallengeCatalog.modifier_icon(modifier_id))
	icon.custom_minimum_size = Vector2(108, 108)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	column.add_child(UiTheme.center_label(
		String(modifier.get("display_name_zh", modifier_id)),
		24,
		UiTheme.C_TEXT
	))
	var description := UiTheme.wrapped_label(
		String(modifier.get("description_zh", "")),
		14,
		UiTheme.C_PAPER
	)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var button := UiTheme.button(
		"已选修饰" if selected else "选用此修饰",
		func() -> void: request_modifier(modifier_id),
		true,
		0
	)
	button.set_meta("modifier_id", modifier_id)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(button)
	_buttons_by_modifier[modifier_id] = button
	return panel


func _render_modifier_states() -> void:
	for modifier_id in _buttons_by_modifier:
		var button: Button = _buttons_by_modifier[modifier_id]
		if not is_instance_valid(button):
			continue
		var selected := String(modifier_id) == _selected_modifier_id
		button.text = "已选修饰" if selected else "选用此修饰"


func _modifier_ids() -> Array[String]:
	var result: Array[String] = []
	var modifiers: Array = _snapshot_data.get("modifiers", [])
	for value in modifiers:
		if value is Dictionary:
			result.append(String(value.get("id", "")))
	return result


func _update_reward_text() -> void:
	if not is_instance_valid(_reward_label):
		return
	_reward_label.text = "完成奖励：" + ChallengeCatalog.reward_text(
		_snapshot_data.get("completion_reward", {}),
		_reward_labels
	)


func _refresh_buttons() -> void:
	var unlocked := bool(_snapshot_data.get("unlocked", false))
	for modifier_id in _buttons_by_modifier:
		var button: Button = _buttons_by_modifier[modifier_id]
		if is_instance_valid(button):
			button.disabled = _busy or not unlocked
	if is_instance_valid(_start_button):
		_start_button.disabled = not can_start()
	if is_instance_valid(_exit_button):
		_exit_button.disabled = false


func _show_empty() -> void:
	_requirement_label.text = "等待挑战档案"
	_reward_label.text = "完成奖励：等待规则载入"
	_set_status("尚未连接挑战状态。")
	_refresh_buttons()


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
