extends Node

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const DECKS_PATH := "res://data/decks/v0.7.0/decks.json"

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
	var cards_doc := _load_json(CARDS_PATH)
	var decks_doc := _load_json(DECKS_PATH)
	var catalog := {}
	for card_value in cards_doc.get("cards", []):
		if card_value is Dictionary:
			catalog[String(card_value.get("id", ""))] = card_value
	_expect(catalog.size() == 40, "40-card catalog")
	for preset_value in decks_doc.get("presets", []):
		_audit_preset(preset_value, catalog)
	if _failures.is_empty():
		print("V018_DECK_BALANCE_AUDIT_OK checks=%d presets=%d" % [
			_checks,
		decks_doc.get("presets", []).size(),
		])
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("FAIL %s" % failure)
	print("V018_DECK_BALANCE_AUDIT_FAILED checks=%d failures=%d" % [
		_checks,
		_failures.size(),
	])
	get_tree().quit(1)

func _audit_preset(value: Variant, catalog: Dictionary) -> void:
	if not value is Dictionary:
		_expect(false, "preset is an object")
		return
	var preset: Dictionary = value
	var preset_id := String(preset.get("id", ""))
	var ids: Array = preset.get("card_definition_ids", [])
	_expect(ids.size() == 8, "%s has 8 cards" % preset_id)
	var seen := {}
	var categories := {}
	var total_cost := 0
	for raw_id in ids:
		var card_id := String(raw_id)
		_expect(catalog.has(card_id), "%s references %s" % [preset_id, card_id])
		_expect(not seen.has(card_id), "%s has unique cards" % preset_id)
		seen[card_id] = true
		if not catalog.has(card_id):
			continue
		var card: Dictionary = catalog[card_id]
		total_cost += int(card.get("cost_spirit", 0))
		for effect_value in card.get("effects", []):
			if effect_value is Dictionary:
				var effect_id := String(effect_value.get("effect_id", ""))
				categories[_effect_category(effect_id)] = true
	_expect(total_cost >= 4 and total_cost <= 16, "%s cost band=%d" % [preset_id, total_cost])
	_expect(categories.has("pressure") or categories.has("defense"), "%s has pressure or defense" % preset_id)
	_expect(categories.size() >= 2, "%s covers two effect directions" % preset_id)

func _effect_category(effect_id: String) -> String:
	if effect_id in ["damage", "apply_status"]:
		return "pressure"
	if effect_id in ["block", "heal", "risk"]:
		return "defense"
	if effect_id in ["draw", "spirit", "reveal_intent"]:
		return "utility"
	return "other"

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
