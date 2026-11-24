extends Control

## 罗塞尔日记 — the desk 3D book (DiaryDeskStage) carries pages, flips and the
## wax seal; this screen owns spread state, quiet chrome and route commands.

signal route_command_requested(command: RouteCommand)
signal hub_requested
signal result_requested
signal page_flip_started
signal page_flip_finished

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const DiaryCatalog := preload("res://src/ui/diary_ui_catalog.gd")
const DiaryDeskStage := preload("res://src/ui/diary_desk_stage.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const RouteCommand := preload("res://src/core/route_command.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")

const POST_SHADER_PATH := "res://assets/ui/diary/diary_postprocess.gdshader"

const OPEN_BEGIN_ASCENSION := "begin_ascension"
## Wait out the settlement pen beat before the page turns by itself.
const AUTO_FLIP_DELAY_SEC := 2.35
const EXIT_BEAT_SEC := 0.55
const EXIT_BEAT_CLUE := "clue"
const EXIT_BEAT_CLOSE := "close"

const C_GOLD := Color(0.96, 0.78, 0.38, 1.0)

var _catalog := DiaryCatalog.new()
var _route_data: Dictionary = {}
var _diary_view: Dictionary = {}
var _spread_list: Array = []
var _current_spread_idx := 0
var is_flipping := false
var _command_busy := false
var _exit_beat := ""
var _pending_auto_flip := false
var _pending_flip_finish := false

var _title_label: Label
var _leaf_label: Label
var _carrier_label: Label
var _status_label: Label
var _pen_flash: Label
var _hub_button: Button
var _annotation_float: PanelContainer
var _annotation_body: Label
var _post_mat: ShaderMaterial
var _desk_stage: DiaryDeskStage


func _ready() -> void:
	theme = UiTheme.build_theme()
	_build()


func _process(_delta: float) -> void:
	if _post_mat == null:
		return
	var t := Time.get_ticks_msec() * 0.001
	## Candle sway breathes through the full-frame grade.
	var sway := (sin(t * 1.1) * 0.5 + 0.5) * 0.07 + (sin(t * 2.7) * 0.5 + 0.5) * 0.04
	var flicker := (sin(t * 7.3) * 0.5 + 0.5) * 0.025
	_post_mat.set_shader_parameter("time", t)
	_post_mat.set_shader_parameter("flicker", clampf(sway * 3.5 + flicker * 6.0, 0.0, 1.0))
	## Measured against the reference: its neighbour-delta (grain + material
	## micro-contrast) is 0.0439 while a clean render sits near 0.029.
	## Grain is what closes that gap, so it is driven hard here.
	_post_mat.set_shader_parameter("intensity", 0.92 + sway * 0.08)
	_post_mat.set_shader_parameter("grain_amount", 0.085)
	_post_mat.set_shader_parameter("warm", 0.30 + sway * 0.18)
	_post_mat.set_shader_parameter("vignette", 0.62)


func apply_snapshot(snapshot: RouteSnapshot) -> void:
	_command_busy = false
	_route_data = snapshot.to_dictionary() if snapshot != null else {}
	_reload_spreads(false)
	_refresh_chrome()
	_sync_desk_spread()
	if not is_flipping:
		_refresh_nav_buttons()


func apply_command_result(result: RouteCommandResult) -> void:
	_command_busy = false
	if result == null:
		_set_status("未收到日记结算。")
		return
	if not result.accepted:
		_exit_beat = ""
		_set_status("字句未能展开：%s" % String(result.reason_code))
		_refresh_desk_if_idle()
		return
	if result.snapshot != null:
		_route_data = result.snapshot.to_dictionary()
	var was_complete := false
	if _current_spread_idx >= 0 and _current_spread_idx < _spread_list.size():
		was_complete = bool(_spread_list[_current_spread_idx].get("is_main_complete", false))
	_reload_spreads(true)
	_refresh_chrome()
	_refresh_desk_if_idle()
	var wipe_note := ""
	for event in result.events:
		if event != null and event.type == &"InkWiped":
			wipe_note = _catalog.annotation_text(String(event.data.get("annotation_id", "")))
			if wipe_note.is_empty():
				wipe_note = _catalog.pool_head_text("wipe")
			break
	if wipe_note.is_empty():
		_play_pen_settlement("【0-08】阿勒苏霍德之笔落在页边——墨迹已改写这一叶。")
	else:
		_play_pen_settlement(wipe_note, true)
	## Auto flip when this spread's mains just completed.
	var now_complete := false
	if _current_spread_idx >= 0 and _current_spread_idx < _spread_list.size():
		now_complete = bool(_spread_list[_current_spread_idx].get("is_main_complete", false))
	if now_complete and not was_complete and _current_spread_idx < _spread_list.size() - 1:
		_schedule_auto_flip_next()


func present_post_encounter(focus_node_id: String, outcome: String) -> void:
	## Called after the app re-applies the snapshot post-battle/rest.
	if focus_node_id.is_empty() and outcome.is_empty():
		return
	var focus_idx := _spread_index_for_node(focus_node_id)
	if focus_idx >= 0:
		_current_spread_idx = focus_idx
		_refresh_chrome()
		_refresh_desk_if_idle()
	_play_pen_settlement(_settlement_flash_text(focus_node_id, outcome))
	if (
		focus_idx >= 0
		and bool(_spread_list[focus_idx].get("is_main_complete", false))
		and focus_idx < _spread_list.size() - 1
	):
		_schedule_auto_flip_next()


func set_challenge_context(_name: String, _modifier: String) -> void:
	pass


func get_status_text() -> String:
	return _status_label.text if is_instance_valid(_status_label) else ""


func get_background_path() -> String:
	return SceneCatalog.UI_CANVAS


func get_page_count() -> int:
	return _spread_list.size()


func get_current_spread_idx() -> int:
	return _current_spread_idx


func is_page_flipping() -> bool:
	return is_flipping


func request_node(node_id: String) -> void:
	if _interactions_locked() or node_id.is_empty():
		return
	var clue := _find_clue(node_id)
	if clue.is_empty():
		return
	_on_clue_pressed(clue)


## Read-only clue view as the desk seal carries it (seal_activated payload).
func get_clue(node_id: String) -> Dictionary:
	return _find_clue(node_id).duplicate(true)


func request_close() -> void:
	_on_hub()


func get_desk_stage() -> Control:
	return _desk_stage


func desk_world_ready() -> bool:
	if not is_instance_valid(_desk_stage):
		return false
	var cam := find_child("DeskCamera", true, false)
	var candle := find_child("CandleMesh", true, false)
	return (
		_desk_stage.get_desk_world() != null
		and _desk_stage.get_book_root() != null
		and _desk_stage.get_desk_mesh() != null
		and cam != null
		and candle != null
	)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	## Desk first so the chrome (title, status, close bookmark) stays clickable on top.
	_build_desk_stage(root)
	_build_annotation_float(root)
	_build_top_chrome(root)
	_build_bottom_chrome(root)
	_build_close_bookmark(root)
	_build_postprocess()


func _build_desk_stage(root: Control) -> void:
	_desk_stage = DiaryDeskStage.new()
	_desk_stage.name = "DiaryDeskStage"
	_desk_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_desk_stage)
	_desk_stage.seal_activated.connect(_on_clue_pressed)
	_desk_stage.flip_committed.connect(_on_desk_flip_committed)
	_desk_stage.status_message.connect(_set_status)
	_desk_stage.flip_visual_finished.connect(_on_desk_flip_visual_finished)


