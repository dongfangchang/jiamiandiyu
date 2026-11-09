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
	_expect(previews.data.size() >= 3, "route selection should expose the available routes")
	var screen = RouteSelectScene.instantiate()
	add_child(screen)
	screen.set_routes(previews.data)
	await get_tree().process_frame
	_expect(
		screen.get_route_count() == previews.data.size(),
		"route selection screen should render all available route options"
	)
	_expect(
		not _contains_internal_id(screen),
		"route selection must not expose internal IDs"
	)
	var selected: Array[StringName] = []
	screen.route_selected.connect(func(route_id: StringName) -> void:
		selected.append(route_id)
	)
	screen.choose_route("route.v028.first_stage")
	_expect(
		selected == [&"route.v028.first_stage"],
		"choosing a route should emit its stable ID once"
	)
	for planned_id in ["chapter.planned.tingen", "chapter.planned.backlund", "chapter.planned.sea", "route.v070.mirror_watch"]:
		screen.choose_route(planned_id)
		_expect(selected.size() == 1, "planned and retired chapters must not start: " + planned_id)
	var planned_buttons := _count_disabled_plans(screen)
	_expect(planned_buttons == 3, "all future chapter buttons should be visibly disabled")
	var returned := [false]
	screen.back_requested.connect(func() -> void: returned[0] = true)
	var back: Button = screen.get("_back_button")
	_expect(not back.disabled, "return to title must remain enabled")
	back.pressed.emit()
	_expect(returned[0], "return to title should emit its navigation signal")
	screen.choose_route("route.missing")
	_expect(
		selected.size() == 1,
		"unknown route choices must not emit"
	)
	_finish()


func _count_disabled_plans(root: Node) -> int:
	var count := 0
	if root is Button and (root as Button).text == "规划中 · 尚未开放" and (root as Button).disabled:
		count += 1
	for child in root.get_children():
		count += _count_disabled_plans(child)
	return count


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
