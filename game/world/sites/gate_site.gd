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

	# Plaza floor, freight bay staging lane stripes & service conduit covers (non-overlapping heights),
	# plus the hazard band at the drop edge (with opening for Mining Shaft 77-N on departure north side).
	_gb(Vector3(0, -0.1, -ow + 10), Vector3(240, 0.03, ow - 10), &"concrete_floor")
	var plaza_strips: Array = []
	var conduit_covers: Array = []
	for side: float in [-1.0, 1.0]:
		# Restrained lane guide stripes framing the central bridge approach corridor (z = ±11.5 m).
		plaza_strips.append({ "c": g(110.0, 0.038, side * 11.5), "s": Vector3(210.0, 0.016, 0.32) })
		# Low steel service conduit trenches flanking the freight apron (z = ±22 m, outside autopilot path).
		conduit_covers.append({ "c": g(116.0, 0.055, side * 22.0), "s": Vector3(204.0, 0.04, 0.9) })
	# Transverse freight staging bay markings across the inner apron (x' = 45..205 m).
	var bx := 45.0
	while bx <= 205.0:
		for side: float in [-1.0, 1.0]:
			plaza_strips.append({ "c": g(bx, 0.038, side * 44.0), "s": Vector3(0.35, 0.016, 34.0) })
		bx += 32.0
	SliceMaterials.add_multimesh(self, plaza_strips, &"rail_steel")
	SliceMaterials.add_multimesh(self, conduit_covers, &"structure")
	if not _cool:
		_gb(Vector3(-_wall + 0.5, -0.05, -ow), Vector3(-_wall + 2.5, 0.05, -183.0), &"hazard")
		_gb(Vector3(-_wall + 0.5, -0.05, -177.0), Vector3(-_wall + 2.5, 0.05, -bridge_half), &"hazard")
	else:
		_gb(Vector3(-_wall + 0.5, -0.05, -ow), Vector3(-_wall + 2.5, 0.05, -253.0), &"hazard")
		_gb(Vector3(-_wall + 0.5, -0.05, -247.0), Vector3(-_wall + 2.5, 0.05, -bridge_half), &"hazard")
	_gb(Vector3(-_wall + 0.5, -0.05, bridge_half), Vector3(-_wall + 2.5, 0.05, ow), &"hazard")

	# Edge railing with a glowing handrail (frame 125s), open at the bridge, Mining Shaft 77-N spur, and STA-0413-N Express spur.
	var posts: Array = []
	var rail_spans: Array = []
	if not _cool:
		rail_spans = [[-ow, -183.0], [-177.0, -bridge_half], [bridge_half, ow]]
	else:
		rail_spans = [[-ow, -253.0], [-247.0, -bridge_half], [bridge_half, ow]]
	for sp: Array in rail_spans:
		var z0: float = sp[0]
		var z1: float = sp[1]
		var xr := -_wall + 0.4
		_gb(Vector3(xr - 0.05, 0, z0), Vector3(xr + 0.05, 1.15, z1), &"structure", _body).visible = false
		_gb(Vector3(xr - 0.04, 1.08, z0), Vector3(xr + 0.04, 1.14, z1), &"rail_glow")
		_gb(Vector3(xr - 0.03, 0.55, z0), Vector3(xr + 0.03, 0.6, z1), &"structure")
		var z := z0
		while z <= z1:
			posts.append({ "c": g(xr, 0.535, z), "s": Vector3(0.06, 1.07, 0.06) })
			z += 2.0
	SliceMaterials.add_multimesh(self, posts, &"structure")
	# Departure-side sign & bollards marking the walkable catwalk out to Cylindrical Mining Shaft 77-N.
	if not _cool:
		_gb(Vector3(-30.1, 0, -184.5), Vector3(-29.9, 3.3, -184.3), &"structure", _body)
		_gb(Vector3(-30.15, 2.2, -185.7), Vector3(-29.85, 3.1, -183.1), &"structure")
		SliceMaterials.add_sign(self, g(-29.8, 2.65, -184.4), "MINING SHAFT 77-N\nDEEP DESCENT →", 0.009, Color(1.0, 0.86, 0.56), -_sx * PI * 0.5)
		var sh_l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.5, 16.0)
		sh_l.position = g(-32.0, 3.4, -180.0)
		add_child(sh_l)
	else:
		# Arrival-side signpost marking the walkable catwalk spur out to STA-0413-N Inter-Stack Express (EXP-077).
		_gb(Vector3(-30.1, 0, -254.5), Vector3(-29.9, 3.3, -254.3), &"structure", _body)
		_gb(Vector3(-30.15, 2.2, -255.8), Vector3(-29.85, 3.1, -253.0), &"structure")
		SliceMaterials.add_sign(self, g(-29.8, 2.65, -254.4), "← EXP-077 EXPRESS\nSTA-0413-N · STK-0414", 0.0085, Color(0.84, 0.94, 1.0), -_sx * PI * 0.5)
		var ex_l := SliceMaterials.make_lamp_light(SliceMaterials.COOL, 1.6, 18.0)
		ex_l.position = g(-32.0, 3.4, -250.0)
		add_child(ex_l)

	# Gate frame: heavy beams in front of the opening edges and lintel.
	_gb(Vector3(0, 0, -ow), Vector3(12, oh + 12, -ow + 12), &"structure_world", _body)
	_gb(Vector3(0, 0, ow - 12), Vector3(12, oh + 12, ow), &"structure_world", _body)
	_gb(Vector3(0, oh - 12, -ow + 12), Vector3(12, oh + 12, ow - 12), &"structure_world")
	var sign_rot := -_sx * PI * 0.5
	var big_text := "BR-077-A  ·  STK-0413  ·  3.0 KM" if not _cool else "STK-0413  ·  FLOOR 77  ·  WEST ARRIVAL"
	SliceMaterials.add_sign(self, g(12.2, oh - 2.0, 0), big_text, 0.4, Color(1.0, 0.82, 0.5) if not _cool else Color(0.8, 0.9, 1.0), sign_rot)
	# Sacred Continuum architectural emblem mounted on both flanks of the monumental gate lintel
	# (honoring the unbroken 3 km bond between STK-0412 and STK-0413).
	for e_side: float in [-1.0, 1.0]:
		var g_emb := ContinuumEmblem.create(3.6, &"copper", &"structure", false)
		g_emb.position = g(12.6, 18.0, e_side * (ow - 6.0))
		g_emb.rotation.y = sign_rot
		add_child(g_emb)

	# Human-scale route signs at the bridge head, with localized sign lighting.
	var sign_glows: Array = []
	for side in [-1.0, 1.0]:
		var zc: float = side * 9.0
		_gb(Vector3(-30.1, 0, zc - 0.08), Vector3(-29.9, 3.2, zc + 0.08), &"structure", _body)
		_gb(Vector3(-30.15, 2.2, zc - 1.1), Vector3(-29.85, 3.0, zc + 1.1), &"structure")
		_gb(Vector3(-29.7, 3.15, zc - 0.25), Vector3(-29.4, 3.28, zc + 0.25), light_mat)
		sign_glows.append(g(-29.55, 3.12, zc))
		var sl := SliceMaterials.make_lamp_light(lcol, 1.1, 9.0)
		sl.position = g(-29.1, 2.9, zc)
		add_child(sl)
		var txt := ("BR-077-A" if side < 0 else "STK-0413 3.0 KM") if not _cool else ("STK-0412 3.0 KM" if side < 0 else "BR-077-A")
		SliceMaterials.add_sign(self, g(-29.8, 2.6, zc), txt, 0.009, Color(1.0, 0.88, 0.6), sign_rot)

	# Restrained threshold bollards through the 40 m wall passage onto the bridge
	# so the transition from dark plaza to bridge head reads cleanly.
	var bollards: Array = []
	var b_caps: Array = []
	for xp in [8.0, -6.0, -20.0, -34.0]:
		for side in [-1.0, 1.0]:
			var zb: float = side * (bridge_half + 1.1)
			bollards.append({ "c": g(xp, 0.55, zb), "s": Vector3(0.28, 1.1, 0.28) })
			b_caps.append({ "c": g(xp, 1.17, zb), "s": Vector3(0.22, 0.14, 0.22) })
			sign_glows.append(g(xp, 1.2, zb))
			var bl := SliceMaterials.make_lamp_light(lcol, 1.05, 13.0)
			bl.position = g(xp, 1.45, side * (bridge_half - 0.4))
			add_child(bl)
	SliceMaterials.add_multimesh(self, bollards, &"structure")
	SliceMaterials.add_multimesh(self, b_caps, light_mat)
	SliceMaterials.add_coronas(self, sign_glows, 1.4, corona_mat)

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
		# Subtle inner-plaza ground pool so the dark plaza reads at the gate approach.
		var pl := SliceMaterials.make_lamp_light(lcol, 1.8, 34.0)
		pl.position = g(24.0, 7.5, side * 20.0)
		add_child(pl)
	SliceMaterials.add_coronas(self, heads, 7.0, corona_mat)

	# Enterable shelter booth: open doorway on the plaza-facing wall (x' = 20, z = -45.5..-44.1),
	# riveted plate walls, wood floor (y = 0.07 above plaza 0.03), bench, warm interior lamp, and persistent supply cache inside.
	_gb(Vector3(20.1, -0.05, -47.9), Vector3(27.9, 0.07, -40.1), &"floor_wood", _metal)
	_gb(Vector3(19.6, 3.0, -48.4), Vector3(28.4, 3.25, -39.6), &"structure", _body)
	# Back (x'=28), north (z=-48), south (z=-40) walls.
	_gb(Vector3(27.7, 0.0, -48.0), Vector3(28.0, 3.0, -40.0), &"plate", _metal)
	_gb(Vector3(20.0, 0.0, -48.0), Vector3(27.7, 3.0, -47.7), &"plate", _metal)
	_gb(Vector3(20.0, 0.0, -40.3), Vector3(27.7, 3.0, -40.0), &"plate", _metal)
	# Front wall (x'=20..20.3) split around doorway z in [-45.5, -44.1] (height 2.25 m).
	_gb(Vector3(20.0, 0.0, -47.7), Vector3(20.3, 3.0, -45.5), &"plate", _metal)
	_gb(Vector3(20.0, 0.0, -44.1), Vector3(20.3, 3.0, -40.3), &"plate", _metal)
	_gb(Vector3(20.0, 2.25, -45.5), Vector3(20.3, 3.0, -44.1), &"plate", _metal)
	# Interior bench + exterior crates + interior hanging lamp.
	_gb(Vector3(25.2, 0.04, -47.5), Vector3(27.4, 0.52, -46.8), &"wood", _body)
	_gb(Vector3(18.7, 0.03, -41.4), Vector3(19.8, 0.9, -40.3), &"container_rust", _body)
	_gb(Vector3(18.9, 0.9, -41.2), Vector3(19.6, 1.5, -40.5), &"container_grey")
	_gb(Vector3(23.8, 2.78, -44.0), Vector3(24.2, 2.95, -43.6), light_mat)
	var booth_light := SliceMaterials.make_lamp_light(lcol, 1.5, 11.0)
	booth_light.position = g(24.0, 2.6, -43.8)
	add_child(booth_light)
	var door_lamp := SliceMaterials.make_lamp_light(lcol, 1.1, 8.0)
	door_lamp.position = g(19.2, 2.5, -44.8)
	add_child(door_lamp)
	# Lootable expedition staging / arrival cache tucked inside the shelter booth.
	if not _cool:
		add_child(LootContainer.create(
			"CONT-GATE-SHELTER", "Gate Shelter Cache", "crate",
			g(26.8, 0.04, -41.4), sign_rot,
			[["ration_tin", 2], ["water_flask", 1], ["bandage_roll", 1], ["fuse_cell", 1]], 5, 4))
	else:
		add_child(LootContainer.create(
			"CONT-ARRIVAL-CACHE", "Arrival Locker", "locker",
			g(26.8, 0.04, -41.4), sign_rot,
			[["water_flask", 2], ["salvaged_relay", 1], ["fuse_cell", 1]], 5, 4))

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
	_gb(Vector3(100, 35.5, -214), Vector3(106, 39.8, -169), &"container_grey")
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
	# Arrival checkpoint service kiosk beside the west arrival shelter.
	_gb(Vector3(19.2, 0.03, -36.8), Vector3(20.1, 2.2, -35.6), &"container_grey", _body)
	_gb(Vector3(19.16, 1.25, -36.55), Vector3(19.2, 1.75, -35.85), &"sign_cyan")
	# Diegetic directional signpost guiding explorers south to the Misty Glass Observation Terrace (400s).
	_gb(Vector3(145.0, 0.0, 96.0), Vector3(145.3, 3.6, 96.3), &"structure", _body)
	_gb(Vector3(144.95, 2.5, 93.8), Vector3(145.35, 3.5, 98.4), &"structure")
	SliceMaterials.add_sign(self, g(144.9, 3.0, 96.1), "GLASS CURTAIN SECTOR 413-S\nOBSERVATION TERRACE  ↓", 0.0085, Color(0.84, 0.94, 1.0), -_sx * PI * 0.5)
	var tl := SliceMaterials.make_lamp_light(SliceMaterials.COOL, 1.3, 12.0)
	tl.position = g(144.2, 3.3, 96.1)
	add_child(tl)
	# Matching north-bound directional signpost guiding explorers toward Hydroponics, Preserve & EXP-077 Express.
	_gb(Vector3(145.0, 0.0, -96.0), Vector3(145.3, 3.6, -96.3), &"structure", _body)
	_gb(Vector3(144.95, 2.5, -98.4), Vector3(145.35, 3.5, -93.8), &"structure")
	SliceMaterials.add_sign(self, g(144.9, 3.0, -96.1), "↑ EXP-077 INTER-STACK EXPRESS (NORTH)\n→ RESIDENTIAL BLOCKS  ·  GLASS TERRACE 413-S", 0.0082, Color(0.84, 0.94, 1.0), -_sx * PI * 0.5)
	var nl := SliceMaterials.make_lamp_light(SliceMaterials.COOL, 1.3, 12.0)
	nl.position = g(144.2, 3.3, -96.1)
	add_child(nl)
