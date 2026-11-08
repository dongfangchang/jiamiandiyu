extends Control

signal deck_command_requested(command: DeckCommand)
signal back_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")
const DeckSnapshotScript := preload("res://src/core/deck_snapshot.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const DeckCommandResultScript := preload("res://src/core/deck_command_result.gd")

var _snapshot_data: Dictionary = {}
var _levels: Dictionary = {}
var _filter_mode := "all"
var _busy := false
var _last_command_type: StringName = &""

var _deck_count_label: Label
var _deck_state_label: Label
var _status_label: Label
var _preset_row: HBoxContainer
var _content_scroll: ScrollContainer
var _scroll_hint_label: Label
var _collection_grid: GridContainer
var _deck_list: VBoxContainer
var _filter_option: OptionButton
var _confirm_button: Button
var _back_button: Button
var _reset_button: Button
var _clear_button: Button
var _action_buttons: Array[Button] = []


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()
	call_deferred("_refresh_scroll_hint")


func apply_snapshot(snapshot: DeckSnapshot) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_busy = false
	_render()
	call_deferred("_refresh_scroll_hint")


func apply_command_result(result: DeckCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到牌组结果。", true)
		_refresh_buttons()
		return
	if not result.accepted:
		_last_command_type = &""
		_set_status(DeckCatalog.reason_text(String(result.reason_code)), true)
		_refresh_buttons()
		return
	if result.snapshot != null:
		_snapshot_data = result.snapshot.to_dictionary()
	_render()
	call_deferred("_refresh_scroll_hint")
	if _last_command_type == DeckCommand.SELECT_PRESET:
		var selected_name := _selected_preset_name()
		var readiness := _selected_preset_readiness()
		_set_status(
			"已载入「%s」。%s" % [selected_name, readiness],
			not bool(_snapshot_data.get("legal", false))
		)
	else:
		_set_status("牌组档案已更新。")
	_last_command_type = &""


func set_progression_snapshot(snapshot: ProgressionSnapshot) -> void:
	_levels.clear()
	var data := snapshot.to_dictionary() if snapshot != null else {}
	for value in data.get("collection", []):
		if value is Dictionary:
			_levels[String(value.get("definition_id", ""))] = int(
				value.get("level", 0)
			)
	if not _snapshot_data.is_empty():
		_render()


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func is_pending() -> bool:
	return _busy


func set_filter(mode: String) -> void:
	if mode not in ["all", "owned", "unowned", "deck"]:
		return
	_filter_mode = mode
	if is_instance_valid(_filter_option):
		_filter_option.select(
			["all", "owned", "unowned", "deck"].find(_filter_mode)
		)
	if not _snapshot_data.is_empty():
		_render_collection()


func request_add_card(definition_id: String) -> void:
	_request(DeckCommand.add_card(StringName(definition_id)))


func request_remove_card(definition_id: String) -> void:
	_request(DeckCommand.remove_card(StringName(definition_id)))


func request_select_preset(preset_id: String) -> void:
	_request(DeckCommand.select_preset(StringName(preset_id)))


func request_save_preset(preset_id: String) -> void:
	_request(DeckCommand.save_preset(StringName(preset_id)))


func request_clear_deck() -> void:
	_request(DeckCommand.clear_deck())


func request_reset_default() -> void:
	_request(DeckCommand.reset_default())


func request_confirm_deck() -> void:
	if _busy or not bool(_snapshot_data.get("legal", false)):
		return
	_request(DeckCommand.confirm_deck())


func request_back() -> void:
	back_requested.emit()


func get_current_deck_count() -> int:
	return int(_snapshot_data.get("current_deck_size", 0))


func get_required_deck_size() -> int:
	return int(_snapshot_data.get("required_deck_size", 0))


func get_card_count() -> int:
	return _visible_cards().size()


func get_total_card_count() -> int:
	return _card_views().size()


func get_preset_count() -> int:
	var presets: Array = _snapshot_data.get("presets", [])
	return presets.size()


func get_selected_preset_id() -> String:
	return String(_snapshot_data.get("selected_preset_id", ""))


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_scroll_hint_text() -> String:
	return _scroll_hint_label.text if is_instance_valid(_scroll_hint_label) else ""


func get_deck_state_text() -> String:
	return _deck_state_label.text if is_instance_valid(_deck_state_label) else ""


func get_background_path() -> String:
	return DeckCatalog.BACKGROUND


func is_confirm_enabled() -> bool:
	return (
		is_instance_valid(_confirm_button)
		and not _confirm_button.disabled
		and not _busy
	)


func get_visible_card_ids() -> Array[String]:
	var result: Array[String] = []
	for card in _visible_cards():
		result.append(String(card.get("definition_id", "")))
	return result


func _build() -> void:
	UiTheme.add_background(self, DeckCatalog.BACKGROUND, UiTheme.C_BG, 0.18)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 42)
	safe.add_theme_constant_override("margin_top", 24)
	safe.add_theme_constant_override("margin_right", 42)
	safe.add_theme_constant_override("margin_bottom", 24)
	add_child(safe)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	safe.add_child(root)
	root.add_child(_build_header())
	_preset_row = HBoxContainer.new()
	_preset_row.add_theme_constant_override("separation", 10)
	root.add_child(_preset_row)
	_scroll_hint_label = UiTheme.label("", 12, UiTheme.C_GOLD)
	_scroll_hint_label.visible = false
	root.add_child(_scroll_hint_label)

	_content_scroll = ScrollContainer.new()
	_content_scroll.name = "ContentScroll"
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_content_scroll)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_content_scroll.add_child(content)

	var collection_panel := UiTheme.panel(
		Color(0.055, 0.058, 0.047, 0.97),
		UiTheme.C_LINE
	)
	collection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(collection_panel)
	var collection_pad := MarginContainer.new()
	collection_pad.add_theme_constant_override("margin_left", 12)
	collection_pad.add_theme_constant_override("margin_top", 10)
	collection_pad.add_theme_constant_override("margin_right", 12)
	collection_pad.add_theme_constant_override("margin_bottom", 10)
	collection_panel.add_child(collection_pad)
	var collection_column := VBoxContainer.new()
	collection_column.add_theme_constant_override("separation", 8)
	collection_pad.add_child(collection_column)
	collection_column.add_child(UiTheme.label("收藏档案", 18, UiTheme.C_TEXT))
	_collection_grid = GridContainer.new()
	_collection_grid.columns = 4
	_collection_grid.add_theme_constant_override("h_separation", 8)
	_collection_grid.add_theme_constant_override("v_separation", 8)
	_collection_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collection_column.add_child(_collection_grid)

	var deck_panel := UiTheme.panel(
		Color(0.055, 0.058, 0.047, 0.97),
		UiTheme.C_GOLD
	)
	deck_panel.custom_minimum_size = Vector2(430, 0)
	deck_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(deck_panel)
	var deck_pad := MarginContainer.new()
	deck_pad.add_theme_constant_override("margin_left", 14)
	deck_pad.add_theme_constant_override("margin_top", 10)
	deck_pad.add_theme_constant_override("margin_right", 14)
	deck_pad.add_theme_constant_override("margin_bottom", 10)
	deck_panel.add_child(deck_pad)
	var deck_column := VBoxContainer.new()
	deck_column.add_theme_constant_override("separation", 8)
	deck_pad.add_child(deck_column)
	deck_column.add_child(UiTheme.label("当前出战牌组", 18, UiTheme.C_TEXT))
	_deck_count_label = UiTheme.label("0 / 8", 26, UiTheme.C_GOLD)
	deck_column.add_child(_deck_count_label)
	_deck_state_label = UiTheme.wrapped_label("", 13, UiTheme.C_PAPER)
	deck_column.add_child(_deck_state_label)
	_deck_list = VBoxContainer.new()
	_deck_list.add_theme_constant_override("separation", 5)
	_deck_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_column.add_child(_deck_list)

	root.add_child(_build_footer())


