extends Control

signal upgrade_requested(definition_id: StringName)
signal back_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const ProgressionSnapshotScript := preload("res://src/core/progression_snapshot.gd")
const ProgressionCommandResultScript := preload("res://src/core/progression_command_result.gd")

var _snapshot_data: Dictionary = {}
var _card_names: Dictionary = {}
var _effect_previews: Dictionary = {}
var _grid: GridContainer
var _status_label: Label
var _ticket_label: Label
var _back_button: Button
var _buttons_by_card: Dictionary = {}
var _status_by_card: Dictionary = {}
var _progress_by_card: Dictionary = {}
var _next_step_by_card: Dictionary = {}
var _button_blocked: Dictionary = {}
var _busy := false
var _card_row_count := 0


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func configure(card_names: Dictionary = {}, effect_previews: Dictionary = {}) -> void:
	_card_names = card_names.duplicate(true)
	_effect_previews = effect_previews.duplicate(true)
	if not _snapshot_data.is_empty():
		_render_collection()


func apply_snapshot(snapshot: ProgressionSnapshot) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_busy = false
	_render_collection()
	_set_status("升级只消耗对应卡牌残页。界面不预先结算升级效果。")


func apply_command_result(result: ProgressionCommandResult) -> void:
	_busy = false
	if result == null:
		_set_status("未收到升级结果。", true)
		_refresh_buttons()
		return
	if not result.accepted:
		_set_status(ProgressionCatalog.reason_text(String(result.reason_code)), true)
		_refresh_buttons()
		return
	apply_snapshot(result.snapshot)
	_set_status("卡牌等级已写入档案，下一次战斗会使用升级后的效果。")


func set_pending(pending: bool) -> void:
	_busy = pending
	_refresh_buttons()


func request_upgrade(definition_id: String) -> void:
	if _busy:
		return
	_busy = true
	_refresh_buttons()
	_set_status("正在整理残页并加固卡牌……")
	upgrade_requested.emit(StringName(definition_id))


func is_pending() -> bool:
	return _busy


func get_card_row_count() -> int:
	return _card_row_count


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_background_path() -> String:
	return ProgressionCatalog.UPGRADE_BACKGROUND


func get_card_name(definition_id: String) -> String:
	return String(_card_names.get(definition_id, UiTheme.readable_id(definition_id)))


func get_card_status_text(definition_id: String) -> String:
	return String(_status_by_card.get(definition_id, ""))


func get_card_progress_text(definition_id: String) -> String:
	return String(_progress_by_card.get(definition_id, ""))


func get_card_next_step_text(definition_id: String) -> String:
	return String(_next_step_by_card.get(definition_id, ""))


func _build() -> void:
	UiTheme.add_background(self, ProgressionCatalog.UPGRADE_BACKGROUND, UiTheme.C_BG, 0.5)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 64)
	safe.add_theme_constant_override("margin_top", 36)
	safe.add_theme_constant_override("margin_right", 64)
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
	title.add_child(UiTheme.label("封印物档案 · 强化", 12, UiTheme.C_GOLD))
	title.add_child(UiTheme.label("卡牌升级", 36, UiTheme.C_TEXT))
	title.add_child(UiTheme.label(
		"用重复回响留下的残页加固卡牌。每张牌的下一次战斗都会读取新等级。",
		14,
		UiTheme.C_MUTED
	))
	_ticket_label = UiTheme.label("占卜券 0", 16, UiTheme.C_PAPER)
	_ticket_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_ticket_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	column.add_child(bottom)
	_status_label = UiTheme.clip_label("", 14, UiTheme.C_MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status_label)
	_back_button = UiTheme.button("返回白昼档案", _on_back, true, 160)
	bottom.add_child(_back_button)


func _render_collection() -> void:
	if not is_instance_valid(_grid):
		return
	for child in _grid.get_children():
		child.queue_free()
	_buttons_by_card.clear()
	_status_by_card.clear()
	_progress_by_card.clear()
	_next_step_by_card.clear()
	_button_blocked.clear()
	_card_row_count = 0
	_ticket_label.text = "占卜券 %d" % int(_snapshot_data.get("divination_tickets", 0))
	var cards: Array = _snapshot_data.get("collection", [])
	var sorted_cards := cards.duplicate()
	sorted_cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("definition_id", "")) < String(b.get("definition_id", ""))
	)
	for card_value in sorted_cards:
		if not card_value is Dictionary:
			continue
		var card: Dictionary = card_value
		if int(card.get("max_level", 0)) <= 0:
			continue
		_grid.add_child(_build_card_row(card))
		_card_row_count += 1
	if _card_row_count == 0:
		var empty := UiTheme.center_label("当前没有可升级卡牌。", 18, UiTheme.C_MUTED)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(empty)
	_refresh_buttons()


