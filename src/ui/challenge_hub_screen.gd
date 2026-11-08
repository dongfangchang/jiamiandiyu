extends Control

signal challenge_selected(challenge_id: StringName)
signal exit_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const ChallengeCatalog := preload("res://src/ui/challenge_ui_catalog.gd")
const ChallengeSnapshotScript := preload("res://src/core/challenge_snapshot.gd")

var _snapshot_data: Array[Dictionary] = []
var _reward_labels: Dictionary = {}
var _cards_row: HBoxContainer
var _status_label: Label
var _buttons_by_challenge: Dictionary = {}
var _busy := false


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_render()


func apply_snapshots(snapshots: Array) -> void:
	_snapshot_data.clear()
	for value in snapshots:
		if value is ChallengeSnapshot:
			_snapshot_data.append(value.to_dictionary())
		elif value is Dictionary:
			_snapshot_data.append(value.duplicate(true))
	_busy = false
	_render()


func set_reward_labels(labels: Dictionary) -> void:
	_reward_labels = labels.duplicate(true)
	_render()


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func request_challenge(challenge_id: String) -> void:
	if _busy:
		return
	var data := _challenge_data(challenge_id)
	if data.is_empty():
		_set_status("未找到这份挑战档案。", true)
		return
	if not bool(data.get("unlocked", false)):
		_set_status(_lock_reason(data), true)
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在打开挑战档案……")
	challenge_selected.emit(StringName(challenge_id))


func request_exit() -> void:
	if _busy:
		return
	exit_requested.emit()


func get_challenge_count() -> int:
	return _snapshot_data.size()


func get_unlocked_count() -> int:
	var count := 0
	for data in _snapshot_data:
		if bool(data.get("unlocked", false)):
			count += 1
	return count


func is_challenge_enabled(challenge_id: String) -> bool:
	var button: Button = _buttons_by_challenge.get(challenge_id, null)
	return is_instance_valid(button) and not button.disabled


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_background_path() -> String:
	return ChallengeCatalog.SELECTION_BACKGROUND


func _build() -> void:
	UiTheme.add_background(
		self,
		ChallengeCatalog.SELECTION_BACKGROUND,
		UiTheme.C_BG,
		0.23
	)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 66)
	safe.add_theme_constant_override("margin_top", 42)
	safe.add_theme_constant_override("margin_right", 66)
	safe.add_theme_constant_override("margin_bottom", 38)
	add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	safe.add_child(root)
	root.add_child(UiTheme.label(
		"镜厅档案 · 挑战",
		12,
		UiTheme.C_GOLD
	))
	root.add_child(UiTheme.label("挑战档案", 42, UiTheme.C_TEXT))
	root.add_child(UiTheme.wrapped_label(
		"已完成的挑战会留下新的路线与修饰。每次出发都使用当前确认牌组；失败不会清除局外收藏。",
		15,
		UiTheme.C_MUTED
	))
	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	root.add_child(divider)
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 18)
	_cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_cards_row)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	_status_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status_label)
	footer.add_child(UiTheme.button(
		"返回白昼档案",
		request_exit,
		true,
		170
	))


func _render() -> void:
	if not is_instance_valid(_cards_row):
		return
	for child in _cards_row.get_children():
		child.queue_free()
	_buttons_by_challenge.clear()
	if _snapshot_data.is_empty():
		_cards_row.add_child(UiTheme.padded_panel(
			UiTheme.center_label("挑战档案尚未载入。", 20, UiTheme.C_MUTED),
			28,
			Color(0.055, 0.058, 0.047, 0.96),
			UiTheme.C_LINE
		))
		_refresh_buttons()
		return
	for data in _snapshot_data:
		_cards_row.add_child(_build_challenge_card(data))
	_set_status("挑战可用 %d / %d。选择一项查看路线与修饰。" % [
		get_unlocked_count(),
		get_challenge_count(),
	])
	_refresh_buttons()


