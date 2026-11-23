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
const GRAIN_PATH := "res://assets/ui/diary/parchment_grain.png"
const WOOD_PATH := "res://assets/ui/diary/desk_wood.png"
const SEAL_PATHS := {
	DiaryCatalog.STATE_AVAILABLE: "res://assets/ui/diary/wax_seal_available.png",
	DiaryCatalog.STATE_COMPLETED: "res://assets/ui/diary/wax_seal_completed.png",
	DiaryCatalog.STATE_LOCKED: "res://assets/ui/diary/wax_seal_locked.png",
}
const SEAL_SIZE := Vector2(82, 82)

## Desk camera pitch. Prop sprites reuse it so a cutout always faces the
## camera squarely instead of being foreshortened; change it in one place.
const CAMERA_PITCH_DEG := -47.5

const CLICK_SLOP_PX := 10.0
const FLIP_THRESHOLD := 0.5
## A committed turn always carries the leaf nearly all the way over, whether the
## player dragged it to threshold or a nav / settlement turned it for them.
const COMMIT_FLIP_PEAK := 0.95
const PROG_FLIP_DURATION := 0.56
const PROG_FLIP_RISE_FRAC := 0.45
const PAGE_VP_SIZE := Vector2i(512, 720)

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

var _stage: SubViewportContainer
var _world_vp: SubViewport
var _desk_world: Node3D
var _book_root: Node3D
var _right_page_mesh: MeshInstance3D
var _left_page_mesh: MeshInstance3D
var _right_hinge: Node3D
var _left_hinge: Node3D
var _left_vp: SubViewport
var _right_vp: SubViewport
var _left_art: TextureRect
var _title_label: Label
var _ink_label: Label
var _wax_button: Button
var _wax_art: TextureRect
var _seal_textures: Dictionary = {}
var _rune_strip: Container
var _rune_buttons: Array[Button] = []
var _rune_art: Array[Node] = []
var _rune_detail: PanelContainer
var _rune_detail_label: Label
var _side_sticker: Button
var _settlement_bloom: ColorRect
var _desk_mesh: MeshInstance3D
var _grain: Texture2D
var _wax_hit: Button
var _candle_flame_light: OmniLight3D
var _candle_flame_mesh: MeshInstance3D
var _flame_t := 0.0
var _wax_pulse_active := false
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
	set_process(DisplayServer.get_name() != "headless")


func _process(delta: float) -> void:
	## Candle light is deliberately STATIC (flicker read as noise and forced a
	## shadow re-render every frame). Only the seal breathes, to stay findable.
	_flame_t += delta
	_sync_wax_hit_rect()
	_update_wax_feedback()


static func _load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path, "Texture2D") else null


func apply_spread(spread: Dictionary) -> void:
	_spread = spread.duplicate(true)
	## During a commit curl, keep the hinge pose so content can swap mid-turn.
	if not _flip_animating:
		_reset_flip_visual()
	_fill_pages()
	_refresh_wax_hit()


func get_desk_world() -> Node3D:
	return _desk_world


func get_book_root() -> Node3D:
	return _book_root


func get_desk_mesh() -> MeshInstance3D:
	return _desk_mesh


func _sync_world_vp_size() -> void:
	## DeskStage uses stretch=true; SubViewport size follows the container — do not set manually.
	if not is_instance_valid(_world_vp) or not is_instance_valid(_stage):
		return
	if _stage.stretch:
		return
	var w := maxi(2, int(size.x))
	var h := maxi(2, int(size.y))
	if w != _world_vp.size.x or h != _world_vp.size.y:
		_world_vp.size = Vector2i(w, h)


func book_is_fullbleed() -> bool:
	## Heuristic for probes: desk mesh exists and book is a child object, not a full-screen Control.
	return not (is_instance_valid(_desk_mesh) and is_instance_valid(_book_root))


func force_render_for_capture() -> void:
	## Headless normally freezes DeskWorld present; capture runners re-enable briefly.
	if is_instance_valid(_world_vp):
		_world_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if is_instance_valid(_left_vp):
		_left_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if is_instance_valid(_right_vp):
		_right_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sync_world_vp_size()


