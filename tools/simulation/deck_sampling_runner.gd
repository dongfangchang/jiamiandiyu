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
const DeckEngineScript := preload("res://src/gameplay/deck_engine.gd")
const DeckCommandScript := preload("res://src/core/deck_command.gd")
const DeckContentAdapterScript := preload(
	"res://tools/simulation/v07_deck_content_adapter.gd"
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
const IdentityRouteContentPortScript := preload(
	"res://tools/simulation/v06_identity_route_content_port.gd"
)
const ChallengeEngineScript := preload(
	"res://src/gameplay/challenge_engine.gd"
)
const ChallengeCommandScript := preload(
	"res://src/core/challenge_command.gd"
)
const ChallengeContentAdapterScript := preload(
	"res://tools/simulation/v07_challenge_content_adapter.gd"
)
const SeededRandomServiceScript := preload(
	"res://src/infrastructure/seeded_random_service.gd"
)

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const PROGRESSION_PATH := "res://data/cards/v0.7.0/progression.json"
const DECKS_PATH := "res://data/decks/v0.7.0/decks.json"
const BALANCE_PATH := "res://data/balance/v0.7.0/balance.json"
const ENEMIES_PATH := "res://data/enemies/v0.7.0/enemies.json"
const ENCOUNTERS_PATH := "res://data/encounters/v0.7.0/encounters.json"
const ROUTES_PATH := "res://data/routes/v0.7.0/routes.json"
const RITUALS_PATH := "res://data/rituals/v0.7.0/rituals.json"
const CHALLENGES_PATH := "res://data/challenges/v0.7.0/challenges.json"
const OUTPUT_PATH := "res://tools/simulation/out/v0.7.0_deck_sampling.json"

const ROOT_SEED: int = 20261108
const SAMPLES_PER_CASE: int = 30
const FIRST_ROUTE_ID: StringName = &"route.v070.first_case"
const FIRST_CHALLENGE_ID: StringName = &"challenge.v060.mirror_echoes"
const SECOND_CHALLENGE_ID: StringName = &"challenge.v070.broken_procession"
const FIRST_CHALLENGE_COMPLETED: String = "challenge.v060.mirror_echoes"

const IDENTITY_IDS: Array[String] = [
	"identity.reporter",
	"identity.doctor",
]

const DECK_STRATEGIES: Dictionary = {
	"deck.preset.ward": {
		"id": "ward",
		"reward_id": &"reward.ink_dart_fragments",
		"rest_weights": {
			"hp": 2.0,
			"corruption": 5.0,
			"spirit_cap": 5.0,
			"attention_cost": 2.0,
		},
		"upgrade_priority": [
			&"card.skill.paper_guard",
			&"card.skill.warding_circle",
			&"card.skill.coffin_nail",
			&"card.skill.ink_dart",
			&"card.skill.calm_breath",
		],
		"card_priority": [
			&"card.skill.focus",
			&"card.skill.paper_guard",
			&"card.skill.warding_circle",
			&"card.skill.lantern_step",
			&"card.skill.omen",
			&"card.skill.coffin_nail",
			&"card.skill.ink_dart",
			&"card.skill.calm_breath",
		],
	},
	"deck.preset.oracle": {
		"id": "oracle",
		"reward_id": &"reward.divination_tickets",
		"rest_weights": {
			"hp": 1.0,
			"corruption": 6.0,
			"spirit_cap": 6.0,
			"attention_cost": 3.0,
		},
		"upgrade_priority": [
			&"card.skill.whispered_hunch",
			&"card.skill.mirrored_memory",
			&"card.skill.coffin_nail",
			&"card.skill.ink_dart",
		],
		"card_priority": [
			&"card.skill.focus",
			&"card.skill.whispered_hunch",
			&"card.skill.mirrored_memory",
			&"card.skill.insight",
			&"card.skill.coffin_nail",
			&"card.skill.ink_dart",
			&"card.skill.paper_guard",
			&"card.skill.calm_breath",
		],
	},
	"deck.preset.burst": {
		"id": "burst",
		"reward_id": &"reward.ink_dart_fragments",
		"rest_weights": {
			"hp": 0.75,
			"corruption": 5.0,
			"spirit_cap": 8.0,
			"attention_cost": 2.0,
		},
		"upgrade_priority": [
			&"card.skill.coffin_nail",
			&"card.skill.ink_dart",
			&"card.skill.fated_echo",
			&"card.skill.piercing_omen",
		],
		"card_priority": [
			&"card.skill.focus",
			&"card.skill.omen",
			&"card.skill.fated_echo",
			&"card.skill.piercing_omen",
			&"card.skill.coffin_nail",
			&"card.skill.ink_dart",
			&"card.skill.paper_guard",
			&"card.skill.calm_breath",
		],
	},
}

var _cards_document: Dictionary
var _progression_document: Dictionary
var _decks_document: Dictionary
var _balance_document: Dictionary
var _enemies_document: Dictionary
var _encounters_document: Dictionary
var _routes_document: Dictionary
var _rituals_document: Dictionary
var _challenges_document: Dictionary
var _catalog_ids: Array[String] = []
var _scenarios: Array[Dictionary] = []


func _ready() -> void:
	_cards_document = _load_json(CARDS_PATH)
	_progression_document = _load_json(PROGRESSION_PATH)
	_decks_document = _load_json(DECKS_PATH)
	_balance_document = _load_json(BALANCE_PATH)
	_enemies_document = _load_json(ENEMIES_PATH)
	_encounters_document = _load_json(ENCOUNTERS_PATH)
	_routes_document = _load_json(ROUTES_PATH)
	_rituals_document = _load_json(RITUALS_PATH)
	_challenges_document = _load_json(CHALLENGES_PATH)
	if (
		_cards_document.is_empty()
		or _progression_document.is_empty()
		or _decks_document.is_empty()
		or _balance_document.is_empty()
		or _enemies_document.is_empty()
		or _encounters_document.is_empty()
		or _routes_document.is_empty()
		or _rituals_document.is_empty()
		or _challenges_document.is_empty()
	):
		push_error("v0.7 deck sampling input is incomplete")
		get_tree().quit(1)
		return
	for value in _decks_document.get("card_catalog_definition_ids", []):
		if value is String and not String(value) in _catalog_ids:
			_catalog_ids.append(String(value))
	_build_scenarios()

	var cases: Array[Dictionary] = []
	for preset_value in _decks_document.get("presets", []):
		if not preset_value is Dictionary:
			continue
		var preset_id := String(preset_value.get("id", ""))
		if not DECK_STRATEGIES.has(preset_id):
			push_error("No simulation strategy for deck preset: %s" % preset_id)
			get_tree().quit(1)
			return
		var strategy: Dictionary = DECK_STRATEGIES[preset_id]
		for identity_id in IDENTITY_IDS:
			for scenario in _scenarios:
				cases.append(_sample_case(
					preset_id,
					identity_id,
					scenario,
					strategy
				))

	var output := {
		"version": "v0.7.0",
		"engine": (
			"DeckEngine+ChallengeEngine+RouteEngine+BattleEngine+"
			+ "ProgressionEngine"
		),
		"root_seed": ROOT_SEED,
		"samples_per_case": SAMPLES_PER_CASE,
		"assumptions": {
			"profile": "late-profile collection owns all 16 cards at level 0",
			"purpose": "Compare preset construction and challenge pressure",
			"not_claimed": "Not a human timing sample or acquisition simulation",
		},
		"sources": {
			"cards": CARDS_PATH,
			"progression": PROGRESSION_PATH,
			"decks": DECKS_PATH,
			"balance": BALANCE_PATH,
			"enemies": ENEMIES_PATH,
			"encounters": ENCOUNTERS_PATH,
			"routes": ROUTES_PATH,
			"rituals": RITUALS_PATH,
			"challenges": CHALLENGES_PATH,
		},
		"campaign_time_model_minutes": {
			"battle_round_conservative": 0.55,
			"battle_round_relaxed": 1.0,
			"battle_enter_and_result": 0.75,
			"deck_selection": 1.0,
			"identity_selection": 0.5,
			"challenge_selection": 1.5,
			"rest_choice": 1.5,
			"ritual": 1.0,
			"gacha_decision": 1.0,
			"upgrade_decision": 0.7,
		},
		"scenarios": _scenarios.duplicate(true),
		"cases": cases,
		"deck_summary": _summarize_decks(cases),
		"scenario_summary": _summarize_scenarios(cases),
		"all_presets": _preset_ids(),
	}

	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write v0.7 deck sampling output: %s" % OUTPUT_PATH)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	print(JSON.stringify({
		"version": output["version"],
		"root_seed": ROOT_SEED,
		"samples_per_case": SAMPLES_PER_CASE,
		"deck_summary": output["deck_summary"],
		"scenario_summary": output["scenario_summary"],
	}, "\t"))
	get_tree().quit(0)


