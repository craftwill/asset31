class_name ConstructionSite
extends SiteKit
## Unfinished Sector 413-U (STK-0413 south extremity): a district that was never
## completed. Bare concrete frames with no facades, every finished floor open and
## reachable by switchback ramps; a dead tower crane, hoardings and material piles.
## Squatters have moved into the lower floors: tarps, bedrolls, barrel fires, strung
## bulbs. Stack-local coordinates; the site rect is the fenced works area.

const BAY := 8.0       # column grid
const FLOOR_H := 4.0
const SLAB_T := 0.4

var _rng := RandomNumberGenerator.new()
var _statics: Array = []
var _walkers: Array = []
var _fires: Array[OmniLight3D] = []
var _frame_rects: Array[Rect2] = []
var _t := 0.0


static func build(_stack: StackRuntime, site: Dictionary) -> Node3D:
	var s := ConstructionSite.new()
	s._build(site)
	return s


func _build(site: Dictionary) -> void:
	var r: Array = site.rect
	var xa := float(r[0])
	var za := float(r[1])
	var xb := float(r[2])
	var zb := float(r[3])
	_rng.seed = 41355
	_hoarding(xa, za, xb, zb)
	# Frames: [x, z, bays x, bays z, levels, finished levels, squatter levels]
	var frames := [
		[xa + 14.0, za + 16.0, 5, 4, 9, 4, 3],
		[xa + 78.0, za + 10.0, 4, 3, 6, 3, 2],
		[xa + 132.0, za + 22.0, 6, 4, 14, 5, 3],
		[xa + 20.0, za + 92.0, 4, 4, 5, 2, 1],
		[xa + 92.0, za + 104.0, 5, 3, 11, 4, 2],
		[xa + 164.0, za + 112.0, 4, 4, 7, 3, 0],
		[xa + 30.0, za + 168.0, 6, 3, 4, 2, 2],
		[xa + 118.0, za + 176.0, 4, 3, 8, 3, 1],
	]
	for f: Array in frames:
		_frame(Vector3(float(f[0]), 0.0, float(f[1])), int(f[2]), int(f[3]), int(f[4]), int(f[5]), int(f[6]))
	_crane(Vector3(xa + 112.0, 0.0, za + 72.0))
	_yard(xa, za, xb, zb)
	# The notice that stopped the works, and what the squatters keep.
	add_child(ReadableNote.create(
		"NOTE-413-WORKS", "Works Notice",
		"SECTOR 413-U — WORKS SUSPENDED\n\n"
		+ "Structural pours halted pending allocation review.\n"
		+ "Crews reassigned to STK-0414. Crane left in place.\n"
		+ "No habitation permitted above the fourth slab.\n\n"
		+ "(Underneath, scratched in by hand:)\n"
		+ "the review never came. we did. mind the open edges.",
		Vector3(xa + 4.0, 1.5, za + 1.0), 0.0))
	add_child(LootContainer.create(
		"CONT-413-SQUAT", "Squatters' Cache", "cache",
		Vector3(xa + 19.0, FLOOR_H + 0.02, za + 37.0), PI * 0.5,
		[["dried_strip", 2], ["water_flask", 1], ["bandage_roll", 1], ["fuse_cell", 1]], 5, 4))
	add_child(LootContainer.create(
		"CONT-413-SITEOFFICE", "Site Office Locker", "locker",
		Vector3(xa + 70.0, 0.0, za + 72.0), 0.0,
		[["salvaged_relay", 1], ["brass_coil", 2], ["ration_tin", 1]], 5, 4))
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(_statics, _walkers, 4138, 0.45)
	flush()


func _process(delta: float) -> void:
	# Barrel fires breathe.
	_t += delta
	for i in _fires.size():
		_fires[i].light_energy = 1.7 + 0.35 * sin(_t * (5.3 + float(i) * 0.7)) + 0.2 * sin(_t * 13.1 + float(i) * 2.0)


