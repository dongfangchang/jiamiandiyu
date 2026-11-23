extends Control

## 罗塞尔日记翻页子系统 — Spread 成对展示；线索交互不触发翻页。

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

## v0.84 P0: desk 3D book is the interaction truth; legacy 2D book chrome is hidden.

const BOOK_PATH := "res://assets/ui/diary/open_book_spread.png"
const INK_PATH := "res://assets/ui/diary/ink_blot.svg"
const RIBBON_PATH := "res://assets/ui/diary/bookmark_ribbon.png"
const GRAIN_PATH_PNG := "res://assets/ui/diary/parchment_grain.png"
const GRAIN_PATH_SVG := "res://assets/ui/diary/parchment_grain.svg"
const GRAIN_PATH := GRAIN_PATH_PNG
const PEN_PATH := "res://assets/ui/diary/pen_008.svg"
const CANDLE_SHADER_PATH := "res://assets/ui/diary/candle_vignette.gdshader"
const GAZE_SHADER_PATH := "res://assets/ui/diary/gaze_distort.gdshader"
const POST_SHADER_PATH := "res://assets/ui/diary/diary_postprocess.gdshader"

const FLIP_DURATION := 0.78
const INDEX_FLIP_DURATION := 1.05
## Index hops turn leaf-by-leaf. One lookback leaf turns slowly; longer jumps
## riffle faster so a cross-volume hop stays near a second instead of crawling.
const INDEX_DESK_FLIP_DURATION := 0.82
const INDEX_DESK_FLIP_MIN := 0.26
const INDEX_CHAIN_BUDGET := 1.15
const FLIP_OFFSET := 92.0
const CORNER_DRAG_FRAC := 0.22
const DEFAULT_SPIRIT_WIPE_COST := 2

const C_INK := Color(0.08, 0.04, 0.02, 1.0)
const C_INK_FAINT := Color(0.22, 0.14, 0.08, 0.88)
const C_GOLD := Color(0.96, 0.78, 0.38, 1.0)
const C_ANNOTATION := Color(0.72, 0.22, 0.14, 1.0)
const INK_BASE_BB := "#1a0e06"
const INK_LOCKED_BB := "#2a180c"
const INK_GOLD_BB := "#f0d070"
const FLIP3D_PEAK_ALPHA := 0.96

var _catalog := DiaryCatalog.new()
var _route_data: Dictionary = {}
var _diary_view: Dictionary = {}
var _spread_list: Array = []
var _current_spread_idx := 0
var is_flipping := false
var _command_busy := false
var _pending_auto_flip := false
var _pending_flip_finish := false
var _glow_tween: Tween
var _flip_tween: Tween
var _flip_forward := true
var _flip_duration := FLIP_DURATION
var _index_chain: Array[int] = []
var _index_chain_active := false
var _index_chain_step := INDEX_DESK_FLIP_DURATION
var _flip_curl: ColorRect
var _ink_seal_fx: ColorRect
var _ink_seal_label: Label

var _title_label: Label
var _leaf_label: Label
var _carrier_label: Label
var _hp_meter: Label
var _spirit_meter: Label
var _corruption_meter: Label
var _attention_meter: Label
var _status_label: Label
var _pen_flash: Label
var _pen_overlay: Control
var _pen_glyph: Control
var _pen_glyph_label: Label
var _prev_button: Button
var _next_button: Button
var _index_button: Button
var _hub_button: Button
var _index_panel: PanelContainer
var _index_list: VBoxContainer
var _edge_index: Control
var _spirit_margin: Label
var _mold_layer: ColorRect
var _gaze_layer: Control
var _gaze_warp: ColorRect
var _gaze_mat: ShaderMaterial
var _post_fx: ColorRect
var _post_mat: ShaderMaterial
var _flip3d_host: SubViewportContainer
var _flip3d_mesh: MeshInstance3D
var _flip3d_hinge: Node3D
var _flip3d_left: MeshInstance3D
var _flip3d_spine: MeshInstance3D
var _flip3d_tween: Tween
var _candle_veil: ColorRect
var _candle_corner: ColorRect
var _candle_vignette: ColorRect
var _candle_mat: ShaderMaterial
var _lamp_glow: ColorRect
var _wear_tl: ColorRect
var _wear_tr: ColorRect
var _wear_bl: ColorRect
var _wear_br: ColorRect
var _ink_trail: ColorRect
var _annotation_float: PanelContainer
var _annotation_body: Label
var _book_root: Control
var _flip_drag_active := false
var _flip_drag_start := Vector2.ZERO
var _gaze_attention_ratio := 0.0
var _pointer_local := Vector2.ZERO
var _hp_wound := 0.0
var _candle_sway := 0.0
var _page_current: Control
var _page_next: Control
var _page_current_left: VBoxContainer
var _page_current_right: VBoxContainer
var _page_next_left: VBoxContainer
var _page_next_right: VBoxContainer
var _edge_shadow: ColorRect
var _glow_targets: Array[Control] = []
var _book_tex: Texture2D
var _ink_tex: Texture2D
var _ribbon_tex: Texture2D
var _grain_tex: Texture2D
var _pen_tex: Texture2D
var _base_notes: Array = []
var _spirit_wipe_cost := DEFAULT_SPIRIT_WIPE_COST
var _desk_stage: Control
var _legacy_book_shell: Control


func _ready() -> void:
	theme = UiTheme.build_theme()
	_book_tex = _load_image(BOOK_PATH)
	_ink_tex = _load_image(INK_PATH)
	_ribbon_tex = _load_image(RIBBON_PATH)
	_grain_tex = load(GRAIN_PATH_PNG) as Texture2D
	if _grain_tex == null:
		_grain_tex = load(GRAIN_PATH_SVG) as Texture2D
	_pen_tex = _load_image(PEN_PATH)
	_build()


