extends Node

## v0.75: Branch C defeat / re-ink narration keyed by diary node_id.

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
	var defeat_map: Dictionary = RouteEngineScript.DEFEAT_ANNOTATIONS_BY_NODE
	var reink_map: Dictionary = RouteEngineScript.REINK_ANNOTATIONS_BY_NODE
	_expect(defeat_map.size() >= 8, "defeat map covers Tingen clues")
	_expect(reink_map.size() >= 8, "reink map covers Tingen clues")
	var defeat_unique := {}
	var reink_unique := {}
	for node_id in EXPECTED_NODES:
		var d := String(defeat_map.get(node_id, ""))
		var r := String(reink_map.get(node_id, ""))
		_expect(not d.is_empty(), "defeat mapped for %s" % node_id)
		_expect(not r.is_empty(), "reink mapped for %s" % node_id)
		_expect(d.find("0-08") >= 0, "defeat keeps 0-08 stamp for %s" % node_id)
		_expect(d.find("夜色") >= 0 or d.find("吞没") >= 0, "defeat branch-C for %s" % node_id)
		_expect(r.find("墨渍") >= 0, "reink keeps 墨渍 for wipe path %s" % node_id)
		defeat_unique[d] = true
		reink_unique[r] = true
	_expect(defeat_unique.size() == EXPECTED_NODES.size(), "defeat lines are distinct")
	_expect(reink_unique.size() == EXPECTED_NODES.size(), "reink lines are distinct")

	var content := V028RouteContent.new()
	var engine := RouteEngineScript.new(content, &"route.v028.first_stage")
	_expect(engine.initialize().accepted, "route engine initializes")
	var first_id := "route.v028.first_stage.node.first_hunt"
	_expect(engine.submit(RouteCommandScript.select_node(StringName(first_id))).accepted, "select first")
	## Defeat on first clue — annotation must match DEFEAT map for that node.
	_expect(
		engine.submit(RouteCommandScript.resolve_node(
			StringName(first_id),
			&"defeat",
			{"hp": 40, "corruption": 0, "attention": 0, "spirit": 4}
		)).accepted,
		"resolve soft defeat"
	)
	var defeated := engine.get_snapshot().data
	var defeat_note := String(defeated.get("clue_annotations", {}).get(first_id, ""))
	var expected_defeat := String(defeat_map.get(first_id, ""))
	_expect(defeat_note == expected_defeat, "defeat note matches map for first_hunt")
	_expect(String(defeated.get("phase", "")) == "map", "soft fail returns to map")
	_expect(first_id not in defeated.get("completed_node_ids", []), "failed clue stays incomplete")

	## Somewhere a re-ink stain uses the per-node map (or at least 墨渍).
	var stained_id := ""
	var stained_note := ""
	for key in defeated.get("clue_annotations", {}).keys():
		var node_id := String(key)
		if node_id == first_id:
			continue
		var note := String(defeated.get("clue_annotations", {}).get(key, ""))
		if note.find("墨渍") >= 0:
			stained_id = node_id
			stained_note = note
			break
	_expect(not stained_id.is_empty(), "defeat stains another clue with ink")
	var expected_reink := String(reink_map.get(stained_id, ""))
	if not expected_reink.is_empty():
		_expect(stained_note == expected_reink, "reink note matches map for %s" % stained_id)

	_expect(
		engine._defeat_annotation_for("route.unknown.missing").find("0-08") >= 0,
		"unknown defeat falls back to pool"
	)
	_expect(
		engine._reink_annotation_for("route.unknown.missing").find("墨渍") >= 0,
		"unknown reink falls back to pool"
	)

	if _failures.is_empty():
		print("V075_DEFEAT_BY_NODE_OK checks=%d" % _checks)
	else:
		print("V075_DEFEAT_BY_NODE_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
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
