extends Control
## Single owner of screen swaps (UI_NAVIGATION_REVIEW §3.1): fade overlay,
## one-transition-at-a-time input lock, optional on_exit/on_enter hooks and
## the diary-only instance cache. Screens opt into hooks by defining them.

signal transition_finished(screen: Control)

const TableSfx := preload("res://src/ui/table_sfx.gd")
const UiTheme := preload("res://src/ui/mask_ui_theme.gd")

const FADE_OUT_SEC := 0.18
const FADE_IN_SEC := 0.18
## Upper bound for a screen's on_exit beat; hooks must finish inside it
## because the screen is freed right after.
const EXIT_HOOK_CAP_SEC := 0.9
const TOAST_SEC := 3.2
const META_UPDATE_MODE := &"router_update_mode"

## Tests: skip every await so swaps stay synchronous. on_exit is not run.
var instant := false

var _busy := false
var _screen: Control = null
var _cache: Dictionary = {}
var _overlay: ColorRect
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _sfx_host: Node
var _fade_tween: Tween
var _last_exit_awaited := false


func _init() -> void:
	name = "ScreenRouter"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay = ColorRect.new()
	_overlay.name = "TransitionOverlay"
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_build_toast()
	_sfx_host = Node.new()
	_sfx_host.name = "TableSfxHost"
	_sfx_host.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_host)


func _enter_tree() -> void:
	TableSfx.set_persistent_host(_sfx_host)


func _exit_tree() -> void:
	if TableSfx.get_persistent_host() == _sfx_host:
		TableSfx.set_persistent_host(null)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for cached in _cache.values():
			if is_instance_valid(cached) and not cached.is_inside_tree():
				cached.free()
		_cache.clear()


func _input(event: InputEvent) -> void:
	## Keys reach focused buttons before the overlay can stop them.
	if _busy and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()


func is_busy() -> bool:
	return _busy


func get_current_screen() -> Control:
	return _screen


func get_overlay() -> ColorRect:
	return _overlay


func get_sfx_host() -> Node:
	return _sfx_host


func get_cached_screen(scene: PackedScene) -> Control:
	var cached: Variant = _cache.get(_cache_key(scene))
	return cached if is_instance_valid(cached) else null


func last_exit_was_awaited() -> bool:
	return _last_exit_awaited


func swap(scene: PackedScene, setup: Callable = Callable(), options: Dictionary = {}) -> Control:
	if _busy or scene == null:
		return null
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_last_exit_awaited = false
	var previous := _screen
	if not instant and is_instance_valid(previous):
		if previous.has_method("on_exit"):
			await _run_exit_hook(previous)
		await _fade_to(1.0, float(options.get("out", FADE_OUT_SEC)))
	_release(previous)
	var next := _acquire(scene, bool(options.get("cache", false)))
	add_child(next)
	## After add_child: SubViewportContainer resets its viewports on enter.
	_set_viewports_frozen(next, false)
	_keep_chrome_on_top()
	_screen = next
	if setup.is_valid():
		setup.call(next)
	if next.has_method("on_enter"):
		next.on_enter()
	_ensure_focus(next)
	if not instant:
		await _fade_to(0.0, float(options.get("in", FADE_IN_SEC)))
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	transition_finished.emit(next)
	return next


func clear_cache() -> void:
	for cached in _cache.values():
		if is_instance_valid(cached) and cached != _screen:
			cached.queue_free()
	_cache.clear()


func show_toast(text_value: String) -> void:
	_toast_label.text = text_value
	_toast_panel.visible = true
	_toast_panel.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	if instant or not is_inside_tree():
		return
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SEC)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast_panel.visible = false)


func get_toast_text() -> String:
	return _toast_label.text if _toast_panel.visible else ""


func _run_exit_hook(screen: Control) -> void:
	var state := {"done": false}
	var runner := func() -> void:
		await screen.on_exit()
		state["done"] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + int(EXIT_HOOK_CAP_SEC * 1000.0)
	while not bool(state["done"]) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_last_exit_awaited = bool(state["done"])


func _fade_to(alpha: float, duration: float) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if duration <= 0.0:
		_overlay.color.a = alpha
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(_overlay, "color:a", alpha, duration)
	await _fade_tween.finished


func _release(previous: Control) -> void:
	if not is_instance_valid(previous):
		return
	_disconnect_listeners(previous)
	remove_child(previous)
	if _cache.values().has(previous):
		_set_viewports_frozen(previous, true)
	else:
		previous.queue_free()
	if _screen == previous:
		_screen = null


func _disconnect_listeners(screen: Control) -> void:
	## A screen that has left must not drive navigation any more (late or
	## double clicks), and a cached one is re-wired by the next setup.
	var script := screen.get_script() as Script
	if script == null:
		return
	for signal_info in script.get_script_signal_list():
		var signal_name := StringName(signal_info.get("name", ""))
		for connection in screen.get_signal_connection_list(signal_name):
			var callable: Callable = connection.get("callable", Callable())
			var target := callable.get_object()
			if target == screen or (target is Node and screen.is_ancestor_of(target)):
				continue
			screen.disconnect(signal_name, callable)


func _acquire(scene: PackedScene, cacheable: bool) -> Control:
	var key := _cache_key(scene)
	if cacheable:
		var cached: Variant = _cache.get(key)
		if is_instance_valid(cached):
			return cached
	var next := scene.instantiate() as Control
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if cacheable:
		_cache[key] = next
	return next


func _cache_key(scene: PackedScene) -> String:
	return scene.resource_path if not scene.resource_path.is_empty() else str(scene.get_instance_id())


func _set_viewports_frozen(root: Node, frozen: bool) -> void:
	## Detached 3D desks keep their worlds; stop them from rendering meanwhile.
	for node in root.find_children("*", "SubViewport", true, false):
		var viewport := node as SubViewport
		if frozen:
			viewport.set_meta(META_UPDATE_MODE, viewport.render_target_update_mode)
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		elif viewport.has_meta(META_UPDATE_MODE):
			viewport.render_target_update_mode = viewport.get_meta(META_UPDATE_MODE)
			viewport.remove_meta(META_UPDATE_MODE)


func _keep_chrome_on_top() -> void:
	move_child(_overlay, -1)
	move_child(_toast_panel, -1)


func _ensure_focus(screen: Control) -> void:
	## Fallback for screens without their own on_enter focus choice (NAV-09).
	if not screen.is_inside_tree():
		return
	var owner_now := get_viewport().gui_get_focus_owner()
	if owner_now != null and screen.is_ancestor_of(owner_now):
		return
	for node in screen.find_children("*", "Button", true, false):
		var button := node as Button
		if (
			button.is_visible_in_tree()
			and not button.disabled
			and button.focus_mode != Control.FOCUS_NONE
		):
			button.grab_focus()
			return


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "RouterToast"
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.visible = false
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.anchor_top = 1.0
	_toast_panel.anchor_bottom = 1.0
	_toast_panel.offset_left = -320.0
	_toast_panel.offset_right = 320.0
	_toast_panel.offset_top = -96.0
	_toast_panel.offset_bottom = -40.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.05, 0.04, 0.92)
	style.border_color = Color(0.72, 0.52, 0.26, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	_toast_panel.add_theme_stylebox_override("panel", style)
	_toast_panel.theme = UiTheme.build_theme()
	_toast_label = Label.new()
	_toast_label.name = "RouterToastLabel"
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.74))
	_toast_panel.add_child(_toast_label)
	add_child(_toast_panel)
