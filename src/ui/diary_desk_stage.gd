extends Control

## v0.84 P0: desk + 3D book stage. One spread = one level (left art / right ink+seal).

signal seal_activated(clue: Dictionary)
signal flip_committed(delta: int)
signal status_message(text: String)
## Emitted when a hinge turn (drag or programmatic) has fully settled flat.
signal flip_visual_finished

const DiaryCatalog := preload("res://src/ui/diary_ui_catalog.gd")
const SceneCatalog := preload("res://src/ui/scene_ui_catalog.gd")
const Ui := preload("res://src/ui/mask_ui_theme.gd")
const TableSfx := preload("res://src/ui/table_sfx.gd")
const PropCatalog := preload("res://src/ui/prop_ui_catalog.gd")
const PagePair := preload("res://src/ui/diary_page_pair.gd")
const ArtLoader := preload("res://src/ui/diary_art_loader.gd")
const ReadingMetrics := preload("res://src/ui/diary_reading_metrics.gd")
const PageOcclusion := preload("res://src/ui/diary_page_occlusion.gd")
const DeskQuality := preload("res://src/ui/diary_desk_quality.gd")
const GRAIN_PATH := "res://assets/ui/diary/parchment_grain.png"
const WOOD_PATH := "res://assets/ui/diary/desk_wood.png"
const SEAL_PATHS := {
	DiaryCatalog.STATE_AVAILABLE: "res://assets/ui/diary/wax_seal_available.png",
	DiaryCatalog.STATE_COMPLETED: "res://assets/ui/diary/wax_seal_completed.png",
	DiaryCatalog.STATE_LOCKED: "res://assets/ui/diary/wax_seal_locked.png",
}

## Reading camera (EXPERIENCE §5.1): steep and long-lens so the right leaf's
## text is within READING_ANGLE_MAX_DEG of face-on everywhere, framing the
## book at ~63% of the frame width (same framing as the old 1.78 m / 38° shot).
const CAMERA_PITCH_DEG := -75.0
const CAMERA_FOV := 23.0
const CAMERA_DISTANCE := 3.0
const CAMERA_TARGET := Vector3(0.0, 0.085, 0.02)
const READING_ANGLE_MAX_DEG := 25.0
## Upright prop cutouts lean back this far so the steep camera still sees them.
const PROP_LEAN_DEG := 45.0
## Below this many window pixels per logical px the 3D pass is supersampled.
const LOW_DPI_SCALE := 1.5

const CLICK_SLOP_PX := 10.0
const FLIP_THRESHOLD := 0.5
## Turn fraction: 0 = flat on its own side, 0.5 = upright (content commit),
## 1 = landed on the opposite side. A full-width drag holds the leaf upright.
const DRAG_TURN_SCALE := 0.5
const COMMIT_TURN := 0.5
const PROG_FLIP_DURATION := 0.56
const PROG_FLIP_RISE_FRAC := 0.45
## A landed leaf rides this high so it clears the arched page it covers until
## the rest binding takes over.
const LAND_LIFT := 0.03
const PAGE_VP_SIZE := PagePair.PAGE_VP_SIZE

const INPUT_IDLE := 0
const INPUT_ARM := 1
const INPUT_FLIP := 2

var _spread: Dictionary = {}
var _input_mode := INPUT_IDLE
var _press_pos := Vector2.ZERO
var _flip_progress := 0.0
var _block_forward := false
var _block_backward := false
var _ink_seep: ColorRect
var _bounce_tween: Tween

var _stage: TextureRect
var _world_vp: SubViewport
var _desk_world: Node3D
var _book_root: Node3D
var _right_page_mesh: MeshInstance3D
var _left_page_mesh: MeshInstance3D
var _right_hinge: Node3D
var _left_hinge: Node3D
## Back faces of the turning leaves and the pages revealed beneath them.
var _right_back_mesh: MeshInstance3D
var _left_back_mesh: MeshInstance3D
var _right_under_mesh: MeshInstance3D
var _left_under_mesh: MeshInstance3D
var _seal_textures: Dictionary = {}
## Ring of prepared spreads: indices into _pairs for each role.
var _pairs: Array[PagePair] = []
var _cur := 0
var _prev := 1
var _next := 2
var _art := ArtLoader.new()
## Which pair/side each page surface currently shows (probe surface).
var _bindings: Dictionary = {}
## Turn in progress: +1 forward (right leaf), -1 backward (left leaf), 0 flat.
var _turn_dir := 0
var _turn_from_key := -1
var _settle_from := 0.0
var _settle_to := 0.0
var _headless := false
var _rune_detail: PanelContainer
var _rune_detail_label: Label
var _settlement_bloom: ColorRect
var _desk_mesh: MeshInstance3D
var _grain: Texture2D
var _wax_hit: Button
var _candle_flame_light: OmniLight3D
var _candle_flame_mesh: MeshInstance3D
var _flame_t := 0.0
## A committing turn is in the air (drag commit or play_flip); it always ends
## with flip_visual_finished. A bounce is tracked apart precisely because it
## commits nothing and must not make callers wait for that signal.
var _flip_animating := false
var _bounce_animating := false
var _cam: Camera3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_grain = _load_texture(GRAIN_PATH)
	for state in SEAL_PATHS:
		_seal_textures[state] = _load_texture(SEAL_PATHS[state])
	_build_stage()
	_build_screen_wax_hit()
	_build_ink_seep()
	_build_rune_detail()
	_build_vignette()
	_build_settlement_bloom()
	_headless = DisplayServer.get_name() == "headless"
	set_process(not _headless)


func _notification(what: int) -> void:
	## The router caches the diary off-tree with its viewports frozen and
	## restores their modes after re-adding it; re-render the static
	## neighbour pages on the following frames so a turn never shows a stale
	## or empty render target.
	if what == NOTIFICATION_ENTER_TREE:
		for pair in _pairs:
			pair.request_redraw()
		## Window / host resizes change the stretch scale without resizing
		## this Control; follow them so the world stays at physical pixels.
		if not get_viewport().size_changed.is_connected(_sync_world_vp_size):
			get_viewport().size_changed.connect(_sync_world_vp_size)
		call_deferred("_sync_world_vp_size")
	elif what == NOTIFICATION_EXIT_TREE:
		if get_viewport().size_changed.is_connected(_sync_world_vp_size):
			get_viewport().size_changed.disconnect(_sync_world_vp_size)


func _process(delta: float) -> void:
	## Candle light is deliberately STATIC (flicker read as noise and forced a
	## shadow re-render every frame). Only the seal breathes, to stay findable.
	_poll_pending_art()
	if _headless:
		set_process(_has_pending_art())
		return
	_flame_t += delta
	## Cheap; also catches ancestor scale changes no signal reports.
	_sync_world_vp_size()
	for pair in _pairs:
		pair.tick_redraw()
	_sync_wax_hit_rect()
	_update_wax_feedback()


static func _load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path, "Texture2D") else null


func apply_spread(spread: Dictionary) -> void:
	## Current leaf. When it is the prepared neighbour (the usual case after a
	## turn), the ring just rotates: no page rebuild, no texture load.
	var key := _key_of(spread)
	if key != _cur_pair().spread_key():
		if key >= 0 and _pairs[_next].spread_key() == key:
			_rotate(1)
		elif key >= 0 and _pairs[_prev].spread_key() == key:
			_rotate(-1)
		elif _flip_animating and _turn_dir != 0:
			## Unprepared turn (no neighbours supplied): land on the pair the
			## leaf is already showing, so the visual still matches.
			_rotate(_turn_dir)
	_spread = spread.duplicate(true)
	_fill_pair(_cur_pair(), spread, true)
	## During a commit curl, keep the hinge pose; the rest binding follows on landing.
	if not _flip_animating:
		_reset_flip_visual()
	_refresh_wax_hit()


func apply_spread_list(spread_list: Array, index: int) -> void:
	## Convenience for the chapter screen: current leaf plus both neighbours.
	var at := func(i: int) -> Dictionary:
		return spread_list[i] if i >= 0 and i < spread_list.size() and spread_list[i] is Dictionary else {}
	apply_spread(at.call(index))
	set_neighbours(at.call(index - 1), at.call(index + 1))


