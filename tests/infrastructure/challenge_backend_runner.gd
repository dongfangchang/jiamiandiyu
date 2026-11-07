extends Node

const JsonDocumentLoaderScript := preload("res://src/infrastructure/json_document_loader.gd")
const SchemaValidatorScript := preload("res://src/infrastructure/schema_validator.gd")
const ChallengeContentAdapterScript := preload("res://src/infrastructure/challenge_content_adapter.gd")
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const ChallengeSessionScript := preload("res://src/app/challenge_session.gd")
const ChallengeCommandScript := preload("res://src/core/challenge_command.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")

const TEST_ROOT := "user://mask_whispers_challenge_backend_v06"
const SAVE_DIRECTORY := "user://mask_whispers_challenge_backend_v06/saves"
const SLOT := "challenge_checkpoint"
const CHALLENGE_PATH := "res://data/challenges/v0.6.0/challenges.json"
const CHALLENGE_SCHEMA := "res://data/schema/v0.6.0/challenges.schema.json"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_remove_tree(TEST_ROOT)
	_test_challenge_schema_and_adapter()
	_test_adapter_rejects_bad_references()
	_test_start_challenge_without_progress_is_locked()
	_test_challenge_session_and_resume()
	_test_challenge_reward_application_once()
	_test_challenge_reward_recovery_and_save_failure()
	_test_v3_to_v4_migration()
	_remove_tree(TEST_ROOT)
	if _failures.is_empty():
		print("CHALLENGE_BACKEND_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("CHALLENGE_BACKEND_FAIL %s" % failure)
	printerr(
		"CHALLENGE_BACKEND_FAILED checks=%d failures=%d"
		% [_checks, _failures.size()]
	)
	get_tree().quit(1)


func _test_challenge_schema_and_adapter() -> void:
	var base: Variant = _start_base_route("schema_base")
	if base == null:
		return
	var loaded := _load_challenge_document()
	_expect(loaded.ok, "formal challenge content should satisfy its schema")
	if not loaded.ok:
		return
	var adapter := ChallengeContentAdapterScript.new(
		loaded.data,
		base.catalog,
		base.route_content,
		base.progression_content
	)
	_expect(adapter.is_valid(), "formal challenge adapter should be valid")
	_expect(
		String(adapter.get_default_challenge_id())
		== "challenge.v060.mirror_echoes",
		"default challenge should be stable"
	)
	var challenge := adapter.get_challenge(
		&"challenge.v060.mirror_echoes"
	)
	_expect(
		challenge.get("modifiers", []).size() == 3,
		"formal challenge should expose three modifiers"
	)
	var tainted_modifier := _find_modifier(
		challenge,
		"modifier.tainted_margins"
	)
	var tainted_effects: Dictionary = tainted_modifier.get("effects", {})
	_expect(
		int(tainted_effects.get("battle_corruption_delta", 0)) == 2,
		"tainted margins should expose its post-battle corruption pressure"
	)


func _test_adapter_rejects_bad_references() -> void:
	var base: Variant = _start_base_route("bad_refs")
	if base == null:
		return
	var loaded := _load_challenge_document()
	if not loaded.ok:
		_expect(false, "valid challenge document is required")
		return

	var missing_route: Dictionary = loaded.data.duplicate(true)
	missing_route.challenges[0].route_id = "route.missing"
	_expect(
		not ChallengeContentAdapterScript.new(
			missing_route,
			base.catalog,
			base.route_content,
			base.progression_content
		).is_valid(),
		"challenge adapter should reject a missing route"
	)

	var duplicate_modifier: Dictionary = loaded.data.duplicate(true)
	duplicate_modifier.challenges[0].modifiers[1].id = (
		duplicate_modifier.challenges[0].modifiers[0].id
	)
	_expect(
		not ChallengeContentAdapterScript.new(
			duplicate_modifier,
			base.catalog,
			base.route_content,
			base.progression_content
		).is_valid(),
		"challenge adapter should reject duplicate modifier ids"
	)

	var unknown_reward: Dictionary = loaded.data.duplicate(true)
	unknown_reward.challenges[0].completion_reward["reward.missing"] = 1
	_expect(
		not ChallengeContentAdapterScript.new(
			unknown_reward,
			base.catalog,
			base.route_content,
			base.progression_content
		).is_valid(),
		"challenge adapter should reject unknown reward ids"
	)

	var missing_removed_card: Dictionary = loaded.data.duplicate(true)
	missing_removed_card.challenges[0].modifiers[2].effects[
		"remove_definition_ids"
	].append("card.skill.missing")
	_expect(
		not ChallengeContentAdapterScript.new(
			missing_removed_card,
			base.catalog,
			base.route_content,
			base.progression_content
		).is_valid(),
		"challenge adapter should reject removed cards outside the route"
	)

	var invalid_battle_corruption: Dictionary = loaded.data.duplicate(true)
	invalid_battle_corruption.challenges[0].modifiers[1].effects[
		"battle_corruption_delta"
	] = "2"
	_expect(
		not ChallengeContentAdapterScript.new(
			invalid_battle_corruption,
			base.catalog,
			base.route_content,
			base.progression_content
		).is_valid(),
		"challenge adapter should reject non-integer battle corruption deltas"
	)

	var out_of_range_battle_corruption: Dictionary = loaded.data.duplicate(true)
	out_of_range_battle_corruption.challenges[0].modifiers[1].effects[
		"battle_corruption_delta"
	] = 11
	_expect(
		not SchemaValidatorScript.new().validate_document(
			out_of_range_battle_corruption,
			CHALLENGE_SCHEMA
		).ok,
		"challenge schema should reject battle corruption deltas above ten"
	)

	var missing_battle_corruption: Dictionary = loaded.data.duplicate(true)
	missing_battle_corruption.challenges[0].modifiers[1].effects.erase(
		"battle_corruption_delta"
	)
	_expect(
		ChallengeContentAdapterScript.new(
			missing_battle_corruption,
			base.catalog,
			base.route_content,
			base.progression_content
		).is_valid(),
		"challenge content should remain compatible when battle corruption is omitted"
	)


func _test_challenge_session_and_resume() -> void:
	var session_directory := TEST_ROOT.path_join("session")
	var base: Variant = _start_base_route("session")
	if base == null:
		return
	var selected_identity: ProgressionCommandResult = base.submit_progression(
		ProgressionCommandScript.select_identity(&"identity.doctor")
	)
	_expect(selected_identity.accepted, "challenge setup should reach the hub")
	var loaded := _load_challenge_document()
	if not loaded.ok:
		return
	var adapter := ChallengeContentAdapterScript.new(
		loaded.data,
		base.catalog,
		base.route_content,
		base.progression_content
	)
	var sequence := _sequence(8, "completed")
	var session := ChallengeSessionScript.new(
		base.services,
		base.catalog,
		base.base_content,
		base.balance,
		base.progression_content,
		base.progression,
		base.route_content,
		adapter,
		adapter.get_default_challenge_id(),
		sequence,
		base.root_seed,
		SLOT
	)
	var initialized := session.initialize()
	_expect(initialized.ok, "challenge session should initialize")
	_expect(
		bool(session.get_challenge_snapshot().data.get("unlocked", false)),
		"sequence eight should unlock the challenge session"
	)
	var selected := session.submit_challenge(
		ChallengeCommandScript.select_modifier(&"modifier.fractured_deck")
	)
	_expect(selected.accepted, "challenge modifier should be selectable")
	var started := session.submit_challenge(
		ChallengeCommandScript.start_challenge()
	)
	_expect(started.accepted, "challenge should start")
	var begun := session.begin_challenge_battle()
	_expect(begun.ok, "first challenge battle should initialize")
	if begun.ok:
		var deck: Array[String] = session.get_battle_session().get_deck_definition_ids()
		_expect(
			not "card.skill.paper_guard" in deck,
			"challenge deck transform should remove restricted cards"
		)
		_expect(not deck.is_empty(), "challenge battle should retain a valid deck")

	var inspected := AppBootstrapScript.inspect_route_checkpoint(
		SLOT,
		session_directory
	)
	_expect(inspected.ok, "challenge checkpoint should be inspectable")
	if inspected.ok and inspected.data.status == "loaded":
		_expect(
			inspected.data.checkpoint.get("challenge_phase", "")
			== "active",
			"checkpoint summary should expose active challenge phase"
		)

	var resume_paths := _challenge_paths()
	resume_paths["save_directory"] = session_directory
	var resumed := AppBootstrapScript.start_challenge(
		0,
		resume_paths,
		SLOT,
		true
	)
	if not resumed.ok:
		print(
			"CHALLENGE_RESUME_FAILED code=%s message=%s details=%s"
			% [resumed.code, resumed.message, resumed.details]
		)
	_expect(resumed.ok, "challenge should resume from a v4 checkpoint")
	if resumed.ok:
		var resumed_session = resumed.data
		_expect(
			resumed_session.get_challenge_snapshot().data.get(
				"selected_modifier_id",
				""
			) == "modifier.fractured_deck",
			"challenge resume should preserve the selected modifier"
		)
		_expect(
			resumed_session.get_challenge_snapshot().data.get("phase", "")
			== "active",
			"challenge resume should restore the active phase"
		)
		_expect(
			resumed_session.get_route_snapshot().data.get("phase", "")
			== "map",
			"challenge resume should return to the last node boundary"
		)

	var locked_session := ChallengeSessionScript.new(
		base.services,
		base.catalog,
		base.base_content,
		base.balance,
		base.progression_content,
		base.progression,
		base.route_content,
		adapter,
		adapter.get_default_challenge_id(),
		_sequence(9, "locked"),
		base.root_seed,
		"locked_checkpoint"
	)
	_expect(locked_session.initialize().ok, "locked challenge should initialize")
	_expect(
		locked_session.get_challenge_snapshot().data.get("phase", "")
		== "locked",
		"sequence nine should keep the challenge locked"
	)


func _test_start_challenge_without_progress_is_locked() -> void:
	var paths := _challenge_paths()
	paths["save_directory"] = TEST_ROOT.path_join("fresh")
	var started := AppBootstrapScript.start_challenge(
		20261108,
		paths,
		"fresh_checkpoint",
		false
	)
	_expect(started.ok, "challenge entry should initialize without an existing save")
	if started.ok:
		_expect(
			not bool(
				started.data.get_challenge_snapshot().data.get(
					"unlocked",
					true
				)
			),
			"a fresh save must not bypass the sequence eight unlock"
		)


func _test_challenge_reward_application_once() -> void:
	var label := "challenge_rewards"
	var base: Variant = _start_base_route(label)
	if base == null:
		return
	var selected_identity: ProgressionCommandResult = base.submit_progression(
		ProgressionCommandScript.select_identity(&"identity.doctor")
	)
	_expect(selected_identity.accepted, "reward test should reach the hub")
	var challenge_adapter := _challenge_adapter(base)
	if challenge_adapter == null:
		return
	var session := _new_challenge_session(
		base,
		challenge_adapter,
		_sequence(8, "completed"),
		SLOT
	)
	_expect(session.initialize().ok, "reward challenge should initialize")
	_expect(
		session.submit_challenge(
			ChallengeCommandScript.select_modifier(
				&"modifier.rushed_reflection"
			)
		).accepted,
		"reward challenge modifier should select"
	)
	_expect(
		session.submit_challenge(ChallengeCommandScript.start_challenge()).accepted,
		"reward challenge should start"
	)
	var before := session.progression.export_persistent_state()
	var completion := _complete_challenge_session(session)
	_expect(completion.accepted, "challenge completion should be accepted")
	_expect(
		completion.snapshot.data.get("phase", "") == "completed",
		"challenge should enter completed phase"
	)
	var after := session.progression.export_persistent_state()
	_expect(
		int(after.get("divination_tickets", 0))
		- int(before.get("divination_tickets", 0)) == 2,
		"challenge tickets should be granted exactly once"
	)
	_expect(
		_fragments_for(after, "card.skill.ink_dart")
		- _fragments_for(before, "card.skill.ink_dart") == 4,
		"challenge fragments should be granted exactly once"
	)

	var duplicate := session.submit_route(
		RouteCommandScript.submit_ritual_step(["seal.inverted_eye"])
	)
	_expect(
		not duplicate.accepted,
		"completed challenge should reject repeated route commands"
	)
	_expect(
		session.apply_pending_challenge_reward(),
		"already-applied reward should remain claimed"
	)
	var repeated := session.progression.export_persistent_state()
	_expect(
		int(repeated.get("divination_tickets", 0))
		== int(after.get("divination_tickets", 0)),
		"repeated completion must not grant tickets again"
	)
	_expect(
		_fragments_for(repeated, "card.skill.ink_dart")
		== _fragments_for(after, "card.skill.ink_dart"),
		"repeated completion must not grant fragments again"
	)


func _test_challenge_reward_recovery_and_save_failure() -> void:
	var label := "challenge_reward_recovery"
	var base: Variant = _start_base_route(label)
	if base == null:
		return
	var selected_identity: ProgressionCommandResult = base.submit_progression(
		ProgressionCommandScript.select_identity(&"identity.reporter")
	)
	_expect(selected_identity.accepted, "recovery test should reach the hub")
	var challenge_adapter := _challenge_adapter(base)
	if challenge_adapter == null:
		return
	var session := _new_challenge_session(
		base,
		challenge_adapter,
		_sequence(8, "completed"),
		SLOT
	)
	_expect(session.initialize().ok, "recovery challenge should initialize")
	_expect(
		session.submit_challenge(
			ChallengeCommandScript.select_modifier(
				&"modifier.rushed_reflection"
			)
		).accepted,
		"recovery challenge modifier should select"
	)
	_expect(
		session.submit_challenge(ChallengeCommandScript.start_challenge()).accepted,
		"recovery challenge should start"
	)
	var before_reward := session.progression.export_persistent_state()
	_expect(
		_complete_challenge_session(session).accepted,
		"recovery challenge should complete"
	)
	var loaded: InfrastructureResult = base.services.saves.load_slot(SLOT)
	_expect(loaded.ok, "completed challenge checkpoint should load")
	if not loaded.ok:
		return
	var recovery_document: Dictionary = loaded.data.duplicate(true)
	recovery_document.progression = before_reward.duplicate(true)
	recovery_document.challenge.reward_applied = false
	_expect(
		base.services.saves.save_slot(SLOT, recovery_document).ok,
		"completed checkpoint fixture should save for recovery test"
	)
	var resume_paths := _challenge_paths()
	resume_paths["save_directory"] = base.services.saves.directory
	var recovered := AppBootstrapScript.start_challenge(
		0,
		resume_paths,
		SLOT,
		true
	)
	_expect(recovered.ok, "completed challenge should recover")
	if not recovered.ok:
		return
	var recovered_session = recovered.data
	var recovered_state: Dictionary = (
		recovered_session.progression.export_persistent_state()
	)
	_expect(
		int(recovered_state.get("divination_tickets", 0))
		- int(before_reward.get("divination_tickets", 0)) == 2,
		"completed checkpoint should recover the reward once"
	)
	_expect(
		recovered_session.apply_pending_challenge_reward(),
		"recovered reward should be marked as applied"
	)
	var reloaded := AppBootstrapScript.start_challenge(
		0,
		resume_paths,
		SLOT,
		true
	)
	_expect(reloaded.ok, "reward-applied checkpoint should reload")
	if reloaded.ok:
		_expect(
			int(
				reloaded.data.progression.export_persistent_state().get(
					"divination_tickets",
					0
				)
			) == int(recovered_state.get("divination_tickets", 0)),
			"recovery must not repeat on the next restart"
		)

	var failed_save_session := _new_challenge_session(
		base,
		challenge_adapter,
		_sequence(8, "completed"),
		"../invalid_challenge_slot"
	)
	_expect(
		failed_save_session.initialize().ok,
		"failed-save challenge should initialize"
	)
	_expect(
		failed_save_session.submit_challenge(
			ChallengeCommandScript.select_modifier(
				&"modifier.rushed_reflection"
			)
		).accepted,
		"failed-save challenge modifier should select"
	)
	_expect(
		failed_save_session.submit_challenge(
			ChallengeCommandScript.start_challenge()
		).accepted,
		"failed-save challenge should start"
	)
	_expect(
		_complete_challenge_session(failed_save_session).accepted,
		"failed-save challenge should still complete in memory"
	)
	_expect(
		failed_save_session.last_checkpoint_result != null
		and not failed_save_session.last_checkpoint_result.ok,
		"challenge must not report a failed checkpoint as saved"
	)


func _test_v3_to_v4_migration() -> void:
	var directory := TEST_ROOT.path_join("migrations_v3")
	var service := SaveMigrationsScript.create_v06_service(directory)
	var v3 := {
		"save_version": 3,
		"content_version": "v0.5.0",
		"created_at": "2026-11-08T00:00:00Z",
		"rng_seed": 303,
		"profile": {"pathway": "seer", "sequence": 8, "identity_id": "identity.doctor"},
		"run": {"checkpoint_kind": "route_post_battle"},
		"collection": {},
		"progression": _minimal_progression(),
		"route": {
			"initialized": true,
			"route_id": "route.v050.first_case",
			"phase": "completed",
			"run_state": {
				"hp": 50,
				"max_hp": 54,
				"spirit": 3,
				"max_spirit": 3,
				"corruption": 0,
				"max_corruption": 10,
				"attention": 0,
				"max_attention": 10,
			},
			"completed_node_ids": [],
			"sequence_state": "completed",
			"state": {},
		},
	}
	var loaded := _write_and_load(service, "legacy_v3", v3)
	_expect(loaded.ok, "v3 save should migrate to v4")
	if loaded.ok:
		_expect(int(loaded.data.save_version) == 4, "migration should produce save version four")
		_expect(
			loaded.data.challenge.phase == "inactive",
			"v3 migration should create an inactive challenge section"
		)
		_expect(
			bool(loaded.data.challenge.get("migrated_from_v3", false)),
			"v3 migration should mark the added challenge section"
		)
		var resaved := service.save_slot("legacy_v3", loaded.data)
		_expect(
			resaved.ok,
			"writing v4 over a migrated v3 save should preserve a valid backup"
		)
		var backup := service.load_backup("legacy_v3")
		_expect(
			backup.ok and int(backup.data.save_version) == 4,
			"v3 backup should be readable through the migration chain"
		)


func _start_base_route(label: String):
	var paths := _challenge_paths()
	paths["save_directory"] = TEST_ROOT.path_join(label)
	var result = AppBootstrapScript.start_route(
		20261108,
		paths,
		"base_checkpoint",
		false
	)
	if not result.ok:
		_expect(false, "base route should start for %s: %s" % [label, result.code])
		return null
	return result.data


func _challenge_adapter(base: Variant) -> ChallengeContentAdapter:
	var loaded := _load_challenge_document()
	if not loaded.ok:
		_expect(false, "challenge fixture should load")
		return null
	return ChallengeContentAdapterScript.new(
		loaded.data,
		base.catalog,
		base.route_content,
		base.progression_content
	)


func _find_modifier(challenge: Dictionary, modifier_id: String) -> Dictionary:
	for value in challenge.get("modifiers", []):
		if value is Dictionary and String(value.get("id", "")) == modifier_id:
			return value
	return {}


func _new_challenge_session(
	base: Variant,
	challenge_adapter: ChallengeContentAdapter,
	sequence: Dictionary,
	slot: String
) -> ChallengeSession:
	return ChallengeSessionScript.new(
		base.services,
		base.catalog,
		base.base_content,
		base.balance,
		base.progression_content,
		base.progression,
		base.route_content,
		challenge_adapter,
		challenge_adapter.get_default_challenge_id(),
		sequence,
		base.root_seed,
		slot
	)


func _complete_challenge_session(
	session: ChallengeSession
) -> ChallengeCommandResult:
	session.submit_route(
		RouteCommandScript.select_node(&"route.v050.node.first_hunt")
	)
	session.submit_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.first_hunt",
			&"victory",
			{"hp": 49, "corruption": 1, "attention": 1, "spirit": 3}
		)
	)
	session.submit_route(
		RouteCommandScript.select_node(&"route.v050.node.mirror_pursuit")
	)
	session.submit_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.mirror_pursuit",
			&"victory",
			{"hp": 35, "corruption": 2, "attention": 2, "spirit": 2}
		)
	)
	session.submit_route(
		RouteCommandScript.select_node(&"route.v050.node.old_house_rest")
	)
	session.submit_route(RouteCommandScript.use_rest(&"rest.bandage"))
	session.submit_route(
		RouteCommandScript.select_node(&"route.v050.node.mirror_baron")
	)
	session.submit_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.mirror_baron",
			&"victory",
			{"hp": 20, "corruption": 4, "attention": 3, "spirit": 3}
		)
	)
	session.submit_route(RouteCommandScript.begin_ascension())
	session.submit_route(
		RouteCommandScript.submit_ritual_step([
			"name.elin_ward",
			"name.thomas_ward",
		])
	)
	session.submit_route(
		RouteCommandScript.submit_ritual_step([
			"event.birth",
			"event.death",
			"event.burial",
		])
	)
	return session.submit_route(
		RouteCommandScript.submit_ritual_step(["seal.inverted_eye"])
	)


