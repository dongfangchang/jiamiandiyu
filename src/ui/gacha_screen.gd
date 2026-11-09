extends Control

signal draw_requested(pull_count: int)
signal back_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const ProgressionCommandResultScript := preload("res://src/core/progression_command_result.gd")

var _snapshot_data: Dictionary = {}
var _card_names: Dictionary = {}
var _card_details: Dictionary = {}
var _result_row: HBoxContainer
var _ticket_label: Label
var _pity_label: Label
var _cost_label: Label
var _guidance_label: Label
var _history_label: Label
var _history_option: OptionButton
var _status_label: Label
var _single_button: Button
var _triple_button: Button
var _back_button: Button
var _busy := false
var _result_count := 0
var _pending_token := 0
var _detail_dialog: AcceptDialog
var _result_card_nodes: Array[Control] = []


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty_results()


func configure(card_names: Dictionary = {}, card_details: Dictionary = {}) -> void:
	_card_names = card_names.duplicate(true)
	_card_details = card_details.duplicate(true)
	_render_results(_snapshot_data.get("last_gacha_results", []))
	_update_history_dropdown(_snapshot_data.get("gacha_history", []))


func apply_snapshot(snapshot: ProgressionSnapshot, show_results: bool = false) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	var latest_results: Array = _snapshot_data.get("last_gacha_results", [])
	if not show_results:
		_snapshot_data["last_gacha_results"] = []
	if is_instance_valid(_detail_dialog):
		_detail_dialog.hide()
	_busy = false
	_pending_token += 1
	_update_resources()
	_render_results(_snapshot_data.get("last_gacha_results", []))
	var history_value: Variant = _snapshot_data.get("gacha_history", [])
	if not history_value is Array or history_value.is_empty():
		if not latest_results.is_empty():
			history_value = [{"draw_index": 1, "pull_count": latest_results.size(), "results": latest_results}]
	_update_history_dropdown(history_value)
	_set_status("祈愿结果由灵界规则结算，界面只呈现回响。")


func apply_command_result(result: ProgressionCommandResult) -> void:
	_busy = false
	_pending_token += 1
	if result == null:
		_set_status("未收到祈愿结果。", true)
		_refresh_buttons()
		return
	if not result.accepted:
		_set_status(ProgressionCatalog.reason_text(String(result.reason_code)), true)
		_refresh_buttons()
		return
	apply_snapshot(result.snapshot, true)
	var results: Array = _snapshot_data.get("last_gacha_results", [])
	var rare_count := 0
	for value in results:
		if value is Dictionary and String(value.get("rarity", "")) == "rare":
			rare_count += 1
	_set_status(
		"祈愿完成：%d 道回响，其中稀有 %d。" % [results.size(), rare_count],
		false
	)


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func request_draw(pull_count: int) -> void:
	if _busy:
		return
	_busy = true
	_pending_token += 1
	var token := _pending_token
	_refresh_buttons()
	_set_status("正在向灵界请求回响……")
	draw_requested.emit(pull_count)
	get_tree().create_timer(4.0).timeout.connect(_on_draw_timeout.bind(token))


func is_pending() -> bool:
	return _busy


func get_result_count() -> int:
	return _result_count


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_ticket_text() -> String:
	return _ticket_label.text if is_instance_valid(_ticket_label) else ""


func get_guidance_text() -> String:
	return _guidance_label.text if is_instance_valid(_guidance_label) else ""


func get_background_path() -> String:
	return ProgressionCatalog.GACHA_BACKGROUND


func get_card_name(definition_id: String) -> String:
	return String(_card_names.get(definition_id, UiTheme.readable_id(definition_id)))


func inspect_result(index: int) -> bool:
	if index < 0 or index >= _result_card_nodes.size():
		return false
	var card := _result_card_nodes[index]
	var result: Variant = card.get_meta("gacha_result", {})
	if not result is Dictionary:
		return false
	_show_card_detail(result)
	return is_instance_valid(_detail_dialog) and _detail_dialog.visible


