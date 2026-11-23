class_name MiningShaft
extends WorldAnchor
## Colossal cylindrical mining elevator shaft (frame 175s, brief §0.1 canon):
## connects Floor 77 toward Asset 31's excavated planetary surface 41 km below.
## Features a 24-sided lit inner cylinder wall, concentric structural ring
## girders, 8 interior vertical lattice towers with moving elevator cars, 3
## vertical strata (inhabited hub -> heavy ore-haulage infrastructure -> deep
## excavation abyss & planetary crust glow), a walkable truss catwalk spur
## directly from STK-0412's East Edge Gate, and a rideable 220 m service lift
## with a live altitude readout down to Undercroft 76-B (40,780 m).

const SIDES := 24
const LOWER_DROP := 220.0

var def: Dictionary
var _cars: Array = []
var _bottom := -2200.0
var _top := 1400.0


static func build(sdef: Dictionary) -> MiningShaft:
	var m := MiningShaft.new()
	m.def = sdef
	m.name = sdef.id
	var p: Array = sdef.position
	m.lx = float(p[0])
	m.ly = float(p[1])
	m.lz = float(p[2])
	m._build()
	return m


func _build() -> void:
	var R := float(def.get("radius", 150.0))
	_bottom = -float(def.get("depth", 2200.0))
	_top = float(def.get("height", 1400.0))
	var h := _top - _bottom
	var cy := (_top + _bottom) * 0.5
	var body := StaticBody3D.new()
	body.name = "Collision"
	body.set_meta(&"surface", "metal")
	add_child(body)

	# 1. 24-sided cylindrical outer shaft shell (inward faces show warm city-like
	# shaft lights & floor bands matching reference 175s). Leave a clean portal
	# gap on the west facet (-X, i == SIDES/2) around y = 0 for the catwalk entry.
	var walls: Array = []
	var rings: Array = []
	var chord := 2.0 * R * tan(PI / float(SIDES))
	var wall_t := 8.0
	for i in SIDES:
		var ang := float(i) * TAU / float(SIDES)
		var nx := cos(ang)
		var nz := sin(ang)
		var r_mid := R + wall_t * 0.5
		var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
		var is_west_entry := (i == SIDES / 2)
		if is_west_entry:
			# Split west facet above and below the catwalk portal (y in [-12, +18]).
			var h_low := -12.0 - _bottom
			var h_hi := _top - 18.0
			walls.append({ "c": Vector3(nx * r_mid, _bottom + h_low * 0.5, nz * r_mid), "s": Vector3(chord + 1.0, h_low, wall_t), "r": rot, "seed": float(i) * 0.04 })
			walls.append({ "c": Vector3(nx * r_mid, 18.0 + h_hi * 0.5, nz * r_mid), "s": Vector3(chord + 1.0, h_hi, wall_t), "r": rot, "seed": float(i) * 0.04 })
		else:
			walls.append({ "c": Vector3(nx * r_mid, cy, nz * r_mid), "s": Vector3(chord + 1.0, h, wall_t), "r": rot, "seed": float(i) * 0.04 })
	SliceMaterials.add_multimesh(self, walls, &"shaft_wall")

	# 2. Concentric structural ring girders & glowing rim strips down the cylinder.
	var ring_lamps: Array = []
	var y := _bottom + 100.0
	while y < _top - 40.0:
		var is_portal_band := absf(y) < 30.0
		for i in SIDES:
			if is_portal_band and i == SIDES / 2:
				continue
			var ang := float(i) * TAU / float(SIDES)
			var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
			var r_in := R - 2.2
			rings.append({ "c": Vector3(cos(ang) * r_in, y, sin(ang) * r_in), "s": Vector3(chord, 4.2, 4.8), "r": rot })
			if int(roundf(absf(y) / 100.0)) % 1 == 0:
				ring_lamps.append({ "c": Vector3(cos(ang) * (R - 4.7), y + 2.3, sin(ang) * (R - 4.7)), "s": Vector3(chord * 0.9, 0.22, 0.22), "r": rot })
		y += 100.0
	SliceMaterials.add_multimesh(self, rings, &"structure")
	SliceMaterials.add_multimesh(self, ring_lamps, &"window_glow")

	# 3. Eight interior vertical steel lattice elevator towers + glowing guide rails + cars.
	var lattice: Array = []
	var guide_rails: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(def.id))
	var tower_r := R * 0.62
	for ti in 8:
		var ang := (float(ti) + 0.5) * TAU / 8.0
		var tx := cos(ang) * tower_r
		var tz := sin(ang) * tower_r
		var ts := 10.0
		for c in [Vector2(-ts * 0.5, -ts * 0.5), Vector2(ts * 0.5, -ts * 0.5), Vector2(-ts * 0.5, ts * 0.5), Vector2(ts * 0.5, ts * 0.5)]:
			lattice.append({ "c": Vector3(tx + c.x, cy, tz + c.y), "s": Vector3(1.1, h, 1.1) })
		# Vertical glowing amber guide strip along the inward face (iconic 175s orange verticals).
		guide_rails.append({ "c": Vector3(tx - cos(ang) * (ts * 0.5 + 0.6), cy, tz - sin(ang) * (ts * 0.5 + 0.6)), "s": Vector3(0.28, h, 0.28) })
		var by := _bottom + 25.0
		while by < _top - 20.0:
			lattice.append({ "c": Vector3(tx, by, tz - ts * 0.5), "s": Vector3(ts - 1.1, 0.6, 0.6) })
			lattice.append({ "c": Vector3(tx, by, tz + ts * 0.5), "s": Vector3(ts - 1.1, 0.6, 0.6) })
			lattice.append({ "c": Vector3(tx - ts * 0.5, by, tz), "s": Vector3(0.6, 0.6, ts - 1.1) })
			lattice.append({ "c": Vector3(tx + ts * 0.5, by, tz), "s": Vector3(0.6, 0.6, ts - 1.1) })
			by += 25.0
		if ti % 2 == 0:
			var car := Node3D.new()
			car.position = Vector3(tx, 0.0, tz)
			add_child(car)
			SliceMaterials.add_box(car, null, Vector3.ZERO, Vector3(ts + 3.0, 6.5, ts + 3.0), &"structure", false)
			SliceMaterials.add_box(car, null, Vector3(0, 0.5, 0), Vector3(ts + 3.4, 2.2, ts + 3.4), &"window_glow", false)
			SliceMaterials.add_coronas(car, [Vector3(0, 0.5, 0)], 14.0, &"corona_soft")
			_cars.append({ "node": car, "phase": rng.randf(), "speed": rng.randf_range(6.0, 14.0) })
	# Lower visual cross-spanning truss girders cutting across the abyss below (175s composition)
	# offset clear of the EL-DEEP-00 vertical express lane at (x = +11.5, z = +1.0),
	# plus vertical ore-haulage conveyor pipe columns along 4 diagonal ribs (Stratum II -> III).
	for ly_cross in [-135.0, -320.0, -560.0, -900.0, -1350.0]:
		lattice.append({ "c": Vector3(0, ly_cross, -26.0), "s": Vector3(R * 1.92, 3.2, 4.0) })
		lattice.append({ "c": Vector3(0, ly_cross, 26.0), "s": Vector3(R * 1.92, 3.2, 4.0) })
		lattice.append({ "c": Vector3(-26.0, ly_cross - 35.0, 0), "s": Vector3(4.0, 3.2, R * 1.92) })
		lattice.append({ "c": Vector3(26.0, ly_cross - 35.0, 0), "s": Vector3(4.0, 3.2, R * 1.92) })
	var pipe_h := 120.0 - (_bottom + 80.0)
	var pipe_cy := (120.0 + _bottom + 80.0) * 0.5
	var beacons: Array = []
	for k in 4:
		var pang := (float(k) + 0.5) * PI * 0.5
		var px := cos(pang) * (R - 9.0)
		var pz := sin(pang) * (R - 9.0)
		var tx_off := -sin(pang) * 2.2
		var tz_off := cos(pang) * 2.2
		lattice.append({ "c": Vector3(px - tx_off, pipe_cy, pz - tz_off), "s": Vector3(1.5, pipe_h, 1.5) })
		lattice.append({ "c": Vector3(px + tx_off, pipe_cy, pz + tz_off), "s": Vector3(1.5, pipe_h, 1.5) })
		for by_b in [-110.0, -220.0, -440.0, -800.0, -1300.0]:
			beacons.append({ "c": Vector3(cos(pang) * (R - 5.2), by_b, sin(pang) * (R - 5.2)), "s": Vector3(0.85, 0.85, 0.85) })
	SliceMaterials.add_multimesh(self, lattice, &"structure")
	SliceMaterials.add_multimesh(self, guide_rails, &"window_glow")
	SliceMaterials.add_multimesh(self, beacons, &"beacon_red")

	# Distant warm ember haze markers around the lower shaft throat (open center so EL-DEEP-00
	# descends continuously all 41 km through to CRUST-00 without clipping any cap slab).
	var abyss_y := _bottom + 40.0
	var deep_glows: Array = []
	for k in 4:
		var ang_d := float(k) * PI * 0.5 + PI * 0.25
		deep_glows.append(Vector3(cos(ang_d) * 78.0, abyss_y + 24.0, sin(ang_d) * 78.0))
	SliceMaterials.add_coronas(self, deep_glows, 48.0, &"corona_molten")

	# 4. Walkable steel truss catwalk from STK-0412 East Edge Gate (x_local = -220)
	# straight into the central observation hub (x_local = 0) and across to +R.
	var entry_x := -float(def.get("entry_dist", 220.0))
	_build_catwalk(body, entry_x, R)
	_build_lower_undercroft(body, R)
	_build_shaft_life()
	_update_cars()


