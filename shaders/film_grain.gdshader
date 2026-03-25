shader_type canvas_item;
// Full-screen film grain post-process overlay.
// Place on a ColorRect (white, full-rect, full alpha) inside a CanvasLayer.
// Reads the screen, applies grain, outputs the result.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float grain_intensity : hint_range(0.0, 0.15, 0.005) = 0.05;
uniform float grain_speed : hint_range(0.5, 5.0, 0.1) = 2.0;

float rand(vec2 co, float t) {
	return fract(sin(dot(co + vec2(t, t), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	float noise = rand(SCREEN_UV * 500.0, TIME * grain_speed) * 2.0 - 1.0;
	screen += vec3(noise * grain_intensity);
	COLOR = vec4(screen, 1.0);
}
