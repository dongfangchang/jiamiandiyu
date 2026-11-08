extends Node

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_formal_chain_configuration()
	_test_zero_cost_and_threshold()
	_test_rejected_action_does_not_advance()
	_test_chain_trigger_kills_all()
	_test_direct_kill_does_not_emit_empty_echo()
	_test_echo_draw_reshuffle_and_hand_limit()
	_test_turn_end_resets_chain()
	_test_deterministic_replay()
	if _failures.is_empty():
		print("V0100_CHAIN_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V0100_CHAIN_FAIL: %s" % failure)
	get_tree().quit(1)


func _test_formal_chain_configuration() -> void:
	var balance: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://data/balance/v0.7.0/balance.json"
		)
	)
	var chain: Dictionary = balance.get("combat", {}).get("chain", {})
	_expect(
		int(chain.get("threshold", 0)) == 3,
		"formal balance must define chain threshold"
	)
	_expect(
		int(chain.get("damage", -1)) == 1
		and int(chain.get("draw", -1)) == 1
		and int(chain.get("spirit", -1)) == 1,
		"formal balance must define chain echo effects"
	)


func _test_zero_cost_and_threshold() -> void:
	var engine = _make_engine(
		[
			&"card.test.block",
			&"card.test.free",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
		],
		[10, 10]
	)
	var first: BattleCommandResult = _play_definition(
		engine,
		&"card.test.block"
	)
	_expect(first.accepted, "first chain card should be accepted")
	_expect(
		int(first.snapshot.data.get("chain", {}).get("count", -1)) == 1,
		"first paid card should advance chain to one"
	)
	var free: BattleCommandResult = _play_definition(
		engine,
		&"card.test.free"
	)
	_expect(free.accepted, "zero-cost card should be accepted")
	_expect(
		int(free.snapshot.data.get("chain", {}).get("count", -1)) == 1,
		"zero-cost card must not advance chain"
	)
	var second: BattleCommandResult = _play_definition(
		engine,
		&"card.test.block"
	)
	_expect(
		int(second.snapshot.data.get("chain", {}).get("count", -1)) == 2,
		"second paid card should advance chain to threshold minus one"
	)
	var third: BattleCommandResult = _play_definition(
		engine,
		&"card.test.block"
	)
	_expect(third.accepted, "threshold card should be accepted")
	var triggers := 0
	for event in third.events:
		if event.type == &"ChainTriggered":
			triggers += 1
	_expect(triggers == 1, "threshold should trigger exactly once")
	_expect(
		int(third.snapshot.data.get("chain", {}).get("count", -1)) == 0,
		"triggered chain should reset to zero"
	)
	_expect(
		int(third.snapshot.data.get("player", {}).get("spirit", -1)) == 1,
		"chain echo should restore one spirit after three paid cards"
	)
	for enemy in third.snapshot.data.get("enemies", []):
		_expect(
			int(enemy.get("hp", 99)) == 8,
			"chain echo should deal configured damage to living enemies"
		)


func _test_rejected_action_does_not_advance() -> void:
	var engine = _make_engine(
		[&"card.test.block"],
		[10]
	)
	var rejected = engine.submit(BattleCommandScript.play_card(
		&"missing.card",
		&""
	))
	_expect(not rejected.accepted, "invalid card command should be rejected")
	_expect(
		int(rejected.snapshot.data.get("chain", {}).get("count", -1)) == 0,
		"rejected commands must not advance chain"
	)


func _test_chain_trigger_kills_all() -> void:
	var engine = _make_engine(
		[
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
		],
		[2, 2],
		{"chain.damage": 2}
	)
	_play_definition(engine, &"card.test.block")
	_play_definition(engine, &"card.test.block")
	var third: BattleCommandResult = _play_definition(
		engine,
		&"card.test.block"
	)
	_expect(
		String(third.snapshot.data.get("outcome", "")) == "victory",
		"chain damage killing all enemies should produce victory"
	)
	_expect(
		int(third.snapshot.data.get("chain", {}).get("count", -1)) == 0,
		"lethal chain trigger should reset chain"
	)


func _test_direct_kill_does_not_emit_empty_echo() -> void:
	var engine = _make_engine(
		[
			&"card.test.block",
			&"card.test.block",
			&"card.test.damage",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
		],
		[3]
	)
	_play_definition(engine, &"card.test.block")
	_play_definition(engine, &"card.test.block")
	var lethal: BattleCommandResult = _play_definition(
		engine,
		&"card.test.damage"
	)
	var chain_triggers := 0
	for event in lethal.events:
		if event.type == &"ChainTriggered":
			chain_triggers += 1
	_expect(
		String(lethal.snapshot.data.get("outcome", "")) == "victory",
		"direct lethal card should finish the battle"
	)
	_expect(
		chain_triggers == 0,
		"direct lethal card must not emit a chain echo with no living target"
	)


