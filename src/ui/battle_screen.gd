extends Control

signal command_requested(command: BattleCommand)
signal selection_changed(card_instance_id: StringName, target_id: StringName)
signal battle_finished(snapshot: BattleSnapshot)
signal exit_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleCommandResultScript := preload("res://src/core/battle_command_result.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")

const PHASE_NAMES := {
	"round_start": "回合开始",
	"player_action": "玩家行动",
	"enemy_action": "敌方行动",
	"battle_ended": "战斗结束",
	"init_error": "初始化错误",
}

const REASON_NAMES := {
	"playable": "可以打出",
	"wrong_phase": "当前不是玩家行动阶段",
	"card_not_in_hand": "这张牌已不在手牌中",
	"insufficient_spirit": "灵性不足",
	"invalid_target": "目标无效或尚未选择",
	"battle_ended": "战斗已经结束",
	"invalid_command": "命令无效",
	"ok": "命令已完成",
}

const BATTLE_BACKGROUND := "res://assets/game/v0.3.0/scenes/battle-tingen-old-house.png"
const ENEMY_ART_BY_DEFINITION := {
	&"enemy.weeping_tenant": "res://assets/game/v0.3.0/enemies/enemy-weeping-tenant.png",
	&"enemy.candle_moth": "res://assets/game/v0.3.0/enemies/enemy-candle-moth.png",
	&"enemy.mirror_hound": "res://assets/game/v0.3.0/enemies/enemy-mirror-hound.png",
	&"enemy.mirror_hound_echo": "res://assets/game/v0.3.0/enemies/enemy-mirror-hound.png",
	&"enemy.mirror_baron": "res://assets/game/v0.5.0/enemies/enemy-mirror-baron.png",
}
const CARD_ART_BY_DEFINITION := {
	&"card.skill.ink_dart": "res://assets/game/v0.3.0/cards/card-skill-ink-dart.png",
	&"card.skill.paper_guard": "res://assets/game/v0.3.0/cards/card-skill-paper-guard.png",
	&"card.skill.calm_breath": "res://assets/game/v0.3.0/cards/card-skill-calm-breath.png",
	&"card.skill.focus": "res://assets/game/v0.3.0/cards/card-skill-focus.png",
	&"card.skill.insight": "res://assets/game/v0.3.0/cards/card-skill-insight.png",
	&"card.skill.omen": "res://assets/game/v0.3.0/cards/card-skill-omen.png",
	&"card.skill.whisper": "res://assets/game/v0.3.0/cards/card-skill-whisper.png",
	&"card.skill.second_look": "res://assets/game/v0.3.0/cards/card-skill-second-look.png",
	&"card.skill.dream_question": "res://assets/game/v0.13.0/cards/card_skill_dream_question.png",
	&"card.skill.mirror_ward": "res://assets/game/v0.13.0/cards/card_skill_mirror_ward.png",
	&"card.skill.severed_string": "res://assets/game/v0.13.0/cards/card_skill_severed_string.png",
	&"card.skill.last_rites": "res://assets/game/v0.13.0/cards/card_skill_last_rites.png",
}
const STATUS_ICON_BASE := "res://assets/game/v0.3.0/status/"

var _snapshot: BattleSnapshot
var _revision := -1
var _pending := false
var _selection_card_id: StringName = &""
var _selection_target_id: StringName = &""
var _last_playability: BattlePlayability
var _playability_handler: Callable
var _card_labels: Dictionary = {}
var _card_details: Dictionary = {}
var _enemy_labels: Dictionary = {}
var _encounter_title := "首场战斗"
var _events: Array[String] = []
var _outcome_emitted := false
var _exit_emitted := false

var _encounter_label: Label
var _phase_label: Label
var _round_label: Label
var _pressure_label: Label
var _chain_label: Label
var _pile_label: Label
var _status_label: Label
var _health_meter: VBoxContainer
var _spirit_meter: VBoxContainer
var _corruption_meter: VBoxContainer
var _attention_meter: VBoxContainer
var _lanes_row: HBoxContainer
var _hand_row: HBoxContainer
var _event_list: VBoxContainer
var _play_button: Button
var _cancel_button: Button
var _end_turn_button: Button
var _selection_label: Label
var _selection_action_button: Button
var _meter_value_labels: Dictionary = {}
var _effects_layer: Control
var _exit_button: Button
var _exit_confirmation: ConfirmationDialog
var _visual_effect_count := 0
var _screen_scroll: ScrollContainer
var _content_root: Control


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_refresh_controls()


func configure(
	encounter_title: String,
	card_labels: Dictionary,
	enemy_labels: Dictionary,
	query_playability_handler: Callable,
	card_details: Dictionary = {}
) -> void:
	_encounter_title = encounter_title if not encounter_title.is_empty() else "首场战斗"
	_card_labels = card_labels.duplicate(true)
	_card_details = card_details.duplicate(true)
	_enemy_labels = enemy_labels.duplicate(true)
	_playability_handler = query_playability_handler
	if is_instance_valid(_encounter_label):
		_encounter_label.text = _encounter_title
	if _snapshot != null:
		_render_snapshot()


