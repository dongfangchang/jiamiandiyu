extends Node

## v0.79: seeded button monkey + forced rest/ritual/reward/challenge coverage.

const AppRootScene := preload("res://src/app/app_root.tscn")
const PreferencesServiceScript := preload(
	"res://src/infrastructure/player_preferences_service.gd"
)
const RouteCommandScript := preload("res://src/core/route_command.gd")

const TEST_ROOT := "res://.tools/monkey/userdata_v079"
const TRACE_DIR := "res://.tools/monkey"
const PRIMARY_SEED := 20261122
const STEP_BUDGET := 80
const FORCE_BURST := 12
const FRAMES_AFTER_CLICK := 3
const MAX_STALLS := 5

const DESTRUCTIVE_LABELS := {
	"重新开始": true,
	"回到主菜单": true,
	"退出战斗": true,
	"退出": true,
	"关闭游戏": true,
}

const NOISE_LABELS := {
	"全部": true,
	"已拥有": true,
	"未拥有": true,
	"牌组内": true,
	"加入牌组": true,
	"移出牌组": true,
	"移出": true,
	"清空": true,
	"覆盖": true,
	"载入此组": true,
	"详情": true,
	"选择手牌": true,
	"已选择": true,
	"拖放/点选": true,
}

const NAV_LABELS := {
	"打开日记": true,
	"合上": true,
	"回日记": true,
	"调查线索": true,
	"‹ 前一页": true,
	"后一页 ›": true,
	"页边": true,
	"进行灵界祈愿": true,
	"整理卡牌与残页": true,
	"调整出战牌组": true,
	"单抽": true,
	"确认出战": true,
	"结束回合": true,
	"打出所选牌": true,
	"测试档案": true,
	"选择此路线": true,
	"扮演此身份": true,
	"执行休整": true,
	"收下这份记录": true,
	"提交本步骤": true,
	"获取仪式提示": true,
	"退出仪式": true,
	"进入挑战档案": true,
}

const KNOWN_ROUTES := {
	"start": true,
	"challenge_hub": true,
	"challenge_select": true,
	"challenge_result": true,
	"deck": true,
	"identity": true,
	"hub": true,
	"map": true,
	"route_select": true,
	"rest": true,
	"battle": true,
	"reward": true,
	"gacha": true,
	"upgrade": true,
	"ritual": true,
	"route_result": true,
}

const REQUIRED_ROUTES := [
	"map",
	"battle",
	"hub",
	"rest",
	"ritual",
	"reward",
	"challenge_hub",
]

var _controller: Control
var _rng := RandomNumberGenerator.new()
var _trace: Array[String] = []
var _failures: Array[String] = []
var _actions := 0
var _stalls := 0
var _routes_seen: Dictionary = {}
var _last_label := ""
var _same_label_streak := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TRACE_DIR))
	var seeds: Array[int] = [
		PRIMARY_SEED,
		77901,
		77902,
		77903,
		77911,
		77921,
		78001,
		78101,
	]
	for seed_value in seeds:
		await _run_seed(seed_value)
		if not _failures.is_empty():
			break
	for route_name in REQUIRED_ROUTES:
		if not _routes_seen.has(route_name):
			_failures.append("coverage gap: missing required route=%s seen=%s" % [
				route_name,
				str(_routes_seen.keys()),
			])
	_write_trace_file()
	if _failures.is_empty():
		print(
			"V079_MONKEY_OK seeds=%s actions=%d routes=%s"
			% [str(seeds), _actions, str(_routes_seen.keys())]
		)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V079_MONKEY_FAIL: %s" % failure)
	print(
		"V079_MONKEY_FAIL actions=%d trace_tail=%s"
		% [_actions, str(_trace.slice(maxi(0, _trace.size() - 16)))]
	)
	get_tree().quit(1)


