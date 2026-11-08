extends Node

const ChallengeEngineScript := preload("res://src/gameplay/challenge_engine.gd")
const ChallengeCommandScript := preload("res://src/core/challenge_command.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_second_challenge_unlock_gate()
	_test_new_modifiers_change_state()
	_test_second_route_is_data_driven()
	_test_first_completion_unlocks_second()
	_test_second_challenge_completion()

	if _failures.is_empty():
		print("V07_CHALLENGE_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V07_CHALLENGE_TEST_FAILURE: %s" % failure)
	printerr(
		"V07_CHALLENGE_TESTS_FAILED checks=%d failures=%d"
		% [_checks, _failures.size()]
	)
	get_tree().quit(1)


func _test_second_challenge_unlock_gate() -> void:
	var engine := _new_engine(&"challenge.v070.broken_procession")
	var locked := engine.initialize(_sequence([]))
	_check(locked.accepted, "second challenge should initialize at sequence eight")
	_check(
		not locked.snapshot.data.unlocked
		and locked.snapshot.data.phase == "locked",
		"second challenge should stay locked before first completion"
	)
	var select := engine.submit(ChallengeCommandScript.select_modifier(
		&"modifier.obituary_echo"
	))
	_check(
		not select.accepted and select.reason_code == &"challenge_locked",
		"locked second challenge should reject modifier selection"
	)


func _test_new_modifiers_change_state() -> void:
	var obituary := _started_engine(
		&"challenge.v070.broken_procession",
		"modifier.obituary_echo"
	)
	var obituary_state: Dictionary = obituary.get_route_snapshot().data["run_state"]
	_check(
		int(obituary_state["corruption"]) == 2,
		"obituary echo should add two starting corruption"
	)
	_check(
		int(obituary.get_completion_reward().get(
			"reward.divination_tickets",
			0
		)) == 4,
		"obituary echo should increase completion tickets"
	)

	var twin := _started_engine(
		&"challenge.v070.broken_procession",
		"modifier.twin_shadow"
	)
	var twin_state: Dictionary = twin.get_route_snapshot().data["run_state"]
	_check(
		int(twin_state["attention"]) == 2,
		"twin shadow should add two starting attention"
	)
	_check(
		int(twin.get_completion_reward().get(
			"reward.ink_dart_fragments",
			0
		)) == 8,
		"twin shadow should increase fragment completion reward"
	)

	var vigil := _started_engine(
		&"challenge.v070.broken_procession",
		"modifier.ritual_vigil"
	)
	var prepared := vigil.prepare_enemy_configs([{
		"id": "boss.instance",
		"phases": [{"id": "phase.one", "at_round": 3}],
	}])
	_check(
		int(prepared[0]["phases"][0]["at_round"]) == 2,
		"ritual vigil should move enemy phases one round earlier"
	)
	var vigil_state: Dictionary = vigil.get_route_snapshot().data["run_state"]
	_check(
		int(vigil_state["max_spirit"]) == 4,
		"ritual vigil should grant one additional max spirit"
	)


func _test_second_route_is_data_driven() -> void:
	var engine := _started_engine(
		&"challenge.v070.broken_procession",
		"modifier.obituary_echo"
	)
	var nodes: Array = engine.get_route_snapshot().data["nodes"]
	_check(nodes.size() == 5, "second challenge should reuse five-node structure")
	var encounters := {}
	for node in nodes:
		encounters[String(node.get("id", ""))] = String(
			node.get("encounter_id", "")
		)
	_check(
		encounters.get("route.v070.broken.node.twin_pursuit", "")
		== "encounter.v070.twin_pursuit",
		"second challenge elite should use its data-driven encounter variant"
	)
	_check(
		encounters.get("route.v070.broken.node.mirror_baron", "")
		== "encounter.v070.broken_baron",
		"second challenge boss should use its data-driven encounter variant"
	)


func _test_first_completion_unlocks_second() -> void:
	var first := _started_engine(
		&"challenge.v060.mirror_echoes",
		"modifier.rushed_reflection"
	)
	var first_completion := _complete_first_route(first)
	_check(first_completion.accepted, "first challenge should complete")
	var completed_ids: Array = first_completion.snapshot.data.get(
		"completed_challenge_ids",
		[]
	)
	_check(
		"challenge.v060.mirror_echoes" in completed_ids,
		"first completion should be persisted in sequence state"
	)
	var second := _new_engine(&"challenge.v070.broken_procession")
	var unlocked := second.initialize(_sequence(completed_ids))
	_check(
		unlocked.snapshot.data.unlocked,
		"completed first challenge should unlock second challenge"
	)


func _test_second_challenge_completion() -> void:
	var engine := _started_engine(
		&"challenge.v070.broken_procession",
		"modifier.obituary_echo"
	)
	var completion := _complete_second_route(engine)
	_check(completion.accepted, "second challenge commands should be accepted")
	_check(
		completion.snapshot.data.phase == "completed",
		"second challenge should complete"
	)
	_check(
		completion.snapshot.data.route_id == "route.v070.broken_procession",
		"second challenge snapshot should keep its route variant id"
	)
	_check(
		"challenge.v070.broken_procession"
		in completion.snapshot.data.completed_challenge_ids,
		"second completion should be persisted"
	)
	var reward: Dictionary = completion.snapshot.data.completion_reward
	_check(
		int(reward.get("reward.divination_tickets", 0)) == 4,
		"second challenge should expose modified ticket reward"
	)


func _complete_first_route(engine: ChallengeEngine) -> ChallengeCommandResult:
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.node.first_hunt")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v070.node.first_hunt",
			&"victory",
			{"hp": 49, "corruption": 1, "attention": 1, "spirit": 3}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.node.mirror_pursuit")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v070.node.mirror_pursuit",
			&"victory",
			{"hp": 35, "corruption": 2, "attention": 2, "spirit": 2}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.node.old_house_rest")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.use_rest(&"rest.bandage")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.node.mirror_baron")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v070.node.mirror_baron",
			&"victory",
			{"hp": 20, "corruption": 4, "attention": 3, "spirit": 3}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.begin_ascension()
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step([
			"name.elin_ward",
			"name.thomas_ward",
		])
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step([
			"event.birth",
			"event.death",
			"event.burial",
		])
	))
	return engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step(["seal.inverted_eye"])
	))


