extends Node

## UI-P0-3: DQ assets + Forward+ Environment + ribbon「合上」wired without crashing.

const UiContentFixture := preload("res://tests/ui/ui_content_fixture.gd")
const DiaryScreenScript := preload("res://src/ui/diary_chapter_screen.gd")
const DiaryCatalogScript := preload("res://src/ui/diary_ui_catalog.gd")
const DeskCatalog := preload("res://src/ui/desk_world_catalog.gd")
const RouteSnapshotScript := preload("res://src/core/route_snapshot.gd")

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
	UiContentFixture.ensure()
	_expect(DeskCatalog.has("desk.dq.room_backplate"), "DQ-01 registered")
	_expect(DeskCatalog.has("desk.dq.desk_albedo"), "DQ-02 registered")
	_expect(DeskCatalog.has("desk.dq.cover_albedo"), "DQ-03 registered")
	_expect(DeskCatalog.has("desk.dq.ruled_lines"), "DQ-04 registered")
	_expect(DeskCatalog.has("desk.dq.ribbon_bookmark"), "DQ-05 registered")
	_expect(DeskCatalog.has("desk.dq.contact_shadow.page"), "DQ-06 registered")

	var host := Control.new()
	host.size = Vector2(1600, 900)
	add_child(host)
	var screen = DiaryScreenScript.new()
	screen.size = Vector2(1600, 900)
	host.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(screen.desk_world_ready(), "desk world ready")
	var desk = screen.get_desk_stage()
	_expect(desk != null, "desk stage present")

	var world_vp := screen.find_child("DeskWorldViewport", true, false) as SubViewport
	_expect(world_vp != null and world_vp.world_3d != null, "world viewport")
	if world_vp != null and world_vp.world_3d != null:
		var env: Environment = world_vp.world_3d.environment
		_expect(env != null, "environment present")
		if env != null:
			_expect(env.tonemap_mode == Environment.TONE_MAPPER_ACES, "ACES tonemap")
			_expect(env.glow_enabled, "glow enabled")
			_expect(env.ssao_enabled, "ssao enabled")

	var backplate := screen.find_child("RoomBackplate", true, false) as MeshInstance3D
	if backplate == null:
		backplate = screen.find_child("RoomBack", true, false) as MeshInstance3D
	_expect(backplate != null, "room backplate node")
	if backplate != null and backplate.material_override is StandardMaterial3D:
		var mat := backplate.material_override as StandardMaterial3D
		_expect(mat.albedo_texture != null, "DQ-01 albedo on room")

	var desk_mesh := screen.find_child("DeskMesh", true, false) as MeshInstance3D
	_expect(desk_mesh != null, "DeskMesh")
	if desk_mesh != null and desk_mesh.material_override is StandardMaterial3D:
		var dmat := desk_mesh.material_override as StandardMaterial3D
		_expect(dmat.albedo_texture != null, "DQ-02 desk albedo")

	var cover := screen.find_child("CoverMesh", true, false) as MeshInstance3D
	_expect(cover != null, "CoverMesh")
	if cover != null and cover.material_override is StandardMaterial3D:
		var cmat := cover.material_override as StandardMaterial3D
		_expect(cmat.albedo_texture != null, "DQ-03 cover albedo")

	_expect(screen.find_child("ForeEdgeL", true, false) != null, "fore edge L")
	_expect(screen.find_child("RibbonBookmark", true, false) != null, "3D ribbon DQ-05")
	_expect(screen.find_child("BookContactShadow", true, false) != null, "DQ-06 page shadow")

	var close := screen.find_child("CloseBookmark", true, false) as Button
	_expect(close != null and close.text == "合上", "CloseBookmark text 合上")
	if close != null:
		_expect(
			close.find_child("CloseBookmarkRibbon", true, false) != null,
			"CloseBookmark uses DQ-05 ribbon art"
		)
		var normal_sb := close.get_theme_stylebox("normal")
		_expect(
			normal_sb == null or normal_sb is StyleBoxEmpty,
			"CloseBookmark is not a flat red StyleBox"
		)

	var catalog := DiaryCatalogScript.new()
	_expect(catalog.ensure_loaded(), "diary catalog loads")
	var nodes := _tingen_nodes()
	var route_dict := {
		"route_id": "route.v028.first_stage",
		"display_name_zh": "第一卷·小丑：廷根值夜者",
		"phase": "map",
		"available_node_id": "route.v028.first_stage.node.first_hunt",
		"unlocked_node_ids": ["route.v028.first_stage.node.first_hunt"],
		"completed_node_ids": [],
		"nodes": nodes,
		"run_state": {
			"hp": 30, "max_hp": 30, "spirit": 10, "max_spirit": 10,
			"corruption": 0, "max_corruption": 10, "attention": 0, "max_attention": 10,
		},
	}
	screen.apply_snapshot(RouteSnapshotScript.new(route_dict))
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(screen.find_child("RuledLines", true, false) != null, "DQ-04 ruled lines")
	_expect(screen.find_child("PageHeaderOrnament", true, false) != null, "DQ-04 header")
	_expect(screen.find_child("PageCornerTL", true, false) != null, "DQ-04 corner TL")
	_expect(screen.find_child("WaxSealCaption", true, false) != null, "wax caption present")

	_finish()


func _tingen_nodes() -> Array:
	return [
		{
			"node_id": "route.v028.first_stage.node.first_hunt",
			"display_name_zh": "初猎",
			"kind": "battle",
			"investigable": true,
		},
		{
			"node_id": "route.v028.first_stage.node.tenant_trace",
			"display_name_zh": "租客踪迹",
			"kind": "battle",
			"investigable": false,
		},
	]


func _expect(cond: bool, label: String) -> void:
	_checks += 1
	if cond:
		print("OK  ", label)
	else:
		_failures.append(label)
		print("FAIL  ", label)


func _finish() -> void:
	print("diary_quality_wiring checks=%d failures=%d" % [_checks, _failures.size()])
	for f in _failures:
		print("  - ", f)
	get_tree().quit(0 if _failures.is_empty() else 1)
