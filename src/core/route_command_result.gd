class_name RouteCommandResult
extends RefCounted

var accepted: bool
var reason_code: StringName
var events: Array[RouteEvent]
var snapshot: RouteSnapshot
var ritual_snapshot: RitualSnapshot
var sequence_state: SequenceState


func _init(
	was_accepted: bool = false,
	reason: StringName = &"",
	emitted_events: Array[RouteEvent] = [],
	current_snapshot: RouteSnapshot = null,
	current_ritual: RitualSnapshot = null,
	current_sequence: SequenceState = null
) -> void:
	accepted = was_accepted
	reason_code = reason
	events = emitted_events.duplicate()
	snapshot = current_snapshot
	ritual_snapshot = current_ritual
	sequence_state = current_sequence


func to_dictionary() -> Dictionary:
	var event_values: Array[Dictionary] = []
	for event in events:
		event_values.append(event.to_dictionary())
	return {
		"accepted": accepted,
		"reason_code": String(reason_code),
		"events": event_values,
		"snapshot": snapshot.to_dictionary() if snapshot != null else {},
		"ritual_snapshot": (
			ritual_snapshot.to_dictionary()
			if ritual_snapshot != null
			else {}
		),
		"sequence_state": (
			sequence_state.to_dictionary()
			if sequence_state != null
			else {}
		),
	}