func _run_seed(seed_value: int) -> void:
	_trace.append("SEED %d" % seed_value)
	_rng.seed = seed_value
	_stalls = 0
	_last_label = ""
	_same_label_streak = 0
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

	if is_instance_valid(_controller):
		_controller.queue_free()
		await _wait_frames(2)
	_controller = AppRootScene.instantiate()
	_controller.configure_for_testing(
		TEST_ROOT.path_join("saves"),
		"monkey_checkpoint",
		seed_value,
		preferences_path,
		TEST_ROOT.path_join("diagnostics")
	)
	add_child(_controller)
	await _wait_frames(4)

	var boot := _button_by_text(_controller, "测试档案")
	if boot == null:
		_failures.append("seed=%d missing 测试档案" % seed_value)
		return
	_press(boot, "boot:测试档案")
	await _wait_frames(6)
	_note_route(seed_value, 0)
	if String(_controller.get_current_route()) not in ["map", "hub"]:
		_trace.append("%d:0 boot_fallback_new_game" % seed_value)
		for label in ["下一步", "开始新游戏", "选择此路线", "扮演此身份", "确认出战", "打开日记"]:
			var button := _button_by_text(_controller, label)
			if button != null and _is_clickable(button):
				_press(button, "%d:0 fallback=%s" % [seed_value, label])
				await _wait_frames(4)
		_note_route(seed_value, 0)

	## Forced coverage tour before free monkey.
	await _force_coverage_tour(seed_value)

	for step in range(1, STEP_BUDGET + 1):
		if not await _monkey_step(seed_value, step):
			return

	_trace.append("SEED %d DONE" % seed_value)
	if is_instance_valid(_controller):
		_controller.queue_free()
		await _wait_frames(2)
	_remove_tree(TEST_ROOT)


func _force_coverage_tour(seed_value: int) -> void:
	_trace.append("%d:FORCE begin" % seed_value)

	## 1) Battle via available clue / select_node, then brief monkey.
	await _ensure_map(seed_value)
	await _try_enter_battle(seed_value)
	await _monkey_burst(seed_value, "battle_burst", FORCE_BURST)

	## 2) Rest / ritual / reward screens (controlled entry; session must exist).
	await _ensure_session_route_screens(seed_value)

	## 3) Challenge hub (+ select if a card is clickable).
	await _force_challenge(seed_value)

	## 4) Return to test map for free monkey.
	await _return_to_test_map(seed_value)
	_trace.append("%d:FORCE end routes=%s" % [seed_value, str(_routes_seen.keys())])


func _ensure_map(seed_value: int) -> void:
	var route := String(_controller.get_current_route())
	if route == "map":
		return
	if route == "hub":
		var open_diary := _button_by_text(_controller, "打开日记")
		if open_diary != null:
			_press(open_diary, "%d:FORCE open_diary" % seed_value)
			await _wait_frames(4)
			_note_route(seed_value, -1)
			return
	var boot := _button_by_text(_controller, "测试档案")
	if boot != null:
		_press(boot, "%d:FORCE retest" % seed_value)
		await _wait_frames(6)
		_note_route(seed_value, -1)


func _try_enter_battle(seed_value: int) -> void:
	var clue := _first_named_button(_controller, "ClueHit")
	if clue != null and _is_clickable(clue):
		_press(clue, "%d:FORCE ClueHit" % seed_value)
		await _wait_frames(5)
		_note_route(seed_value, -1)
		return
	var session = _controller.get_session()
	if session == null:
		return
	var snap: Dictionary = session.get_route_snapshot().data
	var node_id := StringName(snap.get("available_node_id", ""))
	if node_id.is_empty():
		return
	_controller._on_route_command_requested(RouteCommandScript.select_node(node_id))
	_trace.append("%d:FORCE select_node=%s" % [seed_value, String(node_id)])
	await _wait_frames(5)
	_note_route(seed_value, -1)


