extends RefCounted

## Single source of truth for card visuals: illustration, rarity shell and
## mechanic seal. Paths come from the asset registry (R2-10); rarity and
## mechanic are derived from card definitions the app injects at startup via
## `configure()` (R2-09) — the UI never opens content files itself.
##
## Resolution order for a face: v0.85 art window -> legacy plate -> card back.
## Everything degrades, so a half-delivered batch never blanks the UI.

const AssetRegistry := preload("res://src/ui/asset_registry.gd")

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


static func configure(card_definitions: Array) -> void:
	## Called by the app with the loaded, schema-validated card definitions.
	_meta.clear()
	for entry_value in card_definitions:
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


static func is_configured() -> bool:
	return not _meta.is_empty()


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
	var meta: Dictionary = _meta.get(definition_id, {})
	return String(meta.get("rarity", "common"))


static func mechanic_of(definition_id: String) -> String:
	var meta: Dictionary = _meta.get(definition_id, {})
	return String(meta.get("mechanic", "support"))


static func art_window(definition_id: String) -> String:
	## 512x390 illustration for the card frame's art window. Empty when this
	## card has no v0.85 art yet, so callers can fall back to a legacy plate.
	if definition_id.is_empty():
		return ""
	var path := AssetRegistry.card_window(definition_id)
	return path if not path.is_empty() and ResourceLoader.exists(path) else ""


static func has_art_window(definition_id: String) -> bool:
	return not art_window(definition_id).is_empty()


static func seal(definition_id: String, small := false) -> String:
	## Rarity shell x mechanic core, per art/README.md §0.3.
	## An unknown id gets no seal rather than a plausible-looking default —
	## stamping "common/support" on a card that does not exist would hide a
	## content bug behind valid-looking art.
	if not _meta.has(definition_id):
		return ""
	var path := AssetRegistry.seal(rarity_of(definition_id), mechanic_of(definition_id), small)
	return path if not path.is_empty() and ResourceLoader.exists(path) else ""


static func seal_path(rarity: String, mechanic: String, small := false) -> String:
	## Matrix lookup without a card, for probes that audit the 4x6 set.
	return AssetRegistry.seal(rarity, mechanic, small)


static func card_back() -> String:
	return AssetRegistry.fallback("card_back")


static func card_art(definition_id: String) -> String:
	## Full composed plate for screens that expect one image; card back when
	## the card has none.
	var plate := AssetRegistry.card_plate(definition_id)
	if not plate.is_empty() and ResourceLoader.exists(plate):
		return plate
	return card_back()


static func display_art(definition_id: String) -> String:
	## What a card face shows: art window, else plate, else card back.
	var window := art_window(definition_id)
	return window if not window.is_empty() else card_art(definition_id)


static func missing_art() -> PackedStringArray:
	## Lets probes report "not delivered yet" instead of silently showing a
	## fallback that looks like success.
	var out: PackedStringArray = []
	for id in _meta.keys():
		if not has_art_window(String(id)):
			out.append(String(id))
	out.sort()
	return out


static func all_card_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for id in _meta.keys():
		out.append(String(id))
	out.sort()
	return out


static func clear_cache() -> void:
	_meta.clear()
