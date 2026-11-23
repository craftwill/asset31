class_name InterStackExpress
extends Node3D
## Colossal Inter-Stack Express (EXP-077) — horizontal planetary-scale counterpart
## to the 41 km EL-DEEP-00 elevator. Connects the preserved Twin-Stack Landmark
## (STA-0413-N, branching off the north wing of STK-0413 West Arrival at z = -250 m)
## northward along an exposed 14.4 km abyssal viaduct (VD-077-N) to distant STK-0414
## (STA-0414-S at z = -14,680 m, 17.5 km center-to-center).
##
## Features a walkable 3-car consist (63 m total: Forward Panoramic Cab, Mid Saloon,
## Rear Open-Air Chasm Deck) with human-safe 0.16 G S-curve kinematics (110 m/s cruise)
## and train-local free-walk rider lock so players can walk all 3 cars at 396 km/h
## across 14 WorldOrigin rebases with zero phasing, zero texture scroll, and 0.00 m drift.

const GROUP := &"inter_stack_express"
const TRACK_LX := 5980.0        # 60 m west of STK-0413 outer face (19 m clear of cliff buttresses)
const TRACK_LY := 41000.0
const SOUTH_LZ := -290.0        # STA-0413-N boarding stop (Twin-Stack Canyon north wing)
const NORTH_LZ := -14680.0      # STA-0414-S boarding stop (anchored to distant STK-0414 south cliff)
const HALF_W := 2.3             # 4.6 m wide consist
const TRAIN_HALF_LEN := 31.5    # 63.0 m total 3-car length (z_local in [-31.5, +31.5])
const MAX_SPEED := 110.0        # m/s cruise (~396 km/h, ~200 s one-way crossing)
const MAX_ACCEL := 1.6          # m/s^2 (~0.16 G longitudinal — comfortable to walk aboard)
const MAX_JERK := 0.6           # m/s^3 silky S-curve ramp

var express_id := "EXP-077"
var train_lz := SOUTH_LZ
var _prev_train_lz := SOUTH_LZ
var target_lz := SOUTH_LZ
var moving := false
var _vel := 0.0                 # signed Z velocity (m/s, -north / +south)
var _accel := 0.0
var _rider: PlayerController = null
var _rider_local := Vector3.ZERO

var train_anchor: WorldAnchor
var train_body: StaticBody3D
var _door_bars: Array[MeshInstance3D] = []
var _door_shapes: Array[CollisionShape3D] = []
var _status_label: Label3D
var _traction_audio: AudioStreamPlayer3D
var _wind_audio: AudioStreamPlayer3D
var _chime_audio: AudioStreamPlayer3D


static func build() -> InterStackExpress:
	var e := InterStackExpress.new()
	e.name = "EXP-077"
	return e


func _ready() -> void:
	add_to_group(GROUP)
	_build_viaduct()
	_build_station_south()
	_build_station_north()
	_build_train()
	_sync_visuals()


## 14.4 km double-deck abyssal box-truss viaduct (VD-077-N) from STA-0413-N (-290 m)
## to STA-0414-S (-14,680 m) with 900 m colossal piers dropping 6,000 m into the abyss.
func _build_viaduct() -> void:
	var anc := WorldAnchor.new()
	anc.name = "VD-077-N"
	var z_mid := (SOUTH_LZ + NORTH_LZ) * 0.5
	var span := absf(NORTH_LZ - SOUTH_LZ) + 120.0
	anc.lx = TRACK_LX
	anc.ly = TRACK_LY
	anc.lz = z_mid
	add_child(anc)

	var steel: Array = []
	var rails: Array = []
	var lamps: Array = []
	var beacons: Array = []

	# Continuous dark steel twin box-truss girders & central guideway bed under the train (y = -4.2..-0.85).
	steel.append({ "c": Vector3(0.0, -2.55, 0.0), "s": Vector3(8.4, 3.2, span) })
	for sx: float in [-4.9, 4.9]:
		steel.append({ "c": Vector3(sx, -1.8, 0.0), "s": Vector3(1.2, 4.4, span) })
	# Twin gleaming steel maglev/rail running bars (y = -0.95..-0.55, sitting cleanly above girder top -0.95).
	for rx: float in [-1.55, 1.55]:
		rails.append({ "c": Vector3(rx, -0.74, 0.0), "s": Vector3(0.32, 0.36, span) })
	# Colossal abyssal support piers every 900 m descending 6,000 m into the lower Mantle + navigation beacons.
	var pz := -span * 0.5 + 300.0
	while pz <= span * 0.5 - 300.0:
		# Pier shaft starts at y = -4.22 (strictly below girder bottom -4.15 so zero z-fighting!).
		steel.append({ "c": Vector3(0.0, -3004.22, pz), "s": Vector3(12.0, 6000.0, 14.0) })
		# Wide cantilevered pier crosshead saddle (sits below girder bottom, non-overlapping with shaft).
		steel.append({ "c": Vector3(0.0, -5.8, pz), "s": Vector3(18.0, 3.0, 8.0) })
		# Portal clearance frame over the viaduct every 1,800 m for speed sensation at 396 km/h!
		if int(roundf(absf(pz) / 900.0)) % 2 == 0:
			for sx: float in [-5.6, 5.6]:
				steel.append({ "c": Vector3(sx, 5.6, pz), "s": Vector3(1.1, 10.2, 1.1) })
				beacons.append({ "c": Vector3(sx, 11.4, pz), "s": Vector3(0.75, 0.75, 0.75) })
			steel.append({ "c": Vector3(0.0, 10.2, pz), "s": Vector3(10.0, 1.0, 1.1) })
			lamps.append({ "c": Vector3(0.0, 9.52, pz), "s": Vector3(2.4, 0.22, 0.55) })
		pz += 900.0
	# Subtle guideway edge marker lights every 240 m so the 14 km viaduct curves cleanly into the amber haze.
	var lz_m := -span * 0.5 + 120.0
	while lz_m <= span * 0.5 - 120.0:
		for sx: float in [-4.9, 4.9]:
			lamps.append({ "c": Vector3(sx, 0.55, lz_m), "s": Vector3(0.35, 0.25, 0.8) })
		lz_m += 240.0

	SliceMaterials.add_multimesh(anc, steel, &"structure")
	SliceMaterials.add_multimesh(anc, rails, &"rail_steel")
	SliceMaterials.add_multimesh(anc, lamps, &"lamp_cool")
	SliceMaterials.add_multimesh(anc, beacons, &"beacon_red")


