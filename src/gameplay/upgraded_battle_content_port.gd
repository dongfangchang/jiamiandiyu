class_name UpgradedBattleContentPort
extends BattleContentPort

var _base: BattleContentPort
var _upgrade_definitions: Dictionary
var _card_levels: Dictionary


func _init(
	base: BattleContentPort,
	upgrade_definitions: Dictionary,
	card_levels: Dictionary
) -> void:
	_base = base
	_upgrade_definitions = upgrade_definitions.duplicate(true)
	_card_levels = card_levels.duplicate(true)


func get_card_definition(definition_id: StringName) -> Dictionary:
	var definition: Dictionary = _base.get_card_definition(definition_id)
	if definition.is_empty():
		return {}
	var level: int = maxi(0, int(_card_levels.get(String(definition_id), 0)))
	var upgrade_value: Variant = _upgrade_definitions.get(String(definition_id), {})
	if level == 0 or not upgrade_value is Dictionary:
		return definition
	var upgrade: Dictionary = upgrade_value
	var effects_value: Variant = definition.get("effects", [])
	if not effects_value is Array:
		return definition
	var effects: Array = effects_value
	for bonus_value in upgrade.get("bonuses", []):
		if not bonus_value is Dictionary:
			continue
		var bonus: Dictionary = bonus_value
		var effect_index: int = int(bonus.get("effect_index", -1))
		if effect_index < 0 or effect_index >= effects.size():
			continue
		if not effects[effect_index] is Dictionary:
			continue
		var effect: Dictionary = effects[effect_index]
		var field: String = String(bonus.get("field", ""))
		var amount_per_level: int = int(bonus.get("amount_per_level", 0))
		if field.is_empty() or amount_per_level == 0:
			continue
		effect[field] = int(effect.get(field, 0)) + amount_per_level * level
		effects[effect_index] = effect
	definition["effects"] = effects
	return definition
