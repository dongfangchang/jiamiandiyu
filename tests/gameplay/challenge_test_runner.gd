extends Node

const ChallengeEngineScript := preload("res://src/gameplay/challenge_engine.gd")
const ChallengeCommandScript := preload("res://src/core/challenge_command.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")

const CHALLENGE_PATH := "res://data/challenges/v0.6.0/challenges.json"

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_formal_content_references()
	_test_unlock_and_modifier_selection()
	_test_three_modifiers_change_decisions()
	_test_tainted_margins_requires_rest_control()
	_test_full_challenge_completion_and_reward()
	_test_failure_preserves_external_progression()
	_test_active_state_round_trip()
	_test_repeatable_command_sequence()

	if _failures.is_empty():
		print("CHALLENGE_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("CHALLENGE_TEST_FAILURE: %s" % failure)
	printerr(
		"CHALLENGE_TESTS_FAILED checks=%d failures=%d"
		% [_checks, _failures.size()]
	)
	get_tree().quit(1)


func _test_formal_content_references() -> void:
	var document := _load_json(CHALLENGE_PATH)
	var challenge := _first_challenge(document)
	_check(
		String(challenge.get("id", "")) == "challenge.v060.mirror_echoes",
		"formal challenge should expose a stable id"
	)
	var route_document := _load_json("res://data/routes/v0.5.0/routes.json")
	var route_ids := {}
	for route in route_document.get("routes", []):
		route_ids[String(route.get("id", ""))] = true
	_check(
		route_ids.has(String(challenge.get("route_id", ""))),
		"challenge route reference should exist"
	)
	var progression := _load_json("res://data/cards/v0.4.0/progression.json")
	var reward_ids := {}
	for reward in progression.get("reward_options", []):
		reward_ids[String(reward.get("id", ""))] = true
	var encounter_document := _load_json(
		"res://data/encounters/v0.5.0/encounters.json"
	)
	var encounter_card_ids := {}
	for encounter in encounter_document.get("encounters", []):
		for definition_id in encounter.get("deck_definition_ids", []):
			encounter_card_ids[String(definition_id)] = true
	for reward_id in challenge.get("completion_reward", {}):
		_check(
			reward_ids.has(String(reward_id)),
			"challenge reward should reference an existing reward id: %s" % reward_id
		)
	var modifiers: Array = challenge.get("modifiers", [])
	_check(modifiers.size() >= 3, "challenge should expose at least three modifiers")
	var seen := {}
	for value in modifiers:
		var modifier: Dictionary = value
		var modifier_id := String(modifier.get("id", ""))
		_check(not modifier_id.is_empty(), "modifier id should be stable")
		_check(not seen.has(modifier_id), "modifier ids should be unique")
		seen[modifier_id] = true
		_check(
			not modifier.get("effects", {}).is_empty(),
			"modifier should define an effect"
		)
		var effects: Dictionary = modifier.get("effects", {})
		for reward_id in effects.get("completion_reward", {}):
			_check(
				reward_ids.has(String(reward_id)),
				"modifier reward should reference an existing reward id: %s" % reward_id
			)
		for definition_id in effects.get("remove_definition_ids", []):
			_check(
				encounter_card_ids.has(String(definition_id)),
				"removed card should exist in a formal encounter: %s" % definition_id
			)


func _test_unlock_and_modifier_selection() -> void:
	var engine := _new_engine()
	var locked := engine.initialize(_sequence(9, "locked"))
	_check(locked.accepted, "locked challenge should initialize without pretending success")
	_check(
		locked.snapshot.data["phase"] == "locked"
		and not locked.snapshot.data["unlocked"],
		"sequence nine should keep challenge locked"
	)
	var locked_select := engine.submit(
		ChallengeCommandScript.select_modifier(&"modifier.rushed_reflection")
	)
	_check(
		not locked_select.accepted
		and locked_select.reason_code == &"challenge_locked",
		"locked challenge should reject modifier selection with a stable reason"
	)

	var unlocked_engine := _new_engine()
	var unlocked := unlocked_engine.initialize(_sequence(8, "completed"))
	_check(unlocked.accepted, "sequence eight should unlock the challenge")
	_check(
		unlocked.snapshot.data["phase"] == "modifier_selection",
		"unlocked challenge should wait for modifier selection"
	)
	var start_without_modifier := unlocked_engine.submit(
		ChallengeCommandScript.start_challenge()
	)
	_check(
		not start_without_modifier.accepted
		and start_without_modifier.reason_code == &"modifier_required",
		"start should require an explicit modifier"
	)
	var unknown := unlocked_engine.submit(
		ChallengeCommandScript.select_modifier(&"modifier.unknown")
	)
	_check(
		not unknown.accepted and unknown.reason_code == &"unknown_modifier",
		"unknown modifier should be rejected"
	)
	var selected := unlocked_engine.submit(
		ChallengeCommandScript.select_modifier(&"modifier.rushed_reflection")
	)
	_check(selected.accepted, "known modifier should be selectable")
	_check(
		"start_challenge" in selected.snapshot.data["available_commands"],
		"selected modifier should expose start command"
	)


func _test_three_modifiers_change_decisions() -> void:
	var rushed := _started_engine("modifier.rushed_reflection")
	var enemy_configs := [{
		"id": "boss.instance",
		"phases": [
			{"id": "phase.one", "at_round": 3},
			{"id": "phase.two", "at_round": 6},
		],
	}]
	var prepared: Array[Dictionary] = rushed.prepare_enemy_configs(enemy_configs)
	_check(
		int(prepared[0]["phases"][0]["at_round"]) == 1
		and int(prepared[0]["phases"][1]["at_round"]) == 4,
		"rushed reflection should move phases two rounds earlier"
	)
	_check(
		int(enemy_configs[0]["phases"][0]["at_round"]) == 3,
		"enemy preparation must not mutate source content"
	)

	var tainted := _started_engine("modifier.tainted_margins")
	var run_state: Dictionary = tainted.get_route_snapshot().data["run_state"]
	_check(
		int(run_state["corruption"]) == 4
		and int(run_state["attention"]) == 1,
		"tainted margins should change the starting risk profile"
	)

	var fractured := _started_engine("modifier.fractured_deck")
	var source_deck := [
		"card.skill.ink_dart",
		"card.skill.paper_guard",
		"card.skill.paper_guard",
		"card.skill.focus",
	]
	var filtered := fractured.build_battle_deck(source_deck)
	_check(
		not "card.skill.paper_guard" in filtered
		and filtered.size() == 2,
		"fractured deck should remove every restricted card"
	)
	var reward: Dictionary = fractured.get_completion_reward()
	_check(
		int(reward.get("reward.divination_tickets", 0)) == 3,
		"fractured deck should add its deterministic completion ticket"
	)


func _test_tainted_margins_requires_rest_control() -> void:
	var failed_engine := _started_engine("modifier.tainted_margins")
	_advance_tainted_to_boss(failed_engine, &"rest.bandage")
	var failed := failed_engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.mirror_baron",
			&"victory",
			{"hp": 20, "corruption": 8, "attention": 3, "spirit": 3}
		)
	))
	_check(failed.accepted, "tainted boss resolution should be accepted")
	_check(
		failed.snapshot.data["phase"] == "failed"
		and failed.snapshot.data["route"]["route_outcome"] == "failed",
		"tainted margins should fail at corruption limit when rest does not cleanse"
	)

	var prepared_engine := _started_engine("modifier.tainted_margins")
	_advance_tainted_to_boss(prepared_engine, &"rest.seal_echo")
	var boss := prepared_engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.mirror_baron",
			&"victory",
			{"hp": 20, "corruption": 6, "attention": 4, "spirit": 4}
		)
	))
	_check(boss.accepted, "cleansed tainted challenge should reach the boss")
	_check(
		int(boss.snapshot.data["route"]["run_state"]["corruption"]) == 8,
		"tainted battle pressure should add two corruption after boss victory"
	)
	_check(
		boss.snapshot.data["phase"] == "active",
		"cleansed tainted challenge should remain alive for ascension"
	)
	prepared_engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.begin_ascension()
	))
	prepared_engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step([
			"name.elin_ward",
			"name.thomas_ward",
		])
	))
	prepared_engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step([
			"event.birth",
			"event.death",
			"event.burial",
		])
	))
	var completed := prepared_engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.submit_ritual_step(["seal.inverted_eye"])
	))
	_check(
		completed.snapshot.data["phase"] == "completed",
		"tainted challenge should remain completable after using cleansing rest"
	)


