extends Node

const BattleEngineScript = preload("res://src/gameplay/battle_engine.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_formal_starter_cards()
	_test_formal_enemy_and_encounter_content()
	_test_formal_first_battle_initializes()
	_test_formal_starter_card_effects()
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


func _test_formal_starter_cards() -> void:
	var cards: Dictionary = _load_formal_cards()
	_check(cards.size() == 8, "formal starter content should contain 8 unique cards")
	var expected_ids: Array[StringName] = [
		&"card.skill.ink_dart",
		&"card.skill.paper_guard",
		&"card.skill.calm_breath",
		&"card.skill.focus",
		&"card.skill.insight",
		&"card.skill.omen",
		&"card.skill.whisper",
		&"card.skill.second_look",
	]
	for definition_id in expected_ids:
		_check(cards.has(definition_id), "formal card missing: %s" % definition_id)

	var effect_ids: Dictionary = {}
	for definition_id in expected_ids:
		var definition: Dictionary = cards.get(definition_id, {})
		_check(
			StringName(definition.get("id", "")) == definition_id,
			"formal card definition id should match lookup key"
		)
		for effect in definition.get("effects", []):
			effect_ids[StringName(effect.get("effect_id", ""))] = true
	var expected_effects: Array[StringName] = [
		&"damage",
		&"block",
		&"heal",
		&"spirit",
		&"draw",
		&"apply_status",
		&"reveal_intent",
		&"risk",
	]
	for effect_id in expected_effects:
		_check(effect_ids.has(effect_id), "formal effect missing: %s" % effect_id)


func _test_formal_enemy_and_encounter_content() -> void:
	var cards: Dictionary = _load_formal_cards()
	var enemies_document: Dictionary = _load_json_document(
		"res://data/enemies/v0.3.0/enemies.json"
	)
	var encounters_document: Dictionary = _load_json_document(
		"res://data/encounters/v0.3.0/encounters.json"
	)
	_check(
		String(enemies_document.get("content_version", "")) == "v0.3.0",
		"enemy content should use v0.3.0 content version"
	)
	_check(
		String(encounters_document.get("content_version", "")) == "v0.3.0",
		"encounter content should use v0.3.0 content version"
	)
	var enemy_by_id: Dictionary = {}
	for enemy in enemies_document.get("enemies", []):
		enemy_by_id[StringName(enemy.get("id", ""))] = enemy.duplicate(true)
	_check(enemy_by_id.size() == 3, "formal enemy content should contain 3 unique enemies")

	var encounters: Array = encounters_document.get("encounters", [])
	_check(encounters.size() == 1, "formal content should define one first encounter")
	if encounters.is_empty():
		return
	var encounter: Dictionary = encounters[0]
	_check(
		String(encounter.get("id", "")) == "encounter.first_hunt",
		"first encounter should use stable id encounter.first_hunt"
	)
	var enemy_slots: Array = encounter.get("enemy_slots", [])
	_check(enemy_slots.size() == 2, "first encounter should contain two enemies")
	var lanes: Dictionary = {}
	for slot in enemy_slots:
		var enemy_id: StringName = StringName(slot.get("enemy_id", ""))
		var lane_index: int = int(slot.get("lane_index", -1))
		_check(enemy_by_id.has(enemy_id), "encounter should reference a formal enemy")
		_check(not lanes.has(lane_index), "encounter enemy lanes should be unique")
		lanes[lane_index] = true
	for definition_id in encounter.get("deck_definition_ids", []):
		_check(
			cards.has(StringName(definition_id)),
			"encounter should reference a formal card: %s" % definition_id
		)


func _test_formal_first_battle_initializes() -> void:
	var cards: Dictionary = _load_formal_cards()
	var enemies_document: Dictionary = _load_json_document(
		"res://data/enemies/v0.3.0/enemies.json"
	)
	var encounters_document: Dictionary = _load_json_document(
		"res://data/encounters/v0.3.0/encounters.json"
	)
	var enemy_by_id: Dictionary = {}
	for enemy in enemies_document.get("enemies", []):
		enemy_by_id[StringName(enemy.get("id", ""))] = enemy
	var encounters: Array = encounters_document.get("encounters", [])
	if encounters.is_empty():
		_check(false, "formal first battle requires an encounter")
		return
	var encounter: Dictionary = encounters[0]
	var enemy_configs: Array[Dictionary] = []
	for slot in encounter.get("enemy_slots", []):
		var enemy_id: StringName = StringName(slot.get("enemy_id", ""))
		var definition: Dictionary = enemy_by_id.get(enemy_id, {})
		enemy_configs.append({
			"id": "%s.%s" % [encounter.get("id", ""), enemy_id],
			"definition_id": enemy_id,
			"lane_index": int(slot.get("lane_index", -1)),
			"hp": int(definition.get("base_health", 0)),
			"max_hp": int(definition.get("base_health", 0)),
			"base_attack": int(definition.get("base_attack", 0)),
		})
	var engine: BattleEngine = _make_engine_with_definitions(
		cards,
		encounter.get("deck_definition_ids", []),
		enemy_configs
	)
	var snapshot: Dictionary = engine.get_snapshot().to_dictionary()
	_check(
		String(snapshot.get("phase", "")) == "player_action",
		"formal first battle should initialize into player_action"
	)
	_check(
		Array(snapshot.get("enemies", [])).size() == 2,
		"formal first battle snapshot should expose two enemy lanes"
	)


func _test_formal_starter_card_effects() -> void:
	var cards: Dictionary = _load_formal_cards()

	var guard_engine: BattleEngine = _make_engine_with_definitions(
		cards,
		[&"card.skill.paper_guard", &"card.skill.ink_dart"],
		[_enemy(&"enemy.a", 0, 20, 1)]
	)
	var guard_id: StringName = _hand_instance(
		guard_engine,
		&"card.skill.paper_guard"
	)
	var guard_result: BattleCommandResult = guard_engine.submit(
		BattleCommand.play_card(guard_id)
	)
	_check(
		int(guard_result.snapshot.data["player"]["block"]) == 5,
		"formal paper guard should add 5 block"
	)
	var ink_id: StringName = _hand_instance(guard_engine, &"card.skill.ink_dart")
	var ink_result: BattleCommandResult = guard_engine.submit(
		BattleCommand.play_card(ink_id, &"enemy.a")
	)
	_check(
		_enemy_hp(ink_result.snapshot, &"enemy.a") == 16,
		"formal ink dart should deal 4 damage"
	)

	var calm_engine: BattleEngine = _make_engine_with_definitions(
		cards,
		[&"card.skill.calm_breath"],
		[_enemy(&"enemy.a", 0, 20, 1)],
		{"hp": 10, "corruption": 2}
	)
	var calm_id: StringName = _hand_instance(
		calm_engine,
		&"card.skill.calm_breath"
	)
	var calm_result: BattleCommandResult = calm_engine.submit(
		BattleCommand.play_card(calm_id)
	)
	_check(
		int(calm_result.snapshot.data["player"]["hp"]) == 14,
		"formal calm breath should heal 4"
	)
	_check(
		int(calm_result.snapshot.data["player"]["corruption"]) == 1,
		"formal calm breath should reduce corruption by 1"
	)

	var focus_engine: BattleEngine = _make_engine_with_definitions(
		cards,
		[&"card.skill.focus"],
		[_enemy(&"enemy.a", 0, 20, 1)]
	)
	var focus_id: StringName = _hand_instance(focus_engine, &"card.skill.focus")
	var focus_result: BattleCommandResult = focus_engine.submit(
		BattleCommand.play_card(focus_id)
	)
	_check(
		int(focus_result.snapshot.data["player"]["spirit"]) == 4,
		"formal focus should add 1 spirit"
	)

	var insight_deck: Array[StringName] = []
	for _copy_index in range(8):
		insight_deck.append(&"card.skill.insight")
	var insight_engine: BattleEngine = _make_engine_with_definitions(
		cards,
		insight_deck,
		[_enemy(&"enemy.a", 0, 20, 1)]
	)
	var insight_id: StringName = _hand_instance(
		insight_engine,
		&"card.skill.insight"
	)
	var insight_result: BattleCommandResult = insight_engine.submit(
		BattleCommand.play_card(insight_id)
	)
	_check(
		insight_result.snapshot.data["hand"].size() == 5,
		"formal insight should replace itself by drawing one card"
	)
	_check(
		_has_event(insight_result, &"CardDrawn"),
		"formal insight should emit CardDrawn"
	)

	var mark_engine: BattleEngine = _make_engine_with_definitions(
		cards,
		[&"card.skill.omen", &"card.skill.ink_dart"],
		[_enemy(&"enemy.a", 0, 20, 1)]
	)
	var omen_id: StringName = _hand_instance(mark_engine, &"card.skill.omen")
	mark_engine.submit(BattleCommand.play_card(omen_id, &"enemy.a"))
	var marked_ink_id: StringName = _hand_instance(
		mark_engine,
		&"card.skill.ink_dart"
	)
	var mark_result: BattleCommandResult = mark_engine.submit(
		BattleCommand.play_card(marked_ink_id, &"enemy.a")
	)
	_check(
		_enemy_hp(mark_result.snapshot, &"enemy.a") == 14,
		"formal omen should add 2 to the next ink dart"
	)

	var weaken_engine: BattleEngine = _make_engine_with_definitions(
		cards,
		[&"card.skill.whisper"],
		[_enemy(&"enemy.a", 0, 20, 5)]
	)
	var whisper_id: StringName = _hand_instance(
		weaken_engine,
		&"card.skill.whisper"
	)
	weaken_engine.submit(BattleCommand.play_card(whisper_id, &"enemy.a"))
	var weaken_result: BattleCommandResult = weaken_engine.submit(
		BattleCommand.end_turn()
	)
	_check(
		int(weaken_result.snapshot.data["player"]["hp"]) == 17,
		"formal whisper should reduce 5 damage to 3"
	)

	var reveal_engine: BattleEngine = _make_engine_with_definitions(
		cards,
		[&"card.skill.second_look"],
		[_enemy(&"enemy.a", 0, 20, 5)]
	)
	var reveal_id: StringName = _hand_instance(
		reveal_engine,
		&"card.skill.second_look"
	)
	var reveal_result: BattleCommandResult = reveal_engine.submit(
		BattleCommand.play_card(reveal_id, &"enemy.a")
	)
	_check(
		bool(_enemy_view(reveal_result.snapshot, &"enemy.a")["intent"]["revealed"]),
		"formal second look should reveal enemy intent"
	)
	_check(
		int(
			_enemy_view(reveal_result.snapshot, &"enemy.a")["intent"]["visible_fields"]["damage"]
		) == 5,
		"formal second look should expose the intent damage"
	)


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
		{"hp": 200, "max_hp": 200},
		{"battle.enemy_pressure_start_round": 5}
	)
	var pressure_event_count: int = 0
	var result: BattleCommandResult = engine.submit(BattleCommand.end_turn())
	for _round_index in range(2, 10):
		result = engine.submit(BattleCommand.end_turn())
		_check(result.accepted, "end turn should remain accepted during pressure test")
		for event in result.events:
			if event.type == &"EnemyPressureChanged":
				pressure_event_count += 1
		var round_number: int = int(result.snapshot.data["round_number"])
		var bonus: int = int(result.snapshot.data["enemy_pressure_bonus"])
		var intent_damage: int = int(
			_enemy_view(result.snapshot, &"enemy.a")["intent"]["damage"]
		)
		match round_number:
			4:
				_check(bonus == 0, "round four should have no enemy pressure")
				_check(intent_damage == 1, "round four intent should keep base damage")
			5:
				_check(bonus == 1, "round five should gain first pressure point")
				_check(intent_damage == 2, "round five intent should include pressure")
			7:
				_check(bonus == 2, "round seven should gain second pressure point")
				_check(intent_damage == 3, "round seven intent should include pressure")
			9:
				_check(bonus == 3, "round nine should gain third pressure point")
				_check(intent_damage == 4, "round nine intent should include pressure")
	_check(int(result.snapshot.data["round_number"]) == 10, "pressure test should reach round ten")
	_check(
		int(result.snapshot.data["enemy_pressure_bonus"]) == 3,
		"enemy pressure should stop increasing after round nine"
	)
	_check(
		int(_enemy_view(result.snapshot, &"enemy.a")["intent"]["damage"]) == 4,
		"round ten should retain three pressure points"
	)
	_check(pressure_event_count == 3, "pressure should trigger exactly on rounds five, seven and nine")


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
	return _make_engine_with_content(
		content,
		deck,
		enemies,
		player_overrides,
		balance_overrides,
		seed
	)


