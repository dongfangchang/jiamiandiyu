extends Node
## ScreenRouter contract: one transition at a time, overlay blocks input while
## swapping, on_exit is awaited (and capped), the diary instance and its desk
## stage are reused, table SFX outlive the screen, back-target table shape.

const ScreenRouterScript := preload("res://src/app/screen_router.gd")
const AppControllerScript := preload("res://src/app/app_controller.gd")
const DiaryScene := preload("res://scenes/ui/diary_chapter_screen.tscn")
const TableSfx := preload("res://src/ui/table_sfx.gd")

const PROBE_SOURCE := """extends Control
signal exited
var exit_seconds := 0.0
var exit_forever := false
var exit_finished := false
var entered := 0
var presses := 0
var button: Button

func _ready() -> void:
	button = Button.new()
	button.text = "probe"
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func() -> void: presses += 1)
	add_child(button)

func on_enter() -> void:
	entered += 1

func on_exit() -> void:
	if exit_forever:
		await exited
	if exit_seconds > 0.0:
		await get_tree().create_timer(exit_seconds).timeout
	exit_finished = true
"""

var _passed := 0
var _failures: Array[String] = []
var _probe_scene: PackedScene
var _router: Control


func _ready() -> void:
	_probe_scene = _make_probe_scene()
	_router = ScreenRouterScript.new()
	add_child(_router)
	await get_tree().process_frame
	await _test_double_swap_applies_once()
	await _test_overlay_blocks_input_during_swap()
	await _test_on_exit_is_awaited_before_the_next_screen()
	await _test_on_exit_is_capped()
	await _test_diary_instance_is_reused()
	await _test_sfx_outlive_the_screen()
	_test_back_target_table()
	if _failures.is_empty():
		print("SCREEN_ROUTER_OK checks=%d" % _passed)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("SCREEN_ROUTER_FAIL %s" % failure)
	get_tree().quit(1)


func _test_double_swap_applies_once() -> void:
	var setups := [0]
	var count_setup := func(_screen: Control) -> void: setups[0] += 1
	_router.swap(_probe_scene, count_setup)
	var second = _router.swap(_probe_scene, count_setup)
	_expect(_router.is_busy(), "first swap holds the router")
	_expect(second == null, "a swap requested mid-transition is refused")
	await _wait_idle()
	_expect(setups[0] == 1, "only the first of two swaps is applied")
	_expect(_router.get_current_screen().entered == 1, "on_enter runs once for the applied swap")


func _test_overlay_blocks_input_during_swap() -> void:
	var old_screen: Control = _router.get_current_screen()
	await get_tree().process_frame
	var center: Vector2 = old_screen.button.get_global_rect().get_center()
	_router.swap(_probe_scene)
	_expect(
		_router.get_overlay().mouse_filter == Control.MOUSE_FILTER_STOP,
		"overlay stops the mouse during a swap"
	)
	_click(center)
	await get_tree().process_frame
	_expect(old_screen.presses == 0, "a click during the swap does not reach the old screen")
	await _wait_idle()
	var new_screen: Control = _router.get_current_screen()
	_expect(new_screen.presses == 0, "a click during the swap does not reach the new screen")
	_expect(
		_router.get_overlay().mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"overlay lets input through after the swap"
	)
	await get_tree().process_frame
	_click(new_screen.button.get_global_rect().get_center())
	await get_tree().process_frame
	_expect(new_screen.presses == 1, "input reaches the new screen once the swap ends")


func _test_on_exit_is_awaited_before_the_next_screen() -> void:
	var leaving: Control = _router.get_current_screen()
	leaving.exit_seconds = 0.3
	var exit_done_at_setup := [false]
	_router.swap(_probe_scene, func(_screen: Control) -> void:
		exit_done_at_setup[0] = leaving.exit_finished
	)
	await _wait_idle()
	_expect(exit_done_at_setup[0], "next screen is set up only after on_exit finished")
	_expect(_router.last_exit_was_awaited(), "router reports the exit hook as awaited")


func _test_on_exit_is_capped() -> void:
	var leaving: Control = _router.get_current_screen()
	leaving.exit_forever = true
	var started := Time.get_ticks_msec()
	_router.swap(_probe_scene)
	await _wait_idle()
	var elapsed := Time.get_ticks_msec() - started
	_expect(
		elapsed < int((ScreenRouterScript.EXIT_HOOK_CAP_SEC + 1.0) * 1000.0),
		"a hanging on_exit is cut off at the cap (%d ms)" % elapsed
	)
	_expect(not _router.last_exit_was_awaited(), "router reports the capped hook")


