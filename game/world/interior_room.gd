class_name InteriorRoom
extends Node3D
## One streamed, enterable ground-floor room (see InteriorKit for the plan and frame).
## Builds the shell behind the facade cut-outs (street wall with real door and window
## openings, trims that straddle the facade plane, glass) and furnishes it from one of
## six templates. Every template lays itself out from the room's size and a per-building
## seed, so the same six read as different rooms: mirrored plans, different counts,
## positions, cloth colours, clutter, lighting and the odd loot container.
##
## Template code works in (t, y, s): t metres from the left wall (mirrored on half the
## rooms), s metres in from the street wall.

const NAMES := ["UNIT", "RECORDS", "REPAIR", "STORES", "CANTEEN", "CONTINUUM", "BATHS", "LAUNDRY", "WATER RATION"]
const CLOTHS: Array[StringName] = [&"cloth_red", &"cloth_teal", &"cloth_beige", &"fabric_dark", &"cloth_magenta"]
const CRATES: Array[StringName] = [&"wood_dark", &"container_rust", &"container_teal", &"container_grey", &"wood"]
const LOOT_ITEMS := ["ration_tin", "dried_strip", "condensate_can", "water_flask", "bandage_roll", "fuse_cell", "brass_coil", "salvaged_relay"]

var plan: Dictionary
var rng := RandomNumberGenerator.new()
var x0 := 0.0
var x1 := 0.0
var w := 0.0            # clear width along the facade
var d := 0.0            # clear depth behind the street wall
var lit := true
var cool := false
var ceil_y := InteriorKit.CEIL_Y
var ruin := false

var _mirror := false
var _door_t := 0.0
var _items: Dictionary = {}
var _body: StaticBody3D
var _wall: StringName = &"plaster"
var _floor: StringName = &"concrete_floor"
var _loot: LootContainer
var _loot_t := -100.0


static func build(stack: StackRuntime, b: Dictionary) -> InteriorRoom:
	var r := InteriorRoom.new()
	r.plan = b.door
	r.transform = InteriorKit.xform(b)
	r.cool = stack.is_cool()
	r._build(String(stack.def.id))
	return r


func _build(stack_id: String) -> void:
	rng.seed = int(plan.seed) * 7919 + 13
	var sp := InteriorKit.span(plan)
	x0 = sp.x
	x1 = sp.y
	w = x1 - x0
	d = float(plan.depth) - InteriorKit.WALL_T
	lit = bool(plan.lit)
	ceil_y = float(plan.ceil)
	ruin = bool(plan.ruin)
	_mirror = rng.randf() < 0.5
	_door_t = x1 if _mirror else -x0
	_body = StaticBody3D.new()
	_body.name = "Furniture"
	add_child(_body)
	var tpl: int = plan.tpl
	match tpl:
		InteriorKit.Tpl.DWELLING:
			_wall = &"plaster_cool" if cool else &"plaster"
			_floor = &"floor_wood"
		InteriorKit.Tpl.BUREAU:
			_wall = &"preserve_wall"
		InteriorKit.Tpl.WORKSHOP:
			_wall = &"plate"
			_body.set_meta(&"surface", "metal")
		InteriorKit.Tpl.DEPOT:
			_wall = &"concrete"
		InteriorKit.Tpl.CANTEEN:
			_wall = &"plaster"
			_floor = &"floor_wood" if rng.randf() < 0.5 else &"concrete_floor"
		InteriorKit.Tpl.SHRINE:
			_wall = &"concrete"
		InteriorKit.Tpl.BATHHOUSE:
			_wall = &"tile_cool"
		InteriorKit.Tpl.LAUNDRY:
			_wall = &"plaster_cool"
		InteriorKit.Tpl.RATION_HALL:
			_wall = &"concrete"
	_shell()
	if rng.randf() < InteriorKit.LOOT_CHANCE:
		_add_loot(stack_id, tpl)
	match tpl:
		InteriorKit.Tpl.DWELLING: _dwelling()
		InteriorKit.Tpl.BUREAU: _bureau()
		InteriorKit.Tpl.WORKSHOP: _workshop()
		InteriorKit.Tpl.DEPOT: _depot()
		InteriorKit.Tpl.CANTEEN: _canteen()
		InteriorKit.Tpl.SHRINE: _shrine()
		InteriorKit.Tpl.BATHHOUSE: _bathhouse()
		InteriorKit.Tpl.LAUNDRY: _laundry()
		InteriorKit.Tpl.RATION_HALL: _ration_hall()
	if ruin:
		_debris()
	_lights(tpl)
	_sign(tpl)
	for mat: StringName in _items:
		SliceMaterials.add_multimesh(self, _items[mat], mat)


func _exit_tree() -> void:
	# Remember what the player did to the container while the room is streamed out.
	if _loot != null and (_loot.opened or InteriorKit.loot_state.has(_loot.container_id)):
		InteriorKit.loot_state[_loot.container_id] = _loot.serialize()


# ---------------------------------------------------------------- primitives

## Box between two room-local corners.
func _bx(a: Vector3, b: Vector3, mat: StringName, solid := false) -> void:
	var size := (b - a).abs()
	if size.x < 0.002 or size.y < 0.002 or size.z < 0.002:
		return
	if not _items.has(mat):
		_items[mat] = []
	_items[mat].append({ "c": (a + b) * 0.5, "s": size })
	if solid:
		SliceMaterials.add_collision_box(_body, (a + b) * 0.5, size)


func _px(t: float) -> float:
	return (x1 - t) if _mirror else (x0 + t)


## Template-space point -> room-local.
func _p(t: float, y: float, s: float) -> Vector3:
	return Vector3(_px(t), y, InteriorKit.WALL_T + s)


## Box in template space: t0..t1 along the facade, s0..s1 into the room.
func _r(t0: float, t1: float, y0: float, y1: float, s0: float, s1: float, mat: StringName, solid := false) -> void:
	_bx(_p(t0, y0, s0), _p(t1, y1, s1), mat, solid)


## True when a footprint keeps the doorway and the walk in from it clear.
func _free(t0: float, t1: float, s0: float, s1: float) -> bool:
	if t0 < 0.0 or t1 > w or s0 < 0.0 or s1 > d:
		return false
	if s0 < 1.1 and t1 > _loot_t - 0.9 and t0 < _loot_t + 0.9:
		return false
	return s0 > 2.0 or t1 < _door_t - 1.25 or t0 > _door_t + 1.25


