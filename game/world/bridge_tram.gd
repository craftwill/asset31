class_name BridgeTram
extends Node3D
## Physical 3 km Maintenance Rail Tram (TRAM-077) running on a cantilevered south
## track along BR-077-A from STK-0412 East Gate (x = -1488) to STK-0413 West
## Arrival (x = +1488). Requires one Fuse Cell to restore power; moves continuously
## across the real chasm with zero teleports or loading screens (Brief §3.6, §9).

const GROUP := &"bridge_trams"
const TRACK_Z := 8.1
const SPEED := 18.0
const HALF_LEN := 2.8
const HALF_W := 1.4

var tram_id := "TRAM-077"
var west_x := -1488.0
var east_x := 1488.0
var powered := false
var moving := false
var target_x := -1488.0
var _last_dir := 1.0

var car: AnimatableBody3D
var _gate_mesh: MeshInstance3D
var _gate_shape: CollisionShape3D
var _headlamp_w: MeshInstance3D
var _headlamp_e: MeshInstance3D
var _status_label: Label3D
var _car_light: OmniLight3D
var _motor: AudioStreamPlayer3D
var _clunk: AudioStreamPlayer3D


static func build(bridge_len: float) -> BridgeTram:
	var t := BridgeTram.new()
	t.name = "BridgeTram"
	t.west_x = -bridge_len * 0.5 + 12.0
	t.east_x = bridge_len * 0.5 - 12.0
	t.target_x = t.west_x
	return t


func _ready() -> void:
	add_to_group(GROUP)
	_build_car()
	_build_station_console(west_x - 3.2, -1)
	_build_station_console(east_x + 3.2, 1)
	_sync_visuals()


func _build_car() -> void:
	car = AnimatableBody3D.new()
	car.name = "TramCar"
	car.sync_to_physics = false
	car.set_meta(&"surface", "metal")
	car.position = Vector3(west_x, 0.0, TRACK_Z)
	add_child(car)

	# Steel flatbed deck (5.6 x 2.8 m, flush with boarding lip at y = 0.0).
	SliceMaterials.add_box(car, car, Vector3(0, -0.14, 0), Vector3(HALF_LEN * 2.0, 0.28, HALF_W * 2.0), &"bridge_deck")
	SliceMaterials.add_box(car, null, Vector3(0, -0.42, 0), Vector3(HALF_LEN * 1.85, 0.30, HALF_W * 1.65), &"structure", false)
	# Bogie wheels on the twin track rails (z_local = +-0.7).
	for wx: float in [-1.8, 1.8]:
		for wz: float in [-0.7, 0.7]:
			SliceMaterials.add_box(car, null, Vector3(wx, -0.58, wz), Vector3(0.55, 0.36, 0.14), &"structure", false)
	# Low guard rails (south + east + west closed; trimmed corners prevent coplanar z-fighting).
	SliceMaterials.add_box(car, car, Vector3(0, 0.55, HALF_W - 0.06), Vector3(HALF_LEN * 2.0 - 0.26, 1.1, 0.12), &"structure")
	SliceMaterials.add_box(car, car, Vector3(-HALF_LEN + 0.06, 0.55, 0), Vector3(0.12, 1.1, HALF_W * 2.0), &"structure")
	SliceMaterials.add_box(car, car, Vector3(HALF_LEN - 0.06, 0.55, 0), Vector3(0.12, 1.1, HALF_W * 2.0), &"structure")
	# Overhead open steel frame & cab canopy + corner stanchions.
	for cx: float in [-HALF_LEN + 0.12, HALF_LEN - 0.12]:
		for cz: float in [-HALF_W + 0.12, HALF_W - 0.12]:
			SliceMaterials.add_box(car, null, Vector3(cx, 1.35, cz), Vector3(0.12, 2.7, 0.12), &"structure", false)
	SliceMaterials.add_box(car, null, Vector3(0, 2.72, 0), Vector3(HALF_LEN * 2.0, 0.14, HALF_W * 2.0), &"structure", false)

	# Glowing north boarding safety bar (closes while moving across the chasm).
	_gate_mesh = SliceMaterials.add_box(car, null, Vector3(0, 0.95, -HALF_W + 0.06), Vector3(HALF_LEN * 1.9, 0.08, 0.08), &"rail_glow", false)
	_gate_shape = CollisionShape3D.new()
	var gs := BoxShape3D.new()
	gs.size = Vector3(HALF_LEN * 1.9, 1.1, 0.12)
	_gate_shape.shape = gs
	_gate_shape.position = Vector3(0, 0.55, -HALF_W + 0.06)
	car.add_child(_gate_shape)

	# Headlamps + cabin work-light + standby red roof beacon + live telemetry readout.
	_headlamp_w = SliceMaterials.add_box(car, null, Vector3(-HALF_LEN - 0.02, 2.45, 0), Vector3(0.12, 0.24, 0.55), &"tram_headlamp", false)
	_headlamp_e = SliceMaterials.add_box(car, null, Vector3(HALF_LEN + 0.02, 2.45, 0), Vector3(0.12, 0.24, 0.55), &"tram_headlamp", false)
	SliceMaterials.add_box(car, null, Vector3(0, 2.86, 0), Vector3(0.28, 0.16, 0.28), &"beacon_red", false)
	SliceMaterials.add_box(car, null, Vector3(0, 2.58, 0), Vector3(0.45, 0.10, 0.45), &"lamp", false)
	_car_light = SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.4, 12.0)
	_car_light.position = Vector3(0, 2.35, 0)
	car.add_child(_car_light)
	SliceMaterials.add_box(car, null, Vector3(0, 1.85, HALF_W - 0.10), Vector3(2.2, 0.48, 0.06), &"structure", false)
	_status_label = SliceMaterials.add_sign(car, Vector3(0, 1.85, HALF_W - 0.15),
		"TRAM-077  ·  OFFLINE", 0.0046, Color(1.0, 0.84, 0.52), PI)

	# On-board interactive drive console / fuse bay mounted inside the south rail.
	var console := TramConsole.new()
	console.name = "OnboardConsole"
	console.tram = self
	console.station_side = 0
	console.position = Vector3(0, 0.72, HALF_W - 0.36)
	car.add_child(console)
	SliceMaterials.add_box(console, console, Vector3.ZERO, Vector3(0.75, 1.15, 0.46), &"plate_local")
	SliceMaterials.add_box(console, null, Vector3(0, 0.34, -0.24), Vector3(0.42, 0.18, 0.04), &"window_glow", false)

	_motor = _make_audio("res://audio/tram_hum.wav", true, -8.0)
	_clunk = _make_audio("res://audio/lift_clunk.wav", false, -5.0)


