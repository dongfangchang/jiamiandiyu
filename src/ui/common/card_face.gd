extends RefCounted

## Shared card-face pieces for every screen that shows a card (deck, gacha,
## upgrade, battle hand). One resolution order, so a screen can no longer
## silently keep a stale art table:
##   v0.85 art window  ->  legacy composed plate  ->  card back
## plus the rarity x mechanic seal derived from the card's own data.

const CardArt := preload("res://src/ui/card_art_catalog.gd")

const NAME_ART := "CardArt"
const NAME_SEAL := "CardSeal"
## art/README.md §0.1: the illustration window is 512 x 390.
const ART_WINDOW_ASPECT := 512.0 / 390.0


static func window_size(width: float) -> Vector2:
	## A rect of the given width at the art window's own aspect, so the art is
	## neither squashed nor cropped to a strip.
	return Vector2(roundf(width), roundf(width / ART_WINDOW_ASPECT))


static func make_window_face(definition_id: String, width: float, seal_size := Vector2(22, 22)) -> Control:
	## Compact face for battle hand / cast: art window at its native aspect,
	## fixed size (never stretched by a parent container), seal in the corner.
	var size := window_size(width)
	var face := make_face(definition_id, size, seal_size)
	face.size = size
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return face


static func art_path(definition_id: String) -> String:
	return CardArt.display_art(definition_id)


static func make_art(definition_id: String, min_size := Vector2.ZERO, tint := Color.WHITE) -> TextureRect:
	var art := TextureRect.new()
	art.name = NAME_ART
	art.texture = load(art_path(definition_id)) as Texture2D
	art.custom_minimum_size = min_size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = tint
	return art


static func make_seal(definition_id: String, size := Vector2(26, 26), small := true, tint := Color.WHITE) -> TextureRect:
	## Null for an unknown id: no plausible-looking default seal.
	var path := CardArt.seal(definition_id, small)
	if path.is_empty():
		return null
	var seal := TextureRect.new()
	seal.name = NAME_SEAL
	seal.texture = load(path) as Texture2D
	seal.custom_minimum_size = size
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.tooltip_text = "%s · %s" % [
		CardArt.rarity_of(definition_id), CardArt.mechanic_of(definition_id)
	]
	seal.modulate = tint
	return seal


static func make_face(definition_id: String, min_size := Vector2.ZERO, seal_size := Vector2(34, 34)) -> Control:
	## Art filling the rect with the seal stamped in its lower-right corner.
	## Callers anchor/size the returned Control; children follow it.
	var face := Control.new()
	face.name = "CardFace"
	face.custom_minimum_size = min_size
	face.clip_contents = true
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := make_art(definition_id)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.add_child(art)
	var seal := make_seal(definition_id, seal_size, seal_size.x <= 64.0)
	if seal != null:
		seal.anchor_left = 1.0
		seal.anchor_top = 1.0
		seal.anchor_right = 1.0
		seal.anchor_bottom = 1.0
		seal.offset_left = -seal_size.x - 4.0
		seal.offset_top = -seal_size.y - 4.0
		seal.offset_right = -4.0
		seal.offset_bottom = -4.0
		face.add_child(seal)
	return face


static func face_art_path(face: Node) -> String:
	## Test/probe helper: the texture path actually shown by a face or art node.
	var art: TextureRect = face if face is TextureRect else face.find_child(NAME_ART, true, false) as TextureRect
	if art == null or art.texture == null:
		return ""
	return art.texture.resource_path
