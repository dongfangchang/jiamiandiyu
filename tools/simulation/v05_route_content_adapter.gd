extends "res://src/core/route_content_port.gd"

var _default_route_id: StringName = &""
var _routes_by_id: Dictionary = {}
var _rituals_by_id: Dictionary = {}


func _init(routes_document: Dictionary, rituals_document: Dictionary) -> void:
	_default_route_id = StringName(routes_document.get("default_route_id", ""))
	for route_value in routes_document.get("routes", []):
		if route_value is Dictionary:
			var route: Dictionary = route_value
			_routes_by_id[String(route.get("id", ""))] = route.duplicate(true)
	for ritual_value in rituals_document.get("rituals", []):
		if ritual_value is Dictionary:
			var ritual: Dictionary = ritual_value
			_rituals_by_id[String(ritual.get("id", ""))] = ritual.duplicate(true)


func get_default_route_id() -> StringName:
	return _default_route_id


func get_route(route_id: StringName) -> Dictionary:
	var value: Variant = _routes_by_id.get(String(route_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func get_ritual(ritual_id: StringName) -> Dictionary:
	var value: Variant = _rituals_by_id.get(String(ritual_id), {})
	return value.duplicate(true) if value is Dictionary else {}
