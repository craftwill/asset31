class_name VoidBellSanctum
extends WorldAnchor
## The Great Belfry of the Continuum (BELFRY-0414):
## Monumental 400 m-wide cylindrical shaft cathedral inside distant stack STK-0414
## (17.5 km north across the chasm, directly behind the STA-0414-S Express Terminal).
## Faithfully recreates reference_images/religion_concepts/religious_huge_bell.png:
##   - Colossal 88 m-wide, 66 m-tall 12-sided (dodecagonal) 5-tier stepped conical Void Bell
##     suspended at (-15, 34.5, -6) from a bundle of 16 heavy vertical steel cables.
##   - 17 m dark-iron spherical clapper (striker) suspended inside the illuminated coffered
##     bronze vault, physically swinging with a golden shockwave flare whenever The Void Bell tolls.
##   - Foreground-right Lattice Tower (x = +27, z = +38) clear of the bell silhouette, with its
##     glowing warm-white horizontal gondola cabin (y = +12.6 m), side-profile upper box-truss
##     bridge (y = +18.0 m) with deep diagonal under-truss bracing, and cantilevered Pilgrim
##     Overlook Platform (x = +19..+35, z = +46 m) with 2 quiet pilgrim silhouettes.

const GROUP := &"void_bell_sanctum"
const CENTER_LX := 5990.2
const CENTER_LY := 41000.0
const CENTER_LZ := -14960.0
const R := 200.0
const SIDES := 24
const BELL_SIDES := 12

var _bottom := -2200.0
var _top := 1400.0
var _cars: Array = []
var _bell_root: Node3D
var _clapper_pivot: Node3D
var _vault_light: OmniLight3D
var _strike_light: OmniLight3D
var _strike_timer := -1.0
var _bell_base_pos := Vector3(-15.0, 39.5, -6.0)


static func build() -> VoidBellSanctum:
	var s := VoidBellSanctum.new()
	s.name = "BELFRY-0414"
	s.lx = CENTER_LX
	s.ly = CENTER_LY
	s.lz = CENTER_LZ
	s.add_to_group(GROUP)
	s._build()
	return s


func _build() -> void:
	var body := StaticBody3D.new()
	body.name = "SanctumCollision"
	body.set_meta(&"surface", "metal")
	add_child(body)

	_build_cylindrical_shaft()
	_build_lattice_towers_and_catwalks(body)
	_build_colossal_void_bell()
	_build_narthex_and_sanctuary(body)
	_build_shaft_mist()


func _build_cylindrical_shaft() -> void:
	var h := _top - _bottom
	var cy := (_top + _bottom) * 0.5
	var chord := 2.0 * R * tan(PI / float(SIDES))
	var wall_t := 8.0
	var walls: Array = []
	var rings: Array = []
	var ring_lamps: Array = []

	# 1. 24-sided warm-lit cylindrical inner shaft wall.
	#    Facet i == 6 is due South (+Z, ang = PI * 0.5, z = +200 m) where the Threshold
	#    Narthex Gallery enters from STA-0414-S; split that facet below y = -8 and above y = +18.
	for i in SIDES:
		var ang := float(i) * TAU / float(SIDES)
		var nx := cos(ang)
		var nz := sin(ang)
		var r_mid := R + wall_t * 0.5
		var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
		if i == 6:
			var h_low := -8.0 - _bottom
			var h_hi := _top - 18.0
			walls.append({ "c": Vector3(nx * r_mid, _bottom + h_low * 0.5, nz * r_mid), "s": Vector3(chord + 1.0, h_low, wall_t), "r": rot, "seed": float(i) * 0.04 })
			walls.append({ "c": Vector3(nx * r_mid, 18.0 + h_hi * 0.5, nz * r_mid), "s": Vector3(chord + 1.0, h_hi, wall_t), "r": rot, "seed": float(i) * 0.04 })
		else:
			walls.append({ "c": Vector3(nx * r_mid, cy, nz * r_mid), "s": Vector3(chord + 1.0, h, wall_t), "r": rot, "seed": float(i) * 0.04 })
	SliceMaterials.add_multimesh(self, walls, &"shaft_wall")

	# 2. Concentric structural ring girders + glowing rim lamps every 80 m, plus the
	#    signature bright overhead corona ring collar at y = +88 m (top arc of religious_huge_bell.png).
	var y := _bottom + 80.0
	while y < _top - 40.0:
		var is_south_portal := absf(y) < 26.0
		for i in SIDES:
			if is_south_portal and i == 6:
				continue
			var ang := float(i) * TAU / float(SIDES)
			var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
			var r_in := R - 2.4
			rings.append({ "c": Vector3(cos(ang) * r_in, y, sin(ang) * r_in), "s": Vector3(chord, 4.2, 4.8), "r": rot })
			ring_lamps.append({ "c": Vector3(cos(ang) * (R - 5.0), y + 2.3, sin(ang) * (R - 5.0)), "s": Vector3(chord * 0.88, 0.24, 0.24), "r": rot })
		y += 80.0
	# Prominent glowing upper datum ring at y = +88 m (visible across the top of the reference frame).
	for i in SIDES:
		var ang := float(i) * TAU / float(SIDES)
		var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
		rings.append({ "c": Vector3(cos(ang) * (R - 3.0), 88.0, sin(ang) * (R - 3.0)), "s": Vector3(chord, 5.4, 6.0), "r": rot })
		ring_lamps.append({ "c": Vector3(cos(ang) * (R - 6.2), 87.2, sin(ang) * (R - 6.2)), "s": Vector3(chord * 0.94, 0.85, 0.85), "r": rot })
	# 12 vertical glowing amber light ribs & dark vertical shaft columns running down the inner cylinder wall.
	for k in 12:
		var ang := (float(k) + 0.25) * TAU / 12.0
		if absf(ang - PI * 0.5) < 0.25:
			continue
		var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
		rings.append({ "c": Vector3(cos(ang) * (R - 2.0), cy, sin(ang) * (R - 2.0)), "s": Vector3(2.8, h, 3.6), "r": rot })
		ring_lamps.append({ "c": Vector3(cos(ang) * (R - 4.0), cy, sin(ang) * (R - 4.0)), "s": Vector3(0.45, h, 0.45), "r": rot })

	SliceMaterials.add_multimesh(self, rings, &"structure")
	SliceMaterials.add_multimesh(self, ring_lamps, &"window_glow")