## STA-0413-N: Departure Concourse anchored outside the north wing of STK-0413 West Arrival
## (x = 5980, z = -290), linked straight into STK-0413 Arrival Plaza (x = 6040, z = -250)
## by a walkable 54 m steel catwalk spur!
func _build_station_south() -> void:
	var anc := WorldAnchor.new()
	anc.name = "STA-0413-N"
	anc.lx = TRACK_LX
	anc.ly = TRACK_LY
	anc.lz = SOUTH_LZ
	add_child(anc)
	var body := StaticBody3D.new()
	body.set_meta(&"surface", "metal")
	anc.add_child(body)

	# 1. Walkable 54 m catwalk spur connecting STK-0413 West Arrival north wing (x_local = +60, z_local = +40)
	#    to the STA-0413-N boarding platform (x_local = +14.5, z_local = +40).
	SliceMaterials.add_box(anc, body, Vector3(37.25, -0.25, 40.0), Vector3(45.4, 0.50, 6.0), &"bridge_deck")
	for rz: float in [37.1, 42.9]:
		SliceMaterials.add_collision_box(body, Vector3(37.25, 0.6, rz), Vector3(45.4, 1.2, 0.14))
		SliceMaterials.add_box(anc, null, Vector3(37.25, 1.10, rz), Vector3(45.4, 0.08, 0.08), &"rail_glow", false)

	# 2. Broad east-side boarding platform (x_local in [+2.45, +14.5], z_local in [-36, +44], flush with train deck y = 0).
	SliceMaterials.add_box(anc, body, Vector3(8.48, -0.35, 4.0), Vector3(12.0, 0.70, 80.0), &"concrete_floor")
	# Platform safety hazard lip along track edge (x_local = 2.85, top = +0.04 above deck 0.0).
	SliceMaterials.add_box(anc, null, Vector3(2.85, 0.02, 4.0), Vector3(0.75, 0.04, 79.4), &"hazard", false)
	# Canopy steel columns + roof framing over the concourse (non-overlapping corners).
	var steel: Array = []
	for cz: float in [-32.0, -14.0, 4.0, 22.0, 40.0]:
		steel.append({ "c": Vector3(13.8, 3.6, cz), "s": Vector3(0.55, 7.2, 0.55) })
		steel.append({ "c": Vector3(8.5, 7.2, cz), "s": Vector3(9.9, 0.50, 0.55) })
	# Continuous concourse overhead roof slab (starts cleanly above beams at y = 7.48).
	SliceMaterials.add_box(anc, null, Vector3(8.5, 7.72, 4.0), Vector3(12.2, 0.44, 80.4), &"structure", false)
	# Outer east & south/north perimeter guardrails (open at catwalk z in [37.1, 42.9]).
	SliceMaterials.add_collision_box(body, Vector3(14.35, 0.6, 0.5), Vector3(0.2, 1.2, 72.8))
	SliceMaterials.add_box(anc, null, Vector3(14.35, 1.10, 0.5), Vector3(0.08, 0.08, 72.8), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(8.5, 0.6, -35.85), Vector3(11.6, 1.2, 0.2))
	SliceMaterials.add_box(anc, null, Vector3(8.5, 1.10, -35.85), Vector3(11.6, 0.08, 0.08), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(8.5, 0.6, 43.85), Vector3(11.6, 1.2, 0.2))
	SliceMaterials.add_box(anc, null, Vector3(8.5, 1.10, 43.85), Vector3(11.6, 0.08, 0.08), &"rail_glow", false)
	# Waiting benches along the concourse back rail.
	for bz: float in [-22.0, -4.0, 14.0]:
		SliceMaterials.add_box(anc, body, Vector3(12.2, 0.28, bz), Vector3(0.9, 0.56, 3.2), &"wood")
	SliceMaterials.add_multimesh(anc, steel, &"structure")

	# Concourse cool-white linear lights & monumental departure board facing south (+Z) and west (-X).
	var lamp_glows: Array = []
	for lz: float in [-24.0, -6.0, 12.0, 30.0]:
		SliceMaterials.add_box(anc, null, Vector3(8.5, 7.36, lz), Vector3(1.4, 0.16, 0.6), &"lamp_cool", false)
		lamp_glows.append(Vector3(8.5, 7.15, lz))
		var l := SliceMaterials.make_lamp_light(SliceMaterials.COOL, 2.2, 26.0)
		l.position = Vector3(8.5, 6.7, lz)
		anc.add_child(l)
	SliceMaterials.add_coronas(anc, lamp_glows, 2.4, &"corona_cool")

	SliceMaterials.add_box(anc, null, Vector3(8.5, 5.2, 43.4), Vector3(10.4, 1.8, 0.24), &"structure", false)
	SliceMaterials.add_sign(anc, Vector3(8.5, 5.2, 43.56),
		"STA-0413-N  ·  INTER-STACK EXPRESS EXP-077\nDESTINATION: STK-0414 (17.5 KM NORTH)  ·  CRUISE 396 KM/H",
		0.014, Color(0.84, 0.94, 1.0), 0.0)

	# Station dispatch / call console on platform + expedition locker.
	_add_station_console(anc, Vector3(4.8, 0.65, -20.0), -1, -PI * 0.5)
	anc.add_child(LootContainer.create(
		"CONT-STA-0413-N", "Express Transit Locker", "locker",
		Vector3(12.8, 0.02, 28.0), -PI * 0.5,
		[["water_flask", 2], ["ration_tin", 1], ["bandage_roll", 1], ["fuse_cell", 1]], 5, 4))


