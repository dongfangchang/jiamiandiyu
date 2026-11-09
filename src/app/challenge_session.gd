class_name ChallengeSession
extends RefCounted

const GameSessionScript := preload("res://src/app/game_session.gd")
const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")
const ProgressionCommandScript := preload("res://src/core/progression_command.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")
const ChallengeCommandScript := preload("res://src/core/challenge_command.gd")
const ChallengeEngineScript := preload("res://src/gameplay/challenge_engine.gd")
const DeckEngineScript := preload("res://src/gameplay/deck_engine.gd")
const CheckpointEnvelopeBuilderScript := preload("res://src/app/checkpoint_envelope_builder.gd")

const DEFAULT_CONTENT_VERSION := "v0.6.0"
const DEFAULT_SAVE_VERSION := 4
const BATTLE_NODE_TYPES: Array[String] = ["normal", "elite", "boss"]

var services: AppServices
var catalog: CampaignContentCatalog
var base_content: BattleContentPort
var balance: BattleBalancePort
var progression_content: ProgressionContentPort
var progression: ProgressionEngine
var route_content: RouteContentAdapter
var challenge_content: ChallengeContentAdapter
var deck_engine: DeckEngine = null
var content_version: String = DEFAULT_CONTENT_VERSION
var save_version: int = DEFAULT_SAVE_VERSION
var challenge_id: StringName
var sequence_state: Dictionary
var root_seed: int
var checkpoint_slot: String
var last_checkpoint_result: InfrastructureResult = null
var last_error_code: StringName = &""

var _challenge_engine: ChallengeEngine = null
var _battle_session: GameSession = null
var _active_node_id: StringName = &""
var _last_battle: Dictionary = {}
var _completion_reward_applied: bool = false


func _init(
	app_services: AppServices,
	content_catalog: CampaignContentCatalog,
	battle_content: BattleContentPort,
	global_balance: BattleBalancePort,
	progression_content_port: ProgressionContentPort,
	progression_engine: ProgressionEngine,
	route_content_port: RouteContentAdapter,
	challenge_content_port: ChallengeContentAdapter,
	selected_challenge_id: StringName,
	initial_sequence_state: Dictionary,
	run_seed: int,
	save_slot: String,
	deck_engine_value: DeckEngine = null,
	content_version_value: String = DEFAULT_CONTENT_VERSION,
	save_version_value: int = DEFAULT_SAVE_VERSION
) -> void:
	services = app_services
	catalog = content_catalog
	base_content = battle_content
	balance = global_balance
	progression_content = progression_content_port
	progression = progression_engine
	route_content = route_content_port
	challenge_content = challenge_content_port
	deck_engine = deck_engine_value
	content_version = content_version_value
	save_version = save_version_value
	challenge_id = selected_challenge_id
	sequence_state = initial_sequence_state.duplicate(true)
	root_seed = run_seed
	checkpoint_slot = save_slot


func initialize(
	challenge_state: Dictionary = {},
	completion_reward_applied: bool = false
) -> InfrastructureResult:
	if progression == null or progression.get_snapshot() == null:
		return InfrastructureResultScript.failure(
			&"progression_not_initialized",
			"Progression must be initialized before a challenge."
		)
	if route_content == null or challenge_content == null:
		return InfrastructureResultScript.failure(
			&"challenge_ports_missing",
			"Challenge content ports are required."
		)
	if not challenge_content.is_valid():
		return InfrastructureResultScript.failure(
			&"challenge_content_invalid",
			"Challenge content failed reference validation.",
			{"errors": challenge_content.validation_errors()}
		)
	_challenge_engine = ChallengeEngineScript.new(
		route_content,
		challenge_content,
		challenge_id
	)
	var initialized := _challenge_engine.initialize(
		sequence_state,
		challenge_state
	)
	if not initialized.accepted:
		_challenge_engine = null
		return InfrastructureResultScript.failure(
			&"challenge_initialization_failed",
			"Challenge state could not be initialized.",
			{
				"reason_code": String(initialized.reason_code),
				"snapshot": initialized.snapshot.to_dictionary(),
			}
		)
	_completion_reward_applied = completion_reward_applied
	if (
		String(_challenge_engine.get_snapshot().data.get("phase", ""))
		== "completed"
		and not _completion_reward_applied
	):
		if _apply_completed_snapshot_reward():
			save_checkpoint("challenge_reward_recovered")
	return InfrastructureResultScript.success(self)


