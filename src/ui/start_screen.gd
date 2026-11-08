extends Control

signal new_game_requested
signal continue_requested
signal challenge_requested
signal preferences_changed(preferences: Dictionary)
signal restore_backup_requested
signal feedback_submitted(feedback: Dictionary)
signal test_game_requested
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
var _settings_button: Button
var _restore_backup_button: Button
var _test_game_button: Button
var _preferences_status: Label
var _preferences: Dictionary = {}
var _preferences_initialized := false
var _backup_available := false
var _confirm_new_game: ConfirmationDialog
var _system_overlay: Control
var _tutorial_overlay: Control
var _feedback_overlay: Control
var _feedback_status: Label
var _feedback_text: TextEdit
var _feedback_stage: OptionButton
var _feedback_pacing: OptionButton
var _feedback_stuck: CheckButton
var _tutorial_step := 0
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
	error_message: String = "",
	preferences: Dictionary = {}
) -> void:
	_checkpoint_status = status
	_backup_available = bool(summary.get("backup_available", false))
	if not preferences.is_empty():
		_preferences = preferences.duplicate(true)
		_preferences_initialized = true
	if not is_instance_valid(_continue_button):
		return
	_busy = false
	_continue_button.disabled = status != "loaded"
	_new_game_button.disabled = false
	_version_label.text = "v%s  ·  本地离线原型" % String(
		ProjectSettings.get_setting("application/config/version", "0.11.0")
	)
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
			_version_label.text = "v%s  ·  本地离线原型" % String(
				ProjectSettings.get_setting(
					"application/config/version",
					"0.11.0"
				)
			)
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
	if is_instance_valid(_restore_backup_button):
		_restore_backup_button.disabled = _busy or not _backup_available
	if (
		_preferences_initialized
		and not bool(_preferences.get("tutorial_seen", false))
		and _tutorial_overlay == null
	):
		_open_tutorial()


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
	if is_instance_valid(_test_game_button):
		_test_game_button.disabled = _busy


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
		"v%s  ·  本地离线原型" % String(
			ProjectSettings.get_setting("application/config/version", "0.11.0")
		),
		11,
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
		"进入挑战档案",
		_on_challenge,
		false,
		0
	)
	_challenge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_row.add_child(_challenge_button)
	_challenge_hint = UiTheme.label("", 12, UiTheme.C_MUTED)
	_challenge_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	challenge_row.add_child(_challenge_hint)

	var system_row := HBoxContainer.new()
	system_row.add_theme_constant_override("separation", 12)
	content.add_child(system_row)
	_settings_button = UiTheme.button(
		"设置与玩法说明",
		_open_system_menu,
		true,
		0
	)
	_settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_row.add_child(_settings_button)
	_restore_backup_button = UiTheme.button(
		"恢复上次备份",
		_on_restore_backup,
		false,
		180
	)
	_restore_backup_button.disabled = true
	system_row.add_child(_restore_backup_button)
	_test_game_button = UiTheme.button(
		"测试档案",
		_on_test_game,
		true,
		128
	)
	_test_game_button.tooltip_text = "解锁全部卡牌、资源和挑战，用于发布前测试"
	system_row.add_child(_test_game_button)
	_preferences_status = UiTheme.label("", 12, UiTheme.C_MUTED)
	content.add_child(_preferences_status)

	content.add_child(UiTheme.wrapped_label(
		"提示：战斗不支持中途恢复；退出后会回到最近一次已确认的战后检查点。",
		13,
		UiTheme.C_DANGER_TEXT
	))
	return content


func _on_new_game() -> void:
	if _busy:
		return
	if _checkpoint_status == "loaded":
		_open_new_game_confirmation()
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


