extends Node

## Branch C defeat / re-ink narration is keyed by diary node_id, and the re-ink
## stain is what makes a locked clue wipeable (snapshot flag, not text search).

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
	var catalog := RouteContentData.annotation_catalog()
	var pools: Dictionary = catalog.get("pools", {})
	var entries: Dictionary = catalog.get("entries", {})
	var defeat_map: Dictionary = pools.get("defeat", {}).get("by_node", {})
	var reink_map: Dictionary = pools.get("reink", {}).get("by_node", {})
	var defeat_unique := {}
	var reink_unique := {}
	for node_id in EXPECTED_NODES:
		var d := String(defeat_map.get(node_id, ""))
		var r := String(reink_map.get(node_id, ""))
		_expect(RouteContentData.annotation_text(d).find("0-08") >= 0, "defeat mapped for %s" % node_id)
		_expect(bool(entries.get(r, {}).get("ink_stain", false)), "reink is a wipeable stain for %s" % node_id)
		defeat_unique[d] = true
		reink_unique[r] = true
	_expect(defeat_unique.size() == EXPECTED_NODES.size(), "defeat ids are distinct")
	_expect(reink_unique.size() == EXPECTED_NODES.size(), "reink ids are distinct")

	var engine := RouteEngineScript.new(RouteContentData.tingen_content(), &"route.v028.first_stage")
	_expect(engine.initialize().accepted, "route engine initializes")
	var first_id := EXPECTED_NODES[0]
	_expect(engine.submit(RouteCommandScript.select_node(StringName(first_id))).accepted, "select first")
	_expect(
		engine.submit(RouteCommandScript.resolve_node(
			StringName(first_id), &"defeat", {"hp": 40, "corruption": 0, "attention": 0, "spirit": 4}
		)).accepted,
		"resolve soft defeat"
	)
	var defeated := engine.get_snapshot().data
	var notes: Dictionary = defeated.get("clue_annotations", {})
	_expect(String(notes.get(first_id, "")) == String(defeat_map.get(first_id, "")), "defeat id matches map for first_hunt")
	_expect(String(defeated.get("phase", "")) == "map", "soft fail returns to map")
	_expect(first_id not in defeated.get("completed_node_ids", []), "failed clue stays incomplete")

	var stained_view := {}
	for node_value in defeated.get("nodes", []):
		if String(node_value.get("id", "")) != first_id and bool(node_value.get("ink_stained", false)):
			stained_view = node_value
			break
	_expect(not stained_view.is_empty(), "defeat stains another clue with ink")
	var stained_id := String(stained_view.get("id", ""))
	_expect(String(notes.get(stained_id, "")) == String(reink_map.get(stained_id, "")), "reink id matches map for %s" % stained_id)
	_expect(bool(stained_view.get("wipeable", false)), "stained locked clue is wipeable with enough spirit")
	_expect(int(stained_view.get("wipe_cost", -1)) == int(RouteContentData.route_rules().get("spirit_wipe_cost", -2)), "wipe cost from balance")

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