func _build_lattice_towers_and_catwalks(body: StaticBody3D) -> void:
	var h := _top - _bottom
	var cy := (_top + _bottom) * 0.5
	var lattice: Array = []
	var glow_strips: Array = []

	# 1. Eight vertical open-truss lattice towers arranged around the shaft.
	#    Tower 0 at (x = +27.5, z = +38.0) is positioned cleanly to the right of the bell
	#    silhouette from the Ctrl+\ Hero Vantage Point, with a second background right-flank
	#    lattice tower at (x = +58.0, z = +18.0) matching the twin vertical trusses on the
	#    right side of religious_huge_bell.png!
	var tower_positions := [
		Vector2(27.5, 38.0),
		Vector2(58.0, 18.0),
		Vector2(108.0, -76.0),
		Vector2(38.0, -138.0),
		Vector2(-52.0, -136.0),
		Vector2(-124.0, -68.0),
		Vector2(-132.0, 26.0),
		Vector2(-92.0, 88.0),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 414077
	for ti in tower_positions.size():
		var tp: Vector2 = tower_positions[ti]
		var tx := tp.x
		var tz := tp.y
		var ts := 8.6 if ti == 0 else (7.6 if ti == 1 else 10.0)
		var half_t := ts * 0.5
		for c_off in [Vector2(-half_t, -half_t), Vector2(half_t, -half_t), Vector2(-half_t, half_t), Vector2(half_t, half_t)]:
			lattice.append({ "c": Vector3(tx + c_off.x, cy, tz + c_off.y), "s": Vector3(0.88, h, 0.88) })
		var dir_in := -tp.normalized()
		glow_strips.append({ "c": Vector3(tx + dir_in.x * (half_t + 0.48), cy, tz + dir_in.y * (half_t + 0.48)), "s": Vector3(0.26, h, 0.26) })
		var by := _bottom + 24.0
		while by < _top - 20.0:
			var step := 9.0 if absf(by) < 180.0 else 24.0
			lattice.append({ "c": Vector3(tx, by, tz - half_t), "s": Vector3(ts - 0.88, 0.50, 0.50) })
			lattice.append({ "c": Vector3(tx, by, tz + half_t), "s": Vector3(ts - 0.88, 0.50, 0.50) })
			lattice.append({ "c": Vector3(tx - half_t, by, tz), "s": Vector3(0.50, 0.50, ts - 0.88) })
			lattice.append({ "c": Vector3(tx + half_t, by, tz), "s": Vector3(0.50, 0.50, ts - 0.88) })
			if absf(by) < 180.0:
				var d_len := sqrt(ts * ts + step * step) * 0.92
				var d_pitch := atan2(step, ts)
				lattice.append({ "c": Vector3(tx, by + step * 0.5, tz - half_t), "s": Vector3(d_len, 0.36, 0.36), "r": Vector3(0.0, 0.0, d_pitch) })
				lattice.append({ "c": Vector3(tx, by + step * 0.5, tz + half_t), "s": Vector3(d_len, 0.36, 0.36), "r": Vector3(0.0, 0.0, -d_pitch) })
				lattice.append({ "c": Vector3(tx - half_t, by + step * 0.5, tz), "s": Vector3(0.36, 0.36, d_len), "r": Vector3(d_pitch, 0.0, 0.0) })
				lattice.append({ "c": Vector3(tx + half_t, by + step * 0.5, tz), "s": Vector3(0.36, 0.36, d_len), "r": Vector3(-d_pitch, 0.0, 0.0) })
			by += step

		if ti == 0:
			# Hero Foreground Tower 0: Stationary multi-window glowing white observation gondola at y = +13.0 m
			# (positioned right underneath the y = +18.0 m upper truss bridge, matching religious_huge_bell.png!).
			var gond_y := 13.0
			lattice.append({ "c": Vector3(tx, gond_y + 1.25, tz), "s": Vector3(ts + 3.4, 0.50, ts + 3.4) })
			lattice.append({ "c": Vector3(tx, gond_y - 1.25, tz), "s": Vector3(ts + 3.4, 0.50, ts + 3.4) })
			lattice.append({ "c": Vector3(tx, gond_y, tz), "s": Vector3(ts + 2.6, 1.85, ts + 2.6) })
			var w_out := half_t + 1.42
			for wx_o: float in [-3.0, -1.0, 1.0, 3.0]:
				glow_strips.append({ "c": Vector3(tx + wx_o, gond_y, tz - w_out), "s": Vector3(1.65, 1.70, 0.20) })
				glow_strips.append({ "c": Vector3(tx + wx_o, gond_y, tz + w_out), "s": Vector3(1.65, 1.70, 0.20) })
				glow_strips.append({ "c": Vector3(tx - w_out, gond_y, tz + wx_o), "s": Vector3(0.20, 1.70, 1.65) })
				glow_strips.append({ "c": Vector3(tx + w_out, gond_y, tz + wx_o), "s": Vector3(0.20, 1.70, 1.65) })
			var gl := SliceMaterials.make_lamp_light(Color(1.0, 0.90, 0.70), 2.8, 36.0)
			gl.position = Vector3(tx - 5.0, gond_y, tz + 6.0)
			add_child(gl)
			SliceMaterials.add_coronas(self, [Vector3(tx - 3.8, gond_y, tz + 4.2)], 8.5, &"corona_soft")
		elif ti >= 2 and ti % 2 == 0:
			var car := Node3D.new()
			car.position = Vector3(tx, 0.0, tz)
			add_child(car)
			SliceMaterials.add_box(car, null, Vector3.ZERO, Vector3(ts + 2.6, 5.4, ts + 2.6), &"structure", false)
			SliceMaterials.add_box(car, null, Vector3(0, 0.4, 0), Vector3(ts + 3.0, 1.8, ts + 3.0), &"window_glow", false)
			_cars.append({ "node": car, "phase": rng.randf(), "speed": rng.randf_range(5.0, 11.0) })

	# 2. Walkable Upper Cross-Shaft Box-Truss Bridge (y = +18.0 m):
	#    - Foreground-right span from the southeast shaft rim (x = +68, y = +18, z = +54) through
	#      Hero Lattice Tower 0 (x = +27.5, y = +18, z = +38) and continuing north behind the right
	#      flank of the Void Bell to (x = +14.0, y = +18, z = -158) — never crossing in front of the bell!
	#    - Plus the background east-west cross-shaft bridge behind the bell at (y = +18.0 m, z = -68.0 m)
	#      visible on the left & right behind the bell cone in religious_huge_bell.png!
	var br_y := 18.0
	var fg_a := Vector3(68.0, br_y - 0.35, 54.0)
	var fg_b := Vector3(27.5, br_y - 0.35, 38.0)
	var fg_mid := (fg_a + fg_b) * 0.5
	var fg_len := fg_a.distance_to(fg_b)
	var fg_dir := (fg_b - fg_a).normalized()
	var fg_yaw := atan2(fg_dir.x, fg_dir.z)
	var fg_rot := Vector3(0.0, fg_yaw, 0.0)
	var fg_right := Vector3(cos(fg_yaw), 0.0, -sin(fg_yaw))
	var fg_basis := Basis(Vector3.UP, fg_yaw)
	var fg_mi := MeshInstance3D.new()
	var fg_bm := BoxMesh.new()
	fg_bm.size = Vector3(6.6, 0.70, fg_len)
	fg_mi.mesh = fg_bm
	fg_mi.material_override = SliceMaterials.get_mat(&"bridge_deck")
	fg_mi.transform = Transform3D(fg_basis, fg_mid)
	add_child(fg_mi)
	var fg_cs := CollisionShape3D.new()
	var fg_bs := BoxShape3D.new()
	fg_bs.size = Vector3(6.6, 0.70, fg_len)
	fg_cs.shape = fg_bs
	fg_cs.transform = Transform3D(fg_basis, fg_mid)
	body.add_child(fg_cs)
	for side_s: float in [-3.15, 3.15]:
		var rcs := CollisionShape3D.new()
		var rbs := BoxShape3D.new()
		rbs.size = Vector3(0.2, 1.3, fg_len)
		rcs.shape = rbs
		rcs.transform = Transform3D(fg_basis, fg_mid + fg_right * side_s + Vector3(0, 0.95, 0))
		body.add_child(rcs)
		lattice.append({ "c": fg_mid + fg_right * side_s + Vector3(0, -4.4, 0), "s": Vector3(0.78, 0.78, fg_len), "r": fg_rot })
	var n_fg := 10
	for fi in n_fg:
		var u := (float(fi) + 0.5) / float(n_fg)
		var fp := fg_a.lerp(fg_b, u)
		for side_s: float in [-3.1, 3.1]:
			lattice.append({ "c": fp + fg_right * side_s + Vector3(0, -2.2, 0), "s": Vector3(0.60, 4.4, 0.60), "r": fg_rot })
			var diag_rot := (fg_basis * Basis(Vector3.RIGHT, 0.64 if fi % 2 == 0 else -0.64)).get_euler()
			lattice.append({ "c": fp + fg_right * side_s + Vector3(0, -2.2, 0), "s": Vector3(0.48, 6.0, 0.48), "r": diag_rot })
		lattice.append({ "c": fp + Vector3(0, -4.4, 0), "s": Vector3(5.8, 0.55, 0.55), "r": fg_rot })
		glow_strips.append({ "c": fp + fg_right * -3.25 + Vector3(0, 0.52, 0), "s": Vector3(0.30, 0.30, 0.42), "r": fg_rot })
	for u_box: float in [0.18, 0.42]:
		var bp := fg_a.lerp(fg_b, u_box)
		lattice.append({ "c": bp + Vector3(0, 1.35, 0), "s": Vector3(3.4, 2.1, 4.6), "r": fg_rot })

	# Northward continuation of the walkable upper bridge from Tower 0 (27.5, 18, 34.4) straight north along x = 27.5
	# past the right edge of the bell into the background cross-shaft bridge at z = -64.56 (butt-joined cleanly)!
	SliceMaterials.add_box(self, body, Vector3(27.5, br_y - 0.35, -15.08), Vector3(6.2, 0.70, 98.96), &"bridge_deck")
	SliceMaterials.add_collision_box(body, Vector3(24.5, br_y + 0.65, -15.08), Vector3(0.2, 1.3, 98.96))
	SliceMaterials.add_collision_box(body, Vector3(30.5, br_y + 0.65, -15.08), Vector3(0.2, 1.3, 98.96))
	lattice.append({ "c": Vector3(24.5, br_y - 4.4, -16.8), "s": Vector3(0.75, 0.75, 102.4) })
	lattice.append({ "c": Vector3(30.5, br_y - 4.4, -16.8), "s": Vector3(0.75, 0.75, 102.4) })
	var nz_br := -64.0
	while nz_br <= 32.0:
		lattice.append({ "c": Vector3(24.5, br_y - 2.2, nz_br), "s": Vector3(0.55, 4.4, 0.55) })
		lattice.append({ "c": Vector3(30.5, br_y - 2.2, nz_br), "s": Vector3(0.55, 4.4, 0.55) })
		lattice.append({ "c": Vector3(24.5, br_y - 2.2, nz_br + 3.0), "s": Vector3(0.45, 5.8, 0.45), "r": Vector3(0.62, 0.0, 0.0) })
		lattice.append({ "c": Vector3(30.5, br_y - 2.2, nz_br + 3.0), "s": Vector3(0.45, 5.8, 0.45), "r": Vector3(-0.62, 0.0, 0.0) })
		glow_strips.append({ "c": Vector3(24.3, br_y + 0.45, nz_br), "s": Vector3(0.25, 0.30, 0.40) })
		nz_br += 6.0

	# Background east-west cross-shaft bridge behind the bell at (y = +18.0 m, z = -68.0 m, x in [-184..+184 m]).
	SliceMaterials.add_box(self, body, Vector3(0.0, br_y - 0.35, -68.0), Vector3(368.0, 0.70, 6.8), &"bridge_deck")
	SliceMaterials.add_collision_box(body, Vector3(0.0, br_y + 0.65, -71.3), Vector3(368.0, 1.3, 0.2))
	lattice.append({ "c": Vector3(0.0, br_y - 4.4, -68.0), "s": Vector3(366.0, 0.85, 6.2) })
	var bkx := -176.0
	while bkx <= 176.0:
		lattice.append({ "c": Vector3(bkx, br_y - 2.4, -68.0), "s": Vector3(0.65, 4.0, 6.2) })
		if int(roundf(bkx)) % 12 == 0:
			glow_strips.append({ "c": Vector3(bkx, br_y + 0.45, -64.5), "s": Vector3(0.55, 0.35, 0.25) })
		bkx += 6.0
	for sx_cabin: float in [-138.0, -112.0, 74.0, 96.0]:
		lattice.append({ "c": Vector3(sx_cabin, br_y + 1.8, -68.0), "s": Vector3(7.0, 3.6, 4.4) })
		glow_strips.append({ "c": Vector3(sx_cabin, br_y + 1.9, -65.7), "s": Vector3(2.2, 0.65, 0.15) })

	# 3. Foreground Lattice Tower Pilgrim Overlook Platform (y = 0.0 m, x in [21.5..39.5 m], z in [44.0..52.0 m])
	#    extending right-to-left out from the east catwalk into Hero Tower 0 (27.5, 38) with 2 quiet pilgrim
	#    silhouettes standing at its north-west railing (bottom-right of religious_huge_bell.png, with open
	#    misty shaft space between the foreground camera parapet and this platform!).
	SliceMaterials.add_box(self, body, Vector3(30.5, -0.35, 48.0), Vector3(18.0, 0.70, 8.0), &"bridge_deck")
	for px_s: float in [22.2, 26.5, 31.0, 35.5]:
		for pz_s: float in [44.5, 51.5]:
			lattice.append({ "c": Vector3(px_s, -4.5, pz_s), "s": Vector3(0.55, 8.3, 0.55) })
		lattice.append({ "c": Vector3(px_s, -8.5, 48.0), "s": Vector3(0.55, 0.55, 7.6) })
		lattice.append({ "c": Vector3(px_s, -4.2, 48.0), "s": Vector3(0.42, 0.42, 9.2), "r": Vector3(0.62, 0.0, 0.0) })
		lattice.append({ "c": Vector3(px_s, -4.2, 48.0), "s": Vector3(0.42, 0.42, 9.2), "r": Vector3(-0.62, 0.0, 0.0) })
	# Thin double-bar industrial handrails around the Pilgrim Overlook Platform (open on east x = 39.5 for the rim catwalk).
	SliceMaterials.add_collision_box(body, Vector3(30.5, 0.65, 44.1), Vector3(18.0, 1.3, 0.2))
	SliceMaterials.add_collision_box(body, Vector3(21.6, 0.65, 48.0), Vector3(0.2, 1.3, 8.0))
	SliceMaterials.add_collision_box(body, Vector3(28.5, 0.65, 51.9), Vector3(14.0, 1.3, 0.2))
	lattice.append({ "c": Vector3(30.5, 1.08, 44.1), "s": Vector3(18.0, 0.07, 0.07) })
	lattice.append({ "c": Vector3(30.5, 0.56, 44.1), "s": Vector3(18.0, 0.06, 0.06) })
	lattice.append({ "c": Vector3(21.6, 1.08, 48.0), "s": Vector3(0.07, 0.07, 8.0) })
	lattice.append({ "c": Vector3(21.6, 0.56, 48.0), "s": Vector3(0.06, 0.06, 8.0) })
	lattice.append({ "c": Vector3(28.5, 1.08, 51.9), "s": Vector3(14.0, 0.07, 0.07) })
	for post_x: float in [21.8, 24.5, 27.2, 30.0, 32.8, 35.5, 38.2]:
		lattice.append({ "c": Vector3(post_x, 0.58, 44.1), "s": Vector3(0.08, 1.15, 0.08) })
		if post_x < 35.0:
			lattice.append({ "c": Vector3(post_x, 0.58, 51.9), "s": Vector3(0.08, 1.15, 0.08) })

	# Two quiet human pilgrim silhouettes standing at the Pilgrim Overlook railing gazing up at the Void Bell.
	_add_pilgrim_silhouette(lattice, Vector3(23.8, 0.0, 45.2), -2.55, 1.78, true)
	_add_pilgrim_silhouette(lattice, Vector3(25.8, 0.0, 45.0), -2.65, 1.68, false)
	# Subtle golden rim-light behind the Pilgrim Overlook Platform so the 2 pilgrim silhouettes and lattice braces pop.
	var pl_light := SliceMaterials.make_lamp_light(Color(1.0, 0.72, 0.36), 2.4, 42.0)
	pl_light.position = Vector3(26.0, 3.5, 34.0)
	add_child(pl_light)

	# 4. Lower Criss-Crossing Diagonal Abyssal Truss Catwalks cutting through the golden mist below the bell
	#    (matching the lower-left and lower-center diagonal catwalk network in religious_huge_bell.png!).
	var lower_spans := [
		[Vector3(-188.0, 4.0, 28.0), Vector3(18.0, -6.0, -162.0)],
		[Vector3(-184.0, -12.0, -38.0), Vector3(164.0, -20.0, 82.0)],
		[Vector3(-140.0, -28.0, 114.0), Vector3(148.0, -36.0, -126.0)],
		[Vector3(-175.0, -52.0, -84.0), Vector3(172.0, -52.0, 68.0)],
		[Vector3(-92.0, -84.0, 172.0), Vector3(98.0, -84.0, -168.0)],
		[Vector3(-180.0, -140.0, 18.0), Vector3(180.0, -140.0, -18.0)],
	]
	for sp: Array in lower_spans:
		var p0: Vector3 = sp[0]
		var p1: Vector3 = sp[1]
		var mid := (p0 + p1) * 0.5
		var slen := p0.distance_to(p1)
		var dir := (p1 - p0).normalized()
		var syaw := atan2(dir.x, dir.z)
		var spitch := -asin(clampf(dir.y, -0.5, 0.5))
		var srot := Vector3(spitch, syaw, 0.0)
		lattice.append({ "c": mid, "s": Vector3(3.2, 0.55, slen), "r": srot })
		lattice.append({ "c": mid + Vector3(0, -2.2, 0), "s": Vector3(2.8, 0.55, slen), "r": srot })
		var n_lights := int(slen / 10.0)
		for li in n_lights:
			var u := (float(li) + 0.5) / float(n_lights)
			var lp := p0.lerp(p1, u)
			lattice.append({ "c": lp + Vector3(0, -1.1, 0), "s": Vector3(3.0, 2.0, 0.42), "r": Vector3(0.0, syaw, 0.0) })
			glow_strips.append({ "c": lp + Vector3(0, 0.42, 0), "s": Vector3(0.40, 0.26, 0.40) })

	SliceMaterials.add_multimesh(self, lattice, &"structure")
	SliceMaterials.add_multimesh(self, glow_strips, &"window_glow")


func _add_pilgrim_silhouette(lattice: Array, pos: Vector3, yaw: float, height: float, long_coat: bool) -> void:
	var s := height / 1.75
	var ry := Vector3(0.0, yaw, 0.0)
	lattice.append({ "c": pos + Vector3(-0.11 * s, 0.44 * s, 0.0).rotated(Vector3.UP, yaw), "s": Vector3(0.15 * s, 0.88 * s, 0.16 * s), "r": ry })
	lattice.append({ "c": pos + Vector3(0.11 * s, 0.44 * s, 0.0).rotated(Vector3.UP, yaw), "s": Vector3(0.15 * s, 0.88 * s, 0.16 * s), "r": ry })
	var coat_h := 0.82 * s if long_coat else 0.64 * s
	var coat_y := 1.02 * s if long_coat else 1.12 * s
	lattice.append({ "c": pos + Vector3(0.0, coat_y, 0.0), "s": Vector3(0.46 * s, coat_h, 0.26 * s), "r": ry })
	lattice.append({ "c": pos + Vector3(-0.27 * s, 1.14 * s, 0.05 * s).rotated(Vector3.UP, yaw), "s": Vector3(0.13 * s, 0.56 * s, 0.14 * s), "r": ry })
	lattice.append({ "c": pos + Vector3(0.27 * s, 1.14 * s, 0.05 * s).rotated(Vector3.UP, yaw), "s": Vector3(0.13 * s, 0.56 * s, 0.14 * s), "r": ry })
	lattice.append({ "c": pos + Vector3(0.0, 1.58 * s, 0.0), "s": Vector3(0.22 * s, 0.24 * s, 0.23 * s), "r": ry })


## Colossal 12-sided (dodecagonal) 5-tier stepped conical Void Bell + 17 m spherical clapper
## suspended at _bell_base_pos = (-15.0, 34.5, -6.0).
func _build_colossal_void_bell() -> void:
	_bell_root = Node3D.new()
	_bell_root.name = "ColossalVoidBell"
	_bell_root.position = _bell_base_pos
	add_child(_bell_root)

	var armor_plates: Array = []
	var copper_trim: Array = []
	var steel_ribs: Array = []
	var seam_lights: Array = []

	# 1. Five outward-sloping stepped conical dodecagonal tiers flaring from y = +39 m down to y = -26 m
	#    (total bell height = 65 m, top crown radius 5.5 m -> bottom mouth radius 44.0 m = 88 m diameter!).
	#    Note: Basis(Vector3.RIGHT, -tilt) tilts the top (+Y) INWARD (-Z) and bottom (-Y) OUTWARD (+Z),
	#    forming a true conical bell profile matching religious_huge_bell.png!
	var tiers := [
		[28.0, 39.0, 10.8, 5.2,  1.8, false],   # Tier 0: Steep upper crown cone
		[16.0, 28.0, 19.4, 12.0, 2.1, false],   # Tier 1: Upper-mid cone
		[3.5,  16.0, 29.5, 21.0, 2.4, true],    # Tier 2: Mid cone with copper step collar
		[-9.5, 3.5,  38.5, 31.2, 2.8, true],    # Tier 3: Broad lower-mid skirt
		[-22.5, -9.5, 44.5, 40.0, 3.2, true],   # Tier 4: Massive lower sound-bow rim skirt
	]

	for ti in tiers.size():
		var td: Array = tiers[ti]
		var y0 := float(td[0])
		var y1 := float(td[1])
		var r0 := float(td[2])
		var r1 := float(td[3])
		var wt := float(td[4])
		var has_copper := bool(td[5])
		var dy := y1 - y0
		var dr := r0 - r1
		var slope_len := sqrt(dy * dy + dr * dr)
		var tilt := atan2(dr, dy)
		var ym := (y0 + y1) * 0.5
		var rm := (r0 + r1) * 0.5
		var chord_m := 2.0 * rm * tan(PI / float(BELL_SIDES))
		var chord_0 := 2.0 * r0 * tan(PI / float(BELL_SIDES))

		for i in BELL_SIDES:
			var ang := (float(i) + 0.5) * TAU / float(BELL_SIDES)
			var yaw := -ang + PI * 0.5
			var nx := cos(ang)
			var nz := sin(ang)
			# -tilt around local X slopes top (+Y) inward toward the bell axis and bottom (-Y) outward!
			var b_rot := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -tilt)
			var euler := b_rot.get_euler()

			armor_plates.append({
				"c": Vector3(nx * rm, ym, nz * rm),
				"s": Vector3(chord_m * 0.97, slope_len + 0.25, wt),
				"r": euler,
				"seed": float(ti * 12 + i) * 0.07
			})
			if has_copper:
				copper_trim.append({
					"c": Vector3(nx * (rm + wt * 0.42), ym, nz * (rm + wt * 0.42)),
					"s": Vector3(chord_m * 0.76, slope_len * 0.80, 0.52),
					"r": euler
				})
			# Horizontal step collar flange ring at the bottom of each tier (y = y0).
			var flat_rot := Vector3(0.0, yaw, 0.0)
			steel_ribs.append({
				"c": Vector3(nx * (r0 + 0.35), y0 + 0.50, nz * (r0 + 0.35)),
				"s": Vector3(chord_0 * 1.03, 1.00, wt + 0.95),
				"r": flat_rot
			})
			# Warm amber rivet / seam lights mounted OUTSIDE each facet step flange.
			var step_out := r0 + wt * 0.5 + 0.95
			for side_s: float in [-0.36, 0.0, 0.36]:
				var tang := Vector3(-nz, 0.0, nx) * (chord_0 * side_s)
				seam_lights.append({
					"c": Vector3(nx * step_out, y0 + 0.50, nz * step_out) + tang,
					"s": Vector3(0.42, 0.52, 0.28),
					"r": flat_rot
				})

			# 12 Radial External Stiffening Rib Spines along the corner seams (sloped at -tilt!).
			var ang_c := float(i) * TAU / float(BELL_SIDES)
			var cyaw := -ang_c + PI * 0.5
			var c_rot := (Basis(Vector3.UP, cyaw) * Basis(Vector3.RIGHT, -tilt)).get_euler()
			var cnx := cos(ang_c)
			var cnz := sin(ang_c)
			var crm := rm + wt * 0.36
			steel_ribs.append({
				"c": Vector3(cnx * crm, ym, cnz * crm),
				"s": Vector3(1.35, slope_len + 0.45, wt + 1.1),
				"r": c_rot
			})
			# Small glowing amber rivet lamp at the bottom & mid corner of each radial rib (matching reference!).
			var rib_out := crm + (wt + 1.1) * 0.5 + 0.20
			seam_lights.append({
				"c": Vector3(cnx * rib_out, ym, cnz * rib_out),
				"s": Vector3(0.36, 0.72, 0.26),
				"r": c_rot
			})

	# 2. Deep Coffered Interior Bell Vault flush with the inner wall (sloped at -tilt so it never
	#    hangs down below y = -22.0 m or blocks the spherical clapper!).
	for i in BELL_SIDES * 2:
		var ang := float(i) * TAU / float(BELL_SIDES * 2)
		var yaw := -ang + PI * 0.5
		var nx := cos(ang)
		var nz := sin(ang)
		var in_rot_low := (Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -0.34)).get_euler()
		copper_trim.append({
			"c": Vector3(nx * 39.0, -13.5, nz * 39.0),
			"s": Vector3(1.6, 15.5, 1.8),
			"r": in_rot_low
		})
		var in_rot_hi := (Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -0.48)).get_euler()
		steel_ribs.append({
			"c": Vector3(nx * 29.0, 1.0, nz * 29.0),
			"s": Vector3(1.4, 15.0, 1.6),
			"r": in_rot_hi
		})
	for in_ring: Array in [[-21.2, 41.4], [-13.0, 36.6], [-4.0, 29.8]]:
		var ry_in := float(in_ring[0])
		var rr_in := float(in_ring[1])
		var r_chord := 2.0 * rr_in * tan(PI / float(BELL_SIDES))
		for i in BELL_SIDES:
			var ang := (float(i) + 0.5) * TAU / float(BELL_SIDES)
			var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
			copper_trim.append({
				"c": Vector3(cos(ang) * rr_in, ry_in, sin(ang) * rr_in),
				"s": Vector3(r_chord * 1.02, 1.4, 1.8),
				"r": rot
			})
	steel_ribs.append({ "c": Vector3(0.0, 12.0, 0.0), "s": Vector3(28.0, 2.5, 28.0) })

	# 3. Bell Crown Shackle Yoke & 16 Heavy Vertical Suspension Cables rising 600 m into the upper shaft
	#    (cables start cleanly at y = +43.06 m above the y = 41.0..43.0 copper crown cap -> 0 ZFightLint overlaps!).
	steel_ribs.append({ "c": Vector3(0.0, 39.8, 0.0), "s": Vector3(12.4, 2.2, 12.4) })
	copper_trim.append({ "c": Vector3(0.0, 42.0, 0.0), "s": Vector3(9.6, 2.0, 9.6) })
	var cab_h := 620.0
	var cab_cy := 43.06 + cab_h * 0.5
	for ci in 12:
		var cang := float(ci) * TAU / 12.0
		var cr := 5.0 if ci % 2 == 0 else 3.6
		var cw := 0.65 if ci % 2 == 0 else 0.44
		steel_ribs.append({ "c": Vector3(cos(cang) * cr, cab_cy, sin(cang) * cr), "s": Vector3(cw, cab_h, cw) })
		steel_ribs.append({ "c": Vector3(cos(cang) * (cr + 0.65), 41.2, sin(cang) * (cr + 0.65)), "s": Vector3(1.0, 3.8, 1.5), "r": Vector3(0.0, -cang + PI * 0.5, 0.0) })
	for ci in 4:
		var cang := (float(ci) + 0.5) * PI * 0.5
		steel_ribs.append({ "c": Vector3(cos(cang) * 1.7, cab_cy, sin(cang) * 1.7), "s": Vector3(0.90, cab_h, 0.90) })

	SliceMaterials.add_multimesh(_bell_root, armor_plates, &"plate_local")
	SliceMaterials.add_multimesh(_bell_root, copper_trim, &"copper")
	SliceMaterials.add_multimesh(_bell_root, steel_ribs, &"structure")
	SliceMaterials.add_multimesh(_bell_root, seam_lights, &"window_glow")

	# 4. The Colossal 17 m Spherical Clapper (Striker) mounted on _clapper_pivot at (0, +12.0, 0).
	_clapper_pivot = Node3D.new()
	_clapper_pivot.name = "ClapperPivot"
	_clapper_pivot.position = Vector3(0.0, 12.0, 0.0)
	_bell_root.add_child(_clapper_pivot)

	var clapper_armor: Array = []
	var clapper_steel: Array = []
	var clapper_copper: Array = []

	clapper_steel.append({ "c": Vector3(0.0, -16.0, 0.0), "s": Vector3(3.6, 32.0, 3.6) })
	clapper_steel.append({ "c": Vector3(0.0, -16.0, 0.0), "s": Vector3(3.6, 32.0, 3.6), "r": Vector3(0.0, PI * 0.25, 0.0) })
	for cy_neck: Array in [[-21.5, 6.6, 2.0], [-24.6, 5.4, 1.6], [-27.2, 7.2, 1.4]]:
		var ny := float(cy_neck[0])
		var nw := float(cy_neck[1])
		var nh := float(cy_neck[2])
		clapper_steel.append({ "c": Vector3(0.0, ny, 0.0), "s": Vector3(nw, nh, nw) })
		clapper_steel.append({ "c": Vector3(0.0, ny, 0.0), "s": Vector3(nw, nh, nw), "r": Vector3(0.0, PI * 0.25, 0.0) })

	# 17 m Faceted Dark-Iron Spherical Striker centered at y_rel = -36.0 m (bell local y = -24.0 m,
	# framed cleanly inside the open glowing mouth of the bell!).
	var sph_cy := -36.0
	var sph_r := 8.4
	var lon_sides := 12
	for li in range(-3, 4):
		var lat := float(li) * 0.36
		var r_lat := cos(lat) * sph_r
		var y_lat := sph_cy + sin(lat) * sph_r
		var band_h := sph_r * 0.42 * cos(lat * 0.4)
		var band_chord := 2.0 * r_lat * tan(PI / float(lon_sides)) + 0.5
		for j in lon_sides:
			var ang := float(j) * TAU / float(lon_sides)
			var yaw := -ang + PI * 0.5
			var rot := (Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -lat)).get_euler()
			clapper_armor.append({
				"c": Vector3(cos(ang) * (r_lat - 0.6), y_lat, sin(ang) * (r_lat - 0.6)),
				"s": Vector3(band_chord, band_h, 1.8),
				"r": rot,
				"seed": float((li + 3) * 12 + j) * 0.09
			})
			if li == 0:
				clapper_copper.append({
					"c": Vector3(cos(ang) * (r_lat - 0.2), y_lat, sin(ang) * (r_lat - 0.2)),
					"s": Vector3(band_chord * 1.02, 1.8, 1.4),
					"r": Vector3(0.0, yaw, 0.0)
				})
	clapper_steel.append({ "c": Vector3(0.0, -44.8, 0.0), "s": Vector3(5.8, 2.6, 5.8) })
	clapper_steel.append({ "c": Vector3(0.0, -44.8, 0.0), "s": Vector3(5.8, 2.6, 5.8), "r": Vector3(0.0, PI * 0.25, 0.0) })
	clapper_copper.append({ "c": Vector3(0.0, -46.5, 0.0), "s": Vector3(4.0, 1.3, 4.0) })

	SliceMaterials.add_multimesh(_clapper_pivot, clapper_armor, &"plate_local")
	SliceMaterials.add_multimesh(_clapper_pivot, clapper_steel, &"structure")
	SliceMaterials.add_multimesh(_clapper_pivot, clapper_copper, &"copper")

	# 5. Interior Golden Vault Illumination & Exterior Warm Architectural Key/Rim Lights.
	_vault_light = SliceMaterials.make_lamp_light(Color(1.0, 0.70, 0.28), 5.8, 95.0)
	_vault_light.position = Vector3(0.0, -6.0, -8.0)
	_bell_root.add_child(_vault_light)

	_strike_light = SliceMaterials.make_lamp_light(Color(1.0, 0.74, 0.32), 5.2, 85.0)
	_strike_light.position = Vector3(-2.0, -18.0, -22.0)
	_bell_root.add_child(_strike_light)

	for ext_l: Array in [
		[Vector3(-42.0, 6.0, 48.0), Color(1.0, 0.74, 0.40), 3.8, 130.0],
		[Vector3(32.0, -4.0, 52.0), Color(1.0, 0.70, 0.36), 2.8, 125.0],
		[Vector3(0.0, 42.0, 34.0), Color(1.0, 0.78, 0.44), 3.0, 95.0],
	]:
		var el := SliceMaterials.make_lamp_light(ext_l[1], float(ext_l[2]), float(ext_l[3]))
		el.position = ext_l[0]
		_bell_root.add_child(el)


