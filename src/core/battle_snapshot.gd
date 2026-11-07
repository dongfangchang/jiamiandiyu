class_name BattleSnapshot
extends RefCounted

var data: Dictionary = {}


func _init(snapshot_data: Dictionary = {}) -> void:
	data = snapshot_data.duplicate(true)


func to_dictionary() -> Dictionary:
	return data.duplicate(true)


func revision() -> int:
	return int(data.get("revision", 0))
