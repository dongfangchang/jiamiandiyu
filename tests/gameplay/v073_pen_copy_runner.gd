extends Node

## v0.73: thicker 0-08 rewrite pool + deeper defeat / re-ink narration.

const RouteEngineScript := preload("res://src/gameplay/route_engine.gd")
const RouteCommandScript := preload("res://src/core/route_command.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	var source := FileAccess.get_file_as_string("res://src/gameplay/route_engine.gd")
	_expect(not source.is_empty(), "route_engine source readable")
	_expect(source.find("PEN_REWRITE_EVERY_N := 3") >= 0, "rewrite weight unchanged")
	var rewrite_count := _count_pool_entries(source, "PEN_REWRITE_TEXTS")
	var defeat_count := _count_pool_entries(source, "DEFEAT_ANNOTATIONS")
	var reink_count := _count_pool_entries(source, "REINK_ANNOTATIONS")
	var victory_count := _count_pool_entries(source, "VICTORY_ANNOTATIONS")
	_expect(rewrite_count >= 10, "rewrite pool has at least 10 lines")
	_expect(defeat_count >= 6, "defeat pool has at least 6 lines")
	_expect(reink_count >= 5, "reink pool has at least 5 lines")
	_expect(victory_count >= 4, "victory pool has at least 4 lines")
	_expect(source.find("夜色吞没") >= 0, "defeat branch names 夜色吞没")
	_expect(source.find("分支·真相") >= 0, "victory pool marks 真相 branch")
	_expect(source.find("墨渍回涌") >= 0, "reink keeps 墨渍回涌")
	_expect(source.find("查尼斯门") >= 0 or source.find("占卜俱乐部") >= 0, "rewrite flavor touches Tingen canon")

	var content := V028RouteContent.new()
	var engine := RouteEngineScript.new(content, &"route.v028.first_stage")
	var initialized := engine.initialize()
	_expect(initialized.accepted, "route engine initializes")
	var first_id := String(engine.get_snapshot().data.get("available_node_id", ""))
	_expect(not first_id.is_empty(), "first clue available")

	var select := engine.submit(RouteCommandScript.select_node(StringName(first_id)))
	_expect(select.accepted, "select first node")
	var resolve := engine.submit(RouteCommandScript.resolve_node(
		StringName(first_id),
		&"victory",
		{"hp": 50, "corruption": 0, "attention": 0, "spirit": 4}
	))
	_expect(resolve.accepted, "resolve victory")
	var after := engine.get_snapshot().data
	var overlays: Dictionary = after.get("clue_overlays", {})
	_expect(not overlays.is_empty(), "victory may write rewrite overlay")
	var overlay_long := false
	for key in overlays.keys():
		var overlay = overlays[key]
		if overlay is Dictionary:
			var text_zh := String(overlay.get("text_zh", ""))
			if text_zh.length() >= 16:
				overlay_long = true
			_expect(String(key).begins_with("route."), "overlay keeps route node_id")
	_expect(overlay_long, "overlay text is thickened")

	var unlocked: Array = after.get("unlocked_node_ids", [])
	var next_id := ""
	for node_id_value in unlocked:
		var node_id := String(node_id_value)
		if node_id != first_id and node_id not in after.get("completed_node_ids", []):
			next_id = node_id
			break
	_expect(not next_id.is_empty(), "next investigable clue exists")
	var select2 := engine.submit(RouteCommandScript.select_node(StringName(next_id)))
	_expect(select2.accepted, "select next node")
	var defeat := engine.submit(RouteCommandScript.resolve_node(
		StringName(next_id),
		&"defeat",
		{"hp": 40, "corruption": 0, "attention": 0, "spirit": 3}
	))
	_expect(defeat.accepted, "resolve soft defeat")
	var defeated := engine.get_snapshot().data
	var defeat_note := String(defeated.get("clue_annotations", {}).get(next_id, ""))
	_expect(defeat_note.find("0-08") >= 0, "defeat annotation present")
	_expect(
		defeat_note.find("夜色") >= 0
		or defeat_note.find("墨") >= 0
		or defeat_note.find("败") >= 0
		or defeat_note.find("失败") >= 0
		or defeat_note.find("悲剧") >= 0
		or defeat_note.find("软失败") >= 0,
		"defeat narration stays branch-C flavored"
	)
	var stained := false
	for key in defeated.get("clue_annotations", {}).keys():
		var note := String(defeated.get("clue_annotations", {}).get(key, ""))
		if note.find("墨渍") >= 0 or note.find("夜色") >= 0:
			stained = true
			break
	_expect(stained, "defeat leaves ink / night stain somewhere")

	if _failures.is_empty():
		print("V073_PEN_COPY_OK checks=%d" % _checks)
	else:
		print("V073_PEN_COPY_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _count_pool_entries(source: String, const_name: String) -> int:
	## Skip past Array[String] brackets; count only string literals in the pool body.
	var marker := "const %s:" % const_name
	var const_at := source.find(marker)
	if const_at < 0:
		return 0
	var open := source.find("= [", const_at)
	if open < 0:
		return 0
	var cursor := open + 3
	var depth := 1
	var end := -1
	while cursor < source.length():
		var ch := source.substr(cursor, 1)
		if ch == "[":
			depth += 1
		elif ch == "]":
			depth -= 1
			if depth == 0:
				end = cursor
				break
		cursor += 1
	if end < 0:
		return 0
	var block := source.substr(open, end - open)
	var count := 0
	var search_from := 0
	while true:
		var quote := block.find("\"", search_from)
		if quote < 0:
			break
		var close := block.find("\"", quote + 1)
		if close < 0:
			break
		count += 1
		search_from = close + 1
	return count


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
