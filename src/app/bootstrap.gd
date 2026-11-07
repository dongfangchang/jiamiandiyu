class_name AppBootstrap
extends RefCounted

const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")
const JsonDocumentLoaderScript := preload("res://src/infrastructure/json_document_loader.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")
const CampaignContentCatalogScript := preload("res://src/infrastructure/campaign_content_catalog.gd")
const ProgressionContentAdapterScript := preload("res://src/infrastructure/progression_content_adapter.gd")
const SaveMigrationsScript := preload("res://src/infrastructure/save_migrations.gd")
const GameSessionScript := preload("res://src/app/game_session.gd")
const CampaignSessionScript := preload("res://src/app/campaign_session.gd")

const DEFAULT_CARDS_PATH := "res://data/cards/v0.3.0/cards.json"
const DEFAULT_CARDS_SCHEMA_PATH := "res://data/schema/v0.3.0/cards.schema.json"
const DEFAULT_ENEMIES_PATH := "res://data/enemies/v0.3.0/enemies.json"
const DEFAULT_ENEMIES_SCHEMA_PATH := "res://data/schema/v0.3.0/enemies.schema.json"
const DEFAULT_ENCOUNTERS_PATH := "res://data/encounters/v0.3.0/encounters.json"
const DEFAULT_ENCOUNTERS_SCHEMA_PATH := "res://data/schema/v0.3.0/encounters.schema.json"
const DEFAULT_BALANCE_PATH := "res://data/balance/v0.3.0/balance.json"
const DEFAULT_BALANCE_SCHEMA_PATH := "res://data/schema/v0.3.0/balance.schema.json"
const DEFAULT_V04_BALANCE_PATH := "res://data/balance/v0.4.0/balance.json"
const DEFAULT_V04_BALANCE_SCHEMA_PATH := "res://data/schema/v0.4.0/balance.schema.json"
const DEFAULT_PROGRESSION_PATH := "res://data/cards/v0.4.0/progression.json"
const DEFAULT_PROGRESSION_SCHEMA_PATH := "res://data/schema/v0.4.0/progression.schema.json"


static func create_services(run_seed: int) -> AppServices:
	return AppServices.new(SeededRandomService.new(run_seed))


static func load_battle_ports(
	run_seed: int,
	content_path: String,
	content_schema_path: String,
	balance_path: String,
	balance_schema_path: String,
	random_stream_name: StringName = &"battle.shuffle"
) -> InfrastructureResult:
	var loader := JsonDocumentLoaderScript.new()
	var content_loaded := loader.load_document(content_path, content_schema_path)
	if not content_loaded.ok:
		return content_loaded
	var cards: Variant = content_loaded.data.get("cards")
	if not cards is Array:
		return InfrastructureResultScript.failure(
			&"content_cards_missing",
			"Validated content document must contain a cards array.",
			{"source": content_path}
		)

	var balance_loaded := loader.load_document(balance_path, balance_schema_path)
	if not balance_loaded.ok:
		return balance_loaded

	var services := create_services(run_seed)
	return InfrastructureResultScript.success({
		"services": services,
		"content": BattleContentAdapterScript.new(cards),
		"balance": BattleBalanceAdapterScript.new(balance_loaded.data),
		"random": services.create_battle_random(random_stream_name),
	})


