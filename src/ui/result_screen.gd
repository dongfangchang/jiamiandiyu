extends Control

signal return_to_title_requested
signal retry_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")

var _result_label: Label
var _detail_label: Label
var _save_label: Label
var _return_button: Button
var _retry_button: Button
var _last_snapshot: BattleSnapshot
var _last_save_status := ""


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()


func show_result(
	snapshot: BattleSnapshot,
	encounter_title: String = "首场战斗",
	save_status: String = "pending",
	save_message: String = ""
) -> void:
	_last_snapshot = snapshot
	_last_save_status = save_status
	var data := snapshot.to_dictionary() if snapshot != null else {}
	var outcome := String(data.get("outcome", ""))
	var victory := outcome == "victory"
	_result_label.text = "胜利" if victory else "失败"
	_result_label.add_theme_color_override(
		"font_color",
		UiTheme.C_GOLD if victory else UiTheme.C_DANGER_TEXT
	)
	_detail_label.text = "%s\n结束于第 %d 回合 / 上限 %d\n原因：%s" % [
		encounter_title,
		int(data.get("round_number", 0)),
		int(data.get("max_rounds", 0)),
		_reason_text(String(data.get("outcome_reason", ""))),
	]
	_apply_save_status(save_status, save_message)
	_retry_button.text = "返回白昼档案"
	_retry_button.disabled = false
	_return_button.disabled = false


func set_save_status(save_status: String, save_message: String = "") -> void:
	_last_save_status = save_status
	_apply_save_status(save_status, save_message)


func get_result_text() -> String:
	return _result_label.text if is_instance_valid(_result_label) else ""


func get_save_text() -> String:
	return _save_label.text if is_instance_valid(_save_label) else ""


func get_retry_text() -> String:
	return _retry_button.text if is_instance_valid(_retry_button) else ""


func is_return_enabled() -> bool:
	return is_instance_valid(_return_button) and not _return_button.disabled


func _build() -> void:
	UiTheme.add_background(self, "res://assets/game/scenes/title-screen.png", UiTheme.C_BG, 0.86)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 100)
	safe.add_theme_constant_override("margin_top", 88)
	safe.add_theme_constant_override("margin_right", 100)
	safe.add_theme_constant_override("margin_bottom", 76)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	safe.add_child(column)
	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(top_spacer)

	var card := UiTheme.padded_panel(
		_build_card_content(),
		28,
		Color(0.055, 0.06, 0.047, 0.97),
		UiTheme.C_GOLD
	)
	card.custom_minimum_size = Vector2(760, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(card)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(bottom_spacer)
	column.add_child(UiTheme.center_label(
		"战斗结束后只保存检查点；退出页面不会保存战斗中间状态。",
		13,
		UiTheme.C_MUTED
	))


func _build_card_content() -> VBoxContainer:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.add_child(UiTheme.label("战后档案", 13, UiTheme.C_GOLD))
	_result_label = UiTheme.label("等待结算", 56, UiTheme.C_TEXT)
	content.add_child(_result_label)
	_detail_label = UiTheme.wrapped_label("", 16, UiTheme.C_PAPER)
	_detail_label.custom_minimum_size = Vector2(0, 128)
	content.add_child(_detail_label)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	content.add_child(divider)
	_save_label = UiTheme.wrapped_label("检查点尚未确认。", 15, UiTheme.C_DANGER_TEXT)
	content.add_child(_save_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	_retry_button = UiTheme.button("再进行一场", _on_retry, true, 170)
	_return_button = UiTheme.button("返回标题", _on_return, true, 170)
	actions.add_child(_retry_button)
	actions.add_child(_return_button)
	_retry_button.disabled = true
	_return_button.disabled = true
	return content


func _apply_save_status(save_status: String, save_message: String) -> void:
	if not is_instance_valid(_save_label):
		return
	match save_status:
		"saved":
			_save_label.text = "战后检查点已保存。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_GOLD)
		"already_saved":
			_save_label.text = "战后检查点已经存在，无需重复写入。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_GOLD)
		"failed":
			_save_label.text = "检查点写入失败。" + (
				"\n" + save_message if not save_message.is_empty() else ""
			)
			_save_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT)
		_:
			_save_label.text = "等待保存确认；应用确认前不会宣称进度已保存。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_MUTED)


func _reason_text(reason: String) -> String:
	match reason:
		"enemies_defeated":
			return "所有敌人已被击败"
		"player_died":
			return "生命降至 0"
		"round_limit":
			return "达到回合上限"
		"":
			return "规则层未提供原因"
		_:
			return "未识别的结束原因；请查看诊断记录"


func _on_return() -> void:
	_return_button.disabled = true
	return_to_title_requested.emit()


func _on_retry() -> void:
	_retry_button.disabled = true
	retry_requested.emit()
