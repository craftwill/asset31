class_name HydroponicSite
extends Node3D
## Agricultural / Hydroponic Bay 413-A (faithful recreation of video_reference_350s.jpg).
## Grated industrial floor, rust-steel columns with high warm sconces, receding rows
## of raised dark crop troughs filled with low-poly green foliage, overhead suspended
## magenta-pink (and occasional white-spectrum) grow-light tube strips, sparse hat-wearing
## agricultural workers, foreground break-table vignette, harvest crate, and agronomist log.

const WALL_H := 14.0
const ENTRY_HALF := 11.0


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var r: Array = site.rect # [x0, z0, x1, z1]
	var h := HydroponicSite.new()
	var cx := (float(r[0]) + float(r[2])) * 0.5
	var cz := (float(r[1]) + float(r[3])) * 0.5
	h.position = Vector3(cx, 0.0, cz)
	h._build(float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
	return h


func _build(W: float, D: float) -> void:
	var hw := W * 0.5
	var hd := D * 0.5
	var body := StaticBody3D.new()
	body.name = "HydroCollision"
	body.set_meta(&"surface", "metal")
	add_child(body)

	# 1. Grated steel floor (y = 0.04 above stack slab) & dark industrial shell.
	SliceMaterials.add_box(self, body, Vector3(0, -0.06, 0), Vector3(W, 0.2, D), &"bridge_deck")
	var wt := 1.6
	# North wall splits around a 18 m x 9 m bulkhead passage into Ecological Preserve 413-B (450s/475s).
	var p_half := 9.0
	var n_side_w := hw - p_half
	SliceMaterials.add_box(self, body, Vector3(-p_half - n_side_w * 0.5, WALL_H * 0.5, -hd + wt * 0.5), Vector3(n_side_w, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(p_half + n_side_w * 0.5, WALL_H * 0.5, -hd + wt * 0.5), Vector3(n_side_w, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(0, 9.0 + (WALL_H - 9.0) * 0.5, -hd + wt * 0.5), Vector3(p_half * 2.0, WALL_H - 9.0, wt), &"industrial_wall")
	SliceMaterials.add_sign(self, Vector3(0, 9.6, -hd + wt + 0.12),
		"↑ ECOLOGICAL PRESERVE 413-B  ·  ATRIUM", 0.018, Color(0.86, 0.96, 0.88), 0.0)
	# West, East perimeter walls + ceiling slab.
	SliceMaterials.add_box(self, body, Vector3(-hw + wt * 0.5, WALL_H * 0.5, 0), Vector3(wt, WALL_H, D - 2.0 * wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(hw - wt * 0.5, WALL_H * 0.5, 0), Vector3(wt, WALL_H, D - 2.0 * wt), &"industrial_wall")
	SliceMaterials.add_box(self, null, Vector3(0, WALL_H + 0.6, 0), Vector3(W + 0.4, 1.2, D + 0.4), &"structure", false)
	# South wall facing STK-0413 Arrival Plaza: split around wide 22 m open archway (h = 9.0 m).
	var side_w := hw - ENTRY_HALF
	SliceMaterials.add_box(self, body, Vector3(-ENTRY_HALF - side_w * 0.5, WALL_H * 0.5, hd - wt * 0.5), Vector3(side_w, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(ENTRY_HALF + side_w * 0.5, WALL_H * 0.5, hd - wt * 0.5), Vector3(side_w, WALL_H, wt), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(0, 9.0 + (WALL_H - 9.0) * 0.5, hd - wt * 0.5), Vector3(ENTRY_HALF * 2.0, WALL_H - 9.0, wt), &"industrial_wall")
	# Exterior entrance lintel sign facing south (+Z) toward STK-0413 Arrival Plaza.
	SliceMaterials.add_box(self, null, Vector3(0, 9.8, hd + 0.12), Vector3(16.0, 1.4, 0.16), &"structure", false)
	SliceMaterials.add_sign(self, Vector3(0, 9.8, hd + 0.26),
		"HYDROPONIC BAY 413-A  ·  SECTOR 77-W", 0.022, Color(1.0, 0.72, 0.95), 0.0)
	# Subtle magenta entry strip so the bay is legible from across the dark arrival plaza.
	SliceMaterials.add_box(self, null, Vector3(0, 8.9, hd + 0.05), Vector3(18.0, 0.16, 0.16), &"grow_magenta", false)
	SliceMaterials.add_coronas(self, [Vector3(-6.0, 8.85, hd + 0.2), Vector3(6.0, 8.85, hd + 0.2)], 3.0, &"corona_magenta")

	# 2. Monumental rust-dark structural columns along the hall + high warm amber sconces (350s).
	var cols: Array = []
	var col_sconces: Array = []
	var sconce_glows: Array = []
	var steel: Array = []
	var col_xs := [-52.0, -26.0, -4.8, 13.5, 39.0, 62.0]
	var col_zs := [-42.0, -18.0, 6.0, 30.0, 48.0]
	for cx: float in col_xs:
		for cz: float in col_zs:
			cols.append({ "c": Vector3(cx, WALL_H * 0.5, cz), "s": Vector3(1.5, WALL_H, 1.5) })
			SliceMaterials.add_collision_box(body, Vector3(cx, 2.0, cz), Vector3(1.5, 4.0, 1.5))
			# High warm amber column sconce matching the tiny amber glow in 350s.
			if absf(cx) < 30.0 and cz > -25.0:
				col_sconces.append({ "c": Vector3(cx + 0.82, 6.6, cz), "s": Vector3(0.22, 0.36, 0.26) })
				sconce_glows.append(Vector3(cx + 1.0, 6.6, cz))
		# Overhead longitudinal roof girder tying columns together.
		steel.append({ "c": Vector3(cx, WALL_H - 0.8, 0.0), "s": Vector3(0.9, 1.2, D - 3.0) })
	# Foreground lower horizontal structural tie-beam on left column line (exact 350s detail).
	cols.append({ "c": Vector3(-4.8, 0.85, 39.0), "s": Vector3(0.55, 0.42, 18.0) })
	SliceMaterials.add_multimesh(self, cols, &"container_rust")
	SliceMaterials.add_multimesh(self, col_sconces, &"lamp")
	SliceMaterials.add_coronas(self, sconce_glows, 2.0, &"corona_soft")

	# 3. Raised hydroponic crop trough rows + layered low-poly green foliage + overhead magenta grow-tubes.
	var troughs: Array = []
	var crop_bright: Array = []
	var crop_dark: Array = []
	var tubes_magenta: Array = []
	var tubes_white: Array = []
	var tube_coronas: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 41350
	var row_xs := [-62.0, -48.0, -34.0, -20.0, -10.5, 6.5, 19.5, 32.5, 45.5, 58.5]
	var bay_zs := [-46.0, -29.0, -12.0, 5.0, 22.0, 38.0]
	for ri in row_xs.size():
		var rx: float = row_xs[ri]
		for bi in bay_zs.size():
			var bz: float = bay_zs[bi]
			# Skip the foreground south-center bay on x = -10.5 / +6.5 closest to entry so entrance opens cleanly.
			if bi == 5 and (rx == -10.5 or rx == 6.5):
				continue
			var blen := 13.8
			var bw := 2.6
			# Dark wood/steel trough bed + 4 corner legs.
			troughs.append({ "c": Vector3(rx, 0.88, bz), "s": Vector3(bw, 0.42, blen) })
			SliceMaterials.add_collision_box(body, Vector3(rx, 0.55, bz), Vector3(bw, 1.1, blen))
			for lx: float in [-bw * 0.44, bw * 0.44]:
				for lz: float in [-blen * 0.44, 0.0, blen * 0.44]:
					steel.append({ "c": Vector3(rx + lx, 0.34, bz + lz), "s": Vector3(0.10, 0.68, 0.10) })
			# Layered low-poly hydroponic green leaf clusters filling the bed.
			var zc := bz - blen * 0.45
			while zc < bz + blen * 0.46:
				for subx: float in [-0.72, 0.0, 0.72]:
					var h_leaf := rng.randf_range(0.24, 0.46)
					var w_leaf := rng.randf_range(0.55, 0.88)
					var rot := Vector3(rng.randf_range(-0.22, 0.22), rng.randf() * TAU, rng.randf_range(-0.22, 0.22))
					var item := { "c": Vector3(rx + subx + rng.randf_range(-0.12, 0.12), 1.12 + h_leaf * 0.42, zc + rng.randf_range(-0.18, 0.18)), "s": Vector3(w_leaf, h_leaf, w_leaf * 0.85), "r": rot }
					if rng.randf() < 0.62:
						crop_bright.append(item)
					else:
						crop_dark.append(item)
				zc += 1.45
		# Continuous suspended linear grow-light tube rail running directly above every crop row.
		var tz := -52.0
		while tz < 48.0:
			var tlen := 13.5
			var tmid := tz + tlen * 0.5
			steel.append({ "c": Vector3(rx, 4.42, tmid), "s": Vector3(0.22, 0.08, tlen) })
			steel.append({ "c": Vector3(rx, 9.2, tz + 1.0), "s": Vector3(0.05, 9.5, 0.05) })
			# Single foreground white-spectrum tube strip on the left central row (exact 350s visual signature!).
			var is_white := (ri == 4 and tz > 18.0)
			if is_white:
				tubes_white.append({ "c": Vector3(rx, 4.32, tmid), "s": Vector3(0.18, 0.08, tlen - 0.4) })
			else:
				tubes_magenta.append({ "c": Vector3(rx, 4.32, tmid), "s": Vector3(0.18, 0.08, tlen - 0.4) })
			if absf(rx) < 38.0 and int(roundf(tz)) % 27 == 0:
				tube_coronas.append(Vector3(rx, 4.22, tmid))
			tz += 14.0
	SliceMaterials.add_multimesh(self, steel, &"structure")
	SliceMaterials.add_multimesh(self, troughs, &"wood_dark")
	SliceMaterials.add_multimesh(self, crop_bright, &"crop_green")
	SliceMaterials.add_multimesh(self, crop_dark, &"crop_dark")
	SliceMaterials.add_multimesh(self, tubes_magenta, &"grow_magenta")
	SliceMaterials.add_multimesh(self, tubes_white, &"lamp_cool")
	SliceMaterials.add_coronas(self, tube_coronas, 2.2, &"corona_magenta")

	# 4. Restrained practical magenta-white grow-light pools + 2 warm column accent lights.
	var mag_col := Color(1.0, 0.70, 0.94)
	for lx: float in [-24.0, -4.0, 14.0, 34.0]:
		for lz: float in [-32.0, -4.0, 24.0, 44.0]:
			var l := SliceMaterials.make_lamp_light(mag_col, 2.2, 26.0)
			l.position = Vector3(lx, 3.6, lz)
			l.distance_fade_begin = 110.0
			l.distance_fade_length = 40.0
			add_child(l)
	for wz: float in [6.0, 30.0]:
		var wl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.1, 14.0)
		wl.position = Vector3(-3.6, 6.4, wz)
		add_child(wl)

	# 5. Foreground 350s break-table vignette + harvest crate + agronomist log.
	# Small crate table & stool in the south-central aisle (x = -1.6, z = 42.0).
	SliceMaterials.add_box(self, body, Vector3(-1.6, 0.36, 42.0), Vector3(0.95, 0.72, 0.85), &"container_grey")
	SliceMaterials.add_box(self, body, Vector3(-1.6, 0.76, 42.0), Vector3(1.15, 0.08, 1.05), &"wood")
	SliceMaterials.add_box(self, null, Vector3(-1.52, 0.86, 41.92), Vector3(0.16, 0.12, 0.16), &"ceramic", false)
	SliceMaterials.add_box(self, body, Vector3(-2.45, 0.24, 42.2), Vector3(0.55, 0.48, 0.55), &"container_grey")
	# Small sprouting tray crate resting on the grate nearby.
	SliceMaterials.add_box(self, body, Vector3(-3.3, 0.22, 43.2), Vector3(0.75, 0.44, 0.55), &"container_grey")
	SliceMaterials.add_box(self, null, Vector3(-3.3, 0.52, 43.2), Vector3(0.62, 0.22, 0.44), &"crop_green", false)

	add_child(LootContainer.create(
		"CONT-HYDRO-413", "Hydroponics Harvest Crate", "crate",
		Vector3(6.2, 0.04, 45.8), 0.0,
		[["ration_tin", 2], ["water_flask", 2], ["dried_strip", 2]], 5, 4))
	SliceMaterials.add_box(self, body, Vector3(6.2, 0.55, 42.8), Vector3(0.85, 1.1, 0.60), &"plate")
	add_child(ReadableNote.create(
		"NOTE-HYDRO-413", "Bay 413-A Agronomist Log",
		"STK-0413 — HYDROPONIC BAY 413-A (FLOOR 77)\n\n"
		+ "Nutrient mist lines holding steady under 18-hour magenta cycles.\n"
		+ "Harvest crates ship west across BR-077-A whenever the maintenance\n"
		+ "rail tram is powered; bridge walkers may take a ration tin from\n"
		+ "the south staging crate before returning across the chasm.",
		Vector3(6.2, 1.12, 42.8), 0.0, "paper"))

	# 6. Sparse agricultural workers tending the aisles (hat silhouettes via Crowd).
	var crowd := Crowd.new()
	crowd.name = "HydroWorkers"
	add_child(crowd)
	var statics := [
		{ "p": Vector3(-2.35, 0.04, 41.3), "yaw": 0.45 },
		{ "p": Vector3(-2.8, 0.04, 21.0), "yaw": -1.4 },
		{ "p": Vector3(2.4, 0.04, 15.0), "yaw": 1.6 },
		{ "p": Vector3(1.8, 0.04, -6.0), "yaw": 0.8 },
		{ "p": Vector3(-15.2, 0.04, 4.0), "yaw": 1.5 },
		{ "p": Vector3(13.0, 0.04, -22.0), "yaw": -1.2 },
	]
	var walkers := [
		{ "a": Vector3(0.4, 0.04, -38.0), "b": Vector3(0.4, 0.04, 30.0) },
		{ "a": Vector3(13.0, 0.04, -40.0), "b": Vector3(13.0, 0.04, 26.0) },
		{ "a": Vector3(-15.5, 0.04, -32.0), "b": Vector3(-15.5, 0.04, 24.0) },
	]
	crowd.setup(statics, walkers, 4135, 0.15, 220.0)
