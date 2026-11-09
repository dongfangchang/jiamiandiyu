class_name ProgressionContentPort
extends RefCounted


func get_identity_options() -> Array:
	return []


func get_identity(_identity_id: StringName) -> Dictionary:
	return {}


func has_card_definition(_definition_id: StringName) -> bool:
	return false


func get_card_definition(_definition_id: StringName) -> Dictionary:
	return {}


func get_starter_card_ids() -> Array:
	return []


func get_gacha_pool() -> Array:
	return []


func get_reward_options() -> Array:
	return []


func get_upgrade_definition(_definition_id: StringName) -> Dictionary:
	return {}


func get_potion_definitions() -> Array:
	return []


func get_digestion_rules() -> Dictionary:
	return {}