func set_neighbours(prev_spread: Dictionary, next_spread: Dictionary) -> void:
	## Prepare the leaves either side of the current one: their art is
	## requested on a loader thread and their page viewports render ahead, so
	## the next turn shows real content on the leaf's back and underneath.
	_fill_pair(_pairs[_prev], prev_spread, false)
	_fill_pair(_pairs[_next], next_spread, false)
	var keep: Array = []
	for pair in _pairs:
		keep.append(pair.art_path())
	_art.keep_only(keep)


func is_ring_ready() -> bool:
	return not _has_pending_art()


func get_art_load_stats() -> Dictionary:
	return {
		"blocking_loads": _art.blocking_loads,
		"threaded_requests": _art.threaded_requests,
	}


func get_ring_state() -> Dictionary:
	## Read-only probe surface: which prepared pair holds which leaf.
	return {
		"prev_key": _pairs[_prev].spread_key(),
		"current_key": _pairs[_cur].spread_key(),
		"next_key": _pairs[_next].spread_key(),
		"prev_id": _pairs[_prev].get_instance_id(),
		"current_id": _pairs[_cur].get_instance_id(),
		"next_id": _pairs[_next].get_instance_id(),
		"pair_ids": _pairs.map(func(p: PagePair) -> int: return p.get_instance_id()),
	}


func get_page_bindings() -> Dictionary:
	## "<pair instance id>:<left|right>" per page surface, plus under visibility.
	var out := _bindings.duplicate()
	out["right_under_visible"] = is_instance_valid(_right_under_mesh) and _right_under_mesh.visible
	out["left_under_visible"] = is_instance_valid(_left_under_mesh) and _left_under_mesh.visible
	return out


func pair_side_id(pair_id: int, side: String) -> String:
	return "%d:%s" % [pair_id, side]


func get_desk_world() -> Node3D:
	return _desk_world


func get_book_root() -> Node3D:
	return _book_root


func get_desk_mesh() -> MeshInstance3D:
	return _desk_mesh


func get_readability_metrics() -> Dictionary:
	## EXPERIENCE §5.1 probe: on-screen text size in 1600x900-equivalent px,
	## reading angle, framing, contrast, and the viewport sizes.
	var probe := ReadingMetrics.new(
		_cam, _right_page_mesh, _book_root, _page_uv_to_world,
		Vector2(_world_vp.size), size
	)
	var out := probe.measure(_cur_pair())
	out["world_viewport"] = get_world_viewport_size()
	out["expected_world_viewport"] = expected_world_viewport_size()
	return out


func page_uv_to_world(is_left: bool, uv: Vector2) -> Vector3:
	## Public UV→world for tests / occlusion probes (arched leaf surface).
	var mesh := _left_page_mesh if is_left else _right_page_mesh
	return _page_uv_to_world(mesh, uv)


func get_page_occlusion_report() -> Dictionary:
	## AR-07: after DeskQuality is applied, no non-book mesh may sit on the
	## camera→page segment for corner / title / body / wax samples.
	var probe := PageOcclusion.new(
		_cam, _desk_world, _book_root, _left_page_mesh, _right_page_mesh,
		page_uv_to_world
	)
	return probe.report()


func physical_scale() -> Vector2:
	## Control units -> pixels of the window this stage is drawn into. Includes
	## the project's canvas_items stretch (logical 1600x900 -> window pixels,
	## which on macOS HiDPI are already backing pixels) and any parent scale.
	if not is_inside_tree():
		return Vector2.ONE
	var xf := get_viewport().get_final_transform() * get_global_transform_with_canvas()
	return xf.get_scale().abs()


func expected_world_viewport_size() -> Vector2i:
	var px := size * physical_scale()
	return Vector2i(maxi(2, roundi(px.x)), maxi(2, roundi(px.y)))


func get_world_viewport_size() -> Vector2i:
	return _world_vp.size if is_instance_valid(_world_vp) else Vector2i.ZERO


func _sync_world_vp_size() -> void:
	## EXPERIENCE §5.1: DeskWorld renders at physical pixels, never at the
	## logical size and then upscaled. The TextureRect shows it 1:1.
	if not is_instance_valid(_world_vp):
		return
	var want := expected_world_viewport_size()
	if want != _world_vp.size:
		_world_vp.size = want
	## The compatibility renderer builds no mip chain for a ViewportTexture, so
	## a 1024-wide leaf drawn ~400 px wide aliases. On low-density windows,
	## render 3D at 2x and let the bilinear resolve box-filter it.
	var ss := 2.0 if physical_scale().x < LOW_DPI_SCALE else 1.0
	if not is_equal_approx(_world_vp.scaling_3d_scale, ss):
		_world_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		_world_vp.scaling_3d_scale = ss


func book_is_fullbleed() -> bool:
	## Heuristic for probes: desk mesh exists and book is a child object, not a full-screen Control.
	return not (is_instance_valid(_desk_mesh) and is_instance_valid(_book_root))


func force_render_for_capture() -> void:
	## Headless normally freezes DeskWorld present; capture runners re-enable briefly.
	if is_instance_valid(_world_vp):
		_world_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for pair in _pairs:
		pair.set_update_mode(SubViewport.UPDATE_ALWAYS if pair == _cur_pair() else SubViewport.UPDATE_ONCE)
		pair.request_redraw()
	_sync_world_vp_size()


