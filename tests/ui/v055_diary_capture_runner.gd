extends Node

## Capture diary chapter via SubViewport (works headless).
## Writes idle spread + mid-settlement pen beat.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const OUT_IDLE := "res://.tools/ui-captures/v055_diary_chapter.png"
const OUT_PEN := "res://.tools/ui-captures/v055_diary_pen_beat.png"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://.tools/ui-captures")
	)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var screen = DiaryScreenScript.new()
	viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.set_deferred("size", Vector2(1600, 900))
	var snap_data := {
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": [
			"route.v028.first_stage.node.first_hunt",
			"route.v028.first_stage.node.tenant_trace",
		],
		"completed_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"clue_annotations": {
			"route.v028.first_stage.node.first_hunt": "【0-08】真相落下。",
		},
		"clue_overlays": {
			"route.v028.first_stage.node.tenant_trace": {
				"text_zh": "（0-08 已改写）夜色里另有一行字。",
				"margin_note_zh": "笔改",
			},
		},
		"run_state": {
			"hp": 54, "max_hp": 54, "spirit": 3, "max_spirit": 3,
			"corruption": 0, "max_corruption": 10, "attention": 1, "max_attention": 10,
		},
		"nodes": [
			{"id": "route.v028.first_stage.node.first_hunt", "type": "normal", "state": "completed"},
			{"id": "route.v028.first_stage.node.tenant_trace", "type": "normal", "state": "available"},
		],
	}
	screen.apply_snapshot(RouteSnapshotScript.new(snap_data))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_shot(viewport, OUT_IDLE):
		printerr("V055_DIARY_CAPTURE_FAIL idle")
		get_tree().quit(1)
		return

	screen.present_post_encounter(
		"route.v028.first_stage.node.first_hunt",
		"victory"
	)
	## Catch pen overlay mid-beat.
	await get_tree().create_timer(0.55).timeout
	await get_tree().process_frame
	if not _save_shot(viewport, OUT_PEN):
		printerr("V055_DIARY_CAPTURE_FAIL pen")
		get_tree().quit(1)
		return

	print("V055_DIARY_CAPTURE_OK idle=%s pen=%s" % [OUT_IDLE, OUT_PEN])
	get_tree().quit(0)


func _save_shot(viewport: SubViewport, path: String) -> bool:
	var tex: ViewportTexture = viewport.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null:
		return false
	return img.save_png(path) == OK
