extends Node

const BattleEngineScript := preload("res://src/gameplay/battle_engine.gd")
const BattleCommandScript := preload("res://src/core/battle_command.gd")
const BattleContentAdapterScript := preload(
	"res://src/infrastructure/battle_content_adapter.gd"
)
const BattleBalanceAdapterScript := preload(
	"res://src/infrastructure/battle_balance_adapter.gd"
)
const BattleRandomAdapterScript := preload(
	"res://src/infrastructure/battle_random_adapter.gd"
)
const ProgressionEngineScript := preload(
	"res://src/gameplay/progression_engine.gd"
)
const ProgressionCommandScript := preload(
	"res://src/core/progression_command.gd"
)
const ProgressionContentAdapterScript := preload(
	"res://src/infrastructure/progression_content_adapter.gd"
)
const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")
const RouteContentAdapterScript := preload(
	"res://tools/simulation/v05_route_content_adapter.gd"
)
const SeededRandomServiceScript := preload(
	"res://src/infrastructure/seeded_random_service.gd"
)

const CARDS_PATH := "res://data/cards/v0.3.0/cards.json"
const PROGRESSION_PATH := "res://data/cards/v0.4.0/progression.json"
const BALANCE_PATH := "res://data/balance/v0.5.0/balance.json"
const ENEMIES_PATH := "res://data/enemies/v0.5.0/enemies.json"
const ENCOUNTERS_PATH := "res://data/encounters/v0.5.0/encounters.json"
const ROUTES_PATH := "res://data/routes/v0.5.0/routes.json"
const RITUALS_PATH := "res://data/rituals/v0.5.0/rituals.json"
const OUTPUT_PATH := "res://tools/simulation/out/v0.5.0_route_sampling.json"

const ROOT_SEED: int = 20261108
const SAMPLES_PER_CASE: int = 200
const ROUTE_ID: StringName = &"route.v050.first_case"

const IDENTITY_IDS: Array[String] = [
	"identity.reporter",
	"identity.doctor",
]

