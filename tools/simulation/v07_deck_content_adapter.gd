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
	for value in _document.get("presets", []):
		if value is Dictionary and String(value.get("id", "")) == String(preset_id):
			return value.duplicate(true)
	return {}


func get_card_catalog_ids() -> Array:
	return _document.get("card_catalog_definition_ids", []).duplicate(true)
