class_name ConnectionRuntime
extends WorldAnchor
## A physical route between two world points (bridge for now). Anchored at its
## midpoint; local +X runs from endpoint a to endpoint b. Deck top = local y 0.

var def: Dictionary
var length := 0.0


static func build(conn_def: Dictionary) -> ConnectionRuntime:
	var c := ConnectionRuntime.new()
	c.def = conn_def
	c.name = conn_def.id
	var a: Array = conn_def.a
	var b: Array = conn_def.b
	c.lx = (float(a[0]) + float(b[0])) * 0.5
	c.ly = float(a[1])
	c.lz = (float(a[2]) + float(b[2])) * 0.5
	var dx := float(b[0]) - float(a[0])
	var dz := float(b[2]) - float(a[2])
	c.length = sqrt(dx * dx + dz * dz)
	c.rotation.y = atan2(-dz, dx)
	match String(conn_def.kind):
		"bridge":
			c._build_bridge()
		_:
			push_error("Unsupported connection kind: %s" % conn_def.kind)
	return c


func _build_bridge() -> void:
	var L := length
	var w := float(def.width)
	var dt := float(def.deck_thickness)
	var body := StaticBody3D.new()
	body.name = "Collision"
	add_child(body)
	body.set_meta(&"surface", "metal")
	SliceMaterials.add_box(self, body, Vector3(0, -dt * 0.5, 0), Vector3(L, dt, w), &"bridge_deck")
	# Open railing with a glowing handrail (frame 125s). Split into 100 m
	# segments for clean culling and precision; north side opens at x in [-2, 2]
	# into the mid-span maintenance shelter alcove.
	var posts: Array = []
	var rail_glows: Array = []
	var mid_rails: Array = []
	var girders: Array = []
	var alcove_x := 12.0
	var alcove_half := 2.2
	var ax0 := alcove_x - alcove_half
	var ax1 := alcove_x + alcove_half
	# South boarding doorways at both ends for the TRAM-077 maintenance rail car.
	var tw0 := -L * 0.5 + 9.5
	var tw1 := -L * 0.5 + 14.5
	var te0 := L * 0.5 - 14.5
	var te1 := L * 0.5 - 9.5
	for s: float in [-1.0, 1.0]:
		var zr: float = s * (w * 0.5 - 0.1)
		if s < 0.0:
			var len_w := ax0 - (-L * 0.5)
			var len_e := (L * 0.5) - ax1
			SliceMaterials.add_collision_box(body, Vector3(-L * 0.5 + len_w * 0.5, 0.58, zr), Vector3(len_w, 1.15, 0.1))
			SliceMaterials.add_collision_box(body, Vector3(ax1 + len_e * 0.5, 0.58, zr), Vector3(len_e, 1.15, 0.1))
		else:
			# Split south collision railing cleanly around west & east tram boarding gates.
			for seg: Array in [[-L * 0.5, tw0], [tw1, te0], [te1, L * 0.5]]:
				var sa := float(seg[0])
				var sb := float(seg[1])
				SliceMaterials.add_collision_box(body, Vector3((sa + sb) * 0.5, 0.58, zr), Vector3(sb - sa, 1.15, 0.1))
		var rx := -L * 0.5
		while rx < L * 0.5 - 0.01:
			var rxe := minf(rx + 25.0, L * 0.5)
			girders.append({ "c": Vector3((rx + rxe) * 0.5, -dt - 3.0, s * (w * 0.5 - 1.2)), "s": Vector3(rxe - rx, 6.0, 1.6) })
			# Split rail segments cleanly around north alcove or south tram boarding gates.
			var gap_a := ax0 if s < 0.0 else (tw0 if rx < 0.0 else te0)
			var gap_b := ax1 if s < 0.0 else (tw1 if rx < 0.0 else te1)
			if rx < gap_b and rxe > gap_a:
				if rx < gap_a:
					var len_a := gap_a - rx
					rail_glows.append({ "c": Vector3(rx + len_a * 0.5, 1.11, zr), "s": Vector3(len_a, 0.07, 0.07) })
					mid_rails.append({ "c": Vector3(rx + len_a * 0.5, 0.55, zr), "s": Vector3(len_a, 0.05, 0.05) })
				if rxe > gap_b:
					var len_b := rxe - gap_b
					rail_glows.append({ "c": Vector3(gap_b + len_b * 0.5, 1.11, zr), "s": Vector3(len_b, 0.07, 0.07) })
					mid_rails.append({ "c": Vector3(gap_b + len_b * 0.5, 0.55, zr), "s": Vector3(len_b, 0.05, 0.05) })
			else:
				rail_glows.append({ "c": Vector3((rx + rxe) * 0.5, 1.11, zr), "s": Vector3(rxe - rx, 0.07, 0.07) })
				mid_rails.append({ "c": Vector3((rx + rxe) * 0.5, 0.55, zr), "s": Vector3(rxe - rx, 0.05, 0.05) })
			rx = rxe
		var px := -L * 0.5 + 1.0
		while px < L * 0.5:
			var in_n_gap := s < 0.0 and px > ax0 and px < ax1
			var in_s_gap := s > 0.0 and ((px > tw0 and px < tw1) or (px > te0 and px < te1))
			if not in_n_gap and not in_s_gap:
				# Posts sit flush under the handrail (top 1.07 < rail bottom 1.075) and slightly narrower.
				posts.append({ "c": Vector3(px, 0.535, zr), "s": Vector3(0.06, 1.07, 0.06) })
			px += 2.0
	SliceMaterials.add_multimesh(self, rail_glows, &"rail_glow")
	SliceMaterials.add_multimesh(self, mid_rails, &"structure")
	SliceMaterials.add_multimesh(self, girders, &"structure")
	SliceMaterials.add_multimesh(self, posts, &"structure_fade_near")
	# Piers descending into the lower Mantle (caps sit strictly between girders, no coplanar faces).
	var pd := float(def.pier_depth)
	var spacing := float(def.pier_spacing)
	var piers: Array = []
	var x := -L * 0.5 + spacing * 0.5
	while x < L * 0.5:
		piers.append({ "c": Vector3(x, -dt - 6.0 - pd * 0.5, 0), "s": Vector3(8.0, pd, w - 2.0) })
		piers.append({ "c": Vector3(x, -dt - 2.975, 0), "s": Vector3(4.0, 5.85, w - 4.4) })
		x += spacing
	SliceMaterials.add_multimesh(self, piers, &"structure")
	# Route lamps: readable line of light across the gap; transitions subtly from
	# warm amber (STK-0412) to cool white on the final 600 m approaching STK-0413.
	var ls := float(def.lamp_spacing)
	var poles: Array = []
	var heads_warm: Array = []
	var heads_cool: Array = []
	var glows_warm: Array = []
	var glows_cool: Array = []
	var i := 0
	x = -L * 0.5 + ls * 0.5
	while x < L * 0.5:
		var side := -1.0 if i % 2 == 0 else 1.0
		var base := Vector3(x, 0, side * (w * 0.5 - 0.5))
		var is_cool := x > 900.0
		poles.append({ "c": base + Vector3(0, 2.0, 0), "s": Vector3(0.15, 4.0, 0.15) })
		if is_cool:
			heads_cool.append({ "c": base + Vector3(0, 4.05, 0), "s": Vector3(0.5, 0.2, 0.5) })
			glows_cool.append(base + Vector3(0, 3.9, 0))
		else:
			heads_warm.append({ "c": base + Vector3(0, 4.05, 0), "s": Vector3(0.5, 0.2, 0.5) })
			glows_warm.append(base + Vector3(0, 3.9, 0))
		var light := SliceMaterials.make_lamp_light(SliceMaterials.COOL if is_cool else SliceMaterials.WARM, 1.8, 13.0)
		light.position = base + Vector3(0, 3.8, -side * 0.5)
		add_child(light)
		x += ls
		i += 1
	SliceMaterials.add_multimesh(self, poles, &"structure_fade_mid")
	SliceMaterials.add_multimesh(self, heads_warm, &"lamp")
	SliceMaterials.add_multimesh(self, heads_cool, &"lamp_cool")
	SliceMaterials.add_coronas(self, glows_warm, 1.8)
	SliceMaterials.add_coronas(self, glows_cool, 1.8, &"corona_cool")
	_build_tram_track(body, w, dt)
	_build_landmarks(body, w, dt)
	_build_midspan_shelter(body, w, dt)
	add_child(BridgeTram.build(L))


