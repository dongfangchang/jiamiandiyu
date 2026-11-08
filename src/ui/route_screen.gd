extends Control

signal route_command_requested(command: RouteCommand)
signal result_requested
signal hub_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const RouteCommandResultScript := preload("res://src/core/route_command_result.gd")

var _snapshot_data: Dictionary = {}
var _nodes_row: HBoxContainer
var _status_label: Label
var _resource_label: Label
var _route_label: Label
var _challenge_label: Label
var _result_button: Button
var _hub_button: Button
var _buttons_by_node: Dictionary = {}
var _busy := false


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func apply_snapshot(snapshot: RouteSnapshot) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_busy = false
	_render_snapshot()


func apply_command_result(result: RouteCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到路线结果。", true)
		_refresh_buttons()
		return
	if not result.accepted:
		_set_status(RouteCatalog.reason_text(String(result.reason_code)), true)
		_refresh_buttons()
		return
	if result.snapshot != null:
		_snapshot_data = result.snapshot.to_dictionary()
	_render_snapshot()
	_set_status("路线档案已更新。")


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func is_pending() -> bool:
	return _busy


func request_node(node_id: String) -> void:
	if _busy:
		return
	var target: Dictionary = _find_node(node_id)
	if target.is_empty() or String(target.get("state", "")) != "available":
		_set_status("该节点当前不可进入。", true)
		return
	if String(target.get("type", "")) == "ritual":
		request_ascension()
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在进入「%s」……" % String(
		target.get("display_name_zh", node_id)
	))
	route_command_requested.emit(RouteCommand.select_node(StringName(node_id)))


func request_ascension() -> void:
	if _busy or not bool(_snapshot_data.get("can_begin_ascension", false)):
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在展开被篡改的讣告……")
	route_command_requested.emit(RouteCommand.begin_ascension())


func get_node_count() -> int:
	var nodes: Variant = _snapshot_data.get("nodes", [])
	return nodes.size() if nodes is Array else 0


func get_node_state(index: int) -> String:
	var nodes: Array = _snapshot_data.get("nodes", [])
	if index < 0 or index >= nodes.size() or not nodes[index] is Dictionary:
		return ""
	return String(nodes[index].get("state", ""))


func is_node_button_enabled(node_id: String) -> bool:
	var button: Button = _buttons_by_node.get(node_id, null)
	return is_instance_valid(button) and not button.disabled


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_background_path() -> String:
	return RouteCatalog.ROUTE_BACKGROUND


func set_challenge_context(
	challenge_name: String,
	modifier_name: String
) -> void:
	if not is_instance_valid(_challenge_label):
		return
	_challenge_label.text = (
		"挑战 · %s  ·  修饰：%s" % [challenge_name, modifier_name]
	)
	_challenge_label.visible = true


func clear_challenge_context() -> void:
	if is_instance_valid(_challenge_label):
		_challenge_label.text = ""
		_challenge_label.visible = false


func get_challenge_context_text() -> String:
	return _challenge_label.text if is_instance_valid(_challenge_label) else ""


func _build() -> void:
	UiTheme.add_background(self, RouteCatalog.ROUTE_BACKGROUND, UiTheme.C_BG, 0.46)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 48)
	safe.add_theme_constant_override("margin_top", 34)
	safe.add_theme_constant_override("margin_right", 48)
	safe.add_theme_constant_override("margin_bottom", 30)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	safe.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	column.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	header.add_child(heading)
	heading.add_child(UiTheme.label("调查路线 · 占卜家序列 9", 12, UiTheme.C_GOLD))
	_route_label = UiTheme.label("廷根旧宅调查", 35, UiTheme.C_TEXT)
	heading.add_child(_route_label)
	heading.add_child(UiTheme.label(
		"沿固定线索推进。战斗只在节点边界留下检查点。",
		14,
		UiTheme.C_MUTED
	))
	_challenge_label = UiTheme.label("", 13, UiTheme.C_GOLD)
	_challenge_label.visible = false
	heading.add_child(_challenge_label)
	_resource_label = UiTheme.label("", 15, UiTheme.C_PAPER)
	_resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_resource_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	_nodes_row = HBoxContainer.new()
	_nodes_row.add_theme_constant_override("separation", 12)
	_nodes_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_nodes_row)

	var footer := UiTheme.padded_panel(
		_build_footer(),
		13,
		Color(0.055, 0.058, 0.047, 0.96),
		UiTheme.C_LINE
	)
	column.add_child(footer)


func _build_footer() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_status_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_status_label)
	_hub_button = UiTheme.button("返回白昼档案", _on_hub, true, 158)
	_result_button = UiTheme.button("查看路线结算", _on_result, false, 158)
	row.add_child(_hub_button)
	row.add_child(_result_button)
	return row


