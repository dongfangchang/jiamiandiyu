class_name BattleRandomAdapter
extends BattleRandomPort

var _stream: SeededRandomStream


func _init(stream: SeededRandomStream) -> void:
	_stream = stream


func next_int(max_exclusive: int) -> int:
	if _stream == null:
		push_error("BattleRandomAdapter requires a named random stream.")
		return 0
	return _stream.next_int(max_exclusive)


func stream_name() -> StringName:
	return _stream.stream_name if _stream != null else &""


func draw_count() -> int:
	return _stream.draw_count if _stream != null else 0
