// Walkable floors: pixel stone pavers with grime and wet patches that pick up
// lamp highlights (frame 575s). Texture repeat sizes divide the 500 m ground
// tiles, so the pattern is continuous across tiles. Sides use concrete.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

#include "res://shaders/retro_common.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D side_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D grime_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tex_size = 4.0;
uniform float wet_amount : hint_range(0.0, 1.0) = 0.45;
uniform float wet_scale = 23.0;
uniform float use_world = 0.0;
// Second paving that takes over between two logical z values (disabled while y <= x).
// The change happens plate by plate at a ragged edge, as if relaid piecemeal.
uniform vec2 relay_band = vec2(0.0, 0.0);
uniform vec3 tint_b : source_color = vec3(1.0);
uniform float tex_size_b = 12.5;
uniform float wet_b : hint_range(0.0, 1.0) = 0.3;

varying vec3 v_pos;
varying vec3 v_nrm;
varying vec2 v_logical;

void vertex() {
	v_logical = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz + world_origin.xz;
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	if (use_world > 0.5) {
		v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + world_origin;
	} else {
		v_pos = VERTEX * sc;
	}
	v_nrm = NORMAL;
	// Floors are never vertex-snapped: snapping huge ground quads tilts the
	// whole plane each frame (swimming) and makes thin overlays z-fight.
}

void fragment() {
	if (v_nrm.y > 0.5) {
		vec2 uv = v_pos.xz;
		vec3 c = texture(albedo_tex, uv / tex_size).rgb * tint;
		float wet_k = wet_amount;
		if (relay_band.y > relay_band.x) {
			// One decision per large plate, taken at the plate's own centre.
			vec2 cell = floor(v_logical / tex_size_b);
			float along = smoothstep(relay_band.x, relay_band.y, (cell.y + 0.5) * tex_size_b);
			if (along > hash12(cell + 7.3)) {
				c = texture(albedo_tex, uv / tex_size_b).rgb * tint_b;
				wet_k = wet_b;
			}
		}
		float g = texture(grime_tex, uv / 61.0).r;
		float w = texture(grime_tex, uv / wet_scale + 0.37).r;
		float wet = smoothstep(0.55, 0.62, w) * wet_k;
		c *= mix(0.75, 1.1, g);
		c *= mix(1.0, 0.55, wet);
		ALBEDO = c;
		ROUGHNESS = mix(0.92, 0.18, wet);
		SPECULAR = mix(0.2, 0.6, wet);
	} else {
		vec2 uv = retro_box_uv(v_pos, v_nrm);
		ALBEDO = texture(side_tex, vec2(uv.x, -uv.y) / 4.0).rgb * 0.7;
		ROUGHNESS = 0.95;
		SPECULAR = 0.2;
	}
}
