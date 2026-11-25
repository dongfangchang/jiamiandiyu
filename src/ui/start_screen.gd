extends Control

## station.title (ADR-0034): the shut diary on the desk, and a bookmark slip
## carrying the save summary and a TEXT menu. The text items are the only
## controls; the desk props are picture and only light up when an item is
## hovered or focused.

signal new_game_requested
signal continue_requested
signal challenge_requested
signal preferences_changed(preferences: Dictionary)
signal restore_backup_requested
signal feedback_submitted(feedback: Dictionary)
signal test_game_requested
signal quit_requested

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const TitleDeskStage := preload("res://src/ui/title_desk_stage.gd")
const Paper := preload("res://src/ui/title/title_paper.gd")
const TitleSheets := preload("res://src/ui/title/title_sheets.gd")

const MENU_TEXT := {
	"continue": "继续",
	"new_game": "新的日记",
	"challenge": "挑战",
	"settings": "设置",
	"quit": "离开",
	"test_game": "测试档案",
}
## Slip rect in the 1600x900 design space, tucked against the book's edge.
const SLIP_RECT := Rect2(930, 96, 470, 700)

var _desk: Control
var _slip: Control
var _items: Dictionary = {}
var _status_label: Label
var _detail_label: Label
var _notice_label: Label
var _version_label: Label
var _sheets: RefCounted
var _preferences: Dictionary = {}
var _preferences_initialized := false
var _backup_available := false
var _busy := false
var _open_key := ""
var _checkpoint_status := "none"
var _challenge_available := false
var _challenge_hint := ""
var _challenge_hint_label: Label


func _ready() -> void:
	theme = UiTheme.build_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desk = TitleDeskStage.new()
	add_child(_desk)
	_build_slip()
	_sheets = TitleSheets.new(self)
	show_checkpoint_status("none")


func show_checkpoint_status(
	status: String,
	summary: Dictionary = {},
	error_message: String = "",
	preferences: Dictionary = {}
) -> void:
	_checkpoint_status = status
	_backup_available = bool(summary.get("backup_available", false))
	if not preferences.is_empty():
		_preferences = preferences.duplicate(true)
		_preferences_initialized = true
	if not is_instance_valid(_status_label):
		return
	_busy = false
	match status:
		"loaded":
			set_challenge_available(
				bool(summary.get("challenge_available", false)),
				String(summary.get("challenge_reason", ""))
			)
			_status_label.text = "%s · 序列 %d" % [
				_identity_name(String(summary.get("identity_id", ""))),
				int(summary.get("sequence", 0)),
			]
			_detail_label.text = _saved_at_text(String(summary.get("created_at", "")))
		"corrupt":
			set_challenge_available(false, "检查点不可读取")
			_status_label.text = "日记无法读取"
			_detail_label.text = "原始存档已保留。" + (
				"\n" + error_message if not error_message.is_empty() else ""
			)
		_:
			set_challenge_available(false, "完成序列 8 晋升后开放")
			_status_label.text = "尚无日记"
			_detail_label.text = ""
	_detail_label.visible = not _detail_label.text.is_empty()
	_refresh_items()
	if _sheets != null:
		_sheets.set_backup_available(_backup_available and not _busy)
	if (
		_preferences_initialized
		and not bool(_preferences.get("tutorial_seen", false))
		and not _sheets.is_tutorial_open()
	):
		_sheets.open_tutorial()


func get_summary_text() -> String:
	if not is_instance_valid(_status_label):
		return ""
	return (_status_label.text + "\n" + _detail_label.text).strip_edges()


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_version_text() -> String:
	return _version_label.text if is_instance_valid(_version_label) else ""


func get_notice_text() -> String:
	return _notice_label.text if is_instance_valid(_notice_label) else ""


func get_menu_texts() -> PackedStringArray:
	## Visible menu entries in reading order.
	var out := PackedStringArray()
	for key in ["continue", "new_game", "challenge", "settings", "quit", "test_game"]:
		var item := _items.get(key) as Button
		if item != null and item.visible:
			out.append(item.text)
	return out


func get_desk() -> Control:
	return _desk


func set_busy(busy: bool) -> void:
	_busy = busy
	if not busy:
		_open_key = ""
		if is_instance_valid(_desk):
			_desk.reset_open()
	_refresh_items()


func is_continue_enabled() -> bool:
	return _is_live("continue")


