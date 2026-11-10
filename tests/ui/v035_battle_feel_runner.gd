extends Node

## v0.35.0: battle table feel — diegetic meters, aim overlay, intent rows,
## synergy-hint meta on hand cards. Does not simulate OS drag in headless;
## verifies the control surface exists and snapshot-driven presentation works.

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const BattleTableFeel := preload("res://src/ui/battle_table_feel.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_expect(
		BattleTableFeel.intent_icon_id("attack") == "attack",
		"attack intent maps to attack icon"
	)
	_expect(
		BattleTableFeel.intent_icon_id("curse") == "corruption",
		"curse intent maps to corruption icon"
	)
	_expect(
		BattleTableFeel.intent_icon_id("defend", {"block": 4, "damage": 0}) == "block",
		"defend/block intent maps to block icon"
	)
	var hints := BattleTableFeel.missing_definition_ids([
		{
			"in_deck": true,
			"triggered_this_turn": false,
			"satisfied": [true, false],
			"requires": [["card.a"], ["card.b", "card.c"]],
		}
	])
	_expect(hints.has("card.b") and hints.has("card.c"), "partial synergy exposes missing ids")
	_expect(not hints.has("card.a"), "satisfied group is not hinted")

	var cards_document: Dictionary = _read_json("res://data/cards/v0.7.0/cards.json")
	var catalog = CampaignContentCatalogScript.new()
	var loaded = catalog.load_from_documents(
		cards_document,
		_read_json("res://data/enemies/v0.7.0/enemies.json"),
		_read_json("res://data/encounters/v0.7.0/encounters.json")
	)
	_expect(loaded.ok, "canon catalog loads")
	var resolved = catalog.resolve_encounter(&"encounter.first_hunt")
	_expect(resolved.ok, "first_hunt resolves")

	var engine = BattleEngineScript.new()
	var content = BattleContentAdapterScript.new(
		cards_document.get("cards", []),
		cards_document.get("synergies", [])
	)
	var init_result = engine.initialize(
		content,
		BattleBalanceAdapterScript.new(_read_json("res://data/balance/v0.7.0/balance.json")),
		FixedRandom.new(35),
		&"battle.v035.feel",
		{
			"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0,
			"spirit": 3, "max_spirit": 3, "corruption": 2, "max_corruption": 10,
			"attention": 1, "max_attention": 10, "statuses": [],
		},
		[
			"card.skill.ink_dart",
			"card.skill.paper_guard",
			"card.skill.calm_breath",
			"card.skill.focus",
			"card.skill.insight",
			"card.skill.omen",
			"card.skill.whisper",
			"card.skill.second_look",
		],
		resolved.data.enemy_configs
	)
	_expect(init_result.accepted, "battle initializes")

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = BattleScreenScene.instantiate()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var labels := {}
	var details := {}
	for card in cards_document.get("cards", []):
		labels[StringName(card.get("id", ""))] = String(card.get("display_name_zh", ""))
		details[String(card.get("id", ""))] = {
			"name": String(card.get("display_name_zh", "")),
			"effect_text": String(card.get("rules_text_zh", "")),
			"category": String(card.get("category", "")),
			"exhaust": bool(card.get("exhaust", false)),
			"source_zh": String(card.get("source_zh", "")),
		}
	var enemy_labels := {}
	for config in resolved.data.get("enemy_configs", []):
		enemy_labels[StringName(config.get("definition_id", ""))] = String(config.get("display_name_zh", ""))
	screen.configure(
		"v0.35 feel",
		labels,
		enemy_labels,
		func(card_id: StringName, target_id: StringName) -> BattlePlayability:
			return engine.query_card_play(card_id, target_id),
		details
	)
	screen.apply_snapshot(engine.get_snapshot())
	await _frames(4)

	_expect(screen.find_child("AimOverlay", true, false) != null, "AimOverlay exists")
	_expect(screen.find_child("EnemyLanesRow", true, false) != null, "EnemyLanesRow exists")
	_expect(screen.find_child("EnemyStatusScroll", true, false) == null, "nested enemy scroll removed")
	var health_meter: Control = screen.get("_health_meter")
	_expect(health_meter != null and health_meter.find_child("MeterBar", true, false) != null, "health meter has MeterBar")
	_expect(health_meter.find_child("MeterValue", true, false) != null, "health meter has MeterValue")
	var spirit_meter: Control = screen.get("_spirit_meter")
	_expect(spirit_meter != null and spirit_meter.find_child("MeterBar", true, false) != null, "spirit meter has MeterBar")

	var intent_rows := 0
	var lane_root: Node = screen.find_child("EnemyLanesRow", true, false)
	if lane_root != null:
		for lane in lane_root.get_children():
			if lane.find_child("IntentRow", true, false) != null:
				intent_rows += 1
	_expect(intent_rows > 0, "at least one IntentRow rendered")

	var hand_row: Node = screen.get("_hand_row")
	_expect(hand_row != null, "hand row exists")
	var hand_cards := 0
	if hand_row != null:
		for child in hand_row.get_children():
			if child is PanelContainer and child.has_meta("battle_instance_id"):
				hand_cards += 1
				_expect(child.has_meta("battle_definition_id"), "hand card stores definition id")
	_expect(hand_cards > 0, "hand cards rendered")

	# Click-select fallback still works.
	var first_id := StringName("")
	for card in engine.get_snapshot().data.get("hand", []):
		first_id = StringName(card.get("instance_id", ""))
		break
	_expect(not first_id.is_empty(), "has a hand instance")
	screen.select_card_instance(first_id, false)
	_expect(String(screen.get("_selection_card_id")) == String(first_id), "select without toggle keeps card")
	_expect(not bool(screen.is_drag_active()), "drag inactive after click select")

	viewport.queue_free()
	await _frames(1)
	_finish()


func _frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _finish() -> void:
	if _failures.is_empty():
		print("V035_BATTLE_FEEL_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V035_BATTLE_FEEL_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


class FixedRandom:
	extends BattleRandomPort

	var state := 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