func _process(_delta: float) -> void:
	if not is_instance_valid(_book_root):
		return
	var t := Time.get_ticks_msec() * 0.001
	## Candle sway: corner lamp + veil + book warmth breathe together.
	_candle_sway = (sin(t * 1.1) * 0.5 + 0.5) * 0.07 + (sin(t * 2.7) * 0.5 + 0.5) * 0.04
	var flicker := (sin(t * 7.3) * 0.5 + 0.5) * 0.025
	if is_instance_valid(_candle_veil):
		_candle_veil.color = Color(0.16, 0.08, 0.02, 0.04 + _candle_sway * 0.7)
	if is_instance_valid(_candle_corner):
		_candle_corner.color = Color(1.0, 0.72, 0.32, 0.08 + _candle_sway * 0.55 + flicker * 0.6)
	if is_instance_valid(_lamp_glow):
		_lamp_glow.color = Color(0.62, 0.38, 0.14, 0.12 + _candle_sway * 0.4 + flicker * 0.5)
	if _candle_mat != null:
		_candle_mat.set_shader_parameter("flicker", clampf(_candle_sway * 4.0 + flicker * 8.0, 0.0, 1.0))
		_candle_mat.set_shader_parameter("intensity", 0.78 + _candle_sway * 0.55 + flicker)
	if _post_mat != null:
		_post_mat.set_shader_parameter("time", t)
		_post_mat.set_shader_parameter("flicker", clampf(_candle_sway * 3.5 + flicker * 6.0, 0.0, 1.0))
		_post_mat.set_shader_parameter("intensity", 0.28 + _candle_sway * 0.22)
		_post_mat.set_shader_parameter("warm", 0.16 + _candle_sway * 0.28)
	_apply_book_modulate()
	## Gaze: light page drift + shader warp; stronger near pointer / high attention.
	if is_instance_valid(_page_current) and not is_flipping:
		var gaze := _gaze_attention_ratio
		var local := _pointer_local
		var near := 0.0
		var focus_uv := Vector2(0.5, 0.5)
		if _page_current.size.x > 1.0:
			var mid := _page_current.size * 0.5
			near = clampf(1.0 - local.distance_to(mid) / maxf(220.0, mid.length()), 0.0, 1.0)
			focus_uv = Vector2(
				clampf(local.x / maxf(1.0, _page_current.size.x), 0.05, 0.95),
				clampf(local.y / maxf(1.0, _page_current.size.y), 0.05, 0.95)
			)
		var amp := gaze * (0.7 + near * 1.4)
		_page_current.position.x = sin(t * 1.6) * amp
		_page_current.position.y = cos(t * 1.15) * amp * 0.55
		if is_instance_valid(_gaze_layer):
			_gaze_layer.modulate = Color(1, 1, 1, gaze * 0.12 * (0.35 + near))
		if _gaze_mat != null:
			_gaze_mat.set_shader_parameter("strength", clampf(gaze * (0.35 + near * 0.9), 0.0, 1.0))
			_gaze_mat.set_shader_parameter("time", t)
			_gaze_mat.set_shader_parameter("focus_uv", focus_uv)
		if is_instance_valid(_gaze_warp):
			_gaze_warp.visible = gaze > 0.04 and not is_flipping
	elif is_instance_valid(_gaze_warp):
		_gaze_warp.visible = false
		if _gaze_mat != null:
			_gaze_mat.set_shader_parameter("strength", 0.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_pointer_local = Vector2.ZERO


func _apply_book_modulate() -> void:
	if not is_instance_valid(_book_root) or is_flipping:
		return
	var warm := 1.0 + _candle_sway * 0.035
	_book_root.modulate = Color(
		warm,
		warm * (0.98 - _hp_wound * 0.08),
		warm * (0.94 - _hp_wound * 0.12),
		1.0
	)


func apply_snapshot(snapshot: RouteSnapshot) -> void:
	_command_busy = false
	_route_data = snapshot.to_dictionary() if snapshot != null else {}
	_spirit_wipe_cost = int(_route_data.get("spirit_wipe_cost", DEFAULT_SPIRIT_WIPE_COST))
	_reload_spreads(false)
	_refresh_chrome()
	_sync_desk_spread()
	if not is_flipping:
		_render_spread(_page_current_left, _page_current_right, _current_spread())
		_clear_spread(_page_next_left, _page_next_right)
		_set_page_next_idle()
		_page_current.modulate.a = 1.0
		_page_current.position.x = 0.0
		_refresh_nav_buttons()
		_start_glow()


func apply_command_result(result: RouteCommandResult) -> void:
	_command_busy = false
	if result == null:
		_set_status("未收到日记结算。")
		return
	if not result.accepted:
		_set_status("字句未能展开：%s" % String(result.reason_code))
		_refresh_spread_layers_if_idle()
		return
	if result.snapshot != null:
		_route_data = result.snapshot.to_dictionary()
	var was_complete := false
	if _current_spread_idx >= 0 and _current_spread_idx < _spread_list.size():
		was_complete = bool(_spread_list[_current_spread_idx].get("is_main_complete", false))
	_reload_spreads(true)
	_refresh_chrome()
	_refresh_spread_layers_if_idle()
	var wipe_note := ""
	for event in result.events:
		if event != null and event.type == &"InkWiped":
			wipe_note = String(event.data.get(
				"annotation_zh",
				"【灵性】墨渍退开一线——字迹重新可读。"
			))
			break
	if wipe_note.is_empty():
		_play_pen_settlement("【0-08】阿勒苏霍德之笔落在页边——墨迹已改写这一叶。")
	else:
		_play_pen_settlement(wipe_note, true)
	## Branch 4: auto flip when this spread's mains just completed.
	var now_complete := false
	if _current_spread_idx >= 0 and _current_spread_idx < _spread_list.size():
		now_complete = bool(_spread_list[_current_spread_idx].get("is_main_complete", false))
	if now_complete and not was_complete and _current_spread_idx < _spread_list.size() - 1:
		_schedule_auto_flip_next()


func present_post_encounter(focus_node_id: String, outcome: String) -> void:
	## Called after app replaces the screen post-battle/rest (apply_snapshot alone).
	if focus_node_id.is_empty() and outcome.is_empty():
		return
	var focus_idx := _spread_index_for_node(focus_node_id)
	if focus_idx >= 0:
		_current_spread_idx = focus_idx
		_refresh_chrome()
		_refresh_spread_layers_if_idle()
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


func _load_image(path: String) -> Texture2D:
	## Prefer imported resources (SVG/PNG via editor import); buffer decode as fallback.
	if ResourceLoader.exists(path):
		var res: Variant = load(path)
		if res is Texture2D:
			return res as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	var image := Image.new()
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		err = image.load_jpg_from_buffer(bytes)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func _build() -> void:
	UiTheme.add_background(self, SceneCatalog.UI_CANVAS, UiTheme.C_BG, 0.62)
	_lamp_glow = ColorRect.new()
	_lamp_glow.name = "LampGlow"
	_lamp_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lamp_glow.color = Color(0.62, 0.38, 0.14, 0.18)
	_lamp_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_lamp_glow)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_book_root = Control.new()
	_book_root.name = "BookShell"
	_book_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_book_root)

	var book_art := TextureRect.new()
	book_art.name = "DiaryBookArt"
	book_art.texture = _book_tex
	book_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	book_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	book_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Lift page hearts under the 2D ink without covering them in card plates.
	book_art.modulate = Color(1.12, 1.04, 0.92, 1.0)
	book_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book_root.add_child(book_art)

	_edge_shadow = ColorRect.new()
	_edge_shadow.name = "PageEdgeShadow"
	_edge_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge_shadow.color = Color(0.02, 0.01, 0.0, 0.0)
	_edge_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book_root.add_child(_edge_shadow)
	_flip_curl = ColorRect.new()
	_flip_curl.name = "FlipCurlShade"
	_flip_curl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flip_curl.color = Color(0.04, 0.02, 0.01, 0.0)
	_flip_curl.anchor_left = 0.46
	_flip_curl.anchor_right = 0.54
	_flip_curl.anchor_top = 0.12
	_flip_curl.anchor_bottom = 0.88
	_book_root.add_child(_flip_curl)
	_ink_seal_fx = ColorRect.new()
	_ink_seal_fx.name = "InkSealCoagulate"
	_ink_seal_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_seal_fx.color = Color(0.08, 0.03, 0.02, 0.0)
	_ink_seal_fx.visible = false
	_ink_seal_fx.anchor_left = 0.35
	_ink_seal_fx.anchor_right = 0.65
	_ink_seal_fx.anchor_top = 0.38
	_ink_seal_fx.anchor_bottom = 0.62
	_book_root.add_child(_ink_seal_fx)
	_ink_seal_label = Label.new()
	_ink_seal_label.name = "InkSealCoagulateLabel"
	_ink_seal_label.text = "墨封"
	_ink_seal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ink_seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ink_seal_label.add_theme_font_size_override("font_size", 22)
	_ink_seal_label.add_theme_color_override("font_color", Color(0.72, 0.48, 0.22, 0.0))
	_ink_seal_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ink_seal_fx.add_child(_ink_seal_label)

	var page_host := Control.new()
	page_host.name = "DiaryBook"
	page_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## Align text to illustrated parchment panels (gold-trimmed page hearts).
	page_host.offset_left = 188
	page_host.offset_top = 138
	page_host.offset_right = -188
	page_host.offset_bottom = -158
	_book_root.add_child(page_host)

	_page_current = _make_spread_layer("PageCurrent")
	_page_next = _make_spread_layer("PageNext")
	page_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_host.add_child(_page_current)
	page_host.add_child(_page_next)
	_set_page_next_idle()
	_gaze_warp = ColorRect.new()
	_gaze_warp.name = "GazeWarp"
	_gaze_warp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gaze_warp.color = Color(1, 1, 1, 1)
	_gaze_warp.visible = false
	_gaze_warp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gaze_shader := load(GAZE_SHADER_PATH) as Shader
	if gaze_shader != null:
		_gaze_mat = ShaderMaterial.new()
		_gaze_mat.shader = gaze_shader
		_gaze_mat.set_shader_parameter("strength", 0.0)
		_gaze_mat.set_shader_parameter("time", 0.0)
		_gaze_mat.set_shader_parameter("focus_uv", Vector2(0.5, 0.5))
		_gaze_warp.material = _gaze_mat
	page_host.add_child(_gaze_warp)

	_page_current_left = _page_current.get_node("Row/LeftPageWrap/LeftPage") as VBoxContainer
	_page_current_right = _page_current.get_node("Row/RightPageWrap/RightPage") as VBoxContainer
	_page_next_left = _page_next.get_node("Row/LeftPageWrap/LeftPage") as VBoxContainer
	_page_next_right = _page_next.get_node("Row/RightPageWrap/RightPage") as VBoxContainer

	if _ribbon_tex != null:
		var ribbon := TextureRect.new()
		ribbon.name = "BookmarkRibbon"
		ribbon.texture = _ribbon_tex
		ribbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ribbon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ribbon.modulate = Color(1.08, 0.92, 0.72, 1.0)
		ribbon.anchor_left = 0.472
		ribbon.anchor_right = 0.528
		ribbon.anchor_top = 0.70
		ribbon.anchor_bottom = 0.98
		_book_root.add_child(ribbon)

	_mold_layer = ColorRect.new()
	_mold_layer.name = "CorruptionMold"
	_mold_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mold_layer.color = Color(0.05, 0.02, 0.02, 0.0)
	_mold_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book_root.add_child(_mold_layer)
	_spirit_margin = UiTheme.label("", 11, Color(0.82, 0.68, 0.32, 0.0))
	_spirit_margin.name = "SpiritMarginNote"
	_spirit_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spirit_margin.anchor_left = 0.08
	_spirit_margin.anchor_right = 0.42
	_spirit_margin.anchor_top = 0.88
	_spirit_margin.anchor_bottom = 0.94
	_book_root.add_child(_spirit_margin)
	_gaze_layer = Control.new()
	_gaze_layer.name = "GazeDisturb"
	_gaze_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gaze_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book_root.add_child(_gaze_layer)
	_candle_veil = ColorRect.new()
	_candle_veil.name = "CandleVeil"
	_candle_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_candle_veil.color = Color(0.12, 0.06, 0.02, 0.08)
	_candle_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book_root.add_child(_candle_veil)
	_candle_corner = ColorRect.new()
	_candle_corner.name = "CandleCorner"
	_candle_corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_candle_corner.color = Color(1.0, 0.72, 0.32, 0.14)
	_candle_corner.anchor_left = 0.0
	_candle_corner.anchor_right = 0.42
	_candle_corner.anchor_top = 0.0
	_candle_corner.anchor_bottom = 0.38
	_candle_corner.offset_left = 0
	_candle_corner.offset_right = 0
	_candle_corner.offset_top = 0
	_candle_corner.offset_bottom = 0
	_book_root.add_child(_candle_corner)
	_candle_vignette = ColorRect.new()
	_candle_vignette.name = "CandleVignette"
	_candle_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_candle_vignette.color = Color(1, 1, 1, 1)
	_candle_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := load(CANDLE_SHADER_PATH) as Shader
	if shader != null:
		_candle_mat = ShaderMaterial.new()
		_candle_mat.shader = shader
		_candle_mat.set_shader_parameter("light_uv", Vector2(0.16, 0.10))
		_candle_mat.set_shader_parameter("intensity", 0.9)
		_candle_mat.set_shader_parameter("radius", 0.95)
		_candle_mat.set_shader_parameter("flicker", 0.0)
		_candle_vignette.material = _candle_mat
	_book_root.add_child(_candle_vignette)
	_wear_tl = _make_corner_wear("PageWearTL", true, true)
	_wear_tr = _make_corner_wear("PageWearTR", false, true)
	_wear_bl = _make_corner_wear("PageWearBL", true, false)
	_wear_br = _make_corner_wear("PageWearBR", false, false)
	_book_root.add_child(_wear_tl)
	_book_root.add_child(_wear_tr)
	_book_root.add_child(_wear_bl)
	_book_root.add_child(_wear_br)
	_book_root.add_child(_make_corner_drag_cue("PageCornerCueBL", true))
	_book_root.add_child(_make_corner_drag_cue("PageCornerCueBR", false))
	_ink_trail = ColorRect.new()
	_ink_trail.name = "InkTrail"
	_ink_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_trail.color = Color(0.35, 0.18, 0.08, 0.0)
	_ink_trail.visible = false
	_ink_trail.anchor_left = 0.72
	_ink_trail.anchor_right = 0.98
	_ink_trail.anchor_top = 0.20
	_ink_trail.anchor_bottom = 0.78
	_ink_trail.offset_left = 0
	_ink_trail.offset_right = 0
	_ink_trail.offset_top = 0
	_ink_trail.offset_bottom = 0
	_book_root.add_child(_ink_trail)
	_build_pen_overlay(_book_root)
	set_process(true)
	_build_annotation_float(root)
	_build_top_chrome(root)
	_build_bottom_chrome(root)
	_build_index_panel(root)
	_build_flip_3d()
	_build_postprocess()
	_book_root.gui_input.connect(_on_book_gui_input)
	_book_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_install_desk_p0(root)


