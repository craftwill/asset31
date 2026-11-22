// Megastructure facade, final material family.
// - Low-res pixel textures (brick / concrete / metal panel), chosen per building
// - Storey window grid with frames, curtains and lit interiors
// - Hierarchical window-light LOD so distant facades stay readable as light dots
// - Optional storefront band (market street) and ceiling lamp grid
// Applied to unit cubes scaled to size (object mode) or to authored boxes in
// logical world space (use_world = 1) so neighbouring pieces line up seamlessly.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

#include "res://shaders/retro_common.gdshaderinc"

uniform sampler2D brick_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D panel_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D goods_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform vec3 tex_sizes = vec3(2.5, 4.0, 4.0);
uniform float style_override = -1.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 roof_color : source_color = vec3(0.36, 0.29, 0.23);
uniform vec3 glass_color : source_color = vec3(0.03, 0.028, 0.027);
uniform vec3 frame_color : source_color = vec3(0.07, 0.055, 0.045);
uniform vec3 window_color : source_color = vec3(1.0, 0.70, 0.38);
uniform vec3 window_color_alt : source_color = vec3(0.55, 0.80, 0.95);
uniform float window_energy = 1.8;
uniform float lit_fraction : hint_range(0.0, 1.0) = 0.17;
uniform float alt_fraction : hint_range(0.0, 1.0) = 0.012;
uniform float windows_enabled : hint_range(0.0, 1.0) = 1.0;
uniform vec2 bay = vec2(4.0, 3.5);
uniform vec2 window_frac = vec2(0.5, 0.5);
uniform float base_sink = 0.0;
uniform float use_world = 0.0;
uniform float world_floor_y = 41000.0;
uniform float shopfront = 0.0;
uniform float shop_height = 4.6;
uniform float grime_height = 5.0;
uniform float ceiling_lights = 0.0;
uniform float ceiling_light_spacing = 64.0;
uniform float ceiling_light_radius = 1.6;

varying vec3 v_pos;
varying vec3 v_nrm;
varying flat float v_seed;
varying flat float v_zone;
varying float v_base;
varying vec3 v_size;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_size = sc;
	if (use_world > 0.5) {
		v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + world_origin;
		v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
		v_base = world_floor_y;
	} else {
		v_pos = VERTEX * sc;
		v_nrm = NORMAL;
		v_base = -0.5 * sc.y + base_sink;
	}
	// INSTANCE_CUSTOM.x = zone + seed * 0.9 (zone 0 urban, 1 residential, 2 industrial)
	v_zone = floor(INSTANCE_CUSTOM.x + 0.001);
	v_seed = floor(fract(INSTANCE_CUSTOM.x + 0.001) * 512.0 + 0.5);
	POSITION = retro_snap(PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
}

vec3 window_lights(vec2 uv, float level, float seed, float litf) {
	vec2 cell = bay * exp2(level);
	vec2 g = uv / cell;
	vec2 id = floor(g);
	vec2 f = fract(g);
	vec2 dd = abs(f - vec2(0.5, 0.5));
	vec2 hw = window_frac * 0.5;
	float win = step(dd.x, hw.x) * step(dd.y, hw.y);
	vec2 sid = id + seed + level * 131.0;
	float h = hash12(sid);
	float h2 = hash12(sid.yx + 19.7);
	float lit = step(h, litf);
	float alt = step(1.0 - alt_fraction, h2) * (1.0 - lit);
	float flick = 0.4 + 0.65 * hash12(sid + 3.1);
	// Half-drawn curtains on some lit windows (level 0 only).
	float curtain = (level < 0.5 && hash12(sid + 7.7) > 0.6) ? mix(1.0, 0.25, step(f.y, 0.5)) : 1.0;
	return mix(window_color, window_color_alt, alt) * flick * curtain * win * (lit + alt) * window_energy;
}

vec3 wall_tex(vec2 uv, float style) {
	vec2 t = vec2(uv.x, -uv.y);
	vec3 b = texture(brick_tex, t / tex_sizes.x).rgb;
	vec3 c = texture(concrete_tex, t / tex_sizes.y).rgb;
	vec3 p = texture(panel_tex, t / tex_sizes.z).rgb;
	return style < 0.5 ? b : (style < 1.5 ? c : p);
}