func _make_engine_with_definitions(
	definitions: Dictionary,
	deck: Array,
	enemies: Array,
	player_overrides: Dictionary = {},
	balance_overrides: Dictionary = {},
	seed: int = 7
) -> BattleEngine:
	var content: FakeContent = FakeContent.new()
	content.cards = definitions.duplicate(true)
	return _make_engine_with_content(
		content,
		deck,
		enemies,
		player_overrides,
		balance_overrides,
		seed
	)


func _make_engine_with_content(
	content: FakeContent,
	deck: Array,
	enemies: Array,
	player_overrides: Dictionary = {},
	balance_overrides: Dictionary = {},
	seed: int = 7
) -> BattleEngine:
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


func _load_formal_cards() -> Dictionary:
	var document: Dictionary = _load_json_document(
		"res://data/cards/v0.3.0/cards.json"
	)
	var result: Dictionary = {}
	for definition in document.get("cards", []):
		if definition is Dictionary:
			result[StringName(definition.get("id", ""))] = definition.duplicate(true)
	return result


func _load_json_document(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_check(false, "formal content file should be readable: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_check(false, "formal content file should contain a JSON object: %s" % path)
		return {}
	return parsed


func _has_event(result: BattleCommandResult, event_type: StringName) -> bool:
	for event in result.events:
		if event.type == event_type:
			return true
	return false


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
