extends SceneTree

const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")
const JsonDocumentLoaderScript := preload("res://src/infrastructure/json_document_loader.gd")
const AtomicSaveServiceScript := preload("res://src/infrastructure/atomic_save_service.gd")
const SeededRandomServiceScript := preload("res://src/infrastructure/seeded_random_service.gd")
const StructuredLoggerScript := preload("res://src/infrastructure/structured_logger.gd")
const SchemaValidatorScript := preload("res://src/infrastructure/schema_validator.gd")
const BattleRandomAdapterScript := preload("res://src/infrastructure/battle_random_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const ProgressionContentAdapterScript := preload("res://src/infrastructure/progression_content_adapter.gd")
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")

const TEST_ROOT := "user://mask_whispers_infrastructure_tests"
const TEST_SAVE_DIRECTORY := "user://mask_whispers_infrastructure_tests/saves"
const TEST_LOG_DIRECTORY := "user://mask_whispers_infrastructure_tests/logs"

var _failures: Array[String] = []
var _passed := 0


func _initialize() -> void:
	_remove_tree(TEST_ROOT)
	_test_json_loader_success()
	_test_json_loader_failures()
	_test_v03_balance_schema()
	_test_random_reproducibility_and_isolation()
	_test_save_round_trip_and_backup()
	_test_invalid_save_preserves_current()
	_test_corrupt_save_reports_backup()
	_test_migration_missing_and_success()
	_test_logger_writes_structured_event()
	_test_app_bootstrap()
	_test_battle_adapters()
	_test_campaign_catalog_and_cross_references()
	_test_route_checkpoint_inspection()
	_test_v04_schemas_and_adapters()
	_test_v1_save_migrates_to_current()
	_remove_tree(TEST_ROOT)

	if _failures.is_empty():
		print("PASS infrastructure tests: %d" % _passed)
		quit(0)
		return

	for failure in _failures:
		printerr("FAIL %s" % failure)
	print("FAIL infrastructure tests: %d passed, %d failed" % [_passed, _failures.size()])
	quit(1)


func _test_json_loader_success() -> void:
	var loader = JsonDocumentLoaderScript.new()
	var result = loader.load_document("res://tests/infrastructure/fixtures/valid_document.json")
	_expect(result.ok, "valid JSON fixture should load")
	_expect(result.data.get("id", "") == "fixture.infrastructure.valid", "loaded JSON should preserve stable id")


func _test_json_loader_failures() -> void:
	var loader = JsonDocumentLoaderScript.new()
	var invalid = loader.load_document("res://tests/infrastructure/fixtures/invalid_document.json")
	_expect(not invalid.ok and invalid.code == &"invalid_json", "invalid JSON should return invalid_json")

	var missing = loader.load_document("res://tests/infrastructure/fixtures/missing.json")
	_expect(not missing.ok and missing.code == &"not_found", "missing document should return not_found")

	var invalid_path = loader.load_document("https://example.invalid/document.json")
	_expect(not invalid_path.ok and invalid_path.code == &"invalid_path", "absolute path should be rejected")

	var no_schema = loader.parse_document("{\"id\":\"fixture.no_schema\"}")
	_expect(not no_schema.ok and no_schema.code == &"invalid_schema_version", "schema version is required")


func _test_v03_balance_schema() -> void:
	var loader = JsonDocumentLoaderScript.new()
	var result = loader.load_document(
		"res://data/balance/v0.3.0/balance.json",
		"res://data/schema/v0.3.0/balance.schema.json"
	)
	_expect(result.ok, "v0.3 global balance should pass its schema")
	if result.ok:
		_expect(
			int(result.data.combat.enemy_pressure.start_round) == 5,
			"v0.3 enemy pressure should start on round five"
		)
		_expect(
			not result.data.has("cards") and not result.data.has("encounters"),
			"v0.3 balance must not duplicate card or enemy content"
		)


func _test_random_reproducibility_and_isolation() -> void:
	var service_a = SeededRandomServiceScript.new(20261108)
	var service_b = SeededRandomServiceScript.new(20261108)
	var first_values: Array[int] = []
	var second_values: Array[int] = []
	for index in range(12):
		first_values.append(service_a.get_stream(&"battle.shuffle").next_int(1000))
		second_values.append(service_b.get_stream(&"battle.shuffle").next_int(1000))
	_expect(first_values == second_values, "same seed and stream must reproduce values")

	service_a.get_stream(&"gacha.draw").next_int(1000)
	var repeated = service_a.get_stream(&"battle.shuffle").next_int(1000)
	var reference = service_b.get_stream(&"battle.shuffle").next_int(1000)
	_expect(repeated == reference, "unrelated stream must not advance battle stream")

	var shuffled_a = SeededRandomServiceScript.new(7).get_stream(&"shuffle").shuffle_copy([1, 2, 3, 4, 5])
	var shuffled_b = SeededRandomServiceScript.new(7).get_stream(&"shuffle").shuffle_copy([1, 2, 3, 4, 5])
	_expect(shuffled_a == shuffled_b, "shuffle must be reproducible")


func _test_save_round_trip_and_backup() -> void:
	var service = AtomicSaveServiceScript.new(TEST_SAVE_DIRECTORY, 1)
	var first = _save_envelope(1, 100, "first")
	var first_result = service.save_slot("slot_a", first)
	_expect(first_result.ok, "first save should succeed")
	var first_load = service.load_slot("slot_a")
	_expect(first_load.ok and first_load.data.profile.marker == "first", "first save should load")

	var second = _save_envelope(1, 200, "second")
	var second_result = service.save_slot("slot_a", second)
	_expect(second_result.ok, "second save should succeed")
	var second_load = service.load_slot("slot_a")
	_expect(second_load.ok and second_load.data.profile.marker == "second", "newest save should load")
	var backup_load = service.load_backup("slot_a")
	_expect(backup_load.ok and backup_load.data.profile.marker == "first", "backup should preserve previous save")

	var invalid_slot = service.save_slot("../escape", second)
	_expect(not invalid_slot.ok and invalid_slot.code == &"invalid_slot", "unsafe slot name should be rejected")


func _test_corrupt_save_reports_backup() -> void:
	var service = AtomicSaveServiceScript.new(TEST_SAVE_DIRECTORY, 1)
	service.save_slot("slot_corrupt", _save_envelope(1, 10, "stable"))
	service.save_slot("slot_corrupt", _save_envelope(1, 20, "next"))
	var main_path := service.get_slot_path("slot_corrupt")
	var file := FileAccess.open(main_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var result = service.load_slot("slot_corrupt")
	_expect(not result.ok and result.code == &"invalid_json", "corrupt main save should fail")
	_expect(result.details.get("backup_available", false), "corrupt save should report backup availability")


func _test_invalid_save_preserves_current() -> void:
	var service = AtomicSaveServiceScript.new(TEST_SAVE_DIRECTORY, 1)
	_expect(service.save_slot("slot_preserve", _save_envelope(1, 1, "stable")).ok, "baseline save should succeed")
	var invalid := _save_envelope(1, 2, "invalid")
	invalid.erase("collection")
	var rejected = service.save_slot("slot_preserve", invalid)
	_expect(not rejected.ok, "invalid envelope should be rejected")
	var current = service.load_slot("slot_preserve")
	_expect(current.ok and current.data.profile.marker == "stable", "invalid save must not replace current save")


func _test_migration_missing_and_success() -> void:
	var service = AtomicSaveServiceScript.new(TEST_SAVE_DIRECTORY, 2)
	var legacy = _save_envelope(2, 8, "legacy")
	legacy.save_version = 1
	var legacy_path := service.get_slot_path("slot_legacy")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_SAVE_DIRECTORY))
	var file := FileAccess.open(legacy_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy, "  ", true, true))
	file.close()

	var missing = service.load_slot("slot_legacy")
	_expect(not missing.ok and missing.code == &"migration_missing", "missing migration should fail explicitly")

	var registered = service.register_migration(1, func(document: Dictionary) -> Dictionary:
		document.save_version = 2
		return document
	)
	_expect(registered.ok, "valid migration registration should succeed")
	var migrated = service.load_slot("slot_legacy")
	_expect(
		migrated.ok and migrated.data.save_version == 2,
		"registered migration should produce current save (%s: %s)" % [migrated.code, migrated.message]
	)
	_expect(
		migrated.details.get("migrated", false),
		"migration result should be marked (%s: %s)" % [migrated.code, migrated.message]
	)


