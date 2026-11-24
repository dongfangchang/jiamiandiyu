extends Node

## Opening the book on the title must never reveal the legacy panel (title,
## checkpoint summary, backup / test-profile buttons) that sits under the desk.
## The desk stays fully opaque and a black cover on top of everything reaches
## alpha 1 by the end of the beat; the router overlay takes over from black.
## Run windowed with --capture to also save frames to .tools/ui-captures/.

const StartScreenScene := preload("res://scenes/ui/start_screen.tscn")
const OUTPUT_DIRECTORY := "res://.tools/ui-captures"

var _checks := 0
var _failures: Array[String] = []
var _capture := false


func _ready() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	if _capture:
		DisplayServer.window_set_size(Vector2i(1600, 900))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	var screen: Control = StartScreenScene.instantiate()
	add_child(screen)
	screen.show_checkpoint_status("loaded", {
		"content_version": "v0.88.0",
		"sequence": 9,
		"deck_size": 8,
		"identity_id": "identity.reporter",
		"backup_available": true,
		"last_battle": {"outcome": "victory", "round_number": 3},
	})
	await get_tree().process_frame
	await _snap("title_open_0_rest.png")

	var desk: Control = screen.find_child("TitleDeskStage", false, false)
	_expect(desk != null, "title installs the desk stage")
	if desk == null:
		_finish()
		return
	var cover: ColorRect = desk.get_open_cover()
	_expect(cover != null, "desk owns an open cover")
	_expect(screen.get_child(screen.get_child_count() - 1) == desk, "desk is the topmost title layer")
	_expect(cover != null and cover.modulate.a == 0.0, "cover is clear at rest")

	_expect(bool(desk.play_open("continue")), "open beat starts")
	_expect(desk.get_child(desk.get_child_count() - 1) == cover, "cover sits above every desk child (buttons included)")
	var min_desk_alpha := 1.0
	var frames := 0
	var mid_saved := false
	while desk.is_opening() and frames < 300:
		await get_tree().process_frame
		frames += 1
		min_desk_alpha = minf(min_desk_alpha, desk.modulate.a)
		min_desk_alpha = minf(min_desk_alpha, screen.modulate.a)
		if not mid_saved and cover.modulate.a > 0.4:
			mid_saved = true
			await _snap("title_open_1_mid.png")
	_expect(not desk.is_opening(), "open beat finishes (%d frames)" % frames)
	_expect(min_desk_alpha >= 0.999, "desk and screen never fade out (min alpha %.3f)" % min_desk_alpha)
	_expect(cover.modulate.a >= 0.999, "cover is fully black at the end (%.3f)" % cover.modulate.a)
	_expect(cover.visible and cover.is_visible_in_tree(), "cover is visible")
	var view := get_viewport().get_visible_rect()
	_expect(cover.get_global_rect().encloses(view), "cover spans the whole view")
	await _snap("title_open_2_end.png")

	## Returning to the title restores the desk.
	screen.set_busy(false)
	_expect(cover.modulate.a == 0.0 and desk.modulate.a == 1.0, "reset clears the cover")
	_finish()


func _snap(file_name: String) -> void:
	if not _capture:
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIRECTORY, file_name]))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_OPEN_COVER_OK checks=%d" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr("TITLE_OPEN_COVER_FAIL: %s" % failure)
	print("TITLE_OPEN_COVER_FAIL checks=%d" % _checks)
	get_tree().quit(1)


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(label)
