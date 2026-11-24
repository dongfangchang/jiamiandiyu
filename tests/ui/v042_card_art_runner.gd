extends Node

const CardArt := preload("res://src/ui/card_art_catalog.gd")

## v0.42: gap cards wired; all 40 skill cards resolve off card-back.

const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")
const BattleScreenScript := preload("res://src/ui/battle_screen.gd")

const GAP_IDS: Array[String] = [
	"card.skill.ink_scarlet",
	"card.skill.echo_reading",
	"card.skill.midnight_ledger",
	"card.skill.borrowed_breath",
	"card.skill.glass_thesis",
	"card.skill.hungry_symbol",
	"card.skill.candle_archive",
	"card.skill.omen_chorus",
	"card.skill.closed_eye",
	"card.skill.black_thread",
	"card.skill.eclipse",
	"card.skill.red_corridor",
]

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var battle = BattleScreenScript.new()
	add_child(battle)
	await get_tree().process_frame
	for definition_id in GAP_IDS:
		var suffix := definition_id.get_slice(".", definition_id.get_slice_count(".") - 1)
		var expected := "res://assets/game/v0.42.0/cards/card_skill_%s.png" % suffix
		_expect(ResourceLoader.exists(expected), "%s png exists" % definition_id)
		var progression_path := ProgressionCatalog.card_art(definition_id)
		var deck_path := DeckCatalog.card_art(definition_id)
		var battle_path := battle.get_card_art_path(StringName(definition_id))
		_expect(progression_path == expected, "%s progression path" % definition_id)
		_expect(deck_path == expected, "%s deck path" % definition_id)
		var window := CardArt.art_window(definition_id)
		_expect(
			battle_path == (window if not window.is_empty() else expected),
			"%s battle prefers v0.85 art window" % definition_id
		)
		_expect(progression_path == deck_path, "%s progression and deck share plate" % definition_id)
	var cards: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/cards/v0.7.0/cards.json")
	)
	var skill_count := 0
	for card_value in cards.get("cards", []):
		if not card_value is Dictionary:
			continue
		var definition_id := String(card_value.get("id", ""))
		if not definition_id.begins_with("card.skill."):
			continue
		skill_count += 1
		var art := ProgressionCatalog.card_art(definition_id)
		_expect(not art.is_empty(), "%s has art path" % definition_id)
		_expect(art != ProgressionCatalog.CARD_BACK, "%s not card back" % definition_id)
		_expect(ResourceLoader.exists(art), "%s art file exists" % definition_id)
	_expect(skill_count == 40, "forty skill cards audited")
	battle.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V042_CARD_ART_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V042_CARD_ART_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