## STA-0414-S: Monumental South Arrival Terminal anchored into distant STK-0414's south face
## (z = -14,680 m) with a sweeping exterior observation balcony looking 17.5 km south back at
## the preserved Twin-Stack pair (STK-0412 warm + STK-0413 cool) glowing across the abyss!
func _build_station_north() -> void:
	var anc := WorldAnchor.new()
	anc.name = "STA-0414-S"
	anc.lx = TRACK_LX
	anc.ly = TRACK_LY
	anc.lz = NORTH_LZ
	add_child(anc)
	var body := StaticBody3D.new()
	body.set_meta(&"surface", "metal")
	anc.add_child(body)

	# 1. Arrival boarding platform (x_local in [+2.45, +18.0], z_local in [-38, +38])
	#    extending eastward into a wide 38 m panoramic Twin-Stack Overlook Balcony (x_local in [+18.04, +56.0], z_local in [+6, +38]).
	SliceMaterials.add_box(anc, body, Vector3(10.22, -0.35, 0.0), Vector3(15.5, 0.70, 76.0), &"concrete_floor")
	SliceMaterials.add_box(anc, null, Vector3(2.85, 0.02, 0.0), Vector3(0.75, 0.04, 75.4), &"hazard", false)
	# Sweeping Twin-Stack Overlook Balcony deck (butt-joined cleanly at x_local = +18.02, zero overlap!).
	SliceMaterials.add_box(anc, body, Vector3(37.02, -0.35, 22.0), Vector3(38.0, 0.70, 32.0), &"concrete_floor")
	# Monumental concrete arrival portal header anchoring the station into STK-0414's south cliff (z_local = -38..-20),
	# with a central 9.2 m wide x 7.6 m tall open threshold portal leading north into the Great Belfry of the Continuum (BELFRY-0414)!
	SliceMaterials.add_box(anc, body, Vector3(1.1, 8.0, -37.2), Vector3(9.0, 16.0, 1.6), &"industrial_wall")
	SliceMaterials.add_box(anc, body, Vector3(19.3, 8.0, -37.2), Vector3(9.0, 16.0, 1.6), &"industrial_wall")
	SliceMaterials.add_box(anc, body, Vector3(10.2, 11.82, -37.2), Vector3(9.12, 8.36, 1.6), &"industrial_wall")
	SliceMaterials.add_box(anc, null, Vector3(10.2, 7.8, 0.0), Vector3(15.6, 0.45, 72.0), &"structure", false)
	var steel: Array = []
	for cz: float in [-32.0, -14.0, 4.0, 22.0, 34.0]:
		steel.append({ "c": Vector3(17.4, 3.7, cz), "s": Vector3(0.6, 7.4, 0.6) })
	SliceMaterials.add_multimesh(anc, steel, &"structure")

	# Glowing perimeter safety guardrails around the balcony & north/south platform edges.
	SliceMaterials.add_collision_box(body, Vector3(37.02, 0.6, 37.85), Vector3(38.0, 1.2, 0.2))
	SliceMaterials.add_box(anc, null, Vector3(37.02, 1.10, 37.85), Vector3(38.0, 0.08, 0.08), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(55.85, 0.6, 22.0), Vector3(0.2, 1.2, 31.6))
	SliceMaterials.add_box(anc, null, Vector3(55.85, 1.10, 22.0), Vector3(0.08, 0.08, 31.6), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(37.02, 0.6, 6.15), Vector3(38.0, 1.2, 0.2))
	SliceMaterials.add_box(anc, null, Vector3(37.02, 1.10, 6.15), Vector3(38.0, 0.08, 0.08), &"rail_glow", false)
	SliceMaterials.add_collision_box(body, Vector3(10.2, 0.6, 37.85), Vector3(15.2, 1.2, 0.2))
	SliceMaterials.add_box(anc, null, Vector3(10.2, 1.10, 37.85), Vector3(15.2, 0.08, 0.08), &"rail_glow", false)

	# Cool-blue arrival illumination + monumental arrival banner.
	var lamp_glows: Array = []
	for lz: float in [-24.0, -6.0, 12.0, 28.0]:
		SliceMaterials.add_box(anc, null, Vector3(10.2, 7.45, lz), Vector3(1.6, 0.16, 0.6), &"lamp_cool", false)
		lamp_glows.append(Vector3(10.2, 7.25, lz))
		var l := SliceMaterials.make_lamp_light(SliceMaterials.COOL, 2.4, 28.0)
		l.position = Vector3(10.2, 6.8, lz)
		anc.add_child(l)
	var bl := SliceMaterials.make_lamp_light(SliceMaterials.COOL, 2.2, 34.0)
	bl.position = Vector3(37.0, 5.5, 22.0)
	anc.add_child(bl)
	SliceMaterials.add_coronas(anc, lamp_glows, 2.4, &"corona_cool")

	SliceMaterials.add_sign(anc, Vector3(10.2, 9.2, -36.25),
		"STK-0414 · SOUTH TERMINAL STA-0414-S\n↑ NORTH PORTAL: GREAT BELFRY OF THE CONTINUUM (VOID BELL SANCTUM)",
		0.013, Color(1.0, 0.86, 0.56), 0.0)
	# Monumental Continuum emblem anchored on STK-0414's south cliff portal (honoring the 14.4 km VD-077-N bond).
	var ex_emb := ContinuumEmblem.create(1.8, &"copper", &"structure", false)
	ex_emb.position = Vector3(10.2, 13.0, -36.15)
	anc.add_child(ex_emb)

	# Return dispatch console + Twin-Stack Overlook lore plaque + arrival expedition cache.
	_add_station_console(anc, Vector3(4.8, 0.65, -20.0), 1, -PI * 0.5)
	anc.add_child(ReadableNote.create(
		"NOTE-STK-0414", "STK-0414 South Overlook Plaque",
		"STK-0414  ·  FLOOR 77 SOUTH TERMINAL (STA-0414-S)\n\n"
		+ "Look south across the 14.4 km viaduct VD-077-N:\n"
		+ "The glowing pair on the horizon is the Twin-Stack Landmark — STK-0412 (amber) "
		+ "and STK-0413 (cool white), an unusually close 3 km twin pair.\n"
		+ "Across the rest of Asset 31's Mantle, neighbouring stacks stand 15 to 20 km apart "
		+ "across open abyssal chasms linked only by high-speed Express viaducts.",
		Vector3(36.0, 1.45, 37.3), PI, "plaque"))
	anc.add_child(LootContainer.create(
		"CONT-STA-0414-S", "STK-0414 Arrival Cache", "crate",
		Vector3(24.0, 0.02, 10.0), 0.0,
		[["water_flask", 2], ["ration_tin", 2], ["bandage_roll", 1], ["salvaged_relay", 1]], 5, 4))


