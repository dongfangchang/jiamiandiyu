extends Node

## UI-P0-3-fix evidence: Forward+ diary shots at 1600×900 + 2920×1753, plus HiDPI fps.
## Run WITH a display (never --headless). Excluded from default test gate (*capture*).

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")
const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const OUT_DIR := "res://docs/reports/v0.89.0"
const OUT_1600 := OUT_DIR + "/ui_p0_3_fix_diary_1600x900.png"
const OUT_HIDPI := OUT_DIR + "/ui_p0_3_fix_diary_2920x1753.png"
const SAMPLE_FRAMES := 60


func _ready() -> void:
	UiContentFixture.ensure()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var method := String(RenderingServer.get_current_rendering_method())
	var driver := String(RenderingServer.get_current_rendering_driver_name())
	print("V089_DQ_CAPTURE method=%s driver=%s" % [method, driver])

	if not await _capture_at(Vector2i(1600, 900), OUT_1600, false):
		printerr("V089_DQ_CAPTURE_FAIL 1600")
		get_tree().quit(1)
		return
	if not await _capture_at(Vector2i(2920, 1753), OUT_HIDPI, true):
		printerr("V089_DQ_CAPTURE_FAIL hidpi")
		get_tree().quit(1)
		return
	print("V089_DQ_CAPTURE_OK idle1600=%s hidpi=%s" % [OUT_1600, OUT_HIDPI])
	get_tree().quit(0)


func _capture_at(size: Vector2i, path: String, sample_fps: bool) -> bool:
	DisplayServer.window_set_size(size)
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var screen = DiaryScreenScript.new()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.set_deferred("size", Vector2(size))
	screen.apply_snapshot(_snapshot())

	for _i in range(8):
		await get_tree().process_frame
	var desk = screen.get_desk_stage() if screen.has_method("get_desk_stage") else null
	if desk != null and desk.has_method("force_render_for_capture"):
		desk.force_render_for_capture()
	await get_tree().create_timer(0.8).timeout
	for _j in range(4):
		await get_tree().process_frame

	if not await _save_shot(viewport, path):
		viewport.queue_free()
		return false

	if sample_fps:
		## Drop cold-start frames before sampling the idle budget.
		for _warm in range(24):
			await get_tree().process_frame
		var fps_stats := await _sample_fps(SAMPLE_FRAMES)
		print(
			"V089_DQ_FPS size=%dx%d avg=%.1f min=%.1f max=%.1f samples=%d"
			% [
				size.x,
				size.y,
				float(fps_stats.get("avg", 0.0)),
				float(fps_stats.get("min", 0.0)),
				float(fps_stats.get("max", 0.0)),
				int(fps_stats.get("samples", 0)),
			]
		)

	viewport.queue_free()
	await get_tree().process_frame
	return true


func _snapshot() -> RefCounted:
	return RouteSnapshotScript.new({
		"route_id": "route.v028.first_stage",
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
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
		"nodes": [
			{
				"id": "route.v028.first_stage.node.first_hunt",
				"type": "normal",
				"state": "available",
				"display_name_zh": "密修会的闯入者",
				"scene_id": "scene.battle.moretti_home",
			},
			{
				"id": "route.v028.first_stage.node.tenant_trace",
				"type": "normal",
				"state": "locked",
				"display_name_zh": "艾略特绑架案",
				"scene_id": "scene.battle.elliot_ruin",
			},
		],
	})


func _sample_fps(frames: int) -> Dictionary:
	var sum := 0.0
	var min_fps := 9999.0
	var max_fps := 0.0
	var n := 0
	for _i in range(frames):
		await get_tree().process_frame
		var fps := float(Engine.get_frames_per_second())
		if fps <= 0.0:
			continue
		sum += fps
		n += 1
		min_fps = minf(min_fps, fps)
		max_fps = maxf(max_fps, fps)
	return {
		"samples": n,
		"avg": (sum / float(n)) if n > 0 else 0.0,
		"min": min_fps if n > 0 else 0.0,
		"max": max_fps if n > 0 else 0.0,
	}


func _save_shot(viewport: SubViewport, path: String) -> bool:
	RenderingServer.force_draw()
	await get_tree().process_frame
	var tex: ViewportTexture = viewport.get_texture()
	if tex == null:
		printerr("capture texture null for %s" % path)
		return false
	var img: Image = tex.get_image()
	if img == null:
		printerr("capture image null for %s" % path)
		return false
	var err := img.save_png(path)
	if err != OK:
		printerr("capture save failed %s err=%s" % [path, str(err)])
		return false
	print("V089_DQ_SAVED path=%s" % path)
	return true