func _build_stage() -> void:
	## The world viewport is sized in physical pixels (see _sync_world_vp_size)
	## and shown by a plain TextureRect: a stretching SubViewportContainer would
	## force it back to the logical size.
	_world_vp = SubViewport.new()
	_world_vp.name = "DeskWorldViewport"
	_world_vp.size = Vector2i(1600, 900)
	_world_vp.transparent_bg = false
	_world_vp.handle_input_locally = false
	_world_vp.msaa_3d = Viewport.MSAA_DISABLED
	_world_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_world_vp.use_taa = false
	## Headless/dummy: keep node graph for probes; avoid continuous 3D present.
	if DisplayServer.get_name() == "headless":
		_world_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	else:
		_world_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_world_vp.own_world_3d = true
	## Warm night ambient + Forward+ FX (ADR-0035); DQ backplate sits in front of void.
	var env := Environment.new()
	DeskQuality.apply_forward_plus_environment(env)
	_world_vp.world_3d = World3D.new()
	_world_vp.world_3d.environment = env
	add_child(_world_vp)
	_stage = TextureRect.new()
	_stage.name = "DeskStage"
	_stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_stage.texture = _world_vp.get_texture()
	_stage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage.stretch_mode = TextureRect.STRETCH_SCALE
	_stage.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	## Ignore so this Control receives the swipe; seal uses a screen-space hit.
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	resized.connect(_sync_world_vp_size)
	call_deferred("_sync_world_vp_size")

	_desk_world = Node3D.new()
	_desk_world.name = "DeskWorld"
	_world_vp.add_child(_desk_world)

	var floor := MeshInstance3D.new()
	floor.name = "RoomFloor"
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(5.0, 0.06, 3.2)
	floor.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.09, 0.06, 0.04)
	floor_mat.roughness = 0.92
	floor.material_override = floor_mat
	floor.position = Vector3(0.0, -0.62, 0.2)
	_desk_world.add_child(floor)

	var cam := Camera3D.new()
	cam.name = "DeskCamera"
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	## Reference framing: the open book is the subject and nearly fills the
	## frame; only a sliver of desk, the candle and the quill stay in shot.
	## Narrower fov + closer dolly keeps perspective calm at this distance.
	cam.fov = CAMERA_FOV
	var pitch := deg_to_rad(-CAMERA_PITCH_DEG)
	cam.position = CAMERA_TARGET + Vector3(0.0, sin(pitch), cos(pitch)) * CAMERA_DISTANCE
	cam.rotation_degrees = Vector3(CAMERA_PITCH_DEG, 0.0, 0.0)
	_desk_world.add_child(cam)
	cam.current = true
	_cam = cam

	## Steep reading camera (−75°) no longer sees an upright far wall; lean the
	## DQ-01 plate toward the lens so it fills the far rim of the desk frame.
	var room := MeshInstance3D.new()
	room.name = "RoomBack"
	var room_mesh := BoxMesh.new()
	room_mesh.size = Vector3(3.8, 2.2, 0.04)
	room.mesh = room_mesh
	var room_mat := StandardMaterial3D.new()
	room_mat.albedo_color = Color(0.06, 0.04, 0.03)
	room.material_override = room_mat
	room.position = Vector3(0.0, 0.52, -0.78)
	room.rotation_degrees = Vector3(-62.0, 0.0, 0.0)
	_desk_world.add_child(room)
	DeskQuality.apply_room_backplate(room)
	## Side walls keep the desk from reading as a floating slab in black void.
	for side in [-1, 1]:
		var wall := MeshInstance3D.new()
		wall.name = "RoomSide%s" % ("L" if side < 0 else "R")
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(0.08, 2.2, 2.0)
		wall.mesh = wall_mesh
		var wall_mat := StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.05, 0.03, 0.02)
		wall.material_override = wall_mat
		wall.position = Vector3(side * 2.15, 0.85, 0.1)
		_desk_world.add_child(wall)

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.light_energy = 0.40
	key.light_color = Color(1.0, 0.98, 0.95)
	key.rotation_degrees = Vector3(-48.0, 35.0, 0.0)
	## Real cast shadows are what make the book read as an object ON the desk
	## instead of a lit sticker. Tight max_distance keeps the map dense on this
	## small set; normal_bias fights acne on the ~zero-thickness page quads.
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 7.0
	key.shadow_bias = 0.03
	key.shadow_normal_bias = 1.4
	key.shadow_opacity = 0.9
	_desk_world.add_child(key)
	DeskQuality.soften_key_light(key)

	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.light_energy = 0.12
	fill.light_color = Color(0.86, 0.9, 1.0)
	fill.position = Vector3(-0.45, 1.05, 0.45)
	fill.omni_range = 2.4
	_desk_world.add_child(fill)
	var fill_r := OmniLight3D.new()
	fill_r.name = "FillLightRight"
	fill_r.light_energy = 0.16
	fill_r.light_color = Color(0.84, 0.91, 1.0)
	fill_r.position = Vector3(0.7, 0.9, 0.4)
	fill_r.omni_range = 2.0
	_desk_world.add_child(fill_r)

	_desk_mesh = MeshInstance3D.new()
	_desk_mesh.name = "DeskMesh"
	var desk_box := BoxMesh.new()
	desk_box.size = Vector3(2.4, 0.08, 1.4)
	_desk_mesh.mesh = desk_box
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.28, 0.16, 0.08)
	desk_mat.roughness = 0.85
	var wood := _load_texture(WOOD_PATH)
	desk_mat.albedo_texture = wood if wood != null else _grain
	if wood != null:
		## The illustration supplies its own color; retain a slight warmth in the light.
		desk_mat.albedo_color = Color.WHITE
	if desk_mat.albedo_texture != null:
		desk_mat.uv1_scale = Vector3(1.45, 1.0, 1.0)
		desk_mat.texture_repeat = true
	_desk_mesh.material_override = desk_mat
	_desk_mesh.position = Vector3(0.0, -0.04, 0.05)
	_desk_world.add_child(_desk_mesh)
	DeskQuality.apply_desk_pbr(_desk_mesh)
	var desk_lip := MeshInstance3D.new()
	desk_lip.name = "DeskFrontLip"
	var lip_mesh := BoxMesh.new()
	lip_mesh.size = Vector3(2.42, 0.04, 0.06)
	desk_lip.mesh = lip_mesh
	var lip_mat := StandardMaterial3D.new()
	lip_mat.albedo_color = Color(0.2, 0.11, 0.05)
	lip_mat.roughness = 0.7
	desk_lip.material_override = lip_mat
	desk_lip.position = Vector3(0.0, -0.01, 0.72)
	_desk_world.add_child(desk_lip)
	## Four stub legs so the desk reads as furniture, not a floating plank.
	for leg_i in range(4):
		var leg := MeshInstance3D.new()
		leg.name = "DeskLeg%d" % leg_i
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.06, 0.55, 0.06)
		leg.mesh = leg_mesh
		var leg_mat := StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.16, 0.09, 0.04)
		leg.material_override = leg_mat
		var lx := -1.05 if leg_i % 2 == 0 else 1.05
		var lz := -0.55 if leg_i < 2 else 0.55
		leg.position = Vector3(lx, -0.35, lz)
		_desk_world.add_child(leg)

	_build_candle()

	var ink_sprite := _prop_sprite("inkwell", "InkwellProp", Vector3(0.84, 0.0, -0.10), 0.12)
	var quill_sprite := _prop_sprite(
		"quill_pen", "QuillProp", Vector3(0.99, 0.0, -0.04), 0.26, 0.0
	)
	if ink_sprite != null:
		_desk_world.add_child(ink_sprite)
	if quill_sprite != null:
		_desk_world.add_child(quill_sprite)
	if ink_sprite == null or quill_sprite == null:
		_build_desk_tools_mesh()
	_build_pages_and_book()
	DeskQuality.add_diary_contact_shadows(_desk_world, _book_root)


func _build_desk_tools_mesh() -> void:
	var inkwell := MeshInstance3D.new()
	inkwell.name = "InkwellMesh"
	var well_mesh := CylinderMesh.new()
	well_mesh.top_radius = 0.04
	well_mesh.bottom_radius = 0.045
	well_mesh.height = 0.07
	inkwell.mesh = well_mesh
	var well_mat := StandardMaterial3D.new()
	well_mat.albedo_color = Color(0.12, 0.1, 0.14)
	well_mat.metallic = 0.35
	well_mat.roughness = 0.4
	inkwell.material_override = well_mat
	inkwell.position = Vector3(0.86, 0.05, -0.30)
	_desk_world.add_child(inkwell)
	var quill := MeshInstance3D.new()
	quill.name = "QuillMesh"
	var quill_mesh := BoxMesh.new()
	quill_mesh.size = Vector3(0.012, 0.012, 0.28)
	quill.mesh = quill_mesh
	var quill_mat := StandardMaterial3D.new()
	quill_mat.albedo_color = Color(0.75, 0.72, 0.62)
	quill.material_override = quill_mat
	quill.position = Vector3(0.95, 0.04, -0.34)
	quill.rotation_degrees = Vector3(0.0, 28.0, 12.0)
	_desk_world.add_child(quill)
	var nib := MeshInstance3D.new()
	nib.name = "QuillNib"
	var nib_mesh := BoxMesh.new()
	nib_mesh.size = Vector3(0.01, 0.006, 0.04)
	nib.mesh = nib_mesh
	var nib_mat := StandardMaterial3D.new()
	nib_mat.albedo_color = Color(0.55, 0.45, 0.25)
	nib_mat.metallic = 0.6
	nib.material_override = nib_mat
	nib.position = Vector3(1.00, 0.035, -0.46)
	nib.rotation_degrees = Vector3(0.0, 28.0, 12.0)
	_desk_world.add_child(nib)


