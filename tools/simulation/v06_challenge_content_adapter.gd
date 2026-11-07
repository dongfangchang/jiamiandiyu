extends ChallengeContentPort

var _document: Dictionary
var _challenges_by_id: Dictionary = {}


func _init(document: Dictionary) -> void:
	_document = document.duplicate(true)
	for value in _document.get("challenges", []):
		if value is Dictionary:
			var challenge: Dictionary = value.duplicate(true)
			_challenges_by_id[String(challenge.get("id", ""))] = challenge


func get_default_challenge_id() -> StringName:
	return StringName(_document.get("default_challenge_id", ""))


func get_challenge(challenge_id: StringName) -> Dictionary:
	return _challenges_by_id.get(String(challenge_id), {}).duplicate(true)
