shader_type spatial;
// Legacy single-slot surface shader. Assign to a mesh and set `palette_slot`
// to an int to pick one palette color for the whole surface.
//
// For voxel meshes with multiple palette roles, use voxel_palette.gdshader
// instead.
//
// palette_slot mapping:
//   Grayscale (permanent):           Good:
//     0 = gs_light                     4 = good
//     1 = gs_mid_light                 5 = good_muted
//     2 = gs_mid_dark                Bad:
//     3 = gs_dark                      6 = bad
//                                      7 = bad_muted
//   Accent:                          Filler:
//     8 = accent                      10 = filler
//     9 = accent_muted                11 = filler_muted

render_mode unshaded;

global uniform vec4 palette_gs_light;
global uniform vec4 palette_gs_mid_light;
global uniform vec4 palette_gs_mid_dark;
global uniform vec4 palette_gs_dark;
global uniform vec4 palette_good;
global uniform vec4 palette_good_muted;
global uniform vec4 palette_bad;
global uniform vec4 palette_bad_muted;
global uniform vec4 palette_accent;
global uniform vec4 palette_accent_muted;
global uniform vec4 palette_filler;
global uniform vec4 palette_filler_muted;

uniform int palette_slot: hint_range(0, 11, 1) = 0;
uniform sampler2D albedo_texture: hint_default_white;
uniform sampler2D normal_texture: hint_normal;
uniform bool use_texture = false;
uniform float texture_blend: hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 col;
	switch (palette_slot) {
		case 0:  col = palette_gs_light; break;
		case 1:  col = palette_gs_mid_light; break;
		case 2:  col = palette_gs_mid_dark; break;
		case 3:  col = palette_gs_dark; break;
		case 4:  col = palette_good; break;
		case 5:  col = palette_good_muted; break;
		case 6:  col = palette_bad; break;
		case 7:  col = palette_bad_muted; break;
		case 8:  col = palette_accent; break;
		case 9:  col = palette_accent_muted; break;
		case 10: col = palette_filler; break;
		case 11: col = palette_filler_muted; break;
		default: col = vec4(1.0, 0.0, 1.0, 1.0); break;
	}
	if (use_texture) {
		vec3 tex_col = texture(albedo_texture, UV).rgb;
		ALBEDO = mix(col.rgb, tex_col * col.rgb, texture_blend);
		NORMAL_MAP = texture(normal_texture, UV).rgb;
	} else {
		ALBEDO = col.rgb;
	}
}
