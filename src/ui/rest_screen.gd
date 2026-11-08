extends Control

signal route_command_requested(command: RouteCommand)

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const RouteCommandResultScript := preload("res://src/core/route_command_result.gd")

var _snapshot_data: Dictionary = {}
var _options_row: HBoxContainer
var _status_label: Label
var _resource_label: Label
var _buttons_by_rest: Dictionary = {}
var _busy := false


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func apply_snapshot(snapshot: RouteSnapshot) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_busy = false
	_render_options()


func apply_command_result(result: RouteCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到休息结果。", true)
		_refresh_buttons()
		return
	if not result.accepted:
		_set_status(RouteCatalog.reason_text(String(result.reason_code)), true)
		_refresh_buttons()
		return
	if result.snapshot != null:
		_snapshot_data = result.snapshot.to_dictionary()
	_render_options()
	_set_status("休整结果已写入路线档案。")


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func is_pending() -> bool:
	return _busy


func select_rest(rest_id: String) -> void:
	if _busy:
		return
	var option := _find_option(rest_id)
	if option.is_empty():
		_set_status("这个休息选择当前不可用。", true)
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在执行「%s」……" % String(
		option.get("display_name_zh", rest_id)
	))
	route_command_requested.emit(RouteCommand.use_rest(StringName(rest_id)))


func get_option_count() -> int:
	var options: Variant = _snapshot_data.get("rest_options", [])
	return options.size() if options is Array else 0


func get_option_effect_text(index: int) -> String:
	var options: Array = _snapshot_data.get("rest_options", [])
	if index < 0 or index >= options.size() or not options[index] is Dictionary:
		return ""
	return RouteCatalog.rest_effect_text(options[index].get("effects", {}))


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_background_path() -> String:
	return RouteCatalog.REST_BACKGROUND


func _build() -> void:
	UiTheme.add_background(self, RouteCatalog.REST_BACKGROUND, UiTheme.C_BG, 0.43)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 72)
	safe.add_theme_constant_override("margin_top", 42)
	safe.add_theme_constant_override("margin_right", 72)
	safe.add_theme_constant_override("margin_bottom", 38)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	safe.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	column.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	header.add_child(heading)
	heading.add_child(UiTheme.label("旧宅档案 · 短暂休整", 12, UiTheme.C_GOLD))
	heading.add_child(UiTheme.label("旧宅喘息", 36, UiTheme.C_TEXT))
	heading.add_child(UiTheme.label(
		"伤口、污染和目光都在门外等待。只能优先处理其中一种。",
		14,
		UiTheme.C_MUTED
	))
	_resource_label = UiTheme.label("", 15, UiTheme.C_PAPER)
	_resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_resource_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)
	_options_row = HBoxContainer.new()
	_options_row.add_theme_constant_override("separation", 28)
	_options_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_options_row)

	_status_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	_status_label.custom_minimum_size = Vector2(0, 38)
	column.add_child(_status_label)


func _render_options() -> void:
	_update_resources()
	for child in _options_row.get_children():
		child.queue_free()
	_buttons_by_rest.clear()
	var options: Array = _snapshot_data.get("rest_options", [])
	for value in options:
		if value is Dictionary:
			_options_row.add_child(_build_option(value))
	if options.is_empty():
		var empty := UiTheme.center_label("当前没有可用的休息选择。", 20, UiTheme.C_MUTED)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_options_row.add_child(empty)
	_set_status(
		"选择一种休整方式。效果会立即写入路线资源。"
		if not options.is_empty()
		else "等待休息节点。"
	)
	_refresh_buttons()


func _build_option(option: Dictionary) -> Control:
	var rest_id := String(option.get("id", ""))
	var panel := UiTheme.panel(Color(0.065, 0.068, 0.055, 0.97), UiTheme.C_GOLD)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.set_meta("rest_id", rest_id)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 26)
	pad.add_theme_constant_override("margin_top", 26)
	pad.add_theme_constant_override("margin_right", 26)
	pad.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pad.add_child(column)
	column.add_child(UiTheme.center_label(
		String(option.get("display_name_zh", rest_id)),
		29,
		UiTheme.C_TEXT
	))
	column.add_child(UiTheme.center_label(
		RouteCatalog.rest_effect_text(option.get("effects", {})),
		22,
		UiTheme.C_GOLD
	))
	column.add_child(UiTheme.wrapped_label(
		String(option.get("description_zh", "")),
		16,
		UiTheme.C_PAPER
	))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var button := UiTheme.button(
		"执行休整",
		func() -> void: select_rest(rest_id),
		not _busy,
		0
	)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(button)
	_buttons_by_rest[rest_id] = button
	return panel


func _update_resources() -> void:
	var run_state: Dictionary = _snapshot_data.get("run_state", {})
	_resource_label.text = (
		"生命 %d / %d  ·  污染 %d / %d  ·  被注视 %d / %d"
		% [
			int(run_state.get("hp", 0)),
			int(run_state.get("max_hp", 0)),
			int(run_state.get("corruption", 0)),
			int(run_state.get("max_corruption", 10)),
			int(run_state.get("attention", 0)),
			int(run_state.get("max_attention", 10)),
		]
	)


func _find_option(rest_id: String) -> Dictionary:
	var options: Array = _snapshot_data.get("rest_options", [])
	for value in options:
		if value is Dictionary and String(value.get("id", "")) == rest_id:
			return value
	return {}


func _show_empty() -> void:
	if not is_instance_valid(_options_row):
		return
	for child in _options_row.get_children():
		child.queue_free()
	var empty := UiTheme.center_label("等待旧宅休息节点。", 20, UiTheme.C_MUTED)
	empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_row.add_child(empty)
	_set_status("尚未连接休息状态。")


func _refresh_buttons() -> void:
	for rest_id in _buttons_by_rest:
		var button: Button = _buttons_by_rest[rest_id]
		if is_instance_valid(button):
			button.disabled = _busy
func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
