extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const ChallengeScreenScript := preload("res://src/ui/challenge_screen.gd")
const BattleScreenScript := preload("res://src/ui/battle_screen.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	await get_tree().process_frame
	_expect(RouteCatalog.ROUTE_BACKGROUND_DIM <= 0.35, "route dim not crushing art")
	_expect(SceneCatalog.dim_for("battle") <= 0.35, "battle dim not crushing art")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.custom_minimum_size = Vector2(1600, 900)
	add_child(host)
	UiTheme.add_background(host, RouteCatalog.route_background(), UiTheme.C_BG, 0.28)
	await get_tree().process_frame
	var bg := host.find_child("SceneBackground", true, false) as TextureRect
	_expect(bg != null, "scene background exists")
	var holder := host.get_node_or_null("SceneBackgroundHolder") as Control
	_expect(holder != null, "scene background holder exists")
	if bg != null and holder != null:
		_expect(holder.clip_contents, "background holder clips to canvas")

	var challenge = ChallengeScreenScript.new()
	add_child(challenge)
	await get_tree().process_frame
	var desc := challenge.find_child("ChallengeDescriptionBox", true, false)
	_expect(desc is Label, "challenge description is expanding label")

	var battle = BattleScreenScript.new()
	add_child(battle)
	await get_tree().process_frame
	var battle_holder := battle.get_node_or_null("SceneBackgroundHolder") as Control
	var battle_bg := battle.find_child("SceneBackground", true, false) as TextureRect
	_expect(
		battle_holder != null and battle_bg != null and battle_holder.clip_contents,
		"battle background covers canvas"
	)

	challenge.queue_free()
	battle.queue_free()
	host.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("V050_UI_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V050_UI_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
