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

const BATTLE_BACKGROUND := "res://assets/game/v0.24.0/v0.3.0/scenes/battle-tingen-old-house.png"
const ART_LANTERN := "res://assets/game/v0.24.0/enemies/enemy-lantern-pursuer.png"
const ART_TENANT := "res://assets/game/v0.24.0/v0.3.0/enemies/enemy-weeping-tenant.png"
const ART_MOTH := "res://assets/game/v0.24.0/v0.3.0/enemies/enemy-candle-moth.png"
const ART_HOUND := "res://assets/game/v0.24.0/v0.3.0/enemies/enemy-mirror-hound.png"
const ART_TOPHAT := "res://assets/game/v0.24.0/v0.5.0/enemies/enemy-mirror-baron.png"
const ENEMY_ART_BY_DEFINITION := {
	&"enemy.candle_moth": ART_LANTERN,
	&"enemy.tingen.kidnapper": ART_LANTERN,
	&"enemy.mirror_hound": ART_HOUND,
	&"enemy.tingen.rampager": ART_HOUND,
	&"enemy.mirror_hound_echo": ART_TOPHAT,
	&"enemy.weeping_tenant": ART_TENANT,
	&"enemy.tingen.knight_wraith": ART_TENANT,
	&"enemy.mirror_baron": ART_MOTH,
	&"enemy.tingen.megose": ART_MOTH,
}
const RITUAL_SLOT_NAMES := ["灵性之墙", "烛火与祭品", "尊名回应"]
const TRAIT_NAMES := {
	"human": "普通人",
	"beyonder": "非凡者",
	"spirit": "灵体",
	"undead": "不死",
	"filth": "污秽",
	"lost_control": "失控者",
}
const THREAT_NAMES := {
	"corruption": "每次攻击污染+2",
	"attention": "每次攻击被注视+1",
}
const CARD_ART_BY_DEFINITION := {
	&"card.skill.ink_dart": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-ink-dart.png",
	&"card.skill.paper_guard": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-paper-guard.png",
	&"card.skill.calm_breath": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-calm-breath.png",
	&"card.skill.focus": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-focus.png",
	&"card.skill.insight": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-insight.png",
	&"card.skill.omen": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-omen.png",
	&"card.skill.whisper": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-whisper.png",
	&"card.skill.second_look": "res://assets/game/v0.24.0/v0.3.0/cards/card-skill-second-look.png",
	&"card.skill.dream_question": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_dream_question.png",
	&"card.skill.mirror_ward": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_mirror_ward.png",
	&"card.skill.severed_string": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_severed_string.png",
	&"card.skill.last_rites": "res://assets/game/v0.24.0/v0.13.0/cards/card_skill_last_rites.png",
}
const STATUS_ICON_BASE := "res://assets/game/v0.24.0/v0.3.0/status/"

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
var _player_status_label: Label
var _health_meter: VBoxContainer
var _spirit_meter: VBoxContainer
var _corruption_meter: VBoxContainer
var _attention_meter: VBoxContainer
var _lanes_row: HBoxContainer
var _hand_row: HBoxContainer
var _event_list: VBoxContainer
var _event_scroll: ScrollContainer
var _play_button: Button
var _cancel_button: Button
var _end_turn_button: Button
var _selection_label: Label
var _selection_action_button: Button
var _meter_value_labels: Dictionary = {}
var _effects_layer: Control
var _exit_button: Button
var _exit_confirmation: ConfirmationDialog
var _enemy_detail_dialog: AcceptDialog
var _visual_effect_count := 0
var _banner_count := 0
var _screen_scroll: ScrollContainer
var _content_root: Control
var _scroll_hint_label: Label
var _ritual_label: Label
var _ritual_slots: Array[Label] = []
var _risk_label: Label
var _risk_detail_label: Label
var _intel_title_label: Label
var _intel_detail_label: Label
var _intel_hint_label: Label
var _synergy_list: VBoxContainer
var _synergy_scroll: ScrollContainer

const HAND_PANEL_HEIGHT := 256
const HAND_CARD_SIZE := Vector2(242, 196)
const LANE_HEIGHT := 308


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()
	_refresh_controls()
	call_deferred("_refresh_scroll_hint")


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
	UiTheme.set_clip_text(_status_label, _snapshot_hint())
	_refresh_controls()
	call_deferred("_refresh_scroll_hint")


func apply_command_result(result: BattleCommandResult) -> void:
	_pending = false
	if result == null:
		UiTheme.set_clip_text(_status_label, "未收到有效命令结果。")
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
		UiTheme.set_clip_text(_status_label, _reason_text(result.reason_code))
	else:
		UiTheme.set_clip_text(_status_label, "命令已完成。")
	_refresh_controls()


func set_pending(value: bool) -> void:
	_pending = value
	if _pending:
		UiTheme.set_clip_text(_status_label, "正在等待结算……")
	_refresh_controls()


func is_pending() -> bool:
	return _pending


func get_selected_card_id() -> StringName:
	return _selection_card_id


func get_selected_target_id() -> StringName:
	return _selection_target_id


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_scroll_hint_text() -> String:
	return _scroll_hint_label.text if is_instance_valid(_scroll_hint_label) else ""


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


func inspect_enemy(actor_id: String) -> bool:
	if _snapshot == null:
		return false
	for enemy_value in _snapshot.data.get("enemies", []):
		if enemy_value is Dictionary and String(enemy_value.get("actor_id", "")) == actor_id:
			_show_enemy_detail(enemy_value)
			return true
	return false