func _build_stage() -> void:
	_stage = SubViewportContainer.new()
	_stage.name = "DeskStage"
	_stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_stage.stretch = true
	## Ignore so parent DeskStage receives swipe; seal uses screen-space hit.
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_world_vp = SubViewport.new()
	_world_vp.name = "DeskWorldViewport"
	_world_vp.size = Vector2i(1600, 900)
	_world_vp.transparent_bg = false
	_world_vp.handle_input_locally = false
	## Headless/dummy: keep node graph for probes; avoid continuous 3D present.
	if DisplayServer.get_name() == "headless":
		_world_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	else:
		_world_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_world_vp.own_world_3d = true
	## Warm night ambient — avoids pure black void between desk props.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.025, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.76, 0.80, 0.86)
	env.ambient_light_energy = 0.64
	_world_vp.world_3d = World3D.new()
	_world_vp.world_3d.environment = env
	_stage.add_child(_world_vp)
	## Match stage pixels when the shell resizes (sharper desk render).
	resized.connect(_sync_world_vp_size)
	_stage.resized.connect(_sync_world_vp_size)
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
	cam.fov = 38.0
	cam.position = Vector3(0.0, 1.61, 0.93)
	cam.rotation_degrees = Vector3(-59.0, 0.0, 0.0)
	_desk_world.add_child(cam)
	cam.current = true
	_cam = cam

	var room := MeshInstance3D.new()
	room.name = "RoomBack"
	var room_mesh := BoxMesh.new()
	room_mesh.size = Vector3(4.5, 2.6, 0.08)
	room.mesh = room_mesh
	var room_mat := StandardMaterial3D.new()
	room_mat.albedo_color = Color(0.06, 0.04, 0.03)
	room.material_override = room_mat
	room.position = Vector3(0.0, 0.9, -0.85)
	_desk_world.add_child(room)
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
	_left_vp = _make_page_viewport("LeftPageViewport")
	_right_vp = _make_page_viewport("RightPageViewport")
	_desk_world.add_child(_left_vp)
	_desk_world.add_child(_right_vp)
	_build_page_roots()

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

	## Ribbon marker falling out of the gutter over the fore-edge.
	var ribbon_art := _prop_sprite(
		"bookmark", "BookmarkProp", Vector3(-0.03, -0.088, 0.40), 0.46
	)
	if ribbon_art != null:
		## Lies flat along the desk rather than standing up like the props.
		ribbon_art.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		_book_root.add_child(ribbon_art)
	var ribbon := MeshInstance3D.new()
	ribbon.name = "BookmarkRibbon"
	ribbon.visible = ribbon_art == null
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
		_candle_flame_light.shadow_enabled = true
		_candle_flame_light.shadow_bias = 0.04
		_candle_flame_light.shadow_normal_bias = 1.2
		_candle_flame_light.shadow_opacity = 0.7
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
	## Stand UPRIGHT (no pitch): tilting the quad back by the camera pitch threw
	## the painted foot ~32% of its height off the contact point, so props
	## floated. A vertical quad under a pitched camera reads as standing on the
	## desk, which is what the painted art already depicts.
	sprite.rotation_degrees = Vector3(0.0, yaw_deg, 0.0)
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


