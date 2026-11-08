extends SceneTree

const DiagnosticsServiceScript := preload(
	"res://src/infrastructure/playtest_diagnostics_service.gd"
)

const TEST_DIRECTORY := "user://mask_whispers_diagnostics_tests"

var _passed := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_remove_tree(TEST_DIRECTORY)
	var service = DiagnosticsServiceScript.new(TEST_DIRECTORY)
	service.start_session("v0.9.0", "test")
	service.record_event("route_started", {"route_id": "route.test"})
	service.record_event("battle_finished", {
		"outcome": "victory",
		"round_number": 5,
	})
	var finished = service.finish_session({"result": "completed"})
	_expect(finished.ok, "diagnostics session should finish")
	var path := String(finished.details.get("path", ""))
	_expect(FileAccess.file_exists(path), "diagnostics file should exist")
	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(path))
	_expect(parse_error == OK and json.data is Dictionary, "diagnostics JSON should parse")
	if json.data is Dictionary:
		_expect(int(json.data.get("document_version", 0)) == 1, "diagnostic version should persist")
		_expect(String(json.data.get("session_id", "")).begins_with("session_"), "session id should be stable")
		_expect(json.data.get("events", []).size() == 3, "all diagnostic events should be recorded")
		_expect(
			int(json.data.get("duration_ms", -1)) >= 0,
			"diagnostic duration should be non-negative"
		)

	var feedback = service.save_feedback(
		"战斗节奏合适，牌组页面清晰。",
		"battle",
		false,
		"good"
	)
	_expect(feedback.ok, "feedback should save")
	_expect(
		not service.get_latest_feedback_path().is_empty(),
		"latest feedback should be discoverable"
	)
	var empty_feedback = service.save_feedback("", "overall", false, "good")
	_expect(not empty_feedback.ok, "empty feedback should be rejected")
	var duplicate_finish = service.finish_session({})
	_expect(
		duplicate_finish.ok and bool(duplicate_finish.details.get("duplicate", false)),
		"duplicate finish should be idempotent"
	)

	_remove_tree(TEST_DIRECTORY)
	if _failures.is_empty():
		print("DIAGNOSTICS_TESTS_OK checks=%d" % _passed)
		quit(0)
		return
	for failure in _failures:
		printerr("DIAGNOSTICS_TEST_FAIL: %s" % failure)
	quit(1)


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
