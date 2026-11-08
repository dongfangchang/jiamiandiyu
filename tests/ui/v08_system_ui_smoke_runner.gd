extends Node

const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")

var _screen: Control
var _preferences_events := 0
var _restore_events := 0
var _feedback_events := 0
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
	_screen.show_checkpoint_status(
		"loaded",
		{
			"backup_available": true,
			"content_version": "v0.8.0",
			"identity_id": "identity.reporter",
			"sequence": 8,
			"deck_size": 8,
			"collection_count": 10,
			"divination_tickets": 3,
			"pity_counter": 1,
			"rare_pity": 4,
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
	_run_checks()


func _run_checks() -> void:
	_expect(_screen.get("_tutorial_overlay") != null, "first launch should show tutorial")
	_screen.call("_advance_tutorial")
	_expect(_screen.get("_tutorial_step") == 1, "tutorial should advance")
	_screen.call("_finish_tutorial")
	_expect(_screen.get("_tutorial_overlay") == null, "tutorial should close")
	_expect(_preferences_events > 0, "finishing tutorial should save preferences")

	_screen.call("_open_system_menu")
	_expect(_screen.get("_system_overlay") != null, "settings overlay should open")
	_screen.call("_close_system_menu")

	_screen.call("_on_restore_backup")
	_expect(_restore_events == 1, "backup restore should emit once")

	_screen.call("_open_feedback_form")
	var feedback_text: TextEdit = _screen.get("_feedback_text")
	feedback_text.text = "战斗节奏合适，希望增加牌组封面。"
	_screen.call("_submit_feedback")
	_expect(_feedback_events == 1, "feedback should emit once")
	_screen.call("_close_feedback_form")

	_screen.call("_on_new_game")
	var confirmation: ConfirmationDialog = _screen.get("_confirm_new_game")
	_expect(
		confirmation != null and confirmation.visible,
		"new game should require confirmation when a checkpoint exists"
	)

	if _failures.is_empty():
		print("SYSTEM_UI_SMOKE_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("SYSTEM_UI_SMOKE_FAIL: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