func get_enemy_detail_text() -> String:
	return _enemy_detail_dialog.dialog_text if is_instance_valid(_enemy_detail_dialog) else ""


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
		UiTheme.set_clip_text(_status_label, "已选择「%s」；请选择敌方列。" % _card_name(StringName(card["definition_id"])))
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
		UiTheme.set_clip_text(_status_label, "已取消选择。")
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
			UiTheme.set_clip_text(_status_label, "当前阶段不能结束回合。")
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

	# Every region below has a fixed or bounded minimum height. Dynamic text
	# is clipped (with tooltips) or lives inside its own scroll viewport, so a
	# region that receives more content can never squeeze its neighbours
	# (ADR-0030).
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	safe.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_status_strip())

	var middle := HBoxContainer.new()
	middle.name = "BattleMiddle"
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	root.add_child(middle)

	var battlefield := UiTheme.panel(Color("#171711"), UiTheme.C_LINE)
	battlefield.name = "BattlefieldPanel"
	battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield.size_flags_stretch_ratio = 2.6
	battlefield.clip_contents = true
	middle.add_child(battlefield)
	_build_battlefield(battlefield)

	var side := UiTheme.panel(UiTheme.C_SURFACE, UiTheme.C_LINE)
	side.name = "SidePanel"
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.0
	side.clip_contents = true
	middle.add_child(side)
	_build_side_panel(side)

	var hand := UiTheme.panel(UiTheme.C_SURFACE, UiTheme.C_GOLD)
	hand.name = "HandPanel"
	hand.custom_minimum_size = Vector2(0, HAND_PANEL_HEIGHT)
	hand.size_flags_vertical = Control.SIZE_SHRINK_END
	root.add_child(hand)
	_build_hand_panel(hand)


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.name = "BattleHeader"
	row.custom_minimum_size = Vector2(0, 58)
	row.add_theme_constant_override("separation", 12)

	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override("separation", 1)
	row.add_child(title_block)
	_encounter_label = UiTheme.clip_label(_encounter_title, 23, UiTheme.C_TEXT)
	title_block.add_child(_encounter_label)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 10)
	title_block.add_child(info_row)
	_phase_label = UiTheme.clip_label("等待战斗快照", 12, UiTheme.C_MUTED)
	_phase_label.size_flags_stretch_ratio = 0.8
	info_row.add_child(_phase_label)
	_pile_label = UiTheme.clip_label("牌堆 —  ·  弃牌 —", 12, UiTheme.C_MUTED)
	info_row.add_child(_pile_label)
	# Reserved line for the small-viewport scroll hint: it sits at the left
	# edge so it stays visible when the page itself needs scrolling.
	_scroll_hint_label = UiTheme.clip_label("", 12, UiTheme.C_GOLD)
	title_block.add_child(_scroll_hint_label)

	_health_meter = _meter_with_value("生命", "—", UiTheme.C_TEXT, "health", 150)
	_health_meter.tooltip_text = "护盾只保护本回合；下一回合开始时清除。"
	_spirit_meter = _meter_with_value("灵性", "—", UiTheme.C_GOLD, "spirit")
	_corruption_meter = _meter_with_value("污染", "—", UiTheme.C_DANGER_TEXT, "corruption")
	_corruption_meter.tooltip_text = "污染达到上限即失败；达到惩罚线后每回合开始失去 1 点生命。"
	_attention_meter = _meter_with_value("被注视", "—", UiTheme.C_DANGER_TEXT, "attention")
	_attention_meter.tooltip_text = "被注视达到追猎线后，所有敌人攻击 +1；达到上限时 +2。"
	row.add_child(_health_meter)
	row.add_child(_spirit_meter)
	row.add_child(_corruption_meter)
	row.add_child(_attention_meter)

	_round_label = UiTheme.badge("回合 — / —", UiTheme.C_GOLD, UiTheme.C_GOLD)
	_round_label.custom_minimum_size = Vector2(104, 0)
	_round_label.clip_text = true
	_pressure_label = UiTheme.badge("敌方压力 +0", UiTheme.C_MUTED, UiTheme.C_LINE)
	_pressure_label.custom_minimum_size = Vector2(112, 0)
	_pressure_label.clip_text = true
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	row.add_child(left)
	_status_label = UiTheme.clip_label("等待战斗初始化。", 15, UiTheme.C_TEXT)
	left.add_child(_status_label)
	_player_status_label = UiTheme.clip_label("状态：无持续状态", 12, UiTheme.C_GOLD)
	left.add_child(_player_status_label)

	var ritual := VBoxContainer.new()
	ritual.name = "RitualTracker"
	ritual.custom_minimum_size = Vector2(318, 0)
	ritual.add_theme_constant_override("separation", 3)
	row.add_child(ritual)
	_ritual_label = UiTheme.clip_label("仪式准备 0 / 3", 12, UiTheme.C_MUTED)
	_ritual_label.tooltip_text = "仪式魔法：灵性之墙、烛火与祭品、念诵尊名。消耗全部准备的仪式牌每层额外增强。"
	ritual.add_child(_ritual_label)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	ritual.add_child(slots)
	_ritual_slots.clear()
	for slot_name in RITUAL_SLOT_NAMES:
		var slot := UiTheme.badge(String(slot_name), UiTheme.C_MUTED, UiTheme.C_LINE)
		slot.custom_minimum_size = Vector2(98, 0)
		slot.clip_text = true
		slots.add_child(slot)
		_ritual_slots.append(slot)

	var risk := VBoxContainer.new()
	risk.custom_minimum_size = Vector2(290, 0)
	risk.add_theme_constant_override("separation", 2)
	row.add_child(risk)
	_risk_label = UiTheme.clip_label("", 12, UiTheme.C_DANGER_TEXT)
	risk.add_child(_risk_label)
	_risk_detail_label = UiTheme.clip_label("", 12, UiTheme.C_MUTED)
	risk.add_child(_risk_detail_label)

	var strip := UiTheme.padded_panel(row, 9, Color("#252118"), UiTheme.C_LINE)
	strip.name = "BattleStatusStrip"
	strip.custom_minimum_size = Vector2(0, 62)
	return strip