func _add_station_console(parent: Node3D, pos: Vector3, side: int, rot_y: float) -> void:
	var console := ExpressConsole.new()
	console.express = self
	console.station_side = side
	console.position = pos
	console.rotation.y = rot_y
	parent.add_child(console)
	SliceMaterials.add_box(console, console, Vector3.ZERO, Vector3(0.50, 1.30, 0.80), &"plate")
	SliceMaterials.add_box(console, null, Vector3(0.0, 0.34, 0.42), Vector3(0.36, 0.22, 0.04), &"sign_cyan", false)


## Walkable 3-Car Consist (63 m total, z_local in [-31.5, +31.5]):
##   Car 1 (-31.5..-11.5): Panoramic Forward Drive & Observation Cab + Live Telemetry + Console
##   Car 2 (-10.0..+10.0): Mid Passenger/Freight Saloon + Seating + Cache + Note
##   Car 3 (+11.5..+31.5): Rear Open-Air Chasm Observation Platform (looking back at Twin-Stack!)
## Every moving surface uses &"plate_local" / &"wood" / &"structure" (use_world = 0) so ZERO texture scroll!
func _build_train() -> void:
	train_anchor = WorldAnchor.new()
	train_anchor.name = "ExpressTrainAnchor"
	train_anchor.lx = TRACK_LX
	train_anchor.ly = TRACK_LY
	train_anchor.lz = train_lz
	add_child(train_anchor)

	train_body = StaticBody3D.new()
	train_body.name = "ExpressTrainBody"
	train_body.set_meta(&"surface", "metal")
	train_anchor.add_child(train_body)

	# Continuous 63 m walkable steel floor deck (y = -0.35..0.0, flush with station platforms y = 0.0!)
	# plus undercarriage bogie skids sitting cleanly below y = -0.38.
	SliceMaterials.add_box(train_body, train_body, Vector3(0.0, -0.175, 0.0), Vector3(HALF_W * 2.0, 0.35, TRAIN_HALF_LEN * 2.0), &"plate_local")
	for bz: float in [-26.0, -16.0, -5.0, 5.0, 16.0, 26.0]:
		SliceMaterials.add_box(train_body, null, Vector3(0.0, -0.56, bz), Vector3(3.6, 0.36, 2.8), &"structure", false)

	# Build Car 1 (Front Cab, cz = -21.5) & Car 2 (Mid Saloon, cz = 0.0) enclosed bodies with side windows & east boarding doors.
	for car_idx in 2:
		var cz := -21.5 if car_idx == 0 else 0.0
		# Roof slab (y = 3.25..3.55, spanning 19.8 m cleanly).
		SliceMaterials.add_box(train_body, train_body, Vector3(0.0, 3.40, cz), Vector3(HALF_W * 2.04, 0.30, 19.8), &"structure")
		# Lower waist walls (west -X continuous; east +X split around 2.8 m boarding doorway at cz).
		SliceMaterials.add_box(train_body, train_body, Vector3(-HALF_W + 0.10, 0.56, cz), Vector3(0.20, 1.12, 19.6), &"plate_local")
		SliceMaterials.add_box(train_body, train_body, Vector3(HALF_W - 0.10, 0.56, cz - 5.6), Vector3(0.20, 1.12, 8.4), &"plate_local")
		SliceMaterials.add_box(train_body, train_body, Vector3(HALF_W - 0.10, 0.56, cz + 5.6), Vector3(0.20, 1.12, 8.4), &"plate_local")
		# Upper window mullions & translucent glass strips along both sides (y = 1.15..3.22).
		for sx: float in [-HALF_W + 0.10, HALF_W - 0.10]:
			for pz_off: float in [-9.6, -5.8, -1.6, 1.6, 5.8, 9.6]:
				SliceMaterials.add_box(train_body, null, Vector3(sx, 2.18, cz + pz_off), Vector3(0.16, 2.06, 0.22), &"structure", false)
			SliceMaterials.add_box(train_body, null, Vector3(sx, 2.18, cz), Vector3(0.04, 1.98, 19.0), &"glass", false)
		# East boarding blast safety bar (closes while train is moving at 110 m/s!).
		var bar := SliceMaterials.add_box(train_body, null, Vector3(HALF_W - 0.10, 1.05, cz), Vector3(0.10, 0.10, 2.65), &"rail_glow", false)
		_door_bars.append(bar)
		var dcs := CollisionShape3D.new()
		var dbs := BoxShape3D.new()
		dbs.size = Vector3(0.22, 2.4, 2.75)
		dcs.shape = dbs
		dcs.position = Vector3(HALF_W - 0.10, 1.2, cz)
		train_body.add_child(dcs)
		_door_shapes.append(dcs)
		# Warm interior ceiling lights.
		for lz_o: float in [-5.0, 5.0]:
			SliceMaterials.add_box(train_body, null, Vector3(0.0, 3.16, cz + lz_o), Vector3(0.9, 0.12, 1.8), &"lamp", false)
		var cl := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.6, 16.0)
		cl.position = Vector3(0.0, 2.85, cz)
		train_body.add_child(cl)

	# Car 1 Front Panoramic Nose Window & Drive Desk (z_local = -31.35) + Headlamps!
	SliceMaterials.add_box(train_body, train_body, Vector3(0.0, 0.56, -31.38), Vector3(HALF_W * 2.0 - 0.44, 1.12, 0.20), &"plate_local")
	SliceMaterials.add_box(train_body, null, Vector3(0.0, 2.18, -31.38), Vector3(HALF_W * 2.0 - 0.44, 2.02, 0.05), &"glass", false)
	SliceMaterials.add_box(train_body, null, Vector3(-1.3, 0.45, -31.54), Vector3(0.65, 0.28, 0.10), &"tram_headlamp", false)
	SliceMaterials.add_box(train_body, null, Vector3(1.3, 0.45, -31.54), Vector3(0.65, 0.28, 0.10), &"tram_headlamp", false)
	SliceMaterials.add_box(train_body, null, Vector3(0.0, 3.66, -30.5), Vector3(0.35, 0.20, 0.35), &"beacon_red", false)

	# Live telemetry readout mounted above the front panoramic window (facing south +Z toward driver/rider).
	SliceMaterials.add_box(train_body, null, Vector3(0.0, 2.88, -31.15), Vector3(2.8, 0.56, 0.08), &"structure", false)
	_status_label = SliceMaterials.add_sign(train_body, Vector3(0.0, 2.88, -31.08),
		"EXP-077  ·  DOCKED STA-0413-N", 0.0046, Color(0.84, 0.96, 1.0), 0.0)

	# Onboard interactive Drive / Dispatch Console at front cab desk (z_local = -30.5).
	var cab_con := ExpressConsole.new()
	cab_con.name = "OnboardExpressConsole"
	cab_con.express = self
	cab_con.station_side = 0
	cab_con.position = Vector3(0.0, 0.65, -30.5)
	train_body.add_child(cab_con)
	SliceMaterials.add_box(cab_con, cab_con, Vector3.ZERO, Vector3(1.35, 1.05, 0.52), &"plate_local")
	SliceMaterials.add_box(cab_con, null, Vector3(0.0, 0.32, 0.28), Vector3(0.75, 0.20, 0.04), &"sign_cyan", false)

	# Car 2 Interior Passenger Benches + Onboard Expedition Cache + Route Log!
	for bz: float in [-5.5, 5.5]:
		SliceMaterials.add_box(train_body, train_body, Vector3(-1.75, 0.28, bz), Vector3(0.65, 0.52, 3.2), &"wood")
	train_body.add_child(LootContainer.create(
		"CONT-EXP-077", "Saloon Emergency Kit", "crate",
		Vector3(1.62, 0.02, -6.5), -PI * 0.5,
		[["water_flask", 1], ["dried_strip", 2], ["bandage_roll", 2]], 5, 4))
	train_body.add_child(ReadableNote.create(
		"NOTE-EXP-077", "EXP-077 Inter-Stack Manifest",
		"INTER-STACK EXPRESS EXP-077  ·  VIADUCT VD-077-N\n\n"
		+ "Route: STA-0413-N (Twin-Stack Region) ↔ STA-0414-S (STK-0414, 17.5 km North).\n"
		+ "Cruise Speed: 110 m/s (396 km/h)  |  Max Longitudinal Load: 0.16 G (walkable).\n\n"
		+ "Passengers may walk freely between the Forward Panoramic Cab, Mid Saloon, "
		+ "and the Rear Open-Air Chasm Observation Deck while underway.",
		Vector3(-2.12, 1.55, 0.0), PI * 0.5, "plaque"))

	# Enclosed walkable gangway bellows linking Car 1 ↔ Car 2 (z = -10.75) and Car 2 ↔ Car 3 (z = +10.75).
	for gz: float in [-10.75, 10.75]:
		for sx: float in [-HALF_W + 0.14, HALF_W - 0.14]:
			SliceMaterials.add_box(train_body, train_body, Vector3(sx, 1.55, gz), Vector3(0.20, 3.10, 1.46), &"structure")
		SliceMaterials.add_box(train_body, null, Vector3(0.0, 3.24, gz), Vector3(HALF_W * 2.0 - 0.1, 0.24, 1.46), &"structure", false)

	# Car 3 (Rear Open-Air Chasm Observation Deck, z_local in [+11.5, +31.5]):
	# Open sky overhead + glowing amber perimeter guardrails + red rear marker lamps!
	for sx: float in [-HALF_W + 0.08, HALF_W - 0.08]:
		SliceMaterials.add_collision_box(train_body, Vector3(sx, 0.65, 21.5), Vector3(0.16, 1.30, 19.8))
		SliceMaterials.add_box(train_body, null, Vector3(sx, 1.12, 21.5), Vector3(0.08, 0.08, 19.8), &"rail_glow", false)
		SliceMaterials.add_box(train_body, null, Vector3(sx, 0.56, 21.5), Vector3(0.06, 0.06, 19.8), &"structure", false)
	SliceMaterials.add_collision_box(train_body, Vector3(0.0, 0.65, 31.38), Vector3(HALF_W * 2.0 - 0.36, 1.30, 0.16))
	SliceMaterials.add_box(train_body, null, Vector3(0.0, 1.12, 31.38), Vector3(HALF_W * 2.0 - 0.36, 0.08, 0.08), &"rail_glow", false)
	SliceMaterials.add_box(train_body, null, Vector3(0.0, 0.56, 31.38), Vector3(HALF_W * 2.0 - 0.36, 0.06, 0.06), &"structure", false)
	# Rear red tail beacons on observation deck corners.
	SliceMaterials.add_box(train_body, null, Vector3(-1.8, 0.56, 31.54), Vector3(0.42, 0.24, 0.10), &"beacon_red", false)
	SliceMaterials.add_box(train_body, null, Vector3(1.8, 0.56, 31.54), Vector3(0.42, 0.24, 0.10), &"beacon_red", false)
	var deck_l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.3, 14.0)
	deck_l.position = Vector3(0.0, 2.2, 22.0)
	train_body.add_child(deck_l)

	# Speed-modulated traction hum, rear chasm wind, and station docking chime.
	_traction_audio = _make_audio("res://audio/tram_hum.wav", true, -8.0, 0.65, Vector3(0.0, 0.5, -10.0))
	_wind_audio = _make_audio("res://audio/wind.wav", true, -14.0, 1.0, Vector3(0.0, 1.5, 22.0))
	_chime_audio = _make_audio("res://audio/lift_clunk.wav", false, -5.0, 1.15, Vector3(0.0, 1.5, -24.0))