## Plate hoarding around the works with gaps where people have pulled panels off.
func _hoarding(xa: float, za: float, xb: float, zb: float) -> void:
	for side in 4:
		var along_x := side < 2
		var fixed := [za, zb, xa, xb][side] as float
		var u := (xa if along_x else za) + 0.5
		var u_end := (xb if along_x else zb) - 0.5
		while u < u_end - 2.0:
			var w := minf(_rng.randf_range(3.0, 4.2), u_end - u)
			if _rng.randf() < 0.78:
				var h := _rng.randf_range(2.2, 2.7)
				var mat: StringName = &"plate" if _rng.randf() < 0.7 else &"container_grey"
				if along_x:
					box(Vector3(u, 0.0, fixed - 0.05), Vector3(u + w - 0.12, h, fixed + 0.05), mat, true, true)
				else:
					box(Vector3(fixed - 0.05, 0.0, u), Vector3(fixed + 0.05, h, u + w - 0.12), mat, true, true)
			u += w
	# The notice has its own board on two posts, so it never hangs in a gap in the fence.
	box(Vector3(xa + 1.2, 1.55, za - 0.24), Vector3(xa + 6.8, 2.5, za - 0.16), &"container_grey")
	for px: float in [xa + 1.5, xa + 6.5]:
		box(Vector3(px - 0.06, 0.0, za - 0.16), Vector3(px + 0.06, 2.5, za - 0.07), &"structure", true)
	SliceMaterials.add_sign(self, Vector3(xa + 4.0, 2.03, za - 0.25), "413-U  WORKS SUSPENDED", 0.0105, Color(0.62, 0.5, 0.22), PI)
	box(Vector3(xa + 1.0, 0.0, za - 0.3), Vector3(xa + 7.0, 0.012, za + 0.6), &"hazard")


## One bare frame. Columns on an 8 m grid, slabs per bay, a switchback ramp core in
## rows 0-1 (bays 1-2), partial slabs and rebar above `finished`.
func _frame(o: Vector3, nx: int, nz: int, levels: int, finished: int, squat: int) -> void:
	var top := float(levels) * FLOOR_H
	_frame_rects.append(Rect2(o.x - 3.0, o.z - 3.0, float(nx) * BAY + 6.0, float(nz) * BAY + 9.0))
	for ix in nx + 1:
		for iz in nz + 1:
			var p := o + Vector3(float(ix) * BAY, 0.0, float(iz) * BAY)
			# Outer columns stop early on some frames: the pour never reached them.
			var col_top := top
			if (ix == nx or iz == nz) and _rng.randf() < 0.35:
				col_top = float(maxi(finished, levels - 1 - _rng.randi() % 4)) * FLOOR_H + 0.9
			box(p + Vector3(-0.35, -0.5, -0.35), p + Vector3(0.35, col_top + (0.07 if is_equal_approx(col_top, top) else 0.0), 0.35), &"concrete", true)
			# Rebar left sticking out of the top.
			for k in 4:
				var rx := -0.22 + 0.44 * float(k % 2)
				var rz := -0.22 + 0.44 * float(k / 2)
				box(p + Vector3(rx - 0.02, col_top, rz - 0.02), p + Vector3(rx + 0.02, col_top + _rng.randf_range(0.6, 1.6), rz + 0.02), &"copper")
	for lv in range(1, levels + 1):
		var y := float(lv) * FLOOR_H
		var ramp_row := 0 if lv % 2 == 1 else 1
		for ix in nx:
			for iz in nz:
				if iz == ramp_row and (ix == 1 or ix == 2):
					continue   # opening where the ramp arrives
				if lv > finished:
					# Unfinished floors: scattered poured bays only, never above the ramp core.
					if iz < 2 or _rng.randf() < 0.55 + 0.08 * float(lv - finished):
						continue
				var b0 := o + Vector3(float(ix) * BAY, y - SLAB_T, float(iz) * BAY)
				box(b0, b0 + Vector3(BAY, SLAB_T, BAY), &"concrete_floor", true)
		if lv <= finished:
			# Ramp up to this floor: +x on odd floors (row 0), -x on even floors (row 1).
			var zr := o.z + (float(ramp_row) + 0.5) * BAY
			var x_lo := o.x + BAY if lv % 2 == 1 else o.x + 3.0 * BAY
			var x_hi := o.x + 3.0 * BAY if lv % 2 == 1 else o.x + BAY
			ramp(Vector3(x_lo, y - FLOOR_H, zr), Vector3(x_hi, y, zr), BAY - 1.6, &"concrete", 0.35)
			# Scaffold-tube guard on the open side of the ramp well.
			var zg := o.z + float(ramp_row + 1) * BAY - 0.2 if ramp_row == 0 else o.z + float(ramp_row) * BAY + 0.2
			box(Vector3(o.x + BAY, y + 0.95, zg - 0.03), Vector3(o.x + 3.0 * BAY, y + 1.0, zg + 0.03), &"structure")
			for gx in 5:
				var px := o.x + BAY + float(gx) * 4.0
				box(Vector3(px - 0.03, y, zg - 0.03), Vector3(px + 0.03, y + 0.95, zg + 0.03), &"structure")
			if lv <= squat:
				_camp(o, nx, nz, y, lv)
	# A work-light the squatters keep running at the foot of the frame, and one aloft.
	var wl := o + Vector3(-2.2, 0.0, float(nz) * BAY * 0.5)
	box(wl + Vector3(-0.06, 0, -0.06), wl + Vector3(0.06, 3.2, 0.06), &"structure", true)
	light(wl + Vector3(0, 3.3, 0), SliceMaterials.COOL, 2.6, 30.0, &"lamp_cool", 0.5)
	glow(wl + Vector3(0, 3.3, 0), &"corona_cool")
	var up := o + Vector3(float(nx) * BAY * 0.5, float(finished) * FLOOR_H + 3.0, float(nz) * BAY - 1.0)
	light(up, Color(1.0, 0.8, 0.5), 2.0, 26.0, &"bulb", 0.3)
	# Scaffolding up one face.
	var face_z := o.z + float(nz) * BAY + 0.9
	var sc_top := float(mini(levels, finished + 2)) * FLOOR_H
	var sx := 0.0
	while sx <= float(nx) * BAY + 0.1:
		box(o + Vector3(sx - 0.04, 0.0, float(nz) * BAY + 0.86), o + Vector3(sx + 0.04, sc_top + 1.2, float(nz) * BAY + 0.94), &"structure")
		box(o + Vector3(sx - 0.04, 0.0, float(nz) * BAY + 1.96), o + Vector3(sx + 0.04, sc_top + 1.2, float(nz) * BAY + 2.04), &"structure")
		sx += 4.0
	var sy := 2.0
	while sy < sc_top + 0.5:
		box(Vector3(o.x, sy, face_z + 0.02), Vector3(o.x + float(nx) * BAY, sy + 0.05, face_z + 1.08), &"wood_dark" if _rng.randf() < 0.75 else &"wood")
		sy += 2.0


