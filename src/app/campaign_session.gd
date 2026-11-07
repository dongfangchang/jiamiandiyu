class_name CampaignSession
extends RefCounted

const GameSessionScript := preload("res://src/app/game_session.gd")
const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")

const CONTENT_VERSION := "v0.4.0"
const ENDED_OUTCOMES: Array[String] = ["victory", "defeat"]

var services: AppServices
var catalog: RefCounted
var base_content: BattleContentPort
var balance: BattleBalancePort
var progression_content: ProgressionContentPort
var progression: ProgressionEngine
var root_seed: int
var encounter_id: StringName
var encounter_name: String
var checkpoint_slot: String
var last_checkpoint_result: InfrastructureResult = null

var _battle_session: RefCounted = null
var _last_battle: Dictionary = {}
var _last_checkpoint_kind: String = "progression"


func _init(
	app_services: AppServices,
	content_catalog: RefCounted,
	battle_content: BattleContentPort,
	global_balance: BattleBalancePort,
	progression_content_port: ProgressionContentPort,
	progression_engine: ProgressionEngine,
	run_seed: int,
	selected_encounter_id: StringName,
	save_slot: String
) -> void:
	services = app_services
	catalog = content_catalog
	base_content = battle_content
	balance = global_balance
	progression_content = progression_content_port
	progression = progression_engine
	root_seed = run_seed
	encounter_id = selected_encounter_id
	checkpoint_slot = save_slot
	var resolved: InfrastructureResult = catalog.resolve_encounter(encounter_id)
	if resolved.ok:
		encounter_name = String(
			resolved.data.get("display_name_zh", String(encounter_id))
		)


func is_ready() -> bool:
	if progression == null:
		return false
	var snapshot := progression.get_snapshot()
	if snapshot == null or snapshot.data.is_empty():
		return false
	return String(snapshot.data.get("phase", "")) != "init_error"


func get_progression_snapshot() -> ProgressionSnapshot:
	return progression.get_snapshot()


func get_battle_session() -> RefCounted:
	return _battle_session


func get_battle_snapshot() -> BattleSnapshot:
	if _battle_session == null:
		return null
	return _battle_session.get_snapshot()


func get_last_checkpoint_summary() -> Dictionary:
	return _last_battle.duplicate(true)


func submit_progression(command: ProgressionCommand) -> ProgressionCommandResult:
	var result: ProgressionCommandResult = progression.submit(command)
	if result.accepted:
		_last_checkpoint_kind = "progression"
		save_checkpoint()
	return result


func begin_battle() -> InfrastructureResult:
	if _battle_session != null:
		var existing: BattleSnapshot = _battle_session.get_snapshot()
		if (
			existing != null
			and String(existing.data.get("outcome", "")).is_empty()
		):
			return InfrastructureResultScript.success(
				_battle_session,
				{"already_active": true}
			)
	var progression_snapshot := progression.get_snapshot()
	if String(progression_snapshot.data.get("phase", "")) != "hub":
		return InfrastructureResultScript.failure(
			&"battle_not_available",
			"A battle can only begin from the hub phase."
		)
	var battle := GameSessionScript.new(
		services,
		catalog,
		base_content,
		balance,
		services.create_battle_random(&"battle.shuffle"),
		root_seed,
		encounter_id,
		checkpoint_slot,
		progression,
		CONTENT_VERSION,
		false
	)
	if not battle.is_ready():
		var battle_snapshot: Dictionary = battle.get_snapshot().to_dictionary()
		return InfrastructureResultScript.failure(
			&"battle_initialization_failed",
			"Progression state could not initialize a battle.",
			{
				"reason_code": String(battle_snapshot.get("outcome_reason", "")),
				"snapshot": battle_snapshot,
			}
		)
	_battle_session = battle
	return InfrastructureResultScript.success(battle)


func query_card_play(
	card_instance_id: StringName,
	target_id: StringName = &""
) -> BattlePlayability:
	if _battle_session == null:
		return BattlePlayability.new(false, &"battle_not_started")
	return _battle_session.query_card_play(card_instance_id, target_id)


func submit_battle(command: BattleCommand) -> BattleCommandResult:
	if _battle_session == null:
		return BattleCommandResult.new(
			false,
			&"battle_not_started",
			[],
			null
		)
	var result: BattleCommandResult = _battle_session.submit(command)
	if result.accepted and result.snapshot != null:
		var outcome := String(result.snapshot.data.get("outcome", ""))
		if outcome in ENDED_OUTCOMES:
			_last_battle = _battle_summary(result.snapshot)
			var progression_result: ProgressionCommandResult = progression.submit(
				ProgressionCommand.resolve_battle(StringName(outcome))
			)
			if progression_result.accepted:
				_last_checkpoint_kind = "post_battle"
				save_checkpoint()
	return result


func start_next_battle() -> InfrastructureResult:
	_battle_session = null
	_last_battle = {}
	return begin_battle()


func save_checkpoint() -> InfrastructureResult:
	var envelope := _build_checkpoint_envelope()
	last_checkpoint_result = services.saves.save_slot(
		checkpoint_slot,
		envelope
	)
	return last_checkpoint_result


func card_display_name(definition_id: StringName) -> String:
	var card: Dictionary = catalog.get_card(definition_id)
	return String(card.get("display_name_zh", String(definition_id)))


func enemy_display_name(definition_id: StringName) -> String:
	var enemy: Dictionary = catalog.get_enemy(definition_id)
	return String(enemy.get("display_name_zh", String(definition_id)))


func _build_checkpoint_envelope() -> Dictionary:
	var progression_state: Dictionary = progression.export_persistent_state()
	var progression_snapshot: ProgressionSnapshot = progression.get_snapshot()
	var collection: Dictionary = {}
	for item in progression_snapshot.data.get("collection", []):
		if int(item.get("copies", 0)) > 0 or int(item.get("fragments", 0)) > 0:
			collection[String(item.get("definition_id", ""))] = {
				"copies": int(item.get("copies", 0)),
				"level": int(item.get("level", 0)),
				"fragments": int(item.get("fragments", 0)),
			}
	var deck_summary: Dictionary = {}
	var resolved: InfrastructureResult = catalog.resolve_encounter(encounter_id)
	if resolved.ok:
		var owned_deck: Array[String] = progression.build_owned_battle_deck(
			resolved.data.get("deck_definition_ids", [])
		)
		for definition_id in owned_deck:
			deck_summary[definition_id] = int(deck_summary.get(definition_id, 0)) + 1
	return {
		"save_version": 2,
		"content_version": CONTENT_VERSION,
		"created_at": Time.get_datetime_string_from_system(true, false) + "Z",
		"rng_seed": root_seed,
		"profile": {
			"pathway": "seer",
			"sequence": 9,
			"identity_id": String(progression_state.get("identity_id", "")),
		},
		"run": {
			"checkpoint_kind": _last_checkpoint_kind,
			"encounter_id": String(encounter_id),
			"deck_summary": deck_summary,
			"last_battle": _last_battle.duplicate(true),
		},
		"collection": collection,
		"progression": progression_state,
	}


func _battle_summary(snapshot: BattleSnapshot) -> Dictionary:
	var data := snapshot.to_dictionary()
	return {
		"battle_id": String(data.get("battle_id", "")),
		"outcome": String(data.get("outcome", "")),
		"reason_code": String(data.get("outcome_reason", "")),
		"round_number": int(data.get("round_number", 0)),
		"revision": int(data.get("revision", 0)),
	}
