extends Node

const RouteContentAdapterScript := preload(
	"res://tools/simulation/v05_route_content_adapter.gd"
)
const ChallengeContentAdapterScript := preload(
	"res://tools/simulation/v06_challenge_content_adapter.gd"
)
const ChallengeEngineScript := preload(
	"res://src/gameplay/challenge_engine.gd"
)
const ChallengeCommandScript := preload(
	"res://src/core/challenge_command.gd"
)

const ROUTES_PATH := "res://data/routes/v0.5.0/routes.json"
const RITUALS_PATH := "res://data/rituals/v0.5.0/rituals.json"
const ENEMIES_PATH := "res://data/enemies/v0.5.0/enemies.json"
const CHALLENGES_PATH := "res://data/challenges/v0.6.0/challenges.json"
const BALANCE_PATH := "res://data/balance/v0.6.0/balance.json"
const OUTPUT_PATH := "res://tools/simulation/out/v0.6.0_challenge_sampling.json"
const CHALLENGE_ID: StringName = &"challenge.v060.mirror_echoes"

var _checks: int = 0
var _failures: Array[String] = []

var _routes: Dictionary
var _rituals: Dictionary
var _enemies: Dictionary
var _challenges: Dictionary
var _balance: Dictionary
var _route_content
var _challenge_content


