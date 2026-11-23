extends Node

## v0.84 flip-arc burst: samples a REAL programmatic turn (play_flip) at fixed
## offsets so the easing curve, the mid-turn content swap and the settle can be
## eyeballed as a strip. Poses are NOT forced — this captures what ships.
## Needs a display (DeskWorld is a 3D SubViewport); headless renders black.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const OUT_DIR := "res://.tools/ui-captures/v084_flipstrip"
## Turn is PROG_FLIP_DURATION 0.56s, commit fires at 45% (~252ms).
const SAMPLE_MS := [0, 70, 140, 210, 260, 330, 400, 470, 560, 700]

var _mains := [
	"route.v028.first_stage.node.first_hunt",
	"route.v028.first_stage.node.tenant_trace",
]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var screen = DiaryScreenScript.new()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.set_deferred("size", Vector2(1600, 900))
	screen.apply_snapshot(RouteSnapshotScript.new({
		"route_id": "route.v028.first_stage",
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.mirror_pursuit",
		"unlocked_node_ids": _mains + ["route.v028.first_stage.node.mirror_pursuit"],
		"completed_node_ids": _mains,
		"clue_annotations": {
			"route.v028.first_stage.node.first_hunt": "【0-08】真相落下。",
			"route.v028.first_stage.node.tenant_trace": "【0-08】名字被改写。",
		},
		"run_state": {
			"hp": 24, "max_hp": 30, "spirit": 7, "max_spirit": 10,
			"corruption": 2, "max_corruption": 10, "attention": 3, "max_attention": 10,
		},
		"nodes": _nodes(),
	}))
	for _i in range(6):
		await get_tree().process_frame
	var desk = screen.get_desk_stage() if screen.has_method("get_desk_stage") else null
	if desk != null and desk.has_method("force_render_for_capture"):
		desk.force_render_for_capture()
	await get_tree().create_timer(0.8).timeout

	var hinge_r := desk.find_child("RightPageHinge", true, false) as Node3D if desk != null else null
	var hinge_l := desk.find_child("LeftPageHinge", true, false) as Node3D if desk != null else null
	## Step back one leaf first so the sampled turn is a genuine FORWARD turn
	## out of a completed spread (the settlement auto-flip case).
	screen._request_desk_flip(-1)
	await get_tree().create_timer(1.0).timeout
	var start_idx: int = screen.get_current_spread_idx()

	## Buffer frames in RAM: PNG encoding mid-turn would skew the sample times.
	var frames: Array[Image] = []
	var notes: PackedStringArray = []
	screen._request_desk_flip(1)
	var t0 := Time.get_ticks_msec()
	for target_ms in SAMPLE_MS:
		while Time.get_ticks_msec() - t0 < int(target_ms):
			await get_tree().process_frame
		RenderingServer.force_draw()
		var tex: ViewportTexture = viewport.get_texture()
		var img: Image = tex.get_image() if tex != null else null
		if img == null:
			printerr("V084_FLIPSTRIP_FAIL capture null at %sms" % str(target_ms))
			get_tree().quit(1)
			return
		frames.append(img)
		var turn_r := hinge_r.rotation_degrees.z if hinge_r != null else 0.0
		var turn_l := hinge_l.rotation_degrees.z if hinge_l != null else 0.0
		notes.append("%04dms turnR=%7.2f turnL=%7.2f idx=%d flipping=%s" % [
			int(Time.get_ticks_msec() - t0),
			turn_r, turn_l,
			screen.get_current_spread_idx(),
			str(screen.is_page_flipping()),
		])

	for i in range(frames.size()):
		var path := "%s/flip_%02d_%04dms.png" % [OUT_DIR, i, int(SAMPLE_MS[i])]
		var err := frames[i].save_png(path)
		if err != OK:
			printerr("V084_FLIPSTRIP_FAIL save %s err=%s" % [path, str(err)])
			get_tree().quit(1)
			return

	var log_text := "start_idx=%d end_idx=%d\n%s\n" % [
		start_idx, screen.get_current_spread_idx(), "\n".join(notes)
	]
	var f := FileAccess.open("%s/arc.txt" % OUT_DIR, FileAccess.WRITE)
	if f != null:
		f.store_string(log_text)
	print(log_text)
	print("V084_FLIPSTRIP_OK frames=%d dir=%s" % [frames.size(), OUT_DIR])
	get_tree().quit(0)


func _nodes() -> Array:
	return [
		{
			"id": "route.v028.first_stage.node.first_hunt", "type": "normal",
			"state": "completed", "display_name_zh": "密修会的闯入者",
			"scene_id": "scene.battle.moretti_home",
		},
		{
			"id": "route.v028.first_stage.node.tenant_trace", "type": "normal",
			"state": "completed", "display_name_zh": "艾略特绑架案",
			"scene_id": "scene.battle.elliot_ruin",
		},
		{
			"id": "route.v028.first_stage.node.mirror_pursuit", "type": "elite",
			"state": "available", "display_name_zh": "提利尔仓库",
			"scene_id": "scene.battle.tyrell_warehouse",
		},
	]