static func load_campaign_ports(run_seed: int, paths: Dictionary = {}) -> InfrastructureResult:
	var loader := JsonDocumentLoaderScript.new()
	var cards_result := loader.load_document(
		String(paths.get("cards", DEFAULT_CARDS_PATH)),
		String(paths.get("cards_schema", DEFAULT_CARDS_SCHEMA_PATH))
	)
	if not cards_result.ok:
		return _with_stage(cards_result, &"cards")
	var enemies_result := loader.load_document(
		String(paths.get("enemies", DEFAULT_ENEMIES_PATH)),
		String(paths.get("enemies_schema", DEFAULT_ENEMIES_SCHEMA_PATH))
	)
	if not enemies_result.ok:
		return _with_stage(enemies_result, &"enemies")
	var encounters_result := loader.load_document(
		String(paths.get("encounters", DEFAULT_ENCOUNTERS_PATH)),
		String(paths.get("encounters_schema", DEFAULT_ENCOUNTERS_SCHEMA_PATH))
	)
	if not encounters_result.ok:
		return _with_stage(encounters_result, &"encounters")
	var balance_result := loader.load_document(
		String(paths.get("balance", DEFAULT_BALANCE_PATH)),
		String(paths.get("balance_schema", DEFAULT_BALANCE_SCHEMA_PATH))
	)
	if not balance_result.ok:
		return _with_stage(balance_result, &"balance")

	var catalog := CampaignContentCatalogScript.new()
	var catalog_result := catalog.load_from_documents(
		cards_result.data,
		enemies_result.data,
		encounters_result.data
	)
	if not catalog_result.ok:
		return _with_stage(catalog_result, &"catalog")
	var balance_version := String(balance_result.data.get("content_version", ""))
	if balance_version != catalog.content_version:
		return InfrastructureResultScript.failure(
			&"balance_content_version_mismatch",
			"Global balance and campaign content must use the same content_version.",
			{
				"stage": "balance",
				"balance_version": balance_version,
				"content_version": catalog.content_version,
			}
		)

	var services := create_services(run_seed)
	var save_directory := String(paths.get("save_directory", AtomicSaveService.DEFAULT_DIRECTORY))
	services.saves = AtomicSaveService.new(save_directory)
	services.catalog = catalog
	return InfrastructureResultScript.success({
		"services": services,
		"catalog": catalog,
		"content": BattleContentAdapterScript.new(cards_result.data.get("cards", [])),
		"balance": BattleBalanceAdapterScript.new(balance_result.data),
		"random": services.create_battle_random(&"battle.shuffle"),
	})


static func start_new_game(
	run_seed: int,
	encounter_id: StringName = &"",
	paths: Dictionary = {},
	checkpoint_slot: String = "checkpoint"
) -> InfrastructureResult:
	var ports_result := load_campaign_ports(run_seed, paths)
	if not ports_result.ok:
		return ports_result
	var catalog: RefCounted = ports_result.data.catalog
	var selected_id := encounter_id
	if selected_id.is_empty():
		selected_id = StringName(catalog.default_encounter_id())
	if selected_id.is_empty():
		return InfrastructureResultScript.failure(
			&"default_encounter_missing",
			"Campaign content does not define a default encounter."
		)
	var session := GameSessionScript.new(
		ports_result.data.services,
		catalog,
		ports_result.data.content,
		ports_result.data.balance,
		ports_result.data.random,
		run_seed,
		selected_id,
		checkpoint_slot
	)
	if not session.is_ready():
		var snapshot_data: Dictionary = session.get_snapshot().to_dictionary()
		return InfrastructureResultScript.failure(
			&"battle_initialization_failed",
			"Formal content could not initialize the first battle.",
			{
				"encounter_id": String(selected_id),
				"reason_code": String(snapshot_data.get("outcome_reason", "")),
				"snapshot": snapshot_data,
			}
		)
	return InfrastructureResultScript.success(session, {"encounter_id": String(selected_id)})