func _pick(arr: Array) -> StringName:
	return arr[rng.randi() % arr.size()]


# ---------------------------------------------------------------- shell

func _shell() -> void:
	var wt := InteriorKit.WALL_T
	var st := InteriorKit.SHELL_T
	var cy := ceil_y
	var depth: float = plan.depth
	var top := cy + 0.1
	# Floor overlay, ceiling, side and back walls (each bites into its neighbours, so no
	# two visible faces are ever coplanar).
	_bx(Vector3(x0 - 0.1, -0.2, 0.07), Vector3(x1 + 0.1, InteriorKit.FLOOR_Y, depth + 0.1), _floor)
	_bx(Vector3(x0 - 0.1, cy, 0.1), Vector3(x1 + 0.1, cy + 0.2, depth + 0.1), &"concrete")
	_bx(Vector3(x0 - st, -0.1, 0.07), Vector3(x0, top, depth + st), _wall)
	_bx(Vector3(x1, -0.1, 0.07), Vector3(x1 + st, top, depth + st), _wall)
	_bx(Vector3(x0 - 0.1, -0.1, depth), Vector3(x1 + 0.1, top, depth + st), _wall)
	# Street wall, bay by bay, 6 cm behind the facade plane.
	var z0 := 0.06
	for j in range(-int(plan.left), int(plan.right) + 1):
		var xb := float(j) * InteriorKit.BAY
		var b0 := xb - InteriorKit.BAY * 0.5
		var b1 := xb + InteriorKit.BAY * 0.5
		if j == 0:
			_door_bay(z0, wt, top)
			continue
		var hw := InteriorKit.WIN_HW
		var y0 := InteriorKit.WIN_Y0
		var y1 := InteriorKit.WIN_Y1
		_bx(Vector3(b0, -0.1, z0), Vector3(b1, y0, wt), _wall)
		_bx(Vector3(b0, y1, z0), Vector3(b1, top, wt), _wall)
		_bx(Vector3(b0, y0, z0), Vector3(xb - hw, y1, wt), _wall)
		_bx(Vector3(xb + hw, y0, z0), Vector3(b1, y1, wt), _wall)
		# Window trim straddling the facade plane, so the cut edge is always covered.
		_bx(Vector3(xb - hw - 0.05, y0 - 0.05, -0.05), Vector3(xb - hw + 0.04, y1 + 0.05, wt + 0.02), &"structure")
		_bx(Vector3(xb + hw - 0.04, y0 - 0.05, -0.05), Vector3(xb + hw + 0.05, y1 + 0.05, wt + 0.02), &"structure")
		_bx(Vector3(xb - hw + 0.04, y1 - 0.04, -0.05), Vector3(xb + hw - 0.04, y1 + 0.05, wt + 0.02), &"structure")
		_bx(Vector3(xb - hw + 0.04, y0 - 0.05, -0.07), Vector3(xb + hw - 0.04, y0 + 0.04, wt + 0.06), &"structure")
		# Mullions and the pane.
		_bx(Vector3(xb - 0.025, y0 + 0.04, 0.11), Vector3(xb + 0.025, y1 - 0.04, 0.19), &"structure")
		_bx(Vector3(xb - hw + 0.04, 1.72, 0.12), Vector3(xb + hw - 0.04, 1.77, 0.18), &"structure")
		_bx(Vector3(xb - hw + 0.03, y0 + 0.03, 0.14), Vector3(xb + hw - 0.03, y1 - 0.03, 0.16), &"glass")


func _door_bay(z0: float, wt: float, top: float) -> void:
	var hw := InteriorKit.DOOR_HW
	var dh := InteriorKit.DOOR_H
	var half := InteriorKit.BAY * 0.5
	_bx(Vector3(-half, -0.1, z0), Vector3(-hw, top, wt), _wall)
	_bx(Vector3(hw, -0.1, z0), Vector3(half, top, wt), _wall)
	_bx(Vector3(-hw, dh, z0), Vector3(hw, top, wt), _wall)
	# Jambs, head and threshold straddle the facade plane.
	_bx(Vector3(-hw - 0.06, 0.0, -0.05), Vector3(-hw + 0.04, dh + 0.04, wt + 0.02), &"structure")
	_bx(Vector3(hw - 0.04, 0.0, -0.05), Vector3(hw + 0.06, dh + 0.04, wt + 0.02), &"structure")
	_bx(Vector3(-hw + 0.04, dh - 0.04, -0.05), Vector3(hw - 0.04, dh + 0.04, wt + 0.02), &"structure")
	_bx(Vector3(-hw + 0.04, -0.2, -0.09), Vector3(hw - 0.04, 0.055, wt + 0.06), &"plate")
	# Door leaf standing open into the room, on the side away from the furniture run.
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var open := rng.randf_range(0.55, 1.25)
	var leaf: StringName = &"wood" if rng.randf() < 0.6 else &"plate"
	if not ruin or rng.randf() < 0.4:
		_bx(Vector3(side * (hw - 0.03), 0.07, wt + 0.03), Vector3(side * (hw + 0.03), dh - 0.08, wt + open), leaf)
	else:
		# Torn off its hinges and left lying inside.
		_bx(Vector3(side * 0.9, InteriorKit.FLOOR_Y, wt + 1.0), Vector3(side * 0.9 + 0.9, InteriorKit.FLOOR_Y + 0.06, wt + 3.1), leaf)
	# Lamp over the door, outside.
	_bx(Vector3(-0.16, dh + 0.22, -0.2), Vector3(0.16, dh + 0.32, -0.02), (&"lamp_cool" if cool else &"lamp") if lit else &"structure")


