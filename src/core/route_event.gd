class_name RouteEvent
extends RefCounted

var type: StringName
var data: Dictionary


func _init(event_type: StringName = &"", event_data: Dictionary = {}) -> void:
	type = event_type
	data = event_data.duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"type": String(type),
		"data": data.duplicate(true),
	}
