extends Node

## One prepared spread for the desk book: the left (illustration) and right
## (ink + seal) page SubViewports plus the controls inside them.
##
## The stage keeps three of these in a ring (prev / current / next). A turn
## binds the meshes to two pairs at once and the commit only swaps which pair
## is "current", so no page tree is rebuilt and no texture is loaded at the
## moment the leaf lands.

signal wax_pressed
signal rune_pressed(index: int)
signal side_sticker_pressed

const DiaryCatalog := preload("res://src/ui/diary_ui_catalog.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const Ui := preload("res://src/ui/mask_ui_theme.gd")
const PropCatalog := preload("res://src/ui/prop_ui_catalog.gd")

const PAGE_VP_SIZE := Vector2i(512, 720)
const SEAL_SIZE := Vector2(82, 82)

var left_vp: SubViewport
var right_vp: SubViewport
var left_art: TextureRect
var title_label: Label
var folio_label: Label
var ink_label: Label
var wax_button: Button
var wax_art: TextureRect
var rune_strip: Container
var rune_buttons: Array[Button] = []
var rune_art: Array[Node] = []
var side_sticker: Button

## The spread this pair currently shows ({} = blank leaf).
var spread: Dictionary = {}
## Art path whose texture is on left_art ("" = paper placeholder).
var shown_art_path := ""
## Art path the pair is waiting on (threaded load still in flight).
var pending_art_path := ""

var _grain: Texture2D
var _seal_textures: Dictionary = {}
var _redraw_frames := 0


func setup(grain: Texture2D, seal_textures: Dictionary) -> void:
	_grain = grain
	_seal_textures = seal_textures
	left_vp = _make_page_viewport("LeftPageViewport")
	right_vp = _make_page_viewport("RightPageViewport")
	add_child(left_vp)
	add_child(right_vp)
	_build_left()
	_build_right()


func spread_key() -> int:
	## Leaves are identified by their position in the volume; -1 = blank.
	if spread.is_empty():
		return -1
	return int(spread.get("spread_index", spread.get("page_index", -1)))


func primary_clue() -> Dictionary:
	var clues: Array = spread.get("clues", [])
	if clues.size() > 0 and clues[0] is Dictionary:
		return clues[0]
	return {}


func art_path() -> String:
	var clue := primary_clue()
	return String(spread.get("left_art_path", clue.get("left_art_path", "")))


func state() -> int:
	var clue := primary_clue()
	return int(spread.get("state", clue.get("state", DiaryCatalog.STATE_LOCKED)))


func set_update_mode(mode: int) -> void:
	for vp in [left_vp, right_vp]:
		if is_instance_valid(vp):
			vp.render_target_update_mode = mode


func request_redraw() -> void:
	## Static page: render once after a content change. A pair that is
	## already UPDATE_ALWAYS keeps updating. Containers may re-sort a frame
	## later (autowrap height), so the stage repeats it via tick_redraw().
	_redraw_frames = 2
	_redraw_once()


func tick_redraw() -> void:
	if _redraw_frames <= 0:
		return
	_redraw_frames -= 1
	_redraw_once()


func _redraw_once() -> void:
	for vp in [left_vp, right_vp]:
		if is_instance_valid(vp) and vp.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func fill(new_spread: Dictionary) -> void:
	## Text, seal and runes only; the illustration is set by set_art().
	spread = new_spread.duplicate(true)
	var clue := primary_clue()
	title_label.text = String(spread.get("title_zh", clue.get("title_zh", "")))
	if spread.is_empty():
		folio_label.text = ""
	else:
		var idx := int(spread.get("spread_index", spread.get("page_index", 0))) + 1
		folio_label.text = "其 %d 叶" % idx
	ink_label.text = String(spread.get("ink_zh", clue.get("ink_zh", clue.get("text_zh", ""))))
	## 0-08 rewrite reads as warm gold on the page; Roselle stays brown ink.
	if bool(clue.get("rewritten_by_pen", false)):
		ink_label.add_theme_color_override("font_color", Color(0.62, 0.42, 0.12))
	else:
		ink_label.add_theme_color_override("font_color", Color(0.16, 0.09, 0.05))
	var st := state()
	match st:
		DiaryCatalog.STATE_AVAILABLE:
			wax_button.text = "启"
			wax_button.modulate = Color(1, 1, 1, 1)
			ink_label.modulate = Color(1, 1, 1, 1)
		DiaryCatalog.STATE_COMPLETED:
			wax_button.text = "阅"
			wax_button.modulate = Color(0.75, 0.7, 0.55)
			ink_label.modulate = Color(1, 1, 1, 0.92)
		_:
			wax_button.text = "封"
			wax_button.modulate = Color(0.45, 0.4, 0.38)
			## Locked leaf: ink reads drowned / sealed.
			ink_label.modulate = Color(0.55, 0.5, 0.48, 0.7)
	wax_art.texture = _seal_textures.get(st) as Texture2D
	wax_art.visible = wax_art.texture != null and not spread.is_empty()
	wax_button.visible = not wax_art.visible and not spread.is_empty()
	_refresh_runes(st)
	_refresh_side_sticker()
	request_redraw()


func set_art(path: String, texture: Texture2D) -> void:
	shown_art_path = path if texture != null else ""
	if texture == null:
		left_art.texture = _grain
		left_art.modulate = Color(0.95, 0.9, 0.82, 1.0)
	else:
		left_art.texture = texture
		## Lighting carries the leaf now; a boost here just blows the wash out.
		left_art.modulate = Color.WHITE
	left_art.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if texture != null and path.get_base_dir() == SceneCatalog.DIARY_ART_DIR
		else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)
	request_redraw()


