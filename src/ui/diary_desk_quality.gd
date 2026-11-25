extends RefCounted

## Diary-station visual upgrade (ADR-0034 D4 / ADR-0035 Forward+).
## Applies DQ-01…03/05/06 onto an already-built DeskWorld without owning the
## page SubViewports (those live in diary_page_pair) or chrome (chapter screen).

const DeskCatalog := preload("res://src/ui/desk_world_catalog.gd")


static func apply_forward_plus_environment(env: Environment) -> void:
	## ADR-0036 Mobile (user 2026-11-25): minimal exposure/glow correction only.
	## No style retune (palette / candle layout wait for ADR-0037 key frames).
	var method := String(RenderingServer.get_current_rendering_method())
	var compat := method == "gl_compatibility"
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	## RD (Mobile) is ~60% darker at the same lights; lift exposure to match.
	env.tonemap_exposure = 1.15 if compat else 3.0
	env.tonemap_white = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.10
	env.glow_strength = 0.42
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.25
	env.glow_hdr_scale = 1.4
	env.glow_blend_mode = (
		Environment.GLOW_BLEND_MODE_SOFTLIGHT if compat
		else Environment.GLOW_BLEND_MODE_SCREEN
	)
	## Prefer mid/high glow mips only — skips the costliest fine levels.
	env.set("glow_levels/1", false)
	env.set("glow_levels/2", false)
	env.set("glow_levels/3", true)
	env.set("glow_levels/4", true)
	env.set("glow_levels/5", true)
	env.set("glow_levels/6", false)
	env.set("glow_levels/7", false)
	## SSAO is Forward+-only; enabling it on Mobile spam-warns every build.
	env.ssao_enabled = method == "forward_plus"
	if env.ssao_enabled:
		env.ssao_radius = 0.35
		env.ssao_intensity = 0.48
		env.ssao_power = 1.05
		env.ssao_detail = 0.05
		env.ssao_horizon = 0.1
		env.ssao_sharpness = 0.85
	## Warm night void behind the backplate; ambient kept low so SSAO reads.
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.016, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.50, 0.42)
	env.ambient_light_energy = 0.45


static func soften_key_light(key: DirectionalLight3D) -> void:
	if key == null:
		return
	## Soft angular disc → Forward+ penumbra; Compatibility ignores harmlessly.
	## Keep blur modest — HiDPI + SSAO already tax the frame.
	key.light_angular_distance = 1.6
	key.light_energy = 0.48
	key.shadow_blur = 0.6


static func apply_room_backplate(room: MeshInstance3D) -> void:
	if room == null:
		return
	var tex := DeskCatalog.texture("desk.dq.room_backplate")
	if tex == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color.WHITE
	## Unshaded plate: painted night already carries candle falloff.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	room.material_override = mat
	room.name = "RoomBackplate"


static func apply_desk_pbr(desk: MeshInstance3D) -> void:
	if desk == null:
		return
	var albedo := DeskCatalog.texture("desk.dq.desk_albedo")
	if albedo == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.albedo_color = Color.WHITE
	mat.roughness = 1.0
	var normal := DeskCatalog.texture("desk.dq.desk_normal")
	if normal != null:
		mat.normal_enabled = true
		mat.normal_texture = normal
		mat.normal_scale = 0.85
	var rough := DeskCatalog.texture("desk.dq.desk_roughness")
	if rough != null:
		mat.roughness_texture = rough
	mat.uv1_scale = Vector3(1.35, 1.0, 1.0)
	mat.texture_repeat = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	desk.material_override = mat


static func apply_cover_leather(cover: MeshInstance3D) -> void:
	if cover == null:
		return
	var albedo := DeskCatalog.texture("desk.dq.cover_albedo")
	if albedo == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.albedo_color = Color.WHITE
	mat.roughness = 0.78
	mat.metallic = 0.06
	var normal := DeskCatalog.texture("desk.dq.cover_normal")
	if normal != null:
		mat.normal_enabled = true
		mat.normal_texture = normal
		mat.normal_scale = 0.7
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	cover.material_override = mat


