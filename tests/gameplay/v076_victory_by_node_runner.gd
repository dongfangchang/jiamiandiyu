extends Node

## Branch A victory narration is keyed by diary node_id; the same node always
## gets the same id, and the id resolves to the data text.

const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")
const RouteContentData := preload("res://tests/fixtures/route_content_data.gd")

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
	var victory_map: Dictionary = RouteContentData.annotation_catalog().get("pools", {}).get(
		"victory", {}
	).get("by_node", {})
	var unique := {}
	for node_id in EXPECTED_NODES:
		var text := RouteContentData.annotation_text(String(victory_map.get(node_id, "")))
		_expect(text.find("0-08") >= 0, "victory mapped for %s" % node_id)
		unique[text] = true
	_expect(unique.size() == EXPECTED_NODES.size(), "victory lines are distinct")

	var ids: Array[String] = []
	for run in range(2):
		var engine := RouteEngineScript.new(RouteContentData.tingen_content(), &"route.v028.first_stage")
		_expect(engine.initialize().accepted, "route engine initializes")
		var first_id := EXPECTED_NODES[0]
		_expect(engine.submit(RouteCommandScript.select_node(StringName(first_id))).accepted, "select first")
		_expect(
			engine.submit(RouteCommandScript.resolve_node(
				StringName(first_id), &"victory", {"hp": 50, "corruption": 0, "attention": 0, "spirit": 4}
			)).accepted,
			"resolve victory"
		)
		var after := engine.get_snapshot().data
		var note := String(after.get("clue_annotations", {}).get(first_id, ""))
		_expect(note == String(victory_map.get(first_id, "")), "victory id matches map for first_hunt")
		_expect(first_id in after.get("completed_node_ids", []), "first completed")
		var view: Dictionary = after.get("nodes", [])[0]
		_expect(String(view.get("annotation_id", "")) == note, "node view carries annotation id")
		_expect(bool(view.get("can_advance", false)), "completed clue can advance")
		_expect(bool(after.get("nodes", [])[1].get("can_open", false)), "next clue opens after completion")
		_expect(not bool(after.get("nodes", [])[2].get("can_open", true)), "clue after an open one stays closed")
		ids.append(note)
	_expect(ids[0] == ids[1], "same node gets the same annotation id")

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
