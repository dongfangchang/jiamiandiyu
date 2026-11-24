extends RefCounted

## The only reader of data/registry/assets.json (TARGET_ARCHITECTURE §3.5).
## Every UI lookup of a game asset path (assets/game/**) goes through here by
## stable id; no other src/ui file may spell such a path.
##
## Lookups return "" for an unknown id; callers own their fallback via
## `fallback(name)` so a missing entry never blanks a screen.

const REGISTRY_PATH := "res://data/registry/assets.json"

static var _data: Dictionary = {}
static var _loaded := false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	## Sanctioned exception to "UI reads no files" (R2-09/R2-10): this one
	## presentation registry, read once and cached.
	if not FileAccess.file_exists(REGISTRY_PATH):
		push_error("asset registry missing: %s" % REGISTRY_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
	if parsed is Dictionary:
		_data = parsed
	else:
		push_error("asset registry is not a JSON object: %s" % REGISTRY_PATH)


static func section(name: String) -> Dictionary:
	_ensure_loaded()
	var value: Variant = _data.get(name, {})
	return value if value is Dictionary else {}


static func lookup(section_name: String, id: String) -> String:
	var value: Variant = section(section_name).get(id, "")
	return String(value) if value is String else ""


static func fallback(name: String) -> String:
	return lookup("fallbacks", name)


static func ids(section_name: String) -> PackedStringArray:
	var out := PackedStringArray(section(section_name).keys())
	out.sort()
	return out


static func card_window(card_id: String) -> String:
	return String(_card_entry(card_id).get("window", ""))


static func card_plate(card_id: String) -> String:
	return String(_card_entry(card_id).get("plate", ""))


static func seal(rarity: String, mechanic: String, small := false) -> String:
	var entry: Variant = section("seals").get("%s.%s" % [rarity, mechanic], {})
	if not entry is Dictionary:
		return ""
	return String((entry as Dictionary).get("small" if small else "full", ""))


static func source_exists(path: String) -> bool:
	## Checks the source file, not the import cache: a stale .import keeps a
	## deleted PNG "present" for ResourceLoader. Part of the sanctioned exception.
	return not path.is_empty() and FileAccess.file_exists(path)


static func reload() -> void:
	_data = {}
	_loaded = false


static func _card_entry(card_id: String) -> Dictionary:
	var entry: Variant = section("cards").get(card_id, {})
	return entry if entry is Dictionary else {}
