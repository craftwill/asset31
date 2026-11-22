// Low-poly people (scale references). Vertex colour R encodes the body part
// (0 skin, 0.33 shirt, 0.66 trousers, 1 hat/hair); G encodes the limb that
// swings when walking (0 none, 0.25 left leg, 0.5 right leg, 0.75 left arm,
// 1 right arm). INSTANCE_CUSTOM: x palette seed, y walk phase speed (0 = idle),
// z darkness (silhouettes), w unused.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

#include "res://shaders/retro_common.gdshaderinc"

varying vec3 v_col;

vec3 palette(float part, float seed) {
	if (part < 0.15) {
		return mix(vec3(0.55, 0.36, 0.25), vec3(0.32, 0.2, 0.13), hash12(vec2(seed, 1.0)));
	} else if (part < 0.5) {
		float h = hash12(vec2(seed, 2.0));
		if (h < 0.2) return vec3(0.55, 0.52, 0.45);
		if (h < 0.4) return vec3(0.25, 0.45, 0.42);
		if (h < 0.55) return vec3(0.55, 0.22, 0.18);
		if (h < 0.7) return vec3(0.75, 0.62, 0.35);
		if (h < 0.85) return vec3(0.3, 0.3, 0.38);
		return vec3(0.6, 0.6, 0.62);
	} else if (part < 0.85) {
		float h = hash12(vec2(seed, 3.0));
		return h < 0.5 ? vec3(0.22, 0.2, 0.18) : (h < 0.8 ? vec3(0.36, 0.3, 0.22) : vec3(0.2, 0.22, 0.3));
	}
	float h = hash12(vec2(seed, 4.0));
	return h < 0.35 ? vec3(0.85, 0.65, 0.15) : (h < 0.5 ? vec3(0.8, 0.45, 0.12) : vec3(0.12, 0.09, 0.07));
}

void vertex() {
	float seed = floor(INSTANCE_CUSTOM.x * 512.0 + 0.5);
	float opt = COLOR.b;
	// Optional clothing silhouettes per figure (brimmed hats, long coats, packs).
	if (opt > 0.15) {
		bool keep = false;
		if (opt < 0.5) {
			// Wide hat brim / hard-hat rim (more common on dark foundry workers).
			keep = hash12(vec2(seed, 5.0)) < (INSTANCE_CUSTOM.z > 0.3 ? 0.78 : 0.45);
		} else if (opt < 0.85) {
			// Long industrial coat / cloak skirt (iconic 025s silhouette).
			keep = hash12(vec2(seed, 6.0)) < (INSTANCE_CUSTOM.z > 0.3 ? 0.72 : 0.36);
		} else {
			// Backpack / satchel.
			keep = hash12(vec2(seed, 7.0)) < 0.32;
		}
		if (!keep) {
			VERTEX = vec3(0.0);
		}
	}
	float limb = COLOR.g;
	float speed = INSTANCE_CUSTOM.y;
	if (limb > 0.1 && speed > 0.0) {
		float phase = TIME * speed + INSTANCE_CUSTOM.x * 40.0;
		float s = sin(phase);
		float pivot_y = limb < 0.6 ? 0.9 : 1.42;
		float dir = (limb < 0.3 || (limb > 0.6 && limb < 0.8)) ? 1.0 : -1.0;
		if (limb > 0.6) dir = -dir; // arms counter-swing their leg
		float ang = s * 0.45 * dir;
		vec3 v = VERTEX - vec3(0.0, pivot_y, 0.0);
		float cy = cos(ang);
		float sy = sin(ang);
		v = vec3(v.x, v.y * cy - v.z * sy, v.y * sy + v.z * cy);
		VERTEX = v + vec3(0.0, pivot_y, 0.0);
	}
	v_col = palette(COLOR.r, seed) * (1.0 - INSTANCE_CUSTOM.z);
	POSITION = retro_snap_stable(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)), vec3(1.0));
}

void fragment() {
	ALBEDO = v_col;
	ROUGHNESS = 0.9;
}
