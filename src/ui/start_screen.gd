extends Control

signal new_game_requested
signal continue_requested
signal challenge_requested
signal quit_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const TITLE_BACKGROUND := "res://assets/game/scenes/title-screen.png"

var _continue_button: Button
var _new_game_button: Button
var _status_label: Label
var _summary_label: Label
var _version_label: Label
var _challenge_button: Button
var _challenge_hint: Label
var _busy := false
var _checkpoint_status := "none"
var _challenge_available := false


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
	_version_label.text = "本地原型  /  WHISPERS BENEATH THE MASK"
	match status:
		"loaded":
			_continue_button.disabled = false
			_status_label.text = "检测到可继续的检查点"
			var last_battle: Dictionary = summary.get("last_battle", {})
			var identity_name := _identity_name(String(summary.get("identity_id", "")))
			var tickets := _optional_int(summary, ["divination_tickets"])
			var collection_count := _optional_int(
				summary,
				["collection_count", "owned_card_count", "unique_owned_count"]
			)
			var pity_current := _optional_int(summary, ["pity_counter", "rare_pity_counter"])
			var pity_limit := _optional_int(summary, ["rare_pity", "pity_limit"])
			var content_version := String(summary.get("content_version", ""))
			if not content_version.is_empty():
				_version_label.text = content_version + "  /  WHISPERS BENEATH THE MASK"
			set_challenge_available(
				bool(summary.get("challenge_available", false)),
				String(summary.get("challenge_reason", ""))
			)
			_summary_label.text = (
				"身份：%s  ·  序列 %d  ·  牌组 %d 张\n"
				+ "占卜券：%s  ·  稀有保底：%s\n"
				+ "收藏：%s\n"
				+ "上一场：%s / 第 %d 回合  ·  保存于 %s"
			) % [
				identity_name,
				int(summary.get("sequence", 0)),
				int(summary.get("deck_size", 0)),
				_format_value(tickets),
				_format_pity(pity_current, pity_limit),
				_format_value(collection_count),
				_outcome_text(String(last_battle.get("outcome", ""))),
				int(last_battle.get("round_number", 0)),
				String(summary.get("created_at", "未知")),
			]
		"corrupt":
			_continue_button.disabled = true
			set_challenge_available(false, "检查点不可读取")
			_status_label.text = "检查点无法读取"
			_summary_label.text = "原始存档已保留。" + (
				"\n" + error_message if not error_message.is_empty() else ""
			)
		_:
			_continue_button.disabled = true
			set_challenge_available(false, "完成序列 8 晋升后开放")
			_status_label.text = "尚未建立检查点"
			_summary_label.text = (
				"身份：未选择  ·  占卜券：3（新游戏初始）\n"
				+ "开始新游戏以选择白昼身份。战斗中退出会回到最近检查点。"
			)


func get_summary_text() -> String:
	return _summary_label.text if is_instance_valid(_summary_label) else ""


func get_version_text() -> String:
	return _version_label.text if is_instance_valid(_version_label) else ""


func set_busy(busy: bool) -> void:
	_busy = busy
	if is_instance_valid(_continue_button):
		_continue_button.disabled = _busy or _checkpoint_status != "loaded"
	if is_instance_valid(_new_game_button):
		_new_game_button.disabled = _busy
	if is_instance_valid(_challenge_button):
		_challenge_button.disabled = _busy or not _challenge_available


func is_continue_enabled() -> bool:
	return is_instance_valid(_continue_button) and not _continue_button.disabled


func set_challenge_available(available: bool, reason: String = "") -> void:
	_challenge_available = available
	if is_instance_valid(_challenge_button):
		_challenge_button.disabled = _busy or not available
	if is_instance_valid(_challenge_hint):
		_challenge_hint.text = (
			"可重复挑战已解锁。"
			if available
			else (
				reason
				if not reason.is_empty()
				else "完成序列 8 晋升后开放"
			)
		)


func is_challenge_enabled() -> bool:
	return is_instance_valid(_challenge_button) and not _challenge_button.disabled


func get_challenge_hint_text() -> String:
	return _challenge_hint.text if is_instance_valid(_challenge_hint) else ""


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
	_version_label = UiTheme.label(
		"本地原型  /  WHISPERS BENEATH THE MASK",
		12,
		UiTheme.C_GOLD
	)
	footer.add_child(_version_label)


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
	_summary_label.custom_minimum_size = Vector2(0, 112)
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

	var challenge_row := HBoxContainer.new()
	challenge_row.add_theme_constant_override("separation", 12)
	content.add_child(challenge_row)
	_challenge_button = UiTheme.button(
		"进入挑战 · 镜厅余响",
		_on_challenge,
		false,
		0
	)
	_challenge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_row.add_child(_challenge_button)
	_challenge_hint = UiTheme.label("", 12, UiTheme.C_MUTED)
	_challenge_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	challenge_row.add_child(_challenge_hint)

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


func _on_challenge() -> void:
	if _busy or not _challenge_available:
		return
	set_busy(true)
	challenge_requested.emit()


func _on_quit() -> void:
	if _busy:
		return
	quit_requested.emit()


func _identity_name(identity_id: String) -> String:
	match identity_id:
		"identity.reporter":
			return "记者"
		"identity.doctor":
			return "医生"
		"identity.gravedigger":
			return "守墓人"
		"":
			return "未选择"
		_:
			return identity_id


func _outcome_text(outcome: String) -> String:
	match outcome:
		"victory":
			return "胜利"
		"defeat":
			return "失败"
		"":
			return "暂无战斗记录"
		_:
			return outcome


func _optional_int(summary: Dictionary, keys: Array[String]) -> int:
	for key in keys:
		if summary.has(key):
			return int(summary[key])
	return -1


func _format_value(value: int) -> String:
	return str(value) if value >= 0 else "摘要未提供"


func _format_pity(current: int, limit: int) -> String:
	if current >= 0 and limit > 0:
		return "%d/%d" % [current, limit]
	if current >= 0:
		return str(current)
	if limit > 0:
		return "上限 %d" % limit
	return "摘要未提供"