## Cantilevered south maintenance rail track (z = BridgeTram.TRACK_Z = +8.1)
## plus steel boarding thresholds at both ends of BR-077-A.
func _build_tram_track(body: StaticBody3D, w: float, dt: float) -> void:
	var L := length
	var tz := BridgeTram.TRACK_Z
	var track_steel: Array = []
	var rail_bars: Array = []
	var x := -L * 0.5
	while x < L * 0.5 - 0.01:
		var xe := minf(x + 50.0, L * 0.5)
		var xm := (x + xe) * 0.5
		var seg := xe - x
		# Main track girder bed under the twin rails (y = -0.82 .. -2.0).
		track_steel.append({ "c": Vector3(xm, -1.42, tz), "s": Vector3(seg, 1.2, 2.4) })
		# Twin steel running rails (y = -0.74).
		rail_bars.append({ "c": Vector3(xm, -0.76, tz - 0.7), "s": Vector3(seg, 0.14, 0.14) })
		rail_bars.append({ "c": Vector3(xm, -0.76, tz + 0.7), "s": Vector3(seg, 0.14, 0.14) })
		# Outrigger cantilever bracket tying the tram track into the main south bridge girder.
		track_steel.append({ "c": Vector3(x + 25.0, -dt - 0.6, (w * 0.5 + tz) * 0.5), "s": Vector3(0.7, 1.3, tz - w * 0.5 + 1.8) })
		x = xe
	SliceMaterials.add_multimesh(self, track_steel, &"structure")
	SliceMaterials.add_multimesh(self, rail_bars, &"rail_steel")
	# Steel boarding thresholds bridging the 0.7 m gap between pedestrian deck (+6.0) and tram (+6.7).
	for bx: float in [-L * 0.5 + 12.0, L * 0.5 - 12.0]:
		SliceMaterials.add_box(self, body, Vector3(bx, -0.14, 6.35), Vector3(5.0, 0.28, 0.72), &"bridge_deck")


