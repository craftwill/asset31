// Self-lit practical light heads (lamps, beacons, glowing handrails). Fog still applies.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 color : source_color = vec3(1.0, 0.66, 0.34);
uniform float energy = 4.0;
uniform float no_snap = 0.0;
uniform float min_px_y = 0.0;

varying float v_energy_scale;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	vec3 v = VERTEX;
	v_energy_scale = 1.0;
	if (min_px_y > 0.0) {
		vec4 mv_c = MODELVIEW_MATRIX * vec4(v.x, 0.0, v.z, 1.0);
		vec4 clip_c = PROJECTION_MATRIX * mv_c;
		if (clip_c.w > 1.0) {
			float px_h = (sc.y * abs(PROJECTION_MATRIX[1][1]) / clip_c.w) * 270.0;
			if (px_h < min_px_y) {
				float expand = clamp(min_px_y / max(px_h, 0.01), 1.0, 12.0);
				v.y *= expand;
				v_energy_scale = clamp(px_h / min_px_y, 0.12, 1.0);
			}
		}
	}
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(v, 1.0));
	POSITION = (no_snap > 0.5) ? clip : retro_snap_stable(clip, sc);
}

void fragment() {
	ALBEDO = color * energy * v_energy_scale;
}