func rune_hint(index: int, st: int) -> String:
	var state_zh := "墨封"
	match st:
		DiaryCatalog.STATE_AVAILABLE:
			state_zh = "可启"
		DiaryCatalog.STATE_COMPLETED:
			state_zh = "已阅"
	var marks: PackedStringArray = ["本叶", "启印", "阅印", "封印"]
	var mark: String = marks[index] if index >= 0 and index < marks.size() else "符"
	return "%s · %s" % [mark, state_zh]


func _refresh_runes(st: int) -> void:
	if not is_instance_valid(rune_strip):
		return
	## Four marks: 0=本叶状态, 1=可启, 2=已阅, 3=墨封 — lit by clue state (P1).
	var lit := [
		st == DiaryCatalog.STATE_AVAILABLE or st == DiaryCatalog.STATE_COMPLETED,
		st == DiaryCatalog.STATE_AVAILABLE,
		st == DiaryCatalog.STATE_COMPLETED,
		st == DiaryCatalog.STATE_LOCKED,
	]
	var base := Color(0.28, 0.22, 0.18, 0.5)
	match st:
		DiaryCatalog.STATE_AVAILABLE:
			base = Color(0.42, 0.31, 0.18, 0.95)
		DiaryCatalog.STATE_COMPLETED:
			base = Color(0.32, 0.55, 0.3, 0.9)
	for i in range(rune_buttons.size()):
		var rune := rune_buttons[i]
		if not is_instance_valid(rune):
			continue
		var style := rune.get_theme_stylebox("normal") as StyleBoxFlat
		if style == null:
			style = StyleBoxFlat.new()
			rune.add_theme_stylebox_override("normal", style)
			rune.add_theme_stylebox_override("hover", style)
			rune.add_theme_stylebox_override("pressed", style)
		var is_lit: bool = lit[i] if i < lit.size() else false
		## With medallion art present the plate must step back, or the painted
		## token sits on a coloured disc. Lit/unlit then reads on the art.
		var has_art: bool = i < rune_art.size() and is_instance_valid(rune_art[i])
		if is_lit:
			style.bg_color = Color(0, 0, 0, 0) if has_art else base
			style.border_color = (
				Color(0, 0, 0, 0)
				if has_art
				else Color(base.r + 0.15, base.g + 0.1, base.b + 0.05, 0.9)
			)
			rune.modulate = Color(1, 1, 1, 1)
		else:
			style.bg_color = Color(0, 0, 0, 0) if has_art else Color(0.28, 0.22, 0.18, 0.4)
			style.border_color = (
				Color(0, 0, 0, 0) if has_art else Color(0.4, 0.32, 0.22, 0.35)
			)
			## Unlit tokens read as dimmed metal rather than vanishing.
			rune.modulate = Color(0.62, 0.6, 0.58, 0.5) if has_art else Color(1, 1, 1, 0.55)
		rune.tooltip_text = rune_hint(i, st)


func _refresh_side_sticker() -> void:
	if not is_instance_valid(side_sticker):
		return
	var notes: Array = spread.get("side_notes", [])
	if notes.is_empty():
		side_sticker.visible = false
		return
	side_sticker.visible = true
	side_sticker.tooltip_text = "旁支 %d" % notes.size()


func _make_page_viewport(node_name: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.name = node_name
	vp.size = PAGE_VP_SIZE
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.disable_3d = true
	return vp


func _page_parchment(node_name: String, mirror: bool) -> TextureRect:
	## Photographed sheet as the leaf surface. Mirrored on the left page so the
	## spread does not read as the same stamp printed twice. Null when the art
	## is absent, and the caller falls back to the procedural grain tile.
	var sheet := PropCatalog.texture("parchment_sheet")
	if sheet == null:
		return null
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture = sheet
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	## The sheet has deckled edges; COVERED would crop them off, so stretch it
	## to the leaf and let the painted edge land on the page border.
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.flip_h = mirror
	## The photographed sheet is near-white; under the key light it blew out.
	## Modulate it back to parchment so ink keeps its contrast.
	tr.modulate = Color(0.62, 0.57, 0.49)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _paper(root: Control, sheet_name: String, grain_name: String, mirror: bool) -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.74, 0.67, 0.52)
	root.add_child(bg)
	var sheet := _page_parchment(sheet_name, mirror)
	if sheet != null:
		root.add_child(sheet)
	elif _grain != null:
		var grain := TextureRect.new()
		grain.name = grain_name
		grain.texture = _grain
		grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		grain.modulate = Color(0.76, 0.75, 0.73)
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(grain)


