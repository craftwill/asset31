// Tangent-plane 3D starburst super-hubs on Asset 31's Mantle surface (refs 075s, 625s).
// Lies physically on the sphere's tangent plane so every hub naturally foreshortens in
// perspective toward the planetary limb, exactly matching the 3/4/6-spoke star junctions.
// INSTANCE_CUSTOM: r = spoke count (3, 4, or 6), g = angle offset rad, b = intensity, a = soft glow.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec3 core_color : source_color = vec3(1.0, 0.95, 0.82);
uniform vec3 ray_color : source_color = vec3(1.0, 0.80, 0.44);
uniform float global_energy = 1.65;

varying vec4 v_params;

void vertex() {
	v_params = INSTANCE_CUSTOM;
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	if (r > 1.0) {
		discard;
	}

	int spokes = int(round(v_params.r));
	if (spokes < 3) {
		spokes = 6;
	}
	float rot = v_params.g;
	float intensity = max(v_params.b, 0.3);
	float halo_k = max(v_params.a, 0.3);

	// Accumulate sharp, spindly tapered arterial starburst spikes in the hub's tangent plane.
	float rays = 0.0;
	if (spokes == 3) {
		// 3-way Y-junction (like V_ul and V_ll on the left arc).
		for (int i = 0; i < 3; i++) {
			float a = rot + float(i) * 2.0943951;
			vec2 d = vec2(cos(a), sin(a));
			float along = dot(q, d);
			if (along > -0.03) {
				float perp = abs(dot(q, vec2(-d.y, d.x)));
				float t = clamp(along / 0.90, 0.0, 1.0);
				float w = mix(0.038, 0.008, t);
				float taper = pow(max(1.0 - t, 0.0), 1.25) * smoothstep(-0.02, 0.03, along);
				rays = max(rays, exp(-(perp * perp) / (w * w)) * taper);
			}
		}
	} else if (spokes == 4) {
		// 4-way X-junction (pinched X angle like V_tl and V_botl).
		float angles[4] = float[4](0.50, 2.64, -0.50, -2.64);
		for (int i = 0; i < 4; i++) {
			float a = rot + angles[i];
			vec2 d = vec2(cos(a), sin(a));
			float along = dot(q, d);
			if (along > -0.03) {
				float perp = abs(dot(q, vec2(-d.y, d.x)));
				float t = clamp(along / 0.94, 0.0, 1.0);
				float w = mix(0.038, 0.008, t);
				float taper = pow(max(1.0 - t, 0.0), 1.20) * smoothstep(-0.02, 0.03, along);
				rays = max(rays, exp(-(perp * perp) / (w * w)) * taper);
			}
		}
	} else {
		// 6-spoke major super-hub star (like V_center, V_right, V_ur, V_dr).
		for (int i = 0; i < 6; i++) {
			float a = rot + float(i) * 1.04719755;
			vec2 d = vec2(cos(a), sin(a));
			float along = dot(q, d);
			if (along > -0.03) {
				float perp = abs(dot(q, vec2(-d.y, d.x)));
				float max_l = (i % 2 == 0) ? 0.98 : 0.80;
				float t = clamp(along / max_l, 0.0, 1.0);
				float w = mix(0.036, 0.007, t);
				float taper = pow(max(1.0 - t, 0.0), 1.18) * smoothstep(-0.02, 0.03, along);
				rays = max(rays, exp(-(perp * perp) / (w * w)) * taper);
			}
		}
	}

	float r2 = r * r;
	float core = exp(-r2 * 110.0);
	float halo = exp(-r2 * 8.0) * (1.0 - smoothstep(0.55, 1.0, r)) * 0.22 * halo_k;

	vec3 col = core_color * (core * 0.95 + rays * 0.95) + ray_color * (rays * 0.65 + halo);
	ALBEDO = col * global_energy * intensity;
}
