class_name FrozenFloor
extends SiteKit
## The top floor of STK-0413, 18.1 km above Floor 77, reached by the brink lift
## EL-0413-S. Nothing up here was ever heated: a 6 km plate of ice under a white-out,
## dead stubs of buildings crusted in frost, drifts, and one line of marker posts.
## The line runs 3 km north from the lift and then west to the only warm place on the
## level: Hydroponic Bay 413-A and the Preserve behind it (built by StackRuntime at
## this height). Two heated huts break the walk.
## Local coordinates are stack-local x/z with y = 0 at the ice.

const LIFT := Vector2(-1368.0, 3004.0)      # cage centre, beyond the open south edge
const PATH_X := -1375.0
const TURN_Z := -40.0
const DOOR := Vector2(-2827.0, -100.0)      # Hydroponic Bay south archway
const HUTS: Array[Vector2] = [Vector2(-1364.0, 1520.0), Vector2(-1392.0, -52.0)]


static func build(st: Dictionary, stack_def: Dictionary) -> WorldAnchor:
	var anchor := WorldAnchor.new()
	anchor.name = String(st.id)
	anchor.lx = float(stack_def.origin[0])
	anchor.ly = float(stack_def.origin[1]) + float(st.level)
	anchor.lz = float(stack_def.origin[2])
	var f := FrozenFloor.new()
	f.name = "FrozenPlate"
	anchor.add_child(f)
	f._build(float(stack_def.size[0]), float(stack_def.size[2]))
	return anchor


