extends Node

## v0.44: P0 scene PNGs exist; catalog resolves; route nodes carry scene_id.

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const BattleScreenScript := preload("res://src/ui/battle_screen.gd")
const RestScreenScript := preload("res://src/ui/rest_screen.gd")
const RitualScreenScript := preload("res://src/ui/ritual_screen.gd")

const P0 := {
	"scene.battle.tyrell_warehouse": "res://assets/game/v0.44.0/scenes/battle-tyrell-warehouse.png",
	"scene.battle.blackthorn_neil": "res://assets/game/v0.44.0/scenes/battle-blackthorn-neil.png",
	"scene.battle.lamud_chapel": "res://assets/game/v0.44.0/scenes/battle-lamud-chapel.png",
	"scene.rest.divination_club": "res://assets/game/v0.44.0/scenes/rest-divination-club.png",
	"scene.ritual.clown_ascension": "res://assets/game/v0.44.0/scenes/ritual-clown-ascension.png",
}

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	for scene_id in P0.keys():
		var path := String(P0[scene_id])
		_expect(ResourceLoader.exists(path), "%s png exists" % scene_id)
		var kind := "battle"
		if String(scene_id).begins_with("scene.rest."):
			kind = "rest"
		elif String(scene_id).begins_with("scene.ritual."):
			kind = "ritual"
		_expect(SceneCatalog.path_for(scene_id, kind) == path, "%s catalog path" % scene_id)

	var battle = BattleScreenScript.new()
	add_child(battle)
	await get_tree().process_frame
	battle.set_scene_id("scene.battle.tyrell_warehouse")
	_expect(
		battle.get_background_path() == String(P0["scene.battle.tyrell_warehouse"]),
		"battle screen switches to warehouse"
	)
	battle.queue_free()

	var rest = RestScreenScript.new()
	add_child(rest)
	await get_tree().process_frame
	rest.set_scene_id("scene.rest.divination_club")
	_expect(
		rest.get_background_path() == String(P0["scene.rest.divination_club"]),
		"rest screen switches to club"
	)
	rest.queue_free()

	var ritual = RitualScreenScript.new()
	add_child(ritual)
	await get_tree().process_frame
	ritual.set_scene_id("scene.ritual.clown_ascension")
	_expect(
		ritual.get_background_path() == String(P0["scene.ritual.clown_ascension"]),
		"ritual screen switches to clown ascension"
	)
	ritual.queue_free()

	var started = AppBootstrapScript.start_route_v07(
		20261117,
		{
			"test_profile": true,
			"save_directory": "user://v044_scene",
			"route_id": "route.v028.first_stage",
		},
		"v044_scene",
		false
	)
	_expect(started.ok, "tingen route boots")
	if started.ok:
		var session = started.data
		var nodes: Array = session.get_route_snapshot().data.get("nodes", [])
		var by_id := {}
		for node in nodes:
			if node is Dictionary:
				by_id[String(node.get("id", ""))] = node
		_expect(
			String(by_id.get("route.v028.first_stage.node.mirror_pursuit", {}).get("scene_id", ""))
				== "scene.battle.tyrell_warehouse",
			"warehouse node has scene_id"
		)
		_expect(
			String(by_id.get("route.v028.first_stage.node.rest", {}).get("scene_id", ""))
				== "scene.rest.divination_club",
			"club rest has scene_id"
		)
		_expect(
			String(by_id.get("route.v028.first_stage.node.baron", {}).get("scene_id", ""))
				== "scene.battle.blackthorn_neil",
			"neil boss has scene_id"
		)
		_expect(
			String(by_id.get("route.v028.first_stage.node.ascension", {}).get("scene_id", ""))
				== "scene.ritual.clown_ascension",
			"ascension has scene_id"
		)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V044_SCENE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V044_SCENE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
