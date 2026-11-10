extends Control

signal route_command_requested(command: RouteCommand)

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const RitualSnapshotScript := preload("res://src/core/ritual_snapshot.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const RouteCommandResultScript := preload("res://src/core/route_command_result.gd")

var _snapshot_data: Dictionary = {}
var _selected: Array[String] = []
var _option_grid: GridContainer
var _step_panel: VBoxContainer
var _art_rect: TextureRect
var _status_label: Label
var _submit_button: Button
var _hint_button: Button
var _cancel_button: Button
var _busy := false
var _option_buttons: Dictionary = {}
var _title_label: Label
var _kicker_label: Label
var _description_label: Label
var _source_label: Label
var _step_chips: Array[Label] = []


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func apply_snapshot(snapshot: RitualSnapshot) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_busy = false
	_selected.clear()
	_render_snapshot()


func apply_command_result(result: RouteCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到仪式结果。", true)
		_refresh_buttons()
		return
	if result.ritual_snapshot != null:
		_snapshot_data = result.ritual_snapshot.to_dictionary()
	if not result.accepted:
		_selected.clear()
		_render_snapshot()
		_set_status(RouteCatalog.reason_text(String(result.reason_code)), true)
		return
	_selected.clear()
	_render_snapshot()
	if String(_snapshot_data.get("status", "")) == "in_progress":
		var hints := String(_snapshot_data.get("hint_text", ""))
		_set_status(
			"提示：%s" % hints
			if not hints.is_empty()
			else "仪式记录已更新。"
		)


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func is_pending() -> bool:
	return _busy


func select_option(option_id: String) -> void:
	if _busy:
		return
	var step: Dictionary = _snapshot_data.get("step", {})
	if step.is_empty():
		return
	var options: Array = step.get("options", [])
	var exists := false
	for value in options:
		if value is Dictionary and String(value.get("id", "")) == option_id:
			exists = true
			break
	if not exists:
		_set_status("这项证物不在当前仪式中。", true)
		return
	var step_type := String(step.get("type", ""))
	var min_count := int(step.get("min_selections", 1))
	var max_count := int(step.get("max_selections", 1))
	if step_type == "select_id":
		_selected = [option_id]
	elif step_type == "ordered_ids":
		if option_id in _selected:
			_selected.erase(option_id)
		elif _selected.size() < max_count:
			_selected.append(option_id)
	else:
		if option_id in _selected:
			_selected.erase(option_id)
		elif _selected.size() < max_count:
			_selected.append(option_id)
		else:
			_set_status("最多选择 %d 项证物。" % max_count, true)
	_render_options(step)
	_set_status(
		"已选择 %d / %d 项。" % [_selected.size(), max_count]
		if _selected.size() < min_count
		else "证物已选齐，可以提交本步骤。"
	)


func submit_step() -> void:
	if _busy:
		return
	var step: Dictionary = _snapshot_data.get("step", {})
	var min_count := int(step.get("min_selections", 1))
	var max_count := int(step.get("max_selections", 1))
	if _selected.size() < min_count or _selected.size() > max_count:
		_set_status("当前步骤需要选择 %d—%d 项证物。" % [min_count, max_count], true)
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在核对仪式记录……")
	route_command_requested.emit(RouteCommand.submit_ritual_step(
		_selected.duplicate()
	))


func request_hint() -> void:
	if _busy:
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在从灵性中换取提示……")
	route_command_requested.emit(RouteCommand.request_ritual_hint())


func request_cancel() -> void:
	_busy = true
	_refresh_buttons()
	_set_status("正在退出仪式……")
	route_command_requested.emit(RouteCommand.cancel_ritual())


func get_selected_ids() -> Array[String]:
	return _selected.duplicate()


func get_step_title() -> String:
	var step: Dictionary = _snapshot_data.get("step", {})
	return String(step.get("title_zh", ""))


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_background_path() -> String:
	return RouteCatalog.RITUAL_BACKGROUND


func is_submit_enabled() -> bool:
	return is_instance_valid(_submit_button) and not _submit_button.disabled


func is_hint_enabled() -> bool:
	return is_instance_valid(_hint_button) and not _hint_button.disabled


func get_hint_button_text() -> String:
	return _hint_button.text if is_instance_valid(_hint_button) else ""


func _build() -> void:
	UiTheme.add_background(self, RouteCatalog.RITUAL_BACKGROUND, UiTheme.C_BG, 0.39)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 54)
	safe.add_theme_constant_override("margin_top", 30)
	safe.add_theme_constant_override("margin_right", 54)
	safe.add_theme_constant_override("margin_bottom", 26)
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	safe.add_child(column)

	# Header: fixed height, single-line clipped texts (tooltips carry the rest).
	var header := HBoxContainer.new()
	header.name = "RitualHeader"
	header.custom_minimum_size = Vector2(0, 92)
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	header.add_child(heading)
	_kicker_label = UiTheme.clip_label("仪式 · 占卜家途径", 12, UiTheme.C_GOLD)
	heading.add_child(_kicker_label)
	_title_label = UiTheme.clip_label("等待仪式", 33, UiTheme.C_TEXT)
	heading.add_child(_title_label)
	_description_label = UiTheme.clip_label("只依据界面中的线索完成三步仪式。", 14, UiTheme.C_MUTED)
	heading.add_child(_description_label)
	_source_label = UiTheme.clip_label("", 12, UiTheme.C_PAPER_DEEP)
	heading.add_child(_source_label)
	var sequence := UiTheme.label("占卜家 · 序列 9 → 8", 15, UiTheme.C_GOLD)
	sequence.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(sequence)

	# Step tracker: always three fixed-width chips.
	var tracker := HBoxContainer.new()
	tracker.name = "RitualStepTracker"
	tracker.add_theme_constant_override("separation", 8)
	column.add_child(tracker)
	_step_chips.clear()
	for index in range(3):
		var chip := UiTheme.badge("步骤 %d" % (index + 1), UiTheme.C_MUTED, UiTheme.C_LINE)
		chip.custom_minimum_size = Vector2(0, 30)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.clip_text = true
		chip.add_theme_font_size_override("font_size", 14)
		tracker.add_child(chip)
		_step_chips.append(chip)

	var body := HBoxContainer.new()
	body.name = "RitualBody"
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_step_panel = VBoxContainer.new()
	_step_panel.add_theme_constant_override("separation", 12)
	var step_scroll := UiTheme.fixed_scroll(_step_panel, 120)
	step_scroll.name = "RitualStepScroll"
	step_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var step_frame := UiTheme.padded_panel(
		step_scroll,
		18,
		Color(0.06, 0.063, 0.051, 0.97),
		UiTheme.C_GOLD
	)
	step_frame.custom_minimum_size = Vector2(410, 0)
	body.add_child(step_frame)
	var options_panel := VBoxContainer.new()
	options_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_panel.add_theme_constant_override("separation", 12)
	body.add_child(UiTheme.padded_panel(
		options_panel,
		18,
		Color(0.055, 0.059, 0.047, 0.96),
		UiTheme.C_LINE
	))
	_option_grid = GridContainer.new()
	_option_grid.columns = 1
	_option_grid.add_theme_constant_override("h_separation", 10)
	_option_grid.add_theme_constant_override("v_separation", 10)
	var option_scroll := UiTheme.fixed_scroll(_option_grid, 120)
	option_scroll.name = "RitualOptionScroll"
	option_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	options_panel.add_child(option_scroll)
	var actions := HBoxContainer.new()
	actions.name = "RitualActions"
	actions.add_theme_constant_override("separation", 10)
	options_panel.add_child(actions)
	_submit_button = UiTheme.button("提交本步骤", submit_step, false, 170)
	_hint_button = UiTheme.button("获取仪式提示", request_hint, false, 190)
	_cancel_button = UiTheme.button("退出仪式", request_cancel, false, 145)
	actions.add_child(_submit_button)
	actions.add_child(_hint_button)
	actions.add_child(_cancel_button)
	_art_rect = TextureRect.new()
	_art_rect.custom_minimum_size = Vector2(240, 0)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body.add_child(_art_rect)

	var footer := UiTheme.padded_panel(
		_build_footer(),
		12,
		Color(0.05, 0.054, 0.043, 0.97),
		UiTheme.C_LINE
	)
	footer.name = "RitualFooter"
	column.add_child(footer)


func _build_footer() -> HBoxContainer:
	var row := HBoxContainer.new()
	_status_label = UiTheme.clip_label("", 14, UiTheme.C_MUTED)
	row.add_child(_status_label)
	var risk_label := UiTheme.label("错误步骤会留下污染代价", 13, UiTheme.C_DANGER_TEXT)
	risk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(risk_label)
	return row


func _render_header() -> void:
	var title := String(_snapshot_data.get("display_name_zh", ""))
	UiTheme.set_clip_text(_title_label, title if not title.is_empty() else "等待仪式")
	UiTheme.set_clip_text(_kicker_label, "仪式 · %s" % (title if not title.is_empty() else "占卜家途径"))
	var description := String(_snapshot_data.get("description_zh", ""))
	UiTheme.set_clip_text(
		_description_label,
		description if not description.is_empty() else "只依据界面中的线索完成三步仪式。"
	)
	var source := String(_snapshot_data.get("source_zh", ""))
	UiTheme.set_clip_text(_source_label, ("原著出处：" + source) if not source.is_empty() else "")
	var titles: Array = _snapshot_data.get("step_titles", [])
	var step_index := int(_snapshot_data.get("step_index", 0))
	var status := String(_snapshot_data.get("status", "inactive"))
	for index in range(_step_chips.size()):
		var chip: Label = _step_chips[index]
		var name := String(titles[index]) if index < titles.size() else "步骤 %d" % (index + 1)
		var done := status == "completed" or index < step_index
		var current := status == "in_progress" and index == step_index
		chip.text = "%s %d · %s" % ["✓" if done else ("▶" if current else "·"), index + 1, name]
		chip.tooltip_text = chip.text
		chip.add_theme_color_override(
			"font_color",
			UiTheme.C_TEXT if current else (UiTheme.C_GOLD if done else UiTheme.C_MUTED)
		)
		chip.add_theme_stylebox_override("normal", UiTheme.style_box(
			Color("#4a3b1d") if current else UiTheme.C_SURFACE,
			UiTheme.C_GOLD if current or done else UiTheme.C_LINE,
			2 if current else 1,
			5
		))


func _render_snapshot() -> void:
	_clear_nodes(_step_panel)
	_clear_nodes(_option_grid)
	_option_buttons.clear()
	_render_header()
	var status := String(_snapshot_data.get("status", "inactive"))
	if status != "in_progress":
		_render_result(status)
		_refresh_buttons()
		return
	var step: Dictionary = _snapshot_data.get("step", {})
	if step.is_empty():
		_show_empty()
		return
	_step_panel.add_child(UiTheme.label("步骤 %d / %d" % [
		int(_snapshot_data.get("step_index", 0)) + 1,
		int(_snapshot_data.get("step_count", 3)),
	], 13, UiTheme.C_GOLD))
	_step_panel.add_child(UiTheme.wrapped_label(
		String(step.get("title_zh", "仪式步骤")),
		26,
		UiTheme.C_TEXT
	))
	_step_panel.add_child(UiTheme.wrapped_label(
		String(step.get("clue_zh", "")),
		16,
		UiTheme.C_PAPER
	))
	var lore := String(step.get("lore_zh", ""))
	if not lore.is_empty():
		_step_panel.add_child(UiTheme.wrapped_label("原著：" + lore, 13, UiTheme.C_PAPER_DEEP))
	_step_panel.add_child(UiTheme.wrapped_label(
		"污染 %d  ·  灵性 %d  ·  错误 %d  ·  提示 %d" % [
			int(_snapshot_data.get("corruption", 0)),
			int(_snapshot_data.get("spirit", 0)),
			int(_snapshot_data.get("errors", 0)),
			int(_snapshot_data.get("hints_used", 0)),
		],
		14,
		UiTheme.C_MUTED
	))
	var hint_text := String(_snapshot_data.get("hint_text", ""))
	if not hint_text.is_empty():
		_step_panel.add_child(UiTheme.wrapped_label(
			"提示：%s" % hint_text,
			14,
			UiTheme.C_GOLD
		))
	_art_rect.texture = load(RouteCatalog.ritual_step_art(
		String(step.get("type", ""))
	))
	_render_options(step)
	var step_type := String(step.get("type", ""))
	_set_status(
		"按正确顺序依次点选，然后提交本步骤。" if step_type == "ordered_ids"
		else "选择符合原著的选项，然后提交本步骤。"
	)
	_update_hint_button_text()
	_refresh_buttons()


func _render_options(step: Dictionary) -> void:
	_clear_nodes(_option_grid)
	_option_buttons.clear()
	var options: Array = step.get("options", [])
	var step_type := String(step.get("type", ""))
	for value in options:
		if not value is Dictionary:
			continue
		var option: Dictionary = value
		var option_id := String(option.get("id", ""))
		var selected_index := _selected.find(option_id)
		var label := String(option.get("display_name_zh", option_id))
		if selected_index >= 0:
			label = "%d · %s" % [selected_index + 1, label]
		var button := UiTheme.button(
			label,
			func() -> void: select_option(option_id),
			not _busy,
			0
		)
		button.custom_minimum_size = Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 17)
		button.clip_text = true
		button.tooltip_text = label
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_option_grid.add_child(button)
		_option_buttons[option_id] = button
	_refresh_buttons()


