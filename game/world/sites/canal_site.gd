class_name CanalSite
extends SiteKit
## Condensate Canal 413 (STK-0413 residential): a raised water channel running down
## the middle of a side street where STK-0412 has its car street. Each block has a
## stretch of open channel with quays either side and an arched footbridge; at the
## cross streets the water drops into culvert pipes so the crossings stay level.
## Stack-local coordinates; the site rect is the channel strip inside the street.

const HALF_W := 2.5        # channel half-width (inner)
const WALL_H := 1.1
const WATER_Y := 0.8


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := CanalSite.new()
	s._build(site)
	return s


func _build(site: Dictionary) -> void:
	var r: Array = site.rect
	var xa := float(r[0])
	var xb := float(r[2])
	var zc := (float(r[1]) + float(r[3])) * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 41352
	var statics: Array = []
	var walkers: Array = []
	var x := xa
	var seg := 0
	while x < xb - 1.0:
		var s0 := x + CityLayout.STREET * 0.5 + 1.0
		var s1 := x + CityLayout.BLOCK - CityLayout.STREET * 0.5 - 1.0
		# The footbridge sits at a random spot in each block; `_segment` says where.
		var bridge_x := _segment(s0, s1, zc, rng, seg)
		if seg % 2 == 0:
			statics.append({ "p": Vector3(bridge_x + rng.randf_range(-0.6, 0.6), 1.65, zc + rng.randf_range(-1.5, 1.5)), "yaw": rng.randf_range(-PI, PI) })
		# Someone on the quay, kept well clear of the bridge ramps.
		var qx := rng.randf_range(s0 + 4.0, s1 - 4.0)
		if absf(qx - bridge_x) > 3.5:
			statics.append({ "p": Vector3(qx, 0.0, zc + (4.6 if seg % 2 == 0 else -4.6)), "yaw": 0.0 if seg % 2 == 0 else PI })
		x += CityLayout.BLOCK
		seg += 1
	for side: float in [-1.0, 1.0]:
		# Walking lanes run outside the foot of the bridge ramps (which end 6.7 m out).
		walkers.append({ "a": Vector3(xa + 6.0, 0, zc + side * 7.25), "b": Vector3(xb - 6.0, 0, zc + side * 7.25) })
		walkers.append({ "a": Vector3(xb - 30.0, 0, zc + side * 7.7), "b": Vector3(xa + 40.0, 0, zc + side * 7.7) })
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(statics, walkers, 4135, 0.25)
	# Name plate bolted to the outer face of the quay wall (never free-standing text).
	var plate_x := xa + CityLayout.STREET * 0.5 + 6.0
	var wall_face := zc + HALF_W + 0.5
	box(Vector3(plate_x - 1.5, 0.42, wall_face), Vector3(plate_x + 1.5, 0.92, wall_face + 0.04), &"container_grey")
	SliceMaterials.add_sign(self, Vector3(plate_x, 0.67, wall_face + 0.05), "CONDENSATE CANAL 413", 0.0052, Color(0.36, 0.44, 0.54), 0.0)
	_junction_sign()
	flush()


## Street sign where the side street to the canal leaves the main avenue (stack-local
## x = -1375, the avenue runs along z = 0). Seen by someone walking in from the arrival
## gate, it is the only thing that says the residential blocks lie down this turning.
func _junction_sign() -> void:
	var p := Vector3(-1386.0, 0.0, 27.0)
	for off: float in [-2.6, 2.6]:
		box(p + Vector3(-0.1, 0.0, off - 0.1), p + Vector3(0.1, 6.4, off + 0.1), &"structure", true)
	box(p + Vector3(-0.12, 4.3, -3.2), p + Vector3(-0.04, 6.2, 3.2), &"container_grey")
	box(p + Vector3(-0.2, 6.2, -3.3), p + Vector3(0.2, 6.32, 3.3), &"structure")
	SliceMaterials.add_sign(self, p + Vector3(-0.13, 5.55, 0.0), "RESIDENTIAL BLOCKS 413-S", 0.012, Color(0.62, 0.74, 0.9), -PI * 0.5)
	SliceMaterials.add_sign(self, p + Vector3(-0.13, 4.8, 0.0), "CANAL  ·  TERRACE STEPS  →", 0.0095, Color(0.5, 0.6, 0.74), -PI * 0.5)
	light(p + Vector3(-1.0, 6.6, 0.0), SliceMaterials.COOL, 2.0, 16.0, &"lamp_cool", 0.5)
	glow(p + Vector3(-1.0, 6.6, 0.0), &"corona_cool")
	# A second lamp a little way down the turning, so the street reads as lit and lived in.
	lamp_post(Vector3(-1380.6, 0.0, 70.0), 5.0, SliceMaterials.COOL, &"lamp_cool", 1.6, 15.0)


