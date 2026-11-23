extends Node

## Capture immersion diary: mold/candle/gold overwrite + resist seep.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const OUT_IDLE := "res://.tools/ui-captures/v056_diary_immersion.png"
const OUT_RESIST := "res://.tools/ui-captures/v056_diary_resist.png"


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
		"available_node_id": "route.v028.first_stage.node.tenant_trace",
		"unlocked_node_ids": [
			"route.v028.first_stage.node.first_hunt",
			"route.v028.first_stage.node.tenant_trace",
		],
		"completed_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"clue_annotations": {
			"route.v028.first_stage.node.first_hunt": "【0-08】真相落下——金笔覆写命运。",
		},
		"clue_overlays": {},
		"run_state": {
			"hp": 38, "max_hp": 54, "spirit": 2, "max_spirit": 3,
			"corruption": 6, "max_corruption": 10, "attention": 7, "max_attention": 10,
		},
		"nodes": [
			{"id": "route.v028.first_stage.node.first_hunt", "type": "normal", "state": "completed"},
			{"id": "route.v028.first_stage.node.tenant_trace", "type": "normal", "state": "available"},
			{"id": "route.v028.first_stage.node.mirror_pursuit", "type": "normal", "state": "locked"},
			{"id": "route.v028.first_stage.node.boundary", "type": "normal", "state": "locked"},
			{"id": "route.v028.first_stage.node.rest", "type": "rest", "state": "locked"},
			{"id": "route.v028.first_stage.node.lamud", "type": "normal", "state": "locked"},
			{"id": "route.v028.first_stage.node.baron", "type": "normal", "state": "locked"},
			{"id": "route.v028.first_stage.node.ascension", "type": "ritual", "state": "locked"},
		],
	}
	screen.apply_snapshot(RouteSnapshotScript.new(snap_data))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	if not _save_shot(viewport, OUT_IDLE):
		printerr("V056_DIARY_CAPTURE_FAIL idle")
		get_tree().quit(1)
		return

	screen._resist_flip("墨封试压——纸页合回。")
	await get_tree().create_timer(0.22).timeout
	await get_tree().process_frame
	if not _save_shot(viewport, OUT_RESIST):
		printerr("V056_DIARY_CAPTURE_FAIL resist")
		get_tree().quit(1)
		return

	print("V056_DIARY_CAPTURE_OK idle=%s resist=%s" % [OUT_IDLE, OUT_RESIST])
	get_tree().quit(0)


func _save_shot(viewport: SubViewport, path: String) -> bool:
	var tex: ViewportTexture = viewport.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null:
		return false
	return img.save_png(path) == OK
