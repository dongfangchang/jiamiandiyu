class_name RouteSession
extends RefCounted

const GameSessionScript := preload("res://src/app/game_session.gd")
const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")
const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")

const CONTENT_VERSION := "v0.5.0"
const BATTLE_NODE_TYPES: Array[String] = ["normal", "elite", "boss"]

var services: AppServices
var catalog: CampaignContentCatalog
var base_content: BattleContentPort
var balance: BattleBalancePort
var progression_content: ProgressionContentPort
var progression: ProgressionEngine
var route_content: RouteContentAdapter
var root_seed: int
var checkpoint_slot: String
var last_checkpoint_result: InfrastructureResult = null

var _route_engine: RouteEngine = null
var _battle_session: GameSession = null
var _active_node_id: StringName = &""
var _last_battle: Dictionary = {}


func _init(
	app_services: AppServices,
	content_catalog: CampaignContentCatalog,
	battle_content: BattleContentPort,
	global_balance: BattleBalancePort,
	progression_content_port: ProgressionContentPort,
	progression_engine: ProgressionEngine,
	route_content_port: RouteContentAdapter,
	run_seed: int,
	save_slot: String
) -> void:
	services = app_services
	catalog = content_catalog
	base_content = battle_content
	balance = global_balance
	progression_content = progression_content_port
	progression = progression_engine
	route_content = route_content_port
	root_seed = run_seed
	checkpoint_slot = save_slot


func initialize(route_state: Dictionary = {}) -> InfrastructureResult:
	var progression_snapshot := progression.get_snapshot()
	if progression_snapshot == null:
		return InfrastructureResultScript.failure(
			&"progression_not_initialized",
			"Progression must be initialized before the route session."
		)
	var phase := String(progression_snapshot.data.get("phase", ""))
	if phase == "identity_selection" and route_state.is_empty():
		return InfrastructureResultScript.success(self, {"route_deferred": true})
	_route_engine = RouteEngineScript.new(
		route_content,
		route_content.get_default_route_id()
	)
	var initialized: RouteCommandResult
	if route_state.is_empty():
		initialized = _route_engine.initialize({})
		if initialized.accepted:
			initialized = _apply_identity_to_route()
	else:
		initialized = _route_engine.initialize(route_state)
	if not initialized.accepted:
		_route_engine = null
		return InfrastructureResultScript.failure(
			&"route_initialization_failed",
			"Route state could not be initialized.",
			{
				"reason_code": String(initialized.reason_code),
				"snapshot": initialized.snapshot.to_dictionary(),
			}
		)
	return InfrastructureResultScript.success(self)


func is_ready() -> bool:
	if progression == null:
		return false
	var progression_snapshot := progression.get_snapshot()
	if progression_snapshot == null or progression_snapshot.data.is_empty():
		return false
	if String(progression_snapshot.data.get("phase", "")) == "init_error":
		return false
	if String(progression_snapshot.data.get("phase", "")) == "identity_selection":
		return true
	return _route_engine != null


func get_progression_snapshot() -> ProgressionSnapshot:
	return progression.get_snapshot()


func get_route_snapshot() -> RouteSnapshot:
	if _route_engine == null:
		return RouteSnapshot.new({
			"phase": "uninitialized",
			"route_id": "",
			"nodes": [],
			"completed_node_ids": [],
			"available_commands": [],
		})
	return _route_engine.get_snapshot()


func get_ritual_snapshot() -> RitualSnapshot:
	if _route_engine == null:
		return RitualSnapshot.new({"status": "inactive", "ritual_id": ""})
	return _route_engine.get_ritual_snapshot()


func get_sequence_state() -> SequenceState:
	if _route_engine == null:
		return SequenceState.new({
			"pathway_id": "seer",
			"pathway_name_zh": "占卜家",
			"current_sequence": 9,
			"next_sequence": 8,
			"next_sequence_name_zh": "小丑",
			"advancement_state": "locked",
		})
	return _route_engine.get_sequence_state()


func get_battle_session() -> GameSession:
	return _battle_session


func get_battle_snapshot() -> BattleSnapshot:
	if _battle_session == null:
		return null
	return _battle_session.get_snapshot()


func get_active_node_id() -> StringName:
	return _active_node_id


func submit_progression(command: ProgressionCommand) -> ProgressionCommandResult:
	var result: ProgressionCommandResult = progression.submit(command)
	if not result.accepted:
		return result
	if command.type == ProgressionCommand.SELECT_IDENTITY and _route_engine == null:
		var initialized := initialize({})
		if not initialized.ok:
			return ProgressionCommandResult.new(
				false,
				initialized.code,
				[],
				progression.get_snapshot()
			)
	save_checkpoint("progression")
	return result


