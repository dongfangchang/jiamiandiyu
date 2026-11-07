extends RouteContentPort

var _base: RouteContentPort
var _progression: ProgressionEngine


func _init(base: RouteContentPort, progression: ProgressionEngine) -> void:
	_base = base
	_progression = progression


func get_default_route_id() -> StringName:
	return _base.get_default_route_id()


func get_route(route_id: StringName) -> Dictionary:
	var route: Dictionary = _base.get_route(route_id).duplicate(true)
	var initial_value: Variant = route.get("initial_run_state", {})
	if initial_value is Dictionary:
		route["initial_run_state"] = _progression.apply_battle_modifiers(
			initial_value.duplicate(true)
		)
	return route


func get_ritual(ritual_id: StringName) -> Dictionary:
	return _base.get_ritual(ritual_id).duplicate(true)
