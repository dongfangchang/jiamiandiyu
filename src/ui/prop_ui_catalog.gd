extends RefCounted

## Registry for keyed prop art (desk, paper, seal, state tokens, ornaments).
##
## Pipeline:
##   art/assets/raster/<ver>/props/*.png   (RGB on a studio backdrop)
##     -> props.manifest.json              (declares key mode / trim)
##     -> art/tools/key_props.gd           (writes RGBA cutouts)
##     -> data/registry/assets.json "props" (runtime lookup by prop id)
##
## Adding art is a manifest row + a file drop + one tool run + one registry
## row. Every lookup degrades gracefully, so a missing file leaves the
## procedural look in place instead of crashing.

const AssetRegistry := preload("res://src/ui/asset_registry.gd")

## Diary leaf state -> which token lights up. Mirrors 样板.jpg's rail.
const STATE_TOKENS: Array[String] = [
	"token_available",
	"token_failed",
	"token_silence",
	"token_archive",
]

const TOKEN_LABELS: Array[String] = ["可用", "曾失败", "静默", "归藏"]

static var _cache: Dictionary = {}


static func ids() -> PackedStringArray:
	return AssetRegistry.ids("props")


static func path(prop_id: String) -> String:
	return AssetRegistry.lookup("props", prop_id)


static func has(prop_id: String) -> bool:
	var p := path(prop_id)
	if p.is_empty():
		return false
	## Check the SOURCE file, not just ResourceLoader: a stale .import cache
	## keeps reporting a deleted PNG as present, which would let a missing
	## delivery pass as ingested.
	return AssetRegistry.source_exists(p) and ResourceLoader.exists(p)


static func texture(prop_id: String) -> Texture2D:
	## Null when the art has not been ingested yet — callers must handle it and
	## keep their procedural fallback.
	if _cache.has(prop_id):
		return _cache[prop_id] as Texture2D
	var tex: Texture2D = null
	var p := path(prop_id)
	if not p.is_empty() and ResourceLoader.exists(p):
		tex = load(p) as Texture2D
	_cache[prop_id] = tex
	return tex


static func token_for_state(state_index: int) -> Texture2D:
	if state_index < 0 or state_index >= STATE_TOKENS.size():
		return null
	return texture(STATE_TOKENS[state_index])


static func missing() -> PackedStringArray:
	## Lets probes and reports tell "not delivered" from "delivered but wrong",
	## instead of silently accepting a fallback.
	var out: PackedStringArray = []
	for prop_id in ids():
		if not has(String(prop_id)):
			out.append(String(prop_id))
	return out


static func clear_cache() -> void:
	_cache.clear()
