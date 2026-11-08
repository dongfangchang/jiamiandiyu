extends RefCounted

const C_BG := Color("#11120d")
const C_SURFACE := Color("#1c1b15")
const C_SURFACE_RAISED := Color("#242119")
const C_PAPER := Color("#d8c29a")
const C_PAPER_DEEP := Color("#af9165")
const C_TEXT := Color("#e8dfc9")
const C_MUTED := Color("#9f967f")
const C_GOLD := Color("#b99750")
const C_LINE := Color("#3a3731")
const C_DANGER := Color("#7a2828")
const C_DANGER_TEXT := Color("#d8b4a8")
const C_FOG := Color("#788079")


static func build_theme() -> Theme:
	var result := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei UI",
		"Microsoft YaHei",
		"Noto Sans CJK SC",
		"Source Han Sans SC",
	])
	result.default_font = font
	result.default_font_size = 16
	return result


static func style_box(
	background: Color,
	border: Color = C_LINE,
	border_width: int = 1,
	radius: int = 8
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


static func panel(background: Color = C_SURFACE, border: Color = C_LINE) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", style_box(background, border, 1, 8))
	return result


static func padded_panel(
	content: Control,
	margin: int = 14,
	background: Color = C_SURFACE,
	border: Color = C_LINE
) -> PanelContainer:
	var result := panel(background, border)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", margin)
	pad.add_theme_constant_override("margin_top", margin)
	pad.add_theme_constant_override("margin_right", margin)
	pad.add_theme_constant_override("margin_bottom", margin)
	pad.add_child(content)
	result.add_child(pad)
	return result


static func label(text_value: String, font_size: int = 16, color: Color = C_TEXT) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


static func center_label(
	text_value: String,
	font_size: int = 16,
	color: Color = C_TEXT
) -> Label:
	var result := label(text_value, font_size, color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result


static func wrapped_label(
	text_value: String,
	font_size: int = 14,
	color: Color = C_MUTED
) -> Label:
	var result := label(text_value, font_size, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


static func badge(text_value: String, foreground: Color, border: Color) -> Label:
	var result := center_label(text_value, 12, foreground)
	result.add_theme_stylebox_override("normal", style_box(C_SURFACE, border, 1, 5))
	result.add_theme_constant_override("margin_left", 9)
	result.add_theme_constant_override("margin_right", 9)
	result.add_theme_constant_override("margin_top", 3)
	result.add_theme_constant_override("margin_bottom", 3)
	return result


static func button(
	text_value: String,
	on_pressed: Callable,
	enabled: bool = true,
	min_width: float = 132.0,
	primary: bool = false
) -> Button:
	var result := Button.new()
	result.text = text_value
	result.disabled = not enabled
	result.custom_minimum_size = Vector2(min_width, 40)
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_font_size_override("font_size", 15)
	result.add_theme_color_override("font_color", C_TEXT if not primary else Color("#fff8e8"))
	result.add_theme_color_override("font_hover_color", Color("#fff4dc"))
	result.add_theme_color_override("font_disabled_color", C_MUTED)
	var normal_background := C_SURFACE_RAISED if not primary else Color("#4a3b1d")
	var normal_border := C_LINE if not primary else C_GOLD
	result.add_theme_stylebox_override("normal", style_box(normal_background, normal_border, 1, 6))
	result.add_theme_stylebox_override("hover", style_box(
		Color("#302c23") if not primary else Color("#685329"),
		C_GOLD,
		2,
		6
	))
	result.add_theme_stylebox_override("pressed", style_box(Color("#171711"), C_GOLD, 2, 6))
	result.add_theme_stylebox_override("focus", style_box(Color(0, 0, 0, 0), Color("#f3d58a"), 2, 6))
	result.add_theme_stylebox_override("disabled", style_box(Color("#181711"), Color("#514a3b"), 1, 6))
	result.add_theme_constant_override("outline_size", 2)
	result.pressed.connect(on_pressed)
	return result


static func meter(
	title: String,
	value_text: String,
	color: Color,
	min_width: float = 112.0
) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", 2)
	result.custom_minimum_size = Vector2(min_width, 48)
	result.add_child(label(title, 12, C_MUTED))
	result.add_child(label(value_text, 22, color))
	return result


static func add_background(
	root: Control,
	texture_path: String,
	fallback_color: Color = C_BG,
	dim: float = 0.0
) -> void:
	var fallback := ColorRect.new()
	fallback.color = fallback_color
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fallback)

	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		var texture := TextureRect.new()
		texture.texture = load(texture_path)
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(texture)

	if dim > 0.0:
		var tint := ColorRect.new()
		tint.color = Color(C_BG, clampf(dim, 0.0, 1.0))
		tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(tint)


static func readable_id(value: String) -> String:
	if value.is_empty():
		return "未知"
	return value.replace("card.", "").replace("skill.", "").replace("artifact.", "").replace("_", " ")