func _build_pages_and_book() -> void:
	## Three prepared spreads; the current pair is kept first in tree order so
	## find_child() probes land on the leaf the player is looking at.
	for i in range(3):
		var pair: PagePair = PagePair.new()
		pair.name = "PageSlot%d" % i
		pair.setup(_grain, _seal_textures)
		pair.wax_pressed.connect(_on_pair_wax_pressed.bind(pair))
		pair.rune_pressed.connect(_on_pair_rune_pressed.bind(pair))
		pair.side_sticker_pressed.connect(_on_pair_side_sticker_pressed.bind(pair))
		_desk_world.add_child(pair)
		_desk_world.move_child(pair, i)
		_pairs.append(pair)
	_apply_update_modes()

	_book_root = Node3D.new()
	_book_root.name = "BookRoot"
	_book_root.position = Vector3(0.04, 0.085, 0.0)
	## BRIEF ~55–65% viewport width with desk props still readable.
	_book_root.scale = Vector3(0.9, 0.9, 0.9)
	_desk_world.add_child(_book_root)

	var spine := MeshInstance3D.new()
	spine.name = "SpineMesh"
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.035, 0.058, 0.92)
	spine.mesh = spine_mesh
	var spine_mat := StandardMaterial3D.new()
	spine_mat.albedo_color = Color(0.18, 0.08, 0.04)
	spine.material_override = spine_mat
	spine.position.y = -0.031
	_book_root.add_child(spine)

	## Leather cover slab under pages — reads as a thick book on the desk.
	var cover := MeshInstance3D.new()
	cover.name = "CoverMesh"
	var cover_mesh := BoxMesh.new()
	cover_mesh.size = Vector3(1.49, 0.023, 0.994)
	cover.mesh = cover_mesh
	var cover_mat := StandardMaterial3D.new()
	cover_mat.albedo_color = Color(0.20, 0.105, 0.095)
	cover_mat.roughness = 0.72
	cover_mat.metallic = 0.08
	cover.material_override = cover_mat
	cover.position = Vector3(0.0, -0.081, 0.0)
	_book_root.add_child(cover)
	DeskQuality.apply_cover_leather(cover)
	DeskQuality.add_fore_edge_slabs(_book_root)

	## No fake contact plate here: KeyLight / candle now cast the real one.
	## Reference reads as a THICK volume: many leaves, each slightly inset and a
	## touch darker, so the fore-edge shows as a stack of paper rather than one
	## slab. Two half-stacks (not one full-width box) keep the gutter open.
	var leaf_count := 9
	for i in range(leaf_count):
		var t := float(i) / float(leaf_count - 1)
		for side in [-1, 1]:
			var stack := MeshInstance3D.new()
			stack.name = "PageStack%s%d" % ["L" if side < 0 else "R", i]
			var stack_mesh := BoxMesh.new()
			## Deeper leaves shrink slightly -> a tapered, hand-cut fore-edge.
			var w: float = 0.70 - t * 0.018
			var d: float = 0.95 - t * 0.022
			stack_mesh.size = Vector3(w, 0.0075, d)
			stack.mesh = stack_mesh
			var stack_mat := StandardMaterial3D.new()
			## Alternating tone so individual leaves separate under grazing light.
			var shade: float = 0.80 - t * 0.17 - (0.03 if i % 2 == 1 else 0.0)
			stack_mat.albedo_color = Color(shade, shade * 0.97, shade * 0.91)
			if i == 0 and _grain != null:
				# The leaf exposed during a turn belongs to the same paper stock.
				stack_mat.albedo_texture = _grain
				stack_mat.albedo_color = Color(0.76, 0.75, 0.73)
			stack_mat.roughness = 0.97
			stack.material_override = stack_mat
			stack.position = Vector3(
				side * (0.36 + t * 0.004), -0.008 - i * 0.0082, 0.0
			)
			_book_root.add_child(stack)

	## DQ-05 ribbon (visual); interactive「合上」is the chapter-screen CloseBookmark.
	var ribbon_art := _prop_sprite(
		"bookmark", "BookmarkProp", Vector3(-0.03, -0.088, 0.40), 0.46
	)
	if ribbon_art != null:
		ribbon_art.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		_book_root.add_child(ribbon_art)
	var ribbon := MeshInstance3D.new()
	ribbon.name = "BookmarkRibbon"
	ribbon.visible = false
	var ribbon_mesh := BoxMesh.new()
	ribbon_mesh.size = Vector3(0.05, 0.004, 0.30)
	ribbon.mesh = ribbon_mesh
	var ribbon_mat := StandardMaterial3D.new()
	ribbon_mat.albedo_color = Color(0.42, 0.09, 0.08)
	ribbon_mat.roughness = 0.6
	ribbon.material_override = ribbon_mat
	ribbon.position = Vector3(-0.03, -0.088, 0.56)
	ribbon.rotation_degrees = Vector3(0.0, 4.0, 0.0)
	_book_root.add_child(ribbon)
	DeskQuality.replace_bookmark_ribbon(_book_root, ribbon)

	## Hinges sit on the spine so yaw turns the leaf like a real page, not a center spin.
	_left_hinge = Node3D.new()
	_left_hinge.name = "LeftPageHinge"
	_left_hinge.position = Vector3(-0.002, 0.01, 0.0)
	_book_root.add_child(_left_hinge)
	_right_hinge = Node3D.new()
	_right_hinge.name = "RightPageHinge"
	_right_hinge.position = Vector3(0.002, 0.01, 0.0)
	_book_root.add_child(_right_hinge)
	_left_page_mesh = _make_page_mesh("LeftPageMesh", true)
	_right_page_mesh = _make_page_mesh("RightPageMesh", false)
	_left_hinge.add_child(_left_page_mesh)
	_right_hinge.add_child(_right_page_mesh)
	## Each turning leaf is two-sided: the back shows the neighbour's facing
	## page, so the leaf lands already carrying the new content.
	_left_back_mesh = _make_page_mesh("LeftPageBackMesh", true)
	_right_back_mesh = _make_page_mesh("RightPageBackMesh", false)
	_left_hinge.add_child(_left_back_mesh)
	_right_hinge.add_child(_right_back_mesh)
	## Pages revealed under a lifting leaf; a hair below its rest pose.
	_left_under_mesh = _make_under_mesh("LeftUnderPageMesh", true)
	_right_under_mesh = _make_under_mesh("RightUnderPageMesh", false)

	_bind_page_textures()


func _build_candle() -> void:
	## Painted candle when delivered; otherwise the procedural turned brass.
	var sprite := _prop_sprite("candle", "CandleProp", Vector3(-0.86, 0.0, -0.14), 0.28)
	if sprite != null:
		_desk_world.add_child(sprite)
		## Keep the lighting rig the mesh version provided: a sprite emits none.
		_candle_flame_light = OmniLight3D.new()
		_candle_flame_light.name = "CandleFlame"
		_candle_flame_light.position = Vector3(-0.86, 0.24, -0.14)
		_candle_flame_light.light_color = Color(1.0, 0.78, 0.54)
		_candle_flame_light.light_energy = 0.26
		_candle_flame_light.omni_range = 3.2
		## Omni shadows are expensive under Forward+ HiDPI; DQ-06 contact shadow covers the cue.
		_candle_flame_light.shadow_enabled = false
		_desk_world.add_child(_candle_flame_light)
		## Probe compatibility: V083 looks for a node named CandleMesh.
		var marker := Node3D.new()
		marker.name = "CandleMesh"
		sprite.add_child(marker)
		return
	_build_candlestick_mesh()


