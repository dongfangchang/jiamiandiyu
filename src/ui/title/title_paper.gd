extends RefCounted

## Paper-and-ink building blocks for the title station (ADR-0034 D1): the
## bookmark slip, its sub-slips, and the flat text items that are the only
## controls on them. Nothing here looks like a native button.

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const PropCatalog := preload("res://src/ui/prop_ui_catalog.gd")

const INK := Color(0.15, 0.095, 0.055)
const INK_SOFT := Color(0.30, 0.22, 0.15)
const INK_ACTIVE := Color(0.46, 0.08, 0.05)
const INK_DISABLED := Color(0.42, 0.35, 0.27)
const INK_RULE := Color(0.15, 0.095, 0.055, 0.35)
const PAPER_FALLBACK := Color(0.82, 0.73, 0.58)
const INK_FIELD := Color(0.15, 0.095, 0.055, 0.08)

const META_TEXT_ITEM := "title_text_item"

static var _ink_font: Font
static var _ink_title_font: Font


static func ink_font(is_title: bool = false) -> Font:
	if is_title:
		if _ink_title_font == null:
			_ink_title_font = UiTheme.diary_ink_font(true)
		return _ink_title_font
	if _ink_font == null:
		_ink_font = UiTheme.diary_ink_font(false)
	return _ink_font


static func ink_label(
	text_value: String,
	font_size: int,
	color: Color = INK,
	is_title: bool = false
) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ink_font(is_title))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


static func wrapped_ink(text_value: String, font_size: int, color: Color = INK) -> Label:
	var label := ink_label(text_value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(10, 0)
	return label


static func rule() -> ColorRect:
	var line := ColorRect.new()
	line.color = INK_RULE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


static func text_item(text_value: String, on_press: Callable, font_size: int = 26) -> Button:
	## A word written on the paper. Hover / focus / pressed only deepen the ink
	## and draw an ink underline; there is no plate, border or icon.
	var item := Button.new()
	item.text = text_value
	item.flat = true
	item.focus_mode = Control.FOCUS_ALL
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.set_meta(META_TEXT_ITEM, true)
	item.add_theme_font_override("font", ink_font(false))
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", INK)
	item.add_theme_color_override("font_hover_color", INK_ACTIVE)
	item.add_theme_color_override("font_focus_color", INK_ACTIVE)
	item.add_theme_color_override("font_pressed_color", INK_ACTIVE)
	item.add_theme_color_override("font_hover_pressed_color", INK_ACTIVE)
	item.add_theme_color_override("font_disabled_color", INK_DISABLED)
	var plain := _underline(Color(0, 0, 0, 0))
	var marked := _underline(INK_ACTIVE)
	item.add_theme_stylebox_override("normal", plain)
	item.add_theme_stylebox_override("disabled", plain)
	item.add_theme_stylebox_override("hover", marked)
	item.add_theme_stylebox_override("pressed", marked)
	item.add_theme_stylebox_override("hover_pressed", marked)
	item.add_theme_stylebox_override("focus", marked)
	if on_press.is_valid():
		item.pressed.connect(on_press)
	return item


static func _underline(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = color
	box.border_width_bottom = 2
	box.content_margin_left = 2
	box.content_margin_right = 2
	box.content_margin_top = 2
	box.content_margin_bottom = 4
	return box


static func slip(min_size: Vector2, margin: int = 44) -> Dictionary:
	## The DW-04 slip, nine-patched so it can stand upright and carry a menu.
	## Returns {"root": PanelContainer, "content": VBoxContainer}; the paper
	## grows with its content.
	var root := PanelContainer.new()
	var tex := PropCatalog.texture("desk_slip")
	var box: StyleBox
	if tex != null:
		var paper := StyleBoxTexture.new()
		paper.texture = tex
		paper.texture_margin_left = 48
		paper.texture_margin_right = 48
		paper.texture_margin_top = 52
		paper.texture_margin_bottom = 52
		box = paper
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = PAPER_FALLBACK
		box = flat
	box.content_margin_left = margin + 8
	box.content_margin_right = margin + 8
	box.content_margin_top = margin
	box.content_margin_bottom = margin
	root.add_theme_stylebox_override("panel", box)
	root.name = "PaperSlip"
	root.custom_minimum_size = min_size
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	root.add_child(content)
	return {"root": root, "content": content}


static func slip_shadow() -> Control:
	var tex := PropCatalog.texture("desk_slip_shadow")
	if tex == null:
		return null
	var patch := NinePatchRect.new()
	patch.name = "PaperSlipShadow"
	patch.texture = tex
	patch.patch_margin_left = 48
	patch.patch_margin_right = 48
	patch.patch_margin_top = 52
	patch.patch_margin_bottom = 52
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return patch


static func modal_sheet(host: Control, min_size: Vector2, node_name: String) -> Dictionary:
	## A second slip laid over the desk for settings / confirmations. The
	## blocker keeps clicks off the menu underneath while it is open; it only
	## dims, the desk stays in view.
	var blocker := ColorRect.new()
	blocker.name = node_name
	blocker.color = Color(0.0, 0.0, 0.0, 0.38)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(blocker)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.add_child(center)
	var sheet := slip(min_size, 52)
	center.add_child(sheet["root"])
	sheet["blocker"] = blocker
	return sheet


static func choice_row(labels: Array, selected: int, on_select: Callable, font_size: int = 22) -> HBoxContainer:
	## Mutually exclusive text choices; the chosen one stays underlined.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 18)
	var group := ButtonGroup.new()
	for index in labels.size():
		var item := text_item(String(labels[index]), Callable(), font_size)
		item.toggle_mode = true
		item.button_group = group
		item.button_pressed = index == selected
		var picked := index
		item.pressed.connect(func() -> void: on_select.call(picked))
		row.add_child(item)
	return row