func _build_scenarios() -> void:
	_scenarios.append({
		"id": "route.first_case",
		"kind": "route",
		"route_id": String(FIRST_ROUTE_ID),
		"challenge_id": "",
		"modifier_id": "",
	})
	for challenge_id in [FIRST_CHALLENGE_ID, SECOND_CHALLENGE_ID]:
		var challenge := _challenge_by_id(String(challenge_id))
		for modifier_value in challenge.get("modifiers", []):
			if not modifier_value is Dictionary:
				continue
			var modifier_id := String(modifier_value.get("id", ""))
			_scenarios.append({
				"id": "%s.%s" % [
					String(challenge_id).trim_prefix("challenge."),
					modifier_id.trim_prefix("modifier."),
				],
				"kind": "challenge",
				"route_id": String(challenge.get("route_id", "")),
				"challenge_id": String(challenge_id),
				"modifier_id": modifier_id,
			})


func _sample_case(
	preset_id: String,
	identity_id: String,
	scenario: Dictionary,
	strategy: Dictionary
) -> Dictionary:
	var aggregate: Dictionary = {
		"valid_runs": 0,
		"completed_runs": 0,
		"total_rounds": 0,
		"total_minutes_conservative": 0.0,
		"total_minutes_relaxed": 0.0,
		"total_gacha_pulls": 0,
		"total_upgrades": 0,
		"total_final_health": 0,
		"total_final_corruption": 0,
		"total_final_attention": 0,
		"total_boss_phase_events": 0,
		"total_pressure_events": 0,
		"collection_preserved_failures": 0,
		"failed_runs": 0,
		"rest_choices": {},
		"failure_reasons": {},
		"card_usage": {},
	}
	for sample_index in range(SAMPLES_PER_CASE):
		var run := _simulate_run(
			preset_id,
			identity_id,
			scenario,
			strategy,
			ROOT_SEED + sample_index * 104729
		)
		if not bool(run.get("valid", false)):
			var invalid_reason := String(run.get("reason", "unknown"))
			var invalid_reasons: Dictionary = aggregate["failure_reasons"]
			invalid_reasons[invalid_reason] = int(invalid_reasons.get(invalid_reason, 0)) + 1
			continue
		aggregate["valid_runs"] = int(aggregate["valid_runs"]) + 1
		if bool(run["completed"]):
			aggregate["completed_runs"] = int(aggregate["completed_runs"]) + 1
		else:
			aggregate["failed_runs"] = int(aggregate["failed_runs"]) + 1
			if bool(run["collection_preserved"]):
				aggregate["collection_preserved_failures"] = (
					int(aggregate["collection_preserved_failures"]) + 1
				)
			var failed_at := String(run.get("failed_at", "unknown"))
			var failures: Dictionary = aggregate["failure_reasons"]
			failures[failed_at] = int(failures.get(failed_at, 0)) + 1
		aggregate["total_rounds"] += int(run["total_rounds"])
		aggregate["total_minutes_conservative"] += float(
			run["conservative_minutes"]
		)
		aggregate["total_minutes_relaxed"] += float(run["relaxed_minutes"])
		aggregate["total_gacha_pulls"] += int(run["gacha_pulls"])
		aggregate["total_upgrades"] += int(run["upgrades"])
		aggregate["total_final_health"] += int(run["final_health"])
		aggregate["total_final_corruption"] += int(run["final_corruption"])
		aggregate["total_final_attention"] += int(run["final_attention"])
		aggregate["total_boss_phase_events"] += int(run["boss_phase_events"])
		aggregate["total_pressure_events"] += int(run["pressure_events"])
		var rest_id := String(run.get("rest_id", ""))
		if not rest_id.is_empty():
			var rests: Dictionary = aggregate["rest_choices"]
			rests[rest_id] = int(rests.get(rest_id, 0)) + 1
		var usage: Dictionary = run.get("card_usage", {})
		var aggregate_usage: Dictionary = aggregate["card_usage"]
		for definition_id in usage:
			aggregate_usage[definition_id] = (
				int(aggregate_usage.get(definition_id, 0)) + int(usage[definition_id])
			)

	var valid: int = int(aggregate["valid_runs"])
	var divisor: float = float(valid) if valid > 0 else 1.0
	var deck_ids: Array[String] = []
	var deck_result := _initialize_deck(
		preset_id,
		identity_id,
		ROOT_SEED
	)
	if deck_result.get("valid", false):
		deck_ids = deck_result["deck"]
	return {
		"id": "%s.%s.%s" % [preset_id, identity_id, scenario["id"]],
		"preset_id": preset_id,
		"identity_id": identity_id,
		"scenario_id": String(scenario["id"]),
		"scenario_kind": String(scenario["kind"]),
		"challenge_id": String(scenario["challenge_id"]),
		"modifier_id": String(scenario["modifier_id"]),
		"strategy_id": String(strategy["id"]),
		"deck_definition_ids": deck_ids,
		"samples": SAMPLES_PER_CASE,
		"valid_runs": valid,
		"completion_rate": (
			0.0
			if valid == 0
			else float(aggregate["completed_runs"]) / divisor
		),
		"failed_runs": int(aggregate["failed_runs"]),
		"collection_preserved_failures": int(
			aggregate["collection_preserved_failures"]
		),
		"average_total_rounds": float(aggregate["total_rounds"]) / divisor,
		"average_gacha_pulls": float(aggregate["total_gacha_pulls"]) / divisor,
		"average_upgrades": float(aggregate["total_upgrades"]) / divisor,
		"average_final_health": float(aggregate["total_final_health"]) / divisor,
		"average_final_corruption": float(
			aggregate["total_final_corruption"]
		) / divisor,
		"average_final_attention": float(
			aggregate["total_final_attention"]
		) / divisor,
		"average_boss_phase_events": float(
			aggregate["total_boss_phase_events"]
		) / divisor,
		"average_pressure_events": float(
			aggregate["total_pressure_events"]
		) / divisor,
		"average_conservative_minutes": float(
			aggregate["total_minutes_conservative"]
		) / divisor,
		"average_relaxed_minutes": float(
			aggregate["total_minutes_relaxed"]
		) / divisor,
		"average_estimated_minutes": (
			float(aggregate["total_minutes_conservative"])
			+ float(aggregate["total_minutes_relaxed"])
		) / (divisor * 2.0),
		"rest_choices": aggregate["rest_choices"],
		"failure_reasons": aggregate["failure_reasons"],
		"card_usage": aggregate["card_usage"],
	}


