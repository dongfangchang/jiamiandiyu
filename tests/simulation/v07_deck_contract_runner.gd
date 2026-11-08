extends Node

const BattleContentAdapterScript := preload(
	"res://src/infrastructure/battle_content_adapter.gd"
)
const BattleBalanceAdapterScript := preload(
	"res://src/infrastructure/battle_balance_adapter.gd"
)
const BattleRandomAdapterScript := preload(
	"res://src/infrastructure/battle_random_adapter.gd"
)
const DeckEngineScript := preload("res://src/gameplay/deck_engine.gd")
const DeckCommandScript := preload("res://src/core/deck_command.gd")
const DeckContentAdapterScript := preload(
	"res://tools/simulation/v07_deck_content_adapter.gd"
)
const ProgressionEngineScript := preload(
	"res://src/gameplay/progression_engine.gd"
)
const ProgressionContentAdapterScript := preload(
	"res://src/infrastructure/progression_content_adapter.gd"
)
const SeededRandomServiceScript := preload(
	"res://src/infrastructure/seeded_random_service.gd"
)

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const PROGRESSION_PATH := "res://data/cards/v0.7.0/progression.json"
const DECKS_PATH := "res://data/decks/v0.7.0/decks.json"
const BALANCE_PATH := "res://data/balance/v0.7.0/balance.json"
const CHALLENGES_PATH := "res://data/challenges/v0.7.0/challenges.json"
const SAMPLING_PATH := "res://tools/simulation/out/v0.7.0_deck_sampling.json"

var _checks: int = 0
var _failures: Array[String] = []

var _cards: Dictionary
var _progression: Dictionary
var _decks: Dictionary
var _balance: Dictionary
var _challenges: Dictionary