func _build_catwalk(body: StaticBody3D, entry_x: float, R: float) -> void:
	var cw := 6.0
	var dt := 1.2
	# Approach + main spanning truss catwalk from gate edge (-220) to central hub (-7).
	var len_w := -7.0 - entry_x
	var cx_w := entry_x + len_w * 0.5
	SliceMaterials.add_box(self, body, Vector3(cx_w, -dt * 0.5, 0), Vector3(len_w, dt, cw), &"bridge_deck")
	SliceMaterials.add_box(self, null, Vector3(cx_w, -dt - 2.2, 0), Vector3(len_w, 4.0, cw - 0.8), &"structure", false)
	# Floor 77 East boarding threshold (+7.0 .. +9.34) directly feeding the 41 km EL-DEEP-00 bay
	# at x in [9.4, 13.6], z in [-1.1, +3.1], plus east continuation truss (+13.8 .. +R) for 175s symmetry.
	SliceMaterials.add_box(self, body, Vector3(8.17, -dt * 0.5, 0.0), Vector3(2.34, dt, cw), &"bridge_deck")
	SliceMaterials.add_box(self, null, Vector3(8.17, -dt - 2.2, 0.0), Vector3(2.20, 4.0, cw - 0.8), &"structure", false)
	var len_e := R - 13.8
	var cx_e := 13.8 + len_e * 0.5
	SliceMaterials.add_box(self, body, Vector3(cx_e, -dt * 0.5, 0), Vector3(len_e, dt, cw), &"bridge_deck")
	SliceMaterials.add_box(self, null, Vector3(cx_e, -dt - 2.2, 0), Vector3(len_e, 4.0, cw - 0.8), &"structure", false)

	# Central observation hub (14 x 14 m, leaving a 3.2 x 3.2 m bay on the south side for the service lift).
	SliceMaterials.add_box(self, body, Vector3(0, -dt * 0.5, 0), Vector3(14.0, dt, 14.0), &"bridge_deck")
	SliceMaterials.add_box(self, null, Vector3(0, -dt - 2.4, 0), Vector3(13.2, 4.4, 13.2), &"structure", false)

	# Glowing railings along both sides of the catwalk & hub perimeter.
	var rails: Array = []
	var posts: Array = []
	for s: float in [-1.0, 1.0]:
		var zr: float = s * (cw * 0.5 - 0.1)
		SliceMaterials.add_collision_box(body, Vector3(cx_w, 0.58, zr), Vector3(len_w, 1.15, 0.1))
		SliceMaterials.add_collision_box(body, Vector3(8.17, 0.58, zr), Vector3(2.34, 1.15, 0.1))
		SliceMaterials.add_collision_box(body, Vector3(cx_e, 0.58, zr), Vector3(len_e, 1.15, 0.1))
		rails.append({ "c": Vector3(cx_w, 1.11, zr), "s": Vector3(len_w, 0.07, 0.07) })
		rails.append({ "c": Vector3(8.17, 1.11, zr), "s": Vector3(2.34, 0.07, 0.07) })
		rails.append({ "c": Vector3(cx_e, 1.11, zr), "s": Vector3(len_e, 0.07, 0.07) })
		var px := entry_x + 2.0
		while px < R - 2.0:
			if px < -7.2 or px > 14.2:
				posts.append({ "c": Vector3(px, 0.535, zr), "s": Vector3(0.06, 1.07, 0.06) })
			px += 3.0
	# Short north-side safety barrier at x = 9.30 beside the EL-DEEP-00 boarding opening (z in [-3.0, -1.2])
	# plus west-facing end rail on the east continuation truss (x = 13.9).
	SliceMaterials.add_collision_box(body, Vector3(9.30, 0.58, -2.1), Vector3(0.1, 1.15, 1.8))
	rails.append({ "c": Vector3(9.30, 1.11, -2.1), "s": Vector3(0.07, 0.07, 1.8) })
	SliceMaterials.add_collision_box(body, Vector3(13.9, 0.58, 0.0), Vector3(0.15, 1.15, cw))
	rails.append({ "c": Vector3(13.9, 1.11, 0.0), "s": Vector3(0.07, 0.07, cw) })
	# Hub railings (north full, south opens at x in [-1.6, 1.6] for the service lift cage, west/east open for catwalk).
	SliceMaterials.add_collision_box(body, Vector3(0, 0.58, -6.9), Vector3(14.0, 1.15, 0.1))
	rails.append({ "c": Vector3(0, 1.11, -6.9), "s": Vector3(14.0, 0.07, 0.07) })
	SliceMaterials.add_collision_box(body, Vector3(-4.3, 0.58, 6.9), Vector3(5.4, 1.15, 0.1))
	SliceMaterials.add_collision_box(body, Vector3(4.3, 0.58, 6.9), Vector3(5.4, 1.15, 0.1))
	rails.append({ "c": Vector3(-4.3, 1.11, 6.9), "s": Vector3(5.4, 0.07, 0.07) })
	rails.append({ "c": Vector3(4.3, 1.11, 6.9), "s": Vector3(5.4, 0.07, 0.07) })
	for sx in [-6.9, 6.9]:
		for sz in [-4.95, 4.95]:
			SliceMaterials.add_collision_box(body, Vector3(sx, 0.58, sz), Vector3(0.1, 1.15, 3.9))
			rails.append({ "c": Vector3(sx, 1.11, sz), "s": Vector3(0.07, 0.07, 3.9) })
	# East catwalk dead-end barrier.
	SliceMaterials.add_collision_box(body, Vector3(R - 0.5, 0.58, 0), Vector3(0.2, 1.15, cw))
	rails.append({ "c": Vector3(R - 0.5, 1.11, 0), "s": Vector3(0.07, 0.07, cw) })
	SliceMaterials.add_multimesh(self, rails, &"rail_glow")
	SliceMaterials.add_multimesh(self, posts, &"structure_fade_near", 900.0)

	# Warm catwalk & hub lamps.
	var heads: Array = []
	var glows: Array = []
	var lx := entry_x + 16.0
	while lx < R - 16.0:
		var p := Vector3(lx, 4.2, -cw * 0.5 + 0.35 if absf(lx) > 8.0 else -6.4)
		SliceMaterials.add_box(self, null, p - Vector3(0, 2.1, 0), Vector3(0.14, 4.2, 0.14), &"structure", false)
		heads.append({ "c": p, "s": Vector3(0.45, 0.18, 0.45) })
		glows.append(p + Vector3(0, -0.15, 0))
		var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.8, 18.0)
		l.position = p + Vector3(0, -0.4, 0.6)
		add_child(l)
		lx += 36.0
	SliceMaterials.add_multimesh(self, heads, &"lamp")
	SliceMaterials.add_coronas(self, glows, 2.0, &"corona_soft")

	# Hub signboard on dark steel backing (posts sit slightly behind backing plate so zero face overlap).
	SliceMaterials.add_box(self, null, Vector3(-3.0, 1.85, -6.96), Vector3(0.08, 1.5, 0.08), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(3.0, 1.85, -6.96), Vector3(0.08, 1.5, 0.08), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(0.0, 2.35, -6.88), Vector3(6.4, 0.72, 0.10), &"structure", false)
	SliceMaterials.add_sign(self, Vector3(0, 2.35, -6.82),
		"MINING SHAFT 77-N  ·  DEPTH TO SURFACE: 41.0 KM", 0.0085, Color(1.0, 0.84, 0.54), 0.0)
	# Sacred Continuum emblem mounted on the shaft hub bulkhead (honoring the 41 km vertical axis).
	var sh_emb := ContinuumEmblem.create(0.75, &"copper", &"structure", false)
	sh_emb.position = Vector3(-4.2, 2.55, -6.78)
	add_child(sh_emb)
	SliceMaterials.add_box(self, null, Vector3(0.0, 2.35, 6.80), Vector3(5.4, 0.62, 0.10), &"structure", false)
	SliceMaterials.add_sign(self, Vector3(0, 2.35, 6.72),
		"SERVICE CAGE  ↓  UNDERCROFT 76-B (-220 M)", 0.0072, Color(1.0, 0.85, 0.55), PI)
	add_child(ReadableNote.create(
		"NOTE-SHAFT-77", "Shaft 77-N Operations Plaque",
		"ASSET 31 — DEEP EXCAVATION SHAFT 77-N\n"
		+ "Floor 77 Elevation: +41,000 m above original planetary crust.\n"
		+ "Mantle Steel Roof: ~60,000 m.\n\n"
		+ "Ore haulage cages run continuously to the lower mining surface.\n"
		+ "Steel raised from the buried planet builds the upper floors.\n"
		+ "Maintenance service cage (south bay) descends 220 m to Undercroft 76-B.",
		Vector3(-4.2, 1.35, -6.65), 0.0, "plaque"))

	# Industrial haulage dispatch terminal / kiosk tucked into the NE corner of the hub.
	SliceMaterials.add_box(self, body, Vector3(5.2, 1.05, -5.9), Vector3(1.5, 2.1, 0.72), &"plate")
	SliceMaterials.add_box(self, null, Vector3(5.2, 2.18, -5.82), Vector3(1.62, 0.14, 0.92), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(5.2, 1.44, -5.52), Vector3(0.76, 0.42, 0.05), &"window_glow", false)
	SliceMaterials.add_sign(self, Vector3(5.2, 1.88, -5.50), "HAULAGE DISPATCH · 77-N", 0.0038, Color(1.0, 0.84, 0.52), 0.0)

	# Rideable service cage descending 220 m down to the lower undercroft deck
	# (rotated PI so its open landing side faces -Z directly into the hub & undercroft).
	var lift := Lift.new()
	lift.position = Vector3(0.0, -LOWER_DROP, 8.6)
	lift.rotation.y = PI
	lift.top_height = LOWER_DROP
	lift.start_at_top = true
	lift.lift_speed = 7.5
	lift.show_altitude = true
	lift.base_logical_y = ly - LOWER_DROP
	add_child(lift)