func _simulate_run(
	preset_id: String,
	identity_id: String,
	scenario: Dictionary,
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
	var initial_progression_state := _make_full_collection_state(identity_id)
	var progression_initialized := progression.initialize(initial_progression_state)
	if not progression_initialized.accepted:
		return _invalid(
			"progression_init:" + String(progression_initialized.reason_code)
		)

	var deck_engine = DeckEngineScript.new(
		DeckContentAdapterScript.new(_decks_document),
		base_content
	)
	var deck_initialized = deck_engine.initialize(_catalog_ids)
	if not deck_initialized.accepted:
		return _invalid("deck_init:" + String(deck_initialized.reason_code))
	deck_initialized = deck_engine.submit(
		DeckCommandScript.select_preset(StringName(preset_id))
	)
	if not deck_initialized.accepted:
		return _invalid("deck_preset:" + String(deck_initialized.reason_code))
	deck_initialized = deck_engine.submit(DeckCommandScript.confirm_deck())
	if not deck_initialized.accepted:
		return _invalid("deck_confirm:" + String(deck_initialized.reason_code))
	var selected_deck: Array[String] = deck_engine.get_confirmed_deck_ids()
	if selected_deck.size() != 8:
		return _invalid("deck_size")

	var route_base = RouteContentAdapterScript.new(
		_routes_document,
		_rituals_document
	)
	var identity_route = IdentityRouteContentPortScript.new(
		route_base,
		progression
	)
	var challenge = null
	var route = null
	if String(scenario["kind"]) == "challenge":
		var challenge_content = ChallengeContentAdapterScript.new(
			_challenges_document
		)
		challenge = ChallengeEngineScript.new(
			identity_route,
			challenge_content,
			StringName(scenario["challenge_id"])
		)
		var sequence_state := _sequence_state_for_scenario(scenario)
		var challenge_result = challenge.initialize(sequence_state)
		if not challenge_result.accepted:
			return _invalid(
				"challenge_init:" + String(challenge_result.reason_code)
			)
		challenge_result = challenge.submit(
			ChallengeCommandScript.select_modifier(
				StringName(scenario["modifier_id"])
			)
		)
		if not challenge_result.accepted:
			return _invalid(
				"modifier_select:" + String(challenge_result.reason_code)
			)
		challenge_result = challenge.submit(
			ChallengeCommandScript.start_challenge()
		)
		if not challenge_result.accepted:
			return _invalid(
				"challenge_start:" + String(challenge_result.reason_code)
			)
		route = challenge.get_route_engine()
	else:
		route = RouteEngineScript.new(
			identity_route,
			StringName(scenario["route_id"])
		)
		var route_result = route.initialize({})
		if not route_result.accepted:
			return _invalid("route_init:" + String(route_result.reason_code))
	if route == null:
		return _invalid("route_missing")

	var route_definition: Dictionary = route_base.get_route(
		StringName(scenario["route_id"])
	)
	var nodes: Array = route_definition.get("nodes", [])
	if nodes.size() != 5:
		return _invalid("route_node_count")
	var nodes_by_id := {}
	for node_value in nodes:
		nodes_by_id[String(node_value["id"])] = node_value
	var encounters_by_id := {}
	for encounter_value in _encounters_document.get("encounters", []):
		encounters_by_id[String(encounter_value["id"])] = encounter_value
	var ritual_id := String(nodes[4].get("ritual_id", ""))
	var ritual_definition: Dictionary = route_base.get_ritual(
		StringName(ritual_id)
	)
	var collection_before: Array = progression.get_snapshot().data.get(
		"collection",
		[]
	).duplicate(true)

	var total_rounds: int = 0
	var pressure_events: int = 0
	var boss_phase_events: int = 0
	var gacha_pulls: int = 0
	var upgrades: int = 0
	var rest_id: String = ""
	var card_usage: Dictionary = {}
	var guard: int = 0

	while guard < 70:
		guard += 1
		var snapshot := _route_snapshot(route, challenge)
		var phase := String(snapshot.get("phase", ""))
		if phase == "completed" or phase == "failed":
			break
		if phase == "map":
			var available_id := String(snapshot.get("available_node_id", ""))
			var node: Dictionary = nodes_by_id.get(available_id, {})
			if node.is_empty():
				return _invalid("available_node_missing")
			if String(node.get("type", "")) == "ritual":
				var ritual_result := _complete_ritual(
					route,
					challenge,
					ritual_definition
				)
				if not bool(ritual_result.get("valid", false)):
					return ritual_result
				continue
			var select_command = RouteCommandScript.select_node(
				StringName(available_id)
			)
			var selected = _submit_route(route, challenge, select_command)
			if not selected.accepted:
				return _invalid("node_select:" + String(selected.reason_code))
			continue
		if phase == "battle_pending":
			var node_id := String(snapshot.get("selected_node_id", ""))
			var node: Dictionary = nodes_by_id.get(node_id, {})
			var encounter: Dictionary = encounters_by_id.get(
				String(node.get("encounter_id", "")),
				{}
			)
			if encounter.is_empty():
				return _invalid("encounter_missing:" + node_id)
			var player_state: Dictionary = (
				challenge.get_battle_player_state()
				if challenge != null
				else route.get_battle_player_state()
			)
			var battle_result := _run_battle(
				strategy,
				progression,
				base_content,
				balance,
				random_service,
				player_state,
				encounter,
				selected_deck,
				challenge,
				String(scenario["modifier_id"]),
				node_id
			)
			if not bool(battle_result.get("valid", false)):
				return battle_result
			total_rounds += int(battle_result["rounds"])
			pressure_events += int(battle_result["pressure_events"])
			boss_phase_events += int(battle_result["boss_phase_events"])
			_merge_usage(card_usage, battle_result["card_usage"])
			var outcome := (
				&"victory"
				if bool(battle_result["won"])
				else &"defeat"
			)
			var progression_result = progression.submit(
				ProgressionCommandScript.resolve_battle(outcome)
			)
			if not progression_result.accepted:
				return _invalid(
					"progression_battle:"
					+ String(progression_result.reason_code)
				)
			var resolve_command = RouteCommandScript.resolve_node(
				StringName(node_id),
				outcome,
				battle_result["player"]
			)
			var resolved = _submit_route(route, challenge, resolve_command)
			if not resolved.accepted:
				return _invalid("route_resolve:" + String(resolved.reason_code))
			if outcome == &"victory":
				var growth := _apply_reward_and_growth(
					progression,
					strategy,
					preset_id
				)
				if not bool(growth.get("valid", false)):
					return growth
				gacha_pulls += int(growth["gacha_pulls"])
				upgrades += int(growth["upgrades"])
			continue
		if phase == "rest_pending":
			rest_id = _choose_rest(snapshot, strategy)
			if rest_id.is_empty():
				return _invalid("rest_missing")
			var rest_result = _submit_route(
				route,
				challenge,
				RouteCommandScript.use_rest(StringName(rest_id))
			)
			if not rest_result.accepted:
				return _invalid("rest:" + String(rest_result.reason_code))
			continue
		if phase == "ritual":
			var ritual_result := _complete_ritual(
				route,
				challenge,
				ritual_definition
			)
			if not bool(ritual_result.get("valid", false)):
				return ritual_result
			continue
		return _invalid("unexpected_phase:" + phase)

	if guard >= 70:
		return _invalid("route_guard")
	var final_snapshot := _route_snapshot(route, challenge)
	var completed := String(final_snapshot.get("route_outcome", "")) == "completed"
	var run_state: Dictionary = final_snapshot.get("run_state", {})
	var collection_after: Array = progression.get_snapshot().data.get(
		"collection",
		[]
	)
	var fixed_minutes: float = (
		1.0
		+ 0.5
		+ (1.5 if challenge != null else 0.0)
		+ 1.5
		+ 1.0
		+ float(gacha_pulls) * 1.0 / 3.0
		+ float(upgrades) * 0.7
		+ 3.0 * 0.75
	)
	return {
		"valid": true,
		"completed": completed,
		"failed_at": (
			""
			if completed
			else _failed_node(final_snapshot)
		),
		"total_rounds": total_rounds,
		"pressure_events": pressure_events,
		"boss_phase_events": boss_phase_events,
		"gacha_pulls": gacha_pulls,
		"upgrades": upgrades,
		"rest_id": rest_id,
		"final_health": int(run_state.get("hp", 0)),
		"final_corruption": int(run_state.get("corruption", 0)),
		"final_attention": int(run_state.get("attention", 0)),
		"collection_preserved": (
			not completed
			and _collection_not_reduced(collection_before, collection_after)
		),
		"card_usage": card_usage,
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
	selected_deck: Array[String],
	challenge,
	modifier_id: String,
	node_id: String
) -> Dictionary:
	var content = progression.create_upgraded_content(base_content)
	var deck: Array = progression.build_owned_battle_deck(selected_deck)
	if challenge != null:
		deck = challenge.build_battle_deck(deck)
	if deck.is_empty():
		return _invalid("battle_deck_empty")
	var enemies: Array = _enemy_configs(encounter)
	if challenge != null:
		enemies = challenge.prepare_enemy_configs(enemies)
	var random = BattleRandomAdapterScript.new(
		random_service.get_stream(
			StringName("v07.%s.%s" % [modifier_id, node_id])
		)
	)
	var engine = BattleEngineScript.new()
	var battle_id := StringName(
		"v07.sim.%s.%s.%d" % [
			modifier_id if not modifier_id.is_empty() else "first_route",
			node_id,
			random_service.root_seed,
		]
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

	var pressure_events := 0
	var boss_phase_events := 0
	var card_usage := {}
	var turn_state := {
		"round": -1,
		"utility_plays": 0,
		"defense_plays": 0,
	}
	for event in result.events:
		if event.type == &"EnemyPressureChanged":
			pressure_events += 1
		elif event.type == &"EnemyPhaseTriggered":
			boss_phase_events += 1
	var guard := 0
	while result.accepted and String(result.snapshot.data["outcome"]).is_empty():
		guard += 1
		if guard > 150:
			return _invalid("battle_guard")
		var command = _choose_command(
			engine,
			result.snapshot,
			strategy,
			turn_state
		)
		if command.type == BattleCommand.PLAY_CARD:
			var played_id := _played_definition_id(
				result.snapshot.data,
				command.card_instance_id
			)
			if not played_id.is_empty():
				card_usage[played_id] = int(card_usage.get(played_id, 0)) + 1
		result = engine.submit(command)
		if not result.accepted:
			return _invalid("battle_command:" + String(result.reason_code))
		for event in result.events:
			if event.type == &"EnemyPressureChanged":
				pressure_events += 1
			elif event.type == &"EnemyPhaseTriggered":
				boss_phase_events += 1
	var snapshot: Dictionary = result.snapshot.data
	return {
		"valid": true,
		"won": String(snapshot["outcome"]) == "victory",
		"rounds": int(snapshot["round_number"]),
		"player": snapshot["player"].duplicate(true),
		"pressure_events": pressure_events,
		"boss_phase_events": boss_phase_events,
		"card_usage": card_usage,
	}


func _choose_command(
	engine,
	snapshot,
	strategy: Dictionary,
	turn_state: Dictionary
) -> BattleCommand:
	var round_number := int(snapshot.data.get("round_number", 0))
	if int(turn_state.get("round", -1)) != round_number:
		turn_state["round"] = round_number
		turn_state["utility_plays"] = 0
		turn_state["defense_plays"] = 0

	var command: BattleCommand = null
	var strategy_id := String(strategy.get("id", ""))
	if strategy_id == "oracle":
		if int(turn_state["utility_plays"]) < 2:
			command = _find_playable(
				engine,
				snapshot.data,
				[
					&"card.skill.focus",
					&"card.skill.whispered_hunch",
					&"card.skill.mirrored_memory",
					&"card.skill.insight",
				]
			)
		if command == null:
			command = _find_playable(
				engine,
				snapshot.data,
				[
					&"card.skill.coffin_nail",
					&"card.skill.ink_dart",
					&"card.skill.omen",
					&"card.skill.paper_guard",
					&"card.skill.calm_breath",
				]
			)
		if command == null:
			return BattleCommandScript.end_turn()
	elif strategy_id == "ward":
		if int(turn_state["defense_plays"]) < 1:
			command = _find_playable(
				engine,
				snapshot.data,
				[
					&"card.skill.paper_guard",
					&"card.skill.warding_circle",
					&"card.skill.lantern_step",
				]
			)
		if command == null:
			command = _find_playable(
				engine,
				snapshot.data,
				[
					&"card.skill.coffin_nail",
					&"card.skill.omen",
					&"card.skill.ink_dart",
					&"card.skill.focus",
					&"card.skill.calm_breath",
				]
			)
		if command == null:
			return BattleCommandScript.end_turn()
	else:
		command = _find_playable(
			engine,
			snapshot.data,
			strategy["card_priority"]
		)

	if command == null:
		return BattleCommandScript.end_turn()
	var definition_id := _played_definition_id(
		snapshot.data,
		command.card_instance_id
	)
	if _is_utility_card(definition_id):
		turn_state["utility_plays"] = int(turn_state["utility_plays"]) + 1
	if _is_defense_card(definition_id):
		turn_state["defense_plays"] = int(turn_state["defense_plays"]) + 1
	return command


func _find_playable(
	engine,
	snapshot_data: Dictionary,
	definition_ids: Array
) -> BattleCommand:
	for definition_id in definition_ids:
		for card in snapshot_data.get("hand", []):
			if StringName(card["definition_id"]) != definition_id:
				continue
			var target_id := _target_for_card(snapshot_data, card)
			var playability = engine.query_card_play(
				StringName(card["instance_id"]),
				target_id
			)
			if playability.playable:
				return BattleCommandScript.play_card(
					StringName(card["instance_id"]),
					target_id
				)
	return null


func _first_playable_card(engine, snapshot_data: Dictionary) -> BattleCommand:
	for card in snapshot_data.get("hand", []):
		var target_id := _target_for_card(snapshot_data, card)
		var playability = engine.query_card_play(
			StringName(card["instance_id"]),
			target_id
		)
		if playability.playable:
			return BattleCommandScript.play_card(
				StringName(card["instance_id"]),
				target_id
			)
	return null


func _is_utility_card(definition_id: String) -> bool:
	return definition_id in [
		"card.skill.focus",
		"card.skill.whispered_hunch",
		"card.skill.mirrored_memory",
		"card.skill.insight",
		"card.skill.second_sight",
	]


func _is_defense_card(definition_id: String) -> bool:
	return definition_id in [
		"card.skill.paper_guard",
		"card.skill.warding_circle",
		"card.skill.lantern_step",
	]


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


func _played_definition_id(snapshot: Dictionary, instance_id: StringName) -> String:
	for card in snapshot.get("hand", []):
		if StringName(card.get("instance_id", "")) == instance_id:
			return String(card.get("definition_id", ""))
	return ""


func _apply_reward_and_growth(
	progression,
	strategy: Dictionary,
	preset_id: String
) -> Dictionary:
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

	var gacha_pulls := 0
	snapshot = progression.get_snapshot().data
	var costs: Dictionary = snapshot.get("gacha_costs", {})
	var tickets := int(snapshot.get("divination_tickets", 0))
	var pull_count := 0
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

	var upgrades := 0
	snapshot = progression.get_snapshot().data
	for definition_id in strategy["upgrade_priority"]:
		var card_view := _find_collection_card(
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


func _complete_ritual(route, challenge, ritual_definition: Dictionary) -> Dictionary:
	var snapshot := _route_snapshot(route, challenge)
	if bool(snapshot.get("can_begin_ascension", false)):
		var begin_command = RouteCommandScript.begin_ascension()
		var begin_result = _submit_route(route, challenge, begin_command)
		if not begin_result.accepted:
			return _invalid("ritual_begin:" + String(begin_result.reason_code))
	var guard := 0
	while guard < 20:
		guard += 1
		var ritual_snapshot = (
			challenge.get_ritual_snapshot()
			if challenge != null
			else route.get_ritual_snapshot()
		).data
		var status := String(ritual_snapshot.get("status", ""))
		if status == "completed" or status == "failed":
			return {"valid": true}
		if String(_route_snapshot(route, challenge).get("phase", "")) != "ritual":
			return _invalid("ritual_phase")
		var step_index := int(ritual_snapshot.get("step_index", 0))
		var steps: Array = ritual_definition.get("steps", [])
		if step_index < 0 or step_index >= steps.size():
			return _invalid("ritual_step")
		var selections := _correct_selections(steps[step_index])
		var result = _submit_route(
			route,
			challenge,
			RouteCommandScript.submit_ritual_step(selections)
		)
		if not result.accepted:
			return _invalid("ritual_submit:" + String(result.reason_code))
	return _invalid("ritual_guard")


func _correct_selections(step: Dictionary) -> Array[String]:
	var result: Array[String] = []
	match String(step.get("type", "")):
		"select_ids":
			for value in step.get("correct_ids", []):
				result.append(String(value))
		"ordered_ids":
			for value in step.get("correct_order", []):
				result.append(String(value))
		"select_id":
			result.append(String(step.get("correct_id", "")))
	return result


func _choose_rest(snapshot: Dictionary, strategy: Dictionary) -> String:
	var rest_options: Array = snapshot.get("rest_options", [])
	if rest_options.is_empty():
		return ""
	var run_state: Dictionary = snapshot.get("run_state", {})
	var weights: Dictionary = strategy.get("rest_weights", {})
	var selected_id := ""
	var selected_score := -INF
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


func _route_snapshot(route, challenge) -> Dictionary:
	if challenge != null:
		return challenge.get_route_snapshot().data
	return route.get_snapshot().data


func _submit_route(route, challenge, command):
	if challenge != null:
		return challenge.submit(
			ChallengeCommandScript.forward_route(command)
		)
	return route.submit(command)


func _enemy_configs(encounter: Dictionary) -> Array:
	var enemies_by_id := {}
	for value in _enemies_document.get("enemies", []):
		if value is Dictionary:
			enemies_by_id[String(value.get("id", ""))] = value
	var configs: Array = []
	for slot_value in encounter.get("enemy_slots", []):
		if not slot_value is Dictionary:
			continue
		var slot: Dictionary = slot_value
		var source: Dictionary = enemies_by_id.get(
			String(slot.get("enemy_id", "")),
			{}
		)
		if source.is_empty():
			continue
		var lane := int(slot.get("lane_index", 0))
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
		if value is Dictionary and String(value.get("definition_id", "")) == definition_id:
			return value
	return {}


func _collection_not_reduced(before: Array, after: Array) -> bool:
	var after_by_id := {}
	for value in after:
		if value is Dictionary:
			after_by_id[String(value.get("definition_id", ""))] = value
	for value in before:
		if not value is Dictionary:
			continue
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
	if not selected.is_empty():
		return selected
	var available := String(snapshot.get("available_node_id", ""))
	return available if not available.is_empty() else "route_failed"


func _merge_usage(target: Dictionary, source: Dictionary) -> void:
	for definition_id in source:
		target[definition_id] = (
			int(target.get(definition_id, 0)) + int(source[definition_id])
		)


func _summarize_decks(cases: Array[Dictionary]) -> Dictionary:
	var summary := {}
	for value in cases:
		var item: Dictionary = value
		var preset_id := String(item.get("preset_id", ""))
		if summary.has(preset_id):
			continue
		var row := _aggregate_summary(cases, "preset_id", preset_id)
		summary[preset_id] = row
	return summary


func _summarize_scenarios(cases: Array[Dictionary]) -> Dictionary:
	var summary := {}
	var seen := {}
	for value in cases:
		var item: Dictionary = value
		var scenario_id := String(item.get("scenario_id", ""))
		if seen.has(scenario_id):
			continue
		seen[scenario_id] = true
		summary[scenario_id] = _aggregate_summary(
			cases,
			"scenario_id",
			scenario_id
		)
	return summary


func _aggregate_summary(cases: Array[Dictionary], field: String, value: String) -> Dictionary:
	var valid := 0
	var completed := 0
	var failed := 0
	var rounds := 0.0
	var minutes := 0.0
	var upgrades := 0.0
	var gacha := 0.0
	var rest_choices := {}
	for case_value in cases:
		var item: Dictionary = case_value
		if String(item.get(field, "")) != value:
			continue
		var count := int(item.get("valid_runs", 0))
		valid += count
		completed += int(round(
			float(item.get("completion_rate", 0.0)) * float(count)
		))
		failed += int(item.get("failed_runs", 0))
		rounds += float(item.get("average_total_rounds", 0.0)) * count
		minutes += float(item.get("average_estimated_minutes", 0.0)) * count
		upgrades += float(item.get("average_upgrades", 0.0)) * count
		gacha += float(item.get("average_gacha_pulls", 0.0)) * count
		var rests: Dictionary = item.get("rest_choices", {})
		for rest_id in rests:
			rest_choices[rest_id] = (
				int(rest_choices.get(rest_id, 0)) + int(rests[rest_id])
			)
	var divisor := float(valid) if valid > 0 else 1.0
	return {
		"valid_runs": valid,
		"completed_runs": completed,
		"failed_runs": failed,
		"completion_rate": (
			0.0 if valid == 0 else float(completed) / divisor
		),
		"average_total_rounds": rounds / divisor,
		"average_estimated_minutes": minutes / divisor,
		"average_upgrades": upgrades / divisor,
		"average_gacha_pulls": gacha / divisor,
		"rest_choices": rest_choices,
	}


func _initialize_deck(
	preset_id: String,
	identity_id: String,
	seed_value: int
) -> Dictionary:
	var base_content = BattleContentAdapterScript.new(
		_cards_document.get("cards", [])
	)
	var deck_engine = DeckEngineScript.new(
		DeckContentAdapterScript.new(_decks_document),
		base_content
	)
	var result = deck_engine.initialize(_catalog_ids)
	if not result.accepted:
		return _invalid("deck_init:" + String(result.reason_code))
	result = deck_engine.submit(
		DeckCommandScript.select_preset(StringName(preset_id))
	)
	if not result.accepted:
		return _invalid("deck_preset:" + String(result.reason_code))
	result = deck_engine.submit(DeckCommandScript.confirm_deck())
	if not result.accepted:
		return _invalid("deck_confirm:" + String(result.reason_code))
	return {
		"valid": true,
		"deck": deck_engine.get_confirmed_deck_ids(),
	}


func _make_full_collection_state(identity_id: String) -> Dictionary:
	var collection := {}
	for definition_id in _catalog_ids:
		collection[definition_id] = {
			"copies": 1,
			"level": 0,
			"fragments": 0,
		}
	return {
		"phase": "hub",
		"identity_id": identity_id,
		"divination_tickets": int(
			_balance_document.get("progression", {}).get(
				"starting_divination_tickets",
				3
			)
		),
		"collection": collection,
		"pity_counter": 0,
		"reward_option_ids": [],
		"last_battle_outcome": "",
		"last_gacha_results": [],
		"revision": 1,
	}


func _sequence_state_for_scenario(scenario: Dictionary) -> Dictionary:
	var completed_ids: Array[String] = []
	if String(scenario["challenge_id"]) == String(SECOND_CHALLENGE_ID):
		completed_ids.append(FIRST_CHALLENGE_COMPLETED)
	return {
		"pathway": "seer",
		"current_sequence": 8,
		"advancement_state": "completed",
		"completed_challenge_ids": completed_ids,
	}


func _challenge_by_id(challenge_id: String) -> Dictionary:
	for value in _challenges_document.get("challenges", []):
		if value is Dictionary and String(value.get("id", "")) == challenge_id:
			return value
	return {}


func _preset_ids() -> Array[String]:
	var result: Array[String] = []
	for value in _decks_document.get("presets", []):
		if value is Dictionary:
			result.append(String(value.get("id", "")))
	return result


func _invalid(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open v0.7 simulation input: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("v0.7 simulation input is not a JSON object: %s" % path)
		return {}
	return parsed
