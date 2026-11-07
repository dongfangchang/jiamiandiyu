extends Node

const BattleEngineScript = preload("res://src/gameplay/battle_engine.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_valid_play_and_duplicate_rejection()
	_test_insufficient_spirit_and_invalid_target()
	_test_block_absorbs_enemy_damage()
	_test_mark_is_consumed_by_next_damage()
	_test_weaken_reduces_next_attack()
	_test_victory_and_defeat_outcomes()
	_test_round_limit()
	_test_enemy_pressure()
	_test_deterministic_replay()
	_test_invalid_card_definition()

	if _failures.is_empty():
		print("GAMEPLAY_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("GAMEPLAY_TEST_FAILURE: %s" % failure)
	printerr("GAMEPLAY_TESTS_FAILED checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)


func _test_valid_play_and_duplicate_rejection() -> void:
	var engine: BattleEngine = _make_engine(
		[&"card.test.ink_dart"],
		[_enemy(&"enemy.a", 0, 10, 1)]
	)
	var instance_id: StringName = _hand_instance(engine, &"card.test.ink_dart")
	var result: BattleCommandResult = engine.submit(BattleCommand.play_card(instance_id, &"enemy.a"))
	_check(result.accepted, "valid card should be accepted")
	_check(result.reason_code == &"ok", "valid card should return ok")
	_check(_enemy_hp(result.snapshot, &"enemy.a") == 6, "ink dart should deal 4 damage")
	_check(int(result.snapshot.data["player"]["spirit"]) == 2, "valid card should spend 1 spirit")

	var duplicate: BattleCommandResult = engine.submit(BattleCommand.play_card(instance_id, &"enemy.a"))
	_check(not duplicate.accepted, "duplicate card play should be rejected")
	_check(
		duplicate.reason_code == BattlePlayability.CARD_NOT_IN_HAND,
		"duplicate card should report card_not_in_hand"
	)
	_check(duplicate.events.is_empty(), "rejected command should not emit events")
	_check(
		int(duplicate.snapshot.data["player"]["spirit"]) == 2,
		"rejected duplicate should not spend spirit"
	)


func _test_insufficient_spirit_and_invalid_target() -> void:
	var engine: BattleEngine = _make_engine(
		[&"card.test.expensive", &"card.test.ink_dart"],
		[_enemy(&"enemy.a", 0, 10, 1)]
	)
	var expensive_id: StringName = _hand_instance(engine, &"card.test.expensive")
	var expensive: BattleCommandResult = engine.submit(
		BattleCommand.play_card(expensive_id, &"enemy.a")
	)
	_check(not expensive.accepted, "unaffordable card should be rejected")
	_check(
		expensive.reason_code == BattlePlayability.INSUFFICIENT_SPIRIT,
		"unaffordable card should report insufficient_spirit"
	)

	var damage_id: StringName = _hand_instance(engine, &"card.test.ink_dart")
	var invalid: BattleCommandResult = engine.submit(BattleCommand.play_card(damage_id))
	_check(not invalid.accepted, "enemy-target card without target should be rejected")
	_check(
		invalid.reason_code == BattlePlayability.INVALID_TARGET,
		"missing enemy target should report invalid_target"
	)


func _test_block_absorbs_enemy_damage() -> void:
	var engine: BattleEngine = _make_engine(
		[&"card.test.paper_guard"],
		[_enemy(&"enemy.a", 0, 20, 5)]
	)
	var instance_id: StringName = _hand_instance(engine, &"card.test.paper_guard")
	var play_result: BattleCommandResult = engine.submit(BattleCommand.play_card(instance_id))
	_check(play_result.accepted, "self-target block card should be accepted")
	_check(int(play_result.snapshot.data["player"]["block"]) == 5, "block card should add 5 block")

	var end_turn_result: BattleCommandResult = engine.submit(BattleCommand.end_turn())
	_check(end_turn_result.accepted, "end turn should be accepted")
	_check(
		int(end_turn_result.snapshot.data["player"]["hp"]) == 20,
		"five block should fully absorb five damage"
	)
	_check(
		int(end_turn_result.snapshot.data["player"]["block"]) == 0,
		"block should reset at the next round start"
	)


func _test_mark_is_consumed_by_next_damage() -> void:
	var engine: BattleEngine = _make_engine(
		[&"card.test.omen", &"card.test.ink_dart"],
		[_enemy(&"enemy.a", 0, 20, 1)]
	)
	var omen_id: StringName = _hand_instance(engine, &"card.test.omen")
	engine.submit(BattleCommand.play_card(omen_id, &"enemy.a"))
	var damage_id: StringName = _hand_instance(engine, &"card.test.ink_dart")
	var result: BattleCommandResult = engine.submit(BattleCommand.play_card(damage_id, &"enemy.a"))
	_check(result.accepted, "damage after mark should be accepted")
	_check(_enemy_hp(result.snapshot, &"enemy.a") == 14, "mark should add 2 to the next damage")
	var statuses: Array = _enemy_view(result.snapshot, &"enemy.a")["statuses"]
	_check(_status_index(statuses, &"mark") < 0, "mark should be consumed by the next damage")


func _test_weaken_reduces_next_attack() -> void:
	var engine: BattleEngine = _make_engine(
		[&"card.test.whisper"],
		[_enemy(&"enemy.a", 0, 20, 5)]
	)
	var whisper_id: StringName = _hand_instance(engine, &"card.test.whisper")
	engine.submit(BattleCommand.play_card(whisper_id, &"enemy.a"))
	var result: BattleCommandResult = engine.submit(BattleCommand.end_turn())
	_check(result.accepted, "end turn after weaken should be accepted")
	_check(
		int(result.snapshot.data["player"]["hp"]) == 17,
		"weaken should reduce five damage to three"
	)
	var statuses: Array = _enemy_view(result.snapshot, &"enemy.a")["statuses"]
	_check(_status_index(statuses, &"weaken") < 0, "weaken duration should expire after the attack")


func _test_victory_and_defeat_outcomes() -> void:
	var victory_engine: BattleEngine = _make_engine(
		[&"card.test.ink_dart"],
		[_enemy(&"enemy.a", 0, 3, 1)]
	)
	var damage_id: StringName = _hand_instance(victory_engine, &"card.test.ink_dart")
	var victory: BattleCommandResult = victory_engine.submit(
		BattleCommand.play_card(damage_id, &"enemy.a")
	)
	_check(
		victory.snapshot.data["outcome"] == "victory",
		"killing all enemies should produce victory"
	)

	var defeat_engine: BattleEngine = _make_engine(
		[&"card.test.paper_guard"],
		[_enemy(&"enemy.a", 0, 20, 50)],
		{"hp": 2}
	)
	var defeat: BattleCommandResult = defeat_engine.submit(BattleCommand.end_turn())
	_check(
		defeat.snapshot.data["outcome"] == "defeat",
		"lethal enemy action should produce defeat"
	)
	_check(
		defeat.snapshot.data["outcome_reason"] == "player_died",
		"defeat should report player_died"
	)


func _test_round_limit() -> void:
	var engine: BattleEngine = _make_engine(
		[&"card.test.paper_guard"],
		[_enemy(&"enemy.a", 0, 50, 1)],
		{},
		{"battle.max_rounds": 1}
	)
	var result: BattleCommandResult = engine.submit(BattleCommand.end_turn())
	_check(
		result.snapshot.data["outcome"] == "defeat",
		"exceeding max rounds should produce defeat"
	)
	_check(
		result.snapshot.data["outcome_reason"] == "round_limit",
		"round limit defeat should report round_limit"
	)


func _test_enemy_pressure() -> void:
	var engine: BattleEngine = _make_engine(
		[&"card.test.paper_guard"],
		[_enemy(&"enemy.a", 0, 200, 1)],
		{"hp": 200, "max_hp": 200}
	)
	var result: BattleCommandResult
	for _round_index in range(7):
		result = engine.submit(BattleCommand.end_turn())
		_check(result.accepted, "end turn should remain accepted during pressure test")
	_check(
		int(result.snapshot.data["enemy_pressure_bonus"]) == 1,
		"enemy pressure should increase by one after round seven"
	)
	var intent_damage: int = int(
		_enemy_view(result.snapshot, &"enemy.a")["intent"]["damage"]
	)
	_check(intent_damage == 2, "pressure should raise the next intent from one to two")


func _test_deterministic_replay() -> void:
	var deck: Array[StringName] = [
		&"card.test.ink_dart",
		&"card.test.paper_guard",
		&"card.test.insight",
		&"card.test.ink_dart",
	]
	var first: BattleEngine = _make_engine(
		deck,
		[_enemy(&"enemy.a", 0, 30, 1), _enemy(&"enemy.b", 1, 30, 1)],
		{},
		{},
		20261108
	)
	var second: BattleEngine = _make_engine(
		deck,
		[_enemy(&"enemy.a", 0, 30, 1), _enemy(&"enemy.b", 1, 30, 1)],
		{},
		{},
		20261108
	)
	_check(
		first.get_snapshot().to_dictionary() == second.get_snapshot().to_dictionary(),
		"same seed should produce identical initial snapshots"
	)
	var first_result: BattleCommandResult = first.submit(BattleCommand.end_turn())
	var second_result: BattleCommandResult = second.submit(BattleCommand.end_turn())
	_check(
		first_result.to_dictionary() == second_result.to_dictionary(),
		"same seed and commands should produce identical results"
	)


func _test_invalid_card_definition() -> void:
	var content: FakeContent = FakeContent.new()
	var invalid_definition: Dictionary = content.cards[&"card.test.ink_dart"].duplicate(true)
	invalid_definition["effects"] = [{"effect_id": "effect.not_registered"}]
	content.cards[&"card.test.invalid"] = invalid_definition
	content.cards[&"card.test.invalid"]["id"] = "card.test.invalid"
	var engine: BattleEngine = BattleEngineScript.new()
	var balance: FakeBalance = FakeBalance.new()
	var random: FakeRandom = FakeRandom.new(1)
	var result: BattleCommandResult = engine.initialize(
		content,
		balance,
		random,
		&"battle.invalid",
		_player_state(),
		[&"card.test.invalid"],
		[_enemy(&"enemy.a", 0, 10, 1)]
	)
	_check(not result.accepted, "unregistered effect should reject initialization")
	_check(
		result.reason_code == &"card_definition_invalid",
		"invalid effect should report card_definition_invalid"
	)


func _make_engine(
	deck: Array,
	enemies: Array,
	player_overrides: Dictionary = {},
	balance_overrides: Dictionary = {},
	seed: int = 7
) -> BattleEngine:
	var content: FakeContent = FakeContent.new()
	var balance: FakeBalance = FakeBalance.new()
	for key in balance_overrides:
		balance.values[StringName(key)] = balance_overrides[key]
	var random: FakeRandom = FakeRandom.new(seed)
	var engine: BattleEngine = BattleEngineScript.new()
	var player: Dictionary = _player_state()
	for key in player_overrides:
		player[String(key)] = player_overrides[key]
	var result: BattleCommandResult = engine.initialize(
		content,
		balance,
		random,
		&"battle.test",
		player,
		deck,
		enemies
	)
	_check(result.accepted, "test engine should initialize: %s" % result.reason_code)
	return engine


func _player_state() -> Dictionary:
	return {
		"actor_id": &"player",
		"hp": 20,
		"max_hp": 20,
		"block": 0,
		"spirit": 3,
		"max_spirit": 3,
		"corruption": 0,
		"max_corruption": 10,
		"attention": 0,
		"max_attention": 10,
		"statuses": [],
	}


func _enemy(
	enemy_id: StringName,
	lane_index: int,
	hp: int,
	base_attack: int
) -> Dictionary:
	return {
		"id": enemy_id,
		"definition_id": &"enemy.test_dummy",
		"lane_index": lane_index,
		"hp": hp,
		"max_hp": hp,
		"base_attack": base_attack,
	}


func _hand_instance(engine: BattleEngine, definition_id: StringName) -> StringName:
	var snapshot: Dictionary = engine.get_snapshot().to_dictionary()
	for card in snapshot["hand"]:
		if StringName(card["definition_id"]) == definition_id:
			return StringName(card["instance_id"])
	_check(false, "expected card in hand: %s" % definition_id)
	return &""


func _enemy_view(snapshot: BattleSnapshot, enemy_id: StringName) -> Dictionary:
	for enemy in snapshot.data["enemies"]:
		if StringName(enemy["actor_id"]) == enemy_id:
			return enemy
	_check(false, "expected enemy view: %s" % enemy_id)
	return {}


func _enemy_hp(snapshot: BattleSnapshot, enemy_id: StringName) -> int:
	return int(_enemy_view(snapshot, enemy_id).get("hp", -1))


func _status_index(statuses: Array, status_id: StringName) -> int:
	for index in range(statuses.size()):
		if StringName(statuses[index].get("status_id", "")) == status_id:
			return index
	return -1


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


class FakeContent:
	extends BattleContentPort

	var cards: Dictionary = {}

	func _init() -> void:
		cards = {
			&"card.test.ink_dart": {
				"id": "card.test.ink_dart",
				"category": "echo",
				"cost_spirit": 1,
				"target_type": "enemy",
				"effects": [{"effect_id": "damage", "amount": 4}],
			},
			&"card.test.paper_guard": {
				"id": "card.test.paper_guard",
				"category": "echo",
				"cost_spirit": 1,
				"target_type": "self",
				"effects": [{"effect_id": "block", "amount": 5}],
			},
			&"card.test.expensive": {
				"id": "card.test.expensive",
				"category": "echo",
				"cost_spirit": 4,
				"target_type": "enemy",
				"effects": [{"effect_id": "damage", "amount": 13}],
			},
			&"card.test.omen": {
				"id": "card.test.omen",
				"category": "echo",
				"cost_spirit": 1,
				"target_type": "enemy",
				"effects": [{
					"effect_id": "apply_status",
					"status_id": "mark",
					"stacks": 2,
					"duration": 2,
					"max_stacks": 5,
				}],
			},
			&"card.test.whisper": {
				"id": "card.test.whisper",
				"category": "echo",
				"cost_spirit": 1,
				"target_type": "enemy",
				"effects": [{
					"effect_id": "apply_status",
					"status_id": "weaken",
					"stacks": 2,
					"duration": 1,
				}],
			},
			&"card.test.insight": {
				"id": "card.test.insight",
				"category": "echo",
				"cost_spirit": 0,
				"target_type": "none",
				"effects": [{"effect_id": "draw", "count": 1}],
			},
		}

	func get_card_definition(definition_id: StringName) -> Dictionary:
		return cards.get(definition_id, {}).duplicate(true)


class FakeBalance:
	extends BattleBalancePort

	var values: Dictionary = {
		&"battle.max_rounds": 10,
		&"player.starting_hand": 5,
		&"player.turn_draw_to_hand_size": 5,
		&"player.max_hand_size": 8,
		&"battle.enemy_pressure_start_round": 7,
	}

	func get_value(parameter_id: StringName) -> Variant:
		return values.get(parameter_id)


class FakeRandom:
	extends BattleRandomPort

	var state: int = 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
