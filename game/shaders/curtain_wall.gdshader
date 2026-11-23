// Monumental translucent misty glass & silver-gray mullion curtain wall (ref 400s).
// Analytical anti-aliased light-gray structural grid over clear frosted mist glazing
// so real 3D pale-concrete megatowers and lush green base ledges behind the glass
// remain unmistakably visible with crisp architectural depth and zero shimmer.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_schlick_ggx;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 glass_tint : source_color = vec3(0.76, 0.80, 0.77);
uniform vec3 frame_color : source_color = vec3(0.72, 0.75, 0.72);
uniform vec2 cell_size = vec2(6.5, 4.5);
uniform vec2 mega_size = vec2(39.0, 27.0);
uniform float glass_alpha : hint_range(0.0, 1.0) = 0.14;
uniform float no_snap = 1.0;

varying vec3 v_world;
varying vec3 v_nrm;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_world = VERTEX * sc;
	v_nrm = NORMAL;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = no_snap > 0.5 ? clip : retro_snap(clip);
}

float grid_line(float coord, float step_m, float half_w) {
	float fw = max(fwidth(coord), 0.02);
	float u = abs(fract(coord / step_m + 0.5) - 0.5) * step_m;
	return 1.0 - smoothstep(half_w - fw, half_w + fw, u);
}

void fragment() {
	vec3 n = abs(v_nrm);
	float u_m = n.x > 0.5 ? v_world.z : v_world.x;
	float v_m = v_world.y;

	// Crisp fine architectural silver-gray glazing mullions + primary structural rails.
	float sub_v = grid_line(u_m, cell_size.x, 0.14);
	float sub_h = grid_line(v_m, cell_size.y, 0.12);
	float sub_grid = max(sub_v, sub_h);

	float meg_v = grid_line(u_m, mega_size.x, 0.34);
	float meg_h = grid_line(v_m, mega_size.y, 0.32);
	float mega_grid = max(meg_v, meg_h);

	float frame_mask = clamp(max(mega_grid, sub_grid * 0.82), 0.0, 1.0);

	float height_mist = clamp((v_m + 180.0) / 520.0, 0.0, 1.0);
	float ndv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, 2.6);

	vec3 col = mix(glass_tint, frame_color, frame_mask);

	ALBEDO = col;
	EMISSION = mix(glass_tint * (0.10 + 0.12 * height_mist + 0.18 * fresnel), frame_color * 0.24, frame_mask);
	ROUGHNESS = mix(0.24, 0.72, frame_mask);
	SPECULAR = mix(0.40, 0.16, frame_mask);

	float pane_a = clamp(glass_alpha + 0.10 * height_mist + 0.16 * fresnel, 0.12, 0.42);
	ALPHA = mix(pane_a, 0.88, frame_mask);
}