func _advance_tainted_to_boss(
	engine: ChallengeEngine,
	rest_id: StringName
) -> void:
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.first_hunt")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.first_hunt",
			&"victory",
			{"hp": 49, "corruption": 4, "attention": 1, "spirit": 3}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.mirror_pursuit")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.mirror_pursuit",
			&"victory",
			{"hp": 35, "corruption": 6, "attention": 2, "spirit": 2}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.old_house_rest")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.use_rest(rest_id)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.mirror_baron")
	))


func _test_full_challenge_completion_and_reward() -> void:
	var engine := _started_engine("modifier.rushed_reflection")
	var completion := _complete_route(engine)
	_check(completion.accepted, "full challenge route should finish")
	_check(
		completion.snapshot.data["phase"] == "completed",
		"completed route should close challenge"
	)
	_check(
		completion.snapshot.data["challenge_outcome"] == "completed",
		"challenge outcome should be completed"
	)
	_check(
		int(completion.snapshot.data["sequence"]["current_sequence"]) == 8,
		"challenge should preserve the sequence eight progression"
	)
	var reward: Dictionary = completion.snapshot.data["completion_reward"]
	_check(
		int(reward.get("reward.divination_tickets", 0)) == 2
		and int(reward.get("reward.ink_dart_fragments", 0)) == 4,
		"challenge completion should expose deterministic rewards"
	)
	var completed_event := false
	for event in completion.events:
		if event.type == &"ChallengeCompleted":
			completed_event = true
	_check(completed_event, "completion should emit ChallengeCompleted")
	var repeat := engine.submit(
		ChallengeCommandScript.forward_route(RouteCommandScript.begin_ascension())
	)
	_check(
		not repeat.accepted and repeat.reason_code == &"wrong_phase",
		"completed challenge should reject more route commands"
	)