## Walkable Threshold Narthex Gallery (z_local = +200..+242 m),
## South Rim Sanctuary Deck & Chime Keeper's Altar (z_local = +166..+200 m, y = 0 m),
## Central Sanctuary Promenade out to the Hero Viewing Deck (z_local = +82..+166 m, y = 0 m, Ctrl+\),
## Walkable Outer East Catwalk Spur (x = +37.5, outside the right edge of the Ctrl+\ view frustum!)
## leading to the Foreground Lattice Tower Pilgrim Overlook (x = +21.5..+39.5, z = +48 m, y = 0 m),
## and Walkable Ramp up to the +18 m Upper Cross-Shaft Box-Truss Bridge!
func _build_narthex_and_sanctuary(body: StaticBody3D) -> void:
	var trim_mm: Array = []
	var copper_mm: Array = []
	var glow_mm: Array = []

	# 1. Threshold Narthex Gallery (z_local in [+200.06, +241.94], x in [-4.8, +4.8], y = 0.0).
	SliceMaterials.add_box(self, body, Vector3(0.0, -0.35, 221.0), Vector3(9.6, 0.70, 41.88), &"concrete_floor")
	SliceMaterials.add_box(self, body, Vector3(-5.0, 3.8, 221.0), Vector3(0.36, 7.5, 41.80), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(5.0, 3.8, 221.0), Vector3(0.36, 7.5, 41.80), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(0.0, 7.85, 221.0), Vector3(10.4, 0.50, 41.80), &"structure")
	for gz: float in [233.0, 221.0, 209.0]:
		copper_mm.append({ "c": Vector3(-4.55, 3.8, gz), "s": Vector3(0.45, 7.4, 0.85) })
		copper_mm.append({ "c": Vector3(4.55, 3.8, gz), "s": Vector3(0.45, 7.4, 0.85) })
		copper_mm.append({ "c": Vector3(0.0, 7.3, gz), "s": Vector3(8.6, 0.45, 0.85) })
		glow_mm.append({ "c": Vector3(0.0, 7.02, gz), "s": Vector3(2.4, 0.14, 0.40) })
		var nl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.0, 22.0)
		nl.position = Vector3(0.0, 6.5, gz)
		add_child(nl)

	# 2. South Rim Sanctuary Deck (z_local in [+166.0, +199.98], x_local in [-22.0, +24.0], y = 0.0).
	SliceMaterials.add_box(self, body, Vector3(1.0, -0.35, 183.0), Vector3(46.0, 0.70, 33.96), &"concrete_floor")
	for sx_b: float in [-18.0, -6.0, 6.0, 18.0]:
		trim_mm.append({ "c": Vector3(sx_b, -4.5, 183.0), "s": Vector3(1.2, 8.2, 33.0) })
		trim_mm.append({ "c": Vector3(sx_b, -11.0, 191.0), "s": Vector3(1.4, 18.0, 1.4), "r": Vector3(-0.62, 0.0, 0.0) })
	SliceMaterials.add_collision_box(body, Vector3(-13.5, 0.65, 166.15), Vector3(17.0, 1.3, 0.2))
	SliceMaterials.add_box(self, null, Vector3(-13.5, 1.12, 166.15), Vector3(17.0, 0.09, 0.09), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(-21.85, 0.65, 183.0), Vector3(0.2, 1.3, 33.6))
	SliceMaterials.add_box(self, null, Vector3(-21.85, 1.12, 183.0), Vector3(0.09, 0.09, 33.6), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(-13.4, 0.65, 199.85), Vector3(17.0, 1.3, 0.2))
	SliceMaterials.add_collision_box(body, Vector3(14.4, 0.65, 199.85), Vector3(19.0, 1.3, 0.2))
	SliceMaterials.add_collision_box(body, Vector3(23.85, 0.65, 183.0), Vector3(0.2, 1.3, 33.6))
	SliceMaterials.add_box(self, null, Vector3(23.85, 1.12, 183.0), Vector3(0.09, 0.09, 33.6), &"rail_glow", false)

	# 3. Chime Keeper's Sanctum Alcove & Continuum Altar (West side of South Rim Deck, x = -15.5, z = 183.0).
	SliceMaterials.add_box(self, body, Vector3(-15.5, 0.12, 183.0), Vector3(8.6, 0.24, 14.0), &"structure")
	SliceMaterials.add_box(self, body, Vector3(-19.4, 3.8, 183.0), Vector3(0.65, 7.1, 12.4), &"industrial_wall")
	SliceMaterials.add_box(self, body, Vector3(-16.2, 0.82, 183.0), Vector3(1.5, 1.12, 5.4), &"copper")
	SliceMaterials.add_box(self, null, Vector3(-16.2, 1.42, 183.0), Vector3(1.68, 0.08, 5.6), &"structure", false)
	var altar_emblem := ContinuumEmblem.create(2.2, &"copper", &"structure", true)
	altar_emblem.position = Vector3(-18.95, 4.0, 183.0)
	altar_emblem.rotation.y = PI * 0.5
	add_child(altar_emblem)
	for vz_o: float in [-2.1, -1.25, -0.4, 0.4, 1.25, 2.1]:
		glow_mm.append({ "c": Vector3(-15.85, 1.54, 183.0 + vz_o), "s": Vector3(0.14, 0.22, 0.14) })
	var al := SliceMaterials.make_lamp_light(Color(1.0, 0.72, 0.34), 2.4, 24.0)
	al.position = Vector3(-14.5, 3.8, 183.0)
	add_child(al)

	add_child(ReadableNote.create(
		"NOTE-VOID-BELL-SANCTUM", "The Great Belfry of STK-0414 — Liturgy of the Void Bell",
		"THE CONTINUUM  ·  GREAT BELFRY OF STK-0414 (SANCTUM OF THE VOID BELL)\n\n"
		+ "\"Suspended above the four-kilometre shaft hangs the Voice of Continuity — cast from "
		+ "salvaged hull armor of the First Mantle Founding and bound by sixteen unbroken cables.\n\n"
		+ "When its seventeen-metre iron striker touches the bronze sound-bow, the vibration travels "
		+ "through the bedrock piers of VD-077-N, across the seventeen-kilometre abyss, and into the "
		+ "ribs of STK-0413 and STK-0412. To hear the Void Bell is to know that the bridges hold, "
		+ "the shafts endure, and Severance has not claimed our world.\"",
		Vector3(-15.35, 1.52, 180.0), PI * 0.5, "plaque"))

	add_child(LootContainer.create(
		"CONT-VOID-BELL-RELIC", "Chime Keeper's Continuum Reliquary", "crate",
		Vector3(-16.2, 0.26, 187.6), PI * 0.5,
		[["water_flask", 2], ["ration_tin", 2], ["bandage_roll", 2], ["fuse_cell", 1], ["salvaged_relay", 1]], 5, 4))

	# 4. Walkable Sanctuary Promenade & Hero Viewing Deck (y = 0.0 m, x in [10.0..23.0 m], z in [82.5..165.94 m])
	#    leading straight from the South Rim Sanctuary Deck out to the Ctrl+\ Hero Vantage Point at (17.5, 0.08, 86.0)!
	SliceMaterials.add_box(self, body, Vector3(16.5, -0.35, 124.2), Vector3(13.0, 0.70, 83.4), &"concrete_floor")
	SliceMaterials.add_collision_box(body, Vector3(10.1, 0.65, 124.2), Vector3(0.2, 1.3, 83.4))
	SliceMaterials.add_box(self, null, Vector3(10.1, 1.12, 127.0), Vector3(0.08, 0.08, 77.6), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(22.9, 0.65, 134.0), Vector3(0.2, 1.3, 63.6))
	# Angled weathered concrete foreground parapet lip at the north-east corner of the Hero Viewing Deck
	# reproducing ONLY the close bottom-right foreground parapet ledge in religious_huge_bell.png,
	# leaving open misty void between the parapet and the Pilgrim Overlook Platform ahead!
	SliceMaterials.add_collision_box(body, Vector3(16.5, 0.65, 82.65), Vector3(13.0, 1.3, 0.35))
	var parapet_mi := MeshInstance3D.new()
	var parapet_bm := BoxMesh.new()
	parapet_bm.size = Vector3(11.5, 0.86, 0.68)
	parapet_mi.mesh = parapet_bm
	parapet_mi.material_override = SliceMaterials.get_mat(&"structure")
	parapet_mi.position = Vector3(18.5, 0.38, 83.2)
	parapet_mi.rotation.y = deg_to_rad(8.0)
	add_child(parapet_mi)

	# Interactive Resonance Strike Console on the Hero Viewing Deck (x = 12.2, z = 84.8) right beside Ctrl+\!
	var bell_console := ExpressConsole.new()
	bell_console.name = "VoidBellResonanceConsole"
	bell_console.sanctum = self
	bell_console.position = Vector3(12.2, 0.65, 84.8)
	add_child(bell_console)
	SliceMaterials.add_box(bell_console, bell_console, Vector3.ZERO, Vector3(0.95, 1.30, 0.55), &"copper")
	SliceMaterials.add_box(bell_console, null, Vector3(0.0, 0.36, 0.29), Vector3(0.62, 0.24, 0.04), &"window_glow", false)
	var c_emb := ContinuumEmblem.create(0.24, &"copper", &"structure", false)
	c_emb.position = Vector3(0.0, 0.05, 0.30)
	bell_console.add_child(c_emb)

	# 5. Walkable Outer East Catwalk Spur (routed along x = +37.5, outside the right edge of the Ctrl+\ view!)
	#    connecting the Sanctuary Promenade (x = 23..39.5, z = 98) north along x = 37.5 (z = 52..95) straight
	#    onto the east end of the Pilgrim Overlook Platform (x = 21.5..39.5, z = 44..52)!
	SliceMaterials.add_box(self, body, Vector3(31.3, -0.35, 98.0), Vector3(16.4, 0.70, 5.0), &"bridge_deck")
	SliceMaterials.add_box(self, body, Vector3(37.5, -0.35, 73.8), Vector3(4.0, 0.70, 43.2), &"bridge_deck")
	SliceMaterials.add_collision_box(body, Vector3(35.6, 0.65, 73.8), Vector3(0.2, 1.3, 43.0))
	SliceMaterials.add_collision_box(body, Vector3(39.4, 0.65, 73.8), Vector3(0.2, 1.3, 43.0))

	# 6. Walkable East Side Ramp climbing from the Sanctuary Promenade (x = 26.5, y = 0.0, z = 148.0)
	#    north-east up to the y = +18.0 m Upper Cross-Shaft Box-Truss Bridge at (x = 58.0, y = 17.65, z = 54.0).
	_add_walkable_ramp(body, Vector3(26.5, -0.30, 148.0), Vector3(58.0, 17.65, 54.0), 4.6)

	SliceMaterials.add_multimesh(self, trim_mm, &"structure")
	SliceMaterials.add_multimesh(self, copper_mm, &"copper")
	SliceMaterials.add_multimesh(self, glow_mm, &"window_glow")


