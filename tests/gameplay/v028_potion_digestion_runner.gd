extends Node

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const DeckCommandScript := preload("res://src/core/deck_command.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const BattleRandomAdapterScript := preload("res://src/infrastructure/battle_random_adapter.gd")
const SeededRandomServiceScript := preload("res://src/infrastructure/seeded_random_service.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var started = AppBootstrapScript.start_route_v07(
		20261109,
		{"test_profile": true, "save_directory": "user://v028_potion_test", "route_id": "route.v028.first_stage"},
		"v028_potion",
		false
	)
	_expect(started.ok, "v0.28 test session should initialize")
	if not started.ok:
		_finish()
		return
	var session = started.data
	var before: Dictionary = session.get_progression_snapshot().data.get("digestion", {})
	_expect(int(before.get("progress", -1)) == 0, "digestion starts at zero")
	for _index in range(8):
		var result = session.record_card_performance(&"card.skill.dream_question")
		_expect(result.accepted, "eligible divination performance should be accepted")
	var ready: Dictionary = session.get_progression_snapshot().data.get("digestion", {})
	_expect(bool(ready.get("ready", false)), "eight eligible performances should ready the potion")
	var unsupported = session.record_card_performance(&"card.skill.ink_dart")
	_expect(unsupported.accepted, "ineligible performance should be a no-op, not an error")
	var potion = session.progression.grant_potion(&"potion.seer_to_clown")
	_expect(potion.accepted, "chapter potion should enter inventory")
	var consumed = session.consume_potion(&"potion.seer_to_clown")
	_expect(consumed.accepted, "ready chapter potion should be consumable")
	_expect(
		int(session.get_progression_snapshot().data.get("digestion", {}).get("consumed", false)) == 1,
		"consumed potion should mark digestion as consumed"
	)
	var repeated = session.consume_potion(&"potion.seer_to_clown")
	_expect(not repeated.accepted, "consumed potion cannot be used twice")
	_expect(
		int(session.get_sequence_state().data.get("current_sequence", 0)) == 8,
		"consuming the potion should advance to sequence eight"
	)
	var clown_unlocked := false
	var deck_snapshot = session.get_deck_snapshot()
	for card in deck_snapshot.data.get("cards", []):
		if String(card.get("definition_id", "")) == "card.skill.hollow_bell":
			clown_unlocked = String(card.get("add_reason_code", "")) != "sequence_locked"
	_expect(clown_unlocked, "sequence eight should lift the sequence lock on clown cards in the deck")
	_test_wave_transition()
	_test_seer_foresight_and_ritual()
	_test_sequence_locked_gacha()
	_finish()


func _test_wave_transition() -> void:
	var cards: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards/v0.7.0/cards.json"))
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/v0.7.0/balance.json"))
	var content := BattleContentAdapterScript.new(cards.get("cards", []))
	var battle := BattleEngineScript.new()
	var initialized = battle.initialize(content, BattleBalanceAdapterScript.new(balance), BattleRandomAdapterScript.new(SeededRandomServiceScript.new(7).get_stream(&"v028.wave")), &"v028.wave", {
		"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0, "spirit": 3, "max_spirit": 3,
		"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10, "statuses": []
	}, [&"card.skill.ink_dart"], [
		{"id": "wave.one", "definition_id": "enemy.weeping_tenant", "lane_index": 1, "hp": 1, "max_hp": 1, "base_attack": 0, "wave_index": 0, "phases": []},
		{"id": "wave.two", "definition_id": "enemy.candle_moth", "lane_index": 1, "hp": 1, "max_hp": 1, "base_attack": 0, "wave_index": 1, "phases": []}
	])
	_expect(initialized.accepted, "wave fixture should initialize")
	if not initialized.accepted:
		return
	var card_id: StringName = StringName(battle.get_snapshot().data.get("hand", [])[0].get("instance_id", ""))
	var result = battle.submit(BattleCommandScript.play_card(card_id, &"wave.one"))
	_expect(result.accepted, "first wave should accept lethal card")
	_expect(String(result.snapshot.data.get("outcome", "")) == "", "first wave should not end battle")
	_expect(result.events.any(func(event): return event.type == &"EnemyWaveArrived"), "next wave event should be emitted")


func _test_seer_foresight_and_ritual() -> void:
	var cards: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards/v0.7.0/cards.json"))
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/v0.7.0/balance.json"))
	var content := BattleContentAdapterScript.new(cards.get("cards", []))
	var battle := BattleEngineScript.new()
	var initialized = battle.initialize(content, BattleBalanceAdapterScript.new(balance), BattleRandomAdapterScript.new(SeededRandomServiceScript.new(11).get_stream(&"v028.seer")), &"v028.seer", {
		"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0, "spirit": 3, "max_spirit": 3,
		"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10, "statuses": []
	}, [&"card.skill.second_look", &"card.skill.ink_dart", &"card.skill.ink_dart", &"card.skill.ink_dart", &"card.skill.ink_dart"], [
		{"id": "seer.target", "definition_id": "enemy.weeping_tenant", "lane_index": 1, "hp": 20, "max_hp": 20, "base_attack": 2, "wave_index": 0, "phases": []}
	])
	_expect(initialized.accepted, "seer fixture should initialize")
	if not initialized.accepted:
		return
	var second_sight_id := _hand_instance_for(battle, &"card.skill.second_look")
	var sight_result = battle.submit(BattleCommandScript.play_card(second_sight_id, &"seer.target"))
	_expect(sight_result.accepted, "spirit vision should reveal an intent")
	_expect(_has_status(sight_result.snapshot.data.get("player", {}).get("statuses", []), &"foresight"), "revealing intent should grant foresight")
	var hp_before := int(sight_result.snapshot.data.get("player", {}).get("hp", 0))
	var end_result = battle.submit(BattleCommandScript.end_turn())
	_expect(int(end_result.snapshot.data.get("player", {}).get("hp", 0)) == hp_before - 1, "foresight should reduce the next attack by one")
	var prep_battle := BattleEngineScript.new()
	var prep_initialized = prep_battle.initialize(content, BattleBalanceAdapterScript.new(balance), BattleRandomAdapterScript.new(SeededRandomServiceScript.new(13).get_stream(&"v028.ritual")), &"v028.ritual", {
		"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0, "spirit": 3, "max_spirit": 3,
		"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10, "statuses": []
	}, [&"card.skill.borrowed_breath", &"card.skill.candle_archive", &"card.skill.paper_guard", &"card.skill.warding_circle", &"card.skill.ink_dart"], [
		{"id": "ritual.target", "definition_id": "enemy.weeping_tenant", "lane_index": 1, "hp": 20, "max_hp": 20, "base_attack": 0, "wave_index": 0, "phases": []}
	])
	_expect(prep_initialized.accepted, "ritual fixture should initialize")
	if not prep_initialized.accepted:
		return
	for prep_card in [&"card.skill.borrowed_breath", &"card.skill.candle_archive", &"card.skill.paper_guard"]:
		var prep_id := _hand_instance_for(prep_battle, prep_card)
		_expect(prep_battle.submit(BattleCommandScript.play_card(prep_id)).accepted, "ritual preparation should accept %s" % prep_card)
	var ritual_view: Dictionary = prep_battle.get_snapshot().data.get("ritual", {})
	_expect(int(ritual_view.get("stacks", 0)) == 3, "three preparation cards fill the ritual track")
	var finisher_id := _hand_instance_for(prep_battle, &"card.skill.warding_circle")
	var finisher_result = prep_battle.submit(BattleCommandScript.play_card(finisher_id, &"ritual.target"))
	_expect(finisher_result.accepted, "exorcism ritual should be accepted with two spirit left")
	var target: Dictionary = finisher_result.snapshot.data.get("enemies", [])[0]
	_expect(int(target.get("hp", 0)) == 7, "full ritual adds three damage per stack (4 + 9 = 13)")
	_expect(int(finisher_result.snapshot.data.get("ritual", {}).get("stacks", -1)) == 0, "ritual finisher consumes every stack")
	_expect(
		finisher_result.events.any(func(event): return event.type == &"RitualCompleted" and bool(event.data.get("complete", false))),
		"a full three-step ritual emits RitualCompleted(complete=true)"
	)


func _hand_instance_for(battle: BattleEngine, definition_id: StringName) -> StringName:
	for card in battle.get_snapshot().data.get("hand", []):
		if StringName(card.get("definition_id", "")) == definition_id:
			return StringName(card.get("instance_id", ""))
	return &""


func _has_status(statuses: Variant, status_id: StringName) -> bool:
	return _status_stacks(statuses, status_id) > 0


func _status_stacks(statuses: Variant, status_id: StringName) -> int:
	if statuses is Array:
		for status in statuses:
			if status is Dictionary and StringName(status.get("status_id", "")) == status_id:
				return int(status.get("stacks", 0))
	return 0


func _test_sequence_locked_gacha() -> void:
	var started = AppBootstrapScript.start_route_v07(
		20261110,
		{"test_profile": true, "save_directory": "user://v0291_sequence_lock", "route_id": "route.v028.first_stage"},
		"v0291_sequence_lock",
		false
	)
	_expect(started.ok, "sequence lock fixture should initialize")
	if not started.ok:
		return
	var session = started.data
	var pulled = session.submit_progression(ProgressionCommandScript.draw_gacha(1))
	_expect(pulled.accepted, "sequence lock fixture should allow a gacha pull")
	if not pulled.accepted:
		return
	var last_results: Array = pulled.snapshot.data.get("last_gacha_results", [])
	if not last_results.is_empty():
		var definition_id := StringName(last_results[0].get("definition_id", ""))
		var definition: Dictionary = session.catalog.get_card(definition_id)
		var band := String(definition.get("sequence_band", ""))
		_expect(not band.contains("序列8") and not band.contains("→8"), "sequence 9 gacha must not offer sequence 8 cards")


func _finish() -> void:
	if _failures.is_empty():
		print("V028_POTION_DIGESTION_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V028_POTION_DIGESTION_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
