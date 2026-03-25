shader_type spatial;
// Base surface shader that reads color from a palette slot.
// Assign this material to any mesh, then set the `palette_slot` uniform
// to choose which palette color drives the albedo.
//
// palette_slot mapping:
//   0 = bg_light       3 = accent_hostile    6 = danger
//   1 = bg_mid         4 = accent_loot       7 = reward
//   2 = fg_dark        5 = accent_friendly

render_mode unshaded;

global uniform vec4 palette_bg_light;
global uniform vec4 palette_bg_mid;
global uniform vec4 palette_fg_dark;
global uniform vec4 palette_accent_hostile;
global uniform vec4 palette_accent_loot;
global uniform vec4 palette_accent_friendly;
global uniform vec4 palette_danger;
global uniform vec4 palette_reward;

uniform int palette_slot: hint_range(0, 7, 1) = 0;

void fragment() {
	vec4 col;
	switch (palette_slot) {
		case 0: col = palette_bg_light; break;
		case 1: col = palette_bg_mid; break;
		case 2: col = palette_fg_dark; break;
		case 3: col = palette_accent_hostile; break;
		case 4: col = palette_accent_loot; break;
		case 5: col = palette_accent_friendly; break;
		case 6: col = palette_danger; break;
		case 7: col = palette_reward; break;
		default: col = vec4(1.0, 0.0, 1.0, 1.0); break; // magenta = error
	}
	ALBEDO = col.rgb;
}
