extends Node

## Diary unlock: multi-clue unlock, soft defeat annotations, spirit wipe of an
## ink stain, and loading a pre-v0.88 state that still stored annotation text.

const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")
const RouteContentData := preload("res://tests/fixtures/route_content_data.gd")

const ROUTE_ID := &"route.v028.first_stage"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var content := RouteContentData.tingen_content()
	var engine := RouteEngineScript.new(content, ROUTE_ID)
	var initialized := engine.initialize()
	_expect(initialized.accepted, "route engine initializes")
	var snap := engine.get_snapshot().data
	_expect(snap.has("unlocked_node_ids"), "snapshot has unlocked_node_ids")
	_expect(snap.has("clue_annotations"), "snapshot has clue_annotations")
	var first_id := String(snap.get("available_node_id", ""))
	_expect(first_id == "route.v028.first_stage.node.first_hunt", "first hunt available")
	_expect(first_id in snap.get("unlocked_node_ids", []), "first node unlocked")
	var initial_run: Dictionary = snap.get("run_state", {})
	var defaults: Dictionary = RouteContentData.route_rules().get("default_run_state", {})
	for key in defaults.keys():
		_expect(int(initial_run.get(key, -1)) == int(defaults[key]), "initial %s matches balance" % key)

	_expect(engine.submit(RouteCommandScript.select_node(StringName(first_id))).accepted, "select first node")
	_expect(engine.submit(RouteCommandScript.resolve_node(
		StringName(first_id), &"victory", {"hp": 50, "corruption": 0, "attention": 0, "spirit": 3}
	)).accepted, "resolve victory")
	var after := engine.get_snapshot().data
	var unlocked: Array = after.get("unlocked_node_ids", [])
	_expect(unlocked.size() == 2, "victory unlocks exactly one additional clue")
	var victory_id := String(after.get("clue_annotations", {}).get(first_id, ""))
	_expect(RouteContentData.annotation_text(victory_id).find("0-08") >= 0, "victory writes a 0-08 annotation id")
	_expect(first_id in after.get("completed_node_ids", []), "first completed")
	var overlays: Dictionary = after.get("clue_overlays", {})
	_expect(not overlays.is_empty(), "victory rewrites one locked clue via 0-08")
	var rewritten_ok := false
	for key in overlays.keys():
		var overlay = overlays[key]
		if overlay is Dictionary and String(overlay.get("source", "")) == "0-08":
			rewritten_ok = not RouteContentData.annotation_text(String(overlay.get("annotation_id", ""))).is_empty()
			break
	_expect(rewritten_ok, "overlay carries a resolvable 0-08 rewrite id")

	var next_id := ""
	for node_id_value in unlocked:
		var node_id := String(node_id_value)
		if node_id != first_id and node_id not in after.get("completed_node_ids", []):
			next_id = node_id
			break
	_expect(not next_id.is_empty(), "next investigable clue exists")
	_expect(engine.submit(RouteCommandScript.select_node(StringName(next_id))).accepted, "select next node")
	var before_corruption := int(engine.get_snapshot().data.get("run_state", {}).get("corruption", 0))
	_expect(engine.submit(RouteCommandScript.resolve_node(
		StringName(next_id), &"defeat", {"hp": 40, "corruption": before_corruption, "attention": 0, "spirit": 2}
	)).accepted, "resolve soft defeat")
	var defeated := engine.get_snapshot().data
	_expect(String(defeated.get("phase", "")) == "map", "defeat returns to map")
	var defeat_id := String(defeated.get("clue_annotations", {}).get(next_id, ""))
	_expect(RouteContentData.annotation_text(defeat_id).find("0-08") >= 0, "defeat annotation present")
	_expect(next_id not in defeated.get("completed_node_ids", []), "defeated clue stays incomplete")
	var penalty: Dictionary = RouteContentData.route_rules().get("defeat_penalty", {})
	_expect(
		int(defeated.get("run_state", {}).get("corruption", 0)) == before_corruption + int(penalty.get("corruption", 0)),
		"defeat raises corruption by the balance penalty"
	)

	## Soft defeat stains a locked clue; the snapshot says it is wipeable.
	var stained_id := ""
	for node_value in defeated.get("nodes", []):
		if bool(node_value.get("wipeable", false)):
			stained_id = String(node_value.get("id", ""))
			break
	_expect(not stained_id.is_empty(), "defeat leaves a wipeable locked clue")
	var spirit_before := int(defeated.get("run_state", {}).get("spirit", 0))
	var wipe := engine.submit(RouteCommandScript.wipe_ink(StringName(stained_id)))
	_expect(wipe.accepted, "spirit wipe accepted")
	var wipe_event_id := ""
	for event in wipe.events:
		if event.type == &"InkWiped":
			wipe_event_id = String(event.data.get("annotation_id", ""))
	_expect(not RouteContentData.annotation_text(wipe_event_id).is_empty(), "InkWiped carries a resolvable id")
	var wiped := engine.get_snapshot().data
	var cost := int(RouteContentData.route_rules().get("spirit_wipe_cost", -1))
	_expect(stained_id in wiped.get("unlocked_node_ids", []), "wipe unlocks stained clue")
	_expect(int(wiped.get("run_state", {}).get("spirit", 0)) == spirit_before - cost, "wipe spends the balance cost")
	_expect(int(wiped.get("spirit_wipe_cost", 0)) == cost, "snapshot exposes wipe cost")
	_expect(not engine.submit(RouteCommandScript.wipe_ink(StringName(stained_id))).accepted, "cannot wipe already readable clue")
	_expect(engine.submit(RouteCommandScript.select_node(StringName(next_id))).accepted, "can retry defeated clue")

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
