extends Node

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const REQUIRED_FIELDS := [
	"damage_types",
	"attack_form",
	"pathway",
	"sequence_band",
	"target_layer",
	"mechanic_tags",
	"rules_text_zh",
	"flavor_text_zh",
	"art_status",
]

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var file := FileAccess.open(CARDS_PATH, FileAccess.READ)
	_expect(file != null, "attack catalog should be readable")
	if file == null:
		_finish()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	_expect(parsed is Dictionary, "attack catalog should be valid JSON object")
	if not parsed is Dictionary:
		_finish()
		return
	var cards: Variant = parsed.get("cards", [])
	_expect(cards is Array and cards.size() == 40, "attack catalog should contain 40 cards")
	if cards is Array:
		for card_value in cards:
			_expect(card_value is Dictionary, "each catalog entry should be an object")
			if not card_value is Dictionary:
				continue
			var card: Dictionary = card_value
			for field in REQUIRED_FIELDS:
				_expect(card.has(field), "%s should define %s" % [card.get("id", ""), field])
			_expect(
				String(card.get("art_status", "")) == "card_back_fallback",
				"%s should use the v0.27 fallback art status" % card.get("id", "")
			)
			for effect_value in card.get("effects", []):
				if effect_value is Dictionary:
					_expect(
						String(effect_value.get("effect_id", "")) in [
							"damage", "block", "heal", "draw", "spirit", "apply_status",
							"remove_status", "discard", "reveal_intent", "risk",
							"prepare_ritual",
						],
						"%s should keep a registered runtime effect" % card.get("id", "")
					)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V027_ATTACK_CATALOG_OK checks=%d cards=40" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V027_ATTACK_CATALOG_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
