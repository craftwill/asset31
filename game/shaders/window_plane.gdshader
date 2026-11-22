// Reusable standalone window-plane shader using the procedural interior-mapping
// module. Designed for hero/authored window planes and the interior-mapping test
// scene; supports per-instance variation via INSTANCE_CUSTOM (x = seed, y = zone,
// z = category override [-1 auto, 0..6 forced], w = curtain override [-1 auto, 0..1]).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

#include "res://shaders/retro_common.gdshaderinc"
#include "res://shaders/window_interior.gdshaderinc"

uniform vec3 frame_color : source_color = vec3(0.07, 0.055, 0.045);
uniform vec3 glass_tint : source_color = vec3(0.03, 0.028, 0.027);
uniform vec3 window_color : source_color = vec3(1.0, 0.70, 0.38);
uniform vec3 window_color_alt : source_color = vec3(0.55, 0.80, 0.95);
uniform float window_energy = 1.8;
uniform float lit_fraction : hint_range(0.0, 1.0) = 0.65;
uniform float alt_fraction : hint_range(0.0, 1.0) = 0.08;
uniform vec2 bay_size = vec2(4.0, 3.5);
uniform vec2 frame_border = vec2(0.08, 0.08);

varying vec3 v_nrm;
varying vec3 v_ray;
varying flat vec4 v_inst;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, vec4(0.0));
	v_nrm = NORMAL;
	vec3 rpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 ray_r = rpos - INV_VIEW_MATRIX[3].xyz;
	vec3 ax = normalize(MODEL_MATRIX[0].xyz);
	vec3 ay = normalize(MODEL_MATRIX[1].xyz);
	vec3 az = normalize(MODEL_MATRIX[2].xyz);
	v_ray = vec3(dot(ray_r, ax), dot(ray_r, ay), dot(ray_r, az));
	v_inst = INSTANCE_CUSTOM;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = retro_snap_stable(clip, sc);
}

void fragment() {
	vec2 q_uv = vec2(1.0 - UV.x, 1.0 - UV.y);
	vec2 fw = max(fwidth(q_uv), vec2(1e-4));
	float fw_max = max(fw.x, fw.y);
	float detail_k = 1.0 - smoothstep(0.04, 0.14, fw_max);
	vec2 in_frame = step(frame_border, q_uv) * step(q_uv, vec2(1.0) - frame_border);
	float is_glass = in_frame.x * in_frame.y;

	// Map glass UV [frame_border .. 1-frame_border] to bay-local f in [0.25 .. 0.75].
	vec2 g01 = clamp((q_uv - frame_border) / max(vec2(1.0) - 2.0 * frame_border, vec2(1e-4)), vec2(0.0), vec2(1.0));
	vec2 hw = vec2(0.25, 0.25);
	vec2 f = vec2(0.5) + (g01 - vec2(0.5)) * (hw * 2.0);

	float seed = floor(v_inst.x * 512.0 + 0.5);
	float zone = floor(v_inst.y + 0.001);
	float cat_ov = v_inst.z - 1.0; // pass 0 for auto, 1..7 for category 0..6
	float curt_ov = v_inst.w - 1.0; // pass 0 for auto, 1..2 for curtain 0..1

	vec2 sid = vec2(seed, seed * 0.37 + 5.0);
	float h = hash12(sid);
	float h2 = hash12(sid.yx + 19.7);
	float lit = (cat_ov >= 0.0) ? (cat_ov < 5.5 ? 1.0 : 0.0) : step(h, lit_fraction);
	float alt = (cat_ov >= 0.0) ? step(0.85, h2) : (step(1.0 - alt_fraction, h2) * (1.0 - lit));
	float flick = 0.55 + 0.5 * hash12(sid + 3.1);
	vec3 col = mix(window_color, window_color_alt, alt);

	vec3 interior = mantle_window_interior(
		f, hw, bay_size, normalize(v_nrm), normalize(v_ray),
		sid, zone, col, max(lit, alt), flick, window_energy,
		detail_k, cat_ov, curt_ov);

	ALBEDO = mix(frame_color, glass_tint, is_glass);
	ROUGHNESS = mix(0.92, 0.22, is_glass);
	SPECULAR = mix(0.15, 0.55, is_glass);
	EMISSION = interior * is_glass;
}
