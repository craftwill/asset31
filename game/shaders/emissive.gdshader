// Self-lit practical light heads (lamps, beacons). Fog still applies.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 color : source_color = vec3(1.0, 0.66, 0.34);
uniform float energy = 4.0;

void vertex() {
	POSITION = retro_snap(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	ALBEDO = color * energy;
}
