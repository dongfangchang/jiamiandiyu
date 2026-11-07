extends Node

const BALANCE_PATH := "res://data/balance/v0.3.0/balance.json"
const CARDS_PATH := "res://data/cards/v0.3.0/cards.json"
const ENEMIES_PATH := "res://data/enemies/v0.3.0/enemies.json"
const ENCOUNTERS_PATH := "res://data/encounters/v0.3.0/encounters.json"
const SIMULATION_PATH := "res://tools/simulation/out/v0.3.0_battle_sampling.json"

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	var balance: Dictionary = _load_json(BALANCE_PATH)
	var cards_document: Dictionary = _load_json(CARDS_PATH)
	var enemies_document: Dictionary = _load_json(ENEMIES_PATH)
	var encounters_document: Dictionary = _load_json(ENCOUNTERS_PATH)
	var simulation: Dictionary = _load_json(SIMULATION_PATH)

	_check(not balance.has("cards"), "balance must not duplicate card definitions")
	_check(not balance.has("enemies"), "balance must not duplicate enemy definitions")
	_check(not balance.has("encounters"), "balance must not duplicate encounter definitions")
	_check(
		int(balance["combat"]["enemy_pressure"]["start_round"]) == 5,
		"enemy pressure must start at round 5"
	)
	_check(int(balance["player"]["max_health"]) == 54, "v0.3 player max health is 54")
	_check(int(balance["player"]["spirit_per_turn"]) == 3, "v0.3 spirit is 3")
	_check(int(balance["player"]["starting_hand"]) == 5, "v0.3 starting hand is 5")
	_check(int(balance["combat"]["max_rounds"]) == 10, "v0.3 max rounds is 10")

	_check(cards_document["cards"].size() == 8, "formal v0.3 content has 8 cards")
	_check(enemies_document["enemies"].size() == 3, "formal v0.3 content has 3 enemies")
	_check(encounters_document["encounters"].size() == 1, "formal v0.3 content has 1 encounter")
	_check(
		encounters_document["encounters"][0]["enemy_slots"].size() == 2,
		"first encounter uses two enemy lanes"
	)

	_check(simulation.get("engine", "") == "BattleEngine", "sampling must use BattleEngine")
	_check(int(simulation.get("root_seed", 0)) == 20261108, "sampling root seed is fixed")
	_check(int(simulation.get("samples_per_policy", 0)) == 1000, "sampling has 1000 samples")
	_check(simulation.get("policies", []).size() == 4, "sampling has three policies and one probe")

	for policy in simulation.get("policies", []):
		_check(int(policy.get("invalid_runs", -1)) == 0, "sampling must not contain invalid runs")
		for round_key in policy.get("pressure_activations_by_round", {}).keys():
			_check(
				String(round_key) in ["5", "7", "9"],
				"pressure may only activate on rounds five, seven and nine"
			)
		if String(policy.get("id", "")) == "pressure_probe":
			_check(
				int(policy.get("max_applied_pressure_bonus", 0)) == 3,
				"pressure probe must observe the third pressure step"
			)

	if _failures.is_empty():
		print("SIMULATION_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("SIMULATION_TEST_FAILURE: %s" % failure)
	printerr("SIMULATION_TESTS_FAILED checks=%d failures=%d" % [_checks, _failures.size()])
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


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
