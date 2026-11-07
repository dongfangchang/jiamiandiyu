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
const RouteCommandScript := preload("res://src/core/route_command.gd")
const RouteContentAdapterScript := preload(
	"res://tools/simulation/v05_route_content_adapter.gd"
)
const SeededRandomServiceScript := preload(
	"res://src/infrastructure/seeded_random_service.gd"
)
const ChallengeEngineScript := preload(
	"res://src/gameplay/challenge_engine.gd"
)
const ChallengeCommandScript := preload(
	"res://src/core/challenge_command.gd"
)
const ChallengeContentAdapterScript := preload(
	"res://tools/simulation/v06_challenge_content_adapter.gd"
)
const IdentityRouteContentPortScript := preload(
	"res://tools/simulation/v06_identity_route_content_port.gd"
)

const CARDS_PATH := "res://data/cards/v0.3.0/cards.json"
const PROGRESSION_PATH := "res://data/cards/v0.4.0/progression.json"
const BALANCE_PATH := "res://data/balance/v0.6.0/balance.json"
const ENEMIES_PATH := "res://data/enemies/v0.5.0/enemies.json"
const ENCOUNTERS_PATH := "res://data/encounters/v0.5.0/encounters.json"
const ROUTES_PATH := "res://data/routes/v0.5.0/routes.json"
const RITUALS_PATH := "res://data/rituals/v0.5.0/rituals.json"
const CHALLENGES_PATH := "res://data/challenges/v0.6.0/challenges.json"
const OUTPUT_PATH := "res://tools/simulation/out/v0.6.0_challenge_sampling.json"

const ROOT_SEED: int = 20261108
const SAMPLES_PER_CASE: int = 100
const CHALLENGE_ID: StringName = &"challenge.v060.mirror_echoes"

const IDENTITY_IDS: Array[String] = [
	"identity.reporter",
	"identity.doctor",
]

const MODIFIER_IDS: Array[String] = [
	"modifier.rushed_reflection",
	"modifier.tainted_margins",
	"modifier.fractured_deck",
]

