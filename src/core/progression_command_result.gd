class_name ProgressionCommandResult
extends RefCounted

var accepted: bool
var reason_code: StringName
var events: Array[ProgressionEvent]
var snapshot: ProgressionSnapshot


func _init(
	was_accepted: bool = false,
	reason: StringName = &"",
	emitted_events: Array[ProgressionEvent] = [],
	current_snapshot: ProgressionSnapshot = null
) -> void:
	accepted = was_accepted
	reason_code = reason
	events = emitted_events.duplicate()
	snapshot = current_snapshot


func to_dictionary() -> Dictionary:
	var event_values: Array[Dictionary] = []
	for event in events:
		event_values.append(event.to_dictionary())
	return {
		"accepted": accepted,
		"reason_code": String(reason_code),
		"events": event_values,
		"snapshot": snapshot.to_dictionary() if snapshot != null else {},
	}