func _build_postprocess() -> void:
	## Grain / warm grade / vignette over the composed desk frame; it must sit on
	## top to sample the 3D render, and never steals clicks.
	var post_fx := ColorRect.new()
	post_fx.name = "DiaryPostFx"
	post_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_fx.color = Color(1, 1, 1, 1)
	post_fx.z_index = 100
	post_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var post_shader := load(POST_SHADER_PATH) as Shader
	if post_shader != null:
		_post_mat = ShaderMaterial.new()
		_post_mat.shader = post_shader
		_post_mat.set_shader_parameter("time", 0.0)
		_post_mat.set_shader_parameter("intensity", 0.52)
		_post_mat.set_shader_parameter("grain_amount", 0.07)
		_post_mat.set_shader_parameter("vignette", 0.52)
		_post_mat.set_shader_parameter("warm", 0.32)
		_post_mat.set_shader_parameter("flicker", 0.0)
		post_fx.material = _post_mat
	add_child(post_fx)


func _build_top_chrome(root: Control) -> void:
	## Faint header plate — the desk book stays the visual centre.
	var header_plate := Panel.new()
	header_plate.name = "HeaderParchment"
	header_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header_plate.offset_bottom = 48
	header_plate.modulate.a = 0.08
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.10, 0.06, 0.03, 0.32)
	plate.border_color = Color(0.62, 0.45, 0.22, 0.28)
	plate.border_width_bottom = 1
	header_plate.add_theme_stylebox_override("panel", plate)
	root.add_child(header_plate)
	var top := MarginContainer.new()
	top.name = "DiaryHeader"
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 56
	top.add_theme_constant_override("margin_left", 48)
	top.add_theme_constant_override("margin_top", 8)
	top.add_theme_constant_override("margin_right", 48)
	root.add_child(top)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 1)
	top.add_child(titles)
	_carrier_label = UiTheme.label("罗塞尔日记", 12, Color(0.92, 0.74, 0.42, 0.92))
	_carrier_label.modulate.a = 0.8
	titles.add_child(_carrier_label)
	_title_label = UiTheme.clip_label("第一卷", 20, Color(0.96, 0.90, 0.78, 0.95))
	_title_label.modulate.a = 0.95
	titles.add_child(_title_label)
	_leaf_label = UiTheme.clip_label("", 12, Color(0.78, 0.66, 0.46, 0.85))
	_leaf_label.modulate.a = 0.75
	titles.add_child(_leaf_label)