func _build_station_console(sx: float, side: int) -> void:
	var console := TramConsole.new()
	console.name = "StationConsole_%s" % ("W" if side < 0 else "E")
	console.tram = self
	console.station_side = side
	# Mount cleanly inside the south pedestrian bridge railing (z = 5.52) with zero handrail overlap.
	console.position = Vector3(sx, 0.65, 5.52)
	add_child(console)
	SliceMaterials.add_box(console, console, Vector3.ZERO, Vector3(0.68, 1.30, 0.42), &"plate")
	SliceMaterials.add_box(console, null, Vector3(0, 0.34, -0.22), Vector3(0.38, 0.18, 0.04), &"window_glow", false)
	SliceMaterials.add_box(self, null, Vector3(sx, 1.72, 5.64), Vector3(0.08, 0.88, 0.08), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(sx, 1.98, 5.60), Vector3(2.1, 0.54, 0.08), &"structure", false)
	var sign_txt := "TRAM-077 SPUR\nSTK-0412 → STK-0413" if side < 0 else "TRAM-077 SPUR\nSTK-0413 → STK-0412"
	SliceMaterials.add_sign(self, Vector3(sx, 1.98, 5.53), sign_txt, 0.0044, Color(1.0, 0.84, 0.54), PI)


func _make_audio(path: String, loop: bool, vol_db: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	if ResourceLoader.exists(path):
		var s: AudioStreamWAV = load(path)
		if loop:
			s = s.duplicate()
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = int(s.get_length() * s.mix_rate)
		p.stream = s
	p.bus = &"World"
	p.unit_size = 10.0
	p.volume_db = vol_db
	car.add_child(p)
	return p


func console_prompt(station_side: int) -> String:
	if not powered:
		return "[E] Install Fuse Cell — Power BR-077-A Rail Tram"
	if station_side == 0:
		if moving:
			return "[E] Stop Rail Tram"
		var dest := "STK-0413 (3.0 km)" if car.position.x < 0.0 else "STK-0412 (3.0 km)"
		return "[E] Dispatch Rail Tram → %s" % dest
	var want_x := west_x if station_side < 0 else east_x
	if absf(car.position.x - want_x) < 1.0 and not moving:
		return "Rail Tram Docked — Step aboard & press [E] on lever"
	return "[E] Call Rail Tram to %s Spur" % ("STK-0412" if station_side < 0 else "STK-0413")


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
			moving = false
			if _motor != null:
				_motor.stop()
			if _clunk != null:
				_clunk.play()
			_sync_visuals()
			return "Rail Tram halted at %.2f km" % ((car.position.x - west_x) / 1000.0)
		if absf(car.position.x - west_x) < 1.0:
			target_x = east_x
			_last_dir = 1.0
		elif absf(car.position.x - east_x) < 1.0:
			target_x = west_x
			_last_dir = -1.0
		else:
			target_x = east_x if _last_dir > 0.0 else west_x
		moving = true
		if _clunk != null:
			_clunk.play()
		if _motor != null:
			_motor.play()
		_sync_visuals()
		return "TRAM-077 departing toward %s" % ("STK-0413" if target_x > 0.0 else "STK-0412")
	var dest_x := west_x if station_side < 0 else east_x
	if absf(car.position.x - dest_x) < 1.0 and not moving:
		return "Tram docked — step aboard and pull lever [E]"
	target_x = dest_x
	_last_dir = 1.0 if target_x > car.position.x else -1.0
	moving = true
	if _clunk != null:
		_clunk.play()
	if _motor != null and not _motor.playing:
		_motor.play()
	_sync_visuals()
	return "Calling TRAM-077 to %s Spur" % ("STK-0412" if station_side < 0 else "STK-0413")


func _physics_process(delta: float) -> void:
	if not moving or car == null:
		return
	var prev_x := car.position.x
	var next_x := move_toward(prev_x, target_x, SPEED * delta)
	var dx := next_x - prev_x
	car.position.x = next_x
	# Carry player cleanly with the rail car across floating-origin rebases (zero slip).
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player != null and absf(dx) > 0.0:
		var rel := car.to_local(player.global_position)
		if absf(rel.x) <= HALF_LEN and absf(rel.z) <= HALF_W and rel.y > -0.35 and rel.y < 2.2:
			player.global_position += global_basis.x * dx
	if is_equal_approx(next_x, target_x):
		moving = false
		if _motor != null:
			_motor.stop()
		if _clunk != null:
			_clunk.play()
	_sync_visuals()


func _sync_visuals() -> void:
	if car == null:
		return
	_gate_shape.disabled = not moving
	_gate_mesh.visible = moving
	_headlamp_w.visible = powered
	_headlamp_e.visible = powered
	_car_light.light_energy = 1.6 if powered else 0.75
	var km_e := maxf(0.0, (east_x - car.position.x) / 1000.0)
	var km_w := maxf(0.0, (car.position.x - west_x) / 1000.0)
	if not powered:
		_status_label.text = "TRAM-077  ·  OFFLINE\nINSERT FUSE CELL AT CONSOLE"
	elif moving:
		var dir_lbl := "→ STK-0413 (%.2f KM)" % km_e if target_x > car.position.x else "← STK-0412 (%.2f KM)" % km_w
		_status_label.text = "TRAM-077  ·  IN TRANSIT\n%s" % dir_lbl
	else:
		var dock := "DOCKED STK-0412" if car.position.x < 0.0 else "DOCKED STK-0413"
		_status_label.text = "TRAM-077  ·  ONLINE\n%s" % dock


func serialize() -> Dictionary:
	return {
		"powered": powered,
		"x": car.position.x if car != null else west_x,
		"moving": moving,
		"target_x": target_x,
	}


func deserialize(d: Dictionary) -> void:
	powered = bool(d.get("powered", false))
	moving = bool(d.get("moving", false))
	target_x = float(d.get("target_x", west_x))
	if car != null:
		car.position.x = clampf(float(d.get("x", west_x)), west_x, east_x)
	if moving and _motor != null and not _motor.playing:
		_motor.play()
	elif not moving and _motor != null and _motor.playing:
		_motor.stop()
	_sync_visuals()