func _lights(tpl: int) -> void:
	var col := Color(1.0, 0.74, 0.46)
	var energy := rng.randf_range(1.5, 2.1)
	match tpl:
		InteriorKit.Tpl.BUREAU, InteriorKit.Tpl.DEPOT, InteriorKit.Tpl.BATHHOUSE, InteriorKit.Tpl.RATION_HALL:
			col = Color(0.82, 0.9, 1.0)
		InteriorKit.Tpl.SHRINE:
			col = Color(1.0, 0.62, 0.3)
			energy *= 0.55
		_:
			if cool and rng.randf() < 0.5:
				col = Color(0.84, 0.9, 1.0)
	var tall := ceil_y > 4.0
	var hang := ceil_y - 1.6 if tall else 2.5
	if tall:
		energy *= 1.5
	var n := (3 if w > 18.0 else 2) if w > 10.0 else 1
	for i in n:
		var t := w * (float(i) + 0.5) / float(n) + rng.randf_range(-0.6, 0.6)
		var s := d * rng.randf_range(0.42, 0.6)
		# Fixture: stem + shade, lit or dead (ruins have lost some entirely).
		if ruin and rng.randf() < 0.5:
			continue
		_r(t - 0.02, t + 0.02, hang + 0.12, ceil_y, s - 0.02, s + 0.02, &"structure")
		_r(t - 0.14, t + 0.14, hang, hang + 0.12, s - 0.14, s + 0.14, (&"lamp_cool" if col.b > 0.9 else &"bulb") if lit else &"structure")
		if lit:
			var l := OmniLight3D.new()
			l.position = _p(t, hang - 0.12, s)
			l.light_color = col
			l.light_energy = energy
			l.omni_range = 13.0 if tall else 8.5
			l.omni_attenuation = 1.3
			l.shadow_enabled = false
			l.distance_fade_enabled = true
			l.distance_fade_begin = 60.0
			l.distance_fade_length = 25.0
			add_child(l)


func _sign(tpl: int) -> void:
	var text := String(NAMES[tpl])
	if tpl == InteriorKit.Tpl.CANTEEN:
		text = ["CANTEEN", "NOODLES", "TEA", "BROTH"][rng.randi() % 4]
	elif tpl < InteriorKit.Tpl.BATHHOUSE and tpl != InteriorKit.Tpl.SHRINE and tpl != InteriorKit.Tpl.WORKSHOP:
		text = "%s %d" % [text, 10 + int(plan.seed) % 890]
	var col := Color(0.75, 0.85, 1.0) if cool else Color(1.0, 0.85, 0.55)
	if not lit:
		col = col.darkened(0.6)
	if ruin:
		# Letters have dropped off the sign.
		col = col.darkened(0.5)
		var chars := text.split("")
		for i in chars.size():
			if rng.randf() < 0.3:
				chars[i] = " "
		text = "".join(chars)
	# Painted plate over the door; the lettering sits on it rather than on bare wall.
	var half := float(text.length()) * 0.085 + 0.18
	_bx(Vector3(-half, InteriorKit.DOOR_H + 0.46, -0.035), Vector3(half, InteriorKit.DOOR_H + 0.8, -0.004), &"container_grey")
	SliceMaterials.add_sign(self, Vector3(0.0, InteriorKit.DOOR_H + 0.63, -0.045), text, 0.0095, col.darkened(0.5), PI)


func _add_loot(stack_id: String, tpl: int) -> void:
	# Against the street wall, at the end farthest from the door.
	var t := 0.75 if _door_t > w * 0.5 else w - 0.75
	_loot_t = t
	var id := "%s%s-%d" % [InteriorKit.LOOT_PREFIX, stack_id, int(plan.seed)]
	var style: String = ["cabinet", "cabinet", "locker", "crate", "cabinet", "cache", "locker", "cabinet", "crate"][tpl]
	var label: String = ["Household Cabinet", "Records Cabinet", "Tool Locker", "Stores Crate", "Pantry Cabinet", "Offering Cache", "Bathhouse Locker", "Laundry Cabinet", "Ration Crate"][tpl]
	var items: Array = []
	for i in 1 + rng.randi() % 3:
		items.append([LOOT_ITEMS[rng.randi() % LOOT_ITEMS.size()], 1])
	_loot = LootContainer.create(id, label, style, _p(t, InteriorKit.FLOOR_Y, 0.38), 0.0, items, 4, 3)
	if InteriorKit.loot_state.has(id):
		_loot.deserialize(InteriorKit.loot_state[id])
	add_child(_loot)


# ---------------------------------------------------------------- furniture

func _table(t: float, s: float, lt: float, ls: float, h := 0.74, mat: StringName = &"wood") -> bool:
	if ruin and rng.randf() < 0.45:
		return false
	if not _free(t - lt * 0.5 - 0.3, t + lt * 0.5 + 0.3, s - ls * 0.5 - 0.3, s + ls * 0.5 + 0.3):
		return false
	_r(t - lt * 0.5, t + lt * 0.5, h - 0.05, h, s - ls * 0.5, s + ls * 0.5, mat)
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			var lt0 := t + a * (lt * 0.5 - 0.08)
			var ls0 := s + b * (ls * 0.5 - 0.08)
			_r(lt0 - 0.03, lt0 + 0.03, InteriorKit.FLOOR_Y, h - 0.05, ls0 - 0.03, ls0 + 0.03, mat)
	SliceMaterials.add_collision_box(_body, _p(t, h * 0.5, s), Vector3(lt, h, ls))
	return true


func _stool(t: float, s: float, mat: StringName = &"wood_dark") -> void:
	if ruin and rng.randf() < 0.45:
		return
	if _free(t - 0.2, t + 0.2, s - 0.2, s + 0.2):
		_r(t - 0.17, t + 0.17, InteriorKit.FLOOR_Y, 0.44, s - 0.17, s + 0.17, mat, true)


func _crate(t: float, s: float, size: float, y := InteriorKit.FLOOR_Y, mat: StringName = &"") -> void:
	var h := size * 0.5
	if _free(t - h, t + h, s - h, s + h):
		_r(t - h, t + h, y, y + size * rng.randf_range(0.7, 1.0), s - h, s + h, mat if mat != &"" else _pick(CRATES), true)


## Bed along the back wall (head toward t0); `bunk` adds an upper berth.
func _bed(t0: float, bunk: bool) -> void:
	if ruin and rng.randf() < 0.45:
		return
	var s0 := d - 0.95
	if not _free(t0, t0 + 2.0, s0, d):
		return
	var cloth := _pick(CLOTHS)
	for lvl in (2 if bunk else 1):
		var y := InteriorKit.FLOOR_Y + float(lvl) * 1.25
		_r(t0, t0 + 2.0, y + 0.22, y + 0.38, s0, d - 0.03, &"wood_dark")
		_r(t0 + 0.04, t0 + 1.96, y + 0.38, y + 0.5, s0 + 0.04, d - 0.06, &"fabric")
		_r(t0 + 0.55, t0 + 1.95, y + 0.5, y + 0.55, s0 + 0.03, d - 0.05, cloth)
		_r(t0 + 0.08, t0 + 0.45, y + 0.5, y + 0.59, s0 + 0.15, d - 0.2, &"cloth_beige")
	var top := 1.95 if bunk else 0.42
	for tt: float in [t0 + 0.04, t0 + 1.96]:
		_r(tt - 0.04, tt + 0.04, InteriorKit.FLOOR_Y, top, s0, s0 + 0.08, &"wood_dark")
	SliceMaterials.add_collision_box(_body, _p(t0 + 1.0, top * 0.5, s0 + 0.47), Vector3(2.0, top, 0.95))