func _build_bottom_chrome(root: Control) -> void:
	## BRIEF §5A.6: page turns are desk swipes; the footer only whispers status.
	var footer_plate := Panel.new()
	footer_plate.name = "FooterParchment"
	footer_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_plate.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_plate.offset_top = -40
	footer_plate.modulate.a = 0.06
	var foot := StyleBoxFlat.new()
	foot.bg_color = Color(0.08, 0.05, 0.02, 0.22)
	foot.border_color = Color(0.62, 0.45, 0.22, 0.16)
	foot.border_width_top = 1
	footer_plate.add_theme_stylebox_override("panel", foot)
	root.add_child(footer_plate)
	var bottom := MarginContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -48
	bottom.add_theme_constant_override("margin_left", 40)
	bottom.add_theme_constant_override("margin_right", 100)
	bottom.add_theme_constant_override("margin_bottom", 8)
	root.add_child(bottom)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 2)
	bottom.add_child(mid)
	_status_label = UiTheme.clip_label("横滑翻页 · 点蜡封启事", 14, Color(0.96, 0.90, 0.78, 1.0))
	mid.add_child(_status_label)
	var flash_wrap := PanelContainer.new()
	flash_wrap.name = "PenFlashBanner"
	flash_wrap.visible = false
	flash_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_wrap.add_theme_stylebox_override(
		"panel",
		UiTheme.style_box(Color(0.32, 0.10, 0.06, 0.55), Color(0.82, 0.58, 0.22, 0.55), 1, 2)
	)
	mid.add_child(flash_wrap)
	_pen_flash = UiTheme.clip_label("", 14, Color(0.92, 0.78, 0.48, 1.0))
	_pen_flash.name = "PenFlash"
	_pen_flash.visible = false
	flash_wrap.add_child(_pen_flash)


