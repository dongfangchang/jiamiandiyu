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
const DeskCatalog := preload("res://src/ui/desk_world_catalog.gd")

## Page layout is authored in a 512x720 base space and rendered at
## PAGE_SCALE x that (EXPERIENCE §5.1: page viewport >= 1024x1440). Every
## page-space position, size and font goes through px() so the leaf scales
## as one piece.
const PAGE_SCALE := 2.0
const PAGE_BASE_SIZE := Vector2i(512, 720)
const PAGE_VP_SIZE := Vector2i(Vector2(PAGE_BASE_SIZE) * PAGE_SCALE)
const SEAL_SIZE := Vector2(82, 82) * PAGE_SCALE
## Base-space font sizes. On screen (1600x900 equivalent) these land at
## body >= 20, title >= 28, captions >= 15; see the desk stage metrics.
const TITLE_FONT_BASE := 36
const BODY_FONT_BASE := 28
const CAPTION_FONT_BASE := 20
const SEAL_FONT_BASE := 32
const RUNE_GLYPH_BASE := 20
const STICKER_FONT_BASE := 20
## The photographed sheet is near-white and blows out under the key light,
## so it is modulated down to parchment. SHEET_MEAN is the sheet's measured
## mean colour over the right leaf's text column; PAPER_TONE is what the
## text actually sits on, and the contrast floors are measured against it.
const SHEET_MEAN := Color(0.859, 0.763, 0.599)
const PAPER_MODULATE := Color(0.76, 0.70, 0.60)
const PAPER_TONE := SHEET_MEAN * PAPER_MODULATE
const INK_BODY := Color(0.13, 0.07, 0.04)
const INK_TITLE := Color(0.15, 0.08, 0.04)
const INK_REWRITTEN := Color(0.24, 0.11, 0.0)
const INK_CAPTION := Color(0.26, 0.16, 0.07)
## Leaf-state ink modulates; locked ink reads faded but stays above 4.5:1.
const INK_FADE_COMPLETED := Color(1, 1, 1, 0.94)
const INK_FADE_LOCKED := Color(0.9, 0.85, 0.82, 0.9)

var left_vp: SubViewport
var right_vp: SubViewport
var left_art: TextureRect
var title_label: Label
var folio_label: Label
var ink_label: Label
var wax_button: Button
var wax_art: TextureRect
var wax_caption: Label
var rune_strip: Container
var rune_buttons: Array[Button] = []
var rune_art: Array[Node] = []
var side_sticker: Button
var _margin_doodle: TextureRect
var _ink_blot: TextureRect

## The spread this pair currently shows ({} = blank leaf).
var spread: Dictionary = {}
## Art path whose texture is on left_art ("" = paper placeholder).
var shown_art_path := ""
## Art path the pair is waiting on (threaded load still in flight).
var pending_art_path := ""

var caption_labels: Array[Label] = []

var _grain: Texture2D
var _seal_textures: Dictionary = {}
var _redraw_frames := 0


static func px(base: float) -> int:
	return roundi(base * PAGE_SCALE)


static func contrast_ratio(fg: Color, bg: Color) -> float:
	## WCAG relative-luminance contrast; fg alpha is composited over bg first.
	var c := bg.lerp(Color(fg.r, fg.g, fg.b), fg.a)
	var lf := _rel_luminance(c)
	var lb := _rel_luminance(bg)
	return (maxf(lf, lb) + 0.05) / (minf(lf, lb) + 0.05)