func _build(w: float, d: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41399
	# The plate: one collision slab, ice tiles on top.
	SliceMaterials.add_collision_box(_body, Vector3(0, -30.0, 0), Vector3(w, 60.0, d))
	var tiles: Array = []
	var n := int(w / 500.0)
	for i in n:
		for j in int(d / 500.0):
			tiles.append({ "c": Vector3(-w * 0.5 + (float(i) + 0.5) * 500.0, -30.0, -d * 0.5 + (float(j) + 0.5) * 500.0), "s": Vector3(500.0, 60.0, 500.0) })
	# Named like the stack's own ground so the coplanar-face lint treats it the same.
	var ground := Node3D.new()
	ground.name = "City"
	add_child(ground)
	SliceMaterials.add_multimesh(ground, tiles, &"ground_ice")
	_landing()
	_markers(rng)
	for i in HUTS.size():
		_hut(HUTS[i], i, rng)
	_wrecks(w, d, rng)
	SliceMaterials.add_sign(self, Vector3(DOOR.x, 3.4, DOOR.y + 40.0), "HYDROPONIC BAY 413-A  ·  WARM  ↑", 0.016, Color(0.2, 0.34, 0.26), 0.0)
	box(Vector3(DOOR.x - 5.2, 2.6, DOOR.y + 39.9), Vector3(DOOR.x + 5.2, 4.2, DOOR.y + 39.98), &"container_grey")
	for sp: float in [DOOR.x - 4.8, DOOR.x + 4.8]:
		box(Vector3(sp - 0.08, 0.0, DOOR.y + 39.8), Vector3(sp + 0.08, 4.2, DOOR.y + 39.9), &"structure", true)
	flush()


## Top landing of the brink lift: a pier out over the void, like the one below.
func _landing() -> void:
	var x0 := LIFT.x - 10.0
	var x1 := LIFT.x - 2.1
	box(Vector3(x0, -0.6, 2996.0), Vector3(x1, 0.03, LIFT.y + 3.0), &"plate", true, true)
	box(Vector3(x0, 0.0, LIFT.y + 2.9), Vector3(x1, 1.1, LIFT.y + 3.0), &"structure", true)
	box(Vector3(x0, 0.0, 3000.2), Vector3(x0 + 0.1, 1.1, LIFT.y + 2.9), &"structure", true)
	lamp_post(Vector3(x0 + 1.0, 0.0, 2994.0), 5.0, SliceMaterials.COOL, &"lamp_cool", 2.4, 22.0)
	box(Vector3(x0 + 1.6, 1.5, 2993.0), Vector3(x0 + 6.4, 2.7, 2993.08), &"container_grey")
	for sp: float in [x0 + 1.9, x0 + 6.1]:
		box(Vector3(sp - 0.05, 0.0, 2993.08), Vector3(sp + 0.05, 2.7, 2993.16), &"structure", true)
	SliceMaterials.add_sign(self, Vector3(x0 + 4.0, 2.1, 2992.99), "TOP FLOOR  ·  UNHEATED\nFOLLOW THE POSTS", 0.0095, Color(0.16, 0.2, 0.26), PI)


## The line of posts: north from the lift, then west to the bay. Some still burn.
func _markers(rng: RandomNumberGenerator) -> void:
	var pts: Array[Vector2] = []
	var z := 2960.0
	while z > TURN_Z:
		pts.append(Vector2(PATH_X, z))
		z -= 50.0
	var x := PATH_X
	while x > DOOR.x:
		pts.append(Vector2(x, TURN_Z))
		x -= 50.0
	pts.append(Vector2(DOOR.x, TURN_Z))
	for i in pts.size():
		var p := Vector3(pts[i].x + (3.0 if i % 2 == 0 else -3.0), 0.0, pts[i].y)
		var lean := Vector3(rng.randf_range(-0.05, 0.05), 0.0, rng.randf_range(-0.05, 0.05))
		rbox(p + Vector3(0, 2.2, 0), Vector3(0.16, 4.4, 0.16), lean, &"structure", true)
		box(p + Vector3(-0.3, -0.02 - 0.003 * float(i % 9), -0.3), p + Vector3(0.3, 0.35, 0.3), &"ice")
		if rng.randf() < 0.62:
			light(p + Vector3(0, 4.5, 0), Color(0.6, 0.92, 1.0), 1.5, 15.0, &"sign_cyan", 0.36)
			glow(p + Vector3(0, 4.5, 0), &"corona_cool")
		else:
			box(p + Vector3(-0.18, 4.4, -0.18), p + Vector3(0.18, 4.56, 0.18), &"structure")


## Heated hut: the only shelter between the lift and the bay.
func _hut(at: Vector2, index: int, rng: RandomNumberGenerator) -> void:
	var o := Vector3(at.x, 0.0, at.y)
	var hw := 2.6
	var hd := 2.1
	box(o + Vector3(-hw + 0.1, -0.03, -hd + 0.1), o + Vector3(hw - 0.1, 0.08, hd - 0.1), &"plate", true, true)
	box(o + Vector3(-hw, -0.08, -hd), o + Vector3(hw, 2.7, -hd + 0.2), &"container_grey", true, true)
	box(o + Vector3(-hw, -0.08, hd - 0.2), o + Vector3(hw, 2.7, hd), &"container_grey", true, true)
	box(o + Vector3(hw - 0.2, -0.08, -hd + 0.2), o + Vector3(hw, 2.7, hd - 0.2), &"container_grey", true, true)
	# Door wall faces the path (west side), with a 1.2 m opening.
	box(o + Vector3(-hw, -0.08, -hd + 0.2), o + Vector3(-hw + 0.2, 2.7, -0.6), &"container_grey", true, true)
	box(o + Vector3(-hw, -0.08, 0.6), o + Vector3(-hw + 0.2, 2.7, hd - 0.2), &"container_grey", true, true)
	box(o + Vector3(-hw, 2.1, -0.6), o + Vector3(-hw + 0.2, 2.7, 0.6), &"container_grey", true, true)
	box(o + Vector3(-hw - 0.15, 2.7, -hd - 0.15), o + Vector3(hw + 0.15, 2.9, hd + 0.15), &"structure", true)
	box(o + Vector3(-hw - 0.3, 2.9, -hd - 0.3), o + Vector3(hw + 0.3, 3.25, hd + 0.3), &"ice")
	# Heater, bench, a lamp over the door.
	box(o + Vector3(hw - 1.0, 0.08, -0.4), o + Vector3(hw - 0.3, 0.9, 0.4), &"container_rust", true)
	box(o + Vector3(hw - 1.04, 0.3, -0.3), o + Vector3(hw - 1.0, 0.7, 0.3), &"drill_glow")
	var heat := SliceMaterials.make_lamp_light(Color(1.0, 0.55, 0.22), 2.0, 9.0)
	heat.position = o + Vector3(hw - 1.4, 1.0, 0.0)
	add_child(heat)
	box(o + Vector3(-1.6, 0.42, hd - 0.75), o + Vector3(1.2, 0.5, hd - 0.25), &"wood", true)
	box(o + Vector3(-hw - 0.3, 2.3, -0.18), o + Vector3(-hw - 0.05, 2.45, 0.18), &"lamp")
	glow(o + Vector3(-hw - 0.3, 2.35, 0.0), &"corona")
	if index == 0:
		add_child(LootContainer.create(
			"CONT-0413-TOP-HUT", "Way-Hut Locker", "locker",
			o + Vector3(-1.2, 0.08, -hd + 0.5), 0.0,
			[["ration_tin", 2], ["water_flask", 1], ["bandage_roll", 1]], 5, 4))
		add_child(ReadableNote.create(
			"NOTE-0413-TOP", "Way-Hut Log",
			"TOP FLOOR, STK-0413 — UNHEATED\n\n"
			+ "The heating was planned for the year the south side would be closed.\n"
			+ "Neither happened. The bay crew keep the posts lit as far as they can reach.\n\n"
			+ "North to the corner post, then west. You will see green before you feel warm.\n"
			+ "Do not stop between huts.",
			o + Vector3(hw - 0.22, 1.5, 1.1), -PI * 0.5))
	for k in 2 + rng.randi() % 3:
		var cs := rng.randf_range(0.4, 0.7)
		var cp := o + Vector3(-hw - 1.2 - float(k) * 0.9, 0.0, hd - 1.0)
		box(cp + Vector3(0, -0.02 - 0.01 * float(k), 0), cp + Vector3(cs, cs, cs), &"ice", true)


## Frost-crusted stubs, ice blocks and drifts, dense near the path, thin elsewhere.
func _wrecks(w: float, d: float, rng: RandomNumberGenerator) -> void:
	for k in 900:
		var near := k < 620
		var p: Vector2
		if near:
			# Along the L-shaped route.
			var leg := rng.randf() * (2960.0 - TURN_Z + PATH_X - DOOR.x)
			if leg < 2960.0 - TURN_Z:
				p = Vector2(PATH_X + rng.randf_range(-320.0, 320.0), 2960.0 - leg)
			else:
				p = Vector2(PATH_X - (leg - (2960.0 - TURN_Z)), TURN_Z + rng.randf_range(-40.0, 420.0))
		else:
			p = Vector2(rng.randf_range(-w * 0.5 + 40.0, w * 0.5 - 40.0), rng.randf_range(-d * 0.5 + 40.0, d * 0.5 - 40.0))
		var kind := rng.randi() % 5
		var sx := rng.randf_range(6.0, 30.0)
		var sz := rng.randf_range(6.0, 30.0)
		var h := rng.randf_range(4.0, 34.0) * (1.6 if not near else 1.0)
		var yaw := rng.randf_range(-0.3, 0.3)
		# Keep the route, the huts and the warm bay clear.
		var reach := maxf(sx, sz) * 0.75 + 7.0
		if absf(p.x - PATH_X) < reach and p.y > TURN_Z - reach:
			continue
		if absf(p.y - TURN_Z) < reach and p.x < PATH_X + reach and p.x > DOOR.x - reach:
			continue
		if p.x > -2990.0 and p.x < -1960.0 and p.y > -1740.0 and p.y < -30.0:
			continue
		if p.y > 2960.0:
			continue
		var o := Vector3(p.x, 0.0, p.y)
		var sink := 0.3 + 0.002 * float(k)
		match kind:
			0, 1:
				# Dead stub of a building under a cap of ice.
				rbox(o + Vector3(0, h * 0.5 - sink, 0), Vector3(sx, h, sz), Vector3(0, yaw, 0), &"frost_wall", true)
				rbox(o + Vector3(0, h - sink + 0.5, 0), Vector3(sx + 1.2, 1.4, sz + 1.2), Vector3(0, yaw, 0), &"ice")
			2:
				# Ice blocks heaved up out of the plate.
				for b in 1 + rng.randi() % 4:
					var bs := rng.randf_range(1.0, 5.5)
					rbox(o + Vector3(rng.randf_range(-6.0, 6.0), bs * 0.3 - sink * 0.2, rng.randf_range(-6.0, 6.0)), Vector3(bs, bs * 0.8, bs * 1.2),
						Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, 3.0), rng.randf_range(-0.3, 0.3)), &"ice", bs > 2.5)
			3:
				# Drift: a long low ramp of packed snow.
				rbox(o + Vector3(0, 0.1 + 0.001 * float(k % 97), 0), Vector3(sx * 1.6, 1.3, sz * 0.7), Vector3(0, yaw * 5.0, rng.randf_range(0.02, 0.07)), &"ice")
			_:
				# A few bare columns, iced on the windward side.
				for c in 2 + rng.randi() % 4:
					var cp := o + Vector3(float(c % 3) * 9.0, 0.0, float(c / 3) * 9.0)
					var ch := rng.randf_range(6.0, 30.0)
					box(cp + Vector3(-0.45, -sink, -0.45), cp + Vector3(0.45, ch, 0.45), &"rust_steel", true)
					box(cp + Vector3(-0.62, -sink, 0.3), cp + Vector3(0.62, ch * rng.randf_range(0.5, 0.95), 0.72), &"ice")
