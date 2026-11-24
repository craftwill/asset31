class_name DeepRelayLift
extends Node3D
## Heavy Express Ore-Relay Cage (EL-DEEP-00): physically connects Floor 77 Hub
## (41,000 m), Undercroft 76-B (40,780 m), and Asset 31's original buried planetary
## mining surface (0 m) across the full 41 km of real float64 vertical space in both
## directions (Canon §0.1, Brief §3.6). Uses a WorldAnchor for the cage itself and
## sync_to_physics = false so all 40 vertical 1024 m origin rebases stay rock-solid.

const GROUP := &"deep_relays"
const TOP_LY := 41000.0
const MID_LY := 40780.0
const BOT_LY := 0.05          # flush with CRUST-00 outpost deck (+0.05 m above y=0 basalt slab, zero z-fighting)
const HALF_W := 2.1
const SLEEVE_STEP := 200.0
const SLEEVE_HALF := 1400.0   # 2,800 m continuous shaft sleeve (±1,400 m around cage)
const SLEEVE_MIN_Y := 2600.0  # bottom sits flush at 1,200 m (CRUST-00 shaft collar top)
const SLEEVE_MAX_Y := 37400.0 # top sits flush at 38,800 m (EL-CYL-77 shaft bottom)
const MAX_SPEED := 400.0      # m/s cruise speed (~202 s full 41 km transit)
const MAX_ACCEL := 4.5        # m/s^2 (~0.46 G max delta -> felt 0.54 G .. 1.46 G, human-safe!)
const MAX_JERK := 1.8         # m/s^3 smooth S-curve ramp so starts/stops never jolt

var relay_id := "EL-DEEP-00"
# Per-lift configuration; the defaults are EL-DEEP-00. `build_custom` makes other lifts.
var top_ly := TOP_LY
var mid_ly := MID_LY
var bot_ly := BOT_LY
var has_mid := true
var sleeve_kind := "shaft"        # "shaft" = lit cylindrical shaft, "mast" = open guide mast
var sleeve_min := SLEEVE_MIN_Y
var sleeve_max := SLEEVE_MAX_Y
var title := "DEEP EXPRESS CAGE"
var top_name := "Floor 77 Hub (41,000 m)"
var mid_name := "Undercroft 76-B (40,780 m)"
var bot_name := "Asset 31 Crust (0 m)"
var strata: Array = []            # optional [[min altitude, name], ...] from high to low
var lx := 3271.5
var lz := -179.0
var car_ly := TOP_LY
var _prev_car_ly := TOP_LY
var target_ly := TOP_LY
var powered := true
var moving := false
var _vel := 0.0               # signed vertical velocity (m/s, +up / -down)
var _accel := 0.0             # current signed vertical acceleration (m/s^2)
var _rider: PlayerController = null
var _rider_local := Vector3.ZERO

var car_anchor: WorldAnchor
var car_body: AnimatableBody3D
var _gate_mesh: MeshInstance3D
var _gate_shape: CollisionShape3D
var _status_label: Label3D
var _cab_light: OmniLight3D
var _sleeve_anchor: WorldAnchor
var _motor: AudioStreamPlayer3D
var _clunk: AudioStreamPlayer3D


static func build(p_lx := 3271.5, p_lz := -179.0) -> DeepRelayLift:
	var d := DeepRelayLift.new()
	d.name = "DeepRelayLift"
	d.lx = p_lx
	d.lz = p_lz
	return d


## A second lift of the same make: two stations, its own names, an open guide mast.
static func build_custom(cfg: Dictionary) -> DeepRelayLift:
	var d := DeepRelayLift.new()
	d.relay_id = String(cfg.id)
	d.name = d.relay_id
	d.lx = float(cfg.x)
	d.lz = float(cfg.z)
	d.top_ly = float(cfg.top)
	d.bot_ly = float(cfg.bottom)
	d.mid_ly = d.bot_ly
	d.has_mid = false
	d.sleeve_kind = "mast"
	d.sleeve_min = d.bot_ly + SLEEVE_HALF
	d.sleeve_max = d.top_ly - SLEEVE_HALF
	d.title = String(cfg.title)
	d.top_name = String(cfg.top_name)
	d.bot_name = String(cfg.bottom_name)
	d.strata = cfg.get("strata", [])
	d.car_ly = d.bot_ly
	d._prev_car_ly = d.bot_ly
	d.target_ly = d.bot_ly
	return d


