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
	if _busy:
		return
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
	safe.add_theme_constant_override("margin_top", 34)
	safe.add_theme_constant_override("margin_right", 54)
	safe.add_theme_constant_override("margin_bottom", 30)
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	safe.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	header.add_child(heading)
	heading.add_child(UiTheme.label("被篡改的讣告", 12, UiTheme.C_GOLD))
	heading.add_child(UiTheme.label("被篡改的讣告", 35, UiTheme.C_TEXT))
	heading.add_child(UiTheme.label(
		"只依据界面中的证物与线索完成三步仪式。",
		14,
		UiTheme.C_MUTED
	))
	var sequence := UiTheme.label("占卜家 · 序列 9 → 8", 15, UiTheme.C_GOLD)
	sequence.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(sequence)
	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_step_panel = VBoxContainer.new()
	_step_panel.custom_minimum_size = Vector2(390, 0)
	_step_panel.add_theme_constant_override("separation", 14)
	body.add_child(UiTheme.padded_panel(
		_step_panel,
		20,
		Color(0.06, 0.063, 0.051, 0.97),
		UiTheme.C_GOLD
	))
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
	_option_grid.columns = 3
	_option_grid.add_theme_constant_override("h_separation", 10)
	_option_grid.add_theme_constant_override("v_separation", 10)
	_option_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	options_panel.add_child(_option_grid)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	options_panel.add_child(actions)
	_submit_button = UiTheme.button("提交本步骤", submit_step, false, 170)
	_hint_button = UiTheme.button("获取仪式提示", request_hint, false, 190)
	_cancel_button = UiTheme.button("退出仪式", request_cancel, false, 145)
	actions.add_child(_submit_button)
	actions.add_child(_hint_button)
	actions.add_child(_cancel_button)
	_art_rect = TextureRect.new()
	_art_rect.custom_minimum_size = Vector2(265, 0)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body.add_child(_art_rect)

	var footer := UiTheme.padded_panel(
		_build_footer(),
		13,
		Color(0.05, 0.054, 0.043, 0.97),
		UiTheme.C_LINE
	)
	column.add_child(footer)


func _build_footer() -> HBoxContainer:
	var row := HBoxContainer.new()
	_status_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_status_label)
	var risk_label := UiTheme.label("错误步骤会留下污染代价", 13, UiTheme.C_DANGER_TEXT)
	risk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(risk_label)
	return row


func _render_snapshot() -> void:
	_clear_nodes(_step_panel)
	_clear_nodes(_option_grid)
	_option_buttons.clear()
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
	_step_panel.add_child(UiTheme.label(
		String(step.get("title_zh", "仪式步骤")),
		28,
		UiTheme.C_TEXT
	))
	_step_panel.add_child(UiTheme.wrapped_label(
		String(step.get("clue_zh", "")),
		16,
		UiTheme.C_PAPER
	))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_step_panel.add_child(spacer)
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
	_set_status("选择证物，然后提交本步骤。")
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
		button.custom_minimum_size = Vector2(0, 72)
		button.add_theme_font_size_override("font_size", 17)
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
		"晋升完成" if success else "仪式中断",
		31,
		UiTheme.C_GOLD if success else UiTheme.C_DANGER_TEXT
	))
	_step_panel.add_child(UiTheme.wrapped_label(
		"晋升仪式已经完成，序列状态已归档。" if success
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
		_cancel_button.disabled = _busy or not in_progress
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
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
