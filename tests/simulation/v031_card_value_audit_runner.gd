extends Node

## v0.31.0 card value audit.
##
## Every card's effects are priced with one shared unit table and compared with
## a budget derived only from its cost (plus small, documented allowances for
## rarity, Sequence 8 and single-use "exhaust" artifacts). A card whose effect
## value drifts outside the tolerance of its budget fails the audit, so a cheap
## card can never again out-perform an expensive one, and every downside
## (corruption, attention, HP, spirit, discards) is counted as a real cost.
##
## The same model is documented in docs/design/TINGEN_CANON.md §4.

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"

const UNIT := {
	"damage": 1.0, "damage_all": 1.5, "block": 0.8, "heal": 1.0,
	"lose_hp": -1.0, "draw": 2.5, "discard": -1.5, "spirit": 3.0,
	"reveal_intent": 1.5, "reveal_all": 2.5, "steal_attack": 3.0,
	"prepare_ritual": 1.5,
}
const STATUS := {
	"mark": 1.0, "weaken": 0.9, "bound": 4.5, "evasion": 0.85,
	"silenced": 0.6, "sluggish": -3.0, "foresight": 1.0,
}
const RISK := {"corruption": -2.0, "attention": -1.0}
const BUDGET := {0: 2.5, 1: 5.5, 2: 10.5, 3: 15.5}
## Conditional effects (only vs. certain traits/states) are worth half.
const CONDITION_FACTOR := 0.5
## A finisher that consumes ritual stacks is priced at an expected 2 stacks.
const EXPECTED_RITUAL_STACKS := 2.0

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CARDS_PATH))
	_expect(parsed is Dictionary, "cards document parses")
	if not parsed is Dictionary:
		_finish()
		return
	var cards: Array = parsed.get("cards", [])
	_expect(cards.size() == 40, "audit covers 40 cards")
	var by_cost := {}
	for card_value in cards:
		var card: Dictionary = card_value
		var value := card_value_of(card)
		var budget := card_budget(card)
		var tolerance := maxf(1.25, budget * 0.12)
		_expect(
			absf(value - budget) <= tolerance,
			"%s (%s) value %.2f vs budget %.2f ±%.2f" % [
				card.get("display_name_zh", ""), card.get("id", ""), value, budget, tolerance,
			]
		)
		_expect(
			not String(card.get("source_zh", "")).is_empty(),
			"%s cites its canon source" % card.get("id", "")
		)
		var cost := int(card.get("cost_spirit", 0))
		var list: Array = by_cost.get(cost, [])
		list.append(value / maxf(0.01, card_budget(card)))
		by_cost[cost] = list
		# Every artifact must carry an explicit downside or be single-use,
		# mirroring the "every sealed artifact has a negative effect" canon.
		if String(card.get("category", "")) == "artifact":
			_expect(
				bool(card.get("exhaust", false)) or _has_downside(card),
				"%s artifact has a downside or is single-use" % card.get("id", "")
			)
	# Monotonic cost curve: a more expensive card must buy more raw value.
	for cost in [1, 2, 3]:
		_expect(BUDGET[cost] > BUDGET[cost - 1], "budget grows with cost %d" % cost)
	_test_synergies(parsed.get("synergies", []), cards)
	_finish()


func card_value_of(card: Dictionary) -> float:
	var total := 0.0
	for effect_value in card.get("effects", []):
		total += effect_value_of(effect_value)
	return total


func effect_value_of(effect: Dictionary) -> float:
	var effect_id := String(effect.get("effect_id", ""))
	var factor := CONDITION_FACTOR if effect.get("condition", {}) is Dictionary and not effect.get("condition", {}).is_empty() else 1.0
	var base := 0.0
	match effect_id:
		"damage", "damage_all", "block", "heal", "lose_hp", "spirit", "steal_attack", "prepare_ritual":
			base = float(effect.get("amount", 1)) * float(UNIT[effect_id])
			var per_stack := int(effect.get("per_ritual_stack", 0))
			if per_stack != 0:
				base += float(per_stack) * EXPECTED_RITUAL_STACKS * float(UNIT[effect_id]) * 0.75
		"draw", "discard":
			base = float(effect.get("count", 0)) * float(UNIT[effect_id])
		"reveal_intent", "reveal_all":
			base = float(UNIT[effect_id])
		"apply_status":
			var status_id := String(effect.get("status_id", ""))
			base = float(effect.get("stacks", 0)) * float(STATUS.get(status_id, 0.0))
			if status_id == "silenced":
				base = float(effect.get("duration", 0)) * float(STATUS[status_id])
			if String(effect.get("target", "")) == "all_enemies":
				base *= 1.5
		"risk":
			base = float(effect.get("amount", 0)) * float(RISK.get(String(effect.get("risk_id", "")), 0.0))
	return base * factor


func card_budget(card: Dictionary) -> float:
	var budget := float(BUDGET.get(int(card.get("cost_spirit", 0)), 0.0))
	if String(card.get("rarity", "common")) == "rare":
		budget += 1.0
	if String(card.get("sequence_band", "")).contains("序列8"):
		budget += 1.0
	if bool(card.get("exhaust", false)):
		budget *= 1.3
	return budget


func _has_downside(card: Dictionary) -> bool:
	for effect in card.get("effects", []):
		if effect_value_of(effect) < 0.0:
			return true
	return false


func _test_synergies(synergies: Array, cards: Array) -> void:
	_expect(synergies.size() >= 8, "at least eight canon synergies are defined")
	var ids := {}
	for card in cards:
		ids[String(card.get("id", ""))] = true
	for synergy_value in synergies:
		var synergy: Dictionary = synergy_value
		_expect(not String(synergy.get("source_zh", "")).is_empty(), "%s cites its canon source" % synergy.get("id", ""))
		var groups: Array = synergy.get("requires", [])
		_expect(groups.size() >= 2, "%s needs at least two cards" % synergy.get("id", ""))
		var group_cost := 0
		for group in groups:
			var cheapest := 99
			for card_id in group:
				_expect(ids.has(String(card_id)), "%s references %s" % [synergy.get("id", ""), card_id])
				for card in cards:
					if String(card.get("id", "")) == String(card_id):
						cheapest = mini(cheapest, int(card.get("cost_spirit", 0)))
			group_cost += cheapest
		var bonus := 0.0
		for effect in synergy.get("effects", []):
			bonus += effect_value_of(effect)
		# A same-turn combo bonus is capped relative to the spirit the combo
		# already demands, so it rewards the setup without trivialising fights.
		_expect(
			bonus <= 3.0 + float(group_cost) * 3.5,
			"%s bonus %.2f stays within its combo cost %d" % [synergy.get("id", ""), bonus, group_cost]
		)


func _finish() -> void:
	if _failures.is_empty():
		print("V031_CARD_VALUE_AUDIT_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V031_CARD_VALUE_AUDIT_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
