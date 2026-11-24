extends Control

## Title-screen desk: the same table as the diary, with the journal SHUT.
##
## This is a presentation layer only. It owns no actions: the screen keeps its
## real Buttons (and their exact labels, which integration probes search for)
## and registers each one here as a hotspot. The prop art is drawn underneath
## and lights up on hover, so the menu reads as objects on a desk while the
## button tree, focus order and probe surface stay exactly as they were.
##
## Art comes from PropCatalog, so a missing prop degrades to the plain button
## rather than blanking the menu.

const PropCatalog := preload("res://src/ui/prop_ui_catalog.gd")

## The wide desk plate ALREADY contains every object (journal, candle, watch,
## inkwell, dossiers), so this does not stack cut-outs on top of it. Each slot
## is just the screen-space rect of the object as painted, measured off the
## 1920x1080 plate; the button becomes an invisible hotspot there and hover
## lifts a highlight over it.
const SLOTS := {
	"continue": {"rect": Rect2(0.271, 0.139, 0.398, 0.778), "label": "继续"},
	"settings": {"rect": Rect2(0.677, 0.111, 0.094, 0.218), "label": "设置"},
	"new_game": {"rect": Rect2(0.805, 0.218, 0.112, 0.227), "label": "新局"},
	"challenge": {"rect": Rect2(0.781, 0.444, 0.208, 0.500), "label": "挑战"},
	"quit": {"rect": Rect2(0.000, 0.037, 0.122, 0.352), "label": "熄烛"},
}

var _backdrop: TextureRect
var _slots: Dictionary = {}
var _captions: Dictionary = {}
var _opening := false


func _ready() -> void:
	## PASS, not IGNORE: an IGNORE container is skipped during mouse picking
	## together with its children, so the hotspot buttons never saw a click.
	## PASS lets the buttons receive input while the desk itself stays
	## click-through where there is no object.
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_backdrop()
	_build_props()


func has_art() -> bool:
	## Screens ask this before hiding their own panel chrome.
	return PropCatalog.has("title_desk_wide")


func _build_backdrop() -> void:
	var tex := PropCatalog.texture("title_desk_wide")
	if tex == null:
		return
	_backdrop = TextureRect.new()
	_backdrop.name = "TitleDeskBackdrop"
	_backdrop.texture = tex
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_backdrop)


func _build_props() -> void:
	## One highlight per object. Transparent at rest so the painted plate shows
	## through untouched; hover and disabled states tint it.
	for key in SLOTS.keys():
		var slot: Dictionary = SLOTS[key]
		var rect: Rect2 = slot.get("rect", Rect2())
		var glow := ColorRect.new()
		glow.name = "TitleGlow_%s" % key
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.color = Color(1.0, 0.86, 0.55, 0.0)
		glow.anchor_left = rect.position.x
		glow.anchor_top = rect.position.y
		glow.anchor_right = rect.position.x + rect.size.x
		glow.anchor_bottom = rect.position.y + rect.size.y
		glow.offset_left = 0.0
		glow.offset_top = 0.0
		glow.offset_right = 0.0
		glow.offset_bottom = 0.0
		add_child(glow)
		_slots[key] = glow

		## A small caption under each object: the painted desk alone does not
		## say which object does what, and the button text is hidden.
		var caption := Label.new()
		caption.name = "TitleCaption_%s" % key
		caption.text = String(slot.get("label", ""))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 15)
		caption.add_theme_color_override("font_color", Color(0.92, 0.82, 0.58, 0.82))
		caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		caption.add_theme_constant_override("shadow_offset_y", 2)
		caption.anchor_left = rect.position.x
		caption.anchor_right = rect.position.x + rect.size.x
		caption.anchor_top = rect.position.y + rect.size.y
		caption.anchor_bottom = rect.position.y + rect.size.y
		caption.offset_top = -4.0
		caption.offset_bottom = 26.0
		add_child(caption)
		_captions[key] = caption


signal open_finished


func is_opening() -> bool:
	return _opening


