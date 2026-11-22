// Molten steel: animated hot emissive (foundry, frame 025s). Uses object space.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 hot : source_color = vec3(1.0, 0.85, 0.45);
uniform vec3 warm : source_color = vec3(1.0, 0.38, 0.06);
uniform float energy = 4.0;
uniform float flow = 3.0;

varying vec3 v_pos;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_pos = VERTEX * sc;
	POSITION = retro_snap(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	vec2 p = vec2(v_pos.x + v_pos.z, v_pos.y + TIME * flow);
	float n = hash12(floor(p * 3.0));
	float n2 = hash12(floor(p * 1.0) + 7.0);
	float t = clamp(n * 0.6 + n2 * 0.5, 0.0, 1.0);
	ALBEDO = mix(warm, hot, t) * energy;
}
