class_name HighwaySite
extends Node3D
## Multi-lane urban trunk highway & layered megablock gallery corridor (frame 375s).
## Sits directly along STK-0412's main avenue between Market Street (-1100 m) and
## the Foundry industrial pipes (+1100 m). Central transit lane (z in [-7, +7])
## stays completely flat and collision-free for the player and --autopilot while
## outer lanes carry an animated MultiMesh stream of distant industrial vehicles.

const ROAD_HALF := 22.0
const WALL_Z := 24.5
const TRAFFIC_COUNT := 96

var _xa := -1100.0
var _xb := 1100.0
var _cars_body: MultiMeshInstance3D
var _cars_head: MultiMeshInstance3D
var _cars_tail: MultiMeshInstance3D
var _traffic: Array = []   # { "x": float, "z": float, "v": float, "len": float, "h": float, "w": float }


static func build(stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := HighwaySite.new()
	s._build(site)
	return s


func _build(site: Dictionary) -> void:
	var r: Array = site.rect
	_xa = float(r[0])
	_xb = float(r[2])
	var xm := (_xa + _xb) * 0.5
	var length := _xb - _xa
	var body := StaticBody3D.new()
	add_child(body)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.id))

	# 1. Multi-lane dark roadway deck + low outer concrete jersey barriers (z = ±22.5).
	# Central z in [-21.5, +21.5] has zero solid obstacles so walking & --autopilot stay unobstructed.
	SliceMaterials.add_box(self, null, Vector3(xm, -0.02, 0.0), Vector3(length, 0.08, ROAD_HALF * 2.0), &"concrete_floor", false)
	var barriers: Array = []
	var stripes: Array = []
	# Leave clean pedestrian/ramp access openings in the outer jersey barriers at corridor ends (-1046, +1046)
	# and overpass landings (-510, +290) so players can walk freely between Market/Pipes, highway deck, ramps, and galleries.
	var barrier_spans := [
		[_xa + 54.0, -514.0],
		[-496.0, 286.0],
		[304.0, _xb - 54.0],
	]
	for side: float in [-1.0, 1.0]:
		var bz: float = side * (ROAD_HALF + 0.45)
		for sp: Array in barrier_spans:
			var bx0: float = sp[0]
			var bx1: float = sp[1]
			var blen := bx1 - bx0
			var bcx := (bx0 + bx1) * 0.5
			barriers.append({ "c": Vector3(bcx, 0.55, bz), "s": Vector3(blen, 1.1, 0.9) })
			SliceMaterials.add_collision_box(body, Vector3(bcx, 0.55, bz), Vector3(blen, 1.1, 0.9))
		# Continuous outer shoulder curb & inner express lane divider stripes.
		stripes.append({ "c": Vector3(xm, 0.032, side * 19.2), "s": Vector3(length - 8.0, 0.016, 0.24) })
		stripes.append({ "c": Vector3(xm, 0.032, side * 6.8), "s": Vector3(length - 8.0, 0.016, 0.26) })
	# Dashed highway lane dividers along x every 24 m.
	var sx := _xa + 12.0
	while sx < _xb - 12.0:
		for lz: float in [-13.0, 0.0, 13.0]:
			stripes.append({ "c": Vector3(sx, 0.032, lz), "s": Vector3(7.5, 0.016, 0.22) })
		sx += 24.0
	SliceMaterials.add_multimesh(self, barriers, &"concrete")
	SliceMaterials.add_multimesh(self, stripes, &"rail_steel")

	# 2. Towering layered megablock gallery walls flanking both sides of the trunk highway (375s rhythm).
	var lower_arcades: Array = []
	var upper_blocks: Array = []
	var steel: Array = []
	var signs: Dictionary = {}
	var lamp_heads: Array = []
	var lamp_glows: Array = []
	var gallery_strips: Array = []
	var sign_boards: Array = []

	for side: float in [-1.0, 1.0]:
		var bx := _xa + 14.0
		while bx < _xb - 36.0:
			var w := rng.randf_range(34.0, 62.0)
			if bx + w > _xb - 12.0:
				w = _xb - 12.0 - bx
			var cx := bx + w * 0.5
			var depth := 15.0
			var zc: float = side * (WALL_Z + depth * 0.5)
			var h_low := rng.randf_range(16.0, 26.0)
			var h_high := rng.randf_range(78.0, 165.0)
			# Lower lit shopfront / arcade gallery podium.
			lower_arcades.append({ "c": Vector3(cx, (h_low - 1.0) * 0.5, zc), "s": Vector3(w - 2.0, h_low + 1.0, depth), "seed": rng.randf() * 0.9 })
			SliceMaterials.add_collision_box(body, Vector3(cx, h_low * 0.5, zc), Vector3(w - 2.0, h_low, depth))
			# Recessed upper megablock tower rising into the amber haze.
			var z_hi: float = side * (WALL_Z + depth * 0.62)
			upper_blocks.append({ "c": Vector3(cx, h_low + (h_high - h_low) * 0.5, z_hi), "s": Vector3(w - 5.0, h_high - h_low + 1.0, depth * 0.92), "seed": rng.randf() * 0.9 })
			# Stacked multi-tier illuminated pedestrian galleries along both canyon walls (375s horizontal ribbons!).
			# Level 1 (y = 16 m) is built below as a continuous 2.2 km walkable skywalk gallery; upper tiers sit at 29 m & 44 m.
			for gy: float in [29.0, 44.0]:
				steel.append({ "c": Vector3(cx, gy, side * (WALL_Z - 1.5)), "s": Vector3(w - 0.6, 1.1, 3.4) })
				steel.append({ "c": Vector3(cx, gy + 1.1, side * (WALL_Z - 3.0)), "s": Vector3(w - 0.6, 1.0, 0.25) })
				gallery_strips.append({ "c": Vector3(cx, gy + 2.4, side * (WALL_Z - 0.2)), "s": Vector3(w - 3.4, 2.3, 0.22) })
			# Lit arcade window ribbon behind the walkable Level-1 gallery (y = 16 m).
			gallery_strips.append({ "c": Vector3(cx, 18.4, side * (WALL_Z - 0.2)), "s": Vector3(w - 3.4, 2.3, 0.22) })
			# Heavy vertical structural pilasters framing each megablock bay (tucked flush to facade so gallery stays walkable).
			steel.append({ "c": Vector3(bx + 0.8, 36.0, side * (WALL_Z + 0.3)), "s": Vector3(1.8, 72.0, 1.4) })
			# Restrained vertical mounted civic/commercial signs on steel brackets (375s palette).
			if rng.randf() < 0.62:
				var smat: StringName = [&"sign_yellow", &"sign_cyan", &"sign_green", &"sign_magenta"][rng.randi() % 4]
				if not signs.has(smat):
					signs[smat] = []
				var sy := rng.randf_range(21.0, 38.0)
				var sh := rng.randf_range(4.2, 7.6)
				var sz_p: float = side * (WALL_Z - 3.8)
				signs[smat].append({ "c": Vector3(cx, sy, sz_p), "s": Vector3(0.32, sh, 1.55) })
				steel.append({ "c": Vector3(cx, sy, sz_p), "s": Vector3(0.22, sh + 0.3, 1.72) })
				steel.append({ "c": Vector3(cx, sy + sh * 0.35, side * (WALL_Z - 1.9)), "s": Vector3(0.18, 0.18, 3.6) })
				steel.append({ "c": Vector3(cx, sy - sh * 0.35, side * (WALL_Z - 1.9)), "s": Vector3(0.18, 0.18, 3.6) })
			bx += w + rng.randf_range(5.0, 12.0)

	# 3. Continuous 2.2 km walkable Level-1 skywalk galleries (y = 16 m along both canyon walls)
	#    + twin walkable pedestrian overpasses (-460, +340) + highway-level access ramps so players can
	#    walk seamlessly onto the multi-lane highway deck, up/down ramps, across overpasses, and down both galleries.
	var oy := 16.0
	var overpasses := [-460.0, 340.0]
	for side: float in [-1.0, 1.0]:
		var gz: float = side * (WALL_Z - 1.7)
		var grz: float = side * (WALL_Z - 3.35)
		# Continuous walkable concrete/steel skywalk deck along the full 2.2 km highway wall.
		SliceMaterials.add_box(self, body, Vector3(xm, oy - 0.5, gz), Vector3(length, 1.0, 3.4), &"structure")
		# Open guardrail along the gallery edge, split cleanly around overpass bridge junctions (ox ± 3 m).
		var rail_segs := [
			[_xa, overpasses[0] - 3.0],
			[overpasses[0] + 3.0, overpasses[1] - 3.0],
			[overpasses[1] + 3.0, _xb],
		]
		for rs: Array in rail_segs:
			var rx0: float = rs[0]
			var rx1: float = rs[1]
			var rlen_s := rx1 - rx0
			var rcx := (rx0 + rx1) * 0.5
			SliceMaterials.add_collision_box(body, Vector3(rcx, oy + 0.6, grz), Vector3(rlen_s, 1.2, 0.2))
			steel.append({ "c": Vector3(rcx, oy + 1.02, grz), "s": Vector3(rlen_s, 0.08, 0.08) })
			steel.append({ "c": Vector3(rcx, oy + 0.52, grz), "s": Vector3(rlen_s, 0.06, 0.06) })
	for ox: float in overpasses:
		# Span overpass deck strictly between the inner edges of the two 2.2 km skywalk galleries (|z| <= 21.1)
		# so zero floor faces overlap at the junctions!
		SliceMaterials.add_box(self, body, Vector3(ox, oy - 0.5, 0.0), Vector3(6.0, 1.0, (WALL_Z - 3.4) * 2.0), &"concrete")
		# Open guardrails span only the central highway gap (|z| <= 18.1) on the west side (leaving a clean
		# 3.0 m ramp entry at |z| in [18.1, 21.1] down to the highway road) and |z| <= 21.1 on the east side
		# (so BOTH ends open directly onto the 2.2 km elevated skywalk galleries!).
		for es: float in [-1.0, 1.0]:
			var half_span := (WALL_Z - 6.4) if es < 0.0 else (WALL_Z - 3.4)
			var clear_span := half_span * 2.0
			SliceMaterials.add_collision_box(body, Vector3(ox + es * 2.9, oy + 0.6, 0.0), Vector3(0.2, 1.2, clear_span))
			steel.append({ "c": Vector3(ox + es * 2.9, oy + 1.02, 0.0), "s": Vector3(0.08, 0.08, clear_span) })
			steel.append({ "c": Vector3(ox + es * 2.9, oy + 0.52, 0.0), "s": Vector3(0.06, 0.06, clear_span) })
			var pz := -half_span + 0.2
			while pz <= half_span - 0.2:
				steel.append({ "c": Vector3(ox + es * 2.9, oy + 0.52, pz), "s": Vector3(0.07, 1.04, 0.07) })
				pz += 3.5
			# Walkable wide access ramps descending along the inner highway shoulder (|z| = 19.6, width 2.8 m —
			# clear of both outer traffic lanes at |z|=15.8 and the 2.2 km gallery deck at |z|=22.8) from the
			# overpass (x = ox - 3, y = 16 m) cleanly down onto the highway asphalt (x = ox - 45, y = 0 m)!
			var r_dx := 42.0
			var r_len := sqrt(r_dx * r_dx + oy * oy)
			var r_pitch := atan2(oy, r_dx)
			var rz: float = es * 19.6
			SliceMaterials.add_box(self, body, Vector3(ox - 3.0 - r_dx * 0.5, oy * 0.5 - 0.45, rz), Vector3(r_len + 0.8, 0.9, 2.8), &"concrete", true, Vector3(0.0, 0.0, r_pitch))
			# Low outer concrete curb along the traffic-facing edge of the descending ramp.
			SliceMaterials.add_box(self, body, Vector3(ox - 3.0 - r_dx * 0.5, oy * 0.5 + 0.5, es * 18.25), Vector3(r_len, 1.0, 0.3), &"concrete", true, Vector3(0.0, 0.0, r_pitch))
			# Support pier stops cleanly underneath the gallery deck (y = 0..oy - 1.0) so zero top-face overlap!
			SliceMaterials.add_box(self, body, Vector3(ox, (oy - 1.0) * 0.5, es * (ROAD_HALF + 2.0)), Vector3(2.0, oy - 1.0, 1.6), &"structure")
		# Diegetic sign at the ramp entrance on the overpass pointing down to the highway lanes.
		SliceMaterials.add_sign(self, Vector3(ox - 2.95, oy + 2.1, -19.6), "↓ HIGHWAY DECK (0 M)", 0.011, Color(1.0, 0.88, 0.6), -PI * 0.5)
		SliceMaterials.add_sign(self, Vector3(ox - 2.95, oy + 2.1, 19.6), "↓ HIGHWAY DECK (0 M)", 0.011, Color(1.0, 0.88, 0.6), -PI * 0.5)

	# End-of-corridor gallery access ramps at west (Market transition) & east (Foundry Pipes transition)
	# plus monumental district threshold arches & subtle gallery work lamps / maintenance cabinets.
	var r_end_dx := 42.0
	var r_end_len := sqrt(r_end_dx * r_end_dx + oy * oy)
	var r_end_pitch := atan2(oy, r_end_dx)
	for side: float in [-1.0, 1.0]:
		var rz_e: float = side * 19.6
		# West ramp climbs east (+X) from Market exit (_xa + 6, y = 0) up to gallery (_xa + 48, y = 16 m).
		SliceMaterials.add_box(self, body, Vector3(_xa + 6.0 + r_end_dx * 0.5, oy * 0.5 - 0.45, rz_e), Vector3(r_end_len + 0.6, 0.9, 2.8), &"concrete", true, Vector3(0.0, 0.0, r_end_pitch))
		# East ramp climbs west (-X) from Foundry Pipes (_xb - 6, y = 0) up to gallery (_xb - 48, y = 16 m).
		SliceMaterials.add_box(self, body, Vector3(_xb - 6.0 - r_end_dx * 0.5, oy * 0.5 - 0.45, rz_e), Vector3(r_end_len + 0.6, 0.9, 2.8), &"concrete", true, Vector3(0.0, 0.0, -r_end_pitch))
	# Gallery wall sconces & subtle roadside maintenance service cabinets every 140 m along the 2.2 km skywalk.
	var maint_boxes: Array = []
	var mx := _xa + 140.0
	while mx <= _xb - 140.0:
		for side: float in [-1.0, 1.0]:
			var mz: float = side * (WALL_Z - 0.45)
			lamp_heads.append({ "c": Vector3(mx, oy + 3.6, mz), "s": Vector3(0.7, 0.24, 0.35) })
			lamp_glows.append(Vector3(mx, oy + 3.4, mz - side * 0.25))
			maint_boxes.append({ "c": Vector3(mx + 18.0, oy + 0.95, mz), "s": Vector3(1.1, 1.9, 0.55) })
			SliceMaterials.add_collision_box(body, Vector3(mx + 18.0, oy + 0.95, mz), Vector3(1.1, 1.9, 0.55))
		mx += 140.0
	if not maint_boxes.is_empty():
		SliceMaterials.add_multimesh(self, maint_boxes, &"container_grey")
	# District threshold signage at both ends of Trunk Route 77-E.
	SliceMaterials.add_sign(self, Vector3(_xa + 4.0, 14.5, 0.0), "TRUNK ROUTE 77-E  ·  UPPER GALLERIES ↑", 0.026, Color(1.0, 0.86, 0.56), -PI * 0.5)
	SliceMaterials.add_sign(self, Vector3(_xb - 4.0, 14.5, 0.0), "INDUSTRIAL PIPE CORRIDOR  ·  FOUNDRY HALL →", 0.026, Color(1.0, 0.86, 0.56), -PI * 0.5)

	# 4. Monumental overhead steel highway route gantries (every 115 m) with crisp backlit transit boards (ref 375s).
	var gantry_labels := [
		["77-E  ·  FOUNDRY", "BR-077-A  ·  EXPRESS"],
		["SECTOR 412  ·  EAST", "TRUNK LANES  ·  3.0 KM"],
		["EAST GATE  ·  TRAM", "FREIGHT  ·  THROUGH"],
		["MANTLE 77  ·  MAIN", "FOUNDRY HALL  ·  →"],
	]
	var gi := 0
	var gx := _xa + 95.0
	while gx <= _xb - 80.0:
		if absf(gx - float(overpasses[0])) < 32.0 or absf(gx - float(overpasses[1])) < 32.0:
			gx += 45.0
		for side: float in [-1.0, 1.0]:
			steel.append({ "c": Vector3(gx, 9.5, side * (ROAD_HALF + 1.5)), "s": Vector3(1.3, 19.0, 1.3) })
			SliceMaterials.add_collision_box(body, Vector3(gx, 9.5, side * (ROAD_HALF + 1.5)), Vector3(1.3, 19.0, 1.3))
		# Main highway truss girder spanning z = -24..+24 at y = 15.2 m.
		steel.append({ "c": Vector3(gx, 15.0, 0.0), "s": Vector3(1.1, 1.2, ROAD_HALF * 2.0 + 4.0) })
		steel.append({ "c": Vector3(gx, 17.2, 0.0), "s": Vector3(0.9, 0.8, ROAD_HALF * 2.0 + 4.0) })
		# Twin backlit pale-gray overhead transit sign boards framed in dark steel (iconic 375s look!).
		var pair: Array = gantry_labels[gi % gantry_labels.size()]
		for bi in 2:
			var bz := -9.5 if bi == 0 else 9.5
			steel.append({ "c": Vector3(gx, 15.8, bz), "s": Vector3(0.85, 3.3, 11.4) })
			sign_boards.append({ "c": Vector3(gx - 0.48, 15.8, bz), "s": Vector3(0.08, 2.75, 10.6) })
			sign_boards.append({ "c": Vector3(gx + 0.48, 15.8, bz), "s": Vector3(0.08, 2.75, 10.6) })
			SliceMaterials.add_sign(self, Vector3(gx - 0.56, 15.8, bz), String(pair[bi]), 0.024, Color(0.08, 0.07, 0.06), -PI * 0.5)
			SliceMaterials.add_sign(self, Vector3(gx + 0.56, 15.8, bz), "← MARKET 77-W", 0.024, Color(0.08, 0.07, 0.06), PI * 0.5)
		# Overhead sodium-amber highway luminaire bar underneath the gantry.
		for lz: float in [-13.5, 0.0, 13.5]:
			lamp_heads.append({ "c": Vector3(gx, 14.1, lz), "s": Vector3(0.9, 0.22, 1.4) })
			lamp_glows.append(Vector3(gx, 13.8, lz))
		var gl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.8, 38.0)
		gl.position = Vector3(gx, 12.6, 0.0)
		gl.distance_fade_begin = 380.0
		add_child(gl)
		# High elevated skywalk truss & centered transit sign spanning the upper canyon at y = 34 m every 2nd gantry.
		if gi % 2 == 1:
			steel.append({ "c": Vector3(gx, 34.0, 0.0), "s": Vector3(2.8, 2.4, WALL_Z * 2.0 + 4.0) })
			steel.append({ "c": Vector3(gx, 34.0, 0.0), "s": Vector3(3.1, 3.0, 9.6) })
			sign_boards.append({ "c": Vector3(gx - 1.6, 34.0, 0.0), "s": Vector3(0.08, 2.4, 8.8) })
			sign_boards.append({ "c": Vector3(gx + 1.6, 34.0, 0.0), "s": Vector3(0.08, 2.4, 8.8) })
		gi += 1
		gx += 115.0

	SliceMaterials.add_multimesh(self, lower_arcades, &"shopfront")
	SliceMaterials.add_multimesh(self, upper_blocks, &"building")
	SliceMaterials.add_multimesh(self, steel, &"structure")
	SliceMaterials.add_multimesh(self, gallery_strips, &"gallery_strip")
	SliceMaterials.add_multimesh(self, sign_boards, &"sign_board_lit")
	for smat: StringName in signs:
		SliceMaterials.add_multimesh(self, signs[smat], smat)
	SliceMaterials.add_multimesh(self, lamp_heads, &"lamp")
	SliceMaterials.add_coronas(self, lamp_glows, 2.8, &"corona_soft")

	# 4. Sheltered roadside maintenance alcove & diegetic log tucked outside the north jersey barrier.
	add_child(ReadableNote.create(
		"NOTE-HIGHWAY-412", "Trunk Route 77-E Log",
		"STK-0412  ·  FLOOR 77 TRUNK HIGHWAY\n\n"
		+ "Automated freight convoys run nonstop on the outer lanes between Market 77-W "
		+ "and the East Foundry docks.\n"
		+ "Pedestrians on foot should keep to the central divider lane or the upper galleries.\n"
		+ "Next landmark east: Pipe Corridor & Foundry Hall (1.1 km).",
		Vector3(-120.0, 1.45, -(ROAD_HALF + 0.05)), 0.0, "plaque"))

	# 5. Animated distant industrial highway traffic (visual-only MultiMeshes on outer lanes z = ±10.5, ±15.5).
	_setup_traffic(rng)


