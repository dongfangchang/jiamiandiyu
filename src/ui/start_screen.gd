extends Control

signal new_game_requested
signal continue_requested
signal quit_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const TITLE_BACKGROUND := "res://assets/game/scenes/title-screen.png"

var _continue_button: Button
var _new_game_button: Button
var _status_label: Label
var _summary_label: Label
var _busy := false
var _checkpoint_status := "none"


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	show_checkpoint_status("none")


func show_checkpoint_status(
	status: String,
	summary: Dictionary = {},
	error_message: String = ""
) -> void:
	_checkpoint_status = status
	if not is_instance_valid(_continue_button):
		return
	_busy = false
	_continue_button.disabled = status != "loaded"
	_new_game_button.disabled = false
	match status:
		"loaded":
			_continue_button.disabled = false
			_status_label.text = "检测到战后检查点"
			var last_battle: Dictionary = summary.get("last_battle", {})
			_summary_label.text = "内容 %s  ·  序列 %d  ·  牌组 %d 张\n上一场：%s / 第 %d 回合\n保存于 %s" % [
				String(summary.get("content_version", "未知")),
				int(summary.get("sequence", 0)),
				int(summary.get("deck_size", 0)),
				String(last_battle.get("outcome", "未知")),
				int(last_battle.get("round_number", 0)),
				String(summary.get("created_at", "未知")),
			]
		"corrupt":
			_continue_button.disabled = true
			_status_label.text = "检查点无法读取"
			_summary_label.text = "原始存档已保留。" + (
				"\n" + error_message if not error_message.is_empty() else ""
			)
		_:
			_continue_button.disabled = true
			_status_label.text = "尚未建立检查点"
			_summary_label.text = "开始新游戏以进入第一场战斗。战斗中退出会回到最近检查点。"


func set_busy(busy: bool) -> void:
	_busy = busy
	if is_instance_valid(_continue_button):
		_continue_button.disabled = _busy or _checkpoint_status != "loaded"
	if is_instance_valid(_new_game_button):
		_new_game_button.disabled = _busy


func is_continue_enabled() -> bool:
	return is_instance_valid(_continue_button) and not _continue_button.disabled


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func _build() -> void:
	UiTheme.add_background(self, TITLE_BACKGROUND, UiTheme.C_BG, 0.16)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 72)
	safe.add_theme_constant_override("margin_top", 54)
	safe.add_theme_constant_override("margin_right", 72)
	safe.add_theme_constant_override("margin_bottom", 54)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	safe.add_child(column)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(top_spacer)

	var panel := UiTheme.padded_panel(
		_build_panel_content(),
		24,
		Color(0.06, 0.065, 0.052, 0.96),
		UiTheme.C_GOLD
	)
	panel.custom_minimum_size = Vector2(670, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(panel)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(bottom_spacer)

	var footer := HBoxContainer.new()
	column.add_child(footer)
	footer.add_child(UiTheme.label(
		"单人离线原型 · 所有进度仅保存在本机",
		13,
		UiTheme.C_MUTED
	))
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	footer.add_child(UiTheme.label(
		"v0.3.0  /  WHISPERS BENEATH THE MASK",
		12,
		UiTheme.C_GOLD
	))


func _build_panel_content() -> VBoxContainer:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)

	content.add_child(UiTheme.label("雾都入口", 15, UiTheme.C_GOLD))
	var heading := UiTheme.label("假面低语", 48, UiTheme.C_TEXT)
	heading.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	content.add_child(heading)
	content.add_child(UiTheme.wrapped_label(
		"白天扮演凡人，黑夜偿还代价。进入第一场占卜家战斗，验证牌序、灵性与敌方压力。",
		16,
		UiTheme.C_PAPER
	))

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	content.add_child(divider)

	_status_label = UiTheme.label("正在检查本地进度……", 16, UiTheme.C_TEXT)
	content.add_child(_status_label)
	_summary_label = UiTheme.wrapped_label("", 14, UiTheme.C_MUTED)
	_summary_label.custom_minimum_size = Vector2(0, 66)
	content.add_child(_summary_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	_continue_button = UiTheme.button("继续上次战斗", _on_continue, false, 180)
	_new_game_button = UiTheme.button("开始新游戏", _on_new_game, true, 180)
	var quit_button := UiTheme.button("退出", _on_quit, true, 92)
	actions.add_child(_continue_button)
	actions.add_child(_new_game_button)
	actions.add_child(quit_button)

	content.add_child(UiTheme.wrapped_label(
		"提示：战斗不支持中途恢复；退出后会回到最近一次已确认的战后检查点。",
		13,
		UiTheme.C_DANGER_TEXT
	))
	return content


func _on_new_game() -> void:
	if _busy:
		return
	set_busy(true)
	new_game_requested.emit()


func _on_continue() -> void:
	if _busy or _checkpoint_status != "loaded":
		return
	set_busy(true)
	continue_requested.emit()


func _on_quit() -> void:
	if _busy:
		return
	quit_requested.emit()
