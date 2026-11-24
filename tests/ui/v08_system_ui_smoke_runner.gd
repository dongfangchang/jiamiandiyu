extends Node

## Title system slips: first-run guide, settings (incl. backup restore),
## feedback, new-game confirmation and the debug test profile, all driven
## through their text items.

const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")

var _screen: Control
var _preferences_events := 0
var _restore_events := 0
var _feedback_events := 0
var _test_profile_events := 0
var _new_game_events := 0
var _passed := 0
var _failures: Array[String] = []


func _ready() -> void:
	_screen = StartScreenScene.instantiate()
	add_child(_screen)
	_screen.preferences_changed.connect(func(_preferences: Dictionary) -> void:
		_preferences_events += 1
	)
	_screen.restore_backup_requested.connect(func() -> void:
		_restore_events += 1
	)
	_screen.feedback_submitted.connect(func(_feedback: Dictionary) -> void:
		_feedback_events += 1
	)
	_screen.test_game_requested.connect(func() -> void:
		_test_profile_events += 1
	)
	_screen.new_game_requested.connect(func() -> void:
		_new_game_events += 1
	)
	_screen.show_checkpoint_status(
		"loaded",
		{
			"backup_available": true,
			"identity_id": "identity.reporter",
			"sequence": 8,
			"challenge_available": true,
		},
		"",
		{
			"settings_version": 1,
			"tutorial_seen": false,
			"fullscreen": false,
			"ui_scale": 1.0,
			"reduce_flash": false,
		}
	)
	await get_tree().process_frame
	await _run_checks()


func _run_checks() -> void:
	_expect(_screen.is_tutorial_open(), "first launch should show the guide")
	_expect(_press("下一步"), "guide has 下一步")
	await get_tree().process_frame
	_expect(_find_label_text("2 / 6"), "guide should advance")
	_expect(_press("跳过"), "guide has 跳过")
	await get_tree().process_frame
	_expect(not _screen.is_tutorial_open(), "guide should close")
	_expect(_preferences_events > 0, "finishing the guide should save preferences")

	_expect(_press("设置"), "menu has 设置")
	await get_tree().process_frame
	_expect(_screen.is_settings_open(), "settings slip should open")
	var before := _preferences_events
	_expect(_press_prefix("静音桌面音效"), "settings has the mute toggle")
	_expect(_preferences_events == before + 1, "toggling mute saves preferences")
	_expect(_press("恢复上次备份"), "settings has 恢复上次备份")
	_expect(_restore_events == 1, "backup restore should emit once")
	_screen.show_backup_restore_result(true, "ok")
	_expect(_screen.get_notice_text().contains("备份已恢复"), "restore result is written on the slip")
	_expect(_press("合上"), "settings has 合上")
	await get_tree().process_frame
	_expect(not _screen.is_settings_open(), "settings slip should close")

	_press("设置")
	await get_tree().process_frame
	_expect(_press("记录试玩反馈"), "settings has 记录试玩反馈")
	await get_tree().process_frame
	var text := _screen.find_child("FeedbackText", true, false) as TextEdit
	_expect(text != null, "feedback slip has a text field")
	if text != null:
		text.text = "战斗节奏合适，希望增加牌组封面。"
	_expect(_press("保存反馈"), "feedback has 保存反馈")
	_expect(_feedback_events == 1, "feedback should emit once")
	_press("取消")
	await get_tree().process_frame

	_expect(_press("新的日记"), "menu has 新的日记")
	await get_tree().process_frame
	_expect(_screen.is_confirm_open(), "new game should require confirmation when a checkpoint exists")
	_expect(_new_game_events == 0, "confirmation holds the request")
	_expect(_press("开始新的日记"), "confirmation has 开始新的日记")
	_expect(_new_game_events == 1, "confirming emits new game once")
	_screen.set_busy(false)
	await get_tree().process_frame

	if OS.is_debug_build():
		_expect(_press("测试档案"), "debug build lists 测试档案")
		_expect(_test_profile_events == 1, "test profile item should emit once")

	if _failures.is_empty():
		print("SYSTEM_UI_SMOKE_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("SYSTEM_UI_SMOKE_FAIL: %s" % failure)
	get_tree().quit(1)


func _press(text_value: String) -> bool:
	for node in _screen.find_children("*", "BaseButton", true, false):
		var button := node as Button
		if button != null and button.text == text_value and button.is_visible_in_tree() and not button.disabled:
			button.pressed.emit()
			return true
	return false


func _press_prefix(prefix: String) -> bool:
	for node in _screen.find_children("*", "BaseButton", true, false):
		var button := node as Button
		if button != null and button.text.begins_with(prefix) and button.is_visible_in_tree():
			button.button_pressed = not button.button_pressed
			return true
	return false


func _find_label_text(needle: String) -> bool:
	for node in _screen.find_children("*", "Label", true, false):
		if (node as Label).text.contains(needle):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
