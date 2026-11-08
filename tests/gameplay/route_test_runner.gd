extends Node

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_formal_route_references()
	_test_route_content_and_initial_snapshot()
	_test_full_route_and_ascension()
	_test_rest_choices()
	_test_ritual_cancel_hint_and_failure()
	_test_battle_defeat_ends_route()
	_test_state_round_trip()
	_test_boss_phase_behavior()

	if _failures.is_empty():
		print("ROUTE_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("ROUTE_TEST_FAILURE: %s" % failure)
	printerr(
		"ROUTE_TESTS_FAILED checks=%d failures=%d"
		% [_checks, _failures.size()]
	)
	get_tree().quit(1)


func _test_formal_route_references() -> void:
	var routes_document := _load_json("res://data/routes/v0.5.0/routes.json")
	var encounters_document := _load_json(
		"res://data/encounters/v0.5.0/encounters.json"
	)
	var enemies_document := _load_json("res://data/enemies/v0.5.0/enemies.json")
	var rituals_document := _load_json(
		"res://data/rituals/v0.5.0/rituals.json"
	)
	var encounter_ids := {}
	for encounter in encounters_document.get("encounters", []):
		encounter_ids[String(encounter.get("id", ""))] = encounter
	var enemy_ids := {}
	for enemy in enemies_document.get("enemies", []):
		enemy_ids[String(enemy.get("id", ""))] = enemy
	var ritual_ids := {}
	for ritual in rituals_document.get("rituals", []):
		ritual_ids[String(ritual.get("id", ""))] = ritual
	var routes: Array = routes_document.get("routes", [])
	_check(routes.size() == 1, "v0.5 should define one fixed route")
	if routes.is_empty():
		return
	var route: Dictionary = routes[0]
	var nodes: Array = route.get("nodes", [])
	_check(nodes.size() == 5, "formal route should define five nodes")
	for node_value in nodes:
		var node: Dictionary = node_value
		if node.has("encounter_id"):
			_check(
				encounter_ids.has(String(node["encounter_id"])),
				"route encounter reference should exist: %s" % node["encounter_id"]
			)
		if node.has("ritual_id"):
			_check(
				ritual_ids.has(String(node["ritual_id"])),
				"route ritual reference should exist: %s" % node["ritual_id"]
			)
	for encounter_value in encounter_ids.values():
		var encounter: Dictionary = encounter_value
		for slot_value in encounter.get("enemy_slots", []):
			var slot: Dictionary = slot_value
			_check(
				enemy_ids.has(String(slot.get("enemy_id", ""))),
				"encounter enemy reference should exist: %s" % slot.get("enemy_id", "")
			)
	_check(enemy_ids.has("enemy.mirror_hound_echo"), "elite enemy should exist")
	_check(enemy_ids.has("enemy.mirror_baron"), "boss enemy should exist")
	if enemy_ids.has("enemy.mirror_baron"):
		var boss: Dictionary = enemy_ids["enemy.mirror_baron"]
		_check(
			boss.get("phases", []).size() >= 2,
			"boss should define at least two unique phases"
		)


func _test_route_content_and_initial_snapshot() -> void:
	var content := RouteTestContent.new()
	_check(
		content.get_default_route_id() == &"route.v050.first_case",
		"formal route should have the expected default id"
	)
	var engine := RouteEngineScript.new(content)
	var initialized: RouteCommandResult = engine.initialize()
	_check(initialized.accepted, "route should initialize from formal content")
	var snapshot: Dictionary = initialized.snapshot.data
	_check(snapshot["phase"] == "map", "route should start on the map")
	_check(
		snapshot["available_node_id"] == "route.v050.node.first_hunt",
		"first hunt should be the first available node"
	)
	_check(
		"select_node" in snapshot["available_commands"],
		"map snapshot should expose select_node"
	)
	_check(snapshot["nodes"].size() == 5, "route should expose five fixed nodes")
	_check(
		snapshot["sequence"]["advancement_state"] == "locked",
		"ascension should be locked before the boss"
	)
	_check(
		not initialized.ritual_snapshot.data.get("step", {}).is_empty()
		== false,
		"ritual should be inactive before the boss"
	)


func _test_full_route_and_ascension() -> void:
	var content := RouteTestContent.new()
	var engine := RouteEngineScript.new(content)
	var initialized: RouteCommandResult = engine.initialize()
	_check(initialized.accepted, "full route engine should initialize")

	var select_first := engine.submit(
		RouteCommand.select_node(&"route.v050.node.first_hunt")
	)
	_check(select_first.accepted, "first battle node should be selectable")
	_check(
		select_first.snapshot.data["phase"] == "battle_pending",
		"battle node should enter battle_pending"
	)
	var resolve_first := engine.submit(
		RouteCommand.resolve_node(
			&"route.v050.node.first_hunt",
			&"victory",
			{"hp": 49, "corruption": 1, "attention": 1, "spirit": 3}
		)
	)
	_check(resolve_first.accepted, "first victory should resolve")
	_check(
		resolve_first.snapshot.data["available_node_id"]
		== "route.v050.node.mirror_pursuit",
		"first victory should unlock the elite node"
	)
	_check(
		int(resolve_first.snapshot.data["run_state"]["hp"]) == 49,
		"battle end state should carry into the route"
	)

	engine.submit(RouteCommand.select_node(
		&"route.v050.node.mirror_pursuit"
	))
	var resolve_elite := engine.submit(
		RouteCommand.resolve_node(
			&"route.v050.node.mirror_pursuit",
			&"victory",
			{"hp": 31, "corruption": 3, "attention": 2, "spirit": 2}
		)
	)
	_check(resolve_elite.accepted, "elite victory should resolve")
	_check(
		resolve_elite.snapshot.data["available_node_id"]
		== "route.v050.node.old_house_rest",
		"elite victory should unlock rest"
	)

	engine.submit(RouteCommand.select_node(
		&"route.v050.node.old_house_rest"
	))
	var rest_result := engine.submit(RouteCommand.use_rest(&"rest.bandage"))
	_check(rest_result.accepted, "rest should be usable")
	_check(
		int(rest_result.snapshot.data["run_state"]["hp"]) == 43,
		"bandage rest should restore health"
	)
	_check(
		rest_result.snapshot.data["available_node_id"]
		== "route.v050.node.mirror_baron",
		"rest should unlock the boss"
	)

	engine.submit(RouteCommand.select_node(
		&"route.v050.node.mirror_baron"
	))
	var boss_result := engine.submit(
		RouteCommand.resolve_node(
			&"route.v050.node.mirror_baron",
			&"victory",
			{"hp": 20, "corruption": 4, "attention": 3, "spirit": 3}
		)
	)
	_check(boss_result.accepted, "boss victory should resolve")
	_check(
		boss_result.snapshot.data["available_node_id"]
		== "route.v050.node.ascension",
		"boss victory should unlock ascension"
	)
	_check(
		boss_result.sequence_state.data["advancement_state"] == "available",
		"boss victory should make sequence advancement available"
	)
	_check(
		"begin_ascension" in boss_result.snapshot.data["available_commands"],
		"ritual availability should be exposed as a command"
	)
	var ritual_select := engine.submit(
		RouteCommand.select_node(&"route.v050.node.ascension")
	)
	_check(
		not ritual_select.accepted
		and ritual_select.reason_code == &"ascension_requires_begin",
		"ritual node should require BeginAscension"
	)
	var begin := engine.submit(RouteCommand.begin_ascension())
	_check(begin.accepted, "ascension should begin")
	_check(
		begin.ritual_snapshot.data["step"]["type"] == "select_ids",
		"ritual should start with the name step"
	)
	_check(
		"submit_ritual_step" in begin.snapshot.data["available_commands"],
		"ritual snapshot should expose ritual commands"
	)
	_check(
		not JSON.stringify(begin.ritual_snapshot.data).contains("correct"),
		"public ritual snapshot must not expose answer keys"
	)
	var correct_names := engine.submit(
		RouteCommand.submit_ritual_step([
			"name.thomas_ward",
			"name.elin_ward",
		])
	)
	_check(correct_names.accepted, "unordered correct names should be accepted")
	var correct_order := engine.submit(
		RouteCommand.submit_ritual_step([
			"event.birth",
			"event.death",
			"event.burial",
		])
	)
	_check(correct_order.accepted, "correct chronology should be accepted")
	var correct_seal := engine.submit(
		RouteCommand.submit_ritual_step(["seal.inverted_eye"])
	)
	_check(correct_seal.accepted, "correct seal should complete the ritual")
	_check(
		correct_seal.snapshot.data["phase"] == "completed",
		"successful ritual should complete the route"
	)
	_check(
		correct_seal.snapshot.data["route_outcome"] == "completed",
		"successful route should report completed"
	)
	_check(
		correct_seal.sequence_state.data["advancement_state"] == "completed",
		"sequence state should be completed"
	)
	_check(
		int(correct_seal.sequence_state.data["current_sequence"]) == 8,
		"successful ascension should move to sequence eight"
	)
	var sequence_event_found := false
	for event in correct_seal.events:
		if event.type == &"SequenceAdvanced":
			sequence_event_found = true
	_check(sequence_event_found, "ascension should emit SequenceAdvanced")


func _test_rest_choices() -> void:
	var content := RouteTestContent.new()
	var engine := RouteEngineScript.new(content)
	engine.initialize()
	_reach_rest(engine, {"hp": 26, "corruption": 6, "attention": 1, "spirit": 2})
	engine.submit(RouteCommand.select_node(
		&"route.v050.node.old_house_rest"
	))
	var selected: RouteSnapshot = engine.get_snapshot()
	_check(
		selected.data["rest_options"].size() == 2,
		"rest node should offer two meaningful choices"
	)
	_check(
		"use_rest" in selected.data["available_commands"],
		"rest snapshot should expose use_rest"
	)
	var sealed := engine.submit(RouteCommand.use_rest(&"rest.seal_echo"))
	_check(sealed.accepted, "seal echo rest should be accepted")
	_check(
		int(sealed.snapshot.data["run_state"]["corruption"]) == 4,
		"seal echo should reduce corruption"
	)
	_check(
		int(sealed.snapshot.data["run_state"]["attention"]) == 2,
		"seal echo should increase attention"
	)
	_check(
		int(sealed.snapshot.data["run_state"]["max_spirit"]) == 4,
		"seal echo should increase the next battle spirit cap"
	)
	var duplicate := engine.submit(RouteCommand.use_rest(&"rest.bandage"))
	_check(
		not duplicate.accepted and duplicate.reason_code == &"wrong_phase",
		"rest should not be usable twice"
	)


func _test_ritual_cancel_hint_and_failure() -> void:
	var content := RouteTestContent.new()
	content.initial_run_state_override = {
		"hp": 40,
		"max_hp": 54,
		"spirit": 1,
		"max_spirit": 3,
		"corruption": 8,
		"max_corruption": 10,
		"attention": 2,
		"max_attention": 10,
	}
	var engine := RouteEngineScript.new(content)
	engine.initialize()
	_reach_ritual(engine, {"corruption": 8, "spirit": 1})
	var begin := engine.submit(RouteCommand.begin_ascension())
	_check(begin.accepted, "ritual should begin for failure test")
	_check(
		int(begin.ritual_snapshot.data["hint_spirit_cost"]) == 1,
		"ritual snapshot should expose the exact hint cost"
	)
	var hint := engine.submit(RouteCommand.request_ritual_hint())
	_check(hint.accepted, "ritual hint should be usable")
	_check(
		int(hint.ritual_snapshot.data["spirit"]) == 0,
		"hint should consume one spirit"
	)
	_check(
		not String(hint.ritual_snapshot.data["hint_text"]).is_empty(),
		"hint should expose step guidance"
	)
	_check(
		0 in hint.ritual_snapshot.data["hinted_step_indices"],
		"hint should record its step so it cannot be bought twice"
	)
	var second_hint := engine.submit(RouteCommand.request_ritual_hint())
	_check(
		not second_hint.accepted
		and second_hint.reason_code == &"hint_already_used",
		"same ritual step should not grant repeated hints"
	)
	var wrong := engine.submit(
		RouteCommand.submit_ritual_step([
			"name.elin_ward",
			"name.mira_finch",
		])
	)
	_check(wrong.accepted, "wrong-but-valid ritual selection should resolve with cost")
	_check(
		int(wrong.ritual_snapshot.data["corruption"]) == 10,
		"wrong ritual step should add configured corruption"
	)
	_check(
		wrong.snapshot.data["phase"] == "failed",
		"corruption limit should fail the route without hanging"
	)

	var cancel_content := RouteTestContent.new()
	var cancel_engine := RouteEngineScript.new(cancel_content)
	cancel_engine.initialize()
	_reach_ritual(cancel_engine)
	cancel_engine.submit(RouteCommand.begin_ascension())
	var cancelled := cancel_engine.submit(RouteCommand.cancel_ritual())
	_check(cancelled.accepted, "ritual should be cancellable")
	_check(
		cancelled.snapshot.data["phase"] == "map"
		and cancelled.snapshot.data["available_node_id"]
		== "route.v050.node.ascension",
		"cancel should return to the available ritual node"
	)
	var retry := cancel_engine.submit(RouteCommand.begin_ascension())
	_check(retry.accepted, "cancelled ritual should be retryable")


func _test_battle_defeat_ends_route() -> void:
	var content := RouteTestContent.new()
	var engine := RouteEngineScript.new(content)
	engine.initialize()
	engine.submit(RouteCommand.select_node(&"route.v050.node.first_hunt"))
	var result := engine.submit(
		RouteCommand.resolve_node(
			&"route.v050.node.first_hunt",
			&"defeat",
			{"hp": 0, "corruption": 5, "attention": 4, "spirit": 0}
		)
	)
	_check(result.accepted, "battle defeat should resolve")
	_check(
		result.snapshot.data["phase"] == "failed"
		and result.snapshot.data["route_outcome"] == "failed",
		"battle defeat should fail the route"
	)
	_check(
		result.snapshot.data.get("end_reason", "") == "battle_defeat",
		"battle defeat should expose a stable end reason"
	)
	var retry := engine.submit(RouteCommand.select_node(
		&"route.v050.node.first_hunt"
	))
	_check(
		not retry.accepted and retry.reason_code == &"wrong_phase",
		"failed route should reject more node commands"
	)


func _test_state_round_trip() -> void:
	var content := RouteTestContent.new()
	var engine := RouteEngineScript.new(content)
	engine.initialize()
	_reach_rest(engine, {"hp": 30, "corruption": 2, "attention": 1, "spirit": 2})
	var saved: Dictionary = engine.export_persistent_state()
	var restored_engine := RouteEngineScript.new(content)
	var restored: RouteCommandResult = restored_engine.initialize(saved)
	_check(restored.accepted, "route state should restore")
	_check(
		restored.snapshot.data["phase"] == "map"
		and restored.snapshot.data["available_node_id"]
		== "route.v050.node.old_house_rest",
		"restored route should resume at the latest confirmed node"
	)
	_check(
		int(restored.snapshot.data["run_state"]["hp"]) == 30,
		"restored route should preserve run resources"
	)


func _test_boss_phase_behavior() -> void:
	var cards := _load_cards()
	var content := BattleTestContent.new(cards)
	var balance := BattleTestBalance.new()
	var enemy_document := _load_json("res://data/enemies/v0.5.0/enemies.json")
	var boss_definition: Dictionary = {}
	for enemy in enemy_document.get("enemies", []):
		if String(enemy.get("id", "")) == "enemy.mirror_baron":
			boss_definition = enemy.duplicate(true)
			break
	_check(not boss_definition.is_empty(), "boss definition should exist")
	var boss_config := {
		"id": "boss.instance",
		"definition_id": "enemy.mirror_baron",
		"lane_index": 1,
		"hp": int(boss_definition.get("base_health", 0)),
		"max_hp": int(boss_definition.get("base_health", 0)),
		"base_attack": int(boss_definition.get("base_attack", 0)),
		"phases": boss_definition.get("phases", []).duplicate(true),
	}
	var battle := BattleEngineScript.new()
	var initialized := battle.initialize(
		content,
		balance,
		TestRandom.new(17),
		&"battle.boss_phase",
		{
			"actor_id": "player",
			"hp": 999,
			"max_hp": 999,
			"block": 0,
			"spirit": 3,
			"max_spirit": 3,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
			"statuses": [],
		},
		["card.skill.focus"],
		[boss_config]
	)
	_check(initialized.accepted, "boss battle should initialize with phases")
	battle.submit(BattleCommand.end_turn())
	var round_three := battle.submit(BattleCommand.end_turn())
	var phase_found := false
	for event in round_three.events:
		if event.type == &"EnemyPhaseTriggered":
			phase_found = true
	_check(phase_found, "boss should trigger its first phase at round three")
	var snapshot_three: Dictionary = round_three.snapshot.data
	_check(
		int(snapshot_three["enemies"][0]["block"]) == 5,
		"first boss phase should grant mirror block"
	)
	_check(
		int(snapshot_three["enemies"][0]["intent"]["damage"]) == 6,
		"first boss phase should be included in the current intent"
	)
	var phase_count: int = int(
		snapshot_three["enemies"][0]["triggered_phase_count"]
	)
	_check(phase_count == 1, "boss phase should trigger only once")
	battle.submit(BattleCommand.end_turn())
	battle.submit(BattleCommand.end_turn())
	var round_six := battle.submit(BattleCommand.end_turn())
	var second_phase_found := false
	for event in round_six.events:
		if event.type == &"EnemyPhaseTriggered":
			second_phase_found = true
	_check(second_phase_found, "boss should trigger its second phase at round six")
	var snapshot_six: Dictionary = round_six.snapshot.data
	_check(
		int(snapshot_six["enemies"][0]["block"]) == 3,
		"second boss phase should grant its own block"
	)
	_check(
		int(snapshot_six["enemies"][0]["intent"]["damage"]) == 9,
		"second boss phase and pressure should affect the same intent"
	)
	_check(
		int(snapshot_six["enemies"][0]["triggered_phase_count"]) == 2,
		"both boss phases should trigger exactly once"
	)


func _reach_rest(engine: RouteEngineScript, run_state: Dictionary) -> void:
	engine.submit(RouteCommand.select_node(&"route.v050.node.first_hunt"))
	engine.submit(RouteCommand.resolve_node(
		&"route.v050.node.first_hunt",
		&"victory",
		run_state
	))
	engine.submit(RouteCommand.select_node(
		&"route.v050.node.mirror_pursuit"
	))
	engine.submit(RouteCommand.resolve_node(
		&"route.v050.node.mirror_pursuit",
		&"victory",
		run_state
	))


func _reach_ritual(
	engine: RouteEngineScript,
	run_state_override: Dictionary = {}
) -> void:
	var run_state := {
		"hp": 40,
		"corruption": 1,
		"attention": 1,
		"spirit": 3,
	}
	for key in run_state_override:
		run_state[key] = run_state_override[key]
	_reach_rest(engine, run_state)
	engine.submit(RouteCommand.select_node(
		&"route.v050.node.old_house_rest"
	))
	engine.submit(RouteCommand.use_rest(&"rest.bandage"))
	engine.submit(RouteCommand.select_node(
		&"route.v050.node.mirror_baron"
	))
	engine.submit(RouteCommand.resolve_node(
		&"route.v050.node.mirror_baron",
		&"victory",
		run_state
	))


func _load_cards() -> Dictionary:
	var document := _load_json("res://data/cards/v0.3.0/cards.json")
	var cards := {}
	for card in document.get("cards", []):
		cards[StringName(card.get("id", ""))] = card.duplicate(true)
	return cards


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


class RouteTestContent:
	extends RouteContentPort

	var initial_run_state_override: Dictionary = {}
	var _routes: Dictionary = {}
	var _rituals: Dictionary = {}

	func _init() -> void:
		var routes_document := _read_json("res://data/routes/v0.5.0/routes.json")
		var rituals_document := _read_json("res://data/rituals/v0.5.0/rituals.json")
		for route in routes_document.get("routes", []):
			_routes[String(route.get("id", ""))] = route.duplicate(true)
		for ritual in rituals_document.get("rituals", []):
			_rituals[String(ritual.get("id", ""))] = ritual.duplicate(true)

	func get_default_route_id() -> StringName:
		var routes_document := _read_json("res://data/routes/v0.5.0/routes.json")
		return StringName(routes_document.get("default_route_id", ""))

	func get_route(route_id: StringName) -> Dictionary:
		var route: Dictionary = _routes.get(String(route_id), {}).duplicate(true)
		if not initial_run_state_override.is_empty():
			route["initial_run_state"] = initial_run_state_override.duplicate(true)
		return route

	func get_ritual(ritual_id: StringName) -> Dictionary:
		return _rituals.get(String(ritual_id), {}).duplicate(true)

	func _read_json(path: String) -> Dictionary:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		return parsed if parsed is Dictionary else {}


class BattleTestContent:
	extends BattleContentPort

	var _cards: Dictionary

	func _init(cards: Dictionary) -> void:
		_cards = cards.duplicate(true)

	func get_card_definition(definition_id: StringName) -> Dictionary:
		return _cards.get(definition_id, {}).duplicate(true)


class BattleTestBalance:
	extends BattleBalancePort

	var values := {
		&"battle.max_rounds": 10,
		&"player.starting_hand": 1,
		&"player.turn_draw_to_hand_size": 1,
		&"player.max_hand_size": 8,
		&"battle.enemy_pressure_start_round": 5,
	}

	func get_value(parameter_id: StringName) -> Variant:
		return values.get(parameter_id)


class TestRandom:
	extends BattleRandomPort

	var state: int = 1

	func _init(seed_value: int) -> void:
		state = maxi(1, seed_value)

	func next_int(max_exclusive: int) -> int:
		if max_exclusive <= 0:
			return 0
		state = (state * 1103515245 + 12345) & 0x7fffffff
		return state % max_exclusive