func set_challenge_available(available: bool, reason: String = "") -> void:
	_challenge_available = available
	_challenge_hint = (
		"可重复挑战已解锁。"
		if available
		else (reason if not reason.is_empty() else "完成序列 8 晋升后开放")
	)
	_refresh_items()


func is_challenge_enabled() -> bool:
	return _is_live("challenge")


func get_challenge_hint_text() -> String:
	## Snapshot / copy-table reason; UI never invents the rule text.
	return _challenge_hint


func on_enter() -> void:
	for key in ["continue", "new_game"]:
		var item := _items.get(key) as Button
		if item != null and item.is_visible_in_tree() and not item.disabled:
			item.grab_focus()
			return


func on_exit() -> void:
	var key := _open_key
	_open_key = ""
	if key.is_empty() or not is_instance_valid(_desk):
		return
	if not bool(_desk.play_open(key)):
		return
	await _desk.open_finished


func show_backup_restore_result(success: bool, message: String) -> void:
	_set_notice(("备份已恢复。" if success else "恢复失败：") + message, success)


func show_preferences_save_state(success: bool, message: String = "") -> void:
	_set_notice("设置已保存。" if success else "设置保存失败：" + message, success)


func show_feedback_save_state(success: bool, message: String) -> void:
	_sheets.show_feedback_result(success, message)


func open_settings() -> void:
	_sheets.open_settings(_preferences, _backup_available and not _busy)


func close_settings() -> void:
	_sheets.close_settings()


func is_settings_open() -> bool:
	return _sheets.is_settings_open()


func is_confirm_open() -> bool:
	return _sheets.is_confirm_open()


func is_tutorial_open() -> bool:
	return _sheets.is_tutorial_open()


## --- TitleSheets callbacks -------------------------------------------------

func set_preference(key: String, value: Variant) -> void:
	_preferences[key] = value
	preferences_changed.emit(_preferences.duplicate(true))


func request_restore_backup() -> void:
	if _busy or not _backup_available:
		return
	restore_backup_requested.emit()


func submit_feedback(feedback: Dictionary) -> void:
	feedback_submitted.emit(feedback)


func confirm_new_game() -> void:
	_request_open("new_game", new_game_requested)


## --- Slip and menu ---------------------------------------------------------

func _build_slip() -> void:
	var shadow := Paper.slip_shadow()
	if shadow != null:
		_place(shadow, Rect2(SLIP_RECT.position + Vector2(10, 14), SLIP_RECT.size))
		add_child(shadow)
	var sheet := Paper.slip(Vector2.ZERO, 48)
	_slip = sheet["root"]
	_slip.name = "BookmarkSlip"
	_place(_slip, SLIP_RECT)
	add_child(_slip)
	var content: VBoxContainer = sheet["content"]
	content.add_theme_constant_override("separation", 6)

	content.add_child(Paper.ink_label("假面低语", 38, Paper.INK, true))
	_status_label = Paper.ink_label("", 22, Paper.INK)
	_status_label.name = "SaveSummary"
	content.add_child(_status_label)
	_detail_label = Paper.wrapped_ink("", 17, Paper.INK_SOFT)
	content.add_child(_detail_label)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	content.add_child(gap)
	content.add_child(Paper.rule())

	var menu := VBoxContainer.new()
	menu.name = "TitleMenu"
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_theme_constant_override("separation", 2)
	content.add_child(menu)
	_add_item(menu, "continue", _on_continue)
	_add_item(menu, "new_game", _on_new_game)
	_add_item(menu, "challenge", _on_challenge)
	## One size smaller than the 28px menu; only shown while locked.
	_challenge_hint_label = Paper.wrapped_ink("", 20, Paper.INK_DISABLED)
	_challenge_hint_label.name = "ChallengeHint"
	_challenge_hint_label.visible = false
	menu.add_child(_challenge_hint_label)
	_add_item(menu, "settings", open_settings)
	_add_item(menu, "quit", _on_quit)
	if OS.is_debug_build():
		var test_item := _add_item(menu, "test_game", _on_test_game, 18)
		test_item.tooltip_text = "调试构建：解锁全部卡牌、资源和挑战"

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(filler)
	_notice_label = Paper.wrapped_ink("", 15, Paper.INK_SOFT)
	content.add_child(_notice_label)
	_version_label = Paper.ink_label(
		"v%s · 本地离线原型" % String(
			ProjectSettings.get_setting("application/config/version", "0.0.0")
		),
		15,
		Paper.INK_SOFT
	)
	content.add_child(_version_label)


