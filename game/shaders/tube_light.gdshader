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
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = retro_snap_stable(clip, sc);
}

void fragment() {
	float g = v_y / ring_spacing;
	float aa = max(fwidth(g), 1e-4);
	float f = fract(g);
	// Analytical anti-aliased collar ring so rings do not crawl in motion.
	float ring = smoothstep(0.07 + aa, max(0.07 - aa, 0.0), f) + smoothstep(1.0 - aa, 1.0, f);
	ring = clamp(ring, 0.0, 1.0) * (1.0 - smoothstep(0.35, 0.7, aa));
	float band_aa = max(aa * 4.0, 1e-4);
	float bf = fract(g * 4.0);
	float band = mix(smoothstep(0.5 - band_aa, 0.5 + band_aa, bf), 0.5, smoothstep(0.25, 0.6, band_aa));
	vec3 glow = color * energy * mix(0.85, 1.0, band);
	ALBEDO = mix(glow, ring_color, ring);
}