func _build_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	header.add_child(heading)
	heading.add_child(UiTheme.label(
		"封印物档案 · 出战牌组",
		12,
		UiTheme.C_GOLD
	))
	heading.add_child(UiTheme.label("出战牌组", 34, UiTheme.C_TEXT))
	heading.add_child(UiTheme.wrapped_label(
		"从已收容的回响中选择 8 张唯一卡牌。抽卡与升级从下一次战斗开始生效。",
		14,
		UiTheme.C_MUTED
	))
	_filter_option = OptionButton.new()
	_filter_option.custom_minimum_size = Vector2(180, 42)
	_filter_option.add_item("全部回响")
	_filter_option.add_item("仅已拥有")
	_filter_option.add_item("未拥有")
	_filter_option.add_item("当前牌组")
	_filter_option.item_selected.connect(func(index: int) -> void:
		set_filter(["all", "owned", "unowned", "deck"][index])
	)
	_filter_option.disabled = _busy
	header.add_child(_filter_option)
	return header


func _build_footer() -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	_status_label = UiTheme.wrapped_label("", 13, UiTheme.C_MUTED)
	_status_label.custom_minimum_size = Vector2(0, 34)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status_label)
	_clear_button = UiTheme.button("清空", request_clear_deck, true, 86)
	_reset_button = UiTheme.button("恢复初始", request_reset_default, true, 118)
	_back_button = UiTheme.button("返回身份档案", request_back, true, 156)
	_confirm_button = UiTheme.button("确认出战", request_confirm_deck, false, 140)
	for button in [_clear_button, _reset_button, _back_button, _confirm_button]:
		footer.add_child(button)
		_action_buttons.append(button)
	return footer