func _build_close_bookmark(root: Control) -> void:
	## BRIEF DeskChrome: return is a desk-edge ribbon bookmark, kept far right
	## (x≥1536@1600) so it never overlaps WaxSealHit (~0.54–0.76).
	_hub_button = Button.new()
	_hub_button.name = "CloseBookmark"
	_hub_button.text = "合上"
	_hub_button.focus_mode = Control.FOCUS_ALL
	_hub_button.custom_minimum_size = Vector2(48, 88)
	_hub_button.anchor_left = 1.0
	_hub_button.anchor_right = 1.0
	_hub_button.anchor_top = 0.18
	_hub_button.anchor_bottom = 0.18
	_hub_button.offset_left = -52.0
	_hub_button.offset_right = -4.0
	_hub_button.offset_top = 0.0
	_hub_button.offset_bottom = 88.0
	_hub_button.add_theme_font_size_override("font_size", 15)
	_hub_button.add_theme_color_override("font_color", Color(0.96, 0.88, 0.70, 0.95))
	_hub_button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.80, 1.0))
	_hub_button.add_theme_color_override("font_disabled_color", Color(0.45, 0.38, 0.30, 0.55))
	_hub_button.add_theme_stylebox_override(
		"normal",
		UiTheme.style_box(Color(0.55, 0.12, 0.1, 0.88), Color(0.82, 0.58, 0.22, 0.7), 1, 2)
	)
	_hub_button.add_theme_stylebox_override(
		"hover",
		UiTheme.style_box(Color(0.68, 0.16, 0.12, 0.95), Color(0.95, 0.75, 0.35, 0.85), 1, 2)
	)
	_hub_button.add_theme_stylebox_override(
		"pressed",
		UiTheme.style_box(Color(0.22, 0.14, 0.06, 0.78), C_GOLD, 1, 3)
	)
	_hub_button.add_theme_stylebox_override("disabled", UiTheme.style_box(
		Color(0.08, 0.06, 0.04, 0.35), Color(0.35, 0.28, 0.18, 0.4), 1, 2
	))
	_hub_button.pressed.connect(_on_hub)
	root.add_child(_hub_button)


func _build_annotation_float(host: Control) -> void:
	_annotation_float = PanelContainer.new()
	_annotation_float.name = "AnnotationPopup"
	_annotation_float.visible = false
	## Non-modal floating ink — must not block desk swipe / seal.
	_annotation_float.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_annotation_float.anchor_left = 0.52
	_annotation_float.anchor_right = 0.78
	_annotation_float.anchor_top = 0.38
	_annotation_float.anchor_bottom = 0.58
	_annotation_float.add_theme_stylebox_override(
		"panel",
		UiTheme.style_box(Color(0.18, 0.12, 0.07, 0.72), Color(0.72, 0.52, 0.22, 0.4), 1, 3)
	)
	host.add_child(_annotation_float)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_bottom", 12)
	_annotation_float.add_child(pad)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 8)
	pad.add_child(col)
	var head := UiTheme.label("【0-08】页边批注", 14, C_GOLD)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	_annotation_body = UiTheme.wrapped_label("", 14, Color(0.92, 0.82, 0.62, 1.0))
	_annotation_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_annotation_body)


func _pulse_desk_chrome() -> void:
	if is_instance_valid(_status_label):
		_status_label.modulate.a = 0.75
		var tw := create_tween()
		tw.tween_property(_status_label, "modulate:a", 1.0, 1.2)
	if is_instance_valid(_title_label):
		_title_label.modulate.a = 0.62
		var tw2 := create_tween()
		tw2.tween_property(_title_label, "modulate:a", 0.95, 1.4)


func _reload_spreads(keep_idx: bool) -> void:
	_diary_view = _catalog.build_view(_route_data)
	_spread_list = _diary_view.get("spread_list", [])
	if not keep_idx:
		_current_spread_idx = int(_diary_view.get("current_spread_idx", 0))
	_current_spread_idx = clampi(_current_spread_idx, 0, maxi(0, _spread_list.size() - 1))


func _current_spread() -> Dictionary:
	if _current_spread_idx < 0 or _current_spread_idx >= _spread_list.size():
		return {}
	var value = _spread_list[_current_spread_idx]
	return value if value is Dictionary else {}


