extends Control

## Title station desk (ADR-0034): wood, the shut diary (DW-05), the candle
## (DW-06) and the challenge folder, seen from above. Pure picture: every node
## here ignores the mouse and owns no action. The text menu on the bookmark
## slip (start_screen) drives highlight() and play_open().

const PropCatalog := preload("res://src/ui/prop_ui_catalog.gd")

signal open_finished

const DESIGN := Vector2(1600, 900)

## Design-space rects (1600x900); anchors keep them proportional.
const PROPS := {
	"candle": {"tex": "desk_candle_lit", "rect": Rect2(70, 10, 250, 375), "rot": 0.0},
	"folder": {"tex": "desk_folder_closed", "rect": Rect2(78, 410, 330, 454), "rot": -5.0},
	"book": {"tex": "desk_book_closed", "rect": Rect2(-10, 40, 1190, 850), "rot": 0.0},
}

## Which prop answers which menu item.
const KEY_TO_PROP := {
	"continue": "book",
	"new_game": "book",
	"test_game": "book",
	"challenge": "folder",
	"quit": "candle",
}

const SHADOW_OFFSET := Vector2(10, 14)
const LIT := Color(1.35, 1.22, 1.05)

var _props: Dictionary = {}
var _glows: Dictionary = {}
var _tweens: Dictionary = {}
var _opening := false


func _ready() -> void:
	name = "TitleDeskStage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_wood()
	_build_candle_light()
	for key in ["folder", "candle", "book"]:
		_build_prop(String(key))
	_build_vignette()


func prop(key: String) -> Control:
	return _props.get(key) as Control


func prop_keys() -> Array:
	return _props.keys()


func is_lit(key: String) -> bool:
	var glow := _glows.get(key) as CanvasItem
	return glow != null and glow.modulate.a > 0.01


func highlight(menu_key: String, on: bool) -> void:
	var key := String(KEY_TO_PROP.get(menu_key, ""))
	if key.is_empty() or not _props.has(key) or _opening:
		return
	var node: Control = _props[key]
	var glow: CanvasItem = _glows.get(key)
	if _tweens.has(key) and (_tweens[key] as Tween).is_valid():
		(_tweens[key] as Tween).kill()
	if not is_inside_tree():
		node.modulate = LIT if on else Color.WHITE
		if glow != null:
			glow.modulate.a = 1.0 if on else 0.0
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(node, "modulate", LIT if on else Color.WHITE, 0.16)
	if glow != null:
		tween.tween_property(glow, "modulate:a", 1.0 if on else 0.0, 0.16)
	_tweens[key] = tween


func is_opening() -> bool:
	return _opening


func play_open(menu_key: String) -> bool:
	## The chosen object is pushed toward the viewer; the router's own fade
	## follows. The desk itself never fades and nothing sits on top of it.
	var key := String(KEY_TO_PROP.get(menu_key, ""))
	if _opening or key.is_empty() or not _props.has(key) or not is_inside_tree():
		return false
	_opening = true
	var node: Control = _props[key]
	node.pivot_offset = node.size * 0.5
	var toward := (size * 0.5 - node.get_rect().get_center()) * 0.25
	var tween := create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector2(1.14, 1.14), 0.42) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position", node.position + toward, 0.42) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate", LIT, 0.2)
	tween.chain().tween_callback(func() -> void:
		_opening = false
		open_finished.emit()
	)
	return true


func reset_open() -> void:
	_opening = false
	for key in _props.keys():
		var node: Control = _props[key]
		node.scale = Vector2.ONE
		_apply_rect(node, PROPS[key]["rect"])
		node.modulate = Color.WHITE
		var glow: CanvasItem = _glows.get(key)
		if glow != null:
			glow.modulate.a = 0.0


func _build_wood() -> void:
	var wood := TextureRect.new()
	wood.name = "DeskWood"
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wood.texture = PropCatalog.texture("desk_wood")
	wood.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wood.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wood.self_modulate = Color(0.62, 0.55, 0.49)
	wood.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(wood)


func _build_candle_light() -> void:
	## Warm pool from the candle, the scene's only light source.
	var light := TextureRect.new()
	light.name = "CandlePool"
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light.texture = _radial(Color(1.0, 0.72, 0.36, 0.34), Color(1.0, 0.6, 0.25, 0.0))
	light.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	light.stretch_mode = TextureRect.STRETCH_SCALE
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = material
	_apply_rect(light, Rect2(-560, -560, 1450, 1450))
	add_child(light)


func _build_prop(key: String) -> void:
	var spec: Dictionary = PROPS[key]
	var tex := PropCatalog.texture(String(spec["tex"]))
	if tex == null:
		return
	var rect: Rect2 = spec["rect"]
	var shadow_tex := PropCatalog.texture(String(spec["tex"]) + "_shadow")
	if shadow_tex != null:
		var shadow := _texture_node("TitleProp_%s_shadow" % key, shadow_tex)
		shadow.rotation_degrees = float(spec["rot"])
		shadow.modulate = Color(1, 1, 1, 0.85)
		_apply_rect(shadow, Rect2(rect.position + SHADOW_OFFSET, rect.size))
		add_child(shadow)
	var glow := _texture_node(
		"TitleProp_%s_glow" % key,
		_radial(Color(1.0, 0.82, 0.5, 0.30), Color(1.0, 0.8, 0.45, 0.0))
	)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.modulate.a = 0.0
	_apply_rect(glow, rect.grow(rect.size.x * 0.08))
	add_child(glow)
	_glows[key] = glow
	var node := _texture_node("TitleProp_%s" % key, tex)
	node.rotation_degrees = float(spec["rot"])
	_apply_rect(node, rect)
	add_child(node)
	_props[key] = node


func _build_vignette() -> void:
	var shade := TextureRect.new()
	shade.name = "DeskVignette"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.18), Color(0, 0, 0, 0.72),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.45, 0.42)
	tex.fill_to = Vector2(1.08, 1.0)
	tex.width = 256
	tex.height = 256
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)


func _texture_node(node_name: String, tex: Texture2D) -> TextureRect:
	var node := TextureRect.new()
	node.name = node_name
	node.texture = tex
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return node


func _apply_rect(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x / DESIGN.x
	node.anchor_top = rect.position.y / DESIGN.y
	node.anchor_right = rect.end.x / DESIGN.x
	node.anchor_bottom = rect.end.y / DESIGN.y
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


static func _radial(inner: Color, outer: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([inner, outer])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex
