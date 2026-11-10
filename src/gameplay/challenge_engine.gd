class_name ChallengeEngine
extends RefCounted

const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")

const PHASE_LOCKED: StringName = &"locked"
const PHASE_MODIFIER_SELECTION: StringName = &"modifier_selection"
const PHASE_ACTIVE: StringName = &"active"
const PHASE_COMPLETED: StringName = &"completed"
const PHASE_FAILED: StringName = &"failed"
const PHASE_INIT_ERROR: StringName = &"init_error"

const OUTCOME_COMPLETED: StringName = &"completed"
const OUTCOME_FAILED: StringName = &"failed"

const EFFECT_PHASE_ROUND_DELTA: StringName = &"phase_round_delta"
const EFFECT_STARTING_CORRUPTION: StringName = &"starting_corruption_delta"
const EFFECT_STARTING_ATTENTION: StringName = &"starting_attention_delta"
const EFFECT_STARTING_MAX_SPIRIT: StringName = &"starting_max_spirit_delta"
const EFFECT_BATTLE_CORRUPTION: StringName = &"battle_corruption_delta"
const EFFECT_REMOVE_DEFINITIONS: StringName = &"remove_definition_ids"
const EFFECT_COMPLETION_REWARD: StringName = &"completion_reward"

const SUPPORTED_EFFECTS: Array[StringName] = [
	EFFECT_PHASE_ROUND_DELTA,
	EFFECT_STARTING_CORRUPTION,
	EFFECT_STARTING_ATTENTION,
	EFFECT_STARTING_MAX_SPIRIT,
	EFFECT_BATTLE_CORRUPTION,
	EFFECT_REMOVE_DEFINITIONS,
	EFFECT_COMPLETION_REWARD,
]

var _route_content: RouteContentPort
var _challenge_content: ChallengeContentPort
var _requested_challenge_id: StringName

var _challenge: Dictionary = {}
var _challenge_id: StringName = &""
var _modifiers_by_id: Dictionary = {}
var _modifier_order: Array[String] = []
var _completion_reward: Dictionary = {}
var _sequence_state: Dictionary = {}

var _state: Dictionary = {}
var _revision: int = 0
var _route_engine: RouteEngine = null
var _pending_events: Array[ChallengeEvent] = []


func _init(
	route_content: RouteContentPort,
	challenge_content: ChallengeContentPort,
	challenge_id: StringName = &""
) -> void:
	_route_content = route_content
	_challenge_content = challenge_content
	_requested_challenge_id = challenge_id


func initialize(
	sequence_state: Dictionary,
	initial_state: Dictionary = {}
) -> ChallengeCommandResult:
	_reset_runtime()
	if _route_content == null or _challenge_content == null:
		return _initialization_error(&"port_missing")
	if not _load_challenge():
		return _initialization_error(&"content_invalid")
	_sequence_state = sequence_state.duplicate(true)
	var unlocked := is_unlocked()
	if initial_state.is_empty():
		_state = _new_state(unlocked)
	elif not _restore_state(initial_state):
		return _initialization_error(&"state_invalid")
	_revision = maxi(1, int(_state.get("revision", 1)))
	_state["revision"] = _revision
	var event_type: StringName = &"ChallengeReady"
	if not unlocked:
		event_type = &"ChallengeLocked"
	return ChallengeCommandResult.new(
		true,
		&"ok",
		[ChallengeEvent.new(event_type, {
			"challenge_id": String(_challenge_id),
			"phase": String(_state.get("phase", "")),
		})],
		get_snapshot()
	)


func submit(command: ChallengeCommand) -> ChallengeCommandResult:
	if command == null:
		return _rejected(&"invalid_command")
	var phase := StringName(_state.get("phase", PHASE_INIT_ERROR))
	if phase == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	_pending_events.clear()
	var result: ChallengeCommandResult
	match command.type:
		ChallengeCommand.SELECT_MODIFIER:
			result = _select_modifier(command.modifier_id)
		ChallengeCommand.START_CHALLENGE:
			result = _start_challenge()
		ChallengeCommand.ROUTE:
			result = _submit_route(command.route_command)
		_:
			result = _rejected(&"invalid_command")
	if result.accepted:
		_revision += 1
		_state["revision"] = _revision
		result.snapshot = get_snapshot()
	return result


