class_name BattleBalanceAdapter
extends BattleBalancePort

const PARAMETER_PATHS: Dictionary = {
	&"player.base_max_hp": ["player", "max_health"],
	&"player.starting_health": ["player", "starting_health"],
	&"player.base_max_spirit": ["player", "spirit_per_turn"],
	&"player.starting_hand": ["player", "starting_hand"],
	&"player.turn_draw_to_hand_size": ["player", "turn_draw_to_hand_size"],
	&"player.max_hand_size": ["player", "max_hand_size"],
	&"player.max_corruption": ["player", "corruption", "max"],
	&"player.max_attention": ["player", "attention", "max"],
	&"battle.max_rounds": ["combat", "max_rounds"],
	&"battle.enemy_pressure_start_round": ["combat", "enemy_pressure", "start_round"],
	&"battle.chain": ["combat", "chain"],
	&"battle.danger_threshold": ["combat", "danger_threshold"],
	&"risk.corruption_thresholds": ["player", "corruption"],
	&"risk.attention_thresholds": ["player", "attention"],
	&"progression.sequence_9_to_8_requirements": ["upgrades", "sequence_advance"],
	&"gacha.rules": ["gacha"],
	&"progression.starting_divination_tickets": ["progression", "starting_divination_tickets"],
	&"gacha.single_cost": ["gacha", "single_cost"],
	&"gacha.triple_cost": ["gacha", "triple_cost"],
	&"gacha.pulls_per_triple": ["gacha", "pulls_per_triple"],
	&"gacha.rarity_weights": ["gacha", "rarity_weights"],
	&"gacha.rare_pity": ["gacha", "rare_pity"],
	&"gacha.duplicate_fragments": ["gacha", "duplicate_fragments"],
	&"upgrade.cost_by_next_level": ["upgrade", "cost_by_next_level"],
	&"reward.amounts": ["reward", "amounts"],
}

var _document: Dictionary


func _init(document: Dictionary) -> void:
	_document = document.duplicate(true)


func get_value(parameter_id: StringName) -> Variant:
	if not PARAMETER_PATHS.has(parameter_id):
		return null
	var current: Variant = _document
	for segment in PARAMETER_PATHS[parameter_id]:
		if not current is Dictionary or not current.has(String(segment)):
			return null
		current = current[String(segment)]
	return _copy_value(current)


func has_parameter(parameter_id: StringName) -> bool:
	return get_value(parameter_id) != null


func _copy_value(value: Variant) -> Variant:
	if value is Dictionary:
		return value.duplicate(true)
	if value is Array:
		return value.duplicate(true)
	return value
