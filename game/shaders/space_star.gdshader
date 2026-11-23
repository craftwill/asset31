// Crisp, anti-flicker pinpoint stars and planetary surface micro-lights (refs 075s, 625s).
// Expands quads to an energy-conserved minimum screen pixel size so stars never strobe
// or vanish during camera rotation, while remaining depth-tested against the planet sphere.
// INSTANCE_CUSTOM: r = brightness, g = warm_tint (0 cool-white .. 1 warm-gold), b = px_size.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform float global_energy = 1.0;
uniform float softness = 4.6;

varying vec3 v_col;

void vertex() {
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float dist = max(-c.z, 0.1);
	float proj_y = max(abs(PROJECTION_MATRIX[1][1]), 0.001);
	float px_world = (2.0 * dist) / (proj_y * max(VIEWPORT_SIZE.y, 1.0));

	float px_diam = max(INSTANCE_CUSTOM.b, 1.4);
	float world_sz = max(length(MODEL_MATRIX[0].xyz), px_world * px_diam);

	// Slight pull toward camera so surface micro-lights never clip into the planet sphere.
	c.xyz *= max(0.0, dist - 0.04) / dist;
	c.xy += VERTEX.xy * world_sz;
	POSITION = PROJECTION_MATRIX * c;

	vec3 cool_w = vec3(0.86, 0.90, 1.0);
	vec3 warm_w = vec3(1.0, 0.87, 0.64);
	v_col = mix(cool_w, warm_w, clamp(INSTANCE_CUSTOM.g, 0.0, 1.0)) * INSTANCE_CUSTOM.r * global_energy;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r2 = dot(p, p);
	if (r2 > 1.0) {
		discard;
	}
	float a = exp(-r2 * softness) * (1.0 - smoothstep(0.75, 1.0, r2));
	ALBEDO = v_col * a;
}
