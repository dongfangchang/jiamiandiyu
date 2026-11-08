extends Control

signal hub_requested
signal retry_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _snapshot_data: Dictionary = {}
var _save_state := "pending"
var _title_label: Label
var _detail_label: Label
var _save_label: Label
var _result_icon: TextureRect
var _hub_button: Button
var _retry_button: Button


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func show_result(snapshot: RouteSnapshot, save_state: String = "pending") -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_save_state = save_state
	_render_result()


func set_save_state(save_state: String) -> void:
	_save_state = save_state
	_update_save_label()


func get_route_outcome() -> String:
	return String(_snapshot_data.get("route_outcome", ""))


func get_save_text() -> String:
	return _save_label.text if is_instance_valid(_save_label) else ""


func get_title_text() -> String:
	return _title_label.text if is_instance_valid(_title_label) else ""


func get_background_path() -> String:
	return (
		RouteCatalog.RITUAL_BACKGROUND
		if get_route_outcome() == "completed"
		else RouteCatalog.ROUTE_BACKGROUND
	)


func _build() -> void:
	UiTheme.add_background(
		self,
		RouteCatalog.ROUTE_BACKGROUND,
		UiTheme.C_BG,
		RouteCatalog.ROUTE_BACKGROUND_DIM
	)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 160)
	safe.add_theme_constant_override("margin_top", 84)
	safe.add_theme_constant_override("margin_right", 160)
	safe.add_theme_constant_override("margin_bottom", 70)
	add_child(safe)
	var panel := UiTheme.panel(Color(0.055, 0.059, 0.047, 0.97), UiTheme.C_GOLD)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(panel)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 46)
	pad.add_theme_constant_override("margin_top", 32)
	pad.add_theme_constant_override("margin_right", 46)
	pad.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pad.add_child(column)
	column.add_child(UiTheme.label("路线档案 · 结论", 12, UiTheme.C_GOLD))

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 26)
	column.add_child(hero)
	_result_icon = TextureRect.new()
	_result_icon.custom_minimum_size = Vector2(116, 116)
	_result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.add_child(_result_icon)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 3)
	hero.add_child(heading)
	_title_label = UiTheme.label("路线结算", 40, UiTheme.C_TEXT)
	heading.add_child(_title_label)
	heading.add_child(UiTheme.label(
		"调查记录已经封存；局外收藏与序列状态仍保留在本机。",
		15,
		UiTheme.C_MUTED
	))

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)
	_detail_label = UiTheme.wrapped_label("", 17, UiTheme.C_PAPER)
	_detail_label.custom_minimum_size = Vector2(0, 180)
	column.add_child(_detail_label)
	_save_label = UiTheme.wrapped_label("", 16, UiTheme.C_GOLD)
	column.add_child(_save_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(footer)
	_retry_button = UiTheme.button("重新探索", _on_retry, false, 160)
	footer.add_child(_retry_button)
	_hub_button = UiTheme.button("返回白昼档案", _on_hub, true, 180)
	footer.add_child(_hub_button)


func _render_result() -> void:
	var completed := get_route_outcome() == "completed"
	_title_label.text = "晋升完成" if completed else "探索失败"
	_title_label.add_theme_color_override(
		"font_color",
		UiTheme.C_GOLD if completed else UiTheme.C_DANGER_TEXT
	)
	_result_icon.texture = load(
		RouteCatalog.ROUTE_ICON_BASE + (
			"ritual-success.png" if completed else "ritual-failure.png"
		)
	)
	var completed_nodes: Array = _snapshot_data.get("completed_node_ids", [])
	var nodes: Array = _snapshot_data.get("nodes", [])
	var sequence: Dictionary = _snapshot_data.get("sequence", {})
	var run_state: Dictionary = _snapshot_data.get("run_state", {})
	var end_reason := String(_snapshot_data.get("end_reason", ""))
	if completed and end_reason.is_empty():
		end_reason = "ascension_completed"
	var sequence_text := "占卜家 · 序列 %d" % int(
		sequence.get("current_sequence", 9)
	)
	if completed:
		sequence_text += "「%s」" % String(
			sequence.get("next_sequence_name_zh", "小丑")
		)
	_detail_label.text = (
		"路线：%s\n已完成节点：%d / %d\n序列：%s\n"
		+ "结束原因：%s\n"
		+ "剩余生命：%d / %d  ·  污染：%d / %d  ·  被注视：%d / %d"
	) % [
		String(_snapshot_data.get("display_name_zh", "未知路线")),
		completed_nodes.size(),
		nodes.size(),
		sequence_text,
		_end_reason_text(end_reason),
		int(run_state.get("hp", 0)),
		int(run_state.get("max_hp", 0)),
		int(run_state.get("corruption", 0)),
		int(run_state.get("max_corruption", 10)),
		int(run_state.get("attention", 0)),
		int(run_state.get("max_attention", 10)),
	]
	if completed:
		_detail_label.text += (
			"\n\n三步仪式已经完成。下一次启动仍会保留序列 8「小丑」。"
		)
	else:
		_detail_label.text += (
			"\n\n本次探索已结束。收藏、卡牌等级、预设和已确认奖励不会丢失；"
			+ "回到白昼档案后可调整牌组或重新挑战。"
		)
	_update_save_label()
	_hub_button.disabled = false
	_retry_button.disabled = completed


func _update_save_label() -> void:
	match _save_state:
		"saved":
			_save_label.text = "路线检查点已保存。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_GOLD)
		"backup":
			_save_label.text = "主存档异常，但备份检查点可用。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT)
		"failed":
			_save_label.text = "检查点保存失败；退出前请保留当前诊断记录。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT)
		_:
			_save_label.text = "正在写入路线检查点……"
			_save_label.add_theme_color_override("font_color", UiTheme.C_MUTED)


func _end_reason_text(reason: String) -> String:
	match reason:
		"battle_defeat":
			return "战斗中生命降至 0"
		"corruption_limit":
			return "污染达到上限，探索被迫结束"
		"ritual_error", "ritual_corruption_limit":
			return "晋升仪式失败"
		"ascension_completed":
			return "三步晋升仪式完成"
		"route_node_missing":
			return "路线节点数据异常"
		"":
			return "规则层未提供原因"
		_:
			return "未识别的结束原因；请查看诊断记录"


func _show_empty() -> void:
	_title_label.text = "等待路线结算"
	_detail_label.text = "调查尚未结束。"
	_save_label.text = ""
	_result_icon.texture = null
	_hub_button.disabled = true
	_retry_button.disabled = true


func _on_hub() -> void:
	hub_requested.emit()


func _on_retry() -> void:
	retry_requested.emit()