static func add_fore_edge_slabs(book_root: Node3D) -> void:
	if book_root == null:
		return
	var tex := DeskCatalog.texture("desk.dq.fore_edge")
	if tex == null:
		return
	for side in [-1, 1]:
		var slab := MeshInstance3D.new()
		slab.name = "ForeEdge%s" % ("L" if side < 0 else "R")
		var box := BoxMesh.new()
		box.size = Vector3(0.68, 0.074, 0.005)
		slab.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.albedo_color = Color(0.92, 0.88, 0.78)
		mat.roughness = 0.96
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		slab.material_override = mat
		slab.position = Vector3(side * 0.36, -0.042, 0.475)
		book_root.add_child(slab)


static func attach_bookmark_ribbon(book_root: Node3D) -> void:
	## DQ-05 art lies flat from the gutter; the interactive「合上」lives in chrome.
	## ADR-0034 D2: one visible ribbon node — no hidden procedural/BookmarkProp twins.
	if book_root == null:
		return
	var tex := DeskCatalog.texture("desk.dq.ribbon_bookmark")
	if tex == null:
		var fallback := MeshInstance3D.new()
		fallback.name = "BookmarkRibbon"
		var ribbon_mesh := BoxMesh.new()
		ribbon_mesh.size = Vector3(0.05, 0.004, 0.30)
		fallback.mesh = ribbon_mesh
		var ribbon_mat := StandardMaterial3D.new()
		ribbon_mat.albedo_color = Color(0.42, 0.09, 0.08)
		ribbon_mat.roughness = 0.6
		fallback.material_override = ribbon_mat
		fallback.position = Vector3(-0.03, -0.088, 0.56)
		fallback.rotation_degrees = Vector3(0.0, 4.0, 0.0)
		book_root.add_child(fallback)
		return
	var shadow_tex := DeskCatalog.texture("desk.dq.ribbon_bookmark.shadow")
	if shadow_tex != null:
		var shadow := _flat_sprite("RibbonBookmarkShadow", shadow_tex, 0.42)
		shadow.position = Vector3(-0.02, -0.086, 0.42)
		shadow.modulate = Color(1, 1, 1, 0.7)
		book_root.add_child(shadow)
	var ribbon := _flat_sprite("RibbonBookmark", tex, 0.42)
	ribbon.position = Vector3(-0.03, -0.085, 0.40)
	ribbon.rotation_degrees = Vector3(-90.0, 6.0, 0.0)
	book_root.add_child(ribbon)


static func add_diary_contact_shadows(desk_world: Node3D, book_root: Node3D) -> void:
	if desk_world == null:
		return
	_add_contact_shadow(
		desk_world,
		"BookContactShadow",
		"desk.dq.contact_shadow.page",
		Vector3(0.04, 0.0015, 0.02),
		1.55
	)
	_add_contact_shadow(
		desk_world,
		"CandleContactShadow",
		"desk.dq.contact_shadow.candle_lit",
		Vector3(-0.86, 0.0015, -0.14),
		0.28
	)
	if book_root != null:
		## Closed-book silhouette under the cover slab for a denser contact.
		_add_contact_shadow(
			book_root,
			"CoverContactShadow",
			"desk.dq.contact_shadow.book_closed",
			Vector3(0.0, -0.092, 0.0),
			1.48
		)


static func _add_contact_shadow(
	parent: Node3D,
	node_name: String,
	asset_id: String,
	pos: Vector3,
	width_m: float
) -> void:
	var tex := DeskCatalog.texture(asset_id)
	if tex == null:
		return
	var sprite := _flat_sprite(node_name, tex, width_m)
	sprite.position = pos
	sprite.modulate = Color(1, 1, 1, 0.88)
	parent.add_child(sprite)


static func _flat_sprite(node_name: String, tex: Texture2D, width_m: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = node_name
	sprite.texture = tex
	sprite.pixel_size = width_m / float(maxi(1, tex.get_width()))
	sprite.axis = Vector3.AXIS_Y
	sprite.centered = true
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.transparent = true
	sprite.double_sided = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	return sprite