func _make_audio(path: String, loop: bool, vol_db: float, pitch: float, pos: Vector3) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	if ResourceLoader.exists(path):
		var s: AudioStreamWAV = load(path)
		if loop:
			s = s.duplicate()
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = int(s.get_length() * s.mix_rate)
		p.stream = s
	p.position = pos
	p.bus = &"World"
	p.unit_size = 18.0
	p.max_distance = 120.0
	p.volume_db = vol_db
	p.pitch_scale = pitch
	train_body.add_child(p)
	return p


func console_prompt(station_side: int) -> String:
	if station_side == 0:
		if moving:
			var rev_dest := "STA-0413-N (Twin-Stack)" if target_lz < -7000.0 else "STA-0414-S (STK-0414)"
			return "[E] Reverse EXP-077 → %s  (%.1f km)" % [rev_dest, absf(train_lz - SOUTH_LZ) / 1000.0]
		var dest := "STK-0414 (14.4 km North)" if train_lz > -7000.0 else "STA-0413-N Twin-Stack (14.4 km South)"
		return "[E] Depart Inter-Stack Express EXP-077 → %s" % dest
	var want_lz := SOUTH_LZ if station_side < 0 else NORTH_LZ
	if moving:
		return "EXP-077 in transit (%.1f km from Twin-Stack)" % [absf(train_lz - SOUTH_LZ) / 1000.0]
	if absf(train_lz - want_lz) < 2.0:
		return "EXP-077 docked here — board the east doors and use the Front Cab console"
	var label := "STA-0413-N" if station_side < 0 else "STA-0414-S"
	return "[E] Summon Inter-Stack Express EXP-077 to %s" % label