func _test_logger_writes_structured_event() -> void:
	var logger = StructuredLoggerScript.new(TEST_LOG_DIRECTORY, "test.log")
	var result = logger.write_event(&"info", &"save", &"round_trip", "save restored", {"slot": "slot_a"})
	_expect(result.ok, "logger should write event")
	var text := FileAccess.get_file_as_string(TEST_LOG_DIRECTORY.path_join("test.log"))
	_expect(text.contains("\"category\":\"save\""), "log should contain structured category")
	_expect(text.contains("\"slot\":\"slot_a\""), "log should contain context")


func _test_app_bootstrap() -> void:
	var services = AppBootstrapScript.create_services(20261108)
	_expect(services != null, "app bootstrap should create services")
	_expect(services.random.root_seed == 20261108, "app bootstrap should inject run seed")
	_expect(services.saves != null and services.logger != null and services.content != null, "app services should be complete")


func _test_battle_adapters() -> void:
	var content_loaded = JsonDocumentLoaderScript.new().load_document(
		"res://tests/infrastructure/fixtures/battle_cards.json"
	)
	_expect(content_loaded.ok, "battle card fixture should load")
	var content = BattleContentAdapterScript.new(content_loaded.data.get("cards", []))
	_expect(content.card_count() == 2, "content adapter should index both fixture cards")
	var ink_dart: Dictionary = content.get_card_definition(&"card.test.ink_dart")
	var effects: Array = ink_dart.get("effects", [])
	_expect(effects.size() == 1, "content adapter should preserve the effects array")
	if effects.size() == 1 and effects[0] is Dictionary:
		_expect(
			String(effects[0].get("effect_id", "")) == "damage",
			"content adapter should preserve the validated effect ID"
		)
		_expect(
			int(effects[0].get("amount", -1)) == 4,
			"content adapter should preserve the validated effect amount"
		)
	else:
		_expect(false, "content adapter should return an effect object")
	_expect(
		content.get_card_definition(&"card.test.missing").is_empty(),
		"missing content ID must not receive a default definition"
	)

	var balance_loaded = JsonDocumentLoaderScript.new().load_document(
		"res://data/balance/v0.7.0/balance.json",
		"res://data/schema/v0.7.0/balance.schema.json"
	)
	_expect(balance_loaded.ok, "balance adapter should load the current balance")
	var balance = BattleBalanceAdapterScript.new(balance_loaded.data)
	_expect(balance.get_value(&"battle.max_rounds") == 10, "balance port should map max rounds")
	_expect(balance.get_value(&"player.starting_hand") == 5, "balance port should map starting hand")
	_expect(
		balance.get_value(&"battle.enemy_pressure_start_round") == 5,
		"balance port should map enemy pressure start round"
	)
	_expect(
		balance.get_value(&"parameter.not_registered") == null,
		"unknown balance parameter must return null"
	)

	var random_a = BattleRandomAdapterScript.new(
		SeededRandomServiceScript.new(20261108).get_stream(&"battle.shuffle")
	)
	var random_b = BattleRandomAdapterScript.new(
		SeededRandomServiceScript.new(20261108).get_stream(&"battle.shuffle")
	)
	for _index in range(8):
		_expect(
			random_a.next_int(1000) == random_b.next_int(1000),
			"battle random adapter should reproduce the same named stream"
		)
	_expect(random_a.stream_name() == &"battle.shuffle", "random adapter should preserve stream name")