func _refresh_chrome() -> void:
	UiTheme.set_clip_text(
		_carrier_label,
		"%s · %s" % [
			String(_diary_view.get("carrier_zh", "罗塞尔日记")),
			String(_diary_view.get("pen_zh", "阿勒苏霍德之笔")),
		]
	)
	UiTheme.set_clip_text(
		_title_label,
		String(_diary_view.get("display_name_zh", "罗塞尔日记"))
	)
	## Desk folio already shows the leaf on the page; header stays a quiet volume line.
	UiTheme.set_clip_text(_leaf_label, "")
	var available_count := 0
	var wipe_cost := -1
	var rewritten_locked := 0
	for clue_value in _current_spread().get("clues", []):
		if not clue_value is Dictionary:
			continue
		var clue: Dictionary = clue_value
		var state := int(clue.get("state", 0))
		if state == DiaryCatalog.STATE_AVAILABLE:
			available_count += 1
		elif bool(clue.get("wipeable", false)):
			wipe_cost = int(clue.get("wipe_cost", 0))
		elif state == DiaryCatalog.STATE_LOCKED and bool(clue.get("rewritten_by_pen", false)):
			rewritten_locked += 1
	## DeskChrome: quiet edge whisper only — no “点暖金字句” system copy.
	if wipe_cost >= 0:
		_set_status("墨渍可拭 · 灵性 %d" % wipe_cost)
	elif rewritten_locked > 0:
		_set_status("笔改未启 · 横滑翻页")
	elif available_count > 0:
		_set_status("横滑翻页 · 点蜡封启事")
	else:
		_set_status("墨封未启 · 横滑翻页")


func _sync_desk_spread() -> void:
	if not is_instance_valid(_desk_stage):
		return
	_desk_stage.apply_spread(_current_spread())
	_sync_desk_flip_blocks()


func _sync_desk_flip_blocks() -> void:
	if not is_instance_valid(_desk_stage):
		return
	var block_forward := not _spread_can_open(_current_spread_idx + 1)
	var block_backward := _current_spread_idx <= 0
	_desk_stage.set_flip_blocked(block_forward, block_backward)


func _refresh_desk_if_idle() -> void:
	if is_flipping:
		return
	_sync_desk_spread()
	_refresh_nav_buttons()


func _desk_flip_allowed(delta: int) -> bool:
	## Shared gate for drag commits and programmatic turns; bounces with the
	## reason so callers only have to honour the bool.
	var target := _current_spread_idx + delta
	if target < 0 or target >= _spread_list.size():
		_desk_bounce("这一叠已经到头了。")
		return false
	## The snapshot decides which leaves are open; looking back is always fine.
	if delta > 0 and not _spread_can_open(target):
		_desk_bounce("墨封未启——还不能掀到后面。")
		return false
	return true


func _desk_visual_running() -> bool:
	return is_instance_valid(_desk_stage) and _desk_stage.is_flip_animating()


func _request_desk_flip(delta: int) -> void:
	## Entry for every turn the player did not drag (settlement auto-flip):
	## the leaf still swings on the hinge.
	if _interactions_locked() or is_flipping or delta == 0:
		return
	if not _desk_flip_allowed(delta):
		return
	if is_instance_valid(_desk_stage):
		is_flipping = true
		_refresh_nav_buttons()
		if _desk_stage.play_flip(delta):
			return
		## Stage refused (already mid-turn) — fall through to a direct commit.
		is_flipping = false
	_on_desk_flip_committed(delta)


func _on_desk_flip_committed(delta: int) -> void:
	## Arrives mid-curl from the stage (drag or programmatic), or immediately
	## when no stage visual is running (probes, fallback).
	var visual := _desk_visual_running()
	if _command_busy:
		return
	if not visual and is_flipping:
		return
	if not _desk_flip_allowed(delta):
		return
	if not visual:
		## No hinge motion to carry the sound; otherwise the stage played it.
		TableSfx.play(self, TableSfx.KIND_FLIP)
	page_flip_started.emit()
	_current_spread_idx += delta
	is_flipping = visual
	_sync_desk_spread()
	_refresh_chrome()
	_refresh_nav_buttons()
	if visual:
		## Leaf is still up; close out when it settles flat.
		_pending_flip_finish = true
		return
	page_flip_finished.emit()


func _on_desk_flip_visual_finished() -> void:
	if not _pending_flip_finish:
		## Bounce, or a commit the gate rejected — just release the lock.
		if is_flipping:
			is_flipping = false
			_refresh_nav_buttons()
		return
	_pending_flip_finish = false
	is_flipping = false
	_refresh_chrome()
	_refresh_nav_buttons()
	page_flip_finished.emit()


