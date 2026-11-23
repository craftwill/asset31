// Glowing geodesic arterial corridors wrapping Asset 31's Mantle shell (refs 075s, 625s).
// Renders razor-thin, screen-stabilized view-aligned ribbons modulated with procedural
// beaded city-light granulation and two brightness tiers (primary vs secondary corridors).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec3 primary_color : source_color = vec3(1.0, 0.89, 0.66);
uniform vec3 secondary_color : source_color = vec3(0.95, 0.78, 0.50);
uniform float primary_energy = 1.45;
uniform float secondary_energy = 0.52;
uniform float base_half_width = 0.028;
uniform float min_px_half_width = 0.95;

varying vec2 v_arc;      // x = arc length (world units), y = cross coordinate (-1..1)
varying vec2 v_meta;     // x = normalized t (0..1), y = tier (1 primary, 0 secondary)
varying float v_energy_k;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void vertex() {
	vec3 pos_v = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tan_v = normalize((MODELVIEW_MATRIX * vec4(TANGENT.xyz, 0.0)).xyz);
	vec3 view_dir = normalize(-pos_v);
	vec3 side_v = cross(view_dir, tan_v);
	float slen = length(side_v);
	if (slen < 0.0001) {
		side_v = vec3(1.0, 0.0, 0.0);
	} else {
		side_v /= slen;
	}

	// Screen-space pixel size in view units at this vertex depth.
	float dist = max(-pos_v.z, 0.1);
	float proj_y = max(abs(PROJECTION_MATRIX[1][1]), 0.001);
	float px_world = (2.0 * dist) / (proj_y * max(VIEWPORT_SIZE.y, 1.0));
	float tier = UV2.y;
	float target_px = mix(min_px_half_width * 0.80, min_px_half_width * 1.10, tier);
	float hw = max(base_half_width, px_world * target_px);

	// Conserve apparent line luminance when clamped to sub-pixel width.
	v_energy_k = clamp(base_half_width / max(hw, 0.0001), 0.55, 1.0);
	pos_v += side_v * (UV.y * hw);

	// Slight view-space bias toward camera so tangent ribbons never clip into the planet sphere.
	pos_v += view_dir * 0.035;

	POSITION = PROJECTION_MATRIX * vec4(pos_v, 1.0);
	v_arc = UV;
	v_meta = UV2;
}

void fragment() {
	float cross_d = abs(v_arc.y);
	// Crisp bright core with soft narrow warm fringe.
	float profile = exp(-cross_d * cross_d * 5.2) * (1.0 - smoothstep(0.72, 1.0, cross_d));
	float tier = v_meta.y;

	// Procedural beaded city-light granulation along the arterial corridor.
	float s = v_arc.x;
	float cell_f = mix(6.8, 12.5, tier);
	float idx = floor(s * cell_f);
	float frac_s = fract(s * cell_f) - 0.5;
	float rnd = hash11(idx + tier * 71.3);
	float rnd2 = hash11(floor(s * 3.1) + 19.7);

	// Individual light beads + continuous faint luminous artery backbone.
	float bead = exp(-frac_s * frac_s * mix(26.0, 14.0, tier)) * (0.35 + 1.15 * rnd);
	float backbone = mix(0.035, 0.24, tier) * (0.65 + 0.45 * rnd2);

	// Secondary arcs read as delicate, sparser dotted city-light lines (075s/625s equator & upper arc).
	float gap_mask = mix(step(0.38, rnd), step(0.12, rnd), tier);
	float pattern = mix(backbone + bead * 1.15 * gap_mask, backbone + bead * 0.92 * (0.45 + 0.55 * gap_mask), tier);

	// Gentle brightening very close to hub junctions so corridors weld cleanly into starbursts.
	float end_prox = 1.0 - smoothstep(0.0, 0.075, min(v_meta.x, 1.0 - v_meta.x));
	pattern += end_prox * mix(0.18, 0.45, tier);

	vec3 col = mix(secondary_color, primary_color, tier);
	float energy = mix(secondary_energy, primary_energy, tier);
	ALBEDO = col * energy * profile * pattern * v_energy_k;
}
