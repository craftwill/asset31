// Generic textured box surface for props, structure and interiors: one pixel
// texture projected per face in object space (or logical world space for
// seamless runs), optional emission and grime toward the bottom.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

#include "res://shaders/retro_common.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tex_size = 2.0;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform float use_world = 0.0;
uniform float grime = 0.0;
uniform float roughness_val = 0.85;
uniform float specular_val = 0.25;
uniform float stretch = 0.0; // 1 = fit the texture once across each face (posters, signs)
uniform float no_snap = 0.0;
uniform float fade_start = 0.0;
uniform float fade_end = 0.0;

varying vec3 v_pos;
varying vec3 v_nrm;
varying vec3 v_size;
varying float v_dist;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_size = sc;
	if (use_world > 0.5) {
		v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + world_origin;
		v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	} else {
		v_pos = VERTEX * sc;
		v_nrm = NORMAL;
	}
	vec4 mv = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	v_dist = -mv.z;
	vec4 clip = PROJECTION_MATRIX * mv;
	POSITION = (no_snap > 0.5) ? clip : retro_snap_stable(clip, sc);
}

void fragment() {
	if (fade_end > 0.0 && v_dist > fade_start) {
		float ft = clamp((v_dist - fade_start) / max(fade_end - fade_start, 1.0), 0.0, 1.0);
		if (ft >= retro_bayer(FRAGCOORD.xy)) {
			discard;
		}
	}
	vec2 uv = retro_box_uv(v_pos, v_nrm);
	vec2 tuv;
	if (stretch > 0.5) {
		vec3 a = abs(v_nrm);
		vec2 fs = a.x > 0.5 ? v_size.zy : (a.z > 0.5 ? v_size.xy : v_size.xz);
		tuv = vec2(uv.x / fs.x + 0.5, 0.5 - uv.y / fs.y);
	} else {
		tuv = vec2(uv.x, -uv.y) / tex_size;
	}
	vec3 c = texture(albedo_tex, tuv).rgb * tint;
	if (grime > 0.0) {
		float h = use_world > 0.5 ? 1.0 : (v_pos.y / max(v_size.y, 0.001) + 0.5);
		c *= mix(1.0 - grime, 1.0, clamp(h, 0.0, 1.0));
	}
	ALBEDO = c;
	ROUGHNESS = roughness_val;
	SPECULAR = specular_val;
	EMISSION = emission_color * emission_energy;
}
