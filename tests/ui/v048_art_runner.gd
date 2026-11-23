extends Node

const BattleScreenScript := preload("res://src/ui/battle_screen.gd")
const ProgressionCatalog := preload("res://src/ui/progression_ui_catalog.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")

const ENEMY_ART := {
	&"enemy.candle_moth": "res://assets/game/v0.48.0/enemies/enemy-candle-moth.png",
	&"enemy.tingen.kidnapper": "res://assets/game/v0.48.0/enemies/enemy-tingen-kidnapper.png",
	&"enemy.mirror_hound": "res://assets/game/v0.48.0/enemies/enemy-mirror-hound.png",
	&"enemy.tingen.rampager": "res://assets/game/v0.48.0/enemies/enemy-tingen-rampager.png",
	&"enemy.mirror_hound_echo": "res://assets/game/v0.48.0/enemies/enemy-mirror-hound-echo.png",
	&"enemy.weeping_tenant": "res://assets/game/v0.48.0/enemies/enemy-weeping-tenant.png",
	&"enemy.tingen.knight_wraith": "res://assets/game/v0.48.0/enemies/enemy-tingen-knight-wraith.png",
	&"enemy.mirror_baron": "res://assets/game/v0.48.0/enemies/enemy-mirror-baron.png",
	&"enemy.tingen.megose": "res://assets/game/v0.48.0/enemies/enemy-tingen-megose.png",
}

const IDENTITY_ART := {
	"identity.reporter": "res://assets/game/v0.48.0/identities/card-identity-reporter.png",
	"identity.doctor": "res://assets/game/v0.48.0/identities/card-identity-doctor.png",
	"identity.gravedigger": "res://assets/game/v0.48.0/identities/card-identity-gravedigger.png",
}

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	var seen_paths: Dictionary = {}
	var battle = BattleScreenScript.new()
	add_child(battle)
	await get_tree().process_frame

	for definition_id in ENEMY_ART.keys():
		var path := String(ENEMY_ART[definition_id])
		_expect(ResourceLoader.exists(path), "%s exists" % String(definition_id))
		_expect(
			battle.get_enemy_art_path(definition_id) == path,
			"%s battle map" % String(definition_id)
		)
		_expect(not seen_paths.has(path), "%s unique path" % String(definition_id))
		seen_paths[path] = true

	for identity_id in IDENTITY_ART.keys():
		var path := String(IDENTITY_ART[identity_id])
		_expect(ResourceLoader.exists(path), "%s exists" % identity_id)
		_expect(
			ProgressionCatalog.identity_art(identity_id) == path,
			"%s identity catalog" % identity_id
		)

	_expect(
		RouteCatalog.BOSS_ART == String(ENEMY_ART[&"enemy.mirror_baron"]),
		"route boss art uses Neil portrait"
	)
	battle.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V048_ART_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V048_ART_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
