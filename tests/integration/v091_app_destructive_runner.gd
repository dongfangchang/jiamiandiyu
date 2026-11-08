extends Node

const AppRootScene := preload("res://src/app/app_root.tscn")
const PreferencesServiceScript := preload(
	"res://src/infrastructure/player_preferences_service.gd"
)

const TEST_ROOT := "user://mask_whispers_v091_app_destructive"

var _passed := 0
var _failures: Array[String] = []
var _controller: Control


func _ready() -> void:
	_remove_tree(TEST_ROOT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_ROOT))
	var preferences_path := TEST_ROOT.path_join("preferences.json")
	var preferences = PreferencesServiceScript.new(preferences_path)
	preferences.save_preferences({
		"settings_version": 1,
		"tutorial_seen": true,
		"fullscreen": false,
		"ui_scale": 1.0,
		"reduce_flash": false,
	})

	_controller = AppRootScene.instantiate()
	_controller.configure_for_testing(
		TEST_ROOT.path_join("saves"),
		"test_checkpoint",
		20261108,
		preferences_path,
		TEST_ROOT.path_join("diagnostics")
	)
	add_child(_controller)
	await _wait_frames(3)

	var test_button := _button_by_text(_controller, "测试档案")
	_expect(test_button != null, "start screen should expose test profile")
	if test_button != null:
		test_button.pressed.emit()
	await _wait_frames(4)
	_expect(
		String(_controller.get_current_route()) == "map",
		"test profile should initialize the route map"
	)

	var route_hub_button := _button_by_text(_controller, "返回白昼档案")
	if route_hub_button != null:
		route_hub_button.pressed.emit()
	await _wait_frames(3)
	_expect(
		String(_controller.get_current_route()) == "hub",
		"route map should return to the hub"
	)

	var gacha_button := _button_by_text(_controller, "进行灵界祈愿")
	_expect(gacha_button != null, "hub should expose gacha")
	if gacha_button != null:
		gacha_button.pressed.emit()
	await _wait_frames(3)
	var single_button := _button_by_text(_controller, "单抽")
	_expect(single_button != null, "gacha should expose single draw")
	if single_button != null:
		single_button.pressed.emit()
	await _wait_frames(4)
	var gacha_screen = _controller.get_current_screen()
	_expect(
		gacha_screen != null
		and gacha_screen.has_method("get_result_count")
		and int(gacha_screen.get_result_count()) > 0,
		"successful draw should refresh displayed results"
	)
	var gacha_back := _button_by_text(_controller, "返回白昼档案")
	_expect(gacha_back != null and not gacha_back.disabled, "gacha must remain exitable")
	if gacha_back != null:
		gacha_back.pressed.emit()
	await _wait_frames(3)
	_expect(
		String(_controller.get_current_route()) == "hub",
		"gacha back should return to hub"
	)

	var battle_button := _button_by_text(_controller, "进入夜间战斗")
	if battle_button != null:
		battle_button.pressed.emit()
	await _wait_frames(3)
	var node_button := _button_by_text(_controller, "前往节点")
	_expect(node_button != null, "route map should expose the first node")
	if node_button != null:
		node_button.pressed.emit()
	await _wait_frames(4)
	_expect(
		String(_controller.get_current_route()) == "battle",
		"pressing a battle node should enter battle"
	)
	var exit_button := _button_by_text(_controller, "退出战斗")
	_expect(exit_button != null, "battle should expose exit")
	if exit_button != null:
		exit_button.pressed.emit()
	await _wait_frames(2)
	var battle_screen = _controller.get_current_screen()
	_expect(
		bool(battle_screen.is_exit_confirmation_visible()),
		"battle exit should ask for confirmation"
	)
	var confirmation: ConfirmationDialog = battle_screen.get("_exit_confirmation")
	if confirmation != null:
		confirmation.emit_signal("confirmed")
	await _wait_frames(3)
	_expect(
		String(_controller.get_current_route()) == "start",
		"confirmed battle exit should return to title"
	)

	_remove_tree(TEST_ROOT)
	if _failures.is_empty():
		print("V091_APP_DESTRUCTIVE_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V091_APP_DESTRUCTIVE_FAIL: %s" % failure)
	get_tree().quit(1)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _button_by_text(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child in root.get_children():
		var found := _button_by_text(child, text_value)
		if found != null:
			return found
	return null


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
