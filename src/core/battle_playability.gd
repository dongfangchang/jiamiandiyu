class_name BattlePlayability
extends RefCounted

const PLAYABLE: StringName = &"playable"
const WRONG_PHASE: StringName = &"wrong_phase"
const CARD_NOT_IN_HAND: StringName = &"card_not_in_hand"
const INSUFFICIENT_SPIRIT: StringName = &"insufficient_spirit"
const INVALID_TARGET: StringName = &"invalid_target"

var playable: bool = false
var reason_code: StringName = CARD_NOT_IN_HAND


func _init(is_playable: bool = false, reason: StringName = CARD_NOT_IN_HAND) -> void:
	playable = is_playable
	reason_code = reason


func to_dictionary() -> Dictionary:
	return {
		"playable": playable,
		"reason_code": String(reason_code),
	}
