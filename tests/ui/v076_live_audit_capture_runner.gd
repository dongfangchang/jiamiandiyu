extends Node

## Empirical audit shots: rewrite layers, defeat stain, high corruption, rest pending.

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")
const OUT_DIR := "res://.tools/ui-captures/v076_live_audit"

var _viewport: SubViewport


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1600, 900)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	add_child(_viewport)

	## 1) Branch B rewrite visible on locked clue.
	if not await _shot("01_rewrite_layers.png", {
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"clue_annotations": {
			"route.v028.first_stage.node.tenant_trace": "【0-08】墨迹改写了尚未读到的字句。",
		},
		"clue_overlays": {
			"route.v028.first_stage.node.tenant_trace": {
				"text_zh": "「灵摆的指向被笔尖掰弯：废弃楼里先到的不是救援，是第二波屠杀。」",
				"source": "0-08",
				"margin_note_zh": "笔改过",
			},
		},
		"run_state": {
			"hp": 44, "max_hp": 54, "spirit": 3, "max_spirit": 3,
			"corruption": 2, "max_corruption": 10, "attention": 3, "max_attention": 10,
		},
		"nodes": [],
	}):
		_fail("rewrite")
		return

	## 2) Soft-fail stain + high mold/attention.
	if not await _shot("02_defeat_stain.png", {
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.tenant_trace",
		"unlocked_node_ids": [
			"route.v028.first_stage.node.first_hunt",
			"route.v028.first_stage.node.tenant_trace",
		],
		"completed_node_ids": [],
		"clue_annotations": {
			"route.v028.first_stage.node.first_hunt":
				"【0-08】夜色吞没·家门：雨夜里左轮哑了火，密修会的脚印仍停在厨房门外。章节未灭。",
			"route.v028.first_stage.node.mirror_pursuit":
				"【0-08】墨渍回涌·提利尔：仓库页边洇开，2-049 与小丑的字缝再次合拢。",
		},
		"clue_overlays": {},
		"run_state": {
			"hp": 22, "max_hp": 54, "spirit": 1, "max_spirit": 3,
			"corruption": 8, "max_corruption": 10, "attention": 9, "max_attention": 10,
		},
		"nodes": [],
	}):
		_fail("defeat")
		return

	## 3) Completed gold overwrite + available next.
	if not await _shot("03_completed_gold.png", {
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.tenant_trace",
		"unlocked_node_ids": [
			"route.v028.first_stage.node.first_hunt",
			"route.v028.first_stage.node.tenant_trace",
		],
		"completed_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"clue_annotations": {
			"route.v028.first_stage.node.first_hunt":
				"【0-08】分支·真相·家门：密修会退进雨里。暗金记下——厨房仍安全，名字还活着。",
		},
		"clue_overlays": {},
		"run_state": {
			"hp": 50, "max_hp": 54, "spirit": 3, "max_spirit": 3,
			"corruption": 1, "max_corruption": 10, "attention": 2, "max_attention": 10,
		},
		"nodes": [],
	}):
		_fail("completed")
		return

	print("V076_LIVE_AUDIT_CAPTURE_OK dir=%s" % OUT_DIR)
	get_tree().quit(0)


func _shot(filename: String, data: Dictionary) -> bool:
	for child in _viewport.get_children():
		child.queue_free()
	await get_tree().process_frame
	var screen = DiaryScreenScript.new()
	_viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.set_deferred("size", Vector2(1600, 900))
	screen.apply_snapshot(RouteSnapshotScript.new(data))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var path := "%s/%s" % [OUT_DIR, filename]
	var tex: ViewportTexture = _viewport.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null:
		printerr("capture null image %s" % filename)
		return false
	var err := img.save_png(path)
	if err != OK:
		printerr("save fail %s err=%s" % [filename, err])
		return false
	print("saved %s" % path)
	return true


func _fail(label: String) -> void:
	printerr("V076_LIVE_AUDIT_CAPTURE_FAIL %s" % label)
	get_tree().quit(1)