func is_ready() -> bool:
	if _challenge_engine == null:
		return false
	var challenge_snapshot := get_challenge_snapshot()
	return (
		challenge_snapshot != null
		and String(challenge_snapshot.data.get("phase", "")) != "init_error"
	)


func get_challenge_snapshot() -> ChallengeSnapshot:
	if _challenge_engine == null:
		return ChallengeSnapshot.new({"phase": "uninitialized"})
	return _challenge_engine.get_snapshot()


func get_progression_snapshot() -> ProgressionSnapshot:
	return progression.get_snapshot()


func get_route_snapshot() -> RouteSnapshot:
	if _challenge_engine == null:
		return RouteSnapshot.new({
			"phase": "uninitialized",
			"route_id": "",
			"nodes": [],
			"completed_node_ids": [],
			"available_commands": [],
		})
	return _challenge_engine.get_route_snapshot()


func get_ritual_snapshot() -> RitualSnapshot:
	if _challenge_engine == null:
		return RitualSnapshot.new({"status": "inactive", "ritual_id": ""})
	return _challenge_engine.get_ritual_snapshot()


func get_sequence_state() -> SequenceState:
	if _challenge_engine == null:
		return SequenceState.new(sequence_state)
	return _challenge_engine.get_sequence_state()


func get_deck_snapshot() -> DeckSnapshot:
	if deck_engine == null:
		return DeckSnapshot.new({
			"phase": "unavailable",
			"required_deck_size": 0,
			"current_card_ids": [],
			"current_deck_size": 0,
			"legal": false,
			"reason_code": "deck_unavailable",
			"confirmed": false,
			"cards": [],
			"presets": [],
			"available_commands": [],
		})
	return deck_engine.get_snapshot()


func submit_deck(command: DeckCommand) -> DeckCommandResult:
	if deck_engine == null:
		return DeckCommandResult.new(
			false,
			&"deck_unavailable",
			[],
			get_deck_snapshot()
		)
	var result := deck_engine.submit(command)
	if result.accepted:
		save_checkpoint("challenge_deck")
	return result


func get_confirmed_deck_ids() -> Array[String]:
	if deck_engine == null:
		return []
	return deck_engine.get_confirmed_deck_ids()


func get_battle_session() -> GameSession:
	return _battle_session


func get_battle_snapshot() -> BattleSnapshot:
	if _battle_session == null:
		return null
	return _battle_session.get_snapshot()


func get_active_node_id() -> StringName:
	return _active_node_id


func query_card_play(
	card_instance_id: StringName,
	target_id: StringName = &""
) -> BattlePlayability:
	if _battle_session == null:
		return BattlePlayability.new(false, &"battle_not_started")
	return _battle_session.query_card_play(card_instance_id, target_id)


func submit_challenge(command: ChallengeCommand) -> ChallengeCommandResult:
	if _challenge_engine == null:
		return ChallengeCommandResult.new(false, &"challenge_not_initialized")
	var result := _challenge_engine.submit(command)
	if result.accepted:
		_apply_completion_reward_if_needed(result)
		save_checkpoint("challenge")
	return result


func submit_progression(command: ProgressionCommand) -> ProgressionCommandResult:
	var result := progression.submit(command)
	if result.accepted:
		_sync_deck_from_progression(result.snapshot)
		save_checkpoint("challenge_progression")
	return result


func _sync_deck_from_progression(snapshot: ProgressionSnapshot) -> void:
	if deck_engine == null or snapshot == null:
		return
	var owned_ids: Array[String] = []
	for card_value in snapshot.data.get("collection", []):
		if (
			card_value is Dictionary
			and int(card_value.get("copies", 0)) > 0
		):
			owned_ids.append(String(card_value.get("definition_id", "")))
	deck_engine.refresh_owned_card_ids(owned_ids)
	deck_engine.set_current_sequence(int(snapshot.data.get("sequence", 9)))