func _install_desk_p0(root: Control) -> void:
	## Hide legacy full-bleed book UI; desk stage becomes the readable/interactive surface.
	_legacy_book_shell = _book_root
	if is_instance_valid(_book_root):
		_book_root.visible = false
		_book_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_flip3d_host):
		_flip3d_host.visible = false
		_flip3d_host.modulate.a = 0.0
	if is_instance_valid(_post_fx):
		_post_fx.visible = false
	## Dim/hide 2D rain-night plate — desk World3D is the scene backdrop now.
	var bg := get_node_or_null("SceneBackgroundHolder")
	if bg is CanvasItem:
		(bg as CanvasItem).visible = false
	if is_instance_valid(_lamp_glow):
		_lamp_glow.visible = false
	## Edge ink index fights desk swipe; keep panel for probes but off the main path.
	if is_instance_valid(_edge_index):
		_edge_index.visible = false
		_edge_index.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_index_panel):
		_index_panel.visible = false
		_index_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Soften header/footer plates so the 3D desk book stays the visual center.
	var header_plate := find_child("HeaderParchment", true, false) as CanvasItem
	if header_plate != null:
		header_plate.modulate.a = 0.08
	var footer_plate := find_child("FooterParchment", true, false) as CanvasItem
	if footer_plate != null:
		footer_plate.modulate.a = 0.06
	if is_instance_valid(_carrier_label):
		_carrier_label.modulate.a = 0.8
	if is_instance_valid(_title_label):
		_title_label.modulate.a = 0.95
	if is_instance_valid(_leaf_label):
		_leaf_label.modulate.a = 0.75
	if is_instance_valid(_status_label):
		_status_label.modulate.a = 1.0
	## Legacy 2D page FX must not veil the desk SubViewport.
	for fx_name in [
		"CandleVeil", "CorruptionMold", "SpiritMarginNote", "GazeLayer",
		"InkTrail", "CandleCorner", "CandleVignette",
	]:
		var fx := find_child(fx_name, true, false) as CanvasItem
		if fx != null:
			fx.visible = false
			if fx is Control:
				(fx as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin_hub_bookmark(root)
	## Pen flash banner is chrome noise on the desk path; keep node for probes, hide plate.
	var pen_banner := find_child("PenFlashBanner", true, false) as CanvasItem
	if pen_banner != null:
		pen_banner.visible = false
		pen_banner.modulate.a = 0.0
	_desk_stage = DiaryDeskStage.new()
	_desk_stage.name = "DiaryDeskStage"
	_desk_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## Insert under chrome so top/bottom bookmarks stay clickable.
	root.add_child(_desk_stage)
	root.move_child(_desk_stage, 0)
	if _desk_stage.has_signal("seal_activated"):
		_desk_stage.seal_activated.connect(_on_clue_pressed)
	if _desk_stage.has_signal("flip_committed"):
		_desk_stage.flip_committed.connect(_on_desk_flip_committed)
	if _desk_stage.has_signal("status_message"):
		_desk_stage.status_message.connect(_set_status)
	if _desk_stage.has_signal("flip_visual_finished"):
		_desk_stage.flip_visual_finished.connect(_on_desk_flip_visual_finished)


func _desk_flip_allowed(delta: int) -> bool:
	## Shared gate for drag commits and programmatic turns; bounces with the
	## reason so callers only have to honour the bool.
	var target := _current_spread_idx + delta
	if target < 0 or target >= _spread_list.size():
		_desk_bounce("这一叠已经到头了。")
		return false
	var target_spread = _spread_list[target]
	## P0: bounce when flipping forward into a non-investigable locked leaf.
	if delta > 0 and target_spread is Dictionary and not bool(target_spread.get("investigable", true)):
		_desk_bounce("墨封未启——还不能掀到后面。")
		return false
	if delta > 0 and not _can_open_spread(target):
		_desk_bounce("墨封未启——还不能掀到后面。")
		return false
	return true


func _desk_visual_running() -> bool:
	return (
		is_instance_valid(_desk_stage)
		and _desk_stage.has_method("is_flip_animating")
		and bool(_desk_stage.is_flip_animating())
	)


func _request_desk_flip(delta: int, duration: float = -1.0) -> void:
	## Entry for every turn the player did not drag (nav bookmarks, settlement
	## auto-flip, index hops). These used to swap the spread with no hinge
	## motion at all — the 2D flash the desk carrier exists to remove.
	if _interactions_locked() or is_flipping or delta == 0:
		return
	if not _desk_flip_allowed(delta):
		return
	if is_instance_valid(_desk_stage) and _desk_stage.has_method("play_flip"):
		is_flipping = true
		_stop_glow()
		_refresh_nav_buttons()
		var started := false
		if duration > 0.0:
			started = bool(_desk_stage.play_flip(delta, duration))
		else:
			started = bool(_desk_stage.play_flip(delta))
		if started:
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
	if _index_chain_active:
		call_deferred("_advance_index_chain")


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
	_start_glow()
	page_flip_finished.emit()
	if _index_chain_active:
		call_deferred("_advance_index_chain")


func _desk_bounce(reason: String) -> void:
	_sync_desk_flip_blocks()
	if is_instance_valid(_desk_stage) and _desk_stage.has_method("bounce_flip"):
		_desk_stage.bounce_flip(reason)
	else:
		_set_status(reason)


func get_desk_stage() -> Control:
	return _desk_stage


func desk_world_ready() -> bool:
	if not is_instance_valid(_desk_stage):
		return false
	var world = _desk_stage.get_desk_world() if _desk_stage.has_method("get_desk_world") else null
	var book = _desk_stage.get_book_root() if _desk_stage.has_method("get_book_root") else null
	var desk = _desk_stage.get_desk_mesh() if _desk_stage.has_method("get_desk_mesh") else null
	var cam := find_child("DeskCamera", true, false)
	var candle := find_child("CandleMesh", true, false)
	return world != null and book != null and desk != null and cam != null and candle != null


func legacy_book_art_visible() -> bool:
	var art := find_child("DiaryBookArt", true, false)
	return art != null and art is CanvasItem and (art as CanvasItem).visible and (
		is_instance_valid(_legacy_book_shell) and _legacy_book_shell.visible
	)


func _make_page_material(albedo: Color, use_book_tex: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.albedo_color = albedo
	if use_book_tex and _book_tex != null:
		mat.albedo_texture = _book_tex
	mat.roughness = 0.72
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _build_flip_3d() -> void:
	## Deepened book: left page + spine hinge + flipping leaf. 2D remains interaction truth.
	_flip3d_host = SubViewportContainer.new()
	_flip3d_host.name = "DiaryFlip3D"
	_flip3d_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flip3d_host.stretch = true
	_flip3d_host.visible = false
	_flip3d_host.modulate.a = 0.0
	_flip3d_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## Headless/dummy renderer cannot safely spin a live 3D SubViewport; keep markers.
	if DisplayServer.get_name() == "headless":
		for mark_name in [
			"DiaryFlip3DViewport",
			"FlipPageMesh",
			"FlipPageLeft",
			"FlipBookSpine",
			"FlipPageHinge",
			"DiaryWorldEnvironment",
		]:
			var mark := Node.new()
			mark.name = mark_name
			_flip3d_host.add_child(mark)
		_book_root.add_child(_flip3d_host)
		return
	var vp := SubViewport.new()
	vp.name = "DiaryFlip3DViewport"
	vp.transparent_bg = true
	vp.size = Vector2i(1600, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.msaa_3d = Viewport.MSAA_2X
	_flip3d_host.add_child(vp)
	var world := Node3D.new()
	world.name = "Flip3DWorld"
	vp.add_child(world)
	var world_env := WorldEnvironment.new()
	world_env.name = "DiaryWorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.02, 0.01, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.72, 0.42)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.12
	env.glow_strength = 0.35
	env.glow_bloom = 0.04
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.95
	env.adjustment_contrast = 1.14
	world_env.environment = env
	world.add_child(world_env)
	var light := DirectionalLight3D.new()
	light.name = "Flip3DLamp"
	light.rotation_degrees = Vector3(-42.0, -22.0, 0.0)
	light.light_energy = 1.55
	light.light_color = Color(1.0, 0.88, 0.68)
	world.add_child(light)
	var fill := OmniLight3D.new()
	fill.name = "Flip3DFill"
	fill.position = Vector3(-0.6, 0.35, 1.1)
	fill.light_energy = 0.55
	fill.light_color = Color(1.0, 0.82, 0.62)
	fill.omni_range = 3.5
	world.add_child(fill)
	var cam := Camera3D.new()
	cam.name = "Flip3DCamera"
	cam.current = true
	cam.fov = 38.0
	cam.position = Vector3(0.0, 0.06, 2.15)
	world.add_child(cam)
	var book := Node3D.new()
	book.name = "FlipBookRoot"
	world.add_child(book)
	## Left page stays put; flipping leaf hinges on the spine.
	_flip3d_left = MeshInstance3D.new()
	_flip3d_left.name = "FlipPageLeft"
	var left_quad := QuadMesh.new()
	left_quad.size = Vector2(0.84, 1.05)
	_flip3d_left.mesh = left_quad
	_flip3d_left.position = Vector3(-0.44, 0.0, 0.0)
	_flip3d_left.material_override = _make_page_material(Color(1.05, 0.98, 0.88, 1.0), true)
	book.add_child(_flip3d_left)
	_flip3d_spine = MeshInstance3D.new()
	_flip3d_spine.name = "FlipBookSpine"
	var spine_box := BoxMesh.new()
	spine_box.size = Vector3(0.06, 1.08, 0.04)
	_flip3d_spine.mesh = spine_box
	_flip3d_spine.position = Vector3(0.0, 0.0, -0.01)
	var spine_mat := StandardMaterial3D.new()
	spine_mat.albedo_color = Color(0.28, 0.14, 0.07, 1.0)
	spine_mat.roughness = 0.7
	_flip3d_spine.material_override = spine_mat
	book.add_child(_flip3d_spine)
	_flip3d_hinge = Node3D.new()
	_flip3d_hinge.name = "FlipPageHinge"
	_flip3d_hinge.position = Vector3(0.0, 0.0, 0.0)
	book.add_child(_flip3d_hinge)
	_flip3d_mesh = MeshInstance3D.new()
	_flip3d_mesh.name = "FlipPageMesh"
	var flip_quad := QuadMesh.new()
	flip_quad.size = Vector2(0.84, 1.05)
	_flip3d_mesh.mesh = flip_quad
	## Offset so the near edge sits on the hinge.
	_flip3d_mesh.position = Vector3(0.42, 0.0, 0.01)
	_flip3d_mesh.material_override = _make_page_material(Color(1.08, 1.00, 0.90, 1.0), true)
	_flip3d_hinge.add_child(_flip3d_mesh)
	_book_root.add_child(_flip3d_host)


func _play_flip_3d(forward: bool, duration: float) -> void:
	## v0.84 desk path owns flip visuals; never flash the legacy overlay on top of DeskStage.
	if is_instance_valid(_desk_stage):
		return
	if not is_instance_valid(_flip3d_host):
		return
	## Headless markers: still flash the host so probes can assert presence without 3D GPU.
	if not is_instance_valid(_flip3d_hinge):
		_flip3d_host.visible = true
		_flip3d_host.modulate.a = 0.7
		var stub := create_tween()
		stub.tween_property(_flip3d_host, "modulate:a", 0.0, minf(0.35, duration))
		stub.tween_callback(func() -> void:
			if is_instance_valid(_flip3d_host):
				_flip3d_host.visible = false
		)
		return
	if _flip3d_tween != null and _flip3d_tween.is_valid():
		_flip3d_tween.kill()
	var vp := _flip3d_host.get_node_or_null("DiaryFlip3DViewport") as SubViewport
	if vp != null:
		vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_flip3d_host.visible = true
	_flip3d_host.modulate.a = 0.0
	_flip3d_hinge.rotation_degrees = Vector3.ZERO
	## Forward = right leaf folds left over spine; back = starts from left and unfolds.
	if forward:
		_flip3d_mesh.position = Vector3(0.42, 0.0, 0.01)
		_flip3d_hinge.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	else:
		_flip3d_mesh.position = Vector3(-0.42, 0.0, 0.01)
		_flip3d_hinge.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	var yaw := -118.0 if forward else 118.0
	_flip3d_tween = create_tween()
	_flip3d_tween.set_parallel(true)
	_flip3d_tween.tween_property(
		_flip3d_host,
		"modulate:a",
		FLIP3D_PEAK_ALPHA,
		minf(0.28, duration * 0.28)
	)
	_flip3d_tween.tween_property(
		_flip3d_hinge,
		"rotation_degrees:y",
		yaw,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(_flip3d_left):
		_flip3d_tween.tween_property(
			_flip3d_left,
			"position:z",
			-0.03 if forward else 0.03,
			duration * 0.5
		)
	## Keep the turning leaf readable longer before dissolving back to 2D ink.
	_flip3d_tween.chain().set_parallel(true)
	_flip3d_tween.tween_property(_flip3d_host, "modulate:a", 0.0, 0.32)
	if is_instance_valid(_flip3d_left):
		_flip3d_tween.tween_property(_flip3d_left, "position:z", 0.0, 0.22)
	_flip3d_tween.chain().tween_callback(func() -> void:
		if is_instance_valid(_flip3d_host):
			_flip3d_host.visible = false
		if is_instance_valid(_flip3d_hinge):
			_flip3d_hinge.rotation_degrees = Vector3.ZERO
		if is_instance_valid(_flip3d_mesh):
			_flip3d_mesh.position = Vector3(0.42, 0.0, 0.01)
		if vp != null:
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	)


func _build_postprocess() -> void:
	## Full-screen diary grade; samples backbuffer, never steals clicks.
	_post_fx = ColorRect.new()
	_post_fx.name = "DiaryPostFx"
	_post_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_fx.color = Color(1, 1, 1, 1)
	_post_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
		_post_fx.material = _post_mat
	add_child(_post_fx)


func _make_spread_layer(layer_name: String) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 64)
	layer.add_child(row)
	var left_wrap := _page_column("LeftPage", true)
	var spine := Control.new()
	spine.name = "BookSpine"
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spine.custom_minimum_size = Vector2(28, 0)
	var spine_fill := ColorRect.new()
	spine_fill.name = "SpineShade"
	spine_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spine_fill.color = Color(0.08, 0.04, 0.02, 0.42)
	spine_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spine.add_child(spine_fill)
	var right_wrap := _page_column("RightPage", false)
	row.add_child(left_wrap)
	row.add_child(spine)
	row.add_child(right_wrap)
	return layer


func _page_column(page_name: String, is_left: bool) -> Control:
	## Eye-level parchment: warm wash + strong grain (not a faint watermark).
	var wrap := Control.new()
	wrap.name = page_name + "Wrap"
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := Panel.new()
	paper.name = "ParchmentWash"
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wash := StyleBoxFlat.new()
	## Whole-page paper lift (not per-clue cards) so ink sits on the book heart.
	wash.bg_color = (
		Color(0.96, 0.90, 0.74, 0.22) if is_left else Color(0.93, 0.86, 0.70, 0.20)
	)
	wash.border_color = Color(0.42, 0.28, 0.12, 0.10)
	wash.set_border_width_all(0)
	wash.set_corner_radius_all(0)
	paper.add_theme_stylebox_override("panel", wash)
	wrap.add_child(paper)
	if _grain_tex != null:
		var grain := TextureRect.new()
		grain.name = "ParchmentGrain"
		grain.texture = _grain_tex
		grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grain.modulate = (
			Color(1.0, 0.92, 0.78, 0.22) if is_left else Color(0.94, 0.86, 0.72, 0.18)
		)
		grain.flip_h = not is_left
		grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrap.add_child(grain)
		## Second grain pass at offset scale for deeper fiber read.
		var grain2 := TextureRect.new()
		grain2.name = "ParchmentGrainDeep"
		grain2.texture = _grain_tex
		grain2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grain2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		grain2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grain2.modulate = Color(0.85, 0.70, 0.45, 0.12)
		grain2.flip_h = is_left
		grain2.flip_v = true
		grain2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrap.add_child(grain2)
		## Corner water stains — physical paper aging without a new plate.
		var stain_a := ColorRect.new()
		stain_a.name = "PaperStainA"
		stain_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stain_a.color = Color(0.42, 0.28, 0.12, 0.10 if is_left else 0.08)
		stain_a.anchor_left = 0.02 if is_left else 0.55
		stain_a.anchor_right = 0.38 if is_left else 0.98
		stain_a.anchor_top = 0.04
		stain_a.anchor_bottom = 0.22
		wrap.add_child(stain_a)
		var stain_b := ColorRect.new()
		stain_b.name = "PaperStainB"
		stain_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stain_b.color = Color(0.28, 0.16, 0.08, 0.08)
		stain_b.anchor_left = 0.55 if is_left else 0.04
		stain_b.anchor_right = 0.96 if is_left else 0.42
		stain_b.anchor_top = 0.72
		stain_b.anchor_bottom = 0.96
		wrap.add_child(stain_b)
	## Spine-side gutter shadow so the spread reads as two physical pages.
	var gutter := ColorRect.new()
	gutter.name = "PageGutter"
	gutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gutter.color = Color(0.12, 0.06, 0.02, 0.12)
	if is_left:
		gutter.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		gutter.offset_left = -18
	else:
		gutter.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		gutter.offset_right = 18
	wrap.add_child(gutter)
	var page := VBoxContainer.new()
	page.name = page_name
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 12)
	page.offset_left = 8
	page.offset_right = -8
	page.offset_top = 6
	page.offset_bottom = -6
	wrap.add_child(page)
	return wrap


func _build_pen_overlay(host: Control) -> void:
	_pen_overlay = Control.new()
	_pen_overlay.name = "PenOverlay"
	_pen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pen_overlay.visible = false
	_pen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(_pen_overlay)
	var veil := ColorRect.new()
	veil.name = "PenVeil"
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color(0.06, 0.02, 0.01, 0.0)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pen_overlay.add_child(veil)
	var trail := ColorRect.new()
	trail.name = "InkTrail"
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trail.color = Color(0.62, 0.10, 0.08, 0.0)
	trail.anchor_left = 0.16
	trail.anchor_right = 0.84
	trail.anchor_top = 0.48
	trail.anchor_bottom = 0.48
	trail.offset_top = -5
	trail.offset_bottom = 5
	_pen_overlay.add_child(trail)
	var drip := ColorRect.new()
	drip.name = "InkDrip"
	drip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drip.color = Color(0.45, 0.08, 0.06, 0.0)
	drip.anchor_left = 0.48
	drip.anchor_right = 0.52
	drip.anchor_top = 0.48
	drip.anchor_bottom = 0.48
	drip.offset_left = -3
	drip.offset_right = 3
	drip.offset_bottom = 0
	_pen_overlay.add_child(drip)
	var bloom := ColorRect.new()
	bloom.name = "InkBloom"
	bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloom.color = Color(0.55, 0.12, 0.08, 0.0)
	bloom.anchor_left = 0.48
	bloom.anchor_right = 0.52
	bloom.anchor_top = 0.46
	bloom.anchor_bottom = 0.54
	bloom.offset_left = 0
	bloom.offset_right = 0
	bloom.offset_top = 0
	bloom.offset_bottom = 0
	_pen_overlay.add_child(bloom)
	var caption := Label.new()
	caption.name = "PenCaption"
	caption.text = "阿勒苏霍德之笔"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 26)
	caption.add_theme_color_override("font_color", Color(0.96, 0.82, 0.48, 1.0))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.anchor_left = 0.18
	caption.anchor_right = 0.82
	caption.anchor_top = 0.08
	caption.anchor_bottom = 0.16
	caption.modulate.a = 0.0
	_pen_overlay.add_child(caption)
	if _pen_tex != null:
		var art := TextureRect.new()
		art.name = "PenGlyph"
		art.texture = _pen_tex
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.anchor_left = 0.58
		art.anchor_right = 0.92
		art.anchor_top = 0.18
		art.anchor_bottom = 0.52
		_pen_overlay.add_child(art)
		_pen_glyph = art
	else:
		_pen_glyph_label = Label.new()
		_pen_glyph_label.name = "PenGlyph"
		_pen_glyph_label.text = "✒"
		_pen_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pen_glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_pen_glyph_label.add_theme_font_size_override("font_size", 148)
		_pen_glyph_label.add_theme_color_override("font_color", Color(0.92, 0.16, 0.12, 1.0))
		_pen_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pen_glyph_label.anchor_left = 0.62
		_pen_glyph_label.anchor_right = 0.78
		_pen_glyph_label.anchor_top = 0.28
		_pen_glyph_label.anchor_bottom = 0.42
		_pen_overlay.add_child(_pen_glyph_label)
		_pen_glyph = _pen_glyph_label


func _set_page_next_idle() -> void:
	## Transparent PageNext must not steal clicks from PageCurrent.
	if not is_instance_valid(_page_next):
		return
	_page_next.modulate.a = 0.0
	_page_next.position.x = 0.0
	_page_next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_next.visible = false
	_set_tree_mouse_filter(_page_next, Control.MOUSE_FILTER_IGNORE)


func _set_page_next_for_flip() -> void:
	if not is_instance_valid(_page_next):
		return
	_page_next.visible = true
	_page_next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_tree_mouse_filter(_page_next, Control.MOUSE_FILTER_IGNORE)


func _set_tree_mouse_filter(node: Node, mode: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = mode
	for child in node.get_children():
		_set_tree_mouse_filter(child, mode)


func _make_corner_wear(node_name: String, left: bool, top: bool) -> ColorRect:
	var wear := ColorRect.new()
	wear.name = node_name
	wear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wear.color = Color(0.28, 0.06, 0.04, 0.0)
	wear.anchor_left = 0.0 if left else 0.86
	wear.anchor_right = 0.14 if left else 1.0
	wear.anchor_top = 0.0 if top else 0.86
	wear.anchor_bottom = 0.14 if top else 1.0
	wear.offset_left = 0
	wear.offset_right = 0
	wear.offset_top = 0
	wear.offset_bottom = 0
	return wear


func _make_corner_drag_cue(node_name: String, left: bool) -> ColorRect:
	## Soft dog-ear hint: drag starts only in these lower corners.
	var cue := ColorRect.new()
	cue.name = node_name
	cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cue.color = Color(0.55, 0.38, 0.18, 0.16)
	cue.anchor_left = 0.0 if left else (1.0 - CORNER_DRAG_FRAC)
	cue.anchor_right = CORNER_DRAG_FRAC if left else 1.0
	cue.anchor_top = 1.0 - CORNER_DRAG_FRAC
	cue.anchor_bottom = 1.0
	cue.offset_left = 0
	cue.offset_right = 0
	cue.offset_top = 0
	cue.offset_bottom = 0
	return cue


func _build_top_chrome(root: Control) -> void:
	## Soft header plate — readable volume title without a full HUD.
	var header_plate := Panel.new()
	header_plate.name = "HeaderParchment"
	header_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header_plate.offset_bottom = 48
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	top.add_child(row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 1)
	row.add_child(titles)
	_carrier_label = UiTheme.label("罗塞尔日记", 12, Color(0.92, 0.74, 0.42, 0.92))
	titles.add_child(_carrier_label)
	_title_label = UiTheme.clip_label("第一卷", 20, Color(0.96, 0.90, 0.78, 0.95))
	titles.add_child(_title_label)
	_leaf_label = UiTheme.clip_label("", 12, Color(0.78, 0.66, 0.46, 0.85))
	titles.add_child(_leaf_label)
	## Hidden numeric meters kept for probes; live status is page-margin ink.
	var meters := HBoxContainer.new()
	meters.name = "StatusPanel"
	meters.visible = false
	meters.modulate.a = 0.0
	row.add_child(meters)
	_hp_meter = _meter_label("生命")
	_spirit_meter = _meter_label("灵性")
	_corruption_meter = _meter_label("污染")
	_attention_meter = _meter_label("注视")
	meters.add_child(_hp_meter)
	meters.add_child(_spirit_meter)
	meters.add_child(_corruption_meter)
	meters.add_child(_attention_meter)


func _meter_label(title: String) -> Label:
	var label := UiTheme.label("%s —" % title, 12, UiTheme.C_MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.custom_minimum_size = Vector2(88, 0)
	return label


func _build_bottom_chrome(root: Control) -> void:
	## Readable footer — page turns must not vanish into the desk.
	var footer_plate := Panel.new()
	footer_plate.name = "FooterParchment"
	footer_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_plate.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_plate.offset_top = -40
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bottom.add_child(row)
	## BRIEF §5A.6: P0 chrome is return bookmark + status; page turns are desk swipe.
	_prev_button = _ghost_button("‹ 前一页", _on_prev_page)
	_next_button = _ghost_button("后一页 ›", _on_next_page)
	_index_button = _ghost_button("页边", _on_index)
	_hub_button = _ghost_button("合上", _on_hub)
	_prev_button.visible = false
	_next_button.visible = false
	_index_button.visible = false
	_hub_button.modulate.a = 0.95
	row.add_child(_prev_button)
	row.add_child(_next_button)
	row.add_child(_index_button)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	row.add_child(mid)
	## Desk-edge whisper only — no “点暖金字句” chrome language.
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
	row.add_child(_hub_button)


func _pin_hub_bookmark(root: Control) -> void:
	## BRIEF DeskChrome: return as a desk-edge bookmark, not a footer toolbar item.
	## Keep far right (x≥1536@1600) so it never overlaps WaxSealHit (~0.54–0.76).
	if not is_instance_valid(_hub_button):
		return
	var host := _hub_button.get_parent()
	if host != null:
		host.remove_child(_hub_button)
	_hub_button.text = "合上"
	_hub_button.custom_minimum_size = Vector2(48, 88)
	_hub_button.anchor_left = 1.0
	_hub_button.anchor_right = 1.0
	_hub_button.anchor_top = 0.18
	_hub_button.anchor_bottom = 0.18
	_hub_button.offset_left = -52.0
	_hub_button.offset_right = -4.0
	_hub_button.offset_top = 0.0
	_hub_button.offset_bottom = 88.0
	_hub_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_hub_button.modulate = Color.WHITE
	_hub_button.add_theme_font_size_override("font_size", 15)
	var ribbon := UiTheme.style_box(Color(0.55, 0.12, 0.1, 0.88), Color(0.82, 0.58, 0.22, 0.7), 1, 2)
	_hub_button.add_theme_stylebox_override("normal", ribbon)
	_hub_button.add_theme_stylebox_override(
		"hover",
		UiTheme.style_box(Color(0.68, 0.16, 0.12, 0.95), Color(0.95, 0.75, 0.35, 0.85), 1, 2)
	)
	root.add_child(_hub_button)


func _pulse_desk_chrome() -> void:
	if is_instance_valid(_status_label):
		_status_label.modulate.a = 0.75
		var tw := create_tween()
		tw.tween_property(_status_label, "modulate:a", 1.0, 1.2)
	if is_instance_valid(_title_label):
		_title_label.modulate.a = 0.62
		var tw2 := create_tween()
		tw2.tween_property(_title_label, "modulate:a", 0.95, 1.4)


func _ghost_button(text_value: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(110, 34)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.96, 0.88, 0.70, 0.95))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.80, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.38, 0.30, 0.55))
	var normal := UiTheme.style_box(Color(0.12, 0.08, 0.04, 0.62), Color(0.72, 0.55, 0.28, 0.65), 1, 3)
	var hover := UiTheme.style_box(Color(0.22, 0.14, 0.06, 0.78), C_GOLD, 1, 3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", UiTheme.style_box(
		Color(0.08, 0.06, 0.04, 0.35), Color(0.35, 0.28, 0.18, 0.4), 1, 2
	))
	button.pressed.connect(on_pressed)
	return button