func query_card_play(
	card_instance_id: StringName,
	target_id: StringName = &""
) -> BattlePlayability:
	if _battle_session == null:
		return BattlePlayability.new(false, &"battle_not_started")
	return _battle_session.query_card_play(card_instance_id, target_id)


func begin_route_battle() -> InfrastructureResult:
	if _route_engine == null:
		return InfrastructureResultScript.failure(
			&"route_not_initialized",
			"Select an identity before starting a route battle."
		)
	if _battle_session != null:
		var existing := _battle_session.get_snapshot()
		if existing != null and String(existing.data.get("outcome", "")).is_empty():
			return InfrastructureResultScript.success(
				_battle_session,
				{"already_active": true}
			)
	var progression_snapshot := progression.get_snapshot()
	if String(progression_snapshot.data.get("phase", "")) != "hub":
		return InfrastructureResultScript.failure(
			&"battle_not_available",
			"Route battles require the progression hub phase."
		)
	var route_snapshot := _route_engine.get_snapshot().data
	if String(route_snapshot.get("phase", "")) != "map":
		return InfrastructureResultScript.failure(
			&"route_not_on_map",
			"The route is not waiting for a map node."
		)
	var node_id := StringName(route_snapshot.get("available_node_id", ""))
	var node := _node_by_id(route_snapshot, node_id)
	if node.is_empty() or not String(node.get("type", "")) in BATTLE_NODE_TYPES:
		return InfrastructureResultScript.failure(
			&"route_node_not_battle",
			"The available route node is not a battle.",
			{"node_id": String(node_id)}
		)
	var selected := _route_engine.submit(RouteCommandScript.select_node(node_id))
	if not selected.accepted:
		return InfrastructureResultScript.failure(
			&"route_node_select_failed",
			"The route node could not be selected.",
			{"reason_code": String(selected.reason_code), "node_id": String(node_id)}
		)
	_active_node_id = node_id
	var encounter_id := StringName(node.get("encounter_id", ""))
	var resolved := catalog.resolve_encounter(encounter_id)
	if not resolved.ok:
		_active_node_id = &""
		return resolved
	var random: BattleRandomPort = services.create_battle_random(&"battle.shuffle")
	var route_player_state := _route_engine.get_battle_player_state()
	_battle_session = GameSessionScript.new(
		services,
		catalog,
		base_content,
		balance,
		random,
		root_seed,
		encounter_id,
		checkpoint_slot,
		progression,
		CONTENT_VERSION,
		false,
		route_player_state,
		false
	)
	if not _battle_session.is_ready():
		var failed_snapshot: Dictionary = _battle_session.get_snapshot().to_dictionary()
		_battle_session = null
		_active_node_id = &""
		return InfrastructureResultScript.failure(
			&"battle_initialization_failed",
			"Route battle could not initialize.",
			{
				"reason_code": String(failed_snapshot.get("outcome_reason", "")),
				"snapshot": failed_snapshot,
			}
		)
	return InfrastructureResultScript.success(
		_battle_session,
		{"node_id": String(node_id), "encounter_id": String(encounter_id)}
	)


func submit_battle(command: BattleCommand) -> BattleCommandResult:
	if _battle_session == null:
		return BattleCommandResult.new(false, &"battle_not_started", [], null)
	var result: BattleCommandResult = _battle_session.submit(command)
	if not result.accepted or result.snapshot == null:
		return result
	var outcome := String(result.snapshot.data.get("outcome", ""))
	if outcome not in ["victory", "defeat"]:
		return result
	if _active_node_id.is_empty():
		return result
	var resolved := _route_engine.submit(
		RouteCommandScript.resolve_node(
			_active_node_id,
			StringName(outcome),
			result.snapshot.data.get("player", {})
		)
	)
	if not resolved.accepted:
		return BattleCommandResult.new(
			false,
			resolved.reason_code,
			[],
			result.snapshot
		)
	progression.submit(ProgressionCommandScript.resolve_battle(StringName(outcome)))
	_last_battle = _battle_summary(result.snapshot)
	_active_node_id = &""
	save_checkpoint("route_post_battle")
	return result


func submit_route(command: RouteCommand) -> RouteCommandResult:
	if _route_engine == null:
		return RouteCommandResult.new(false, &"route_not_initialized")
	var result: RouteCommandResult = _route_engine.submit(command)
	if result.accepted:
		save_checkpoint("route")
	return result


