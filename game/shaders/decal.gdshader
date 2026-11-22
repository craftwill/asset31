// Alpha-cutout surface (tally marks scratched on walls). Stretched once per face.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

#include "res://shaders/retro_common.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_disable;
uniform vec3 tint : source_color = vec3(1.0);

varying vec3 v_pos;
varying vec3 v_nrm;
varying vec3 v_size;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_size = sc;
	v_pos = VERTEX * sc;
	v_nrm = NORMAL;
	POSITION = retro_snap(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

void fragment() {
	vec2 uv = retro_box_uv(v_pos, v_nrm);
	vec3 a = abs(v_nrm);
	vec2 fs = a.x > 0.5 ? v_size.zy : (a.z > 0.5 ? v_size.xy : v_size.xz);
	vec4 t = texture(albedo_tex, vec2(uv.x / fs.x + 0.5, 0.5 - uv.y / fs.y));
	ALBEDO = t.rgb * tint;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
