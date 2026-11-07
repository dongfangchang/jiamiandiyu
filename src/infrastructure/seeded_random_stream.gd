class_name SeededRandomStream
extends RefCounted

var stream_name: StringName
var draw_count := 0

var _rng := RandomNumberGenerator.new()


func _init(name: StringName, seed_value: int) -> void:
	stream_name = name
	_rng.seed = seed_value


func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		push_error("next_int requires max_exclusive > 0")
		return 0
	draw_count += 1
	return _rng.randi_range(0, max_exclusive - 1)


func next_float() -> float:
	draw_count += 1
	return _rng.randf()


func shuffle_copy(values: Array) -> Array:
	var shuffled := values.duplicate()
	for index in range(shuffled.size() - 1, 0, -1):
		var swap_index := next_int(index + 1)
		var held: Variant = shuffled[index]
		shuffled[index] = shuffled[swap_index]
		shuffled[swap_index] = held
	return shuffled


func get_snapshot() -> Dictionary:
	return {
		"stream_name": String(stream_name),
		"draw_count": draw_count,
		"state": _rng.state,
	}
