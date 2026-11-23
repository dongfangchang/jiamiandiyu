extends Node

## v0.36.0: battle participation — turn stamp, discard altar, aim preview helpers.
## Does not simulate OS drag; verifies presentation surface + snapshot-driven copy.

const BattleScreenScene := preload("res://scenes/ui/battle_screen.tscn")
const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const BattleTableFeel := preload("res://src/ui/battle_table_feel.gd")
const BattlePlayability := preload("res://src/core/battle_playability.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_expect(
		BattleTableFeel.turn_stamp_zh("player_action").contains("你的回合"),
		"player turn stamp copy"
	)
	_expect(
		BattleTableFeel.turn_stamp_zh("enemy_action").contains("敌方"),
		"enemy turn stamp copy"
	)
	_expect(
		BattleTableFeel.discard_altar_zh(1, 2, "冥想").contains("献出"),
		"discard altar copy"
	)
	_expect(
		BattleTableFeel.clip_aim_preview(
			"造成5点物理伤害；若目标处于束缚，额外造成3点；再叠加仪式与连携说明。",
			20
		).contains("…"),
		"long aim preview is clipped"
	)

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
		FixedRandom.new(36),
		&"battle.v036.participation",
		{
			"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0,
			"spirit": 3, "max_spirit": 3, "corruption": 2, "max_corruption": 10,
			"attention": 1, "max_attention": 10, "statuses": [],
		},
		[
			"card.skill.focus",
			"card.skill.ink_dart",
			"card.skill.paper_guard",
			"card.skill.calm_breath",
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
		enemy_labels[StringName(config.get("definition_id", ""))] = String(
			config.get("display_name_zh", "")
		)
	screen.configure(
		"v0.36 participation",
		labels,
		enemy_labels,
		func(card_id: StringName, target_id: StringName, discard_ids: Array) -> BattlePlayability:
			return engine.query_card_play(card_id, target_id, discard_ids),
		details
	)
	screen.apply_snapshot(engine.get_snapshot())
	await _frames(4)

	_expect(screen.find_child("TurnStamp", true, false) != null, "TurnStamp exists")
	_expect(screen.get_turn_stamp_text().contains("你的回合"), "turn stamp shows player action")
	_expect(screen.find_child("DiscardAltar", true, false) != null, "DiscardAltar exists")
	_expect(not screen.is_discard_altar_active(), "altar idle before discard card selected")
	_expect(screen.find_child("AimPreview", true, false) != null, "AimPreview exists")

	var focus_id := StringName("")
	for card in engine.get_snapshot().data.get("hand", []):
		if String(card.get("definition_id", "")) == "card.skill.focus":
			focus_id = StringName(card.get("instance_id", ""))
			break
	_expect(not focus_id.is_empty(), "focus is in opening hand")
	screen.select_card_instance(focus_id, false)
	await _frames(2)
	_expect(screen.is_discard_altar_active(), "altar activates for focus discard cost")
	_expect(screen.get_discard_altar_text().contains("献出"), "altar shows offering copy")

	var other_id := StringName("")
	for card in engine.get_snapshot().data.get("hand", []):
		var iid := StringName(card.get("instance_id", ""))
		if iid != focus_id:
			other_id = iid
			break
	_expect(not other_id.is_empty(), "another hand card exists for discard mark")
	screen.toggle_discard_choice(other_id)
	await _frames(1)
	_expect(screen.get_discard_altar_text().contains("1 /"), "altar counts marked discard")

	screen.cancel_selection()
	await _frames(1)
	_expect(not screen.is_discard_altar_active(), "altar returns to idle after cancel")

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
		print("V036_BATTLE_PARTICIPATION_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V036_BATTLE_PARTICIPATION_FAIL %s" % failure)
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
