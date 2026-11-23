extends Node

## v0.76: Branch A victory narration keyed by diary node_id.

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
	var victory_map: Dictionary = RouteEngineScript.VICTORY_ANNOTATIONS_BY_NODE
	_expect(victory_map.size() >= 8, "victory map covers Tingen clues")
	var unique := {}
	for node_id in EXPECTED_NODES:
		var line := String(victory_map.get(node_id, ""))
		_expect(not line.is_empty(), "victory mapped for %s" % node_id)
		_expect(line.find("0-08") >= 0, "victory keeps 0-08 for %s" % node_id)
		_expect(line.find("真相") >= 0, "victory branch-A for %s" % node_id)
		unique[line] = true
	_expect(unique.size() == EXPECTED_NODES.size(), "victory lines are distinct")

	var content := V028RouteContent.new()
	var engine := RouteEngineScript.new(content, &"route.v028.first_stage")
	_expect(engine.initialize().accepted, "route engine initializes")
	var first_id := "route.v028.first_stage.node.first_hunt"
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
	var note := String(after.get("clue_annotations", {}).get(first_id, ""))
	var expected := String(victory_map.get(first_id, ""))
	_expect(note == expected, "victory note matches map for first_hunt")
	_expect(first_id in after.get("completed_node_ids", []), "first completed")
	_expect(
		engine._victory_annotation_for("route.unknown.missing").find("0-08") >= 0,
		"unknown victory falls back to pool"
	)

	if _failures.is_empty():
		print("V076_VICTORY_BY_NODE_OK checks=%d" % _checks)
	else:
		print("V076_VICTORY_BY_NODE_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
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
