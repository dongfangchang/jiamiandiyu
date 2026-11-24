extends Node

## Renderer evaluation (ADR-0035): captures the diary desk idle + mid-flip at an
## explicit pixel size and measures mean frame time (vsync off), under whatever
## renderer the process was started with (`--rendering-method` /
## `--rendering-driver`). Needs a real window (GPU); the *_capture_runner name
## keeps it out of tools/run_tests.sh.
##
## Example:
##   Godot --path . --rendering-method mobile --rendering-driver metal \
##     res://tests/ui/renderer_eval_capture_runner.tscn -- \
##     --size=2920x1753 --look=tuned --out=res://.tools/ui-captures/renderer_eval/mobile
## Runner args (after `--`): size=WxH, out=res://dir, look=default|tuned,
## frames=N (timing sample, default 300), shots=0|1. Any other key=value is
## passed to RendererEvalLook.apply as an A/B knob (see renderer_eval_look.gd).

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")
const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const RendererEvalLook := preload("res://tests/ui/renderer_eval_look.gd")
const FLIP_CAPTURE_DURATION := 6.0
const FLIP_CAPTURE_AT := 2.0
const BOOL_KNOBS := ["fog", "ssao", "soft_high", "pcss", "glow", "force_srgb"]
const FLOAT_KNOBS := ["exposure", "page_emit"]

var _size := Vector2i(1600, 900)
var _out := "res://.tools/ui-captures/renderer_eval/unnamed"
var _look := "default"
var _frames := 300
var _shots := true
var _opts := {}


func _ready() -> void:
	_parse_args()
	UiContentFixture.ensure()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var method := str(RenderingServer.get_current_rendering_method())
	var viewport := SubViewport.new()
	viewport.size = _size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var screen = DiaryScreenScript.new()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.set_deferred("size", Vector2(_size))
	screen.apply_snapshot(RouteSnapshotScript.new(_snapshot()))
	for _i in range(6):
		await get_tree().process_frame
	var desk = screen.get_desk_stage()
	desk.force_render_for_capture()
	if _look == "tuned":
		RendererEvalLook.apply(desk.get_desk_world(), method, _opts)
	await get_tree().create_timer(1.0).timeout
	for _j in range(6):
		await get_tree().process_frame
	await _save_shot(viewport, "%s/idle_%dx%d.png" % [_out, _size.x, _size.y])
	var idle_ms := await _measure(desk, false)

	## Slow programmatic turn, shot while the leaf is in the air.
	desk.play_flip(1, FLIP_CAPTURE_DURATION)
	await get_tree().create_timer(FLIP_CAPTURE_AT).timeout
	await _save_shot(viewport, "%s/flip_%dx%d.png" % [_out, _size.x, _size.y])
	while desk.is_flip_animating():
		await get_tree().process_frame
	var flip_ms := await _measure(desk, true)

	print("RENDERER_EVAL method=%s look=%s opts=%s size=%dx%d adapter=%s idle_ms=%.2f flip_ms=%.2f" % [
		method, _look, JSON.stringify(_opts), _size.x, _size.y,
		RenderingServer.get_video_adapter_name(), idle_ms, flip_ms
	])
	get_tree().quit(0)


func _measure(desk, flipping: bool) -> float:
	## Mean wall-clock frame time; when flipping, turns back and forth so every
	## sampled frame has a leaf in the air.
	var sum := 0.0
	var dir := 1
	await get_tree().process_frame
	var last := Time.get_ticks_usec()
	for _n in range(_frames):
		if flipping and not desk.is_flip_animating():
			dir = -dir
			desk.play_flip(dir, 0.56)
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		sum += float(now - last) / 1000.0
		last = now
	return sum / float(_frames)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.trim_prefix("--").split("=", true, 1)
		if kv.size() != 2:
			continue
		var key := kv[0]
		var value := kv[1]
		match key:
			"size":
				var wh := value.split("x")
				_size = Vector2i(int(wh[0]), int(wh[1]))
			"out":
				_out = value
			"look":
				_look = value
			"frames":
				_frames = maxi(1, int(value))
			"shots":
				_shots = value == "1"
			"msaa":
				_opts[key] = int(value)
			_:
				if key in BOOL_KNOBS:
					_opts[key] = value == "1"
				elif key in FLOAT_KNOBS:
					_opts[key] = float(value)
				else:
					_opts[key] = value



func _save_shot(viewport: SubViewport, path: String) -> void:
	if not _shots:
		return
	RenderingServer.force_draw()
	await get_tree().process_frame
	var img: Image = viewport.get_texture().get_image()
	if img == null or img.save_png(path) != OK:
		printerr("RENDERER_EVAL_CAPTURE_FAIL %s" % path)
		return
	print("RENDERER_EVAL_SHOT %s" % path)


func _snapshot() -> Dictionary:
	var nodes := []
	var ids := ["first_hunt", "tenant_trace", "mirror_pursuit", "boundary"]
	var names := ["密修会的闯入者", "艾略特绑架案", "提利尔仓库", "伍德家的恶灵"]
	var scenes := ["moretti_home", "elliot_ruin", "tyrell_warehouse", "wood_house"]
	for i in ids.size():
		nodes.append({
			"id": "route.v028.first_stage.node.%s" % ids[i],
			"type": "normal",
			"state": "available" if i == 0 else "locked",
			"display_name_zh": names[i],
			"scene_id": "scene.battle.%s" % scenes[i],
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
