extends RefCounted

## Maps frozen scene.* IDs to texture paths via the asset registry. Missing
## files fall back safely.

const AssetRegistry := preload("res://src/ui/asset_registry.gd")

const UI_CANVAS_ID := "scene.ui.canvas"
const UI_CANVAS_DIM := 0.32


## Quiet gothic rain-night plate for system / hub UI shells (low contrast canvas).
static func ui_canvas() -> String:
	return AssetRegistry.lookup("scenes", UI_CANVAS_ID)


static func fallback_for(kind: String) -> String:
	match kind:
		"rest":
			return AssetRegistry.fallback("scene.rest")
		"ritual":
			return AssetRegistry.fallback("scene.ritual")
		_:
			return AssetRegistry.fallback("scene.battle")


## Diary left-leaf illustrations are a SEPARATE set from the full-screen scene
## plates. The leaf is a ~0.71 portrait vignette; the battle screen is 16:9.
## Neither aspect survives the other's cover-crop (a 16:9 plate loses ~60% of
## its width on the leaf, a portrait loses ~60% of its height on the screen),
## so the diary gets its own art and silently falls back to the scene plate
## until those illustrations exist.
static func diary_path_for(scene_id: String, kind: String = "battle") -> String:
	## Portrait leaf art when delivered; otherwise the existing scene plate.
	var leaf := AssetRegistry.lookup("diary_pages", scene_id)
	if not leaf.is_empty() and ResourceLoader.exists(leaf):
		return leaf
	return path_for(scene_id, kind)


static func has_diary_art(scene_id: String) -> bool:
	## Lets probes/reports tell "delivered" from "still falling back".
	var leaf := AssetRegistry.lookup("diary_pages", scene_id)
	return not leaf.is_empty() and ResourceLoader.exists(leaf)


static func is_diary_leaf(path: String) -> bool:
	## True when `path` is a portrait leaf (vs a landscape scene plate fallback).
	return not path.is_empty() and path in AssetRegistry.section("diary_pages").values()


static func diary_scene_ids() -> PackedStringArray:
	return AssetRegistry.ids("diary_pages")


static func path_for(scene_id: String, kind: String = "battle") -> String:
	var mapped := AssetRegistry.lookup("scenes", scene_id)
	if not mapped.is_empty() and ResourceLoader.exists(mapped):
		return mapped
	return fallback_for(kind)


static func dim_for(kind: String) -> float:
	## Hub canvas stays quiet under chrome; battle plates keep a bit more presence.
	match kind:
		"rest", "ritual", "hub", "title":
			return UI_CANVAS_DIM
		_:
			return 0.26