## Shelving against the back wall with a random load.
func _shelves(t0: float, t1: float, depth := 0.45, levels := 3) -> void:
	if ruin and rng.randf() < 0.45:
		return
	if not _free(t0, t1, d - depth, d):
		return
	for tt: float in [t0, t1 - 0.05]:
		_r(tt, tt + 0.05, InteriorKit.FLOOR_Y, 2.2, d - depth, d - 0.04, &"structure")
	for lvl in levels:
		var y := 0.45 + float(lvl) * 0.62
		_r(t0, t1, y, y + 0.04, d - depth, d - 0.03, &"wood_dark")
		var t := t0 + 0.12
		while t < t1 - 0.45:
			var cw := rng.randf_range(0.22, 0.42)
			if rng.randf() < 0.7:
				_r(t, t + cw, y + 0.04, y + 0.04 + rng.randf_range(0.14, 0.4), d - depth + 0.06, d - 0.1, _pick(CRATES))
			t += cw + rng.randf_range(0.05, 0.3)
	SliceMaterials.add_collision_box(_body, _p((t0 + t1) * 0.5, 1.1, d - depth * 0.5), Vector3(t1 - t0, 2.2, depth))


## Tins / cups on a surface.
func _clutter(t0: float, t1: float, y: float, s0: float, s1: float, n: int) -> void:
	for i in n:
		var t := rng.randf_range(t0 + 0.06, t1 - 0.06)
		var s := rng.randf_range(s0 + 0.06, s1 - 0.06)
		var r := rng.randf_range(0.03, 0.06)
		_r(t - r, t + r, y, y + rng.randf_range(0.06, 0.16), s - r, s + r, &"metal_light" if rng.randf() < 0.6 else &"ceramic")


# ---------------------------------------------------------------- templates

## Family unit: beds or bunks at the back, a table to eat at, a cooking counter,
## shelves, a rug and a line of washing.
func _dwelling() -> void:
	var beds := 1 + rng.randi() % (3 if w > 10.0 else 2)
	var t := rng.randf_range(0.1, 0.5)
	for i in beds:
		_bed(t, rng.randf() < 0.4)
		t += 2.0 + rng.randf_range(0.25, 0.9)
	# Cooking counter + shelves share what is left of the back wall.
	if w - t > 2.2:
		var c1 := minf(w - 0.1, t + rng.randf_range(1.6, 2.6))
		_r(t, c1, InteriorKit.FLOOR_Y, 0.86, d - 0.6, d - 0.03, &"plate", true)
		_r(t - 0.02, c1 + 0.02, 0.86, 0.9, d - 0.63, d - 0.03, &"wood_dark")
		_r(t + 0.2, t + 0.7, 0.9, 0.96, d - 0.5, d - 0.14, &"structure")
		_clutter(t + 0.8, c1, 0.9, d - 0.55, d - 0.1, 2 + rng.randi() % 4)
		if w - c1 > 1.4:
			_shelves(c1 + 0.2, minf(w - 0.1, c1 + 0.2 + rng.randf_range(1.1, 2.0)))
	# Table and stools, somewhere mid-room.
	var tt := rng.randf_range(1.4, w - 1.4)
	var ts := rng.randf_range(1.6, maxf(1.7, d - 2.6))
	var tl := rng.randf_range(1.0, 1.6)
	if _table(tt, ts, tl, 0.8):
		_clutter(tt - tl * 0.5, tt + tl * 0.5, 0.74, ts - 0.4, ts + 0.4, 1 + rng.randi() % 4)
		for i in 1 + rng.randi() % 4:
			var sd := -1.0 if i % 2 == 0 else 1.0
			_stool(tt + (float(i / 2) - 0.5) * 0.7, ts + sd * 0.72)
		# Rug under it.
		_r(tt - 1.2, tt + 1.2, InteriorKit.FLOOR_Y, InteriorKit.FLOOR_Y + 0.012, ts - 0.9, ts + 0.9, _pick(CLOTHS))
	# Washing line across the room.
	if rng.randf() < 0.65:
		var ls := rng.randf_range(2.2, maxf(2.3, d - 1.6))
		_r(0.0, w, 2.3, 2.315, ls - 0.008, ls + 0.008, &"structure")
		for i in 2 + rng.randi() % 5:
			var ct := rng.randf_range(0.5, w - 1.0)
			_r(ct, ct + rng.randf_range(0.4, 0.8), 2.3 - rng.randf_range(0.5, 0.95), 2.3, ls - 0.012, ls + 0.012, _pick(CLOTHS))
	for i in rng.randi() % 3:
		_crate(rng.randf_range(0.4, w - 0.4), rng.randf_range(0.4, 1.4), rng.randf_range(0.4, 0.6))


