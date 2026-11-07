class_name SeededRandomService
extends RefCounted

const _FNV_OFFSET := 2166136261
const _FNV_PRIME := 16777619
const _LOW_32_MASK := 0xFFFFFFFF
const _SIGN_BIT_MASK := 0x7FFFFFFFFFFFFFFF

var root_seed: int
var _streams: Dictionary = {}


func _init(seed_value: int) -> void:
	root_seed = seed_value


func get_stream(stream_name: StringName) -> SeededRandomStream:
	var key := String(stream_name)
	if _streams.has(key):
		return _streams[key]

	var stream_seed := _derive_stream_seed(root_seed, key)
	var stream := SeededRandomStream.new(stream_name, stream_seed)
	_streams[key] = stream
	return stream


func get_debug_snapshot() -> Dictionary:
	var stream_snapshots: Array[Dictionary] = []
	var keys := _streams.keys()
	keys.sort()
	for key in keys:
		stream_snapshots.append(_streams[key].get_snapshot())
	return {
		"root_seed": root_seed,
		"streams": stream_snapshots,
	}


static func stable_name_hash(value: String) -> int:
	var hash_value := _FNV_OFFSET
	for byte in value.to_utf8_buffer():
		hash_value ^= int(byte)
		hash_value = (hash_value * _FNV_PRIME) & _LOW_32_MASK
	return hash_value


func _derive_stream_seed(seed_value: int, stream_name: String) -> int:
	var name_hash := stable_name_hash(stream_name)
	var mixed := (seed_value & _SIGN_BIT_MASK) ^ (name_hash << 16) ^ name_hash
	return mixed & _SIGN_BIT_MASK