func _ready() -> void:
	add_to_group(GROUP)
	_build_cage()
	if sleeve_kind == "mast":
		_build_guide_mast()
	else:
		_build_stratum_sleeve()
	_build_station_console(top_ly, 2)
	if has_mid:
		_build_station_console(mid_ly, 1)
	_build_station_console(bot_ly, -1)
	_sync_visuals()


func _span_km() -> float:
	return (top_ly - bot_ly) / 1000.0


func _half_way() -> float:
	return (top_ly + bot_ly) * 0.5


func _build_cage() -> void:
	car_anchor = WorldAnchor.new()
	car_anchor.name = "RelayCageAnchor"
	car_anchor.lx = lx
	car_anchor.ly = car_ly
	car_anchor.lz = lz
	add_child(car_anchor)

	car_body = AnimatableBody3D.new()
	car_body.name = "RelayCageBody"
	car_body.sync_to_physics = false
	car_body.set_meta(&"surface", "metal")
	car_anchor.add_child(car_body)

	# Heavy 4.2 x 4.2 m reinforced grated ore-cage deck (open landing on west -X side).
	SliceMaterials.add_box(car_body, car_body, Vector3(0, -0.15, 0), Vector3(HALF_W * 2.0, 0.30, HALF_W * 2.0), &"bridge_deck")
	SliceMaterials.add_box(car_body, null, Vector3(0, -0.55, 0), Vector3(HALF_W * 1.85, 0.50, HALF_W * 1.85), &"structure", false)
	# Reinforced steel walls on east (+X), north (-Z), south (+Z) — east wall fits between north/south walls (no coplanar corners).
	SliceMaterials.add_box(car_body, car_body, Vector3(HALF_W - 0.08, 0.65, 0), Vector3(0.16, 1.3, (HALF_W - 0.16) * 2.0), &"plate_local")
	SliceMaterials.add_box(car_body, car_body, Vector3(0, 0.65, -HALF_W + 0.08), Vector3(HALF_W * 2.0, 1.3, 0.16), &"plate_local")
	SliceMaterials.add_box(car_body, car_body, Vector3(0, 0.65, HALF_W - 0.08), Vector3(HALF_W * 2.0, 1.3, 0.16), &"plate_local")
	# Corner steel cage columns (offset slightly inward so faces never z-fight the walls) + roof canopy + beacon.
	for cx: float in [-HALF_W + 0.14, HALF_W - 0.14]:
		for cz: float in [-HALF_W + 0.14, HALF_W - 0.14]:
			SliceMaterials.add_box(car_body, null, Vector3(cx, 1.65, cz), Vector3(0.14, 3.3, 0.14), &"structure", false)
	SliceMaterials.add_box(car_body, car_body, Vector3(0, 3.35, 0), Vector3(HALF_W * 2.05, 0.22, HALF_W * 2.05), &"structure")
	SliceMaterials.add_box(car_body, null, Vector3(0, 3.56, 0), Vector3(0.32, 0.20, 0.32), &"beacon_red", false)

	# Glowing west safety blast bar (closes while descending/ascending at high speed).
	_gate_mesh = SliceMaterials.add_box(car_body, null, Vector3(-HALF_W + 0.08, 1.05, 0), Vector3(0.10, 0.10, HALF_W * 1.9), &"rail_glow", false)
	_gate_shape = CollisionShape3D.new()
	var gs := BoxShape3D.new()
	gs.size = Vector3(0.16, 2.2, HALF_W * 1.9)
	_gate_shape.shape = gs
	_gate_shape.position = Vector3(-HALF_W + 0.08, 1.1, 0)
	car_body.add_child(_gate_shape)

	# Interior work-light + live 41 km altitude / stratum readout mounted on east wall facing -X.
	SliceMaterials.add_box(car_body, null, Vector3(0, 3.16, 0), Vector3(0.55, 0.12, 0.55), &"lamp", false)
	_cab_light = SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.7, 14.0)
	_cab_light.position = Vector3(0, 2.9, 0)
	car_body.add_child(_cab_light)
	SliceMaterials.add_box(car_body, null, Vector3(HALF_W - 0.18, 2.05, 0), Vector3(0.08, 0.72, 2.35), &"structure", false)
	_status_label = SliceMaterials.add_sign(car_body, Vector3(HALF_W - 0.24, 2.05, 0),
		"EL-DEEP-00  ·  40,780 M", 0.0048, Color(1.0, 0.84, 0.52), -PI * 0.5)

	# On-board interactive relay control panel on east inner wall.
	var console := RelayConsole.new()
	console.name = "OnboardRelayConsole"
	console.relay = self
	console.station_side = 0
	console.position = Vector3(HALF_W - 0.42, 0.75, 0)
	car_body.add_child(console)
	SliceMaterials.add_box(console, console, Vector3.ZERO, Vector3(0.46, 1.25, 0.80), &"plate_local")
	SliceMaterials.add_box(console, null, Vector3(-0.24, 0.34, 0), Vector3(0.04, 0.20, 0.44), &"window_glow", false)

	# Engraved Sacred Symbol of The Continuum above the 41 km shaft cage console.
	var cage_emblem := ContinuumEmblem.create(0.28, &"copper", &"structure", false)
	cage_emblem.position = Vector3(HALF_W - 0.26, 2.74, 0.0)
	cage_emblem.rotation.y = -PI * 0.5
	car_body.add_child(cage_emblem)

	if sleeve_kind == "mast":
		# Open-air cage: hoist cables from a head frame, and shoes that grip the guide rails.
		SliceMaterials.add_box(car_body, null, Vector3(0, 3.92, 0), Vector3(HALF_W * 1.6, 0.3, 0.5), &"structure", false)
		for cx: float in [-0.5, 0.5]:
			SliceMaterials.add_box(car_body, null, Vector3(cx, 4.07 + 60.0, 0), Vector3(0.07, 120.0, 0.07), &"structure", false)
		for sz: float in [-1.0, 1.0]:
			for sy: float in [0.2, 3.0]:
				SliceMaterials.add_box(car_body, null, Vector3(HALF_W + 0.3, sy, sz * (HALF_W - 0.5)), Vector3(0.6, 0.3, 0.34), &"structure", false)

	_motor = _make_audio("res://audio/tram_hum.wav", true, -6.0, 0.65)
	_clunk = _make_audio("res://audio/lift_clunk.wav", false, -4.0, 0.82)


