extends Node

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const TEST_ROOT := "user://mask_whispers_v011_route_select"

var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	_remove_tree(TEST_ROOT)
	var previews = AppBootstrapScript.get_route_previews_v07({})
	_expect(previews.ok, "route previews should load")
	if previews.ok:
		var ids: Array[String] = []
		for preview in previews.data:
			ids.append(String(preview.get("id", "")))
			_expect(
				not String(preview.get("description_zh", "")).is_empty(),
				"route previews should include descriptions"
			)
		_expect(
			ids.has("route.v070.first_case")
			and ids.has("route.v070.broken_procession")
			and ids.has("route.v070.mirror_watch"),
			"route previews should contain all normal routes"
		)
	var started = AppBootstrapScript.start_route_v07(
		20261108,
		{
			"save_directory": TEST_ROOT,
			"test_profile": true,
			"route_id": "route.v070.mirror_watch",
		},
		"route_select_checkpoint",
		false
	)
	_expect(started.ok, "selected route should initialize")
	if not started.ok:
		printerr("V011_ROUTE_SELECT_DIAG: %s %s %s" % [
			String(started.code),
			started.message,
			str(started.details),
		])
	if started.ok:
		var route = started.data.get_route_snapshot()
		_expect(
			String(route.data.get("route_id", "")) == "route.v070.mirror_watch",
			"route snapshot should use the selected route"
		)
		var nodes: Array = route.data.get("nodes", [])
		_expect(
			nodes.size() == 5
			and String(nodes[0].get("encounter_id", ""))
				== "encounter.v070.twin_pursuit",
			"selected route should use its own node order"
		)
		var saved = started.data.save_checkpoint("route_select")
		_expect(saved.ok, "selected route checkpoint should save")
		var resumed = AppBootstrapScript.start_route_v07(
			20261108,
			{"save_directory": TEST_ROOT},
			"route_select_checkpoint",
			true
		)
		_expect(resumed.ok, "selected route checkpoint should resume")
		if resumed.ok:
			_expect(
				String(resumed.data.get_route_snapshot().data.get(
					"route_id",
					""
				)) == "route.v070.mirror_watch",
				"resume should preserve the selected route"
			)
	_remove_tree(TEST_ROOT)
	if _failures.is_empty():
		print("V011_ROUTE_SELECT_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V011_ROUTE_SELECT_FAIL: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)


func _remove_tree(relative_path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(relative_path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(file_name))
	for child_name in directory.get_directories():
		_remove_tree(relative_path.path_join(child_name))
	DirAccess.remove_absolute(absolute_path)
