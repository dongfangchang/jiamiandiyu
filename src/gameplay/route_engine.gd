class_name RouteEngine
extends RefCounted

const PHASE_MAP: StringName = &"map"
const PHASE_BATTLE_PENDING: StringName = &"battle_pending"
const PHASE_REST_PENDING: StringName = &"rest_pending"
const PHASE_RITUAL: StringName = &"ritual"
const PHASE_COMPLETED: StringName = &"completed"
const PHASE_FAILED: StringName = &"failed"
const PHASE_INIT_ERROR: StringName = &"init_error"

const NODE_NORMAL: StringName = &"normal"
const NODE_ELITE: StringName = &"elite"
const NODE_REST: StringName = &"rest"
const NODE_BOSS: StringName = &"boss"
const NODE_RITUAL: StringName = &"ritual"

const OUTCOME_VICTORY: StringName = &"victory"
const OUTCOME_DEFEAT: StringName = &"defeat"

const ROUTE_OUTCOME_COMPLETED: StringName = &"completed"
const ROUTE_OUTCOME_FAILED: StringName = &"failed"

var _content: RouteContentPort
var _requested_route_id: StringName

var _route: Dictionary = {}
var _route_id: StringName = &""
var _nodes: Array[Dictionary] = []
var _node_by_id: Dictionary = {}
var _rest_options: Dictionary = {}
var _ritual: Dictionary = {}

var _state: Dictionary = {}
var _revision: int = 0
var _pending_events: Array[RouteEvent] = []


func _init(
	content: RouteContentPort,
	route_id: StringName = &""
) -> void:
	_content = content
	_requested_route_id = route_id


