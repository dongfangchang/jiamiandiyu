extends Node

## AR-05 · Renderer compare capture (ADR-0035 evidence).
## Run WITH a display (never --headless). Switch via CLI:
##   Godot --path . --rendering-method <gl_compatibility|mobile|forward_plus> \
##     res://tools/architecture/ar05_renderer_compare_runner.tscn
## Does not mutate project.godot.

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")
const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const CAPTURE_SIZE := Vector2i(2920, 1753)
const OUT_DIR := "res://.tools/ui-captures/ar05_renderer"
const SAMPLE_FRAMES := 48


func _ready() -> void:
	UiContentFixture.ensure()
	DisplayServer.window_set_size(CAPTURE_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var method := String(RenderingServer.get_current_rendering_method())
	var driver := String(RenderingServer.get_current_rendering_driver_name())
	var slug := method.replace("+", "plus").replace("/", "_")
	print("AR05_RENDERER method=%s driver=%s size=%dx%d" % [
		method, driver, CAPTURE_SIZE.x, CAPTURE_SIZE.y
	])

	var viewport := SubViewport.new()
	viewport.name = "Ar05CaptureViewport"
	viewport.size = CAPTURE_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var screen = DiaryScreenScript.new()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.set_deferred("size", Vector2(CAPTURE_SIZE))
	screen.apply_snapshot(_snapshot())

	for _i in range(8):
		await get_tree().process_frame

	var desk = screen.get_desk_stage() if screen.has_method("get_desk_stage") else null
	if desk != null and desk.has_method("force_render_for_capture"):
		desk.force_render_for_capture()

	await get_tree().create_timer(0.9).timeout
	for _j in range(4):
		await get_tree().process_frame

	var baseline_path := "%s/%s_baseline.png" % [OUT_DIR, slug]
	if not await _save_shot(viewport, baseline_path):
		printerr("AR05_RENDERER_FAIL baseline")
		get_tree().quit(1)
		return

	var fx_info := _apply_quality_fx(desk)
	await get_tree().create_timer(0.6).timeout
	for _k in range(4):
		await get_tree().process_frame

	var fx_path := "%s/%s_fx.png" % [OUT_DIR, slug]
	if not await _save_shot(viewport, fx_path):
		printerr("AR05_RENDERER_FAIL fx")
		get_tree().quit(1)
		return

	var fps_stats := await _sample_fps(SAMPLE_FRAMES)
	var report_path := "%s/%s_report.txt" % [OUT_DIR, slug]
	var report := _build_report(method, driver, fx_info, fps_stats, baseline_path, fx_path)
	var abs_report := ProjectSettings.globalize_path(report_path)
	var f := FileAccess.open(abs_report, FileAccess.WRITE)
	if f == null:
		printerr("AR05_RENDERER_FAIL report write")
		get_tree().quit(1)
		return
	f.store_string(report)
	f.close()
	print(report)
	print("AR05_RENDERER_OK method=%s baseline=%s fx=%s report=%s" % [
		method, baseline_path, fx_path, report_path
	])
	get_tree().quit(0)


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


func _world_env(desk: Control) -> Environment:
	if desk == null:
		return null
	var world_vp := desk.find_child("DeskWorldViewport", true, false) as SubViewport
	if world_vp == null or world_vp.world_3d == null:
		return null
	return world_vp.world_3d.environment


func _apply_quality_fx(desk: Control) -> Dictionary:
	## Same Environment knobs on every renderer; unsupported ones no-op or degrade.
	var env := _world_env(desk)
	var info := {
		"env_found": env != null,
		"ssao_requested": true,
		"glow_requested": true,
		"tonemap_requested": "ACES",
		"ssao_enabled_after": false,
		"glow_enabled_after": false,
		"tonemap_after": "",
	}
	if env == null:
		return info
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.2
	env.ssao_power = 1.5
	env.ssao_detail = 0.55
	info["ssao_enabled_after"] = env.ssao_enabled
	info["glow_enabled_after"] = env.glow_enabled
	info["tonemap_after"] = str(env.tonemap_mode)
	return info


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


func _build_report(
	method: String,
	driver: String,
	fx_info: Dictionary,
	fps_stats: Dictionary,
	baseline_path: String,
	fx_path: String
) -> String:
	var lines: PackedStringArray = []
	lines.append("AR-05 renderer compare")
	lines.append("method=%s" % method)
	lines.append("driver=%s" % driver)
	lines.append("capture_size=%dx%d" % [CAPTURE_SIZE.x, CAPTURE_SIZE.y])
	lines.append("platform=%s" % OS.get_name())
	lines.append("fps_avg=%.1f fps_min=%.1f fps_max=%.1f samples=%d" % [
		float(fps_stats.get("avg", 0.0)),
		float(fps_stats.get("min", 0.0)),
		float(fps_stats.get("max", 0.0)),
		int(fps_stats.get("samples", 0)),
	])
	lines.append("fx_env_found=%s" % str(fx_info.get("env_found", false)))
	lines.append("fx_ssao_enabled=%s" % str(fx_info.get("ssao_enabled_after", false)))
	lines.append("fx_glow_enabled=%s" % str(fx_info.get("glow_enabled_after", false)))
	lines.append("fx_tonemap=%s" % str(fx_info.get("tonemap_after", "")))
	lines.append("baseline=%s" % baseline_path)
	lines.append("fx=%s" % fx_path)
	return "\n".join(lines) + "\n"


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
	## Also write absolute path confirmation for polling evidence.
	print("AR05_SAVED path=%s bytes=%d" % [path, img.get_data().size()])
	return true