static func _rel_luminance(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


func font_sizes() -> Dictionary:
	## Page-pixel font sizes of the readable text on the right leaf.
	return {
		"title": title_label.get_theme_font_size("font_size"),
		"body": ink_label.get_theme_font_size("font_size"),
		"caption": caption_labels.map(
			func(l: Label) -> int: return l.get_theme_font_size("font_size")
		).min(),
	}


func text_colors() -> Dictionary:
	## Effective colours of the readable text (label colour x modulate).
	var caption: Color = caption_labels[0].get_theme_color("font_color") if not caption_labels.is_empty() else INK_CAPTION
	return {
		"title": title_label.get_theme_color("font_color"),
		"body": ink_label.get_theme_color("font_color") * ink_label.modulate,
		"caption": caption,
	}


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
	## 0-08 rewrite reads as warm amber on the page; Roselle stays brown ink.
	ink_label.add_theme_color_override(
		"font_color", INK_REWRITTEN if bool(clue.get("rewritten_by_pen", false)) else INK_BODY
	)
	var st := state()
	var wax_glyph := "封"
	match st:
		DiaryCatalog.STATE_AVAILABLE:
			wax_glyph = "启"
			wax_button.modulate = Color(1, 1, 1, 1)
			ink_label.modulate = Color(1, 1, 1, 1)
		DiaryCatalog.STATE_COMPLETED:
			wax_glyph = "阅"
			wax_button.modulate = Color(0.75, 0.7, 0.55)
			ink_label.modulate = INK_FADE_COMPLETED
		_:
			wax_glyph = "封"
			wax_button.modulate = Color(0.45, 0.4, 0.38)
			## Locked leaf: ink reads drowned / sealed, yet stays legible.
			ink_label.modulate = INK_FADE_LOCKED
	wax_button.text = wax_glyph
	if is_instance_valid(wax_caption):
		wax_caption.text = wax_glyph
		wax_caption.visible = not spread.is_empty()
	wax_art.texture = _seal_textures.get(st) as Texture2D
	wax_art.visible = wax_art.texture != null and not spread.is_empty()
	wax_button.visible = not wax_art.visible and not spread.is_empty()
	_refresh_runes(st)
	_refresh_side_sticker()
	_refresh_margin_marks()
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
		if texture != null and SceneCatalog.is_diary_leaf(path)
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
	tr.modulate = PAPER_MODULATE
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
	art_frame.add_theme_constant_override("margin_left", px(40))
	art_frame.add_theme_constant_override("margin_right", px(52))
	art_frame.add_theme_constant_override("margin_top", px(58))
	art_frame.add_theme_constant_override("margin_bottom", px(72))
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
	_decorate_right_page(right_root)
	var margin := MarginContainer.new()
	margin.name = "RightPageMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", px(44))
	margin.add_theme_constant_override("margin_right", px(30))
	margin.add_theme_constant_override("margin_top", px(44))
	margin.add_theme_constant_override("margin_bottom", px(40))
	right_root.add_child(margin)
	## Reference splits the leaf: written column on the left, a rail of state
	## marks down the right margin.
	var row := HBoxContainer.new()
	row.name = "RightPageRow"
	row.add_theme_constant_override("separation", px(14))
	margin.add_child(row)
	var col := VBoxContainer.new()
	col.name = "RightPageColumn"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", px(12))
	row.add_child(col)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_override("font", Ui.diary_ink_font(true))
	title_label.add_theme_font_size_override("font_size", px(TITLE_FONT_BASE))
	title_label.add_theme_color_override("font_color", INK_TITLE)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title_label)
	folio_label = Label.new()
	folio_label.name = "FolioLabel"
	folio_label.add_theme_font_size_override("font_size", px(CAPTION_FONT_BASE))
	folio_label.add_theme_color_override("font_color", INK_CAPTION)
	folio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(folio_label)
	caption_labels.append(folio_label)

	ink_label = Label.new()
	ink_label.name = "InkLabel"
	ink_label.add_theme_font_override("font", Ui.diary_ink_font())
	ink_label.add_theme_font_size_override("font_size", px(BODY_FONT_BASE))
	ink_label.add_theme_color_override("font_color", INK_BODY)
	ink_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ink_label.clip_text = true
	ink_label.max_lines_visible = 8
	ink_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	## Slight letter spacing so ≤60 字 doesn't feel like a dense system dump.
	ink_label.add_theme_constant_override("line_spacing", px(6))
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
	seal_style.set_corner_radius_all(px(54))
	seal_style.set_border_width_all(px(2))
	seal_style.border_color = Color(0.35, 0.08, 0.06, 0.9)
	wax_button.add_theme_stylebox_override("normal", seal_style)
	seal_style.shadow_color = Color(0.12, 0.05, 0.04, 0.36)
	seal_style.shadow_offset = Vector2(px(2), px(4))
	seal_style.shadow_size = px(4)
	var seal_hover := seal_style.duplicate() as StyleBoxFlat
	seal_hover.bg_color = Color(0.56, 0.16, 0.16)
	wax_button.add_theme_stylebox_override("hover", seal_hover)
	wax_button.add_theme_stylebox_override("pressed", seal_style)
	wax_button.add_theme_color_override("font_color", Color(0.96, 0.86, 0.55))
	wax_button.add_theme_font_size_override("font_size", px(SEAL_FONT_BASE))
	wax_button.pressed.connect(func() -> void: wax_pressed.emit())
	## Soft drop shadow under the seal so it reads as wax on paper.
	var seal_host := Control.new()
	seal_host.name = "WaxSealHost"
	seal_host.custom_minimum_size = SEAL_SIZE + Vector2(px(8), px(8))
	seal_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(seal_host)
	wax_button.position = Vector2(px(4), px(4))
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
	## Caption stays readable on painted seals (ADR-0034：蜡封带文字).
	wax_caption = Label.new()
	wax_caption.name = "WaxSealCaption"
	wax_caption.text = "启"
	wax_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wax_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wax_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wax_caption.add_theme_font_override("font", Ui.diary_ink_font(true))
	wax_caption.add_theme_font_size_override("font_size", px(SEAL_FONT_BASE))
	wax_caption.add_theme_color_override("font_color", Color(0.96, 0.86, 0.55))
	wax_caption.position = wax_button.position
	wax_caption.size = SEAL_SIZE
	wax_caption.hide()
	seal_host.add_child(wax_caption)