func _test_campaign_catalog_and_cross_references() -> void:
	var loader = JsonDocumentLoaderScript.new()
	var cards = loader.load_document(
		"res://tests/infrastructure/fixtures/v0.3.0/cards.json",
		"res://data/schema/v0.3.0/cards.schema.json"
	)
	var enemies = loader.load_document(
		"res://tests/infrastructure/fixtures/v0.3.0/enemies.json",
		"res://data/schema/v0.3.0/enemies.schema.json"
	)
	var encounters = loader.load_document(
		"res://tests/infrastructure/fixtures/v0.3.0/encounters.json",
		"res://data/schema/v0.3.0/encounters.schema.json"
	)
	_expect(cards.ok, "v0.3 cards fixture should pass schema")
	_expect(enemies.ok, "v0.3 enemies fixture should pass schema")
	_expect(encounters.ok, "v0.3 encounters fixture should pass schema")
	if not cards.ok or not enemies.ok or not encounters.ok:
		return

	var catalog = CampaignContentCatalogScript.new()
	var catalog_result = catalog.load_from_documents(
		cards.data,
		enemies.data,
		encounters.data
	)
	_expect(catalog_result.ok, "campaign catalog should load linked content")
	_expect(
		catalog.default_encounter_id() == "encounter.test.first_battle",
		"catalog should retain deterministic encounter order"
	)
	var resolved = catalog.resolve_encounter(&"encounter.test.first_battle")
	_expect(resolved.ok, "catalog should resolve an encounter")
	if resolved.ok:
		_expect(
			resolved.data.deck_definition_ids.size() == 8,
			"encounter should resolve its fixed deck"
		)
		_expect(
			resolved.data.enemy_configs.size() == 1,
			"encounter should resolve enemy slots into engine configs"
		)
		_expect(
			resolved.data.enemy_configs[0].id == "encounter.test.first_battle.enemy.0",
			"runtime enemy ID should be deterministic"
		)

	var version_mismatch: Dictionary = enemies.data.duplicate(true)
	version_mismatch.content_version = "v0.3.0-other"
	var version_result = CampaignContentCatalogScript.new().load_from_documents(
		cards.data,
		version_mismatch,
		encounters.data
	)
	_expect(
		not version_result.ok and version_result.code == &"content_version_mismatch",
		"catalog should reject mismatched content versions"
	)

	var bad_encounters: Dictionary = encounters.data.duplicate(true)
	bad_encounters.encounters[0].enemy_slots[0].enemy_id = "enemy.test.missing"
	var reference_result = CampaignContentCatalogScript.new().load_from_documents(
		cards.data,
		enemies.data,
		bad_encounters
	)
	_expect(
		not reference_result.ok and reference_result.code == &"encounter_enemy_missing",
		"catalog should reject missing enemy references"
	)

	var lane_encounters: Dictionary = encounters.data.duplicate(true)
	lane_encounters.encounters[0].enemy_slots = [
		{"enemy_id": "enemy.test.dummy", "lane_index": 0},
		{"enemy_id": "enemy.test.dummy", "lane_index": 0},
	]
	var lane_result = CampaignContentCatalogScript.new().load_from_documents(
		cards.data,
		enemies.data,
		lane_encounters
	)
	_expect(
		not lane_result.ok and lane_result.code == &"encounter_lane_invalid",
		"catalog should reject duplicate enemy lanes"
	)


