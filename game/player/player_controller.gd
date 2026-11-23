class_name PlayerController
extends CharacterBody3D
## Grounded first-person controller. Lives in render space at the scene root;
## WorldOrigin moves it back toward 0,0,0 when it rebases.

signal fatal_fall(height: float)
signal hard_landing(height: float)
signal footstep(surface: String)

@export var walk_speed := 1.8
@export var sprint_speed := 4.6
@export var crouch_speed := 0.9
@export var ground_accel := 10.0
@export var ground_decel := 14.0
@export var air_accel := 1.2
@export var jump_velocity := 3.4
@export var mouse_sensitivity := 0.0022
@export var stand_height := 1.8
@export var crouch_height := 1.15
@export var eye_below_top := 0.12
@export var radius := 0.3
@export var fatal_fall_height := 60.0

var head: Node3D
var camera: Camera3D
var work_lamp: SpotLight3D

## Dev/test only: when set, drives the player in this render-space direction.
var autopilot_dir := Vector3.ZERO
var speed_override := 0.0
var input_enabled := true
var riding_transport := false

var _pitch := 0.0
var _shape: CapsuleShape3D
var _col: CollisionShape3D
var _crouched := false
var _eye_height := 0.0
var _bob := 0.0
var _gravity := 9.81
var _air_top_y := 0.0
var _was_on_floor := true
var last_safe_logical := PackedFloat64Array()
var _safe_timer := 0.0
var _stride := 0.0
var floor_surface := "stone"


func _ready() -> void:
	_gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	_shape = CapsuleShape3D.new()
	_shape.radius = radius
	_shape.height = stand_height
	_col = CollisionShape3D.new()
	_col.shape = _shape
	_col.position.y = stand_height * 0.5
	add_child(_col)
	head = Node3D.new()
	head.name = "Head"
	add_child(head)
	camera = Camera3D.new()
	camera.near = 0.12
	camera.far = 48000.0
	camera.fov = 74.0
	head.add_child(camera)
	camera.current = true
	# Restrained handheld tungsten work-lamp (off by default, toggle with F).
	work_lamp = SpotLight3D.new()
	work_lamp.position = Vector3(0.18, -0.14, -0.15)
	work_lamp.light_color = Color(1.0, 0.78, 0.52)
	work_lamp.light_energy = 1.6
	work_lamp.spot_range = 20.0
	work_lamp.spot_angle = 26.0
	work_lamp.spot_attenuation = 1.15
	work_lamp.shadow_enabled = false
	work_lamp.visible = false
	head.add_child(work_lamp)
	_eye_height = stand_height - eye_below_top
	head.position.y = _eye_height
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.45
	WorldOrigin.origin_shifted.connect(_on_origin_shifted)
	_air_top_y = position.y


func set_look(yaw: float, pitch: float) -> void:
	rotation.y = yaw
	_pitch = clampf(pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
	head.rotation.x = _pitch


func get_pitch() -> float:
	return _pitch


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var m := event as InputEventMouseMotion
		rotation.y -= m.relative.x * mouse_sensitivity
		set_look(rotation.y, _pitch - m.relative.y * mouse_sensitivity)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if riding_transport:
		velocity = Vector3.ZERO
		_update_head(delta, 0.0)
		reset_fall_tracking()
		return
	var wish := Vector3.ZERO
	var sprinting := false
	if autopilot_dir != Vector3.ZERO:
		wish = Vector3(autopilot_dir.x, 0, autopilot_dir.z).normalized()
	elif input_enabled:
		var iv := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		wish = transform.basis * Vector3(iv.x, 0, iv.y)
		wish.y = 0.0
		wish = wish.normalized() * minf(iv.length(), 1.0)
		sprinting = Input.is_action_pressed(&"sprint")
		_update_crouch(Input.is_action_pressed(&"crouch"))

	var speed := walk_speed
	if _crouched:
		speed = crouch_speed
	elif sprinting:
		speed = sprint_speed
	if speed_override > 0.0:
		speed = speed_override

	var on_floor := is_on_floor()
	var hv := Vector3(velocity.x, 0, velocity.z)
	var target := wish * speed
	var rate := air_accel
	if on_floor:
		rate = ground_accel if target.length() >= hv.length() else ground_decel
	hv = hv.lerp(target, 1.0 - exp(-rate * delta))
	velocity.x = hv.x
	velocity.z = hv.z

	if on_floor:
		if input_enabled and autopilot_dir == Vector3.ZERO and Input.is_action_just_pressed(&"jump") and not _crouched:
			velocity.y = jump_velocity
	else:
		velocity.y -= _gravity * delta

	move_and_slide()
	_footsteps(delta)
	_track_falls(delta)
	_update_head(delta, hv.length())


func _update_crouch(want: bool) -> void:
	if want == _crouched:
		return
	if not want:
		# Only stand up if there is headroom.
		var lift := Vector3.UP * (stand_height - crouch_height)
		if test_move(global_transform, lift):
			return
	_crouched = want
	var hgt := crouch_height if _crouched else stand_height
	_shape.height = hgt
	_col.position.y = hgt * 0.5
	_eye_height = hgt - eye_below_top


func _update_head(delta: float, hspeed: float) -> void:
	var amp := 0.0
	if is_on_floor() and hspeed > 0.3:
		_bob += delta * hspeed * 1.9
		amp = clampf(hspeed / sprint_speed, 0.0, 1.0) * 0.03
	var target_y := _eye_height + sin(_bob * 2.0) * amp
	head.position.y = lerpf(head.position.y, target_y, 1.0 - exp(-14.0 * delta))


func _track_falls(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		if not _was_on_floor:
			var fall := _air_top_y - position.y
			if fall > fatal_fall_height:
				fatal_fall.emit(fall)
			elif fall > 5.0:
				hard_landing.emit(fall)
		_air_top_y = position.y
		_safe_timer -= delta
		if _safe_timer <= 0.0:
			_safe_timer = 1.0
			last_safe_logical = WorldOrigin.to_logical(position)
	else:
		_air_top_y = maxf(_air_top_y, position.y)
		if _air_top_y - position.y > fatal_fall_height * 4.0:
			# Falling into the void between stacks: no floor for kilometres.
			fatal_fall.emit(_air_top_y - position.y)
			_air_top_y = position.y
	_was_on_floor = on_floor


func _on_origin_shifted(delta: Vector3) -> void:
	_air_top_y -= delta.y


## Called by high-speed vertical transports (e.g. 41 km DeepRelayLift) while the
## player is carried inside the cage so extreme vertical drops never trigger a false fall.
func reset_fall_tracking() -> void:
	_air_top_y = position.y
	_was_on_floor = true


func _footsteps(delta: float) -> void:
	if not is_on_floor():
		_stride = 0.0
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y > 0.7:
			var col := c.get_collider()
			if col != null:
				floor_surface = String(col.get_meta(&"surface", "stone"))
			break
	var hs := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	if hs < 0.4:
		return
	_stride += hs * delta
	var stride_len := 0.75 if hs < 3.0 else 1.05
	if _crouched:
		stride_len = 0.55
	if _stride >= stride_len:
		_stride = 0.0
		footstep.emit(floor_surface)
