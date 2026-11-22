// Overhead tube lights of the market street (frame 550s): glowing cylinder
// with darker collar rings. Cylinder axis = local Y.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 color : source_color = vec3(1.0, 0.84, 0.62);
uniform float energy = 1.4;
uniform float ring_spacing = 6.0;
uniform vec3 ring_color : source_color = vec3(0.16, 0.12, 0.09);

varying float v_y;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_y = VERTEX.y * sc.y;
	POSITION = retro_snap(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	float f = fract(v_y / ring_spacing);
	float ring = step(f, 0.07);
	vec3 glow = color * energy * mix(0.85, 1.0, step(0.5, fract(v_y / ring_spacing * 4.0)));
	ALBEDO = mix(glow, ring_color, ring);
}
