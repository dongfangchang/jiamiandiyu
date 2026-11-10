extends Control

signal hub_requested
signal retry_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const ChallengeCatalog := preload("res://src/ui/challenge_ui_catalog.gd")
const ChallengeSnapshotScript := preload("res://src/core/challenge_snapshot.gd")

var _snapshot_data: Dictionary = {}
var _reward_labels: Dictionary = {}
var _save_state := "pending"
var _eyebrow_label: Label
var _title_label: Label
var _detail_label: Label
var _reward_label: Label
var _save_label: Label
var _result_icon: TextureRect
var _retry_button: Button


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_show_empty()


func show_result(
	snapshot: ChallengeSnapshot,
	save_state: String = "pending"
) -> void:
	_snapshot_data = snapshot.to_dictionary() if snapshot != null else {}
	_save_state = save_state
	_render()


func set_save_state(save_state: String) -> void:
	_save_state = save_state
	_update_save_label()


func set_reward_labels(labels: Dictionary) -> void:
	_reward_labels = labels.duplicate(true)
	_update_reward_text()


func get_title_text() -> String:
	return _title_label.text if is_instance_valid(_title_label) else ""


func get_reward_text() -> String:
	return _reward_label.text if is_instance_valid(_reward_label) else ""


func get_save_text() -> String:
	return _save_label.text if is_instance_valid(_save_label) else ""


func is_retry_enabled() -> bool:
	return is_instance_valid(_retry_button) and not _retry_button.disabled


func get_background_path() -> String:
	return ChallengeCatalog.RESULT_BACKGROUND


func get_emblem_path() -> String:
	return ChallengeCatalog.challenge_emblem(
		String(_snapshot_data.get("challenge_id", ""))
	)


func _build() -> void:
	UiTheme.add_background(
		self,
		ChallengeCatalog.RESULT_BACKGROUND,
		UiTheme.C_BG,
		0.26
	)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 156)
	safe.add_theme_constant_override("margin_top", 76)
	safe.add_theme_constant_override("margin_right", 156)
	safe.add_theme_constant_override("margin_bottom", 66)
	add_child(safe)
	var panel := UiTheme.panel(Color(0.055, 0.059, 0.047, 0.97), UiTheme.C_GOLD)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(panel)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 44)
	pad.add_theme_constant_override("margin_top", 30)
	pad.add_theme_constant_override("margin_right", 44)
	pad.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	pad.add_child(column)
	_eyebrow_label = UiTheme.label(
		"值夜者档案 · 传承",
		12,
		UiTheme.C_GOLD
	)
	column.add_child(_eyebrow_label)
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 24)
	column.add_child(hero)
	_result_icon = TextureRect.new()
	_result_icon.custom_minimum_size = Vector2(120, 120)
	_result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.add_child(_result_icon)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	hero.add_child(heading)
	_title_label = UiTheme.label("挑战结算", 42, UiTheme.C_TEXT)
	heading.add_child(_title_label)
	heading.add_child(UiTheme.wrapped_label(
		"廷根的档案已经封存，留下的只有你带走的构筑与收藏。",
		15,
		UiTheme.C_MUTED
	))
	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)
	var detail_box := UiTheme.fixed_text("", 16, UiTheme.C_PAPER, 150)
	detail_box.name = "ChallengeResultDetail"
	detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_label = UiTheme.fixed_text_label(detail_box)
	column.add_child(detail_box)
	_reward_label = UiTheme.clip_label("", 16, UiTheme.C_GOLD)
	column.add_child(_reward_label)
	_save_label = UiTheme.clip_label("", 15, UiTheme.C_GOLD)
	column.add_child(_save_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	_retry_button = UiTheme.button("再次挑战", _on_retry, false, 156)
	actions.add_child(_retry_button)
	actions.add_child(UiTheme.button("返回白昼档案", _on_hub, true, 180))


func _render() -> void:
	var completed := String(
		_snapshot_data.get("challenge_outcome", "")
	) == "completed"
	_title_label.text = "挑战完成" if completed else "挑战中断"
	_title_label.add_theme_color_override(
		"font_color",
		UiTheme.C_GOLD if completed else UiTheme.C_DANGER_TEXT
	)
	_result_icon.texture = load(ChallengeCatalog.outcome_icon(completed))
	var challenge_id := String(_snapshot_data.get("challenge_id", ""))
	_eyebrow_label.text = (
		"邪神子嗣降临 · 传承"
		if challenge_id == "challenge.v070.broken_procession"
		else "安提哥努斯笔记案 · 传承"
	)
	var route: Dictionary = _snapshot_data.get("route", {})
	var run_state: Dictionary = route.get("run_state", {})
	var sequence: Dictionary = _snapshot_data.get("sequence", {})
	var selected: Dictionary = _snapshot_data.get("selected_modifier", {})
	var completed_ids: Array = route.get("completed_node_ids", [])
	var nodes: Array = route.get("nodes", [])
	_detail_label.text = (
		"挑战：%s\n修饰：%s\n路线节点：%d / %d\n"
		+ "路线：%s\n"
		+ "序列：占卜家 · %d「%s」\n"
		+ "剩余生命：%d / %d  ·  污染：%d / %d  ·  被注视：%d / %d"
	) % [
		String(_snapshot_data.get("display_name_zh", "值夜者档案")),
		String(selected.get("display_name_zh", "未记录")),
		completed_ids.size(),
		nodes.size(),
		ChallengeCatalog.route_name(String(_snapshot_data.get("route_id", ""))),
		int(sequence.get("current_sequence", 8)),
		String(sequence.get("next_sequence_name_zh", "小丑")),
		int(run_state.get("hp", 0)),
		int(run_state.get("max_hp", 0)),
		int(run_state.get("corruption", 0)),
		int(run_state.get("max_corruption", 10)),
		int(run_state.get("attention", 0)),
		int(run_state.get("max_attention", 10)),
	]
	if not completed:
		_detail_label.text += "\n\n挑战失败；局外收藏、卡牌等级与已确认奖励均已保留。"
	_update_reward_text()
	_update_save_label()
	_retry_button.disabled = false


func _update_reward_text() -> void:
	if not is_instance_valid(_reward_label):
		return
	var completed := String(
		_snapshot_data.get("challenge_outcome", "")
	) == "completed"
	if not completed:
		_reward_label.text = "挑战奖励：未发放 · 局外收藏保留"
		_reward_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT)
		return
	_reward_label.text = "挑战奖励：" + ChallengeCatalog.reward_text(
		_snapshot_data.get("completion_reward", {}),
		_reward_labels
	)
	_reward_label.add_theme_color_override("font_color", UiTheme.C_GOLD)


func _update_save_label() -> void:
	if not is_instance_valid(_save_label):
		return
	match _save_state:
		"saved":
			_save_label.text = "挑战检查点已保存。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_GOLD)
		"backup":
			_save_label.text = "主存档异常；备份检查点仍可读取。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT)
		"failed":
			_save_label.text = "挑战检查点保存失败；原始存档不会被覆盖。"
			_save_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT)
		_:
			_save_label.text = "正在写入挑战检查点……"
			_save_label.add_theme_color_override("font_color", UiTheme.C_MUTED)


func _show_empty() -> void:
	_title_label.text = "等待挑战结算"
	_detail_label.text = "值夜者档案尚未结束。"
	_reward_label.text = ""
	_save_label.text = ""
	_result_icon.texture = null
	_retry_button.disabled = true


func _on_retry() -> void:
	retry_requested.emit()


func _on_hub() -> void:
	hub_requested.emit()
