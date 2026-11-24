extends Node

## Pen rewrite / defeat / re-ink narration: the engine emits annotation ids
## from the diary data pools and the same state always yields the same id.

const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")
const RouteContentData := preload("res://tests/fixtures/route_content_data.gd")

const ROUTE_ID := &"route.v028.first_stage"

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var catalog := RouteContentData.annotation_catalog()
	var pools: Dictionary = catalog.get("pools", {})
	var entries: Dictionary = catalog.get("entries", {})
	_expect(pools.get("pen_rewrite", {}).get("cycle", []).size() >= 10, "rewrite pool has at least 10 lines")
	_expect(pools.get("defeat", {}).get("cycle", []).size() >= 6, "defeat pool has at least 6 lines")
	_expect(pools.get("reink", {}).get("cycle", []).size() >= 5, "reink pool has at least 5 lines")
	_expect(pools.get("victory", {}).get("cycle", []).size() >= 4, "victory pool has at least 4 lines")
	for pool_id in pools.keys():
		for annotation_id in _pool_ids(pools[pool_id]):
			_expect(entries.has(annotation_id), "pool %s id resolves: %s" % [pool_id, annotation_id])
	## reink.generic.05 was never wipeable (pre-R2 text lacked the stain word);
	## kept as-is under the behaviour freeze.
	var stained_reink := 0
	for annotation_id in pools.get("reink", {}).get("cycle", []):
		if bool(entries.get(annotation_id, {}).get("ink_stain", false)):
			stained_reink += 1
	_expect(stained_reink >= 5, "reink pool lines are wipeable stains")

	var first := _play_victory_then_defeat()
	var second := _play_victory_then_defeat()
	_expect(first == second, "same commands give the same annotation ids")
	var overlays: Dictionary = first.get("overlays", {})
	_expect(not overlays.is_empty(), "victory writes a rewrite overlay")
	for key in overlays.keys():
		var overlay: Dictionary = overlays[key]
		_expect(String(key).begins_with("route."), "overlay keeps route node_id")
		var rewrite_id := String(overlay.get("annotation_id", ""))
		_expect(rewrite_id.begins_with("annotation.pen_rewrite."), "overlay carries pen rewrite id")
		_expect(RouteContentData.annotation_text(rewrite_id).length() >= 16, "overlay text resolves and is thick")
		_expect(not overlay.has("text_zh"), "overlay stores no text")
		_expect(
			RouteContentData.annotation_text(String(overlay.get("margin_note_id", ""))) != "",
			"margin note id resolves"
		)
	var defeat_id := String(first.get("defeat_id", ""))
	_expect(defeat_id.begins_with("annotation.defeat."), "defeat annotation id present")
	_expect(RouteContentData.annotation_text(defeat_id).find("0-08") >= 0, "defeat text resolves")
	_expect(bool(first.get("stained", false)), "defeat leaves a wipeable ink stain somewhere")

	if _failures.is_empty():
		print("V073_PEN_COPY_OK checks=%d" % _checks)
	else:
		print("V073_PEN_COPY_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _play_victory_then_defeat() -> Dictionary:
	var engine := RouteEngineScript.new(RouteContentData.tingen_content(), ROUTE_ID)
	_expect(engine.initialize().accepted, "route engine initializes")
	var first_id := String(engine.get_snapshot().data.get("available_node_id", ""))
	_expect(engine.submit(RouteCommandScript.select_node(StringName(first_id))).accepted, "select first node")
	_expect(engine.submit(RouteCommandScript.resolve_node(
		StringName(first_id), &"victory", {"hp": 50, "corruption": 0, "attention": 0, "spirit": 4}
	)).accepted, "resolve victory")
	var after := engine.get_snapshot().data
	var next_id := ""
	for node_id_value in after.get("unlocked_node_ids", []):
		var node_id := String(node_id_value)
		if node_id != first_id and node_id not in after.get("completed_node_ids", []):
			next_id = node_id
			break
	_expect(not next_id.is_empty(), "next investigable clue exists")
	_expect(engine.submit(RouteCommandScript.select_node(StringName(next_id))).accepted, "select next node")
	_expect(engine.submit(RouteCommandScript.resolve_node(
		StringName(next_id), &"defeat", {"hp": 40, "corruption": 0, "attention": 0, "spirit": 3}
	)).accepted, "resolve soft defeat")
	var defeated := engine.get_snapshot().data
	var stained := false
	for node_value in defeated.get("nodes", []):
		if bool(node_value.get("ink_stained", false)):
			stained = true
	return {
		"overlays": after.get("clue_overlays", {}),
		"victory_id": String(after.get("clue_annotations", {}).get(first_id, "")),
		"defeat_id": String(defeated.get("clue_annotations", {}).get(next_id, "")),
		"annotations": defeated.get("clue_annotations", {}),
		"stained": stained,
	}


func _pool_ids(pool: Dictionary) -> Array:
	var ids: Array = pool.get("cycle", []).duplicate()
	ids.append_array(pool.get("by_node", {}).values())
	if pool.has("default"):
		ids.append(pool["default"])
	return ids


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