func _build_index_panel(root: Control) -> void:
	## Edge ink index: seeps from the right gutter on hover / toggle.
	_edge_index = Control.new()
	_edge_index.name = "EdgeInkIndex"
	_edge_index.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_edge_index.offset_left = -56
	_edge_index.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_edge_index)
	_edge_index.mouse_entered.connect(_on_edge_index_hover.bind(true))
	_edge_index.mouse_exited.connect(_on_edge_index_hover.bind(false))

	_index_panel = PanelContainer.new()
	_index_panel.name = "IndexPanel"
	_index_panel.visible = true
	_index_panel.modulate.a = 0.0
	_index_panel.anchor_left = 1.0
	_index_panel.anchor_right = 1.0
	_index_panel.anchor_top = 0.16
	_index_panel.anchor_bottom = 0.84
	_index_panel.offset_left = -220
	_index_panel.offset_right = -8
	_index_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_index_panel.add_theme_stylebox_override(
		"panel",
		UiTheme.style_box(Color(0.16, 0.11, 0.07, 0.38), Color(0.55, 0.40, 0.22, 0.35), 1, 2)
	)
	root.add_child(_index_panel)
	_index_panel.mouse_entered.connect(_on_edge_index_hover.bind(true))
	_index_panel.mouse_exited.connect(_on_edge_index_hover.bind(false))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	_index_panel.add_child(pad)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	pad.add_child(col)
	col.add_child(UiTheme.label("纸缝批注", 13, Color(0.72, 0.55, 0.28, 0.85)))
	col.add_child(UiTheme.clip_label("墨封之叶不可跳。", 10, Color(0.5, 0.4, 0.28, 0.7)))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_index_list = VBoxContainer.new()
	_index_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_index_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_index_list)


