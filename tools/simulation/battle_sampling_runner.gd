extends Node

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleContentAdapterScript := preload(
	"res://src/infrastructure/battle_content_adapter.gd"
)
const BattleBalanceAdapterScript := preload(
	"res://src/infrastructure/battle_balance_adapter.gd"
)
const SeededRandomServiceScript := preload(
	"res://src/infrastructure/seeded_random_service.gd"
)
const BattleRandomAdapterScript := preload(
	"res://src/infrastructure/battle_random_adapter.gd"
)

const CARDS_PATH := "res://data/cards/v0.3.0/cards.json"
const ENEMIES_PATH := "res://data/enemies/v0.3.0/enemies.json"
const ENCOUNTERS_PATH := "res://data/encounters/v0.3.0/encounters.json"
const BALANCE_PATH := "res://data/balance/v0.3.0/balance.json"
const OUTPUT_PATH := "res://tools/simulation/out/v0.3.0_battle_sampling.json"

const BASE_SEED: int = 20261108
const SAMPLES_PER_POLICY: int = 1000

const POLICIES: Array[Dictionary] = [
	{
		"id": "aggressive_damage",
		"description": "增伤和直接伤害优先，护甲与治疗只作为资源余量。",
		"priority": [
			&"card.skill.focus",
			&"card.skill.omen",
			&"card.skill.ink_dart",
			&"card.skill.whisper",
			&"card.skill.insight",
			&"card.skill.second_look",
			&"card.skill.paper_guard",
			&"card.skill.calm_breath",
		],
	},
	{
		"id": "balanced_mark",
		"description": "先建立标记与低语，再以护甲控制损耗并用墨刺收尾。",
		"priority": [
			&"card.skill.focus",
			&"card.skill.insight",
			&"card.skill.omen",
			&"card.skill.whisper",
			&"card.skill.ink_dart",
			&"card.skill.paper_guard",
			&"card.skill.calm_breath",
			&"card.skill.second_look",
		],
	},
	{
		"id": "defense_first",
		"description": "优先护甲、治疗和削弱，在确认安全后逐步输出。",
		"priority": [
			&"card.skill.paper_guard",
			&"card.skill.calm_breath",
			&"card.skill.whisper",
			&"card.skill.focus",
			&"card.skill.insight",
			&"card.skill.omen",
			&"card.skill.ink_dart",
			&"card.skill.second_look",
		],
	},
	{
		"id": "pressure_probe",
		"description": "压力诊断策略，刻意不主动伤害，以验证第 5/7/9 回合实际生效。",
		"fallback_allowed": false,
		"priority": [
			&"card.skill.paper_guard",
			&"card.skill.calm_breath",
			&"card.skill.whisper",
			&"card.skill.focus",
			&"card.skill.insight",
			&"card.skill.second_look",
		],
	},
]

var _cards_document: Dictionary
var _enemies_document: Dictionary
var _encounters_document: Dictionary
var _balance_document: Dictionary


