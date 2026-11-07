class_name SequenceState
extends RefCounted

var data: Dictionary


func _init(state_data: Dictionary = {}) -> void:
	data = state_data.duplicate(true)


func to_dictionary() -> Dictionary:
	return data.duplicate(true)
