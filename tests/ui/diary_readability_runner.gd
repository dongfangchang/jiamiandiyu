extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## EXPERIENCE §5.1 / ADR-0034 D3 diary readability floors, headless-safe:
## - the DeskWorld viewport follows physical pixels (host stretched from the
##   logical 1600x900 like canvas_items stretch on a HiDPI window), including
##   after a resize;
## - page viewports are at least 1024x1440;
## - projected on-screen text sizes, ink contrast, reading angle and book
##   framing meet the floors, through public probes only;
## - chrome text sizes meet the floors;
## - AR-07: after DeskQuality, camera→page samples are not occluded by
##   non-book meshes (corners / title / body / wax on both leaves).

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const DeskStage := preload("res://src/ui/diary_desk_stage.gd")
const PagePair := preload("res://src/ui/diary_page_pair.gd")
const DiaryCatalog := preload("res://src/ui/diary_ui_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")
const LOGICAL := Vector2i(1600, 900)

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	TableSfx.set_muted(true)
	var host := SubViewport.new()
	host.size = _physical(Vector2i(2920, 1753))
	host.size_2d_override = LOGICAL
	host.size_2d_override_stretch = true
	add_child(host)
	var screen = DiaryScreenScript.new()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.apply_snapshot(RouteSnapshotScript.new(_snapshot("available")))
	await _frames(3)
	var desk: Control = screen.get_desk_stage()

	## 1. Physical-pixel world viewport, at HiDPI and after a resize.
	_expect(desk.size == Vector2(LOGICAL), "desk lays out in logical 1600x900 (%s)" % str(desk.size))
	_expect(desk.get_world_viewport_size() == host.size, "HiDPI world viewport = physical %s (got %s)" % [str(host.size), str(desk.get_world_viewport_size())])
	for phys in [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(3200, 1800)]:
		host.size = _physical(phys)
		await _frames(2)
		_expect(desk.get_world_viewport_size() == host.size, "resized world viewport = physical %s (got %s)" % [str(host.size), str(desk.get_world_viewport_size())])
		_expect(desk.expected_world_viewport_size() == host.size, "expected size follows host scale %s" % str(host.size))
	var world_vp := desk.find_child("DeskWorldViewport", true, false) as SubViewport
	_expect(world_vp != null and world_vp.size == host.size, "DeskWorldViewport node carries the physical size")

	## 2. Page viewports.
	for vp_name in ["LeftPageViewport", "RightPageViewport"]:
		var vp := desk.find_child(vp_name, true, false) as SubViewport
		_expect(vp != null and vp.size.x >= 1024 and vp.size.y >= 1440, "%s >= 1024x1440 (%s)" % [vp_name, str(vp.size) if vp else "missing"])
	_expect(PagePair.PAGE_VP_SIZE == Vector2i(Vector2(PagePair.PAGE_BASE_SIZE) * PagePair.PAGE_SCALE), "page size derives from PAGE_SCALE")

	## 3/4. Text on screen, contrast, posture, framing (per leaf state).
	for state in ["available", "completed", "locked"]:
		screen.apply_snapshot(RouteSnapshotScript.new(_snapshot(state)))
		await _frames(2)
		var m: Dictionary = desk.get_readability_metrics()
		_expect(float(m["screen_body_px"]) >= 20.0, "%s body >= 20px on screen (%.1f)" % [state, m["screen_body_px"]])
		_expect(float(m["screen_title_px"]) >= 28.0, "%s title >= 28px on screen (%.1f)" % [state, m["screen_title_px"]])
		_expect(float(m["screen_caption_px"]) >= 15.0, "%s caption >= 15px on screen (%.1f)" % [state, m["screen_caption_px"]])
		_expect(float(m["contrast_body"]) >= 4.5, "%s body contrast >= 4.5 (%.2f)" % [state, m["contrast_body"]])
		_expect(float(m["contrast_title"]) >= 4.5, "%s title contrast >= 4.5 (%.2f)" % [state, m["contrast_title"]])
		_expect(float(m["contrast_caption"]) >= 3.0, "%s caption contrast >= 3 (%.2f)" % [state, m["contrast_caption"]])
		_expect(float(m["reading_angle_deg"]) <= DeskStage.READING_ANGLE_MAX_DEG, "%s reading angle <= 25 deg (%.1f)" % [state, m["reading_angle_deg"]])
		var frac := float(m["book_width_frac"])
		_expect(frac >= 0.55 and frac <= 0.65, "%s book spans 55-65%% of the width (%.3f)" % [state, frac])

	## 5. Chrome.
	var chrome: Dictionary = screen.get_chrome_font_sizes()
	_expect(int(chrome["title"]) >= 28, "volume title >= 28px (%d)" % chrome["title"])
	for key in ["carrier", "hint", "close", "note"]:
		_expect(int(chrome[key]) >= 15, "chrome %s >= 15px (%d)" % [key, chrome[key]])

	## 6. Occlusion (AR-07): full stage with DeskQuality; non-book mesh on a
	## camera→page sample segment fails (exposes leaned RoomBack / RoomBackplate).
	var occ: Dictionary = desk.get_page_occlusion_report()
	_expect(bool(occ.get("quality_backplate_present", false)), "DeskQuality backplate present for occlusion stage")
	_expect(bool(occ.get("clear", false)), _occlusion_failure_label(occ))
	_finish()


func _occlusion_failure_label(occ: Dictionary) -> String:
	if bool(occ.get("clear", false)):
		return "page samples clear of non-book occluders (hits=0)"
	var hits: Array = occ.get("hits", [])
	var preview: PackedStringArray = PackedStringArray()
	for i in mini(hits.size(), 4):
		var h: Dictionary = hits[i]
		preview.append("%s/%s←%s" % [h.get("side", "?"), h.get("sample", "?"), h.get("occluder", "?")])
	var more := "" if hits.size() <= 4 else " +%d" % (hits.size() - 4)
	return "page samples clear of non-book occluders (hits=%d: %s%s)" % [
		int(occ.get("hit_count", hits.size())),
		", ".join(preview),
		more,
	]


static func _physical(window: Vector2i) -> Vector2i:
	## canvas_items stretch with aspect "keep": uniform scale, letterboxed.
	var s := minf(float(window.x) / LOGICAL.x, float(window.y) / LOGICAL.y)
	return Vector2i(roundi(LOGICAL.x * s), roundi(LOGICAL.y * s))


func _frames(n: int) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _snapshot(first_state: String) -> Dictionary:
	var first := "route.v028.first_stage.node.first_hunt"
	return {
		"route_id": "route.v028.first_stage",
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": first if first_state == "available" else "",
		"unlocked_node_ids": [first] if first_state != "locked" else [],
		"completed_node_ids": [first] if first_state == "completed" else [],
		"clue_annotations": {},
		"run_state": {"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10},
		"nodes": [
			{"id": first, "type": "normal", "state": first_state,
				"display_name_zh": "密修会的闯入者", "scene_id": "scene.battle.moretti_home"},
			{"id": "route.v028.first_stage.node.tenant_trace", "type": "normal", "state": "locked",
				"display_name_zh": "艾略特绑架案", "scene_id": "scene.battle.elliot_ruin"},
		],
	}


func _finish() -> void:
	if _failures.is_empty():
		print("DIARY_READABILITY_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("DIARY_READABILITY_FAIL: %s" % failure)
	print("DIARY_READABILITY_FAIL checks=%d" % _checks)
	get_tree().quit(1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