func _page_parchment(node_name: String, mirror: bool) -> TextureRect:
	## Photographed sheet as the leaf surface. Mirrored on the left page so the
	## spread does not read as the same stamp printed twice. Null when the art
	## is absent, and the caller falls back to the procedural grain tile.
	var sheet := PropCatalog.texture("parchment_sheet")
	if sheet == null:
		return null
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture = sheet
	tr.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	## The sheet has deckled edges; COVERED would crop them off, so stretch it
	## to the leaf and let the painted edge land on the page border.
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.flip_h = mirror
	## The photographed sheet is near-white; under the key light it blew out.
	## Modulate it back to parchment so ink keeps its contrast.
	tr.modulate = Color(0.62, 0.57, 0.49)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _make_page_viewport(node_name: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.name = node_name
	vp.size = PAGE_VP_SIZE
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	return vp


func _build_page_roots() -> void:
	var left_root := Control.new()
	left_root.name = "LeftPageRoot"
	left_root.size = Vector2(PAGE_VP_SIZE)
	_left_vp.add_child(left_root)
	var left_bg := ColorRect.new()
	left_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	left_bg.color = Color(0.74, 0.67, 0.52)
	left_root.add_child(left_bg)
	var left_sheet := _page_parchment("LeftPageParchment", true)
	if left_sheet != null:
		left_root.add_child(left_sheet)
	elif _grain != null:
		var left_grain := TextureRect.new()
		left_grain.name = "LeftPageGrain"
		left_grain.texture = _grain
		left_grain.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		left_grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		left_grain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		left_grain.modulate = Color(0.76, 0.75, 0.73)
		left_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_root.add_child(left_grain)
	## Reference: the illustration is washed straight onto the leaf and fades
	## into the paper. No dark plate, no gold border — those read as a sticker.
	var art_frame := MarginContainer.new()
	art_frame.name = "SceneArtFrame"
	art_frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	art_frame.add_theme_constant_override("margin_left", 40)
	art_frame.add_theme_constant_override("margin_right", 52)
	art_frame.add_theme_constant_override("margin_top", 58)
	art_frame.add_theme_constant_override("margin_bottom", 72)
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_root.add_child(art_frame)
	var art_plate := Control.new()
	art_plate.name = "SceneArtPlate"
	art_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art_plate)
	_left_art = TextureRect.new()
	_left_art.name = "SceneArt"
	_left_art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_left_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_left_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_left_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_plate.add_child(_left_art)
	var feather := Shader.new()
	feather.code = """shader_type canvas_item;
	void fragment() {
		vec2 edge = min(UV, 1.0 - UV);
		COLOR.a *= smoothstep(0.0, 0.028, min(edge.x, edge.y));
	}"""
	var feather_mat := ShaderMaterial.new()
	feather_mat.shader = feather
	_left_art.material = feather_mat

	var right_root := Control.new()
	right_root.name = "RightPageRoot"
	right_root.size = Vector2(PAGE_VP_SIZE)
	right_root.theme = Ui.build_theme()
	_right_vp.add_child(right_root)
	var right_bg := ColorRect.new()
	right_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	right_bg.color = Color(0.74, 0.67, 0.52)
	right_root.add_child(right_bg)
	var right_sheet := _page_parchment("RightPageParchment", false)
	if right_sheet != null:
		right_root.add_child(right_sheet)
	elif _grain != null:
		var grain := TextureRect.new()
		grain.texture = _grain
		grain.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		grain.modulate = Color(0.76, 0.75, 0.73)
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right_root.add_child(grain)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 40)
	right_root.add_child(margin)
	## Reference splits the leaf: written column on the left, a rail of state
	## marks down the right margin.
	var row := HBoxContainer.new()
	row.name = "RightPageRow"
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var col := VBoxContainer.new()
	col.name = "RightPageColumn"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	row.add_child(col)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.add_theme_font_override("font", Ui.diary_ink_font(true))
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.18, 0.1, 0.05))
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.clip_text = true
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title_label)
	var folio := Label.new()
	folio.name = "FolioLabel"
	folio.add_theme_font_size_override("font_size", 18)
	folio.add_theme_color_override("font_color", Color(0.42, 0.28, 0.14, 0.75))
	folio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(folio)

	_ink_label = Label.new()
	_ink_label.name = "InkLabel"
	_ink_label.add_theme_font_override("font", Ui.diary_ink_font())
	_ink_label.add_theme_font_size_override("font_size", 24)
	_ink_label.add_theme_color_override("font_color", Color(0.16, 0.09, 0.05))
	_ink_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ink_label.clip_text = true
	_ink_label.max_lines_visible = 10
	_ink_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	## Slight letter spacing so ≤60 字 doesn't feel like a dense system dump.
	_ink_label.add_theme_constant_override("line_spacing", 6)
	col.add_child(_ink_label)

	_wax_button = Button.new()
	_wax_button.name = "WaxSealButton"
	_wax_button.text = "启"
	_wax_button.custom_minimum_size = SEAL_SIZE
	_wax_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_wax_button.focus_mode = Control.FOCUS_NONE
	var seal_style := StyleBoxFlat.new()
	seal_style.bg_color = Color(0.45, 0.13, 0.135)
	seal_style.corner_radius_top_left = 54
	seal_style.corner_radius_top_right = 54
	seal_style.corner_radius_bottom_left = 54
	seal_style.corner_radius_bottom_right = 54
	seal_style.border_width_left = 2
	seal_style.border_width_top = 2
	seal_style.border_width_right = 2
	seal_style.border_width_bottom = 2
	seal_style.border_color = Color(0.35, 0.08, 0.06, 0.9)
	_wax_button.add_theme_stylebox_override("normal", seal_style)
	seal_style.shadow_color = Color(0.12, 0.05, 0.04, 0.36)
	seal_style.shadow_offset = Vector2(2, 4)
	seal_style.shadow_size = 4
	var seal_hover := seal_style.duplicate() as StyleBoxFlat
	seal_hover.bg_color = Color(0.56, 0.16, 0.16)
	_wax_button.add_theme_stylebox_override("hover", seal_hover)
	_wax_button.add_theme_stylebox_override("pressed", seal_style)
	_wax_button.add_theme_color_override("font_color", Color(0.96, 0.86, 0.55))
	_wax_button.add_theme_font_size_override("font_size", 32)
	_wax_button.pressed.connect(_on_wax_pressed)
	## Soft drop shadow under the seal so it reads as wax on paper.
	var seal_host := Control.new()
	seal_host.name = "WaxSealHost"
	seal_host.custom_minimum_size = SEAL_SIZE + Vector2(8, 8)
	seal_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(seal_host)
	_wax_button.position = Vector2(4, 4)
	_wax_button.size = SEAL_SIZE
	seal_host.add_child(_wax_button)
	_wax_art = TextureRect.new()
	_wax_art.name = "WaxSealArt"
	_wax_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wax_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wax_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_wax_art.position = _wax_button.position
	_wax_art.size = SEAL_SIZE
	_wax_art.hide()
	seal_host.add_child(_wax_art)

	_rune_strip = VBoxContainer.new()
	_rune_strip.name = "RuneStrip"
	_rune_strip.alignment = BoxContainer.ALIGNMENT_BEGIN
	_rune_strip.add_theme_constant_override("separation", 14)
	_rune_strip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_rune_buttons.clear()
	_rune_art.clear()
	var rune_glyphs: PackedStringArray = ["✶", "✦", "〄", "◎"]
	var rune_names := PropCatalog.TOKEN_LABELS
	for i in range(4):
		var cell := VBoxContainer.new()
		cell.name = "RuneCell%d" % i
		cell.add_theme_constant_override("separation", 1)
		var rune := Button.new()
		rune.name = "Rune%d" % i
		rune.text = rune_glyphs[i]
		rune.custom_minimum_size = Vector2(46, 46)
		rune.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rune.focus_mode = Control.FOCUS_NONE
		rune.flat = false
		rune.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		rune.add_theme_font_size_override("font_size", 20)
		## Real medallion art when ingested; the glyph/StyleBox stays as the
		## fallback so a missing prop degrades instead of blanking the rail.
		var token := PropCatalog.token_for_state(i)
		if token != null:
			rune.text = ""
			var art := TextureRect.new()
			art.name = "RuneArt%d" % i
			art.texture = token
			art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rune.add_child(art)
			_rune_art.append(art)
		else:
			_rune_art.append(null)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.32, 0.26, 0.2, 0.55)
		## Round medallions, not squares — matches the stamped-seal language.
		style.corner_radius_top_left = 23
		style.corner_radius_top_right = 23
		style.corner_radius_bottom_left = 23
		style.corner_radius_bottom_right = 23
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.45, 0.35, 0.22, 0.55)
		rune.add_theme_stylebox_override("normal", style)
		rune.add_theme_stylebox_override("hover", style)
		rune.add_theme_stylebox_override("pressed", style)
		rune.pressed.connect(_on_rune_pressed.bind(i))
		cell.add_child(rune)
		var caption := Label.new()
		caption.name = "RuneCaption%d" % i
		caption.text = rune_names[i]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_size_override("font_size", 16)
		caption.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 0.85))
		cell.add_child(caption)
		_rune_buttons.append(rune)
		_rune_strip.add_child(cell)
	row.add_child(_rune_strip)
	## Side-branch sticker (kind!=main); hidden until spread carries side_notes.
	_side_sticker = Button.new()
	_side_sticker.name = "SideBranchSticker"
	_side_sticker.visible = false
	_side_sticker.focus_mode = Control.FOCUS_NONE
	_side_sticker.text = "旁"
	_side_sticker.custom_minimum_size = Vector2(36, 28)
	_side_sticker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_side_sticker.add_theme_font_size_override("font_size", 12)
	_side_sticker.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	var sticker_style := StyleBoxFlat.new()
	sticker_style.bg_color = Color(0.82, 0.72, 0.48, 0.92)
	sticker_style.border_color = Color(0.55, 0.38, 0.16, 0.8)
	sticker_style.border_width_left = 1
	sticker_style.border_width_top = 1
	sticker_style.border_width_right = 1
	sticker_style.border_width_bottom = 1
	sticker_style.corner_radius_top_left = 2
	sticker_style.corner_radius_top_right = 2
	sticker_style.corner_radius_bottom_left = 2
	sticker_style.corner_radius_bottom_right = 2
	_side_sticker.add_theme_stylebox_override("normal", sticker_style)
	_side_sticker.pressed.connect(_on_side_sticker_pressed)
	col.add_child(_side_sticker)


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


