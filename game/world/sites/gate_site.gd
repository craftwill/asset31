class_name GateSite
extends Node3D
## Stack-edge gate plaza. Departure (warm, freight yard, big route sign) or
## arrival (cool lamps on long cables, checkpoint; frame 500s mood).
## Built in gate space: x' = metres inward from the wall's inner face (the
## drop edge is at x' = -wall thickness), z = along the wall.

var _sx := 1.0          # +1 for a gate in the +x wall, -1 for -x
var _wall := 40.0
var _body: StaticBody3D
var _metal: StaticBody3D
var _cool := false


static func build(stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := GateSite.new()
	s._sx = 1.0 if String(stack.def.opening.side) == "+x" else -1.0
	s._wall = float(stack.def.wall_thickness)
	s._cool = site.kind == "gate_arrival"
	s.position = Vector3(s._sx * stack.size_x() * 0.5, 0, 0)
	s._build(stack, site)
	return s


## Gate space -> site local.
func g(xp: float, y: float, z: float) -> Vector3:
	return Vector3(-_sx * xp, y, z)


func _gb(a: Vector3, b: Vector3, mat: StringName, body: StaticBody3D = null) -> MeshInstance3D:
	var pa := g(a.x, a.y, a.z)
	var pb := g(b.x, b.y, b.z)
	return SliceMaterials.add_box(self, body, (pa + pb) * 0.5, (pb - pa).abs(), mat, body != null)


func _build(stack: StackRuntime, site: Dictionary) -> void:
	_body = StaticBody3D.new()
	add_child(_body)
	_metal = StaticBody3D.new()
	_metal.set_meta(&"surface", "metal")
	add_child(_metal)
	var ow := float(stack.def.opening.width) * 0.5
	var oh := float(stack.def.opening.height)
	var bridge_half := 6.0
	var light_mat := &"lamp_cool" if _cool else &"lamp"
	var corona_mat := &"corona_cool" if _cool else &"corona"
	var lcol := SliceMaterials.COOL if _cool else SliceMaterials.WARM

	# Plaza floor and the hazard band at the drop edge.
	_gb(Vector3(0, -0.1, -ow + 10), Vector3(240, 0.03, ow - 10), &"concrete_floor")
	_gb(Vector3(-_wall + 0.5, -0.05, -ow), Vector3(-_wall + 2.5, 0.05, -bridge_half), &"hazard")
	_gb(Vector3(-_wall + 0.5, -0.05, bridge_half), Vector3(-_wall + 2.5, 0.05, ow), &"hazard")

	# Edge railing with a glowing handrail (frame 125s), open at the bridge.
	var posts: Array = []
	for side in [-1.0, 1.0]:
		var za: float = side * bridge_half
		var zb: float = side * ow
		var xr := -_wall + 0.4
		_gb(Vector3(xr - 0.05, 0, minf(za, zb)), Vector3(xr + 0.05, 1.15, maxf(za, zb)), &"structure", _body).visible = false
		_gb(Vector3(xr - 0.04, 1.08, minf(za, zb)), Vector3(xr + 0.04, 1.14, maxf(za, zb)), &"rail_glow")
		_gb(Vector3(xr - 0.03, 0.55, minf(za, zb)), Vector3(xr + 0.03, 0.6, maxf(za, zb)), &"structure")
		var z := minf(za, zb)
		while z <= maxf(za, zb):
			posts.append({ "c": g(xr, 0.54, z), "s": Vector3(0.08, 1.08, 0.08) })
			z += 2.0
	SliceMaterials.add_multimesh(self, posts, &"structure")

	# Gate frame: heavy beams in front of the opening edges and lintel.
	_gb(Vector3(0, 0, -ow), Vector3(12, oh + 12, -ow + 12), &"structure_world", _body)
	_gb(Vector3(0, 0, ow - 12), Vector3(12, oh + 12, ow), &"structure_world", _body)
	_gb(Vector3(0, oh - 12, -ow + 12), Vector3(12, oh + 12, ow - 12), &"structure_world")
	var sign_rot := -_sx * PI * 0.5
	var big_text := "BR-077-A  ·  STK-0413  ·  3.0 KM" if not _cool else "STK-0413  ·  FLOOR 77  ·  WEST ARRIVAL"
	SliceMaterials.add_sign(self, g(12.2, oh - 2.0, 0), big_text, 0.4, Color(1.0, 0.82, 0.5) if not _cool else Color(0.8, 0.9, 1.0), sign_rot)

	# Human-scale route signs at the bridge head.
	for side in [-1.0, 1.0]:
		var zc: float = side * 9.0
		_gb(Vector3(-30.1, 0, zc - 0.08), Vector3(-29.9, 3.2, zc + 0.08), &"structure", _body)
		_gb(Vector3(-30.15, 2.2, zc - 1.1), Vector3(-29.85, 3.0, zc + 1.1), &"structure")
		var txt := ("BR-077-A" if side < 0 else "STK-0413 3.0 KM") if not _cool else ("STK-0412 3.0 KM" if side < 0 else "BR-077-A")
		SliceMaterials.add_sign(self, g(-29.8, 2.6, zc), txt, 0.009, Color(1.0, 0.88, 0.6), sign_rot)

	# Light masts aimed at the bridge head.
	var heads: Array = []
	for side in [-1.0, 1.0]:
		var zc: float = side * 45.0
		_gb(Vector3(59.6, 0, zc - 0.4), Vector3(60.4, 26, zc + 0.4), &"structure", _body)
		_gb(Vector3(58.5, 26, zc - 1.5), Vector3(61.5, 27, zc + 1.5), light_mat)
		heads.append(g(60, 26.3, zc))
		var spot := SpotLight3D.new()
		spot.position = g(60, 25.5, zc)
		spot.light_color = lcol
		spot.light_energy = 7.0
		spot.spot_range = 160.0
		spot.spot_angle = 32.0
		spot.spot_attenuation = 0.8
		spot.light_volumetric_fog_energy = 1.0
		add_child(spot)
		spot.set_meta(&"aim", g(-30, 0, side * 6.0))
	SliceMaterials.add_coronas(self, heads, 7.0, corona_mat)

	# Shelter booth: a stop point before the crossing.
	_gb(Vector3(20, -0.5, -48), Vector3(28, 3.0, -40), &"plate", _metal)
	_gb(Vector3(19.6, 3.0, -48.4), Vector3(28.4, 3.2, -39.6), &"structure")
	_gb(Vector3(19.95, 1.2, -46), Vector3(20.0, 2.2, -42), &"window_glow")
	var booth_light := SliceMaterials.make_lamp_light(lcol, 1.2, 10.0)
	booth_light.position = g(18.5, 2.0, -44)
	add_child(booth_light)

	if _cool:
		_arrival_extras(ow, oh)
	else:
		_departure_extras()


func _ready() -> void:
	for c in get_children():
		if c is SpotLight3D and c.has_meta(&"aim"):
			c.look_at(to_global(c.get_meta(&"aim")), Vector3.UP)


## Freight yard: container stacks and a gantry crane.
func _departure_extras() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4120
	var mats := [&"container_rust", &"container_teal", &"container_grey"]
	for i in 14:
		var xp := 70.0 + (i % 7) * 14.0
		var zc := -200.0 + int(i / 7.0) * 9.0
		var stack_n := rng.randi_range(1, 3)
		for k in stack_n:
			_gb(Vector3(xp, k * 2.6 - (0.5 if k == 0 else 0.0), zc), Vector3(xp + 12.2, (k + 1) * 2.6, zc + 2.45), mats[rng.randi() % 3], _body if k == 0 else null)
	_gb(Vector3(60, 0, -215), Vector3(62, 38, -213), &"structure", _body)
	_gb(Vector3(60, 0, -170), Vector3(62, 38, -168), &"structure", _body)
	_gb(Vector3(160, 0, -215), Vector3(162, 38, -213), &"structure", _body)
	_gb(Vector3(160, 0, -170), Vector3(162, 38, -168), &"structure", _body)
	_gb(Vector3(58, 38, -216), Vector3(164, 41, -212), &"structure")
	_gb(Vector3(58, 38, -171), Vector3(164, 41, -167), &"structure")
	_gb(Vector3(100, 36, -214), Vector3(106, 41, -169), &"container_grey")
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup([{ "p": g(22, 0, -37), "yaw": 0.4 }, { "p": g(-20, 0, 3), "yaw": PI * 0.5 * _sx }],
		[{ "a": g(30, 0, -100), "b": g(140, 0, -120) }], 4121)


## Arrival: hanging lamps on very long cables (500s), checkpoint figures.
func _arrival_extras(ow: float, oh: float) -> void:
	var heads: Array = []
	for i in 7:
		var zc := -150.0 + i * 50.0
		var xp := 30.0 + (i % 2) * 25.0
		var ly := 14.0 + (i % 3) * 4.0
		_gb(Vector3(xp - 0.05, ly + 0.4, zc - 0.05), Vector3(xp + 0.05, oh - 12.0, zc + 0.05), &"structure")
		_gb(Vector3(xp - 1.2, ly, zc - 1.2), Vector3(xp + 1.2, ly + 0.5, zc + 1.2), &"structure")
		_gb(Vector3(xp - 0.9, ly - 0.08, zc - 0.9), Vector3(xp + 0.9, ly, zc + 0.9), &"lamp_cool")
		heads.append(g(xp, ly - 0.3, zc))
		var l := SliceMaterials.make_lamp_light(SliceMaterials.COOL, 3.0, 40.0)
		l.position = g(xp, ly - 1.0, zc)
		l.distance_fade_begin = 500.0
		add_child(l)
	SliceMaterials.add_coronas(self, heads, 4.0, &"corona_cool")
	var statics: Array = []
	for i in 5:
		statics.append({ "p": g(22.0 + i * 1.3, 0, -38.0 + (i % 2) * 1.5), "yaw": -_sx * PI * 0.5 + 0.3 * i })
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(statics, [{ "a": g(10, 0, 40), "b": g(120, 0, 60) }, { "a": g(15, 0, -80), "b": g(90, 0, -20) }], 4131, 0.25)