func _reload_spreads(keep_idx: bool) -> void:
	_diary_view = _catalog.build_view(_route_data)
	_spread_list = _diary_view.get("spread_list", [])
	_base_notes = _diary_view.get("base_notes_zh", [])
	if not _base_notes is Array:
		_base_notes = []
	if keep_idx:
		_current_spread_idx = clampi(_current_spread_idx, 0, maxi(0, _spread_list.size() - 1))
	else:
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
	var spread := _current_spread()
	## Desk folio already shows leaf on the page; header stays a quiet volume line.
	UiTheme.set_clip_text(_leaf_label, "")
	var run_state: Dictionary = _diary_view.get("run_state", {})
	var hp := int(run_state.get("hp", 0))
	var max_hp := maxi(1, int(run_state.get("max_hp", 1)))
	var spirit := int(run_state.get("spirit", 0))
	var max_spirit := maxi(1, int(run_state.get("max_spirit", 1)))
	var corruption := int(run_state.get("corruption", 0))
	var max_corruption := maxi(1, int(run_state.get("max_corruption", 1)))
	var attention := int(run_state.get("attention", 0))
	var max_attention := maxi(1, int(run_state.get("max_attention", 1)))
	_hp_meter.text = "生命 %d/%d" % [hp, max_hp]
	_spirit_meter.text = "灵性 %d/%d" % [spirit, max_spirit]
	_corruption_meter.text = "污染 %d/%d" % [corruption, max_corruption]
	_attention_meter.text = "注视 %d/%d" % [attention, max_attention]
	## Page-physical marks (immersion): spirit margin + corruption mold + gaze tint.
	if is_instance_valid(_spirit_margin):
		var spirit_ratio := float(spirit) / float(max_spirit)
		_spirit_margin.text = "灵性批注 · 余烬尚温" if spirit > 0 else ""
		_spirit_margin.modulate = Color(0.82, 0.68, 0.32, clampf(spirit_ratio * 0.85, 0.0, 0.85))
	if is_instance_valid(_mold_layer):
		var mold := float(corruption) / float(max_corruption)
		_mold_layer.color = Color(0.06, 0.02, 0.02, clampf(mold * 0.42, 0.0, 0.42))
		_rebuild_mold_blotches(mold)
	_gaze_attention_ratio = float(attention) / float(max_attention)
	_hp_wound = 1.0 - float(hp) / float(max_hp)
	_apply_book_modulate()
	if is_instance_valid(_book_root):
		var wear_a := clampf(_hp_wound * 0.55, 0.0, 0.55)
		for wear in [_wear_tl, _wear_tr, _wear_bl, _wear_br]:
			if is_instance_valid(wear):
				wear.color = Color(0.32, 0.05, 0.04, wear_a)
	var available_count := 0
	var wipeable_count := 0
	var rewritten_locked := 0
	for clue_value in spread.get("clues", []):
		if not clue_value is Dictionary:
			continue
		var clue: Dictionary = clue_value
		var state := int(clue.get("state", 0))
		if state == DiaryCatalog.STATE_AVAILABLE:
			available_count += 1
		elif state == DiaryCatalog.STATE_LOCKED and _clue_wipeable(clue):
			wipeable_count += 1
		elif state == DiaryCatalog.STATE_LOCKED and bool(clue.get("rewritten_by_pen", false)):
			rewritten_locked += 1
	## DeskChrome: quiet edge whisper only — no “点暖金字句” system copy.
	if wipeable_count > 0:
		_set_status("墨渍可拭 · 灵性 %d" % _spirit_wipe_cost)
	elif rewritten_locked > 0:
		_set_status("笔改未启 · 横滑翻页")
	elif available_count > 0:
		_set_status("横滑翻页 · 点蜡封启事")
	else:
		_set_status("墨封未启 · 横滑翻页")


func _sync_desk_spread() -> void:
	if not is_instance_valid(_desk_stage):
		return
	if _desk_stage.has_method("apply_spread"):
		_desk_stage.apply_spread(_current_spread())
	_sync_desk_flip_blocks()


func _sync_desk_flip_blocks() -> void:
	if not is_instance_valid(_desk_stage) or not _desk_stage.has_method("set_flip_blocked"):
		return
	var next := _current_spread_idx + 1
	var block_forward := true
	if next >= 0 and next < _spread_list.size():
		var nxt = _spread_list[next]
		var investigable := nxt is Dictionary and bool(nxt.get("investigable", true))
		block_forward = not investigable or not _can_open_spread(next)
	var block_backward := _current_spread_idx <= 0
	_desk_stage.set_flip_blocked(block_forward, block_backward)


func _refresh_spread_layers_if_idle() -> void:
	if is_flipping:
		return
	_render_spread(_page_current_left, _page_current_right, _current_spread())
	_clear_spread(_page_next_left, _page_next_right)
	_set_page_next_idle()
	_sync_desk_spread()
	_refresh_nav_buttons()
	_start_glow()


func _render_spread(left: VBoxContainer, right: VBoxContainer, spread: Dictionary) -> void:
	_stop_glow()
	_glow_targets.clear()
	_clear_spread(left, right)
	if spread.is_empty():
		return
	left.add_child(_page_masthead(true, spread))
	right.add_child(_page_masthead(false, spread))
	var left_clues: Array = spread.get("left_clues", [])
	var right_clues: Array = spread.get("right_clues", [])
	for index in range(left_clues.size()):
		if left_clues[index] is Dictionary:
			left.add_child(_build_passage(left_clues[index], index))
	var offset := left_clues.size()
	for index in range(right_clues.size()):
		if right_clues[index] is Dictionary:
			right.add_child(_build_passage(right_clues[index], offset + index))


func _clear_spread(left: VBoxContainer, right: VBoxContainer) -> void:
	for child in left.get_children():
		child.queue_free()
	for child in right.get_children():
		child.queue_free()


func _page_masthead(is_left: bool, spread: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.name = "PageMasthead"
	box.add_theme_constant_override("separation", 6)
	var folio := UiTheme.label(
		("其%s · 左页" if is_left else "右页 · 其%s") % String(spread.get("spread_label_zh", "")),
		14,
		Color(0.42, 0.26, 0.10, 1.0)
	)
	folio.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if is_left else HORIZONTAL_ALIGNMENT_RIGHT
	)
	box.add_child(folio)
	if is_left:
		var title := UiTheme.wrapped_label(String(spread.get("title_zh", "")), 26, C_INK)
		title.add_theme_font_size_override("font_size", 26)
		box.add_child(title)
	box.add_child(_ornament_line())
	var start := 0 if is_left else mini(2, _base_notes.size())
	var stop := mini(2, _base_notes.size()) if is_left else _base_notes.size()
	for index in range(start, stop):
		box.add_child(UiTheme.wrapped_label(String(_base_notes[index]), 13, C_INK_FAINT))
	box.add_child(_ornament_line())
	return box


func _ornament_line() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var left := ColorRect.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(0, 1)
	left.color = Color(0.48, 0.32, 0.12, 0.55)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var diamond := UiTheme.label("✦", 12, Color(0.62, 0.42, 0.16, 0.85))
	var right := ColorRect.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(0, 1)
	right.color = Color(0.48, 0.32, 0.12, 0.55)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(left)
	row.add_child(diamond)
	row.add_child(right)
	return row


