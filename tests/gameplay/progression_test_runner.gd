extends Node

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const ProgressionEngineScript := preload("res://src/gameplay/progression_engine.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_formal_progression_content()
	_test_formal_balance_contract()
	_test_identity_selection_and_modifiers()
	_test_reward_flow_and_fragments()
	_test_reward_bundle_atomic_application()
	_test_gacha_cost_duplicate_and_replay()
	_test_gacha_rare_pity()
	_test_insufficient_tickets()
	_test_upgrade_and_battle_effect()
	_test_upgrade_failures()
	_test_owned_deck_filter()
	_test_persistent_state_round_trip()
	_test_invalid_content_rejected()

	if _failures.is_empty():
		print("PROGRESSION_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("PROGRESSION_TEST_FAILURE: %s" % failure)
	printerr(
		"PROGRESSION_TESTS_FAILED checks=%d failures=%d"
		% [_checks, _failures.size()]
	)
	get_tree().quit(1)


func _test_formal_balance_contract() -> void:
	var balance: Dictionary = _load_json_document(
		"res://data/balance/v0.4.0/balance.json"
	)
	var progression: Dictionary = balance.get("progression", {})
	var gacha: Dictionary = balance.get("gacha", {})
	var upgrade: Dictionary = balance.get("upgrade", {})
	var reward: Dictionary = balance.get("reward", {})
	var amounts: Dictionary = reward.get("amounts", {})
	var costs: Dictionary = upgrade.get("cost_by_next_level", {})
	_check(
		int(progression.get("starting_divination_tickets", -1)) == 3,
		"formal balance should grant three opening tickets"
	)
	_check(int(gacha.get("single_cost", -1)) == 2, "single gacha should cost two tickets")
	_check(int(gacha.get("triple_cost", -1)) == 5, "triple gacha should cost five tickets")
	_check(
		int(gacha.get("rare_pity", -1)) == 4,
		"formal rare pity should be four draws"
	)
	_check(
		int(amounts.get("reward.ink_dart_fragments", 0))
		>= int(costs.get("1", 999)),
		"first reward should fund at least one visible upgrade"
	)


func _test_formal_progression_content() -> void:
	var content := _content()
	var base_cards: Dictionary = _load_card_definitions()
	_check(content.get_identity_options().size() == 3, "three identities should be available")
	_check(content.get_starter_card_ids().size() == 6, "six deterministic starter cards")
	_check(content.get_gacha_pool().size() == 7, "formal gacha pool should contain seven upgradable cards")
	_check(content.get_reward_options().size() == 2, "two post-battle rewards")
	for definition_id in content.get_starter_card_ids():
		_check(
			base_cards.has(StringName(definition_id)),
			"starter card should exist in the battle content: %s" % definition_id
		)
	for entry in content.get_gacha_pool():
		_check(
			base_cards.has(StringName(entry["definition_id"])),
			"gacha card should exist in battle content: %s" % entry["definition_id"]
		)
		_check(
			not content.get_upgrade_definition(StringName(entry["definition_id"])).is_empty(),
			"gacha card must have an upgrade definition: %s" % entry["definition_id"]
		)
	_check(
		"card.skill.second_look" in content.get_starter_card_ids(),
		"unupgradable utility card should remain deterministically owned"
	)


func _test_identity_selection_and_modifiers() -> void:
	var pair := _make_engine(11)
	var engine: ProgressionEngine = pair[0]
	var initial: Dictionary = engine.get_snapshot().to_dictionary()
	_check(initial["phase"] == "identity_selection", "new progression should start at identity")
	_check(initial["collection"].size() == 8, "collection snapshot should list all pool cards")
	_check(initial["divination_tickets"] == 5, "initial tickets should come from balance")

	var reporter := engine.submit(
		ProgressionCommand.select_identity(&"identity.reporter")
	)
	_check(reporter.accepted, "reporter identity should be selectable")
	_check(reporter.snapshot.data["phase"] == "hub", "identity selection should enter hub")
	_check(
		int(reporter.snapshot.data["battle_modifiers"].get("starting_attention", 0)) == -1,
		"reporter should reduce starting attention"
	)
	var reporter_state := _battle_player_state()
	reporter_state["attention"] = 2
	var reporter_player := engine.apply_battle_modifiers(reporter_state)
	_check(
		int(reporter_player["attention"]) == 1,
		"reporter should reduce starting attention by one"
	)
	var duplicate_selection := engine.submit(
		ProgressionCommand.select_identity(&"identity.doctor")
	)
	_check(
		not duplicate_selection.accepted
		and duplicate_selection.reason_code == &"wrong_phase",
		"identity should only be selected once"
	)

	var doctor_pair := _make_engine(12)
	var doctor_engine: ProgressionEngine = doctor_pair[0]
	doctor_engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	_check(
		int(
			doctor_engine.get_snapshot().data["battle_modifiers"].get(
				"max_hp_bonus",
				0
			)
		) == 4,
		"doctor should expose max hp modifier"
	)
	var doctor_player := doctor_engine.apply_battle_modifiers(_battle_player_state())
	_check(
		int(doctor_player["max_hp"]) == 24 and int(doctor_player["hp"]) == 24,
		"doctor modifier should increase max and starting health"
	)


func _test_reward_flow_and_fragments() -> void:
	var pair := _make_engine(21)
	var engine: ProgressionEngine = pair[0]
	engine.submit(ProgressionCommand.select_identity(&"identity.reporter"))
	var resolved := engine.submit(ProgressionCommand.resolve_battle(&"victory"))
	_check(resolved.accepted, "victory should resolve into reward choice")
	_check(resolved.snapshot.data["phase"] == "reward", "victory should enter reward phase")
	_check(
		resolved.snapshot.data["reward_options"].size() == 2,
		"reward phase should expose two choices"
	)
	_check(
		int(resolved.snapshot.data["divination_tickets"]) == 6,
		"reporter victory should grant one extra ticket"
	)
	var fragments := engine.submit(
		ProgressionCommand.claim_reward(&"reward.ink_dart_fragments")
	)
	_check(fragments.accepted, "fragment reward should be claimable")
	var ink_state: Dictionary = _collection_item(fragments.snapshot, &"card.skill.ink_dart")
	_check(int(ink_state["fragments"]) == 20, "fragment reward amount should be applied")
	_check(fragments.snapshot.data["phase"] == "hub", "claiming reward should return to hub")
	var duplicate_claim := engine.submit(
		ProgressionCommand.claim_reward(&"reward.divination_tickets")
	)
	_check(
		not duplicate_claim.accepted
		and duplicate_claim.reason_code == &"wrong_phase",
		"reward should not be claimable twice"
	)


func _test_reward_bundle_atomic_application() -> void:
	var pair := _make_engine(22)
	var engine: ProgressionEngine = pair[0]
	engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	var before := engine.get_snapshot().to_dictionary()
	var applied := engine.apply_reward_bundle({
		"reward.divination_tickets": 2.0,
		"reward.ink_dart_fragments": 4.0,
	})
	_check(applied.accepted, "valid challenge reward bundle should be accepted")
	_check(
		int(applied.snapshot.data["divination_tickets"])
		== int(before["divination_tickets"]) + 2,
		"reward bundle should grant every ticket in one batch"
	)
	var ink_state: Dictionary = _collection_item(
		applied.snapshot,
		&"card.skill.ink_dart"
	)
	_check(
		int(ink_state["fragments"]) == 4,
		"reward bundle should grant card fragments to the referenced card"
	)
	_check(
		int(applied.snapshot.data["revision"]) == int(before["revision"]) + 1,
		"one reward bundle should advance progression by one revision"
	)
	var applied_event_count := 0
	for event in applied.events:
		if event.type == &"RewardBundleApplied":
			applied_event_count += 1
	_check(
		applied_event_count == 2,
		"reward bundle should emit one event per positive reward"
	)

	var atomic_pair := _make_engine(23)
	var atomic_engine: ProgressionEngine = atomic_pair[0]
	atomic_engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	var atomic_before := atomic_engine.get_snapshot().to_dictionary()
	var unknown := atomic_engine.apply_reward_bundle({
		"reward.divination_tickets": 5,
		"reward.missing": 1,
	})
	_check(
		not unknown.accepted
		and unknown.reason_code == &"reward_not_supported",
		"unknown reward id should reject the entire bundle"
	)
	_check(
		atomic_engine.get_snapshot().to_dictionary() == atomic_before,
		"unknown reward must not partially apply valid siblings"
	)

	var negative := atomic_engine.apply_reward_bundle({
		"reward.divination_tickets": -1,
	})
	_check(
		not negative.accepted
		and negative.reason_code == &"reward_amount_invalid",
		"negative reward amount should be rejected"
	)
	var fractional := atomic_engine.apply_reward_bundle({
		"reward.divination_tickets": 1.5,
	})
	_check(
		not fractional.accepted
		and fractional.reason_code == &"reward_amount_invalid",
		"non-integral reward amount should be rejected"
	)
	var empty := atomic_engine.apply_reward_bundle({})
	_check(
		not empty.accepted and empty.reason_code == &"reward_bundle_empty",
		"empty reward bundle should be rejected"
	)
	_check(
		atomic_engine.get_snapshot().to_dictionary() == atomic_before,
		"all rejected bundles should preserve progression exactly"
	)


func _test_gacha_cost_duplicate_and_replay() -> void:
	var first_pair := _make_engine(20261108)
	var first: ProgressionEngine = first_pair[0]
	first.submit(ProgressionCommand.select_identity(&"identity.reporter"))
	var first_result := first.submit(ProgressionCommand.draw_gacha(3))
	_check(first_result.accepted, "triple gacha should be accepted")
	_check(
		int(first_result.snapshot.data["divination_tickets"]) == 0,
		"triple gacha should deduct its configured cost"
	)
	var draw_event_count := 0
	for event in first_result.events:
		if event.type == &"GachaCardDrawn":
			draw_event_count += 1
	_check(draw_event_count == 3, "triple gacha should emit three draw events")
	_check(
		first_result.snapshot.data.get("gacha_history", []).size() == 1,
		"gacha history should persist the completed draw"
	)
	_check(
		int(first_result.snapshot.data.gacha_history[0].get("pull_count", 0)) == 3,
		"gacha history should retain pull count"
	)
	var duplicate_found := false
	for result_value in first_result.snapshot.data["last_gacha_results"]:
		if bool(result_value["duplicate"]):
			duplicate_found = true
			_check(
				int(result_value["fragments"]) >= 6,
				"duplicate packs should convert to fragments"
			)
	_check(duplicate_found, "starter pool pulls should exercise duplicate conversion")

	var second_pair := _make_engine(20261108)
	var second: ProgressionEngine = second_pair[0]
	second.submit(ProgressionCommand.select_identity(&"identity.reporter"))
	var second_result := second.submit(ProgressionCommand.draw_gacha(3))
	_check(
		first_result.to_dictionary() == second_result.to_dictionary(),
		"same seed and command sequence should reproduce gacha"
	)


func _test_gacha_rare_pity() -> void:
	var pair := _make_engine(
		31,
		{
			&"gacha.rarity_weights": {"common": 100, "rare": 0},
			&"gacha.rare_pity": 3,
			&"progression.starting_divination_tickets": 20,
		}
	)
	var engine: ProgressionEngine = pair[0]
	engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	var result := engine.submit(ProgressionCommand.draw_gacha(3))
	_check(result.accepted, "pity sequence should be accepted")
	var results: Array = result.snapshot.data["last_gacha_results"]
	_check(
		String(results[2]["rarity"]) == "rare",
		"third non-rare draw should trigger rare pity"
	)
	_check(
		int(result.snapshot.data["pity_counter"]) == 0,
		"rare draw should reset pity counter"
	)


func _test_insufficient_tickets() -> void:
	var pair := _make_engine(
		41,
		{&"progression.starting_divination_tickets": 1}
	)
	var engine: ProgressionEngine = pair[0]
	engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	var result := engine.submit(ProgressionCommand.draw_gacha(1))
	_check(
		not result.accepted
		and result.reason_code == &"insufficient_divination_tickets",
		"gacha should reject insufficient tickets"
	)
	_check(
		int(result.snapshot.data["divination_tickets"]) == 1,
		"rejected gacha should not deduct tickets"
	)


func _test_upgrade_and_battle_effect() -> void:
	var pair := _make_engine(51)
	var engine: ProgressionEngine = pair[0]
	var content: ProgressionTestContent = pair[1]
	var balance: ProgressionTestBalance = pair[2]
	engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	engine.submit(ProgressionCommand.resolve_battle(&"victory"))
	engine.submit(ProgressionCommand.claim_reward(&"reward.ink_dart_fragments"))
	var upgraded := engine.submit(
		ProgressionCommand.upgrade_card(&"card.skill.ink_dart")
	)
	_check(upgraded.accepted, "ink dart should upgrade with reward fragments")
	var ink_state: Dictionary = _collection_item(
		upgraded.snapshot,
		&"card.skill.ink_dart"
	)
	_check(int(ink_state["level"]) == 1, "ink dart should reach level one")
	_check(int(ink_state["fragments"]) == 10, "upgrade should deduct next-level cost")

	var base_content := ProgressionTestBattleContent.new(_load_card_definitions())
	var upgraded_content := engine.create_upgraded_content(base_content)
	var upgraded_definition := upgraded_content.get_card_definition(
		&"card.skill.ink_dart"
	)
	_check(
		int(upgraded_definition["effects"][0]["amount"]) == 5,
		"card upgrade should add one damage at level one"
	)

	var battle := BattleEngineScript.new()
	var initialized: BattleCommandResult = battle.initialize(
		upgraded_content,
		balance,
		ProgressionTestRandom.new(7),
		&"battle.upgrade",
		_battle_player_state(),
		[&"card.skill.ink_dart"],
		[_battle_enemy()]
	)
	_check(initialized.accepted, "upgraded content should initialize battle")
	var card_id: StringName = StringName(
		initialized.snapshot.data["hand"][0]["instance_id"]
	)
	var played: BattleCommandResult = battle.submit(
		BattleCommand.play_card(card_id, &"enemy.a")
	)
	_check(
		int(played.snapshot.data["enemies"][0]["hp"]) == 15,
		"upgraded ink dart should deal five damage in the next battle"
	)


func _test_upgrade_failures() -> void:
	var pair := _make_engine(61)
	var engine: ProgressionEngine = pair[0]
	engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	var unsupported := engine.submit(
		ProgressionCommand.upgrade_card(&"card.skill.second_look")
	)
	_check(
		not unsupported.accepted and unsupported.reason_code == &"upgrade_not_supported",
		"deterministic utility card should report unsupported upgrade"
	)
	var unowned := engine.submit(
		ProgressionCommand.upgrade_card(&"card.skill.omen")
	)
	_check(
		not unowned.accepted and unowned.reason_code == &"card_not_owned",
		"unowned card should not be upgradeable"
	)
	var insufficient := engine.submit(
		ProgressionCommand.upgrade_card(&"card.skill.ink_dart")
	)
	_check(
		not insufficient.accepted
		and insufficient.reason_code == &"insufficient_fragments",
		"upgrade should reject insufficient fragments"
	)

	var rewarded := _make_engine(62)
	var max_engine: ProgressionEngine = rewarded[0]
	max_engine.submit(ProgressionCommand.select_identity(&"identity.doctor"))
	max_engine.submit(ProgressionCommand.resolve_battle(&"victory"))
	max_engine.submit(ProgressionCommand.claim_reward(&"reward.ink_dart_fragments"))
	# Inject enough fragments through restore to exercise the max-level guard.
	var state := max_engine.export_persistent_state()
	state["collection"]["card.skill.ink_dart"]["fragments"] = 999
	state["collection"]["card.skill.ink_dart"]["level"] = 3
	var restored_pair := _make_engine(62, {}, state)
	var restored_engine: ProgressionEngine = restored_pair[0]
	var max_result := restored_engine.submit(
		ProgressionCommand.upgrade_card(&"card.skill.ink_dart")
	)
	_check(
		not max_result.accepted and max_result.reason_code == &"card_level_max",
		"max-level card should reject upgrade"
	)


func _test_owned_deck_filter() -> void:
	var pair := _make_engine(71)
	var engine: ProgressionEngine = pair[0]
	var source_deck: Array[String] = [
		"card.skill.ink_dart",
		"card.skill.omen",
		"card.skill.ink_dart",
	]
	var owned := engine.build_owned_battle_deck(source_deck)
	_check(owned.size() == 2, "unowned gacha cards should be filtered from battle deck")
	_check(
		not "card.skill.omen" in owned,
		"rare gacha card should not be owned at new-game start"
	)


func _test_persistent_state_round_trip() -> void:
	var pair := _make_engine(81)
	var engine: ProgressionEngine = pair[0]
	engine.submit(ProgressionCommand.select_identity(&"identity.gravedigger"))
	engine.submit(ProgressionCommand.draw_gacha(1))
	var saved: Dictionary = engine.export_persistent_state()
	var restored_pair := _make_engine(81, {}, saved)
	var restored: ProgressionEngine = restored_pair[0]
	_check(
		engine.get_snapshot().to_dictionary() == restored.get_snapshot().to_dictionary(),
		"persistent progression state should round-trip exactly"
	)


func _test_invalid_content_rejected() -> void:
	var content := _content()
	content.gacha_pool[0]["definition_id"] = "card.missing"
	var engine := ProgressionEngineScript.new(
		content,
		ProgressionTestBalance.new({}),
		ProgressionTestRandom.new(1)
	)
	var result = engine.initialize()
	_check(
		not result.accepted and result.reason_code == &"content_invalid",
		"progression content should reject missing card references"
	)

	var unupgradable_content := _content()
	unupgradable_content.gacha_pool.append({
		"definition_id": "card.skill.second_look",
		"rarity": "common",
	})
	var unupgradable_engine := ProgressionEngineScript.new(
		unupgradable_content,
		ProgressionTestBalance.new({}),
		ProgressionTestRandom.new(1)
	)
	var unupgradable_result = unupgradable_engine.initialize()
	_check(
		not unupgradable_result.accepted
		and unupgradable_result.reason_code == &"content_invalid",
		"gacha pool should reject cards without an upgrade path"
	)


func _make_engine(
	seed: int,
	overrides: Dictionary = {},
	initial_state: Dictionary = {}
) -> Array:
	var content := _content()
	var balance := ProgressionTestBalance.new(overrides)
	var engine := ProgressionEngineScript.new(
		content,
		balance,
		ProgressionTestRandom.new(seed)
	)
	var result: ProgressionCommandResult = engine.initialize(initial_state)
	_check(result.accepted, "progression engine should initialize: %s" % result.reason_code)
	return [engine, content, balance]


func _content() -> ProgressionTestContent:
	var document: Dictionary = _load_json_document(
		"res://data/cards/v0.4.0/progression.json"
	)
	return ProgressionTestContent.new(document)


func _load_card_definitions() -> Dictionary:
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
		_check(false, "JSON file should be readable: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_check(false, "JSON file should contain an object: %s" % path)
		return {}
	return parsed


func _collection_item(
	snapshot: ProgressionSnapshot,
	definition_id: StringName
) -> Dictionary:
	for item in snapshot.data["collection"]:
		if StringName(item["definition_id"]) == definition_id:
			return item
	_check(false, "collection item should exist: %s" % definition_id)
	return {}


func _battle_player_state() -> Dictionary:
	return {
		"actor_id": "player",
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


func _battle_enemy() -> Dictionary:
	return {
		"id": &"enemy.a",
		"definition_id": &"enemy.test",
		"lane_index": 0,
		"hp": 20,
		"max_hp": 20,
		"base_attack": 1,
	}


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


class ProgressionTestContent:
	extends ProgressionContentPort

	var identities: Array = []
	var starter_card_ids: Array = []
	var gacha_pool: Array = []
	var reward_options: Array = []
	var upgrade_definitions: Dictionary = {}
	var base_card_ids: Dictionary = {}

	func _init(document: Dictionary) -> void:
		identities = document.get("identities", []).duplicate(true)
		starter_card_ids = document.get("starter_card_ids", []).duplicate(true)
		gacha_pool = document.get("gacha_pool", []).duplicate(true)
		reward_options = document.get("reward_options", []).duplicate(true)
		upgrade_definitions = document.get("upgrade_definitions", {}).duplicate(true)
		for definition_id in _load_cards():
			base_card_ids[String(definition_id)] = true

	func get_identity_options() -> Array:
		return identities.duplicate(true)

	func get_identity(identity_id: StringName) -> Dictionary:
		for identity in identities:
			if StringName(identity.get("id", "")) == identity_id:
				return identity.duplicate(true)
		return {}

	func has_card_definition(definition_id: StringName) -> bool:
		return base_card_ids.has(String(definition_id))

	func get_starter_card_ids() -> Array:
		return starter_card_ids.duplicate(true)

	func get_gacha_pool() -> Array:
		return gacha_pool.duplicate(true)

	func get_reward_options() -> Array:
		return reward_options.duplicate(true)

	func get_upgrade_definition(definition_id: StringName) -> Dictionary:
		return upgrade_definitions.get(String(definition_id), {}).duplicate(true)

	func _load_cards() -> Dictionary:
		var cards: Dictionary = {}
		var file := FileAccess.open("res://data/cards/v0.3.0/cards.json", FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				for card in parsed.get("cards", []):
					cards[StringName(card.get("id", ""))] = card.duplicate(true)
		return cards


class ProgressionTestBattleContent:
	extends BattleContentPort

	var cards: Dictionary = {}
	var card_ids: Array[String] = []

	func _init(definitions: Dictionary) -> void:
		cards = definitions.duplicate(true)
		for definition_id in cards:
			card_ids.append(String(definition_id))

	func get_card_definition(definition_id: StringName) -> Dictionary:
		return cards.get(definition_id, {}).duplicate(true)


class ProgressionTestBalance:
	extends BattleBalancePort

	var values: Dictionary = {
		&"progression.starting_divination_tickets": 5,
		&"gacha.single_cost": 2,
		&"gacha.triple_cost": 5,
		&"gacha.rarity_weights": {"common": 85, "rare": 15},
		&"gacha.rare_pity": 4,
		&"gacha.duplicate_fragments": 6,
		&"upgrade.cost_by_next_level": {"1": 10, "2": 20, "3": 30},
		&"reward.amounts": {
			"reward.divination_tickets": 2,
			"reward.ink_dart_fragments": 20,
		},
		&"battle.max_rounds": 10,
		&"player.starting_hand": 5,
		&"player.turn_draw_to_hand_size": 5,
		&"player.max_hand_size": 8,
		&"battle.enemy_pressure_start_round": 5,
	}

	func _init(overrides: Dictionary = {}) -> void:
		values = values.duplicate(true)
		for key in overrides:
			values[StringName(key)] = overrides[key]

	func get_value(parameter_id: StringName) -> Variant:
		return values.get(parameter_id)


class ProgressionTestRandom:
	extends BattleRandomPort

	var state: int = 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