func apply_snapshot(snapshot: BattleSnapshot) -> void:
	if snapshot == null:
		return
	var snapshot_data := snapshot.to_dictionary()
	var incoming_revision := int(snapshot_data.get("revision", 0))
	if incoming_revision < _revision:
		return
	_revision = incoming_revision
	_snapshot = BattleSnapshotScript.new(snapshot_data)
	_pending = false
	_last_playability = null
	if (
		not _selection_card_id.is_empty()
		and _find_hand_card(_selection_card_id).is_empty()
	):
		_selection_card_id = &""
		_selection_target_id = &""
	_render_snapshot()
	_status_label.text = _snapshot_hint()
	_refresh_controls()


func apply_command_result(result: BattleCommandResult) -> void:
	_pending = false
	if result == null:
		_status_label.text = "未收到有效命令结果。"
		_refresh_controls()
		return
	if result.accepted:
		_selection_card_id = &""
		_selection_target_id = &""
	for event in result.events:
		_append_event(_format_event(event))
		_play_event_feedback(event)
	if result.snapshot != null:
		apply_snapshot(result.snapshot)
		var outcome := String(result.snapshot.data.get("outcome", ""))
		if not outcome.is_empty() and not _outcome_emitted:
			_outcome_emitted = true
			battle_finished.emit(result.snapshot)
	if not result.accepted:
		_status_label.text = _reason_text(result.reason_code)
	else:
		_status_label.text = "命令已完成。"
	_refresh_controls()


func set_pending(value: bool) -> void:
	_pending = value
	if _pending:
		_status_label.text = "正在等待结算……"
	_refresh_controls()


func is_pending() -> bool:
	return _pending


func get_selected_card_id() -> StringName:
	return _selection_card_id


func get_selected_target_id() -> StringName:
	return _selection_target_id


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_event_count() -> int:
	return _events.size()


func get_snapshot_data() -> Dictionary:
	return _snapshot.to_dictionary() if _snapshot != null else {}


func get_background_path() -> String:
	return BATTLE_BACKGROUND


func get_enemy_art_path(definition_id: StringName) -> String:
	return String(ENEMY_ART_BY_DEFINITION.get(definition_id, ""))


func get_card_art_path(definition_id: StringName) -> String:
	var direct := String(CARD_ART_BY_DEFINITION.get(definition_id, ""))
	return direct if not direct.is_empty() else ProgressionCatalog.card_art(String(definition_id))


func get_card_effect_text(definition_id: StringName) -> String:
	var details_value: Variant = _card_details.get(String(definition_id), {})
	if details_value is Dictionary:
		return String(details_value.get("effect_text", ""))
	return ""


func get_visual_effect_count() -> int:
	return _visual_effect_count


func get_chain_text() -> String:
	return _chain_label.text if is_instance_valid(_chain_label) else ""


func is_exit_confirmation_visible() -> bool:
	return (
		is_instance_valid(_exit_confirmation)
		and _exit_confirmation.visible
	)


func get_status_icon_path(icon_id: String) -> String:
	return STATUS_ICON_BASE.path_join("status-" + icon_id + ".png")


func select_card_instance(card_instance_id: StringName) -> void:
	if _pending or _snapshot == null:
		return
	var card := _find_hand_card(card_instance_id)
	if card.is_empty():
		_show_playability(BattlePlayability.new(false, BattlePlayability.CARD_NOT_IN_HAND))
		return
	if _selection_card_id == card_instance_id:
		cancel_selection()
		return
	_selection_card_id = card_instance_id
	_selection_target_id = &""
	_last_playability = null
	selection_changed.emit(_selection_card_id, _selection_target_id)
	if String(card.get("target_type", "none")) == "enemy":
		_status_label.text = "已选择「%s」；请选择敌方列。" % _card_name(StringName(card["definition_id"]))
	else:
		_query_current_playability()
	_refresh_hand_selection()
	_refresh_selection()
	_refresh_controls()


func select_target(enemy_id: StringName) -> void:
	if _pending or _selection_card_id.is_empty():
		return
	_selection_target_id = enemy_id
	selection_changed.emit(_selection_card_id, _selection_target_id)
	_query_current_playability()
	_refresh_selection()
	_refresh_controls()


func cancel_selection() -> void:
	_selection_card_id = &""
	_selection_target_id = &""
	_last_playability = null
	if is_instance_valid(_status_label):
		_status_label.text = "已取消选择。"
	selection_changed.emit(&"", &"")
	_refresh_hand_selection()
	_refresh_selection()
	_refresh_controls()


func play_selected() -> void:
	if _pending or _selection_card_id.is_empty():
		return
	_query_current_playability()
	if _last_playability == null or not _last_playability.playable:
		if _last_playability != null:
			_show_playability(_last_playability)
		return
	set_pending(true)
	var command := BattleCommandScript.play_card(
		_selection_card_id,
		_selection_target_id
	)
	command_requested.emit(command)


func end_turn() -> void:
	if _pending or not _is_player_action_phase():
		if not _pending:
			_status_label.text = "当前阶段不能结束回合。"
		return
	set_pending(true)
	command_requested.emit(BattleCommandScript.end_turn())