const STRATEGIES: Array[Dictionary] = [
	{
		"id": "aggressive",
		"reward_id": &"reward.ink_dart_fragments",
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
		"reward_id": &"reward.divination_tickets",
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
		"id": "neglect_corruption",
		"reward_id": &"reward.divination_tickets",
		"rest_mode": "neglect_corruption",
		"rest_weights": {
			"hp": 10.0,
			"corruption": 0.0,
			"spirit_cap": 0.0,
			"attention_cost": 0.0,
		},
		"upgrade_priority": [
			&"card.skill.ink_dart",
			&"card.skill.omen",
			&"card.skill.paper_guard",
		],
		"card_priority": [
			&"card.skill.focus",
			&"card.skill.omen",
			&"card.skill.ink_dart",
			&"card.skill.insight",
			&"card.skill.whisper",
			&"card.skill.paper_guard",
			&"card.skill.second_look",
			&"card.skill.calm_breath",
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
var _challenges_document: Dictionary


func _ready() -> void:
	_cards_document = _load_json(CARDS_PATH)
	_progression_document = _load_json(PROGRESSION_PATH)
	_balance_document = _load_json(BALANCE_PATH)
	_enemies_document = _load_json(ENEMIES_PATH)
	_encounters_document = _load_json(ENCOUNTERS_PATH)
	_routes_document = _load_json(ROUTES_PATH)
	_rituals_document = _load_json(RITUALS_PATH)
	_challenges_document = _load_json(CHALLENGES_PATH)
	if (
		_cards_document.is_empty()
		or _progression_document.is_empty()
		or _balance_document.is_empty()
		or _enemies_document.is_empty()
		or _encounters_document.is_empty()
		or _routes_document.is_empty()
		or _rituals_document.is_empty()
		or _challenges_document.is_empty()
	):
		get_tree().quit(1)
		return

	var cases: Array[Dictionary] = []
	for modifier_id in MODIFIER_IDS:
		for identity_id in IDENTITY_IDS:
			for strategy in STRATEGIES:
				cases.append(_sample_case(modifier_id, identity_id, strategy))

	var output: Dictionary = {
		"version": "v0.6.0",
		"engine": "ChallengeEngine+RouteEngine+BattleEngine+ProgressionEngine",
		"root_seed": ROOT_SEED,
		"samples_per_case": SAMPLES_PER_CASE,
		"challenge_id": String(CHALLENGE_ID),
		"sources": {
			"cards": CARDS_PATH,
			"progression": PROGRESSION_PATH,
			"balance": BALANCE_PATH,
			"enemies": ENEMIES_PATH,
			"encounters": ENCOUNTERS_PATH,
			"routes": ROUTES_PATH,
			"rituals": RITUALS_PATH,
			"challenges": CHALLENGES_PATH,
		},
		"time_model_minutes": {
			"battle_round_conservative": 0.55,
			"battle_round_relaxed": 1.0,
			"battle_enter_and_result": 0.75,
			"challenge_selection": 1.5,
			"route_identity": 0.5,
			"rest_choice": 1.5,
			"ritual": 1.0,
			"gacha_decision": 1.0,
			"upgrade_decision": 0.7,
			"note": "Planning estimate for challenge repeat play, not a human timing sample.",
		},
		"cases": cases,
		"modifier_summary": _summarize_modifiers(cases),
	}

	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write challenge sampling output: %s" % OUTPUT_PATH)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()

	print(JSON.stringify({
		"version": output["version"],
		"root_seed": ROOT_SEED,
		"samples_per_case": SAMPLES_PER_CASE,
		"cases": cases,
		"modifier_summary": output["modifier_summary"],
	}, "\t"))
	get_tree().quit(0)


func _sample_case(
	modifier_id: String,
	identity_id: String,
	strategy: Dictionary
) -> Dictionary:
	var valid_runs: int = 0
	var completed_runs: int = 0
	var total_rounds: int = 0
	var total_pressure_events: int = 0
	var total_boss_phase_events: int = 0
	var total_gacha_pulls: int = 0
	var total_upgrades: int = 0
	var total_conservative_minutes: float = 0.0
	var total_relaxed_minutes: float = 0.0
	var total_final_health: int = 0
	var total_final_corruption: int = 0
	var total_final_attention: int = 0
	var total_initial_corruption: int = 0
	var total_initial_attention: int = 0
	var total_initial_deck_cards: int = 0
	var total_first_phase_rounds: int = 0
	var first_phase_samples: int = 0
	var total_prepared_min_phase_rounds: int = 0
	var prepared_phase_samples: int = 0
	var rest_counts: Dictionary = {}
	var failure_reasons: Dictionary = {}
	var collection_preserved_failures: int = 0
	var failed_runs: int = 0

	for sample_index in range(SAMPLES_PER_CASE):
		var seed_value: int = ROOT_SEED + sample_index * 104729
		var route_result: Dictionary = _simulate_challenge(
			modifier_id,
			identity_id,
			strategy,
			seed_value
		)
		if not bool(route_result.get("valid", false)):
			var reason := String(route_result.get("reason", "unknown"))
			failure_reasons[reason] = int(failure_reasons.get(reason, 0)) + 1
			continue
		valid_runs += 1
		if bool(route_result["completed"]):
			completed_runs += 1
		else:
			failed_runs += 1
			if bool(route_result["collection_preserved"]):
				collection_preserved_failures += 1
			var failed_at := String(route_result.get("failed_at", "unknown"))
			failure_reasons[failed_at] = int(failure_reasons.get(failed_at, 0)) + 1
		total_rounds += int(route_result["total_rounds"])
		total_pressure_events += int(route_result["pressure_events"])
		total_boss_phase_events += int(route_result["boss_phase_events"])
		total_gacha_pulls += int(route_result["gacha_pulls"])
		total_upgrades += int(route_result["upgrades"])
		total_conservative_minutes += float(route_result["conservative_minutes"])
		total_relaxed_minutes += float(route_result["relaxed_minutes"])
		total_final_health += int(route_result["final_health"])
		total_final_corruption += int(route_result["final_corruption"])
		total_final_attention += int(route_result["final_attention"])
		total_initial_corruption += int(route_result["initial_corruption"])
		total_initial_attention += int(route_result["initial_attention"])
		total_initial_deck_cards += int(route_result["initial_deck_cards"])
		for phase_round in route_result.get("first_phase_rounds", []):
			total_first_phase_rounds += int(phase_round)
			first_phase_samples += 1
		for phase_round in route_result.get("prepared_min_phase_rounds", []):
			total_prepared_min_phase_rounds += int(phase_round)
			prepared_phase_samples += 1
		var rest_id := String(route_result["rest_id"])
		if not rest_id.is_empty():
			rest_counts[rest_id] = int(rest_counts.get(rest_id, 0)) + 1

	var divisor: float = float(valid_runs) if valid_runs > 0 else 1.0
	return {
		"id": "%s.%s.%s" % [
			modifier_id.trim_prefix("modifier."),
			identity_id.trim_prefix("identity."),
			String(strategy["id"]),
		],
		"modifier_id": modifier_id,
		"identity_id": identity_id,
		"strategy_id": String(strategy["id"]),
		"samples": SAMPLES_PER_CASE,
		"valid_runs": valid_runs,
		"completion_rate": 0.0 if valid_runs == 0 else float(completed_runs) / float(valid_runs),
		"average_initial_corruption": total_initial_corruption / divisor,
		"average_initial_attention": total_initial_attention / divisor,
		"average_initial_deck_cards": total_initial_deck_cards / divisor,
		"average_total_rounds": total_rounds / divisor,
		"average_pressure_events": total_pressure_events / divisor,
		"average_boss_phase_events": total_boss_phase_events / divisor,
		"average_first_phase_round": (
			float(total_first_phase_rounds) / float(first_phase_samples)
			if first_phase_samples > 0
			else 0.0
		),
		"average_prepared_min_phase_round": (
			float(total_prepared_min_phase_rounds) / float(prepared_phase_samples)
			if prepared_phase_samples > 0
			else 0.0
		),
		"average_gacha_pulls": total_gacha_pulls / divisor,
		"average_upgrades": total_upgrades / divisor,
		"average_final_health": total_final_health / divisor,
		"average_final_corruption": total_final_corruption / divisor,
		"average_final_attention": total_final_attention / divisor,
		"average_conservative_minutes": total_conservative_minutes / divisor,
		"average_relaxed_minutes": total_relaxed_minutes / divisor,
		"average_estimated_minutes": (
			total_conservative_minutes + total_relaxed_minutes
		) / (divisor * 2.0),
		"failed_runs": failed_runs,
		"collection_preserved_failures": collection_preserved_failures,
		"rest_choices": rest_counts,
		"failure_reasons": failure_reasons,
	}


func _simulate_challenge(
	modifier_id: String,
	identity_id: String,
	strategy: Dictionary,
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
	var progression = ProgressionEngineScript.new(
		progression_content,
		balance,
		BattleRandomAdapterScript.new(
			random_service.get_stream(&"gacha.draw")
		)
	)
	var progression_result = progression.initialize()
	if not progression_result.accepted:
		return _invalid("progression_init:" + String(progression_result.reason_code))
	progression_result = progression.submit(
		ProgressionCommandScript.select_identity(StringName(identity_id))
	)
	if not progression_result.accepted:
		return _invalid("identity_select:" + String(progression_result.reason_code))

	var route_base = RouteContentAdapterScript.new(
		_routes_document,
		_rituals_document
	)
	var identity_route = IdentityRouteContentPortScript.new(route_base, progression)
	var challenge_content = ChallengeContentAdapterScript.new(
		_challenges_document
	)
	var challenge = ChallengeEngineScript.new(
		identity_route,
		challenge_content,
		CHALLENGE_ID
	)
	var sequence_state: Dictionary = {
		"pathway": "seer",
		"current_sequence": 8,
		"advancement_state": "completed",
	}
	var challenge_result = challenge.initialize(sequence_state)
	if not challenge_result.accepted:
		return _invalid("challenge_init:" + String(challenge_result.reason_code))
	challenge_result = challenge.submit(
		ChallengeCommandScript.select_modifier(StringName(modifier_id))
	)
	if not challenge_result.accepted:
		return _invalid("modifier_select:" + String(challenge_result.reason_code))
	challenge_result = challenge.submit(
		ChallengeCommandScript.start_challenge()
	)
	if not challenge_result.accepted:
		return _invalid("challenge_start:" + String(challenge_result.reason_code))

	var route = challenge.get_route_engine()
	if route == null:
		return _invalid("route_missing")
	var route_definition: Dictionary = route_base.get_route(
		StringName("route.v050.first_case")
	)
	var nodes: Array = route_definition.get("nodes", [])
	if nodes.size() != 5:
		return _invalid("route_node_count")
	var route_snapshot: Dictionary = route.get_snapshot().data
	var initial_run_state: Dictionary = route_snapshot.get("run_state", {})
	var initial_corruption := int(initial_run_state.get("corruption", 0))
	var initial_attention := int(initial_run_state.get("attention", 0))
	var collection_before: Array = progression.get_snapshot().data.get(
		"collection",
		[]
	).duplicate(true)

	var node_by_id: Dictionary = {}
	for node_value in nodes:
		node_by_id[String(node_value["id"])] = node_value.duplicate(true)
	var encounter_by_id: Dictionary = {}
	for encounter_value in _encounters_document.get("encounters", []):
		encounter_by_id[String(encounter_value["id"])] = encounter_value.duplicate(true)
	var ritual_definition: Dictionary = route_base.get_ritual(
		StringName(nodes[4].get("ritual_id", ""))
	)

	var total_rounds: int = 0
	var battle_count: int = 0
	var pressure_events: int = 0
	var boss_phase_events: int = 0
	var first_phase_rounds: Array[int] = []
	var prepared_min_phase_rounds: Array[int] = []
	var gacha_pulls: int = 0
	var upgrades: int = 0
	var rest_id: String = ""
	var initial_deck_cards: int = 0
	var deck_count_recorded: bool = false
	var guard: int = 0

	while guard < 70:
		guard += 1
		route_snapshot = route.get_snapshot().data
		var phase := String(route_snapshot.get("phase", ""))
		if phase == "completed" or phase == "failed":
			break
		if phase == "map":
			var available_id := String(route_snapshot.get("available_node_id", ""))
			var node: Dictionary = node_by_id.get(available_id, {})
			if node.is_empty():
				return _invalid("available_node_missing")
			if String(node.get("type", "")) == "ritual":
				var ritual_result := _complete_ritual(challenge, route, ritual_definition)
				if not bool(ritual_result.get("valid", false)):
					return ritual_result
				continue
			challenge_result = challenge.submit(
				ChallengeCommandScript.forward_route(
					RouteCommandScript.select_node(StringName(available_id))
				)
			)
			if not challenge_result.accepted:
				return _invalid("node_select:" + String(challenge_result.reason_code))
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
			var player_state: Dictionary = challenge.get_battle_player_state()
			var battle_result: Dictionary = _run_battle(
				strategy,
				progression,
				base_content,
				balance,
				random_service,
				player_state,
				encounter,
				node_id,
				challenge,
				modifier_id
			)
			if not bool(battle_result.get("valid", false)):
				return battle_result
			if not deck_count_recorded:
				initial_deck_cards = int(battle_result["deck_size"])
				deck_count_recorded = true
			total_rounds += int(battle_result["rounds"])
			battle_count += 1
			pressure_events += int(battle_result["pressure_events"])
			boss_phase_events += int(battle_result["boss_phase_events"])
			first_phase_rounds.append_array(
				battle_result.get("first_phase_rounds", [])
			)
			prepared_min_phase_rounds.append_array(
				battle_result.get("prepared_min_phase_rounds", [])
			)
			var outcome := (
				&"victory"
				if bool(battle_result["won"])
				else &"defeat"
			)
			progression_result = progression.submit(
				ProgressionCommandScript.resolve_battle(outcome)
			)
			if not progression_result.accepted:
				return _invalid(
					"progression_battle:" + String(progression_result.reason_code)
				)
			challenge_result = challenge.submit(
				ChallengeCommandScript.forward_route(
					RouteCommandScript.resolve_node(
						StringName(node_id),
						outcome,
						battle_result["player"]
					)
				)
			)
			if not challenge_result.accepted:
				return _invalid("route_resolve:" + String(challenge_result.reason_code))
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
			challenge_result = challenge.submit(
				ChallengeCommandScript.forward_route(
					RouteCommandScript.use_rest(StringName(rest_id))
				)
			)
			if not challenge_result.accepted:
				return _invalid("rest:" + String(challenge_result.reason_code))
			continue
		if phase == "ritual":
			var ritual_result := _complete_ritual(challenge, route, ritual_definition)
			if not bool(ritual_result.get("valid", false)):
				return ritual_result
			continue
		return _invalid("unexpected_phase:" + phase)

	if guard >= 70:
		return _invalid("route_guard")
	route_snapshot = route.get_snapshot().data
	var completed := String(route_snapshot.get("route_outcome", "")) == "completed"
	var run_state: Dictionary = route_snapshot.get("run_state", {})
	var collection_after: Array = progression.get_snapshot().data.get(
		"collection",
		[]
	)
	var collection_preserved := (
		not completed
		and _collection_not_reduced(collection_before, collection_after)
	)
	var fixed_minutes: float = (
		1.5
		+ float(battle_count) * 0.75
		+ 1.5
		+ 1.0
		+ float(gacha_pulls) * 1.0 / 3.0
		+ float(upgrades) * 0.7
	)
	return {
		"valid": true,
		"completed": completed,
		"failed_at": "" if completed else _failed_node(route_snapshot),
		"total_rounds": total_rounds,
		"pressure_events": pressure_events,
		"boss_phase_events": boss_phase_events,
		"first_phase_rounds": first_phase_rounds,
		"prepared_min_phase_rounds": prepared_min_phase_rounds,
		"gacha_pulls": gacha_pulls,
		"upgrades": upgrades,
		"rest_id": rest_id,
		"initial_corruption": initial_corruption,
		"initial_attention": initial_attention,
		"initial_deck_cards": initial_deck_cards,
		"final_health": int(run_state.get("hp", 0)),
		"final_corruption": int(run_state.get("corruption", 0)),
		"final_attention": int(run_state.get("attention", 0)),
		"collection_preserved": collection_preserved,
		"completion_reward": challenge.get_completion_reward(),
		"conservative_minutes": float(total_rounds) * 0.55 + fixed_minutes,
		"relaxed_minutes": float(total_rounds) + fixed_minutes,
	}


func _run_battle(
	strategy: Dictionary,
	progression,
	base_content,
	balance,
	random_service: SeededRandomService,
	player_state: Dictionary,
	encounter: Dictionary,
	node_id: String,
	challenge,
	modifier_id: String
) -> Dictionary:
	var content = progression.create_upgraded_content(base_content)
	var random = BattleRandomAdapterScript.new(
		random_service.get_stream(
			StringName("challenge.battle.%s.%s" % [modifier_id, node_id])
		)
	)
	var deck: Array = progression.build_owned_battle_deck(
		encounter.get("deck_definition_ids", [])
	)
	deck = challenge.build_battle_deck(deck)
	var enemies: Array = _enemy_configs(encounter)
	enemies = challenge.prepare_enemy_configs(enemies)
	var prepared_min_phase_rounds: Array[int] = []
	for enemy in enemies:
		var phases: Array = enemy.get("phases", [])
		if not phases.is_empty():
			prepared_min_phase_rounds.append(int(phases[0].get("at_round", 0)))
	var engine = BattleEngineScript.new()
	var battle_id := StringName(
		"challenge.sim.%s.%s.%d" % [modifier_id, node_id, random_service.root_seed]
	)
	var result = engine.initialize(
		content,
		balance,
		random,
		battle_id,
		player_state,
		deck,
		enemies
	)
	if not result.accepted:
		return _invalid("battle_init:" + String(result.reason_code))

	var pressure_events: int = 0
	var boss_phase_events: int = 0
	var first_phase_rounds: Array[int] = []
	var battle_first_phase_round: int = 0
	for event in result.events:
		if event.type == &"EnemyPressureChanged":
			pressure_events += 1
		elif event.type == &"EnemyPhaseTriggered":
			boss_phase_events += 1
			var initial_phase_round := int(event.data.get("round_number", 0))
			if (
				initial_phase_round > 0
				and (
					battle_first_phase_round == 0
					or initial_phase_round < battle_first_phase_round
				)
			):
				battle_first_phase_round = initial_phase_round
	var guard: int = 0
	while result.accepted and String(result.snapshot.data["outcome"]).is_empty():
		guard += 1
		if guard > 150:
			return _invalid("battle_guard")
		result = engine.submit(_choose_command(engine, result.snapshot, strategy))
		if not result.accepted:
			return _invalid("battle_command:" + String(result.reason_code))
		for event in result.events:
			if event.type == &"EnemyPressureChanged":
				pressure_events += 1
			elif event.type == &"EnemyPhaseTriggered":
				boss_phase_events += 1
				var phase_round := int(event.data.get("round_number", 0))
				if (
					phase_round > 0
					and (
						battle_first_phase_round == 0
						or phase_round < battle_first_phase_round
					)
				):
					battle_first_phase_round = phase_round

	if battle_first_phase_round > 0:
		first_phase_rounds.append(battle_first_phase_round)

	var snapshot: Dictionary = result.snapshot.data
	return {
		"valid": true,
		"won": String(snapshot["outcome"]) == "victory",
		"rounds": int(snapshot["round_number"]),
		"player": snapshot["player"].duplicate(true),
		"pressure_events": pressure_events,
		"boss_phase_events": boss_phase_events,
		"first_phase_rounds": first_phase_rounds,
		"prepared_min_phase_rounds": prepared_min_phase_rounds,
		"deck_size": deck.size(),
	}


func _choose_command(engine, snapshot, strategy: Dictionary):
	for definition_id in strategy["card_priority"]:
		for card in snapshot.data["hand"]:
			if StringName(card["definition_id"]) != definition_id:
				continue
			var target_id := _target_for_card(snapshot.data, card)
			if engine.query_card_play(
				StringName(card["instance_id"]),
				target_id
			).playable:
				return BattleCommandScript.play_card(
					StringName(card["instance_id"]),
					target_id
				)
	for card in snapshot.data["hand"]:
		var target_id := _target_for_card(snapshot.data, card)
		if engine.query_card_play(
			StringName(card["instance_id"]),
			target_id
		).playable:
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
	for definition_id in strategy["upgrade_priority"]:
		var card_view: Dictionary = _find_collection_card(
			snapshot.get("collection", []),
			String(definition_id)
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


func _complete_ritual(
	challenge,
	route,
	ritual_definition: Dictionary
) -> Dictionary:
	if bool(route.get_snapshot().data.get("can_begin_ascension", false)):
		var begin_result = challenge.submit(
			ChallengeCommandScript.forward_route(
				RouteCommandScript.begin_ascension()
			)
		)
		if not begin_result.accepted:
			return _invalid("ritual_begin:" + String(begin_result.reason_code))
	var guard: int = 0
	while guard < 20:
		guard += 1
		var ritual_snapshot: Dictionary = route.get_ritual_snapshot().data
		var status := String(ritual_snapshot.get("status", ""))
		if status == "completed" or status == "failed":
			return {"valid": true}
		if String(route.get_snapshot().data.get("phase", "")) != "ritual":
			return _invalid("ritual_phase")
		var step_index := int(ritual_snapshot.get("step_index", 0))
		var steps: Array = ritual_definition.get("steps", [])
		if step_index < 0 or step_index >= steps.size():
			return _invalid("ritual_step")
		var selections := _correct_selections(steps[step_index])
		var result = challenge.submit(
			ChallengeCommandScript.forward_route(
				RouteCommandScript.submit_ritual_step(selections)
			)
		)
		if not result.accepted:
			return _invalid("ritual_submit:" + String(result.reason_code))
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


func _choose_rest(snapshot: Dictionary, strategy: Dictionary) -> String:
	var rest_options: Array = snapshot.get("rest_options", [])
	if rest_options.is_empty():
		return ""
	var run_state: Dictionary = snapshot.get("run_state", {})
	var weights: Dictionary = strategy.get("rest_weights", {})
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
			float(hp_gain) * float(weights.get("hp", 1.0))
			+ float(corruption_removed) * float(weights.get("corruption", 6.0))
			+ float(spirit_gain) * float(weights.get("spirit_cap", 6.0))
			- float(attention_gain) * float(weights.get("attention_cost", 3.0))
		)
		if score > selected_score:
			selected_score = score
			selected_id = String(option.get("id", ""))
	return selected_id


func _enemy_configs(encounter: Dictionary) -> Array:
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
			"id": StringName("%s.lane.%d" % [source["id"], lane]),
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


func _collection_not_reduced(before: Array, after: Array) -> bool:
	var after_by_id: Dictionary = {}
	for value in after:
		var card: Dictionary = value
		after_by_id[String(card.get("definition_id", ""))] = card
	for value in before:
		var original: Dictionary = value
		var definition_id := String(original.get("definition_id", ""))
		var current: Dictionary = after_by_id.get(definition_id, {})
		if current.is_empty():
			return false
		if int(current.get("copies", 0)) < int(original.get("copies", 0)):
			return false
		if int(current.get("level", 0)) < int(original.get("level", 0)):
			return false
	return true


func _failed_node(snapshot: Dictionary) -> String:
	var selected := String(snapshot.get("selected_node_id", ""))
	return selected if not selected.is_empty() else String(
		snapshot.get("available_node_id", "route_failed")
	)


func _summarize_modifiers(cases: Array[Dictionary]) -> Dictionary:
	var summary: Dictionary = {}
	for modifier_id in MODIFIER_IDS:
		var valid_runs: int = 0
		var completed_runs: int = 0
		var initial_corruption: float = 0.0
		var initial_attention: float = 0.0
		var deck_cards: float = 0.0
		var boss_phases: float = 0.0
		var first_phase_rounds: float = 0.0
		var first_phase_round_count: int = 0
		var prepared_phase_rounds: float = 0.0
		var prepared_phase_round_count: int = 0
		var estimated_minutes: float = 0.0
		for case_value in cases:
			var case: Dictionary = case_value
			if String(case.get("modifier_id", "")) != modifier_id:
				continue
			var count := int(case.get("valid_runs", 0))
			valid_runs += count
			completed_runs += int(round(
				float(case.get("completion_rate", 0.0)) * float(count)
			))
			initial_corruption += float(case.get("average_initial_corruption", 0.0)) * count
			initial_attention += float(case.get("average_initial_attention", 0.0)) * count
			deck_cards += float(case.get("average_initial_deck_cards", 0.0)) * count
			boss_phases += float(case.get("average_boss_phase_events", 0.0)) * count
			var first_phase_round := float(
				case.get("average_first_phase_round", 0.0)
			)
			if first_phase_round > 0.0:
				first_phase_rounds += first_phase_round * float(count)
				first_phase_round_count += count
			var prepared_phase_round := float(
				case.get("average_prepared_min_phase_round", 0.0)
			)
			if prepared_phase_round > 0.0:
				prepared_phase_rounds += prepared_phase_round * float(count)
				prepared_phase_round_count += count
			estimated_minutes += float(case.get("average_estimated_minutes", 0.0)) * count
		var divisor: float = float(valid_runs) if valid_runs > 0 else 1.0
		summary[modifier_id] = {
			"valid_runs": valid_runs,
			"completion_rate": 0.0 if valid_runs == 0 else float(completed_runs) / divisor,
			"average_initial_corruption": initial_corruption / divisor,
			"average_initial_attention": initial_attention / divisor,
			"average_initial_deck_cards": deck_cards / divisor,
			"average_boss_phase_events": boss_phases / divisor,
			"average_first_phase_round": (
				first_phase_rounds / float(first_phase_round_count)
				if first_phase_round_count > 0
				else 0.0
			),
			"average_prepared_min_phase_round": (
				prepared_phase_rounds / float(prepared_phase_round_count)
				if prepared_phase_round_count > 0
				else 0.0
			),
			"average_estimated_minutes": estimated_minutes / divisor,
		}
	return summary


func _invalid(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open challenge simulation input: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Challenge simulation input is not a JSON object: %s" % path)
		return {}
	return parsed
