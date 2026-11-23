extends Node

## v0.38.0: route progress / next-step / challenge pathway clarifier.

const RouteScreenScene := preload("res://scenes/ui/route_screen.tscn")
const ChallengeHubScene := preload("res://scenes/ui/challenge_hub_screen.tscn")
const RouteSelectScene := preload("res://scenes/ui/route_select_screen.tscn")
const RestScreenScene := preload("res://scenes/ui/rest_screen.tscn")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	await _test_route_progress()
	await _test_challenge_clarifier()
	await _test_route_select_hook()
	await _test_rest_hook()
	_finish()


func _test_route_progress() -> void:
	var screen = RouteScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.apply_snapshot(RouteSnapshotScript.new({
		"revision": 1,
		"phase": "map",
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"chapter_title_zh": "第一卷·小丑",
		"chapter_phase_zh": "密修会之后",
		"chapter_summary_zh": "沿线索推进廷根调查。",
		"current_node_id": "node.b",
		"route_outcome": "",
		"nodes": [
			{
				"id": "node.a",
				"display_name_zh": "密修会的闯入者",
				"type": "battle",
				"state": "completed",
				"narrative_beat_zh": "密修会潜入莫雷蒂家。",
				"investigation_goal_zh": "守住住所",
				"source_zh": "原著",
			},
			{
				"id": "node.b",
				"display_name_zh": "艾略特绑架案",
				"type": "battle",
				"state": "available",
				"narrative_beat_zh": "绑架案把调查推向码头。",
				"investigation_goal_zh": "追回人质",
				"reward_hint_zh": "保留灵视",
				"source_zh": "原著",
			},
			{
				"id": "node.c",
				"display_name_zh": "提利尔仓库",
				"type": "elite",
				"state": "locked",
				"narrative_beat_zh": "仓库深处有失控者。",
				"investigation_goal_zh": "压制失控",
			},
		],
	}))
	await get_tree().process_frame
	_expect(screen.find_child("RouteProgress", true, false) != null, "progress label exists")
	_expect(screen.get_progress_text().contains("1 / 3"), "progress shows cleared/total")
	_expect(screen.get_progress_text().contains("艾略特"), "progress names next node")
	_expect(screen.find_child("NextStepBadge", true, false) != null, "available node has 下一步 badge")
	_expect(screen.get_status_text().contains("艾略特"), "status points to next node")
	screen.queue_free()
	await get_tree().process_frame


func _test_challenge_clarifier() -> void:
	var screen = ChallengeHubScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	var note := screen.find_child("PathwayClarifier", true, false) as Label
	_expect(note != null, "pathway clarifier exists")
	_expect(note.text.contains("魔术师") or note.text.contains("途径"), "clarifier mentions pathway limit")
	screen.queue_free()
	await get_tree().process_frame


func _test_route_select_hook() -> void:
	var screen = RouteSelectScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	_expect(screen.find_child("MainlineHook", true, false) != null, "mainline hook exists")
	screen.queue_free()
	await get_tree().process_frame


func _test_rest_hook() -> void:
	var screen = RestScreenScene.instantiate()
	add_child(screen)
	await get_tree().process_frame
	screen.apply_snapshot(RouteSnapshotScript.new({
		"revision": 1,
		"phase": "rest_pending",
		"chapter_phase_zh": "从灵视到证据",
		"chapter_summary_zh": "休整后继续追查异常。",
		"rest_options": [{
			"id": "rest.bandage",
			"display_name_zh": "值夜者的包扎",
			"effects": {"heal": 8},
		}],
		"resources": {"hp": 40, "max_hp": 54, "corruption": 1, "attention": 1},
	}))
	await get_tree().process_frame
	var hook := screen.find_child("RestChapterHook", true, false) as Label
	_expect(hook != null, "rest chapter hook exists")
	_expect(hook.text.contains("从灵视到证据"), "rest hook shows chapter phase")
	screen.queue_free()
	await get_tree().process_frame


func _finish() -> void:
	if _failures.is_empty():
		print("V038_NARRATIVE_ROUTE_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("V038_NARRATIVE_ROUTE_FAIL %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