func _bind_page_textures() -> void:
	var left_mat := StandardMaterial3D.new()
	left_mat.albedo_texture = _left_vp.get_texture()
	left_mat.roughness = 0.88
	left_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	left_mat.emission_enabled = true
	left_mat.emission = Color(0.35, 0.28, 0.18)
	## Trimmed now that shadows land on the leaves — just enough lift to keep
	## ink readable when the right page falls into the candle's shadow side.
	left_mat.emission_energy_multiplier = 0.0
	_left_page_mesh.material_override = left_mat
	var right_mat := StandardMaterial3D.new()
	right_mat.albedo_texture = _right_vp.get_texture()
	right_mat.roughness = 0.88
	right_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	right_mat.emission_enabled = true
	right_mat.emission = Color(0.4, 0.32, 0.2)
	right_mat.emission_energy_multiplier = 0.0
	_right_page_mesh.material_override = right_mat


func _fill_pages() -> void:
	var clue := _primary_clue()
	var art_path := String(_spread.get("left_art_path", clue.get("left_art_path", "")))
	var art := _load_texture(art_path) if not art_path.is_empty() else null
	if art == null:
		_left_art.texture = _grain
		_left_art.modulate = Color(0.95, 0.9, 0.82, 1.0)
	else:
		_left_art.texture = art
		## Lighting carries the leaf now; a boost here just blows the wash out.
		_left_art.modulate = Color.WHITE
	_left_art.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if art != null and art_path.get_base_dir() == SceneCatalog.DIARY_ART_DIR
		else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)
	_title_label.text = String(_spread.get("title_zh", clue.get("title_zh", "")))
	var folio := _right_vp.find_child("FolioLabel", true, false) as Label
	if folio != null:
		var idx := int(_spread.get("spread_index", _spread.get("page_index", 0))) + 1
		folio.text = "其 %d 叶" % idx
	_ink_label.text = String(_spread.get("ink_zh", clue.get("ink_zh", clue.get("text_zh", ""))))
	## 0-08 rewrite reads as warm gold on the page; Roselle stays brown ink.
	if bool(clue.get("rewritten_by_pen", false)):
		_ink_label.add_theme_color_override("font_color", Color(0.62, 0.42, 0.12))
	else:
		_ink_label.add_theme_color_override("font_color", Color(0.16, 0.09, 0.05))
	var state := int(_spread.get("state", clue.get("state", DiaryCatalog.STATE_LOCKED)))
	_wax_pulse_active = state == DiaryCatalog.STATE_AVAILABLE
	match state:
		DiaryCatalog.STATE_AVAILABLE:
			_wax_button.text = "启"
			_wax_button.modulate = Color(1, 1, 1, 1)
			_ink_label.modulate = Color(1, 1, 1, 1)
		DiaryCatalog.STATE_COMPLETED:
			_wax_button.text = "阅"
			_wax_button.modulate = Color(0.75, 0.7, 0.55)
			_ink_label.modulate = Color(1, 1, 1, 0.92)
		_:
			_wax_button.text = "封"
			_wax_button.modulate = Color(0.45, 0.4, 0.38)
			## Locked leaf: ink reads drowned / sealed.
			_ink_label.modulate = Color(0.55, 0.5, 0.48, 0.7)
	_wax_art.texture = _seal_textures.get(state) as Texture2D
	_wax_art.visible = _wax_art.texture != null
	_wax_button.visible = not _wax_art.visible
	_update_wax_feedback()
	_refresh_runes(state)
	_refresh_side_sticker()