## Records bureau: a public counter, rows of desks with live terminals, filing
## cabinets along the back wall.
func _bureau() -> void:
	# Filing cabinets of uneven height across the back.
	var t := rng.randf_range(0.1, 0.6)
	while t < w - 0.7:
		var cw := rng.randf_range(0.55, 0.9)
		if rng.randf() < 0.82:
			_r(t, t + cw, InteriorKit.FLOOR_Y, rng.randf_range(1.1, 2.1), d - 0.55, d - 0.03, &"container_grey" if rng.randf() < 0.75 else &"container_teal", true)
		t += cw + (0.03 if rng.randf() < 0.7 else rng.randf_range(0.3, 0.9))
	# Desks in rows, each with a terminal and a stool.
	var screen: StringName = [&"sign_cyan", &"sign_green", &"sign_yellow"][rng.randi() % 3]
	var rows := 1 if d < 6.5 else 2
	for row in rows:
		var s := 2.4 + float(row) * 2.1 + rng.randf_range(-0.2, 0.2)
		var dt := rng.randf_range(0.9, 1.5)
		while dt < w - 0.9:
			if rng.randf() < 0.8 and _table(dt, s, 1.3, 0.7, 0.74, &"plate"):
				_r(dt - 0.22, dt + 0.22, 0.74, 1.06, s + 0.05, s + 0.3, &"structure")
				if lit and rng.randf() < 0.8:
					_r(dt - 0.18, dt + 0.18, 0.8, 1.02, s + 0.035, s + 0.05, screen)
				_clutter(dt - 0.6, dt - 0.25, 0.74, s - 0.3, s + 0.3, rng.randi() % 3)
				_stool(dt + rng.randf_range(-0.2, 0.2), s - 0.75, &"fabric_dark")
			dt += rng.randf_range(1.9, 2.6)
	# Notice board on the back wall, boxes of paper by the entrance.
	var nt := rng.randf_range(0.5, w - 2.0)
	_r(nt, nt + 1.4, 1.2, 2.1, d - 0.045, d - 0.03, &"wood")
	for i in 3 + rng.randi() % 5:
		var px := nt + rng.randf_range(0.08, 1.1)
		var py := rng.randf_range(1.28, 1.8)
		_r(px, px + 0.2, py, py + 0.26, d - 0.055, d - 0.045, &"cloth_beige")
	for i in rng.randi() % 3:
		_crate(rng.randf_range(0.4, w - 0.4), rng.randf_range(0.35, 1.2), rng.randf_range(0.35, 0.5), InteriorKit.FLOOR_Y, &"wood")


## Repair shop: long benches, a couple of machines, pipes, a tool rail, parts crates.
func _workshop() -> void:
	# Bench run along the back wall with a gap for a machine.
	var gap0 := rng.randf_range(1.5, w - 3.0)
	var gap1 := gap0 + rng.randf_range(1.4, 2.2)
	for seg: Array in [[0.1, gap0 - 0.15], [gap1 + 0.15, w - 0.1]]:
		var a: float = seg[0]
		var b: float = seg[1]
		if b - a < 0.8:
			continue
		_r(a, b, 0.84, 0.9, d - 0.75, d - 0.03, &"wood_dark")
		_r(a + 0.05, b - 0.05, InteriorKit.FLOOR_Y, 0.84, d - 0.7, d - 0.08, &"structure", true)
		_clutter(a, b, 0.9, d - 0.7, d - 0.1, 3 + rng.randi() % 6)
		# Vice / part being worked on.
		var vt := rng.randf_range(a + 0.2, b - 0.4)
		_r(vt, vt + rng.randf_range(0.2, 0.5), 0.9, 0.9 + rng.randf_range(0.12, 0.3), d - 0.6, d - 0.3, &"copper" if rng.randf() < 0.5 else &"metal_light")
	# Machine in the gap, and maybe a free-standing one.
	_r(gap0, gap1, InteriorKit.FLOOR_Y, rng.randf_range(1.3, 2.0), d - 0.95, d - 0.05, _pick([&"container_rust", &"container_teal", &"container_grey"]), true)
	_r(gap0 + 0.2, gap0 + 0.5, 1.0, 1.25, d - 1.0, d - 0.95, &"rail_glow" if lit else &"structure")
	if w > 9.0 and rng.randf() < 0.7:
		var mt := rng.randf_range(1.2, w - 2.4)
		var ms := rng.randf_range(2.4, maxf(2.5, d - 3.2))
		if _free(mt - 0.3, mt + 1.5, ms - 0.3, ms + 1.2):
			_r(mt, mt + 1.2, InteriorKit.FLOOR_Y, 1.05, ms, ms + 0.9, &"container_grey", true)
			_r(mt + 0.3, mt + 0.9, 1.05, 1.5, ms + 0.2, ms + 0.7, &"structure")
	# Tool rail on the back wall and pipes at the ceiling.
	_r(0.3, w - 0.3, 1.55, 1.6, d - 0.07, d - 0.03, &"structure")
	var tt := 0.5
	while tt < w - 0.6:
		if rng.randf() < 0.6 and (tt < gap0 - 0.2 or tt > gap1 + 0.1):
			_r(tt, tt + 0.07, 1.6 - rng.randf_range(0.25, 0.55), 1.6, d - 0.09, d - 0.05, &"metal_light")
		tt += rng.randf_range(0.18, 0.4)
	for i in 1 + rng.randi() % 3:
		var ps := rng.randf_range(0.5, d - 0.5)
		_r(0.0, w, 2.85 - float(i) * 0.02, 2.95 - float(i) * 0.02, ps, ps + 0.1, &"copper" if i == 0 else &"structure")
	for i in 2 + rng.randi() % 5:
		_crate(rng.randf_range(0.4, w - 0.4), rng.randf_range(0.4, d - 1.8), rng.randf_range(0.4, 0.75))


## Stores: racking in aisles, pallets of crates, a hazard strip at the door.
func _depot() -> void:
	var t := rng.randf_range(0.5, 1.2)
	while t < w - 1.2:
		var s0 := rng.randf_range(2.2, 2.9)
		var s1 := d - rng.randf_range(0.1, 0.9)
		if _free(t, t + 0.7, s0, s1) and rng.randf() < 0.85:
			for ss: float in [s0, s1 - 0.06]:
				for tt: float in [t, t + 0.64]:
					_r(tt, tt + 0.06, InteriorKit.FLOOR_Y, 2.7, ss, ss + 0.06, &"structure")
			for lvl in 4:
				var y := 0.2 + float(lvl) * 0.68
				_r(t, t + 0.7, y, y + 0.04, s0, s1, &"plate")
				var s := s0 + 0.1
				while s < s1 - 0.5:
					var cs := rng.randf_range(0.3, 0.6)
					if rng.randf() < 0.72:
						_r(t + 0.06, t + 0.64, y + 0.04, y + 0.04 + rng.randf_range(0.25, 0.55), s, s + cs, _pick(CRATES))
					s += cs + rng.randf_range(0.04, 0.35)
			SliceMaterials.add_collision_box(_body, _p(t + 0.35, 1.35, (s0 + s1) * 0.5), Vector3(0.7, 2.7, s1 - s0))
		t += rng.randf_range(2.0, 2.8)
	# Pallets near the front.
	for i in 2 + rng.randi() % 4:
		var pt := rng.randf_range(0.7, w - 0.7)
		var ps := rng.randf_range(0.6, 1.7)
		if _free(pt - 0.6, pt + 0.6, ps - 0.5, ps + 0.5):
			_r(pt - 0.55, pt + 0.55, InteriorKit.FLOOR_Y, InteriorKit.FLOOR_Y + 0.12, ps - 0.45, ps + 0.45, &"wood")
			var mat := _pick(CRATES)
			var hh := rng.randf_range(0.5, 1.3)
			_r(pt - 0.48, pt + 0.48, InteriorKit.FLOOR_Y + 0.12, InteriorKit.FLOOR_Y + 0.12 + hh, ps - 0.4, ps + 0.4, mat, true)
	_r(_door_t - 1.0, _door_t + 1.0, InteriorKit.FLOOR_Y, InteriorKit.FLOOR_Y + 0.01, 0.05, 0.45, &"hazard")