## Repeating 2,800 m cylindrical shaft stratum sleeve that tracks the cage modulo
## 200 m strictly within [1,200 m .. 38,800 m] (butt-joined flush to EL-CYL-77 at
## 38,800 m and CRUST-00's shaft collar at 1,200 m with zero overlap). Uses
## world-Y shaft_wall and exact 100 m / 25 m multiples of 200 m so window grids,
## floor bands, rings, and lattice braces never shift or pop as the sleeve steps.
func _build_stratum_sleeve() -> void:
	_sleeve_anchor = WorldAnchor.new()
	_sleeve_anchor.name = "DeepShaftSleeve"
	_sleeve_anchor.lx = lx - 11.5
	_sleeve_anchor.ly = sleeve_max
	_sleeve_anchor.lz = lz - 1.0
	_sleeve_anchor.visible = true
	add_child(_sleeve_anchor)
	var walls: Array = []
	var ribs: Array = []
	var lamps: Array = []
	var beacons: Array = []
	var R := 150.0
	var sides := 24
	var chord := 2.0 * R * tan(PI / float(sides))
	var sleeve_h := SLEEVE_HALF * 2.0
	# 24-sided world-Y lit cylindrical outer shaft wall (identical to EL-CYL-77 & CRUST-00).
	for i in sides:
		var ang := float(i) * TAU / float(sides)
		var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
		walls.append({ "c": Vector3(cos(ang) * (R + 4.0), 0.0, sin(ang) * (R + 4.0)), "s": Vector3(chord + 1.0, sleeve_h, 8.0), "r": rot, "seed": float(i) * 0.04 })
	# Concentric structural ring girders + rim lamps every 100 m (exact divisor of 200 m step).
	for k in range(-13, 14):
		var y := float(k) * 100.0
		for i in sides:
			var ang := float(i) * TAU / float(sides)
			var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
			ribs.append({ "c": Vector3(cos(ang) * (R - 2.2), y, sin(ang) * (R - 2.2)), "s": Vector3(chord, 4.2, 4.8), "r": rot })
			lamps.append({ "c": Vector3(cos(ang) * (R - 4.7), y + 2.3, sin(ang) * (R - 4.7)), "s": Vector3(chord * 0.9, 0.22, 0.22), "r": rot })
		if k % 2 == 0:
			for bi in 4:
				var bang := (float(bi) + 0.5) * PI * 0.5
				beacons.append({ "c": Vector3(cos(bang) * (R - 5.2), y, sin(bang) * (R - 5.2)), "s": Vector3(0.95, 0.95, 0.95) })
	# 8 matching 10 x 10 m interior lattice towers + 25 m cross-bracing (exact divisor of 200 m step) + amber guide rails.
	var tower_r := R * 0.62
	var ts := 10.0
	for i in 8:
		var ang := (float(i) + 0.5) * TAU / 8.0
		var tx := cos(ang) * tower_r
		var tz := sin(ang) * tower_r
		for c_off in [Vector2(-ts * 0.5, -ts * 0.5), Vector2(ts * 0.5, -ts * 0.5), Vector2(-ts * 0.5, ts * 0.5), Vector2(ts * 0.5, ts * 0.5)]:
			ribs.append({ "c": Vector3(tx + c_off.x, 0.0, tz + c_off.y), "s": Vector3(1.1, sleeve_h, 1.1) })
		lamps.append({ "c": Vector3(tx - cos(ang) * (ts * 0.5 + 0.6), 0.0, tz - sin(ang) * (ts * 0.5 + 0.6)), "s": Vector3(0.28, sleeve_h, 0.28) })
		var by := -SLEEVE_HALF + 25.0
		while by < SLEEVE_HALF:
			ribs.append({ "c": Vector3(tx, by, tz - ts * 0.5), "s": Vector3(ts - 1.1, 0.6, 0.6) })
			ribs.append({ "c": Vector3(tx, by, tz + ts * 0.5), "s": Vector3(ts - 1.1, 0.6, 0.6) })
			ribs.append({ "c": Vector3(tx - ts * 0.5, by, tz), "s": Vector3(0.6, 0.6, ts - 1.1) })
			ribs.append({ "c": Vector3(tx + ts * 0.5, by, tz), "s": Vector3(0.6, 0.6, ts - 1.1) })
			by += 25.0
	SliceMaterials.add_multimesh(_sleeve_anchor, walls, &"shaft_wall")
	SliceMaterials.add_multimesh(_sleeve_anchor, ribs, &"structure")
	SliceMaterials.add_multimesh(_sleeve_anchor, lamps, &"window_glow")
	SliceMaterials.add_multimesh(_sleeve_anchor, beacons, &"beacon_red")


