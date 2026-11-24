extends RefCounted

## Lookup for `data/registry/assets.json` → `desk_world` section (DQ / index card).
## Resolve assets paths only via the registry; never hard-code game-asset prefixes here.

const AssetRegistry := preload("res://src/ui/asset_registry.gd")

static var _cache: Dictionary = {}


static func path(asset_id: String) -> String:
	return AssetRegistry.lookup("desk_world", asset_id)


static func has(asset_id: String) -> bool:
	var p := path(asset_id)
	if p.is_empty():
		return false
	return AssetRegistry.source_exists(p) and ResourceLoader.exists(p)


static func texture(asset_id: String) -> Texture2D:
	if _cache.has(asset_id):
		return _cache[asset_id] as Texture2D
	var tex: Texture2D = null
	var p := path(asset_id)
	if not p.is_empty() and ResourceLoader.exists(p):
		tex = load(p) as Texture2D
	_cache[asset_id] = tex
	return tex


static func clear_cache() -> void:
	_cache.clear()
