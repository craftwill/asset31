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
#include "res://shaders/window_interior.gdshaderinc"

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
uniform float no_snap = 0.0;
uniform float fade_start = 0.0;
uniform float fade_end = 0.0;
uniform float floor_bands = 0.0;
uniform float interior_enabled = 1.0;
uniform float world_y = 0.0;

varying vec3 v_pos;
varying vec3 v_nrm;
varying flat float v_seed;
varying flat float v_zone;
varying float v_base;
varying vec3 v_size;
varying float v_dist;
varying float v_ly;
varying vec3 v_ray;

void vertex() {
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_size = sc;
	vec3 rpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wpos = rpos + world_origin;
	v_ly = wpos.y;
	vec3 ray_r = rpos - INV_VIEW_MATRIX[3].xyz;
	if (use_world > 0.5) {
		v_pos = wpos;
		v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
		v_base = world_floor_y;
		v_ray = ray_r;
	} else {
		v_pos = VERTEX * sc;
		if (world_y > 0.5) {
			v_pos.y = wpos.y;
		}
		v_nrm = NORMAL;
		v_base = (world_y > 0.5) ? world_floor_y : (-0.5 * sc.y + base_sink);
		vec3 ax = normalize(MODEL_MATRIX[0].xyz);
		vec3 ay = normalize(MODEL_MATRIX[1].xyz);
		vec3 az = normalize(MODEL_MATRIX[2].xyz);
		v_ray = vec3(dot(ray_r, ax), dot(ray_r, ay), dot(ray_r, az));
	}
	// INSTANCE_CUSTOM.x = zone + seed * 0.9 (zone 0 urban, 1 residential, 2 industrial)
	v_zone = floor(INSTANCE_CUSTOM.x + 0.001);
	v_seed = floor(fract(INSTANCE_CUSTOM.x + 0.001) * 512.0 + 0.5);
	vec4 mv = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	v_dist = -mv.z;
	vec4 clip = PROJECTION_MATRIX * mv;
	POSITION = (no_snap > 0.5) ? clip : retro_snap_stable(clip, sc);
}

// Analytical 1D box-filter coverage for a centred rectangle [-hw, hw] inside
// a unit cell, conserving energy across pixel boundaries so windows never pop.
float box_cov(vec2 f, vec2 hw, vec2 aa) {
	vec2 p = f - vec2(0.5);
	vec2 a = max(aa, vec2(1e-4));
	vec2 cov = max(min(p + 0.5 * a, hw) - max(p - 0.5 * a, -hw), vec2(0.0)) / a;
	return cov.x * cov.y;
}

vec3 window_lights(vec2 uv, float level, float seed, float litf, vec2 fw_base) {
	float sc_lvl = exp2(level);
	vec2 cell = bay * sc_lvl;
	vec2 g = uv / cell;
	vec2 id = floor(g);
	vec2 f = fract(g);
	vec2 hw = window_frac * 0.5;
	float win = box_cov(f, hw, fw_base / sc_lvl);
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
			litf *= 0.68;
		} else {
			style = r < 0.1 ? 0.0 : (r < 0.5 ? 1.0 : 2.0);
			litf *= 0.25;
		}
	}
	vec3 btint = tint * mix(0.82, 1.12, hash12(vec2(v_seed, 9.0)));

	vec2 g = uv / bay;
	vec2 fw = max(fwidth(g), vec2(1e-4));
	float fw_max = max(fw.x, fw.y);
	float fw_min = max(min(fw.x, fw.y), 1e-4);
	float aniso = fw_max / fw_min;
	float far_t = smoothstep(0.22, 0.65, fw_max);
	float wlod = max(0.0, log2(fw_max / 0.20));
	float ceil_px_w = max(length(fwidth(v_pos.xz)), 1e-4);

	if (fade_end > 0.0 && v_dist > fade_start) {
		float ft = clamp((v_dist - fade_start) / max(fade_end - fade_start, 1.0), 0.0, 1.0);
		if (ft >= retro_bayer(FRAGCOORD.xy)) {
			discard;
		}
	}

	if (floor_bands > 0.5) {
		// Macro floor-slab dark bands (900 m pitch, ~60 m slab) and district-scale
		// occupancy variation so distant stack walls read as layered floors.
		float fy = fract((v_ly - world_floor_y + 60.0) / 900.0);
		float slab_band = smoothstep(0.0, 0.015, fy) * (1.0 - smoothstep(0.065, 0.085, fy));
		float macro = mix(0.45, 1.35, hash12(floor(vec2(uv.x, v_ly - world_floor_y) / 260.0) + vec2(37.0, 11.0)));
		litf *= mix(macro, 0.12, slab_band);
	}

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
			float px_w = ceil_px_w;
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
			float win = box_cov(f, hw, fw);
			vec2 fr = hw + vec2(0.06, 0.05);
			float outer = box_cov(f, fr, fw);
			float frame = max(outer - win, 0.0);
			float sill = box_cov(vec2(f.x, f.y + fr.y + 0.03), vec2(fr.x, 0.03), fw);
			float cover = window_frac.x * window_frac.y;
			vec3 a_near = mix(albedo, frame_color, max(frame, sill));
			a_near = mix(a_near, glass_color * mix(0.7, 1.4, hash12(id + v_seed + 2.0)), win);
			albedo = mix(a_near, mix(albedo, glass_color, cover), far_t);
			if (shopfront < 0.5 || h > shop_height + 0.4) {
				float l0 = floor(wlod);
				float lt = fract(wlod);
				vec3 e_lod = mix(window_lights(uv, l0, v_seed, litf, fw), window_lights(uv, l0 + 1.0, v_seed, litf, fw), lt);
				float eff_alt = alt_fraction * (1.0 - litf);
				vec3 e_avg = (window_color * litf + window_color_alt * eff_alt) * 0.725 * cover * window_energy;
				float graze_t = smoothstep(3.5, 8.0, aniso) * smoothstep(0.15, 0.45, fw_max);
				vec3 e_far = mix(e_lod, e_avg, graze_t);
				// Near/mid distance: single-pass ray-box procedural 3D room interiors
				// that cross-fade seamlessly into the far emissive LOD with zero pop.
				float interior_k = (interior_enabled > 0.5) ? (1.0 - smoothstep(0.12, 0.26, fw_max)) : 0.0;
				if (interior_k > 0.001 && win > 0.01) {
					vec2 sid0 = id + v_seed;
					float h_lit = hash12(sid0);
					float h_alt = hash12(sid0.yx + 19.7);
					float is_lit = step(h_lit, litf);
					float is_alt = step(1.0 - alt_fraction, h_alt) * (1.0 - is_lit);
					float flick = 0.4 + 0.65 * hash12(sid0 + 3.1);
					vec3 lcol = mix(window_color, window_color_alt, is_alt);
					float detail_k = 1.0 - smoothstep(0.05, 0.15, fw_max);
					vec3 e_int = mantle_window_interior(
						f, hw, bay, normalize(n), normalize(v_ray),
						sid0, v_zone, lcol, max(is_lit, is_alt), flick, window_energy,
						detail_k, -1.0, -1.0) * win;
					emit += mix(e_far, e_int, interior_k);
				} else {
					emit += e_far;
				}
			}
		}
	}
	if (fade_end > 0.0) {
		float e_fade = 1.0 - smoothstep(max(0.0, fade_start - 700.0), fade_start, v_dist);
		emit *= e_fade;
	}
	ALBEDO = albedo;
	ROUGHNESS = 0.95;
	EMISSION = emit;
}
