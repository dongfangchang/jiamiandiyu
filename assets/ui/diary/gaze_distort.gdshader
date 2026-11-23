shader_type canvas_item;
render_mode unshaded, blend_mix;

// Screen-space subtle warp driven by attention / pointer focus.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;
uniform vec2 focus_uv = vec2(0.5, 0.5);

void fragment() {
	vec2 uv = SCREEN_UV;
	float near = 1.0 - clamp(distance(uv, focus_uv) * 1.7, 0.0, 1.0);
	float w = strength * (0.25 + near * 0.95);
	vec2 offset = vec2(
		sin(uv.y * 48.0 + time * 3.1) * 0.0038,
		cos(uv.x * 42.0 + time * 2.4) * 0.0028
	) * w;
	vec4 sampled = texture(screen_texture, uv + offset);
	// Soft magenta-brown fringe when gaze is high near focus.
	vec3 fringe = sampled.rgb + vec3(0.04, -0.01, 0.02) * w * near;
	COLOR = vec4(fringe, sampled.a * COLOR.a);
}
