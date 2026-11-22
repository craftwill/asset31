class_name MiningSurface
extends WorldAnchor
## Asset 31's original buried planetary mining surface at logical altitude y = 0 m
## (41 km directly beneath Floor 77, Canon §0.1).
## Not a cave or void: a real, continuously excavated planetary crust beneath the
## colossal underside keel and 60 m foundation legs of the Mantle megastructure,
## ringed by towering core-drill rigs feeding raw ore up Mining Shaft 77-N.

var _drills: Array = []


static func build(sdef: Dictionary) -> MiningSurface:
	var m := MiningSurface.new()
	m.name = String(sdef.get("id", "CRUST-00"))
	var p: Array = sdef.position
	m.lx = float(p[0])
	m.ly = float(p[1])
	m.lz = float(p[2])
	m._build()
	return m


func _build() -> void:
	var body := StaticBody3D.new()
	body.name = "CrustCollision"
	add_child(body)
	var metal := StaticBody3D.new()
	metal.name = "DeckCollision"
	metal.set_meta(&"surface", "metal")
	add_child(metal)

	# 1. Stepped excavated planetary iron-basalt crust floor (1100 x 1100 m) with
	# concentric strip-mining terraces rising around the central excavation basin.
	SliceMaterials.add_box(self, body, Vector3(0, -10.0, 0), Vector3(1100.0, 20.0, 1100.0), &"crust_rock")
	var benches: Array = []
	for tier in 4:
		var inner := 190.0 + float(tier) * 78.0
		var bh := 18.0 + float(tier) * 24.0
		var bw := 82.0
		var y_c := bh * 0.5 - 2.0
		benches.append({ "c": Vector3(0, y_c, -(inner + bw * 0.5)), "s": Vector3((inner + bw) * 2.0, bh, bw) })
		benches.append({ "c": Vector3(0, y_c, (inner + bw * 0.5)), "s": Vector3((inner + bw) * 2.0, bh, bw) })
		benches.append({ "c": Vector3(-(inner + bw * 0.5), y_c, 0), "s": Vector3(bw, bh, inner * 2.0) })
		benches.append({ "c": Vector3((inner + bw * 0.5), y_c, 0), "s": Vector3(bw, bh, inner * 2.0) })
	SliceMaterials.add_multimesh(self, benches, &"crust_rock")

	# 2. Colossal Mantle Underside Keel overhead (y = +380 m) + 6 titanic 60 m support legs
	# planting straight into the planetary crust + 300 m diameter central shaft rising upward.
	var keel: Array = []
	# Four giant underside keel slabs framing the central 300 m shaft aperture.
	keel.append({ "c": Vector3(0, 410.0, -450.0), "s": Vector3(1300.0, 60.0, 600.0) })
	keel.append({ "c": Vector3(0, 410.0, 450.0), "s": Vector3(1300.0, 60.0, 600.0) })
	keel.append({ "c": Vector3(-450.0, 410.0, 0), "s": Vector3(600.0, 60.0, 300.0) })
	keel.append({ "c": Vector3(450.0, 410.0, 0), "s": Vector3(600.0, 60.0, 300.0) })
	# Six monumental Mantle foundation legs descending 400 m into the rock.
	for k in 6:
		var ang := float(k) * TAU / 6.0 + 0.25
		var leg_r := 320.0
		var lx_p := cos(ang) * leg_r
		var lz_p := sin(ang) * leg_r
		keel.append({ "c": Vector3(lx_p, 195.0, lz_p), "s": Vector3(52.0, 420.0, 52.0) })
	# Lower collar of the 300 m cylindrical Mining Shaft 77-N plunging upward from the keel.
	var shaft_walls: Array = []
	var shaft_lamps: Array = []
	var R := 150.0
	var sides := 24
	var chord := 2.0 * R * tan(PI / float(sides))
	for i in sides:
		var ang := float(i) * TAU / float(sides)
		var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
		shaft_walls.append({ "c": Vector3(cos(ang) * (R + 4.0), 660.0, sin(ang) * (R + 4.0)), "s": Vector3(chord + 1.0, 620.0, 8.0), "r": rot, "seed": float(i) * 0.04 })
		shaft_lamps.append({ "c": Vector3(cos(ang) * (R - 3.0), 382.0, sin(ang) * (R - 3.0)), "s": Vector3(chord * 0.85, 1.4, 1.4), "r": rot })
	SliceMaterials.add_multimesh(self, keel, &"structure")
	SliceMaterials.add_multimesh(self, shaft_walls, &"stack_wall")
	SliceMaterials.add_multimesh(self, shaft_lamps, &"window_glow")

	# 3. Three colossal 145 m Vertical Core-Drill Excavation Rigs extracting iron ore from the crust.
	var rig_steel: Array = []
	var rig_beacons: Array = []
	var rig_glows: Array = []
	var rig_positions := [Vector3(-125.0, 0.0, -105.0), Vector3(135.0, 0.0, -95.0), Vector3(-15.0, 0.0, 140.0)]
	for ri in rig_positions.size():
		var rp: Vector3 = rig_positions[ri]
		# Four massive derrick corner legs + cross-bracing.
		for sx: float in [-14.0, 14.0]:
			for sz: float in [-14.0, 14.0]:
				rig_steel.append({ "c": rp + Vector3(sx, 72.0, sz), "s": Vector3(3.2, 146.0, 3.2) })
		for by: float in [28.0, 64.0, 102.0, 138.0]:
			rig_steel.append({ "c": rp + Vector3(0, by, -14.0), "s": Vector3(28.0, 2.2, 2.2) })
			rig_steel.append({ "c": rp + Vector3(0, by, 14.0), "s": Vector3(28.0, 2.2, 2.2) })
			rig_steel.append({ "c": rp + Vector3(-14.0, by, 0), "s": Vector3(2.2, 2.2, 28.0) })
			rig_steel.append({ "c": rp + Vector3(14.0, by, 0), "s": Vector3(2.2, 2.2, 28.0) })
		rig_beacons.append({ "c": rp + Vector3(0, 147.0, 0), "s": Vector3(1.8, 1.8, 1.8) })
		# Glowing excavated bore crater under the rig.
		SliceMaterials.add_box(self, null, rp + Vector3(0, 0.4, 0), Vector3(22.0, 0.8, 22.0), &"molten_slow", false)
		rig_glows.append(rp + Vector3(0, 6.0, 0))
		# Rotating glowing vertical core-drill column.
		var drill := Node3D.new()
		drill.position = rp
		add_child(drill)
		SliceMaterials.add_box(drill, null, Vector3(0, 62.0, 0), Vector3(5.5, 124.0, 5.5), &"structure", false)
		SliceMaterials.add_box(drill, null, Vector3(0, 14.0, 0), Vector3(7.4, 24.0, 7.4), &"drill_glow", false)
		_drills.append({ "node": drill, "speed": 0.45 + float(ri) * 0.12 })
		# Heavy ore-conveyor bridge running from rig toward the central shaft haulage base.
		var to_c := (Vector3(0, 18.0, 0) - (rp + Vector3(0, 28.0, 0)))
		var clen := to_c.length()
		var yaw := atan2(-to_c.x, -to_c.z)
		rig_steel.append({ "c": (rp + Vector3(0, 28.0, 0) + Vector3(0, 18.0, 0)) * 0.5, "s": Vector3(4.2, 3.6, clen), "r": Vector3(0.0, yaw, 0.0) })
		var dl := SliceMaterials.make_lamp_light(Color(1.0, 0.52, 0.22), 5.5, 120.0)
		dl.position = rp + Vector3(0, 26.0, 0)
		add_child(dl)
	SliceMaterials.add_multimesh(self, rig_steel, &"structure")
	SliceMaterials.add_multimesh(self, rig_beacons, &"beacon_red")
	SliceMaterials.add_coronas(self, rig_glows, 26.0, &"corona_molten")

	# 4. Walkable Operations Outpost CRUST-00 around the Deep Express Relay Cage landing (11.5, 0, 1.0).
	_build_outpost(body, metal)


