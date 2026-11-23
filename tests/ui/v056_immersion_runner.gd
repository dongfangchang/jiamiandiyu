extends Node

## v0.56 immersion UI probes (soft-fail covered by ROUTE_TESTS).

const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	await _run()


func _run() -> void:
	var screen = DiaryScreenScript.new()
	add_child(screen)
	screen.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"run_state": {
			"hp": 40, "max_hp": 54, "spirit": 2, "max_spirit": 3,
			"corruption": 4, "max_corruption": 10, "attention": 3, "max_attention": 10,
		},
		"nodes": [{
			"id": "route.v028.first_stage.node.first_hunt",
			"type": "normal",
			"state": "available",
		}],
	}))
	await get_tree().process_frame
	_expect(screen.find_child("StatusPanel", true, false) != null, "status panel node retained")
	var status_panel := screen.find_child("StatusPanel", true, false) as CanvasItem
	_expect(status_panel != null and not status_panel.visible, "numeric status panel hidden")
	_expect(screen.find_child("EdgeInkIndex", true, false) != null, "edge ink index present")
	_expect(screen.find_child("CorruptionMold", true, false) != null, "corruption mold layer")
	_expect(screen.find_child("CandleVeil", true, false) != null, "candle veil present")
	_expect(screen.find_child("CandleCorner", true, false) != null, "candle corner glow")
	var vignette := screen.find_child("CandleVignette", true, false) as CanvasItem
	_expect(vignette != null, "candle vignette present")
	_expect(
		vignette != null and vignette.material is ShaderMaterial,
		"candle vignette uses shader material"
	)
	_expect(screen.find_child("FlipCurlShade", true, false) != null, "flip curl shade present")
	_expect(
		FileAccess.file_exists("res://assets/ui/diary/candle_vignette.gdshader"),
		"candle shader asset present"
	)
	_expect(screen.find_child("PageEdgeShadow", true, false) != null, "page edge shadow present")
	_expect(screen.find_child("LampGlow", true, false) != null, "lamp glow present")
	_expect(screen.find_child("ParchmentGrain", true, false) != null, "parchment grain layer")
	_expect(screen.find_child("ParchmentGrainDeep", true, false) != null, "deep grain layer")
	_expect(screen.find_child("PaperStainA", true, false) != null, "paper stain layer")
	_expect(screen.find_child("GazeDisturb", true, false) != null, "gaze disturb layer")
	var gaze_warp := screen.find_child("GazeWarp", true, false) as CanvasItem
	_expect(gaze_warp != null, "gaze warp overlay present")
	_expect(
		gaze_warp != null and gaze_warp.material is ShaderMaterial,
		"gaze warp uses shader material"
	)
	_expect(
		FileAccess.file_exists("res://assets/ui/diary/gaze_distort.gdshader"),
		"gaze distort shader asset present"
	)
	## Pump a process frame so attention-driven warp can enable.
	await get_tree().process_frame
	_expect(
		gaze_warp != null and gaze_warp.visible,
		"gaze warp enables when attention present"
	)
	var grain := screen.find_child("ParchmentGrain", true, false) as CanvasItem
	_expect(grain != null and grain.modulate.a >= 0.35, "grain readable at eye level")
	_expect(screen.find_child("InkTrail", true, false) != null, "index ink trail host")
	_expect(screen.find_child("InkBloom", true, false) != null, "pen ink bloom host")
	_expect(screen.find_child("PageWearTL", true, false) != null, "hp corner wear")
	_expect(screen.find_child("SpiritMarginNote", true, false) != null, "spirit margin note")
	var wear := screen.find_child("PageWearTL", true, false) as ColorRect
	_expect(wear != null and wear.color.a > 0.05, "low hp seeps corner wear")
	var index := screen.find_child("IndexPanel", true, false) as CanvasItem
	_expect(index != null and index.modulate.a < 0.2, "index starts seeped away")
	_expect(screen.find_child("AnnotationPopup", true, false) != null, "page float annotation host")
	screen._show_annotation_popup("【0-08】试墨。")
	await get_tree().process_frame
	var float_panel := screen.find_child("AnnotationPopup", true, false) as CanvasItem
	_expect(float_panel != null and float_panel.visible, "annotation float opens without AcceptDialog")
	_expect(screen.find_child("InkSealCoagulate", true, false) != null, "ink seal coagulate host")
	screen._resist_flip("墨封试压")
	await get_tree().process_frame
	var mold := screen.find_child("CorruptionMold", true, false) as ColorRect
	_expect(mold != null and mold.color.a > 0.05, "resist flip seeps mold")
	_expect(mold != null and mold.get_child_count() > 0, "mold blotches rebuild")
	var seal_fx := screen.find_child("InkSealCoagulate", true, false) as CanvasItem
	_expect(seal_fx != null and seal_fx.visible, "resist flip plays ink seal coagulate")
	var parchment := screen.find_child("ParchmentWash", true, false) as Panel
	_expect(parchment != null, "parchment wash present")
	if parchment != null:
		var style: StyleBox = parchment.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			_expect((style as StyleBoxFlat).bg_color.a <= 0.1, "parchment wash stays translucent")
		else:
			_expect(false, "parchment wash stays translucent")
	_expect(
		screen.find_child("AvailableInkEdge", true, false) != null,
		"available clue uses margin edge not card wash"
	)
	_expect(
		FileAccess.file_exists("res://docs/design/DIARY_IMMERSION_BRIEF.md"),
		"immersion brief present"
	)
	## Lookback via index must animate leaf-by-leaf; idx stays until flip settles.
	var all_first_page := [
		"route.v028.first_stage.node.first_hunt",
		"route.v028.first_stage.node.tenant_trace",
		"route.v028.first_stage.node.mirror_pursuit",
		"route.v028.first_stage.node.boundary",
	]
	screen.apply_snapshot(RouteSnapshotScript.new({
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.rest",
		"unlocked_node_ids": all_first_page + ["route.v028.first_stage.node.rest"],
		"completed_node_ids": all_first_page,
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
		"nodes": [],
	}))
	await get_tree().process_frame
	_expect(screen.get_current_spread_idx() == 1, "index slow-flip fixture opens leaf 2")
	var back_chain: Array = screen._build_index_chain(1, 0)
	_expect(back_chain.size() == 1 and int(back_chain[0]) == 0, "index chain lookback is one leaf")
	var same_chain: Array = screen._build_index_chain(1, 1)
	_expect(same_chain.is_empty(), "index chain same leaf empty")
	var fwd_chain: Array = screen._build_index_chain(0, 1)
	_expect(fwd_chain.size() == 1 and int(fwd_chain[0]) == 1, "index chain forward adjacent is one leaf")
	var flips := {"n": 0}
	screen.page_flip_finished.connect(func() -> void: flips["n"] = int(flips["n"]) + 1)
	var flip3d := screen.find_child("DiaryFlip3D", true, false) as CanvasItem
	_expect(flip3d != null, "diary flip 3d host present")
	_expect(
		flip3d != null and flip3d.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"diary flip 3d ignores mouse"
	)
	_expect(screen.find_child("FlipPageMesh", true, false) != null, "flip page mesh present")
	_expect(screen.find_child("FlipPageLeft", true, false) != null, "flip left page present")
	_expect(screen.find_child("FlipBookSpine", true, false) != null, "flip book spine present")
	_expect(screen.find_child("FlipPageHinge", true, false) != null, "flip page hinge present")
	_expect(screen.find_child("DiaryFlip3DViewport", true, false) != null, "flip 3d viewport present")
	_expect(
		screen.find_child("DiaryWorldEnvironment", true, false) != null,
		"diary world environment present"
	)
	_expect(
		FileAccess.file_exists("res://assets/ui/diary/parchment_grain.png"),
		"formal parchment grain png present"
	)
	_expect(
		FileAccess.file_exists("res://art/assets/svg/v0.69.0/diary/parchment_grain.svg"),
		"art source parchment svg present"
	)
	_expect(
		FileAccess.file_exists("res://docs/design/ART_BRIEF_V069.md"),
		"art brief v069 present"
	)
	var before := screen.get_current_spread_idx()
	screen._index_jump(0)
	await get_tree().process_frame
	_expect(screen.is_page_flipping(), "index jump starts animated flip")
	_expect(screen.get_current_spread_idx() == before, "index jump does not teleport idx mid-flip")
	await get_tree().create_timer(0.2).timeout
	_expect(
		flip3d != null and flip3d.visible and flip3d.modulate.a > 0.05,
		"flip 3d overlay plays during page turn"
	)
	await get_tree().create_timer(1.2).timeout
	_expect(int(flips["n"]) >= 1, "index slow flip emits finished")
	_expect(screen.get_current_spread_idx() == 0, "index slow flip lands on target leaf")
	_expect(not screen.is_page_flipping(), "index chain idle after settle")
	_expect(screen.find_child("PageCornerCueBL", true, false) != null, "page corner cue BL")
	_expect(screen.find_child("PageCornerCueBR", true, false) != null, "page corner cue BR")
	var post_fx := screen.find_child("DiaryPostFx", true, false) as CanvasItem
	_expect(post_fx != null, "diary post fx present")
	_expect(
		post_fx != null and post_fx.material is ShaderMaterial,
		"diary post fx uses shader material"
	)
	_expect(
		FileAccess.file_exists("res://assets/ui/diary/diary_postprocess.gdshader"),
		"diary postprocess shader asset present"
	)
	_expect(
		post_fx != null and post_fx.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"diary post fx ignores mouse"
	)
	## Force a known book size so corner math is stable in headless.
	screen._book_root.size = Vector2(1000, 800)
	_expect(screen._is_page_corner(Vector2(40, 760)), "lower-left is page corner")
	_expect(screen._is_page_corner(Vector2(960, 760)), "lower-right is page corner")
	_expect(not screen._is_page_corner(Vector2(500, 400)), "page heart is not page corner")
	_expect(not screen._is_page_corner(Vector2(40, 40)), "upper corner is not drag corner")
	_finish()


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("V056_IMMERSION_OK checks=%d" % _checks)
		get_tree().quit(0)
	else:
		print("V056_IMMERSION_FAIL checks=%d failures=%s" % [_checks, str(_failures)])
		get_tree().quit(1)