func _build_candlestick_mesh() -> void:
	var origin := Vector3(-0.84, 0.0, -0.19)
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.65, 0.49, 0.29)
	brass.metallic = 0.62
	brass.roughness = 0.32
	var holder := _turned_mesh("CandleHolder", [
		Vector2(0.001, 0), Vector2(0.085, 0), Vector2(0.093, 0.005),
		Vector2(0.094, 0.012), Vector2(0.088, 0.016), Vector2(0.079, 0.017),
		Vector2(0.079, 0.022), Vector2(0.072, 0.026), Vector2(0.055, 0.031),
		Vector2(0.032, 0.043), Vector2(0.022, 0.05), Vector2(0.021, 0.058),
		Vector2(0.031, 0.067), Vector2(0.032, 0.076), Vector2(0.025, 0.084),
		Vector2(0.018, 0.091), Vector2(0.020, 0.105), Vector2(0.034, 0.11),
		Vector2(0.054, 0.116), Vector2(0.070, 0.127), Vector2(0.071, 0.132),
		Vector2(0.067, 0.134), Vector2(0.061, 0.129), Vector2(0.050, 0.124),
		Vector2(0.034, 0.122), Vector2(0.032, 0.134), Vector2(0.035, 0.148),
		Vector2(0.036, 0.153), Vector2(0.030, 0.155), Vector2(0.027, 0.15)
	], brass)
	holder.position = origin
	_desk_world.add_child(holder)
	var wax := StandardMaterial3D.new()
	wax.albedo_color = Color(0.90, 0.855, 0.735)
	wax.roughness = 0.78
	var candle := _turned_mesh("CandleMesh", [
		Vector2(0.026, 0.144), Vector2(0.027, 0.195), Vector2(0.026, 0.25),
		Vector2(0.027, 0.266), Vector2(0.024, 0.270), Vector2(0.017, 0.261),
		Vector2(0.009, 0.258), Vector2(0.001, 0.258)
	], wax, true)
	holder.add_child(candle)
	for i in 4:
		var drop := MeshInstance3D.new()
		var bead := SphereMesh.new()
		bead.radius = 0.003 + i % 2 * 0.001
		bead.height = 0.019 + i % 3 * 0.009
		drop.mesh = bead
		drop.material_override = wax
		var angle := 0.55 + i * 1.57
		drop.position = Vector3(0.026 * cos(angle), 0.261 - bead.height * 0.46, 0.026 * sin(angle))
		candle.add_child(drop)
	var wick_mat := StandardMaterial3D.new()
	wick_mat.albedo_color = Color(0.09, 0.065, 0.045)
	candle.add_child(_turned_mesh("Wick", [Vector2(0.002, 0.257), Vector2(0.0016, 0.272)], wick_mat))
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.84, 0.48)
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_candle_flame_mesh = _turned_mesh("CandleFlameMesh", [
		Vector2(0.001, 0.270), Vector2(0.0065, 0.277), Vector2(0.006, 0.284),
		Vector2(0.003, 0.293), Vector2(0.0002, 0.307)
	], flame_mat)
	holder.add_child(_candle_flame_mesh)
	_candle_flame_light = OmniLight3D.new()
	_candle_flame_light.name = "CandleFlame"
	_candle_flame_light.position = Vector3(0.006, 0.285, 0.008)
	_candle_flame_light.light_color = Color(1.0, 0.78, 0.54)
	_candle_flame_light.light_energy = 0.035
	_candle_flame_light.omni_range = 0.68
	holder.add_child(_candle_flame_light)


func _prop_sprite(
	prop_id: String,
	node_name: String,
	ground: Vector3,
	height_m: float,
	yaw_deg := 0.0
) -> Sprite3D:
	## Painted prop cutout standing on the desk. Returns null when the art has
	## not been ingested, so every call site keeps its procedural fallback.
	var tex := PropCatalog.texture(prop_id)
	if tex == null:
		return null
	var sprite := Sprite3D.new()
	sprite.name = node_name
	sprite.texture = tex
	sprite.pixel_size = height_m / float(maxi(1, tex.get_height()))
	## Pivot at the foot of the art, so a prop sits ON the desk whatever its
	## pixel height, and the yaw/pitch below rotate about that contact point.
	sprite.offset = Vector2(0.0, float(tex.get_height()) * 0.5)
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	## Alpha-discard (not blend) so the cutout casts a real shadow and never
	## sorts oddly against the book.
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.shaded = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	## The pivot is the painted foot (offset above), so leaning the quad back
	## keeps it on the desk. Upright it collapsed to a sliver under the steep
	## reading camera; PROP_LEAN_DEG gives it back most of its height.
	sprite.rotation_degrees = Vector3(-PROP_LEAN_DEG, yaw_deg, 0.0)
	## Nudge the foot just above the desk surface so the quad never z-fights it.
	sprite.position = ground + Vector3(0.0, 0.004, 0.0)
	return sprite


static func _turned_mesh(label: String, profile: Array[Vector2], material: Material, molten := false) -> MeshInstance3D:
	# Rotate the reference silhouette around the stem. A separate normal per
	# profile segment preserves the machined lips even at diary viewing scale.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 48
	for ring in profile.size() - 1:
		var slope := profile[ring + 1] - profile[ring]
		for i in SIDES:
			for corner: Vector2i in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
				var angle := TAU * float(i + corner.x) / SIDES
				var section := profile[ring + corner.y]
				var y := section.y
				if molten and y > 0.26:
					y += 0.0028 * sin(3.0 * angle) + 0.0015 * cos(5.0 * angle)
				surface.set_normal(Vector3(slope.y * cos(angle), -slope.x, slope.y * sin(angle)).normalized())
				surface.add_vertex(Vector3(section.x * cos(angle), y, section.x * sin(angle)))
	surface.index()
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = surface.commit()
	part.material_override = material
	return part


