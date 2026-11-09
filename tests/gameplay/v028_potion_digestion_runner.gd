extends Node

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
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
		var result = session.record_card_performance(&"card.skill.omen")
		_expect(result.accepted, "eligible divination performance should be accepted")
	var ready: Dictionary = session.get_progression_snapshot().data.get("digestion", {})
	_expect(bool(ready.get("ready", false)), "eight eligible performances should ready the potion")
	var unsupported = session.record_card_performance(&"card.skill.paper_guard")
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
	_test_wave_transition()
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