func initialize(initial_state: Dictionary = {}) -> RouteCommandResult:
	_reset_runtime()
	if _content == null:
		return _initialization_error(&"port_missing")
	if not _load_route():
		return _initialization_error(&"content_invalid")
	if initial_state.is_empty():
		_state = _new_state()
	elif not _restore_state(initial_state):
		return _initialization_error(&"state_invalid")
	_revision = maxi(1, int(_state.get("revision", 1)))
	_state["revision"] = _revision
	return RouteCommandResult.new(
		true,
		&"ok",
		[RouteEvent.new(&"RouteReady", {
			"route_id": String(_route_id),
			"available_node_id": String(_state.get("available_node_id", &"")),
		})],
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func submit(command: RouteCommand) -> RouteCommandResult:
	if command == null:
		return _rejected(&"invalid_command")
	if StringName(_state.get("phase", PHASE_INIT_ERROR)) == PHASE_INIT_ERROR:
		return _rejected(&"not_initialized")
	_pending_events.clear()
	var result: RouteCommandResult
	match command.type:
		RouteCommand.SELECT_NODE:
			result = _select_node(command.node_id)
		RouteCommand.RESOLVE_NODE:
			result = _resolve_node(
				command.node_id,
				command.battle_outcome,
				command.battle_player_state
			)
		RouteCommand.USE_REST:
			result = _use_rest(command.rest_id)
		RouteCommand.BEGIN_ASCENSION:
			result = _begin_ascension()
		RouteCommand.SUBMIT_RITUAL_STEP:
			result = _submit_ritual_step(command.ritual_selections)
		RouteCommand.REQUEST_RITUAL_HINT:
			result = _request_ritual_hint()
		RouteCommand.CANCEL_RITUAL:
			result = _cancel_ritual()
		_:
			return _rejected(&"invalid_command")
	if result.accepted:
		_revision += 1
		_state["revision"] = _revision
		result.snapshot = get_snapshot()
		result.ritual_snapshot = get_ritual_snapshot()
		result.sequence_state = get_sequence_state()
	return result


func get_snapshot() -> RouteSnapshot:
	var node_views: Array[Dictionary] = []
	var completed: Array = _state.get("completed_node_ids", [])
	var available_id := String(_state.get("available_node_id", ""))
	var selected_id := String(_state.get("selected_node_id", ""))
	for node in _nodes:
		var node_id := String(node["id"])
		var node_state := "locked"
		if node_id in completed:
			node_state = "completed"
		elif node_id == available_id:
			node_state = "available"
		node_views.append({
			"id": node_id,
			"type": String(node.get("type", "")),
			"display_name_zh": String(node.get("display_name_zh", node_id)),
			"encounter_id": String(node.get("encounter_id", "")),
			"ritual_id": String(node.get("ritual_id", "")),
			"chapter_phase": String(node.get("chapter_phase", "")),
			"narrative_beat_zh": String(node.get("narrative_beat_zh", "")),
			"investigation_goal_zh": String(node.get("investigation_goal_zh", "")),
			"reward_hint_zh": String(node.get("reward_hint_zh", "")),
			"source_zh": String(node.get("source_zh", "")),
			"state": node_state,
		})
	var current_node_id := selected_id if not selected_id.is_empty() else available_id
	var phase := StringName(_state.get("phase", PHASE_MAP))
	return RouteSnapshot.new({
		"revision": _revision,
		"route_id": String(_route_id),
		"display_name_zh": String(_route.get("display_name_zh", _route_id)),
		"chapter_id": String(_route.get("chapter_id", "")),
		"chapter_title_zh": String(_route.get("chapter_title_zh", "")),
		"chapter_phase_zh": String(_route.get("chapter_phase_zh", "")),
		"chapter_summary_zh": String(_route.get("chapter_summary_zh", "")),
		"chapter_potion_id": String(_route.get("chapter_potion_id", "")),
		"phase": String(phase),
		"current_node_id": current_node_id,
		"available_node_id": available_id,
		"selected_node_id": selected_id,
		"completed_node_ids": completed.duplicate(),
		"nodes": node_views,
		"run_state": _state.get("run_state", {}).duplicate(true),
		"rest_options": _available_rest_options(),
		"route_outcome": String(_state.get("route_outcome", "")),
		"end_reason": String(_state.get("end_reason", "")),
		"sequence": get_sequence_state().to_dictionary(),
		"ritual": get_ritual_snapshot().to_dictionary(),
		"can_begin_ascension": _can_begin_ascension(),
		"available_commands": _available_commands(),
	})


func get_ritual_snapshot() -> RitualSnapshot:
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	if ritual_state.is_empty():
		return RitualSnapshot.new({
			"status": "inactive",
			"ritual_id": "",
		})
	var ritual_id := String(ritual_state.get("ritual_id", ""))
	var ritual_definition: Dictionary = _content.get_ritual(StringName(ritual_id))
	var steps: Array = ritual_definition.get("steps", [])
	var step_index := int(ritual_state.get("step_index", 0))
	var step_count: int = steps.size()
	var status := String(ritual_state.get("status", "in_progress"))
	var snapshot := {
		"status": status,
		"ritual_id": ritual_id,
		"display_name_zh": String(
			ritual_definition.get("display_name_zh", ritual_id)
		),
		"description_zh": String(ritual_definition.get("description_zh", "")),
		"source_zh": String(ritual_definition.get("source_zh", "")),
		"step_titles": _ritual_step_titles(steps),
		"step_index": step_index,
		"step_count": step_count,
		"hints_used": int(ritual_state.get("hints_used", 0)),
		"hinted_step_indices": ritual_state.get("hinted_steps", []).duplicate(),
		"errors": int(ritual_state.get("errors", 0)),
		"hint_spirit_cost": int(
			ritual_definition.get("hint_spirit_cost", 1)
		),
		"hint_text": String(ritual_state.get("hint_text", "")),
		"corruption": int(_state.get("run_state", {}).get("corruption", 0)),
		"spirit": int(_state.get("run_state", {}).get("spirit", 0)),
		"result": String(ritual_state.get("result", "")),
	}
	if status == "in_progress" and step_index >= 0 and step_index < step_count:
		var step: Dictionary = steps[step_index]
		snapshot["step"] = {
			"id": String(step.get("id", "")),
			"type": String(step.get("type", "")),
			"title_zh": String(step.get("title_zh", "")),
			"clue_zh": String(step.get("clue_zh", "")),
			"lore_zh": String(step.get("lore_zh", "")),
			"min_selections": int(step.get("min_selections", 1)),
			"max_selections": int(step.get("max_selections", 1)),
			"options": _public_ritual_options(step.get("options", [])),
		}
	else:
		snapshot["step"] = {}
	return RitualSnapshot.new(snapshot)


func _ritual_step_titles(steps: Array) -> Array:
	var titles: Array = []
	for step_value in steps:
		if step_value is Dictionary:
			titles.append(String(step_value.get("title_zh", "")))
	return titles


func get_sequence_state() -> SequenceState:
	var sequence_source: Dictionary = _route.get("sequence", {})
	var sequence_state := String(_state.get("sequence_state", "locked"))
	var next_sequence := int(sequence_source.get("next_sequence", 8))
	var current_sequence := int(
		sequence_source.get("current_sequence", 9)
	)
	if sequence_state == "completed":
		current_sequence = next_sequence
	return SequenceState.new({
		"pathway_id": String(sequence_source.get("pathway_id", "seer")),
		"pathway_name_zh": String(
			sequence_source.get("pathway_name_zh", "占卜家")
		),
		"current_sequence": current_sequence,
		"next_sequence": next_sequence,
		"next_sequence_name_zh": String(
			sequence_source.get("next_sequence_name_zh", "小丑")
		),
		"advancement_state": sequence_state,
	})


func mark_sequence_advanced() -> void:
	_state["sequence_state"] = "completed"
	_revision += 1
	_state["revision"] = _revision


func get_available_node_id() -> StringName:
	return StringName(_state.get("available_node_id", &""))


func get_battle_player_state() -> Dictionary:
	var run_state: Dictionary = _state.get("run_state", {})
	return {
		"actor_id": "player",
		"hp": int(run_state.get("hp", 1)),
		"max_hp": int(run_state.get("max_hp", 1)),
		"block": 0,
		"spirit": int(run_state.get("spirit", 0)),
		"max_spirit": int(run_state.get("max_spirit", 0)),
		"corruption": int(run_state.get("corruption", 0)),
		"max_corruption": int(run_state.get("max_corruption", 10)),
		"attention": int(run_state.get("attention", 0)),
		"max_attention": int(run_state.get("max_attention", 10)),
		"statuses": [],
	}


func export_persistent_state() -> Dictionary:
	return _state.duplicate(true)


func _select_node(node_id: StringName) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_MAP:
		return _rejected(&"wrong_phase")
	var node: Dictionary = _node_by_id.get(String(node_id), {})
	if node.is_empty():
		return _rejected(&"unknown_node")
	if String(node_id) != String(_state.get("available_node_id", "")):
		return _rejected(&"node_not_available")
	var node_type := StringName(node.get("type", ""))
	if node_type == NODE_RITUAL:
		return _rejected(&"ascension_requires_begin")
	_state["selected_node_id"] = String(node_id)
	if node_type == NODE_REST:
		_state["phase"] = String(PHASE_REST_PENDING)
	else:
		_state["phase"] = String(PHASE_BATTLE_PENDING)
	_emit(&"RouteNodeSelected", {
		"node_id": String(node_id),
		"node_type": String(node_type),
		"encounter_id": String(node.get("encounter_id", "")),
	})
	return _success()


func _resolve_node(
	node_id: StringName,
	outcome: StringName,
	battle_player_state: Dictionary
) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_BATTLE_PENDING:
		return _rejected(&"wrong_phase")
	if String(node_id) != String(_state.get("selected_node_id", "")):
		return _rejected(&"wrong_node")
	if outcome != OUTCOME_VICTORY and outcome != OUTCOME_DEFEAT:
		return _rejected(&"invalid_battle_outcome")
	if not battle_player_state.is_empty():
		_apply_battle_player_state(battle_player_state)
	_emit(&"BattleNodeResolved", {
		"node_id": String(node_id),
		"outcome": String(outcome),
	})
	_state["selected_node_id"] = ""
	if outcome == OUTCOME_DEFEAT:
		_state["phase"] = String(PHASE_FAILED)
		_state["route_outcome"] = String(ROUTE_OUTCOME_FAILED)
		_state["end_reason"] = "battle_defeat"
		_emit(&"RouteFailed", {"reason_code": "battle_defeat"})
		return _success()
	if _corruption_limit_reached():
		_state["phase"] = String(PHASE_FAILED)
		_state["route_outcome"] = String(ROUTE_OUTCOME_FAILED)
		_state["end_reason"] = "corruption_limit"
		_emit(&"RouteFailed", {"reason_code": "corruption_limit"})
		return _success()
	_complete_node(String(node_id))
	_advance_after_completed_node()
	return _success()


func _use_rest(rest_id: StringName) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_REST_PENDING:
		return _rejected(&"wrong_phase")
	var option: Dictionary = _rest_options.get(String(rest_id), {})
	if option.is_empty():
		return _rejected(&"rest_not_available")
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	var effects: Dictionary = option.get("effects", {})
	var max_spirit_before := int(run_state.get("max_spirit", 0))
	var max_spirit_after := maxi(
		0,
		max_spirit_before + int(effects.get("max_spirit_delta", 0))
	)
	run_state["max_spirit"] = max_spirit_after
	run_state["spirit"] = clampi(
		int(run_state.get("spirit", 0)),
		0,
		max_spirit_after
	)
	run_state["hp"] = clampi(
		int(run_state.get("hp", 0)) + int(effects.get("hp_delta", 0)),
		0,
		int(run_state.get("max_hp", 1))
	)
	run_state["corruption"] = clampi(
		int(run_state.get("corruption", 0))
		+ int(effects.get("corruption_delta", 0)),
		0,
		int(run_state.get("max_corruption", 10))
	)
	run_state["attention"] = clampi(
		int(run_state.get("attention", 0))
		+ int(effects.get("attention_delta", 0)),
		0,
		int(run_state.get("max_attention", 10))
	)
	_state["run_state"] = run_state
	var node_id := String(_state.get("selected_node_id", ""))
	_emit(&"RestUsed", {
		"node_id": node_id,
		"rest_id": String(rest_id),
		"effects": effects.duplicate(true),
	})
	_state["selected_node_id"] = ""
	_complete_node(node_id)
	_advance_after_completed_node()
	return _success()


func _begin_ascension() -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_MAP:
		return _rejected(&"wrong_phase")
	if not _can_begin_ascension():
		return _rejected(&"ascension_not_available")
	var ritual_node: Dictionary = _node_by_id.get(
		String(_state.get("available_node_id", "")),
		{}
	)
	_state["selected_node_id"] = String(ritual_node.get("id", ""))
	_state["ritual_state"] = {
		"ritual_id": String(ritual_node.get("ritual_id", "")),
		"step_index": 0,
		"hints_used": 0,
		"hinted_steps": [],
		"errors": 0,
		"hint_text": "",
		"status": "in_progress",
		"result": "",
	}
	_state["phase"] = String(PHASE_RITUAL)
	_emit(&"AscensionStarted", {
		"node_id": String(ritual_node.get("id", "")),
		"ritual_id": String(ritual_node.get("ritual_id", "")),
	})
	return _success()


func _submit_ritual_step(selections: Array[String]) -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_RITUAL:
		return _rejected(&"wrong_phase")
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	var ritual_definition: Dictionary = _content.get_ritual(
		StringName(ritual_state.get("ritual_id", ""))
	)
	var steps: Array = ritual_definition.get("steps", [])
	var step_index := int(ritual_state.get("step_index", 0))
	if step_index < 0 or step_index >= steps.size():
		return _rejected(&"ritual_step_invalid")
	var step: Dictionary = steps[step_index]
	var min_selections := int(step.get("min_selections", 1))
	var max_selections := int(step.get("max_selections", 1))
	if selections.size() < min_selections or selections.size() > max_selections:
		return _rejected(&"ritual_selection_count")
	var valid_ids := {}
	for option in step.get("options", []):
		valid_ids[String(option.get("id", ""))] = true
	var seen := {}
	for selection in selections:
		if not valid_ids.has(String(selection)) or seen.has(String(selection)):
			return _rejected(&"invalid_ritual_selection")
		seen[String(selection)] = true
	if not _ritual_step_matches(step, selections):
		_apply_corruption(int(ritual_definition.get("wrong_step_corruption", 2)))
		ritual_state["errors"] = int(ritual_state.get("errors", 0)) + 1
		ritual_state["hint_text"] = ""
		_state["ritual_state"] = ritual_state
		_emit(&"RitualStepRejected", {
			"step_index": step_index,
			"step_id": String(step.get("id", "")),
			"corruption": int(_state["run_state"]["corruption"]),
		})
		if int(_state["run_state"]["corruption"]) >= int(_state["run_state"]["max_corruption"]):
			_fail_ritual(&"corruption_limit")
		return _success()
	ritual_state["step_index"] = step_index + 1
	ritual_state["hint_text"] = ""
	_state["ritual_state"] = ritual_state
	_emit(&"RitualStepAccepted", {
		"step_index": step_index,
		"step_id": String(step.get("id", "")),
	})
	if step_index + 1 >= steps.size():
		_complete_ritual()
	return _success()


func _request_ritual_hint() -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_RITUAL:
		return _rejected(&"wrong_phase")
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	var step_index := int(ritual_state.get("step_index", 0))
	var hinted_steps: Array = ritual_state.get("hinted_steps", [])
	if step_index in hinted_steps:
		return _rejected(&"hint_already_used")
	var ritual_definition: Dictionary = _content.get_ritual(
		StringName(ritual_state.get("ritual_id", ""))
	)
	var hint_cost := int(ritual_definition.get("hint_spirit_cost", 1))
	if hint_cost < 0:
		return _rejected(&"content_invalid")
	var run_state: Dictionary = _state.get("run_state", {})
	if int(run_state.get("spirit", 0)) < hint_cost:
		return _rejected(&"insufficient_spirit")
	run_state["spirit"] = int(run_state.get("spirit", 0)) - hint_cost
	_state["run_state"] = run_state
	var steps: Array = ritual_definition.get("steps", [])
	if step_index < 0 or step_index >= steps.size():
		return _rejected(&"ritual_step_invalid")
	var step: Dictionary = steps[step_index]
	ritual_state["hints_used"] = int(ritual_state.get("hints_used", 0)) + 1
	hinted_steps.append(step_index)
	ritual_state["hinted_steps"] = hinted_steps
	ritual_state["hint_text"] = String(step.get("hint_zh", ""))
	_state["ritual_state"] = ritual_state
	_emit(&"RitualHintRevealed", {
		"step_index": step_index,
		"hint_zh": String(ritual_state["hint_text"]),
		"spirit": int(run_state["spirit"]),
	})
	return _success()


func _cancel_ritual() -> RouteCommandResult:
	if StringName(_state.get("phase", "")) != PHASE_RITUAL:
		return _rejected(&"wrong_phase")
	_state["selected_node_id"] = ""
	_state["ritual_state"] = {}
	_state["phase"] = String(PHASE_MAP)
	_emit(&"AscensionCancelled", {})
	return _success()


func _complete_ritual() -> void:
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	ritual_state["status"] = "completed"
	ritual_state["result"] = "success"
	_state["ritual_state"] = ritual_state
	_state["sequence_state"] = "completed"
	var node_id := String(_state.get("selected_node_id", ""))
	_state["selected_node_id"] = ""
	_complete_node(node_id)
	_state["phase"] = String(PHASE_COMPLETED)
	_state["route_outcome"] = String(ROUTE_OUTCOME_COMPLETED)
	_state["end_reason"] = "ascension_completed"
	_emit(&"RitualCompleted", {"ritual_id": String(ritual_state["ritual_id"])})
	_emit(&"SequenceAdvanced", {
		"pathway_id": "seer",
		"from_sequence": 9,
		"to_sequence": 8,
		"sequence_name_zh": "小丑",
	})
	_emit(&"RouteCompleted", {"route_id": String(_route_id)})


func _fail_ritual(reason: StringName) -> void:
	var ritual_state: Dictionary = _state.get("ritual_state", {})
	ritual_state["status"] = "failed"
	ritual_state["result"] = String(reason)
	_state["ritual_state"] = ritual_state
	_state["phase"] = String(PHASE_FAILED)
	_state["route_outcome"] = String(ROUTE_OUTCOME_FAILED)
	_state["end_reason"] = String(reason)
	_emit(&"RitualFailed", {"reason_code": String(reason)})
	_emit(&"RouteFailed", {"reason_code": String(reason)})


func _continue_after_node(node_id: String) -> void:
	var node_index := _node_index(node_id)
	if node_index < 0:
		_state["phase"] = String(PHASE_FAILED)
		_state["end_reason"] = "route_node_missing"
		return
	if node_index + 1 >= _nodes.size():
		_state["phase"] = String(PHASE_COMPLETED)
		_state["route_outcome"] = String(ROUTE_OUTCOME_COMPLETED)
		_emit(&"RouteCompleted", {"route_id": String(_route_id)})
		return
	var next_node: Dictionary = _nodes[node_index + 1]
	_state["available_node_id"] = String(next_node.get("id", ""))
	_state["phase"] = String(PHASE_MAP)
	_emit(&"RouteNodeAvailable", {
		"node_id": String(next_node.get("id", "")),
		"node_type": String(next_node.get("type", "")),
	})


func _advance_after_completed_node() -> void:
	var completed: Array = _state.get("completed_node_ids", [])
	if completed.is_empty():
		_state["phase"] = String(PHASE_FAILED)
		return
	var last_completed := String(completed.back())
	var last_node: Dictionary = _node_by_id.get(last_completed, {})
	if StringName(last_node.get("type", "")) == NODE_BOSS:
		_state["sequence_state"] = "available"
	_continue_after_node(last_completed)


func _complete_node(node_id: String) -> void:
	var completed: Array = _state.get("completed_node_ids", [])
	if node_id.is_empty() or node_id in completed:
		return
	completed.append(node_id)
	_state["completed_node_ids"] = completed
	_emit(&"RouteNodeCompleted", {"node_id": node_id})


func _apply_battle_player_state(player_state: Dictionary) -> void:
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	for key in ["hp", "corruption", "attention", "spirit"]:
		if player_state.has(key):
			run_state[key] = int(player_state[key])
	run_state["hp"] = clampi(
		int(run_state.get("hp", 0)),
		0,
		int(run_state.get("max_hp", 1))
	)
	run_state["corruption"] = clampi(
		int(run_state.get("corruption", 0)),
		0,
		int(run_state.get("max_corruption", 10))
	)
	run_state["attention"] = clampi(
		int(run_state.get("attention", 0)),
		0,
		int(run_state.get("max_attention", 10))
	)
	_state["run_state"] = run_state


func _corruption_limit_reached() -> bool:
	var run_state: Dictionary = _state.get("run_state", {})
	return int(run_state.get("corruption", 0)) >= int(
		run_state.get("max_corruption", 1)
	)


func _apply_corruption(amount: int) -> void:
	var run_state: Dictionary = _state.get("run_state", {}).duplicate(true)
	var before := int(run_state.get("corruption", 0))
	run_state["corruption"] = clampi(
		before + amount,
		0,
		int(run_state.get("max_corruption", 10))
	)
	_state["run_state"] = run_state
	_emit(&"RiskChanged", {
		"risk_id": "corruption",
		"before": before,
		"after": int(run_state["corruption"]),
		"reason_code": "ritual_error",
	})


func _ritual_step_matches(step: Dictionary, selections: Array[String]) -> bool:
	var step_type := StringName(step.get("type", ""))
	if step_type == &"select_ids":
		var expected: Array = step.get("correct_ids", [])
		if expected.size() != selections.size():
			return false
		var actual_sorted := selections.duplicate()
		var expected_sorted: Array[String] = []
		for value in expected:
			expected_sorted.append(String(value))
		actual_sorted.sort()
		expected_sorted.sort()
		return actual_sorted == expected_sorted
	if step_type == &"ordered_ids":
		var expected_order: Array = step.get("correct_order", [])
		if expected_order.size() != selections.size():
			return false
		for index in range(selections.size()):
			if String(selections[index]) != String(expected_order[index]):
				return false
		return true
	if step_type == &"select_id":
		return selections.size() == 1 and String(selections[0]) == String(
			step.get("correct_id", "")
		)
	return false


func _public_ritual_options(options_value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not options_value is Array:
		return result
	for value in options_value:
		if not value is Dictionary:
			continue
		result.append({
			"id": String(value.get("id", "")),
			"display_name_zh": String(
				value.get("display_name_zh", value.get("id", ""))
			),
		})
	return result


func _available_rest_options() -> Array[Dictionary]:
	if StringName(_state.get("phase", "")) != PHASE_REST_PENDING:
		return []
	var result: Array[Dictionary] = []
	for option in _rest_options.values():
		result.append(option.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return result


func _can_begin_ascension() -> bool:
	if StringName(_state.get("phase", "")) != PHASE_MAP:
		return false
	var node: Dictionary = _node_by_id.get(
		String(_state.get("available_node_id", "")),
		{}
	)
	return (
		not node.is_empty()
		and StringName(node.get("type", "")) == NODE_RITUAL
		and String(_state.get("sequence_state", "")) == "available"
	)


func _available_commands() -> Array[String]:
	var result: Array[String] = []
	match StringName(_state.get("phase", PHASE_INIT_ERROR)):
		PHASE_MAP:
			result.append("select_node")
			if _can_begin_ascension():
				result.append("begin_ascension")
		PHASE_BATTLE_PENDING:
			result.append("resolve_node")
		PHASE_REST_PENDING:
			result.append("use_rest")
		PHASE_RITUAL:
			result.append("submit_ritual_step")
			result.append("request_ritual_hint")
			result.append("cancel_ritual")
	return result


func _load_route() -> bool:
	var route_id := _requested_route_id
	if route_id.is_empty():
		route_id = _content.get_default_route_id()
	if route_id.is_empty():
		return false
	var route_value: Variant = _content.get_route(route_id)
	if not route_value is Dictionary or route_value.is_empty():
		return false
	_route = route_value.duplicate(true)
	_route_id = StringName(_route.get("id", ""))
	if _route_id != route_id:
		return false
	var nodes_value: Variant = _route.get("nodes")
	if not nodes_value is Array or nodes_value.size() < 3 or nodes_value.size() > 12:
		return false
	var seen_types: Dictionary = {}
	for value in nodes_value:
		if not value is Dictionary:
			return false
		var node: Dictionary = value.duplicate(true)
		var node_id := String(node.get("id", ""))
		if node_id.is_empty() or _node_by_id.has(node_id):
			return false
		var node_type := StringName(node.get("type", ""))
		if node_type not in [NODE_NORMAL, NODE_ELITE, NODE_REST, NODE_BOSS, NODE_RITUAL]:
			return false
		seen_types[node_type] = true
		if node.get("type") in ["normal", "elite", "boss"]:
			if String(node.get("encounter_id", "")).is_empty():
				return false
		if node.get("type") == "ritual":
			var ritual_id := String(node.get("ritual_id", ""))
			_ritual = _content.get_ritual(StringName(ritual_id)).duplicate(true)
			if _ritual.is_empty() or not _validate_ritual(_ritual):
				return false
		_nodes.append(node)
		_node_by_id[node_id] = node
	if not seen_types.has(NODE_RITUAL) or not seen_types.has(NODE_BOSS):
		return false
	var options_value: Variant = _route.get("rest_options")
	if not options_value is Array or options_value.size() < 2:
		return false
	for value in options_value:
		if not value is Dictionary:
			return false
		var option: Dictionary = value.duplicate(true)
		var option_id := String(option.get("id", ""))
		if option_id.is_empty() or _rest_options.has(option_id):
			return false
		_rest_options[option_id] = option
	return true


func _validate_ritual(ritual: Dictionary) -> bool:
	var steps_value: Variant = ritual.get("steps")
	if not steps_value is Array or steps_value.size() != 3:
		return false
	for value in steps_value:
		if not value is Dictionary:
			return false
		var step: Dictionary = value
		var step_type := StringName(step.get("type", ""))
		if step_type not in [&"select_ids", &"ordered_ids", &"select_id"]:
			return false
		var options_value: Variant = step.get("options")
		if not options_value is Array or options_value.size() < 2:
			return false
		var option_ids := {}
		for option_value in options_value:
			if not option_value is Dictionary:
				return false
			var option_id := String(option_value.get("id", ""))
			if option_id.is_empty() or option_ids.has(option_id):
				return false
			option_ids[option_id] = true
		if step_type == &"select_ids":
			var correct_ids: Variant = step.get("correct_ids")
			if not correct_ids is Array or correct_ids.size() != int(
				step.get("min_selections", 1)
			):
				return false
			for id_value in correct_ids:
				if not option_ids.has(String(id_value)):
					return false
		elif step_type == &"ordered_ids":
			var correct_order: Variant = step.get("correct_order")
			if not correct_order is Array or correct_order.size() != option_ids.size():
				return false
			for id_value in correct_order:
				if not option_ids.has(String(id_value)):
					return false
		elif not option_ids.has(String(step.get("correct_id", ""))):
			return false
	return true


func _new_state() -> Dictionary:
	var run_state_value: Variant = _route.get("initial_run_state", {})
	var run_state: Dictionary = (
		run_state_value.duplicate(true)
		if run_state_value is Dictionary
		else {}
	)
	run_state["hp"] = maxi(0, int(run_state.get("hp", 54)))
	run_state["max_hp"] = maxi(1, int(run_state.get("max_hp", 54)))
	run_state["spirit"] = maxi(0, int(run_state.get("spirit", 3)))
	run_state["max_spirit"] = maxi(0, int(run_state.get("max_spirit", 3)))
	run_state["corruption"] = maxi(0, int(run_state.get("corruption", 0)))
	run_state["max_corruption"] = maxi(1, int(run_state.get("max_corruption", 10)))
	run_state["attention"] = maxi(0, int(run_state.get("attention", 0)))
	run_state["max_attention"] = maxi(1, int(run_state.get("max_attention", 10)))
	run_state["hp"] = mini(int(run_state["hp"]), int(run_state["max_hp"]))
	run_state["corruption"] = mini(
		int(run_state["corruption"]),
		int(run_state["max_corruption"])
	)
	run_state["attention"] = mini(
		int(run_state["attention"]),
		int(run_state["max_attention"])
	)
	return {
		"route_id": String(_route_id),
		"phase": String(PHASE_MAP),
		"available_node_id": String(_nodes[0]["id"]),
		"selected_node_id": "",
		"completed_node_ids": [],
		"run_state": run_state,
		"ritual_state": {},
		"sequence_state": "locked",
		"route_outcome": "",
		"end_reason": "",
		"revision": 1,
	}


func _restore_state(value: Dictionary) -> bool:
	if not value.get("run_state") is Dictionary:
		return false
	var restored := value.duplicate(true)
	var phase := StringName(restored.get("phase", PHASE_MAP))
	if phase not in [
		PHASE_MAP,
		PHASE_BATTLE_PENDING,
		PHASE_REST_PENDING,
		PHASE_RITUAL,
		PHASE_COMPLETED,
		PHASE_FAILED,
	]:
		return false
	var completed_value: Variant = restored.get("completed_node_ids", [])
	if not completed_value is Array:
		return false
	var completed: Array = []
	for node_id_value in completed_value:
		var node_id := String(node_id_value)
		if not _node_by_id.has(node_id) or node_id in completed:
			return false
		completed.append(node_id)
	var available_id := String(restored.get("available_node_id", ""))
	var selected_id := String(restored.get("selected_node_id", ""))
	if not available_id.is_empty() and not _node_by_id.has(available_id):
		return false
	if not selected_id.is_empty() and not _node_by_id.has(selected_id):
		return false
	if phase in [PHASE_BATTLE_PENDING, PHASE_REST_PENDING, PHASE_RITUAL]:
		if selected_id.is_empty():
			return false
	if not _validate_run_state(restored["run_state"]):
		return false
	var ritual_state: Variant = restored.get("ritual_state", {})
	if phase == PHASE_RITUAL:
		if not ritual_state is Dictionary or ritual_state.is_empty():
			return false
		if not _content.get_ritual(
			StringName(ritual_state.get("ritual_id", ""))
		):
			return false
	restored["phase"] = String(phase)
	restored["completed_node_ids"] = completed
	_state = restored
	return true


func _validate_run_state(run_state: Dictionary) -> bool:
	var required := [
		"hp",
		"max_hp",
		"spirit",
		"max_spirit",
		"corruption",
		"max_corruption",
		"attention",
		"max_attention",
	]
	for key in required:
		if not run_state.has(key):
			return false
	if int(run_state["max_hp"]) <= 0 or int(run_state["hp"]) < 0:
		return false
	if int(run_state["hp"]) > int(run_state["max_hp"]):
		return false
	if int(run_state["max_spirit"]) < 0 or int(run_state["spirit"]) < 0:
		return false
	if int(run_state["max_corruption"]) <= 0 or int(run_state["corruption"]) < 0:
		return false
	if int(run_state["corruption"]) > int(run_state["max_corruption"]):
		return false
	if int(run_state["max_attention"]) <= 0 or int(run_state["attention"]) < 0:
		return false
	if int(run_state["attention"]) > int(run_state["max_attention"]):
		return false
	return true


func _node_index(node_id: String) -> int:
	for index in range(_nodes.size()):
		if String(_nodes[index].get("id", "")) == node_id:
			return index
	return -1


func _emit(event_type: StringName, event_data: Dictionary) -> void:
	_pending_events.append(RouteEvent.new(event_type, event_data))


func _success() -> RouteCommandResult:
	return RouteCommandResult.new(
		true,
		&"ok",
		_pending_events.duplicate(),
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func _rejected(reason: StringName) -> RouteCommandResult:
	return RouteCommandResult.new(
		false,
		reason,
		[],
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func _initialization_error(reason: StringName) -> RouteCommandResult:
	_state = {"phase": String(PHASE_INIT_ERROR)}
	_revision = 0
	return RouteCommandResult.new(
		false,
		reason,
		[],
		get_snapshot(),
		get_ritual_snapshot(),
		get_sequence_state()
	)


func _reset_runtime() -> void:
	_route = {}
	_route_id = &""
	_nodes.clear()
	_node_by_id.clear()
	_rest_options.clear()
	_ritual.clear()
	_state = {}
	_revision = 0
	_pending_events.clear()