func _build_passage(clue: Dictionary, index: int) -> Control:
	var state := int(clue.get("state", DiaryCatalog.STATE_LOCKED))
	var text := String(clue.get("text_zh", ""))
	var base_text := String(clue.get("base_text_zh", text))
	var overwrite_text := String(clue.get("overwrite_text_zh", ""))
	if overwrite_text.is_empty() and bool(clue.get("rewritten_by_pen", false)):
		overwrite_text = text
	var annotation := String(clue.get("annotation_zh", ""))
	var margin_note := String(clue.get("margin_note_zh", ""))
	var wipeable := _clue_wipeable(clue)
	var rewritten := bool(clue.get("rewritten_by_pen", false))
	var interactive := (
		not _interactions_locked()
		and (
			state == DiaryCatalog.STATE_AVAILABLE
			or state == DiaryCatalog.STATE_COMPLETED
			or wipeable
		)
	)

	var block := MarginContainer.new()
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_theme_constant_override("margin_top", 6)
	block.add_theme_constant_override("margin_bottom", 6)
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.custom_minimum_size = Vector2(0, 128)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_child(stack)

	## No per-passage card plate — contrast comes from whole-page wash + ink.
	if state == DiaryCatalog.STATE_AVAILABLE:
		var edge := ColorRect.new()
		edge.name = "AvailableInkEdge"
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.color = Color(0.95, 0.72, 0.28, 0.78)
		edge.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		edge.offset_right = 3
		stack.add_child(edge)
		_glow_targets.append(edge)
		var underline := ColorRect.new()
		underline.name = "AvailableInkUnderline"
		underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		underline.color = Color(0.88, 0.62, 0.22, 0.22)
		underline.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		underline.offset_top = -2
		stack.add_child(underline)
	elif state == DiaryCatalog.STATE_COMPLETED:
		var edge := ColorRect.new()
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.color = Color(0.52, 0.16, 0.12, 0.45)
		edge.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		edge.offset_right = 2
		stack.add_child(edge)
	elif wipeable or rewritten:
		if wipeable:
			var wipe_edge := ColorRect.new()
			wipe_edge.name = "WipeEdge"
			wipe_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wipe_edge.color = Color(0.45, 0.68, 0.92, 0.9)
			wipe_edge.set_anchors_preset(Control.PRESET_LEFT_WIDE)
			wipe_edge.offset_right = 3
			stack.add_child(wipe_edge)
			_glow_targets.append(wipe_edge)
		if rewritten:
			var rewrite_edge := ColorRect.new()
			rewrite_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rewrite_edge.color = Color(0.85, 0.22, 0.16, 0.75)
			rewrite_edge.set_anchors_preset(Control.PRESET_TOP_WIDE)
			rewrite_edge.offset_bottom = 2
			stack.add_child(rewrite_edge)

	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 12
	body.offset_right = -10
	body.offset_top = 4
	body.offset_bottom = -4
	body.add_theme_constant_override("separation", 3)
	stack.add_child(body)

	var tag_color := Color(0.28, 0.18, 0.10, 0.9)
	var tag_text := "墨渍吞没"
	match state:
		DiaryCatalog.STATE_AVAILABLE:
			tag_color = C_GOLD
			tag_text = "可调查" + (" ·笔改" if rewritten else "")
		DiaryCatalog.STATE_COMPLETED:
			tag_color = C_ANNOTATION
			tag_text = "已落笔"
		_:
			if wipeable:
				tag_color = Color(0.35, 0.48, 0.72, 1.0)
				tag_text = "可灵性擦拭 ·%d" % _spirit_wipe_cost
			elif rewritten:
				tag_color = C_ANNOTATION
				tag_text = "笔改过 ·未解锁"
	body.add_child(UiTheme.label("§%d  %s" % [index + 1, tag_text], 12, tag_color))

	var passage := RichTextLabel.new()
	passage.bbcode_enabled = true
	passage.fit_content = true
	passage.scroll_active = false
	passage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	passage.add_theme_font_size_override("normal_font_size", 18)
	passage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Layered ink: Roselle brown base; 0-08 gold overwrite when rewritten/completed.
	passage.name = "RoselleBaseInk"
	if rewritten:
		## Keep the original diary line under the pen rewrite.
		passage.text = "[color=%s][s]%s[/s][/color]" % [INK_BASE_BB, base_text]
		passage.modulate = Color(1, 1, 1, 0.78)
	else:
		match state:
			DiaryCatalog.STATE_AVAILABLE:
				passage.text = "[color=%s][i]%s[/i][/color]" % [INK_BASE_BB, text]
			DiaryCatalog.STATE_COMPLETED:
				passage.text = "[color=%s][s]%s[/s][/color]" % [INK_BASE_BB, text]
			_:
				passage.text = "[color=%s]%s[/color]" % [INK_LOCKED_BB, _obscure(text)]
				passage.modulate = Color(1, 1, 1, 0.92)
	body.add_child(passage)
	if rewritten or state == DiaryCatalog.STATE_COMPLETED:
		var gold_overwrite := RichTextLabel.new()
		gold_overwrite.name = "GoldOverwrite"
		gold_overwrite.bbcode_enabled = true
		gold_overwrite.fit_content = true
		gold_overwrite.scroll_active = false
		gold_overwrite.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gold_overwrite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gold_overwrite.add_theme_font_size_override("normal_font_size", 18)
		gold_overwrite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if rewritten and not overwrite_text.is_empty():
			gold_overwrite.text = "[color=%s][i]%s[/i][/color]" % [INK_GOLD_BB, overwrite_text]
		elif state == DiaryCatalog.STATE_COMPLETED and not annotation.is_empty():
			gold_overwrite.text = "[color=%s][i]%s[/i][/color]" % [INK_GOLD_BB, annotation]
		else:
			gold_overwrite.text = ""
		if not gold_overwrite.text.is_empty():
			body.add_child(gold_overwrite)
	## Top black erosion on completed/rewritten only — locked clues use ink blot.
	var run_for_veil: Dictionary = _diary_view.get("run_state", {})
	var veil_ratio := float(int(run_for_veil.get("corruption", 0))) / float(
		maxi(1, int(run_for_veil.get("max_corruption", 10)))
	)
	if (
		veil_ratio > 0.18
		and (
			state == DiaryCatalog.STATE_COMPLETED
			or rewritten
		)
	):
		var black_veil := ColorRect.new()
		black_veil.name = "CorruptionInkVeil"
		black_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		black_veil.color = Color(0.04, 0.02, 0.02, clampf(veil_ratio * 0.16, 0.04, 0.16))
		black_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.add_child(black_veil)

	if state == DiaryCatalog.STATE_AVAILABLE and not margin_note.is_empty():
		body.add_child(UiTheme.wrapped_label("—— %s" % margin_note, 13, Color(0.42, 0.28, 0.12, 1.0)))
	elif state == DiaryCatalog.STATE_AVAILABLE and not annotation.is_empty():
		body.add_child(UiTheme.wrapped_label(annotation, 14, Color(0.72, 0.48, 0.16, 1.0)))

	if state == DiaryCatalog.STATE_LOCKED:
		## Soft ink pool over text — keep obscure Roselle ink readable underneath.
		var pool := ColorRect.new()
		pool.name = "InkPool"
		pool.mouse_filter = Control.MOUSE_FILTER_IGNORE
		## Irregular mid-page blot — not a full-width card rectangle.
		pool.color = (
			Color(0.55, 0.12, 0.10, 0.10) if wipeable
			else Color(0.14, 0.06, 0.04, 0.08) if rewritten
			else Color(0.10, 0.05, 0.03, 0.06)
		)
		pool.anchor_left = 0.12
		pool.anchor_top = 0.36
		pool.anchor_right = 0.88
		pool.anchor_bottom = 0.88
		pool.offset_left = 0
		pool.offset_top = 0
		pool.offset_right = 0
		pool.offset_bottom = 0
		stack.add_child(pool)
		if _ink_tex != null:
			var blot := TextureRect.new()
			blot.name = "InkBlot"
			blot.texture = _ink_tex
			blot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			blot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			blot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			blot.modulate = Color(1.0, 1.0, 1.0, 0.18 if wipeable else 0.12)
			blot.anchor_left = 0.30
			blot.anchor_top = 0.38
			blot.anchor_right = 0.74
			blot.anchor_bottom = 0.86
			stack.add_child(blot)
		if not wipeable:
			## Coagulated seal plate — ink fused to paper, not a soft wash.
			var plate := ColorRect.new()
			plate.name = "InkSealPlate"
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plate.color = Color(0.12, 0.05, 0.03, 0.18)
			plate.anchor_left = 0.72
			plate.anchor_right = 0.96
			plate.anchor_top = 0.02
			plate.anchor_bottom = 0.18
			stack.add_child(plate)
			var plate_edge := ColorRect.new()
			plate_edge.name = "InkSealPlateEdge"
			plate_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plate_edge.color = Color(0.55, 0.28, 0.12, 0.45)
			plate_edge.anchor_left = 0.62
			plate_edge.anchor_right = 0.96
			plate_edge.anchor_top = 0.02
			plate_edge.anchor_bottom = 0.045
			stack.add_child(plate_edge)
		var seal := Label.new()
		seal.name = "InkSealMark"
		seal.text = "墨封·凝固" if not wipeable else "可拭"
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.add_theme_font_size_override("font_size", 13)
		seal.add_theme_color_override(
			"font_color",
			Color(0.72, 0.55, 0.28, 0.7) if wipeable else Color(0.78, 0.58, 0.28, 0.92)
		)
		seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		seal.anchor_left = 0.55
		seal.anchor_right = 0.96
		seal.anchor_top = 0.02
		seal.anchor_bottom = 0.22
		stack.add_child(seal)
	if rewritten:
		var stamp := Label.new()
		stamp.name = "PenRewriteStamp"
		stamp.text = "【0-08】笔改"
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp.add_theme_font_size_override("font_size", 15)
		stamp.add_theme_color_override("font_color", Color(0.98, 0.82, 0.38, 1.0))
		stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stamp.anchor_left = 0.42
		stamp.anchor_right = 0.98
		stamp.anchor_top = 0.0
		stamp.anchor_bottom = 0.28
		stack.add_child(stamp)

	var hit := Button.new()
	hit.name = "ClueHit"
	hit.focus_mode = Control.FOCUS_ALL
	hit.disabled = not interactive
	hit.mouse_filter = (
		Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	)
	hit.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## Transparent flat boxes still need a real StyleBoxFlat to remain clickable.
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(0, 0, 0, 0)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.78, 0.62, 0.28, 0.08 if state == DiaryCatalog.STATE_AVAILABLE else 0.0)
	hit.add_theme_stylebox_override("normal", clear)
	hit.add_theme_stylebox_override("hover", hover)
	hit.add_theme_stylebox_override("pressed", hover)
	hit.add_theme_stylebox_override("disabled", clear)
	hit.add_theme_stylebox_override(
		"focus",
		UiTheme.style_box(Color(0.78, 0.62, 0.28, 0.04), Color(0.72, 0.55, 0.26, 0.35), 1, 0)
	)
	stack.add_child(hit)
	if interactive:
		hit.pressed.connect(func() -> void:
			_on_clue_pressed(clue)
		)
	return block


func _obscure(text: String) -> String:
	## Keep Chinese-readable fragments; avoid block glyphs that read as UI junk.
	if text.length() <= 10:
		return "……墨迹吞没了字句……"
	var head := text.substr(0, mini(6, text.length()))
	var tail := text.substr(maxi(0, text.length() - 3), 3)
	return "%s……墨……墨封……%s" % [head, tail]


func _interactions_locked() -> bool:
	return is_flipping or _command_busy


func _refresh_nav_buttons() -> void:
	var last := _spread_list.size() - 1
	_prev_button.disabled = is_flipping or _current_spread_idx <= 0
	_next_button.disabled = (
		is_flipping
		or _current_spread_idx >= last
		or last < 0
		or not _can_advance_from(_current_spread_idx)
	)
	_index_button.disabled = is_flipping
	_hub_button.disabled = is_flipping


func _can_advance_from(spread_idx: int) -> bool:
	## Forward flip only after this spread's main clues are complete.
	if spread_idx < 0 or spread_idx >= _spread_list.size():
		return false
	var spread = _spread_list[spread_idx]
	if not spread is Dictionary:
		return false
	return bool(spread.get("is_main_complete", false))


func _can_open_spread(target_idx: int) -> bool:
	## Lookback always allowed; forward only through completed prior spreads.
	if target_idx < 0 or target_idx >= _spread_list.size():
		return false
	if target_idx <= _current_spread_idx:
		return true
	for index in range(target_idx):
		var spread = _spread_list[index]
		if not spread is Dictionary or not bool(spread.get("is_main_complete", false)):
			return false
	return true


func _furthest_open_idx() -> int:
	var furthest := 0
	for index in range(_spread_list.size()):
		furthest = index
		var spread = _spread_list[index]
		if not spread is Dictionary or not bool(spread.get("is_main_complete", false)):
			break
	return furthest


func _set_status(text_value: String) -> void:
	UiTheme.set_clip_text(_status_label, text_value)
	_pulse_desk_chrome()


func _play_pen_settlement(text_value: String, is_wipe: bool = false) -> void:
	## Settlement-only cue: status + pen flash + short glyph sweep.
	_flash_pen(text_value)
	TableSfx.play(self, TableSfx.KIND_WIPE if is_wipe else TableSfx.KIND_PEN)
	_run_pen_overlay(is_wipe)
	## Desk bloom so settlement reads on the 3D book, not only the chrome banner.
	if is_instance_valid(_desk_stage) and _desk_stage.has_method("play_settlement_fx"):
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


func _run_pen_overlay(is_wipe: bool) -> void:
	if not is_instance_valid(_pen_overlay) or not is_instance_valid(_pen_glyph):
		return
	_pen_overlay.visible = true
	_pen_overlay.modulate.a = 1.0
	var veil := _pen_overlay.get_node_or_null("PenVeil") as ColorRect
	var trail := _pen_overlay.get_node_or_null("InkTrail") as ColorRect
	var caption := _pen_overlay.get_node_or_null("PenCaption") as Label
	var drip := _pen_overlay.get_node_or_null("InkDrip") as ColorRect
	var bloom := _pen_overlay.get_node_or_null("InkBloom") as ColorRect
	if _pen_glyph_label != null and is_instance_valid(_pen_glyph_label):
		_pen_glyph_label.text = "✧" if is_wipe else "✒"
	if caption != null:
		caption.text = "灵性擦拭" if is_wipe else "【0-08】阿勒苏霍德之笔"
		caption.modulate.a = 0.0
	_pen_glyph.rotation_degrees = -32.0 if is_wipe else 28.0
	## Wipe tints cool; pen keeps warm ink red.
	_pen_glyph.modulate = (
		Color(0.55, 0.72, 0.95, 0.0) if is_wipe else Color(1.05, 0.92, 0.82, 0.0)
	)
	_pen_glyph.scale = Vector2(1.7, 1.7)
	_pen_glyph.pivot_offset = _pen_glyph.size * 0.5
	_pen_glyph.anchor_left = 0.72
	_pen_glyph.anchor_right = 0.98
	_pen_glyph.anchor_top = 0.06
	_pen_glyph.anchor_bottom = 0.38
	if trail != null:
		trail.color.a = 0.0
		trail.anchor_right = 0.20
		trail.offset_top = -5
		trail.offset_bottom = 5
	if drip != null:
		drip.color.a = 0.0
		drip.anchor_top = 0.48
		drip.anchor_bottom = 0.48
		drip.offset_bottom = 0
	if bloom != null:
		bloom.color = (
			Color(0.35, 0.55, 0.85, 0.0) if is_wipe else Color(0.55, 0.12, 0.08, 0.0)
		)
		bloom.anchor_left = 0.49
		bloom.anchor_right = 0.51
		bloom.anchor_top = 0.49
		bloom.anchor_bottom = 0.51
	## Punch the book so settlement reads as a camera beat.
	if is_instance_valid(_book_root):
		_book_root.scale = Vector2(1.0, 1.0)
		_book_root.pivot_offset = _book_root.size * 0.5
	if is_instance_valid(_edge_shadow):
		_edge_shadow.color.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	if veil != null:
		veil.color.a = 0.0
		tween.tween_property(veil, "color:a", 0.55 if is_wipe else 0.68, 0.28)
	if caption != null:
		tween.tween_property(caption, "modulate:a", 1.0, 0.28)
	if is_instance_valid(_edge_shadow):
		tween.tween_property(_edge_shadow, "color:a", 0.38, 0.35)
	if is_instance_valid(_book_root):
		tween.tween_property(_book_root, "scale", Vector2(1.055, 1.055), 0.38).set_trans(
			Tween.TRANS_BACK
		)
	tween.tween_property(_pen_glyph, "modulate:a", 1.0, 0.18)
	tween.tween_property(_pen_glyph, "scale", Vector2(1.05, 1.05), 1.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_pen_glyph, "anchor_left", 0.22, 1.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_pen_glyph, "anchor_right", 0.42, 1.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_pen_glyph, "anchor_top", 0.52, 1.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_pen_glyph, "anchor_bottom", 0.74, 1.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_pen_glyph, "rotation_degrees", -8.0 if is_wipe else 10.0, 1.35)
	if trail != null:
		tween.tween_property(trail, "color:a", 0.78, 0.4)
		tween.tween_property(trail, "anchor_right", 0.82, 1.3).set_trans(Tween.TRANS_SINE)
	if drip != null:
		tween.tween_property(drip, "color:a", 0.65, 0.55).set_delay(0.35)
		tween.tween_property(drip, "offset_bottom", 48.0, 0.9).set_delay(0.35).set_trans(
			Tween.TRANS_SINE
		)
	if bloom != null:
		## Ink blooms from the nib — minimum readable blot without a handwriting engine.
		tween.tween_property(bloom, "color:a", 0.42 if is_wipe else 0.55, 0.45).set_delay(0.25)
		tween.tween_property(bloom, "anchor_left", 0.28, 1.05).set_delay(0.25).set_trans(
			Tween.TRANS_SINE
		)
		tween.tween_property(bloom, "anchor_right", 0.72, 1.05).set_delay(0.25).set_trans(
			Tween.TRANS_SINE
		)
		tween.tween_property(bloom, "anchor_top", 0.38, 1.05).set_delay(0.25).set_trans(
			Tween.TRANS_SINE
		)
		tween.tween_property(bloom, "anchor_bottom", 0.68, 1.05).set_delay(0.25).set_trans(
			Tween.TRANS_SINE
		)
	tween.chain().tween_interval(0.85)
	tween.set_parallel(true)
	tween.tween_property(_pen_glyph, "modulate:a", 0.0, 0.55)
	if veil != null:
		tween.tween_property(veil, "color:a", 0.0, 0.55)
	if trail != null:
		tween.tween_property(trail, "color:a", 0.0, 0.5)
	if drip != null:
		tween.tween_property(drip, "color:a", 0.0, 0.45)
	if bloom != null:
		tween.tween_property(bloom, "color:a", 0.0, 0.55)
	if caption != null:
		tween.tween_property(caption, "modulate:a", 0.0, 0.45)
	if is_instance_valid(_book_root):
		tween.tween_property(_book_root, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(_edge_shadow):
		tween.tween_property(_edge_shadow, "color:a", 0.0, 0.5)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(_pen_overlay):
			_pen_overlay.visible = false
		if is_instance_valid(_book_root):
			_book_root.scale = Vector2.ONE
		if is_instance_valid(_edge_shadow):
			_edge_shadow.color.a = 0.0
	)