func _make_page_mesh(node_name: String, is_left: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var quad := QuadMesh.new()
	quad.size = Vector2(0.72, 0.96)
	quad.subdivide_width = 35
	var arrays := quad.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in vertices.size():
		var t := 1.0 - uvs[i].x if is_left else uvs[i].x
		vertices[i].z = _page_height(t)
		var slope := (_page_height(t + 0.001) - _page_height(t - 0.001)) / 0.00144
		normals[i] = Vector3(slope if is_left else -slope, 0.0, 1.0).normalized()
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var leaf := ArrayMesh.new()
	leaf.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = leaf
	mi.position = Vector3(-0.36 if is_left else 0.36, 0.004, 0.0)
	mi.rotation_degrees.x = -90.0
	return mi


static func _page_height(t: float) -> float:
	# Gathered paper arches just outside the binding and falls toward the fore edge.
	return 0.22 * t * exp(-6.5 * t) + 0.005 * sin(PI * t)


func _make_under_mesh(node_name: String, is_left: bool) -> MeshInstance3D:
	var mount := Node3D.new()
	mount.name = node_name + "Mount"
	mount.position = Vector3(-0.002 if is_left else 0.002, 0.007, 0.0)
	_book_root.add_child(mount)
	var mi := _make_page_mesh(node_name, is_left)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	mount.add_child(mi)
	return mi


func _page_material(mirror_u: bool, back: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.88
	## Front faces only on the leaf proper; its twin draws the back faces.
	mat.cull_mode = BaseMaterial3D.CULL_FRONT if back else BaseMaterial3D.CULL_BACK
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.28, 0.18)
	## Trimmed now that shadows land on the leaves — just enough lift to keep
	## ink readable when the right page falls into the candle's shadow side.
	mat.emission_energy_multiplier = 0.0
	if mirror_u:
		## Seen from behind after a half-turn, u runs spine->edge reversed.
		mat.uv1_scale = Vector3(-1.0, 1.0, 1.0)
		mat.uv1_offset = Vector3(1.0, 0.0, 0.0)
	## Pages are minified onto the desk; ask for trilinear + anisotropic. A
	## ViewportTexture has no mip chain in Godot 4.7 (no SubViewport option), so
	## this measures as plain bilinear today; the anti-aliasing comes from the
	## supersampled 3D pass instead (see _sync_world_vp_size).
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


func _bind_page_textures() -> void:
	_left_page_mesh.material_override = _page_material(false, false)
	_right_page_mesh.material_override = _page_material(false, false)
	_left_back_mesh.material_override = _page_material(true, true)
	_right_back_mesh.material_override = _page_material(true, true)
	_left_under_mesh.material_override = _page_material(false, false)
	_right_under_mesh.material_override = _page_material(false, false)
	## A turning leaf must shadow whichever face points at the light.
	for leaf in [_left_page_mesh, _right_page_mesh]:
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	for back in [_left_back_mesh, _right_back_mesh]:
		back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bind_rest()


func _bind(mesh: MeshInstance3D, role: String, pair: PagePair, side: String) -> void:
	var mat := mesh.material_override as StandardMaterial3D
	var vp: SubViewport = pair.left_vp if side == "left" else pair.right_vp
	mat.albedo_texture = vp.get_texture()
	_bindings[role] = pair_side_id(pair.get_instance_id(), side)


func _bind_rest() -> void:
	## Flat spread: both leaves show the current pair, nothing beneath.
	var cur := _cur_pair()
	_bind(_left_page_mesh, "left", cur, "left")
	_bind(_right_page_mesh, "right", cur, "right")
	_bind(_left_back_mesh, "left_back", cur, "left")
	_bind(_right_back_mesh, "right_back", cur, "right")
	_right_under_mesh.visible = false
	_left_under_mesh.visible = false
	_turn_dir = 0


func _bind_turn(dir: int) -> void:
	## Forward: right leaf front = current right, back = next left, beneath =
	## next right. Backward mirrors it with the previous pair.
	if dir == 0:
		_bind_rest()
		return
	var cur := _cur_pair()
	_bind(_left_page_mesh, "left", cur, "left")
	_bind(_right_page_mesh, "right", cur, "right")
	if dir > 0:
		var nxt: PagePair = _pairs[_next]
		_bind(_right_back_mesh, "right_back", nxt, "left")
		_bind(_right_under_mesh, "right_under", nxt, "right")
		## A blocked turn only bounces: do not let the lifted leaf reveal it.
		_right_under_mesh.visible = not _block_forward
		_left_under_mesh.visible = false
	else:
		var prv: PagePair = _pairs[_prev]
		_bind(_left_back_mesh, "left_back", prv, "right")
		_bind(_left_under_mesh, "left_under", prv, "left")
		_left_under_mesh.visible = not _block_backward
		_right_under_mesh.visible = false
	_turn_dir = dir
	_turn_from_key = cur.spread_key()


func _cur_pair() -> PagePair:
	return _pairs[_cur]


static func _key_of(spread: Dictionary) -> int:
	if spread.is_empty():
		return -1
	return int(spread.get("spread_index", spread.get("page_index", -1)))


func _rotate(dir: int) -> void:
	## Swap roles only. The pair that wraps around holds a stale leaf, so it is
	## blanked until set_neighbours() prepares it.
	var wrapped: int
	if dir > 0:
		wrapped = _prev
		_prev = _cur
		_cur = _next
		_next = wrapped
	else:
		wrapped = _next
		_next = _cur
		_cur = _prev
		_prev = wrapped
	_fill_pair(_pairs[wrapped], {}, false)
	_apply_update_modes()


func _apply_update_modes() -> void:
	## Current pair draws every frame (the seal breathes); neighbours keep the
	## frame they rendered once after their last fill.
	for i in range(_pairs.size()):
		var pair: PagePair = _pairs[i]
		if i == _cur:
			pair.set_update_mode(SubViewport.UPDATE_ALWAYS)
		elif pair.left_vp.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
			pair.set_update_mode(SubViewport.UPDATE_DISABLED)
	if is_instance_valid(_desk_world):
		_desk_world.move_child(_cur_pair(), 0)


func _fill_pair(pair: PagePair, spread: Dictionary, block: bool) -> void:
	pair.fill(spread)
	var path: String = pair.art_path()
	if path == pair.shown_art_path and pair.pending_art_path.is_empty():
		return
	if path.is_empty():
		pair.pending_art_path = ""
		pair.set_art("", null)
		return
	var tex := _art.take(path, block)
	if tex != null or block:
		pair.pending_art_path = ""
		pair.set_art(path, tex)
		return
	## Not decoded yet: paper placeholder now, real art when the thread lands.
	pair.pending_art_path = path
	if not pair.shown_art_path.is_empty():
		pair.set_art("", null)
	set_process(true)


func _has_pending_art() -> bool:
	for pair in _pairs:
		if not String(pair.pending_art_path).is_empty():
			return true
	return false


func _poll_pending_art() -> void:
	for pair in _pairs:
		var path: String = pair.pending_art_path
		if path.is_empty() or not _art.ready(path):
			continue
		pair.pending_art_path = ""
		pair.set_art(path, _art.take(path, false))


func _on_pair_wax_pressed(pair: Node) -> void:
	if pair == _cur_pair():
		_on_wax_pressed()


func _on_pair_rune_pressed(index: int, pair: Node) -> void:
	if pair != _cur_pair():
		return
	var clue := _primary_clue()
	var state: int = pair.state()
	var title := String(_spread.get("title_zh", clue.get("title_zh", "未署名页")))
	var body: String = pair.rune_hint(index, state)
	var ann := String(clue.get("annotation_zh", ""))
	if state == DiaryCatalog.STATE_COMPLETED and not ann.is_empty():
		body = "%s\n%s" % [body, ann.substr(0, 36)]
	elif state == DiaryCatalog.STATE_AVAILABLE:
		body = "%s\n点蜡封启事。" % body
	elif state == DiaryCatalog.STATE_LOCKED:
		body = "%s\n墨封未启。" % body
	_show_rune_detail("%s\n%s" % [title, body])


func _on_pair_side_sticker_pressed(pair: Node) -> void:
	if pair != _cur_pair():
		return
	var notes: Array = _spread.get("side_notes", [])
	if notes.is_empty():
		return
	var lines: PackedStringArray = []
	for note_value in notes:
		if not note_value is Dictionary:
			continue
		var note: Dictionary = note_value
		var t := String(note.get("title_zh", note.get("margin_note_zh", "旁支")))
		lines.append("· %s" % t.substr(0, 16))
	_show_rune_detail("页边贴条\n%s" % "\n".join(lines))


func _build_rune_detail() -> void:
	_rune_detail = PanelContainer.new()
	_rune_detail.name = "RuneDetailLayer"
	_rune_detail.visible = false
	_rune_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	_rune_detail.anchor_left = 0.42
	_rune_detail.anchor_right = 0.78
	_rune_detail.anchor_top = 0.58
	_rune_detail.anchor_bottom = 0.78
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.88)
	style.border_color = Color(0.62, 0.45, 0.22, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	_rune_detail.add_theme_stylebox_override("panel", style)
	_rune_detail_label = Label.new()
	_rune_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rune_detail_label.add_theme_font_override("font", Ui.diary_ink_font())
	_rune_detail_label.add_theme_font_size_override("font_size", 18)
	_rune_detail_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68))
	_rune_detail.add_child(_rune_detail_label)
	_rune_detail.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_hide_rune_detail()
	)
	add_child(_rune_detail)


func _show_rune_detail(text: String) -> void:
	if not is_instance_valid(_rune_detail) or not is_instance_valid(_rune_detail_label):
		return
	_rune_detail_label.text = text
	_rune_detail.visible = true
	_rune_detail.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_rune_detail, "modulate:a", 1.0, 0.12)


func _hide_rune_detail() -> void:
	if is_instance_valid(_rune_detail):
		_rune_detail.visible = false


func _build_vignette() -> void:
	## Reference falls off to near-black at the corners so the lit book is the
	## only thing the eye lands on. Four edge gradients beat a shader here
	## (gl_compatibility, and it must sit over the 3D SubViewport).
	var host := Control.new()
	host.name = "DeskVignette"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(host)
	var edges := {
		"VignetteTop": [Vector2(0.0, 0.0), Vector2(1.0, 0.30), Vector2(0.5, 0.0)],
		"VignetteBottom": [Vector2(0.0, 0.72), Vector2(1.0, 1.0), Vector2(0.5, 1.0)],
		"VignetteLeft": [Vector2(0.0, 0.0), Vector2(0.22, 1.0), Vector2(0.0, 0.5)],
		"VignetteRight": [Vector2(0.80, 0.0), Vector2(1.0, 1.0), Vector2(1.0, 0.5)],
	}
	for edge_name in edges.keys():
		var rect: Array = edges[edge_name]
		var grad := Gradient.new()
		grad.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
		grad.set_color(1, Color(0.0, 0.0, 0.0, 0.42))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.width = 128
		tex.height = 128
		tex.fill = GradientTexture2D.FILL_LINEAR
		var focus: Vector2 = rect[2]
		tex.fill_from = Vector2(1.0 - focus.x, 1.0 - focus.y)
		tex.fill_to = focus
		var tr := TextureRect.new()
		tr.name = edge_name
		tr.texture = tex
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.anchor_left = rect[0].x
		tr.anchor_top = rect[0].y
		tr.anchor_right = rect[1].x
		tr.anchor_bottom = rect[1].y
		host.add_child(tr)


func _build_settlement_bloom() -> void:
	_settlement_bloom = ColorRect.new()
	_settlement_bloom.name = "SettlementInkBloom"
	_settlement_bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settlement_bloom.color = Color(0.35, 0.08, 0.05, 0.0)
	_settlement_bloom.anchor_left = 0.35
	_settlement_bloom.anchor_right = 0.72
	_settlement_bloom.anchor_top = 0.32
	_settlement_bloom.anchor_bottom = 0.72
	add_child(_settlement_bloom)