func _build() -> void:
	UiTheme.add_background(self, BATTLE_BACKGROUND, UiTheme.C_BG, 0.58)
	_effects_layer = Control.new()
	_effects_layer.name = "EffectsLayer"
	_effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effects_layer.z_index = 50
	add_child(_effects_layer)

	_screen_scroll = ScrollContainer.new()
	_screen_scroll.name = "BattlePageScroll"
	_screen_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_screen_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_screen_scroll.follow_focus = true
	add_child(_screen_scroll)
	_content_root = Control.new()
	_content_root.name = "BattlePageContent"
	_content_root.custom_minimum_size = Vector2(1600, 900)
	_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_scroll.add_child(_content_root)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 24)
	safe.add_theme_constant_override("margin_top", 18)
	safe.add_theme_constant_override("margin_right", 24)
	safe.add_theme_constant_override("margin_bottom", 18)
	_content_root.add_child(safe)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	safe.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_status_strip())

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	root.add_child(middle)

	var battlefield := UiTheme.panel(Color("#171711"), UiTheme.C_LINE)
	battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield.size_flags_stretch_ratio = 2.8
	middle.add_child(battlefield)
	_build_battlefield(battlefield)

	var side := UiTheme.panel(UiTheme.C_SURFACE, UiTheme.C_LINE)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.0
	middle.add_child(side)
	_build_side_panel(side)

	var hand := UiTheme.panel(UiTheme.C_SURFACE, UiTheme.C_GOLD)
	hand.custom_minimum_size = Vector2(0, 292)
	root.add_child(hand)
	_build_hand_panel(hand)


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override("separation", 2)
	row.add_child(title_block)
	_encounter_label = UiTheme.label(_encounter_title, 25, UiTheme.C_TEXT)
	title_block.add_child(_encounter_label)
	_phase_label = UiTheme.label("等待战斗快照", 12, UiTheme.C_MUTED)
	title_block.add_child(_phase_label)
	_pile_label = UiTheme.label("牌堆 —  ·  弃牌 —", 12, UiTheme.C_MUTED)
	title_block.add_child(_pile_label)

	_health_meter = _meter_with_value("生命", "—", UiTheme.C_TEXT, "health")
	_spirit_meter = _meter_with_value("灵性", "—", UiTheme.C_GOLD, "spirit")
	_corruption_meter = _meter_with_value("污染", "—", UiTheme.C_DANGER_TEXT, "corruption")
	_attention_meter = _meter_with_value("被注视", "—", UiTheme.C_DANGER_TEXT, "attention")
	row.add_child(_health_meter)
	row.add_child(_spirit_meter)
	row.add_child(_corruption_meter)
	row.add_child(_attention_meter)

	_round_label = UiTheme.badge("回合 — / —", UiTheme.C_GOLD, UiTheme.C_GOLD)
	_pressure_label = UiTheme.badge("敌方压力 +0", UiTheme.C_MUTED, UiTheme.C_LINE)
	row.add_child(_round_label)
	var pressure_group := HBoxContainer.new()
	pressure_group.add_theme_constant_override("separation", 5)
	var pressure_icon := _status_icon("attack", 20)
	pressure_group.add_child(pressure_icon)
	pressure_group.add_child(_pressure_label)
	row.add_child(pressure_group)
	_end_turn_button = UiTheme.button("结束回合", end_turn, false, 126, true)
	row.add_child(_end_turn_button)
	_exit_button = UiTheme.button("退出战斗", _request_exit, true, 112)
	row.add_child(_exit_button)
	return row


func _build_status_strip() -> Control:
	var strip := UiTheme.padded_panel(
		UiTheme.wrapped_label("等待战斗初始化。", 15, UiTheme.C_TEXT),
		10,
		Color("#252118"),
		UiTheme.C_LINE
	)
	_status_label = strip.get_child(0).get_child(0) as Label
	return strip


