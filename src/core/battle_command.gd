class_name BattleCommand
extends RefCounted

const PLAY_CARD: StringName = &"play_card"
const END_TURN: StringName = &"end_turn"

var type: StringName = &""
var card_instance_id: StringName = &""
var target_id: StringName = &""


func _init(
	command_type: StringName,
	card_id: StringName = &"",
	enemy_id: StringName = &""
) -> void:
	type = command_type
	card_instance_id = card_id
	target_id = enemy_id


static func play_card(card_instance_id: StringName, target_id: StringName = &"") -> BattleCommand:
	return BattleCommand.new(PLAY_CARD, card_instance_id, target_id)


static func end_turn() -> BattleCommand:
	return BattleCommand.new(END_TURN)