func _desk_bounce(reason: String) -> void:
	_sync_desk_flip_blocks()
	if is_instance_valid(_desk_stage):
		_desk_stage.bounce_flip(reason)
	else:
		_set_status(reason)


func _interactions_locked() -> bool:
	return is_flipping or _command_busy


func _refresh_nav_buttons() -> void:
	_hub_button.disabled = is_flipping


func _spread_flag(spread_idx: int, key: String) -> bool:
	if spread_idx < 0 or spread_idx >= _spread_list.size():
		return false
	var spread = _spread_list[spread_idx]
	return spread is Dictionary and bool(spread.get(key, false))


func _spread_can_open(spread_idx: int) -> bool:
	return _spread_flag(spread_idx, "can_open")


func _set_status(text_value: String) -> void:
	UiTheme.set_clip_text(_status_label, text_value)
	_pulse_desk_chrome()


func _play_pen_settlement(text_value: String, is_wipe: bool = false) -> void:
	## Settlement-only cue: status + pen flash banner + desk bloom on the 3D book.
	_flash_pen(text_value)
	TableSfx.play(self, TableSfx.KIND_WIPE if is_wipe else TableSfx.KIND_PEN)
	if is_instance_valid(_desk_stage):
		_desk_stage.play_settlement_fx("wipe" if is_wipe else "pen")


func _flash_pen(text_value: String) -> void:
	_set_status(text_value)
	if not is_instance_valid(_pen_flash):
		return
	var banner := _pen_flash.get_parent() as Control
	if banner != null:
		banner.visible = true
		banner.modulate.a = 0.0
	_pen_flash.visible = true
	UiTheme.set_clip_text(_pen_flash, "✒ %s" % text_value)
	_pen_flash.modulate = Color(1.0, 0.9, 0.6, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pen_flash, "modulate:a", 1.0, 0.16)
	if banner != null:
		tween.tween_property(banner, "modulate:a", 1.0, 0.16)
	tween.chain().tween_interval(2.1)
	tween.set_parallel(true)
	tween.tween_property(_pen_flash, "modulate:a", 0.0, 0.6)
	if banner != null:
		tween.tween_property(banner, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(_pen_flash):
			_pen_flash.visible = false
		if banner != null and is_instance_valid(banner):
			banner.visible = false
	)


func _on_clue_pressed(clue: Dictionary) -> void:
	if _interactions_locked() or clue.is_empty():
		return
	var state := int(clue.get("state", DiaryCatalog.STATE_LOCKED))
	var node_id := String(clue.get("node_id", ""))
	var annotation := String(clue.get("annotation_zh", ""))
	if state == DiaryCatalog.STATE_COMPLETED:
		_show_annotation_popup(annotation)
		return
	if state == DiaryCatalog.STATE_LOCKED:
		if not bool(clue.get("wipeable", false)) or node_id.is_empty():
			_set_status("墨渍未干。灵性不足，或这里还没有可擦的夜色。")
			return
		_command_busy = true
		_refresh_nav_buttons()
		_set_status("灵性汇于指尖……试图擦开墨渍。")
		route_command_requested.emit(RouteCommand.wipe_ink(StringName(node_id)))
		return
	if state != DiaryCatalog.STATE_AVAILABLE or node_id.is_empty():
		return
	_command_busy = true
	_exit_beat = EXIT_BEAT_CLUE
	_refresh_nav_buttons()
	if String(clue.get("open_command", "")) == OPEN_BEGIN_ASCENSION:
		_set_status("仪式扉页翻开——考核的字句在页边亮起。")
		route_command_requested.emit(RouteCommand.begin_ascension())
		return
	_set_status("字句展开……调查开始。")
	route_command_requested.emit(RouteCommand.select_node(StringName(node_id)))


func _show_annotation_popup(annotation: String) -> void:
	if not is_instance_valid(_annotation_float) or not is_instance_valid(_annotation_body):
		return
	_annotation_body.text = (
		annotation if not annotation.is_empty() else "这段结局尚未留下可读墨迹。"
	)
	## Brief floating ink, auto-fade (non-modal).
	_annotation_float.visible = true
	_annotation_float.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_annotation_float, "modulate:a", 1.0, 0.22)
	tween.tween_interval(2.2)
	tween.tween_property(_annotation_float, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		if is_instance_valid(_annotation_float):
			_annotation_float.visible = false
	)


