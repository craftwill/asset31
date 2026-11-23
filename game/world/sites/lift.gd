class_name Lift
extends Node3D
## Open freight lift (frame 175s style, at human scale). Stand on the platform
## for a moment to ride; it comes to whichever landing the player waits at.
## The west safety gate closes while moving. Local origin = platform centre at
## the bottom landing; the platform top is 2 cm above its landing.

const HALF := 1.5
const SPEED := 1.6
const BOARD_TIME := 1.0

var top_height := 42.0
var start_at_top := false
var lift_speed := SPEED
var show_altitude := false
var base_logical_y := 41000.0
var platform: AnimatableBody3D
var _gate_shape: CollisionShape3D
var _gate_mesh: MeshInstance3D
var _alt_label: Label3D
var _target := 0.0
var _moving := false
var _on_timer := 0.0
var _needs_exit := false
var _motor: AudioStreamPlayer3D
var _clunk: AudioStreamPlayer3D


func _ready() -> void:
	_build_shaft()
	platform = AnimatableBody3D.new()
	platform.sync_to_physics = false
	platform.set_meta(&"surface", "metal")
	add_child(platform)
	SliceMaterials.add_box(platform, platform, Vector3(0, -0.08, 0), Vector3(3.0, 0.2, 3.0), &"bridge_deck")
	SliceMaterials.add_box(platform, platform, Vector3(-0.06, 0.57, -1.45), Vector3(2.88, 1.1, 0.1), &"structure")
	SliceMaterials.add_box(platform, platform, Vector3(1.45, 0.57, 0), Vector3(0.1, 1.1, 3.0), &"structure")
	_gate_mesh = SliceMaterials.add_box(platform, null, Vector3(-1.45, 0.9, 0), Vector3(0.08, 0.08, 3.0), &"rail_glow", false)
	_gate_shape = CollisionShape3D.new()
	var gs := BoxShape3D.new()
	gs.size = Vector3(0.1, 1.1, 3.0)
	_gate_shape.shape = gs
	_gate_shape.position = Vector3(-1.45, 0.57, 0)
	platform.add_child(_gate_shape)
	var lamp := SliceMaterials.add_box(platform, null, Vector3(1.3, 2.3, -1.3), Vector3(0.3, 0.12, 0.3), &"lamp", false)
	lamp.name = "LiftLamp"
	var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.0, 6.0)
	l.position = Vector3(1.2, 2.1, -1.2)
	platform.add_child(l)
	SliceMaterials.add_box(platform, null, Vector3(1.45, 1.7, -1.45), Vector3(0.06, 1.2, 0.06), &"structure", false)
	if show_altitude:
		SliceMaterials.add_box(platform, null, Vector3(0.0, 1.48, -1.42), Vector3(1.45, 0.44, 0.06), &"structure", false)
		_alt_label = SliceMaterials.add_sign(platform, Vector3(0.0, 1.48, -1.37),
			"EL-CYL-77  ·  41,000 M", 0.0046, Color(1.0, 0.84, 0.52), 0.0)
	_motor = _audio("res://audio/lift_motor.wav", true)
	if top_height > 100.0:
		_motor.pitch_scale = 0.78
	_clunk = _audio("res://audio/lift_clunk.wav", false)
	if start_at_top:
		platform.position.y = top_height
		_target = top_height
	_set_gate(false)
	_update_altitude_display()


func _audio(path: String, loop: bool) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	if ResourceLoader.exists(path):
		var s: AudioStreamWAV = load(path)
		if loop:
			s = s.duplicate()
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = int(s.get_length() * s.mix_rate)
		p.stream = s
	p.bus = &"World"
	p.unit_size = 6.0
	p.volume_db = -6.0
	platform.add_child(p)
	return p


func _build_shaft() -> void:
	var cols := [Vector2(-1.6, -1.6), Vector2(1.6, -1.6), Vector2(-1.6, 1.65), Vector2(1.6, 1.65)]
	var body := StaticBody3D.new()
	add_child(body)
	for c: Vector2 in cols:
		SliceMaterials.add_box(self, body, Vector3(c.x, (top_height + 3.0) * 0.5, c.y), Vector3(0.2, top_height + 3.0, 0.2), &"structure")
	var beams: Array = []
	var y := 3.5
	while y <= top_height + 2.0:
		beams.append({ "c": Vector3(0, y, -1.6), "s": Vector3(3.2, 0.1, 0.1) })
		beams.append({ "c": Vector3(-1.6, y, 0.02), "s": Vector3(0.1, 0.1, 3.25) })
		beams.append({ "c": Vector3(1.6, y, 0.02), "s": Vector3(0.1, 0.1, 3.25) })
		y += 3.5
	SliceMaterials.add_multimesh(self, beams, &"structure")
	SliceMaterials.add_box(self, null, Vector3(0, top_height + 3.3, 0), Vector3(3.6, 0.6, 3.6), &"structure", false)


func _set_gate(closed: bool) -> void:
	_gate_shape.disabled = not closed
	_gate_mesh.visible = closed


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return
	var rel := player.global_position - platform.global_position
	var on := absf(rel.x) < HALF and absf(rel.z) < HALF and rel.y > -0.3 and rel.y < 1.2
	var at_top := platform.position.y > top_height - 0.01
	var at_bottom := platform.position.y < 0.01
	if _moving:
		var prev_y := platform.position.y
		var y := move_toward(prev_y, _target, lift_speed * delta)
		var dy := y - prev_y
		platform.position.y = y
		platform.force_update_transform()
		if on and absf(dy) > 0.0:
			player.global_position.y = platform.global_position.y + maxf(rel.y, 0.02)
			if player is PlayerController:
				(player as PlayerController).reset_fall_tracking()
		_update_altitude_display()
		if is_equal_approx(y, _target):
			_moving = false
			_motor.stop()
			_clunk.play()
			_needs_exit = true
			_set_gate(_target > 0.0 and not start_at_top) # roof lift keeps west side closed at top
			_update_altitude_display()
		return
	if on and not _needs_exit:
		_on_timer += delta
		if _on_timer >= BOARD_TIME:
			_start(0.0 if at_top else top_height)
		return
	_on_timer = 0.0
	if not on:
		_needs_exit = false
	# Call the lift to the landing the player is waiting at.
	var to_bottom := Vector2(rel.x, rel.z).length() < 4.5
	if at_top and to_bottom and absf(player.global_position.y - global_position.y) < 2.0:
		_start(0.0)
	elif at_bottom and to_bottom and absf(player.global_position.y - (global_position.y + top_height)) < 2.0:
		_start(top_height)


func _start(target: float) -> void:
	_target = target
	_moving = true
	_on_timer = 0.0
	_set_gate(true)
	_clunk.play()
	_motor.play()
	_update_altitude_display()


func _update_altitude_display() -> void:
	if _alt_label == null:
		return
	var alt := int(roundf(base_logical_y + platform.position.y))
	var km_to_crust := float(alt) / 1000.0
	var status := "HOLD"
	if _moving:
		status = "DESCENDING" if _target < platform.position.y else "ASCENDING"
	elif platform.position.y > top_height - 0.1:
		status = "FLOOR 77 HUB"
	elif platform.position.y < 0.1:
		status = "UNDERCROFT 76-B"
	_alt_label.text = "EL-CYL-77  ·  %d M\n%s  ·  CRUST -%.2f KM" % [alt, status, km_to_crust]