## A squatters' camp on one finished floor.
func _camp(o: Vector3, nx: int, nz: int, y: float, lv: int) -> void:
	var cloths: Array[StringName] = [&"cloth_red", &"cloth_teal", &"cloth_beige", &"fabric_dark", &"awning_rust", &"awning_dark"]
	var x_max := float(nx) * BAY
	var z_max := float(nz) * BAY
	# Shelters in the bays away from the ramp core.
	for k in 2 + _rng.randi() % 3:
		var px := _rng.randf_range(3.2 * BAY if nx > 4 else 0.4, x_max - 3.6)
		# Shelters stop short of the open edge, where someone paces.
		var pz := _rng.randf_range(2.0 * BAY + 0.6, z_max - 5.0) if nz > 2 else _rng.randf_range(0.6, z_max - 5.0)
		if nx <= 4:
			px = _rng.randf_range(0.4, BAY - 3.4) if k % 2 == 0 else _rng.randf_range(3.0 * BAY + 0.4, x_max - 3.4)
		var p := o + Vector3(px, y + 0.017 * float(k), pz)
		# Tarp lean-to on four poles, bedroll, a crate.
		for ax: float in [0.0, 3.0]:
			for az: float in [0.0, 2.6]:
				box(p + Vector3(ax - 0.03, 0, az - 0.03), p + Vector3(ax + 0.03, 2.1 if az < 1.0 else 1.5, az + 0.03), &"structure")
		rbox(p + Vector3(1.5, 1.86, 1.3), Vector3(3.3, 0.04, 2.9), Vector3(-0.23, 0, 0), cloths[_rng.randi() % cloths.size()])
		box(p + Vector3(0.3, 0, 0.5), p + Vector3(2.2, 0.12, 1.3), &"fabric")
		box(p + Vector3(0.3, 0.12, 0.5), p + Vector3(1.5, 0.17, 1.3), cloths[_rng.randi() % cloths.size()])
		var cs := _rng.randf_range(0.45, 0.7)
		box(p + Vector3(2.4, 0, 1.6 + 0.023 * float(k)), p + Vector3(2.4 + cs, cs, 1.63 + 0.047 * float(k) + cs), &"wood_dark", true)
		if _rng.randf() < 0.6:
			_statics.append({ "p": p + Vector3(_rng.randf_range(0.6, 2.4), 0.0, 3.4), "yaw": _rng.randf_range(-PI, PI) })
	# Barrel fire with people round it.
	var f := o + Vector3(_rng.randf_range(0.5 * BAY, 0.8 * BAY) if lv % 2 == 0 else x_max - _rng.randf_range(0.5 * BAY, 0.9 * BAY), y, z_max - _rng.randf_range(2.5, 5.0))
	box(f + Vector3(-0.3, 0, -0.3), f + Vector3(0.3, 0.85, 0.3), &"container_rust", true)
	box(f + Vector3(-0.24, 0.85, -0.24), f + Vector3(0.24, 0.9, 0.24), &"drill_glow")
	glow(f + Vector3(0, 1.0, 0), &"corona_molten")
	var fl := SliceMaterials.make_lamp_light(Color(1.0, 0.55, 0.2), 1.8, 13.0)
	fl.position = f + Vector3(0, 1.3, 0)
	add_child(fl)
	_fires.append(fl)
	for k in 2 + _rng.randi() % 2:
		var ang := _rng.randf_range(0.0, TAU)
		_statics.append({ "p": f + Vector3(cos(ang), 0, sin(ang)) * 1.3, "yaw": atan2(cos(ang), sin(ang)) })
	# A wire of bulbs across the floor, half of them dead.
	var wz := o.z + _rng.randf_range(2.2 * BAY, z_max - 1.0) if nz > 2 else o.z + z_max - 1.0
	box(Vector3(o.x, y + 2.9, wz - 0.01), Vector3(o.x + x_max, y + 2.92, wz + 0.01), &"structure")
	var bx := 1.5
	while bx < x_max - 1.0:
		box(Vector3(o.x + bx - 0.05, y + 2.78, wz - 0.05), Vector3(o.x + bx + 0.05, y + 2.89, wz + 0.05), &"bulb" if _rng.randf() < 0.5 else &"structure")
		bx += _rng.randf_range(2.2, 3.4)
	# Washing, water drums, a walker pacing the open edge.
	for k in 3 + _rng.randi() % 4:
		var cx := _rng.randf_range(1.0, x_max - 1.5)
		box(Vector3(o.x + cx, y + 2.9 - _rng.randf_range(0.5, 1.0), wz + 0.02), Vector3(o.x + cx + _rng.randf_range(0.4, 0.8), y + 2.9, wz + 0.05), cloths[_rng.randi() % cloths.size()])
	for k in 1 + _rng.randi() % 3:
		var d := o + Vector3(x_max - 0.9 - float(k) * 0.8, y, z_max - 1.0)
		SliceMaterials.add_cylinder(self, d, d + Vector3(0, 0.9, 0), 0.3, &"container_teal" if k % 2 == 0 else &"container_rust", 8)
	if lv % 2 == 1:
		_walkers.append({ "a": o + Vector3(1.0, y, z_max - 0.9), "b": o + Vector3(x_max - 3.5, y, z_max - 0.9) })