func _find_clue(node_id: String) -> Dictionary:
	for spread_value in _spread_list:
		if not spread_value is Dictionary:
			continue
		for clue_value in spread_value.get("clues", []):
			if clue_value is Dictionary and String(clue_value.get("node_id", "")) == node_id:
				return clue_value
	return {}


func _spread_index_for_node(node_id: String) -> int:
	if node_id.is_empty():
		return -1
	for index in range(_spread_list.size()):
		var spread_value = _spread_list[index]
		if not spread_value is Dictionary:
			continue
		for clue_value in spread_value.get("clues", []):
			if clue_value is Dictionary and String(clue_value.get("node_id", "")) == node_id:
				return index
	return -1


func _settlement_flash_text(node_id: String, outcome: String) -> String:
	var clue := _find_clue(node_id)
	var annotation := String(clue.get("annotation_zh", ""))
	if not annotation.is_empty():
		return annotation
	var pool_id: String = {"spirit": "wipe"}.get(outcome, outcome)
	var head := _catalog.pool_head_text(pool_id)
	if not head.is_empty():
		return head
	return "【0-08】阿勒苏霍德之笔落在页边——墨迹已改写这一叶。"


func _schedule_auto_flip_next() -> void:
	_pending_auto_flip = true
	var tree := get_tree()
	if tree == null:
		call_deferred("_try_auto_flip_next")
		return
	## A bound method (not a lambda) so the connection dies with the screen.
	tree.create_timer(AUTO_FLIP_DELAY_SEC).timeout.connect(_try_auto_flip_next, CONNECT_ONE_SHOT)


func _try_auto_flip_next() -> void:
	if not _pending_auto_flip:
		return
	_pending_auto_flip = false
	if is_flipping or _current_spread_idx >= _spread_list.size() - 1:
		return
	if not _spread_flag(_current_spread_idx, "can_advance"):
		return
	## Settlement turns the leaf on the hinge, same as a hand would.
	_request_desk_flip(1)


func _on_hub() -> void:
	if is_flipping:
		return
	TableSfx.play(self, TableSfx.KIND_SEAL)
	_exit_beat = EXIT_BEAT_CLOSE
	hub_requested.emit()


## Router hooks. The screen is cached across battles (NAV-03), so on_enter must
## put it back into an idle, interactive state; the app re-applies the snapshot
## and any post-encounter settlement in its setup right before this.
func on_enter() -> void:
	_exit_beat = ""
	if is_instance_valid(_desk_stage):
		_desk_stage.modulate.a = 1.0
	if is_flipping:
		## Left mid-turn: settle on the committed spread.
		is_flipping = false
		_pending_flip_finish = false
		_refresh_desk_if_idle()
	_refresh_nav_buttons()
	if _hub_button.is_visible_in_tree():
		_hub_button.grab_focus()


## The app releases a seal press it could not honour (e.g. battle not ready).
func set_pending(value: bool) -> void:
	_command_busy = value
	if not value:
		_exit_beat = ""
	_refresh_nav_buttons()


func on_exit() -> void:
	## Pending timers would fire into a detached, cached screen.
	_pending_auto_flip = false
	var beat := _exit_beat
	_exit_beat = ""
	if beat.is_empty() or not is_inside_tree():
		return
	## Let the clue's status line and pen stroke read before the swap (NAV-04),
	## and close the book softly when returning to the hub.
	if beat == EXIT_BEAT_CLUE and is_instance_valid(_desk_stage):
		_desk_stage.play_settlement_fx("pen")
	var tween := create_tween()
	if is_instance_valid(_desk_stage):
		tween.tween_interval(EXIT_BEAT_SEC * 0.5)
		tween.tween_property(_desk_stage, "modulate:a", 0.0, EXIT_BEAT_SEC * 0.5)
	else:
		tween.tween_interval(EXIT_BEAT_SEC)
	await tween.finished


func get_exit_beat() -> String:
	return _exit_beat