## Sparse structural portal gantries every 500 m with monumental cable-stay
## pylon towers at 1.0 km and 2.0 km plus diegetic distance markers so
## long-distance progress across the 3 km gap is readable without bright pathing.
func _build_landmarks(_body: StaticBody3D, w: float, dt: float) -> void:
	var L := length
	var steel: Array = []
	var cables: Array = []
	var beacons: Array = []
	var lamp_heads_warm: Array = []
	var lamp_heads_cool: Array = []
	var lamp_glows_warm: Array = []
	var lamp_glows_cool: Array = []
	var step := 500.0
	var gx := -L * 0.5 + step
	while gx < L * 0.5 - 100.0:
		var km_from_a := (gx + L * 0.5) / 1000.0
		var km_to_b := (L * 0.5 - gx) / 1000.0
		var is_pylon := absf(absf(gx) - 500.0) < 10.0
		var is_cool := gx > 900.0
		var z_north := -(w * 0.5 + (1.05 if is_pylon else 0.55))
		var z_south := 10.65 if is_pylon else 10.25
		var z_span := z_south - z_north
		var z_mid := (z_north + z_south) * 0.5
		if is_pylon:
			# Monumental 46 m cable-stay suspension pylon tower straddling deck + tram track.
			for z_col: float in [z_north, z_south]:
				var sgn := -1.0 if z_col < 0.0 else 1.0
				steel.append({ "c": Vector3(gx, 19.0, z_col), "s": Vector3(1.6, 54.0, 1.6) })
				steel.append({ "c": Vector3(gx, -dt * 0.5 - 0.8, z_col - sgn * 0.6), "s": Vector3(1.2, 1.8, 1.6) })
				beacons.append({ "c": Vector3(gx, 46.35, z_col), "s": Vector3(0.55, 0.55, 0.55) })
				# Three diagonal steel stay cables anchoring east & west outside deck & tram envelope.
				var z_cab := z_col - sgn * 0.5
				for dir: float in [-1.0, 1.0]:
					for tier: Array in [[42.0, 135.0], [34.0, 90.0], [26.0, 45.0]]:
						var p0 := Vector3(gx, float(tier[0]), z_cab)
						var p1 := Vector3(gx + dir * float(tier[1]), 0.2, z_cab)
						var v := p1 - p0
						var clen := v.length()
						var rz := atan2(-v.x, v.y)
						cables.append({ "c": (p0 + p1) * 0.5, "s": Vector3(0.14, clen, 0.14), "r": Vector3(0.0, 0.0, rz) })
			# Lower gantry crossbeam (10.2 m) + two upper structural tie-beams (span inset inside pylon legs).
			steel.append({ "c": Vector3(gx, 10.2, z_mid), "s": Vector3(1.1, 1.0, z_span + 1.2) })
			steel.append({ "c": Vector3(gx, 28.0, z_mid), "s": Vector3(1.2, 1.3, z_span + 1.2) })
			steel.append({ "c": Vector3(gx, 44.5, z_mid), "s": Vector3(1.3, 1.5, z_span + 1.2) })
		else:
			# Twin steel portal legs outside the deck & tram track + overhead cross-beam.
			for z_col: float in [z_north, z_south]:
				var sgn := -1.0 if z_col < 0.0 else 1.0
				steel.append({ "c": Vector3(gx, 4.2, z_col), "s": Vector3(0.7, 11.4, 0.7) })
				steel.append({ "c": Vector3(gx, -dt * 0.5 - 0.6, z_col - sgn * 0.45), "s": Vector3(0.55, 1.4, 1.2) })
				steel.append({ "c": Vector3(gx, 8.6, z_col - sgn * 1.25), "s": Vector3(0.35, 3.0, 0.35), "r": Vector3(sgn * 0.72, 0.0, 0.0) })
			steel.append({ "c": Vector3(gx, 10.2, z_mid), "s": Vector3(0.8, 0.9, z_span + 0.9) })
			steel.append({ "c": Vector3(gx, 9.45, z_mid), "s": Vector3(0.3, 0.2, z_span - 0.8) })
		# Restrained overhead work lamp under gantry centre.
		if is_cool:
			lamp_heads_cool.append({ "c": Vector3(gx, 9.25, 0.0), "s": Vector3(0.9, 0.22, 0.9) })
			lamp_glows_cool.append(Vector3(gx, 9.0, 0.0))
		else:
			lamp_heads_warm.append({ "c": Vector3(gx, 9.25, 0.0), "s": Vector3(0.9, 0.22, 0.9) })
			lamp_glows_warm.append(Vector3(gx, 9.0, 0.0))
		var gl := SliceMaterials.make_lamp_light(SliceMaterials.COOL if is_cool else SliceMaterials.WARM, 1.6, 18.0)
		gl.position = Vector3(gx, 8.7, 0.0)
		add_child(gl)
		# Diegetic distance signs facing both directions of travel.
		var sign_off := 0.62 if is_pylon else 0.45
		var sign_col := Color(0.84, 0.91, 1.0) if is_cool else Color(1.0, 0.82, 0.52)
		var txt_east := "BR-077-A  ·  %.1f KM   |   STK-0413  %.1f KM" % [km_from_a, km_to_b]
		var txt_west := "BR-077-A  ·  %.1f KM   |   STK-0412  %.1f KM" % [km_to_b, km_from_a]
		SliceMaterials.add_sign(self, Vector3(gx - sign_off, 10.2, 0.0), txt_east, 0.016, sign_col, -PI * 0.5)
		SliceMaterials.add_sign(self, Vector3(gx + sign_off, 10.2, 0.0), txt_west, 0.016, sign_col, PI * 0.5)
		gx += step
	SliceMaterials.add_multimesh(self, steel, &"structure")
	SliceMaterials.add_multimesh(self, cables, &"structure_fade_far")
	SliceMaterials.add_multimesh(self, beacons, &"beacon_red")
	SliceMaterials.add_multimesh(self, lamp_heads_warm, &"lamp")
	SliceMaterials.add_multimesh(self, lamp_heads_cool, &"lamp_cool")
	SliceMaterials.add_coronas(self, lamp_glows_warm, 2.8, &"corona_soft")
	SliceMaterials.add_coronas(self, lamp_glows_cool, 2.8, &"corona_cool")


