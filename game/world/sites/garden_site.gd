class_name GardenSite
extends SiteKit
## Garden Court 413-C (STK-0413 residential): one city block left open as a hanging
## garden fed from Hydroponic Bay 413-A. A stepped planter mound with a tree on top
## under a grow-light gantry, hanging planters on poles, corner beds, benches and a
## feed pipe. Stack-local coordinates; the site rect is the block's lot area.


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := GardenSite.new()
	s._build(site)
	return s


func _build(site: Dictionary) -> void:
	var r: Array = site.rect
	var xa := float(r[0])
	var za := float(r[1])
	var xb := float(r[2])
	var zb := float(r[3])
	var c := Vector3((xa + xb) * 0.5, 0.0, (za + zb) * 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41353
	# Low perimeter wall with an opening in the middle of each side.
	for side: float in [-1.0, 1.0]:
		var zw := za if side < 0.0 else zb
		var xw := xa if side < 0.0 else xb
		for half: float in [-1.0, 1.0]:
			var u0 := 3.0 * half
			box(Vector3(c.x + u0, 0.0, zw - 0.2), Vector3(xa + 0.45 if half < 0.0 else xb - 0.45, 0.75, zw + 0.2), &"concrete", true)
			box(Vector3(xw - 0.2, 0.0, c.z + u0), Vector3(xw + 0.2, 0.7, za if half < 0.0 else zb), &"concrete", true)
	# Stepped planter mound: three tiers, grass on each, stairs on the four sides.
	var tiers := [[12.0, 0.8], [8.0, 1.6], [4.2, 2.4]]
	for i in tiers.size():
		var h: float = tiers[i][0]
		var y: float = tiers[i][1]
		box(c + Vector3(-h, -0.05 - 0.1 * float(i), -h), c + Vector3(h, y - 0.06, h), &"concrete", true)
		box(c + Vector3(-h + 0.35, y - 0.06, -h + 0.35), c + Vector3(h - 0.35, y, h - 0.35), &"grass_floor", true)
		box(c + Vector3(-h, y - 0.06, -h), c + Vector3(h, y + 0.02, -h + 0.34), &"concrete")
		box(c + Vector3(-h, y - 0.06, h - 0.34), c + Vector3(h, y + 0.02, h), &"concrete")
		box(c + Vector3(-h, y - 0.06, -h + 0.34), c + Vector3(-h + 0.34, y + 0.02, h - 0.34), &"concrete")
		box(c + Vector3(h - 0.34, y - 0.06, -h + 0.34), c + Vector3(h, y + 0.02, h - 0.34), &"concrete")
		var y_lo := 0.0 if i == 0 else float(tiers[i - 1][1])
		for dir: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var top := c + dir * (h - 0.2) + Vector3(0, y + 0.02, 0)
			ramp(c + dir * (h + 1.5) + Vector3(0, y_lo, 0), top, 2.2, &"plate", 0.16, true)
		# Shrubs and crop rows on the tier's step.
		var inner: float = 0.0 if i == tiers.size() - 1 else float(tiers[i + 1][0])
		for k in 26 - i * 8:
			var px := rng.randf_range(-h + 0.8, h - 0.8)
			var pz := rng.randf_range(-h + 0.8, h - 0.8)
			if maxf(absf(px), absf(pz)) < inner + 0.6 or minf(absf(px), absf(pz)) < 1.6:
				continue
			var sh := rng.randf_range(0.3, 0.95)
			var sw := rng.randf_range(0.35, 0.8)
			box(c + Vector3(px - sw, y - 0.2 - 0.02 * float(k), pz - sw), c + Vector3(px + sw, y + sh, pz + sw), &"crop_green" if rng.randf() < 0.6 else &"crop_dark")
	# The tree on the top tier.
	var ty := 2.4
	box(c + Vector3(-0.3, ty, -0.3), c + Vector3(0.3, ty + 4.6, 0.3), &"tree_trunk", true)
	for k in 9:
		var o := Vector3(rng.randf_range(-2.4, 2.4), rng.randf_range(3.4, 6.2), rng.randf_range(-2.4, 2.4))
		var fs := rng.randf_range(1.1, 2.1)
		box(c + o + Vector3(-fs, ty - fs * 0.5, -fs), c + o + Vector3(fs, ty + fs * 0.5, fs), &"crop_dark" if k % 3 == 0 else &"crop_green")
	# Grow-light gantry over the mound (the same magenta as the hydroponic bay).
	var g := 9.4
	var gy := 9.6
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			box(c + Vector3(sx * g - 0.15, 0.8, sz * g - 0.15), c + Vector3(sx * g + 0.15, gy, sz * g + 0.15), &"structure", true)
		box(c + Vector3(sx * g - 0.12, gy, -g - 0.4), c + Vector3(sx * g + 0.12, gy + 0.3, g + 0.4), &"structure")
		box(c + Vector3(sx * 4.6 - 0.12, gy - 0.16, -g), c + Vector3(sx * 4.6 + 0.12, gy - 0.04, g), &"grow_magenta")
	for sz: float in [-1.0, 1.0]:
		box(c + Vector3(-g - 0.4, gy + 0.3, sz * g - 0.12), c + Vector3(g + 0.4, gy + 0.55, sz * g + 0.12), &"structure")
	box(c + Vector3(-g, gy + 0.02, -0.12), c + Vector3(g, gy + 0.24, 0.12), &"structure")
	var grow := SliceMaterials.make_lamp_light(Color(1.0, 0.5, 0.92), 4.2, 28.0)
	grow.position = c + Vector3(0, gy - 1.0, 0)
	add_child(grow)
	glow(c + Vector3(-4.6, gy - 0.1, 0), &"corona_magenta")
	glow(c + Vector3(4.6, gy - 0.1, 0), &"corona_magenta")
	# Hanging planters on poles around the court, and corner beds.
	var hw := (xb - xa) * 0.5
	for k in 8:
		var ang := float(k) * TAU / 8.0 + 0.39
		var p := c + Vector3(cos(ang), 0, sin(ang)) * (hw - 5.0)
		var ph := rng.randf_range(4.2, 5.6)
		box(p + Vector3(-0.07, 0, -0.07), p + Vector3(0.07, ph, 0.07), &"structure", true)
		box(p + Vector3(-0.9, ph - 0.1, -0.05), p + Vector3(0.9, ph, 0.05), &"structure")
		for e: float in [-0.8, 0.8]:
			var drop := rng.randf_range(0.6, 1.5)
			box(p + Vector3(e - 0.01, ph - 0.1 - drop, -0.01), p + Vector3(e + 0.01, ph - 0.1, 0.01), &"structure")
			box(p + Vector3(e - 0.3, ph - 0.5 - drop, -0.3), p + Vector3(e + 0.3, ph - 0.1 - drop, 0.3), &"container_rust" if rng.randf() < 0.5 else &"ceramic")
			box(p + Vector3(e - 0.38, ph - 0.12 - drop, -0.38), p + Vector3(e + 0.38, ph + 0.25 - drop, 0.38), &"crop_green")
			box(p + Vector3(e + 0.1, ph - 1.3 - drop, -0.12), p + Vector3(e + 0.3, ph - 0.5 - drop, 0.1), &"crop_dark")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var q := c + Vector3(sx * (hw - 3.2), 0, sz * (hw - 3.2))
			box(q + Vector3(-2.2, 0, -2.2), q + Vector3(2.2, 0.55, 2.2), &"concrete", true)
			box(q + Vector3(-2.0, 0.55, -2.0), q + Vector3(2.0, 0.6, 2.0), &"grass_floor")
			for k in 5:
				var o := Vector3(rng.randf_range(-1.5, 1.5), 0.6, rng.randf_range(-1.5, 1.5))
				var sh := rng.randf_range(0.5, 1.6)
				var hs := 0.42 - 0.035 * float(k)
				box(q + o + Vector3(-hs, -0.2 - 0.03 * float(k), -hs), q + o + Vector3(hs, sh, hs), &"crop_green" if k % 2 == 0 else &"crop_dark")
			# Bench facing the mound.
			var bq := c + Vector3(sx * (hw - 7.2), 0, sz * 6.0)
			box(bq + Vector3(-0.25, 0.4, -1.0), bq + Vector3(0.25, 0.47, 1.0), &"wood", true)
			box(bq + Vector3(-0.2, 0.0, -0.9), bq + Vector3(0.2, 0.4, -0.75), &"structure")
			box(bq + Vector3(-0.2, 0.0, 0.75), bq + Vector3(0.2, 0.4, 0.9), &"structure")
	# Feed pipe from the hydroponic bay, running in along the west wall to a trough.
	SliceMaterials.add_cylinder(self, Vector3(xa + 0.6, 0.3, za + 1.0), Vector3(xa + 0.6, 0.3, c.z - 4.0), 0.14, &"copper", 8)
	SliceMaterials.add_cylinder(self, Vector3(xa + 0.6, 0.3, c.z - 4.0), Vector3(xa + 3.4, 0.3, c.z - 4.0), 0.14, &"copper", 8)
	box(Vector3(xa + 3.2, 0.0, c.z - 5.2), Vector3(xa + 5.4, 0.6, c.z - 2.8), &"concrete", true)
	box(Vector3(xa + 3.4, 0.4, c.z - 5.0), Vector3(xa + 5.2, 0.52, c.z - 3.0), &"water")
	lamp_post(Vector3(xa + 4.0, 0, za + 4.0), 4.4, SliceMaterials.COOL, &"lamp_cool", 1.3, 13.0)
	lamp_post(Vector3(xb - 4.0, 0, zb - 4.0), 4.4, SliceMaterials.COOL, &"lamp_cool", 1.3, 13.0)
	SliceMaterials.add_sign(self, Vector3(c.x, 1.25, za - 0.22), "GARDEN COURT 413-C", 0.012, Color(0.75, 1.0, 0.8), PI)
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(
		[{ "p": c + Vector3(-(hw - 7.9), 0, 6.3), "yaw": PI * 0.5 }, { "p": c + Vector3(2.0, 1.6, -6.0), "yaw": 0.4 }, { "p": c + Vector3(hw - 6.0, 0, -9.0), "yaw": -2.0 }],
		[{ "a": c + Vector3(-hw + 2.5, 0, -hw + 2.5), "b": c + Vector3(hw - 2.5, 0, -hw + 2.5) }, { "a": c + Vector3(hw - 2.0, 0, 0), "b": c + Vector3(-hw + 2.0, 0, 14.0) }],
		4136, 0.2)
	flush()