func is_unlocked() -> bool:
	var required_sequence := int(_challenge.get("required_sequence", 8))
	var current_sequence := int(_sequence_state.get("current_sequence", 9))
	var advancement_state := String(
		_sequence_state.get("advancement_state", "locked")
	)
	if not (
		current_sequence <= required_sequence
		and advancement_state == "completed"
	):
		return false
	var completed_ids := _completed_challenge_ids()
	var required_value: Variant = _challenge.get(
		"required_challenge_ids",
		[]
	)
	if required_value is Array:
		for challenge_id in required_value:
			if not String(challenge_id) in completed_ids:
				return false
	return true


func get_selected_modifier_id() -> StringName:
	return StringName(_state.get("selected_modifier_id", &""))


func get_route_engine() -> RouteEngine:
	return _route_engine


func get_route_snapshot() -> RouteSnapshot:
	if _route_engine == null:
		return RouteSnapshot.new({
			"phase": "uninitialized",
			"route_id": String(_challenge.get("route_id", "")),
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
	var sequence_data := _sequence_state.duplicate(true)
	if _route_engine != null:
		sequence_data = _route_engine.get_sequence_state().to_dictionary()
	sequence_data["completed_challenge_ids"] = _completed_challenge_ids()
	return SequenceState.new(sequence_data)


func get_battle_player_state() -> Dictionary:
	if _route_engine == null:
		return {}
	return _route_engine.get_battle_player_state()


func get_completion_reward() -> Dictionary:
	var reward := _completion_reward.duplicate(true)
	var modifier := _selected_modifier()
	if not modifier.is_empty():
		var effects: Dictionary = modifier.get("effects", {})
		var reward_delta_value: Variant = effects.get(
			String(EFFECT_COMPLETION_REWARD),
			{}
		)
		if reward_delta_value is Dictionary:
			_merge_reward(reward, reward_delta_value)
	return reward


func build_battle_deck(source_deck_ids: Array) -> Array[String]:
	var removed := {}
	var modifier := _selected_modifier()
	if not modifier.is_empty():
		var effects: Dictionary = modifier.get("effects", {})
		var values: Variant = effects.get(
			String(EFFECT_REMOVE_DEFINITIONS),
			[]
		)
		if values is Array:
			for value in values:
				removed[String(value)] = true
	var result: Array[String] = []
	for value in source_deck_ids:
		var definition_id := String(value)
		if not removed.has(definition_id):
			result.append(definition_id)
	return result


func prepare_enemy_configs(enemy_configs: Array) -> Array[Dictionary]:
	var phase_round_delta := 0
	var modifier := _selected_modifier()
	if not modifier.is_empty():
		var effects: Dictionary = modifier.get("effects", {})
		phase_round_delta = int(effects.get(
			String(EFFECT_PHASE_ROUND_DELTA),
			0
		))
	var prepared: Array[Dictionary] = []
	for source_value in enemy_configs:
		if not source_value is Dictionary:
			continue
		var enemy: Dictionary = source_value.duplicate(true)
		var phases_value: Variant = enemy.get("phases", [])
		if phases_value is Array:
			var phases: Array = []
			for phase_value in phases_value:
				if not phase_value is Dictionary:
					continue
				var phase: Dictionary = phase_value.duplicate(true)
				if phase.has("at_hp_percent"):
					# HP-threshold phases advance earlier by 10 percentage
					# points per round of delta (negative delta = earlier).
					phase["at_hp_percent"] = clampi(
						int(phase.get("at_hp_percent", 50)) - phase_round_delta * 10,
						1,
						99
					)
				else:
					phase["at_round"] = maxi(
						1,
						int(phase.get("at_round", 1)) + phase_round_delta
					)
				phases.append(phase)
			enemy["phases"] = phases
		prepared.append(enemy)
	return prepared


func get_snapshot() -> ChallengeSnapshot:
	var modifier_views: Array[Dictionary] = []
	for modifier_id in _modifier_order:
		var modifier: Dictionary = _modifiers_by_id[modifier_id]
		modifier_views.append({
			"id": modifier_id,
			"display_name_zh": String(modifier.get("display_name_zh", modifier_id)),
			"description_zh": String(modifier.get("description_zh", "")),
			"effects": modifier.get("effects", {}).duplicate(true),
		})
	var selected_modifier := _selected_modifier()
	var route_snapshot := get_route_snapshot().to_dictionary()
	return ChallengeSnapshot.new({
		"revision": _revision,
		"challenge_id": String(_challenge_id),
		"display_name_zh": String(
			_challenge.get("display_name_zh", _challenge_id)
		),
		"description_zh": String(_challenge.get("description_zh", "")),
		"phase": String(_state.get("phase", PHASE_INIT_ERROR)),
		"unlocked": is_unlocked(),
		"required_sequence": int(_challenge.get("required_sequence", 8)),
		"required_challenge_ids": (
			_challenge.get("required_challenge_ids", []).duplicate()
			if _challenge.get("required_challenge_ids", []) is Array
			else []
		),
		"completed_challenge_ids": _completed_challenge_ids(),
		"route_id": String(_challenge.get("route_id", "")),
		"selected_modifier_id": String(
			_state.get("selected_modifier_id", "")
		),
		"selected_modifier": selected_modifier.duplicate(true),
		"modifiers": modifier_views,
		"completion_reward": get_completion_reward(),
		"challenge_outcome": String(_state.get("challenge_outcome", "")),
		"route": route_snapshot,
		"ritual": get_ritual_snapshot().to_dictionary(),
		"sequence": get_sequence_state().to_dictionary(),
		"available_commands": _available_commands(),
	})


func export_persistent_state() -> Dictionary:
	return {
		"challenge_id": String(_challenge_id),
		"phase": String(_state.get("phase", PHASE_INIT_ERROR)),
		"selected_modifier_id": String(
			_state.get("selected_modifier_id", "")
		),
		"challenge_outcome": String(_state.get("challenge_outcome", "")),
		"route_state": (
			_route_engine.export_persistent_state()
			if _route_engine != null
			else {}
		),
		"sequence_state": get_sequence_state().to_dictionary(),
		"revision": _revision,
	}


func _select_modifier(modifier_id: StringName) -> ChallengeCommandResult:
	if not is_unlocked():
		return _rejected(&"challenge_locked")
	if StringName(_state.get("phase", "")) != PHASE_MODIFIER_SELECTION:
		return _rejected(&"wrong_phase")
	if not _modifiers_by_id.has(String(modifier_id)):
		return _rejected(&"unknown_modifier")
	_state["selected_modifier_id"] = String(modifier_id)
	_emit(&"ChallengeModifierSelected", {
		"modifier_id": String(modifier_id),
	})
	return _success()


func _start_challenge() -> ChallengeCommandResult:
	if not is_unlocked():
		return _rejected(&"challenge_locked")
	if StringName(_state.get("phase", "")) != PHASE_MODIFIER_SELECTION:
		return _rejected(&"wrong_phase")
	var selected_modifier_id := String(
		_state.get("selected_modifier_id", "")
	)
	if selected_modifier_id.is_empty():
		return _rejected(&"modifier_required")
	var route_id := StringName(_challenge.get("route_id", ""))
	var route_content := ChallengeRouteContentPort.new(
		_route_content,
		_build_initial_run_state()
	)
	_route_engine = RouteEngineScript.new(route_content, route_id)
	var initialized := _route_engine.initialize({})
	if not initialized.accepted:
		_route_engine = null
		_state["phase"] = String(PHASE_INIT_ERROR)
		return ChallengeCommandResult.new(
			false,
			initialized.reason_code,
			[],
			get_snapshot(),
			initialized
		)
	_state["phase"] = String(PHASE_ACTIVE)
	_state["challenge_outcome"] = ""
	_emit(&"ChallengeStarted", {
		"challenge_id": String(_challenge_id),
		"modifier_id": selected_modifier_id,
		"route_id": String(route_id),
	})
	return _success(initialized)


func _submit_route(command: RouteCommand) -> ChallengeCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_ACTIVE:
		return _rejected(&"wrong_phase")
	if command == null:
		return _rejected(&"invalid_route_command")
	if _route_engine == null:
		return _rejected(&"route_not_initialized")
	var forwarded_command := _prepare_route_command(command)
	var route_result: RouteCommandResult = _route_engine.submit(forwarded_command)
	if not route_result.accepted:
		return ChallengeCommandResult.new(
			false,
			route_result.reason_code,
			[],
			get_snapshot(),
			route_result
		)
	var route_snapshot: Dictionary = route_result.snapshot.data
	var route_outcome := String(route_snapshot.get("route_outcome", ""))
	if route_outcome == String(OUTCOME_COMPLETED):
		_state["phase"] = String(PHASE_COMPLETED)
		_state["challenge_outcome"] = String(OUTCOME_COMPLETED)
		_record_challenge_completion(String(_challenge_id))
		_emit(&"ChallengeCompleted", {
			"challenge_id": String(_challenge_id),
			"modifier_id": String(_state.get("selected_modifier_id", "")),
			"reward": get_completion_reward(),
		})
	elif route_outcome == String(OUTCOME_FAILED):
		_state["phase"] = String(PHASE_FAILED)
		_state["challenge_outcome"] = String(OUTCOME_FAILED)
		_emit(&"ChallengeFailed", {
			"challenge_id": String(_challenge_id),
			"modifier_id": String(_state.get("selected_modifier_id", "")),
			"reason_code": String(
				route_snapshot.get("route_outcome", "route_failed")
			),
		})
	return _success(route_result)


func _prepare_route_command(command: RouteCommand) -> RouteCommand:
	if (
		command.type != RouteCommand.RESOLVE_NODE
		or command.battle_outcome != RouteEngine.OUTCOME_VICTORY
	):
		return command
	var battle_delta := _selected_modifier_battle_corruption()
	if battle_delta == 0:
		return command
	var player_state: Dictionary = command.battle_player_state.duplicate(true)
	var current_run_state: Dictionary = _route_engine.get_snapshot().data.get(
		"run_state",
		{}
	)
	var corruption_before := maxi(
		int(player_state.get("corruption", 0)),
		int(current_run_state.get("corruption", 0))
	)
	var max_corruption := maxi(
		1,
		int(player_state.get(
			"max_corruption",
			current_run_state.get("max_corruption", 10)
		))
	)
	player_state["corruption"] = clampi(
		corruption_before + battle_delta,
		0,
		max_corruption
	)
	return RouteCommand.resolve_node(
		command.node_id,
		command.battle_outcome,
		player_state
	)


func _selected_modifier_battle_corruption() -> int:
	var modifier := _selected_modifier()
	if modifier.is_empty():
		return 0
	var effects: Dictionary = modifier.get("effects", {})
	return int(effects.get(String(EFFECT_BATTLE_CORRUPTION), 0))


func _load_challenge() -> bool:
	var challenge_id := _requested_challenge_id
	if challenge_id.is_empty():
		challenge_id = _challenge_content.get_default_challenge_id()
	if challenge_id.is_empty():
		return false
	var value: Variant = _challenge_content.get_challenge(challenge_id)
	if not value is Dictionary or value.is_empty():
		return false
	_challenge = value.duplicate(true)
	_challenge_id = StringName(_challenge.get("id", ""))
	if _challenge_id != challenge_id:
		return false
	var required_sequence := int(_challenge.get("required_sequence", -1))
	if required_sequence < 0 or required_sequence > 9:
		return false
	var route_id := StringName(_challenge.get("route_id", ""))
	if route_id.is_empty() or _route_content.get_route(route_id).is_empty():
		return false
	var reward_value: Variant = _challenge.get("completion_reward", {})
	if not reward_value is Dictionary:
		return false
	_completion_reward = reward_value.duplicate(true)
	if not _validate_reward(_completion_reward):
		return false
	var modifiers_value: Variant = _challenge.get("modifiers", [])
	if not modifiers_value is Array or modifiers_value.size() < 3:
		return false
	for modifier_value in modifiers_value:
		if not modifier_value is Dictionary:
			return false
		var modifier: Dictionary = modifier_value.duplicate(true)
		var modifier_id := String(modifier.get("id", ""))
		if modifier_id.is_empty() or _modifiers_by_id.has(modifier_id):
			return false
		if String(modifier.get("display_name_zh", "")).is_empty():
			return false
		var effects_value: Variant = modifier.get("effects", {})
		if not effects_value is Dictionary or effects_value.is_empty():
			return false
		var effects: Dictionary = effects_value
		for effect_id in effects:
			if not StringName(effect_id) in SUPPORTED_EFFECTS:
				return false
		if not _validate_modifier_effects(effects):
			return false
		_modifiers_by_id[modifier_id] = modifier
		_modifier_order.append(modifier_id)
	return not _modifier_order.is_empty()


func _validate_modifier_effects(effects: Dictionary) -> bool:
	for key in [
		String(EFFECT_PHASE_ROUND_DELTA),
		String(EFFECT_STARTING_CORRUPTION),
		String(EFFECT_STARTING_ATTENTION),
		String(EFFECT_STARTING_MAX_SPIRIT),
		String(EFFECT_BATTLE_CORRUPTION),
	]:
		if effects.has(key) and not _is_integer_number(effects[key]):
			return false
	if int(effects.get(String(EFFECT_PHASE_ROUND_DELTA), 0)) < -9:
		return false
	if (
		int(effects.get(String(EFFECT_BATTLE_CORRUPTION), 0)) < 0
		or int(effects.get(String(EFFECT_BATTLE_CORRUPTION), 0)) > 10
	):
		return false
	if effects.has(String(EFFECT_REMOVE_DEFINITIONS)):
		var values: Variant = effects[String(EFFECT_REMOVE_DEFINITIONS)]
		if not values is Array:
			return false
		var seen := {}
		for value in values:
			if not value is String or String(value).is_empty() or seen.has(value):
				return false
			seen[value] = true
	if effects.has(String(EFFECT_COMPLETION_REWARD)):
		var reward: Variant = effects[String(EFFECT_COMPLETION_REWARD)]
		if not reward is Dictionary or not _validate_reward(reward):
			return false
	return true


func _validate_reward(reward: Dictionary) -> bool:
	for key in reward:
		if not _is_integer_number(reward[key]) or int(reward[key]) < 0:
			return false
	return true


func _is_integer_number(value: Variant) -> bool:
	match typeof(value):
		TYPE_INT:
			return true
		TYPE_FLOAT:
			var number: float = value
			return is_finite(number) and is_equal_approx(number, round(number))
		_:
			return false


func _build_initial_run_state() -> Dictionary:
	var route := _route_content.get_route(
		StringName(_challenge.get("route_id", ""))
	)
	var base_value: Variant = route.get("initial_run_state", {})
	var run_state: Dictionary = (
		base_value.duplicate(true) if base_value is Dictionary else {}
	)
	var modifier := _selected_modifier()
	if modifier.is_empty():
		return run_state
	var effects: Dictionary = modifier.get("effects", {})
	run_state["corruption"] = clampi(
		int(run_state.get("corruption", 0))
		+ int(effects.get(String(EFFECT_STARTING_CORRUPTION), 0)),
		0,
		int(run_state.get("max_corruption", 10))
	)
	run_state["attention"] = clampi(
		int(run_state.get("attention", 0))
		+ int(effects.get(String(EFFECT_STARTING_ATTENTION), 0)),
		0,
		int(run_state.get("max_attention", 10))
	)
	run_state["max_spirit"] = maxi(
		0,
		int(run_state.get("max_spirit", 3))
		+ int(effects.get(String(EFFECT_STARTING_MAX_SPIRIT), 0))
	)
	run_state["spirit"] = mini(
		int(run_state.get("spirit", 3)),
		int(run_state["max_spirit"])
	)
	return run_state


func _selected_modifier() -> Dictionary:
	var modifier_id := String(_state.get("selected_modifier_id", ""))
	if modifier_id.is_empty():
		return {}
	return _modifiers_by_id.get(modifier_id, {}).duplicate(true)


func _merge_reward(target: Dictionary, delta: Dictionary) -> void:
	for key in delta:
		target[key] = int(target.get(key, 0)) + int(delta[key])


func _new_state(unlocked: bool) -> Dictionary:
	return {
		"challenge_id": String(_challenge_id),
		"phase": (
			String(PHASE_MODIFIER_SELECTION)
			if unlocked
			else String(PHASE_LOCKED)
		),
		"selected_modifier_id": "",
		"challenge_outcome": "",
		"revision": 1,
	}


func _restore_state(value: Dictionary) -> bool:
	if String(value.get("challenge_id", "")) != String(_challenge_id):
		return false
	var phase := StringName(value.get("phase", PHASE_INIT_ERROR))
	if phase not in [
		PHASE_LOCKED,
		PHASE_MODIFIER_SELECTION,
		PHASE_ACTIVE,
		PHASE_COMPLETED,
		PHASE_FAILED,
	]:
		return false
	if phase != PHASE_LOCKED and not is_unlocked():
		return false
	var selected_modifier_id := String(
		value.get("selected_modifier_id", "")
	)
	if (
		not selected_modifier_id.is_empty()
		and not _modifiers_by_id.has(selected_modifier_id)
	):
		return false
	if phase in [PHASE_ACTIVE, PHASE_COMPLETED, PHASE_FAILED]:
		if selected_modifier_id.is_empty():
			return false
	var route_state_value: Variant = value.get("route_state", {})
	if phase in [PHASE_ACTIVE, PHASE_COMPLETED, PHASE_FAILED]:
		if not route_state_value is Dictionary or route_state_value.is_empty():
			return false
		var route_content := ChallengeRouteContentPort.new(
			_route_content,
			_build_initial_run_state_for_modifier(selected_modifier_id)
		)
		_route_engine = RouteEngineScript.new(
			route_content,
			StringName(_challenge.get("route_id", ""))
		)
		var initialized := _route_engine.initialize(route_state_value)
		if not initialized.accepted:
			_route_engine = null
			return false
		_state = {
			"challenge_id": String(_challenge_id),
			"phase": String(phase),
			"selected_modifier_id": selected_modifier_id,
			"challenge_outcome": String(
				value.get("challenge_outcome", "")
			),
			"revision": maxi(1, int(value.get("revision", 1))),
		}
	else:
		_state = {
			"challenge_id": String(_challenge_id),
			"phase": String(phase),
			"selected_modifier_id": selected_modifier_id,
			"challenge_outcome": String(
				value.get("challenge_outcome", "")
			),
			"revision": maxi(1, int(value.get("revision", 1))),
		}
	return true


func _build_initial_run_state_for_modifier(
	modifier_id: String
) -> Dictionary:
	var previous := String(_state.get("selected_modifier_id", ""))
	_state["selected_modifier_id"] = modifier_id
	var result := _build_initial_run_state()
	_state["selected_modifier_id"] = previous
	return result


func _available_commands() -> Array[String]:
	var result: Array[String] = []
	match StringName(_state.get("phase", PHASE_INIT_ERROR)):
		PHASE_MODIFIER_SELECTION:
			result.append("select_modifier")
			if not String(_state.get("selected_modifier_id", "")).is_empty():
				result.append("start_challenge")
		PHASE_ACTIVE:
			result.append("forward_route")
			if _route_engine != null:
				for command in _route_engine.get_snapshot().data.get(
					"available_commands",
					[]
				):
					if not String(command) in result:
						result.append(String(command))
	return result


func _completed_challenge_ids() -> Array[String]:
	var result: Array[String] = []
	var value: Variant = _sequence_state.get(
		"completed_challenge_ids",
		[]
	)
	if value is Array:
		for challenge_id in value:
			var challenge_key := String(challenge_id)
			if not challenge_key.is_empty() and not challenge_key in result:
				result.append(challenge_key)
	return result


func _record_challenge_completion(challenge_id: String) -> void:
	var completed_ids := _completed_challenge_ids()
	if challenge_id.is_empty() or challenge_id in completed_ids:
		return
	completed_ids.append(challenge_id)
	_sequence_state["completed_challenge_ids"] = completed_ids


func _emit(event_type: StringName, event_data: Dictionary) -> void:
	_pending_events.append(ChallengeEvent.new(event_type, event_data))


func _success(
	route_result: RouteCommandResult = null
) -> ChallengeCommandResult:
	return ChallengeCommandResult.new(
		true,
		&"ok",
		_pending_events.duplicate(),
		get_snapshot(),
		route_result
	)


func _rejected(reason: StringName) -> ChallengeCommandResult:
	return ChallengeCommandResult.new(
		false,
		reason,
		[],
		get_snapshot()
	)


func _initialization_error(reason: StringName) -> ChallengeCommandResult:
	_state = {"phase": String(PHASE_INIT_ERROR)}
	_revision = 0
	return ChallengeCommandResult.new(
		false,
		reason,
		[],
		get_snapshot()
	)


func _reset_runtime() -> void:
	_challenge = {}
	_challenge_id = &""
	_modifiers_by_id.clear()
	_modifier_order.clear()
	_completion_reward.clear()
	_sequence_state = {}
	_state = {}
	_revision = 0
	_route_engine = null
	_pending_events.clear()
