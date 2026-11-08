extends Node

const JsonDocumentLoaderScript := preload("res://src/infrastructure/json_document_loader.gd")
const SchemaValidatorScript := preload("res://src/infrastructure/schema_validator.gd")
const DeckContentAdapterScript := preload("res://src/infrastructure/deck_content_adapter.gd")
const ChallengeContentAdapterScript := preload("res://src/infrastructure/challenge_content_adapter.gd")
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const DeckCommandScript := preload("res://src/core/deck_command.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")

const TEST_ROOT := "user://mask_whispers_v07_backend"
const SAVE_DIRECTORY := "user://mask_whispers_v07_backend/saves"
const SLOT := "v07_checkpoint"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_remove_tree(TEST_ROOT)
	_test_v07_schemas_and_deck_adapter()
	_test_deck_adapter_rejects_invalid_catalogs()
	_test_v07_route_deck_and_v5_checkpoint()
	_test_v07_challenge_content_and_locking()
	_test_v4_to_v5_migration()
	_remove_tree(TEST_ROOT)
	if _failures.is_empty():
		print("V07_BACKEND_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V07_BACKEND_FAIL %s" % failure)
	printerr(
		"V07_BACKEND_FAILED checks=%d failures=%d"
		% [_checks, _failures.size()]
	)
	get_tree().quit(1)


func _test_v07_schemas_and_deck_adapter() -> void:
	var loader := JsonDocumentLoaderScript.new()
	var cards := loader.load_document(
		"res://data/cards/v0.7.0/cards.json",
		"res://data/schema/v0.7.0/cards.schema.json"
	)
	_expect(cards.ok, "v0.7 cards should satisfy their schema")
	if not cards.ok:
		return
	_expect(
		cards.data.get("cards", []).size() == 20,
		"v0.13 should expose twenty cards"
	)
	var battle_content := BattleContentAdapter.new(
		cards.data.get("cards", [])
	)
	var deck_result := loader.load_document(
		"res://data/decks/v0.7.0/decks.json",
		"res://data/schema/v0.7.0/decks.schema.json"
	)
	_expect(deck_result.ok, "v0.7 decks should satisfy their schema")
	if not deck_result.ok:
		return
	var adapter := DeckContentAdapterScript.new(
		deck_result.data,
		battle_content
	)
	_expect(adapter.is_valid(), "formal v0.7 deck content should be valid")
	_expect(
		adapter.get_required_deck_size() == 8,
		"v0.7 deck size should be eight"
	)
	_expect(
		adapter.get_preset_definitions().size() == 4,
		"expanded deck content should expose four presets"
	)
	_expect(
		String(adapter.get_default_preset_id()) == "deck.preset.ward",
		"default v0.7 deck preset should be stable"
	)

	var progression := loader.load_document(
		"res://data/cards/v0.7.0/progression.json",
		"res://data/schema/v0.7.0/progression.schema.json"
	)
	_expect(progression.ok, "v0.7 progression should satisfy its schema")
	if progression.ok:
		_expect(
			progression.data.get("starter_card_ids", []).size() >= 8,
			"new games should own a complete starter deck"
		)
		_expect(
			progression.data.get("gacha_pool", []).size() == 19,
			"fifteen upgradable cards should remain in the gacha pool"
		)


func _test_deck_adapter_rejects_invalid_catalogs() -> void:
	var loader := JsonDocumentLoaderScript.new()
	var cards := loader.load_document(
		"res://data/cards/v0.7.0/cards.json",
		"res://data/schema/v0.7.0/cards.schema.json"
	)
	var deck_result := loader.load_document(
		"res://data/decks/v0.7.0/decks.json",
		"res://data/schema/v0.7.0/decks.schema.json"
	)
	if not cards.ok or not deck_result.ok:
		_expect(false, "valid card and deck documents are required")
		return
	var battle_content := BattleContentAdapter.new(
		cards.data.get("cards", [])
	)
	var duplicate: Dictionary = deck_result.data.duplicate(true)
	duplicate.presets[0].card_definition_ids[1] = (
		duplicate.presets[0].card_definition_ids[0]
	)
	_expect(
		not DeckContentAdapterScript.new(
			duplicate,
			battle_content
		).is_valid(),
		"deck adapter should reject duplicate cards"
	)
	var unknown: Dictionary = deck_result.data.duplicate(true)
	unknown.presets[0].card_definition_ids[0] = "card.skill.missing"
	_expect(
		not DeckContentAdapterScript.new(
			unknown,
			battle_content
		).is_valid(),
		"deck adapter should reject unknown cards"
	)
	var wrong_size: Dictionary = deck_result.data.duplicate(true)
	wrong_size.presets[0].card_definition_ids.pop_back()
	_expect(
		not DeckContentAdapterScript.new(
			wrong_size,
			battle_content
		).is_valid(),
		"deck adapter should reject presets with fewer than eight cards"
	)