func _render() -> void:
	_action_buttons = []
	var base_buttons: Array[Button] = [
		_clear_button,
		_reset_button,
		_back_button,
		_confirm_button,
	]
	for button in base_buttons:
		if is_instance_valid(button):
			_action_buttons.append(button)
	_render_presets()
	_render_collection()
	_render_deck()
	_deck_count_label.text = "%d / %d" % [
		get_current_deck_count(),
		get_required_deck_size(),
	]
	var legal := bool(_snapshot_data.get("legal", false))
	var reason := DeckCatalog.reason_text(
		String(_snapshot_data.get("reason_code", ""))
	)
	_deck_state_label.text = (
		"已确认 · " + reason
		if bool(_snapshot_data.get("confirmed", false))
		else reason
	)
	_deck_state_label.add_theme_color_override(
		"font_color",
		UiTheme.C_GOLD if legal else UiTheme.C_DANGER_TEXT
	)
	if bool(_snapshot_data.get("confirmed", false)):
		_set_status("这套牌组已确认，将用于下一次路线或挑战。")
	else:
		_set_status(
			"牌组合法；确认后用于下一次出战。"
			if legal
			else reason,
			not legal
		)
	_refresh_buttons()


func _render_presets() -> void:
	for child in _preset_row.get_children():
		child.queue_free()
	for value in _snapshot_data.get("presets", []):
		if value is Dictionary:
			_preset_row.add_child(_build_preset(value))


func _build_preset(preset: Dictionary) -> Control:
	var preset_id := String(preset.get("id", ""))
	var selected := bool(preset.get("selected", false))
	var panel := UiTheme.panel(
		Color(0.06, 0.063, 0.051, 0.97),
		UiTheme.C_GOLD if selected else UiTheme.C_LINE
	)
	panel.custom_minimum_size = Vector2(338, 112)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(pad)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pad.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 1)
	row.add_child(text)
	text.add_child(UiTheme.label(
		String(preset.get("display_name_zh", preset_id)),
		16,
		UiTheme.C_GOLD if selected else UiTheme.C_TEXT
	))
	var guidance: Dictionary = DeckCatalog.preset_guidance(preset_id)
	text.add_child(UiTheme.label(
		String(guidance.get("tag", "")),
		12,
		UiTheme.C_GOLD if selected else UiTheme.C_PAPER
	))
	text.add_child(UiTheme.label(
		_preset_cost_summary(preset),
		11,
		UiTheme.C_PAPER
	))
	text.add_child(UiTheme.wrapped_label(
		String(guidance.get("when", preset.get("description_zh", ""))),
		11,
		UiTheme.C_MUTED
	))
	text.add_child(UiTheme.label(
		"可直接确认出战"
			if bool(preset.get("legal", false))
			else "载入后需补齐收藏卡或换回可用预设",
		10,
		UiTheme.C_GOLD if bool(preset.get("legal", false)) else UiTheme.C_DANGER_TEXT
	))
	var load_button := UiTheme.button(
		"已载入" if selected else "载入此组",
		func() -> void: request_select_preset(preset_id),
		true,
		88
	)
	load_button.set_meta("preset_id", preset_id)
	row.add_child(load_button)
	_action_buttons.append(load_button)
	var save_button := UiTheme.button(
		"覆盖",
		func() -> void: request_save_preset(preset_id),
		true,
		72
	)
	save_button.set_meta("preset_id", preset_id)
	row.add_child(save_button)
	_action_buttons.append(save_button)
	return panel


