extends Node

const BALANCE_PATH := "res://data/balance/v0.4.0/balance.json"
const BASE_CARDS_PATH := "res://data/cards/v0.3.0/cards.json"
const PROGRESSION_PATH := "res://data/cards/v0.4.0/progression.json"
const OUTPUT_PATH := "res://tools/simulation/out/v0.4.0_economy_sampling.json"

const ROOT_SEED: int = 20261108
const SAMPLES_PER_STRATEGY: int = 1000

const STRATEGIES: Array[Dictionary] = [
	{
		"id": "ticket_route_reporter",
		"identity_id": &"identity.reporter",
		"reward_id": &"reward.divination_tickets",
		"use_tickets_for_gacha": true,
	},
	{
		"id": "upgrade_route_doctor",
		"identity_id": &"identity.doctor",
		"reward_id": &"reward.ink_dart_fragments",
		"use_tickets_for_gacha": false,
	},
	{
		"id": "fragment_route_gravedigger",
		"identity_id": &"identity.gravedigger",
		"reward_id": &"reward.divination_tickets",
		"use_tickets_for_gacha": true,
	},
]


func _ready() -> void:
	var balance: Dictionary = _load_json(BALANCE_PATH)
	var base_cards: Dictionary = _load_json(BASE_CARDS_PATH)
	var progression: Dictionary = _load_json(PROGRESSION_PATH)
	if balance.is_empty() or base_cards.is_empty() or progression.is_empty():
		get_tree().quit(1)
		return
	if not _validate_inputs(balance, base_cards, progression):
		get_tree().quit(1)
		return

	var results: Array[Dictionary] = []
	for strategy in STRATEGIES:
		results.append(_sample_strategy(strategy, balance, base_cards, progression))

	var output: Dictionary = {
		"version": "v0.4.0",
		"model": "deterministic_economy",
		"root_seed": ROOT_SEED,
		"samples_per_strategy": SAMPLES_PER_STRATEGY,
		"assumption": "teaching_battle_victory",
		"balance_source": BALANCE_PATH,
		"base_cards_source": BASE_CARDS_PATH,
		"progression_source": PROGRESSION_PATH,
		"strategies": results,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write economy simulation output: %s" % OUTPUT_PATH)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(output, "\t"))
	file.close()

	print(JSON.stringify({
		"version": output["version"],
		"root_seed": ROOT_SEED,
		"samples_per_strategy": SAMPLES_PER_STRATEGY,
		"strategies": results,
	}, "\t"))
	get_tree().quit(0)


func _validate_inputs(balance: Dictionary, base_cards: Dictionary, progression: Dictionary) -> bool:
	for key in ["progression", "gacha", "upgrade", "reward"]:
		if not balance.get(key) is Dictionary:
			push_error("v0.4 balance is missing block: %s" % key)
			return false
	var known_cards: Dictionary = {}
	for card in base_cards.get("cards", []):
		known_cards[StringName(card["id"])] = true
	for definition_id in progression.get("starter_card_ids", []):
		if not known_cards.has(StringName(definition_id)):
			push_error("Starter card is missing from formal content: %s" % definition_id)
			return false
	for entry in progression.get("gacha_pool", []):
		if not known_cards.has(StringName(entry.get("definition_id", ""))):
			push_error("Gacha card is missing from formal content: %s" % entry.get("definition_id", ""))
			return false
	var identity_ids: Dictionary = {}
	for identity in progression.get("identities", []):
		identity_ids[String(identity.get("id", ""))] = true
	var reward_ids: Dictionary = {}
	for reward in progression.get("reward_options", []):
		reward_ids[String(reward.get("id", ""))] = true
	for strategy in STRATEGIES:
		if not identity_ids.has(String(strategy["identity_id"])):
			push_error("Strategy references missing identity: %s" % strategy["identity_id"])
			return false
		if not reward_ids.has(String(strategy["reward_id"])):
			push_error("Strategy references missing reward: %s" % strategy["reward_id"])
			return false
	return true


func _sample_strategy(
	strategy: Dictionary,
	balance: Dictionary,
	base_cards: Dictionary,
	progression: Dictionary
) -> Dictionary:
	var totals: Dictionary = {
		"pulls": 0,
		"tickets_earned": 0,
		"tickets_spent": 0,
		"tickets_remaining": 0,
		"fragments_earned": 0,
		"fragments_spent": 0,
		"fragments_remaining": 0,
		"new_cards": 0,
		"duplicates": 0,
		"pity_forced": 0,
		"upgrades_completed": 0,
		"loops_with_pulls": 0,
		"loops_with_upgrade": 0,
		"active_loops": 0,
		"valid_loops": 0,
	}
	for sample_index in range(SAMPLES_PER_STRATEGY):
		var seed_value: int = ROOT_SEED + sample_index * 7919
		var result: Dictionary = _simulate_once(
			strategy,
			balance,
			base_cards,
			progression,
			seed_value
		)
		if not bool(result.get("valid", false)):
			continue
		totals["valid_loops"] = int(totals["valid_loops"]) + 1
		for key in [
			"pulls",
			"tickets_earned",
			"tickets_spent",
			"tickets_remaining",
			"fragments_earned",
			"fragments_spent",
			"fragments_remaining",
			"new_cards",
			"duplicates",
			"pity_forced",
			"upgrades_completed",
			"loops_with_pulls",
			"loops_with_upgrade",
			"active_loops",
		]:
			totals[key] = int(totals[key]) + int(result[key])

	var valid: int = int(totals["valid_loops"])
	var averages: Dictionary = {}
	for key in [
		"pulls",
		"tickets_earned",
		"tickets_spent",
		"tickets_remaining",
		"fragments_earned",
		"fragments_spent",
		"fragments_remaining",
		"new_cards",
		"duplicates",
		"pity_forced",
		"upgrades_completed",
		"loops_with_pulls",
		"loops_with_upgrade",
		"active_loops",
	]:
		averages[key] = 0.0 if valid == 0 else float(totals[key]) / float(valid)
	averages["active_loop_rate"] = (
		0.0 if valid == 0 else float(totals["active_loops"]) / float(valid)
	)
	return {
		"id": String(strategy["id"]),
		"identity_id": String(strategy["identity_id"]),
		"reward_id": String(strategy["reward_id"]),
		"valid_loops": valid,
		"averages": averages,
	}


func _simulate_once(
	strategy: Dictionary,
	balance: Dictionary,
	base_cards: Dictionary,
	progression: Dictionary,
	seed_value: int
) -> Dictionary:
	var tickets: int = int(balance["progression"]["starting_divination_tickets"])
	var tickets_earned: int = tickets
	var tickets_spent: int = 0
	var pulls: int = 0
	var new_cards: int = 0
	var duplicates: int = 0
	var pity_forced: int = 0
	var upgrades_completed: int = 0
	var pity: int = 0

	var identity: Dictionary = _find_by_id(
		progression.get("identities", []),
		String(strategy["identity_id"])
	)
	if identity.is_empty():
		return {"valid": false, "reason": "identity_missing"}
	var victory_resources: Dictionary = identity.get("victory_resources", {})
	var identity_tickets: int = int(victory_resources.get("divination_tickets", 0))
	tickets += identity_tickets
	tickets_earned += identity_tickets
	var duplicate_bonus: int = int(identity.get("duplicate_fragment_bonus", 0))

	var reward: Dictionary = _find_by_id(
		progression.get("reward_options", []),
		String(strategy["reward_id"])
	)
	if reward.is_empty():
		return {"valid": false, "reason": "reward_missing"}
	var reward_amount: int = int(
		balance["reward"]["amounts"].get(String(strategy["reward_id"]), 0)
	)
	if reward_amount <= 0:
		return {"valid": false, "reason": "reward_amount_missing"}

	var fragments_by_card: Dictionary = {}
	var known_cards: Dictionary = {}
	for card in base_cards.get("cards", []):
		known_cards[StringName(card["id"])] = true
		fragments_by_card[StringName(card["id"])] = 0
	var fragments_earned: int = 0
	var fragments_spent: int = 0
	var reward_kind: String = String(reward.get("kind", ""))
	if reward_kind == "divination_tickets":
		tickets += reward_amount
		tickets_earned += reward_amount
	elif reward_kind == "card_fragments":
		var target_id := StringName(reward.get("target_definition_id", ""))
		if not known_cards.has(target_id):
			return {"valid": false, "reason": "reward_target_missing"}
		fragments_by_card[target_id] = int(fragments_by_card[target_id]) + reward_amount
		fragments_earned += reward_amount
	else:
		return {"valid": false, "reason": "reward_kind_unsupported"}

	var collection: Dictionary = {}
	for definition_id in progression.get("starter_card_ids", []):
		collection[StringName(definition_id)] = 1
	var pool_by_rarity: Dictionary = {}
	for entry in progression.get("gacha_pool", []):
		var rarity := String(entry.get("rarity", ""))
		var bucket: Array = pool_by_rarity.get(rarity, [])
		bucket.append(entry.duplicate(true))
		pool_by_rarity[rarity] = bucket
	for rarity in pool_by_rarity:
		pool_by_rarity[rarity].sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("definition_id", "")) < String(b.get("definition_id", ""))
		)

	var gacha: Dictionary = balance["gacha"]
	var single_cost: int = int(gacha["single_cost"])
	var triple_cost: int = int(gacha["triple_cost"])
	var triple_pulls: int = int(gacha["pulls_per_triple"])
	var pity_threshold: int = int(gacha["rare_pity"])
	var random := RandomNumberGenerator.new()
	random.seed = seed_value

	if bool(strategy["use_tickets_for_gacha"]) and tickets >= triple_cost:
		tickets -= triple_cost
		tickets_spent += triple_cost
		for _draw_index in range(triple_pulls):
			var draw_result: Dictionary = _draw_card(
				random,
				pool_by_rarity,
				collection,
				fragments_by_card,
				gacha,
				duplicate_bonus,
				pity,
				pity_threshold
			)
			pulls += 1
			pity = int(draw_result["next_pity"])
			pity_forced += int(draw_result["pity_forced"])
			fragments_earned += int(draw_result["fragments"])
			duplicates += int(draw_result["duplicate"])
			new_cards += int(draw_result["new_card"])
	while bool(strategy["use_tickets_for_gacha"]) and tickets >= single_cost:
		tickets -= single_cost
		tickets_spent += single_cost
		var single_result: Dictionary = _draw_card(
			random,
			pool_by_rarity,
			collection,
			fragments_by_card,
			gacha,
			duplicate_bonus,
			pity,
			pity_threshold
		)
		pulls += 1
		pity = int(single_result["next_pity"])
		pity_forced += int(single_result["pity_forced"])
		fragments_earned += int(single_result["fragments"])
		duplicates += int(single_result["duplicate"])
		new_cards += int(single_result["new_card"])

	var upgrade_result: Dictionary = _try_upgrade(
		fragments_by_card,
		collection,
		progression.get("upgrade_definitions", {}),
		balance["upgrade"]["cost_by_next_level"]
	)
	upgrades_completed += int(upgrade_result["upgrades_completed"])
	fragments_spent += int(upgrade_result["fragments_spent"])
	var fragments_remaining: int = 0
	for value in fragments_by_card.values():
		fragments_remaining += int(value)

	return {
		"valid": true,
		"pulls": pulls,
		"tickets_earned": tickets_earned,
		"tickets_spent": tickets_spent,
		"tickets_remaining": tickets,
		"fragments_earned": fragments_earned,
		"fragments_spent": fragments_spent,
		"fragments_remaining": fragments_remaining,
		"new_cards": new_cards,
		"duplicates": duplicates,
		"pity_forced": pity_forced,
		"upgrades_completed": upgrades_completed,
		"loops_with_pulls": 1 if pulls > 0 else 0,
		"loops_with_upgrade": 1 if upgrades_completed > 0 else 0,
		"active_loops": 1 if pulls > 0 or upgrades_completed > 0 else 0,
	}


