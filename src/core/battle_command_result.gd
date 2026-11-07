class_name BattleCommandResult
extends RefCounted

var accepted: bool = false
var reason_code: StringName = &""
var events: Array[BattleEvent] = []
var snapshot: BattleSnapshot


func _init(
	was_accepted: bool,
	reason: StringName,
	result_events: Array[BattleEvent],
	result_snapshot: BattleSnapshot
) -> void:
	accepted = was_accepted
	reason_code = reason
	events = result_events
	snapshot = result_snapshot


func to_dictionary() -> Dictionary:
	var event_data: Array[Dictionary] = []
	for event in events:
		event_data.append(event.to_dictionary())
	return {
		"accepted": accepted,
		"reason_code": String(reason_code),
		"events": event_data,
		"snapshot": snapshot.to_dictionary() if snapshot != null else {},
	}