func _test_echo_draw_reshuffle_and_hand_limit() -> void:
	var engine = _make_engine(
		[
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
		],
		[20],
		{"draw": 4, "damage": 0},
		7,
		8,
		8
	)
	_play_definition(engine, &"card.test.block")
	_play_definition(engine, &"card.test.block")
	var trigger: BattleCommandResult = _play_definition(
		engine,
		&"card.test.block"
	)
	var reshuffled := false
	var hand_limit_discard := false
	for event in trigger.events:
		if event.type == &"DeckReshuffled":
			reshuffled = true
		if (
			event.type == &"CardDiscarded"
			and String(event.data.get("reason_code", "")) == "hand_limit"
		):
			hand_limit_discard = true
	_expect(
		reshuffled,
		"echo draw should reshuffle when the draw pile is empty"
	)
	_expect(
		hand_limit_discard,
		"echo draw must respect hand limit without duplicating cards"
	)
	_expect(
		int(trigger.snapshot.data.get("player", {}).get("spirit", -1)) == 1,
		"echo should still restore spirit after a draw-boundary case"
	)


func _test_turn_end_resets_chain() -> void:
	var engine = _make_engine(
		[
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
			&"card.test.block",
		],
		[20]
	)
	_play_definition(engine, &"card.test.block")
	var result = engine.submit(BattleCommandScript.end_turn())
	_expect(result.accepted, "end turn should be accepted while chain is below threshold")
	_expect(
		int(result.snapshot.data.get("chain", {}).get("count", -1)) == 0,
		"turn end should clear chain"
	)


func _test_deterministic_replay() -> void:
	var deck := [
		&"card.test.block",
		&"card.test.block",
		&"card.test.block",
		&"card.test.block",
		&"card.test.free",
		&"card.test.block",
	]
	var first = _make_engine(deck, [10, 10], {}, 20261108)
	var second = _make_engine(deck, [10, 10], {}, 20261108)
	_expect(
		first.get_snapshot().to_dictionary()
		== second.get_snapshot().to_dictionary(),
		"same seed should initialize identical chain snapshots"
	)
	for _index in range(3):
		_play_definition(first, &"card.test.block")
		_play_definition(second, &"card.test.block")
	_expect(
		first.get_snapshot().to_dictionary()
		== second.get_snapshot().to_dictionary(),
		"same commands should produce identical chain results"
	)


func _make_engine(
	deck: Array,
	enemy_hp: Array,
	chain_overrides: Dictionary = {},
	seed: int = 7,
	starting_hand: int = 5,
	max_hand_size: int = 8
):
	var balance = FakeBalance.new()
	balance.starting_hand = starting_hand
	balance.max_hand_size = max_hand_size
	for key in chain_overrides:
		balance.chain[String(key)] = chain_overrides[key]
	var engine = BattleEngineScript.new()
	var enemies: Array = []
	for index in range(enemy_hp.size()):
		enemies.append({
			"id": "enemy.%d" % index,
			"definition_id": "enemy.test",
			"lane_index": index,
			"hp": int(enemy_hp[index]),
			"max_hp": int(enemy_hp[index]),
			"base_attack": 1,
		})
	var initialized = engine.initialize(
		FakeContent.new(),
		balance,
		FakeRandom.new(seed),
		&"battle.chain",
		{
			"actor_id": "player",
			"hp": 30,
			"max_hp": 30,
			"block": 0,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
			"statuses": [],
		},
		deck,
		enemies
	)
	_expect(initialized.accepted, "chain test engine should initialize")
	return engine


func _play_definition(engine, definition_id: StringName):
	var snapshot: Dictionary = engine.get_snapshot().to_dictionary()
	for card in snapshot.get("hand", []):
		if StringName(card.get("definition_id", "")) == definition_id:
			var target_id: StringName = &""
			if String(card.get("target_type", "")) == "enemy":
				target_id = StringName(
					snapshot.get("enemies", [])[0].get("actor_id", "")
				)
			return engine.submit(BattleCommandScript.play_card(
				StringName(card.get("instance_id", "")),
				target_id
			))
	_expect(false, "requested card should exist in hand: %s" % definition_id)
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)


class FakeContent:
	extends BattleContentPort

	var cards := {
		&"card.test.block": {
			"id": "card.test.block",
			"category": "skill",
			"cost_spirit": 1,
			"target_type": "self",
			"effects": [{"effect_id": "block", "amount": 1, "target": "self"}],
		},
		&"card.test.free": {
			"id": "card.test.free",
			"category": "skill",
			"cost_spirit": 0,
			"target_type": "none",
			"effects": [{"effect_id": "draw", "count": 1, "target": "none"}],
		},
		&"card.test.damage": {
			"id": "card.test.damage",
			"category": "skill",
			"cost_spirit": 1,
			"target_type": "enemy",
			"effects": [{"effect_id": "damage", "amount": 3, "target": "enemy"}],
		},
	}

	func get_card_definition(definition_id: StringName) -> Dictionary:
		return cards.get(definition_id, {}).duplicate(true)


class FakeBalance:
	extends BattleBalancePort

	var starting_hand := 5
	var max_hand_size := 8
	var chain := {
		"threshold": 3,
		"damage": 2,
		"draw": 1,
		"spirit": 1,
	}

	func get_value(parameter_id: StringName) -> Variant:
		match parameter_id:
			&"battle.max_rounds":
				return 10
			&"player.starting_hand":
				return starting_hand
			&"player.turn_draw_to_hand_size":
				return 6
			&"player.max_hand_size":
				return max_hand_size
			&"battle.enemy_pressure_start_round":
				return 7
			&"battle.chain":
				return chain.duplicate(true)
		return null


class FakeRandom:
	extends BattleRandomPort

	var state := 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