func get_detail_text() -> String:
	return _detail_dialog.dialog_text if is_instance_valid(_detail_dialog) else ""


func get_history_count() -> int:
	return _history_option.item_count - 1 if is_instance_valid(_history_option) and _history_option.item_count > 0 else 0


func _build() -> void:
	UiTheme.add_background(self, ProgressionCatalog.GACHA_BACKGROUND, UiTheme.C_BG, 0.28)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 68)
	safe.add_theme_constant_override("margin_top", 38)
	safe.add_theme_constant_override("margin_right", 68)
	safe.add_theme_constant_override("margin_bottom", 34)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	safe.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	column.add_child(top)
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	title.add_child(UiTheme.label("灵界档案 · 占卜", 12, UiTheme.C_GOLD))
	title.add_child(UiTheme.label("灵界祈愿", 36, UiTheme.C_TEXT))
	title.add_child(UiTheme.label(
		"抽取封印中的回响。重复的回响会化为残页。",
		14,
		UiTheme.C_MUTED
	))
	var resource_box := HBoxContainer.new()
	resource_box.add_theme_constant_override("separation", 18)
	top.add_child(resource_box)
	_ticket_label = UiTheme.label("占卜券 0", 18, UiTheme.C_PAPER)
	resource_box.add_child(_add_icon_label(
		ProgressionCatalog.TICKET_ICON,
		_ticket_label
	))
	_pity_label = UiTheme.label("稀有保底 0 / 0", 15, UiTheme.C_GOLD)
	resource_box.add_child(_pity_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	_result_row = HBoxContainer.new()
	_result_row.add_theme_constant_override("separation", 24)
	_result_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_result_row)

	var status_panel := UiTheme.padded_panel(
		_build_bottom_controls(),
		14,
		Color(0.055, 0.06, 0.047, 0.96),
		UiTheme.C_LINE
	)
	column.add_child(status_panel)


func _build_bottom_controls() -> VBoxContainer:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_guidance_label = UiTheme.wrapped_label("抽取说明等待档案。", 13, UiTheme.C_PAPER)
	content.add_child(_guidance_label)
	_history_label = UiTheme.label("抽卡记录：暂无", 12, UiTheme.C_PAPER_DEEP)
	_history_label.clip_text = true
	_history_label.tooltip_text = "最近一次祈愿的结算记录"
	content.add_child(_history_label)
	_history_option = OptionButton.new()
	_history_option.name = "GachaHistoryDropdown"
	_history_option.custom_minimum_size = Vector2(240, 34)
	_history_option.text = "抽卡记录（0）"
	_history_option.item_selected.connect(_on_history_selected)
	content.add_child(_history_option)
	_status_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	content.add_child(_status_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	_cost_label = UiTheme.label("祈愿费用未知", 14, UiTheme.C_PAPER)
	_cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_cost_label)
	_back_button = UiTheme.button("返回白昼档案", _on_back, true, 160)
	_single_button = UiTheme.button("单抽", func() -> void: request_draw(1), true, 132)
	_triple_button = UiTheme.button("三连", func() -> void: request_draw(3), true, 132)
	row.add_child(_back_button)
	row.add_child(_single_button)
	row.add_child(_triple_button)
	return content


