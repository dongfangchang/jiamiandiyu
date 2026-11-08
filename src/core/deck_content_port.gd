class_name DeckContentPort
extends RefCounted


func get_default_preset_id() -> StringName:
	return &""


func get_required_deck_size() -> int:
	return 0


func get_preset_definitions() -> Array:
	return []


func get_preset(_preset_id: StringName) -> Dictionary:
	return {}


func get_card_catalog_ids() -> Array:
	return []
