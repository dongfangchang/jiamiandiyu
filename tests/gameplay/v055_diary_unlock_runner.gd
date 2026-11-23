extends Node

## v0.55: multi-clue unlock + soft defeat annotations.

const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var content := V028RouteContent.new()
	var engine := RouteEngineScript.new(content, &"route.v028.first_stage")
	var initialized := engine.initialize()
	_expect(initialized.accepted, "route engine initializes")
	var snap := engine.get_snapshot().data
	_expect(snap.has("unlocked_node_ids"), "snapshot has unlocked_node_ids")
	_expect(snap.has("clue_annotations"), "snapshot has clue_annotations")
	var first_id := String(snap.get("available_node_id", ""))
	_expect(first_id == "route.v028.first_stage.node.first_hunt", "first hunt available")
	_expect(first_id in snap.get("unlocked_node_ids", []), "first node unlocked")

	var select := engine.submit(RouteCommandScript.select_node(StringName(first_id)))
	_expect(select.accepted, "select first node")
	var resolve := engine.submit(RouteCommandScript.resolve_node(
		StringName(first_id),
		&"victory",
		{"hp": 50, "corruption": 0, "attention": 0, "spirit": 3}
	))
	_expect(resolve.accepted, "resolve victory")
	var after := engine.get_snapshot().data
	var unlocked: Array = after.get("unlocked_node_ids", [])
	_expect(unlocked.size() == 2, "victory unlocks exactly one additional clue")
	var annotations: Dictionary = after.get("clue_annotations", {})
	_expect(
		String(annotations.get(first_id, "")).find("0-08") >= 0,
		"victory writes 0-08 annotation"
	)
	_expect(first_id in after.get("completed_node_ids", []), "first completed")
	_expect(after.has("clue_overlays"), "snapshot has clue_overlays")
	var overlays: Dictionary = after.get("clue_overlays", {})
	_expect(not overlays.is_empty(), "victory rewrites one locked clue via 0-08")
	var rewritten_ok := false
	for key in overlays.keys():
		var overlay = overlays[key]
		if overlay is Dictionary and String(overlay.get("source", "")) == "0-08":
			rewritten_ok = not String(overlay.get("text_zh", "")).is_empty()
			break
	_expect(rewritten_ok, "overlay carries 0-08 rewritten text")

	var next_ids: Array[String] = []
	for node_id_value in unlocked:
		var node_id := String(node_id_value)
		if node_id != first_id and node_id not in after.get("completed_node_ids", []):
			next_ids.append(node_id)
	_expect(next_ids.size() >= 1, "next investigable clue exists")
	var next_id := next_ids[0]

	var select2 := engine.submit(RouteCommandScript.select_node(StringName(next_id)))
	_expect(select2.accepted, "select next node")
	var before_corruption := int(
		engine.get_snapshot().data.get("run_state", {}).get("corruption", 0)
	)
	var defeat := engine.submit(RouteCommandScript.resolve_node(
		StringName(next_id),
		&"defeat",
		{"hp": 40, "corruption": before_corruption, "attention": 0, "spirit": 2}
	))
	_expect(defeat.accepted, "resolve soft defeat")
	var defeated := engine.get_snapshot().data
	_expect(String(defeated.get("phase", "")) == "map", "defeat returns to map")
	var defeat_note := String(defeated.get("clue_annotations", {}).get(next_id, ""))
	_expect(defeat_note.find("0-08") >= 0, "defeat annotation present")
	_expect(
		next_id not in defeated.get("completed_node_ids", []),
		"defeated clue stays incomplete"
	)
	var after_corruption := int(defeated.get("run_state", {}).get("corruption", 0))
	_expect(after_corruption > before_corruption, "defeat raises corruption")

	## Soft defeat stains a locked clue with 墨渍; spirit wipe restores it (map phase).
	var stained_id := ""
	var notes: Dictionary = defeated.get("clue_annotations", {})
	for key in notes.keys():
		var node_id := String(key)
		if (
			String(notes[key]).find("墨渍") >= 0
			and node_id not in defeated.get("unlocked_node_ids", [])
			and node_id not in defeated.get("completed_node_ids", [])
		):
			stained_id = node_id
			break
	_expect(not stained_id.is_empty(), "defeat stains a locked clue with ink")
	var spirit_before := int(defeated.get("run_state", {}).get("spirit", 0))
	var wipe := engine.submit(RouteCommandScript.wipe_ink(StringName(stained_id)))
	_expect(wipe.accepted, "spirit wipe accepted")
	var wiped := engine.get_snapshot().data
	_expect(stained_id in wiped.get("unlocked_node_ids", []), "wipe unlocks stained clue")
	_expect(
		int(wiped.get("run_state", {}).get("spirit", 0)) == spirit_before - 2,
		"wipe spends 2 spirit"
	)
	_expect(int(wiped.get("spirit_wipe_cost", 0)) == 2, "snapshot exposes wipe cost")
	var poor := engine.submit(RouteCommandScript.wipe_ink(StringName(stained_id)))
	_expect(not poor.accepted, "cannot wipe already readable clue")

	var retry := engine.submit(RouteCommandScript.select_node(StringName(next_id)))
	_expect(retry.accepted, "can retry defeated clue")

	_finish()


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("V055_DIARY_UNLOCK_OK checks=%d" % _checks)
	else:
		print("V055_DIARY_UNLOCK_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
	get_tree().quit(0 if _failures.is_empty() else 1)


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