func _build_battlefield(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(_pad(column, 10))

	var intel := VBoxContainer.new()
	intel.add_theme_constant_override("separation", 1)
	var intel_panel := UiTheme.padded_panel(intel, 7, Color("#211c14"), UiTheme.C_LINE)
	intel_panel.name = "BossIntelPanel"
	intel_panel.custom_minimum_size = Vector2(0, 70)
	column.add_child(intel_panel)
	_intel_title_label = UiTheme.clip_label("战场情报", 16, UiTheme.C_TEXT)
	intel.add_child(_intel_title_label)
	_intel_detail_label = UiTheme.clip_label("未揭示的意图显示为未知；危险预感会在致命攻击前发出警告。", 13, UiTheme.C_PAPER)
	intel.add_child(_intel_detail_label)
	_intel_hint_label = UiTheme.clip_label("", 13, UiTheme.C_GOLD)
	intel.add_child(_intel_hint_label)

	_lanes_row = HBoxContainer.new()
	_lanes_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lanes_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_lanes_row.add_theme_constant_override("separation", 10)
	var enemy_scroll := ScrollContainer.new()
	enemy_scroll.name = "EnemyStatusScroll"
	enemy_scroll.custom_minimum_size = Vector2(0, 120)
	enemy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	enemy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	enemy_scroll.add_child(_lanes_row)
	column.add_child(enemy_scroll)


func _build_side_panel(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(_pad(column, 10))

	var chain_row := HBoxContainer.new()
	chain_row.add_theme_constant_override("separation", 8)
	var chain_hint := UiTheme.clip_label("行动 · 同回合回响", 16, UiTheme.C_TEXT)
	chain_row.add_child(chain_hint)
	_chain_label = UiTheme.badge("连携 —", UiTheme.C_GOLD, UiTheme.C_LINE)
	_chain_label.custom_minimum_size = Vector2(86, 0)
	_chain_label.clip_text = true
	_chain_label.tooltip_text = "同一回合打出需要灵性的牌会累积连携"
	chain_row.add_child(_chain_label)
	column.add_child(chain_row)

	var selection_box := UiTheme.fixed_text("尚未选择手牌。", 13, UiTheme.C_PAPER, 40)
	selection_box.name = "SelectionBox"
	_selection_label = UiTheme.fixed_text_label(selection_box)
	column.add_child(selection_box)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	_selection_action_button = UiTheme.button("打出所选牌", play_selected, false, 0, true)
	_selection_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_selection_action_button)
	_cancel_button = UiTheme.button("取消选择", cancel_selection, false, 0)
	_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_cancel_button)

	var synergy_heading := UiTheme.clip_label("原著联动（同一回合打出所列卡牌即触发）", 13, UiTheme.C_GOLD)
	synergy_heading.tooltip_text = "联动来自《诡秘之主》第一卷的真实战斗与经历。将鼠标停在条目上可查看原著出处与效果。"
	column.add_child(synergy_heading)
	_synergy_list = VBoxContainer.new()
	_synergy_list.add_theme_constant_override("separation", 3)
	_synergy_scroll = UiTheme.fixed_scroll(_synergy_list, 116)
	_synergy_scroll.name = "SynergyScroll"
	column.add_child(_synergy_scroll)

	var divider := ColorRect.new()
	divider.color = UiTheme.C_LINE
	divider.custom_minimum_size = Vector2(0, 1)
	column.add_child(divider)
	column.add_child(UiTheme.clip_label("战斗记录", 13, UiTheme.C_MUTED))

	_event_list = VBoxContainer.new()
	_event_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_event_list.add_theme_constant_override("separation", 5)
	_event_scroll = ScrollContainer.new()
	_event_scroll.name = "BattleLogScroll"
	_event_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_scroll.custom_minimum_size = Vector2(0, 72)
	_event_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_event_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_event_scroll.follow_focus = true
	_event_scroll.add_child(_event_list)
	column.add_child(_event_scroll)
	_append_event("等待战斗开始。")


func _build_hand_panel(panel: PanelContainer) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(_pad(column, 10))

	var heading := HBoxContainer.new()
	column.add_child(heading)
	heading.add_child(UiTheme.label("手牌", 18, UiTheme.C_TEXT))
	var tip := UiTheme.clip_label(
		"选择手牌 → 选择目标 → 打出。金色“联动”标签表示可与其他牌触发原著联动；“单场一次”的封印物打出后移出本场。",
		12,
		UiTheme.C_MUTED
	)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(tip)

	var scroll := ScrollContainer.new()
	scroll.name = "HandScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_hand_row = HBoxContainer.new()
	_hand_row.add_theme_constant_override("separation", 10)
	_hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hand_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_hand_row)


func _refresh_scroll_hint() -> void:
	if not is_instance_valid(_screen_scroll) or not is_instance_valid(_scroll_hint_label):
		return
	var vertical_bar := _screen_scroll.get_v_scroll_bar()
	var horizontal_bar := _screen_scroll.get_h_scroll_bar()
	var vertical_overflow := vertical_bar.max_value > vertical_bar.page + 1.0
	var horizontal_overflow := horizontal_bar.max_value > horizontal_bar.page + 1.0
	# The hint line is always reserved in the status strip; only its text
	# changes, so showing it never shifts other regions.
	if not (vertical_overflow or horizontal_overflow):
		UiTheme.set_clip_text(_scroll_hint_label, "")
		return
	UiTheme.set_clip_text(_scroll_hint_label, (
		"页面内容超出当前窗口 · 上下滑动查看手牌和操作"
		if vertical_overflow and not horizontal_overflow
		else "页面内容超出当前窗口 · 滑动查看完整战场和操作"
	))


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

	UiTheme.set_clip_text(_encounter_label, _encounter_title)
	UiTheme.set_clip_text(_phase_label, "%s  ·  占卜家途径" % PHASE_NAMES.get(phase, phase))
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
	var wave_text := ""
	if int(data.get("pending_wave_count", 0)) > 0:
		wave_text = "  ·  后续波次 %d" % int(data.get("pending_wave_count", 0))
	UiTheme.set_clip_text(_pile_label, "牌堆 %d  ·  弃牌 %d  ·  移出 %d%s" % [
		int(data.get("draw_pile_count", 0)),
		int(data.get("discard_pile_count", 0)),
		int(data.get("exhaust_pile_count", 0)),
		wave_text,
	])
	_pressure_label.add_theme_color_override(
		"font_color",
		UiTheme.C_DANGER_TEXT if pressure > 0 else UiTheme.C_MUTED
	)
	_set_meter(
		_health_meter,
		"%d / %d%s" % [
			int(player.get("hp", 0)),
			int(player.get("max_hp", 0)),
			"  盾%d" % int(player.get("block", 0)) if int(player.get("block", 0)) > 0 else "",
		]
	)
	var status_texts: Array[String] = []
	for status_value in player.get("statuses", []):
		if not status_value is Dictionary:
			continue
		var status: Dictionary = status_value
		var status_id := StringName(status.get("status_id", ""))
		var stacks := int(status.get("stacks", 0))
		match status_id:
			&"foresight":
				status_texts.append("预见（下次攻击 -1）")
			&"ritual_preparation":
				pass
			&"evasion":
				status_texts.append("闪避 %d（抵消下一次攻击）" % stacks)
			&"sluggish":
				status_texts.append("迟缓（下回合灵性 -%d）" % stacks)
			_:
				status_texts.append("%s ×%d" % [_status_name(status_id), stacks])
	UiTheme.set_clip_text(
		_player_status_label,
		"状态：" + ("、".join(status_texts) if not status_texts.is_empty() else "无持续状态")
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
	_render_ritual(data.get("ritual", {}))
	_render_risk(data.get("risk_pressure", {}))
	_render_lanes(data.get("enemies", []))
	_render_intel(data)
	_render_synergies(data.get("synergies", []))
	_render_hand(data.get("hand", []))
	_refresh_selection()
	_refresh_controls()


func _render_ritual(ritual_value: Variant) -> void:
	var ritual: Dictionary = ritual_value if ritual_value is Dictionary else {}
	var stacks := int(ritual.get("stacks", 0))
	var maximum := maxi(1, int(ritual.get("max", RITUAL_SLOT_NAMES.size())))
	UiTheme.set_clip_text(_ritual_label, (
		"仪式准备 %d / %d · 打出“驱邪仪式”一次兑现" % [stacks, maximum]
		if stacks > 0
		else "仪式准备 0 / %d · 灵性之墙、圣夜粉、烛芯可积累" % maximum
	))
	_ritual_label.add_theme_color_override("font_color", UiTheme.C_GOLD if stacks > 0 else UiTheme.C_MUTED)
	for index in range(_ritual_slots.size()):
		var slot: Label = _ritual_slots[index]
		var lit := index < stacks
		slot.add_theme_color_override("font_color", UiTheme.C_TEXT if lit else UiTheme.C_MUTED)
		slot.add_theme_stylebox_override("normal", UiTheme.style_box(
			Color("#4a3b1d") if lit else UiTheme.C_SURFACE,
			UiTheme.C_GOLD if lit else UiTheme.C_LINE,
			1,
			5
		))


func _render_risk(risk_value: Variant) -> void:
	var risk: Dictionary = risk_value if risk_value is Dictionary else {}
	var parts: Array[String] = []
	var attention_penalty := int(risk.get("attention_penalty", 0))
	if attention_penalty > 0:
		parts.append("被注视过高：敌方攻击 +%d" % attention_penalty)
	if int(risk.get("corruption_penalty", 0)) > 0:
		parts.append("污染侵蚀：每回合 -1 生命")
	if parts.is_empty():
		var hunter_at := int(risk.get("attention_hunter_at", 0))
		var penalty_at := int(risk.get("corruption_penalty_at", 0))
		parts.append(
			"风险线：被注视 %d · 污染 %d" % [hunter_at, penalty_at]
			if hunter_at > 0 or penalty_at > 0
			else "风险平稳"
		)
		_risk_label.add_theme_color_override("font_color", UiTheme.C_MUTED)
	else:
		_risk_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT)
	UiTheme.set_clip_text(_risk_label, "  ·  ".join(parts))
	if is_instance_valid(_risk_detail_label):
		UiTheme.set_clip_text(
			_risk_detail_label,
			"闪避/预见/削弱可以抵消敌方攻击"
		)


