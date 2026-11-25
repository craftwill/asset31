class_name CathedralDeep
extends SiteKit
## The Cathedral of the Deep, on the unheated top floor of STK-0413: an old load
## frame of the megastructure that the Continuum has kept as a holy place for longer
## than anyone can say. The marked route from the Brink Lift runs straight through
## its nave, under the Void Bell: a stepped, angular shell of overlapping plates the
## size of a city block, hung between twelve piers with its striker showing below
## the rim. It is the physical home of the bell that is heard across the Mantle; the
## sound itself is the existing VoidBell bus and is not touched here.
## Local coordinates: stack-local x/z, y = 0 at the ice (child of the FrozenFloor anchor).

const CENTRE := Vector2(-1375.0, 2150.0)
const HALF_X := 62.0
const HALF_Z := 84.0
const PIER_X := 36.0
const PIER_H := 150.0
const RIM_Y := 38.0

var _rng := RandomNumberGenerator.new()


static func build() -> CathedralDeep:
	var c := CathedralDeep.new()
	c.name = "SITE-CATHEDRAL-DEEP"
	c._build()
	return c


## Footprint (with margin) that the frozen floor keeps clear of wrecks and posts.
static func footprint() -> Rect2:
	return Rect2(CENTRE.x - HALF_X - 14.0, CENTRE.y - HALF_Z - 30.0, (HALF_X + 14.0) * 2.0, (HALF_Z + 30.0) * 2.0)


func _build() -> void:
	_rng.seed = 41407
	var c := Vector3(CENTRE.x, 0.0, CENTRE.y)
	_piers(c)
	_roof_frame(c)
	_portal(c, 1.0)
	_portal(c, -1.0)
	_bell(c)
	_floor_and_rites(c)
	flush()