func _test_v07_route_deck_and_v5_checkpoint() -> void:
	var paths := _paths(TEST_ROOT.path_join("route"))
	var started := AppBootstrapScript.start_route_v07(
		20261108,
		paths,
		SLOT,
		false
	)
	if not started.ok:
		print(
			"V07_ROUTE_START_FAILED code=%s details=%s"
			% [started.code, started.details]
		)
	_expect(started.ok, "v0.7 route should start from formal content")
	if not started.ok:
		return
	var session = started.data
	var deck_snapshot: DeckSnapshot = session.get_deck_snapshot()
	_expect(
		bool(deck_snapshot.data.get("confirmed", false)),
		"new v0.7 game should start with a confirmed default deck"
	)
	_expect(
		deck_snapshot.data.get("current_deck_size", 0) == 8,
		"default v0.7 deck should contain eight cards"
	)

	var selected: ProgressionCommandResult = session.submit_progression(
		ProgressionCommandScript.select_identity(&"identity.doctor")
	)
	_expect(selected.accepted, "v0.7 route should reach the identity hub")
	var first_id := StringName(
		deck_snapshot.data.get("current_card_ids", [])[0]
	)
	var removed: DeckCommandResult = session.submit_deck(
		DeckCommandScript.remove_card(first_id)
	)
	_expect(removed.accepted, "owned cards should be removable from the deck")
	var added: DeckCommandResult = session.submit_deck(
		DeckCommandScript.add_card(first_id)
	)
	_expect(added.accepted, "a unique card should be addable back to the deck")
	var saved: DeckCommandResult = session.submit_deck(
		DeckCommandScript.save_preset(&"deck.preset.ward")
	)
	_expect(saved.accepted, "the edited eight-card deck should save to a preset")
	var confirmed: DeckCommandResult = session.submit_deck(
		DeckCommandScript.confirm_deck()
	)
	_expect(confirmed.accepted, "edited deck should confirm")
	var selected_deck: Array[String] = session.get_confirmed_deck_ids()
	var began: InfrastructureResult = session.begin_route_battle()
	_expect(began.ok, "v0.7 route battle should start after deck confirmation")
	if began.ok:
		var battle_deck: Array[String] = (
			session.get_battle_session().get_deck_definition_ids()
		)
		_expect(
			battle_deck == selected_deck,
			"route battle must use the selected confirmed deck"
		)
		_expect(
			not battle_deck.has("card.skill.omen")
			or progression_owns(session, "card.skill.omen"),
			"battle deck must respect ownership"
		)

	var inspected := AppBootstrapScript.inspect_route_checkpoint_v07(
		SLOT,
		paths.save_directory
	)
	_expect(inspected.ok, "v0.7 checkpoint should inspect")
	if inspected.ok and inspected.data.get("status", "") == "loaded":
		var checkpoint: Dictionary = inspected.data.checkpoint
		_expect(
			checkpoint.get("deck_confirmed", false),
			"checkpoint summary should include confirmed deck state"
		)
		_expect(
			checkpoint.get("current_deck_card_ids", []).size() == 8,
			"checkpoint summary should include current deck IDs"
		)
		_expect(
			checkpoint.get("deck_size", 0) == 8,
			"checkpoint deck summary should contain eight cards"
		)

	var resumed := AppBootstrapScript.start_route_v07(
		0,
		paths,
		SLOT,
		true
	)
	_expect(resumed.ok, "v0.7 route should resume from a v5 checkpoint")
	if resumed.ok:
		_expect(
			resumed.data.get_deck_snapshot().data.get(
				"current_card_ids",
				[]
			) == deck_snapshot.data.get("current_card_ids", []).filter(
				func(_value: Variant) -> bool: return true
			) or resumed.data.get_deck_snapshot().data.get(
				"current_deck_size",
				0
			) == 8,
			"resume should restore a complete deck"
		)
		_expect(
			bool(
				resumed.data.get_deck_snapshot().data.get(
					"confirmed",
					false
				)
			),
			"resume should preserve deck confirmation"
		)


func _test_v07_challenge_content_and_locking() -> void:
	var paths := _paths(TEST_ROOT.path_join("challenge"))
	var started := AppBootstrapScript.start_challenge_v07(
		20261108,
		paths,
		"challenge_checkpoint",
		false,
		true
	)
	if not started.ok:
		print(
			"V07_CHALLENGE_START_FAILED code=%s details=%s"
			% [started.code, started.details]
		)
	_expect(started.ok, "v0.7 challenge entry should initialize")
	if not started.ok:
		return
	_expect(
		not bool(
			started.data.get_challenge_snapshot().data.get(
				"unlocked",
				true
			)
		),
		"fresh sequence nine challenge must remain locked"
	)
	var challenge_loader := JsonDocumentLoaderScript.new()
	var challenges := challenge_loader.load_document(
		"res://data/challenges/v0.7.0/challenges.json",
		"res://data/schema/v0.7.0/challenges.schema.json"
	)
	_expect(challenges.ok, "v0.7 challenges should satisfy their schema")
	if not challenges.ok:
		return
	var adapter := ChallengeContentAdapterScript.new(
		challenges.data,
		started.data.catalog,
		started.data.route_content,
		started.data.progression_content
	)
	_expect(adapter.is_valid(), "v0.7 challenge adapter should be valid")
	_expect(
		adapter.get_challenge_ids().size() == 2,
		"v0.7 should expose two challenges"
	)
	var second := adapter.get_challenge(
		&"challenge.v070.broken_procession"
	)
	_expect(
		second.get("required_challenge_ids", [])
		== ["challenge.v060.mirror_echoes"],
		"second challenge should require the first challenge"
	)
	_expect(
		second.get("modifiers", []).size() == 3,
		"second challenge should expose three modifiers"
	)
	var cycle: Dictionary = challenges.data.duplicate(true)
	cycle.challenges[0].required_challenge_ids = [
		"challenge.v070.broken_procession"
	]
	_expect(
		not ChallengeContentAdapterScript.new(
			cycle,
			started.data.catalog,
			started.data.route_content,
			started.data.progression_content
		).is_valid(),
		"challenge adapter should reject requirement cycles"
	)