func _add_icon_label(icon_path: String, text_label: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	row.add_child(text_label)
	return row


func _render_results(results_value: Variant) -> void:
	if not is_instance_valid(_result_row):
		return
	for child in _result_row.get_children():
		child.free()
	_result_count = 0
	_result_card_nodes.clear()
	var results: Array = results_value if results_value is Array else []
	if results.is_empty():
		_show_empty_results()
		return
	for result_value in results:
		if result_value is Dictionary:
			var result_card := _build_result_card(result_value, _result_count)
			_result_card_nodes.append(result_card)
			_result_row.add_child(result_card)
			_result_count += 1


func _update_history_dropdown(history_value: Variant) -> void:
	if not is_instance_valid(_history_option):
		return
	_history_option.clear()
	_history_option.add_item("抽卡记录（%d 次）" % (history_value.size() if history_value is Array else 0))
	_history_option.set_item_disabled(0, true)
	var history: Array = history_value if history_value is Array else []
	for index in range(history.size()):
		if not history[index] is Dictionary:
			continue
		var entry: Dictionary = history[index]
		var results: Array = entry.get("results", [])
		_history_option.add_item("第 %d 次 · %d 张 · %s" % [
			int(entry.get("draw_index", index + 1)),
			int(entry.get("pull_count", results.size())),
			_history_summary(results),
		])
		_history_option.set_item_metadata(_history_option.item_count - 1, entry.duplicate(true))
	_history_option.select(0)
	_history_option.disabled = history.is_empty()
	_history_label.text = "抽卡记录：暂无" if history.is_empty() else "抽卡记录已保存，可从下拉框查看"


func _history_summary(results: Array) -> String:
	var names: Array[String] = []
	for result_value in results:
		if result_value is Dictionary:
			names.append(get_card_name(String(result_value.get("definition_id", ""))))
	return "、".join(names) if not names.is_empty() else "无结果"


func _on_history_selected(index: int) -> void:
	if not is_instance_valid(_history_option) or index <= 0:
		return
	var entry: Variant = _history_option.get_item_metadata(index)
	if entry is Dictionary:
		var results: Array = entry.get("results", [])
		_history_label.text = "第 %d 次：%s" % [int(entry.get("draw_index", index)), _history_summary(results)]


func _show_empty_results() -> void:
	var back := TextureRect.new()
	back.texture = load(ProgressionCatalog.CARD_BACK)
	back.custom_minimum_size = Vector2(260, 366)
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_result_row.add_child(back)
	var hint := UiTheme.center_label("尚未抽取回响", 20, UiTheme.C_PAPER)
	hint.custom_minimum_size = Vector2(260, 0)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_row.add_child(hint)
	_result_count = 0


func _build_result_card(result: Dictionary, flip_index: int = 0) -> Control:
	var definition_id := String(result.get("definition_id", ""))
	var rarity := String(result.get("rarity", ""))
	var panel := UiTheme.panel(
		Color(0.07, 0.072, 0.058, 0.97),
		UiTheme.C_GOLD if rarity == "rare" else UiTheme.C_LINE
	)
	panel.custom_minimum_size = Vector2(292, 404)
	panel.set_meta("gacha_result", result.duplicate(true))
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = Vector2(146, 202)
	panel.set_meta("revealed", false)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_card_detail(result)
	)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	pad.add_child(column)
	var flip_area := Control.new()
	flip_area.custom_minimum_size = Vector2(0, 190)
	flip_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(flip_area)
	var back := TextureRect.new()
	back.texture = load(ProgressionCatalog.CARD_BACK)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flip_area.add_child(back)
	var front := TextureRect.new()
	front.texture = load(ProgressionCatalog.card_art(definition_id))
	front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	front.visible = false
	flip_area.add_child(front)
	column.add_child(UiTheme.center_label(
		get_card_name(definition_id),
		22,
		UiTheme.C_TEXT
	))
	column.add_child(UiTheme.center_label(
		ProgressionCatalog.rarity_text(rarity),
		13,
		UiTheme.C_GOLD if rarity == "rare" else UiTheme.C_MUTED
	))
	var duplicate := bool(result.get("duplicate", false))
	var fragments := int(result.get("fragments", 0))
	column.add_child(UiTheme.center_label(
		"重复回响 · 残页 +%d" % fragments if duplicate else "首次收容",
		14,
		UiTheme.C_DANGER_TEXT if duplicate else UiTheme.C_PAPER
	))
	call_deferred("_play_result_flip", panel, flip_area, back, front, flip_index)
	return panel


