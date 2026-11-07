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
const BALANCE_PATH := "res://data/balance/v0.4.0/balance.json"
const PROGRESSION_PATH := "res://data/cards/v0.4.0/progression.json"
const OUTPUT_PATH := "res://tools/simulation/out/v0.4.0_upgrade_battle_sampling.json"

const ROOT_SEED: int = 20261108
const SAMPLE_PAIRS: int = 500
const INK_DART_ID: StringName = &"card.skill.ink_dart"
const DOCTOR_ID: StringName = &"identity.doctor"

const STARTER_DECK: Array[StringName] = [
	&"card.skill.ink_dart",
	&"card.skill.ink_dart",
	&"card.skill.ink_dart",
	&"card.skill.ink_dart",
	&"card.skill.paper_guard",
	&"card.skill.paper_guard",
	&"card.skill.paper_guard",
	&"card.skill.calm_breath",
	&"card.skill.focus",
	&"card.skill.insight",
	&"card.skill.second_look",
	&"card.skill.second_look",
]

const POLICY_PRIORITY: Array[StringName] = [
	&"card.skill.focus",
	&"card.skill.omen",
	&"card.skill.ink_dart",
	&"card.skill.whisper",
	&"card.skill.insight",
	&"card.skill.second_look",
	&"card.skill.paper_guard",
	&"card.skill.calm_breath",
]

var _cards_document: Dictionary
var _enemies_document: Dictionary
var _encounters_document: Dictionary
var _balance_document: Dictionary
var _progression_document: Dictionary


