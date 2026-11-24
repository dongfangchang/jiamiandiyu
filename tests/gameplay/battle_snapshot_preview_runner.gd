extends Node

## Battle snapshot read-model (ROADMAP R2-01): per-card playable / blocked_reason /
## required_discard / preview and player.ritual_payoff_preview must match what
## resolution actually does, so the UI never recomputes rules.

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")

var _checks := 0
var _failures: Array[String] = []
var _cards_document: Dictionary
var _balance_document: Dictionary


func _ready() -> void:
	_cards_document = _read_json("res://data/cards/v0.7.0/cards.json")
	_balance_document = _read_json("res://data/balance/v0.7.0/balance.json")
	_test_ritual_preview_matches_resolution()
	_test_blocked_reason_tracks_spirit()
	_test_required_discard_is_capped_by_hand()
	_test_intents_carry_ids_only()
	_test_rule_parameters_are_required()
	_finish()


func _test_ritual_preview_matches_resolution() -> void:
	var engine = _make_engine([&"card.skill.warding_circle", &"card.skill.paper_guard"])
	var enemy_id := StringName(engine.get_snapshot().data["enemies"][0]["actor_id"])
	var guard := _hand_card(engine, &"card.skill.paper_guard")
	var guard_preview: Dictionary = guard.get("preview", {})
	_expect(int(guard_preview.get("ritual_stacks", 0)) == 1, "paper_guard previews +1 ritual stack")
	_expect(int(guard_preview.get("block", 0)) == 5, "paper_guard previews its block from card data")
	var circle := _hand_card(engine, &"card.skill.warding_circle")
	var payoff_before: Dictionary = engine.get_snapshot().data["player"].get("ritual_payoff_preview", {})
	_expect(
		int(payoff_before.get("damage", -1)) == int(circle["preview"]["damage"]),
		"player payoff preview equals the payoff card's own preview"
	)
	_expect(
		int(circle["preview"]["conditional"]["damage"]) > 0,
		"condition-gated damage is reported separately"
	)
	engine.submit(BattleCommandScript.play_card(StringName(guard["instance_id"])))
	circle = _hand_card(engine, &"card.skill.warding_circle")
	var expected := int(circle["preview"]["damage"])
	_expect(expected > int(payoff_before.get("damage", 0)), "one more stack raises the previewed payoff")
	_expect(int(circle["preview"]["ritual_consumed"]) == 1, "preview reports the stacks it will consume")
	_expect(
		int(engine.get_snapshot().data["player"]["ritual_payoff_preview"]["damage"]) == expected,
		"player payoff preview follows the new stack count"
	)
	var result = engine.submit(
		BattleCommandScript.play_card(StringName(circle["instance_id"]), enemy_id)
	)
	_expect(result.accepted, "warding_circle play accepted")
	var dealt := -1
	var announced := -1
	for event in result.events:
		if event.type == &"DamageApplied" and dealt < 0 and String(event.data.get("source_id", "")) == "card.skill.warding_circle":
			dealt = int(event.data.get("raw_amount", -1))
		if event.type == &"RitualCompleted":
			announced = int(event.data.get("payoff_damage", -1))
	_expect(dealt == expected, "resolved damage %d equals previewed %d" % [dealt, expected])
	_expect(announced == expected, "RitualCompleted announces the resolved payoff")


func _test_blocked_reason_tracks_spirit() -> void:
	var engine = _make_engine([&"card.skill.eclipse", &"card.skill.paper_guard"])
	var eclipse := _hand_card(engine, &"card.skill.eclipse")
	_expect(bool(eclipse.get("playable", false)), "eclipse is playable with full spirit")
	_expect(String(eclipse.get("blocked_reason", "x")) == "", "playable card has no blocked_reason")
	var guard := _hand_card(engine, &"card.skill.paper_guard")
	engine.submit(BattleCommandScript.play_card(StringName(guard["instance_id"])))
	eclipse = _hand_card(engine, &"card.skill.eclipse")
	_expect(not bool(eclipse.get("playable", true)), "eclipse is blocked after spending spirit")
	_expect(
		String(eclipse.get("blocked_reason", "")) == String(BattlePlayability.INSUFFICIENT_SPIRIT),
		"blocked_reason is the insufficient_spirit id"
	)
	var enemy_id := StringName(engine.get_snapshot().data["enemies"][0]["actor_id"])
	var query = engine.query_card_play(StringName(eclipse["instance_id"]), enemy_id)
	_expect(query.reason_code == BattlePlayability.INSUFFICIENT_SPIRIT, "snapshot agrees with query_card_play")


func _test_required_discard_is_capped_by_hand() -> void:
	var alone = _make_engine([&"card.skill.focus"])
	_expect(
		int(_hand_card(alone, &"card.skill.focus").get("required_discard", -1)) == 0,
		"focus alone in hand needs no discard choice"
	)
	var paired = _make_engine([&"card.skill.focus", &"card.skill.ink_dart"])
	_expect(
		int(_hand_card(paired, &"card.skill.focus").get("required_discard", -1)) == 1,
		"focus with another card needs one discard choice"
	)


func _test_intents_carry_ids_only() -> void:
	var engine = _make_engine([&"card.skill.ink_dart"])
	var intent: Dictionary = engine.get_snapshot().data["enemies"][0]["intent"]
	_expect(String(intent.get("intent_id", "")) == "attack", "default intent id is attack")
	_expect(intent.has("variant_id"), "intent exposes variant_id")
	_expect(String(intent.get("display_name_zh", "x")).is_empty(), "engine adds no display text of its own")


func _test_rule_parameters_are_required() -> void:
	var broken := _balance_document.duplicate(true)
	broken["combat"].erase("rules")
	var engine = BattleEngineScript.new()
	var result = engine.initialize(
		_content(), BattleBalanceAdapterScript.new(broken), FixedRandom.new(3),
		&"battle.snapshot.broken", _player(), [&"card.skill.ink_dart"], [_enemy()]
	)
	_expect(not result.accepted and result.reason_code == &"balance_missing", "missing battle.rules fails loudly")


func _make_engine(deck: Array):
	var engine = BattleEngineScript.new()
	var result = engine.initialize(
		_content(),
		BattleBalanceAdapterScript.new(_balance_document),
		FixedRandom.new(88),
		&"battle.snapshot.preview",
		_player(),
		deck,
		[_enemy()]
	)
	_expect(result.accepted, "engine initializes")
	return engine


func _content():
	return BattleContentAdapterScript.new(
		_cards_document.get("cards", []),
		_cards_document.get("synergies", [])
	)


func _player() -> Dictionary:
	return {
		"actor_id": "player", "hp": 54, "max_hp": 54, "block": 0,
		"spirit": 3, "max_spirit": 3, "corruption": 0, "max_corruption": 10,
		"attention": 0, "max_attention": 10, "statuses": [],
	}


func _enemy() -> Dictionary:
	return {
		"id": &"enemy.a",
		"definition_id": &"enemy.test_dummy",
		"lane_index": 0,
		"hp": 60,
		"max_hp": 60,
		"base_attack": 1,
	}


func _hand_card(engine, definition_id: StringName) -> Dictionary:
	for card in engine.get_snapshot().data.get("hand", []):
		if StringName(card.get("definition_id", "")) == definition_id:
			return card
	_expect(false, "hand contains %s" % String(definition_id))
	return {"preview": {"conditional": {}}}


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _finish() -> void:
	if _failures.is_empty():
		print("BATTLE_SNAPSHOT_PREVIEW_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("BATTLE_SNAPSHOT_PREVIEW_FAIL %s" % failure)
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