func _add_item(menu: VBoxContainer, key: String, on_press: Callable, font_size: int = 28) -> Button:
	var item := Paper.text_item(String(MENU_TEXT[key]), on_press, font_size)
	item.name = "TitleItem_%s" % key
	menu.add_child(item)
	_items[key] = item
	item.mouse_entered.connect(_sync_highlight.bind(key))
	item.mouse_exited.connect(_sync_highlight.bind(key))
	item.focus_entered.connect(_sync_highlight.bind(key))
	item.focus_exited.connect(_sync_highlight.bind(key))
	return item


func _sync_highlight(key: String) -> void:
	var item := _items.get(key) as Button
	if item == null or not is_instance_valid(_desk):
		return
	var on := not item.disabled and (item.is_hovered() or item.has_focus())
	_desk.highlight(key, on)


func _refresh_items() -> void:
	if _items.is_empty():
		return
	var has_checkpoint := _checkpoint_status == "loaded"
	_set_item("continue", has_checkpoint, _busy)
	_set_item("new_game", true, _busy)
	_set_challenge_item(_busy)
	_set_item("settings", true, false)
	_set_item("quit", true, _busy)
	_set_item("test_game", true, _busy)


func _set_item(key: String, listed: bool, disabled: bool) -> void:
	## A condition that is not met removes the entry from the list; it is not
	## a hidden leftover of another layout.
	var item := _items.get(key) as Button
	if item == null:
		return
	item.visible = listed
	item.disabled = disabled
	_sync_highlight(key)


func _set_challenge_item(busy: bool) -> void:
	## Locked challenge stays listed in grey with the snapshot reason under it
	## (v0.89 user ruling); it cannot be selected or focused.
	var item := _items.get("challenge") as Button
	if item == null:
		return
	var locked := not _challenge_available
	item.visible = true
	item.disabled = locked or busy
	item.focus_mode = Control.FOCUS_NONE if locked else Control.FOCUS_ALL
	if is_instance_valid(_challenge_hint_label):
		if locked and not _challenge_hint.is_empty():
			_challenge_hint_label.text = _challenge_hint
			_challenge_hint_label.visible = true
		else:
			_challenge_hint_label.visible = false
	_sync_highlight("challenge")


func _is_live(key: String) -> bool:
	var item := _items.get(key) as Button
	return item != null and item.visible and not item.disabled


func _set_notice(text_value: String, success: bool) -> void:
	if is_instance_valid(_notice_label):
		_notice_label.text = text_value
		_notice_label.add_theme_color_override(
			"font_color", Paper.INK_SOFT if success else Paper.INK_ACTIVE
		)
	_sheets.show_settings_notice(text_value)


func _place(node: Control, rect: Rect2) -> void:
	var design: Vector2 = TitleDeskStage.DESIGN
	node.anchor_left = rect.position.x / design.x
	node.anchor_top = rect.position.y / design.y
	node.anchor_right = rect.end.x / design.x
	node.anchor_bottom = rect.end.y / design.y
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


## --- Actions ---------------------------------------------------------------

func _on_new_game() -> void:
	if _busy:
		return
	if _checkpoint_status == "loaded":
		_sheets.open_confirm_new_game()
		return
	_request_open("new_game", new_game_requested)


func _on_continue() -> void:
	if _busy or _checkpoint_status != "loaded":
		return
	_request_open("continue", continue_requested)


func _on_challenge() -> void:
	if _busy or not _challenge_available:
		return
	_request_open("challenge", challenge_requested)


func _on_test_game() -> void:
	if _busy:
		return
	_request_open("test_game", test_game_requested)


func _on_quit() -> void:
	if _busy:
		return
	quit_requested.emit()


func _request_open(key: String, intent: Signal) -> void:
	## Every exit from the title plays the same push-in as the router's on_exit.
	set_busy(true)
	_open_key = key
	intent.emit()


## --- Text ------------------------------------------------------------------

func _identity_name(identity_id: String) -> String:
	match identity_id:
		"identity.reporter":
			return "记者"
		"identity.doctor":
			return "医生"
		"identity.gravedigger":
			return "守墓人"
		"":
			return "未选择身份"
		_:
			return identity_id


func _saved_at_text(created_at: String) -> String:
	if created_at.is_empty():
		return ""
	var stamp := created_at.replace("T", " ").trim_suffix("Z")
	return "保存于 " + stamp.substr(0, 16)