## Canteen: a serving counter with the kitchen behind it, stools, tables, a lit menu.
func _canteen() -> void:
	var cs := d - rng.randf_range(1.5, 2.0)
	var c0 := rng.randf_range(0.1, 0.8)
	var c1 := w - rng.randf_range(1.0, 1.6)   # gap at one end to get behind
	_r(c0, c1, InteriorKit.FLOOR_Y, 1.0, cs, cs + 0.5, &"wood_dark", true)
	_r(c0 - 0.03, c1 + 0.03, 1.0, 1.05, cs - 0.06, cs + 0.56, &"wood")
	_clutter(c0, c1, 1.05, cs, cs + 0.5, 4 + rng.randi() % 6)
	var st := c0 + 0.5
	while st < c1 - 0.3:
		if rng.randf() < 0.8:
			_r(st - 0.14, st + 0.14, InteriorKit.FLOOR_Y, 0.6, cs - 0.52, cs - 0.24, &"wood_dark", true)
		st += rng.randf_range(0.75, 1.1)
	# Kitchen line on the back wall: stove, pots, a steaming vat.
	_r(c0, c1, InteriorKit.FLOOR_Y, 0.88, d - 0.6, d - 0.03, &"plate", true)
	var kt := c0 + 0.2
	while kt < c1 - 0.5:
		var kw := rng.randf_range(0.3, 0.55)
		_r(kt, kt + kw, 0.88, 0.88 + rng.randf_range(0.15, 0.45), d - 0.5, d - 0.5 + kw, &"metal_light" if rng.randf() < 0.6 else &"copper")
		kt += kw + rng.randf_range(0.15, 0.6)
	# Lit menu boards above the kitchen.
	var mt := c0 + rng.randf_range(0.2, 0.8)
	var board: StringName = [&"sign_yellow", &"sign_magenta", &"sign_green", &"sign_cyan"][rng.randi() % 4]
	while mt < c1 - 1.0:
		var mw := rng.randf_range(0.7, 1.3)
		_r(mt, mt + mw, 2.1, 2.55, d - 0.06, d - 0.03, board if lit else &"structure")
		mt += mw + rng.randf_range(0.15, 0.5)
	# Tables between the door and the counter.
	var tt := rng.randf_range(1.0, 1.6)
	while tt < w - 0.9:
		var ts := rng.randf_range(1.5, maxf(1.6, cs - 2.0))
		var sq := rng.randf_range(0.7, 0.95)
		if rng.randf() < 0.85 and _table(tt, ts, sq, sq, 0.72):
			_clutter(tt - sq * 0.5, tt + sq * 0.5, 0.72, ts - sq * 0.5, ts + sq * 0.5, rng.randi() % 4)
			for a: Array in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
				if rng.randf() < 0.7:
					_stool(tt + float(a[0]) * (sq * 0.5 + 0.3), ts + float(a[1]) * (sq * 0.5 + 0.3))
		tt += rng.randf_range(1.9, 2.7)


## Continuum shrine: the three-ring emblem over an altar, votive lights, benches,
## hanging cloths.
func _shrine() -> void:
	var at := w * 0.5 + rng.randf_range(-0.6, 0.6)
	_r(at - 0.9, at + 0.9, InteriorKit.FLOOR_Y, 0.9, d - 0.7, d - 0.03, &"concrete", true)
	_r(at - 1.0, at + 1.0, 0.9, 0.95, d - 0.76, d - 0.03, _pick(CLOTHS))
	_r(at - 1.5, at + 1.5, InteriorKit.FLOOR_Y, InteriorKit.FLOOR_Y + 0.14, d - 1.5, d - 0.03, &"concrete", true)
	var emblem := ContinuumEmblem.create(0.5, &"copper", &"structure", false)
	emblem.position = _p(at, 1.95, d - 0.12)
	emblem.rotation.y = PI
	add_child(emblem)
	# Votive lights on the altar and along the side ledges.
	var flame: StringName = &"bulb" if lit else &"ceramic"
	for i in 3 + rng.randi() % 6:
		var vt := at + rng.randf_range(-0.85, 0.85)
		var vs := d - rng.randf_range(0.25, 0.65)
		_r(vt - 0.025, vt + 0.025, 0.95, 0.95 + rng.randf_range(0.06, 0.16), vs - 0.025, vs + 0.025, flame)
	for side: float in [0.0, 1.0]:
		var lt := 0.0 if side < 0.5 else w - 0.22
		_r(lt, lt + 0.22, 1.0, 1.05, 2.3, d - 1.0, &"wood_dark")
		for i in 2 + rng.randi() % 5:
			var vs := rng.randf_range(2.4, d - 1.1)
			_r(lt + 0.08, lt + 0.14, 1.05, 1.05 + rng.randf_range(0.06, 0.15), vs, vs + 0.06, flame)
		# Hanging cloth above the ledge.
		if rng.randf() < 0.75:
			var hs := rng.randf_range(2.6, d - 2.2)
			var ht := 0.03 if side < 0.5 else w - 0.05
			_r(ht, ht + 0.02, 1.35, 2.9, hs, hs + rng.randf_range(0.7, 1.2), _pick(CLOTHS))
	# Benches facing the altar, an aisle down the middle.
	var s := d - rng.randf_range(2.6, 3.0)
	while s > 2.2:
		for side: float in [-1.0, 1.0]:
			var b0 := at + side * 0.55
			var b1 := at + side * minf(w * 0.5 - 0.7, rng.randf_range(2.2, 3.6))
			if rng.randf() < 0.85 and _free(minf(b0, b1), maxf(b0, b1), s - 0.2, s + 0.2):
				_r(b0, b1, 0.38, 0.44, s - 0.18, s + 0.18, &"wood_dark")
				_r(b0, b1, InteriorKit.FLOOR_Y, 0.38, s - 0.12, s + 0.12, &"wood_dark", true)
		s -= rng.randf_range(1.0, 1.3)


