extends Node
## BUG-0038: route nodes without a diary entry get fallback spreads whose seal
## issues the same RouteCommand as a main spread; the main volume is unchanged.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const DiaryCatalogScript := preload("res://src/ui/diary_ui_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const ROUTES_PATH := "res://data/routes/v0.7.0/routes.json"
const MAIN_ROUTE := "route.v028.first_stage"
const MAIN_PREFIX := "route.v028.first_stage.node."
const CHALLENGE_ROUTE := "route.v070.first_case"
const CHALLENGE_PREFIX := "route.v070.node."
## SHA-256 of JSON.stringify(build_view(...)) for the main route, recorded from
## the catalog before the fallback existed. Order: start, mid-route, all but
## ascension done, no nodes in the snapshot.
const MAIN_VIEW_HASHES := [
	"67de271d11e146b6d194eaa22e61d02b7c6603fc8777c5d5f70c94f89b8d8abd",
	"3030c9fc0be6fd20bb1ac39a6e7d024a5b235d23ac3b1d70d34bfa90429f6fa0",
	"25cacdc960835870872d0b6cf7c1824cf114ae2bed5a797df12b297d2ce85735",
	"23bb7b63bd49b689573e5a400c90056dcd8210ed10af7c7b805c697d6bc55fd3",
]

var _checks := 0
var _failures: Array[String] = []
var _commands: Array = []
var _routes: Dictionary = {}


