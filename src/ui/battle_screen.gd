extends Control

signal command_requested(command: BattleCommand)
signal selection_changed(card_instance_id: StringName, target_id: StringName)
signal battle_finished(snapshot: BattleSnapshot)

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleCommandResultScript := preload("res://src/core/battle_command_result.gd")
const BattlePlayabilityScript := preload("res://src/core/battle_playability.gd")
const BattleSnapshotScript := preload("res://src/core/battle_snapshot.gd")

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
var _enemy_labels: Dictionary = {}
var _encounter_title := "首场战斗"
var _events: Array[String] = []
var _outcome_emitted := false

var _encounter_label: Label
var _phase_label: Label
var _round_label: Label
var _pressure_label: Label
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


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_refresh_controls()


func configure(
	encounter_title: String,
	card_labels: Dictionary,
	enemy_labels: Dictionary,
	query_playability_handler: Callable
) -> void:
	_encounter_title = encounter_title if not encounter_title.is_empty() else "首场战斗"
	_card_labels = card_labels.duplicate(true)
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
	_status_label.text = "战斗已载入。"
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
	return String(CARD_ART_BY_DEFINITION.get(definition_id, ""))


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

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 24)
	safe.add_theme_constant_override("margin_top", 18)
	safe.add_theme_constant_override("margin_right", 24)
	safe.add_theme_constant_override("margin_bottom", 18)
	add_child(safe)

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
	hand.custom_minimum_size = Vector2(0, 252)
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
	_end_turn_button = UiTheme.button("结束回合", end_turn, false, 126)
	row.add_child(_end_turn_button)
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
	_selection_label = UiTheme.wrapped_label("尚未选择手牌。", 14, UiTheme.C_PAPER)
	_selection_label.custom_minimum_size = Vector2(0, 52)
	column.add_child(_selection_label)
	_selection_action_button = UiTheme.button("打出所选牌", play_selected, false, 150)
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

	_encounter_label.text = _encounter_title
	_phase_label.text = "%s  ·  占卜家 · 序列 9" % PHASE_NAMES.get(phase, phase)
	_phase_label.tooltip_text = "revision %d · %s" % [
		_revision,
		String(data.get("battle_id", "")),
	]
	_round_label.text = "回合 %d / %d" % [round_number, max_rounds]
	_pressure_label.text = "敌方压力 +%d" % pressure
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
	panel.custom_minimum_size = Vector2(0, 410)

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
			art.custom_minimum_size = Vector2(0, 205)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			art.modulate = Color.WHITE if alive else Color(0.42, 0.42, 0.42, 0.7)
			column.add_child(art)
		else:
			var unknown := UiTheme.panel(Color("#171711"), UiTheme.C_LINE)
			unknown.custom_minimum_size = Vector2(0, 205)
			unknown.add_child(UiTheme.center_label("未知存在", 16, UiTheme.C_MUTED))
			column.add_child(unknown)
		column.add_child(UiTheme.center_label(
			_enemy_name(definition_id),
			17,
			UiTheme.C_TEXT if alive else UiTheme.C_MUTED
		))
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
	panel.custom_minimum_size = Vector2(242, 206)
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
	panel.tooltip_text = "实例 ID：%s" % String(instance_id)

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
	return panel


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


func _set_buttons_disabled(control: Node, disabled: bool) -> void:
	if control is BaseButton:
		(control as BaseButton).disabled = disabled
	for child in control.get_children():
		_set_buttons_disabled(child, disabled)


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
	return String(_card_labels.get(definition_id, UiTheme.readable_id(String(definition_id))))


func _enemy_name(definition_id: StringName) -> String:
	return String(_enemy_labels.get(definition_id, UiTheme.readable_id(String(definition_id))))


func _reason_text(reason_code: StringName) -> String:
	return String(REASON_NAMES.get(String(reason_code), "操作被规则层拒绝：%s" % String(reason_code)))


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
				String(data.get("target_id", "无目标")),
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
		"BattleEnded":
			return "战斗结束：%s。" % String(data.get("outcome", ""))
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


func _on_battle_finished(snapshot: BattleSnapshot) -> void:
	battle_finished.emit(snapshot)