func play_settlement_fx(kind: String = "pen") -> void:
	## Presentation-only desk ink bloom (win / wipe / defeat). Does not touch rules.
	if not is_instance_valid(_settlement_bloom):
		return
	var tint := Color(0.45, 0.12, 0.08, 0.0)
	match kind:
		"wipe":
			tint = Color(0.25, 0.4, 0.7, 0.0)
		"defeat", "ink":
			tint = Color(0.12, 0.04, 0.03, 0.0)
		"win":
			tint = Color(0.55, 0.35, 0.12, 0.0)
		_:
			tint = Color(0.45, 0.12, 0.08, 0.0)
	_settlement_bloom.color = tint
	_settlement_bloom.color.a = 0.0
	var peak := 0.55 if kind != "wipe" else 0.4
	var tw := create_tween()
	tw.tween_property(_settlement_bloom, "color:a", peak, 0.18)
	tw.tween_property(_settlement_bloom, "color:a", 0.0, 0.55)
	if is_instance_valid(_book_root):
		var base_scale := _book_root.scale
		var punch := create_tween()
		punch.tween_property(_book_root, "scale", base_scale * 1.03, 0.12).set_trans(Tween.TRANS_BACK)
		punch.tween_property(_book_root, "scale", base_scale, 0.22)
	TableSfx.play(self, TableSfx.KIND_WIPE if kind == "wipe" else TableSfx.KIND_PEN)


func _primary_clue() -> Dictionary:
	var clues: Array = _spread.get("clues", [])
	if clues.size() > 0 and clues[0] is Dictionary:
		return clues[0]
	return {}


func _gui_input(event: InputEvent) -> void:
	if _flip_animating or _bounce_animating:
		## A leaf is already in the air; ignore new gestures until it settles so
		## the drag never fights the commit / programmatic tween.
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_input_mode = INPUT_ARM
			_press_pos = mb.position
			_flip_progress = 0.0
			_set_wax_hit_enabled(true)
			accept_event()
		else:
			_on_release(mb.position)
			accept_event()
	elif event is InputEventMouseMotion and _input_mode != INPUT_IDLE:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _press_pos
		if _input_mode == INPUT_ARM and delta.length() > CLICK_SLOP_PX:
			_input_mode = INPUT_FLIP
			## Gesture became a flip — don't let the seal steal the release.
			_set_wax_hit_enabled(false)
		if _input_mode == INPUT_FLIP:
			## Drag left (negative x) opens next page; right goes previous.
			_flip_progress = clampf((-delta.x) / maxf(180.0, size.x * 0.22), -1.0, 1.0)
			_apply_flip_visual(_flip_progress * DRAG_TURN_SCALE)
			accept_event()


func _apply_flip_visual(progress: float) -> void:
	## progress: turn fraction, signed by direction (see COMMIT_TURN).
	var p := clampf(progress, -1.0, 1.0)
	var dir := 0 if is_zero_approx(p) else (1 if p > 0.0 else -1)
	if dir != _turn_dir:
		_bind_turn(dir)
	var s := absf(p)
	var angle := 180.0 * s
	var lift := 0.05 * sin(PI * s) + LAND_LIFT * smoothstep(COMMIT_TURN, 1.0, s)
	## Paper relaxes flat as it falls onto the far side.
	var flat := 1.0 - 0.97 * smoothstep(0.55, 1.0, s)
	## The binding runs along Z. Both leaves lift toward +Y.
	if is_instance_valid(_right_hinge):
		var on := dir > 0
		_right_hinge.rotation_degrees = Vector3(0.0, 0.0, angle if on else 0.0)
		_right_hinge.position = Vector3(0.002, 0.01 + (lift if on else 0.0), 0.0)
		_set_leaf_flat(_right_page_mesh, _right_back_mesh, flat if on else 1.0)
	if is_instance_valid(_left_hinge):
		var on := dir < 0
		_left_hinge.rotation_degrees = Vector3(0.0, 0.0, -angle if on else 0.0)
		_left_hinge.position = Vector3(-0.002, 0.01 + (lift if on else 0.0), 0.0)
		_set_leaf_flat(_left_page_mesh, _left_back_mesh, flat if on else 1.0)
	_shade_turning_leaf(s, dir)


func _set_leaf_flat(front: MeshInstance3D, back: MeshInstance3D, flat: float) -> void:
	for mesh in [front, back]:
		if is_instance_valid(mesh):
			mesh.scale = Vector3(1.0, 1.0, flat)


func _shade_turning_leaf(s: float, dir: int) -> void:
	## A leaf edge-on to the key light reads darker; nothing to hide any more.
	var shade: float = 1.0 - 0.3 * sin(PI * s)
	_set_leaf_shade(_right_page_mesh, shade if dir > 0 else 1.0)
	_set_leaf_shade(_right_back_mesh, shade if dir > 0 else 1.0)
	_set_leaf_shade(_left_page_mesh, shade if dir < 0 else 1.0)
	_set_leaf_shade(_left_back_mesh, shade if dir < 0 else 1.0)


func _set_leaf_shade(mesh: MeshInstance3D, shade: float) -> void:
	if not is_instance_valid(mesh):
		return
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = Color(shade, shade, shade, 1.0)


func _reset_flip_visual() -> void:
	_flip_progress = 0.0
	_apply_flip_visual(0.0)
	_bind_rest()


func is_flip_animating() -> bool:
	return _flip_animating


func play_flip(delta: int, total_duration: float = PROG_FLIP_DURATION) -> bool:
	## Programmatic turn (nav bookmarks / settlement auto-flip / index chain).
	## Same hinge motion as a drag commit, from a flat leaf.
	if _flip_animating or delta == 0:
		return false
	var dur := maxf(0.2, total_duration)
	_input_mode = INPUT_IDLE
	_flip_progress = 0.0
	_commit_turn(delta, 0.0, dur * PROG_FLIP_RISE_FRAC, dur * (1.0 - PROG_FLIP_RISE_FRAC))
	return true


func _commit_turn(delta: int, from_turn: float, rise: float, settle: float) -> void:
	## Leaf rises to upright, the chapter commits (apply_spread rotates the
	## ring to the prepared neighbour), then it falls onto the far side and
	## the rest binding takes over with identical content: no swap to see.
	var dir := 1 if delta > 0 else -1
	var peak := COMMIT_TURN * dir
	_flip_animating = true
	_hide_rune_detail()
	## Seal must not take a click while the leaf is mid-air.
	_set_wax_hit_enabled(false)
	TableSfx.play(self, TableSfx.KIND_FLIP)
	if _turn_dir != dir:
		_bind_turn(dir)
	_turn_from_key = _cur_pair().spread_key()
	var tw := create_tween()
	tw.tween_method(_apply_flip_visual, from_turn, peak, maxf(0.04, rise)).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		flip_committed.emit(delta)
		## A refused commit (gate said no) leaves the current leaf in place:
		## fall back flat instead of landing on content that did not change.
		var landed: bool = _cur_pair().spread_key() != _turn_from_key
		_settle_from = peak
		_settle_to = float(dir) if landed else 0.0
	)
	tw.tween_method(_settle_turn, 0.0, 1.0, settle).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_flip_animating = false
		_reset_flip_visual()
		_set_wax_hit_enabled(true)
		flip_visual_finished.emit()
	)


func _settle_turn(u: float) -> void:
	_apply_flip_visual(lerpf(_settle_from, _settle_to, u))


func set_flip_target_locked(locked: bool) -> void:
	## Compat: lock both directions when parent only knows "blocked".
	_block_forward = locked
	_block_backward = locked


func set_flip_blocked(forward: bool, backward: bool) -> void:
	_block_forward = forward
	_block_backward = backward


func bounce_flip(reason: String = "") -> void:
	_play_bounce(reason)


