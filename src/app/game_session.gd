class_name GameSession
extends RefCounted

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")

const ENDED_OUTCOMES: Array[String] = ["victory", "defeat"]

var services: AppServices
var catalog: RefCounted
var battle_id: StringName
var encounter_id: StringName
var encounter_name: String
var root_seed: int
var checkpoint_slot: String
var last_checkpoint_result: InfrastructureResult = null

var _engine: RefCounted
var _content_version: String
var _deck_definition_ids: Array[String] = []
var _last_saved_key: String = ""
var _starting_sequence: int = 9
var _pathway_id: String = "seer"


func _init(
	app_services: AppServices,
	content_catalog: RefCounted,
	content: BattleContentPort,
	balance: BattleBalancePort,
	random: BattleRandomPort,
	run_seed: int,
	selected_encounter_id: StringName,
	save_slot: String
) -> void:
	services = app_services
	catalog = content_catalog
	root_seed = run_seed
	encounter_id = selected_encounter_id
	checkpoint_slot = save_slot
	_content_version = content_catalog.content_version
	var advancement: Variant = balance.get_value(&"progression.sequence_9_to_8_requirements")
	if advancement is Dictionary:
		_starting_sequence = int(advancement.get("from_sequence", _starting_sequence))
	_engine = BattleEngineScript.new()
	var resolved = catalog.resolve_encounter(encounter_id)
	if not resolved.ok:
		return
	encounter_name = String(resolved.data.get("display_name_zh", String(encounter_id)))
	_deck_definition_ids.assign(resolved.data.get("deck_definition_ids", []))
	battle_id = StringName("%s.%d" % [String(encounter_id), run_seed])
	var player_state := _build_player_state(balance)
	_engine.initialize(
		content,
		balance,
		random,
		battle_id,
		player_state,
		_deck_definition_ids,
		resolved.data.get("enemy_configs", [])
	)


func is_ready() -> bool:
	var snapshot := get_snapshot()
	return not snapshot.data.is_empty() and String(snapshot.data.get("phase", "")) != "init_error"


func get_snapshot() -> BattleSnapshot:
	return _engine.get_snapshot()


func query_card_play(
	card_instance_id: StringName,
	target_id: StringName = &""
) -> BattlePlayability:
	return _engine.query_card_play(card_instance_id, target_id)


func submit(command: BattleCommand) -> BattleCommandResult:
	var result = _engine.submit(command)
	if result.accepted and result.snapshot != null:
		var outcome := String(result.snapshot.data.get("outcome", ""))
		if outcome in ENDED_OUTCOMES:
			last_checkpoint_result = save_checkpoint(result.snapshot)
	return result


func save_checkpoint(snapshot: BattleSnapshot = null) -> InfrastructureResult:
	var current_snapshot := snapshot if snapshot != null else get_snapshot()
	var snapshot_data := current_snapshot.to_dictionary()
	var outcome := String(snapshot_data.get("outcome", ""))
	if not outcome in ENDED_OUTCOMES:
		return InfrastructureResultScript.failure(
			&"battle_not_ended",
			"Only an ended battle can create a post-battle checkpoint."
		)
	var save_key := "%s:%d:%s" % [
		String(snapshot_data.get("battle_id", "")),
		int(snapshot_data.get("revision", 0)),
		outcome,
	]
	if save_key == _last_saved_key:
		last_checkpoint_result = InfrastructureResultScript.success(
			{"slot": checkpoint_slot},
			{"already_saved": true}
		)
		return last_checkpoint_result
	var envelope := _build_checkpoint_envelope(snapshot_data)
	var result := services.saves.save_slot(checkpoint_slot, envelope)
	if result.ok:
		_last_saved_key = save_key
		last_checkpoint_result = result
		return result
	last_checkpoint_result = InfrastructureResultScript.failure(
		&"checkpoint_save_failed",
		"Post-battle checkpoint could not be saved.",
		{
			"cause": String(result.code),
			"cause_message": result.message,
			"cause_details": result.details,
		}
	)
	return last_checkpoint_result


func card_display_name(definition_id: StringName) -> String:
	var card: Dictionary = catalog.get_card(definition_id)
	return String(card.get("display_name_zh", String(definition_id)))


func enemy_display_name(definition_id: StringName) -> String:
	var enemy: Dictionary = catalog.get_enemy(definition_id)
	return String(enemy.get("display_name_zh", String(definition_id)))


func _build_player_state(balance: BattleBalancePort) -> Dictionary:
	var max_corruption: Variant = balance.get_value(&"player.max_corruption")
	var max_attention: Variant = balance.get_value(&"player.max_attention")
	return {
		"actor_id": "player",
		"hp": int(balance.get_value(&"player.starting_health")),
		"max_hp": int(balance.get_value(&"player.base_max_hp")),
		"block": 0,
		"spirit": 0,
		"max_spirit": int(balance.get_value(&"player.base_max_spirit")),
		"corruption": 0,
		"max_corruption": int(max_corruption) if max_corruption != null else 0,
		"attention": 0,
		"max_attention": int(max_attention) if max_attention != null else 0,
		"statuses": [],
	}


func _build_checkpoint_envelope(snapshot_data: Dictionary) -> Dictionary:
	var deck_summary: Dictionary = {}
	for definition_id in _deck_definition_ids:
		deck_summary[definition_id] = int(deck_summary.get(definition_id, 0)) + 1
	return {
		"save_version": 1,
		"content_version": _content_version,
		"created_at": Time.get_datetime_string_from_system(true, false) + "Z",
		"rng_seed": root_seed,
		"profile": {
			"pathway": _pathway_id,
			"sequence": _starting_sequence,
		},
		"run": {
			"checkpoint_kind": "post_battle",
			"encounter_id": String(encounter_id),
			"deck_summary": deck_summary,
			"last_battle": {
				"battle_id": String(snapshot_data.get("battle_id", "")),
				"outcome": String(snapshot_data.get("outcome", "")),
				"reason_code": String(snapshot_data.get("outcome_reason", "")),
				"round_number": int(snapshot_data.get("round_number", 0)),
				"revision": int(snapshot_data.get("revision", 0)),
			},
		},
		"collection": {},
	}
