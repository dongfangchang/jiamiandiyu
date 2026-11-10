extends Control

signal identity_selected(identity_id: StringName)
signal battle_requested
signal gacha_requested
signal upgrade_requested
signal deck_requested
signal main_menu_requested
signal restart_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const ProgressionCommandResultScript := preload("res://src/core/progression_command_result.gd")
const DeckSnapshotScript := preload("res://src/core/deck_snapshot.gd")

var _snapshot: ProgressionSnapshot
var _mode_container: VBoxContainer
var _status_label: Label
var _resource_label: Label
var _busy := false
var _identity_id := ""
var _action_buttons: Array[Button] = []
var _has_hub_actions := false
var _deck_data: Dictionary = {}
var _deck_summary_label: Label
var _deck_button: Button
var _main_menu_button: Button
var _restart_button: Button


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func apply_snapshot(snapshot: ProgressionSnapshot) -> void:
	_snapshot = snapshot
	_busy = false
	var data := snapshot.to_dictionary() if snapshot != null else {}
	_identity_id = String(data.get("identity_id", ""))
	_action_buttons.clear()
	_has_hub_actions = false
	_clear_mode()
	match String(data.get("phase", "")):
		"identity_selection":
			_show_identity_options(data)
			_set_status("选择一份白昼身份，决定第一场行动的资源倾向。")
		"hub":
			_show_hub(data)
			_set_status("身份已记录。选择下一次行动。")
		"reward":
			_show_waiting("战后奖励正在等待归档。返回奖励页完成选择。")
		_:
			_show_waiting("成长档案尚未准备好。")
	_update_resources(data)


func apply_command_result(result: ProgressionCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到成长结果。", true)
		_refresh_action_buttons()
		return
	if not result.accepted:
		_set_status(ProgressionCatalog.reason_text(String(result.reason_code)), true)
		_refresh_action_buttons()
		return
	_set_status("档案已更新。")
	apply_snapshot(result.snapshot)


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_action_buttons()


func is_pending() -> bool:
	return _busy


func choose_identity(identity_id: String) -> void:
	_request_identity(identity_id)


func set_deck_snapshot(snapshot: DeckSnapshot) -> void:
	_deck_data = snapshot.to_dictionary() if snapshot != null else {}
	_update_deck_summary()


func has_deck_action() -> bool:
	return is_instance_valid(_deck_button)


func get_deck_summary_text() -> String:
	return (
		_deck_summary_label.text
		if is_instance_valid(_deck_summary_label)
		else ""
	)


func has_hub_actions() -> bool:
	return _has_hub_actions


func has_main_menu_action() -> bool:
	return is_instance_valid(_main_menu_button)


func has_restart_action() -> bool:
	return is_instance_valid(_restart_button)


func get_selected_identity_id() -> String:
	return _identity_id


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_background_path() -> String:
	return ProgressionCatalog.IDENTITY_BACKGROUND


func _build() -> void:
	UiTheme.add_background(self, ProgressionCatalog.IDENTITY_BACKGROUND, UiTheme.C_BG, 0.26)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 64)
	safe.add_theme_constant_override("margin_top", 42)
	safe.add_theme_constant_override("margin_right", 64)
	safe.add_theme_constant_override("margin_bottom", 38)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	safe.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	column.add_child(header)
	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation", 3)
	header.add_child(title_column)
	title_column.add_child(UiTheme.label("白昼档案 · 人格", 12, UiTheme.C_GOLD))
	title_column.add_child(UiTheme.label("白昼身份", 34, UiTheme.C_TEXT))
	title_column.add_child(UiTheme.label(
		"选择一种被人相信的生活，让夜晚的力量拥有代价。",
		14,
		UiTheme.C_MUTED
	))
	_resource_label = UiTheme.label("占卜券 0 · 已收容 0 张", 15, UiTheme.C_PAPER)
	_resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_resource_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	_mode_container = VBoxContainer.new()
	_mode_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mode_container.add_theme_constant_override("separation", 14)
	column.add_child(_mode_container)

	_status_label = UiTheme.clip_label("", 14, UiTheme.C_MUTED)
	_status_label.custom_minimum_size = Vector2(0, 38)
	column.add_child(_status_label)


