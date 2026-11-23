extends Node

const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const ChallengeCatalog := preload("res://src/ui/challenge_ui_catalog.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")

const UI_CANVAS := "res://assets/game/v0.54.0/scenes/ui-canvas-gothic-rain-night.png"
const P4 := {
	"scene.hub.reward_archive": UI_CANVAS,
	"scene.hub.challenge_board": UI_CANVAS,
	"scene.hub.challenge_result": UI_CANVAS,
	"scene.hub.rest_blackthorn": UI_CANVAS,
	"scene.ritual.obituary": UI_CANVAS,
	"scene.ritual.ascension": UI_CANVAS,
}

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	for scene_id in P4.keys():
		var path := String(P4[scene_id])
		_expect(ResourceLoader.exists(path), "%s exists" % scene_id)
		_expect(SceneCatalog.path_for(scene_id) == path, "%s scene catalog" % scene_id)

	_expect(
		ChallengeCatalog.SELECTION_BACKGROUND == String(P4["scene.hub.challenge_board"]),
		"challenge selection catalog"
	)
	_expect(
		ChallengeCatalog.RESULT_BACKGROUND == String(P4["scene.hub.challenge_result"]),
		"challenge result catalog"
	)
	_expect(
		ProgressionCatalog.REWARD_BACKGROUND == String(P4["scene.hub.reward_archive"]),
		"reward catalog"
	)
	_expect(
		ProgressionCatalog.UPGRADE_BACKGROUND == String(P4["scene.hub.reward_archive"]),
		"upgrade catalog"
	)
	_expect(
		RouteCatalog.REST_BACKGROUND == String(P4["scene.hub.rest_blackthorn"]),
		"rest catalog"
	)
	_expect(
		RouteCatalog.RITUAL_BACKGROUND == String(P4["scene.ritual.obituary"]),
		"ritual catalog"
	)
	_expect(
		SceneCatalog.FALLBACK_REST == String(P4["scene.hub.rest_blackthorn"]),
		"fallback rest"
	)
	_expect(
		SceneCatalog.FALLBACK_RITUAL == String(P4["scene.ritual.obituary"]),
		"fallback ritual"
	)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V049_SCENE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V049_SCENE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
