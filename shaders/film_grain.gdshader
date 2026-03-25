shader_type canvas_item;
// Lightweight film grain post-process effect.
// Attach to a full-screen ColorRect placed on a CanvasLayer.

uniform float grain_intensity: hint_range(0.0, 0.15, 0.005) = 0.04;
uniform float grain_speed: hint_range(0.5, 5.0, 0.1) = 2.0;

// Simple pseudo-random hash
float rand(vec2 co, float t) {
	return fract(sin(dot(co + vec2(t, t), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float noise = rand(SCREEN_UV, TIME * grain_speed) * 2.0 - 1.0;
	vec4 screen_color = texture(TEXTURE, UV);
	screen_color.rgb += vec3(noise * grain_intensity);
	COLOR = screen_color;
}