func _ensure_session_route_screens(seed_value: int) -> void:
	if not await _ensure_live_session(seed_value):
		_trace.append("%d:FORCE skip rest/ritual/reward (no session)" % seed_value)
		return

	## Prefer real node select when on map; else controlled screen entry.
	await _ensure_map(seed_value)
	await _try_select_node_type(seed_value, "rest")
	if String(_controller.get_current_route()) != "rest":
		if _controller.get_session() != null:
			_controller._show_rest_screen()
			_trace.append("%d:FORCE _show_rest_screen" % seed_value)
			await _wait_frames(4)
			_note_route(seed_value, -1)
	await _monkey_burst(seed_value, "rest_burst", FORCE_BURST)

	if not await _ensure_live_session(seed_value):
		return
	await _ensure_map(seed_value)
	await _try_select_node_type(seed_value, "ritual")
	if String(_controller.get_current_route()) != "ritual":
		if _controller.get_session() != null:
			_controller._on_route_command_requested(RouteCommandScript.begin_ascension())
			await _wait_frames(3)
		if String(_controller.get_current_route()) != "ritual":
			if _controller.get_session() != null:
				_controller._show_ritual_screen()
				_trace.append("%d:FORCE _show_ritual_screen" % seed_value)
			else:
				_trace.append("%d:FORCE skip ritual (no session)" % seed_value)
		else:
			_trace.append("%d:FORCE begin_ascension" % seed_value)
		await _wait_frames(4)
		_note_route(seed_value, -1)
	await _monkey_burst(seed_value, "ritual_burst", FORCE_BURST)

	if not await _ensure_live_session(seed_value):
		return
	_controller._show_reward()
	_trace.append("%d:FORCE _show_reward" % seed_value)
	await _wait_frames(4)
	_note_route(seed_value, -1)
	await _monkey_burst(seed_value, "reward_burst", FORCE_BURST)

	## Hub satellites.
	if not await _ensure_live_session(seed_value):
		return
	_controller._show_hub()
	await _wait_frames(3)
	_note_route(seed_value, -1)
	var gacha := _button_by_text(_controller, "进行灵界祈愿")
	if gacha != null and _is_clickable(gacha):
		_press(gacha, "%d:FORCE gacha" % seed_value)
		await _wait_frames(4)
		_note_route(seed_value, -1)
		await _monkey_burst(seed_value, "gacha_burst", 8)


func _ensure_live_session(seed_value: int) -> bool:
	if _controller.get_session() != null:
		return true
	_trace.append("%d:FORCE session lost → retest" % seed_value)
	await _return_to_test_map(seed_value)
	return _controller.get_session() != null


func _try_select_node_type(seed_value: int, node_type: String) -> void:
	var session = _controller.get_session()
	if session == null:
		return
	## Never send route commands while battle screen is mounted.
	if String(_controller.get_current_route()) != "map":
		_trace.append(
			"%d:FORCE skip select_%s (route=%s)"
			% [seed_value, node_type, String(_controller.get_current_route())]
		)
		return
	var snap: Dictionary = session.get_route_snapshot().data
	for value in snap.get("nodes", []):
		if not (value is Dictionary):
			continue
		var node: Dictionary = value
		if String(node.get("type", "")) != node_type:
			continue
		var node_id := String(node.get("id", ""))
		if node_id.is_empty():
			continue
		_controller._on_route_command_requested(
			RouteCommandScript.select_node(StringName(node_id))
		)
		_trace.append("%d:FORCE select_%s=%s" % [seed_value, node_type, node_id])
		await _wait_frames(5)
		_note_route(seed_value, -1)
		if String(_controller.get_current_route()) in [node_type, "ritual", "rest"]:
			return


