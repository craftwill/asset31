// Camera-facing additive light glow ("corona") for practical lights, in the
// spirit of late-90s light flares. Fades by distance instead of fogging.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 color : source_color = vec3(1.0, 0.62, 0.30);
uniform float energy = 0.9;
uniform float fade_near = 0.5;
uniform float fade_start = 120.0;
uniform float fade_end = 900.0;
// Optional dimming when close (a far-off light that is nothing much once you reach it).
uniform float near_dim = 1.0;
uniform float near_dim_start = 0.0;
uniform float near_dim_end = 0.0;

varying float v_fade;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float d = length(c.xyz);
	// Pull toward the camera so the glow is not cut by its own lamp.
	c.xyz *= max(0.0, d - 0.6) / max(d, 0.001);
	c.xy += VERTEX.xy * sc.x;
	POSITION = retro_snap(PROJECTION_MATRIX * c);
	v_fade = (1.0 - smoothstep(fade_start, fade_end, d)) * smoothstep(0.0, fade_near, d);
	if (near_dim_end > near_dim_start) {
		v_fade *= mix(near_dim, 1.0, smoothstep(near_dim_start, near_dim_end, d));
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r2 = dot(p, p);
	float a = exp(-r2 * 5.0) * (1.0 - smoothstep(0.7, 1.0, r2));
	ALBEDO = color * energy * a * v_fade;
}