func _render_intel(data: Dictionary) -> void:
	var boss := {}
	var living: Array = []
	for enemy_value in data.get("enemies", []):
		if not enemy_value is Dictionary or int(enemy_value.get("hp", 0)) <= 0:
			continue
		living.append(enemy_value)
		var tier := String(enemy_value.get("tier", ""))
		if tier == "boss" or (tier == "elite" and boss.is_empty()):
			if boss.is_empty() or tier == "boss":
				boss = enemy_value
	if not boss.is_empty():
		var phases: Array = boss.get("phases", [])
		var triggered: Array = boss.get("triggered_phases", [])
		var current_phase := "初始形态"
		var current_desc := String(boss.get("intent", {}).get("description_zh", ""))
		if not triggered.is_empty() and triggered[-1] is Dictionary:
			current_phase = String(triggered[-1].get("display_name_zh", "强化"))
			current_desc = String(triggered[-1].get("description_zh", current_desc))
		var tier_text := "首领" if String(boss.get("tier", "")) == "boss" else "精英"
		UiTheme.set_clip_text(_intel_title_label, "%s · %s  ·  生命 %d / %d  ·  阶段 %d / %d：%s" % [
			tier_text,
			_enemy_display(boss),
			int(boss.get("hp", 0)),
			int(boss.get("max_hp", 0)),
			triggered.size() + 1,
			phases.size() + 1,
			current_phase,
		])
		var next_phase: Dictionary = boss.get("next_phase", {})
		var detail := current_desc
		if not next_phase.is_empty():
			var trigger_text := (
				"生命 ≤ %d%%" % int(next_phase.get("at_hp_percent", 0))
				if int(next_phase.get("at_hp_percent", -1)) > 0
				else "第 %d 回合" % int(next_phase.get("at_round", 0))
			)
			detail = "%s  ｜  下一阶段（%s）：%s" % [
				current_desc if not current_desc.is_empty() else "特质：" + _traits_text(boss.get("traits", [])),
				trigger_text,
				String(next_phase.get("display_name_zh", "")),
			]
		UiTheme.set_clip_text(_intel_detail_label, detail)
		var hint := ""
		if not triggered.is_empty() and triggered[-1] is Dictionary:
			hint = String(triggered[-1].get("counter_hint_zh", ""))
		if hint.is_empty() and not next_phase.is_empty():
			hint = String(next_phase.get("counter_hint_zh", ""))
		UiTheme.set_clip_text(_intel_hint_label, ("应对：" + hint) if not hint.is_empty() else "")
		_intel_title_label.add_theme_color_override("font_color", UiTheme.C_DANGER_TEXT if tier_text == "首领" else UiTheme.C_TEXT)
		return
	var trait_counts := {}
	for enemy in living:
		for trait_value in enemy.get("traits", []):
			trait_counts[String(trait_value)] = true
	UiTheme.set_clip_text(_intel_title_label, "战场情报  ·  第 %d 波%s  ·  存活敌人 %d" % [
		int(data.get("current_wave", 0)) + 1,
		("（后续 %d 波）" % int(data.get("pending_wave_count", 0))) if int(data.get("pending_wave_count", 0)) > 0 else "",
		living.size(),
	])
	_intel_title_label.add_theme_color_override("font_color", UiTheme.C_TEXT)
	UiTheme.set_clip_text(_intel_detail_label, "敌方特质：" + (_traits_text(trait_counts.keys()) if not trait_counts.is_empty() else "普通"))
	var advice := ""
	if trait_counts.has("spirit") or trait_counts.has("undead"):
		advice = "灵体/不死：驱邪仪式、银质匕首、太阳圣徽与阳炎符咒更有效。"
	elif trait_counts.has("filth"):
		advice = "污秽：猎魔子弹与净化类封印物造成额外伤害。"
	elif trait_counts.has("lost_control"):
		advice = "失控者：3-0611 安静发丝可以让他们安静下来。"
	UiTheme.set_clip_text(_intel_hint_label, advice)