func _add_walkable_ramp(body: StaticBody3D, p0: Vector3, p1: Vector3, width: float) -> void:
	var mid := (p0 + p1) * 0.5
	var d := p1 - p0
	var horiz := Vector2(d.x, d.z).length()
	var slen := d.length()
	var yaw := atan2(d.x, d.z)
	var pitch := -atan2(d.y, horiz)
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.60, slen)
	mi.mesh = bm
	mi.material_override = SliceMaterials.get_mat(&"bridge_deck")
	mi.transform = Transform3D(basis, mid)
	add_child(mi)

	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width, 0.60, slen)
	cs.shape = bs
	cs.transform = Transform3D(basis, mid)
	body.add_child(cs)

	for sx: float in [-width * 0.5 + 0.12, width * 0.5 - 0.12]:
		var r_off := basis * Vector3(sx, 0.85, 0.0)
		var rcs := CollisionShape3D.new()
		var rbs := BoxShape3D.new()
		rbs.size = Vector3(0.18, 1.1, slen)
		rcs.shape = rbs
		rcs.transform = Transform3D(basis, mid + r_off)
		body.add_child(rcs)


func _build_shaft_mist() -> void:
	# Warm golden-amber volumetric mist swirling around the lower catwalks beneath the bell mouth.
	var fv := FogVolume.new()
	fv.name = "BelfryGoldenMist"
	fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fv.size = Vector3(360.0, 140.0, 360.0)
	fv.position = Vector3(0.0, -52.0, 0.0)
	var fm := FogMaterial.new()
	fm.density = 0.0055
	fm.albedo = Color(0.95, 0.72, 0.40)
	fm.emission = Color(0.46, 0.28, 0.12)
	fm.edge_fade = 0.35
	fv.material = fm
	add_child(fv)