func _test_diary_instance_is_reused() -> void:
	_router.swap(DiaryScene, Callable(), {"cache": true})
	await _wait_idle()
	var diary: Control = _router.get_current_screen()
	var desk_id: int = diary.get_desk_stage().get_instance_id()
	var viewports := diary.find_children("*", "SubViewport", true, false)
	_expect(not viewports.is_empty(), "diary hosts SubViewports")
	var modes_before := {}
	for viewport in viewports:
		modes_before[viewport.get_instance_id()] = viewport.render_target_update_mode
	_router.swap(_probe_scene)
	await _wait_idle()
	_expect(is_instance_valid(diary) and not diary.is_inside_tree(), "diary is detached, not freed")
	var all_frozen := true
	for viewport in viewports:
		if viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED:
			all_frozen = false
	_expect(all_frozen, "detached diary SubViewports stop updating")
	_router.swap(DiaryScene, Callable(), {"cache": true})
	await _wait_idle()
	var again: Control = _router.get_current_screen()
	_expect(again == diary, "diary instance is reused")
	_expect(again.get_desk_stage().get_instance_id() == desk_id, "desk stage is not rebuilt")
	var restored := true
	var dump := []
	for viewport in viewports:
		dump.append("%s:%d->%d" % [viewport.name, modes_before[viewport.get_instance_id()], viewport.render_target_update_mode])
		if viewport.render_target_update_mode != modes_before[viewport.get_instance_id()]:
			restored = false
	_expect(restored, "SubViewport update modes are restored on return %s" % str(dump))
	_router.clear_cache()
	_router.swap(_probe_scene)
	await _wait_idle()
	await get_tree().process_frame
	_expect(not is_instance_valid(diary), "clearing the cache frees the diary once it leaves")


func _test_sfx_outlive_the_screen() -> void:
	var was_muted := TableSfx.is_muted()
	TableSfx.set_muted(false)
	var screen: Control = _router.get_current_screen()
	var host: Node = _router.get_sfx_host()
	var players_before := host.get_child_count()
	TableSfx.play(screen, TableSfx.KIND_SEAL)
	_expect(host.get_child_count() == players_before + 1, "table SFX player is hosted by the router")
	_expect(
		screen.find_children("TableSfxPlayer*", "AudioStreamPlayer", true, false).is_empty(),
		"table SFX player is not parented to the screen"
	)
	_router.swap(_probe_scene)
	await _wait_idle()
	_expect(host.get_child_count() >= players_before, "SFX survives the screen swap")
	TableSfx.set_muted(was_muted)


func _test_back_target_table() -> void:
	var targets: Dictionary = AppControllerScript.BACK_TARGETS
	var expected := {
		&"route_select": [&"hub", &"hub"],
		&"map": [&"hub", &"hub"],
		&"reward": [&"hub", &"hub"],
		&"rest": [&"map", &"map"],
		&"battle": [&"map", &"map"],
		&"deck": [&"hub", &"challenge_hub"],
		&"route_result": [&"hub", &"hub"],
		&"challenge_select": [&"challenge_hub", &"challenge_hub"],
		&"challenge_result": [&"challenge_hub", &"challenge_hub"],
		&"challenge_hub": [&"start", &"start"],
		&"hub": [&"start", &"start"],
	}
	for route_name in expected:
		_expect(
			targets.has(route_name) and targets[route_name] == expected[route_name],
			"back target for %s is %s" % [route_name, str(expected[route_name])]
		)
	var controller = AppControllerScript.new()
	for route_name in targets:
		_expect(
			controller.get_back_target(route_name) == &"start",
			"without a session %s backs to the title" % route_name
		)
	controller.free()


func _make_probe_scene() -> PackedScene:
	var script := GDScript.new()
	script.source_code = PROBE_SOURCE
	script.reload()
	var node := Control.new()
	node.set_script(script)
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	return scene


func _click(position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = position
		event.global_position = position
		get_viewport().push_input(event, true)


func _wait_idle(timeout_sec: float = 4.0) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	await get_tree().process_frame
	while _router.is_busy() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(message)