func _render_synergies(synergies_value: Variant) -> void:
	if not is_instance_valid(_synergy_list):
		return
	for child in _synergy_list.get_children():
		child.free()
	var shown := 0
	if synergies_value is Array:
		for synergy_value in synergies_value:
			if not synergy_value is Dictionary or not bool(synergy_value.get("in_deck", false)):
				continue
			_synergy_list.add_child(_build_synergy_row(synergy_value))
			shown += 1
	if shown == 0:
		_synergy_list.add_child(UiTheme.wrapped_label(
			"当前牌组没有可触发的原著联动。可在牌组中搭配“提利尔仓库”（2-049 + 左轮）等组合。",
			12,
			UiTheme.C_MUTED
		))


func _build_synergy_row(synergy: Dictionary) -> Control:
	var satisfied: Array = synergy.get("satisfied", [])
	var done := 0
	for value in satisfied:
		if bool(value):
			done += 1
	var triggered := bool(synergy.get("triggered_this_turn", false))
	var names: Array[String] = []
	for group in synergy.get("requires", []):
		var group_names: Array[String] = []
		for card_id in group:
			var name := _card_name_or_empty(StringName(card_id))
			if not name.is_empty():
				group_names.append(name)
		names.append("/".join(group_names) if not group_names.is_empty() else "？")
	var color := UiTheme.C_MUTED
	var state := "%d / %d" % [done, satisfied.size()]
	if triggered:
		color = UiTheme.C_GOLD
		state = "已触发"
	elif done > 0:
		color = UiTheme.C_PAPER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.set_meta("synergy_id", String(synergy.get("id", "")))
	var label := UiTheme.clip_label(
		"%s：%s" % [String(synergy.get("display_name_zh", "")), " + ".join(names)],
		12,
		color
	)
	label.tooltip_text = "%s\n效果：%s\n出处：%s" % [
		String(synergy.get("display_name_zh", "")),
		String(synergy.get("bonus_text_zh", "")),
		String(synergy.get("source_zh", "")),
	]
	row.add_child(label)
	var badge := UiTheme.badge(state, color, UiTheme.C_GOLD if triggered else UiTheme.C_LINE)
	badge.custom_minimum_size = Vector2(58, 0)
	badge.clip_text = true
	row.add_child(badge)
	return row


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
				var previous: Dictionary = lane_actors[lane_index]
				if previous.is_empty() or int(previous.get("hp", 0)) <= 0:
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
	panel.custom_minimum_size = Vector2(0, LANE_HEIGHT)
	panel.clip_contents = true

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(_pad(column, 8))
	var lane_title := "第 %d 列" % (lane_index + 1)
	if has_enemy:
		var tier := String(enemy.get("tier", "normal"))
		lane_title += "  ·  " + ("首领" if tier == "boss" else ("精英" if tier == "elite" else "普通"))
	column.add_child(UiTheme.center_label(lane_title, 12, UiTheme.C_MUTED))

	if has_enemy:
		var definition_id := StringName(enemy.get("definition_id", ""))
		var art_path := get_enemy_art_path(definition_id)
		var art_holder: Control
		if not art_path.is_empty() and ResourceLoader.exists(art_path):
			var art := TextureRect.new()
			art.name = "EnemyArt"
			art.texture = load(art_path) as Texture2D
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			art.modulate = Color.WHITE if alive else Color(0.42, 0.42, 0.42, 0.7)
			art_holder = art
		else:
			var unknown := UiTheme.panel(Color("#171711"), UiTheme.C_LINE)
			unknown.add_child(UiTheme.center_label("未知存在", 16, UiTheme.C_MUTED))
			art_holder = unknown
		art_holder.custom_minimum_size = Vector2(0, 90)
		column.add_child(art_holder)
		var name_label := UiTheme.clip_label(
			_enemy_display(enemy),
			16,
			UiTheme.C_TEXT if alive else UiTheme.C_MUTED
		)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		name_label.tooltip_text = "点击查看状态、特质与原著出处"
		name_label.mouse_filter = Control.MOUSE_FILTER_STOP
		name_label.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_show_enemy_detail(enemy)
		)
		column.add_child(name_label)
		panel.set_meta("battle_actor_id", String(enemy.get("actor_id", "")))
		panel.set_meta("battle_alive", alive)
		var hp_label := UiTheme.clip_label(
			"生命 %d / %d%s" % [
				int(enemy.get("hp", 0)),
				int(enemy.get("max_hp", 0)),
				"  护盾 %d" % int(enemy.get("block", 0))
				if int(enemy.get("block", 0)) > 0 else "",
			],
			13,
			UiTheme.C_DANGER_TEXT
		)
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(hp_label)
		var intent_label := UiTheme.clip_label(_intent_text(enemy), 13, UiTheme.C_PAPER)
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(intent_label)
		var intent: Dictionary = enemy.get("intent", {})
		var danger := alive and bool(intent.get("danger", false))
		var warn_label := UiTheme.clip_label(
			"危险预感：灵性在警告你！" if danger else _traits_line(enemy),
			12,
			UiTheme.C_DANGER_TEXT if danger else UiTheme.C_MUTED
		)
		warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if danger:
			warn_label.tooltip_text = "占卜家的危险预感：这次攻击可能非常致命。闪避、束缚或削弱它。"
		column.add_child(warn_label)
		var phase_count := int(enemy.get("triggered_phase_count", 0))
		var pressure_bonus := int(enemy.get("pressure_bonus", 0))
		var phase_text := ""
		var triggered_phases: Array = enemy.get("triggered_phases", [])
		var phase_total := (enemy.get("phases", []) as Array).size() + 1
		if not triggered_phases.is_empty() and triggered_phases[-1] is Dictionary:
			phase_text = "阶段 %d / %d：%s（已生效）" % [
				phase_count + 1,
				phase_total,
				String(triggered_phases[-1].get("display_name_zh", "强化")),
			]
		elif phase_count > 0:
			phase_text = "阶段 %d：效果已生效" % phase_count
		if pressure_bonus > 0:
			phase_text += (" · " if not phase_text.is_empty() else "") + "强化 +%d" % pressure_bonus
		var phase_badge := UiTheme.badge(
			phase_text if not phase_text.is_empty() else "尚未强化",
			UiTheme.C_DANGER_TEXT if not phase_text.is_empty() else UiTheme.C_MUTED,
			UiTheme.C_DANGER if not phase_text.is_empty() else UiTheme.C_LINE
		)
		phase_badge.clip_text = true
		phase_badge.custom_minimum_size = Vector2(0, 22)
		column.add_child(phase_badge)
		var status_row := HBoxContainer.new()
		status_row.alignment = BoxContainer.ALIGNMENT_CENTER
		status_row.add_theme_constant_override("separation", 5)
		for status_value in enemy.get("statuses", []):
			if not status_value is Dictionary:
				continue
			var status: Dictionary = status_value
			var status_id := StringName(status.get("status_id", ""))
			var status_badge := UiTheme.badge(
				"%s %d" % [
					_status_name(status_id),
					int(status.get("stacks", 0)),
				],
				UiTheme.C_GOLD if status_id in [&"mark", &"bound"] else UiTheme.C_PAPER,
				UiTheme.C_LINE
			)
			status_badge.tooltip_text = _status_tooltip(status_id)
			status_row.add_child(status_badge)
		var status_scroll := UiTheme.fixed_scroll(status_row, 26, true)
		status_scroll.name = "EnemyStatusRow"
		column.add_child(status_scroll)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(spacer)
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


