// Procedural interior-mapping shader module for Asset31 (the Mantle).
// Simulates 3D inhabited rooms behind flat window planes using single-pass
// tangent-space ray-box intersection, dark furniture silhouettes, curtains/blinds,
// and 7 deterministic room categories within the dark amber Mantle palette.
//
// Dependencies: #include "res://shaders/retro_common.gdshaderinc" before this file.

// Average brightness of a window's interior relative to lit_col * flick * energy,
// from the same per-window hashes as mantle_window_interior(). The flat far LOD
// uses it so a window keeps its brightness when the 3D room hands over to it.
float mantle_window_mean(vec2 sid, float zone, float is_lit) {
	if (is_lit < 0.5) {
		return 0.0;
	}
	float h_cat = hash12(sid + vec2(41.3, 17.1));
	float h_curt = hash12(sid + vec2(73.9, 29.3));
	if (h_curt > 0.80) {
		return 0.44; // closed curtains / blinds
	}
	float g = 0.46;
	if (zone > 1.5) {
		g *= (h_cat < 0.52) ? 0.78 : ((h_cat < 0.82) ? 1.0 : 0.58);
	} else if (zone > 0.5) {
		g *= (h_cat < 0.82) ? 1.0 : 0.58;
	} else {
		g *= (h_cat < 0.76) ? 1.0 : ((h_cat < 0.88) ? 0.78 : 0.58);
	}
	return g * ((h_curt >= 0.30) ? 0.8 : 1.0);
}