## Open guide mast for lifts that climb outside a stack: a 2,800 m lattice that tracks
## the cage in 200 m steps like the shaft sleeve, with a rail of dim lamps.
func _build_guide_mast() -> void:
	_sleeve_anchor = WorldAnchor.new()
	_sleeve_anchor.name = "GuideMast"
	_sleeve_anchor.lx = lx - 11.5
	_sleeve_anchor.ly = clampf(car_ly, sleeve_min, sleeve_max)
	_sleeve_anchor.lz = lz - 1.0
	add_child(_sleeve_anchor)
	var steel: Array = []
	var lamps: Array = []
	var h := SLEEVE_HALF * 2.0
	# Local offset of the cage centre inside the sleeve frame is (+11.5, 0, +1.0).
	var c := Vector3(11.5, 0.0, 1.0)
	var r := HALF_W + 1.5
	for sx: float in [-1.0, 1.0]:
		steel.append({ "c": c + Vector3(sx * r, 0.0, r), "s": Vector3(0.7, h, 0.7) })
		steel.append({ "c": c + Vector3(sx * r, 0.0, -r - 3.0), "s": Vector3(0.7, h, 0.7) })
	# Two guide rails hard against the cage's outer (east) side: what it actually runs on.
	for sz: float in [-1.0, 1.0]:
		steel.append({ "c": c + Vector3(HALF_W + 0.72, 0.0, sz * (HALF_W - 0.5)), "s": Vector3(0.3, h, 0.3) })
	var y := -SLEEVE_HALF + 25.0
	var k := 0
	while y < SLEEVE_HALF:
		steel.append({ "c": c + Vector3(0.0, y, r), "s": Vector3(r * 2.0 - 0.7, 0.5, 0.5) })
		steel.append({ "c": c + Vector3(0.0, y + 0.6, -r - 3.0), "s": Vector3(r * 2.0 - 0.7, 0.5, 0.5) })
		for sx: float in [-1.0, 1.0]:
			steel.append({ "c": c + Vector3(sx * r, y + 1.2, -1.5), "s": Vector3(0.5, 0.5, r * 2.0 + 3.0 - 0.7) })
		if k % 4 == 0:
			# Tie back toward the stack every 100 m.
			steel.append({ "c": c + Vector3(0.0, y + 1.8, -r - 3.0 - 6.0), "s": Vector3(0.6, 0.6, 12.0) })
		y += 25.0
		k += 1
	# A cross-tie between the rails every 25 m, and a dim marker lamp every 100 m
	# (no continuous lamp strip: it read as a bright line through the fog).
	var ty := -SLEEVE_HALF + 12.5
	var tk := 0
	while ty < SLEEVE_HALF:
		steel.append({ "c": c + Vector3(HALF_W + 0.72, ty, 0.0), "s": Vector3(0.2, 0.2, (HALF_W - 0.5) * 2.0 - 0.3) })
		steel.append({ "c": c + Vector3((HALF_W + 0.72 + r) * 0.5, ty + 0.3, r * 0.5 + (HALF_W - 0.5) * 0.5), "s": Vector3(r - HALF_W - 0.72 + 0.2, 0.2, 0.2) })
		if tk % 4 == 0:
			lamps.append({ "c": c + Vector3(HALF_W + 0.95, ty + 0.5, 0.0), "s": Vector3(0.12, 0.4, 0.4) })
		ty += 25.0
		tk += 1
	SliceMaterials.add_multimesh(_sleeve_anchor, steel, &"rust_steel")
	SliceMaterials.add_multimesh(_sleeve_anchor, lamps, &"window_glow")