func _clue_wipeable(clue: Dictionary) -> bool:
	if int(clue.get("state", DiaryCatalog.STATE_LOCKED)) != DiaryCatalog.STATE_LOCKED:
		return false
	var annotation := String(clue.get("annotation_zh", ""))
	if annotation.find("墨渍") < 0:
		return false
	var run_state: Dictionary = _diary_view.get("run_state", {})
	return int(run_state.get("spirit", 0)) >= _spirit_wipe_cost


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
		if not _clue_wipeable(clue) or node_id.is_empty():
			_set_status("墨渍未干。灵性不足，或这里还没有可擦的夜色。")
			return
		_command_busy = true
		_stop_glow()
		_refresh_nav_buttons()
		_set_status("灵性汇于指尖……试图擦开墨渍。")
		route_command_requested.emit(RouteCommand.wipe_ink(StringName(node_id)))
		return
	if state != DiaryCatalog.STATE_AVAILABLE or node_id.is_empty():
		return
	_command_busy = true
	_stop_glow()
	_refresh_nav_buttons()
	if String(clue.get("node_type", "")) == "ritual":
		_set_status("仪式扉页翻开——考核的字句在页边亮起。")
		route_command_requested.emit(RouteCommand.begin_ascension())
		return
	_set_status("字句展开……调查开始。")
	route_command_requested.emit(RouteCommand.select_node(StringName(node_id)))


func _build_annotation_float(host: Control) -> void:
	_annotation_float = PanelContainer.new()
	_annotation_float.name = "AnnotationPopup"
	_annotation_float.visible = false
	## Non-modal floating ink — must not block desk swipe / seal.
	_annotation_float.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_annotation_float.anchor_left = 0.28
	_annotation_float.anchor_right = 0.72
	_annotation_float.anchor_top = 0.34
	_annotation_float.anchor_bottom = 0.62
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


func _show_annotation_popup(annotation: String) -> void:
	if not is_instance_valid(_annotation_float) or not is_instance_valid(_annotation_body):
		return
	_annotation_body.text = (
		annotation if not annotation.is_empty() else "这段结局尚未留下可读墨迹。"
	)
	## Desk P0: brief floating ink, auto-fade (non-modal system window).
	_annotation_float.anchor_left = 0.52
	_annotation_float.anchor_right = 0.78
	_annotation_float.anchor_top = 0.38
	_annotation_float.anchor_bottom = 0.58
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


func _on_edge_index_hover(entering: bool) -> void:
	if not is_instance_valid(_index_panel):
		return
	var target_a := 0.92 if entering else 0.0
	var tween := create_tween()
	tween.tween_property(_index_panel, "modulate:a", target_a, 0.35).set_trans(Tween.TRANS_SINE)


func _set_index_open(open: bool) -> void:
	if not is_instance_valid(_index_panel):
		return
	if open:
		_rebuild_index_list()
	var tween := create_tween()
	tween.tween_property(_index_panel, "modulate:a", 0.95 if open else 0.0, 0.4)


func _is_page_corner(local_pos: Vector2) -> bool:
	## Only the lower page corners own the drag-flip gesture.
	if not is_instance_valid(_book_root):
		return false
	var sz := _book_root.size
	if sz.x <= 1.0 or sz.y <= 1.0:
		return false
	var in_bottom := local_pos.y >= sz.y * (1.0 - CORNER_DRAG_FRAC)
	var in_left := local_pos.x <= sz.x * CORNER_DRAG_FRAC
	var in_right := local_pos.x >= sz.x * (1.0 - CORNER_DRAG_FRAC)
	return in_bottom and (in_left or in_right)


func _on_book_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_pointer_local = mm.position
		if _flip_drag_active and is_instance_valid(_book_root) and not is_flipping:
			var preview := clampf((mm.position.x - _flip_drag_start.x) * 0.04, -6.0, 6.0)
			_book_root.rotation_degrees = preview
			var lift := absf(preview) / 6.0
			_book_root.scale = Vector2(1.0 + lift * 0.02, 1.0 - lift * 0.015)
			if is_instance_valid(_flip_curl):
				_flip_curl.color.a = lift * 0.28
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				## Page-heart presses stay with clues; only corners start a flip drag.
				if _is_page_corner(mb.position) and not is_flipping and not _index_chain_active:
					_flip_drag_active = true
					_flip_drag_start = mb.position
			else:
				if _flip_drag_active:
					var delta := mb.position.x - _flip_drag_start.x
					_flip_drag_active = false
					if is_instance_valid(_book_root):
						var settle := create_tween()
						settle.set_parallel(true)
						settle.tween_property(_book_root, "rotation_degrees", 0.0, 0.18)
						settle.tween_property(_book_root, "scale", Vector2.ONE, 0.18)
						if is_instance_valid(_flip_curl):
							settle.tween_property(_flip_curl, "color:a", 0.0, 0.18)
					if delta < -48.0:
						_on_next_page()
					elif delta > 48.0:
						_on_prev_page()


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
	match outcome:
		"victory":
			return "【0-08】真相落下。暗金字迹在页边停住，像一声叹息。"
		"defeat":
			return "【0-08】失败被写入纸背。墨痕爬行，遮住了旁人的名字。"
		"rest":
			return "【0-08】休整写进页边：呼吸平稳了一些，注视却未退尽。"
		"wipe", "spirit":
			return "【灵性】指尖发热，墨渍退开一线——字迹重新可读。"
		_:
			return "【0-08】阿勒苏霍德之笔落在页边——墨迹已改写这一叶。"


func _schedule_auto_flip_next() -> void:
	_pending_auto_flip = true
	var tree := get_tree()
	if tree == null:
		call_deferred("_try_auto_flip_next")
		return
	## Wait out the longer pen overlay before the page turns.
	var on_delay := func() -> void:
		if is_instance_valid(self):
			_try_auto_flip_next()
	tree.create_timer(2.35).timeout.connect(on_delay, CONNECT_ONE_SHOT)


func _on_prev_page() -> void:
	if is_flipping or _current_spread_idx <= 0:
		return
	_request_desk_flip(-1)


func _on_next_page() -> void:
	if is_flipping or _current_spread_idx >= _spread_list.size() - 1:
		return
	if not _can_advance_from(_current_spread_idx):
		_resist_flip("本叶命运未写完——书页自己合了回去。")
		return
	_request_desk_flip(1)


func _resist_flip(whisper: String) -> void:
	TableSfx.play(self, TableSfx.KIND_SEAL)
	## Desk P0: bounce the 3D leaf; do not shake the hidden 2D book shell.
	if is_instance_valid(_desk_stage):
		_desk_bounce(whisper)
		return
	_set_status(whisper)
	if not is_instance_valid(_book_root):
		return
	_book_root.pivot_offset = _book_root.size * 0.5
	if is_instance_valid(_mold_layer):
		_mold_layer.color.a = minf(0.55, _mold_layer.color.a + 0.18)
	_play_ink_seal_coagulate()
	var tween := create_tween()
	tween.tween_property(_book_root, "rotation_degrees", -2.4, 0.12)
	tween.tween_property(_book_root, "rotation_degrees", 1.6, 0.14)
	tween.tween_property(_book_root, "rotation_degrees", 0.0, 0.18)
	if is_instance_valid(_mold_layer):
		tween.parallel().tween_property(_mold_layer, "color:a", _mold_layer.color.a * 0.7, 0.45)


func _play_ink_seal_coagulate() -> void:
	## Ink blooms wet, then hardens into a stuck seal on the page.
	if not is_instance_valid(_ink_seal_fx):
		return
	_ink_seal_fx.visible = true
	_ink_seal_fx.pivot_offset = _ink_seal_fx.size * 0.5
	_ink_seal_fx.scale = Vector2(0.55, 0.55)
	_ink_seal_fx.color = Color(0.35, 0.10, 0.06, 0.0)
	_ink_seal_fx.rotation_degrees = -8.0
	if is_instance_valid(_ink_seal_label):
		_ink_seal_label.add_theme_color_override("font_color", Color(0.85, 0.62, 0.28, 0.0))
	var tween := create_tween()
	tween.set_parallel(true)
	## Wet bloom.
	tween.tween_property(_ink_seal_fx, "color:a", 0.42, 0.18)
	tween.tween_property(_ink_seal_fx, "scale", Vector2(1.35, 1.2), 0.28).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(_ink_seal_label):
		tween.tween_method(
			func(a: float) -> void:
				if is_instance_valid(_ink_seal_label):
					_ink_seal_label.add_theme_color_override(
						"font_color",
						Color(0.85, 0.62, 0.28, a)
					),
			0.0,
			0.85,
			0.22
		)
	tween.chain().set_parallel(true)
	## Coagulate: shrink, darken, stick.
	tween.tween_property(_ink_seal_fx, "scale", Vector2(1.0, 1.0), 0.38).set_trans(Tween.TRANS_BACK)
	tween.tween_property(
		_ink_seal_fx,
		"color",
		Color(0.08, 0.03, 0.02, 0.72),
		0.38
	)
	tween.tween_property(_ink_seal_fx, "rotation_degrees", 0.0, 0.38)
	if is_instance_valid(_ink_seal_label):
		tween.tween_method(
			func(a: float) -> void:
				if is_instance_valid(_ink_seal_label):
					_ink_seal_label.add_theme_color_override(
						"font_color",
						Color(0.72, 0.48, 0.22, a)
					),
			0.85,
			1.0,
			0.3
		)
	tween.chain().tween_interval(0.55)
	tween.chain().set_parallel(true)
	tween.tween_property(_ink_seal_fx, "color:a", 0.0, 0.45)
	if is_instance_valid(_ink_seal_label):
		tween.tween_method(
			func(a: float) -> void:
				if is_instance_valid(_ink_seal_label):
					_ink_seal_label.add_theme_color_override(
						"font_color",
						Color(0.72, 0.48, 0.22, a)
					),
			1.0,
			0.0,
			0.4
		)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(_ink_seal_fx):
			_ink_seal_fx.visible = false
			_ink_seal_fx.scale = Vector2.ONE
	)


func _try_auto_flip_next() -> void:
	if not _pending_auto_flip:
		return
	_pending_auto_flip = false
	if is_flipping or _current_spread_idx >= _spread_list.size() - 1:
		return
	if not _can_advance_from(_current_spread_idx):
		return
	## Settlement turns the leaf on the hinge, same as a hand would.
	_request_desk_flip(1)