func _draw_card(
	random: RandomNumberGenerator,
	pool_by_rarity: Dictionary,
	collection: Dictionary,
	fragments_by_card: Dictionary,
	gacha: Dictionary,
	duplicate_bonus: int,
	pity: int,
	pity_threshold: int
) -> Dictionary:
	var forced: bool = pity + 1 >= pity_threshold
	var rarity: String = "rare" if forced else _roll_rarity(random, gacha)
	var candidates: Array = pool_by_rarity.get(rarity, [])
	if candidates.is_empty():
		push_error("No gacha candidates for rarity: %s" % rarity)
		return {
			"next_pity": pity,
			"pity_forced": 0,
			"fragments": 0,
			"duplicate": 0,
			"new_card": 0,
		}
	var entry: Dictionary = candidates[random.randi_range(0, candidates.size() - 1)]
	var selected := StringName(entry["definition_id"])
	var is_new: bool = not collection.has(selected)
	var duplicate_fragments: int = 0
	if is_new:
		collection[selected] = 1
	else:
		duplicate_fragments = int(gacha["duplicate_fragments"]) + duplicate_bonus
		fragments_by_card[selected] = int(fragments_by_card.get(selected, 0)) + duplicate_fragments
	return {
		"next_pity": 0 if rarity == "rare" else pity + 1,
		"pity_forced": 1 if forced else 0,
		"fragments": duplicate_fragments,
		"duplicate": 1 if not is_new else 0,
		"new_card": 1 if is_new else 0,
	}