func _decorate_right_page(root: Control) -> void:
	## DQ-04: ruled lines, header, corners (tr/bl swapped per UI-07-DQ), doodle + blot.
	## Offsets go through px() so they track PAGE_SCALE with the readability leaf.
	var lines := DeskCatalog.texture("desk.dq.ruled_lines")
	if lines != null:
		var ruled := TextureRect.new()
		ruled.name = "RuledLines"
		ruled.texture = lines
		ruled.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ruled.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ruled.stretch_mode = TextureRect.STRETCH_SCALE
		ruled.modulate = Color(1, 1, 1, 0.42)
		ruled.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(ruled)
	var header_tex := DeskCatalog.texture("desk.dq.page_header_ornament")
	if header_tex != null:
		var header := TextureRect.new()
		header.name = "PageHeaderOrnament"
		header.texture = header_tex
		header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		header.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.anchor_left = 0.12
		header.anchor_right = 0.88
		header.anchor_top = 0.015
		header.anchor_bottom = 0.015
		header.offset_top = 0.0
		header.offset_bottom = float(px(36))
		header.modulate = Color(1, 1, 1, 0.78)
		root.add_child(header)
	## File names tr/bl disagree with canvas centroids (UI-07-DQ); map by visual corner.
	_place_corner(root, "PageCornerTL", "desk.dq.page_corner_tl", 0.0, 0.0, 0.0, 0.0)
	_place_corner(root, "PageCornerTR", "desk.dq.page_corner_bl", 1.0, 0.0, 1.0, 0.0)
	_place_corner(root, "PageCornerBL", "desk.dq.page_corner_tr", 0.0, 1.0, 0.0, 1.0)
	_place_corner(root, "PageCornerBR", "desk.dq.page_corner_br", 1.0, 1.0, 1.0, 1.0)
	_margin_doodle = _place_deco(
		root, "MarginDoodle", Vector2(0.78, 0.22), Vector2(px(72), px(72))
	)
	_ink_blot = _place_deco(root, "InkBlot", Vector2(0.08, 0.72), Vector2(px(64), px(64)))