func _build_outpost(body: StaticBody3D, metal: StaticBody3D) -> void:
	# Elevated steel grated operations deck (x in [-16, +9.4], z in [-14, +14]) flush with DeepRelayLift west landing.
	SliceMaterials.add_box(self, metal, Vector3(-3.3, -0.25, 0), Vector3(25.4, 0.60, 28.0), &"bridge_deck")
	# Walkable concrete ramp on the west edge (-16..-24) leading straight out onto Asset 31's raw basalt crust!
	SliceMaterials.add_box(self, body, Vector3(-19.5, -0.18, 0), Vector3(8.0, 0.44, 10.0), &"concrete_floor")
	# Glowing amber safety rails around perimeter (open on east at z in [-1.2, +3.2] for relay cage, open west for crust ramp).
	var rails: Array = []
	for sz: float in [-13.9, 13.9]:
		SliceMaterials.add_collision_box(metal, Vector3(-3.3, 0.58, sz), Vector3(25.4, 1.15, 0.1))
		rails.append({ "c": Vector3(-3.3, 1.11, sz), "s": Vector3(25.4, 0.07, 0.07) })
	# East edge split around DeepRelayLift opening z in [-1.2, +3.2].
	SliceMaterials.add_collision_box(metal, Vector3(9.3, 0.58, -7.55), Vector3(0.1, 1.15, 12.7))
	SliceMaterials.add_collision_box(metal, Vector3(9.3, 0.58, 8.55), Vector3(0.1, 1.15, 10.7))
	rails.append({ "c": Vector3(9.3, 1.11, -7.55), "s": Vector3(0.07, 0.07, 12.7) })
	rails.append({ "c": Vector3(9.3, 1.11, 8.55), "s": Vector3(0.07, 0.07, 10.7) })
	# West edge split around ramp z in [-5, +5].
	for sz: float in [-9.45, 9.45]:
		SliceMaterials.add_collision_box(metal, Vector3(-15.9, 0.58, sz), Vector3(0.1, 1.15, 8.9))
		rails.append({ "c": Vector3(-15.9, 1.11, sz), "s": Vector3(0.07, 0.07, 8.9) })
	SliceMaterials.add_multimesh(self, rails, &"rail_glow")

	# Outpost floodlight masts + warm landing pools.
	var lamp_glows: Array = []
	for p: Vector3 in [Vector3(6.5, 6.5, -11.5), Vector3(6.5, 6.5, 11.5), Vector3(-13.5, 6.5, -11.5), Vector3(-13.5, 6.5, 11.5)]:
		SliceMaterials.add_box(self, null, Vector3(p.x, 3.25, p.z), Vector3(0.24, 6.5, 0.24), &"structure", false)
		SliceMaterials.add_box(self, null, p, Vector3(0.9, 0.24, 0.9), &"lamp", false)
		lamp_glows.append(p + Vector3(0, -0.2, 0))
		var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.5, 28.0)
		l.position = p + Vector3(0, -0.6, 0)
		add_child(l)
	SliceMaterials.add_coronas(self, lamp_glows, 3.2, &"corona_soft")

	# Enterable Crust Survey Shelter Booth (x in [-11, -3], z in [-12, -6], doorway facing +Z).
	SliceMaterials.add_box(self, metal, Vector3(-7.0, 0.06, -9.0), Vector3(7.8, 0.08, 5.8), &"floor_wood")
	SliceMaterials.add_box(self, body, Vector3(-7.0, 3.25, -9.0), Vector3(8.4, 0.30, 6.4), &"structure")
	SliceMaterials.add_box(self, metal, Vector3(-7.0, 1.60, -11.85), Vector3(8.0, 3.1, 0.3), &"plate")
	SliceMaterials.add_box(self, metal, Vector3(-10.85, 1.60, -9.0), Vector3(0.3, 3.1, 5.8), &"plate")
	SliceMaterials.add_box(self, metal, Vector3(-3.15, 1.60, -9.0), Vector3(0.3, 3.1, 5.8), &"plate")
	# South wall split around doorway x in [-7.8, -6.2].
	SliceMaterials.add_box(self, metal, Vector3(-9.3, 1.60, -6.15), Vector3(3.0, 3.1, 0.3), &"plate")
	SliceMaterials.add_box(self, metal, Vector3(-4.7, 1.60, -6.15), Vector3(3.0, 3.1, 0.3), &"plate")
	SliceMaterials.add_box(self, metal, Vector3(-7.0, 2.70, -6.15), Vector3(1.6, 0.9, 0.3), &"plate")
	SliceMaterials.add_box(self, null, Vector3(-7.0, 2.95, -9.0), Vector3(0.6, 0.14, 0.6), &"lamp", false)
	var sl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.8, 12.0)
	sl.position = Vector3(-7.0, 2.7, -9.0)
	add_child(sl)

	# Outpost canon signboard facing west (-X) and south (+Z).
	SliceMaterials.add_box(self, null, Vector3(-7.0, 3.85, -6.0), Vector3(7.6, 0.85, 0.12), &"structure", false)
	SliceMaterials.add_sign(self, Vector3(-7.0, 3.85, -5.88),
		"ASSET 31 · CRUST OUTPOST 00 · ELEVATION 0 M", 0.0085, Color(1.0, 0.84, 0.52), 0.0)

	# Expedition reward cache inside shelter + geological survey plaque outside.
	add_child(LootContainer.create(
		"CONT-CRUST-00", "Core Survey Footlocker", "cache",
		Vector3(-9.6, 0.10, -10.6), 0.0,
		[["ration_tin", 2], ["water_flask", 2], ["bandage_roll", 2], ["fuse_cell", 1], ["salvaged_relay", 1]], 5, 4))
	SliceMaterials.add_box(self, metal, Vector3(-3.2, 0.65, -4.5), Vector3(0.9, 1.2, 0.6), &"plate")
	add_child(ReadableNote.create(
		"NOTE-CRUST-00", "Asset 31 Crust Datum 0.00 m Plaque",
		"ASSET 31 — ORIGINAL PLANETARY CRUST (DATUM 0.00 M)\n"
		+ "Floor 77 Overhead: +41,000 m  |  Mantle Steel Roof: ~60,000 m\n\n"
		+ "You are standing on the buried bedrock of Asset 31.\n"
		+ "Every steel girder, stack wall, and habitable floor above was\n"
		+ "excavated from this shrinking world and hoisted up the shafts.\n"
		+ "As the Mantle climbs outward, the planet beneath grows thinner.",
		Vector3(-3.2, 1.28, -4.45), 0.0, "plaque"))

	# Sparse dark-suited deep-crust mining crew silhouettes.
	var crew := Crowd.new()
	crew.name = "CrustCrew"
	add_child(crew)
	var statics := [
		{ "p": Vector3(2.5, 0.05, -7.2), "yaw": 2.4 },
		{ "p": Vector3(-11.5, 0.05, 5.4), "yaw": 1.1 },
		{ "p": Vector3(-5.2, 0.05, 9.8), "yaw": -0.4 },
	]
	var walkers := [
		{ "a": Vector3(-13.0, 0.05, -2.5), "b": Vector3(4.5, 0.05, -2.5) },
		{ "a": Vector3(-28.0, 0.05, -18.0), "b": Vector3(-28.0, 0.05, 22.0) },
	]
	crew.setup(statics, walkers, 3100, 1.0, 400.0)


func _process(delta: float) -> void:
	for d: Dictionary in _drills:
		(d.node as Node3D).rotation.y += float(d.speed) * delta
