extends RefCounted

## Shared card-face pieces for every screen that shows a card outside battle
## (deck, gacha, upgrade). One resolution order, so a screen can no longer
## silently keep a stale art table:
##   v0.85 art window  ->  legacy composed plate  ->  card back
## plus the rarity x mechanic seal derived from the card's own data.

const CardArt := preload("res://src/ui/card_art_catalog.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")

const NAME_ART := "CardArt"
const NAME_SEAL := "CardSeal"


static func art_path(definition_id: String) -> String:
	var path := CardArt.art_window(definition_id)
	if path.is_empty() and not definition_id.is_empty():
		path = DeckCatalog.card_art(definition_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		path = CardArt.CARD_BACK
	return path


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