func _build_ink_seep() -> void:
	_ink_seep = ColorRect.new()
	_ink_seep.name = "InkSeep"
	_ink_seep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_seep.color = Color(0.08, 0.03, 0.02, 0.0)
	_ink_seep.anchor_left = 0.48
	_ink_seep.anchor_right = 0.78
	_ink_seep.anchor_top = 0.28
	_ink_seep.anchor_bottom = 0.82
	add_child(_ink_seep)


func _build_screen_wax_hit() -> void:
	## Page SubViewports live under Node3D — their Buttons do not get screen picks.
	## Screen-space hit approximates the right-page seal region on the desk book.
	_wax_hit = Button.new()
	_wax_hit.name = "WaxSealHit"
	_wax_hit.focus_mode = Control.FOCUS_ALL
	_wax_hit.flat = true
	var empty_style := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		_wax_hit.add_theme_stylebox_override(style_name, empty_style)
	## Rect is PROJECTED from the seal's real world position every frame (see
	## _sync_wax_hit_rect). Hand-tuned anchors silently drifted whenever the
	## camera or book scale changed; these are only a pre-first-frame fallback.
	_wax_hit.anchor_left = 0.54
	_wax_hit.anchor_right = 0.76
	_wax_hit.anchor_top = 0.52
	_wax_hit.anchor_bottom = 0.82
	_wax_hit.pressed.connect(_on_wax_pressed)
	add_child(_wax_hit)


func _page_uv_to_world(mesh: MeshInstance3D, uv: Vector2) -> Vector3:
	var distance_from_spine := (1.0 - uv.x) if mesh == _left_page_mesh else uv.x
	var local := Vector3((uv.x - 0.5) * 0.72, (0.5 - uv.y) * 0.96, _page_height(distance_from_spine))
	return mesh.global_transform * local


func _sync_wax_hit_rect() -> void:
	## Keep the screen-space hit glued to where the seal actually renders.
	if not is_instance_valid(_wax_hit) or not is_instance_valid(_cam):
		return
	if _pairs.is_empty() or not is_instance_valid(_right_page_mesh):
		return
	if _flip_animating or _bounce_animating:
		return
	var seal_rect: Rect2 = _cur_pair().wax_button.get_global_rect()
	if seal_rect.size.x <= 1.0 or seal_rect.size.y <= 1.0:
		return
	var vp_size := Vector2(PAGE_VP_SIZE)
	var corners: Array[Vector2] = []
	for corner in [
		seal_rect.position,
		seal_rect.position + Vector2(seal_rect.size.x, 0.0),
		seal_rect.position + Vector2(0.0, seal_rect.size.y),
		seal_rect.position + seal_rect.size,
	]:
		var uv := Vector2(corner.x / vp_size.x, corner.y / vp_size.y)
		var world := _page_uv_to_world(_right_page_mesh, uv)
		if _cam.is_position_behind(world):
			return
		corners.append(_cam.unproject_position(world))
	var min_p := corners[0]
	var max_p := corners[0]
	for pt in corners:
		min_p = min_p.min(pt)
		max_p = max_p.max(pt)
	## unproject gives DeskWorld (physical) pixels; the stage TextureRect spans
	## this Control, so normalise by the viewport size.
	var vp := Vector2(_world_vp.size)
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	## Small outward pad so the wax edge stays comfortably clickable.
	var pad := Vector2(6.0, 6.0)
	min_p -= pad
	max_p += pad
	_wax_hit.anchor_left = clampf(min_p.x / vp.x, 0.0, 1.0)
	_wax_hit.anchor_right = clampf(max_p.x / vp.x, 0.0, 1.0)
	_wax_hit.anchor_top = clampf(min_p.y / vp.y, 0.0, 1.0)
	_wax_hit.anchor_bottom = clampf(max_p.y / vp.y, 0.0, 1.0)
	_wax_hit.offset_left = 0.0
	_wax_hit.offset_right = 0.0
	_wax_hit.offset_top = 0.0
	_wax_hit.offset_bottom = 0.0


func _refresh_wax_hit() -> void:
	if not is_instance_valid(_wax_hit):
		return
	var clue := _primary_clue()
	var title := String(_spread.get("title_zh", clue.get("title_zh", "")))
	var state_name := String(clue.get("state_name", _cur_pair().wax_button.text))
	_wax_hit.accessibility_name = "%s · %s" % [title, state_name]
	_wax_hit.tooltip_text = _wax_hit.accessibility_name
	## Spread content swaps at the peak of a turn; keep the seal cold until the
	## leaf is flat, otherwise a mid-air click enters the next level.
	_set_wax_hit_enabled(not _flip_animating and not _bounce_animating)


func _update_wax_feedback() -> void:
	if not is_instance_valid(_wax_hit) or _pairs.is_empty():
		return
	var wax_art: TextureRect = _cur_pair().wax_art
	var wax_button: Button = _cur_pair().wax_button
	var pulse: bool = _cur_pair().state() == DiaryCatalog.STATE_AVAILABLE and not _spread.is_empty()
	var emphasized := not _wax_hit.disabled and (
		_wax_hit.is_hovered() or _wax_hit.has_focus()
	)
	var brightness := 1.0
	if pulse:
		brightness = 0.96 + 0.04 * sin(_flame_t * 3.2)
	if emphasized:
		brightness *= 1.13
	if _wax_hit.button_pressed:
		brightness *= 0.91
	wax_art.modulate = Color(brightness, brightness, brightness)
	if pulse:
		wax_button.modulate = wax_art.modulate


func _on_wax_pressed() -> void:
	if _input_mode == INPUT_FLIP or _flip_animating:
		return
	_hide_rune_detail()
	var clue := _primary_clue()
	if clue.is_empty():
		return
	TableSfx.play(self, TableSfx.KIND_SEAL)
	seal_activated.emit(clue)


func _set_wax_hit_enabled(enabled: bool) -> void:
	if not is_instance_valid(_wax_hit):
		return
	_wax_hit.disabled = not enabled
	_wax_hit.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	_wax_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	_wax_hit.mouse_filter = (
		Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	)


func _on_release(pos: Vector2) -> void:
	var mode := _input_mode
	_input_mode = INPUT_IDLE
	if mode == INPUT_FLIP:
		## Keep seal off until the turn / bounce finishes.
		_set_wax_hit_enabled(false)
		var delta := 1 if _flip_progress > 0.0 else -1
		var blocked := (delta > 0 and _block_forward) or (delta < 0 and _block_backward)
		if absf(_flip_progress) >= FLIP_THRESHOLD and not blocked:
			## Carry the leaf from where the hand left it up to upright (commit)
			## and on over onto the far side.
			var from_turn := _flip_progress * DRAG_TURN_SCALE
			var rise := 0.18 * (COMMIT_TURN - absf(from_turn)) / (COMMIT_TURN * 0.5)
			_commit_turn(delta, from_turn, rise, 0.30)
			return
		var reason := ""
		if blocked and absf(_flip_progress) >= FLIP_THRESHOLD:
			reason = (
				"墨封未启——还不能掀到后面。"
				if delta > 0
				else "这一叠已经到头了。"
			)
		_play_bounce(reason)
		return
	_set_wax_hit_enabled(true)
	if mode == INPUT_ARM and pos.distance_to(_press_pos) <= CLICK_SLOP_PX:
		pass


func _play_bounce(reason: String = "") -> void:
	if _bounce_tween != null and is_instance_valid(_bounce_tween):
		_bounce_tween.kill()
	var from := _flip_progress * DRAG_TURN_SCALE
	_bounce_animating = true
	_bounce_tween = create_tween()
	_bounce_tween.tween_method(_apply_flip_visual, from, 0.0, 0.2)
	_bounce_tween.tween_callback(func() -> void:
		_bounce_animating = false
		_reset_flip_visual()
		_set_wax_hit_enabled(true)
	)
	if is_instance_valid(_ink_seep) and not reason.is_empty():
		_ink_seep.color.a = 0.0
		var seep := create_tween()
		seep.tween_property(_ink_seep, "color:a", 0.42, 0.12)
		seep.tween_property(_ink_seep, "color:a", 0.0, 0.38)
	if not reason.is_empty():
		status_message.emit(reason)
