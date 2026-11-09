class_name ProgressionContentAdapter
extends ProgressionContentPort

var content_version: String = ""
var base_cards_version: String = ""

var _identities: Array = []
var _identities_by_id: Dictionary = {}
var _starter_card_ids: Array = []
var _gacha_pool: Array = []
var _reward_options: Array = []
var _upgrade_definitions: Dictionary = {}
var _potion_definitions: Array = []
var _digestion_rules: Dictionary = {}
var _battle_content: BattleContentPort


func _init(document: Dictionary, battle_content: BattleContentPort) -> void:
	_battle_content = battle_content
	content_version = String(document.get("content_version", ""))
	base_cards_version = String(document.get("base_cards_version", ""))
	_identities = document.get("identities", []).duplicate(true)
	for identity in _identities:
		if identity is Dictionary:
			_identities_by_id[String(identity.get("id", ""))] = identity.duplicate(true)
	_starter_card_ids = document.get("starter_card_ids", []).duplicate(true)
	_gacha_pool = document.get("gacha_pool", []).duplicate(true)
	_reward_options = document.get("reward_options", []).duplicate(true)
	_upgrade_definitions = document.get("upgrade_definitions", {}).duplicate(true)
	_potion_definitions = document.get("potion_definitions", []).duplicate(true)
	_digestion_rules = document.get("digestion_rules", {}).duplicate(true)


func get_identity_options() -> Array:
	return _identities.duplicate(true)


func get_identity(identity_id: StringName) -> Dictionary:
	var value: Variant = _identities_by_id.get(String(identity_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func has_card_definition(definition_id: StringName) -> bool:
	if _battle_content == null:
		return false
	return not _battle_content.get_card_definition(definition_id).is_empty()


func get_card_definition(definition_id: StringName) -> Dictionary:
	if _battle_content == null:
		return {}
	return _battle_content.get_card_definition(definition_id)


func get_starter_card_ids() -> Array:
	return _starter_card_ids.duplicate(true)


func get_gacha_pool() -> Array:
	return _gacha_pool.duplicate(true)


func get_reward_options() -> Array:
	return _reward_options.duplicate(true)


func get_upgrade_definition(definition_id: StringName) -> Dictionary:
	var value: Variant = _upgrade_definitions.get(String(definition_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func get_potion_definitions() -> Array:
	return _potion_definitions.duplicate(true)


func get_digestion_rules() -> Dictionary:
	return _digestion_rules.duplicate(true)