func _show_identity_options(data: Dictionary) -> void:
	var options: Array = data.get("identity_options", [])
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mode_container.add_child(grid)
	for option_value in options:
		if not option_value is Dictionary:
			continue
		var option: Dictionary = option_value
		grid.add_child(_build_identity_card(option))


func _build_identity_card(option: Dictionary) -> Control:
	var identity_id := String(option.get("id", ""))
	var panel := UiTheme.panel(Color(0.07, 0.072, 0.058, 0.95), UiTheme.C_LINE)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(pad)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	pad.add_child(column)
	var art := TextureRect.new()
	art.texture = load(ProgressionCatalog.identity_art(identity_id))
	art.custom_minimum_size = Vector2(0, 318)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	column.add_child(art)
	column.add_child(UiTheme.label(
		String(option.get("display_name_zh", identity_id)),
		25,
		UiTheme.C_TEXT
	))
	var description := UiTheme.wrapped_label(
		String(option.get("description_zh", "")),
		14,
		UiTheme.C_PAPER
	)
	description.custom_minimum_size = Vector2(0, 56)
	column.add_child(description)
	column.add_child(UiTheme.label(
		ProgressionCatalog.modifier_text(option.get("battle_modifiers", {})),
		13,
		UiTheme.C_GOLD
	))
	var passive_text := String(option.get("passive_text_zh", ""))
	if not passive_text.is_empty():
		column.add_child(UiTheme.wrapped_label(
			"身份特性：%s" % passive_text,
			13,
			UiTheme.C_PAPER_DEEP
		))
	var button := UiTheme.button(
		"扮演此身份",
		func() -> void: _request_identity(identity_id),
		not _busy,
		0
	)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(button)
	_action_buttons.append(button)
	return panel


func _show_hub(data: Dictionary) -> void:
	_has_hub_actions = true
	var selected: Dictionary = {}
	for option_value in data.get("identity_options", []):
		if option_value is Dictionary and bool(option_value.get("selected", false)):
			selected = option_value
			break
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mode_container.add_child(row)

	var portrait_panel := UiTheme.panel(Color(0.06, 0.065, 0.052, 0.96), UiTheme.C_GOLD)
	portrait_panel.custom_minimum_size = Vector2(360, 0)
	row.add_child(portrait_panel)
	var art := TextureRect.new()
	art.texture = load(ProgressionCatalog.identity_art(_identity_id))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_panel.add_child(art)

	var actions_panel := UiTheme.padded_panel(
		_build_hub_actions(data, selected),
		22,
		Color(0.07, 0.072, 0.058, 0.96),
		UiTheme.C_LINE
	)
	actions_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(actions_panel)


