class_name ChallengeRouteContentPort
extends RouteContentPort

var _base: RouteContentPort
var _initial_run_state: Dictionary


func _init(base: RouteContentPort, initial_run_state: Dictionary = {}) -> void:
	_base = base
	_initial_run_state = initial_run_state.duplicate(true)


func get_default_route_id() -> StringName:
	return _base.get_default_route_id()


func get_route(route_id: StringName) -> Dictionary:
	var route: Dictionary = _base.get_route(route_id).duplicate(true)
	if _initial_run_state.is_empty():
		return route
	var run_state_value: Variant = route.get("initial_run_state", {})
	var run_state: Dictionary = (
		run_state_value.duplicate(true) if run_state_value is Dictionary else {}
	)
	for key in _initial_run_state:
		run_state[key] = _initial_run_state[key]
	route["initial_run_state"] = run_state
	return route


func get_ritual(ritual_id: StringName) -> Dictionary:
	return _base.get_ritual(ritual_id).duplicate(true)