func _ready() -> void:
	_cards = _load_json(CARDS_PATH)
	_progression = _load_json(PROGRESSION_PATH)
	_decks = _load_json(DECKS_PATH)
	_balance = _load_json(BALANCE_PATH)
	_challenges = _load_json(CHALLENGES_PATH)

	_expect(not _cards.is_empty(), "cards load")
	_expect(not _progression.is_empty(), "progression load")
	_expect(not _decks.is_empty(), "decks load")
	_expect(not _balance.is_empty(), "balance load")
	_expect(not _challenges.is_empty(), "challenges load")
	_test_card_pool()
	_test_balance()
	_test_default_deck_and_presets()
	_test_upgrade_effect_in_battle_content()
	_test_sampling_output()

	if _failures.is_empty():
		print("V07_DECK_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("FAIL %s" % failure)
	print("V07_DECK_TESTS_FAILED checks=%d failures=%d" % [
		_checks,
		_failures.size(),
	])
	get_tree().quit(1)


func _test_card_pool() -> void:
	var cards: Array = _cards.get("cards", [])
	_expect(cards.size() == 20, "exactly 20 cards")
	var ids := {}
	for value in cards:
		if value is Dictionary:
			var definition_id := String(value.get("id", ""))
			_expect(not definition_id.is_empty(), "card id is not empty")
			_expect(not ids.has(definition_id), "card id unique: %s" % definition_id)
			ids[definition_id] = true
	_expect(ids.size() == 20, "20 unique card ids")

	var upgrade_definitions: Dictionary = _progression.get(
		"upgrade_definitions",
		{}
	)
	for value in _progression.get("gacha_pool", []):
		var definition_id := String(value.get("definition_id", ""))
		_expect(ids.has(definition_id), "gacha card exists: %s" % definition_id)
		_expect(
			upgrade_definitions.has(definition_id),
			"gacha card has upgrade definition: %s" % definition_id
		)
	var starter_ids: Array = _progression.get("starter_card_ids", [])
	_expect(starter_ids.size() >= 8, "starter collection has at least 8 cards")
	for definition_id in starter_ids:
		_expect(ids.has(String(definition_id)), "starter card exists")


func _test_balance() -> void:
	_expect(
		String(_balance.get("content_version", "")) == "v0.7.0",
		"balance version is v0.7.0"
	)
	var adapter = BattleBalanceAdapterScript.new(_balance)
	for parameter_id in [
		&"player.base_max_hp",
		&"player.base_max_spirit",
		&"battle.max_rounds",
		&"battle.enemy_pressure_start_round",
		&"progression.starting_divination_tickets",
		&"gacha.single_cost",
		&"gacha.triple_cost",
		&"gacha.rarity_weights",
		&"gacha.rare_pity",
		&"gacha.duplicate_fragments",
		&"upgrade.cost_by_next_level",
		&"reward.amounts",
	]:
		_expect(adapter.has_parameter(parameter_id), "balance parameter: %s" % parameter_id)


func _test_default_deck_and_presets() -> void:
	var base_content = BattleContentAdapterScript.new(_cards.get("cards", []))
	var deck_content = DeckContentAdapterScript.new(_decks)
	var deck_engine = DeckEngineScript.new(deck_content, base_content)
	var owned: Array = _decks.get("card_catalog_definition_ids", []).duplicate()
	var result = deck_engine.initialize(owned)
	_expect(result.accepted, "full-card deck engine initializes")
	if not result.accepted:
		return
	var default_deck: Array[String] = deck_engine.get_current_deck_ids()
	_expect(default_deck.size() == 8, "default deck has 8 cards")
	_expect(_unique(default_deck), "default deck has unique cards")
	var default_result = deck_engine.submit(DeckCommandScript.confirm_deck())
	_expect(default_result.accepted, "default deck confirms")
	for preset_value in _decks.get("presets", []):
		var preset: Dictionary = preset_value
		var preset_id := String(preset.get("id", ""))
		var selected = deck_engine.submit(
			DeckCommandScript.select_preset(StringName(preset_id))
		)
		_expect(selected.accepted, "preset selects: %s" % preset_id)
		var confirmed = deck_engine.submit(DeckCommandScript.confirm_deck())
		_expect(confirmed.accepted, "preset confirms: %s" % preset_id)
		var actual: Array[String] = deck_engine.get_confirmed_deck_ids()
		_expect(actual.size() == 8, "preset has 8 cards: %s" % preset_id)
		_expect(_unique(actual), "preset cards unique: %s" % preset_id)


func _test_upgrade_effect_in_battle_content() -> void:
	var base_content = BattleContentAdapterScript.new(_cards.get("cards", []))
	var content = ProgressionContentAdapterScript.new(_progression, base_content)
	var balance = BattleBalanceAdapterScript.new(_balance)
	var random_service = SeededRandomServiceScript.new(20261108)
	var progression = ProgressionEngineScript.new(
		content,
		balance,
		BattleRandomAdapterScript.new(random_service.get_stream(&"gacha.draw"))
	)
	var initial_state := _full_collection_state("identity.reporter")
	initial_state["collection"]["card.skill.ink_dart"]["level"] = 1
	var result = progression.initialize(initial_state)
	_expect(result.accepted, "upgraded progression state initializes")
	if not result.accepted:
		return
	var upgraded_content = progression.create_upgraded_content(base_content)
	var base_card: Dictionary = base_content.get_card_definition(
		&"card.skill.ink_dart"
	)
	var upgraded_card: Dictionary = upgraded_content.get_card_definition(
		&"card.skill.ink_dart"
	)
	_expect(
		int(base_card["effects"][0]["amount"]) == 4,
		"base ink dart amount"
	)
	_expect(
		int(upgraded_card["effects"][0]["amount"]) == 5,
		"level 1 ink dart amount is one higher"
	)


func _test_sampling_output() -> void:
	var output := _load_json(SAMPLING_PATH)
	_expect(not output.is_empty(), "deck sampling output exists")
	if output.is_empty():
		return
	_expect(String(output.get("version", "")) == "v0.7.0", "sampling version")
	_expect(int(output.get("samples_per_case", 0)) == 30, "sampling count")
	var cases: Array = output.get("cases", [])
	_expect(cases.size() == 42, "42 deck/identity/scenario cases")
	for value in cases:
		var case: Dictionary = value
		_expect(
			int(case.get("valid_runs", 0)) == 30,
			"case has 30 valid runs: %s" % case.get("id", "")
		)
	var deck_summary: Dictionary = output.get("deck_summary", {})
	var scenario_summary: Dictionary = output.get("scenario_summary", {})
	_expect(deck_summary.size() == 3, "three deck summaries")
	_expect(scenario_summary.size() == 7, "seven scenario summaries")
	for preset_id in [
		"deck.preset.ward",
		"deck.preset.oracle",
		"deck.preset.burst",
	]:
		_expect(deck_summary.has(preset_id), "summary exists: %s" % preset_id)
		if deck_summary.has(preset_id):
			var item: Dictionary = deck_summary[preset_id]
			_expect(int(item.get("valid_runs", 0)) > 0, "deck has valid runs")
			_expect(
				float(item.get("average_estimated_minutes", 0.0)) >= 15.0
				and float(item.get("average_estimated_minutes", 0.0)) <= 30.0,
				"deck runtime in 15-30 minute target: %s" % preset_id
			)


func _full_collection_state(identity_id: String) -> Dictionary:
	var collection := {}
	for definition_id in _decks.get("card_catalog_definition_ids", []):
		collection[String(definition_id)] = {
			"copies": 1,
			"level": 0,
			"fragments": 0,
		}
	return {
		"phase": "hub",
		"identity_id": identity_id,
		"divination_tickets": 3,
		"collection": collection,
		"pity_counter": 0,
		"reward_option_ids": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
		"revision": 1,
	}


func _unique(values: Array[String]) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}