func _refresh_runes(state: int) -> void:
	if not is_instance_valid(_rune_strip):
		return
	## Four marks: 0=本叶状态, 1=可启, 2=已阅, 3=墨封 — lit by clue state (P1).
	var lit := [
		state == DiaryCatalog.STATE_AVAILABLE or state == DiaryCatalog.STATE_COMPLETED,
		state == DiaryCatalog.STATE_AVAILABLE,
		state == DiaryCatalog.STATE_COMPLETED,
		state == DiaryCatalog.STATE_LOCKED,
	]
	var base := Color(0.28, 0.22, 0.18, 0.5)
	match state:
		DiaryCatalog.STATE_AVAILABLE:
			base = Color(0.42, 0.31, 0.18, 0.95)
		DiaryCatalog.STATE_COMPLETED:
			base = Color(0.32, 0.55, 0.3, 0.9)
	for i in range(_rune_buttons.size()):
		var rune := _rune_buttons[i]
		if not is_instance_valid(rune):
			continue
		var style := rune.get_theme_stylebox("normal") as StyleBoxFlat
		if style == null:
			style = StyleBoxFlat.new()
			rune.add_theme_stylebox_override("normal", style)
			rune.add_theme_stylebox_override("hover", style)
			rune.add_theme_stylebox_override("pressed", style)
		var is_lit: bool = lit[i] if i < lit.size() else false
		## With medallion art present the plate must step back, or the painted
		## token sits on a coloured disc. Lit/unlit then reads on the art.
		var has_art: bool = i < _rune_art.size() and is_instance_valid(_rune_art[i])
		if is_lit:
			style.bg_color = Color(0, 0, 0, 0) if has_art else base
			style.border_color = (
				Color(0, 0, 0, 0)
				if has_art
				else Color(base.r + 0.15, base.g + 0.1, base.b + 0.05, 0.9)
			)
			rune.modulate = Color(1, 1, 1, 1)
		else:
			style.bg_color = Color(0, 0, 0, 0) if has_art else Color(0.28, 0.22, 0.18, 0.4)
			style.border_color = (
				Color(0, 0, 0, 0) if has_art else Color(0.4, 0.32, 0.22, 0.35)
			)
			## Unlit tokens read as dimmed metal rather than vanishing.
			rune.modulate = Color(0.62, 0.6, 0.58, 0.5) if has_art else Color(1, 1, 1, 0.55)
		rune.tooltip_text = _rune_hint(i, state)


