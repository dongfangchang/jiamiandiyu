class_name ProgressionCommand
extends RefCounted

const SELECT_IDENTITY: StringName = &"select_identity"
const RESOLVE_BATTLE: StringName = &"resolve_battle"
const CLAIM_REWARD: StringName = &"claim_reward"
const DRAW_GACHA: StringName = &"draw_gacha"
const UPGRADE_CARD: StringName = &"upgrade_card"

var type: StringName = &""
var identity_id: StringName = &""
var battle_outcome: StringName = &""
var reward_id: StringName = &""
var pull_count: int = 0
var definition_id: StringName = &""


func _init(
	command_type: StringName = &"",
	identity_id_value: StringName = &"",
	battle_outcome_value: StringName = &"",
	reward_id_value: StringName = &"",
	pull_count_value: int = 0,
	definition_id_value: StringName = &""
) -> void:
	type = command_type
	identity_id = identity_id_value
	battle_outcome = battle_outcome_value
	reward_id = reward_id_value
	pull_count = pull_count_value
	definition_id = definition_id_value


static func select_identity(identity_id_value: StringName) -> ProgressionCommand:
	return ProgressionCommand.new(SELECT_IDENTITY, identity_id_value)


static func resolve_battle(outcome: StringName) -> ProgressionCommand:
	return ProgressionCommand.new(RESOLVE_BATTLE, &"", outcome)


static func claim_reward(reward_id_value: StringName) -> ProgressionCommand:
	return ProgressionCommand.new(CLAIM_REWARD, &"", &"", reward_id_value)


static func draw_gacha(pull_count_value: int) -> ProgressionCommand:
	return ProgressionCommand.new(DRAW_GACHA, &"", &"", &"", pull_count_value)


static func upgrade_card(definition_id_value: StringName) -> ProgressionCommand:
	return ProgressionCommand.new(
		UPGRADE_CARD,
		&"",
		&"",
		&"",
		0,
		definition_id_value
	)
