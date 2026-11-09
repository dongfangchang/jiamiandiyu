class_name RouteContentAdapter
extends RouteContentPort

const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")

const EXPECTED_NODE_TYPES: Array[String] = [
	"normal",
	"elite",
	"rest",
	"boss",
	"ritual",
]

var content_version: String = ""
var base_cards_version: String = ""
var base_encounters_version: String = ""

var _default_route_id: StringName = &""
var _routes_by_id: Dictionary = {}
var _rituals_by_id: Dictionary = {}


func _init(
	routes_document: Dictionary,
	rituals_document: Dictionary,
	catalog: CampaignContentCatalog
) -> void:
	content_version = String(routes_document.get("content_version", ""))
	base_cards_version = String(routes_document.get("base_cards_version", ""))
	base_encounters_version = String(
		routes_document.get("base_encounters_version", "")
	)
	_validate_documents(routes_document, rituals_document, catalog)


func is_valid() -> bool:
	return (
		not content_version.is_empty()
		and not _default_route_id.is_empty()
		and _routes_by_id.has(String(_default_route_id))
	)


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if content_version.is_empty():
		errors.append("routes.content_version must not be empty")
	if base_cards_version.is_empty():
		errors.append("routes.base_cards_version must not be empty")
	if base_encounters_version.is_empty():
		errors.append("routes.base_encounters_version must not be empty")
	if _default_route_id.is_empty() or not _routes_by_id.has(String(_default_route_id)):
		errors.append("default_route_id must reference an existing route")
	return errors


func get_default_route_id() -> StringName:
	return _default_route_id


func get_route(route_id: StringName) -> Dictionary:
	var value: Variant = _routes_by_id.get(String(route_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func get_ritual(ritual_id: StringName) -> Dictionary:
	var value: Variant = _rituals_by_id.get(String(ritual_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func has_route(route_id: StringName) -> bool:
	return _routes_by_id.has(String(route_id))


func has_ritual(ritual_id: StringName) -> bool:
	return _rituals_by_id.has(String(ritual_id))


func _validate_documents(
	routes_document: Dictionary,
	rituals_document: Dictionary,
	catalog: CampaignContentCatalog
) -> void:
	if not _load_rituals(rituals_document):
		return
	if content_version.is_empty() or String(
		rituals_document.get("content_version", "")
	) != content_version:
		return
	if base_encounters_version != catalog.content_version:
		return
	if base_cards_version != catalog.cards_content_version:
		return
	var routes: Variant = routes_document.get("routes")
	if not routes is Array or routes.is_empty():
		return
	for route_value in routes:
		if not route_value is Dictionary:
			return
		var route: Dictionary = route_value
		var route_id := String(route.get("id", ""))
		if route_id.is_empty() or _routes_by_id.has(route_id):
			return
		if not _validate_route(route, catalog):
			return
		_routes_by_id[route_id] = route.duplicate(true)
	var default_id := String(routes_document.get("default_route_id", ""))
	if default_id.is_empty() or not _routes_by_id.has(default_id):
		return
	_default_route_id = StringName(default_id)


func _load_rituals(document: Dictionary) -> bool:
	var rituals: Variant = document.get("rituals")
	if not rituals is Array or rituals.is_empty():
		return false
	for ritual_value in rituals:
		if not ritual_value is Dictionary:
			return false
		var ritual: Dictionary = ritual_value
		var ritual_id := String(ritual.get("id", ""))
		if ritual_id.is_empty() or _rituals_by_id.has(ritual_id):
			return false
		if not _validate_ritual(ritual):
			return false
		_rituals_by_id[ritual_id] = ritual.duplicate(true)
	return true


func _validate_route(route: Dictionary, catalog: CampaignContentCatalog) -> bool:
	var nodes_value: Variant = route.get("nodes")
	if not nodes_value is Array or nodes_value.size() < 3 or nodes_value.size() > 12:
		return false
	var seen_node_ids: Dictionary = {}
	var seen_node_types: Dictionary = {}
	for value in nodes_value:
		if not value is Dictionary:
			return false
		var node: Dictionary = value
		var node_id := String(node.get("id", ""))
		if node_id.is_empty() or seen_node_ids.has(node_id):
			return false
		var node_type := String(node.get("type", ""))
		if node_type not in EXPECTED_NODE_TYPES:
			return false
		seen_node_ids[node_id] = true
		seen_node_types[node_type] = true
		if node_type in ["normal", "elite", "boss"]:
			if not catalog.has_encounter(
				StringName(node.get("encounter_id", ""))
			):
				return false
		elif node_type == "ritual":
			if not has_ritual(StringName(node.get("ritual_id", ""))):
				return false
	var options_value: Variant = route.get("rest_options")
	if not options_value is Array or options_value.size() < 2:
		return false
	var seen_rest_ids: Dictionary = {}
	for option_value in options_value:
		if not option_value is Dictionary:
			return false
		var option_id := String(option_value.get("id", ""))
		if option_id.is_empty() or seen_rest_ids.has(option_id):
			return false
		seen_rest_ids[option_id] = true
	if not seen_node_types.has("ritual") or not seen_node_types.has("boss"):
		return false
	return true


func _validate_ritual(ritual: Dictionary) -> bool:
	var steps_value: Variant = ritual.get("steps")
	if not steps_value is Array or steps_value.size() != 3:
		return false
	var seen_step_ids: Dictionary = {}
	for step_value in steps_value:
		if not step_value is Dictionary:
			return false
		var step: Dictionary = step_value
		var step_id := String(step.get("id", ""))
		if step_id.is_empty() or seen_step_ids.has(step_id):
			return false
		seen_step_ids[step_id] = true
		var options_value: Variant = step.get("options")
		if not options_value is Array or options_value.size() < 2:
			return false
		var option_ids: Dictionary = {}
		for option_value in options_value:
			if not option_value is Dictionary:
				return false
			var option_id := String(option_value.get("id", ""))
			if option_id.is_empty() or option_ids.has(option_id):
				return false
			option_ids[option_id] = true
		var step_type := String(step.get("type", ""))
		if step_type == "select_ids":
			var ids: Variant = step.get("correct_ids")
			if not ids is Array or ids.is_empty():
				return false
			for id_value in ids:
				if not option_ids.has(String(id_value)):
					return false
		elif step_type == "ordered_ids":
			var order: Variant = step.get("correct_order")
			if not order is Array or order.size() != option_ids.size():
				return false
			for id_value in order:
				if not option_ids.has(String(id_value)):
					return false
		elif step_type == "select_id":
			if not option_ids.has(String(step.get("correct_id", ""))):
				return false
		else:
			return false
	return true