func _preset_cost_summary(preset: Dictionary) -> String:
	var ids: Variant = preset.get("card_definition_ids", [])
	var cards: Variant = _snapshot_data.get("cards", [])
	if not ids is Array or not cards is Array:
		return "费用摘要：等待卡牌数据"
	var costs: Array[int] = []
	for raw_id in ids:
		var found := false
		for card_value in cards:
			if card_value is Dictionary and String(card_value.get("definition_id", "")) == String(raw_id):
				costs.append(int(card_value.get("cost_spirit", 0)))
				found = true
				break
		if not found:
			return "费用摘要：卡牌数据不完整"
	if costs.is_empty():
		return "费用摘要：暂无卡牌"
	var total := 0
	var highest := 0
	for cost in costs:
		total += cost
		highest = maxi(highest, cost)
	return "费用 %.2f · 最高 %d · %d 张" % [float(total) / float(costs.size()), highest, costs.size()]


func _render_collection() -> void:
	for child in _collection_grid.get_children():
		child.queue_free()
	for card in _visible_cards():
		_collection_grid.add_child(_build_card_tile(card))


func _build_card_tile(card: Dictionary) -> Control:
	var definition_id := String(card.get("definition_id", ""))
	var owned := bool(card.get("owned", false))
	var in_deck := bool(card.get("in_deck", false))
	var panel := UiTheme.panel(
		Color(0.06, 0.063, 0.051, 0.97),
		UiTheme.C_GOLD if in_deck else UiTheme.C_LINE
	)
	panel.custom_minimum_size = Vector2(245, 112)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 7)
	pad.add_theme_constant_override("margin_top", 7)
	pad.add_theme_constant_override("margin_right", 7)
	pad.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(pad)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pad.add_child(row)
	var art := TextureRect.new()
	art.texture = load(DeckCatalog.card_art(definition_id))
	art.custom_minimum_size = Vector2(108, 72)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(art)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	info.add_child(UiTheme.label(
		String(card.get("display_name_zh", definition_id)),
		16,
		UiTheme.C_TEXT if owned else UiTheme.C_MUTED
	))
	info.add_child(UiTheme.label(
		"等级 %d  ·  灵性 %d" % [
			int(_levels.get(definition_id, 0)),
			int(card.get("cost_spirit", 0)),
		],
		11,
		UiTheme.C_GOLD if owned else UiTheme.C_MUTED
	))
	info.add_child(UiTheme.label(
		"目标：" + DeckCatalog.target_text(
			String(card.get("target_type", ""))
		),
		11,
		UiTheme.C_MUTED
	))
	info.add_child(UiTheme.badge(
		"已拥有 · 可加入" if owned else "未拥有 · 仅可查看",
		UiTheme.C_GOLD if owned else UiTheme.C_MUTED,
		UiTheme.C_GOLD if owned else UiTheme.C_LINE
	))
	var button := UiTheme.button(
		"移出牌组" if in_deck else ("加入牌组" if owned else "尚未拥有"),
		func() -> void:
			if in_deck:
				request_remove_card(definition_id)
			else:
				request_add_card(definition_id),
		owned,
		72
	)
	button.set_meta("definition_id", definition_id)
	info.add_child(button)
	_action_buttons.append(button)
	panel.tooltip_text = String(card.get("description_zh", ""))
	return panel


func _render_deck() -> void:
	for child in _deck_list.get_children():
		child.queue_free()
	var current_ids: Array = _snapshot_data.get("current_card_ids", [])
	var cards_by_id := {}
	for card in _card_views():
		cards_by_id[String(card.get("definition_id", ""))] = card
	for index in range(maxi(int(_snapshot_data.get("required_deck_size", 8)), current_ids.size())):
		if index < current_ids.size():
			var definition_id := String(current_ids[index])
			_deck_list.add_child(_build_deck_row(
				index + 1,
				cards_by_id.get(definition_id, {"definition_id": definition_id}),
				true
			))
		else:
			_deck_list.add_child(_build_deck_row(index + 1, {}, false))


