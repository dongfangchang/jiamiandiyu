extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## Diary readability captures (EXPERIENCE §5.1): idle + mid-flip of the full
## diary screen at a logical 1600x900 layout rendered into `--phys=WxH`
## physical pixels (SubViewport with size_2d_override stretch, the same
## transform canvas_items stretch applies to a HiDPI window).
##   -- --phys=2920x1753 --out=res://.tools/ui-captures/v089_readability/after
## `--window` instead puts the screen in the real root window and logs its
## size, screen scale and the DeskWorld viewport size.
## Needs a display; excluded from tools/run_tests.sh by name.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")
const LOGICAL := Vector2i(1600, 900)


func _ready() -> void:
	UiContentFixture.ensure()
	TableSfx.set_muted(true)
	var phys := LOGICAL
	var out_dir := "res://.tools/ui-captures/v089_readability/after"
	var use_window := false
	for arg in OS.get_cmdline_user_args():
		var a := String(arg)
		if a.begins_with("--phys="):
			var parts := a.trim_prefix("--phys=").split("x")
			phys = Vector2i(int(parts[0]), int(parts[1]))
		elif a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
		elif a == "--window":
			use_window = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var host: Viewport
	var screen = DiaryScreenScript.new()
	if use_window:
		host = get_tree().root
		host.add_child.call_deferred(screen)
		await get_tree().process_frame
	else:
		## Project stretch aspect is "keep": the window letterboxes, and the
		## content area is LOGICAL scaled uniformly. Render exactly that area.
		var s := minf(float(phys.x) / LOGICAL.x, float(phys.y) / LOGICAL.y)
		var vp := SubViewport.new()
		vp.size = Vector2i(roundi(LOGICAL.x * s), roundi(LOGICAL.y * s))
		vp.size_2d_override = LOGICAL
		vp.size_2d_override_stretch = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.transparent_bg = false
		add_child(vp)
		vp.add_child(screen)
		host = vp
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.apply_snapshot(RouteSnapshotScript.new(_snapshot()))
	for _i in range(6):
		await get_tree().process_frame
	var desk = screen.get_desk_stage()
	desk.force_render_for_capture()
	await get_tree().create_timer(1.0).timeout
	for _j in range(4):
		await get_tree().process_frame
	var tag := "window" if use_window else "%dx%d" % [phys.x, phys.y]
	var world_vp := desk.find_child("DeskWorldViewport", true, false) as SubViewport
	print("READABILITY_PROBE tag=%s window=%s screen_scale=%.2f host_final_scale=%s world_vp=%s" % [
		tag,
		str(get_window().size),
		DisplayServer.screen_get_scale(),
		str(host.get_final_transform().get_scale()),
		str(world_vp.size) if world_vp != null else "?",
	])
	if desk.has_method("get_readability_metrics"):
		print("READABILITY_METRICS %s" % str(desk.get_readability_metrics()))
	await _save(host, "%s/diary_%s_idle.png" % [out_dir, tag])
	desk.call("_apply_flip_visual", 0.36)
	await get_tree().create_timer(0.3).timeout
	for _k in range(4):
		await get_tree().process_frame
	await _save(host, "%s/diary_%s_flip.png" % [out_dir, tag])
	print("READABILITY_CAPTURE_OK dir=%s" % out_dir)
	get_tree().quit(0)


func _save(host: Viewport, path: String) -> void:
	RenderingServer.force_draw()
	await get_tree().process_frame
	var img := host.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s %dx%d" % [path, img.get_width(), img.get_height()])


func _snapshot() -> Dictionary:
	var names := [
		["first_hunt", "normal", "available", "密修会的闯入者", "scene.battle.moretti_home"],
		["tenant_trace", "normal", "locked", "艾略特绑架案", "scene.battle.elliot_ruin"],
		["mirror_pursuit", "normal", "locked", "提利尔仓库", "scene.battle.tyrell_warehouse"],
		["boundary", "normal", "locked", "伍德家的恶灵", "scene.battle.wood_house"],
		["rest", "rest", "locked", "占卜俱乐部", "scene.rest.divination_club"],
		["lamud", "normal", "locked", "拉姆德小镇驱邪", "scene.battle.lamud_chapel"],
		["baron", "normal", "locked", "失控的老尼尔", "scene.battle.blackthorn_neil"],
		["ascension", "ritual", "locked", "晋升：小丑", "scene.ritual.clown_ascension"],
	]
	var nodes: Array = []
	for n in names:
		nodes.append({
			"id": "route.v028.first_stage.node.%s" % n[0],
			"type": n[1], "state": n[2], "display_name_zh": n[3], "scene_id": n[4],
		})
	return {
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
		"nodes": nodes,
	}