func begin_challenge_battle() -> InfrastructureResult:
	if _challenge_engine == null:
		return InfrastructureResultScript.failure(
			&"challenge_not_initialized",
			"Challenge is not initialized."
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
			"Challenge battles require the progression hub phase."
		)
	var challenge_snapshot := get_challenge_snapshot().data
	if String(challenge_snapshot.get("phase", "")) != "active":
		return InfrastructureResultScript.failure(
			&"challenge_not_active",
			"Challenge must be active before starting a battle."
		)
	var route_snapshot := get_route_snapshot().data
	if String(route_snapshot.get("phase", "")) != "map":
		return InfrastructureResultScript.failure(
			&"route_not_on_map",
			"Challenge route is not waiting for a map node."
		)
	var node_id := StringName(route_snapshot.get("available_node_id", ""))
	var node := _node_by_id(route_snapshot, node_id)
	if node.is_empty() or not String(node.get("type", "")) in BATTLE_NODE_TYPES:
		return InfrastructureResultScript.failure(
			&"route_node_not_battle",
			"The available challenge node is not a battle.",
			{"node_id": String(node_id)}
		)
	var selected := _challenge_engine.submit(
		ChallengeCommandScript.forward_route(
			RouteCommandScript.select_node(node_id)
		)
	)
	if not selected.accepted:
		return InfrastructureResultScript.failure(
			&"route_node_select_failed",
			"Challenge battle node could not be selected.",
			{
				"reason_code": String(selected.reason_code),
				"node_id": String(node_id),
			}
		)
	_active_node_id = node_id
	var encounter_id := StringName(node.get("encounter_id", ""))
	var resolved := catalog.resolve_encounter(encounter_id)
	if not resolved.ok:
		_active_node_id = &""
		return resolved
	var route_player_state := _challenge_engine.get_battle_player_state()
	var confirmed_deck: Array[String] = []
	if deck_engine != null:
		confirmed_deck = deck_engine.get_confirmed_deck_ids()
		if confirmed_deck.size() != deck_engine.get_snapshot().data.get(
			"required_deck_size",
			0
		):
			_active_node_id = &""
			return InfrastructureResultScript.failure(
				&"deck_not_confirmed",
				"Confirm an eight-card deck before entering a challenge."
			)
	_battle_session = GameSessionScript.new(
		services,
		catalog,
		base_content,
		balance,
		services.create_battle_random(&"challenge.battle.shuffle"),
		root_seed,
		encounter_id,
		checkpoint_slot,
		progression,
		content_version,
		false,
		route_player_state,
		true,
		_challenge_engine,
		confirmed_deck
	)
	if not _battle_session.is_ready():
		var failed_snapshot := _battle_session.get_snapshot()
		_battle_session = null
		_active_node_id = &""
		return InfrastructureResultScript.failure(
			&"challenge_battle_initialization_failed",
			"Challenge battle could not initialize.",
			{
				"snapshot": (
					failed_snapshot.to_dictionary()
					if failed_snapshot != null
					else {}
				)
			}
		)
	return InfrastructureResultScript.success(
		_battle_session,
		{
			"node_id": String(node_id),
			"encounter_id": String(encounter_id),
		}
	)


func submit_battle(command: BattleCommand) -> BattleCommandResult:
	if _battle_session == null:
		return BattleCommandResult.new(false, &"battle_not_started", [], null)
	var result := _battle_session.submit(command)
	if not result.accepted or result.snapshot == null:
		return result
	var outcome := String(result.snapshot.data.get("outcome", ""))
	if outcome not in ["victory", "defeat"] or _active_node_id.is_empty():
		return result
	var resolved := _challenge_engine.submit(
		ChallengeCommandScript.forward_route(
			RouteCommandScript.resolve_node(
				_active_node_id,
				StringName(outcome),
				result.snapshot.data.get("player", {})
			)
		)
	)
	if not resolved.accepted:
		return BattleCommandResult.new(
			false,
			resolved.reason_code,
			[],
			result.snapshot
		)
	var progression_result := progression.submit(
		ProgressionCommandScript.resolve_battle(StringName(outcome))
	)
	if not progression_result.accepted:
		return BattleCommandResult.new(
			false,
			progression_result.reason_code,
			[],
			result.snapshot
		)
	_last_battle = _battle_summary(result.snapshot)
	_active_node_id = &""
	_apply_completion_reward_if_needed(resolved)
	save_checkpoint("challenge_post_battle")
	return result


func submit_route(command: RouteCommand) -> ChallengeCommandResult:
	if _challenge_engine == null:
		return ChallengeCommandResult.new(false, &"challenge_not_initialized")
	var result := _challenge_engine.submit(
		ChallengeCommandScript.forward_route(command)
	)
	if result.accepted:
		_apply_completion_reward_if_needed(result)
		save_checkpoint("challenge_route")
	return result


func card_display_name(definition_id: StringName) -> String:
	var card := catalog.get_card(definition_id)
	return String(card.get("display_name_zh", String(definition_id)))