func _test_failure_preserves_external_progression() -> void:
	var engine := _started_engine("modifier.tainted_margins")
	var collection := {
		"card.skill.ink_dart": {"copies": 1, "level": 2, "fragments": 7}
	}
	var before := collection.duplicate(true)
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.first_hunt")
	))
	var failed := engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.first_hunt",
			&"defeat",
			{"hp": 0, "corruption": 5, "attention": 4, "spirit": 0}
		)
	))
	_check(failed.accepted, "battle defeat should resolve challenge")
	_check(
		failed.snapshot.data["phase"] == "failed"
		and failed.snapshot.data["challenge_outcome"] == "failed",
		"battle defeat should fail challenge"
	)
	_check(
		collection == before,
		"challenge domain must not delete external collection on failure"
	)


func _test_active_state_round_trip() -> void:
	var engine := _started_engine("modifier.fractured_deck")
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.first_hunt")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.first_hunt",
			&"victory",
			{"hp": 50, "corruption": 1, "attention": 1, "spirit": 3}
		)
	))
	var saved := engine.export_persistent_state()
	var restored_engine := _new_engine()
	var restored := restored_engine.initialize(_sequence(8, "completed"), saved)
	_check(restored.accepted, "active challenge state should restore")
	_check(
		restored.snapshot.data["selected_modifier_id"]
		== "modifier.fractured_deck",
		"restore should keep selected modifier"
	)
	_check(
		restored.snapshot.data["route"]["available_node_id"]
		== "route.v050.node.mirror_pursuit",
		"restore should resume at the next confirmed route node"
	)
	_check(
		int(restored.snapshot.data["route"]["run_state"]["hp"]) == 50,
		"restore should preserve route resources"
	)


