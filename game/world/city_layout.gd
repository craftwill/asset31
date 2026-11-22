class_name CityLayout
extends RefCounted
## Deterministic floor layout. The same function feeds near collision, near
## visuals and far visuals, so every LOD shows the same buildings in the same
## place. All positions are stack-local metres (floor top = y 0).

const CHUNK := 500.0
const BLOCK := 62.5
const STREET := 14.0
const STOREY := 3.5
const AVENUE_HALF := 24.0
const EDGE_MARGIN := 24.0
const PILLAR_CLEAR := 14.0
const GATE_PLAZA_RADIUS := 260.0
const INDUSTRIAL_RADIUS := 1100.0
const LAMP_SPACING := 36.0
const LAMP_OFFSET := 28.0

enum Zone { URBAN, RESIDENTIAL, INDUSTRIAL }


static func chunk_counts(def: Dictionary) -> Vector2i:
	return Vector2i(int(float(def.size[0]) / CHUNK), int(float(def.size[2]) / CHUNK))


static func chunk_origin(def: Dictionary, key: Vector2i) -> Vector2:
	return Vector2(-float(def.size[0]) * 0.5 + key.x * CHUNK, -float(def.size[2]) * 0.5 + key.y * CHUNK)


static func chunk_key_for(def: Dictionary, x: float, z: float) -> Vector2i:
	var n := chunk_counts(def)
	return Vector2i(
		clampi(int(floor((x + float(def.size[0]) * 0.5) / CHUNK)), 0, n.x - 1),
		clampi(int(floor((z + float(def.size[2]) * 0.5) / CHUNK)), 0, n.y - 1))


## Point on the floor at the centre of the edge gate (stack-local XZ).
static func gate_point(def: Dictionary) -> Vector2:
	var side: String = def.opening.side
	var hw := float(def.size[0]) * 0.5
	var hd := float(def.size[2]) * 0.5
	match side:
		"+x": return Vector2(hw, 0.0)
		"-x": return Vector2(-hw, 0.0)
		"+z": return Vector2(0.0, hd)
		_: return Vector2(0.0, -hd)


static func pillar_positions(def: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var sp := float(def.pillars.spacing)
	var hw := float(def.size[0]) * 0.5
	var hd := float(def.size[2]) * 0.5
	var x := -hw + sp * 0.5
	while x < hw:
		var z := -hd + sp * 0.5
		while z < hd:
			out.append(Vector2(x, z))
			z += sp
		x += sp
	return out


## Authored sites reserve ground: rect = [x0, z0, x1, z1] in stack-local metres.
static func site_rects(def: Dictionary, only_no_lamps := false) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for s: Dictionary in def.get("sites", []):
		if only_no_lamps and not s.get("no_lamps", false):
			continue
		var r: Array = s.rect
		out.append(Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]), float(r[3]) - float(r[1])))
	return out