func _play_result_flip(panel, flip_area, back, front, flip_index: int) -> void:
	await get_tree().create_timer(float(flip_index) * 0.42).timeout
	if not is_instance_valid(panel):
		return
	var entrance: Tween = panel.create_tween().set_parallel(true)
	entrance.tween_property(panel, "modulate:a", 1.0, 0.18)
	entrance.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrance.finished
	if not is_instance_valid(flip_area):
		return
	var flip: Tween = flip_area.create_tween()
	flip.tween_property(flip_area, "scale:x", 0.04, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flip.tween_callback(func() -> void:
		back.visible = false
		front.visible = true
		panel.set_meta("revealed", true)
	)
	flip.tween_property(flip_area, "scale:x", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _show_card_detail(result: Dictionary) -> void:
	if not is_instance_valid(_detail_dialog):
		_detail_dialog = AcceptDialog.new()
		_detail_dialog.title = "回响详情"
		_detail_dialog.ok_button_text = "关闭"
		add_child(_detail_dialog)
	var definition_id := String(result.get("definition_id", ""))
	var card_detail: Dictionary = _card_details.get(definition_id, {})
	var description := String(card_detail.get("description", ""))
	var effect_text := String(card_detail.get("effect_text", ""))
	var detail := "【%s】\n%s\n\n%s\n品阶：%s\n%s" % [
		get_card_name(definition_id),
		description if not description.is_empty() else "点击查看这张回响的规则。",
		effect_text,
		ProgressionCatalog.rarity_text(String(result.get("rarity", ""))),
		("重复回响转化为残页 +%d" % int(result.get("fragments", 0))) if bool(result.get("duplicate", false)) else "首次收容",
	]
	_detail_dialog.dialog_text = detail
	_detail_dialog.popup_centered(Vector2(460, 300))


func _update_resources() -> void:
	var costs: Dictionary = _snapshot_data.get("gacha_costs", {})
	var rarity_weights: Dictionary = _snapshot_data.get("rarity_weights", {})
	var tickets := int(_snapshot_data.get("divination_tickets", 0))
	var single_cost := int(costs.get("single", 0))
	var triple_cost := int(costs.get("triple", 0))
	_ticket_label.text = "占卜券 %d" % tickets
	_pity_label.text = "稀有保底 %d / %d" % [
		int(_snapshot_data.get("pity_counter", 0)),
		int(_snapshot_data.get("rare_pity", 0)),
	]
	_guidance_label.text = _gacha_guidance(rarity_weights, int(_snapshot_data.get("rare_pity", 0)))
	_cost_label.text = "单抽 %d 券  ·  三连 %d 券  ·  三连按三次独立抽取结算" % [
		single_cost,
		triple_cost,
	]
	_single_button.disabled = _busy or single_cost <= 0 or tickets < single_cost
	_triple_button.disabled = _busy or triple_cost <= 0 or tickets < triple_cost


func _gacha_guidance(rarity_weights: Dictionary, rare_pity: int) -> String:
	if not rarity_weights.has("rare") or rare_pity <= 0:
		return "抽取说明：稀有率与保底信息暂不可用，请稍后查看档案。"
	var rare_weight: Variant = rarity_weights.get("rare")
	var rare_weight_text := str(rare_weight)
	if rare_weight is float and is_equal_approx(float(rare_weight), round(float(rare_weight))):
		rare_weight_text = str(int(rare_weight))
	return "抽取说明：稀有回响权重 %s · 保底上限 %d 次" % [rare_weight_text, rare_pity]


func _refresh_buttons() -> void:
	if is_instance_valid(_back_button):
		_back_button.disabled = false
	_update_resources()


func _on_back() -> void:
	_clear_results()
	_busy = false
	_pending_token += 1
	back_requested.emit()


func _clear_results() -> void:
	_snapshot_data["last_gacha_results"] = []
	if is_instance_valid(_result_row):
		for child in _result_row.get_children():
			child.free()
	_result_card_nodes.clear()
	_result_count = 0
	_show_empty_results()
	if is_instance_valid(_detail_dialog):
		_detail_dialog.hide()


func _on_draw_timeout(token: int) -> void:
	if token != _pending_token or not _busy:
		return
	_busy = false
	_set_status("祈愿结算超时，已解除等待。可以返回或重试。", true)
	_refresh_buttons()


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
