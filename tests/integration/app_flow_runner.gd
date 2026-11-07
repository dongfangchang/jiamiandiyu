extends Node

const AppRootScene := preload("res://src/app/app_root.tscn")

const TEST_ROOT := "user://mask_whispers_app_integration"

var _checks := 0
var _failures: Array[String] = []
var _app: Control


func _ready() -> void:
	await get_tree().process_frame
	_remove_tree(TEST_ROOT)
	_app = AppRootScene.instantiate()
	_app.configure_for_testing(TEST_ROOT, "flow_slot", 424242)
	add_child(_app)
	await get_tree().process_frame
	await _test_start_route()
	await _test_new_game_and_battle_route()
	await _test_battle_to_saved_result()
	await _test_return_and_continue()
	await _test_corrupt_checkpoint_state()
	_remove_tree(TEST_ROOT)
	_finish()


func _test_start_route() -> void:
	_expect(_app.get_current_route() == &"start", "app starts on start route")
	var start = _app.get_current_screen()
	_expect(start != null, "start screen is mounted")
	_expect(not start.is_continue_enabled(), "continue disabled without checkpoint")
	_expect(start.get_status_text().contains("尚未"), "start screen shows empty checkpoint state")
	await get_tree().process_frame


func _test_new_game_and_battle_route() -> void:
	var result = _app.start_new_game(424242)
	await get_tree().process_frame
	_expect(result.ok, "new game starts from formal content")
	_expect(_app.get_current_route() == &"battle", "new game routes to battle")
	_expect(_app.get_session() != null, "real game session is retained")
	var battle = _app.get_current_screen()
	_expect(battle.get_snapshot_data().size() > 0, "battle screen receives real snapshot")
	_expect(String(battle.get_snapshot_data().get("battle_id", "")).contains("first_hunt"), "formal encounter is active")
	await get_tree().process_frame


func _test_battle_to_saved_result() -> void:
	var session = _app.get_session()
	for _index in 20:
		if String(session.get_snapshot().data.get("outcome", "")) != "":
			break
		var battle = _app.get_current_screen()
		var revision_before := int(battle.get_snapshot_data().get("revision", 0))
		battle.end_turn()
		await get_tree().process_frame
		_expect(
			int(session.get_snapshot().data.get("revision", 0)) > revision_before,
			"battle UI end-turn intent advances the real session"
		)
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"result", "battle outcome routes to result")
	var result_screen = _app.get_current_screen()
	_expect(result_screen.get_result_text() in ["胜利", "失败"], "result screen displays a legal outcome")
	_expect(result_screen.get_save_text().contains("保存"), "result screen displays checkpoint state")
	_expect(session.last_checkpoint_result != null and session.last_checkpoint_result.ok, "post-battle checkpoint saved")


func _test_return_and_continue() -> void:
	_app.get_current_screen().return_to_title_requested.emit()
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"start", "result returns to title")
	var start = _app.get_current_screen()
	_expect(start.is_continue_enabled(), "saved checkpoint enables continue")
	_expect(start.get_status_text().contains("检查点"), "title displays loaded checkpoint")

	_app.get_current_screen().continue_requested.emit()
	await get_tree().process_frame
	_expect(_app.get_current_route() == &"battle", "continue starts saved encounter")
	_expect(_app.get_session() != null, "continue creates a real battle session")


func _test_corrupt_checkpoint_state() -> void:
	var saves = AtomicSaveService.new(TEST_ROOT)
	var checkpoint_path: String = saves.get_slot_path("flow_slot")
	var file := FileAccess.open(checkpoint_path, FileAccess.WRITE)
	_expect(file != null, "integration test can prepare corrupt checkpoint")
	if file == null:
		return
	file.store_string("{broken")
	file.close()

	_app.show_start_screen()
	await get_tree().process_frame
	var start = _app.get_current_screen()
	_expect(_app.get_current_route() == &"start", "corrupt checkpoint stays on start route")
	_expect(not start.is_continue_enabled(), "corrupt checkpoint disables continue")
	_expect(start.get_status_text().contains("无法读取"), "corrupt checkpoint is reported without overwrite")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("APP_INTEGRATION_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("APP_INTEGRATION_FAIL %s" % failure)
	print("APP_INTEGRATION_FAIL checks=%d failures=%d" % [_checks, _failures.size()])
	get_tree().quit(1)


func _remove_tree(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(file_name))
	for child_name in directory.get_directories():
		_remove_tree(path.path_join(child_name))
	DirAccess.remove_absolute(absolute_path)