func _intent_text(enemy: Dictionary) -> String:
	if int(enemy.get("hp", 0)) <= 0:
		return "已被击败"
	var intent: Dictionary = enemy.get("intent", {})
	if not bool(intent.get("revealed", false)):
		return "意图：未知（灵视或占卜可揭示）"
	var visible: Dictionary = intent.get("visible_fields", {})
	var name := String(visible.get("display_name_zh", ""))
	var text := "意图：%s攻击 %d" % [
		(name + " · ") if not name.is_empty() else "",
		int(visible.get("damage", 0)),
	]
	if int(visible.get("corruption", 0)) > 0:
		text += " · 污染+%d" % int(visible.get("corruption", 0))
	if int(visible.get("attention", 0)) > 0:
		text += " · 注视+%d" % int(visible.get("attention", 0))
	if int(visible.get("block", 0)) > 0:
		text += " · 护盾+%d" % int(visible.get("block", 0))
	return text


func _traits_line(enemy: Dictionary) -> String:
	var parts: Array[String] = []
	var traits_text := _traits_text(enemy.get("traits", []))
	if not traits_text.is_empty():
		parts.append(traits_text)
	var threat := String(enemy.get("threat", ""))
	if THREAT_NAMES.has(threat):
		parts.append(String(THREAT_NAMES[threat]))
	return " · ".join(parts) if not parts.is_empty() else "特质：普通"


func _traits_text(traits_value: Variant) -> String:
	var names: Array[String] = []
	if traits_value is Array:
		for trait_value in traits_value:
			names.append(String(TRAIT_NAMES.get(String(trait_value), String(trait_value))))
	return "、".join(names)


func _enemy_display(enemy: Dictionary) -> String:
	var definition_id := StringName(enemy.get("definition_id", ""))
	if _enemy_labels.has(definition_id):
		return String(_enemy_labels[definition_id])
	var display := String(enemy.get("display_name_zh", ""))
	return display if not display.is_empty() else "未知存在"


func _status_tooltip(status_id: StringName) -> String:
	match status_id:
		&"mark":
			return "标记：受到下一次伤害时附加等量伤害并消耗"
		&"weaken":
			return "削弱：降低敌人下一次攻击"
		&"bound":
			return "束缚：跳过行动，每跳过一次减少 1 层"
		&"silenced":
			return "失声：无法发动诅咒类意图，诅咒威胁也被压制"
		_:
			return _status_name(status_id)


