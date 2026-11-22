class_name DeepRelayLift
extends Node3D
## Heavy Express Ore-Relay Cage (EL-DEEP-00): physically connects Undercroft 76-B
## (40,780 m) to Asset 31's original buried planetary mining surface (0 m) across
## 41 km of real float64 vertical space (Canon §0.1, Brief §3.6).
## Requires 1 Salvaged Relay to engage. Uses a WorldAnchor for the cage itself
## and sync_to_physics = false so 40 vertical 1024 m origin rebases stay rock-solid.

const GROUP := &"deep_relays"
const TOP_LY := 40780.0
const BOT_LY := 0.0
const HALF_W := 2.1
const SLEEVE_STEP := 200.0

var relay_id := "EL-DEEP-00"
var lx := 3271.5
var lz := -179.0
var car_ly := TOP_LY
var target_ly := TOP_LY
var powered := false
var moving := false
var _cur_speed := 0.0
var _last_dir := -1.0

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
	_build_station_console(TOP_LY, 1)
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
	# Reinforced steel walls on east (+X), north (-Z), south (+Z) with open viewing upper mesh slots.
	SliceMaterials.add_box(car_body, car_body, Vector3(HALF_W - 0.08, 0.65, 0), Vector3(0.16, 1.3, HALF_W * 2.0), &"plate")
	SliceMaterials.add_box(car_body, car_body, Vector3(0, 0.65, -HALF_W + 0.08), Vector3(HALF_W * 2.0, 1.3, 0.16), &"plate")
	SliceMaterials.add_box(car_body, car_body, Vector3(0, 0.65, HALF_W - 0.08), Vector3(HALF_W * 2.0, 1.3, 0.16), &"plate")
	# Corner steel cage columns + roof canopy + beacon.
	for cx: float in [-HALF_W + 0.12, HALF_W - 0.12]:
		for cz: float in [-HALF_W + 0.12, HALF_W - 0.12]:
			SliceMaterials.add_box(car_body, null, Vector3(cx, 1.65, cz), Vector3(0.16, 3.3, 0.16), &"structure", false)
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
	SliceMaterials.add_box(console, console, Vector3.ZERO, Vector3(0.46, 1.25, 0.80), &"plate")
	SliceMaterials.add_box(console, null, Vector3(-0.24, 0.34, 0), Vector3(0.04, 0.20, 0.44), &"window_glow", false)

	_motor = _make_audio("res://audio/tram_hum.wav", true, -6.0, 0.65)
	_clunk = _make_audio("res://audio/lift_clunk.wav", false, -4.0, 0.82)


## Repeating 600 m shaft stratum sleeve that tracks the cage modulo 200 m during
## the middle 38 km express transit so the player sees endless steel ribs and
## glowing amber guide rails rushing past the open cage walls.
func _build_stratum_sleeve() -> void:
	_sleeve_anchor = WorldAnchor.new()
	_sleeve_anchor.name = "DeepShaftSleeve"
	_sleeve_anchor.lx = lx - 11.5
	_sleeve_anchor.ly = 20000.0
	_sleeve_anchor.lz = lz - 1.0
	_sleeve_anchor.visible = false
	add_child(_sleeve_anchor)
	var ribs: Array = []
	var lamps: Array = []
	var R := 148.0
	var sides := 16
	var chord := 2.0 * R * tan(PI / float(sides))
	for k in range(-3, 4):
		var y := float(k) * SLEEVE_STEP
		for i in sides:
			var ang := float(i) * TAU / float(sides)
			var rot := Vector3(0.0, -ang + PI * 0.5, 0.0)
			ribs.append({ "c": Vector3(cos(ang) * R, y, sin(ang) * R), "s": Vector3(chord, 6.0, 6.0), "r": rot })
			if i % 2 == 0:
				lamps.append({ "c": Vector3(cos(ang) * (R - 3.6), y + 3.2, sin(ang) * (R - 3.6)), "s": Vector3(chord * 0.8, 0.35, 0.35), "r": rot })
	for i in 8:
		var ang := (float(i) + 0.5) * TAU / 8.0
		var tx := cos(ang) * (R * 0.62)
		var tz := sin(ang) * (R * 0.62)
		ribs.append({ "c": Vector3(tx, 0.0, tz), "s": Vector3(2.2, SLEEVE_STEP * 7.0, 2.2) })
		lamps.append({ "c": Vector3(tx - cos(ang) * 2.0, 0.0, tz - sin(ang) * 2.0), "s": Vector3(0.35, SLEEVE_STEP * 7.0, 0.35) })
	SliceMaterials.add_multimesh(_sleeve_anchor, ribs, &"structure")
	SliceMaterials.add_multimesh(_sleeve_anchor, lamps, &"window_glow")


func _build_station_console(station_ly: float, side: int) -> void:
	var anc := WorldAnchor.new()
	anc.name = "RelayStation_%s" % ("TOP" if side > 0 else "BOT")
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
	SliceMaterials.add_box(anc, null, Vector3(0.0, 2.08, 0), Vector3(0.08, 0.56, 2.25), &"structure", false)
	var txt := "DEEP RELAY CAGE · EL-DEEP-00\n40,780 M → ASSET 31 CRUST (0 M)" if side > 0 else "DEEP RELAY CAGE · EL-DEEP-00\nASSET 31 CRUST (0 M) → 40,780 M"
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


