extends Node

## Branch B overwrite is keyed by diary node_id: every Tingen clue has its own
## pen-rewrite id in the diary data, and the engine picks exactly that id.

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
	var by_node: Dictionary = RouteContentData.annotation_catalog().get("pools", {}).get(
		"pen_rewrite", {}
	).get("by_node", {})
	var unique := {}
	for node_id in EXPECTED_NODES:
		var annotation_id := String(by_node.get(node_id, ""))
		var text := RouteContentData.annotation_text(annotation_id)
		_expect(not annotation_id.is_empty(), "mapped rewrite id for %s" % node_id)
		_expect(text.length() >= 16, "mapped line thick enough for %s" % node_id)
		unique[text] = true
	_expect(unique.size() == EXPECTED_NODES.size(), "each node has a distinct rewrite")

	var engine := RouteEngineScript.new(RouteContentData.tingen_content(), &"route.v028.first_stage")
	_expect(engine.initialize().accepted, "route engine initializes")
	var first_id := String(engine.get_snapshot().data.get("available_node_id", ""))
	_expect(first_id == EXPECTED_NODES[0], "first hunt available")
	_expect(engine.submit(RouteCommandScript.select_node(StringName(first_id))).accepted, "select first")
	var resolved := engine.submit(RouteCommandScript.resolve_node(
		StringName(first_id), &"victory", {"hp": 50, "corruption": 0, "attention": 0, "spirit": 4}
	))
	_expect(resolved.accepted, "resolve victory")
	var overlays: Dictionary = engine.get_snapshot().data.get("clue_overlays", {})
	_expect(not overlays.is_empty(), "victory wrote a rewrite overlay")
	for key in overlays.keys():
		var node_id := String(key)
		var overlay_id := String(overlays[key].get("annotation_id", ""))
		_expect(overlay_id == String(by_node.get(node_id, "")), "overlay id matches node map for %s" % node_id)
	var rewritten := false
	for event in resolved.events:
		if event.type == &"ClueRewritten":
			rewritten = true
			_expect(
				String(event.data.get("annotation_id", "")) == String(by_node.get(String(event.data.get("node_id", "")), "")),
				"ClueRewritten event carries the node's id"
			)
			_expect(not event.data.has("text_zh"), "event carries no text")
	_expect(rewritten, "ClueRewritten emitted")

	## The snapshot node view mirrors the rewrite id for the UI.
	for node_value in engine.get_snapshot().data.get("nodes", []):
		var node_id := String(node_value.get("id", ""))
		if overlays.has(node_id):
			_expect(
				String(by_node.get(node_id, "")) in node_value.get("annotation_ids", []),
				"node view lists rewrite id for %s" % node_id
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