func _place_corner(
	root: Control,
	node_name: String,
	asset_id: String,
	al: float,
	at: float,
	ar: float,
	ab: float
) -> void:
	var tex := DeskCatalog.texture(asset_id)
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.anchor_left = al
	tr.anchor_top = at
	tr.anchor_right = ar
	tr.anchor_bottom = ab
	var s := float(px(56))
	var pad := float(px(4))
	if al < 0.5:
		tr.offset_left = pad
		tr.offset_right = pad + s
	else:
		tr.offset_left = -pad - s
		tr.offset_right = -pad
	if at < 0.5:
		tr.offset_top = pad
		tr.offset_bottom = pad + s
	else:
		tr.offset_top = -pad - s
		tr.offset_bottom = -pad
	tr.modulate = Color(1, 1, 1, 0.7)
	root.add_child(tr)


func _place_deco(root: Control, node_name: String, anchor: Vector2, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = node_name
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.anchor_left = anchor.x
	tr.anchor_right = anchor.x
	tr.anchor_top = anchor.y
	tr.anchor_bottom = anchor.y
	tr.offset_left = 0.0
	tr.offset_top = 0.0
	tr.offset_right = size.x
	tr.offset_bottom = size.y
	tr.modulate = Color(1, 1, 1, 0.55)
	tr.visible = false
	root.add_child(tr)
	return tr


func _refresh_margin_marks() -> void:
	if spread.is_empty():
		if is_instance_valid(_margin_doodle):
			_margin_doodle.visible = false
		if is_instance_valid(_ink_blot):
			_ink_blot.visible = false
		return
	var idx := absi(spread_key())
	if is_instance_valid(_margin_doodle):
		var doodle_id := "desk.dq.margin_doodles.%02d" % ((idx % 6) + 1)
		_margin_doodle.texture = DeskCatalog.texture(doodle_id)
		_margin_doodle.visible = _margin_doodle.texture != null
	if is_instance_valid(_ink_blot):
		var blot_id := "desk.dq.ink_blots.%02d" % ((idx % 4) + 1)
		_ink_blot.texture = DeskCatalog.texture(blot_id)
		_ink_blot.visible = _ink_blot.texture != null


func _build_runes(row: Container) -> void:
	rune_strip = VBoxContainer.new()
	rune_strip.name = "RuneStrip"
	rune_strip.alignment = BoxContainer.ALIGNMENT_BEGIN
	rune_strip.add_theme_constant_override("separation", px(10))
	rune_strip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rune_buttons.clear()
	rune_art.clear()
	var rune_glyphs: PackedStringArray = ["✶", "✦", "〄", "◎"]
	var rune_names := PropCatalog.TOKEN_LABELS
	for i in range(4):
		var cell := VBoxContainer.new()
		cell.name = "RuneCell%d" % i
		cell.add_theme_constant_override("separation", px(1))
		var rune := Button.new()
		rune.name = "Rune%d" % i
		rune.text = rune_glyphs[i]
		rune.custom_minimum_size = Vector2(px(46), px(46))
		rune.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rune.focus_mode = Control.FOCUS_NONE
		rune.flat = false
		rune.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		rune.add_theme_font_size_override("font_size", px(RUNE_GLYPH_BASE))
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
		style.set_corner_radius_all(px(23))
		style.set_border_width_all(px(2))
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
		caption.add_theme_font_override("font", Ui.diary_ink_font())
		caption.add_theme_font_size_override("font_size", px(CAPTION_FONT_BASE))
		caption.add_theme_color_override("font_color", INK_CAPTION)
		cell.add_child(caption)
		caption_labels.append(caption)
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
	side_sticker.custom_minimum_size = Vector2(px(36), px(28))
	side_sticker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	side_sticker.add_theme_font_size_override("font_size", px(STICKER_FONT_BASE))
	side_sticker.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	var sticker_style := StyleBoxFlat.new()
	sticker_style.bg_color = Color(0.82, 0.72, 0.48, 0.92)
	sticker_style.border_color = Color(0.55, 0.38, 0.16, 0.8)
	sticker_style.set_border_width_all(px(1))
	sticker_style.set_corner_radius_all(px(2))
	side_sticker.add_theme_stylebox_override("normal", sticker_style)
	side_sticker.pressed.connect(func() -> void: side_sticker_pressed.emit())
	col.add_child(side_sticker)
