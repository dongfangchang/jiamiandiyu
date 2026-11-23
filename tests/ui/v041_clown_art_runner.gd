extends Node

## v0.41.0: clown card art exists and catalog/battle/deck resolve the same path.

const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")
const BattleScreenScript := preload("res://src/ui/battle_screen.gd")

const CLOWN_IDS: Array[String] = [
	"card.skill.veil_step",
	"card.skill.severed_fate",
	"card.skill.paper_swarm",
	"card.skill.mirror_shard",
	"card.skill.last_witness",
	"card.skill.false_death",
	"card.skill.sealed_answer",
	"card.skill.hollow_bell",
]

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var battle = BattleScreenScript.new()
	add_child(battle)
	await get_tree().process_frame
	for definition_id in CLOWN_IDS:
		var suffix := definition_id.get_slice(".", definition_id.get_slice_count(".") - 1)
		var expected := "res://assets/game/v0.41.0/cards/card_skill_%s.png" % suffix
		_expect(ResourceLoader.exists(expected), "%s png exists" % definition_id)
		var progression_path := ProgressionCatalog.card_art(definition_id)
		var deck_path := DeckCatalog.card_art(definition_id)
		var battle_path := battle.get_card_art_path(StringName(definition_id))
		_expect(progression_path == expected, "%s progression catalog path" % definition_id)
		_expect(deck_path == expected, "%s deck catalog path" % definition_id)
		_expect(battle_path == expected, "%s battle path" % definition_id)
		_expect(
			progression_path == deck_path and deck_path == battle_path,
			"%s three surfaces share one art path" % definition_id
		)
		_expect(progression_path != ProgressionCatalog.CARD_BACK, "%s not card back" % definition_id)
	battle.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V041_CLOWN_ART_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V041_CLOWN_ART_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
