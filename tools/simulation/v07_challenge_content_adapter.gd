extends "res://src/core/challenge_content_port.gd"

var _document: Dictionary
var _challenge_ids: Array[String] = []


func _init(document: Dictionary) -> void:
	_document = document.duplicate(true)
	for value in _document.get("challenges", []):
		if value is Dictionary:
			var challenge_id := String(value.get("id", ""))
			if not challenge_id.is_empty() and not challenge_id in _challenge_ids:
				_challenge_ids.append(challenge_id)


func get_default_challenge_id() -> StringName:
	return StringName(_document.get("default_challenge_id", ""))


func get_challenge_ids() -> Array:
	return _challenge_ids.duplicate()


func get_challenge(challenge_id: StringName) -> Dictionary:
	for value in _document.get("challenges", []):
		if value is Dictionary and String(value.get("id", "")) == String(challenge_id):
			return value.duplicate(true)
	return {}