## Dead tower crane: mast, jib, counter-jib, a slab still hanging from the hook.
func _crane(p: Vector3) -> void:
	var h := 86.0
	box(p + Vector3(-3.0, 0, -3.0), p + Vector3(3.0, 1.2, 3.0), &"concrete", true)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			box(p + Vector3(sx * 1.1 - 0.12, 1.2, sz * 1.1 - 0.12), p + Vector3(sx * 1.1 + 0.12, h, sz * 1.1 + 0.12), &"structure", true)
	var y := 4.0
	while y < h:
		for sx: float in [-1.0, 1.0]:
			box(p + Vector3(sx * 1.1 - 0.05, y, -1.1), p + Vector3(sx * 1.1 + 0.05, y + 0.1, 1.1), &"structure")
			box(p + Vector3(-1.1, y + 0.1, sx * 1.1 - 0.05), p + Vector3(1.1, y + 0.2, sx * 1.1 + 0.05), &"structure")
		y += 4.0
	box(p + Vector3(-1.6, h, -1.6), p + Vector3(1.6, h + 2.4, 1.6), &"container_grey")
	box(p + Vector3(-1.0, h + 0.4, -62.0), p + Vector3(1.0, h + 1.6, -1.6), &"structure")
	box(p + Vector3(-1.0, h + 0.4, 1.6), p + Vector3(1.0, h + 1.6, 20.0), &"structure")
	box(p + Vector3(-1.4, h - 1.6, 14.0), p + Vector3(1.4, h + 0.4, 20.0), &"concrete")
	box(p + Vector3(-0.15, h + 2.4, -0.15), p + Vector3(0.15, h + 11.0, 0.15), &"structure")
	box(p + Vector3(-0.3, h + 11.0, -0.3), p + Vector3(0.3, h + 11.5, 0.3), &"beacon_red")
	glow(p + Vector3(0, h + 11.3, 0), &"corona")
	# Hook cable and the slab nobody ever landed.
	var hz := -38.0
	box(p + Vector3(-0.04, 31.0, hz - 0.04), p + Vector3(0.04, h + 0.4, hz + 0.04), &"structure")
	box(p + Vector3(-0.5, 30.0, hz - 0.5), p + Vector3(0.5, 31.0, hz + 0.5), &"hazard")
	box(p + Vector3(-3.0, 28.4, hz - 2.0), p + Vector3(3.0, 28.8, hz + 2.0), &"concrete")