func _ready() -> void:
	_routes = _load_json(ROUTES_PATH)
	_rituals = _load_json(RITUALS_PATH)
	_enemies = _load_json(ENEMIES_PATH)
	_challenges = _load_json(CHALLENGES_PATH)
	_balance = _load_json(BALANCE_PATH)
	_expect(not _routes.is_empty(), "routes load")
	_expect(not _rituals.is_empty(), "rituals load")
	_expect(not _enemies.is_empty(), "enemies load")
	_expect(not _challenges.is_empty(), "challenges load")
	_expect(not _balance.is_empty(), "v0.6 balance loads")
	_expect(
		String(_balance.get("content_version", "")) == "v0.6.0",
		"balance is versioned v0.6.0"
	)
	_expect(
		String(_challenges.get("default_challenge_id", "")) == String(CHALLENGE_ID),
		"default challenge id is stable"
	)

	_route_content = RouteContentAdapterScript.new(_routes, _rituals)
	_challenge_content = ChallengeContentAdapterScript.new(_challenges)
	_test_unlock_gate()
	_test_modifier_effects()
	_test_rewards_reference_existing_ids()
	_test_sampling_output()

	if _failures.is_empty():
		print("V06_CHALLENGE_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("FAIL %s" % failure)
	print("V06_CHALLENGE_TESTS_FAILED checks=%d failures=%d" % [
		_checks,
		_failures.size(),
	])
	get_tree().quit(1)


func _test_unlock_gate() -> void:
	var locked = _new_challenge({
		"pathway": "seer",
		"current_sequence": 9,
		"advancement_state": "locked",
	})
	var locked_snapshot: Dictionary = locked.get_snapshot().data
	_expect(bool(locked_snapshot.get("unlocked", true)) == false, "sequence 9 stays locked")
	_expect(
		String(locked_snapshot.get("phase", "")) == "locked",
		"locked challenge phase"
	)

	var unlocked = _new_challenge({
		"pathway": "seer",
		"current_sequence": 8,
		"advancement_state": "completed",
	})
	var unlocked_snapshot: Dictionary = unlocked.get_snapshot().data
	_expect(bool(unlocked_snapshot.get("unlocked", false)), "sequence 8 unlocks challenge")
	_expect(
		String(unlocked_snapshot.get("phase", "")) == "modifier_selection",
		"unlocked challenge offers modifier selection"
	)


func _test_modifier_effects() -> void:
	var expected: Array[String] = [
		"modifier.rushed_reflection",
		"modifier.tainted_margins",
		"modifier.fractured_deck",
	]
	var actual := {}
	for value in _challenges.get("challenges", []):
		var challenge: Dictionary = value
		for modifier_value in challenge.get("modifiers", []):
			var modifier: Dictionary = modifier_value
			actual[String(modifier.get("id", ""))] = true
	_expect(actual.size() == 3, "exactly three challenge modifiers")
	for modifier_id in expected:
		_expect(actual.has(modifier_id), "modifier exists: %s" % modifier_id)

	var tainted = _started_challenge("modifier.tainted_margins")
	var tainted_state: Dictionary = tainted.get_route_snapshot().data.get(
		"run_state",
		{}
	)
	_expect(int(tainted_state.get("corruption", 0)) == 4, "tainted margins starts with 4 corruption")
	_expect(int(tainted_state.get("attention", 0)) == 1, "tainted margins starts with 1 attention")

	var fractured = _started_challenge("modifier.fractured_deck")
	var deck: Array = fractured.build_battle_deck([
		"card.skill.paper_guard",
		"card.skill.paper_guard",
		"card.skill.ink_dart",
	])
	_expect(deck.size() == 1, "fractured deck removes paper guards")
	_expect(deck[0] == "card.skill.ink_dart", "fractured deck keeps other cards")
	var reward: Dictionary = fractured.get_completion_reward()
	_expect(
		int(reward.get("reward.divination_tickets", 0)) == 3,
		"fractured deck adds one completion ticket"
	)

	var enemy: Dictionary = _find_first_enemy_with_phases()
	_expect(not enemy.is_empty(), "boss phase enemy exists")
	if not enemy.is_empty():
		var rushed = _started_challenge("modifier.rushed_reflection")
		var prepared: Array[Dictionary] = rushed.prepare_enemy_configs([
			enemy.duplicate(true),
		])
		var original_round := int(enemy["phases"][0]["at_round"])
		var modified_round := int(prepared[0]["phases"][0]["at_round"])
		_expect(
			modified_round == maxi(1, original_round - 2),
			"rushed reflection moves enemy phases two rounds earlier"
		)


func _test_rewards_reference_existing_ids() -> void:
	var allowed := {
		"reward.divination_tickets": true,
		"reward.ink_dart_fragments": true,
	}
	for value in _challenges.get("challenges", []):
		var challenge: Dictionary = value
		for reward_id in challenge.get("completion_reward", {}):
			_expect(allowed.has(String(reward_id)), "completion reward exists: %s" % reward_id)
		for modifier_value in challenge.get("modifiers", []):
			var modifier: Dictionary = modifier_value
			var extra: Dictionary = modifier.get("effects", {}).get(
				"completion_reward",
				{}
			)
			for reward_id in extra:
				_expect(allowed.has(String(reward_id)), "modifier reward exists: %s" % reward_id)


func _test_sampling_output() -> void:
	var output := _load_json(OUTPUT_PATH)
	_expect(not output.is_empty(), "challenge sampling output exists")
	if output.is_empty():
		return
	_expect(String(output.get("version", "")) == "v0.6.0", "sampling output version")
	_expect(
		String(output.get("challenge_id", "")) == String(CHALLENGE_ID),
		"sampling challenge id"
	)
	var summary: Dictionary = output.get("modifier_summary", {})
	_expect(summary.size() == 3, "sampling includes three modifier summaries")
	if summary.size() == 3:
		var tainted: Dictionary = summary.get("modifier.tainted_margins", {})
		var fractured: Dictionary = summary.get("modifier.fractured_deck", {})
		_expect(
			float(tainted.get("average_initial_corruption", 0.0)) >= 4.0,
			"sampling shows tainted corruption pressure"
		)
		_expect(
			float(tainted.get("completion_rate", 1.0)) < 1.0,
			"tainted margins has a natural failure sample"
		)
		_expect(
			float(fractured.get("average_initial_deck_cards", 0.0))
				< float(tainted.get("average_initial_deck_cards", 0.0)),
			"fractured deck has fewer cards than tainted deck"
		)
		for modifier_id in summary:
			var item: Dictionary = summary[modifier_id]
			_expect(int(item.get("valid_runs", 0)) > 0, "modifier has valid runs: %s" % modifier_id)
		var tainted_failure_seen := false
		var tainted_failures_preserved := true
		for case_value in output.get("cases", []):
			var case: Dictionary = case_value
			if (
				String(case.get("modifier_id", "")) != "modifier.tainted_margins"
				or String(case.get("strategy_id", "")) != "neglect_corruption"
			):
				continue
			tainted_failure_seen = tainted_failure_seen or int(case.get("failed_runs", 0)) > 0
			tainted_failures_preserved = (
				tainted_failures_preserved
				and int(case.get("collection_preserved_failures", 0))
					== int(case.get("failed_runs", 0))
			)
		_expect(tainted_failure_seen, "tainted margins produces natural failures")
		_expect(
			tainted_failures_preserved,
			"tainted failures preserve collection and levels"
		)


func _new_challenge(sequence_state: Dictionary):
	var challenge = ChallengeEngineScript.new(
		_route_content,
		_challenge_content,
		CHALLENGE_ID
	)
	var result = challenge.initialize(sequence_state)
	_expect(result.accepted, "challenge initializes")
	return challenge


func _started_challenge(modifier_id: String):
	var challenge = _new_challenge({
		"pathway": "seer",
		"current_sequence": 8,
		"advancement_state": "completed",
	})
	var selected = challenge.submit(
		ChallengeCommandScript.select_modifier(StringName(modifier_id))
	)
	_expect(selected.accepted, "select modifier: %s" % modifier_id)
	var started = challenge.submit(ChallengeCommandScript.start_challenge())
	_expect(started.accepted, "start challenge: %s" % modifier_id)
	return challenge


func _find_first_enemy_with_phases() -> Dictionary:
	for value in _enemies.get("enemies", []):
		var enemy: Dictionary = value
		if enemy.get("phases", []).size() > 0:
			return enemy.duplicate(true)
	return {}


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}