func activate_console(station_side: int) -> String:
	if station_side == 0:
		if moving:
			target_lz = SOUTH_LZ if target_lz < -7000.0 else NORTH_LZ
			_attach_rider_if_aboard()
			_sync_visuals()
			var rdest := "STA-0413-N (Twin-Stack)" if target_lz > -7000.0 else "STA-0414-S (STK-0414)"
			return "EXP-077 reversing course → %s (smooth 0.16 G deceleration)" % rdest
		target_lz = NORTH_LZ if train_lz > -7000.0 else SOUTH_LZ
		moving = true
		_attach_rider_if_aboard()
		if _chime_audio.stream != null:
			_chime_audio.play()
		if _traction_audio.stream != null and not _traction_audio.playing:
			_traction_audio.play()
		if _wind_audio.stream != null and not _wind_audio.playing:
			_wind_audio.play()
		_sync_visuals()
		var dest := "STA-0414-S (STK-0414 · 17.5 km North)" if target_lz < -7000.0 else "STA-0413-N (Twin-Stack Landmark)"
		return "EXP-077 departing → %s  (walk freely through all 3 cars!)" % dest
	var want_lz := SOUTH_LZ if station_side < 0 else NORTH_LZ
	if moving:
		return "EXP-077 is already underway."
	if absf(train_lz - want_lz) < 2.0:
		return "EXP-077 is docked right here — board through the east doors."
	target_lz = want_lz
	moving = true
	if _traction_audio.stream != null and not _traction_audio.playing:
		_traction_audio.play()
	_sync_visuals()
	return "Summoning EXP-077 across VD-077-N..."