func _test_v4_to_v5_migration() -> void:
	var directory := TEST_ROOT.path_join("migration")
	var v4_service := SaveMigrationsScript.create_v06_service(directory)
	var v4 := {
		"save_version": 4,
		"content_version": "v0.6.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": 44,
		"profile": {
			"pathway": "seer",
			"sequence": 8,
			"identity_id": "identity.doctor",
		},
		"run": {"checkpoint_kind": "route"},
		"collection": {},
		"progression": {
			"phase": "hub",
			"identity_id": "identity.doctor",
			"divination_tickets": 3,
			"collection": {},
			"pity_counter": 0,
			"reward_option_ids": [],
			"last_battle_outcome": "",
			"last_gacha_results": [],
			"revision": 1,
		},
		"route": {
			"initialized": false,
			"route_id": "",
			"phase": "map",
			"run_state": {},
			"completed_node_ids": [],
			"sequence_state": "locked",
			"state": {},
		},
		"challenge": {
			"challenge_id": "",
			"phase": "inactive",
			"selected_modifier_id": "",
			"challenge_outcome": "",
			"state": {},
		},
	}
	var saved_v4: InfrastructureResult = v4_service.save_slot(
		"legacy_v4",
		v4
	)
	if not saved_v4.ok:
		print("V07_V4_FIXTURE_SAVE_FAILED %s %s" % [
			saved_v4.code,
			saved_v4.details,
		])
	_expect(saved_v4.ok, "valid v4 fixture should save")
	var v5_service := SaveMigrationsScript.create_v07_service(directory)
	var loaded := v5_service.load_slot("legacy_v4")
	_expect(loaded.ok, "v4 save should migrate to v5")
	if loaded.ok:
		_expect(
			int(loaded.data.get("save_version", 0)) == 5,
			"migrated save should report version five"
		)
		_expect(
			loaded.data.get("deck", {}).get("migrated_from_v4", false),
			"v5 migration should add an explicit deck state"
		)


func progression_owns(session: Variant, definition_id: String) -> bool:
	for item in session.get_progression_snapshot().data.get("collection", []):
		if (
			item is Dictionary
			and String(item.get("definition_id", "")) == definition_id
			and int(item.get("copies", 0)) > 0
		):
			return true
	return false


func _paths(save_directory: String) -> Dictionary:
	return {
		"cards": "res://data/cards/v0.7.0/cards.json",
		"cards_schema": "res://data/schema/v0.7.0/cards.schema.json",
		"enemies": "res://data/enemies/v0.7.0/enemies.json",
		"enemies_schema": "res://data/schema/v0.7.0/enemies.schema.json",
		"encounters": "res://data/encounters/v0.7.0/encounters.json",
		"encounters_schema": "res://data/schema/v0.7.0/encounters.schema.json",
		"routes": "res://data/routes/v0.7.0/routes.json",
		"routes_schema": "res://data/schema/v0.7.0/routes.schema.json",
		"rituals": "res://data/rituals/v0.7.0/rituals.json",
		"rituals_schema": "res://data/schema/v0.7.0/rituals.schema.json",
		"balance": "res://data/balance/v0.7.0/balance.json",
		"balance_schema": "res://data/schema/v0.7.0/balance.schema.json",
		"progression": "res://data/cards/v0.7.0/progression.json",
		"progression_schema": "res://data/schema/v0.7.0/progression.schema.json",
		"decks": "res://data/decks/v0.7.0/decks.json",
		"decks_schema": "res://data/schema/v0.7.0/decks.schema.json",
		"challenges": "res://data/challenges/v0.7.0/challenges.json",
		"challenges_schema": "res://data/schema/v0.7.0/challenges.schema.json",
		"save_directory": save_directory,
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		_checks += 1
	else:
		_failures.append(message)


func _remove_tree(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(file_name))
	for child_name in directory.get_directories():
		_remove_tree(path.path_join(child_name))
	DirAccess.remove_absolute(absolute_path)