func _test_repeatable_command_sequence() -> void:
	var first := _started_engine("modifier.tainted_margins")
	var first_completion := _complete_route(first)
	var second := _started_engine("modifier.tainted_margins")
	var second_completion := _complete_route(second)
	_check(
		JSON.stringify(first_completion.snapshot.data)
		== JSON.stringify(second_completion.snapshot.data),
		"same challenge commands should produce the same final snapshot"
	)


func _complete_route(engine: ChallengeEngine) -> ChallengeCommandResult:
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.first_hunt")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.first_hunt",
			&"victory",
			{"hp": 49, "corruption": 1, "attention": 1, "spirit": 3}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.mirror_pursuit")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.mirror_pursuit",
			&"victory",
			{"hp": 35, "corruption": 2, "attention": 2, "spirit": 2}
		)
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.old_house_rest")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.use_rest(&"rest.bandage")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.select_node(&"route.v050.node.mirror_baron")
	))
	engine.submit(ChallengeCommandScript.forward_route(
		RouteCommandScript.resolve_node(
			&"route.v050.node.mirror_baron",
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


func _started_engine(modifier_id: String) -> ChallengeEngine:
	var engine := _new_engine()
	var initialized := engine.initialize(_sequence(8, "completed"))
	_check(initialized.accepted, "challenge engine should initialize")
	var selected := engine.submit(
		ChallengeCommandScript.select_modifier(StringName(modifier_id))
	)
	_check(selected.accepted, "modifier should select: %s" % modifier_id)
	var started := engine.submit(ChallengeCommandScript.start_challenge())
	_check(started.accepted, "challenge should start: %s" % modifier_id)
	return engine


func _new_engine() -> ChallengeEngine:
	return ChallengeEngineScript.new(
		RouteTestContent.new(),
		ChallengeTestContent.new()
	)


func _sequence(current_sequence: int, advancement_state: String) -> Dictionary:
	return {
		"pathway_id": "seer",
		"pathway_name_zh": "占卜家",
		"current_sequence": current_sequence,
		"next_sequence": 8,
		"next_sequence_name_zh": "小丑",
		"advancement_state": advancement_state,
	}


func _first_challenge(document: Dictionary) -> Dictionary:
	var values: Array = document.get("challenges", [])
	return values[0] if not values.is_empty() else {}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "JSON should be readable: %s" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_check(parsed is Dictionary, "JSON should parse as object: %s" % path)
	return parsed if parsed is Dictionary else {}


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


class ChallengeTestContent:
	extends ChallengeContentPort

	var _challenges: Dictionary = {}
	var _default_id: String = ""

	func _init() -> void:
		var file := FileAccess.open(
			"res://data/challenges/v0.6.0/challenges.json",
			FileAccess.READ
		)
		if file == null:
			return
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if not parsed is Dictionary:
			return
		_default_id = String(parsed.get("default_challenge_id", ""))
		for value in parsed.get("challenges", []):
			var challenge: Dictionary = value
			_challenges[String(challenge.get("id", ""))] = challenge.duplicate(true)

	func get_default_challenge_id() -> StringName:
		return StringName(_default_id)

	func get_challenge(challenge_id: StringName) -> Dictionary:
		return _challenges.get(String(challenge_id), {}).duplicate(true)


class RouteTestContent:
	extends RouteContentPort

	var _routes: Dictionary = {}
	var _rituals: Dictionary = {}
	var _default_route_id: String = ""

	func _init() -> void:
		var routes_document := _read_json("res://data/routes/v0.5.0/routes.json")
		var rituals_document := _read_json("res://data/rituals/v0.5.0/rituals.json")
		_default_route_id = String(routes_document.get("default_route_id", ""))
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