## Mid-span windbreak shelter and lookout alcove beside the 1.5 km gantry
## (x = 12), cantilevered off the north side so travellers can pause and look back.
func _build_midspan_shelter(body: StaticBody3D, w: float, dt: float) -> void:
	var sx := 12.0
	var z0 := -w * 0.5
	var z1 := z0 - 4.6
	var zc := (z0 + z1) * 0.5
	# Cantilevered deck bay and underside steel support brackets.
	SliceMaterials.add_box(self, body, Vector3(sx, -dt * 0.5, zc), Vector3(12.0, dt, 4.6), &"bridge_deck")
	SliceMaterials.add_box(self, null, Vector3(sx - 5.2, -dt - 1.4, zc), Vector3(0.6, 2.8, 4.2), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(sx + 5.2, -dt - 1.4, zc), Vector3(0.6, 2.8, 4.2), &"structure", false)
	# Sheltered west windbreak booth (x = sx-5.95..sx+1.2); north wall fits between west wall and east end.
	SliceMaterials.add_box(self, body, Vector3(sx - 5.8, 1.65, zc), Vector3(0.3, 3.3, 4.4), &"plate")
	SliceMaterials.add_box(self, body, Vector3(sx - 2.225, 1.65, z1 + 0.15), Vector3(6.85, 3.3, 0.3), &"plate")
	SliceMaterials.add_box(self, null, Vector3(sx - 2.3, 3.43, zc), Vector3(7.4, 0.24, 4.8), &"structure", false)
	# Bench and weathered maintenance crates inside the shelter.
	SliceMaterials.add_box(self, body, Vector3(sx - 3.8, 0.25, z1 + 0.7), Vector3(2.4, 0.5, 0.65), &"wood")
	SliceMaterials.add_box(self, body, Vector3(sx - 4.9, 0.45, z0 - 1.1), Vector3(1.1, 0.9, 1.1), &"container_grey")
	SliceMaterials.add_box(self, body, Vector3(sx - 4.8, 1.2, z0 - 1.1), Vector3(0.8, 0.6, 0.8), &"container_rust")
	# Open lookout railing around east and north-east perimeter (x = sx+1.2..sx+5.9).
	SliceMaterials.add_collision_box(body, Vector3(sx + 3.55, 0.58, z1 + 0.1), Vector3(4.7, 1.15, 0.1))
	SliceMaterials.add_collision_box(body, Vector3(sx + 5.9, 0.58, zc), Vector3(0.1, 1.15, 4.5))
	SliceMaterials.add_box(self, null, Vector3(sx + 3.55, 1.11, z1 + 0.1), Vector3(4.65, 0.07, 0.07), &"rail_glow", false)
	SliceMaterials.add_box(self, null, Vector3(sx + 5.9, 1.11, zc + 0.05), Vector3(0.07, 0.07, 4.4), &"rail_glow", false)
	SliceMaterials.add_box(self, null, Vector3(sx + 3.55, 0.55, z1 + 0.1), Vector3(4.65, 0.05, 0.05), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(sx + 5.9, 0.55, zc + 0.05), Vector3(0.05, 0.05, 4.4), &"structure", false)
	# Warm sheltered interior light + diegetic plaque.
	SliceMaterials.add_box(self, null, Vector3(sx - 2.3, 3.22, zc), Vector3(0.45, 0.14, 0.45), &"lamp", false)
	SliceMaterials.add_coronas(self, [Vector3(sx - 2.3, 3.12, zc)], 1.4)
	var sl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.4, 11.0)
	sl.position = Vector3(sx - 2.3, 2.9, zc)
	add_child(sl)
	SliceMaterials.add_sign(self, Vector3(sx - 2.3, 2.35, z1 + 0.35), "BR-077-A  ·  MID-SPAN SHELTER  1.5 KM", 0.008, Color(1.0, 0.85, 0.55), 0.0)
	# Risky route landmark cache tucked inside the mid-span bridge shelter.
	add_child(LootContainer.create(
		"CONT-BRIDGE-MIDSPAN", "Mid-Span Footlocker", "cache",
		Vector3(sx - 1.2, 0.0, z1 + 0.72), 0.0,
		[["condensate_can", 2], ["dried_strip", 1], ["salvaged_relay", 1]], 5, 4))
	add_child(ReadableNote.create(
		"NOTE-BRIDGE-MIDSPAN", "Traveller's Log",
		"BR-077-A — 1.5 KM WIND SHELTER\n\n"
		+ "Halfway across the gap. The wind cuts hard out on the grating—\n"
		+ "stop here to catch your breath before pushing on to STK-0413.\n"
		+ "Left spare cans and a relay in the footlocker for the next runner.",
		Vector3(sx - 3.6, 0.52, z1 + 0.72), 0.25, "paper"))
	# Wayside Shrine of The Continuum tucked cleanly against the shelter's west steel wall:
	# oxidized copper vertical-spine & three-ring emblem (Matter, Life, Memory) + votive bulbs + weathered plaque.
	var shrine := ContinuumEmblem.create(0.58, &"copper", &"structure", true)
	shrine.position = Vector3(sx - 5.56, 1.98, zc)
	shrine.rotation.y = PI * 0.5
	add_child(shrine)
	add_child(ReadableNote.create(
		"NOTE-CONTINUUM-BRIDGE", "Wayside Shrine of The Continuum",
		"THE CONTINUUM  ·  MATTER · LIFE · MEMORY\n\n"
		+ "All that stands endures through connection.\n"
		+ "Every girder, cable, shaft, and span is a vow against Severance.\n\n"
		+ "When the Void Bell tolls from the deep chasm below,\n"
		+ "hold fast to the rail and remember the bridge that carries you.",
		Vector3(sx - 5.58, 1.40, zc + 1.15), PI * 0.5, "plaque"))


func contains_local(p: Vector3) -> bool:
	return absf(p.x) <= length * 0.5 and absf(p.z) <= float(def.width) and p.y > -50.0 and p.y < 50.0
