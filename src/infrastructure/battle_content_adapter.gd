class_name BattleContentAdapter
extends BattleContentPort

var _cards_by_id: Dictionary = {}
var _synergies: Array = []


func _init(card_definitions: Array = [], synergy_definitions: Array = []) -> void:
	for definition in card_definitions:
		if definition is Dictionary:
			_cards_by_id[StringName(definition.get("id", ""))] = definition.duplicate(true)
	for synergy in synergy_definitions:
		if synergy is Dictionary:
			_synergies.append(synergy.duplicate(true))


func get_synergies() -> Array:
	return _synergies.duplicate(true)


func get_card_definition(definition_id: StringName) -> Dictionary:
	if not _cards_by_id.has(definition_id):
		return {}
	var definition: Dictionary = _cards_by_id[definition_id]
	return definition.duplicate(true)


func has_card(definition_id: StringName) -> bool:
	return _cards_by_id.has(definition_id)


func card_count() -> int:
	return _cards_by_id.size()
