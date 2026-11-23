extends Node

## v0.35: unconditional discard effects require a chosen hand card.
## Covers 冥想 (focus) and 安静发丝 (black_thread).

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")

var _checks := 0
var _failures: Array[String] = []
var _cards_document: Dictionary


func _ready() -> void:
	_cards_document = _read_json("res://data/cards/v0.7.0/cards.json")
	_test_focus_requires_choice()
	_test_focus_discards_chosen_card()
	_test_black_thread_requires_choice()
	_finish()


func _test_focus_requires_choice() -> void:
	var engine = _make_engine(
		[&"card.skill.focus", &"card.skill.ink_dart", &"card.skill.paper_guard"],
		[_enemy(&"enemy.a", 0, 20, 1)]
	)
	var focus_id := _hand_instance(engine, &"card.skill.focus")
	var ink_id := _hand_instance(engine, &"card.skill.ink_dart")
	var denied = engine.query_card_play(focus_id)
	_expect(
		not denied.playable and denied.reason_code == BattlePlayability.NEED_DISCARD_CHOICE,
		"focus without discard choice is blocked"
	)
	var rejected = engine.submit(BattleCommandScript.play_card(focus_id))
	_expect(not rejected.accepted, "focus play without discard is rejected")
	var ok = engine.query_card_play(focus_id, &"", [ink_id])
	_expect(ok.playable, "focus with chosen discard is playable")


func _test_focus_discards_chosen_card() -> void:
	var engine = _make_engine(
		[&"card.skill.focus", &"card.skill.ink_dart", &"card.skill.paper_guard"],
		[_enemy(&"enemy.a", 0, 20, 1)]
	)
	var focus_id := _hand_instance(engine, &"card.skill.focus")
	var ink_id := _hand_instance(engine, &"card.skill.ink_dart")
	var guard_id := _hand_instance(engine, &"card.skill.paper_guard")
	var before_spirit := int(engine.get_snapshot().data["player"]["spirit"])
	var result = engine.submit(BattleCommandScript.play_card(focus_id, &"", [ink_id]))
	_expect(result.accepted, "focus with discard accepted")
	_expect(
		int(result.snapshot.data["player"]["spirit"]) == before_spirit + 1,
		"focus still grants +1 spirit"
	)
	var remaining: Array = []
	for card in result.snapshot.data.get("hand", []):
		remaining.append(String(card.get("instance_id", "")))
	_expect(not remaining.has(String(ink_id)), "chosen ink dart was discarded")
	_expect(remaining.has(String(guard_id)), "unchosen paper guard remains")
	var discarded_event := false
	for event in result.events:
		if event.type == &"CardDiscarded" and String(event.data.get("reason_code", "")) == "effect":
			if String(event.data.get("card_instance_id", "")) == String(ink_id):
				discarded_event = true
	_expect(discarded_event, "CardDiscarded effect event names chosen card")


func _test_black_thread_requires_choice() -> void:
	var engine = _make_engine(
		[&"card.skill.black_thread", &"card.skill.calm_breath"],
		[_enemy(&"enemy.a", 0, 40, 3)]
	)
	var thread_id := _hand_instance(engine, &"card.skill.black_thread")
	var calm_id := _hand_instance(engine, &"card.skill.calm_breath")
	var enemy_id := StringName(engine.get_snapshot().data["enemies"][0]["actor_id"])
	var denied = engine.query_card_play(thread_id, enemy_id)
	_expect(
		not denied.playable and denied.reason_code == BattlePlayability.NEED_DISCARD_CHOICE,
		"black_thread without discard choice is blocked"
	)
	var ok = engine.query_card_play(thread_id, enemy_id, [calm_id])
	_expect(ok.playable, "black_thread with discard and enemy is playable")
	var result = engine.submit(BattleCommandScript.play_card(thread_id, enemy_id, [calm_id]))
	_expect(result.accepted, "black_thread play accepted")
	var remaining_ids: Array = []
	for card in result.snapshot.data.get("hand", []):
		remaining_ids.append(String(card.get("instance_id", "")))
	_expect(not remaining_ids.has(String(calm_id)), "black_thread discarded chosen calm breath")


func _make_engine(deck: Array, enemies: Array):
	var engine = BattleEngineScript.new()
	var content = BattleContentAdapterScript.new(
		_cards_document.get("cards", []),
		_cards_document.get("synergies", [])
	)
	var result = engine.initialize(
		content,
		BattleBalanceAdapterScript.new(_read_json("res://data/balance/v0.7.0/balance.json")),
		FixedRandom.new(35),
		&"battle.v035.discard",
		{
			"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0,
			"spirit": 3, "max_spirit": 3, "corruption": 0, "max_corruption": 10,
			"attention": 0, "max_attention": 10, "statuses": [],
		},
		deck,
		enemies
	)
	_expect(result.accepted, "engine initializes for discard tests")
	return engine


func _hand_instance(engine, definition_id: StringName) -> StringName:
	for card in engine.get_snapshot().data.get("hand", []):
		if StringName(card.get("definition_id", "")) == definition_id:
			return StringName(card.get("instance_id", ""))
	_expect(false, "hand contains %s" % String(definition_id))
	return &""


func _enemy(actor_id: StringName, lane: int, hp: int, attack: int) -> Dictionary:
	return {
		"id": actor_id,
		"definition_id": &"enemy.test_dummy",
		"lane_index": lane,
		"hp": hp,
		"max_hp": hp,
		"base_attack": attack,
	}


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _finish() -> void:
	if _failures.is_empty():
		print("V035_DISCARD_CHOICE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V035_DISCARD_CHOICE_FAIL %s" % failure)
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
