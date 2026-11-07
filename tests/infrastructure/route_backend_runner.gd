extends Node

const JsonDocumentLoaderScript := preload("res://src/infrastructure/json_document_loader.gd")
const SchemaValidatorScript := preload("res://src/infrastructure/schema_validator.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const RouteContentAdapterScript := preload("res://src/infrastructure/route_content_adapter.gd")
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")

const TEST_ROOT := "user://mask_whispers_route_backend_v05"
const SAVE_DIRECTORY := "user://mask_whispers_route_backend_v05/saves"
const SLOT := "route_checkpoint"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_remove_tree(TEST_ROOT)
	_test_schemas_and_cross_version_catalog()
	_test_route_adapter_rejects_bad_references()
	_test_route_session_and_node_resume()
	_test_v1_and_v2_migrations()
	_remove_tree(TEST_ROOT)
	if _failures.is_empty():
		print("ROUTE_BACKEND_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("ROUTE_BACKEND_FAIL %s" % failure)
	print("ROUTE_BACKEND_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)


func _test_schemas_and_cross_version_catalog() -> void:
	var loader := JsonDocumentLoaderScript.new()
	var cards := loader.load_document(
		"res://data/cards/v0.3.0/cards.json",
		"res://data/schema/v0.3.0/cards.schema.json"
	)
	var enemies := loader.load_document(
		"res://data/enemies/v0.5.0/enemies.json",
		"res://data/schema/v0.5.0/enemies.schema.json"
	)
	var encounters := loader.load_document(
		"res://data/encounters/v0.5.0/encounters.json",
		"res://data/schema/v0.5.0/encounters.schema.json"
	)
	var routes := loader.load_document(
		"res://data/routes/v0.5.0/routes.json",
		"res://data/schema/v0.5.0/routes.schema.json"
	)
	var rituals := loader.load_document(
		"res://data/rituals/v0.5.0/rituals.json",
		"res://data/schema/v0.5.0/rituals.schema.json"
	)
	var balance := loader.load_document(
		"res://data/balance/v0.5.0/balance.json",
		"res://data/schema/v0.5.0/balance.schema.json"
	)
	_expect(cards.ok, "v0.3 cards should satisfy their schema")
	_expect(enemies.ok, "v0.5 enemies with phases should satisfy their schema")
	_expect(encounters.ok, "v0.5 encounters should satisfy their schema")
	_expect(routes.ok, "v0.5 routes should satisfy their schema")
	_expect(rituals.ok, "v0.5 rituals should satisfy their schema")
	_expect(balance.ok, "v0.5 balance should satisfy its schema")
	if not cards.ok or not enemies.ok or not encounters.ok or not routes.ok or not rituals.ok:
		return

	var catalog := CampaignContentCatalogScript.new()
	var loaded := catalog.load_from_documents(
		cards.data,
		enemies.data,
		encounters.data
	)
	_expect(loaded.ok, "catalog should accept a v0.5 package using v0.3 cards")
	_expect(catalog.content_version == "v0.5.0", "catalog package version should be v0.5.0")
	_expect(catalog.cards_content_version == "v0.3.0", "catalog should retain the base card version")
	var boss := catalog.resolve_encounter(&"encounter.mirror_baron")
	_expect(boss.ok, "boss encounter should resolve across package versions")
	if boss.ok:
		_expect(boss.data.enemy_configs.size() == 1, "boss encounter should have one enemy")
		_expect(
			boss.data.enemy_configs[0].phases.size() == 2,
			"boss phases should reach the battle configuration"
		)

	var adapter := RouteContentAdapterScript.new(routes.data, rituals.data, catalog)
	_expect(adapter.is_valid(), "route adapter should validate route and ritual references")
	_expect(adapter.has_route(&"route.v050.first_case"), "formal route should be exposed")
	_expect(
		adapter.has_ritual(&"ritual.v050.tampered_obituary"),
		"formal ritual should be exposed"
	)
	var formal_route: Dictionary = adapter.get_route(&"route.v050.first_case")
	if not formal_route.is_empty():
		var seal_effects: Dictionary = formal_route.rest_options[1].effects
		_expect(
			int(seal_effects.get("max_spirit_delta", 0)) == 1,
			"route adapter should preserve the formal max spirit rest modifier"
		)

	var missing_delta: Dictionary = routes.data.duplicate(true)
	missing_delta.routes[0].rest_options[1].effects.erase("max_spirit_delta")
	var missing_delta_validation = SchemaValidatorScript.new().validate_document(
		missing_delta,
		"res://data/schema/v0.5.0/routes.schema.json"
	)
	_expect(
		missing_delta_validation.ok,
		"rest max_spirit_delta should be optional for older route data"
	)
	var missing_delta_adapter := RouteContentAdapterScript.new(
		missing_delta,
		rituals.data,
		catalog
	)
	_expect(
		missing_delta_adapter.is_valid(),
		"route adapter should accept rest data without max_spirit_delta"
	)
	if missing_delta_adapter.is_valid():
		var defaulted_route: Dictionary = missing_delta_adapter.get_route(
			&"route.v050.first_case"
		)
		_expect(
			int(defaulted_route.rest_options[1].effects.get("max_spirit_delta", 0)) == 0,
			"missing rest max_spirit_delta should default to zero"
		)

	var invalid_delta_type: Dictionary = routes.data.duplicate(true)
	invalid_delta_type.routes[0].rest_options[1].effects.max_spirit_delta = "1"
	_expect(
		not SchemaValidatorScript.new().validate_document(
			invalid_delta_type,
			"res://data/schema/v0.5.0/routes.schema.json"
		).ok,
		"route schema should reject a non-integer max_spirit_delta"
	)

	var invalid_delta_range: Dictionary = routes.data.duplicate(true)
	invalid_delta_range.routes[0].rest_options[1].effects.max_spirit_delta = 6
	_expect(
		not SchemaValidatorScript.new().validate_document(
			invalid_delta_range,
			"res://data/schema/v0.5.0/routes.schema.json"
		).ok,
		"route schema should reject max_spirit_delta outside the allowed range"
	)

	var duplicate_phases: Dictionary = enemies.data.duplicate(true)
	duplicate_phases.enemies[4].phases[1].id = duplicate_phases.enemies[4].phases[0].id
	var phase_validation = SchemaValidatorScript.new().validate_document(
		duplicate_phases,
		"res://data/schema/v0.5.0/enemies.schema.json"
	)
	_expect(
		not phase_validation.ok,
		"enemy schema should reject duplicate phase IDs"
	)


func _test_route_adapter_rejects_bad_references() -> void:
	var loader := JsonDocumentLoaderScript.new()
	var cards := loader.load_document(
		"res://data/cards/v0.3.0/cards.json",
		"res://data/schema/v0.3.0/cards.schema.json"
	)
	var enemies := loader.load_document(
		"res://data/enemies/v0.5.0/enemies.json",
		"res://data/schema/v0.5.0/enemies.schema.json"
	)
	var encounters := loader.load_document(
		"res://data/encounters/v0.5.0/encounters.json",
		"res://data/schema/v0.5.0/encounters.schema.json"
	)
	var routes := loader.load_document(
		"res://data/routes/v0.5.0/routes.json",
		"res://data/schema/v0.5.0/routes.schema.json"
	)
	var rituals := loader.load_document(
		"res://data/rituals/v0.5.0/rituals.json",
		"res://data/schema/v0.5.0/rituals.schema.json"
	)
	if not (cards.ok and enemies.ok and encounters.ok and routes.ok and rituals.ok):
		_expect(false, "valid fixtures are required for bad-reference test")
		return
	var catalog := CampaignContentCatalogScript.new()
	_expect(
		catalog.load_from_documents(cards.data, enemies.data, encounters.data).ok,
		"catalog should load before bad route test"
	)
	var bad_routes: Dictionary = routes.data.duplicate(true)
	bad_routes.routes[0].nodes[0].encounter_id = "encounter.missing"
	var adapter := RouteContentAdapterScript.new(bad_routes, rituals.data, catalog)
	_expect(not adapter.is_valid(), "route adapter should reject a missing encounter reference")


func _test_route_session_and_node_resume() -> void:
	var started = AppBootstrapScript.start_route(
		20261108,
		_route_paths(),
		SLOT,
		false
	)
	if not started.ok:
		print("ROUTE_START_FAILED code=%s details=%s" % [started.code, started.details])
	_expect(started.ok, "new route session should load all formal content")
	if not started.ok:
		return
	var session = started.data
	_expect(session.is_ready(), "route session should be ready during identity selection")
	_expect(
		session.get_progression_snapshot().data.phase == "identity_selection",
		"new route session should begin at identity selection"
	)
	var selected = session.submit_progression(
		ProgressionCommandScript.select_identity(&"identity.doctor")
	)
	_expect(selected.accepted, "route session should accept identity selection")
	_expect(
		session.get_route_snapshot().data.run_state.max_hp == 58,
		"identity max-health modifier should enter route run state"
	)
	_expect(
		session.last_checkpoint_result != null and session.last_checkpoint_result.ok,
		"identity selection should write a v3 checkpoint"
	)

	_expect(_play_current_route_battle(session), "first route battle should be won")
	_expect(_claim_reward(session), "first battle reward should be claimed")
	_expect(_play_current_route_battle(session), "elite route battle should be won")
	_expect(_claim_reward(session), "elite battle reward should be claimed")
	_expect(
		session.get_route_snapshot().data.current_node_id == "route.v050.node.old_house_rest",
		"route should stop at the rest node"
	)

	var inspected = AppBootstrapScript.inspect_route_checkpoint(SLOT, SAVE_DIRECTORY)
	_expect(inspected.ok and inspected.data.status == "loaded", "route checkpoint should inspect as loaded")
	if inspected.ok and inspected.data.status == "loaded":
		_expect(
			inspected.data.checkpoint.current_node_id == "route.v050.node.old_house_rest",
			"checkpoint summary should expose the current rest node"
		)
	var resumed = AppBootstrapScript.start_route(
		0,
		_route_paths(),
		SLOT,
		true
	)
	_expect(resumed.ok, "route should resume at the node boundary")
	if not resumed.ok:
		return
	session = resumed.data
	_expect(
		session.get_route_snapshot().data.current_node_id == "route.v050.node.old_house_rest",
		"resume should restore the rest node"
	)
	_expect(
		session.get_route_snapshot().data.run_state.max_hp == 58,
		"resume should preserve identity-modified route health"
	)

	var select_rest = session.submit_route(
		RouteCommandScript.select_node(&"route.v050.node.old_house_rest")
	)
	_expect(select_rest.accepted, "rest node should be selectable")
	var used_rest = session.submit_route(
		RouteCommandScript.use_rest(&"rest.seal_echo")
	)
	_expect(used_rest.accepted, "seal echo rest should resolve once")
	_expect(
		int(session.get_route_snapshot().data.run_state.max_spirit) == 4,
		"seal echo should increase the next route battle spirit cap"
	)
	_expect(
		int(session.get_route_snapshot().data.run_state.attention) >= 1,
		"seal echo should add attention to route state"
	)
	_expect(
		session.get_route_snapshot().data.current_node_id == "route.v050.node.mirror_baron",
		"rest should unlock the boss"
	)
	_expect(_play_current_route_battle(session), "boss battle should be won")
	_expect(_claim_reward(session), "boss reward should be claimed")
	var begun = session.submit_route(RouteCommandScript.begin_ascension())
	_expect(begun.accepted, "ascension should begin after the boss")
	_expect(
		session.submit_route(RouteCommandScript.submit_ritual_step(
			["name.elin_ward", "name.thomas_ward"]
		)).accepted,
		"ritual name step should accept two Ward names"
	)
	_expect(
		session.submit_route(RouteCommandScript.submit_ritual_step(
			["event.birth", "event.death", "event.burial"]
		)).accepted,
		"ritual chronology step should accept chronological order"
	)
	var ritual_done = session.submit_route(RouteCommandScript.submit_ritual_step(
		["seal.inverted_eye"]
	))
	_expect(ritual_done.accepted, "ritual seal step should complete ascension")
	_expect(
		session.get_route_snapshot().data.phase == "completed",
		"route should complete after ascension"
	)
	_expect(
		int(session.get_sequence_state().data.current_sequence) == 8,
		"sequence should advance to eight"
	)
	_expect(
		session.get_sequence_state().data.next_sequence_name_zh == "小丑",
		"sequence eight should expose the Clown name"
	)
	_expect(
		session.last_checkpoint_result != null and session.last_checkpoint_result.ok,
		"ritual completion should persist a checkpoint"
	)
	var final_inspection = AppBootstrapScript.inspect_route_checkpoint(SLOT, SAVE_DIRECTORY)
	_expect(final_inspection.ok, "completed route checkpoint should be inspectable")
	if final_inspection.ok:
		_expect(
			final_inspection.data.checkpoint.sequence == 8,
			"checkpoint summary should persist sequence eight"
		)
		_expect(
			final_inspection.data.checkpoint.route_phase == "completed",
			"checkpoint summary should persist completed route phase"
		)


func _test_v1_and_v2_migrations() -> void:
	var migration_directory := TEST_ROOT.path_join("migrations")
	var service = SaveMigrationsScript.create_v05_service(migration_directory)
	var progression := {
		"phase": "identity_selection",
		"identity_id": "",
		"divination_tickets": 3,
		"collection": {},
		"pity_counter": 0,
		"reward_option_ids": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
		"revision": 1,
	}
	var v2 := {
		"save_version": 2,
		"content_version": "v0.4.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": 101,
		"profile": {"pathway": "seer", "sequence": 9},
		"run": {"checkpoint_kind": "post_battle"},
		"collection": {},
		"progression": progression.duplicate(true),
	}
	var v2_loaded: InfrastructureResult = _write_and_load(
		service,
		"legacy_v2",
		v2
	)
	_expect(v2_loaded.ok, "v2 save should migrate to v3")
	if v2_loaded.ok:
		_expect(int(v2_loaded.data.save_version) == 3, "v2 migration should produce save version three")
		_expect(
			not bool(v2_loaded.data.route.initialized),
			"v2 migration should create an uninitialized route"
		)

	var v1 := {
		"save_version": 1,
		"content_version": "v0.3.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": 202,
		"profile": {"pathway": "seer", "sequence": 9},
		"run": {"checkpoint_kind": "post_battle"},
		"collection": {},
	}
	var v1_loaded: InfrastructureResult = _write_and_load(
		service,
		"legacy_v1",
		v1
	)
	if not v1_loaded.ok:
		print("V1_MIGRATION_FAILED code=%s message=%s details=%s" % [
			v1_loaded.code,
			v1_loaded.message,
			v1_loaded.details,
		])
	_expect(v1_loaded.ok, "v1 save should migrate through v2 to v3")
	if v1_loaded.ok:
		_expect(int(v1_loaded.data.save_version) == 3, "v1 migration should produce save version three")
		_expect(
			bool(v1_loaded.data.progression.get("migrated_from_v1", false)),
			"v1 migration should mark progression reset"
		)


func _play_current_route_battle(session) -> bool:
	var begun = session.begin_route_battle()
	_expect(begun.ok, "route battle should begin")
	if not begun.ok:
		return false
	for _round_index in range(16):
		var outcome := _play_battle_to_end(session)
		if not outcome.is_empty():
			return outcome == "victory"
	return false


func _play_battle_to_end(session) -> String:
	for _action_index in range(60):
		var snapshot: BattleSnapshot = session.get_battle_snapshot()
		if snapshot == null:
			return ""
		var outcome := String(snapshot.data.get("outcome", ""))
		if not outcome.is_empty():
			return outcome
		var acted := false
		var target_id := _first_alive_enemy(snapshot.data)
		for card_value in snapshot.data.get("hand", []):
			var card: Dictionary = card_value
			var instance_id := StringName(card.get("instance_id", ""))
			var target := target_id if String(card.get("target_type", "")) == "enemy" else &""
			if not session.query_card_play(instance_id, target).playable:
				continue
			var result: BattleCommandResult = session.submit_battle(
				BattleCommandScript.play_card(instance_id, target)
			)
			acted = result.accepted
			if acted:
				break
		if not acted:
			var end_result: BattleCommandResult = session.submit_battle(
				BattleCommandScript.end_turn()
			)
			if not end_result.accepted:
				return ""
	return ""


func _claim_reward(session) -> bool:
	var snapshot: ProgressionSnapshot = session.get_progression_snapshot()
	var rewards: Array = snapshot.data.get("reward_options", [])
	if rewards.is_empty():
		_expect(false, "victory should expose a reward option")
		return false
	var result: ProgressionCommandResult = session.submit_progression(
		ProgressionCommandScript.claim_reward(
			StringName(rewards[0].get("id", ""))
		)
	)
	return result.accepted


func _first_alive_enemy(snapshot: Dictionary) -> StringName:
	for enemy_value in snapshot.get("enemies", []):
		if enemy_value is Dictionary and int(enemy_value.get("hp", 0)) > 0:
			return StringName(enemy_value.get("actor_id", ""))
	return &""


func _route_paths() -> Dictionary:
	return {
		"cards": "res://data/cards/v0.3.0/cards.json",
		"cards_schema": "res://data/schema/v0.3.0/cards.schema.json",
		"enemies": "res://data/enemies/v0.5.0/enemies.json",
		"enemies_schema": "res://data/schema/v0.5.0/enemies.schema.json",
		"encounters": "res://data/encounters/v0.5.0/encounters.json",
		"encounters_schema": "res://data/schema/v0.5.0/encounters.schema.json",
		"routes": "res://data/routes/v0.5.0/routes.json",
		"routes_schema": "res://data/schema/v0.5.0/routes.schema.json",
		"rituals": "res://data/rituals/v0.5.0/rituals.json",
		"rituals_schema": "res://data/schema/v0.5.0/rituals.schema.json",
		"balance": "res://data/balance/v0.5.0/balance.json",
		"balance_schema": "res://data/schema/v0.5.0/balance.schema.json",
		"progression": "res://data/cards/v0.4.0/progression.json",
		"progression_schema": "res://data/schema/v0.4.0/progression.schema.json",
		"save_directory": SAVE_DIRECTORY,
	}


func _write_and_load(
	service: AtomicSaveService,
	slot: String,
	document: Dictionary
) -> InfrastructureResult:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(service.directory)
	)
	var path := service.get_slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "migration fixture should be writable")
		return InfrastructureResult.failure(&"write_failed", "fixture write failed")
	file.store_string(JSON.stringify(document, "  ", true, true))
	file.close()
	return service.load_slot(slot)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
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
