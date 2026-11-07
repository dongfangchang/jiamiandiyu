class_name ChallengeCommandResult
extends RefCounted

var accepted: bool
var reason_code: StringName
var events: Array[ChallengeEvent]
var snapshot: ChallengeSnapshot
var route_result: RouteCommandResult


func _init(
	was_accepted: bool = false,
	reason: StringName = &"",
	emitted_events: Array[ChallengeEvent] = [],
	current_snapshot: ChallengeSnapshot = null,
	submitted_route_result: RouteCommandResult = null
) -> void:
	accepted = was_accepted
	reason_code = reason
	events = emitted_events.duplicate()
	snapshot = current_snapshot
	route_result = submitted_route_result


func to_dictionary() -> Dictionary:
	var event_values: Array[Dictionary] = []
	for event in events:
		event_values.append(event.to_dictionary())
	return {
		"accepted": accepted,
		"reason_code": String(reason_code),
		"events": event_values,
		"snapshot": snapshot.to_dictionary() if snapshot != null else {},
		"route_result": route_result.to_dictionary() if route_result != null else {},
	}
