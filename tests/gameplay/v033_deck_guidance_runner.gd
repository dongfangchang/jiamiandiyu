extends Node

## v0.33.0: preset matchup guidance must live in data/decks and appear on deck snapshots.

const DeckEngineScript := preload("res://src/gameplay/deck_engine.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const DeckContentPortScript := preload("res://src/core/deck_content_port.gd")

const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"
const DECKS_PATH := "res://data/decks/v0.7.0/decks.json"
const PROGRESSION_PATH := "res://data/cards/v0.7.0/progression.json"

const REQUIRED_FIELDS := [
	"strategy_tag_zh",
	"best_against_zh",
	"caution_zh",
	"combo_focus_zh",
]

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_test_data_fields()
	_test_snapshot_fields()
	_finish()


func _test_data_fields() -> void:
	var decks := _read_json(DECKS_PATH)
	var presets: Array = decks.get("presets", [])
	_expect(presets.size() == 4, "four presets remain defined")
	for value in presets:
		var preset: Dictionary = value
		var preset_id := String(preset.get("id", ""))
		for field in REQUIRED_FIELDS:
			_expect(
				not String(preset.get(field, "")).strip_edges().is_empty(),
				"%s has %s" % [preset_id, field]
			)
	_expect(
		String(presets[3].get("best_against_zh", "")).contains("梅高欧丝")
			or String(presets[3].get("best_against_zh", "")).contains("老尼尔"),
		"echo preset calls out boss matchups"
	)
	_expect(
		String(presets[0].get("caution_zh", "")).contains("梅高欧丝")
			or String(presets[0].get("caution_zh", "")).contains("首领"),
		"ward preset warns about boss pressure"
	)


func _test_snapshot_fields() -> void:
	var decks := _read_json(DECKS_PATH)
	var cards := _read_json(CARDS_PATH)
	var progression := _read_json(PROGRESSION_PATH)
	var engine = DeckEngineScript.new(
		DeckContentFixture.new(decks),
		BattleContentAdapterScript.new(cards.get("cards", []))
	)
	var owned: Array = progression.get("starter_card_ids", []).duplicate()
	for preset in decks.get("presets", []):
		for card_id in preset.get("card_definition_ids", []):
			if not owned.has(String(card_id)):
				owned.append(String(card_id))
	var result = engine.initialize(owned)
	_expect(result.accepted, "deck engine initializes with guided presets")
	var views: Array = result.snapshot.data.get("presets", [])
	_expect(views.size() == 4, "snapshot exposes four presets")
	for value in views:
		var preset: Dictionary = value
		for field in REQUIRED_FIELDS:
			_expect(
				not String(preset.get(field, "")).strip_edges().is_empty(),
				"snapshot %s keeps %s" % [preset.get("id", ""), field]
			)


func _finish() -> void:
	if _failures.is_empty():
		print("V033_DECK_GUIDANCE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V033_DECK_GUIDANCE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


class DeckContentFixture:
	extends "res://src/core/deck_content_port.gd"

	var _document: Dictionary

	func _init(document: Dictionary) -> void:
		_document = document.duplicate(true)

	func get_default_preset_id() -> StringName:
		return StringName(_document.get("default_preset_id", ""))

	func get_required_deck_size() -> int:
		return int(_document.get("required_deck_size", 0))

	func get_preset_definitions() -> Array:
		return _document.get("presets", []).duplicate(true)

	func get_preset(preset_id: StringName) -> Dictionary:
		for preset in _document.get("presets", []):
			if String(preset.get("id", "")) == String(preset_id):
				return preset.duplicate(true)
		return {}

	func get_card_catalog_ids() -> Array:
		return _document.get("card_catalog_definition_ids", []).duplicate(true)