const STRATEGIES: Array[Dictionary] = [
	{
		"id": "aggressive",
		"description": "优先增伤、标记和直接伤害，奖励偏向墨刺碎片。",
		"reward_id": &"reward.ink_dart_fragments",
		"ritual_accuracy": 0.82,
		"rest_mode": "aggressive",
		"rest_weights": {
			"hp": 0.75,
			"corruption": 5.0,
			"spirit_cap": 8.0,
			"attention_cost": 2.0,
		},
		"upgrade_priority": [
			&"card.skill.ink_dart",
			&"card.skill.omen",
			&"card.skill.focus",
			&"card.skill.paper_guard",
		],
		"card_priority": [
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
		"id": "balanced",
		"description": "兼顾护甲、标记和输出，奖励偏向占卜券。",
		"reward_id": &"reward.divination_tickets",
		"ritual_accuracy": 0.90,
		"rest_mode": "balanced",
		"rest_weights": {
			"hp": 1.0,
			"corruption": 6.0,
			"spirit_cap": 6.0,
			"attention_cost": 3.0,
		},
		"upgrade_priority": [
			&"card.skill.ink_dart",
			&"card.skill.paper_guard",
			&"card.skill.omen",
			&"card.skill.whisper",
			&"card.skill.calm_breath",
		],
		"card_priority": [
			&"card.skill.focus",
			&"card.skill.insight",
			&"card.skill.paper_guard",
			&"card.skill.omen",
			&"card.skill.ink_dart",
			&"card.skill.whisper",
			&"card.skill.calm_breath",
			&"card.skill.second_look",
		],
	},
	{
		"id": "defensive",
		"description": "优先护甲、治疗和削弱，奖励偏向可稳定转化的碎片。",
		"reward_id": &"reward.ink_dart_fragments",
		"ritual_accuracy": 0.95,
		"rest_mode": "defensive",
		"rest_weights": {
			"hp": 1.4,
			"corruption": 8.0,
			"spirit_cap": 4.0,
			"attention_cost": 4.0,
		},
		"upgrade_priority": [
			&"card.skill.paper_guard",
			&"card.skill.calm_breath",
			&"card.skill.ink_dart",
			&"card.skill.omen",
			&"card.skill.whisper",
		],
		"card_priority": [
			&"card.skill.paper_guard",
			&"card.skill.whisper",
			&"card.skill.calm_breath",
			&"card.skill.focus",
			&"card.skill.insight",
			&"card.skill.omen",
			&"card.skill.ink_dart",
			&"card.skill.second_look",
		],
	},
]

var _cards_document: Dictionary
var _progression_document: Dictionary
var _balance_document: Dictionary
var _enemies_document: Dictionary
var _encounters_document: Dictionary
var _routes_document: Dictionary
var _rituals_document: Dictionary


func _ready() -> void:
	_cards_document = _load_json(CARDS_PATH)
	_progression_document = _load_json(PROGRESSION_PATH)
	_balance_document = _load_json(BALANCE_PATH)
	_enemies_document = _load_json(ENEMIES_PATH)
	_encounters_document = _load_json(ENCOUNTERS_PATH)
	_routes_document = _load_json(ROUTES_PATH)
	_rituals_document = _load_json(RITUALS_PATH)
	if (
		_cards_document.is_empty()
		or _progression_document.is_empty()
		or _balance_document.is_empty()
		or _enemies_document.is_empty()
		or _encounters_document.is_empty()
		or _routes_document.is_empty()
		or _rituals_document.is_empty()
	):
		get_tree().quit(1)
		return

	var results: Array[Dictionary] = []
	for strategy in STRATEGIES:
		for identity_id in IDENTITY_IDS:
			results.append(_sample_case(strategy, identity_id))

	var output: Dictionary = {
		"version": "v0.5.0",
		"engine": "RouteEngine+BattleEngine+ProgressionEngine",
		"root_seed": ROOT_SEED,
		"samples_per_case": SAMPLES_PER_CASE,
		"route_id": String(ROUTE_ID),
		"sources": {
			"cards": CARDS_PATH,
			"progression": PROGRESSION_PATH,
			"balance": BALANCE_PATH,
			"enemies": ENEMIES_PATH,
			"encounters": ENCOUNTERS_PATH,
			"routes": ROUTES_PATH,
			"rituals": RITUALS_PATH,
		},
		"time_model_minutes": {
			"battle_round_conservative": 0.55,
			"battle_round_relaxed": 1.0,
			"battle_enter_and_result": 0.75,
			"route_identity": 0.5,
			"rest_choice": 1.5,
			"ritual_step": 0.4,
			"gacha_decision": 1.2,
			"upgrade_decision": 0.7,
			"note": "Planning estimate only; no human timing sample yet.",
		},
		"cases": results,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write route sampling output: %s" % OUTPUT_PATH)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()

	print(JSON.stringify({
		"version": output["version"],
		"root_seed": ROOT_SEED,
		"samples_per_case": SAMPLES_PER_CASE,
		"cases": results,
	}, "\t"))
	get_tree().quit(0)


func _sample_case(strategy: Dictionary, identity_id: String) -> Dictionary:
	var valid_runs: int = 0
	var completed_runs: int = 0
	var battle_victories: Dictionary = {}
	var battle_round_totals: Dictionary = {}
	var battle_runs: Dictionary = {}
	var total_rounds: int = 0
	var total_pressure_events: int = 0
	var total_boss_phase_events: int = 0
	var total_ritual_errors: int = 0
	var total_gacha_pulls: int = 0
	var total_upgrades: int = 0
	var total_conservative_minutes: float = 0.0
	var total_relaxed_minutes: float = 0.0
	var final_health_total: int = 0
	var final_corruption_total: int = 0
	var final_attention_total: int = 0
	var final_sequence_total: int = 0
	var rest_counts: Dictionary = {}
	var failure_reasons: Dictionary = {}

	for sample_index in range(SAMPLES_PER_CASE):
		var seed_value: int = ROOT_SEED + sample_index * 104729
		var route_result: Dictionary = _simulate_route(
			strategy,
			identity_id,
			seed_value
		)
		if not bool(route_result.get("valid", false)):
			var reason := String(route_result.get("reason", "unknown"))
			failure_reasons[reason] = int(failure_reasons.get(reason, 0)) + 1
			continue
		valid_runs += 1
		if bool(route_result["completed"]):
			completed_runs += 1
		total_rounds += int(route_result["total_rounds"])
		total_pressure_events += int(route_result["pressure_events"])
		total_boss_phase_events += int(route_result["boss_phase_events"])
		total_ritual_errors += int(route_result["ritual_errors"])
		total_gacha_pulls += int(route_result["gacha_pulls"])
		total_upgrades += int(route_result["upgrades"])
		total_conservative_minutes += float(route_result["conservative_minutes"])
		total_relaxed_minutes += float(route_result["relaxed_minutes"])
		final_health_total += int(route_result["final_health"])
		final_corruption_total += int(route_result["final_corruption"])
		final_attention_total += int(route_result["final_attention"])
		final_sequence_total += int(route_result["sequence"])
		var rest_id := String(route_result["rest_id"])
		if not rest_id.is_empty():
			rest_counts[rest_id] = int(rest_counts.get(rest_id, 0)) + 1
		for node_id in route_result["battle_rounds"]:
			battle_round_totals[node_id] = (
				int(battle_round_totals.get(node_id, 0))
				+ int(route_result["battle_rounds"][node_id])
			)
			battle_runs[node_id] = int(battle_runs.get(node_id, 0)) + 1
			if bool(route_result["battle_wins"].get(node_id, false)):
				battle_victories[node_id] = (
					int(battle_victories.get(node_id, 0)) + 1
				)
		if not bool(route_result["completed"]):
			var failure := String(route_result["failed_at"])
			failure_reasons[failure] = int(failure_reasons.get(failure, 0)) + 1

	var battle_averages: Dictionary = {}
	for node_id in battle_runs:
		battle_averages[node_id] = {
			"runs": int(battle_runs[node_id]),
			"win_rate": (
				float(battle_victories.get(node_id, 0))
				/ float(battle_runs[node_id])
			),
			"average_rounds": (
				float(battle_round_totals.get(node_id, 0))
				/ float(battle_runs[node_id])
			),
		}
	var divisor: float = float(valid_runs) if valid_runs > 0 else 1.0
	var conservative_average: float = total_conservative_minutes / divisor
	var relaxed_average: float = total_relaxed_minutes / divisor
	var midpoint_average: float = (
		conservative_average + relaxed_average
	) * 0.5
	return {
		"id": "%s.%s" % [
			String(strategy["id"]),
			identity_id.trim_prefix("identity."),
		],
		"strategy_id": String(strategy["id"]),
		"identity_id": identity_id,
		"ritual_accuracy_assumption": float(strategy["ritual_accuracy"]),
		"samples": SAMPLES_PER_CASE,
		"valid_runs": valid_runs,
		"route_completion_rate": (
			0.0 if valid_runs == 0 else float(completed_runs) / float(valid_runs)
		),
		"ascension_completion_rate": (
			0.0 if valid_runs == 0 else float(completed_runs) / float(valid_runs)
		),
		"average_total_rounds": 0.0 if valid_runs == 0 else float(total_rounds) / divisor,
		"average_pressure_events": (
			0.0 if valid_runs == 0 else float(total_pressure_events) / divisor
		),
		"average_boss_phase_events": (
			0.0 if valid_runs == 0 else float(total_boss_phase_events) / divisor
		),
		"average_ritual_errors": (
			0.0 if valid_runs == 0 else float(total_ritual_errors) / divisor
		),
		"average_gacha_pulls": (
			0.0 if valid_runs == 0 else float(total_gacha_pulls) / divisor
		),
		"average_upgrades": (
			0.0 if valid_runs == 0 else float(total_upgrades) / divisor
		),
		"average_final_health": (
			0.0 if valid_runs == 0 else float(final_health_total) / divisor
		),
		"average_final_corruption": (
			0.0 if valid_runs == 0 else float(final_corruption_total) / divisor
		),
		"average_final_attention": (
			0.0 if valid_runs == 0 else float(final_attention_total) / divisor
		),
		"average_final_sequence": (
			9.0 if valid_runs == 0 else float(final_sequence_total) / divisor
		),
		"average_conservative_minutes": conservative_average,
		"average_relaxed_minutes": relaxed_average,
		"average_estimated_minutes": midpoint_average,
		"target_15_30_met_conservative": (
			conservative_average >= 15.0 and conservative_average <= 30.0
		),
		"target_15_30_met_relaxed": (
			relaxed_average >= 15.0 and relaxed_average <= 30.0
		),
		"target_15_30_met_midpoint": (
			midpoint_average >= 15.0 and midpoint_average <= 30.0
		),
		"battle_profiles": battle_averages,
		"rest_choices": rest_counts,
		"failure_reasons": failure_reasons,
	}


func _simulate_route(
	strategy: Dictionary,
	identity_id: String,
	seed_value: int
) -> Dictionary:
	var base_content = BattleContentAdapterScript.new(
		_cards_document.get("cards", [])
	)
	var progression_content = ProgressionContentAdapterScript.new(
		_progression_document,
		base_content
	)
	var balance = BattleBalanceAdapterScript.new(_balance_document)
	var random_service = SeededRandomServiceScript.new(seed_value)
	var gacha_random = BattleRandomAdapterScript.new(
		random_service.get_stream(&"gacha.draw")
	)
	var progression = ProgressionEngineScript.new(
		progression_content,
		balance,
		gacha_random
	)
	var progression_result = progression.initialize()
	if not progression_result.accepted:
		return _invalid("progression_init:" + String(progression_result.reason_code))
	progression_result = progression.submit(
		ProgressionCommandScript.select_identity(StringName(identity_id))
	)
	if not progression_result.accepted:
		return _invalid("identity_select:" + String(progression_result.reason_code))

	var route_content = RouteContentAdapterScript.new(
		_routes_document,
		_rituals_document
	)
	var route_definition: Dictionary = route_content.get_route(ROUTE_ID)
	if route_definition.is_empty():
		return _invalid("route_missing")
	var run_state: Dictionary = progression.apply_battle_modifiers(
		route_definition["initial_run_state"].duplicate(true)
	)
	var nodes: Array = route_definition.get("nodes", [])
	if nodes.size() != 5:
		return _invalid("route_node_count")
	var initial_state: Dictionary = {
		"route_id": String(ROUTE_ID),
		"phase": "map",
		"available_node_id": String(nodes[0]["id"]),
		"selected_node_id": "",
		"completed_node_ids": [],
		"run_state": run_state,
		"ritual_state": {},
		"sequence_state": "locked",
		"route_outcome": "",
		"revision": 1,
	}
	var route = RouteEngineScript.new(route_content, ROUTE_ID)
	var route_result = route.initialize(initial_state)
	if not route_result.accepted:
		return _invalid("route_init:" + String(route_result.reason_code))

	var node_by_id: Dictionary = {}
	for node_value in nodes:
		node_by_id[String(node_value["id"])] = node_value.duplicate(true)
	var encounter_by_id: Dictionary = {}
	for encounter_value in _encounters_document.get("encounters", []):
		encounter_by_id[String(encounter_value["id"])] = encounter_value.duplicate(true)
	var ritual_definition: Dictionary = route_content.get_ritual(
		StringName(nodes[4].get("ritual_id", ""))
	)
	var battle_rounds: Dictionary = {}
	var battle_wins: Dictionary = {}
	var total_rounds: int = 0
	var pressure_events: int = 0
	var boss_phase_events: int = 0
	var ritual_errors: int = 0
	var gacha_pulls: int = 0
	var upgrades: int = 0
	var rest_id: String = ""
	var guard: int = 0
	var ritual_random := RandomNumberGenerator.new()
	ritual_random.seed = seed_value ^ 0x5F3759DF

	while guard < 60:
		guard += 1
		var route_snapshot: Dictionary = route.get_snapshot().data
		var phase := String(route_snapshot.get("phase", ""))
		if phase == "completed":
			break
		if phase == "failed":
			break
		if phase == "map":
			var available_id := String(route_snapshot.get("available_node_id", ""))
			var node: Dictionary = node_by_id.get(available_id, {})
			if node.is_empty():
				return _invalid("available_node_missing")
			if String(node.get("type", "")) == "ritual":
				var ritual_result := _run_ritual(
					route,
					ritual_definition,
					ritual_random,
					float(strategy["ritual_accuracy"])
				)
				if not bool(ritual_result.get("valid", false)):
					return ritual_result
				ritual_errors += int(ritual_result["errors"])
				continue
			route_result = route.submit(
				RouteCommandScript.select_node(StringName(available_id))
			)
			if not route_result.accepted:
				return _invalid("node_select:" + String(route_result.reason_code))
			continue
		if phase == "battle_pending":
			var node_id := String(route_snapshot.get("selected_node_id", ""))
			var node: Dictionary = node_by_id.get(node_id, {})
			var encounter: Dictionary = encounter_by_id.get(
				String(node.get("encounter_id", "")),
				{}
			)
			if encounter.is_empty():
				return _invalid("encounter_missing:" + node_id)
			var battle_result: Dictionary = _run_battle(
				strategy,
				progression,
				base_content,
				balance,
				random_service,
				route.get_battle_player_state(),
				encounter,
				node_id
			)
			if not bool(battle_result.get("valid", false)):
				return battle_result
			var outcome := (
				&"victory"
				if bool(battle_result["won"])
				else &"defeat"
			)
			battle_rounds[node_id] = int(battle_result["rounds"])
			battle_wins[node_id] = bool(battle_result["won"])
			total_rounds += int(battle_result["rounds"])
			pressure_events += int(battle_result["pressure_events"])
			boss_phase_events += int(battle_result["boss_phase_events"])
			progression_result = progression.submit(
				ProgressionCommandScript.resolve_battle(outcome)
			)
			if not progression_result.accepted:
				return _invalid(
					"progression_battle:" + String(progression_result.reason_code)
				)
			route_result = route.submit(
				RouteCommandScript.resolve_node(
					StringName(node_id),
					outcome,
					battle_result["player"]
				)
			)
			if not route_result.accepted:
				return _invalid("route_resolve:" + String(route_result.reason_code))
			if outcome == &"victory":
				var growth_result := _apply_reward_and_growth(
					progression,
					strategy
				)
				if not bool(growth_result.get("valid", false)):
					return growth_result
				gacha_pulls += int(growth_result["gacha_pulls"])
				upgrades += int(growth_result["upgrades"])
			continue
		if phase == "rest_pending":
			rest_id = _choose_rest(route_snapshot, strategy)
			if rest_id.is_empty():
				return _invalid("rest_missing")
			route_result = route.submit(
				RouteCommandScript.use_rest(StringName(rest_id))
			)
			if not route_result.accepted:
				return _invalid("rest:" + String(route_result.reason_code))
			continue
		if phase == "ritual":
			var ritual_result := _run_ritual(
				route,
				ritual_definition,
				ritual_random,
				float(strategy["ritual_accuracy"])
			)
			if not bool(ritual_result.get("valid", false)):
				return ritual_result
			ritual_errors += int(ritual_result["errors"])
			continue
		return _invalid("unexpected_phase:" + phase)

	if guard >= 60:
		return _invalid("route_guard")
	var final_snapshot: Dictionary = route.get_snapshot().data
	var completed := String(final_snapshot.get("route_outcome", "")) == "completed"
	var battle_count: int = battle_rounds.size()
	var fixed_minutes: float = (
		0.5
		+ float(battle_count) * 0.75
		+ (1.5 if not rest_id.is_empty() else 0.0)
		+ 3.0 * 0.4
		+ float(gacha_pulls) * 1.2 / 3.0
		+ float(upgrades) * 0.7
	)
	var conservative_minutes: float = (
		float(total_rounds) * 0.55 + fixed_minutes
	)
	var relaxed_minutes: float = float(total_rounds) + fixed_minutes
	return {
		"valid": true,
		"completed": completed,
		"failed_at": "" if completed else _failed_node(final_snapshot),
		"total_rounds": total_rounds,
		"battle_rounds": battle_rounds,
		"battle_wins": battle_wins,
		"pressure_events": pressure_events,
		"boss_phase_events": boss_phase_events,
		"ritual_errors": ritual_errors,
		"gacha_pulls": gacha_pulls,
		"upgrades": upgrades,
		"rest_id": rest_id,
		"final_health": int(final_snapshot["run_state"]["hp"]),
		"final_corruption": int(final_snapshot["run_state"]["corruption"]),
		"final_attention": int(final_snapshot["run_state"]["attention"]),
		"sequence": int(final_snapshot.get("sequence", {}).get("current_sequence", 9)),
		"conservative_minutes": conservative_minutes,
		"relaxed_minutes": relaxed_minutes,
	}


func _run_battle(
	strategy: Dictionary,
	progression,
	base_content,
	balance,
	random_service,
	player_state: Dictionary,
	encounter: Dictionary,
	node_id: String
) -> Dictionary:
	var content = progression.create_upgraded_content(base_content)
	var random = BattleRandomAdapterScript.new(
		random_service.get_stream(
			StringName("battle.shuffle.%s" % node_id)
		)
	)
	var engine = BattleEngineScript.new()
	var deck: Array = progression.build_owned_battle_deck(
		encounter.get("deck_definition_ids", [])
	)
	var battle_id := StringName(
		"route.sim.%s.%d" % [node_id, random_service.root_seed]
	)
	var result = engine.initialize(
		content,
		balance,
		random,
		battle_id,
		player_state,
		deck,
		_enemy_configs(encounter, node_id)
	)
	if not result.accepted:
		return _invalid("battle_init:" + String(result.reason_code))

	var pressure_events: int = 0
	var boss_phase_events: int = 0
	var guard: int = 0
	while result.accepted and String(result.snapshot.data["outcome"]).is_empty():
		guard += 1
		if guard > 150:
			return _invalid("battle_guard")
		var command = _choose_command(engine, result.snapshot, strategy)
		result = engine.submit(command)
		if not result.accepted:
			return _invalid("battle_command:" + String(result.reason_code))
		for event in result.events:
			if event.type == &"EnemyPressureChanged":
				pressure_events += 1
			elif event.type == &"EnemyPhaseTriggered":
				var phase_id := String(event.data.get("phase_id", ""))
				if phase_id in [
					"phase.polished_mirror",
					"phase.broken_reflection",
				]:
					boss_phase_events += 1

	var snapshot: Dictionary = result.snapshot.data
	return {
		"valid": true,
		"won": String(snapshot["outcome"]) == "victory",
		"rounds": int(snapshot["round_number"]),
		"player": snapshot["player"].duplicate(true),
		"pressure_events": pressure_events,
		"boss_phase_events": boss_phase_events,
	}


func _choose_command(engine, snapshot, strategy: Dictionary):
	var priority: Array = strategy["card_priority"]
	for definition_id in priority:
		for card in snapshot.data["hand"]:
			if StringName(card["definition_id"]) != definition_id:
				continue
			var target_id := _target_for_card(snapshot.data, card)
			var playability = engine.query_card_play(
				StringName(card["instance_id"]),
				target_id
			)
			if playability.playable:
				return BattleCommandScript.play_card(
					StringName(card["instance_id"]),
					target_id
				)
	for card in snapshot.data["hand"]:
		var target_id := _target_for_card(snapshot.data, card)
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


func _apply_reward_and_growth(progression, strategy: Dictionary) -> Dictionary:
	var snapshot: Dictionary = progression.get_snapshot().data
	if String(snapshot.get("phase", "")) != "reward":
		return _invalid("progression_reward_phase")
	var reward_id := String(strategy["reward_id"])
	var offered: Array = []
	for option in snapshot.get("reward_options", []):
		offered.append(String(option.get("id", "")))
	if not reward_id in offered:
		reward_id = String(offered[0]) if not offered.is_empty() else ""
	if reward_id.is_empty():
		return _invalid("reward_missing")
	var result = progression.submit(
		ProgressionCommandScript.claim_reward(StringName(reward_id))
	)
	if not result.accepted:
		return _invalid("reward_claim:" + String(result.reason_code))

	var gacha_pulls: int = 0
	snapshot = progression.get_snapshot().data
	var costs: Dictionary = snapshot.get("gacha_costs", {})
	var tickets := int(snapshot.get("divination_tickets", 0))
	var pull_count: int = 0
	if tickets >= int(costs.get("triple", 9999)):
		pull_count = 3
	elif tickets >= int(costs.get("single", 9999)):
		pull_count = 1
	if pull_count > 0:
		result = progression.submit(
			ProgressionCommandScript.draw_gacha(pull_count)
		)
		if result.accepted:
			gacha_pulls = pull_count
		else:
			return _invalid("gacha:" + String(result.reason_code))

	var upgrades: int = 0
	snapshot = progression.get_snapshot().data
	var priority: Array = strategy["upgrade_priority"]
	var candidates: Array[String] = []
	for definition_id in priority:
		candidates.append(String(definition_id))
	for card in snapshot.get("collection", []):
		var definition_id := String(card.get("definition_id", ""))
		if not definition_id in candidates:
			candidates.append(definition_id)
	for definition_id in candidates:
		var card_view: Dictionary = _find_collection_card(
			snapshot.get("collection", []),
			definition_id
		)
		if card_view.is_empty():
			continue
		if (
			int(card_view.get("copies", 0)) <= 0
			or int(card_view.get("level", 0)) >= int(card_view.get("max_level", 0))
			or int(card_view.get("fragments", 0)) < int(card_view.get("next_upgrade_cost", 0))
			or int(card_view.get("next_upgrade_cost", 0)) <= 0
		):
			continue
		result = progression.submit(
			ProgressionCommandScript.upgrade_card(StringName(definition_id))
		)
		if result.accepted:
			upgrades = 1
		break
	return {
		"valid": true,
		"gacha_pulls": gacha_pulls,
		"upgrades": upgrades,
	}


func _run_ritual(
	route,
	ritual_definition: Dictionary,
	rng: RandomNumberGenerator,
	accuracy: float
) -> Dictionary:
	if route.get_snapshot().data.get("can_begin_ascension", false):
		var begin_result = route.submit(RouteCommandScript.begin_ascension())
		if not begin_result.accepted:
			return _invalid("ritual_begin:" + String(begin_result.reason_code))
	var errors: int = 0
	var error_used_steps: Dictionary = {}
	var guard: int = 0
	while guard < 20:
		guard += 1
		var route_snapshot: Dictionary = route.get_snapshot().data
		var ritual_snapshot: Dictionary = route.get_ritual_snapshot().data
		var status := String(ritual_snapshot.get("status", ""))
		if status == "completed" or status == "failed":
			return {"valid": true, "errors": errors}
		if String(route_snapshot.get("phase", "")) != "ritual":
			return _invalid("ritual_phase")
		var step_index := int(ritual_snapshot.get("step_index", 0))
		var steps: Array = ritual_definition.get("steps", [])
		if step_index < 0 or step_index >= steps.size():
			return _invalid("ritual_step")
		var step: Dictionary = steps[step_index]
		var use_wrong: bool = (
			not error_used_steps.has(step_index)
			and rng.randf() > accuracy
		)
		var selections: Array[String] = (
			_wrong_selections(step)
			if use_wrong
			else _correct_selections(step)
		)
		var result = route.submit(
			RouteCommandScript.submit_ritual_step(selections)
		)
		if not result.accepted:
			return _invalid("ritual_submit:" + String(result.reason_code))
		if use_wrong:
			error_used_steps[step_index] = true
			errors += 1
	return _invalid("ritual_guard")


func _correct_selections(step: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var step_type := String(step.get("type", ""))
	if step_type == "select_ids":
		for value in step.get("correct_ids", []):
			result.append(String(value))
	elif step_type == "ordered_ids":
		for value in step.get("correct_order", []):
			result.append(String(value))
	elif step_type == "select_id":
		result.append(String(step.get("correct_id", "")))
	return result


func _wrong_selections(step: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var step_type := String(step.get("type", ""))
	var option_ids: Array[String] = []
	for option in step.get("options", []):
		option_ids.append(String(option.get("id", "")))
	if step_type == "ordered_ids":
		var correct: Array[String] = _correct_selections(step)
		for index in range(correct.size() - 1, -1, -1):
			result.append(correct[index])
		return result
	if step_type == "select_ids":
		var correct: Array[String] = _correct_selections(step)
		var wrong_id := ""
		for option_id in option_ids:
			if not option_id in correct:
				wrong_id = option_id
				break
		if not correct.is_empty():
			result.append(correct[0])
		if not wrong_id.is_empty():
			result.append(wrong_id)
		return result
	var correct_id := String(step.get("correct_id", ""))
	for option_id in option_ids:
		if option_id != correct_id:
			result.append(option_id)
			break
	return result


func _choose_rest(snapshot: Dictionary, strategy: Dictionary) -> String:
	var rest_options: Array = snapshot.get("rest_options", [])
	if rest_options.is_empty():
		return ""
	var run_state: Dictionary = snapshot.get("run_state", {})
	var weights: Dictionary = strategy.get("rest_weights", {})
	var hp_value := float(weights.get("hp", 1.0))
	var corruption_value := float(weights.get("corruption", 6.0))
	var spirit_cap_value := float(weights.get("spirit_cap", 6.0))
	var attention_cost := float(weights.get("attention_cost", 3.0))
	var selected_id := ""
	var selected_score: float = -INF
	for option_value in rest_options:
		var option: Dictionary = option_value
		var effects: Dictionary = option.get("effects", {})
		var missing_hp := maxi(
			0,
			int(run_state.get("max_hp", 1)) - int(run_state.get("hp", 0))
		)
		var hp_gain := mini(missing_hp, maxi(0, int(effects.get("hp_delta", 0))))
		var corruption_removed := mini(
			maxi(0, int(run_state.get("corruption", 0))),
			maxi(0, -int(effects.get("corruption_delta", 0)))
		)
		var spirit_gain := maxi(0, int(effects.get("max_spirit_delta", 0)))
		var attention_gain := maxi(0, int(effects.get("attention_delta", 0)))
		var score := (
			float(hp_gain) * hp_value
			+ float(corruption_removed) * corruption_value
			+ float(spirit_gain) * spirit_cap_value
			- float(attention_gain) * attention_cost
		)
		if score > selected_score:
			selected_score = score
			selected_id = String(option.get("id", ""))
	return selected_id


func _enemy_configs(encounter: Dictionary, node_id: String) -> Array:
	var definitions: Array = _enemies_document.get("enemies", [])
	var by_id: Dictionary = {}
	for definition in definitions:
		by_id[String(definition["id"])] = definition
	var configs: Array = []
	for slot_value in encounter.get("enemy_slots", []):
		var slot: Dictionary = slot_value
		var source: Dictionary = by_id.get(String(slot["enemy_id"]), {})
		if source.is_empty():
			continue
		var lane := int(slot["lane_index"])
		configs.append({
			"id": StringName("%s.%s.lane.%d" % [node_id, source["id"], lane]),
			"definition_id": StringName(source["id"]),
			"lane_index": lane,
			"hp": int(source["base_health"]),
			"max_hp": int(source["base_health"]),
			"base_attack": int(source["base_attack"]),
			"phases": source.get("phases", []).duplicate(true),
		})
	return configs


func _find_collection_card(collection: Array, definition_id: String) -> Dictionary:
	for value in collection:
		var card: Dictionary = value
		if String(card.get("definition_id", "")) == definition_id:
			return card
	return {}


func _failed_node(snapshot: Dictionary) -> String:
	var selected := String(snapshot.get("selected_node_id", ""))
	if not selected.is_empty():
		return selected
	return String(snapshot.get("available_node_id", "route_failed"))


func _invalid(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open route simulation input: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Route simulation input is not a JSON object: %s" % path)
		return {}
	return parsed
