extends Node

const AppBootstrapScript := preload("res://src/app/bootstrap.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")

const P2 := {
	"scene.battle.megose_descent": "res://assets/game/v0.46.0/scenes/battle-megose-descent.png",
	"scene.rest.chanis_gate": "res://assets/game/v0.46.0/scenes/rest-chanis-gate.png",
	"scene.ritual.above_fog": "res://assets/game/v0.46.0/scenes/ritual-above-fog.png",
}

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	for scene_id in P2.keys():
		var path := String(P2[scene_id])
		var kind := "battle"
		if String(scene_id).begins_with("scene.rest."):
			kind = "rest"
		elif String(scene_id).begins_with("scene.ritual."):
			kind = "ritual"
		_expect(ResourceLoader.exists(path), "%s exists" % scene_id)
		_expect(SceneCatalog.path_for(scene_id, kind) == path, "%s catalog" % scene_id)

	var started = AppBootstrapScript.start_route_v07(
		20261117,
		{
			"test_profile": true,
			"save_directory": "user://v046_scene",
			"route_id": "route.v070.broken_procession",
		},
		"v046_scene",
		false
	)
	_expect(started.ok, "broken procession boots")
	if started.ok:
		var by_id := {}
		for node in started.data.get_route_snapshot().data.get("nodes", []):
			if node is Dictionary:
				by_id[String(node.get("id", ""))] = node
		_expect(
			String(by_id.get("route.v070.broken.node.mirror_baron", {}).get("scene_id", ""))
				== "scene.battle.megose_descent",
			"megose boss scene_id"
		)
		_expect(
			String(by_id.get("route.v070.broken.node.ascension", {}).get("scene_id", ""))
				== "scene.ritual.above_fog",
			"above fog ritual scene_id"
		)

	var watch = AppBootstrapScript.start_route_v07(
		20261118,
		{
			"test_profile": true,
			"save_directory": "user://v046_scene_watch",
			"route_id": "route.v070.mirror_watch",
		},
		"v046_scene_watch",
		false
	)
	_expect(watch.ok, "mirror watch boots")
	if watch.ok:
		for node in watch.data.get_route_snapshot().data.get("nodes", []):
			if node is Dictionary and String(node.get("id", "")).ends_with(".rest"):
				_expect(
					String(node.get("scene_id", "")) == "scene.rest.chanis_gate",
					"chanis gate rest scene_id"
				)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V046_SCENE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V046_SCENE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
