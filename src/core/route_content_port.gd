class_name RouteContentPort
extends RefCounted


func get_default_route_id() -> StringName:
	return &""


func get_route(_route_id: StringName) -> Dictionary:
	return {}


func get_ritual(_ritual_id: StringName) -> Dictionary:
	return {}


## Route balance section (data/balance `route`): wipe cost, pen cadence,
## defeat penalties, default run stats. Empty means content is incomplete.
func get_route_rules() -> Dictionary:
	return {}


## Diary `annotations` section (pools / fixed / entries). Empty is allowed:
## the engine then emits only the `annotation.<pool>.default` ids.
func get_annotation_catalog() -> Dictionary:
	return {}