func enemy_display_name(definition_id: StringName) -> String:
	var enemy := catalog.get_enemy(definition_id)
	return String(enemy.get("display_name_zh", String(definition_id)))


func resolve_current_encounter() -> InfrastructureResult:
	var snapshot := get_route_snapshot().data
	var node_id := StringName(
		snapshot.get("selected_node_id", snapshot.get("available_node_id", ""))
	)
	var node := _node_by_id(snapshot, node_id)
	if node.is_empty():
		return InfrastructureResultScript.failure(
			&"challenge_route_node_missing",
			"Current challenge node is unavailable."
		)
	return catalog.resolve_encounter(StringName(node.get("encounter_id", "")))


func save_checkpoint(kind: String = "challenge") -> InfrastructureResult:
	if progression == null or _challenge_engine == null:
		return InfrastructureResultScript.failure(
			&"challenge_not_initialized",
			"Challenge checkpoint requires initialized progression and challenge."
		)
	var envelope := _build_checkpoint_envelope(kind)
	last_checkpoint_result = services.saves.save_slot(
		checkpoint_slot,
		envelope
	)
	return last_checkpoint_result


func _apply_completion_reward_if_needed(
	result: ChallengeCommandResult
) -> void:
	if _completion_reward_applied:
		return
	for event in result.events:
		if event.type != &"ChallengeCompleted":
			continue
		_apply_reward_value(event.data.get("reward", {}))
		return


func apply_pending_challenge_reward() -> bool:
	if _completion_reward_applied or _challenge_engine == null:
		return _completion_reward_applied
	if _apply_completed_snapshot_reward():
		save_checkpoint("challenge_reward_manual")
		return true
	return false


func _apply_completed_snapshot_reward() -> bool:
	if String(get_challenge_snapshot().data.get("phase", "")) != "completed":
		return false
	return _apply_reward_value(
		get_challenge_snapshot().data.get("completion_reward", {})
	)


func _apply_reward_value(reward_value: Variant) -> bool:
	if not reward_value is Dictionary or reward_value.is_empty():
		last_error_code = &"challenge_reward_missing"
		return false
	var reward_amounts: Dictionary = reward_value
	var applied: ProgressionCommandResult = progression.apply_reward_bundle(
		reward_amounts
	)
	if not applied.accepted:
		last_error_code = applied.reason_code
		return false
	_completion_reward_applied = true
	last_error_code = &""
	return true


func _build_checkpoint_envelope(kind: String) -> Dictionary:
	var progression_state: Dictionary = progression.export_persistent_state()
	var progression_snapshot := progression.get_snapshot()
	var challenge_state := _challenge_engine.export_persistent_state()
	var route_state_value: Variant = challenge_state.get("route_state", {})
	var route_state: Dictionary = (
		route_state_value if route_state_value is Dictionary else {}
	)
	var sequence := get_sequence_state().data
	if (
		String(sequence.get("advancement_state", "locked")) == "locked"
		and not sequence_state.is_empty()
	):
		sequence = sequence_state.duplicate(true)
	var route_snapshot := get_route_snapshot().data
	var current_node_id := String(route_snapshot.get("current_node_id", ""))
	var encounter := resolve_current_encounter()
	var deck_summary: Dictionary = {}
	var active_deck: Array[String] = []
	if deck_engine != null:
		active_deck = deck_engine.get_confirmed_deck_ids()
	if active_deck.is_empty() and encounter.ok:
		active_deck = progression.build_owned_battle_deck(
			encounter.data.get("deck_definition_ids", [])
		)
	active_deck.assign(_challenge_engine.build_battle_deck(active_deck))
	for definition_id in active_deck:
		deck_summary[definition_id] = int(
			deck_summary.get(definition_id, 0)
		) + 1
	var challenge_payload := challenge_state.duplicate(true)
	challenge_payload["reward_applied"] = _completion_reward_applied
	challenge_payload["sequence_state"] = sequence.duplicate(true)
	return CheckpointEnvelopeBuilderScript.build(
		progression_state,
		progression_snapshot,
		route_state,
		sequence,
		root_seed,
		content_version,
		save_version,
		kind,
		_last_battle,
		String(encounter.data.get("id", "")) if encounter.ok else "",
		current_node_id,
		deck_summary,
		challenge_payload,
		(
			deck_engine.export_persistent_state()
			if deck_engine != null
			else {}
		)
	)


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