// Evaluates one procedural room interior behind a window opening.
//   f          : bay-local UV in [0, 1] x [0, 1] (window opening is centred at 0.5, half-size hw)
//   hw         : half-size of window opening inside the bay (e.g. vec2(0.25, 0.25))
//   bay_m      : bay dimensions in metres (e.g. vec2(4.0, 3.5))
//   n          : outward face normal in room-matching space
//   ray_dir    : unit vector from camera to fragment in the same space as `n`
//   sid        : stable deterministic window seed (floor(uv/bay) + building_seed)
//   zone       : 0 = urban, 1 = residential, 2 = industrial
//   lit_col    : base light colour (warm amber or cool alt)
//   is_lit     : 1.0 if lit, 0.0 if dark unlit room
//   flick      : deterministic per-window brightness factor (~0.4..1.05)
//   energy     : overall window emission scale
//   detail_k   : 1.0 near (silhouettes + slats + folds), 0.0 mid (clean room box + drapes)
//   cat_override: < 0.0 for deterministic procedural category, or 0..6 to force a category
//   curt_override: < 0.0 for deterministic curtain state, or 0..1 to force state
vec3 mantle_window_interior(
		vec2 f,
		vec2 hw,
		vec2 bay_m,
		vec3 n,
		vec3 ray_dir,
		vec2 sid,
		float zone,
		vec3 lit_col,
		float is_lit,
		float flick,
		float energy,
		float detail_k,
		float cat_override,
		float curt_override) {
	// Stable per-window variation hashes (never changes with view angle or reload).
	float h_cat  = hash12(sid + vec2(41.3, 17.1));
	float h_curt = (curt_override >= 0.0) ? curt_override : hash12(sid + vec2(73.9, 29.3));
	float h_var  = hash12(sid + vec2(109.1, 53.7));
	float h_dep  = hash12(sid + vec2(151.7, 89.3));
	float h_side = (hash12(sid + vec2(197.3, 13.7)) > 0.5) ? 1.0 : -1.0;

	// Window-pane local UV in [0, 1] x [0, 1].
	vec2 wuv = clamp((f - (vec2(0.5) - hw)) / max(hw * 2.0, vec2(1e-4)), vec2(0.0), vec2(1.0));

	// Choose one of 7 room categories:
	// 0 Residential, 1 Office, 2 Workshop, 3 Industrial, 4 Empty, 5 Closed curtains, 6 Dark unlit
	int cat = 6;
	if (cat_override >= 0.0) {
		cat = int(floor(cat_override + 0.5));
	} else if (is_lit > 0.5) {
		if (h_curt > 0.80) {
			cat = 5;
		} else if (zone > 1.5) {
			cat = (h_cat < 0.52) ? 3 : ((h_cat < 0.82) ? 2 : 4);
		} else if (zone > 0.5) {
			cat = (h_cat < 0.58) ? 0 : ((h_cat < 0.72) ? 1 : ((h_cat < 0.82) ? 2 : 4));
		} else {
			cat = (h_cat < 0.38) ? 0 : ((h_cat < 0.62) ? 1 : ((h_cat < 0.76) ? 2 : ((h_cat < 0.88) ? 3 : 4)));
		}
	}

	// Curtain / blind occlusion mask on the glass plane (0 = clear glass, 1 = covered).
	float curt_mask = 0.0;
	float curt_tex = 1.0;
	if (cat == 5) {
		// Fully closed curtains or blinds with soft backlit folds/slats.
		curt_mask = 1.0;
		if (h_var > 0.45) {
			float fold = 0.82 + 0.18 * sin(wuv.x * 22.0 + h_cat * 6.28);
			curt_tex = mix(0.9, fold, detail_k);
		} else {
			float slat = 0.72 + 0.28 * smoothstep(0.18, 0.32, fract(wuv.y * 14.0));
			curt_tex = mix(0.85, slat, detail_k);
		}
	} else if (h_curt >= 0.30 && h_curt <= 0.62) {
		// Partially closed curtains (left, right, or parted both sides).
		float sway = (h_var > 0.85) ? sin(TIME * 0.85 + h_cat * 31.0) * 0.014 * (1.0 - wuv.y) : 0.0;
		float cover = 0.22 + 0.24 * fract(h_curt * 11.3);
		float fold = 0.78 + 0.22 * sin(wuv.x * 26.0 + h_var * 9.0);
		if (h_var < 0.35) {
			curt_mask = step(wuv.x, cover + sway);
		} else if (h_var < 0.70) {
			curt_mask = step(1.0 - cover + sway, wuv.x);
		} else {
			float half_c = cover * 0.78;
			curt_mask = max(step(wuv.x, half_c + sway), step(1.0 - half_c - sway, wuv.x));
		}
		curt_tex = mix(0.88, fold, detail_k);
	} else if (h_curt > 0.62 && h_curt <= 0.80) {
		// Partially lowered horizontal blinds from top edge.
		float drop = 0.28 + 0.38 * fract(h_curt * 17.7);
		curt_mask = step(1.0 - drop, wuv.y);
		float slat = 0.68 + 0.32 * smoothstep(0.2, 0.35, fract(wuv.y * 14.0));
		curt_tex = mix(0.84, slat, detail_k);
	}

	// Fast path for fully closed curtains / blinds (cat 5): soft backlit fabric.
	if (cat == 5) {
		float center_glow = 0.65 + 0.35 * (1.0 - length((wuv - vec2(0.5, 0.55)) * vec2(1.2, 1.3)));
		vec3 closed_col = lit_col * clamp(center_glow, 0.35, 1.0) * curt_tex * 0.62;
		return closed_col * flick * energy * is_lit;
	}

	// Build orthonormal face tangent basis matching retro_box_uv():
	//   +T aligns with +uv.x, +B aligns with +uv.y (+Y), inward is -n.
	vec3 T = (abs(n.x) > abs(n.z)) ? vec3(0.0, 0.0, sign(n.x)) : vec3(-sign(n.z), 0.0, 0.0);
	vec3 B = vec3(0.0, 1.0, 0.0);
	float half_w = max(bay_m.x * 0.5, 0.1);
	float half_h = max(bay_m.y * 0.5, 0.1);

	// Room space: x in [-1, 1], y in [-1, 1], z in [0, depth] (depth ~1.2..1.85 half-widths = 2.4..3.7 m).
	float depth = mix(1.20, 1.85, h_dep);
	vec3 ro = vec3((f.x - 0.5) * 2.0, (f.y - 0.5) * 2.0, 0.0);
	vec3 rd = vec3(
		dot(ray_dir, T) / half_w,
		dot(ray_dir, B) / half_h,
		max(dot(ray_dir, -n), 0.06) / half_w);

	// Ray-box intersection against left/right walls (x=+-1), floor/ceil (y=+-1), back wall (z=depth).
	float tx = (rd.x >= 0.0 ? (1.0 - ro.x) : (-1.0 - ro.x)) / (abs(rd.x) + 1e-5);
	float ty = (rd.y >= 0.0 ? (1.0 - ro.y) : (-1.0 - ro.y)) / (abs(rd.y) + 1e-5);
	float tz = depth / (rd.z + 1e-5);
	float t_hit = min(min(tx, ty), tz);
	vec3 hp = ro + rd * t_hit;

	// Surface identification & base shading (dark concrete/steel Mantle walls).
	float z01 = clamp(hp.z / depth, 0.0, 1.0);
	vec3 room_tone = (cat == 6) ? vec3(0.035, 0.028, 0.022) : lit_col;
	float light_y = (cat == 0 && h_var > 0.55) ? -0.15 : 0.72; // desk/side lamp vs ceiling bulb
	vec3 lamp_pos = vec3(h_side * 0.25 * (cat == 0 ? 1.0 : 0.0), light_y, depth * 0.52);
	float dist_l = length((hp - lamp_pos) * vec3(1.0, 0.9, 0.75));
	float falloff = 1.0 / (0.55 + dist_l * dist_l * 0.95);
	// Corner ambient occlusion deepens architectural room edges.
	float ao_x = 1.0 - 0.28 * smoothstep(0.78, 1.0, abs(hp.x));
	float ao_y = 1.0 - 0.28 * smoothstep(0.78, 1.0, abs(hp.y));
	float ao_z = 1.0 - 0.25 * smoothstep(0.80, 1.0, z01);

	float surf_shade = 0.55;
	float lamp_spot = 0.0;
	if (tz <= tx && tz <= ty) {
		// Back wall: subtle wall panel seams + vertical shadow toward floor.
		float seam = 1.0 - 0.14 * detail_k * step(0.95, fract((hp.x + 1.0) * 1.5));
		surf_shade = mix(0.32, 0.76, smoothstep(-1.0, 0.7, hp.y)) * seam * ao_x * ao_y;
		// Back-wall dark silhouette details (shelves, divider, machinery tank).
		if (detail_k > 0.02) {
			float bx = hp.x * h_side;
			float back_sil = 0.0;
			if (cat == 0) {
				// Residential: wall shelf + framed dark rectangle.
				float shelf = step(0.18, hp.y) * step(hp.y, 0.26) * step(-0.75, bx) * step(bx, -0.1);
				float frame_p = step(0.05, hp.y) * step(hp.y, 0.55) * step(0.25, bx) * step(bx, 0.68);
				back_sil = max(shelf * 0.75, frame_p * 0.45);
			} else if (cat == 1) {
				// Office: tall filing/shelf cabinet + partition column.
				float cab = step(-1.0, hp.y) * step(hp.y, 0.42) * step(0.22, bx) * step(bx, 0.85);
				float div = step(-0.18, bx) * step(bx, -0.06);
				back_sil = max(cab * 0.65, div * 0.55);
			} else if (cat == 2) {
				// Workshop: overhead tool rack + vertical pipe conduit.
				float rack = step(0.05, hp.y) * step(hp.y, 0.45) * step(-0.6, bx) * step(bx, 0.55);
				float pipe = step(0.65, bx) * step(bx, 0.78);
				back_sil = max(rack * 0.6, pipe * 0.7);
			} else if (cat == 3) {
				// Industrial: heavy structural rib + cylindrical tank silhouette.
				float rib = step(0.86, fract((hp.x + 1.0) * 2.0));
				float tank = step(-1.0, hp.y) * step(hp.y, 0.65) * step(-0.75, bx) * step(bx, -0.15);
				back_sil = max(rib * 0.55, tank * 0.78);
			}
			surf_shade *= (1.0 - back_sil * detail_k);
		}
	} else if (ty < tx && ty < tz) {
		if (rd.y > 0.0) {
			// Ceiling + hanging bulb / fluorescent strip.
			surf_shade = mix(0.24, 0.54, 1.0 - z01 * 0.5) * ao_x * ao_z;
			if (cat != 6) {
				if (cat == 1 || cat == 3) {
					// Linear overhead tube strip.
					float bar = (1.0 - smoothstep(0.10, 0.24, abs(hp.x))) * (1.0 - smoothstep(0.28, 0.42, abs(z01 - 0.50)));
					lamp_spot = bar * 0.85;
				} else {
					// Small ceiling bulb glow.
					float d_b = length(vec2(hp.x - lamp_pos.x, (hp.z - lamp_pos.z) * 0.85));
					lamp_spot = (1.0 - smoothstep(0.06, 0.28, d_b)) * 0.95;
				}
			}
		} else {
			// Floor: darker than walls, picks up subtle pool under the light.
			surf_shade = mix(0.16, 0.44, falloff) * ao_x * ao_z;
		}
	} else {
		// Left or right side wall: deeper gradient into the room for strong 3D depth.
		float seam = 1.0 - 0.14 * detail_k * step(0.94, fract(hp.z * 1.6));
		surf_shade = mix(0.54, 0.22, z01) * mix(0.65, 1.0, smoothstep(-1.0, 0.4, hp.y)) * seam * ao_y * ao_z;
	}

	// Category light level tuning (empty rooms dimmer, dark rooms barely visible).
	float cat_gain = 1.0;
	if (cat == 4) cat_gain = 0.58;
	else if (cat == 3) cat_gain = 0.78;
	else if (cat == 6) cat_gain = 0.28;

	vec3 interior = room_tone * (surf_shade * (0.42 + 0.82 * falloff) + lamp_spot) * cat_gain;

	// Mid-room parallax silhouette layer (z = 0.42 * depth) for true 3D furniture parallax.
	if (detail_k > 0.02 && cat != 6) {
		float z_mid = depth * 0.42;
		float t_mid = z_mid / (rd.z + 1e-5);
		if (t_mid < t_hit) {
			vec2 mp = ro.xy + rd.xy * t_mid;
			if (abs(mp.x) < 1.0 && abs(mp.y) < 1.0) {
				float mx = mp.x * h_side;
				float my = mp.y;
				float sil = 0.0;
				if (cat == 0) {
					// Bed frame + headboard on one side, table + chair on the other.
					float bed = step(-1.0, my) * step(my, -0.38) * step(-0.95, mx) * step(mx, -0.05);
					float headb = step(-0.38, my) * step(my, -0.10) * step(-0.95, mx) * step(mx, -0.78);
					float tbl = step(-0.52, my) * step(my, -0.42) * step(0.18, mx) * step(mx, 0.82);
					float leg = step(-1.0, my) * step(my, -0.52) * (step(0.22, mx) * step(mx, 0.29) + step(0.71, mx) * step(mx, 0.78));
					sil = clamp(bed + headb + tbl + leg, 0.0, 1.0);
				} else if (cat == 1) {
					// Office desk + chair back silhouette.
					float desk = step(-0.50, my) * step(my, -0.40) * step(-0.72, mx) * step(mx, 0.65);
					float legs = step(-1.0, my) * step(my, -0.50) * (step(-0.68, mx) * step(mx, -0.56) + step(0.50, mx) * step(mx, 0.62));
					float chair = step(-0.40, my) * step(my, 0.0) * step(-0.22, mx) * step(mx, 0.16);
					sil = clamp(desk + legs + chair, 0.0, 1.0);
				} else if (cat == 2) {
					// Workshop bench + bulky tool/machine silhouette + hanging cord.
					float bench = step(-1.0, my) * step(my, -0.32) * step(-0.85, mx) * step(mx, 0.65);
					float mach = step(-0.32, my) * step(my, 0.14) * step(0.10, mx) * step(mx, 0.58);
					float cord = step(0.32, my) * step(abs(mx + 0.15), 0.03);
					sil = clamp(bench + mach + cord, 0.0, 1.0);
				} else if (cat == 3) {
					// Industrial stanchion + heavy machinery + overhead pipe.
					float post = step(abs(mx - 0.35), 0.08);
					float unit = step(-1.0, my) * step(my, 0.10) * step(-0.82, mx) * step(mx, -0.08);
					float pipe = step(0.56, my) * step(my, 0.70);
					sil = clamp(post + unit + pipe, 0.0, 1.0);
				} else if (cat == 4 && h_var > 0.5) {
					// Empty room: lone abandoned crate on floor.
					sil = step(-1.0, my) * step(my, -0.54) * step(0.15, mx) * step(mx, 0.58);
				}
				// Occasional quiet inhabitant silhouette (~12% of lit rooms, subtle breathing sway).
				float h_occ = hash12(sid + vec2(241.7, 67.3));
				if (cat <= 2 && h_occ < 0.14) {
					float ox = (h_occ / 0.14 - 0.5) * 0.7 + sin(TIME * 0.55 + h_cat * 40.0) * 0.02;
					float body_s = step(-0.78, my) * step(my, 0.08) * step(abs(mx - ox), 0.13);
					float head_s = step(0.08, my) * step(my, 0.28) * step(abs(mx - ox), 0.075);
					sil = max(sil, clamp(body_s + head_s, 0.0, 1.0));
				}
				// Dark silhouettes absorb most interior light, preserving readable rim contrast.
				interior = mix(interior, interior * 0.12, sil * detail_k);
			}
		}
	}

	// Apply partial curtains / blinds + top rod over the interior view.
	if (curt_mask > 0.5) {
		// Unlit rooms: the cloth only catches a trace of street light, it never glows.
		vec3 curt_lit = (cat == 6) ? vec3(0.0030, 0.0026, 0.0022) : (lit_col * 0.34 * curt_tex * cat_gain);
		interior = mix(interior, curt_lit, 0.88);
	}
	if (detail_k > 0.1 && h_curt >= 0.30 && wuv.y > 0.95) {
		interior *= 0.25;
	}

	// Subtle interior window mullions on some residential/office windows near the camera.
	if (detail_k > 0.1 && h_var > 0.45 && (cat == 0 || cat == 1)) {
		float mull = max(step(abs(wuv.x - 0.5), 0.025), step(abs(wuv.y - 0.55), 0.025));
		interior = mix(interior, interior * 0.18, mull * detail_k);
	}

	if (cat == 6) {
		return interior * 0.45;
	}
	return interior * flick * energy * 0.98;
}