func _build_left() -> void:
	var left_root := Control.new()
	left_root.name = "LeftPageRoot"
	left_root.size = Vector2(PAGE_VP_SIZE)
	left_vp.add_child(left_root)
	_paper(left_root, "LeftPageParchment", "LeftPageGrain", true)
	## Reference: the illustration is washed straight onto the leaf and fades
	## into the paper. No dark plate, no gold border — those read as a sticker.
	var art_frame := MarginContainer.new()
	art_frame.name = "SceneArtFrame"
	art_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_frame.add_theme_constant_override("margin_left", 40)
	art_frame.add_theme_constant_override("margin_right", 52)
	art_frame.add_theme_constant_override("margin_top", 58)
	art_frame.add_theme_constant_override("margin_bottom", 72)
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_root.add_child(art_frame)
	var art_plate := Control.new()
	art_plate.name = "SceneArtPlate"
	art_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art_plate)
	left_art = TextureRect.new()
	left_art.name = "SceneArt"
	left_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	left_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_plate.add_child(left_art)
	var feather := Shader.new()
	feather.code = """shader_type canvas_item;
	void fragment() {
		vec2 edge = min(UV, 1.0 - UV);
		COLOR.a *= smoothstep(0.0, 0.028, min(edge.x, edge.y));
	}"""
	var feather_mat := ShaderMaterial.new()
	feather_mat.shader = feather
	left_art.material = feather_mat
	set_art("", null)


func _build_right() -> void:
	var right_root := Control.new()
	right_root.name = "RightPageRoot"
	right_root.size = Vector2(PAGE_VP_SIZE)
	right_root.theme = Ui.build_theme()
	right_vp.add_child(right_root)
	_paper(right_root, "RightPageParchment", "RightPageGrain", false)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 40)
	right_root.add_child(margin)
	## Reference splits the leaf: written column on the left, a rail of state
	## marks down the right margin.
	var row := HBoxContainer.new()
	row.name = "RightPageRow"
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var col := VBoxContainer.new()
	col.name = "RightPageColumn"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	row.add_child(col)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_override("font", Ui.diary_ink_font(true))
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.18, 0.1, 0.05))
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title_label)
	folio_label = Label.new()
	folio_label.name = "FolioLabel"
	folio_label.add_theme_font_size_override("font_size", 18)
	folio_label.add_theme_color_override("font_color", Color(0.42, 0.28, 0.14, 0.75))
	folio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(folio_label)

	ink_label = Label.new()
	ink_label.name = "InkLabel"
	ink_label.add_theme_font_override("font", Ui.diary_ink_font())
	ink_label.add_theme_font_size_override("font_size", 24)
	ink_label.add_theme_color_override("font_color", Color(0.16, 0.09, 0.05))
	ink_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ink_label.clip_text = true
	ink_label.max_lines_visible = 10
	ink_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	## Slight letter spacing so ≤60 字 doesn't feel like a dense system dump.
	ink_label.add_theme_constant_override("line_spacing", 6)
	col.add_child(ink_label)

	_build_wax(col)
	_build_runes(row)
	_build_side_sticker(col)


