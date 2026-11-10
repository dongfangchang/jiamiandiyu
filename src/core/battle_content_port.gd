class_name BattleContentPort
extends RefCounted


func get_card_definition(_definition_id: StringName) -> Dictionary:
	return {}


## Data-driven "original novel" combos. Each entry lists required card groups
## (one card from every group played in the same turn) and bonus effects.
func get_synergies() -> Array:
	return []