static func start_campaign(
	run_seed: int,
	encounter_id: StringName = &"",
	paths: Dictionary = {},
	checkpoint_slot: String = "checkpoint",
	resume_from_checkpoint: bool = false
) -> InfrastructureResult:
	var loader := JsonDocumentLoaderScript.new()
	var cards_result := loader.load_document(
		String(paths.get("cards", DEFAULT_CARDS_PATH)),
		String(paths.get("cards_schema", DEFAULT_CARDS_SCHEMA_PATH))
	)
	if not cards_result.ok:
		return _with_stage(cards_result, &"cards")
	var enemies_result := loader.load_document(
		String(paths.get("enemies", DEFAULT_ENEMIES_PATH)),
		String(paths.get("enemies_schema", DEFAULT_ENEMIES_SCHEMA_PATH))
	)
	if not enemies_result.ok:
		return _with_stage(enemies_result, &"enemies")
	var encounters_result := loader.load_document(
		String(paths.get("encounters", DEFAULT_ENCOUNTERS_PATH)),
		String(paths.get("encounters_schema", DEFAULT_ENCOUNTERS_SCHEMA_PATH))
	)
	if not encounters_result.ok:
		return _with_stage(encounters_result, &"encounters")
	var balance_result := loader.load_document(
		String(paths.get("balance", DEFAULT_V04_BALANCE_PATH)),
		String(paths.get("balance_schema", DEFAULT_V04_BALANCE_SCHEMA_PATH))
	)
	if not balance_result.ok:
		return _with_stage(balance_result, &"balance")
	var progression_result := loader.load_document(
		String(paths.get("progression", DEFAULT_PROGRESSION_PATH)),
		String(paths.get("progression_schema", DEFAULT_PROGRESSION_SCHEMA_PATH))
	)
	if not progression_result.ok:
		return _with_stage(progression_result, &"progression")

	var catalog := CampaignContentCatalogScript.new()
	var catalog_result := catalog.load_from_documents(
		cards_result.data,
		enemies_result.data,
		encounters_result.data
	)
	if not catalog_result.ok:
		return _with_stage(catalog_result, &"catalog")
	var progression_version := String(
		progression_result.data.get("content_version", "")
	)
	var balance_version := String(balance_result.data.get("content_version", ""))
	if progression_version != balance_version:
		return InfrastructureResultScript.failure(
			&"progression_content_version_mismatch",
			"Progression content and global balance must share content_version.",
			{
				"progression_version": progression_version,
				"balance_version": balance_version,
			}
		)
	var base_cards_version := String(
		progression_result.data.get("base_cards_version", "")
	)
	if base_cards_version != catalog.content_version:
		return InfrastructureResultScript.failure(
			&"progression_base_cards_version_mismatch",
			"Progression content must reference the loaded base card version.",
			{
				"base_cards_version": base_cards_version,
				"catalog_version": catalog.content_version,
			}
		)

	var battle_content: BattleContentPort = BattleContentAdapterScript.new(
		cards_result.data.get("cards", [])
	)
	var global_balance: BattleBalancePort = BattleBalanceAdapterScript.new(
		balance_result.data
	)
	var progression_content: ProgressionContentPort = (
		ProgressionContentAdapterScript.new(
			progression_result.data,
			battle_content
		)
	)

	var save_directory := String(
		paths.get("save_directory", AtomicSaveService.DEFAULT_DIRECTORY)
	)
	var save_service := SaveMigrationsScript.create_v04_service(save_directory)
	var selected_seed := run_seed
	var selected_encounter := encounter_id
	var progression_state: Dictionary = {}

	if resume_from_checkpoint:
		var loaded := save_service.load_slot(checkpoint_slot)
		if not loaded.ok:
			return InfrastructureResultScript.failure(
				&"campaign_checkpoint_unavailable",
				"Campaign checkpoint could not be loaded.",
				{
					"cause": String(loaded.code),
					"cause_message": loaded.message,
					"cause_details": loaded.details,
				}
			)
		var envelope: Dictionary = loaded.data
		selected_seed = int(envelope.get("rng_seed", run_seed))
		var run_data: Dictionary = envelope.get("run", {})
		var saved_encounter := String(run_data.get("encounter_id", ""))
		if not saved_encounter.is_empty():
			selected_encounter = StringName(saved_encounter)
		var saved_progression: Variant = envelope.get("progression", {})
		if saved_progression is Dictionary:
			progression_state = saved_progression.duplicate(true)
		if bool(progression_state.get("migrated_from_v1", false)):
			progression_state = {}

	if selected_encounter.is_empty():
		selected_encounter = StringName(catalog.default_encounter_id())
	if selected_encounter.is_empty() or not catalog.has_encounter(selected_encounter):
		return InfrastructureResultScript.failure(
			&"campaign_encounter_invalid",
			"Campaign encounter is missing or unknown.",
			{"encounter_id": String(selected_encounter)}
		)

	var services := create_services(selected_seed)
	services.saves = save_service
	services.catalog = catalog
	var progression_engine := ProgressionEngine.new(
		progression_content,
		global_balance,
		services.create_battle_random(&"gacha.draw")
	)
	var initialized := progression_engine.initialize(progression_state)
	if not initialized.accepted:
		return InfrastructureResultScript.failure(
			&"progression_initialization_failed",
			"Persistent progression could not be initialized.",
			{
				"reason_code": String(initialized.reason_code),
				"snapshot": initialized.snapshot.to_dictionary(),
			}
		)

	var campaign := CampaignSessionScript.new(
		services,
		catalog,
		battle_content,
		global_balance,
		progression_content,
		progression_engine,
		selected_seed,
		selected_encounter,
		checkpoint_slot
	)
	return InfrastructureResultScript.success(
		campaign,
		{
			"encounter_id": String(selected_encounter),
			"resumed": resume_from_checkpoint,
		}
	)