func _build_lower_undercroft(body: StaticBody3D, _R: float) -> void:
	var y0 := -LOWER_DROP
	var dt := 1.0
	# Lower undercroft maintenance deck (18 x 12 m) directly north of the lift landing (z = 8.6)
	# plus a cantilevered north grate overlook spur extending over the 2 km drop.
	SliceMaterials.add_box(self, body, Vector3(0, y0 - dt * 0.5, 1.0), Vector3(18.0, dt, 12.0), &"bridge_deck")
	SliceMaterials.add_box(self, null, Vector3(0, y0 - dt - 1.6, 1.0), Vector3(17.2, 3.0, 11.2), &"structure", false)
	SliceMaterials.add_box(self, body, Vector3(0, y0 - dt * 0.5, -6.75), Vector3(6.4, dt, 3.5), &"bridge_deck")
	SliceMaterials.add_box(self, null, Vector3(0, y0 - dt - 1.2, -6.6), Vector3(5.8, 2.2, 3.0), &"structure", false)
	# Railings around the undercroft deck (south opens for lift; north opens onto overlook spur).
	var rails: Array = []
	SliceMaterials.add_collision_box(body, Vector3(-6.05, y0 + 0.58, -4.9), Vector3(5.7, 1.15, 0.1))
	SliceMaterials.add_collision_box(body, Vector3(6.05, y0 + 0.58, -4.9), Vector3(5.7, 1.15, 0.1))
	rails.append({ "c": Vector3(-6.05, y0 + 1.11, -4.9), "s": Vector3(5.7, 0.07, 0.07) })
	rails.append({ "c": Vector3(6.05, y0 + 1.11, -4.9), "s": Vector3(5.7, 0.07, 0.07) })
	SliceMaterials.add_collision_box(body, Vector3(0.0, y0 + 0.58, -8.4), Vector3(6.4, 1.15, 0.1))
	rails.append({ "c": Vector3(0.0, y0 + 1.11, -8.4), "s": Vector3(6.4, 0.07, 0.07) })
	for ox in [-3.1, 3.1]:
		SliceMaterials.add_collision_box(body, Vector3(ox, y0 + 0.58, -6.7), Vector3(0.1, 1.15, 3.5))
		rails.append({ "c": Vector3(ox, y0 + 1.11, -6.7), "s": Vector3(0.07, 0.07, 3.5) })
	SliceMaterials.add_collision_box(body, Vector3(-5.3, y0 + 0.58, 6.9), Vector3(7.4, 1.15, 0.1))
	SliceMaterials.add_collision_box(body, Vector3(5.3, y0 + 0.58, 6.9), Vector3(7.4, 1.15, 0.1))
	rails.append({ "c": Vector3(-5.3, y0 + 1.11, 6.9), "s": Vector3(7.4, 0.07, 0.07) })
	rails.append({ "c": Vector3(5.3, y0 + 1.11, 6.9), "s": Vector3(7.4, 0.07, 0.07) })
	# West railing full; east railing splits around z in [-1.2, +3.2] for the 41 km Deep Express Relay Cage.
	SliceMaterials.add_collision_box(body, Vector3(-8.9, y0 + 0.58, 1.0), Vector3(0.1, 1.15, 12.0))
	rails.append({ "c": Vector3(-8.9, y0 + 1.11, 1.0), "s": Vector3(0.07, 0.07, 12.0) })
	SliceMaterials.add_collision_box(body, Vector3(8.9, y0 + 0.58, -3.1), Vector3(0.1, 1.15, 3.8))
	SliceMaterials.add_collision_box(body, Vector3(8.9, y0 + 0.58, 5.1), Vector3(0.1, 1.15, 3.8))
	rails.append({ "c": Vector3(8.9, y0 + 1.11, -3.1), "s": Vector3(0.07, 0.07, 3.8) })
	rails.append({ "c": Vector3(8.9, y0 + 1.11, 5.1), "s": Vector3(0.07, 0.07, 3.8) })
	# Steel boarding threshold bridging Undercroft (+9.0) cleanly to DeepRelayLift west edge (+9.34).
	SliceMaterials.add_box(self, body, Vector3(9.17, y0 - 0.15, 1.0), Vector3(0.34, 0.30, 4.4), &"bridge_deck")
	SliceMaterials.add_multimesh(self, rails, &"rail_glow")
	# Warm undercroft overhead canopy frame + lamps + reward loot cache + relay log.
	for sx in [-7.5, 7.5]:
		SliceMaterials.add_box(self, null, Vector3(sx, y0 + 2.2, -3.5), Vector3(0.25, 4.4, 0.25), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(0, y0 + 4.4, -3.5), Vector3(15.4, 0.3, 0.35), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(0, y0 + 4.15, -3.5), Vector3(0.9, 0.2, 0.9), &"lamp", false)
	SliceMaterials.add_coronas(self, [Vector3(0, y0 + 4.0, -3.5)], 2.4, &"corona_soft")
	var ul := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.2, 24.0)
	ul.position = Vector3(0, y0 + 3.6, -2.2)
	add_child(ul)
	SliceMaterials.add_sign(self, Vector3(0, y0 + 4.4, -3.3),
		"UNDERCROFT 76-B  ·  40,780 M ELEVATION  ·  CRUST 40.78 KM BELOW", 0.011, Color(1.0, 0.84, 0.54), 0.0)
	add_child(LootContainer.create(
		"CONT-SHAFT-UNDERCROFT", "Undercroft Expedition Cache", "cache",
		Vector3(-5.8, y0, -3.4), 0.0,
		[["salvaged_relay", 1], ["water_flask", 2], ["fuse_cell", 1], ["dried_strip", 1]], 5, 4))
	SliceMaterials.add_box(self, body, Vector3(4.8, y0 + 0.55, -3.8), Vector3(0.9, 1.1, 0.65), &"plate")
	add_child(ReadableNote.create(
		"NOTE-UNDERCROFT-LOG", "Deep Haulage Relay Dispatch",
		"UNDERCROFT 76-B — STRATUM II TRANSFER LOG\n"
		+ "Elevation: +40,780 m above original Asset 31 crust.\n\n"
		+ "Lower relay cages below -2,200 m require Shift-4 clearance.\n"
		+ "Raw iron and core-rock hoisted from the buried crust feed the\n"
		+ "foundries above — every new roof tier thins the world beneath us.\n"
		+ "Do not lean over the north grate during heavy ore lifts.",
		Vector3(4.8, y0 + 1.12, -3.72), 0.0, "paper"))


## Sparse industrial crew silhouettes on the Floor 77 shaft hub & approach catwalk.
func _build_shaft_life() -> void:
	var c := Crowd.new()
	c.name = "ShaftCrew"
	add_child(c)
	var statics := [
		{ "p": Vector3(2.8, 0.0, -5.4), "yaw": -1.35 },
		{ "p": Vector3(-2.4, 0.0, -5.6), "yaw": 0.15 },
	]
	var walkers := [
		{ "a": Vector3(-56.0, 0.0, -1.6), "b": Vector3(-14.0, 0.0, -1.6) },
	]
	c.setup(statics, walkers, 7701, 1.0, 420.0)


func _process(_delta: float) -> void:
	_update_cars()


func _update_cars() -> void:
	var span := (_top - 40.0) - (_bottom + 40.0)
	var t := Time.get_ticks_msec() / 1000.0
	for c: Dictionary in _cars:
		var u := fposmod(float(c.phase) + t * float(c.speed) / (2.0 * span), 1.0)
		var k := u * 2.0 if u < 0.5 else 2.0 - u * 2.0
		(c.node as Node3D).position.y = _bottom + 40.0 + k * span