func _ready() -> void:
	_routes = _load_routes()
	_expect(_routes.has(MAIN_ROUTE) and _routes.has(CHALLENGE_ROUTE), "route content loads")
	_test_main_view_unchanged()
	_test_challenge_fallback_spreads()
	await _test_challenge_seal_commands()
	if _failures.is_empty():
		print("CHALLENGE_DIARY_FALLBACK_OK checks=%d" % _checks)
	else:
		for failure in _failures:
			printerr("CHALLENGE_DIARY_FALLBACK_FAIL %s" % failure)
		print("CHALLENGE_DIARY_FALLBACK_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(0 if _failures.is_empty() else 1)


func _test_main_view_unchanged() -> void:
	var states := _main_states()
	for index in states.size():
		var view: Dictionary = DiaryCatalogScript.new().build_view(states[index])
		var digest := JSON.stringify(view).sha256_text()
		_expect(digest == MAIN_VIEW_HASHES[index], "main view %d is byte-identical" % index)
		for spread in view.get("spread_list", []):
			_expect(not spread.has("is_fallback"), "main spreads are never fallback")


func _test_challenge_fallback_spreads() -> void:
	var route_data := _challenge_state([], CHALLENGE_PREFIX + "first_hunt")
	var view: Dictionary = DiaryCatalogScript.new().build_view(route_data)
	var spreads: Array = view.get("spread_list", [])
	var nodes: Array = _routes.get(CHALLENGE_ROUTE, {}).get("nodes", [])
	_expect(spreads.size() == nodes.size(), "one fallback spread per challenge node (%d)" % spreads.size())
	for index in mini(spreads.size(), nodes.size()):
		var spread: Dictionary = spreads[index]
		var node: Dictionary = nodes[index]
		_expect(String(spread.get("node_id", "")) == String(node.get("id", "")), "spread %d follows route order" % index)
		_expect(bool(spread.get("is_fallback", false)), "spread %d is a fallback page" % index)
		_expect(
			String(spread.get("title_zh", "")) == String(node.get("display_name_zh", "")).substr(0, DiaryCatalogScript.TITLE_MAX),
			"spread %d title is the node display name" % index
		)
		_expect(spread.get("clues", []).size() == 1, "spread %d carries one sealable clue" % index)
	if spreads.size() >= 2:
		_expect(bool(spreads[0].get("is_available", false)), "first challenge node is available")
		_expect(bool(spreads[1].get("is_locked", false)), "second challenge node stays locked")
	_expect(String(view.get("display_name_zh", "")) == String(route_data.get("display_name_zh", "")), "volume title falls back to the route name")
	_expect(int(view.get("current_spread_idx", -1)) == 0, "challenge diary opens on its first page")
	for spread in spreads:
		_expect(not String(spread.get("node_id", "")).begins_with(MAIN_PREFIX), "no main volume page leaks into the challenge")

	var nameless := route_data.duplicate(true)
	nameless["nodes"] = [{"id": CHALLENGE_PREFIX + "first_hunt", "type": "normal"}]
	var nameless_view: Dictionary = DiaryCatalogScript.new().build_view(nameless)
	var nameless_spreads: Array = nameless_view.get("spread_list", [])
	_expect(
		nameless_spreads.size() == 1 and String(nameless_spreads[0].get("title_zh", "")) == "无名之页",
		"a node without a display name gets the generic title"
	)


func _test_challenge_seal_commands() -> void:
	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	var screen = DiaryScreenScript.new()
	screen.size = Vector2(1600, 900)
	host.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	screen.route_command_requested.connect(func(command): _commands.append(command))
	var desk = screen.get_desk_stage()
	_expect(desk != null, "desk stage present")
	if desk == null:
		host.queue_free()
		return

	screen.apply_snapshot(RouteSnapshotScript.new(_challenge_state([], CHALLENGE_PREFIX + "first_hunt")))
	await get_tree().process_frame
	_expect(screen.get_page_count() == 5, "challenge diary shows five spreads")
	var locked: Dictionary = screen.get_clue(CHALLENGE_PREFIX + "mirror_pursuit")
	_expect(int(locked.get("state", -1)) == DiaryCatalogScript.STATE_LOCKED, "later seal is locked")
	desk.seal_activated.emit(locked)
	await get_tree().process_frame
	_expect(_commands.is_empty(), "locked fallback seal issues no command")

	var first: Dictionary = screen.get_clue(CHALLENGE_PREFIX + "first_hunt")
	_expect(int(first.get("state", -1)) == DiaryCatalogScript.STATE_AVAILABLE, "first seal is available")
	desk.seal_activated.emit(first)
	await get_tree().process_frame
	_expect(_commands.size() == 1, "available seal issues one command")
	if _commands.size() == 1:
		var command: RouteCommand = _commands[0]
		_expect(command.type == RouteCommand.SELECT_NODE, "seal issues select_node")
		_expect(String(command.node_id) == CHALLENGE_PREFIX + "first_hunt", "select_node targets the first node")

	_commands.clear()
	var done := [
		CHALLENGE_PREFIX + "first_hunt",
		CHALLENGE_PREFIX + "mirror_pursuit",
		CHALLENGE_PREFIX + "old_house_rest",
		CHALLENGE_PREFIX + "mirror_baron",
	]
	screen.apply_snapshot(RouteSnapshotScript.new(_challenge_state(done, CHALLENGE_PREFIX + "ascension")))
	await get_tree().process_frame
	desk.seal_activated.emit(screen.get_clue(CHALLENGE_PREFIX + "ascension"))
	await get_tree().process_frame
	_expect(
		_commands.size() == 1 and _commands[0].type == RouteCommand.BEGIN_ASCENSION,
		"ritual fallback seal begins the ascension"
	)
	host.queue_free()


func _main_states() -> Array:
	var p := MAIN_PREFIX
	var bare := _main_state([], p + "first_hunt")
	bare.erase("nodes")
	var mid := _main_state([p + "first_hunt", p + "tenant_trace"], p + "mirror_pursuit")
	mid["clue_annotations"] = {p + "first_hunt": "旧注"}
	mid["clue_overlays"] = {p + "boundary": {"text_zh": "改写", "margin_note_zh": "页边"}}
	return [
		_main_state([], p + "first_hunt"),
		mid,
		_main_state([
			p + "first_hunt", p + "tenant_trace", p + "mirror_pursuit", p + "boundary",
			p + "rest", p + "lamud", p + "baron",
		], p + "ascension"),
		bare,
	]


func _main_state(completed: Array, available: String) -> Dictionary:
	return _state_for(MAIN_ROUTE, completed, available)


func _challenge_state(completed: Array, available: String) -> Dictionary:
	return _state_for(CHALLENGE_ROUTE, completed, available)


func _state_for(route_id: String, completed: Array, available: String) -> Dictionary:
	var route: Dictionary = _routes.get(route_id, {})
	var unlocked := completed.duplicate()
	unlocked.append(available)
	var nodes: Array = []
	for node_value in route.get("nodes", []):
		var node: Dictionary = node_value
		nodes.append({
			"id": String(node.get("id", "")),
			"type": String(node.get("type", "")),
			"display_name_zh": String(node.get("display_name_zh", "")),
			"scene_id": String(node.get("scene_id", "")),
		})
	return {
		"route_id": route_id,
		"display_name_zh": String(route.get("display_name_zh", "")),
		"phase": "map",
		"available_node_id": available,
		"completed_node_ids": completed.duplicate(),
		"unlocked_node_ids": unlocked,
		"clue_annotations": {},
		"clue_overlays": {},
		"nodes": nodes,
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 3, "max_spirit": 3,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
	}


func _load_routes() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_PATH))
	var result := {}
	if parsed is Dictionary:
		for route_value in parsed.get("routes", []):
			if route_value is Dictionary:
				result[String(route_value.get("id", ""))] = route_value
	return result


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