func _flip_to(target_idx: int, forward: bool, duration: float = -1.0) -> void:
	if is_flipping:
		return
	if target_idx < 0 or target_idx >= _spread_list.size():
		return
	if target_idx == _current_spread_idx:
		return
	if forward and not _can_open_spread(target_idx):
		_clear_index_chain()
		_desk_bounce("后面的页还被夜色封着——墨封未解。")
		return
	## Desk P0: never fall back to the 2D slide / Flip3D flash path.
	if is_instance_valid(_desk_stage):
		_request_desk_flip(1 if forward else -1)
		return
	is_flipping = true
	_flip_forward = forward
	_flip_duration = INDEX_FLIP_DURATION if duration < 0.0 and _index_chain_active else (
		FLIP_DURATION if duration < 0.0 else duration
	)
	_set_index_open(false)
	_refresh_nav_buttons()
	_stop_glow()
	TableSfx.play(self, TableSfx.KIND_FLIP)
	page_flip_started.emit()

	var target: Dictionary = _spread_list[target_idx]
	_set_page_next_for_flip()
	_render_spread(_page_next_left, _page_next_right, target)
	## Flip preview must never steal clicks; interactions are locked anyway.
	_set_tree_mouse_filter(_page_next, Control.MOUSE_FILTER_IGNORE)

	var dur := _flip_duration
	_play_flip_3d(forward, dur)
	var out_x := FLIP_OFFSET if forward else -FLIP_OFFSET
	var in_x := -FLIP_OFFSET if forward else FLIP_OFFSET
	_page_current.position.x = 0.0
	_page_current.modulate.a = 1.0
	_page_current.scale = Vector2.ONE
	_page_current.rotation_degrees = 0.0
	_page_current.pivot_offset = Vector2(
		_page_current.size.x * (0.92 if forward else 0.08),
		_page_current.size.y * 0.5
	)
	_page_next.position.x = in_x
	_page_next.modulate.a = 0.0
	_page_next.scale = Vector2(0.92, 0.96)
	_page_next.rotation_degrees = -4.5 if forward else 4.5
	_page_next.pivot_offset = Vector2(
		_page_next.size.x * (0.08 if forward else 0.92),
		_page_next.size.y * 0.5
	)
	_edge_shadow.color.a = 0.0
	if is_instance_valid(_flip_curl):
		_flip_curl.color.a = 0.0
		_flip_curl.anchor_left = 0.48 if forward else 0.46
		_flip_curl.anchor_right = 0.58 if forward else 0.54

	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()
	_flip_tween = create_tween()
	_flip_tween.set_parallel(true)
	_flip_tween.tween_property(_page_current, "position:x", out_x, dur).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(_page_current, "modulate:a", 0.0, dur).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(
		_page_current,
		"scale",
		Vector2(0.88, 0.94),
		dur
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(
		_page_current,
		"rotation_degrees",
		6.5 if forward else -6.5,
		dur
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(_page_next, "position:x", 0.0, dur).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(_page_next, "modulate:a", 1.0, dur).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(_page_next, "scale", Vector2.ONE, dur).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(_page_next, "rotation_degrees", 0.0, dur).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_method(_set_edge_shadow_progress, 0.0, 1.0, dur)
	_flip_tween.chain().tween_callback(func() -> void:
		_finish_flip(target_idx)
	)


func _set_edge_shadow_progress(progress: float) -> void:
	## Pseudo-3D mid-flip: shade peaks + curl band slides across the spine.
	var arch := sin(progress * PI)
	_edge_shadow.color.a = arch * 0.58
	if is_instance_valid(_flip_curl):
		_flip_curl.color.a = arch * 0.48
		if _flip_forward:
			_flip_curl.anchor_left = lerpf(0.52, 0.18, progress)
			_flip_curl.anchor_right = lerpf(0.62, 0.32, progress)
		else:
			_flip_curl.anchor_left = lerpf(0.38, 0.68, progress)
			_flip_curl.anchor_right = lerpf(0.48, 0.82, progress)


func _finish_flip(target_idx: int) -> void:
	_current_spread_idx = target_idx
	_page_current.position.x = 0.0
	_page_current.modulate.a = 1.0
	_page_current.scale = Vector2.ONE
	_page_current.rotation_degrees = 0.0
	_page_next.scale = Vector2.ONE
	_page_next.rotation_degrees = 0.0
	_edge_shadow.color.a = 0.0
	if is_instance_valid(_flip_curl):
		_flip_curl.color.a = 0.0
	_clear_spread(_page_next_left, _page_next_right)
	_set_page_next_idle()
	## Unlock before re-render so clue hit targets are built enabled.
	is_flipping = false
	_command_busy = false
	_render_spread(_page_current_left, _page_current_right, _current_spread())
	_sync_desk_spread()
	_refresh_chrome()
	_refresh_nav_buttons()
	_start_glow()
	page_flip_finished.emit()
	if _index_chain_active:
		call_deferred("_advance_index_chain")


func _on_index() -> void:
	if is_flipping:
		return
	var open := is_instance_valid(_index_panel) and _index_panel.modulate.a < 0.4
	_set_index_open(open)


func _rebuild_index_list() -> void:
	for child in _index_list.get_children():
		child.queue_free()
	var open_limit := _furthest_open_idx()
	for index in range(_spread_list.size()):
		var spread: Dictionary = _spread_list[index]
		var done := bool(spread.get("is_main_complete", false))
		var current := index == _current_spread_idx
		var reachable := index <= open_limit or index <= _current_spread_idx
		var done_count := 0
		var total_main := 0
		for clue_value in spread.get("clues", []):
			if not clue_value is Dictionary:
				continue
			if String(clue_value.get("kind", "main")) != "main":
				continue
			total_main += 1
			if int(clue_value.get("state", 0)) == DiaryCatalog.STATE_COMPLETED:
				done_count += 1
		var progress := "%d/%d" % [done_count, maxi(1, total_main)]
		var label := "其%s · %s（%s）" % [
			String(spread.get("spread_label_zh", str(index + 1))),
			String(spread.get("title_zh", "")),
			progress,
		]
		if current:
			label = "▸ 正在读 · " + label
		elif done:
			label = "✓ 已写完 · " + label
		elif not reachable:
			label = "墨封 · " + label
		else:
			label = "· 可翻回 · " + label
		var button := Button.new()
		button.text = label
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 38)
		button.disabled = not reachable
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_color_override(
			"font_color",
			C_GOLD if current else (UiTheme.C_MUTED if not reachable else UiTheme.C_PAPER)
		)
		button.add_theme_stylebox_override(
			"normal",
			UiTheme.style_box(Color(0.12, 0.09, 0.05, 0.55), Color(0.45, 0.35, 0.2, 0.5), 1, 3)
		)
		button.add_theme_stylebox_override(
			"hover",
			UiTheme.style_box(Color(0.18, 0.13, 0.07, 0.7), C_GOLD, 1, 3)
		)
		button.add_theme_stylebox_override(
			"disabled",
			UiTheme.style_box(Color(0.08, 0.06, 0.04, 0.4), Color(0.3, 0.25, 0.18, 0.35), 1, 3)
		)
		var target := index
		button.pressed.connect(func() -> void:
			_index_jump(target)
		)
		_index_list.add_child(button)


func _rebuild_mold_blotches(mold_ratio: float) -> void:
	if not is_instance_valid(_mold_layer):
		return
	for child in _mold_layer.get_children():
		child.queue_free()
	var count := int(floor(mold_ratio * 7.0))
	if count <= 0:
		return
	## Deterministic blotches from ratio so refresh does not jitter every frame.
	var seed_v := int(mold_ratio * 1000.0)
	for i in range(count):
		var blot := ColorRect.new()
		blot.name = "MoldBlotch_%d" % i
		blot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h := 0.08 + float((seed_v + i * 37) % 17) * 0.01
		var w := 0.10 + float((seed_v + i * 53) % 19) * 0.01
		blot.set_anchor(SIDE_LEFT, float((seed_v + i * 17) % 80) * 0.01)
		blot.set_anchor(SIDE_TOP, float((seed_v + i * 29) % 75) * 0.01)
		blot.set_anchor(SIDE_RIGHT, minf(1.0, blot.anchor_left + w))
		blot.set_anchor(SIDE_BOTTOM, minf(1.0, blot.anchor_top + h))
		blot.offset_left = 0
		blot.offset_top = 0
		blot.offset_right = 0
		blot.offset_bottom = 0
		blot.color = Color(0.05, 0.01, 0.01, 0.18 + mold_ratio * 0.22)
		_mold_layer.add_child(blot)


func _index_jump(target_idx: int) -> void:
	if is_flipping or _index_chain_active:
		return
	if target_idx < 0 or target_idx >= _spread_list.size():
		return
	if target_idx == _current_spread_idx:
		_set_index_open(false)
		return
	if not _can_open_spread(target_idx):
		_resist_flip("那一叶仍被墨封着——纸页自己合了回去。")
		return
	_set_index_open(false)
	_set_status("墨痕牵引视线……")
	_play_ink_trail()
	## Leaf-by-leaf only — never teleport across sealed or unread middles.
	_index_chain = _build_index_chain(_current_spread_idx, target_idx)
	if _index_chain.is_empty():
		_resist_flip("中间仍有墨封——纸页自己合了回去。")
		return
	_index_chain_active = true
	_index_chain_step = clampf(
		INDEX_CHAIN_BUDGET / float(maxi(1, _index_chain.size())),
		INDEX_DESK_FLIP_MIN,
		INDEX_DESK_FLIP_DURATION
	)
	_advance_index_chain()


func _build_index_chain(from_idx: int, to_idx: int) -> Array[int]:
	var steps: Array[int] = []
	if from_idx == to_idx:
		return steps
	var step := 1 if to_idx > from_idx else -1
	var cursor := from_idx + step
	while true:
		## Forward chain must stay within open leaves; abort if a middle is sealed.
		if step > 0 and not _can_open_spread(cursor):
			return [] as Array[int]
		steps.append(cursor)
		if cursor == to_idx:
			break
		cursor += step
		if steps.size() > _spread_list.size() + 2:
			return [] as Array[int]
	return steps


func _clear_index_chain() -> void:
	_index_chain.clear()
	_index_chain_active = false


func _advance_index_chain() -> void:
	if not _index_chain_active:
		return
	if is_flipping:
		return
	if _index_chain.is_empty():
		_index_chain_active = false
		_set_status("墨痕落定于此叶。")
		_refresh_nav_buttons()
		return
	var next_idx: int = _index_chain.pop_front()
	if next_idx < 0 or next_idx >= _spread_list.size():
		_clear_index_chain()
		return
	if next_idx == _current_spread_idx:
		call_deferred("_advance_index_chain")
		return
	var forward := next_idx > _current_spread_idx
	if forward and not _can_open_spread(next_idx):
		_clear_index_chain()
		_resist_flip("那一叶仍被墨封着——纸页自己合了回去。")
		return
	## Index hops turn one leaf at a time, slower; the chain advances when the
	## stage reports the leaf settled (restores the cross-leaf slow turn).
	_request_desk_flip(1 if forward else -1, _index_chain_step)


func _play_ink_trail() -> void:
	if not is_instance_valid(_ink_trail):
		return
	_ink_trail.visible = true
	_ink_trail.color.a = 0.0
	_ink_trail.anchor_top = 0.18
	_ink_trail.anchor_bottom = 0.28
	var tween := create_tween()
	tween.tween_property(_ink_trail, "color:a", 0.38, 0.18)
	tween.parallel().tween_property(_ink_trail, "anchor_bottom", 0.82, 0.55).set_trans(
		Tween.TRANS_SINE
	)
	tween.tween_property(_ink_trail, "color:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		if is_instance_valid(_ink_trail):
			_ink_trail.visible = false
	)


func _on_hub() -> void:
	if is_flipping:
		return
	is_flipping = true
	_refresh_nav_buttons()
	TableSfx.play(self, TableSfx.KIND_SEAL)
	var tween := create_tween()
	tween.tween_property(_book_root, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		is_flipping = false
		hub_requested.emit()
	)


func _start_glow() -> void:
	_stop_glow()
	if _glow_targets.is_empty() or is_flipping:
		return
	_glow_tween = create_tween()
	_glow_tween.set_loops()
	_glow_tween.tween_method(_set_glow, 0.45, 1.0, 0.95)
	_glow_tween.tween_method(_set_glow, 1.0, 0.45, 0.95)


func _set_glow(alpha: float) -> void:
	## Eye-level pulse on margin ink edges (not full-rect cards).
	for target in _glow_targets:
		if is_instance_valid(target) and target is ColorRect:
			var edge := target as ColorRect
			var c: Color = edge.color
			var is_wipe := c.b > c.r and c.b > 0.5
			var base := 0.55 if is_wipe else 0.48
			var span := 0.40 if is_wipe else 0.42
			edge.color = Color(c.r, c.g, c.b, base + span * alpha)


func _stop_glow() -> void:
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = null
