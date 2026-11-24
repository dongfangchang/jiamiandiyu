extends RefCounted

## Single source of truth for card visuals: illustration, rarity shell and
## mechanic seal. Replaces the two divergent `card_art()` implementations
## (a 40-row hardcoded dict in progression_ui_catalog, and a five-branch
## version-directory if-chain in deck_ui_catalog) that had to be edited in
## lockstep whenever a card was added.
##
## Adding a card now needs NO code change here:
##   1. drop art at  <ART_DIR>/<card.id>/art.png
##   2. the card's own `rarity` + effects/tags in data/cards/** drive the seal
## Everything degrades: a card with no art falls back to the legacy plate and
## then to the card back, so a half-delivered batch never blanks the UI.

const ART_DIR := "res://assets/game/v0.85.0/cards"
const SEAL_DIR := "res://assets/game/v0.85.0/seals"
const CARD_BACK := "res://assets/game/v0.24.0/v0.4.0/cards/card-back-sealed-omen.png"
const CARDS_PATH := "res://data/cards/v0.7.0/cards.json"

## Legacy full-card plates, kept as the fallback until v0.85 art covers a card.
const LegacyDeck := preload("res://src/ui/deck_ui_catalog.gd")

const RARITIES: Array[String] = ["common", "uncommon", "rare", "mythic"]
const MECHANICS: Array[String] = [
	"attack", "defense", "ritual", "divination", "support", "curse",
]

## Tags that mark a card as divination even when its effects look generic
## (a scrying tool that happens to draw is still divination, not support).
const DIVINATION_TAGS: Array[String] = [
	"占卜", "预感", "推演", "意图揭示", "灵性视觉", "梦境", "通灵", "厄运",
]

static var _meta: Dictionary = {}
static var _loaded := false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(CARDS_PATH):
		return
	var file := FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	for entry_value in (parsed as Dictionary).get("cards", []):
		if not entry_value is Dictionary:
			continue
		var card: Dictionary = entry_value
		var id := String(card.get("id", ""))
		if id.is_empty():
			continue
		_meta[id] = {
			"rarity": _rarity_of(card),
			"mechanic": _mechanic_of(card),
		}


static func _rarity_of(card: Dictionary) -> String:
	var rarity := String(card.get("rarity", "common"))
	return rarity if rarity in RARITIES else "common"


static func _mechanic_of(card: Dictionary) -> String:
	## Derived, never stored twice: the seal must not drift from the rules.
	## Order matters — it reads as "what is this card FOR", so the defining
	## trait wins over incidental effects (a heal with a risk side-effect is
	## support, not curse).
	var effects: Array = card.get("effects", [])
	var ids: Array[String] = []
	for effect_value in effects:
		if effect_value is Dictionary:
			ids.append(String((effect_value as Dictionary).get("effect_id", "")))
	var tags: Array = card.get("mechanic_tags", [])

	if "仪式" in tags or "prepare_ritual" in ids:
		return "ritual"
	for tag in DIVINATION_TAGS:
		if tag in tags:
			return "divination"
	if "reveal_intent" in ids or "reveal_all" in ids:
		return "divination"
	if "damage" in ids or "damage_all" in ids or "steal_attack" in ids:
		return "attack"
	if "block" in ids:
		return "defense"
	if "heal" in ids or "spirit" in ids or "draw" in ids:
		return "support"
	if "risk" in ids or "lose_hp" in ids or "discard" in ids:
		return "curse"
	return "support"


static func rarity_of(definition_id: String) -> String:
	_ensure_loaded()
	var meta: Dictionary = _meta.get(definition_id, {})
	return String(meta.get("rarity", "common"))


static func mechanic_of(definition_id: String) -> String:
	_ensure_loaded()
	var meta: Dictionary = _meta.get(definition_id, {})
	return String(meta.get("mechanic", "support"))


static func art_window(definition_id: String) -> String:
	## 512x390 illustration for the card frame's art window. Empty when this
	## card has no v0.85 art yet, so callers can fall back to a legacy plate.
	if definition_id.is_empty():
		return ""
	var path := "%s/%s/art.png" % [ART_DIR, definition_id]
	return path if ResourceLoader.exists(path) else ""


static func has_art_window(definition_id: String) -> bool:
	return not art_window(definition_id).is_empty()


static func seal(definition_id: String, small := false) -> String:
	## Rarity shell x mechanic core, per art/README.md §0.3.
	## An unknown id gets no seal rather than a plausible-looking default —
	## stamping "common/support" on a card that does not exist would hide a
	## content bug behind valid-looking art.
	_ensure_loaded()
	if not _meta.has(definition_id):
		return ""
	var name := "seal-%s-%s%s.png" % [
		rarity_of(definition_id),
		mechanic_of(definition_id),
		"-128" if small else "",
	]
	var path := "%s/%s" % [SEAL_DIR, name]
	return path if ResourceLoader.exists(path) else ""


static func card_art(definition_id: String) -> String:
	## Compatibility entry for existing screens that still expect a single
	## full-card image. Prefers the legacy composed plate because the v0.85
	## delivery is an art WINDOW, not a finished card face.
	var legacy := LegacyDeck.card_art(definition_id)
	if legacy != CARD_BACK and ResourceLoader.exists(legacy):
		return legacy
	return CARD_BACK


static func missing_art() -> PackedStringArray:
	## Lets probes report "not delivered yet" instead of silently showing a
	## fallback that looks like success.
	_ensure_loaded()
	var out: PackedStringArray = []
	for id in _meta.keys():
		if not has_art_window(String(id)):
			out.append(String(id))
	out.sort()
	return out


static func all_card_ids() -> PackedStringArray:
	_ensure_loaded()
	var out: PackedStringArray = []
	for id in _meta.keys():
		out.append(String(id))
	out.sort()
	return out


static func clear_cache() -> void:
	_meta.clear()
	_loaded = false
