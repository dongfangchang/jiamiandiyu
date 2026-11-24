extends RefCounted

## Test-only reader for the route balance and diary annotations that the app
## injects via RouteContentAdapter. Hand-written RouteContentPort fixtures
## delegate here so they stay on the same data files as the game.

const BALANCE_PATH := "res://data/balance/v0.7.0/balance.json"
const DIARY_PATH := "res://data/diaries/v0.55.0/tingen_volume_1.json"
const ROUTES_PATH := "res://data/routes/v0.7.0/routes.json"
const RITUALS_PATH := "res://data/rituals/v0.7.0/rituals.json"


static func route_rules() -> Dictionary:
	var rules: Variant = read_json(BALANCE_PATH).get("route", {})
	return rules.duplicate(true) if rules is Dictionary else {}


static func annotation_catalog() -> Dictionary:
	var annotations: Variant = read_json(DIARY_PATH).get("annotations", {})
	return annotations.duplicate(true) if annotations is Dictionary else {}


static func annotation_text(annotation_id: String) -> String:
	var entry: Variant = annotation_catalog().get("entries", {}).get(annotation_id, {})
	return String(entry.get("text_zh", "")) if entry is Dictionary else ""


static func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


## The Tingen volume route (route.v028.first_stage) on live v0.7 content.
class TingenContent:
	extends RouteContentPort

	const ROUTE_ID := "route.v028.first_stage"

	var _route: Dictionary = {}
	var _rituals: Dictionary = {}
	var _rules: Dictionary = {}
	var _annotations: Dictionary = {}

	func _init(rules: Dictionary, annotations: Dictionary, routes: Dictionary, rituals: Dictionary) -> void:
		_rules = rules
		_annotations = annotations
		for route in routes.get("routes", []):
			if String(route.get("id", "")) == ROUTE_ID:
				_route = route.duplicate(true)
		for ritual in rituals.get("rituals", []):
			_rituals[String(ritual.get("id", ""))] = ritual.duplicate(true)

	func get_default_route_id() -> StringName:
		return StringName(ROUTE_ID)

	func get_route(route_id: StringName) -> Dictionary:
		return _route.duplicate(true) if String(route_id) == ROUTE_ID else {}

	func get_ritual(ritual_id: StringName) -> Dictionary:
		return _rituals.get(String(ritual_id), {}).duplicate(true)

	func get_route_rules() -> Dictionary:
		return _rules.duplicate(true)

	func get_annotation_catalog() -> Dictionary:
		return _annotations.duplicate(true)


static func tingen_content() -> RouteContentPort:
	return TingenContent.new(
		route_rules(), annotation_catalog(), read_json(ROUTES_PATH), read_json(RITUALS_PATH)
	)
