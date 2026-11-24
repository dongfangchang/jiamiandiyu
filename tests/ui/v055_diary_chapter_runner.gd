extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## v0.55: diary chapter hub replaces route-tree map UI.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const DiaryCatalogScript := preload("res://src/ui/diary_ui_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	var catalog := DiaryCatalogScript.new()
	_expect(catalog.ensure_loaded(), "diary volume loads")
	var view := catalog.build_view({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": [
			"route.v028.first_stage.node.first_hunt",
			"route.v028.first_stage.node.tenant_trace",
		],
		"completed_node_ids": [],
		"clue_annotations": {},
		"run_state": {
			"hp": 30,
			"max_hp": 30,
			"spirit": 10,
			"max_spirit": 10,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
		},
		"nodes": [
			{
				"id": "route.v028.first_stage.node.first_hunt",
				"type": "normal",
				"state": "available",
			},
			{
				"id": "route.v028.first_stage.node.tenant_trace",
				"type": "normal",
				"state": "available",
			},
			{
				"id": "route.v028.first_stage.node.rest",
				"type": "rest",
				"state": "locked",
			},
		],
	})
	_expect(String(view.get("carrier_zh", "")) == "罗塞尔日记", "carrier is diary")
	var pages: Array = view.get("pages", [])
	## v0.84 P0: one main clue per spread (was multi-clue pages in v0.55).
	_expect(pages.size() >= 8, "diary has one spread per main clue")
	if pages.size() > 0:
		var page0: Dictionary = pages[0]
		_expect(page0.get("clues", []).size() == 1, "one clue per spread")
		_expect(page0.has("left_clues") and page0.has("right_clues"), "spread has left/right clue arrays")
		_expect(page0.has("is_main_complete"), "spread has is_main_complete")
	if pages.size() > 1:
		var page1: Dictionary = pages[1]
		var leaked := 0
		for clue_value in page1.get("clues", []):
			if clue_value is Dictionary and int(clue_value.get("state", 0)) == 1:
				leaked += 1
		_expect(leaked == 0, "later page gated until prior mains done")

	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	var screen = DiaryScreenScript.new()
	screen.size = Vector2(1600, 900)
	host.add_child(screen)
	screen.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"clue_annotations": {},
		"run_state": {
			"hp": 30,
			"max_hp": 30,
			"spirit": 10,
			"max_spirit": 10,
			"corruption": 1,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
		},
		"nodes": [{
			"id": "route.v028.first_stage.node.first_hunt",
			"type": "normal",
			"state": "available",
		}],
	}))
	await get_tree().process_frame
	_expect(screen.get_page_count() >= 2, "screen page count")
	_expect(screen.get_background_path() == SceneCatalog.ui_canvas(), "uses rain-night canvas")
	_expect(not screen.is_page_flipping(), "not flipping on load")
	## v0.84 P0: enter control is desk WaxSealButton (legacy ClueHit retired from main path).
	var wax := screen.find_child("WaxSealButton", true, false) as Button
	_expect(wax != null, "wax seal enter control present")
	_expect(wax != null and not wax.disabled, "available wax seal enabled")
	_expect(screen.find_child("DiaryDeskStage", true, false) != null, "desk stage present")
	_expect(screen.find_child("DeskWorld", true, false) != null, "desk world present")
	var status := screen.get_status_text()
	_expect(status.find("前往节点") < 0, "no node-forward prompt")
	## Status may say 本叶/调查; desk P0 no longer requires the word 线索.
	_expect(screen.find_child("DiaryHeader", true, false) != null, "diary header present")
	_expect(screen.find_child("WaxSealButton", true, false) != null, "wax seal is P0 locked/enter affordance")
	_expect(FileAccess.file_exists("res://src/ui/diary_desk_stage.gd"), "desk stage script present")
	_expect(screen.find_child("PenFlashBanner", true, false) != null, "pen flash banner node present")
	_expect(screen.find_child("HeaderParchment", true, false) != null, "header parchment plate")
	_expect(screen.find_child("FooterParchment", true, false) != null, "footer parchment plate")
	var close := screen.find_child("CloseBookmark", true, false) as Button
	_expect(close != null and close.visible and not close.disabled, "close bookmark is live")

	## Desk forward flip gated until current spread mains complete.
	var desk = screen.get_desk_stage() if screen.has_method("get_desk_stage") else null
	if desk != null:
		desk.flip_committed.emit(1)
		await get_tree().process_frame
	_expect(screen.get_current_spread_idx() == 0, "forward flip blocked before mains done")
	_expect(not screen.is_page_flipping(), "no flip lock when blocked")

	## Complete first four mains; P0 opens spread 4 (rest).
	var all_first_page := [
		"route.v028.first_stage.node.first_hunt",
		"route.v028.first_stage.node.tenant_trace",
		"route.v028.first_stage.node.mirror_pursuit",
		"route.v028.first_stage.node.boundary",
	]
	screen.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.rest",
		"unlocked_node_ids": all_first_page + ["route.v028.first_stage.node.rest"],
		"completed_node_ids": all_first_page,
		"clue_annotations": {},
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
		"nodes": [],
	}))
	await get_tree().process_frame
	_expect(screen.get_current_spread_idx() == 4, "opens next incomplete spread after mains done")

	## Lookback then forward via desk (immediate commit).
	TableSfx.reset_for_tests()
	var flip_started := {"v": false}
	var flip_finished := {"v": false}
	screen.page_flip_started.connect(func() -> void: flip_started["v"] = true)
	screen.page_flip_finished.connect(func() -> void: flip_finished["v"] = true)
	if desk != null:
		desk.flip_committed.emit(-1)
		await get_tree().process_frame
	_expect(flip_started["v"], "page_flip_started emitted")
	_expect(flip_finished["v"], "page_flip_finished emitted")
	_expect(not screen.is_page_flipping(), "is_flipping false after flip")
	_expect(screen.get_current_spread_idx() == 3, "returned to prior spread")
	_expect(TableSfx.call_count(TableSfx.KIND_FLIP) >= 1, "flip plays table sfx")
	wax = screen.find_child("WaxSealButton", true, false) as Button
	_expect(wax != null, "wax seal present after flip")
	flip_started["v"] = false
	flip_finished["v"] = false
	if desk != null:
		desk.flip_committed.emit(1)
		await get_tree().process_frame
	_expect(flip_finished["v"], "forward flip after complete works")
	_expect(screen.get_current_spread_idx() == 4, "advanced to second spread")

	## Rewritten overlay lives in catalog fields (desk ink), not PenRewriteStamp Control.
	var rewritten_locked := {
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"clue_annotations": {},
		"clue_overlays": {
			"route.v028.first_stage.node.tenant_trace": {
				"text_zh": "（0-08 已改写）夜色里另有一行字。",
				"margin_note_zh": "笔改",
			},
		},
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
		"nodes": [],
	}
	screen.apply_snapshot(RouteSnapshotScript.new(rewritten_locked))
	await get_tree().process_frame
	var rewrite_view := catalog.build_view(rewritten_locked)
	var rewrite_ok := false
	for page_value in rewrite_view.get("pages", []):
		for clue_value in page_value.get("clues", []):
			if (
				clue_value is Dictionary
				and String(clue_value.get("node_id", "")).ends_with("tenant_trace")
				and bool(clue_value.get("rewritten_by_pen", false))
			):
				rewrite_ok = true
	_expect(rewrite_ok, "0-08 rewrite stamp on locked overlay clue")

	## Completed clue shows annotation text path.
	var annotated_data := {
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.tenant_trace",
		"unlocked_node_ids": [
			"route.v028.first_stage.node.first_hunt",
			"route.v028.first_stage.node.tenant_trace",
		],
		"completed_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"clue_annotations": {
			"route.v028.first_stage.node.first_hunt": "【0-08】真相落下。",
		},
		"run_state": {
			"hp": 28,
			"max_hp": 30,
			"spirit": 8,
			"max_spirit": 10,
			"corruption": 0,
			"max_corruption": 10,
			"attention": 0,
			"max_attention": 10,
		},
		"nodes": [
			{
				"id": "route.v028.first_stage.node.first_hunt",
				"type": "normal",
				"state": "completed",
			},
			{
				"id": "route.v028.first_stage.node.tenant_trace",
				"type": "normal",
				"state": "available",
			},
		],
	}
	screen.apply_snapshot(RouteSnapshotScript.new(annotated_data))
	await get_tree().process_frame
	var completed_view := catalog.build_view(annotated_data)
	var found_annotation := false
	for page_value in completed_view.get("pages", []):
		for clue_value in page_value.get("clues", []):
			if (
				clue_value is Dictionary
				and String(clue_value.get("node_id", ""))
					== "route.v028.first_stage.node.first_hunt"
			):
				found_annotation = String(clue_value.get("annotation_zh", "")).begins_with("【0-08】")
	_expect(found_annotation, "0-08 annotation on completed clue")

	## Post-battle return path: present_post_encounter flashes 0-08 without apply_command_result.
	screen.present_post_encounter(
		"route.v028.first_stage.node.first_hunt",
		"victory"
	)
	await get_tree().process_frame
	var pen_flash := screen.find_child("PenFlash", true, false) as Label
	var pen_banner := screen.find_child("PenFlashBanner", true, false) as Control
	_expect(pen_flash != null and pen_flash.visible, "0-08 pen flash after post-encounter")
	_expect(pen_banner != null and pen_banner.visible, "pen flash banner visible")
	_expect(
		screen.get_status_text().find("0-08") >= 0,
		"status carries 0-08 settlement text"
	)
	_expect(screen.get_current_spread_idx() == 0, "settlement keeps focus on resolved spread")

	## Completing the last main of a spread schedules auto-flip after flash delay.
	var all_mains_done := {
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.rest",
		"unlocked_node_ids": all_first_page + ["route.v028.first_stage.node.rest"],
		"completed_node_ids": all_first_page,
		"clue_annotations": {
			"route.v028.first_stage.node.boundary": "【0-08】真相落下。",
		},
		"run_state": {
			"hp": 28, "max_hp": 30, "spirit": 8, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
		"nodes": [],
	}
	screen.apply_snapshot(RouteSnapshotScript.new(all_mains_done))
	await get_tree().process_frame
	## Focus completed boundary (spread 3); auto-flip should advance to rest (spread 4).
	screen.present_post_encounter(
		"route.v028.first_stage.node.boundary",
		"victory"
	)
	await get_tree().process_frame
	_expect(screen.get_current_spread_idx() == 3, "focus completed spread before auto flip")
	await get_tree().create_timer(2.5).timeout
	await get_tree().create_timer(1.0).timeout
	_expect(screen.get_current_spread_idx() == 4, "auto flip after spread mains complete")

	_finish()


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("V055_DIARY_CHAPTER_OK checks=%d" % _checks)
	else:
		print("V055_DIARY_CHAPTER_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
	get_tree().quit(0 if _failures.is_empty() else 1)
