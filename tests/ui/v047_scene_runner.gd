extends Node

const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const DeckCatalog := preload("res://src/ui/deck_ui_catalog.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const StartScreenScript := preload("res://src/ui/start_screen.gd")

## Hub shells share the quiet v0.54 rain-night UI canvas.
const UI_CANVAS := "res://assets/game/v0.54.0/scenes/ui-canvas-gothic-rain-night.png"
const P3 := {
	"scene.title.mask_desk": UI_CANVAS,
	"scene.hub.route_map": UI_CANVAS,
	"scene.hub.deck_archive": UI_CANVAS,
	"scene.hub.gacha_altar": UI_CANVAS,
}

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	for scene_id in P3.keys():
		var path := String(P3[scene_id])
		_expect(ResourceLoader.exists(path), "%s exists" % scene_id)
		_expect(SceneCatalog.path_for(scene_id) == path, "%s scene catalog" % scene_id)

	_expect(RouteCatalog.ROUTE_BACKGROUND == String(P3["scene.hub.route_map"]), "route catalog")
	_expect(DeckCatalog.BACKGROUND == String(P3["scene.hub.deck_archive"]), "deck catalog")
	_expect(
		ProgressionCatalog.IDENTITY_BACKGROUND == String(P3["scene.title.mask_desk"]),
		"identity catalog"
	)
	_expect(
		ProgressionCatalog.GACHA_BACKGROUND == String(P3["scene.hub.gacha_altar"]),
		"gacha catalog"
	)
	_expect(
		StartScreenScript.TITLE_BACKGROUND == String(P3["scene.title.mask_desk"]),
		"start title background"
	)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V047_SCENE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V047_SCENE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
