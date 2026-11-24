extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const BattleScreenScript := preload("res://src/ui/battle_screen.gd")

const P1 := {
	"scene.battle.moretti_home": "res://assets/game/v0.45.0/scenes/battle-moretti-home.png",
	"scene.battle.elliot_ruin": "res://assets/game/v0.45.0/scenes/battle-elliot-ruin.png",
	"scene.battle.wood_house": "res://assets/game/v0.45.0/scenes/battle-wood-house.png",
}

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	await get_tree().process_frame
	for scene_id in P1.keys():
		var path := String(P1[scene_id])
		_expect(ResourceLoader.exists(path), "%s exists" % scene_id)
		_expect(SceneCatalog.path_for(scene_id, "battle") == path, "%s catalog" % scene_id)
	var battle = BattleScreenScript.new()
	add_child(battle)
	await get_tree().process_frame
	battle.set_scene_id("scene.battle.moretti_home")
	_expect(
		battle.get_background_path() == String(P1["scene.battle.moretti_home"]),
		"battle switches to moretti home"
	)
	battle.set_scene_id("scene.battle.elliot_ruin")
	_expect(
		battle.get_background_path() == String(P1["scene.battle.elliot_ruin"]),
		"battle switches to elliot ruin"
	)
	battle.set_scene_id("scene.battle.wood_house")
	_expect(
		battle.get_background_path() == String(P1["scene.battle.wood_house"]),
		"battle switches to wood house"
	)
	battle.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V045_SCENE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V045_SCENE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