func _force_challenge(seed_value: int) -> void:
	_controller.show_start_screen()
	await _wait_frames(4)
	_note_route(seed_value, -1)
	var challenge := _button_by_text(_controller, "进入挑战档案")
	if challenge == null:
		_trace.append("%d:FORCE missing 进入挑战档案" % seed_value)
		return
	_press(challenge, "%d:FORCE 进入挑战档案" % seed_value)
	await _wait_frames(5)
	_note_route(seed_value, -1)
	await _monkey_burst(seed_value, "challenge_burst", FORCE_BURST + 4)


func _return_to_test_map(seed_value: int) -> void:
	var route := String(_controller.get_current_route())
	if route != "start":
		## Prefer hub→start destructive only if needed.
		var back := _button_by_text(_controller, "回日记")
		if back == null:
			back = _button_by_text(_controller, "合上")
		if back != null and _is_clickable(back):
			_press(back, "%d:FORCE back=%s" % [seed_value, _button_label(back)])
			await _wait_frames(4)
		var menu := _button_by_text(_controller, "回到主菜单")
		if menu != null and _is_clickable(menu):
			_press(menu, "%d:FORCE 回到主菜单" % seed_value)
			await _wait_frames(4)
			await _handle_dialogs(seed_value, -2)
	var boot := _button_by_text(_controller, "测试档案")
	if boot != null:
		_press(boot, "%d:FORCE return_test" % seed_value)
		await _wait_frames(6)
		_note_route(seed_value, -1)


func _monkey_burst(seed_value: int, tag: String, steps: int) -> void:
	_trace.append("%d:BURST %s x%d" % [seed_value, tag, steps])
	for i in range(steps):
		if not await _monkey_step(seed_value, -100 - i):
			return


func _monkey_step(seed_value: int, step: int) -> bool:
	if not is_instance_valid(_controller):
		_failures.append("seed=%d step=%d controller freed" % [seed_value, step])
		return false
	var route := String(_controller.get_current_route())
	if not KNOWN_ROUTES.has(route):
		_failures.append("seed=%d step=%d illegal route=%s" % [seed_value, step, route])
		return false
	_routes_seen[route] = int(_routes_seen.get(route, 0)) + 1

	if await _handle_dialogs(seed_value, step):
		_stalls = 0
		return true

	var candidates := _collect_clickables(_controller)
	var nav: Array[Button] = []
	var normal: Array[Button] = []
	var noise: Array[Button] = []
	var destructive: Array[Button] = []
	for button in candidates:
		var label := _button_label(button)
		if DESTRUCTIVE_LABELS.has(label):
			destructive.append(button)
		elif NAV_LABELS.has(label) or String(button.name) == "ClueHit":
			nav.append(button)
		elif NOISE_LABELS.has(label):
			noise.append(button)
		else:
			normal.append(button)
	var pool: Array[Button] = []
	if not nav.is_empty() and _rng.randf() < 0.65:
		pool = nav
	elif not normal.is_empty():
		pool = normal
	elif not nav.is_empty():
		pool = nav
	elif not noise.is_empty():
		pool = noise
	else:
		pool = destructive
	if pool.is_empty():
		_stalls += 1
		_trace.append("%d:%d route=%s STALL" % [seed_value, step, route])
		## Force-tour bursts use negative steps; soft-skip empty screens.
		if step < 0:
			await _wait_frames(1)
			return true
		if _stalls >= MAX_STALLS:
			_failures.append(
				"seed=%d step=%d stalled on route=%s" % [seed_value, step, route]
			)
			return false
		await _wait_frames(2)
		return true

	_stalls = 0
	if _same_label_streak >= 3 and pool.size() > 1:
		var filtered: Array[Button] = []
		for button in pool:
			if _button_label(button) != _last_label:
				filtered.append(button)
		if not filtered.is_empty():
			pool = filtered
	var pick: Button = pool[_rng.randi_range(0, pool.size() - 1)]
	var pick_label := _button_label(pick)
	if pick_label == _last_label:
		_same_label_streak += 1
	else:
		_last_label = pick_label
		_same_label_streak = 1
	_press(pick, "%d:%d route=%s click=%s" % [seed_value, step, route, pick_label])
	await _wait_frames(FRAMES_AFTER_CLICK)
	_note_route(seed_value, step)
	return true