func _render_result(status: String) -> void:
	var success := status == "completed"
	var icon := TextureRect.new()
	icon.texture = load(
		RouteCatalog.ROUTE_ICON_BASE + (
			"ritual-success.png" if success else "ritual-failure.png"
		)
	)
	icon.custom_minimum_size = Vector2(112, 112)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_step_panel.add_child(icon)
	_step_panel.add_child(UiTheme.center_label(
		"仪式完成" if success else "仪式中断",
		31,
		UiTheme.C_GOLD if success else UiTheme.C_DANGER_TEXT
	))
	_step_panel.add_child(UiTheme.wrapped_label(
		"仪式已经完成，结果已归档。" if success
		else "仪式失败，路线已经中断；已获得的局外收藏仍会保留。",
		16,
		UiTheme.C_PAPER
	))
	_art_rect.texture = load(
		RouteCatalog.ROUTE_ICON_BASE + (
			"ritual-success.png" if success else "ritual-failure.png"
		)
	)
	_set_status("晋升结果已归档。" if success else "仪式失败。", not success)


func _refresh_buttons() -> void:
	var step: Dictionary = _snapshot_data.get("step", {})
	var min_count := int(step.get("min_selections", 1))
	var max_count := int(step.get("max_selections", 1))
	var in_progress := String(_snapshot_data.get("status", "")) == "in_progress"
	if is_instance_valid(_submit_button):
		_submit_button.disabled = (
			_busy
			or not in_progress
			or _selected.size() < min_count
			or _selected.size() > max_count
		)
	if is_instance_valid(_hint_button):
		var hinted: Array = _snapshot_data.get("hinted_step_indices", [])
		var step_index := int(_snapshot_data.get("step_index", 0))
		_hint_button.disabled = (
			_busy
			or not in_progress
			or step_index in hinted
		)
	if is_instance_valid(_cancel_button):
		_cancel_button.disabled = not in_progress
	for button_value in _option_buttons.values():
		var button: Button = button_value
		if is_instance_valid(button):
			button.disabled = _busy or not in_progress


func _update_hint_button_text() -> void:
	if not is_instance_valid(_hint_button):
		return
	var cost := maxi(0, int(_snapshot_data.get("hint_spirit_cost", 0)))
	_hint_button.text = (
		"获取仪式提示（%d 灵性）" % cost
		if cost > 0
		else "获取仪式提示"
	)


func _show_empty() -> void:
	if not is_instance_valid(_step_panel):
		return
	_clear_nodes(_step_panel)
	_clear_nodes(_option_grid)
	_step_panel.add_child(UiTheme.center_label("等待晋升仪式。", 22, UiTheme.C_MUTED))
	_set_status("尚未连接仪式状态。")
	_update_hint_button_text()
	_refresh_buttons()


func _clear_nodes(parent: Node) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	UiTheme.set_clip_text(_status_label, message)
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
