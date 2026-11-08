extends Control

signal reward_claimed(reward_id: StringName)
signal hub_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const ProgressionCommandResultScript := preload("res://src/core/progression_command_result.gd")

var _snapshot: ProgressionSnapshot
var _options_row: HBoxContainer
var _status_label: Label
var _ticket_label: Label
var _hub_button: Button
var _busy := false
var _action_buttons: Array[Button] = []


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func apply_snapshot(snapshot: ProgressionSnapshot) -> void:
	_snapshot = snapshot
	_busy = false
	var data := snapshot.to_dictionary() if snapshot != null else {}
	_ticket_label.text = "局势已归档 · 当前占卜券 %d" % int(data.get("divination_tickets", 0))
	_action_buttons.clear()
	for child in _options_row.get_children():
		_options_row.remove_child(child)
		child.queue_free()
	var options: Array = data.get("reward_options", [])
	for option_value in options:
		if option_value is Dictionary:
			_options_row.add_child(_build_reward_card(option_value, data))
	if options.is_empty():
		var empty := UiTheme.center_label(
			"当前没有可领取的战利品。",
			19,
			UiTheme.C_MUTED
		)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_options_row.add_child(empty)
	_hub_button.visible = options.is_empty()
	_hub_button.disabled = _busy or not options.is_empty()
	_set_status(
		"必须选择一份战利品；确认后会返回白昼档案。"
		if not options.is_empty()
		else "没有待领取档案。"
	)


func apply_command_result(result: ProgressionCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到奖励结果。", true)
		_refresh_buttons()
		return
	if not result.accepted:
		_set_status(ProgressionCatalog.reason_text(String(result.reason_code)), true)
		_refresh_buttons()
		return
	apply_snapshot(result.snapshot)
	_set_status("战利品已经写入本地档案。")
	_hub_button.disabled = false


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func is_pending() -> bool:
	return _busy


func claim_reward(reward_id: String) -> void:
	_request_reward(reward_id)


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_option_count() -> int:
	if not is_instance_valid(_options_row):
		return 0
	var count := 0
	for child in _options_row.get_children():
		if child.has_meta("reward_id"):
			count += 1
	return count


func get_background_path() -> String:
	return ProgressionCatalog.REWARD_BACKGROUND


func _build() -> void:
	UiTheme.add_background(self, ProgressionCatalog.REWARD_BACKGROUND, UiTheme.C_BG, 0.34)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 66)
	safe.add_theme_constant_override("margin_top", 42)
	safe.add_theme_constant_override("margin_right", 66)
	safe.add_theme_constant_override("margin_bottom", 42)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	safe.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	column.add_child(top)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	heading.add_child(UiTheme.label("战后档案 · 战利品", 12, UiTheme.C_GOLD))
	heading.add_child(UiTheme.label("挑选战利品", 36, UiTheme.C_TEXT))
	heading.add_child(UiTheme.label(
		"胜利留下两页互相矛盾的记录。只有一份能被带回去。",
		14,
		UiTheme.C_MUTED
	))
	_ticket_label = UiTheme.label("", 15, UiTheme.C_PAPER)
	_ticket_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_ticket_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	_options_row = HBoxContainer.new()
	_options_row.add_theme_constant_override("separation", 24)
	_options_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_options_row)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	column.add_child(bottom)
	_status_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status_label)
	_hub_button = UiTheme.button("返回白昼档案", _on_hub, false, 160)
	bottom.add_child(_hub_button)


func _build_reward_card(option: Dictionary, data: Dictionary) -> Control:
	var reward_id := String(option.get("id", ""))
	var kind := String(option.get("kind", ""))
	var panel := UiTheme.panel(Color(0.065, 0.068, 0.055, 0.97), UiTheme.C_GOLD)
	panel.set_meta("reward_id", reward_id)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 26)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_right", 26)
	pad.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(pad)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	pad.add_child(column)
	var icon := TextureRect.new()
	icon.texture = load(ProgressionCatalog.reward_icon(kind))
	icon.custom_minimum_size = Vector2(150, 150)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var title := UiTheme.center_label(
		String(option.get("display_name_zh", reward_id)),
		28,
		UiTheme.C_TEXT
	)
	column.add_child(title)
	column.add_child(UiTheme.center_label(
		"+%d" % int(option.get("amount", 0)),
		44,
		UiTheme.C_GOLD
	))
	var guidance: Dictionary = ProgressionCatalog.reward_guidance(kind)
	column.add_child(UiTheme.center_label(
		String(guidance.get("tag", "未知奖励")),
		14,
		UiTheme.C_GOLD
	))
	column.add_child(UiTheme.wrapped_label(
		String(guidance.get("when", "")),
		15,
		UiTheme.C_PAPER
	))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var button := UiTheme.button(
		"收下这份记录",
		func() -> void: _request_reward(reward_id),
		not _busy,
		0
	)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(button)
	_action_buttons.append(button)
	return panel


func _show_empty() -> void:
	if not is_instance_valid(_options_row):
		return
	for child in _options_row.get_children():
		child.queue_free()
	var empty := UiTheme.center_label("等待战后档案。", 19, UiTheme.C_MUTED)
	empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_row.add_child(empty)
	_set_status("当前没有待领取奖励。")


func _request_reward(reward_id: String) -> void:
	if _busy:
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在归档战利品……")
	reward_claimed.emit(StringName(reward_id))


func _on_hub() -> void:
	if _busy:
		return
	hub_requested.emit()


func _refresh_buttons() -> void:
	var has_options := get_option_count() > 0
	for button in _action_buttons:
		if is_instance_valid(button):
			button.disabled = _busy
	if is_instance_valid(_hub_button):
		_hub_button.visible = not has_options
		_hub_button.disabled = _busy or has_options


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