func _build_card_row(card: Dictionary) -> Control:
	var definition_id := String(card.get("definition_id", ""))
	var level := int(card.get("level", 0))
	var max_level := int(card.get("max_level", 0))
	var copies := int(card.get("copies", 0))
	var fragments := int(card.get("fragments", 0))
	var cost := int(card.get("next_upgrade_cost", 0))
	var owned := copies > 0
	var panel := UiTheme.panel(Color(0.065, 0.068, 0.055, 0.97), UiTheme.C_LINE)
	var ready_to_upgrade := owned and level < max_level and fragments >= cost and cost > 0
	panel.add_theme_stylebox_override(
		"panel",
		UiTheme.style_box(
			Color(0.09, 0.085, 0.055, 0.99) if ready_to_upgrade else Color(0.065, 0.068, 0.055, 0.97),
			UiTheme.C_GOLD if ready_to_upgrade else UiTheme.C_LINE,
			2 if ready_to_upgrade else 1,
			8
		)
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_meta("definition_id", definition_id)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(pad)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	pad.add_child(row)
	var art := TextureRect.new()
	art.texture = load(ProgressionCatalog.card_art(definition_id))
	art.custom_minimum_size = Vector2(138, 108)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(art)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	info.add_child(title_row)
	title_row.add_child(UiTheme.label(get_card_name(definition_id), 20, UiTheme.C_TEXT))
	var level_icon := TextureRect.new()
	level_icon.texture = load(ProgressionCatalog.upgrade_icon(maxi(1, level)))
	level_icon.custom_minimum_size = Vector2(32, 32)
	level_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	level_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	level_icon.modulate = Color(1, 1, 1, 1 if level > 0 else 0.45)
	title_row.add_child(level_icon)
	title_row.add_child(UiTheme.badge(
		"等级 %d / %d" % [level, max_level],
		UiTheme.C_GOLD,
		UiTheme.C_GOLD if level > 0 else UiTheme.C_LINE
	))
	var status := _card_status(owned, level, max_level, fragments, cost)
	info.add_child(UiTheme.label(
		"● 现在可以升级" if ready_to_upgrade else status,
		14,
		UiTheme.C_GOLD if ready_to_upgrade else UiTheme.C_MUTED
	))
	_status_by_card[definition_id] = status
	var required_fragments := maxi(0, cost) if level < max_level else 0
	var shortfall := maxi(0, required_fragments - fragments)
	var progress_text := "残页：已有 %d · 需要 %d · 差额 %d" % [
		fragments,
		required_fragments,
		shortfall,
	]
	var next_step_text := _next_step_text(owned, level, max_level, required_fragments, shortfall)
	_progress_by_card[definition_id] = progress_text
	_next_step_by_card[definition_id] = next_step_text
	info.add_child(UiTheme.label(progress_text, 13, UiTheme.C_PAPER))
	info.add_child(UiTheme.wrapped_label(
		next_step_text,
		13,
		UiTheme.C_GOLD if owned and level < max_level and shortfall == 0 else UiTheme.C_MUTED
	))
	var before_text := _preview_text(definition_id, level)
	var after_text := _preview_text(definition_id, level + 1)
	var preview := UiTheme.wrapped_label(
		"当前：%s\n升级后：%s" % [before_text, after_text]
		if owned and level < max_level
		else "当前：%s" % before_text,
		13,
		UiTheme.C_PAPER
	)
	preview.custom_minimum_size = Vector2(0, 42)
	info.add_child(preview)

	var action := VBoxContainer.new()
	action.custom_minimum_size = Vector2(126, 0)
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(action)
	var upgrade_button := UiTheme.button(
		"立即升级" if ready_to_upgrade else "升级",
		func() -> void: request_upgrade(definition_id),
		true,
		112
	)
	var base_disabled := (
		_busy
		or not owned
		or level >= max_level
		or cost <= 0
		or fragments < cost
	)
	upgrade_button.disabled = base_disabled
	action.add_child(upgrade_button)
	_buttons_by_card[definition_id] = upgrade_button
	_button_blocked[definition_id] = base_disabled
	return panel


func _card_status(owned: bool, level: int, max_level: int, fragments: int, cost: int) -> String:
	if not owned:
		return "未收容 · 先通过祈愿获得该卡牌"
	if level >= max_level:
		return "已满级 · 当前效果已是最高等级"
	if cost <= 0:
		return "升级所需残页暂不可用 · 返回档案后重试"
	var remaining := maxi(0, cost - fragments)
	if remaining == 0:
		return "残页 %d / %d · 可升级" % [fragments, cost]
	return "残页 %d / %d · 还需 %d 页" % [fragments, cost, remaining]


func _next_step_text(
	owned: bool,
	level: int,
	max_level: int,
	required_fragments: int,
	shortfall: int
) -> String:
	if not owned:
		return "下一步：先通过祈愿或奖励收容这张卡。"
	if level >= max_level:
		return "下一步：已达当前等级上限，可投入其他卡牌。"
	if required_fragments <= 0:
		return "下一步：等待成长档案提供升级成本。"
	if shortfall <= 0:
		return "下一步：残页足够，可以升级。"
	return "下一步：再收集 %d 张残页。" % shortfall


func _preview_text(definition_id: String, level: int) -> String:
	var value: Variant = _effect_previews.get(definition_id, null)
	if value is Array:
		var values: Array = value
		var index := clampi(level, 0, maxi(0, values.size() - 1))
		return String(values[index]) if not values.is_empty() else "效果由规则层结算"
	if value is Dictionary:
		var levels: Dictionary = value
		if levels.has(str(level)):
			return String(levels[str(level)])
		if levels.has(level):
			return String(levels[level])
	return "效果由规则层结算"


func _show_empty() -> void:
	if not is_instance_valid(_grid):
		return
	for child in _grid.get_children():
		child.queue_free()
	var empty := UiTheme.center_label("等待成长档案。", 18, UiTheme.C_MUTED)
	empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(empty)
	_set_status("尚未连接卡牌收藏。")


func _refresh_buttons() -> void:
	if is_instance_valid(_back_button):
		_back_button.disabled = false
	for definition_id in _buttons_by_card:
		var button: Button = _buttons_by_card[definition_id]
		if is_instance_valid(button):
			button.disabled = _busy or bool(_button_blocked.get(definition_id, true))


func _on_back() -> void:
	back_requested.emit()


func _set_status(message: String, danger: bool = false) -> void:
	if not is_instance_valid(_status_label):
		return
	UiTheme.set_clip_text(_status_label, message)
	_status_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
	)
