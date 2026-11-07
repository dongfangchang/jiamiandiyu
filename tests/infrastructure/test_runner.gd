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
	_test_balance_schema()
	_test_random_reproducibility_and_isolation()
	_test_save_round_trip_and_backup()
	_test_invalid_save_preserves_current()
	_test_corrupt_save_reports_backup()
	_test_migration_missing_and_success()
	_test_logger_writes_structured_event()
	_test_app_bootstrap()
	_test_battle_ports_and_adapters()
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


func _test_balance_schema() -> void:
	var loader = JsonDocumentLoaderScript.new()
	var schema_path := "res://data/schema/v0.2.0/balance.schema.json"
	var result = loader.load_document(
		"res://data/balance/v0.2.0/balance_draft.json",
		schema_path
	)
	_expect(result.ok, "current balance draft should satisfy v0.2.0 schema")

	var invalid = result.data.duplicate(true) if result.ok else {}
	if not invalid.is_empty():
		invalid.cards[0].id = invalid.cards[1].id
	var validator = SchemaValidatorScript.new()
	var duplicate_result = validator.validate_document(invalid, schema_path)
	_expect(
		not duplicate_result.ok and duplicate_result.code == &"schema_validation_failed",
		"duplicate stable IDs should fail schema validation"
	)
	if not duplicate_result.ok:
		var has_duplicate_error := false
		for error_text in duplicate_result.details.get("errors", []):
			if String(error_text).contains("duplicates value"):
				has_duplicate_error = true
				break
		_expect(has_duplicate_error, "schema errors should report duplicate ID")


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


func _test_battle_ports_and_adapters() -> void:
	var content_path := "res://tests/infrastructure/fixtures/battle_cards.json"
	var content_schema_path := "res://data/schema/v0.2.0/battle_cards.schema.json"
	var content_loaded = JsonDocumentLoaderScript.new().load_document(
		content_path,
		content_schema_path
	)
	_expect(content_loaded.ok, "battle card fixture should pass its schema")
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

	var invalid_fixture: Dictionary = ink_dart.duplicate(true)
	invalid_fixture.erase("effects")
	var invalid_document := {
		"schema_version": 1,
		"content_version": "test.v0.2.0",
		"cards": [invalid_fixture],
	}
	var invalid_result = SchemaValidatorScript.new().validate_document(
		invalid_document,
		content_schema_path
	)
	_expect(
		not invalid_result.ok,
		"battle card schema should reject a missing effects array"
	)

	var duplicate_fixture: Dictionary = ink_dart.duplicate(true)
	var duplicate_document := {
		"schema_version": 1,
		"content_version": "test.v0.2.0",
		"cards": [ink_dart.duplicate(true), duplicate_fixture],
	}
	var duplicate_result = SchemaValidatorScript.new().validate_document(
		duplicate_document,
		content_schema_path
	)
	_expect(
		not duplicate_result.ok,
		"battle card schema should reject duplicate stable IDs"
	)

	var balance_loaded = JsonDocumentLoaderScript.new().load_document(
		"res://data/balance/v0.2.0/balance_draft.json",
		"res://data/schema/v0.2.0/balance.schema.json"
	)
	_expect(balance_loaded.ok, "balance adapter should load the frozen draft")
	var balance = BattleBalanceAdapterScript.new(balance_loaded.data)
	_expect(balance.get_value(&"battle.max_rounds") == 10, "balance port should map max rounds")
	_expect(balance.get_value(&"player.starting_hand") == 5, "balance port should map starting hand")
	_expect(
		balance.get_value(&"battle.enemy_pressure_start_round") == 7,
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

	var bundle_result = AppBootstrapScript.load_battle_ports(
		20261108,
		content_path,
		content_schema_path,
		"res://data/balance/v0.2.0/balance_draft.json",
		"res://data/schema/v0.2.0/balance.schema.json"
	)
	_expect(bundle_result.ok, "app bootstrap should assemble all battle ports")
	if bundle_result.ok:
		_expect(bundle_result.data.content.card_count() == 2, "bundle should expose content port")
		_expect(
			bundle_result.data.balance.get_value(&"battle.max_rounds") == 10,
			"bundle should expose balance port"
		)
		_expect(
			bundle_result.data.random.stream_name() == &"battle.shuffle",
			"bundle should expose named battle random port"
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