func _ready() -> void:
	_cards_document = _load_json(CARDS_PATH)
	_enemies_document = _load_json(ENEMIES_PATH)
	_encounters_document = _load_json(ENCOUNTERS_PATH)
	_balance_document = _load_json(BALANCE_PATH)
	_progression_document = _load_json(PROGRESSION_PATH)
	if (
		_cards_document.is_empty()
		or _enemies_document.is_empty()
		or _encounters_document.is_empty()
		or _balance_document.is_empty()
		or _progression_document.is_empty()
	):
		get_tree().quit(1)
		return

	var baseline_content: Array = _cards_document["cards"].duplicate(true)
	var upgraded_content: Array = _cards_document["cards"].duplicate(true)
	var upgrade_bonus: int = _ink_dart_upgrade_bonus()
	if not _apply_ink_dart_upgrade(upgraded_content, upgrade_bonus):
		push_error("Cannot build upgraded ink dart simulation content")
		get_tree().quit(1)
		return

	var baseline_samples: Array[Dictionary] = []
	var upgraded_samples: Array[Dictionary] = []
	for sample_index in range(SAMPLE_PAIRS):
		var seed_value: int = ROOT_SEED + sample_index * 104729
		baseline_samples.append(_run_battle(baseline_content, seed_value))
		upgraded_samples.append(_run_battle(upgraded_content, seed_value))

	var baseline_summary: Dictionary = _summarize(baseline_samples)
	var upgraded_summary: Dictionary = _summarize(upgraded_samples)
	var output: Dictionary = {
		"version": "v0.4.0",
		"engine": "BattleEngine",
		"root_seed": ROOT_SEED,
		"sample_pairs": SAMPLE_PAIRS,
		"identity_id": String(DOCTOR_ID),
		"identity_health_bonus": _doctor_health_bonus(),
		"upgrade_model": {
			"card_id": String(INK_DART_ID),
			"target_level": 2,
			"numeric_effect_bonus_per_level": upgrade_bonus,
			"note": "Simulation-only projected card copy; production upgrade rules must apply the same data rule.",
		},
		"baseline": baseline_summary,
		"upgraded": upgraded_summary,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write upgrade battle sampling output: %s" % OUTPUT_PATH)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()

	print(JSON.stringify({
		"version": output["version"],
		"root_seed": ROOT_SEED,
		"sample_pairs": SAMPLE_PAIRS,
		"baseline": baseline_summary,
		"upgraded": upgraded_summary,
	}, "\t"))
	get_tree().quit(0)


func _apply_ink_dart_upgrade(cards: Array, bonus: int) -> bool:
	for card_source in cards:
		var card: Dictionary = card_source
		if StringName(card.get("id", "")) != INK_DART_ID:
			continue
		for effect_source in card.get("effects", []):
			var effect: Dictionary = effect_source
			if StringName(effect.get("effect_id", "")) == &"damage":
				effect["amount"] = int(effect.get("amount", 0)) + bonus
				return true
	return false


func _ink_dart_upgrade_bonus() -> int:
	var upgrade: Dictionary = _progression_document.get(
		"upgrade_definitions",
		{}
	).get(String(INK_DART_ID), {})
	for bonus_value in upgrade.get("bonuses", []):
		var bonus: Dictionary = bonus_value
		if int(bonus.get("effect_index", -1)) == 0 and String(bonus.get("field", "")) == "amount":
			return int(bonus.get("amount_per_level", 0))
	return 0


func _doctor_health_bonus() -> int:
	for identity_value in _progression_document.get("identities", []):
		var identity: Dictionary = identity_value
		if StringName(identity.get("id", "")) != DOCTOR_ID:
			continue
		return int(identity.get("battle_modifiers", {}).get("max_hp_bonus", 0))
	return 0


func _run_battle(cards: Array, seed_value: int) -> Dictionary:
	var content := BattleContentAdapterScript.new(cards)
	var balance = BattleBalanceAdapterScript.new(_balance_document)
	var random_service = SeededRandomServiceScript.new(seed_value)
	var random = BattleRandomAdapterScript.new(random_service.get_stream(&"battle.shuffle"))
	var encounter: Dictionary = _encounters_document["encounters"][0]
	var engine = BattleEngineScript.new()
	var initialize_result = engine.initialize(
		content,
		balance,
		random,
		StringName("upgrade.sim.%d" % seed_value),
		_player_state(),
		STARTER_DECK,
		_enemy_configs(encounter)
	)
	if not initialize_result.accepted:
		return {
			"valid": false,
			"reason": String(initialize_result.reason_code),
		}

	var result = initialize_result
	var ink_dart_hits: int = 0
	var ink_dart_damage: int = 0
	var command_guard: int = 0
	while result.accepted and String(result.snapshot.data["outcome"]).is_empty():
		command_guard += 1
		if command_guard > 100:
			return {"valid": false, "reason": "command_guard"}
		var command = _choose_command(engine, result.snapshot)
		result = engine.submit(command)
		if not result.accepted:
			return {"valid": false, "reason": String(result.reason_code)}
		for event in result.events:
			if (
				event.type == &"DamageApplied"
				and StringName(event.data.get("source_id", "")) == INK_DART_ID
			):
				ink_dart_hits += 1
				ink_dart_damage += int(event.data.get("amount", 0))

	var snapshot: Dictionary = result.snapshot.data
	return {
		"valid": true,
		"won": String(snapshot["outcome"]) == "victory",
		"rounds": int(snapshot["round_number"]),
		"remaining_health": int(snapshot["player"]["hp"]),
		"ink_dart_hits": ink_dart_hits,
		"ink_dart_damage": ink_dart_damage,
	}


func _choose_command(engine, snapshot):
	for definition_id in POLICY_PRIORITY:
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
	var health_bonus: int = _doctor_health_bonus()
	var max_health: int = int(player["max_health"]) + health_bonus
	return {
		"actor_id": &"player",
		"hp": max_health,
		"max_hp": max_health,
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


func _summarize(samples: Array[Dictionary]) -> Dictionary:
	var valid: int = 0
	var wins: int = 0
	var rounds_total: int = 0
	var health_total: int = 0
	var ink_hits_total: int = 0
	var ink_damage_total: int = 0
	for sample in samples:
		if not bool(sample.get("valid", false)):
			continue
		valid += 1
		if bool(sample["won"]):
			wins += 1
		rounds_total += int(sample["rounds"])
		health_total += int(sample["remaining_health"])
		ink_hits_total += int(sample["ink_dart_hits"])
		ink_damage_total += int(sample["ink_dart_damage"])
	return {
		"valid_samples": valid,
		"win_rate": 0.0 if valid == 0 else float(wins) / float(valid),
		"average_rounds": 0.0 if valid == 0 else float(rounds_total) / float(valid),
		"average_remaining_health": 0.0 if valid == 0 else float(health_total) / float(valid),
		"ink_dart_hits": ink_hits_total,
		"ink_dart_damage": ink_damage_total,
		"average_damage_per_ink_dart_hit": (
			0.0 if ink_hits_total == 0 else float(ink_damage_total) / float(ink_hits_total)
		),
	}


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
