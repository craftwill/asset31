class_name SquatWatcher
extends Node3D
## One squatter who notices the player. No combat, no speech, no pursuit: when the
## player comes near they stop and turn to look; one with a flashlight raises it onto
## the player for a few seconds, then lowers it and goes back to what they were doing.
## Rare by design (long cooldown), so it reads as being noticed, not as a system.

const NOTICE := 26.0       # metres
const FORGET := 36.0
const HOLD := 4.2          # seconds the light stays on the player
const COOLDOWN := 75.0

var has_light := false
var home_yaw := 0.0
var dark := 0.5

var _mm: MultiMesh
var _yaw := 0.0
var _seed := 0.3
var _lamp: SpotLight3D
var _state := 0            # 0 at work, 1 watching, 2 lowering the light
var _t := 0.0
var _cool := 0.0


static func create(pos: Vector3, yaw: float, with_light: bool, seed := 0.3) -> SquatWatcher:
	var w := SquatWatcher.new()
	w.position = pos
	w.home_yaw = yaw
	w._yaw = yaw
	w.has_light = with_light
	w._seed = seed
	return w


func _ready() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = Crowd.figure_mesh()
	_mm.instance_count = 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = SliceMaterials.get_mat(&"figure")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 260.0
	add_child(mmi)
	_mm.set_instance_custom_data(0, Color(_seed, 0.0, dark, 0.0))
	if has_light:
		_lamp = SpotLight3D.new()
		_lamp.position = Vector3(0.3, 1.25, 0.0)
		_lamp.light_color = Color(0.92, 0.96, 1.0)
		_lamp.light_energy = 0.0
		_lamp.spot_range = 46.0
		_lamp.spot_angle = 13.0
		_lamp.spot_attenuation = 0.8
		_lamp.shadow_enabled = false
		_lamp.light_volumetric_fog_energy = 5.0
		add_child(_lamp)
	_apply()


func _apply() -> void:
	_mm.set_instance_transform(0, Transform3D(Basis(Vector3.UP, _yaw), Vector3.ZERO))


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return
	var to := player.global_position - global_position
	var dist := Vector2(to.x, to.z).length()
	if absf(to.y) > 6.0:
		dist = 1000.0
	_cool = maxf(0.0, _cool - delta)
	var want := home_yaw
	match _state:
		0:
			if dist < NOTICE and _cool <= 0.0:
				_state = 1
				_t = 0.0
		1:
			_t += delta
			want = atan2(-to.x, -to.z)
			if _lamp != null:
				# Raise the light after a beat, hold it on the player with a little lag.
				var k := clampf((_t - 0.9) / 0.7, 0.0, 1.0)
				_lamp.light_energy = lerpf(_lamp.light_energy, 5.5 * k, clampf(delta * 6.0, 0.0, 1.0))
				var aim := player.global_position + Vector3(0, 1.3, 0)
				var cur := _lamp.global_position - _lamp.global_basis.z * 10.0
				_lamp.look_at(cur.lerp(aim, clampf(delta * 2.2, 0.0, 1.0)), Vector3.UP)
			if _t > HOLD + 1.6 or dist > FORGET:
				_state = 2
				_t = 0.0
		2:
			_t += delta
			if _lamp != null:
				# The beam drops to the ground and goes out.
				_lamp.light_energy = lerpf(_lamp.light_energy, 0.0, clampf(delta * 2.5, 0.0, 1.0))
				_lamp.rotate_object_local(Vector3.RIGHT, -delta * 0.5)
			if _t > 1.6:
				if _lamp != null:
					_lamp.light_energy = 0.0
				_state = 0
				_cool = COOLDOWN
	_yaw = lerp_angle(_yaw, want, clampf(delta * (2.0 if _state == 1 else 0.9), 0.0, 1.0))
	_apply()