func console_prompt() -> String:
	if _strike_timer >= 0.0 and _strike_timer < 4.5:
		return "The Void Bell is resonating across the Mantle..."
	return "[E] Toll The Void Bell — Sound the Continuum Resonance"


func activate_console(ambience: AmbienceManager) -> String:
	if ambience != null:
		ambience.trigger_void_bell()
	else:
		on_bell_struck()
	return "The 17 m iron striker swings — The Void Bell tolls across the 17.5 km chasm..."


func on_bell_struck() -> void:
	_strike_timer = 0.0


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var span := (_top - _bottom) * 0.68
	var mid := (_top + _bottom) * 0.5
	for c: Dictionary in _cars:
		var n: Node3D = c.node
		var u := fposmod(t * float(c.speed) / span + float(c.phase), 2.0)
		if u > 1.0:
			u = 2.0 - u
		n.position.y = mid + (u - 0.5) * span

	# Animate the 17 m spherical clapper swing, golden interior vault shockwave flare,
	# and subtle low-frequency bell canopy vibration when The Void Bell tolls!
	if _strike_timer >= 0.0:
		_strike_timer += delta
		var st := _strike_timer
		var damp := exp(-st * 0.19)
		if _clapper_pivot != null:
			var swing := sin(st * 2.35) * 0.19 * damp
			_clapper_pivot.rotation.z = swing
			_clapper_pivot.rotation.x = sin(st * 1.18) * 0.05 * damp
		if _bell_root != null:
			var vib := sin(st * 26.0) * 0.14 * exp(-st * 0.55)
			_bell_root.position = _bell_base_pos + Vector3(vib, 0.0, vib * 0.6)
		if _vault_light != null and _strike_light != null:
			var flash := exp(-st * 0.38) * (0.65 + 0.35 * absf(cos(st * 2.35)))
			_vault_light.light_energy = 5.8 + 6.5 * flash
			_strike_light.light_energy = 5.2 + 7.5 * flash
		if st > 22.0:
			_strike_timer = -1.0
			if _clapper_pivot != null:
				_clapper_pivot.rotation = Vector3.ZERO
			if _bell_root != null:
				_bell_root.position = _bell_base_pos
			if _vault_light != null:
				_vault_light.light_energy = 5.8
			if _strike_light != null:
				_strike_light.light_energy = 5.2