func _rune_hint(index: int, state: int) -> String:
	var state_zh := "墨封"
	match state:
		DiaryCatalog.STATE_AVAILABLE:
			state_zh = "可启"
		DiaryCatalog.STATE_COMPLETED:
			state_zh = "已阅"
	var marks: PackedStringArray = ["本叶", "启印", "阅印", "封印"]
	var mark: String = marks[index] if index >= 0 and index < marks.size() else "符"
	return "%s · %s" % [mark, state_zh]


func _refresh_side_sticker() -> void:
	if not is_instance_valid(_side_sticker):
		return
	var notes: Array = _spread.get("side_notes", [])
	if notes.is_empty():
		_side_sticker.visible = false
		return
	_side_sticker.visible = true
	_side_sticker.tooltip_text = "旁支 %d" % notes.size()


func _on_rune_pressed(index: int) -> void:
	var clue := _primary_clue()
	var state := int(_spread.get("state", clue.get("state", DiaryCatalog.STATE_LOCKED)))
	var title := String(_spread.get("title_zh", clue.get("title_zh", "未署名页")))
	var body := _rune_hint(index, state)
	var ann := String(clue.get("annotation_zh", ""))
	if state == DiaryCatalog.STATE_COMPLETED and not ann.is_empty():
		body = "%s\n%s" % [body, ann.substr(0, 36)]
	elif state == DiaryCatalog.STATE_AVAILABLE:
		body = "%s\n点蜡封启事。" % body
	elif state == DiaryCatalog.STATE_LOCKED:
		body = "%s\n墨封未启。" % body
	_show_rune_detail("%s\n%s" % [title, body])