func _complete_second_route(engine: ChallengeEngine) -> ChallengeCommandResult:
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.broken.node.first_hunt")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v070.broken.node.first_hunt",
			&"victory",
			{"hp": 50, "corruption": 3, "attention": 2, "spirit": 3}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.broken.node.twin_pursuit")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v070.broken.node.twin_pursuit",
			&"victory",
			{"hp": 32, "corruption": 5, "attention": 3, "spirit": 3}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.broken.node.old_house_rest")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.use_rest(&"rest.seal_echo")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v070.broken.node.mirror_baron")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v070.broken.node.mirror_baron",
			&"victory",
			{"hp": 18, "corruption": 6, "attention": 4, "spirit": 4}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.begin_ascension()
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step([
			"name.elin_ward",
			"name.thomas_ward",
		])
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step([
			"event.birth",
			"event.death",
			"event.burial",
		])
	))
	return engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step(["seal.inverted_eye"])
	))


func _started_engine(
	challenge_id: StringName,
	modifier_id: String
) -> ChallengeEngine:
	var engine := _new_engine(challenge_id)
	var initialized := engine.initialize(
		_sequence(["challenge.v060.mirror_echoes"])
	)
	_check(initialized.accepted, "challenge should initialize: %s" % challenge_id)
	var selected := engine.submit(ChallengeCommandScript.select_modifier(
		StringName(modifier_id)
	))
	_check(selected.accepted, "modifier should select: %s" % modifier_id)
	var started := engine.submit(ChallengeCommandScript.start_challenge())
	_check(started.accepted, "challenge should start: %s" % challenge_id)
	return engine


func _new_engine(challenge_id: StringName) -> ChallengeEngine:
	return ChallengeEngineScript.new(
		RouteContentFixture.new(),
		ChallengeContentFixture.new(),
		challenge_id
	)


func _sequence(completed_ids: Array) -> Dictionary:
	return {
		"pathway_id": "seer",
		"pathway_name_zh": "占卜家",
		"current_sequence": 8,
		"next_sequence": 8,
		"next_sequence_name_zh": "小丑",
		"advancement_state": "completed",
		"completed_challenge_ids": completed_ids,
	}


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


class ChallengeContentFixture:
	extends ChallengeContentPort

	var _challenges: Dictionary = {}
	var _order: Array[String] = []
	var _default_id: String = ""

	func _init() -> void:
		var parsed := _read_json("res://data/challenges/v0.7.0/challenges.json")
		_default_id = String(parsed.get("default_challenge_id", ""))
		for value in parsed.get("challenges", []):
			var challenge: Dictionary = value
			var challenge_id := String(challenge.get("id", ""))
			_challenges[challenge_id] = challenge.duplicate(true)
			_order.append(challenge_id)

	func get_default_challenge_id() -> StringName:
		return StringName(_default_id)

	func get_challenge_ids() -> Array:
		return _order.duplicate()

	func get_challenge(challenge_id: StringName) -> Dictionary:
		return _challenges.get(String(challenge_id), {}).duplicate(true)

	func _read_json(path: String) -> Dictionary:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		return parsed if parsed is Dictionary else {}


class RouteContentFixture:
	extends RouteContentPort

	var _routes: Dictionary = {}
	var _rituals: Dictionary = {}
	var _default_route_id: String = ""

	func _init() -> void:
		var routes_document := _read_json(
			"res://data/routes/v0.7.0/routes.json"
		)
		var rituals_document := _read_json(
			"res://data/rituals/v0.7.0/rituals.json"
		)
		_default_route_id = String(
			routes_document.get("default_route_id", "")
		)
		for route in routes_document.get("routes", []):
			_routes[String(route.get("id", ""))] = route.duplicate(true)
		for ritual in rituals_document.get("rituals", []):
			_rituals[String(ritual.get("id", ""))] = ritual.duplicate(true)

	func get_default_route_id() -> StringName:
		return StringName(_default_route_id)

	func get_route(route_id: StringName) -> Dictionary:
		return _routes.get(String(route_id), {}).duplicate(true)

	func get_ritual(ritual_id: StringName) -> Dictionary:
		return _rituals.get(String(ritual_id), {}).duplicate(true)

	func _read_json(path: String) -> Dictionary:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		return parsed if parsed is Dictionary else {}