func _attach_rider_if_aboard() -> void:
	if _rider != null and is_instance_valid(_rider):
		return
	var players := get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	var p := players[0] as PlayerController
	if p == null:
		return
	train_anchor.apply_origin()
	train_anchor.force_update_transform()
	p.force_update_transform()
	var loc := train_anchor.to_local(p.global_position)
	if absf(loc.x) <= HALF_W + 0.2 and absf(loc.z) <= TRAIN_HALF_LEN + 0.2 and loc.y >= -0.6 and loc.y <= 3.6:
		_rider = p
		_rider_local = Vector3(
			clampf(loc.x, -(HALF_W - 0.55), HALF_W - 0.55),
			0.02,
			clampf(loc.z, -(TRAIN_HALF_LEN - 0.8), TRAIN_HALF_LEN - 0.8))
		_rider.riding_transport = true
		_rider.velocity = Vector3.ZERO
		_rider.reset_fall_tracking()


func _release_rider() -> void:
	if _rider != null and is_instance_valid(_rider):
		_rider.riding_transport = false
		_rider.velocity = Vector3.ZERO
		_rider.reset_fall_tracking()
	_rider = null


func _physics_process(delta: float) -> void:
	if not moving:
		return
	_prev_train_lz = train_lz
	var rem := target_lz - train_lz
	var dist := absf(rem)
	var dir := signf(rem)
	# Proven human-safe S-curve braking envelope (<= 1.6 m/s^2 = 0.16 G) transitioning into
	# gentle exponential hydraulic soft-docking in the final 4 m (matches DeepRelayLift).
	var docked := false
	if dist < 0.02 and absf(_vel) < 0.04:
		train_lz = target_lz
		_vel = 0.0
		_accel = 0.0
		moving = false
		docked = true
	else:
		var brake_a := MAX_ACCEL * 0.72
		var v_stop := minf(sqrt(2.0 * brake_a * dist), dist * 0.9)
		var v_des := dir * minf(MAX_SPEED, v_stop)
		var a_req := clampf((v_des - _vel) / maxf(delta, 0.001), -MAX_ACCEL, MAX_ACCEL)
		if dist > 4.0:
			_accel = move_toward(_accel, a_req, MAX_JERK * delta)
		else:
			_accel = a_req
		_accel = clampf(_accel, -MAX_ACCEL, MAX_ACCEL)
		var next_vel := clampf(_vel + _accel * delta, -MAX_SPEED, MAX_SPEED)
		var step := (_vel + next_vel) * 0.5 * delta
		if (rem > 0.0 and step >= rem) or (rem < 0.0 and step <= rem):
			train_lz = target_lz
			_vel = 0.0
			_accel = 0.0
			moving = false
			docked = true
		else:
			train_lz += step
			_vel = next_vel
	if docked:
		if _traction_audio.playing:
			_traction_audio.stop()
		if _wind_audio.playing:
			_wind_audio.stop()
		if _chime_audio.stream != null:
			_chime_audio.play()
		_apply_train_position(train_lz)
		if _rider != null and is_instance_valid(_rider):
			_rider.global_position = train_anchor.to_global(_rider_local)
			_rider.force_update_transform()
		_release_rider()
		_sync_visuals()
		return

	_apply_train_position(train_lz)

	# Allow the player to walk freely through all 3 cars (63 m) in train-local space while moving at 110 m/s!
	if _rider != null and is_instance_valid(_rider):
		if _rider.input_enabled:
			var move_in := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
			if move_in.length_squared() > 0.001:
				var wish := (_rider.global_basis * Vector3(move_in.x, 0.0, move_in.y)).normalized()
				var spd := _rider.sprint_speed if Input.is_action_pressed(&"sprint") else _rider.walk_speed
				_rider_local.x = clampf(_rider_local.x + wish.x * spd * delta, -(HALF_W - 0.55), HALF_W - 0.55)
				_rider_local.z = clampf(_rider_local.z + wish.z * spd * delta, -(TRAIN_HALF_LEN - 0.8), TRAIN_HALF_LEN - 0.8)
		_rider.global_position = train_anchor.to_global(_rider_local)
		_rider.force_update_transform()
		_rider.velocity = Vector3.ZERO
		_rider.reset_fall_tracking()

	var frac := clampf(absf(_vel) / MAX_SPEED, 0.0, 1.0)
	_traction_audio.pitch_scale = 0.65 + frac * 0.72
	_wind_audio.volume_db = -18.0 + frac * 11.0
	_sync_visuals()


