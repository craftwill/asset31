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


func _ready() -> void:
	add_to_group(GROUP)
	_build_cage()
	_build_stratum_sleeve()
	_build_station_console(TOP_LY, 2)
	_build_station_console(MID_LY, 1)
	_build_station_console(BOT_LY, -1)
	_sync_visuals()


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
	_sleeve_anchor.ly = SLEEVE_MAX_Y
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
		return TOP_LY
	if side == 1:
		return MID_LY
	return BOT_LY


func _station_name(side: int) -> String:
	if side == 2:
		return "Floor 77 Hub (41,000 m)"
	if side == 1:
		return "Undercroft 76-B (40,780 m)"
	return "Asset 31 Crust (0 m)"


func console_prompt(station_side: int) -> String:
	if not powered:
		return "[E] Install Salvaged Relay — Unlock 41 km Deep Express Cage"
	if station_side == 0:
		if moving:
			var rev_dest := "Floor 77 Hub (41,000 m)" if target_ly < 1.0 else "Asset 31 Crust (0 m)"
			return "[E] Reverse → %s  (now %.1f km)" % [rev_dest, car_ly / 1000.0]
		var dest := "Asset 31 Crust (0 m)" if car_ly > 20000.0 else "Floor 77 Hub (41,000 m)"
		var verb := "Descend" if car_ly > 20000.0 else "Ascend"
		return "[E] %s 41.0 km → %s" % [verb, dest]
	var want_ly := _station_ly(station_side)
	if absf(car_ly - want_ly) < 1.0 and not moving:
		return "41 km Deep Express Cage Docked — Step aboard & press [E] on panel"
	return "[E] Call Deep Express Cage to %s" % _station_name(station_side)


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
			target_ly = TOP_LY if target_ly < 1.0 else BOT_LY
			if _clunk != null:
				_clunk.play()
			_sync_visuals()
			return "EL-DEEP-00 braking smoothly to reverse → %s" % ("Asset 31 Crust (0 m)" if target_ly < 1.0 else "Floor 77 Hub (41,000 m)")
		target_ly = BOT_LY if car_ly > 20000.0 else TOP_LY
		moving = true
		if _clunk != null:
			_clunk.play()
		if _motor != null:
			_motor.play()
		_sync_visuals()
		return "EL-DEEP-00 descending 41.0 km to Asset 31 Crust (0 m)" if target_ly < 1.0 else "EL-DEEP-00 ascending 41.0 km to Floor 77 Hub (41,000 m)"
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
	return "Calling EL-DEEP-00 to %s..." % _station_name(station_side)


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
			var sy := clampf(roundf(ref_y / SLEEVE_STEP) * SLEEVE_STEP, SLEEVE_MIN_Y, SLEEVE_MAX_Y)
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
		var snapped_y := clampf(roundf(car_ly / SLEEVE_STEP) * SLEEVE_STEP, SLEEVE_MIN_Y, SLEEVE_MAX_Y)
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
		_status_label.text = "EL-DEEP-00  ·  %d M\nOFFLINE · INSERT SALVAGED RELAY" % alt_i
	elif moving:
		var arrow := "▼" if _vel < -0.1 else ("▲" if _vel > 0.1 else "•")
		var felt_g := (9.81 + _accel) / 9.81
		_status_label.text = "EL-DEEP-00  ·  %d M  (%d M/S · %.2f G)\n%s %s" % [alt_i, int(roundf(spd)), felt_g, arrow, _stratum_name(car_ly)]
	else:
		var dock := "FLOOR 77 HUB" if car_ly > 40900.0 else ("UNDERCROFT 76-B" if car_ly > 20000.0 else "CRUST OUTPOST 00")
		_status_label.text = "EL-DEEP-00  ·  %d M\nONLINE · DOCKED %s" % [alt_i, dock]


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
	car_ly = clampf(float(d.get("car_ly", TOP_LY)), BOT_LY, TOP_LY)
	moving = bool(d.get("moving", false))
	target_ly = clampf(float(d.get("target_ly", TOP_LY)), BOT_LY, TOP_LY)
	_vel = clampf(float(d.get("vel", 0.0)), -MAX_SPEED, MAX_SPEED)
	_accel = clampf(float(d.get("accel", 0.0)), -MAX_ACCEL, MAX_ACCEL)
	_prev_car_ly = car_ly
	if car_anchor != null:
		car_anchor.set_logical(lx, car_ly, lz)
	if _sleeve_anchor != null:
		var snapped_y := clampf(roundf(car_ly / SLEEVE_STEP) * SLEEVE_STEP, SLEEVE_MIN_Y, SLEEVE_MAX_Y)
		_sleeve_anchor.set_logical(lx - 11.5, snapped_y, lz - 1.0)
	if moving and _motor != null and not _motor.playing:
		_motor.play()
	elif not moving and _motor != null and _motor.playing:
		_motor.stop()
	_sync_visuals()
