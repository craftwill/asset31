class_name TerraceSite
extends SiteKit
## Terrace Steps 413 (STK-0413 residential): a block built as a stepped plaza instead
## of four buildings, so the street climbs. Three terraces rise toward a small tea
## kiosk and lookout on top, with stalls and benches on the way up and a view down
## onto the canal. Stack-local coordinates; the site rect is the block's lot area.

const STEP := 1.5


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := TerraceSite.new()
	s._build(site)
	return s


func _build(site: Dictionary) -> void:
	var r: Array = site.rect
	var xa := float(r[0])
	var za := float(r[1])
	var xb := float(r[2])
	var zb := float(r[3])
	var c := Vector3((xa + xb) * 0.5, 0.0, (za + zb) * 0.5)
	var hw := (xb - xa) * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 41354
	var dirs: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	# Three terraces; each one's stairs are offset so the climb zig-zags.
	var halves := [hw - 3.5, hw - 10.5, hw - 17.0]
	var offs := [0.0, 5.0, -3.0]
	for i in 3:
		var h: float = halves[i]
		var y := STEP * float(i + 1)
		box(c + Vector3(-h, y - STEP - 0.4, -h), c + Vector3(h, y, h), &"concrete_floor", true)
		for d: Vector3 in dirs:
			var side := Vector3(d.z, 0, d.x) * float(offs[i])
			ramp(c + d * (h + 3.1) + side + Vector3(0, y - STEP, 0), c + d * (h - 0.1) + side + Vector3(0, y, 0), 3.4, &"plate", 0.2, true)
			# Kerb rail along the edge, broken at the stairs.
			var t := Vector3(d.z, 0, d.x)
			for seg: Array in [[-h + 0.2, float(offs[i]) - 2.1], [float(offs[i]) + 2.1, h - 0.2]]:
				var p0 := c + d * (h - 0.25) + t * float(seg[0]) + Vector3(0, y, 0)
				var p1 := c + d * (h - 0.1) + t * float(seg[1]) + Vector3(0, y + 0.42, 0)
				box(p0, p1, &"concrete", true)
	# Top: tea kiosk, awning, lamp, a couple of stools.
	var ty := STEP * 3.0
	box(c + Vector3(-2.2, ty, -1.4), c + Vector3(2.2, ty + 1.0, 1.4), &"wood_dark", true)
	box(c + Vector3(-2.3, ty + 1.0, -1.5), c + Vector3(2.3, ty + 1.06, 1.5), &"wood")
	for sx: float in [-2.1, 2.1]:
		for sz: float in [-1.3, 1.3]:
			box(c + Vector3(sx - 0.06, ty + 1.06, sz - 0.06), c + Vector3(sx + 0.06, ty + 2.7, sz + 0.06), &"structure")
	rbox(c + Vector3(0, ty + 2.85, 0), Vector3(5.4, 0.06, 3.8), Vector3(0.1, 0, 0), &"awning_dark")
	box(c + Vector3(-1.0, ty + 2.2, -1.36), c + Vector3(1.0, ty + 2.55, -1.3), &"sign_cyan")
	light(c + Vector3(0, ty + 2.5, 0), Color(1.0, 0.8, 0.52), 1.6, 12.0, &"bulb", 0.22)
	for k in 5:
		var cx := rng.randf_range(-2.0, 2.0)
		box(c + Vector3(cx - 0.08, ty + 1.06, -0.3), c + Vector3(cx + 0.08, ty + 1.06 + rng.randf_range(0.1, 0.3), -0.14), &"ceramic" if k % 2 == 0 else &"metal_light")
	for sx: float in [-1.4, 0.0, 1.4]:
		box(c + Vector3(sx - 0.17, ty, -2.3), c + Vector3(sx + 0.17, ty + 0.5, -1.96), &"wood_dark", true)
	# Stalls and benches on the two lower terraces.
	var awnings: Array[StringName] = [&"awning_rust", &"awning_dark", &"cloth_teal", &"cloth_beige"]
	for i in 2:
		var h: float = halves[i]
		var y := STEP * float(i + 1)
		var inner: float = halves[i + 1]
		var band := (h + inner) * 0.5
		for k in 7 - i * 3:
			var d := dirs[k % 4]
			var t := Vector3(d.z, 0, d.x)
			var along := rng.randf_range(-h + 3.0, h - 3.0)
			if absf(along - float(offs[i])) < 3.6 or absf(along - float(offs[i + 1])) < 3.6:
				continue
			var p := c + d * band + t * along + Vector3(0, y, 0)
			if rng.randf() < 0.55:
				box(p + Vector3(-1.1, 0, -0.7), p + Vector3(1.1, 0.85, 0.7), &"wood", true)
				for sx: float in [-1.0, 1.0]:
					box(p + Vector3(sx - 0.04, 0.85, -0.66), p + Vector3(sx + 0.04, 2.3, -0.58), &"structure")
				rbox(p + Vector3(0, 2.38, 0), Vector3(2.6, 0.05, 1.9), Vector3(0.14, 0, 0), awnings[rng.randi() % awnings.size()])
				for q in 4:
					var qx := rng.randf_range(-0.9, 0.9)
					var qh := 0.1 + 0.017 * float(q)
					var qz := -0.45 + 0.24 * float(q)
					box(p + Vector3(qx - qh, 0.83 - 0.02 * float(q), qz), p + Vector3(qx + qh, 0.95 + 0.07 * float(q) + rng.randf_range(0.0, 0.05), qz + 0.2), &"container_rust" if q % 2 == 0 else &"ceramic")
			else:
				box(p + Vector3(-1.0, 0.4, -0.22), p + Vector3(1.0, 0.47, 0.22), &"wood", true)
				box(p + Vector3(-0.9, 0, -0.18), p + Vector3(-0.76, 0.4, 0.18), &"structure")
				box(p + Vector3(0.76, 0, -0.18), p + Vector3(0.9, 0.4, 0.18), &"structure")
	# Lamps on the corners of the first terrace.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var lp := c + Vector3(sx * (float(halves[0]) - 1.2), STEP, sz * (float(halves[0]) - 1.2))
			lamp_post(lp, 3.8, SliceMaterials.COOL if sx * sz > 0.0 else SliceMaterials.WARM, &"lamp_cool" if sx * sz > 0.0 else &"lamp", 1.4, 13.0)
	SliceMaterials.add_sign(self, c + Vector3(0, ty + 2.38, -1.4), "TEA", 0.012, Color(0.1, 0.12, 0.14), PI)
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(
		[{ "p": c + Vector3(0.6, ty, -2.9), "yaw": 0.0 }, { "p": c + Vector3(-1.6, ty, -3.1), "yaw": 0.3 }, { "p": c + Vector3(float(halves[1]) - 1.0, STEP * 2.0, 4.0), "yaw": -PI * 0.5 }],
		[{ "a": c + Vector3(-float(halves[0]) + 1.5, STEP, -float(halves[0]) + 1.5), "b": c + Vector3(float(halves[0]) - 1.5, STEP, -float(halves[0]) + 1.5) }],
		4137, 0.2)
	flush()