func _ready() -> void:
	_cards_document = _load_json(CARDS_PATH)
	_enemies_document = _load_json(ENEMIES_PATH)
	_encounters_document = _load_json(ENCOUNTERS_PATH)
	_balance_document = _load_json(BALANCE_PATH)

	if (
		_cards_document.is_empty()
		or _enemies_document.is_empty()
		or _encounters_document.is_empty()
		or _balance_document.is_empty()
	):
		get_tree().quit(1)
		return

	var results: Array[Dictionary] = []
	for policy in POLICIES:
		results.append(_sample_policy(policy))

	var output: Dictionary = {
		"version": "v0.3.0",
		"engine": "BattleEngine",
		"cards_source": CARDS_PATH,
		"enemies_source": ENEMIES_PATH,
		"encounters_source": ENCOUNTERS_PATH,
		"balance_source": BALANCE_PATH,
		"root_seed": BASE_SEED,
		"samples_per_policy": SAMPLES_PER_POLICY,
		"policies": results,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write simulation output: %s" % OUTPUT_PATH)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()

	print(JSON.stringify(output, "\t"))
	get_tree().quit(0)


func _sample_policy(policy: Dictionary) -> Dictionary:
	var wins: int = 0
	var round_total: int = 0
	var remaining_health_total: int = 0
	var pressure_event_total: int = 0
	var pressure_battles: int = 0
	var max_pressure_bonus: int = 0
	var invalid_runs: int = 0
	var pressure_activations_by_round: Dictionary = {
		"5": 0,
		"7": 0,
		"9": 0,
	}

	for sample_index in range(SAMPLES_PER_POLICY):
		var battle: Dictionary = _run_battle(policy, BASE_SEED + sample_index)
		if not bool(battle.get("valid", false)):
			invalid_runs += 1
			continue
		if bool(battle["won"]):
			wins += 1
			remaining_health_total += int(battle["remaining_health"])
		round_total += int(battle["rounds"])
		pressure_event_total += int(battle["pressure_events"])
		if int(battle["pressure_events"]) > 0:
			pressure_battles += 1
		for round_number in battle["pressure_round_numbers"]:
			var key: String = str(round_number)
			pressure_activations_by_round[key] = (
				int(pressure_activations_by_round.get(key, 0)) + 1
			)
		max_pressure_bonus = maxi(max_pressure_bonus, int(battle["max_pressure_bonus"]))

	var valid_samples: int = SAMPLES_PER_POLICY - invalid_runs
	return {
		"id": String(policy["id"]),
		"description": String(policy["description"]),
		"priority": policy["priority"],
		"fallback_allowed": bool(policy.get("fallback_allowed", true)),
		"samples": valid_samples,
		"invalid_runs": invalid_runs,
		"win_rate": 0.0 if valid_samples == 0 else float(wins) / float(valid_samples),
		"average_rounds": 0.0 if valid_samples == 0 else float(round_total) / float(valid_samples),
		"average_remaining_health_on_win": (
			0.0 if wins == 0 else float(remaining_health_total) / float(wins)
		),
		"battles_with_pressure": pressure_battles,
		"total_pressure_events": pressure_event_total,
		"average_pressure_events_per_battle": (
			0.0 if valid_samples == 0 else float(pressure_event_total) / float(valid_samples)
		),
		"pressure_activations_by_round": pressure_activations_by_round,
		"max_applied_pressure_bonus": max_pressure_bonus,
	}


func _run_battle(policy: Dictionary, seed: int) -> Dictionary:
	var cards: Array = _cards_document.get("cards", [])
	var content := BattleContentAdapterScript.new(cards)
	var balance = BattleBalanceAdapterScript.new(_balance_document)
	var random_service = SeededRandomServiceScript.new(seed)
	var random = BattleRandomAdapterScript.new(random_service.get_stream(&"battle.shuffle"))
	var encounter: Dictionary = _encounters_document.get("encounters", [])[0]
	var engine = BattleEngineScript.new()
	var initialize_result = engine.initialize(
		content,
		balance,
		random,
		StringName("simulation.%d" % seed),
		_player_state(),
		encounter["deck_definition_ids"],
		_enemy_configs(encounter)
	)
	if not initialize_result.accepted:
		return {
			"valid": false,
			"reason": String(initialize_result.reason_code),
		}

	var pressure_events: int = 0
	var pressure_round_numbers: Dictionary = {}
	var max_pressure_bonus: int = 0
	var result = initialize_result
	var command_guard: int = 0
	while result.accepted and String(result.snapshot.data["outcome"]).is_empty():
		command_guard += 1
		if command_guard > 100:
			return {"valid": false, "reason": "command_guard"}
		var command = _choose_command(engine, result.snapshot, policy)
		result = engine.submit(command)
		if not result.accepted:
			return {"valid": false, "reason": String(result.reason_code)}
		for event in result.events:
			if event.type == &"EnemyPressureChanged":
				pressure_events += 1
				pressure_round_numbers[int(event.data.get("round_number", 0))] = true
				max_pressure_bonus = maxi(
					max_pressure_bonus,
					int(event.data.get("bonus", 0))
				)
		max_pressure_bonus = maxi(
			max_pressure_bonus,
			int(result.snapshot.data.get("enemy_pressure_bonus", 0))
		)

	var snapshot: Dictionary = result.snapshot.data
	return {
		"valid": true,
		"won": String(snapshot["outcome"]) == "victory",
		"reason": String(snapshot["outcome_reason"]),
		"rounds": int(snapshot["round_number"]),
		"remaining_health": int(snapshot["player"]["hp"]),
		"pressure_events": pressure_events,
		"pressure_round_numbers": pressure_round_numbers.keys(),
		"max_pressure_bonus": max_pressure_bonus,
	}


func _choose_command(engine, snapshot, policy: Dictionary):
	var priority: Array = policy["priority"]
	for definition_id in priority:
		for card in snapshot.data["hand"]:
			if StringName(card["definition_id"]) != definition_id:
				continue
			var target_id: StringName = _target_for_card(snapshot.data, card)
			var playability = engine.query_card_play(
				StringName(card["instance_id"]),
				target_id
			)
			if playability.playable:
				return BattleCommandScript.play_card(
					StringName(card["instance_id"]),
					target_id
				)

	if bool(policy.get("fallback_allowed", true)):
		for card in snapshot.data["hand"]:
			var target_id: StringName = _target_for_card(snapshot.data, card)
			var playability = engine.query_card_play(
				StringName(card["instance_id"]),
				target_id
			)
			if playability.playable:
				return BattleCommandScript.play_card(
					StringName(card["instance_id"]),
					target_id
				)
	return BattleCommandScript.end_turn()


func _target_for_card(snapshot: Dictionary, card: Dictionary) -> StringName:
	if String(card.get("target_type", "none")) != "enemy":
		return &""
	var selected: Dictionary = {}
	for enemy in snapshot["enemies"]:
		if int(enemy["hp"]) <= 0:
			continue
		if selected.is_empty() or int(enemy["hp"]) < int(selected["hp"]):
			selected = enemy
	return StringName(selected.get("actor_id", ""))


func _player_state() -> Dictionary:
	var player: Dictionary = _balance_document["player"]
	return {
		"actor_id": &"player",
		"hp": int(player["starting_health"]),
		"max_hp": int(player["max_health"]),
		"block": 0,
		"spirit": int(player["spirit_per_turn"]),
		"max_spirit": int(player["spirit_per_turn"]),
		"corruption": 0,
		"max_corruption": int(player["corruption"]["max"]),
		"attention": 0,
		"max_attention": int(player["attention"]["max"]),
		"statuses": [],
	}


func _enemy_configs(encounter: Dictionary) -> Array:
	var definitions: Array = _enemies_document.get("enemies", [])
	var by_id: Dictionary = {}
	for definition in definitions:
		by_id[String(definition["id"])] = definition
	var configs: Array = []
	for slot in encounter["enemy_slots"]:
		var source: Dictionary = by_id[String(slot["enemy_id"])]
		var lane: int = int(slot["lane_index"])
		configs.append({
			"id": StringName("%s.enemy.%d" % [String(encounter["id"]), lane]),
			"definition_id": StringName(source["id"]),
			"lane_index": lane,
			"hp": int(source["base_health"]),
			"max_hp": int(source["base_health"]),
			"base_attack": int(source["base_attack"]),
		})
	return configs


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open simulation input: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Simulation input is not a JSON object: %s" % path)
		return {}
	return parsed