func _open_new_game_confirmation() -> void:
	if not is_instance_valid(_confirm_new_game):
		_confirm_new_game = ConfirmationDialog.new()
		_confirm_new_game.title = "覆盖当前进度？"
		_confirm_new_game.dialog_text = (
			"开始新游戏会从下一检查点起覆盖当前存档。"
			+ "最近一次备份会保留，但可能不是最新进度。"
		)
		_confirm_new_game.ok_button_text = "开始新游戏"
		_confirm_new_game.cancel_button_text = "取消"
		_confirm_new_game.confirmed.connect(func() -> void:
			set_busy(true)
			new_game_requested.emit()
		)
		add_child(_confirm_new_game)
	_confirm_new_game.popup_centered()


func _on_restore_backup() -> void:
	if _busy or not _backup_available:
		return
	restore_backup_requested.emit()


func _on_test_game() -> void:
	if _busy:
		return
	set_busy(true)
	test_game_requested.emit()


func show_backup_restore_result(success: bool, message: String) -> void:
	if not is_instance_valid(_preferences_status):
		return
	_preferences_status.text = (
		("备份已恢复。" if success else "恢复失败：") + message
	)
	_preferences_status.add_theme_color_override(
		"font_color",
		UiTheme.C_PAPER if success else UiTheme.C_DANGER_TEXT
	)


func show_preferences_save_state(success: bool, message: String = "") -> void:
	if not is_instance_valid(_preferences_status):
		return
	_preferences_status.text = (
		"设置已保存。" if success else "设置保存失败：" + message
	)
	_preferences_status.add_theme_color_override(
		"font_color",
		UiTheme.C_MUTED if success else UiTheme.C_DANGER_TEXT
	)