func _try_upgrade(
	fragments_by_card: Dictionary,
	collection: Dictionary,
	upgrade_definitions: Dictionary,
	cost_by_next_level: Dictionary
) -> Dictionary:
	var best_card: StringName = &""
	var best_fragments: int = -1
	var best_cost: int = 0
	for definition_id in collection:
		var upgrade: Dictionary = upgrade_definitions.get(String(definition_id), {})
		if upgrade.is_empty():
			continue
		var max_level: int = int(upgrade.get("max_level", 0))
		var current_level: int = 0
		if current_level >= max_level:
			continue
		var cost: int = int(cost_by_next_level.get("1", 0))
		var fragments: int = int(fragments_by_card.get(definition_id, 0))
		if cost > 0 and fragments >= cost and fragments > best_fragments:
			best_card = definition_id
			best_fragments = fragments
			best_cost = cost
	if best_card.is_empty():
		return {"upgrades_completed": 0, "fragments_spent": 0}
	fragments_by_card[best_card] = best_fragments - best_cost
	return {"upgrades_completed": 1, "fragments_spent": best_cost}


func _roll_rarity(random: RandomNumberGenerator, gacha: Dictionary) -> String:
	var weights: Dictionary = gacha["rarity_weights"]
	var rarities: Array[String] = []
	var total_weight: int = 0
	for rarity in weights.keys():
		rarities.append(String(rarity))
		total_weight += int(weights[rarity])
	rarities.sort()
	var roll: int = random.randi_range(0, total_weight - 1)
	for rarity in rarities:
		roll -= int(weights[rarity])
		if roll < 0:
			return rarity
	return "common"


func _find_by_id(entries: Array, expected_id: String) -> Dictionary:
	for value in entries:
		var entry: Dictionary = value
		if String(entry.get("id", "")) == expected_id:
			return entry.duplicate(true)
	return {}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open economy input: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Economy input is not a JSON object: %s" % path)
		return {}
	return parsed