static func avenue_lamps(def: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var hw := float(def.size[0]) * 0.5
	var blocked := site_rects(def, true)
	var x := -hw + 30.0
	while x < hw - 10.0:
		for z in [-LAMP_OFFSET, LAMP_OFFSET]:
			var p := Vector2(x, z)
			var ok := true
			for r in blocked:
				if r.has_point(p):
					ok = false
					break
			if ok:
				out.append(Vector3(x, 0.0, z))
		x += LAMP_SPACING
	return out


static func zone_at(def: Dictionary, p: Vector2) -> Zone:
	for district: Dictionary in def.districts:
		var c := Vector2(float(district.center[0]), float(district.center[1]))
		if p.distance_to(c) < float(district.radius):
			if district.kind == "residential":
				return Zone.RESIDENTIAL
			if district.kind == "industrial":
				return Zone.INDUSTRIAL
	if p.distance_to(gate_point(def)) < INDUSTRIAL_RADIUS:
		return Zone.INDUSTRIAL
	return Zone.URBAN


## Returns Array of { "c": Vector3 centre, "s": Vector3 size, "seed": float 0..1 }.
static func generate_chunk(def: Dictionary, key: Vector2i) -> Array:
	var out: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d" % [def.id, key.x, key.y])
	var org := chunk_origin(def, key)
	var ctx := {
		"hw": float(def.size[0]) * 0.5,
		"hd": float(def.size[2]) * 0.5,
		"ceiling": float(def.size[1]),
		"sp": float(def.pillars.spacing),
		"pclear": float(def.pillars.size) * 0.5 + PILLAR_CLEAR,
		"gate": gate_point(def),
		"sites": site_rects(def),
	}
	var n := int(CHUNK / BLOCK)
	var bsz := BLOCK - STREET
	for bi in n:
		for bj in n:
			var bx := org.x + bi * BLOCK + STREET * 0.5
			var bz := org.y + bj * BLOCK + STREET * 0.5
			var zone := zone_at(def, Vector2(bx + bsz * 0.5, bz + bsz * 0.5))
			if zone == Zone.INDUSTRIAL:
				_try_building(out, rng, Rect2(bx, bz, bsz, bsz), zone, ctx)
			else:
				var half := bsz * 0.5
				for li in 2:
					for lj in 2:
						_try_building(out, rng, Rect2(bx + li * half, bz + lj * half, half, half), zone, ctx)
	return out


static func _try_building(out: Array, rng: RandomNumberGenerator, lot: Rect2, zone: Zone, ctx: Dictionary) -> void:
	# Always draw the same number of randoms so exclusions never reshuffle neighbours.
	var r_in := PackedFloat32Array([rng.randf(), rng.randf(), rng.randf(), rng.randf()])
	var r_h := rng.randf()
	var r_mega := rng.randf()
	var r_mh := rng.randf()
	var r_seed := rng.randf()
	var r_set := rng.randf()
	var r_set_h := rng.randf()
	var r_set_in := rng.randf()
	var r_roof := rng.randf()
	var r_roof_p := Vector3(rng.randf(), rng.randf(), rng.randf())
	if _excluded(lot, ctx):
		return
	var inset_max := 4.0 if zone == Zone.INDUSTRIAL else 2.5
	var il := 1.0 + r_in[0] * inset_max
	var ir := 1.0 + r_in[1] * inset_max
	var it := 1.0 + r_in[2] * inset_max
	var ib := 1.0 + r_in[3] * inset_max
	var fx := lot.size.x - il - ir
	var fz := lot.size.y - it - ib
	var h: float
	match zone:
		Zone.RESIDENTIAL:
			h = 9.0 + floorf(r_h * 8.0) * STOREY
		Zone.INDUSTRIAL:
			h = 12.0 + r_h * 30.0
		_:
			if r_mega < 0.012:
				h = 300.0 + r_mh * (float(ctx.ceiling) - 360.0)
			else:
				h = 14.0 + pow(r_h, 2.4) * 150.0
	h = minf(ceilf(h / STOREY) * STOREY, float(ctx.ceiling) - 40.0)
	# The seed carries the zone in its integer part (read by the facade shader).
	var seed := float(zone) + r_seed * 0.9
	var cx := lot.position.x + il + fx * 0.5
	var cz := lot.position.y + it + fz * 0.5
	var top := h
	var top_fx := fx
	var top_fz := fz
	var top_cx := cx
	var top_cz := cz
	if zone != Zone.INDUSTRIAL and h > 30.0 and r_set < 0.45:
		# Stepped silhouette: a lower body and a narrower upper body.
		var h1 := ceilf(h * (0.45 + 0.3 * r_set_h) / STOREY) * STOREY
		var k := 0.15 + 0.15 * r_set_in
		_box(out, cx, -1.0, cz, fx, h1 + 1.0, fz, seed)
		top_fx = fx * (1.0 - 2.0 * k)
		top_fz = fz * (1.0 - 2.0 * k)
		top_cx = cx + (r_roof_p.x - 0.5) * fx * k
		top_cz = cz + (r_roof_p.z - 0.5) * fz * k
		# Starts 0.5 m inside the lower body so no horizontal faces are coplanar.
		_box(out, top_cx, h1 - 0.5, top_cz, top_fx, h - h1 + 0.5, top_fz, seed)
	else:
		# Buildings sink 1 m into the floor slab so no faces are coplanar with the ground.
		_box(out, cx, -1.0, cz, fx, h + 1.0, fz, seed)
	if r_roof < 0.6 and top_fx > 6.0 and top_fz > 6.0:
		# Rooftop clutter: plant room / tank / hut.
		var rw := 2.0 + r_roof_p.y * 3.0
		var rd := 2.0 + r_roof_p.x * 3.0
		var rh := 2.0 + r_roof * 4.0
		var rx := top_cx + (r_roof_p.x - 0.5) * (top_fx - rw - 1.0)
		var rz := top_cz + (r_roof_p.z - 0.5) * (top_fz - rd - 1.0)
		_box(out, rx, top - 0.5, rz, rw, rh + 0.5, rd, seed)


## Box from y0 upward with height h.
static func _box(out: Array, cx: float, y0: float, cz: float, sx: float, h: float, sz: float, seed: float) -> void:
	out.append({ "c": Vector3(cx, y0 + h * 0.5, cz), "s": Vector3(sx, h, sz), "seed": seed })


static func _excluded(lot: Rect2, ctx: Dictionary) -> bool:
	var hw: float = ctx.hw
	var hd: float = ctx.hd
	if lot.position.x < -hw + EDGE_MARGIN or lot.end.x > hw - EDGE_MARGIN:
		return true
	if lot.position.y < -hd + EDGE_MARGIN or lot.end.y > hd - EDGE_MARGIN:
		return true
	if lot.position.y < AVENUE_HALF and lot.end.y > -AVENUE_HALF:
		return true
	var c := lot.get_center()
	if c.distance_to(ctx.gate) < GATE_PLAZA_RADIUS:
		return true
	for r: Rect2 in ctx.sites:
		if r.intersects(lot):
			return true
	var sp: float = ctx.sp
	var px := (roundf((c.x + hw - sp * 0.5) / sp)) * sp - hw + sp * 0.5
	var pz := (roundf((c.y + hd - sp * 0.5) / sp)) * sp - hd + sp * 0.5
	var pc: float = ctx.pclear
	var pr := Rect2(px - pc, pz - pc, pc * 2.0, pc * 2.0)
	return pr.intersects(lot)