func _open_system_menu() -> void:
	if is_instance_valid(_system_overlay):
		_system_overlay.queue_free()
		_system_overlay = null
	var overlay := ColorRect.new()
	overlay.color = Color(0.015, 0.018, 0.014, 0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_system_overlay = overlay

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var content := VBoxContainer.new()
	var panel := UiTheme.padded_panel(
		content,
		24,
		Color(0.055, 0.06, 0.048, 0.99),
		UiTheme.C_GOLD
	)
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	content.add_theme_constant_override("separation", 14)
	content.add_child(UiTheme.label("设置与玩法说明", 30, UiTheme.C_TEXT))
	content.add_child(UiTheme.wrapped_label(
		"身份决定一项资源或战斗修正；八张牌组决定可用手段。"
		+ "战斗中会提升污染与被注视，休息和仪式用于控制风险。",
		15,
		UiTheme.C_PAPER
	))

	var fullscreen := CheckButton.new()
	fullscreen.text = "全屏显示"
	fullscreen.button_pressed = bool(_preferences.get("fullscreen", false))
	fullscreen.toggled.connect(func(enabled: bool) -> void:
		_preferences["fullscreen"] = enabled
		preferences_changed.emit(_preferences.duplicate(true))
	)
	content.add_child(fullscreen)

	var reduce_flash := CheckButton.new()
	reduce_flash.text = "减少闪烁与高对比反馈"
	reduce_flash.button_pressed = bool(_preferences.get("reduce_flash", false))
	reduce_flash.toggled.connect(func(enabled: bool) -> void:
		_preferences["reduce_flash"] = enabled
		preferences_changed.emit(_preferences.duplicate(true))
	)
	content.add_child(reduce_flash)

	var scale_row := HBoxContainer.new()
	content.add_child(scale_row)
	scale_row.add_child(UiTheme.label("界面缩放", 16, UiTheme.C_TEXT))
	var scale_option := OptionButton.new()
	scale_option.add_item("90%")
	scale_option.add_item("100%")
	scale_option.add_item("110%")
	var scale_values: Array[float] = [0.9, 1.0, 1.1]
	var current_scale := float(_preferences.get("ui_scale", 1.0))
	scale_option.select(_nearest_index(scale_values, current_scale))
	scale_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_option.item_selected.connect(func(index: int) -> void:
		_preferences["ui_scale"] = scale_values[clampi(index, 0, 2)]
		preferences_changed.emit(_preferences.duplicate(true))
	)
	scale_row.add_child(scale_option)

	content.add_child(UiTheme.wrapped_label(
		"操作：鼠标选择手牌与目标；Esc 取消当前选择。"
		+ "\n检查点：仅在节点或战斗结算后保存，战斗中退出会回到最近检查点。"
		+ "\n存档位置：Godot 的 user://saves；设置与引导状态保存在 user://preferences.json。",
		14,
		UiTheme.C_MUTED
	))
	content.add_child(UiTheme.button(
		"重新查看新手引导",
		_open_tutorial,
		false,
		220
	))
	content.add_child(UiTheme.button(
		"记录试玩反馈",
		_open_feedback_form,
		false,
		220
	))
	var close := UiTheme.button("关闭", _close_system_menu, true, 120)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	content.add_child(close)


func _close_system_menu() -> void:
	if is_instance_valid(_system_overlay):
		_system_overlay.queue_free()
		_system_overlay = null


func _open_feedback_form() -> void:
	if is_instance_valid(_system_overlay):
		_close_system_menu()
	if is_instance_valid(_feedback_overlay):
		_feedback_overlay.queue_free()
	var overlay := ColorRect.new()
	overlay.color = Color(0.015, 0.018, 0.014, 0.9)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_feedback_overlay = overlay
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var content := VBoxContainer.new()
	var panel := UiTheme.padded_panel(
		content,
		24,
		Color(0.055, 0.06, 0.048, 0.99),
		UiTheme.C_GOLD
	)
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	content.add_theme_constant_override("separation", 12)
	content.add_child(UiTheme.label("记录试玩反馈", 28, UiTheme.C_TEXT))
	content.add_child(UiTheme.wrapped_label(
		"反馈只保存在本机。不会上传文本、输入记录或系统信息。",
		13,
		UiTheme.C_MUTED
	))
	var text := TextEdit.new()
	text.custom_minimum_size = Vector2(0, 190)
	text.placeholder_text = "哪里有趣、哪里卡住、节奏是否合适……"
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_child(text)
	_feedback_text = text
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 12)
	content.add_child(options)
	var stage := OptionButton.new()
	for label in ["整体", "牌组", "战斗", "抽卡与升级", "路线与仪式", "挑战"]:
		stage.add_item(label)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_child(stage)
	_feedback_stage = stage
	var pacing := OptionButton.new()
	for label in ["节奏合适", "节奏偏快", "节奏偏慢"]:
		pacing.add_item(label)
	pacing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_child(pacing)
	_feedback_pacing = pacing
	var stuck := CheckButton.new()
	stuck.text = "当前有卡住或无法继续"
	content.add_child(stuck)
	_feedback_stuck = stuck
	_feedback_status = UiTheme.label("", 13, UiTheme.C_MUTED)
	content.add_child(_feedback_status)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	actions.add_child(UiTheme.button(
		"取消",
		_close_feedback_form,
		false,
		100
	))
	actions.add_child(UiTheme.button(
		"保存反馈",
		_submit_feedback,
		true,
		140
	))


func _submit_feedback() -> void:
	if not is_instance_valid(_feedback_text):
		return
	var feedback := {
		"text": _feedback_text.text,
		"stage": _feedback_stage_id(_feedback_stage.selected),
		"stuck": _feedback_stuck.button_pressed,
		"pacing": _feedback_pacing_id(_feedback_pacing.selected),
	}
	if String(feedback.text).strip_edges().is_empty():
		_feedback_status.text = "请先写下一句反馈。"
		_feedback_status.add_theme_color_override(
			"font_color",
			UiTheme.C_DANGER_TEXT
		)
		return
	feedback_submitted.emit(feedback)


func _close_feedback_form() -> void:
	if is_instance_valid(_feedback_overlay):
		_feedback_overlay.queue_free()
		_feedback_overlay = null
	_feedback_status = null
	_feedback_text = null
	_feedback_stage = null
	_feedback_pacing = null
	_feedback_stuck = null


