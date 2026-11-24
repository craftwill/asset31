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
// Enterable ground-floor rooms (city MultiMeshes only). Per-instance COLOR carries
// (face + 1, door bay index, left bays + 8 * right bays + 64 * lit); see InteriorKit.
uniform float doors_enabled = 0.0;
// Ceiling lamp grid: lamps die out between these two object-space z values and stay
// dead beyond the second (disabled while y <= x).
uniform vec2 dead_band = vec2(0.0, 0.0);
// City buildings: lit windows thin out between these logical z values and are all dark
// beyond the second (disabled while y <= x).
uniform vec2 lit_fade_band = vec2(0.0, 0.0);
// 1 = apply that fade along the surface itself (kilometre-long stack walls) instead of
// once per building.
uniform float lit_fade_pixel = 0.0;
uniform float door_cut_near = 46.0;
uniform float door_cut_far = 58.0;

varying vec3 v_pos;
varying vec3 v_nrm;
varying flat float v_seed;
varying flat float v_zone;
varying float v_base;
varying vec3 v_size;
varying float v_dist;
varying float v_ly;
varying vec3 v_ray;
varying flat vec3 v_door;
varying flat float v_lit_k;
varying float v_lz;

void vertex() {
	v_door = (doors_enabled > 0.5) ? COLOR.rgb : vec3(0.0);
	// Per building (its origin), so a facade never fades halfway across.
	v_lit_k = (lit_fade_band.y > lit_fade_band.x)
		? 1.0 - smoothstep(lit_fade_band.x, lit_fade_band.y, MODEL_MATRIX[3].z + world_origin.z) : 1.0;
	vec3 sc = retro_object_scale(MODEL_MATRIX, INSTANCE_CUSTOM);
	v_size = sc;
	vec3 rpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wpos = rpos + world_origin;
	v_ly = wpos.y;
	v_lz = wpos.z;
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

// 1 when the whole window of bay column `idx` fits on a face of half-width
// `face_half` (bays are centred on the building, so edge bays can be cut by a corner).
float bay_fits(float idx, float face_half) {
	return step(abs((idx + 0.5) * bay.x) + bay.x * (window_frac.x * 0.5 + 0.06) + 0.25, face_half);
}

// Flat window emission for one LOD level.
//   near_match : 1 near the 3D-interior hand-off, where the flat window takes the
//                same average brightness as the room it replaces (no pop), easing
//                to the classic bright light-dot look (0) in the distance.
//   room       : (active, door bay, left bays, right bays) of an enterable room on
//                this face; its ground-floor bays glow only if the room is lit (room_lit).
vec3 window_lights(vec2 uv, float level, float seed, float litf, vec2 fw_base, float zone, float near_match, float face_half, vec4 room, float room_lit, float altf) {
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
	float alt = step(1.0 - altf, h2) * (1.0 - lit);
	float flick = 0.4 + 0.65 * hash12(sid + 3.1);
	float gain = 1.0;
	if (level < 0.5) {
		// Half-drawn curtains on some lit windows in the far look.
		float curtain = (hash12(sid + 7.7) > 0.6) ? mix(1.0, 0.25, step(f.y, 0.5)) : 1.0;
		gain = mix(curtain, mantle_window_mean(sid, zone, lit + alt), near_match);
		win *= bay_fits(id.x, face_half);
		float rel = id.x - room.y;
		if (room.x > 0.5 && id.y > -0.5 && id.y < 0.5 && rel > -room.z - 0.5 && rel < room.w + 0.5) {
			// Enterable room: the door bay glows through its doorway, the others are lit windows.
			vec2 pm = (f - vec2(0.5)) * bay;
			float door = step(abs(pm.x), 0.7) * step(f.y * bay.y, 2.3);
			return window_color * ((abs(rel) < 0.5) ? door : win) * 0.42 * window_energy * room_lit;
		}
	} else {
		gain = mix(1.0, 0.5, near_match);
	}
	return mix(window_color, window_color_alt, alt) * flick * gain * win * (lit + alt) * window_energy;
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
	float altf = alt_fraction;
	if (style < -0.5) {
		if (v_zone < 0.5) {
			style = r < 0.35 ? 0.0 : (r < 0.75 ? 1.0 : 2.0);
		} else if (v_zone < 1.5) {
			style = r < 0.6 ? 0.0 : (r < 0.9 ? 1.0 : 2.0);
			litf *= 0.68;
		} else if (v_zone < 2.5) {
			style = r < 0.1 ? 0.0 : (r < 0.5 ? 1.0 : 2.0);
			litf *= 0.25;
		} else {
			// Abandoned: bare concrete and brick, almost every window dead.
			style = r < 0.45 ? 0.0 : 1.0;
			litf *= 0.12;
			altf *= 0.12;
		}
	}
	// Power failing with distance: both the common and the odd-coloured windows go.
	float lit_k = v_lit_k;
	if (lit_fade_pixel > 0.5 && lit_fade_band.y > lit_fade_band.x) {
		// Stepped in 16 m lengths so no single window is ever half faded.
		lit_k = 1.0 - smoothstep(lit_fade_band.x, lit_fade_band.y, floor(v_lz / 16.0) * 16.0 + 8.0);
	}
	litf *= lit_k * lit_k;
	altf *= lit_k * lit_k;
	vec3 btint = tint * mix(0.82, 1.12, hash12(vec2(v_seed, 9.0)));
	if (v_zone > 2.5) {
		btint *= 0.95;
	}

	vec2 g = uv / bay;
	vec2 fw = max(fwidth(g), vec2(1e-4));
	float fw_max = max(fw.x, fw.y);
	float fw_min = max(min(fw.x, fw.y), 1e-4);
	float aniso = fw_max / fw_min;
	float far_t = smoothstep(0.22, 0.65, fw_max);
	// Object-mode boxes know their face width, so bays cut by a corner can be dropped.
	float face_half = (use_world > 0.5) ? 1e9 : 0.5 * (abs(n.x) > 0.5 ? v_size.z : v_size.x);
	// Enterable ground-floor room on this face? (active, door bay, bays to its left, right)
	vec4 room = vec4(0.0);
	float room_lit = 0.0;
	if (!horiz && v_door.x > 0.5) {
		float fcode = abs(n.x) > 0.5 ? (n.x > 0.0 ? 1.0 : 2.0) : (n.z > 0.0 ? 3.0 : 4.0);
		if (abs(fcode - v_door.x) < 0.5) {
			float pack = floor(v_door.z + 0.5);
			room = vec4(1.0, floor(v_door.y + 0.5), mod(pack, 8.0), mod(floor(pack / 8.0), 8.0));
			room_lit = step(63.5, pack);
		}
	}
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
			float alive = 1.0;
			if (dead_band.y > dead_band.x) {
				// Whole lamps go out (a rare straggler survives), never half a lamp.
				float lz = (id.y + 0.5 + 0.9 * (hash12(id + 61.0) - 0.5)) * ceiling_light_spacing;
				alive = max(1.0 - smoothstep(dead_band.x, dead_band.y, lz), step(0.985, hash12(id + 43.0)) * 0.5 * step(lz, dead_band.y + 700.0));
				on *= alive;
			}
			float inten = mix(0.45, 1.3, hash12(id + 23.0));
			float r_eff = max(ceiling_light_radius, px_w * 0.9);
			float scale = (ceiling_light_radius * ceiling_light_radius) / (r_eff * r_eff);
			float d = length(f);
			float lamp = 1.0 - smoothstep(r_eff - px_w * 0.5, r_eff + px_w * 0.5, d);
			vec3 near_e = window_color * lamp * on * inten * scale;
			float area = 3.14159 * ceiling_light_radius * ceiling_light_radius / (ceiling_light_spacing * ceiling_light_spacing);
			vec3 avg_e = window_color * density * 0.875 * area * alive;
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
			float fits = bay_fits(id.x, face_half);
			float win = box_cov(f, hw, fw) * fits;
			float cover = window_frac.x * window_frac.y;
			// Bays of an enterable room: 1 = doorway bay, 2 = real window into the room.
			float rel = id.x - room.y;
			float open_kind = 0.0;
			if (room.x > 0.5 && h >= 0.0 && h < bay.y && rel > -room.z - 0.5 && rel < room.w + 0.5) {
				open_kind = (abs(rel) < 0.5) ? 1.0 : 2.0;
			}
			// Near the camera the openings are cut out of the facade (dithered), revealing
			// the real streamed room behind; farther away they are painted lit.
			float cut_k = 1.0 - smoothstep(door_cut_near, door_cut_far, length(v_ray));
			bool cut = open_kind > 0.5 && cut_k > retro_bayer(FRAGCOORD.xy);
			if (open_kind > 0.5 && open_kind < 1.5) {
				// Doorway: 1.4 x 2.3 m opening with a dark frame, replacing the bay's window.
				vec2 pm = (f - vec2(0.5)) * bay;
				bool in_door = abs(pm.x) < 0.70 && h < 2.30;
				bool in_frame = abs(pm.x) < 0.82 && h < 2.42;
				if (in_door && cut) {
					discard;
				}
				if (in_door) {
					albedo = mix(glass_color, albedo, far_t);
				} else if (in_frame) {
					albedo = mix(frame_color, albedo, far_t);
				}
			} else {
				if (open_kind > 1.5 && cut && abs(f.x - 0.5) < hw.x && abs(f.y - 0.5) < hw.y) {
					discard;
				}
				vec2 fr = hw + vec2(0.06, 0.05);
				float outer = box_cov(f, fr, fw) * fits;
				float frame = max(outer - win, 0.0);
				float sill = box_cov(vec2(f.x, f.y + fr.y + 0.03), vec2(fr.x, 0.03), fw) * fits;
				vec3 a_near = mix(albedo, frame_color, max(frame, sill));
				a_near = mix(a_near, glass_color * mix(0.7, 1.4, hash12(id + v_seed + 2.0)), win);
				albedo = mix(a_near, mix(albedo, glass_color, cover), far_t);
			}
			if (shopfront < 0.5 || h > shop_height + 0.4) {
				float l0 = floor(wlod);
				float lt = fract(wlod);
				float near_match = 1.0 - smoothstep(0.26, 0.7, fw_max);
				vec3 e_lod = mix(
					window_lights(uv, l0, v_seed, litf, fw, v_zone, near_match, face_half, room, room_lit, altf),
					window_lights(uv, l0 + 1.0, v_seed, litf, fw, v_zone, near_match, face_half, room, room_lit, altf), lt);
				float eff_alt = altf * (1.0 - litf);
				vec3 e_avg = (window_color * litf + window_color_alt * eff_alt) * 0.725 * cover * window_energy;
				float graze_t = smoothstep(3.5, 8.0, aniso) * smoothstep(0.15, 0.45, fw_max);
				vec3 e_far = mix(e_lod, e_avg, graze_t);
				// Near/mid distance: single-pass ray-box procedural 3D room interiors that
				// cross-fade into the far emissive LOD. The fade follows the footprint along
				// the least foreshortened axis, so rooms keep their depth when you look up a
				// tower or along a street; they only flatten once a window is under ~1 px wide.
				float interior_k = (interior_enabled > 0.5)
					? (1.0 - smoothstep(0.12, 0.26, fw_min)) * (1.0 - smoothstep(0.45, 0.9, fw_max)) : 0.0;
				if (open_kind < 0.5 && interior_k > 0.001 && win > 0.01) {
					vec2 sid0 = id + v_seed;
					float h_lit = hash12(sid0);
					float h_alt = hash12(sid0.yx + 19.7);
					float is_lit = step(h_lit, litf);
					float is_alt = step(1.0 - altf, h_alt) * (1.0 - is_lit);
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