func _build_hub_actions(data: Dictionary, selected: Dictionary) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.add_child(UiTheme.label("当前伪装", 13, UiTheme.C_GOLD))
	content.add_child(UiTheme.label(
		String(selected.get("display_name_zh", "未知身份")),
		34,
		UiTheme.C_TEXT
	))
	content.add_child(UiTheme.wrapped_label(
		String(selected.get("description_zh", "")),
		15,
		UiTheme.C_PAPER
	))
	content.add_child(UiTheme.label(
		ProgressionCatalog.modifier_text(selected.get("battle_modifiers", {})),
		14,
		UiTheme.C_GOLD
	))
	var passive_text := String(selected.get("passive_text_zh", ""))
	if not passive_text.is_empty():
		content.add_child(UiTheme.wrapped_label(
			"身份特性：%s" % passive_text,
			14,
			UiTheme.C_PAPER
		))
	var owned := 0
	for card_value in data.get("collection", []):
		if card_value is Dictionary and int(card_value.get("copies", 0)) > 0:
			owned += 1
	content.add_child(UiTheme.wrapped_label(
		"占卜券 %d  ·  已收容 %d 张  ·  稀有保底 %d / %d\n上一场：%s" % [
			int(data.get("divination_tickets", 0)),
			owned,
			int(data.get("pity_counter", 0)),
			int(data.get("rare_pity", 0)),
			_last_outcome_text(String(data.get("last_battle_outcome", ""))),
		],
		15,
		UiTheme.C_MUTED
	))
	_deck_summary_label = UiTheme.clip_label("", 14, UiTheme.C_GOLD)
	content.add_child(_deck_summary_label)
	_deck_button = UiTheme.button(
		"调整出战牌组",
		_on_deck,
		true,
		0
	)
	_deck_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_deck_button)
	_action_buttons.append(_deck_button)
	_update_deck_summary()
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var battle_button := UiTheme.button("进入夜间战斗", _on_battle, true, 0)
	var gacha_button := UiTheme.button("进行灵界祈愿", _on_gacha, true, 0)
	var upgrade_button := UiTheme.button("整理卡牌与残页", _on_upgrade, true, 0)
	_main_menu_button = UiTheme.button("回到主菜单", _on_main_menu, false, 0)
	_restart_button = UiTheme.button("重新开始", _on_restart, false, 0)
	var menu_button := _main_menu_button
	var restart_button := _restart_button
	for button in [battle_button, gacha_button, upgrade_button, menu_button, restart_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(button)
		_action_buttons.append(button)
	_refresh_action_buttons()
	return content


func _show_waiting(message: String) -> void:
	var panel := UiTheme.padded_panel(
		UiTheme.center_label(message, 20, UiTheme.C_PAPER),
		42,
		Color(0.06, 0.065, 0.052, 0.96),
		UiTheme.C_LINE
	)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mode_container.add_child(panel)


func _show_empty() -> void:
	_clear_mode()
	_show_waiting("等待本地成长档案。")
	_set_status("尚未连接成长状态。")


func _clear_mode() -> void:
	if not is_instance_valid(_mode_container):
		return
	for child in _mode_container.get_children():
		child.queue_free()


func _update_resources(data: Dictionary) -> void:
	if not is_instance_valid(_resource_label):
		return
	var owned := 0
	for card_value in data.get("collection", []):
		if card_value is Dictionary and int(card_value.get("copies", 0)) > 0:
			owned += 1
	_resource_label.text = "占卜券 %d  ·  已收容 %d 张" % [
		int(data.get("divination_tickets", 0)),
		owned,
	]


func _request_identity(identity_id: String) -> void:
	if _busy:
		return
	_busy = true
	_identity_id = identity_id
	_refresh_action_buttons()
	_set_status("正在记录身份……")
	identity_selected.emit(StringName(identity_id))


func _on_battle() -> void:
	if _busy:
		return
	battle_requested.emit()


func _on_gacha() -> void:
	if _busy:
		return
	gacha_requested.emit()


func _on_upgrade() -> void:
	if _busy:
		return
	upgrade_requested.emit()


func _on_main_menu() -> void:
	if _busy:
		return
	main_menu_requested.emit()


func _on_restart() -> void:
	if _busy:
		return
	restart_requested.emit()


func _on_deck() -> void:
	if _busy:
		return
	deck_requested.emit()


func _update_deck_summary() -> void:
	if not is_instance_valid(_deck_summary_label):
		return
	var current := int(_deck_data.get("current_deck_size", 0))
	var required := int(_deck_data.get("required_deck_size", 8))
	var preset_id := String(_deck_data.get("selected_preset_id", ""))
	var legal := bool(_deck_data.get("legal", false))
	var confirmed := bool(_deck_data.get("confirmed", false))
	var preset_name := String(DeckCatalog.PRESET_NAMES.get(preset_id, ""))
	if preset_name.is_empty():
		preset_name = "自定义牌组"
	_deck_summary_label.text = "出战牌组：%s · %d / %d%s%s" % [
		preset_name,
		current,
		required,
		" · 合法" if legal else " · 尚未合法",
		" · 已确认" if confirmed else "",
	]


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	UiTheme.set_clip_text(_status_label, message)
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)


func _refresh_action_buttons() -> void:
	for button in _action_buttons:
		if is_instance_valid(button):
			button.disabled = _busy


func _last_outcome_text(outcome: String) -> String:
	match outcome:
		"victory":
			return "胜利"
		"defeat":
			return "失败"
		_:
			return "尚未战斗"
