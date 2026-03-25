shader_type canvas_item;
// Full-screen film grain post-process overlay.
// Place on a ColorRect (white, full-rect) inside a CanvasLayer.
// The ColorRect must have its color set to white with full alpha.

uniform float grain_intensity: hint_range(0.0, 0.15, 0.005) = 0.04;
uniform float grain_speed: hint_range(0.5, 5.0, 0.1) = 2.0;

float rand(vec2 co, float t) {
	return fract(sin(dot(co + vec2(t, t), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float noise = rand(SCREEN_UV, TIME * grain_speed) * 2.0 - 1.0;
	// Output noise as additive luminance — transparent base so it blends over the scene
	COLOR = vec4(vec3(noise * grain_intensity + 0.5), grain_intensity * abs(noise));
}