## Communal bathhouse: a raised pool, benches, lockers, a shower wall and pipework.
func _bathhouse() -> void:
	var fy := InteriorKit.FLOOR_Y
	var pc := w * 0.5 + rng.randf_range(-0.8, 0.8)
	var pw := minf(w * 0.5 - 2.2, rng.randf_range(2.6, 4.6))
	var p0 := 2.7
	var p1 := d - rng.randf_range(1.5, 2.0)
	# Pool basin: tiled rim, water unless the place is derelict.
	_r(pc - pw, pc + pw, fy, 0.12, p0, p1, &"tile_cool")
	_r(pc - pw - 0.3, pc + pw + 0.3, fy, 0.55, p0 - 0.3, p0, &"tile_cool", true)
	_r(pc - pw - 0.3, pc + pw + 0.3, fy, 0.55, p1, p1 + 0.3, &"tile_cool", true)
	_r(pc - pw - 0.3, pc - pw, fy, 0.55, p0, p1, &"tile_cool", true)
	_r(pc + pw, pc + pw + 0.3, fy, 0.55, p0, p1, &"tile_cool", true)
	if not ruin:
		_r(pc - pw, pc + pw, 0.12, 0.44, p0, p1, &"water")
	# Step up to the rim on the door side, filler spout at the back.
	_r(pc - 1.0, pc + 1.0, fy, 0.28, p0 - 0.7, p0 - 0.3, &"tile_cool", true)
	_r(pc - 0.08, pc + 0.08, 0.55, 1.2, p1 + 0.1, p1 + 0.26, &"copper")
	_r(pc - 0.08, pc + 0.08, 1.1, 1.2, p1 - 0.35, p1 + 0.1, &"copper")
	# Lockers down the left wall, benches in front of them.
	var ls := 2.4
	while ls < d - 0.7:
		if rng.randf() < 0.85:
			_r(0.03, 0.5, fy, rng.randf_range(1.7, 1.95), ls, ls + 0.55, &"container_grey" if rng.randf() < 0.7 else &"container_teal", true)
		ls += 0.58
	_r(0.8, 1.2, 0.4, 0.46, 2.6, d - 1.0, &"wood", true)
	_r(0.85, 1.15, fy, 0.4, 2.7, 2.85, &"structure")
	_r(0.85, 1.15, fy, 0.4, d - 1.25, d - 1.1, &"structure")
	# Shower wall on the right: riser, heads, low partitions.
	_r(w - 0.12, w - 0.04, 2.15, 2.23, 2.2, d - 0.4, &"copper")
	var ss := 2.6
	while ss < d - 0.8:
		_r(w - 0.1, w - 0.04, 0.3, 2.15, ss - 0.03, ss + 0.03, &"copper")
		_r(w - 0.42, w - 0.1, 2.08, 2.14, ss - 0.05, ss + 0.05, &"metal_light")
		_r(w - 1.1, w - 0.03, fy, 1.5, ss + 0.62, ss + 0.68, &"tile_cool", true)
		ss += 1.35
	# Towels on a rail by the door wall, buckets about.
	var tt := clampf(_door_t + (3.0 if _door_t < w * 0.5 else -5.0), 0.4, w - 2.6)
	_r(tt, tt + 2.2, 1.5, 1.53, 0.06, 0.09, &"structure")
	for i in 2 + rng.randi() % 4:
		var tx := tt + rng.randf_range(0.05, 1.7)
		_r(tx, tx + 0.4, 1.5 - rng.randf_range(0.5, 0.9), 1.5, 0.09, 0.12, _pick(CLOTHS))
	for i in 2 + rng.randi() % 4:
		var bt := rng.randf_range(1.6, w - 1.6)
		var bs := rng.randf_range(0.5, 1.9)
		if _free(bt - 0.2, bt + 0.2, bs - 0.2, bs + 0.2):
			_r(bt - 0.16, bt + 0.16, fy, 0.3, bs - 0.16, bs + 0.16, &"wood_dark", true)
	# Overhead pipe runs.
	for i in 2:
		var ps := rng.randf_range(1.0, d - 1.0)
		_r(0.0, w, ceil_y - 0.5 - float(i) * 0.16, ceil_y - 0.38 - float(i) * 0.16, ps, ps + 0.12, &"copper" if i == 0 else &"structure")


## Communal laundry: washers along the back, folding tables, and lines of washing
## filling the room.
func _laundry() -> void:
	var fy := InteriorKit.FLOOR_Y
	var t := rng.randf_range(0.15, 0.6)
	while t < w - 0.85:
		if rng.randf() < 0.85:
			var h := 0.92 if rng.randf() < 0.7 else 1.7
			_r(t, t + 0.72, fy, h, d - 0.72, d - 0.03, &"metal_light" if rng.randf() < 0.75 else &"container_grey", true)
			_r(t + 0.16, t + 0.56, 0.3, 0.7, d - 0.76, d - 0.72, &"structure")
			if lit and rng.randf() < 0.5:
				_r(t + 0.08, t + 0.16, 0.78, 0.84, d - 0.75, d - 0.72, &"rail_glow")
		t += 0.76 if rng.randf() < 0.8 else rng.randf_range(1.2, 2.0)
	_r(0.0, w, 1.25, 1.33, d - 0.2, d - 0.08, &"copper")
	# Folding tables with piles of cloth.
	var ft := rng.randf_range(1.6, 2.4)
	while ft < w - 1.4:
		var fs := rng.randf_range(2.6, maxf(2.7, d - 2.6))
		if _table(ft, fs, 2.2, 0.9, 0.82, &"plate"):
			for i in 1 + rng.randi() % 4:
				var px := ft + rng.randf_range(-0.9, 0.6)
				_r(px, px + rng.randf_range(0.3, 0.5), 0.82, 0.82 + rng.randf_range(0.06, 0.28), fs - 0.3, fs + 0.25, _pick(CLOTHS))
		ft += rng.randf_range(3.2, 4.4)
	# Lines of washing right across the room, at different heights.
	var ls := rng.randf_range(2.3, 2.8)
	while ls < d - 1.1:
		var ly := rng.randf_range(2.25, 2.6)
		_r(0.0, w, ly, ly + 0.015, ls - 0.008, ls + 0.008, &"structure")
		var ct := rng.randf_range(0.2, 0.8)
		while ct < w - 0.9:
			var cw := rng.randf_range(0.4, 0.95)
			if rng.randf() < (0.35 if ruin else 0.8):
				_r(ct, ct + cw, ly - rng.randf_range(0.5, 1.15), ly, ls - 0.012, ls + 0.012, _pick(CLOTHS))
			ct += cw + rng.randf_range(0.08, 0.5)
		ls += rng.randf_range(0.9, 1.5)
	# Baskets.
	for i in 3 + rng.randi() % 4:
		_crate(rng.randf_range(0.5, w - 0.5), rng.randf_range(0.5, d - 1.6), rng.randf_range(0.4, 0.6), fy, &"wood")