func _build_deck_row(index: int, card: Dictionary, filled: bool) -> Control:
	var row := UiTheme.panel(
		Color(0.065, 0.068, 0.055, 0.94),
		UiTheme.C_GOLD if filled else UiTheme.C_LINE
	)
	row.custom_minimum_size = Vector2(0, 47)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_top", 5)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_bottom", 5)
	row.add_child(pad)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	pad.add_child(line)
	line.add_child(UiTheme.label("%02d" % index, 12, UiTheme.C_MUTED))
	var definition_id := String(card.get("definition_id", ""))
	var name_label := UiTheme.label(
		String(card.get("display_name_zh", "空置牌位" if not filled else definition_id)),
		14,
		UiTheme.C_TEXT if filled else UiTheme.C_MUTED
	)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	if filled:
		line.add_child(UiTheme.label(
			"等级 %d" % int(_levels.get(definition_id, 0)),
			11,
			UiTheme.C_GOLD
		))
		var remove := UiTheme.button(
			"移出",
			func() -> void: request_remove_card(definition_id),
			true,
			62
		)
		remove.set_meta("definition_id", definition_id)
		line.add_child(remove)
		_action_buttons.append(remove)
	return row


func _visible_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in _card_views():
		var owned := bool(card.get("owned", false))
		var in_deck := bool(card.get("in_deck", false))
		match _filter_mode:
			"owned":
				if owned:
					result.append(card)
			"unowned":
				if not owned:
					result.append(card)
			"deck":
				if in_deck:
					result.append(card)
			_:
				result.append(card)
	return result


func _card_views() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in _snapshot_data.get("cards", []):
		if value is Dictionary:
			result.append(value)
	return result


func _request(command: DeckCommand) -> void:
	if _busy or command == null:
		return
	_busy = true
	_last_command_type = command.type
	_refresh_buttons()
	_set_status(
		"正在载入牌组「%s」……" % DeckCatalog.preset_name(String(command.preset_id))
		if command.type == DeckCommand.SELECT_PRESET
		else "正在更新牌组档案……"
	)
	deck_command_requested.emit(command)


func _refresh_buttons() -> void:
	var legal := bool(_snapshot_data.get("legal", false))
	for button in _action_buttons:
		if not is_instance_valid(button):
			continue
		if button == _back_button or button == _reset_button or button == _clear_button:
			button.disabled = false if button == _back_button else _busy
		elif button == _confirm_button:
			button.disabled = _busy or not legal
		else:
			button.disabled = _busy
	if is_instance_valid(_filter_option):
		_filter_option.disabled = _busy


func _show_empty() -> void:
	_deck_count_label.text = "0 / 8"
	_deck_state_label.text = "等待牌组档案"
	_set_status("尚未连接牌组状态。")
	_refresh_buttons()


func _refresh_scroll_hint() -> void:
	if not is_instance_valid(_content_scroll) or not is_instance_valid(_scroll_hint_label):
		return
	var vertical_bar := _content_scroll.get_v_scroll_bar()
	var overflow := vertical_bar.max_value > vertical_bar.page + 1.0
	_scroll_hint_label.visible = overflow
	_scroll_hint_label.text = "内容超出当前窗口 · 向下滚动查看卡牌与出战操作" if overflow else ""


func _selected_preset_name() -> String:
	var selected_id := String(_snapshot_data.get("selected_preset_id", ""))
	if selected_id.is_empty():
		return "自定义牌组"
	return DeckCatalog.preset_name(selected_id)


func _selected_preset_readiness() -> String:
	var reason := DeckCatalog.reason_text(String(_snapshot_data.get("reason_code", "")))
	if bool(_snapshot_data.get("legal", false)):
		return "这套牌组已满足 8 张唯一卡牌要求，可以确认出战。"
	if reason.is_empty():
		return "当前牌组还不能确认出战。"
	return "当前牌组暂不能确认出战：%s" % reason


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
