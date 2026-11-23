extends Node

## v0.78: seeded main-path button monkey over AppRoot + test profile.

const AppRootScene := preload("res://src/app/app_root.tscn")
const PreferencesServiceScript := preload(
	"res://src/infrastructure/player_preferences_service.gd"
)

const TEST_ROOT := "res://.tools/monkey/userdata"
const TRACE_DIR := "res://.tools/monkey"
const PRIMARY_SEED := 20261122
const STEP_BUDGET := 100
const FRAMES_AFTER_CLICK := 3
const MAX_STALLS := 5

## Soft-deprioritized: only chosen when nothing else is clickable.
const DESTRUCTIVE_LABELS := {
	"重新开始": true,
	"回到主菜单": true,
	"退出战斗": true,
	"退出": true,
	"关闭游戏": true,
}

## Deck/filter chrome floods the pool; keep as fallback only.
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
}

## Prefer these when present so the monkey reaches diary/battle.
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
	"测试档案": true,
	"选择此路线": true,
	"扮演此身份": true,
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
	var seeds: Array[int] = [PRIMARY_SEED, 77801, 77802]
	for seed_value in seeds:
		await _run_seed(seed_value)
		if not _failures.is_empty():
			break
	if not _routes_seen.has("map") and not _routes_seen.has("battle"):
		_failures.append("coverage gap: never reached map/battle routes=%s" % str(_routes_seen.keys()))
	_write_trace_file()
	if _failures.is_empty():
		print(
			"V078_MONKEY_OK seeds=%s actions=%d routes=%s"
			% [str(seeds), _actions, str(_routes_seen.keys())]
		)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V078_MONKEY_FAIL: %s" % failure)
	print("V078_MONKEY_FAIL actions=%d trace_tail=%s" % [_actions, str(_trace.slice(maxi(0, _trace.size() - 12)))])
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
	var boot_route := String(_controller.get_current_route())
	if boot_route != "map" and boot_route != "hub":
		## Fall back to a deterministic new-game path if test profile failed.
		_trace.append("%d:0 boot_route=%s fallback_new_game" % [seed_value, boot_route])
		for label in ["下一步", "开始新游戏", "选择此路线", "扮演此身份", "确认出战", "打开日记"]:
			var button := _button_by_text(_controller, label)
			if button != null and _is_clickable(button):
				_press(button, "%d:0 fallback=%s" % [seed_value, label])
				await _wait_frames(4)
		_note_route(seed_value, 0)

	for step in range(1, STEP_BUDGET + 1):
		if not is_instance_valid(_controller):
			_failures.append("seed=%d step=%d controller freed" % [seed_value, step])
			return
		var route := String(_controller.get_current_route())
		if not KNOWN_ROUTES.has(route):
			_failures.append("seed=%d step=%d illegal route=%s" % [seed_value, step, route])
			return
		_routes_seen[route] = int(_routes_seen.get(route, 0)) + 1

		if await _handle_dialogs(seed_value, step):
			_stalls = 0
			continue

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
		## 60% prefer navigation when available; else normal; else noise; else destructive.
		if not nav.is_empty() and _rng.randf() < 0.6:
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
			_trace.append("%d:%d route=%s STALL no-clickables" % [seed_value, step, route])
			if _stalls >= MAX_STALLS:
				_failures.append(
					"seed=%d step=%d stalled on route=%s for %d turns"
					% [seed_value, step, route, _stalls]
				)
				return
			await _wait_frames(2)
			continue

		_stalls = 0
		## Break long same-label streaks (e.g. ClueHit / 结束回合 loops).
		if _same_label_streak >= 4 and pool.size() > 1:
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

	_trace.append("SEED %d DONE actions_budget=%d" % [seed_value, STEP_BUDGET])
	if is_instance_valid(_controller):
		_controller.queue_free()
		await _wait_frames(2)
	_remove_tree(TEST_ROOT)


func _handle_dialogs(seed_value: int, step: int) -> bool:
	var dialogs: Array = []
	_gather_dialogs(_controller, dialogs)
	var acted := false
	for node in dialogs:
		if node == null or not is_instance_valid(node):
			continue
		## Godot 4: dialogs extend Window, not Control.
		if node is ConfirmationDialog:
			var confirm := node as ConfirmationDialog
			if not confirm.visible:
				continue
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
			_trace.append("%d:%d dialog=AcceptDialog ok" % [seed_value, step])
			accept.emit_signal("confirmed")
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
	if button.disabled:
		return false
	if not button.visible:
		return false
	if not button.is_visible_in_tree():
		return false
	if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	## Ignore dialog chrome buttons; dialogs are handled separately.
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
	if step == 0 or step % 20 == 0:
		_trace.append("%d:%d route_now=%s" % [seed_value, step, route])


func _button_by_text(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child in root.get_children():
		var found := _button_by_text(child, text_value)
		if found != null:
			return found
	return null


func _write_trace_file() -> void:
	var path := TRACE_DIR.path_join("v078_monkey_trace.txt")
	var absolute := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		printerr("V078_MONKEY could not write trace %s" % absolute)
		return
	for line in _trace:
		file.store_line(line)
	if not _failures.is_empty():
		file.store_line("--- FAILURES ---")
		for failure in _failures:
			file.store_line(failure)
	file.close()
	print("V078_MONKEY_TRACE %s lines=%d" % [path, _trace.size()])


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