## Twelve piers in two rows: stepped bases, a deep recess up each inner face, and here
## and there a maintenance platform small enough to show how big the piers are.
func _piers(c: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		for i in 6:
			var z := -65.0 + float(i) * 26.0
			var p := c + Vector3(side * PIER_X, 0.0, z)
			box(p + Vector3(-7.0, -0.4, -7.0), p + Vector3(7.0, 16.0, 7.0), &"structure", true)
			box(p + Vector3(-5.6, 16.0, -5.6), p + Vector3(5.6, 34.0, 5.6), &"structure", true)
			box(p + Vector3(-4.5, 34.0, -4.5), p + Vector3(4.5, PIER_H, 4.5), &"structure")
			# Recess: two fins leave a dark slot down the nave face.
			for f: float in [-1.0, 1.0]:
				box(p + Vector3(-side * 5.6, 34.0, f * 3.4 - 0.5), p + Vector3(-side * 4.5, PIER_H - 6.0, f * 3.4 + 0.5), &"structure")
			# Frost and ice at the foot, on the windward side.
			box(p + Vector3(-7.6, -0.3, 6.2), p + Vector3(7.6, _rng.randf_range(1.5, 5.0), 8.4), &"ice")
			# Outer buttress leaning in (a flying brace of plain plate).
			rbox(p + Vector3(side * 13.0, 30.0, 0.0), Vector3(3.0, 66.0, 5.0), Vector3(0, 0, side * 0.34), &"structure")
			box(p + Vector3(side * 20.0, -0.4, -4.0), p + Vector3(side * 27.0, 7.0, 4.0), &"structure", true)
			# Maintenance platforms with a rail and one amber lamp.
			for h: float in [46.0, 92.0]:
				if _rng.randf() < 0.6:
					var q := p + Vector3(-side * 6.2, h, 0.0)
					box(q + Vector3(-1.7, -0.15, -2.4), q + Vector3(1.7, 0.0, 2.4), &"plate")
					box(q + Vector3(-side * 1.7 - 0.04, 0.0, -2.4), q + Vector3(-side * 1.7 + 0.04, 1.05, 2.4), &"structure")
					box(q + Vector3(-0.12, 1.9, -0.12), q + Vector3(0.12, 2.05, 0.12), &"lamp")
					glow(q + Vector3(0, 2.0, 0), &"corona_soft")
			# The three rings on the foot of every second pier, cut into a plate.
			if i % 2 == 1:
				box(p + Vector3(-side * 6.9, 2.2, -1.6), p + Vector3(-side * 7.12, 8.2, 1.6), &"container_grey")
				var e := ContinuumEmblem.create(1.5, &"copper", &"structure", false)
				e.position = p + Vector3(-side * 7.22, 5.2, 0.0)
				e.rotation.y = -side * PI * 0.5
				add_child(e)


## Girders tying the pier heads together, and the hangers the bell is slung from.
func _roof_frame(c: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		box(c + Vector3(side * PIER_X - 3.0, PIER_H, -70.0), c + Vector3(side * PIER_X + 3.0, PIER_H + 7.0, 70.0), &"structure")
	for i in 6:
		var z := -65.0 + float(i) * 26.0
		box(c + Vector3(-PIER_X - 4.0, PIER_H + 7.0, z - 2.4), c + Vector3(PIER_X + 4.0, PIER_H + 13.0, z + 2.4), &"structure")
		# Lower tie with a hollow box section.
		box(c + Vector3(-PIER_X + 4.5, 118.0, z - 1.2), c + Vector3(PIER_X - 4.5, 121.0, z + 1.2), &"structure")
	# Suspension: four massive arms from the middle piers down to the crown, plus cables.
	var crown_y := 106.0
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var a := c + Vector3(sx * (PIER_X - 4.5), 121.0, sz * 13.0)
			var b := c + Vector3(sx * 7.0, crown_y, sz * 5.0)
			var mid := (a + b) * 0.5
			var arm := SliceMaterials.add_cylinder(self, a, b, 1.3, &"structure", 6)
			arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			box(mid + Vector3(-1.8, -1.0, -1.8), mid + Vector3(1.8, 1.0, 1.8), &"structure")
			SliceMaterials.add_cylinder(self, c + Vector3(sx * 4.0, crown_y, sz * 4.0), c + Vector3(sx * 4.0, PIER_H + 7.0, sz * 4.0), 0.22, &"structure", 6)


## Entrance at one end of the nave: two pylons and a lintel carrying the symbol.
func _portal(c: Vector3, end: float) -> void:
	var z := end * HALF_Z
	for sx: float in [-1.0, 1.0]:
		box(c + Vector3(sx * 21.0 - 6.0, -0.4, z - 5.0), c + Vector3(sx * 21.0 + 6.0, 58.0, z + 5.0), &"structure", true)
		box(c + Vector3(sx * 21.0 - 4.0, 58.0, z - 3.5), c + Vector3(sx * 21.0 + 4.0, 84.0, z + 3.5), &"structure")
		box(c + Vector3(sx * 15.6, -0.3, z + end * 4.6), c + Vector3(sx * 26.4, 3.2, z + end * 6.8), &"ice")
	box(c + Vector3(-27.8, 40.0, z - 4.0), c + Vector3(27.8, 52.0, z + 4.0), &"structure")
	# Entrance plate with the three rings, facing out.
	box(c + Vector3(-5.0, 41.0, z + end * 4.0), c + Vector3(5.0, 51.0, z + end * 4.14), &"container_grey")
	var e := ContinuumEmblem.create(2.6, &"copper", &"structure", false)
	e.position = c + Vector3(0.0, 46.0, z + end * 4.3)
	e.rotation.y = 0.0 if end > 0.0 else PI
	add_child(e)
	for sx: float in [-1.0, 1.0]:
		box(c + Vector3(sx * 14.6 - 0.2, 5.2, z + end * 5.0), c + Vector3(sx * 14.6 + 0.2, 5.5, z + end * 5.5), &"lamp")
		glow(c + Vector3(sx * 14.6, 5.35, z + end * 5.6), &"corona_soft")
		var l := SliceMaterials.make_lamp_light(SliceMaterials.WARM, 1.4, 22.0)
		l.position = c + Vector3(sx * 13.0, 5.0, z + end * 7.0)
		add_child(l)


## One ring of `n` plates around the bell's axis.
func _ring(c: Vector3, y0: float, y1: float, r: float, n: int, twist: float, thick: float, mat: StringName, lean := 0.0) -> void:
	var chord := 2.0 * r * tan(PI / float(n)) + thick * 0.6
	for i in n:
		var ang := float(i) * TAU / float(n) + twist
		var p := c + Vector3(cos(ang) * r, (y0 + y1) * 0.5, sin(ang) * r)
		rbox(p, Vector3(chord, y1 - y0, thick), Vector3(lean, -ang + PI * 0.5, 0.0), mat)


## The Void Bell: five stepped tiers of overlapping plates, each twisted against the
## last, eight ribs, amber seams, a hollow mouth and a striker hanging through it.
func _bell(c: Vector3) -> void:
	# [y0, y1, radius, sides, twist]
	var tiers := [
		[RIM_Y, RIM_Y + 16.0, 31.0, 8, 0.0],
		[RIM_Y + 14.0, RIM_Y + 28.0, 26.5, 8, PI / 8.0],
		[RIM_Y + 26.0, RIM_Y + 40.0, 21.0, 6, 0.0],
		[RIM_Y + 38.0, RIM_Y + 52.0, 15.0, 6, PI / 6.0],
		[RIM_Y + 50.0, RIM_Y + 62.0, 9.5, 4, PI / 4.0],
	]
	for i in tiers.size():
		var t: Array = tiers[i]
		_ring(c, t[0], t[1], t[2], t[3], t[4], 3.4 - float(i) * 0.3, &"structure", 0.0)
		# Shoulder plate closing the step to the next tier, tipped outward like a skirt.
		_ring(c, float(t[1]) - 1.2, float(t[1]) + 0.6, float(t[2]) - 2.4, t[3], t[4], 6.0, &"structure")
		# Amber seam where the tiers overlap.
		_ring(c, float(t[0]) + 0.5, float(t[0]) + 0.9, float(t[2]) + 1.85 - float(i) * 0.15, t[3], t[4], 0.25, &"gallery_strip")
	# Lip plates flaring below the rim, alternate ones cut short (irregular mouth).
	for i in 8:
		var ang := float(i) * TAU / 8.0
		var drop := 7.0 if i % 2 == 0 else 3.0
		var p := c + Vector3(cos(ang) * 33.2, RIM_Y - drop * 0.5 + 0.5, sin(ang) * 33.2)
		rbox(p, Vector3(18.0, drop, 1.6), Vector3(0.0, -ang + PI * 0.5, 0.0), &"structure")
	# Eight thick ribs up the outside, stepping in with the tiers.
	for i in 8:
		var ang := float(i) * TAU / 8.0 + PI / 8.0
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		for k in 3:
			var r0 := [33.5, 24.0, 13.5][k] as float
			var ya := [RIM_Y - 2.0, RIM_Y + 24.0, RIM_Y + 46.0][k] as float
			var yb := [RIM_Y + 26.0, RIM_Y + 48.0, RIM_Y + 66.0][k] as float
			rbox(c + dir * r0 + Vector3(0, (ya + yb) * 0.5, 0), Vector3(2.6, yb - ya, 4.2), Vector3(0.0, -ang + PI * 0.5, 0.0), &"structure")
	# Crown block and yoke.
	box(c + Vector3(-8.0, RIM_Y + 60.0, -6.0), c + Vector3(8.0, RIM_Y + 70.0, 6.0), &"structure")
	box(c + Vector3(-12.0, RIM_Y + 64.0, -2.5), c + Vector3(12.0, RIM_Y + 68.0, 2.5), &"structure")
	# The striker: a six-sided mass on a shaft, its foot showing below the mouth.
	SliceMaterials.add_cylinder(self, c + Vector3(0, RIM_Y + 60.0, 0), c + Vector3(0, RIM_Y + 6.0, 0), 1.1, &"structure", 6)
	SliceMaterials.add_cylinder(self, c + Vector3(0, RIM_Y + 8.0, 0), c + Vector3(0, RIM_Y - 9.0, 0), 7.5, &"structure", 6)
	SliceMaterials.add_cylinder(self, c + Vector3(0, RIM_Y - 9.0, 0), c + Vector3(0, RIM_Y - 12.0, 0), 5.0, &"copper", 6)
	# A dull glow inside the hollow, so the mouth reads as a chamber from below.
	var inner := SliceMaterials.make_lamp_light(Color(1.0, 0.6, 0.28), 2.6, 60.0)
	inner.position = c + Vector3(0, RIM_Y + 14.0, 0)
	inner.distance_fade_begin = 500.0
	add_child(inner)
	# Inspection gantry hung under the rim: a human-sized thing beside the bell.
	box(c + Vector3(-36.0, RIM_Y - 16.2, -1.2), c + Vector3(-9.0, RIM_Y - 16.0, 1.2), &"plate")
	for rz: float in [-1.2, 1.2]:
		box(c + Vector3(-36.0, RIM_Y - 15.0, rz - 0.04), c + Vector3(-9.0, RIM_Y - 14.94, rz + 0.04), &"structure")
	for hx: float in [-34.0, -22.0, -10.5]:
		box(c + Vector3(hx - 0.06, RIM_Y - 16.0, -1.26), c + Vector3(hx + 0.06, RIM_Y - 3.0, -1.14), &"structure")
		box(c + Vector3(hx - 0.06, RIM_Y - 16.0, 1.14), c + Vector3(hx + 0.06, RIM_Y - 3.0, 1.26), &"structure")
	box(c + Vector3(-36.0, RIM_Y - 16.2, -1.2), c + Vector3(-36.6, RIM_Y - 14.0, 1.2), &"structure")
	box(c + Vector3(-22.2, RIM_Y - 14.2, -0.2), c + Vector3(-21.8, RIM_Y - 14.0, 0.2), &"lamp")
	glow(c + Vector3(-22.0, RIM_Y - 14.1, 0.0), &"corona_soft")


## What generations of keepers have left on the floor beneath it.
func _floor_and_rites(c: Vector3) -> void:
	# The worn way down the nave: bare dark plate where the frost never settles.
	box(c + Vector3(-2.6, -0.2, -HALF_Z - 22.0), c + Vector3(2.6, 0.035, HALF_Z + 22.0), &"plate", true, true)
	# Ceremonial dais under the mouth: three shallow steps, walked over by the route.
	for k in 3:
		var h := 12.0 - float(k) * 3.0
		box(c + Vector3(-h, -0.26 - 0.05 * float(k), -h), c + Vector3(h, 0.18 * float(k + 1), h), &"concrete", true)
	# The route keeps to the middle; the altar stands to one side of it.
	var a := c + Vector3(6.2, 0.54, 0.0)
	box(a + Vector3(-1.1, 0.0, -1.8), a + Vector3(1.1, 1.0, 1.8), &"concrete", true)
	box(a + Vector3(-1.2, 1.0, -1.9), a + Vector3(1.2, 1.06, 1.9), &"cloth_red")
	for k in 7:
		var vz := -1.5 + float(k) * 0.5
		box(a + Vector3(-0.5 + 0.11 * float(k % 3), 1.06, vz - 0.03), a + Vector3(-0.44 + 0.11 * float(k % 3), 1.14 + 0.03 * float(k % 4), vz + 0.03), &"bulb" if k % 3 != 1 else &"ceramic")
	var al := SliceMaterials.make_lamp_light(Color(1.0, 0.62, 0.3), 1.2, 12.0)
	al.position = a + Vector3(-0.6, 1.6, 0.0)
	add_child(al)
	var e := ContinuumEmblem.create(0.7, &"copper", &"structure", false)
	e.position = a + Vector3(0.6, 2.4, 0.0)
	e.rotation.y = -PI * 0.5
	add_child(e)
	# Abandoned things: bowls, a folded cloth, a toppled stand, rope coils.
	for k in 6:
		var o := c + Vector3(_rng.randf_range(-9.0, -4.0), 0.54, _rng.randf_range(-8.0, 8.0))
		var s := _rng.randf_range(0.14, 0.3)
		box(o + Vector3(-s, 0.0, -s), o + Vector3(s, s * 0.7, s), &"ceramic" if k % 2 == 0 else &"copper")
	box(c + Vector3(-7.5, 0.54, 4.0), c + Vector3(-6.3, 0.6, 5.4), &"cloth_beige")
	rbox(c + Vector3(-8.4, 0.9, -5.0), Vector3(0.12, 1.7, 0.12), Vector3(0.0, 0.3, 1.2), &"structure")
	# Small shrines where the lower ties meet the piers: a niche, a lamp, offerings.
	for side: float in [-1.0, 1.0]:
		for z: float in [-39.0, 39.0]:
			var s0 := c + Vector3(side * (PIER_X - 8.4), 0.0, z * side)
			box(s0 + Vector3(-0.9, 0.0, -1.2), s0 + Vector3(0.9, 1.5, 1.2), &"concrete", true)
			box(s0 + Vector3(-0.2, 1.5, -0.2), s0 + Vector3(0.2, 1.62, 0.2), &"bulb")
			glow(s0 + Vector3(0, 1.7, 0), &"corona_soft")
			box(s0 + Vector3(-1.0, -0.2, -1.3), s0 + Vector3(1.0, 0.25, -1.9), &"ice")
			var sl := SliceMaterials.make_lamp_light(Color(1.0, 0.62, 0.3), 0.9, 9.0)
			sl.position = s0 + Vector3(-side * 0.8, 1.9, 0.0)
			add_child(sl)
	# Evidence of repair: a patch plate bolted over a pier foot, a stack of spare plate.
	box(c + Vector3(-PIER_X + 7.0, 3.0, 11.0), c + Vector3(-PIER_X + 7.16, 9.0, 16.0), &"container_rust")
	for k in 4:
		box(c + Vector3(PIER_X - 14.0, 0.0 + 0.22 * float(k), 20.0), c + Vector3(PIER_X - 10.0, 0.2 + 0.22 * float(k), 23.0), &"plate" if k % 2 == 0 else &"container_grey")
	# Faded inscription by the south entrance.
	add_child(ReadableNote.create(
		"NOTE-CATHEDRAL-DEEP", "Worn Plate At The Threshold",
		"CATHEDRAL OF THE DEEP\n\n"
		+ "...one structure. Matter, life, memory...\n"
		+ "What is joined is kept. What is kept is joined.\n\n"
		+ "The bell was hung before the count of floors was begun.\n"
		+ "It does not call anyone. It answers the structure.\n\n"
		+ "Do not sever. Repair what you pass.",
		c + Vector3(15.4, 1.5, HALF_Z + 5.06), 0.0))
