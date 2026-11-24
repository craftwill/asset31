// The haze floor far below the stacks, seen wherever you look down into a gap
// (reference 612s-620s): a brown glowing murk scattered with countless small lights.
// Self-lit and unfogged; it fades to the haze colour toward the horizon by itself.
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;

#include "res://shaders/retro_common.gdshaderinc"

uniform vec3 haze : source_color = vec3(0.115, 0.062, 0.030);
uniform vec3 light_a : source_color = vec3(1.0, 0.86, 0.62);
uniform vec3 light_b : source_color = vec3(1.0, 0.62, 0.30);
uniform float energy = 1.6;
// Lit shaft that passes through the floor (x, z, radius): nothing is drawn inside it.
uniform vec3 hole = vec3(0.0, 0.0, 0.0);

varying vec3 v_lpos;
varying float v_dist;

void vertex() {
	vec3 rpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_lpos = rpos + world_origin;
	v_dist = length(rpos - INV_VIEW_MATRIX[3].xyz);
}

// One layer of point lights on a jittered grid, energy-conserving below 1 px.
vec3 lights(vec2 p, float cell, float radius, float density, float px, float seed) {
	vec2 g = p / cell;
	vec2 id = floor(g);
	vec2 jit = vec2(hash12(id + seed), hash12(id.yx + seed + 7.1)) * 0.7 + 0.15;
	float d = length((fract(g) - jit) * cell);
	// Districts: dense patches and dark ones.
	float macro = hash12(floor(id * cell / 900.0) + seed * 3.0);
	float on = step(hash12(id + seed + 3.3), density * mix(0.25, 1.5, macro));
	float r_eff = max(radius, px * 0.75);
	float k = (radius * radius) / (r_eff * r_eff);
	float spot = 1.0 - smoothstep(r_eff - px * 0.5, r_eff + px * 0.5, d);
	vec3 col = mix(light_a, light_b, hash12(id + seed + 9.7));
	float inten = mix(0.5, 1.4, hash12(id + seed + 5.5));
	vec3 near_e = col * spot * on * inten * k;
	// When the grid is finer than the pixels, resolve to its average glow.
	float area = 3.14159 * radius * radius / (cell * cell);
	vec3 avg_e = mix(light_a, light_b, 0.5) * density * 0.9 * area;
	return mix(near_e, avg_e, smoothstep(3.0, 1.2, cell / px));
}

void fragment() {
	vec2 p = v_lpos.xz;
	if (hole.z > 0.0 && distance(p, hole.xy) < hole.z) {
		discard;
	}
	float px = max(length(fwidth(p)), 1e-3);
	// Slow uneven murk.
	float murk = mix(0.75, 1.25, hash12(floor(p / 1400.0)));
	vec3 col = haze * murk;
	vec3 e = lights(p, 150.0, 9.0, 0.55, px, 11.0) + lights(p, 57.0, 5.0, 0.35, px, 29.0);
	col += e * energy;
	// The lights drown in the haze with distance; the haze itself carries to the horizon.
	float far = 1.0 - exp(-v_dist * 0.00009);
	ALBEDO = mix(col, haze * 1.15, far * 0.85);
}
