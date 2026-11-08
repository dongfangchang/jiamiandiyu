extends Node

const RouteSelectScene := preload("res://scenes/ui/route_select_screen.tscn")
const AppBootstrapScript := preload("res://src/app/bootstrap.gd")

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	var previews = AppBootstrapScript.get_route_previews_v07({})
	_expect(previews.ok, "route previews should load")
	if not previews.ok:
		_finish()
		return
	_expect(previews.data.size() == 3, "route selection should expose three routes")
	var screen = RouteSelectScene.instantiate()
	add_child(screen)
	screen.set_routes(previews.data)
	await get_tree().process_frame
	_expect(
		screen.get_route_count() == 3,
		"route selection screen should render all route options"
	)
	_expect(
		not _contains_internal_id(screen),
		"route selection must not expose internal IDs"
	)
	var selected: Array[StringName] = []
	screen.route_selected.connect(func(route_id: StringName) -> void:
		selected.append(route_id)
	)
	screen.choose_route("route.v070.mirror_watch")
	_expect(
		selected == [&"route.v070.mirror_watch"],
		"choosing a route should emit its stable ID once"
	)
	screen.choose_route("route.missing")
	_expect(
		selected.size() == 1,
		"unknown route choices must not emit"
	)
	_finish()


func _contains_internal_id(root: Node) -> bool:
	if root is Label:
		var text_value := (root as Label).text
		if text_value.contains("route.") or text_value.contains("encounter."):
			return true
	for child in root.get_children():
		if _contains_internal_id(child):
			return true
	return false


func _finish() -> void:
	if _failures.is_empty():
		print("V011_ROUTE_SELECT_UI_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V011_ROUTE_SELECT_UI_FAIL: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
