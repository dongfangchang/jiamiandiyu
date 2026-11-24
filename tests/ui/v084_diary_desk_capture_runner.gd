extends Node

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")

## v0.84 desk P0 visual capture (1600×900).

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

const OUT_IDLE := "res://.tools/ui-captures/v084_desk_idle.png"
const OUT_FLIP := "res://.tools/ui-captures/v084_desk_flip.png"


func _ready() -> void:
	UiContentFixture.ensure()
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
	screen.apply_snapshot(RouteSnapshotScript.new({
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
			{
				"id": "route.v028.first_stage.node.mirror_pursuit",
				"type": "normal",
				"state": "locked",
				"display_name_zh": "提利尔仓库",
				"scene_id": "scene.battle.tyrell_warehouse",
			},
			{
				"id": "route.v028.first_stage.node.boundary",
				"type": "normal",
				"state": "locked",
				"display_name_zh": "伍德家的恶灵",
				"scene_id": "scene.battle.wood_house",
			},
			{
				"id": "route.v028.first_stage.node.rest",
				"type": "rest",
				"state": "locked",
				"display_name_zh": "占卜俱乐部",
				"scene_id": "scene.rest.divination_club",
			},
			{
				"id": "route.v028.first_stage.node.lamud",
				"type": "normal",
				"state": "locked",
				"display_name_zh": "拉姆德小镇驱邪",
				"scene_id": "scene.battle.lamud_chapel",
			},
			{
				"id": "route.v028.first_stage.node.baron",
				"type": "normal",
				"state": "locked",
				"display_name_zh": "失控的老尼尔",
				"scene_id": "scene.battle.blackthorn_neil",
			},
			{
				"id": "route.v028.first_stage.node.ascension",
				"type": "ritual",
				"state": "locked",
				"display_name_zh": "晋升：小丑",
				"scene_id": "scene.ritual.clown_ascension",
			},
		],
	}))
	for _i in range(6):
		await get_tree().process_frame
	var desk = screen.get_desk_stage() if screen.has_method("get_desk_stage") else null
	if desk != null and desk.has_method("force_render_for_capture"):
		desk.force_render_for_capture()
	await get_tree().create_timer(0.8).timeout
	for _j in range(4):
		await get_tree().process_frame
	if not await _save_shot(viewport, OUT_IDLE):
		printerr("V084_DESK_CAPTURE_FAIL idle")
		get_tree().quit(1)
		return

	## Mid-flip visual: force a curl pose then shoot.
	if desk != null and desk.has_method("_apply_flip_visual"):
		desk.call("_apply_flip_visual", 0.72)
	await get_tree().create_timer(0.35).timeout
	for _k in range(4):
		await get_tree().process_frame
	if not await _save_shot(viewport, OUT_FLIP):
		printerr("V084_DESK_CAPTURE_FAIL flip")
		get_tree().quit(1)
		return

	print("V084_DESK_CAPTURE_OK idle=%s flip=%s" % [OUT_IDLE, OUT_FLIP])
	get_tree().quit(0)


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
	return true