func _process(_delta: float) -> void:
	if not moving:
		return
	var f := Engine.get_physics_interpolation_fraction()
	var vis_lz := lerpf(_prev_train_lz, train_lz, f)
	_apply_train_position(vis_lz)
	if _rider != null and is_instance_valid(_rider):
		_rider.global_position = train_anchor.to_global(_rider_local)
		_rider.force_update_transform()


func _apply_train_position(z_val: float) -> void:
	train_anchor.lz = z_val
	train_anchor.apply_origin()
	train_anchor.force_update_transform()


func _sync_visuals() -> void:
	for bar in _door_bars:
		bar.visible = moving
	for cs in _door_shapes:
		cs.disabled = not moving
	if _status_label != null:
		var km_north := absf(train_lz - SOUTH_LZ) / 1000.0
		if moving:
			var kmh := absf(_vel) * 3.6
			var g_lon := absf(_accel) / 9.81
			var dest := "STK-0414" if target_lz < -7000.0 else "STA-0413-N"
			_status_label.text = "EXP-077 → %s  ·  %.0f KM/H  ·  %.2f G\nVIADUCT VD-077-N  ·  %.2f / 14.4 KM" % [dest, kmh, g_lon, km_north]
		else:
			var st := "STA-0413-N (TWIN-STACK)" if train_lz > -7000.0 else "STA-0414-S (STK-0414)"
			_status_label.text = "EXP-077  ·  DOCKED %s\n[E] DEPART ACROSS 14.4 KM VIADUCT" % st


func serialize() -> Dictionary:
	return { "train_lz": train_lz, "target_lz": target_lz, "moving": moving }


func deserialize(d: Dictionary) -> void:
	_release_rider()
	train_lz = float(d.get("train_lz", SOUTH_LZ))
	_prev_train_lz = train_lz
	target_lz = float(d.get("target_lz", train_lz))
	moving = bool(d.get("moving", false))
	_vel = 0.0
	_accel = 0.0
	_apply_train_position(train_lz)
	if not moving:
		if _traction_audio.playing:
			_traction_audio.stop()
		if _wind_audio.playing:
			_wind_audio.stop()
	_sync_visuals()