func _on_side_sticker_pressed() -> void:
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
	_rune_detail_label.add_theme_font_size_override("font_size", 13)
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
			_apply_flip_visual(_flip_progress)
			accept_event()


func _apply_flip_visual(progress: float) -> void:
	var p := clampf(progress, -1.0, 1.0)
	## The binding runs along Z. Both leaves lift toward +Y.
	if is_instance_valid(_right_hinge):
		var right_turn := maxf(0.0, p) * 95.0
		var right_lift := maxf(0.0, p) * 0.05
		_right_hinge.rotation_degrees = Vector3(0.0, 0.0, right_turn)
		_right_hinge.position = Vector3(0.002, 0.01 + right_lift, 0.0)
	if is_instance_valid(_left_hinge):
		var left_turn := maxf(0.0, -p) * -95.0
		var left_lift := maxf(0.0, -p) * 0.05
		_left_hinge.rotation_degrees = Vector3(0.0, 0.0, left_turn)
		_left_hinge.position = Vector3(-0.002, 0.01 + left_lift, 0.0)
	_shade_turning_leaf(p)


func _shade_turning_leaf(p: float) -> void:
	## Shadow softens the content swap at the top of the arc.
	var dip := smoothstep(0.45, 0.95, absf(p))
	var shade: float = 1.0 - 0.82 * dip
	_set_leaf_shade(_right_page_mesh, shade if p > 0.0 else 1.0)
	_set_leaf_shade(_left_page_mesh, shade if p < 0.0 else 1.0)


func _set_leaf_shade(mesh: MeshInstance3D, shade: float) -> void:
	if not is_instance_valid(mesh):
		return
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = Color(shade, shade, shade, 1.0)


func _reset_flip_visual() -> void:
	_flip_progress = 0.0
	_set_leaf_shade(_right_page_mesh, 1.0)
	_set_leaf_shade(_left_page_mesh, 1.0)
	if is_instance_valid(_right_hinge):
		_right_hinge.rotation_degrees = Vector3.ZERO
		_right_hinge.position = Vector3(0.002, 0.01, 0.0)
	if is_instance_valid(_left_hinge):
		_left_hinge.rotation_degrees = Vector3.ZERO
		_left_hinge.position = Vector3(-0.002, 0.01, 0.0)


