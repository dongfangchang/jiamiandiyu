extends Node

## v0.74: Branch B overwrite text is keyed by diary node_id.

const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")

const EXPECTED_NODES: Array[String] = [
	"route.v028.first_stage.node.first_hunt",
	"route.v028.first_stage.node.tenant_trace",
	"route.v028.first_stage.node.mirror_pursuit",
	"route.v028.first_stage.node.boundary",
	"route.v028.first_stage.node.rest",
	"route.v028.first_stage.node.lamud",
	"route.v028.first_stage.node.baron",
	"route.v028.first_stage.node.ascension",
]

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	_expect(RouteEngineScript.PEN_REWRITE_EVERY_N == 3, "rewrite weight unchanged")
	var by_node: Dictionary = RouteEngineScript.PEN_REWRITE_BY_NODE
	_expect(by_node.size() >= 8, "per-node map covers Tingen clues")
	for node_id in EXPECTED_NODES:
		var line := String(by_node.get(node_id, ""))
		_expect(not line.is_empty(), "mapped rewrite for %s" % node_id)
		_expect(line.length() >= 16, "mapped line thick enough for %s" % node_id)

	## Distinct lines — no copy-paste across nodes.
	var unique := {}
	for node_id in EXPECTED_NODES:
		unique[String(by_node.get(node_id, ""))] = true
	_expect(unique.size() == EXPECTED_NODES.size(), "each node has a distinct rewrite")

	var content := V028RouteContent.new()
	var engine := RouteEngineScript.new(content, &"route.v028.first_stage")
	_expect(engine.initialize().accepted, "route engine initializes")
	var first_id := String(engine.get_snapshot().data.get("available_node_id", ""))
	_expect(first_id == "route.v028.first_stage.node.first_hunt", "first hunt available")
	_expect(engine.submit(RouteCommandScript.select_node(StringName(first_id))).accepted, "select first")
	_expect(
		engine.submit(RouteCommandScript.resolve_node(
			StringName(first_id),
			&"victory",
			{"hp": 50, "corruption": 0, "attention": 0, "spirit": 4}
		)).accepted,
		"resolve victory"
	)
	var after := engine.get_snapshot().data
	var overlays: Dictionary = after.get("clue_overlays", {})
	_expect(not overlays.is_empty(), "victory wrote a rewrite overlay")
	var matched := false
	for key in overlays.keys():
		var node_id := String(key)
		var overlay = overlays[key]
		if not overlay is Dictionary:
			continue
		var text_zh := String(overlay.get("text_zh", ""))
		var expected := String(by_node.get(node_id, ""))
		_expect(not expected.is_empty(), "overlay target has a map entry: %s" % node_id)
		_expect(text_zh == expected, "overlay text matches map for %s" % node_id)
		_expect(text_zh != String(RouteEngineScript.PEN_REWRITE_TEXTS[0]), "uses node map not only pool head")
		matched = text_zh == expected
	_expect(matched, "at least one overlay matched its node map")

	## Fallback path: unknown id returns a pool line (unit-level via public const + helper behavior).
	var fallback_engine := RouteEngineScript.new(content, &"route.v028.first_stage")
	fallback_engine.initialize()
	var fallback := fallback_engine._pen_rewrite_text_for("route.unknown.missing")
	_expect(not fallback.is_empty(), "unknown node falls back to pool text")
	_expect(
		fallback in RouteEngineScript.PEN_REWRITE_TEXTS
		or fallback.begins_with("「"),
		"fallback stays diary-voiced"
	)

	if _failures.is_empty():
		print("V074_PEN_BY_NODE_OK checks=%d" % _checks)
	else:
		print("V074_PEN_BY_NODE_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)


class V028RouteContent:
	extends RouteContentPort

	var _route: Dictionary = {}
	var _rituals: Dictionary = {}

	func _init() -> void:
		var routes_document := _read_json("res://data/routes/v0.7.0/routes.json")
		for route in routes_document.get("routes", []):
			if String(route.get("id", "")) == "route.v028.first_stage":
				_route = route.duplicate(true)
		var rituals_document := _read_json("res://data/rituals/v0.7.0/rituals.json")
		for ritual in rituals_document.get("rituals", []):
			_rituals[String(ritual.get("id", ""))] = ritual.duplicate(true)

	func get_default_route_id() -> StringName:
		return &"route.v028.first_stage"

	func get_route(route_id: StringName) -> Dictionary:
		if String(route_id) == "route.v028.first_stage":
			return _route.duplicate(true)
		return {}

	func get_ritual(ritual_id: StringName) -> Dictionary:
		return _rituals.get(String(ritual_id), {}).duplicate(true)

	func _read_json(path: String) -> Dictionary:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		return parsed if parsed is Dictionary else {}
