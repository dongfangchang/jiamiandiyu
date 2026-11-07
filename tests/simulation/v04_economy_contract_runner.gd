extends Node

const BALANCE_PATH := "res://data/balance/v0.4.0/balance.json"
const BASE_CARDS_PATH := "res://data/cards/v0.3.0/cards.json"
const PROGRESSION_PATH := "res://data/cards/v0.4.0/progression.json"
const ECONOMY_PATH := "res://tools/simulation/out/v0.4.0_economy_sampling.json"
const BATTLE_PATH := "res://tools/simulation/out/v0.4.0_upgrade_battle_sampling.json"

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	var balance: Dictionary = _load_json(BALANCE_PATH)
	var base_cards: Dictionary = _load_json(BASE_CARDS_PATH)
	var progression: Dictionary = _load_json(PROGRESSION_PATH)
	var economy: Dictionary = _load_json(ECONOMY_PATH)
	var battle: Dictionary = _load_json(BATTLE_PATH)

	_check(int(balance.get("schema_version", 0)) == 2, "v0.4 draft uses schema version 2")
	_check(balance.get("content_version", "") == "v0.4.0", "balance content version is v0.4.0")
	_check(balance.get("status", "") == "draft", "balance remains an explicit draft")
	_check(not balance.has("cards"), "balance must not copy card definitions")
	_check(not balance.has("enemies"), "balance must not copy enemy definitions")
	_check(not balance.has("encounters"), "balance must not copy encounter definitions")

	var starting: Dictionary = balance.get("progression", {})
	_check(
		int(starting.get("starting_divination_tickets", 0)) == 3,
		"start with three divination tickets"
	)

	var gacha: Dictionary = balance.get("gacha", {})
	_check(int(gacha.get("single_cost", 0)) == 2, "single pull costs two tickets")
	_check(int(gacha.get("triple_cost", 0)) == 5, "triple pull costs five tickets")
	_check(int(gacha.get("pulls_per_triple", 0)) == 3, "triple pull performs three draws")
	_check(int(gacha.get("rare_pity", 0)) == 4, "rare pity triggers by fourth pull")
	_check(
		int(gacha.get("rarity_weights", {}).get("common", 0))
		+ int(gacha.get("rarity_weights", {}).get("rare", 0))
		== 100,
		"gacha weights total 100"
	)
	_check(int(gacha.get("duplicate_fragments", 0)) == 6, "duplicate card gives six fragments")

	var upgrade: Dictionary = balance.get("upgrade", {})
	var costs: Dictionary = upgrade.get("cost_by_next_level", {})
	_check(int(costs.get("1", 0)) == 6, "first upgrade costs six fragments")
	_check(int(costs.get("2", 0)) == 12, "second upgrade costs twelve fragments")
	_check(int(costs.get("3", 0)) == 24, "third upgrade costs twenty-four fragments")

	var reward_amounts: Dictionary = balance.get("reward", {}).get("amounts", {})
	_check(
		int(reward_amounts.get("reward.divination_tickets", 0)) == 3,
		"ticket reward grants three tickets"
	)
	_check(
		int(reward_amounts.get("reward.ink_dart_fragments", 0)) == 6,
		"ink dart reward grants six fragments"
	)

	_check(progression.get("content_version", "") == "v0.4.0", "progression content is v0.4.0")
	_check(progression.get("identities", []).size() == 3, "three identity definitions exist")
	_check(progression.get("starter_card_ids", []).size() == 6, "six starter cards exist")
	var gacha_pool: Array = progression.get("gacha_pool", [])
	var upgrade_definitions: Dictionary = progression.get("upgrade_definitions", {})
	_check(gacha_pool.size() == 7, "gacha pool has seven upgradeable cards")
	var gacha_ids: Array[String] = []
	var all_gacha_cards_upgradeable := true
	for entry in gacha_pool:
		var definition_id := String(entry.get("definition_id", ""))
		if definition_id.is_empty() or definition_id in gacha_ids:
			all_gacha_cards_upgradeable = false
			continue
		gacha_ids.append(definition_id)
		if not upgrade_definitions.has(definition_id):
			all_gacha_cards_upgradeable = false
	_check(
		all_gacha_cards_upgradeable,
		"every unique gacha card must have an upgrade definition"
	)
	_check(progression.get("reward_options", []).size() == 2, "two post-battle rewards exist")
	_check(base_cards.get("cards", []).size() == 8, "formal battle pool still has eight cards")

	var identities: Dictionary = {}
	for identity in progression.get("identities", []):
		identities[String(identity["id"])] = identity
	_check(
		int(
			identities.get("identity.reporter", {})
			.get("victory_resources", {})
			.get("divination_tickets", 0)
		) == 1,
		"reporter grants one victory ticket"
	)
	_check(
		int(
			identities.get("identity.doctor", {})
			.get("battle_modifiers", {})
			.get("max_hp_bonus", 0)
		) == 4,
		"doctor grants four max health"
	)
	_check(
		int(identities.get("identity.gravedigger", {}).get("duplicate_fragment_bonus", 0)) == 2,
		"gravedigger adds two fragments to duplicates"
	)

	_check(economy.get("version", "") == "v0.4.0", "economy output version is v0.4.0")
	_check(int(economy.get("root_seed", 0)) == 20261108, "economy output has fixed root seed")
	_check(
		int(economy.get("samples_per_strategy", 0)) == 1000,
		"economy output samples 1000 loops per strategy"
	)
	var economy_strategies: Array = economy.get("strategies", [])
	_check(economy_strategies.size() == 3, "economy output covers three strategies")
	var strategy_by_id: Dictionary = {}
	for strategy in economy_strategies:
		strategy_by_id[String(strategy.get("id", ""))] = strategy
		_check(
			int(strategy.get("valid_loops", 0)) == 1000,
			"economy strategy has 1000 valid loops"
		)
		_check(
			is_equal_approx(
				float(strategy.get("averages", {}).get("active_loop_rate", 0.0)),
				1.0
			),
			"every economy strategy has a meaningful action"
		)

	var reporter: Dictionary = strategy_by_id.get("ticket_route_reporter", {})
	_check(
		int(reporter.get("averages", {}).get("pulls", 0)) == 4,
		"reporter ticket route performs four pulls"
	)
	_check(
		float(reporter.get("averages", {}).get("loops_with_pulls", 0.0)) == 1.0,
		"reporter ticket route completes its gacha decision"
	)

	var doctor: Dictionary = strategy_by_id.get("upgrade_route_doctor", {})
	_check(
		int(doctor.get("averages", {}).get("pulls", 0)) == 0,
		"doctor fragment route does not consume tickets"
	)
	_check(
		int(doctor.get("averages", {}).get("upgrades_completed", 0)) == 1,
		"doctor fragment route completes one first upgrade"
	)

	var gravedigger: Dictionary = strategy_by_id.get("fragment_route_gravedigger", {})
	_check(
		int(gravedigger.get("averages", {}).get("pulls", 0)) == 3,
		"gravedigger ticket route performs three pulls"
	)
	_check(
		float(gravedigger.get("averages", {}).get("loops_with_pulls", 0.0)) == 1.0,
		"gravedigger ticket route completes its gacha decision"
	)

	_check(battle.get("version", "") == "v0.4.0", "battle output version is v0.4.0")
	_check(int(battle.get("sample_pairs", 0)) == 500, "battle output samples 500 pairs")
	_check(int(battle.get("identity_health_bonus", 0)) == 4, "battle output applies doctor bonus")
	var baseline: Dictionary = battle.get("baseline", {})
	var upgraded: Dictionary = battle.get("upgraded", {})
	_check(int(baseline.get("valid_samples", 0)) == 500, "baseline battle samples are valid")
	_check(int(upgraded.get("valid_samples", 0)) == 500, "upgraded battle samples are valid")
	_check(
		is_equal_approx(float(baseline.get("win_rate", 0.0)), 1.0),
		"doctor baseline wins teaching battle"
	)
	_check(
		is_equal_approx(float(upgraded.get("win_rate", 0.0)), 1.0),
		"upgraded doctor wins teaching battle"
	)
	_check(
		is_equal_approx(
			float(baseline.get("average_damage_per_ink_dart_hit", 0.0)),
			4.0
		),
		"baseline ink dart damage is four"
	)
	_check(
		is_equal_approx(
			float(upgraded.get("average_damage_per_ink_dart_hit", 0.0)),
			5.0
		),
		"level-one ink dart damage is five"
	)
	_check(
		int(upgraded.get("ink_dart_damage", 0))
		> int(baseline.get("ink_dart_damage", 0)),
		"upgrade produces visible extra damage in real BattleEngine"
	)

	if _failures.is_empty():
		print("V04_ECONOMY_TESTS_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V04_ECONOMY_TEST_FAILURE: %s" % failure)
	printerr("V04_ECONOMY_TESTS_FAILED checks=%d failures=%d" % [_checks, _failures.size()])
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
