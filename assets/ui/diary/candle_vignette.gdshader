shader_type canvas_item;

// Warm candle vignette for diary immersion (top-left lamp).
uniform vec2 light_uv = vec2(0.16, 0.10);
uniform float intensity : hint_range(0.0, 2.0) = 0.95;
uniform float radius : hint_range(0.2, 2.5) = 0.92;
uniform float flicker : hint_range(0.0, 1.0) = 0.0;
uniform vec4 warm_tint : source_color = vec4(1.0, 0.70, 0.34, 1.0);
uniform vec4 rim_tint : source_color = vec4(0.08, 0.03, 0.01, 1.0);

void fragment() {
	vec2 uv = UV;
	float d = distance(uv, light_uv);
	float r = radius * (1.0 + flicker * 0.10);
	float falloff = 1.0 - smoothstep(0.05, r, d);
	float rim = smoothstep(r * 0.55, r * 1.15, d);
	float a = clamp(falloff * intensity * (0.55 + flicker * 0.35), 0.0, 1.0);
	vec3 rgb = mix(rim_tint.rgb, warm_tint.rgb, falloff);
	rgb = mix(rgb, rim_tint.rgb, rim * 0.35);
	COLOR = vec4(rgb, a * COLOR.a);
}
