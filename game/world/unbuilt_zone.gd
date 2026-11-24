class_name UnbuiltZone
extends SiteKit
## The never-built south extremity of STK-0413 (reference 581s-597s). This side of
## the stack was not finished: no outer wall, so the floor simply stops at the void
## between stacks. What exists is a field of rust steel frames (instanced per chunk
## by StackRuntime from CityLayout.generate_frames), dark blue floor plates and one
## pale service pipe with orange flanges running the full 6 km width. The pipe is
## the only warm thing out here, so people gather along it.
## Stack-local coordinates.

const PIPE_D := 1.8
const PIPE_Y := 1.35
const SEG := 12.5

var pipe_z := 0.0
var _fires: Array[OmniLight3D] = []
var _t := 0.0


static func build(stack: StackRuntime, district: Dictionary) -> UnbuiltZone:
	var z := UnbuiltZone.new()
	z._build(stack, district)
	return z


func _build(stack: StackRuntime, district: Dictionary) -> void:
	var r: Array = district.rect
	var xa := float(r[0]) + 24.0
	var xb := float(r[2]) - 24.0
	var z_edge := float(r[3])
	pipe_z = float(district.get("pipe_z", (float(r[1]) + float(r[3])) * 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41390
	_pipe(xa, xb)
	# Warm-up spots along the pipe.
	var statics: Array = []
	var walkers: Array = []
	var x := xa + 90.0
	var n := 0
	while x < xb - 60.0:
		_camp(x, 1.0 if n % 3 != 1 else -1.0, rng, statics)
		if n % 4 == 0:
			walkers.append({ "a": Vector3(x + 12.0, 0, pipe_z + 6.7), "b": Vector3(x + 150.0, 0, pipe_z + 6.7) })   # beyond the camps, inside the clear street strip
		x += rng.randf_range(170.0, 300.0)
		n += 1
	# Ways over the pipe: a steel step-over on the axis of the long street, and a pair
	# of planks somebody has propped across it roughly every kilometre.
	_crossing(-1375.0, true)
	var px := xa + 420.0
	while px < xb - 200.0:
		if absf(px + 1375.0) > 120.0:
			_crossing(px + rng.randf_range(-60.0, 60.0), false)
		px += 1000.0
	_edge(xa, xb, z_edge, rng)
	_lift_pier(z_edge)
	for camp: Dictionary in district.get("camps", []):
		_squat(camp, rng, statics)
	var crowd := Crowd.new()
	add_child(crowd)
	crowd.setup(statics, walkers, 4139, 0.5, 260.0)
	add_child(ReadableNote.create(
		"NOTE-413-PIPE", "Scratched Into The Pipe Lagging",
		"RETURN LINE 413-S\n\n"
		+ "It still runs warm. Nobody knows what it returns, or to where.\n"
		+ "Keep a hand on it and walk; it goes the whole width of the stack.\n"
		+ "South of here the floor was never closed. There is no wall.\n"
		+ "In the blue you will not see the edge until you are standing on it.",
		Vector3(stack.def.get("note_x", -1372.0), 1.5, pipe_z + PIPE_D * 0.5 + 0.02), 0.0, "invisible"))
	flush()


func _pipe(xa: float, xb: float) -> void:
	var body: Array = []
	var flange: Array = []
	var band: Array = []
	var cyl := SliceMaterials.unit_cylinder(12)
	var rot := Vector3(0, 0, PI * 0.5)
	var x := xa
	var i := 0
	while x < xb - 0.1:
		var seg := minf(SEG, xb - x)
		body.append({ "c": Vector3(x + seg * 0.5, PIPE_Y, pipe_z), "s": Vector3(PIPE_D, seg, PIPE_D), "r": rot })
		# Orange flange at every joint, a dark strap between.
		flange.append({ "c": Vector3(x, PIPE_Y, pipe_z), "s": Vector3(PIPE_D * 1.2, 0.5, PIPE_D * 1.2), "r": rot })
		band.append({ "c": Vector3(x + seg * 0.5, PIPE_Y, pipe_z), "s": Vector3(PIPE_D * 1.04, 0.32, PIPE_D * 1.04), "r": rot })
		# Saddle under each joint.
		box(Vector3(x - 0.3, -0.06, pipe_z - 0.75), Vector3(x + 0.3, PIPE_Y - PIPE_D * 0.42, pipe_z + 0.75), &"concrete")
		x += SEG
		i += 1
	SliceMaterials.add_multimesh(self, body, &"pipe_pale", 0.0, cyl)
	SliceMaterials.add_multimesh(self, flange, &"pipe_flange", 0.0, cyl)
	SliceMaterials.add_multimesh(self, band, &"structure", 0.0, cyl)
	# Collision in 500 m lengths.
	var cx := xa
	while cx < xb:
		var l := minf(500.0, xb - cx)
		SliceMaterials.add_collision_box(_metal, Vector3(cx + l * 0.5, PIPE_Y, pipe_z), Vector3(l, PIPE_D * 0.92, PIPE_D * 0.92))
		cx += 500.0


func _process(delta: float) -> void:
	_t += delta
	for i in _fires.size():
		_fires[i].light_energy = 2.2 + 0.4 * sin(_t * (4.7 + float(i) * 0.9)) + 0.25 * sin(_t * 12.3 + float(i) * 1.7)


## A frame somebody lives in, beside the long street: a few floors got their decking,
## switchback ramps lead up, and a fire burns on an upper floor where it can be seen
## from the street. `camp` = { x, z (corner), levels, fires: [floor, ...], side }.
## `side` says which way the street lies (+1 = +x), so the fires sit on that edge.
func _squat(camp: Dictionary, rng: RandomNumberGenerator, statics: Array) -> void:
	var bay := 8.0
	var fh := 4.0
	var nx := 4
	var nz := 3
	var o := Vector3(float(camp.x), 0.0, float(camp.z))
	var levels := int(camp.levels)
	var side := float(camp.side)
	var fires: Array = camp.fires
	var cloths: Array[StringName] = [&"awning_dark", &"fabric_dark", &"awning_rust", &"cloth_teal"]
	for ix in nx + 1:
		for iz in nz + 1:
			var p := o + Vector3(float(ix) * bay, 0.0, float(iz) * bay)
			var top := float(levels) * fh + rng.randf_range(1.5, 9.0)
			box(p + Vector3(-0.3, -0.5, -0.3), p + Vector3(0.3, top, 0.3), &"rust_steel", true)
	for lv in range(1, levels + 1):
		var y := float(lv) * fh
		var ramp_row := 0 if lv % 2 == 1 else 1
		for ix in nx + 1:
			box(o + Vector3(float(ix) * bay - 0.16, y - 0.72, 0.3), o + Vector3(float(ix) * bay + 0.16, y - 0.3, float(nz) * bay - 0.3), &"rust_steel")
		for iz in nz + 1:
			box(o + Vector3(0.3, y - 0.78, float(iz) * bay - 0.16), o + Vector3(float(nx) * bay - 0.3, y - 0.36, float(iz) * bay + 0.16), &"rust_steel")
		for ix in nx:
			for iz in nz:
				if iz == ramp_row and (ix == 1 or ix == 2):
					continue   # opening where the ramp comes up
				box(o + Vector3(float(ix) * bay, y - 0.3, float(iz) * bay), o + Vector3(float(ix + 1) * bay, y, float(iz + 1) * bay), &"deck_pale", true)
		var zr := o.z + (float(ramp_row) + 0.5) * bay
		var x_lo := o.x + bay if lv % 2 == 1 else o.x + 3.0 * bay
		var x_hi := o.x + 3.0 * bay if lv % 2 == 1 else o.x + bay
		ramp(Vector3(x_lo, y - fh, zr), Vector3(x_hi, y, zr), bay - 1.8, &"deck_pale", 0.25)
		if not fires.has(float(lv)) and not fires.has(lv):
			continue
		# The fire, on the street-side edge of the back bay.
		# Right at the open edge, so the flames show from the street below.
		var fx := o.x + (float(nx) * bay - 1.0 if side > 0.0 else 1.0)
		var f := Vector3(fx, y, o.z + 2.5 * bay)
		box(f + Vector3(-0.3, 0.0, -0.3), f + Vector3(0.3, 0.85, 0.3), &"container_rust", true)
		box(f + Vector3(-0.24, 0.85, -0.24), f + Vector3(0.24, 0.92, 0.24), &"drill_glow")
		box(f + Vector3(-0.12, 0.92, -0.12), f + Vector3(0.12, 1.5, 0.12), &"drill_glow")
		glow(f + Vector3(0, 1.5, 0), &"corona_molten")
		var fl := SliceMaterials.make_lamp_light(Color(1.0, 0.55, 0.2), 2.2, 16.0)
		fl.position = f + Vector3(0, 1.4, 0)
		add_child(fl)
		_fires.append(fl)
		for k in 2 + rng.randi() % 2:
			var ang := rng.randf_range(0.0, TAU)
			var off := Vector3(-side * (0.5 + absf(cos(ang)) * 1.1), 0.0, sin(ang) * 1.5)
			statics.append({ "p": f + off, "yaw": atan2(-off.x, -off.z) + PI })
		# Lean-to, bedrolls and a crate further in from the edge.
		var t0 := f + Vector3(-side * 7.5, 0.0, -1.6)
		for ax: float in [0.0, 3.2]:
			box(t0 + Vector3(ax - 0.03, 0.0, 2.57), t0 + Vector3(ax + 0.03, 1.6, 2.63), &"structure")
			box(t0 + Vector3(ax - 0.03, 0.0, -0.03), t0 + Vector3(ax + 0.03, 2.2, 0.03), &"structure")
		rbox(t0 + Vector3(1.6, 1.96, 1.3), Vector3(3.6, 0.04, 2.9), Vector3(-0.23, 0, 0), cloths[rng.randi() % cloths.size()])
		box(t0 + Vector3(0.3, 0.0, 0.5), t0 + Vector3(2.2, 0.12, 1.3), &"fabric")
		box(t0 + Vector3(0.3, 0.12, 0.55), t0 + Vector3(1.5, 0.17, 1.25), &"fabric_dark")
		box(t0 + Vector3(2.5, 0.0, 1.5), t0 + Vector3(3.1, 0.55, 2.1), &"wood_dark", true)
		statics.append({ "p": t0 + Vector3(1.4, 0.0, 3.4), "yaw": rng.randf_range(-PI, PI) })


## A way over the pipe at stack-local `x`: a steel stile with rails, or bare planks.
func _crossing(x: float, steel: bool) -> void:
	var top := PIPE_Y + PIPE_D * 0.5 + 0.22
	var half := PIPE_D * 0.5 + 0.35
	var run := 4.6
	if steel:
		box(Vector3(x - 1.1, top - 0.12, pipe_z - half), Vector3(x + 1.1, top, pipe_z + half), &"plate", true, true)
		for side: float in [-1.0, 1.0]:
			ramp(Vector3(x, 0.0, pipe_z + side * (half + run)), Vector3(x, top, pipe_z + side * half), 2.2, &"plate", 0.12, true)
			box(Vector3(x - 1.06, 0.0, pipe_z + side * (half - 0.08)), Vector3(x - 1.0, top + 1.0, pipe_z + side * half), &"structure")
			box(Vector3(x + 1.0, 0.0, pipe_z + side * (half - 0.08)), Vector3(x + 1.06, top + 1.0, pipe_z + side * half), &"structure")
		for rail: float in [-1.03, 1.03]:
			box(Vector3(x + rail - 0.03, top + 0.95, pipe_z - half), Vector3(x + rail + 0.03, top + 1.0, pipe_z + half), &"structure")
		lamp_post(Vector3(x + 1.8, 0.0, pipe_z - half - run - 0.6), 4.2, SliceMaterials.COOL, &"lamp_cool", 1.8, 16.0)
	else:
		# Two long boards leaning on the lagging from either side, a crate as a step.
		for side: float in [-1.0, 1.0]:
			ramp(Vector3(x, 0.0, pipe_z + side * (half + run + 0.6)), Vector3(x, top - 0.08, pipe_z + side * (half - 0.5)), 0.95, &"wood", 0.07)
		box(Vector3(x - 0.5, top - 0.2, pipe_z - half + 0.5), Vector3(x + 0.5, top - 0.1, pipe_z + half - 0.5), &"wood_dark", true)
		box(Vector3(x + 0.7, 0.0, pipe_z - half - run), Vector3(x + 1.3, 0.5, pipe_z - half - run + 0.6), &"wood_dark", true)


## People warming themselves at the pipe: a floodlamp, a glowing bleed valve, a
## tarp, a crate or two (reference 594s).
func _camp(x: float, side: float, rng: RandomNumberGenerator, statics: Array) -> void:
	var zs := pipe_z + side * (PIPE_D * 0.5)
	# Lamp post with an angled flood head.
	var lp := Vector3(x + rng.randf_range(-1.0, 1.0), 0.0, zs + side * 1.7)
	box(lp + Vector3(-0.09, 0, -0.09), lp + Vector3(0.09, 5.4, 0.09), &"structure", true)
	rbox(lp + Vector3(0.0, 5.45, -side * 0.55), Vector3(0.5, 0.22, 0.8), Vector3(side * 0.5, 0, 0), &"structure")
	rbox(lp + Vector3(0.0, 5.34, -side * 0.6), Vector3(0.38, 0.05, 0.62), Vector3(side * 0.5, 0, 0), &"bulb")
	var fl := SliceMaterials.make_lamp_light(Color(1.0, 0.74, 0.46), 2.3, 17.0)
	fl.position = lp + Vector3(0, 4.6, -side * 0.9)
	add_child(fl)
	glow(lp + Vector3(0, 5.3, -side * 0.6), &"corona")
	# Bleed valve on the pipe, glowing: where the heat comes out.
	var vx := x + rng.randf_range(3.0, 6.5)
	box(Vector3(vx - 0.28, PIPE_Y + PIPE_D * 0.42, pipe_z - 0.28), Vector3(vx + 0.28, PIPE_Y + PIPE_D * 0.5 + 0.34, pipe_z + 0.28), &"structure")
	box(Vector3(vx - 0.2, PIPE_Y + PIPE_D * 0.5 + 0.34, pipe_z - 0.2), Vector3(vx + 0.2, PIPE_Y + PIPE_D * 0.5 + 0.44, pipe_z + 0.2), &"drill_glow")
	glow(Vector3(vx, PIPE_Y + PIPE_D * 0.5 + 0.6, pipe_z), &"corona_molten")
	var hl := SliceMaterials.make_lamp_light(Color(1.0, 0.5, 0.18), 1.5, 10.0)
	hl.position = Vector3(vx, PIPE_Y + PIPE_D * 0.5 + 0.9, pipe_z + side * 0.6)
	add_child(hl)
	# People standing with their backs or hands to it.
	for k in 2 + rng.randi() % 4:
		var px := x + rng.randf_range(-2.5, 8.0)
		statics.append({ "p": Vector3(px, 0.0, zs + side * rng.randf_range(0.35, 1.3)), "yaw": (PI if side > 0.0 else 0.0) + rng.randf_range(-0.6, 0.6) })
	# Crates, a tarp on poles, bedrolls under it.
	for k in 1 + rng.randi() % 2:
		var cs := rng.randf_range(0.5, 0.75)
		var cp := Vector3(x + rng.randf_range(-3.0, 9.0), 0.0, zs + side * rng.randf_range(2.4, 3.6))
		box(cp + Vector3(0, -0.03 - 0.02 * float(k), 0), cp + Vector3(cs, cs * 0.8, cs), &"wood_dark" if k == 0 else &"container_grey", true)
	if rng.randf() < 0.75:
		var t0 := Vector3(x + rng.randf_range(7.0, 10.0), 0.0, zs + side * 0.4)
		for ax: float in [0.0, 3.4]:
			box(t0 + Vector3(ax - 0.03, 0, side * 2.7 - 0.03), t0 + Vector3(ax + 0.03, 1.7, side * 2.7 + 0.03), &"structure")
		rbox(t0 + Vector3(1.7, 2.02, side * 1.3), Vector3(3.8, 0.04, 3.0), Vector3(side * 0.22, 0, 0), &"awning_dark")
		box(t0 + Vector3(0.4, 0.008, side * 0.5), t0 + Vector3(2.3, 0.12, side * 0.5 + side * 0.8), &"fabric")
		box(t0 + Vector3(0.4, 0.12, side * 0.55), t0 + Vector3(1.5, 0.17, side * 0.5 + side * 0.75), &"fabric_dark")
	# A sheet of meltwater on the plates.
	if rng.randf() < 0.6:
		var wp := Vector3(x + rng.randf_range(4.0, 12.0), 0.0, zs + side * rng.randf_range(3.5, 6.0))
		box(wp + Vector3(0, 0.004, 0), wp + Vector3(rng.randf_range(2.5, 4.5), 0.016, rng.randf_range(0.8, 1.6)), &"water")


## Pier out over the void to the brink lift (EL-0413-S, cage centre x -1368, 4 m past
## the edge), and the far light on its mast that can be seen from the residential
## streets kilometres to the north.
func _lift_pier(z_edge: float) -> void:
	var cage := Vector2(-1368.0, z_edge + 4.0)
	var x0 := cage.x - 10.0
	var x1 := cage.x - 2.1
	# Starts at the edge itself and sits 3 cm proud, so it never shares a face with the floor.
	box(Vector3(x0, -0.6, z_edge - 4.0), Vector3(x1, 0.03, cage.y + 3.0), &"plate", true, true)
	box(Vector3(x0, 0.0, cage.y + 2.9), Vector3(x1, 1.1, cage.y + 3.0), &"structure", true)
	box(Vector3(x0, 0.0, z_edge + 0.2), Vector3(x0 + 0.1, 1.1, cage.y + 2.9), &"structure", true)
	lamp_post(Vector3(x0 + 1.0, 0.0, z_edge - 6.0), 5.0, SliceMaterials.COOL, &"lamp_cool", 2.2, 20.0)
	# Plate sign on two posts, facing the way you arrive.
	box(Vector3(x0 + 1.6, 1.5, z_edge - 7.0), Vector3(x0 + 6.4, 2.7, z_edge - 6.92), &"container_grey")
	for sp: float in [x0 + 1.9, x0 + 6.1]:
		box(Vector3(sp - 0.05, 0.0, z_edge - 6.92), Vector3(sp + 0.05, 2.7, z_edge - 6.84), &"structure", true)
	SliceMaterials.add_sign(self, Vector3(x0 + 4.0, 2.1, z_edge - 7.01), "BRINK LIFT  EL-0413-S\nTOP FLOOR  ·  18.1 KM UP", 0.0095, Color(0.5, 0.6, 0.72), PI)
	# The beacon: high on the mast, on the axis of the long street (x = -1375).
	var b := Vector3(-1375.0, 96.0, z_edge + 1.0)
	box(b + Vector3(-0.2, -96.0, -0.2), b + Vector3(0.2, 0.0, 0.2), &"rust_steel")
	box(b + Vector3(-0.3, 0.0, -0.3), b + Vector3(0.3, 0.6, 0.3), &"lamp_cool")
	SliceMaterials.add_coronas(self, [b + Vector3(0, 0.6, 0)], 46.0, &"corona_beacon").extra_cull_margin = 60.0


## The open edge: no wall, only the cut ends of the floor steel reaching into the void.
func _edge(xa: float, xb: float, z_edge: float, rng: RandomNumberGenerator) -> void:
	var x := xa + 20.0
	var k := 0
	while x < xb:
		var reach := rng.randf_range(4.0, 16.0)
		var y := -rng.randf_range(0.9, 2.5) - 0.03 * float(k % 7)
		box(Vector3(x - 0.35, y - 0.7, z_edge - 3.0), Vector3(x + 0.35, y, z_edge + reach), &"rust_steel")
		if rng.randf() < 0.35:
			# A lone unfinished column right at the brink.
			var h := rng.randf_range(8.0, 40.0)
			box(Vector3(x + 6.0, 0.0, z_edge - 6.9), Vector3(x + 6.9, h, z_edge - 6.0), &"rust_steel", true)
		x += rng.randf_range(28.0, 70.0)
		k += 1