func _show_enemy_detail(enemy: Dictionary) -> void:
	if not is_instance_valid(_enemy_detail_dialog):
		_enemy_detail_dialog = AcceptDialog.new()
		_enemy_detail_dialog.title = "怪物状态与属性"
		_enemy_detail_dialog.ok_button_text = "关闭"
		add_child(_enemy_detail_dialog)
	var statuses: Array = enemy.get("statuses", [])
	var status_text := "无"
	if not statuses.is_empty():
		var names: Array[String] = []
		for value in statuses:
			if value is Dictionary:
				names.append("%s ×%d" % [
					_status_name(StringName(value.get("status_id", ""))),
					int(value.get("stacks", 0)),
				])
		status_text = "、".join(names)
	var next_phase: Dictionary = enemy.get("next_phase", {})
	var next_text := "无"
	if not next_phase.is_empty():
		next_text = "%s（%s）" % [
			String(next_phase.get("display_name_zh", "")),
			(
				"生命 ≤ %d%%" % int(next_phase.get("at_hp_percent", 0))
				if int(next_phase.get("at_hp_percent", -1)) > 0
				else "第 %d 回合" % int(next_phase.get("at_round", 0))
			),
		]
	_enemy_detail_dialog.dialog_text = "【%s】\n生命：%d / %d\n基础攻击：%d\n护盾：%d\n特质：%s\n当前意图：%s\n状态：%s\n强化阶段：%d · 下一阶段：%s" % [
		_enemy_display(enemy),
		int(enemy.get("hp", 0)),
		int(enemy.get("max_hp", 0)),
		int(enemy.get("base_attack", 0)),
		int(enemy.get("block", 0)),
		_traits_line(enemy),
		_intent_text(enemy).trim_prefix("意图："),
		status_text,
		int(enemy.get("triggered_phase_count", 0)),
		next_text,
	]
	_enemy_detail_dialog.popup_centered(Vector2(520, 360))


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
	var definition_id := StringName(card.get("definition_id", ""))
	var detail: Dictionary = _card_details.get(String(definition_id), {}) if _card_details.get(String(definition_id), {}) is Dictionary else {}
	var selected := instance_id == _selection_card_id
	var border := UiTheme.C_GOLD if selected else UiTheme.C_LINE
	var panel := UiTheme.panel(
		Color("#272318") if selected else Color("#1b1a15"),
		border
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.set_meta("battle_instance_id", String(instance_id))
	panel.custom_minimum_size = HAND_CARD_SIZE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.clip_contents = true

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(_pad(column, 8))

	var art_path := get_card_art_path(definition_id)
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.name = "CardArt"
		art.texture = load(art_path) as Texture2D
		art.custom_minimum_size = Vector2(0, 30)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.modulate = Color(0.94, 0.9, 0.78, 0.92)
		column.add_child(art)
	else:
		var placeholder := UiTheme.panel(Color("#171711"), UiTheme.C_LINE)
		placeholder.custom_minimum_size = Vector2(0, 30)
		column.add_child(placeholder)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	column.add_child(title_row)
	var name_label := UiTheme.clip_label(_card_name(definition_id), 17, UiTheme.C_TEXT)
	title_row.add_child(name_label)
	var cost_badge := UiTheme.badge(
		"%d 灵性" % int(card.get("cost_spirit", 0)),
		UiTheme.C_GOLD,
		UiTheme.C_GOLD
	)
	cost_badge.custom_minimum_size = Vector2(58, 0)
	title_row.add_child(cost_badge)

	var target_type := String(card.get("target_type", "none"))
	var category := String(card.get("category", detail.get("category", "")))
	var category_zh := "非凡能力"
	match category:
		"identity":
			category_zh = "人格"
		"artifact":
			category_zh = "封印物"
		"ally":
			category_zh = "值夜者支援"
	column.add_child(UiTheme.clip_label(
		"%s · %s" % [
			category_zh,
			"选择敌人" if target_type == "enemy" else "无需目标",
		],
		12,
		UiTheme.C_MUTED
	))
	var effect_text := get_card_effect_text(definition_id)
	var effect_box := UiTheme.fixed_text(
		effect_text if not effect_text.is_empty() else "效果由规则层结算。",
		12,
		UiTheme.C_PAPER,
		50
	)
	effect_box.name = "CardEffectBox"
	effect_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(effect_box)

	var chips: Array[String] = []
	if bool(card.get("exhaust", detail.get("exhaust", false))):
		chips.append("单场一次")
	if bool(card.get("consumes_ritual", detail.get("consumes_ritual", false))):
		chips.append("兑现仪式")
	var synergy_names: Array = detail.get("synergy_names", [])
	if not synergy_names.is_empty():
		chips.append("联动：" + "、".join(synergy_names))
	var chip_label := UiTheme.clip_label(
		" · ".join(chips) if not chips.is_empty() else String(detail.get("source_zh", "")),
		11,
		UiTheme.C_GOLD if not chips.is_empty() else UiTheme.C_MUTED
	)
	chip_label.name = "CardChips"
	column.add_child(chip_label)
	var source := String(detail.get("source_zh", ""))
	panel.tooltip_text = "%s\n点击整张卡牌选择；再选择目标并打出%s" % [
		effect_text,
		"\n出处：" + source if not source.is_empty() else "",
	]

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var select_button := UiTheme.button(
		"已选择" if selected else "选择手牌",
		select_card_instance.bind(instance_id),
		not _pending
	)
	select_button.name = "SelectButton"
	select_button.custom_minimum_size = Vector2(0, 32)
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
		UiTheme.set_clip_text(_status_label, "玩法查询接口尚未接入。")
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
	UiTheme.set_clip_text(_status_label, _reason_text(playability.reason_code))
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


func _card_name_or_empty(definition_id: StringName) -> String:
	if _card_labels.has(definition_id):
		return String(_card_labels[definition_id])
	var details_value: Variant = _card_details.get(String(definition_id), {})
	if details_value is Dictionary:
		return String(details_value.get("name", ""))
	return ""


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
			var act_name := String(data.get("display_name_zh", ""))
			return "%s 发动%s，造成 %d 点伤害%s。" % [
				_enemy_name_by_actor(StringName(data.get("enemy_id", ""))),
				"「%s」" % act_name if not act_name.is_empty() else "攻击",
				int(data.get("damage", 0)),
				"（被注视 +%d）" % int(data.get("attention_bonus", 0)) if int(data.get("attention_bonus", 0)) > 0 else "",
			]
		"EnemyPressureChanged":
			return "敌方压力提升至 +%d。" % int(data.get("bonus", 0))
		"EnemyPhaseTriggered":
			return "%s 进入新阶段「%s」：%s（攻击 +%d，护盾 +%d，恢复 %d）。" % [
				_enemy_name_by_actor(StringName(data.get("enemy_id", ""))),
				String(data.get("display_name_zh", "未知强化")),
				String(data.get("description_zh", "")),
				int(data.get("base_attack_bonus", 0)),
				int(data.get("block_bonus", 0)),
				int(data.get("heal", 0)),
			]
		"SynergyTriggered":
			return "原著联动「%s」：%s" % [
				String(data.get("display_name_zh", "")),
				String(data.get("bonus_text_zh", "")),
			]
		"EnemyBound":
			return "%s 被束缚，跳过本次行动（剩余 %d）。" % [
				_enemy_name_by_actor(StringName(data.get("enemy_id", ""))),
				int(data.get("remaining", 0)),
			]
		"AttackEvaded":
			return "闪避生效：抵消 %d 点伤害。" % int(data.get("evaded", 0))
		"PowerStolen":
			return "%s 的力量被窃取：攻击 %d → %d。" % [
				_enemy_name_by_actor(StringName(data.get("enemy_id", ""))),
				int(data.get("before", 0)),
				int(data.get("after", 0)),
			]
		"RitualProgressed":
			return "仪式准备 %d → %d / %d。" % [
				int(data.get("before", 0)),
				int(data.get("after", 0)),
				int(data.get("max", 3)),
			]
		"RitualCompleted":
			return (
				"三段仪式完成，尊名得到回应！（%d 层准备全部兑现）" % int(data.get("stacks", 0))
				if bool(data.get("complete", false))
				else "仪式兑现：%d 层准备。" % int(data.get("stacks", 0))
			)
		"CardExhausted":
			return "%s 已使用，本场移出。" % _card_name(StringName(data.get("definition_id", "")))
		"ConditionMet":
			return "条件达成，追加效果。"
		"StatusChanged":
			return "%s：%s %d。" % [
				_enemy_name_by_actor(StringName(data.get("target_id", "")))
				if String(data.get("target_id", "")) != "player" else "你",
				_status_name(StringName(data.get("status_id", ""))),
				int(data.get("stacks", 0)),
			]
		"EnemyWaveArrived":
			return "第 %d 波异常抵达：%d 个目标进入战场。" % [
				int(data.get("wave_index", 0)) + 1,
				int(data.get("enemy_count", 0)),
			]
		"IntentRevealed":
			return "%s 的意图被揭示。" % _enemy_name_by_actor(
				StringName(data.get("enemy_id", ""))
			)
		"ForesightConsumed":
			return "预见生效：本次攻击伤害降低%d。" % int(data.get("reduction", 0))
		"RitualPrepared":
			return "仪式准备完成：下一次标记额外增强。"
		"RiskChanged":
			return "%s %d → %d。" % [
				"污染" if String(data.get("risk_id", "")) == "corruption" else "被注视",
				int(data.get("before", 0)),
				int(data.get("after", 0)),
			]
		"CorruptionOverflow":
			return "污染达到上限，灵魂被污秽吞没。"
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
	if is_instance_valid(_event_scroll):
		call_deferred("_scroll_event_log_to_latest")


func _scroll_event_log_to_latest() -> void:
	if not is_instance_valid(_event_scroll):
		return
	await get_tree().process_frame
	if not is_instance_valid(_event_scroll):
		return
	await get_tree().process_frame
	if not is_instance_valid(_event_scroll):
		return
	var bar := _event_scroll.get_v_scroll_bar()
	_event_scroll.scroll_vertical = int(bar.max_value)


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
	icon_id: String,
	width: float = 112.0
) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", 2)
	result.custom_minimum_size = Vector2(width, 48)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 5)
	title_row.add_child(_status_icon(icon_id, 18))
	title_row.add_child(UiTheme.label(title, 12, UiTheme.C_MUTED))
	result.add_child(title_row)
	var value_label := UiTheme.clip_label(value_text, 21, color)
	value_label.name = "MeterValue"
	result.add_child(value_label)
	_meter_value_labels[title] = value_label
	return result