func save_checkpoint(kind: String = "route") -> InfrastructureResult:
	if progression == null:
		return InfrastructureResultScript.failure(
			&"progression_not_initialized",
			"Checkpoint requires initialized progression."
		)
	var envelope := _build_checkpoint_envelope(kind)
	last_checkpoint_result = services.saves.save_slot(checkpoint_slot, envelope)
	return last_checkpoint_result


func card_display_name(definition_id: StringName) -> String:
	var card: Dictionary = catalog.get_card(definition_id)
	return String(card.get("display_name_zh", String(definition_id)))


func enemy_display_name(definition_id: StringName) -> String:
	var enemy: Dictionary = catalog.get_enemy(definition_id)
	return String(enemy.get("display_name_zh", String(definition_id)))


func resolve_current_encounter() -> InfrastructureResult:
	var snapshot := get_route_snapshot().data
	var node_id := StringName(
		snapshot.get("selected_node_id", snapshot.get("available_node_id", ""))
	)
	var node := _node_by_id(snapshot, node_id)
	if node.is_empty():
		return InfrastructureResultScript.failure(
			&"route_node_missing",
			"Current route node is unavailable."
		)
	return catalog.resolve_encounter(StringName(node.get("encounter_id", "")))


func _apply_identity_to_route() -> RouteCommandResult:
	var persistent := _route_engine.export_persistent_state()
	var battle_state := progression.apply_battle_modifiers(
		_route_engine.get_battle_player_state()
	)
	var run_state: Dictionary = persistent.get("run_state", {}).duplicate(true)
	for key in ["hp", "max_hp", "attention", "max_attention"]:
		if battle_state.has(key):
			run_state[key] = int(battle_state[key])
	persistent["run_state"] = run_state
	return _route_engine.initialize(persistent)


func _build_checkpoint_envelope(kind: String) -> Dictionary:
	var progression_state: Dictionary = progression.export_persistent_state()
	var progression_snapshot := progression.get_snapshot()
	var route_snapshot := get_route_snapshot().data
	var sequence := get_sequence_state().data
	var collection: Dictionary = {}
	for item in progression_snapshot.data.get("collection", []):
		if int(item.get("copies", 0)) > 0 or int(item.get("fragments", 0)) > 0:
			collection[String(item.get("definition_id", ""))] = {
				"copies": int(item.get("copies", 0)),
				"level": int(item.get("level", 0)),
				"fragments": int(item.get("fragments", 0)),
			}
	var route_state := (
		_route_engine.export_persistent_state()
		if _route_engine != null
		else {}
	)
	var current_node_id := String(route_snapshot.get("current_node_id", ""))
	var encounter := resolve_current_encounter()
	var deck_summary: Dictionary = {}
	if encounter.ok:
		var owned_deck: Array[String] = progression.build_owned_battle_deck(
			encounter.data.get("deck_definition_ids", [])
		)
		for definition_id in owned_deck:
			deck_summary[definition_id] = int(deck_summary.get(definition_id, 0)) + 1
	return {
		"save_version": 3,
		"content_version": CONTENT_VERSION,
		"created_at": Time.get_datetime_string_from_system(true, false) + "Z",
		"rng_seed": root_seed,
		"profile": {
			"pathway": String(sequence.get("pathway_id", "seer")),
			"sequence": int(sequence.get("current_sequence", 9)),
			"identity_id": String(progression_state.get("identity_id", "")),
		},
		"run": {
			"checkpoint_kind": kind,
			"encounter_id": (
				String(encounter.data.get("id", ""))
				if encounter.ok
				else ""
			),
			"current_node_id": current_node_id,
			"deck_summary": deck_summary,
			"last_battle": _last_battle.duplicate(true),
		},
		"collection": collection,
		"progression": progression_state,
		"route": {
			"initialized": _route_engine != null,
			"route_id": String(route_state.get("route_id", "")),
			"phase": String(route_state.get("phase", "")),
			"run_state": route_state.get("run_state", {}).duplicate(true),
			"completed_node_ids": route_state.get("completed_node_ids", []).duplicate(),
			"sequence_state": String(route_state.get("sequence_state", "locked")),
			"state": route_state,
		},
	}


func _node_by_id(snapshot: Dictionary, node_id: StringName) -> Dictionary:
	for value in snapshot.get("nodes", []):
		if value is Dictionary and String(value.get("id", "")) == String(node_id):
			return value
	return {}


func _battle_summary(snapshot: BattleSnapshot) -> Dictionary:
	var data := snapshot.to_dictionary()
	return {
		"battle_id": String(data.get("battle_id", "")),
		"outcome": String(data.get("outcome", "")),
		"reason_code": String(data.get("outcome_reason", "")),
		"round_number": int(data.get("round_number", 0)),
		"revision": int(data.get("revision", 0)),
	}