func _handle_dialogs(seed_value: int, step: int) -> bool:
	var dialogs: Array = []
	_gather_dialogs(_controller, dialogs)
	var acted := false
	for node in dialogs:
		if node == null or not is_instance_valid(node):
			continue
		## Godot 4: AcceptDialog/ConfirmationDialog extend Window, not Control.
		if node is ConfirmationDialog:
			var confirm := node as ConfirmationDialog
			if not confirm.visible:
				continue
			## Prefer confirm so exit/new-game dialogs do not soft-lock the monkey.
			var confirm_it := _rng.randf() < 0.85
			_trace.append(
				"%d:%d dialog=ConfirmationDialog %s"
				% [seed_value, step, "confirm" if confirm_it else "cancel"]
			)
			if confirm_it:
				confirm.emit_signal("confirmed")
			else:
				confirm.emit_signal("canceled")
			acted = true
			await _wait_frames(FRAMES_AFTER_CLICK)
		elif node is AcceptDialog:
			var accept := node as AcceptDialog
			if not accept.visible:
				continue
			accept.emit_signal("confirmed")
			_trace.append("%d:%d dialog=AcceptDialog ok" % [seed_value, step])
			acted = true
			await _wait_frames(FRAMES_AFTER_CLICK)
	return acted


func _gather_dialogs(node: Node, out: Array) -> void:
	if node is ConfirmationDialog or node is AcceptDialog:
		out.append(node)
	for child in node.get_children():
		_gather_dialogs(child, out)


func _collect_clickables(root: Node) -> Array[Button]:
	var found: Array[Button] = []
	_gather_buttons(root, found)
	return found


func _gather_buttons(node: Node, out: Array[Button]) -> void:
	if node is Button:
		var button := node as Button
		if _is_clickable(button):
			out.append(button)
	for child in node.get_children():
		_gather_buttons(child, out)


func _is_clickable(button: Button) -> bool:
	if not is_instance_valid(button):
		return false
	if button.disabled or not button.visible or not button.is_visible_in_tree():
		return false
	if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	var parent := button.get_parent()
	while parent != null:
		if parent is AcceptDialog or parent is ConfirmationDialog:
			return false
		parent = parent.get_parent()
	return true


func _button_label(button: Button) -> String:
	var text := String(button.text).strip_edges()
	if not text.is_empty():
		return text
	return String(button.name)


func _press(button: Button, trace_line: String) -> void:
	_actions += 1
	_trace.append(trace_line)
	if is_instance_valid(button) and not button.disabled:
		button.pressed.emit()


func _note_route(seed_value: int, step: int) -> void:
	if not is_instance_valid(_controller):
		return
	var route := String(_controller.get_current_route())
	_routes_seen[route] = int(_routes_seen.get(route, 0)) + 1
	if step == 0 or step % 20 == 0 or step < 0:
		_trace.append("%d:%d route_now=%s" % [seed_value, step, route])


func _button_by_text(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child in root.get_children():
		var found := _button_by_text(child, text_value)
		if found != null:
			return found
	return null


func _first_named_button(root: Node, button_name: String) -> Button:
	var node := root.find_child(button_name, true, false)
	if node is Button:
		return node as Button
	return null


func _write_trace_file() -> void:
	var path := TRACE_DIR.path_join("v079_monkey_trace.txt")
	var absolute := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		printerr("V079_MONKEY could not write trace %s" % absolute)
		return
	for line in _trace:
		file.store_line(line)
	if not _failures.is_empty():
		file.store_line("--- FAILURES ---")
		for failure in _failures:
			file.store_line(failure)
	file.close()
	print("V079_MONKEY_TRACE %s lines=%d" % [path, _trace.size()])


func _wait_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


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
