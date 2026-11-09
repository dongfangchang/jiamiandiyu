extends Node

const DeckEngineScript := preload("res://src/gameplay/deck_engine.gd")
const DeckCommandScript := preload("res://src/core/deck_command.gd")
const ProgressionEngineScript := preload("res://src/gameplay/progression_engine.gd")
const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const ProgressionContentAdapterScript := preload("res://src/infrastructure/progression_content_adapter.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const BattleRandomAdapterScript := preload("res://src/infrastructure/battle_random_adapter.gd")
const SeededRandomServiceScript := preload("res://src/infrastructure/seeded_random_service.gd")

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const PROGRESSION_PATH := "res://data/cards/v0.7.0/progression.json"
const DECKS_PATH := "res://data/decks/v0.7.0/decks.json"
const BALANCE_PATH := "res://data/balance/v0.5.0/balance.json"

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_formal_card_pool()
	_test_default_deck_is_legal()
	_test_default_deck_has_defense_and_finishers()
	_test_all_presets_are_legal_when_all_cards_owned()
	_test_editor_rejections_and_reset()
	_test_preset_selection_and_confirmation()
	_test_save_preset_and_restore()
	_test_unowned_preset_is_reported()
	_test_new_card_upgrade_reaches_battle_content()
	_test_all_formal_cards_initialize_battle()
	_test_sequence_locked_card_view()

	if _failures.is_empty():
		print("V07_DECK_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V07_DECK_TEST_FAILURE: %s" % failure)
	printerr(
		"V07_DECK_TESTS_FAILED checks=%d failures=%d"
		% [_checks, _failures.size()]
	)
	get_tree().quit(1)


func _test_formal_card_pool() -> void:
	var cards_document := _read_json(CARDS_PATH)
	var progression := _read_json(PROGRESSION_PATH)
	var cards: Array = cards_document.get("cards", [])
	_check(cards.size() == 40, "formal expanded card pool should contain 40 cards")
	var ids := {}
	for value in cards:
		var card: Dictionary = value
		var definition_id := String(card.get("id", ""))
		_check(not definition_id.is_empty(), "card id should not be empty")
		_check(not ids.has(definition_id), "card ids should be unique")
		ids[definition_id] = true
	var upgrades: Dictionary = progression.get("upgrade_definitions", {})
	for entry in progression.get("gacha_pool", []):
		var definition_id := String(entry.get("definition_id", ""))
		_check(ids.has(definition_id), "gacha card should exist: %s" % definition_id)
		_check(
			upgrades.has(definition_id),
			"gacha card should have an upgrade definition: %s" % definition_id
		)
	_check(
		progression.get("starter_card_ids", []).size() >= 8,
		"starter collection should allow an eight-card deck"
	)
	_check(
		"card.skill.omen" in progression.get("starter_card_ids", []),
		"starter collection should include a reachable mark enabler"
	)
	_check(
		"card.skill.coffin_nail" in progression.get("starter_card_ids", []),
		"starter collection should include a reliable finisher"
	)


func _test_default_deck_is_legal() -> void:
	var result := _new_engine(_starter_ids()).initialize(_starter_ids())
	_check(result.accepted, "deck engine should initialize")
	_check(result.snapshot.data.legal, "default deck should be immediately legal")
	_check(
		int(result.snapshot.data.current_deck_size) == 8,
		"default deck should contain eight cards"
	)
	_check(
		not result.snapshot.data.confirmed,
		"default deck should require explicit confirmation"
	)


func _test_default_deck_has_defense_and_finishers() -> void:
	var result := _new_engine(_starter_ids()).initialize(_starter_ids())
	var cards: Array = _read_json(CARDS_PATH).get("cards", [])
	var deck_ids: Array = result.snapshot.data.current_card_ids
	_check(
		_count_cards_with_effects(deck_ids, cards, ["damage"]) >= 2,
		"default deck should contain at least two damage sources"
	)
	_check(
		_count_cards_with_effects(deck_ids, cards, ["block", "heal"]) >= 2,
		"default deck should contain at least two defensive cards"
	)


func _test_all_presets_are_legal_when_all_cards_owned() -> void:
	var cards: Array = _read_json(CARDS_PATH).get("cards", [])
	var all_owned: Array = []
	for value in cards:
		all_owned.append(String(value.get("id", "")))
	var engine := _new_engine(all_owned)
	_check(engine.initialize(all_owned).accepted, "full collection deck engine should initialize")
	for preset_id in [
		&"deck.preset.ward",
		&"deck.preset.oracle",
		&"deck.preset.burst",
	]:
		var selected := engine.submit(
			DeckCommandScript.select_preset(preset_id)
		)
		_check(
			selected.accepted and selected.snapshot.data.legal,
			"preset should become legal with full collection: %s" % preset_id
		)
		var deck_ids: Array = selected.snapshot.data.current_card_ids
		_check(
			_count_cards_with_effects(deck_ids, cards, ["damage"]) >= 2,
			"preset should have at least two damage sources: %s" % preset_id
		)
		_check(
			_count_cards_with_effects(deck_ids, cards, ["block", "heal"]) >= 2,
			"preset should have at least two defensive cards: %s" % preset_id
		)


func _test_editor_rejections_and_reset() -> void:
	var engine := _new_engine(_starter_ids())
	_check(engine.initialize(_starter_ids()).accepted, "deck editor should initialize")
	var duplicate := engine.submit(DeckCommandScript.add_card(
		&"card.skill.ink_dart"
	))
	_check(
		not duplicate.accepted and duplicate.reason_code == &"duplicate_card",
		"duplicate card should be rejected"
	)
	var unowned := engine.submit(DeckCommandScript.add_card(
		&"card.skill.fated_echo"
	))
	_check(
		not unowned.accepted and unowned.reason_code == &"card_not_owned",
		"unowned card should be rejected"
	)
	engine.submit(DeckCommandScript.remove_card(&"card.skill.focus"))
	_check(
		not engine.submit(DeckCommandScript.confirm_deck()).accepted,
		"seven-card deck should not confirm"
	)
	engine.submit(DeckCommandScript.clear_deck())
	_check(
		engine.get_snapshot().data.reason_code == "empty_deck",
		"empty deck should expose a stable reason"
	)
	engine.submit(DeckCommandScript.reset_default())
	_check(
		engine.get_snapshot().data.legal,
		"reset should restore the legal default deck"
	)


func _test_preset_selection_and_confirmation() -> void:
	var owned := _starter_ids()
	owned.append("card.skill.omen")
	owned.append("card.skill.whisper")
	owned.append("card.skill.whispered_hunch")
	owned.append("card.skill.mirrored_memory")
	owned.append("card.skill.second_sight")
	var engine := _new_engine(owned)
	engine.initialize(owned)
	var selected := engine.submit(DeckCommandScript.select_preset(
		&"deck.preset.oracle"
	))
	_check(selected.accepted, "known preset should be selectable")
	_check(
		selected.snapshot.data.legal,
		"oracle preset should be legal when all cards are owned"
	)
	var confirmed := engine.submit(DeckCommandScript.confirm_deck())
	_check(confirmed.accepted, "legal preset should confirm")
	_check(
		engine.get_confirmed_deck_ids().size() == 8,
		"confirmed deck should expose eight cards"
	)
	var invalid_preset := engine.submit(DeckCommandScript.select_preset(
		&"deck.preset.unknown"
	))
	_check(
		not invalid_preset.accepted
		and invalid_preset.reason_code == &"unknown_preset",
		"unknown preset should be rejected"
	)


func _test_save_preset_and_restore() -> void:
	var owned := _starter_ids()
	var engine := _new_engine(owned)
	engine.initialize(owned)
	engine.submit(DeckCommandScript.remove_card(&"card.skill.second_look"))
	engine.submit(DeckCommandScript.add_card(&"card.skill.omen"))
	# The card is not owned yet, so build a collection that is legal for the
	# persistence check and replace one starter with the newly-owned card.
	var full_owned := owned.duplicate()
	full_owned.append("card.skill.omen")
	engine = _new_engine(full_owned)
	engine.initialize(full_owned)
	engine.submit(DeckCommandScript.remove_card(&"card.skill.second_look"))
	engine.submit(DeckCommandScript.add_card(&"card.skill.omen"))
	var saved := engine.submit(DeckCommandScript.save_preset(
		&"deck.preset.burst"
	))
	_check(saved.accepted, "legal edited deck should save to a preset slot")
	_check(engine.submit(DeckCommandScript.confirm_deck()).accepted, "saved deck should confirm")
	var persistent := engine.export_persistent_state()
	var restored := _new_engine(full_owned).initialize(full_owned, persistent)
	_check(restored.accepted, "deck state should restore")
	_check(
		restored.snapshot.data.confirmed,
		"restore should preserve confirmation"
	)
	_check(
		"card.skill.omen" in restored.snapshot.data.current_card_ids,
		"restore should preserve current deck edits"
	)


func _test_unowned_preset_is_reported() -> void:
	var engine := _new_engine(_starter_ids())
	engine.initialize(_starter_ids())
	var selected := engine.submit(DeckCommandScript.select_preset(
		&"deck.preset.burst"
	))
	_check(selected.accepted, "locked preset should load for inspection")
	_check(
		not selected.snapshot.data.legal
		and selected.snapshot.data.reason_code == "card_not_owned",
		"unowned preset should report card_not_owned"
	)
	_check(
		not engine.submit(DeckCommandScript.confirm_deck()).accepted,
		"unowned preset should not confirm"
	)


func _test_new_card_upgrade_reaches_battle_content() -> void:
	var cards_document := _read_json(CARDS_PATH)
	var progression_document := _read_json(PROGRESSION_PATH)
	var balance_document := _read_json(BALANCE_PATH)
	var base_content := BattleContentAdapterScript.new(
		cards_document.get("cards", [])
	)
	var progression_content := ProgressionContentAdapterScript.new(
		progression_document,
		base_content
	)
	var random_service := SeededRandomServiceScript.new(20261108)
	var progression := ProgressionEngineScript.new(
		progression_content,
		BattleBalanceAdapterScript.new(balance_document),
		BattleRandomAdapterScript.new(
			random_service.get_stream(&"gacha.draw")
		)
	)
	var state := {
		"phase": "hub",
		"identity_id": "identity.reporter",
		"divination_tickets": 0,
		"pity_counter": 0,
		"collection": {
			"card.skill.warding_circle": {
				"copies": 1,
				"level": 1,
				"fragments": 0
			}
		},
		"last_battle_outcome": "",
		"reward_option_ids": [],
		"last_gacha_results": []
	}
	var initialized := progression.initialize(state)
	_check(initialized.accepted, "formal v0.7 progression should initialize")
	if not initialized.accepted:
		return
	var upgraded_content: BattleContentPort = progression.create_upgraded_content(
		base_content
	)
	var definition := upgraded_content.get_card_definition(
		&"card.skill.warding_circle"
	)
	_check(
		int(definition["effects"][0]["amount"]) == 5,
		"new card upgrade should be visible to battle content"
	)


func _test_all_formal_cards_initialize_battle() -> void:
	var cards_document := _read_json(CARDS_PATH)
	var balance_document := _read_json(BALANCE_PATH)
	var base_content := BattleContentAdapterScript.new(
		cards_document.get("cards", [])
	)
	var balance := BattleBalanceAdapterScript.new(balance_document)
	var random := BattleRandomAdapterScript.new(
		SeededRandomServiceScript.new(20261108).get_stream(
			&"battle.shuffle"
		)
	)
	var deck_ids: Array[String] = []
	for card in cards_document.get("cards", []):
		deck_ids.append(String(card.get("id", "")))
	var battle := BattleEngineScript.new()
	var initialized := battle.initialize(
		base_content,
		balance,
		random,
		&"v07.card.pool",
		{
			"actor_id": "player",
			"hp": 54,
			"max_hp": 54,
			"block": 0,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
			"statuses": []
		},
		deck_ids,
		[{
			"id": "enemy.test",
			"definition_id": "enemy.test",
			"lane_index": 1,
			"hp": 20,
			"max_hp": 20,
			"base_attack": 2
		}]
	)
	_check(
		initialized.accepted,
		"all 16 formal cards should pass BattleEngine validation"
	)


func _test_sequence_locked_card_view() -> void:
	var owned := _starter_ids()
	owned.append("card.skill.lantern_step")
	var engine := _new_engine(owned)
	_check(engine.initialize(owned, {}, 9).accepted, "sequence nine deck initializes")
	for card in engine.get_snapshot().data.cards:
		if card.definition_id == "card.skill.lantern_step":
			_check(card.owned and not card.can_add, "owned lantern step is not addable at sequence nine")
			_check(card.add_reason_code == "sequence_locked" and card.required_sequence == 8, "locked card explains the required sequence")
	var before := engine.export_persistent_state()
	var rejected := engine.submit(DeckCommandScript.add_card(&"card.skill.lantern_step"))
	_check(not rejected.accepted and rejected.reason_code == &"sequence_locked", "adding sequence eight card remains rejected")
	_check(engine.export_persistent_state() == before, "rejected sequence card does not mutate deck")
	for card in engine.set_current_sequence(8).data.cards:
		if card.definition_id == "card.skill.lantern_step":
			_check(card.can_add and card.add_reason_code == "playable", "advancement refreshes addability")
	_check(engine.submit(DeckCommandScript.add_card(&"card.skill.lantern_step")).accepted, "advanced player can add owned lantern step")


func _new_engine(owned_ids: Array) -> DeckEngine:
	var deck_document := _read_json(DECKS_PATH)
	var cards_document := _read_json(CARDS_PATH)
	var battle_content := BattleContentAdapterScript.new(
		cards_document.get("cards", [])
	)
	return DeckEngineScript.new(
		DeckContentFixture.new(deck_document),
		battle_content
	)


func _starter_ids() -> Array:
	var progression := _read_json(PROGRESSION_PATH)
	return progression.get("starter_card_ids", []).duplicate()


func _count_cards_with_effects(
	deck_ids: Array,
	cards: Array,
	effect_ids: Array
) -> int:
	var count := 0
	for deck_id in deck_ids:
		for value in cards:
			var card: Dictionary = value
			if String(card.get("id", "")) != String(deck_id):
				continue
			for effect in card.get("effects", []):
				if String(effect.get("effect_id", "")) in effect_ids:
					count += 1
					break
			break
	return count


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "JSON should be readable: %s" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_check(parsed is Dictionary, "JSON should parse as object: %s" % path)
	return parsed if parsed is Dictionary else {}


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


class DeckContentFixture:
	extends DeckContentPort

	var _document: Dictionary

	func _init(document: Dictionary) -> void:
		_document = document.duplicate(true)

	func get_default_preset_id() -> StringName:
		return StringName(_document.get("default_preset_id", ""))

	func get_required_deck_size() -> int:
		return int(_document.get("required_deck_size", 0))

	func get_preset_definitions() -> Array:
		return _document.get("presets", []).duplicate(true)

	func get_preset(preset_id: StringName) -> Dictionary:
		for preset in _document.get("presets", []):
			if String(preset.get("id", "")) == String(preset_id):
				return preset.duplicate(true)
		return {}

	func get_card_catalog_ids() -> Array:
		return _document.get(
			"card_catalog_definition_ids",
			[]
		).duplicate()
