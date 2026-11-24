extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## GPU strip of one forward turn on the bare desk stage, with the frame gap
## around the commit. `-- --old=<res path>` runs a different stage script
## (e.g. a copy of the pre-v0.88 stage) for a before/after comparison.
## Needs a display; excluded from tools/run_tests.sh by name.

const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const DiaryCatalog := preload("res://src/ui/diary_ui_catalog.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")
const OUT_ROOT := "res://.tools/ui-captures/diary_turn"
const SAMPLE_MS := [0, 90, 180, 240, 280, 330, 390, 450, 520, 600, 700]

var _spreads: Array = []
var _idx := 1
var _desk: Control
var _neighbours := false


func _ready() -> void:
	UiContentFixture.ensure()
	TableSfx.set_muted(true)
	var script_path := "res://src/ui/diary_desk_stage.gd"
	var tag := "after"
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--old="):
			script_path = String(arg).trim_prefix("--old=")
			tag = "before"
	var out_dir := "%s/%s" % [OUT_ROOT, tag]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	_spreads = _make_spreads()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	_desk = (load(script_path) as GDScript).new()
	viewport.add_child(_desk)
	_desk.size = Vector2(1600, 900)
	_neighbours = _desk.has_method("apply_spread_list")
	_apply()
	_desk.flip_committed.connect(func(delta: int) -> void:
		_idx += delta
		_apply()
	)
	await get_tree().create_timer(1.2).timeout
	_desk.force_render_for_capture()
	await get_tree().create_timer(0.4).timeout

	var frames: Array[Image] = []
	var notes: PackedStringArray = []
	var max_gap := 0
	var last := Time.get_ticks_usec()
	_desk.play_flip(1)
	var t0 := Time.get_ticks_msec()
	for target_ms in SAMPLE_MS:
		while Time.get_ticks_msec() - t0 < int(target_ms):
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			max_gap = maxi(max_gap, now - last)
			last = now
		RenderingServer.force_draw()
		frames.append(viewport.get_texture().get_image())
		last = Time.get_ticks_usec()
		notes.append("%04dms idx=%d" % [Time.get_ticks_msec() - t0, _idx])
	for i in range(frames.size()):
		frames[i].save_png(ProjectSettings.globalize_path("%s/turn_%02d_%04dms.png" % [out_dir, i, int(SAMPLE_MS[i])]))
	var report := "%s neighbours=%s max_frame_gap_ms=%.1f\n%s" % [
		tag, str(_neighbours), float(max_gap) / 1000.0, "\n".join(notes)
	]
	print(report)
	print("DIARY_TURN_CAPTURE_OK dir=%s" % out_dir)
	get_tree().quit(0)


func _apply() -> void:
	if _neighbours:
		_desk.apply_spread_list(_spreads, _idx)
	else:
		_desk.apply_spread(_spreads[_idx])


func _make_spreads() -> Array:
	var out: Array = []
	for scene_id in SceneCatalog.diary_scene_ids():
		var path := SceneCatalog.diary_path_for(String(scene_id))
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var i := out.size()
		out.append({
			"spread_index": i,
			"page_index": i,
			"title_zh": "第 %d 叶 · 试翻" % (i + 1),
			"ink_zh": "这一叶的墨迹编号为 %d，用来分辨正反面与下一叶。" % (i + 1),
			"left_art_path": path,
			"state": DiaryCatalog.STATE_COMPLETED,
			"clues": [{"node_id": "test.node.%d" % i, "state": DiaryCatalog.STATE_COMPLETED}],
		})
		if out.size() >= 4:
			break
	return out