func _build_wax(col: Container) -> void:
	wax_button = Button.new()
	wax_button.name = "WaxSealButton"
	wax_button.text = "启"
	wax_button.custom_minimum_size = SEAL_SIZE
	wax_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wax_button.focus_mode = Control.FOCUS_NONE
	var seal_style := StyleBoxFlat.new()
	seal_style.bg_color = Color(0.45, 0.13, 0.135)
	seal_style.corner_radius_top_left = 54
	seal_style.corner_radius_top_right = 54
	seal_style.corner_radius_bottom_left = 54
	seal_style.corner_radius_bottom_right = 54
	seal_style.border_width_left = 2
	seal_style.border_width_top = 2
	seal_style.border_width_right = 2
	seal_style.border_width_bottom = 2
	seal_style.border_color = Color(0.35, 0.08, 0.06, 0.9)
	wax_button.add_theme_stylebox_override("normal", seal_style)
	seal_style.shadow_color = Color(0.12, 0.05, 0.04, 0.36)
	seal_style.shadow_offset = Vector2(2, 4)
	seal_style.shadow_size = 4
	var seal_hover := seal_style.duplicate() as StyleBoxFlat
	seal_hover.bg_color = Color(0.56, 0.16, 0.16)
	wax_button.add_theme_stylebox_override("hover", seal_hover)
	wax_button.add_theme_stylebox_override("pressed", seal_style)
	wax_button.add_theme_color_override("font_color", Color(0.96, 0.86, 0.55))
	wax_button.add_theme_font_size_override("font_size", 32)
	wax_button.pressed.connect(func() -> void: wax_pressed.emit())
	## Soft drop shadow under the seal so it reads as wax on paper.
	var seal_host := Control.new()
	seal_host.name = "WaxSealHost"
	seal_host.custom_minimum_size = SEAL_SIZE + Vector2(8, 8)
	seal_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(seal_host)
	wax_button.position = Vector2(4, 4)
	wax_button.size = SEAL_SIZE
	seal_host.add_child(wax_button)
	wax_art = TextureRect.new()
	wax_art.name = "WaxSealArt"
	wax_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wax_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wax_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wax_art.position = wax_button.position
	wax_art.size = SEAL_SIZE
	wax_art.hide()
	seal_host.add_child(wax_art)


func _build_runes(row: Container) -> void:
	rune_strip = VBoxContainer.new()
	rune_strip.name = "RuneStrip"
	rune_strip.alignment = BoxContainer.ALIGNMENT_BEGIN
	rune_strip.add_theme_constant_override("separation", 14)
	rune_strip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rune_buttons.clear()
	rune_art.clear()
	var rune_glyphs: PackedStringArray = ["✶", "✦", "〄", "◎"]
	var rune_names := PropCatalog.TOKEN_LABELS
	for i in range(4):
		var cell := VBoxContainer.new()
		cell.name = "RuneCell%d" % i
		cell.add_theme_constant_override("separation", 1)
		var rune := Button.new()
		rune.name = "Rune%d" % i
		rune.text = rune_glyphs[i]
		rune.custom_minimum_size = Vector2(46, 46)
		rune.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rune.focus_mode = Control.FOCUS_NONE
		rune.flat = false
		rune.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		rune.add_theme_font_size_override("font_size", 20)
		## Real medallion art when ingested; the glyph/StyleBox stays as the
		## fallback so a missing prop degrades instead of blanking the rail.
		var token := PropCatalog.token_for_state(i)
		if token != null:
			rune.text = ""
			var art := TextureRect.new()
			art.name = "RuneArt%d" % i
			art.texture = token
			art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rune.add_child(art)
			rune_art.append(art)
		else:
			rune_art.append(null)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.32, 0.26, 0.2, 0.55)
		## Round medallions, not squares — matches the stamped-seal language.
		style.corner_radius_top_left = 23
		style.corner_radius_top_right = 23
		style.corner_radius_bottom_left = 23
		style.corner_radius_bottom_right = 23
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.45, 0.35, 0.22, 0.55)
		rune.add_theme_stylebox_override("normal", style)
		rune.add_theme_stylebox_override("hover", style)
		rune.add_theme_stylebox_override("pressed", style)
		rune.pressed.connect(func() -> void: rune_pressed.emit(i))
		cell.add_child(rune)
		var caption := Label.new()
		caption.name = "RuneCaption%d" % i
		caption.text = rune_names[i]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_size_override("font_size", 16)
		caption.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 0.85))
		cell.add_child(caption)
		rune_buttons.append(rune)
		rune_strip.add_child(cell)
	row.add_child(rune_strip)


func _build_side_sticker(col: Container) -> void:
	## Side-branch sticker (kind!=main); hidden until spread carries side_notes.
	side_sticker = Button.new()
	side_sticker.name = "SideBranchSticker"
	side_sticker.visible = false
	side_sticker.focus_mode = Control.FOCUS_NONE
	side_sticker.text = "旁"
	side_sticker.custom_minimum_size = Vector2(36, 28)
	side_sticker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	side_sticker.add_theme_font_size_override("font_size", 12)
	side_sticker.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	var sticker_style := StyleBoxFlat.new()
	sticker_style.bg_color = Color(0.82, 0.72, 0.48, 0.92)
	sticker_style.border_color = Color(0.55, 0.38, 0.16, 0.8)
	sticker_style.border_width_left = 1
	sticker_style.border_width_top = 1
	sticker_style.border_width_right = 1
	sticker_style.border_width_bottom = 1
	sticker_style.corner_radius_top_left = 2
	sticker_style.corner_radius_top_right = 2
	sticker_style.corner_radius_bottom_left = 2
	sticker_style.corner_radius_bottom_right = 2
	side_sticker.add_theme_stylebox_override("normal", sticker_style)
	side_sticker.pressed.connect(func() -> void: side_sticker_pressed.emit())
	col.add_child(side_sticker)