func _set_meter(meter: VBoxContainer, value_text: String) -> void:
	if not is_instance_valid(meter):
		return
	var value_label := meter.get_node_or_null("MeterValue") as Label
	if is_instance_valid(value_label):
		UiTheme.set_clip_text(value_label, value_text)


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
		&"foresight":
			return "预见"
		&"ritual_preparation":
			return "仪式准备"
		&"bound":
			return "束缚"
		&"evasion":
			return "闪避"
		&"silenced":
			return "失声"
		&"sluggish":
			return "迟缓"
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
				_show_floating_text(anchor, "受到伤害  -%d" % amount, UiTheme.C_DANGER_TEXT)
				_flash_actor(anchor, UiTheme.C_DANGER)
				_shake_actor(anchor)
				_pulse_control(anchor, Color(1.25, 0.48, 0.42, 1))
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
		"ForesightConsumed":
			_show_floating_text(_health_meter, "预见：伤害 -%d" % int(data.get("reduction", 0)), UiTheme.C_GOLD)
		"RitualProgressed":
			_show_floating_text(_health_meter, "仪式准备 %d/3" % int(data.get("after", 0)), UiTheme.C_GOLD)
		"RitualCompleted":
			if bool(data.get("complete", false)):
				_show_banner("仪式完成", "灵性之墙 · 烛火与祭品 · 尊名回应 —— 力量降下。", UiTheme.C_GOLD)
		"SynergyTriggered":
			_show_banner(
				"原著联动 · %s" % String(data.get("display_name_zh", "")),
				String(data.get("source_zh", "")),
				UiTheme.C_GOLD
			)
		"EnemyBound":
			var bound_anchor := _actor_anchor(StringName(data.get("enemy_id", "")))
			if bound_anchor != null:
				_show_floating_text(bound_anchor, "束缚：跳过行动", UiTheme.C_GOLD)
		"AttackEvaded":
			_show_floating_text(_health_meter, "闪避 %d" % int(data.get("evaded", 0)), UiTheme.C_GOLD)
		"PowerStolen":
			var stolen_anchor := _actor_anchor(StringName(data.get("enemy_id", "")))
			if stolen_anchor != null:
				_show_floating_text(stolen_anchor, "攻击 -%d" % int(data.get("amount", 0)), UiTheme.C_GOLD)
		"RiskChanged":
			var is_corruption := String(data.get("risk_id", "")) == "corruption"
			var delta := int(data.get("after", 0)) - int(data.get("before", 0))
			if delta != 0:
				_show_floating_text(
					_corruption_meter if is_corruption else _attention_meter,
					"%s %+d" % ["污染" if is_corruption else "被注视", delta],
					UiTheme.C_DANGER_TEXT if delta > 0 else UiTheme.C_GOLD
				)
		"ChainTriggered":
			_show_floating_text(
				_health_meter,
				"灵性回响！",
				UiTheme.C_GOLD
			)
			_pulse_control(_health_meter, Color(1.18, 1.1, 0.72, 1))
		"EnemyPressureChanged":
			_show_floating_text(_pressure_label, "敌人强化！", UiTheme.C_DANGER_TEXT)
			_pulse_control(_pressure_label, Color(1.25, 0.48, 0.42, 1))
		"EnemyPhaseTriggered":
			_show_banner(
				"%s · %s" % [
					_enemy_name_by_actor(StringName(data.get("enemy_id", ""))),
					String(data.get("display_name_zh", "进入新阶段")),
				],
				String(data.get("description_zh", "")),
				UiTheme.C_DANGER_TEXT
			)
			_pulse_control(_pressure_label, Color(1.25, 0.48, 0.42, 1))


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


## A transient overlay banner on the effects layer. It never participates in
## container layout, so announcing a combo or boss phase cannot move controls.
func _show_banner(title: String, subtitle: String, color: Color) -> void:
	if not is_instance_valid(_effects_layer):
		return
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	var title_label := UiTheme.center_label(title, 30, color)
	title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 1))
	title_label.add_theme_constant_override("outline_size", 6)
	box.add_child(title_label)
	if not subtitle.is_empty():
		var subtitle_label := UiTheme.wrapped_label(subtitle, 15, UiTheme.C_PAPER)
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(subtitle_label)
	var banner := UiTheme.padded_panel(box, 14, Color(0.06, 0.055, 0.045, 0.94), color)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var width := minf(760.0, maxf(320.0, _effects_layer.size.x - 80.0))
	banner.custom_minimum_size = Vector2(width, 0)
	banner.size = Vector2(width, 0)
	banner.position = Vector2((_effects_layer.size.x - width) * 0.5, _effects_layer.size.y * 0.24 + float(_banner_count % 2) * 92.0)
	_effects_layer.add_child(banner)
	_banner_count += 1
	_visual_effect_count += 1
	banner.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.18)
	tween.tween_interval(1.9)
	tween.tween_property(banner, "modulate:a", 0.0, 0.45)
	tween.tween_callback(banner.queue_free)


func get_banner_count() -> int:
	return _banner_count


func _flash_actor(actor: Control, color: Color) -> void:
	if not is_instance_valid(_effects_layer) or not is_instance_valid(actor):
		return
	var flash := ColorRect.new()
	flash.color = Color(color, 0.48)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.position = actor.get_global_rect().position - _effects_layer.global_position
	flash.size = actor.get_global_rect().size
	_effects_layer.add_child(flash)
	_visual_effect_count += 1
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.34)
	tween.tween_callback(flash.queue_free)


func _shake_actor(actor: Control) -> void:
	if not is_instance_valid(actor):
		return
	var origin := actor.position
	var tween := create_tween()
	tween.tween_property(actor, "position", origin + Vector2(9, 0), 0.045)
	tween.tween_property(actor, "position", origin + Vector2(-8, 0), 0.045)
	tween.tween_property(actor, "position", origin + Vector2(5, 0), 0.045)
	tween.tween_property(actor, "position", origin, 0.06)


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