func _build_battlefield(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(_pad(column, 12))

	var heading := HBoxContainer.new()
	column.add_child(heading)
	heading.add_child(UiTheme.label("三列威胁", 19, UiTheme.C_TEXT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	heading.add_child(UiTheme.label(
		"未揭示的意图显示为未知",
		13,
		UiTheme.C_MUTED
	))

	_lanes_row = HBoxContainer.new()
	_lanes_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lanes_row.add_theme_constant_override("separation", 10)
	column.add_child(_lanes_row)


func _build_side_panel(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(_pad(column, 12))

	column.add_child(UiTheme.label("战斗记录", 18, UiTheme.C_TEXT))
	var chain_row := HBoxContainer.new()
	chain_row.add_theme_constant_override("separation", 8)
	var chain_hint := UiTheme.label("同回合回响", 13, UiTheme.C_MUTED)
	chain_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chain_row.add_child(chain_hint)
	_chain_label = UiTheme.badge("连携 —", UiTheme.C_GOLD, UiTheme.C_LINE)
	_chain_label.tooltip_text = "同一回合打出需要灵性的牌会累积连携"
	chain_row.add_child(_chain_label)
	column.add_child(chain_row)
	_selection_label = UiTheme.wrapped_label("尚未选择手牌。", 14, UiTheme.C_PAPER)
	_selection_label.custom_minimum_size = Vector2(0, 52)
	column.add_child(_selection_label)
	_selection_action_button = UiTheme.button("打出所选牌", play_selected, false, 150, true)
	column.add_child(_selection_action_button)
	_cancel_button = UiTheme.button("取消选择", cancel_selection, false, 150)
	column.add_child(_cancel_button)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)

	_event_list = VBoxContainer.new()
	_event_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_list.add_theme_constant_override("separation", 6)
	column.add_child(_event_list)
	_append_event("等待战斗开始。")


func _build_hand_panel(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(_pad(column, 10))

	var heading := HBoxContainer.new()
	column.add_child(heading)
	heading.add_child(UiTheme.label("手牌", 18, UiTheme.C_TEXT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	heading.add_child(UiTheme.label(
		"选择手牌 → 选择目标 → 打出。界面不计算结算。",
		13,
		UiTheme.C_MUTED
	))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_hand_row = HBoxContainer.new()
	_hand_row.add_theme_constant_override("separation", 10)
	_hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hand_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_hand_row)


func _render_snapshot() -> void:
	if _snapshot == null or not is_instance_valid(_lanes_row):
		return
	var data := _snapshot.data
	var player: Dictionary = data.get("player", {})
	var phase := String(data.get("phase", ""))
	var round_number := int(data.get("round_number", 0))
	var max_rounds := int(data.get("max_rounds", 0))
	var pressure := int(data.get("enemy_pressure_bonus", 0))
	var chain: Dictionary = data.get("chain", {})
	var chain_count := int(chain.get("count", 0))
	var chain_threshold := int(chain.get("threshold", 0))

	_encounter_label.text = _encounter_title
	_phase_label.text = "%s  ·  占卜家 · 序列 9" % PHASE_NAMES.get(phase, phase)
	_phase_label.tooltip_text = "revision %d · %s" % [
		_revision,
		String(data.get("battle_id", "")),
	]
	_round_label.text = "回合 %d / %d" % [round_number, max_rounds]
	_pressure_label.text = "敌方压力 +%d" % pressure
	_chain_label.visible = chain_threshold > 0
	_chain_label.text = "连携 %d / %d" % [chain_count, chain_threshold]
	_chain_label.tooltip_text = (
		"再打出 %d 张需要灵性的牌触发回响" % maxi(
			0,
			chain_threshold - chain_count
		)
		if chain_threshold > 0
		else "本场战斗未启用连携"
	)
	_chain_label.add_theme_color_override(
		"font_color",
		UiTheme.C_GOLD if chain_count > 0 else UiTheme.C_MUTED
	)
	_pile_label.text = "牌堆 %d  ·  弃牌 %d" % [
		int(data.get("draw_pile_count", 0)),
		int(data.get("discard_pile_count", 0)),
	]
	_pressure_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if pressure > 0 else UiTheme.C_MUTED
	)
	_set_meter(
		_health_meter,
		"%d / %d%s" % [
			int(player.get("hp", 0)),
			int(player.get("max_hp", 0)),
			"  护盾 %d" % int(player.get("block", 0)) if int(player.get("block", 0)) > 0 else "",
		]
	)
	_set_meter(_spirit_meter, "%d / %d" % [
		int(player.get("spirit", 0)),
		int(player.get("max_spirit", 0)),
	])
	_set_meter(_corruption_meter, "%d / %d" % [
		int(player.get("corruption", 0)),
		int(player.get("max_corruption", 0)),
	])
	_set_meter(_attention_meter, "%d / %d" % [
		int(player.get("attention", 0)),
		int(player.get("max_attention", 0)),
	])

	_render_lanes(data.get("enemies", []))
	_render_hand(data.get("hand", []))
	_refresh_selection()
	_refresh_controls()


func _render_lanes(enemies_value: Variant) -> void:
	for child in _lanes_row.get_children():
		child.free()
	var lane_actors: Array[Dictionary] = [{}, {}, {}]
	if enemies_value is Array:
		for enemy_value in enemies_value:
			if not enemy_value is Dictionary:
				continue
			var enemy: Dictionary = enemy_value
			var lane_index := int(enemy.get("lane_index", -1))
			if lane_index >= 0 and lane_index < 3:
				lane_actors[lane_index] = enemy
	for lane_index in 3:
		_lanes_row.add_child(_build_lane(lane_index, lane_actors[lane_index]))


func _build_lane(lane_index: int, enemy: Dictionary) -> Control:
	var has_enemy := not enemy.is_empty()
	var alive := has_enemy and int(enemy.get("hp", 0)) > 0
	var border := UiTheme.C_DANGER if alive else UiTheme.C_LINE
	var panel := UiTheme.panel(Color("#201e18"), border)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 350)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(_pad(column, 10))
	column.add_child(UiTheme.center_label("第 %d 列" % (lane_index + 1), 14, UiTheme.C_MUTED))

	if has_enemy:
		var definition_id := StringName(enemy.get("definition_id", ""))
		var art_path := get_enemy_art_path(definition_id)
		if not art_path.is_empty() and ResourceLoader.exists(art_path):
			var art := TextureRect.new()
			art.name = "EnemyArt"
			art.texture = load(art_path) as Texture2D
			art.custom_minimum_size = Vector2(0, 170)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			art.modulate = Color.WHITE if alive else Color(0.42, 0.42, 0.42, 0.7)
			column.add_child(art)
		else:
			var unknown := UiTheme.panel(Color("#171711"), UiTheme.C_LINE)
			unknown.custom_minimum_size = Vector2(0, 170)
			unknown.add_child(UiTheme.center_label("未知存在", 16, UiTheme.C_MUTED))
			column.add_child(unknown)
		column.add_child(UiTheme.center_label(
			_enemy_name(definition_id),
			17,
			UiTheme.C_TEXT if alive else UiTheme.C_MUTED
		))
		panel.set_meta("battle_actor_id", String(enemy.get("actor_id", "")))
		panel.set_meta("battle_alive", alive)
		column.add_child(UiTheme.center_label(
			"生命 %d / %d%s" % [
				int(enemy.get("hp", 0)),
				int(enemy.get("max_hp", 0)),
				"  护盾 %d" % int(enemy.get("block", 0))
				if int(enemy.get("block", 0)) > 0 else "",
			],
			13,
			UiTheme.C_DANGER_TEXT
		))
		var intent: Dictionary = enemy.get("intent", {})
		var intent_text := "意图：未知"
		if bool(intent.get("revealed", false)):
			var visible: Dictionary = intent.get("visible_fields", {})
			intent_text = "意图：攻击 %d" % int(visible.get("damage", 0))
		column.add_child(UiTheme.center_label(intent_text, 13, UiTheme.C_PAPER))
		var statuses: Array = enemy.get("statuses", [])
		if not statuses.is_empty():
			var status_row := HBoxContainer.new()
			status_row.alignment = BoxContainer.ALIGNMENT_CENTER
			status_row.add_theme_constant_override("separation", 6)
			for status_value in statuses:
				if not status_value is Dictionary:
					continue
				var status: Dictionary = status_value
				var status_id := StringName(status.get("status_id", ""))
				var status_badge := UiTheme.badge(
					"%s %d" % [
						_status_name(status_id),
						int(status.get("stacks", 0)),
					],
					UiTheme.C_GOLD if status_id == &"mark" else UiTheme.C_PAPER,
					UiTheme.C_LINE
				)
				if status_id == &"mark":
					status_badge.tooltip_text = "标记：受到下一次伤害时附加等量伤害并消耗"
				elif status_id == &"weaken":
					status_badge.tooltip_text = "削弱：降低敌人下一次攻击"
				status_row.add_child(status_badge)
			column.add_child(status_row)

		var target_button := UiTheme.button(
			"选择此目标",
			_on_lane_pressed.bind(StringName(enemy.get("actor_id", ""))),
			alive and not _pending and not _selection_card_id.is_empty()
		)
		target_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_button.name = "TargetButton"
		column.add_child(target_button)
	else:
		var empty := Control.new()
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(empty)
		column.add_child(UiTheme.center_label("此列无目标", 14, UiTheme.C_MUTED))
	return panel


func _render_hand(hand_value: Variant) -> void:
	for child in _hand_row.get_children():
		child.free()
	if not hand_value is Array or hand_value.is_empty():
		_hand_row.add_child(UiTheme.center_label("手牌为空。结束回合或等待抽牌。", 15, UiTheme.C_MUTED))
		return
	for card_value in hand_value:
		if card_value is Dictionary:
			_hand_row.add_child(_build_hand_card(card_value))


func _build_hand_card(card: Dictionary) -> Control:
	var instance_id := StringName(card.get("instance_id", ""))
	var selected := instance_id == _selection_card_id
	var border := UiTheme.C_GOLD if selected else UiTheme.C_LINE
	var panel := UiTheme.panel(
		Color("#272318") if selected else Color("#1b1a15"),
		border
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.set_meta("battle_instance_id", String(instance_id))
	panel.custom_minimum_size = Vector2(242, 212)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(_pad(column, 11))

	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var art_path := get_card_art_path(StringName(card.get("definition_id", "")))
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.name = "CardArt"
		art.texture = load(art_path) as Texture2D
		art.custom_minimum_size = Vector2(0, 58)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.modulate = Color(0.94, 0.9, 0.78, 0.92)
		column.add_child(art)
	else:
		var placeholder := UiTheme.padded_panel(
			UiTheme.center_label("灵界残留", 13, UiTheme.C_MUTED),
			8,
			Color("#171711"),
			UiTheme.C_LINE
		)
		placeholder.custom_minimum_size = Vector2(0, 58)
		column.add_child(placeholder)

	var name_label := UiTheme.label(
		_card_name(StringName(card.get("definition_id", ""))),
		18,
		UiTheme.C_TEXT
	)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(name_label)
	title_row.add_child(UiTheme.badge(
		"%d 灵性" % int(card.get("cost_spirit", 0)),
		UiTheme.C_GOLD,
		UiTheme.C_GOLD
	))

	var target_type := String(card.get("target_type", "none"))
	var category_zh := "非凡能力"
	if String(card.get("category", "")) == "identity":
		category_zh = "人格"
	elif String(card.get("category", "")) == "artifact":
		category_zh = "封印物"
	column.add_child(UiTheme.label(
		"%s · %s" % [
			category_zh,
			"敌方列" if target_type == "enemy" else "自身/无目标",
		],
		13,
		UiTheme.C_MUTED
	))
	var effect_text := get_card_effect_text(
		StringName(card.get("definition_id", ""))
	)
	if not effect_text.is_empty():
		var effect_label := UiTheme.wrapped_label(
			effect_text,
			12,
			UiTheme.C_PAPER
		)
		effect_label.custom_minimum_size = Vector2(0, 34)
		column.add_child(effect_label)
	panel.tooltip_text = "点击整张卡牌选择；再选择目标并打出"

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var select_button := UiTheme.button(
		"已选择" if selected else "选择手牌",
		select_card_instance.bind(instance_id),
		not _pending
	)
	select_button.name = "SelectButton"
	select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(select_button)
	panel.gui_input.connect(_on_hand_card_input.bind(instance_id))
	_make_card_descendants_mouse_transparent(panel, select_button)
	return panel


func _on_hand_card_input(
	event: InputEvent,
	instance_id: StringName
) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		select_card_instance(instance_id)


func _make_card_descendants_mouse_transparent(
	control: Node,
	select_button: Button
) -> void:
	for child in control.get_children():
		if child == select_button:
			continue
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_card_descendants_mouse_transparent(child, select_button)


func _query_current_playability() -> void:
	if _selection_card_id.is_empty():
		return
	if not _playability_handler.is_valid():
		_last_playability = BattlePlayabilityScript.new(false, BattlePlayability.INVALID_TARGET)
		_status_label.text = "玩法查询接口尚未接入。"
		return
	var result: Variant = _playability_handler.call(
		_selection_card_id,
		_selection_target_id
	)
	if result is BattlePlayability:
		_last_playability = result
		_show_playability(result)


func _show_playability(playability: BattlePlayability) -> void:
	_last_playability = playability
	_status_label.text = _reason_text(playability.reason_code)
	_refresh_controls()


func _refresh_selection() -> void:
	if not is_instance_valid(_selection_label):
		return
	if _selection_card_id.is_empty():
		_selection_label.text = "尚未选择手牌。"
		return
	var card := _find_hand_card(_selection_card_id)
	var card_name := _card_name(
		StringName(card.get("definition_id", ""))
	) if not card.is_empty() else String(_selection_card_id)
	var target_text := "未选择目标" if _selection_target_id.is_empty() else _enemy_name_by_actor(_selection_target_id)
	var reason := ""
	if _last_playability != null:
		reason = "\n" + _reason_text(_last_playability.reason_code)
	_selection_label.text = "当前选择：%s\n目标：%s%s" % [card_name, target_text, reason]


func _refresh_controls() -> void:
	if not is_instance_valid(_end_turn_button):
		return
	_end_turn_button.disabled = _pending or not _is_player_action_phase()
	_cancel_button.disabled = _pending or _selection_card_id.is_empty()
	_selection_action_button.disabled = (
		_pending
		or _selection_card_id.is_empty()
		or _last_playability == null
		or not _last_playability.playable
	)
	for child in _hand_row.get_children():
		_set_buttons_disabled(child, _pending)
	for child in _lanes_row.get_children():
		_set_buttons_disabled(
			child,
			_pending or _selection_card_id.is_empty()
		)
	_refresh_target_highlights()


func _refresh_target_highlights() -> void:
	if _snapshot == null or not is_instance_valid(_lanes_row):
		return
	var enemy_target := false
	if not _selection_card_id.is_empty():
		var selected := _find_hand_card(_selection_card_id)
		enemy_target = String(selected.get("target_type", "")) == "enemy"
	for lane in _lanes_row.get_children():
		if not lane is PanelContainer:
			continue
		var panel := lane as PanelContainer
		var alive := bool(panel.get_meta("battle_alive", false))
		var highlighted := enemy_target and alive and not _pending
		var border := (
			UiTheme.C_GOLD
			if highlighted
			else (UiTheme.C_DANGER if alive else UiTheme.C_LINE)
		)
		panel.add_theme_stylebox_override(
			"panel",
			UiTheme.style_box(
				Color("#262116") if highlighted else Color("#201e18"),
				border,
				2 if highlighted else 1,
				8
			)
		)
		var target_button := _find_named_button(panel, "TargetButton")
		if target_button != null:
			target_button.disabled = not highlighted
			target_button.text = "选择目标" if highlighted else "选择此目标"


func _refresh_hand_selection() -> void:
	if not is_instance_valid(_hand_row):
		return
	for child in _hand_row.get_children():
		if not child is PanelContainer:
			continue
		var panel := child as PanelContainer
		var instance_id := StringName(panel.get_meta(
			"battle_instance_id",
			""
		))
		var selected := instance_id == _selection_card_id
		panel.add_theme_stylebox_override(
			"panel",
			UiTheme.style_box(
				Color("#272318") if selected else Color("#1b1a15"),
				UiTheme.C_GOLD if selected else UiTheme.C_LINE,
				1,
				8
			)
		)
		var select_button := _find_named_button(panel, "SelectButton")
		if select_button != null:
			select_button.text = "已选择" if selected else "选择手牌"


func _set_buttons_disabled(control: Node, disabled: bool) -> void:
	if control is BaseButton:
		(control as BaseButton).disabled = disabled
	for child in control.get_children():
		_set_buttons_disabled(child, disabled)


func _find_named_button(root: Node, button_name: String) -> Button:
	if root is Button and root.name == button_name:
		return root as Button
	for child in root.get_children():
		var found := _find_named_button(child, button_name)
		if found != null:
			return found
	return null


func _find_hand_card(card_instance_id: StringName) -> Dictionary:
	if _snapshot == null:
		return {}
	var hand: Variant = _snapshot.data.get("hand", [])
	if not hand is Array:
		return {}
	for card_value in hand:
		if card_value is Dictionary and StringName(card_value.get("instance_id", "")) == card_instance_id:
			return card_value
	return {}


func _enemy_name_by_actor(actor_id: StringName) -> String:
	if _snapshot == null:
		return String(actor_id)
	var enemies: Variant = _snapshot.data.get("enemies", [])
	if enemies is Array:
		for enemy_value in enemies:
			if enemy_value is Dictionary and StringName(enemy_value.get("actor_id", "")) == actor_id:
				return _enemy_name(StringName(enemy_value.get("definition_id", "")))
	return String(actor_id)


func _card_name(definition_id: StringName) -> String:
	if _card_labels.has(definition_id):
		return String(_card_labels[definition_id])
	var details_value: Variant = _card_details.get(String(definition_id), {})
	if details_value is Dictionary:
		var display_name := String(details_value.get("name", ""))
		if not display_name.is_empty():
			return display_name
	return "未知卡牌"


func _enemy_name(definition_id: StringName) -> String:
	if _enemy_labels.has(definition_id):
		return String(_enemy_labels[definition_id])
	return "未知存在"


func _reason_text(reason_code: StringName) -> String:
	return String(REASON_NAMES.get(
		String(reason_code),
		"操作被规则层拒绝；请查看战斗记录。"
	))


func _snapshot_hint() -> String:
	if _snapshot == null:
		return "等待战斗状态。"
	var data := _snapshot.data
	var outcome := String(data.get("outcome", ""))
	if outcome == "victory":
		return "战斗完成。请继续领取奖励。"
	if outcome == "defeat":
		return "战斗结束。请查看结果并返回安全边界。"
	if String(data.get("phase", "")) != "player_action":
		return "敌方正在行动，请等待本回合结算。"
	var hand: Variant = data.get("hand", [])
	if hand is Array and hand.is_empty():
		return "当前没有可选手牌；请结束回合。"
	if not _selection_card_id.is_empty():
		return "已选择手牌；请选择目标或取消选择。"
	return "请选择一张手牌开始行动。"


func _format_event(event: BattleEvent) -> String:
	var data := event.data
	match String(event.type):
		"BattleStarted":
			return "战斗开始。"
		"RoundStarted":
			return "第 %d 回合开始。" % int(data.get("round_number", 0))
		"CardPlayed":
			return "打出 %s → %s。" % [
				_card_name(StringName(data.get("definition_id", ""))),
				(
					_enemy_name_by_actor(StringName(data.get("target_id", "")))
					if not String(data.get("target_id", "")).is_empty()
					else "无目标"
				),
			]
		"CardDrawn":
			return "抽取 %s。" % _card_name(StringName(data.get("definition_id", "")))
		"DamageApplied":
			return "%s 受到 %d 点伤害（%d → %d）。" % [
				_enemy_name_by_actor(StringName(data.get("target_id", "")))
				if String(data.get("target_id", "")) != "player" else "你",
				int(data.get("amount", 0)),
				int(data.get("hp_before", 0)),
				int(data.get("hp_after", 0)),
			]
		"EnemyActed":
			return "%s 发动攻击，造成 %d 点伤害。" % [
				_enemy_name_by_actor(StringName(data.get("enemy_id", ""))),
				int(data.get("damage", 0)),
			]
		"EnemyPressureChanged":
			return "敌方压力提升至 +%d。" % int(data.get("bonus", 0))
		"IntentRevealed":
			return "%s 的意图被揭示。" % _enemy_name_by_actor(
				StringName(data.get("enemy_id", ""))
			)
		"RiskChanged":
			return "%s %d → %d。" % [
				"污染" if String(data.get("risk_id", "")) == "corruption" else "被注视",
				int(data.get("before", 0)),
				int(data.get("after", 0)),
			]
		"ChainChanged":
			return "连携 %d → %d。" % [
				int(data.get("before", 0)),
				int(data.get("after", 0)),
			]
		"ChainTriggered":
			return "灵性回响：对全体敌人造成 %d 伤害，抽 %d 张牌，恢复 %d 灵性。" % [
				int(data.get("damage", 0)),
				int(data.get("draw", 0)),
				int(data.get("spirit", 0)),
			]
		"BattleEnded":
			return "战斗结束：%s。" % (
				"胜利" if String(data.get("outcome", "")) == "victory" else "失败"
			)
		_:
			return "灵性痕迹一闪而过。"


func _append_event(text_value: String) -> void:
	if not is_instance_valid(_event_list):
		return
	_events.append(text_value)
	while _events.size() > 10:
		_events.pop_front()
	for child in _event_list.get_children():
		child.free()
	for event_text in _events:
		_event_list.add_child(UiTheme.wrapped_label("· " + event_text, 13, UiTheme.C_MUTED))


func _is_player_action_phase() -> bool:
	return (
		_snapshot != null
		and String(_snapshot.data.get("phase", "")) == "player_action"
		and String(_snapshot.data.get("outcome", "")).is_empty()
	)


func _meter_with_value(
	title: String,
	value_text: String,
	color: Color,
	icon_id: String
) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", 2)
	result.custom_minimum_size = Vector2(108, 48)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 5)
	title_row.add_child(_status_icon(icon_id, 18))
	title_row.add_child(UiTheme.label(title, 12, UiTheme.C_MUTED))
	result.add_child(title_row)
	var value_label := UiTheme.label(value_text, 22, color)
	value_label.name = "MeterValue"
	result.add_child(value_label)
	_meter_value_labels[title] = value_label
	return result


func _set_meter(meter: VBoxContainer, value_text: String) -> void:
	if not is_instance_valid(meter):
		return
	var value_label := meter.get_node_or_null("MeterValue") as Label
	if is_instance_valid(value_label):
		value_label.text = value_text


func _status_icon(icon_id: String, size: int) -> TextureRect:
	var icon_path := get_status_icon_path(icon_id)
	var icon := TextureRect.new()
	icon.name = "StatusIcon"
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path) as Texture2D
	return icon


func _status_name(status_id: StringName) -> String:
	match status_id:
		&"mark":
			return "标记"
		&"weaken":
			return "削弱"
		&"bleed":
			return "流血"
		&"vulnerable":
			return "易伤"
		_:
			return "未知状态"


func _pad(content: Control, margin: int) -> MarginContainer:
	var result := MarginContainer.new()
	result.add_theme_constant_override("margin_left", margin)
	result.add_theme_constant_override("margin_top", margin)
	result.add_theme_constant_override("margin_right", margin)
	result.add_theme_constant_override("margin_bottom", margin)
	result.add_child(content)
	return result


func _on_lane_pressed(enemy_id: StringName) -> void:
	select_target(enemy_id)


func _request_exit() -> void:
	if not is_instance_valid(_exit_confirmation):
		_exit_confirmation = ConfirmationDialog.new()
		_exit_confirmation.title = "退出当前战斗？"
		_exit_confirmation.dialog_text = (
			"战斗中途不会保存。确认后将返回标题，并从最近检查点继续。"
		)
		_exit_confirmation.ok_button_text = "退出战斗"
		_exit_confirmation.cancel_button_text = "继续战斗"
		_exit_confirmation.confirmed.connect(func() -> void:
			if _exit_emitted:
				return
			_exit_emitted = true
			exit_requested.emit()
		)
		add_child(_exit_confirmation)
	_exit_confirmation.popup_centered()


func _play_event_feedback(event: BattleEvent) -> void:
	var data := event.data
	match String(event.type):
		"CardPlayed":
			_play_card_cast(
				StringName(data.get("definition_id", "")),
				StringName(data.get("target_id", ""))
			)
		"DamageApplied":
			var target_id := StringName(data.get("target_id", ""))
			var amount := int(data.get("amount", 0))
			var anchor := _actor_anchor(target_id)
			if anchor != null and amount > 0:
				_show_floating_text(anchor, "-%d" % amount, UiTheme.C_DANGER_TEXT)
				_pulse_control(anchor, Color(1.15, 0.72, 0.68, 1))
		"Healed":
			var target_id := StringName(data.get("target_id", ""))
			var amount := int(data.get("amount", 0))
			var anchor := _actor_anchor(target_id)
			if anchor != null and amount > 0:
				_show_floating_text(anchor, "+%d" % amount, UiTheme.C_GOLD)
				_pulse_control(anchor, Color(1.1, 1.08, 0.82, 1))
		"BlockChanged":
			var before := int(data.get("before", 0))
			var after := int(data.get("after", 0))
			if after > before:
				var anchor := _actor_anchor(StringName(data.get("target_id", "")))
				if anchor != null:
					_show_floating_text(
						anchor,
						"护盾 +%d" % (after - before),
						UiTheme.C_GOLD
					)
		"StatusChanged":
			var anchor := _actor_anchor(StringName(data.get("target_id", "")))
			if anchor != null:
				_show_floating_text(
					anchor,
					"状态：%s" % _status_name(StringName(
						data.get("status_id", "")
					)),
					UiTheme.C_PAPER
				)
		"RiskChanged":
			_show_floating_text(
				_health_meter,
				"污染 %+d" % (
					int(data.get("after", 0)) - int(data.get("before", 0))
				),
				UiTheme.C_DANGER_TEXT
			)
		"ChainTriggered":
			_show_floating_text(
				_health_meter,
				"灵性回响！",
				UiTheme.C_GOLD
			)
			_pulse_control(_health_meter, Color(1.18, 1.1, 0.72, 1))


func _play_card_cast(definition_id: StringName, target_id: StringName) -> void:
	if not is_instance_valid(_effects_layer):
		return
	var target := _actor_anchor(target_id)
	if target == null:
		target = _health_meter
	var start := Vector2(
		_effects_layer.size.x * 0.24,
		_effects_layer.size.y * 0.78
	)
	var end := target.get_global_rect().get_center() - _effects_layer.global_position
	var card_visual := TextureRect.new()
	card_visual.texture = load(get_card_art_path(definition_id)) as Texture2D
	card_visual.custom_minimum_size = Vector2(130, 92)
	card_visual.size = Vector2(130, 92)
	card_visual.position = start
	card_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	card_visual.modulate = Color(1, 1, 1, 0.95)
	_effects_layer.add_child(card_visual)
	_visual_effect_count += 1
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_visual, "position", end, 0.25)
	tween.tween_property(card_visual, "scale", Vector2(0.35, 0.35), 0.25)
	tween.tween_property(card_visual, "rotation", 0.22, 0.25)
	tween.chain().tween_property(card_visual, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(card_visual.queue_free)


func _show_floating_text(anchor: Control, text_value: String, color: Color) -> void:
	if not is_instance_valid(_effects_layer) or not is_instance_valid(anchor):
		return
	var label := UiTheme.label(text_value, 26, color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 1))
	label.add_theme_constant_override("outline_size", 5)
	label.size = Vector2(180, 44)
	var center := anchor.get_global_rect().get_center() - _effects_layer.global_position
	label.position = center - Vector2(90, 18)
	_effects_layer.add_child(label)
	_visual_effect_count += 1
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -58), 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(label.queue_free)


func _pulse_control(control: Control, color: Color) -> void:
	if not is_instance_valid(control):
		return
	var tween := create_tween()
	tween.tween_property(control, "modulate", color, 0.08)
	tween.tween_property(control, "modulate", Color.WHITE, 0.18)


func _actor_anchor(actor_id: StringName) -> Control:
	if actor_id.is_empty() or actor_id == &"player":
		return _health_meter
	for child in _lanes_row.get_children():
		if String(child.get_meta("battle_actor_id", "")) == String(actor_id):
			return child as Control
	return null


func _on_battle_finished(snapshot: BattleSnapshot) -> void:
	battle_finished.emit(snapshot)
