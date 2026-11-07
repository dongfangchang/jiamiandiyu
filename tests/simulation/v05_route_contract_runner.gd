extends Node

const BALANCE_PATH := "res://data/balance/v0.5.0/balance.json"
const ROUTES_PATH := "res://data/routes/v0.5.0/routes.json"
const RITUALS_PATH := "res://data/rituals/v0.5.0/rituals.json"
const ENEMIES_PATH := "res://data/enemies/v0.5.0/enemies.json"
const ENCOUNTERS_PATH := "res://data/encounters/v0.5.0/encounters.json"
const SAMPLING_PATH := "res://tools/simulation/out/v0.5.0_route_sampling.json"
const BALANCE_SCHEMA_PATH := "res://data/schema/v0.5.0/balance.schema.json"
const ROUTES_SCHEMA_PATH := "res://data/schema/v0.5.0/routes.schema.json"
const RITUALS_SCHEMA_PATH := "res://data/schema/v0.5.0/rituals.schema.json"
const ENEMIES_SCHEMA_PATH := "res://data/schema/v0.5.0/enemies.schema.json"
const ENCOUNTERS_SCHEMA_PATH := "res://data/schema/v0.5.0/encounters.schema.json"
const SchemaValidatorScript := preload(
	"res://src/infrastructure/schema_validator.gd"
)

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	var balance: Dictionary = _load_json(BALANCE_PATH)
	var routes: Dictionary = _load_json(ROUTES_PATH)
	var rituals: Dictionary = _load_json(RITUALS_PATH)
	var enemies: Dictionary = _load_json(ENEMIES_PATH)
	var encounters: Dictionary = _load_json(ENCOUNTERS_PATH)
	var sampling: Dictionary = _load_json(SAMPLING_PATH)
	var validator = SchemaValidatorScript.new()
	_check_schema(validator, balance, BALANCE_SCHEMA_PATH, "balance")
	_check_schema(validator, routes, ROUTES_SCHEMA_PATH, "routes")
	_check_schema(validator, rituals, RITUALS_SCHEMA_PATH, "rituals")
	_check_schema(validator, enemies, ENEMIES_SCHEMA_PATH, "enemies")
	_check_schema(validator, encounters, ENCOUNTERS_SCHEMA_PATH, "encounters")

	_check(int(balance.get("schema_version", 0)) == 2, "v0.5 balance keeps schema 2")
	_check(balance.get("content_version", "") == "v0.5.0", "balance content version is v0.5.0")
	_check(balance.get("status", "") == "draft", "v0.5 balance is an explicit draft")
	_check(not balance.has("cards"), "balance must not own card definitions")
	_check(not balance.has("enemies"), "balance must not own enemy definitions")
	_check(not balance.has("routes"), "balance must not own route definitions")
	_check(not balance.has("rituals"), "balance must not own ritual definitions")
	_check(
		int(balance.get("combat", {}).get("enemy_pressure", {}).get("start_round", 0)) == 5,
		"enemy pressure starts at round five"
	)

	_check(routes.get("content_version", "") == "v0.5.0", "route content version is v0.5.0")
	var route_entries: Array = routes.get("routes", [])
	_check(route_entries.size() == 1, "v0.5 has exactly one fixed route")
	var route: Dictionary = route_entries[0] if not route_entries.is_empty() else {}
	_check(route.get("id", "") == "route.v050.first_case", "first route has stable id")
	var nodes: Array = route.get("nodes", [])
	_check(nodes.size() == 5, "fixed route has five nodes")
	if nodes.size() == 5:
		_check(nodes[0].get("type", "") == "normal", "node one is normal combat")
		_check(nodes[1].get("type", "") == "elite", "node two is elite combat")
		_check(nodes[2].get("type", "") == "rest", "node three is rest")
		_check(nodes[3].get("type", "") == "boss", "node four is boss combat")
		_check(nodes[4].get("type", "") == "ritual", "node five is ascension")
	_check(route.get("rest_options", []).size() == 2, "rest has two explicit choices")
	_check(
		route.get("sequence", {}).get("current_sequence", 0) == 9
		and route.get("sequence", {}).get("next_sequence", 0) == 8,
		"route advances seer sequence nine to eight"
	)

	var ritual_entries: Array = rituals.get("rituals", [])
	_check(ritual_entries.size() == 1, "one ascension ritual exists")
	var ritual: Dictionary = ritual_entries[0] if not ritual_entries.is_empty() else {}
	_check(ritual.get("steps", []).size() == 3, "ascension ritual has three steps")
	_check(int(ritual.get("wrong_step_corruption", 0)) == 2, "ritual errors cost two corruption")
	_check(int(ritual.get("hint_spirit_cost", 0)) == 1, "ritual hint costs one spirit")

	var enemy_entries: Array = enemies.get("enemies", [])
	var boss: Dictionary = {}
	for enemy in enemy_entries:
		if String(enemy.get("id", "")) == "enemy.mirror_baron":
			boss = enemy
	_check(not boss.is_empty(), "mirror baron exists")
	_check(boss.get("phases", []).size() == 2, "mirror baron has two unique phases")
	_check(encounters.get("encounters", []).size() == 3, "three v0.5 encounters exist")

	_check(sampling.get("version", "") == "v0.5.0", "route sampling output is v0.5.0")
	_check(
		sampling.get("engine", "") == "RouteEngine+BattleEngine+ProgressionEngine",
		"route sampling uses real domain engines"
	)
	_check(int(sampling.get("root_seed", 0)) == 20261108, "route sampling uses fixed root seed")
	_check(int(sampling.get("samples_per_case", 0)) == 200, "route sampling runs 200 routes per case")
	var cases: Array = sampling.get("cases", [])
	_check(cases.size() == 6, "sampling covers three strategies and two identities")
	var all_valid := true
	var all_completed := true
	var all_have_pressure := true
	var all_have_boss_phases := true
	var all_sequence_eight := true
	var all_have_time_estimates := true
	var all_within_adjusted_duration := true
	var all_rest_choices_accounted := true
	var aggregate_rest_choices: Dictionary = {}
	for case in cases:
		all_valid = all_valid and int(case.get("valid_runs", 0)) == 200
		all_completed = all_completed and is_equal_approx(
			float(case.get("route_completion_rate", 0.0)),
			1.0
		)
		all_have_pressure = all_have_pressure and float(
			case.get("average_pressure_events", 0.0)
		) > 0.0
		all_have_boss_phases = all_have_boss_phases and float(
			case.get("average_boss_phase_events", 0.0)
		) > 0.0
		all_sequence_eight = all_sequence_eight and is_equal_approx(
			float(case.get("average_final_sequence", 9.0)),
			8.0
		)
		all_have_time_estimates = (
			all_have_time_estimates
			and float(case.get("average_conservative_minutes", 0.0)) > 0.0
			and float(case.get("average_relaxed_minutes", 0.0)) > 0.0
		)
		all_within_adjusted_duration = (
			all_within_adjusted_duration
			and bool(case.get("target_15_30_met_midpoint", false))
		)
		var rest_choices: Dictionary = case.get("rest_choices", {})
		var rest_total := 0
		for rest_id in rest_choices:
			var count := int(rest_choices[rest_id])
			rest_total += count
			aggregate_rest_choices[rest_id] = (
				int(aggregate_rest_choices.get(rest_id, 0)) + count
			)
		all_rest_choices_accounted = (
			all_rest_choices_accounted
			and rest_total == int(case.get("valid_runs", 0))
		)
	_check(all_valid, "all route samples are valid")
	_check(all_completed, "all sampled routes complete under their strategy assumptions")
	_check(all_have_pressure, "all sampled cases trigger enemy pressure")
	_check(all_have_boss_phases, "all sampled cases trigger boss phases")
	_check(all_sequence_eight, "completed samples finish at sequence eight")
	_check(all_have_time_estimates, "every sampled case has duration estimates")
	_check(
		all_within_adjusted_duration,
		"duration estimates stay within the ADR-0008 15-30 minute target"
	)
	_check(
		all_rest_choices_accounted,
		"every valid route records exactly one rest choice"
	)
	_check(
		int(aggregate_rest_choices.get("rest.bandage", 0)) > 0,
		"bandage rest is selected by at least one strategy sample"
	)
	_check(
		int(aggregate_rest_choices.get("rest.seal_echo", 0)) > 0,
		"seal echo rest is selected by at least one strategy sample"
	)
	_check(
		sampling.get("time_model_minutes", {}).get("note", "").contains("Planning estimate"),
		"time estimates are explicitly marked as planning-only"
	)

	if _failures.is_empty():
		print("V05_ROUTE_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V05_ROUTE_TEST_FAILURE: %s" % failure)
	printerr("V05_ROUTE_TESTS_FAILED checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_check(false, "required JSON should be readable: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_check(false, "required JSON should be an object: %s" % path)
		return {}
	return parsed


func _check_schema(validator, document: Dictionary, schema_path: String, label: String) -> void:
	var result = validator.validate_document(document, schema_path)
	_check(
		result.ok,
		"%s should conform to its v0.5 schema (%s)" % [label, String(result.message)]
	)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