func is_flip_animating() -> bool:
	return _flip_animating


func play_flip(delta: int, total_duration: float = PROG_FLIP_DURATION) -> bool:
	## Programmatic turn (nav bookmarks / settlement auto-flip / index chain).
	## Without this these entries swapped the spread with no hinge motion, i.e.
	## exactly the 2D flash the desk carrier exists to remove. Mirrors the drag
	## commit: curl up, swap content at the peak, then settle flat.
	if _flip_animating or delta == 0:
		return false
	var over: float = COMMIT_FLIP_PEAK if delta > 0 else -COMMIT_FLIP_PEAK
	var dur := maxf(0.2, total_duration)
	var rise := dur * PROG_FLIP_RISE_FRAC
	_flip_animating = true
	_input_mode = INPUT_IDLE
	_flip_progress = 0.0
	_hide_rune_detail()
	## Seal must not take a click while the leaf is mid-air.
	_set_wax_hit_enabled(false)
	TableSfx.play(self, TableSfx.KIND_FLIP)
	var tw := create_tween()
	tw.tween_method(_apply_flip_visual, 0.0, over, rise).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		flip_committed.emit(delta)
	)
	tw.tween_method(_apply_flip_visual, over, 0.0, dur - rise).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_flip_animating = false
		_reset_flip_visual()
		_set_wax_hit_enabled(true)
		flip_visual_finished.emit()
	)
	return true


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
	if not is_instance_valid(_wax_button) or not is_instance_valid(_right_page_mesh):
		return
	if _flip_animating or _bounce_animating:
		return
	var seal_rect := _wax_button.get_global_rect()
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
	## unproject gives DeskWorld viewport pixels; stretch=true maps them 1:1
	## onto this Control, so normalise by the viewport size.
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
	var state_name := String(clue.get("state_name", _wax_button.text))
	_wax_hit.accessibility_name = "%s · %s" % [title, state_name]
	_wax_hit.tooltip_text = _wax_hit.accessibility_name
	## Spread content swaps at the peak of a turn; keep the seal cold until the
	## leaf is flat, otherwise a mid-air click enters the next level.
	_set_wax_hit_enabled(not _flip_animating and not _bounce_animating)


func _update_wax_feedback() -> void:
	if not is_instance_valid(_wax_hit) or not is_instance_valid(_wax_art):
		return
	var emphasized := not _wax_hit.disabled and (
		_wax_hit.is_hovered() or _wax_hit.has_focus()
	)
	var brightness := 1.0
	if _wax_pulse_active:
		brightness = 0.96 + 0.04 * sin(_flame_t * 3.2)
	if emphasized:
		brightness *= 1.13
	if _wax_hit.button_pressed:
		brightness *= 0.91
	_wax_art.modulate = Color(brightness, brightness, brightness)
	if _wax_pulse_active:
		_wax_button.modulate = _wax_art.modulate


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
			## Peak curl → parent swaps spread while still turned → ease flat onto new leaf.
			var peak := _flip_progress
			## Threshold can be as low as 0.5; carry it the rest of the way over
			## so a committed turn always looks like the leaf went past vertical.
			var over: float = signf(peak) * maxf(absf(peak) * 1.1, COMMIT_FLIP_PEAK)
			_flip_animating = true
			_hide_rune_detail()
			TableSfx.play(self, TableSfx.KIND_FLIP)
			var tw := create_tween()
			tw.tween_method(_apply_flip_visual, peak, over, 0.18).set_trans(
				Tween.TRANS_SINE
			).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void:
				flip_committed.emit(delta)
			)
			tw.tween_method(_apply_flip_visual, over, 0.0, 0.26).set_trans(
				Tween.TRANS_SINE
			).set_ease(Tween.EASE_IN)
			tw.tween_callback(func() -> void:
				_flip_animating = false
				_reset_flip_visual()
				_set_wax_hit_enabled(true)
				flip_visual_finished.emit()
			)
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
	var from := _flip_progress
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