static func inspect_checkpoint(
	save_slot: String = "checkpoint",
	save_directory: String = AtomicSaveService.DEFAULT_DIRECTORY
) -> InfrastructureResult:
	var service := SaveMigrationsScript.create_v04_service(save_directory)
	var slot_info := service.inspect_slot(save_slot)
	if not slot_info.ok:
		return slot_info
	if not bool(slot_info.data.get("has_save", false)):
		return InfrastructureResultScript.success({
			"status": "none",
			"checkpoint": null,
			"backup_available": bool(slot_info.data.get("has_backup", false)),
		})
	var loaded := service.load_slot(save_slot)
	if not loaded.ok:
		return InfrastructureResultScript.success({
			"status": "corrupt",
			"checkpoint": null,
			"error_code": String(loaded.code),
			"message": loaded.message,
			"backup_available": bool(loaded.details.get("backup_available", false)),
		})
	return InfrastructureResultScript.success({
		"status": "loaded",
		"checkpoint": _checkpoint_summary(loaded.data),
		"backup_available": bool(slot_info.data.get("has_backup", false)),
	})


static func checkpoint_summary(envelope: Dictionary) -> Dictionary:
	return _checkpoint_summary(envelope)


static func _checkpoint_summary(envelope: Dictionary) -> Dictionary:
	var profile: Dictionary = envelope.get("profile", {})
	var run: Dictionary = envelope.get("run", {})
	var progression: Dictionary = envelope.get("progression", {})
	var last_battle: Dictionary = run.get("last_battle", {})
	var deck_summary: Dictionary = run.get("deck_summary", {})
	var deck_size := 0
	for count in deck_summary.values():
		deck_size += int(count)
	return {
		"content_version": String(envelope.get("content_version", "")),
		"created_at": String(envelope.get("created_at", "")),
		"rng_seed": int(envelope.get("rng_seed", 0)),
		"pathway": String(profile.get("pathway", "")),
		"sequence": int(profile.get("sequence", 0)),
		"identity_id": String(
			profile.get(
				"identity_id",
				progression.get("identity_id", "")
			)
		),
		"progression_phase": String(progression.get("phase", "")),
		"divination_tickets": int(progression.get("divination_tickets", 0)),
		"checkpoint_kind": String(run.get("checkpoint_kind", "")),
		"encounter_id": String(run.get("encounter_id", "")),
		"deck_size": deck_size,
		"last_battle": last_battle.duplicate(true),
	}


static func _with_stage(result: InfrastructureResult, stage: StringName) -> InfrastructureResult:
	if result.ok:
		return result
	var details := result.details.duplicate(true)
	details["stage"] = String(stage)
	return InfrastructureResultScript.failure(result.code, result.message, details)