## Builds one block of open channel and returns the x of its footbridge.
func _segment(s0: float, s1: float, zc: float, rng: RandomNumberGenerator, seg: int) -> float:
	# Bed, two walls with a coping, water.
	box(Vector3(s0, -0.25, zc - HALF_W - 0.1), Vector3(s1, 0.15, zc + HALF_W + 0.1), &"concrete", true)
	for side: float in [-1.0, 1.0]:
		var zi := zc + side * HALF_W
		box(Vector3(s0 - 0.5, -0.3, zi), Vector3(s1 + 0.5, WALL_H, zi + side * 0.5), &"concrete", true)
		box(Vector3(s0 - 0.55, WALL_H, zi - side * 0.06), Vector3(s1 + 0.55, WALL_H + 0.1, zi + side * 0.58), &"structure")
		# Mooring rings / rungs on the quay face.
		var rx := s0 + 3.0
		while rx < s1 - 2.0:
			box(Vector3(rx, 0.35, zi + side * 0.5), Vector3(rx + 0.4, 0.42, zi + side * 0.56), &"metal_light")
			rx += rng.randf_range(5.0, 9.0)
	box(Vector3(s0, 0.15, zc - HALF_W), Vector3(s1, WATER_Y, zc + HALF_W), &"water")
	# End walls and the culvert pipes that carry the water under the cross street.
	for end: float in [-1.0, 1.0]:
		var xe := s0 if end < 0.0 else s1
		box(Vector3(xe, -0.35, zc - HALF_W - 0.6), Vector3(xe + end * 0.62, WALL_H + 0.25, zc + HALF_W + 0.6), &"concrete", true)
		for pz: float in [-1.2, 1.2]:
			SliceMaterials.add_cylinder(self, Vector3(xe - end * 0.4, 0.55, zc + pz), Vector3(xe + end * 0.9, 0.55, zc + pz), 0.5, &"structure", 10)
		box(Vector3(xe + end * 0.62, 0.0, zc - 2.0), Vector3(xe + end * 1.4, 0.12, zc + 2.0), &"plate", true, true)
	# Arched footbridge mid-block: deck with a ramp down to each quay.
	var mx := (s0 + s1) * 0.5 + rng.randf_range(-8.0, 8.0)
	var deck_y := 1.65
	var reach := HALF_W + 0.9
	box(Vector3(mx - 1.2, deck_y - 0.18, zc - reach), Vector3(mx + 1.2, deck_y, zc + reach), &"plate", true, true)
	for side: float in [-1.0, 1.0]:
		ramp(Vector3(mx, 0.0, zc + side * (reach + 3.3)), Vector3(mx, deck_y, zc + side * reach), 2.4, &"plate", 0.18, true)
	for rail: float in [-1.0, 1.0]:
		var rxx := mx + rail * 1.16
		box(Vector3(rxx - 0.03, deck_y + 0.95, zc - reach), Vector3(rxx + 0.03, deck_y + 1.0, zc + reach), &"structure")
		for pz: float in [-reach + 0.04, 0.0, reach - 0.04]:
			box(Vector3(rxx - 0.025, deck_y, zc + pz - 0.03), Vector3(rxx + 0.025, deck_y + 0.95, zc + pz + 0.03), &"structure")
	# A lamp on alternating quays, a string of small lights across the water.
	var lside := 1.0 if seg % 2 == 0 else -1.0
	lamp_post(Vector3(s0 + rng.randf_range(6.0, 14.0), 0.0, zc + lside * (HALF_W + 1.1)), 4.6, SliceMaterials.COOL, &"lamp_cool", 1.6, 15.0)
	var wx := s1 - rng.randf_range(6.0, 14.0)
	for side: float in [-1.0, 1.0]:
		box(Vector3(wx - 0.05, 0.0, zc + side * (HALF_W + 0.8) - 0.05), Vector3(wx + 0.05, 3.7, zc + side * (HALF_W + 0.8) + 0.05), &"structure", true)
	box(Vector3(wx - 0.01, 3.6, zc - HALF_W - 0.8), Vector3(wx + 0.01, 3.62, zc + HALF_W + 0.8), &"structure")
	var bz := -HALF_W - 0.3
	while bz < HALF_W + 0.4:
		box(Vector3(wx - 0.05, 3.48, zc + bz - 0.05), Vector3(wx + 0.05, 3.58, zc + bz + 0.05), &"bulb" if rng.randf() < 0.85 else &"structure")
		bz += 0.9
	light(Vector3(wx, 3.4, zc), Color(1.0, 0.8, 0.5), 0.9, 9.0)
	# Something moored or left on the quay.
	if rng.randf() < 0.7:
		var px := rng.randf_range(s0 + 4.0, s1 - 8.0)
		if absf(px - mx) > 5.0:
			box(Vector3(px, WATER_Y - 0.1, zc - 1.1), Vector3(px + 4.2, WATER_Y + 0.22, zc + 1.1), &"wood_dark", true)
			box(Vector3(px + 0.5, WATER_Y + 0.22, zc - 0.6), Vector3(px + 1.6, WATER_Y + 0.8, zc + 0.5), &"container_teal" if rng.randf() < 0.5 else &"wood")
			box(Vector3(px + 2.2, WATER_Y + 0.22, zc - 0.4), Vector3(px + 3.0, WATER_Y + 0.6, zc + 0.4), &"container_rust")
	for i in 1 + rng.randi() % 3:
		var cx := rng.randf_range(s0 + 2.0, s1 - 2.0)
		var cz := zc + (1.0 if rng.randf() < 0.5 else -1.0) * (HALF_W + 0.95)
		if absf(cx - mx) > 2.5:
			var cs := rng.randf_range(0.5, 0.8)
			box(Vector3(cx - cs * 0.5, 0.0, cz - cs * 0.5), Vector3(cx + cs * 0.5, cs, cz + cs * 0.5), &"wood_dark" if rng.randf() < 0.6 else &"container_grey", true)
	return mx
