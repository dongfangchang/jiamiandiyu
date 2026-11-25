extends Node

## station.title (ADR-0034): the only controls are the text items on the
## bookmark slip; desk props are picture; no legacy panel, background holder
## or cover survives. Run windowed with `-- --capture [--capture-size=WxH]`
## to also save frames to .tools/ui-captures/v089_title_*.png.

const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const Paper := preload("res://src/ui/title/title_paper.gd")
const OUTPUT_DIRECTORY := "res://.tools/ui-captures"
const MENU_ALLOWED := ["继续", "新的日记", "挑战", "设置", "离开", "测试档案"]
const LEGACY_NAMES := ["Cover", "SceneBackgroundHolder", "SceneDim", "SceneFallback"]

var _checks := 0
var _failures: Array[String] = []
var _capture := false
var _suffix := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_capture = "--capture" in args and DisplayServer.get_name() != "headless"
	if _capture:
		var size := Vector2i(1600, 900)
		for arg in args:
			if String(arg).begins_with("--capture-size="):
				var parts := String(arg).trim_prefix("--capture-size=").split("x")
				size = Vector2i(int(parts[0]), int(parts[1]))
		_suffix = "_%dx%d" % [size.x, size.y]
		DisplayServer.window_set_size(size)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
		await get_tree().create_timer(0.4).timeout

	var screen: Control = StartScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame

	_check_no_legacy(screen)
	_check_buttons_are_text(screen, MENU_ALLOWED, "empty title")
	_check_props_inert(screen)
	var empty_menu: PackedStringArray = screen.get_menu_texts()
	_expect(not empty_menu.has("继续"), "no checkpoint: 继续 is not listed")
	_expect(empty_menu.has("挑战"), "no checkpoint: 挑战 stays listed (grey)")
	_expect(empty_menu.has("新的日记") and empty_menu.has("设置") and empty_menu.has("离开"),
		"no checkpoint: 新的日记 / 设置 / 离开 listed (%s)" % str(empty_menu))
	_expect(screen.get_summary_text() == "尚无日记", "no checkpoint summary reads 尚无日记")
	_expect(_label_uses_serif(screen.find_child("SaveSummary", true, false) as Label),
		"save summary is set in Source Han Serif")
	_check_challenge_locked(screen, "完成序列 8")

	screen.show_checkpoint_status("loaded", {
		"sequence": 9,
		"identity_id": "identity.reporter",
		"created_at": "2026-11-08T02:30:00Z",
		"challenge_available": false,
		"challenge_reason": "完成序列 8 晋升后开放",
		"backup_available": true,
	})
	await get_tree().process_frame
	_expect(screen.get_menu_texts().has("挑战"), "locked loaded: 挑战 stays listed")
	_check_challenge_locked(screen, "序列 8")
	_expect(not screen.is_challenge_enabled(), "locked loaded: challenge not enabled")

	screen.show_checkpoint_status("loaded", {
		"sequence": 9,
		"identity_id": "identity.reporter",
		"created_at": "2026-11-08T02:30:00Z",
		"challenge_available": true,
		"backup_available": true,
	})
	await get_tree().process_frame
	var menu: PackedStringArray = screen.get_menu_texts()
	_expect(menu.size() >= 5 and menu[0] == "继续" and menu[1] == "新的日记" and menu[2] == "挑战",
		"loaded menu reads 继续 / 新的日记 / 挑战 … (%s)" % str(menu))
	_expect(screen.get_summary_text().contains("记者 · 序列 9"), "summary names identity and sequence")
	_expect(screen.get_summary_text().contains("保存于 2026-11-08 02:30"), "summary names saved-at")
	_check_buttons_are_text(screen, MENU_ALLOWED, "loaded title")
	var unlocked := _item(screen, "挑战")
	_expect(unlocked != null and not unlocked.disabled, "unlocked 挑战 is enabled")
	_expect(unlocked.focus_mode == Control.FOCUS_ALL, "unlocked 挑战 can focus")
	var unlocked_hint := screen.find_child("ChallengeHint", true, false) as Label
	_expect(unlocked_hint != null and not unlocked_hint.visible, "unlocked hides challenge hint")
	await _snap("v089_title_rest")

	var desk: Control = screen.get_desk()
	if _capture:
		## A real cursor resting on an item would keep its prop lit.
		get_viewport().warp_mouse(Vector2(4, 4))
		await get_tree().process_frame
	var cont := _item(screen, "继续")
	cont.grab_focus()
	await get_tree().create_timer(0.25).timeout
	_expect(desk.is_lit("book"), "focusing 继续 lights the book")
	_expect(not desk.is_lit("candle"), "focusing 继续 leaves the candle")
	await _snap("v089_title_focus_continue")
	_item(screen, "离开").grab_focus()
	await get_tree().create_timer(0.25).timeout
	_expect(desk.is_lit("candle") and not desk.is_lit("book"), "focusing 离开 moves the light to the candle")
	_item(screen, "挑战").grab_focus()
	await get_tree().create_timer(0.25).timeout
	_expect(desk.is_lit("folder"), "focusing 挑战 lights the folder")
	cont.grab_focus()
	await get_tree().create_timer(0.25).timeout

	_item(screen, "设置").pressed.emit()
	await get_tree().process_frame
	_expect(screen.is_settings_open(), "设置 opens the settings slip")
	var restore := _item(screen, "恢复上次备份")
	_expect(restore != null and not restore.disabled, "settings slip carries 恢复上次备份")
	_check_buttons_are_text(screen, [], "settings open")
	await _snap("v089_title_settings")
	screen.close_settings()
	await get_tree().process_frame
	_expect(not screen.is_settings_open(), "settings slip closes")
	_expect(_item(screen, "恢复上次备份") == null, "closed settings leave no buttons behind")

	_item(screen, "新的日记").pressed.emit()
	await get_tree().process_frame
	_expect(screen.is_confirm_open(), "新的日记 over a save asks for confirmation on a slip")
	_check_buttons_are_text(screen, [], "confirm open")
	_item(screen, "取消").pressed.emit()
	await get_tree().process_frame
	_expect(not screen.is_confirm_open(), "取消 closes the confirmation")

	## Open beat: the book is pushed in, nothing fades, nothing covers.
	var book: Control = desk.prop("book")
	_expect(bool(desk.play_open("continue")), "open beat starts")
	var min_alpha := 1.0
	var frames := 0
	while desk.is_opening() and frames < 300:
		await get_tree().process_frame
		frames += 1
		min_alpha = minf(min_alpha, minf(desk.modulate.a, screen.modulate.a))
		if frames == 12:
			await _snap("v089_title_open_mid")
	_expect(not desk.is_opening(), "open beat finishes (%d frames)" % frames)
	_expect(book.scale.x > 1.05, "the book is pushed toward the viewer")
	_expect(min_alpha >= 0.999, "desk never fades (min alpha %.3f)" % min_alpha)
	_check_no_legacy(screen)
	screen.set_busy(false)
	_expect(book.scale == Vector2.ONE, "returning to the title resets the book")

	screen.show_checkpoint_status("corrupt", {"backup_available": true}, "checksum mismatch")
	await get_tree().process_frame
	_expect(not screen.get_menu_texts().has("继续"), "corrupt checkpoint does not list 继续")
	_expect(screen.get_status_text() == "日记无法读取", "corrupt checkpoint is stated on the slip")
	_expect(screen.get_summary_text().contains("原始存档已保留"), "corrupt summary explains the safe state")
	_finish()