func _build_station_console(station_ly: float, side: int) -> void:
	var anc := WorldAnchor.new()
	var tag := "F77" if side == 2 else ("MID" if side == 1 else "BOT")
	anc.name = "RelayStation_%s" % tag
	anc.lx = lx - 3.1
	anc.ly = station_ly
	anc.lz = lz - 2.6
	add_child(anc)
	var console := RelayConsole.new()
	console.relay = self
	console.station_side = side
	console.position = Vector3(0, 0.65, 0)
	anc.add_child(console)
	SliceMaterials.add_box(console, console, Vector3.ZERO, Vector3(0.45, 1.30, 0.68), &"plate")
	SliceMaterials.add_box(console, null, Vector3(-0.24, 0.34, 0), Vector3(0.04, 0.18, 0.38), &"window_glow", false)
	SliceMaterials.add_box(anc, null, Vector3(0.05, 1.78, 0), Vector3(0.08, 0.96, 0.08), &"structure", false)
	SliceMaterials.add_box(anc, null, Vector3(0.0, 2.08, 0), Vector3(0.08, 0.56, 2.55), &"structure", false)
	var txt := "DEEP EXPRESS CAGE · EL-DEEP-00\nFLOOR 77 (41,000 M) ↔ CRUST (0 M)"
	if side == 1:
		txt = "DEEP EXPRESS CAGE · EL-DEEP-00\nUNDERCROFT 76-B (40,780 M) → CRUST (0 M)"
	elif side < 0:
		txt = "DEEP EXPRESS CAGE · EL-DEEP-00\nASSET 31 CRUST (0 M) ↔ FLOOR 77 (41,000 M)"
	if sleeve_kind == "mast":
		txt = "%s · %s\n%s" % [title, relay_id, "FLOOR 77  ↔  TOP FLOOR"]
	SliceMaterials.add_sign(anc, Vector3(-0.07, 2.08, 0), txt, 0.0042, Color(1.0, 0.84, 0.52), -PI * 0.5)


