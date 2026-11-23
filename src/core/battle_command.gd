class_name BattleCommand
extends RefCounted

const PLAY_CARD: StringName = &"play_card"
const END_TURN: StringName = &"end_turn"

var type: StringName = &""
var card_instance_id: StringName = &""
var target_id: StringName = &""
## Hand instance ids chosen for discard effects on the played card.
var discard_instance_ids: Array[StringName] = []


func _init(
	command_type: StringName,
	card_id: StringName = &"",
	enemy_id: StringName = &"",
	discard_ids: Array = []
) -> void:
	type = command_type
	card_instance_id = card_id
	target_id = enemy_id
	discard_instance_ids.clear()
	for value in discard_ids:
		var id := StringName(value)
		if not id.is_empty():
			discard_instance_ids.append(id)


static func play_card(
	card_instance_id: StringName,
	target_id: StringName = &"",
	discard_ids: Array = []
) -> BattleCommand:
	return BattleCommand.new(PLAY_CARD, card_instance_id, target_id, discard_ids)


static func end_turn() -> BattleCommand:
	return BattleCommand.new(END_TURN)
