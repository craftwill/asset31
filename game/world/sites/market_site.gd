class_name MarketSite
extends Node3D
## Market street (frame 550s): the avenue through the home district narrows to
## a ~28 m street lined with lit storefronts, an overhead tube light running
## down its centre, hanging banners, embedded rails and a crowd.
## Coordinates are stack-local (this node sits at the stack origin).

const STREET_HALF := 14.0
const SHOP_DEPTH := 16.5
const BLOCK := 62.5
const SIDE_STREET := 14.0


static func build(stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := MarketSite.new()
	s._build(stack, site)
	return s


func _build(stack: StackRuntime, site: Dictionary) -> void:
	var r: Array = site.rect
	var x0 := float(r[0])
	var x1 := float(r[2])
	var hw := stack.size_x() * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(site.id))
	var body := StaticBody3D.new()
	add_child(body)
	var shops: Array = []
	var signs: Dictionary = {}
	var awnings: Dictionary = {}
	var stall_wood: Array = []
	var stall_crates: Array = []
	var stall_poles: Array = []
	# Shop rows between side streets (block boundaries every 62.5 m).
	var k := ceili((x0 + hw) / BLOCK)
	while -hw + k * BLOCK + BLOCK <= x1 + 0.01:
		var seg_a := -hw + k * BLOCK + SIDE_STREET * 0.5
		var seg_b := -hw + (k + 1) * BLOCK - SIDE_STREET * 0.5
		for side in [-1.0, 1.0]:
			var x := seg_a
			while x < seg_b - 4.0:
				var w := minf(rng.randf_range(8.0, 15.0), seg_b - x)
				if seg_b - (x + w) < 6.0:
					w = seg_b - x
				var storeys := rng.randi_range(3, 12)
				var h := 4.6 + storeys * 3.5
				var z_front: float = side * STREET_HALF
				var z_back: float = side * (STREET_HALF + SHOP_DEPTH)
				var c := Vector3(x + w * 0.5, (h - 1.0) * 0.5, (z_front + z_back) * 0.5)
				var sz := Vector3(w - 0.4, h + 1.0, SHOP_DEPTH)
				shops.append({ "c": c, "s": sz, "seed": rng.randf() * 0.9 })
				SliceMaterials.add_collision_box(body, c, sz)
				# Warm interior spill onto the pavement.
				var hue := rng.randf()
				var col := Color(1.0, 0.7, 0.42) if hue < 0.7 else (Color(0.7, 1.0, 0.85) if hue < 0.85 else Color(1.0, 0.6, 0.85))
				var l := SliceMaterials.make_lamp_light(col, rng.randf_range(0.7, 1.4), 9.0)
				l.position = Vector3(x + w * 0.5, 2.6, side * (STREET_HALF - 1.2))
				add_child(l)
				# Projecting shopfront awnings overhanging the sidewalk (ref 550s).
				if rng.randf() < 0.62:
					var amat: StringName = [&"awning_rust", &"awning_dark", &"cloth_beige"][rng.randi() % 3]
					if not awnings.has(amat):
						awnings[amat] = []
					awnings[amat].append({
						"c": Vector3(x + w * 0.5, 3.45, side * (STREET_HALF - 1.15)),
						"s": Vector3(w - 1.2, 0.08, 2.2),
						"r": Vector3(side * 0.14, 0.0, 0.0),
					})
				# Sparse sidewalk vendor stalls and stacked crates tucked against shopfronts
				# (outer sidewalk only, keeping the central roadway and inner walk clear).
				if rng.randf() < 0.32 and w > 9.0:
					var sx := x + w * 0.5 + rng.randf_range(-1.5, 1.5)
					var sz_p: float = side * (STREET_HALF - 1.2)
					stall_wood.append({ "c": Vector3(sx, 0.45, sz_p), "s": Vector3(2.4, 0.85, 1.1) })
					SliceMaterials.add_collision_box(body, Vector3(sx, 0.45, sz_p), Vector3(2.4, 0.85, 1.1))
					stall_crates.append({ "c": Vector3(sx + 1.65, 0.35, sz_p + side * 0.1), "s": Vector3(0.65, 0.65, 0.65) })
					stall_poles.append({ "c": Vector3(sx - 1.1, 1.2, sz_p - side * 0.45), "s": Vector3(0.06, 2.35, 0.06) })
					stall_poles.append({ "c": Vector3(sx + 1.1, 1.2, sz_p - side * 0.45), "s": Vector3(0.06, 2.35, 0.06) })
					var cmat: StringName = [&"awning_rust", &"cloth_teal", &"cloth_beige"][rng.randi() % 3]
					if not awnings.has(cmat):
						awnings[cmat] = []
					awnings[cmat].append({ "c": Vector3(sx, 2.4, sz_p), "s": Vector3(2.6, 0.07, 1.4), "r": Vector3(side * 0.12, 0.0, 0.0) })
				# Some protruding signs.
				if rng.randf() < 0.35:
					var mat: StringName = [&"sign_green", &"sign_magenta", &"sign_cyan", &"sign_yellow"][rng.randi() % 4]
					if not signs.has(mat):
						signs[mat] = []
					var sy := rng.randf_range(6.0, 9.0)
					signs[mat].append({ "c": Vector3(x + 1.0, sy, side * (STREET_HALF - 0.95)), "s": Vector3(0.25, 1.6, 1.7) })
				x += w
		k += 1
	SliceMaterials.add_multimesh(self, shops, &"shopfront")
	for mat: StringName in signs:
		SliceMaterials.add_multimesh(self, signs[mat], mat)
	for amat: StringName in awnings:
		SliceMaterials.add_multimesh(self, awnings[amat], amat)
	if not stall_wood.is_empty():
		SliceMaterials.add_multimesh(self, stall_wood, &"wood")
	if not stall_crates.is_empty():
		SliceMaterials.add_multimesh(self, stall_crates, &"container_rust")
	if not stall_poles.is_empty():
		SliceMaterials.add_multimesh(self, stall_poles, &"structure")

	# Sparse industrial service kiosks / ration vending units tucked along outer sidewalks.
	var kiosks: Array = []
	var kiosk_screens: Array = []
	var kx := x0 + 95.0
	var ki := 0
	while kx < x1 - 80.0:
		var kside := -1.0 if ki % 2 == 0 else 1.0
		var kz := kside * (STREET_HALF - 0.55)
		kiosks.append({ "c": Vector3(kx, 1.15, kz), "s": Vector3(1.1, 2.3, 0.7) })
		SliceMaterials.add_collision_box(body, Vector3(kx, 1.15, kz), Vector3(1.1, 2.3, 0.7))
		kiosk_screens.append({ "c": Vector3(kx, 1.45, kz - kside * 0.37), "s": Vector3(0.68, 0.48, 0.03) })
		kx += 175.0
		ki += 1
	if not kiosks.is_empty():
		SliceMaterials.add_multimesh(self, kiosks, &"container_grey")
		SliceMaterials.add_multimesh(self, kiosk_screens, &"sign_cyan")

	# Pavement: worn concrete sidewalks along the shop fronts, rails in the middle.
	for side in [-1.0, 1.0]:
		var za: float = side * (STREET_HALF - 4.5)
		var zb: float = side * STREET_HALF
		SliceMaterials.add_box(self, null, Vector3((x0 + x1) * 0.5, -0.02, (za + zb) * 0.5), Vector3(x1 - x0, 0.1, absf(zb - za)), &"concrete_floor", false)
		SliceMaterials.add_box(self, null, Vector3((x0 + x1) * 0.5, 0.0, side * 0.75), Vector3(x1 - x0, 0.1, 0.12), &"rail_steel", false)

	# Overhead tube light (550s), with support beams and hangers.
	var ty := 15.0
	var x := x0 + 12.0
	var tube_lights: Array = []
	var glows: Array = []
	while x < x1 - 12.0:
		var xe := minf(x + 40.0, x1 - 12.0)
		SliceMaterials.add_cylinder(self, Vector3(x, ty, 0), Vector3(xe, ty, 0), 1.4, &"tube", 12)
		SliceMaterials.add_box(self, null, Vector3(x, ty, 0), Vector3(1.2, 3.3, 3.3), &"structure", false)
		x = xe
	x = x0 + 12.0
	while x < x1 - 12.0:
		SliceMaterials.add_box(self, null, Vector3(x, ty + 4.0, 0), Vector3(0.5, 0.5, STREET_HALF * 2.0), &"structure", false)
		SliceMaterials.add_box(self, null, Vector3(x, ty + 2.1, 0), Vector3(0.15, 3.6, 0.15), &"structure", false)
		x += 80.0
	x = x0 + 20.0
	while x < x1 - 20.0:
		var l := SliceMaterials.make_lamp_light(Color(1.0, 0.86, 0.66), 3.2, 30.0)
		l.position = Vector3(x, ty - 2.2, 0)
		l.distance_fade_begin = 400.0
		add_child(l)
		x += 32.0
	x = x0 + 14.0
	while x < x1 - 14.0:
		glows.append(Vector3(x, ty, 0))
		x += 9.0
	SliceMaterials.add_coronas(self, glows, 7.0, &"corona_soft")

	# Banners on cables across the street.
	var cloths: Dictionary = {}
	x = x0 + 25.0
	while x < x1 - 20.0:
		var cy := rng.randf_range(10.0, 13.0)
		SliceMaterials.add_box(self, null, Vector3(x, cy, 0), Vector3(0.04, 0.04, STREET_HALF * 2.0), &"structure", false)
		var n := rng.randi_range(5, 9)
		for i in n:
			var z := -STREET_HALF + (i + 0.5) * (STREET_HALF * 2.0 / n)
			var mat: StringName = [&"cloth_red", &"cloth_teal", &"cloth_beige", &"cloth_magenta", &"cloth_beige"][rng.randi() % 5]
			if not cloths.has(mat):
				cloths[mat] = []
			var bh := rng.randf_range(1.0, 1.8)
			cloths[mat].append({ "c": Vector3(x, cy - bh * 0.5, z), "s": Vector3(0.03, bh, rng.randf_range(0.9, 1.6)) })
		x += rng.randf_range(22.0, 34.0)
	for mat: StringName in cloths:
		SliceMaterials.add_multimesh(self, cloths[mat], mat)

	# East exit threshold gantry leading out toward the industrial corridor.
	var ex := x1 - 4.0
	for side in [-1.0, 1.0]:
		SliceMaterials.add_box(self, body, Vector3(ex, 6.2, side * (STREET_HALF - 0.35)), Vector3(0.7, 12.4, 0.7), &"structure")
	SliceMaterials.add_box(self, null, Vector3(ex, 12.4, 0.0), Vector3(0.8, 0.9, STREET_HALF * 2.0), &"structure", false)
	SliceMaterials.add_box(self, null, Vector3(ex, 11.8, 0.0), Vector3(0.9, 0.2, 0.9), &"lamp", false)
	SliceMaterials.add_coronas(self, [Vector3(ex, 11.6, 0.0)], 2.2, &"corona_soft")
	var el := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 2.0, 24.0)
	el.position = Vector3(ex, 11.1, 0.0)
	add_child(el)
	SliceMaterials.add_sign(self, Vector3(ex - 0.45, 12.4, 0.0), "SECTOR 77-E  ·  INDUSTRIAL CORRIDOR  →", 0.022, Color(1.0, 0.85, 0.55), -PI * 0.5)

	# Crowd: pedestrians walking the street, a few standing at shop fronts.
	var walkers: Array = []
	for i in 70:
		var z := rng.randf_range(-STREET_HALF + 1.5, STREET_HALF - 1.5)
		var xa := rng.randf_range(x0 + 5.0, x1 - 5.0)
		var span := rng.randf_range(40.0, 160.0)
		walkers.append({ "a": Vector3(xa, 0.0, z), "b": Vector3(clampf(xa + span, x0 + 5.0, x1 - 5.0), 0.0, z + rng.randf_range(-2.0, 2.0)) })
	var statics: Array = []
	for i in 30:
		var side := -1.0 if i % 2 == 0 else 1.0
		statics.append({ "p": Vector3(rng.randf_range(x0 + 5.0, x1 - 5.0), 0.0, side * (STREET_HALF - rng.randf_range(0.8, 3.0))),
			"yaw": (0.0 if side > 0.0 else PI) + rng.randf_range(-0.8, 0.8) })
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(statics, walkers, hash(String(site.id)) + 1, 0.0, 380.0)