## Ground-level yard: site office, material piles, mixer, a ground fire by the gate.
func _yard(xa: float, za: float, _xb: float, _zb: float) -> void:
	# Site office container and its lamp, long dead.
	var so := Vector3(xa + 62.0, 0.0, za + 68.0)
	box(so, so + Vector3(6.0, 2.6, 2.5), &"container_teal", true, true)
	box(so + Vector3(-0.1, 2.6, -0.1), so + Vector3(6.1, 2.7, 2.6), &"structure")
	box(so + Vector3(1.0, 0.0, 2.5), so + Vector3(1.9, 2.0, 2.56), &"plate")
	box(so + Vector3(3.0, 1.1, 2.5), so + Vector3(4.6, 1.9, 2.54), &"glass")
	# Piles: slabs, rebar bundles, pallets of block, pipe stacks.
	for k in 26:
		var p := Vector3(xa + _rng.randf_range(8.0, 228.0), 0.0, za + _rng.randf_range(66.0, 100.0) + (0.0 if k % 3 else 85.0))
		var blocked := false
		for fr: Rect2 in _frame_rects:
			if fr.intersects(Rect2(p.x, p.z, 7.0, 2.5)):
				blocked = true
		if blocked or Rect2(so.x - 2.0, so.z - 2.0, 12.0, 8.0).intersects(Rect2(p.x, p.z, 7.0, 2.5)):
			continue
		match k % 4:
			0:
				for n in 2 + _rng.randi() % 4:
					box(p + Vector3(0, float(n) * 0.24, 0), p + Vector3(3.6, float(n) * 0.24 + 0.2, 2.4), &"concrete", n == 0)
			1:
				for n in 5:
					box(p + Vector3(0, 0.02 + float(n / 3) * 0.07, float(n % 3) * 0.09), p + Vector3(_rng.randf_range(5.0, 7.0), 0.07 + float(n / 3) * 0.07, float(n % 3) * 0.09 + 0.05), &"copper")
			2:
				box(p, p + Vector3(1.2, 0.14, 1.0), &"wood")
				box(p + Vector3(0.05, 0.14, 0.05), p + Vector3(1.15, 0.14 + _rng.randf_range(0.5, 1.3), 0.95), &"concrete", true)
			_:
				for n in 3:
					SliceMaterials.add_cylinder(self, p + Vector3(0, 0.3, float(n) * 0.62), p + Vector3(4.5, 0.3, float(n) * 0.62), 0.3, &"structure", 8)
	# Cement mixer.
	var m := Vector3(xa + 96.0, 0.0, za + 86.0)
	box(m + Vector3(-0.6, 0, -0.5), m + Vector3(0.6, 0.7, 0.5), &"container_rust", true)
	rbox(m + Vector3(0, 1.2, 0), Vector3(1.0, 1.1, 1.0), Vector3(0.5, 0.3, 0), &"container_rust")
	# Gate fire: the first thing you see coming in from the lit streets.
	var f := Vector3(xa + 9.0, 0.0, za + 7.0)
	box(f + Vector3(-0.3, 0, -0.3), f + Vector3(0.3, 0.85, 0.3), &"container_rust", true)
	box(f + Vector3(-0.24, 0.85, -0.24), f + Vector3(0.24, 0.9, 0.24), &"drill_glow")
	glow(f + Vector3(0, 1.0, 0), &"corona_molten")
	var fl := SliceMaterials.make_lamp_light(Color(1.0, 0.55, 0.2), 1.8, 14.0)
	fl.position = f + Vector3(0, 1.3, 0)
	add_child(fl)
	_fires.append(fl)
	_statics.append({ "p": f + Vector3(1.2, 0, 0.4), "yaw": -1.3 })
	_statics.append({ "p": f + Vector3(-0.9, 0, 1.0), "yaw": 2.4 })
	# A lane kept free of frames, scaffolds and piles (which start at za + 66).
	_walkers.append({ "a": Vector3(xa + 12.0, 0, za + 61.0), "b": Vector3(xa + 200.0, 0, za + 61.0) })
