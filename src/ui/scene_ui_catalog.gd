extends RefCounted

## Maps frozen scene.* IDs to texture paths. Missing files fall back safely.

## Quiet gothic rain-night plate for system / hub UI shells (low contrast canvas).
const UI_CANVAS := "res://assets/game/v0.54.0/scenes/ui-canvas-gothic-rain-night.png"
const UI_CANVAS_DIM := 0.32

const FALLBACK_BATTLE := "res://assets/game/v0.24.0/v0.3.0/scenes/battle-tingen-old-house.png"
const FALLBACK_REST := UI_CANVAS
const FALLBACK_RITUAL := UI_CANVAS

const SCENE_PATHS := {
	"scene.battle.tingen_old_house": FALLBACK_BATTLE,
	"scene.battle.tyrell_warehouse": "res://assets/game/v0.44.0/scenes/battle-tyrell-warehouse.png",
	"scene.battle.blackthorn_neil": "res://assets/game/v0.44.0/scenes/battle-blackthorn-neil.png",
	"scene.battle.lamud_chapel": "res://assets/game/v0.44.0/scenes/battle-lamud-chapel.png",
	"scene.battle.moretti_home": "res://assets/game/v0.45.0/scenes/battle-moretti-home.png",
	"scene.battle.elliot_ruin": "res://assets/game/v0.45.0/scenes/battle-elliot-ruin.png",
	"scene.battle.wood_house": "res://assets/game/v0.45.0/scenes/battle-wood-house.png",
	"scene.battle.megose_descent": "res://assets/game/v0.46.0/scenes/battle-megose-descent.png",
	"scene.rest.divination_club": "res://assets/game/v0.44.0/scenes/rest-divination-club.png",
	"scene.rest.chanis_gate": "res://assets/game/v0.46.0/scenes/rest-chanis-gate.png",
	"scene.hub.rest_blackthorn": UI_CANVAS,
	"scene.ritual.clown_ascension": "res://assets/game/v0.44.0/scenes/ritual-clown-ascension.png",
	"scene.ritual.obituary": UI_CANVAS,
	"scene.ritual.above_fog": "res://assets/game/v0.46.0/scenes/ritual-above-fog.png",
	"scene.ritual.ascension": UI_CANVAS,
	"scene.title.mask_desk": UI_CANVAS,
	"scene.hub.route_map": UI_CANVAS,
	"scene.hub.deck_archive": UI_CANVAS,
	"scene.hub.gacha_altar": UI_CANVAS,
	"scene.hub.reward_archive": UI_CANVAS,
	"scene.hub.challenge_board": UI_CANVAS,
	"scene.hub.challenge_result": UI_CANVAS,
}


## Diary left-leaf illustrations are a SEPARATE set from the full-screen scene
## plates. The leaf is a ~0.71 portrait vignette; the battle screen is 16:9.
## Neither aspect survives the other's cover-crop (a 16:9 plate loses ~60% of
## its width on the leaf, a portrait loses ~60% of its height on the screen),
## so the diary gets its own art and silently falls back to the scene plate
## until those illustrations exist.
const DIARY_ART_DIR := "res://assets/game/v0.85.0/diary"

const DIARY_PATHS := {
	"scene.battle.moretti_home": "battle-moretti-home.png",
	"scene.battle.elliot_ruin": "battle-elliot-ruin.png",
	"scene.battle.tyrell_warehouse": "battle-tyrell-warehouse.png",
	"scene.battle.wood_house": "battle-wood-house.png",
	"scene.rest.divination_club": "rest-divination-club.png",
	"scene.battle.lamud_chapel": "battle-lamud-chapel.png",
	"scene.battle.blackthorn_neil": "battle-blackthorn-neil.png",
	"scene.ritual.clown_ascension": "ritual-clown-ascension.png",
}


static func diary_path_for(scene_id: String, kind: String = "battle") -> String:
	## Portrait leaf art when delivered; otherwise the existing scene plate.
	var leaf := String(DIARY_PATHS.get(scene_id, ""))
	if not leaf.is_empty():
		var full := "%s/%s" % [DIARY_ART_DIR, leaf]
		if ResourceLoader.exists(full):
			return full
	return path_for(scene_id, kind)


static func has_diary_art(scene_id: String) -> bool:
	## Lets probes/reports tell "delivered" from "still falling back".
	var leaf := String(DIARY_PATHS.get(scene_id, ""))
	if leaf.is_empty():
		return false
	return ResourceLoader.exists("%s/%s" % [DIARY_ART_DIR, leaf])


static func path_for(scene_id: String, kind: String = "battle") -> String:
	var mapped := String(SCENE_PATHS.get(scene_id, ""))
	if not mapped.is_empty() and ResourceLoader.exists(mapped):
		return mapped
	match kind:
		"rest":
			return FALLBACK_REST
		"ritual":
			return FALLBACK_RITUAL
		_:
			return FALLBACK_BATTLE


static func dim_for(kind: String) -> float:
	## Hub canvas stays quiet under chrome; battle plates keep a bit more presence.
	match kind:
		"rest", "ritual", "hub", "title":
			return UI_CANVAS_DIM
		_:
			return 0.26