func _render_snapshot() -> void:
	_route_label.text = String(
		_snapshot_data.get("display_name_zh", "未知路线")
	)
	_update_resources()
	for child in _nodes_row.get_children():
		child.queue_free()
	_buttons_by_node.clear()
	var nodes: Array = _snapshot_data.get("nodes", [])
	for index in range(nodes.size()):
		if nodes[index] is Dictionary:
			_nodes_row.add_child(_build_node(nodes[index], index))
	var phase := String(_snapshot_data.get("phase", ""))
	var outcome := String(_snapshot_data.get("route_outcome", ""))
	_result_button.disabled = _busy or outcome.is_empty()
	_hub_button.disabled = _busy
	if phase == "map":
		_set_status("选择当前可进入的路线节点。")
	elif phase == "battle_pending":
		_set_status("战斗节点已经选定，等待战斗结算。")
	elif phase == "rest_pending":
		_set_status("休息节点已经选定，等待休整选择。")
	elif phase == "ritual":
		_set_status("晋升仪式已经开启。")
	elif phase == "completed":
		_set_status("路线调查完成，序列状态已归档。")
	elif phase == "failed":
		_set_status("路线已经中断，可从节点检查点继续。", true)
	else:
		_set_status("路线档案尚未准备好。")
	_refresh_buttons()


func _build_node(node: Dictionary, index: int) -> Control:
	var node_id := String(node.get("id", ""))
	var state := String(node.get("state", "locked"))
	var node_type := String(node.get("type", ""))
	var panel := UiTheme.panel(
		Color(0.065, 0.068, 0.055, 0.97),
		UiTheme.C_GOLD if state == "available" else UiTheme.C_LINE
	)
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.set_meta("node_id", node_id)
	panel.set_meta("node_state", state)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 13)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_right", 13)
	pad.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(pad)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	pad.add_child(column)
	var icon := TextureRect.new()
	icon.texture = load(RouteCatalog.route_state_icon(state))
	icon.custom_minimum_size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	column.add_child(UiTheme.center_label(
		"%02d" % (index + 1),
		12,
		UiTheme.C_MUTED
	))
	column.add_child(UiTheme.center_label(
		String(node.get("display_name_zh", node_id)),
		22,
		UiTheme.C_TEXT if state != "locked" else UiTheme.C_MUTED
	))
	column.add_child(UiTheme.center_label(
		RouteCatalog.node_type_text(node_type),
		13,
		UiTheme.C_GOLD if node_type in ["elite", "boss", "ritual"] else UiTheme.C_PAPER_DEEP
	))
	column.add_child(UiTheme.center_label(
		RouteCatalog.node_state_text(state),
		13,
		UiTheme.C_GOLD if state == "available" else UiTheme.C_MUTED
	))
	if node_type == "boss" and ResourceLoader.exists(RouteCatalog.BOSS_ART):
		var boss := TextureRect.new()
		boss.texture = load(RouteCatalog.BOSS_ART)
		boss.custom_minimum_size = Vector2(0, 112)
		boss.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		boss.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		column.add_child(boss)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var action_text := (
		"开始晋升"
		if node_type == "ritual"
		else ("进入休息" if node_type == "rest" else "前往节点")
	)
	var button := UiTheme.button(
		action_text,
		func() -> void: request_node(node_id),
		state == "available" and not _busy,
		0
	)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(button)
	_buttons_by_node[node_id] = button
	return panel


func _update_resources() -> void:
	var run_state: Dictionary = _snapshot_data.get("run_state", {})
	_resource_label.text = (
		"生命 %d / %d  ·  灵性 %d  ·  污染 %d / %d  ·  被注视 %d / %d"
		% [
			int(run_state.get("hp", 0)),
			int(run_state.get("max_hp", 0)),
			int(run_state.get("spirit", 0)),
			int(run_state.get("corruption", 0)),
			int(run_state.get("max_corruption", 10)),
			int(run_state.get("attention", 0)),
			int(run_state.get("max_attention", 10)),
		]
	)


func _show_empty() -> void:
	if not is_instance_valid(_nodes_row):
		return
	for child in _nodes_row.get_children():
		child.queue_free()
	var empty := UiTheme.center_label("等待路线档案。", 20, UiTheme.C_MUTED)
	empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_nodes_row.add_child(empty)
	_set_status("尚未连接路线状态。")


func _find_node(node_id: String) -> Dictionary:
	var nodes: Array = _snapshot_data.get("nodes", [])
	for value in nodes:
		if value is Dictionary and String(value.get("id", "")) == node_id:
			return value
	return {}


func _refresh_buttons() -> void:
	for node_id in _buttons_by_node:
		var button: Button = _buttons_by_node[node_id]
		if not is_instance_valid(button):
			continue
		var node := _find_node(String(node_id))
		button.disabled = _busy or String(node.get("state", "")) != "available"
	if is_instance_valid(_result_button):
		_result_button.disabled = _busy or String(
			_snapshot_data.get("route_outcome", "")
		).is_empty()
	if is_instance_valid(_hub_button):
		_hub_button.disabled = _busy


func _on_result() -> void:
	if _busy:
		return
	result_requested.emit()


func _on_hub() -> void:
	if _busy:
		return
	hub_requested.emit()


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