func _test_route_checkpoint_inspection() -> void:
	var session_directory := TEST_SAVE_DIRECTORY.path_join("session")
	var slot := "session_checkpoint"
	var initial_inspection = AppBootstrapScript.inspect_route_checkpoint_v07(
		slot,
		session_directory
	)
	_expect(
		initial_inspection.ok and initial_inspection.data.status == "none",
		"checkpoint inspection should report a missing checkpoint explicitly"
	)
	var started = AppBootstrapScript.start_route_v07(
		20261108,
		{"save_directory": session_directory},
		slot
	)
	_expect(started.ok, "route should start from formal content")
	if not started.ok:
		return
	var session = started.data
	var selected = session.submit_progression(
		ProgressionCommand.select_identity(&"identity.doctor")
	)
	_expect(selected.accepted, "identity selection should be accepted")
	_expect(
		session.last_checkpoint_result != null and session.last_checkpoint_result.ok,
		"identity selection should write a checkpoint"
	)
	var inspected = AppBootstrapScript.inspect_route_checkpoint_v07(
		slot,
		session_directory
	)
	_expect(
		inspected.ok and inspected.data.status == "loaded",
		"checkpoint inspection should report loaded state"
	)
	if inspected.ok and inspected.data.status == "loaded":
		var checkpoint: Dictionary = inspected.data.checkpoint
		_expect(
			checkpoint.content_version == "v0.7.0",
			"checkpoint should report the current content version"
		)
		_expect(checkpoint.rng_seed == 20261108, "checkpoint should store root seed")
		_expect(
			checkpoint.identity_id == "identity.doctor",
			"checkpoint summary should include selected identity"
		)

	_expect(
		session.save_checkpoint().ok,
		"a later checkpoint should create a backup"
	)
	var save_service = AtomicSaveServiceScript.new(session_directory)
	var main_path := save_service.get_slot_path(slot)
	var file := FileAccess.open(main_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var corrupt_inspection = AppBootstrapScript.inspect_route_checkpoint_v07(
		slot,
		session_directory
	)
	_expect(
		corrupt_inspection.ok and corrupt_inspection.data.status == "corrupt",
		"checkpoint inspection should report a corrupt main save"
	)
	_expect(
		corrupt_inspection.ok and corrupt_inspection.data.backup_available,
		"corrupt checkpoint summary should expose backup availability"
	)


func _test_v04_schemas_and_adapters() -> void:
	var loader = JsonDocumentLoaderScript.new()
	var balance_result = loader.load_document(
		"res://data/balance/v0.4.0/balance.json",
		"res://data/schema/v0.4.0/balance.schema.json"
	)
	_expect(balance_result.ok, "v0.4 balance should pass its schema")
	var progression_result = loader.load_document(
		"res://data/cards/v0.4.0/progression.json",
		"res://data/schema/v0.4.0/progression.schema.json"
	)
	_expect(progression_result.ok, "v0.4 progression should pass its schema")
	if not balance_result.ok or not progression_result.ok:
		return
	_expect(
		int(balance_result.data.schema_version) == 2,
		"v0.4 balance should use schema version two"
	)
	var invalid_balance: Dictionary = balance_result.data.duplicate(true)
	invalid_balance.erase("progression")
	_expect(
		not SchemaValidatorScript.new().validate_document(
			invalid_balance,
			"res://data/schema/v0.4.0/balance.schema.json"
		).ok,
		"v0.4 balance schema should reject missing progression parameters"
	)
	var invalid_progression: Dictionary = progression_result.data.duplicate(true)
	invalid_progression.gacha_pool[0].rarity = "legendary"
	_expect(
		not SchemaValidatorScript.new().validate_document(
			invalid_progression,
			"res://data/schema/v0.4.0/progression.schema.json"
		).ok,
		"v0.4 progression schema should reject unsupported rarities"
	)

	var cards_result = loader.load_document(
		"res://data/cards/v0.3.0/cards.json",
		"res://data/schema/v0.3.0/cards.schema.json"
	)
	_expect(cards_result.ok, "base cards should load for progression adapter")
	if not cards_result.ok:
		return
	var base_content = BattleContentAdapterScript.new(cards_result.data.get("cards", []))
	var balance = BattleBalanceAdapterScript.new(balance_result.data)
	_expect(
		balance.get_value(&"progression.starting_divination_tickets") == 3,
		"balance adapter should map starting divination tickets"
	)
	_expect(
		balance.get_value(&"gacha.single_cost") == 2,
		"balance adapter should map gacha single cost"
	)
	_expect(
		balance.get_value(&"gacha.rare_pity") == 4,
		"balance adapter should map rare pity"
	)
	_expect(
		balance.get_value(&"upgrade.cost_by_next_level").get("1", -1) == 6,
		"balance adapter should map upgrade costs"
	)

	var progression_content = ProgressionContentAdapterScript.new(
		progression_result.data,
		base_content
	)
	_expect(
		progression_content.get_identity_options().size() == 3,
		"progression adapter should expose three identities"
	)
	_expect(
		progression_content.get_starter_card_ids().size() == 6,
		"progression adapter should expose six starter cards"
	)
	_expect(
		progression_content.has_card_definition(&"card.skill.ink_dart"),
		"progression adapter should resolve formal base card references"
	)
	_expect(
		not progression_content.has_card_definition(&"card.missing"),
		"progression adapter should reject missing base card references"
	)


func _test_v1_save_migrates_to_current() -> void:
	var migration_directory := TEST_SAVE_DIRECTORY.path_join("campaign_migration")
	var slot := "legacy_campaign"
	var save_service = SaveMigrationsScript.create_v07_service(migration_directory)
	var legacy := {
		"save_version": 1,
		"content_version": "v0.3.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": 771,
		"profile": {"pathway": "seer", "sequence": 9},
		"run": {"checkpoint_kind": "post_battle", "encounter_id": "encounter.first_hunt"},
		"collection": {},
	}
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(migration_directory)
	)
	var path := save_service.get_slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy, "  ", true, true))
	file.close()
	var loaded = save_service.load_slot(slot)
	_expect(loaded.ok, "v1 save should migrate through the full chain")
	if loaded.ok:
		_expect(
			int(loaded.data.save_version) == 5,
			"migrated save should use the current save version"
		)
		_expect(
			bool(loaded.data.progression.get("migrated_from_v1", false)),
			"migrated save should mark the progression reset"
		)
		_expect(
			bool(loaded.data.route.get("migrated_from_v2", false)),
			"migrated save should add an uninitialized route"
		)
		_expect(
			bool(loaded.data.challenge.get("migrated_from_v3", false)),
			"migrated save should add an inactive challenge"
		)
		_expect(
			bool(loaded.data.deck.get("migrated_from_v4", false)),
			"migrated save should add an uninitialized deck"
		)


func _save_envelope(save_version: int, seed_value: int, marker: String) -> Dictionary:
	return {
		"save_version": save_version,
		"content_version": "v0.2.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": seed_value,
		"profile": {"marker": marker},
		"run": {},
		"collection": {},
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
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