func _build_challenge_card(data: Dictionary) -> Control:
	var challenge_id := String(data.get("challenge_id", ""))
	var unlocked := bool(data.get("unlocked", false))
	var panel := UiTheme.panel(
		Color(0.055, 0.059, 0.047, 0.97),
		UiTheme.C_GOLD if unlocked else UiTheme.C_LINE
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)
	var emblem := TextureRect.new()
	emblem.texture = load(ChallengeCatalog.challenge_emblem(challenge_id))
	emblem.custom_minimum_size = Vector2(116, 116)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(emblem)
	column.add_child(UiTheme.center_label(
		String(data.get("display_name_zh", ChallengeCatalog.challenge_name(challenge_id))),
		30,
		UiTheme.C_TEXT if unlocked else UiTheme.C_MUTED
	))
	column.add_child(UiTheme.label(
		"路线：" + ChallengeCatalog.route_name(
			String(data.get("route_id", ""))
		),
		13,
		UiTheme.C_GOLD if unlocked else UiTheme.C_MUTED
	))
	var description := UiTheme.wrapped_label(
		String(data.get("description_zh", "")),
		15,
		UiTheme.C_PAPER
	)
	description.custom_minimum_size = Vector2(0, 76)
	column.add_child(description)
	var modifiers: Array = data.get("modifiers", [])
	column.add_child(UiTheme.label("本次可选修饰", 12, UiTheme.C_MUTED))
	column.add_child(_build_modifier_chips(modifiers))
	column.add_child(UiTheme.label(
		"完成奖励：" + ChallengeCatalog.reward_text(
			data.get("completion_reward", {}),
			_reward_labels
		),
		13,
		UiTheme.C_GOLD
	))
	var requirement := _requirement_text(data)
	var requirement_label := UiTheme.wrapped_label(
		requirement,
		13,
		UiTheme.C_GOLD if unlocked else UiTheme.C_DANGER_TEXT
	)
	column.add_child(requirement_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var button := UiTheme.button(
		"进入挑战" if unlocked else "尚未解锁",
		func() -> void: request_challenge(challenge_id),
		unlocked,
		0
	)
	button.set_meta("challenge_id", challenge_id)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(button)
	_buttons_by_challenge[challenge_id] = button
	return panel


func _modifier_names(modifiers: Array) -> String:
	var names: Array[String] = []
	for value in modifiers:
		if value is Dictionary:
			names.append(String(value.get("display_name_zh", value.get("id", ""))))
	return " · ".join(names) if not names.is_empty() else "暂无"


func _build_modifier_chips(modifiers: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	for value in modifiers:
		if not value is Dictionary:
			continue
		var modifier: Dictionary = value
		var modifier_id := String(modifier.get("id", ""))
		var chip := UiTheme.panel(
			Color(0.066, 0.069, 0.055, 0.96),
			UiTheme.C_LINE
		)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 6)
		pad.add_theme_constant_override("margin_top", 4)
		pad.add_theme_constant_override("margin_right", 6)
		pad.add_theme_constant_override("margin_bottom", 4)
		chip.add_child(pad)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		pad.add_child(line)
		var icon := TextureRect.new()
		icon.texture = load(ChallengeCatalog.modifier_icon(modifier_id))
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		line.add_child(icon)
		var name_label := UiTheme.label(
			String(modifier.get("display_name_zh", modifier_id)),
			11,
			UiTheme.C_PAPER
		)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		row.add_child(chip)
	return row


func _requirement_text(data: Dictionary) -> String:
	if bool(data.get("unlocked", false)):
		return "已解锁 · 要求序列 %d" % int(data.get("required_sequence", 8))
	return _lock_reason(data)


func _lock_reason(data: Dictionary) -> String:
	var challenge_id := String(data.get("challenge_id", ""))
	var required := ChallengeCatalog.required_challenge_names(
		data.get("required_challenge_ids", [])
	)
	if not required.is_empty():
		return "锁定 · 需先完成：%s" % required
	return "锁定 · 完成序列 %d 晋升后开放" % int(
		data.get("required_sequence", 8)
	)


func _challenge_data(challenge_id: String) -> Dictionary:
	for data in _snapshot_data:
		if String(data.get("challenge_id", "")) == challenge_id:
			return data
	return {}


func _refresh_buttons() -> void:
	for challenge_id in _buttons_by_challenge:
		var button: Button = _buttons_by_challenge[challenge_id]
		if not is_instance_valid(button):
			continue
		var data := _challenge_data(String(challenge_id))
		button.disabled = _busy or not bool(data.get("unlocked", false))


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
