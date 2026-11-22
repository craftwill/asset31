// Grimy window glass: clear enough to read city lights outside without milky glare.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_schlick_ggx;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 color : source_color = vec3(0.08, 0.07, 0.06);
uniform float alpha_val = 0.03;

void vertex() {
	POSITION = retro_snap(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	ALBEDO = color;
	ROUGHNESS = 0.38;
	SPECULAR = 0.14;
	ALPHA = alpha_val;
}
