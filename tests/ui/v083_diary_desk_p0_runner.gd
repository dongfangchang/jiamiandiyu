extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## v0.84 / BRIEF V083_*: desk 3D book P0 probes.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const DiaryCatalogScript := preload("res://src/ui/diary_ui_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []
var _last_command = null


func _ready() -> void:
	UiContentFixture.ensure()
	var catalog := DiaryCatalogScript.new()
	_expect(catalog.ensure_loaded(), "diary volume loads")
	var nodes := _tingen_nodes()
	var view := catalog.build_view({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"clue_annotations": {},
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
		"nodes": nodes,
	})
	var spreads: Array = view.get("spread_list", [])
	_expect(spreads.size() == 8, "V083_SPREAD_PER_NODE tingen=8")
	if spreads.size() > 0:
		var s0: Dictionary = spreads[0]
		_expect(s0.get("clues", []).size() == 1, "one clue per spread")
		_expect(String(s0.get("node_id", "")).ends_with("first_hunt"), "spread0 is first_hunt")
		_expect(not String(s0.get("left_art_path", "")).is_empty(), "left art path set")
		_expect(String(s0.get("title_zh", "")) != "", "title present")

	var version := String(ProjectSettings.get_setting("application/config/version", ""))
	_expect(version.naturalnocasecmp_to("0.84.0") >= 0, "project supports the v0.84 diary desk")

	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	var screen = DiaryScreenScript.new()
	screen.size = Vector2(1600, 900)
	host.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(screen.has_method("desk_world_ready") and screen.desk_world_ready(), "V083_DESK_WORLD")
	_expect(screen.find_child("DeskCamera", true, false) != null, "DeskCamera present")
	_expect(screen.find_child("CandleMesh", true, false) != null, "CandleMesh present")
	_expect(screen.find_child("RightPageHinge", true, false) != null, "spine hinge present")
	_expect(screen.find_child("WaxSealHit", true, false) != null, "screen wax hit present")
	## The desk stage is the only page carrier: no flat open-book plate anywhere.
	var flat_book_art := false
	for rect in screen.find_children("*", "TextureRect", true, false):
		var tex := (rect as TextureRect).texture
		if tex != null and tex.resource_path.ends_with("open_book_spread.png"):
			flat_book_art = true
	_expect(not flat_book_art, "V083_NO_BOOK_ART_PATH")
	var desk = screen.get_desk_stage() if screen.has_method("get_desk_stage") else null
	_expect(desk != null, "desk stage present")
	if desk != null and desk.has_method("book_is_fullbleed"):
		_expect(not desk.book_is_fullbleed(), "V083_BOOK_NOT_FULLBLEED")
	var book_root := screen.find_child("BookRoot", true, false) as Node3D
	_expect(
		book_root != null and book_root.scale.x <= 0.96 and book_root.scale.x >= 0.7,
		"book scale leaves desk margin"
	)

	screen.route_command_requested.connect(func(cmd): _last_command = cmd)
	var route_dict := {
		"route_id": "route.v028.first_stage",
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": [
			"route.v028.first_stage.node.first_hunt",
			"route.v028.first_stage.node.tenant_trace",
		],
		"completed_node_ids": [],
		"nodes": nodes,
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
	}
	screen.apply_snapshot(RouteSnapshotScript.new(route_dict))
	await get_tree().process_frame

	## Flip commit: both first two unlocked/investigable after first completed? 
	## With first available and second unlocked but prior incomplete → second not investigable.
	## Complete first in snapshot so flip can advance.
	route_dict["completed_node_ids"] = ["route.v028.first_stage.node.first_hunt"]
	route_dict["available_node_id"] = "route.v028.first_stage.node.tenant_trace"
	route_dict["unlocked_node_ids"] = [
		"route.v028.first_stage.node.first_hunt",
		"route.v028.first_stage.node.tenant_trace",
	]
	screen.apply_snapshot(RouteSnapshotScript.new(route_dict))
	await get_tree().process_frame
	## Land on completed first page then flip forward.
	if screen.has_method("get_current_spread_idx"):
		## Force index 0 via present if needed — current_idx may already be 1.
		pass
	var idx0 := int(screen.get_current_spread_idx())
	if desk != null and desk.has_signal("flip_committed"):
		## From idx0, try +1; if at last unlocked leaf, bounce handled separately.
		if idx0 > 0:
			desk.flip_committed.emit(-1)
			await get_tree().process_frame
			## Skip waiting full tween: call finish path by waiting few frames.
			for _i in range(8):
				await get_tree().process_frame
		idx0 = int(screen.get_current_spread_idx())
		desk.flip_committed.emit(1)
		for _i in range(12):
			await get_tree().process_frame
	var idx1 := int(screen.get_current_spread_idx())
	_expect(idx1 != idx0, "V083_FLIP_COMMIT")

	## Bounce: only first unlocked, cannot open second.
	screen.apply_snapshot(RouteSnapshotScript.new({
		"route_id": "route.v028.first_stage",
		"display_name_zh": "第一卷",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"nodes": nodes,
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
	}))
	await get_tree().process_frame
	var before := int(screen.get_current_spread_idx())
	if desk != null:
		desk.flip_committed.emit(1)
		for _i in range(8):
			await get_tree().process_frame
	var after := int(screen.get_current_spread_idx())
	_expect(after == before, "V083_FLIP_BOUNCE")

	## Seal / enter: must be AVAILABLE (bounce snapshot above left first_hunt available).
	_last_command = null
	if desk != null and desk.has_signal("seal_activated"):
		var clue0: Dictionary = {}
		var list: Array = screen.get_page_count() if false else []
		## Prefer wax signal with the current spread clue.
		var spread0 = {}
		if screen.has_method("get_current_spread_idx"):
			## ensure on available leaf 0
			while int(screen.get_current_spread_idx()) > 0:
				desk.flip_committed.emit(-1)
				await get_tree().process_frame
		desk.seal_activated.emit({
			"node_id": "route.v028.first_stage.node.first_hunt",
			"state": 1,
			"node_type": "normal",
			"annotation_zh": "",
		})
		await get_tree().process_frame
	else:
		screen.request_node("route.v028.first_stage.node.first_hunt")
		await get_tree().process_frame
	_expect(_last_command != null, "V083_SEAL_SELECT / API request_node")
	_expect(screen.has_method("apply_snapshot"), "V083_API_COMPAT apply_snapshot")
	_expect(screen.has_method("present_post_encounter"), "V083_API_COMPAT present_post_encounter")

	if _failures.is_empty():
		print("V083_DIARY_DESK_P0_OK checks=%d" % _checks)
	else:
		print("V083_DIARY_DESK_P0_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		for failure in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _tingen_nodes() -> Array:
	return [
		{"id": "route.v028.first_stage.node.first_hunt", "type": "normal", "display_name_zh": "密修会的闯入者", "scene_id": "scene.battle.moretti_home"},
		{"id": "route.v028.first_stage.node.tenant_trace", "type": "normal", "display_name_zh": "艾略特绑架案", "scene_id": "scene.battle.elliot_ruin"},
		{"id": "route.v028.first_stage.node.mirror_pursuit", "type": "elite", "display_name_zh": "提利尔仓库", "scene_id": "scene.battle.tyrell_warehouse"},
		{"id": "route.v028.first_stage.node.boundary", "type": "normal", "display_name_zh": "伍德家的恶灵", "scene_id": "scene.battle.wood_house"},
		{"id": "route.v028.first_stage.node.rest", "type": "rest", "display_name_zh": "占卜俱乐部", "scene_id": "scene.rest.divination_club"},
		{"id": "route.v028.first_stage.node.lamud", "type": "elite", "display_name_zh": "拉姆德小镇驱邪", "scene_id": "scene.battle.lamud_chapel"},
		{"id": "route.v028.first_stage.node.baron", "type": "boss", "display_name_zh": "失控的老尼尔", "scene_id": "scene.battle.blackthorn_neil"},
		{"id": "route.v028.first_stage.node.ascension", "type": "ritual", "display_name_zh": "晋升：小丑", "scene_id": "scene.ritual.clown_ascension"},
	]


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