func show_feedback_save_state(success: bool, message: String) -> void:
	if not is_instance_valid(_feedback_status):
		return
	_feedback_status.text = (
		"反馈已保存。" if success else "反馈保存失败：" + message
	)
	_feedback_status.add_theme_color_override(
		"font_color",
		UiTheme.C_PAPER if success else UiTheme.C_DANGER_TEXT
	)
	if success:
		get_tree().create_timer(0.8).timeout.connect(_close_feedback_form)


func _feedback_stage_id(index: int) -> String:
	var ids := ["overall", "deck", "battle", "growth", "route", "challenge"]
	return ids[clampi(index, 0, ids.size() - 1)]


func _feedback_pacing_id(index: int) -> String:
	var ids := ["good", "too_fast", "too_slow"]
	return ids[clampi(index, 0, ids.size() - 1)]


func _open_tutorial() -> void:
	if is_instance_valid(_system_overlay):
		_close_system_menu()
	if is_instance_valid(_tutorial_overlay):
		_tutorial_overlay.queue_free()
	_tutorial_step = 0
	var overlay := ColorRect.new()
	overlay.color = Color(0.015, 0.018, 0.014, 0.9)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_tutorial_overlay = overlay
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var content := VBoxContainer.new()
	var panel := UiTheme.padded_panel(
		content,
		28,
		Color(0.055, 0.06, 0.048, 0.99),
		UiTheme.C_GOLD
	)
	panel.custom_minimum_size = Vector2(780, 360)
	center.add_child(panel)
	content.add_theme_constant_override("separation", 16)
	content.add_child(UiTheme.label("首次游玩指引", 16, UiTheme.C_GOLD))
	var body := UiTheme.wrapped_label("", 20, UiTheme.C_TEXT)
	body.custom_minimum_size = Vector2(0, 190)
	body.set_meta("tutorial_body", true)
	content.add_child(body)
	var progress := UiTheme.label("", 13, UiTheme.C_MUTED)
	progress.set_meta("tutorial_progress", true)
	content.add_child(progress)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	actions.add_child(UiTheme.button("跳过", _finish_tutorial, false, 100))
	actions.add_child(UiTheme.button("下一步", _advance_tutorial, true, 120))
	_update_tutorial_view()


func _advance_tutorial() -> void:
	_tutorial_step += 1
	if _tutorial_step >= _tutorial_steps().size():
		_finish_tutorial()
		return
	_update_tutorial_view()


func _update_tutorial_view() -> void:
	if not is_instance_valid(_tutorial_overlay):
		return
	var steps := _tutorial_steps()
	var body := _find_meta_node(_tutorial_overlay, "tutorial_body") as Label
	var progress := _find_meta_node(_tutorial_overlay, "tutorial_progress") as Label
	if body != null:
		body.text = steps[clampi(_tutorial_step, 0, steps.size() - 1)]
	if progress != null:
		progress.text = "%d / %d" % [_tutorial_step + 1, steps.size()]


func _finish_tutorial() -> void:
	if is_instance_valid(_tutorial_overlay):
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null
	_preferences["tutorial_seen"] = true
	preferences_changed.emit(_preferences.duplicate(true))


func _tutorial_steps() -> Array[String]:
	return [
		"选择一项白昼身份。身份会改变一项战斗或资源倾向。",
		"从收藏中确认一套八张唯一卡牌。抽到的新卡会进入收藏，升级效果会带入战斗。",
		"战斗中使用灵性打出卡牌，选择三列中的敌人并结束回合。",
		"污染与被注视会改变路线风险。休息时在即时生命和下一战资源之间取舍。",
		"首领战后完成短仪式即可晋升。检查点只在安全边界保存。",
	]


func _find_meta_node(root: Node, key: String) -> Node:
	for child in root.get_children():
		if bool(child.get_meta(key, false)):
			return child
		var nested := _find_meta_node(child, key)
		if nested != null:
			return nested
	return null


func _nearest_index(values: Array[float], target: float) -> int:
	var best_index := 0
	var best_distance := absf(values[0] - target)
	for index in range(1, values.size()):
		var distance := absf(values[index] - target)
		if distance < best_distance:
			best_index = index
			best_distance = distance
	return best_index


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
