class_name AppServices
extends RefCounted

const BattleRandomAdapterScript := preload("res://src/infrastructure/battle_random_adapter.gd")

var random: SeededRandomService
var saves: AtomicSaveService
var logger: StructuredLogger
var content: JsonDocumentLoader
var catalog: RefCounted


func _init(random_service: SeededRandomService) -> void:
	random = random_service
	saves = AtomicSaveService.new()
	logger = StructuredLogger.new()
	content = JsonDocumentLoader.new()


func create_battle_random(
	stream_name_value: StringName = &"battle.shuffle"
) -> BattleRandomPort:
	return BattleRandomAdapterScript.new(random.get_stream(stream_name_value))
