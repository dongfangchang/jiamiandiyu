extends Node

const UiTheme := preload("res://src/ui/mask_ui_theme.gd")
const RouteCatalog := preload("res://src/ui/route_ui_catalog.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const RouteScreenScript := preload("res://src/ui/route_screen.gd")
const ChallengeScreenScript := preload("res://src/ui/challenge_screen.gd")
const BattleScreenScript := preload("res://src/ui/battle_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_expect(RouteCatalog.ROUTE_BACKGROUND_DIM <= 0.35, "route dim not crushing art")
	_expect(SceneCatalog.dim_for("battle") <= 0.35, "battle dim not crushing art")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.custom_minimum_size = Vector2(1600, 900)
	add_child(host)
	UiTheme.add_background(host, RouteCatalog.ROUTE_BACKGROUND, UiTheme.C_BG, 0.28)
	await get_tree().process_frame
	var bg := host.find_child("SceneBackground", true, false) as TextureRect
	_expect(bg != null, "scene background exists")
	var holder := host.get_node_or_null("SceneBackgroundHolder") as Control
	_expect(holder != null, "scene background holder exists")
	if bg != null and holder != null:
		_expect(holder.clip_contents, "background holder clips to canvas")

	var route = RouteScreenScript.new()
	route.custom_minimum_size = Vector2(1600, 900)
	add_child(route)
	await get_tree().process_frame
	var summary := route.find_child("ChapterSummaryBox", true, false)
	_expect(summary is Label, "chapter summary is expanding label")
	_expect(not (summary is ScrollContainer), "chapter summary is not a scroll box")
	var goal := route.find_child("CurrentGoalBox", true, false)
	_expect(goal is Label, "current goal is expanding label")
	route.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"chapter_title_zh": "第一卷《小丑》：廷根",
		"chapter_phase_zh": "密修会的闯入",
		"chapter_summary_zh": "从莫雷蒂家的闯入开始，沿着廷根值夜者的夏天推进调查。",
		"phase": "map",
		"current_node_id": "route.v028.first_stage.node.intruder",
		"nodes": [
			{
				"id": "route.v028.first_stage.node.intruder",
				"display_name_zh": "密修会的闯入者",
				"type": "normal",
				"state": "available",
				"investigation_goal_zh": "确认闯入者身份并保住家人",
				"narrative_beat_zh": "深夜，密修会成员潜入莫雷蒂家。",
				"source_zh": "第一卷 6月30日",
			}
		],
	}))
	await get_tree().process_frame
	_expect(
		is_instance_valid(summary) and (summary as Label).visible
			and not String((summary as Label).text).is_empty(),
		"chapter summary visible with text"
	)
	var story := route.find_child("NodeStoryBox", true, false)
	_expect(story is Label, "node story is expanding label")
	_expect(not (story is ScrollContainer), "node story is not a scroll box")

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

	route.queue_free()
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