func _setup_traffic(rng: RandomNumberGenerator) -> void:
	var lanes := [-15.8, -10.5, 10.5, 15.8]
	var dirs := [-1.0, -1.0, 1.0, 1.0]
	var speeds := [24.0, 31.0, 29.0, 22.0]
	var bodies: Array = []
	var heads: Array = []
	var tails: Array = []
	for i in TRAFFIC_COUNT:
		var li := i % 4
		var x := lerpf(_xa + 20.0, _xb - 20.0, (float(i) + rng.randf() * 0.7) / float(TRAFFIC_COUNT))
		var vlen := rng.randf_range(4.4, 9.2)
		var vh := rng.randf_range(1.6, 2.8)
		var vw := rng.randf_range(1.9, 2.4)
		var z: float = lanes[li]
		var v: float = dirs[li] * (speeds[li] + rng.randf_range(-3.0, 3.0))
		_traffic.append({ "x": x, "z": z, "v": v, "len": vlen, "h": vh, "w": vw })
		var dir_i := 1.0 if v > 0.0 else -1.0
		bodies.append({ "c": Vector3(x, vh * 0.5 + 0.35, z), "s": Vector3(vlen, vh, vw) })
		heads.append({ "c": Vector3(x + dir_i * (vlen * 0.5 + 0.16), 0.85, z), "s": Vector3(0.26, 0.28, vw * 0.78) })
		tails.append({ "c": Vector3(x - dir_i * (vlen * 0.5 + 0.16), 0.92, z), "s": Vector3(0.26, 0.24, vw * 0.82) })
	_cars_body = SliceMaterials.add_multimesh(self, bodies, &"container_grey")
	_cars_head = SliceMaterials.add_multimesh(self, heads, &"tram_headlamp")
	_cars_tail = SliceMaterials.add_multimesh(self, tails, &"beacon_red")
	_sync_traffic()


func _process(delta: float) -> void:
	if _traffic.is_empty():
		return
	var span := _xb - _xa - 24.0
	for car: Dictionary in _traffic:
		var x: float = float(car.x) + float(car.v) * delta
		if x > _xb - 12.0:
			x -= span
		elif x < _xa + 12.0:
			x += span
		car.x = x
	_sync_traffic()


func _sync_traffic() -> void:
	var mm_b := _cars_body.multimesh
	var mm_h := _cars_head.multimesh
	var mm_t := _cars_tail.multimesh
	for i in _traffic.size():
		var car: Dictionary = _traffic[i]
		var x: float = car.x
		var z: float = car.z
		var dir := 1.0 if float(car.v) > 0.0 else -1.0
		var vlen: float = car.len
		var vh: float = car.h
		var vw: float = car.w
		mm_b.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(vlen, vh, vw)), Vector3(x, vh * 0.5 + 0.35, z)))
		mm_h.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(0.28, 0.28, vw * 0.78)), Vector3(x + dir * (vlen * 0.5 + 0.14), 0.85, z)))
		mm_t.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(0.28, 0.24, vw * 0.82)), Vector3(x - dir * (vlen * 0.5 + 0.14), 0.92, z)))