func play_open(key: String) -> bool:
	## "The book opens" beat before the screen changes: the chosen object is
	## pushed toward the viewer and the desk dims away, so entering a chapter
	## reads as lifting the cover rather than a hard cut.
	## Returns false when there is nothing to animate, and the caller should
	## proceed immediately.
	if _opening or not _slots.has(key):
		return false
	_opening = true
	var glow: ColorRect = _slots[key]
	var focus := glow.get_global_rect().get_center()

	## Captions and the other objects fade first — attention narrows.
	var tween := create_tween()
	tween.set_parallel(true)
	for other in _captions.keys():
		var caption: Label = _captions[other]
		if is_instance_valid(caption):
			tween.tween_property(caption, "modulate:a", 0.0, 0.18)
	for other in _slots.keys():
		if String(other) == key:
			continue
		var dim: ColorRect = _slots[other]
		if is_instance_valid(dim):
			tween.tween_property(dim, "color", Color(0, 0, 0, 0.45), 0.26)

	## The chosen object warms up, then the whole desk pushes in and whites
	## out into the next screen.
	tween.tween_property(glow, "color", Color(1.0, 0.90, 0.62, 0.22), 0.22)
	if is_instance_valid(_backdrop):
		_backdrop.pivot_offset = _backdrop.size * 0.5
		var zoom := 1.0 + 0.09
		tween.chain().tween_property(_backdrop, "scale", Vector2(zoom, zoom), 0.42) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(func() -> void:
		_opening = false
		open_finished.emit()
	)
	return true


func reset_open() -> void:
	## Called when returning to the title so a second visit is not blank.
	_opening = false
	modulate.a = 1.0
	if is_instance_valid(_backdrop):
		_backdrop.scale = Vector2.ONE
	for key in _slots.keys():
		var glow: ColorRect = _slots[key]
		if is_instance_valid(glow):
			glow.color = Color(1.0, 0.86, 0.55, 0.0)
	for key in _captions.keys():
		var caption: Label = _captions[key]
		if is_instance_valid(caption):
			caption.modulate.a = 1.0


func bind(key: String, button: Button) -> bool:
	## Make `button` the invisible hotspot over the prop for `key`. The button
	## keeps its text (probes search by label) but renders nothing itself.
	if not _slots.has(key) or not is_instance_valid(button):
		return false
	var glow: ColorRect = _slots[key]
	button.flat = true
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	## The painted object carries the meaning; the caption names it. The
	## button's own text must stay set (integration probes find entries by
	## label) but must not render, and per-state font colour overrides were
	## not enough — the theme still drew it. Shrink the glyphs away instead.
	button.add_theme_font_size_override("font_size", 1)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	## Reparent the button onto the desk so it covers exactly the prop rect.
	var parent := button.get_parent()
	if parent != null:
		parent.remove_child(button)
	add_child(button)
	button.anchor_left = glow.anchor_left
	button.anchor_top = glow.anchor_top
	button.anchor_right = glow.anchor_right
	button.anchor_bottom = glow.anchor_bottom
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
	## Buttons were sized for a menu row; a leftover minimum width would stop
	## the hotspot covering its whole object.
	button.custom_minimum_size = Vector2.ZERO
	button.size_flags_horizontal = Control.SIZE_FILL
	button.size_flags_vertical = Control.SIZE_FILL

	button.mouse_entered.connect(_on_hover.bind(key, true))
	button.mouse_exited.connect(_on_hover.bind(key, false))
	_refresh_slot(key, button)
	return true


func refresh(key: String, button: Button) -> void:
	_refresh_slot(key, button)


func _refresh_slot(key: String, button: Button) -> void:
	## A disabled action dims its caption; without this the desk would invite
	## clicks that silently do nothing.
	if not _captions.has(key) or not is_instance_valid(button):
		return
	var caption: Label = _captions[key]
	caption.add_theme_color_override(
		"font_color",
		Color(0.55, 0.5, 0.42, 0.5) if button.disabled else Color(0.92, 0.82, 0.58, 0.82)
	)


func _on_hover(key: String, entering: bool) -> void:
	if not _slots.has(key):
		return
	var glow: ColorRect = _slots[key]
	var tween := create_tween()
	tween.tween_property(
		glow, "color",
		Color(1.0, 0.86, 0.55, 0.10 if entering else 0.0),
		0.14
	)
	if _captions.has(key):
		var caption: Label = _captions[key]
		caption.add_theme_color_override(
			"font_color",
			Color(1.0, 0.92, 0.70, 1.0) if entering else Color(0.92, 0.82, 0.58, 0.82)
		)
