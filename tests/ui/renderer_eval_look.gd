extends RefCounted

## ADR-0035 "best-effort tuned" look for the diary desk, applied at runtime on
## top of the nodes DiaryDeskStage builds. Evaluation only: UI-P0-3 ports the
## chosen values into src/ui/diary_desk_stage.gd. Features a renderer does not
## support are set anyway and silently ignored, so one call is a fair
## per-renderer comparison. `opts` keys (all optional) are the A/B knobs the
## capture runner exposes: fog, ssao, soft_high, pcss, glow (bool), msaa (0/2/4),
## exposure (float, <=0 = per-renderer default), tonemap (agx|filmic|aces|linear),
## page_emit (float, default 0), force_srgb (bool).

const TONEMAPS := {
	"linear": Environment.TONE_MAPPER_LINEAR,
	"filmic": Environment.TONE_MAPPER_FILMIC,
	"aces": Environment.TONE_MAPPER_ACES,
	"agx": Environment.TONE_MAPPER_AGX,
}


static func apply(desk_world: Node3D, method: String, opts: Dictionary = {}) -> void:
	var vp := desk_world.get_viewport()
	var forward_plus := method == "forward_plus"
	var compat := method == "gl_compatibility"
	var msaa: int = opts.get("msaa", 4)
	vp.msaa_3d = {0: Viewport.MSAA_DISABLED, 2: Viewport.MSAA_2X}.get(msaa, Viewport.MSAA_4X)
	vp.positional_shadow_atlas_size = 4096
	var q := RenderingServer.SHADOW_QUALITY_SOFT_LOW
	if opts.get("soft_high", false):
		q = RenderingServer.SHADOW_QUALITY_SOFT_HIGH
	RenderingServer.directional_soft_shadow_filter_set_quality(q)
	RenderingServer.positional_soft_shadow_filter_set_quality(q)

	var env: Environment = vp.world_3d.environment
	env.background_color = Color(0.02, 0.012, 0.01)
	## Candle becomes the key: ambient drops so shadows and falloff read.
	env.ambient_light_color = Color(0.55, 0.50, 0.48)
	env.ambient_light_energy = 0.30
	env.tonemap_mode = TONEMAPS.get(opts.get("tonemap", "filmic"), Environment.TONE_MAPPER_FILMIC)
	## The same light lands ~2.5x dimmer under the RD renderers than under
	## gl_compatibility (measured, ADR-0035); exposure makes up the value.
	var exposure: float = opts.get("exposure", 0.0)
	env.tonemap_exposure = exposure if exposure > 0.0 else (1.15 if compat else 3.0)
	env.glow_enabled = opts.get("glow", true)
	env.glow_intensity = 0.7
	env.glow_strength = 1.0
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT if compat else Environment.GLOW_BLEND_MODE_SCREEN
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 0.95
	if forward_plus and opts.get("ssao", true):
		env.ssao_enabled = true
		env.ssao_radius = 0.12
		env.ssao_intensity = 2.2
		env.ssao_power = 1.6
		env.ssao_detail = 0.6
		env.ssao_light_affect = 0.15
	if forward_plus and opts.get("fog", true):
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.01
		env.volumetric_fog_albedo = Color(0.9, 0.82, 0.72)
		env.volumetric_fog_anisotropy = 0.45
		env.volumetric_fog_length = 3.0
		env.volumetric_fog_ambient_inject = 0.0

	## Paper is matte (GGX specular lifts ink toward paper under RD).
	## page_emit (self-lit page) and force_srgb are rejected probes kept for
	## A/B: both destroy ink contrast under RD (ADR-0035 §4).
	var page_emit: float = opts.get("page_emit", 0.0)
	for mi in desk_world.find_children("*", "MeshInstance3D", true, false):
		var page_mat := (mi as MeshInstance3D).material_override as StandardMaterial3D
		if page_mat == null or not (page_mat.albedo_texture is ViewportTexture):
			continue
		page_mat.set_flag(BaseMaterial3D.FLAG_ALBEDO_TEXTURE_FORCE_SRGB, opts.get("force_srgb", false))
		page_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		page_mat.metallic_specular = 0.0
		if page_emit > 0.0:
			page_mat.emission_enabled = true
			page_mat.emission = Color(1.0, 0.92, 0.80)
			page_mat.emission_texture = page_mat.albedo_texture
			page_mat.emission_energy_multiplier = page_emit

	var pcss: bool = opts.get("pcss", true)
	var key := desk_world.get_node_or_null("KeyLight") as DirectionalLight3D
	if key != null:
		## Cool window spill from the back-right; soft contact shadows.
		key.light_color = Color(0.72, 0.80, 1.0)
		key.light_energy = 0.30
		key.light_angular_distance = 2.0 if pcss else 0.0
		key.shadow_blur = 1.6
		key.shadow_opacity = 1.0
		key.light_volumetric_fog_energy = 0.0
	for fill_name in ["FillLight", "FillLightRight"]:
		var fill := desk_world.get_node_or_null(fill_name) as OmniLight3D
		if fill != null:
			fill.light_energy *= 0.6
			fill.light_volumetric_fog_energy = 0.0
	var candle := desk_world.get_node_or_null("CandleFlame") as OmniLight3D
	if candle != null:
		candle.light_color = Color(1.0, 0.68, 0.38)
		candle.light_energy = 1.0
		candle.omni_range = 2.8
		candle.omni_attenuation = 1.6
		candle.light_size = 0.05 if pcss else 0.0
		candle.shadow_enabled = true
		candle.shadow_blur = 1.4
		candle.shadow_opacity = 0.85
		candle.light_volumetric_fog_energy = 3.0
		## The painted candle must not be lit (and blown out) by its own flame.
		var prop := desk_world.get_node_or_null("CandleProp") as VisualInstance3D
		if prop != null:
			prop.layers = 2
			candle.light_cull_mask = 0xFFFFF & ~2
		## HDR flame core: the only thing above the glow threshold.
		var core := MeshInstance3D.new()
		core.name = "EvalFlameCore"
		var sphere := SphereMesh.new()
		sphere.radius = 0.007
		sphere.height = 0.022
		core.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.BLACK
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.35)
		mat.emission_energy_multiplier = 6.0
		core.material_override = mat
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		core.position = candle.position + Vector3(0.0, 0.025, 0.02)
		desk_world.add_child(core)