void fragment() {
	vec3 n = v_nrm;
	bool horiz = abs(n.y) > 0.5;
	vec2 uv = retro_box_uv(v_pos, n);
	float h = v_pos.y - v_base;
	uv.y = h;

	float r = hash12(vec2(v_seed, 3.0));
	float style = style_override;
	float litf = lit_fraction;
	if (style < -0.5) {
		if (v_zone < 0.5) {
			style = r < 0.35 ? 0.0 : (r < 0.75 ? 1.0 : 2.0);
		} else if (v_zone < 1.5) {
			style = r < 0.6 ? 0.0 : (r < 0.9 ? 1.0 : 2.0);
			litf *= 0.55;
		} else {
			style = r < 0.1 ? 0.0 : (r < 0.5 ? 1.0 : 2.0);
			litf *= 0.25;
		}
	}
	vec3 btint = tint * mix(0.82, 1.12, hash12(vec2(v_seed, 9.0)));

	vec2 g = uv / bay;
	vec2 fw = fwidth(g);
	float far_t = smoothstep(0.3, 0.85, max(fw.x, fw.y));
	float wlod = max(0.0, log2(max(fw.x, fw.y) / 0.25));

	vec3 albedo;
	vec3 emit = vec3(0.0);

	if (horiz) {
		vec2 tuv = v_pos.xz;
		albedo = roof_color * mix(0.75, 1.15, hash12(floor(tuv / 6.0) + v_seed));
		albedo *= texture(concrete_tex, tuv / 8.0).rgb * 2.6;
		if (n.y < -0.5 && ceiling_lights > 0.5) {
			// Visual-comfort rules: a lamp is never smaller than ~1 px (energy
			// conserved when enlarged), and when lamps are packed closer than
			// ~3 px the grid resolves to its average glow, so nothing crawls.
			vec2 cg = tuv / ceiling_light_spacing;
			vec2 id = floor(cg);
			vec2 f = (fract(cg) - 0.5) * ceiling_light_spacing;
			float px_w = max(length(fwidth(tuv)), 1e-4);
			// Density and intensity vary by district-sized regions.
			float density = mix(0.35, 0.9, hash12(floor(id / 7.0) + 51.0));
			float on = step(hash12(id + 17.0), density);
			float inten = mix(0.45, 1.3, hash12(id + 23.0));
			float r_eff = max(ceiling_light_radius, px_w * 0.9);
			float scale = (ceiling_light_radius * ceiling_light_radius) / (r_eff * r_eff);
			float d = length(f);
			float lamp = 1.0 - smoothstep(r_eff - px_w * 0.5, r_eff + px_w * 0.5, d);
			vec3 near_e = window_color * lamp * on * inten * scale;
			float area = 3.14159 * ceiling_light_radius * ceiling_light_radius / (ceiling_light_spacing * ceiling_light_spacing);
			vec3 avg_e = window_color * density * 0.875 * area;
			float t = smoothstep(3.0, 1.5, ceiling_light_spacing / px_w);
			emit += mix(near_e, avg_e, t) * window_energy * 2.5;
		}
	} else {
		albedo = wall_tex(uv, style) * btint;
		// Grime toward the street.
		albedo *= mix(0.55, 1.0, smoothstep(0.0, grime_height, h));
		bool in_shop = shopfront > 0.5 && h < shop_height;
		if (in_shop) {
			// Storefronts: split the face into shop bays of ~7 m.
			float facew = abs(n.x) > 0.5 ? v_size.z : v_size.x;
			float nseg = max(1.0, floor(facew / 7.0 + 0.5));
			float u01 = (uv.x + facew * 0.5) / facew;
			float sid = floor(u01 * nseg);
			float sf = fract(u01 * nseg);
			float open = step(0.22, hash12(vec2(sid, v_seed + 5.0)));
			float edge = step(sf, 0.04) + step(0.96, sf);
			if (h > 0.35 && h < 3.4 && edge < 0.5) {
				if (open > 0.5) {
					vec3 goods = texture(goods_tex, vec2(uv.x, -h) / 4.0).rgb;
					float mull = step(0.94, fract(uv.x / 1.75));
					albedo = mix(goods * 0.6, frame_color, mull);
					emit += goods * (1.0 - mull) * 2.2 + vec3(1.0, 0.75, 0.45) * 0.25 * (1.0 - mull);
				} else {
					float slat = step(0.8, fract(h / 0.18));
					albedo = mix(vec3(0.20, 0.19, 0.18), vec3(0.09), slat) * texture(panel_tex, uv / 4.0).rgb * 3.0;
				}
			} else if (h > 3.55 && h < 4.35 && edge < 0.5) {
				float sh = hash12(vec2(sid, v_seed + 11.0));
				vec3 sc;
				if (sh < 0.3) sc = vec3(0.25, 0.95, 0.75);
				else if (sh < 0.5) sc = vec3(0.95, 0.35, 0.85);
				else if (sh < 0.75) sc = vec3(1.0, 0.85, 0.45);
				else sc = vec3(0.45, 0.75, 1.0);
				float pix = step(0.35, hash12(floor(vec2(uv.x * 4.0, h * 6.0)) + sid));
				float lit_sign = open * step(0.3, sh + 0.2);
				albedo = vec3(0.05);
				emit += sc * mix(0.3, 0.8, pix) * 1.3 * lit_sign;
			}
		} else if (windows_enabled > 0.5) {
			vec2 id = floor(g);
			vec2 f = fract(g);
			vec2 hw = window_frac * 0.5;
			vec2 dd = abs(f - vec2(0.5, 0.5));
			float win = step(dd.x, hw.x) * step(dd.y, hw.y);
			vec2 fr = hw + vec2(0.06, 0.05);
			float frame = step(dd.x, fr.x) * step(dd.y, fr.y) * (1.0 - win);
			float sill = step(dd.x, fr.x) * step(abs(f.y - 0.5 + fr.y + 0.03), 0.03);
			float cover = window_frac.x * window_frac.y;
			vec3 a_near = mix(albedo, frame_color, max(frame, sill));
			a_near = mix(a_near, glass_color * mix(0.7, 1.4, hash12(id + v_seed + 2.0)), win);
			albedo = mix(a_near, mix(albedo, glass_color, cover), far_t);
			if (shopfront < 0.5 || h > shop_height + 0.4) {
				float l0 = floor(wlod);
				float lt = fract(wlod);
				emit += mix(window_lights(uv, l0, v_seed, litf), window_lights(uv, l0 + 1.0, v_seed, litf), lt);
			}
		}
	}
	ALBEDO = albedo;
	ROUGHNESS = 0.95;
	EMISSION = emit;
}
