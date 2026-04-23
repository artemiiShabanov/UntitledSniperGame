shader_type spatial;
// Voxel recolor shader. Reads per-vertex COLOR baked by MagicaVoxel, matches
// against the 6 canonical source colors from VoxelSourcePalette, and outputs
// the appropriate palette slot.
//
// Source colors (hex):
//   4 grayscale steps:    #E8E8E8, #909090, #505050, #1A1A1A
//   PRIMARY placeholder:  #FF00FF  → rewritten to { good | bad | accent | filler } per mesh_type
//   SECONDARY placeholder:#800080  → rewritten to the `_muted` variant of the same slot
//
// mesh_type (per-instance uniform):
//   0 = GOOD    (friendly warriors, friendly banners)
//   1 = BAD     (enemy warriors, damage flash)
//   2 = ACCENT  (extraction markers, opportunity targets)
//   3 = FILLER  (wood, leather, cloth, skin)

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

// Which semantic role this mesh carries.
// Material-level uniform — PaletteManager.get_voxel_material(type) returns
// one of 4 pre-built ShaderMaterials, each with mesh_type baked in.
uniform int mesh_type: hint_range(0, 3, 1) = 3;  // default: FILLER

const float MATCH_THRESHOLD = 0.05;

// Source color constants (must match VoxelSourcePalette.gd exactly)
const vec3 SRC_GS_LIGHT     = vec3(0.910, 0.910, 0.910);
const vec3 SRC_GS_MID_LIGHT = vec3(0.565, 0.565, 0.565);
const vec3 SRC_GS_MID_DARK  = vec3(0.314, 0.314, 0.314);
const vec3 SRC_GS_DARK      = vec3(0.102, 0.102, 0.102);
const vec3 SRC_PRIMARY      = vec3(1.0, 0.0, 1.0);
const vec3 SRC_SECONDARY    = vec3(0.5, 0.0, 0.5);

void fragment() {
	vec3 src = COLOR.rgb;

	// Resolve PRIMARY and SECONDARY per mesh_type.
	vec3 primary_out;
	vec3 secondary_out;
	switch (mesh_type) {
		case 0:  // GOOD
			primary_out = palette_good.rgb;
			secondary_out = palette_good_muted.rgb;
			break;
		case 1:  // BAD
			primary_out = palette_bad.rgb;
			secondary_out = palette_bad_muted.rgb;
			break;
		case 2:  // ACCENT
			primary_out = palette_accent.rgb;
			secondary_out = palette_accent_muted.rgb;
			break;
		default: // FILLER
			primary_out = palette_filler.rgb;
			secondary_out = palette_filler_muted.rgb;
			break;
	}

	// Match vertex color to one of the 6 source colors.
	vec3 out_color;
	if      (distance(src, SRC_GS_LIGHT)     < MATCH_THRESHOLD) out_color = palette_gs_light.rgb;
	else if (distance(src, SRC_GS_MID_LIGHT) < MATCH_THRESHOLD) out_color = palette_gs_mid_light.rgb;
	else if (distance(src, SRC_GS_MID_DARK)  < MATCH_THRESHOLD) out_color = palette_gs_mid_dark.rgb;
	else if (distance(src, SRC_GS_DARK)      < MATCH_THRESHOLD) out_color = palette_gs_dark.rgb;
	else if (distance(src, SRC_PRIMARY)      < MATCH_THRESHOLD) out_color = primary_out;
	else if (distance(src, SRC_SECONDARY)    < MATCH_THRESHOLD) out_color = secondary_out;
	else                                                        out_color = vec3(1.0, 0.0, 1.0);  // magenta = unapproved source color

	ALBEDO = out_color;
}
