class_name HydroponicSite
extends Node3D
## Agricultural / Hydroponic Bay 413-A (faithful megastructure-scale recreation of
## video_reference_350s.jpg): colossal 700 m x 600 m x 26 m grow-hall inside STK-0413
## with grated industrial floors, massive rust-steel structural columns and high warm
## amber sconces, 50+ receding rows of raised dark crop troughs filled with low-poly
## green foliage, continuous overhead magenta-pink (and foreground white-spectrum)
## grow-light tube strips dissolving into dusty purple agricultural haze, foreground
## break-table vignette, workers, harvest crate, and agronomist log.

const WALL_H := 26.0
const ENTRY_HALF := 14.0


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var r: Array = site.rect # [x0, z0, x1, z1] -> [-2940, -700, -2240, -100]
	var h := HydroponicSite.new()
	var cx := (float(r[0]) + float(r[2])) * 0.5
	var cz := (float(r[1]) + float(r[3])) * 0.5
	h.position = Vector3(cx, 0.0, cz)
	h._build(float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
	return h


func _build(W: float, D: float) -> void:
	var hw := W * 0.5 # 350 m
	var hd := D * 0.5 # 300 m
	# Main south arrival doorway aligns with STK-0413 Arrival Plaza north edge (stack x = -2827 -> local x = -237).
	var entry_x := -237.0
	var preserve_x := 0.0
	var body := StaticBody3D.new()
	body.name = "HydroCollision"
	body.set_meta(&"surface", "metal")
	add_child(body)

	# 1. Grated steel floor (y = 0.07 above STK-0413 Arrival Plaza 0.03 so zero floor z-fight) & colossal 700 x 600 x 26 m shell.
	SliceMaterials.add_box(self, body, Vector3(0, -0.03, 0), Vector3(W, 0.2, D), &"bridge_deck")
	var wt := 2.4
	# North wall splits around a grand 32 m x 14 m bulkhead passage into Ecological Preserve 413-B (z = -hd).
	var p_half := 16.0
	var nw_l := (preserve_x - p_half) - (-hw)
	var nw_r := hw - (preserve_x + p_half)
	SliceMaterials.add_box(self, body, Vector3(-hw + nw_l * 0.5, WALL_H * 0.5, -hd + wt * 0.5), Vector3(nw_l, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(preserve_x + p_half + nw_r * 0.5, WALL_H * 0.5, -hd + wt * 0.5), Vector3(nw_r, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(preserve_x, 14.0 + (WALL_H - 14.0) * 0.5, -hd + wt * 0.5), Vector3(p_half * 2.0, WALL_H - 14.0, wt), &"industrial_wall")
	SliceMaterials.add_sign(self, Vector3(preserve_x, 15.2, -hd + wt + 0.16),
		"↑ ECOLOGICAL PRESERVE 413-B  ·  BIOSPHERE ATRIUM", 0.026, Color(0.86, 0.96, 0.88), 0.0)
	# West, East perimeter walls + dark industrial roof slab.
	SliceMaterials.add_box(self, body, Vector3(-hw + wt * 0.5, WALL_H * 0.5, 0), Vector3(wt, WALL_H, D - 2.0 * wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(hw - wt * 0.5, WALL_H * 0.5, 0), Vector3(wt, WALL_H, D - 2.0 * wt), &"industrial_wall")
	SliceMaterials.add_box(self, null, Vector3(0, WALL_H + 1.0, 0), Vector3(W + 0.4, 2.0, D + 0.4), &"structure", false)
	# South wall facing STK-0413 Arrival Plaza: split around wide 28 m archway at entry_x.
	var sw_l := (entry_x - ENTRY_HALF) - (-hw)
	var sw_r := hw - (entry_x + ENTRY_HALF)
	SliceMaterials.add_box(self, body, Vector3(-hw + sw_l * 0.5, WALL_H * 0.5, hd - wt * 0.5), Vector3(sw_l, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(entry_x + ENTRY_HALF + sw_r * 0.5, WALL_H * 0.5, hd - wt * 0.5), Vector3(sw_r, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(entry_x, 11.0 + (WALL_H - 11.0) * 0.5, hd - wt * 0.5), Vector3(ENTRY_HALF * 2.0, WALL_H - 11.0, wt), &"industrial_wall")
	# Exterior entrance lintel sign facing south (+Z) toward STK-0413 Arrival Plaza.
	SliceMaterials.add_box(self, null, Vector3(entry_x, 12.0, hd + 0.14), Vector3(22.0, 1.8, 0.18), &"structure", false)
	SliceMaterials.add_sign(self, Vector3(entry_x, 12.0, hd + 0.28),
		"HYDROPONIC BAY 413-A  ·  SECTOR 77-W", 0.026, Color(1.0, 0.72, 0.95), 0.0)
	SliceMaterials.add_box(self, null, Vector3(entry_x, 10.9, hd + 0.06), Vector3(24.0, 0.20, 0.20), &"grow_magenta", false)
	SliceMaterials.add_coronas(self, [Vector3(entry_x - 8.0, 10.8, hd + 0.25), Vector3(entry_x + 8.0, 10.8, hd + 0.25)], 4.0, &"corona_magenta")

	# 2. Monumental rust-dark structural columns (2.4 x 26 x 2.4 m) & high warm amber sconces (350s).
	var cols: Array = []
	var col_sconces: Array = []
	var sconce_glows: Array = []
	var steel: Array = []
	var col_step_x := 36.0
	var col_step_z := 34.0
	var cx_c := entry_x - 76.8 # aligns a monumental column line right at entry_x - 4.8 (exact 350s foreground column!)
	while cx_c < hw - 18.0:
		var cz_c := -hd + 28.0
		while cz_c < hd - 16.0:
			cols.append({ "c": Vector3(cx_c, WALL_H * 0.5, cz_c), "s": Vector3(2.4, WALL_H, 2.4) })
			SliceMaterials.add_collision_box(body, Vector3(cx_c, 2.2, cz_c), Vector3(2.4, 4.4, 2.4))
			if absf(cx_c - entry_x) < 120.0 and cz_c > -40.0:
				col_sconces.append({ "c": Vector3(cx_c + 1.28, 7.2, cz_c), "s": Vector3(0.28, 0.44, 0.30) })
				sconce_glows.append(Vector3(cx_c + 1.50, 7.2, cz_c))
			cz_c += col_step_z
		# Overhead longitudinal roof truss girder tying columns together.
		steel.append({ "c": Vector3(cx_c, WALL_H - 1.2, 0.0), "s": Vector3(1.2, 1.8, D - 5.0) })
		cx_c += col_step_x
	# Cross roof trusses every 68 m for authentic cavernous industrial ceiling depth.
	var cz_t := -hd + 34.0
	while cz_t < hd - 20.0:
		steel.append({ "c": Vector3(0.0, WALL_H - 2.6, cz_t), "s": Vector3(W - 6.0, 1.4, 1.0) })
		cz_t += 68.0
	# Foreground lower horizontal structural tie-beam on left column line (exact 350s detail).
	cols.append({ "c": Vector3(entry_x - 4.8, 0.90, hd - 21.0), "s": Vector3(0.65, 0.48, 34.0) })
	SliceMaterials.add_multimesh(self, cols, &"container_rust")
	SliceMaterials.add_multimesh(self, col_sconces, &"lamp")
	SliceMaterials.add_coronas(self, sconce_glows, 2.4, &"corona_soft")

	# 3. Endless receding rows of raised hydroponic crop troughs + lush low-poly foliage + magenta grow-tubes.
	var troughs: Array = []
	var crop_bright: Array = []
	var crop_dark: Array = []
	var tubes_magenta: Array = []
	var tubes_white: Array = []
	var tube_coronas: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 41350

	# Build ~54 parallel crop rows spanning the entire 700 m width, aligned cleanly around the main entry aisle!
	var row_xs: Array[float] = []
	# Left of entry_x
	var rx_l := entry_x - 10.5
	while rx_l > -hw + 10.0:
		row_xs.append(rx_l)
		rx_l -= 12.5
	# Right of entry_x
	var rx_r := entry_x + 6.5
	while rx_r < hw - 10.0:
		row_xs.append(rx_r)
		rx_r += 12.5
	row_xs.sort()

	var bay_step_z := 22.0
	var bay_len := 18.6
	var bay_w := 3.0
	for rx: float in row_xs:
		# Keep a clean wide cross-aisle leading to the Preserve north portal at preserve_x.
		var near_entry_aisle := absf(rx - entry_x) < 12.0
		var near_preserve_aisle := absf(rx - preserve_x) < 16.0
		var bz := -hd + 24.0
		while bz < hd - 18.0:
			# Leave open staging apron just inside south entry archway & north preserve portal.
			if near_entry_aisle and bz > hd - 38.0:
				bz += bay_step_z
				continue
			if near_preserve_aisle and bz < -hd + 34.0:
				bz += bay_step_z
				continue
			troughs.append({ "c": Vector3(rx, 0.88, bz), "s": Vector3(bay_w, 0.44, bay_len) })
			# Collide near the walkable entry/central/preserve corridors (avoid 10,000 tiny distant boxes).
			if absf(rx - entry_x) < 140.0 or absf(rx - preserve_x) < 120.0:
				SliceMaterials.add_collision_box(body, Vector3(rx, 0.55, bz), Vector3(bay_w, 1.1, bay_len))
			for lx_leg: float in [-bay_w * 0.44, bay_w * 0.44]:
				for lz_leg: float in [-bay_len * 0.44, bay_len * 0.44]:
					steel.append({ "c": Vector3(rx + lx_leg, 0.34, bz + lz_leg), "s": Vector3(0.11, 0.68, 0.11) })
			# Dense detailed foliage near the primary sightline/aisles; broader clusters in far bays for high FPS.
			var dist_vis := minf(absf(rx - entry_x), absf(rx - preserve_x))
			if dist_vis < 95.0 and bz > -140.0:
				var zc := bz - bay_len * 0.45
				while zc < bz + bay_len * 0.46:
					for subx: float in [-0.85, 0.0, 0.85]:
						var h_leaf := rng.randf_range(0.28, 0.52)
						var w_leaf := rng.randf_range(0.65, 1.05)
						var rot := Vector3(rng.randf_range(-0.22, 0.22), rng.randf() * TAU, rng.randf_range(-0.22, 0.22))
						var item := { "c": Vector3(rx + subx + rng.randf_range(-0.14, 0.14), 1.14 + h_leaf * 0.42, zc + rng.randf_range(-0.20, 0.20)), "s": Vector3(w_leaf, h_leaf, w_leaf * 0.88), "r": rot }
						if rng.randf() < 0.62:
							crop_bright.append(item)
						else:
							crop_dark.append(item)
					zc += 2.2
			else:
				# Efficient broad lush foliage mounds for far-horizon receding rows.
				for k_m in 3:
					var zm := bz + (float(k_m) - 1.0) * (bay_len * 0.31)
					var item := { "c": Vector3(rx, 1.32, zm), "s": Vector3(bay_w * 0.92, 0.44, bay_len * 0.29), "r": Vector3(0, rng.randf_range(-0.08, 0.08), 0) }
					if (k_m + int(absf(rx))) % 2 == 0:
						crop_bright.append(item)
					else:
						crop_dark.append(item)
			bz += bay_step_z

		# Continuous suspended linear grow-light tube rails stretching the entire 600 m hall depth!
		var tz := -hd + 12.0
		var seg_len := 28.0
		while tz < hd - 16.0:
			var tmid := tz + seg_len * 0.5
			steel.append({ "c": Vector3(rx, 4.55, tmid), "s": Vector3(0.24, 0.09, seg_len - 0.5) })
			if absf(rx - entry_x) < 160.0:
				steel.append({ "c": Vector3(rx, 15.2, tz + 1.5), "s": Vector3(0.06, 21.4, 0.06) })
			# Iconic foreground white-spectrum strip on the left central row (exact 350s visual signature!).
			var is_white := (absf(rx - (entry_x - 10.5)) < 1.0 and tz > hd - 62.0)
			if is_white:
				tubes_white.append({ "c": Vector3(rx, 4.44, tmid), "s": Vector3(0.22, 0.10, seg_len - 1.0) })
			else:
				tubes_magenta.append({ "c": Vector3(rx, 4.44, tmid), "s": Vector3(0.20, 0.09, seg_len - 1.0) })
			if absf(rx - entry_x) < 90.0 and int(roundf(tz)) % 56 == 0:
				tube_coronas.append(Vector3(rx, 4.30, tmid))
			tz += seg_len

	SliceMaterials.add_multimesh(self, steel, &"structure")
	SliceMaterials.add_multimesh(self, troughs, &"wood_dark")
	SliceMaterials.add_multimesh(self, crop_bright, &"crop_green")
	SliceMaterials.add_multimesh(self, crop_dark, &"crop_dark")
	SliceMaterials.add_multimesh(self, tubes_magenta, &"grow_magenta")
	SliceMaterials.add_multimesh(self, tubes_white, &"lamp_cool")
	SliceMaterials.add_coronas(self, tube_coronas, 2.6, &"corona_magenta")

	# 4. Wide magenta-white grow-light pools across the walkable aisles + warm column sconces.
	var mag_col := Color(1.0, 0.68, 0.94)
	for lx_off: float in [-70.0, -24.0, 8.0, 52.0, 120.0, 237.0]:
		for lz_p: float in [-240.0, -140.0, -40.0, 60.0, 160.0, 250.0]:
			var l := SliceMaterials.make_lamp_light(mag_col, 3.0, 48.0)
			l.position = Vector3(entry_x + lx_off, 5.2, lz_p)
			l.distance_fade_begin = 160.0
			l.distance_fade_length = 60.0
			add_child(l)
	for wz: float in [hd - 40.0, hd - 74.0, hd - 108.0]:
		var wl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.4, 18.0)
		wl.position = Vector3(entry_x - 3.2, 7.0, wz)
		add_child(wl)

	# 5. Foreground 350s break-table vignette + harvest crate + agronomist log right inside south entry.
	var fg_z := hd - 18.0
	SliceMaterials.add_box(self, body, Vector3(entry_x - 1.6, 0.36, fg_z), Vector3(0.95, 0.72, 0.85), &"container_grey")
	SliceMaterials.add_box(self, body, Vector3(entry_x - 1.6, 0.76, fg_z), Vector3(1.15, 0.08, 1.05), &"wood")
	SliceMaterials.add_box(self, null, Vector3(entry_x - 1.52, 0.86, fg_z - 0.08), Vector3(0.16, 0.12, 0.16), &"ceramic", false)
	SliceMaterials.add_box(self, body, Vector3(entry_x - 2.45, 0.24, fg_z + 0.2), Vector3(0.55, 0.48, 0.55), &"container_grey")
	SliceMaterials.add_box(self, body, Vector3(entry_x - 3.3, 0.22, fg_z + 1.2), Vector3(0.75, 0.44, 0.55), &"container_grey")
	SliceMaterials.add_box(self, null, Vector3(entry_x - 3.3, 0.52, fg_z + 1.2), Vector3(0.62, 0.22, 0.44), &"crop_green", false)

	add_child(LootContainer.create(
		"CONT-HYDRO-413", "Hydroponics Harvest Crate", "crate",
		Vector3(entry_x + 6.2, 0.04, fg_z + 3.8), 0.0,
		[["ration_tin", 2], ["water_flask", 2], ["dried_strip", 2]], 5, 4))
	SliceMaterials.add_box(self, body, Vector3(entry_x + 6.2, 0.55, fg_z + 0.8), Vector3(0.85, 1.1, 0.60), &"plate")
	add_child(ReadableNote.create(
		"NOTE-HYDRO-413", "Bay 413-A Agronomist Log",
		"STK-0413 — HYDROPONIC BAY 413-A (FLOOR 77)\n\n"
		+ "54 rows across 700 x 600 m holding steady under 18-hour magenta cycles.\n"
		+ "Harvest crates ship west across BR-077-A whenever the maintenance\n"
		+ "rail tram is powered; follow the central avenue 600 m north to reach\n"
		+ "Ecological Preserve 413-B.",
		Vector3(entry_x + 6.2, 1.12, fg_z + 0.8), 0.0, "paper"))

	# 6. Agricultural workers tending the endless aisles (hat silhouettes via Crowd).
	var crowd := Crowd.new()
	crowd.name = "HydroWorkers"
	add_child(crowd)
	var statics := [
		{ "p": Vector3(entry_x - 2.35, 0.04, fg_z - 0.7), "yaw": 0.45 },
		{ "p": Vector3(entry_x - 2.8, 0.04, fg_z - 22.0), "yaw": -1.4 },
		{ "p": Vector3(entry_x + 2.4, 0.04, fg_z - 28.0), "yaw": 1.6 },
		{ "p": Vector3(entry_x + 1.8, 0.04, fg_z - 52.0), "yaw": 0.8 },
		{ "p": Vector3(entry_x - 16.5, 0.04, fg_z - 38.0), "yaw": 1.5 },
		{ "p": Vector3(entry_x + 13.0, 0.04, fg_z - 72.0), "yaw": -1.2 },
		{ "p": Vector3(entry_x - 4.0, 0.04, fg_z - 115.0), "yaw": 0.3 },
		{ "p": Vector3(entry_x + 19.0, 0.04, fg_z - 160.0), "yaw": -0.9 },
	]
	var walkers := [
		{ "a": Vector3(entry_x + 0.4, 0.04, -180.0), "b": Vector3(entry_x + 0.4, 0.04, fg_z - 12.0) },
		{ "a": Vector3(entry_x + 13.0, 0.04, -220.0), "b": Vector3(entry_x + 13.0, 0.04, fg_z - 18.0) },
		{ "a": Vector3(entry_x - 16.5, 0.04, -160.0), "b": Vector3(entry_x - 16.5, 0.04, fg_z - 20.0) },
		{ "a": Vector3(preserve_x + 2.0, 0.04, -hd + 20.0), "b": Vector3(preserve_x + 2.0, 0.04, 80.0) },
	]
	crowd.setup(statics, walkers, 4135, 0.15, 320.0)