func _make_audio(path: String, loop: bool, vol_db: float, pitch: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	if ResourceLoader.exists(path):
		var s: AudioStreamWAV = load(path)
		if loop:
			s = s.duplicate()
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = int(s.get_length() * s.mix_rate)
		p.stream = s
	p.bus = &"World"
	p.unit_size = 12.0
	p.volume_db = vol_db
	p.pitch_scale = pitch
	car_body.add_child(p)
	return p


func _station_ly(side: int) -> float:
	if side == 2:
		return top_ly
	if side == 1:
		return mid_ly
	return bot_ly


func _station_name(side: int) -> String:
	if side == 2:
		return top_name
	if side == 1:
		return mid_name
	return bot_name


func console_prompt(station_side: int) -> String:
	if not powered:
		return "[E] Install Salvaged Relay — Unlock %.0f km %s" % [_span_km(), title.capitalize()]
	if station_side == 0:
		if moving:
			var rev_dest := top_name if target_ly < _half_way() else bot_name
			return "[E] Reverse → %s  (now %.1f km)" % [rev_dest, car_ly / 1000.0]
		var going_down := car_ly > _half_way()
		return "[E] %s %.1f km → %s" % ["Descend" if going_down else "Ascend", _span_km(), bot_name if going_down else top_name]
	var want_ly := _station_ly(station_side)
	if absf(car_ly - want_ly) < 1.0 and not moving:
		return "%s Docked — Step aboard & press [E] on panel" % title.capitalize()
	return "[E] Call %s to %s" % [title.capitalize(), _station_name(station_side)]


func power_on() -> void:
	powered = true
	if _clunk != null:
		_clunk.play()
	_sync_visuals()


func activate_console(station_side: int) -> String:
	if not powered:
		return "UNPOWERED"
	if station_side == 0:
		if moving:
			# Smoothly decelerate through 0 m/s at <= 0.46 G before reversing direction (never snap velocity).
			target_ly = top_ly if target_ly < _half_way() else bot_ly
			if _clunk != null:
				_clunk.play()
			_sync_visuals()
			return "%s braking smoothly to reverse → %s" % [relay_id, bot_name if target_ly < _half_way() else top_name]
		target_ly = bot_ly if car_ly > _half_way() else top_ly
		moving = true
		if _clunk != null:
			_clunk.play()
		if _motor != null:
			_motor.play()
		_sync_visuals()
		if target_ly < _half_way():
			return "%s descending %.1f km to %s" % [relay_id, _span_km(), bot_name]
		return "%s ascending %.1f km to %s" % [relay_id, _span_km(), top_name]
	var want_ly := _station_ly(station_side)
	if absf(car_ly - want_ly) < 1.0 and not moving:
		return "Cage docked — step inside and press [E] on the east panel"
	target_ly = want_ly
	moving = true
	if _clunk != null:
		_clunk.play()
	if _motor != null and not _motor.playing:
		_motor.play()
	_sync_visuals()
	return "Calling %s to %s..." % [relay_id, _station_name(station_side)]


func _attach_rider_if_aboard() -> void:
	if _rider != null or car_anchor == null:
		return
	var player := get_tree().get_first_node_in_group(&"player") as PlayerController
	if player == null:
		return
	var rel := car_anchor.to_local(player.global_position)
	if absf(rel.x) <= HALF_W and absf(rel.z) <= HALF_W and rel.y >= -0.6 and rel.y <= 3.5:
		_rider = player
		_rider_local = Vector3(clampf(rel.x, -1.55, 1.55), 0.02, clampf(rel.z, -1.55, 1.55))
		_rider.riding_transport = true
		_rider.velocity = Vector3.ZERO
		_rider.reset_fall_tracking()


func _release_rider() -> void:
	if _rider != null and is_instance_valid(_rider):
		_rider.riding_transport = false
		_rider.velocity = Vector3.ZERO
		_rider.reset_fall_tracking()
	_rider = null


func _process(_delta: float) -> void:
	# Smooth visual interpolation at full display refresh rate (144/240+ FPS) so the
	# passing 41 km shaft walls glide with zero 60 Hz micro-stutter.
	if moving and car_anchor != null:
		var f := Engine.get_physics_interpolation_fraction()
		var vis_ly := lerpf(_prev_car_ly, car_ly, f)
		car_anchor.set_logical(lx, vis_ly, lz)
		if _rider != null and is_instance_valid(_rider):
			_rider.global_position = car_anchor.to_global(_rider_local)


func _physics_process(delta: float) -> void:
	if not moving or car_anchor == null:
		_prev_car_ly = car_ly
		if _rider != null:
			_release_rider()
		if _sleeve_anchor != null:
			var p := get_tree().get_first_node_in_group(&"player") as Node3D
			var ref_y := WorldOrigin.to_logical(p.position)[1] if p != null else car_ly
			var sy := clampf(roundf(ref_y / SLEEVE_STEP) * SLEEVE_STEP, sleeve_min, sleeve_max)
			if absf(_sleeve_anchor.ly - sy) > 1.0:
				_sleeve_anchor.set_logical(lx - 11.5, sy, lz - 1.0)
		return
	_prev_car_ly = car_ly
	# Lock onto any player standing inside the cage so they ride in the cage's exact
	# local frame (zero collider lag, zero phasing at 400 m/s across 40 vertical rebases).
	if _rider == null or not is_instance_valid(_rider):
		_rider = null
		_attach_rider_if_aboard()

	# Allow smooth local walking inside the 4.2 x 4.2 m cage while riding.
	if _rider != null and _rider.input_enabled:
		var iv := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		if iv.length() > 0.01:
			var wish := _rider.transform.basis * Vector3(iv.x, 0.0, iv.y)
			wish.y = 0.0
			if wish.length() > 0.001:
				wish = wish.normalized() * minf(iv.length(), 1.0) * _rider.walk_speed * delta
				_rider_local.x = clampf(_rider_local.x + wish.x, -1.55, 1.45)
				_rider_local.z = clampf(_rider_local.z + wish.z, -1.55, 1.55)
		_rider_local.y = 0.02

	# Human-safe S-curve kinematics: <= 4.5 m/s^2 (~0.46 G), felt load stays in 0.54 G .. 1.46 G
	# all the way through gentle hydraulic soft-docking at 0.00 m/s.
	var to_target := target_ly - car_ly
	var dist := absf(to_target)
	if dist < 0.02 and absf(_vel) < 0.06:
		car_ly = target_ly
		_vel = 0.0
		_accel = 0.0
		moving = false
	else:
		var dir := signf(to_target)
		# Kinematic braking curve transitioning into gentle exponential soft-docking in final ~1.5 m.
		var brake_a := MAX_ACCEL * 0.84
		var v_stop := minf(sqrt(2.0 * brake_a * dist), dist * 2.1)
		var want_vel := dir * minf(MAX_SPEED, v_stop)
		var want_accel := clampf((want_vel - _vel) / maxf(delta, 0.001), -MAX_ACCEL, MAX_ACCEL)
		# S-curve jerk limiting during departure, cruise, and braking; soft exponential settle in final 2 m.
		if dist > 2.0:
			_accel = move_toward(_accel, want_accel, MAX_JERK * delta)
		else:
			_accel = want_accel
		_accel = clampf(_accel, -MAX_ACCEL, MAX_ACCEL)
		var next_vel := clampf(_vel + _accel * delta, -MAX_SPEED, MAX_SPEED)
		var step := (_vel + next_vel) * 0.5 * delta
		if (to_target > 0.0 and step >= to_target) or (to_target < 0.0 and step <= to_target):
			car_ly = target_ly
			_vel = 0.0
			_accel = 0.0
			moving = false
		else:
			car_ly += step
			_vel = next_vel

	car_anchor.set_logical(lx, car_ly, lz)
	car_anchor.force_update_transform()
	if car_body != null:
		car_body.force_update_transform()

	# Pin rider cleanly to exact cage-local position (eliminates camera/floor phasing completely).
	if _rider != null:
		_rider.global_position = car_anchor.to_global(_rider_local)
		_rider.velocity = Vector3.ZERO
		_rider.reset_fall_tracking()

	# Keep the 2,800 m cylindrical sleeve clamped flush between CRUST-00 (1,200 m) and EL-CYL-77 (38,800 m)
	# with zero overlap and zero gap; world-Y shaft_wall & 100/25 m multiples make 200 m steps invisible.
	if _sleeve_anchor != null:
		var snapped_y := clampf(roundf(car_ly / SLEEVE_STEP) * SLEEVE_STEP, sleeve_min, sleeve_max)
		if absf(_sleeve_anchor.ly - snapped_y) > 1.0:
			_sleeve_anchor.set_logical(lx - 11.5, snapped_y, lz - 1.0)

	if not moving:
		_prev_car_ly = car_ly
		_release_rider()
		if _motor != null:
			_motor.stop()
		if _clunk != null:
			_clunk.play()
	_sync_visuals()


func _stratum_name(alt: float) -> String:
	if not strata.is_empty():
		for st: Array in strata:
			if alt > float(st[0]):
				return String(st[1])
		return String(strata[strata.size() - 1][1])
	if alt > 39000.0:
		return "UPPER MANTLE · F77-74"
	if alt > 25000.0:
		return "MID-MANTLE · RESIDENTIAL"
	if alt > 10000.0:
		return "LOWER MANTLE · FOUNDRIES"
	if alt > 1000.0:
		return "FOUNDATION KEEL · ORE"
	return "ASSET 31 CRUST · EXCAVATION"


func _sync_visuals() -> void:
	if car_body == null:
		return
	_gate_shape.disabled = not moving
	_gate_mesh.visible = moving
	_cab_light.light_energy = 1.9 if powered else 0.7
	var spd := absf(_vel)
	if _motor != null and moving:
		_motor.pitch_scale = 0.62 + clampf(spd / MAX_SPEED, 0.0, 1.0) * 0.48
	var alt_i := int(roundf(car_ly))
	if not powered:
		_status_label.text = "%s  ·  %d M\nOFFLINE · INSERT SALVAGED RELAY" % [relay_id, alt_i]
	elif moving:
		var arrow := "▼" if _vel < -0.1 else ("▲" if _vel > 0.1 else "•")
		var felt_g := (9.81 + _accel) / 9.81
		_status_label.text = "%s  ·  %d M  (%d M/S · %.2f G)\n%s %s" % [relay_id, alt_i, int(roundf(spd)), felt_g, arrow, _stratum_name(car_ly)]
	else:
		var dock := "FLOOR 77 HUB" if car_ly > 40900.0 else ("UNDERCROFT 76-B" if car_ly > 20000.0 else "CRUST OUTPOST 00")
		if sleeve_kind == "mast":
			dock = "TOP FLOOR" if car_ly > _half_way() else "FLOOR 77 EDGE"
		_status_label.text = "%s  ·  %d M\nONLINE · DOCKED %s" % [relay_id, alt_i, dock]


func serialize() -> Dictionary:
	return {
		"powered": powered,
		"car_ly": car_ly,
		"moving": moving,
		"target_ly": target_ly,
		"vel": _vel,
		"accel": _accel,
	}


func deserialize(d: Dictionary) -> void:
	powered = bool(d.get("powered", true))
	car_ly = clampf(float(d.get("car_ly", top_ly)), bot_ly, top_ly)
	moving = bool(d.get("moving", false))
	target_ly = clampf(float(d.get("target_ly", top_ly)), bot_ly, top_ly)
	_vel = clampf(float(d.get("vel", 0.0)), -MAX_SPEED, MAX_SPEED)
	_accel = clampf(float(d.get("accel", 0.0)), -MAX_ACCEL, MAX_ACCEL)
	_prev_car_ly = car_ly
	if car_anchor != null:
		car_anchor.set_logical(lx, car_ly, lz)
	if _sleeve_anchor != null:
		var snapped_y := clampf(roundf(car_ly / SLEEVE_STEP) * SLEEVE_STEP, sleeve_min, sleeve_max)
		_sleeve_anchor.set_logical(lx - 11.5, snapped_y, lz - 1.0)
	if moving and _motor != null and not _motor.playing:
		_motor.play()
	elif not moving and _motor != null and _motor.playing:
		_motor.stop()
	_sync_visuals()
