extends Node

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const DECKS_PATH := "res://data/decks/v0.7.0/decks.json"
var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	var cards := _index(_load_json(CARDS_PATH).get("cards", []))
	var decks := _load_json(DECKS_PATH)
	for preset_value in decks.get("presets", []):
		_measure(preset_value, cards)
	if _failures.is_empty():
		print("V020_PRESET_METRICS_OK checks=%d presets=%d" % [_checks, decks.get("presets", []).size()])
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("FAIL %s" % failure)
	get_tree().quit(1)

func _measure(value: Variant, cards: Dictionary) -> void:
	if not value is Dictionary:
		_expect(false, "preset object")
		return
	var preset: Dictionary = value
	var preset_id := String(preset.get("id", ""))
	var total_cost := 0
	var max_cost := 0
	var categories := {}
	var risk_effects := 0
	for raw_id in preset.get("card_definition_ids", []):
		var id := String(raw_id)
		_expect(cards.has(id), "%s card exists" % preset_id)
		if not cards.has(id):
			continue
		var card: Dictionary = cards[id]
		var cost := int(card.get("cost_spirit", 0))
		total_cost += cost
		max_cost = maxi(max_cost, cost)
		for effect_value in card.get("effects", []):
			if not effect_value is Dictionary:
				continue
			var effect_id := String(effect_value.get("effect_id", ""))
			categories[_category(effect_id)] = true
			if effect_id == "risk":
				risk_effects += 1
		var average_cost := float(total_cost) / 8.0
		_expect(average_cost >= 0.0 and average_cost <= 2.0, "%s average cost" % preset_id)
	_expect(max_cost <= 3, "%s max cost" % preset_id)
	_expect(categories.size() >= 2, "%s category coverage" % preset_id)
	print("V020_METRIC %s average_cost=%.2f max_cost=%d categories=%d risk_effects=%d" % [
		preset_id, float(total_cost) / 8.0, max_cost, categories.size(), risk_effects,
	])

func _category(effect_id: String) -> String:
	if effect_id in ["damage", "apply_status"]:
		return "pressure"
	if effect_id in ["block", "heal"]:
		return "defense"
	if effect_id in ["draw", "spirit", "reveal_intent"]:
		return "utility"
	if effect_id == "risk":
		return "risk"
	return "other"

func _index(values: Array) -> Dictionary:
	var result := {}
	for value in values:
		if value is Dictionary:
			result[String(value.get("id", ""))] = value
	return result

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
