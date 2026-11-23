shader_type canvas_item;
render_mode unshaded, blend_mix;

// Diary-screen post: warm grade + film grain + soft edge crush.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float time = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.55;
uniform float grain_amount : hint_range(0.0, 1.0) = 0.08;
uniform float vignette : hint_range(0.0, 1.5) = 0.55;
uniform float warm : hint_range(0.0, 1.0) = 0.35;
uniform float flicker : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 src = texture(screen_texture, uv);
	float i = clamp(intensity, 0.0, 1.0);
	// Warm grade: lift reds, soft crush blues.
	vec3 graded = src.rgb;
	graded.r = mix(graded.r, graded.r * 1.06 + 0.02, warm * i);
	graded.g = mix(graded.g, graded.g * 0.98, warm * i * 0.6);
	graded.b = mix(graded.b, graded.b * 0.90, warm * i);
	// Soft vignette from screen center.
	float d = distance(uv, vec2(0.5, 0.48));
	float vig = smoothstep(0.35, 0.95, d) * vignette * i;
	graded *= 1.0 - vig * (0.55 + flicker * 0.15);
	// Film grain (stable-ish per pixel + time).
	float g = hash21(uv * vec2(1600.0, 900.0) + vec2(time * 11.0, time * 7.0));
	graded += (g - 0.5) * grain_amount * i * (0.85 + flicker * 0.4);
	COLOR = vec4(graded, src.a * COLOR.a);
}