func console_prompt(station_side: int) -> String:
	if not powered:
		return "[E] Install Salvaged Relay — Unlock 41 km Deep Descent Cage"
	if station_side == 0:
		if moving:
			return "EL-DEEP-00 In Express Transit (%.1f km altitude)" % (car_ly / 1000.0)
		var dest := "Asset 31 Crust (0 m)" if car_ly > 20000.0 else "Undercroft 76-B (40,780 m)"
		return "[E] Engage Deep Relay Cage → %s" % dest
	var want_ly := TOP_LY if station_side > 0 else BOT_LY
	if absf(car_ly - want_ly) < 1.0 and not moving:
		return "Deep Relay Cage Docked — Step aboard & press [E] on panel"
	return "[E] Recall Deep Relay Cage to %s" % ("Undercroft 76-B" if station_side > 0 else "Crust Outpost")


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
			return "Express descent locked until arrival at %s" % ("Crust (0 m)" if target_ly < 1.0 else "Undercroft (40,780 m)")
		target_ly = BOT_LY if car_ly > 20000.0 else TOP_LY
		_last_dir = -1.0 if target_ly < car_ly else 1.0
		moving = true
		_cur_speed = 8.0
		if _clunk != null:
			_clunk.play()
		if _motor != null:
			_motor.play()
		_sync_visuals()
		return "EL-DEEP-00 descending 41.0 km to Asset 31 Crust" if target_ly < 1.0 else "EL-DEEP-00 ascending 41.0 km to Floor 76-B"
	var want_ly := TOP_LY if station_side > 0 else BOT_LY
	if absf(car_ly - want_ly) < 1.0 and not moving:
		return "Cage docked — step inside and activate east panel [E]"
	target_ly = want_ly
	_last_dir = -1.0 if target_ly < car_ly else 1.0
	moving = true
	_cur_speed = 12.0
	if _clunk != null:
		_clunk.play()
	if _motor != null and not _motor.playing:
		_motor.play()
	_sync_visuals()
	return "Recalling EL-DEEP-00 express cage..."


func _physics_process(delta: float) -> void:
	if not moving or car_anchor == null:
		return
	var dist_top := absf(TOP_LY - car_ly)
	var dist_bot := absf(car_ly - BOT_LY)
	var edge_dist := minf(dist_top, dist_bot)
	# Grounded smooth departure/arrival near both landings, high-speed express in the middle 38 km.
	var want_speed := lerpf(10.0, 720.0, clampf(edge_dist / 500.0, 0.0, 1.0))
	_cur_speed = move_toward(_cur_speed, want_speed, 160.0 * delta)
	var prev_ly := car_ly
	car_ly = move_toward(car_ly, target_ly, _cur_speed * delta)
	var dy := car_ly - prev_ly
	car_anchor.set_logical(lx, car_ly, lz)

	# Carry player inside cage cleanly across 40 floating-origin vertical rebases.
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player != null and absf(dy) > 0.0:
		var rel := car_anchor.to_local(player.global_position)
		if absf(rel.x) <= HALF_W and absf(rel.z) <= HALF_W and rel.y > -0.45 and rel.y < 3.2:
			player.position.y += dy

	# Stream repeating shaft sleeve only while inside the deep middle 38 km transit band.
	if _sleeve_anchor != null:
		var in_mid := car_ly > 480.0 and car_ly < 38800.0
		_sleeve_anchor.visible = in_mid
		if in_mid:
			var snapped_y := roundf(car_ly / SLEEVE_STEP) * SLEEVE_STEP
			if absf(_sleeve_anchor.ly - snapped_y) > 1.0:
				_sleeve_anchor.set_logical(lx - 11.5, snapped_y, lz - 1.0)

	if is_equal_approx(car_ly, target_ly):
		moving = false
		_cur_speed = 0.0
		if _sleeve_anchor != null:
			_sleeve_anchor.visible = false
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
	if _motor != null and moving:
		_motor.pitch_scale = 0.62 + clampf(_cur_speed / 720.0, 0.0, 1.0) * 0.48
	var alt_i := int(roundf(car_ly))
	if not powered:
		_status_label.text = "EL-DEEP-00  ·  %d M\nOFFLINE · INSERT SALVAGED RELAY" % alt_i
	elif moving:
		var arrow := "▼" if target_ly < car_ly else "▲"
		_status_label.text = "EL-DEEP-00  ·  %d M  (%d M/S)\n%s %s" % [alt_i, int(roundf(_cur_speed)), arrow, _stratum_name(car_ly)]
	else:
		var dock := "UNDERCROFT 76-B" if car_ly > 20000.0 else "CRUST OUTPOST 00"
		_status_label.text = "EL-DEEP-00  ·  %d M\nONLINE · DOCKED %s" % [alt_i, dock]


func serialize() -> Dictionary:
	return {
		"powered": powered,
		"car_ly": car_ly,
		"moving": moving,
		"target_ly": target_ly,
	}


func deserialize(d: Dictionary) -> void:
	powered = bool(d.get("powered", false))
	car_ly = clampf(float(d.get("car_ly", TOP_LY)), BOT_LY, TOP_LY)
	moving = bool(d.get("moving", false))
	target_ly = clampf(float(d.get("target_ly", TOP_LY)), BOT_LY, TOP_LY)
	if car_anchor != null:
		car_anchor.set_logical(lx, car_ly, lz)
	if moving and _motor != null and not _motor.playing:
		_motor.play()
	elif not moving and _motor != null and _motor.playing:
		_motor.stop()
	_sync_visuals()