## Water-ration hall: queue rails leading to a caged counter, storage tanks behind.
func _ration_hall() -> void:
	var fy := InteriorKit.FLOOR_Y
	var cs := d - rng.randf_range(2.3, 2.9)
	# Counter and the cage over it, with lit dispenser hatches.
	_r(0.0, w, fy, 1.1, cs, cs + 0.5, &"plate", true)
	_r(0.0, w, 1.1, 1.16, cs - 0.08, cs + 0.58, &"structure")
	_r(0.0, w, 2.3, 2.42, cs + 0.2, cs + 0.3, &"structure")
	SliceMaterials.add_collision_box(_body, _p(w * 0.5, 1.8, cs + 0.25), Vector3(w, 1.3, 0.1))
	var bt := 0.15
	while bt < w:
		_r(bt - 0.02, bt + 0.02, 1.16, 2.3, cs + 0.23, cs + 0.27, &"structure")
		bt += 0.32
	var ht := rng.randf_range(1.2, 2.0)
	while ht < w - 1.0:
		_r(ht - 0.4, ht + 0.4, 0.45, 0.85, cs - 0.03, cs, (&"sign_cyan" if rng.randf() < 0.75 else &"sign_green") if lit else &"structure")
		_r(ht - 0.06, ht + 0.06, 1.16, 1.4, cs + 0.02, cs + 0.14, &"copper")
		ht += rng.randf_range(1.9, 2.8)
	# Tanks behind the counter, piped down to it.
	var tank_h := minf(ceil_y - 0.7, rng.randf_range(4.2, 5.4))
	var tk := rng.randf_range(0.5, 1.0)
	while tk < w - 1.9:
		var tw := rng.randf_range(1.4, 1.9)
		_r(tk, tk + tw, 0.5, tank_h, d - 1.5, d - 0.1, &"container_teal" if rng.randf() < 0.7 else &"container_grey", true)
		_r(tk + 0.15, tk + 0.3, fy, 0.5, d - 1.4, d - 0.2, &"structure")
		_r(tk + tw - 0.3, tk + tw - 0.15, fy, 0.5, d - 1.4, d - 0.2, &"structure")
		_r(tk + tw * 0.5 - 0.06, tk + tw * 0.5 + 0.06, 1.4, 1.52, cs + 0.3, d - 1.5, &"copper")
		tk += tw + rng.randf_range(0.3, 1.1)
	# Queue rails: staggered gaps so the line snakes.
	var qs := 2.6
	var row := 0
	while qs < cs - 1.2:
		var g0 := 0.0 if row % 2 == 0 else 1.6
		var g1 := w - 1.6 if row % 2 == 0 else w
		_r(g0, g1, 0.92, 0.98, qs - 0.03, qs + 0.03, &"structure")
		SliceMaterials.add_collision_box(_body, _p((g0 + g1) * 0.5, 0.5, qs), Vector3(g1 - g0, 1.0, 0.08))
		var pt := g0 + 0.1
		while pt < g1:
			_r(pt - 0.03, pt + 0.03, fy, 0.92, qs - 0.03, qs + 0.03, &"structure")
			pt += 2.0
		qs += 1.4
		row += 1
	_r(0.2, w - 0.2, fy, fy + 0.01, cs - 0.75, cs - 0.45, &"hazard")
	# Allocation board on the left wall; a few people's belongings left in the queue.
	_r(0.03, 0.06, 1.5, 2.6, 2.4, minf(d - 3.2, 5.4), &"sign_board_lit" if lit else &"structure")
	for i in rng.randi() % 4:
		_crate(rng.randf_range(0.6, w - 0.6), rng.randf_range(2.9, maxf(3.0, cs - 1.6)), rng.randf_range(0.3, 0.45), fy, &"wood_dark")


## Abandoned rooms: rubble, a fallen ceiling panel, drifted rubbish.
func _debris() -> void:
	var fy := InteriorKit.FLOOR_Y
	for i in 8 + rng.randi() % 10:
		var t := rng.randf_range(0.3, w - 0.3)
		var s := rng.randf_range(0.3, d - 0.3)
		var sz := rng.randf_range(0.12, 0.45)
		if _free(t - sz, t + sz, s - sz, s + sz):
			_r(t - sz, t + sz, fy, fy + rng.randf_range(0.05, 0.3), s - sz * 0.7, s + sz * 0.7, &"concrete" if rng.randf() < 0.6 else &"wood_dark")
	for i in 1 + rng.randi() % 2:
		var t := rng.randf_range(1.5, w - 2.5)
		var s := rng.randf_range(2.4, maxf(2.5, d - 2.0))
		_r(t, t + rng.randf_range(1.2, 2.0), fy, fy + 0.07, s, s + rng.randf_range(0.8, 1.4), &"plate")
	# Rubbish drifted into the corners.
	for corner: Vector2 in [Vector2(0.5, d - 0.5), Vector2(w - 0.5, d - 0.5)]:
		for i in 3 + rng.randi() % 3:
			var o := Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.35, 0.35))
			var sz := rng.randf_range(0.15, 0.35)
			_r(corner.x + o.x - sz, corner.x + o.x + sz, fy, fy + rng.randf_range(0.1, 0.5), corner.y + o.y - sz, corner.y + o.y + sz, _pick(CLOTHS) if rng.randf() < 0.4 else &"fabric_dark")
