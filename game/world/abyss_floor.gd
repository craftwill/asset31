class_name AbyssFloor
extends WorldAnchor
## What lies beneath the stacks, seen from every gap, bridge and open edge
## (reference 612s-620s): a brown haze floor 3.2 km below Floor 77 sown with small
## lights, dark towers standing up out of it, and now and then a stroke of lightning
## inside the haze. Purely scenery: nothing here is reachable.

const FLOOR_SHADER := preload("res://shaders/abyss_floor.gdshader")
const BOLT_SHADER := preload("res://shaders/lightning.gdshader")
const DEPTH := 3200.0            # below Floor 77
const SPAN := 90000.0
const CELL := 520.0

var _bolt: MeshInstance3D
var _bolt_mat: ShaderMaterial
var _bolt_t := -1.0
var _next := 6.0
var _rng := RandomNumberGenerator.new()
var _forced_yaw := 1000.0
var _hold := false   # test hook (--bolt-hold): keep a stroke lit so it can be captured


static func build(world_def: Dictionary) -> AbyssFloor:
	var a := AbyssFloor.new()
	a.name = "AbyssFloor"
	a.lx = 5000.0
	a.ly = 41000.0 - DEPTH
	a.lz = 0.0
	a._build(world_def)
	return a


func _build(world_def: Dictionary) -> void:
	_rng.seed = 77031
	_hold = OS.get_cmdline_user_args().has("--bolt-hold")
	if _hold:
		_next = 0.2
	var mat := ShaderMaterial.new()
	mat.shader = FLOOR_SHADER
	# The 41 km lift shaft passes down through the floor; keep its lit interior clear.
	mat.set_shader_parameter(&"hole", Vector3(3260.0, -180.0, 175.0))
	var plane := SliceMaterials.add_box(self, null, Vector3(0, -1.0, 0), Vector3(SPAN, 2.0, SPAN), &"structure", false)
	plane.material_override = mat
	plane.extra_cull_margin = 1000.0

	# Footprints nothing may stand in: the stacks themselves (they reach far lower).
	var keep_out: Array[Rect2] = []
	for sd: Dictionary in world_def.stacks:
		var o: Array = sd.origin
		var s: Array = sd.size
		keep_out.append(Rect2(float(o[0]) - float(s[0]) * 0.5 - 400.0, float(o[2]) - float(s[2]) * 0.5 - 400.0, float(s[0]) + 800.0, float(s[2]) + 800.0))
	for st: Dictionary in world_def.get("structures", []):
		if st.kind == "distant_stack":
			var p: Array = st.position
			keep_out.append(Rect2(float(p[0]) - float(st.width) * 0.5 - 400.0, float(p[2]) - float(st.depth) * 0.5 - 400.0, float(st.width) + 800.0, float(st.depth) + 800.0))
	keep_out.append(Rect2(3260.0 - 420.0, -180.0 - 420.0, 840.0, 840.0))

	# Dark towers rising out of the haze, a few very tall.
	var towers: Array = []
	var n := int(SPAN / CELL)
	for i in n:
		for j in n:
			var r_on := _rng.randf()
			var px := -SPAN * 0.5 + (float(i) + _rng.randf_range(0.2, 0.8)) * CELL
			var pz := -SPAN * 0.5 + (float(j) + _rng.randf_range(0.2, 0.8)) * CELL
			var w := _rng.randf_range(40.0, 150.0)
			var d := _rng.randf_range(40.0, 150.0)
			var h := 180.0 + pow(_rng.randf(), 3.0) * 2300.0
			var seed := _rng.randf() * 0.9
			if r_on > 0.2:
				continue
			var lp := Vector2(lx + px, lz + pz)
			var blocked := false
			for r: Rect2 in keep_out:
				if r.has_point(lp):
					blocked = true
					break
			if blocked:
				continue
			towers.append({ "c": Vector3(px, h * 0.5 - 60.0, pz), "s": Vector3(w, h + 120.0, d), "seed": seed })
			if h > 900.0 and _rng.randf() < 0.6:
				# Stepped crown on the tall ones.
				towers.append({ "c": Vector3(px, h + 90.0, pz), "s": Vector3(w * 0.5, 300.0, d * 0.5), "seed": seed })
	var city := Node3D.new()
	city.name = "City"   # procedural scenery: same lint treatment as the stack cities
	add_child(city)
	SliceMaterials.add_multimesh(city, towers, &"abyss_tower")

	_bolt_mat = ShaderMaterial.new()
	_bolt_mat.shader = BOLT_SHADER
	_bolt = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(700.0, 900.0)
	_bolt.mesh = q
	_bolt.material_override = _bolt_mat
	_bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bolt.extra_cull_margin = 400.0
	_bolt.visible = false
	add_child(_bolt)


## Makes the next stroke land in `delay` seconds, `yaw_deg` degrees round from north
## as seen from the camera (0 = -z), a few kilometres out. Used by the showcase video.
func strike_soon(delay: float, yaw_deg: float) -> void:
	_next = delay
	_forced_yaw = deg_to_rad(yaw_deg)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# Nothing to see from beneath it (the 41 km descent, the crust).
	visible = cam.global_position.y > global_position.y + 60.0
	if not visible:
		return
	if _bolt_t >= 0.0:
		_bolt_t += delta
		# Two or three quick pulses, then gone.
		var k := maxf(0.0, 1.0 - _bolt_t / 0.42)
		var flick := 0.35 + 0.65 * absf(sin(_bolt_t * 46.0))
		_bolt_mat.set_shader_parameter(&"intensity", k * flick)
		if _hold:
			# Keep it out in front (south) of wherever the test camera is now.
			var hl := to_local(cam.global_position)
			_bolt.position = Vector3(hl.x - 900.0, 310.0, hl.z + 4600.0)
			_bolt.look_at(cam.global_position, Vector3.UP)
			_bolt_mat.set_shader_parameter(&"intensity", 1.0)
			return
		if _bolt_t > 0.42:
			_bolt_t = -1.0
			_bolt.visible = false
		return
	_next -= delta
	if _next > 0.0:
		return
	_next = _rng.randf_range(3.5, 13.0)
	# Strike somewhere in the haze within a few kilometres, upright, facing the viewer.
	var ang := _rng.randf_range(0.0, TAU)
	var dist := _rng.randf_range(900.0, 5200.0)
	if _forced_yaw < 100.0:
		# Out in front of a viewer facing that way, clear of the floor edge.
		ang = atan2(-cos(_forced_yaw), -sin(_forced_yaw)) + 0.12
		dist = 5200.0
		_forced_yaw = 1000.0
	if _hold:
		ang = PI * 0.5
		dist = 2600.0
	var local := to_local(cam.global_position)
	var p := Vector3(local.x + cos(ang) * dist, 310.0, local.z + sin(ang) * dist)
	_bolt.position = p
	# Turned fully toward the viewer (they are far above it), like a sprite.
	_bolt.look_at(cam.global_position, Vector3.UP)
	_bolt_mat.set_shader_parameter(&"seed", _rng.randf() * 100.0)
	_bolt_t = 0.0
	_bolt.visible = true