func _item(root: Node, text_value: String) -> Button:
	for node in root.find_children("*", "BaseButton", true, false):
		var button := node as Button
		if button != null and button.text == text_value and button.is_visible_in_tree():
			return button
	return null


func _check_challenge_locked(screen: Control, reason_fragment: String) -> void:
	var challenge := _item(screen, "挑战")
	_expect(challenge != null and challenge.visible, "locked: 挑战 visible")
	_expect(challenge != null and challenge.disabled, "locked: 挑战 disabled")
	_expect(
		challenge != null and challenge.focus_mode == Control.FOCUS_NONE,
		"locked: 挑战 cannot focus"
	)
	var hint_text := String(screen.get_challenge_hint_text())
	_expect(not hint_text.strip_edges().is_empty(), "locked: get_challenge_hint_text non-empty")
	_expect(hint_text.contains(reason_fragment), "locked: hint mentions %s" % reason_fragment)
	var hint := screen.find_child("ChallengeHint", true, false) as Label
	_expect(hint != null and hint.visible, "locked: ChallengeHint visible")
	_expect(hint != null and hint.text == hint_text, "locked: ChallengeHint shows snapshot reason")
	_expect(_label_uses_serif(hint), "locked: ChallengeHint is Source Han Serif")
	_expect(
		hint != null and hint.get_theme_font_size("font_size") < 28,
		"locked: ChallengeHint is smaller than menu"
	)


func _check_no_legacy(screen: Control) -> void:
	for node in screen.find_children("*", "", true, false):
		for legacy in LEGACY_NAMES:
			if String(node.name).contains(legacy):
				_expect(false, "legacy node %s survives" % node.get_path())
	_checks += 1


func _check_buttons_are_text(screen: Control, menu_allowed: Array, label: String) -> void:
	## Every BaseButton is a text item; outside an open slip it must be a menu entry.
	var sheet_open: bool = screen.is_settings_open() or screen.is_confirm_open() or screen.is_tutorial_open()
	for node in screen.find_children("*", "BaseButton", true, false):
		var button := node as Button
		_expect(button != null and bool(button.get_meta(Paper.META_TEXT_ITEM, false)),
			"%s: %s is a text item" % [label, node.name])
		if button == null:
			continue
		_expect(not button.text.strip_edges().is_empty(), "%s: %s has readable text" % [label, node.name])
		_expect(button.icon == null, "%s: %s carries no icon" % [label, node.name])
		if not sheet_open:
			_expect(menu_allowed.has(button.text), "%s: %s is a menu entry" % [label, button.text])


func _check_props_inert(screen: Control) -> void:
	var desk: Control = screen.get_desk()
	_expect(desk != null and desk.mouse_filter == Control.MOUSE_FILTER_IGNORE, "desk ignores the mouse")
	_expect(desk.prop_keys().size() == 3, "desk shows book, folder and candle")
	for node in desk.find_children("*", "Control", true, false):
		_expect((node as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"prop %s ignores the mouse" % node.name)
	_expect(desk.find_children("*", "BaseButton", true, false).is_empty(), "desk holds no buttons")


func _label_uses_serif(label: Label) -> bool:
	if label == null:
		return false
	var font := label.get_theme_font("font")
	if font is FontVariation:
		font = (font as FontVariation).base_font
	return font != null and font.resource_path.contains("SourceHanSerif")


func _snap(file_name: String) -> void:
	if not _capture:
		return
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(
		"%s/%s%s.png" % [OUTPUT_DIRECTORY, file_name, _suffix]
	))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_STATION_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("TITLE_STATION_FAIL: %s" % failure)
	print("TITLE_STATION_FAIL checks=%d" % _checks)
	get_tree().quit(1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