func _fragments_for(state: Dictionary, definition_id: String) -> int:
	var collection_value: Variant = state.get("collection", {})
	if not collection_value is Dictionary:
		return 0
	var card_state_value: Variant = collection_value.get(definition_id, {})
	if not card_state_value is Dictionary:
		return 0
	return int(card_state_value.get("fragments", 0))


func _load_challenge_document() -> InfrastructureResult:
	return JsonDocumentLoaderScript.new().load_document(
		CHALLENGE_PATH,
		CHALLENGE_SCHEMA
	)


func _challenge_paths() -> Dictionary:
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
		"challenges": CHALLENGE_PATH,
		"challenges_schema": CHALLENGE_SCHEMA,
		"save_directory": SAVE_DIRECTORY,
	}


func _sequence(current_sequence: int, advancement_state: String) -> Dictionary:
	return {
		"pathway_id": "seer",
		"pathway_name_zh": "占卜家",
		"current_sequence": current_sequence,
		"next_sequence": 8,
		"next_sequence_name_zh": "小丑",
		"advancement_state": advancement_state,
	}


func _minimal_progression() -> Dictionary:
	return {
		"phase": "hub",
		"identity_id": "identity.doctor",
		"divination_tickets": 3,
		"collection": {
			"card.skill.ink_dart": {"copies": 1, "level": 0, "fragments": 0},
			"card.skill.paper_guard": {"copies": 1, "level": 0, "fragments": 0},
			"card.skill.calm_breath": {"copies": 1, "level": 0, "fragments": 0},
			"card.skill.focus": {"copies": 1, "level": 0, "fragments": 0},
			"card.skill.insight": {"copies": 1, "level": 0, "fragments": 0},
			"card.skill.omen": {"copies": 1, "level": 0, "fragments": 0},
		},
		"pity_counter": 0,
		"reward_option_ids": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
		"revision": 1,
	}


func _write_and_load(
	service: AtomicSaveService,
	slot: String,
	document: Dictionary
) -> InfrastructureResult:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(service.directory)
	)
	var file := FileAccess.open(service.get_slot_path(slot), FileAccess.WRITE)
	if file == null:
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
