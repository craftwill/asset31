// Grimy window glass: mostly transparent, slight warm reflection.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 color : source_color = vec3(0.25, 0.22, 0.18);
uniform float alpha_val = 0.07;

void vertex() {
	POSITION = retro_snap(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	ALBEDO = color;
	ROUGHNESS = 0.2;
	SPECULAR = 0.6;
	ALPHA = alpha_val;
}
